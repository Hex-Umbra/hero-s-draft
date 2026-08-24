# P-03 — Système audio — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Doter Hero's Draft d'un système audio complet — bruitages et musique — piloté par la donnée, capable de tourner sans que les fichiers sonores existent encore.

**Architecture:** Un `AudioDirector` central est le seul point d'entrée : le code de jeu déclare un *moment de jeu*, jamais un fichier. La résolution moment → son passe par `assets/data/audio.json` avec une chaîne de repli à quatre niveaux finissant par le silence. Un `AudioBackend` abstrait isole `flame_audio` ; son implémentation silencieuse est le défaut, ce qui garde les 295 tests existants muets sans en modifier aucun.

**Tech Stack:** Dart / Flutter · Flame `^1.17.0` · `flame_audio` (ajouté en tâche 12) · `flutter_riverpod ^2.5.1` · `shared_preferences ^2.2.0` · `flutter_test`

**Spec:** [`docs/superpowers/specs/2026-08-24-p03-systeme-audio-design.md`](../specs/2026-08-24-p03-systeme-audio-design.md)

## Global Constraints

Ces règles s'appliquent à **chaque** tâche, sans être répétées dans les tâches.

- `dart analyze` doit rendre `No issues found!` avant tout commit. Zéro issue, pas « zéro erreur ».
- `flutter test` doit être au vert avant tout commit.
- **Les 295 tests existants doivent rester au vert. Aucun ne doit être affaibli, réécrit ni supprimé.** La seule modification autorisée est l'ajout mécanique d'un argument de constructeur devenu requis (tâches 2 et 8). Toute autre retouche d'un test existant signale une mauvaise couture — arrêter et remonter le problème.
- L'audio ne lève jamais d'exception et ne bloque jamais le jeu. Toute défaillance dégrade en silence.
- État partagé exclusivement via `Notifier` / `NotifierProvider` de Riverpod 2.x. Jamais de `StateNotifier`, jamais de singleton, jamais de variable globale.
- Les composants Flame ne lisent jamais un provider. Ils reçoivent leurs collaborateurs par injection depuis la couche UI.
- Aucun code mort, aucun import inutilisé, aucun bloc commenté dans un commit.
- Libellés d'interface : `lib/l10n/app_fr.arb` **et** `app_en.arb`, les deux systématiquement. `audio.json` ne contient aucun texte joueur, la règle bilingue `_fr`/`_en` ne s'y applique pas.
- Style de test : `ProviderContainer` en `setUp`, `group(...)` nommé, helpers privés préfixés `_` — voir `test/unit/deck_controller_test.dart`.
- Commits fréquents, un par tâche minimum, message en français, préfixe conventionnel (`feat(audio):`, `test(audio):`, `docs(vault):`).

**Note de réconciliation avec l'audit du 25/07 :** l'audit listait 15 identifiants de sons, dont trois variantes `card_play_melee` / `_magic` / `_buff`. Dans une architecture pilotée par la donnée ces trois-là ne sont pas des moments distincts : ce sont trois résolutions du même moment `card_play`. Le catalogue de code compte donc **14 moments**, qui résolvent vers 15 sons ou davantage selon ce que déclare `audio.json`.

---

## Task 1: Interface de backend et couture de test

Aucune dépendance nouvelle. Cette tâche pose l'abstraction et prouve que le défaut est silencieux.

**Files:**
- Create: `lib/services/audio/audio_backend.dart`
- Create: `lib/services/audio/silent_audio_backend.dart`
- Create: `lib/services/audio/audio_providers.dart`
- Create: `test/unit/audio/fake_audio_backend.dart`
- Test: `test/unit/audio/audio_backend_test.dart`

**Interfaces:**
- Consumes: rien
- Produces: `abstract class AudioBackend` avec `Future<bool> preload(String file)`, `void playOnce(String file, {double volume})`, `Future<void> playLoop(String file, {double volume, int fadeMs})`, `Future<void> stopLoop({int fadeMs})` · `class SilentAudioBackend implements AudioBackend` · `final audioBackendProvider = Provider<AudioBackend>` · `class FakeAudioBackend implements AudioBackend` exposant `List<String> playedOnce`, `String? currentLoop`, `Set<String> missingFiles`

- [ ] **Step 1: Écrire le test qui échoue**

Créer `test/unit/audio/audio_backend_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/services/audio/audio_backend.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

void main() {
  group('AudioBackend', () {
    test('le backend par defaut est silencieux', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final backend = container.read(audioBackendProvider);

      expect(backend, isA<SilentAudioBackend>());
    });

    test('le backend silencieux ne leve jamais et precharge avec succes', () async {
      const backend = SilentAudioBackend();

      await expectLater(backend.preload('sfx/absent.mp3'), completion(isTrue));
      expect(() => backend.playOnce('sfx/absent.mp3'), returnsNormally);
      await expectLater(backend.playLoop('music/absent.mp3'), completes);
      await expectLater(backend.stopLoop(), completes);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/audio_backend_test.dart
```

Attendu : ÉCHEC à la compilation, `Target of URI doesn't exist: '.../audio_backend.dart'`.

- [ ] **Step 3: Écrire l'implémentation minimale**

`lib/services/audio/audio_backend.dart` :

```dart
/// Couche la plus basse du systeme audio : la seule qui parle a une
/// bibliotheque de lecture. Aucune implementation ne leve d'exception —
/// un fichier absent se signale par une valeur de retour, jamais par un throw.
abstract class AudioBackend {
  /// Charge [file] en cache. Retourne `false` si le fichier est absent
  /// ou illisible. Ne leve jamais.
  Future<bool> preload(String file);

  /// Joue [file] une fois. Sans effet si le fichier n'a pas ete precharge.
  void playOnce(String file, {double volume = 1.0});

  /// Demarre une boucle, en remplacant celle en cours s'il y en a une.
  /// [fadeMs] est la duree du fondu enchaine.
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0});

  /// Arrete la boucle en cours. Sans effet s'il n'y en a pas.
  Future<void> stopLoop({int fadeMs = 0});
}
```

`lib/services/audio/silent_audio_backend.dart` :

```dart
import 'audio_backend.dart';

/// Backend par defaut : se comporte comme si tout fonctionnait, sans
/// produire le moindre son. C'est ce qui rend `flutter test` muet sans
/// qu'aucun test existant n'ait a surcharger quoi que ce soit.
class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<bool> preload(String file) async => true;

  @override
  void playOnce(String file, {double volume = 1.0}) {}

  @override
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0}) async {}

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {}
}
```

`lib/services/audio/audio_providers.dart` :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'audio_backend.dart';
import 'silent_audio_backend.dart';

/// Vaut `SilentAudioBackend` par defaut, et c'est deliberé :
/// `main.dart` est le SEUL endroit qui le surcharge par le backend reel.
/// Le defaut inverse aurait impose de modifier 51 fichiers de test.
final audioBackendProvider = Provider<AudioBackend>(
  (ref) => const SilentAudioBackend(),
);
```

- [ ] **Step 4: Écrire le faux backend pour les tâches suivantes**

`test/unit/audio/fake_audio_backend.dart` :

```dart
import 'package:roguelike_card_game/services/audio/audio_backend.dart';

/// Backend d'observation : enregistre ce qu'on lui demande au lieu de le jouer.
/// Ajouter un fichier a [missingFiles] simule un asset absent du disque.
class FakeAudioBackend implements AudioBackend {
  final List<String> playedOnce = [];
  final List<double> playedVolumes = [];
  final Set<String> missingFiles = {};
  final List<String> preloadAttempts = [];
  String? currentLoop;
  double? currentLoopVolume;
  int loopStartCount = 0;

  @override
  Future<bool> preload(String file) async {
    preloadAttempts.add(file);
    return !missingFiles.contains(file);
  }

  @override
  void playOnce(String file, {double volume = 1.0}) {
    playedOnce.add(file);
    playedVolumes.add(volume);
  }

  @override
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0}) async {
    currentLoop = file;
    currentLoopVolume = volume;
    loopStartCount++;
  }

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {
    currentLoop = null;
    currentLoopVolume = null;
  }
}
```

- [ ] **Step 5: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/audio/audio_backend_test.dart
```

Attendu : PASS, 2 tests.

- [ ] **Step 6: Vérifier l'analyse statique et la non-régression**

```bash
dart analyze
```

Attendu : `No issues found!`

```bash
flutter test
```

Attendu : 297 tests au vert (295 existants + 2 neufs), aucun fichier existant modifié.

- [ ] **Step 7: Commit**

```bash
git add lib/services/audio test/unit/audio && git commit -m "feat(audio): poser l'interface de backend et la couture silencieuse par defaut"
```

---

## Task 2: Modèle de données et chargement tolérant

**Files:**
- Create: `lib/models/data/audio_data.dart`
- Create: `assets/data/audio.json`
- Create: `assets/audio/sfx/.gitkeep`, `assets/audio/music/.gitkeep`
- Modify: `lib/models/data/game_data_registry.dart`
- Modify: `lib/services/game_data_service.dart:51-89`
- Modify: `pubspec.yaml` (section `assets:`)
- Test: `test/unit/audio/audio_data_test.dart`

**Interfaces:**
- Consumes: rien de la tâche 1
- Produces: `class SoundData {String file; double volume; int variants;}` · `class MomentSounds {String? defaultSound; Map<String,String> byAnimation;}` · `class AudioData {int schemaVersion; Map<String,SoundData> sounds; Map<String,MomentSounds> moments; Map<String,SoundData> music; bool enabled;}` avec `AudioData.fromJson(Map<String,dynamic>)` et `const AudioData.disabled()` · `GameDataRegistry.audio` de type `AudioData`

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/audio_data_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';

