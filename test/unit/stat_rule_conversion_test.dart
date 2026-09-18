import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat/status_effect_processor.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/stat_gains.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// La conversion d'une ressource au gain, et la règle R5 qui la borne
/// (spec P-41, §7.1, §7.2).
void main() {
  const armorToMight = StatRule(
    stat: RuleStat.armor,
    mode: RuleMode.convert,
    to: RuleTarget.statusMight,
    duration: 1,
  );

  EntityStats stats() => EntityStats(
        maxPv: 80,
        currentPv: 80,
        maxMana: 3,
        currentMana: 3,
        armure: 2,
        might: 1,
      );

  // `firstOrNull` n'est pas disponible : `package:collection` n'est pas une
  // dependance du projet.
  StatusEffect? mightOf(EntityStats s) {
    final found = s.statuses.where((st) => st.id == 'might');
    return found.isEmpty ? null : found.first;
  }

  group('StatGains.apply', () {
    test('sans regle : l armure s ajoute a l armure', () {
      const gain = StatGain(GainResource.armor, 5, GainSource.card);
      final after = StatGains.apply(stats(), gain, const []);
      expect(after.armure, 2 + 5);
      expect(after.statuses, isEmpty);
    });

    // R5 : une ressource ephemere ne devient jamais permanente. L'armure d'un
    // tour devient de la Puissance d'un tour, jamais de la Puissance de run.
    test('avec la regle : l armure devient de la Puissance temporaire', () {
      const gain = StatGain(GainResource.armor, 5, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMight]);

      expect(after.armure, 2, reason: 'aucune armure ecrite');
      expect(after.might, 1, reason: 'aucune Puissance permanente');
      expect(mightOf(after)!.value, 5);
      expect(mightOf(after)!.duration, 1);
    });

    test('toute source d armure y passe', () {
      for (final source in GainSource.values) {
        final after = StatGains.apply(
          stats(),
          StatGain(GainResource.armor, 3, source),
          const [armorToMight],
        );
        expect(after.armure, 2, reason: 'source ${source.name}');
        expect(mightOf(after)!.value, 3, reason: 'source ${source.name}');
      }
    });

    test('une regle qui ne vise pas la ressource ne fait rien', () {
      const gain = StatGain(GainResource.mana, 2, GainSource.card);
      final after = StatGains.apply(stats(), gain, const [armorToMight]);
      expect(after.currentMana, 3 + 2);
      expect(after.statuses, isEmpty);
    });

    test('un gain nul ou negatif ne cree aucun statut', () {
      for (final amount in const [0, -3]) {
        final after = StatGains.apply(
          stats(),
          StatGain(GainResource.armor, amount, GainSource.card),
          const [armorToMight],
        );
        expect(after.statuses, isEmpty, reason: 'gain de $amount');
      }
    });

    test('deux gains convertis s empilent en un seul statut', () {
      const gain = StatGain(GainResource.armor, 4, GainSource.card);
      final once = StatGains.apply(stats(), gain, const [armorToMight]);
      final twice = StatGains.apply(once, gain, const [armorToMight]);
      expect(mightOf(twice)!.value, 8);
    });
  });

  group('le statut armor_regen du heros', () {
    const metallicize = StatusEffect(
      id: 'armor_regen',
      name: 'Metallisation',
      type: StatusType.buff,
      value: 3,
      duration: 2,
    );

    // Une liste vide par defaut aurait laisse `metallicize` donner de
    // l'armure a une classe qui la convertit (spec §4.1).
    test('passe par les regles que son appelant lui donne', () {
      final converted = StatusEffectProcessor.processPlayerStatuses(
        stats().addStatus(metallicize),
        const [armorToMight],
      );
      expect(converted.armure, 2);
      expect(mightOf(converted)!.value, 3);
    });
  });

  group('RunState', () {
    const rulebound = HeroData(
      id: 'berserker',
      classCard: 'berserker.png',
      maxHp: 80,
      maxMana: 3,
      baseDamage: 15,
      statRules: [armorToMight],
    );

    late ProviderContainer container;
    late RunController run;

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('startNewRun porte les regles de la classe', () {
      run.startNewRun(rulebound);
      expect(run.currentState.statRules, [armorToMight]);
    });

    test('un gain de carte du heros les traverse', () {
      run.startNewRun(rulebound);
      run.grant(const StatGain(GainResource.armor, 6, GainSource.card));

      expect(run.currentState.heroStats.armure, 0);
      expect(mightOf(run.currentState.heroStats)!.value, 6);
    });

    // Les regles sont du contenu : une run rechargee les relit de sa classe,
    // et non d'une sauvegarde qui les figerait (decision 1 du plan).
    test('elles ne sont pas serialisees', () {
      run.startNewRun(rulebound);
      expect(run.currentState.toJson().containsKey('statRules'), isFalse);
    });
  });
}
