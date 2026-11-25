import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Le halo jaune d'un porteur de Foudre chargee (spec P-53, §5.2, L-b) : un
/// contour flou autour de la carte, ne a l'apparition de la rupture, qui
/// pulse tant que la charge dure. Ni eclair, ni etincelle.
class ChargeHalo extends PositionComponent {
  ChargeHalo({required Vector2 size, super.position})
      : super(size: size, priority: _haloPriority);

  static const Color color = Color(0xFFFFEA00);

  static const int _haloPriority = 5;
  static const double _birthSeconds = 0.2;
  static const double _pulseSeconds = 0.6;
  static const double _troughOpacity = 0.35;
  static const double _fadeSeconds = 0.2;

  double _age = 0;
  double _fadeAge = 0;
  bool _fadingOut = false;

  /// Le fondu de sortie, puis le retrait du halo.
  void fadeOut() {
    _fadingOut = true;
  }

  double get _opacity {
    final double alive = _age < _birthSeconds
        ? _age / _birthSeconds
        : _troughOpacity +
            (1 - _troughOpacity) *
                (0.5 +
                    0.5 *
                        cos(2 * pi * (_age - _birthSeconds) / _pulseSeconds));
    return _fadingOut ? alive * (1 - _fadeAge / _fadeSeconds) : alive;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_fadingOut) {
      _fadeAge += dt;
      if (_fadeAge >= _fadeSeconds) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = _opacity.clamp(0.0, 1.0);
    final rrect = RRect.fromRectAndRadius(size.toRect(), const Radius.circular(0));
    final haloPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 10);
    canvas.drawRRect(rrect, haloPaint);
  }
}
