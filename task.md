# Tasks: Refactoring Boss Node Rewards and Enemy Gold Drops

- [x] 1. In `lib/models/data/enemy_data.dart`, add a `gold` field (default 10) and update `fromJson` to parse it.
- [x] 2. In `assets/data/enemies.json`, add `"gold"` properties to each enemy (slime: 10, goblin: 12, skeleton: 15, orc: 25).
- [x] 3. In `lib/models/map_node.dart`, define enum `BossRewardType { cards, doubleXp, improvedRelic }` and add `final BossRewardType? bossRewardType;` to `MapNode`, ensuring `fromJson`/`toJson` serialize/deserialize it properly.
- [x] 4. In `lib/services/map_generator_service.dart`, assign `bossRewardType` to the final floor (boss floor) nodes based on horizontal index (0: cards, 1: doubleXp, 2: improvedRelic).
- [x] 5. Create `lib/game/controllers/reward_controller.dart` which manages the `RewardState` (holding gold/XP gained, rolled relic, rolled cards, collection states, and resolution state) and provides methods to collect/skip rewards, applying them to player inventory/level/map node completion.
- [x] 6. In `lib/ui/widgets/map/map_node_widget.dart`, replace coordinates string-parsing checks with checking `node.bossRewardType`.
- [x] 7. In `lib/ui/screens/draft_screen.dart`, remove the random gold gain inside `_finishDraft` since combat gold is now managed by the reward controller.
- [x] 8. In `lib/ui/screens/game_screen.dart`, refactor victory reward logic (remove old relic rolling, XP calculations, and card draft dialog launcher) to delegate calculations and collection flow to the new `rewardProvider` (sequentially displaying relic screen, card draft dialog, and handling level ups / navigation).
- [x] 9. Make sure to run `dart analyze` and fix any compiler/lint warnings.
- [x] 10. Update the task.md file as you progress.
