import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_validator.dart';
import '../../../services/content_editor/entity_writer.dart';
import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// Le bandeau de l'issue du dernier geste, s'il y a quelque chose a dire :
/// un echec, sinon les fautes, sinon ce qui a ete ecrit.
Widget? outcomeBannerFor({
  String? failure,
  required List<ValidationFault> faults,
  WriteReport? report,
  required ValueChanged<String> onJump,
}) {
  if (failure != null) return OutcomeBanner.failure(failure);
  if (faults.isNotEmpty) return OutcomeBanner.faults(faults, onJump: onJump);
  if (report != null) return OutcomeBanner.report(report);
  return null;
}

/// L'issue du dernier geste (spec D7) : un refus en rouge, une ecriture en
/// vert, et en ambre ce qu'il reste a faire pour la voir.
class OutcomeBanner extends StatelessWidget {
  const OutcomeBanner.failure(String this.failure, {super.key})
      : faults = const [],
        report = null,
        onJump = null;

  const OutcomeBanner.faults(
    this.faults, {
    super.key,
    required ValueChanged<String> this.onJump,
  })  : failure = null,
        report = null;

  const OutcomeBanner.report(WriteReport this.report, {super.key})
      : failure = null,
        faults = const [],
        onJump = null;

  final String? failure;
  final List<ValidationFault> faults;
  final WriteReport? report;

  /// Ramene au champ nomme par une faute.
  final ValueChanged<String>? onJump;

  @override
  Widget build(BuildContext context) {
    final refused = report == null;
    final tone = refused ? AppColors.danger : AppColors.success;
    return Container(
      key: const Key('editeur-issue'),
      constraints: const BoxConstraints(maxHeight: 130),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: refused ? 0.07 : 0.05),
        border: Border.all(color: tone.withValues(alpha: refused ? 0.45 : 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _lines(),
        ),
      ),
    );
  }

  List<Widget> _lines() {
    final failure = this.failure;
    if (failure != null) {
      return [
        _line(Icons.error, AppColors.danger, [
          Expanded(
            child: Text('Échec : $failure',
                style: _style(EditorColors.refusedInk)),
          ),
        ]),
      ];
    }
    final report = this.report;
    if (report == null) return [for (final fault in faults) _fault(fault)];
    return [
      for (final path in report.written)
        _line(Icons.check_circle, AppColors.success, [
          Expanded(
            child: Text('Écrit : $path',
                style: _style(EditorColors.writtenInk)),
          ),
        ]),
      if (report.syncFailed)
        _line(Icons.error, AppColors.danger, [
          Expanded(
            child: Text(
              'sync_assets a échoué : ${report.sync!.output}',
              style: _style(EditorColors.refusedInk),
            ),
          ),
        ]),
      // §6.3 de la spec du 2026-09-08 : pour une creation, le redemarrage a
      // chaud a ete verifie a la main le 2026-09-14.
      _line(Icons.restart_alt, AppColors.warning, [
        Expanded(
          child: Text(
            report.createdEntity
                ? 'Redémarrage à chaud pour charger la nouvelle entité.'
                : 'Redémarrage à chaud pour voir la modification.',
            style: _style(AppColors.warning),
          ),
        ),
      ]),
    ];
  }

  /// Une faute qui nomme son champ se touche pour y revenir.
  Widget _fault(ValidationFault fault) {
    final field = fault.field;
    final line = _line(Icons.error, AppColors.danger, [
      if (field != null) ...[
        Text(
          field,
          style: editorMono(color: AppColors.danger, weight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(
        child: Text(fault.message, style: _style(EditorColors.refusedInk)),
      ),
      if (field != null) ...[
        const SizedBox(width: 8),
        const Text(
          'aller au champ ↑',
          style: TextStyle(color: EditorColors.faint, fontSize: 11.5),
        ),
      ],
    ]);
    if (field == null) return line;
    // Le `Material` transparent est ce qui manquait a l'encre du survol et du
    // focus pour se voir : sans lui, elle peint sous le fond du bandeau.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => onJump?.call(field),
        borderRadius: BorderRadius.circular(5),
        child: line,
      ),
    );
  }

  static TextStyle _style(Color color) =>
      TextStyle(color: color, fontSize: 13);

  static Widget _line(IconData icon, Color color, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          ...children,
        ],
      ),
    );
  }
}

/// La barre d'actions fixe au bas du formulaire (spec D7) : l'issue du
/// dernier geste, une ligne d'aide, et les boutons — toujours visibles, quel
/// que soit le defilement.
class EditorActionBar extends StatelessWidget {
  const EditorActionBar({
    super.key,
    this.banner,
    required this.note,
    this.noteIsAlarm = false,
    required this.actions,
  });

  final Widget? banner;
  final String note;

  /// La note annonce des fautes : elle passe au rouge.
  final bool noteIsAlarm;
  final List<Widget> actions;

  /// Sous cette largeur, la note passe au-dessus des boutons.
  static const double stackBelow = 560;

  @override
  Widget build(BuildContext context) {
    final noteRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          noteIsAlarm ? Icons.block : Icons.info_outline,
          size: 16,
          color: noteIsAlarm ? AppColors.danger : EditorColors.faint,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            note,
            style: TextStyle(
              color: noteIsAlarm ? AppColors.danger : EditorColors.faint,
              fontSize: 12.5,
              fontWeight: noteIsAlarm ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 8,
      children: actions,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 14),
      decoration: const BoxDecoration(
        color: EditorColors.bar,
        border: Border(top: BorderSide(color: EditorColors.line)),
        boxShadow: [
          BoxShadow(
            color: EditorColors.barShadow,
            blurRadius: 30,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < stackBelow;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner != null) ...[banner!, const SizedBox(height: 10)],
              if (stacked) ...[
                noteRow,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: buttons),
              ] else
                Row(
                  children: [
                    Expanded(child: noteRow),
                    const SizedBox(width: 12),
                    buttons,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
