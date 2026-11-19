import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/data/model_extensions.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';

class EnemyIntentsPanel extends StatefulWidget {
  final List<EnemyInstance> enemies;

  /// Les noms des états rompus : celui d'un ennemi qui ne fait rien ce tour.
  final ChargeCatalog charges;

  /// La hauteur maximale du panneau ; au-delà, la liste défile. `null` : le
  /// panneau prend la hauteur de son contenu (la démonstration du tutoriel).
  final double? maxHeight;

  const EnemyIntentsPanel({
    super.key,
    required this.enemies,
    this.charges = const ChargeCatalog.empty(),
    this.maxHeight,
  });

  /// La valeur affichée dans la pastille compacte d'une intention : les
  /// dégâts nus pour une attaque, un gain signé pour la défense et le buff.
  static String compactValue(EnemyIntent intent) => switch (intent.type) {
        IntentType.attack => '${intent.value}',
        IntentType.defend || IntentType.buff => '+${intent.value}',
      };

  /// La phrase de l'infobulle d'une intention, sous son libellé complet.
  /// [skippedState] est le nom de l'état rompu d'un ennemi qui ne fera rien
  /// ce tour : sa phrase remplace l'explication de l'intention.
  static String explanation(
    AppLocalizations l10n, {
    required EnemyIntent? intent,
    required String enemyName,
    String? skippedState,
  }) {
    if (intent == null) return l10n.intentWaitingExplanation(enemyName);
    if (skippedState != null) return l10n.intentSkipped(skippedState);
    return switch (intent.type) {
      IntentType.attack => l10n.intentAttackExplanation(enemyName, intent.value),
      IntentType.defend => l10n.intentDefendExplanation(enemyName, intent.value),
      IntentType.buff => l10n.intentBuffExplanation(enemyName, intent.value),
    };
  }

  @override
  State<EnemyIntentsPanel> createState() => _EnemyIntentsPanelState();
}

class _EnemyIntentsPanelState extends State<EnemyIntentsPanel> {
  // Explicite : `Scrollbar(thumbVisibility: true)` lève une erreur en debug
  // sous Windows, où le `SingleChildScrollView` ne s'attache pas au
  // `PrimaryScrollController`.
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// L'icône et la couleur du palier d'une intention. Les quatre paliers
  /// d'attaque suivent les seuils des libellés (`IntentTypeExtension`).
  (IconData, Color) _visuals(EnemyIntent intent) {
    switch (intent.type) {
      case IntentType.attack:
        if (intent.value >= 20) {
          return (Icons.gavel, const Color(0xFFC0392B)); // Crimson profond
        } else if (intent.value >= 12) {
          return (Icons.whatshot, const Color(0xFFE74C3C)); // Écarlate
        } else if (intent.value >= 6) {
          return (Icons.flash_on, const Color(0xFFFF7675)); // Corail
        }
        return (Icons.bolt, const Color(0xFFF39C12)); // Ambre/Orange
      case IntentType.defend:
        return (Icons.shield, const Color(0xFF448AFF));
      case IntentType.buff:
        return (Icons.trending_up, const Color(0xFFE040FB));
    }
  }

  /// La pastille d'une intention : l'icône et la valeur seules. Le libellé
  /// complet et sa phrase passent dans l'infobulle, au survol ou à l'appui
  /// long, ce qui tient chaque ennemi sur une seule ligne.
  Widget _intentChip(
    AppLocalizations l10n,
    EnemyInstance enemy,
    String name,
    String? skippedState,
  ) {
    final intent = enemy.effectiveIntent;
    final IconData icon;
    final Color color;
    final String label;
    if (intent == null) {
      icon = Icons.hourglass_empty;
      color = Colors.white30;
      label = l10n.waitingIntents;
    } else {
      (icon, color) = _visuals(intent);
      label = intent.type.getLabel(l10n, intent.value);
    }

    // Un ennemi qui ne fait rien ce tour : son intention reste lisible mais
    // grisee et barree.
    final skipped = intent != null && skippedState != null;
    final chipColor = skipped ? Colors.white38 : color;

    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(245),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: skipped ? Colors.lightBlueAccent : color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(185),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
      richMessage: TextSpan(
        children: [
          TextSpan(
            text: '$label\n',
            style: TextStyle(
              color: intent == null ? Colors.white70 : color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: skipped ? TextDecoration.lineThrough : null,
            ),
          ),
          TextSpan(
            text: EnemyIntentsPanel.explanation(
              l10n,
              intent: intent,
              enemyName: name,
              skippedState: skippedState,
            ),
            style: skipped
                ? const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                  )
                : null,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: chipColor.withAlpha(intent == null ? 10 : 20),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: chipColor.withAlpha(60), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: chipColor, size: 14),
            // Sans intention, la pastille garde « En attente... » : l'état
            // est bref, et le tutoriel le decrit ainsi.
            if (intent == null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: chipColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              const SizedBox(width: 4),
              Text(
                EnemyIntentsPanel.compactValue(intent),
                style: TextStyle(
                  color: chipColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: skipped ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _enemyRow(AppLocalizations l10n, String locale, EnemyInstance enemy) {
    final name = enemy.data.getName(locale);
    final skippingCharge = enemy.skippingCharge;
    final skippedState = skippingCharge == null
        ? null
        : widget.charges[skippingCharge]?.brokenName(locale) ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          // Seul le nom se tronque : le niveau, les PV et l'intention restent
          // entiers, c'est ce que le joueur lit.
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: enemy.isBoss ? Colors.amberAccent : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  locale == 'fr'
                      ? 'Niv. ${enemy.stats.level}'
                      : 'Lvl. ${enemy.stats.level}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${enemy.stats.currentPv}/${enemy.stats.maxPv}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(width: 6),
          _intentChip(l10n, enemy, name, skippedState),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final bounded = widget.maxHeight != null;
    final enemies = widget.enemies;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final enemy in enemies) ...[
          _enemyRow(l10n, locale, enemy),
          if (enemy != enemies.last)
            const Divider(color: Colors.white10, height: 8),
        ],
      ],
    );

    return Container(
      width: 250,
      constraints: bounded ? BoxConstraints(maxHeight: widget.maxHeight!) : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amberAccent.withAlpha(100),
          width: 1.5,
        ),
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
                Icons.remove_red_eye_outlined,
                color: Colors.amberAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              // Le panneau a une largeur fixe de 250 : sans `Flexible`, un
              // titre long (locale, mise a l'echelle du texte) deborde de la
              // `Row` et Flutter peint la bande d'erreur jaune et noire a la
              // place. Ici le titre se replie sur plusieurs lignes, sans rien
              // perdre.
              Flexible(
                child: Text(
                  l10n.enemyIntentsTitle.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          if (bounded)
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
                  // La marge droite laisse la barre hors des pastilles
                  // d'intention, alignees au bord droit des lignes.
                  child: SingleChildScrollView(
                    controller: _scroll,
                    padding: const EdgeInsets.only(right: 8),
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
