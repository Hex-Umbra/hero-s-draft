import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/save_service.dart';

const paladin = HeroData(
  id: 'paladin',
  nameEn: 'Paladin',
  nameFr: 'Paladin',
  descriptionEn: 'A holy knight',
  descriptionFr: 'Un saint chevalier',
  classCard: 'paladin.png',
  maxHp: 100,
  maxMana: 3,
  baseDamage: 5,
  luck: 0,
  armorMastery: 0,
  passiveTrait: 'regen_armor',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Declaration du mode de la run', () {
    test('une run lancee normalement n est pas une run debug', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(debugRunProvider.notifier).requestNormalRun();
      container.read(runProvider.notifier).startNewRun(paladin);

      expect(container.read(debugRunProvider).isDebugRun, isFalse);
    });

    test('le bouton Run Debug marque la run nee deux ecrans plus loin', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);

      expect(container.read(debugRunProvider).isDebugRun, isTrue);
    });

    test('une demande de run debug abandonnee ne teint pas la run suivante', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // « Run Debug », puis retour a l'accueil, puis « Jouer » : sans que le
      // bouton normal efface la demande en attente, cette run partirait en
      // debug sans que rien ne le signale.
      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(debugRunProvider.notifier).requestNormalRun();
      container.read(runProvider.notifier).startNewRun(paladin);

      expect(container.read(debugRunProvider).isDebugRun, isFalse);
    });

    test('la demande est consommee : la run suivante repart normale', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      expect(container.read(debugRunProvider).isDebugRun, isTrue);

      container.read(runProvider.notifier).startNewRun(paladin);

      expect(container.read(debugRunProvider).isDebugRun, isFalse);
    });
  });

  group('Une run debug ne persiste rien', () {
    test('le checkpoint ne declenche aucune sauvegarde', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isFalse);
    });

    test('une run normale, elle, se sauvegarde toujours', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(autosaveOrchestratorProvider);

      container.read(runProvider.notifier).startNewRun(paladin);

      container.read(checkpointProvider.notifier).bump();
      await Future<void>.delayed(Duration.zero);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('une run debug n efface pas la sauvegarde existante', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Une vraie partie est sur le disque.
      await SaveService.save(container.read);
      expect(await SaveService.hasSave(), isTrue);

      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);

      // C'est le chemin de `DeathOverlay`, atteint par « Perdre le combat » du
      // menu de debug. Sans ce verrou, tester une mort effacerait la vraie
      // partie — proteger la seule ecriture n'aurait servi a rien.
      await SaveService.clear(container.read);

      expect(await SaveService.hasSave(), isTrue);
    });

    test('charger une sauvegarde rabaisse le mode debug', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(debugRunProvider.notifier).requestDebugRun();
      container.read(runProvider.notifier).startNewRun(paladin);
      expect(container.read(debugRunProvider).isDebugRun, isTrue);

      // Sans cela, enchainer une run debug puis « Continuer » priverait la
      // vraie partie de toute sauvegarde pour le reste de la session.
      await SaveService.load(container.read);

      expect(container.read(debugRunProvider).isDebugRun, isFalse);
    });
  });

  group('Une run normale est intouchable', () {
    test('DebugActions refuse d agir hors d une run debug', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(paladin);
      final pvBefore = container.read(runProvider).heroStats.currentPv;

      DebugActions.updateHeroStats(
        container.read,
        (s) => s.copyWith(currentPv: 1),
      );
      DebugActions.setGold(container.read, 999);
      DebugActions.loseCombat(container.read);

      expect(container.read(runProvider).heroStats.currentPv, pvBefore);
      expect(container.read(inventoryProvider).gold, 50);
    });
  });
}
