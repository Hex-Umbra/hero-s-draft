import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
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
                              onTap: () => _onChoiceSelected(context, ref, choice),
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
                                onTap: () => _onChoiceSelected(context, ref, choice),
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

  void _finishDraft(WidgetRef ref) {
    final runController = ref.read(runProvider.notifier);
    final rng = Random();
    runController.gainGold(rng.nextInt(15) + 10);
    runController.nextLevel();
    onDraftComplete();
  }

  void _showCloneModal(BuildContext context, WidgetRef ref) {
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);
    
    // Choisir 3 cartes aléatoires
    masterDeck.shuffle();
    final options = masterDeck.take(3).toList();
    
    if (options.isEmpty) {
       _finishDraft(ref);
       return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A3D),
          title: const Text('Choisissez une carte à cloner', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((card) => ListTile(
                title: Text(card.data.name, style: const TextStyle(color: Colors.amber)),
                subtitle: Text('Niveau ${card.level}', style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  ref.read(deckProvider.notifier).addCardToMasterDeck(
                    CardInstance(data: card.data, level: card.level)
                  );
                  Navigator.of(ctx).pop();
                  _finishDraft(ref);
                },
              )).toList(),
            ),
          ),
        );
      }
    );
  }

  void _onChoiceSelected(BuildContext context, WidgetRef ref, _DraftChoice choice) {
    if (choice.isCloneOption) {
      _showCloneModal(context, ref);
      return;
    }

    final runController = ref.read(runProvider.notifier);
    runController.applyHeroStatModifier(
      maxPvAcc: choice.pvBoost,
      attackAcc: choice.atkBoost,
      armorAcc: choice.armorBoost,
      maxManaAcc: choice.manaBoost,
    );
    
    _finishDraft(ref);
  }

  List<_DraftChoice> _generateChoices() {
    final rng = Random();
    final choices = List.generate(3, (index) {
        int type = rng.nextInt(4);
        if (type == 0) return _DraftChoice('Vitalité', '+15 PV Max', 15, 0, 0, 0);
        if (type == 1) return _DraftChoice('Aiguisage', '+5 Attaque', 0, 5, 0, 0);
        if (type == 2) return _DraftChoice('Plaque de Fer', '+10 Armure', 0, 0, 10, 0);
        return _DraftChoice('Sagesse', '+5 Mana Max', 0, 0, 0, 5);
    });

    if (rng.nextDouble() < 0.3) {
      choices.add(_DraftChoice('Miroir', 'Cloner une carte de votre deck', 0, 0, 0, 0, isCloneOption: true));
    }

    return choices;
  }
}

class _DraftChoice {
  final String title;
  final String description;
  final int pvBoost;
  final int atkBoost;
  final int armorBoost;
  final int manaBoost;
  final bool isCloneOption;

  _DraftChoice(this.title, this.description, this.pvBoost, this.atkBoost, this.armorBoost, this.manaBoost, {this.isCloneOption = false});
}
