import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/tutorial/tutorial_progress_service.dart';

void main() {
  group('TutorialProgressService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default hasCompletedTutorial is false', () async {
      final completed = await TutorialProgressService.hasCompletedTutorial();
      expect(completed, false);
    });

    test('markTutorialCompleted sets completion flag to true', () async {
      await TutorialProgressService.markTutorialCompleted();
      final completed = await TutorialProgressService.hasCompletedTutorial();
      expect(completed, true);
    });

    test('resetTutorial sets completion flag to false', () async {
      await TutorialProgressService.markTutorialCompleted();
      var completed = await TutorialProgressService.hasCompletedTutorial();
      expect(completed, true);

      await TutorialProgressService.resetTutorial();
      completed = await TutorialProgressService.hasCompletedTutorial();
      expect(completed, false);
    });
  });
}
