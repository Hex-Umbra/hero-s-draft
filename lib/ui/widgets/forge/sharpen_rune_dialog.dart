import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/inventory_controller.dart';
import '../../../game/controllers/run_controller.dart';
import '../../../game/services/forge_rune_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../game_button.dart';
import '../game_dialog.dart';
import '../gold_indicator.dart';
import 'forge_card_preview.dart';
import 'forge_slot_row.dart';

/// Le dialogue d'affûtage (spec P-43 E2, A4, §4.7) : la carte, puis une ligne
/// par rune qu'elle porte — son nom, son niveau et le suivant, ce que le
/// niveau de plus ajoute à cette carte, et « Affûter — coût or », inactif au
/// plafond ou faute d'or. Affûter monte la rune par
/// `RunController.sharpenRune`, puis ferme le dialogue sur son id : un seul
/// affûtage par visite (D14). Annuler, ou la croix, le ferme sur `null` et
/// ramène à la sélection.
class SharpenRuneDialog extends ConsumerWidget {
  final CardInstance card;

  const SharpenRuneDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final gold = ref.watch(inventoryProvider).gold;

    Widget row(ForgeUpgradeData rune, int level) {
      final sharpenable = ForgeRuneRules.canSharpen(rune, level);
      final cost = ForgeRuneRules.sharpenCost(level);
      return ForgeSlotRow(
        rune: rune,
        title: rune.getName(locale),
        // Une rune au plafond n'a pas de niveau suivant : pas de ligne de
        // niveau, son bouton dit « Niveau maximal ».
        detail: sharpenable ? l10n.sharpenLevel(level, level + 1) : null,
        description: rune.getDescription(1, locale, card.data, card.rarity,
            carried: level),
        actionLabel:
            sharpenable ? l10n.sharpenAction(cost) : l10n.runeMaxLevel,
        onAction: sharpenable && gold >= cost
            ? () {
                if (ref
                    .read(runProvider.notifier)
                    .sharpenRune(card.uniqueId, rune.id)) {
                  Navigator.of(context).pop(rune.id);
                }
              }
            : null,
      );
    }

    return GameDialog(
      glowColor: Colors.amberAccent,
      maxWidth: 640,
      title: Row(
        children: [
          Expanded(child: Text(card.data.getName(locale))),
          const GoldIndicator(),
        ],
      ),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ForgeCardPreview(card: card, locale: locale, l10n: l10n),
            ),
            const SizedBox(height: 16),
            for (final MapEntry(key: id, value: level)
                in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
              if (ForgeUpgradeData.getById(id) case final rune?)
                row(rune, level),
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
      ],
    );
  }
}
