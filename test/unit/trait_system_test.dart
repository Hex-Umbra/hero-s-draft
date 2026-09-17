import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategy.dart';
import 'package:roguelike_card_game/game/systems/trait_system.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

/// Le répartiteur des passifs (spec P-49, §5.3).
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
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
}
