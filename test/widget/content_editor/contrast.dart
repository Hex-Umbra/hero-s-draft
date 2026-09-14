import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Le rapport de contraste WCAG entre deux couleurs opaques, de 1:1 a 21:1.
///
/// Tire de la seule luminance du framework, jamais de `readableOn` : un test
/// qui jugerait le texte choisi avec la fonction qui le choisit passerait quoi
/// qu'elle decide.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}
