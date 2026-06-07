import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/model_extensions.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import '../../../../game/controllers/inventory_controller.dart';
import '../../../../models/data/relic_data.dart';

class RelicsDialog extends ConsumerWidget {
  const RelicsDialog({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'InventoryOverlay',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return const RelicsDialog();
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
    final inventoryState = ref.watch(inventoryProvider);
    final relics = inventoryState.relics;

    final Map<String, int> relicCounts = {};
    final Map<String, RelicData> relicMap = {};
    for (var r in relics) {
      relicCounts[r.id] = (relicCounts[r.id] ?? 0) + 1;
      relicMap[r.id] = r;
    }
    final uniqueIds = relicCounts.keys.toList();

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GameDialog(
      glowColor: Colors.amberAccent,
      maxWidth: min(MediaQuery.of(context).size.width * 0.9, 850),
      title: Row(
        children: [
          const Icon(
            Icons.inventory_2,
            color: Colors.amber,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.relicInventory.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  locale == 'fr'
                      ? 'Objets magiques passifs en votre possession'
                      : 'Passive magical items in your possession',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Material(
        color: Colors.transparent,
        child: SizedBox(
          height: min(MediaQuery.of(context).size.height * 0.55, 450),
          child: relics.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.emptyInventory,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32.0,
                      ),
                      child: Text(
                        locale == 'fr'
                            ? 'Triomphez des monstres Élites ou explorez la Boutique pour acquérir des Reliques et obtenir de précieux effets passifs.'
                            : 'Defeat Elite monsters or explore the Shop to acquire Relics and obtain precious passive effects.',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final double availableWidth = constraints.maxWidth;
                    final double cardWidth = (availableWidth - 16) / 2;
                    const double cardHeight = 110;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: uniqueIds.map((id) {
                          final relic = relicMap[id]!;
                          final count = relicCounts[id]!;
                          return SizedBox(
                            width: cardWidth,
                            height: cardHeight,
                            child: _buildRelicCard(
                              context,
                              relic,
                              count,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildRelicCard(BuildContext context, RelicData relic, int count) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    Color triggerColor = Colors.grey;
    String triggerText = 'Passif';
    switch (relic.trigger) {
      case RelicTrigger.startOfRun:
        triggerText = l10n.relicTriggerRun;
        triggerColor = Colors.blueAccent;
        break;
      case RelicTrigger.startOfCombat:
        triggerText = l10n.relicTriggerCombat;
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.startOfTurn:
        triggerText = l10n.relicTriggerTurnStart;
        triggerColor = Colors.greenAccent;
        break;
      case RelicTrigger.endOfTurn:
        triggerText = l10n.relicTriggerTurnEnd;
        triggerColor = Colors.amberAccent;
        break;
      case RelicTrigger.onCardPlayed:
        triggerText = l10n.relicTriggerCardPlayed;
        triggerColor = Colors.purpleAccent;
        break;
      case RelicTrigger.onEnemyKilled:
        triggerText = l10n.relicTriggerEnemyKilled;
        triggerColor = Colors.orangeAccent;
        break;
      case RelicTrigger.onAttackPlayed:
        triggerText = locale == 'fr' ? 'Attaque Jouée' : 'Attack Played';
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.onSkillPlayed:
        triggerText = locale == 'fr' ? 'Compétence Jouée' : 'Skill Played';
        triggerColor = Colors.cyanAccent;
        break;
      case RelicTrigger.onPowerPlayed:
        triggerText = locale == 'fr' ? 'Pouvoir Joué' : 'Power Played';
        triggerColor = Colors.pinkAccent;
        break;
    }

    Color rarityColor = relic.rarity.color;
    String rarityText = relic.rarity.getLabel(l10n).toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rarityColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: rarityColor.withValues(alpha: 0.15), blurRadius: 10),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(relic.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relic.getName(locale),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: triggerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: triggerColor.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      triggerText,
                      style: TextStyle(
                        color: triggerColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    relic.getDescription(locale),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rarityText,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (count > 1)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  '×$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
