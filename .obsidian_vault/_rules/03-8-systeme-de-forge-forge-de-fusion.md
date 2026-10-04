### 3.8. 🔨 Runes — la Fusion qui les Donne, l'Affûtage au Feu et le Puits d'Échange

Une rune est une amélioration permanente d'une carte, notée `id:niveau` dans
`CardInstance.forgeUpgrades`. Depuis le lot E2 de P-43
([ADR-106](../_adr/ADR-106-fusion-egale-forge.md), vague 2, fusionnée dans `main` le
2026-10-03), **une rune s'obtient par la fusion de cartes** (§3.8.4), **monte d'un niveau au feu
de camp** (§3.8.5) et **s'échange au Puits d'échange** (§3.8.6) ; la boutique vend des cartes qui en
portent déjà ([`_rules/03-9`](03-9-boutique.md)). Ont disparu avec E2 : la forge du feu — ses fentes
tirées, ses relances, ses fentes achetées et sa « session » dans `RunState` —, la Forge de Fusion,
la capacité de runes d'une carte, et les clés `pools` et `stackable`. **Le lot E3** (branche de la
vague 3, en attente du propriétaire — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md))
ajoute trois sources d'affûtage hors du feu et un plafond que la run peut relever (§3.8.7).

#### 3.8.1. Une rune est un fichier

- **Un fichier par rune** sous `assets/data/forge_upgrades/` : nom et description bilingues, emoji,
  icône, couleur, poids de tirage (`weight`), **rang minimal (`minFusionRank`, obligatoire, entier
  ≥ 1)**, champs d'éligibilité, **plafond (`maxLevel`, obligatoire, `null` = sans plafond)** et
  **effet (`deltas`, obligatoire)**. `ForgeUpgradeData.fromJson` refuse une clé obligatoire absente
  ou hors bornes ; le modèle tient le registre `getById(id)`.
- **`binary`** (branche de la vague 3, A16 ; booléen, absent = faux, toujours écrit par `toJson`) :
  la rune n'a qu'un niveau qui compte, son plafond ne monte jamais. Vrai sur *Persistant* et
  *Allégé* ; refusé avec un `maxLevel` autre que 1.
- **Aucune rune n'a de code à son nom** — ni son effet, ni son éligibilité, ni ses textes :
  `rune_ids_in_code_test.dart` refuse tout id de rune livrée écrit en littéral dans `lib/`
  ([ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md)). Les noms d'icône et de couleur se
  traduisent par deux tables, `runeIcons` et `runeColors` (`lib/ui/widgets/forge/rune_style.dart`) ;
  un nom inconnu retombe sur du gris et un point d'interrogation, et un test d'intégrité exige que
  chaque rune livrée ait les siens.

#### 3.8.2. Les onze runes

Au niveau L, appliquées par un seul applicateur (`EffectiveCard`), pour le moteur comme pour tous
les rendus :

