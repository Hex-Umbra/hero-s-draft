import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/ui/widgets/hud/enemy_intents_panel.dart';

/// Le panneau a une largeur fixe de 250. Ses deux `Row` — le titre et le
/// libellé d'intention — mettaient une `Icon` et un `Text` côte à côte sans
/// contrainte : dès que le libellé était assez long pour la locale, la
/// police ou la mise à l'échelle du texte, Flutter peignait la bande
/// d'erreur jaune et noire à la place du texte, en plein HUD de combat.
///
/// Ces cas verrouillent le repli. Ils échouent sans les `Flexible` ajoutés
/// dans `enemy_intents_panel.dart`.

/// Le Slime, mais avec l'attaque qu'on lui demande : `effectiveIntent`
/// multiplie par `stats.attaque / data.baseDamage`, donc on garde les deux
/// égaux pour que la valeur affichée soit exactement celle passée ici.
EnemyInstance _enemy({required int intentValue, String nameFr = 'Slime'}) {
  final data = EnemyData(
    id: 'slime',
    nameEn: 'Slime',
    nameFr: nameFr,
    maxHp: 18,
    baseDamage: 4,
    spritePath: 'enemy_slime.png',
  );

  return EnemyInstance(
    data: data,
    stats: EntityStats(
      maxPv: data.maxHp,
      currentPv: data.maxHp,
      armure: 0,
      attaque: data.baseDamage,
    ),
    currentIntent: EnemyIntent(type: IntentType.attack, value: intentValue),
  );
}

Widget _harness(
  List<EnemyInstance> enemies, {
  Locale locale = const Locale('fr', ''),
  double textScale = 1.0,
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', ''), Locale('fr', '')],
    locale: locale,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Center(child: EnemyIntentsPanel(enemies: enemies)),
      ),
    ),
  );
}

void main() {
  group('EnemyIntentsPanel ne déborde pas', () {
    testWidgets('titre et intention courte en français', (tester) async {
      await tester.pumpWidget(_harness([_enemy(intentValue: 4)]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('« Attaque Dévastatrice », le libellé le plus long', (
      tester,
    ) async {
      // Le palier « dévastatrice » démarre à 20 (enemy_intents_panel.dart).
      await tester.pumpWidget(_harness([_enemy(intentValue: 25)]));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dévastatrice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nom d\'ennemi long', (tester) async {
      await tester.pumpWidget(
        _harness([
          _enemy(intentValue: 25, nameFr: 'Champion Corrompu des Profondeurs'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('mise à l\'échelle du texte à 200 %', (tester) async {
      await tester.pumpWidget(
        _harness([_enemy(intentValue: 25)], textScale: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('plusieurs ennemis, tous paliers d\'attaque', (tester) async {
      await tester.pumpWidget(
        _harness([
          _enemy(intentValue: 4),
          _enemy(intentValue: 8),
          _enemy(intentValue: 15),
          _enemy(intentValue: 25),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('locale anglaise', (tester) async {
      await tester.pumpWidget(
        _harness([_enemy(intentValue: 25)], locale: const Locale('en', '')),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
