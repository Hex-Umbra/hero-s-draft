import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../forge_upgrade_dialog.dart'; // Pour ForgeSlot
import '../game_button.dart';

class ForgeSlotRow extends StatelessWidget {
  final ForgeSlot slot;
  final int currentGold;
  final String locale;
  final AppLocalizations l10n;
  final VoidCallback onReroll;
  final VoidCallback onSelect;

  const ForgeSlotRow({
    super.key,
    required this.slot,
    required this.currentGold,
    required this.locale,
    required this.l10n,
    required this.onReroll,
    required this.onSelect,
  });

  String _getTranslation(String en, String fr) {
    return locale == 'fr' ? fr : en;
  }

  String _getUpgradeName(String upgrade) {
    final parts = upgrade.split(':');
    final id = parts[0];
    final tier = parts.length > 1 ? parts[1] : '1';
    final isFr = locale == 'fr';

    switch (id) {
      case 'sharp':
        return isFr ? 'Tranchant $tier' : 'Sharp $tier';
      case 'hardened':
        return isFr ? 'Endurci $tier' : 'Hardened $tier';
      case 'burning':
        return isFr ? 'Brûlant $tier' : 'Burning $tier';
      case 'freezing':
        return isFr ? 'Congelant $tier' : 'Freezing $tier';
      case 'shocking':
        return isFr ? 'Surchargé $tier' : 'Shocking $tier';
      case 'quick':
        return isFr ? 'Véloce $tier' : 'Quick $tier';
      case 'eco':
        return isFr ? 'Économe $tier' : 'Eco $tier';
      case 'enduring':
        return isFr ? 'Persistant' : 'Enduring';
      default:
        return id;
    }
  }

  String _getUpgradeDescription(String upgrade) {
    final parts = upgrade.split(':');
    final id = parts[0];
    final tierStr = parts.length > 1 ? parts[1] : '1';
    final tier = int.tryParse(tierStr) ?? 1;
    final isFr = locale == 'fr';

    switch (id) {
      case 'sharp':
        final val = 2 * tier;
        return isFr ? '+$val Dégâts sur la carte' : '+$val Damage on the card';
      case 'hardened':
        final val = 2 * tier;
        return isFr ? '+$val Armure sur la carte' : '+$val Block on the card';
      case 'burning':
        return isFr ? 'Applique $tier Brûlure' : 'Applies $tier Burn';
      case 'freezing':
        return isFr ? 'Applique $tier Gel' : 'Applies $tier Freeze';
      case 'shocking':
        return isFr ? 'Applique $tier Électrocution' : 'Applies $tier Shock';
      case 'quick':
        return isFr ? 'Pioche +$tier carte(s)' : 'Draw +$tier card(s)';
      case 'eco':
        return isFr ? 'Gagne +$tier Mana à l\'utilisation' : 'Gains +$tier Mana on play';
      case 'enduring':
        return isFr ? 'Retire Épuisement (Exhaust)' : 'Removes Exhaust';
      default:
        return '';
    }
  }

  IconData _getUpgradeIcon(String id) {
    switch (id) {
      case 'sharp':
        return Icons.hardware_rounded;
      case 'hardened':
        return Icons.shield_rounded;
      case 'burning':
        return Icons.local_fire_department_rounded;
      case 'freezing':
        return Icons.ac_unit_rounded;
      case 'shocking':
        return Icons.flash_on_rounded;
      case 'quick':
        return Icons.style_rounded;
      case 'eco':
        return Icons.diamond_rounded;
      case 'enduring':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Color _getUpgradeColor(String id) {
    switch (id) {
      case 'sharp':
        return Colors.redAccent;
      case 'hardened':
        return Colors.blueAccent;
      case 'burning':
        return Colors.orangeAccent;
      case 'freezing':
        return Colors.lightBlueAccent;
      case 'shocking':
        return Colors.amberAccent;
      case 'quick':
        return Colors.amber;
      case 'eco':
        return Colors.cyanAccent;
      case 'enduring':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
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

    // Extraction dynamique avec conservation des fallbacks
    final upgradeColor = upgradeData != null
        ? _getUpgradeColorFromString(upgradeData.color)
        : _getUpgradeColor(upgradeId);
    final upgradeIcon = upgradeData != null
        ? _getUpgradeIconFromString(upgradeData.icon)
        : _getUpgradeIcon(upgradeId);
    final upgradeName = upgradeData != null
        ? upgradeData.getName(locale) + (upgradeId == 'enduring' ? '' : ' $tier')
        : _getUpgradeName(slot.upgrade);
    final upgradeDesc = upgradeData != null
        ? upgradeData.getDescription(tier, locale)
        : _getUpgradeDescription(slot.upgrade);

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
