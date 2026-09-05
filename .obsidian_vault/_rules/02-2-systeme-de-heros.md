### 2.2. Système de Héros

Trois classes de héros, une par dossier `assets/data/classes/<id>/` (`class.json` + `icon.png` + `cards/`) :

| Héros | HP | Mana | Attaque | Luck | Armor Mastery | Passif | Compétences |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | 0 | `regen_armor` (gain armure fin de tour) | `paladin_shield` (15 armure, 3 mana), `paladin_rage` (2 atk buff, 5 mana) |
| **Berserker** | 80 | 3 | 15 | 0 | 0 | `berserker_armor` (armure ∝ HP manquants, début tour) | `berserker_leech` (vampirisme 3, 0 mana), `berserker_pierce` (15 dégâts perce-armure, 3 mana) |
| **Mage** | 60 | 3 | 10 | 0 | 0 | `spell_armor` (armure quand skill jouée) | `mage_nova` (20 dégâts AoE, 4 mana), `mage_strike` (150 dégâts ciblés, 8 mana) |

**Passifs** (gérés par `TraitSystem`, un fichier par passif sous `assets/data/passives/`) :
| ID | Trigger | EffectType | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|
| `regen_armor` | `endOfTurn` | `gain_armor` | 2 | +2 armure (+armorMastery) à chaque fin de tour |
| `berserker_armor` | `startOfTurn` | `berserker_armor` | 1 | +1 armure par tranche de 10 HP manquants (+armorMastery) |
| `spell_armor` | `onCardPlayed` | `spell_armor` | 1 | +1 armure quand une carte Skill est jouée (+armorMastery) |
