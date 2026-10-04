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
///
/// Sans or ([isFree] — le *Rémouleur*, spec P-43 E3, §4.9, A21) : le bouton
/// dit « Choisir », sans coût ni condition d'or, et n'écrit rien — il ferme
/// le dialogue sur l'id de la rune, que l'événement monte lui-même.
class SharpenRuneDialog extends ConsumerWidget {
  final CardInstance card;

  /// Vrai au *Rémouleur* : choisir, sans payer ni écrire.
  final bool isFree;

  const SharpenRuneDialog({
    super.key,
    required this.card,
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final gold = ref.watch(inventoryProvider).gold;
    // Le plafond effectif de la run (spec P-43 E3, §4.8, A17).
    final capBonus = ref.watch(runProvider).runeCapBonus;

    Widget row(ForgeUpgradeData rune, int level) {
      final sharpenable =
          ForgeRuneRules.canSharpen(rune, level, capBonus: capBonus);
      final cost = ForgeRuneRules.sharpenCost(level);
      final String actionLabel;
      final VoidCallback? onAction;
      if (!sharpenable) {
        actionLabel = l10n.runeMaxLevel;
        onAction = null;
      } else if (isFree) {
        actionLabel = l10n.fusionRuneChoose;
        onAction = () => Navigator.of(context).pop(rune.id);
      } else {
        actionLabel = l10n.sharpenAction(cost);
        onAction = gold >= cost
            ? () {
                if (ref
                    .read(runProvider.notifier)
                    .sharpenRune(card.uniqueId, rune.id)) {
                  Navigator.of(context).pop(rune.id);
                }
              }
            : null;
      }
      return ForgeSlotRow(
        rune: rune,
        title: rune.getName(locale),
        // Une rune au plafond n'a pas de niveau suivant : pas de ligne de
        // niveau, son bouton dit « Niveau maximal ».
        detail: sharpenable ? l10n.sharpenLevel(level, level + 1) : null,
        description: rune.getDescription(1, locale, card.data, card.rarity,
            carried: level),
        actionLabel: actionLabel,
        onAction: onAction,
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
