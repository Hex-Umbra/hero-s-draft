import 'package:flutter/foundation.dart';
import '../models/data/game_data_registry.dart';
import '../models/card_instance.dart';
import '../models/data/card_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/passive_data.dart';
import '../models/entity_stats.dart';
import '../models/enemy_instance.dart';
import '../game/services/damage_pipeline.dart';
import 'tutorial_data.dart';
import 'tutorial_fixtures.dart';
import 'tutorial_step.dart';

class TutorialMockState {
  // --- Tranche persistante (écrite par les étapes 02 et 03) ---
  HeroData? chosenHero;
  PassiveData? activePassive;
  List<CardInstance> masterDeck = [];

  // --- Tranche scratch (réinitialisée à chaque étape) ---
  EntityStats heroStats = EntityStats(
    maxPv: 80,
    currentPv: 80,
    maxMana: 3,
    currentMana: 3,
    armure: 0,
    attaque: 0,
  );
  List<CardInstance> hand = [];
  EnemyInstance? enemy;
  int playerXp = 0;
  int xpToNextLevel = 100;
  int playerLevel = 1;
  bool hasDrafted = false;

  /// Statistiques de départ dérivées de la classe choisie, ou valeurs de
  /// repli tant que l'étape 02 n'a pas été franchie.
  EntityStats baseStatsForHero() {
    final hero = chosenHero;
    if (hero == null) {
      return EntityStats(
        maxPv: 80,
        currentPv: 80,
        maxMana: 3,
        currentMana: 3,
        armure: 0,
        attaque: 0,
      );
    }
    return EntityStats(
      maxPv: hero.maxHp,
      currentPv: hero.maxHp,
      maxMana: hero.maxMana,
      currentMana: hero.maxMana,
      armure: 0,
      armorMastery: hero.armorMastery,
      attaque: 0,
      luck: hero.luck,
    );
  }

  /// Réinitialise uniquement la tranche scratch.
  void resetScratch() {
    heroStats = baseStatsForHero();
    hand = [];
    enemy = null;
    playerXp = 0;
    xpToNextLevel = 100;
    playerLevel = 1;
    hasDrafted = false;
  }
}

class TutorialEngine extends ChangeNotifier {
  final GameDataRegistry data;
  late final TutorialFixtures fixtures;

  int _currentStepIndex = 0;
  final TutorialMockState mockState = TutorialMockState();

  TutorialEngine({required this.data}) {
    fixtures = TutorialFixtures(data);
  }

  int get currentStepIndex => _currentStepIndex;

  bool get isLastStep => _currentStepIndex == kTutorialSteps.length - 1;

  void nextStep() {
    if (_currentStepIndex >= kTutorialSteps.length - 1) return;
    _currentStepIndex++;
    // `>=` et non `>` : atteindre le plancher suffit à verrouiller l'amont.
    if (_currentStepIndex >= _upstreamFloorIndex) _upstreamLocked = true;
    prepareStep(_currentStepIndex);
    notifyListeners();
  }

  void prevStep() {
    if (_currentStepIndex <= minReachableStep) return;
    _currentStepIndex--;
    prepareStep(_currentStepIndex);
    notifyListeners();
  }

  /// Indice plancher du retour en arrière une fois les étapes d'amont
  /// franchies. Dans le parcours cible à 15 étapes, l'indice 3 est « La
  /// Carte du Monde », la première étape qui suit le draft de départ :
  /// revenir en deçà invaliderait la classe et le deck dont dépendent toutes
  /// les étapes suivantes.
  static const int _upstreamFloorIndex = 3;

  bool _upstreamLocked = false;

  int get minReachableStep => _upstreamLocked ? _upstreamFloorIndex : 0;

  void chooseHero(HeroData hero) {
    mockState.chosenHero = hero;
    mockState.activePassive = fixtures.passiveFor(hero);
    mockState.heroStats = mockState.baseStatsForHero();
    notifyListeners();
  }

  /// Fixe le deck de départ : les cartes choisies plus les cartes de classe,
  /// comme `StarterDeckDraftScreen._startAdventure`. Un draft vide donne un
  /// deck vide, cartes de classe comprises : `_isStepActionComplete` lit
  /// `masterDeck.isNotEmpty` pour savoir si l'étape est terminée, et ne doit
  /// donc jamais voir un deck non vide tant que la sélection n'est pas
  /// complète.
  void setStarterDeck(List<CardData> chosen) {
    if (chosen.isEmpty) {
      mockState.masterDeck = [];
      notifyListeners();
      return;
    }

    final hero = mockState.chosenHero;
    final classCards = hero == null
        ? <CardData>[]
        : hero.skills.map(fixtures.card).toList();

    mockState.masterDeck = [
      ...classCards.map((c) => CardInstance(data: c)),
      ...chosen.map((c) => CardInstance(data: c)),
    ];
    notifyListeners();
  }

