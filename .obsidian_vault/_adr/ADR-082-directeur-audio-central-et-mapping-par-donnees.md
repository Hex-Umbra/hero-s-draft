### Statut

✅ **Livré le 2026-08-25** — branche `feat/p03-systeme-audio`, 28 commits (spec, plan et TDD).
Chantier **P-03** de `docs/ROADMAP.md` (Tier S, dernier chantier ouvert du Jalon 1 « Socle »).
Conception : `docs/superpowers/specs/2026-08-24-p03-systeme-audio-design.md`.

### Contexte

Le projet n'avait aucune dépendance audio, aucun fichier son, et un unique
`// TODO: Audio Hook` (`floating_text.dart:166`) — le seul TODO du projet toutes catégories
confondues. Trois contraintes, prises ensemble, excluaient l'implémentation naïve :

1. **Le son doit arriver avant les fichiers.** Le sourcing (~15 bruitages, 4 musiques) est mené
   en parallèle du code ; le jeu tournerait plusieurs semaines avec un catalogue troué. Un
   moteur qui suppose ses assets présents produirait un jeu qui plante ou inonde la console.
2. **Le moment du déclenchement décide de la synchronisation.** La séquence de combat est
   explicitement étalée dans le temps (`_enemyRipostePhase`, délais dégressifs,
   `Future.delayed`) : l'état change à l'instant T, l'animation correspondante joue à T+300 ms.
   Brancher le son sur le changement d'état plutôt que sur l'animation produirait un son
   systématiquement en avance sur son image.
3. **Le mapping ne peut pas vivre dans le code.** Le projet est piloté à 100 % par la donnée ;
   un catalogue d'événements codé en dur ferait de l'audio la seule exception.

### Décision

**D1 — Directeur central, deux méthodes, rien d'autre.** `AudioDirector.onMoment(GameMoment,
{AudioSource? source})` et `MusicConductor.onScene(MusicScene)` sont les seuls points d'entrée :
le code de jeu déclare un moment ou une scène, jamais un fichier. Toute la résolution — donc
toute la gestion de l'asset absent — tient dans ces deux objets. Ils sont atteints par **deux
chemins volontairement différents** : la couche Flame (`HerosDraftGame`, `lib/game/components/`,
`lib/game/systems/`) les reçoit comme **champs injectés par constructeur**
(`HerosDraftGame.audio`, posé par `GameScreen` via `ref.read(audioDirectorProvider)` à la
construction du jeu, `game_screen.dart:247`), parce que `HerosDraftGame` n'a structurellement
aucun accès à Riverpod ; les contrôleurs Riverpod (`DeckNotifier`, `TurnPhaseManager`,
`PlayerStatsManager`, les stratégies d'effet) les lisent directement par
`ref.read(audioDirectorProvider)`. Détail de cette frontière et invariant vérifié (§16.2) :
[`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md).

**D2 — Mapping par données.** `assets/data/audio.json` (chargé par `gameDataLoaderProvider`,
exposé dans `GameDataRegistry.audio`) porte `sounds`, `moments` et `music`, avec une chaîne de
repli à 4 niveaux résolue par `AudioDirector._resolve()`. Un son propre à une carte, un ennemi
ou une relique s'ajoute par un champ JSON (`sfx`), sans une ligne de Dart. Catalogue complet :
[`_rules/09-00`](../_rules/09-00-systeme-audio.md).

**D3 — Les appels se posent aux points d'animation, pas aux changements d'état.** Conséquence
directe du point 2 du Contexte : synchronisation son/image par construction, jamais par
rattrapage. C'est ce qui interdit un bus d'événements générique (D8).

**D4 — `SilentAudioBackend` est le défaut ; `main.dart` est le seul endroit qui branche
`FlameAudioBackend`.** `audioBackendProvider` vaut `const SilentAudioBackend()` par défaut
(`audio_providers.dart`) ; seul `main.dart:17` le surcharge par
`audioBackendProvider.overrideWithValue(FlameAudioBackend())`. Inverse du réflexe habituel
(défaut réel, surcharge en test) : le défaut réel aurait imposé de modifier 51 fichiers de test
pour que `flutter test` reste muet. Les 295 tests qui existaient avant ce chantier n'ont pas été
touchés.

**D5 — L'audio ne peut jamais casser ni ralentir le jeu.** Fichier absent, `audio.json`
malformé, backend en échec à l'initialisation → dégradation silencieuse à chaque fois (voir
tableau au §Conséquences de la conception, §9). Asymétrie assumée avec `SaveService`, qui
échoue durement : une sauvegarde corrompue est une perte de données, un son absent est
cosmétique.

**D6 — Les réglages vivent dans une clé `shared_preferences` distincte de `SaveService`.**
`GameOverScreen` efface la sauvegarde de run à la mort du héros ; le volume ne doit pas mourir
avec le héros. `SettingsService` retombe silencieusement sur les valeurs par défaut si le JSON
est illisible — contrairement à `SaveService`, perdre son réglage de volume ne justifie pas un
écran d'erreur.

