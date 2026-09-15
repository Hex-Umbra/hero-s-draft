import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/floating_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Flame 1.38 donne `HasPaint` a `TextComponent` et y branche l'opacite sur
  // `TextStyle.foreground`. Ce chemin-la leve sur un style qui porte deja une
  // `color`, et n'estompe pas les ombres : `FloatingText` garde donc son
  // propre setter, et ce test le tient.
  test('l opacite estompe le texte et ses ombres ensemble', () {
    final text = FloatingText(
      text: '12',
      color: Colors.red,
      position: Vector2.zero(),
      isCritical: true,
    );

    text.opacity = 0.5;

    final style = (text.textRenderer as TextPaint).style;
    expect(text.opacity, 0.5);
    expect(style.foreground, isNull);
    expect(style.color!.a, closeTo(0.5, 0.01));
    for (final shadow in style.shadows!) {
      expect(shadow.color.a, lessThanOrEqualTo(0.5 + 0.01));
    }
    expect(style.shadows!.first.color.a, closeTo(0.45, 0.01));
  });
}
