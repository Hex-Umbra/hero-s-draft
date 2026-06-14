import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../l10n/app_localizations.dart';
import 'game_button.dart';
import 'forge/forge_card_preview.dart';
import 'forge/forge_slot_row.dart';
import 'forge/forge_buy_slot_button.dart';

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


  String _getBuySlotButtonText(bool canBuySlot, int nextCost, int currentBonusSlots) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    if (currentBonusSlots >= 4 || _slots.length >= 5) {
      return isFr
          ? 'Capacité maximale atteinte (5 slots)'
          : 'Maximum capacity reached (5 slots)';
    } else {
      return isFr
          ? 'Acheter une fente supplémentaire ($nextCost Or)'
          : 'Buy an additional slot ($nextCost Gold)';
    }
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
                          child: ForgeCardPreview(
                            card: widget.card,
                            totalMaxForgeUpgrades: _totalMaxForgeUpgrades,
                            locale: locale,
                            l10n: l10n,
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
                                    ..._slots.map((slot) => ForgeSlotRow(
                                          slot: slot,
                                          currentGold: currentGold,
                                          locale: locale,
                                          l10n: l10n,
                                          onReroll: () => _rerollSlot(slot.index, slot.rerollCost),
                                          onSelect: () => _selectUpgrade(slot.upgrade),
                                        )),
                                    const SizedBox(height: 16),
                                    ForgeBuySlotButton(
                                      isEnabled: canBuySlot && hasEnoughGold,
                                      text: _getBuySlotButtonText(canBuySlot, nextCost, runState.bonusForgeSlots),
                                      onPressed: _onBuySlotTapped,
                                    ),
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
