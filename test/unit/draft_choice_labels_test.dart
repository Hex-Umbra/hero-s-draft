import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_labels.dart';

/// Les libellés d'un choix de draft viennent de la donnée (spec P-41, §8.1) ;
/// Affinité se décrit par le passif actif (spec P-49, §6.5).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  late Map<String, LevelUpRewardData> byId;

  setUpAll(() async {
    final registry = await loadGameDataRegistry(rootBundle);
    byId = {for (final r in registry.levelUpRewards) r.id: r};
  });

  DraftChoice choice(String id, RewardRarity rarity) {
    final data = byId[id]!;
    return DraftChoice(data: data, rarity: rarity, amount: data.amountFor(rarity));
  }

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

  test('le titre vient du nom déclaré, dans les deux langues', () {
    final affinity = choice('affinity', RewardRarity.uncommon);
    expect(DraftChoiceLabels.getChoiceTitle(fr, affinity), 'Affinité');
    expect(DraftChoiceLabels.getChoiceTitle(en, affinity), 'Affinity');
  });

  test('la description : le passif actif et l effet de la Maitrise tiree', () {
    final affinity = choice('affinity', RewardRarity.uncommon); // +2
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
    final affinity = choice('affinity', RewardRarity.uncommon); // +2
    expect(
      DraftChoiceLabels.getChoiceDescription(
        fr,
        affinity,
        passive: regen(perPoint: 2),
      ),
      "Régénération d'Armure : +4 Armure en fin de tour",
    );
  });

  test('sans passif actif, le gabarit de repli est rendu', () {
    final affinity = choice('affinity', RewardRarity.rare); // +3
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity),
      '+3 Maîtrise, sans effet sur votre passif',
    );
  });

  test('une récompense de stat rend sa valeur tirée', () {
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, choice('vitality', RewardRarity.epic)),
      '+15 PV Max',
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(en, choice('ferocity', RewardRarity.legendary)),
      '+50% Crit Damage',
    );
  });

  test('aucun libellé rendu ne laisse fuir un placeholder', () {
    for (final reward in byId.values) {
      for (final rarity in RewardRarity.values) {
        final rendu = DraftChoiceLabels.getChoiceDescription(
          fr,
          DraftChoice(
            data: reward,
            rarity: rarity,
            amount: reward.amountFor(rarity),
          ),
          passive: regen(),
        );
        expect(rendu, isNot(contains('{')), reason: '${reward.id} / ${rarity.name}');
      }
    }
  });
}
