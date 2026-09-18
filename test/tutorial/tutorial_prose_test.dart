import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/tutorial/tutorial_data.dart';
import 'package:roguelike_card_game/tutorial/tutorial_prose.dart';
import 'package:roguelike_card_game/tutorial/tutorial_step.dart';

/// La prose du tutoriel ne recopie plus la liste des récompenses à la main
/// (spec P-41, §8.1 : « la prose du tutoriel [...] lit le registre »).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les placeholders sont remplis depuis le catalogue', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    const gabarit =
        'Trois options sont tirées parmi {rollableCount} types — '
        '{rollableNames} — et jusqu\'à {mythicCount} options Mythiques '
        'peuvent s\'y ajouter : {mythicNames}.';

    expect(
      fillRewardPlaceholders(gabarit, rewards, isFrench: true),
      'Trois options sont tirées parmi six types — Vitalité, Aiguisage, '
      'Affinité, Sagesse, Précision et Férocité — et jusqu\'à deux options '
      'Mythiques peuvent s\'y ajouter : Trèfle à 4 feuilles et Miroir.',
    );
  });

  test('les noms sont donnés dans l ordre déclaré, pas alphabétique', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    final rendu = fillRewardPlaceholders('{rollableNames}', rewards, isFrench: true);

    expect(rendu.indexOf('Vitalité'), lessThan(rendu.indexOf('Aiguisage')));
    expect(rendu.indexOf('Précision'), lessThan(rendu.indexOf('Férocité')));
  });

  test('l anglais est rendu en anglais', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      '4-Leaf Clover and Mirror',
    );
    expect(
      fillRewardPlaceholders('{rollableCount}', rewards, isFrench: false),
      'six',
    );
  });

  test('aucun placeholder ne survit dans l étape de draft', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    final etape = kTutorialSteps
        .firstWhere((s) => s.type == TutorialStepType.draft);

    for (final corps in [etape.bodyFr, etape.bodyEn]) {
      final rendu = fillRewardPlaceholders(
        corps,
        rewards,
        isFrench: corps == etape.bodyFr,
      );
      expect(rendu, isNot(contains('{')));
    }
  });

  test('un texte sans placeholder traverse inchangé', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    const corps = 'Les reliques donnent des bonus passifs.';

    expect(fillRewardPlaceholders(corps, rewards, isFrench: true), corps);
  });
}
