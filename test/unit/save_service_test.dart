import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/services/save_service.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';

void main() {
  group('SaveService', () {
    const smite = SignatureData(
      id: 'smite',
      heroClass: 'paladin',
      nameEn: 'Smite',
      nameFr: 'Châtiment',
      descriptionEn: 'Deal 6 damage.',
      descriptionFr: 'Inflige 6 dégâts.',
      cost: 1,
      cooldown: 2,
      type: CardType.attack,
      effects: [CardEffect(type: 'damage', value: 6)],
    );
    const holyShield = SignatureData(
      id: 'holy_shield',
      heroClass: 'paladin',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacré',
      descriptionEn: 'Gain 8 Block.',
      descriptionFr: "Donne 8 d'Armure.",
      cost: 1,
      cooldown: 2,
      type: CardType.skill,
      target: CardTarget.self,
      effects: [CardEffect(type: 'armor', value: 8)],
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // startNewRun's default hero passive ('regen_armor') round-trips through
      // RunState.fromJsonWithReport, which looks it up via
      // PassiveData.getById — that requires a populated GameDataRegistry,
      // exactly like test/unit/run_state_persistence_test.dart already sets
      // up for the same reason.
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [
          PassiveData(
            id: 'regen_armor',
            nameFr: "Régénération d'Armure",
            nameEn: 'Armor Regeneration',
            trigger: RelicTrigger.endOfTurn,
            effectType: 'gain_armor',
            value: 2,
          ),
        ],
        relics: const [],
        forgeUpgrades: const [],
      );
    });

    test('hasSave is false before any save exists', () async {
      expect(await SaveService.hasSave(), isFalse);
    });

    test('save then load round-trips run/inventory state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const dummyHero = HeroData(
        id: 'paladin',
        nameEn: 'Paladin',
        nameFr: 'Paladin',
        descriptionEn: 'A holy knight',
        descriptionFr: 'Un saint chevalier',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        luck: 0,
        mastery: 0,
      );
      container.read(runProvider.notifier).startNewRun(dummyHero);
      container.read(inventoryProvider.notifier).gainGold(37);

      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final result = await SaveService.load(freshContainer.read);

      expect(result.success, isTrue);
      expect(result.missingItems, isEmpty);
      expect(freshContainer.read(runProvider).heroClassId, 'paladin');
      expect(freshContainer.read(inventoryProvider).gold, 87); // 50 starting + 37
    });

    test('a save still carrying a "skills" key loads without error', () async {
      // Saves written before the skill system was removed carry a 'skills'
      // key. Nothing writes it any more and nothing must read it — but an
      // existing save must keep loading rather than being wiped by the
      // catch-all in SaveService.load. This is the only behavioural guarantee
      // of the removal, so it is pinned here.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const dummyHero = HeroData(
        id: 'paladin',
        nameEn: 'Paladin',
        nameFr: 'Paladin',
        descriptionEn: 'A holy knight',
        descriptionFr: 'Un saint chevalier',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      container.read(runProvider.notifier).startNewRun(dummyHero);
      await SaveService.save(container.read);

      final prefs = await SharedPreferences.getInstance();
      final payload =
          jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
      payload['skills'] = {'skill1Cooldown': 2, 'skill2Cooldown': 0};
      await prefs.setString('run_save', jsonEncode(payload));

      final freshContainer = ProviderContainer();
      addTearDown(freshContainer.dispose);
      final result = await SaveService.load(freshContainer.read);

      expect(result.success, isTrue);
      expect(freshContainer.read(runProvider).heroClassId, 'paladin');
      expect(await SaveService.hasSave(), isTrue);
    });

    test('une run d E4 sauvee puis rechargee : le deck sans signature, les '
        'signatures relues de la classe, rien d ecrit', () async {
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'holy_shield'],
      );
      // Par `fromJson`, sans `category` : ce test traverse la Task 7 intact.
      final strike = CardData.fromJson(
          {'id': 'strike', 'cost': 1, 'type': 'attack', 'effects': <dynamic>[]});
      final registry = GameDataRegistry(
        enemies: const [],
        heroes: const [paladin],
        cards: [strike],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
        signatures: const [smite, holyShield],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(runProvider.notifier)
          .startNewRun(paladin, null, paladin.getSignatures(registry));
      container.read(deckProvider.notifier).initializeStarterDeck(
          [for (var i = 0; i < 5; i++) CardInstance(data: strike)]);
      expect(
        container.read(runProvider).signatures.map((s) => s.data.id),
        ['smite', 'holy_shield'],
      );
      await SaveService.save(container.read);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('run_save')!;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      expect((payload['run'] as Map<String, dynamic>).containsKey('signatures'),
          isFalse);
      expect(raw, isNot(contains('holy_shield')),
          reason: 'aucune signature ecrite, ni dans la run ni dans le deck');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(result.missingItems, isEmpty);
      final deck = fresh.read(deckProvider).masterDeck;
      expect(deck, hasLength(5));
      expect(deck.map((c) => c.data.id), everyElement('strike'));
      expect(
        fresh.read(runProvider).signatures.map((s) => s.data.id),
        paladin.skills,
      );
    });

    test('une classe inconnue du registre reprend sans signature', () async {
      // Le registre du setUp ne connait aucune classe : les signatures
      // donnees au depart ne survivent pas a la reprise, preuve qu elles ne
      // sont pas lues dans la sauvegarde.
      const dummyHero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(runProvider.notifier)
          .startNewRun(dummyHero, null, const [smite]);
      await SaveService.save(container.read);

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).signatures, isEmpty);
    });

    test('un id de skills absent du registre fait echouer la reprise et '
        'efface la sauvegarde', () async {
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'absente'],
      );
      GameDataRegistry(
        enemies: const [],
        heroes: const [paladin],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
        signatures: const [smite],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(paladin);
      await SaveService.save(container.read);

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('clear removes the save', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      await SaveService.clear(container.read);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('load returns a failed result and clears storage on corrupted JSON', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save', 'not valid json {{{');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('load refuses a save written by a newer build and keeps it', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'run_save',
        '{"schemaVersion": 999, "run": {}, "deck": {}, "inventory": {}}',
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(result.savedByNewerBuild, isTrue);
      expect(await SaveService.hasSave(), isTrue);
    });

    test('load returns a failed result and clears storage when schemaVersion is missing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save', '{"run": {}, "deck": {}, "inventory": {}}');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final result = await SaveService.load(container.read);

      expect(result.success, isFalse);
      expect(result.savedByNewerBuild, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });

    test('save writes under run_save and retires the legacy run_save_v1', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', '{"schemaVersion": 1}');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.save(container.read);

      expect(prefs.containsKey('run_save'), isTrue);
      expect(prefs.containsKey('run_save_v1'), isFalse);
    });

    test('load falls back to a legacy run_save_v1 save', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      await SaveService.save(container.read);

      // Remet la sauvegarde sous l'ancienne clé, là où la laisse un build
      // publié jusqu'à 0.5.1.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', prefs.getString('run_save')!);
      await prefs.remove('run_save');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).heroClassId, 'paladin');
    });

    test('clear also removes a legacy run_save_v1 save', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('run_save_v1', '{"schemaVersion": 1}');
      expect(await SaveService.hasSave(), isTrue);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await SaveService.clear(container.read);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('load migrates a legacy v1 save stored under run_save_v1', () async {
      const hero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      await SaveService.save(container.read);

      // Réécrit la sauvegarde telle que l'écrivaient tous les builds jusqu'à
      // 0.5.1 : version 1, clé `attaque`, sous l'ancienne clé de stockage. La
      // valeur d'`attaque` n'est plus relue depuis le lot B de P-41 (spec,
      // §7.5) : seul compte ici que la chaîne de migration ouvre la partie.
      final prefs = await SharedPreferences.getInstance();
      final save =
          jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
      final run = save['run'] as Map<String, dynamic>;
      final heroStats = run['heroStats'] as Map<String, dynamic>;
      heroStats['attaque'] = heroStats.remove('might');
      heroStats.remove('mightTargets');
      save['schemaVersion'] = 1;
      await prefs.setString('run_save_v1', jsonEncode(save));
      await prefs.remove('run_save');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).heroClassId, 'paladin');
    });

    // Les evolutions de signature, sauvegardees sous `signatureEvolutions`
    // (spec P-42 T1 et P-44 lot 1, §8 — tache a risque).
    group('les evolutions de signature (spec §8)', () {
      const zeal = SignatureEvolutionData(id: 'zeal', tier: EvolutionTier.minor);
      const aegis =
          SignatureEvolutionData(id: 'aegis', tier: EvolutionTier.minor);
      const sentence =
          SignatureEvolutionData(id: 'sentence', tier: EvolutionTier.major);
      // Seule `haste` declare l exclusion : la relecture la lit dans les deux
      // sens (Q7).
      const haste = SignatureEvolutionData(
        id: 'haste',
        tier: EvolutionTier.major,
        cooldown: -1,
        excludes: ['devastation'],
      );
      const devastation = SignatureEvolutionData(
        id: 'devastation',
        tier: EvolutionTier.major,
        cooldown: 1,
      );
      const ward = SignatureEvolutionData(id: 'ward', tier: EvolutionTier.minor);
      const evolvingSmite = SignatureData(
        id: 'smite',
        heroClass: 'paladin',
        cost: 1,
        cooldown: 2,
        type: CardType.attack,
        effects: [CardEffect(type: 'damage', value: 6)],
        evolutions: [zeal, aegis, sentence, haste, devastation],
      );
      const evolvingShield = SignatureData(
        id: 'holy_shield',
        heroClass: 'paladin',
        cost: 1,
        cooldown: 2,
        type: CardType.skill,
        target: CardTarget.self,
        effects: [CardEffect(type: 'armor', value: 8)],
        evolutions: [ward],
      );
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'holy_shield'],
      );

      setUp(() {
        GameDataRegistry(
          enemies: const [],
          heroes: const [paladin],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
          signatures: const [evolvingSmite, evolvingShield],
        );
      });

      /// Une run du Paladin dont chaque signature porte [evolutions], sauvee.
      Future<void> saveRun(Map<String, List<String>> evolutions) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final run = container.read(runProvider.notifier);
        run.startNewRun(paladin, null, const [evolvingSmite, evolvingShield]);
        run.updateState(run.currentState.copyWith(signatures: [
          for (final s in run.currentState.signatures)
            SignatureInstance(
              s.data,
              evolutions: evolutions[s.data.id] ?? const [],
            ),
        ]));
        await SaveService.save(container.read);
      }

      /// La run telle que la sauvegarde l ecrit.
      Future<Map<String, dynamic>> savedRun() async {
        final prefs = await SharedPreferences.getInstance();
        final payload =
            jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
        return payload['run'] as Map<String, dynamic>;
      }

      /// Remplace `signatureEvolutions` dans la sauvegarde ; nul, la retire.
      Future<void> rewrite(Object? value) async {
        final prefs = await SharedPreferences.getInstance();
        final payload =
            jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
        final run = payload['run'] as Map<String, dynamic>;
        if (value == null) {
          run.remove('signatureEvolutions');
        } else {
          run['signatureEvolutions'] = value;
        }
        await prefs.setString('run_save', jsonEncode(payload));
      }

      /// La reprise : le resultat, et les evolutions de chaque signature, dans
      /// l ordre de la classe.
      Future<(SaveLoadResult, List<List<String>>)> reload() async {
        final fresh = ProviderContainer();
        addTearDown(fresh.dispose);
        final result = await SaveService.load(fresh.read);
        return (
          result,
          [for (final s in fresh.read(runProvider).signatures) s.evolutions],
        );
      }

      test('aller-retour exact : chaque liste telle quelle, dans l ordre de '
          'la premiere prise', () async {
        await saveRun({
          'smite': ['zeal:2', 'sentence:1', 'aegis:1'],
          'holy_shield': ['ward:1'],
        });
        expect((await savedRun())['signatureEvolutions'], {
          'smite': ['zeal:2', 'sentence:1', 'aegis:1'],
          'holy_shield': ['ward:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions, [
          ['zeal:2', 'sentence:1', 'aegis:1'],
          ['ward:1'],
        ]);
      });

      test('une signature sans evolution n ecrit aucune cle', () async {
        await saveRun({
          'smite': ['zeal:1'],
        });
        expect((await savedRun())['signatureEvolutions'], {
          'smite': ['zeal:1'],
        });

        final (_, evolutions) = await reload();
        expect(evolutions, [
          ['zeal:1'],
          <String>[],
        ]);
      });

      test('une sauvegarde sans la cle, ou d une autre forme, reprend sans '
          'evolution', () async {
        for (final value in <Object?>[
          null,
          'smite',
          ['zeal:1'],
          {'smite': 'zeal:1'},
        ]) {
          await saveRun({
            'smite': ['zeal:1'],
          });
          await rewrite(value);

          final (result, evolutions) = await reload();
          expect(result.success, isTrue, reason: '$value');
          expect(result.missingItems, isEmpty, reason: '$value');
          expect(evolutions, [<String>[], <String>[]], reason: '$value');
        }
      });

      test('un id absent du pool est retire et signale, une fois', () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1', 'ghost:1', 'ghost:2'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(evolutions.first, ['zeal:1']);
        expect(result.missingItems, const [
          MissingSaveItem(
            id: 'ghost',
            nameFr: 'ghost',
            nameEn: 'ghost',
            category: 'signatureEvolution',
          ),
        ]);
      });

      test('une reference mal formee ou de niveau nul est ignoree, sans '
          'rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': [
            'zeal',
            'zeal:x',
            'zeal:0',
            'zeal:-1',
            'zeal:1:2',
            3,
            null,
            'aegis:1',
          ],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['aegis:1']);
      });

      test('les references d un meme id se reunissent a la place de la '
          'premiere, niveaux additionnes', () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1', 'aegis:1', 'zeal:2'],
        });

        final (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['zeal:3', 'aegis:1']);
      });

      test('une majeure est ramenee au niveau 1, sans rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': ['sentence:2', 'zeal:1', 'sentence:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['sentence:1', 'zeal:1']);
      });

      test('deux majeures qui s excluent : la premiere arrivee est gardee, '
          'dans un sens comme dans l autre, sans rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': ['haste:1', 'zeal:1', 'devastation:1'],
        });
        var (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['haste:1', 'zeal:1']);

        // `devastation` ne declare rien : c est l exclusion de `haste` qui
        // l ecarte, lue dans l autre sens.
        await rewrite({
          'smite': ['devastation:1', 'haste:1'],
        });
        (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['devastation:1']);
      });

      test('la cle d une signature que la classe ne porte pas est ignoree',
          () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1'],
          'reckless_strike': ['brutality:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions, [
          ['zeal:1'],
          <String>[],
        ]);
      });
    });
  });
}
