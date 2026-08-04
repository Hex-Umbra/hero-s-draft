### 3.5. 🎒 Système de Reliques

**24 reliques** définies dans `relics.json` (au lieu de 14 initialement, équilibrant le pool commun), organisées par déclencheurs et types d'effets :

| ID | Nom | Rareté | Trigger | Effet | Valeur | Description |
|:---|:---|:---|:---|:---|:---|:---|
| `iron_talisman` | Talisman de Fer | Common | startOfTurn | gain_armor | 2 | Gagne 2 points d'Armure au début de chaque tour. |
| `whetstone` | Pierre à aiguiser | Common | startOfRun | gain_strength | 1 | +1 Force de manière permanente pour toute la run. |
| `leather_boots` | Bottes en cuir | Common | startOfCombat | gain_armor | 3 | Gagne 3 points d'Armure au début du combat. |
| `lucky_coin` | Pièce de chance | Common | startOfRun | gain_crit | 5 | +5 de chance de coup critique de manière permanente pour toute la run. |
| `bandage` | Bandage de voyage | Common | endOfTurn | heal | 1 | Restaure 1 PV à la fin de chaque tour. |
| `ancestral_shield` | Bouclier Ancestral | Uncommon | startOfCombat | gain_armor | 5 | Gagne 5 points d'Armure au début du combat. |
| `protection_rune` | Rune de Protection | Uncommon | endOfTurn | gain_armor | 3 | Gagne 3 points d'Armure à la fin de chaque tour. |
| `cursed_blade` | Lame Maudite | Uncommon | startOfRun | gain_strength | 2 | +2 Force de manière permanente pour toute la run. |
| `vampiric_fang` | Croc Vampirique | Uncommon | onEnemyKilled | heal | 8 | Restaure 8 PV chaque fois qu'un ennemi meurt. |
| `lucky_charm` | Porte-bonheur | Uncommon | startOfRun | gain_crit | 10 | +10% de chance de critique de manière permanente pour toute la run. |
| `pen_nib` | Plume de scribe | Uncommon | onCardPlayed | charge_strength_turn | 3 | Toutes les 5 cartes jouées, gagne 3 Force pour le tour en cours. |
| `mage_amulet` | Amulette du Mage | Rare | onCardPlayed | gain_armor | 1 | Gagne 1 point d'Armure chaque fois que vous jouez une carte. |
| `mana_crystal` | Cristal de Mana | Rare | startOfCombat | gain_mana | 1 | Gagne 1 Mana au début du combat (tour 1 uniquement). |
| `spirit_essence` | Essence Spirituelle | Rare | onEnemyKilled | gain_mana | 1 | Gagne 1 Mana chaque fois qu'un ennemi meurt. |
| `regen_ring` | Anneau Régenérant | Rare | endOfTurn | heal | 2 | Restaure 2 PV à la fin de chaque tour. |
| `critical_lens` | Lentille de Focalisation | Rare | startOfRun | gain_crit | 15 | +15% de chance de critique de manière permanente pour toute la run. |
| `kunai` | Croc Kunaï | Rare | onAttackPlayed | charge_armor_mastery_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise d'Armure pour le combat. |
| `shuriken` | Shuriken | Rare | onAttackPlayed | charge_strength_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Force pour le combat. |
| `incense_burner` | Encensoir | Rare | startOfTurn | charge_armor_turn | 8 | Tous les 4 tours, gagne 8 points d'Armure. |
| `lucky_clover` | Trèfle Chanceux | Epic | startOfRun | gain_luck | 1 | +1 Chance de manière permanente pour toute la run. |
| `energy_stone` | Pierre d'Énergie | Epic | startOfTurn | gain_mana | 1 | Gagne 1 Mana au début de chaque tour. |
| `phoenix_feather` | Plume de Phénix | Epic | startOfCombat | gain_mana | 2 | Gagne 2 Mana au début du combat. |
| `fortune_dice` | Dés de Fortune | Legendary | startOfRun | gain_luck | 2 | +2 Chance de manière permanente pour toute la run. |
| `crown_kings` | Couronne des Rois | Legendary | startOfRun | gain_mana | 1 | Gagne 1 Mana Max de manière permanente au début de la run. |

**Cycle de vie des triggers** :
- `startOfRun` : Appliqué immédiatement à l'ajout (`InventoryController.addRelic()`).
- `startOfCombat` : Via `RunController.startCombat()`.
- `startOfTurn` / `endOfTurn` : Via `RunController.startTurn()` / `TraitSystem.onTurnEnd()`.
- `onCardPlayed` : Via `CombatController.applyPlayerCardPlay()`.
- `onAttackPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.attack`.
- `onSkillPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.skill`.
- `onPowerPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.power`.
- `onEnemyKilled` : Via `CombatController._cleanDeadEnemies()` → `RunController.onEnemyKilled()`.

**Système de Charges (Reliques Actives)** :
Les reliques à charges accumulent des compteurs représentés par des effets de statut temporaires ou de combat sur le Héros. Une fois le seuil de charges atteint, le compteur est réinitialisé et l'effet bénéfique s'applique :
- **Kunaï** (`kunai`) : Génère `kunai_charge` (durée 1, donc réinitialisé à chaque tour). À 3 charges, reset et ajoute +1 Maîtrise d'Armure pour le combat via le statut temporaire `'armor_mastery'` (durée 99).
- **Shuriken** (`shuriken`) : Génère `shuriken_charge` (durée 1). À 3 charges, reset et ajoute +1 Force permanente pour le combat (`strength` de 99 tours).
- **Plume de Scribe** (`pen_nib`) : Génère `pen_nib_charge` (durée 99). À 5 charges, reset et ajoute +3 Force temporaire pour le tour en cours (`strength` de 1 tour).
- **Encensoir** (`incense_burner`) : Génère `incense_charge` (durée 99). À 4 charges, reset et octroie +8 points d'Armure.
