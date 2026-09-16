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
import 'package:roguelike_card_game/models/status_effect.dart';

const _strength = StatusEffect(
  id: 'strength',
  name: 'Force',
  type: StatusType.buff,
  value: 5,
  duration: 2,
);

void main() {
  group('PowerRules.damageBonusFor', () {
    final stats = EntityStats(
      maxPv: 50,
      currentPv: 50,
      armure: 0,
      attackPower: 2,
      skillPower: 3,
      alterationPower: 4,
      statuses: const [_strength],
    );

    test('une carte Attaque recoit la puissance d attaque et la Force', () {
      expect(stats.damageBonusFor(CardType.attack), 7);
    });

    test('une carte Competence recoit sa puissance, sans la Force', () {
      expect(stats.damageBonusFor(CardType.skill), 3);
    });

    test('les cartes Pouvoir et Statut ne recoivent aucun bonus', () {
      expect(stats.damageBonusFor(CardType.power), 0);
      expect(stats.damageBonusFor(CardType.status), 0);
    });
  });

  group('PowerRules.statusBonusFor', () {
    final stats = EntityStats(
      maxPv: 50,
      currentPv: 50,
      armure: 0,
      attackPower: 2,
      alterationPower: 4,
    );

    test('un statut pose sur un ou plusieurs ennemis recoit alterationPower', () {
      expect(stats.statusBonusFor(CardTarget.singleEnemy), 4);
      expect(stats.statusBonusFor(CardTarget.allEnemies), 4);
    });

    test('un statut pose sur soi, ou sans cible, ne recoit rien', () {
      expect(stats.statusBonusFor(CardTarget.self), 0);
      expect(stats.statusBonusFor(CardTarget.none), 0);
    });
  });

  group('resolution d une carte', () {
    const hero = HeroData(
      id: 'mage',
      classCard: 'mage.png',
      maxHp: 60,
      maxMana: 3,
      baseDamage: 0,
      passiveTrait: 'spell_armor',
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
      run.startNewRun(hero);
      run.updateState(
        run.currentState.copyWith(
          heroStats: run.currentState.heroStats.copyWith(
            skillPower: 3,
            alterationPower: 2,
          ),
        ),
      );
      final enemy = EnemyInstance(
        data: slime,
        stats: EntityStats(
          maxPv: 100,
          currentPv: 100,
          armure: 0,
          attackPower: 1,
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

    test('une Competence offensive ajoute skillPower, pas la Force', () {
      run.addStatus(_strength);

      play(card(CardType.skill, CardTarget.singleEnemy, const [
        CardEffect(type: 'damage', value: 5),
      ]));

      expect(enemy().stats.currentPv, 100 - (5 + 3));
    });

    test('un statut pose sur l ennemi gagne alterationPower en intensite', () {
      play(card(CardType.attack, CardTarget.singleEnemy, const [
        CardEffect(type: 'apply_status', value: 4, statusId: 'poison', duration: 3),
      ]));

      final poison = enemy().stats.statuses.singleWhere((s) => s.id == 'poison');
      expect(poison.value, 4 + 2);
      expect(poison.duration, 3);
    });

    test('un statut pose sur soi ignore alterationPower', () {
      play(card(CardType.skill, CardTarget.self, const [
        CardEffect(type: 'apply_status', value: 2, statusId: 'strength', duration: 1),
      ]));

      final strength = run.currentState.heroStats.statuses
          .singleWhere((s) => s.id == 'strength');
      expect(strength.value, 2);
    });

    test('une rune d altération gagne alterationPower en intensite', () {
      play(card(
        CardType.attack,
        CardTarget.singleEnemy,
        const [CardEffect(type: 'damage', value: 1)],
        runes: const ['burning:1'],
      ));

      final burn = enemy().stats.statuses.singleWhere((s) => s.id == 'burn');
      expect(burn.value, 1 + 2);
      expect(burn.duration, 1);
    });
  });
}
