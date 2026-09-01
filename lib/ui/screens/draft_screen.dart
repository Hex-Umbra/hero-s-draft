import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/level_up_reward_service.dart';
import '../../models/card_instance.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/audio_source.dart';
import '../../services/audio/game_moment.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/draft/draft_choice_labels.dart';
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

class _DraftScreenState extends ConsumerState<DraftScreen>
    with TickerProviderStateMixin {
  late List<DraftChoice> _choices;
  bool _baseCompleted = false;
  bool _showMythicAlert = false;
  bool _mythicRevealing = false;
  bool _mythicCompleted = false;
  int _baseLandedCount = 0;
  int _mythicLandedCount = 0;
  late AnimationController _alertController;
  int? _selectedIndex;
  int? _hoveredIndex;

  bool get _hasMythicChoices =>
      _choices.any((c) => c.rarity == RewardRarity.mythic);

  /// Un cran du rouleau. La cadence n'est pas pilotee ici : `DraftCardReel`
  /// emet `onTick` a chaque carte qui defile, et sa courbe de deceleration
  /// espace les emissions d'elle-meme.
  void _reelTick() =>
      ref.read(audioDirectorProvider).onMoment(GameMoment.reelTick);

  /// La revelation. La rarete voyage comme cle de variante, pas comme son :
  /// `audio.json` decide quel bruitage chaque rarete declenche, et deux
  /// raretes peuvent partager le meme tant qu'aucun son distinct n'existe.
  /// Le libelle passe a `DraftCardReel.rarity` est localise, donc inutilisable
  /// ici — c'est l'enum brut qu'il faut.
  void _reelLand(RewardRarity rarity) => ref
      .read(audioDirectorProvider)
      .onMoment(GameMoment.reelLand, source: VariantAudioSource(rarity.name));

  void _onBaseReelLanded(RewardRarity rarity) {
    _reelLand(rarity);
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

  void _onMythicReelLanded(RewardRarity rarity) {
    _reelLand(rarity);
    _mythicLandedCount++;
    final mythicChoicesCount =
        _choices.where((c) => c.rarity == RewardRarity.mythic).length;
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
    _choices = LevelUpRewardService.generateChoices(
      luck: ref.read(runProvider).heroStats.luck,
      forceLegendary: widget.forceLegendary,
    );
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

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

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
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                        AppSpacing.heightSm,
                        Text(
                          l10n.chooseUpgrade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.heightXl,
                        if (isPortrait)
                          Expanded(
                            child: ListView(
                              shrinkWrap: true,
                              children: visibleChoices.map((choice) {
                                final index = _choices.indexOf(choice);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.sm,
                                    horizontal: AppSpacing.xxl,
                                  ),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 160,
                                      ),
                                      child: MouseRegion(
                                        onEnter: (_) => setState(
                                          () => _hoveredIndex = index,
                                        ),
                                        onExit: (_) => setState(
                                          () => _hoveredIndex = null,
                                        ),
                                        child: AnimatedScale(
                                          scale: _selectedIndex == index
                                              ? 1.12
                                              : (_hoveredIndex == index
                                                  ? 1.05
                                                  : 1.0),
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: _selectedIndex == index
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.amber
                                                            .withValues(
                                                                alpha: 0.4),
                                                        blurRadius: 16,
                                                        spreadRadius: 3,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: DraftCardReel(
                                              onTick: () => _reelTick(),
                                              title:
                                                  DraftChoiceLabels.getChoiceTitle(
                                                l10n,
                                                choice,
                                              ),
                                              description:
                                                  DraftChoiceLabels.getChoiceDescription(
                                                l10n,
                                                choice,
                                              ),
                                              onTap: () {
                                                if (_hasMythicChoices &&
                                                    !_mythicCompleted) {
                                                  return;
                                                }
                                                _onChoiceSelected(
                                                  choice,
                                                  index,
                                                );
                                              },
                                              rarity: DraftChoiceLabels.rarityToString(
                                                l10n,
                                                choice.rarity,
                                              ),
                                              index: index,
                                              onLand: index < 3
                                                  ? () => _onBaseReelLanded(
                                                      choice.rarity)
                                                  : null,
                                              initialLanded: index >= 3
                                                  ? true
                                                  : _baseCompleted,
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
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    child: MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _hoveredIndex = index),
                                      onExit: (_) =>
                                          setState(() => _hoveredIndex = null),
                                      child: AnimatedScale(
                                        scale: _selectedIndex == index
                                            ? 1.12
                                            : (_hoveredIndex == index
                                                ? 1.05
                                                : 1.0),
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeOut,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: _selectedIndex == index
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.amber
                                                          .withValues(
                                                              alpha: 0.4),
                                                      blurRadius: 16,
                                                      spreadRadius: 3,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: DraftCardReel(
                                            onTick: () => _reelTick(),
                                            title: DraftChoiceLabels.getChoiceTitle(
                                              l10n,
                                              choice,
                                            ),
                                            description: DraftChoiceLabels.getChoiceDescription(
                                              l10n,
                                              choice,
                                            ),
                                            onTap: () {
                                              if (_hasMythicChoices &&
                                                  !_mythicCompleted) {
                                                return;
                                              }
                                              _onChoiceSelected(
                                                choice,
                                                index,
                                              );
                                            },
                                            rarity: DraftChoiceLabels.rarityToString(
                                              l10n,
                                              choice.rarity,
                                            ),
                                            index: index,
                                            onLand: index < 3
                                                ? () => _onBaseReelLanded(
                                                    choice.rarity)
                                                : null,
                                            initialLanded: index >= 3
                                                ? true
                                                : _baseCompleted,
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
                              Shadow(color: Color(0xFFE53E3E), blurRadius: 15),
                            ],
                          ),
                        ),
                        AppSpacing.heightXxl,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _choices
                              .where((c) => c.rarity == RewardRarity.mythic)
                              .map((choice) {
                            final mythicIndex = _choices.indexOf(choice);
                            final relativeIndex = mythicIndex - 3;
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 160,
                                ),
                                child: MouseRegion(
                                  onEnter: (_) => setState(
                                    () => _hoveredIndex = mythicIndex,
                                  ),
                                  onExit: (_) =>
                                      setState(() => _hoveredIndex = null),
                                  child: AnimatedScale(
                                    scale: _selectedIndex == mythicIndex
                                        ? 1.12
                                        : (_hoveredIndex == mythicIndex
                                            ? 1.05
                                            : 1.0),
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    curve: Curves.easeOut,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        boxShadow: _selectedIndex == mythicIndex
                                            ? [
                                                BoxShadow(
                                                  color: Colors.amber
                                                      .withValues(alpha: 0.4),
                                                  blurRadius: 16,
                                                  spreadRadius: 3,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: DraftCardReel(
                                        onTick: () => _reelTick(),
                                        title: DraftChoiceLabels.getChoiceTitle(
                                          l10n,
                                          choice,
                                        ),
                                        description: DraftChoiceLabels.getChoiceDescription(
                                          l10n,
                                          choice,
                                        ),
                                        onTap: () {},
                                        rarity: DraftChoiceLabels.rarityToString(
                                          l10n,
                                          choice.rarity,
                                        ),
                                        index: relativeIndex,
                                        onLand: () => _onMythicReelLanded(choice.rarity),
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

                  double lineWidthPercent = (val / 0.2).clamp(0.0, 1.0);

                  double exclamationScale = 0.0;
                  if (val > 0.2) {
                    final t = (val - 0.2) / 0.4;
                    const c4 = (2 * pi) / 3;
                    exclamationScale = t == 0
                        ? 0
                        : t == 1
                            ? 1
                            : pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1;
                    exclamationScale = exclamationScale.clamp(0.0, 1.2);
                  }

                  bool isVisible = true;
                  if (val > 0.6) {
                    final blinkVal = ((val - 0.6) / 0.4 * 6).floor();
                    isVisible = blinkVal % 2 == 0;
                  }

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.3 * val),
                        ),
                      ),
                      Center(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 6,
                            width: MediaQuery.of(context).size.width *
                                lineWidthPercent,
                            decoration: BoxDecoration(
                              color: isVisible
                                  ? const Color(0xFFE53E3E)
                                  : Colors.transparent,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53E3E)
                                      .withValues(alpha: 0.8),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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
                                  Shadow(color: Colors.white, blurRadius: 5),
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
    widget.onDraftComplete();
  }

  void _showCloneModal(BuildContext context, WidgetRef ref) {
    final deckState = ref.read(deckProvider);
    final masterDeck = List.of(deckState.masterDeck);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

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
        return GameDialog(
          showCloseButton: false,
          title: Text(
            l10n.chooseCardToClone,
          ),
          content: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
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
                          card.rarity.getLabel(l10n).toUpperCase(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () {
                          ref.read(deckProvider.notifier).addCardToMasterDeck(
                                CardInstance(
                                  data: card.data,
                                  rarity: card.rarity,
                                  forgeUpgrades: List.from(card.forgeUpgrades),
                                ),
                              );
                          Navigator.of(ctx).pop();
                          _finishDraft(ref);
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onChoiceSelected(
    DraftChoice choice,
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
        critChanceAcc: choice.critChanceBoost,
        critDamageAcc: choice.critDamageBoost,
      );

      _finishDraft(ref);
    });
  }

}
