import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';

class DeckScreen extends ConsumerWidget {
  final bool allowMerge;
  const DeckScreen({super.key, this.allowMerge = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;

    // Grouper les cartes pour identifier les fusions possibles
    final Map<String, List<CardInstance>> groups = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.level}';
      groups.putIfAbsent(key, () => []).add(card);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text(
          'Mon Deck',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black45,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total : ${masterDeck.length} cartes',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        200, // Doublé pour un affichage plus clair
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: groups.keys.length,
                  itemBuilder: (context, index) {
                    final key = groups.keys.elementAt(index);
                    final cardList = groups[key]!;
                    final card = cardList.first;
                    final count = cardList.length;
                    final canMerge = count >= 3;

                    return Column(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              UiCard(
                                title: card.data.name,
                                description: card.data.description,
                                cost: card.data.cost,
                                target: _getTargetLabel(card.data.target),
                                rarity:
                                    '${_getRarityLabel(card.data.rarity)} - Niv. ${card.level}',
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    'x$count',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (canMerge && allowMerge)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () {
                              _confirmMerge(context, ref, card);
                            },
                            child: const Text(
                              'FUSIONNER (3)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (canMerge && !allowMerge)
                          const Text(
                            'Fusion possible',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            '${3 - count} de plus requis',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRarityLabel(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common:
        return 'Commun';
      case CardRarity.uncommon:
        return 'Peu Commun';
      case CardRarity.rare:
        return 'Rare';
      case CardRarity.epic:
        return 'Épique';
    }
  }

  String _getTargetLabel(CardTarget target) {
    switch (target) {
      case CardTarget.singleEnemy:
        return 'Cible unique';
      case CardTarget.allEnemies:
        return 'Tous les ennemis';
      case CardTarget.self:
        return 'Soi-même';
      case CardTarget.none:
        return 'Aucune';
    }
  }

  void _confirmMerge(BuildContext context, WidgetRef ref, CardInstance card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: const Text(
          'Confirmer la fusion',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous fusionner 3 exemplaires de "${card.data.name}" (Niv. ${card.level}) pour obtenir un exemplaire de Niveau ${card.level + 1} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              ref
                  .read(deckProvider.notifier)
                  .mergeCards(card.data.id, card.level);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Fusion réussie : ${card.data.name} est maintenant Niveau ${card.level + 1} !',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Fusionner',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
