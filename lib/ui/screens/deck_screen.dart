import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
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
        title: const Text('Mon Deck', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                    maxCrossAxisExtent: 100, // Taille max fixe pour garantir le format Nano
                    childAspectRatio: 0.55,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
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
                                description: 'Niv. ${card.level}\n\n${card.data.description}',
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    'x$count',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 1),
                        if (canMerge && allowMerge)
                          SizedBox(
                            height: 18,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                              ),
                              onPressed: () {
                                _confirmMerge(context, ref, card);
                              },
                              child: const Text('MERGE', style: TextStyle(fontSize: 6)),
                            ),
                          )
                        else if (canMerge && !allowMerge)
                          const Text(
                            'Merge!',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 6, fontWeight: FontWeight.bold),
                          )
                        else
                          Text(
                            '+${3 - count}',
                            style: const TextStyle(color: Colors.white54, fontSize: 6),
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

  void _confirmMerge(BuildContext context, WidgetRef ref, CardInstance card) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: const Text('Confirmer la fusion', style: TextStyle(color: Colors.white)),
        content: Text(
          'Voulez-vous fusionner 3 exemplaires de "${card.data.name}" (Niv. ${card.level}) pour obtenir un exemplaire de Niveau ${card.level + 1} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              ref.read(deckProvider.notifier).mergeCards(card.data.id, card.level);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fusion réussie : ${card.data.name} est maintenant Niveau ${card.level + 1} !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Fusionner', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
