import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_loader.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'fake_bundle.dart';

/// Modele de test minimal : le chargeur ne doit connaitre aucun modele du jeu.
class Thing {
  Thing(this.id, this.label);
  final String id;
  final String label;

  static Thing fromJson(Map<String, dynamic> json) =>
      Thing(json['id'] as String, json['label'] as String);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameDataLoader — selection par motif', () {
    test('un motif a un segment ne prend que les fichiers de ce repertoire', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
        'assets/data/things/b.json': '{"id":"b","label":"B"}',
        'assets/data/others/c.json': '{"id":"c","label":"C"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['a', 'b']);
    });

    test('le comptage de segments separe class.json de cards/*.json', () async {
      // `startsWith('assets/data/classes/')` capterait les deux. C est
      // precisement ce que le motif resout.
      final bundle = FakeBundle({
        'assets/data/classes/paladin/class.json': '{"id":"paladin","label":"Paladin"}',
        'assets/data/classes/paladin/cards/smite.json': '{"id":"smite","label":"Chatiment"}',
        'assets/data/classes/mage/class.json': '{"id":"mage","label":"Mage"}',
      });

      final shallow = GameDataLoader(bundle);
      final classes = await shallow.loadAll<Thing>([
        EntitySource('assets/data/classes/*/class.json', Thing.fromJson),
      ]);
      shallow.throwIfFailed();
      expect(classes.map((t) => t.id), ['mage', 'paladin']);

      final deep = GameDataLoader(bundle);
      final cards = await deep.loadAll<Thing>([
        EntitySource('assets/data/classes/*/cards/*.json', Thing.fromJson),
      ]);
      deep.throwIfFailed();
      expect(cards.map((t) => t.id), ['smite']);
    });

    test('les assets de paquets sont ignores', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
        'packages/flame/assets/data/things/x.json': '{"id":"x","label":"X"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['a']);
    });

    test('une categorie absente du manifeste rend une liste vide sans lever', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));

      final empty = await loader.loadAll<Thing>([
        EntitySource('assets/data/nothing/*.json', Thing.fromJson),
      ]);

      expect(empty, isEmpty);
      loader.throwIfFailed(); // ne doit pas lever
    });
  });

  group('GameDataLoader — ordre et fusion', () {
    test('le resultat est trie par id, quel que soit l ordre du manifeste', () async {
      // `listAssets()` n offre AUCUNE garantie d ordre
      // (`asset_manifest.dart:115, 122-124` deplace les cles entre deux
      // structures). Le tri par id est la seule regle qui donne le meme
      // resultat depuis le bundle et depuis le disque.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/zebre.json': '{"id":"zebre","label":"Z"}',
        'assets/data/things/abeille.json': '{"id":"abeille","label":"A"}',
        'assets/data/things/mouette.json': '{"id":"mouette","label":"M"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['abeille', 'mouette', 'zebre']);
    });

    test('deux sources sont fusionnees puis triees ensemble', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/mouette.json': '{"id":"mouette","label":"M"}',
        'assets/data/classes/paladin/things/abeille.json': '{"id":"abeille","label":"A"}',
        'assets/data/classes/paladin/things/zebre.json': '{"id":"zebre","label":"Z"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
        EntitySource('assets/data/classes/*/things/*.json', Thing.fromJson),
      ]);

      loader.throwIfFailed();
      expect(things.map((t) => t.id), ['abeille', 'mouette', 'zebre']);
    });

    test('un id duplique entre deux sources echoue en nommant les deux fichiers', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/smite.json': '{"id":"smite","label":"neutre"}',
        'assets/data/classes/paladin/things/smite.json': '{"id":"smite","label":"paladin"}',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
        EntitySource('assets/data/classes/*/things/*.json', Thing.fromJson),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('smite') &&
              message.contains('assets/data/things/smite.json') &&
              message.contains('assets/data/classes/paladin/things/smite.json');
        })),
      );
    });
  });

  group('GameDataLoader — agregation des erreurs', () {
    test('deux fichiers fautifs produisent UN rapport listant les deux', () async {
      // L ancien chargeur levait a la premiere entree fautive. Avec 71 fichiers,
      // corriger une faute par cycle de rebuild serait invivable.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/bon.json': '{"id":"bon","label":"B"}',
        'assets/data/things/casse1.json': '{ ceci n est pas du json',
        'assets/data/things/casse2.json': '{"id":"casse2"}',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      // Les entites fautives sont exclues ; le chargement va au bout.
      expect(things.map((t) => t.id), ['bon']);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('casse1.json') && message.contains('casse2.json');
        })),
      );
    });

    test('le rapport est tronque a 10 fichiers, suivis du reste en nombre', () async {
      // `gameDataLoaderProvider` est un FutureProvider dont l erreur atterrit
      // dans des `Text('Erreur de chargement: $err')` non scrollables
      // (`relic_exchange_screen.dart:118`) : 72 lignes y seraient illisibles.
      final loader = GameDataLoader(FakeBundle({
        for (var i = 0; i < 13; i++)
          'assets/data/things/casse$i.json': '{ pas du json',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          final lines = message.split('\n').where((l) => l.contains('casse')).length;
          return lines == 10 && message.contains('et 3 autres');
        })),
      );
    });

    test('un fichier contenant un tableau est rejete, pas un objet', () async {
      // §6.1 : « Un JSON d entite contient un objet, pas un tableau. » C est
      // la faute la plus probable pendant la migration — recopier un
      // catalogue entier au lieu d une de ses entrees.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '[{"id":"a","label":"A"}]',
      }));

      final things = await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);

      expect(things, isEmpty);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) =>
            e.toString().contains('a.json') &&
            e.toString().contains('objet JSON'))),
      );
    });

    test('sans erreur, throwIfFailed ne leve pas', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));
      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      loader.throwIfFailed();
    });
  });

  // Un document plat, comme `xp_curve.json` (spec P-43 E3, §3.2) : ni motif,
  // ni injection, ni id — et son erreur fait echouer le chargement avec
  // celles des entites.
  group('GameDataLoader — document plat', () {
    test('un document present est lu, sans erreur', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{"id":"curve","label":"Courbe"}',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      loader.throwIfFailed();
      expect(thing?.label, 'Courbe');
    });

    test('un document absent rend null, et son erreur remonte avec celles '
        'des entites, en une fois', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/casse.json': '{ pas du json',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      final missing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(missing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('2 erreur(s)') &&
              message.contains('curve.json') &&
              message.contains('casse.json');
        })),
      );
    });

    test('un document illisible rend null et son erreur est accumulee',
        () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{ ceci n est pas du json',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(thing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) => e.toString().contains('curve.json'))),
      );
    });

    test('un fromJson qui leve rend null et son erreur est accumulee',
        () async {
      // `Thing.fromJson` exige un `label` : son absence leve.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{"id":"curve"}',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(thing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) => e.toString().contains('curve.json'))),
      );
    });

    test('le demarrage du jeu refuse un registre sans xp_curve.json', () async {
      // Aucune entite : seule l erreur du document doit remonter. Si la
      // lecture de la courbe glissait apres `throwIfFailed`, le registre
      // naitrait avec `xpCurve: null` et le jeu planterait au premier gain
      // d XP.
      await expectLater(
        loadGameDataRegistry(FakeBundle(const {})),
        throwsA(predicate((e) => e.toString().contains('xp_curve.json'))),
      );
    });

    test('le demarrage du jeu refuse un registre sans effect_icons.json',
        () async {
      // Les autres documents manquent aussi (la table des cadres, les lieux) :
      // le test verifie que la faute des icones d effet est parmi celles qui
      // remontent.
      await expectLater(
        loadGameDataRegistry(FakeBundle(const {
          'assets/data/xp_curve.json': '{"xpPerLevelByAct":[100]}',
        })),
        throwsA(predicate((e) => e.toString().contains('effect_icons.json'))),
      );
    });

    test('le demarrage du jeu refuse un registre sans tier_frames.json',
        () async {
      await expectLater(
        loadGameDataRegistry(FakeBundle(const {
          'assets/data/xp_curve.json': '{"xpPerLevelByAct":[100]}',
          'assets/data/effect_icons.json': '{}',
        })),
        throwsA(predicate((e) => e.toString().contains('tier_frames.json'))),
      );
    });
  });

  group('GameDataLoader — manifeste et fautes', () {
    test('assetsMatching rend les cles et leurs segments sans lire les fichiers',
        () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/frames/tier_1.png': 'pas du json',
        'assets/data/frames/tier_2.png': 'pas du json non plus',
        'assets/data/frames/lisez_moi/a.png': 'trop profond',
      }));

      final matches = await loader.assetsMatching('assets/data/frames/*');

      expect(matches.map((m) => m.key), unorderedEquals([
        'assets/data/frames/tier_1.png',
        'assets/data/frames/tier_2.png',
      ]));
      for (final match in matches) {
        expect(match.captures, [match.key.split('/').last]);
      }
      loader.throwIfFailed();
    });

    test('fault ajoute une faute que throwIfFailed remonte', () {
      final loader = GameDataLoader(FakeBundle(const {}));

      loader.fault('assets/data/quelque_chose : une faute de verification');

      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) =>
            e.toString().contains('1 erreur(s)') &&
            e.toString().contains('une faute de verification'))),
      );
    });
  });
}
