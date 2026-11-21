import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/data/model_extensions.dart';
import '../../../models/enemy_instance.dart';
import '../../../models/enemy_intent.dart';
import 'intent_pips.dart';

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

  /// Une ligne : le niveau, le nom, la rangée des pastilles d'intention. Trois
  /// colonnes de largeur fixe pour les deux bords, le nom prend le reste.
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
          SizedBox(
            width: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.levelLabel(enemy.stats.level),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enemy.isBoss ? Colors.amberAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _IntentPipRow(
                  l10n: l10n,
                  enemyName: name,
                  intent: enemy.effectiveIntent,
                  skippedState: skippedState,
                ),
              ),
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

/// La rangée des pastilles d'un ennemi, sous une seule infobulle : le libellé
/// complet de l'intention et sa phrase. Elle tient l'index de la pastille
/// survolée, qui prend un liseré de la couleur de l'infobulle ; au doigt,
/// aucun `MouseRegion` ne s'active.
class _IntentPipRow extends StatefulWidget {
  final AppLocalizations l10n;
  final String enemyName;
  final EnemyIntent? intent;

  /// Le nom de l'état rompu d'un ennemi qui ne fait rien ce tour, sinon `null`.
  final String? skippedState;

  const _IntentPipRow({
    required this.l10n,
    required this.enemyName,
    required this.intent,
    required this.skippedState,
  });

  @override
  State<_IntentPipRow> createState() => _IntentPipRowState();
}

class _IntentPipRowState extends State<_IntentPipRow> {
  int? _hovered;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final intent = widget.intent;
    final skippedState = widget.skippedState;
    final skipped = intent != null && skippedState != null;
    final pips = IntentPips.of(intent, skipped: skipped, l10n: l10n);
    final label = intent == null
        ? l10n.waitingIntents
        : intent.type.getLabel(l10n, intent.value);
    final borderColor = skipped ? Colors.lightBlueAccent : pips.first.color;

    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(245),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
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
              color: intent == null
                  ? Colors.white70
                  : IntentPips.of(intent, skipped: false, l10n: l10n).first.color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              decoration: skipped ? TextDecoration.lineThrough : null,
            ),
          ),
          TextSpan(
            text: EnemyIntentsPanel.explanation(
              l10n,
              intent: intent,
              enemyName: widget.enemyName,
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < pips.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            MouseRegion(
              onEnter: (_) => setState(() => _hovered = i),
              onExit: (_) => setState(() => _hovered = null),
              child: IntentPipChip(
                pips[i],
                hoverColor: _hovered == i ? borderColor : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Une pastille d'intention dessinée, celle du panneau et de la fiche d'un
/// ennemi.
class IntentPipChip extends StatelessWidget {
  final IntentPip pip;

  /// Le liseré de la pastille survolée ; `null` hors du survol.
  final Color? hoverColor;

  const IntentPipChip(this.pip, {super.key, this.hoverColor});

  @override
  Widget build(BuildContext context) {
    final hover = hoverColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: pip.color.withAlpha(pip.waiting ? 10 : 20),
        borderRadius: BorderRadius.circular(6),
        border: hover != null
            ? Border.all(color: hover, width: 1.5)
            : Border.all(color: pip.color.withAlpha(60), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(pip.icon, color: pip.color, size: 14),
          const SizedBox(width: 4),
          Text(
            pip.value,
            style: TextStyle(
              color: pip.color,
              fontSize: 12,
              fontWeight: pip.waiting ? null : FontWeight.bold,
              fontStyle: pip.waiting ? FontStyle.italic : null,
              decoration: pip.struck ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
