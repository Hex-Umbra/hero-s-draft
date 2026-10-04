import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

import 'shipped_data.dart';

/// La borne de la main sur chacun des six chemins qui ajoutent une carte à
/// la main (spec P-43 E3, §4.3, A6, A11) : la main d'ouverture, la pioche du
/// tour, une carte `draw`, la rune `quick`, *Frénésie*, le menu de debug.
///
/// La borne vaut ici 7, et non la main de départ (10) : un chemin qui lirait
/// encore une constante piocherait au-delà. Chaque cas vérifie aussi la
/// conservation des piles — rien ne se perd, rien ne se double.
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );
  const berserker = HeroData(
    id: 'berserker',
    classCard: 'berserker.png',
    maxHp: 80,
    maxMana: 3,
  );

  /// *Frénésie*, qui fait piocher trois cartes par ennemi abattu.
  const frenzy = PassiveData(
    id: 'frenzy',
    trigger: RelicTrigger.onEnemyKilled,
    effectType: 'frenzy',
    value: 2,
    duration: 1,
    draw: 3,
  );

  /// Une carte sans effet, gratuite, qui ne vise que le héros.
  CardInstance filler(String id) => CardInstance(
        data: CardData(
          id: id,
          cost: 0,
          type: CardType.skill,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.self,
          effects: const [],
        ),
      );

  List<CardInstance> fillers(String prefix, int count) =>
      [for (var i = 0; i < count; i++) filler('${prefix}_$i')];

  late ProviderContainer container;
  late RunController run;
  late DeckNotifier deck;
  late CombatController combat;

  setUp(() {
    // La rune `quick` telle que le jeu la livre : `EffectiveCard` lit le
    // catalogue du registre.
    shippedRuneRegistry(const ['quick']);
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    deck = container.read(deckProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  /// Une run de [hero] dont la main maximale vaut 7.
  void startRun({
    HeroData hero = paladin,
    PassiveData? passive,
    int cardsPerTurn = 5,
    bool debug = false,
  }) {
    // Avant `startNewRun` : c'est lui qui rend effectif le mode demandé.
    if (debug) container.read(debugRunProvider.notifier).requestDebugRun();
    run.startNewRun(hero, passive);
    run.updateState(
      run.currentState.copyWith(maxHandSize: 7, cardsPerTurn: cardsPerTurn),
    );
  }

  /// Pose [hand] en main et [drawPile] en pioche ; le deck est les deux.
  void seedPiles(List<CardInstance> hand, List<CardInstance> drawPile) {
    deck.initializeStarterDeck([...hand, ...drawPile]);
    deck.state = deck.state.copyWith(
      hand: hand,
      drawPile: drawPile,
      discardPile: const [],
      exhaustPile: const [],
    );
  }

  DeckState piles() => container.read(deckProvider);

  /// La conservation : pioche + main + défausse + épuisement = deck.
  void expectConserved() {
    final s = piles();
    expect(
      s.drawPile.length +
          s.hand.length +
          s.discardPile.length +
          s.exhaustPile.length,
      s.masterDeck.length,
    );
  }

  test('la main d ouverture s arrete a la borne', () {
    startRun(cardsPerTurn: 9);
    deck.initializeStarterDeck(fillers('c', 12));

    combat.startPlayerCombat();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('la pioche du tour s arrete a la borne', () {
    startRun();
    deck.initializeStarterDeck(fillers('c', 12));
    combat.startPlayerCombat();
    expect(piles().hand, hasLength(5));

    combat.startPlayerTurn();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('une carte draw jouee sur une main pleine ne pioche rien', () {
    startRun();
    final drawThree = CardInstance(
      data: const CardData(
        id: 'draw_three',
        cost: 0,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [CardEffect(type: 'draw', value: 3)],
      ),
    );
    seedPiles([drawThree, ...fillers('h', 6)], fillers('p', 5));

    // L'effet se résout avant que la carte quitte la main : la main est
    // pleine, à 7, quand la carte pioche.
    combat.applyPlayerCardPlay(drawThree);

    expect(piles().hand, hasLength(6));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('la rune quick jouee sur une main pleine ne pioche rien', () {
    startRun();
    final swift = CardInstance(
      data: const CardData(
        id: 'swift',
        cost: 0,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [],
      ),
      rarity: CardRarity.rare,
      forgeUpgrades: const ['quick:1'],
    );
    // La rune ajoute bien une pioche : sans la borne, la carte piocherait.
    expect(swift.effective.addedEffects.map((e) => e.type), ['draw']);
    seedPiles([swift, ...fillers('h', 6)], fillers('p', 5));

    combat.applyPlayerCardPlay(swift);

    expect(piles().hand, hasLength(6));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('Frenesie sur une main pleine ne pioche rien', () {
    startRun(hero: berserker, passive: frenzy);
    seedPiles(fillers('h', 7), fillers('p', 5));

    // Un ennemi abattu sans carte jouee — la file d'ennemis, le menu de
    // debug : une carte qui tue a deja quitte la main quand les morts se
    // comptent (`combat_controller.dart:225`, `:274`).
    run.onEnemyKilled();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('le menu de debug pioche jusqu a la borne', () {
    startRun(debug: true);
    seedPiles(fillers('h', 5), fillers('p', 7));

    DebugActions.drawCards(container.read, 5);

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('une main deja au-dela de la borne ne pioche rien et ne perd rien', () {
    // Le champ « Main max » du menu de debug abaisse la borne sous la main en
    // cours : la pioche suivante n'ajoute rien, et ne retire rien.
    startRun();
    seedPiles(fillers('h', 9), fillers('p', 3));

    combat.startPlayerTurn();

    expect(piles().hand, hasLength(9));
    expect(piles().drawPile, hasLength(3));
    expectConserved();
  });

  test('startNewRun pose la main de depart : apres une run a 7, la suivante '
      'repart a 10', () {
    expect(GameConstants.startingMaxHandSize, 10);
    expect(run.currentState.maxHandSize, GameConstants.startingMaxHandSize);
    startRun();
    expect(run.currentState.maxHandSize, 7);

    run.startNewRun(paladin);

    expect(run.currentState.maxHandSize, GameConstants.startingMaxHandSize);
  });
}
