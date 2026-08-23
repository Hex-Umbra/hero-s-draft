class TutorialStep {
  final String titleFr;
  final String titleEn;
  final String bodyFr;
  final String bodyEn;
  final TutorialStepType type;
  final String? highlightZone;

  const TutorialStep({
    required this.titleFr,
    required this.titleEn,
    required this.bodyFr,
    required this.bodyEn,
    required this.type,
    this.highlightZone,
  });
}

enum TutorialStepType {
  welcome,
  classChoice,
  starterDeck,
  map,
  nodeTypes,
  combatOverview,
  cards,
  playCard,
  armorDamage,
  elements,
  enemies,
  merge,
  xp,
  draft,
  relics,
}

