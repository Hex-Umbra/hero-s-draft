### 2.2. Système de Héros

Trois classes de héros définis dans `heroes.json` :

| Héros | HP | Mana | Attaque | Luck | Armor Mastery | Passif | Compétences |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | 0 | `regenArmor` (gain armure fin de tour) | `paladin_shield` (15 armure, 3 mana), `paladin_rage` (2 atk buff, 5 mana) |
| **Berserker** | 80 | 3 | 15 | 0 | 0 | `berserkerArmor` (armure ∝ HP manquants, début tour) | `berserker_leech` (vampirisme 3, 0 mana), `berserker_pierce` (15 dégâts perce-armure, 3 mana) |
| **Mage** | 60 | 3 | 10 | 0 | 0 | `spellArmor` (armure quand skill jouée) | `mage_nova` (20 dégâts AoE, 4 mana), `mage_strike` (150 dégâts ciblés, 8 mana) |

**Passifs** (gérés par `TraitSystem`, données dans `passives.json`) :
| ID | Trigger | EffectType | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|
| `regenArmor` | `endOfTurn` | `gain_armor` | 2 | +2 armure (+armorMastery) à chaque fin de tour |
| `berserkerArmor` | `startOfTurn` | `berserker_armor` | 1 | +1 armure par tranche de 10 HP manquants (+armorMastery) |
| `spellArmor` | `onCardPlayed` | `spell_armor` | 1 | +1 armure quand une carte Skill est jouée (+armorMastery) |
