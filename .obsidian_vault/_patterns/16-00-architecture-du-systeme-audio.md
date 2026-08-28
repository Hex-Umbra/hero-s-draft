## 16. Architecture du Système Audio

Trois couches sous `lib/services/audio/` (et non `lib/game/services/` : l'audio est appelé
aussi bien depuis le combat Flame que depuis des écrans purement Flutter — accueil, boutique,
draft). Pourquoi ces décisions plutôt que des appels dispersés ou un bus d'événements :
[ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md). Le catalogue des
14 moments et la chaîne de repli vivent dans
[`_rules/09-00`](../_rules/09-00-systeme-audio.md).

### 16.1. Les trois couches

1. **Backend** (`AudioBackend`, `lib/services/audio/audio_backend.dart`) — la seule couche qui
   parle à une bibliothèque de lecture, et la seule dont une implémentation importe
   `flame_audio` (`FlameAudioBackend`, seule classe du projet à le faire). `SilentAudioBackend`
   est un no-op complet et le défaut du provider. Aucune des deux ne lève jamais une exception.
2. **Résolution** — `AudioDirector` (bruitages) et `MusicConductor` (musique). Deux
   `Provider`s sans état métier propre : ils reçoivent `AudioData` (le catalogue) et une
   fonction `AudioSettings Function() settings` **à la construction**, jamais un `ref` Riverpod
   capturé en interne — ce qui les garde testables sans `ProviderContainer`.
3. **Réglages** — `AudioSettingsNotifier extends Notifier<AudioSettings>`
   (`audio_providers.dart`), le seul état Riverpod véritable du sous-système : master / sfx /
   music / coupure, persistés via `SettingsService` dans une clé `shared_preferences` dédiée.

### 16.2. Deux chemins d'accès au directeur, jamais mélangés

> [!IMPORTANT]
> `flutter_riverpod` n'est importé par **aucun** fichier de `lib/game/components/` (vérifié par
> recherche sur le dossier). C'est un invariant de la séparation triangulaire de `CLAUDE.md`
> (`_patterns/01-00`), pas une coïncidence : un composant Flame qui l'importerait casserait la
> raison d'être de l'injection ci-dessous.

