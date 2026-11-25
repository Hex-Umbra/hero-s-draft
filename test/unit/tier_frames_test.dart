import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/models/data/tier_frame_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'fake_bundle.dart';
import 'tier_frame_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('la table des cadres', () {
    test(
        'un ennemi d un tier sans cadre fait echouer le chargement, le message '
        'nomme l ennemi et le tier', () async {
      final bundle = FakeBundle({
        'assets/data/xp_curve.json': '{"xpPerLevelByAct":[100]}',
        'assets/data/effect_icons.json': '{}',
        'assets/data/tier_frames.json':
            '{"frames":[{"tier":1,"size":[88,120],"window":[12,12]}]}',
        'assets/data/frames/tier_1.png': '',
        'assets/data/locations/forest/combat.png': '',
        'assets/data/locations/forest/window_1.png': '',
        'assets/data/locations/forest/window_2.png': '',
        'assets/data/locations/forest/window_3.png': '',
        'assets/data/enemies/rat/enemy.json':
            '{"maxHp":10,"baseDamage":1,"spritePath":"rat.png","tier":2}',
      });

      await expectLater(
        loadGameDataRegistry(bundle),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('rat') && message.contains('tier 2');
        })),
      );
    });

    test('une entree sans image au manifeste est une faute', () {
      final faults = tierFrameFaults(
        enemies: const [],
        frames: TierFrameTable([testFrameOf(1)]),
        assetKeys: const {},
      );

      expect(faults, hasLength(1));
      expect(faults.single, contains('tier_1.png'));
    });

    test('une fenetre hors du canevas est une faute', () {
      final faults = tierFrameFaults(
        enemies: const [],
        frames: const TierFrameTable([
          TierFrame(tier: 1, width: 88, height: 120, windowX: 30, windowY: 12),
        ]),
        assetKeys: {testFrameOf(1).imagePath},
      );

      expect(faults, hasLength(1));
      expect(faults.single, contains('sort du canevas'));
    });

    test('une fenetre decentree est une faute', () {
      final faults = tierFrameFaults(
        enemies: const [],
        frames: const TierFrameTable([
          TierFrame(tier: 2, width: 96, height: 128, windowX: 12, windowY: 16),
        ]),
        assetKeys: {testFrameOf(2).imagePath},
      );

      expect(faults, hasLength(1));
      expect(faults.single, contains('pas centree'));
    });

    test('un canevas plus petit que le gabarit est une faute', () {
      final faults = tierFrameFaults(
        enemies: const [],
        frames: const TierFrameTable([
          TierFrame(tier: 1, width: 80, height: 110, windowX: 8, windowY: 7),
        ]),
        assetKeys: {testFrameOf(1).imagePath},
      );

      expect(faults, hasLength(1));
      expect(faults.single, contains('gabarit'));
    });

    test('un tier en double est refuse', () {
      expect(
        () => TierFrameTable.fromJson({
          'frames': [
            {'tier': 1, 'size': [88, 120], 'window': [12, 12]},
            {'tier': 1, 'size': [96, 128], 'window': [16, 16]},
          ],
        }),
        throwsFormatException,
      );
    });

    test('une taille impaire est refusee', () {
      expect(
        () => TierFrame.fromJson({
          'tier': 1,
          'size': [89, 120],
          'window': [12, 12],
        }),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('tier 1'))),
      );
    });

    test('la table livree porte les cinq cadres de B73', () async {
      final registry = await loadGameDataRegistry(rootBundle);

      expect(registry.tierFrames.frames, testTierFrames);
      // `boardScaleFor` prendra le bas du plus grand cadre
      // (`frameBelowWindowCenter`, Task 2) : sa demi-hauteur est 76.
      final halfHeights = registry.tierFrames.frames.map((f) => f.height / 2);
      expect(halfHeights.reduce((a, b) => a > b ? a : b), 76);
    });

    test('chaque cadre livre a sa taille et une fenetre transparente', () async {
      for (final frame in testTierFrames) {
        final bytes = await rootBundle.load(frame.imagePath);
        final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        final image = (await codec.getNextFrame()).image;
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;

        expect(
          (image.width, image.height),
          (frame.width, frame.height),
          reason: frame.imagePath,
        );
        for (var y = frame.windowY;
            y < frame.windowY + GameConstants.enemyWindowHeight;
            y++) {
          for (var x = frame.windowX;
              x < frame.windowX + GameConstants.enemyWindowWidth;
              x++) {
            final alpha = rgba.getUint8((y * image.width + x) * 4 + 3);
            if (alpha != 0) {
              fail('${frame.imagePath} : le pixel ($x, $y) de la fenetre '
                  'a un alpha de $alpha');
            }
          }
        }
        image.dispose();
        codec.dispose();
      }
    });
  });
}
