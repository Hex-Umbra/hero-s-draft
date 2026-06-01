import 'package:flutter/material.dart';

class DraftChoiceCard extends StatelessWidget {
  final String title;
  final String description;
  final String rarity;
  final VoidCallback onTap;

  const DraftChoiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.rarity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine rarity color matching the game's theme
    Color rarityColor = const Color(0xFF8E8E93); // Common Gray
    final rarityUpper = rarity.toUpperCase();
    
    if (rarityUpper == 'HORS NORME' ||
        rarityUpper == 'UNCOMMON' ||
        rarityUpper == 'ATYPIQUE') {
      rarityColor = const Color(0xFF34C759); // Uncommon Green
    } else if (rarityUpper == 'RARE') {
      rarityColor = const Color(0xFF007AFF); // Rare Blue
    } else if (rarityUpper == 'ÉPIQUE' || rarityUpper == 'EPIC') {
      rarityColor = const Color(0xFFAF52DE); // Epic Purple
    } else if (rarityUpper == 'LÉGENDAIRE' || rarityUpper == 'LEGENDARY') {
      rarityColor = const Color(0xFFFFCC00); // Legendary Gold
    }

    // 2. Map Draft Upgrades to intuitive thematic icons/emojis
    String emoji = '✨';
    final titleUpper = title.toUpperCase();
    if (titleUpper.contains('VITALIT') || titleUpper.contains('VITALITY')) {
      emoji = '❤️'; // Vitality / HP
    } else if (titleUpper.contains('AIGUIS') || titleUpper.contains('SHARPEN')) {
      emoji = '⚔️'; // Attack Power
    } else if (titleUpper.contains('FORGE')) {
      emoji = '🛡️'; // Armor Mastery
    } else if (titleUpper.contains('SAGESSE') || titleUpper.contains('WISDOM')) {
      emoji = '🔮'; // Mana Max
    } else if (titleUpper.contains('TRÈFLE') || titleUpper.contains('CLOVER')) {
      emoji = '🍀'; // Luck Boost
    } else if (titleUpper.contains('MIROIR') || titleUpper.contains('MIRROR')) {
      emoji = '🪞'; // Mirror Cloning
    }

    final isLegendary = rarityUpper == 'LÉGENDAIRE' || rarityUpper == 'LEGENDARY';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        height: 240,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A3D),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: rarityColor.withValues(alpha: 0.8),
            width: isLegendary ? 3.0 : 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: rarityColor.withValues(alpha: isLegendary ? 0.45 : 0.2),
              blurRadius: isLegendary ? 20 : 8,
              spreadRadius: isLegendary ? 3 : 1,
            ),
          ],
        ),
        child: Column(
          children: [
            // Rarity Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: rarityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                rarity.toUpperCase(),
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            // Large Upgrade Icon
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const Spacer(),
            // Upgrade Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Description of stat boost
            Expanded(
              flex: 4,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
