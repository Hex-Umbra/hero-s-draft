import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/damage_pipeline.dart';
import 'package:roguelike_card_game/game/services/proportional_status.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

import 'shipped_data.dart';

/// Le critique que la carte jouée ajoute à celui de l'attaquant (spec P-43
/// E2, §4.2, A10) : `precise`.
void main() {
  // Ni critique, ni statut : seul le bonus de la carte peut critiquer.
  final charges = shippedChargeCatalog();

  EntityStats stats() =>
      EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);

  test('critChanceBonus s ajoute au jet : a 100 points, le coup est critique',
      () {
    for (var i = 0; i < 20; i++) {
      final (damage, isCrit) = DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: stats(),
        defenderStats: stats(),
        charges: charges,
        critChanceBonus: 100,
      );
      expect((damage, isCrit), (15, true));
    }
  });

  test('0 par defaut : le jet d aujourd hui, sans critique a 0 %', () {
    for (var i = 0; i < 20; i++) {
      expect(
        DamagePipeline.calculate(
          initialDamage: 10,
          attackerStats: stats(),
          defenderStats: stats(),
          charges: charges,
        ),
        (10, false),
      );
    }
  });

  // Les statuts proportionnels (spec P-42/P-44 lot 1, §4.4, reponse P-1).
  EntityStats withStatus(String id, int points, {String? sourceId}) =>
      stats().addStatus(StatusEffect(
        id: id,
        name: id,
        type: StatusType.debuff,
        value: points,
        duration: 2,
        sourceId: sourceId,
      ));

  int damageWith({EntityStats? attacker, EntityStats? defender}) =>
      DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: attacker ?? stats(),
        defenderStats: defender ?? stats(),
        charges: charges,
        canCrit: false,
      ).$1;

  test('le bareme de P-1 : 25 % par point ; Vulnerable 4, Faiblesse 2, Gel 3 '
      'points au plus', () {
    expect(
      [
        ProportionalStatus.vulnerable,
        ProportionalStatus.weakness,
        ProportionalStatus.freeze,
      ].map((s) => (s.percentPerPoint, s.maxPoints, s.maxPercent)),
      [(25, 4, 100), (25, 2, 50), (25, 3, 75)],
    );
  });

  test('Vulnerable : +25 % par point, plafonne a +100 %', () {
    expect(
      [1, 2, 4, 6].map((p) => damageWith(defender: withStatus('vulnerable', p))),
      [13, 15, 20, 20],
    );
  });

  test('Faiblesse : -25 % par point, plafonnee a -50 %', () {
    expect(
      [1, 2, 3].map((p) => damageWith(attacker: withStatus('weakness', p))),
      [8, 5, 5],
    );
  });

  test('les points se lisent sur la somme des entrees de meme id', () {
    final defender = withStatus('vulnerable', 1, sourceId: 'a')
        .addStatus(const StatusEffect(
      id: 'vulnerable',
      name: 'vulnerable',
      type: StatusType.debuff,
      value: 1,
      duration: 2,
      sourceId: 'b',
    ));
    expect(defender.statuses, hasLength(2));
    expect(damageWith(defender: defender), 15);
  });

  // Les charges : la Foudre du défenseur, le héros gelé (spec P-53, §4.9).
  EntityStats charged(String id, int points, ChargeBearer bearer) =>
      ChargeRules.pose(stats(), charges[id]!, points, bearer);

  test('Foudre sous le seuil : +1 par point, apres le critique', () {
    final defender = charged('shock', 2, ChargeBearer.enemy);
    expect(
      DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: stats(),
        defenderStats: defender,
        charges: charges,
        critChanceBonus: 100,
      ),
      (17, true),
    );
  });

  test('Foudre chargee : +2 par point, que Vulnerable amplifie', () {
    final defender = charged('shock', 3, ChargeBearer.enemy)
        .addStatus(const StatusEffect(
      id: 'vulnerable',
      name: 'vulnerable',
      type: StatusType.debuff,
      value: 2,
      duration: 2,
    ));
    expect(damageWith(defender: defender), 24);
  });

  // Le héros gelé : sa piste `weakenDealt`, posée à la main dans l'état voulu.
  EntityStats frozenHero(ChargeState state) => stats().copyWith(charges: {
        'freeze': ChargeTrack.start(charges['freeze']!, ChargeBearer.hero)
            .copyWith(state: state),
      });

  int hit(EntityStats attacker, int initialDamage) =>
      DamagePipeline.calculate(
        initialDamage: initialDamage,
        attackerStats: attacker,
        defenderStats: stats(),
        charges: charges,
        canCrit: false,
      ).$1;

  test('gele et Faiblesse : 8 puis 6 puis 3', () {
    final weak = withStatus('weakness', 1);
    expect(hit(stats(), 8), 8);
    expect(hit(weak, 8), 6);
    final both = frozenHero(ChargeState.brokenActive).addStatus(
      weak.statuses.single,
    );
    expect(hit(both, 8), 3);
  });

  test('une rupture en attente ne reduit rien', () {
    expect(hit(frozenHero(ChargeState.brokenPending), 10), 10);
  });
}