void main() {
  group('AudioData', () {
    test('parse un catalogue complet', () {
      final data = AudioData.fromJson({
        'schemaVersion': 1,
        'sounds': {
          'impact_normal': {'file': 'sfx/impact_normal.mp3', 'volume': 0.8, 'variants': 3},
          'card_play_fire': {'file': 'sfx/card_play_fire.mp3'},
        },
        'moments': {
          'card_play': {
            'default': 'card_play_generic',
            'byAnimation': {'fire': 'card_play_fire'},
          },
          'impact': {'default': 'impact_normal'},
        },
        'music': {
          'menu': {'file': 'music/menu.mp3'},
        },
      });

      expect(data.enabled, isTrue);
      expect(data.sounds['impact_normal']!.volume, 0.8);
      expect(data.sounds['impact_normal']!.variants, 3);
      expect(data.sounds['card_play_fire']!.volume, 1.0);
      expect(data.sounds['card_play_fire']!.variants, 1);
      expect(data.moments['card_play']!.byAnimation['fire'], 'card_play_fire');
      expect(data.moments['impact']!.defaultSound, 'impact_normal');
      expect(data.music['menu']!.file, 'music/menu.mp3');
    });

    test('un catalogue desactive est vide et jamais nul', () {
      const data = AudioData.disabled();

      expect(data.enabled, isFalse);
      expect(data.sounds, isEmpty);
      expect(data.moments, isEmpty);
      expect(data.music, isEmpty);
    });

    test('un moment sans defaut ni variantes reste lisible', () {
      final data = AudioData.fromJson({
        'schemaVersion': 1,
        'sounds': <String, dynamic>{},
        'moments': {
          'turn_start': <String, dynamic>{},
        },
        'music': <String, dynamic>{},
      });

      expect(data.moments['turn_start']!.defaultSound, isNull);
      expect(data.moments['turn_start']!.byAnimation, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/audio_data_test.dart
```

Attendu : ÉCHEC, `Target of URI doesn't exist: '.../audio_data.dart'`.

- [ ] **Step 3: Écrire le modèle**

`lib/models/data/audio_data.dart` :

```dart
/// Un son declare dans `assets/data/audio.json`.
///
/// [variants] > 1 declare N fichiers numerotes derives de [file] :
/// `sfx/impact.mp3` avec `variants: 3` designe `sfx/impact_1.mp3`,
/// `_2` et `_3`, tires au hasard a chaque lecture pour casser la repetition.
class SoundData {
  final String file;
  final double volume;
  final int variants;

  const SoundData({
    required this.file,
    this.volume = 1.0,
    this.variants = 1,
  });

  factory SoundData.fromJson(Map<String, dynamic> json) => SoundData(
        file: json['file'] as String,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
        variants: (json['variants'] as num?)?.toInt() ?? 1,
      );
}

/// Les sons possibles pour un moment de jeu : un repli par type d'animation,
/// et un defaut. Les deux sont optionnels — un moment sans aucun des deux
/// se resout en silence, ce qui est un etat normal pendant le sourcing.
class MomentSounds {
  final String? defaultSound;
  final Map<String, String> byAnimation;

  const MomentSounds({this.defaultSound, this.byAnimation = const {}});

  factory MomentSounds.fromJson(Map<String, dynamic> json) {
    final raw = json['byAnimation'] as Map<String, dynamic>?;
    return MomentSounds(
      defaultSound: json['default'] as String?,
      byAnimation: raw == null
          ? const {}
          : raw.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

/// Catalogue audio complet. [enabled] vaut `false` quand le fichier est
/// absent ou illisible : le jeu tourne alors en silence, sans erreur.
class AudioData {
  final int schemaVersion;
  final Map<String, SoundData> sounds;
  final Map<String, MomentSounds> moments;
  final Map<String, SoundData> music;
  final bool enabled;

  const AudioData({
    required this.schemaVersion,
    required this.sounds,
    required this.moments,
    required this.music,
    this.enabled = true,
  });

  const AudioData.disabled()
      : schemaVersion = 0,
        sounds = const {},
        moments = const {},
        music = const {},
        enabled = false;

  factory AudioData.fromJson(Map<String, dynamic> json) {
    Map<String, SoundData> readSounds(String key) {
      final raw = json[key] as Map<String, dynamic>?;
      if (raw == null) return const {};
      return raw.map(
        (id, value) => MapEntry(id, SoundData.fromJson(value as Map<String, dynamic>)),
      );
    }

    final rawMoments = json['moments'] as Map<String, dynamic>?;

    return AudioData(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      sounds: readSounds('sounds'),
      music: readSounds('music'),
      moments: rawMoments == null
          ? const {}
          : rawMoments.map(
              (id, value) =>
                  MapEntry(id, MomentSounds.fromJson(value as Map<String, dynamic>)),
            ),
    );
  }
}
```

- [ ] **Step 4: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/audio/audio_data_test.dart
```

Attendu : PASS, 3 tests.

- [ ] **Step 5: Créer le catalogue de départ**

`assets/data/audio.json`. Les fichiers n'existent pas encore — **c'est normal et voulu**, ce fichier est aussi la liste de courses du sourcing.

```json
{
  "schemaVersion": 1,
  "sounds": {
    "card_hover":        { "file": "sfx/card_hover.mp3", "volume": 0.4 },
    "card_pickup":       { "file": "sfx/card_pickup.mp3", "volume": 0.6 },
    "card_play_generic": { "file": "sfx/card_play_generic.mp3" },
    "card_play_melee":   { "file": "sfx/card_play_melee.mp3" },
    "card_play_magic":   { "file": "sfx/card_play_magic.mp3" },
    "card_play_buff":    { "file": "sfx/card_play_buff.mp3" },
    "impact_normal":     { "file": "sfx/impact_normal.mp3", "volume": 0.9, "variants": 3 },
    "impact_crit":       { "file": "sfx/impact_crit.mp3" },
    "armor_hit":         { "file": "sfx/armor_hit.mp3", "volume": 0.8 },
    "heal":              { "file": "sfx/heal.mp3", "volume": 0.7 },
    "enemy_attack":      { "file": "sfx/enemy_attack.mp3", "volume": 0.8 },
    "enemy_death":       { "file": "sfx/enemy_death.mp3" },
    "card_draw":         { "file": "sfx/card_draw.mp3", "volume": 0.5 },
    "mana_gain":         { "file": "sfx/mana_gain.mp3", "volume": 0.6 },
    "insufficient_mana": { "file": "sfx/insufficient_mana.mp3", "volume": 0.7 },
    "turn_start":        { "file": "sfx/turn_start.mp3", "volume": 0.6 },
    "turn_end":          { "file": "sfx/turn_end.mp3", "volume": 0.6 }
  },
  "moments": {
    "card_hover":        { "default": "card_hover" },
    "card_pickup":       { "default": "card_pickup" },
    "card_play":         { "default": "card_play_generic",
                           "byAnimation": { "melee": "card_play_melee",
                                            "magic": "card_play_magic",
                                            "buff": "card_play_buff" } },
    "impact":            { "default": "impact_normal" },
    "impact_crit":       { "default": "impact_crit" },
    "armor_hit":         { "default": "armor_hit" },
    "heal":              { "default": "heal" },
    "enemy_attack":      { "default": "enemy_attack" },
    "enemy_death":       { "default": "enemy_death" },
    "card_draw":         { "default": "card_draw" },
    "mana_gain":         { "default": "mana_gain" },
    "insufficient_mana": { "default": "insufficient_mana" },
    "turn_start":        { "default": "turn_start" },
    "turn_end":          { "default": "turn_end" }
  },
  "music": {
    "menu":   { "file": "music/menu.mp3",   "volume": 0.6 },
    "map":    { "file": "music/map.mp3",    "volume": 0.6 },
    "combat": { "file": "music/combat.mp3", "volume": 0.6 },
    "boss":   { "file": "music/boss.mp3",   "volume": 0.7 }
  }
}
```

Créer les deux dossiers d'assets avec un `.gitkeep` vide dans chacun — Flutter échoue au build sur un dossier d'assets déclaré mais inexistant :

```bash
mkdir -p assets/audio/sfx assets/audio/music && touch assets/audio/sfx/.gitkeep assets/audio/music/.gitkeep
```

- [ ] **Step 6: Déclarer les assets dans `pubspec.yaml`**

Dans la section `flutter:` → `assets:`, ajouter les deux dossiers après `- assets/images/` :

```yaml
  assets:
    - assets/data/
    - assets/images/
    - assets/audio/sfx/
    - assets/audio/music/
```

- [ ] **Step 7: Brancher le chargement, en le rendant tolérant**

Dans `lib/services/game_data_service.dart`, ajouter l'import `import '../models/data/audio_data.dart';` puis ce chargeur **au-dessus** de `gameDataLoaderProvider` :

```dart
/// Charge `audio.json`. Contrairement a `_loadJsonList`, cette fonction ne
/// leve jamais : l'audio est le seul sous-systeme auquel il est interdit de
/// faire echouer le demarrage du jeu. Fichier absent ou malforme = catalogue
/// desactive, jeu silencieux.
Future<AudioData> _loadAudioData(String path) async {
  try {
    final String content = await rootBundle.loadString(path);
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      return const AudioData.disabled();
    }
    return AudioData.fromJson(decoded);
  } catch (_) {
    return const AudioData.disabled();
  }
}
```

Dans le corps de `gameDataLoaderProvider`, après le `await Future.wait([...])` existant :

```dart
  final audio = await _loadAudioData('assets/data/audio.json');
```

et passer `audio: audio,` au constructeur de `GameDataRegistry`.

Dans `lib/models/data/game_data_registry.dart`, ajouter l'import `import 'audio_data.dart';`, le champ `final AudioData audio;` après `forgeUpgrades`, et le paramètre `required this.audio,` au constructeur.

- [ ] **Step 8: Vérifier**

```bash
dart analyze
```

Attendu : `No issues found!`

```bash
flutter test
```

Attendu : 300 au vert. **Les tests widget qui construisent un `GameDataRegistry` de test vont échouer à la compilation** faute du paramètre `audio`. C'est le seul cas où ce plan autorise à toucher un test existant : ajouter `audio: const AudioData.disabled(),` à chaque construction de registre factice, et rien d'autre. Repérer les sites avec :

```bash
grep -rn "GameDataRegistry(" test/
```

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat(audio): charger un catalogue audio pilote par la donnee, tolerant a l'absence"
```

---

## Task 3: Moments de jeu et chaîne de repli

Le cœur du système.

**Files:**
- Create: `lib/services/audio/game_moment.dart`
- Create: `lib/services/audio/audio_source.dart`
- Create: `lib/services/audio/audio_settings.dart`
- Create: `lib/services/audio/audio_director.dart`
- Test: `test/unit/audio/audio_director_resolution_test.dart`

**Interfaces:**
- Consumes: `AudioBackend`, `FakeAudioBackend` (tâche 1) · `AudioData`, `SoundData`, `MomentSounds` (tâche 2)
- Produces: `enum GameMoment` à 14 valeurs, chacune portant `final String jsonKey` · `abstract class AudioSource {String? get sfx; String? get animation;}` · `class AudioSettings` immuable (`master`, `sfx`, `music`, `muted`, `effectiveSfx`, `effectiveMusic`, `copyWith`, `toJson`, `fromJson`, `==`) · `class AudioDirector` avec `AudioDirector({required AudioBackend backend, required AudioData data, required AudioSettings Function() settings, Random? random})`, `Future<void> preloadAll()` et `void onMoment(GameMoment moment, {AudioSource? source})`

> **Pourquoi `AudioSettings` est ici et non en tâche 6 :** c'est une classe de valeur pure, sans dépendance de persistance. La déclarer ici donne au directeur sa signature définitive du premier coup. La tâche 6 n'ajoute que ce qui touche au stockage (`SettingsService`) et à l'état partagé (le `Notifier`).

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/audio_director_resolution_test.dart` :

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

class _Source implements AudioSource {
  @override
  final String? sfx;
  @override
  final String? animation;

  const _Source({this.sfx, this.animation});
}

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'propre': {'file': 'sfx/propre.mp3'},
        'feu': {'file': 'sfx/feu.mp3'},
        'generique': {'file': 'sfx/generique.mp3'},
      },
      'moments': {
        'card_play': {
          'default': 'generique',
          'byAnimation': {'fire': 'feu'},
        },
        'turn_start': <String, dynamic>{},
      },
      'music': <String, dynamic>{},
    });

Future<AudioDirector> _director(FakeAudioBackend backend) async {
  final director = AudioDirector(
    backend: backend,
    data: _catalogue(),
    settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
    random: Random(42),
  );
  await director.preloadAll();
  return director;
}

void main() {
  group('AudioDirector — chaine de repli', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('niveau 1 : le champ sfx de la source prime sur tout', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay,
          source: const _Source(sfx: 'propre', animation: 'fire'));

      expect(backend.playedOnce, ['sfx/propre.mp3']);
    });

    test('niveau 2 : a defaut, le type d animation de la source', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'fire'));

      expect(backend.playedOnce, ['sfx/feu.mp3']);
    });

    test('niveau 3 : a defaut, le son par defaut du moment', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'inconnu'));

      expect(backend.playedOnce, ['sfx/generique.mp3']);
    });

    test('niveau 3 : un moment systemique sans source prend le defaut', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedOnce, ['sfx/generique.mp3']);
    });

    test('niveau 4 : un moment sans defaut se resout en silence', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.turnStart);

      expect(backend.playedOnce, isEmpty);
    });

    test('niveau 4 : un moment absent du catalogue se resout en silence', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.enemyDeath);

      expect(backend.playedOnce, isEmpty);
    });

    test('un sfx pointant vers un son inconnu retombe sur le niveau suivant', () async {
      final director = await _director(backend);

      director.onMoment(GameMoment.cardPlay,
          source: const _Source(sfx: 'inexistant', animation: 'fire'));

      expect(backend.playedOnce, ['sfx/feu.mp3']);
    });

    test('la coupure globale rend silencieux', () async {
      final director = AudioDirector(
        backend: backend,
        data: _catalogue(),
        settings: () => const AudioSettings(muted: true),
        random: Random(42),
      );
      await director.preloadAll();

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedOnce, isEmpty);
    });

    test('le volume du son est multiplie par le volume des bruitages', () async {
      final director = AudioDirector(
        backend: backend,
        data: AudioData.fromJson({
          'schemaVersion': 1,
          'sounds': {
            'generique': {'file': 'sfx/generique.mp3', 'volume': 0.8},
          },
          'moments': {
            'card_play': {'default': 'generique'},
          },
          'music': <String, dynamic>{},
        }),
        settings: () => const AudioSettings(master: 1.0, sfx: 0.5),
        random: Random(42),
      );
      await director.preloadAll();

      director.onMoment(GameMoment.cardPlay);

      expect(backend.playedVolumes.single, closeTo(0.4, 0.0001));
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/audio_director_resolution_test.dart
```

Attendu : ÉCHEC à la compilation, `game_moment.dart` introuvable.

- [ ] **Step 3: Écrire les moments et l'interface de source**

`lib/services/audio/game_moment.dart` :

```dart
/// Les 14 moments de jeu que le code peut declarer.
///
/// Un appelant declare un moment, jamais un fichier : c'est ce qui permet
/// de garder toute la resolution — et donc la gestion de l'asset absent —
/// dans `AudioDirector`.
///
/// L'audit du 25/07 listait 15 identifiants, dont trois variantes de
/// `card_play`. Ces trois-la ne sont pas des moments distincts : ce sont
/// trois resolutions du moment `cardPlay`, decidees par la donnee.
enum GameMoment {
  cardHover('card_hover'),
  cardPickup('card_pickup'),
  cardPlay('card_play'),
  impact('impact'),
  impactCrit('impact_crit'),
  armorHit('armor_hit'),
  heal('heal'),
  enemyAttack('enemy_attack'),
  enemyDeath('enemy_death'),
  cardDraw('card_draw'),
  manaGain('mana_gain'),
  insufficientMana('insufficient_mana'),
  turnStart('turn_start'),
  turnEnd('turn_end');

  const GameMoment(this.jsonKey);

  /// Cle correspondante dans la section `moments` de `assets/data/audio.json`.
  final String jsonKey;
}
```

`lib/services/audio/audio_source.dart` :

```dart
/// Implemente par les modeles de donnees qui peuvent porter un son propre.
///
/// [sfx] est le niveau 1 de la chaine de repli, [animation] le niveau 2.
/// Les deux sont optionnels : une entite qui n'implemente rien de particulier
/// laisse le moment se resoudre sur son defaut.
abstract class AudioSource {
  String? get sfx;
  String? get animation;
}
```

`lib/services/audio/audio_settings.dart` — classe de valeur pure, sans dépendance de persistance :

```dart
import 'package:flutter/foundation.dart';

/// Reglages audio du joueur. Immuable ; toute modification passe par
/// [copyWith] et produit un nouvel etat Riverpod.
@immutable
class AudioSettings {
  final double master;
  final double sfx;
  final double music;
  final bool muted;

  const AudioSettings({
    this.master = 0.8,
    this.sfx = 1.0,
    this.music = 0.6,
    this.muted = false,
  });

  /// Volume reellement applique aux bruitages : produit du general et de
  /// la categorie, ramene a zero par la coupure globale.
  double get effectiveSfx => muted ? 0.0 : master * sfx;

  double get effectiveMusic => muted ? 0.0 : master * music;

  AudioSettings copyWith({
    double? master,
    double? sfx,
    double? music,
    bool? muted,
  }) =>
      AudioSettings(
        master: master ?? this.master,
        sfx: sfx ?? this.sfx,
        music: music ?? this.music,
        muted: muted ?? this.muted,
      );

  Map<String, dynamic> toJson() => {
        'master': master,
        'sfx': sfx,
        'music': music,
        'muted': muted,
      };

  factory AudioSettings.fromJson(Map<String, dynamic> json) => AudioSettings(
        master: (json['master'] as num?)?.toDouble() ?? 0.8,
        sfx: (json['sfx'] as num?)?.toDouble() ?? 1.0,
        music: (json['music'] as num?)?.toDouble() ?? 0.6,
        muted: json['muted'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is AudioSettings &&
      other.master == master &&
      other.sfx == sfx &&
      other.music == music &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(master, sfx, music, muted);
}
```

- [ ] **Step 4: Écrire le directeur**

`lib/services/audio/audio_director.dart` :

```dart
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/data/audio_data.dart';
import 'audio_backend.dart';
import 'audio_settings.dart';
import 'audio_source.dart';
import 'game_moment.dart';

/// Point d'entree unique du systeme audio.
///
/// Le code de jeu appelle [onMoment] avec un moment et, si elle existe,
/// l'entite a l'origine du moment. Le directeur resout, applique les
/// reglages, et delegue au backend. Aucun appelant ne connait jamais un
/// nom de fichier.
class AudioDirector {
  AudioDirector({
    required AudioBackend backend,
    required AudioData data,
    required AudioSettings Function() settings,
    Random? random,
  })  : _backend = backend,
        _data = data,
        _settings = settings,
        _random = random ?? Random();

  final AudioBackend _backend;
  final AudioData _data;
  final AudioSettings Function() _settings;
  final Random _random;

  final Set<String> _availableFiles = {};
  final Set<String> _reportedMissing = {};

  /// Precharge tout le catalogue. Volontairement `async` et jamais attendu
  /// par un ecran : un son demande avant la fin du prechargement est
  /// abandonne, pas mis en file.
  Future<void> preloadAll() async {
    if (!_data.enabled) return;
    for (final sound in _data.sounds.values) {
      for (final file in _filesFor(sound)) {
        final ok = await _backend.preload(file);
        if (ok) {
          _availableFiles.add(file);
        } else {
          _reportMissing(file);
        }
      }
    }
  }

  void onMoment(GameMoment moment, {AudioSource? source}) {
    if (!_data.enabled) return;

    final volumeScale = _settings().effectiveSfx;
    if (volumeScale <= 0) return;

    final soundId = _resolve(moment, source);
    if (soundId == null) return;

    final sound = _data.sounds[soundId];
    if (sound == null) return;

    final file = _pickFile(sound);
    if (!_availableFiles.contains(file)) return;

    _backend.playOnce(file, volume: sound.volume * volumeScale);
  }

  /// La chaine de repli, dans l'ordre : son propre a l'entite, son du type
  /// d'animation, son par defaut du moment, silence.
  String? _resolve(GameMoment moment, AudioSource? source) {
    final explicit = source?.sfx;
    if (explicit != null && _data.sounds.containsKey(explicit)) {
      return explicit;
    }

    final moments = _data.moments[moment.jsonKey];
    if (moments == null) return null;

    final animation = source?.animation;
    if (animation != null) {
      final byAnimation = moments.byAnimation[animation];
      if (byAnimation != null) return byAnimation;
    }

    return moments.defaultSound;
  }

  List<String> _filesFor(SoundData sound) {
    if (sound.variants <= 1) return [sound.file];
    return List.generate(sound.variants, (i) => _variantFile(sound.file, i + 1));
  }

  String _pickFile(SoundData sound) {
    if (sound.variants <= 1) return sound.file;
    return _variantFile(sound.file, _random.nextInt(sound.variants) + 1);
  }

  String _variantFile(String file, int index) {
    final dot = file.lastIndexOf('.');
    if (dot < 0) return '${file}_$index';
    return '${file.substring(0, dot)}_$index${file.substring(dot)}';
  }

  void _reportMissing(String file) {
    if (!_reportedMissing.add(file)) return;
    debugPrint('[audio] fichier declare mais absent : $file');
  }
}
```

- [ ] **Step 5: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/audio/audio_director_resolution_test.dart
```

Attendu : PASS, 9 tests.

- [ ] **Step 6: Vérifier**

```bash
dart analyze
```

Attendu : `No issues found!`

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(audio): resoudre un moment de jeu en son par la chaine de repli"
```

---

## Task 4: Champ `sfx` dans les modèles de contenu

**Files:**
- Modify: `lib/models/data/card_data.dart`
- Modify: `lib/models/data/enemy_data.dart`
- Modify: `lib/models/data/relic_data.dart`
- Test: `test/unit/audio/audio_source_models_test.dart`

**Interfaces:**
- Consumes: `AudioSource` (tâche 3)
- Produces: `CardData implements AudioSource` · `EnemyData implements AudioSource` · `RelicData implements AudioSource` — toutes trois avec `final String? sfx;` et un getter `animation` (`CardData` a déjà le champ ; `EnemyData` et `RelicData` retournent `null`)

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/audio_source_models_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';

void main() {
  group('Modeles porteurs de son', () {
    test('CardData expose sfx et animation comme AudioSource', () {
      final card = CardData.fromJson({
        'id': 'test_card',
        'nameEn': 'Test',
        'nameFr': 'Test',
        'descriptionEn': '',
        'descriptionFr': '',
        'cost': 1,
        'type': 'attack',
        'category': 'global',
        'rarity': 'common',
        'target': 'singleEnemy',
        'animation': 'fire',
        'sfx': 'card_play_fire',
        'effects': <dynamic>[],
      });

      expect(card, isA<AudioSource>());
      expect(card.sfx, 'card_play_fire');
      expect(card.animation, 'fire');
    });

    test('le champ sfx est optionnel et vaut null par defaut', () {
      final card = CardData.fromJson({
        'id': 'test_card',
        'nameEn': 'Test',
        'nameFr': 'Test',
        'descriptionEn': '',
        'descriptionFr': '',
        'cost': 1,
        'type': 'attack',
        'category': 'global',
        'rarity': 'common',
        'target': 'singleEnemy',
        'effects': <dynamic>[],
      });

      expect(card.sfx, isNull);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/audio_source_models_test.dart
```

Attendu : ÉCHEC, `The getter 'sfx' isn't defined for the class 'CardData'`.

- [ ] **Step 3: Ajouter le champ aux trois modèles**

Dans `lib/models/data/card_data.dart` : importer `'../../services/audio/audio_source.dart'`, changer la déclaration en `class CardData implements AudioSource {`, ajouter le champ après `animation` :

```dart
  @override
  final String? sfx; // Identifiant de son propre a la carte (voir audio.json)
```

Marquer `animation` d'un `@override`, ajouter `this.sfx,` au constructeur, et dans `fromJson` :

```dart
      sfx: json['sfx'] as String?,
```

Répéter pour `EnemyData` et `RelicData`. Ces deux-là n'ont pas de champ `animation` : leur satisfaire l'interface se fait par un getter constant, à placer juste après le champ `sfx` :

```dart
  @override
  String? get animation => null;
```

- [ ] **Step 4: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/audio/audio_source_models_test.dart
```

Attendu : PASS, 2 tests.

- [ ] **Step 5: Vérifier la non-régression complète**

```bash
dart analyze && flutter test
```

Attendu : `No issues found!` puis tous les tests au vert. Aucun JSON de contenu n'a besoin d'être modifié — le champ est optionnel.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(audio): permettre a une carte, un ennemi ou une relique de declarer son son"
```

---

## Task 5: Mode dégradé et disponibilité des fichiers

**Files:**
- Test: `test/unit/audio/audio_director_degraded_test.dart`
- Modify: `lib/services/audio/audio_director.dart` (si un test révèle un manque)

**Interfaces:**
- Consumes: `AudioDirector`, `FakeAudioBackend`
- Produces: rien de neuf — cette tâche **verrouille** un comportement déjà écrit en tâche 3

- [ ] **Step 1: Écrire les tests qui verrouillent la dégradation**

`test/unit/audio/audio_director_degraded_test.dart` :

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'present': {'file': 'sfx/present.mp3'},
        'absent': {'file': 'sfx/absent.mp3'},
        'varie': {'file': 'sfx/varie.mp3', 'variants': 3},
      },
      'moments': {
        'impact': {'default': 'present'},
        'heal': {'default': 'absent'},
        'card_draw': {'default': 'varie'},
      },
      'music': <String, dynamic>{},
    });

AudioDirector _director(FakeAudioBackend backend, {AudioData? data}) => AudioDirector(
      backend: backend,
      data: data ?? _catalogue(),
      settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
      random: Random(7),
    );

void main() {
  group('AudioDirector — mode degrade', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('un fichier absent rend le moment silencieux, sans exception', () async {
      backend.missingFiles.add('sfx/absent.mp3');
      final director = _director(backend);
      await director.preloadAll();

      expect(() => director.onMoment(GameMoment.heal), returnsNormally);
      expect(backend.playedOnce, isEmpty);
    });

    test('un fichier absent n empeche pas les autres de jouer', () async {
      backend.missingFiles.add('sfx/absent.mp3');
      final director = _director(backend);
      await director.preloadAll();

      director.onMoment(GameMoment.impact);

      expect(backend.playedOnce, ['sfx/present.mp3']);
    });

    test('un catalogue desactive rend tout silencieux sans lever', () async {
      final director = _director(backend, data: const AudioData.disabled());
      await director.preloadAll();

      expect(() => director.onMoment(GameMoment.impact), returnsNormally);
      expect(backend.playedOnce, isEmpty);
      expect(backend.preloadAttempts, isEmpty);
    });

    test('jouer avant la fin du prechargement est silencieux, pas mis en file', () async {
      final director = _director(backend);

      director.onMoment(GameMoment.impact);
      expect(backend.playedOnce, isEmpty);

      await director.preloadAll();
      expect(backend.playedOnce, isEmpty,
          reason: 'le son demande trop tot est abandonne, jamais rejoue');
    });

    test('les variantes sont toutes prechargees et une seule est jouee', () async {
      final director = _director(backend);
      await director.preloadAll();

      director.onMoment(GameMoment.cardDraw);

      expect(
        backend.preloadAttempts,
        containsAll(['sfx/varie_1.mp3', 'sfx/varie_2.mp3', 'sfx/varie_3.mp3']),
      );
      expect(backend.playedOnce, hasLength(1));
      expect(backend.playedOnce.single, matches(r'^sfx/varie_[123]\.mp3$'));
    });
  });
}
```

- [ ] **Step 2: Lancer les tests**

```bash
flutter test test/unit/audio/audio_director_degraded_test.dart
```

Attendu : PASS, 5 tests. **Si l'un échoue**, corriger `audio_director.dart` — le test décrit le comportement voulu, pas l'inverse.

- [ ] **Step 3: Vérifier**

```bash
dart analyze && flutter test
```

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "test(audio): verrouiller la degradation silencieuse du directeur"
```

---

## Task 6: Réglages audio et persistance

**Files:**
- Create: `lib/services/settings_service.dart`
- Modify: `lib/services/audio/audio_providers.dart`
- Test: `test/unit/audio/audio_settings_test.dart`

**Interfaces:**
- Consumes: `AudioSettings` (tâche 3) — la classe de valeur existe déjà, cette tâche n'y touche pas
- Produces: `class SettingsService` avec `static Future<AudioSettings> load()` et `static Future<void> save(AudioSettings)` · `class AudioSettingsNotifier extends Notifier<AudioSettings>` avec `Future<void> hydrate()`, `void setMaster(double)`, `void setSfx(double)`, `void setMusic(double)`, `void toggleMute()` · `final audioSettingsProvider = NotifierProvider<AudioSettingsNotifier, AudioSettings>`

> **Ne pas recréer `AudioSettings`.** La classe est écrite en tâche 3, avec `effectiveSfx`, `effectiveMusic`, `copyWith`, `toJson`, `fromJson` et `==`. Cette tâche n'ajoute que le stockage et l'état partagé. Les deux premiers tests ci-dessous vérifient la classe de la tâche 3 : ils sont ici parce que c'est ici que les réglages deviennent utilisables, et ils doivent passer sans qu'une ligne d'`audio_settings.dart` ne bouge.

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/audio_settings_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSettings', () {
    test('le volume effectif est le produit du general et de la categorie', () {
      const settings = AudioSettings(master: 0.5, sfx: 0.8, music: 0.6);

      expect(settings.effectiveSfx, closeTo(0.4, 0.0001));
      expect(settings.effectiveMusic, closeTo(0.3, 0.0001));
    });

    test('la coupure prime sur les deux volumes', () {
      const settings = AudioSettings(master: 1.0, sfx: 1.0, music: 1.0, muted: true);

      expect(settings.effectiveSfx, 0.0);
      expect(settings.effectiveMusic, 0.0);
    });
  });

  group('SettingsService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('aller-retour de persistance', () async {
      const written = AudioSettings(master: 0.3, sfx: 0.4, music: 0.5, muted: true);

      await SettingsService.save(written);
      final read = await SettingsService.load();

      expect(read.master, closeTo(0.3, 0.0001));
      expect(read.sfx, closeTo(0.4, 0.0001));
      expect(read.music, closeTo(0.5, 0.0001));
      expect(read.muted, isTrue);
    });

    test('sans reglage enregistre, retourne les defauts', () async {
      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('un JSON corrompu retombe silencieusement sur les defauts', () async {
      SharedPreferences.setMockInitialValues({'settings_v1': 'ceci n est pas du json'});

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });

    test('une version de schema inconnue retombe sur les defauts', () async {
      SharedPreferences.setMockInitialValues({
        'settings_v1': '{"schemaVersion": 99, "master": 0.1}',
      });

      final read = await SettingsService.load();

      expect(read, const AudioSettings());
    });
  });

  group('AudioSettingsNotifier', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la coupure bascule et se persiste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(audioSettingsProvider.notifier);

      expect(container.read(audioSettingsProvider).muted, isFalse);

      notifier.toggleMute();
      expect(container.read(audioSettingsProvider).muted, isTrue);

      final persisted = await SettingsService.load();
      expect(persisted.muted, isTrue);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/audio_settings_test.dart
```

Attendu : ÉCHEC, `settings_service.dart` introuvable. Les deux premiers tests du groupe `AudioSettings` compilent déjà — la classe vient de la tâche 3 — mais le fichier ne se lance pas tant que `SettingsService` n'existe pas.

- [ ] **Step 3: Écrire le service de persistance**

`lib/services/settings_service.dart` :

```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_settings.dart';

/// Persistance des preferences du joueur.
///
/// Cle distincte de celle de `SaveService` : `GameOverScreen` efface la
/// sauvegarde de run a la mort du heros, et le volume ne doit pas mourir
/// avec le personnage.
///
/// Asymetrie assumee avec `SaveService` : un JSON illisible ou une version
/// de schema inconnue retombe **silencieusement** sur les defauts. Perdre un
/// reglage de volume ne justifie pas un ecran d'erreur.
class SettingsService {
  static const String _settingsKey = 'settings_v1';
  static const int _schemaVersion = 1;

  static Future<void> save(AudioSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'schemaVersion': _schemaVersion,
      ...settings.toJson(),
    };
    await prefs.setString(_settingsKey, jsonEncode(payload));
  }

  static Future<AudioSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null) return const AudioSettings();

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const AudioSettings();
      if (decoded['schemaVersion'] != _schemaVersion) return const AudioSettings();

      return AudioSettings.fromJson(decoded);
    } catch (_) {
      return const AudioSettings();
    }
  }
}
```

- [ ] **Step 4: Écrire le notifier et le brancher au provider**

Dans `lib/services/audio/audio_providers.dart`, ajouter :

```dart
class AudioSettingsNotifier extends Notifier<AudioSettings> {
  @override
  AudioSettings build() => const AudioSettings();

