import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/forge_upgrade_dialog.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

class DeckScreen extends ConsumerWidget {
  final bool allowMerge;
  const DeckScreen({super.key, this.allowMerge = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Grouper les cartes pour identifier les fusions possibles
    final Map<String, List<CardInstance>> groups = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.rarity.name}';
      groups.putIfAbsent(key, () => []).add(card);
    }

    final appBar = PageHeader(
      title: l10n.myDeck,
      showBackButton: true,
      isParchment: false,
    );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: appBar,
      body: Padding(
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
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 70 / 110,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: groups.keys.length,
                // `_` et non `context` : la fusion se lance avec le `context`
                // de l'écran, que la grille ne démonte pas (spec P-43 E2,
                // §4.5).
                itemBuilder: (_, index) {
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
                            UiCard.fromInstance(
                              card: card,
                              locale: locale,
                              l10n: l10n,
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
                      if (card.rarity.next == null)
                        const SizedBox.shrink()
                      else if (canMerge && allowMerge)
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
                            _confirmMerge(context, ref, cardList);
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
    );
  }

  /// La fusion, puis le choix d'une rune (spec P-43 E2, A1, §4.5). [context]
  /// est celui de l'écran, jamais celui de la case de la grille : la fusion
  /// reconstruit la grille, qui peut démonter la case qui l'a lancée pendant
  /// le dialogue de choix.
  void _confirmMerge(
    BuildContext context,
    WidgetRef ref,
    List<CardInstance> duplicates,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final merged = await showDialog<CardInstance>(
      context: context,
      builder: (ctx) => _MergeDialog(duplicates: duplicates, ref: ref),
    );
    if (merged == null || !context.mounted) return;

    // L'offre : une fonction pure, sur la carte que la fusion rend, au rang
    // qu'elle atteint ; l'état ne change que par `DeckNotifier`.
    final offer = ForgeRuneRules.drawRunes(
      merged,
      GameDataRegistry.instance?.forgeUpgrades ?? const <ForgeUpgradeData>[],
      Random(),
      count: 3,
    );
    if (offer.isNotEmpty) {
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ForgeUpgradeDialog(card: merged, offer: offer),
      );
      if (!context.mounted) return;
    }

    context.showNotification(
      l10n.deckMergeSuccess(merged.data.getName(locale), merged.rarity.index + 1),
      type: NotificationType.success,
    );
    // Sans rune éligible, la fusion s'est faite sans dialogue : le joueur lit
    // les deux faits, dans cet ordre (A1).
    if (offer.isEmpty) {
      context.showNotification(l10n.forgeNoEligibleRune);
    }
  }
}

class _MergeDialog extends StatefulWidget {
  final List<CardInstance> duplicates;
  final WidgetRef ref;

  const _MergeDialog({
    required this.duplicates,
    required this.ref,
  });

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  final Set<String> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.duplicates.length == 3) {
      _selectedCardIds.addAll(widget.duplicates.map((c) => c.uniqueId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performMerge();
      });
    }
  }

  /// La fusion des trois exemplaires choisis ; le dialogue se ferme sur la
  /// carte qu'elle rend, `null` si elle est refusée (spec P-43 E2, §4.5).
  void _performMerge() {
    final merged = widget.ref.read(deckProvider.notifier).mergeCards(
          widget.duplicates
              .where((c) => _selectedCardIds.contains(c.uniqueId))
              .map((c) => c.uniqueId)
              .toList(),
        );
    Navigator.of(context).pop(merged);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GameDialog(
      glowColor: Colors.green,
      title: Text(
        l10n.confirmMerge,
      ),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez exactement 3 cartes à fusionner (Sélectionné: ${_selectedCardIds.length}/3)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.duplicates.length,
                itemBuilder: (context, index) {
                  final card = widget.duplicates[index];
                  final isSelected = _selectedCardIds.contains(card.uniqueId);
                  // Le niveau que joue chaque rune, par l'analyseur unique,
                  // nommé selon la règle des infobulles (spec P-43 E2, §4.11,
                  // E-S6).
                  final runes = [
                    for (final MapEntry(key: id, value: level)
                        in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
                      ForgeUpgradeData.getById(id)?.nameAt(level, locale) ??
                          '$id $level',
                  ];
                  return CheckboxListTile(
                    title: Text(
                      '${card.data.getName(locale)} (${card.rarity.name.toUpperCase()})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      runes.isEmpty
                          ? l10n.mergeRunesNone
                          : l10n.mergeRunesLabel(runes.join(', ')),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    value: isSelected,
                    activeColor: Colors.green,
                    checkColor: Colors.black,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (_selectedCardIds.length < 3) {
                            _selectedCardIds.add(card.uniqueId);
                          }
                        } else {
                          _selectedCardIds.remove(card.uniqueId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        GameButton(
          text: l10n.cancel,
          baseColor: Colors.white70,
          onPressed: () => Navigator.of(context).pop(),
          height: 38,
          fontSize: 14,
        ),
        GameButton(
          text: 'Continuer',
          onPressed: _selectedCardIds.length == 3 ? _performMerge : null,
          baseColor: Colors.green,
          height: 38,
          fontSize: 14,
        ),
      ],
    );
  }
}
