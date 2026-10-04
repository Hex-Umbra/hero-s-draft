### 3.5. 🎒 Système de Reliques

**28 reliques**, un fichier par relique sous `assets/data/relics/` (au lieu de 14 initialement, équilibrant le pool commun) — re-compté le 2026-10-04 (`ls assets/data/relics | wc -l`) sur la branche de la vague 3, qui en ajoute trois (25 sur `main`) —, organisées par déclencheurs et types d'effets :

| ID | Nom | Rareté | Trigger | Effet | Valeur | Description |
|:---|:---|:---|:---|:---|:---|:---|
| `iron_talisman` | Talisman de Fer | Common | startOfTurn | gain_armor | 2 | Gagne 2 points d'Armure au début de chaque tour. |
| `whetstone` | Pierre à aiguiser | Common | startOfRun | gain_might | 1 | +1 Puissance de manière permanente pour toute la run. |
| `leather_boots` | Bottes en cuir | Common | startOfCombat | gain_armor | 3 | Gagne 3 points d'Armure au début du combat. |
| `lucky_coin` | Pièce de chance | Common | startOfRun | gain_crit | 5 | +5 de chance de coup critique de manière permanente pour toute la run. |
| `bandage` | Bandage de voyage | Common | endOfTurn | heal | 1 | Restaure 1 PV à la fin de chaque tour. |
| `ancestral_shield` | Bouclier Ancestral | Uncommon | startOfCombat | gain_armor | 5 | Gagne 5 points d'Armure au début du combat. |
| `protection_rune` | Rune de Protection | Uncommon | endOfTurn | gain_armor | 3 | Gagne 3 points d'Armure à la fin de chaque tour. |
| `cursed_blade` | Lame Maudite | Uncommon | startOfRun | gain_might | 2 | +2 Puissance de manière permanente pour toute la run. |
| `vampiric_fang` | Croc Vampirique | Uncommon | onEnemyKilled | heal | 8 | Restaure 8 PV chaque fois qu'un ennemi meurt. |
| `lucky_charm` | Porte-bonheur | Uncommon | startOfRun | gain_crit | 10 | +10% de chance de critique de manière permanente pour toute la run. |
| `pen_nib` | Plume de scribe | Uncommon | onCardPlayed | charge_might_turn | 3 | Toutes les 5 cartes jouées, gagne 3 Puissance pour le tour en cours. |
| `mage_amulet` | Amulette du Mage | Rare | onCardPlayed | gain_armor | 1 | Gagne 1 point d'Armure chaque fois que vous jouez une carte. |
| `mana_crystal` | Cristal de Mana | Rare | startOfCombat | gain_mana | 1 | Gagne 1 Mana au début du combat (tour 1 uniquement). |
| `spirit_essence` | Essence Spirituelle | Rare | onEnemyKilled | gain_mana | 1 | Gagne 1 Mana chaque fois qu'un ennemi meurt. |
| `regen_ring` | Anneau Régenérant | Rare | endOfTurn | heal | 2 | Restaure 2 PV à la fin de chaque tour. |
| `critical_lens` | Lentille de Focalisation | Rare | startOfRun | gain_crit | 15 | +15% de chance de critique de manière permanente pour toute la run. |
| `kunai` | Croc Kunaï | Rare | onAttackPlayed | charge_mastery_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise pour le combat. |
| `shuriken` | Shuriken | Rare | onAttackPlayed | charge_might_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Puissance pour le combat. |
| `incense_burner` | Encensoir | Rare | startOfTurn | charge_armor_turn | 8 | Tous les 4 tours, gagne 8 points d'Armure. |
| `lucky_clover` | Trèfle Chanceux | Epic | startOfRun | gain_luck | 1 | +1 Chance de manière permanente pour toute la run. |
| `energy_stone` | Pierre d'Énergie | Epic | startOfTurn | gain_mana | 1 | Gagne 1 Mana au début de chaque tour. |
| `phoenix_feather` | Plume de Phénix | Epic | startOfCombat | gain_mana | 2 | Gagne 2 Mana au début du combat. |
| `fortune_dice` | Dés de Fortune | Legendary | startOfRun | gain_luck | 2 | +2 Chance de manière permanente pour toute la run. |
| `crown_kings` | Couronne des Rois | Legendary | startOfRun | gain_mana | 1 | Gagne 1 Mana Max de manière permanente au début de la run. |
| `scholars_satchel` | Besace de l'Érudit | Legendary | startOfRun | increase_cards_per_turn | 1 | Pioche 1 carte supplémentaire au début de chaque tour, pour toute la run. |
| `bounty_ledger` | Registre des primes | Rare | startOfRun | increase_elite_card_chance | 25 | Après un combat d'élite, +25 % de chance de trouver une seconde carte. |
| `gleaners_pouch` | Sacoche du glaneur | Rare | startOfRun | increase_combat_card_drops | 1 | Après un combat normal, trouvez une carte de plus. |
| `grindstone` | Meule | Legendary | startOfRun | increase_boss_rune_sharpens | 1 | La récompense du Boss d'XP fait gagner un niveau à une rune de plus, si l'une peut encore monter. |

