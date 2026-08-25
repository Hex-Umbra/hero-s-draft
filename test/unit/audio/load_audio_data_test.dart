import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// `loadAudioData()` parle a `rootBundle`, donc au canal `flutter/assets`.
/// Le simuler via `setMockMessageHandler` permet de forcer un fichier
/// absent ou un contenu invalide sans toucher au vrai `assets/data/audio.json`
/// ni ajouter de fixture au bundle de l'app.
ByteData _asset(String content) => ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('loadAudioData — mode degrade (Fix 4)', () {
    late DebugPrintCallback originalDebugPrint;
    late List<String> debugMessages;

    setUp(() {
      originalDebugPrint = debugPrint;
      debugMessages = [];
      debugPrint = (message, {wrapWidth}) {
        if (message != null) debugMessages.add(message);
      };
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null);
    });

    test('fichier absent : catalogue desactive et trace en debug, sans lever', () async {
      // Chemin propre a ce test : `rootBundle.loadString` met le resultat
      // en cache par cle, y compris un echec. Reutiliser le meme chemin
      // dans plusieurs tests ferait retomber les suivants sur l echec (ou
      // le succes) mis en cache par le premier, au lieu d exercer leur
      // propre handler.
      const path = 'assets/data/audio_test_absent.json';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async => null);

      final result = await loadAudioData(path);

      expect(result.enabled, isFalse);
      expect(result.sounds, isEmpty);
      expect(result.moments, isEmpty);
      expect(result.music, isEmpty);
      // Prouve que c'est bien la branche `catch` (fichier introuvable) qui a
      // parle, pas seulement que le resultat final est desactive : un
      // catalogue "JSON valide mais pas un objet" (test plus bas) retombe
      // sur `enabled: false` par une tout autre branche.
      expect(debugMessages, hasLength(1));
      expect(debugMessages.single, contains('echec de chargement de "$path"'));
    });

    test('JSON malforme (syntaxe invalide) : catalogue desactive et trace en debug, sans lever', () async {
      const path = 'assets/data/audio_test_malformed.json';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async => _asset('{ ceci n est pas du json'));

      final result = await loadAudioData(path);

      expect(result.enabled, isFalse);
      expect(result.sounds, isEmpty);
      expect(result.moments, isEmpty);
      expect(result.music, isEmpty);
      expect(debugMessages, hasLength(1));
      expect(debugMessages.single, contains('echec de chargement de "$path"'));
    });

    test('JSON valide mais pas un objet : catalogue desactive et trace en debug, sans lever', () async {
      const path = 'assets/data/audio_test_wrong_shape.json';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async => _asset('[1, 2, 3]'));

      final result = await loadAudioData(path);

      expect(result.enabled, isFalse);
      expect(result.sounds, isEmpty);
      expect(result.moments, isEmpty);
      expect(result.music, isEmpty);
      // Cette branche (`decoded is! Map`) rend le meme `enabled: false` que
      // le `catch` du test precedent : sans ce message distinct, rien ne
      // prouverait que c'est bien CETTE branche qui s'est executee plutot
      // que retomber sur le `catch` par une autre voie.
      expect(debugMessages, hasLength(1));
      expect(debugMessages.single, contains('ne decode pas vers un objet JSON'));
    });

    test('fichier present et valide : catalogue active, rien en debug (temoin de non-regression)', () async {
      const path = 'assets/data/audio_test_valid.json';
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (message) async => _asset('{"schemaVersion": 1, "sounds": {}, "moments": {}, "music": {}}'),
      );

      final result = await loadAudioData(path);

      expect(result.enabled, isTrue);
      expect(debugMessages, isEmpty);
    });
  });
}
