import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../data/models/player_class.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late HerosDraftGame _game;
  bool _showDraft = false;

  @override
  void initState() {
    super.initState();
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
        ref.read(runProvider.notifier).tickCooldown();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    _game.syncState(runState);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          
          if (_showDraft)
            Positioned.fill(
              child: DraftScreen(
                onDraftComplete: () {
                  setState(() { _showDraft = false; });
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
                Text(
                  'Classe : ${runState.heroClass.name}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                    _game.executeTurn();
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Fin de Tour', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            
          // HUD Compétences Spéciales
          if (!runState.isDead && !_showDraft)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildSkillButtons(runState)
            )
        ],
      ),
    );
  }

  Widget _buildSkillButtons(RunState runState) {
    if (runState.heroClass == PlayerClassType.paladin) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'armor_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.blue : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                ref.read(runProvider.notifier).useArmorRestoreSpecial();
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? '+15 Armure' : 'Bouclier (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.shield, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'attack_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.amber : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                ref.read(runProvider.notifier).useAttackBuffSpecial();
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? '+15% PV Max (Dégâts)' : 'Rage (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.flash_on, color: Colors.white),
          ),
        ],
      );
    } else if (runState.heroClass == PlayerClassType.mage) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'aoe_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.purple : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                ref.read(runProvider.notifier).triggerGenericSpecial();
                _game.executeMageAoe();
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? 'Nova (AoE)' : 'Nova (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.blur_circular, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'target_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.deepPurpleAccent : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                if (_game.selectedEnemy != null) {
                  ref.read(runProvider.notifier).triggerGenericSpecial();
                  _game.executeMageTargeted();
                }
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? 'Frappe de Foudre' : 'Frappe (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.electric_bolt, color: Colors.white),
          ),
        ],
      );
    } else {
      // Berserker
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'life_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.redAccent : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                ref.read(runProvider.notifier).useBerserkerLifesteal();
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? 'Vampirisme (3T)' : 'Sangsue (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'pierce_btn',
            backgroundColor: runState.specialCooldown == 0 ? Colors.orange : Colors.grey,
            onPressed: runState.specialCooldown == 0 ? () {
                if (_game.selectedEnemy != null) {
                  ref.read(runProvider.notifier).triggerGenericSpecial();
                  _game.executeBerserkerTargeted();
                }
            } : null,
            label: Text(
              runState.specialCooldown == 0 ? 'Perce-Armure' : 'Brise (CD: ${runState.specialCooldown})',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: const Icon(Icons.broken_image, color: Colors.white),
          ),
        ],
      );
    }
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

