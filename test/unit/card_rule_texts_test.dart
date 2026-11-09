import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/card_rule_texts.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

/// La seule écriture des lignes de coût, de coups et de croissance, lue par
/// les deux infobulles (spec P-44 lot 1, §6.1).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  ScaleWith scale(ScaleSource source, double ratio) => ScaleWith(
        source: source,
        ratio: ratio,
        statusId: source == ScaleSource.targetStatus ? 'vulnerable' : null,
      );

  /// Les clés d'une source : la forme en tranches, puis la forme nue.
  (String, String) expected(AppLocalizations l10n, ScaleSource source) {
    return switch (source) {
      ScaleSource.armor => (l10n.cardScaleArmorPer(5), l10n.cardScaleArmor('1')),
      ScaleSource.missingHp =>
        (l10n.cardScaleMissingHpPer(5), l10n.cardScaleMissingHp('1')),
      ScaleSource.cardsPlayedThisTurn =>
        (l10n.cardScaleCardsPlayedPer(5), l10n.cardScaleCardsPlayed('1')),
      ScaleSource.enemiesAlive =>
        (l10n.cardScaleEnemiesAlivePer(5), l10n.cardScaleEnemiesAlive('1')),
      ScaleSource.targetStatus => (
          l10n.cardScaleTargetStatusPer(5, 'Vulnérable'),
          l10n.cardScaleTargetStatus('1', 'Vulnérable')
        ),
      ScaleSource.targetMissingHp =>
        (l10n.cardScaleTargetMissingHpPer(5), l10n.cardScaleTargetMissingHp('1')),
    };
  }

  test(
      'un ratio sous 1 s ecrit en tranches, un ratio d au moins 1 tel quel, '
      'pour les six sources', () {
    for (final l10n in [fr, en]) {
      for (final source in ScaleSource.values) {
        final (per, bare) = expected(l10n, source);
        expect(CardRuleTexts.scale(l10n, scale(source, 0.2)), per);
        expect(CardRuleTexts.scale(l10n, scale(source, 1)), bare);
      }
    }
    expect(CardRuleTexts.scale(fr, scale(ScaleSource.armor, 1.5)),
        fr.cardScaleArmor('1,5'));
    expect(CardRuleTexts.scale(en, scale(ScaleSource.armor, 1.5)),
        en.cardScaleArmor('1.5'));
  });

  test('les degats : une ligne a coups au-dela d un coup', () {
    expect(
      CardRuleTexts.damage(fr, amount: 3, hits: 3, allEnemies: false),
      fr.cardDescDamageHits(3, 3),
    );
    expect(
      CardRuleTexts.damage(fr, amount: 3, hits: 3, allEnemies: true),
      fr.cardDescDamageHits(3, 3),
    );
    expect(
      CardRuleTexts.damage(fr, amount: 3, hits: 1, allEnemies: false),
      fr.cardDescDamage(3),
    );
    expect(
      CardRuleTexts.damage(fr, amount: 3, hits: 1, allEnemies: true),
      fr.cardDescDamageAll(3),
    );
  });

  test('les couts : PV puis Armure, rien pour le mana seul', () {
    CardData card({int cost = 0, int hp = 0, int armor = 0}) => CardData(
          id: 'test',
          cost: cost,
          hpCost: hp,
          armorCost: armor,
          type: CardType.attack,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: const [],
        );

    expect(CardRuleTexts.extraCosts(fr, card(cost: 1, hp: 3, armor: 2)),
        [fr.cardCostHp(3), fr.cardCostArmor(2)]);
    expect(CardRuleTexts.extraCosts(fr, card(cost: 2)), isEmpty);
  });

  test('targetStatus nomme le statut', () {
    final text =
        CardRuleTexts.scale(fr, scale(ScaleSource.targetStatus, 1));
    expect(text, contains('Vulnérable'));
  });
}
