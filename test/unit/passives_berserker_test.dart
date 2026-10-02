import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
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
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Berserker (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const berserker = HeroData(
    id: 'berserker',
    classCard: 'berserker.png',
    maxHp: 80,
    maxMana: 3,
  );

  PassiveData rage({int value = 1}) => PassiveData(
        id: 'rage',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'rage',
        value: value,
        duration: 1,
      );

  PassiveData bloodthirst({int value = 1}) => PassiveData(
        id: 'bloodthirst',
        trigger: RelicTrigger.onAttackPlayed,
        effectType: 'bloodthirst',
        value: value,
        duration: 2,
      );

  PassiveData frenzy({int value = 2, int draw = 1}) => PassiveData(
        id: 'frenzy',
        trigger: RelicTrigger.onEnemyKilled,
        effectType: 'frenzy',
        value: value,
        duration: 1,
        draw: draw,
      );

  final slime = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: 'Slime',
    maxHp: 40,
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

  EntityStats stats() => run.currentState.heroStats;

  int temporaryMight() {
    var total = 0;
    for (final status in stats().statuses) {
      if (status.id == 'might') total += status.value;
    }
    return total;
  }

  String seedEnemy({int hp = 40}) {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 40, currentPv: hp, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
    return enemy.id;
  }

  CardInstance attack(int damage) => CardInstance(
        data: CardData(
          id: 'test_attack',
          cost: 0,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [CardEffect(type: 'damage', value: damage)],
        ),
      );

  group('Rage', () {
    // Le defaut releve au diagnostic (§I.3.2) : le passif ne doit plus etre
    // muet a pleine vie.
    test('a pleine vie, le plancher tient', () {
      run.startNewRun(berserker, rage());
      run.startTurn();
      expect(temporaryMight(), 1);
    });

    test('la Puissance monte par tranche de 10 PV manquants', () {
      run.startNewRun(berserker, rage());
      run.takeDamage(30);
      run.startTurn();

      // Le plancher, plus 3 tranches.
      expect(temporaryMight(), 1 + 3);
    });

    test('la Puissance accordee est temporaire, jamais permanente', () {
      run.startNewRun(berserker, rage());
      run.startTurn();

      expect(stats().might, 0);
      final gained = stats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.duration, 1);
      expect(gained.sourceId, 'passive:rage');
    });

    // R3 c de la revue du brainstorm v3 (spec P-43 E0, §4.6) : la Puissance
    // de Rage ne grossit plus l'entree d'une Forme Demoniaque en cours.
    test('Rage ne rejoint pas une Forme Demoniaque, et expire au tic suivant', () {
      run.startNewRun(berserker, rage());
      run.addStatus(
        StatusEffect(
          id: 'might',
          name: 'Puissance',
          type: StatusType.buff,
          value: 2,
          duration: 4,
          sourceId: StatusSource.card('demon_form'),
        ),
      );

      run.startTurn();
      run.startTurn();

      final might = stats().statuses.where((s) => s.id == 'might').toList();
      expect(might, hasLength(2));
      final fromDemon =
          might.singleWhere((s) => s.sourceId == 'card:demon_form');
      expect((fromDemon.value, fromDemon.duration), (2, 2));
      final fromRage = might.singleWhere((s) => s.sourceId == 'passive:rage');
      expect((fromRage.value, fromRage.duration), (1, 1));
      // Avant P-43 E0 : une seule entree, 2 + 1 + 1 = 4.
      expect(temporaryMight(), 2 + 1);
    });
  });

  group('Soif de Sang', () {
    test('jouer une Attaque arme le Vol de vie', () {
      run.startNewRun(berserker, bloodthirst());
      seedEnemy();
      combat.applyPlayerCardPlay(attack(5));

      final buff = stats().statuses.singleWhere((s) => s.id == 'lifesteal');
      expect(buff.value, 1, reason: 'a pleine vie, la valeur de base');
      expect(buff.duration, 2);
    });

    test('la valeur monte a mesure que les PV baissent', () {
      run.startNewRun(berserker, bloodthirst());
      run.takeDamage(40); // la moitie des PV
      seedEnemy();
      combat.applyPlayerCardPlay(attack(5));

      // 50 % de PV manquants, un quart par point : 1 + 2.
      expect(
        stats().statuses.singleWhere((s) => s.id == 'lifesteal').value,
        3,
      );
    });

    // Le statut arme le soin ; c'est la resolution des degats qui le paie
    // (spec §1.2). La premiere Attaque arme, les suivantes drainent.
    test('l Attaque suivante soigne des degats infliges', () {
      run.startNewRun(berserker, bloodthirst());
      run.takeDamage(20);
      seedEnemy();

      combat.applyPlayerCardPlay(attack(5));
      expect(stats().currentPv, 60, reason: 'la premiere arme seulement');

      // 25 % de PV manquants : le statut vaut 2, et les degats infliges (5)
      // ne le plafonnent pas.
      combat.applyPlayerCardPlay(attack(5));
      expect(stats().currentPv, 60 + 2);
    });

    test('le soin ne depasse jamais les degats infliges', () {
      run.startNewRun(berserker, bloodthirst(value: 9));
      run.takeDamage(20);
      seedEnemy();

      combat.applyPlayerCardPlay(attack(1));
      combat.applyPlayerCardPlay(attack(1));

      expect(stats().currentPv, 60 + 1);
    });
  });

  group('Frenesie', () {
    test('un ennemi abattu donne de la Puissance et fait piocher', () {
      run.startNewRun(berserker, frenzy());

      // Une pioche garnie et une main vide : la carte que le passif tire est
      // la seule qui puisse arriver en main.
      final deck = container.read(deckProvider.notifier);
      deck.initializeStarterDeck([attack(1), attack(1), attack(1)]);
      deck.startCombat(handSize: 0, maxHandSize: 10);
      expect(container.read(deckProvider).hand, isEmpty);

      seedEnemy(hp: 1);
      combat.applyPlayerCardPlay(attack(5));

      expect(combat.currentState.enemies, isEmpty);
      expect(temporaryMight(), 2);
      expect(
        stats().statuses.singleWhere((s) => s.id == 'might').sourceId,
        'passive:frenzy',
      );
      expect(container.read(deckProvider).hand, hasLength(1));
    });
  });

  group('le catalogue', () {
    test('le Berserker garde Rage en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'berserker');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['rage', 'bloodthirst', 'frenzy']);
    });

    test('berserker_armor n existe plus, ni en donnee ni en strategie', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      expect(
        registry.passives.map((p) => p.id),
        isNot(contains('berserker_armor')),
      );
    });
  });
}
