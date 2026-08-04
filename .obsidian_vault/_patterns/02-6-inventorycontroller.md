### 2.6. `InventoryController` (`inventoryProvider`)

**Provider** : `NotifierProvider<InventoryController, InventoryState>`

**État** : `gold`, `relics` (List\<RelicData\>), `bonusShopCards`.

**Responsabilités** : `gainGold()`, `spendGold()` (validation), `addRelic()` (si trigger `startOfRun` → application immédiate via runProvider), `buyShopExpansion()`, `reset(initialGold: 50)`.
