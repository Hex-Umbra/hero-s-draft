import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Sans ce fichier, le probleme §2.2 de la spec n est pas resolu : un dossier
/// de classe incomplet serait aussi silencieux qu une entree manquante l etait
/// quand la classe vivait eclatee dans quatre fichiers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  // `setUpAll` : `GameDataRegistry` ecrit un singleton statique dans son
  // constructeur, donc un seul registre par fichier de test.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  test('tout passiveTrait designe un passif existant', () {
    final known = registry.passives.map((p) => p.id).toSet();
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      final trait = hero.passiveTrait;
      if (trait == null) continue;
      if (!known.contains(trait)) {
        offenders.add('${hero.id} → passiveTrait "$trait" introuvable');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('toute carte de signature existe et appartient bien a sa classe', () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      for (final skillId in hero.skills) {
        final matches = registry.cards.where((c) => c.id == skillId);
        if (matches.isEmpty) {
          offenders.add('${hero.id} → carte "$skillId" introuvable');
          continue;
        }
        final card = matches.single;
        if (card.heroClass != hero.id) {
          offenders.add(
            '${hero.id} → carte "$skillId" rangee sous "${card.heroClass}"',
          );
        }
        if (!File('assets/data/classes/${hero.id}/cards/$skillId.json')
            .existsSync()) {
          offenders.add(
            '${hero.id} → carte "$skillId" absente du dossier de la classe',
          );
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque dossier de classe et d ennemi porte son image', () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      final expected = 'assets/data/classes/${hero.id}/icon.png';
      if (hero.iconPath != expected) {
        offenders.add('${hero.id} → iconPath vaut "${hero.iconPath}"');
      }
      if (!File(expected).existsSync()) {
        offenders.add('${hero.id} → $expected manquant');
      }
    }

    for (final enemy in registry.enemies) {
      final expected = 'assets/data/enemies/${enemy.id}/sprite.png';
      if (enemy.spritePath != expected) {
        offenders.add('${enemy.id} → spritePath vaut "${enemy.spritePath}"');
      }
      if (!File(expected).existsSync()) {
        offenders.add('${enemy.id} → $expected manquant');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque dossier de classe contient exactement ses cartes de signature', () {
    // Un dossier `cards/` qui porterait une carte orpheline — non listee dans
    // `skills` — serait chargee dans le pool de la classe sans que rien ne le
    // dise. P-42 y ajoutera un pool plus large ; ce test devra alors changer
    // de forme, pas disparaitre.
    for (final hero in registry.heroes) {
      final onDisk = Directory('assets/data/classes/${hero.id}/cards')
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      expect(onDisk, hero.skills.toSet(), reason: 'classe ${hero.id}');
    }
  });
}
