import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

import 'charge_test_data.dart';
import 'shipped_data.dart';

void main() {
  final catalog = shippedChargeCatalog();
  final freeze = catalog['freeze']!;
  final burn = catalog['burn']!;
  final shock = catalog['shock']!;

  EntityStats fresh() =>
      EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);

  EntityStats pose(
    EntityStats stats,
    ChargeData charge,
    int points, [
    ChargeBearer bearer = ChargeBearer.enemy,
  ]) =>
      ChargeRules.pose(stats, charge, points, bearer);

  group('la pose', () {
    test('sans surcharge, la pose est plafonnee au restant', () {
      var stats = pose(fresh(), freeze, 2);
      stats = pose(stats, freeze, 2);

      final track = stats.charges['freeze']!;
      expect(track.state, ChargeState.brokenPending);
      expect(ChargeRules.points(stats, 'freeze'), 0);
      expect(track.ruptures, 1);
      expect(track.threshold, 4);

      final capped = testCharge();
      var held = pose(fresh(), capped, 2);
      held = pose(held, capped, 2);
      expect(ChargeRules.points(held, 'test_charge'), 3);
      expect(
        ChargeRules.points(pose(held, capped, 1), 'test_charge'),
        3,
      );
    });

    test('Gel : rupture a 3, Gel a 0, seuil a 4 puis 5', () {
      var stats = pose(fresh(), freeze, 3);
      expect(ChargeRules.points(stats, 'freeze'), 0);
      expect(stats.charges['freeze']!.state, ChargeState.brokenPending);
      expect(stats.charges['freeze']!.ruptures, 1);
      expect(stats.charges['freeze']!.threshold, 4);

      stats = stats.copyWith(charges: {
        'freeze': stats.charges['freeze']!.copyWith(state: ChargeState.none),
      });
      stats = pose(stats, freeze, 4);
      expect(stats.charges['freeze']!.threshold, 5);
    });

    test('Gel : rien ne se pose sur un porteur gele', () {
      final frozen = pose(fresh(), freeze, 3);

      expect(pose(frozen, freeze, 2), same(frozen));
    });

    test('Gel : un boss a 6, le heros a 5', () {
      final boss = pose(fresh(), freeze, 5, ChargeBearer.boss);
      expect(boss.charges['freeze']!.ruptures, 0);
      expect(boss.charges['freeze']!.threshold, 6);

      final hero = pose(fresh(), freeze, 5, ChargeBearer.hero);
      expect(hero.charges['freeze']!.ruptures, 1);
      expect(hero.charges['freeze']!.state, ChargeState.brokenPending);
      expect(hero.charges['freeze']!.rupture.kind, RuptureKind.weakenDealt);
    });

    test('Foudre : chargee a 3, la surcharge libre', () {
      var stats = pose(fresh(), shock, 2);
      stats = pose(stats, shock, 1);
      expect(stats.charges['shock']!.state, ChargeState.brokenActive);
      expect(ChargeRules.points(stats, 'shock'), 3);

      stats = pose(stats, shock, 2);
      expect(ChargeRules.points(stats, 'shock'), 5);
      expect(stats.charges['shock']!.state, ChargeState.brokenActive);
      expect(stats.charges['shock']!.ruptures, 1);
    });

    test('Feu : surcharge libre, aucune rupture a la pose', () {
      final stats = pose(fresh(), burn, 9);

      expect(ChargeRules.points(stats, 'burn'), 9);
      expect(stats.charges['burn']!.state, ChargeState.none);
      expect(stats.charges['burn']!.ruptures, 0);
    });

    test('les points sont la somme des entrees de meme id', () {
      StatusEffect shockFrom(String source) => StatusEffect(
            id: 'shock',
            name: 'Foudre',
            type: StatusType.debuff,
            value: 1,
            duration: 1,
            sourceId: source,
          );
      var stats = fresh()
          .addStatus(shockFrom('card:a'))
          .addStatus(shockFrom('card:b'));
      expect(stats.statuses, hasLength(2));
      expect(ChargeRules.points(stats, 'shock'), 2);

      stats = pose(stats, shock, 1);
      expect(stats.statuses.where((s) => s.id == 'shock'), hasLength(1));
      expect(ChargeRules.points(stats, 'shock'), 3);
    });

    test('la forme de l entree : debuff, duree 1, retiree a 0', () {
      var stats = pose(fresh(), freeze, 2);
      final entry = stats.statuses.single;
      expect(entry.id, 'freeze');
      expect(entry.type, StatusType.debuff);
      expect(entry.duration, 1);
      expect(entry.name, freeze.nameFr);

      stats = pose(stats, freeze, 1);
      expect(stats.statuses.where((s) => s.id == 'freeze'), isEmpty);
    });

    test('le tic laisse une charge intacte', () {
      final stats = pose(fresh(), burn, 4).addStatus(const StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 2,
        duration: 1,
      ));

      final ticked = stats.tickStatuses({'burn'});
      final entry = ticked.statuses.single;
      expect((entry.id, entry.value, entry.duration), ('burn', 4, 1));
    });

    test('la rupture en vigueur est copiee sur la piste', () {
      final onHero = pose(fresh(), freeze, 3, ChargeBearer.hero);
      expect(onHero.charges['freeze']!.rupture.kind, RuptureKind.weakenDealt);
      expect(onHero.charges['freeze']!.rupture.percent, 50);

      final onEnemy = pose(fresh(), freeze, 1);
      expect(onEnemy.charges['freeze']!.rupture.kind, RuptureKind.skipAction);
    });

    test(
        'la piste survit a takeDamage, addStatus, tickStatuses et copyWith ; '
        'toJson ne l ecrit pas', () {
      final stats = pose(fresh(), freeze, 2);
      final track = stats.charges['freeze']!;

      expect(stats.takeDamage(5).charges['freeze'], track);
      expect(
        stats
            .addStatus(const StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 1,
              duration: 2,
            ))
            .charges['freeze'],
        track,
      );
      expect(stats.tickStatuses({'freeze'}).charges['freeze'], track);
      expect(stats.copyWith(currentPv: 50).charges['freeze'], track);

      expect(stats.toJson().containsKey('charges'), isFalse);
      expect(EntityStats.fromJson(stats.toJson()).charges, isEmpty);
    });

    test('clearCombatEffects vide les statuts et les pistes', () {
      final cleared = pose(fresh(), freeze, 2)
          .addStatus(const StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 1,
            duration: 2,
          ))
          .clearCombatEffects();

      expect(cleared.statuses, isEmpty);
      expect(cleared.charges, isEmpty);
    });
  });

  group('les lignes', () {
    test('une ligne par charge : points, seuil, etat et valeur', () {
      expect(
        ChargeRules.linesFor(pose(fresh(), freeze, 2)),
        [const ChargeLine('freeze', 2, 3, ChargeState.none, RuptureKind.skipAction, 0)],
      );

      var charged = pose(fresh(), shock, 3);
      charged = pose(charged, shock, 1);
      expect(
        ChargeRules.linesFor(charged),
        [
          const ChargeLine(
            'shock', 4, 3, ChargeState.brokenActive, RuptureKind.amplifyHits, 8),
        ],
      );

      expect(
        ChargeRules.linesFor(pose(fresh(), shock, 2)),
        [const ChargeLine('shock', 2, 3, ChargeState.none, RuptureKind.amplifyHits, 0)],
      );
      expect(
        ChargeRules.linesFor(pose(fresh(), freeze, 2, ChargeBearer.hero)),
        [const ChargeLine('freeze', 2, 5, ChargeState.none, RuptureKind.weakenDealt, 0)],
      );

      expect(
        ChargeRules.linesFor(pose(fresh(), freeze, 5, ChargeBearer.hero)),
        [
          const ChargeLine('freeze', 0, 6, ChargeState.brokenPending,
              RuptureKind.weakenDealt, 50),
        ],
      );
    });

    test('un ennemi gele a 0 point a sa ligne ; une charge a 0 non rompue n en a pas',
        () {
      expect(ChargeRules.linesFor(pose(fresh(), freeze, 3)), hasLength(1));

      final drained = pose(fresh(), freeze, 2).copyWith(statuses: const []);
      expect(ChargeRules.linesFor(drained), isEmpty);
      expect(ChargeRules.linesFor(fresh()), isEmpty);
    });

    test('deux lignes egales sont egales', () {
      const line = ChargeLine('shock', 4, 3, ChargeState.brokenActive, RuptureKind.amplifyHits, 8);

      expect(
        line,
        const ChargeLine('shock', 4, 3, ChargeState.brokenActive, RuptureKind.amplifyHits, 8),
      );
      expect(
        line.hashCode,
        const ChargeLine('shock', 4, 3, ChargeState.brokenActive, RuptureKind.amplifyHits, 8).hashCode,
      );
      expect(
        line,
        isNot(const ChargeLine('shock', 5, 3, ChargeState.brokenActive, RuptureKind.amplifyHits, 8)),
      );
    });
  });
}