> [!NOTE]
> **`increase_cards_per_turn` est le premier `effectType` qui touche au deck.** Il agit sur
> `RunState.cardsPerTurn` via `applyRunRuleModifier`, et non sur `EntityStats` — lequel est
> partagé avec les ennemis, qui n'ont pas de deck. Il n'a de sens qu'en `startOfRun` : une
> variante par combat ou par tour cumulerait indéfiniment. Sa rareté `legendary` est
> calibrée sur la Couronne des Rois (+1 Mana Max permanent), le seul autre effet permanent
> qui modifie une règle de run plutôt qu'une statistique.
> Voir [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).

> [!NOTE]
> **Trois règles de run de plus, sur le même modèle** (lot E3 de P-43 — branche de la vague 3, en
> attente du propriétaire, [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)) : le
> *Registre des primes* et la *Sacoche du glaneur* (D31, D57, toutes deux rares) modulent la
> trouvaille ([`_rules/06-00`](06-00-economie-de-jeu.md) §6.4), la *Meule* (D42(a), légendaire)
> la récompense du boss « XP » ([`_rules/02-1`](02-1-generation-procedurale-de-carte.md)). Chacune
> écrit un champ de `RunState` — `eliteCardChanceBonus`, `extraCombatCards`,
> `extraBossRuneSharpens` — par `PlayerStatsManager.applyRunRuleModifier`, le seul à en recevoir
> les accumulateurs, et le défait symétriquement dans `removeRelicEffect` : à l'Autel comme au
> *Colporteur*, qui cède une relique par `RunController.loseRelic`. Plusieurs exemplaires
> s'additionnent. Aucune n'est exclue du tirage de la relique que vise le *Colporteur*.

**Cycle de vie des triggers** :
- `startOfRun` : Appliqué immédiatement à l'ajout (`InventoryController.addRelic()`), et **retiré symétriquement** par `removeRelicEffect()` lors d'un sacrifice à l'Autel d'Échange — ou, sur la branche de la vague 3, de la relique cédée au *Colporteur* (`RunController.loseRelic`).
- `startOfCombat` : Via `RunController.startCombat()`.
- `startOfTurn` / `endOfTurn` : Via `RunController.startTurn()` / `TraitSystem.onTurnEnd()`.
- `onCardPlayed` : Via `CombatController.applyPlayerCardPlay()`.
- `onAttackPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.attack`.
- `onSkillPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.skill`.
- `onPowerPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.power`.
- `onEnemyKilled` : Via `CombatController._cleanDeadEnemies()` → `RunController.onEnemyKilled()`.

**Système de Charges (Reliques Actives)** :
Les reliques à charges accumulent des compteurs représentés par des effets de statut temporaires ou de combat sur le Héros. Une fois le seuil de charges atteint, le compteur est réinitialisé et l'effet bénéfique s'applique :
- **Kunaï** (`kunai`) : Génère `kunai_charge` (durée 1, donc réinitialisé à chaque tour). À 3 charges, reset et ajoute +1 Maîtrise pour le combat via le statut temporaire `'mastery'` (durée 99) — valable pour n'importe quel passif qui déclare un bloc `mastery` ([`_rules/03-2`](03-2-gestion-de-l-armure.md)).
- **Shuriken** (`shuriken`) : Génère `shuriken_charge` (durée 1). À 3 charges, reset et ajoute +1 Puissance pour le combat (`might` de 99 tours, source `relic:shuriken`).
- **Plume de Scribe** (`pen_nib`) : Génère `pen_nib_charge` (durée 99). À 5 charges, reset et ajoute +3 Puissance pour le tour en cours (`might` de 1 tour, source `relic:pen_nib`). Chaque relique a sa source : les deux Puissances ne se confondent pas, chacune garde sa durée ([ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md)). Les noms `strength` et `charge_strength_*` que portait cette fiche sont devenus `might` et `charge_might_*` avec [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) — corrigé le 2026-10-02.
- **Encensoir** (`incense_burner`) : Génère `incense_charge` (durée 99). À 4 charges, reset et octroie +8 points d'Armure.
