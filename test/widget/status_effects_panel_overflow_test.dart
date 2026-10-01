import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/ui/widgets/hud/status_effects_panel.dart';

/// Le panneau a une largeur fixe de 250, dont 218 utiles après ses 16 px de
/// padding. Son `Row` de titre mettait une `Icon` et un `Text` côte à côte
/// sans contrainte : « EFFETS DU JOUEUR » en capitales, à `letterSpacing`
/// 1.2, n'y tient pas, et Flutter peignait la bande d'erreur jaune et noire
/// à la place du titre — en plein HUD de combat comme dans le tutoriel.
///
/// C'est le défaut déjà corrigé sur son panneau jumeau `EnemyIntentsPanel`
/// (PR #28) : les deux exposent la même `Row` titre dans le même `Container`
/// figé. Seul le jumeau avait été traité.
///
/// Ces cas verrouillent le repli. Ils échouent sans le `Flexible` ajouté
/// dans `status_effects_panel.dart`.

StatusEffect _status({
  required String id,
  required String name,
  StatusType type = StatusType.debuff,
  int value = 3,
  int duration = 2,
}) {
  return StatusEffect(
    id: id,
    name: name,
    type: type,
    value: value,
    duration: duration,
  );
}

Widget _harness(
  List<StatusEffect> statuses, {
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
        child: Center(child: StatusEffectsPanel(statuses: statuses)),
      ),
    ),
  );
}

void main() {
  group('StatusEffectsPanel ne déborde pas', () {
    testWidgets('le titre seul, sans aucun statut, en français', (tester) async {
      // Le cas décisif : aucun statut affiché, donc le seul contenu variable
      // est le titre. S'il déborde ici, le défaut est bien dans l'en-tête et
      // non dans les lignes de statut, qui ont déjà leur `Expanded`.
      await tester.pumpWidget(_harness(const []));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('plusieurs statuts en français', (tester) async {
      await tester.pumpWidget(
        _harness([
          _status(id: 'poison', name: 'Poison'),
          _status(id: 'burn', name: 'Brûlure'),
          _status(id: 'might', name: 'Puissance', type: StatusType.buff),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('libellé de statut long via la branche par défaut', (
      tester,
    ) async {
      // Un id inconnu tombe dans le `default` du switch, qui affiche
      // `'${status.name} : ${status.value}'` — donc un nom long y arrive
      // tel quel, sans passer par une clé ARB.
      await tester.pumpWidget(
        _harness([
          _status(
            id: 'inconnu',
            name: 'Malédiction Persistante des Abysses',
            value: 12,
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('mise à l\'échelle du texte à 200 %', (tester) async {
      await tester.pumpWidget(
        _harness([_status(id: 'poison', name: 'Poison')], textScale: 2.0),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('locale anglaise', (tester) async {
      await tester.pumpWidget(
        _harness(
          [_status(id: 'poison', name: 'Poison')],
          locale: const Locale('en', ''),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // D36, A8 (spec P-43 E0) : une ligne par entrée, chacune avec sa durée. Une
  // ligne sommée n'aurait qu'une durée pour dire deux vieillissements.
  testWidgets('deux Puissances de sources differentes : deux lignes', (
    tester,
  ) async {
    final statuses = EntityStats(
      maxPv: 80,
      currentPv: 80,
      armure: 0,
      might: 0,
    )
        .addStatus(
          StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 2,
            duration: 4,
            sourceId: StatusSource.card('demon_form'),
          ),
        )
        .addStatus(
          StatusEffect(
            id: 'might',
            name: 'Puissance',
            type: StatusType.buff,
            value: 5,
            duration: 1,
            sourceId: StatusSource.rule('armor'),
          ),
        )
        .statuses;

    await tester.pumpWidget(_harness(statuses));
    await tester.pumpAndSettle();

    expect(find.text('Puissance : +2'), findsOneWidget);
    expect(find.text('4 trs'), findsOneWidget);
    expect(find.text('Puissance : +5'), findsOneWidget);
    expect(find.text('1 trs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