  /// Charge les reglages persistes. Appele une fois au demarrage.
  Future<void> hydrate() async {
    state = await SettingsService.load();
  }

  void setMaster(double value) => _update(state.copyWith(master: value));
  void setSfx(double value) => _update(state.copyWith(sfx: value));
  void setMusic(double value) => _update(state.copyWith(music: value));
  void toggleMute() => _update(state.copyWith(muted: !state.muted));

  void _update(AudioSettings next) {
    state = next;
    SettingsService.save(next);
  }
}

final audioSettingsProvider =
    NotifierProvider<AudioSettingsNotifier, AudioSettings>(AudioSettingsNotifier.new);
```

avec les imports `import 'audio_settings.dart';` et `import '../settings_service.dart';`.

- [ ] **Step 5: Lancer tous les tests audio**

```bash
flutter test test/unit/audio/
```

Attendu : PASS, tous les tests des tâches 1 à 6.

- [ ] **Step 6: Vérifier**

```bash
dart analyze && flutter test
```

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(audio): persister les reglages audio hors de la sauvegarde de run"
```

---

## Task 7: Garde-fous du catalogue

Deux garde-fous **asymétriques** : l'un échoue la CI, l'autre jamais.

**Files:**
- Test: `test/unit/audio/audio_catalogue_test.dart`
- Test: `test/unit/audio/audio_sourcing_report_test.dart`

