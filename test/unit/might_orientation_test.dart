import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/power_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

const _temporaryMight = StatusEffect(
  id: 'might',
  name: 'Puissance',
  type: StatusType.buff,
  value: 5,
  duration: 2,
);

/// La Puissance, que la classe oriente (spec P-41, §7.1).
void main() {
  group('PowerRules', () {
    EntityStats stats(Set<MightTarget> targets) => EntityStats(
          maxPv: 50,
          currentPv: 50,
          armure: 0,
          might: 2,
          mightTargets: targets,
          statuses: const [_temporaryMight],
        );

    test('vers attack : seules les cartes Attaque la recoivent, temporaire comprise', () {
      final s = stats({MightTarget.attack});
      expect(s.damageBonusFor(CardType.attack), 2 + 5);
      expect(s.damageBonusFor(CardType.skill), 0);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 0);
    });

    test('vers skill : seules les cartes Competence la recoivent', () {
      final s = stats({MightTarget.skill});
      expect(s.damageBonusFor(CardType.attack), 0);
      expect(s.damageBonusFor(CardType.skill), 2 + 5);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 0);
    });

    test('vers alteration : seuls les statuts poses sur un ennemi la recoivent', () {
      final s = stats({MightTarget.alteration});
      expect(s.damageBonusFor(CardType.attack), 0);
      expect(s.damageBonusFor(CardType.skill), 0);
      expect(s.statusBonusFor(CardTarget.singleEnemy), 2 + 5);
      expect(s.statusBonusFor(CardTarget.allEnemies), 2 + 5);
    });

    test('les cartes Pouvoir et Statut ne recoivent jamais rien', () {
      final s = stats(MightTarget.values.toSet());
      expect(s.damageBonusFor(CardType.power), 0);
      expect(s.damageBonusFor(CardType.status), 0);
    });

    test('un statut pose sur soi, ou sans cible, ne recoit jamais rien', () {
      final s = stats(MightTarget.values.toSet());
      expect(s.statusBonusFor(CardTarget.self), 0);
      expect(s.statusBonusFor(CardTarget.none), 0);
    });

    test('des stats construites sans orientation la tournent vers attack', () {
      final s = EntityStats(maxPv: 10, currentPv: 10, armure: 0, might: 1);
      expect(s.mightTargets, {MightTarget.attack});
    });
  });

  group('EntityStats en JSON', () {
    test('mightTargets fait l aller-retour', () {
      final s = EntityStats(
        maxPv: 10,
        currentPv: 10,
        armure: 0,
        might: 3,
        mightTargets: const {MightTarget.alteration, MightTarget.skill},
      );
      final json = s.toJson();
      expect(json['mightTargets'], ['skill', 'alteration']);
      expect(EntityStats.fromJson(json).mightTargets, s.mightTargets);
    });

    test('absent du JSON : attack', () {
      final json = EntityStats(maxPv: 10, currentPv: 10, armure: 0, might: 3)
          .toJson()
        ..remove('mightTargets');
      expect(EntityStats.fromJson(json).mightTargets, {MightTarget.attack});
    });
  });

  group('resolution d une carte', () {
    const mage = HeroData(
      id: 'mage',
      classCard: 'mage.png',
      maxHp: 60,
      maxMana: 3,
      mightTargets: {MightTarget.skill, MightTarget.alteration},
    );
    final slime = EnemyData(
      id: 'slime',
      nameEn: 'Slime',
      nameFr: 'Slime',
      maxHp: 100,
      baseDamage: 1,
      spritePath: 'slime.png',
      tier: 1,
      intents: [EnemyIntent(type: IntentType.attack, value: 1)],
    );

    late ProviderContainer container;
    late RunController run;
    late CombatController combat;
    late String enemyId;

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      run.startNewRun(mage);
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(might: 3),
        ),
      );
      final enemy = EnemyInstance(
        data: slime,
        stats: EntityStats(
          maxPv: 100,
          currentPv: 100,
          armure: 0,
          might: 1,
        ),
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
      CardType type,
      CardTarget target,
      List<CardEffect> effects, {
      List<String> runes = const [],
    }) {
      return CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: target,
          effects: effects,
        ),
        forgeUpgrades: runes,
      );
    }

    void play(CardInstance card) {
      final played = EffectResolver.resolveCard(
        card,
        run,
        container.read(deckProvider.notifier),
        combat,
        enemyId,
        container.read(effectRegistryProvider),
      );
      expect(played, isTrue);
    }

    EnemyInstance enemy() => combat.currentState.enemies.single;

    test('startNewRun copie l orientation de la classe dans les stats', () {
      expect(
        run.currentState.heroStats.mightTargets,
        {MightTarget.skill, MightTarget.alteration},
      );
    });

    test('une Competence offensive recoit la Puissance, temporaire comprise', () {
      run.addStatus(_temporaryMight);

      play(card(CardType.skill, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - (5 + 3 + 5));
    });

    test('une carte Attaque ne recoit rien quand la classe ne l oriente pas', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - 5);
    });

    test('un statut pose sur l ennemi gagne la Puissance en intensite, pas en duree', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'apply_status', value: 4, statusId: 'poison', duration: 3),
      ]));

      final poison = enemy().stats.statuses.singleWhere((s) => s.id == 'poison');
      expect(poison.value, 4 + 3);
      expect(poison.duration, 3);
    });

    test('un statut pose sur soi ignore la Puissance', () {
      play(card(CardType.skill, CardTarget.self, const [
        CardEffect(type: 'apply_status', value: 2, statusId: 'might', duration: 1),
      ]));

      final applied = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'might');
      expect(applied.value, 2);
    });

    test('une rune d alteration gagne la Puissance en intensite', () {
      play(card(
        CardType.attack,
        CardTarget.singleEnemy,
        const [CardEffect(type: 'damage', value: 1)],
        runes: const ['burning:1'],
      ));

      final burn = enemy().stats.statuses.singleWhere((s) => s.id == 'burn');
      expect(burn.value, 1 + 3);
      expect(burn.duration, 1);
    });
  });
}
