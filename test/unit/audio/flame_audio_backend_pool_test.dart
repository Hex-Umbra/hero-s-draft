import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/audio/flame_audio_backend.dart';

/// Pool d'observation : compte les demarrages sans rien jouer.
class _FakePool implements SfxPool {
  final List<double> startedVolumes = [];
  bool throwOnStart = false;

  @override
  Future<void> start(double volume) async {
    if (throwOnStart) throw StateError('lecteur indisponible');
    startedVolumes.add(volume);
  }
}

void main() {
  group('FlameAudioBackend — reservoir de lecteurs pre-armes', () {
    late List<String> creations;
    late Map<String, _FakePool> pools;
    late Set<String> missing;
    late FlameAudioBackend backend;

    setUp(() {
      creations = [];
      pools = {};
      missing = {};
      backend = FlameAudioBackend(
        poolFactory: (file) async {
          creations.add(file);
          if (missing.contains(file)) return null;
          return pools[file] = _FakePool();
        },
      );
    });

    test('preload cree un pool par fichier', () async {
      await expectLater(backend.preload('sfx/card_hover.wav'), completion(isTrue));
      await expectLater(backend.preload('sfx/card_draw.wav'), completion(isTrue));

      expect(creations, ['sfx/card_hover.wav', 'sfx/card_draw.wav']);
    });

    test('un fichier deja precharge ne recree pas son pool', () async {
      await backend.preload('sfx/card_hover.wav');
      await backend.preload('sfx/card_hover.wav');

      expect(creations, hasLength(1));
    });

    // Le defaut d'origine : `FlameAudio.play` instanciait un `AudioPlayer`
    // natif et enchainait quatre allers-retours de canal de plateforme a
    // CHAQUE son. D'ou une latence audible et, en survol rapide, un
    // empilement qui se vidait d'un coup. Ce test est la garde : le chemin
    // de lecture ne doit plus rien allouer.
    test('playOnce reutilise le pool et n en cree jamais', () async {
      await backend.preload('sfx/card_hover.wav');
      creations.clear();

      backend.playOnce('sfx/card_hover.wav');
      backend.playOnce('sfx/card_hover.wav');
      backend.playOnce('sfx/card_hover.wav');

      expect(creations, isEmpty, reason: 'aucune allocation sur le chemin de lecture');
      expect(pools['sfx/card_hover.wav']!.startedVolumes, hasLength(3));
    });

    test('playOnce transmet le volume demande', () async {
      await backend.preload('sfx/heal.wav');

      backend.playOnce('sfx/heal.wav', volume: 0.42);

      expect(pools['sfx/heal.wav']!.startedVolumes, [0.42]);
    });

    test('playOnce sur un fichier non precharge reste silencieux et n alloue pas', () {
      expect(() => backend.playOnce('sfx/jamais_precharge.wav'), returnsNormally);

      expect(creations, isEmpty);
    });

    test('preload rend false quand le pool ne peut pas etre cree', () async {
      missing.add('sfx/absent.wav');

      await expectLater(backend.preload('sfx/absent.wav'), completion(isFalse));
      // L'echec ne doit pas etre memorise comme un pool utilisable : jouer
      // ce fichier reste silencieux.
      expect(() => backend.playOnce('sfx/absent.wav'), returnsNormally);
    });

    test('un echec de demarrage ne remonte jamais a l appelant', () async {
      await backend.preload('sfx/card_hover.wav');
      pools['sfx/card_hover.wav']!.throwOnStart = true;

      expect(() => backend.playOnce('sfx/card_hover.wav'), returnsNormally);
    });
  });
}
