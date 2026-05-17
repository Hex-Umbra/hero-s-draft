import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';

class DraftScreen extends ConsumerStatefulWidget {
  final VoidCallback onDraftComplete;

  const DraftScreen({super.key, required this.onDraftComplete});

  @override
  ConsumerState<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends ConsumerState<DraftScreen> {
  late List<_DraftChoice> _choices;

  @override
  void initState() {
    super.initState();
    _choices = _generateChoices();
  }

  String _rarityToString(RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.legendary:
        return 'Légendaire';
      case RewardRarity.epic:
        return 'Épique';
      case RewardRarity.rare:
        return 'Rare';
      case RewardRarity.uncommon:
        return 'Peu Commun';
      case RewardRarity.common:
        return 'Commun';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
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
                          children: _choices
                              .map(
                                (choice) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 40,
                                  ),
                                  child: UiCard(
                                    title: choice.title,
                                    description: choice.description,
                                    onTap: () =>
                                        _onChoiceSelected(context, ref, choice),
                                    rarity: _rarityToString(choice.rarity),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _choices
                            .map(
                              (choice) => Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    child: UiCard(
                                      title: choice.title,
                                      description: choice.description,
                                      onTap: () => _onChoiceSelected(
                                        context,
                                        ref,
                                        choice,
                                      ),
                                      rarity: _rarityToString(choice.rarity),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              );
            },
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
    widget.onDraftComplete();
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
          title: const Text(
            'Choisissez une carte à cloner',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (card) => ListTile(
                      title: Text(
                        card.data.name,
                        style: const TextStyle(color: Colors.amber),
                      ),
                      subtitle: Text(
                        'Niveau ${card.level}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        ref
                            .read(deckProvider.notifier)
                            .addCardToMasterDeck(
                              CardInstance(data: card.data, level: card.level),
                            );
                        Navigator.of(ctx).pop();
                        _finishDraft(ref);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _onChoiceSelected(
    BuildContext context,
    WidgetRef ref,
    _DraftChoice choice,
  ) {
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
      luckAcc: choice.luckBoost,
    );

    _finishDraft(ref);
  }

  RewardRarity _rollRarity(int luck) {
    final rng = Random();
    // Probabilités de base (sur 100)
    double legendaryChance = 1.0;
    double epicChance = 4.0;
    double rareChance = 15.0;
    double uncommonChance = 30.0;
    
    // La chance augmente les probabilités des hautes raretés
    legendaryChance += luck * 0.5;
    epicChance += luck * 1.5;
    rareChance += luck * 3.0;
    uncommonChance += luck * 4.0;

    double roll = rng.nextDouble() * 100;

    if (roll < legendaryChance) return RewardRarity.legendary;
    roll -= legendaryChance;
    if (roll < epicChance) return RewardRarity.epic;
    roll -= epicChance;
    if (roll < rareChance) return RewardRarity.rare;
    roll -= rareChance;
    if (roll < uncommonChance) return RewardRarity.uncommon;
    
    return RewardRarity.common;
  }

  List<_DraftChoice> _generateChoices() {
    final rng = Random();
    final runState = ref.read(runProvider);
    final luck = runState.heroStats.luck;

    final choices = List.generate(3, (index) {
      RewardRarity rarity = _rollRarity(luck);

      if (rarity == RewardRarity.legendary) {
        return _DraftChoice(
          'Trèfle à 4 feuilles',
          '+1 Chance',
          0,
          0,
          0,
          0,
          luckBoost: 1,
          rarity: rarity,
        );
      }

      double multiplier = 1.0;
      if (rarity == RewardRarity.uncommon) multiplier = 1.5;
      if (rarity == RewardRarity.rare) multiplier = 2.0;
      if (rarity == RewardRarity.epic) multiplier = 3.0;

      int type = rng.nextInt(4);
      if (type == 0) {
        int boost = (15 * multiplier).round();
        return _DraftChoice('Vitalité', '+$boost PV Max', boost, 0, 0, 0, rarity: rarity);
      }
      if (type == 1) {
        int boost = (5 * multiplier).round();
        return _DraftChoice('Aiguisage', '+$boost Attaque', 0, boost, 0, 0, rarity: rarity);
      }
      if (type == 2) {
        int boost = (10 * multiplier).round();
        return _DraftChoice('Plaque de Fer', '+$boost Armure', 0, 0, boost, 0, rarity: rarity);
      }
      
      // type == 3 : Sagesse
      // Le mana max est puissant, on ajuste le scaling pour éviter des valeurs folles
      double manaMultiplier = 1.0;
      if (rarity == RewardRarity.uncommon) manaMultiplier = 1.2; // +6
      if (rarity == RewardRarity.rare) manaMultiplier = 1.6; // +8
      if (rarity == RewardRarity.epic) manaMultiplier = 2.0; // +10
      int boost = (5 * manaMultiplier).round();
      return _DraftChoice('Sagesse', '+$boost Mana Max', 0, 0, 0, boost, rarity: rarity);
    });

    if (rng.nextDouble() < 0.3) {
      choices.add(
        _DraftChoice(
          'Miroir',
          'Cloner une carte de votre deck',
          0,
          0,
          0,
          0,
          isCloneOption: true,
          rarity: RewardRarity.epic, // Le miroir est considéré comme épique
        ),
      );
    }

    return choices;
  }
}

enum RewardRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary
}

class _DraftChoice {
  final String title;
  final String description;
  final int pvBoost;
  final int atkBoost;
  final int armorBoost;
  final int manaBoost;
  final int luckBoost;
  final bool isCloneOption;
  final RewardRarity rarity;

  _DraftChoice(
    this.title,
    this.description,
    this.pvBoost,
    this.atkBoost,
    this.armorBoost,
    this.manaBoost, {
    this.luckBoost = 0,
    this.isCloneOption = false,
    this.rarity = RewardRarity.common,
  });
}
