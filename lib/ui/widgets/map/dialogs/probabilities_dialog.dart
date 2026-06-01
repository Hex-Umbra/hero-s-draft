import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../blur_wrapper.dart';

class ProbabilitiesDialog extends ConsumerWidget {
  const ProbabilitiesDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProbabilitiesOverlay',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const ProbabilitiesDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  static Map<String, double> calculateDraftProbabilities(
    int luck,
    bool isLevelReward,
  ) {
    double legendaryChance = isLevelReward
        ? 0.5 + luck * 0.5
        : 1.0 + luck * 0.5;
    double epicChance = isLevelReward ? 4.5 + luck * 1.5 : 5.0 + luck * 1.5;
    double rareChance = isLevelReward ? 15.0 + luck * 3.0 : 14.0 + luck * 3.0;
    double uncommonChance = 20.0 + luck * 4.0;

    legendaryChance = legendaryChance.clamp(0.0, 100.0);
    epicChance = epicChance.clamp(0.0, 100.0);
    rareChance = rareChance.clamp(0.0, 100.0);
    uncommonChance = uncommonChance.clamp(0.0, 100.0);

    double pLeg = legendaryChance;
    double pEpic = epicChance;
    double pRare = rareChance;
    double pUncommon = uncommonChance;

    double sum = pLeg;
    pEpic = pEpic.clamp(0.0, 100.0 - sum);
    sum += pEpic;
    pRare = pRare.clamp(0.0, 100.0 - sum);
    sum += pRare;
    pUncommon = pUncommon.clamp(0.0, 100.0 - sum);
    sum += pUncommon;
    double pCommon = (100.0 - sum).clamp(0.0, 100.0);

    return {
      'legendary': pLeg,
      'epic': pEpic,
      'rare': pRare,
      'uncommon': pUncommon,
      'common': pCommon,
    };
  }

  static Map<String, double> calculateRelicProbabilities(int luck) {
    double leg = 1.0 + luck * 0.5;
    double epic = 5.0 + luck * 1.0;
    double rare = 14.0 + luck * 2.0;
    double uncommon = 20.0 + luck * 3.0;

    double sum = leg + epic + rare + uncommon;
    if (sum > 100.0) {
      leg = leg / sum * 100.0;
      epic = epic / sum * 100.0;
      rare = rare / sum * 100.0;
      uncommon = uncommon / sum * 100.0;
      return {
        'legendary': leg,
        'epic': epic,
        'rare': rare,
        'uncommon': uncommon,
        'common': 0.0,
      };
    }
    double common = 100.0 - sum;
    return {
      'legendary': leg,
      'epic': epic,
      'rare': rare,
      'uncommon': uncommon,
      'common': common,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runProvider);
    final int luck = runState.heroStats.luck;

    final baseDraftStd = calculateDraftProbabilities(0, false);
    final curDraftStd = calculateDraftProbabilities(luck, false);

    final baseDraftLeg = calculateDraftProbabilities(0, true);
    final curDraftLeg = calculateDraftProbabilities(luck, true);

    final baseRelics = calculateRelicProbabilities(0);
    final curRelics = calculateRelicProbabilities(luck);

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return BlurWrapper(
      sigma: 8,
      child: Center(
        child: Container(
          width: min(MediaQuery.of(context).size.width * 0.9, 650),
          height: min(MediaQuery.of(context).size.height * 0.85, 750),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.casino_outlined,
                      color: Colors.amberAccent,
                      size: 36,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.luckPercentageTitle.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            locale == 'fr'
                                ? 'Ajustement en temps réel basé sur votre statistique de Chance'
                                : 'Real-time adjustments based on your Luck statistic',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amberAccent.withAlpha(60),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.casino,
                          color: Colors.amberAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.currentLuck(luck),
                          style: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildProbabilitySectionCard(
                          title: locale == 'fr'
                              ? 'Draft standard de récompenses'
                              : 'Standard Reward Draft',
                          subtitle: locale == 'fr'
                              ? "Chances d'obtenir chaque rareté de carte/stat en fin de combat standard"
                              : "Chances of getting each card/stat rarity at the end of standard combat",
                          icon: Icons.style_outlined,
                          accentColor: Colors.cyanAccent,
                          rows: [
                            _buildProbabilityRow(
                              rarityName: l10n.rarityLegendary,
                              color: Colors.amber,
                              basePercent: baseDraftStd['legendary']!,
                              currentPercent: curDraftStd['legendary']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityEpic,
                              color: Colors.purpleAccent,
                              basePercent: baseDraftStd['epic']!,
                              currentPercent: curDraftStd['epic']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityRare,
                              color: Colors.blueAccent,
                              basePercent: baseDraftStd['rare']!,
                              currentPercent: curDraftStd['rare']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityUncommon,
                              color: Colors.greenAccent,
                              basePercent: baseDraftStd['uncommon']!,
                              currentPercent: curDraftStd['uncommon']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityCommon,
                              color: Colors.grey,
                              basePercent: baseDraftStd['common']!,
                              currentPercent: curDraftStd['common']!,
                            ),
                          ],
                        ),
                        _buildProbabilitySectionCard(
                          title: locale == 'fr'
                              ? 'Récompense de niveau'
                              : 'Level Reward',
                          subtitle: locale == 'fr'
                              ? "Chances d'obtenir chaque rareté d'option lors de la montée de niveau (Trèfle / Miroir)"
                              : "Chances of getting each option rarity when leveling up (Clover / Mirror)",
                          icon: Icons.auto_awesome_outlined,
                          accentColor: Colors.lightGreenAccent,
                          rows: [
                            _buildProbabilityRow(
                              rarityName: l10n.rarityLegendary,
                              color: Colors.amber,
                              basePercent: baseDraftLeg['legendary']!,
                              currentPercent: curDraftLeg['legendary']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityEpic,
                              color: Colors.purpleAccent,
                              basePercent: baseDraftLeg['epic']!,
                              currentPercent: curDraftLeg['epic']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityRare,
                              color: Colors.blueAccent,
                              basePercent: baseDraftLeg['rare']!,
                              currentPercent: curDraftLeg['rare']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityUncommon,
                              color: Colors.greenAccent,
                              basePercent: baseDraftLeg['uncommon']!,
                              currentPercent: curDraftLeg['uncommon']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityCommon,
                              color: Colors.grey,
                              basePercent: baseDraftLeg['common']!,
                              currentPercent: curDraftLeg['common']!,
                            ),
                          ],
                        ),
                        _buildProbabilitySectionCard(
                          title: locale == 'fr'
                              ? 'Butin de Reliques'
                              : 'Relic Loot',
                          subtitle: locale == 'fr'
                              ? "Chances d'apparition des reliques par rareté (Boss, Élites & Événements)"
                              : "Relic drop rates by rarity (Boss, Elites & Events)",
                          icon: Icons.emoji_events_outlined,
                          accentColor: Colors.amber,
                          rows: [
                            _buildProbabilityRow(
                              rarityName: l10n.rarityLegendary,
                              color: Colors.amber,
                              basePercent: baseRelics['legendary']!,
                              currentPercent: curRelics['legendary']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityEpic,
                              color: Colors.purpleAccent,
                              basePercent: baseRelics['epic']!,
                              currentPercent: curRelics['epic']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityRare,
                              color: Colors.blueAccent,
                              basePercent: baseRelics['rare']!,
                              currentPercent: curRelics['rare']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityUncommon,
                              color: Colors.greenAccent,
                              basePercent: baseRelics['uncommon']!,
                              currentPercent: curRelics['uncommon']!,
                            ),
                            _buildProbabilityRow(
                              rarityName: l10n.rarityCommon,
                              color: Colors.grey,
                              basePercent: baseRelics['common']!,
                              currentPercent: curRelics['common']!,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProbabilityRow({
    required String rarityName,
    required Color color,
    required double basePercent,
    required double currentPercent,
  }) {
    final bool isIncreased = currentPercent > basePercent;
    final bool isDecreased = currentPercent < basePercent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withAlpha(60), width: 1),
                ),
                child: Text(
                  rarityName.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${basePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white30, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white24,
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isIncreased
                          ? Colors.greenAccent
                          : (isDecreased ? Colors.redAccent : Colors.white70),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isIncreased) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.trending_up,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                  ] else if (isDecreased) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.trending_down,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (basePercent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (currentPercent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withAlpha(100), color],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: color.withAlpha(80), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilitySectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required List<Widget> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252538).withAlpha(180),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white12, height: 1),
          ),
          ...rows,
        ],
      ),
    );
  }
}
