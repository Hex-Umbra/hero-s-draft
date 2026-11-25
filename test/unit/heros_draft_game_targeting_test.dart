import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui' show FilterQuality, Rect;
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/card_component.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/game/systems/state_sync_system.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

import 'tier_frame_fixture.dart';

const _slime = EnemyData(
  id: 'slime',
  nameEn: 'Slime',
  maxHp: 18,
  baseDamage: 4,
  spritePath: 'slime.png',
);

const _strike = CardData(
  id: 'strike',
  cost: 1,
  type: CardType.attack,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [CardEffect(type: 'damage', value: 6)],
);

EnemyInstance _instance(String id) => EnemyInstance(
      id: id,
      data: _slime,
      stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
    );

/// Une carte jamais montée : `game` posé à la main, pour que `baseScale` le
/// lise ; aucun effet visuel ne joue sur une carte non chargée.
EnemyCard _enemy(HerosDraftGame game, String id, {int tier = 1}) => EnemyCard(
      instance: _instance(id),
      frame: testFrameOf(tier),
      windowBackground: null,
      onTapEnemy: (_, _) {},
    )..game = game;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HerosDraftGame game;
  late List<String?> selectedIds;
  late List<CardInstance> playedCards;
  late List<EnemyInspection?> inspections;
  late int cancellations;
  late EnemyCard e1;
  late EnemyCard e2;

  setUp(() {
    selectedIds = [];
    playedCards = [];
    inspections = [];
    cancellations = 0;
    game = HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: const [],
      chargeCatalog: const ChargeCatalog.empty(),
      onEnemiesDead: () {},
      onPhaseChanged: (_) {},
      onShowTooltip: (_, _, _) {},
      onHideTooltip: () {},
      onPlayCard: (card, _) {
        playedCards.add(card);
        return false;
      },
      onEnemyKilled: () {},
      onResolveEnemyIntent: (_) {},
      onStartEnemyTurn: () => false,
      onResolveFireWave: () => false,
      onResolveEnemyStatuses: () {},
      onEndEnemyTurn: () {},
      onSelectEnemy: selectedIds.add,
      onUpdateEnemyStats: (_, _) {},
      onInspectionChanged: inspections.add,
      onEnemyTargetCancelled: () => cancellations++,
    );
    game.stateSyncSystem = StateSyncSystem()
      ..currentState = RunState(
        currentLevel: 1,
        heroClassId: 'paladin',
        heroStats: EntityStats(
          maxPv: 80,
          currentPv: 60,
          maxMana: 3,
          currentMana: 3,
          armure: 0,
          might: 0,
        ),
      );
    // Un canevas de 1280 x 800 : `scaleFactor` vaut 1, le palier 1,3348,
    // lisse (B85), et le rectangle de la fiche se calcule sans que le jeu
    // soit charge.
    game.onGameResize(Vector2(1280, 800));
    e1 = _enemy(game, 'e1');
    e2 = _enemy(game, 'e2');
  });

  test('sans contexte, le rapport de pixels vaut 1', () {
    expect(game.devicePixelRatio, 1);
  });

  test('la carte au repos est a l echelle du palier, un boss aussi', () {
    final boss = EnemyCard(
      instance: EnemyInstance(
        id: 'boss',
        data: _slime,
        stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
        isBoss: true,
      ),
      frame: testFrameOf(1),
      windowBackground: null,
      onTapEnemy: (_, _) {},
    )..game = game;

    expect(game.boardScale.frame, closeTo(1.3348, 1e-4));
    expect(e1.restScale, game.boardScale.frame);
    expect(boss.restScale, game.boardScale.frame);
  });

  test('la carte d un ennemi mesure le canevas de son tier, sa fenetre a l offset de la table', () {
    final card = _enemy(game, 'e3', tier: 3);

    expect(card.size, Vector2(104, 136));
    expect(card.windowLocalRect, const Rect.fromLTWH(20, 20, 64, 96));
  });

  test('le sprite du decor n est jamais lisse et reste au fond (B88)', () async {
    final image = await createTestImage(width: 2, height: 2);

    final decor = decorSpriteFor(image);

    expect(decor.paint.filterQuality, FilterQuality.none);
    expect(decor.priority, GameConstants.priorityBackground);
  });

  test('une cible attendue : toucher un ennemi vivant le rapporte et cesse d attendre', () {
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, ['e1']);
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 0);
    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('sans cible attendue, toucher un ennemi ne rapporte rien et ouvre sa fiche', () {
    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, isEmpty);
    expect(game.inspectedEnemy, e1);
    expect(e1.isInspected, isTrue);
    expect(inspections.single!.enemyId, 'e1');
  });

  test('toucher un second ennemi remplace la fiche', () {
    game.handlePlayerTargeting(e1, 1);
    game.handlePlayerTargeting(e2, 2);

    expect(game.inspectedEnemy, e2);
    expect(e1.isInspected, isFalse);
    expect(e2.isInspected, isTrue);
    expect(inspections.map((i) => i!.enemyId), ['e1', 'e2']);
  });

  test('toucher l ennemi dont la fiche est ouverte la garde, sans second rappel', () {
    game.handlePlayerTargeting(e1, 1);
    game.handlePlayerTargeting(e1, 2);

    expect(game.inspectedEnemy, e1);
    expect(inspections, hasLength(1));
  });

  test('une carte focalisee garde la priorite sur la cible attendue', () {
    final card = CardComponent(CardInstance(data: _strike));
    game.focusedCard = card;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(playedCards, [card.card]);
    expect(selectedIds, isEmpty);
  });

  test('une carte focalisee joue sa carte et n ouvre aucune fiche', () {
    final card = CardComponent(CardInstance(data: _strike));
    game.focusedCard = card;

    game.handlePlayerTargeting(e1, 1);

    expect(playedCards, [card.card]);
    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('un ennemi mort ou mourant n est jamais rapporte', () {
    game.awaitingEnemyTarget = true;

    e1.isDead = true;
    game.handlePlayerTargeting(e1, 1);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);

    final dying = _enemy(game, 'e3')..isPendingDeath = true;
    game.handlePlayerTargeting(dying, 2);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);
  });

  test('hors du tour du joueur, aucune cible n est rapportee', () {
    game.currentPhase = TurnPhase.enemy;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, isEmpty);
  });

  test('hors du tour du joueur, un ennemi mort ou mourant : aucune fiche', () {
    game.currentPhase = TurnPhase.enemy;
    game.handlePlayerTargeting(e1, 1);
    expect(game.inspectedEnemy, isNull);

    game.currentPhase = TurnPhase.player;
    e1.isDead = true;
    game.handlePlayerTargeting(e1, 2);
    e2.isPendingDeath = true;
    game.handlePlayerTargeting(e2, 3);

    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('focaliser une carte ou toucher le decor annule l attente et le dit a l ecran', () {
    game.awaitingEnemyTarget = true;
    game.setFocusedCard(CardComponent(CardInstance(data: _strike)));
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 1);

    game.awaitingEnemyTarget = true;
    game.onTapDown(TapDownEvent(1, game, TapDownDetails()));
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 2);
  });

  test('focaliser une carte, armer une signature, toucher le decor, finir le tour ferment la fiche', () async {
    void open() => game.handlePlayerTargeting(e1, 1);

    open();
    game.setFocusedCard(CardComponent(CardInstance(data: _strike)));
    expect(game.inspectedEnemy, isNull);
    game.setFocusedCard(null);

    open();
    game.awaitingEnemyTarget = true;
    expect(game.inspectedEnemy, isNull);
    game.awaitingEnemyTarget = false;

    open();
    game.onTapDown(TapDownEvent(2, game, TapDownDetails()));
    expect(game.inspectedEnemy, isNull);

    open();
    await game.executeTurn();
    expect(game.inspectedEnemy, isNull);

    expect(e1.isInspected, isFalse);
    expect(inspections.where((i) => i == null), hasLength(4));
  });

  test('closeInspection sans fiche ouverte ne rappelle rien', () {
    game.closeInspection();

    expect(inspections, isEmpty);
  });

  test('l etat de combat ferme la fiche : ennemi parti, phase ennemie, combat fini', () {
    final states = [
      CombatState(enemies: [_instance('e2')]),
      CombatState(enemies: [_instance('e1')], turnPhase: TurnPhase.enemy),
      CombatState(enemies: [_instance('e1')], isCombatEnded: true),
    ];
    for (final state in states) {
      game.handlePlayerTargeting(e1, 1);
      game.closeInspectionIfStale(state);
      expect(game.inspectedEnemy, isNull);
      expect(inspections.last, isNull);
    }
  });

  test('l etat de combat garde la fiche d un ennemi vivant au tour du joueur', () {
    game.handlePlayerTargeting(e1, 1);

    game.closeInspectionIfStale(CombatState(enemies: [_instance('e1')]));

    expect(game.inspectedEnemy, e1);
    expect(inspections, hasLength(1));
  });

  test('le pointeur retenu garde la fiche une fois, puis il est oublie', () {
    game.handlePlayerTargeting(e1, 7);

    game.closeInspectionUnlessOn(7);
    expect(game.inspectedEnemy, e1);

    game.closeInspectionUnlessOn(7);
    expect(game.inspectedEnemy, isNull);
  });

  test('un autre pointeur ferme la fiche', () {
    game.handlePlayerTargeting(e1, 7);

    game.closeInspectionUnlessOn(8);

    expect(game.inspectedEnemy, isNull);
    expect(inspections.last, isNull);
  });

  test('garder la meme fiche retient aussi le pointeur', () {
    game.handlePlayerTargeting(e1, 7);
    game.closeInspectionUnlessOn(7);

    game.handlePlayerTargeting(e1, 9);
    game.closeInspectionUnlessOn(9);

    expect(game.inspectedEnemy, e1);
  });

  test('ni la carte focalisee ni la signature ne retiennent le pointeur', () {
    game.focusedCard = CardComponent(CardInstance(data: _strike));
    game.handlePlayerTargeting(e1, 5);
    game.focusedCard = null;
    game.inspectEnemy(e2);
    game.closeInspectionUnlessOn(5);
    expect(game.inspectedEnemy, isNull);

    game.awaitingEnemyTarget = true;
    game.handlePlayerTargeting(e1, 6);
    game.inspectEnemy(e2);
    game.closeInspectionUnlessOn(6);
    expect(game.inspectedEnemy, isNull);
  });

  test('replacer les ennemis reemet le rectangle de la fiche ouverte', () {
    game.enemyCards.addAll([e1, e2]);
    game.handlePlayerTargeting(e1, 1);
    final before = inspections.single!.rect;

    e1.place(Vector2(300, 200));
    game.repositionEnemies();

    expect(inspections, hasLength(2));
    expect(inspections.last!.enemyId, 'e1');
    expect(inspections.last!.rect.center.dx, closeTo(300, 0.001));
    expect(inspections.last!.rect, isNot(before));
  });

  test('replacer les ennemis sans fiche, ou fiche d un ennemi parti, ne rappelle rien', () {
    game.enemyCards.addAll([e1, e2]);
    game.repositionEnemies();
    expect(inspections, isEmpty);

    game.handlePlayerTargeting(e1, 1);
    game.enemyCards.remove(e1);
    game.repositionEnemies();
    expect(inspections, hasLength(1));
  });

  test('une reconstruction a taille inchangee ne reemet rien, un vrai redimensionnement reemet', () {
    game.enemyCards.add(e1);
    game.handlePlayerTargeting(e1, 1);

    game.onGameResize(Vector2(1280, 800));
    expect(inspections, hasLength(1));

    game.onGameResize(Vector2(1440, 900));
    expect(inspections, hasLength(2));
    expect(inspections.last!.enemyId, 'e1');
  });

  test('la selection et la surbrillance ne touchent pas la fiche, qui ne touche pas la selection', () {
    game.handlePlayerTargeting(e1, 1);

    e1.setSelection(true);
    game.highlightEnemy(e1);
    game.highlightEnemy(null);
    e1.setHighlight(true);
    e1.setHighlight(false);
    expect(e1.isInspected, isTrue);

    e1.setSelection(true);
    game.closeInspection();
    expect(e1.isInspected, isFalse);
    expect(e1.isSelected, isTrue);
  });

  test('l ecran qui rend la main n est pas rappele', () {
    game.awaitingEnemyTarget = true;
    game.awaitingEnemyTarget = false;

    expect(cancellations, 0);
  });
}
