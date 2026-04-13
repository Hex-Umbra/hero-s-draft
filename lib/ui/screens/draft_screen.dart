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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'RÉCOMPENSE DE COMBAT',
              style: TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Choisissez une amélioration pour votre héros',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: choices.map((choice) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: UiCard(
                  title: choice.title,
                  description: choice.description,
                  onTap: () {
                    ref.read(runProvider.notifier).applyHeroStatModifier(
                      maxPvAcc: choice.pvBoost,
                      attackAcc: choice.atkBoost,
                      armorAcc: choice.armorBoost,
                      maxManaAcc: choice.manaBoost,
                    );
                    ref.read(runProvider.notifier).nextLevel();
                    onDraftComplete();
                  },
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
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
