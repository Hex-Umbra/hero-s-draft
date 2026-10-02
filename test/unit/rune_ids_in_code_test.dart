import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les runes sont des fichiers : aucun id de rune livrée n'est écrit en dur
/// dans `lib/`, et le multiplicateur de rareté n'a plus qu'un endroit,
/// l'applicateur (spec P-43 E1, A1, A4, §8). Sur le modèle de
/// `stat_gain_single_passage_test.dart`.
void main() {
  final runeIds = [
    for (final file in Directory('assets/data/forge_upgrades').listSync())
      if (file is File && file.path.endsWith('.json'))
        file.uri.pathSegments.last.replaceAll('.json', ''),
  ];

  /// Les endroits de `lib/` où [pattern] apparaît, `chemin:ligne : extrait`.
  List<String> offendersOf(RegExp pattern) {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final source = entity.readAsStringSync();
      for (final match in pattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('$path:$line : ${match.group(0)}');
      }
    }
    return offenders;
  }

  test('aucun id de rune livree n est ecrit en litteral dans lib', () {
    expect(runeIds, hasLength(11), reason: 'les onze runes livrees');
    final offenders =
        offendersOf(RegExp('''['"](${runeIds.join('|')})['"]'''));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le multiplicateur de rarete n est plus calcule hors de l applicateur',
      () {
    final offenders = offendersOf(RegExp(r'\brarityMultiplier\b'));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
