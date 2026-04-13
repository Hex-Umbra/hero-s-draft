import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/heros_draft_game.dart';
import '../../game/controllers/run_controller.dart';
import '../../data/models/player_class.dart';
import 'draft_screen.dart';

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
                       ElevatedButton(
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                         onPressed: () {
                           ref.read(runProvider.notifier).startNewRun(PlayerClass.paladin);
                           _game.resetEnemies();
                         },
                         child: const Text('Recommencer la Run'),
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
                    'BUFF ATTAQUE (+25%) - Reste ${runState.attackBuffDuration} tour(s)',
                    style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
              ],
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
              child: Column(
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
                      runState.specialCooldown == 0 ? '+25% Attaque' : 'Rage (CD: ${runState.specialCooldown})',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)
                    ),
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                  ),
                ],
              )
            )
        ],
      ),
    );
  }
}

