import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Le statut `mana_regen`, la Source de Mana : du mana au début des tours
/// suivants, sur le modèle de `might_regen` (spec P-42 tranche 2, A5).
void main() {
  EntityStats hero() => EntityStats(
        maxPv: 80,
        currentPv: 80,
        armure: 0,
        might: 0,
        maxMana: 3,
        currentMana: 0,
      );

  int manaRegenCount(EntityStats stats) =>
      stats.statuses.where((s) => s.id == 'mana_regen').length;

  test('createStatus fabrique mana_regen : un buff nomme Source de Mana', () {
    final status = EffectResolver.createStatus('mana_regen', 1, 2);

    expect(status, isNotNull);
    expect(status!.id, 'mana_regen');
    expect(status.name, 'Source de Mana');
    expect(status.type, StatusType.buff);
    expect((status.value, status.duration), (1, 2));
  });

  test('Source de Mana : +1 Mana au debut des deux tours suivants, puis rien',
      () {
    var stats = hero().addStatus(EffectResolver.createStatus('mana_regen', 1, 2)!);

    final gains = <int>[];
    for (var turn = 0; turn < 3; turn++) {
      stats = StatusEffectProcessor.processPlayerStatuses(
      stats,
      const [],
      const ChargeCatalog.empty(),
    );
      gains.add(stats.currentMana);
      stats = stats.copyWith(currentMana: 0);
    }

    expect(gains, [1, 1, 0]);
    expect(manaRegenCount(stats), 0);
  });

  test('deux Sources de Mana s additionnent', () {
    final source = EffectResolver.createStatus('mana_regen', 1, 2)!;
    var stats = hero().addStatus(source).addStatus(source);

    stats = StatusEffectProcessor.processPlayerStatuses(
      stats,
      const [],
      const ChargeCatalog.empty(),
    );

    expect(stats.currentMana, 2);
  });
}
