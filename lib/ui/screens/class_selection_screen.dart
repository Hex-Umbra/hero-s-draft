import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../game/controllers/run_controller.dart';
import 'game_screen.dart';

class ClassSelectionScreen extends ConsumerWidget {
  const ClassSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Les données sont déjà chargées par le SplashScreen
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classes = gameData.heroes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez votre Classe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: classes.map((c) => _buildClassCard(context, ref, c)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, WidgetRef ref, HeroData playerClass) {
    Color classColor = Colors.blue;
    if (playerClass.id == 'berserker') classColor = Colors.red;
    if (playerClass.id == 'mage') classColor = Colors.purple;

    IconData icon = Icons.person;
    // On pourrait utiliser playerClass.iconPath plus tard
    if (playerClass.id == 'paladin') icon = Icons.shield;
    if (playerClass.id == 'berserker') icon = Icons.whatshot;
    if (playerClass.id == 'mage') icon = Icons.auto_fix_high;

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        color: const Color(0xFF2A2A3D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: classColor, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: classColor),
              const SizedBox(height: 20),
              Text(
                playerClass.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: classColor),
              ),
              const SizedBox(height: 10),
              Text(
                'PV: ${playerClass.maxHp}\n'
                'Mana: ${playerClass.maxMana}\n'
                'Attaque: ${playerClass.baseDamage}\n'
                'Armure: ${playerClass.baseArmor}\n',
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const Divider(color: Colors.white24, height: 30),
              Expanded(
                child: Text(
                  playerClass.description,
                  style: const TextStyle(fontSize: 14, color: Colors.white70, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: classColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  ref.read(runProvider.notifier).startNewRun(playerClass);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const GameScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: const Text('Sélectionner', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
