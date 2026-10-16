import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/ui/widgets/hud/signature_bar.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/ui_card_helpers.dart';

const _smite = SignatureInstance(
  SignatureData(
    id: 'smite',
    heroClass: 'paladin',
    nameEn: 'Smite',
    nameFr: 'Châtiment',
    descriptionEn: 'Deal 6 damage and gain 4 Block.',
    descriptionFr: "Inflige 6 dégâts et donne 4 d'Armure.",
    cost: 1,
    cooldown: 2,
    type: CardType.attack,
    target: CardTarget.singleEnemy,
    effects: [CardEffect(type: 'damage', value: 8)],
  ),
);

const _holyShield = SignatureInstance(
  SignatureData(
    id: 'holy_shield',
    heroClass: 'paladin',
    nameEn: 'Holy Shield',
    nameFr: 'Bouclier Sacré',
    descriptionEn: 'Gain 8 Block and heal 2 HP.',
    descriptionFr: "Donne 8 d'Armure et soigne 2 PV.",
    cost: 1,
    cooldown: 2,
    type: CardType.skill,
    target: CardTarget.self,
    effects: [CardEffect(type: 'block', value: 8)],
  ),
);

class _Calls {
  final played = <SignatureInstance>[];
  final armed = <SignatureInstance>[];
  int disarmed = 0;
  int insufficientMana = 0;

  int get gestures =>
      played.length + armed.length + disarmed + insufficientMana;
}

Widget _harness(
  _Calls calls, {
  List<SignatureInstance> signatures = const [_smite, _holyShield],
  CombatState? combatState,
  int currentMana = 3,
  bool interactive = true,
  String? armedId,
  Locale locale = const Locale('en', ''),
}) => MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('en', ''), Locale('fr', '')],
  locale: locale,
  home: Scaffold(
    body: Stack(
      children: [
        SignatureBar(
          signatures: signatures,
          combatState: combatState ?? CombatState(),
          currentMana: currentMana,
          interactive: interactive,
          classColor: Colors.amber,
          armedId: armedId,
          onPlay: calls.played.add,
          onArm: calls.armed.add,
          onDisarm: () => calls.disarmed++,
          onInsufficientMana: () => calls.insufficientMana++,
        ),
      ],
    ),
  ),
);

CombatState _smiteRecharging([int readyOn = 3]) =>
    CombatState(turnCount: 1, signaturesReadyOn: {'smite': readyOn});

Finder _tile(String id) => find.byKey(ValueKey('signature-tile-$id'));

