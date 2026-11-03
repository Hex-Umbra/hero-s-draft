import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';

import 'scripted_random.dart';

void main() {
  group('EntityStats & StatusEffect', () {
    test('takeDamage applies to armor first then PV', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 10,
        might: 0,
      );

      stats = stats.takeDamage(15);

      expect(stats.armure, 0);
      expect(stats.currentPv, 95);
    });

    test('addStatus applies buff and tickStatuses reduces duration', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 0,
        might: 0,
      );

      final poison = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 2,
      );

      stats = stats.addStatus(poison);

      expect(stats.statuses.length, 1);
      expect(stats.statuses.first.value, 3);
      expect(stats.statuses.first.duration, 2);

      // Add another poison stack, should merge values
      final poison2 = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 2,
        duration: 3,
      );

      stats = stats.addStatus(poison2);

      expect(stats.statuses.length, 1);
      expect(stats.statuses.first.value, 5); // 3 + 2
      expect(stats.statuses.first.duration, 3); // max(2, 3)

      // Tick statuses reduces duration
      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 2);

      stats = stats.tickStatuses();
      expect(stats.statuses.first.duration, 1);
    });

    test('effectiveMight calculates base + strength', () {
      var stats = EntityStats(
        maxPv: 100,
        currentPv: 100,
        maxMana: 10,
        currentMana: 10,
        armure: 0,
        might: 5,
      );

      expect(stats.effectiveMight, 5);

      final strength = StatusEffect(
        id: 'might',
        name: 'Puissance',
        type: StatusType.buff,
        value: 3,
        duration: 1,
      );

      stats = stats.addStatus(strength);

      expect(stats.effectiveMight, 8); // 5 base + 3 strength
    });

    test('EnemyInstance effectiveIntent scales attack with current stats', () {
      var enemy = EnemyInstance(
        stats: EntityStats(
          maxPv: 20,
          currentPv: 20,
          armure: 0,
          might: 8,
        ),
        data: const EnemyData(
          id: 'test',
          nameEn: 'Test Enemy',
          nameFr: 'Test Ennemi',
          maxHp: 20,
          baseDamage: 8,
          spritePath: '',
        ),
      );

      // Raw intent is attack with value 8
      enemy = enemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
      );
      expect(enemy.effectiveIntent?.value, 8);

      // 1. Permanent/spawn-time scaling: Boost base stats.might to 10 (e.g. from level)
      var scaledEnemy = enemy.copyWith(
        stats: enemy.stats.copyWith(might: 10),
      );
      expect(scaledEnemy.effectiveIntent?.value, 10); // 8 * 1.25 = 10

      // Raw intent with value 12 (special attack) when base stats.might is scaled to 10
      scaledEnemy = scaledEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(scaledEnemy.effectiveIntent?.value, 15); // 12 * 1.25 = 15

      // 2. In-battle strength status: Keep base stats.might at 8, add a +2 strength buff
      var buffedEnemy = enemy.copyWith(
        stats: enemy.stats.addStatus(
          const StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 2,
            duration: 99,
          ),
        ),
      );
      expect(buffedEnemy.stats.effectiveMight, 10);

      // Raw intent with value 12 (special attack) with +2 strength
      buffedEnemy = buffedEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(buffedEnemy.effectiveIntent?.value, 14); // 12 + 2 = 14

      // 3. In-battle strength debuff: Keep base stats.might at 8, add a -2 strength debuff
      var debuffedEnemy = enemy.copyWith(
        stats: enemy.stats.addStatus(
          const StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: -2,
            duration: 99,
          ),
        ),
      );
      expect(debuffedEnemy.stats.effectiveMight, 6);

      // Raw intent with value 12 (special attack) with -2 strength
      debuffedEnemy = debuffedEnemy.copyWith(
        currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
      );
      expect(debuffedEnemy.effectiveIntent?.value, 10); // 12 - 2 = 10
    });

    test(
      'EnemyInstance effectiveIntent scales attack proportionally for Elites with buffs',
      () {
        // Simulate an elite enemy spawned with a multiplier of 2.25
        // JSON baseDamage = 8. Spawns with stats.might = 18.
        var eliteEnemy = EnemyInstance(
          stats: EntityStats(
            maxPv: 50,
            currentPv: 50,
            armure: 0,
            might: 18,
          ),
          data: const EnemyData(
            id: 'orc',
            nameEn: 'Furious Orc',
            nameFr: 'Orc Furieux',
            maxHp: 50,
            baseDamage: 8,
            spritePath: '',
          ),
        );

        // 1st action: Attack 8 in JSON should scale to 18
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
        );
        expect(eliteEnemy.effectiveIntent?.value, 18);

        // 2nd action: Buff 2 in JSON is executed, applying 2 Strength status
        eliteEnemy = eliteEnemy.copyWith(
          stats: eliteEnemy.stats.addStatus(
            const StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: 2,
              duration: 99,
            ),
          ),
        );
        expect(eliteEnemy.stats.effectiveMight, 20);

        // 3rd action: Attack 8 in JSON should now scale to 18 + 2 (inBattleBonus) = 20
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
        );
        expect(eliteEnemy.effectiveIntent?.value, 20);

        // A stronger attack: Attack 10 in JSON should scale to 23 (10 * 2.25) + 2 (inBattleBonus) = 25
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
        );
        expect(eliteEnemy.effectiveIntent?.value, 25);

        // An even stronger attack: Attack 12 in JSON should scale to 27 (12 * 2.25) + 2 (inBattleBonus) = 29
        eliteEnemy = eliteEnemy.copyWith(
          currentIntent: EnemyIntent(type: IntentType.attack, value: 12),
        );
        expect(eliteEnemy.effectiveIntent?.value, 29);
      },
    );

    test('le Gel reduit l intention de 25 % par point, 3 points au plus', () {
      EnemyInstance frozen(int points) => EnemyInstance(
            stats: EntityStats(
              maxPv: 20,
              currentPv: 20,
              armure: 0,
              might: 10,
            ).addStatus(StatusEffect(
              id: 'freeze',
              name: 'Gel',
              type: StatusType.debuff,
              value: points,
              duration: 1,
            )),
            data: const EnemyData(
              id: 'test',
              nameEn: 'Test Enemy',
              nameFr: 'Test Ennemi',
              maxHp: 20,
              baseDamage: 10,
              spritePath: '',
            ),
            currentIntent: EnemyIntent(type: IntentType.attack, value: 10),
          );

      expect(
        [1, 2, 3, 5].map((p) => frozen(p).effectiveIntent?.value),
        [8, 5, 3, 3],
      );
    });
  });

  // La portée de la règle s'écrit dans la fabrique, une fois (spec P-43 E0,
  // A1 et §4.4) : seule la Puissance retient sa source.
  group('EffectResolver.createStatus', () {
    test('la Puissance retient sa source', () {
      final status = EffectResolver.createStatus(
        'might',
        2,
        4,
        sourceId: StatusSource.card('demon_form'),
      )!;

      expect(status.sourceId, 'card:demon_form');
    });

    test('un autre statut est pose sans source', () {
      final status = EffectResolver.createStatus(
        'poison',
        3,
        2,
        sourceId: StatusSource.card('poison_dart'),
      )!;

      expect(status.sourceId, isNull);
    });
  });

  // Un seul bonus de Puissance de statut par resolution : le premier
  // `apply_status`, tous statuts confondus (Q11, A15).
  group('Q11 : un seul bonus de statut par resolution', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late GameDataRegistry registry;
    late ProviderContainer container;
    late RunController run;
    late CombatController combat;
    late DeckNotifier deck;
    late String enemyId;

    setUpAll(() async {
      registry = await loadGameDataRegistry(rootBundle);
    });

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      deck = container.read(deckProvider.notifier);
      run.startNewRun(registry.heroes.singleWhere((h) => h.id == 'mage'));
      final enemy = EnemyInstance(
        data: registry.enemies.first,
        stats: EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0),
      );
      enemyId = enemy.id;
      combat.state = CombatState(
        enemies: [enemy],
        selectedEnemyId: enemyId,
        turnPhase: TurnPhase.player,
      );
      // Puissance temporaire 2, la seule du Mage.
      run.updateState(run.currentState.copyWith(
        heroStats: run.currentState.heroStats.copyWith(
          might: 0,
          currentMana: 9,
          statuses: const [
            StatusEffect(
              id: 'might',
              name: 'Puissance',
              type: StatusType.buff,
              value: 2,
              duration: 2,
            ),
          ],
        ),
      ));
    });

    tearDown(() => container.dispose());

    void play(CardData data,
        {List<String> runes = const [], Random? random}) {
      final played = EffectResolver.resolveCard(
        CardInstance(data: data, forgeUpgrades: runes),
        run,
        deck,
        combat,
        enemyId,
        container.read(effectRegistryProvider),
        random: random,
      );
      expect(played, isTrue);
    }

    CardData shipped(String id) =>
        registry.cards.singleWhere((c) => c.id == id);

    List<StatusEffect> onEnemy(String id) => combat
        .currentState.enemies.single.stats.statuses
        .where((s) => s.id == id)
        .toList();

    test(
        'Boule de Feu et Brulant : la Brulure de la rune recoit la Puissance, '
        'celle de la carte non', () {
      play(shipped('fireball'), runes: const ['burning:1']);

      final burn = onEnemy('burn').single;
      expect(burn.value, 5);
      expect(burn.duration, 2);
    });

    test(
        'Coup de Tonnerre et Brulant : la Brulure de la rune la recoit, '
        'l Electrocution non', () {
      play(shipped('thunder_clap'), runes: const ['burning:1']);

      expect(onEnemy('burn').single.value, 3);
      expect(onEnemy('shock').single.value, 1);
    });

    test('l echo recoit son propre bonus de statut', () {
      play(shipped('poison_stab'),
          runes: const ['echo:7'], random: ScriptedRandom([0]));

      // Deux resolutions de 1 Poison, chacune avec la Puissance 2 : 2 x (1 + 2).
      expect(onEnemy('poison').single.value, 6);
    });

    test('sans rune, le premier statut de la carte recoit le bonus', () {
      play(shipped('poison_stab'));

      expect(onEnemy('poison').single.value, 1 + 2);
    });

    test('une carte sur soi : aucun de ses statuts ne recoit de Puissance',
        () {
      play(const CardData(
        id: 'test',
        cost: 1,
        type: CardType.skill,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [
          CardEffect(
              type: 'apply_status', statusId: 'might', value: 1, duration: 2),
          CardEffect(
              type: 'apply_status',
              statusId: 'armor_regen',
              value: 2,
              duration: 2),
        ],
      ));

      final statuses = run.currentState.heroStats.statuses;
      final fromCard = statuses.where((s) => s.sourceId == 'card:test');
      expect(fromCard.singleWhere((s) => s.id == 'might').value, 1);
      expect(statuses.singleWhere((s) => s.id == 'armor_regen').value, 2);
    });
  });
}
