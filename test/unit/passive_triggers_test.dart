import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_counters.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

/// Ce qui déclenche un passif (spec P-41, §6.4) : les déclencheurs que le
/// lot B pose, et les compteurs par tour et par combat.
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  /// Un passif observable : deux points d'armure, quel que soit l'événement.
  PassiveData armorOn(RelicTrigger trigger) => PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: 'gain_armor',
        value: 2,
      );

  final slime = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: 'Slime',
    maxHp: 10,
    baseDamage: 1,
    spritePath: 'slime.png',
    tier: 1,
    intents: [EnemyIntent(type: IntentType.attack, value: 1)],
  );

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  int armor() => run.currentState.heroStats.armure;

  /// Pose un ennemi vivant et le sélectionne.
  String seedEnemy({int hp = 10}) {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 10, currentPv: hp, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
    return enemy.id;
  }

  CardInstance card(CardType type) => CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: const [CardEffect(type: 'damage', value: 1)],
        ),
      );

  group('les declencheurs par type de carte', () {
    test('onAttackPlayed atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onAttackPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 2);
    });

    test('onSkillPlayed atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onSkillPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.skill));
      expect(armor(), 2);
    });

    test('le type d une carte ne declenche pas celui d une autre', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onSkillPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 0);
    });

    // `onCardPlayed` reste servi : c'est le declencheur de P-49.
    test('onCardPlayed reste servi, quel que soit le type', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onCardPlayed));
      seedEnemy();
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(armor(), 2);
    });
  });

  group('onEnemyKilled', () {
    test('atteint le passif', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onEnemyKilled));
      run.onEnemyKilled();
      expect(armor(), 2);
    });
  });

  group('onDamageTaken', () {
    test('se declenche sur ce que l armure a encaisse', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onDamageTaken));
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(armure: 10),
        ),
      );

      run.takeDamage(4);

      // 10 d'armure, 4 encaisses, puis les 2 du passif.
      expect(armor(), 10 - 4 + 2);
      expect(run.currentState.heroStats.currentPv, 100);
    });

    test('sans armure, rien n est encaisse et rien ne se declenche', () {
      run.startNewRun(hero, armorOn(RelicTrigger.onDamageTaken));
      run.takeDamage(4);

      expect(armor(), 0);
      expect(run.currentState.heroStats.currentPv, 100 - 4);
    });
  });

  group('les compteurs', () {
    final counted = armorOn(RelicTrigger.onAttackPlayed);

    test('un compteur de tour disparait au tour suivant', () {
      run.startNewRun(hero);
      expect(
        PassiveCounters.bump(run, counted, scope: CounterScope.turn),
        1,
      );
      expect(
        PassiveCounters.bump(run, counted, scope: CounterScope.turn),
        2,
      );

      run.startTurn();
      expect(PassiveCounters.valueOf(run, counted), 0);
    });

    test('un compteur de combat traverse les tours, et clear le vide', () {
      run.startNewRun(hero);
      PassiveCounters.bump(run, counted, scope: CounterScope.combat);

      run.startTurn();
      expect(PassiveCounters.valueOf(run, counted), 1);

      PassiveCounters.clear(run, counted);
      expect(PassiveCounters.valueOf(run, counted), 0);
    });
  });
}
