import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/location_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'fake_bundle.dart';

const _forest = 'assets/data/locations/forest';

List<String> _forestKeys() => [
      '$_forest/combat.png',
      '$_forest/window_1.png',
      '$_forest/window_2.png',
      '$_forest/window_3.png',
    ];

Future<(int, int)> _sizeOf(String path) async {
  final bytes = await rootBundle.load(path);
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
  );
  final image = (await codec.getNextFrame()).image;
  final size = (image.width, image.height);
  image.dispose();
  codec.dispose();
  return size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationCatalog', () {
    test('la foret : son decor de combat et ses trois fonds dans l ordre', () {
      final catalog = LocationCatalog.fromAssetKeys([
        '$_forest/window_3.png',
        '$_forest/combat.png',
        '$_forest/window_1.png',
        '$_forest/window_2.png',
      ]);

      expect(catalog.faults, isEmpty);
      final forest = catalog.current!;
      expect(forest.id, 'forest');
      expect(forest.decorFor(DecorScreen.combat), '$_forest/combat.png');
      expect(forest.windowBackgrounds, [
        '$_forest/window_1.png',
        '$_forest/window_2.png',
        '$_forest/window_3.png',
      ]);
      expect(forest.decorFor(DecorScreen.rest), isNull);
    });

    test('aucun lieu est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys(const []);

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('aucun lieu'));
    });

    test('deux lieux sont refuses, le message nomme les deux dossiers', () {
      final catalog = LocationCatalog.fromAssetKeys([
        ..._forestKeys(),
        'assets/data/locations/dungeon/combat.png',
        'assets/data/locations/dungeon/window_1.png',
        'assets/data/locations/dungeon/window_2.png',
        'assets/data/locations/dungeon/window_3.png',
      ]);

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('forest'));
      expect(catalog.faults.single, contains('dungeon'));
    });

    test('un lieu sans combat.png est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys(
        _forestKeys().where((k) => !k.endsWith('combat.png')),
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains(_forest));
      expect(catalog.faults.single, contains('combat.png'));
    });

    test('deux fonds sont refuses', () {
      final catalog = LocationCatalog.fromAssetKeys(
        _forestKeys().where((k) => !k.endsWith('window_3.png')),
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('window_1.png'));
    });

    test('quatre fonds sont refuses', () {
      final catalog = LocationCatalog.fromAssetKeys(
        [..._forestKeys(), '$_forest/window_4.png'],
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('window_4.png'));
    });

    test('un nom de fichier inconnu est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys(
        [..._forestKeys(), '$_forest/sky.png'],
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('sky.png'));
    });

    test('un combat.jpg est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys(
        [..._forestKeys(), '$_forest/combat.jpg'],
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('combat.jpg'));
    });

    test('un combat.PNG est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys(
        [..._forestKeys(), '$_forest/combat.PNG'],
      );

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('combat.PNG'));
    });

    test('un dossier de lieu hors snake_case est refuse', () {
      final catalog = LocationCatalog.fromAssetKeys([
        'assets/data/locations/Forest/combat.png',
        'assets/data/locations/Forest/window_1.png',
        'assets/data/locations/Forest/window_2.png',
        'assets/data/locations/Forest/window_3.png',
      ]);

      expect(catalog.faults, hasLength(1));
      expect(catalog.faults.single, contains('Forest'));
    });

    test('un catalogue vide rend current nul', () {
      expect(const LocationCatalog.empty().current, isNull);
      expect(LocationCatalog.fromAssetKeys(const []).current, isNull);
    });

    test('rest.png depose habille le repos', () {
      final catalog = LocationCatalog.fromAssetKeys(
        [..._forestKeys(), '$_forest/rest.png'],
      );

      expect(catalog.faults, isEmpty);
      expect(catalog.current!.decorFor(DecorScreen.rest), '$_forest/rest.png');
    });

    test('le chargement refuse un second lieu et nomme son dossier', () async {
      final bundle = FakeBundle({
        'assets/data/xp_curve.json': '{"xpPerLevelByAct":[100]}',
        'assets/data/effect_icons.json': '{}',
        'assets/data/tier_frames.json': '{"frames":[]}',
        for (final key in _forestKeys()) key: '',
        for (final name in ['combat', 'window_1', 'window_2', 'window_3'])
          'assets/data/locations/dungeon/$name.png': '',
      });

      await expectLater(
        loadGameDataRegistry(bundle),
        throwsA(predicate((e) => e.toString().contains('dungeon'))),
      );
    });

    test(
        'le lieu courant livre est la foret, ses images aux tailles de B74 '
        'et B67', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final forest = registry.locations.current!;

      expect(forest.id, 'forest');
      expect(
        await _sizeOf(forest.decorFor(DecorScreen.combat)!),
        (640, 360),
      );
      expect(forest.windowBackgrounds, hasLength(3));
      for (final background in forest.windowBackgrounds) {
        expect(await _sizeOf(background), (128, 192), reason: background);
      }
    });
  });
}
