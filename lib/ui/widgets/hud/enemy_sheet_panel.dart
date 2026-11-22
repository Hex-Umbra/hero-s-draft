import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/combat_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/game_data_service.dart';
import 'enemy_intents_panel.dart';
import 'enemy_sheet_view.dart';

/// Le cadre de la fiche d'un ennemi (spec P-05, §5.4), posé à côté de sa carte
/// agrandie. Il lit l'ennemi dans l'état de combat à chaque construction, et
/// absorbe ses appuis : aucun n'atteint un ennemi estompé dessous.
class EnemySheetPanel extends ConsumerWidget {
  final String enemyId;

  /// Le rectangle de la carte agrandie, barre et languettes au repos
  /// comprises, sur le canevas du jeu.
  final Rect card;

  const EnemySheetPanel({super.key, required this.enemyId, required this.card});

  static const double _lineGap = 5;

  /// Entre la dernière pastille et le nom de l'intention, marge de la pastille
  /// comprise.
  static const double _pipToName = 8;
  static const Color _hintColor = Color(0xFFC9C9D6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enemy = ref
        .watch(combatProvider)
        .enemies
        .where((e) => e.id == enemyId)
        .firstOrNull;
    // Le reflet est différé : l'ennemi parti peut y rester une ou deux images.
    if (enemy == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final view = EnemySheetView.of(
      enemy,
      charges: ref.watch(chargeCatalogProvider),
      l10n: l10n,
      locale: Localizations.localeOf(context).languageCode,
    );
    final topLeft = SheetPlacement.topLeftFor(
      card: card,
      screen: MediaQuery.sizeOf(context),
    );

    return Positioned(
      left: topLeft.dx,
      top: topLeft.dy,
      child: AbsorbPointer(
        child: SizedBox(
          width: 310,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C).withAlpha(245),
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
                _title(view),
                const Divider(color: Colors.white12, height: 12),
                _figures(view),
                const Divider(color: Colors.white12, height: 12),
                ..._intent(l10n, view),
                if (view.bonuses.isNotEmpty)
                  ..._entries(
                    l10n.sheetSectionBonuses,
                    view.bonuses,
                    const Color(0xFF69F0AE),
                  ),
                if (view.alterations.isNotEmpty)
                  ..._entries(
                    l10n.sheetSectionAlterations,
                    view.alterations,
                    const Color(0xFFFF8A80),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(EnemySheetView view) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              view.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFD740),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            view.level,
            style: const TextStyle(color: Color(0xFF7C7C8A), fontSize: 12),
          ),
        ],
      );

  /// PV, Armure et Puissance, 18 entre deux ; une ligne de plus si les trois
  /// ne tiennent pas dans la largeur du cadre.
  Widget _figures(EnemySheetView view) => Wrap(
        spacing: 18,
        runSpacing: _lineGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(view.hp, style: _figure(Colors.white)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, color: Color(0xFF2196F3), size: 12),
              const SizedBox(width: 4),
              Text(view.armor, style: _figure(const Color(0xFF00E5FF))),
            ],
          ),
          Text('⚡ ${view.might}', style: _figure(const Color(0xFFFF5252))),
        ],
      );

  List<Widget> _intent(AppLocalizations l10n, EnemySheetView view) => [
        _sectionTitle(l10n.sheetSectionIntent),
        const SizedBox(height: _lineGap),
        Row(
          children: [
            for (var i = 0; i < view.pips.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              IntentPipChip(view.pips[i]),
            ],
            if (view.intentName.isNotEmpty) ...[
              const SizedBox(width: _pipToName - IntentPipChip.marginX),
              Flexible(
                child: Text(
                  view.intentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: _lineGap),
        Text(
          view.intentSentence,
          style: const TextStyle(color: _hintColor, fontSize: 12),
        ),
      ];

  List<Widget> _entries(String title, List<SheetEntry> entries, Color color) => [
        const SizedBox(height: _lineGap),
        _sectionTitle(title),
        for (final entry in entries) ...[
          const SizedBox(height: _lineGap),
          Text(
            entry.text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (entry.hint case final hint?)
            Text(hint, style: const TextStyle(color: _hintColor, fontSize: 12)),
        ],
      ];

  static Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
          color: Color(0xFF8E8E9C),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      );

  static TextStyle _figure(Color color) =>
      TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold);
}
