import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';
import '../widgets/gold_indicator.dart';
import '../widgets/ui_card.dart';
import '../widgets/game_button.dart';
import '../widgets/notification_overlay.dart';

class FusionOption {
  final String upgradeId;
  final List<String> originalUpgrades;
  final int totalTier;
  final int cost;

  FusionOption({
    required this.upgradeId,
    required this.originalUpgrades,
    required this.totalTier,
    required this.cost,
  });
}

class ForgeFusionScreen extends ConsumerStatefulWidget {
  const ForgeFusionScreen({super.key});

  @override
  ConsumerState<ForgeFusionScreen> createState() => _ForgeFusionScreenState();
}

class _ForgeFusionScreenState extends ConsumerState<ForgeFusionScreen> {
  CardInstance? _selectedCard;

  List<FusionOption> _getFusionsForCard(CardInstance card) {
    final Map<String, List<String>> groups = {};
    for (final upg in card.forgeUpgrades) {
      final id = upg.split(':')[0];
      groups.putIfAbsent(id, () => []).add(upg);
    }

    final fusions = <FusionOption>[];
    groups.forEach((id, list) {
      if (list.length >= 2) {
        int totalTier = 0;
        for (final upg in list) {
          final parts = upg.split(':');
          final tier = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
          totalTier += tier;
        }
        final cost = 80 * (list.length - 1);
        fusions.add(FusionOption(
          upgradeId: id,
          originalUpgrades: list,
          totalTier: totalTier,
          cost: cost,
        ));
      }
    });
    return fusions;
  }

  void _onCardSelected(CardInstance card) {
    setState(() {
      _selectedCard = card;
    });
  }

  void _onFusionPerform(CardInstance card, FusionOption fusion, int currentGold) {
    if (currentGold < fusion.cost) {
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      context.showNotification(
        isFr ? "Or insuffisant !" : "Not enough Gold!",
        type: NotificationType.error,
      );
      return;
    }

    final success = ref.read(inventoryProvider.notifier).spendGold(fusion.cost);
    if (!success) return;

    // Calculer les nouveaux upgrades
    final updatedUpgrades = <String>[];
    bool addedFused = false;
    for (final upg in card.forgeUpgrades) {
      final id = upg.split(':')[0];
      if (id == fusion.upgradeId) {
        if (!addedFused) {
          updatedUpgrades.add('${fusion.upgradeId}:${fusion.totalTier}');
          addedFused = true;
        }
      } else {
        updatedUpgrades.add(upg);
      }
    }

    ref.read(deckProvider.notifier).setForgeUpgrades(card.uniqueId, updatedUpgrades);

    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final upgradeData = ForgeUpgradeData.getById(fusion.upgradeId);
    final upgradeName = upgradeData?.getName(isFr ? 'fr' : 'en') ?? fusion.upgradeId;

    context.showNotification(
      isFr
          ? "Fusion réussie : $upgradeName (Niveau ${fusion.totalTier})"
          : "Fusion success: $upgradeName (Tier ${fusion.totalTier})",
      type: NotificationType.success,
    );

    // Mettre à jour l'instance de carte sélectionnée en la rechargeant du deck
    final masterDeck = ref.read(deckProvider).masterDeck;
    final updatedCard = masterDeck.firstWhere((c) => c.uniqueId == card.uniqueId, orElse: () => card);
    setState(() {
      _selectedCard = updatedCard;
    });
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;
    final inventoryState = ref.watch(inventoryProvider);
    final currentGold = inventoryState.gold;
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';

    // Trouver toutes les cartes éligibles du deck (ayant au moins deux améliorations de même type)
    final eligibleCards = masterDeck.where((card) {
      return _getFusionsForCard(card).isNotEmpty;
    }).toList();

    // Si la carte sélectionnée n'est plus éligible, la déselectionner
    if (_selectedCard != null) {
      final cardStillExists = masterDeck.any((c) => c.uniqueId == _selectedCard!.uniqueId);
      if (!cardStillExists) {
        _selectedCard = null;
      } else {
        final currentCardInDeck = masterDeck.firstWhere((c) => c.uniqueId == _selectedCard!.uniqueId);
        if (_getFusionsForCard(currentCardInDeck).isEmpty) {
          _selectedCard = null;
        }
      }
    }

    final header = PageHeader(
      title: isFr ? 'FORGE DE FUSION' : 'FUSION FORGE',
      showBackButton: false,
      isParchment: false,
      actions: const [
        GoldIndicator(),
      ],
    );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: header,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF2E0854).withAlpha(120),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 760;

