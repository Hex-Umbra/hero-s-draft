import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/cost_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les coûts combinés (D40 ; spec P-42 T1 et P-44 lot 1, §4.1, A9, A10,
/// A20) : la forme, la règle d'accessibilité, le paiement hors du pipeline,
/// *Transfusion*.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Une carte à `costs` telle qu'un fichier la porte. Elle porte `passive` :
  /// A8 refuse un coût en PV ou en Armure sur une neutre.
  Map<String, dynamic> costed(Object? costs) => {
        'id': 'test_costs',
        'passive': 'rage',
        'type': 'attack',
        'target': 'singleEnemy',
        'effects': [
          {'type': 'damage', 'value': 1},
        ],
        'costs': costs,
      };

  Matcher refused(String key) => throwsA(isA<FormatException>()
      .having((e) => e.message, 'message', contains(key)));

  group('la forme (A9)', () {
    test('cost et costs ensemble sont refuses', () {
      expect(
        () => CardData.fromJson({...costed({'mana': 0, 'hp': 3}), 'cost': 1}),
        refused('"cost" et "costs"'),
      );
    });

    test('A8 : un cout en PV ou en Armure sur une neutre est refuse', () {
      expect(
        () => CardData.fromJson(costed({'mana': 0, 'hp': 3})..remove('passive')),
        refused('passive'),
      );
      expect(
        () => CardData.fromJson(costed({'mana': 0, 'armor': 3})..remove('passive')),
        refused('passive'),
      );
    });

    test('ni cost ni costs : refuse, nomme', () {
      expect(
        () => CardData.fromJson(costed(null)..remove('costs')),
        refused('"cost" ou "costs"'),
      );
    });

    test('costs.mana absent ou negatif est refuse', () {
      expect(() => CardData.fromJson(costed({'hp': 3})), refused('costs.mana'));
      expect(() => CardData.fromJson(costed({'mana': -1, 'hp': 3})),
          refused('costs.mana'));
    });

    test('costs sans hp ni armor est refuse', () {
      expect(() => CardData.fromJson(costed({'mana': 1})),
          refused('sans "hp" ni "armor"'));
    });

    test('costs.discard est refusee, nommee', () {
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 2, 'discard': 1})),
          refused('costs.discard'));
    });

    test('costs.hp ou costs.armor a 0 est refuse', () {
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 0, 'armor': 2})),
          refused('costs.hp'));
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 2, 'armor': 0})),
          refused('costs.armor'));
    });

    test('toJson ecrit costs ou cost, et l aller-retour garde les trois', () {
      final card = CardData.fromJson(costed({'mana': 1, 'hp': 3, 'armor': 2}));
      expect((card.cost, card.hpCost, card.armorCost), (1, 3, 2));
      final json = card.toJson();
      expect(json.containsKey('cost'), isFalse);
      final back = CardData.fromJson(json);
      expect((back.cost, back.hpCost, back.armorCost), (1, 3, 2));

      final manaOnly = costed(null)..remove('costs');
      manaOnly['cost'] = 2;
      final plain = CardData.fromJson(manaOnly);
      expect(plain.toJson()['cost'], 2);
      expect(plain.toJson().containsKey('costs'), isFalse);
    });

    test('une CardInstance a costs survit a l aller-retour de sauvegarde', () {
      final card = CardInstance(
        data: CardData.fromJson(costed({'mana': 0, 'armor': 4})),
        rarity: CardRarity.rare,
      );
      final back = CardInstance.fromJson(card.toJson());
      expect((back.data.cost, back.data.hpCost, back.data.armorCost), (0, 0, 4));
      expect(back.rarity, CardRarity.rare);
    });
  });

  group('le jeu', () {
    late GameDataRegistry registry;
    late ProviderContainer container;
    late RunController run;
    late CombatController combat;
    late String enemyId;

    setUpAll(() async {
      registry = await loadGameDataRegistry(rootBundle);
    });

    void startAs(String heroId, [String? passiveId]) => run.startNewRun(
          registry.heroes.singleWhere((h) => h.id == heroId),
          passiveId == null
              ? null
              : registry.passives.singleWhere((p) => p.id == passiveId),
        );

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
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

    EntityStats hero() => run.currentState.heroStats;

    void setHero({int? mana, int? pv, int? armor}) =>
        run.updateState(run.currentState.copyWith(
          heroStats: hero().copyWith(
            currentMana: mana,
            currentPv: pv,
            armure: armor,
          ),
        ));

    CardInstance card({
      int mana = 0,
      int hp = 0,
      int armor = 0,
      List<CardEffect> effects = const [CardEffect(type: 'damage', value: 1)],
      CardRarity rarity = CardRarity.common,
      List<String> runes = const [],
    }) =>
        CardInstance(
          data: CardData(
            id: 'test_costs',
            cost: mana,
            hpCost: hp,
            armorCost: armor,
            type: CardType.attack,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: effects,
          ),
          rarity: rarity,
          forgeUpgrades: runes,
        );

    bool play(CardInstance card) => EffectResolver.resolveCard(
          card,
          run,
          container.read(deckProvider.notifier),
          combat,
          enemyId,
          container.read(effectRegistryProvider),
        );

    group('canAfford (A10)', () {
      test('PV egaux au cout : refusee ; cout + 1 : acceptee', () {
        setHero(mana: 3, pv: 3);
        expect(EffectResolver.canAfford(card(hp: 3), hero()), isFalse);
        setHero(pv: 4);
        expect(EffectResolver.canAfford(card(hp: 3), hero()), isTrue);
      });

      test('Armure egale au cout : acceptee ; un de moins : refusee', () {
        setHero(mana: 3, armor: 4);
        expect(EffectResolver.canAfford(card(armor: 4), hero()), isTrue);
        setHero(armor: 3);
        expect(EffectResolver.canAfford(card(armor: 4), hero()), isFalse);
      });

      test('missingFor nomme la seule ressource qui manque', () {
        setHero(mana: 3, pv: 4, armor: 2);
        expect(hero().missingFor(mana: 1, hp: 4, armor: 3),
            {CostResource.hp, CostResource.armor});
        expect(hero().missingFor(mana: 4, hp: 3, armor: 2),
            {CostResource.mana});
        expect(hero().missingFor(mana: 3, hp: 3, armor: 2), isEmpty);
      });

      test('le mana d abord : sans mana, refusee malgre PV et Armure', () {
        setHero(mana: 1, pv: 50, armor: 10);
        expect(EffectResolver.canAfford(card(mana: 2, hp: 3, armor: 2), hero()),
            isFalse);
      });

      test('la rarete ne multiplie jamais les couts : une epique a 3 PV coute 3',
          () {
        setHero(mana: 3, pv: 4);
        final epic = card(hp: 3, rarity: CardRarity.epic);
        expect(EffectResolver.canAfford(epic, hero()), isTrue);
        expect(play(epic), isTrue);
        expect(hero().currentPv, 1);
      });
    });

    group('le paiement (§4.1)', () {
      test('une carte refusee n ecrit rien', () {
        setHero(mana: 3, pv: 3, armor: 2);
        var writes = 0;
        container.listen(runProvider, (_, _) => writes++);

        expect(play(card(hp: 3, armor: 1)), isFalse);

        expect(writes, 0);
        expect((hero().currentMana, hero().currentPv, hero().armure), (3, 3, 2));
        expect(combat.currentState.enemies.single.stats.currentPv, 100);
      });

      test('consumeResource debite mana, PV et Armure en une seule ecriture', () {
        setHero(mana: 3, pv: 50, armor: 5);
        var writes = 0;
        container.listen(runProvider, (_, _) => writes++);

        expect(run.consumeResource(mana: 1, hp: 3, armor: 2), isTrue);

        expect(writes, 1);
        expect((hero().currentMana, hero().currentPv, hero().armure), (2, 47, 3));

        // Par resolveCard aussi : une carte sans effet n'ecrit que son
        // paiement.
        writes = 0;
        expect(play(card(mana: 1, hp: 3, armor: 2, effects: const [])), isTrue);
        expect(writes, 1);
        expect((hero().currentMana, hero().currentPv, hero().armure), (1, 44, 1));
      });

      test('PV payes jusqu a 1 : la carte se resout jusqu au bout', () {
        setHero(mana: 3, pv: 4);
        expect(play(card(hp: 3)), isTrue);
        expect(hero().currentPv, 1);
        expect(combat.currentState.enemies.single.stats.currentPv, 99);
      });

      test('aucun onDamageTaken : Ferveur ne monte pas sur l Armure depensee', () {
        startAs('paladin', 'fervor');
        setHero(mana: 3, armor: 6);
        expect(play(card(armor: 4)), isTrue);
        expect(hero().armure, 2);
        expect(hero().statuses.where((s) => s.id == 'might'), isEmpty);
      });

      test('sous Rage, les PV payes comptent dans la Puissance du tour suivant',
          () {
        startAs('berserker', 'rage');
        setHero(mana: 3, pv: 80);
        expect(play(card(hp: 10)), isTrue);
        run.startTurn();
        final might = hero().statuses.where((s) => s.id == 'might');
        expect(might.fold<int>(0, (sum, s) => sum + s.value), 2);
      });

      test('Allege ne touche que le mana', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(mana: 1, hp: 3, rarity: CardRarity.rare,
            runes: const ['cheap:1'])), isTrue);
        expect((hero().currentMana, hero().currentPv), (3, 47));
      });
    });

    group('Transfusion (A20)', () {
      test('rend 2 sur un cout de 3, apres la resolution', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(hp: 3, runes: const ['transfusion:1'])), isTrue);
        expect(hero().currentPv, 49);
      });

      test('jamais au-dela des PV max', () {
        setHero(mana: 3, pv: 99);
        expect(play(card(hp: 3, runes: const ['transfusion:1'], effects: const [
          CardEffect(type: 'heal', value: 5),
        ])), isTrue);
        expect(hero().currentPv, 100);
      });

      test('une seule fois, apres l echo', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(hp: 3, runes: const ['echo:7', 'transfusion:1'])),
            isTrue);
        expect(hero().currentPv, 49);
        expect(combat.currentState.enemies.single.stats.currentPv, 98);
      });
    });
  });
}
