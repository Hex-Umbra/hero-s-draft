import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/reward_controller.dart';
import '../../models/data/card_data.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';

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

  String _getRarityLabel(CardRarity rarity) {
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
      case CardRarity.unique:
        return 'Unique';
    }
  }

  String _getTargetLabel(CardTarget target) {
    final l10n = AppLocalizations.of(context)!;
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';

    final rewardState = ref.watch(rewardProvider);
    final draftPool = rewardState.rolledCards;

    return Scaffold(
      backgroundColor: const Color(0xFF13131E),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      isFr ? "SÉLECTION DE CARTES DE BOSS" : "BOSS CARD SELECTION",
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isFr
                          ? "Choisissez précisément 3 cartes à ajouter à votre deck permanent."
                          : "Choose exactly 3 cards to add to your permanent deck.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isMobile ? 11 : 14,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Badge Compteur
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedCards.length == 3
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedCards.length == 3
                              ? Colors.green
                              : Colors.amber.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isFr
                            ? "Cartes sélectionnées : ${_selectedCards.length} / 3"
                            : "Selected cards: ${_selectedCards.length} / 3",
                        style: TextStyle(
                          color: _selectedCards.length == 3
                              ? Colors.greenAccent
                              : Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GRID DE DRAFT
              Expanded(
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
                              UiCard(
                                  title: card.getName(locale),
                                  description: card.getDescription(locale),
                                  cost: card.cost,
                                  effects: card.effects,
                                  level: 1,
                                  rarity: _getRarityLabel(card.rarity),
                                  target: _getTargetLabel(card.target),
                                  type: card.type,
                                  targetType: card.target,
                                  isExhaust: card.isExhaust,
                                  isSelected: isSelected,
                                  baseMaxForgeUpgrades: card.baseMaxForgeUpgrades,
                                  onTap: () => _toggleCardSelection(card),
                                ),
                                // Indicateur Checkmark
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
              ),
              const SizedBox(height: 20),

              // BOUTON DE VALIDATION
              AnimatedScale(
                scale: _selectedCards.length == 3 ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedCards.length == 3
                        ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: _selectedCards.length == 3
                          ? Colors.amber.shade700
                          : Colors.grey.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _selectedCards.length == 3 ? _confirmSelection : null,
                    child: Text(
                      isFr ? "CONFIRMER LA SÉLECTION" : "CONFIRM SELECTION",
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: _selectedCards.length == 3 ? Colors.white : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