| Rune | Delta | Effet | Plafond | Rang min. | Poids |
|:---|:---|:---|:---:|:---:|---:|
| *Tranchant* (`sharp`) | `percentBonus` dégâts, 15 | Chaque effet de dégâts gagne **15 % × L de sa valeur à la rareté, au moins +L** (entier, demie vers le haut) : *Frappe* (6) +1 au niveau 1, *Frappe Lourde* (12) +2 | — | 1 | 100 |
| *Endurci* (`hardened`) | `percentBonus` armure, 15 | Idem sur chaque effet d'armure : *Mur de Fer* (10) +2 au niveau 1 | — | 1 | 100 |
| *Spectral* (`spectral`) | `percentBonus` dégâts, 40 ; `addExhaust` | **40 % × L de la valeur à la rareté, au moins +L** — la Puissance n'y entre pas — et **la carte s'épuise** | — | 1 | 50 |
| *Précis* (`precise`) | `critBonus`, 5 | **+5 × L points de chance critique** sur les dégâts de la carte ([`_rules/03-11`](03-11-systeme-de-coup-critique.md)) | 10 | 1 | 50 |
| *Allégé* (`cheap`) | `reduceCost`, 1 | **La carte coûte L Mana de moins**, jamais sous 0 | 1 | 1 | 50 |
| *Brûlant*, *Congelant*, *Surchargé* | `addEffect` `apply_status` | Posent `burn`, `freeze`, `shock` de valeur L pour L tours, par `addStatus` : ils fusionnent avec le statut que la cible porte ([`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.3) | — · 1 · — | 1 | 80 |
| *Véloce* (`quick`) | `addEffect` `draw` | Pioche L cartes à la pose | 1 | **2** | 60 |
| *Économe* (`eco`) | `addEffect` `gain_mana` | Rend L Mana **à la pose** — ce n'est pas une réduction de coût | 1 | **2** | 40 |
| *Persistant* (`enduring`) | `removeExhaust` | La carte ne s'épuise plus | 1 | 1 | 30 |

- **Les effets ajoutés** se résolvent **avant** ceux de la carte, par les mêmes stratégies ; ils ne
  sont ni multipliés par la rareté ni visés par un pourcentage. Deux pourcentages sur un même effet
  ne se composent pas : *Tranchant* et *Spectral* s'additionnent, chacun sur la valeur à la rareté.
- **L'épuisement** : `CardInstance.exhaustsOnPlay` — un pouvoir, une carte *Spectrale*, ou une carte
  `isExhaust` sans *Persistant*. **L'épuisement de *Spectral* l'emporte sur *Persistant*.** Le badge
  « Usage unique » et les particules d'épuisement lisent ce même prédicat : ils apparaissent sur une
  carte *Spectrale* et quittent une carte *Persistante*.
- **Le coût** : `CardInstance.currentCost` est le coût que calcule l'applicateur — *Allégé* le
  baisse, la rareté ne le change jamais ([`_rules/03-1`](03-1-gestion-du-mana.md)).
- **Le plafond** : une seule fonction, `ForgeUpgradeData.boundLevel`, borne les quatre endroits qui
  écrivent un niveau — l'héritage de la fusion, les pré-forgées de la boutique, l'affûtage et le
  Puits — et, sur la branche de la vague 3, `DeckNotifier.raiseRuneLevel`, l'écriture que
  partagent le feu et les trois sources sans or. Le plafond lu est **le plafond effectif** :
  `maxLevel` plus le bonus de la run pour cette rune (`capBonus`, §3.8.7).
- **Une rune de chaque type par carte** (D3) — une rune portée ne se repropose jamais —, et **aucun
  plafond du nombre de runes** : la capacité de runes d'une carte n'existe plus.
- **Les descriptions** sont les mêmes sur la carte, dans ses infobulles et dans chaque dialogue, une
  ligne par rune au niveau qu'elle joue. `{val}` y dit **ce que la rune ajoute à cette carte**, pour
  toute sorte chiffrée ; dans un dialogue qui offre une rune ou un niveau, c'est le gain **marginal**,
  ce que la carte porte déjà compris.

#### 3.8.3. Éligibilité — un prédicat unique, lu dans la donnée

`ForgeRuneRules.isEligible(rune, carte, catalogue)` : une rune s'offre à une carte si et seulement
si, à la fois :

1. son `eligibleCardTypes`, s'il existe, contient le type de la carte ;
2. son `eligibleEffects`, s'il existe, nomme un **effet propre** de la carte — les effets qu'une
   autre rune ajoute ne comptent pas ;
3. aucun effet propre n'est dans son `excludesEffects` — *Persistant* refuse une carte qui pioche ou
   rend du Mana ;
4. `requiresExhaust` est satisfait — *Persistant* ne s'offre qu'à une carte qui s'épuise ;
5. le coût **courant** de la carte, calculé par l'applicateur sur le catalogue reçu, atteint
   `requiresMinCost` — ni *Économe* ni *Allégé* sur une carte gratuite ;
6. aucune rune portée ne l'exclut ni n'est exclue par elle (`excludesRunes`, **symétrique**) —
   *Persistant* ne cohabite ni avec *Économe* ni avec *Véloce*, *Allégé* pas avec *Économe* ;
7. **`minFusionRank` ≤ le rang de la carte qui la reçoit** (`CardRarity.fusionRank`) — à la fusion,
   le rang **atteint** ; en boutique et au Puits, le rang de la carte. Une commune et une carte de
   classe, de rang 0, n'en reçoivent aucune ;
8. **la carte ne la porte pas déjà.**

Ce que le prédicat offre, sur les cartes livrées sans rune héritée — matrice gardée par
`forge_upgrades_catalog_test.dart` :

| Cartes | Première fusion (peu commune) | Deuxième fusion (rare) |
|:---|:---|:---|
| *Frappe*, *Frappe Lourde*, *Boule de Feu*, *Trait de Glace*, *Coup Empoisonné*, *Attaque Rapide*, *Balayage*, *Coup de Tonnerre* | *Tranchant*, les trois élémentaires, *Allégé*, *Précis*, *Spectral* | les mêmes, *Économe*, *Véloce* |
| *Cri de Guerre* | les mêmes et *Endurci* | et *Économe*, *Véloce* |
| *Défense*, *Mur de Fer*, *Éveil* | *Endurci*, *Allégé* | et *Économe*, *Véloce* |
| *Potion de Soin* | *Persistant*, *Allégé* | et *Économe*, *Véloce* — jamais avec *Persistant* |
| *Forme Démoniaque*, *Métallisation* | *Allégé* | et *Économe*, *Véloce* |
| *Concentration*, *Focalisation* | **aucune** | *Véloce* |

Les six cartes de classe, `unique`, ne fusionnent pas et ne reçoivent jamais de rune.

#### 3.8.4. La fusion donne la rune

La fusion 3 → 1 ([`_rules/02-4`](02-4-progression-de-rarete-dynamique-et-fusion-int.md)) garde
toutes les runes de ses trois exemplaires, puis **offre une rune parmi trois** :

- l'offre est tirée sur la carte fusionnée, au rang qu'elle atteint, par `ForgeRuneRules.drawRunes` :
  **jusqu'à trois runes distinctes, pondérées par `weight`, sans remise**, parmi celles que le
  prédicat accepte — **moins s'il y en a moins, jamais aucune tant qu'une existe** (D65) ;
- le dialogue de fusion (`ForgeUpgradeDialog`) montre la carte et une ligne par rune offerte, au
  niveau 1 ; **il ne se ferme que par un choix** — ni annulation, ni relance, ni fente achetée ;
- sans aucune rune éligible — la première fusion d'une *Concentration* —, la fusion se fait sans
  dialogue : « fusion réussie », puis « Aucune rune ne peut être ajoutée à cette carte. » ;
- **la fusion reste gratuite** (D32).

#### 3.8.5. L'affûtage au feu de camp

Au feu de camp, « AFFÛTER » remplace l'ancienne forge parmi trois options exclusives
([`_rules/03-7`](03-7-feu-de-camp-repos.md)) :

- **une rune d'une carte gagne un niveau**, une seule, une fois par visite (D4, D14) ;
- **coût : 50 × le niveau porté** — 50, 100, 150, 200… (`ForgeRuneRules.sharpenCost`, D20, D63) ;
  il croît avec le niveau de la rune, pas avec le rang de la carte ;
- se montent : *Tranchant*, *Endurci*, *Brûlant*, *Surchargé*, *Spectral* sans plafond, *Précis*
  jusqu'au niveau 10 ; jamais *Économe*, *Véloce*, *Congelant*, *Persistant*, *Allégé*, au plafond
  dès le niveau 1 (`canSharpen`) — sauf, pour les trois premières, sous *Transcendance* (§3.8.7) ;
- la référence `id:n` devient `id:n+1` à sa place, par `GoldManager.sharpenRune`, qui refuse — sans
  rien toucher — une rune au plafond ou l'or qui manque. Sur la branche de la vague 3, il vérifie,
  paie, puis délègue l'écriture à `DeckNotifier.raiseRuneLevel` ; `capBonus` lui est **requis**,
  comme à `exchangeRune` — `RunController` passe `RunState.runeCapBonus`.

#### 3.8.6. Le Puits d'échange

Le Puits d'échange remplace la Forge de Fusion — même nœud de la carte, `MapNodeType.forgeFusion`,
désormais garanti **tous les trois actes** ([`_rules/02-1`](02-1-generation-procedurale-de-carte.md)) :

- le joueur choisit une carte qui porte une rune, la rune à **donner**, puis **une remplaçante parmi
  toutes celles que le prédicat accepte sur la carte sans la rune donnée**, à son rang
  (`ForgeRuneRules.wellOptions`) — donner *Persistant* pour *Économe* est donc possible ;
- **la rune reçue entre aux deux tiers du niveau donné**, arrondi au plus proche, au moins 1, puis
  bornée par son plafond (`wellLevel` = `boundLevel((2L + 1) ~/ 3)`, D39) : *Tranchant* 9 contre
  *Économe* donne *Économe* 1 ;
- **coût : 50 × le niveau de la rune donnée** (`wellCost`, base distincte de celle de l'affûtage) ;
- **un échange par visite** ; la rune reçue prend la place de la rune donnée, par
  `GoldManager.exchangeRune`, qui refuse sans rien toucher une remplaçante hors de l'offre ou l'or
  qui manque ;
- après un échange, quitter l'écran — bouton ou retour système — résout le nœud ; sans échange, le
  retour ne le résout pas, et le joueur peut revenir.

| Niveau donné | 1 | 2 | 3 | 4 | 5 | 6 | 9 | 12 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Niveau reçu, avant plafond | 1 | 1 | 2 | 3 | 3 | 4 | 6 | 8 |
| Coût (or) | 50 | 100 | 150 | 200 | 250 | 300 | 450 | 600 |

#### 3.8.7. L'affûtage hors du feu, et le plafond relevé

*Branche de la vague 3, en attente du propriétaire —
[ADR-107](../_adr/ADR-107-trouvaille-et-progression.md) (D42, A3 à A5, A13 à A18, A21).* Trois
sources montent une rune **sans or**, toutes par `DeckNotifier.raiseRuneLevel(cardId, runeId,
{levels, capBonus})`, qui refuse sans rien toucher une carte absente, une rune non portée, hors
registre, ou à son plafond effectif :

| Source | Quelle rune | Combien |
|:---|:---|:---|
| **Le boss « XP »** | une paire (carte, rune) tirée au hasard parmi celles dont la rune peut encore monter (`ForgeRuneRules.sharpenablePairs`) ; chaque tirage voit le précédent | 1 (`GameConstants.bossXpRuneSharpens`), plus 1 par *Meule* ; aucune sans paire — et le jeu le dit |
| **La *Meule*** (relique légendaire) | idem | +1 par exemplaire (`RunState.extraBossRuneSharpens`) |
| **Le *Rémouleur*** (événement) | celle que le joueur choisit, par la sélection et le dialogue du feu en mode sans or (`isFree`) | 1 niveau, contre 10 % des PV max ([`_rules/03-6`](03-6-systeme-d-evenements.md)) |

**Ce n'est pas le feu** : la règle « une rune, un niveau par visite » (D14) et le prix en or (D20)
restent les siens.

***Transcendance*** — une récompense mythique (D42(c)) : **le plafond d'un type de rune monte de 1,
sur toutes les cartes, pour toute la run** (`RunController.raiseRuneCap`, qui écrit
`RunState.runeCapBonus[id]`). Le joueur choisit dans une modale non refermable la rune à relever
parmi les **candidates** : les runes qu'une carte du deck porte **à leur plafond effectif**, ni sans
plafond ni `binary`, une fois chacune, dans l'ordre du catalogue (`ForgeRuneRules.raisableCaps`) —
dans les onze runes livrées, *Économe*, *Véloce*, *Congelant* et *Précis*, jamais *Persistant* ni
*Allégé*. Elle n'est tirée que si une candidate existe (`requires: raisableRune`).

- **Tous les écrivains de niveau lisent le plafond effectif** : `boundLevel(…, capBonus:)`, la
  fusion (`consolidate`, par `DeckNotifier.mergeCards(…, capBonus:)` que passe l'écran de deck), les
  pré-forgées de la boutique, l'affûtage au feu (`canSharpen`, `hasSharpenableRune`, la sélection
  et le dialogue), le Puits (`wellLevel`, et son écran), le boss « XP » et le *Rémouleur*. Le
  paramètre est optionnel, à défaut neutre, sur `boundLevel`, `ForgeRuneRules` et `mergeCards` ;
  les appelants de production passent tous `RunState.runeCapBonus`. Le tutoriel n'en passe aucun.
- **Ce que cela ouvre** : *Économe* 2 ou *Véloce* 2, par l'affûtage — feu, boss, événement — ou par
  l'héritage d'une fusion ; jamais avec *Persistant*.
- **Le nom d'une rune dit son niveau dès qu'il dépasse 1** (`ForgeUpgradeData.nameAt`), même pour
  une rune de plafond de base 1 : *Économe 2*.

> [!NOTE]
> **Les sources de rune en jeu** : la fusion (une rune par fusion), les pré-forgées de la boutique,
> et les clones qui recopient les runes (boss « cartes », Miroirs). Les niveaux montent par
> l'héritage et l'affûtage — au feu, et sur la branche de la vague 3 par le boss « XP », la *Meule*
> et le *Rémouleur*. **Les fusions, rares en vague 2, deviennent fréquentes avec la trouvaille de la
> vague 3** — une carte après chaque combat ([`_rules/06-00`](06-00-economie-de-jeu.md) §6.4).
