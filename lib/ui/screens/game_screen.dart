import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/combat_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/combat_state.dart';
import '../../game/services/effect_resolver.dart';
import '../../game/systems/trait_system.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import 'deck_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../../models/map_node.dart';
import '../widgets/hud/player_health_bar.dart';
import '../widgets/hud/mana_indicator.dart';
import '../widgets/hud/status_effects_panel.dart';
import '../widgets/hud/enemy_intents_panel.dart';
import '../widgets/hud/dialogs/pause_dialog.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/relic_carousel/relic_carousel_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late HerosDraftGame _game;
  bool _showDraft = false;
  String? _phaseBannerText;
  bool _showPhaseBanner = false;

  String? _tooltipTitle;
  String? _tooltipDescription;
  bool _showTooltip = false;
  bool _showManaWarning = false;
  int _turnCount = 1;
  bool _isVictoryHandled = false;

  void _handleCombatVictory() {
    if (_isVictoryHandled) return;
    _isVictoryHandled = true;

    final runState = ref.read(runProvider);
    final currentNodeType = runState.currentNodeType;

    if (currentNodeType == MapNodeType.boss ||
        currentNodeType == MapNodeType.elite) {
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      final relics = gameData.relics;
      if (relics.isNotEmpty) {
        final luck = runState.heroStats.luck;
        final rand = Random().nextDouble() * 100;

        final currentNode = runState.mapNodes.firstWhere(
          (n) => n.id == runState.currentNodeId,
          orElse: () => runState.mapNodes.first,
        );
        final bool isImprovedRelic = currentNode.bossEnemyId == 'boss_relic_improved';

        final double legChance;
        final double epicChance;
        final double rareChance;
        final double uncommonChance;

        if (isImprovedRelic) {
          // No common relic, minimum Uncommon. Increased chances for Legendary/Epic.
          legChance = 15.0 + luck * 0.5;
          epicChance = 30.0 + luck * 1.0;
          rareChance = 35.0 + luck * 2.0;
          uncommonChance = 20.0 + luck * 3.0; // The rest goes to Uncommon (total is 100% since no Common is allowed)
        } else {
          legChance = 1.0 + luck * 0.5;
          epicChance = 5.0 + luck * 1.0;
          rareChance = 14.0 + luck * 2.0;
          uncommonChance = 20.0 + luck * 3.0;
        }

        RelicRarity rarity;
        double roll = rand;
        if (roll < legChance) {
          rarity = RelicRarity.legendary;
        } else {
          roll -= legChance;
          if (roll < epicChance) {
            rarity = RelicRarity.epic;
          } else {
            roll -= epicChance;
            if (roll < rareChance) {
              rarity = RelicRarity.rare;
            } else {
              roll -= rareChance;
              if (isImprovedRelic) {
                // If it is improved relic, it's guaranteed at least Uncommon
                rarity = RelicRarity.uncommon;
              } else {
                if (roll < uncommonChance) {
                  rarity = RelicRarity.uncommon;
                } else {
                  rarity = RelicRarity.common;
                }
              }
            }
          }
        }

        var filtered = relics.where((r) => r.rarity == rarity).toList();
        if (filtered.isEmpty) {
          filtered = relics
              .where((r) => r.rarity == RelicRarity.common)
              .toList();
          if (filtered.isEmpty) {
            filtered = relics;
          }
        }
        final chosenRelic = filtered[Random().nextInt(filtered.length)];

        // Show the premium carousel dialog instead of a direct snackbar
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black87,
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (dialogContext, _, _) {
            return RelicCarouselScreen(
              relicPool: relics,
              wonRelic: chosenRelic,
              onCollect: () {
                // Add the relic to inventory upon collecting
                ref.read(inventoryProvider.notifier).addRelic(chosenRelic);

                // Show localized snackbar confirmation
                final l10n = AppLocalizations.of(context)!;
                final locale = Localizations.localeOf(context).languageCode;
                String rarityStr = '';
                switch (chosenRelic.rarity) {
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
                  '👑 ${locale == 'fr' ? 'RELIQUE OBTENUE' : 'RELIC OBTAINED'} : ${chosenRelic.emoji} ${chosenRelic.getName(locale)} ($rarityStr)',
                  type: NotificationType.success,
                );

                // Dismiss carousel screen
                Navigator.of(dialogContext).pop();

                // Process XP and progress
                _resolveCombatProgression();
              },
            );
          },
          transitionBuilder: (ctx, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        );
        return; // Return early, transitions are handled in onCollect callback
      }
    }

    // Fallback if not boss/elite or relics empty
    _resolveCombatProgression();
  }

  void _resolveCombatProgression() {
    final combatState = ref.read(combatProvider);
    final runState = ref.read(runProvider);
    final currentNode = runState.mapNodes.firstWhere(
      (n) => n.id == runState.currentNodeId,
      orElse: () => runState.mapNodes.first,
    );
    final bool isCardGiver = currentNode.bossEnemyId == 'boss_card_giver';
    final bool isXpMultiplier = currentNode.bossEnemyId == 'boss_xp_multiplier';

    // 1. Calculate accumulated XP from all defeated enemies
    int totalXp = 0;
    for (var enemy in combatState.defeatedEnemies) {
      final double levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1);
      totalXp += (enemy.data.xp * levelMultiplier).round();
    }

    if (isXpMultiplier) {
      totalXp *= 2;
    }

    if (isCardGiver) {
      _showBossCardGiverDialog(context, () {
        _finishResolveCombatProgression(totalXp);
      });
    } else {
      _finishResolveCombatProgression(totalXp);
    }
  }

  void _finishResolveCombatProgression(int totalXp) {
    final locale = Localizations.localeOf(context).languageCode;
    // 2. Add XP to player and check level up
    final bool leveledUp = ref.read(runProvider.notifier).gainXp(totalXp);

    // 3. Show notification
    context.showNotification(
      '⚔️ ${locale == 'fr' ? 'VICTOIRE ! +$totalXp XP gagnés' : 'VICTORY! +$totalXp XP earned'}',
      type: NotificationType.success,
    );

    if (leveledUp) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          context.showNotification(
            '🎉 LEVEL UP !',
            type: NotificationType.success,
          );
          setState(() {
            _showDraft = true;
          });
        }
      });
    } else {
      // No level up, just give default victory gold & return to map
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _finishCombatWithoutDraft();
        }
      });
    }
  }

  void _showBossCardGiverDialog(BuildContext context, VoidCallback onComplete) {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    final allCards = gameData.cards;

    // Choose 3 distinct random cards from the pool
    final random = Random();
    final List<CardData> selectedThree = [];
    if (allCards.isNotEmpty) {
      final pool = List<CardData>.from(allCards);
      for (int i = 0; i < 3; i++) {
        if (pool.isEmpty) break;
        final idx = random.nextInt(pool.length);
        selectedThree.add(pool.removeAt(idx));
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isFr = Localizations.localeOf(context).languageCode == 'fr';
            final Set<CardData> selected = {};

            return AlertDialog(
              backgroundColor: const Color(0xFFF4ECD8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF8B4513), width: 2),
              ),
              title: Text(
                isFr ? "Récompense de Boss : Choix de Cartes" : "Boss Reward: Card Choice",
                style: const TextStyle(
                  color: Color(0xFF8B4513),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isFr
                          ? "Choisissez entre 1 et 3 cartes à ajouter à votre deck :"
                          : "Choose between 1 and 3 cards to add to your deck:",
                      style: const TextStyle(color: Color(0xFF4A3728), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Cards display
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: selectedThree.map((cardData) {
                        final isSelected = selected.contains(cardData);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selected.remove(cardData);
                              } else {
                                selected.add(cardData);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 140,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.amber.withAlpha(50) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.grey,
                                width: isSelected ? 3 : 1.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: Colors.amber.withAlpha(100), blurRadius: 8, spreadRadius: 2)]
                                  : [],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Title / Name
                                Text(
                                  cardData.getName(isFr ? 'fr' : 'en'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A3728),
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                // Cost
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${cardData.cost} Mana',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Description
                                Text(
                                  cardData.getDescription(isFr ? 'fr' : 'en'),
                                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: (selected.isNotEmpty && selected.length <= 3)
                        ? () {
                            // Add selected cards to deck
                            for (var cardData in selected) {
                              ref.read(deckProvider.notifier).addCardToMasterDeck(
                                    CardInstance(data: cardData),
                                  );
                            }
                            Navigator.of(dialogContext).pop();
                            onComplete();
                          }
                        : null,
                    child: Text(
                      isFr ? "Confirmer" : "Confirm",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _finishCombatWithoutDraft() {
    final runController = ref.read(runProvider.notifier);
    final rng = Random();
    final currentNodeType = runController.currentState.currentNodeType;

    int goldGained = rng.nextInt(15) + 10;
    if (currentNodeType == MapNodeType.elite) {
      goldGained = rng.nextInt(15) + 20;
    }

    ref.read(inventoryProvider.notifier).gainGold(goldGained);
    runController.nextLevel();
    runController.completeCurrentNode();
    Navigator.of(context).pop(); // Return to map
  }

  void _startPlayerNewTurn() {
    setState(() {
      _showManaWarning = false;
      _turnCount++;
    });
    ref.read(runProvider.notifier).startTurn();
    final deckNotifier = ref.read(deckProvider.notifier);
    if (ref.read(deckProvider).drawPile.length < 5) {
      deckNotifier.shuffleDiscardIntoDraw();
    }
    deckNotifier.drawCards(5);
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
            bossEnemyId: bossEnemyId,
          );

      ref.read(deckProvider.notifier).initializeCombat();
      ref.read(deckProvider.notifier).drawCards(5);
    });

    _game = HerosDraftGame(
      onPlayerTakeDamage: (dmg) {
        ref.read(runProvider.notifier).takeDamage(dmg);
      },
      onPlayerHeal: (heal) {
        ref.read(runProvider.notifier).heal(heal);
      },
      onPlayerGainArmor: (armor) {
        final currentArmor = ref.read(runProvider).heroStats.armure;
        ref
            .read(runProvider.notifier)
            .setHeroStats(armure: currentArmor + armor);
      },
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
      onShowTooltip: (title, description) {
        setState(() {
          _tooltipTitle = title;
          _tooltipDescription = description;
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
        final deckController = ref.read(deckProvider.notifier);
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
          runController,
          deckController,
        );

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
            .resolveEnemyIntent(enemyId, ref.read(runProvider.notifier));
      },
      onStartEnemyTurn: () {
        ref
            .read(combatProvider.notifier)
            .startEnemyTurn(ref.read(runProvider.notifier));
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
      onEnemiesSpawned: () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
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
    final l10n = AppLocalizations.of(context)!;

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
                  if (_showDraft)
                    Positioned.fill(
                      child: DraftScreen(
                        onDraftComplete: () {
                          setState(() {
                            _showDraft = false;
                          });
                          ref.read(runProvider.notifier).completeCurrentNode();
                          Navigator.of(context).pop(); // Retour à la carte
                        },
                      ),
                    ),

                  if (!_showDraft && runState.isDead)
                    Positioned.fill(
                      child: Container(
                        color: Colors.red.withAlpha(230),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.youAreDead,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                    },
                                    child: Text(l10n.mainMenu),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ClassSelectionScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(l10n.changeClass),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Bouton Mon Deck (Haut Droite, à côté de Pause)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      top: 10,
                      right: 75,
                      child: IconButton(
                        icon: const Icon(
                          Icons.style,
                          color: Colors.amber,
                          size: 40,
                        ),
                        tooltip: l10n.myDeck,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeckScreen(allowMerge: false),
                            ),
                          );
                        },
                      ),
                    ),

                  // Bouton Pause (Haut Droite)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      top: 10,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(
                          Icons.pause_circle_outline,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: _showPauseMenu,
                      ),
                    ),

                  // Indicateurs de niveau (Haut Gauche)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      top: 10,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.actLevel(runState.act, runState.currentLevel),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // HUD Bas (Vie + Deck)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: hudHeight,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: hudWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Cristaux de Mana
                                  ManaIndicator(
                                    currentMana: runState.heroStats.currentMana,
                                    maxMana: runState.heroStats.maxMana,
                                  ),
                                  const SizedBox(height: 4),
                                  PlayerHealthBar(
                                    currentPv: runState.heroStats.currentPv,
                                    maxPv: runState.heroStats.maxPv,
                                    armure: runState.heroStats.armure,
                                    effectiveAttaque:
                                        runState.heroStats.effectiveAttaque,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Avertissement "Plus de mana" placé au-dessus du bouton de Fin de Tour
                  if (!runState.isDead && !_showDraft && _showManaWarning)
                    Positioned(
                      right: 20,
                      top: MediaQuery.of(context).size.height / 2 - 85,
                      child: Container(
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withAlpha(245),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.cyanAccent.withAlpha(200),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(150),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.manaWarning,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Bouton Fin de Tour (Milieu Droite)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      right: 20,
                      top: MediaQuery.of(context).size.height / 2 - 25,
                      child: SizedBox(
                        width: 170,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _showManaWarning = false;
                            });
                            TraitSystem.onTurnEnd(
                              ref.read(runProvider.notifier),
                            );
                            ref
                                .read(runProvider.notifier)
                                .applyRelics(RelicTrigger.endOfTurn);
                            ref.read(deckProvider.notifier).discardHand();
                            _game.executeTurn();
                          },
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: Text(
                            l10n.endTurn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Compteur de tour placé juste en dessous du bouton de Fin de Tour
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      right: 20,
                      top: MediaQuery.of(context).size.height / 2 + 33,
                      child: Container(
                        width: 170,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C).withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          l10n.turnCount(_turnCount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                  // Draw Pile (Bas Gauche)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.drawPile(deckState.drawPile.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Discard Pile (Bas Droite)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.discardPile(deckState.discardPile.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Panneau des Status/Buffs du Joueur (Bas Gauche, au-dessus de la Pioche)
                  if (!runState.isDead && !_showDraft)
                    Positioned(
                      bottom: 80,
                      left: 20,
                      child: StatusEffectsPanel(
                        statuses: runState.heroStats.statuses,
                      ),
                    ),

                  // Panneau des Intentions Ennemies (Bas Droite, au-dessus de la Défausse)
                  if (!runState.isDead &&
                      !_showDraft &&
                      combatState.enemies.isNotEmpty)
                    Positioned(
                      bottom: 80,
                      right: 20,
                      child: EnemyIntentsPanel(enemies: combatState.enemies),
                    ),

                  // Phase Banner Overlay (Centre)
                  if (_showPhaseBanner)
                    IgnorePointer(
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 40,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(180),
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: Colors.amber.withAlpha(200),
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            _phaseBannerText ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Tooltip Overlay
                  if (_showTooltip)
                    Positioned(
                      left: 40,
                      right: 40,
                      bottom: 220,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A3D).withAlpha(240),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blueAccent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(100),
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tooltipTitle ?? '',
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(color: Colors.white24),
                              Text(
                                _tooltipDescription ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
