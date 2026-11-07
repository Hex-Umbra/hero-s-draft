import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'curtain_step.dart';

/// Le rideau d'un niveau gagné (D80), à la couleur de la classe : une pyramide
/// transparente et des flèches au hasard sur grand écran, une colonne de lumière
/// et des chevrons sur téléphone. Il revient à chaque niveau, son entrée reste
/// courte.
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
  /// La largeur sous laquelle le rideau passe en colonne, la même que l'écran
  /// d'évolution pour ses onglets.
  static const _phoneWidth = 600.0;

  /// Le nombre de pulsations des chevrons par tour de [_drift].
  static const _chevronPulsesPerTurn = 6;

  late final AnimationController _entrance;

  /// Le tour des flèches et des étincelles, qui montent sans fin.
  late final AnimationController _drift;

  /// Tiré à chaque ouverture : c'est lui qui place les flèches et les
  /// étincelles.
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

  Widget _chevrons(double size) => SizedBox(
        height: size * 1.3,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(0, (1 - i) * size * 0.36),
                child: Opacity(
                  opacity: 0.35 +
                      0.65 *
                          (0.5 +
                              0.5 *
                                  math.sin(
                                    (_drift.value * _chevronPulsesPerTurn -
                                            i * 0.28) *
                                        2 *
                                        math.pi,
                                  )),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: size,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
          ],
        ),
      );

  Widget _content(double t, {required bool low, required bool withChevrons}) {
    final rest = curtainStep(t, 0.55, 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withChevrons) ...[
          Opacity(
            opacity: curtainStep(t, 0.2, 0.6),
            child: _chevrons(low ? 30 : 52),
          ),
          SizedBox(height: low ? 4 : 12),
        ],
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
        SizedBox(height: low ? 4 : 10),
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
        SizedBox(height: low ? 8 : 18),
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
      builder: (context, box) {
        final phone = box.maxWidth < _phoneWidth;
        return AnimatedBuilder(
          animation: Listenable.merge([_entrance, _drift]),
          builder: (context, _) {
            final t = _entrance.value;
            final rise = curtainStep(t, 0, 0.55, Curves.easeOutCubic);
            return Container(
              color: Colors.black.withValues(alpha: 0.68 * rise),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (phone)
                    Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(1, rise, 1),
                      child: CustomPaint(
                        painter: _ColumnPainter(
                          classColor: widget.classColor,
                          drift: _drift.value,
                          seed: _seed,
                        ),
                      ),
                    )
                  else
                    CustomPaint(
                      painter: _PyramidPainter(
                        classColor: widget.classColor,
                        drift: _drift.value,
                        rise: rise,
                        seed: _seed,
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _content(
                        t,
                        low: box.maxHeight < 420,
                        withChevrons: phone,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// La pyramide transparente, à deux faces, et les flèches qui montent partout
/// dans le rideau.
class _PyramidPainter extends CustomPainter {
  /// La surface du rideau, en pixels, pour une flèche.
  static const _areaPerArrow = 30000.0;

  /// La moitié de la zone du texte, où les flèches s'effacent.
  static const _textHalfWidth = 210.0;
  static const _textHalfHeight = 92.0;

  static const _gold = Color(0xFFFFD54F);

  final Color classColor;
  final double drift;
  final double rise;
  final int seed;

  const _PyramidPainter({
    required this.classColor,
    required this.drift,
    required this.rise,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hsl = HSLColor.fromColor(classColor);
    final light = hsl.withLightness(0.76).toColor();
    _paintPyramid(canvas, size, hsl, light);
    _paintArrows(canvas, size, light);
  }

  void _paintPyramid(Canvas canvas, Size size, HSLColor hsl, Color light) {
    final w = size.width;
    final h = size.height;
    final baseWidth = math.min(w, math.max(h * 1.35, w * 0.7));
    final top = Offset(w / 2, h - h * 0.94 * rise);
    final left = Offset((w - baseWidth) / 2, h);
    final right = Offset((w + baseWidth) / 2, h);
    final middle = Offset(w / 2, h);

    Paint faceFill(Color color, double bottom, double upper) => Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h),
        top,
        [color.withValues(alpha: bottom), color.withValues(alpha: upper)],
      );
    Path face(Offset corner) => Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(corner.dx, corner.dy)
      ..lineTo(middle.dx, middle.dy)
      ..close();
    canvas.drawPath(
      face(left),
      faceFill(hsl.withLightness(hsl.lightness * 0.8).toColor(), 0.55, 0.22),
    );
    canvas.drawPath(
      face(right),
      faceFill(hsl.withLightness(hsl.lightness * 0.45).toColor(), 0.62, 0.26),
    );

    Paint edge(double bottom, double upper, double width) => Paint()
      ..strokeWidth = width
      ..shader = ui.Gradient.linear(
        Offset(0, h),
        top,
        [light.withValues(alpha: bottom), light.withValues(alpha: upper)],
      );
    canvas.drawLine(top, left, edge(0.85, 0.5, 1.5));
    canvas.drawLine(top, right, edge(0.85, 0.5, 1.5));
    canvas.drawLine(top, middle, edge(0.28, 0.12, 1));
  }

  void _paintArrows(Canvas canvas, Size size, Color light) {
    final w = size.width;
    final h = size.height;
    final random = math.Random(seed);
    final count = (w * h / _areaPerArrow).clamp(12, 34).round();
    final textHalfWidth = math.min(w * 0.46, _textHalfWidth);
    for (var i = 0; i < count; i++) {
      // Une par tranche de largeur : le hasard, sans tas d'un seul côté.
      final x = (i + random.nextDouble()) / count * w;
      final phase = random.nextDouble();
      final speed = 1 + random.nextInt(2);
      final length = 16 + random.nextDouble() * 26;
      final warmth = random.nextDouble();

      final progress = (phase + drift * speed) % 1.0;
      final y = h + 40 - (h + 80) * progress;
      final inText = math.max(
        (x - w / 2).abs() / textHalfWidth,
        (y - h / 2).abs() / _textHalfHeight,
      );
      final clear = ((inText - 0.8) / 0.3).clamp(0.0, 1.0);
      final alpha = math.sin(progress * math.pi) * 0.85 * clear * rise;
      if (alpha <= 0.01) continue;

      final paint = Paint()
        ..color = Color.lerp(light, _gold, warmth)!.withValues(alpha: alpha)
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
  bool shouldRepaint(_PyramidPainter oldDelegate) => true;
}

/// La colonne de lumière, en fondu sur les côtés et vers le haut, et les
/// étincelles qui y montent.
class _ColumnPainter extends CustomPainter {
  static const _sparkCount = 26;
  static const _gold = Color(0xFFFFD54F);

  final Color classColor;
  final double drift;
  final int seed;

  const _ColumnPainter({
    required this.classColor,
    required this.drift,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final hsl = HSLColor.fromColor(classColor);
    final deep = hsl.withLightness(hsl.lightness * 0.36).toColor();
    final core = hsl.withLightness(hsl.lightness * 0.62).toColor();
    final light = hsl.withLightness(0.76).toColor();
    final body = Offset.zero & size;

    canvas.saveLayer(body, Paint());
    canvas.drawRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          [
            deep.withValues(alpha: 0),
            deep,
            core,
            deep,
            deep.withValues(alpha: 0),
          ],
          const [0, 0.05, 0.5, 0.95, 1],
        ),
    );
    canvas.drawRect(
      body,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = ui.Gradient.linear(
          Offset(0, size.height),
          Offset.zero,
          [Colors.white, Colors.white, Colors.white.withValues(alpha: 0)],
          const [0.0, 0.66, 0.98],
        ),
    );
    canvas.restore();

    canvas.drawRect(
      body,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height),
          size.width * 0.48,
          [light.withValues(alpha: 0.4), light.withValues(alpha: 0)],
        ),
    );

    final random = math.Random(seed);
    final sparkColor = Color.lerp(light, _gold, 0.5)!;
    for (var i = 0; i < _sparkCount; i++) {
      final x = random.nextDouble() * size.width;
      final phase = random.nextDouble();
      final speed = 1 + random.nextInt(2);
      final radius = 1.2 + random.nextDouble() * 1.8;
      final progress = (phase + drift * speed) % 1.0;
      canvas.drawCircle(
        Offset(x, size.height * (1 - progress)),
        radius,
        Paint()
          ..color = sparkColor.withValues(
            alpha: math.sin(progress * math.pi) * 0.75,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_ColumnPainter oldDelegate) => true;
}
