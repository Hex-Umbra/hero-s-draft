import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/effect_line_texts.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategies.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/effect_kind.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/effect_style.dart';
import 'package:roguelike_card_game/ui/widgets/forge/rune_style.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/ui_card_helpers.dart';

/// Le type d'effet qu'un delta nomme, s'il en nomme un.
String? _effectOf(CardDelta delta) => switch (delta) {
      PercentBonusDelta(:final effect) => effect,
      AddEffectDelta(:final effect) => effect,
      FlatBonusDelta(:final effect) => effect,
      RemoveExhaustDelta() => null,
      ReduceCostDelta() => null,
      CritBonusDelta() => null,
      AddExhaustDelta() => null,
      ArmorPierceDelta() => null,
      LifestealPercentDelta() => null,
      SplashPercentDelta() => null,
      EchoChanceDelta() => null,
      RefundHpCostDelta() => null,
    };

/// Les sortes qu'une évolution vise (A39), lues sur ses deltas et sa cible.
List<String> _kindsOf(SignatureEvolutionData e) => [
      for (final delta in e.deltas)
        switch (delta) {
          FlatBonusDelta(:final effect, :final statusId) ||
          AddEffectDelta(:final effect, :final statusId) =>
            effect == 'apply_status' ? 'status:$statusId' : effect,
          CritBonusDelta() => EffectKind.crit,
          _ => null,
        },
      if (e.target != null) EffectKind.allEnemies,
    ].nonNulls.toList();

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

  // Garde de tete de fichier : sans elle, les tests suivants
  // bouclent sur `registry.heroes` et `registry.enemies` et passeraient a
  // vide si le bundle perdait la totalite de assets/data/classes/*/ ou
  // assets/data/enemies/*/ — une boucle for sur une liste vide ne produit
  // aucun coupable, donc `expect(offenders, isEmpty)` serait trivialement
  // vrai plus bas. Un fichier de garde doit se suffire a lui-meme : il ne
  // doit pas dependre de real_bundle_load_test.dart (qui verifie
  // hasLength(3) et hasLength(4)) pour detecter une perte totale.
  test('le registre contient au moins un heros et un ennemi', () {
    expect(registry.heroes, isNotEmpty);
    expect(registry.enemies, isNotEmpty);
  });

  test('chaque effectType de passif a sa strategie', () {
    final offenders = [
      for (final passive in registry.passives)
        if (!PassiveStrategies.byEffectType.containsKey(passive.effectType))
          '${passive.id} → effectType "${passive.effectType}" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Un type d'effet que nomme une rune et qu'aucune stratégie ne résout ne
  // ferait rien en jeu (spec P-43 E1, A13).
  test('chaque type d effet que nomme une rune a sa strategie', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final strategies = container.read(effectRegistryProvider);

    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final type in {
          ...?rune.eligibleEffects,
          ...rune.excludesEffects,
          for (final delta in rune.deltas) ?_effectOf(delta),
        })
          if (strategies.get(type) == null)
            '${rune.id} → type d effet "$type" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Un nom que les tables ne connaissent pas retomberait en silence sur du
  // gris et une icone d'aide (spec P-43 E2, A19).
  test('chaque icone et chaque couleur de rune livree est connue des tables',
      () {
    final offenders = [
      for (final rune in registry.forgeUpgrades) ...[
        if (!runeIcons.containsKey(rune.icon)) '${rune.id} → icone "${rune.icon}"',
        if (!runeColors.containsKey(rune.color))
          '${rune.id} → couleur "${rune.color}"',
      ],
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Les icones d effet (spec §3.7, A35, A39) : un nom que les tables ne
  // connaissent pas retomberait en silence sur du gris et une icone d aide.
  test(
      'chaque icone et chaque couleur d evolution livree et d effect_icons.json '
      'est connue d effectIcons et effectColors', () {
    final entries = [
      for (final k in registry.effectIcons.kinds) (k, registry.effectIcons.entryOf(k)!),
    ];
    final offenders = [
      for (final s in registry.signatures)
        for (final e in s.evolutions) ...[
          if (!effectIcons.containsKey(e.icon)) '${s.id}/${e.id} → icone "${e.icon}"',
          if (!effectColors.containsKey(e.color))
            '${s.id}/${e.id} → couleur "${e.color}"',
        ],
      for (final (kind, entry) in entries) ...[
        if (!effectIcons.containsKey(entry.icon)) '$kind → icone "${entry.icon}"',
        if (!effectColors.containsKey(entry.color))
          '$kind → couleur "${entry.color}"',
      ],
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
      'chaque entree d effectIcons et d effectColors sert au moins une '
      'evolution ou une sorte', () {
    final entries = [
      for (final k in registry.effectIcons.kinds) registry.effectIcons.entryOf(k)!,
    ];
    final usedIcons = {
      for (final s in registry.signatures) ...s.evolutions.map((e) => e.icon),
      ...entries.map((e) => e.icon),
    };
    final usedColors = {
      for (final s in registry.signatures) ...s.evolutions.map((e) => e.color),
      ...entries.map((e) => e.color),
    };

    final offenders = [
      for (final name in effectIcons.keys)
        if (!usedIcons.contains(name)) 'effectIcons → "$name" ne sert a rien',
      for (final name in effectColors.keys)
        if (!usedColors.contains(name)) 'effectColors → "$name" ne sert a rien',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
      'deux evolutions d une meme signature de meme icone ne sont jamais deux '
      'mineures ni deux majeures (A37)', () {
    final offenders = [
      for (final s in registry.signatures)
        for (final tier in EvolutionTier.values)
          for (final icon in {
            for (final e in s.evolutions.where((e) => e.tier == tier)) e.icon,
          })
            if (s.evolutions.where((e) => e.tier == tier && e.icon == icon).length >
                1)
              '${s.id} → deux ${tier.name} d icone "$icon"',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
      'chaque sorte que produit une signature livree ou une evolution de son '
      'pool figure au document ; chaque status:<id> du document est cree par '
      'createStatus', () {
    final documented = registry.effectIcons.kinds.toSet();
    final offenders = [
      for (final s in registry.signatures)
        for (final line in SignatureInstance(
          s,
          evolutions: [for (final e in s.evolutions) '${e.id}:1'],
        ).effectLines)
          if (!documented.contains(line.kind)) '${s.id} → sorte "${line.kind}"',
      for (final kind in documented)
        if (kind.startsWith('status:') &&
            EffectResolver.createStatus(kind.substring(7), 1, 1) == null)
          '$kind → createStatus ne cree rien',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Une sorte sans phrase montrerait son icone seule dans la liste de
  // l appui long (A41).
  test(
      'chaque sorte que produit une signature livree ou une evolution de son '
      'pool a sa phrase (A41)', () {
    final fr = lookupAppLocalizations(const Locale('fr'));
    final en = lookupAppLocalizations(const Locale('en'));
    final offenders = [
      for (final s in registry.signatures)
        for (final line in SignatureInstance(
          s,
          evolutions: [for (final e in s.evolutions) '${e.id}:1'],
        ).effectLines)
          for (final l10n in [fr, en])
            if (EffectLineTexts.phrase(l10n, line) == null)
              '${s.id} → sorte "${line.kind}" sans phrase (${l10n.localeName})',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test(
      'une evolution sans cooldown qui vise une seule sorte porte son icon et '
      'sa color (A39)', () {
    final checkedIds = <String>[];
    final offenders = <String>[];
    for (final s in registry.signatures) {
      for (final e in s.evolutions) {
        final kinds = _kindsOf(e);
        if (e.cooldown != 0 || kinds.length != 1) continue;
        checkedIds.add(e.id);
        final entry = registry.effectIcons.entryOf(kinds.single);
        if (entry == null) {
          offenders.add('${s.id}/${e.id} → sorte "${kinds.single}" absente');
        } else if (entry.icon != e.icon || entry.color != e.color) {
          offenders.add('${s.id}/${e.id} → ${e.icon}/${e.color} au lieu de '
              '${entry.icon}/${entry.color}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
    expect(checkedIds, hasLength(32));
    expect(checkedIds, containsAll(['zeal', 'sentence']));
  });

  test(
      'chaque effet qu ajoute une evolution a sa strategie, et chaque statut '
      'qu elle pose est fabrique par createStatus', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final strategies = container.read(effectRegistryProvider);

    final offenders = <String>[];
    for (final s in registry.signatures) {
      for (final e in s.evolutions) {
        for (final delta in e.deltas) {
          final (effect, statusId) = switch (delta) {
            AddEffectDelta(:final effect, :final statusId) => (effect, statusId),
            FlatBonusDelta(:final effect, :final statusId) => (effect, statusId),
            _ => (null, null),
          };
          if (effect == null) continue;
          if (strategies.get(effect) == null) {
            offenders.add('${s.id}/${e.id} → effet "$effect" sans strategie');
          }
          if (statusId != null &&
              EffectResolver.createStatus(statusId, 1, 1) == null) {
            offenders.add('${s.id}/${e.id} → statut "$statusId" non fabrique');
          }
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // P-6 (a) : la table du document est alignee sur les faces des cartes.
  test(
      'les faces des cartes et le document donnent la meme icone et la meme '
      'couleur a chaque sorte commune', () {
    final effects = [
      for (final type in ['damage', 'armor', 'heal', 'gain_mana', 'draw'])
        CardEffect(type: type, value: 1),
      for (final id in [
        'might',
        'might_regen',
        'armor_regen',
        'poison',
        'weakness',
        'vulnerable',
        'burn',
        'freeze',
        'shock',
      ])
        CardEffect(type: 'apply_status', value: 1, statusId: id, duration: 1),
    ];

    final offenders = <String>[];
    for (final effect in effects) {
      final kind = EffectKind.of(effect);
      final table = effectVisualsOf(registry.effectIcons, kind);
      final cardFace = getEffectVisuals(effect);
      final flameFace = CardTextRenderer.getEffectVisuals(effect);
      if (cardFace.icon != table.icon || cardFace.color != table.color) {
        offenders.add('$kind → la face de carte differe du document');
      }
      if (flameFace.icon != table.icon || flameFace.color != table.color) {
        offenders.add('$kind → la face Flame differe du document');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque id d excludesRunes designe une rune livree', () {
    final known = registry.forgeUpgrades.map((r) => r.id).toSet();
    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final id in rune.excludesRunes)
          if (!known.contains(id)) '${rune.id} → excludesRunes "$id" introuvable',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque statut que pose une rune est fabrique par createStatus', () {
    final statuses = {
      for (final rune in registry.forgeUpgrades)
        for (final delta in rune.deltas)
          if (delta case AddEffectDelta(:final statusId?)) statusId,
    };
    expect(statuses, isNotEmpty, reason: 'aucune rune ne pose de statut');

    final offenders = [
      for (final statusId in statuses)
        if (EffectResolver.createStatus(statusId, 1, 1) == null)
          'statut "$statusId" que createStatus ne fabrique pas',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque status:<id> de feeds est fabrique par createStatus', () {
    final offenders = [
      for (final passive in registry.passives)
        for (final entry in passive.feeds)
          if (entry.startsWith('status:') &&
              EffectResolver.createStatus(entry.substring(7), 1, 1) == null)
            '${passive.id} → "$entry" que createStatus ne fabrique pas',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('les feeds livres sont ceux de spec §3.3', () {
    expect({for (final p in registry.passives) p.id: p.feeds}, {
      'regen_armor': ['armor', 'status:armor_regen', 'scale:armor', 'cost:armor'],
      'fervor': ['armor', 'attack'],
      'blessing': ['armor', 'status:armor_regen', 'status:weakness', 'heal'],
      'rage': [
        'cost:hp',
        'scale:missingHp',
        'armor',
        'status:might',
        'status:might_regen',
      ],
      'bloodthirst': ['attack'],
      'frenzy': ['scale:targetMissingHp', 'scale:enemiesAlive'],
      'mana_flux': ['skill'],
      'channeling': ['power'],
      'mage_mark': ['damage', 'status:vulnerable', 'scale:targetStatus'],
    });
  });

  test('toute classe declaree par un passif existe', () {
    final known = registry.heroes.map((h) => h.id).toSet();
    final offenders = <String>[];

    for (final passive in registry.passives) {
      for (final heroId in passive.classes ?? const <String>[]) {
        if (!known.contains(heroId)) {
          offenders.add('${passive.id} → classe "$heroId" introuvable');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Une classe sans passif disponible démarrerait sa run sans passif : le jeu
  // le permet (`passive_absent_test`), mais aucune classe livrée n'est dans ce
  // cas (spec P-49, §4.2).
  test('chaque classe a au moins un passif disponible', () {
    final offenders = [
      for (final hero in registry.heroes)
        if (availablePassivesFor(hero, registry).isEmpty) hero.id,
    ];

    expect(
      offenders,
      isEmpty,
      reason: 'classes sans passif : ${offenders.join(', ')}',
    );
  });

  // O5 (spec P-42 T1 et P-44 lot 1, §4.8) : la disponibilité se lit sur le
  // registre. Aucun passif n'est nommé : la tranche qui livre un lot n'a
  // rien à réécrire ici.
  test('un passif est disponible pour sa classe si et seulement si il a un lot',
      () {
    final withLot = registry.cards.map((c) => c.passive).nonNulls.toSet();
    final offenders = <String>[];
    for (final hero in registry.heroes) {
      final available =
          availablePassivesFor(hero, registry).map((p) => p.id).toSet();
      for (final passive in registry.passives) {
        if (!(passive.classes?.contains(hero.id) ?? true)) continue;
        if (available.contains(passive.id) != withLot.contains(passive.id)) {
          offenders.add('${hero.id} → ${passive.id}');
        }
      }
    }
    expect(withLot, isNotEmpty);
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Le nom du dossier est l'id du passif (spec §3.2) : un dossier mal nommé
  // ouvrirait un passif qui n'existe pas, et n'en ouvrirait aucun.
  test('chaque dossier de cards/ est l id d un passif', () {
    final passiveIds = registry.passives.map((p) => p.id).toSet();
    final folders = [
      for (final entity in Directory('assets/data/cards').listSync())
        if (entity is Directory)
          entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ];
    expect(folders, isNotEmpty);
    expect(folders.where((f) => !passiveIds.contains(f)), isEmpty);
  });

  test('chaque id de skills est une signature de sa classe, rangee sous elle',
      () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      for (final skillId in hero.skills) {
        final matches = registry.signatures.where((s) => s.id == skillId);
        if (matches.isEmpty) {
          offenders.add('${hero.id} → signature "$skillId" introuvable');
          continue;
        }
        final signature = matches.single;
        if (signature.heroClass != hero.id) {
          offenders.add(
            '${hero.id} → signature "$skillId" rangee sous '
            '"${signature.heroClass}"',
          );
        }
        if (!File('assets/data/classes/${hero.id}/skills/$skillId.json')
            .existsSync()) {
          offenders.add(
            '${hero.id} → signature "$skillId" absente du dossier skills',
          );
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Une signature n entre jamais dans le deck (spec P-43 E4, §3.1) : un id
  // partage avec une carte laisserait un pool, un `masterDeck` ou une source
  // de statut `card:<id>` designer l une pour l autre.
  test('aucun id de signature n est un id de carte', () {
    expect(registry.signatures, isNotEmpty);

    final signatureIds = registry.signatures.map((s) => s.id).toSet();
    final cardIds = registry.cards.map((c) => c.id).toSet();

    expect(signatureIds.intersection(cardIds), isEmpty);
  });

  test('chaque dossier de classe et d ennemi porte son image', () {
    final offenders = <String>[];

    for (final hero in registry.heroes) {
      final expected = 'assets/data/classes/${hero.id}/${hero.id}.png';
      if (hero.classCard != expected) {
        offenders.add('${hero.id} → classCard vaut "${hero.classCard}"');
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

  test('chaque dossier skills contient exactement les signatures de sa classe',
      () {
    // Un dossier `skills/` qui porterait une signature orpheline — non listee
    // dans `skills` — serait chargee sans que rien ne le dise.
    for (final hero in registry.heroes) {
      final onDisk = Directory('assets/data/classes/${hero.id}/skills')
          .listSync()
          .whereType<File>()
          // Windows laisse trainer Thumbs.db/desktop.ini dans les dossiers
          // consultes par l explorateur ; ni l un ni l autre n est couvert
          // par .gitignore. Sans ce filtre, un fichier parasite local ferait
          // rougir ce test pour une raison etrangere a l integrite.
          .where((f) => f.path.endsWith('.json'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toSet();
      expect(onDisk, hero.skills.toSet(), reason: 'classe ${hero.id}');
    }
  });
}