**Interfaces:**
- Consumes: `AudioData` (tâche 2), champ `sfx` des modèles (tâche 4)
- Produces: rien de code — deux tests

- [ ] **Step 1: Écrire le test bloquant de cohérence**

`test/unit/audio/audio_catalogue_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';

Map<String, dynamic> _readJsonMap(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<dynamic> _readJsonList(String path) =>
    jsonDecode(File(path).readAsStringSync()) as List<dynamic>;

void main() {
  group('Coherence du catalogue audio', () {
    late AudioData audio;

    setUp(() {
      audio = AudioData.fromJson(_readJsonMap('assets/data/audio.json'));
    });

    test('tout son reference par un moment est declare', () {
      final referenced = <String>{};
      for (final moment in audio.moments.values) {
        if (moment.defaultSound != null) referenced.add(moment.defaultSound!);
        referenced.addAll(moment.byAnimation.values);
      }

      final unknown = referenced.difference(audio.sounds.keys.toSet());

      expect(unknown, isEmpty,
          reason: 'Sons references par un moment mais absents de "sounds" : $unknown');
    });

    test('tout champ sfx d un JSON de contenu correspond a un son declare', () {
      const contentFiles = [
        'assets/data/cards.json',
        'assets/data/hero_cards.json',
        'assets/data/enemies.json',
        'assets/data/relics.json',
      ];

      final declared = audio.sounds.keys.toSet();
      final offenders = <String>[];

      for (final path in contentFiles) {
        for (final entry in _readJsonList(path)) {
          final map = entry as Map<String, dynamic>;
          final sfx = map['sfx'] as String?;
          if (sfx != null && !declared.contains(sfx)) {
            offenders.add('$path :: ${map['id']} -> "$sfx"');
          }
        }
      }

      expect(offenders, isEmpty,
          reason: 'Champs sfx pointant vers un son non declare :\n${offenders.join('\n')}');
    });
  });
}
```

