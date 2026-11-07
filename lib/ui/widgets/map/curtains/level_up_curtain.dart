import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'curtain_band.dart';
import 'curtain_step.dart';

/// Le rideau d'un niveau gagné (D81) : un bandeau à la couleur de la classe,
/// sur des flèches placées au hasard qui montent et passent derrière lui. Il
/// revient à chaque niveau, son entrée reste courte.
class LevelUpCurtain extends StatefulWidget {
  final Color classColor;
  final String title;
  final String subtitle;
  final String action;

  const LevelUpCurtain({
    super.key,
    required this.classColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  State<LevelUpCurtain> createState() => _LevelUpCurtainState();
}

class _LevelUpCurtainState extends State<LevelUpCurtain>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;

  /// Le tour des flèches, qui montent sans fin.
  late final AnimationController _drift;

  /// Tiré à chaque ouverture : c'est lui qui place les flèches.
  final int _seed = math.Random().nextInt(1 << 31);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    super.dispose();
  }

  Widget _content(double t, {required bool low}) {
    final rest = curtainStep(t, 0.55, 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: curtainStep(t, 0.25, 1, Curves.easeOutBack),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.title,
              style: TextStyle(
                color: Colors.amberAccent,
                fontSize: low ? 30 : 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                shadows: const [
                  Shadow(color: Color(0xFFFFA000), blurRadius: 14),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: low ? 4 : 8),
        Opacity(
          opacity: rest,
          child: Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: low ? 6 : 12),
        Opacity(
          opacity: rest,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.action,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
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
        animation: Listenable.merge([_entrance, _drift]),
        builder: (context, _) {
          final t = _entrance.value;
          final open = curtainStep(t, 0, 0.55, Curves.easeOutCubic);
          return Container(
            color: Colors.black.withValues(alpha: 0.68 * open),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ArrowsPainter(
                    classColor: widget.classColor,
                    drift: _drift.value,
                    fade: open,
                    seed: _seed,
                  ),
                ),
                Center(
                  child: CurtainBand(
                    classColor: widget.classColor,
                    open: open,
                    longFade: true,
                    child: _content(t, low: box.maxHeight < 420),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Les flèches qui montent partout dans le rideau.
class _ArrowsPainter extends CustomPainter {
  /// La surface du rideau, en pixels, pour une flèche.
  static const _areaPerArrow = 30000.0;

  static const _gold = Color(0xFFFFD54F);

  final Color classColor;
  final double drift;
  final double fade;
  final int seed;

  const _ArrowsPainter({
    required this.classColor,
    required this.drift,
    required this.fade,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final light = HSLColor.fromColor(classColor).withLightness(0.76).toColor();
    final random = math.Random(seed);
    final count = (w * h / _areaPerArrow).clamp(12, 34).round();
    for (var i = 0; i < count; i++) {
      // Une par tranche de largeur : le hasard, sans tas d'un seul côté.
      final x = (i + random.nextDouble()) / count * w;
      final phase = random.nextDouble();
      final speed = 1 + random.nextInt(2);
      final length = 16 + random.nextDouble() * 26;
      final warmth = random.nextDouble();

      final progress = (phase + drift * speed) % 1.0;
      final y = h + 40 - (h + 80) * progress;
      final paint = Paint()
        ..color = Color.lerp(light, _gold, warmth)!.withValues(
          alpha: math.sin(progress * math.pi) * 0.85 * fade,
        )
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 1.5 + length * 0.07;
      final tip = Offset(x, y - length / 2);
      final head = length * 0.34;
      canvas.drawLine(Offset(x, y + length / 2), tip, paint);
      canvas.drawPath(
        Path()
          ..moveTo(x - head, tip.dy + head)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(x + head, tip.dy + head),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArrowsPainter oldDelegate) => true;
}
