import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/effect_resolver.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/relic_data.dart';

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
          CardInstance(data: gameData.cards.firstWhere((c) => c.id == 'strike_basic')),
          CardInstance(data: gameData.cards.firstWhere((c) => c.id == 'defend_basic')),
          CardInstance(data: gameData.cards.firstWhere((c) => c.id == 'demon_form')),
          CardInstance(data: gameData.cards.firstWhere((c) => c.id == 'metallicize')),
          CardInstance(data: gameData.cards.firstWhere((c) => c.id == 'poison_stab')),
        ];

        // Ajout d'une relique de test
        ref.read(runProvider.notifier).addRelic(const RelicData(
          id: 'test_relic',
          name: 'Calendrier de Pierre',
          description: 'Au début du combat, gagne 6 Armure.',
          trigger: RelicTrigger.startOfCombat,
          effectType: 'gain_armor',
          value: 6,
        ));

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
        ref.read(runProvider.notifier).setHeroStats(armure: currentArmor + armor);
      },
      onEnemiesDead: () {
        setState(() {
          _showDraft = true;
        });
      },
      onEnemyDebuffDeck: (count) {
        final card = CardInstance(data: const CardData(id: 'injury', name: 'Blessure', description: 'Injouable.', cost: 99, type: CardType.status, category: CardCategory.global, rarity: CardRarity.common, target: CardTarget.none, effects: []));
        for (int i = 0; i < count; i++) {
          ref.read(deckProvider.notifier).addCardToDiscardPile(CardInstance(data: card.data)); // Nouvelle instance
        }
      },
      onTurnEnded: () {
        ref.read(runProvider.notifier).startTurn();
        ref.read(deckProvider.notifier).drawCards(5);
      },
      onPhaseChanged: (phase) {
        _triggerPhaseBanner(phase == TurnPhase.player ? 'TOUR JOUEUR' : 'TOUR ENNEMI');
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
        
        // 1. Vérification si la carte peut être jouée
        if (!EffectResolver.canPlayCard(card, runController.currentState, target)) {
          return false; // Pas assez de mana ou cible invalide
        }

        // 2. Animation du héros selon le type de carte
        if (card.data.type == CardType.attack) {
          _game.heroCard?.dashAnimation();
        } else {
          // Déterminer le type d'icône (défense ou buff générique)
          bool hasArmor = card.data.effects.any((e) => e.type == 'armor');
          _game.heroCard?.buffAnimation(hasArmor ? 'defend' : 'buff');
        }

        // 3. Résolution via EffectResolver
        bool success = EffectResolver.resolveCard(
          card,
          runController,
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
          
          if (_game.enemyCards.isEmpty) {
            _game.onEnemiesDead();
            _game.currentPhase = TurnPhase.player;
          }
        }

        return success;
      }
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
    _game.syncState(runState);
    _game.syncDeck(deckState);

    return Scaffold(
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
                        setState(() { _showDraft = false; });
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
                             const Text('VOUS ÊTES MORT', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                             const SizedBox(height: 20),
                             Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                                   onPressed: () {
                                     Navigator.of(context).popUntil((route) => route.isFirst);
                                   },
                                   child: const Text('Menu Principal'),
                                 ),
                                 const SizedBox(width: 10),
                                 ElevatedButton(
                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                                   onPressed: () {
                                     Navigator.of(context).pushReplacement(
                                       MaterialPageRoute(builder: (context) => const ClassSelectionScreen()),
                                     );
                                   },
                                   child: const Text('Changer de Classe'),
                                 ),
                               ]
                             )
                          ],
                        ),
                      ),
                    )
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
                          'Niveau actuel : ${runState.currentLevel}',
                          style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        // Affichage simplifié des statuts du joueur
                        ...runState.heroStats.statuses.map((s) => Text(
                          s.duration > 90 
                              ? '${s.name} : ${s.value} (Permanent)'
                              : '${s.name} : ${s.value} (${s.duration} tours)',
                          style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                        )),
                      ],
                    ),
                  ),
                
                // Bouton Pause (Haut Droite)
                if (!runState.isDead && !_showDraft)
                  Positioned(
                    top: 10,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.pause_circle_outline, color: Colors.white, size: 40),
                      onPressed: () {
                        _showPauseMenu();
                      },
                    ),
                  ),
                  
                // Barre de Vie du Joueur (Bas Centre)
                if (!runState.isDead && !_showDraft)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: SizedBox(
                        width: screenWidth * 0.3, // 30% de la largeur
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${runState.heroStats.currentPv} / ${runState.heroStats.maxPv} PV',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: (runState.heroStats.maxPv > 0) 
                                    ? runState.heroStats.currentPv / runState.heroStats.maxPv 
                                    : 0,
                                minHeight: 12,
                                backgroundColor: Colors.black54,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF27AE60)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Bouton Fin de Tour (Milieu Droite)
                if (!runState.isDead && !_showDraft)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          ref.read(deckProvider.notifier).discardHand();
                          _game.executeTurn();
                        },
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('Fin de Tour', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                      decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(8)),
                      child: Text('Pioche: ${deckState.drawPile.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                // Discard Pile (Bas Droite)
                if (!runState.isDead && !_showDraft)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: Text('Défausse: ${deckState.discardPile.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),

                // Phase Banner Overlay (Centre)
                if (_showPhaseBanner)
                  IgnorePointer(
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          border: Border.symmetric(horizontal: BorderSide(color: Colors.amber.withAlpha(200), width: 2)),
                        ),
                        child: Text(
                          _phaseBannerText ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
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
                          border: Border.all(color: Colors.blueAccent, width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 10, spreadRadius: 5),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tooltipTitle ?? '',
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Divider(color: Colors.white24),
                            Text(
                              _tooltipDescription ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
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
    );
  }

  void _showPauseMenu() {
    _game.pauseEngine();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: const Text('PAUSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                child: const Text('Retour au Menu Principal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Reprendre le Combat', style: TextStyle(color: Colors.white70)),
              )
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
