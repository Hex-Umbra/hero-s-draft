import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/effect_icon_table.dart';
import 'package:roguelike_card_game/models/data/effect_kind.dart';
import 'package:roguelike_card_game/ui/widgets/effect_style.dart';

void main() {
  group('EffectIconTable.fromJson', () {
    test('un document complet se lit : chaque sorte, son icon et sa color', () {
      final table = EffectIconTable.fromJson({
        'damage': {'icon': 'hardware_rounded', 'color': 'redAccent'},
        'status:weakness': {
          'icon': 'trending_down_rounded',
          'color': 'purpleAccent',
        },
        'crit': {'icon': 'flare_rounded', 'color': 'amber'},
      });

      final damage = table.entryOf('damage')!;
      expect(damage.icon, 'hardware_rounded');
      expect(damage.color, 'redAccent');
      expect(
        table.kinds,
        unorderedEquals(['damage', 'status:weakness', 'crit']),
      );
      expect(table.entryOf('heal'), isNull);
      expect(EffectKind.isKind('status:weakness'), isTrue);
      expect(EffectKind.isKind('crit'), isTrue);
      expect(EffectKind.isKind('target:allEnemies'), isTrue);
    });

    test('une cle hors des sortes est refusee, nommee, apply_status nu compris',
        () {
      for (final key in ['apply_status', 'status:Weakness', 'poison', 'target:self']) {
        expect(
          () => EffectIconTable.fromJson({
            key: {'icon': 'hardware_rounded', 'color': 'redAccent'},
          }),
          throwsA(
            isA<FormatException>().having((e) => e.message, 'message', contains(key)),
          ),
          reason: key,
        );
      }
    });

    test('une valeur sans icon ou color, vide, ou a une cle de plus est refusee',
        () {
      final bad = <Object?>[
        {'color': 'redAccent'},
        {'icon': 'hardware_rounded'},
        {'icon': '', 'color': 'redAccent'},
        {'icon': 'hardware_rounded', 'color': 'redAccent', 'size': 3},
      ];
      for (final value in bad) {
        expect(
          () => EffectIconTable.fromJson({'damage': value}),
          throwsA(
            isA<FormatException>().having((e) => e.message, 'message', contains('damage')),
          ),
          reason: '$value',
        );
      }
    });
  });

  test('une sorte absente retombe sur Icons.help_outline et du gris', () {
    const empty = EffectIconTable.empty();

    final visuals = effectVisualsOf(empty, 'damage');
    expect(visuals.icon, Icons.help_outline);
    expect(visuals.color, Colors.grey);
    expect(effectVisualsOrNull(empty, 'damage'), isNull);
  });
}
