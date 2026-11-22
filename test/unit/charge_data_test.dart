import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Un fichier de charge livré, tel que le disque le porte (id compris).
Map<String, dynamic> _file(String id) =>
    jsonDecode(File('assets/data/charges/$id.json').readAsStringSync())
        as Map<String, dynamic>;

/// Le fichier [id] livré, modifié par [edit].
Map<String, dynamic> _with(
  String id,
  void Function(Map<String, dynamic> json) edit,
) {
  final json = _file(id);
  edit(json);
  return json;
}

/// [json] doit être refusé, et le message doit nommer [key].
void _refused(Map<String, dynamic> json, String key) {
  expect(
    () => ChargeData.fromJson(json),
    throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    ),
    reason: 'attendu : un refus qui nomme "$key"',
  );
}

void main() {
  test('une cle inconnue est refusee, nommee', () {
    _refused(_with('freeze', (j) => j['foo'] = 1), 'foo');
  });

  test('un nom ou une description sans sa paire _fr / _en est refuse', () {
    _refused(_with('freeze', (j) => j.remove('name_en')), 'name_en');
    _refused(_with('freeze', (j) => j.remove('description_fr')), 'description_fr');
    _refused(_with('burn', (j) => j.remove('summary_en')), 'summary_en');
  });

  test('un seuil inferieur a 1 est refuse', () {
    for (final key in ['threshold', 'bossThreshold', 'heroThreshold']) {
      _refused(_with('freeze', (j) => j[key] = 0), key);
    }
  });

  test('une montee ou un declin negatifs sont refuses', () {
    _refused(_with('freeze', (j) => j['thresholdGrowth'] = -1), 'thresholdGrowth');
    _refused(_with('freeze', (j) => j['decay'] = -1), 'decay');
  });

  test('une sorte de rupture inconnue est refusee', () {
    _refused(
      _with('freeze', (j) => (j['rupture'] as Map)['kind'] = 'stun'),
      'stun',
    );
  });

  test('un parametre d une autre sorte est refuse', () {
    _refused(
      _with('burn', (j) => (j['rupture'] as Map)['bonusPerPoint'] = 2),
      'bonusPerPoint',
    );
    _refused(
      _with('burn', (j) => (j['rupture'] as Map).remove('explosionDamage')),
      'explosionDamage',
    );
  });

  test('un parametre hors de ses bornes est refuse', () {
    for (final percent in [0, 101]) {
      _refused(
        _with('freeze', (j) => (j['heroRupture'] as Map)['percent'] = percent),
        'percent',
      );
    }
    _refused(
      _with('shock', (j) => (j['rupture'] as Map)['bonusPerPoint'] = 0),
      'bonusPerPoint',
    );
    _refused(
      _with('burn', (j) => (j['rupture'] as Map)['damagePerPoint'] = -1),
      'damagePerPoint',
    );
  });

  test('belowThresholdPercent hors de [0, 100] est refuse', () {
    for (final percent in [-1, 101]) {
      _refused(
        _with('shock', (j) => j['belowThresholdPercent'] = percent),
        'belowThresholdPercent',
      );
    }
  });

  test('belowThresholdPercent est exige pour explode et amplifyHits, refuse '
      'pour les autres', () {
    _refused(
      _with('burn', (j) => j.remove('belowThresholdPercent')),
      'belowThresholdPercent',
    );
    _refused(
      _with('shock', (j) => j.remove('belowThresholdPercent')),
      'belowThresholdPercent',
    );
    _refused(
      _with('freeze', (j) => j['belowThresholdPercent'] = 50),
      'belowThresholdPercent',
    );
  });

  test('une sorte et un moment incompatibles sont refuses', () {
    _refused(_with('burn', (j) => j['breaksOn'] = 'threshold'), 'breaksOn');
    _refused(_with('freeze', (j) => j['breaksOn'] = 'bearerTurn'), 'breaksOn');
  });

  test('brokenName est exige pour une rupture qui dure, refuse pour explode',
      () {
    _refused(_with('freeze', (j) => j.remove('brokenName_fr')), 'brokenName');
    _refused(_with('shock', (j) {
      j.remove('brokenName_fr');
      j.remove('brokenName_en');
    }), 'brokenName');
    _refused(_with('burn', (j) {
      j['brokenName_fr'] = 'Brûlé';
      j['brokenName_en'] = 'Burned';
    }), 'brokenName');
  });

  test('heroDescription est exigee si et seulement si heroRupture', () {
    _refused(_with('freeze', (j) {
      j.remove('heroDescription_fr');
      j.remove('heroDescription_en');
    }), 'heroDescription');
    _refused(_with('burn', (j) {
      j['heroDescription_fr'] = 'Sur vous';
      j['heroDescription_en'] = 'On you';
    }), 'heroDescription');
    _refused(_with('freeze', (j) => j.remove('heroDescription_en')),
        'heroDescription');
  });

  test('un seuil de Feu de 2 est refuse, de 3 accepte', () {
    _refused(_with('burn', (j) => j['threshold'] = 2), 'threshold');
    expect(ChargeData.fromJson(_file('burn')).threshold, 3);
  });

  test('les seuils du boss et du heros d un Feu suivent la meme regle', () {
    _refused(_with('burn', (j) => j['bossThreshold'] = 2), 'bossThreshold');
    _refused(_with('burn', (j) => j['heroThreshold'] = 2), 'heroThreshold');
  });

  test('skipAction est refuse comme rupture du heros', () {
    _refused(_with('freeze', (j) {
      j.remove('heroRupture');
      j.remove('heroDescription_fr');
      j.remove('heroDescription_en');
    }), 'heroRupture');
    // Une heroRupture qui vaut skipAction : l'erreur nomme cette clé-là.
    _refused(
      _with('freeze', (j) => j['heroRupture'] = {'kind': 'skipAction'}),
      '"heroRupture" skipAction',
    );
    final accepted = ChargeData.fromJson(_file('freeze'));
    expect(accepted.ruptureFor(ChargeBearer.hero).kind, RuptureKind.weakenDealt);
  });

  test('un jeton inconnu est refuse', () {
    _refused(
      _with('freeze', (j) => j['description_fr'] = 'Inflige {damage}.'),
      'damage',
    );
    // Un jeton d une autre sorte que la rupture du texte l est aussi.
    _refused(
      _with('freeze', (j) => j['description_fr'] = 'Inflige {percent}.'),
      'percent',
    );
    // La phrase courte passe par la même liste.
    _refused(
      _with('shock', (j) => j['summary_fr'] = 'Inflige {damage}.'),
      'damage',
    );
  });

  test('le seuil de depart par porteur', () {
    final freeze = ChargeData.fromJson(_file('freeze'));
    expect(freeze.startThreshold(ChargeBearer.enemy), 3);
    expect(freeze.startThreshold(ChargeBearer.boss), 6);
    expect(freeze.startThreshold(ChargeBearer.hero), 5);
    expect(freeze.ruptureFor(ChargeBearer.hero).kind, RuptureKind.weakenDealt);
    expect(freeze.ruptureFor(ChargeBearer.enemy).kind, RuptureKind.skipAction);

    final shock = ChargeData.fromJson(_file('shock'));
    for (final bearer in ChargeBearer.values) {
      expect(shock.startThreshold(bearer), 3);
    }
  });

  test('les jetons se remplissent, belowValue compris, la demie vers le haut',
      () {
    final burn = ChargeData.fromJson(_file('burn'));
    final fr = burn.describe('fr');
    expect(fr, contains('chaque tranche de 3 inflige 4 par point'));
    expect(fr, contains('12 dégâts et 1 Feu'));
    expect(fr, contains('le reste inflige 2 par point'));
    expect(burn.belowValue, 2);

    final shock = ChargeData.fromJson(_file('shock'));
    expect(shock.describe('en'), startsWith('Each hit taken deals +1 per point'));

    final odd = ChargeData.fromJson(
      _with('shock', (j) => (j['rupture'] as Map)['bonusPerPoint'] = 3),
    );
    expect(odd.belowValue, 2);
    expect(odd.describe('en'), startsWith('Each hit taken deals +2 per point'));

    expect(ChargeData.fromJson(_file('freeze')).belowValue, isNull);
    expect(halfUp(3, 50), 2);
    expect(halfUp(5, 50), 3);
    expect(halfUp(4, 50), 2);
  });

  test('toJson puis fromJson rend la meme charge', () {
    for (final id in ['freeze', 'burn', 'shock']) {
      final charge = ChargeData.fromJson(_file(id));
      expect(ChargeData.fromJson(charge.toJson()).toJson(), charge.toJson());
      expect(charge.toJson(), _file(id), reason: id);
    }
  });

  test('ChargeCatalog : acces par id, ids, vide par defaut', () {
    final catalog = ChargeCatalog.of([
      for (final id in ['freeze', 'burn', 'shock']) ChargeData.fromJson(_file(id)),
    ]);
    expect(catalog['burn']!.id, 'burn');
    expect(catalog['unknown'], isNull);
    expect(catalog.isCharge('shock'), isTrue);
    expect(catalog.isCharge('poison'), isFalse);
    expect(catalog.ids, {'burn', 'freeze', 'shock'});
    expect(catalog.all, hasLength(3));
    expect(catalog.isEmpty, isFalse);
    expect(const ChargeCatalog.empty().isEmpty, isTrue);
  });

  test('chargeCatalogProvider rend le catalogue vide sans registre charge', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(chargeCatalogProvider).isEmpty, isTrue);
  });
}
