import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/data/relic_data.dart';
import '../../models/map_node.dart';
import '../../services/game_data_service.dart';
import '../widgets/screen_scaffold.dart';

class RelicExchangeScreen extends ConsumerStatefulWidget {
  final MapNode node;

  const RelicExchangeScreen({super.key, required this.node});

  @override
  ConsumerState<RelicExchangeScreen> createState() => _RelicExchangeScreenState();
}

class _RelicExchangeScreenState extends ConsumerState<RelicExchangeScreen> {
  RelicData? _offeredRelic;
  RelicRarity? _requiredRarity;
  final Set<int> _selectedOriginalIndices = {};

  RelicRarity _getRequiredSacrificeRarity(RelicRarity offered) {
    switch (offered) {
      case RelicRarity.uncommon:
        return RelicRarity.common;
      case RelicRarity.rare:
        return RelicRarity.uncommon;
      case RelicRarity.epic:
        return RelicRarity.rare;
      case RelicRarity.legendary:
        return RelicRarity.epic;
      default:
        return RelicRarity.common;
    }
  }

  String _getRelicRarityLabel(BuildContext context, RelicRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case RelicRarity.common:
        return l10n.rarityCommon;
      case RelicRarity.uncommon:
        return l10n.rarityUncommon;
      case RelicRarity.rare:
        return l10n.rarityRare;
      case RelicRarity.epic:
        return l10n.rarityEpic;
      case RelicRarity.legendary:
        return l10n.rarityLegendary;
    }
  }

  Color _getRelicRarityColor(RelicRarity rarity) {
    switch (rarity) {
      case RelicRarity.common:
        return const Color(0xFF8E8E93);
      case RelicRarity.uncommon:
        return const Color(0xFF34C759);
      case RelicRarity.rare:
        return const Color(0xFF007AFF);
      case RelicRarity.epic:
        return const Color(0xFFAF52DE);
      case RelicRarity.legendary:
        return const Color(0xFFFFCC00);
    }
  }

  void _onRelicTap(int index) {
    setState(() {
      if (_selectedOriginalIndices.contains(index)) {
        _selectedOriginalIndices.remove(index);
      } else {
        if (_selectedOriginalIndices.length < 3) {
          _selectedOriginalIndices.add(index);
        }
      }
    });
  }

  void _performExchange(List<RelicData> inventory) {
    if (_offeredRelic == null || _selectedOriginalIndices.length != 3) return;

    final sacrificed = _selectedOriginalIndices.map((idx) => inventory[idx]).toList();
    
    // Complete the node and exchange relics
    ref.read(runProvider.notifier).exchangeRelics(sacrificed, _offeredRelic!);
    ref.read(runProvider.notifier).completeCurrentNode();

    Navigator.of(context).pop();
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final gameDataAsync = ref.watch(gameDataLoaderProvider);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.parchment,
      body: gameDataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8B4513))),
        error: (err, stack) => Center(
          child: Text(
            isFr ? 'Erreur de chargement: $err' : 'Error loading data: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (gameData) {
          if (_offeredRelic == null) {
            final seed = (widget.node.id.hashCode ^ runState.act).abs();
            final random = Random(seed);

            // 1. Roll for rarity: Uncommon (40%), Rare (35%), Epic (20%), Legendary (5%)
            final double roll = random.nextDouble();
            RelicRarity offeredRarity;
            if (roll < 0.40) {
              offeredRarity = RelicRarity.uncommon;
            } else if (roll < 0.75) {
              offeredRarity = RelicRarity.rare;
            } else if (roll < 0.95) {
              offeredRarity = RelicRarity.epic;
            } else {
              offeredRarity = RelicRarity.legendary;
            }

            final eligibleRelics = gameData.relics.where((r) => r.rarity == offeredRarity).toList();
            if (eligibleRelics.isNotEmpty) {
              _offeredRelic = eligibleRelics[random.nextInt(eligibleRelics.length)];
            } else {
              _offeredRelic = gameData.relics.firstWhere((r) => r.rarity != RelicRarity.common, orElse: () => gameData.relics.first);
            }
            _requiredRarity = _getRequiredSacrificeRarity(_offeredRelic!.rarity);
          }

          final requiredRarityText = _getRelicRarityLabel(context, _requiredRarity!);
          final requiredRarityColor = _getRelicRarityColor(_requiredRarity!);
          final offeredRarityText = _getRelicRarityLabel(context, _offeredRelic!.rarity);
          final offeredRarityColor = _getRelicRarityColor(_offeredRelic!.rarity);

          // Filter qualified relics from player's inventory
          final qualifiedRelics = <_QualifiedRelicIndex>[];
          for (int i = 0; i < inventoryState.relics.length; i++) {
            final r = inventoryState.relics[i];
            if (r.rarity == _requiredRarity) {
              qualifiedRelics.add(_QualifiedRelicIndex(originalIndex: i, relic: r));
            }
          }

          final canExchange = _selectedOriginalIndices.length == 3;

          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 650),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4ECD8), // Paper tone
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B4513), // Brown border
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        isFr ? 'AUTEL DES RELIQUES' : 'RELIC SHRINE',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF5C3A21),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isFr
                            ? 'Un autel mystique qui propose d\'échanger vos reliques contre une relique de puissance supérieure.'
                            : 'A mystical altar that proposes to exchange your relics for a relic of superior power.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7A583C),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const Divider(color: Color(0xFF8B4513), height: 32, thickness: 1.5),

                      // Section: Offered Relic
                      Text(
                        isFr ? 'RELIQUE PROPOSÉE' : 'OFFERED RELIC',
                        style: const TextStyle(
                          color: Color(0xFF5C3A21),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C), // Dark container for contrast
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: offeredRarityColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: offeredRarityColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _offeredRelic!.emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _offeredRelic!.getName(isFr ? 'fr' : 'en'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: offeredRarityColor.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          offeredRarityText.toUpperCase(),
                                          style: TextStyle(
                                            color: offeredRarityColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _offeredRelic!.getDescription(isFr ? 'fr' : 'en'),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section: Sacrifice Requirement
                      Text(
                        isFr
                            ? 'SACRIFICE REQUIS : 3 RELIQUES DE RARETÉ $requiredRarityText'
                            : 'REQUIRED SACRIFICE: 3 $requiredRarityText RELICS',
                        style: TextStyle(
                          color: requiredRarityColor.withRed(150),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (qualifiedRelics.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isFr
                                ? 'Vous n\'avez aucune relique de rareté $requiredRarityText à sacrifier.'
                                : 'You have no $requiredRarityText relics to sacrifice.',
                            style: const TextStyle(color: Color(0xFF8B0000), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (qualifiedRelics.length < 3)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isFr
                                ? 'Vous n\'avez pas assez de reliques de rareté $requiredRarityText (3 requises, vous en avez ${qualifiedRelics.length}).'
                                : 'You do not have enough $requiredRarityText relics (3 required, you have ${qualifiedRelics.length}).',
                            style: const TextStyle(color: Color(0xFF8B0000), fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else ...[
                        Text(
                          isFr
                              ? 'Sélectionnez précisément 3 reliques à échanger (${_selectedOriginalIndices.length}/3) :'
                              : 'Select exactly 3 relics to exchange (${_selectedOriginalIndices.length}/3) :',
                          style: const TextStyle(color: Color(0xFF4A3728), fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        // List of qualified relics to select
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 2.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: qualifiedRelics.length,
                          itemBuilder: (context, idx) {
                            final qr = qualifiedRelics[idx];
                            final isSelected = _selectedOriginalIndices.contains(qr.originalIndex);

                            return GestureDetector(
                              onTap: () => _onRelicTap(qr.originalIndex),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFFFCC00) : requiredRarityColor.withValues(alpha: 0.5),
                                    width: isSelected ? 3.0 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFFCC00).withValues(alpha: 0.6),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(qr.relic.emoji, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            qr.relic.getName(isFr ? 'fr' : 'en'),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFFFCC00),
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          qr.relic.getDescription(isFr ? 'fr' : 'en'),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      const Divider(color: Color(0xFF8B4513), height: 40, thickness: 1.5),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Button "Partir" (Leave)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B4513),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Color(0xFF5C3A21), width: 1.5),
                              ),
                            ),
                            onPressed: _leave,
                            child: Text(
                              isFr ? 'PARTIR' : 'LEAVE',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          
                          // Button "Échanger" (Exchange)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canExchange ? const Color(0xFFD29034) : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: canExchange ? const Color(0xFF8F5A15) : Colors.grey.shade500,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onPressed: canExchange ? () => _performExchange(inventoryState.relics) : null,
                            child: Text(
                              isFr ? 'ÉCHANGER' : 'EXCHANGE',
                              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QualifiedRelicIndex {
  final int originalIndex;
  final RelicData relic;

  _QualifiedRelicIndex({required this.originalIndex, required this.relic});
}
