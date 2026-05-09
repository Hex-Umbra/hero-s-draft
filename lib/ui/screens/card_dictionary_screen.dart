import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';

class CardDictionaryScreen extends ConsumerWidget {
  const CardDictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameDataAsync = ref.watch(gameDataLoaderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: const Text('Dictionnaire des Cartes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black45,
        elevation: 0,
      ),
      body: gameDataAsync.when(
        data: (gameData) {
          final allCards = gameData.cards;
          
          // Grouper par catégorie ou type ? Essayons par type pour la clarté
          final Map<CardType, List<CardData>> groupedCards = {};
          for (var card in allCards) {
            groupedCards.putIfAbsent(card.type, () => []).add(card);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: groupedCards.entries.map((group) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _getTypeLabel(group.key),
                        style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 100, // Taille max fixe pour garantir le format Nano
                        childAspectRatio: 0.65,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: group.value.length,
                      itemBuilder: (context, index) {
                        final card = group.value[index];
                        return UiCard(
                          title: card.name,
                          description: '${_getRarityLabel(card.rarity)}\nCible : ${_getTargetLabel(card.target)}\n\n${card.description}',
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('Erreur : $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  String _getTypeLabel(CardType type) {
    switch (type) {
      case CardType.attack: return 'ATTAQUES';
      case CardType.skill: return 'COMPÉTENCES';
      case CardType.power: return 'POUVOIRS';
      case CardType.status: return 'STATUTS / MALÉDICTIONS';
    }
  }

  String _getRarityLabel(CardRarity rarity) {
    switch (rarity) {
      case CardRarity.common: return 'Commun';
      case CardRarity.uncommon: return 'Peu Commun';
      case CardRarity.rare: return 'Rare';
      case CardRarity.epic: return 'Épique';
    }
  }

  String _getTargetLabel(CardTarget target) {
    switch (target) {
      case CardTarget.singleEnemy: return 'Cible unique';
      case CardTarget.allEnemies: return 'Tous les ennemis';
      case CardTarget.self: return 'Soi-même';
      case CardTarget.none: return 'Aucune';
    }
  }
}
