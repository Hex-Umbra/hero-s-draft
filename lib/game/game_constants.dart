import 'package:flame/components.dart';
import 'package:roguelike_card_game/models/map_node.dart';

/// Une règle de trouvaille : [guaranteed] cartes garanties, puis des jets
/// successifs, en pourcentage — le premier raté arrête.
typedef CardDropRule = ({int guaranteed, List<int> extraChances});

class GameConstants {
  // --- Z-INDEX PRIORITIES ---
  static const int priorityBackground = -100;
  /// Le givre aux coins de l'ecran : au-dessus du fond, sous les cartes.
  static const int priorityFrostVignette = -50;
  /// La carte de combat survolée : ses languettes déroulées passent sur la
  /// carte voisine, sous la main.
  static const int priorityEntityHovered = 5;
  static const int priorityCardBase = 10;
  static const int priorityCardHovered = 100;
  static const int priorityCardFocused = 150;
  static const int priorityCardTrail = 200;
  static const int priorityTargetingLine = 300;
  static const int priorityCardDraggingMax = 500;
  /// Le voile qui estompe le plateau pendant la fiche d'un ennemi : au-dessus
  /// de la carte focalisée de la main, sous la carte ouverte.
  static const int priorityInspectionVeil = 180;
  /// La carte d'un ennemi dont la fiche est ouverte, au-dessus du voile.
  static const int priorityInspectedEnemy = 190;

  // --- FICHE D'UN ENNEMI ---
  /// L'agrandissement de la carte ouverte : le double, à tout palier (B79, B84).
  static const double inspectionScale = 2.0;
  /// Agrandissement, descente et fondu du voile, à l'aller comme au retour.
  static const double inspectionSeconds = 0.15;

  // --- CARD DIMENSIONS ---
  static const double cardWidth = 140.0;
  static const double cardHeight = 196.0;
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);

  // --- MAIN EN ÉVENTAIL ---
  /// L'agrandissement d'une carte survolée, relatif à sa taille en main.
  static const double cardHoverScale = 1.2;
  /// La réserve laissée de chaque côté de l'éventail de la main. Elle reflète
  /// les panneaux latéraux du HUD de combat (`combat_side_panels.dart`) : le
  /// panneau des statuts à gauche et celui des intentions ennemies à droite,
  /// larges de 250 et posés à 20 du bord, plus 16 de marge (20 + 250 + 16).
  static const double handSideReserve = 286.0;

  // --- BARRE DE PV D'UN ENNEMI (unités de la carte) ---
  static const double enemyHealthBarTop = -17.0;
  static const double enemyHealthBarHeight = 13.0;
  static const double enemyHealthBarRadius = 4.0;
  static const double enemyHealthBarFontSize = 9.0;
  static const double enemyHealthBarShieldSize = 8.0;
  static const double enemyHealthBarShieldGap = 3.0;
  static const double enemyHealthBarArmorGap = 2.0;

  // --- CADRE ET RANGÉE D'UN ENNEMI (pixels de cadre) ---
  /// La fenêtre que le cadre entoure, et que le sprite remplit.
  static const double enemyWindowWidth = 64.0;
  static const double enemyWindowHeight = 96.0;

  /// Le plus petit cadre admis : la fenêtre et sa marge de chaque côté.
  static const double enemyTemplateWidth = 88.0;
  static const double enemyTemplateHeight = 120.0;
  static const double enemyTemplateMargin = 12.0;

  /// Les languettes d'état : largeur au repos et recouvrement sur la carte.
  static const double statusTabRestWidth = 30.0;
  static const double statusTabOverlap = 1.0;

  /// La rangée des ennemis : écart minimal et maximal entre deux places, part
  /// utilisable de la largeur d'écran et hauteur du centre (part de l'écran).
  static const double enemyRowMinGap = 7.0;
  static const double enemyRowMaxGap = 122.0;
  static const double enemyRowUsableWidth = 0.95;
  static const double enemyRowCenterY = 0.21;

  // --- MAP GENERATION QUOTAS ---
  static const Map<MapNodeType, ({int min, int max})> nodeQuotas = {
    MapNodeType.combat: (min: 12, max: 22),
    MapNodeType.elite: (min: 3, max: 6),
    MapNodeType.rest: (min: 3, max: 6),
    MapNodeType.shop: (min: 2, max: 5),
    MapNodeType.event: (min: 4, max: 9),
  };

  // --- TROUVAILLE (D1, D31, D57) ---
  /// Les cartes trouvées après un combat, par type de nœud. Un type absent
  /// n'en donne aucune : le boss garde sa récompense (D1).
  static const Map<MapNodeType, CardDropRule> cardDrops = {
    MapNodeType.combat: (guaranteed: 1, extraChances: []),
    MapNodeType.elite: (guaranteed: 1, extraChances: [25]),
  };

  // --- BOSS « XP » (D42) ---
  /// Les runes que la récompense du boss « XP » monte d'un niveau (D42(a)),
  /// tirées parmi les paires (carte, rune) du deck dont la rune peut encore
  /// monter ; la *Meule* en ajoute une par exemplaire
  /// (`RunState.extraBossRuneSharpens`).
  static const int bossXpRuneSharpens = 1;

  // --- DECK RULES ---
  /// La main maximale au début d'une run (D25) : la stat vit sur
  /// `RunState.maxHandSize`, que lisent les six chemins de pioche — au-delà,
  /// la pioche s'interrompt sans consommer de carte ni déclencher de
  /// remélange (règle « arrêt net »). Aucun chemin de pioche ne lit cette
  /// valeur-ci.
  static const int startingMaxHandSize = 10;

  // --- COMBAT TIMINGS (ms) ---
  /// Délai du dash du héros avant d'appliquer les dégâts d'une compétence.
  static const int combatDelayHeroDashMs = 200;
  /// Délai après l'exécution d'une compétence avant de continuer ou de riposter.
  static const int combatDelayAfterSkillMs = 400;
  /// Délai avant le début du tour des ennemis.
  static const int combatDelayEnemyTurnStartMs = 600;
  /// Délai après la résolution des ticks (poison, buffs, etc.) au début du tour ennemi.
  static const int combatDelayAfterTicksMs = 400;
  /// Délai entre deux vagues de la chaîne du Feu (spec P-53, §4.10) : 0,6 s
  /// d'animation — l'éclair puis la boule de feu — et 0,2 s de pause (§5.2).
  static const int combatDelayFireWaveMs = 800;
  /// Délai du dash d'un ennemi lors de son attaque.
  static const int combatDelayEnemyDashMs = 200;
  /// Durée des trois secousses d'un ennemi gelé, qui perd son action.
  static const int combatDelayFrozenShakeMs = 300;
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

