### 3.6. 🎪 Système d'Événements

**5 événements** sous `assets/data/events/`, un fichier par événement, chacun avec 3 choix
narratifs — **re-mesuré le 2026-09-05** (`ls assets/data/events/*.json | wc -l`) ; cette fiche
en annonçait 2 depuis une date inconnue.

| Événement | Choix | Actions |
|:---|:---|:---|
| `mysterious_altar` (Autel Mystérieux) | Sacrifier du sang | `take_damage: 15`, `gain_strength: 3` |
| | Offrande d'or | `spend_gold: 30`, `gain_max_hp: 10` |
| | Prier et partir | aucune action |
| `goblin_merchant` (Marchand Gobelin) | Acheter un sac | `spend_gold: 25`, `gain_relic` (tirage influencé par luck) |
| | Voler le gobelin | `take_damage: 10`, `gain_gold: 50` |
| | Aider à se cacher | `gain_gold: 15` |
| `abandoned_camp` (Le Feu de Camp Abandonné) | Fouiller les sacs restants | `take_damage: 10`, `gain_relic: 1` |
| | Se reposer près du feu | `heal: 15` |
| | Consommer les provisions | `spend_gold: 25`, `heal: 30` |
| `blessed_fountain` (La Fontaine Bénie) | Boire l'eau bénie | `heal: 25` |
| | Purifier son esprit | `gain_max_hp: -12`, `gain_strength: 1` |
| | Jeter une pièce dans la fontaine | `spend_gold: 20`, `gain_max_hp: 8` |
| `forgotten_tomb` (Le Tombeau Oublié) | Piller le sarcophage | `gain_gold: 100`, `take_damage: 18` |
| | Inspecter les gravures murales | `gain_max_hp: 10` |
| | Respecter le repos des morts | `gain_gold: 15` |

**Algorithme de rareté pour `gain_relic`** (influencé par `luck`) :
| Rareté | Proba base (luck=0) | Bonus par point de luck |
|:---|:---|:---|
| Legendary | 1% | +0.5% |
| Epic | 5% | +1.0% |
| Rare | 14% | +2.0% |
| Uncommon | 20% | +3.0% |
| Common | Reste | — |
