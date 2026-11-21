import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'components/card_component.dart';
import 'components/entities/combat_entity.dart';
import 'components/entities/hero_card.dart';
import 'components/entities/enemy_card.dart';
import 'components/visual_effects/targeting_line.dart';
import '../models/card_instance.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/card_data.dart';
import '../models/data/charge_data.dart';
import '../models/entity_stats.dart';
import 'game_constants.dart';

import 'controllers/run_controller.dart';
import 'controllers/deck_controller.dart';
import '../models/enemy_intent.dart';
import '../models/combat_state.dart';
import '../services/audio/audio_director.dart';
import '../services/audio/game_moment.dart';

import 'systems/state_sync_system.dart';
import 'systems/card_animation_system.dart';
import 'systems/combat_visual_system.dart';
import 'systems/layout_system.dart';
import 'systems/hand_geometry.dart';
import 'systems/entity_hover.dart';

class HerosDraftGame extends FlameGame with TapCallbacks, PointerMoveCallbacks {
  List<EnemyData> availableEnemies = [];
  List<HeroData> availableHeroes = [];
  HeroCard? heroCard;
  List<EnemyCard> enemyCards = [];
  List<CardComponent> handCards = [];
  CardComponent? hoveredCard;
  CardComponent? focusedCard;

  /// La carte de combat sous la souris, ennemi ou héros : ses languettes sont
  /// déroulées. Nulle au doigt, qui ne survole jamais.
  CombatEntity? hoveredEntity;

  StateSyncSystem? stateSyncSystem;
  CardAnimationSystem? cardAnimationSystem;
  CombatVisualSystem? combatVisualSystem;
  LayoutSystem? layoutSystem;

  TargetingLine get targetingLine => combatVisualSystem!.targetingLine;

  /// Le dernier point connu de la souris, nul tant qu'elle n'a pas bougé
  /// au-dessus du jeu (un écran tactile ne survole jamais) et après un
  /// glisser, qui l'emporte ailleurs.
  Vector2? _lastPointerPos;

