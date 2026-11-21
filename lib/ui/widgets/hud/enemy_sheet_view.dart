import 'dart:math' as math;
import 'dart:ui';

import '../../../game/systems/status_readout.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import 'intent_pips.dart';

/// Une ligne d'une section de la fiche : « {émoji} {titre} », suivi des tours
/// restants, et sa ligne d'aide dessous (spec P-05, §4.4).
class SheetEntry {
  final String text;
  final String? hint;

  const SheetEntry({required this.text, this.hint});

  factory SheetEntry.of(StatusReadout readout, AppLocalizations l10n) {
    final turns = readout.turnsLeft;
    return SheetEntry(
      text: '${readout.emoji} ${readout.title}'
          '${turns == null ? '' : ' · ${l10n.sheetTurnsLeft(turns)}'}',
      hint: readout.hint,
    );
  }
}

/// Ce que la fiche d'un ennemi écrit, calculé sans écran : le widget n'a plus
/// qu'à le dessiner.
class EnemySheetView {
  final String title;
  final String level;
  final String hp;
  final String armor;
  final String might;
  final List<IntentPip> pips;
  final String intentName;
  final String intentSentence;
  final List<SheetEntry> bonuses;
  final List<SheetEntry> alterations;

  const EnemySheetView({
    required this.title,
    required this.level,
    required this.hp,
    required this.armor,
    required this.might,
    required this.pips,
    required this.intentName,
    required this.intentSentence,
    required this.bonuses,
    required this.alterations,
  });

  static EnemySheetView of(
    EnemyInstance enemy, {
    required ChargeCatalog charges,
    required AppLocalizations l10n,
    required String locale,
  }) {
    final stats = enemy.stats;
    final intent = enemy.effectiveIntent;
    final skippingCharge = enemy.skippingCharge;
    final readouts = StatusReadout.of(stats, charges, l10n, locale);

    return EnemySheetView(
      title: enemy.data.getName(locale).toUpperCase(),
      level: l10n.levelLabel(stats.level),
      hp: l10n.sheetHp(stats.currentPv, stats.maxPv),
      armor: l10n.sheetArmor(stats.armure),
      might: l10n.sheetMight(stats.effectiveMight),
      pips: IntentPips.of(intent, skipped: skippingCharge != null, l10n: l10n),
      intentName: intent == null ? '' : _intentName(intent, l10n),
      intentSentence: switch (intent) {
        null => l10n.sheetIntentWaiting,
        _ when skippingCharge != null => l10n.intentSkipped(
            charges[skippingCharge]?.brokenName(locale) ?? ''),
        EnemyIntent(type: IntentType.attack, :final value) =>
          l10n.sheetIntentAttack(value),
        EnemyIntent(type: IntentType.defend, :final value) =>
          l10n.sheetIntentDefend(value),
        EnemyIntent(type: IntentType.buff, :final value) =>
          l10n.sheetIntentBuff(value),
      },
      bonuses: [
        for (final entry in readouts.left) SheetEntry.of(entry, l10n),
      ],
      alterations: [
        for (final entry in readouts.right) SheetEntry.of(entry, l10n),
      ],
    );
  }

  /// Le nom de l'intention, sans sa valeur : les paliers d'attaque suivent les
  /// seuils 6, 12 et 20 de `IntentTypeExtension.getLabel`.
  static String _intentName(EnemyIntent intent, AppLocalizations l10n) =>
      switch (intent.type) {
        IntentType.attack when intent.value >= 20 =>
          l10n.intentNameDevastatingAttack,
        IntentType.attack when intent.value >= 12 => l10n.intentNameHeavyAttack,
        IntentType.attack when intent.value >= 6 => l10n.intentNameAttack,
        IntentType.attack => l10n.intentNameQuickAttack,
        IntentType.defend => l10n.intentNameDefend,
        IntentType.buff => l10n.intentNameBuff,
      };
}

/// L'endroit où la fiche se pose à côté de la carte agrandie (spec P-05, §4.6).
abstract final class SheetPlacement {
  /// Le coin haut gauche du cadre : à droite de [card] si le cadre tient, sinon
  /// à gauche, sinon du côté le plus large, borné à l'écran. Le haut est celui
  /// de [card], sans passer sous [margin].
  static Offset topLeftFor({
    required Rect card,
    required Size screen,
    double width = 310,
    double gap = 24,
    double margin = 16,
  }) {
    final rightEdge = screen.width - margin - width;
    final double left;
    if (card.right + gap + width <= screen.width - margin) {
      left = card.right + gap;
    } else if (card.left - gap - width >= margin) {
      left = card.left - gap - width;
    } else {
      final onLeft = card.left > screen.width - card.right;
      left = (onLeft ? card.left - gap - width : card.right + gap)
          .clamp(margin, rightEdge)
          .toDouble();
    }
    return Offset(left, math.max(card.top, margin));
  }
}
