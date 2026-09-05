import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le SEUL test qui prouve que l application voit reellement les fichiers.
///
/// Un repertoire present mais NON declare au pubspec ne produit aucun
/// message : son contenu se charge en developpement et disparait en build
/// (`flutter_tools/lib/src/asset.dart` — la declaration n est pas recursive,
/// et rien ne signale l omission). Comparer `tool/sync_assets.dart` au
/// pubspec ne prouve rien : les deux parcourent le disque.
///
/// `flutter test` construit le bundle d assets par defaut
/// (`flutter_tools/lib/src/commands/test.dart:412, 486-489`), ce que
/// `test/unit/audio/audio_ui_and_reel_moments_test.dart:22` exerce deja en
/// lisant `assets/data/audio.json` par `rootBundle`. Hypothese gardee : la CI
/// lance `flutter test` nu — `--no-test-assets` ferait echouer ce fichier.
///
/// (Ne pas citer `load_audio_data_test.dart` comme precedent : celui-la
/// SIMULE le canal `flutter/assets` et n atteint jamais le vrai bundle.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le manifeste declare les 71 fichiers d entite, par categorie', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final json = manifest
        .listAssets()
        .where((a) => a.startsWith('assets/data/') && a.endsWith('.json'))
        .toList();

    int countUnder(String prefix, int depth) => json
        .where((a) => a.startsWith(prefix) && a.split('/').length == depth)
        .length;

    expect(countUnder('assets/data/cards/', 4), 17, reason: 'cartes neutres');
    expect(countUnder('assets/data/relics/', 4), 25, reason: 'reliques');
    expect(countUnder('assets/data/events/', 4), 5, reason: 'evenements');
    expect(countUnder('assets/data/forge_upgrades/', 4), 8, reason: 'forge');
    expect(countUnder('assets/data/passives/', 4), 3, reason: 'passifs');

    expect(json.where((a) => a.endsWith('/class.json')).length, 3);
    expect(json.where((a) => a.endsWith('/enemy.json')).length, 4);
    expect(countUnder('assets/data/classes/', 6), 6, reason: 'cartes de classe');

    // Les deux documents de configuration restent a plat.
    expect(json, contains('assets/data/audio.json'));
    expect(json, contains('assets/data/patch_notes.json'));
  });

  test('les images d entites sont declarees, pas seulement presentes', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().toSet();

    for (final id in ['paladin', 'berserker', 'mage']) {
      expect(assets, contains('assets/data/classes/$id/icon.png'));
    }
    for (final id in ['slime', 'gobelin', 'squelette', 'orc']) {
      expect(assets, contains('assets/data/enemies/$id/sprite.png'));
    }
    expect(assets, contains('assets/images/bg_dungeon.png'));
  });

  test('le registre se charge entierement depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.cards, hasLength(23)); // 17 neutres + 6 de classe
    expect(registry.relics, hasLength(25));
    expect(registry.events, hasLength(5));
    expect(registry.forgeUpgrades, hasLength(8));
    expect(registry.passives, hasLength(3));
    expect(registry.heroes, hasLength(3));
    expect(registry.enemies, hasLength(4));

    // Le tri par id est la seule regle qui donne le meme resultat depuis le
    // bundle et depuis le disque : `listAssets()` n offre aucune garantie
    // d ordre.
    final ids = registry.relics.map((r) => r.id).toList();
    expect(ids, orderedEquals(List<String>.of(ids)..sort()));
  });
}