- [ ] **Step 2: Lancer le test**

```bash
flutter test test/unit/audio/audio_catalogue_test.dart
```

Attendu : PASS, 2 tests — aucun JSON de contenu ne porte encore de champ `sfx`, et `audio.json` est cohérent avec lui-même.

- [ ] **Step 3: Écrire le rapport non bloquant de sourcing**

`test/unit/audio/audio_sourcing_report_test.dart` :

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';

/// Ce test ne verifie rien : il **rapporte**. C'est le tableau de bord du
/// sourcing, deliberement incapable de rougir la CI. Un catalogue troue est
/// l'etat normal du projet pendant tout le chantier P-03.
void main() {
  test('rapport de sourcing : fichiers declares mais absents du disque', () {
    final audio = AudioData.fromJson(
      jsonDecode(File('assets/data/audio.json').readAsStringSync()) as Map<String, dynamic>,
    );

    final expected = <String>[];
    for (final sound in audio.sounds.values) {
      if (sound.variants <= 1) {
        expected.add(sound.file);
      } else {
        final dot = sound.file.lastIndexOf('.');
        for (var i = 1; i <= sound.variants; i++) {
          expected.add('${sound.file.substring(0, dot)}_$i${sound.file.substring(dot)}');
        }
      }
    }
    expected.addAll(audio.music.values.map((m) => m.file));

    final missing =
        expected.where((f) => !File('assets/audio/$f').existsSync()).toList()..sort();
    final present = expected.length - missing.length;

    debugPrint('');
    debugPrint('===== SOURCING AUDIO : $present / ${expected.length} fichiers presents =====');
    if (missing.isEmpty) {
      debugPrint('Catalogue complet.');
    } else {
      for (final file in missing) {
        debugPrint('  manquant : assets/audio/$file');
      }
    }
    debugPrint('=========================================================');

    // Aucune assertion : ce test reussit toujours, par construction.
  });
}
```

- [ ] **Step 4: Lancer le rapport et lire sa sortie**

```bash
flutter test test/unit/audio/audio_sourcing_report_test.dart --reporter expanded
```

Attendu : PASS, avec la liste complète des fichiers manquants affichée — 21 à ce stade (17 sons dont un en 3 variantes, plus 4 musiques).

- [ ] **Step 5: Vérifier**

```bash
dart analyze && flutter test
```

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "test(audio): garder la coherence du catalogue et rapporter l avancee du sourcing"
```

---

## Task 8: Injection dans Flame et les quatre moments d'impact

`triggerHitReactions()` est un entonnoir unique — quatre moments s'y branchent d'un coup, héros et ennemis couverts.

**Files:**
- Modify: `lib/game/heros_draft_game.dart:29-87` (champ `audio` + constructeur)
- Modify: `lib/game/components/entities/combat_entity.dart:175-215`
- Modify: `lib/ui/screens/game_screen.dart:243`
- Modify: `lib/services/audio/audio_providers.dart` (ajouter `audioDirectorProvider`)
- Test: `test/unit/audio/audio_impact_moments_test.dart`

**Interfaces:**
- Consumes: `AudioDirector` (tâches 3 et 6)
- Produces: `HerosDraftGame.audio` de type `AudioDirector` (champ `final`, paramètre nommé requis `audio:`) · `final audioDirectorProvider = Provider<AudioDirector>`

> **Rappel d'architecture :** `HerosDraftGame` n'a **aucun** accès à Riverpod — il est découplé par quinze callbacks injectés depuis `GameScreen`. Le directeur est donc un **collaborateur injecté**, pas un provider lu. La lecture du provider a lieu dans `GameScreen`, couche UI. Ne jamais importer `flutter_riverpod` dans un fichier de `lib/game/components/`.

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/audio_impact_moments_test.dart`. On teste la **décision** du directeur, pas le rendu Flame — instancier un `HerosDraftGame` complet en test serait lourd et fragile.

> **Limite connue et assumée, à ne pas signaler comme un oubli en revue :** aucun test automatique ne vérifie que les appels sont réellement posés aux bons endroits de `combat_entity.dart`. Seule la résolution est couverte. Le câblage se vérifie à l'exécution, en tâche 12 step 5. L'alternative — monter un `HerosDraftGame` complet dans un test widget — est disproportionnée pour le style de test de ce dépôt.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        'impact_normal': {'file': 'sfx/impact_normal.mp3'},
        'impact_crit': {'file': 'sfx/impact_crit.mp3'},
        'armor_hit': {'file': 'sfx/armor_hit.mp3'},
        'heal': {'file': 'sfx/heal.mp3'},
      },
      'moments': {
        'impact': {'default': 'impact_normal'},
        'impact_crit': {'default': 'impact_crit'},
        'armor_hit': {'default': 'armor_hit'},
        'heal': {'default': 'heal'},
      },
      'music': <String, dynamic>{},
    });

void main() {
  group('Moments d impact', () {
    late FakeAudioBackend backend;
    late AudioDirector director;

    setUp(() async {
      backend = FakeAudioBackend();
      director = AudioDirector(
        backend: backend,
        data: _catalogue(),
        settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
      );
      await director.preloadAll();
    });

    test('les quatre moments d impact resolvent chacun vers leur son', () {
      director.onMoment(GameMoment.impact);
      director.onMoment(GameMoment.impactCrit);
      director.onMoment(GameMoment.armorHit);
      director.onMoment(GameMoment.heal);

      expect(backend.playedOnce, [
        'sfx/impact_normal.mp3',
        'sfx/impact_crit.mp3',
        'sfx/armor_hit.mp3',
        'sfx/heal.mp3',
      ]);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il passe déjà**

```bash
flutter test test/unit/audio/audio_impact_moments_test.dart
```

Attendu : PASS. Ce test documente le contrat que le branchement doit honorer ; le branchement lui-même se vérifie ensuite à l'analyse et en jeu.

- [ ] **Step 3: Exposer le directeur par un provider**

Dans `lib/services/audio/audio_providers.dart`, ajouter, avec l'import de `gameDataLoaderProvider` et de `AudioDirector` :

```dart
/// Le directeur depend du catalogue, donc du chargement asynchrone des
/// donnees. Tant que celui-ci n'a pas abouti, on rend un directeur sur
/// catalogue desactive : silencieux, jamais nul, jamais en erreur.
final audioDirectorProvider = Provider<AudioDirector>((ref) {
  final registry = ref.watch(gameDataLoaderProvider).valueOrNull;
  final director = AudioDirector(
    backend: ref.watch(audioBackendProvider),
    data: registry?.audio ?? const AudioData.disabled(),
    settings: () => ref.read(audioSettingsProvider),
  );
  unawaited(director.preloadAll());
  return director;
});
```

Ajouter `import 'dart:async';` pour `unawaited`, plus les imports de `game_data_service.dart`, `audio_data.dart` et `audio_director.dart`.

- [ ] **Step 4: Injecter le directeur dans le jeu Flame**

Dans `lib/game/heros_draft_game.dart`, ajouter l'import `import '../services/audio/audio_director.dart';`, puis le champ auprès des autres champs `final` du constructeur :

```dart
  /// Injecte depuis `GameScreen` : la couche Flame ne lit jamais un provider.
  final AudioDirector audio;
