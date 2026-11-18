import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../game/systems/charge_rules.dart';
import '../../../models/charge_track.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/data/effect_icon_table.dart';
import '../../../models/status_effect.dart';
import '../effect_style.dart';

class StatusEffectsPanel extends StatefulWidget {
  final List<StatusEffect> statuses;

  /// Les charges du héros, une ligne chacune (spec P-53, §5.1). Les statuts
  /// dont l'id est une charge ne se dessinent pas : leur ligne les remplace.
  final List<ChargeLine> chargeLines;

  /// Les noms des charges et de leurs états rompus.
  final ChargeCatalog charges;

  /// L'icône et la couleur de chaque statut que la table porte (spec §3.7,
  /// A39) ; un statut absent de la table garde l'icône de ce panneau.
  final EffectIconTable effectIcons;

  /// La hauteur maximale du panneau ; au-delà, la liste défile. `null` : le
  /// panneau prend la hauteur de son contenu (la démonstration du tutoriel).
  final double? maxHeight;

  const StatusEffectsPanel({
    super.key,
    required this.statuses,
    this.chargeLines = const [],
    this.charges = const ChargeCatalog.empty(),
    this.effectIcons = const EffectIconTable.empty(),
    this.maxHeight,
  });

  @override
  State<StatusEffectsPanel> createState() => _StatusEffectsPanelState();
}

class _StatusEffectsPanelState extends State<StatusEffectsPanel> {
  // Explicite : `Scrollbar(thumbVisibility: true)` lève une erreur en debug
  // sous Windows, où le `SingleChildScrollView` ne s'attache pas au
  // `PrimaryScrollController`.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Le texte d'une ligne de charge, sans durée (spec P-53, §5.1) : sous le
  /// seuil les points seuls, rompue l'effet de la rupture.
  String _lineLabel(AppLocalizations l10n, String locale, ChargeLine line) {
    final data = widget.charges[line.chargeId];
    final name = data?.name(locale) ?? line.chargeId;
    final state = data?.brokenName(locale) ?? name;
    if (line.kind == RuptureKind.explode) {
      return l10n.statusChargeOpen(name, line.points);
    }
    return switch (line.state) {
      ChargeState.none =>
        l10n.statusChargePoints(name, line.points, line.threshold),
      ChargeState.brokenPending => line.kind == RuptureKind.weakenDealt
          ? l10n.statusChargeWeakenNext(state, line.value)
          : l10n.statusChargeCharged(state, line.value),
      ChargeState.brokenActive => line.kind == RuptureKind.weakenDealt
          ? l10n.statusChargeWeakenNow(state, line.value)
          : l10n.statusChargeCharged(state, line.value),
    };
  }

  Widget _chargeRow(AppLocalizations l10n, String locale, ChargeLine line) {
    final visuals = effectVisualsOrNull(
      widget.effectIcons,
      'status:${line.chargeId}',
    );
    final icon = visuals?.icon ?? Icons.arrow_downward;
    final color = visuals?.color ?? Colors.redAccent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          // Pas de durée, et le libellé se replie sur deux lignes plutôt que
          // de se tronquer : « Gelé : −50 % de dégâts au prochain tour » se
          // lit en entier.
          Expanded(
            child: Text(
              _lineLabel(l10n, locale, line),
              softWrap: true,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(AppLocalizations l10n, StatusEffect status) {
    IconData icon;
    Color color;
    String label;

    switch (status.id) {
      case 'might':
        icon = Icons.flash_on;
        color = Colors.orangeAccent;
        label = l10n.statusMight(status.value);
        break;
      case 'poison':
        icon = Icons.sick;
        color = const Color(0xFF69F0AE);
        label = l10n.statusPoison(status.value);
        break;
      case 'metallicize':
      case 'armor_regen':
        icon = Icons.shield;
        color = Colors.cyanAccent;
        label = l10n.statusArmorRegen(status.value);
        break;
      case 'weakness':
        icon = Icons.arrow_downward;
        color = Colors.redAccent;
        label = l10n.statusWeakness(status.value);
        break;
      case 'vulnerable':
        icon = Icons.arrow_downward;
        color = Colors.redAccent;
        label = l10n.statusVulnerable(status.value);
        break;
      case 'might_regen':
        icon = Icons.flash_on;
        color = Colors.orangeAccent;
        label = l10n.statusMightRegen(status.value);
        break;
      case 'mana_regen':
        icon = Icons.diamond;
        color = Colors.cyanAccent;
        label = l10n.statusManaRegen(status.value);
        break;
      case 'lifesteal':
        icon = Icons.favorite;
        color = Colors.redAccent;
        label = l10n.statusLifesteal(status.value);
        break;
      default:
        icon = status.type == StatusType.buff
            ? Icons.arrow_upward
            : Icons.arrow_downward;
        color = status.type == StatusType.buff
            ? Colors.greenAccent
            : Colors.redAccent;
        label = '${status.name} : ${status.value}';
        break;
    }

    final tabled = effectVisualsOrNull(
      widget.effectIcons,
      'status:${status.id}',
    );
    if (tabled != null) {
      icon = tabled.icon;
      color = tabled.color;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            l10n.statusTurns(status.duration),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final statuses = widget.statuses
        .where((s) => !widget.charges.isCharge(s.id))
        .toList();
    final rows = <Widget>[
      ...widget.chargeLines.map((line) => _chargeRow(l10n, locale, line)),
      ...statuses.map((status) => _statusRow(l10n, status)),
    ];
    final empty = rows.isEmpty;
    final bounded = widget.maxHeight != null;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );

    return Container(
      width: 250,
      constraints: bounded ? BoxConstraints(maxHeight: widget.maxHeight!) : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.offline_bolt,
                color: Colors.cyanAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              // Le panneau a une largeur fixe de 250 : sans `Flexible`, un
              // titre long (locale, mise a l'echelle du texte) deborde de la
              // `Row` et Flutter peint la bande d'erreur jaune et noire a la
              // place. « EFFETS DU JOUEUR » depasse deja de 18 px en francais,
              // sans aucun statut affiche. Ici le titre se replie sur
              // plusieurs lignes, sans rien perdre.
              //
              // Meme correctif que sur le panneau jumeau `EnemyIntentsPanel`,
              // qui expose la meme `Row` titre dans le meme `Container` fige.
              Flexible(
                child: Text(
                  l10n.playerEffects.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          if (empty)
            Text(
              l10n.noStatusActive,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (bounded)
            Flexible(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                // Une seule barre : sous Windows, linux et macOS le
                // comportement par defaut en ajouterait une seconde sur le
                // meme controleur.
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: list,
                  ),
                ),
              ),
            )
          else
            list,
        ],
      ),
    );
  }
}
