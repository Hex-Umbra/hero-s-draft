import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';

    // Grouper les cartes pour identifier les fusions possibles
    final Map<String, List<CardInstance>> groups = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.level}';
      groups.putIfAbsent(key, () => []).add(card);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        title: Text(
          l10n.myDeck,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                isFr ? 'Total : ${masterDeck.length} cartes' : 'Total: ${masterDeck.length} cards',
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
                                title: card.data.getName(locale),
                                description: card.data.getDescription(locale),
                                cost: card.data.cost,
                                target: _getTargetLabel(locale, card.data.target),
                                level: card.level,
                                effects: card.data.effects,
                                type: card.data.type,
                                isExhaust: card.data.isExhaust,
                                rarity: isFr
                                    ? '${_getRarityLabel(context, card.data.rarity)} - Niv. ${card.level}'
                                    : '${_getRarityLabel(context, card.data.rarity)} - Lvl. ${card.level}',
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
                            child: Text(
                              isFr ? 'FUSIONNER (3)' : 'MERGE (3)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (canMerge && !allowMerge)
                          Text(
                            isFr ? 'Fusion possible' : 'Merge possible',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            isFr ? '${3 - count} de plus requis' : '${3 - count} more required',
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

  void _confirmMerge(BuildContext context, WidgetRef ref, CardInstance card) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
    final cardName = card.data.getName(locale);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: Text(
          isFr ? 'Confirmer la fusion' : 'Confirm Merge',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isFr
              ? 'Voulez-vous fusionner 3 exemplaires de "$cardName" (Niv. ${card.level}) pour obtenir un exemplaire de Niveau ${card.level + 1} ?'
              : 'Do you want to merge 3 copies of "$cardName" (Lvl. ${card.level}) to obtain a Lvl. ${card.level + 1} copy?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              isFr ? 'Annuler' : 'Cancel',
              style: const TextStyle(color: Colors.white54),
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
                    isFr
                        ? 'Fusion réussie : $cardName est maintenant Niveau ${card.level + 1} !'
                        : 'Merge successful: $cardName is now Level ${card.level + 1}!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(
              isFr ? 'Fusionner' : 'Merge',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
