import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/run_controller.dart';
import '../sword_icon.dart';
import 'dialogs/probabilities_dialog.dart';
import 'dialogs/stats_dialog.dart';

class HeroMiniStatsPanel extends ConsumerWidget {
  const HeroMiniStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runProvider);
    final stats = runState.heroStats;

    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3728).withAlpha(230), // Brun foncé
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD2B48C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 165,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    locale == 'fr' ? 'STATS DU HÉROS' : 'HERO STATS',
                    style: const TextStyle(
                      color: Color(0xFFE8D5B5), // Parchemin
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Tooltip(
                  message: locale == 'fr'
                      ? 'Afficher les détails'
                      : 'Show details',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => StatsDialog.show(context),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.visibility_outlined,
                          color: Color(0xFFE8D5B5),
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 165,
            height: 1,
            color: const Color(0xFFD2B48C).withAlpha(80),
          ),
          const SizedBox(height: 8),
          // PV
          _buildMiniStatRow(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            value:
                '${stats.currentPv}/${stats.maxPv} ${locale == 'fr' ? 'PV' : 'HP'}',
          ),
          const SizedBox(height: 6),
          // Mana
          _buildMiniStatRow(
            icon: Icons.diamond_rounded,
            iconColor: Colors.cyanAccent,
            value: '${stats.currentMana}/${stats.maxMana} Mana',
          ),
          const SizedBox(height: 6),
          // Attaque
          _buildMiniStatRowWidget(
            icon: SwordIcon(size: 16, color: Colors.orangeAccent),
            value: '${stats.attaque} ${locale == 'fr' ? 'Attaque' : 'Attack'}',
          ),
          const SizedBox(height: 6),
          // Maîtrise
          _buildMiniStatRow(
            icon: Icons.shield_outlined,
            iconColor: Colors.lightBlueAccent,
            value:
                '+${stats.armorMastery} ${locale == 'fr' ? 'Maîtrise' : 'Mastery'}',
          ),
          const SizedBox(height: 6),
          // Chance
          SizedBox(
            width: 165,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStatRow(
                  icon: Icons.casino_outlined,
                  iconColor: Colors.amberAccent,
                  value: '${stats.luck} ${locale == 'fr' ? 'Chance' : 'Luck'}',
                ),
                Tooltip(
                  message: locale == 'fr'
                      ? 'Voir les probabilités'
                      : 'View probabilities',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => ProbabilitiesDialog.show(context),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.info_outline,
                          color: Color(0xFFE8D5B5),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 165,
            height: 1,
            color: const Color(0xFFD2B48C).withAlpha(80),
          ),
          const SizedBox(height: 8),
          // Jauge d'XP
          _buildXpBar(context, stats, locale),
        ],
      ),
    );
  }

  Widget _buildXpBar(BuildContext context, dynamic stats, String locale) {
    final double progress = stats.xpToNextLevel > 0
        ? (stats.xp / stats.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP: ${stats.xp}/${stats.xpToNextLevel}',
              style: const TextStyle(
                color: Color(0xFFE8D5B5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.amber.withAlpha(120), width: 0.5),
              ),
              child: Text(
                locale == 'fr' ? 'Niv. ${stats.level}' : 'Lvl. ${stats.level}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            width: 165,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black38,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatRow({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8D5B5),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatRowWidget({
    required Widget icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 16, height: 16, child: Center(child: icon)),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8D5B5),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
