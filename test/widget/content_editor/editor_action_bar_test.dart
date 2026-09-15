import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_action_bar.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 900}) {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
    ));
  }

  group('outcomeBannerFor', () {
    testWidgets('rien a dire, pas de bandeau', (tester) async {
      expect(outcomeBannerFor(faults: const [], onJump: (_) {}), isNull);
    });

    testWidgets('un echec l emporte sur les fautes et le rapport',
        (tester) async {
      await pump(
        tester,
        outcomeBannerFor(
          failure: 'disque plein',
          faults: const [ValidationFault('x')],
          report: const WriteReport(written: ['a.json']),
          onJump: (_) {},
        )!,
      );
      expect(find.text('Échec : disque plein'), findsOneWidget);
      expect(find.text('x'), findsNothing);
      expect(find.byKey(const Key('editeur-issue')), findsOneWidget);
    });
  });

  testWidgets('une faute qui nomme son champ y ramene, une autre non',
      (tester) async {
    final jumps = <String>[];
    await pump(
      tester,
      OutcomeBanner.faults(
        const [
          ValidationFault('« 1a » n\'est pas un entier', field: 'value'),
          ValidationFault('assets/data/relics/x.json existe déjà'),
        ],
        onJump: jumps.add,
      ),
    );

    expect(find.textContaining('n\'est pas un entier'), findsOneWidget);
    await tester.tap(find.text('value'));
    expect(jumps, ['value']);

    expect(
      find.ancestor(
        of: find.textContaining('existe déjà'),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('un rapport dit ce qui est ecrit et ce qu il reste a faire',
      (tester) async {
    await pump(
      tester,
      const OutcomeBanner.report(WriteReport(
        written: ['assets/data/relics/a.json', 'assets/data/relics/b.json'],
        sync: ProcessOutcome(1, 'boum'),
        createdEntity: true,
      )),
    );
    expect(find.text('Écrit : assets/data/relics/a.json'), findsOneWidget);
    expect(find.text('Écrit : assets/data/relics/b.json'), findsOneWidget);
    expect(find.text('sync_assets a échoué : boum'), findsOneWidget);
    expect(find.text('Redémarrage à chaud pour charger la nouvelle entité.'),
        findsOneWidget);

    await pump(
      tester,
      const OutcomeBanner.report(WriteReport(written: ['a.json'])),
    );
    expect(find.text('Redémarrage à chaud pour voir la modification.'),
        findsOneWidget);
  });

  group('EditorActionBar', () {
    EditorActionBar bar() => EditorActionBar(
          note: 'Valider vérifie sans écrire',
          actions: [
            EditorButton(label: 'Valider', icon: Icons.fact_check, onPressed: () {}),
            EditorButton(label: 'Écrire', icon: Icons.save, onPressed: () {}),
          ],
        );

    testWidgets('large, la note et les boutons partagent une ligne',
        (tester) async {
      await pump(tester, bar());
      expect(
        tester.getCenter(find.text('Valider vérifie sans écrire')).dy,
        moreOrLessEquals(tester.getCenter(find.text('Écrire')).dy, epsilon: 12),
      );
      expect(tester.getTopLeft(find.text('Écrire')).dx,
          greaterThan(tester.getTopLeft(find.text('Valider')).dx));
    });

    testWidgets('etroite, la note passe au-dessus des boutons', (tester) async {
      await pump(tester, bar(), width: 420);
      expect(
        tester.getBottomLeft(find.text('Valider vérifie sans écrire')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Valider')).dy),
      );
    });

    testWidgets('le bandeau se tient au-dessus de la ligne d actions',
        (tester) async {
      await pump(
        tester,
        EditorActionBar(
          banner: const OutcomeBanner.failure('disque plein'),
          note: 'note',
          actions: const [],
        ),
      );
      expect(
        tester.getBottomLeft(find.byKey(const Key('editeur-issue'))).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('note')).dy),
      );
    });
  });
}
