import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les ids d'entités deviendront des noms de fichiers au lot 3 de la
/// réorganisation des données. Le poste de dev est insensible à la casse,
/// la CI ne l'est pas : une divergence passerait en local et casserait en CI.
void main() {
  test('tous les ids d entites sont en snake_case ASCII minuscule', () {
    final pattern = RegExp(r'^[a-z0-9_]+$');
    final offenders = <String>[];

    const catalogues = [
      'cards.json',
      'hero_cards.json',
      'relics.json',
      'events.json',
      'enemies.json',
      'heroes.json',
      'passives.json',
      'forge_upgrades.json',
    ];

    for (final name in catalogues) {
      final raw = File('assets/data/$name').readAsStringSync();
      for (final entry in jsonDecode(raw) as List) {
        final id = (entry as Map<String, dynamic>)['id'] as String;
        if (!pattern.hasMatch(id)) offenders.add('$name → $id');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
