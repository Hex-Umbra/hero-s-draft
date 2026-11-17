import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/effective_card.dart';
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

  group('la Puissance de statut sur la face (Q11, A15)', () {
    CardData card(List<CardEffect> effects) => CardData(
          id: 'test_card',
          cost: 1,
          type: CardType.attack,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: effects,
        );
    const damage = CardEffect(type: 'damage', value: 4);
    const freeze =
        CardEffect(type: 'apply_status', value: 2, statusId: 'freeze', duration: 1);
    const poison =
        CardEffect(type: 'apply_status', value: 1, statusId: 'poison', duration: 2);
    const burn = AddEffectDelta(
      effect: 'apply_status',
      valuePerLevel: 1,
      statusId: 'burn',
      durationPerLevel: 1,
    );

    test('le badge d un statut ajoute le bonus, celui des degats l ignore', () {
      expect(CardTextRenderer.badgeValue(freeze, statusBonus: 1), '3');
      expect(CardTextRenderer.badgeValue(damage, statusBonus: 1), '4');
    });

    test('seul le premier statut de la carte porte le bonus', () {
      final effective = EffectiveCard.apply(
          card([damage, freeze, poison]), CardRarity.common, const []);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 0), isFalse);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 1), isTrue);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 2), isFalse);
    });

    test('un statut ajoute par une rune passe avant et prend le bonus', () {
      final effective = EffectiveCard.apply(
          card([damage, freeze]), CardRarity.common, const [(burn, 1)]);
      expect(EffectResolver.statusBonusIndex(effective), 0);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 1), isFalse);
    });

    test('sans statut, personne ne porte le bonus', () {
      final effective =
          EffectiveCard.apply(card([damage]), CardRarity.common, const []);
      expect(EffectResolver.statusBonusIndex(effective), -1);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 0), isFalse);
    });
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
