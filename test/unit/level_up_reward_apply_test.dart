import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/level_up_reward_service.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Chaque récompense de niveau monte la stat que sa donnée désigne
/// (spec P-41, §8.1).
///
/// L'ancienne version composait sept accumulateurs dans `DraftScreen` : une
/// stat ajoutée sans être appliquée n'aurait fait rougir personne. Le `switch`
/// exhaustif sur `RewardStat` ne compile plus dans ce cas, et ce fichier
/// vérifie la correspondance stat par stat.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, LevelUpRewardData> byId;

  setUpAll(() async {
    byId = {
      for (final r in (await loadGameDataRegistry(rootBundle)).levelUpRewards)
        r.id: r,
    };
  });

  DraftChoice choice(String id, RewardRarity rarity) {
    final data = byId[id]!;
    return DraftChoice(data: data, rarity: rarity, amount: data.amountFor(rarity));
  }

  const paladin = HeroData(
    id: 'paladin',
    nameFr: 'Le Paladin',
    nameEn: 'Paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  ProviderContainer freshRun() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(runProvider.notifier).startNewRun(paladin);
    return container;
  }

  test('Vitalité monte les PV max et les PV courants', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('vitality', RewardRarity.epic)); // +15

    final apres = container.read(runProvider).heroStats;
    expect(apres.maxPv, avant.maxPv + 15);
    expect(apres.currentPv, avant.currentPv + 15);
  });

  test('Aiguisage monte la Puissance', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.might;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('sharpening', RewardRarity.rare)); // +4

    expect(container.read(runProvider).heroStats.might, avant + 4);
  });

  test('Affinité monte la Maîtrise', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.mastery;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('affinity', RewardRarity.legendary)); // +7

    expect(container.read(runProvider).heroStats.mastery, avant + 7);
  });

  test('Sagesse monte le mana max', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.maxMana;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('wisdom', RewardRarity.legendary)); // +4

    expect(container.read(runProvider).heroStats.maxMana, avant + 4);
  });

  test('Précision monte la chance de critique', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.critChance;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('precision', RewardRarity.epic)); // +4

    expect(container.read(runProvider).heroStats.critChance, avant + 4);
  });

  test('Férocité est en points de pourcentage, divisés par 100', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.critMultiplier;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('ferocity', RewardRarity.rare)); // 30 -> +0,30

    expect(
      container.read(runProvider).heroStats.critMultiplier,
      closeTo(avant + 0.30, 0.0001),
    );
  });

  test('le Trèfle monte la Chance', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.luck;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('lucky_clover', RewardRarity.mythic)); // +1

    expect(container.read(runProvider).heroStats.luck, avant + 1);
  });

  test('le Miroir ne touche aucune stat', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('mirror', RewardRarity.mythic));

    final apres = container.read(runProvider).heroStats;
    expect(apres.maxPv, avant.maxPv);
    expect(apres.might, avant.might);
    expect(apres.mastery, avant.mastery);
    expect(apres.maxMana, avant.maxMana);
    expect(apres.luck, avant.luck);
    expect(apres.critChance, avant.critChance);
    expect(apres.critMultiplier, avant.critMultiplier);
  });
}
