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

### 6.3. Valeurs des Récompenses de Montée de Niveau

`LevelUpRewardService.generateChoices()` tire un type puis une rareté, et en déduit la
valeur. Trois types suivent un **multiplicateur générique** appliqué à une base
(`×1` / `×1,5` / `×2` / `×3` / `×4`, arrondi par `num.round()`), les trois autres portent
leur propre courbe. Le mythique partage toujours la valeur du légendaire.

| Récompense | Champ | Commun | Peu commun | Rare | Épique | Légendaire |
|:---|:---|---:|---:|---:|---:|---:|
| Vitalité | `pvBoost` | 5 | 8 | 10 | 15 | 20 |
| Aiguisage | `atkBoost` | 2 | 3 | 4 | 6 | 8 |
| Forge d'Acier | `armorBoost` | 1 | 2 | 3 | 5 | 7 |
| Sagesse | `manaBoost` | 1 | 2 | 2 | 3 | 4 |
| Précision | `critChanceBoost` | 1 | 2 | 3 | 4 | 5 |
| Férocité | `critDamageBoost` | +10 % | +20 % | +30 % | +40 % | +50 % |

Deux récompenses n'ont pas de courbe : elles ne sortent **qu'en mythique**, avec une valeur
unique, et chacune est tirée par un jet indépendant — le **Trèfle à 4 feuilles**
(`luckBoost: 1`) et le **Miroir** (`isCloneOption`, clone d'une carte).

> [!IMPORTANT]
> **La Forge d'Acier a sa propre courbe, plus raide que le générique.** La Maîtrise d'Armure
> s'ajoute à *chaque* gain d'armure du passif — à chaque tour pour le Paladin, à chaque
> Compétence jouée pour le Mage — donc elle compose bien plus fort que les autres
> récompenses. C'est aussi la seule case qui avait cassé : sa cascade de `if` n'avait pas de
> palier légendaire et retombait sur `1`, la valeur d'un commun. Corrigé en `0.4.9`.

> [!NOTE]
> **Sagesse plafonne à 2 sur deux paliers consécutifs.** `round(1 × 1,5)` et `round(1 × 2,0)`
> donnent tous deux 2 : peu commun et rare rendent la même chose. Comportement existant,
> laissé tel quel et verrouillé comme tel.

Les 30 cases de ce tableau sont verrouillées par `test/unit/level_up_reward_values_test.dart`,
qui vérifie en outre que chaque type progresse strictement avec la rareté — l'invariant que
la Forge d'Acier violait.
