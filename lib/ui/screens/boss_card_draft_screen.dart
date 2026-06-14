import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/reward_controller.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/draft/card_draft_layout.dart';

class BossCardDraftScreen extends ConsumerStatefulWidget {
  const BossCardDraftScreen({super.key});

  @override
  ConsumerState<BossCardDraftScreen> createState() => _BossCardDraftScreenState();
}

class _BossCardDraftScreenState extends ConsumerState<BossCardDraftScreen> {
  final Set<CardData> _selectedCards = {};

  void _toggleCardSelection(CardData card) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    setState(() {
      if (_selectedCards.contains(card)) {
        _selectedCards.remove(card);
      } else {
        if (_selectedCards.length < 3) {
          _selectedCards.add(card);
        } else {
          context.showNotification(
            isFr ? "Vous ne pouvez sélectionner que 3 cartes maximum." : "You can only select up to 3 cards.",
            type: NotificationType.warning,
          );
        }
      }
    });
  }

  void _confirmSelection() {
    if (_selectedCards.length != 3) return;

    ref.read(rewardProvider.notifier).chooseCards(_selectedCards.toList());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
    final l10n = AppLocalizations.of(context)!;

    final rewardState = ref.watch(rewardProvider);
    final draftPool = rewardState.rolledCards;

    final isConfirmEnabled = _selectedCards.length == 3;

    return CardDraftLayout(
      title: isFr ? "SÉLECTION DE CARTES DE BOSS" : "BOSS CARD SELECTION",
      subtitle: isFr
          ? "Choisissez précisément 3 cartes à ajouter à votre deck permanent."
          : "Choose exactly 3 cards to add to your permanent deck.",
      cardCountText: isFr
          ? "Cartes sélectionnées : ${_selectedCards.length} / 3"
          : "Selected cards: ${_selectedCards.length} / 3",
      confirmButtonText: isFr ? "CONFIRMER LA SÉLECTION" : "CONFIRM SELECTION",
      onConfirm: _confirmSelection,
      isConfirmEnabled: isConfirmEnabled,
      themeColor: Colors.amber,
      child: draftPool.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 70 / 110,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: draftPool.length,
              itemBuilder: (context, index) {
                final card = draftPool[index];
                final isSelected = _selectedCards.contains(card);

                return Stack(
                  children: [
                    UiCard.fromData(
                      card: card,
                      locale: locale,
                      l10n: l10n,
                      isSelected: isSelected,
                      onTap: () => _toggleCardSelection(card),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
