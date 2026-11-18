import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/proportional_status.dart';
import 'package:roguelike_card_game/game/systems/mana_reserve.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
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
  );

  const master = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
    mastery: 2,
  );

  PassiveData channeling() => const PassiveData(
        id: 'channeling',
        trigger: RelicTrigger.endOfTurn,
        effectType: ManaReserve.effectType,
        value: 0,
        mastery: PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} to the Mana reserve cap',
          descriptionFr: '+{amount} au plafond de la reserve de Mana',
        ),
      );

  PassiveData mageMark() => const PassiveData(
        id: 'mage_mark',
        trigger: RelicTrigger.onDamagingCardPlayed,
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
        // Comme `mana_flux.json` : sans plancher, 3 − 2 points ferait 1.
        mastery: const PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          floor: 2,
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

  CardInstance card(CardType type, {CardTarget target = CardTarget.singleEnemy}) =>
      CardInstance(
        data: CardData(
          id: 'test_card',
          cost: 0,
          type: type,
          rarity: CardRarity.common,
          target: target,
          effects: const [CardEffect(type: 'damage', value: 1)],
        ),
      );

  group('Canalisation (D30)', () {
    void setMana(int mana) => run.updateState(
          run.currentState.copyWith(
            heroStats: stats().copyWith(currentMana: mana),
          ),
        );

    test(
        'le mana non depense passe en reserve, et le tour suivant commence a '
        'maxMana + reserve', () {
      run.startNewRun(mage, channeling());
      expect(run.consumeResource(mana: 1), isTrue);

      run.endTurn();
      expect(run.currentState.manaReserve, 2);

      run.startTurn();
      expect(stats().currentMana, 3 + 2);
      expect(run.currentState.manaReserve, 0);
    });

    test('la reserve est plafonnee au Mana max', () {
      run.startNewRun(mage, channeling());
      setMana(5);

      run.endTurn();
      expect(run.currentState.manaReserve, 3);

      run.startTurn();
      expect(stats().currentMana, 3 + 3);
    });

    test('chaque point de Maitrise releve le plafond de 1', () {
      run.startNewRun(master, channeling());
      setMana(7);

      run.endTurn();
      expect(run.currentState.manaReserve, 3 + 2);

      run.startTurn();
      expect(stats().currentMana, 3 + 5);
    });

    test('sans mana non depense, rien en reserve : le tour repart a maxMana',
        () {
      run.startNewRun(mage, channeling());
      expect(run.consumeResource(mana: 3), isTrue);

      run.endTurn();
      expect(run.currentState.manaReserve, 0);

      run.startTurn();
      expect(stats().currentMana, 3);
    });

    test('la reserve ne sert qu une fois : le tour qui la lit la vide', () {
      run.startNewRun(mage, channeling());
      run.endTurn();
      run.startTurn();
      expect(stats().currentMana, 6);

      // Un second début de tour sans fin de tour entre les deux.
      run.startTurn();
      expect(stats().currentMana, 3);
    });

    test('startCombat vide la reserve laissee par le combat precedent', () {
      run.startNewRun(mage, channeling());
      run.endTurn();
      expect(run.currentState.manaReserve, 3);

      run.startCombat();
      expect(run.currentState.manaReserve, 0);
      expect(stats().currentMana, 3);
    });

    test('sous un autre passif, la fin du tour ne met rien en reserve', () {
      run.startNewRun(mage, manaFlux());
      expect(run.consumeResource(mana: 1), isTrue);

      run.endTurn();
      expect(run.currentState.manaReserve, 0);

      run.startTurn();
      expect(stats().currentMana, 3);
    });

    test(
        'la relique de debut de tour et la Source de Mana s ajoutent '
        'par-dessus la reserve', () {
      run.startNewRun(mage, channeling());
      container.read(inventoryProvider.notifier).addRelic(
            const RelicData(
              id: 'energy_stone',
              trigger: RelicTrigger.startOfTurn,
              effectType: 'gain_mana',
              value: 1,
              rarity: RelicRarity.common,
              emoji: '',
            ),
          );
      run.addStatus(EffectResolver.createStatus('mana_regen', 1, 2)!);
      expect(run.consumeResource(mana: 1), isTrue);

      run.endTurn();
      run.startTurn();

      // Mana max, réserve, Pierre d'énergie, Source de Mana.
      expect(stats().currentMana, 3 + 2 + 1 + 1);
    });

    test('un Mana max releve releve aussi le plafond de la reserve', () {
      run.startNewRun(mage, channeling());
      run.updateState(
        run.currentState.copyWith(
          heroStats: stats().copyWith(maxMana: 4, currentMana: 6),
        ),
      );

      run.endTurn();
      expect(run.currentState.manaReserve, 4);

      run.startTurn();
      expect(stats().currentMana, 4 + 4);
    });

    test('la reserve n est pas un gain : une regle de classe sur le mana ne '
        'la convertit pas', () {
      const converter = HeroData(
        id: 'mage',
        classCard: 'mage.png',
        maxHp: 60,
        maxMana: 3,
        statRules: [
          StatRule(
            stat: RuleStat.mana,
            mode: RuleMode.convert,
            to: RuleTarget.statusMight,
          ),
        ],
      );
      run.startNewRun(converter, channeling());
      expect(run.consumeResource(mana: 1), isTrue);

      run.endTurn();
      run.startTurn();

      expect(stats().currentMana, 3 + 2);
      expect(stats().statuses.where((s) => s.id == 'might'), isEmpty);
    });

    test('l apercu dit ce que la fin du tour met en reserve', () {
      run.startNewRun(master, channeling());
      for (final mana in [0, 2, 5, 9]) {
        setMana(mana);
        final preview = ManaReserve.forRun(run.currentState)!;

        run.endTurn();

        expect(run.currentState.manaReserve, preview.banked,
            reason: 'mana $mana');
        expect(preview.capped, mana > 5, reason: 'mana $mana');
      }
    });
  });

  group('Marque du Mage', () {
    test('la premiere carte de degats du tour rend la cible Vulnerable', () {
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

    test('la deuxieme carte de degats du meme tour ne marque rien', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.attack));
      combat.applyPlayerCardPlay(card(CardType.skill));

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

    test('une Competence de degats marque', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(card(CardType.skill));

      expect(vulnerableOnEnemy(), 1);
    });

    test('une carte sans degats ne marque ni ne consomme', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();

      combat.applyPlayerCardPlay(
        CardInstance(
          data: const CardData(
            id: 'test_armor',
            cost: 0,
            type: CardType.skill,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: [CardEffect(type: 'armor', value: 3)],
          ),
        ),
      );
      expect(vulnerableOnEnemy(), 0);

      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(vulnerableOnEnemy(), 1);
    });

    test(
        'une cible tuee par la carte ne consomme pas la marque : la carte de '
        'degats suivante marque', () {
      run.startNewRun(mage, mageMark());
      final enemyA = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 1, armure: 0, might: 0),
      );
      final enemyB = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
      );
      combat.state = CombatState(
        enemies: [enemyA, enemyB],
        selectedEnemyId: enemyA.id,
        turnPhase: TurnPhase.player,
      );

      combat.applyPlayerCardPlay(card(CardType.attack));
      combat.selectEnemy(enemyB.id);
      combat.applyPlayerCardPlay(card(CardType.attack));

      final b = combat.currentState.enemies.singleWhere((e) => e.id == enemyB.id);
      expect(
        b.stats.statuses.where((s) => s.id == 'vulnerable').single.value,
        1,
      );
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

    // Finding 2 de la revue finale : `PassiveEvent.enemyId` documente
    // n'etre renseigne que pour une carte a cible unique. Une Attaque a
    // portee de groupe ne doit marquer personne, meme si une selection
    // residuelle (d'une carte precedente) pointe encore vers un ennemi.
    test(
        'une carte de degats de groupe ne marque ni ne consomme : la carte a '
        'cible unique suivante marque', () {
      run.startNewRun(mage, mageMark());
      final enemyA = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
      );
      final enemyB = EnemyInstance(
        data: slime,
        stats: EntityStats(maxPv: 40, currentPv: 40, armure: 0, might: 0),
      );
      combat.state = CombatState(
        enemies: [enemyA, enemyB],
        selectedEnemyId: enemyA.id, // selection residuelle
        turnPhase: TurnPhase.player,
      );

      combat.applyPlayerCardPlay(
        card(CardType.attack, target: CardTarget.allEnemies),
      );

      bool isVulnerable(String enemyId) => combat.currentState.enemies
          .firstWhere((e) => e.id == enemyId)
          .stats
          .statuses
          .any((s) => s.id == 'vulnerable');

      expect(isVulnerable(enemyA.id), isFalse,
          reason: 'la selection residuelle ne doit pas etre lue');
      expect(isVulnerable(enemyB.id), isFalse);

      combat.selectEnemy(enemyB.id);
      combat.applyPlayerCardPlay(card(CardType.attack));

      expect(isVulnerable(enemyB.id), isTrue,
          reason: 'la carte de groupe n a pas consomme le compteur');
      expect(isVulnerable(enemyA.id), isFalse);
    });

    // Finding 3 de la revue finale : si la cible visee n'existe plus dans le
    // combat au moment ou le passif se resout, la marque ne peut pas
    // s'appliquer — et le compteur du tour ne doit donc pas etre consomme.
    test('une cible absente ne consomme pas le compteur du tour', () {
      run.startNewRun(mage, mageMark());
      seedEnemy();
      final realEnemyId = combat.currentState.enemies.single.id;

      // Simule une selection perimee : l'ennemi vise n'est plus dans le
      // combat quand la Marque se resout.
      combat.state = combat.state.copyWith(selectedEnemyId: 'ghost_enemy_id');
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(vulnerableOnEnemy(), 0, reason: 'rien a marquer, cible absente');

      // Avant le correctif, le compteur du tour aurait deja ete consomme par
      // l'attaque precedente : cette deuxieme Attaque, sur une cible bien
      // presente, ne marquerait alors rien.
      combat.state = combat.state.copyWith(selectedEnemyId: realEnemyId);
      combat.applyPlayerCardPlay(card(CardType.attack));
      expect(vulnerableOnEnemy(), 1,
          reason: 'le compteur du tour est encore disponible');
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

    test('la Maitrise fait baisser le seuil, jusqu a son plancher', () {
      run.startNewRun(master, manaFlux(threshold: 3));
      seedEnemy();

      // 3 − 2 points de Maitrise font 1, que le plancher porte à 2.
      playSkills(1);
      expect(stats().currentMana, 3, reason: 'une seule ne suffit plus');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    // Le plancher vit dans `PassiveData.withMastery` (spec P-43 E3, A23) : à
    // Maitrise 9, le seuil de 3 tomberait à −6, il reste à 2.
    test('le seuil ne descend jamais sous son plancher', () {
      const veryMasterful = HeroData(
        id: 'mage',
        classCard: 'mage.png',
        maxHp: 60,
        maxMana: 3,
        mastery: 9,
      );
      run.startNewRun(veryMasterful, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(1);
      expect(stats().currentMana, 3, reason: 'une Compétence ne suffit pas');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });
  });

  group('le catalogue', () {
    test('le Mage propose Canalisation, Marque du Mage puis Flux de Mana, ses '
        'trois passifs pourvus d un lot (O5)', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'mage');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['channeling', 'mage_mark', 'mana_flux']);
    });

    // D43, D60 (spec P-43 E3, §3.6).
    test('mana_flux.json porte son plancher, 2', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final flux = registry.passives.singleWhere((p) => p.id == 'mana_flux');
      expect(flux.threshold, 3);
      expect(flux.mastery!.field, 'threshold');
      expect(flux.mastery!.floor, 2);
    });

    test(
        'channeling.json : une banque de mana du Mage, plafond 3 + 1 par '
        'point de Maitrise', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final channeling =
          registry.passives.singleWhere((p) => p.id == 'channeling');

      expect(channeling.effectType, ManaReserve.effectType);
      expect(channeling.classes, ['mage']);

      final hero = EntityStats(
        maxPv: 60,
        currentPv: 60,
        maxMana: 3,
        currentMana: 9,
        armure: 0,
        might: 0,
      );
      for (final points in [0, 1, 2]) {
        expect(
          ManaReserve.preview(channeling.withMastery(points), hero)!.banked,
          3 + points,
          reason: 'Maitrise $points',
        );
      }
    });

    test(
        'mage_mark.json pose 2 Vulnerable pendant 2 tours, sur la carte de '
        'degats', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final mark = registry.passives.singleWhere((p) => p.id == 'mage_mark');
      expect(mark.value, 2);
      expect(mark.duration, 2);
      expect(mark.trigger, RelicTrigger.onDamagingCardPlayed);
      expect(ProportionalStatus.vulnerable.percentPerPoint * mark.value, 50);
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
