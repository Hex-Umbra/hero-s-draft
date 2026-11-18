import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/charge_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'enemy_phase_helper.dart';
import 'shipped_data.dart';

/// La symétrie héros / ennemis des charges livrées (spec P-53, §4 et §9) :
/// chaque charge est posée par la règle, sur le héros ou sur un ennemi, et le
/// contrôleur la joue.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  final shipped = shippedChargeCatalog();
  final freeze = shipped['freeze']!;
  final burn = shipped['burn']!;
  final shock = shipped['shock']!;

  const brute = EnemyData(
    id: 'brute',
    nameEn: 'Brute',
    nameFr: 'Brute',
    maxHp: 100,
    baseDamage: 10,
    spritePath: '',
  );

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;

  setUp(() {
    container = ProviderContainer(overrides: [shippedChargeOverride()]);
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });
  tearDown(() => container.dispose());

  EntityStats hero() => run.currentState.heroStats;
  EnemyInstance byId(String id) =>
      combat.currentState.enemies.singleWhere((e) => e.id == id);

  /// Une run de Paladin, avec ses vraies signatures.
  void startRun() {
    run.startNewRun(
      HeroData(id: 'paladin', classCard: 'paladin.png', maxHp: 100, maxMana: 3),
      null,
      registry.heroes
          .singleWhere((h) => h.id == 'paladin')
          .getSignatures(registry),
    );
  }

  EnemyInstance foe(String id, {EnemyData? data, int might = 0}) =>
      EnemyInstance(
        id: id,
        data: data ?? brute,
        stats: EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: might),
      );

  void fight(List<EnemyInstance> row, {String? selected}) {
    combat.state = CombatState(
      enemies: row,
      selectedEnemyId: selected,
      turnPhase: TurnPhase.player,
    );
  }

  void poseOnHero(ChargeData charge, int points) => run.updateHeroStats(
        (s) => ChargeRules.pose(s, charge, points, ChargeBearer.hero),
      );

  void poseOnFoe(String id, ChargeData charge, int points) =>
      combat.updateEnemyStats(
        id,
        ChargeRules.pose(byId(id).stats, charge, points, ChargeBearer.enemy),
      );

  void play(CardInstance card) {
    final deck = container.read(deckProvider.notifier);
    deck.initializeStarterDeck([card]);
    deck.startCombat(
        handSize: 0, maxHandSize: GameConstants.startingMaxHandSize);
    deck.state = deck.state.copyWith(hand: [card]);
    combat.applyPlayerCardPlay(card);
  }

  CardInstance strike() => CardInstance(
        data: registry.cards.singleWhere((c) => c.id == 'strike_basic'),
      );

  /// La fin du tour du joueur, la phase ennemie, puis l'ouverture du tour
  /// suivant du joueur.
  void nextHeroTurn() {
    runEnemyPhaseStart(combat);
    combat.endEnemyTurn();
    run.startTurn();
  }

  test('Gel : l ennemi gele perd son action', () {
    startRun();
    final hit = EnemyIntent(type: IntentType.attack, value: 10);
    fight([foe('A', might: 10).copyWith(currentIntent: hit)]);
    poseOnFoe('A', freeze, 3);
    expect(byId('A').skipsAction, isTrue);

    combat.resolveEnemyIntent('A');

    expect(hero().currentPv, 100);
    expect(byId('A').skipsAction, isFalse);
  });

  test(
      'Gel : le heros gele inflige -50 % pendant son prochain tour, chaque '
      'coup compte, et joue cartes et signatures', () {
    startRun();
    fight([foe('A')], selected: 'A');
    poseOnHero(freeze, 5);

    nextHeroTurn();
    play(strike());
    expect(byId('A').stats.currentPv, 100 - 3);

    play(CardInstance(
      data: const CardData(
        id: 'double_test',
        cost: 0,
        type: CardType.attack,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [CardEffect(type: 'damage', value: 4, hits: 2)],
      ),
    ));
    expect(byId('A').stats.currentPv, 100 - 3 - 4);

    final smite = run.currentState.signatures.singleWhere(
      (s) => s.data.id == 'smite',
    );
    expect(combat.playSignature(smite, enemyId: 'A'), isTrue);
    expect(byId('A').stats.currentPv, 100 - 3 - 4 - 3);

    nextHeroTurn();
    final before = byId('A').stats.currentPv;
    play(strike());
    expect(byId('A').stats.currentPv, before - 6);
  });

  test('Gel du heros : les degats de ses statuts ne sont pas reduits', () {
    startRun();
    final frozenHero = ChargeTrack.start(freeze, ChargeBearer.hero)
        .copyWith(state: ChargeState.brokenActive);
    run.updateHeroStats((s) => s.copyWith(charges: {freeze.id: frozenHero}));
    final bearer = foe('A');
    final (row, report) = ChargeRules.fireWave(
      [
        bearer.copyWith(
          stats: ChargeRules.pose(bearer.stats, burn, 3, ChargeBearer.enemy),
        ),
      ],
      bearerIds: null,
      wave: 1,
      charges: shipped,
    );

    expect(report, isNotNull);
    expect(row.single.stats.currentPv, 100 - 12);
    expect(hero().charges[freeze.id]!.state, ChargeState.brokenActive);
  });

  test('Feu du heros : sa part au debut de son tour, sans explosion', () {
    startRun();
    fight([foe('A'), foe('B')]);
    poseOnHero(burn, 5);
    poseOnHero(freeze, 2);

    run.startTurn();

    expect(hero().currentPv, 100 - 16);
    expect(ChargeRules.points(hero(), 'burn'), 0);
    expect(ChargeRules.points(hero(), 'freeze'), 1);
    expect(byId('A').stats.currentPv, 100);
    expect(byId('B').stats.currentPv, 100);
  });

  test('Foudre du heros : les coups ennemis lui font +1 par point', () {
    startRun();
    final hit = EnemyIntent(type: IntentType.attack, value: 10);
    fight([foe('A', might: 10).copyWith(currentIntent: hit)]);
    poseOnHero(shock, 2);

    combat.resolveEnemyIntent('A');

    expect(hero().currentPv, 100 - 12);
  });

  test('Foudre du heros chargee : +2 par point, chaque coup ennemi note', () {
    startRun();
    final hit = EnemyIntent(type: IntentType.attack, value: 10);
    fight([foe('A', might: 10).copyWith(currentIntent: hit)]);
    poseOnHero(shock, 3);

    combat.resolveEnemyIntent('A');

    expect(hero().currentPv, 100 - 16);
    expect(hero().chargeHits, [const ChargeHit(6)]);
  });

  test('Feu : un ennemi entre deux voisins explose', () {
    startRun();
    fight([foe('A'), foe('B'), foe('C')]);
    poseOnFoe('B', burn, 3);

    combat.startEnemyTurn();

    expect(100 - byId('B').stats.currentPv, 12);
    expect([for (final id in ['A', 'C']) 100 - byId(id).stats.currentPv],
        [12, 12]);
    expect([
      for (final id in ['A', 'C']) ChargeRules.points(byId(id).stats, 'burn'),
    ], [1, 1]);

    while (combat.resolveNextFireWave()) {}
    combat.resolveEnemyStatuses();

    expect([for (final id in ['A', 'C']) 100 - byId(id).stats.currentPv],
        [14, 14]);
    expect([
      for (final id in ['A', 'C']) ChargeRules.points(byId(id).stats, 'burn'),
    ], [0, 0]);
  });

  test('Foudre : un ennemi a 2 points prend +1 par point a chaque coup', () {
    startRun();
    fight([foe('A')], selected: 'A');
    poseOnFoe('A', shock, 2);

    play(strike());

    expect(byId('A').stats.currentPv, 100 - 8);
  });
}
