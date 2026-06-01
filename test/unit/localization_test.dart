import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
  group('Localization and Bilingual Data Parsing Tests', () {
    test(
      'CardData parses and returns correct dynamic translations for name and description',
      () {
        final jsonFragment = {
          'id': 'strike_test',
          'name_en': 'Strike Test',
          'name_fr': 'Frappe Test',
          'description_en': 'Deals 6 damage.',
          'description_fr': 'Inflige 6 dégâts.',
          'cost': 1,
          'type': 'attack',
          'category': 'global',
          'rarity': 'common',
          'target': 'singleEnemy',
          'isExhaust': false,
          'effects': [
            {'type': 'damage', 'value': 6},
          ],
        };

        final cardData = CardData.fromJson(jsonFragment);

        // Verify English translation
        expect(cardData.getName('en'), 'Strike Test');
        expect(cardData.getDescription('en'), 'Deals 6 damage.');

        // Verify French translation
        expect(cardData.getName('fr'), 'Frappe Test');
        expect(cardData.getDescription('fr'), 'Inflige 6 dégâts.');

        // Verify fallback behavior on unknown/default locale (falls back to English nameEn/descriptionEn)
        expect(cardData.getName('es'), 'Strike Test');
        expect(cardData.getDescription('de'), 'Deals 6 damage.');
      },
    );
  });
}
