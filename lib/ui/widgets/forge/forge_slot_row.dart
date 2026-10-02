import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../forge_upgrade_dialog.dart'; // Pour ForgeSlot
import '../game_button.dart';

class ForgeSlotRow extends StatelessWidget {
  final ForgeSlot slot;

  /// La carte que la forge améliore : la fente dit ce que la rune lui ajoute
  /// (spec P-43 E1, §5.1).
  final CardInstance card;
  final int currentGold;
  final String locale;
  final AppLocalizations l10n;
  final VoidCallback onReroll;
  final VoidCallback onSelect;

  const ForgeSlotRow({
    super.key,
    required this.slot,
    required this.card,
    required this.currentGold,
    required this.locale,
    required this.l10n,
    required this.onReroll,
    required this.onSelect,
  });

  String _getTranslation(String en, String fr) {
    return locale == 'fr' ? fr : en;
  }

  Color _getUpgradeColorFromString(String colorStr) {
    switch (colorStr) {
      case 'redAccent':
        return Colors.redAccent;
      case 'blueAccent':
        return Colors.blueAccent;
      case 'orangeAccent':
        return Colors.orangeAccent;
      case 'lightBlueAccent':
        return Colors.lightBlueAccent;
      case 'amberAccent':
        return Colors.amberAccent;
      case 'amber':
        return Colors.amber;
      case 'cyanAccent':
        return Colors.cyanAccent;
      case 'greenAccent':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getUpgradeIconFromString(String iconStr) {
    switch (iconStr) {
      case 'hardware_rounded':
        return Icons.hardware_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'local_fire_department_rounded':
        return Icons.local_fire_department_rounded;
      case 'ac_unit_rounded':
        return Icons.ac_unit_rounded;
      case 'flash_on_rounded':
        return Icons.flash_on_rounded;
      case 'style_rounded':
        return Icons.style_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'hourglass_bottom_rounded':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = slot.upgrade.split(':');
    final upgradeId = parts[0];
    final tierStr = parts.length > 1 ? parts[1] : '1';
    final tier = int.tryParse(tierStr) ?? 1;

    final upgradeData = ForgeUpgradeData.getById(upgradeId);

    // Une rune absente du registre s'affiche sous son id, sans description,
    // avec l'icône et la couleur par défaut (spec P-43 E1, §5.2).
    final upgradeColor = _getUpgradeColorFromString(upgradeData?.color ?? '');
    final upgradeIcon = _getUpgradeIconFromString(upgradeData?.icon ?? '');
    final upgradeName = upgradeData != null
        ? upgradeData.getName(locale) + (upgradeData.stackable ? ' $tier' : '')
        : upgradeId;
    // Ce que la fente ajoute à cette carte, au-delà de ce que la carte porte
    // déjà de cette rune (spec P-43 E1, §5.1).
    final upgradeDesc = upgradeData?.getDescription(
          tier,
          locale,
          card.data,
          card.rarity,
          carried: ForgeUpgradeData.levelsOf(card.forgeUpgrades)[upgradeId] ?? 0,
        ) ??
        '';

    final rerollCost = slot.rerollCost;
    final canAffordReroll = currentGold >= rerollCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: upgradeColor.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: upgradeColor.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: upgradeColor.withAlpha(100),
              ),
            ),
            child: Icon(
              upgradeIcon,
              color: upgradeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upgradeName,
                  style: TextStyle(
                    color: upgradeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  upgradeDesc,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: canAffordReroll ? onReroll : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: canAffordReroll
                        ? Colors.orangeAccent.withAlpha(20)
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canAffordReroll
                          ? Colors.orangeAccent.withAlpha(120)
                          : Colors.white24,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.autorenew,
                        color: canAffordReroll
                            ? Colors.orangeAccent
                            : Colors.white30,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$rerollCost',
                        style: TextStyle(
                          color: canAffordReroll
                              ? Colors.white
                              : Colors.white30,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GameButton(
                text: _getTranslation('Forge', 'Forger'),
                onPressed: onSelect,
                baseColor: upgradeColor,
                height: 36,
                fontSize: 13,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
