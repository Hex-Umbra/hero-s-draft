import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/fire_wave_report.dart';
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

  group('les coups', () {
    test('noteHit note le bonus de chaque coup, rien sans Foudre', () {
      final plain = fresh();
      expect(ChargeRules.noteHit(plain, catalog), same(plain));

      var stats = pose(fresh(), shock, 2);
      stats = ChargeRules.noteHit(stats, catalog);
      expect(stats.chargeHits, [const ChargeHit(2)]);

      stats = pose(stats, shock, 1);
      stats = ChargeRules.noteHit(stats, catalog);
      expect(stats.chargeHits, [const ChargeHit(2), const ChargeHit(6)]);
    });

    test(
        'le journal des coups survit a takeDamage, addStatus, tickStatuses et '
        'copyWith ; toJson ne l ecrit pas ; clearCombatEffects le vide', () {
      final stats = ChargeRules.noteHit(pose(fresh(), shock, 2), catalog);
      final hits = stats.chargeHits;
      expect(hits, isNotEmpty);

      expect(stats.takeDamage(5).chargeHits, hits);
      expect(
        stats
            .addStatus(const StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 1,
              duration: 2,
            ))
            .chargeHits,
        hits,
      );
      expect(stats.tickStatuses({'shock'}).chargeHits, hits);
      expect(stats.copyWith(currentPv: 50).chargeHits, hits);

      expect(stats.toJson().containsKey('chargeHits'), isFalse);
      expect(EntityStats.fromJson(stats.toJson()).chargeHits, isEmpty);
      expect(stats.clearCombatEffects().chargeHits, isEmpty);
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

  group('le Feu', () {
    // Les valeurs de l'exemple de l'étude, écrites ici et non lues dans le
    // fichier livré (A18) : seuil 3, 4 par point, 12 par explosion, 1 Feu à
    // chaque voisin.
    final fire = testCharge({
      'id': 'test_fire',
      'brokenName_fr': null,
      'brokenName_en': null,
      'overcharge': true,
      'breaksOn': 'bearerTurn',
      'rupture': {
        'kind': 'explode',
        'damagePerPoint': 4,
        'explosionDamage': 12,
        'chargePerNeighbour': 1,
      },
    });
    final fireCatalog = ChargeCatalog.of([fire]);
    const target = EnemyData(
      id: 'cible',
      nameEn: 'Target',
      maxHp: 200,
      baseDamage: 0,
      spritePath: 'cible.png',
      tier: 1,
    );

    EnemyInstance foe(String id, {int burning = 0, int pv = 200}) {
      final stats = EntityStats(maxPv: pv, currentPv: pv, armure: 0, might: 0);
      return EnemyInstance(
        id: id,
        data: target,
        stats: burning == 0
            ? stats
            : ChargeRules.pose(stats, fire, burning, ChargeBearer.enemy),
      );
    }

    int lost(EnemyInstance e) => e.stats.maxPv - e.stats.currentPv;
    int fireOn(EnemyInstance e) => ChargeRules.points(e.stats, 'test_fire');

    (List<EnemyInstance>, FireWaveReport?) wave(
      List<EnemyInstance> row, {
      Set<String>? bearers,
      int number = 1,
    }) =>
        ChargeRules.fireWave(
          row,
          bearerIds: bearers,
          wave: number,
          charges: fireCatalog,
        );

    test('5 points : 16 au porteur, 12 et 1 Feu a chaque voisin', () {
      final (row, report) = wave([foe('A'), foe('B', burning: 5), foe('C')]);

      expect(row.map(lost), [12, 16, 12]);
      expect(row.map(fireOn), [1, 0, 1]);
      expect(row[1].stats.statuses, isEmpty);
      expect(row[1].stats.charges['test_fire']!.ruptures, 1);

      final resolution = report!.resolved.single;
      expect(
        (
          resolution.bearerId,
          resolution.chargeId,
          resolution.tranches,
        ),
        ('B', 'test_fire', 1),
      );
      expect(
        resolution.splashes.map((s) => (s.targetId, s.charge)),
        [('A', 1), ('C', 1)],
      );
      expect(report.wave, 1);
      expect(report.nextBearerIds, {'A', 'C'});
    });

    test('2 points : 4 au porteur, sans explosion', () {
      final (row, report) = wave([foe('A'), foe('B', burning: 2), foe('C')]);

      expect(row.map(lost), [0, 4, 0]);
      expect(row.map(fireOn), [0, 0, 0]);
      expect(row[1].stats.charges['test_fire']!.ruptures, 0);
      expect(report!.resolved.single.tranches, 0);
      expect(report.resolved.single.splashes, isEmpty);
      expect(report.nextBearerIds, isEmpty);
    });

    test('un bout de rangee n a qu un voisin, un ennemi seul aucun', () {
      final (edge, edgeReport) =
          wave([foe('A', burning: 3), foe('B'), foe('C')]);
      expect(edge.map(lost), [12, 12, 0]);
      expect(edge.map(fireOn), [0, 1, 0]);
      expect(
        edgeReport!.resolved.single.splashes.map((s) => s.targetId),
        ['B'],
      );

      final (alone, aloneReport) = wave([foe('A', burning: 3)]);
      expect(lost(alone.single), 12);
      expect(aloneReport!.resolved.single.splashes, isEmpty);
      expect(aloneReport.nextBearerIds, isEmpty);
    });

    test('le heros porteur : sa part seule', () {
      final hero = ChargeRules.pose(
        EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0),
        fire,
        5,
        ChargeBearer.hero,
      );

      final after = ChargeRules.resolveOwnFire(hero, fireCatalog);

      expect(after.currentPv, 100 - 16);
      expect(ChargeRules.points(after, 'test_fire'), 0);
    });

    test('l exemple de l etude : A 48, B 64, C 48, en trois vagues', () {
      var (row, report) = wave([foe('A'), foe('B', burning: 9), foe('C')]);
      expect(report!.nextBearerIds, {'A', 'C'});
      expect(row.map(lost), [36, 36, 36]);

      (row, report) = wave(row, bearers: report.nextBearerIds, number: 2);
      expect(report!.wave, 2);
      expect(report.nextBearerIds, {'B'});
      expect(row.map(lost), [48, 60, 48]);

      (row, report) = wave(row, bearers: report.nextBearerIds, number: 3);
      expect(report!.wave, 3);
      expect(report.nextBearerIds, isEmpty);
      expect(row.map(lost), [48, 64, 48]);
      expect(row.map(fireOn), [0, 0, 0]);

      expect(wave(row, bearers: report.nextBearerIds, number: 4).$2, isNull);
    });

    test('une vague est simultanee', () {
      final (row, report) =
          wave([foe('A', burning: 3), foe('B', burning: 3)]);

      expect(row.map(lost), [12 + 12, 12 + 12]);
      expect(row.map(fireOn), [1, 1]);
      expect(report!.nextBearerIds, {'A', 'B'});
    });

    test('un porteur que sa vague tue explose quand meme', () {
      final (row, report) =
          wave([foe('A'), foe('B', burning: 9, pv: 10), foe('C')]);

      expect(row[1].stats.currentPv, 0);
      expect([lost(row[0]), lost(row[2])], [36, 36]);
      expect([fireOn(row[0]), fireOn(row[2])], [3, 3]);
      expect(report!.resolved.single.tranches, 3);
    });

    test('un mort pendant la chaine garde sa place et ne recoit plus rien', () {
      // Vague 1 : A explose trois fois sur B ; C, tué par sa propre part,
      // explose une fois sur B. B porte alors 4 Feu, C est mort.
      var (row, report) = wave([
        foe('A', burning: 9),
        foe('B'),
        foe('C', burning: 3, pv: 10),
      ]);
      expect(row[2].stats.currentPv, 0);
      expect(fireOn(row[1]), 4);
      expect(report!.nextBearerIds, {'B'});

      (row, report) = wave(row, bearers: report.nextBearerIds, number: 2);

      expect(row, hasLength(3));
      expect(row[2].stats.currentPv, 0);
      expect(fireOn(row[2]), 0);
      expect(
        report!.resolved.single.splashes.map((s) => (s.targetId, s.charge)),
        [('A', 1)],
      );
      expect(lost(row[0]), 48);
      expect(report.nextBearerIds, {'A'});
    });

    test('la chaine s arrete', () {
      var row = [
        for (final id in ['A', 'B', 'C', 'D', 'E'])
          foe(id, burning: 9, pv: 10000),
      ];
      int inPlay(List<EnemyInstance> r) =>
          r.fold(0, (sum, e) => sum + fireOn(e));

      Set<String>? bearers;
      var waves = 0;
      while (true) {
        final before = inPlay(row);
        final (next, report) = wave(row, bearers: bearers, number: waves + 1);
        if (report == null) break;
        waves++;
        expect(waves, lessThan(50));
        if (report.resolved.any((r) => r.tranches > 0)) {
          expect(inPlay(next), lessThan(before));
        }
        row = next;
        bearers = report.nextBearerIds;
      }

      expect(waves, greaterThan(1));
      expect(inPlay(row), 0);
    });

    test('l Armure absorbe le Feu ; ni Vulnerable ni critique', () {
      final bearer = foe('A', burning: 3);
      final armoured = bearer.copyWith(
        stats: bearer.stats.copyWith(armure: 5, critChance: 100).addStatus(
              const StatusEffect(
                id: 'vulnerable',
                name: 'Vulnérable',
                type: StatusType.debuff,
                value: 2,
                duration: 2,
              ),
            ),
      );

      final (row, _) = wave([armoured]);

      expect(lost(row.single), 12 - 5);
      expect(row.single.stats.armure, 0);
    });
  });

  group('le declin et les fermetures', () {
    test('declin : -1 sans rupture, jamais sous 0, aucun sur un porteur rompu',
        () {
      final two = ChargeRules.decay(pose(fresh(), freeze, 2), catalog);
      expect(ChargeRules.points(two, 'freeze'), 1);

      final one = ChargeRules.decay(two, catalog);
      expect(one.statuses.where((s) => s.id == 'freeze'), isEmpty);
      expect(ChargeRules.decay(one, catalog).statuses, isEmpty);

      final frozen = pose(fresh(), freeze, 3);
      final kept = ChargeRules.decay(frozen, catalog);
      expect(kept.charges['freeze'], frozen.charges['freeze']);
      expect(kept.charges['freeze']!.state, ChargeState.brokenPending);

      final burning = ChargeRules.decay(pose(fresh(), burn, 4), catalog);
      expect(ChargeRules.points(burning, 'burn'), 4);
    });

    test('Foudre : retombe a 0 a la fermeture de phase, declin sous le seuil seulement',
        () {
      final charged = pose(fresh(), shock, 3);
      expect(ChargeRules.points(ChargeRules.decay(charged, catalog), 'shock'), 3);

      final closed = ChargeRules.closePhase(charged, endsPlayerTurn: false);
      expect(ChargeRules.points(closed, 'shock'), 0);
      expect(closed.charges['shock']!.state, ChargeState.none);

      final below = ChargeRules.decay(pose(fresh(), shock, 2), catalog);
      expect(ChargeRules.points(below, 'shock'), 1);
    });

    test('le gel du heros en attente survit a la fermeture du tour du joueur',
        () {
      ChargeState state(EntityStats s) => s.charges['freeze']!.state;

      var hero = pose(fresh(), freeze, 5, ChargeBearer.hero);
      expect(state(hero), ChargeState.brokenPending);

      hero = ChargeRules.closePhase(hero, endsPlayerTurn: true);
      expect(state(hero), ChargeState.brokenPending);

      hero = ChargeRules.startBearerTurn(hero);
      expect(state(hero), ChargeState.brokenActive);

      hero = ChargeRules.closePhase(hero, endsPlayerTurn: false);
      expect(state(hero), ChargeState.brokenActive);

      hero = ChargeRules.closePhase(hero, endsPlayerTurn: true);
      expect(state(hero), ChargeState.none);
    });
  });
}
