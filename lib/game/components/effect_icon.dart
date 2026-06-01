import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class EffectIcon extends PositionComponent with HasPaint {
  final String iconType;

  EffectIcon({required this.iconType, required Vector2 position})
    : super(position: position, size: Vector2(40, 40), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    // Combined premium animation: drift upward, scale up-and-down, and fade out
    add(
      MoveEffect.by(
        Vector2(0, -65),
        EffectController(duration: 1.1, curve: Curves.easeOutCubic),
      ),
    );

    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 1.1, curve: Curves.easeIn),
      ),
    );

    add(
      SequenceEffect([
        ScaleEffect.to(
          Vector2.all(1.4),
          EffectController(duration: 0.25, curve: Curves.easeOutQuad),
        ),
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.25, curve: Curves.easeInQuad),
        ),
      ]),
    );

    add(RemoveEffect(delay: 1.1));
  }

  @override
  void render(Canvas canvas) {
    // TextComponent / PositionComponent opacity handling with saveLayer for clean fade out
    if (opacity < 1) {
      canvas.saveLayer(size.toRect(), paint);
      _drawVector(canvas);
      canvas.restore();
    } else {
      _drawVector(canvas);
    }
    super.render(canvas);
  }

  void _drawVector(Canvas canvas) {
    canvas.save();
    // Translate origin to center of component for symmetrical drawing
    canvas.translate(size.x / 2, size.y / 2);

    Color glowColor;
    Color coreColor;
    Color strokeColor;

    if (iconType == 'defend' ||
        iconType == 'shield' ||
        iconType == 'armor_buff') {
      glowColor = Colors.cyanAccent;
      coreColor = const Color(0xFF0EA5E9); // Modern sky blue
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      final shieldPath = Path();
      shieldPath.moveTo(0, -14);
      shieldPath.lineTo(12, -14);
      shieldPath.quadraticBezierTo(14, 5, 0, 16);
      shieldPath.quadraticBezierTo(-14, 5, -12, -14);
      shieldPath.close();

      canvas.drawPath(shieldPath, glowPaint);
      canvas.drawPath(shieldPath, fillPaint);
      canvas.drawPath(shieldPath, strokePaint);
      // Center line vertical accent
      canvas.drawLine(const Offset(0, -14), const Offset(0, 16), strokePaint);
    } else if (iconType == 'poison' || iconType == 'debuff') {
      glowColor = const Color(0xFF10B981); // Emerald poison green
      coreColor = const Color(0xFF047857); // Deep emerald
      strokeColor = const Color(0xFF34D399); // Light mint

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      final dropPath = Path();
      dropPath.moveTo(0, -15);
      dropPath.cubicTo(8, -5, 13, 2, 13, 8);
      dropPath.arcToPoint(
        const Offset(-13, 8),
        radius: const Radius.circular(13),
        clockwise: true,
      );
      dropPath.cubicTo(-13, 2, -8, -5, 0, -15);
      dropPath.close();

      canvas.drawPath(dropPath, glowPaint);
      canvas.drawPath(dropPath, fillPaint);
      canvas.drawPath(dropPath, strokePaint);
    } else if (iconType == 'burn' || iconType == 'fire') {
      glowColor = Colors.deepOrangeAccent;
      coreColor = const Color(0xFFF97316); // Bright orange
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      final flamePath = Path();
      flamePath.moveTo(0, 15);
      flamePath.cubicTo(-10, 15, -15, 8, -10, -2);
      flamePath.cubicTo(-15, -6, -8, -15, 0, -17);
      flamePath.cubicTo(2, -10, 8, -6, 5, -2);
      flamePath.cubicTo(12, 0, 12, 10, 0, 15);
      flamePath.close();

      canvas.drawPath(flamePath, glowPaint);
      canvas.drawPath(flamePath, fillPaint);
      canvas.drawPath(flamePath, strokePaint);
    } else if (iconType == 'freeze' ||
        iconType == 'cold' ||
        iconType == 'ice') {
      glowColor = Colors.lightBlueAccent;
      coreColor = const Color(0xFF0284C7); // Sky blue
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      // Draw a central snowflake crystal
      canvas.drawCircle(Offset.zero, 4, glowPaint);
      canvas.drawCircle(Offset.zero, 4, fillPaint);
      canvas.drawCircle(Offset.zero, 4, strokePaint);

      // Draw 6 spokes
      for (int i = 0; i < 6; i++) {
        canvas.save();
        canvas.rotate(i * 3.14159 / 3);
        // Main spoke line
        canvas.drawLine(Offset.zero, const Offset(0, -16), glowPaint);
        canvas.drawLine(Offset.zero, const Offset(0, -16), strokePaint);
        // Little branches
        canvas.drawLine(const Offset(0, -10), const Offset(-5, -13), glowPaint);
        canvas.drawLine(
          const Offset(0, -10),
          const Offset(-5, -13),
          strokePaint,
        );
        canvas.drawLine(const Offset(0, -10), const Offset(5, -13), glowPaint);
        canvas.drawLine(
          const Offset(0, -10),
          const Offset(5, -13),
          strokePaint,
        );
        canvas.restore();
      }
    } else if (iconType == 'shock' || iconType == 'lightning') {
      glowColor = Colors.yellowAccent;
      coreColor = const Color(0xFFFACC15); // Electric gold yellow
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      final boltPath = Path();
      boltPath.moveTo(2, -18);
      boltPath.lineTo(-10, 0);
      boltPath.lineTo(-2, 0);
      boltPath.lineTo(-6, 18);
      boltPath.lineTo(8, -2);
      boltPath.lineTo(0, -2);
      boltPath.close();

      canvas.drawPath(boltPath, glowPaint);
      canvas.drawPath(boltPath, fillPaint);
      canvas.drawPath(boltPath, strokePaint);
    } else if (iconType == 'buff' || iconType == 'attack_buff') {
      // Crossed swords
      glowColor = Colors.orangeAccent;
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = strokeColor.withValues(alpha: opacity);

      final goldPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.amberAccent.withValues(alpha: opacity);

      // Sword 1 (bottom-left to top-right)
      canvas.drawLine(const Offset(-12, 12), const Offset(12, -12), glowPaint);
      canvas.drawLine(
        const Offset(-12, 12),
        const Offset(12, -12),
        strokePaint,
      );
      // Sword 1 guard
      canvas.drawLine(const Offset(-8, 2), const Offset(-2, 8), goldPaint);

      // Sword 2 (bottom-right to top-left)
      canvas.drawLine(const Offset(12, 12), const Offset(-12, -12), glowPaint);
      canvas.drawLine(
        const Offset(12, 12),
        const Offset(-12, -12),
        strokePaint,
      );
      // Sword 2 guard
      canvas.drawLine(const Offset(8, 2), const Offset(2, 8), goldPaint);
    } else {
      // General Sparkle Aura (4-pointed star)
      glowColor = Colors.amber;
      coreColor = const Color(0xFFF59E0B);
      strokeColor = Colors.white;

      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = glowColor.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = coreColor.withValues(alpha: opacity);

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = strokeColor.withValues(alpha: opacity);

      final starPath = Path();
      starPath.moveTo(0, -15);
      starPath.quadraticBezierTo(0, 0, 15, 0);
      starPath.quadraticBezierTo(0, 0, 0, 15);
      starPath.quadraticBezierTo(0, 0, -15, 0);
      starPath.quadraticBezierTo(0, 0, 0, -15);
      starPath.close();

      canvas.drawPath(starPath, glowPaint);
      canvas.drawPath(starPath, fillPaint);
      canvas.drawPath(starPath, strokePaint);
    }

    canvas.restore();
  }
}
