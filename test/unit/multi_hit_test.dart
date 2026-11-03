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

import 'shipped_data.dart';

/// Refuse un chargement en nommant [key] (spec P-44 lot 1, §3.1).
Matcher _refuses(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

CardData _card(List<CardEffect> effects, {CardRarity rarity = CardRarity.common}) =>
    CardData(
      id: 'test',
      cost: 1,
      type: CardType.attack,
      rarity: rarity,
      target: CardTarget.singleEnemy,
      effects: effects,
    );

void main() {
  group('chargement', () {
    test('hits et mightRatio absents valent 1', () {
      final effect = CardEffect.fromJson({'type': 'damage', 'value': 3});
      expect(effect.hits, 1);
      expect(effect.mightRatio, 1.0);
      expect(effect.scaleWith, isNull);
    });

    test('hits sous 1 ou non entier est refuse, nomme', () {
      for (final hits in [0, 1.5]) {
        expect(
          () => CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'hits': hits}),
          _refuses('hits'),
        );
      }
    });

    test('mightRatio hors de ]0, 1] est refuse, nomme', () {
      for (final ratio in [0, -0.5, 1.5]) {
        expect(
          () => CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'mightRatio': ratio}),
          _refuses('mightRatio'),
        );
      }
      for (final ratio in [1, 0.5]) {
        expect(
          CardEffect.fromJson(
              {'type': 'damage', 'value': 3, 'mightRatio': ratio}).mightRatio,
          ratio.toDouble(),
        );
      }
    });

    test('hits et mightRatio sur un effet autre que damage sont refuses', () {
      expect(
        () => CardEffect.fromJson({'type': 'armor', 'value': 2, 'hits': 2}),
        _refuses('hits'),
      );
      expect(
        () => CardEffect.fromJson(
            {'type': 'heal', 'value': 2, 'mightRatio': 0.5}),
        _refuses('mightRatio'),
      );
    });

    test(
        'toJson n ecrit hits et mightRatio que hors de leur defaut ; '
        'l aller-retour les garde', () {
      final plain = CardEffect.fromJson({'type': 'damage', 'value': 3});
      expect(plain.toJson().containsKey('hits'), isFalse);
      expect(plain.toJson().containsKey('mightRatio'), isFalse);

      final multi = CardEffect.fromJson(
          {'type': 'damage', 'value': 3, 'hits': 3, 'mightRatio': 0.5});
      final back = CardEffect.fromJson(multi.toJson());
      expect(back.value, 3);
      expect(back.hits, 3);
      expect(back.mightRatio, 0.5);
    });
  });

  group('la vue jouee', () {
    setUp(() => shippedRuneRegistry(const ['sharp']));

    test(
        'une carte epique garde ses coups, son mightRatio et son scaleWith '
        'par card.effective', () {
      final card = CardInstance(
        data: _card(
          const [
            CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
            CardEffect(
              type: 'armor',
              value: 2,
              scaleWith:
                  ScaleWith(source: ScaleSource.armor, ratio: 0.2),
            ),
          ],
          rarity: CardRarity.epic,
        ),
      );
      final effects = card.effective.effects;
      expect(effects[0].value, 6);
      expect(effects[0].hits, 3);
      expect(effects[0].mightRatio, 0.5);
      expect(effects[1].value, 5);
      expect(effects[1].scaleWith!.source, ScaleSource.armor);
      expect(effects[1].scaleWith!.ratio, 0.2);
    });

    test('A14 : Tranchant 1 sur 3 x 3 donne +1 par coup', () {
      final card = CardInstance(
        data: _card(const [
          CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
        ]),
        forgeUpgrades: const ['sharp:1'],
      );
      final effect = card.effective.effects.single;
      expect(effect.value, 4);
      expect(effect.hits, 3);
    });

    test('A14 : Tranchant 5 sur 3 x 3 donne +3 par coup, pas +5', () {
      final card = CardInstance(
        data: _card(const [
          CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5),
        ]),
        forgeUpgrades: const ['sharp:5'],
      );
      expect(card.effective.effects.single.value, 6);
    });
  });

  group('resolution', () {
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

    EnemyInstance foe({int pv = 100, List<StatusEffect> statuses = const []}) =>
        EnemyInstance(
          data: registry.enemies.first,
          stats: EntityStats(
            maxPv: 100,
            currentPv: pv,
            armure: 0,
            might: 0,
            statuses: statuses,
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

    StatusEffect status(String id, int value) => StatusEffect(
          id: id,
          name: id,
          type: id == 'shock' ? StatusType.debuff : StatusType.buff,
          value: value,
          duration: 2,
        );

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      deck = container.read(deckProvider.notifier);
      // Le Mage oriente sa Puissance vers les Competences.
      run.startNewRun(registry.heroes.singleWhere((h) => h.id == 'mage'));
      fight([foe()]);
    });

    tearDown(() => container.dispose());

    EntityStats hero() => run.currentState.heroStats;
    EntityStats enemy([int index = 0]) =>
        combat.currentState.enemies[index].stats;

    void setHero(EntityStats Function(EntityStats) change) => run.updateState(
        run.currentState.copyWith(heroStats: change(hero())));

    void play(
      List<CardEffect> effects, {
      CardTarget target = CardTarget.singleEnemy,
      List<String> runes = const [],
    }) {
      setHero((h) => h.copyWith(currentMana: 9));
      final played = EffectResolver.resolveCard(
        CardInstance(
          data: CardData(
            id: 'test',
            cost: 1,
            type: CardType.skill,
            rarity: CardRarity.common,
            target: target,
            effects: effects,
          ),
          forgeUpgrades: runes,
        ),
        run,
        deck,
        combat,
        enemyId,
        container.read(effectRegistryProvider),
      );
      expect(played, isTrue);
    }

    const volley = CardEffect(
      type: 'damage',
      value: 3,
      hits: 3,
      mightRatio: 0.5,
    );

    test('la Puissance par coup vaut floor(bonus x mightRatio)', () {
      setHero((h) => h.copyWith(might: 0, statuses: [status('might', 3)]));
      play([volley]);
      expect(enemy().currentPv, 100 - 3 * (3 + 1));
    });

    test('l Electrocution compte a chaque coup', () {
      setHero((h) => h.copyWith(might: 0));
      fight([foe(statuses: [status('shock', 2)])]);
      play([volley]);
      expect(enemy().currentPv, 100 - 15);
    });

    test('le critique se tire a chaque coup', () {
      setHero((h) => h.copyWith(might: 0));
      play([volley], runes: const ['precise:20']);
      expect(enemy().currentPv, 100 - 3 * 5);
    });

    test('une cible unique morte perd les coups restants', () {
      setHero((h) => h.copyWith(
            might: 0,
            maxPv: 100,
            currentPv: 50,
            statuses: [status('lifesteal', 99)],
          ));
      fight([foe(pv: 5)]);
      play([volley]);
      expect(enemy().currentPv, 0);
      expect(hero().currentPv, 56);
    });

    test('allEnemies : chaque coup frappe chaque ennemi vivant, jamais un mort',
        () {
      setHero((h) => h.copyWith(
            might: 0,
            maxPv: 100,
            currentPv: 50,
            statuses: [status('lifesteal', 99)],
          ));
      fight([foe(), foe(pv: 0)]);
      play(
        [const CardEffect(type: 'damage', value: 3, hits: 2, mightRatio: 0.5)],
        target: CardTarget.allEnemies,
      );
      expect(enemy(0).currentPv, 100 - 6);
      expect(enemy(1).currentPv, 0);
      expect(hero().currentPv, 56);
    });
  });
}
