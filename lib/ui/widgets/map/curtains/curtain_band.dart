import 'package:flutter/material.dart';

/// Le bandeau de lumière en travers de l'écran, à la couleur de la classe : il
/// s'ouvre du centre vers les bords selon [open]. En fondu court sur les deux
/// côtés, ou, avec [longFade], de plus en plus plein des bords vers le centre.
class CurtainBand extends StatelessWidget {
  /// Le plateau plein du centre, avec [longFade] : sans lui, la pointe du
  /// dégradé se verrait comme une ligne verticale.
  static const _longFadeStops = [0.0, 0.4, 0.6, 1.0];

  /// La part de l'opacité gardée aux bords sur téléphone, avec [longFade] : le
  /// texte y occupe toute la largeur et doit rester lisible.
  static const _longFadePhoneEdge = 0.6;

  /// La largeur sous laquelle le bandeau occupe tout l'écran.
  static const _phoneWidth = 600.0;

  final Color classColor;

  /// L'ouverture, de 0 (fermé) à 1 (ouvert).
  final double open;
  final bool longFade;
  final Widget child;

  const CurtainBand({
    super.key,
    required this.classColor,
    required this.open,
    this.longFade = false,
    required this.child,
  });

  /// Le dégradé du bandeau, de [color] à l'opacité [alpha] au plus plein.
  LinearGradient _gradient(
    Color color,
    double alpha,
    double edge, {
    required bool narrow,
  }) {
    final outer = longFade && narrow ? alpha * _longFadePhoneEdge : 0.0;
    return LinearGradient(
      colors: [
        color.withValues(alpha: outer),
        color.withValues(alpha: alpha),
        color.withValues(alpha: alpha),
        color.withValues(alpha: outer),
      ],
      stops: longFade ? _longFadeStops : [0, edge, 1 - edge, 1],
    );
  }

  Widget _hairline(Color color, double edge, {required bool narrow}) =>
      Container(
        height: 1.5,
        decoration: BoxDecoration(
          gradient: _gradient(color, 1, edge * 1.6, narrow: narrow),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(classColor);
    final deep = hsl.withLightness(hsl.lightness * 0.36).toColor();
    final light = hsl.withLightness(0.76).toColor();

    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < _phoneWidth;
        final edge = narrow ? 0.03 : 0.16;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(open, 1, 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hairline(light, edge, narrow: narrow),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 20 : 40,
                  vertical: box.maxHeight < 420 ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  gradient: _gradient(deep, 0.97, edge, narrow: narrow),
                ),
                child: child,
              ),
              _hairline(light, edge, narrow: narrow),
            ],
          ),
        );
      },
    );
  }
}
