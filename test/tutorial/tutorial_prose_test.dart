import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
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
      'Trois options sont tirées parmi cinq types — Vitalité, Aiguisage, '
      'Affinité, Précision, Férocité — et jusqu\'à trois options Mythiques '
      'peuvent s\'y ajouter : Sagesse, Trèfle à 4 feuilles et Miroir.',
    );
  });

  test('les tirables se joignent par virgules, les mythiques par une conjonction', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;

    // Le texte d'origine (avant ce chantier) appose les tirables entre
    // tirets, a virgules pures, et coordonne seulement les mythiques avec
    // "et"/"and" (git show 95dec39:lib/tutorial/tutorial_data.dart). Les deux
    // listes ne sont pas la meme forme grammaticale ; ce test empeche de les
    // refusionner derriere le meme join sans faire rougir la suite.
    expect(
      fillRewardPlaceholders('{rollableNames}', rewards, isFrench: true),
      'Vitalité, Aiguisage, Affinité, Précision, Férocité',
    );
    expect(
      fillRewardPlaceholders('{rollableNames}', rewards, isFrench: false),
      'Vitality, Sharpening, Affinity, Precision, Ferocity',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: true),
      'Sagesse, Trèfle à 4 feuilles et Miroir',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      'Wisdom, 4-Leaf Clover and Mirror',
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
      'Wisdom, 4-Leaf Clover and Mirror',
    );
    expect(
      fillRewardPlaceholders('{rollableCount}', rewards, isFrench: false),
      'five',
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

  // Les paliers de l'étape « L'Expérience » se lisent sur la courbe (spec
  // P-43 E3, §5.3, A26).
  test('les paliers de l acte 1 et de l acte 2 sont lus sur la courbe',
      () async {
    final curve = (await loadGameDataRegistry(rootBundle)).xpCurve!;

    expect(fillXpPlaceholders('{xpAct1} puis {xpAct2}', curve), '115 puis 200');
    // Une autre courbe, d'autres nombres : la prose ne recopie rien.
    expect(
      fillXpPlaceholders('{xpAct1} puis {xpAct2}', const XpCurveData([70, 90])),
      '70 puis 90',
    );
  });

  test('aucun placeholder ne survit dans l étape XP', () async {
    final data = await loadGameDataRegistry(rootBundle);
    final etape =
        kTutorialSteps.firstWhere((s) => s.type == TutorialStepType.xp);

    for (final corps in [etape.bodyFr, etape.bodyEn]) {
      final rendu = fillXpPlaceholders(
        fillRewardPlaceholders(
          corps,
          data.levelUpRewards,
          isFrench: corps == etape.bodyFr,
        ),
        data.xpCurve!,
      );
      expect(rendu, isNot(contains('{')));
      expect(rendu, contains('115'));
      expect(rendu, contains('200'));
    }
  });
}
