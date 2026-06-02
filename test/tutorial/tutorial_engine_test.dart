import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';

void main() {
  group('TutorialEngine Tests', () {
    late TutorialEngine engine;

    setUp(() {
      engine = TutorialEngine();
      engine.resetMockState();
    });

    test('Initial state is step 0', () {
      expect(engine.currentStepIndex, 0);
      expect(engine.isLastStep, false);
    });

    test('nextStep advances step and resets mock state', () {
      engine.nextStep();
      expect(engine.currentStepIndex, 1);

      // Advance to step 5 (playCard step)
      while (engine.currentStepIndex < 5) {
        engine.nextStep();
      }
      expect(engine.currentStepIndex, 5);
      expect(engine.mockState.enemy, isNotNull);
      expect(engine.mockState.enemy!.hp, 20);

      // Playing a card deals damage
      final card = engine.mockState.hand.firstWhere((c) => c.id == 'strike');
      final success = engine.playCard(card);
      expect(success, true);
      expect(engine.mockState.enemy!.hp, 14); // 20 - 6 damage
    });

    test('prevStep goes back and resets mock state', () {
      engine.nextStep();
      expect(engine.currentStepIndex, 1);
      engine.prevStep();
      expect(engine.currentStepIndex, 0);
    });

    test('mergeCards upgrades cards in hand', () {
      // Go to step 9 (merge step)
      while (engine.currentStepIndex < 9) {
        engine.nextStep();
      }
      expect(engine.currentStepIndex, 9);
      expect(engine.mockState.hand.length, 3);

      engine.mergeCards();
      expect(engine.mockState.hand.length, 1);
      expect(engine.mockState.hand.first.id, 'strike_upgraded');
    });

    test('gainXp triggers level up when exceeding 100', () {
      // Go to step 10 (xp step)
      while (engine.currentStepIndex < 10) {
        engine.nextStep();
      }
      expect(engine.currentStepIndex, 10);
      expect(engine.mockState.playerLevel, 1);
      expect(engine.mockState.playerXp, 0);

      engine.gainXp(35);
      expect(engine.mockState.playerXp, 35);
      engine.gainXp(35);
      expect(engine.mockState.playerXp, 70);
      engine.gainXp(35);
      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.playerXp, 5); // 105 - 100
    });
  });
}
