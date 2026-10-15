import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_counters.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le jeu d'une signature (spec P-43 E4, §4.2 à §4.4) — tâche à risque.
///
/// Les signatures sont les vraies, lues du bundle. Le héros est neutre — ni
/// critique ni Maîtrise — pour que chaque compte soit exact.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;
  late DeckNotifier deck;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
  });
  tearDown(() => container.dispose());

  EntityStats hero() => run.currentState.heroStats;
  EnemyInstance enemy() => combat.currentState.enemies.single;
  SignatureInstance signature(String id) =>
      run.currentState.signatures.singleWhere((s) => s.data.id == id);
  SignatureData shipped(String id) =>
      registry.signatures.singleWhere((s) => s.id == id);
  PassiveData passive(String id) =>
      registry.passives.singleWhere((p) => p.id == id);

  /// Une run de [classId] avec les vraies signatures de la classe (ou
  /// [signatures]), un deck de dix Frappes dont cinq en main, et un combat
  /// contre un Slime de 200 PV que personne ne cible encore.
  void start(
    String classId, {
    PassiveData? withPassive,
    List<SignatureData>? signatures,
  }) {
    run.startNewRun(
      HeroData(id: classId, classCard: '$classId.png', maxHp: 100, maxMana: 3),
      withPassive,
      signatures ??
          registry.heroes
              .singleWhere((h) => h.id == classId)
              .getSignatures(registry),
    );
    final strike = registry.cards.singleWhere((c) => c.id == 'strike_basic');
    deck.initializeStarterDeck(
        [for (var i = 0; i < 10; i++) CardInstance(data: strike)]);
    deck.startCombat(
        handSize: 5, maxHandSize: GameConstants.startingMaxHandSize);
    combat.updateState(CombatState(
      enemies: [
        EnemyInstance(
          data: registry.enemies.singleWhere((e) => e.id == 'slime'),
          stats: EntityStats(maxPv: 200, currentPv: 200, armure: 0, might: 0),
        ),
      ],
      turnPhase: TurnPhase.player,
    ));
  }

  /// Le tour ennemi puis l'ouverture du tour joueur suivant : `turnCount`
  /// monte d'un, le mana revient au maximum, l'armure à zéro.
  void nextTurn() {
    combat.startEnemyTurn();
    combat.endEnemyTurn();
    run.startTurn();
  }

  group('le jeu', () {
    test('paie le cout, resout, et met la signature en recharge', () {
      start('paladin');
      final target = enemy().id;

      expect(combat.playSignature(signature('smite'), enemyId: target), isTrue);

      expect(hero().currentMana, 3 - 1);
      expect(enemy().stats.currentPv, 200 - 6);
      expect(hero().armure, 4);
      expect(combat.currentState.selectedEnemyId, target);
      expect(combat.currentState.signatureTurnsLeft('smite'), 2);
      expect(combat.currentState.isSignatureReady('smite'), isFalse);
    });

    test('recharge 2 : refusee au meme tour, encore au suivant, prete au '
        'troisieme', () {
      start('paladin');
      final smite = signature('smite');
      expect(combat.playSignature(smite, enemyId: enemy().id), isTrue);

      expect(combat.playSignature(smite, enemyId: enemy().id), isFalse);
      nextTurn();
      expect(combat.currentState.signatureTurnsLeft('smite'), 1);
      expect(combat.playSignature(smite, enemyId: enemy().id), isFalse);
      nextTurn();
      expect(combat.currentState.isSignatureReady('smite'), isTrue);
      expect(combat.playSignature(smite, enemyId: enemy().id), isTrue);
    });

    test('recharge 1 : refusee au meme tour, prete au suivant', () {
      const quick = SignatureData(
        id: 'eclair_test',
        heroClass: 'paladin',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        cost: 0,
        cooldown: 1,
        type: CardType.skill,
        target: CardTarget.self,
        effects: [CardEffect(type: 'armor', value: 1)],
      );
      start('paladin', signatures: const [quick]);
      final eclair = signature('eclair_test');

      expect(combat.playSignature(eclair), isTrue);
      expect(combat.currentState.signatureTurnsLeft('eclair_test'), 1);
      expect(combat.playSignature(eclair), isFalse);
      nextTurn();
      expect(combat.playSignature(eclair), isTrue);
    });

    test('un initializeCombat neuf rend toutes les signatures pretes', () {
      start('paladin');
      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.currentState.isSignatureReady('holy_shield'), isFalse);

      combat.initializeCombat(1, MapNodeType.combat, registry.enemies);

      expect(combat.currentState.turnCount, 1);
      expect(combat.currentState.signaturesReadyOn, isEmpty);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });
  });

  group('les refus, sans effet', () {
    test('mana insuffisant : ni le mana, ni la recharge, ni la selection ne '
        'bougent', () {
      start('berserker');
      run.updateState(run.currentState
          .copyWith(heroStats: hero().copyWith(currentMana: 1)));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isFalse,
      );

      expect(hero().currentMana, 1);
      expect(enemy().stats.currentPv, 200);
      expect(combat.currentState.isSignatureReady('reckless_strike'), isTrue);
      expect(combat.currentState.selectedEnemyId, isNull);
    });

    test('cible unique sans enemyId : refusee malgre une selection restante',
        () {
      start('paladin');
      combat.selectEnemy(enemy().id); // laissee par une carte precedente

      expect(combat.playSignature(signature('smite')), isFalse);

      expect(hero().currentMana, 3);
      expect(enemy().stats.currentPv, 200);
      expect(combat.currentState.isSignatureReady('smite'), isTrue);
    });

    test('refusee au tour ennemi', () {
      start('paladin');
      combat.startEnemyTurn();

      expect(combat.playSignature(signature('holy_shield')), isFalse);

      expect(hero().armure, 0);
      expect(hero().currentMana, 3);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });

    test('refusee une fois le combat fini', () {
      start('paladin');
      combat.updateState(combat.currentState.copyWith(isCombatEnded: true));

      expect(combat.playSignature(signature('holy_shield')), isFalse);

      expect(hero().currentMana, 3);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });

    test('une signature hors de la run est refusee', () {
      start('paladin');

      expect(
        combat.playSignature(SignatureInstance(shipped('mana_surge'))),
        isFalse,
      );

      expect(hero().currentMana, 3);
    });
  });

  group('hors des piles', () {
    test('main, pioche, defausse, epuisement et deck identiques', () {
      start('paladin');
      final before = container.read(deckProvider);

      expect(combat.playSignature(signature('holy_shield')), isTrue);

      final after = container.read(deckProvider);
      expect(after.hand, before.hand);
      expect(after.drawPile, before.drawPile);
      expect(after.discardPile, before.discardPile);
      expect(after.exhaustPile, before.exhaustPile);
      expect(after.masterDeck, before.masterDeck);
    });

    test('holy_shield et mana_surge ne s epuisent plus : rejouables a T+2',
        () {
      start('paladin',
          signatures: [shipped('holy_shield'), shipped('mana_surge')]);

      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.playSignature(signature('mana_surge')), isTrue);
      expect(container.read(deckProvider).exhaustPile, isEmpty);

      nextTurn();
      nextTurn();

      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.playSignature(signature('mana_surge')), isTrue);
      expect(container.read(deckProvider).exhaustPile, isEmpty);
    });
  });

  group('ce qui ecoute une carte jouee', () {
    test('reckless_strike arme Soif de Sang', () {
      start('berserker', withPassive: passive('bloodthirst'));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isTrue,
      );

      expect(hero().statuses.any((s) => s.id == 'lifesteal'), isTrue);
    });

    test('magic_missile, Competence depuis D28, fait monter Flux de Mana', () {
      final flux = passive('mana_flux');
      start('mage', withPassive: flux);

      expect(
        combat.playSignature(signature('magic_missile'), enemyId: enemy().id),
        isTrue,
      );

      expect(PassiveCounters.valueOf(run, flux), 1);
    });

    test('magic_missile ne pose pas Vulnerable sous Marque du Mage', () {
      start('mage', withPassive: passive('mage_mark'));

      expect(
        combat.playSignature(signature('magic_missile'), enemyId: enemy().id),
        isTrue,
      );

      expect(
          enemy().stats.statuses.any((s) => s.id == 'vulnerable'), isFalse);
    });

    test('l Amulette du Mage voit une signature jouee (Q-P1)', () {
      start('paladin');
      container.read(inventoryProvider.notifier).addRelic(
          registry.relics.singleWhere((r) => r.id == 'mage_amulet'));

      expect(combat.playSignature(signature('holy_shield')), isTrue);

      expect(hero().armure, 8 + 1);
    });

    test('le Shuriken compte reckless_strike comme une Attaque (Q-P1)', () {
      start('berserker');
      container.read(inventoryProvider.notifier).addRelic(
          registry.relics.singleWhere((r) => r.id == 'shuriken'));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isTrue,
      );

      expect(
        hero().statuses.singleWhere((s) => s.id == 'shuriken_charge').value,
        1,
      );
    });
  });
}
