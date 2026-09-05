import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_loader.dart';

// `ByteData` et `Uint8List` viennent de `package:flutter/services.dart`, qui
// les reexporte : pas d import `dart:typed_data`, comme dans
// `test/unit/audio/load_audio_data_test.dart`.

class FakeBundle extends CachingAssetBundle {
  FakeBundle(this.files);
  final Map<String, String> files;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final manifest = <String, Object>{
        for (final path in files.keys) path: <Object>[],
      };
      return const StandardMessageCodec().encodeMessage(manifest)!;
    }
    final content = files[key];
    if (content == null) throw Exception('asset introuvable : $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
  }
}

/// Modele de test portant exactement les champs que le repertoire injecte.
class Thing {
  Thing(this.id, this.owner, this.category);
  final String id;
  final String? owner;
  final String category;

  static Thing fromJson(Map<String, dynamic> json) => Thing(
        json['id'] as String,
        json['owner'] as String?,
        json['category'] as String? ?? 'global',
      );
}

EntitySource<Thing> _ownedSource() => EntitySource(
      'assets/data/classes/*/things/*.json',
      Thing.fromJson,
      inject: (c) => {'id': c[1], 'owner': c[0], 'category': 'owned'},
      redundantFields: const {'id', 'owner', 'category'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Autorite du repertoire', () {
    test('le repertoire injecte l appartenance, meme si le fichier se tait', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"label":"Chatiment"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      loader.throwIfFailed();
      expect(things.single.id, 'smite');
      expect(things.single.owner, 'paladin');
      expect(things.single.category, 'owned');
    });

    test('le fichier a le droit de confirmer un champ injecte a l identique', () async {
      // Tolerance a expiration : elle sert pendant la migration, ou elle
      // laisse passer tels quels les `category` et `heroClass` des fichiers
      // issus du decoupage. La tache 9 la retire.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json':
            '{"id":"smite","owner":"paladin","category":"owned"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      loader.throwIfFailed();
      expect(things.single.owner, 'paladin');
    });

    test('un champ injecte contredit fait echouer, en nommant tout', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"mage"}',
      }));

      await loader.loadAll<Thing>([_ownedSource()]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('assets/data/classes/paladin/things/smite.json') &&
              message.contains('owner') &&
              message.contains('paladin') &&
              message.contains('mage');
        })),
      );
    });

    test('l entite contredite est exclue, les autres passent', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"mage"}',
        'assets/data/classes/paladin/things/shield.json': '{"label":"Bouclier"}',
      }));

      final things = await loader.loadAll<Thing>([_ownedSource()]);

      expect(things.map((t) => t.id), ['shield']);
      expect(() => loader.throwIfFailed(), throwsException);
    });

    test('un champ hors redundantFields est interdit, meme s il est juste', () {
      // Expiration de la tolerance : pendant la migration, redeclarer
      // `owner: paladin` sous `classes/paladin/` etait tolere. Ce n est plus
      // une confirmation utile, c est une seconde verite en attente de
      // diverger.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/things/smite.json': '{"owner":"paladin"}',
      }));

      return loader.loadAll<Thing>([
        EntitySource(
          'assets/data/classes/*/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[1], 'owner': c[0], 'category': 'owned'},
          // `id` seul reste redeclarable.
        ),
      ]).then((_) {
        expect(
          () => loader.throwIfFailed(),
          throwsA(predicate((e) {
            final message = e.toString();
            return message.contains('smite.json') &&
                message.contains('impose par le repertoire') &&
                message.contains('owner');
          })),
        );
      });
    });
  });

  group('Origine de l id', () {
    test('pour un fichier nomme, l id vient du nom de fichier', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/iron_talisman.json': '{"label":"Talisman"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      loader.throwIfFailed();
      expect(things.single.id, 'iron_talisman');
    });

    test('pour class.json et enemy.json, l id vient du repertoire parent', () async {
      // Derogation assumee de §6.1 : ces deux fichiers portent un nom fixe,
      // donc leur identite est celle de leur dossier.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/classes/paladin/class.json': '{"label":"Paladin"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/classes/*/class.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      loader.throwIfFailed();
      expect(things.single.id, 'paladin');
    });

    test('un id de fichier contredit par le JSON fait echouer', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/iron_talisman.json': '{"id":"iron_talismn"}',
      }));

      await loader.loadAll<Thing>([
        EntitySource(
          'assets/data/things/*.json',
          Thing.fromJson,
          inject: (c) => {'id': c[0]},
        ),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('iron_talisman.json') &&
              message.contains('iron_talismn');
        })),
      );
    });
  });
}
