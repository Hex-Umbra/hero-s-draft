import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  test('chaque classe declare un displayOrder distinct et non nul', () {
    final raw = File('assets/data/heroes.json').readAsStringSync();
    final heroes = (jsonDecode(raw) as List)
        .map((e) => HeroData.fromJson(e as Map<String, dynamic>))
        .toList();

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
    final raw = File('assets/data/heroes.json').readAsStringSync();
    final heroes = (jsonDecode(raw) as List)
        .map((e) => HeroData.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(
      heroes.map((h) => h.id).toList(),
      ['paladin', 'berserker', 'mage'],
    );
  });
}