  double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);

  RunState? get currentRunState => stateSyncSystem?.currentState;
  CombatState? get currentCombatState => stateSyncSystem?.currentCombatState;

  TurnPhase currentPhase = TurnPhase.player;
  EnemyCard? selectedEnemy;
  EnemyCard? highlightedEnemy;
  bool isCardAnimating = false;

  /// Injecte depuis `GameScreen` : la couche Flame ne lit jamais un provider.
  final AudioDirector audio;

  /// Les images à charger avant le premier rendu. Fournie par le registre
  /// (`GameDataRegistry.imagesToPreload`) : la couche de rendu ne lit jamais
  /// de JSON elle-même.
  final List<String> imagesToPreload;

  /// Le catalogue des charges élémentaires, injecté comme [audio] : les
  /// languettes des cartes de combat y lisent quels statuts sont des charges
  /// et le nom de leur état rompu (spec P-53, A2).
  final ChargeCatalog chargeCatalog;

  final void Function() onEnemiesDead;
  final void Function(TurnPhase) onPhaseChanged;
  final void Function(String title, String description, CardType cardType) onShowTooltip;
  final void Function() onHideTooltip;
  final bool Function(CardInstance, EnemyCard?) onPlayCard;
  final VoidCallback? onEnemiesSpawned;
  final void Function() onEnemyKilled;

  final void Function(String enemyId) onResolveEnemyIntent;
  /// Ouvre la phase ennemie ; vrai si une première vague du Feu s'est jouée.
  final bool Function() onStartEnemyTurn;

  /// La vague suivante de la chaîne du Feu ; faux quand la chaîne est finie.
  final bool Function() onResolveFireWave;

  /// Les autres statuts des ennemis, après la chaîne du Feu.
  final void Function() onResolveEnemyStatuses;
  final void Function() onEndEnemyTurn;
  final void Function(String? enemyId) onSelectEnemy;
  final void Function(String enemyId, EntityStats stats) onUpdateEnemyStats;
  final VoidCallback? onAnimationStateChanged;

  /// Appele quand le jeu lui-meme abandonne l attente d une cible (carte
  /// focalisee, toucher du decor) — jamais quand l ecran la leve.
  final VoidCallback? onEnemyTargetCancelled;

  bool _awaitingEnemyTarget = false;

  /// Armee par l ecran : le prochain ennemi vivant touche lui est rapporte
  /// par [onSelectEnemy]. La lever eteint l ennemi illumine sans rappeler
  /// [onEnemyTargetCancelled].
  bool get awaitingEnemyTarget => _awaitingEnemyTarget;
  set awaitingEnemyTarget(bool value) {
    _awaitingEnemyTarget = value;
    if (!value) highlightEnemy(null);
  }

  HerosDraftGame({
    required this.audio,
    required this.imagesToPreload,
    required this.chargeCatalog,
    required this.onEnemiesDead,
    required this.onPhaseChanged,
    required this.onShowTooltip,
    required this.onHideTooltip,
    required this.onPlayCard,
    required this.onEnemyKilled,
    required this.onResolveEnemyIntent,
    required this.onStartEnemyTurn,
    required this.onResolveFireWave,
    required this.onResolveEnemyStatuses,
    required this.onEndEnemyTurn,
    required this.onSelectEnemy,
    required this.onUpdateEnemyStats,
    this.onEnemiesSpawned,
    this.onAnimationStateChanged,
    this.onEnemyTargetCancelled,
  }) {
    // Cache propre au jeu, jamais le singleton `Flame.images` : le muter en
    // place changerait le prefixe pour tout le processus, et la mutation
    // survivrait d un test widget a l autre dans le meme isolate.
    //
    // Prefixe vide parce que le prefixe ne fait PAS partie des cles du cache
    // (`flame/lib/src/cache/images.dart:29-32`) : avec un prefixe par
    // dossier, l `icon.png` du mage ecraserait celui du paladin. Avec des
    // chemins complets, le chemin est la cle.
    images = Images(prefix: '');
  }

  void setHoveredCard(CardComponent? card) {
    if (card != null && card != hoveredCard) {
      audio.onMoment(GameMoment.cardHover);
    }
    cardAnimationSystem?.setHoveredCard(card);
  }

  void setFocusedCard(CardComponent? card) {
    // Saisir une carte au glisser passe aussi par ici : le glisser commence
    // par le onTapDown de la carte, qui la focalise.
    if (card != null) _cancelEnemyTarget();
    cardAnimationSystem?.setFocusedCard(card);
  }

  void _cancelEnemyTarget() {
    if (!_awaitingEnemyTarget) return;
    awaitingEnemyTarget = false;
    onEnemyTargetCancelled?.call();
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    final pointer = event.localPosition;
    _lastPointerPos = pointer;
    combatVisualSystem?.updatePointer(pointer);
    if (_awaitingEnemyTarget) {
      highlightEnemy(_livingEnemyAt(pointer));
    }
    refreshHover();
    refreshEntityHover();
  }

  /// Oublie le dernier point de la souris : un glisser l'a emportée ailleurs,
  /// et le survol attend son prochain mouvement.
  void forgetPointer() {
    _lastPointerPos = null;
  }

  /// La souris a quitté le jeu (bord de la fenêtre) : plus aucune carte
  /// n'est sous elle.
  void pointerLeft() {
    forgetPointer();
    setHoveredCard(null);
    _setHoveredEntity(null);
  }

  /// Le seul arbitre du survol des cartes de combat (voir
  /// [pickHoveredEntity]) : les ennemis vivants, puis le héros. Appelé à
  /// chaque mouvement de la souris, et quand le plateau change sous un
  /// pointeur immobile.
  void refreshEntityHover() {
    final pointer = _lastPointerPos;
    if (pointer == null) return;

    final hero = heroCard;
    final entities = <CombatEntity>[
      for (final enemy in enemyCards)
        if (_isAlive(enemy) && enemy.isLoaded) enemy,
      if (hero != null && hero.isLoaded) hero,
    ];
    final hovered = hoveredEntity;
    final current = hovered == null ? -1 : entities.indexOf(hovered);
    final index = pickHoveredEntity(
      zones: [for (final entity in entities) entity.zone],
      current: current < 0 ? null : current,
      pointer: pointer.toOffset(),
    );
    _setHoveredEntity(index == null ? null : entities[index]);
  }

  void _setHoveredEntity(CombatEntity? entity) {
    if (entity == hoveredEntity) return;
    hoveredEntity?.setHovered(false);
    hoveredEntity = entity;
    entity?.setHovered(true);
  }

  /// Le seul arbitre du survol de la main : désigne la carte sous le dernier
  /// point connu de la souris (voir [pickHoveredCard]). Appelé à chaque
  /// mouvement, et quand la main change sous un pointeur immobile.
  void refreshHover() {
    final pointer = _lastPointerPos;
    if (pointer == null) return;

    // La carte focalisée, levée et grossie, est dessinée au-dessus de toute
    // la main : elle passe en dernier, lue telle qu'elle est à l'écran. Les
    // autres sont lues à leur place au repos.
    final focused = focusedCard;
    final drawn = [
      for (final card in handCards)
        if (card != focused) card,
      if (focused != null && handCards.contains(focused)) focused,
    ];
    final baseScale = scaleFactor * 0.88;
    final index = pickHoveredCard(
      cards: [
        for (final card in drawn)
          card == focused
              ? HandCardPose(
                  x: card.position.x,
                  y: card.position.y,
                  angle: card.angle,
                  scale: card.scale.x / baseScale,
                  hoverable: _isHoverable(card),
                )
              : HandCardPose(
                  x: card.originalPosition.x,
                  y: card.originalPosition.y,
                  angle: card.originalAngle,
                  hoverable: _isHoverable(card),
                ),
      ],
      pointerX: pointer.x,
      pointerY: pointer.y,
      width: GameConstants.cardWidth * baseScale,
      height: GameConstants.cardHeight * baseScale,
      hoverScale: GameConstants.cardHoverScale,
      current: _indexOrNull(drawn, hoveredCard),
    );
    setHoveredCard(index == null ? null : drawn[index]);
  }

  bool _isHoverable(CardComponent card) =>
      !card.isEnteringHand && !card.isPlayed && !card.isDragging;

  int? _indexOrNull(List<CardComponent> cards, CardComponent? card) {
    if (card == null) return null;
    final index = cards.indexOf(card);
    return index < 0 ? null : index;
  }

  /// L'ennemi vivant dont la zone contient le point, l'ennemi survolé d'abord :
  /// ses languettes déroulées passent sur ses voisins (A8).
  EnemyCard? _livingEnemyAt(Vector2 canvasPos) {
    final hovered = hoveredEntity;
    final ordered = [
      if (hovered is EnemyCard && enemyCards.contains(hovered)) hovered,
      for (final enemy in enemyCards)
        if (enemy != hovered) enemy,
    ];
    for (final enemy in ordered) {
      if (_isAlive(enemy) && enemy.zoneContains(canvasPos)) return enemy;
    }
    return null;
  }

  bool _isAlive(EnemyCard enemy) => !enemy.isDead && !enemy.isPendingDeath;

  /// Ne recoit que les touchers du decor : un ennemi, le heros ou une carte
  /// arretent la propagation de l evenement.
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _cancelEnemyTarget();
    setFocusedCard(null);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final system = StateSyncSystem();
    stateSyncSystem = system;
    final animSys = CardAnimationSystem();
    cardAnimationSystem = animSys;
    final visualSys = CombatVisualSystem();
    combatVisualSystem = visualSys;
    final laySys = LayoutSystem();
    layoutSystem = laySys;

    await add(system);
    await add(animSys);
    await add(visualSys);
    await add(laySys);

    final uniqueImages = <String>{
      'assets/images/bg_dungeon.png',
      ...imagesToPreload,
    }.toList();
    await images.loadAll(uniqueImages);

    final bgSprite = Sprite(images.fromCache('assets/images/bg_dungeon.png'));
    add(
      SpriteComponent(sprite: bgSprite, size: size)
        ..priority = GameConstants.priorityBackground,
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (heroCard != null) {
      heroCard!.position = Vector2(size.x / 2, size.y * 0.51);
    }
    if (enemyCards.isNotEmpty) {
      repositionEnemies();
    }
    layoutHand();

    children.whereType<SpriteComponent>().forEach((bg) {
      if (bg.priority == GameConstants.priorityBackground) bg.size = size;
    });
  }

  void highlightEnemy(EnemyCard? enemy) {
    if (highlightedEnemy != enemy) {
      highlightedEnemy?.setSelection(false);
      highlightedEnemy = enemy;
      highlightedEnemy?.setSelection(true);
    }
  }

  bool tryPlayCard(dynamic cardComp, EnemyCard? target) {
    if (cardComp is CardComponent && onPlayCard(cardComp.card, target)) {
      handCards.remove(cardComp);
      layoutHand();

      isCardAnimating = true;
      onAnimationStateChanged?.call();

      cardComp.playAnimation(
        target,
        // Les degats sont deja appliques dans l'etat : c'est leur *rendu*
        // — nombres flottants et bruitages — qui attend ici la frappe de
        // l'animation, pour ne plus se superposer au son de la carte ni le
        // suivre d'une seconde.
        onImpact: resolvePendingHits,
        onComplete: () {
          cardComp.removeFromParent();
          isCardAnimating = false;
          onAnimationStateChanged?.call();
          resolvePendingDeaths();
        },
      );

      return true;
    }
    return false;
  }

  /// Rend visibles et audibles les coups mis en attente pendant l'animation,
  /// heros compris. Idempotent : les entites sans etat en attente ne font
  /// rien, ce qui permet a [resolvePendingDeaths] de le rappeler en filet.
  void resolvePendingHits() {
    heroCard?.resolvePendingVisualStats();
    for (var card in enemyCards) {
      card.resolvePendingVisualStats();
    }
  }

  void resolvePendingDeaths() {
    resolvePendingHits();

    final deadCards = enemyCards.where((c) => c.isPendingDeath).toList();
    if (deadCards.isEmpty) return;

    for (var card in deadCards) {
      audio.onMoment(GameMoment.enemyDeath, source: card.data);
      card.isDead = true;
      card.add(OpacityEffect.to(0.0, EffectController(duration: 0.4)));
      card.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.4),
          onComplete: () {
            card.removeFromParent();
          },
        ),
      );
      enemyCards.remove(card);
    }
    repositionEnemies();
    onEnemiesSpawned?.call();
  }

  @override
  Color backgroundColor() => const Color(0xFF1E1E2C);

  void syncState(RunState state) {
    stateSyncSystem?.nextState = state;
  }

  void syncDeck(DeckState deckState) {
    stateSyncSystem?.nextDeckState = deckState;
  }

  void syncCombat(CombatState combatState) {
    stateSyncSystem?.nextCombatState = combatState;
  }

  void layoutHand() {
    layoutSystem?.layoutHand();
  }

  void repositionEnemies() {
    layoutSystem?.repositionEnemies();
  }

  void handlePlayerTargeting(EnemyCard target) {
    _handlePlayerTargeting(target);
  }

  void _handlePlayerTargeting(EnemyCard target) {
    if (currentRunState == null ||
        currentRunState!.isDead ||
        currentPhase != TurnPhase.player) {
      return;
    }

    if (focusedCard != null) {
      if (focusedCard!.card.data.target == CardTarget.singleEnemy ||
          focusedCard!.card.data.target == CardTarget.allEnemies) {
        final cardToPlay = focusedCard!;
        if (!cardToPlay.canAfford) {
          audio.onMoment(GameMoment.insufficientMana);
          cardToPlay.shakeAnimation();
          return;
        }
        setFocusedCard(null);
        bool played = tryPlayCard(cardToPlay, target);
        if (played) {
          return;
        }
      }
      return;
    }

    // Un ennemi mort ou mourant laisse l attente en place : l ecran ne
    // verifie pas l ennemi qu on lui rapporte, seul un vivant l est donc.
    if (_awaitingEnemyTarget && _isAlive(target)) {
      awaitingEnemyTarget = false;
      onSelectEnemy(target.id);
    }
  }

  Future<void> executeTurn() async {
    if (currentPhase != TurnPhase.player ||
        currentRunState == null ||
        currentRunState!.isDead) {
      return;
    }
    audio.onMoment(GameMoment.turnEnd);

    currentPhase = TurnPhase.enemy;

    if (enemyCards.isEmpty) {
      onEnemiesDead();
      currentPhase = TurnPhase.player;
      return;
    }

    await _enemyRipostePhase();
  }

  Future<void> _enemyRipostePhase() async {
    onPhaseChanged(TurnPhase.enemy);
    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyTurnStartMs));

    // La chaîne du Feu, une vague à la fois : chacune laisse son compte rendu
    // dans l'état, que `StateSyncSystem` montre avant la suivante (spec
    // P-53, §4.10). Après chaque vague, le filet relâche un voisin que sa
    // boule de feu n'a pas atteint : aucun état retenu ne lui survit.
    var wave = onStartEnemyTurn();
    while (wave) {
      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayFireWaveMs));
      resolvePendingHits();
      wave = onResolveFireWave();
    }
    onResolveEnemyStatuses();

    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterTicksMs));

    final activeEnemies = List<EnemyCard>.from(enemyCards);
    for (var enemy in activeEnemies) {
      if (currentRunState == null || currentRunState!.isDead) break;

      // Un ennemi gelé ne fonce pas : son action est perdue, et le contrôleur
      // consomme le gel même sans intention (spec P-53, A13).
      if (enemy.skipsAction) {
        enemy.frozenTurnAnimation();
        await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayFrozenShakeMs));
        onResolveEnemyIntent(enemy.id);
        await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterIntentResolveMs));
        continue;
      }

      final intent = enemy.effectiveIntent;
      if (intent == null) continue;

      if (intent.type == IntentType.attack) {
        audio.onMoment(GameMoment.enemyAttack, source: enemy.data);
        enemy.dashAnimation();
      } else {
        enemy.buffAnimation(intent.type);
      }

      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyDashMs));

      onResolveEnemyIntent(enemy.id);

      await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayAfterIntentResolveMs));
    }

    await Future.delayed(const Duration(milliseconds: GameConstants.combatDelayEnemyTurnEndMs));

    onEndEnemyTurn();
  }

  void resetEnemies() {
    stateSyncSystem?.currentState = null;
    stateSyncSystem?.currentCombatState = null;
  }

  @override
  void onRemove() {
    stateSyncSystem?.currentState = null;
    stateSyncSystem?.currentCombatState = null;
    super.onRemove();
  }
}
