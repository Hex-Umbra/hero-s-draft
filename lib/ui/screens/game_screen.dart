import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/heros_draft_game.dart';
import '../../game/game_constants.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/combat_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/reward_controller.dart';
import '../../models/combat_state.dart';
import '../../game/services/effect_resolver.dart';
import '../../game/systems/trait_system.dart';
import 'boss_card_draft_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../widgets/hud/dialogs/pause_dialog.dart';
import '../widgets/hud/death_overlay.dart';
import '../widgets/hud/combat_top_bar.dart';
import '../widgets/hud/combat_bottom_hud.dart';
import '../widgets/hud/turn_control_panel.dart';
import '../widgets/hud/combat_side_panels.dart';
import '../widgets/hud/combat_phase_banner.dart';
import '../widgets/hud/combat_tooltip_overlay.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/relic_carousel/relic_carousel_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late HerosDraftGame _game;
  final bool _showDraft = false;
  String? _phaseBannerText;
  bool _showPhaseBanner = false;

  String? _tooltipTitle;
  String? _tooltipDescription;
  CardType? _tooltipCardType;
  bool _showTooltip = false;

  Color _getTooltipBorderColor() {
    if (_tooltipCardType == null) return Colors.blueAccent;
    switch (_tooltipCardType!) {
      case CardType.attack:
        return Colors.redAccent;
      case CardType.skill:
        return Colors.blueAccent;
      case CardType.power:
        return Colors.amber;
      case CardType.status:
        return Colors.blueGrey;
    }
  }
  bool _showManaWarning = false;
  bool _showRemainingManaWarning = false;
  int _turnCount = 1;
  bool _isVictoryHandled = false;

  void _handleCombatVictory() {
    if (_isVictoryHandled) return;
    _isVictoryHandled = true;

    final runState = ref.read(runProvider);
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    final currentNode = runState.mapNodes.firstWhere(
      (n) => n.id == runState.currentNodeId,
      orElse: () => runState.mapNodes.first,
    );

    ref.read(rewardProvider.notifier).handleVictory(
      defeatedEnemies: ref.read(combatProvider).defeatedEnemies,
      currentNode: currentNode,
      allRelics: gameData.relics,
      allCards: gameData.cards,
      luck: runState.heroStats.luck,
      act: runState.act,
    );

    _presentNextReward();
  }

  void _presentNextReward() {
    if (!mounted) return;
    final rewardState = ref.read(rewardProvider);

    // 1. Present Relic if any and not processed yet
    if (rewardState.rolledRelic != null &&
        !rewardState.isRelicCollected &&
        !rewardState.isRelicSkipped) {
      _showRelicCarouselDialog(rewardState.rolledRelic!);
      return;
    }

    // 2. Present Cards if any and not processed yet
    if (rewardState.rolledCards.isNotEmpty && !rewardState.isCardsProcessed) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BossCardDraftScreen(),
        ),
      ).then((_) {
        if (mounted) {
          _presentNextReward();
        }
      });
      return;
    }

    // 3. Process Gold and XP
    if (!rewardState.isGoldXpCollected) {
      final leveledUp = ref.read(rewardProvider.notifier).collectGoldAndXp();
      final locale = Localizations.localeOf(context).languageCode;
      
      context.showNotification(
        '⚔️ ${locale == 'fr' ? 'VICTOIRE ! +${rewardState.goldGained} Or et +${rewardState.xpGained} XP gagnés' : 'VICTORY! +${rewardState.goldGained} Gold and +${rewardState.xpGained} XP earned'}',
        type: NotificationType.success,
      );

      if (rewardState.rolledBonusCard != null) {
        final bonusCardName = locale == 'fr' ? rewardState.rolledBonusCard!.nameFr : rewardState.rolledBonusCard!.nameEn;
        context.showNotification(
          '🎁 ${locale == 'fr' ? 'Carte Bonus obtenue : $bonusCardName' : 'Bonus Card obtained: $bonusCardName'}',
          type: NotificationType.success,
        );
      }

      if (leveledUp) {
        context.showNotification(
          '🎉 LEVEL UP !',
          type: NotificationType.success,
        );
      }
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _completeAndExitCombat();
        }
      });
    }
  }

  void _showRelicCarouselDialog(RelicData rolledRelic) {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, _, _) {
        return RelicCarouselScreen(
          relicPool: gameData.relics,
          wonRelic: rolledRelic,
          onCollect: () {
            ref.read(rewardProvider.notifier).collectRelic();

            final l10n = AppLocalizations.of(context)!;
            final locale = Localizations.localeOf(context).languageCode;
            String rarityStr = '';
            switch (rolledRelic.rarity) {
              case RelicRarity.common:
                rarityStr = l10n.rarityCommon.toUpperCase();
                break;
              case RelicRarity.uncommon:
                rarityStr = l10n.rarityUncommon.toUpperCase();
                break;
              case RelicRarity.rare:
                rarityStr = l10n.rarityRare.toUpperCase();
                break;
              case RelicRarity.epic:
                rarityStr = l10n.rarityEpic.toUpperCase();
                break;
              case RelicRarity.legendary:
                rarityStr = l10n.rarityLegendary.toUpperCase();
                break;
            }

            context.showNotification(
              '👑 ${locale == 'fr' ? 'RELIQUE OBTENUE' : 'RELIC OBTAINED'} : ${rolledRelic.emoji} ${rolledRelic.getName(locale)} ($rarityStr)',
              type: NotificationType.success,
            );

            Navigator.of(dialogContext).pop();
            _presentNextReward();
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    );
  }

  void _completeAndExitCombat() {
    final runController = ref.read(runProvider.notifier);
    runController.nextLevel();
    runController.completeCurrentNode();
    Navigator.of(context).pop();
  }

  void _startPlayerNewTurn() {
    setState(() {
      _showManaWarning = false;
      _showRemainingManaWarning = false;
      _turnCount++;
    });
    _game.currentPhase = TurnPhase.player;
    _game.heroCard?.suppressArmorChangeAnimation = true;
    ref.read(runProvider.notifier).startTurn();
    ref
        .read(deckProvider.notifier)
        .drawCards(5, maxHandSize: GameConstants.maxHandSize);
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final deck = ref.read(deckProvider);

      if (deck.masterDeck.isEmpty) {
        final gameData = ref.read(gameDataLoaderProvider).requireValue;
        final starterCards = [
          CardInstance(
            data: gameData.cards.firstWhere((c) => c.id == 'strike_basic'),
          ),
          CardInstance(
            data: gameData.cards.firstWhere((c) => c.id == 'defend_basic'),
          ),
          CardInstance(
            data: gameData.cards.firstWhere((c) => c.id == 'demon_form'),
          ),
          CardInstance(
            data: gameData.cards.firstWhere((c) => c.id == 'metallicize'),
          ),
          CardInstance(
            data: gameData.cards.firstWhere((c) => c.id == 'poison_stab'),
          ),
        ];

        ref.read(deckProvider.notifier).initializeStarterDeck(starterCards);
      }

      ref.read(runProvider.notifier).startCombat();

      final runState = ref.read(runProvider);
      final currentNode = runState.mapNodes.firstWhere(
        (n) => n.id == runState.currentNodeId,
        orElse: () => runState.mapNodes.first,
      );
      final bossEnemyId = currentNode.bossEnemyId;
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      ref
          .read(combatProvider.notifier)
          .initializeCombat(
            runState.currentLevel,
            runState.currentNodeType,
            gameData.enemies,
            playerLevel: runState.heroStats.level,
            act: runState.act,
            playerMaxHp: runState.heroStats.maxPv,
            playerAttaque: runState.heroStats.attaque,
            playerMaxMana: runState.heroStats.maxMana,
            playerRelicsCount: ref.read(inventoryProvider).relics.length,
            playerCardsCount: ref.read(deckProvider).masterDeck.length,
            bossEnemyId: bossEnemyId,
          );

      ref.read(deckProvider.notifier).startCombat(
            handSize: 5,
            maxHandSize: GameConstants.maxHandSize,
          );
    });

    _game = HerosDraftGame(
      onEnemiesDead: _handleCombatVictory,
      onEnemyDebuffDeck: (count) {
        // Logique retirée car la carte "Blessure" de test a été supprimée
      },
      onTurnEnded: _startPlayerNewTurn,
      onPhaseChanged: (phase) {
        final l10n = AppLocalizations.of(context)!;
        _triggerPhaseBanner(
          phase == TurnPhase.player ? l10n.playerTurn : l10n.enemyTurn,
        );
      },
      onEnemyKilled: () {
        ref.read(runProvider.notifier).onEnemyKilled();
      },
      onShowTooltip: (title, description, cardType) {
        setState(() {
          _tooltipTitle = title;
          _tooltipDescription = description;
          _tooltipCardType = cardType;
          _showTooltip = true;
        });
      },
      onHideTooltip: () {
        setState(() {
          _showTooltip = false;
        });
      },
      onPlayCard: (card, target) {
        final runController = ref.read(runProvider.notifier);
        final combatController = ref.read(combatProvider.notifier);
        final previousMana = runController.currentState.heroStats.currentMana;

        if (!EffectResolver.canPlayCard(
          card,
          runController.currentState,
          target?.id,
        )) {
          return false;
        }

        if (card.data.type == CardType.attack) {
          _game.heroCard?.dashAnimation();
        } else {
          bool hasArmor = card.data.effects.any((e) => e.type == 'armor');
          _game.heroCard?.buffAnimation(hasArmor ? 'defend' : 'buff');
        }

        if (target != null) {
          combatController.selectEnemy(target.id);
        }

        combatController.applyPlayerCardPlay(
          card,
        );

        setState(() {
          _showRemainingManaWarning = false;
        });

        if (runController.currentState.heroStats.currentMana > 0) {
          setState(() {
            _showManaWarning = false;
          });
        } else if (previousMana > 0 &&
            runController.currentState.heroStats.currentMana == 0) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted &&
                ref.read(combatProvider).enemies.isNotEmpty &&
                ref.read(runProvider).heroStats.currentMana == 0) {
              setState(() {
                _showManaWarning = true;
              });
            }
          });
        }

        return true;
      },
      onResolveEnemyIntent: (enemyId) {
        ref
            .read(combatProvider.notifier)
            .resolveEnemyIntent(enemyId);
      },
      onStartEnemyTurn: () {
        ref
            .read(combatProvider.notifier)
            .startEnemyTurn();
      },
      onEndEnemyTurn: () {
        ref.read(combatProvider.notifier).endEnemyTurn();
        _startPlayerNewTurn();
      },
      onSelectEnemy: (enemyId) {
        ref.read(combatProvider.notifier).selectEnemy(enemyId);
      },
      onUpdateEnemyStats: (enemyId, stats) {
        ref.read(combatProvider.notifier).updateEnemyStats(enemyId, stats);
      },
      onExecuteSkill: (skill, targetEnemyId) {
        ref.read(combatProvider.notifier).executeSkill(skill, targetEnemyId: targetEnemyId);
      },
      onEnemiesSpawned: () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      },
      onAnimationStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  void _triggerPhaseBanner(String text) async {
    setState(() {
      _phaseBannerText = text;
      _showPhaseBanner = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _showPhaseBanner = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final deckState = ref.watch(deckProvider);
    final combatState = ref.watch(combatProvider);
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;

    ref.listen<CombatState>(combatProvider, (previous, next) {
      final wasEnded = previous?.isCombatEnded ?? false;
      if (next.isCombatEnded && next.isVictory && !wasEnded) {
        _handleCombatVictory();
      }
    });

    _game.availableEnemies = gameData.enemies;
    _game.availableHeroes = gameData.heroes;
    _game.syncState(runState);
    _game.syncDeck(deckState);
    _game.syncCombat(combatState);

    final currentNodeId = runState.currentNodeId;
    bool isCompleted = false;
    try {
      final currentNode = runState.mapNodes.firstWhere(
        (n) => n.id == currentNodeId,
      );
      isCompleted = currentNode.isCompleted;
    } catch (_) {}

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;
    final double textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final double baseHudHeight = isMobile ? 100.0 : 88.0;
    final double hudHeight = (baseHudHeight * textScaleFactor).clamp(88.0, 140.0);
    final double hudWidth = isMobile ? screenWidth * 0.90 : screenWidth * 0.52;

    return PopScope(
      canPop: isCompleted || runState.isDead,
      child: Scaffold(
        body: Stack(
          children: [
            // Le jeu prend tout l'écran
            Positioned.fill(child: GameWidget(game: _game)),

            // HUD et Overlays dans une SafeArea
            SafeArea(
              child: Stack(
                children: [

                  if (!_showDraft && runState.isDead) const DeathOverlay(),

                  if (!runState.isDead && !_showDraft)
                    CombatTopBar(
                      act: runState.act,
                      currentLevel: runState.currentLevel,
                      onPauseTap: _showPauseMenu,
                    ),

                  if (!runState.isDead && !_showDraft)
                    CombatBottomHud(
                      hudHeight: hudHeight,
                      hudWidth: hudWidth,
                      currentMana: runState.heroStats.currentMana,
                      maxMana: runState.heroStats.maxMana,
                      currentPv: runState.heroStats.currentPv,
                      maxPv: runState.heroStats.maxPv,
                      armure: runState.heroStats.armure,
                      effectiveAttaque: runState.heroStats.effectiveAttaque,
                    ),

                  if (!runState.isDead && !_showDraft)
                    TurnControlPanel(
                      canEndTurn:
                          combatState.turnPhase == TurnPhase.player &&
                          _game.currentPhase == TurnPhase.player &&
                          !_game.isCardAnimating,
                      onEndTurnTap: () {
                        final currentMana = runState.heroStats.currentMana;
                        if (currentMana > 0 && !_showRemainingManaWarning) {
                          setState(() {
                            _showRemainingManaWarning = true;
                            _showManaWarning = false;
                          });
                          return;
                        }
                        setState(() {
                          _showManaWarning = false;
                          _showRemainingManaWarning = false;
                        });
                        TraitSystem.onTurnEnd(ref.read(runProvider.notifier));
                        ref
                            .read(runProvider.notifier)
                            .applyRelics(RelicTrigger.endOfTurn);
                        ref.read(deckProvider.notifier).discardHand();
                        _game.executeTurn();
                      },
                      showManaWarning: _showManaWarning,
                      showRemainingManaWarning: _showRemainingManaWarning,
                      turnCount: _turnCount,
                    ),

                  if (!runState.isDead && !_showDraft)
                    CombatSidePanels(
                      drawPileCount: deckState.drawPile.length,
                      discardPileCount: deckState.discardPile.length,
                      heroStatuses: runState.heroStats.statuses,
                      enemies: combatState.enemies,
                    ),

                  // Phase Banner Overlay (Centre)
                  if (_showPhaseBanner)
                    CombatPhaseBanner(text: _phaseBannerText ?? ''),

                  // Tooltip Overlay
                  CombatTooltipOverlay(
                    visible: _showTooltip,
                    title: _tooltipTitle,
                    description: _tooltipDescription,
                    borderColor: _getTooltipBorderColor(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPauseMenu() {
    _game.pauseEngine();
    PauseDialog.show(
      context,
      onResume: () => Navigator.of(context).pop(),
      onExit: () {
        Navigator.of(context).pop();
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ).then((_) {
      if (mounted) {
        _game.resumeEngine();
      }
    });
  }
}
