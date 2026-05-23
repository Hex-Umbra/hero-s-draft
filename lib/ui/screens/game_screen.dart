import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sword_icon.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/effect_resolver.dart';
import '../../game/systems/trait_system.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import 'deck_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/enemy_intent.dart';
import '../../models/status_effect.dart';

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

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final deck = ref.read(deckProvider);

      // Initialisation du starter deck si c'est le début de la run
      if (deck.masterDeck.isEmpty) {
        final gameData = ref.read(gameDataLoaderProvider).requireValue;

        // On récupère les cartes par ID depuis les données JSON
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

      // On initialise toujours le combat quand on arrive sur l'écran
      ref.read(runProvider.notifier).startCombat();
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
      onEnemiesDead: () {
        setState(() {
          _showDraft = true;
        });
      },
      onEnemyDebuffDeck: (count) {
        // Logique retirée car la carte "Blessure" de test a été supprimée
      },
      onTurnEnded: () {
        setState(() {
          _showManaWarning = false;
          _turnCount++;
        });
        ref.read(runProvider.notifier).startTurn();
        ref.read(deckProvider.notifier).drawCards(5);
      },
      onPhaseChanged: (phase) {
        _triggerPhaseBanner(
          phase == TurnPhase.player ? 'TOUR JOUEUR' : 'TOUR ENNEMI',
        );
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
        final previousMana = runController.currentState.heroStats.currentMana;

        // 1. VÃ©rification si la carte peut Ãªtre jouÃ©e
        if (!EffectResolver.canPlayCard(
          card,
          runController.currentState,
          target,
        )) {
          return false; // Pas assez de mana ou cible invalide
        }

        // 2. Animation du hÃ©ros selon le type de carte
        if (card.data.type == CardType.attack) {
          _game.heroCard?.dashAnimation();
        } else {
          // DÃ©terminer le type d'icÃ´ne (dÃ©fense ou buff gÃ©nÃ©rique)
          bool hasArmor = card.data.effects.any((e) => e.type == 'armor');
          _game.heroCard?.buffAnimation(hasArmor ? 'defend' : 'buff');
        }

        // 3. RÃ©solution via EffectResolver
        bool success = EffectResolver.resolveCard(
          card,
          runController,
          deckController,
          _game.enemyCards,
          target,
        );

        if (success) {
          // Nettoyage des ennemis morts
          for (var enemy in _game.enemyCards.toList()) {
            if (enemy.stats.currentPv <= 0) {
              enemy.removeFromParent();
              _game.enemyCards.remove(enemy);
              if (_game.selectedEnemy == enemy) _game.selectedEnemy = null;
            }
          }

          // Dire au DeckNotifier que la carte est jouée
          ref.read(deckProvider.notifier).playCard(card);
          
          // Déclencher les traits passifs
          TraitSystem.onCardPlayed(runController, card);

          if (_game.enemyCards.isEmpty) {
            _game.onEnemiesDead();
            _game.currentPhase = TurnPhase.player;
          } else {
            if (runController.currentState.heroStats.currentMana > 0) {
              setState(() {
                _showManaWarning = false;
              });
            } else if (previousMana > 0 && runController.currentState.heroStats.currentMana == 0) {
              // Demander s'il veut finir son tour après un court délai (pour laisser les animations se faire)
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted &&
                    _game.enemyCards.isNotEmpty &&
                    ref.read(runProvider).heroStats.currentMana == 0) {
                  setState(() {
                    _showManaWarning = true;
                  });
                }
              });
            }
          }
        }

        return success;
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
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final screenWidth = MediaQuery.of(context).size.width;

    _game.availableEnemies = gameData.enemies;
    _game.availableHeroes = gameData.heroes;
    _game.syncState(runState);
    _game.syncDeck(deckState);

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
                          // Barre de Vie et Mana (Centrée)
                          SizedBox(
                            width: screenWidth * 0.4, // 40% de la largeur
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
                                    int bonusAttack = 0;
                                    try {
                                      bonusAttack = _game.heroCard?.bonusAttack ?? 0;
                                    } catch (_) {}
                                    final totalAttack = runState.heroStats.effectiveAttaque + bonusAttack;
                                    final currentArmor = runState.heroStats.armure;

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // 1. Badge d'Attaque (Orange)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.orangeAccent.withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.orange.withValues(alpha: 0.5),
                                              width: 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(50),
                                                blurRadius: 4,
                                                offset: const Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const SwordIcon(size: 14, color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$totalAttack',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // 2. Badge d'Armure (Bleu, toujours affiché)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withValues(alpha: 0.95),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: Colors.cyanAccent.withValues(alpha: 0.5),
                                              width: 1.0,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withAlpha(50),
                                                blurRadius: 4,
                                                offset: const Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.shield, color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$currentArmor',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // 3. Barre de vie progressive avec superposition d'armure
                                        Expanded(
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
                                                  // Remplissage PV (Vert)
                                                  if (runState.heroStats.maxPv > 0 &&
                                                      runState.heroStats.currentPv > 0)
                                                    FractionallySizedBox(
                                                      alignment: Alignment.centerLeft,
                                                      widthFactor: (runState.heroStats.currentPv /
                                                              runState.heroStats.maxPv)
                                                          .clamp(0.0, 1.0),
                                                      heightFactor: 1.0,
                                                      child: Container(
                                                        decoration: const BoxDecoration(
                                                          gradient: LinearGradient(
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
                                                  // Remplissage Armure (Bleu Translucide, se superpose)
                                                  if (currentArmor > 0 && runState.heroStats.maxPv > 0)
                                                    FractionallySizedBox(
                                                      alignment: Alignment.centerLeft,
                                                      widthFactor: (currentArmor / runState.heroStats.maxPv)
                                                          .clamp(0.0, 1.0),
                                                      heightFactor: 1.0,
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.blueAccent.withValues(alpha: 0.4),
                                                              Colors.lightBlueAccent.withValues(alpha: 0.6),
                                                            ],
                                                            begin: Alignment.centerLeft,
                                                            end: Alignment.centerRight,
                                                          ),
                                                          border: const Border(
                                                            right: BorderSide(
                                                              color: Colors.cyanAccent,
                                                              width: 2.0,
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
                if (!runState.isDead && !_showDraft && _game.enemyCards.isNotEmpty)
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
                          ..._game.enemyCards.map((enemy) {
                            final intent = enemy.effectiveIntent;
                            final name = enemy.data?.name ?? 'Ennemi';
                            
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
                                  if (enemy != _game.enemyCards.last)
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
