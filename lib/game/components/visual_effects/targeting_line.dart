import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TargetingLine extends Component {
  Vector2? from;
  Vector2? to;
  bool isVisible = false;
  Color color;
  double _time = 0.0;

  TargetingLine({this.color = Colors.white70});

  @override
  void update(double dt) {
    super.update(dt);
    if (isVisible) {
      _time += dt * 1.5; // Speed of dot scrolling
    }
  }

  Vector2 getBezierPoint(Vector2 p0, Vector2 p1, Vector2 p2, double t) {
    final double u = 1.0 - t;
    final double tt = t * t;
    final double uu = u * u;

    final x = uu * p0.x + 2 * u * t * p1.x + tt * p2.x;
    final y = uu * p0.y + 2 * u * t * p1.y + tt * p2.y;
    return Vector2(x, y);
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible || from == null || to == null) return;

    // Define control point for Quadratic Bezier
    final midX = (from!.x + to!.x) / 2;
    // Bend the curve upwards
    final double controlY =
        min(from!.y, to!.y) - 100 - (from!.x - to!.x).abs() * 0.15;
    final controlPoint = Vector2(midX, controlY);

    // Draw the smooth bezier path underneath as a subtle glow
    final mainPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path();
    path.moveTo(from!.x, from!.y);
    path.quadraticBezierTo(controlPoint.x, controlPoint.y, to!.x, to!.y);
    canvas.drawPath(path, mainPaint);

    // Draw glowing dotted circles scrolling along the curve
    final int numDots = 16;
    for (int i = 0; i <= numDots; i++) {
      // Offset translation based on time
      final double t = (i / numDots + (_time * 0.25)) % 1.0;

      // Position along Bezier
      final p = getBezierPoint(from!, controlPoint, to!, t);

      // Scale down near start and end for smooth entry/exit
      final double scale = t < 0.15
          ? (t / 0.15)
          : (t > 0.85 ? (1.0 - t) / 0.15 : 1.0);
      final double radius = 3.0 + scale * 4.0;

      final dotPaint = Paint()
        ..color = color.withValues(alpha: (0.1 + scale * 0.9))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + scale * 2);

      canvas.drawCircle(Offset(p.x, p.y), radius, dotPaint);
    }

    // Tangent angle at t = 1.0 for the arrow
    final angle = atan2(to!.y - controlPoint.y, to!.x - controlPoint.x);
    final arrowSize = 18.0;

    final arrowPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final arrowPath = Path();
    arrowPath.moveTo(to!.x, to!.y);
    arrowPath.lineTo(
      to!.x - arrowSize * cos(angle - pi / 6),
      to!.y - arrowSize * sin(angle - pi / 6),
    );
    arrowPath.moveTo(to!.x, to!.y);
    arrowPath.lineTo(
      to!.x - arrowSize * cos(angle + pi / 6),
      to!.y - arrowSize * sin(angle + pi / 6),
    );

    canvas.drawPath(arrowPath, arrowPaint);

    // Glowing impact circle
    canvas.drawCircle(
      Offset(to!.x, to!.y),
      8,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void updatePoints(Vector2 from, Vector2 to) {
    this.from = from;
    this.to = to;
    isVisible = true;
  }

  void hide() {
    isVisible = false;
  }
}
