import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Probabilities Logic Tests', () {
    Map<String, double> calculateDraftProbabilities(int luck, bool isLevelReward) {
      double legendaryChance = isLevelReward ? 0.5 + luck * 0.5 : 1.0 + luck * 0.5;
      double epicChance = isLevelReward ? 4.5 + luck * 1.5 : 5.0 + luck * 1.5;
      double rareChance = isLevelReward ? 15.0 + luck * 3.0 : 14.0 + luck * 3.0;
      double uncommonChance = 20.0 + luck * 4.0;

      legendaryChance = legendaryChance.clamp(0.0, 100.0);
      epicChance = epicChance.clamp(0.0, 100.0);
      rareChance = rareChance.clamp(0.0, 100.0);
      uncommonChance = uncommonChance.clamp(0.0, 100.0);

      double pLeg = legendaryChance;
      double pEpic = epicChance;
      double pRare = rareChance;
      double pUncommon = uncommonChance;
      
      double sum = pLeg;
      pEpic = pEpic.clamp(0.0, 100.0 - sum);
      sum += pEpic;
      pRare = pRare.clamp(0.0, 100.0 - sum);
      sum += pRare;
      pUncommon = pUncommon.clamp(0.0, 100.0 - sum);
      sum += pUncommon;
      double pCommon = (100.0 - sum).clamp(0.0, 100.0);

      return {
        'legendary': pLeg,
        'epic': pEpic,
        'rare': pRare,
        'uncommon': pUncommon,
        'common': pCommon,
      };
    }

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

    test('calculateDraftProbabilities with luck = 0 (isLevelReward = false)', () {
      final probs = calculateDraftProbabilities(0, false);
      expect(probs['legendary'], 1.0);
      expect(probs['epic'], 5.0);
      expect(probs['rare'], 14.0);
      expect(probs['uncommon'], 20.0);
      expect(probs['common'], 60.0);
      
      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });

    test('calculateDraftProbabilities with luck = 5 (isLevelReward = false)', () {
      final probs = calculateDraftProbabilities(5, false);
      expect(probs['legendary'], 3.5);
      expect(probs['epic'], 12.5);
      expect(probs['rare'], 29.0);
      expect(probs['uncommon'], 40.0);
      expect(probs['common'], 15.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });

    test('calculateDraftProbabilities with luck = 0 (isLevelReward = true)', () {
      final probs = calculateDraftProbabilities(0, true);
      expect(probs['legendary'], 0.5);
      expect(probs['epic'], 4.5);
      expect(probs['rare'], 15.0);
      expect(probs['uncommon'], 20.0);
      expect(probs['common'], 60.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });

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
