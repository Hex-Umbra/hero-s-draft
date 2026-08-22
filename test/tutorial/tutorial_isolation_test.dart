import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le tutoriel est autonome vis-à-vis de l'état du jeu : un seul fichier du
/// dossier a le droit de toucher Riverpod, et seulement pour lire des
/// données immuables. Voir ADR-081 et `_rules/08-00`.
void main() {
  test('un seul fichier de lib/tutorial/ importe flutter_riverpod', () {
    final offenders = <String>[];

    for (final entity in Directory('lib/tutorial').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalized = entity.path.replaceAll(r'\', '/');
      if (normalized.endsWith('lib/tutorial/tutorial_loader.dart')) continue;
      if (entity.readAsStringSync().contains('flutter_riverpod')) {
        offenders.add(normalized);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Seul tutorial_loader.dart peut importer Riverpod. '
          'Fichiers fautifs : ${offenders.join(", ")}',
    );
  });

  test('aucun provider d\'etat n\'est reference dans lib/tutorial/', () {
    const forbidden = [
      'runProvider',
      'deckProvider',
      'combatProvider',
      'inventoryProvider',
      'skillProvider',
      'rewardProvider',
      'shopProvider',
      'eventProvider',
      'checkpointProvider',
      'GameDataRegistry.instance',
    ];
    final offenders = <String>[];

    for (final entity in Directory('lib/tutorial').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final content = entity.readAsStringSync();
      for (final symbol in forbidden) {
        if (content.contains(symbol)) {
          offenders.add('${entity.path.replaceAll(r'\', '/')} → $symbol');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