- **Couche Flame** (`HerosDraftGame`, tout `lib/game/components/`, tout `lib/game/systems/`) :
  `game.audio.onMoment(...)` — c'est la seule méthode que la couche Flame appelle sur
  `game.audio`. `AudioDirector` expose aussi `preloadAll()` (`audio_director.dart:39`), mais
  celle-ci n'est jamais appelée via `game.audio` : `audio_providers.dart` l'appelle une seule
  fois au démarrage, directement sur l'instance issue du provider. `onScene` n'existe
  pas sur `AudioDirector` : c'est une méthode de `MusicConductor`, jamais atteint depuis Flame
  (la couche qui l'appelle est en §16.3). `audio` est un **champ**
  `final AudioDirector audio;` de `HerosDraftGame`, rempli **une seule fois** par `GameScreen`
  via `ref.read(audioDirectorProvider)` au moment de la construction du jeu
  (`game_screen.dart:247`). `HerosDraftGame` n'a structurellement aucun accès à Riverpod : ses
  14 autres collaborateurs externes (`onEnemiesDead`, `onPhaseChanged`, `onPlayCard`,
  `onExecuteSkill`... — `heros_draft_game.dart:61-75`) sont déjà des callbacks injectés par
  constructeur, pas des providers lus en interne.
- **Pourquoi un champ et pas un quinzième callback.** Un callback par moment de jeu ferait
  exploser un constructeur déjà large ; le directeur est précisément l'objet conçu pour être
  appelé directement, pas remonté événement par événement.
- **Couche Riverpod** (contrôleurs : `DeckNotifier`, `TurnPhaseManager`, `PlayerStatsManager`,
  les stratégies d'effet sous `lib/game/services/effects/`) : `ref.read(audioDirectorProvider)`
  directement, sans passer par `game.audio`.
- **La lecture du provider n'a lieu qu'en un seul point côté Flame** — la construction dans
  `GameScreen` — jamais à l'intérieur d'un composant. C'est ce qui permet à `game.audio` de
  rester un simple champ final plutôt qu'un accès Riverpod déguisé.

### 16.3. `onScene` est idempotent — c'est ce qui autorise son appel depuis `build()`

`MusicConductor.onScene(scene)` retourne immédiatement si `scene == _current`
(`music_conductor.dart:41`). Chaque écran appelle
`ref.read(musicConductorProvider).onScene(MusicScene.xxx)` sans condition alentour — y compris
depuis des méthodes rejouées à chaque rebuild ou à chaque retour arrière dans la pile de
navigation. C'est la garde **interne** au conducteur, et non une discipline d'appel côté écran,
qui empêche un redémarrage de piste à chaque frame : naviguer Accueil → Notes de version →
Accueil ne relance jamais la musique.

### 16.4. La frontière conducteur / backend sur le fondu

`fadeMs` traverse tout le contrat (`AudioBackend.playLoop`/`stopLoop`, puis `MusicConductor`)
mais **n'est pas encore honoré**. `FlameAudioBackend.playLoop`/`stopLoop` reçoivent le
paramètre et l'ignorent : `FlameAudio.bgm` n'expose aucun fondu enchaîné natif, la transition
est franche dans cette version. Le paramètre reste dans la signature pour que le fondu puisse
s'ajouter **dans `FlameAudioBackend` uniquement**, plus tard, sans toucher au contrat
`AudioBackend` ni à `MusicConductor` — c'est la frontière que ce chantier a posée précisément
pour que l'ajout futur soit un changement d'implémentation, jamais un changement de contrat.

> [!WARNING]
> Ne pas lire la présence de `fadeMs` dans une signature comme une preuve que le fondu
> fonctionne. Tant que `FlameAudioBackend` ne l'implémente pas, toute transition de musique —
> changement de scène comme reprise après coupure — est instantanée.

### 16.5. `SoundData.expectedFiles` — propriétaire unique de la dérivation de variantes

`SoundData.expectedFiles` (`lib/models/data/audio_data.dart`) est le seul endroit du code qui
calcule les noms de fichiers numérotés d'un son à variantes (`impact_normal.wav` +
`variants: 3` → `_1`/`_2`/`_3`, suffixe inséré avant l'extension). Deux consommateurs l'appellent
plutôt que de recalculer la règle : `AudioDirector` (`preloadAll()` pour le préchargement,
`_pickFile()` pour le tirage aléatoire à la lecture) et
`test/unit/audio/audio_sourcing_report_test.dart` (calcul de ce qui doit exister sur le disque
pour le rapport de sourcing). **Une première version du rapport avait dupliqué cette
dérivation avant d'être recentrée sur `expectedFiles`** — toute évolution future du contrat de
nommage (`_rules/09-00` §9.3) ne doit donc toucher qu'un seul endroit ; en ajouter un second
reproduirait exactement la divergence déjà corrigée une fois.

### 16.6. La reprise de `MusicConductor` après coupure — testée, pas accidentelle

**Invariant central : `_current` est non nul si et seulement si le backend a une boucle
réellement active pour cette scène.** `onScene()` et `refreshVolume()` le maintiennent tous les
deux, symétriquement : dès que l'un ou l'autre arrête la boucle (volume effectif nul, que la
cause soit une coupure, un curseur à 0, ou une scène atteinte alors que le son était déjà coupé),
il stocke la scène dans `_pending` **et** met `_current` à `null`. Dès que l'un ou l'autre
démarre une boucle, il vide `_pending`.

Cet invariant est ce qui permet à `refreshVolume()` de choisir correctement entre deux
comportements quand le volume redevient positif :
- **`_current` non nul (scène inchangée, boucle déjà active)** : ajuste le volume en place via
  `setVolume`, sans redémarrer la piste — un simple glissement de curseur ne doit pas faire
  recommencer la musique depuis le début.
- **`_current` nul (`_pending` retient la scène arrêtée)** : redémarre en repassant par
  `onScene(_pending)`, qui pose `_current` et relance la boucle puisque `scene != _current` (nul)
  est vrai.

C'est ce second cas qui fait que la musique **reprend** après une coupure, y compris quand
l'écran de réglages est le seul écran visité entre la coupure et le démutage : il n'a pas de
scène propre (`music_scene.dart` : sa scène est héritée) et n'appelle donc jamais `onScene()` —
la reprise doit donc pouvoir se faire **depuis `refreshVolume()` seul**, sans dépendre d'un
écran qui rappellerait `onScene()` depuis son `build()`.

`onScene()` reste idempotent au sens de §16.3 : redemander la scène déjà active (`_current`
non nul, donc réellement en cours) est toujours un no-op immédiat, avant même de regarder le
volume.

> [!IMPORTANT]
> Régression verrouillée par `test/unit/audio/music_conductor_test.dart` :
> *« refreshVolume() redemarre seul la piste apres une coupure, sans aucun appel a onScene
> entre les deux »* couvre la reprise elle-même ; *« la musique reprend quand on redemande la
> meme scene apres une coupure puis un demutage »* couvre le cas où un écran rappelle bien
> `onScene()` après coup ; *« refreshVolume() ajuste le volume en place quand la scene ne
> change pas »* couvre le chemin `setVolume`. Casser l'invariant ci-dessus — par exemple en ne
> nullifiant `_current` que d'un seul côté — fait échouer l'un ou l'autre.
