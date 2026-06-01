import 'package:flutter/material.dart';

class SwordIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SwordIcon({
    super.key,
    this.size = 24.0,
    this.color = Colors.orangeAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SwordPainter(color: color)),
    );
  }
}

class _SwordPainter extends CustomPainter {
  final Color color;

  _SwordPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;

    // Use two shades of the color for a premium, beveled 3D look
    final HSLColor hslColor = HSLColor.fromColor(color);
    final Color lightColor = hslColor
        .withLightness((hslColor.lightness + 0.15).clamp(0.0, 1.0))
        .toColor();
    final Color darkColor = hslColor
        .withLightness((hslColor.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();

    final Paint mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint lightPaint = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;

    final Paint darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // 1. Blade: Left half (shaded dark for a bevel effect)
    final Path leftBlade = Path()
      ..moveTo(cx, h * 0.05) // Tip
      ..lineTo(cx - w * 0.12, h * 0.20) // Left shoulder
      ..lineTo(cx - w * 0.07, h * 0.65) // Left bottom base
      ..lineTo(cx, h * 0.65) // Center base
      ..close();
    canvas.drawPath(leftBlade, darkPaint);

    // 1. Blade: Right half (shaded light for a bevel effect)
    final Path rightBlade = Path()
      ..moveTo(cx, h * 0.05) // Tip
      ..lineTo(cx + w * 0.12, h * 0.20) // Right shoulder
      ..lineTo(cx + w * 0.07, h * 0.65) // Right bottom base
      ..lineTo(cx, h * 0.65) // Center base
      ..close();
    canvas.drawPath(rightBlade, lightPaint);

    // 2. Crossguard (Beautiful slightly curved design)
    final Path guardPath = Path()
      ..moveTo(cx - w * 0.30, h * 0.64)
      ..quadraticBezierTo(
        cx - w * 0.32,
        h * 0.62,
        cx - w * 0.32,
        h * 0.60,
      ) // Left end curve
      ..lineTo(cx - w * 0.26, h * 0.66)
      ..lineTo(cx + w * 0.26, h * 0.66)
      ..lineTo(cx + w * 0.32, h * 0.60) // Right end curve
      ..quadraticBezierTo(cx + w * 0.32, h * 0.62, cx + w * 0.30, h * 0.64)
      ..lineTo(cx, h * 0.72) // Curve point downward in center
      ..close();
    canvas.drawPath(guardPath, mainPaint);

    // Highlight center of guard
    final Paint guardHighlight = Paint()
      ..color = lightColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, h * 0.68), w * 0.06, guardHighlight);

    // 3. Grip/Hilt (Leather wrapped look via alternating segments)
    final Paint gripPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    final Path gripPath = Path()
      ..moveTo(cx - w * 0.05, h * 0.72)
      ..lineTo(cx + w * 0.05, h * 0.72)
      ..lineTo(cx + w * 0.04, h * 0.88)
      ..lineTo(cx - w * 0.04, h * 0.88)
      ..close();
    canvas.drawPath(gripPath, gripPaint);

    // Hilt wrappings details
    final Paint wrapPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.02;
    canvas.drawLine(
      Offset(cx - w * 0.05, h * 0.76),
      Offset(cx + w * 0.05, h * 0.78),
      wrapPaint,
    );
    canvas.drawLine(
      Offset(cx - w * 0.05, h * 0.81),
      Offset(cx + w * 0.05, h * 0.83),
      wrapPaint,
    );

    // 4. Pommel (Round circular jewel at the base)
    canvas.drawCircle(Offset(cx, h * 0.91), w * 0.08, lightPaint);
    canvas.drawCircle(Offset(cx, h * 0.91), w * 0.06, mainPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
