import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/systems/signature_evolution_rules.dart';
import '../../models/data/signature_evolution_data.dart';
import '../../models/signature_instance.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/audio_source.dart';
import '../../services/audio/game_moment.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/effect_style.dart';
import '../widgets/relic_carousel/draft_card_reel.dart';

/// Le choix d'une évolution de [signature] : trois rouleaux, comme le draft de
/// montée de niveau (spec vague 5, §5.1). Le tirage se refait à chaque
/// ouverture ; toucher un rouleau posé prend l'évolution, puis [onComplete].
class SignatureEvolutionScreen extends ConsumerStatefulWidget {
  final SignatureInstance signature;
  final VoidCallback onComplete;

  const SignatureEvolutionScreen({
    super.key,
    required this.signature,
    required this.onComplete,
  });

  @override
  ConsumerState<SignatureEvolutionScreen> createState() =>
      _SignatureEvolutionScreenState();
}

class _SignatureEvolutionScreenState
    extends ConsumerState<SignatureEvolutionScreen> {
  late final List<SignatureEvolutionData> _offer;
  int? _selectedIndex;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _offer = SignatureEvolutionRules.offer(widget.signature, Random());
  }

  void _reelTick() =>
      ref.read(audioDirectorProvider).onMoment(GameMoment.reelTick);

  void _reelLand() => ref
      .read(audioDirectorProvider)
      .onMoment(GameMoment.reelLand, source: const VariantAudioSource('common'));

  /// Le niveau déjà pris de [evolution], 0 si elle n'est pas prise.
  int _takenLevel(SignatureEvolutionData evolution) => widget.signature.taken
      .where((t) => t.$1.id == evolution.id)
      .map((t) => t.$2)
      .firstOrNull ??
      0;

  void _onChoiceSelected(SignatureEvolutionData evolution, int index) {
    if (_selectedIndex != null) return;
    setState(() => _selectedIndex = index);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      // Refusé ou non, le rideau de la carte rouvre ce qui reste.
      ref
          .read(runProvider.notifier)
          .chooseSignatureEvolution(widget.signature.data.id, evolution.id);
      widget.onComplete();
    });
  }

  Widget _reel(
    AppLocalizations l10n,
    List<ReelEntry> spinPool,
    SignatureEvolutionData evolution,
    int index,
  ) {
    final locale = l10n.localeName;
    final taken = _takenLevel(evolution);
    final cost = widget.signature.data.cost;
    final description = StringBuffer(
      evolution.getDescription(taken + 1, locale, cost: cost),
    );
    if (evolution.tier == EvolutionTier.minor && taken > 0) {
      description.write('\n${l10n.evolutionLevelUp(taken, taken + 1)}');
    }
    return MouseRegion(
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
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: DraftCardReel(
            onTick: _reelTick,
            title: evolution.getName(locale),
            description: description.toString(),
            onTap: () => _onChoiceSelected(evolution, index),
            rarity: evolution.tier == EvolutionTier.major
                ? l10n.evolutionTierMajor
                : l10n.evolutionTierMinor,
            index: index,
            onLand: _reelLand,
            spinPool: spinPool,
            icon: EvolutionIcon(evolution: evolution, size: 44),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final cost = widget.signature.data.cost;
    final spinPool = [
      for (final e in widget.signature.data.evolutions)
        (
          title: e.getName(locale),
          description: e.getDescription(1, locale, cost: cost),
        ),
    ];

    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isPortrait = constraints.maxWidth < 600;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.evolutionScreenTitle(
                        widget.signature.data.getName(locale),
                      ),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.heightSm,
                    Text(
                      l10n.evolutionScreenSubtitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.heightXl,
                    if (isPortrait)
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final (index, e) in _offer.indexed)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                  horizontal: AppSpacing.xxl,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 160,
                                    ),
                                    child: _reel(l10n, spinPool, e, index),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final (index, e) in _offer.indexed)
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 160,
                                  ),
                                  child: _reel(l10n, spinPool, e, index),
                                ),
                              ),
                            ),
                        ],
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
}
