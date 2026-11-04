import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/signature_evolution_rules.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le tirage, le choix et l'attente des évolutions de signature (spec vague 5,
/// partie 3) : les règles pures sur le pool livré de *Frappe Téméraire*, puis
/// l'entrée dans `RunController` sur les vraies classes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  SignatureInstance strike(List<String> evolutions) => SignatureInstance(
        registry.signatures.singleWhere((s) => s.id == 'reckless_strike'),
        evolutions: evolutions,
      );

  List<String> ids(List<SignatureEvolutionData> offer) =>
      [for (final e in offer) e.id];

  Iterable<List<SignatureEvolutionData>> offers(SignatureInstance s) sync* {
    for (var seed = 0; seed < 20; seed++) {
      yield SignatureEvolutionRules.offer(s, Random(seed));
    }
  }

  group('le tirage', () {
    test('au palier mineur : trois mineures, sans remise', () {
      for (final offer in offers(strike([]))) {
        expect(offer, hasLength(3));
        expect(ids(offer).toSet(), hasLength(3));
        expect(offer.every((e) => e.tier == EvolutionTier.minor), isTrue);
      }
    });

    test('au palier majeur : les majeures non prises, trois au plus', () {
      for (final offer in offers(strike(['brutality:1']))) {
        expect(offer, hasLength(3));
        expect(ids(offer).toSet(), hasLength(3));
        expect(offer.every((e) => e.tier == EvolutionTier.major), isTrue);
      }
    });

    test('une majeure exclue n est pas offerte, dans les deux sens', () {
      for (final offer
          in offers(strike(['brutality:1', 'haste:1', 'instinct:1']))) {
        expect(ids(offer), isNot(contains('devastation')));
      }
      for (final offer
          in offers(strike(['brutality:1', 'devastation:1', 'instinct:1']))) {
        expect(ids(offer), isNot(contains('haste')));
      }
    });

    test('sous trois majeures eligibles, des mineures completent jusqu a trois',
        () {
      for (final offer
          in offers(strike(['brutality:1', 'instinct:1', 'haste:1']))) {
        expect(offer, hasLength(3));
        expect(ids(offer), containsAll(['cleave', 'composure']));
        expect(offer.where((e) => e.tier == EvolutionTier.minor), hasLength(1));
      }
    });

    test('majeures epuisees : trois mineures au palier majeur (Q6, repli)', () {
      for (final offer
          in offers(strike(['haste:1', 'cleave:1', 'composure:1']))) {
        expect(offer, hasLength(3));
        expect(offer.every((e) => e.tier == EvolutionTier.minor), isTrue);
      }
    });
  });

  group('l entree dans RunController', () {
    late ProviderContainer container;
    late RunController run;

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
    });
    tearDown(() => container.dispose());

    /// Une run de la classe livrée [classId], le héros au niveau [level], les
    /// évolutions de la signature [signatureId] posées.
    void start(
      String classId,
      int level, {
      String? signatureId,
      List<String> evolutions = const [],
    }) {
      final hero = registry.heroes.singleWhere((h) => h.id == classId);
      run.startNewRun(hero, null, hero.getSignatures(registry));
      final state = run.currentState;
      run.updateState(state.copyWith(
        heroStats: state.heroStats.copyWith(level: level),
        signatures: [
          for (final s in state.signatures)
            s.data.id == signatureId
                ? SignatureInstance(s.data, evolutions: evolutions)
                : s,
        ],
      ));
    }

    List<String> smiteTaken() => run.currentState.signatures
        .singleWhere((s) => s.data.id == 'smite')
        .evolutions;

    List<List<String>> taken() =>
        [for (final s in run.currentState.signatures) s.evolutions];

    test(
        'chooseSignatureEvolution refuse sans rien ecrire : signature hors run, '
        'rien n attend, hors du pool', () {
      start('paladin', 5);
      final before = taken();

      expect(run.chooseSignatureEvolution('reckless_strike', 'zeal'), isFalse);
      expect(run.chooseSignatureEvolution('smite', 'nonexistent'), isFalse);
      run.updateState(run.currentState.copyWith(
        heroStats: run.currentState.heroStats.copyWith(level: 4),
      ));
      expect(run.chooseSignatureEvolution('smite', 'zeal'), isFalse);

      expect(taken(), before);
      expect(container.read(checkpointProvider), 0);
    });

    test('chooseSignatureEvolution refuse une evolution non admissible au palier',
        () {
      start('paladin', 5);
      expect(run.chooseSignatureEvolution('smite', 'haste'), isFalse);

      start('paladin', 10, signatureId: 'smite', evolutions: ['zeal:1']);
      expect(run.chooseSignatureEvolution('smite', 'aegis'), isFalse);

      start('berserker', 20,
          signatureId: 'reckless_strike',
          evolutions: ['brutality:1', 'haste:1', 'instinct:1']);
      final before = taken();
      expect(
          run.chooseSignatureEvolution('reckless_strike', 'devastation'),
          isFalse);

      expect(taken(), before);
      expect(container.read(checkpointProvider), 0);
    });

    test('une mineure deja prise monte d un niveau a sa place ; une autre entre '
        'a la fin', () {
      final smite = registry.signatures.singleWhere((s) => s.id == 'smite');
      expect(
        SignatureEvolutionRules.withChoice(
            ['zeal:1', 'sentence:1'], smite.evolutions.firstWhere((e) => e.id == 'zeal')),
        ['zeal:2', 'sentence:1'],
      );

      start('paladin', 15, signatureId: 'smite', evolutions: ['zeal:1', 'sentence:1']);
      expect(run.chooseSignatureEvolution('smite', 'zeal'), isTrue);
      expect(smiteTaken(), ['zeal:2', 'sentence:1']);

      start('paladin', 15, signatureId: 'smite', evolutions: ['zeal:1', 'haste:1']);
      expect(run.chooseSignatureEvolution('smite', 'aegis'), isTrue);
      expect(smiteTaken(), ['zeal:1', 'haste:1', 'aegis:1']);
    });

    test('chaque choix accepte sauve : le checkpoint monte d un', () {
      start('paladin', 5);
      expect(container.read(checkpointProvider), 0);
      expect(run.chooseSignatureEvolution('smite', 'zeal'), isTrue);
      expect(container.read(checkpointProvider), 1);
    });

    test(
        'nextPendingEvolution : Chatiment puis Bouclier Sacre au niveau 5 ; sur '
        'un saut de 4 a 10, les deux mineures puis les deux majeures', () {
      String? next() => run.currentState.nextPendingEvolution?.data.id;

      // L'ordre livré de `HeroData.skills` du Paladin : Bouclier Sacre, puis
      // Châtiment.
      start('paladin', 5);
      expect(next(), 'holy_shield');
      run.chooseSignatureEvolution('holy_shield', 'ward');
      expect(next(), 'smite');
      run.chooseSignatureEvolution('smite', 'zeal');
      expect(next(), isNull);

      start('paladin', 10);
      expect(next(), 'holy_shield');
      run.chooseSignatureEvolution('holy_shield', 'ward');
      expect(next(), 'smite');
      run.chooseSignatureEvolution('smite', 'zeal');
      expect(next(), 'holy_shield');
      run.chooseSignatureEvolution('holy_shield', 'haste');
      expect(next(), 'smite');
      run.chooseSignatureEvolution('smite', 'haste');
      expect(next(), isNull);
    });

    test('hasPendingChoice : un draft ou une evolution en attente', () {
      start('paladin', 4);
      expect(run.currentState.hasPendingChoice, isFalse);
      run.updateState(run.currentState.copyWith(pendingDrafts: 1));
      expect(run.currentState.hasPendingChoice, isTrue);

      start('paladin', 5);
      expect(run.currentState.hasPendingChoice, isTrue);
    });
  });
}
