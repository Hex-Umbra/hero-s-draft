### 2.1. `RunController` (`runProvider`) — Superviseur Global (Façade)

**Provider** : `NotifierProvider<RunController, RunState>`

**État `RunState`** : `currentLevel`, `act`, `heroStats` (EntityStats), `heroClassId`, `mapNodes` (List\<MapNode\>), `currentNodeId`, `activePassive` (PassiveData?), `pendingDrafts` (int). `bonusForgeSlots`, `forgeSlots` et `forgeTargetCardId` ont disparu avec la forge du feu, et leur API (`setForgeSession`, `clearForgeSession`, `buyBonusForgeSlot`) avec eux — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md). `passiveTrait` a disparu avec P-49 : le lien classe → passif part désormais du passif lui-même (`classes`), voir [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md).

**Organisation Modulaire** :
`RunController` délègue l'ensemble de ses traitements logiques à quatre gestionnaires spécialisés instanciés à sa création :
- **`PlayerStatsManager`** (`lib/game/controllers/run/player_stats_manager.dart`) :
  - Gère les points de vie, le mana, l'armure et les altérations d'état temporaires du héros.
  - Traite l'application des soins (`heal`), des dégâts directs (`takeDamage`) et l'application des modificateurs de statistiques permanents (`applyHeroStatModifier`).
  - **`grant(StatGain gain)`** (P-41 lot A) : façade vers `StatGains.apply` (`lib/game/systems/stat_gains.dart`), le seul point de passage d'un gain d'armure, de mana ou de puissance, étiqueté par sa `GainSource` — remplace l'ancien `setHeroStats`, supprimé. `RunController.grant` la relaie. Détail : [`_rules/03-2`](../_rules/03-2-gestion-de-l-armure.md), [ADR-095](../_adr/ADR-095-passage-unique-des-gains-scission-des-puissances-et.md).
  - Gère le système d'Expérience (XP) et les montées de niveau : accumule l'XP de victoire, calcule le seuil requis ($100 \times 1.5^{\text{level} - 1}$), traite la montée en niveau en cascade (multi-levels) et gère le report du reste d'expérience (`carry-over`) sans perte tout en incrémentant `pendingDrafts`.
- **`MapProgressionManager`** (`lib/game/controllers/run/map_progression_manager.dart`) :
  - Gère le déplacement vers un nœud de la carte stratégique (`travelToNode`) et valide son accessibilité.
  - Gère la complétion du nœud actuel (`completeCurrentNode`) : réinitialise l'armure à 0, nettoie les statuts temporaires, et gère le passage à l'acte suivant (en déclenchant la génération d'une nouvelle carte via `MapGeneratorService`).
- **`GoldManager`** (`lib/game/controllers/run/gold_manager.dart`) :
  - Ne tient pas l'or, qui vit dans `InventoryController` (`spendGold`) : il vend des services contre lui.
  - Vend les deux services de rune payants (ADR-106, A16) — la règle « payer et écrire, ou rien » vit ici, les formules dans `ForgeRuneRules` : **`sharpenRune(cardId, runeId)`**, l'affûtage au feu (un niveau de plus contre `50 × niveau` or), et **`exchangeRune(cardId, givenId, receivedId)`**, l'échange au Puits (la rune reçue à sa place, aux deux tiers du niveau donné, contre `50 × niveau donné` or). Chacun refuse sans rien toucher, puis dépense par `inventoryProvider` et réécrit la référence par `DeckNotifier.setForgeUpgrades` ; `RunController` les expose sous les mêmes noms. Détail : [`_patterns/10-00`](10-00-architecture-du-systeme-de-forge-et-de-fusion.md) §10.3.

**Tour de combat** : `startCombat()` (initialise le combat, applique les reliques `startOfCombat` et les passifs) → `startTurn()` (réinitialise l'armure à 0 → restaure le mana → applique les reliques et statuts de début de tour, ex: `armor_regen`, `strength_regen` → décrémente les durées de statuts).

**Système de reliques** : Délègue à `PlayerStatsManager` l'application des effets de reliques selon le trigger (`applyRelics`, `applyRelicEffect`).

**Interactions** : Lit `inventoryProvider` (reliques). Muté par `CombatController`, `EventController`, `ShopController`, `TraitSystem`, `EffectResolver`.

**Réhydratation (`hydrate(RunState)`)** : Depuis la v3.2.0 (Système de Sauvegarde), `RunController` expose `hydrate(RunState savedState)` qui remplace intégralement `state` par une sauvegarde chargée. Appelée exclusivement par `SaveService.load()`, jamais par un flux de jeu normal.
