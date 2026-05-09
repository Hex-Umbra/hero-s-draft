import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/data/hero_data.dart';
import '../../services/game_data_service.dart';
import '../../game/controllers/run_controller.dart';
import 'map_screen.dart';
import 'card_dictionary_screen.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Dictionnaire des cartes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CardDictionaryScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400, // Largeur max d'une carte
              childAspectRatio: 0.75, // Ajustement de l'aspect ratio pour la verticalité
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              return _buildClassCard(context, ref, classes[index]);
            },
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
    if (playerClass.id == 'paladin') icon = Icons.shield;
    if (playerClass.id == 'berserker') icon = Icons.whatshot;
    if (playerClass.id == 'mage') icon = Icons.auto_fix_high;

    return Card(
      color: const Color(0xFF2A2A3D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: classColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 60, color: classColor),
            const SizedBox(height: 10),
            Text(
              playerClass.name,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: classColor),
            ),
            const SizedBox(height: 10),
            Text(
              'PV: ${playerClass.maxHp} | Mana: ${playerClass.maxMana}\n'
              'ATK: ${playerClass.baseDamage} | DEF: ${playerClass.baseArmor}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
              ),
              const Divider(color: Colors.white24, height: 20),
              Expanded(
              child: SingleChildScrollView(
                child: Text(
                  playerClass.description,
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: classColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
              onPressed: () {
                ref.read(runProvider.notifier).startNewRun(playerClass);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                  (route) => route.isFirst,
                );
              },
              child: const Text('Sélectionner', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
