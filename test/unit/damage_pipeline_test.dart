import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/damage_pipeline.dart';
import 'package:roguelike_card_game/game/services/proportional_status.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Le critique que la carte jouée ajoute à celui de l'attaquant (spec P-43
/// E2, §4.2, A10) : `precise`.
void main() {
  // Ni critique, ni statut : seul le bonus de la carte peut critiquer.
  EntityStats stats() =>
      EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);

  test('critChanceBonus s ajoute au jet : a 100 points, le coup est critique',
      () {
    for (var i = 0; i < 20; i++) {
      final (damage, isCrit) = DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: stats(),
        defenderStats: stats(),
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
}
