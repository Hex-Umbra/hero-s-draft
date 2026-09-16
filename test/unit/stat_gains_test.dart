import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

void main() {
  EntityStats stats() => EntityStats(
        maxPv: 50,
        currentPv: 40,
        maxMana: 3,
        currentMana: 3,
        armure: 1,
        armorMastery: 3,
        attackPower: 2,
        lastActionWasCrit: true,
      );

  group('StatGains.apply', () {
    test('armure d une carte : la valeur seule', () {
      const gain = StatGain(GainResource.armor, 10, GainSource.card);
      expect(StatGains.apply(stats(), gain).armure, 1 + 10);
    });

    for (final source in GainSource.values.where((s) => s != GainSource.passive)) {
      test('armure de source ${source.name} : jamais de Maitrise', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain).armure, 1 + 2);
      });
    }

    test('armure d un passif : la valeur plus la Maitrise', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.passive);
      expect(StatGains.apply(stats(), gain).armure, 1 + 2 + 3);
    });

    test('la Maitrise d un passif compte le statut armor_mastery', () {
      final boosted = stats().addStatus(
        const StatusEffect(
          id: 'armor_mastery',
          name: 'Maitrise',
          type: StatusType.buff,
          value: 1,
          duration: 2,
        ),
      );
      const gain = StatGain(GainResource.armor, 2, GainSource.passive);
      expect(StatGains.apply(boosted, gain).armure, 1 + 2 + 3 + 1);
    });

    test('un passif de valeur 0 rend quand meme la Maitrise', () {
      const gain = StatGain(GainResource.armor, 0, GainSource.passive);
      expect(StatGains.apply(stats(), gain).armure, 1 + 3);
    });

    test('mana : aucun plafond', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      expect(StatGains.apply(stats(), gain).currentMana, 3 + 2);
    });

    test('puissances : chacune dans sa stat, et un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.attackPower, 4, GainSource.progression)).attackPower,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.attackPower, -2, GainSource.progression)).attackPower,
        0,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.skillPower, 3, GainSource.progression)).skillPower,
        3,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.alterationPower, 5, GainSource.progression)).alterationPower,
        5,
      );
    });

    test('un gain ne touche a rien d autre', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain);

      expect(after.currentPv, 40);
      expect(after.currentMana, 3);
      expect(after.attackPower, 2);
      expect(after.armorMastery, 3);
      expect(after.lastActionWasCrit, isTrue);
    });
  });
}
