import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import 'draft_screen.dart';
import 'class_selection_screen.dart';
import '../../services/game_data_service.dart';
import '../../models/data/skill_data.dart';
import '../../models/data/game_data_registry.dart';

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
        ref.read(runProvider.notifier).startTurn();
        ref.read(deckProvider.notifier).drawCards(5);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    
    _game.availableEnemies = gameData.enemies;
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
            
          // HUD Compétences Spéciales
          if (!runState.isDead && !_showDraft)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildSkillButtons(runState, gameData)
            )
        ],
      ),
    );
  }

  Widget _buildSkillButtons(RunState runState, GameDataRegistry gameData) {
    var heroSkills = gameData.skills.where((SkillData s) => s.id.startsWith(runState.heroClassId)).toList();
    
    if (heroSkills.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heroSkills.asMap().entries.map((entry) {
        int index = entry.key;
        var skill = entry.value;

        int cd = index == 0 ? runState.skill1Cooldown : runState.skill2Cooldown;
        bool canCast = cd == 0;
        
        if (skill.effectType == 'lifesteal_buff') {
           int hpCost = (runState.heroStats.currentPv * 0.1).round();
           if (hpCost < 1) hpCost = 1;
           if (runState.heroStats.currentPv <= hpCost) canCast = false;
        } else {
           if (runState.heroStats.currentMana < skill.manaCost) canCast = false;
        }

        if ((skill.effectType == 'damage_targeted' || skill.effectType == 'damage_pierce') && _game.selectedEnemy == null) {
            canCast = false;
        }

        Color btnColor = Colors.blueAccent;
        if (runState.heroClassId == 'berserker') btnColor = Colors.redAccent;
        if (runState.heroClassId == 'mage') btnColor = Colors.purple;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FloatingActionButton.extended(
            heroTag: 'skill_${skill.id}',
            backgroundColor: canCast ? btnColor : Colors.grey,
            onPressed: canCast ? () {
                bool triggered = false;
                if (index == 0) {
                    triggered = ref.read(runProvider.notifier).triggerGenericSkill1(
                        cd: skill.effectType == 'lifesteal_buff' ? 4 : 2, 
                        mana: skill.manaCost,
                        hpPercent: skill.effectType == 'lifesteal_buff' ? 10 : 0
                    );
                } else {
                    triggered = ref.read(runProvider.notifier).triggerGenericSkill2(
                        cd: 4, 
                        mana: skill.manaCost
                    );
                }
                
                if (triggered) {
                    _game.executeSkill(
                        skill,
                        onTriggerAttackBuff: () {
                            ref.read(runProvider.notifier).applyAttackBuff(skill.effectValue);
                        },
                        onTriggerLifesteal: () {
                            ref.read(runProvider.notifier).applyLifestealBuff(skill.effectValue);
                        }
                    );
                }
            } : null,
            label: Text(
              cd == 0 ? '${skill.name} (${skill.manaCost > 0 ? '${skill.manaCost} Mana' : 'Coût PV'})' : '${skill.name} (CD: $cd)',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
            ),
            icon: Icon(skill.effectType.contains('damage') ? Icons.flash_on : Icons.shield, color: Colors.white),
          ),
        );
      }).toList(),
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

