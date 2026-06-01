import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
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

  String _rarityToString(BuildContext context, RewardRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case RewardRarity.legendary:
        return l10n.rarityLegendary;
      case RewardRarity.epic:
        return l10n.rarityEpic;
      case RewardRarity.rare:
        return l10n.rarityRare;
      case RewardRarity.uncommon:
        return l10n.rarityUncommon;
      case RewardRarity.common:
        return l10n.rarityCommon;
    }
  }

  String _getChoiceTitle(BuildContext context, _DraftChoice choice) {
    final l10n = AppLocalizations.of(context)!;
    if (choice.title == 'Vitalité') return l10n.draftChoiceVitality;
    if (choice.title == 'Aiguisage') return l10n.draftChoiceSharpening;
    if (choice.title == 'Forge d\'Acier') return l10n.draftChoiceSteelForge;
    if (choice.title == 'Sagesse') return l10n.draftChoiceWisdom;
    if (choice.title == 'Trèfle à 4 feuilles') return l10n.draftChoiceClover;
    if (choice.title == 'Miroir') return l10n.draftChoiceMirror;
    return choice.title;
  }

  String _getChoiceDescription(BuildContext context, _DraftChoice choice) {
    final l10n = AppLocalizations.of(context)!;
    if (choice.title == 'Vitalité') {
      return l10n.draftChoiceVitalityDesc(choice.pvBoost);
    }
    if (choice.title == 'Aiguisage') {
      return l10n.draftChoiceSharpeningDesc(choice.atkBoost);
    }
    if (choice.title == 'Forge d\'Acier') {
      return l10n.draftChoiceSteelForgeDesc(choice.armorBoost);
    }
    if (choice.title == 'Sagesse') {
      return l10n.draftChoiceWisdomDesc(choice.manaBoost);
    }
    if (choice.title == 'Trèfle à 4 feuilles') {
      return l10n.draftChoiceCloverDesc(choice.luckBoost);
    }
    if (choice.title == 'Miroir') {
      return l10n.draftChoiceMirrorDesc;
    }
    return choice.description;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                    Text(
                      l10n.combatReward,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.chooseUpgrade,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
                                    title: _getChoiceTitle(context, choice),
                                    description: _getChoiceDescription(
                                      context,
                                      choice,
                                    ),
                                    onTap: () =>
                                        _onChoiceSelected(context, ref, choice),
                                    rarity: _rarityToString(
                                      context,
                                      choice.rarity,
                                    ),
                                    type: CardType.power,
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
                                      title: _getChoiceTitle(context, choice),
                                      description: _getChoiceDescription(
                                        context,
                                        choice,
                                      ),
                                      onTap: () => _onChoiceSelected(
                                        context,
                                        ref,
                                        choice,
                                      ),
                                      rarity: _rarityToString(
                                        context,
                                        choice.rarity,
                                      ),
                                      type: CardType.power,
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
    ref.read(inventoryProvider.notifier).gainGold(rng.nextInt(15) + 10);
    runController.nextLevel();
    widget.onDraftComplete();
  }

  void _showCloneModal(BuildContext context, WidgetRef ref) {
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

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
          title: Text(
            l10n.chooseCardToClone,
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (card) => ListTile(
                      title: Text(
                        card.data.getName(locale),
                        style: const TextStyle(color: Colors.amber),
                      ),
                      subtitle: Text(
                        l10n.levelLabel(card.level),
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

  RewardRarity _rollRarity(
    int luck, {
    bool canBeLegendary = true,
    bool isLevelReward = false,
  }) {
    final rng = Random();
    // Probabilités de base (sur 100)
    double legendaryChance = isLevelReward ? 0.5 : 1.0;
    double epicChance = isLevelReward ? 4.5 : 5.0;
    double rareChance = isLevelReward ? 15.0 : 14.0;
    double uncommonChance = 20.0;

    // La chance augmente les probabilités des hautes raretés
    legendaryChance += luck * 0.5;
    epicChance += luck * 1.5;
    rareChance += luck * 3.0;
    uncommonChance += luck * 4.0;

    double roll = rng.nextDouble() * 100;

    if (canBeLegendary && roll < legendaryChance) return RewardRarity.legendary;
    if (!canBeLegendary) {
      // Si on ne peut pas être légendaire, on décale le roll pour ignorer la tranche légendaire
      roll = (rng.nextDouble() * (100 - legendaryChance)) + legendaryChance;
    } else {
      roll -= legendaryChance;
    }

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

    // 1. Génération des 3 choix standards (Commun à Légendaire)
    final choices = List.generate(3, (index) {
      RewardRarity rarity = _rollRarity(
        luck,
        canBeLegendary: true,
        isLevelReward: false,
      );

      double multiplier = 1.0;
      if (rarity == RewardRarity.uncommon) multiplier = 1.5;
      if (rarity == RewardRarity.rare) multiplier = 2.0;
      if (rarity == RewardRarity.epic) multiplier = 3.0;
      if (rarity == RewardRarity.legendary) multiplier = 4.0;

      int type = rng.nextInt(4);
      if (type == 0) {
        int boost = (5 * multiplier).round();
        return _DraftChoice(
          'Vitalité',
          '+$boost PV Max',
          boost,
          0,
          0,
          0,
          rarity: rarity,
        );
      }
      if (type == 1) {
        int boost = (2 * multiplier).round();
        return _DraftChoice(
          'Aiguisage',
          '+$boost Attaque',
          0,
          boost,
          0,
          0,
          rarity: rarity,
        );
      }
      if (type == 2) {
        // Maîtrise d'Armure (Bonus permanent sur les gains passifs uniquement)
        // Les valeurs sont plus petites car c'est un bonus cumulatif puissant
        double masteryMultiplier = 1.0;
        if (rarity == RewardRarity.uncommon) masteryMultiplier = 2.0; // +2
        if (rarity == RewardRarity.rare) masteryMultiplier = 3.0; // +3
        if (rarity == RewardRarity.epic) masteryMultiplier = 5.0; // +5
        int boost = (1 * masteryMultiplier).round();
        return _DraftChoice(
          'Forge d\'Acier',
          '+$boost aux gains d\'Armure de votre passif',
          0,
          0,
          boost,
          0,
          rarity: rarity,
        );
      }

      // type == 3 : Sagesse (Mana)
      // On utilise les mêmes multiplicateurs pour rester cohérent
      int boost = (1 * multiplier).round();
      if (boost < 1) boost = 1;
      return _DraftChoice(
        'Sagesse',
        '+$boost Mana Max',
        0,
        0,
        0,
        boost,
        rarity: rarity,
      );
    });

    // 2. Tirage des récompenses Légendaires (En bonus, en plus des 3 choix)
    // Chaque récompense légendaire est testée indépendamment

    // Trèfle à 4 feuilles
    if (_rollRarity(luck, isLevelReward: true) == RewardRarity.legendary) {
      choices.add(
        _DraftChoice(
          'Trèfle à 4 feuilles',
          '+1 Chance',
          0,
          0,
          0,
          0,
          luckBoost: 1,
          rarity: RewardRarity.legendary,
        ),
      );
    }

    // Miroir (Clonage)
    if (_rollRarity(luck, isLevelReward: true) == RewardRarity.legendary) {
      choices.add(
        _DraftChoice(
          'Miroir',
          'Cloner une carte au choix parmi 3 cartes aléatoires de votre deck',
          0,
          0,
          0,
          0,
          isCloneOption: true,
          rarity: RewardRarity.legendary,
        ),
      );
    }

    return choices;
  }
}

enum RewardRarity { common, uncommon, rare, epic, legendary }

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