```

et le paramètre `required this.audio,` dans le constructeur.

Dans `lib/ui/screens/game_screen.dart:243`, ajouter en première ligne des arguments nommés :

```dart
    _game = HerosDraftGame(
      audio: ref.read(audioDirectorProvider),
      onEnemiesDead: _handleCombatVictory,
```

avec l'import `import '../../services/audio/audio_providers.dart';`.

- [ ] **Step 5: Brancher les quatre moments dans l'entonnoir**

Dans `lib/game/components/entities/combat_entity.dart`, méthode `triggerHitReactions`, ajouter l'import `import '../../../services/audio/game_moment.dart';` puis :

- dans la branche `newStats.armure < oldStats.armure`, juste avant `shieldHitAnimation();` :

```dart
        game.audio.onMoment(GameMoment.armorHit);
```

- dans la branche `newStats.armure > oldStats.armure`, après le `spawnFloatingText` :

```dart
        game.audio.onMoment(GameMoment.armorHit);
```

- dans la branche `newStats.currentPv < oldStats.currentPv`, juste après le calcul de `isCritical` :

```dart
      game.audio.onMoment(isCritical ? GameMoment.impactCrit : GameMoment.impact);
```

- ajouter la branche de soin, immédiatement après le bloc de perte de PV :

```dart
    if (newStats.currentPv > oldStats.currentPv) {
      game.audio.onMoment(GameMoment.heal);
    }
```

- [ ] **Step 6: Vérifier**

```bash
dart analyze
```

Attendu : `No issues found!`

```bash
flutter test
```

Attendu : tous au vert. Les tests widget qui construisent un `HerosDraftGame` échoueront à la compilation faute du paramètre `audio` — leur ajouter l'argument est autorisé au même titre qu'en tâche 2. Repérer les sites avec :

```bash
grep -rn "HerosDraftGame(" test/ lib/
```

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat(audio): sonoriser les quatre moments d impact par l entonnoir unique"
```

---

## Task 9: Les dix moments restants

**Files:**
- Modify: `lib/game/heros_draft_game.dart:89` (`setHoveredCard`), `:220` (`resolvePendingDeaths`), `:297` (`executeTurn`), `:360` (`_enemyRipostePhase`)
- Modify: `lib/game/components/visual_effects/card_animator.dart`
- Modify: `lib/game/controllers/combat/turn_phase_manager.dart`
- Modify: `lib/game/controllers/deck_controller.dart`
- Modify: `lib/game/services/effects/strategies.dart:94` (`GainManaEffectStrategy`)
- Modify: `lib/game/services/effect_resolver.dart:99`
- Modify: `lib/game/controllers/run/player_stats_manager.dart:438`
- Test: `test/unit/audio/audio_remaining_moments_test.dart`

**Interfaces:**
- Consumes: `HerosDraftGame.audio` (tâche 8), `GameMoment` (tâche 3)
- Produces: aucun symbole nouveau

> **Contrainte de couche.** Les six derniers fichiers sont des contrôleurs et services Riverpod, pas des composants Flame : ils lisent `audioDirectorProvider` par `ref.read`, ce qui est autorisé et normal à cette couche. Seuls les fichiers de `lib/game/components/` et `heros_draft_game.dart` passent par `game.audio`.

- [ ] **Step 1: Écrire le test des dix moments**

`test/unit/audio/audio_remaining_moments_test.dart`. Même limite assumée qu'en tâche 8 : le test couvre la résolution, pas la pose des appels. Le câblage se vérifie à l'exécution en tâche 12 step 5 — ce n'est pas un oubli à signaler en revue.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/audio_source.dart';
import 'package:roguelike_card_game/services/audio/game_moment.dart';

import 'fake_audio_backend.dart';

class _Source implements AudioSource {
  @override
  final String? sfx;
  @override
  final String? animation;

  const _Source({this.sfx, this.animation});
}

const _ids = <String>[
  'card_hover',
  'card_pickup',
  'card_play_generic',
  'card_play_magic',
  'enemy_attack',
  'enemy_death',
  'card_draw',
  'mana_gain',
  'insufficient_mana',
  'turn_start',
  'turn_end',
];

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': {
        for (final id in _ids) id: {'file': 'sfx/$id.mp3'},
      },
      'moments': {
        'card_hover': {'default': 'card_hover'},
        'card_pickup': {'default': 'card_pickup'},
        'card_play': {
          'default': 'card_play_generic',
          'byAnimation': {'magic': 'card_play_magic'},
        },
        'enemy_attack': {'default': 'enemy_attack'},
        'enemy_death': {'default': 'enemy_death'},
        'card_draw': {'default': 'card_draw'},
        'mana_gain': {'default': 'mana_gain'},
        'insufficient_mana': {'default': 'insufficient_mana'},
        'turn_start': {'default': 'turn_start'},
        'turn_end': {'default': 'turn_end'},
      },
      'music': <String, dynamic>{},
    });

void main() {
  group('Les dix moments restants', () {
    late FakeAudioBackend backend;
    late AudioDirector director;

    setUp(() async {
      backend = FakeAudioBackend();
      director = AudioDirector(
        backend: backend,
        data: _catalogue(),
        settings: () => const AudioSettings(master: 1.0, sfx: 1.0),
      );
      await director.preloadAll();
    });

    test('chaque moment systemique resout vers son son', () {
      director.onMoment(GameMoment.cardHover);
      director.onMoment(GameMoment.cardPickup);
      director.onMoment(GameMoment.enemyAttack);
      director.onMoment(GameMoment.enemyDeath);
      director.onMoment(GameMoment.cardDraw);
      director.onMoment(GameMoment.manaGain);
      director.onMoment(GameMoment.insufficientMana);
      director.onMoment(GameMoment.turnStart);
      director.onMoment(GameMoment.turnEnd);

      expect(backend.playedOnce, [
        'sfx/card_hover.mp3',
        'sfx/card_pickup.mp3',
        'sfx/enemy_attack.mp3',
        'sfx/enemy_death.mp3',
        'sfx/card_draw.mp3',
        'sfx/mana_gain.mp3',
        'sfx/insufficient_mana.mp3',
        'sfx/turn_start.mp3',
        'sfx/turn_end.mp3',
      ]);
    });

    test('cardPlay resout par le type d animation de la carte', () {
      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'magic'));

      expect(backend.playedOnce, ['sfx/card_play_magic.mp3']);
    });

    test('cardPlay sans animation connue retombe sur le generique', () {
      director.onMoment(GameMoment.cardPlay, source: const _Source(animation: 'inconnu'));

      expect(backend.playedOnce, ['sfx/card_play_generic.mp3']);
    });
  });
}
```

- [ ] **Step 2: Lancer le test**

```bash
flutter test test/unit/audio/audio_remaining_moments_test.dart
```

Attendu : PASS.

- [ ] **Step 3: Brancher les moments côté Flame**

- `heros_draft_game.dart:89`, dans `setHoveredCard`, ne jouer que sur une carte réellement nouvelle pour éviter la répétition à chaque frame :

```dart
  void setHoveredCard(CardComponent? card) {
    if (card != null && card != hoveredCard) {
      audio.onMoment(GameMoment.cardHover);
    }
    cardAnimationSystem?.setHoveredCard(card);
```

- `heros_draft_game.dart:220`, dans `resolvePendingDeaths`, appeler `audio.onMoment(GameMoment.enemyDeath);` une fois par ennemi effectivement retiré.
- `heros_draft_game.dart:297`, dans `executeTurn`, appeler `audio.onMoment(GameMoment.turnEnd);` en première instruction.
- `heros_draft_game.dart:360`, dans `_enemyRipostePhase`, appeler `audio.onMoment(GameMoment.enemyAttack);` immédiatement avant chaque `enemy.dashAnimation();`.
- `card_animator.dart` : `audio.onMoment(GameMoment.cardPickup)` au début de l'animation de prise en main, et `audio.onMoment(GameMoment.cardPlay, source: card.data)` au début de l'animation de jeu. Le `CardAnimator` accède au jeu par sa référence existante ; si elle n'existe pas, lui passer `AudioDirector` en paramètre de constructeur plutôt que d'importer Riverpod.

- [ ] **Step 4: Brancher les moments côté contrôleurs**

Dans chacun de ces fichiers, obtenir le directeur par `ref.read(audioDirectorProvider)` :

- `turn_phase_manager.dart`, dans `startPlayerTurn()` : `GameMoment.turnStart`.
- `deck_controller.dart`, dans `drawCards()` : `GameMoment.cardDraw`, **une seule fois par appel** même si plusieurs cartes sont piochées, et seulement si au moins une carte l'a effectivement été.
- `strategies.dart:94`, `GainManaEffectStrategy.resolve` : `GameMoment.manaGain`.
- `effect_resolver.dart:99`, dans la branche de mana insuffisante : `GameMoment.insufficientMana`.
- `player_stats_manager.dart:438`, dans la branche de mana insuffisante pour une compétence : `GameMoment.insufficientMana`.

- [ ] **Step 5: Vérifier**

```bash
dart analyze && flutter test
```

Attendu : `No issues found!` et tous les tests au vert.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(audio): brancher les dix moments de jeu restants"
```

---

## Task 10: Chef d'orchestre de la musique

**Files:**
- Create: `lib/services/audio/music_scene.dart`
- Create: `lib/services/audio/music_conductor.dart`
- Modify: `lib/services/audio/audio_providers.dart`
- Test: `test/unit/audio/music_conductor_test.dart`

**Interfaces:**
- Consumes: `AudioBackend`, `AudioData`, `AudioSettings`
- Produces: `enum MusicScene {menu, map, combat, boss}` portant `final String jsonKey` · `class MusicConductor` avec `MusicConductor({required AudioBackend backend, required AudioData data, required AudioSettings Function() settings, bool locked = false})`, `void onScene(MusicScene scene)`, `void unlock()`, `Future<void> refreshVolume()`, `MusicScene? get currentScene` · `final musicConductorProvider = Provider<MusicConductor>`

> **Frontière volontaire :** le fondu enchaîné n'est **pas** implémenté ici. Le conducteur décide *quelle* piste et *si* elle change ; le fondu est un détail de plateforme, passé au backend via `fadeMs` et implémenté dans `FlameAudioBackend` (tâche 12). Cela garde le conducteur entièrement déterministe et testable sans timer.

- [ ] **Step 1: Écrire le test qui échoue**

`test/unit/audio/music_conductor_test.dart` :

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/music_conductor.dart';
import 'package:roguelike_card_game/services/audio/music_scene.dart';

import 'fake_audio_backend.dart';

AudioData _catalogue() => AudioData.fromJson({
      'schemaVersion': 1,
      'sounds': <String, dynamic>{},
      'moments': <String, dynamic>{},
      'music': {
        'menu': {'file': 'music/menu.mp3', 'volume': 0.6},
        'map': {'file': 'music/map.mp3'},
        'combat': {'file': 'music/combat.mp3'},
      },
    });

MusicConductor _conductor(FakeAudioBackend backend, {bool locked = false}) =>
    MusicConductor(
      backend: backend,
      data: _catalogue(),
      settings: () => const AudioSettings(master: 1.0, music: 1.0),
      locked: locked,
    );

void main() {
  group('MusicConductor', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('une scene demarre sa piste au volume declare', () {
      _conductor(backend).onScene(MusicScene.menu);

      expect(backend.currentLoop, 'music/menu.mp3');
      expect(backend.loopStartCount, 1);
      expect(backend.currentLoopVolume, closeTo(0.6, 0.0001),
          reason: 'volume de la piste (0.6) x general (1.0) x musique (1.0)');
    });

    test('redemander la scene en cours est un no-op', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.menu);

      expect(backend.loopStartCount, 1,
          reason: 'naviguer entre deux ecrans du meme groupe ne redemarre pas la musique');
    });

    test('changer de scene remplace la piste', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.combat);

      expect(backend.currentLoop, 'music/combat.mp3');
      expect(backend.loopStartCount, 2);
    });

    test('une scene sans piste declaree ne casse rien', () {
      final conductor = _conductor(backend);

      conductor.onScene(MusicScene.menu);
      expect(() => conductor.onScene(MusicScene.boss), returnsNormally);
      expect(backend.currentLoop, 'music/menu.mp3',
          reason: 'faute de piste de boss, la precedente continue');
    });

    test('verrouille, aucune piste ne demarre', () {
      _conductor(backend, locked: true).onScene(MusicScene.menu);

      expect(backend.currentLoop, isNull);
    });

    test('le deverrouillage demarre la scene en attente', () {
      final conductor = _conductor(backend, locked: true);

      conductor.onScene(MusicScene.map);
      expect(backend.currentLoop, isNull);

      conductor.unlock();

      expect(backend.currentLoop, 'music/map.mp3');
    });

    test('le deverrouillage sans scene en attente ne joue rien', () {
      final conductor = _conductor(backend, locked: true);

      conductor.unlock();

      expect(backend.currentLoop, isNull);
    });

    test('la coupure arrete la piste en cours', () async {
      var muted = false;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: 1.0, music: 1.0, muted: muted),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.currentLoop, 'music/menu.mp3');

      muted = true;
      await conductor.refreshVolume();

      expect(backend.currentLoop, isNull);
    });
  });
}
```

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/unit/audio/music_conductor_test.dart
```

