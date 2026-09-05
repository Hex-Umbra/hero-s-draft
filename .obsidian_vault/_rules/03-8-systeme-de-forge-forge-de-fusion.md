### 3.8. 🔨 Système de Forge & Forge de Fusion (Forge v2.5)

La Forge permet d'ajouter des améliorations permanentes (upgrades) aux cartes du Master Deck en échange d'or. Elle a été étendue pour intégrer un système piloté par les données (data-driven) et un nœud spécial sur la carte : la **Forge de Fusion**.

#### 3.8.1. Forge classique (Améliorations Data-Driven & Cumulables)
- **Structure pilotée par les données** : Toutes les améliorations de forge sont définies de manière déclarative, un fichier par amélioration sous `assets/data/forge_upgrades/` (nom, description bilingue, icône, couleur, poids d'apparition, restrictions et multiplicateurs). Le modèle `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) parse ces données et fournit un registre statique `getById(id)` pour un rendu dynamique bilingue unifié.
- **Cumul et Suppression de l'Épuisement** : La contrainte d'exclusion `alreadyHas` a été supprimée. Un joueur peut désormais obtenir et appliquer plusieurs améliorations identiques (mêmes runes) sur une même carte. Leurs effets se cumulent et s'additionnent directement en combat (géré dynamiquement dans `CardTextRenderer` et `EffectResolver`).
- **Limite de Capacité & Fentes de Runes (Rune Sockets)** : Une carte peut accueillir au maximum $baseMaxForgeUpgrades + rarityIndex$ améliorations (la capacité augmente avec la rareté de la carte). Les cartes uniques de classe ont une limite fixe de 5 améliorations. Les améliorations de forge sont représentées par des fentes de runes circulaires disposées sur plusieurs rangées (maximum 5 fentes par ligne, avec retour à la ligne automatique géré par `Wrap` en Flutter et par division/coordonnées Canvas en Flame).
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
- **Filtrage Intelligent par Type de Carte** : Les améliorations proposées sont filtrées en amont selon le type de carte pour éviter les tirages aberrants ou inutiles :
  - *skill* (Compétence) : Exclut toutes les options offensives de dégâts physiques (`sharp`) ou élémentaires (`burning`, `freezing`, `shocking`).
  - *power* (Pouvoir) : Autorise uniquement les améliorations utilitaires (`eco` pour la réduction de coût mana, `quick` pour piocher une carte, et `enduring` pour retirer l'effet d'épuisement).
  - *attack* (Attaque) : Conserve l'accès au pool complet de toutes les améliorations (stats physiques, élémentaires, pioche, réduction de coût, enduring).
- **Sélection Pondérée par Rareté** : Les tirages d'options s'appuient sur un tirage pondéré par poids configuré dans le JSON (`weightCommon`, `weightUncommon`, `weightRare`) selon la rareté de la carte. Les Tiers des upgrades suivent la distribution de probabilité : Tier I (80%), Tier II (15%), Tier III (5%).
- **Relance Individuelle (Reroll)** : Le joueur peut relancer le tirage d'un slot spécifique. Le coût en or augmente exponentiellement par slot :
  $$\text{Coût} = \text{round}(20 \times 1.25^n)$$
  où $n$ est le nombre de relances déjà appliquées à ce slot. Consomme l'or de l'inventaire via `inventoryProvider`.
- **Achat de Fentes Progressives (Buy Slots)** : Le joueur peut étendre sa grille d'options en achetant des fentes bonus additionnelles (champ `bonusForgeSlots` de `RunState`).
  - Capacité maximale : Capée à 4 fentes bonus achetées (soit un maximum de 5 slots affichés au total).
  - Tarification progressive en or : $50 \rightarrow 80 \rightarrow 120 \rightarrow 175$ Or.
  - Le bouton d'achat en bas de la liste est désactivé si l'or disponible est insuffisant ou si la capacité maximale de 5 slots est atteinte.
- **Architecture Modulaire & UI Responsive (v0.2.2)** : Le dialogue de forge (`ForgeUpgradeDialog`) a été converti en interface plein écran réactive (`Dialog.fullscreen`) et découpé selon le principe de responsabilité unique (SRP) :
  - **`ForgeCardPreview`** : Affiche le visuel de la carte sélectionnée avec son coût en mana, sa description dynamique et ses runes d'amélioration à gauche (sur Desktop) ou en haut (sur Mobile).
  - **`ForgeSlotRow`** : Ligne d'option d'amélioration gérant le bouton de forge, le coût de relance et le bouton de reroll.
  - **`ForgeBuySlotButton`** : Bouton d'achat de slots bonus en bas de la liste d'options.
  - Desktop : Disposition en colonnes jumelles (`Row`) avec aperçu de carte à gauche et panneau de défilement scrollable (`ListView`) contenant les slots d'amélioration et le bouton d'achat à droite.
  - Mobile : Empilement vertical fluide (`Column`) assurant un scroll confortable et empêchant tout débordement (RenderFlex overflow).

#### 3.8.2. Forge de Fusion (Fusion Forge)
Le nœud de **Forge de Fusion** (`MapNodeType.forgeFusion`) permet au joueur de combiner les améliorations identiques d'une carte pour cumuler leurs tiers (ex: combiner `sharp:1` et `sharp:2` en un unique `sharp:3` sur la carte).
- **Règles de Fusion** :
  - Seules les améliorations de même type (même ID de rune) sur une même carte sont éligibles à la fusion.
  - Leurs tiers sont additionnés. Exemple : deux runes de dégâts Tier 1 fusionnent en une rune de dégâts Tier 2. Trois runes Tier 1 fusionnent en une rune Tier 3.
  - Les runes de type `enduring` ne possèdent pas de statistiques cumulables (binaire persistant/exhaust) et sont exclues de la fusion.
- **Formule du Coût en Or** :
  La fusion a un coût strict calculé en fonction du nombre de runes fusionnées :
  $$\text{Coût} = 80 \times (N - 1) \text{ Or}$$
  Où $N$ est le nombre de runes de même type sélectionnées pour être combinées.
  - Fusionner 2 runes coûte 80 Or.
  - Fusionner 3 runes coûte 160 Or.
- **Interface Utilisateur (`ForgeFusionScreen`)** :
  - L'écran analyse le deck et n'affiche que les cartes possédant au moins deux améliorations du même type (runes identiques). Si aucune carte n'est éligible, un message de fallback est affiché.
  - Lors de la sélection d'une carte éligible, l'écran montre son aperçu visuel complet (UiCard) et liste les fusions possibles.
  - Un bouton de validation applique la fusion, débite l'or via `inventoryProvider.notifier.spendGold(...)` et met à jour le deck via `deckProvider.notifier.setForgeUpgrades(...)`.
  - Le joueur peut quitter l'atelier à tout moment en cliquant sur le bouton de retour, ce qui finalise le nœud sur la carte.
