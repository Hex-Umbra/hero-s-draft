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
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les cartes des trois lots de la tranche 2 (Croise, Vampire, Voile), jouees
/// telles que le registre les livre.
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

  EnemyInstance foe() => EnemyInstance(
        data: registry.enemies.first,
        stats: EntityStats(
          maxPv: 100,
          currentPv: 100,
          armure: 0,
          might: 0,
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

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('Riposte : 3 degats et 5 Armure', () {
    startAs('paladin');
    fight([foe()]);

    playShipped('riposte');

    expect(enemy().currentPv, 97);
    expect(hero().armure, 5);
  });

  test('Jugement : 5 a chaque ennemi, 6 Armure une seule fois', () {
    startAs('paladin');
    fight([foe(), foe()]);

    playShipped('judgment');

    expect(enemy(0).currentPv, 95);
    expect(enemy(1).currentPv, 95);
    expect(hero().armure, 6);
  });

  test('Marteau sacre : trois coups de 3 + floor(Puissance x 0,75)', () {
    startAs('paladin', statuses: [might(4)]);
    fight([foe()]);

    playShipped('holy_hammer');

    expect(enemy().currentPv, 100 - 3 * (3 + 3));
  });

  test('Fleau beni : deux coups de 3 + floor(Puissance x 0,75)', () {
    startAs('paladin', statuses: [might(2)]);
    fight([foe()]);

    playShipped('blessed_flail');

    expect(enemy().currentPv, 100 - 2 * (3 + 1));
  });

  test('Frenesie sanglante : 3, +2 par carte jouee avant elle ce tour', () {
    startAs('berserker');
    fight([foe()]);

    playShipped('blood_frenzy');
    expect(enemy().currentPv, 97);

    // `resolveCard` ne compte pas son propre jeu : trois cartes jouees avant.
    for (var i = 0; i < 3; i++) {
      combat.state = combat.currentState.recordCardPlayed();
    }
    playShipped('blood_frenzy');
    expect(enemy().currentPv, 97 - (3 + 2 * 3));
  });

  test('Cataclysme : 8 a chaque ennemi, plus la Puissance du Mage', () {
    startAs('mage', statuses: [might(2)]);
    fight([foe(), foe()]);

    playShipped('cataclysm');

    expect(enemy(0).currentPv, 90);
    expect(enemy(1).currentPv, 90);
  });

  test('Meditation : +1 Mana au debut des deux tours suivants, puis rien', () {
    startAs('mage');
    fight([foe()]);

    playShipped('meditation');
    final manaAtTurnStart = <int>[];
    for (var i = 0; i < 3; i++) {
      run.startTurn();
      manaAtTurnStart.add(hero().currentMana);
    }

    expect(manaAtTurnStart, [4, 4, 3]);
  });
}
