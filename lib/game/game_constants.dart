import 'package:flame/components.dart';
import 'package:roguelike_card_game/models/map_node.dart';

class GameConstants {
  // --- Z-INDEX PRIORITIES ---
  static const int priorityBackground = -100;
  static const int priorityCardBase = 10;
  static const int priorityCardHovered = 100;
  static const int priorityCardFocused = 150;
  static const int priorityCardTrail = 200;
  static const int priorityTargetingLine = 300;
  static const int priorityCardDraggingMax = 500;

  // --- CARD DIMENSIONS ---
  static const double cardWidth = 140.0;
  static const double cardHeight = 196.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);

  // --- STAT BADGE DIMENSIONS ---
  static final Vector2 badgeHpSize = Vector2(130.0, 16.0);
  static final Vector2 badgeStandardSize = Vector2(48.0, 22.0);
  static final Vector2 badgeCircleSize = Vector2.all(36.0);

  // --- MAP GENERATION QUOTAS ---
  static const Map<MapNodeType, ({int min, int max})> nodeQuotas = {
    MapNodeType.combat: (min: 12, max: 22),
    MapNodeType.elite: (min: 3, max: 6),
    MapNodeType.rest: (min: 3, max: 6),
    MapNodeType.shop: (min: 2, max: 5),
    MapNodeType.event: (min: 4, max: 9),
  };

  // --- DECK RULES ---
  /// Nombre maximum de cartes en main. Au-delà, la pioche s'interrompt sans
  /// consommer de carte ni déclencher de remélange (règle « arrêt net »).
  static const int maxHandSize = 10;

  // --- COMBAT TIMINGS (ms) ---
  /// Délai du dash du héros avant d'appliquer les dégâts d'une compétence.
  static const int combatDelayHeroDashMs = 200;
  /// Délai après l'exécution d'une compétence avant de continuer ou de riposter.
  static const int combatDelayAfterSkillMs = 400;
  /// Délai avant le début du tour des ennemis.
  static const int combatDelayEnemyTurnStartMs = 600;
  /// Délai après la résolution des ticks (poison, buffs, etc.) au début du tour ennemi.
  static const int combatDelayAfterTicksMs = 400;
  /// Délai du dash d'un ennemi lors de son attaque.
  static const int combatDelayEnemyDashMs = 200;
  /// Délai après la résolution d'une intention d'ennemi.
  static const int combatDelayAfterIntentResolveMs = 400;
  /// Délai avant de finaliser le tour des ennemis.
  static const int combatDelayEnemyTurnEndMs = 300;

  // --- FLOATING TEXT CONFIGURATIONS ---
  /// Taille de police pour les textes flottants de type coup critique.
  static const double floatingTextFontSizeCritical = 36.0;
  /// Taille de police pour les textes flottants de type poison.
  static const double floatingTextFontSizePoison = 22.0;
  /// Taille de police pour les textes flottants standards.
  static const double floatingTextFontSizeStandard = 26.0;

  /// Durée de l'effet de rotation initiale à l'apparition.
  static const double floatingTextDurationBirthRotation = 0.15;
  /// Durée de la phase initiale d'agrandissement (pop) pour un coup critique.
  static const double floatingTextDurationCritInitialPop = 0.35;
  /// Durée du retour à l'échelle intermédiaire pour un coup critique.
  static const double floatingTextDurationCritInitialReturn = 0.15;
  /// Durée d'un cycle de pulsation de l'échelle d'un coup critique.
  static const double floatingTextDurationCritPulse = 0.3;
  /// Durée de l'effet de rebond (bounce) initial standard.
  static const double floatingTextDurationStandardBounce = 0.15;
  /// Durée du mouvement de dérive (drift) pour le poison.
  static const double floatingTextDurationDriftPoison = 1.2;
  /// Durée du mouvement de dérive (drift) pour le bouclier.
  static const double floatingTextDurationDriftShield = 1.0;
  /// Durée du mouvement de dérive (drift) standard.
  static const double floatingTextDurationDriftStandard = 1.0;
  /// Durée de l'effet de fondu de sortie (fade out).
  static const double floatingTextDurationFadeOut = 1.2;
  /// Délai avant suppression complète du composant.
  static const double floatingTextDurationRemoveDelay = 1.2;

  /// Facteur multiplicateur pour la rotation initiale aléatoire.
  static const double floatingTextRotationFactor = 0.3;
  /// Dérive horizontale maximale.
  static const double floatingTextDriftXMax = 80.0;
  /// Multiplicateur de dérive horizontale pour le bouclier.
  static const double floatingTextDriftXShieldMultiplier = 0.5;
  /// Dérive verticale de base pour le poison.
  static const double floatingTextDriftYPoisonBase = -90.0;
  /// Plage de dérive verticale aléatoire pour le poison.
  static const double floatingTextDriftYPoisonRandomRange = 30.0;
  /// Dérive verticale de base pour le bouclier.
  static const double floatingTextDriftYShieldBase = -40.0;
  /// Plage de dérive verticale aléatoire pour le bouclier.
  static const double floatingTextDriftYShieldRandomRange = 20.0;
  /// Dérive verticale de base standard.
  static const double floatingTextDriftYStandardBase = 60.0;
  /// Plage de dérive verticale aléatoire standard.
  static const double floatingTextDriftYStandardRandomRange = 40.0;
}

