import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/services/displayed_effect_value.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/effective_card.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le chiffre qu'un effet montre en combat, sur une carte comme sur une
/// signature, et sa preuve : c'est celui que le moteur inflige.
void main() {
  group('la valeur et son ecriture', () {
    test(
        'un multi-coups s ecrit valeur×coups, la Puissance par coup arrondie '
        'vers le bas', () {
      const effect =
          CardEffect(type: 'damage', value: 3, hits: 3, mightRatio: 0.5);
      String label(int damageBonus) => DisplayedEffectValue.label(
            effect,
            DisplayedEffectValue.of(effect, damageBonus: damageBonus),
          );
      expect(label(3), '4×3');
      expect(label(1), '3×3');
      expect(DisplayedEffectValue.format(7), '7');
      expect(DisplayedEffectValue.format(7, hits: 2), '7×2');
    });

    test('un effet a scaleWith ajoute le terme, la Puissance des degats ne '
        'touche que les degats', () {
      const damage = CardEffect(
        type: 'damage',
        value: 2,
        scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 1),
      );
      expect(DisplayedEffectValue.of(damage, scaleTerm: 7), 9);

      const armor = CardEffect(
        type: 'armor',
        value: 6,
        scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 0.2),
      );
      expect(DisplayedEffectValue.of(armor, scaleTerm: 2, damageBonus: 5), 8);
    });

    test('la Puissance de statut ne touche qu un statut', () {
      const freeze = CardEffect(
          type: 'apply_status', value: 2, statusId: 'freeze', duration: 1);
      const damage = CardEffect(type: 'damage', value: 4);
      expect(DisplayedEffectValue.of(freeze, statusBonus: 1), 3);
      expect(DisplayedEffectValue.of(damage, statusBonus: 1), 4);
    });

    test('le terme lu sur le heros, 0 sans combat', () {
      const fortification = CardEffect(
        type: 'armor',
        value: 6,
        scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 0.2),
      );
      final card = CardInstance(
        data: const CardData(
          id: 'test_card',
          cost: 1,
          type: CardType.skill,
          rarity: CardRarity.common,
          target: CardTarget.self,
          effects: [fortification],
        ),
      );
      final armored =
          EntityStats(maxPv: 80, currentPv: 80, armure: 10, might: 0);
      expect(
        DisplayedEffectValue.ofCardEffect(card, 0,
            hero: armored, combat: CombatState()),
        8,
      );
      expect(
        DisplayedEffectValue.ofCardEffect(card, 0, hero: armored, combat: null),
        6,
      );
    });
  });

  group('la Puissance de statut sur la face (Q11, A15)', () {
    CardData card(List<CardEffect> effects) => CardData(
          id: 'test_card',
          cost: 1,
          type: CardType.attack,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: effects,
        );
    const damage = CardEffect(type: 'damage', value: 4);
    const freeze = CardEffect(
        type: 'apply_status', value: 2, statusId: 'freeze', duration: 1);
    const poison = CardEffect(
        type: 'apply_status', value: 1, statusId: 'poison', duration: 2);
    const burn = AddEffectDelta(
      effect: 'apply_status',
      valuePerLevel: 1,
      statusId: 'burn',
      durationPerLevel: 1,
    );
    final alteration = EntityStats(
      maxPv: 80,
      currentPv: 80,
      armure: 0,
      might: 2,
      mightTargets: const {MightTarget.alteration},
    );

    test('seul le premier statut de la carte porte le bonus', () {
      final effective = EffectiveCard.apply(
          card([damage, freeze, poison]), CardRarity.common, const []);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 0), isFalse);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 1), isTrue);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 2), isFalse);

      final instance = CardInstance(data: card([damage, freeze, poison]));
      expect(
        [
          for (var i = 0; i < 3; i++)
            DisplayedEffectValue.ofCardEffect(instance, i,
                hero: alteration, combat: CombatState()),
        ],
        [4, 4, 1],
      );
    });

    test('un statut ajoute par une rune passe avant et prend le bonus', () {
      final effective = EffectiveCard.apply(
          card([damage, freeze]), CardRarity.common, const [(burn, 1)]);
      expect(EffectResolver.statusBonusIndex(effective), 0);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 1), isFalse);
    });

    test('sans statut, personne ne porte le bonus', () {
      final effective =
          EffectiveCard.apply(card([damage]), CardRarity.common, const []);
      expect(EffectResolver.statusBonusIndex(effective), -1);
      expect(EffectResolver.cardEffectGetsStatusBonus(effective, 0), isFalse);
    });
  });

  group('les entrees d une signature', () {
    test('sans lecteur, la valeur evoluee ; un multi-coups garde ses coups',
        () {
      const flurry = SignatureData(
        id: 'flurry_test',
        heroClass: 'berserker',
        cost: 1,
        cooldown: 2,
        type: CardType.attack,
        target: CardTarget.singleEnemy,
        effects: [
          CardEffect(type: 'damage', value: 3, hits: 2),
          CardEffect(type: 'armor', value: 2),
        ],
      );
      final signature = SignatureInstance(flurry);
      expect(signature.effectLines(), [
        (kind: 'damage', value: 3, duration: null, hits: 2),
        (kind: 'armor', value: 2, duration: null, hits: 1),
      ]);

      final mighty =
          EntityStats(maxPv: 80, currentPv: 80, armure: 0, might: 2);
      final lines = DisplayedEffectValue.signatureLines(
        signature,
        hero: mighty,
        combat: CombatState(),
      );
      expect(lines.map((l) => l.value), [5, 2]);
      expect(
        DisplayedEffectValue.format(lines.first.value!, hits: lines.first.hits),
        '5×2',
      );
    });
  });

  group('le chiffre montre est celui inflige', () {
    late GameDataRegistry registry;
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
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
    List<EffectLine> shown(SignatureInstance s) =>
        DisplayedEffectValue.signatureLines(
          s,
          hero: hero(),
          combat: combat.currentState,
        );

    /// Une run de [classId], héros neutre — ni critique ni Maîtrise —, ses
    /// vraies signatures, 9 Mana, cinq Frappes en main, et un Slime de 200 PV
    /// sans Armure ni statut.
    void start(String classId, Set<MightTarget> mightTargets) {
      run.startNewRun(
        HeroData(
          id: classId,
          classCard: '$classId.png',
          maxHp: 100,
          maxMana: 9,
          mightTargets: mightTargets,
        ),
        null,
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
            stats:
                EntityStats(maxPv: 200, currentPv: 200, armure: 0, might: 0),
          ),
        ],
        turnPhase: TurnPhase.player,
      ));
    }

    test('Berserker sous Posture de Rage : Frappe Temeraire et une Frappe', () {
      start('berserker', const {MightTarget.attack});
      expect(combat.playSignature(signature('rage_form')), isTrue);
      expect(hero().effectiveMight, 2);

      final reckless = signature('reckless_strike');
      final displayed = shown(reckless).single.value!;
      expect(displayed, 15 + 2);
      final before = enemy().stats.currentPv;
      expect(combat.playSignature(reckless, enemyId: enemy().id), isTrue);
      expect(before - enemy().stats.currentPv, displayed);

      final strike = deck.state.hand.first;
      final strikeShown = DisplayedEffectValue.ofCardEffect(strike, 0,
          hero: hero(), combat: combat.currentState);
      expect(strikeShown, 6 + 2);
      final beforeStrike = enemy().stats.currentPv;
      combat.selectEnemy(enemy().id);
      combat.applyPlayerCardPlay(strike);
      expect(beforeStrike - enemy().stats.currentPv, strikeShown);
    });

    test('Mage a Puissance d alteration : les degats et le Vulnerable de '
        'Projectile Magique', () {
      start('mage', const {MightTarget.skill, MightTarget.alteration});
      run.updateState(
          run.currentState.copyWith(heroStats: hero().copyWith(might: 2)));

      final exposed = SignatureInstance(shipped('magic_missile'),
          evolutions: const ['exposure:1']);
      final lines = shown(exposed);
      expect(lines.map((l) => (l.kind, l.value)), [
        ('damage', 5 + 2),
        ('draw', 1),
        ('status:vulnerable', 2 + 2),
      ]);

      expect(combat.playSignature(exposed, enemyId: enemy().id), isTrue);
      expect(
        enemy().stats.statuses.singleWhere((s) => s.id == 'vulnerable').value,
        lines.last.value,
      );
    });

    test('Mage sans evolution : les degats montres sont les degats infliges',
        () {
      start('mage', const {MightTarget.skill, MightTarget.alteration});
      run.updateState(
          run.currentState.copyWith(heroStats: hero().copyWith(might: 2)));

      final missile = signature('magic_missile');
      final displayed = shown(missile).first.value!;
      expect(combat.playSignature(missile, enemyId: enemy().id), isTrue);
      expect(200 - enemy().stats.currentPv, displayed);
    });

    test('deux statuts ajoutes : seul le premier pris porte le bonus', () {
      start('mage', const {MightTarget.skill, MightTarget.alteration});
      run.updateState(
          run.currentState.copyWith(heroStats: hero().copyWith(might: 2)));

      final both = SignatureInstance(shipped('magic_missile'),
          evolutions: const ['ember:1', 'exposure:1']);
      expect(shown(both).map((l) => (l.kind, l.value)), [
        ('damage', 7),
        ('draw', 1),
        ('status:burn', 1 + 2),
        ('status:vulnerable', 2),
      ]);
    });
  });
}
