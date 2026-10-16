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

const _smite = SignatureInstance(
  SignatureData(
    id: 'smite',
    heroClass: 'paladin',
    nameEn: 'Smite',
    nameFr: 'Chatiment',
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
    nameFr: 'Bouclier sacre',
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
  final shown = <SignatureInstance>[];
  int disarmed = 0;
  int insufficientMana = 0;
  int hidden = 0;

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
          onShowTooltip: calls.shown.add,
          onHideTooltip: () => calls.hidden++,
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

  testWidgets('sur une tuile de 64, le compte tient sur une ligne, a part du '
      'nom et du cout', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);

    final calls = _Calls();
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
    expect(tester.getSize(_tile('holy_shield')), const Size(64, 64));

    final count = find.text('2 tours');
    final paragraph = tester.renderObject<RenderParagraph>(count);
    final oneLine = TextPainter(
      text: paragraph.text,
      textDirection: TextDirection.ltr,
      textScaler: paragraph.textScaler,
    )..layout();
    addTearDown(oneLine.dispose);
    expect(paragraph.size.height, oneLine.height);

    final countRect = tester.getRect(count);
    final nameRect = tester.getRect(find.text('Bouclier sacre'));
    final costRect = tester.getRect(
      find.descendant(of: _tile('holy_shield'), matching: find.text('1')),
    );
    expect(countRect.overlaps(nameRect), isFalse);
    expect(countRect.overlaps(costRect), isFalse);
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

  testWidgets('les tuiles suivent l ordre donne et mesurent 76, 64 sous 600 '
      'de large', (tester) async {
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
    expect(tester.getSize(_tile('smite')), const Size(76, 76));

    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();
    expect(tester.getSize(_tile('smite')), const Size(64, 64));
  });

  testWidgets('le survol montre l infobulle de la signature, la sortie et '
      'l appui long aussi', (tester) async {
    final calls = _Calls();
    await tester.pumpWidget(_harness(calls));

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 10));
    await mouse.moveTo(tester.getCenter(_tile('smite')));
    await tester.pump();
    expect(calls.shown, [_smite]);
    expect(calls.hidden, 0);

    await mouse.moveTo(const Offset(700, 10));
    await tester.pump();
    expect(calls.hidden, 1);

    final touch = await tester.startGesture(
      tester.getCenter(_tile('holy_shield')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(calls.shown, [_smite, _holyShield]);
    expect(calls.hidden, 1);

    await touch.up();
    await tester.pump();
    expect(calls.hidden, 2);
  });
}
