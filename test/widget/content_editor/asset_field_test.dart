import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/asset_field.dart';

/// Un PNG de 1 x 1 pixel transparent.
final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

void main() {
  Future<void> pump(WidgetTester tester, AssetField field) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: field),
      ));

  testWidgets('un son se choisit parmi les sons declares, ou aucun',
      (tester) async {
    String? picked;
    var cleared = false;
    await pump(
      tester,
      AssetField(
        fieldKey: 'sfx',
        slot: const AssetSlot.sound(),
        value: null,
        soundIds: const ['clang', 'zap'],
        onSelectSound: (id) => picked = id,
        onClear: () => cleared = true,
      ),
    );

    await tester.tap(find.text('zap'));
    expect(picked, 'zap');
    await tester.tap(find.text('aucun'));
    expect(cleared, isTrue);
  });

  testWidgets('Importer n apparait qu avec son geste', (tester) async {
    await pump(tester,
        const AssetField(fieldKey: 'sfx', slot: AssetSlot.sound()));
    expect(find.byKey(const Key('editeur-importer-sfx')), findsNothing);

    var imported = false;
    await pump(
      tester,
      AssetField(
        fieldKey: 'sfx',
        slot: const AssetSlot.sound(),
        onImport: () => imported = true,
      ),
    );
    await tester.tap(find.byKey(const Key('editeur-importer-sfx')));
    expect(imported, isTrue);
  });

  testWidgets('une image montre son apercu, et « aucune » si optionnelle',
      (tester) async {
    await pump(
      tester,
      AssetField(
        fieldKey: 'iconPath',
        slot: const AssetSlot.image('icon.png', isRequired: false),
        value: 'assets/data/classes/x/icon.png',
        imageBytes: _pixel,
        onClear: () {},
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('aucune'), findsOneWidget);

    await pump(
      tester,
      const AssetField(
        fieldKey: 'spritePath',
        slot: AssetSlot.image('sprite.png'),
        value: 'assets/data/enemies/x/sprite.png',
      ),
    );
    expect(find.text('aucune'), findsNothing);
  });
}
