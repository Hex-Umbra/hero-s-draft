import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/card_instance.dart';
import '../widgets/relic_carousel/draft_card_reel.dart';

class DraftScreen extends ConsumerStatefulWidget {
  final VoidCallback onDraftComplete;
  final bool forceLegendary;

  const DraftScreen({
    super.key,
    required this.onDraftComplete,
    this.forceLegendary = false,
  });

  @override
  ConsumerState<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends ConsumerState<DraftScreen> with TickerProviderStateMixin {
  late List<_DraftChoice> _choices;
  bool _baseCompleted = false;
  bool _showMythicAlert = false;
  bool _mythicRevealing = false;
  bool _mythicCompleted = false;
  int _baseLandedCount = 0;
  int _mythicLandedCount = 0;
  late AnimationController _alertController;
  int? _selectedIndex;
  int? _hoveredIndex;

  bool get _hasMythicChoices => _choices.any((c) => c.rarity == RewardRarity.mythic);

  void _onBaseReelLanded() {
    _baseLandedCount++;
    if (_baseLandedCount == 3) {
      if (_hasMythicChoices) {
        setState(() {
          _baseCompleted = true;
          _showMythicAlert = true;
        });
        _alertController.forward(from: 0.0);
      } else {
        setState(() {
          _baseCompleted = true;
        });
      }
    }
  }

  void _onMythicReelLanded() {
    _mythicLandedCount++;
    final mythicChoicesCount = _choices.where((c) => c.rarity == RewardRarity.mythic).length;
    if (_mythicLandedCount == mythicChoicesCount) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _mythicRevealing = false;
            _mythicCompleted = true;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _choices = _generateChoices();
    _alertController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _alertController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showMythicAlert = false;
          _mythicRevealing = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _alertController.dispose();
    super.dispose();
  }

  String _rarityToString(BuildContext context, RewardRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case RewardRarity.mythic:
        return Localizations.localeOf(context).languageCode == 'fr' ? 'MYTHIQUE' : 'MYTHIC';
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
    final visibleChoices = _mythicCompleted ? _choices : _choices.sublist(0, 3);

    return Stack(
      children: [
        Material(
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
                              children: visibleChoices.map((choice) {
                                final index = _choices.indexOf(choice);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 40,
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 160,
                                      ),
                                      child: MouseRegion(
                                        onEnter: (_) => setState(() => _hoveredIndex = index),
                                        onExit: (_) => setState(() => _hoveredIndex = null),
                                        child: AnimatedScale(
                                          scale: _selectedIndex == index
                                              ? 1.12
                                              : (_hoveredIndex == index ? 1.05 : 1.0),
                                          duration: const Duration(milliseconds: 200),
                                          curve: Curves.easeOut,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: _selectedIndex == index
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.amber.withOpacity(0.4),
                                                        blurRadius: 16,
                                                        spreadRadius: 3,
                                                      )
                                                    ]
                                                  : [],
                                            ),
                                            child: DraftCardReel(
                                              title: _getChoiceTitle(context, choice),
                                              description: _getChoiceDescription(
                                                context,
                                                choice,
                                              ),
                                              onTap: () {
                                                if (_hasMythicChoices && !_mythicCompleted) return;
                                                _onChoiceSelected(context, ref, choice, index);
                                              },
                                              rarity: _rarityToString(
                                                context,
                                                choice.rarity,
                                              ),
                                              index: index,
                                              onLand: index < 3 ? _onBaseReelLanded : null,
                                              initialLanded: index >= 3 ? true : _baseCompleted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: visibleChoices.map((choice) {
                              final index = _choices.indexOf(choice);
                              return Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    child: MouseRegion(
                                      onEnter: (_) => setState(() => _hoveredIndex = index),
                                      onExit: (_) => setState(() => _hoveredIndex = null),
                                      child: AnimatedScale(
                                        scale: _selectedIndex == index
                                            ? 1.12
                                            : (_hoveredIndex == index ? 1.05 : 1.0),
                                        duration: const Duration(milliseconds: 200),
                                        curve: Curves.easeOut,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: _selectedIndex == index
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.amber.withOpacity(0.4),
                                                      blurRadius: 16,
                                                      spreadRadius: 3,
                                                    )
                                                  ]
                                                : [],
                                          ),
                                          child: DraftCardReel(
                                            title: _getChoiceTitle(context, choice),
                                            description: _getChoiceDescription(
                                              context,
                                              choice,
                                            ),
                                            onTap: () {
                                              if (_hasMythicChoices && !_mythicCompleted) return;
                                              _onChoiceSelected(context, ref, choice, index);
                                            },
                                            rarity: _rarityToString(
                                              context,
                                              choice.rarity,
                                            ),
                                            index: index,
                                            onLand: index < 3 ? _onBaseReelLanded : null,
                                            initialLanded: index >= 3 ? true : _baseCompleted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (_mythicRevealing)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'RÉCOMPENSE MYTHIQUE DÉCOUVERTE !',
                          style: TextStyle(
                            color: Color(0xFFE53E3E),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: Color(0xFFE53E3E),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _choices
                              .where((c) => c.rarity == RewardRarity.mythic)
                              .map((choice) {
                            final mythicIndex = _choices.indexOf(choice);
                            final relativeIndex = mythicIndex - 3;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _hoveredIndex = mythicIndex),
                                  onExit: (_) => setState(() => _hoveredIndex = null),
                                  child: AnimatedScale(
                                    scale: _selectedIndex == mythicIndex
                                        ? 1.12
                                        : (_hoveredIndex == mythicIndex ? 1.05 : 1.0),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _selectedIndex == mythicIndex
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber.withOpacity(0.4),
                                                  blurRadius: 16,
                                                  spreadRadius: 3,
                                                )
                                              ]
                                            : [],
                                      ),
                                      child: DraftCardReel(
                                        title: _getChoiceTitle(context, choice),
                                        description: _getChoiceDescription(
                                          context,
                                          choice,
                                        ),
                                        onTap: () {},
                                        rarity: _rarityToString(
                                          context,
                                          choice.rarity,
                                        ),
                                        index: relativeIndex,
                                        onLand: _onMythicReelLanded,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_showMythicAlert)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _alertController,
                builder: (context, child) {
                  final val = _alertController.value;

                  // Phase 1: Draw line from left to right (0.0 to 0.2) - Twice as fast
                  double lineWidthPercent = (val / 0.2).clamp(0.0, 1.0);

                  // Phase 2: Exclamation marks scale up elastically (0.2 to 0.6)
                  double exclamationScale = 0.0;
                  if (val > 0.2) {
                    final t = (val - 0.2) / 0.4;
                    // Elastic ease out
                    const c4 = (2 * pi) / 3;
                    exclamationScale = t == 0
                        ? 0
                        : t == 1
                            ? 1
                            : pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
                    exclamationScale = exclamationScale.clamp(0.0, 1.2);
                  }

                  // Phase 3: Blinking warning (0.6 to 1.0)
                  bool isVisible = true;
                  if (val > 0.6) {
                    // Blinks twice
                    final blinkVal = ((val - 0.6) / 0.4 * 6).floor();
                    isVisible = blinkVal % 2 == 0;
                  }

                  return Stack(
                    children: [
                      // Darken background slightly to increase contrast
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3 * val),
                        ),
                      ),

                      // Horizontal Red Line
                      Center(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 6,
                            width: MediaQuery.of(context).size.width * lineWidthPercent,
                            decoration: BoxDecoration(
                              color: isVisible ? const Color(0xFFE53E3E) : Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53E3E).withValues(alpha: 0.8),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Exclamation Points
                      if (val > 0.2 && isVisible)
                        Center(
                          child: Transform.scale(
                            scale: exclamationScale,
                            child: const Text(
                              '!!!',
                              style: TextStyle(
                                color: Color(0xFFE53E3E),
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4.0,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFE53E3E),
                                    blurRadius: 25,
                                  ),
                                  Shadow(
                                    color: Colors.white,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
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
    int index,
  ) {
    if (_selectedIndex != null) return;

    setState(() {
      _selectedIndex = index;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
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
    });
  }

  RewardRarity _rollRarity(
    int luck, {
    bool canBeLegendary = true,
    bool isLevelReward = false,
  }) {
    if (widget.forceLegendary) {
      if (isLevelReward) {
        return RewardRarity.mythic;
      }
    }
    final rng = Random();
    // Probabilités de base (sur 100)
    double mythicChance = isLevelReward ? 0.5 : 0.0;
    double legendaryChance = 2.0;
    double epicChance = 6.0;
    double rareChance = 16.0;
    double uncommonChance = 24.0;

    // La chance augmente les probabilités des hautes raretés
    if (isLevelReward) {
      mythicChance += luck * 0.15;
    }
    legendaryChance += luck * 0.5;
    epicChance += luck * 1.5;
    rareChance += luck * 3.0;
    uncommonChance += luck * 4.0;

    double roll = rng.nextDouble() * 100;

    if (isLevelReward && roll < mythicChance) {
      return RewardRarity.mythic;
    }
    if (isLevelReward) {
      roll -= mythicChance;
    }

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
      RewardRarity rarity;
      if (widget.forceLegendary) {
        if (index == 0) {
          rarity = RewardRarity.uncommon;
        } else if (index == 1) {
          rarity = RewardRarity.epic;
        } else {
          rarity = RewardRarity.legendary;
        }
      } else {
        rarity = _rollRarity(
          luck,
          canBeLegendary: true,
          isLevelReward: false,
        );
      }

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
    if (_rollRarity(luck, isLevelReward: true) == RewardRarity.mythic) {
      choices.add(
        _DraftChoice(
          'Trèfle à 4 feuilles',
          '+1 Chance',
          0,
          0,
          0,
          0,
          luckBoost: 1,
          rarity: RewardRarity.mythic,
        ),
      );
    }

    // Miroir (Clonage)
    if (_rollRarity(luck, isLevelReward: true) == RewardRarity.mythic) {
      choices.add(
        _DraftChoice(
          'Miroir',
          'Cloner une carte au choix parmi 3 cartes aléatoires de votre deck',
          0,
          0,
          0,
          0,
          isCloneOption: true,
          rarity: RewardRarity.mythic,
        ),
      );
    }

    return choices;
  }
}

enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }

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
