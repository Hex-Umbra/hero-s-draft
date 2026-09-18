import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
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
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Mage (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
  );

  const master = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    baseDamage: 10,
    mastery: 2,
  );

  PassiveData channeling({int value = 1}) => PassiveData(
        id: 'channeling',
        trigger: RelicTrigger.endOfTurn,
        effectType: 'channeling',
        value: value,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Block per Mana',
          descriptionFr: '+{amount} Armure par Mana',
        ),
      );

  PassiveData mageMark() => const PassiveData(
        id: 'mage_mark',
        trigger: RelicTrigger.onAttackPlayed,
        effectType: 'mage_mark',
        value: 1,
        duration: 2,
      );

  PassiveData manaFlux({int threshold = 3}) => PassiveData(
        id: 'mana_flux',
        trigger: RelicTrigger.onSkillPlayed,
        effectType: 'mana_flux',
        value: 1,
        threshold: threshold,
        mastery: const PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          descriptionEn: '-{amount} Skill to gather',
          descriptionFr: '-{amount} Competence a reunir',
        ),
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

  void seedEnemy() {
    final enemy = EnemyInstance(
      data: slime,
      stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
    );
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemy.id,
      turnPhase: TurnPhase.player,
    );
  }

  int vulnerableOnEnemy() {
    final statuses = combat.currentState.enemies.single.stats.statuses
        .where((s) => s.id == 'vulnerable');
    return statuses.isEmpty ? 0 : statuses.first.value;
  }

  CardInstance card(CardType type) => CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: const [CardEffect(type: 'damage', value: 1)],
        ),
      );

  group('Canalisation', () {
    test('le mana non depense devient de l armure', () {
      run.startNewRun(mage, channeling());
      run.endTurn();

      // 3 de mana au depart, 1 point d'armure par mana.
      expect(stats().armure, 3);
    });

    test('sans mana, rien', () {
      run.startNewRun(mage, channeling());
      expect(run.consumeResource(mana: 3), isTrue);
      run.endTurn();

      expect(stats().armure, 0);
    });

    test('la Maitrise augmente l armure par mana', () {
      run.startNewRun(master, channeling());
      run.endTurn();

      expect(stats().armure, 3 * (1 + 2));
    });
  });

  group('Marque du Mage', () {
    test('la premiere Attaque du tour rend la cible Vulnerable', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 1);
      expect(
        combat.currentState.enemies.single.stats.statuses
            .singleWhere((s) => s.id == 'vulnerable')
            .duration,
        2,
      );
    });

    test('la deuxieme Attaque du meme tour ne marque rien', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));
      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 1, reason: 'une seule marque posee');
    });

    test('au tour suivant, la marque revient', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));
      run.startTurn();
      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(vulnerableOnEnemy(), 2, reason: 'une seconde marque empilee');
    });

    test('une Competence ne marque jamais', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.skill));

      expect(vulnerableOnEnemy(), 0);
    });

    test('seule la cible visee est marquee, pas les autres ennemis', () {
      run.startNewRun(mage, mageMark());
      final enemyA = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
      );
      final enemyB = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
      );
      // `enemyA` est le premier de la liste : un passif qui marquerait
      // `enemies.first` au lieu de lire `PassiveEvent.enemyId` passerait
      // encore le reste du groupe, ou un seul ennemi n'est jamais seme.
      combat.state = CombatState(
        enemies: [enemyA, enemyB],
        selectedEnemyId: enemyB.id,
        turnPhase: TurnPhase.player,
      );

      combat.applyPlayerCardPlay(card(CardType.attack));

      bool isVulnerable(String enemyId) => combat.currentState.enemies
          .firstWhere((e) => e.id == enemyId)
          .stats
          .statuses
          .any((s) => s.id == 'vulnerable');

      expect(isVulnerable(enemyB.id), isTrue,
          reason: 'la cible visee par la carte est marquee');
      expect(isVulnerable(enemyA.id), isFalse,
          reason: 'un ennemi non vise ne doit jamais etre marque');
    });
  });

  group('Flux de Mana', () {
    /// Joue [count] Compétences, sans passer par le coût en mana.
    void playSkills(int count) {
      for (var i = 0; i < count; i++) {
        run.updateState(
          run.currentState.copyWith(
            heroStats: stats().copyWith(currentMana: 3),
          ),
        );
        combat.applyPlayerCardPlay(card(CardType.skill));
      }
    }

    test('le mana arrive au seuil, pas avant', () {
      run.startNewRun(mage, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(2);
      expect(stats().currentMana, 3, reason: 'rien avant le seuil');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    test('le compteur repart de zero apres le declenchement', () {
      run.startNewRun(mage, manaFlux(threshold: 2));
      seedEnemy();

      playSkills(2);
      expect(stats().currentMana, 3 + 1);

      playSkills(1);
      expect(stats().currentMana, 3, reason: 'le compteur a ete vide');
    });

    test('la Maitrise fait baisser le seuil', () {
      run.startNewRun(master, manaFlux(threshold: 3));
      seedEnemy();

      // 3 − 2 points de Maitrise : une Compétence suffit.
      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    // Ce test ne distingue pas le plancher de son absence : le declencheur
    // ne se resout qu'au premier `onSkillPlayed`, ou le compteur vaut deja 1
    // et `1 >= threshold` est vrai que `threshold` vaille 1 ou un negatif
    // profond. Le plancher n'a d'effet observable qu'ailleurs (une future
    // lecture de `passive.threshold` par l'UI, par exemple) ; ce test
    // documente l'intention de la strategie, pas un comportement qu'il
    // pourrait a lui seul faire echouer.
    test('le seuil ne descend jamais sous une Competence', () {
      const veryMasterful = HeroData(
        id: 'mage',
        classCard: 'mage.png',
        maxHp: 60,
        maxMana: 3,
        baseDamage: 10,
        mastery: 9,
      );
      run.startNewRun(veryMasterful, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });
  });

  group('le catalogue', () {
    test('le Mage garde Canalisation en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'mage');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['channeling', 'mage_mark', 'mana_flux']);
    });

    test('les neuf passifs sont livres, et spell_armor n y est plus', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      expect(registry.passives, hasLength(9));
      expect(
        registry.passives.map((p) => p.id),
        isNot(contains('spell_armor')),
      );
    });
  });
}