void main() {
  test('la priorite des etats : inactive, recharge, mana, armee, disponible', () {
    SignatureTileState of({
      bool interactive = true,
      int turnsLeft = 0,
      bool affordable = true,
      bool armed = false,
    }) => signatureTileStateOf(
      interactive: interactive,
      turnsLeft: turnsLeft,
      affordable: affordable,
      armed: armed,
    );

    expect(of(), SignatureTileState.available);
    expect(of(armed: true), SignatureTileState.armed);
    expect(of(affordable: false, armed: true), SignatureTileState.unaffordable);
    expect(
      of(turnsLeft: 2, affordable: false, armed: true),
      SignatureTileState.recharging,
    );
    expect(
      of(interactive: false, turnsLeft: 2, affordable: false, armed: true),
      SignatureTileState.inactive,
    );
  });

  testWidgets('le fond est neutre quel que soit le type, sans liseré', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(_Calls(), armedId: 'smite'));
    await tester.pump();

    for (final id in ['smite', 'holy_shield']) {
      final tile = tester.widget<Container>(_tile(id));
      expect((tile.decoration! as BoxDecoration).color, neutralCardBackground);

      final stripes = tester
          .widgetList<ColoredBox>(
            find.descendant(of: _tile(id), matching: find.byType(ColoredBox)),
          )
          .map((b) => b.color)
          .where((c) => c == Colors.redAccent || c == Colors.blueAccent);
      expect(stripes, isEmpty);
    }
  });

  testWidgets('une tuile en recharge affiche son compte, en anglais et en '
      'francais', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _harness(calls, combatState: _smiteRecharging()),
    );
    expect(find.text('2 turns'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        calls,
        combatState: _smiteRecharging(),
        locale: const Locale('fr', ''),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 tours'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        calls,
        combatState: _smiteRecharging(2),
        locale: const Locale('fr', ''),
      ),
    );
    expect(find.text('1 tour'), findsOneWidget);
  });

  testWidgets('en recharge, nom, type, description et compte ne se '
      'chevauchent pas, aux deux largeurs', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final calls = _Calls();
    for (final size in const [Size(1280, 800), Size(400, 800)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        _harness(
          calls,
          combatState: CombatState(
            turnCount: 1,
            signaturesReadyOn: {'holy_shield': 3},
          ),
          locale: const Locale('fr', ''),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      Finder inTile(Finder matching) =>
          find.descendant(of: _tile('holy_shield'), matching: matching);

      final count = inTile(find.text('2 tours'));
      final paragraph = tester.renderObject<RenderParagraph>(count);
      final oneLine = TextPainter(
        text: paragraph.text,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      addTearDown(oneLine.dispose);
      expect(paragraph.size.height, oneLine.height);

      final rects = [
        tester.getRect(inTile(find.text('Bouclier Sacré'))),
        tester.getRect(inTile(find.text('Compétence'))),
        tester.getRect(inTile(find.text("Donne 8 d'Armure et soigne 2 PV."))),
        tester.getRect(count),
        tester.getRect(
          inTile(
            find.byWidgetPredicate(
              (w) =>
                  w is Container &&
                  w.decoration is BoxDecoration &&
                  (w.decoration! as BoxDecoration).shape == BoxShape.circle,
            ),
          ),
        ),
      ];
      for (var i = 0; i < rects.length; i++) {
        for (var j = i + 1; j < rects.length; j++) {
          expect(
            rects[i].overlaps(rects[j]),
            isFalse,
            reason: 'rectangles $i et $j, sur $size',
          );
        }
      }
    }
  });

  testWidgets('la tuile montre le nom, le type et la description', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));

    Finder inSmite(String text) =>
        find.descendant(of: _tile('smite'), matching: find.text(text));

    expect(inSmite('Smite'), findsOneWidget);
    expect(inSmite('Attack'), findsOneWidget);
    expect(inSmite('Deal 6 damage and gain 4 Block.'), findsOneWidget);
    expect(inSmite('2 turns'), findsNothing);

    await tester.pumpWidget(_harness(calls, combatState: _smiteRecharging()));
    expect(inSmite('Smite'), findsOneWidget);
    expect(inSmite('Attack'), findsOneWidget);
    expect(inSmite('Deal 6 damage and gain 4 Block.'), findsOneWidget);
    expect(inSmite('2 turns'), findsOneWidget);
  });

  testWidgets('armer une signature ne deplace pas les tuiles', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));
    final rest = tester.getTopLeft(_tile('smite'));

    // L'impulsion se répète sans fin : jamais `pumpAndSettle` une fois armée.
    await tester.pumpWidget(_harness(calls, armedId: 'smite'));
    await tester.pump();
    expect(find.text('Choose a target'), findsOneWidget);
    expect(tester.getTopLeft(_tile('smite')), rest);
  });

  testWidgets('une tuile inactive garde son compte lisible et ne repond pas', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _harness(calls, interactive: false, combatState: _smiteRecharging()),
    );
    expect(find.text('2 turns'), findsOneWidget);

    await tester.tap(_tile('smite'));
    await tester.tap(_tile('holy_shield'));
    await tester.pump();

    expect(calls.gestures, 0);
  });

  testWidgets('toucher une tuile en recharge n appelle rien', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls, combatState: _smiteRecharging()));

    await tester.tap(_tile('smite'));
    await tester.pump();

    expect(calls.gestures, 0);
  });

  testWidgets('toucher une tuile disponible sans cible d ennemi la joue '
      'aussitot', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));

    await tester.tap(_tile('holy_shield'));
    await tester.pump();

    expect(calls.played, [_holyShield]);
    expect(calls.armed, isEmpty);
  });

  testWidgets('toucher une tuile disponible qui vise un ennemi l arme', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));

    await tester.tap(_tile('smite'));
    await tester.pump();

    expect(calls.armed, [_smite]);
    expect(calls.played, isEmpty);
  });

  testWidgets('une tuile armee montre l invite et se desarme au toucher', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls, armedId: 'smite'));
    expect(find.text('Choose a target'), findsOneWidget);

    await tester.tap(_tile('smite'));
    await tester.pump();

    expect(calls.disarmed, 1);
    expect(calls.armed, isEmpty);

    await tester.pumpWidget(_harness(calls));
    expect(find.text('Choose a target'), findsNothing);
  });

  testWidgets('mana insuffisant : le son, la secousse, rien n est joue', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls, currentMana: 0));
    final rest = tester.getTopLeft(_tile('smite'));

    await tester.tap(_tile('smite'));
    expect(calls.insufficientMana, 1);
    expect(calls.played, isEmpty);
    expect(calls.armed, isEmpty);

    // Le premier frame démarre l'animation à t = 0.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(tester.getTopLeft(_tile('smite')), isNot(rest));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_tile('smite')), rest);
  });

  testWidgets('les tuiles suivent l ordre donne et mesurent 220 de large, 170 '
      'sous 600', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(
      _harness(calls, signatures: const [_holyShield, _smite]),
    );
    expect(
      tester.getTopLeft(_tile('holy_shield')).dy,
      lessThan(tester.getTopLeft(_tile('smite')).dy),
    );

    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(tester.getSize(_tile('smite')).width, 220);
    expect(tester.getSize(_tile('holy_shield')).width, 220);

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(tester.getSize(_tile('smite')).width, 170);
    expect(tester.getSize(_tile('holy_shield')).width, 170);
  });

  Size paintedSize(WidgetTester tester, String id) =>
      Size(
        tester.getBottomRight(_tile(id)).dx - tester.getTopLeft(_tile(id)).dx,
        tester.getBottomRight(_tile(id)).dy - tester.getTopLeft(_tile(id)).dy,
      );

  MouseCursor cursor() =>
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1)!;

  testWidgets('survoler une tuile qui repond l agrandit et met le curseur '
      'main, la quitter la ramene', (tester) async {
    await tester.pumpWidget(_harness(_Calls()));
    final rest = paintedSize(tester, 'smite');
    final restLeft = tester.getTopLeft(_tile('smite'));
    final otherRest = tester.getRect(_tile('holy_shield'));

    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await mouse.addPointer(location: const Offset(700, 10));
    addTearDown(mouse.removePointer);
    await tester.pump();
    expect(cursor(), SystemMouseCursors.basic);

    await mouse.moveTo(tester.getCenter(_tile('smite')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    final hovered = paintedSize(tester, 'smite');
    expect(hovered.width, closeTo(rest.width * 1.05, 0.01));
    expect(hovered.height, closeTo(rest.height * 1.05, 0.01));
    expect(tester.getTopLeft(_tile('smite')).dx, closeTo(restLeft.dx, 0.01));
    expect(cursor(), SystemMouseCursors.click);
    expect(tester.getRect(_tile('holy_shield')), otherRest);

    await mouse.moveTo(const Offset(700, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(paintedSize(tester, 'smite'), rest);
    expect(cursor(), SystemMouseCursors.basic);
  });

  testWidgets('une tuile en recharge ou inactive ne reagit pas au survol', (
    tester,
  ) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls, combatState: _smiteRecharging()));
    final rest = paintedSize(tester, 'smite');

    final mouse = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      pointer: 1,
    );
    await mouse.addPointer(location: const Offset(700, 10));
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(_tile('smite')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(paintedSize(tester, 'smite'), rest);
    expect(cursor(), SystemMouseCursors.basic);

    await tester.pumpWidget(_harness(calls, interactive: false));
    final restInactive = paintedSize(tester, 'holy_shield');
    await mouse.moveTo(tester.getCenter(_tile('holy_shield')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(paintedSize(tester, 'holy_shield'), restInactive);
    expect(cursor(), SystemMouseCursors.basic);
    expect(calls.gestures, 0);
  });

  testWidgets('ni le survol ni l appui long n ouvrent rien', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 10));
    await mouse.moveTo(tester.getCenter(_tile('smite')));
    await tester.pump();
    await mouse.moveTo(const Offset(700, 10));
    await tester.pump();

    final touch = await tester.startGesture(
      tester.getCenter(_tile('holy_shield')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await touch.cancel();
    await tester.pump();

    expect(calls.gestures, 0);
    expect(tester.takeException(), isNull);
  });
}
