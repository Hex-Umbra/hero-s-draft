### Statut

✅ **Livré le 2026-08-23** — branche `docs/p45-fidelite-tutoriel`, 31 commits TDD.
Chantier **P-45** de `docs/ROADMAP.md` (Tier A). Amende [ADR-019](ADR-019-systeme-de-tutoriel-autonome-isolant-la-boucle-pri.md).
Conception : `docs/superpowers/specs/2026-08-22-p45-fidelite-du-tutoriel-design.md`.
Plan : `docs/superpowers/plans/2026-08-23-p45-fidelite-du-tutoriel.md`.

### Contexte

Un audit de fidélité a relevé **50 écarts** entre `lib/tutorial/` et le comportement réel du
jeu — valeurs de héros, règles d'armure et de statuts, contenu des récompenses, reliques,
jusqu'à une légende de carte inexacte. La cause n'était pas de la négligence ponctuelle mais
la règle elle-même : ADR-019 posait « zéro dépendance Riverpod » sans distinguer l'état de
run (`RunController`, `DeckNotifier`…) de la donnée immuable (`cards.json`, `heroes.json`…).
En interdisant les deux, elle forçait à **recopier à la main** chaque valeur pédagogique dans
des POJOs (`TutorialCard`, `TutorialEnemy`) et des chaînes en dur — puis le jeu a bougé sans
que ces copies suivent. ADR-019 avait d'ailleurs anticipé le risque (« duplication
fonctionnelle légère ») sans le chiffrer ; il s'est matérialisé en 50 écarts mesurés.

### Décision

**La règle « zéro dépendance Riverpod » devient « zéro provider d'*état* ».**

Les neuf providers d'état restent strictement interdits dans `lib/tutorial/`, car ce sont eux
qui portent le risque d'effet de bord sur la run de production :

| Provider | Déclaration |
|:---|:---|
| `runProvider` | `lib/game/controllers/run_controller.dart:474` |
| `deckProvider` | `lib/game/controllers/deck_controller.dart:387` |
| `combatProvider` | `lib/game/controllers/combat_controller.dart:447` |
| `inventoryProvider` | `lib/game/controllers/inventory_controller.dart:62` |
| `skillProvider` | `lib/game/controllers/skill_controller.dart:48` |
| `rewardProvider` | `lib/game/controllers/reward_controller.dart:280` |
| `shopProvider` | `lib/game/controllers/shop_controller.dart:386` |
| `eventProvider` | `lib/game/controllers/event_controller.dart:136` |
| `checkpointProvider` | `lib/game/controllers/checkpoint_controller.dart:13` |

`gameDataLoaderProvider` (`lib/services/game_data_service.dart`) est différent par nature :
un `FutureProvider` qui ne fait que lire `rootBundle` et met en cache un `GameDataRegistry`
immuable, sans aucun état de run. Il est désormais autorisé, mais **en un seul point** :
`lib/tutorial/tutorial_loader.dart`. Aucun autre fichier du dossier ne peut l'importer ni le
référencer.

**Le critère est exécutable, pas déclaratif.** `test/tutorial/tutorial_isolation_test.dart`
échoue si :
1. un fichier de `lib/tutorial/` autre que `tutorial_loader.dart` importe `flutter_riverpod` ;
2. un fichier de `lib/tutorial/` référence un des neuf providers d'état ci-dessus (ou l'ancien
   singleton `GameDataRegistry.instance`).

### Preuves dans le code

| Élément | Chemin |
|:---|:---|
| Frontière Riverpod unique | `lib/tutorial/tutorial_loader.dart` |
| Résolution fail-fast des fixtures contre le registre | `lib/tutorial/tutorial_fixtures.dart` |
| Garde-fou exécutable (2 tests) | `test/tutorial/tutorial_isolation_test.dart` |
| `FutureProvider` de données immuables amendé | `lib/services/game_data_service.dart` |
| Moteur local, aucun provider | `lib/tutorial/tutorial_engine.dart` |

### Conséquences

**Acquis.** Les valeurs de démonstration (PV de héros, dégâts, reliques, raretés) ne peuvent
plus diverger du jeu réel : elles sont lues dans le même `GameDataRegistry`, jamais
recopiées. Une évolution future des données casse un test de fixture avant d'atteindre un
joueur, au lieu de dériver silencieusement pendant des mois comme les 50 écarts d'origine.

**Coût accepté.** Le tutoriel dépend désormais du chargement des assets au démarrage :
`TutorialLoader` doit gérer un état `loading` (rare, le registre étant déjà en cache à ce
stade du parcours joueur) et un état `error` — deux états qu'un module 100 % local n'avait
jamais eu à considérer.

**Portée de l'amendement.** Le reste d'ADR-019 tient intact : module isolé sous
`lib/tutorial/`, moteur `ChangeNotifier` local, persistance de complétion par
`TutorialProgressService`. Seule la ligne « zéro dépendance Riverpod » de sa section
Décision est remplacée par la règle ci-dessus.
