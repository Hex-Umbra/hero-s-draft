import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TargetingLine extends Component {
  Vector2? from;
  Vector2? to;
  bool isVisible = false;
  Color color;

  TargetingLine({this.color = Colors.white70});

  @override
  void render(Canvas canvas) {
    if (!isVisible || from == null || to == null) return;

    final paint = Paint()
      ..color = color.withAlpha(180)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Dessiner la ligne avec un effet de pointillés/courbe
    final path = Path();
    path.moveTo(from!.x, from!.y);
    
    // Courbe de Bézier quadratique pour un effet plus organique
    final controlPoint = Vector2(
      (from!.x + to!.x) / 2,
      min(from!.y, to!.y) - 50,
    );
    path.quadraticBezierTo(controlPoint.x, controlPoint.y, to!.x, to!.y);

    canvas.drawPath(path, paint);

    // Dessiner une flèche au bout
    final angle = atan2(to!.y - controlPoint.y, to!.x - controlPoint.x);
    final arrowSize = 15.0;
    
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
    
    canvas.drawPath(arrowPath, paint..strokeWidth = 3);
    
    // Cercle d'impact subtil
    canvas.drawCircle(Offset(to!.x, to!.y), 6, Paint()..color = color.withAlpha(200));
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
