import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Le statut `hp_regen`, la Source de Vie : des PV au début des tours suivants,
/// sur le modèle de `mana_regen`, symétrique et borné aux PV max (spec P-42
/// tranche 3, A6, A7, A20).
void main() {
  EntityStats bearer({int currentPv = 50}) => EntityStats(
        maxPv: 80,
        currentPv: currentPv,
        armure: 0,
        might: 0,
      );

  StatusEffect spring() => EffectResolver.createStatus('hp_regen', 2, 3)!;

  EntityStats playerTurn(EntityStats stats) =>
      StatusEffectProcessor.processPlayerStatuses(
        stats,
        const [],
        const ChargeCatalog.empty(),
      );

  EntityStats enemyTurn(EntityStats stats) =>
      StatusEffectProcessor.processEnemyStatuses(
        stats,
        const ChargeCatalog.empty(),
      );

  int springCount(EntityStats stats) =>
      stats.statuses.where((s) => s.id == 'hp_regen').length;

  test('createStatus fabrique hp_regen : un buff nomme Source de Vie', () {
    final status = EffectResolver.createStatus('hp_regen', 2, 3);

    expect(status, isNotNull);
    expect(status!.id, 'hp_regen');
    expect(status.name, 'Source de Vie');
    expect(status.type, StatusType.buff);
    expect((status.value, status.duration), (2, 3));
  });

  test('Source de Vie : +2 PV au debut des trois tours suivants, puis rien',
      () {
    var stats = bearer().addStatus(spring());

    final pv = <int>[];
    for (var turn = 0; turn < 4; turn++) {
      stats = playerTurn(stats);
      pv.add(stats.currentPv);
    }

    expect(pv, [52, 54, 56, 56]);
    expect(springCount(stats), 0);
  });

  test('la Source de Vie ne depasse jamais les PV max', () {
    final stats = playerTurn(bearer(currentPv: 79).addStatus(spring()));

    expect(stats.currentPv, 80);
  });

  test('deux Sources de Vie s additionnent', () {
    final stats = playerTurn(bearer().addStatus(spring()).addStatus(spring()));

    expect(stats.currentPv, 54);
  });

  test('un heros que son Poison tue n est pas releve', () {
    final poison = EffectResolver.createStatus('poison', 3, 1)!;
    final stats = playerTurn(
      bearer(currentPv: 2).addStatus(poison).addStatus(spring()),
    );

    expect(stats.currentPv, 0);
  });

  test('sur un ennemi : +2 PV au debut de ses trois tours suivants, borne aux '
      'PV max', () {
    var stats = bearer().addStatus(spring());

    final pv = <int>[];
    for (var turn = 0; turn < 4; turn++) {
      stats = enemyTurn(stats);
      pv.add(stats.currentPv);
    }

    expect(pv, [52, 54, 56, 56]);
    expect(springCount(stats), 0);
    expect(enemyTurn(bearer(currentPv: 79).addStatus(spring())).currentPv, 80);
  });

  test('un ennemi que son Poison tue n est pas releve', () {
    final poison = EffectResolver.createStatus('poison', 3, 1)!;
    final stats = enemyTurn(
      bearer(currentPv: 2).addStatus(poison).addStatus(spring()),
    );

    expect(stats.currentPv, 0);
  });
}