                      if (eligibleCards.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.layers_clear_rounded, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                isFr
                                    ? "Aucune carte de votre deck n'a de runes identiques à fusionner."
                                    : "No cards in your deck have identical runes to merge.",
                                style: const TextStyle(color: Colors.white70, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      // Left panel: List of eligible cards
                      final cardsListPanel = Container(
                        width: isDesktop ? 300 : double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.deepPurpleAccent.withAlpha(40)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isFr ? "CARTES ÉLIGIBLES" : "ELIGIBLE CARDS",
                              style: const TextStyle(
                                color: Colors.deepPurpleAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.builder(
                                itemCount: eligibleCards.length,
                                itemBuilder: (context, index) {
                                  final card = eligibleCards[index];
                                  final isSelected = _selectedCard?.uniqueId == card.uniqueId;
                                  final fusions = _getFusionsForCard(card);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.deepPurpleAccent.withAlpha(40)
                                          : Colors.white.withAlpha(5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.deepPurpleAccent
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () => _onCardSelected(card),
                                      title: Text(
                                        card.data.getName(locale),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isFr
                                            ? "${fusions.length} fusion(s) possible(s)"
                                            : "${fusions.length} merge(s) available",
                                        style: TextStyle(
                                          color: isSelected ? Colors.purpleAccent : Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );

                      // Right panel: Details of selected card and fusions
                      final detailsPanel = Expanded(
                        child: _selectedCard == null
                            ? Center(
                                child: Text(
                                  isFr
                                      ? "Sélectionnez une carte à gauche pour afficher ses options de fusion."
                                      : "Select a card on the left to view its fusion options.",
                                  style: const TextStyle(color: Colors.white38),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.deepPurpleAccent.withAlpha(40)),
                                ),
                                child: isDesktop
                                    ? Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 150,
                                            child: Column(
                                              children: [
                                                UiCard.fromInstance(
                                                  card: _selectedCard!,
                                                  locale: locale,
                                                  l10n: AppLocalizations.of(context)!,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: _buildFusionOptionsList(
                                              _selectedCard!,
                                              _getFusionsForCard(_selectedCard!),
                                              currentGold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            Center(
                                              child: SizedBox(
                                                width: 140,
                                                height: 196,
                                                child: UiCard.fromInstance(
                                                  card: _selectedCard!,
                                                  locale: locale,
                                                  l10n: AppLocalizations.of(context)!,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            _buildFusionOptionsList(
                                              _selectedCard!,
                                              _getFusionsForCard(_selectedCard!),
                                              currentGold,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                      );

                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            cardsListPanel,
                            const SizedBox(width: 24),
                            detailsPanel,
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            if (_selectedCard == null)
                              Expanded(child: cardsListPanel)
                            else ...[
                              ElevatedButton.icon(
                                onPressed: () => setState(() => _selectedCard = null),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(isFr ? "Retour aux cartes" : "Back to cards"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(child: detailsPanel),
                            ],
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameButton(
                      text: isFr ? "Quitter l'atelier" : "Leave workshop",
                      onPressed: _leave,
                      baseColor: Colors.deepPurpleAccent,
                      height: 48,
                      width: 200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFusionOptionsList(CardInstance card, List<FusionOption> fusions, int currentGold) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isFr ? "FUSIONS POSSIBLES" : "AVAILABLE FUSIONS",
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...fusions.map((fusion) {
          final upgradeData = ForgeUpgradeData.getById(fusion.upgradeId);
          final upgradeName = upgradeData?.getName(isFr ? 'fr' : 'en') ?? fusion.upgradeId;
          final upgradeEmoji = upgradeData?.emoji ?? '🔮';
          final hasEnoughGold = currentGold >= fusion.cost;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withAlpha(40)),
            ),
            child: Row(
              children: [
                Text(
                  upgradeEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isFr
                            ? "Fusionner ${fusion.originalUpgrades.length}x $upgradeName"
                            : "Merge ${fusion.originalUpgrades.length}x $upgradeName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isFr
                            ? "Résultat : $upgradeName (Niveau ${fusion.totalTier})"
                            : "Result: $upgradeName (Tier ${fusion.totalTier})",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GameButton(
                  text: '${fusion.cost} Or',
                  onPressed: hasEnoughGold
                      ? () => _onFusionPerform(card, fusion, currentGold)
                      : null,
                  baseColor: hasEnoughGold ? Colors.amber : Colors.grey,
                  height: 36,
                  fontSize: 13,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
