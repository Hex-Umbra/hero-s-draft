import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';

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
      if (deck.masterDeck.isEmpty) {
        final starterCards = [
          CardInstance(data: CardData(id: 'strike_1', name: 'Frappe', description: 'Inflige 5 dégâts', cost: 1, type: CardType.attack, category: CardCategory.global, rarity: CardRarity.common, target: CardTarget.singleEnemy, effects: [CardEffect(type: 'damage', value: 5)])),
          CardInstance(data: CardData(id: 'strike_2', name: 'Frappe', description: 'Inflige 5 dégâts', cost: 1, type: CardType.attack, category: CardCategory.global, rarity: CardRarity.common, target: CardTarget.singleEnemy, effects: [CardEffect(type: 'damage', value: 5)])),
          CardInstance(data: CardData(id: 'defend_1', name: 'Défense', description: 'Gagne 5 Armure', cost: 1, type: CardType.skill, category: CardCategory.global, rarity: CardRarity.common, target: CardTarget.none, effects: [CardEffect(type: 'armor', value: 5)])),
          CardInstance(data: CardData(id: 'defend_2', name: 'Défense', description: 'Gagne 5 Armure', cost: 1, type: CardType.skill, category: CardCategory.global, rarity: CardRarity.common, target: CardTarget.none, effects: [CardEffect(type: 'armor', value: 5)])),
          CardInstance(data: CardData(id: 'heal_1', name: 'Soin', description: 'Soigne 5 PV', cost: 2, type: CardType.skill, category: CardCategory.global, rarity: CardRarity.uncommon, target: CardTarget.none, effects: [CardEffect(type: 'heal', value: 5)])),
        ];
        ref.read(deckProvider.notifier).initializeStarterDeck(starterCards);
        ref.read(deckProvider.notifier).initializeCombat();
        ref.read(deckProvider.notifier).drawCards(5);
      }
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
        // Validation basique (mana)
        final runState = ref.read(runProvider);
        if (runState.heroStats.currentMana < card.currentCost) return false;
        
        // Validation cible
        if (card.data.target == CardTarget.singleEnemy && target == null) return false;

        // Résolution des effets
        ref.read(runProvider.notifier).consumeResource(mana: card.currentCost);
        
        // Animation du héros selon le type de carte
        if (card.data.type == CardType.attack) {
          _game.heroCard?.dashAnimation();
        } else {
          // Déterminer le type d'icône (défense ou buff générique)
          bool hasArmor = card.data.effects.any((e) => e.type == 'armor');
          _game.heroCard?.buffAnimation(hasArmor ? 'defend' : 'buff');
        }

        for (var effect in card.data.effects) {
          if (effect.type == 'damage') {
             if (card.data.target == CardTarget.singleEnemy && target != null) {
                target.updateStats(target.stats.takeDamage(effect.value + runState.effectiveAttaque));
                if (target.stats.currentPv <= 0) {
                   target.removeFromParent();
                   _game.enemyCards.remove(target);
                   if (_game.selectedEnemy == target) _game.selectedEnemy = null;
                }
             } else if (card.data.target == CardTarget.allEnemies) {
                for (var enemy in _game.enemyCards.toList()) {
                   enemy.updateStats(enemy.stats.takeDamage(effect.value + runState.effectiveAttaque));
                   if (enemy.stats.currentPv <= 0) {
                      enemy.removeFromParent();
                      _game.enemyCards.remove(enemy);
                      if (_game.selectedEnemy == enemy) _game.selectedEnemy = null;
                   }
                }
             }
          } else if (effect.type == 'armor') {
             final currentArmor = ref.read(runProvider).heroStats.armure;
             ref.read(runProvider.notifier).setHeroStats(armure: currentArmor + effect.value);
          } else if (effect.type == 'heal') {
             ref.read(runProvider.notifier).heal(effect.value);
          } else if (effect.type == 'draw') {
             ref.read(deckProvider.notifier).drawCards(effect.value);
          }
        }
        
        // Dire au DeckNotifier que la carte est jouée
        ref.read(deckProvider.notifier).playCard(card);
        
        if (_game.enemyCards.isEmpty) {
           _game.onEnemiesDead();
           _game.currentPhase = TurnPhase.player;
        }

        return true;
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
    
    _game.availableEnemies = gameData.enemies;
    _game.syncState(runState);
    _game.syncDeck(deckState);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          
          if (_showDraft)
            Positioned.fill(
              child: DraftScreen(
                onDraftComplete: () {
                  setState(() { _showDraft = false; });
                  ref.read(deckProvider.notifier).initializeCombat();
                  ref.read(deckProvider.notifier).drawCards(5);
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

          Positioned(
            top: 40,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Niveau actuel : ${runState.currentLevel}',
                  style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (runState.attackBuffDuration > 0)
                  Text(
                    'BUFF RAGE (+15% PV Max) - Reste ${runState.attackBuffDuration} tour(s)',
                    style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          
          // Bouton Pause (en haut à droite)
          if (!runState.isDead && !_showDraft)
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.pause_circle_outline, color: Colors.white, size: 40),
                onPressed: () {
                  _showPauseMenu();
                },
              ),
            ),
          
          // HUD Fin de Tour
          if (!runState.isDead && !_showDraft)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
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
          // Draw Pile
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
            
          // Discard Pile
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

          // Phase Banner Overlay
          if (_showPhaseBanner)
            Positioned.fill(
              child: IgnorePointer(
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
