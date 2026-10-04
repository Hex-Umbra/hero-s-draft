import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les trois passifs du Paladin (spec P-41, §6.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  const master = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    mastery: 2,
  );

  PassiveData fervor({int value = 1, int duration = 2}) => PassiveData(
        id: 'fervor',
        trigger: RelicTrigger.onDamageTaken,
        effectType: 'fervor',
        value: value,
        duration: duration,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} Might',
          descriptionFr: '+{amount} Puissance',
        ),
      );

  // `threshold` comme `blessing.json` : sans lui, 0, la tranche ne soigne
  // plus rien (spec P-43 E3, A24).
  PassiveData blessing({int value = 1, int threshold = 5}) => PassiveData(
        id: 'blessing',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'blessing',
        value: value,
        threshold: threshold,
        mastery: const PassiveMastery(
          field: 'value',
          perPoint: 1,
          descriptionEn: '+{amount} HP per tranche',
          descriptionFr: '+{amount} PV par tranche',
        ),
      );

  late ProviderContainer container;
  late RunController run;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
  });

  tearDown(() => container.dispose());

  EntityStats stats() => run.currentState.heroStats;

  int temporaryMight() {
    var total = 0;
    for (final status in stats().statuses) {
      if (status.id == 'might') total += status.value;
    }
    return total;
  }

  /// Pose l'état du héros sans passer par un gain : ces tests mesurent le
  /// passif, pas la chaîne de gains.
  void setHero({int armure = 0, int? currentPv}) {
    run.updateState(
      run.currentState.copyWith(
        heroStats: stats().copyWith(
          armure: armure,
          currentPv: currentPv ?? stats().currentPv,
        ),
      ),
    );
  }

  group('Ferveur', () {
    test('l armure qui encaisse octroie de la Puissance temporaire', () {
      run.startNewRun(paladin, fervor());
      setHero(armure: 10);

      run.takeDamage(4);

      expect(temporaryMight(), 1);
      expect(stats().might, 0, reason: 'jamais de Puissance permanente');
      final gained = stats().statuses.singleWhere((s) => s.id == 'might');
      expect(gained.duration, 2);
      expect(gained.sourceId, 'passive:fervor');
    });

    // La meme source rejouee s'additionne (D36) : d'un tour ennemi a
    // l'autre, Ferveur rejoint son entree encore active et prend sa duree.
    test('d un tour a l autre, Ferveur rejoint son entree', () {
      run.startNewRun(paladin, fervor());
      setHero(armure: 10);
      run.takeDamage(2);

      run.startTurn(); // le tic : l'entree passe a 1 tour
      setHero(armure: 10);
      run.takeDamage(2);

      final gained = stats().statuses.where((s) => s.id == 'might').toList();
      expect(gained, hasLength(1));
      expect(gained.single.value, 1 + 1);
      expect(gained.single.duration, 2);
    });

    test('des degats qui vont droit aux PV ne donnent rien', () {
      run.startNewRun(paladin, fervor());
      run.takeDamage(4);

      expect(temporaryMight(), 0);
      expect(stats().currentPv, 100 - 4);
    });

    test('la Maitrise augmente la Puissance accordee', () {
      run.startNewRun(master, fervor());
      setHero(armure: 10);

      run.takeDamage(1);

      expect(temporaryMight(), 1 + 2);
    });
  });

  group('Benediction', () {
    // Le seul passif du jeu dont l'ordre d'execution est contraignant : sans
    // la capture de `startTurn`, il n'a rien a convertir (spec §1.1, §6.3).
    test('l armure survivante devient des PV, malgre la remise a zero', () {
      run.startNewRun(paladin, blessing());
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      // 12 d'armure, une tranche de 5 par point de vie : 2 PV.
      expect(stats().currentPv, 50 + 2);
      expect(stats().armure, 0, reason: 'la remise a zero a bien eu lieu');
    });

    test('sans armure au tour precedent, rien', () {
      run.startNewRun(paladin, blessing());
      setHero(currentPv: 50);

      run.startTurn();

      expect(stats().currentPv, 50);
    });

    test('la conversion ne depasse jamais les PV max', () {
      run.startNewRun(paladin, blessing());
      setHero(armure: 60, currentPv: 99);

      run.startTurn();

      expect(stats().currentPv, 100);
    });

    test('la Maitrise augmente les PV par tranche', () {
      run.startNewRun(master, blessing());
      setHero(armure: 10, currentPv: 50);

      run.startTurn();

      // 2 tranches de 5, et (1 + 2) PV par tranche.
      expect(stats().currentPv, 50 + 2 * 3);
    });

    // La tranche en donnée (spec P-43 E3, A24).
    test('la tranche est le seuil du passif', () {
      run.startNewRun(paladin, blessing(threshold: 4));
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      // 12 d'armure, une tranche de 4 : 3 PV.
      expect(stats().currentPv, 50 + 3);
    });

    test('un seuil sous 1 ne soigne rien, sans lever', () {
      run.startNewRun(paladin, blessing(threshold: 0));
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      expect(stats().currentPv, 50);
    });
  });

  group('le catalogue', () {
    test('le Paladin garde la Regeneration d Armure en premier choix', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'paladin');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['regen_armor', 'fervor', 'blessing']);
    });

    // D60 (spec P-43 E3, §3.6) : la tranche en donnée, la Maîtrise sur la
    // valeur, sans plancher.
    test('blessing.json porte sa tranche, 5, et sa Maitrise sur la valeur',
        () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final blessing =
          registry.passives.singleWhere((p) => p.id == 'blessing');
      expect(blessing.threshold, 5);
      expect(blessing.mastery!.field, 'value');
      expect(blessing.mastery!.floor, isNull);
    });
  });
}
