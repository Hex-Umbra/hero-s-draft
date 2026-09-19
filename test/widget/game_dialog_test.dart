import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';

Future<void> _poser(
  WidgetTester tester, {
  required List<Widget> actions,
  Size taille = const Size(800, 600),
  TextScaler? echelle,
}) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: echelle == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: echelle),
              child: child!,
            ),
      home: Scaffold(
        body: GameDialog(
          title: const Text('Un titre de panneau'),
          content: const Text('Le corps du panneau.'),
          actions: actions,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // `GameDialog` porte les panneaux de tout le jeu — pause, reliques,
  // statistiques, probabilites, fusion. Sa rangee d'actions etait une `Row`,
  // qui ne retrecit pas ses enfants : deux boutons y debordaient de 33px sur
  // un telephone de 320px (mesure le 2026-09-19 sur le panneau de choix de
  // passif, depuis remplace par la carte depliante). Ces deux tests gardent
  // le `Wrap` qui l'a remplacee, seule couverture restante de ce correctif.
  testWidgets('deux actions tiennent sur un telephone de 320px', (
    tester,
  ) async {
    await _poser(
      tester,
      taille: const Size(320, 900),
      actions: [
        TextButton(onPressed: () {}, child: const Text('Annuler')),
        ElevatedButton(onPressed: () {}, child: const Text('Valider')),
      ],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
  });

  testWidgets('deux actions tiennent a 320px avec un texte a l echelle 1.3', (
    tester,
  ) async {
    await _poser(
      tester,
      taille: const Size(320, 900),
      echelle: const TextScaler.linear(1.3),
      actions: [
        TextButton(onPressed: () {}, child: const Text('Annuler')),
        ElevatedButton(onPressed: () {}, child: const Text('Valider')),
      ],
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('avec la place, les deux actions restent sur une seule ligne', (
    tester,
  ) async {
    // Le `Wrap` ne doit rien changer tant que la place existe : c'est ce qui
    // rend le correctif sans effet visible sur les panneaux du jeu.
    await _poser(
      tester,
      actions: [
        TextButton(onPressed: () {}, child: const Text('Annuler')),
        ElevatedButton(onPressed: () {}, child: const Text('Valider')),
      ],
    );

    expect(
      tester.getCenter(find.text('Annuler')).dy,
      tester.getCenter(find.text('Valider')).dy,
    );
  });
}
