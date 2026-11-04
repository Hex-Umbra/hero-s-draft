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
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';
import 'package:roguelike_card_game/ui/screens/content_editor_screen.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/property_row.dart';

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
    // Une classe creee ecrit desormais son passif de depart dans la meme
    // transaction (tache 2) : le dossier plat doit deja exister, comme celui
    // des reliques ci-dessus — l'ecrivain ne cree que les dossiers de classe
    // et d'ennemi, jamais ceux d'une categorie a plat.
    Directory('$root/assets/data/passives').createSync(recursive: true);
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

  /// Une carte neutre et deux classes colorees, chacune portant une
  /// signature. Le bleu du paladin compte : c'est sur lui que le seuil de
  /// `ThemeData.estimateBrightnessForColor` laisserait un texte blanc, a
  /// 3,1:1.
  void seedOwners() {
    Directory('$root/assets/data/cards').createSync(recursive: true);
    File('$root/assets/data/cards/frappe.json').writeAsStringSync('{}');
    for (final (id, color, signature) in const [
      ('mage', '#9C27B0', 'eclair'),
      ('paladin', '#2196F3', 'bouclier'),
    ]) {
      Directory('$root/assets/data/classes/$id/skills')
          .createSync(recursive: true);
      File('$root/assets/data/classes/$id/skills/$signature.json')
          .writeAsStringSync('{}');
      File('$root/assets/data/classes/$id/class.json').writeAsStringSync(
        '{"id":"$id","name_fr":"$id","name_en":"$id",'
        '"description_fr":".","description_en":".",'
        '"classCard":"assets/data/classes/$id/$id.png",'
        '"themeColor":"$color","maxHp":100,"maxMana":3}',
      );
    }
  }

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
    // `relics` et `passives` : les deux dossiers a plat que le setUp
    // pre-seme, le second depuis que la recette de classe ecrit un passif de
    // depart (tache 2) — aucun n'a bouge, rien d'autre n'est apparu.
    expect(Directory('$root/assets/data').listSync(), hasLength(2));
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

  testWidgets('creer une classe ecrit ses signatures et referme skills',
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
      File('$root/assets/data/classes/gambler/skills/bluff.json').existsSync(),
      isTrue,
    );
    // L'emplacement de l'icone, garde par defaut, est ecrit.
    expect(classJson['iconPath'], 'assets/data/classes/gambler/icon.png');
  });

  testWidgets('creer une classe ecrit aussi son passif de depart',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Sans une seule signature : le passif est ecrit par la recette elle-meme,
    // pas par ce que l'auteur pense a saisir.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // La recette ecrit ce passif, mais aucune carte : la classe creee n'a de
    // passif jouable qu'une fois une carte de lot de ce passif ecrite
    // (categorie `lotCard`). Jusque-la, sa selection n'offre aucun passif.
    final passif = File('$root/assets/data/passives/gambler.json');
    expect(passif.existsSync(), isTrue);

    final json = jsonDecode(passif.readAsStringSync()) as Map<String, dynamic>;
    expect(json['id'], 'gambler');
    // Il ne vise que la classe creee : la recette remplace le `["paladin"]`
    // du gabarit (sans `classes`, le chargement echoue, A5).
    expect(json['classes'], ['gambler']);
    // Sa prose est voyante, jamais inventee.
    expect(json['name_fr'], startsWith(kProsePlaceholderPrefix));

    // Et la classe est ecrite avant lui, sans quoi la reference serait
    // pendante sur le disque.
    expect(
      File('$root/assets/data/classes/gambler/class.json').existsSync(),
      isTrue,
    );
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
      'deux signatures identiques sont refusees, rien n est ecrit',
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
    expect(inIssue(find.textContaining('deux signatures')),
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

    testWidgets('Valider voit le doublon de signatures',
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
      expect(inIssue(find.textContaining('deux signatures')),
          findsOneWidget);
    });

    testWidgets('Valider voit la signature non nommee',
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
      // L'identifiant de la signature reste vide : le brouillon de classe seul
      // est pourtant parfaitement valide, et c'est exactement le piege.

      await tester.tap(find.text('Valider'));
      await tester.pump();

      expect(inIssue(find.textContaining('un identifiant est requis')),
          findsOneWidget);
      // La faute est celle de la signature : la rangee `id` de la classe, dont
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

    testWidgets('choisir une signature la charge depuis son dossier',
        (tester) async {
      seedOwners();
      File('$root/assets/data/classes/mage/skills/eclair.json')
          .writeAsStringSync(
        '{"id":"eclair","name_fr":"Éclair","name_en":"Bolt",'
        '"description_fr":".","description_en":".","cost":5,"cooldown":2,'
        '"type":"attack","effects":[{"type":"damage","value":77}]}',
      );
      await tester.pumpWidget(harness(projectRoot: root));
      await tester.tap(find.text('Signature'));
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
      // Dix onglets de type : la barre prend une ligne de plus que neuf, et le
      // formulaire de ces deux tests, serre sur 600 de haut, deborderait.
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
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
      // Dix onglets de type : la barre prend une ligne de plus que neuf, et le
      // formulaire de ces deux tests, serre sur 600 de haut, deborderait.
      tester.view.physicalSize = const Size(800, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Directory('$root/assets/data/classes/mage/skills')
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
          'mightTargets': ['attack'],
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
        'une faute d import de classe n est pas repetee par ses signatures',
        (tester) async {
      // `EntityValidator` juge un import en attente contre chaque brouillon,
      // signature comprise : sans le filtre de `_judge`, ce fichier
      // introuvable serait rapporte une fois pour la classe, et une fois de
      // plus, taguee « signature 1 : », pour sa seule signature.
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
      expect(inIssue(find.textContaining('signature 1 :')), findsNothing);
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
