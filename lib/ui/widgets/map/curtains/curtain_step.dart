import 'package:flutter/animation.dart';

/// L'avancée, de 0 à 1, d'une étape d'animation d'un rideau qui court de
/// [begin] à [end] sur l'entrée [t] du rideau.
double curtainStep(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.easeOut,
]) =>
    Interval(begin, end, curve: curve).transform(t);
