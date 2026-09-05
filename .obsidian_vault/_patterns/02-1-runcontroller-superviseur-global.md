### 2.1. `RunController` (`runProvider`) — Superviseur Global (Façade)

**Provider** : `NotifierProvider<RunController, RunState>`

**État `RunState`** : `currentLevel`, `act`, `heroStats` (EntityStats), `heroClassId`, `mapNodes` (List\<MapNode\>), `currentNodeId`, `passiveTrait`, `activePassive` (PassiveData?), `pendingDrafts` (int), `bonusForgeSlots` (int), `forgeSlots` (List\<String\>), `forgeTargetCardId` (String?).

**Organisation Modulaire** :
`RunController` délègue l'ensemble de ses traitements logiques à quatre gestionnaires spécialisés instanciés à sa création :
- **`PlayerStatsManager`** (`lib/game/controllers/run/player_stats_manager.dart`) :
  - Gère les points de vie, le mana, l'armure et les altérations d'état temporaires du héros.
  - Traite l'application des soins (`heal`), des dégâts directs (`takeDamage`) et l'application des modificateurs de statistiques permanents (`applyHeroStatModifier`).
  - Gère le système d'Expérience (XP) et les montées de niveau : accumule l'XP de victoire, calcule le seuil requis ($100 \times 1.5^{\text{level} - 1}$), traite la montée en niveau en cascade (multi-levels) et gère le report du reste d'expérience (`carry-over`) sans perte tout en incrémentant `pendingDrafts`.
- **`MapProgressionManager`** (`lib/game/controllers/run/map_progression_manager.dart`) :
  - Gère le déplacement vers un nœud de la carte stratégique (`travelToNode`) et valide son accessibilité.
  - Gère la complétion du nœud actuel (`completeCurrentNode`) : réinitialise l'armure à 0, nettoie les statuts temporaires, et gère le passage à l'acte suivant (en déclenchant la génération d'une nouvelle carte via `MapGeneratorService`).
- **`GoldManager`** (`lib/game/controllers/run/gold_manager.dart`) :
  - Gère les transactions d'or (gains, dépenses, validation de solde).
  - Gère la facturation progressive pour l'achat de fentes bonus de forge ($50 \rightarrow 80 \rightarrow 120 \rightarrow 175$ Or).

**Tour de combat** : `startCombat()` (initialise le combat, applique les reliques `startOfCombat` et les passifs) → `startTurn()` (réinitialise l'armure à 0 → restaure le mana → applique les reliques et statuts de début de tour, ex: `armor_regen`, `strength_regen` → décrémente les durées de statuts).

**Système de reliques** : Délègue à `PlayerStatsManager` l'application des effets de reliques selon le trigger (`applyRelics`, `applyRelicEffect`).

**Interactions** : Lit `inventoryProvider` (reliques). Muté par `CombatController`, `EventController`, `ShopController`, `TraitSystem`, `EffectResolver`.

**Réhydratation (`hydrate(RunState)`)** : Depuis la v3.2.0 (Système de Sauvegarde), `RunController` expose `hydrate(RunState savedState)` qui remplace intégralement `state` par une sauvegarde chargée. Appelée exclusivement par `SaveService.load()`, jamais par un flux de jeu normal.
