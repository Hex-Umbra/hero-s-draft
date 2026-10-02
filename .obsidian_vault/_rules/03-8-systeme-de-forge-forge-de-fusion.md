### 3.8. 🔨 Système de Forge & Forge de Fusion (Forge v2.5)

La Forge permet d'ajouter des améliorations permanentes (upgrades) aux cartes du Master Deck en échange d'or. Elle a été étendue pour intégrer un système piloté par les données (data-driven) et un nœud spécial sur la carte : la **Forge de Fusion**.

#### 3.8.1. Forge classique (Améliorations Data-Driven)
- **Structure pilotée par les données** : Toutes les améliorations de forge (runes) sont définies de manière déclarative, un fichier par rune sous `assets/data/forge_upgrades/` : nom et description bilingues, emoji, icône, couleur, poids (`weight`), pools de rareté (`pools`), **champs d'éligibilité, plafond de niveau (`maxLevel`) et effet (`deltas`)**. Le modèle `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) les lit et fournit le registre statique `getById(id)`. **Aucune rune n'a de code à son nom** : ni son effet, ni son éligibilité, ni ses textes — un test (`rune_ids_in_code_test.dart`) refuse tout id de rune livrée écrit en littéral dans `lib/` — [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md).
- **Ce que fait une rune — ses deltas**, appliqués par un seul applicateur (`EffectiveCard`), pour le moteur comme pour tous les rendus. Au niveau L :

  | Rune | Delta | Effet |
  |:---|:---|:---|
  | *Tranchant* (`sharp`) | `percentBonus` dégâts, 15 | Chaque effet de dégâts de la carte gagne **15 % × L de sa valeur à la rareté de la carte, au moins +L** (arrondi entier, demie vers le haut). Sur *Frappe* commune (6) : +1 au niveau 1 ; sur *Frappe Lourde* (12) : +2 |
  | *Endurci* (`hardened`) | `percentBonus` armure, 15 | Idem sur chaque effet d'armure : *Mur de Fer* (10) +2 au niveau 1 |
  | *Véloce* (`quick`) | `addEffect` `draw` | Pioche L cartes à la pose |
  | *Économe* (`eco`) | `addEffect` `gain_mana` | Rend L mana **à la pose** — ce n'est pas une réduction de coût |
  | *Brûlant*, *Congelant*, *Surchargé* | `addEffect` `apply_status` | Posent `burn`, `freeze`, `shock` de valeur L pour L tours, par `addStatus` : ils fusionnent avec le statut que la cible porte ([`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.3) |
  | *Persistant* (`enduring`) | `removeExhaust` | La carte ne s'épuise plus, quel que soit le niveau (`CardInstance.exhaustsOnPlay` lit la donnée) |

  Les effets ajoutés se résolvent **avant** ceux de la carte, par les mêmes stratégies — *Économe* fait entendre le son du gain de mana. Ils ne sont ni multipliés par la rareté ni visés par un pourcentage. Deux exemplaires d'un même id **additionnent leurs niveaux** : la carte joue, et ses infobulles écrivent, une ligne par rune au niveau total.
- **Plafond de niveau (`maxLevel`, clé obligatoire)** : 1 pour *Économe*, *Véloce*, *Congelant* et *Persistant* ; `null` — sans plafond — pour *Tranchant*, *Endurci*, *Brûlant* et *Surchargé*. **Une seule fonction, `ForgeUpgradeData.boundLevel`, borne les quatre endroits qui écrivent un niveau** : le tirage du feu, celui des cartes pré-forgées de la boutique, la fusion de cartes 3→1 et la Forge de Fusion (§3.8.2). Le niveau qu'affiche une fente est donc celui que la carte recevra, ce qu'elle porte déjà compris.
- **Cumul** : seules les runes sans plafond se cumulent sur une carte. **Une rune dont le plafond est atteint sur la carte n'est plus proposée** — exemplaires additionnés (D75) : une carte ne porte jamais deux *Économe*, *Véloce*, *Congelant* ou *Persistant*.
- **Rune non cumulable** : une amélioration déclarée `"stackable": false` — aujourd'hui la seule `enduring` — est binaire. Elle est tirée au niveau 1, et affichée sans niveau dans la fente de la forge et le dialogue de fusion ; les infobulles, elles, écrivent le niveau selon `maxLevel`. `stackable` vit jusqu'à la vague suivante du programme, qui le supprime — [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md), amendé par ADR-105.
- **Limite de Capacité & Fentes de Runes (Rune Sockets)** : Une carte peut accueillir au maximum $baseMaxForgeUpgrades + fusionRank$ améliorations, `CardRarity.fusionRank` valant 0 à 4 de `common` à `legendary` — le nombre de fusions qu'il a fallu pour atteindre la rareté (`CardData.forgeCapacityAt` ; renommé depuis `forgeSlotBonus`, mêmes valeurs). Les cartes uniques de classe ont une limite fixe de 5 améliorations, `unique` n'ajoutant aucun emplacement. Une carte sauvegardée au-delà de sa capacité garde ses runes et les montre toutes, mais n'en accepte plus. Les améliorations de forge sont représentées par des fentes de runes circulaires disposées sur plusieurs rangées (maximum 5 fentes par ligne, avec retour à la ligne automatique géré par `Wrap` en Flutter et par division/coordonnées Canvas en Flame) ; l'emoji d'une rune est lu dans son fichier.
- **Génération Probabiliste de Slots de Base** : À chaque session d'ouverture pour une carte donnée, le système génère de 1 à 5 slots d'options d'upgrades indépendants (tirages de Bernoulli successifs) selon les chances suivantes :
  - Slot 1 : 100% (Garanti)
  - Slot 2 : 50%
  - Slot 3 : 25%
  - Slot 4 : 10%
  - Slot 5 : 2%
- **Anti-Exploit de Reroll Sauvage (Session Persistence)** : Afin d'éviter que le joueur ne contourne le coût des relances ou ne force de meilleures options en fermant et rouvrant simplement la forge, la session de forge active est persistée dans `RunState` (`forgeSlots` contenant les options tirées formatées `id:tier`, et `forgeTargetCardId` contenant l'identifiant unique de la carte ciblée).
  - Si le joueur ouvre la forge sur une carte et que `runState.forgeTargetCardId == card.uniqueId`, le dialogue charge immédiatement les fentes préalablement générées et sauvegardées.
  - Si la carte est différente ou s'il n'y a pas de session active, un nouveau tirage est effectué et immédiatement sauvegardé via `RunNotifier.setForgeSession()`.
  - La session n'est effacée (via `clearForgeSession()`) qu'après validation d'une amélioration ou lors du départ définitif du camp de repos (`RestScreen`).
- **Éligibilité : un prédicat unique, lu dans la donnée** (`ForgeRuneRules.isEligible`, ADR-105). Une rune s'offre à une carte si et seulement si :
  - son `eligibleCardTypes`, s'il existe, contient le type de la carte ;
  - son `eligibleEffects`, s'il existe, nomme un **effet propre** de la carte — *Tranchant* exige des dégâts, *Endurci* de l'armure ; les effets ajoutés par d'autres runes ne comptent pas ;
  - aucun effet propre n'est dans son `excludesEffects` — *Persistant* refuse une carte qui pioche ou rend du mana ;
  - `requiresExhaust` est satisfait — *Persistant* ne s'offre qu'à une carte qui s'épuise ;
  - le coût **courant** de la carte atteint `requiresMinCost` — *Économe* ne s'offre pas à une carte gratuite ;
  - aucune rune portée ne l'exclut ni n'est exclue par elle (`excludesRunes`, **symétrique**) — *Persistant* ne cohabite ni avec *Économe* ni avec *Véloce* ;
  - son plafond n'est pas atteint sur la carte.

  Sur les 23 cartes livrées, sans rune : les Attaques sans armure reçoivent *Tranchant*, les trois runes élémentaires, *Véloce* et *Économe* ; les Attaques à armure, les mêmes et *Endurci* ; *Éveil*, *Défense*, *Mur de Fer*, *Endurci*, *Véloce* et *Économe* ; *Bouclier Sacré*, les mêmes et *Persistant* ; *Potion de Soin*, *Véloce*, *Économe* et *Persistant* ; *Forme Démoniaque*, *Métallisation* et *Posture de Rage*, *Véloce* et *Économe* ; *Concentration*, *Focalisation* et *Surtension de Mana*, *Véloce* seule — matrice gardée par `forge_upgrades_catalog_test.dart`.
- **Une carte sans aucune rune éligible est refusée à la sélection du feu**, avec le message « Aucune rune ne peut être ajoutée à cette carte. » (`forgeNoEligibleRune`) — après le refus d'une carte pleine, qui garde le sien. La forge ne s'ouvre pas.
- **Le tirage d'une fente** (`ForgeUpgradeDialog`, et de même pour les cartes pré-forgées de la boutique) :
  1. un **pool ciblé selon la rareté de la carte** — commune : `common` ; peu commune : `common` à 75 %, `uncommon` à 25 % ; rare et au-delà : `common` à 65 %, `uncommon` à 25 %, `rare` à 10 % ;
  2. parmi les runes de ce pool (`pools`) que le prédicat accepte, hors celles déjà proposées dans la session, un **tirage pondéré par `weight`** ; si le pool ciblé est vide, le tirage descend vers `common`, puis essaie tous les pools — c'est ainsi qu'une carte commune sans dégâts ni armure se voit proposer *Véloce*, *Économe* ou *Persistant* ; en dernier recours, l'exclusion des ids déjà proposés est levée ;
  3. un niveau 1, 2 ou 3 à 80, 15 et 5 % pour une rune cumulable, 1 sinon — **puis borné par le plafond**.

  Les clés `weightCommon`, `weightUncommon` et `weightRare` que cette fiche décrivait jusqu'au 2026-10-02 n'existent dans aucun fichier : le ciblage par rareté est en code, le poids est la clé `weight`. Le repli sur *Tranchant* quand rien n'était éligible a disparu.
- **Relance Individuelle (Reroll)** : Le joueur peut relancer le tirage d'un slot spécifique. Le coût en or augmente exponentiellement par slot :
  $$\text{Coût} = \text{round}(20 \times 1.25^n)$$
  où $n$ est le nombre de relances déjà appliquées à ce slot. Consomme l'or de l'inventaire via `inventoryProvider`. ⚠️ Sur une carte qui n'accepte qu'une rune (*Concentration*, *Focalisation*, *Surtension de Mana* : *Véloce*), une relance payante ne peut rien changer — défaut connu, laissé à la vague suivante du programme, qui supprime la forge du feu.
- **Achat de Fentes Progressives (Buy Slots)** : Le joueur peut étendre sa grille d'options en achetant des fentes bonus additionnelles (champ `bonusForgeSlots` de `RunState`).
  - Capacité maximale : Capée à 4 fentes bonus achetées (soit un maximum de 5 slots affichés au total).
  - Tarification progressive en or : $50 \rightarrow 80 \rightarrow 120 \rightarrow 175$ Or.
  - Le bouton d'achat en bas de la liste est désactivé si l'or disponible est insuffisant ou si la capacité maximale de 5 slots est atteinte.
- **Descriptions** : identiques sur la carte, dans ses infobulles et à la forge, une ligne par rune au niveau qu'elle joue. Celles de *Tranchant* et *Endurci* disent le gain réel : « +{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier}) » ; à la forge, `{val}` est le gain **marginal** de la fente, ce que la carte porte déjà compris.
- **Architecture Modulaire & UI Responsive (v0.2.2)** : Le dialogue de forge (`ForgeUpgradeDialog`) a été converti en interface plein écran réactive (`Dialog.fullscreen`) et découpé selon le principe de responsabilité unique (SRP) :
  - **`ForgeCardPreview`** : Affiche le visuel de la carte sélectionnée avec son coût en mana, sa description dynamique et ses runes d'amélioration à gauche (sur Desktop) ou en haut (sur Mobile).
  - **`ForgeSlotRow`** : Ligne d'option d'amélioration gérant le bouton de forge, le coût de relance et le bouton de reroll. Elle reçoit la carte forgée, pour dire le gain exact de sa rune.
  - **`ForgeBuySlotButton`** : Bouton d'achat de slots bonus en bas de la liste d'options.
  - Desktop : Disposition en colonnes jumelles (`Row`) avec aperçu de carte à gauche et panneau de défilement scrollable (`ListView`) contenant les slots d'amélioration et le bouton d'achat à droite.
  - Mobile : Empilement vertical fluide (`Column`) assurant un scroll confortable et empêchant tout débordement (RenderFlex overflow).

#### 3.8.2. Forge de Fusion (Fusion Forge)
Le nœud de **Forge de Fusion** (`MapNodeType.forgeFusion`) permet au joueur de combiner les améliorations identiques d'une carte pour cumuler leurs tiers (ex: combiner `sharp:1` et `sharp:2` en un unique `sharp:3` sur la carte).
- **Règles de Fusion** :
  - Seules les améliorations de même type (même ID de rune) sur une même carte sont éligibles à la fusion.
  - Leurs tiers sont additionnés. Exemple : deux runes de dégâts Tier 1 fusionnent en une rune de dégâts Tier 2. Trois runes Tier 1 fusionnent en une rune Tier 3.
  - Les runes non cumulables (`stackable: false`, comme `enduring`) ne possèdent pas de statistiques cumulables (binaire persistant/exhaust) et sont exclues de la fusion (`ForgeRuneRules.fusionOptionsFor`). Cette exclusion n'existait pas dans le code avant le 2026-09-15.
  - **Une fusion qui perdrait un niveau n'est pas proposée** : seulement si la somme tient sous le `maxLevel` de la rune (ADR-105). Sans objet en partie neuve — aucune carte n'y porte deux exemplaires dont la somme dépasse le plafond ; le cas ne vient que d'une sauvegarde plus ancienne.
- **Formule du Coût en Or** :
  La fusion a un coût strict calculé en fonction du nombre de runes fusionnées :
  $$\text{Coût} = 80 \times (N - 1) \text{ Or}$$
  Où $N$ est le nombre de runes de même type sélectionnées pour être combinées.
  - Fusionner 2 runes coûte 80 Or.
  - Fusionner 3 runes coûte 160 Or.
- **Interface Utilisateur (`ForgeFusionScreen`)** :
  - L'écran analyse le deck et n'affiche que les cartes possédant au moins deux améliorations du même type (runes identiques) dont la fusion est proposable. Si aucune carte n'est éligible, un message de fallback est affiché.
  - Lors de la sélection d'une carte éligible, l'écran montre son aperçu visuel complet (UiCard) et liste les fusions possibles.
  - Un bouton de validation applique la fusion, débite l'or via `inventoryProvider.notifier.spendGold(...)` et met à jour le deck via `deckProvider.notifier.setForgeUpgrades(...)`.
  - Le joueur peut quitter l'atelier à tout moment en cliquant sur le bouton de retour, ce qui finalise le nœud sur la carte.

La fusion de **cartes** 3→1, qui réunit les runes de trois exemplaires, est une autre règle :
[`_rules/02-4`](02-4-progression-de-rarete-dynamique-et-fusion-int.md).
