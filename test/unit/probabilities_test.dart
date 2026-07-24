import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';

/// Samples [LevelUpRewardService.rollRarity] (the real production code,
/// not a copy of its formula) [sampleCount] times and returns the observed
/// percentage of rolls landing on each rarity.
Map<RewardRarity, double> _sampleDraftProbabilities(
  int luck,
  bool isLevelReward, {
  int sampleCount = 20000,
}) {
  final counts = <RewardRarity, int>{for (final r in RewardRarity.values) r: 0};
  for (var i = 0; i < sampleCount; i++) {
    final rarity = LevelUpRewardService.rollRarity(
      luck,
      isLevelReward: isLevelReward,
    );
    counts[rarity] = counts[rarity]! + 1;
  }
  return counts.map((k, v) => MapEntry(k, v / sampleCount * 100));
}

void main() {
  group('Probabilities Logic Tests', () {
    Map<String, double> calculateRelicProbabilities(int luck) {
      double leg = 1.0 + luck * 0.5;
      double epic = 5.0 + luck * 1.0;
      double rare = 14.0 + luck * 2.0;
      double uncommon = 20.0 + luck * 3.0;

      double sum = leg + epic + rare + uncommon;
      if (sum > 100.0) {
        leg = leg / sum * 100.0;
        epic = epic / sum * 100.0;
        rare = rare / sum * 100.0;
        uncommon = uncommon / sum * 100.0;
        return {
          'legendary': leg,
          'epic': epic,
          'rare': rare,
          'uncommon': uncommon,
          'common': 0.0,
        };
      }
      double common = 100.0 - sum;
      return {
        'legendary': leg,
        'epic': epic,
        'rare': rare,
        'uncommon': uncommon,
        'common': common,
      };
    }

    test(
      'LevelUpRewardService.rollRarity matches expected weights for luck = 0 (isLevelReward = false)',
      () {
        final probs = _sampleDraftProbabilities(0, false);
        expect(probs[RewardRarity.mythic], 0.0);
        expect(probs[RewardRarity.legendary], closeTo(2.0, 2.0));
        expect(probs[RewardRarity.epic], closeTo(6.0, 2.0));
        expect(probs[RewardRarity.rare], closeTo(16.0, 2.5));
        expect(probs[RewardRarity.uncommon], closeTo(24.0, 2.5));
        expect(probs[RewardRarity.common], closeTo(52.0, 2.5));

        final sum = probs.values.reduce((a, b) => a + b);
        expect(sum, closeTo(100.0, 0.01));
      },
    );

    test(
      'LevelUpRewardService.rollRarity matches expected weights for luck = 5 (isLevelReward = false)',
      () {
        final probs = _sampleDraftProbabilities(5, false);
        expect(probs[RewardRarity.mythic], 0.0);
        expect(probs[RewardRarity.legendary], closeTo(4.5, 2.0));
        expect(probs[RewardRarity.epic], closeTo(13.5, 2.0));
        expect(probs[RewardRarity.rare], closeTo(31.0, 2.5));
        expect(probs[RewardRarity.uncommon], closeTo(44.0, 2.5));
        expect(probs[RewardRarity.common], closeTo(7.0, 2.0));

        final sum = probs.values.reduce((a, b) => a + b);
        expect(sum, closeTo(100.0, 0.01));
      },
    );

    test(
      'LevelUpRewardService.rollRarity matches expected weights for luck = 0 (isLevelReward = true)',
      () {
        final probs = _sampleDraftProbabilities(0, true);
        expect(probs[RewardRarity.mythic], closeTo(0.5, 0.5));
        expect(probs[RewardRarity.legendary], closeTo(2.0, 2.0));
        expect(probs[RewardRarity.epic], closeTo(6.0, 2.0));
        expect(probs[RewardRarity.rare], closeTo(16.0, 2.5));
        expect(probs[RewardRarity.uncommon], closeTo(24.0, 2.5));
        expect(probs[RewardRarity.common], closeTo(51.5, 2.5));

        final sum = probs.values.reduce((a, b) => a + b);
        expect(sum, closeTo(100.0, 0.01));
      },
    );

    test('calculateRelicProbabilities with luck = 0', () {
      final probs = calculateRelicProbabilities(0);
      expect(probs['legendary'], 1.0);
      expect(probs['epic'], 5.0);
      expect(probs['rare'], 14.0);
      expect(probs['uncommon'], 20.0);
      expect(probs['common'], 60.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });

    test('calculateRelicProbabilities with luck = 10', () {
      final probs = calculateRelicProbabilities(10);
      expect(probs['legendary']!, closeTo(5.71, 0.01));
      expect(probs['epic']!, closeTo(14.29, 0.01));
      expect(probs['rare']!, closeTo(32.38, 0.01));
      expect(probs['uncommon']!, closeTo(47.62, 0.01));
      expect(probs['common'], 0.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });
  });
}
