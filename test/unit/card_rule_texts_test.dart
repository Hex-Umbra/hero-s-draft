import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/card_rule_texts.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';

/// La seule écriture des lignes de coût, de coups et de croissance, lue par
/// les deux infobulles (spec P-44 lot 1, §6.1).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));
  final charges = shippedChargeCatalog();

  ScaleWith scale(ScaleSource source, double ratio) => ScaleWith(
        source: source,
        ratio: ratio,
        statusId: source == ScaleSource.targetStatus ? 'vulnerable' : null,
      );

  /// Les clés d'une source : la forme en tranches, puis la forme nue.
  (String, String) expected(AppLocalizations l10n, ScaleSource source) {
    final vulnerable = l10n.localeName == 'fr' ? 'Vulnérable' : 'Vulnerable';
    return switch (source) {
      ScaleSource.armor => (l10n.cardScaleArmorPer(5), l10n.cardScaleArmor('1')),
      ScaleSource.missingHp =>
        (l10n.cardScaleMissingHpPer(5), l10n.cardScaleMissingHp('1')),
      ScaleSource.cardsPlayedThisTurn =>
        (l10n.cardScaleCardsPlayedPer(5), l10n.cardScaleCardsPlayed('1')),
      ScaleSource.enemiesAlive =>
        (l10n.cardScaleEnemiesAlivePer(5), l10n.cardScaleEnemiesAlive('1')),
      ScaleSource.targetStatus => (
          l10n.cardScaleTargetStatusPer(5, vulnerable),
          l10n.cardScaleTargetStatus('1', vulnerable)
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
        expect(CardRuleTexts.scale(l10n, scale(source, 0.2), charges), per);
        expect(CardRuleTexts.scale(l10n, scale(source, 1), charges), bare);
      }
    }
    expect(CardRuleTexts.scale(fr, scale(ScaleSource.armor, 1.5), charges),
        fr.cardScaleArmor('1,5'));
    expect(CardRuleTexts.scale(en, scale(ScaleSource.armor, 1.5), charges),
        en.cardScaleArmor('1.5'));
  });

  test('les lignes d Execution et d Exploitation en toutes lettres', () {
    final missingHp = ScaleWith(source: ScaleSource.targetMissingHp, ratio: 0.2);
    final vulnerable = ScaleWith(
      source: ScaleSource.targetStatus,
      ratio: 1,
      statusId: 'vulnerable',
    );
    expect(CardRuleTexts.scale(fr, missingHp, charges),
        '+1 par tranche de 5 PV manquants de la cible');
    expect(CardRuleTexts.scale(en, missingHp, charges),
        '+1 per 5 missing HP on the target');
    expect(CardRuleTexts.scale(fr, vulnerable, charges),
        '+1 par point de Vulnérable de la cible');
    expect(CardRuleTexts.scale(en, vulnerable, charges),
        '+1 per point of Vulnerable on the target');
  });

  test('statusName donne a chaque statut le nom francais de createStatus', () {
    for (final id in [
      'poison',
      'might',
      'weakness',
      'vulnerable',
      'might_regen',
      'mana_regen',
      'armor_regen',
      'hp_regen',
    ]) {
      expect(fr.statusName(id), EffectResolver.createStatus(id, 1, 1)!.name);
    }
    expect(fr.statusName('inconnu'), 'inconnu');
  });

  test('statusName nomme le vol de vie et les six statuts de reliques', () {
    expect(fr.statusName('lifesteal'), 'Vol de Vie');
    expect(en.statusName('lifesteal'), 'Lifesteal');

    const relicNames = {
      'crit_chance': 'Critique (Relique)',
      'mastery': 'Maîtrise (Relique)',
      'kunai_charge': 'Charge Kunaï',
      'shuriken_charge': 'Charge Shuriken',
      'pen_nib_charge': 'Charge Plume',
      'incense_charge': 'Charge Encensoir',
    };
    for (final MapEntry(key: id, value: name) in relicNames.entries) {
      expect(fr.statusName(id), name);
      expect(en.statusName(id), isNot(id));
    }
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
        CardRuleTexts.scale(fr, scale(ScaleSource.targetStatus, 1), charges);
    expect(text, contains('Vulnérable'));
  });

  test('targetStatus sur une charge dit son nom, jamais l id', () {
    final text = CardRuleTexts.scale(
      fr,
      const ScaleWith(
        source: ScaleSource.targetStatus,
        ratio: 1,
        statusId: 'freeze',
      ),
      charges,
    );
    expect(text, contains('Gel'));
    expect(text, isNot(contains('freeze')));
  });
}
