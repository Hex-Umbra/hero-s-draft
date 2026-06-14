import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';
import '../../models/data/hero_skills_link.dart';
import '../../services/game_data_service.dart';
import '../widgets/ui_card.dart';
import 'map_screen.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/draft/card_draft_layout.dart';

class StarterDeckDraftScreen extends ConsumerStatefulWidget {
  final HeroData playerClass;
  final PassiveData passive;

  const StarterDeckDraftScreen({
    super.key,
    required this.playerClass,
    required this.passive,
  });

  @override
  ConsumerState<StarterDeckDraftScreen> createState() =>
      _StarterDeckDraftScreenState();
}

class _StarterDeckDraftScreenState
    extends ConsumerState<StarterDeckDraftScreen> {
  late List<CardData> _draftPool;
  final Set<int> _selectedIndexes = {};
  bool _isPoolGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPoolGenerated) {
      _generateDraftPool();
      _isPoolGenerated = true;
    }
  }

  void _generateDraftPool() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    // 1. Filtrer pour n'obtenir que les cartes globales non statut
    final globalCards = gameData.cards
        .where(
          (c) => c.category == CardCategory.global && c.type != CardType.status,
        )
        .toList();

    setState(() {
      _draftPool = globalCards;
    });
  }

  void _toggleCardSelection(int index) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        if (_selectedIndexes.length < 5) {
          _selectedIndexes.add(index);
        } else {
          context.showNotification(
            l10n.draftDeckSnackbarMax,
            type: NotificationType.warning,
          );
        }
      }
    });
  }

  void _startAdventure() {
    if (_selectedIndexes.length != 5) return;

    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    final classCards = widget.playerClass.getHeroCards(gameData);

    // 2. Assembler le deck de départ (5 choisies + N de classe auto-ajoutées)
    final List<CardInstance> finalDeck = [];

    // Ajouter les cartes spécifiques de classe
    for (var cardData in classCards) {
      finalDeck.add(CardInstance(data: cardData));
    }

    // Ajouter les 5 cartes globales sélectionnées par index
    final selectedCards = _selectedIndexes
        .map((idx) => _draftPool[idx])
        .toList();
    for (var cardData in selectedCards) {
      finalDeck.add(CardInstance(data: cardData));
    }

    // 3. Initialiser les providers
    ref.read(deckProvider.notifier).clearDeck();
    ref
        .read(runProvider.notifier)
        .startNewRun(widget.playerClass, widget.passive);
    ref.read(deckProvider.notifier).initializeStarterDeck(finalDeck);

    // 4. Redirection propre vers la map de jeu
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MapScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    // Couleurs thématiques par classe
    Color classColor = Colors.blue;
    if (widget.playerClass.id == 'berserker') classColor = Colors.red;
    if (widget.playerClass.id == 'mage') classColor = Colors.purple;

    final isConfirmEnabled = _selectedIndexes.length == 5;

    return CardDraftLayout(
      title: l10n.draftDeckTitle,
      subtitle: l10n.draftDeckSubtitle,
      cardCountText: l10n.draftDeckSelectedCount(_selectedIndexes.length),
      confirmButtonText: l10n.draftDeckProceed,
      onConfirm: _startAdventure,
      isConfirmEnabled: isConfirmEnabled,
      themeColor: classColor,
      child: _draftPool.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isMobile ? 140 : 180,
                childAspectRatio: 70 / 110,
                crossAxisSpacing: isMobile ? 8 : 16,
                mainAxisSpacing: isMobile ? 8 : 16,
              ),
              itemCount: _draftPool.length,
              itemBuilder: (context, index) {
                final card = _draftPool[index];
                final isSelected = _selectedIndexes.contains(index);
                final isMaxSelected = _selectedIndexes.length == 5;

                return GestureDetector(
                  onTap: () => _toggleCardSelection(index),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected
                        ? 1.0
                        : (isMaxSelected ? 0.4 : 1.0),
                    child: Stack(
                      children: [
                        UiCard.fromData(
                          card: card,
                          locale: locale,
                          l10n: l10n,
                          isSelected: isSelected,
                        ),
                        // Indicateur Checkmark
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: classColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
