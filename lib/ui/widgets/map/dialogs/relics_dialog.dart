import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/controllers/run_controller.dart';
import '../../../../models/data/relic_data.dart';
import '../../blur_wrapper.dart';

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
    final runState = ref.watch(runProvider);
    final relics = runState.relics;

    // Regroupement des reliques par doublon (stacking)
    final Map<String, int> relicCounts = {};
    final Map<String, RelicData> relicMap = {};
    for (var r in relics) {
      relicCounts[r.id] = (relicCounts[r.id] ?? 0) + 1;
      relicMap[r.id] = r;
    }
    final uniqueIds = relicCounts.keys.toList();

    return BlurWrapper(
      sigma: 8,
      child: Center(
        child: Container(
          width: min(MediaQuery.of(context).size.width * 0.9, 850),
          height: min(MediaQuery.of(context).size.height * 0.85, 650),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.1),
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
                    const Icon(Icons.inventory_2, color: Colors.amber, size: 32),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVENTAIRE DES RELIQUES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          Text(
                            'Objets magiques passifs en votre possession',
                            style: TextStyle(
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
                Expanded(
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
                            const Text(
                              'Votre inventaire est vide',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                'Triomphez des monstres Élites ou explorez la Boutique pour acquérir des Reliques et obtenir de précieux effets passifs.',
                                style: TextStyle(
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
                            // Une relique prend exactement la moitié de la largeur disponible (2 colonnes) avec un espacement de 16px
                            final double cardWidth = (availableWidth - 16) / 2;
                            const double cardHeight =
                                110; // Hauteur réduite de moitié pour un affichage compact et fluide

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
                                    child: _buildRelicCard(relic, count),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelicCard(RelicData relic, int count) {
    Color triggerColor = Colors.grey;
    String triggerText = 'Passif';
    switch (relic.trigger) {
      case RelicTrigger.startOfRun:
        triggerText = 'Début Run';
        triggerColor = Colors.blueAccent;
        break;
      case RelicTrigger.startOfCombat:
        triggerText = 'Début Combat';
        triggerColor = Colors.redAccent;
        break;
      case RelicTrigger.startOfTurn:
        triggerText = 'Début Tour';
        triggerColor = Colors.greenAccent;
        break;
      case RelicTrigger.endOfTurn:
        triggerText = 'Fin Tour';
        triggerColor = Colors.amberAccent;
        break;
      case RelicTrigger.onCardPlayed:
        triggerText = 'Carte Jouée';
        triggerColor = Colors.purpleAccent;
        break;
      case RelicTrigger.onEnemyKilled:
        triggerText = 'Ennemi Tué';
        triggerColor = Colors.orangeAccent;
        break;
    }

    Color rarityColor = Colors.grey;
    String rarityText = 'Commun';
    switch (relic.rarity) {
      case RelicRarity.common:
        rarityColor = const Color(0xFF8E8E93);
        rarityText = 'COMMUN';
        break;
      case RelicRarity.uncommon:
        rarityColor = const Color(0xFF34C759);
        rarityText = 'PEU COMMUN';
        break;
      case RelicRarity.rare:
        rarityColor = const Color(0xFF007AFF);
        rarityText = 'RARE';
        break;
      case RelicRarity.epic:
        rarityColor = const Color(0xFFAF52DE);
        rarityText = 'ÉPIQUE';
        break;
      case RelicRarity.legendary:
        rarityColor = const Color(0xFFFFCC00);
        rarityText = 'LÉGENDAIRE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: rarityColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
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
                  Text(
                    relic.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      relic.name,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: triggerColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: triggerColor.withValues(alpha: 0.3),
                          width: 0.5),
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
                    relic.description,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
