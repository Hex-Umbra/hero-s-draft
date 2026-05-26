import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CircleProgressComponent extends PositionComponent {
  final double radius;
  final double percentage;
  final Color color;

  CircleProgressComponent({
    required this.radius,
    required this.percentage,
    required this.color,
  }) : super(size: Vector2.all(radius * 2));

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Dessine un arc de cercle à partir du haut (-pi/2)
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.x, size.y),
      -1.5708, // -90 degrés
      6.28319 * percentage, // 360 degrés * pourcentage
      true,
      paint,
    );
  }
}
