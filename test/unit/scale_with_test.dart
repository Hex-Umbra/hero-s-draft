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
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Refuse un chargement en nommant [key] (spec P-44 lot 1, §3.1).
Matcher _refuses(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

Map<String, dynamic> _effect(Map<String, dynamic> scaleWith,
        {String type = 'armor', Map<String, dynamic> extra = const {}}) =>
    {'type': type, 'value': 2, 'scaleWith': scaleWith, ...extra};

Map<String, dynamic> _card(String target, Map<String, dynamic> scaleWith) => {
      'id': 'test',
      'cost': 1,
      'type': 'attack',
      'rarity': 'common',
      'target': target,
      'effects': [_effect(scaleWith, type: 'damage')],
    };

void main() {
  group('chargement', () {
    test('termFor arrondit vers le bas', () {
      int term(double ratio, int quantity) =>
          ScaleWith(source: ScaleSource.armor, ratio: ratio).termFor(quantity);
      expect(term(0.2, 14), 2);
      expect(term(0.1, 30), 3);
      expect(term(0.2, 15), 3);
      expect(term(1, 7), 7);
      expect(term(1.5, 3), 4);
    });

    test('scaleWith se lit : source, ratio, statusId', () {
      final card = CardData.fromJson(_card('singleEnemy', {
        'source': 'targetStatus',
        'ratio': 1,
        'statusId': 'poison',
      }));
      final scale = card.effects.single.scaleWith!;
      expect(scale.source, ScaleSource.targetStatus);
      expect(scale.ratio, 1.0);
      expect(scale.statusId, 'poison');
    });

    test('ratio 0,3 est refuse ; 0,2, 0,1, 1 et 1,5 sont acceptes', () {
      expect(
        () => CardEffect.fromJson(
            _effect({'source': 'armor', 'ratio': 0.3})),
        _refuses('ratio'),
      );
      for (final ratio in [0.2, 0.1, 1, 1.5]) {
        expect(
          CardEffect.fromJson(_effect({'source': 'armor', 'ratio': ratio}))
              .scaleWith!
              .ratio,
          ratio.toDouble(),
        );
      }
    });

    test('ratio nul ou negatif est refuse', () {
      for (final ratio in [0, -1]) {
        expect(
          () => CardEffect.fromJson(
              _effect({'source': 'armor', 'ratio': ratio})),
          _refuses('ratio'),
        );
      }
    });

    test('source inconnue est refusee, nommee', () {
      expect(
        () => CardEffect.fromJson(_effect({'source': 'block', 'ratio': 1})),
        _refuses('scaleWith.source'),
      );
    });

    test('statusId exige pour targetStatus, refuse ailleurs', () {
      expect(
        () => CardEffect.fromJson(
            _effect({'source': 'targetStatus', 'ratio': 1})),
        _refuses('statusId'),
      );
      expect(
        () => CardEffect.fromJson(_effect(
            {'source': 'armor', 'ratio': 1, 'statusId': 'poison'})),
        _refuses('statusId'),
      );
    });

    test('scaleWith refuse sur draw et gain_mana, et sur un effet a hits 2',
        () {
      const scale = {'source': 'armor', 'ratio': 1};
      for (final type in ['draw', 'gain_mana']) {
        expect(
          () => CardEffect.fromJson(_effect(scale, type: type)),
          _refuses('scaleWith'),
        );
      }
      expect(
        () => CardEffect.fromJson(
            _effect(scale, type: 'damage', extra: {'hits': 2})),
        _refuses('scaleWith'),
      );
    });

    test('targetStatus et targetMissingHp refuses hors d une cible unique', () {
      const status = {
        'source': 'targetStatus',
        'ratio': 1,
        'statusId': 'poison',
      };
      const missing = {'source': 'targetMissingHp', 'ratio': 1};
      expect(
        () => CardData.fromJson(_card('allEnemies', status)),
        _refuses('scaleWith.source'),
      );
      expect(
        () => CardData.fromJson(_card('self', missing)),
        _refuses('scaleWith.source'),
      );
      expect(
        () => SignatureData.fromJson({
          'id': 'sig',
          'heroClass': 'mage',
          'name_en': 'Sig',
          'name_fr': 'Sig',
          'description_en': 'Sig',
          'description_fr': 'Sig',
          'cost': 1,
          'cooldown': 1,
          'type': 'attack',
          'target': 'allEnemies',
          'effects': [_effect(status, type: 'damage')],
        }),
        _refuses('scaleWith.source'),
      );
    });

    test('toJson ecrit scaleWith, et l aller-retour le garde', () {
      final effect = CardEffect.fromJson(_effect({
        'source': 'targetStatus',
        'ratio': 0.5,
        'statusId': 'poison',
      }, type: 'damage'));
      final back = CardEffect.fromJson(effect.toJson()).scaleWith!;
      expect(back.source, ScaleSource.targetStatus);
      expect(back.ratio, 0.5);
      expect(back.statusId, 'poison');
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

    EnemyInstance foe({int pv = 100}) => EnemyInstance(
          data: registry.enemies.first,
          stats: EntityStats(maxPv: 100, currentPv: pv, armure: 0, might: 0),
        );

    void fight(List<EnemyInstance> enemies) {
      enemyId = enemies.first.id;
      combat.state = CombatState(
        enemies: enemies,
        selectedEnemyId: enemyId,
        turnPhase: TurnPhase.player,
      );
    }

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      deck = container.read(deckProvider.notifier);
      run.startNewRun(registry.heroes.singleWhere((h) => h.id == 'paladin'));
      fight([foe()]);
    });

    tearDown(() => container.dispose());

    EntityStats hero() => run.currentState.heroStats;
    EntityStats enemy([int index = 0]) =>
        combat.currentState.enemies[index].stats;

    void setHero(EntityStats Function(EntityStats) change) => run.updateState(
        run.currentState.copyWith(heroStats: change(hero())));

    void play(List<CardEffect> effects,
        {CardRarity rarity = CardRarity.common,
        CardTarget target = CardTarget.singleEnemy}) {
      setHero((h) => h.copyWith(currentMana: 9));
      final played = EffectResolver.resolveCard(
        CardInstance(
          data: CardData(
            id: 'test',
            cost: 1,
            type: CardType.attack,
            rarity: rarity,
            target: target,
            effects: effects,
          ),
        ),
        run,
        deck,
        combat,
        enemyId,
        container.read(effectRegistryProvider),
      );
      expect(played, isTrue);
    }

    CardEffect grows(ScaleSource source, double ratio,
            {String? statusId, String type = 'damage', int value = 1}) =>
        CardEffect(
          type: type,
          value: value,
          scaleWith:
              ScaleWith(source: source, ratio: ratio, statusId: statusId),
        );

    test('armor : le terme lit l Armure du heros', () {
      setHero((h) => h.copyWith(armure: 7));
      play([grows(ScaleSource.armor, 1, value: 2)]);
      expect(enemy().currentPv, 100 - 9);
    });

    test('missingHp : PV max moins PV courants', () {
      setHero((h) => h.copyWith(maxPv: 100, currentPv: 70));
      play([grows(ScaleSource.missingHp, 0.2, value: 4)]);
      expect(enemy().currentPv, 100 - 10);
    });

    test('cardsPlayedThisTurn : les jeux d avant celui-ci', () {
      combat.state = combat.currentState
          .recordCardPlayed()
          .recordCardPlayed();
      play([grows(ScaleSource.cardsPlayedThisTurn, 1)]);
      expect(enemy().currentPv, 100 - 3);
    });

    test('enemiesAlive : un ennemi a 0 PV ne compte pas', () {
      fight([foe(), foe(), foe(pv: 0)]);
      play([grows(ScaleSource.enemiesAlive, 1)],
          target: CardTarget.allEnemies);
      expect(enemy(0).currentPv, 100 - 3);
      expect(enemy(1).currentPv, 100 - 3);
      expect(enemy(2).currentPv, 0);
    });

    test('targetStatus : la somme des entrees du statut sur la cible', () {
      StatusEffect poison(int value, String source) => StatusEffect(
            id: 'poison',
            name: 'Poison',
            type: StatusType.debuff,
            value: value,
            duration: 2,
            sourceId: source,
          );
      final target = foe();
      fight([
        target.copyWith(
          stats: target.stats.copyWith(
            statuses: [poison(2, 'card:a'), poison(3, 'card:b')],
          ),
        ),
      ]);
      play([grows(ScaleSource.targetStatus, 1, statusId: 'poison')]);
      expect(enemy().currentPv, 100 - 6);
    });

    test('targetMissingHp : les PV manquants de la cible', () {
      fight([foe(pv: 60)]);
      play([grows(ScaleSource.targetMissingHp, 0.1)]);
      expect(enemy().currentPv, 60 - 5);
    });

    test('une cible morte ne nourrit ni targetStatus ni targetMissingHp', () {
      int term(CardEffect effect) => EffectResolver.scaleTerm(
            effect,
            hero: hero(),
            combat: combat.currentState,
            targetId: enemyId,
          );
      final missing = grows(ScaleSource.targetMissingHp, 1);
      final vulnerable =
          grows(ScaleSource.targetStatus, 1, statusId: 'vulnerable');
      final marked = EffectResolver.createStatus('vulnerable', 2, 2)!;

      fight([foe(pv: 0)]);
      expect(term(missing), 0);
      fight([foe(pv: 60)]);
      expect(term(missing), 40);

      final dead = foe(pv: 0);
      fight([
        dead.copyWith(stats: dead.stats.copyWith(statuses: [marked])),
      ]);
      expect(term(vulnerable), 0);
      final alive = foe();
      fight([
        alive.copyWith(stats: alive.stats.copyWith(statuses: [marked])),
      ]);
      expect(term(vulnerable), 2);
    });

    test('la rarete ne multiplie pas le terme', () {
      setHero((h) => h.copyWith(armure: 4));
      play([grows(ScaleSource.armor, 1, value: 5)],
          rarity: CardRarity.epic);
      expect(enemy().currentPv, 100 - (8 + 4));
    });

    test('l Armure d un effet precedent compte pour le suivant', () {
      setHero((h) => h.copyWith(armure: 0));
      play([
        const CardEffect(type: 'armor', value: 5),
        grows(ScaleSource.armor, 1, type: 'armor'),
      ], target: CardTarget.self);
      expect(hero().armure, 11);
    });
  });
}
