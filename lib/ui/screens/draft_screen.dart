import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../widgets/ui_card.dart';

class DraftScreen extends ConsumerWidget {
  final VoidCallback onDraftComplete;

  const DraftScreen({super.key, required this.onDraftComplete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = _generateChoices();

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isPortrait = constraints.maxWidth < 600;

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RÉCOMPENSE DE COMBAT',
                      style: TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Choisissez une amélioration pour votre héros',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    if (isPortrait)
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: choices.map((choice) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                            child: UiCard(
                              title: choice.title,
                              description: choice.description,
                              onTap: () => _onChoiceSelected(ref, choice),
                            ),
                          )).toList(),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: choices.map((choice) => Flexible(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 200),
                              child: UiCard(
                                title: choice.title,
                                description: choice.description,
                                onTap: () => _onChoiceSelected(ref, choice),
                              ),
                            ),
                          ),
                        )).toList(),
                      ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  void _onChoiceSelected(WidgetRef ref, _DraftChoice choice) {
    final runController = ref.read(runProvider.notifier);
    runController.applyHeroStatModifier(
      maxPvAcc: choice.pvBoost,
      attackAcc: choice.atkBoost,
      armorAcc: choice.armorBoost,
      maxManaAcc: choice.manaBoost,
    );
    
    // Récompense en or aléatoire
    final rng = Random();
    runController.gainGold(rng.nextInt(15) + 10);
    
    // On avance d'un niveau (optionnel selon si on veut que currentLevel = nombre de combats)
    runController.nextLevel();
    
    onDraftComplete();
  }

  List<_DraftChoice> _generateChoices() {
    final rng = Random();
    return List.generate(3, (index) {
        int type = rng.nextInt(4);
        if (type == 0) return _DraftChoice('Vitalité', '+15 PV Max', 15, 0, 0, 0);
        if (type == 1) return _DraftChoice('Aiguisage', '+5 Attaque', 0, 5, 0, 0);
        if (type == 2) return _DraftChoice('Plaque de Fer', '+10 Armure', 0, 0, 10, 0);
        return _DraftChoice('Sagesse', '+5 Mana Max', 0, 0, 0, 5);
    });
  }
}

class _DraftChoice {
  final String title;
  final String description;
  final int pvBoost;
  final int atkBoost;
  final int armorBoost;
  final int manaBoost;

  _DraftChoice(this.title, this.description, this.pvBoost, this.atkBoost, this.armorBoost, this.manaBoost);
}
