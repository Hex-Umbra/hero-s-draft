import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/model_extensions.dart';
import '../../l10n/app_localizations.dart';
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

    final runState = ref.read(runProvider);
    if (runState.forgeTargetSessions.containsKey(widget.card.uniqueId)) {
      _slots = [];
      final savedSlots = runState.forgeTargetSessions[widget.card.uniqueId]!;
      for (int i = 0; i < savedSlots.length; i++) {
        final s = savedSlots[i];
        final parts = s.split(':');
        final id = parts[0];
        final tier = parts.length > 1 ? parts[1] : '1';
        final rerolls = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
        _slots.add(ForgeSlot(
          index: i,
          upgrade: '$id:$tier',
          rerollsCount: rerolls,
        ));
      }
    } else {
      _slots = _generateInitialSlots(widget.card);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(runProvider.notifier).setForgeSession(
          widget.card.uniqueId,
          _slots.map((s) => '${s.upgrade}:${s.rerollsCount}').toList(),
        );
      });
    }
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

      // Card type specific exclusions:
      if (card.data.type == CardType.skill) {
        if (id == 'sharp' || id == 'burning' || id == 'freezing' || id == 'shocking') {
          continue;
        }
      }
      if (card.data.type == CardType.power) {
        if (id != 'eco' && id != 'quick' && id != 'enduring') {
          continue;
        }
      }

      if ((id == 'burning' || id == 'freezing' || id == 'shocking') &&
          card.data.type != CardType.attack) {
        continue;
      }
      if (id == 'enduring' && !card.data.isExhaust) {
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

    // Add existing bonus slots
    final runState = ref.read(runProvider);
    final bonusCount = runState.bonusForgeSlots;
    for (int i = 0; i < bonusCount; i++) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      final newIndex = slots.isEmpty ? 0 : slots.map((s) => s.index).reduce(max) + 1;
      slots.add(ForgeSlot(index: newIndex, upgrade: upg));
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

    ref.read(runProvider.notifier).setForgeSession(
      widget.card.uniqueId,
      _slots.map((s) => '${s.upgrade}:${s.rerollsCount}').toList(),
    );
  }

  void _onBuySlotTapped() {
    final success = ref.read(runProvider.notifier).buyBonusForgeSlot();
    if (!success) return;

    setState(() {
      final excludedIds = _slots.map((s) => s.upgrade.split(':')[0]).toList();
      final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
      final newIndex = _slots.isEmpty ? 0 : _slots.map((s) => s.index).reduce(max) + 1;
      _slots.add(ForgeSlot(index: newIndex, upgrade: newUpgrade));
    });

    ref.read(runProvider.notifier).setForgeSession(
      widget.card.uniqueId,
      _slots.map((s) => '${s.upgrade}:${s.rerollsCount}').toList(),
    );
  }

  void _selectUpgrade(String upgrade) {
    ref
        .read(deckProvider.notifier)
        .addForgeUpgrade(widget.card.uniqueId, upgrade);
    ref.read(runProvider.notifier).clearForgeSession();
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

  Widget _buildSlotRow(ForgeSlot slot, int currentGold) {
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
  }

  Widget _buildBuySlotButton(bool canBuySlot, bool hasEnoughGold, int nextCost, int currentBonusSlots) {
    final bool isEnabled = canBuySlot && hasEnoughGold;
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    String buttonText;
    if (currentBonusSlots >= 4 || _slots.length >= 5) {
      buttonText = isFr
          ? 'Capacité maximale atteinte (5 slots)'
          : 'Maximum capacity reached (5 slots)';
    } else {
      buttonText = isFr
          ? 'Acheter une fente supplémentaire ($nextCost Or)'
          : 'Buy an additional slot ($nextCost Gold)';
    }

    return InkWell(
      onTap: isEnabled ? _onBuySlotTapped : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.amber.withAlpha(25)
              : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEnabled
                ? Colors.amber.withAlpha(150)
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: isEnabled ? Colors.amber : Colors.white30,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              buttonText,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white30,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final currentGold = ref.watch(inventoryProvider).gold;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    final bonusCount = runState.bonusForgeSlots;
    final nextCost = bonusCount < 4 ? [50, 80, 120, 175][bonusCount] : 0;
    final canBuySlot = bonusCount < 4 && _slots.length < 5;
    final hasEnoughGold = currentGold >= nextCost;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF0D0D1A),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                const Color(0xFF1E1000).withAlpha(180),
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTranslation('FORGE UPGRADE', 'AMÉLIORATION FORGE'),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getTranslation(
                              'Select an upgrade slot or reroll options',
                              'Choisissez une amélioration ou relancez les options',
                            ),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amberAccent.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              '$currentGold',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 24),

                  // MAIN RESPONSIVE CONTENT
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 720;

                        // Left panel: Card + capacity info
                        final cardPanel = SizedBox(
                          width: isDesktop ? 240 : double.infinity,
                          child: Column(
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
                              const SizedBox(height: 20),
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
                              const SizedBox(height: 6),
                              Text(
                                '${widget.card.forgeUpgrades.length} / $_totalMaxForgeUpgrades ${_getTranslation('Upgrades', 'Améliorations')}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        );

                        // Right panel: Scrollable list of options + Buy slot button
                        final listPanel = Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  _getTranslation('AVAILABLE FORGE SLOTS', 'OFFRES DE LA FORGE'),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  children: [
                                    ..._slots.map((slot) => _buildSlotRow(slot, currentGold)),
                                    const SizedBox(height: 16),
                                    _buildBuySlotButton(canBuySlot, hasEnoughGold, nextCost, runState.bonusForgeSlots),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              cardPanel,
                              const SizedBox(width: 48),
                              listPanel,
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              cardPanel,
                              const SizedBox(height: 24),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 12),
                              listPanel,
                            ],
                          );
                        }
                      },
                    ),
                  ),

                  // FOOTER / ACTIONS
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GameButton(
                        text: _getTranslation('Cancel', 'Annuler'),
                        onPressed: () => Navigator.of(context).pop(),
                        baseColor: Colors.white70,
                        height: 44,
                        width: 140,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
