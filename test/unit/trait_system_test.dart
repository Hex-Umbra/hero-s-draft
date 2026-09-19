import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  int armor() => run.currentState.heroStats.armure;

  PassiveData passive(RelicTrigger trigger, String effectType) => PassiveData(
        id: 'test_passive',
        trigger: trigger,
        effectType: effectType,
        value: 2,
      );

  test('sans passif actif : rien', () {
    run.startNewRun(hero);
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
    expect(armor(), 0);
  });

  test('un evenement que le passif n attend pas : rien', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.startOfTurn));
    expect(armor(), 0);
  });

  test('l evenement attendu : la strategie de l effectType agit', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
    expect(armor(), 2);
  });

  test('le declencheur suit la donnee : gain_armor sur une carte jouee', () {
    // Avant P-49, gain_armor n etait honore qu en debut et en fin de tour.
    run.startNewRun(hero, passive(RelicTrigger.onCardPlayed, 'gain_armor'));
    TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.onCardPlayed));
    expect(armor(), 2);
  });

  test('un effectType sans strategie : rien, sans exception', () {
    run.startNewRun(hero, passive(RelicTrigger.endOfTurn, 'inconnu'));
    expect(
      () => TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn)),
      returnsNormally,
    );
    expect(armor(), 0);
  });

  group('la Maitrise, appliquee avant la strategie', () {
    const master = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
      mastery: 3,
    );
    const regen = PassiveData(
      id: 'regen_armor',
      trigger: RelicTrigger.endOfTurn,
      effectType: 'gain_armor',
      value: 2,
      mastery: PassiveMastery(field: 'value', perPoint: 1),
    );

    test('un passif qui declare mastery en tire son parametre augmente', () {
      run.startNewRun(master, regen);
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 + 3);
    });

    test('un passif sans mastery l ignore', () {
      run.startNewRun(master, passive(RelicTrigger.endOfTurn, 'gain_armor'));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2);
    });

    test('le statut de combat mastery compte', () {
      run.startNewRun(master, regen);
      run.addStatus(
        const StatusEffect(
          id: 'mastery',
          name: 'Maîtrise (Relique)',
          type: StatusType.buff,
          value: 1,
          duration: 99,
        ),
      );
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 + 3 + 1);
    });

    test('la Maitrise ne s accumule pas sur le passif actif', () {
      run.startNewRun(master, regen);
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      TraitSystem.dispatch(run, const PassiveEvent(RelicTrigger.endOfTurn));
      expect(armor(), 2 * (2 + 3));
      expect(run.currentState.activePassive!.value, 2);
    });
  });
}