**D7 — Le catalogue est déclaré avant d'exister, gardé par deux garde-fous asymétriques.**
`test/unit/audio/audio_catalogue_test.dart` (bloquant, 2 tests : tout son référencé par un
moment est déclaré ; tout champ `sfx` d'un JSON de contenu pointe vers un son déclaré) attrape
les fautes de frappe. `test/unit/audio/audio_sourcing_report_test.dart` (non bloquant, aucune
assertion) liste les fichiers déclarés mais absents du disque — c'est le tableau de bord du
sourcing, et il est **conçu pour ne jamais rougir la CI**. Les deux gardent le même catalogue
mais n'ont pas le même métier : l'un protège la cohérence, l'autre mesure l'avancement.

**D8 — Pas de bus d'événements de jeu.** Rejeté, pas oublié. Un bus émettrait au changement
d'état, donc en avance sur l'image (D3/Contexte point 2) ; le corriger imposerait d'émettre
depuis la séquence d'animation elle-même, ce qui n'est plus qu'une indirection par-dessus D3
sans bénéfice net.

> [!NOTE]
> **Condition de réouverture explicite.** Le bus vaudra son coût quand un **second abonné**
> existera au-delà de l'audio — l'historique des runs (**P-11**), les vibrations, les succès.
> Un seul abonné ne justifie pas l'indirection ; ADR à rouvrir au moment où le deuxième se
> présente, pas avant.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Point d'entrée bruitages | `AudioDirector.onMoment` — `lib/services/audio/audio_director.dart` |
| Point d'entrée musique | `MusicConductor.onScene` — `lib/services/audio/music_conductor.dart` |
| Champ injecté côté Flame | `HerosDraftGame.audio` — `lib/game/heros_draft_game.dart` |
| Couture d'injection | `GameScreen._game = HerosDraftGame(audio: ref.read(audioDirectorProvider), ...)` — `lib/ui/screens/game_screen.dart:247` |
| Contrat de données | `AudioData`, `SoundData`, `MomentSounds` — `lib/models/data/audio_data.dart` |
| Catalogue | `assets/data/audio.json` |
| Défaut silencieux + seule surcharge réelle | `audioBackendProvider` (`lib/services/audio/audio_providers.dart`) et `lib/main.dart:17` |
| Réglages, clé dédiée | `SettingsService` (`lib/services/settings_service.dart`), `AudioSettingsNotifier` (`audio_providers.dart`) |
| Garde-fou bloquant | `test/unit/audio/audio_catalogue_test.dart` |
| Garde-fou non bloquant (sourcing) | `test/unit/audio/audio_sourcing_report_test.dart` |

### Conséquences

**Acquis**

- Un seul objet à connaître pour ajouter un son à n'importe quel moment de jeu, et un seul champ
  JSON (`sfx`) pour en donner un propre à une carte, un ennemi ou une relique.
- Les 295 tests qui existaient avant ce chantier n'ont subi **aucune modification** : la
  couture silencieuse par défaut (D4) a tenu sa promesse. Le total est aujourd'hui de 354, la
  différence étant entièrement composée de tests neufs pour l'audio.
- Le jeu reste silencieux et fonctionnel avec un catalogue troué — condition nécessaire pour
  développer et jouer pendant tout le sourcing.

**Coûts assumés**

- `fadeMs` est accepté par tout le contrat (`AudioBackend`, `MusicConductor`) mais **pas encore
  honoré** : `FlameAudio.bgm` n'expose aucun fondu natif, les transitions de musique sont
  franches en l'état. Détail et frontière exacte : `_patterns/16-00`.
- `triggerHitReactions()` traite toute hausse de PV comme un soin, sans distinguer sa cause.
  Aucun faux positif aujourd'hui, pour des raisons qui ne sont pas des garde-fous audio.
  Avertissement complet à destination des auteurs de contenu : `_rules/09-00`.
- Le sourcing reste hors chiffrage et hors périmètre de cet ADR — c'est un fait de
  planification, pas d'architecture. Nombre de fichiers restants, mesuré à chaque passe :
  `docs/ROADMAP.md`, chantier P-03.

### Voir aussi

- Règle de jeu : [`_rules/09-00-systeme-audio.md`](../_rules/09-00-systeme-audio.md) — les 14
  moments, la chaîne de repli, le format des assets, l'avertissement `heal`.
- Pattern : [`_patterns/16-00-architecture-du-systeme-audio.md`](../_patterns/16-00-architecture-du-systeme-audio.md)
  — les trois couches, la frontière du fondu, l'idempotence de `onScene`.
- Planification : `docs/ROADMAP.md`, chantier P-03 — estimation corrigée et état du sourcing.
