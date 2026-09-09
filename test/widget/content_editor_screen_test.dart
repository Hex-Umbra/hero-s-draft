import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_editor_providers.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system_io.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';

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

  Widget harness({required String? projectRoot}) {
    return ProviderScope(
      overrides: [
        contentFileSystemProvider
            .overrideWithValue(const _NoProcessFileSystem()),
        projectRootProvider.overrideWithValue(projectRoot),
      ],
      child: const MaterialApp(home: ContentEditorScreen()),
    );
  }

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
    await tester.pumpWidget(harness(projectRoot: root));

    await tester.tap(find.text('Relique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ennemi'));
    await tester.pumpAndSettle();

    // Le niveau 1 est bien la, mais reinitialise : plus aucune branche ouverte
    // en dessous.
    expect(find.text('Créer'), findsOneWidget);
    expect(find.text('talisman_de_fer'), findsNothing);
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

    Color? backgroundOf(String label) {
      final button = tester.widget<Container>(
        find.ancestor(
          of: find.text(label),
          matching: find.byKey(const Key('editeur-bouton-fond')),
        ),
      );
      return (button.decoration as BoxDecoration?)?.color;
    }

    // Sans cette assertion, la couleur pourrait etre uniforme et le test
    // passerait quand meme : c'est la *difference* qui porte l'information.
    expect(backgroundOf('eclair'), isNot(backgroundOf('frappe')));
    expect(backgroundOf('eclair'), const Color(0xFF9C27B0));
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

    expect(find.textContaining('minuscules'), findsOneWidget);
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

    expect(find.textContaining('minuscules'), findsOneWidget);
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
    expect(find.textContaining('Relancer'), findsOneWidget);
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
    expect(find.textContaining('deux cartes de signature'), findsOneWidget);
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
      expect(find.textContaining('deux cartes de signature'), findsOneWidget);
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

      expect(find.textContaining('un identifiant est requis'), findsOneWidget);
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

  testWidgets('le passif se choisit dans le catalogue, pas dans l usage',
      (tester) async {
    // Un passif present sur le disque qu'aucune classe n'emploie : le cas que
    // `knownValues`, qui liste les valeurs *employees*, manquerait.
    Directory('$root/assets/data/passives').createSync(recursive: true);
    File('$root/assets/data/passives/chance_du_joueur.json')
        .writeAsStringSync('{}');

    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    expect(find.text('chance_du_joueur'), findsWidgets);
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

  group('mode Modifier', () {
    /// Une relique deja sur le disque, portant **une cle que le gabarit n a
    /// pas** et des valeurs enumerees differentes des siennes. C est ce que
    /// « Modifier » doit conserver : sans relecture du fichier, `compose()`
    /// ecrit la mecanique du gabarit par-dessus, et tout ce qui n y figure
    /// pas disparait — validation passee, ecriture reussie, aucun signal.
    void seedRelic() {
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

    testWidgets('Ecrire sans avoir charge est refuse, sans rien ecrire',
        (tester) async {
      seedRelic();
      final before = _dataTreeSnapshot(root);
      await tester.pumpWidget(harness(projectRoot: root));
      await aimAtSeededRelic(tester);

      // Le geste que le bouton Charger rend indispensable : la boite JSON
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
      // Le formulaire tient : la boite JSON porte toujours le gabarit.
      expect(find.textContaining('startOfCombat'), findsOneWidget);
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
          'maxHp': 100,
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
      expect(find.textContaining('"maxHp": 100'), findsOneWidget);
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
