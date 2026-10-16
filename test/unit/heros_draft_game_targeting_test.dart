import 'package:flame/events.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/card_component.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/game/systems/state_sync_system.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

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

EnemyCard _enemy(String id) => EnemyCard(
      instance: EnemyInstance(
        id: id,
        data: _slime,
        stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
      ),
      onTapEnemy: (_) {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HerosDraftGame game;
  late List<String?> selectedIds;
  late List<CardInstance> playedCards;
  late int cancellations;
  late EnemyCard e1;

  setUp(() {
    selectedIds = [];
    playedCards = [];
    cancellations = 0;
    game = HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: const [],
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
      onStartEnemyTurn: () {},
      onEndEnemyTurn: () {},
      onSelectEnemy: selectedIds.add,
      onUpdateEnemyStats: (_, _) {},
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
    e1 = _enemy('e1');
  });

  test('une cible attendue : toucher un ennemi vivant le rapporte et cesse d attendre', () {
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1);

    expect(selectedIds, ['e1']);
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 0);
  });

  test('sans cible attendue, toucher un ennemi ne rapporte rien', () {
    game.handlePlayerTargeting(e1);

    expect(selectedIds, isEmpty);
  });

  test('une carte focalisee garde la priorite sur la cible attendue', () {
    final card = CardComponent(CardInstance(data: _strike));
    game.focusedCard = card;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1);

    expect(playedCards, [card.card]);
    expect(selectedIds, isEmpty);
  });

  test('un ennemi mort ou mourant n est jamais rapporte', () {
    game.awaitingEnemyTarget = true;

    e1.isDead = true;
    game.handlePlayerTargeting(e1);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);

    final dying = _enemy('e2')..isPendingDeath = true;
    game.handlePlayerTargeting(dying);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);
  });

  test('hors du tour du joueur, aucune cible n est rapportee', () {
    game.currentPhase = TurnPhase.enemy;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1);

    expect(selectedIds, isEmpty);
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

  test('l ecran qui rend la main n est pas rappele', () {
    game.awaitingEnemyTarget = true;
    game.awaitingEnemyTarget = false;

    expect(cancellations, 0);
  });
}
