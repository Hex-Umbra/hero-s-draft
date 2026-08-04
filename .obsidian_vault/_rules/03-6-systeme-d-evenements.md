### 3.6. 🎪 Système d'Événements

**2 événements** dans `events.json`, chacun avec 3 choix narratifs :

| Événement | Choix | Actions |
|:---|:---|:---|
| `mysterious_altar` (Autel Mystérieux) | Sacrifier du sang | `take_damage: 15`, `gain_strength: 3` |
| | Offrande d'or | `spend_gold: 30`, `gain_max_hp: 10` |
| | Prier et partir | aucune action |
| `goblin_merchant` (Marchand Gobelin) | Acheter un sac | `spend_gold: 25`, `gain_relic` (tirage influencé par luck) |
| | Voler le gobelin | `take_damage: 10`, `gain_gold: 50` |
| | Aider à se cacher | `gain_gold: 15` |

**Algorithme de rareté pour `gain_relic`** (influencé par `luck`) :
| Rareté | Proba base (luck=0) | Bonus par point de luck |
|:---|:---|:---|
| Legendary | 1% | +0.5% |
| Epic | 5% | +1.0% |
| Rare | 14% | +2.0% |
| Uncommon | 20% | +3.0% |
| Common | Reste | — |
