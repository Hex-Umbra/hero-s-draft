import 'dart:math';

/// Un `Random` dont chaque tirage est écrit d'avance (spec P-43 E3, §8 :
/// « sur un `Random` dont le premier tirage est connu »). `nextInt(max)` rend
/// la valeur suivante du script, ramenée sous `max` ; au bout du script, il
/// reprend au début.
///
/// Un script `[24]` fait passer le jet de la seconde carte d'élite
/// (24 < 25), `[25]` le fait manquer ; ramenée sous la taille d'un pool, la
/// même valeur désigne aussi la carte tirée.
class ScriptedRandom implements Random {
  ScriptedRandom(this.script);

  final List<int> script;
  var _next = 0;

  @override
  int nextInt(int max) => script[_next++ % script.length] % max;

  @override
  double nextDouble() =>
      throw UnsupportedError('ScriptedRandom ne tire que des entiers');

  @override
  bool nextBool() =>
      throw UnsupportedError('ScriptedRandom ne tire que des entiers');
}
