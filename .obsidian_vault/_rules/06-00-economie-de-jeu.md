## 6. Économie de Jeu

### 6.1. Or

- **Or initial** : 50 (défini dans `InventoryController.reset(initialGold: 50)`).
- **Sources** : Victoires combat (via `completeCurrentNode`), événements (`gain_gold`), reliques.
- **Dépenses** : Boutique (cartes, services), événements (`spend_gold`).

### 6.2. Récompenses Post-Combat

Le système de récompenses par statistiques (Vitalité, Aiguisage, Forge, Sagesse) est géré par `RunController.applyHeroStatModifier()` avec des multiplicateurs de rareté.

| Attribut | Bonus base | Note |
|:---|:---|:---|
| `maxPvAcc` | +X PV Max | Soigne aussi le delta |
| `attackAcc` | +X Attaque permanente | Additionné à `effectiveAttaque` |
| `armorAcc` | +X Maîtrise d'Armure | Bonus permanent sur tous les gains d'armure |
| `maxManaAcc` | +X Mana Max | Augmente le plafond régénéré chaque tour |
| `luckAcc` | +X Chance | Influence rareté des récompenses et reliques |
