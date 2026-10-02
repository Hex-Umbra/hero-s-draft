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
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les runes livrées, jouées sur les vraies cartes par
/// `EffectResolver.resolveCard` (spec P-43 E1, §4.4, §4.8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  late ProviderContainer container;
  late RunController run;
  late CombatController combat;
  late DeckNotifier deck;
  late String enemyId;

  // `setUpAll` : `GameDataRegistry` ecrit un singleton statique, un seul
  // registre par fichier.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  void startAs(String heroId) =>
      run.startNewRun(registry.heroes.singleWhere((h) => h.id == heroId));

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
    // Le Paladin : ni Puissance ni critique au depart, les chiffres sont nets.
    startAs('paladin');
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
  });

  tearDown(() => container.dispose());

  CardInstance card(
    String id, {
    CardRarity? rarity,
    List<String> runes = const [],
  }) =>
      CardInstance(
        data: registry.cards.singleWhere((c) => c.id == id),
        rarity: rarity,
        forgeUpgrades: runes,
      );

  EntityStats hero() => run.currentState.heroStats;
  EntityStats enemy() => combat.currentState.enemies.single.stats;
  List<StatusEffect> enemyStatuses(String id) =>
      enemy().statuses.where((s) => s.id == id).toList();

  void play(CardInstance card) {
    // Assez de mana pour jouer plusieurs cartes dans un meme cas.
    run.updateState(run.currentState
        .copyWith(heroStats: hero().copyWith(currentMana: 9)));
    final played = EffectResolver.resolveCard(
      card,
      run,
      deck,
      combat,
      enemyId,
      container.read(effectRegistryProvider),
    );
    expect(played, isTrue);
  }

  group('Tranchant et Endurci : 15 % de la base par niveau, au moins +1', () {
    test('Tranchant 1 sur une Frappe commune : +1', () {
      play(card('strike_basic', runes: const ['sharp:1']));
      expect(enemy().currentPv, 100 - (6 + 1));
    });

    test('Tranchant 2 sur une Frappe legendaire : +4', () {
      play(card('strike_basic',
          rarity: CardRarity.legendary, runes: const ['sharp:2']));
      expect(enemy().currentPv, 100 - (12 + 4));
    });

    test('Endurci 1 sur une Defense : +1', () {
      play(card('defend_basic', runes: const ['hardened:1']));
      expect(hero().armure, 5 + 1);
    });

    test('Endurci 1 sur un Mur de Fer : +2', () {
      play(card('iron_wall', runes: const ['hardened:1']));
      expect(hero().armure, 10 + 2);
    });
  });

  group('les effets ajoutes passent par le registre de strategies', () {
    test('Veloce pioche une carte', () {
      final waiting = card('defend_basic');
      deck.state = deck.state.copyWith(drawPile: [waiting]);

      play(card('strike_basic', runes: const ['quick:1']));

      expect(deck.state.hand.map((c) => c.uniqueId), [waiting.uniqueId]);
    });

    test('Econome rend un mana', () {
      play(card('strike_basic', runes: const ['eco:1']));
      expect(hero().currentMana, 9 - 1 + 1);
    });
  });

  // Les trois runes neuves, sur les vraies cartes (spec P-43 E2, §4.1, §4.2).
  group('Allege, Precis et Spectral', () {
    test('Allege : la Frappe ne coute plus de mana', () {
      play(card('strike_basic', runes: const ['cheap:1']));
      expect(hero().currentMana, 9);
    });

    test('Precis : le critique de la carte s ajoute a celui du heros', () {
      // 50 % du heros et 50 % de Precis 10 : le coup est critique, x1,5. Vingt
      // coups, pour qu'un fil coupe ne passe pas sur la chance (50 % du heros
      // seul : une chance sur un million de les voir tous critiques).
      run.updateState(run.currentState
          .copyWith(heroStats: hero().copyWith(critChance: 50)));
      for (var i = 0; i < 20; i++) {
        combat.state = combat.currentState.copyWith(enemies: [
          combat.currentState.enemies.single
              .copyWith(stats: enemy().copyWith(currentPv: 100)),
        ]);
        play(card('strike_basic', runes: const ['precise:10']));
        expect(enemy().currentPv, 100 - 9, reason: 'coup ${i + 1}');
      }
    });

    test('Spectral 1 sur une Frappe commune : +40 % de la base, +2', () {
      play(card('strike_basic', runes: const ['spectral:1']));
      expect(enemy().currentPv, 100 - (6 + 2));
    });
  });

  group('les statuts des runes : addStatus, sans source (spec E0, A4)', () {
    test('Coup de Tonnerre et Surcharge, trois fois : 5, 7 puis 9 degats', () {
      // Chaque choc de rune rejoint le choc en cours, que `DamagePipeline`
      // lit : +3 et +5 au lieu de +2 et +3.
      final hp = <int>[];
      for (var i = 0; i < 3; i++) {
        play(card('thunder_clap', runes: const ['shocking:1']));
        hp.add(enemy().currentPv);
      }
      expect(hp, [100 - 5, 100 - 5 - 7, 100 - 5 - 7 - 9]);
      expect(enemyStatuses('shock').map((s) => (s.value, s.sourceId)),
          [(6, null)]);
    });

    test('Brulant 2, joue deux fois : une brulure de 4 pour 2 tours', () {
      for (var i = 0; i < 2; i++) {
        play(card('strike_basic', runes: const ['burning:2']));
      }
      expect(
        enemyStatuses('burn').map((s) => (s.value, s.duration, s.sourceId)),
        [(4, 2, null)],
      );
    });

    test('Congelant, joue deux fois : une seule entree de gel', () {
      for (var i = 0; i < 2; i++) {
        play(card('strike_basic', runes: const ['freezing:1']));
      }
      expect(enemyStatuses('freeze'), hasLength(1));
    });

    test('Boule de Feu et Brulant 1 : une brulure de 3 pour 2 tours', () {
      // La rune pose avant la carte, dont la brulure rejoint la sienne.
      play(card('fireball', runes: const ['burning:1']));
      expect(enemyStatuses('burn').map((s) => (s.value, s.duration)), [(3, 2)]);
    });
  });

  test('G1 : un Coup Empoisonne legendaire inflige 7 degats et pose 5 Poison',
      () {
    play(card('poison_stab', rarity: CardRarity.legendary));
    expect(enemy().currentPv, 100 - 7);
    expect(
      enemyStatuses('poison').map((s) => (s.value, s.duration)),
      [(5, 2)],
    );
  });

  test('le Berserker convertit en une fois l armure de la carte et celle de '
      'la rune', () {
    // Defense (5) et Endurci 1 (+1) : un seul gain de 6, converti a 0,5.
    startAs('berserker');

    play(card('defend_basic', runes: const ['hardened:1']));

    expect(hero().armure, 0);
    expect(
      hero().statuses.where((s) => s.id == 'might').map((s) => s.value),
      [3],
    );
  });
}
