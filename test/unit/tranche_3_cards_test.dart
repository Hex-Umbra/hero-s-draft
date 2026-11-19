import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'enemy_phase_helper.dart';

/// Les cartes des trois lots de la tranche 3 (Sanctifie, Carnage, Marque),
/// jouees telles que le registre les livre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  late ProviderContainer container;
  late RunController run;
  late CombatController combat;
  late DeckNotifier deck;
  late String enemyId;

  // `setUpAll` : `GameDataRegistry` ecrit un singleton statique.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  EnemyInstance foe({int hp = 100, int might = 0}) => EnemyInstance(
        data: registry.enemies.first,
        stats: EntityStats(
          maxPv: 100,
          currentPv: hp,
          armure: 0,
          might: might,
        ),
      );

  void fight(List<EnemyInstance> enemies) {
    enemyId = enemies.first.id;
    combat.state = CombatState(
      enemies: enemies,
      selectedEnemyId: enemyId,
      turnPhase: TurnPhase.player,
    );
  }

  EntityStats hero() => run.currentState.heroStats;
  EntityStats enemy([int index = 0]) => combat.currentState.enemies[index].stats;

  void setHero(EntityStats Function(EntityStats) change) => run.updateState(
      run.currentState.copyWith(heroStats: change(hero())));

  /// Un nouveau run sous la classe [heroId], sans passif, sans critique.
  void startAs(String heroId, {List<StatusEffect> statuses = const []}) {
    run.startNewRun(registry.heroes.singleWhere((h) => h.id == heroId));
    setHero((h) => h.copyWith(critChance: 0, statuses: statuses));
  }

  void playShipped(String id) {
    setHero((h) => h.copyWith(currentMana: 9));
    final played = EffectResolver.resolveCard(
      CardInstance(data: registry.cards.singleWhere((c) => c.id == id)),
      run,
      deck,
      combat,
      enemyId,
      container.read(effectRegistryProvider),
    );
    expect(played, isTrue);
  }

  StatusEffect might(int value) => StatusEffect(
        id: 'might',
        name: 'might',
        type: StatusType.buff,
        value: value,
        duration: 2,
      );

  StatusEffect vulnerable(int value) => StatusEffect(
        id: 'vulnerable',
        name: 'vulnerable',
        type: StatusType.debuff,
        value: value,
        duration: 2,
      );

  StatusEffect statusOn(EntityStats stats, String id) =>
      stats.statuses.singleWhere((s) => s.id == id);

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('Execution : 4, +1 par tranche de 5 PV manquants de la cible', () {
    startAs('berserker');
    fight([foe(hp: 80)]);
    playShipped('execution');
    expect(enemy().currentPv, 72);

    fight([foe()]);
    playShipped('execution');
    expect(enemy().currentPv, 96);
  });

  test('Exploitation : 4, +1 par point de Vulnerable de la cible', () {
    final lost = <int>[];
    for (final points in [0, 2, 6]) {
      startAs('mage');
      fight([
        foe().copyWith(
          stats: foe().stats.copyWith(statuses: [
            if (points > 0) vulnerable(points),
          ]),
        ),
      ]);
      playShipped('exploit');
      lost.add(100 - enemy().currentPv);
    }

    // 4, puis 6 x 1,5, puis 10 x 2 (le plafond du bareme).
    expect(lost, [4, 9, 20]);
  });

  test('Salve : trois coups de 2 + floor(Puissance x 0,5)', () {
    startAs('mage', statuses: [might(3)]);
    fight([foe()]);

    playShipped('volley');

    expect(enemy().currentPv, 100 - 3 * (2 + 1));
  });

  test('Moulinet : 7 a chaque ennemi vivant, plus la Puissance du Berserker',
      () {
    startAs('berserker', statuses: [might(2)]);
    fight([foe(), foe()]);

    playShipped('windmill');

    expect(enemy(0).currentPv, 91);
    expect(enemy(1).currentPv, 91);
  });

  test(
      'Coup de grace : 10 a chaque ennemi vivant, plus la Puissance du '
      'Berserker', () {
    startAs('berserker', statuses: [might(2)]);
    fight([foe(), foe()]);

    playShipped('coup_de_grace');

    expect(enemy(0).currentPv, 88);
    expect(enemy(1).currentPv, 88);
  });

  test('Tourbillon : 2 a chaque ennemi et pioche 1 carte', () {
    startAs('berserker');
    fight([foe(), foe()]);
    final strike = CardInstance(
      data: registry.cards.singleWhere((c) => c.id == 'strike_basic'),
    );
    deck.initializeStarterDeck([strike, strike, strike]);
    deck.startCombat(
        handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);
    expect(container.read(deckProvider).hand, isEmpty);

    playShipped('whirlwind');

    expect(enemy(0).currentPv, 98);
    expect(enemy(1).currentPv, 98);
    expect(container.read(deckProvider).hand, hasLength(1));
  });

  test('Edit : 2 Faiblesse pendant 2 tours a chaque ennemi', () {
    startAs('paladin');
    fight([foe(), foe()]);

    playShipped('edict');

    for (var i = 0; i < 2; i++) {
      final weakness = statusOn(enemy(i), 'weakness');
      expect((weakness.value, weakness.duration), (2, 2));
    }
  });

  test(
      'Reprimande : 4 Armure au heros, la Puissance du Paladin sur la '
      'Faiblesse seule', () {
    startAs('paladin', statuses: [might(1)]);
    fight([foe()]);

    playShipped('rebuke');

    expect(hero().armure, 4);
    final weakness = statusOn(enemy(), 'weakness');
    expect((weakness.value, weakness.duration), (2, 2));
  });

  test('Priere : Source de Vie 2 pendant 3 tours sur le heros', () {
    startAs('paladin');
    fight([foe()]);

    playShipped('prayer');

    final regen = statusOn(hero(), 'hp_regen');
    expect((regen.value, regen.duration), (2, 3));
    expect(regen.type, StatusType.buff);
    expect(enemy().statuses, isEmpty);
  });

  test(
      'Sommation : la Faiblesse reduit les deux attaques suivantes de la '
      'cible, pas la troisieme (A19)', () {
    startAs('paladin');
    final attacker = foe(might: registry.enemies.first.baseDamage);
    fight([attacker]);
    playShipped('summons');

    final lost = <int>[];
    for (var i = 0; i < 3; i++) {
      combat.state = combat.currentState.copyWith(
        enemies: [
          combat.currentState.enemies.single.copyWith(
            currentIntent: EnemyIntent(type: IntentType.attack, value: 8),
          ),
        ],
      );
      final before = hero().currentPv;
      runEnemyPhaseStart(combat);
      combat.resolveEnemyIntent(attacker.id);
      combat.endEnemyTurn();
      run.startTurn();
      lost.add(before - hero().currentPv);
    }

    expect(lost, [6, 6, 8]);
  });
}
