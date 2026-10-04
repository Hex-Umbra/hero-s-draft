import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// *Affinité* n'est pas tirée quand le passif actif ne déclare pas de Maîtrise
/// (spec P-41, §8.2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<LevelUpRewardData> rewards;

  setUpAll(() async {
    rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
  });

  PassiveData passif({PassiveMastery? mastery}) => PassiveData(
        id: 'ward',
        nameEn: 'Ward',
        nameFr: 'Garde',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'gain_armor',
        value: 2,
        mastery: mastery,
      );

  const bloc = PassiveMastery(
    field: 'value',
    perPoint: 1,
    descriptionEn: '+{amount} Block at end of turn',
    descriptionFr: '+{amount} Armure en fin de tour',
  );

  Set<String> tirees({PassiveData? activePassive}) {
    final vues = <String>{};
    for (var i = 0; i < 2000; i++) {
      for (final choix in LevelUpRewardService.generateChoices(
        rewards: rewards,
        luck: 0,
        activePassive: activePassive,
      )) {
        if (choix.data.pool == RewardPool.draft) vues.add(choix.data.id);
      }
    }
    return vues;
  }

  test('affinity.json déclare son exigence', () {
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');
    expect(affinity.requires, RewardRequirement.passiveMastery);
  });

  test('hors d Affinite et de Transcendance, aucune récompense n exige quoi '
      'que ce soit', () {
    for (final reward in rewards
        .where((r) => r.id != 'affinity' && r.id != 'transcendence')) {
      expect(reward.requires, isNull, reason: reward.id);
    }
  });

  // Transcendance (spec P-43 E3, §4.8 ; A15) : tirée seulement si une rune du
  // deck est à son plafond effectif.
  test('transcendence.json declare son exigence', () {
    final transcendence = rewards.firstWhere((r) => r.id == 'transcendence');
    expect(transcendence.requires, RewardRequirement.raisableRune);
    expect(transcendence.effect, RewardEffect.raiseRuneCap);
    expect(transcendence.pool, RewardPool.mythic);
  });

  test('isAvailableWith : Transcendance suit le fait de la rune, Affinite '
      'n en depend pas', () {
    final transcendence = rewards.firstWhere((r) => r.id == 'transcendence');
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');

    expect(transcendence.isAvailableWith(null), isFalse);
    expect(transcendence.isAvailableWith(null, hasRaisableRune: true), isTrue);
    expect(affinity.isAvailableWith(passif(mastery: bloc)), isTrue);
    expect(affinity.isAvailableWith(passif(), hasRaisableRune: true), isFalse);
  });

  test('generateChoices sous forceLegendary sort Transcendance avec une rune '
      'a relever, jamais sans', () {
    List<String> mythicsOf({required bool hasRaisableRune}) => [
          for (final choice in LevelUpRewardService.generateChoices(
            rewards: rewards,
            luck: 0,
            forceLegendary: true,
            hasRaisableRune: hasRaisableRune,
          ).skip(3))
            choice.data.id,
        ];

    expect(mythicsOf(hasRaisableRune: true),
        ['wisdom', 'lucky_clover', 'mirror', 'transcendence']);
    expect(mythicsOf(hasRaisableRune: false),
        ['wisdom', 'lucky_clover', 'mirror']);
  });

  test('un passif avec Maitrise laisse les cinq types tirables', () {
    expect(
      tirees(activePassive: passif(mastery: bloc)),
      {'vitality', 'sharpening', 'affinity', 'precision', 'ferocity'},
    );
  });

  test('un passif sans Maitrise retire l Affinite de la table', () {
    final vues = tirees(activePassive: passif());
    expect(vues, isNot(contains('affinity')));
    // Les quatre autres restent : la table rétrécit, elle ne se vide pas.
    expect(
      vues,
      {'vitality', 'sharpening', 'precision', 'ferocity'},
    );
  });

  test('sans passif actif du tout, l Affinite n est pas tiree non plus', () {
    // Une récompense de Maîtrise sans passif est tout aussi inerte : c'est le
    // même cas (décision 2 du plan).
    expect(tirees(), isNot(contains('affinity')));
  });

  test('l exigence se lit sans passer par le tirage', () {
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');
    final vitality = rewards.firstWhere((r) => r.id == 'vitality');

    expect(affinity.isAvailableWith(passif(mastery: bloc)), isTrue);
    expect(affinity.isAvailableWith(passif()), isFalse);
    expect(affinity.isAvailableWith(null), isFalse);
    // Une récompense sans exigence est toujours disponible.
    expect(vitality.isAvailableWith(null), isTrue);
  });
}
