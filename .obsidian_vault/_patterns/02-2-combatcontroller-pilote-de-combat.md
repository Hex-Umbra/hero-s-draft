### 2.2. `CombatController` (`combatProvider`) — Pilote de Combat (Façade)

**Provider** : `NotifierProvider<CombatController, CombatState>`

**État `CombatState`** : `enemies` (List\<EnemyInstance\> actifs, max 5 slots), `pendingEnemies` (List\<EnemyInstance\> en réserve), `defeatedEnemies` (List\<EnemyInstance\> éliminés), `turnPhase` (TurnPhase: player/enemy), `turnCount`, `selectedEnemyId`, `isCombatEnded`, `isVictory`.

**Organisation Modulaire** :
`CombatController` délègue ses principales étapes de traitement logique à deux processeurs spécialisés :
- **`StatusEffectProcessor`** (`lib/game/controllers/combat/status_effect_processor.dart`) :
  - Centralise le calcul et le traitement autonome des altérations d'état (Poison, Brûlure, Régénération de Force, Régénération d'Armure) appliquées à la fois au joueur et à l'ensemble des ennemis actifs de manière unifiée en début de phase de tour.
- **`TurnPhaseManager`** (`lib/game/controllers/combat/turn_phase_manager.dart`) :
  - Gère la transition entre les phases (Joueur ⇄ Ennemi), l'orchestration séquentielle des actions de riposte ennemie et la fin de tour.

**Responsabilités directes** :
- **Initialisation** : `initializeCombat(...)` — Génère la liste totale des ennemis via `EncounterSystem.generateEnemiesForLevel()`. Instancie les stats des ennemis en appliquant le multiplicateur de niveau (+6% HP/lvl, +4% ATK/lvl) et le **facteur d'Acte en escalier géométrique** (`getHpActFactor`/`getDamageActFactor`, palier de 2 actes depuis ADR-072 — voir §3.1), ainsi que les modificateurs de nœuds (3x HP/2x ATK pour boss, 1.5x pour élite). Les 5 premiers ennemis sont placés dans `enemies` (câblés avec une intention de départ), les suivants sont placés dans `pendingEnemies`.

  > [!IMPORTANT]
  > **Séparation stricte Niveau ↔ Acte (branche `feature/combat_scaling`, mergée vers `main` — voir ADR-070)** : `EncounterSystem.getEnemyLevel()` ne dépend plus jamais de l'Acte (uniquement du niveau du joueur et du type de nœud). L'Acte n'agit plus que via `getHpActFactor`/`getDamageActFactor`, ce qui rend structurellement impossible le double comptage qui existait auparavant (l'Acte apparaissant à la fois dans `enemyLevel` et dans un terme linéaire direct des multiplicateurs).
  
  Le calcul pour déterminer si le combat est un boss s'appuie sur la correction de garde `isBoss` :
  ```dart
  final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
  ```
  Cela évite de classifier faussement un combat standard se trouvant à un étage multiple de 10 comme un boss (le test `level % 10 == 0` n'est activé en secours que si le `nodeType` est non défini).
- **Pipeline de jeu de carte** : `applyPlayerCardPlay(card, RunController, DeckNotifier)` — `EffectResolver.resolveCard()` → `deck.playCard()` → `TraitSystem.onCardPlayed()` → reliques `onCardPlayed` → `_cleanDeadEnemies()`.
- **Intentions ennemies** : `resolveEnemyIntent(enemyId, RunController)` — switch sur IntentType : attack → `runController.takeDamage`, defend → armure, buff → strength(99 tours), debuffDeck → no-op. Les dégâts d'intentions affichés tiennent compte des réductions du gel (50% de réduction cumulable).
- **Nettoyage et Renforcement** : `_cleanDeadEnemies(RunController)` — Filtre les ennemis actifs décédés (HP ≤ 0) et les déplace dans `defeatedEnemies` en appelant `RunController.onEnemyKilled()` (déclencheurs de reliques). Pour chaque ennemi mort, si `enemies.length < 5` et que `pendingEnemies` n'est pas vide, transfère le premier ennemi en attente de la réserve vers le board actif (et lance `_rollIntent` sur lui). Met à jour la sélection de cible et prononce la victoire uniquement si les listes active (`enemies`) et de réserve (`pendingEnemies`) sont toutes deux vides.

**Logique de roll d'intentions** (`_rollIntent`) :
- Si l'ennemi a des `intents` prédéfinis : cycle séquentiel (modulo length, via `intentStep`).
- Sinon aléatoire : 60% attack (baseDamage), 25% defend (5-10 armure), 15% buff (+2 strength).
