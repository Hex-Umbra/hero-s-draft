import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_labels.dart';

/// Affinité se décrit par le passif actif (spec P-49, §6.5).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  const affinity = DraftChoice(
    type: LevelUpRewardType.affinity,
    masteryBoost: 2,
  );

  PassiveData regen({int perPoint = 1}) => PassiveData(
        id: 'regen_armor',
        nameEn: 'Armor Regeneration',
        nameFr: "Régénération d'Armure",
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: perPoint,
          descriptionEn: '+{amount} Block at end of turn',
          descriptionFr: '+{amount} Armure en fin de tour',
        ),
      );

  test('le titre', () {
    expect(DraftChoiceLabels.getChoiceTitle(fr, affinity), 'Affinité');
    expect(DraftChoiceLabels.getChoiceTitle(en, affinity), 'Affinity');
  });

  test('la description : le passif actif et l effet de la Maitrise tiree', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity, passive: regen()),
      "Régénération d'Armure : +2 Armure en fin de tour",
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: regen()),
      'Armor Regeneration: +2 Block at end of turn',
    );
  });

  test('perPoint multiplie la valeur tiree', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(
        fr,
        affinity,
        passive: regen(perPoint: 2),
      ),
      "Régénération d'Armure : +4 Armure en fin de tour",
    );
  });

  test('sans passif, ou avec un passif sans mastery : sans effet', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity),
      '+2 Maîtrise, sans effet sur votre passif',
    );
    const bare = PassiveData(
      id: 'bare',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 1,
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: bare),
      '+2 Mastery, no effect on your passive',
    );
  });

  test('les autres recompenses ignorent le passif', () {
    const vitality = DraftChoice(type: LevelUpRewardType.vitality, pvBoost: 5);
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, vitality, passive: regen()),
      DraftChoiceLabels.getChoiceDescription(fr, vitality),
    );
  });
}
