import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/model_extensions.dart';
import '../../l10n/app_localizations.dart';
import 'game_dialog.dart';
import 'game_button.dart';
import 'ui_card.dart';

class ForgeSlot {
  final int index;
  String upgrade; // e.g. "sharp:2"
  int rerollsCount; // n_i

  ForgeSlot({
    required this.index,
    required this.upgrade,
    this.rerollsCount = 0,
  });

  int get rerollCost => (20 * pow(1.25, rerollsCount)).round();
}

class ForgeUpgradeDialog extends ConsumerStatefulWidget {
  final CardInstance card;

  const ForgeUpgradeDialog({
    super.key,
    required this.card,
  });

  @override
  ConsumerState<ForgeUpgradeDialog> createState() => _ForgeUpgradeDialogState();
}

class _ForgeUpgradeDialogState extends ConsumerState<ForgeUpgradeDialog> {
  late List<ForgeSlot> _slots;
  late int _totalMaxForgeUpgrades;

  @override
  void initState() {
    super.initState();
    final rarityIndex = widget.card.rarity.index;
    _totalMaxForgeUpgrades =
        widget.card.data.baseMaxForgeUpgrades + rarityIndex;
    _slots = _generateInitialSlots(widget.card);
  }

  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName) {
    List<String> poolUpgrades;
    if (poolName == 'common') {
      poolUpgrades = ['sharp', 'hardened', 'burning', 'freezing', 'shocking'];
    } else if (poolName == 'uncommon') {
      poolUpgrades = [
        'sharp',
        'hardened',
        'burning',
        'freezing',
        'shocking',
        'quick',
      ];
    } else {
      // rare
      poolUpgrades = [
        'sharp',
        'hardened',
        'burning',
        'freezing',
        'shocking',
        'quick',
        'eco',
        'enduring',
      ];
    }

    final eligible = <String>[];
    for (final id in poolUpgrades) {
      final alreadyHas = card.forgeUpgrades.any((u) => u.split(':')[0] == id);
      if (alreadyHas) continue;

      if ((id == 'burning' || id == 'freezing' || id == 'shocking') &&
          card.data.type != CardType.attack) {
        continue;
      }
      if (id == 'enduring' &&
          (!card.data.isExhaust || card.data.type == CardType.power)) {
        continue;
      }

      eligible.add(id);
    }
    return eligible;
  }

  String? _rollUpgradeId(
    CardInstance card,
    Random rand,
    List<String> excludedIdsInCurrentRolls,
  ) {
    final r = rand.nextInt(100);
    String targetPool;
    if (card.rarity == CardRarity.common) {
      targetPool = 'common';
    } else if (card.rarity == CardRarity.uncommon) {
      targetPool = r < 75 ? 'common' : 'uncommon';
    } else {
      targetPool = r < 65 ? 'common' : (r < 90 ? 'uncommon' : 'rare');
    }

    List<String> poolOrder = ['rare', 'uncommon', 'common'];
    int startIndex = poolOrder.indexOf(targetPool);
    if (startIndex == -1) startIndex = 2;

    for (int i = startIndex; i < poolOrder.length; i++) {
      final pool = poolOrder[i];
      final eligible = _getEligibleUpgradesForPool(card, pool)
          .where((id) => !excludedIdsInCurrentRolls.contains(id))
          .toList();
      if (eligible.isNotEmpty) {
        return eligible[rand.nextInt(eligible.length)];
      }
    }

    for (final pool in poolOrder) {
      final eligible = _getEligibleUpgradesForPool(card, pool)
          .where((id) => !excludedIdsInCurrentRolls.contains(id))
          .toList();
      if (eligible.isNotEmpty) {
        return eligible[rand.nextInt(eligible.length)];
      }
    }
    return null;
  }

  String _rollSlotUpgrade(CardInstance card, List<String> excludedIds) {
    final rand = Random();
    String? rolledId = _rollUpgradeId(card, rand, excludedIds);
    rolledId ??= _rollUpgradeId(card, rand, []);
    rolledId ??= 'sharp';

    int tier = 1;
    if (rolledId != 'enduring') {
      final t = rand.nextInt(100);
      if (t < 80) {
        tier = 1;
      } else if (t < 95) {
        tier = 2;
      } else {
        tier = 3;
      }
    }
    return '$rolledId:$tier';
  }

  List<ForgeSlot> _generateInitialSlots(CardInstance card) {
    final List<ForgeSlot> slots = [];
    final List<String> excludedIds = [];
    final rand = Random();

    final upg1 = _rollSlotUpgrade(card, excludedIds);
    slots.add(ForgeSlot(index: 0, upgrade: upg1));
    excludedIds.add(upg1.split(':')[0]);

    if (rand.nextDouble() < 0.50) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 1, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.25) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 2, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.10) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 3, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.02) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 4, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    return slots;
  }

  void _rerollSlot(int slotIndex, int cost) {
    final success = ref.read(inventoryProvider.notifier).spendGold(cost);
    if (!success) return;

    setState(() {
      final slotIdx = _slots.indexWhere((s) => s.index == slotIndex);
      if (slotIdx != -1) {
        final excludedIds = _slots
            .where((s) => s.index != slotIndex)
            .map((s) => s.upgrade.split(':')[0])
            .toList();

        final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
        _slots[slotIdx].upgrade = newUpgrade;
        _slots[slotIdx].rerollsCount += 1;
      }
    });
  }

  void _selectUpgrade(String upgrade) {
    ref
        .read(deckProvider.notifier)
        .addForgeUpgrade(widget.card.uniqueId, upgrade);
    Navigator.of(context).pop(upgrade);
  }

  String _getTranslation(String en, String fr) {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'fr' ? fr : en;
  }

  String _getUpgradeName(String upgrade) {
    final parts = upgrade.split(':');
    final id = parts[0];
    final tier = parts.length > 1 ? parts[1] : '1';
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

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
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

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

  @override
  Widget build(BuildContext context) {
    final currentGold = ref.watch(inventoryProvider).gold;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    return GameDialog(
      glowColor: Colors.amber,
      maxWidth: 750,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTranslation('FORGE UPGRADE', 'AMÉLIORATION FORGE'),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$currentGold',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      subtitle: Text(
        _getTranslation(
          'Select an upgrade slot or reroll options',
          'Choisissez une amélioration ou relancez les options',
        ),
      ),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isVertical = constraints.maxWidth < 600;
                final content = [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 170,
                        child: UiCard(
                          title: widget.card.data.getName(locale),
                          description: widget.card.data.getDescription(locale),
                          cost: widget.card.data.cost,
                          effects: widget.card.data.effects,
                          type: widget.card.data.type,
                          targetType: widget.card.data.target,
                          isExhaust: widget.card.data.isExhaust,
                          rarity: widget.card.rarity.getLabel(l10n),
                          forgeUpgrades: widget.card.forgeUpgrades,
                          rarityMultiplier: widget.card.rarityMultiplier,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getTranslation('CAPACITY', 'CAPACITÉ'),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_totalMaxForgeUpgrades, (i) {
                          final isUsed = i < widget.card.forgeUpgrades.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              isUsed ? Icons.star : Icons.star_border,
                              color: isUsed ? Colors.amber : Colors.white24,
                              size: 20,
                              shadows: isUsed
                                  ? [
                                      const Shadow(
                                        color: Colors.amberAccent,
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.card.forgeUpgrades.length} / $_totalMaxForgeUpgrades ${_getTranslation('Upgrades', 'Améliorations')}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  if (!isVertical) const SizedBox(width: 32),
                  if (isVertical)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white12),
                    ),
                  Expanded(
                    flex: isVertical ? 0 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _getTranslation('AVAILABLE FORGE SLOTS', 'OFFRES DE LA FORGE'),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._slots.map((slot) {
                          final upgradeId = slot.upgrade.split(':')[0];
                          final upgradeColor = _getUpgradeColor(upgradeId);
                          final upgradeIcon = _getUpgradeIcon(upgradeId);
                          final upgradeName = _getUpgradeName(slot.upgrade);
                          final upgradeDesc = _getUpgradeDescription(slot.upgrade);
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
                                      onTap: canAffordReroll
                                          ? () => _rerollSlot(slot.index, rerollCost)
                                          : null,
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
                                      onPressed: () => _selectUpgrade(slot.upgrade),
                                      baseColor: upgradeColor,
                                      height: 36,
                                      fontSize: 13,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ];

                if (isVertical) {
                  return Column(
                    children: content.cast<Widget>(),
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: content.cast<Widget>(),
                  );
                }
              },
            ),
            const SizedBox(height: 24),
            GameButton(
              text: _getTranslation('Cancel', 'Annuler'),
              onPressed: () => Navigator.of(context).pop(),
              baseColor: Colors.white70,
              height: 40,
              width: 120,
            ),
          ],
        ),
      ),
    );
  }
}
