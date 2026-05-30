import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';


class DeckScreen extends ConsumerWidget {
  final bool allowMerge;
  const DeckScreen({super.key, this.allowMerge = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

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
                l10n.deckTotalCards(masterDeck.length),
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
                                target: _getTargetLabel(l10n, card.data.target),
                                level: card.level,
                                effects: card.data.effects,
                                type: card.data.type,
                                isExhaust: card.data.isExhaust,
                                rarity: l10n.rarityLevel(
                                  _getRarityLabel(context, card.data.rarity),
                                  card.level,
                                ),
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
                              l10n.mergeLabel(3),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else if (canMerge && !allowMerge)
                          Text(
                            l10n.mergePossible,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        else
                          Text(
                            l10n.mergeMoreRequired(3 - count),
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

  String _getTargetLabel(AppLocalizations l10n, CardTarget target) {
    switch (target) {
      case CardTarget.singleEnemy:
        return l10n.targetSingleEnemy;
      case CardTarget.allEnemies:
        return l10n.targetAllEnemies;
      case CardTarget.self:
        return l10n.targetSelf;
      case CardTarget.none:
        return l10n.targetNone;
    }
  }

  void _confirmMerge(BuildContext context, WidgetRef ref, CardInstance card) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final cardName = card.data.getName(locale);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3D),
        title: Text(
          l10n.confirmMerge,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l10n.deckMergeConfirm(cardName, card.level, card.level + 1),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
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
              context.showNotification(
                l10n.deckMergeSuccess(cardName, card.level + 1),
                type: NotificationType.success,
              );
            },
            child: Text(
              l10n.merge,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
