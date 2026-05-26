import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FlameShieldIcon extends PositionComponent {
  final Color color;

  FlameShieldIcon({
    required Vector2 position,
    required Vector2 size,
    required this.color,
    Anchor anchor = Anchor.topLeft,
  }) : super(position: position, size: size, anchor: anchor);

  @override
  void render(Canvas canvas) {
    final double w = size.x;
    final double h = size.y;
    final double cx = w / 2;

    // Use two shades of the color for a premium, beveled 3D look
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color lightColor = hslColor.withLightness((hslColor.lightness + 0.12).clamp(0.0, 1.0)).toColor();
    final Color darkColor = hslColor.withLightness((hslColor.lightness - 0.12).clamp(0.0, 1.0)).toColor();

    final Paint lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final Paint darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // 1. Dessine la moitié gauche du bouclier (teinte sombre pour effet biseau)
    final Path leftShield = Path()
      ..moveTo(cx, h * 0.08) // Sommet centre
      ..lineTo(w * 0.12, h * 0.18) // Épaule gauche
      ..lineTo(w * 0.12, h * 0.58) // Flanc gauche
      ..quadraticBezierTo(w * 0.12, h * 0.85, cx, h * 0.95) // Arrondi vers la pointe
      ..lineTo(cx, h * 0.08)
      ..close();
    canvas.drawPath(leftShield, darkPaint);

    // 2. Dessine la moitié droite du bouclier (teinte claire)
    final Path rightShield = Path()
      ..moveTo(cx, h * 0.08)
      ..lineTo(w * 0.88, h * 0.18) // Épaule droite
      ..lineTo(w * 0.88, h * 0.58) // Flanc droit
      ..quadraticBezierTo(w * 0.88, h * 0.85, cx, h * 0.95) // Arrondi vers la pointe
      ..lineTo(cx, h * 0.08)
      ..close();
    canvas.drawPath(rightShield, lightPaint);

    // 3. Jolie bordure brillante de couleur cyan accent
    final Paint borderPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08;

    final Path borderPath = Path()
      ..moveTo(cx, h * 0.08)
      ..lineTo(w * 0.12, h * 0.18)
      ..lineTo(w * 0.12, h * 0.58)
      ..quadraticBezierTo(w * 0.12, h * 0.85, cx, h * 0.95)
      ..quadraticBezierTo(w * 0.88, h * 0.85, w * 0.88, h * 0.58)
      ..lineTo(w * 0.88, h * 0.18)
      ..close();
    canvas.drawPath(borderPath, borderPaint);
  }
}
