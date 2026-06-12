import 'dart:math' show cos, sin;
import 'package:flutter/material.dart';

class PolychromaticBorder extends StatefulWidget {
  final Widget child;
  final Color rarityColor;
  final bool isSelected;
  final bool isUnique;
  final int upgradeCount;

  const PolychromaticBorder({
    super.key,
    required this.child,
    required this.rarityColor,
    required this.isSelected,
    this.isUnique = false,
    this.upgradeCount = 0,
  });

  @override
  State<PolychromaticBorder> createState() => _PolychromaticBorderState();
}

class _PolychromaticBorderState extends State<PolychromaticBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovered = true;
        });
        _controller.repeat();
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
        _controller.stop();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _PolychromaticBorderPainter(
              animationValue: _controller.value,
              rarityColor: widget.rarityColor,
              isSelected: widget.isSelected,
              isHovered: _isHovered,
              isUnique: widget.isUnique,
              upgradeCount: widget.upgradeCount,
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _PolychromaticBorderPainter extends CustomPainter {
  final double animationValue;
  final Color rarityColor;
  final bool isSelected;
  final bool isHovered;
  final bool isUnique;
  final int upgradeCount;

  _PolychromaticBorderPainter({
    required this.animationValue,
    required this.rarityColor,
    required this.isSelected,
    required this.isHovered,
    this.isUnique = false,
    this.upgradeCount = 0,
  });

  List<Color> _getRarityShineColors(Color baseColor) {
    // Rareté Unique → arc-en-ciel complet basé sur l'upgradeCount
    if (isUnique) {
      final pool = [
        baseColor,
        Colors.white70,
        Colors.greenAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
        Colors.orangeAccent,
        Colors.red,
        Colors.yellow,
        Colors.cyan,
        Colors.pink,
      ];
      final count = (upgradeCount + 1).clamp(1, pool.length);
      final colors = pool.sublist(0, count);
      return [...colors, colors.first];
    }
    final hsv = HSVColor.fromColor(baseColor);
    if (hsv.saturation < 0.15 || hsv.value < 0.15) {
      return [
        baseColor,
        Colors.white,
        const Color(0xFFE0E0E0),
        const Color(0xFFBDBDBD),
        Colors.white,
        baseColor,
      ];
    }
    final hue = hsv.hue;
    if (hue >= 340 || hue < 20) {
      return [
        baseColor,
        Colors.orangeAccent,
        Colors.red,
        Colors.pinkAccent,
        baseColor,
      ];
    } else if (hue >= 20 && hue < 50) {
      return [
        baseColor,
        Colors.amber,
        Colors.yellow,
        Colors.deepOrange,
        baseColor,
      ];
    } else if (hue >= 50 && hue < 70) {
      return [
        baseColor,
        Colors.lightGreenAccent,
        Colors.yellowAccent,
        Colors.amberAccent,
        baseColor,
      ];
    } else if (hue >= 70 && hue < 165) {
      return [
        baseColor,
        Colors.limeAccent,
        Colors.tealAccent,
        Colors.green,
        baseColor,
      ];
    } else if (hue >= 165 && hue < 200) {
      return [
        baseColor,
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.tealAccent,
        baseColor,
      ];
    } else if (hue >= 200 && hue < 260) {
      return [
        baseColor,
        Colors.cyan,
        Colors.indigoAccent,
        Colors.blue,
        baseColor,
      ];
    } else {
      return [
        baseColor,
        Colors.pinkAccent,
        Colors.deepPurpleAccent,
        Colors.purple,
        baseColor,
      ];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    final paint = Paint()
      ..style = PaintingStyle.stroke;

    if (isHovered) {
      paint.strokeWidth = 3.0;
      final colors = _getRarityShineColors(rarityColor);
      final angle = animationValue * 2 * 3.141592653589793;
      final cosVal = cos(angle);
      final sinVal = sin(angle);
      paint.shader = LinearGradient(
        begin: Alignment(cosVal, sinVal),
        end: Alignment(-cosVal, -sinVal),
        colors: colors,
      ).createShader(rect);
    } else {
      paint.strokeWidth = isSelected ? 2.5 : 1.5;
      paint.color = isSelected
          ? Colors.white.withValues(alpha: 0.8)
          : rarityColor.withValues(alpha: 0.5);
    }

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PolychromaticBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.rarityColor != rarityColor ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isUnique != isUnique ||
        oldDelegate.upgradeCount != upgradeCount ||
        oldDelegate.isHovered != isHovered;
  }
}
