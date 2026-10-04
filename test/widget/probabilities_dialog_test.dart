import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/probabilities_dialog.dart';

/// La fiche des probabilités de la carte du monde (spec P-43 E3, §5.1, §8 ;
/// C4.1, C4.2, C4.7). Elle lit la run et le chargeur, qui lui donne ses
/// mythiques : chaque cas surcharge le chargeur et le résout avant le premier
/// pump — sans quoi le vrai chargeur se lancerait (« Le piège du montage »).
///
/// Ouvre la fiche par `ProbabilitiesDialog.show`, sur un écran assez haut
/// pour que la zone défilante de la fiche soit à sa taille maximale.
Future<void> _openDialog(
  WidgetTester tester,
  ProviderContainer container,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProbabilitiesDialog.show(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

/// Un conteneur dont le chargeur est surchargé par [registry], et résolu.
Future<ProviderContainer> _containerOn(GameDataRegistry registry) async {
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry shipped;
  setUpAll(() async {
    shipped = await loadGameDataRegistry(rootBundle);
  });

  testWidgets('la section du draft standard a quitte la fiche, en francais',
      (tester) async {
    final container = await _containerOn(shipped);

    await _openDialog(tester, container, const Locale('fr', ''));

    // `_buildProbabilitySectionCard` écrit les titres en capitales.
    expect(find.text('DRAFT STANDARD DE RÉCOMPENSES'), findsNothing);
    expect(
      find.text(
        "Chances d'obtenir chaque rareté de carte/stat en fin de combat "
        'standard',
      ),
      findsNothing,
    );
    expect(find.text('RÉCOMPENSE DE NIVEAU'), findsOneWidget);
    expect(find.text('BUTIN DE RELIQUES'), findsOneWidget);
  });

  testWidgets('la section du draft standard a quitte la fiche, en anglais',
      (tester) async {
    final container = await _containerOn(shipped);

    await _openDialog(tester, container, const Locale('en', ''));

    expect(find.text('STANDARD REWARD DRAFT'), findsNothing);
    expect(
      find.text(
        'Chances of getting each card/stat rarity at the end of standard '
        'combat',
      ),
      findsNothing,
    );
    expect(find.text('LEVEL REWARD'), findsOneWidget);
    expect(find.text('RELIC LOOT'), findsOneWidget);
  });

  testWidgets('la recompense de niveau affiche les chances du tirage',
      (tester) async {
    final container = await _containerOn(shipped);
    final run = container.read(runProvider.notifier);
    run.updateState(
      run.currentState.copyWith(
        heroStats: run.currentState.heroStats.copyWith(luck: 5),
      ),
    );

    await _openDialog(tester, container, const Locale('fr', ''));

    // La commune à Chance 0, puis à Chance 5, selon `slotRarityChances` ;
    // aucune autre ligne de la fiche n'écrit ces deux textes, et l'ancienne
    // table afficherait « 60.0% » et « 15.0% ».
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('7.0%'), findsOneWidget);
    // Une autre rareté, et l'ordre des rangées (S7) : la légendaire, à
    // Chance 0 puis à Chance 5, sur la première rangée, au-dessus de la
    // commune.
    expect(find.text('2.0%'), findsOneWidget);
    expect(find.text('4.5%'), findsOneWidget);
    expect(tester.getTopLeft(find.text('4.5%')).dy,
        lessThan(tester.getTopLeft(find.text('7.0%')).dy));
  });

  // La parenthèse des mythiques, lue sur la donnée (propriétaire n° 7, C3.2).
  testWidgets('la parenthese nomme les mythiques de la donnee, en francais et '
      'en anglais', (tester) async {
    final container = await _containerOn(shipped);

    await _openDialog(tester, container, const Locale('fr', ''));
    expect(
      find.text("Chances d'obtenir chaque rareté d'option lors de la montée "
          'de niveau (options mythiques, tirées à part : Sagesse / Trèfle à '
          '4 feuilles / Miroir / Transcendance)'),
      findsOneWidget,
    );

    // Un arbre neuf : la fiche ouverte en français reste sinon au-dessus.
    await tester.pumpWidget(const SizedBox());
    await _openDialog(tester, container, const Locale('en', ''));
    expect(
      find.text('Chances of getting each option rarity when leveling up '
          '(mythic options, rolled separately: Wisdom / 4-Leaf Clover / '
          'Mirror / Transcendence)'),
      findsOneWidget,
    );
  });

  testWidgets('sur un registre a une seule mythique, la parenthese ne nomme '
      'qu elle', (tester) async {
    const talisman = LevelUpRewardData(
      id: 'talisman',
      nameFr: 'Talisman',
      nameEn: 'Talisman',
      descriptionFr: '+{amount} Chance',
      descriptionEn: '+{amount} Luck',
      effect: RewardEffect.stat,
      stat: RewardStat.luck,
      pool: RewardPool.mythic,
      values: {RewardRarity.mythic: 1},
    );
    final container = await _containerOn(GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [],
      levelUpRewards: const [talisman],
    ));

    await _openDialog(tester, container, const Locale('fr', ''));

    expect(
      find.text("Chances d'obtenir chaque rareté d'option lors de la montée "
          'de niveau (options mythiques, tirées à part : Talisman)'),
      findsOneWidget,
    );
  });
}
