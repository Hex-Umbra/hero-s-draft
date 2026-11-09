import 'package:flutter/material.dart';

import 'curtain_band.dart';
import 'curtain_step.dart';

/// Le rideau d'une évolution mineure (D80) : un bandeau en travers de l'écran,
/// à la couleur de la classe. Un petit pas : la carte reste visible, et il
/// s'ouvre sans rebond puis ne bouge plus.
class MinorEvolutionCurtain extends StatefulWidget {
  final Color classColor;
  final String title;
  final String subtitle;
  final String action;

  const MinorEvolutionCurtain({
    super.key,
    required this.classColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  State<MinorEvolutionCurtain> createState() => _MinorEvolutionCurtainState();
}

class _MinorEvolutionCurtainState extends State<MinorEvolutionCurtain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(widget.classColor);
    final light = hsl.withLightness(0.76).toColor();

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, _) {
        final t = _entrance.value;
        final open = curtainStep(t, 0, 0.7, Curves.easeOutCubic);
        return Container(
          color: Colors.black.withValues(alpha: 0.5 * open),
          alignment: Alignment.center,
          child: CurtainBand(
            classColor: widget.classColor,
            open: open,
            child: Opacity(
              opacity: curtainStep(t, 0.4, 1),
              child: _content(light),
            ),
          ),
        );
      },
    );
  }

  Widget _content(Color light) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 18,
        children: [
          Icon(Icons.auto_awesome, size: 38, color: light),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.action,
                  style: TextStyle(
                    color: light,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
