import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/asset_picker.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/color_field.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/property_row.dart';

import 'content_editor/contrast.dart';

/// L'etat de `assets/data`, a plat comme en profondeur, trie pour une
/// comparaison stable. Sert a prouver qu'une ecriture refusee n'a rien
/// laisse sur le disque — pas seulement qu'un message d'erreur s'affiche.
List<String> _dataTreeSnapshot(String root) => Directory('$root/assets/data')
    .listSync(recursive: true)
    .map((entity) => IoContentFileSystem.toSlashes(entity.path))
    .toList()
  ..sort();

void main() {
  late Directory sandbox;
  late String root;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('editor_screen_');
    root = IoContentFileSystem.toSlashes(sandbox.path);
    Directory('$root/assets/data/relics').createSync(recursive: true);
    File('$root/pubspec.yaml').writeAsStringSync('name: sandbox\n');
  });

  tearDown(() => sandbox.deleteSync(recursive: true));

  Widget harness({
    required String? projectRoot,
    ContentFileSystem? fs,
    AssetPicker? picker,
  }) {
    return ProviderScope(
      overrides: [
        contentFileSystemProvider
            .overrideWithValue(fs ?? const _NoProcessFileSystem()),
        projectRootProvider.overrideWithValue(projectRoot),
        assetPickerProvider.overrideWithValue(picker ?? const _FakePicker(null)),
      ],
      // Le theme de l'application, et non celui par defaut de `MaterialApp` :
      // les boutons illisibles n'existaient que sous lui, dont le texte courant
      // est un blanc a 70 % prevu pour le fond sombre de l'ecran.
      child: MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: const ContentEditorScreen(),
      ),
    );
  }

  /// Un neutre et deux classes colorees. Le bleu du paladin compte : c'est sur
  /// lui que le seuil de `ThemeData.estimateBrightnessForColor` laisserait un
  /// texte blanc, a 3,1:1.
  void seedOwners() {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    for (final (id, color, card) in const [
      ('mage', '#9C27B0', 'eclair'),
      ('paladin', '#2196F3', 'bouclier'),
    ]) {
      Directory('$root/assets/data/classes/$id/cards')
          .createSync(recursive: true);
      File('$root/assets/data/classes/$id/cards/$card.json')
          .writeAsStringSync('{}');
      File('$root/assets/data/classes/$id/class.json').writeAsStringSync(
        '{"id":"$id","name_fr":"$id","name_en":"$id",'
        '"description_fr":".","description_en":".",'
        '"classCard":"assets/data/classes/$id/$id.png",'
        '"themeColor":"$color","maxHp":100,"maxMana":3,"baseDamage":5}',
      );
    }
  }

  /// Le bouton de choix qui porte [label].
  Finder buttonOf(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byKey(const Key('editeur-bouton-fond')),
      );

  /// Ce que dit le bandeau d'issue. Une faute qui nomme son champ s'affiche
  /// aussi sous ce champ : c'est dans le bandeau qu'on la compte.
  Finder inIssue(Finder finder) => find.descendant(
        of: find.byKey(const Key('editeur-issue')),
        matching: finder,
      );

  /// Ce que dit la rangee `id` de la classe, ou de toute entite editee.
  Finder inIdRow(Finder finder) => find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('editeur-id')),
          matching: find.byType(PropertyRow),
        ),
        matching: finder,
      );

  testWidgets('sans racine, l ecran refuse et explique pourquoi',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: null));

    expect(find.textContaining('arborescence source'), findsOneWidget);
    expect(find.text('Écrire'), findsNothing);
  });

  testWidgets('les sept types sont des boutons, visibles d emblee',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    for (final label in const [
      'Carte', 'Relique', 'Événement', 'Passif',
      'Amélioration de forge', 'Classe', 'Ennemi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'type manquant : $label');
    }
    expect(find.byType(DropdownButton<EntityCategory>), findsNothing);
  });

  testWidgets('le niveau 1 n apparait qu apres avoir choisi un type',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    expect(find.text('Créer'), findsNothing);
    expect(find.text('Modifier'), findsNothing);

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();

    expect(find.text('Créer'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    // Les sept types restent la : rien ne se replie vers le haut.
    expect(find.text('Ennemi'), findsOneWidget);
  });

  testWidgets('Modifier ouvre la liste des entites presentes', (tester) async {
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(find.text('talisman_de_fer'), findsOneWidget);
  });

  testWidgets('choisir un autre type referme la branche ouverte',
      (tester) async {
    // Les deux categories portent une entite. Sans elles, ce test ne pouvait
    // pas echouer : le bac a sable etant neuf, `talisman_de_fer` etait
    // introuvable **avant** le premier tap, et l'autre assertion etait vraie
    // que la branche se referme ou non.
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');
    Directory('$root/assets/data/enemies/gobelin').createSync(recursive: true);
    File('$root/assets/data/enemies/gobelin/enemy.json')
        .writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    // La branche est bel et bien ouverte : sans cette assertion, la
    // disparition d'apres ne prouverait rien.
    expect(find.text('talisman_de_fer'), findsOneWidget);

    await tester.tap(find.text('Ennemi'));
    await tester.pumpAndSettle();

    // Le niveau 1 est bien la, mais reinitialise : plus aucune branche ouverte
    // en dessous.
    expect(find.text('Créer'), findsOneWidget);
    // La cible de l'ancienne categorie a disparu...
    expect(find.text('talisman_de_fer'), findsNothing);
    // ...et aucune cible de la nouvelle n'a pris sa place : c'est **cette**
    // assertion qui tient la fermeture de la branche. `gobelin` existe sur le
    // disque et s'afficherait aussitot si « Modifier » restait selectionne.
    expect(find.text('gobelin'), findsNothing);
  });

  testWidgets('changer de type vide le champ identifiant', (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.pump();

    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Un identifiant tape pour une categorie ne designe rien dans une autre :
    // garde, il restait affiche sous le nouveau formulaire comme s'il lui
    // appartenait.
    final idField =
        tester.widget<TextField>(find.byKey(const Key('editeur-id')));
    expect(idField.controller!.text, isEmpty);
  });

  testWidgets('retaper le choix deja selectionne ne vide pas la saisie',
      (tester) async {
    // La barre d'outils rappelle `onSelected` pour le choix courant aussi :
    // sans garde, retaper « Créer » reensemencait le document au gabarit, et
    // retaper « Relique » effacait l'identifiant et le formulaire.
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    final value = find.byKey(const Key('editeur-champ-value'));
    await tester.ensureVisible(value);
    await tester.enterText(value, '12');
    await tester.pump();

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final written = jsonDecode(
      File('$root/assets/data/relics/talisman.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['id'], 'talisman');
    expect(written['value'], 12);
  });

  group('lisibilite', () {
    testWidgets('chaque bouton de choix se lit sur son fond', (tester) async {
      /// Tout ce que le bouton de [label] ecrit — libelle, et coche s'il est
      /// choisi — doit se lire sur son fond, a 4,5:1 au moins (WCAG AA).
      void expectReadable(List<String> labels) {
        for (final label in labels) {
          expect(
            buttonOf(label),
            findsOneWidget,
            reason: '« $label » n est pas un bouton de choix',
          );
          final fill = (tester.widget<Container>(buttonOf(label)).decoration!
                  as BoxDecoration)
              .color!;
          final inks = tester.widgetList<RichText>(
            find.descendant(of: buttonOf(label), matching: find.byType(RichText)),
          );
          for (final ink in inks) {
            final seen = Color.alphaBlend(ink.text.style!.color!, fill);
            expect(
              contrastRatio(seen, fill),
              greaterThanOrEqualTo(4.5),
              reason: '« $label » illisible sur ${colorToHex(fill)}',
            );
          }
        }
      }

      seedOwners();
      await tester.pumpWidget(harness(projectRoot: root));

      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      // Un choix d'identite selectionne garde son fond : sa coche doit s'y lire.
      await tester.tap(find.text('eclair'));
      await tester.pumpAndSettle();
      expectReadable(const [
        'Carte', 'Relique', 'Créer', 'Modifier', 'frappe', 'eclair', 'bouclier',
      ]);

      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expectReadable(const ['Neutre', 'mage', 'paladin']);

      await tester.tap(find.text('Passif'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('paladin'));
      await tester.tap(find.text('paladin'));
      await tester.pumpAndSettle();
      expectReadable(const ['paladin']);
    });

    testWidgets('seul le choix actif est marque choisi', (tester) async {
      final semantics = tester.ensureSemantics();
      Matcher chosen(bool yes) => isSemantics(isSelected: yes);
      Finder checkOn(String label) => find.descendant(
            of: buttonOf(label),
            matching: find.byIcon(Icons.check),
          );
      BorderSide underline(String label) =>
          ((tester.widget<Container>(buttonOf(label)).decoration!
                      as BoxDecoration)
                  .border! as Border)
              .bottom;

      seedOwners();
      await tester.pumpWidget(harness(projectRoot: root));

      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(buttonOf('Relique')), chosen(true));
      expect(tester.getSemantics(buttonOf('Carte')), chosen(false));
      expect(tester.getSemantics(buttonOf('Créer')), chosen(true));
      expect(tester.getSemantics(buttonOf('Modifier')), chosen(false));
      // Un onglet choisi se souligne : la selection ne repose pas sur la
      // seule couleur de son texte.
      expect(underline('Relique').color, AppColors.neonBlue);
      expect(underline('Carte').color, Colors.transparent);

      // Changer de type deplace la selection, et referme le mode choisi dessous.
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(buttonOf('Carte')), chosen(true));
      expect(tester.getSemantics(buttonOf('Relique')), chosen(false));
      expect(tester.getSemantics(buttonOf('Créer')), chosen(false));

      // Une pastille garde sa couleur, choisie ou non : seule la coche dit
      // laquelle l'est.
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(checkOn('Neutre'), findsOneWidget);
      expect(checkOn('mage'), findsNothing);
      await tester.tap(find.byKey(const Key('editeur-proprietaire-mage')));
      await tester.pumpAndSettle();
      expect(checkOn('mage'), findsOneWidget);
      expect(checkOn('Neutre'), findsNothing);
      semantics.dispose();
    });

    testWidgets('le formulaire annonce ce qu il edite', (tester) async {
      String title() {
        expect(find.byKey(const Key('editeur-titre')), findsOneWidget);
        return tester.widget<Text>(find.byKey(const Key('editeur-titre'))).data!;
      }

      seedOwners();
      await tester.pumpWidget(harness(projectRoot: root));

      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(title(), allOf(contains('Créer'), contains('Carte')));

      // La confusion d'origine : un formulaire de carte pris pour celui d'une
      // classe, que seul le chemin distinguait. Celui de la classe le dit, et
      // ne porte aucune pastille de proprietaire.
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      expect(title(), allOf(contains('Créer'), contains('Classe')));
      expect(
        find.byKey(const Key('editeur-proprietaire-neutre')),
        findsNothing,
      );

      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      expect(title(), allOf(contains('Modifier'), contains('Relique')));
    });

    testWidgets('une faute s aligne sur le formulaire, pas en son centre',
        (tester) async {
      // Assez large pour que la faute tienne sur une ligne : un texte qui
      // passe a la ligne occupe toute la largeur, et son centrage ne se voit
      // plus.
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Valider'));
      await tester.pump();

      // Plus etroite que le formulaire, la faute se centrait, loin des
      // boutons qui venaient de la produire : le bandeau s'aligne sur le
      // formulaire.
      expect(
        inIssue(find.textContaining('un identifiant est requis')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('editeur-issue'))).dx,
        tester.getTopLeft(find.byKey(const Key('editeur-entete'))).dx,
      );
    });
  });

  testWidgets('les cartes portent la couleur de leur proprietaire',
      (tester) async {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    Directory('$root/assets/data/classes/mage/cards')
        .createSync(recursive: true);
    File('$root/assets/data/classes/mage/cards/eclair.json').writeAsStringSync('{}');
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
      '{"id":"mage","name_fr":"Mage","name_en":"Mage",'
      '"description_fr":".","description_en":".",'
      '"classCard":"assets/data/classes/mage/mage.png",'
      '"themeColor":"#9C27B0","maxHp":100,"maxMana":3,"baseDamage":5}',
    );

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    Finder group(String owner) => find.byKey(Key('editeur-groupe-$owner'));
    Color dotOf(String owner) => (tester
            .widget<Container>(find.descendant(
              of: group(owner),
              matching: find.byKey(const Key('editeur-groupe-pastille')),
            ))
            .decoration! as BoxDecoration)
        .color!;

    // Chaque carte se range sous son proprietaire, qui porte sa couleur.
    expect(find.descendant(of: group('mage'), matching: find.text('eclair')),
        findsOneWidget);
    expect(find.descendant(of: group('neutre'), matching: find.text('frappe')),
        findsOneWidget);
    // Sans cette assertion, la couleur pourrait etre uniforme et le test
    // passerait quand meme : c'est la *difference* qui porte l'information.
    expect(dotOf('mage'), isNot(dotOf('neutre')));
    expect(dotOf('mage'), const Color(0xFF9C27B0));
    expect(dotOf('neutre'), kNeutralOwnerColor);
  });

  testWidgets('le chemin calcule est affiche et suit la categorie',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.pump();

    expect(
      find.textContaining('assets/data/cards/talisman.json'),
      findsOneWidget,
    );
  });

  testWidgets('un brouillon fautif est refuse sans rien ecrire',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Identifiant en majuscules : la famille 1 doit le refuser.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'Talisman');
    await tester.tap(find.text('Valider'));
    await tester.pump();

    expect(inIssue(find.textContaining('minuscules')), findsOneWidget);
    expect(Directory('$root/assets/data').listSync(), hasLength(1));
  });

  testWidgets('un brouillon fautif est aussi refuse par Ecrire, sans rien ecrire',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    // `cards/` doit exister pour que l'ecriture soit *capable* de reussir si
    // la porte E6 venait a manquer : sans dossier cible, l'absence d'effet
    // ne prouverait qu'une erreur d'E/S sans rapport, pas que la validation a
    // retenu la main. Voir la carte de signature (Task 6) pour la meme
    // exigence cote ecrivain.
    Directory('$root/assets/data/cards').createSync(recursive: true);
    final before = _dataTreeSnapshot(root);

    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Meme brouillon fautif que ci-dessus — identifiant en majuscules — mais
    // tape sur le vrai controle d'ecriture. C'est lui, et non Valider, que la
    // decision E6 doit tenir : Valider n'appelle jamais EntityWriter.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'Talisman');
    await tester.tap(find.text('Écrire'));
    // `_write` est async (valide puis, si la porte le permet, ecrit et lance
    // sync_assets) : un `pump()` seul pourrait conclure avant la fin de la
    // future, et un test qui verifie trop tot serait le meme defaut sous un
    // autre habit.
    await tester.pumpAndSettle();

    expect(inIssue(find.textContaining('minuscules')), findsOneWidget);
    expect(_dataTreeSnapshot(root), equals(before));
  });

  testWidgets('creer une relique avec le seul identifiant ecrit un fichier valide',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // C'est ce test qui echouerait si la substitution passait *apres* la
    // validation : la famille bilingue refuserait la prose vide.
    expect(find.textContaining('Écrit :'), findsOneWidget);
    final written = jsonDecode(
      File('$root/assets/data/relics/talisman.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['name_fr'], contains('À REMPLIR'));
    expect(written['name_en'], contains('À REMPLIR'));
  });

  testWidgets('une creation sans son ni illustration n ecrit ni sfx ni spritePath',
      (tester) async {
    // `audio_catalogue_test` refuse tout `sfx` non declare : un `"sfx": ""`
    // ecrit par le gabarit faisait rougir la suite a chaque creation.
    Directory('$root/assets/data/cards').createSync(recursive: true);

    for (final (type, id, path) in const [
      ('Relique', 'talisman', 'assets/data/relics/talisman.json'),
      ('Carte', 'frappe', 'assets/data/cards/frappe.json'),
      ('Ennemi', 'troll', 'assets/data/enemies/troll/enemy.json'),
    ]) {
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text(type));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), id);
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      final written = jsonDecode(File('$root/$path').readAsStringSync())
          as Map<String, dynamic>;
      expect(written.containsKey('sfx'), isFalse, reason: type);
      if (type == 'Carte') {
        expect(written.containsKey('spritePath'), isFalse);
      }
    }
  });

  testWidgets('apres une creation, l arbre revient a la branche 0',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // Plus aucune branche ouverte, mais le compte rendu reste lisible : la
    // nouvelle entite n'existe pas encore pour l'application qui tourne, et
    // ouvrir son formulaire donnerait l'illusion inverse.
    expect(find.text('Créer'), findsNothing);
    expect(find.textContaining('Écrit :'), findsOneWidget);
    // Verifie a la main le 2026-09-14, classe comme relique : un redemarrage a
    // chaud suffit a charger une entite creee. Rien n'impose de relancer.
    expect(
      find.textContaining('Redémarrage à chaud pour charger la nouvelle entité'),
      findsOneWidget,
    );
    expect(find.textContaining('flutter run'), findsNothing);
  });

  testWidgets('creer une classe ecrit ses cartes et referme skills',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.enterText(
        find.byKey(const Key('editeur-nombre-cartes')), '2');
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('editeur-carte-0-id')), 'bluff');
    await tester.enterText(
        find.byKey(const Key('editeur-carte-1-id')), 'all_in');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final classJson = jsonDecode(
      File('$root/assets/data/classes/gambler/class.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(classJson['skills'], ['all_in', 'bluff']);
    expect(
      File('$root/assets/data/classes/gambler/cards/bluff.json').existsSync(),
      isTrue,
    );
    // L'emplacement de l'icone, garde par defaut, est ecrit.
    expect(classJson['iconPath'], 'assets/data/classes/gambler/icon.png');
  });

  testWidgets(
      'une classe creee apres « aucune » n a ni iconPath ni icone deposee',
      (tester) async {
    // Le remplacement doit etre la : sans lui, `_placeClassIcon` sort sur sa
    // garde de source absente, et l'absence d'icone ne prouverait rien.
    Directory('$root/assets/placeholders/images').createSync(recursive: true);
    File('assets/placeholders/images/placeholder_icon.png')
        .copySync('$root/assets/placeholders/images/placeholder_icon.png');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'barde');
    await tester.pump();

    // A la creation, l'emplacement est present : le champ montre le chemin
    // calcule, et « aucune » le retire vraiment.
    expect(find.text('assets/data/classes/barde/icon.png'), findsOneWidget);
    final none = find.text('aucune');
    await tester.ensureVisible(none);
    await tester.tap(none);
    await tester.pumpAndSettle();
    expect(find.text('(aucune)'), findsOneWidget);

    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final classJson = jsonDecode(
      File('$root/assets/data/classes/barde/class.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(classJson.containsKey('iconPath'), isFalse);
    expect(
      File('$root/assets/data/classes/barde/icon.png').existsSync(),
      isFalse,
    );
  });

  testWidgets(
      'deux cartes de signature identiques sont refusees, rien n est ecrit',
      (tester) async {
    // Sans le controle de la recette, les deux passeraient chacune la
    // validation individuelle (ni l'une ni l'autre n'existe encore sur le
    // disque), et `writeAll` les ecrirait au meme chemin l'une apres
    // l'autre : la seconde ecraserait la premiere, sans faute affichee.
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.enterText(
        find.byKey(const Key('editeur-nombre-cartes')), '2');
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('editeur-carte-0-id')), 'bluff');
    await tester.enterText(
        find.byKey(const Key('editeur-carte-1-id')), 'bluff');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Écrit :'), findsNothing);
    expect(inIssue(find.textContaining('deux cartes de signature')),
        findsOneWidget);
    expect(
      Directory('$root/assets/data/classes').existsSync(),
      isFalse,
      reason: 'la porte E6 doit tenir tant que la recette porte un doublon',
    );
  });

  group('Valider juge le document que Ecrire ecrira', () {
    // Un bouton qui valide autre chose que ce qui sera ecrit est pire qu'un
    // bouton absent : il donne le feu vert a un geste que l'ecriture refusera,
    // ou reproche une faute que le remplissage allait effacer. Les deux
    // controles partent donc du **meme** document.

    testWidgets('Valider voit le doublon de cartes de signature',
        (tester) async {
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
      await tester.enterText(
          find.byKey(const Key('editeur-nombre-cartes')), '2');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('editeur-carte-0-id')), 'bluff');
      await tester.enterText(
          find.byKey(const Key('editeur-carte-1-id')), 'bluff');

      await tester.tap(find.text('Valider'));
      await tester.pump();

      // C'est la faute que « Écrire » leve sur ce meme formulaire, deux tests
      // plus haut. Valider ne peut pas rester muet la ou Ecrire refuse.
      expect(inIssue(find.textContaining('deux cartes de signature')),
          findsOneWidget);
    });

    testWidgets('Valider voit la carte de signature non nommee',
        (tester) async {
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
      await tester.enterText(
          find.byKey(const Key('editeur-nombre-cartes')), '1');
      await tester.pump();
      // L'identifiant de la carte reste vide : le brouillon de classe seul est
      // pourtant parfaitement valide, et c'est exactement le piege.

      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(inIssue(find.textContaining('un identifiant est requis')),
          findsOneWidget);
      // La faute est celle de la carte : la rangee `id` de la classe, dont
      // l'identifiant est valide, n'en dit rien.
      expect(inIdRow(find.textContaining('un identifiant est requis')),
          findsNothing);
    });

    testWidgets('Valider ne reproche pas la prose que le remplissage fournit',
        (tester) async {
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
      await tester.tap(find.text('Valider'));
      await tester.pump();

      // Le symetrique : « Écrire » ecrit ce formulaire sans broncher (test
      // « creer une relique avec le seul identifiant »). Valider ne doit donc
      // pas exiger une prose que la substitution va poser.
      expect(
        find.textContaining('variantes linguistiques'),
        findsNothing,
        reason: 'Valider jugeait le brouillon non rempli',
      );
    });
  });

  testWidgets('une faute de carte de signature vise son panneau, pas la classe',
      (tester) async {
    // Une carte de signature n'a pas de rangee a elle : sa faute `id` bordait
    // de rouge l'identifiant de la classe, pourtant valide, et y ramenait.
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.enterText(
        find.byKey(const Key('editeur-nombre-cartes')), '1');
    await tester.pump();
    await tester.tap(find.text('Valider'));
    await tester.pump();

    final classId =
        tester.widget<TextField>(find.byKey(const Key('editeur-id')));
    expect(
      (classId.decoration!.enabledBorder! as OutlineInputBorder)
          .borderSide
          .color,
      isNot(AppColors.danger),
    );
    expect(inIdRow(find.byIcon(Icons.error)), findsNothing);
    expect(inIssue(find.textContaining('carte 1 :')), findsOneWidget);
  });

  testWidgets('le proprietaire d une carte est un champ, pas un niveau',
      (tester) async {
    Directory('$root/assets/data/classes/mage/cards').createSync(recursive: true);
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
      '{"id":"mage","name_fr":"Mage","name_en":"Mage",'
      '"description_fr":".","description_en":".",'
      '"classCard":"assets/data/classes/mage/mage.png",'
      '"maxHp":100,"maxMana":3,"baseDamage":5}',
    );

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('editeur-proprietaire-mage')));
    await tester.enterText(find.byKey(const Key('editeur-id')), 'eclair');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(
      File('$root/assets/data/classes/mage/cards/eclair.json').existsSync(),
      isTrue,
      reason: 'le propriétaire choisi décide du répertoire',
    );
  });

  testWidgets('les classes d un passif se choisissent dans le catalogue',
      (tester) async {
    // Une classe presente sur le disque qu'aucun passif ne declare : le cas
    // que `knownValues`, qui liste les valeurs *employees*, manquerait.
    Directory('$root/assets/data/classes/barde').createSync(recursive: true);
    File('$root/assets/data/classes/barde/class.json').writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Passif'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(buttonOf('barde'), findsOneWidget);
  });

  testWidgets('une saisie non entiere est une faute, et rien n est ecrit',
      (tester) async {
    final before = _dataTreeSnapshot(root);
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
    final value = find.byKey(const Key('editeur-champ-value'));
    await tester.ensureVisible(value);
    await tester.enterText(value, '1a');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(inIssue(find.textContaining('n\'est pas un entier')),
        findsOneWidget);
    expect(_dataTreeSnapshot(root), equals(before));
  });

  testWidgets(
      'une structure qui change efface la faute de conversion en cours',
      (tester) async {
    // `onStructureChanged` recree le formulaire, ses controleurs avec lui, et
    // chaque champ retombe sur la valeur du document. Une faute de conversion
    // qui survivrait n'aurait alors plus de cause visible — le champ affiche a
    // nouveau une valeur saisissable.
    Directory('$root/assets/data/cards').createSync(recursive: true);
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'double_coup');

    final cost = find.byKey(const Key('editeur-champ-cost'));
    await tester.ensureVisible(cost);
    await tester.enterText(cost, '1a');
    await tester.pump();

    final add = find.byKey(const Key('editeur-ajouter-effects'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    expect(find.textContaining('n\'est pas un entier'), findsNothing);
    final written = jsonDecode(
      File('$root/assets/data/cards/double_coup.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['cost'], 1);
  });

  testWidgets('une vue brute illisible reste brute, texte intact',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('editeur-bascule-json'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('editeur-json-brut')), '{ pas du json');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    final box =
        tester.widget<TextField>(find.byKey(const Key('editeur-json-brut')));
    expect(box.controller!.text, '{ pas du json');
    expect(find.textContaining('ne se relit pas'), findsOneWidget);
  });

  testWidgets('ajouter un effet a une carte l ecrit', (tester) async {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'double_coup');
    final add = find.byKey(const Key('editeur-ajouter-effects'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final written = jsonDecode(
      File('$root/assets/data/cards/double_coup.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written['effects'], hasLength(2));
  });

  testWidgets('un son se choisit puis se retire, et aucun n ecrit rien',
      (tester) async {
    File('$root/assets/data/audio.json').writeAsStringSync(
        '{"sounds": {"clang": {"file": "sfx/clang.wav"}}}');
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

    await tester.ensureVisible(find.text('clang'));
    await tester.tap(find.text('clang'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('aucun'));
    await tester.tap(find.text('aucun'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    final written = jsonDecode(
      File('$root/assets/data/relics/talisman.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(written.containsKey('sfx'), isFalse);
  });

  testWidgets(
      'cliquer une entite au niveau 2 remplit le champ identifiant (a)',
      (tester) async {
    // (a) Avant ce correctif, choisir une entite au niveau 2 ne faisait que
    // la surligner : `_target`/`_targetOwner` changeaient, mais
    // `_id.text` restait inchange, si bien que « Charger » et « Écrire »
    // pouvaient viser une entite differente de celle mise en surbrillance.
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('talisman_de_fer'));
    await tester.pumpAndSettle();

    final idField =
        tester.widget<TextField>(find.byKey(const Key('editeur-id')));
    expect(idField.controller!.text, 'talisman_de_fer');
  });

  testWidgets('taper dans le champ identifiant ne relit pas le disque',
      (tester) async {
    // `build` est relance a chaque frappe. Trois lectures y vivaient :
    // `entityIdsByOwner` pour le niveau 2, la meme pour les pastilles de
    // proprietaire, et un `class.json` decode **par bouton** pour sa couleur
    // et son image. Le panneau de valeurs connues, quarante lignes plus bas,
    // montrait deja la bonne facon de faire : retenir tant que la categorie ne
    // change pas.
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    Directory('$root/assets/data/classes/mage/cards')
        .createSync(recursive: true);
    File('$root/assets/data/classes/mage/cards/eclair.json')
        .writeAsStringSync('{}');
    File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
      '{"id":"mage","name_fr":"Mage","name_en":"Mage",'
      '"description_fr":".","description_en":".",'
      '"classCard":"assets/data/classes/mage/mage.png",'
      '"themeColor":"#9C27B0","maxHp":100,"maxMana":3,"baseDamage":5}',
    );

    final fs = _CountingFileSystem();
    await tester.pumpWidget(harness(projectRoot: root, fs: fs));
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    final listings = fs.listings;
    final reads = fs.reads;
    expect(listings, greaterThan(0), reason: 'le niveau 2 a bien lu le disque');

    for (final typed in const ['e', 'ec', 'ecl']) {
      await tester.enterText(find.byKey(const Key('editeur-id')), typed);
      await tester.pump();
    }

    expect(fs.listings, listings, reason: 'arborescence relue a chaque frappe');
    expect(fs.reads, reads, reason: 'class.json redecode a chaque frappe');
  });

  testWidgets('changer de categorie relit le disque', (tester) async {
    // La contrepartie, sans laquelle la memorisation serait un cache perime :
    // le catalogue est retenu **par categorie**, exactement comme celui des
    // valeurs connues.
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');

    final fs = _CountingFileSystem();
    await tester.pumpWidget(harness(projectRoot: root, fs: fs));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(find.text('talisman_de_fer'), findsOneWidget);

    final listings = fs.listings;

    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    expect(fs.listings, greaterThan(listings));
    expect(find.text('frappe'), findsOneWidget);
    expect(find.text('talisman_de_fer'), findsNothing);
  });

  testWidgets('toucher une faute ramene a son champ', (tester) async {
    tester.view.physicalSize = const Size(1000, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    final value = find.byKey(const Key('editeur-champ-value'));
    await tester.ensureVisible(value);
    await tester.enterText(value, '1a');
    await tester.pump();
    // Retour en haut du formulaire : le champ fautif sort de la vue.
    await tester.drag(
      find.byKey(const Key('editeur-formulaire')),
      const Offset(0, 4000),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byKey(const Key('editeur-formulaire')));
    expect(tester.getRect(value).top, greaterThanOrEqualTo(viewport.bottom),
        reason: 'le champ doit etre hors de vue avant le saut');

    await tester.tap(inIssue(find.text('value')));
    await tester.pumpAndSettle();

    final field = tester.getRect(value);
    expect(field.top, greaterThanOrEqualTo(viewport.top));
    expect(field.bottom, lessThanOrEqualTo(viewport.bottom));
  });

  testWidgets('les valeurs deja utilisees ne s affichent qu avec la place',
      (tester) async {
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{"effectType":"gain_armor"}');
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(find.text('VALEURS DÉJÀ UTILISÉES'), findsNothing);

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();
    expect(find.text('VALEURS DÉJÀ UTILISÉES'), findsOneWidget);
  });

  testWidgets('plus et moins reglent le nombre de cartes de signature',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    final plus = find.byKey(const Key('editeur-cartes-plus'));
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editeur-carte-0-id')), findsOneWidget);

    await tester.tap(find.byKey(const Key('editeur-cartes-moins')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('editeur-carte-0-id')), findsNothing);
  });

  testWidgets('l etat du fichier suit sa relecture', (tester) async {
    File('$root/assets/data/relics/talisman_de_fer.json')
        .writeAsStringSync('{}');
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau fichier'), findsOneWidget);

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('talisman_de_fer'));
    await tester.pumpAndSettle();
    expect(find.text('Relu du disque'), findsOneWidget);

    // Un autre identifiant designe un autre fichier, qui n'a pas ete relu.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'autre');
    await tester.pump();
    expect(find.text('Non chargé'), findsOneWidget);
  });

  group('mode Modifier', () {
    /// Une relique deja sur le disque, portant **une cle que le gabarit n a
    /// pas** et des valeurs enumerees differentes des siennes. C est ce que
    /// « Modifier » doit conserver : sans relecture du fichier, `compose()`
    /// ecrit la mecanique du gabarit par-dessus, et tout ce qui n y figure
    /// pas disparait — validation passee, ecriture reussie, aucun signal.
    void seedRelic() {
      File('$root/assets/data/audio.json').writeAsStringSync(
        '{"sounds": {"clang_distinctif": {"file": "sfx/clang_distinctif.wav"}}}',
      );
      File('$root/assets/data/relics/talisman_de_fer.json').writeAsStringSync(
        jsonEncode(const {
          'id': 'talisman_de_fer',
          'name_en': 'Iron Talisman',
          'name_fr': 'Talisman de fer',
          'description_en': 'Gain 5 armor when an enemy dies.',
          'description_fr': 'Donne 5 armure a la mort d un ennemi.',
          'trigger': 'onEnemyKilled',
          'effectType': 'gain_armor',
          'value': 5,
          'rarity': 'legendary',
          'sfx': 'clang_distinctif',
        }),
      );
    }

    /// Le document du formulaire, lu dans la vue brute puis refermee.
    Future<Map<String, dynamic>> mechanicsBox(WidgetTester tester) async {
      final toggle = find.byKey(const Key('editeur-bascule-json'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final box =
          tester.widget<TextField>(find.byKey(const Key('editeur-json-brut')));
      final decoded = jsonDecode(box.controller!.text) as Map<String, dynamic>;
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      return decoded;
    }

    /// Amene l ecran sur la relique semee, en mode Modifier.
    Future<void> aimAtSeededRelic(WidgetTester tester) async {
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('editeur-id')),
        'talisman_de_fer',
      );
      await tester.pump();
    }

    testWidgets('Charger relit la cible, et ce qu elle porte survit a Ecrire',
        (tester) async {
      seedRelic();
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester);

      await tester.tap(find.text('Charger'));
      await tester.pump();

      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Écrit :'), findsOneWidget);
      final written = jsonDecode(
        File('$root/assets/data/relics/talisman_de_fer.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;

      // La cle que le gabarit ignore : la preuve directe de la relecture.
      expect(written['sfx'], 'clang_distinctif');
      // Les valeurs que le gabarit aurait ramenees aux siennes.
      expect(written['trigger'], 'onEnemyKilled');
      expect(written['rarity'], 'legendary');
      // La prose vient elle aussi du fichier : restee vide, elle aurait fait
      // echouer la famille 5 avant meme d ecrire.
      expect(written['name_fr'], 'Talisman de fer');
      expect(written['description_en'], 'Gain 5 armor when an enemy dies.');
    });

    testWidgets(
        'choisir une entite au niveau 2 la charge, et en choisir une autre la '
        'remplace', (tester) async {
      // Observe a la main : le formulaire montrait le gabarit — le meme pour
      // toutes les entites — tant que « Charger » n etait pas presse, puis
      // gardait le contenu de la precedente quand on en choisissait une autre.
      seedRelic();
      File('$root/assets/data/relics/amulette.json').writeAsStringSync(
        jsonEncode(const {
          'id': 'amulette',
          'name_en': 'Amulet',
          'name_fr': 'Amulette',
          'description_en': 'Heal.',
          'description_fr': 'Soigne.',
          'trigger': 'onCombatEnd',
          'effectType': 'heal',
          'value': 17,
          'rarity': 'rare',
        }),
      );
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('talisman_de_fer'));
      await tester.pumpAndSettle();

      expect(await mechanicsBox(tester), containsPair('sfx', 'clang_distinctif'),
          reason: 'le gabarit est encore affiche');
      expect(find.text('Talisman de fer'), findsOneWidget);

      await tester.tap(find.text('amulette'));
      await tester.pumpAndSettle();

      final amulet = await mechanicsBox(tester);
      expect(amulet, containsPair('value', 17),
          reason: 'le contenu de l entite precedente est reste');
      expect(amulet.containsKey('sfx'), isFalse);
      expect(find.text('Amulette'), findsOneWidget);
    });

    testWidgets('choisir une carte de classe la charge depuis son dossier',
        (tester) async {
      seedOwners();
      File('$root/assets/data/classes/mage/cards/eclair.json').writeAsStringSync(
        '{"id":"eclair","name_fr":"Éclair","name_en":"Bolt",'
        '"description_fr":".","description_en":".","cost":5,"type":"attack",'
        '"rarity":"common","effects":[{"type":"damage","value":77}]}',
      );
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('eclair'));
      await tester.pumpAndSettle();

      expect(find.textContaining('aucun fichier à charger'), findsNothing);
      expect((await mechanicsBox(tester))['effects'], [
        {'type': 'damage', 'value': 77},
      ]);
    });

    testWidgets('Ecrire sans avoir charge est refuse, sans rien ecrire',
        (tester) async {
      seedRelic();
      final before = _dataTreeSnapshot(root);
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester);

      // Le geste que le bouton Charger rend indispensable : le formulaire
      // porte encore le gabarit, et l ecrire serait la perte de donnees que
      // tout ce mode doit empecher.
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Charger'), findsWidgets);
      expect(find.textContaining('Écrit :'), findsNothing);
      expect(
        jsonDecode(
          File('$root/assets/data/relics/talisman_de_fer.json')
              .readAsStringSync(),
        ),
        containsPair('sfx', 'clang_distinctif'),
      );
      expect(_dataTreeSnapshot(root), equals(before));
    });

    testWidgets('une cible absente est signalee, sans vider le formulaire',
        (tester) async {
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester); // rien n a ete seme cette fois

      await tester.tap(find.text('Charger'));
      await tester.pump();

      expect(find.textContaining('aucun fichier à charger'), findsOneWidget);
      // Le formulaire tient : le document porte toujours le gabarit.
      expect((await mechanicsBox(tester))['trigger'], 'startOfCombat');
    });

    testWidgets('le type reste choisissable apres le passage en Modifier',
        (tester) async {
      // Le geste reel : on choisit d'abord Modifier, on change ensuite de
      // type. Rien ne doit se figer — c'est l'invariant meme de l'arbre : les
      // sept types restent la, quel que soit le mode. Avant l'arbre, un bug
      // gelait la liste deroulante des lors qu'on avait bascule sur Modifier,
      // rendant toute entite hors de la categorie par defaut inatteignable.
      Directory('$root/assets/data/classes/gambler/cards')
          .createSync(recursive: true);
      File('$root/assets/data/classes/gambler/class.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'id': 'gambler',
          'name_en': 'Gambler',
          'name_fr': 'Parieur',
          'description_en': 'Plays with the odds.',
          'description_fr': 'Manipule les probabilites.',
          // Pas les 100 du gabarit : le champ ne prouve la relecture que
          // s'il montre une valeur que le gabarit n'a pas.
          'maxHp': 120,
          'maxMana': 3,
          'baseDamage': 5,
          'displayOrder': 99,
          'iconPath': 'assets/data/classes/gambler/icon.png',
        }),
      );

      await tester.pumpWidget(harness(projectRoot: root));

      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      // Le type reste choisissable : rien ne s'est fige en passant en
      // Modifier.
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
      await tester.pump();
      await tester.tap(find.text('Charger'));
      await tester.pumpAndSettle();

      expect(find.textContaining('aucun fichier à charger'), findsNothing);
      expect(find.textContaining('Parieur'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('editeur-champ-maxHp')))
            .controller!
            .text,
        '120',
      );
    });

    testWidgets('une cle inconnue du gabarit a son champ et survit a Ecrire',
        (tester) async {
      seedRelic();
      final path = '$root/assets/data/relics/talisman_de_fer.json';
      File(path).writeAsStringSync(jsonEncode({
        ...jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
        'custom_flag': true,
      }));
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('talisman_de_fer'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('editeur-champ-custom_flag')), findsOneWidget);

      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();
      expect(jsonDecode(File(path).readAsStringSync()),
          containsPair('custom_flag', true));
    });
  });

  group('imports', () {
    const audio = '{\n  "sounds": {\n    "clang": { "file": "sfx/clang.wav" }\n  }\n}\n';

    String sourceFile(String name, String content) {
      final file = File('$root/import/$name')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
      return IoContentFileSystem.toSlashes(file.path);
    }

    /// Un ennemi deja sur le disque, avec son sprite dessine.
    void seedGobelin() {
      Directory('$root/assets/data/enemies/gobelin').createSync(recursive: true);
      File('$root/assets/data/enemies/gobelin/sprite.png')
          .writeAsStringSync('ancienne');
      File('$root/assets/data/enemies/gobelin/enemy.json').writeAsStringSync(
        jsonEncode({
          'id': 'gobelin',
          'name_en': 'Goblin',
          'name_fr': 'Gobelin',
          'maxHp': 30,
          'baseDamage': 5,
          'spritePath': 'assets/data/enemies/gobelin/sprite.png',
          'intents': [
            {'type': 'attack', 'value': 5},
          ],
        }),
      );
    }

    Future<void> importSound(WidgetTester tester, String soundId) async {
      final button = find.byKey(const Key('editeur-importer-sfx'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('editeur-import-son-id')), soundId);
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();
    }

    testWidgets('importer un son le copie, le declare et le lie', (tester) async {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      final source = sourceFile('clang.wav', 'octets');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

      await importSound(tester, 'talisman_clang');
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Écrit :'), findsWidgets);
      expect(
        File('$root/assets/audio/sfx/talisman_clang.wav').readAsStringSync(),
        'octets',
      );
      final sounds = (jsonDecode(
        File('$root/assets/data/audio.json').readAsStringSync(),
      ) as Map<String, dynamic>)['sounds'] as Map<String, dynamic>;
      expect(sounds.keys, contains('talisman_clang'));
      expect(
        jsonDecode(File('$root/assets/data/relics/talisman.json')
            .readAsStringSync()),
        containsPair('sfx', 'talisman_clang'),
      );
    });

    testWidgets('un son deja declare est refuse, rien n est copie',
        (tester) async {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      final source = sourceFile('clang.wav', 'octets');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

      await importSound(tester, 'clang');
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(inIssue(find.textContaining('existe déjà dans audio.json')),
          findsOneWidget);
      expect(Directory('$root/assets/audio').existsSync(), isFalse);
    });

    testWidgets('importer une image d ennemi remplace son sprite',
        (tester) async {
      seedGobelin();
      final source = sourceFile('gobelin.png', 'nouvelle');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Ennemi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('gobelin'));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('editeur-importer-spritePath'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(
        File('$root/assets/data/enemies/gobelin/sprite.png').readAsStringSync(),
        'nouvelle',
      );
      // Le chemin reste celui que l'ecrivain calcule, jamais celui du fichier
      // importe (spec §6.14).
      expect(
        jsonDecode(File('$root/assets/data/enemies/gobelin/enemy.json')
            .readAsStringSync()),
        containsPair('spritePath', 'assets/data/enemies/gobelin/sprite.png'),
      );
    });

    testWidgets('un fichier choisi apres un changement d entite est ignore',
        (tester) async {
      seedGobelin();
      final source = sourceFile('gobelin.png', 'nouvelle');
      final picker = _PendingPicker();
      await tester.pumpWidget(harness(projectRoot: root, picker: picker));
      await tester.tap(find.text('Ennemi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('gobelin'));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('editeur-importer-spritePath'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      // Le selecteur est encore ouvert : l usager change de formulaire
      // pendant ce temps, comme le permet un dialogue non bloquant sous
      // Windows et Linux (lockParentWindow ne concerne pas ce faux
      // selecteur, mais reproduit le meme delai).
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      picker.completer.complete(source);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');
      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('à importer'), findsNothing);
    });

    testWidgets(
        'un fichier choisi apres une creation qui referme la branche est '
        'ignore', (tester) async {
      // L'icone d'une classe, et non le sprite d'un ennemi : une image
      // obligatoire ne relit ni le document ni le descripteur au reveil, et
      // passait donc sans lever. L'icone optionnelle, elle, relisait les deux
      // alors que plus aucune categorie n'etait choisie.
      final source = sourceFile('icone.png', 'nouvelle');
      final picker = _PendingPicker();
      await tester.pumpWidget(harness(projectRoot: root, picker: picker));
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'barde');
      await tester.pump();

      final button = find.byKey(const Key('editeur-importer-iconPath'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();

      // Le selecteur est encore ouvert quand la creation est ecrite, et la
      // branche se referme.
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();
      expect(find.text('Créer'), findsNothing);

      picker.completer.complete(source);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'un son importe puis efface par la vue brute n est ni copie ni '
        'declare', (tester) async {
      File('$root/assets/data/audio.json').writeAsStringSync(audio);
      final source = sourceFile('clang.wav', 'octets');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Relique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editeur-id')), 'talisman');

      await importSound(tester, 'talisman_clang');

      final toggle = find.byKey(const Key('editeur-bascule-json'));
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final box = find.byKey(const Key('editeur-json-brut'));
      final withoutSfx = jsonDecode(
        tester.widget<TextField>(box).controller!.text,
      ) as Map<String, dynamic>;
      withoutSfx.remove('sfx');
      await tester.enterText(box, jsonEncode(withoutSfx));

      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      final written = jsonDecode(
        File('$root/assets/data/relics/talisman.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(written.containsKey('sfx'), isFalse);
      expect(Directory('$root/assets/audio').existsSync(), isFalse);
      expect(
        File('$root/assets/data/audio.json').readAsStringSync(),
        audio,
      );
    });

    testWidgets('importer une icone de classe ecrit iconPath', (tester) async {
      Directory('$root/assets/data/classes/mage/cards')
          .createSync(recursive: true);
      File('$root/assets/data/classes/mage/mage.png')
          .writeAsStringSync('carte');
      File('$root/assets/data/classes/mage/class.json').writeAsStringSync(
        jsonEncode({
          'id': 'mage',
          'name_fr': 'Mage',
          'name_en': 'Mage',
          'description_fr': '.',
          'description_en': '.',
          'classCard': 'assets/data/classes/mage/mage.png',
          'maxHp': 100,
          'maxMana': 3,
          'baseDamage': 5,
          'displayOrder': 1,
          'themeColor': '#9C27B0',
          'skills': <String>[],
        }),
      );
      final source = sourceFile('icone.png', 'nouvelle icone');
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(source)));
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mage'));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('editeur-importer-iconPath'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Écrire'));
      await tester.pumpAndSettle();

      expect(
        jsonDecode(
          File('$root/assets/data/classes/mage/class.json').readAsStringSync(),
        ),
        containsPair('iconPath', 'assets/data/classes/mage/icon.png'),
      );
      expect(
        File('$root/assets/data/classes/mage/icon.png').readAsStringSync(),
        'nouvelle icone',
      );
    });

    testWidgets(
        'une faute d import de classe n est pas repetee par ses cartes',
        (tester) async {
      // `EntityValidator` juge un import en attente contre chaque brouillon,
      // carte de signature comprise : sans le filtre de `_judge`, ce fichier
      // introuvable serait rapporte une fois pour la classe, et une fois de
      // plus, taguee « carte 1 : », pour sa seule carte.
      final missing = '$root/import/introuvable.png';
      await tester.pumpWidget(
          harness(projectRoot: root, picker: _FakePicker(missing)));
      await tester.tap(find.text('Classe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Créer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
      await tester.enterText(
          find.byKey(const Key('editeur-nombre-cartes')), '1');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('editeur-carte-0-id')), 'bluff');

      final button = find.byKey(const Key('editeur-importer-classCard'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(
        inIssue(find.textContaining('fichier introuvable')),
        findsOneWidget,
      );
      expect(inIssue(find.textContaining('carte 1 :')), findsNothing);
    });
  });
}

/// `IoContentFileSystem` moins le lancement de processus.
///
/// Le disque reste reel — c est tout l interet d un bac a sable — mais
/// `sync_assets` n est pas relance. Deux raisons : sa duree, un `dart run`
/// par ecriture ; et surtout le fait que `Process.run` prend le bac a sable
/// comme repertoire de travail, que Windows refuse ensuite de supprimer tant
/// que le processus vit. Le `tearDown` echouerait par intermittence.
/// L enchainement reel avec `sync_assets` est couvert par
/// `test/unit/content_editor/entity_writer_test.dart`.
class _NoProcessFileSystem implements ContentFileSystem {
  const _NoProcessFileSystem();

  static const ContentFileSystem _disk = IoContentFileSystem();

  @override
  String get startDirectory => _disk.startDirectory;

  @override
  bool fileExists(String path) => _disk.fileExists(path);

  @override
  bool directoryExists(String path) => _disk.directoryExists(path);

  @override
  String readFile(String path) => _disk.readFile(path);

  @override
  Uint8List readBytes(String path) => _disk.readBytes(path);

  @override
  void writeFile(String path, String contents) =>
      _disk.writeFile(path, contents);

  @override
  void deleteFile(String path) => _disk.deleteFile(path);

  @override
  void createDirectory(String path) => _disk.createDirectory(path);

  @override
  void copyFile(String from, String to) => _disk.copyFile(from, to);

  @override
  List<String> listDirectory(String path) => _disk.listDirectory(path);

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) async =>
      const ProcessOutcome(0, '');
}

/// Compte ce que l ecran demande au disque.
///
/// Deux compteurs, parce que le defaut avait deux visages : `listDirectory`
/// pour l enumeration d une arborescence entiere, `readFile` pour le
/// `class.json` relu bouton par bouton.
class _CountingFileSystem implements ContentFileSystem {
  _CountingFileSystem();

  static const ContentFileSystem _inner = _NoProcessFileSystem();

  int listings = 0;
  int reads = 0;

  @override
  String get startDirectory => _inner.startDirectory;

  @override
  bool fileExists(String path) => _inner.fileExists(path);

  @override
  bool directoryExists(String path) => _inner.directoryExists(path);

  @override
  String readFile(String path) {
    reads++;
    return _inner.readFile(path);
  }

  @override
  Uint8List readBytes(String path) {
    reads++;
    return _inner.readBytes(path);
  }

  @override
  void writeFile(String path, String contents) =>
      _inner.writeFile(path, contents);

  @override
  void deleteFile(String path) => _inner.deleteFile(path);

  @override
  void createDirectory(String path) => _inner.createDirectory(path);

  @override
  void copyFile(String from, String to) => _inner.copyFile(from, to);

  @override
  List<String> listDirectory(String path) {
    listings++;
    return _inner.listDirectory(path);
  }

  @override
  Future<ProcessOutcome> run(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
  }) =>
      _inner.run(executable, arguments, workingDirectory: workingDirectory);
}

/// Rend toujours le meme chemin, sans ouvrir de fenetre.
class _FakePicker implements AssetPicker {
  const _FakePicker(this.path);

  final String? path;

  @override
  Future<String?> pickFile({required List<String> extensions}) async => path;
}

/// Ne se resout que lorsque le test l'y invite : reproduit un selecteur de
/// fichier encore ouvert pendant que l usager continue a manipuler l ecran —
/// c'est le cas reel sous Windows et Linux, ou la fenetre ne bloque pas
/// celle de Flutter.
class _PendingPicker implements AssetPicker {
  final completer = Completer<String?>();

  @override
  Future<String?> pickFile({required List<String> extensions}) =>
      completer.future;
}
