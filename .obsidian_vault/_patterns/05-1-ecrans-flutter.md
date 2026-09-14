### 5.1. Écrans Flutter (`lib/ui/screens/`)

| Écran | Classe | Pattern | Responsabilité |
|:---|:---|:---|:---|
| `HomeScreen` | `ConsumerStatefulWidget` | `FutureBuilder` sur `SaveService.hasSave()`, `setState` au retour de chaque `push` ([ADR-073](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md)) | Menu joueur **aligné à gauche**, boutons à largeur commune : « Continuer » conditionnel, Jouer, Tutoriel, Dictionnaire, Patch Notes, Réglages, **Quitter** (sortie par plateforme, masqué sur web et iOS). En `kDebugMode`, **colonne de debug à droite** (Run Debug, Éditeur de contenu), repliée sous le menu sous 700 px — [ADR-091](../_adr/ADR-091-menu-d-accueil-quitter-par-plateforme-et-retrait-du.md) |
| `ClassSelectionScreen` | `ConsumerWidget` | `ref.watch(gameDataLoaderProvider)` | Affiche les héros triés par `displayOrder` sous `ScreenScaffold` (mode sombre) et `PageHeader` **avec bouton retour** vers l'accueil ; pousse `StarterDeckDraftScreen` |
| `StarterDeckDraftScreen` | `ConsumerStatefulWidget` | `ref.read(gameDataLoaderProvider)`, `ref.read(deckProvider.notifier)` | Choix initial de 5 cartes globales via `CardDraftLayout` (**`onBack`** : retour à la sélection de classe) et `UiCard.fromData`, + cartes de classe (`HeroSkillsLink.getHeroCards`) ; `startNewRun()` à la validation seulement |
| `ContentEditorScreen` | `ConsumerStatefulWidget` | `ref.watch(projectRootProvider)`, `ref.read(contentFileSystemProvider)` | Éditeur de contenu, `kDebugMode` seulement — [`_patterns/19-00`](19-00-editeur-de-contenu-seam-disque-validation-ecriture.md) |
| `MapScreen` | `ConsumerStatefulWidget` | `ref.watch(runProvider)`, `ref.watch(inventoryProvider)` | **God Class (2471 lignes)** — CustomPainter, pan/zoom, navigation sous `ScreenScaffold` (mode parchemin) et `GoldIndicator` (mode parchemin), overlay bloquant « LEVEL UP ! ». |
| `GameScreen` | `ConsumerStatefulWidget` | Tous les providers | **God Class (1667 lignes)** — embed `GameWidget<HerosDraftGame>`, overlays privés (sans draft), orchestration combat, sortie directe sur level up. |
| `ShopScreen` | `ConsumerWidget` | `ref.watch(inventoryProvider)` | Achat/purge de cartes et reliques thématiques sous `ScreenScaffold` (mode sombre), `PageHeader`, `GoldIndicator` et `UiCard.fromData`/`fromInstance`. |
| `EventScreen` | `ConsumerWidget` | `ref.watch(runProvider)` | Événements narratifs à choix branchus affichés sous `ScreenScaffold` (mode sombre) et `PageHeader`. |
| `RestScreen` | `ConsumerWidget` | `ref.watch(runProvider)`, `ref.watch(deckProvider)` | Feu de camp sous `ScreenScaffold` (mode sombre) et `PageHeader` : Soin (30%), Forge (upgrade via `ForgeUpgradeDialog`), Oubli. |
| `DraftScreen` | `ConsumerStatefulWidget` | `ref.read(deckProvider.notifier)` | Draft post-combat : 3 choix de cartes (utilise `ScreenScaffold` et `PageHeader`). |
| `BossCardDraftScreen` | `ConsumerStatefulWidget` | `ref.read(rewardProvider.notifier)` | Écran de sélection post-boss de gauche (x=0) sous `CardDraftLayout` et `UiCard.fromData` : affiche 5 cartes aléatoires du deck du joueur pour en cloner 2. |
| `DictionaryScreen` | `ConsumerWidget` | `ref.watch(gameDataLoaderProvider)` | Catalogue filtrable de toutes les cartes et reliques affiché sous `ScreenScaffold` (mode sombre), `PageHeader` et `UiCard.fromData`. |

**Pattern de navigation** : 100% via `Navigator.of(context).push(MaterialPageRoute(...))` — aucun routeur centralisé.