Attendu : ÉCHEC, `music_scene.dart` introuvable.

- [ ] **Step 3: Écrire les scènes**

`lib/services/audio/music_scene.dart` :

```dart
/// Les quatre ambiances musicales du jeu. Une scene, une piste.
enum MusicScene {
  /// Accueil, Reglages, Notes de version, Dictionnaire, Selection de classe.
  menu('menu'),

  /// Carte du monde, Boutique, Evenement, Repos, Forge, Echange de reliques.
  map('map'),

  /// Combat standard et elite.
  combat('combat'),

  /// Combat de boss.
  boss('boss');

  const MusicScene(this.jsonKey);

  final String jsonKey;
}
```

- [ ] **Step 4: Écrire le conducteur**

`lib/services/audio/music_conductor.dart` :

```dart
import '../../models/data/audio_data.dart';
import 'audio_backend.dart';
import 'audio_settings.dart';
import 'music_scene.dart';

/// Traduit une scene en piste de fond, et rien d'autre.
///
/// Le fondu enchaine n'est pas ici : le conducteur decide *quelle* piste et
/// *si* elle change, le backend sait la faire entrer en douceur. Cette
/// frontiere garde le conducteur deterministe, donc testable sans timer.
class MusicConductor {
  MusicConductor({
    required AudioBackend backend,
    required AudioData data,
    required AudioSettings Function() settings,
    bool locked = false,
  })  : _backend = backend,
        _data = data,
        _settings = settings,
        _locked = locked;

  static const int _fadeMs = 400;

  final AudioBackend _backend;
  final AudioData _data;
  final AudioSettings Function() _settings;

  bool _locked;
  MusicScene? _pending;
  MusicScene? _current;

  MusicScene? get currentScene => _current;

  /// Idempotent : redemander la scene en cours ne fait rien. C'est ce qui
  /// rend sur de l'appeler depuis un `build()`, y compris au retour arriere.
  void onScene(MusicScene scene) {
    if (_locked) {
      _pending = scene;
      return;
    }
    if (scene == _current) return;
    if (!_data.enabled) return;

    final track = _data.music[scene.jsonKey];
    if (track == null) return; // Piste non declaree : la precedente continue.

    _current = scene;

    final volume = track.volume * _settings().effectiveMusic;
    if (volume <= 0) {
      _backend.stopLoop(fadeMs: _fadeMs);
      return;
    }
    _backend.playLoop(track.file, volume: volume, fadeMs: _fadeMs);
  }

  /// Appele au premier geste utilisateur sur le web, ou l'autoplay est bloque.
  void unlock() {
    if (!_locked) return;
    _locked = false;

    final pending = _pending;
    _pending = null;
    if (pending != null) onScene(pending);
  }

  /// A appeler quand les reglages changent : reapplique le volume, ou coupe.
  Future<void> refreshVolume() async {
    final scene = _current;
    if (scene == null) return;

    final track = _data.music[scene.jsonKey];
    if (track == null) return;

    final volume = track.volume * _settings().effectiveMusic;
    if (volume <= 0) {
      await _backend.stopLoop(fadeMs: _fadeMs);
      _current = null;
      return;
    }
    await _backend.playLoop(track.file, volume: volume, fadeMs: _fadeMs);
  }
}
```

- [ ] **Step 5: Exposer le conducteur**

Dans `lib/services/audio/audio_providers.dart`, sur le modèle de `audioDirectorProvider` :

```dart
final musicConductorProvider = Provider<MusicConductor>((ref) {
  final registry = ref.watch(gameDataLoaderProvider).valueOrNull;
  return MusicConductor(
    backend: ref.watch(audioBackendProvider),
    data: registry?.audio ?? const AudioData.disabled(),
    settings: () => ref.read(audioSettingsProvider),
    locked: kIsWeb,
  );
});
```

avec `import 'package:flutter/foundation.dart';` pour `kIsWeb`.

- [ ] **Step 6: Lancer le test pour vérifier qu'il passe**

```bash
flutter test test/unit/audio/music_conductor_test.dart
```

Attendu : PASS, 8 tests.

- [ ] **Step 7: Vérifier**

```bash
dart analyze && flutter test
```

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(audio): piloter la musique de fond par scene, idempotent au retour arriere"
```

---

## Task 11: Câblage des scènes et déverrouillage web

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/ui/screens/home_screen.dart`, `map_screen.dart`, `game_screen.dart`, `shop_screen.dart`, `event_screen.dart`, `rest_screen.dart`, `forge_fusion_screen.dart`, `relic_exchange_screen.dart`, `class_selection_screen.dart`, `patch_notes_screen.dart`, `card_dictionary_screen.dart`, `deck_screen.dart`, `draft_screen.dart`, `starter_deck_draft_screen.dart`, `boss_card_draft_screen.dart`, `rest_card_selection_screen.dart`
- Test: aucun test neuf — le comportement est verrouillé par la tâche 10

**Interfaces:**
- Consumes: `musicConductorProvider`, `MusicScene` (tâche 10)
- Produces: aucun symbole nouveau

- [ ] **Step 1: Poser le capteur de premier geste**

Dans `lib/main.dart`, envelopper l'arbre dans un `Listener` qui déverrouille au premier pointeur. Remplacer le `builder:` existant de `MaterialApp` :

```dart
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => ref.read(musicConductorProvider).unlock(),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const GameNotificationOverlay(),
            ],
          ),
        );
      },
```

`unlock()` est déjà un no-op après le premier appel : le laisser sur chaque pointeur est sûr et évite d'ajouter un état local.

- [ ] **Step 2: Hydrater les réglages au démarrage**

Toujours dans `HerosDraftApp.build`, à côté du `ref.watch(autosaveOrchestratorProvider)` existant :

```dart
    ref.watch(audioSettingsHydrationProvider);
```

et dans `audio_providers.dart` :

```dart
/// Charge les reglages persistes une seule fois, au demarrage.
final audioSettingsHydrationProvider = FutureProvider<void>(
  (ref) => ref.read(audioSettingsProvider.notifier).hydrate(),
);
```

- [ ] **Step 3: Déclarer la scène de chaque écran**

Dans le `build()` de chaque écran listé, en première instruction :

```dart
    ref.read(musicConductorProvider).onScene(MusicScene.menu);
```

Correspondances :

| Scène | Écrans |
|:---|:---|
| `MusicScene.menu` | `home_screen`, `class_selection_screen`, `patch_notes_screen`, `card_dictionary_screen`, `deck_screen` |
| `MusicScene.map` | `map_screen`, `shop_screen`, `event_screen`, `rest_screen`, `rest_card_selection_screen`, `forge_fusion_screen`, `relic_exchange_screen`, `draft_screen`, `starter_deck_draft_screen`, `boss_card_draft_screen` |
| `MusicScene.combat` / `MusicScene.boss` | `game_screen`, selon que la rencontre est un boss — utiliser l'information de nœud déjà disponible dans l'écran |

L'appel depuis `build()` est sûr **parce que `onScene` est idempotent** : il ne fait rien quand la scène ne change pas, et se corrige tout seul au retour arrière, là où un appel dans `initState` laisserait la mauvaise piste.

Pour les écrans qui ne sont pas des `ConsumerWidget`/`ConsumerStatefulWidget`, les convertir — c'est le pattern dominant du dossier.

- [ ] **Step 4: Vérifier**

```bash
dart analyze && flutter test
```

Attendu : `No issues found!` et tous les tests au vert. Les tests widget existants passent : le conducteur tourne sur `SilentAudioBackend` et un catalogue désactivé.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat(audio): declarer la scene musicale de chaque ecran et deverrouiller sur le web"
```

---

## Task 12: Backend réel `flame_audio`

C'est seulement ici que la dépendance entre dans le projet. Les onze tâches précédentes sont complètes et testées sans elle.

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/services/audio/flame_audio_backend.dart`
- Modify: `lib/main.dart`
- Test: aucun test unitaire — ce fichier est le point de contact avec la plateforme, il se vérifie en exécution

**Interfaces:**
- Consumes: `AudioBackend` (tâche 1)
- Produces: `class FlameAudioBackend implements AudioBackend`

- [ ] **Step 1: Ajouter la dépendance**

Dans `pubspec.yaml`, sous `dependencies:`, après `flame: ^1.17.0` :

```yaml
  flame_audio: ^2.10.0
```

```bash
flutter pub get
```

Attendu : résolution sans conflit. **Si le solveur refuse**, ne pas forcer : relever la contrainte exacte qu'il propose pour `flame ^1.17.0` et l'utiliser, puis noter la version retenue dans le message de commit.

- [ ] **Step 2: Écrire le backend réel**

`lib/services/audio/flame_audio_backend.dart` :

```dart
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import 'audio_backend.dart';

/// La SEULE classe du projet qui importe `flame_audio`.
///
/// Toutes les methodes avalent leurs erreurs : l'audio n'a pas le droit de
/// faire echouer le jeu. Les chemins sont relatifs a `assets/audio/`, ce que
/// FlameAudio prend comme racine par defaut.
class FlameAudioBackend implements AudioBackend {
  @override
  Future<bool> preload(String file) async {
    try {
      await FlameAudio.audioCache.load(file);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void playOnce(String file, {double volume = 1.0}) {
    try {
      FlameAudio.play(file, volume: volume);
    } catch (_) {
      // Silence volontaire : un bruitage rate n'interrompt pas une partie.
    }
  }

  @override
  Future<void> playLoop(String file, {double volume = 1.0, int fadeMs = 0}) async {
    try {
      if (FlameAudio.bgm.isPlaying) {
        await FlameAudio.bgm.stop();
      }
      await FlameAudio.bgm.play(file, volume: volume);
    } catch (e) {
      debugPrint('[audio] echec de lecture de la boucle "$file" : $e');
    }
  }

  @override
  Future<void> stopLoop({int fadeMs = 0}) async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {
      // Idem : rien a recuperer.
    }
  }
}
```

