import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

List<HeroData> _heroes() => Directory('assets/data/classes')
    .listSync()
    .whereType<Directory>()
    .map((d) {
      final json =
          jsonDecode(File('${d.path}/class.json').readAsStringSync())
              as Map<String, dynamic>;
      // L id vient du repertoire parent (§6.1) ; le chargeur l injecte, mais
      // ce test lit le disque directement et doit donc faire de meme.
      json['id'] ??= d.uri.pathSegments[d.uri.pathSegments.length - 2];
      return HeroData.fromJson(json);
    })
    .toList();

void main() {
  test('chaque classe declare un displayOrder distinct et non nul', () {
    final heroes = _heroes();

    expect(heroes, isNotEmpty);
    for (final hero in heroes) {
      expect(
        hero.displayOrder,
        greaterThan(0),
        reason: 'la classe "${hero.id}" n a pas de displayOrder',
      );
    }
    final orders = heroes.map((h) => h.displayOrder).toList();
    expect(orders.toSet(), hasLength(orders.length), reason: 'doublon');
  });

  test('le tri par displayOrder rend paladin, berserker, mage', () {
    final heroes = _heroes()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(
      heroes.map((h) => h.id).toList(),
      ['paladin', 'berserker', 'mage'],
    );
  });
}
