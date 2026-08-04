### 3.2. 🛡️ Gestion de l'Armure

**Absorption des dégâts** (`EntityStats.takeDamage(amount)`) :
```dart
if (armure >= amount) {
  armure -= amount;          // Armure absorbe tout
} else {
  int remaining = amount - armure;
  armure = 0;                // Armure brisée
  currentPv = (currentPv - remaining).clamp(0, maxPv);
}
```

**Maîtrise d'Armure (`armorMastery`)** : Statistique cumulative et permanente. Tous les gains d'armure dans `RunController` et `TraitSystem` ajoutent systématiquement l'Armor Mastery effective (obtenue via le getter dynamique `effectiveArmorMastery` sur `EntityStats`, qui combine la base `armorMastery` et les bonus temporaires de combat issus du statut `'armor_mastery'`) au montant.

**Persistance et Cycle de Reset** :
- **Reset de Tour** : L'armure accumulée par le joueur est réinitialisée à `0` au début de son tour (au lancement de `startTurn()` dans `RunController`, avant l'application des reliques et effets de statut de début de tour). Cela évite l'accumulation infinie d'armure d'un tour à l'autre et garantit l'équilibrage des reliques ou effets générateurs d'armure.
- **Suppression d'Animation** : Lors de cette réinitialisation en début de tour, les animations visuelles de perte d'armure (popup textuel négatif comme "-X" et animation de secousse de bouclier) sont désactivées via un drapeau transitoire (`suppressArmorChangeAnimation` sur `HeroCard`) pour éviter d'indiquer à tort que le joueur a subi des dégâts.
- **Fin de Combat** : L'armure restante est également remise à 0 à la fin de chaque combat (`completeCurrentNode()`).
- **Maîtrise d'Armure** : La Maîtrise d'Armure (`effectiveArmorMastery`), quant à elle, reste persistante tout au long de la partie ou du combat selon son origine.