  /// Prépare l'étape [index] : réinitialise la tranche scratch, puis pose le
  /// décor propre à l'étape. La tranche persistante (classe, deck) survit.
  ///
  /// `seedHand`/`seedEnemy` notifient chacun individuellement ; les appeler
  /// tels quels ici produirait jusqu'à trois notifications par changement
  /// d'étape (une par semis, plus celle de `nextStep`/`prevStep`), soit
  /// autant de reconstructions complètes de l'écran. On passe donc par leurs
  /// variantes privées, sans notification, et une seule notification est
  /// émise à la fin de cette méthode.
  void prepareStep(int index) {
    mockState.resetScratch();
    _armorGainedThisStep = false;

    switch (kTutorialSteps[index].type) {
      case TutorialStepType.cards:
        _seedHand([
          TutorialFixtureIds.strike,
          TutorialFixtureIds.defend,
          TutorialFixtureIds.fireball,
        ]);
        break;
      case TutorialStepType.playCard:
        _seedEnemy();
        _seedHand([TutorialFixtureIds.strike, TutorialFixtureIds.defend]);
        break;
      case TutorialStepType.armorDamage:
        _seedEnemy();
        break;
      case TutorialStepType.merge:
        _seedHand([
          TutorialFixtureIds.strike,
          TutorialFixtureIds.strike,
          TutorialFixtureIds.strike,
        ]);
        break;
      case TutorialStepType.draft:
        mockState.playerLevel = 2;
        break;
      default:
        break;
    }

    notifyListeners();
  }

  /// Peuple la main à partir d'ids de cartes du registre.
  void seedHand(List<String> cardIds) {
    _seedHand(cardIds);
    notifyListeners();
  }

  void _seedHand(List<String> cardIds) {
    mockState.hand = cardIds
        .map((id) => CardInstance(data: fixtures.card(id)))
        .toList();
  }

  /// Place l'ennemi d'entraînement, intention comprise.
  void seedEnemy() {
    _seedEnemy();
    notifyListeners();
  }

  void _seedEnemy() {
    final data = fixtures.trainingEnemy;
    mockState.enemy = EnemyInstance(
      data: data,
      stats: EntityStats(
        maxPv: data.maxHp,
        currentPv: data.maxHp,
        armure: 0,
        attaque: data.baseDamage,
      ),
      currentIntent: data.intents?.first,
    );
  }

  void setMana(int value) {
    mockState.heroStats = mockState.heroStats.copyWith(currentMana: value);
    notifyListeners();
  }

  void setHeroArmor(int value) {
    mockState.heroStats = mockState.heroStats.copyWith(armure: value);
    if (value > 0) _armorGainedThisStep = true;
    notifyListeners();
  }

  bool _armorGainedThisStep = false;

  /// Vrai dès qu'un gain d'armure a eu lieu pendant l'étape courante.
  ///
  /// La complétion de l'étape « Jouer des cartes & finir le tour » ne peut
  /// pas lire `heroStats.armure` : finir le tour remet l'armure à 0, ce qui
  /// re-verrouillerait l'étape et bloquerait le joueur. Le drapeau se
  /// verrouille jusqu'au prochain `prepareStep`.
  bool get armorGainedThisStep => _armorGainedThisStep;

  /// Applique des dégâts au héros via la vraie formule d'absorption.
  void applyDamageToHero(int amount) {
    mockState.heroStats = mockState.heroStats.takeDamage(amount);
    notifyListeners();
  }

  /// Joue une carte de la main. Les dégâts passent par le pipeline réel :
  /// avec `critChance: 0`, il est déterministe.
  bool playCard(CardInstance card) {
    if (mockState.heroStats.currentMana < card.currentCost) return false;

    _manaWarningPending = false;

    mockState.heroStats = mockState.heroStats.copyWith(
      currentMana: mockState.heroStats.currentMana - card.currentCost,
    );
    mockState.hand.remove(card);

    for (final effect in card.data.effects) {
      final scaled = (effect.value * card.rarityMultiplier).round();

      if (effect.type == 'damage') {
        final enemy = mockState.enemy;
        if (enemy == null) continue;
        final (dealt, isCrit) = DamagePipeline.calculate(
          initialDamage: scaled + mockState.heroStats.effectiveAttaque,
          attackerStats: mockState.heroStats,
          defenderStats: enemy.stats,
        );
        mockState.enemy = enemy.copyWith(
          stats: enemy.stats.takeDamage(dealt, isCrit: isCrit),
        );
      } else if (effect.type == 'armor') {
        mockState.heroStats = mockState.heroStats.copyWith(
          armure: mockState.heroStats.armure + scaled,
        );
        if (scaled > 0) _armorGainedThisStep = true;
      }
    }

    notifyListeners();
    return true;
  }

  /// Fusionne les 3 exemplaires de la main en une carte de rareté
  /// supérieure, comme `DeckNotifier.mergeCards`.
  void mergeCards() {
    if (mockState.hand.length != 3) return;
    final base = mockState.hand.first;
    final nextIndex = (base.rarity.index + 1).clamp(0, CardRarity.values.length - 1);
    mockState.hand = [
      CardInstance(data: base.data, rarity: CardRarity.values[nextIndex]),
    ];
    notifyListeners();
  }

  void draftReward() {
    mockState.hasDrafted = true;
    notifyListeners();
  }

  void gainXp(int amount) {
    mockState.playerXp += amount;
    if (mockState.playerXp >= mockState.xpToNextLevel) {
      mockState.playerLevel++;
      mockState.playerXp = mockState.playerXp - mockState.xpToNextLevel;
    }
    notifyListeners();
  }

  bool _manaWarningPending = false;

  bool get manaWarningPending => _manaWarningPending;

  /// Reproduit la double confirmation du jeu : terminer le tour avec du mana
  /// restant demande deux clics. Le second tour ouvre avec l'armure remise à
  /// zéro et le mana au maximum, comme `RunController.startTurn()`.
  bool endTurn() {
    if (mockState.heroStats.currentMana > 0 && !_manaWarningPending) {
      _manaWarningPending = true;
      notifyListeners();
      return false;
    }

    _manaWarningPending = false;
    mockState.heroStats = mockState.heroStats.copyWith(
      armure: 0,
      currentMana: mockState.heroStats.maxMana,
    );
    notifyListeners();
    return true;
  }
}
