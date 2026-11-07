import 'package:flutter/material.dart';

/// Le bandeau de lumière en travers de l'écran, à la couleur de la classe, en
/// fondu sur les côtés : il s'ouvre du centre vers les bords selon [open].
class CurtainBand extends StatelessWidget {
  final Color classColor;

  /// L'ouverture, de 0 (fermé) à 1 (ouvert).
  final double open;
  final Widget child;

  const CurtainBand({
    super.key,
    required this.classColor,
    required this.open,
    required this.child,
  });

  Widget _hairline(Color color, double edge) => Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color,
              color,
              color.withValues(alpha: 0),
            ],
            stops: [0, edge * 1.6, 1 - edge * 1.6, 1],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(classColor);
    final deep = hsl.withLightness(hsl.lightness * 0.36).toColor();
    final light = hsl.withLightness(0.76).toColor();

    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 600;
        final edge = narrow ? 0.03 : 0.16;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(open, 1, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hairline(light, edge),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 20 : 40,
                  vertical: box.maxHeight < 420 ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      deep.withValues(alpha: 0),
                      deep.withValues(alpha: 0.97),
                      deep.withValues(alpha: 0.97),
                      deep.withValues(alpha: 0),
                    ],
                    stops: [0, edge, 1 - edge, 1],
                  ),
                ),
                child: child,
              ),
              _hairline(light, edge),
            ],
          ),
        );
      },
    );
  }
}
