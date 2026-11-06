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

/// Le choix et l'attente des évolutions de signature (spec P-42 T1 et P-44
/// lot 1, partie 3 ; D78) : les règles pures sur le pool livré de *Frappe
/// Téméraire*, puis l'entrée dans `RunController` sur les vraies classes.
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

  const minors = ['brutality', 'instinct', 'shatter'];

  group('ce que le palier admet : tout, sans tirage (D78)', () {
    test('au palier mineur : toutes les mineures', () {
      expect(ids(SignatureEvolutionRules.admissible(strike([]))), minors);
    });

    test('au palier majeur : les quatre majeures, aucune mineure', () {
      expect(
        ids(SignatureEvolutionRules.admissible(strike(['brutality:1']))),
        ['haste', 'devastation', 'cleave', 'composure'],
      );
    });

    test('une majeure prise ne revient pas', () {
      expect(
        ids(SignatureEvolutionRules.admissible(
            strike(['brutality:1', 'cleave:1', 'instinct:1']))),
        ['haste', 'devastation', 'composure'],
      );
    });

    test('une majeure exclue n est pas admise, dans les deux sens', () {
      expect(
        ids(SignatureEvolutionRules.admissible(
            strike(['brutality:1', 'haste:1', 'instinct:1']))),
        isNot(contains('devastation')),
      );
      expect(
        ids(SignatureEvolutionRules.admissible(
            strike(['brutality:1', 'devastation:1', 'instinct:1']))),
        isNot(contains('haste')),
      );
    });

    test('sous trois majeures eligibles, toutes les mineures s ajoutent (Q6)',
        () {
      expect(
        ids(SignatureEvolutionRules.admissible(
            strike(['brutality:1', 'instinct:1', 'haste:1']))),
        ['cleave', 'composure', ...minors],
      );
    });

    test('majeures epuisees : les mineures seules au palier majeur (Q6, repli)',
        () {
      expect(
        ids(SignatureEvolutionRules.admissible(
            strike(['haste:1', 'cleave:1', 'composure:1']))),
        minors,
      );
    });
  });

  group('le tableau range tout le pool (D78)', () {
    test('au palier mineur, les majeures viennent au palier suivant', () {
      final board = SignatureEvolutionRules.board(strike([]));
      expect(ids(board.choices), minors);
      expect(
        ids(board.upcoming),
        ['haste', 'devastation', 'cleave', 'composure'],
      );
      expect(board.upcomingHeroLevel, 10);
      expect(board.takenMajors, isEmpty);
      expect(board.excluded, isEmpty);
    });

    test('au palier majeur, les mineures viennent au palier suivant', () {
      final board = SignatureEvolutionRules.board(strike(['brutality:1']));
      expect(
        ids(board.choices),
        ['haste', 'devastation', 'cleave', 'composure'],
      );
      expect(ids(board.upcoming), minors);
      expect(board.upcomingHeroLevel, 15);
    });

    test('une majeure prise se range a part, jamais parmi celles a venir', () {
      final board = SignatureEvolutionRules.board(
          strike(['brutality:1', 'cleave:1', 'instinct:1']));
      expect(ids(board.takenMajors), ['cleave']);
      expect(ids(board.choices), isNot(contains('cleave')));
      expect(ids(board.upcoming), minors);
      expect(board.upcomingHeroLevel, 25);
    });

    test('une majeure exclue dit qui l exclut, dans les deux sens', () {
      final byHaste = SignatureEvolutionRules.board(
          strike(['brutality:1', 'haste:1', 'instinct:1']));
      expect([for (final (e, by) in byHaste.excluded) (e.id, by.id)],
          [('devastation', 'haste')]);
      expect(ids(byHaste.upcoming), isEmpty);

      final byDevastation = SignatureEvolutionRules.board(
          strike(['brutality:1', 'devastation:1']));
      expect([for (final (e, by) in byDevastation.excluded) (e.id, by.id)],
          [('haste', 'devastation')]);
      expect(ids(byDevastation.upcoming), ['cleave', 'composure']);
    });

    test('chaque evolution du pool est rangee une fois, et une seule', () {
      for (final evolutions in [
        <String>[],
        ['brutality:1'],
        ['brutality:1', 'haste:1'],
        ['brutality:1', 'haste:1', 'instinct:1'],
        ['haste:1', 'cleave:1', 'composure:1'],
        ['haste:1', 'cleave:1', 'composure:1', 'brutality:1'],
      ]) {
        final s = strike(evolutions);
        final board = SignatureEvolutionRules.board(s);
        final all = [
          ...ids(board.choices),
          ...ids(board.upcoming),
          ...ids(board.takenMajors),
          for (final (e, _) in board.excluded) e.id,
        ];
        expect(all, hasLength(s.data.evolutions.length), reason: '$evolutions');
        expect(all.toSet(), {for (final e in s.data.evolutions) e.id},
            reason: '$evolutions');
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

    test('chacune des quatre majeures se prend au premier palier majeur', () {
      for (final major in ['haste', 'sentence', 'radiance', 'devotion']) {
        start('paladin', 10, signatureId: 'smite', evolutions: ['zeal:1']);
        expect(run.chooseSignatureEvolution('smite', major), isTrue, reason: major);
        expect(smiteTaken(), ['zeal:1', '$major:1']);
      }
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
