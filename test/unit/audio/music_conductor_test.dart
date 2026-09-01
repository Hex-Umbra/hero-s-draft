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
      // sfx delibrement different de music : un test qui lirait par erreur
      // effectiveSfx au lieu d'effectiveMusic doit voir une valeur fausse,
      // pas une coincidence qui le laisse passer.
      settings: () => const AudioSettings(master: 1.0, music: 1.0, sfx: 0.2),
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

    test(
        'la musique reprend quand on redemande la meme scene apres une '
        'coupure puis un demutage', () async {
      // Regression : refreshVolume() met _current a null dans sa branche a
      // volume nul, precisement pour que ce cycle fonctionne. onScene() ne
      // le fait pas dans la sienne (voir le commentaire a cote de
      // `_current = null` dans refreshVolume) : c'est l'asymetrie qui rend
      // ce test capable d'echouer si elle disparait.
      var muted = false;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: 1.0, music: 1.0, muted: muted),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.currentLoop, 'music/menu.mp3');
      expect(backend.loopStartCount, 1);

      muted = true;
      await conductor.refreshVolume();
      expect(backend.currentLoop, isNull, reason: 'la coupure arrete la boucle');

      muted = false;
      conductor.onScene(MusicScene.menu);

      expect(
        backend.currentLoop,
        'music/menu.mp3',
        reason: 'refreshVolume() a mis _current a null : redemander la meme '
            "scene n'est donc plus absorbe par le no-op d'idempotence, et la "
            'musique reprend apres la coupure',
      );
      expect(
        backend.loopStartCount,
        2,
        reason: 'sans la nullification dans refreshVolume(), scene == '
            '_current serait reste vrai et onScene() ne relancerait jamais '
            'playLoop',
      );
    });

    test(
        'refreshVolume() redemarre seul la piste apres une coupure, sans '
        'aucun appel a onScene entre les deux', () async {
      // Regression : l'ecran de reglages, seul construit pour changer le
      // volume, n'appelle jamais onScene() (sa scene est heritee, voir
      // music_scene.dart). Si refreshVolume() ne sait pas reprendre seul,
      // la musique reste coupee tant qu on ne quitte pas l'ecran.
      var master = 1.0;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: master, music: 1.0, sfx: 0.2),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.currentLoop, 'music/menu.mp3');
      expect(backend.loopStartCount, 1);

      master = 0.0;
      await conductor.refreshVolume();
      expect(backend.currentLoop, isNull, reason: 'volume nul : la boucle s\'arrete');

      master = 1.0;
      await conductor.refreshVolume();

      expect(
        backend.currentLoop,
        'music/menu.mp3',
        reason: 'un second refreshVolume() a volume positif doit a lui seul '
            'relancer la piste stockee, sans qu aucun ecran ne rappelle '
            'onScene()',
      );
      expect(backend.loopStartCount, 2, reason: 'la boucle a bien redemarre');
    });

    test(
        'deux refreshVolume() concurrents a volume nul ne perdent pas la '
        'scene en attente', () async {
      // Regression : refreshVolume() ecrivait _pending/_current apres le
      // await sur stopLoop(). Les quatre sites d'appel (settings_screen.dart,
      // game_screen.dart) invoquent tous refreshVolume() sans l'attendre :
      // un second appel peut donc demarrer avant que le premier n'ait repris
      // apres son await, et lire l'ancien _current avant qu'il soit mis a
      // null. Les deux ecrivent alors _pending a partir de ce meme _current :
      // le second ecrase avec null ce que le premier venait de poser, et
      // plus aucun refreshVolume() ulterieur ne peut relancer la musique.
      var master = 1.0;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: master, music: 1.0, sfx: 0.2),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.currentLoop, 'music/menu.mp3');
      expect(backend.loopStartCount, 1);

      master = 0.0;
      final first = conductor.refreshVolume();
      final second = conductor.refreshVolume();
      await first;
      await second;

      expect(backend.currentLoop, isNull, reason: 'volume nul : la boucle s\'arrete');

      master = 1.0;
      await conductor.refreshVolume();

      expect(
        backend.currentLoop,
        'music/menu.mp3',
        reason: 'la scene en attente doit survivre a deux refreshVolume() '
            'entrelaces a volume nul, sinon plus aucun refreshVolume() '
            'ulterieur ne peut relancer la musique',
      );
      expect(backend.loopStartCount, 2, reason: 'la boucle a bien redemarre');
    });

    test(
        'refreshVolume() ajuste le volume en place quand la scene ne '
        'change pas, sans redemarrer la piste', () async {
      var music = 1.0;
      final conductor = MusicConductor(
        backend: backend,
        data: _catalogue(),
        settings: () => AudioSettings(master: 1.0, music: music, sfx: 0.2),
      );

      conductor.onScene(MusicScene.menu);
      expect(backend.loopStartCount, 1);
      expect(backend.currentLoopVolume, closeTo(0.6, 0.0001));

      music = 0.5;
      await conductor.refreshVolume();

      expect(
        backend.loopStartCount,
        1,
        reason: 'un ajustement de volume ne doit pas redemarrer la piste '
            'depuis le debut',
      );
      expect(
        backend.currentLoopVolume,
        closeTo(0.3, 0.0001),
        reason: 'piste (0.6) x general (1.0) x musique (0.5)',
      );
      expect(backend.setVolumeCalls, [closeTo(0.3, 0.0001)]);
    });
  });

  group('MusicConductor — piste absente du disque', () {
    late FakeAudioBackend backend;

    setUp(() => backend = FakeAudioBackend());

    test('le prechargement sonde chaque piste declaree', () async {
      await _conductor(backend).preloadAll();

      expect(backend.musicPreloadAttempts,
          ['music/menu.mp3', 'music/map.mp3', 'music/combat.mp3']);
    });

    // Le defaut d'origine : `onScene` allait droit au backend, qui
    // journalisait une erreur a chaque entree de scene, sans deduplication.
    // Le contrat du systeme veut qu'un fichier manquant produise du silence.
    test('une piste absente n est jamais tentee, et ne coupe pas la precedente',
        () async {
      backend.missingFiles.add('music/map.mp3');
      final conductor = _conductor(backend);
      await conductor.preloadAll();

      conductor.onScene(MusicScene.menu);
      conductor.onScene(MusicScene.map);

      expect(backend.currentLoop, 'music/menu.mp3',
          reason: 'la piste precedente continue, comme pour une scene non declaree');
      expect(backend.loopStartCount, 1);
      expect(conductor.currentScene, MusicScene.menu);
    });

    // Le cache est negatif et pas positif, precisement pour ce cas :
    // `preloadAll()` n'est jamais attendu, donc un cache positif serait vide
    // au premier `onScene()` et refuserait a tort une piste presente.
    test('avant la fin du prechargement, la lecture reste tentee', () {
      backend.missingFiles.add('music/menu.mp3');

      _conductor(backend).onScene(MusicScene.menu);

      expect(backend.loopStartCount, 1,
          reason: 'rien n a encore ete conclu sur cette piste');
    });

    test('une piste absente redevient jouable si elle apparait au prochain lancement',
        () async {
      backend.missingFiles.add('music/menu.mp3');
      final premier = _conductor(backend);
      await premier.preloadAll();
      premier.onScene(MusicScene.menu);
      expect(backend.loopStartCount, 0);

      // Nouveau lancement : le fichier a ete pose entre-temps.
      backend.missingFiles.clear();
      final second = _conductor(backend);
      await second.preloadAll();
      second.onScene(MusicScene.menu);

      expect(backend.loopStartCount, 1);
    });
  });
}
