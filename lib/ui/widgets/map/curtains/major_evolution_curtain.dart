import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'curtain_step.dart';

/// Le rideau d'une évolution majeure (D80) : l'écran s'éteint autour d'un
/// médaillon doré, entouré d'un anneau comme l'icône d'une majeure. Un tournant
/// de la run : une entrée en plusieurs temps, puis des rayons qui tournent.
class MajorEvolutionCurtain extends StatefulWidget {
  final Color classColor;
  final String title;
  final String subtitle;
  final String action;

  const MajorEvolutionCurtain({
    super.key,
    required this.classColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  State<MajorEvolutionCurtain> createState() => _MajorEvolutionCurtainState();
}

class _MajorEvolutionCurtainState extends State<MajorEvolutionCurtain>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFFFD54F);

  /// Le nombre d'impulsions de l'invite par tour de [_rays].
  static const _pulsesPerTurn = 16;

  late final AnimationController _entrance;
  late final AnimationController _rays;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _rays = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _rays.dispose();
    super.dispose();
  }

  Widget _medallion(double size, double pop) {
    final classColor = widget.classColor;
    final hsl = HSLColor.fromColor(classColor);
    return Transform.scale(
      scale: pop,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              hsl.withLightness(hsl.lightness * 0.3).toColor(),
              const Color(0xFF12121C),
            ],
          ),
          border: Border.all(color: _gold, width: size * 0.035),
          boxShadow: [
            BoxShadow(
              color: _gold.withValues(alpha: 0.45),
              blurRadius: 28,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: classColor.withValues(alpha: 0.7),
              blurRadius: 80,
              spreadRadius: 18,
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(size * 0.07),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _gold.withValues(alpha: 0.45), width: 1.2),
          ),
          child: Icon(Icons.auto_awesome, size: size * 0.48, color: _gold),
        ),
      ),
    );
  }

  /// L'onde, unique, qui part du médaillon à son arrivée.
  Widget _wave(double size, double wave) {
    final extent = size * 5;
    return OverflowBox(
      maxWidth: extent,
      maxHeight: extent,
      child: Transform.scale(
        scale: 0.2 + 0.8 * wave,
        child: Container(
          width: extent,
          height: extent,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _gold.withValues(alpha: 1 - wave),
              width: 5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BoxConstraints box, double t, double turn) {
    final low = box.maxHeight < 420;
    final size = low ? 64.0 : 112.0;
    final fade = curtainStep(t, 0, 0.25);
    final wave = curtainStep(t, 0.12, 0.6, Curves.easeOutCubic);
    final titleIn = curtainStep(t, 0.32, 0.6);
    final rest = curtainStep(t, 0.5, 0.8);
    final rayExtent = math.max(box.maxWidth, box.maxHeight) * 1.5;
    final pulse =
        0.65 + 0.35 * (0.5 + 0.5 * math.sin(turn * _pulsesPerTurn * 2 * math.pi));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              OverflowBox(
                maxWidth: rayExtent,
                maxHeight: rayExtent,
                child: Opacity(
                  opacity: fade,
                  child: Transform.rotate(
                    angle: turn * 2 * math.pi,
                    child: CustomPaint(
                      size: Size.square(rayExtent),
                      painter: _RaysPainter(widget.classColor),
                    ),
                  ),
                ),
              ),
              if (wave > 0 && wave < 1) _wave(size, wave),
              _medallion(size, curtainStep(t, 0.12, 1, Curves.elasticOut)),
            ],
          ),
        ),
        SizedBox(height: low ? 12 : 30),
        Opacity(
          opacity: titleIn,
          child: Transform.scale(
            scale: 1.18 - 0.18 * titleIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: _gold,
                    fontSize: low ? 30 : 46,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: const [
                      Shadow(color: Color(0xFFFFA000), blurRadius: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: low ? 6 : 12),
        Opacity(
          opacity: rest,
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: low ? 15 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: low ? 10 : 30),
        Opacity(
          opacity: rest * pulse,
          child: Text(
            widget.action,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: Listenable.merge([_entrance, _rays]),
        builder: (context, _) {
          final t = _entrance.value;
          return Container(
            color: const Color(0xFF07070E).withValues(
              alpha: 0.94 * curtainStep(t, 0, 0.25),
            ),
            alignment: Alignment.center,
            child: _content(box, t, _rays.value),
          );
        },
      ),
    );
  }
}

class _RaysPainter extends CustomPainter {
  static const _rayCount = 12;
  static const _gold = _MajorEvolutionCurtainState._gold;

  final Color classColor;

  const _RaysPainter(this.classColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Color.lerp(_gold, classColor, 0.3)!.withValues(alpha: 0.34),
          classColor.withValues(alpha: 0.10),
          classColor.withValues(alpha: 0),
        ],
        const [0.0, 0.3, 0.6],
      );
    const halfWidth = math.pi / _rayCount * 0.32;
    for (var i = 0; i < _rayCount; i++) {
      final angle = i * 2 * math.pi / _rayCount;
      canvas.drawPath(
        Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + radius * math.cos(angle - halfWidth),
            center.dy + radius * math.sin(angle - halfWidth),
          )
          ..lineTo(
            center.dx + radius * math.cos(angle + halfWidth),
            center.dy + radius * math.sin(angle + halfWidth),
          )
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter oldDelegate) =>
      oldDelegate.classColor != classColor;
}
