import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../../../models/data/passive_data.dart';
import '../../../../services/game_data_service.dart';
import '../../blur_wrapper.dart';
import '../../sword_icon.dart';

class StatsDialog extends ConsumerWidget {
  const StatsDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'StatsOverlay',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const StatsDialog();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runProvider);
    final gameData = ref.watch(gameDataLoaderProvider).value;
    if (gameData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final heroData = gameData.heroes.firstWhere(
      (h) => h.id == runState.heroClassId,
      orElse: () => gameData.heroes.first,
    );

    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    Color classColor = Colors.blue;
    if (runState.heroClassId == 'berserker') classColor = Colors.red;
    if (runState.heroClassId == 'mage') classColor = Colors.purple;

    IconData classIcon = Icons.person;
    if (runState.heroClassId == 'paladin') classIcon = Icons.shield;
    if (runState.heroClassId == 'berserker') classIcon = Icons.whatshot;
    if (runState.heroClassId == 'mage') classIcon = Icons.auto_fix_high;

    final passive =
        runState.activePassive ??
        PassiveData.fallback(runState.passiveTrait ?? '');
    final traitName = passive.getName(locale);
    final traitDesc = passive.getDescription(locale);

    final stats = runState.heroStats;

    return BlurWrapper(
      sigma: 8,
      child: Center(
        child: Container(
          width: min(MediaQuery.of(context).size.width * 0.85, 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: classColor.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: classColor.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(classIcon, color: classColor, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heroData.getName(locale).toUpperCase(),
                            style: TextStyle(
                              color: classColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            l10n.actLevel(runState.act, runState.currentLevel),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
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
                Text(
                  l10n.heroStatsTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  context,
                  icon: Icons.favorite,
                  iconColor: Colors.redAccent,
                  label: l10n.tooltipHpTitle,
                  value: '${stats.currentPv} / ${stats.maxPv}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: stats.maxPv > 0
                            ? (stats.currentPv / stats.maxPv).clamp(0.0, 1.0)
                            : 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1E824C),
                                Color(0xFF27AE60),
                                Color(0xFF58D68D),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildStatRow(
                  context,
                  icon: Icons.diamond_rounded,
                  iconColor: Colors.cyanAccent,
                  label: l10n.tooltipManaTitle,
                  value:
                      '${stats.maxMana} ${locale == 'fr' ? 'Cristaux' : 'Crystals'}',
                  child: Row(
                    children: List.generate(
                      stats.maxMana,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.diamond_rounded,
                          color: i < stats.currentMana
                              ? Colors.cyanAccent
                              : Colors.white12,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: SwordIcon(size: 16, color: Colors.orangeAccent),
                        title: locale == 'fr' ? 'Attaque' : 'Attack',
                        value: '${stats.attaque}',
                        subtitle: locale == 'fr'
                            ? 'Dégâts de base'
                            : 'Base damage',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: const Icon(
                          Icons.shield_outlined,
                          color: Colors.lightBlueAccent,
                          size: 16,
                        ),
                        title: locale == 'fr' ? 'Maîtrise' : 'Mastery',
                        value: '+${stats.armorMastery}',
                        subtitle: locale == 'fr'
                            ? "Sur l'Armure Passive"
                            : "On passive armor",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: const Icon(
                          Icons.casino_outlined,
                          color: Colors.amberAccent,
                          size: 16,
                        ),
                        title: locale == 'fr' ? 'Chance' : 'Luck',
                        value: '${stats.luck}',
                        subtitle: locale == 'fr'
                            ? 'Loot & Événements'
                            : 'Loot & Events',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactStatCard(
                        icon: const Icon(
                          Icons.bolt_outlined,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        title: locale == 'fr' ? 'Critique' : 'Critique',
                        value: '${stats.critChance}%',
                        subtitle: 'x${stats.critMultiplier.toStringAsFixed(1)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            size: 18,
                            color: Colors.cyanAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.classPassive.toUpperCase()} : $traitName',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyanAccent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        traitDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.cyanAccent.withValues(alpha: 0.8),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildCompactStatCard({
    required Widget icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
