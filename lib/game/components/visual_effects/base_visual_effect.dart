import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class BaseVisualEffect extends PositionComponent with HasPaint {
  final double duration;
  final VoidCallback? onComplete;

  BaseVisualEffect({
    required this.duration,
    this.onComplete,
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  }) {
    add(
      RemoveEffect(
        delay: duration,
        onComplete: onComplete,
      ),
    );
  }
}
