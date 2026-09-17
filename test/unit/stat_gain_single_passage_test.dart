import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Aucune ligne de `lib/` n'ajoute à l'armure, au mana ou à une puissance par
/// une addition écrite à la main : tout gain passe par `StatGains.apply`
/// (spec P-41, §4.1). Un gain écrit ailleurs échapperait aux règles de classe
/// que le lot B de P-41 y fera entrer.
///
/// Le motif reconnaît l'addition écrite en ligne, dans les deux sens et sur
/// plusieurs lignes. Il ne voit pas une addition calculée dans une variable
/// locale, ou enveloppée dans un appel (`max(0, s.armure + g)`) : pour
/// celles-là, la revue reste le filet. Il ne voit donc pas non plus la seule
/// exception voulue par la spec : la remontée du mana courant qui suit une
/// hausse de `maxMana`, dans `applyHeroStatModifier`.
final _additiveGains = [
  // `armure: s.armure + g`, éventuellement entre parenthèses ou sur deux lignes.
  RegExp(r'\b(armure|currentMana|might|skillPower|alterationPower)\s*:\s*\(?\s*[\w.\[\]!?]*\b\1\b\s*\+'),
  // `armure: g + s.armure`.
  RegExp(r'\b(armure|currentMana|might|skillPower|alterationPower)\s*:[^,;{}]*?\+\s*[\w.\[\]!?]*\b\1\b'),
];

bool _isAdditiveGain(String source) =>
    _additiveGains.any((pattern) => pattern.hasMatch(source));

void main() {
  group('le motif du garde-fou', () {
    const gains = [
      ('une addition en ligne', 'copyWith(armure: stats.armure + gain)'),
      ('des operandes inverses', 'copyWith(armure: gain + stats.armure)'),
      ('un retour a la ligne', 'copyWith(\n  armure:\n      stats.armure + gain,\n)'),
      ('une addition entre parentheses', 'copyWith(currentMana: (stats.currentMana + gain).clamp(0, 9))'),
      ('un chemin indexe', 'copyWith(might: enemies[i].stats.might + 1)'),
    ];
    for (final (name, source) in gains) {
      test('reconnait $name', () => expect(_isAdditiveGain(source), isTrue));
    }

    const others = [
      ('une remise a zero', 'copyWith(armure: 0, currentPv: newPv)'),
      ('une restauration', 'copyWith(currentMana: stats.maxMana)'),
      ('une serialisation', "{'armure': armure, 'currentMana': currentMana}"),
      ('une depense', 'copyWith(currentMana: stats.currentMana - mana)'),
      ('une addition a une autre stat', 'copyWith(currentMana: stats.maxMana + bonus)'),
    ];
    for (final (name, source) in others) {
      test('ignore $name', () => expect(_isAdditiveGain(source), isFalse));
    }
  });

  test('tous les gains passent par StatGains.apply', () {
    final offenders = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('lib/game/systems/stat_gains.dart')) continue;
      final source = entity.readAsStringSync();
      for (final pattern in _additiveGains) {
        for (final match in pattern.allMatches(source)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          offenders.add('$path:$line');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
