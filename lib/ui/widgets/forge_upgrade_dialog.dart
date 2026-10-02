import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../l10n/app_localizations.dart';
import 'forge/forge_card_preview.dart';
import 'forge/forge_slot_row.dart';

/// Le dialogue de la fusion (spec P-43 E2, A1, A2, §4.5) : la carte fusionnée
/// et une ligne par rune de son [offer] — trois au plus, tirées par
/// `ForgeRuneRules.drawRunes` —, au niveau 1. Il ne se ferme que par un
/// choix : ni annulation, ni retour, ni relance, ni fente achetée. Le choix
/// pose `id:1` sur la carte par `DeckNotifier.addForgeUpgrade`, puis ferme
/// le dialogue sur l'id choisi. Le gabarit plein écran d'ADR-039 D4 reste.
class ForgeUpgradeDialog extends ConsumerWidget {
  final CardInstance card;

  /// Les ids des runes offertes, trois au plus.
  final List<String> offer;

  const ForgeUpgradeDialog({
    super.key,
    required this.card,
    required this.offer,
  });

  void _choose(BuildContext context, WidgetRef ref, String runeId) {
    ref.read(deckProvider.notifier).addForgeUpgrade(card.uniqueId, '$runeId:1');
    Navigator.of(context).pop(runeId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    final rows = [
      for (final id in offer)
        if (ForgeUpgradeData.getById(id) case final rune?)
          ForgeSlotRow(
            rune: rune,
            title: rune.nameAt(1, locale),
            description: rune.getDescription(1, locale, card.data, card.rarity),
            actionLabel: l10n.fusionRuneChoose,
            onAction: () => _choose(context, ref, id),
          ),
    ];

    // Ni annulation ni retour : le dialogue ne se ferme que par un choix (A1).
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: const Color(0xFF0D0D1A),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  const Color(0xFF1E1000).withAlpha(180),
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
                    Text(
                      l10n.fusionRuneTitle,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fusionRuneSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 720;
                          final cardPanel = SizedBox(
                            width: isDesktop ? 240 : double.infinity,
                            child: ForgeCardPreview(
                              card: card,
                              locale: locale,
                              l10n: l10n,
                            ),
                          );
                          final listPanel = Expanded(
                            child: ListView(children: rows),
                          );
                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                cardPanel,
                                const SizedBox(width: 48),
                                listPanel,
                              ],
                            );
                          }
                          return Column(
                            children: [
                              cardPanel,
                              const SizedBox(height: 24),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 12),
                              listPanel,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
