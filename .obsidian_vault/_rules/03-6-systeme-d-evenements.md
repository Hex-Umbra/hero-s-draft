### 3.6. 🎪 Système d'Événements

**7 événements** sous `assets/data/events/`, un fichier par événement, avec 2 ou 3 choix
narratifs — **re-mesuré le 2026-10-04** (`ls assets/data/events/*.json | wc -l`) sur la branche
de la vague 3, qui en ajoute deux, le *Colporteur* et le *Rémouleur* (5 sur `main`). Tous entrent
dans le tirage uniforme de `initializeEvent` : chacun une fois sur sept.

| Événement | Choix | Actions |
|:---|:---|:---|
| `mysterious_altar` (Autel Mystérieux) | Sacrifier votre sang | `take_damage: 15`, `gain_might: 1` |
| | Faire une offrande d'or | `spend_gold: 50`, `gain_max_hp: 10` |
| | Prier et partir | aucune action |
| `goblin_merchant` (Marchand Gobelin) | Acheter une relique mystérieuse | `spend_gold: 40`, `gain_relic: 1` (tirage influencé par luck) |
| | Voler le gobelin | `gain_gold: 50`, `take_damage: 12` |
| | L'aider à se cacher | `take_damage: 15`, `gain_relic: 1` |
| `abandoned_camp` (Le Feu de Camp Abandonné) | Fouiller les sacs restants | `take_damage: 10`, `gain_relic: 1` |
| | Se reposer près du feu | `heal: 15` |
| | Consommer les provisions | `spend_gold: 25`, `heal: 30` |
| `blessed_fountain` (La Fontaine Bénie) | Boire l'eau bénie | `heal: 25` |
| | Purifier son esprit | `gain_max_hp: -12`, `gain_might: 1` |
| | Jeter une pièce dans la fontaine | `spend_gold: 20`, `gain_max_hp: 8` |
| `forgotten_tomb` (Le Tombeau Oublié) | Piller le sarcophage | `gain_gold: 100`, `take_damage: 18` |
| | Inspecter les gravures murales | `gain_max_hp: 10` |
| | Respecter le repos des morts | `gain_gold: 15` |
| `relic_peddler` (Le Colporteur, D23) | Vendre votre relique la plus faible | `trade_relic: 40` — une relique visée |
| | L'échanger contre des remèdes | `trade_relic: 0`, `heal_percent: 20` — une relique visée, et `requiresHpBelowPercent: 50` |
| | Passer votre chemin | aucune action |
| `wandering_grinder` (Le Rémouleur, D42(b)) | Lui confier une rune | `lose_hp_percent: 10`, `sharpen_rune: 1` — une rune affûtable, et des PV au-dessus du coût |
| | Passer votre chemin | aucune action |

Table **relue fichier par fichier le 2026-10-04** : `gain_strength`, que cette fiche écrivait, est
`gain_might` depuis [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md), et les
valeurs de l'Autel Mystérieux et du Marchand Gobelin avaient dérivé de leurs fichiers.

**Les actions et la condition d'E3** (branche de la vague 3, en attente du propriétaire —
[ADR-107](../_adr/ADR-107-trouvaille-et-progression.md), A2, A4, A19 à A22), composables comme
les autres et bornées au chargement par `EventAction.fromJson` :

| Type | `value` | Effet |
|:---|:---|:---|
| `trade_relic` | entier ≥ 0, l'or par rang | La **relique visée** quitte l'inventaire par `RunController.loseRelic` — sa règle de run défaite, puis la relique retirée —, contre `value × (rang de rareté + 1)` or : 40 à 200 au *Colporteur*, rien à 0 |
| `heal_percent` | 1 à 100 | Soigne `round(PV max × value / 100)` |
| `lose_hp_percent` | 1 à 100 | Retire autant de PV ; le choix n'est sélectionnable que si les PV courants dépassent ce montant, la règle de `take_damage` |
| `sharpen_rune` | 1, seule valeur admise | Monte d'un niveau, **sans or**, la rune que le joueur a choisie, par `DeckNotifier.raiseRuneLevel` sous le plafond effectif de la run |

- **La relique visée** est tirée **une fois, à l'ouverture** de l'événement, parmi les reliques de
  plus petite rareté, au hasard parmi les ex æquo (`EventState.tradedRelic`) ; les badges la
  nomment avant tout choix. Sans relique — un inventaire vide, courant à l'acte 1 —, ils disent
  « Aucune relique à céder », et les deux choix d'échange restent inactifs.
- **`requiresHpBelowPercent: p`** sur un choix : sélectionnable si `PV × 100 < PV max × p`.
- **La rune du *Rémouleur*** : le joueur choisit la carte, puis la rune, dans la sélection et le
  dialogue du feu de camp **en mode sans or** — le bouton dit « Choisir », sans coût ni solde
  affiché, et n'écrit rien ; l'événement monte la paire rendue. Annuler n'engage rien : ni le
  choix, ni les PV. Sans rune affûtable, le choix est grisé et son badge dit « Aucune rune à
  affûter ».
- **La condition d'un choix** se calcule en un seul endroit, `EventController.isChoiceSelectable`,
  que l'écran appelle pour chaque bouton : les PV et l'or, plus deux faits que le modèle reçoit
  calculés — `hasTradedRelic` et `hasSharpenableRune` (`EventChoice.isSelectable`, qui n'importe
  rien de `lib/game/`).
- **Le retour système, une fois un choix fait, termine la visite** : il résout le nœud comme le
  bouton de sortie, par le mécanisme du feu de camp et du Puits. Avant ce correctif, il ramenait à
  la carte sur un nœud non résolu, et rentrer y tirait un **nouvel** événement — un second choix
  dans le même nœud. Avant tout choix, le retour reste bloqué.

**Algorithme de rareté pour `gain_relic`** (influencé par `luck`) :
| Rareté | Proba base (luck=0) | Bonus par point de luck |
|:---|:---|:---|
| Legendary | 1% | +0.5% |
| Epic | 5% | +1.0% |
| Rare | 14% | +2.0% |
| Uncommon | 20% | +3.0% |
| Common | Reste | — |
