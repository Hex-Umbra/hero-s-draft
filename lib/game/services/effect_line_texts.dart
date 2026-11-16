import '../../l10n/app_localizations.dart';
import '../../models/data/charge_data.dart';
import '../../models/data/effect_kind.dart';
import '../../models/signature_instance.dart';

/// La seule écriture des lignes de la liste qu'ouvre l'appui long sur une
/// signature (spec A41, §6.1) : une phrase par sorte d'effet qu'une signature
/// produit, sans point final.
abstract final class EffectLineTexts {
  /// La phrase de [line], à sa valeur et, pour un statut, à sa durée ; `null`
  /// pour une sorte sans phrase — la ligne montre alors son icône seule. Une
  /// charge du [charges] se dit par son nom, sans durée (spec P-53, §6.2).
  static String? phrase(
    AppLocalizations l10n,
    EffectLine line,
    ChargeCatalog charges,
  ) {
    final amount = line.value ?? 0;
    // La durée par défaut d'un statut, celle qu'applique le moteur.
    final duration = line.duration ?? 1;
    final charge = line.kind.startsWith('status:')
        ? charges[line.kind.substring('status:'.length)]
        : null;
    if (charge != null) {
      return l10n.effectLineCharge(amount, charge.name(l10n.localeName));
    }
    return switch (line.kind) {
      'damage' => l10n.effectLineDamage(amount),
      'armor' => l10n.effectLineArmor(amount),
      'heal' => l10n.effectLineHeal(amount),
      'draw' => l10n.effectLineDraw(amount),
      'gain_mana' => l10n.effectLineGainMana(amount),
      'status:might' => l10n.effectLineMight(amount, duration),
      'status:might_regen' => l10n.effectLineMightRegen(amount, duration),
      'status:armor_regen' => l10n.effectLineArmorRegen(amount, duration),
      'status:weakness' => l10n.effectLineWeakness(amount, duration),
      'status:vulnerable' => l10n.effectLineVulnerable(amount, duration),
      EffectKind.crit => l10n.effectLineCrit(amount),
      EffectKind.allEnemies => l10n.effectLineAllEnemies,
      _ => null,
    };
  }
}
