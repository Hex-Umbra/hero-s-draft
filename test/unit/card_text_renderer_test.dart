import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

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

  test('les lignes de l infobulle disent le meme total que le badge', () {
    const fortification = CardEffect(
      type: 'armor',
      value: 6,
      scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 0.2),
    );
    const fury = CardEffect(
      type: 'apply_status',
      value: 1,
      statusId: 'might',
      duration: 2,
      scaleWith: ScaleWith(source: ScaleSource.missingHp, ratio: 0.1),
    );
    int term(CardEffect effect, EntityStats hero) => EffectResolver.scaleTerm(
          effect,
          hero: hero,
          combat: CombatState(),
        );

    final armored = EntityStats(maxPv: 80, currentPv: 80, armure: 10, might: 0);
    final wounded = EntityStats(maxPv: 80, currentPv: 50, armure: 0, might: 0);
    expect(CardTextRenderer.playedValue(fortification, term(fortification, armored)), 8);
    expect(CardTextRenderer.badgeValue(fortification, scaleTerm: term(fortification, armored)), '8');
    expect(CardTextRenderer.playedValue(fury, term(fury, wounded)), 4);

    // Hors combat, le terme est 0 : la valeur de base.
    expect(CardTextRenderer.playedValue(fortification, 0), 6);
    expect(CardTextRenderer.playedValue(fury, 0), 1);
  });
}
