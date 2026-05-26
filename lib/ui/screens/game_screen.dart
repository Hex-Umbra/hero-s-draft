import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sword_icon.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/combat_controller.dart';
import '../../models/combat_state.dart';
import '../../game/services/effect_resolver.dart';
import '../../game/systems/trait_system.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import 'deck_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';
import '../../models/enemy_intent.dart';
import '../../models/status_effect.dart';
import '../../models/map_node.dart';

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

  void _handleCombatVictory() {
    final runState = ref.read(runProvider);
    final currentNodeType = runState.currentNodeType;

    if (currentNodeType == MapNodeType.boss || currentNodeType == MapNodeType.elite) {
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      final relics = gameData.relics;
      if (relics.isNotEmpty) {
        final luck = runState.heroStats.luck;
        final rand = Random().nextDouble() * 100;
        
        final double legChance = 1.0 + luck * 0.5;
        final double epicChance = 5.0 + luck * 1.0;
        final double rareChance = 14.0 + luck * 2.0;
        final double uncommonChance = 20.0 + luck * 3.0;

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
              if (roll < uncommonChance) {
                rarity = RelicRarity.uncommon;
              } else {
                rarity = RelicRarity.common;
              }
            }
          }
        }

        var filtered = relics.where((r) => r.rarity == rarity).toList();
        if (filtered.isEmpty) {
          filtered = relics.where((r) => r.rarity == RelicRarity.common).toList();
          if (filtered.isEmpty) {
            filtered = relics;
          }
        }
        final chosenRelic = filtered[Random().nextInt(filtered.length)];
        ref.read(runProvider.notifier).addRelic(chosenRelic);

        // Display snackbar
        String rarityStr = '';
        Color rarityColor = Colors.grey;
        switch (chosenRelic.rarity) {
          case RelicRarity.common:
            rarityStr = 'COMMUN';
            rarityColor = Colors.grey;
            break;
          case RelicRarity.uncommon:
            rarityStr = 'PEU COMMUN';
            rarityColor = Colors.green;
            break;
          case RelicRarity.rare:
            rarityStr = 'RARE';
            rarityColor = Colors.blueAccent;
            break;
          case RelicRarity.epic:
            rarityStr = 'ÉPIQUE';
            rarityColor = Colors.purpleAccent;
            break;
          case RelicRarity.legendary:
            rarityStr = 'LÉGENDAIRE';
            rarityColor = Colors.amber;
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '👑 RELIQUE OBTENUE : ${chosenRelic.emoji} ${chosenRelic.name} ($rarityStr)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: rarityColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    if (currentNodeType == MapNodeType.elite) {
      final runController = ref.read(runProvider.notifier);
      final rng = Random();
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          runController.gainGold(rng.nextInt(15) + 20);
          runController.nextLevel();
          runController.completeCurrentNode();
          Navigator.of(context).pop(); // Retour à la carte
        }
      });
    } else {
      setState(() {
        _showDraft = true;
      });
    }
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
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      ref.read(combatProvider.notifier).initializeCombat(
        runState.currentLevel,
        runState.currentNodeType,
        gameData.enemies,
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
      onTurnEnded: () {
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
      },
      onPhaseChanged: (phase) {
        _triggerPhaseBanner(
          phase == TurnPhase.player ? 'TOUR JOUEUR' : 'TOUR ENNEMI',
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

        combatController.applyPlayerCardPlay(
          card,
          runController,
          deckController,
        );

        if (runController.currentState.heroStats.currentMana > 0) {
          setState(() {
            _showManaWarning = false;
          });
        } else if (previousMana > 0 && runController.currentState.heroStats.currentMana == 0) {
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
        ref.read(combatProvider.notifier).resolveEnemyIntent(
          enemyId,
          ref.read(runProvider.notifier),
        );
      },
      onStartEnemyTurn: () {
        ref.read(combatProvider.notifier).startEnemyTurn(
          ref.read(runProvider.notifier),
        );
      },
      onEndEnemyTurn: () {
        ref.read(combatProvider.notifier).endEnemyTurn();
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
    final screenWidth = MediaQuery.of(context).size.width;

    ref.listen<CombatState>(combatProvider, (previous, next) {
      if (next.isCombatEnded && next.isVictory) {
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
      final currentNode = runState.mapNodes.firstWhere((n) => n.id == currentNodeId);
      isCompleted = currentNode.isCompleted;
    } catch (_) {}

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
                            const Text(
                              'VOUS ÊTES MORT',
                              style: TextStyle(
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
                                  child: const Text('Menu Principal'),
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
                                  child: const Text('Changer de Classe'),
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
                      tooltip: 'Mon Deck',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DeckScreen(
                              allowMerge: false,
                            ),
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
                      onPressed: () {
                        _showPauseMenu();
                      },
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
                          'Acte ${runState.act} - Niveau : ${runState.currentLevel}',
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
                      height: 88,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                                                SizedBox(
                            width: screenWidth * 0.52, // Élargi pour accueillir les stats sans tasser la barre de vie
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Cristaux de Mana
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                      runState.heroStats.maxMana, (index) {
                                    final isActive =
                                        index < runState.heroStats.currentMana;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4.0),
                                      child: Icon(
                                        Icons.diamond,
                                        color: isActive
                                            ? Colors.cyanAccent
                                            : Colors.white24,
                                        size: 24,
                                        shadows: isActive
                                            ? [
                                                const Shadow(
                                                  color: Colors.cyanAccent,
                                                  blurRadius: 8,
                                                )
                                              ]
                                            : null,
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final totalAttack = runState.heroStats.effectiveAttaque;
                                    final currentArmor = runState.heroStats.armure;

                                    return Row(
                                      children: [
                                        // 1. Stats à gauche (alignés à droite pour s'accoler à la barre de vie)
                                        Expanded(
                                          flex: 1,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Dégâts d'Attaque (Rouge Gradient, sans fond)
                                                ShaderMask(
                                                  shaderCallback: (bounds) => const LinearGradient(
                                                    colors: [
                                                      Color(0xFFFF2A2A),
                                                      Color(0xFFFF7A7A),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ).createShader(bounds),
                                                  blendMode: BlendMode.srcIn,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const SwordIcon(size: 20, color: Colors.white),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$totalAttack',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 14),

                                                // Armure (Bleu Gradient, sans fond, toujours affiché)
                                                ShaderMask(
                                                  shaderCallback: (bounds) => const LinearGradient(
                                                    colors: [
                                                      Color(0xFF2196F3),
                                                      Color(0xFF00E5FF),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ).createShader(bounds),
                                                  blendMode: BlendMode.srcIn,
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.shield, color: Colors.white, size: 20),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '$currentArmor',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 14), // Espacement avec la barre de vie
                                              ],
                                            ),
                                          ),
                                        ),

                                        // 2. Barre de vie progressive centrée (Largeur fixe de 26% de l'écran)
                                        SizedBox(
                                          width: screenWidth * 0.26,
                                          child: Container(
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.white.withAlpha(50),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Stack(
                                                children: [
                                                   // Remplissage PV (Vert - Core interne avec padding)
                                                   if (runState.heroStats.maxPv > 0 &&
                                                       runState.heroStats.currentPv > 0)
                                                     FractionallySizedBox(
                                                       alignment: Alignment.centerLeft,
                                                       widthFactor: (runState.heroStats.currentPv /
                                                               runState.heroStats.maxPv)
                                                           .clamp(0.0, 1.0),
                                                       heightFactor: 1.0,
                                                       child: Padding(
                                                         padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 1.5),
                                                         child: Container(
                                                           decoration: BoxDecoration(
                                                             borderRadius: BorderRadius.circular(8),
                                                             gradient: const LinearGradient(
                                                               colors: [
                                                                 Color(0xFF1E824C), // Vert forêt foncé
                                                                 Color(0xFF27AE60), // Vert éclatant
                                                                 Color(0xFF58D68D), // Vert doux / menthe
                                                               ],
                                                               begin: Alignment.centerLeft,
                                                               end: Alignment.centerRight,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),
                                                   // Remplissage Armure (Bleu Translucide - Englobant avec 0.5px de padding)
                                                   if (currentArmor > 0 && runState.heroStats.maxPv > 0)
                                                     FractionallySizedBox(
                                                       alignment: Alignment.centerLeft,
                                                       widthFactor: (currentArmor / runState.heroStats.maxPv)
                                                           .clamp(0.0, 1.0),
                                                       heightFactor: 1.0,
                                                       child: Padding(
                                                         padding: const EdgeInsets.symmetric(vertical: 0.5, horizontal: 0.5),
                                                         child: Container(
                                                           decoration: BoxDecoration(
                                                             gradient: LinearGradient(
                                                               colors: [
                                                                 Colors.blueAccent.withValues(alpha: 0.45),
                                                                 Colors.lightBlueAccent.withValues(alpha: 0.65),
                                                               ],
                                                               begin: Alignment.centerLeft,
                                                               end: Alignment.centerRight,
                                                             ),
                                                             borderRadius: BorderRadius.circular(10),
                                                             border: Border.all(
                                                               color: Colors.cyanAccent.withValues(alpha: 0.7),
                                                               width: 1.0,
                                                             ),
                                                           ),
                                                         ),
                                                       ),
                                                     ),
                                                  // Texte des PV
                                                  Center(
                                                    child: Text(
                                                      '${runState.heroStats.currentPv} / ${runState.heroStats.maxPv} PV',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        shadows: [
                                                          Shadow(
                                                            color: Colors.black54,
                                                            offset: Offset(1, 1),
                                                            blurRadius: 2,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 3. Espaceur symétrique à droite (pour garantir le centrage parfait de la barre de vie)
                                        const Expanded(
                                          flex: 1,
                                          child: SizedBox(),
                                        ),
                                      ],
                                    );
                                  },
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
                      child: const Text(
                        "Plus de mana.\nTerminer le tour ?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _showManaWarning = false;
                          });
                          TraitSystem.onTurnEnd(ref.read(runProvider.notifier));
                          ref.read(runProvider.notifier).applyRelics(RelicTrigger.endOfTurn);
                          ref.read(deckProvider.notifier).discardHand();
                          _game.executeTurn();
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Fin de Tour',
                          style: TextStyle(
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
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Tour $_turnCount",
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
                        'Pioche: ${deckState.drawPile.length}',
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
                        'Défausse: ${deckState.discardPile.length}',
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
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C).withAlpha(240),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.cyanAccent.withAlpha(100),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.offline_bolt,
                                color: Colors.cyanAccent,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "EFFETS DU JOUEUR",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 12),
                          if (runState.heroStats.statuses.isEmpty)
                            const Text(
                              "Aucun effet actif",
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            ...runState.heroStats.statuses.map((status) {
                              IconData icon;
                              Color color;
                              String label;

                              switch (status.id) {
                                case 'strength':
                                  icon = Icons.flash_on;
                                  color = Colors.orangeAccent;
                                  label = 'Attaque : +${status.value}';
                                  break;
                                case 'poison':
                                  icon = Icons.sick;
                                  color = const Color(0xFF69F0AE);
                                  label = 'Poison : ${status.value}';
                                  break;
                                case 'metallicize':
                                  icon = Icons.shield;
                                  color = Colors.cyanAccent;
                                  label = 'Métallisation : +${status.value}';
                                  break;
                                default:
                                  icon = status.type == StatusType.buff
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward;
                                  color = status.type == StatusType.buff
                                      ? Colors.greenAccent
                                      : Colors.redAccent;
                                  label = '${status.name} : ${status.value}';
                                  break;
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(icon, color: color, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              label,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${status.duration} trs',
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),

                // Panneau des Intentions Ennemies (Bas Droite, au-dessus de la Défausse)
                if (!runState.isDead && !_showDraft && combatState.enemies.isNotEmpty)
                  Positioned(
                    bottom: 80,
                    right: 20,
                    child: Container(
                      width: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C).withAlpha(240),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amberAccent.withAlpha(100),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: Colors.amberAccent,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "INTENTIONS ENNEMIES",
                                style: TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 12),
                          ...combatState.enemies.map((enemy) {
                            final intent = enemy.effectiveIntent;
                            final name = enemy.data.name;
                            
                            Widget intentWidget;
                            if (intent == null) {
                              intentWidget = Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(30),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.hourglass_empty,
                                        color: Colors.white30, size: 14),
                                    SizedBox(width: 6),
                                    Text(
                                      "En attente...",
                                      style: TextStyle(
                                        color: Colors.white30,
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              IconData icon;
                              Color color;
                              String label;

                              switch (intent.type) {
                                case IntentType.attack:
                                  if (intent.value >= 20) {
                                    icon = Icons.gavel;
                                    color = const Color(0xFFC0392B); // Crimson profond
                                    label = 'Attaque Dévastatrice : ${intent.value}';
                                  } else if (intent.value >= 12) {
                                    icon = Icons.whatshot;
                                    color = const Color(0xFFE74C3C); // Écarlate
                                    label = 'Attaque Lourde : ${intent.value}';
                                  } else if (intent.value >= 6) {
                                    icon = Icons.flash_on;
                                    color = const Color(0xFFFF7675); // Corail
                                    label = 'Attaque : ${intent.value}';
                                  } else {
                                    icon = Icons.bolt;
                                    color = const Color(0xFFF39C12); // Ambre/Orange
                                    label = 'Attaque Rapide : ${intent.value}';
                                  }
                                  break;
                                case IntentType.defend:
                                  icon = Icons.shield;
                                  color = const Color(0xFF448AFF);
                                  label = 'Défense : +${intent.value}';
                                  break;
                                case IntentType.buff:
                                  icon = Icons.trending_up;
                                  color = const Color(0xFFE040FB);
                                  label = 'Buff Attaque : +${intent.value}';
                                  break;
                                case IntentType.debuffDeck:
                                  icon = Icons.sick;
                                  color = const Color(0xFF69F0AE);
                                  label = 'Malédiction : ${intent.value}';
                                  break;
                              }

                              intentWidget = Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: color.withAlpha(60),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, color: color, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: enemy.isBoss ? Colors.amberAccent : Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${enemy.stats.currentPv}/${enemy.stats.maxPv} PV',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  intentWidget,
                                  if (enemy != combatState.enemies.last)
                                    const Divider(color: Colors.white10, height: 12),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
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
    ),);
  }

  void _showPauseMenu() {
    _game.pauseEngine();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: const Text(
            'PAUSE',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {
                  // Ferme le dialog
                  Navigator.of(context).pop();
                  // Revient au premier écran (Menu Principal)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Retour au Menu Principal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Reprendre le Combat',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      // Reprend le moteur de jeu peu importe comment on quitte le menu
      _game.resumeEngine();
    });
  }
}
