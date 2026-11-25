import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Le contour de ciblage d'un ennemi (B78, spec P-05 vague 2, A14) : un trait
/// posé à l'extérieur de sa fenêtre, sur le filet du cadre, et la lueur cyan
/// pulsante de la surbrillance. Au repos, rien. Il ne décide rien : sa carte
/// lui dit quoi montrer.
class TargetOutline extends PositionComponent {
  TargetOutline({required this.window}) : super(priority: _priority);

  /// La fenêtre de la carte, dans les coordonnées de la carte.
  final Rect window;

  /// Au-dessus du cadre (2), sous la gangue (4) et le halo (5).
  static const int _priority = 3;

  Color? _color;
  double _strokeWidth = 0;
  bool _glowing = false;
  double _time = 0;

  /// La couleur du trait, nulle au repos.
  Color? get color => _color;

  /// Le rectangle du trait : la fenêtre agrandie de la moitié du trait, qui se
  /// pose ainsi tout entier hors d'elle ; nul au repos.
  Rect? get strokeRect =>
      _color == null ? null : window.inflate(_strokeWidth / 2);

  /// [color] nulle : plus de trait.
  void setStroke(Color? color, double width) {
    _color = color;
    _strokeWidth = width;
  }

  /// La lueur de la surbrillance, qui pulse tant qu'elle dure.
  set glowing(bool value) {
    if (value && !_glowing) _time = 0;
    _glowing = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_glowing) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_glowing) {
      final opacity = 0.5 + 0.3 * sin(_time * 4);
      final width = 6 + 2 * opacity;
      canvas.drawRect(
        window.inflate(width / 2),
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8 + 4 * opacity),
      );
    }
    final rect = strokeRect;
    final stroke = color;
    if (rect != null && stroke != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }
  }
}
