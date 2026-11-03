import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les cartes et signatures livrées, vues comme (id, coût, effets).
Iterable<(String, int, List<CardEffect>)> _costed(GameDataRegistry registry) =>
    [
      for (final c in registry.cards) (c.id, c.cost, c.effects),
      for (final s in registry.signatures) (s.id, s.cost, s.effects),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async => registry = await loadGameDataRegistry(rootBundle));

  test(
      'D38 : la somme hits x mightRatio ne depasse pas le cout en mana + 1, '
      'cartes et signatures', () {
    final faulty = [
      for (final (id, cost, effects) in _costed(registry))
        if (effects
                .where((e) => e.type == 'damage')
                .fold<double>(0, (sum, e) => sum + e.hits * e.mightRatio) >
            cost + 1 + 1e-9)
          id,
    ];
    expect(faulty, isEmpty);
  });

  test('aucune carte livree ne porte hpCost ni armorCost', () {
    final faulty = [
      for (final c in registry.cards)
        if (c.hpCost != 0 || c.armorCost != 0) c.id,
    ];
    expect(faulty, isEmpty);
  });

  test('D38 : un effet a plusieurs coups declare mightRatio < 1', () {
    final faulty = [
      for (final (id, _, effects) in _costed(registry))
        if (effects.any((e) => e.hits >= 2 && e.mightRatio >= 1)) id,
    ];
    expect(faulty, isEmpty);
  });
}
