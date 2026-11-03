import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

/// La face Flame faute de banc (spec §9) : ses calculs, statiques.
void main() {
  test(
      'le badge d un multi-coups dit valeur×coups, la Puissance par coup '
      'arrondie vers le bas', () {
    const effect =
        CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5);
    expect(CardTextRenderer.badgeValue(effect, damageBonus: 3), '4×3');
    expect(CardTextRenderer.badgeValue(effect, damageBonus: 1), '3×3');
  });

  test('le badge d un effet a scaleWith ajoute le terme', () {
    const damage = CardEffect(
      type: 'damage',
      value: 2,
      scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 1),
    );
    expect(CardTextRenderer.badgeValue(damage, scaleTerm: 7), '9');

    const armor = CardEffect(
      type: 'armor',
      value: 6,
      scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 0.2),
    );
    expect(
        CardTextRenderer.badgeValue(armor, scaleTerm: 2, damageBonus: 5), '8');
  });
}