> **Note sur `fadeMs` :** le paramètre est accepté mais pas encore honoré — `FlameAudio.bgm` n'expose pas de fondu natif. La transition est franche dans cette version. Le paramètre existe pour que le fondu s'ajoute ici sans toucher au conducteur ni à son contrat. C'est un manque connu et assumé, pas un oubli : le signaler tel quel dans la documentation de la tâche 14.

- [ ] **Step 3: Brancher le backend réel dans `main.dart`**

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        audioBackendProvider.overrideWithValue(FlameAudioBackend()),
      ],
      child: const HerosDraftApp(),
    ),
  );
}
```

Retirer le `const` devant `ProviderScope`, ajouter les imports de `audio_providers.dart` et `flame_audio_backend.dart`.

- [ ] **Step 4: Vérifier**

```bash
dart analyze && flutter test
```

Attendu : `No issues found!` et tous les tests au vert — `main.dart` n'est pas exécuté par les tests, la surcharge ne les atteint pas. **C'est la vérification qui valide la décision D4 de la spec.**

- [ ] **Step 5: Vérifier en exécution**

```bash
flutter run -d windows
```

Attendu : le jeu démarre, aucune exception audio dans la console, et le rapport de sourcing indique toujours les fichiers manquants. Le jeu est silencieux tant que le catalogue est vide — **c'est le comportement correct**.

**Vérification du câblage des tâches 8 et 9** — c'est le seul contrôle du fait que les appels sont posés au bon endroit, aucun test ne le couvre. Déposer un fichier MP3 court et audible dans `assets/audio/sfx/`, nommé d'après un son du catalogue (`impact_normal_1.mp3` est le plus facile à déclencher), relancer, et frapper un ennemi. Si le son sort à l'impact, la chaîne complète — point d'appel, résolution, disponibilité, backend — est vérifiée de bout en bout. Répéter avec `turn_start.mp3` pour couvrir un moment côté contrôleur. Retirer ensuite le fichier de test s'il n'est pas destiné à rester.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(audio): brancher le backend flame_audio dans l application reelle"
```

---

## Task 13: Écran de réglages et coupure en jeu

**Files:**
- Create: `lib/ui/screens/settings_screen.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Modify: `lib/ui/screens/home_screen.dart`
- Modify: `lib/ui/screens/game_screen.dart` (icône de coupure dans le HUD)
- Test: `test/widget/settings_screen_test.dart`

**Interfaces:**
- Consumes: `audioSettingsProvider`, `musicConductorProvider`
- Produces: `class SettingsScreen extends ConsumerWidget`

- [ ] **Step 1: Ajouter les libellés bilingues**

Dans `lib/l10n/app_fr.arb` :

```json
  "settingsTitle": "Réglages",
  "audioSection": "Audio",
  "volumeMaster": "Volume général",
  "volumeSfx": "Bruitages",
  "volumeMusic": "Musique",
  "muteAll": "Couper le son",
```

Dans `lib/l10n/app_en.arb`, les mêmes clés : `"Settings"`, `"Audio"`, `"Master volume"`, `"Sound effects"`, `"Music"`, `"Mute all"`.

```bash
flutter gen-l10n
```

- [ ] **Step 2: Écrire le test qui échoue**

`test/widget/settings_screen_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/services/audio/audio_providers.dart';
import 'package:roguelike_card_game/ui/screens/settings_screen.dart';

Widget _harness() => const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en', ''), Locale('fr', '')],
        locale: Locale('fr', ''),
        home: SettingsScreen(),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SettingsScreen', () {
    testWidgets('affiche trois curseurs et un interrupteur', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsNWidgets(3));
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('l interrupteur bascule la coupure globale', (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(element);
      expect(container.read(audioSettingsProvider).muted, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(container.read(audioSettingsProvider).muted, isTrue);
    });

    testWidgets('deplacer le curseur des bruitages met a jour le reglage',
        (tester) async {
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(SettingsScreen));
      final container = ProviderScope.containerOf(element);

      await tester.drag(find.byType(Slider).at(1), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(container.read(audioSettingsProvider).sfx, lessThan(1.0));
    });
  });
}
```

- [ ] **Step 3: Lancer le test pour vérifier qu'il échoue**

```bash
flutter test test/widget/settings_screen_test.dart
```

Attendu : ÉCHEC, `settings_screen.dart` introuvable.

- [ ] **Step 4: Écrire l'écran**

`lib/ui/screens/settings_screen.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../services/audio/audio_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);
    final conductor = ref.read(musicConductorProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.audioSection, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _VolumeSlider(
            label: l10n.volumeMaster,
            value: settings.master,
            onChanged: (v) {
              notifier.setMaster(v);
              conductor.refreshVolume();
            },
          ),
          _VolumeSlider(
            label: l10n.volumeSfx,
            value: settings.sfx,
            onChanged: notifier.setSfx,
          ),
          _VolumeSlider(
            label: l10n.volumeMusic,
            value: settings.music,
            onChanged: (v) {
              notifier.setMusic(v);
              conductor.refreshVolume();
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(l10n.muteAll),
            value: settings.muted,
            onChanged: (_) {
              notifier.toggleMute();
              conductor.refreshVolume();
            },
          ),
        ],
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            label: '${(value * 100).round()} %',
            divisions: 20,
          ),
        ),
      ],
    );
  }
}
```

Les couleurs viennent du thème (`Theme.of(context)`), jamais en dur — voir `lib/ui/theme/app_theme.dart`. Le curseur des bruitages n'appelle pas `refreshVolume()` : il ne concerne que les tirs ponctuels, qui relisent les réglages à chaque lecture.

- [ ] **Step 5: Ajouter l'entrée depuis l'accueil**

Dans `home_screen.dart`, un bouton « Réglages » près des boutons existants, poussant `SettingsScreen`.

- [ ] **Step 6: Ajouter la coupure au HUD de combat**

Dans `game_screen.dart`, une `IconButton` (`Icons.volume_up` / `Icons.volume_off`) **rejoignant un groupe de contrôles existant**, sans occuper un nouveau coin. Elle appelle `toggleMute()` puis `refreshVolume()`.

- [ ] **Step 7: Vérifier la géométrie en portrait téléphone**

```bash
flutter run -d chrome
```

Réduire la fenêtre à 390 × 844 (portrait téléphone) et vérifier que l'icône n'introduit **aucun débordement** dans le HUD. L'audit responsive du 05/08 relève que ce HUD déborde déjà : si l'icône aggrave la situation, la déplacer plutôt que de l'accepter, et le signaler dans le commit.

- [ ] **Step 8: Vérifier**

```bash
dart analyze && flutter test
```

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "feat(audio): ajouter l ecran de reglages et la coupure du son en combat"
```

---

## Task 14: Documentation et clôture

**Files:**
- Create: `.obsidian_vault/_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md`
- Create: `.obsidian_vault/_rules/09-00-systeme-audio.md`
- Create: `.obsidian_vault/_patterns/16-00-architecture-du-systeme-audio.md`
- Modify: `docs/ROADMAP.md` (P-03), `docs/INDEX.md`
- Modify: `.obsidian_vault/_memory_bank/` via le skill

- [ ] **Step 1: Vérifier que le numéro d'ADR est toujours libre**

```bash
ls .obsidian_vault/_adr/ | tail -3
```

Attendu : `ADR-081` en dernier. Si un `ADR-082` existe déjà, prendre le suivant libre et corriger les renvois de la spec.

- [ ] **Step 2: Écrire l'ADR**

`ADR-082` documente les huit décisions du §3 de la spec, en particulier : le directeur central plutôt que des appels dispersés, le mapping par données, le backend silencieux par défaut, le rejet du bus d'événements et sa condition de réouverture (un second abonné), et l'asymétrie des deux garde-fous de catalogue.

- [ ] **Step 3: Écrire la fiche de règle**

`_rules/09-00-systeme-audio.md` : les 14 moments et ce qui les déclenche, la chaîne de repli, le format des assets, le contrat de nommage des variantes. C'est la fiche que consultera quelqu'un qui veut donner un son à une carte.

- [ ] **Step 4: Écrire la fiche de pattern**

`_patterns/16-00-architecture-du-systeme-audio.md` : les trois couches, l'injection du directeur dans Flame par constructeur plutôt que par provider, l'idempotence de `onScene` qui rend son appel depuis `build()` correct, la frontière conducteur/backend sur le fondu — **et le fait que `fadeMs` n'est pas encore honoré**.

- [ ] **Step 5: Mettre à jour la ROADMAP**

Cocher P-03 dans le Tier S, **et corriger son estimation** : 3-5 j annoncés, 6-9 j réels hors sourcing, avec les trois postes absents du chiffrage d'origine (musique, écran de réglages, mapping par données). Le Jalon 1 « Socle » est alors clos.

- [ ] **Step 6: Lancer la synchronisation du memory bank**

Invoquer le skill `memory-bank-sync`. Il re-mesure chaque métrique, met à jour `activeContext.md` et `progress.md`, et archive la livraison la plus ancienne.

- [ ] **Step 7: Écrire la note joueur**

Invoquer le skill `patch-notes-writer`. Il déplace ensemble `patch_notes.json`, `pubspec.yaml` et `site/_site/versions.json` — les trois doivent rester dans un seul commit, sinon `verify_version.sh` échoue la release.

- [ ] **Step 8: Vérification finale**

```bash
dart analyze && flutter test
```

Attendu : `No issues found!`, tous les tests au vert.

```bash
flutter test test/unit/audio/audio_sourcing_report_test.dart --reporter expanded
```

Lire le rapport : il dit exactement ce qu'il reste à sourcer.

- [ ] **Step 9: Commit**

```bash
git add -A && git commit -m "docs(vault): documenter le systeme audio et clore le Jalon 1"
```

---

## Ordre d'exécution et points de reprise

Les tâches sont séquentielles, mais le chantier admet **trois paliers livrables** :

| Palier | Tâches | Ce qui marche à la fin |
|:---|:---|:---|
| **Moteur** | 1 → 7 | Tout le système audio est écrit et testé, sans une seule dépendance nouvelle et sans un seul son. Le jeu n'a pas changé |
| **Bruitages** | 8 → 9, puis 12 | Les 14 moments sont branchés et audibles dès qu'un fichier arrive dans `assets/audio/sfx/` |
| **Musique et réglages** | 10 → 11, 13 | Bande-son par scène et contrôle complet du volume |

Si le chantier doit être interrompu, s'arrêter **à la fin d'un palier**, jamais au milieu : chacun laisse le dépôt dans un état cohérent, analysé propre et testé.
