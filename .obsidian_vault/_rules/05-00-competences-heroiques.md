## 5. Compétences Héroïques (Skills)

**6 compétences** (2 par héros) dans `skills.json` :

| ID | Héros | Nom | Coût Mana | Type d'Effet | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|:---|:---|
| `paladin_shield` | Paladin | Bouclier | 3 | `armor_buff` | 15 | Gain d'armure (+armorMastery) |
| `paladin_rage` | Paladin | Rage | 5 | `attack_buff` | 2 | Buff force (15% maxPv, durée 2) |
| `mage_nova` | Mage | Nova | 4 | `damage_aoe` | 20 | Dégâts à tous les ennemis |
| `mage_strike` | Mage | Frappe Foudre | 8 | `damage_targeted` | 150 | Dégâts massifs ciblés |
| `berserker_leech` | Berserker | Vampirisme | 0 | `lifesteal_buff` | 3 | Buff lifesteal (durée 3) |
| `berserker_pierce` | Berserker | Perce-Armure | 3 | `damage_pierce` | 15 | Dégâts perçants (ignore armure) |

**Cooldown** : Chaque compétence a un cooldown qui se décrémente de 1 par tour (`SkillController.tickCooldowns()`). Utilisable quand `cooldown <= 0`.
