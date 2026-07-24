import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

void main() {
  group('MissingSaveItem', () {
    test('two items with the same fields are equal', () {
      const a = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      const b = MissingSaveItem(
        id: 'kunai',
        nameFr: 'Croc Kunaï',
        nameEn: 'Kunai Fang',
        category: 'relic',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
