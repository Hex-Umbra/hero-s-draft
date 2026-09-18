import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';

/// L'identité des trois classes, lue sur les vrais `class.json`
/// (spec P-41, §7.1 et §7.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  // `setUpAll` : `GameDataRegistry` écrit un singleton statique dans son
  // constructeur, donc un seul registre par fichier de test.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  HeroData hero(String id) => registry.heroes.firstWhere((h) => h.id == id);

  group('l orientation de la Puissance', () {
    test('le Paladin renforce tout : c est son identite de generaliste', () {
      expect(hero('paladin').mightTargets, {
        MightTarget.attack,
        MightTarget.skill,
        MightTarget.alteration,
      });
    });

    test('le Berserker frappe en direct, et seulement ainsi', () {
      expect(hero('berserker').mightTargets, {MightTarget.attack});
    });

    test('le Mage frappe par ses Competences et ses alterations', () {
      expect(hero('mage').mightTargets, {
        MightTarget.skill,
        MightTarget.alteration,
      });
    });
  });

  group('les regles de stat', () {
    test('le Berserker convertit son armure en Puissance d un tour', () {
      final rule = hero('berserker').statRules.single;
      expect(rule.stat, RuleStat.armor);
      expect(rule.mode, RuleMode.convert);
      expect(rule.to, RuleTarget.statusMight);
      expect(rule.duration, 1);
    });

    test('le Paladin et le Mage n en declarent aucune', () {
      expect(hero('paladin').statRules, isEmpty);
      expect(hero('mage').statRules, isEmpty);
    });
  });

  group('les stats de depart', () {
    test('le Paladin part avec de la Maitrise, qui amplifie son passif', () {
      expect(hero('paladin').mastery, greaterThan(0));
      expect(hero('paladin').critChance, 0);
    });

    test('le Berserker part avec du critique, sans toucher a la Puissance', () {
      expect(hero('berserker').critChance, greaterThan(0));
      expect(hero('berserker').mastery, 0);
    });

    test('le Mage ne part avec aucune stat : son identite est ailleurs', () {
      expect(hero('mage').mastery, 0);
      expect(hero('mage').critChance, 0);
    });

    // P-16 : un point de mana vaut environ +33 % d'actions par tour, le
    // levier le plus explosif du jeu. Differencier le mana avant
    // l'assainissement de son economie coulerait le defaut dans le beton des
    // classes (spec §7.3).
    test('maxMana reste a 3 partout, et luck a 0', () {
      for (final h in registry.heroes) {
        expect(h.maxMana, 3, reason: h.id);
        expect(h.luck, 0, reason: h.id);
      }
    });
  });

  group('ce que la run et le tutoriel en font', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('startNewRun copie le critique de la classe', () {
      final run = container.read(runProvider.notifier);
      run.startNewRun(hero('berserker'));

      final stats = run.currentState.heroStats;
      expect(stats.critChance, hero('berserker').critChance);
      expect(stats.mastery, 0);
      expect(run.currentState.statRules, hero('berserker').statRules);
    });

    // Un tutoriel dont les degats varient ne peut pas annoncer ce que fera
    // une carte : exception explicite et testee a la fidelite d'ADR-081
    // (spec §9.1, decision 5 du plan).
    test('le tutoriel ne recopie pas le critique de la classe', () {
      final mock = TutorialMockState()..chosenHero = hero('berserker');
      expect(hero('berserker').critChance, greaterThan(0));
      expect(mock.baseStatsForHero().critChance, 0);
      expect(
        mock.baseStatsForHero().mightTargets,
        hero('berserker').mightTargets,
        reason: 'l orientation, elle, est fidele',
      );
    });

    // Decision 1 du plan : `statRules` n'est jamais serialise, et
    // `fromJsonWithReport` le relit de la classe via le vrai registre. Ce
    // test couvre ce demi-chemin de chargement, non teste ailleurs : sans
    // lui, une reconstruction cassee (par exemple qui retournerait toujours
    // une liste vide) passerait inapercue, puisqu'un Berserker qui reprend sa
    // run retrouverait alors silencieusement son armure pour le reste de la
    // run.
    test('fromJsonWithReport relit les regles de stat de la classe', () {
      final run = container.read(runProvider.notifier);
      run.startNewRun(hero('berserker'));

      final json = run.currentState.toJson();
      final (rebuilt, missing) = RunState.fromJsonWithReport(json);

      expect(missing, isEmpty);
      expect(rebuilt.statRules, hasLength(1));
      expect(rebuilt.statRules.single.to, RuleTarget.statusMight);
      expect(
        rebuilt.statRules,
        hero('berserker').statRules,
        reason: 'egalite par valeur, pas par identite d instance',
      );
    });
  });
}
