import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Fige le comportement des gains d'armure, de mana et de puissance tel qu'il
/// était avant leur passage par `StatGains` (spec P-41, §4.1). Ces tests
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu. Une seule valeur a
/// changé depuis, voulue : Armure du Berserker avec de la Maîtrise (P-49).
///
/// Couverts ailleurs : l'intention « défense » d'un ennemi
/// (`combat_controller_test.dart`) et l'armure d'une carte du tutoriel
/// (`tutorial/tutorial_engine_test.dart`).
void main() {
  // Une Maîtrise non nulle : seuls les passifs qui la déclarent en tirent parti.
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    mastery: 3,
  );

  const metallicize = StatusEffect(
    id: 'armor_regen',
    name: 'Metallisation',
    type: StatusType.buff,
    value: 3,
    duration: 2,
  );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats heroStats() => run.currentState.heroStats;

  CardInstance card(
    CardType type,
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
        target: CardTarget.self,
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
      container.read(combatProvider.notifier),
      null,
      container.read(effectRegistryProvider),
    );
    expect(played, isTrue);
  }

  RelicData relic(String effectType, int value) => RelicData(
        id: 'test_relic',
        trigger: RelicTrigger.startOfTurn,
        effectType: effectType,
        value: value,
        rarity: RelicRarity.common,
        emoji: '*',
      );

  PassiveData passive(RelicTrigger trigger, String effectType, int value) =>
      PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: value,
        mastery: const PassiveMastery(field: 'value', perPoint: 1),
      );

  group('armure hors passifs : la valeur seule, jamais la Maitrise', () {
    setUp(() => run.startNewRun(paladin));

    test('carte', () {
      play(card(CardType.skill, const [CardEffect(type: 'armor', value: 10)]));
      expect(heroStats().armure, 10);
    });

    test('rune hardened sur une carte sans effet d armure', () {
      play(card(CardType.attack, const [], runes: const ['hardened:1']));
      expect(heroStats().armure, 2);
    });

    test('relique gain_armor', () {
      run.applyRelicEffect(relic('gain_armor', 4));
      expect(heroStats().armure, 4);
    });

    test('relique charge_armor_turn : a la quatrieme charge', () {
      final incense = relic('charge_armor_turn', 6);
      for (var i = 0; i < 3; i++) {
        run.applyRelicEffect(incense);
      }
      expect(heroStats().armure, 0);

      run.applyRelicEffect(incense);
      expect(heroStats().armure, 6);
    });

    test('statut armor_regen du heros', () {
      final stats = StatusEffectProcessor.processPlayerStatuses(
        heroStats().addStatus(metallicize),
        const [],
      );
      expect(stats.armure, 3);
    });

    test('statut armor_regen d un ennemi', () {
      final enemyStats = EntityStats(
        maxPv: 20,
        currentPv: 20,
        armure: 1,
        might: 2,
        statuses: const [metallicize],
      );
      expect(StatusEffectProcessor.processEnemyStatuses(enemyStats).armure, 4);
    });
  });

  // P-49 (spec, §6.4) : la Maîtrise augmente le paramètre que le passif
  // déclare, avant son calcul. Régénération et Armure Magique n'en voient pas
  // la différence ; Armure du Berserker, si — changement voulu.
  group('armure des passifs : la Maitrise augmente le parametre declare', () {
    test('gain_armor en debut de tour', () {
      run.startNewRun(paladin, passive(RelicTrigger.startOfTurn, 'gain_armor', 2));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
      expect(heroStats().armure, 2 + 3);
    });

    test('gain_armor en fin de tour', () {
      run.startNewRun(paladin, passive(RelicTrigger.endOfTurn, 'gain_armor', 2));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(heroStats().armure, 2 + 3);
    });

    // Les deux tests de `berserker_armor` ont ete retires avec le passif : il
    // ne donne plus d'armure mais de la Puissance temporaire, sous le nom de
    // *Rage* (spec P-41, §6.3). Sa formule et son plancher sont couverts par
    // `test/unit/passives_berserker_test.dart`.

    // Le test de `spell_armor` a ete retire avec le passif : la survie du Mage
    // passe desormais par *Canalisation*, qui la fait payer (spec P-41, §6.3).
    // Le filtrage par type de carte est couvert par les declencheurs
    // `onAttackPlayed` / `onSkillPlayed` (`passive_triggers_test.dart`), qui
    // le font en amont de toute strategie.
  });

  group('mana : aucun plafond', () {
    setUp(() => run.startNewRun(paladin));

    test('carte gain_mana', () {
      play(card(CardType.skill, const [CardEffect(type: 'gain_mana', value: 2)]));
      expect(heroStats().currentMana, 3 + 2);
    });

    test('rune eco', () {
      play(card(CardType.skill, const [], runes: const ['eco:1']));
      expect(heroStats().currentMana, 3 + 1);
    });

    test('relique gain_mana hors debut de run', () {
      run.applyRelicEffect(relic('gain_mana', 2));
      expect(heroStats().currentMana, 3 + 2);
    });
  });

  group('puissance d attaque par progression', () {
    setUp(() => run.startNewRun(paladin));

    test('un gain, puis un retrait de meme valeur', () {
      run.applyHeroStatModifier(mightAcc: 4);
      expect(heroStats().might, 4);

      run.applyHeroStatModifier(mightAcc: -4);
      expect(heroStats().might, 0);
    });
  });
}
