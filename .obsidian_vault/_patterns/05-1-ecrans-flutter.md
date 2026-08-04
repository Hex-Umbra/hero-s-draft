### 5.1. Écrans Flutter (`lib/ui/screens/`)

| Écran | Classe | Pattern | Responsabilité |
|:---|:---|:---|:---|
| `HomeScreen` | `ConsumerWidget` | `ref.watch(gameDataLoaderProvider)`, `FutureProvider` sur `SaveService.hasSave()` | Écran d'accueil, chargement données, boutons "New Game" / "Dictionary" et (depuis v3.2.0) "Continuer" conditionnel + dialogues de confirmation d'écrasement et de contenu manquant au chargement |
| `ClassSelectionScreen` | `ConsumerWidget` | `ref.watch(gameDataLoaderProvider)` | Affiche 3 héros sous `ScreenScaffold` (mode sombre) et `PageHeader`, déclenche `startNewRun()` |
| `StarterDeckDraftScreen` | `ConsumerStatefulWidget` | `ref.watch(gameDataLoaderProvider)`, `ref.read(deckProvider.notifier)` | Choix initial de 5 cartes globales parmi le catalogue complet via `CardDraftLayout` et `UiCard.fromData` + cartes de classe uniques résolues via compétences |
| `MapScreen` | `ConsumerStatefulWidget` | `ref.watch(runProvider)`, `ref.watch(inventoryProvider)` | **God Class (2471 lignes)** — CustomPainter, pan/zoom, navigation sous `ScreenScaffold` (mode parchemin) et `GoldIndicator` (mode parchemin), overlay bloquant « LEVEL UP ! ». |
| `GameScreen` | `ConsumerStatefulWidget` | Tous les providers | **God Class (1667 lignes)** — embed `GameWidget<HerosDraftGame>`, overlays privés (sans draft), orchestration combat, sortie directe sur level up. |
| `ShopScreen` | `ConsumerWidget` | `ref.watch(inventoryProvider)` | Achat/purge de cartes et reliques thématiques sous `ScreenScaffold` (mode sombre), `PageHeader`, `GoldIndicator` et `UiCard.fromData`/`fromInstance`. |
| `EventScreen` | `ConsumerWidget` | `ref.watch(runProvider)` | Événements narratifs à choix branchus affichés sous `ScreenScaffold` (mode sombre) et `PageHeader`. |
| `RestScreen` | `ConsumerWidget` | `ref.watch(runProvider)`, `ref.watch(deckProvider)` | Feu de camp sous `ScreenScaffold` (mode sombre) et `PageHeader` : Soin (30%), Forge (upgrade via `ForgeUpgradeDialog`), Oubli. |
| `DraftScreen` | `ConsumerStatefulWidget` | `ref.read(deckProvider.notifier)` | Draft post-combat : 3 choix de cartes (utilise `ScreenScaffold` et `PageHeader`). |
| `BossCardDraftScreen` | `ConsumerStatefulWidget` | `ref.read(rewardProvider.notifier)` | Écran de sélection post-boss de gauche (x=0) sous `CardDraftLayout` et `UiCard.fromData` : affiche 5 cartes aléatoires du deck du joueur pour en cloner 2. |
| `DictionaryScreen` | `ConsumerWidget` | `ref.watch(gameDataLoaderProvider)` | Catalogue filtrable de toutes les cartes et reliques affiché sous `ScreenScaffold` (mode sombre), `PageHeader` et `UiCard.fromData`. |

**Pattern de navigation** : 100% via `Navigator.of(context).push(MaterialPageRoute(...))` — aucun routeur centralisé.
