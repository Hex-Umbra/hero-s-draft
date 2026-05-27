import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../services/game_data_service.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';

class CardDictionaryScreen extends ConsumerWidget {
  const CardDictionaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameDataAsync = ref.watch(gameDataLoaderProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          isFr ? 'Dictionnaire des Cartes' : 'Card Dictionary',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
                        _getTypeLabel(context, group.key),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent:
                                200, // Doublé pour un affichage plus clair
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: group.value.length,
                      itemBuilder: (context, index) {
                        final card = group.value[index];
                        return UiCard(
                          title: card.getName(locale),
                          description: card.getDescription(locale),
                          rarity: _getRarityLabel(context, card.rarity),
                          target: _getTargetLabel(locale, card.target),
                          cost: card.cost,
                          type: card.type,
                          isExhaust: card.isExhaust,
                          effects: card.effects,
                        );
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(
          child: Text(
            'Erreur : $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(BuildContext context, CardType type) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    switch (type) {
      case CardType.attack:
        return '${l10n.cardTypeAttack.toUpperCase()}S';
      case CardType.skill:
        return '${l10n.cardTypeSkill.toUpperCase()}S';
      case CardType.power:
        return '${l10n.cardTypePower.toUpperCase()}S';
      case CardType.status:
        return locale == 'fr' ? 'STATUTS / MALÉDICTIONS' : 'STATUS / CURSES';
    }
  }

  String _getRarityLabel(BuildContext context, CardRarity rarity) {
    final l10n = AppLocalizations.of(context)!;
    switch (rarity) {
      case CardRarity.common:
        return l10n.rarityCommon;
      case CardRarity.uncommon:
        return l10n.rarityUncommon;
      case CardRarity.rare:
        return l10n.rarityRare;
      case CardRarity.epic:
        return l10n.rarityEpic;
      case CardRarity.legendary:
        return l10n.rarityLegendary;
    }
  }

  String _getTargetLabel(String locale, CardTarget target) {
    final isFr = locale == 'fr';
    switch (target) {
      case CardTarget.singleEnemy:
        return isFr ? 'Cible unique' : 'Single enemy';
      case CardTarget.allEnemies:
        return isFr ? 'Tous les ennemis' : 'All enemies';
      case CardTarget.self:
        return isFr ? 'Soi-même' : 'Self';
      case CardTarget.none:
        return isFr ? 'Aucune' : 'None';
    }
  }
}
