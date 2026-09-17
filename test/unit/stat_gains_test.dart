import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

void main() {
  EntityStats stats() => EntityStats(
        maxPv: 50,
        currentPv: 40,
        maxMana: 3,
        currentMana: 3,
        armure: 1,
        mastery: 3,
        might: 2,
        lastActionWasCrit: true,
      );

  group('StatGains.apply', () {
    // La Maîtrise agit sur le passif avant son gain (spec P-49, §6.3) :
    // aucune source, `passive` comprise, ne la reçoit ici.
    for (final source in GainSource.values) {
      test('armure de source ${source.name} : la valeur seule', () {
        final gain = StatGain(GainResource.armor, 2, source);
        expect(StatGains.apply(stats(), gain).armure, 1 + 2);
      });
    }

    test('mana : aucun plafond', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      expect(StatGains.apply(stats(), gain).currentMana, 3 + 2);
    });

    test('Puissance : un gain ajoute, un gain negatif retire', () {
      final s = stats();
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, 4, GainSource.progression)).might,
        2 + 4,
      );
      expect(
        StatGains.apply(s, const StatGain(GainResource.might, -2, GainSource.progression)).might,
        0,
      );
    });

    test('un gain ne touche a rien d autre', () {
      const gain = StatGain(GainResource.armor, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain);

      expect(after.currentPv, 40);
      expect(after.currentMana, 3);
      expect(after.might, 2);
      expect(after.mastery, 3);
      expect(after.lastActionWasCrit, isTrue);
    });
  });
}
