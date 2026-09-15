# Éditeur de contenu — habillage « éditeur » — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** donner à l'éditeur de contenu (menu debug) l'apparence d'un vrai éditeur — barre d'outils, explorateur, sections, grille de propriétés, barre d'actions fixe, panneau Référence — sans toucher à sa logique.

**Architecture:** d'abord des briques présentationnelles autonomes et testées (tâches 1 à 6), chacune laissant la suite verte ; puis une seule tâche d'intégration (tâche 7) qui recompose l'écran avec elles, retire l'arbre `TreeLevel` et ajuste les tests d'écran dont la structure observée disparaît.

**Tech Stack:** Flutter 3.41.6 / Dart 3.11, Riverpod 2.x, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-09-15-editeur-de-contenu-habillage-editeur-design.md`

## Global Constraints

- **Aucune logique touchée** : `lib/services/content_editor/` ne change pas. Seuls `lib/ui/` et `test/widget/` changent. Aucune donnée de `assets/data/` n'est modifiée.
- **`dart analyze` doit être propre — zéro problème — après chaque tâche.**
- **Ne jamais lancer `dart format`** : le dépôt n'y a jamais été passé. Le code nouveau suit son voisinage (deux espaces, virgules finales, lignes ≤ 80 colonnes quand c'est raisonnable).
- **Un test doit pouvoir échouer** : écrit d'abord, vu rouge, rendu vert. `flutter test test/widget/content_editor_screen_test.dart test/widget/content_editor/` doit passer à la fin de **chaque** tâche ; la suite complète `flutter test` à la fin de la tâche 7.
- **Les libellés visibles et les clés `editeur-*` existants sont conservés** (spec D11) : `Créer`, `Modifier`, `Charger`, `Valider`, `Écrire`, les sept libellés de type, `aucun`, `aucune`, `Importer…`, `Ajouter`, `Valider la couleur`, et toutes les `Key('editeur-…')` déjà présentes. Aucun nouveau texte ne doit **égaler exactement** l'un de ces libellés.
- **Contrat de choix** (spec D9) : tout élément sélectionnable peint son libellé sur un fond **opaque** porté par un `Container(key: Key('editeur-bouton-fond'))`, lisible à 4,5:1 (texte et icônes), expose `Semantics(container: true, button: true, selected: …)`, et marque sa sélection autrement que par la couleur.
- **Couleurs** : uniquement `AppColors` et `EditorColors` (créé en tâche 1). Pas de nouvelle police : `monospace` avec repli `Consolas`, `Menlo`, `Roboto Mono`.
- **Pas de `ListView`** dans le formulaire ni l'explorateur : un `ListView` ne construit pas ses enfants hors écran, et les tests les cherchent. `SingleChildScrollView` + `Column`.
- **`PropertyLabel` exige une largeur bornée** (il contient un `Flexible`) : dans une `Row`, l'envelopper dans `Flexible` ou `SizedBox`.
- Commentaires de code en français **sans accent**, comme le voisinage ; libellés d'écran en français accentué, sans clé ARB (exception bornée à l'éditeur).
- **Commits** : un commit par tâche sur la branche courante `feat/menu-debug-lot-2`, jamais de push. Message en français, conventional commits, sujet sans accent (`feat(editeur): …`, `test(editeur): …`), corps terminé par `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- `assets/data/patch_notes.json` et `.obsidian_vault/` ne sont pas touchés par ce plan.
- Suite complète : `flutter test`. Un fichier : `flutter test <chemin>`. Un test : `flutter test <chemin> --plain-name "<nom>"`.

---

## Structure des fichiers

Tous sous `lib/ui/widgets/content_editor/` sauf mention.

**Créés**

| Fichier | Tâche | Responsabilité |
|:---|:---|:---|
| `editor_style.dart` | 1 | `EditorColors`, `editorMono`, `kCategoryIcons`, `kRarityColors`, `editorInputDecoration` |
| `dashed_border.dart` | 1 | `DashedBorder` — cadre en pointillés |
| `editor_panel.dart` | 1 | `EditorPanel` (section titrée), `separatedRows` |
| `property_row.dart` | 1 | `PropertyLabel`, `FieldError`, `PropertyRow` |
| `editor_button.dart` | 1 | `EditorButton`, `EditorButtonTone` |
| `field_anchors.dart` | 1 | `FieldAnchors` — ancres des champs pour le saut depuis une faute |
| `editor_segmented.dart` | 2 | `EditorSegment<T>`, `EditorSegmented<T>` |
| `form_blocks.dart` | 4 | `NumberGrid`, `ElementCard`, `AddElementButton`, `CountBadge`, `LangBadge`, `summaryOf` |
| `editor_app_bar.dart` | 5 | `EditorAppBar`, `shortRoot` |
| `editor_toolbar.dart` | 5 | `EditorToolbar` (onglets de type) |
| `entity_explorer.dart` | 5 | `EntityExplorer` (mode Modifier) |
| `reference_panel.dart` | 6 | `ReferencePanel` (valeurs déjà utilisées) |
| `editor_action_bar.dart` | 6 | `EditorActionBar`, `OutcomeBanner`, `outcomeBannerFor` |

**Modifiés**

| Fichier | Tâche | Ce qui change |
|:---|:---|:---|
| `choice_button.dart` | 2 (puis 7) | puce restylée, `tint`, `isPlaceholder`, `Semantics` ; `imagePath` retiré en 7 |
| `asset_field.dart`, `color_field.dart` | 3 | rangée de propriété, vignette sur damier, boutons de l'éditeur ; `AssetField.errorText` |
| `document_form.dart` | 4 (puis 7) | rangées, grille de nombres, sous-panneaux, fautes et ancres ; ressources retirées en 7 |
| `entity_form.dart` | 7 | réécrit : en-tête de fichier et sections, sans boutons ni issue |
| `lib/ui/screens/content_editor_screen.dart` | 7 | recomposé : barre de titre, barre d'outils, explorateur, formulaire, barre d'actions, référence |
| `tree_level.dart` | 7 | **supprimé** |
| `test/widget/content_editor/contrast.dart` | 2 | `expectReadableChoice` |

**Tests créés** (sous `test/widget/content_editor/`) : `editor_primitives_test.dart` (1), `choice_button_test.dart`, `editor_segmented_test.dart` (2), `editor_toolbar_test.dart`, `entity_explorer_test.dart` (5), `reference_panel_test.dart`, `editor_action_bar_test.dart` (6).

---

## Task 1 : les jetons et les briques de base

**Files:**
- Create: `lib/ui/widgets/content_editor/editor_style.dart`
- Create: `lib/ui/widgets/content_editor/dashed_border.dart`
- Create: `lib/ui/widgets/content_editor/editor_panel.dart`
- Create: `lib/ui/widgets/content_editor/property_row.dart`
- Create: `lib/ui/widgets/content_editor/editor_button.dart`
- Create: `lib/ui/widgets/content_editor/field_anchors.dart`
- Test: `test/widget/content_editor/editor_primitives_test.dart`

**Interfaces:**
- Consumes: `AppColors` (`lib/ui/theme/app_colors.dart`), `EntityCategory` (`lib/services/content_editor/entity_descriptor.dart`).
- Produces (utilisés par toutes les tâches suivantes) :
  - `abstract final class EditorColors` — `side`, `bar`, `panel`, `panelHead`, `well`, `chip`, `chipBorder`, `line`, `lineStrong`, `keyText`, `soft`, `muted`, `faint`, `accent`, `accentInk`, `debug` (tous `static const Color`).
  - `TextStyle editorMono({double size = 12.5, Color color = EditorColors.keyText, FontWeight? weight})`
  - `const Map<EntityCategory, IconData> kCategoryIcons`, `const Map<String, Color> kRarityColors`
  - `InputDecoration editorInputDecoration({String? hintText, bool hasError = false})`
  - `DashedBorder({Key? key, required Widget child, required Color color, double radius = 9})`
  - `List<Widget> separatedRows(List<Widget> rows)`
  - `EditorPanel({Key? key, required IconData icon, required String title, required List<Widget> children, String? caption, Widget? trailing})`
  - `PropertyLabel({Key? key, required String label, bool isRequired = false, String? note, bool hasError = false})` — le point obligatoire porte `Key('editeur-obligatoire')`.
  - `FieldError(String message, {Key? key})`
  - `PropertyRow({Key? key, required String label, required Widget child, bool isRequired = false, String? note, String? errorText, bool alignTop = false, double labelWidth = 170})`
  - `enum EditorButtonTone { quiet, outlined, primary }`, `EditorButton({Key? key, required String label, required IconData icon, required VoidCallback? onPressed, EditorButtonTone tone = EditorButtonTone.outlined, bool dense = false})`
  - `class FieldAnchors { GlobalKey keyFor(String field); Future<void> reveal(String field); }`

- [ ] **Step 1: Écrire les tests (rouges)**

Créer `test/widget/content_editor/editor_primitives_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_panel.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/field_anchors.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/property_row.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(1000, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: child),
    ));
  }

  const control = SizedBox(key: Key('controle'), width: 120, height: 30);

  group('PropertyRow', () {
    testWidgets('la cle se tient a gauche du controle quand la place le permet',
        (tester) async {
      await pump(tester, const PropertyRow(label: 'maxHp', child: control));

      final label = tester.getTopLeft(find.text('maxHp'));
      final field = tester.getTopLeft(find.byKey(const Key('controle')));
      expect(field.dx, greaterThanOrEqualTo(label.dx + 170));
    });

    testWidgets('la cle passe au-dessus quand le controle manque de place',
        (tester) async {
      await pump(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: PropertyRow(label: 'maxHp', child: control),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(const Key('controle'))).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.text('maxHp')).dy),
      );
    });

    testWidgets('un champ obligatoire porte son point, un autre non',
        (tester) async {
      await pump(
        tester,
        const PropertyRow(label: 'cost', isRequired: true, child: control),
      );
      expect(find.byKey(const Key('editeur-obligatoire')), findsOneWidget);

      await pump(tester, const PropertyRow(label: 'luck', child: control));
      expect(find.byKey(const Key('editeur-obligatoire')), findsNothing);
    });

    testWidgets('une faute rougit la cle et s affiche sous le controle',
        (tester) async {
      await pump(
        tester,
        const PropertyRow(
          label: 'cost',
          errorText: 'champ obligatoire absent',
          child: control,
        ),
      );

      expect(tester.widget<Text>(find.text('cost')).style!.color,
          AppColors.danger);
      expect(
        tester.getTopLeft(find.text('champ obligatoire absent')).dy,
        greaterThan(tester.getBottomLeft(find.byKey(const Key('controle'))).dy),
      );
    });

    testWidgets('une mention accompagne la cle', (tester) async {
      await pump(
        tester,
        const PropertyRow(label: 'iconPath', note: 'optionnel', child: control),
      );
      expect(find.text('optionnel'), findsOneWidget);
    });
  });

  testWidgets('un panneau se titre en capitales, avec precision et controle',
      (tester) async {
    await pump(
      tester,
      const EditorPanel(
        icon: Icons.tune,
        title: 'Mécanique',
        caption: 'précision',
        trailing: Text('bascule'),
        children: [Text('rangée 1'), Text('rangée 2')],
      ),
    );

    expect(find.text('MÉCANIQUE'), findsOneWidget);
    expect(find.text('précision'), findsOneWidget);
    expect(find.text('bascule'), findsOneWidget);
    // Un filet sous l'en-tete, un entre les deux rangees.
    expect(find.byType(Divider), findsNWidgets(2));
  });

  group('EditorButton', () {
    testWidgets('un bouton actif appelle son geste', (tester) async {
      var taps = 0;
      await pump(
        tester,
        Center(
          child: EditorButton(
            label: 'Valider',
            icon: Icons.fact_check,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.text('Valider'));
      expect(taps, 1);
    });

    testWidgets('le geste principal est le seul bouton plein', (tester) async {
      await pump(
        tester,
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EditorButton(
                label: 'Valider',
                icon: Icons.fact_check,
                onPressed: () {},
              ),
              EditorButton(
                label: 'Écrire',
                icon: Icons.save,
                tone: EditorButtonTone.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      Color fillOf(String label) => (tester
              .widget<Container>(find
                  .ancestor(of: find.text(label), matching: find.byType(Container))
                  .first)
              .decoration! as BoxDecoration)
          .color!;
      expect(fillOf('Écrire'), EditorColors.accent);
      expect(fillOf('Valider').a, lessThan(1));
    });
  });

  group('FieldAnchors', () {
    testWidgets('une ancre ramene son champ dans la vue', (tester) async {
      final anchors = FieldAnchors();
      await pump(
        tester,
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 3000),
              KeyedSubtree(
                key: anchors.keyFor('value'),
                child: const SizedBox(key: Key('champ'), height: 40, width: 100),
              ),
            ],
          ),
        ),
        size: const Size(800, 600),
      );
      expect(tester.getTopLeft(find.byKey(const Key('champ'))).dy,
          greaterThan(600));

      final revealed = anchors.reveal('value');
      await tester.pumpAndSettle();
      await revealed;

      expect(tester.getTopLeft(find.byKey(const Key('champ'))).dy,
          inInclusiveRange(0, 560));
    });

    testWidgets('une ancre sans champ ne leve rien', (tester) async {
      await pump(tester, const SizedBox());
      await expectLater(FieldAnchors().reveal('absent'), completes);
    });
  });
}
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/editor_primitives_test.dart`
Expected: FAIL à la compilation — `editor_button.dart`, `editor_panel.dart`, … introuvables.

- [ ] **Step 3: Écrire `editor_style.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';

/// Les couleurs de l'editeur de contenu (spec D10), tirees d'`AppColors` quand
/// le jeu les porte deja. Propres a cet ecran : le reste du jeu n'a ni puits
/// de saisie ni panneaux d'inspecteur.
abstract final class EditorColors {
  /// Barre d'outils, explorateur, panneau de reference.
  static const Color side = Color(0xFF10101F);

  /// Barre de titre, barre d'actions.
  static const Color bar = Color(0xFF13132A);
  static const Color panel = AppColors.surfaceDark;
  static const Color panelHead = Color(0xFF1E1E36);

  /// Le fond d'une saisie.
  static const Color well = Color(0xFF0E0E1C);
  static const Color chip = Color(0xFF16162A);
  static const Color chipBorder = Color(0xFF45456A);
  static const Color line = Color(0xFF26263E);
  static const Color lineStrong = AppColors.darkBorder;
  static const Color keyText = Color(0xFFAFC0C9);
  static const Color soft = Color(0xFFC5D0D6);
  static const Color muted = AppColors.textSecondary;

  /// Le plus discret des textes encore lisibles : 5:1 sur `side` et `panel`.
  static const Color faint = Color(0xFF7A8E9A);
  static const Color accent = AppColors.neonBlue;
  static const Color accentInk = Color(0xFF00141B);

  /// Celle du tiroir de debug : le badge DEBUG dit la meme chose.
  static const Color debug = Colors.deepPurpleAccent;
}

/// Les cles JSON, chemins et identifiants : ce que l'auteur retrouvera tel
/// quel dans le fichier.
TextStyle editorMono({
  double size = 12.5,
  Color color = EditorColors.keyText,
  FontWeight? weight,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Consolas', 'Menlo', 'Roboto Mono'],
      fontSize: size,
      color: color,
      fontWeight: weight,
    );

/// L'icone de chaque type : dans la barre d'outils, et sur la tuile de
/// l'en-tete du fichier.
const Map<EntityCategory, IconData> kCategoryIcons = {
  EntityCategory.card: Icons.style,
  EntityCategory.relic: Icons.diamond,
  EntityCategory.passive: Icons.auto_awesome,
  EntityCategory.event: Icons.explore,
  EntityCategory.forgeUpgrade: Icons.hardware,
  EntityCategory.heroClass: Icons.shield,
  EntityCategory.enemy: Icons.pest_control,
};

/// Les couleurs de rarete du jeu, pour les options d'une cle `rarity`.
const Map<String, Color> kRarityColors = {
  'common': AppColors.rarityCommon,
  'uncommon': AppColors.rarityUncommon,
  'rare': AppColors.rarityRare,
  'epic': AppColors.rarityEpic,
  'legendary': AppColors.rarityLegendary,
  'unique': AppColors.rarityUnique,
};

/// Le puits d'une saisie : fond sombre, bord qui s'allume au focus, rouge
/// quand une faute vise le champ. Le message, lui, est affiche par la rangee
/// (`PropertyRow`), jamais par le champ.
InputDecoration editorInputDecoration({
  String? hintText,
  bool hasError = false,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(color: color, width: width),
      );
  final rest = hasError ? AppColors.danger : EditorColors.lineStrong;
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: EditorColors.faint),
    isDense: true,
    filled: true,
    fillColor: EditorColors.well,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(rest, 1),
    enabledBorder: border(rest, 1),
    focusedBorder:
        border(hasError ? AppColors.danger : EditorColors.accent, 1.5),
  );
}
```

- [ ] **Step 4: Écrire `dashed_border.dart`**

```dart
import 'package:flutter/material.dart';

/// Un cadre en pointilles : ce qui reste a remplir — un emplacement d'image
/// vide, le geste « Ajouter ».
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 9,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedOutlinePainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 5;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius))
            .deflate(0.5),
      );
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
```

- [ ] **Step 5: Écrire `editor_panel.dart`**

```dart
import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Des rangees separees d'un filet : les champs d'un panneau, ceux d'un
/// element de liste.
List<Widget> separatedRows(List<Widget> rows) => [
      for (var i = 0; i < rows.length; i++) ...[
        if (i > 0)
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
        rows[i],
      ],
    ];

/// Une section du formulaire (spec D4) : un en-tete titre, puis ses rangees.
class EditorPanel extends StatelessWidget {
  const EditorPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.caption,
    this.trailing,
  });

  final IconData icon;

  /// Affiche en capitales espacees, comme `PageHeader`.
  final String title;
  final List<Widget> children;

  /// Une precision discrete, a droite de l'en-tete.
  final String? caption;

  /// Un controle d'en-tete : la bascule JSON, le nombre de cartes.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: EditorColors.panel,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: EditorColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 42),
            padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
            color: EditorColors.panelHead,
            child: Row(
              children: [
                Icon(icon, size: 18, color: EditorColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EditorColors.soft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                if (caption != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    caption!,
                    style: const TextStyle(
                      color: EditorColors.faint,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          ...separatedRows(children),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Écrire `property_row.dart`**

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// La cle d'une propriete : son nom JSON, un point si elle est obligatoire,
/// une mention discrete (« optionnel »), rouge quand une faute la vise.
///
/// Contient un `Flexible` : a poser dans une largeur bornee.
class PropertyLabel extends StatelessWidget {
  const PropertyLabel({
    super.key,
    required this.label,
    this.isRequired = false,
    this.note,
    this.hasError = false,
  });

  final String label;
  final bool isRequired;
  final String? note;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRequired) ...[
          Semantics(
            label: 'obligatoire',
            child: Container(
              key: const Key('editeur-obligatoire'),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: EditorColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            style: editorMono(
              color: hasError ? AppColors.danger : EditorColors.keyText,
            ),
          ),
        ),
        if (note != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              border: Border.all(color: EditorColors.lineStrong),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              note!,
              style: const TextStyle(color: EditorColors.faint, fontSize: 10.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le message d'une faute, sous le champ qu'elle vise.
class FieldError extends StatelessWidget {
  const FieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error, size: 15, color: AppColors.danger),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Une rangee de l'inspecteur (spec D5) : la cle a gauche, le controle a
/// droite, et le message d'une faute sous le controle. La cle passe au-dessus
/// quand le controle n'a plus sa place a cote.
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.note,
    this.errorText,
    this.alignTop = false,
    this.labelWidth = 170,
  });

  /// Sous cette largeur, un controle ne se lit plus a cote de sa cle.
  static const double minControlWidth = 240;

  final String label;
  final Widget child;
  final bool isRequired;
  final String? note;
  final String? errorText;

  /// Pour un controle plus haut qu'une ligne : une rangee de puces, une
  /// vignette. La cle s'aligne alors sur sa premiere ligne.
  final bool alignTop;

  /// 170 au premier niveau, 110 dans un element de liste.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final error = errorText;
    final top = alignTop || error != null;
    final key = PropertyLabel(
      label: label,
      isRequired: isRequired,
      note: note,
      hasError: error != null,
    );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: FieldError(error),
          ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < labelWidth + 14 + minControlWidth) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [key, const SizedBox(height: 6), body],
            );
          }
          return Row(
            crossAxisAlignment:
                top ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: EdgeInsets.only(top: top ? 9 : 0),
                  child: key,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 7: Écrire `editor_button.dart`**

```dart
import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Le poids d'un bouton de l'editeur.
enum EditorButtonTone {
  /// Un geste secondaire : Charger, aucune.
  quiet,

  /// Un geste courant : Valider, Importer…
  outlined,

  /// Le seul geste qui engage le disque : Écrire.
  primary,
}

/// Un bouton de l'editeur, dessine comme `GameButton` — bord neon, lueur et
/// leger grossissement au survol — mais sans son d'interface : l'editeur n'est
/// pas un menu du jeu, et `GameButton` exigerait le directeur audio dans
/// chaque test.
class EditorButton extends StatefulWidget {
  const EditorButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tone = EditorButtonTone.outlined,
    this.dense = false,
  });

  final String label;
  final IconData icon;

  /// `null` : le bouton est inerte, et le montre.
  final VoidCallback? onPressed;
  final EditorButtonTone tone;

  /// Le format des gestes de champ : Importer…, aucune.
  final bool dense;

  @override
  State<EditorButton> createState() => _EditorButtonState();
}

class _EditorButtonState extends State<EditorButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final hovered = _hovered && enabled;
    final dense = widget.dense;
    const accent = EditorColors.accent;

    final Color fill;
    final Color edge;
    final Color ink;
    if (!enabled) {
      fill = Colors.white.withValues(alpha: 0.05);
      edge = EditorColors.line;
      ink = EditorColors.faint;
    } else {
      switch (widget.tone) {
        case EditorButtonTone.quiet:
          fill = hovered ? const Color(0xFF1C1C34) : Colors.transparent;
          edge = hovered ? const Color(0xFF6A6A95) : EditorColors.lineStrong;
          ink = EditorColors.soft;
        case EditorButtonTone.outlined:
          fill = accent.withValues(alpha: hovered ? 0.22 : 0.1);
          edge = hovered ? accent : accent.withValues(alpha: 0.5);
          ink = accent;
        case EditorButtonTone.primary:
          fill = hovered ? const Color(0xFF45E0FF) : accent;
          edge = accent;
          ink = EditorColors.accentInk;
      }
    }
    final glows = enabled &&
        widget.tone != EditorButtonTone.quiet &&
        (hovered || widget.tone == EditorButtonTone.primary);
    final radius = BorderRadius.circular(dense ? 7 : 11);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedScale(
        scale: hovered && !MediaQuery.disableAnimationsOf(context) ? 1.03 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: dense ? 32 : 40,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: edge, width: dense ? 1 : 2),
            boxShadow: [
              if (glows)
                BoxShadow(
                  color: accent.withValues(alpha: hovered ? 0.45 : 0.28),
                  blurRadius: hovered ? 20 : 16,
                ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: dense ? 16 : 19, color: ink),
                    SizedBox(width: dense ? 5 : 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: ink,
                        fontSize: dense ? 12.5 : 14,
                        fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Écrire `field_anchors.dart`**

```dart
import 'package:flutter/widgets.dart';

/// Les ancres des champs du formulaire, par nom de champ — celui que porte
/// `ValidationFault.field` : une cle de premier niveau (`id`), ou le libelle
/// d'un chemin (`effects[0].value`).
///
/// Une `GlobalKey` par champ, posee par le widget qui le rend : le bandeau
/// d'issue n'a qu'a demander a le revoir.
class FieldAnchors {
  final Map<String, GlobalKey> _keys = {};

  GlobalKey keyFor(String field) =>
      _keys.putIfAbsent(field, () => GlobalKey(debugLabel: field));

  /// Fait defiler le formulaire jusqu'au champ. Sans effet si aucun widget ne
  /// le porte : une faute peut viser un champ que le formulaire ne montre pas.
  Future<void> reveal(String field) async {
    final context = _keys[field]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}
```

- [ ] **Step 9: Vérifier que les tests passent**

Run: `flutter test test/widget/content_editor/editor_primitives_test.dart`
Expected: PASS, 10 tests.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add lib/ui/widgets/content_editor/editor_style.dart lib/ui/widgets/content_editor/dashed_border.dart lib/ui/widgets/content_editor/editor_panel.dart lib/ui/widgets/content_editor/property_row.dart lib/ui/widgets/content_editor/editor_button.dart lib/ui/widgets/content_editor/field_anchors.dart test/widget/content_editor/editor_primitives_test.dart
git commit -m "feat(editeur): jetons et briques de base de l habillage editeur" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 2 : les puces et le sélecteur segmenté

**Files:**
- Modify: `lib/ui/widgets/content_editor/choice_button.dart` (réécriture du `build`, deux paramètres)
- Create: `lib/ui/widgets/content_editor/editor_segmented.dart`
- Modify: `test/widget/content_editor/contrast.dart` (ajout de `expectReadableChoice`)
- Test: `test/widget/content_editor/choice_button_test.dart`, `test/widget/content_editor/editor_segmented_test.dart`

**Interfaces:**
- Consumes (tâche 1) : `EditorColors`, `editorMono`, `kRarityColors`.
- Consumes (existant) : `readableOn(Color)` et `colorToHex(Color)` de `color_field.dart`, `kNeutralOwnerColor` de `choice_button.dart`.
- Produces :
  - `ChoiceButton({Key? key, required String label, required bool isSelected, required VoidCallback onTap, Color? identityColor, Color? tint, bool isPlaceholder = false, String? imagePath})` — `imagePath` reste pour l'instant (l'arbre l'utilise encore), retiré en tâche 7.
  - `EditorSegment<T>({required T value, required String label, IconData? icon, Key? key})`
  - `EditorSegmented<T>({Key? key, required List<EditorSegment<T>> segments, required T? selected, required ValueChanged<T> onSelected, bool dense = false})` — la `EditorSegment.key` est posée sur la zone touchable du segment.
  - `void expectReadableChoice(WidgetTester tester, String label)` dans `test/widget/content_editor/contrast.dart`.

**Contexte :** `ChoiceButton` sert aujourd'hui aux niveaux de l'arbre, aux pastilles de propriétaire et aux options du formulaire. Les tests d'écran `lisibilite` (dans `test/widget/content_editor_screen_test.dart`) exigent déjà : `Container(key: Key('editeur-bouton-fond'))` au fond **opaque**, texte et coche à 4,5:1, coche sur le seul choix actif, fond d'identité conservé choisi ou non. Ils doivent rester verts sans modification.

- [ ] **Step 1: Ajouter le contrôle de lisibilité partagé**

Ajouter à la fin de `test/widget/content_editor/contrast.dart` (et les imports `package:flutter/material.dart`, `package:flutter_test/flutter_test.dart`, `package:roguelike_card_game/ui/widgets/content_editor/color_field.dart` en tête ; retirer alors l'import `package:flutter/painting.dart` devenu redondant) :

```dart
/// Le fond du choix qui porte [label] : le `Container` du contrat de choix.
Finder choiceFill(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byKey(const Key('editeur-bouton-fond')),
    );

/// Tout ce que le choix [label] ecrit — libelle, icone, coche — se lit a
/// 4,5:1 au moins sur son fond, qui doit etre opaque (WCAG AA).
void expectReadableChoice(WidgetTester tester, String label) {
  expect(choiceFill(label), findsOneWidget,
      reason: '« $label » n est pas un choix');
  final fill =
      (tester.widget<Container>(choiceFill(label)).decoration! as BoxDecoration)
          .color!;
  expect(fill.a, 1.0, reason: '« $label » doit peindre un fond opaque');
  final inks = tester.widgetList<RichText>(
    find.descendant(of: choiceFill(label), matching: find.byType(RichText)),
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
```

- [ ] **Step 2: Écrire les tests de la puce (rouges)**

Créer `test/widget/content_editor/choice_button_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<Widget> buttons) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: Wrap(children: buttons)),
      ));

  testWidgets('une puce de rarete se lit, choisie ou non, pour chaque rarete',
      (tester) async {
    for (final entry in kRarityColors.entries) {
      await pump(tester, [
        ChoiceButton(
          label: '${entry.key}-repos',
          isSelected: false,
          tint: entry.value,
          onTap: () {},
        ),
        ChoiceButton(
          label: '${entry.key}-choisie',
          isSelected: true,
          tint: entry.value,
          onTap: () {},
        ),
      ]);
      expectReadableChoice(tester, '${entry.key}-repos');
      expectReadableChoice(tester, '${entry.key}-choisie');
    }
  });

  testWidgets('une puce de rarete au repos ecrit dans la teinte de sa rarete',
      (tester) async {
    await pump(tester, [
      ChoiceButton(
        label: 'epic',
        isSelected: false,
        tint: kRarityColors['epic'],
        onTap: () {},
      ),
    ]);
    expect(
      tester.widget<Text>(find.text('epic')).style!.color,
      Color.lerp(kRarityColors['epic'], Colors.white, 0.4),
    );
  });

  testWidgets('une puce ordinaire et « aucun » se lisent, choisis ou non',
      (tester) async {
    await pump(tester, [
      ChoiceButton(label: 'attack', isSelected: false, onTap: () {}),
      ChoiceButton(label: 'skill', isSelected: true, onTap: () {}),
      ChoiceButton(
        label: 'aucun',
        isSelected: false,
        isPlaceholder: true,
        onTap: () {},
      ),
      ChoiceButton(
        label: 'mage',
        isSelected: true,
        identityColor: const Color(0xFF9C27B0),
        onTap: () {},
      ),
    ]);
    for (final label in const ['attack', 'skill', 'aucun', 'mage']) {
      expectReadableChoice(tester, label);
    }
  });

  testWidgets('seule la puce choisie porte la coche et se dit choisie',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, [
      ChoiceButton(label: 'attack', isSelected: true, onTap: () {}),
      ChoiceButton(label: 'skill', isSelected: false, onTap: () {}),
    ]);

    expect(
      find.descendant(
          of: choiceFill('attack'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: choiceFill('skill'), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(tester.getSemantics(choiceFill('attack')),
        containsSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('skill')),
        containsSemantics(isSelected: false));
    semantics.dispose();
  });
}
```

- [ ] **Step 3: Écrire les tests du segmenté (rouges)**

Créer `test/widget/content_editor/editor_segmented_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_segmented.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required String? selected,
    required ValueChanged<String> onSelected,
  }) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(
          body: Center(
            child: EditorSegmented<String>(
              selected: selected,
              onSelected: onSelected,
              segments: const [
                EditorSegment(value: 'create', label: 'Créer', icon: Icons.add),
                EditorSegment(
                  value: 'modify',
                  label: 'Modifier',
                  icon: Icons.edit,
                  key: Key('segment-modifier'),
                ),
              ],
            ),
          ),
        ),
      ));

  testWidgets('toucher un segment rappelle sa valeur', (tester) async {
    String? picked;
    await pump(tester, selected: null, onSelected: (v) => picked = v);

    await tester.tap(find.byKey(const Key('segment-modifier')));
    expect(picked, 'modify');
    await tester.tap(find.text('Créer'));
    expect(picked, 'create');
  });

  testWidgets('le segment choisi se dit choisi et porte son anneau',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selected: 'create', onSelected: (_) {});

    expect(tester.getSemantics(choiceFill('Créer')),
        containsSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('Modifier')),
        containsSemantics(isSelected: false));

    BoxBorder? ringOf(String label) =>
        (tester.widget<Container>(choiceFill(label)).decoration! as BoxDecoration)
            .border;
    expect((ringOf('Créer')! as Border).top.color,
        EditorColors.accent.withValues(alpha: 0.5));
    expect((ringOf('Modifier')! as Border).top.color, Colors.transparent);
    semantics.dispose();
  });

  testWidgets('chaque segment se lit sur son fond, choisi ou non',
      (tester) async {
    await pump(tester, selected: 'modify', onSelected: (_) {});
    expectReadableChoice(tester, 'Créer');
    expectReadableChoice(tester, 'Modifier');
  });
}
```

- [ ] **Step 4: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/choice_button_test.dart test/widget/content_editor/editor_segmented_test.dart`
Expected: FAIL à la compilation — `tint`, `isPlaceholder`, `editor_segmented.dart` inconnus.

- [ ] **Step 5: Réécrire `ChoiceButton`**

Dans `choice_button.dart`, garder `kNeutralOwnerColor` et la documentation de tête ; ajouter les imports `editor_style.dart` (et garder `color_field.dart` pour `readableOn`) ; remplacer la classe par :

```dart
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.identityColor,
    this.tint,
    this.isPlaceholder = false,
    this.imagePath,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// La couleur qui identifie le choix : [kNeutralOwnerColor] pour une entite
  /// neutre, `themeColor` de sa classe sinon. Elle reste le fond, choisi ou
  /// non, et un anneau marque alors la selection.
  final Color? identityColor;

  /// Une teinte d'option — la couleur d'une rarete. Au repos, elle colore le
  /// libelle et le bord sur le fond sombre d'une puce ; choisie, elle devient
  /// le fond.
  final Color? tint;

  /// « aucun » : l'absence de valeur, en italique tant qu'elle n'est pas
  /// choisie.
  final bool isPlaceholder;

  /// L'icone ou la carte de la classe proprietaire.
  final String? imagePath;

  static const double _radius = 6;

  @override
  Widget build(BuildContext context) {
    final identity = identityColor;
    final tint = this.tint;

    // Le texte tire sa couleur de son fond, jamais du theme (voir la note de
    // tete) : au repos teinte, il est eclairci vers le blanc pour garder
    // 4,5:1 sur le fond sombre, meme pour le violet d'une rarete epique.
    final Color fill;
    final Color ink;
    final Color edge;
    if (identity != null) {
      fill = identity;
      ink = readableOn(fill);
      edge = Colors.transparent;
    } else if (isSelected) {
      fill = tint ?? EditorColors.accent;
      ink = readableOn(fill);
      edge = Colors.transparent;
    } else if (tint != null) {
      fill = Color.alphaBlend(tint.withValues(alpha: 0.07), EditorColors.chip);
      ink = Color.lerp(tint, Colors.white, 0.4)!;
      edge = tint.withValues(alpha: 0.45);
    } else {
      fill = EditorColors.chip;
      ink = isPlaceholder ? EditorColors.muted : EditorColors.soft;
      edge = EditorColors.chipBorder;
    }
    final labelStyle = isPlaceholder && !isSelected
        ? TextStyle(color: ink, fontSize: 12.5, fontStyle: FontStyle.italic)
        : editorMono(
            color: ink,
            weight: isSelected ? FontWeight.w700 : FontWeight.w500,
          );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: Container(
        // L'anneau d'un choix d'identite, separe du bouton par le fond de
        // l'ecran : il se detache de toute couleur de classe. Sa place est
        // gardee au repos, pour que choisir ne decale pas la rangee.
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_radius + 4),
          border: Border.all(
            color: identity != null && isSelected
                ? EditorColors.accent
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Container(
            key: const Key('editeur-bouton-fond'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: edge),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check, size: 15, color: ink),
                  const SizedBox(width: 5),
                ],
                if (imagePath != null) ...[
                  ClipOval(
                    child: Image.asset(
                      imagePath!,
                      width: 16,
                      height: 16,
                      fit: BoxFit.cover,
                      // Un placeholder absent ne doit pas faire tomber l'ecran.
                      errorBuilder: (_, _, _) => const SizedBox(width: 16),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(label, style: labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

Mettre à jour le commentaire de tête de la classe pour citer le contrat de choix (spec D9) au lieu du seul libellé gras.

- [ ] **Step 6: Écrire `editor_segmented.dart`**

```dart
import 'package:flutter/material.dart';

import 'editor_style.dart';

/// Un segment d'[EditorSegmented].
@immutable
class EditorSegment<T> {
  const EditorSegment({
    required this.value,
    required this.label,
    this.icon,
    this.key,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// Posee sur la zone touchable du segment.
  final Key? key;
}

/// Un choix exclusif entre quelques valeurs voisines : Créer / Modifier,
/// Formulaire / JSON.
///
/// Suit le contrat de choix (spec D9) : chaque segment peint un fond opaque de
/// cle `editeur-bouton-fond`, se dit choisi a l'accessibilite, et marque sa
/// selection d'un anneau en plus de la couleur.
class EditorSegmented<T> extends StatelessWidget {
  const EditorSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelected,
    this.dense = false,
  });

  final List<EditorSegment<T>> segments;

  /// `null` : aucun segment choisi.
  final T? selected;

  /// Rappele aussi pour le segment deja choisi : a l'appelant de l'ignorer.
  final ValueChanged<T> onSelected;

  /// Le format d'un en-tete de panneau.
  final bool dense;

  static final Color _selectedFill = Color.alphaBlend(
    EditorColors.accent.withValues(alpha: 0.14),
    EditorColors.well,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 2 : 3),
      decoration: BoxDecoration(
        color: EditorColors.well,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            _segment(segments[i]),
          ],
        ],
      ),
    );
  }

  Widget _segment(EditorSegment<T> segment) {
    final isSelected = segment.value == selected;
    final ink = isSelected ? EditorColors.accent : EditorColors.muted;
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        key: segment.key,
        onTap: () => onSelected(segment.value),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          key: const Key('editeur-bouton-fond'),
          padding: EdgeInsets.symmetric(
            horizontal: dense ? 10 : 12,
            vertical: dense ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: isSelected ? _selectedFill : EditorColors.well,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? EditorColors.accent.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: dense ? 15 : 17, color: ink),
                const SizedBox(width: 6),
              ],
              Text(
                segment.label,
                style: TextStyle(
                  color: ink,
                  fontSize: dense ? 12 : 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Vérifier que tout passe**

Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart`
Expected: PASS — les nouveaux tests, et les tests d'écran `lisibilite` inchangés.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/ui/widgets/content_editor/choice_button.dart lib/ui/widgets/content_editor/editor_segmented.dart test/widget/content_editor/contrast.dart test/widget/content_editor/choice_button_test.dart test/widget/content_editor/editor_segmented_test.dart
git commit -m "feat(editeur): puces teintees et selecteur segmente du contrat de choix" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 3 : les champs de ressource et de couleur

**Files:**
- Modify: `lib/ui/widgets/content_editor/asset_field.dart`
- Modify: `lib/ui/widgets/content_editor/color_field.dart` (le `build` de `ColorField` seulement ; `colorToHex`, `hexToColor`, `readableOn` et `_open` inchangés)
- Test: `test/widget/content_editor/asset_field_test.dart` (ajouts), `test/widget/content_editor/color_field_test.dart` (inchangé, doit rester vert)

**Interfaces:**
- Consumes (tâche 1) : `EditorColors`, `editorMono`, `DashedBorder`, `PropertyRow`, `EditorButton`, `EditorButtonTone`. (tâche 2) : `ChoiceButton(isPlaceholder:)`.
- Produces : `AssetField` garde tous ses paramètres et gagne `String? errorText` (la faute qui vise la ressource, affichée sous elle). `ColorField` garde sa signature.

**Contexte :** `AssetField` est aujourd'hui une colonne (nom en gras, puces ou vignette 64×64, bouton « Importer… »). Il devient une `PropertyRow` (spec D4-D5, maquette : section Ressources). Les tests existants exigent : `Key('editeur-champ-<fieldKey>')` sur la rangée de puces d'un son, `Key('editeur-importer-<fieldKey>')` sur le bouton d'import, les textes `aucun`, `aucune`, un seul widget `Image` pour l'aperçu.

- [ ] **Step 1: Écrire les tests (rouges)**

Ajouter à la fin du `main()` de `test/widget/content_editor/asset_field_test.dart` :

```dart
  testWidgets('une image obligatoire porte son point, une optionnelle sa mention',
      (tester) async {
    await pump(
      tester,
      const AssetField(
        fieldKey: 'classCard',
        slot: AssetSlot.image('{id}.png'),
        value: 'assets/data/classes/x/x.png',
      ),
    );
    expect(find.byKey(const Key('editeur-obligatoire')), findsOneWidget);
    expect(find.text('optionnel'), findsNothing);

    await pump(
      tester,
      const AssetField(
        fieldKey: 'iconPath',
        slot: AssetSlot.image('icon.png', isRequired: false),
      ),
    );
    expect(find.byKey(const Key('editeur-obligatoire')), findsNothing);
    expect(find.text('optionnel'), findsOneWidget);
    // Sans valeur, le chemin le dit : il n'y a rien a montrer.
    expect(find.text('(aucune)'), findsOneWidget);
  });

  testWidgets('une faute sur la ressource s affiche sous elle', (tester) async {
    await pump(
      tester,
      const AssetField(
        fieldKey: 'sfx',
        slot: AssetSlot.sound(),
        errorText: 'son inconnu : clang',
      ),
    );
    expect(find.text('son inconnu : clang'), findsOneWidget);
  });

  testWidgets('un import en attente est annonce', (tester) async {
    await pump(
      tester,
      const AssetField(
        fieldKey: 'sfx',
        slot: AssetSlot.sound(),
        value: 'clang',
        pendingLabel: 'à importer : clang.wav',
      ),
    );
    expect(find.text('à importer : clang.wav'), findsOneWidget);
    expect(find.byIcon(Icons.schedule), findsOneWidget);
  });
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/asset_field_test.dart`
Expected: FAIL — `errorText` inconnu (compilation).

- [ ] **Step 3: Réécrire `AssetField`**

Garder la documentation de tête et tous les champs existants ; ajouter :

```dart
  /// La faute qui vise cette ressource, affichee sous elle.
  final String? errorText;
```

(et `this.errorText,` au constructeur). Imports : `dart:typed_data`, `material.dart`, `entity_descriptor.dart`, `app_colors.dart`, `choice_button.dart`, `dashed_border.dart`, `editor_button.dart`, `editor_style.dart`, `property_row.dart`. Remplacer `build`, `_sounds` et `_image` par :

```dart
  @override
  Widget build(BuildContext context) {
    final isImage = slot.kind == AssetKind.image;
    return PropertyRow(
      label: fieldKey,
      isRequired: isImage && slot.isRequired,
      note: isImage && !slot.isRequired ? 'optionnel' : null,
      errorText: errorText,
      alignTop: true,
      child: isImage ? _image() : _sounds(),
    );
  }

  Widget _pending() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 15, color: AppColors.warning),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              pendingLabel!,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _importButton(IconData icon) => EditorButton(
        key: Key('editeur-importer-$fieldKey'),
        label: 'Importer…',
        icon: icon,
        dense: true,
        onPressed: onImport,
      );

  Widget _sounds() {
    final current = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          key: Key('editeur-champ-$fieldKey'),
          spacing: 6,
          runSpacing: 6,
          children: [
            ChoiceButton(
              label: 'aucun',
              isPlaceholder: true,
              isSelected: current == null,
              onTap: () => onClear?.call(),
            ),
            // Un son en attente d'import n'est pas encore dans `audio.json` :
            // il reste affiche, et choisi.
            for (final id in {...soundIds, ?current})
              ChoiceButton(
                label: id,
                isSelected: current == id,
                onTap: () => onSelectSound?.call(id),
              ),
          ],
        ),
        if (pendingLabel != null)
          Padding(padding: const EdgeInsets.only(top: 8), child: _pending()),
        if (onImport != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _importButton(Icons.music_note),
          ),
      ],
    );
  }

  Widget _image() {
    final clearable = !slot.isRequired && onClear != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Thumbnail(bytes: imageBytes, portrait: slot.isRequired),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value ?? '(aucune)',
                style: editorMono(
                  size: 12,
                  color: value == null ? EditorColors.faint : EditorColors.soft,
                ),
              ),
              if (pendingLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _pending(),
                ),
              if (onImport != null || clearable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onImport != null) _importButton(Icons.upload_file),
                      if (clearable)
                        EditorButton(
                          label: 'aucune',
                          icon: Icons.close,
                          tone: EditorButtonTone.quiet,
                          dense: true,
                          onPressed: onClear,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// L'apercu d'une image, sur un damier : une zone transparente s'y voit.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.bytes, required this.portrait});

  final Uint8List? bytes;

  /// Une image obligatoire est une carte ou un sprite, en hauteur ; une icone
  /// est carree.
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    final frame = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: portrait ? 72 : 56,
        height: portrait ? 96 : 56,
        child: CustomPaint(
          painter: const _CheckerPainter(),
          child: bytes == null
              ? const Center(
                  child: Icon(Icons.image, size: 22, color: EditorColors.faint),
                )
              : Image.memory(
                  bytes,
                  // Un apercu de 72 points : decoder une carte de classe de
                  // 6,5 Mo a pleine taille serait un cout pur.
                  cacheWidth: 144,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) =>
                      const Center(child: Text('?')),
                ),
        ),
      ),
    );
    if (bytes == null) {
      return DashedBorder(
        color: EditorColors.lineStrong,
        radius: 8,
        child: frame,
      );
    }
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: frame,
    );
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  static const double _cell = 6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF15152A),
    );
    final light = Paint()..color = const Color(0xFF1B1B32);
    for (var row = 0; row * _cell < size.height; row++) {
      for (var column = row.isEven ? 1 : 0;
          column * _cell < size.width;
          column += 2) {
        canvas.drawRect(
          Rect.fromLTWH(column * _cell, row * _cell, _cell, _cell),
          light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) => false;
```

(la dernière accolade fermante de `_CheckerPainter` suit.)

- [ ] **Step 4: Restyler `ColorField.build`**

Imports ajoutés : `../../theme/app_colors.dart`, `editor_style.dart`. Remplacer le `build` de `ColorField` par :

```dart
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: 'Ouvrir la roue des couleurs',
          child: InkWell(
            key: const Key('editeur-couleur-pastille'),
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: value,
                borderRadius: BorderRadius.circular(8),
                // Le lisere doit se voir sur le fond de l'ecran, meme autour
                // d'une couleur sombre.
                border: Border.all(
                  color: EditorColors.soft.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: value.withValues(alpha: 0.45),
                    blurRadius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: EditorColors.well,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: EditorColors.lineStrong),
          ),
          child: Text(
            colorToHex(value),
            style: editorMono(size: 13, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        const Flexible(
          child: Text(
            'Clic sur la pastille : roue complète',
            style: TextStyle(color: EditorColors.faint, fontSize: 12),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 5: Vérifier que tout passe**

Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart`
Expected: PASS.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/content_editor/asset_field.dart lib/ui/widgets/content_editor/color_field.dart test/widget/content_editor/asset_field_test.dart
git commit -m "feat(editeur): ressources et couleur en rangees de proprietes" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 4 : le formulaire de mécanique en inspecteur

**Files:**
- Create: `lib/ui/widgets/content_editor/form_blocks.dart`
- Modify: `lib/ui/widgets/content_editor/document_form.dart` (réécriture du rendu ; la logique des valeurs est reprise à l'identique)
- Test: `test/widget/content_editor/document_form_test.dart` (ajouts ; les tests existants restent verts)

**Interfaces:**
- Consumes (tâche 1) : `EditorColors`, `editorMono`, `kRarityColors`, `editorInputDecoration`, `DashedBorder`, `separatedRows`, `PropertyLabel`, `PropertyRow`, `FieldError`, `FieldAnchors`. (tâche 2) : `ChoiceButton(tint:, isPlaceholder:)`. (existant) `inferFieldKind`, `FieldKind`, `labelOf`, `patternOf`, `FieldPath`, `EditorDocument`, `ColorField`, `hexToColor`, `colorToHex`.
- Produces :
  - `DocumentForm` garde tous ses paramètres (dont `assetField`, retiré seulement en tâche 7) et gagne `Map<String, String> faults = const {}` (message par libellé de champ) et `FieldAnchors? anchors`.
  - Dans `form_blocks.dart` : `NumberGrid({Key? key, required List<Widget> cells})`, `ElementCard({Key? key, required List<Widget> children, int? index, String? title, String summary = '', VoidCallback? onRemove, Key? removeKey})`, `AddElementButton({Key? key, required VoidCallback onPressed})`, `CountBadge(int count, {Key? key})`, `LangBadge(String language, {Key? key})`, `String summaryOf(Object? element)`.

**Contexte :** `DocumentForm` infère un widget par valeur du document (spec du 2026-09-14, §4). Le rendu change, pas l'inférence ni les écritures dans le document. À conserver exactement : `Key('editeur-champ-<libellé>')` sur le `TextField`, le `Wrap` de puces, le `Switch`, le `ColorField` ; `Key('editeur-ajouter-<libellé>')` sur « Ajouter » (liste d'objets) et sur le champ d'ajout (liste de chaînes) ; `Key('editeur-retirer-<libellé>[<i>]')` sur le retrait d'un élément ; les contrôleurs retenus par libellé dans `_controllers` ; les messages de conversion (`« 1a » n'est pas un entier`, `« x » n'est pas un nombre`, `JSON invalide`) ; l'ordre des champs (clés du document, puis ressources absentes, puis références absentes). Un booléen se touche par sa clé et bascule : c'est un `Switch` qui porte la clé, plus un `SwitchListTile`.

- [ ] **Step 1: Écrire les tests (rouges)**

Dans `test/widget/content_editor/document_form_test.dart` : ajouter les imports `package:roguelike_card_game/ui/theme/app_colors.dart`, `package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart`, `package:roguelike_card_game/ui/widgets/content_editor/field_anchors.dart` ; étendre `pump` de deux paramètres nommés passés au `DocumentForm` :

```dart
    Map<String, String> faults = const {},
    FieldAnchors? anchors,
```

puis ajouter :

```dart
  testWidgets('une suite de nombres se range en grille', (tester) async {
    await pump(tester, templateOf(hero), hero);

    final maxHp = tester.getTopLeft(find.byKey(const Key('editeur-champ-maxHp')));
    final maxMana =
        tester.getTopLeft(find.byKey(const Key('editeur-champ-maxMana')));
    final luck = tester.getTopLeft(find.byKey(const Key('editeur-champ-luck')));
    expect(maxMana.dy, maxHp.dy, reason: 'deux nombres voisins, une rangee');
    expect(maxMana.dx, greaterThan(maxHp.dx));
    expect(luck.dy, greaterThan(maxHp.dy), reason: 'trois colonnes au plus');
  });

  testWidgets('un nombre isole garde sa rangee de propriete', (tester) async {
    await pump(tester, templateOf(relic), relic);

    expect(
      tester.getTopLeft(find.byKey(const Key('editeur-champ-value'))).dx,
      greaterThanOrEqualTo(tester.getTopLeft(find.text('value')).dx + 170),
    );
  });

  testWidgets('une faute nommant un champ le borde et s affiche sous lui',
      (tester) async {
    await pump(tester, templateOf(relic), relic,
        faults: const {'value': 'champ obligatoire absent'});

    final field = find.byKey(const Key('editeur-champ-value'));
    expect(
      tester.getTopLeft(find.text('champ obligatoire absent')).dy,
      greaterThan(tester.getBottomLeft(field).dy),
    );
    final decoration = tester.widget<TextField>(field).decoration!;
    expect(
      (decoration.enabledBorder! as OutlineInputBorder).borderSide.color,
      AppColors.danger,
    );
  });

  testWidgets('une rarete prend la couleur du jeu', (tester) async {
    await pump(tester, templateOf(relic), relic);

    expect(
      tester.widget<Text>(find.text('legendary')).style!.color,
      Color.lerp(kRarityColors['legendary'], Colors.white, 0.4),
    );
  });

  testWidgets('chaque champ pose son ancre', (tester) async {
    final anchors = FieldAnchors();
    await pump(tester, templateOf(card), card,
        anchors: anchors,
        vocabulary: const {'effects[].type': ['damage']});

    expect(anchors.keyFor('cost').currentContext, isNotNull);
    expect(anchors.keyFor('effects[0].value').currentContext, isNotNull);
  });

  testWidgets('un element de liste se resume et se retire', (tester) async {
    final document = templateOf(card);
    await pump(tester, document, card, vocabulary: const {
      'effects[].type': ['damage'],
    });

    expect(find.text('#1'), findsOneWidget);
    expect(find.text('damage · 6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editeur-retirer-effects[0]')));
    expect(document.root['effects'], isEmpty);
    expect(structureChanges, 1);
  });
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/document_form_test.dart`
Expected: FAIL — `faults`, `anchors` inconnus (compilation).

- [ ] **Step 3: Écrire `form_blocks.dart`**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'dashed_border.dart';
import 'editor_panel.dart';
import 'editor_style.dart';

/// Les deux premieres valeurs simples d'un element : `damage · 6`.
String summaryOf(Object? element) => element is Map
    ? element.values
        .where((value) => value is String || value is num || value is bool)
        .take(2)
        .join(' · ')
    : '';

/// Une suite de nombres rangee en grille (spec D5) : trois colonnes au plus,
/// une de moins par tranche de 190 points qui manque.
class NumberGrid extends StatelessWidget {
  const NumberGrid({super.key, required this.cells});

  final List<Widget> cells;

  static const double minCellWidth = 190;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          math.min(3, (constraints.maxWidth / minCellWidth).floor()),
        );
        final rows = <Widget>[
          for (var start = 0; start < cells.length; start += columns)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var column = 0; column < columns; column++)
                  Expanded(
                    child: _cell(
                      column,
                      start + column < cells.length
                          ? cells[start + column]
                          : null,
                    ),
                  ),
              ],
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: separatedRows(rows),
        );
      },
    );
  }

  Widget _cell(int column, Widget? cell) {
    final content = cell ?? const SizedBox.shrink();
    if (column == 0) return content;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: EditorColors.line)),
      ),
      child: content,
    );
  }
}

/// Un element d'une liste d'objets, ou un objet imbrique (spec D6) : un cadre,
/// un en-tete — numero et resume, ou nom —, puis ses rangees.
class ElementCard extends StatelessWidget {
  const ElementCard({
    super.key,
    required this.children,
    this.index,
    this.title,
    this.summary = '',
    this.onRemove,
    this.removeKey,
  });

  final List<Widget> children;

  /// Le rang de l'element, a partir de 1.
  final int? index;

  /// Le nom d'un objet imbrique.
  final String? title;
  final String summary;
  final VoidCallback? onRemove;
  final Key? removeKey;

  static final Color _fill = Color.alphaBlend(
    EditorColors.well.withValues(alpha: 0.6),
    EditorColors.panel,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: EditorColors.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 2),
            child: Row(
              children: [
                if (index != null)
                  Text(
                    '#$index',
                    style: editorMono(
                      size: 12,
                      color: EditorColors.soft,
                      weight: FontWeight.w700,
                    ),
                  ),
                if (title != null) Text(title!, style: editorMono()),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    summary,
                    overflow: TextOverflow.ellipsis,
                    style: editorMono(size: 12, color: EditorColors.faint),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    key: removeKey,
                    tooltip: 'Retirer',
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    color: EditorColors.faint,
                    hoverColor: AppColors.danger.withValues(alpha: 0.1),
                    icon: const Icon(Icons.delete),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          ...children,
        ],
      ),
    );
  }
}

/// Le geste « Ajouter » d'une liste, en pointilles : ce qui reste a remplir.
class AddElementButton extends StatelessWidget {
  const AddElementButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      color: EditorColors.lineStrong,
      radius: 9,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(9),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: EditorColors.accent),
                SizedBox(width: 6),
                Text(
                  'Ajouter',
                  style: TextStyle(
                    color: EditorColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Le nombre d'elements d'une liste.
class CountBadge extends StatelessWidget {
  const CountBadge(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: EditorColors.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: EditorColors.accentInk,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// `FR` ou `EN`, devant un texte affiche au joueur.
class LangBadge extends StatelessWidget {
  const LangBadge(this.language, {super.key});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: EditorColors.muted,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        language,
        style: editorMono(
          size: 10.5,
          color: EditorColors.accentInk,
          weight: FontWeight.w700,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Réécrire le rendu de `DocumentForm`**

Garder la documentation de tête de la classe, les champs existants et `dispose`. Imports : `dart:convert`, `material.dart`, `editor_document.dart`, `entity_descriptor.dart`, `field_kind.dart`, `field_path.dart`, `../../theme/app_colors.dart`, `choice_button.dart`, `color_field.dart`, `editor_panel.dart`, `editor_style.dart`, `field_anchors.dart`, `form_blocks.dart`, `property_row.dart`. Ajouter au widget :

```dart
    this.faults = const {},
    this.anchors,
```

```dart
  /// Le message de la premiere faute de chaque champ, par libelle
  /// (`effects[0].value`) : le champ se borde de rouge et l'affiche dessous.
  final Map<String, String> faults;

  /// Ou poser l'ancre de chaque champ, pour que le bandeau d'issue y ramene.
  final FieldAnchors? anchors;
```

Puis remplacer tout le corps de `_DocumentFormState` après `dispose` par :

```dart
  @override
  Widget build(BuildContext context) {
    final root = _document.root;
    final descriptor = widget.descriptor;
    final fields = <String, Object?>{
      for (final key in root.keys)
        if (_isField(key)) key: root[key],
      for (final key in descriptor.assetKeys.keys)
        if (!root.containsKey(key)) key: null,
      for (final key in descriptor.referenceKeys.keys)
        if (!root.containsKey(key)) key: null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: separatedRows(_rows(const [], fields)),
    );
  }

  /// `id` a son champ, la prose de premier niveau aussi ; `skills` est derive
  /// par l'ecrivain ; une cle interdite ne s'ecrit pas.
  bool _isField(String key) {
    final descriptor = widget.descriptor;
    if (key == 'id' || key == 'skills') return false;
    if (descriptor.forbiddenKeys.contains(key)) return false;
    for (final base in descriptor.bilingualBases) {
      if (key == base || key == '${base}_fr' || key == '${base}_en') {
        return false;
      }
    }
    return true;
  }

  void _set(FieldPath path, Object? value) {
    _document.setAt(path, value);
    widget.onChanged();
  }

  FieldKind _kindOf(FieldPath path, Object? value) => inferFieldKind(
        path: path,
        value: value,
        descriptor: widget.descriptor,
        hasModelElement:
            value is List && _document.modelElementFor(path) != null,
      );

  bool _isNumber(FieldPath path, Object? value) {
    final kind = _kindOf(path, value);
    return kind == FieldKind.integer || kind == FieldKind.decimal;
  }

  bool _isRequired(FieldPath path) =>
      path.length == 1 && widget.descriptor.requiredKeys.contains(path.first);

  /// Le dernier segment nomme du chemin : `type` pour `effects[0].type`.
  String _name(FieldPath path) =>
      path.lastWhere((segment) => segment is String) as String;

  Widget _anchored(String label, Widget child) {
    final anchors = widget.anchors;
    return anchors == null
        ? child
        : KeyedSubtree(key: anchors.keyFor(label), child: child);
  }

  /// Les rangees d'un objet, dans l'ordre du document. Une suite d'au moins
  /// deux nombres forme une grille ; une paire `x_fr` / `x_en` de chaines, une
  /// seule rangee ; le reste, une rangee par champ.
  List<Widget> _rows(
    FieldPath prefix,
    Map<String, Object?> map, {
    double labelWidth = 170,
  }) {
    final rows = <Widget>[];
    final numbers = <FieldPath>[];

    void flushNumbers() {
      if (numbers.length >= 2) {
        rows.add(NumberGrid(cells: [
          for (final path in numbers) _numberCell(path, map[path.last]),
        ]));
      } else {
        for (final path in numbers) {
          rows.add(_field(path, map[path.last], labelWidth: labelWidth));
        }
      }
      numbers.clear();
    }

    for (final entry in map.entries) {
      final key = entry.key;
      final path = [...prefix, key];
      final french = key.endsWith('_en')
          ? '${key.substring(0, key.length - 3)}_fr'
          : null;
      // Rendu avec sa paire francaise — qui ne fait une rangee que si les deux
      // valeurs sont des chaines : sinon chacune garde son propre champ.
      if (french != null && map[french] is String && entry.value is String) {
        continue;
      }
      final english = key.endsWith('_fr')
          ? '${key.substring(0, key.length - 3)}_en'
          : null;
      if (english != null && map[english] is String && entry.value is String) {
        flushNumbers();
        rows.add(_bilingual(path, [...prefix, english], map,
            labelWidth: labelWidth));
        continue;
      }
      if (_isNumber(path, entry.value)) {
        numbers.add(path);
        continue;
      }
      flushNumbers();
      rows.add(_field(path, entry.value, labelWidth: labelWidth));
    }
    flushNumbers();
    return rows;
  }

  Widget _field(FieldPath path, Object? value, {double labelWidth = 170}) {
    final descriptor = widget.descriptor;
    final pattern = patternOf(path);
    final label = labelOf(path);

    PropertyRow row(Widget child, {bool alignTop = false}) => PropertyRow(
          label: _name(path),
          isRequired: _isRequired(path),
          errorText: widget.faults[label],
          alignTop: alignTop,
          labelWidth: labelWidth,
          child: child,
        );

    final Widget built;
    switch (_kindOf(path, value)) {
      case FieldKind.asset:
        built = widget.assetField(pattern, descriptor.assetKeys[pattern]!);
      case FieldKind.reference:
        built = row(
          _choices(
            path,
            widget.referenceOptions[pattern] ?? const [],
            isSelected: (option) => value == option,
            onTap: (option) => _set(path, option),
            noneSelected: value == null,
            onNone: () {
              _document.removeAt(path);
              widget.onChanged();
            },
          ),
          alignTop: true,
        );
      case FieldKind.color:
        built = row(ColorField(
          key: Key('editeur-champ-$label'),
          value: hexToColor(value is String ? value : '') ??
              const Color(0xFFFF00FF),
          onChanged: (color) => _set(path, colorToHex(color)),
        ));
      case FieldKind.enumChoice:
        // Les raretes portent les couleurs du jeu : elles se reconnaissent
        // d'un coup d'oeil.
        final tints =
            _name(path) == 'rarity' ? kRarityColors : const <String, Color>{};
        built = row(
          _choices(
            path,
            descriptor.enumKeys[pattern]!,
            isSelected: (option) => value == option,
            onTap: (option) => _set(path, option),
            tintOf: (option) => tints[option],
          ),
          alignTop: true,
        );
      case FieldKind.enumMulti:
        final options = descriptor.enumListKeys[pattern]!;
        // Une valeur qui n'est pas une liste (vue brute, fichier retouche)
        // ne selectionne rien : la validation dira pourquoi elle est refusee.
        final selected = {
          ...(value is List ? value.whereType<String>() : const <String>[]),
        };
        built = row(
          _choices(
            path,
            options,
            isSelected: selected.contains,
            onTap: (option) => _set(path, [
              for (final o in options)
                if (selected.contains(o) != (o == option)) o,
            ]),
          ),
          alignTop: true,
        );
      case FieldKind.vocabulary:
        // La valeur fautive reste visible, et choisie : la validation dira
        // pourquoi elle est refusee.
        final options = {
          ...?widget.vocabulary[pattern],
          if (value is String && value.isNotEmpty) value,
        }.toList();
        built = row(
          _choices(
            path,
            options,
            isSelected: (option) => value == option,
            onTap: (option) => _set(path, option),
          ),
          alignTop: true,
        );
      case FieldKind.boolean:
        built = row(Align(
          alignment: Alignment.centerLeft,
          child: Switch(
            key: Key('editeur-champ-$label'),
            value: value! as bool,
            activeTrackColor: EditorColors.accent,
            onChanged: (checked) => _set(path, checked),
          ),
        ));
      case FieldKind.integer:
        built = row(_narrow(_integerField(path, value)));
      case FieldKind.decimal:
        built = row(_narrow(_decimalField(path, value)));
      case FieldKind.text:
        built = row(
          _textField(path, value! as String, (text) => _set(path, text)),
        );
      case FieldKind.objectList:
        built = _objectList(path, value! as List);
      case FieldKind.stringList:
        built = row(
          _stringList(path, (value! as List).cast<String>()),
          alignTop: true,
        );
      case FieldKind.object:
        built = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ElementCard(
            title: _name(path),
            children: separatedRows(
              _rows(path, value! as Map<String, dynamic>, labelWidth: 110),
            ),
          ),
        );
      case FieldKind.rawJson:
        built = row(_textField(
          path,
          jsonEncode(value),
          (text) {
            try {
              _set(path, jsonDecode(text));
            } on FormatException {
              _document.reportConversion(path, 'JSON invalide');
              widget.onChanged();
            }
          },
          mono: true,
        ));
    }
    return _anchored(label, built);
  }

  /// Un nombre n'a pas besoin de toute la largeur.
  Widget _narrow(Widget field) => Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: field,
        ),
      );

  Widget _integerField(FieldPath path, Object? value) =>
      _textField(path, '$value', (text) {
        final parsed = int.tryParse(text.trim());
        if (parsed == null) {
          _document.reportConversion(path, '« $text » n\'est pas un entier');
          widget.onChanged();
        } else {
          _set(path, parsed);
        }
      }, keyboard: TextInputType.number, mono: true);

  Widget _decimalField(FieldPath path, Object? value) =>
      _textField(path, '$value', (text) {
        final parsed = double.tryParse(text.trim());
        if (parsed == null) {
          _document.reportConversion(path, '« $text » n\'est pas un nombre');
          widget.onChanged();
        } else {
          _set(path, parsed);
        }
      },
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          mono: true);

  /// Une cellule de la grille de nombres : sa cle au-dessus, son champ, et
  /// le message d'une faute.
  Widget _numberCell(FieldPath path, Object? value) {
    final label = labelOf(path);
    final error = widget.faults[label];
    final field = _kindOf(path, value) == FieldKind.integer
        ? _integerField(path, value)
        : _decimalField(path, value);
    return _anchored(
      label,
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PropertyLabel(
                label: _name(path),
                isRequired: _isRequired(path),
                hasError: error != null,
              ),
            ),
            const SizedBox(height: 6),
            field,
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: FieldError(error),
              ),
          ],
        ),
      ),
    );
  }

  /// Une paire `x_fr` / `x_en` sur une rangee, francais a gauche.
  Widget _bilingual(
    FieldPath french,
    FieldPath english,
    Map<String, Object?> map, {
    double labelWidth = 170,
  }) {
    final frenchKey = french.last as String;
    final frenchLabel = labelOf(french);
    final englishLabel = labelOf(english);
    return PropertyRow(
      label: frenchKey.substring(0, frenchKey.length - 3),
      alignTop: true,
      labelWidth: labelWidth,
      errorText: widget.faults[frenchLabel] ?? widget.faults[englishLabel],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _anchored(
              frenchLabel,
              _textField(french, map[frenchKey]! as String,
                  (text) => _set(french, text),
                  language: 'FR'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _anchored(
              englishLabel,
              _textField(english, map[english.last]! as String,
                  (text) => _set(english, text),
                  language: 'EN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choices(
    FieldPath path,
    List<String> options, {
    required bool Function(String option) isSelected,
    required void Function(String option) onTap,
    VoidCallback? onNone,
    bool noneSelected = false,
    Color? Function(String option)? tintOf,
  }) {
    return Wrap(
      key: Key('editeur-champ-${labelOf(path)}'),
      spacing: 6,
      runSpacing: 6,
      children: [
        if (onNone != null)
          ChoiceButton(
            label: 'aucun',
            isPlaceholder: true,
            isSelected: noneSelected,
            onTap: onNone,
          ),
        for (final option in options)
          ChoiceButton(
            label: option,
            isSelected: isSelected(option),
            onTap: () => onTap(option),
            tint: tintOf?.call(option),
          ),
      ],
    );
  }

  Widget _textField(
    FieldPath path,
    String initial,
    ValueChanged<String> onChanged, {
    TextInputType? keyboard,
    bool mono = false,
    String? language,
  }) {
    final label = labelOf(path);
    final controller = _controllers.putIfAbsent(
      label,
      () => TextEditingController(text: initial),
    );
    final decoration =
        editorInputDecoration(hasError: widget.faults.containsKey(label));
    return TextField(
      key: Key('editeur-champ-$label'),
      controller: controller,
      keyboardType: keyboard,
      style: mono
          ? editorMono(size: 13, color: AppColors.textPrimary)
          : const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
      decoration: language == null
          ? decoration
          : decoration.copyWith(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 8, right: 6),
                child: LangBadge(language),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
      onChanged: onChanged,
    );
  }

  Widget _objectList(FieldPath path, List<dynamic> list) {
    final label = labelOf(path);
    final error = widget.faults[label];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: PropertyLabel(
                  label: _name(path),
                  isRequired: _isRequired(path),
                  hasError: error != null,
                ),
              ),
              const SizedBox(width: 8),
              CountBadge(list.length),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: FieldError(error),
            ),
          for (var i = 0; i < list.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElementCard(
                index: i + 1,
                summary: summaryOf(list[i]),
                removeKey: Key('editeur-retirer-$label[$i]'),
                onRemove: () {
                  _document.removeElement(path, i);
                  widget.onStructureChanged();
                },
                children: separatedRows(_rows(
                  [...path, i],
                  list[i] as Map<String, dynamic>,
                  labelWidth: 110,
                )),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AddElementButton(
              key: Key('editeur-ajouter-$label'),
              onPressed: () {
                if (_document.addElement(path)) widget.onStructureChanged();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _stringList(FieldPath path, List<String> list) {
    final label = labelOf(path);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < list.length; i++)
          InputChip(
            label: Text(list[i], style: editorMono(color: EditorColors.soft)),
            backgroundColor: EditorColors.chip,
            side: const BorderSide(color: EditorColors.chipBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            deleteIconColor: EditorColors.faint,
            visualDensity: VisualDensity.compact,
            onDeleted: () {
              _document.setAt(path, [...list]..removeAt(i));
              widget.onStructureChanged();
            },
          ),
        SizedBox(
          width: 160,
          child: TextField(
            key: Key('editeur-ajouter-$label'),
            style: editorMono(size: 13, color: AppColors.textPrimary),
            decoration: editorInputDecoration(hintText: 'ajouter…'),
            onSubmitted: (text) {
              final added = text.trim();
              if (added.isEmpty) return;
              _document.setAt(path, [...list, added]);
              widget.onStructureChanged();
            },
          ),
        ),
      ],
    );
  }
}
```

**Avant de valider cette étape, comparer ligne à ligne avec l'ancien `document_form.dart`** (`git show HEAD:lib/ui/widgets/content_editor/document_form.dart`) : chaque écriture dans le document (`setAt`, `removeAt`, `removeElement`, `addElement`, `reportConversion`) et chaque rappel (`onChanged`, `onStructureChanged`) doit se retrouver à l'identique. Seul le rendu change.

- [ ] **Step 5: Vérifier que tout passe**

Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart`
Expected: PASS — les six nouveaux tests, les tests existants de `document_form_test.dart` et de l'écran.

Si un test d'écran existant échoue parce qu'un champ est devenu hors de vue ou plus haut, corriger d'abord la mise en page (compacité) ; ne toucher au test que s'il observait une structure disparue, et le dire dans le rapport.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/content_editor/form_blocks.dart lib/ui/widgets/content_editor/document_form.dart test/widget/content_editor/document_form_test.dart
git commit -m "feat(editeur): la mecanique en inspecteur, grille de nombres et sous-panneaux" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 5 : la barre de titre, la barre d'outils et l'explorateur

**Files:**
- Create: `lib/ui/widgets/content_editor/editor_app_bar.dart`
- Create: `lib/ui/widgets/content_editor/editor_toolbar.dart`
- Create: `lib/ui/widgets/content_editor/entity_explorer.dart`
- Test: `test/widget/content_editor/editor_toolbar_test.dart`, `test/widget/content_editor/entity_explorer_test.dart`

**Interfaces:**
- Consumes (tâche 1) : `EditorColors`, `editorMono`, `kCategoryIcons`, `editorInputDecoration`. (tâche 2, tests) : `expectReadableChoice`, `choiceFill`. (existant) `kEntityDescriptors`, `EntityCategory`, `kNeutralOwnerColor`.
- Produces :
  - `String shortRoot(String root)` ; `EditorAppBar({Key? key, required String? rootPath})` — `PreferredSizeWidget`, hauteur 58.
  - `EditorToolbar({Key? key, required EntityCategory? selected, required ValueChanged<EntityCategory> onSelected, Widget? trailing})` — un onglet par entrée de `kEntityDescriptors`, dans son ordre ; rappelle `onSelected` aussi pour l'onglet déjà choisi.
  - `EntityExplorer({Key? key, required Map<String?, List<String>> idsByOwner, required String? selectedOwner, required String? selectedId, required void Function(String? owner, String id) onSelected, required Color Function(String? owner) colorOf})` — groupes `Key('editeur-groupe-<propriétaire ou neutre>')`, pastille `Key('editeur-groupe-pastille')`, filtre `Key('editeur-filtre')`.

**Contexte :** ces widgets remplacent, en tâche 7, les niveaux `TreeLevel` de l'écran (spec D1, D2). Ils ne sont pas encore branchés ici. **Aucun texte ne doit égaler un libellé de type** : le titre de l'explorateur est `ENTITÉS`, le groupe neutre `Neutres` (la pastille de propriétaire du formulaire s'appelle `Neutre`).

- [ ] **Step 1: Écrire les tests de la barre (rouges)**

Créer `test/widget/content_editor/editor_toolbar_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_app_bar.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_style.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_toolbar.dart';

import 'contrast.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    tester.view.physicalSize = const Size(1400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: child),
    ));
  }

  const labels = [
    'Carte', 'Relique', 'Événement', 'Passif',
    'Amélioration de forge', 'Classe', 'Ennemi',
  ];

  testWidgets('les sept types sont des onglets qui rappellent leur type',
      (tester) async {
    final picked = <EntityCategory>[];
    await pump(tester, EditorToolbar(selected: null, onSelected: picked.add));

    for (final label in labels) {
      expect(find.text(label), findsOneWidget, reason: 'type manquant : $label');
    }
    await tester.tap(find.text('Classe'));
    await tester.tap(find.text('Ennemi'));
    expect(picked, [EntityCategory.heroClass, EntityCategory.enemy]);
  });

  testWidgets('l onglet choisi se souligne, se dit choisi, et tout se lit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      EditorToolbar(selected: EntityCategory.relic, onSelected: (_) {}),
    );

    BorderSide underline(String label) =>
        ((tester.widget<Container>(choiceFill(label)).decoration!
                    as BoxDecoration)
                .border! as Border)
            .bottom;
    expect(underline('Relique').color, EditorColors.accent);
    expect(underline('Carte').color, Colors.transparent);
    expect(tester.getSemantics(choiceFill('Relique')),
        containsSemantics(isSelected: true));
    expect(tester.getSemantics(choiceFill('Carte')),
        containsSemantics(isSelected: false));
    for (final label in labels) {
      expectReadableChoice(tester, label);
    }
    semantics.dispose();
  });

  testWidgets('le controle d action se tient au bout de la barre',
      (tester) async {
    await pump(
      tester,
      EditorToolbar(
        selected: EntityCategory.card,
        onSelected: (_) {},
        trailing: const Text('action'),
      ),
    );
    expect(
      tester.getTopLeft(find.text('action')).dx,
      greaterThan(tester.getTopRight(find.text('Ennemi')).dx),
    );
  });

  group('EditorAppBar', () {
    test('le depot se reduit a ses deux derniers dossiers', () {
      expect(shortRoot('C:/Users/moi/Jeux/roguelike_card_game'),
          '…/Jeux/roguelike_card_game');
      expect(shortRoot('/depot'), '/depot');
    });

    testWidgets('titre, badge DEBUG, et le depot quand il y en a un',
        (tester) async {
      await pump(
        tester,
        const EditorAppBar(rootPath: 'C:/Users/moi/Jeux/roguelike_card_game'),
      );
      expect(find.text('ÉDITEUR DE CONTENU'), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
      expect(find.text('…/Jeux/roguelike_card_game'), findsOneWidget);

      await pump(tester, const EditorAppBar(rootPath: null));
      expect(find.byIcon(Icons.folder_open), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Écrire les tests de l'explorateur (rouges)**

Créer `test/widget/content_editor/entity_explorer_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/entity_explorer.dart';

import 'contrast.dart';

void main() {
  const mage = Color(0xFF9C27B0);
  const ids = <String?, List<String>>{
    null: ['frappe', 'garde'],
    'paladin': ['bouclier'],
    'mage': ['eclair'],
  };

  late List<(String?, String)> picked;

  Future<void> pump(
    WidgetTester tester, {
    String? selectedOwner,
    String? selectedId,
  }) {
    picked = [];
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(
        body: SizedBox(
          width: 240,
          child: EntityExplorer(
            idsByOwner: ids,
            selectedOwner: selectedOwner,
            selectedId: selectedId,
            onSelected: (owner, id) => picked.add((owner, id)),
            colorOf: (owner) => switch (owner) {
              null => kNeutralOwnerColor,
              'mage' => mage,
              _ => const Color(0xFF2196F3),
            },
          ),
        ),
      ),
    ));
  }

  Finder group(String owner) => find.byKey(Key('editeur-groupe-$owner'));

  testWidgets('les neutres d abord, puis chaque classe par ordre alphabetique',
      (tester) async {
    await pump(tester);

    final neutral = tester.getTopLeft(group('neutre')).dy;
    final mageTop = tester.getTopLeft(group('mage')).dy;
    final paladin = tester.getTopLeft(group('paladin')).dy;
    expect(neutral, lessThan(mageTop));
    expect(mageTop, lessThan(paladin));
    expect(find.text('ENTITÉS'), findsOneWidget);
    expect(find.text('4'), findsOneWidget, reason: 'le total des entites');
  });

  testWidgets('chaque groupe porte la couleur de son proprietaire',
      (tester) async {
    await pump(tester);

    Color dot(String owner) => (tester
            .widget<Container>(find.descendant(
              of: group(owner),
              matching: find.byKey(const Key('editeur-groupe-pastille')),
            ))
            .decoration! as BoxDecoration)
        .color!;
    expect(dot('mage'), mage);
    expect(dot('neutre'), kNeutralOwnerColor);
    expect(find.descendant(of: group('mage'), matching: find.text('eclair')),
        findsOneWidget);
    expect(find.descendant(of: group('neutre'), matching: find.text('Neutres')),
        findsOneWidget);
  });

  testWidgets('choisir une entite rappelle son proprietaire', (tester) async {
    await pump(tester);

    await tester.tap(find.text('eclair'));
    await tester.tap(find.text('garde'));
    expect(picked, [('mage', 'eclair'), (null, 'garde')]);
  });

  testWidgets('l entite choisie porte la coche, se dit choisie, et tout se lit',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, selectedOwner: 'mage', selectedId: 'eclair');

    expect(
      find.descendant(
          of: choiceFill('eclair'), matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: choiceFill('frappe'), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(tester.getSemantics(choiceFill('eclair')),
        containsSemantics(isSelected: true));
    for (final label in const ['eclair', 'frappe', 'bouclier']) {
      expectReadableChoice(tester, label);
    }
    semantics.dispose();
  });

  testWidgets('le filtre ne garde que les entites qui le contiennent',
      (tester) async {
    await pump(tester);

    await tester.enterText(find.byKey(const Key('editeur-filtre')), 'ECL');
    await tester.pump();
    expect(find.text('eclair'), findsOneWidget);
    expect(find.text('frappe'), findsNothing);
    expect(group('neutre'), findsNothing, reason: 'un groupe vide disparait');

    await tester.enterText(find.byKey(const Key('editeur-filtre')), 'zzz');
    await tester.pump();
    expect(find.text('Aucune entité ne correspond.'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/editor_toolbar_test.dart test/widget/content_editor/entity_explorer_test.dart`
Expected: FAIL — fichiers introuvables (compilation).

- [ ] **Step 4: Écrire `editor_app_bar.dart`**

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// Les deux derniers dossiers d'un chemin : assez pour reconnaitre le depot.
String shortRoot(String root) {
  final parts = root.split('/').where((part) => part.isNotEmpty).toList();
  return parts.length <= 2
      ? root
      : '…/${parts.sublist(parts.length - 2).join('/')}';
}

/// La barre de titre de l'editeur : retour, titre, badge DEBUG, et le depot
/// ou il ecrit.
class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EditorAppBar({super.key, required this.rootPath});

  /// `null` hors arborescence source : l'ecran refuse alors de s'ouvrir.
  final String? rootPath;

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final root = rootPath;
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: EditorColors.bar,
        border: Border(bottom: BorderSide(color: EditorColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'ÉDITEUR DE CONTENU',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Color(0x96000000),
                  offset: Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: EditorColors.debug,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Spacer(),
          if (root != null)
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_open,
                    size: 16,
                    color: EditorColors.faint,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      shortRoot(root),
                      overflow: TextOverflow.ellipsis,
                      style: editorMono(size: 12, color: EditorColors.faint),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Écrire `editor_toolbar.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// La barre d'outils (spec D1) : les types en onglets, et au bout l'action.
/// Les onglets passent a la ligne quand la largeur manque.
class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.trailing,
  });

  final EntityCategory? selected;

  /// Rappele aussi pour l'onglet deja choisi : a l'appelant de l'ignorer.
  final ValueChanged<EntityCategory> onSelected;

  /// Le choix de l'action, une fois un type choisi.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(bottom: BorderSide(color: EditorColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              children: [
                for (final descriptor in kEntityDescriptors.values)
                  _TypeTab(
                    label: descriptor.label,
                    icon: kCategoryIcons[descriptor.category]!,
                    isSelected: descriptor.category == selected,
                    onTap: () => onSelected(descriptor.category),
                  ),
              ],
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: trailing,
            ),
        ],
      ),
    );
  }
}

/// Un onglet de type, selon le contrat de choix (spec D9) : son soulignement
/// marque la selection autrement que par la couleur du texte.
class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          key: const Key('editeur-bouton-fond'),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: EditorColors.side,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? EditorColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? EditorColors.accent : EditorColors.faint,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected ? AppColors.textPrimary : EditorColors.muted,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Écrire `entity_explorer.dart`**

```dart
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// L'explorateur du mode Modifier (spec D2) : les entites existantes,
/// groupees par proprietaire — les neutres d'abord, puis chaque classe par
/// ordre alphabetique —, et un filtre.
///
/// Une `Column` dans un `SingleChildScrollView`, pas un `ListView` : un
/// `ListView` ne construit pas ses enfants hors ecran.
class EntityExplorer extends StatefulWidget {
  const EntityExplorer({
    super.key,
    required this.idsByOwner,
    required this.selectedOwner,
    required this.selectedId,
    required this.onSelected,
    required this.colorOf,
  });

  /// Tel que le rend `entityIdsByOwner` : la cle `null` porte les neutres.
  final Map<String?, List<String>> idsByOwner;
  final String? selectedOwner;
  final String? selectedId;
  final void Function(String? owner, String id) onSelected;

  /// La couleur d'un proprietaire, `null` pour les neutres.
  final Color Function(String? owner) colorOf;

  @override
  State<EntityExplorer> createState() => _EntityExplorerState();
}

class _EntityExplorerState extends State<EntityExplorer> {
  final TextEditingController _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filter.text.trim().toLowerCase();
    final owners = [
      null,
      ...widget.idsByOwner.keys.whereType<String>().toList()..sort(),
    ];
    final total = widget.idsByOwner.values
        .fold<int>(0, (sum, ids) => sum + ids.length);

    final groups = <Widget>[];
    for (final owner in owners) {
      final ids = [
        for (final id in widget.idsByOwner[owner] ?? const <String>[])
          if (id.toLowerCase().contains(query)) id,
      ];
      if (ids.isNotEmpty) groups.add(_group(owner, ids));
    }

    return Container(
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(right: BorderSide(color: EditorColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_tree,
                      size: 16,
                      color: EditorColors.muted,
                    ),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'ENTITÉS',
                        style: TextStyle(
                          color: EditorColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                    Text(
                      '$total',
                      style: const TextStyle(
                        color: EditorColors.faint,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('editeur-filtre'),
                  controller: _filter,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  decoration: editorInputDecoration(hintText: 'Filtrer…')
                      .copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 17,
                      color: EditorColors.faint,
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 32, minHeight: 0),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: EditorColors.line),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 6, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: groups.isNotEmpty
                    ? groups
                    : const [
                        Padding(
                          padding: EdgeInsets.all(14),
                          child: Text(
                            'Aucune entité ne correspond.',
                            style: TextStyle(
                              color: EditorColors.faint,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String? owner, List<String> ids) {
    return KeyedSubtree(
      key: Key('editeur-groupe-${owner ?? 'neutre'}'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 5),
              child: Row(
                children: [
                  Container(
                    key: const Key('editeur-groupe-pastille'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.colorOf(owner),
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), spreadRadius: 2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      owner ?? 'Neutres',
                      style: const TextStyle(
                        color: EditorColors.soft,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${ids.length}',
                    style: const TextStyle(
                      color: EditorColors.faint,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            for (final id in ids)
              _ExplorerItem(
                id: id,
                isSelected:
                    id == widget.selectedId && owner == widget.selectedOwner,
                onTap: () => widget.onSelected(owner, id),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une entite de l'explorateur, selon le contrat de choix (spec D9).
class _ExplorerItem extends StatelessWidget {
  const _ExplorerItem({
    required this.id,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final bool isSelected;
  final VoidCallback onTap;

  static final Color _selectedFill = Color.alphaBlend(
    EditorColors.accent.withValues(alpha: 0.12),
    EditorColors.side,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            key: const Key('editeur-bouton-fond'),
            padding: const EdgeInsets.fromLTRB(30, 5, 10, 5),
            decoration: BoxDecoration(
              color: isSelected ? _selectedFill : EditorColors.side,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    id,
                    overflow: TextOverflow.ellipsis,
                    style: editorMono(
                      color: isSelected
                          ? AppColors.textPrimary
                          : const Color(0xFFB9C5CC),
                      weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, size: 16, color: EditorColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Vérifier que tout passe**

Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart`
Expected: PASS.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/ui/widgets/content_editor/editor_app_bar.dart lib/ui/widgets/content_editor/editor_toolbar.dart lib/ui/widgets/content_editor/entity_explorer.dart test/widget/content_editor/editor_toolbar_test.dart test/widget/content_editor/entity_explorer_test.dart
git commit -m "feat(editeur): barre de titre, onglets de type et explorateur d entites" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 6 : le panneau Référence, la barre d'actions et le bandeau d'issue

**Files:**
- Create: `lib/ui/widgets/content_editor/reference_panel.dart`
- Create: `lib/ui/widgets/content_editor/editor_action_bar.dart`
- Test: `test/widget/content_editor/reference_panel_test.dart`, `test/widget/content_editor/editor_action_bar_test.dart`

**Interfaces:**
- Consumes (tâche 1) : `EditorColors`, `editorMono`, `EditorButton`. (existant) `hexToColor` (`color_field.dart`), `ValidationFault` (`lib/services/content_editor/entity_validator.dart` : `message`, `field`), `WriteReport` (`lib/services/content_editor/entity_writer.dart` : `written`, `sync`, `syncFailed`, `createdEntity`), `ProcessOutcome(int exitCode, String output)` (`content_file_system.dart`).
- Produces :
  - `ReferencePanel({Key? key, required Map<String, List<String>> values, required int entityCount})` — une teinte hexadécimale porte `Key('editeur-reference-teinte')`.
  - `OutcomeBanner.failure(String failure, {Key? key})`, `OutcomeBanner.faults(List<ValidationFault> faults, {Key? key, required ValueChanged<String> onJump})`, `OutcomeBanner.report(WriteReport report, {Key? key})` — la racine du bandeau porte `Key('editeur-issue')`.
  - `Widget? outcomeBannerFor({String? failure, required List<ValidationFault> faults, WriteReport? report, required ValueChanged<String> onJump})` — échec, sinon fautes, sinon rapport, sinon `null` (la précédence de l'actuel `_outcome` de l'écran).
  - `EditorActionBar({Key? key, Widget? banner, required String note, bool noteIsAlarm = false, required List<Widget> actions})`

**Contexte :** l'écran affiche aujourd'hui l'issue (`_outcome`) et les valeurs connues (`_knownValuesPanel`) à sa façon ; la tâche 7 les remplace par ces widgets. Les tests d'écran cherchent ces textes **exacts** : `Échec : <message>`, `Écrit : <chemin>` (un `Text` par chemin), `sync_assets a échoué : <sortie>`, `Redémarrage à chaud pour charger la nouvelle entité.`, `Redémarrage à chaud pour voir la modification.` — ils doivent rester tels quels. Un message de faute est un `Text` à lui seul (les tests font `textContaining(<message>)`).

- [ ] **Step 1: Écrire les tests (rouges)**

Créer `test/widget/content_editor/reference_panel_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/reference_panel.dart';

void main() {
  Future<void> pump(WidgetTester tester, ReferencePanel panel) =>
      tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkNeonTheme,
        home: Scaffold(body: SizedBox(width: 300, child: panel)),
      ));

  testWidgets('chaque cle montre ses valeurs en etiquettes, et leur nombre',
      (tester) async {
    await pump(
      tester,
      const ReferencePanel(
        entityCount: 3,
        values: {
          'passiveTrait': ['regen_armor', 'spell_armor'],
        },
      ),
    );

    expect(find.text('VALEURS DÉJÀ UTILISÉES'), findsOneWidget);
    expect(find.text('Relevées dans 3 entités'), findsOneWidget);
    expect(find.text('passiveTrait'), findsOneWidget);
    expect(find.text('regen_armor'), findsOneWidget);
    expect(find.text('spell_armor'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('une couleur porte sa pastille, un chemin le nom de son fichier',
      (tester) async {
    await pump(
      tester,
      const ReferencePanel(
        entityCount: 1,
        values: {
          'themeColor': ['#2196F3'],
          'classCard': ['assets/data/classes/mage/mage.png'],
        },
      ),
    );

    expect(find.text('Relevées dans 1 entité'), findsOneWidget);
    final swatch = tester.widget<Container>(
        find.byKey(const Key('editeur-reference-teinte')));
    expect((swatch.decoration! as BoxDecoration).color,
        const Color(0xFF2196F3));
    expect(find.text('mage.png'), findsOneWidget);
    expect(find.text('assets/data/classes/mage/mage.png'), findsNothing);
  });

  testWidgets('sans valeur, le panneau le dit', (tester) async {
    await pump(tester, const ReferencePanel(entityCount: 0, values: {}));
    expect(find.text('Aucune valeur relevée.'), findsOneWidget);
  });
}
```

Créer `test/widget/content_editor/editor_action_bar_test.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/content_file_system.dart';
import 'package:roguelike_card_game/services/content_editor/entity_validator.dart';
import 'package:roguelike_card_game/services/content_editor/entity_writer.dart';
import 'package:roguelike_card_game/ui/theme/app_theme.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_action_bar.dart';
import 'package:roguelike_card_game/ui/widgets/content_editor/editor_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child, {double width = 900}) {
    tester.view.physicalSize = Size(width, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(MaterialApp(
      theme: AppTheme.darkNeonTheme,
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
    ));
  }

  group('outcomeBannerFor', () {
    testWidgets('rien a dire, pas de bandeau', (tester) async {
      expect(outcomeBannerFor(faults: const [], onJump: (_) {}), isNull);
    });

    testWidgets('un echec l emporte sur les fautes et le rapport',
        (tester) async {
      await pump(
        tester,
        outcomeBannerFor(
          failure: 'disque plein',
          faults: const [ValidationFault('x')],
          report: const WriteReport(written: ['a.json']),
          onJump: (_) {},
        )!,
      );
      expect(find.text('Échec : disque plein'), findsOneWidget);
      expect(find.text('x'), findsNothing);
      expect(find.byKey(const Key('editeur-issue')), findsOneWidget);
    });
  });

  testWidgets('une faute qui nomme son champ y ramene, une autre non',
      (tester) async {
    final jumps = <String>[];
    await pump(
      tester,
      OutcomeBanner.faults(
        const [
          ValidationFault('« 1a » n\'est pas un entier', field: 'value'),
          ValidationFault('assets/data/relics/x.json existe déjà'),
        ],
        onJump: jumps.add,
      ),
    );

    expect(find.textContaining('n\'est pas un entier'), findsOneWidget);
    await tester.tap(find.text('value'));
    expect(jumps, ['value']);

    expect(
      find.ancestor(
        of: find.textContaining('existe déjà'),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });

  testWidgets('un rapport dit ce qui est ecrit et ce qu il reste a faire',
      (tester) async {
    await pump(
      tester,
      const OutcomeBanner.report(WriteReport(
        written: ['assets/data/relics/a.json', 'assets/data/relics/b.json'],
        sync: ProcessOutcome(1, 'boum'),
        createdEntity: true,
      )),
    );
    expect(find.text('Écrit : assets/data/relics/a.json'), findsOneWidget);
    expect(find.text('Écrit : assets/data/relics/b.json'), findsOneWidget);
    expect(find.text('sync_assets a échoué : boum'), findsOneWidget);
    expect(find.text('Redémarrage à chaud pour charger la nouvelle entité.'),
        findsOneWidget);

    await pump(
      tester,
      const OutcomeBanner.report(WriteReport(written: ['a.json'])),
    );
    expect(find.text('Redémarrage à chaud pour voir la modification.'),
        findsOneWidget);
  });

  group('EditorActionBar', () {
    EditorActionBar bar() => EditorActionBar(
          note: 'Valider vérifie sans écrire',
          actions: [
            EditorButton(label: 'Valider', icon: Icons.fact_check, onPressed: () {}),
            EditorButton(label: 'Écrire', icon: Icons.save, onPressed: () {}),
          ],
        );

    testWidgets('large, la note et les boutons partagent une ligne',
        (tester) async {
      await pump(tester, bar());
      expect(
        tester.getCenter(find.text('Valider vérifie sans écrire')).dy,
        moreOrLessEquals(tester.getCenter(find.text('Écrire')).dy, epsilon: 12),
      );
      expect(tester.getTopLeft(find.text('Écrire')).dx,
          greaterThan(tester.getTopLeft(find.text('Valider')).dx));
    });

    testWidgets('etroite, la note passe au-dessus des boutons', (tester) async {
      await pump(tester, bar(), width: 420);
      expect(
        tester.getBottomLeft(find.text('Valider vérifie sans écrire')).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Valider')).dy),
      );
    });

    testWidgets('le bandeau se tient au-dessus de la ligne d actions',
        (tester) async {
      await pump(
        tester,
        EditorActionBar(
          banner: const OutcomeBanner.failure('disque plein'),
          note: 'note',
          actions: const [],
        ),
      );
      expect(
        tester.getBottomLeft(find.byKey(const Key('editeur-issue'))).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.text('note')).dy),
      );
    });
  });
}
```

- [ ] **Step 2: Vérifier qu'ils échouent**

Run: `flutter test test/widget/content_editor/reference_panel_test.dart test/widget/content_editor/editor_action_bar_test.dart`
Expected: FAIL — fichiers introuvables (compilation).

- [ ] **Step 3: Écrire `reference_panel.dart`**

```dart
import 'package:flutter/material.dart';

import 'color_field.dart';
import 'editor_style.dart';

/// Les valeurs deja utilisees dans la categorie (spec D8), en etiquettes : un
/// aide-memoire pour nommer comme le reste du contenu.
class ReferencePanel extends StatelessWidget {
  const ReferencePanel({
    super.key,
    required this.values,
    required this.entityCount,
  });

  /// Tel que le rend `knownValues` : cle -> valeurs relevees.
  final Map<String, List<String>> values;

  /// Le nombre d'entites relues pour les relever.
  final int entityCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EditorColors.side,
        border: Border(left: BorderSide(color: EditorColors.line)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.library_books, size: 16, color: EditorColors.muted),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'VALEURS DÉJÀ UTILISÉES',
                    style: TextStyle(
                      color: EditorColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entityCount == 1
                  ? 'Relevées dans 1 entité'
                  : 'Relevées dans $entityCount entités',
              style: const TextStyle(color: EditorColors.faint, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (values.isEmpty)
              const Text(
                'Aucune valeur relevée.',
                style: TextStyle(color: EditorColors.faint, fontSize: 12.5),
              ),
            for (final entry in values.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: editorMono(
                              size: 12,
                              color: EditorColors.muted,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value.length}',
                          style: const TextStyle(
                            color: EditorColors.faint,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final value in entry.value) _ValueTag(value),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une valeur relevee. Une couleur montre sa teinte ; un chemin se reduit au
/// nom de son fichier, le chemin entier restant en infobulle.
class _ValueTag extends StatelessWidget {
  const _ValueTag(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(value);
    final slash = value.lastIndexOf('/');
    final shown = slash < 0 ? value : value.substring(slash + 1);

    final tag = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A31),
        border: Border.all(color: const Color(0xFF26264A)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              key: const Key('editeur-reference-teinte'),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(shown, style: editorMono(size: 11.5, color: EditorColors.soft)),
        ],
      ),
    );
    return slash < 0 ? tag : Tooltip(message: value, child: tag);
  }
}
```

- [ ] **Step 4: Écrire `editor_action_bar.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_validator.dart';
import '../../../services/content_editor/entity_writer.dart';
import '../../theme/app_colors.dart';
import 'editor_style.dart';

/// Le bandeau de l'issue du dernier geste, s'il y a quelque chose a dire :
/// un echec, sinon les fautes, sinon ce qui a ete ecrit.
Widget? outcomeBannerFor({
  String? failure,
  required List<ValidationFault> faults,
  WriteReport? report,
  required ValueChanged<String> onJump,
}) {
  if (failure != null) return OutcomeBanner.failure(failure);
  if (faults.isNotEmpty) return OutcomeBanner.faults(faults, onJump: onJump);
  if (report != null) return OutcomeBanner.report(report);
  return null;
}

/// L'issue du dernier geste (spec D7) : un refus en rouge, une ecriture en
/// vert, et en ambre ce qu'il reste a faire pour la voir.
class OutcomeBanner extends StatelessWidget {
  const OutcomeBanner.failure(String this.failure, {super.key})
      : faults = const [],
        report = null,
        onJump = null;

  const OutcomeBanner.faults(
    this.faults, {
    super.key,
    required ValueChanged<String> this.onJump,
  })  : failure = null,
        report = null;

  const OutcomeBanner.report(WriteReport this.report, {super.key})
      : failure = null,
        faults = const [],
        onJump = null;

  final String? failure;
  final List<ValidationFault> faults;
  final WriteReport? report;

  /// Ramene au champ nomme par une faute.
  final ValueChanged<String>? onJump;

  static const Color _refusedInk = Color(0xFFFFB3C0);
  static const Color _writtenInk = Color(0xFFB5FFD9);

  @override
  Widget build(BuildContext context) {
    final refused = report == null;
    final tone = refused ? AppColors.danger : AppColors.success;
    return Container(
      key: const Key('editeur-issue'),
      constraints: const BoxConstraints(maxHeight: 130),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: refused ? 0.07 : 0.05),
        border: Border.all(color: tone.withValues(alpha: refused ? 0.45 : 0.35)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _lines(),
        ),
      ),
    );
  }

  List<Widget> _lines() {
    final failure = this.failure;
    if (failure != null) {
      return [
        _line(Icons.error, AppColors.danger, [
          Expanded(child: Text('Échec : $failure', style: _style(_refusedInk))),
        ]),
      ];
    }
    final report = this.report;
    if (report == null) return [for (final fault in faults) _fault(fault)];
    return [
      for (final path in report.written)
        _line(Icons.check_circle, AppColors.success, [
          Expanded(child: Text('Écrit : $path', style: _style(_writtenInk))),
        ]),
      if (report.syncFailed)
        _line(Icons.error, AppColors.danger, [
          Expanded(
            child: Text(
              'sync_assets a échoué : ${report.sync!.output}',
              style: _style(_refusedInk),
            ),
          ),
        ]),
      // §6.3 de la spec du 2026-09-08 : pour une creation, le redemarrage a
      // chaud a ete verifie a la main le 2026-09-14.
      _line(Icons.restart_alt, AppColors.warning, [
        Expanded(
          child: Text(
            report.createdEntity
                ? 'Redémarrage à chaud pour charger la nouvelle entité.'
                : 'Redémarrage à chaud pour voir la modification.',
            style: _style(AppColors.warning),
          ),
        ),
      ]),
    ];
  }

  /// Une faute qui nomme son champ se touche pour y revenir.
  Widget _fault(ValidationFault fault) {
    final field = fault.field;
    final line = _line(Icons.error, AppColors.danger, [
      if (field != null) ...[
        Text(
          field,
          style: editorMono(color: AppColors.danger, weight: FontWeight.w700),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(child: Text(fault.message, style: _style(_refusedInk))),
      if (field != null) ...[
        const SizedBox(width: 8),
        const Text(
          'aller au champ ↑',
          style: TextStyle(color: EditorColors.faint, fontSize: 11.5),
        ),
      ],
    ]);
    if (field == null) return line;
    return InkWell(
      onTap: () => onJump?.call(field),
      borderRadius: BorderRadius.circular(5),
      child: line,
    );
  }

  static TextStyle _style(Color color) =>
      TextStyle(color: color, fontSize: 13);

  static Widget _line(IconData icon, Color color, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          ...children,
        ],
      ),
    );
  }
}

/// La barre d'actions fixe au bas du formulaire (spec D7) : l'issue du
/// dernier geste, une ligne d'aide, et les boutons — toujours visibles, quel
/// que soit le defilement.
class EditorActionBar extends StatelessWidget {
  const EditorActionBar({
    super.key,
    this.banner,
    required this.note,
    this.noteIsAlarm = false,
    required this.actions,
  });

  final Widget? banner;
  final String note;

  /// La note annonce des fautes : elle passe au rouge.
  final bool noteIsAlarm;
  final List<Widget> actions;

  /// Sous cette largeur, la note passe au-dessus des boutons.
  static const double stackBelow = 560;

  @override
  Widget build(BuildContext context) {
    final noteRow = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          noteIsAlarm ? Icons.block : Icons.info_outline,
          size: 16,
          color: noteIsAlarm ? AppColors.danger : EditorColors.faint,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            note,
            style: TextStyle(
              color: noteIsAlarm ? AppColors.danger : EditorColors.faint,
              fontSize: 12.5,
              fontWeight: noteIsAlarm ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
    final buttons = Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 8,
      children: actions,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(26, 12, 26, 14),
      decoration: const BoxDecoration(
        color: EditorColors.bar,
        border: Border(top: BorderSide(color: EditorColors.line)),
        boxShadow: [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 30,
            offset: Offset(0, -12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < stackBelow;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner != null) ...[banner!, const SizedBox(height: 10)],
              if (stacked) ...[
                noteRow,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: buttons),
              ] else
                Row(
                  children: [
                    Expanded(child: noteRow),
                    const SizedBox(width: 12),
                    buttons,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Vérifier que tout passe**

Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart`
Expected: PASS.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/ui/widgets/content_editor/reference_panel.dart lib/ui/widgets/content_editor/editor_action_bar.dart test/widget/content_editor/reference_panel_test.dart test/widget/content_editor/editor_action_bar_test.dart
git commit -m "feat(editeur): panneau des valeurs connues, barre d actions et bandeau d issue" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

## Task 7 : recomposer l'écran

**Files:**
- Modify: `lib/ui/widgets/content_editor/entity_form.dart` (réécriture)
- Modify: `lib/ui/widgets/content_editor/document_form.dart` (retrait des ressources et de `assetField`)
- Modify: `lib/ui/widgets/content_editor/choice_button.dart` (retrait de `imagePath`)
- Modify: `lib/ui/screens/content_editor_screen.dart`
- Delete: `lib/ui/widgets/content_editor/tree_level.dart`
- Test: `test/widget/content_editor_screen_test.dart`, `test/widget/content_editor/document_form_test.dart`

**Interfaces:**
- Consumes : tout ce que produisent les tâches 1 à 6 (voir leurs blocs *Produces*), et l'existant de l'écran (`_draft`, `_judge`, `_load`, `_write`, `_toggleRaw`, `_setCardCount`, `_ensureCatalog`, `_knownValuesFor`, `_ownerColor`, `_ownerClassJson`, `_assetField`, `_pendingImports`, `_importAsset`, `_bytesOf`, `_refuse`, `_SoundIdDialog`).
- Produces :
  - `enum EntityFileStatus { newFile, loaded, notLoaded }` dans `entity_form.dart`.
  - `EntityForm({Key? key, required EntityDescriptor descriptor, required bool isModification, required TextEditingController idController, required VoidCallback onIdentityChanged, required String pathPreview, required EntityFileStatus status, required Map<String, TextEditingController> proseControllers, required Widget mechanics, required bool rawView, required VoidCallback onToggleRaw, required FieldAnchors anchors, Color? identityColor, Widget? resources, Map<String, String> faults = const {}, List<String> ownerClassIds = const [], String? selectedOwner, ValueChanged<String?>? onOwnerSelected, Color? Function(String classId)? ownerColorOf, bool showSignatureCards = false, TextEditingController? cardCountController, int cardCount = 0, ValueChanged<int>? onCardCountChanged, List<TextEditingController> cardIds = const [], List<TextEditingController> cardNameFr = const [], List<TextEditingController> cardNameEn = const []})` — **plus de** `onValidate`, `onWrite`, `outcome`, `onLoad`.
  - Nouvelles clés : `editeur-entete` (rangée d'en-tête), `editeur-formulaire` (le `SingleChildScrollView` du formulaire), `editeur-prose-<clé>` (champs de prose), `editeur-cartes-plus`, `editeur-cartes-moins`.

**Contexte :** l'écran empile aujourd'hui trois `TreeLevel` (Type, Action, Entité), puis une `Row` [`EntityForm` avec ses boutons et son issue | panneau de valeurs connues]. Il devient (maquette, spec D1-D8) :

```
ScreenScaffold (sombre)
├─ EditorAppBar
└─ Column
   ├─ EditorToolbar  (+ EditorSegmented Créer/Modifier dès qu'un type est choisi)
   └─ Expanded
      ├─ si type ET action choisis : LayoutBuilder → Row
      │   ├─ [Modifier] SizedBox(240, EntityExplorer)
      │   ├─ Expanded(Column[ Expanded(EntityForm), EditorActionBar ])
      │   └─ [largeur ≥ 1100] SizedBox(300, ReferencePanel)
      └─ sinon : l'invite, et le bandeau d'issue s'il y a lieu
```

**Les comportements ne changent pas** : chaque rappel (`onSelected` de type, de mode, d'entité) reprend exactement le corps actuel, **commentaires compris** — gardes « retaper le choix courant ne change rien », remises à zéro, `_load(root)` après le choix d'une entité. Seul le widget qui les déclenche change.

- [ ] **Step 1: Adapter les tests d'écran dont la structure disparaît**

Dans `test/widget/content_editor_screen_test.dart` :

1. Ajouter les imports `package:roguelike_card_game/ui/theme/app_colors.dart` et `package:roguelike_card_game/ui/widgets/content_editor/choice_button.dart`, et l'aide suivante à côté de `buttonOf` :

```dart
  /// Ce que dit le bandeau d'issue. Une faute qui nomme son champ s'affiche
  /// aussi sous ce champ : c'est dans le bandeau qu'on la compte.
  Finder inIssue(Finder finder) => find.descendant(
        of: find.byKey(const Key('editeur-issue')),
        matching: finder,
      );
```

2. Remplacer le test `seul le choix actif porte la coche` par :

```dart
    testWidgets('seul le choix actif est marque choisi', (tester) async {
      final semantics = tester.ensureSemantics();
      Matcher chosen(bool yes) => containsSemantics(isSelected: yes);
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
```

3. Dans `une faute s aligne sur le formulaire, pas en son centre`, remplacer l'`expect` final par :

```dart
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
```

4. Dans `les cartes portent la couleur de leur proprietaire`, remplacer `backgroundOf` et ses `expect` par :

```dart
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
```

(garder les éventuelles assertions qui suivent et qui ne portaient pas sur `backgroundOf`, en les adaptant de la même façon si elles lisaient le fond d'un bouton d'entité).

5. Partout où un test compte un message de faute **qui nomme son champ** avec `findsOneWidget` — au moins `minuscules`, `deux cartes de signature`, `un identifiant est requis`, `n'est pas un entier`, `variantes linguistiques`, `existe déjà dans audio.json` —, envelopper le finder dans `inIssue(…)`. Ne pas toucher aux messages sans champ (`ne se relit pas`, `aucun fichier à charger`, `Écrit :`, `Redémarrage à chaud…`) : ils ne s'affichent qu'une fois.

6. Dans le commentaire du test `retaper le choix deja selectionne ne vide pas la saisie`, remplacer `` `TreeLevel` rappelle `onSelected` `` par `` La barre d'outils rappelle `onSelected` ``.

7. Ajouter, avant le `group('mode Modifier', …)` :

```dart
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
```

8. Dans `test/widget/content_editor/document_form_test.dart` : retirer `assetField: (key, slot) => Text('ressource $key'),` du `pump`, et remplacer le test `une ressource absente du document a quand meme son champ` par :

```dart
  testWidgets('une ressource n est pas un champ de la mecanique',
      (tester) async {
    // Elle a sa propre section, Ressources, que l'ecran compose.
    await pump(
      tester,
      EditorDocument({...relic.decodeTemplate(), 'sfx': 'clang'}),
      relic,
    );
    expect(find.byKey(const Key('editeur-champ-sfx')), findsNothing);
    expect(find.text('sfx'), findsNothing);
  });
```

- [ ] **Step 2: Vérifier que les tests adaptés échouent**

Run: `flutter test test/widget/content_editor_screen_test.dart test/widget/content_editor/document_form_test.dart`
Expected: FAIL — `assetField` toujours requis (compilation) ; une fois l'argument retiré, les tests nouveaux ou adaptés échouent (`editeur-issue`, `editeur-groupe-*`, `editeur-cartes-plus` introuvables).

- [ ] **Step 3: Retirer les ressources de `DocumentForm` et `imagePath` de `ChoiceButton`**

Dans `document_form.dart` :
- retirer le paramètre `assetField` (champ, constructeur, documentation) ;
- dans `_isField`, ajouter `if (descriptor.assetKeys.containsKey(key)) return false;` avec le commentaire `// Une ressource a sa propre section, que l'ecran compose.` ;
- dans `build`, retirer la ligne des ressources absentes (`for (final key in descriptor.assetKeys.keys) …`) ;
- remplacer le `case FieldKind.asset:` par :

```dart
      case FieldKind.asset:
        // Jamais atteint : les ressources sont ecartees par `_isField`, et
        // aucune n'est imbriquee. Elles vivent dans la section Ressources.
        built = const SizedBox.shrink();
```

Dans `choice_button.dart` : retirer `imagePath` (champ, paramètre, documentation, et le bloc `ClipOval` du `build`).

- [ ] **Step 4: Réécrire `entity_form.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';
import 'choice_button.dart';
import 'color_field.dart';
import 'editor_panel.dart';
import 'editor_segmented.dart';
import 'editor_style.dart';
import 'field_anchors.dart';
import 'form_blocks.dart';
import 'property_row.dart';

/// Ce que le disque sait du fichier que montre le formulaire (spec D3).
enum EntityFileStatus {
  /// Une creation : le fichier n'existe pas encore.
  newFile,

  /// Le formulaire montre le contenu du chemin vise, relu du disque.
  loaded,

  /// Modification sans relecture du chemin vise : « Écrire » sera refuse.
  notLoaded,
}

/// Le formulaire d'une entite : l'en-tete du fichier, puis ses sections —
/// Identite, Textes, Mecanique, Ressources, Cartes de signature (spec D3-D4).
///
/// **Purement presentationnel** : tout l'etat vit dans l'ecran appelant, sous
/// forme de `TextEditingController`s et de callbacks. Les boutons et l'issue
/// vivent dans la barre d'actions de l'ecran, toujours visible.
///
/// **Un seul visage** (spec du 2026-09-14, D6) : creation et modification
/// partagent le formulaire infere du document ; les pastilles de proprietaire
/// et la recette de classe restent propres a la creation.
class EntityForm extends StatelessWidget {
  const EntityForm({
    super.key,
    required this.descriptor,
    required this.isModification,
    required this.idController,
    required this.onIdentityChanged,
    required this.pathPreview,
    required this.status,
    required this.proseControllers,
    required this.mechanics,
    required this.rawView,
    required this.onToggleRaw,
    required this.anchors,
    this.identityColor,
    this.resources,
    this.faults = const {},
    this.ownerClassIds = const [],
    this.selectedOwner,
    this.onOwnerSelected,
    this.ownerColorOf,
    this.showSignatureCards = false,
    this.cardCountController,
    this.cardCount = 0,
    this.onCardCountChanged,
    this.cardIds = const [],
    this.cardNameFr = const [],
    this.cardNameEn = const [],
  });

  final EntityDescriptor descriptor;
  final bool isModification;

  final TextEditingController idController;
  final VoidCallback onIdentityChanged;
  final String pathPreview;
  final EntityFileStatus status;

  /// La couleur du proprietaire, ou `themeColor` d'une classe : elle teinte
  /// la tuile de l'en-tete. `null` : l'accent.
  final Color? identityColor;

  final Map<String, TextEditingController> proseControllers;

  /// La mecanique : le formulaire infere, ou la vue JSON brute.
  final Widget mechanics;
  final bool rawView;
  final VoidCallback onToggleRaw;

  /// Les champs de ressource. `null` en vue brute, ou sans ressource.
  final Widget? resources;

  /// Le message de la premiere faute de chaque champ nomme.
  final Map<String, String> faults;
  final FieldAnchors anchors;

  /// Rangee de pastilles de proprietaire, pour une carte en creation
  /// seulement : `Key('editeur-proprietaire-<classe>')` et
  /// `Key('editeur-proprietaire-neutre')`.
  final List<String> ownerClassIds;
  final String? selectedOwner;
  final ValueChanged<String?>? onOwnerSelected;
  final Color? Function(String classId)? ownerColorOf;

  /// La recette de classe, pour une classe en creation seulement.
  final bool showSignatureCards;
  final TextEditingController? cardCountController;
  final int cardCount;
  final ValueChanged<int>? onCardCountChanged;
  final List<TextEditingController> cardIds;
  final List<TextEditingController> cardNameFr;
  final List<TextEditingController> cardNameEn;

  static const TextStyle _heading = TextStyle(
    color: EditorColors.faint,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final resources = this.resources;
    return SingleChildScrollView(
      // Un `SingleChildScrollView`, pas un `ListView` : ce formulaire est
      // plus long qu'un ecran, et un `ListView` ne construit pas ses enfants
      // hors de la vue.
      key: const Key('editeur-formulaire'),
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 16),
          _identity(),
          if (descriptor.bilingualBases.isNotEmpty) ...[
            const SizedBox(height: 16),
            _texts(),
          ],
          const SizedBox(height: 16),
          EditorPanel(
            icon: Icons.tune,
            title: 'Mécanique',
            trailing: _viewToggle(),
            children: [mechanics],
          ),
          if (resources != null) ...[
            const SizedBox(height: 16),
            EditorPanel(
              icon: Icons.perm_media,
              title: 'Ressources',
              caption: "copiées au moment d'écrire",
              children: [resources],
            ),
          ],
          if (showSignatureCards) ...[
            const SizedBox(height: 16),
            _signatureCards(),
          ],
        ],
      ),
    );
  }

  /// Ce que le formulaire edite, le chemin vise et son etat. Sans ce titre,
  /// seul le chemin distinguait le formulaire d'une carte de celui d'une
  /// classe : une classe voulue a ete ecrite en carte neutre.
  Widget _header() {
    final own = identityColor ?? EditorColors.accent;
    final id = idController.text.trim();
    final pathStyle = editorMono(size: 12, color: EditorColors.faint);
    return Row(
      key: const Key('editeur-entete'),
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: own.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: own.withValues(alpha: 0.55)),
          ),
          child: Icon(
            kCategoryIcons[descriptor.category],
            size: 24,
            color: Color.lerp(own, Colors.white, 0.25),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${isModification ? 'Modifier' : 'Créer'} · ${descriptor.label}',
                key: const Key('editeur-titre'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              if (id.isEmpty)
                Text('(identifiant requis)', style: pathStyle)
              else
                Text.rich(
                  TextSpan(children: _crumbs(pathPreview, id)),
                  style: pathStyle,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _StatusPill(status),
      ],
    );
  }

  /// Le chemin vise, l'identifiant surligne : c'est lui qui le calcule. Le
  /// texte reste le chemin exact, separateurs compris.
  static List<TextSpan> _crumbs(String path, String id) {
    final idStyle = TextStyle(
      color: EditorColors.accent,
      fontWeight: FontWeight.w600,
      backgroundColor: EditorColors.accent.withValues(alpha: 0.12),
    );
    const fileStyle = TextStyle(color: EditorColors.soft);
    final segments = path.split('/');
    return [
      for (var i = 0; i < segments.length; i++) ...[
        if (i > 0)
          const TextSpan(text: '/', style: TextStyle(color: Color(0xFF3D4B55))),
        if (segments[i] == id)
          TextSpan(text: id, style: idStyle)
        else if (i == segments.length - 1 && segments[i] == '$id.json') ...[
          TextSpan(text: id, style: idStyle),
          const TextSpan(text: '.json', style: fileStyle),
        ] else if (i == segments.length - 1)
          TextSpan(text: segments[i], style: fileStyle)
        else
          TextSpan(text: segments[i]),
      ],
    ];
  }

  Widget _identity() {
    final idError = faults['id'];
    return EditorPanel(
      icon: Icons.badge,
      title: 'Identité',
      children: [
        KeyedSubtree(
          key: anchors.keyFor('id'),
          child: PropertyRow(
            label: 'id',
            isRequired: true,
            alignTop: true,
            errorText: idError,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  key: const Key('editeur-id'),
                  controller: idController,
                  // Saisissable en modification aussi : c'est le seul moyen
                  // de **designer** l'entite a charger.
                  onChanged: (_) => onIdentityChanged(),
                  style: editorMono(size: 13, color: AppColors.textPrimary),
                  decoration: editorInputDecoration(hasError: idError != null),
                ),
                const SizedBox(height: 5),
                Text(
                  descriptor.folderFile != null
                      ? 'Minuscules, chiffres et _ · nomme le dossier et ses fichiers'
                      : 'Minuscules, chiffres et _ · nomme le fichier',
                  style:
                      const TextStyle(color: EditorColors.faint, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (descriptor.supportsHeroClass)
          KeyedSubtree(
            key: anchors.keyFor('heroClass'),
            child: isModification ? _lockedOwner() : _ownerPills(),
          ),
      ],
    );
  }

  /// Le proprietaire d'une carte est un champ du formulaire, pas un niveau de
  /// l'arbre : la neutralite et chaque classe sont des pastilles, colorees
  /// par le `themeColor` de la classe.
  Widget _ownerPills() {
    return PropertyRow(
      label: 'propriétaire',
      alignTop: true,
      errorText: faults['heroClass'],
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceButton(
            key: const Key('editeur-proprietaire-neutre'),
            label: 'Neutre',
            isSelected: selectedOwner == null,
            onTap: () => onOwnerSelected?.call(null),
            identityColor: kNeutralOwnerColor,
          ),
          for (final classId in ownerClassIds)
            ChoiceButton(
              key: Key('editeur-proprietaire-$classId'),
              label: classId,
              isSelected: selectedOwner == classId,
              onTap: () => onOwnerSelected?.call(classId),
              identityColor: ownerColorOf?.call(classId) ?? kNeutralOwnerColor,
            ),
        ],
      ),
    );
  }

  /// En modification, le dossier impose le proprietaire : il se lit, il ne se
  /// choisit pas.
  Widget _lockedOwner() {
    final owner = selectedOwner;
    final color = owner == null
        ? kNeutralOwnerColor
        : ownerColorOf?.call(owner) ?? kNeutralOwnerColor;
    final ink = readableOn(color);
    return PropertyRow(
      label: 'propriétaire',
      child: Wrap(
        spacing: 10,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 15, color: ink),
                const SizedBox(width: 5),
                Text(
                  owner ?? 'neutre',
                  style: editorMono(color: ink, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Text(
            'imposé par le dossier',
            style: TextStyle(color: EditorColors.faint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// La prose affichee au joueur : francais et anglais cote a cote, l'un
  /// sous l'autre quand la place manque.
  Widget _texts() {
    return EditorPanel(
      icon: Icons.translate,
      title: 'Textes',
      caption: 'affichés au joueur',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 560;
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (wide)
                    Row(
                      children: [
                        const SizedBox(width: 184),
                        Expanded(child: _language('FR', 'Français')),
                        const SizedBox(width: 14),
                        Expanded(child: _language('EN', 'English')),
                      ],
                    ),
                  for (final base in descriptor.bilingualBases)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _bilingualRow(base, wide),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  static Widget _language(String code, String name) => Row(
        children: [
          LangBadge(code),
          const SizedBox(width: 6),
          Text(name.toUpperCase(), style: _heading),
        ],
      );

  Widget _bilingualRow(String base, bool wide) {
    final french = '${base}_fr';
    final english = '${base}_en';
    final error = faults[french] ?? faults[english];
    final multiline = base == 'description';

    Widget field(String key, String code) => KeyedSubtree(
          key: anchors.keyFor(key),
          child: TextField(
            key: Key('editeur-prose-$key'),
            controller: proseControllers[key],
            minLines: multiline ? 2 : 1,
            maxLines: multiline ? 4 : 1,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
            decoration: wide
                ? editorInputDecoration(hasError: faults.containsKey(key))
                : editorInputDecoration(hasError: faults.containsKey(key))
                    .copyWith(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8, right: 6),
                      child: LangBadge(code),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                  ),
          ),
        );

    final label = PropertyLabel(label: base, hasError: error != null);
    final fields = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: field(french, 'FR')),
              const SizedBox(width: 14),
              Expanded(child: field(english, 'EN')),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(french, 'FR'),
              const SizedBox(height: 8),
              field(english, 'EN'),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: label,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(child: fields),
            ],
          )
        else ...[
          Align(alignment: Alignment.centerLeft, child: label),
          const SizedBox(height: 6),
          fields,
        ],
        if (error != null)
          Padding(
            padding: EdgeInsets.only(top: 5, left: wide ? 184 : 0),
            child: FieldError(error),
          ),
      ],
    );
  }

  /// La bascule entre formulaire et JSON brut. La cle de test suit le segment
  /// **inactif** : c'est lui qu'il faut toucher pour basculer, dans un sens
  /// comme dans l'autre.
  Widget _viewToggle() {
    return EditorSegmented<bool>(
      dense: true,
      selected: rawView,
      onSelected: (raw) {
        if (raw != rawView) onToggleRaw();
      },
      segments: [
        EditorSegment(
          value: false,
          label: 'Formulaire',
          icon: Icons.view_agenda,
          key: rawView ? const Key('editeur-bascule-json') : null,
        ),
        EditorSegment(
          value: true,
          label: 'JSON',
          icon: Icons.data_object,
          key: rawView ? null : const Key('editeur-bascule-json'),
        ),
      ],
    );
  }

  /// La classe en creation entraine ses cartes de signature : combien, puis
  /// pour chacune son identifiant et son nom bilingue.
  Widget _signatureCards() {
    final error = faults['skills'];
    return KeyedSubtree(
      key: anchors.keyFor('skills'),
      child: EditorPanel(
        icon: Icons.style,
        title: 'Cartes de signature',
        caption: 'Nombre',
        trailing: _stepper(),
        children: [
          if (cardCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 34,
                        child: Text('#', style: _heading),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('IDENTIFIANT', style: _heading),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _language('FR', 'Nom')),
                      const SizedBox(width: 10),
                      Expanded(child: _language('EN', 'Nom')),
                    ],
                  ),
                  for (var i = 0; i < cardCount; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            child: Text(
                              '${i + 1}',
                              textAlign: TextAlign.center,
                              style: editorMono(
                                size: 12,
                                color: EditorColors.faint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: Key('editeur-carte-$i-id'),
                              controller: cardIds[i],
                              style: editorMono(
                                size: 13,
                                color: AppColors.textPrimary,
                              ),
                              decoration: editorInputDecoration(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: Key('editeur-carte-$i-nom-fr'),
                              controller: cardNameFr[i],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                              ),
                              decoration: editorInputDecoration(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              key: Key('editeur-carte-$i-nom-en'),
                              controller: cardNameEn[i],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                              ),
                              decoration: editorInputDecoration(),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: FieldError(error),
            ),
          if (cardCount == 0 && error == null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                'Aucune carte de signature : la classe sera écrite seule.',
                style: TextStyle(color: EditorColors.faint, fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }

  /// Le nombre de cartes : se tape, ou se regle d'un cran.
  Widget _stepper() {
    return Container(
      decoration: BoxDecoration(
        color: EditorColors.well,
        border: Border.all(color: EditorColors.lineStrong),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            key: const Key('editeur-cartes-moins'),
            icon: Icons.remove,
            tooltip: 'Une carte de moins',
            onPressed: cardCount > 0
                ? () => onCardCountChanged?.call(cardCount - 1)
                : null,
          ),
          SizedBox(
            width: 48,
            child: TextField(
              key: const Key('editeur-nombre-cartes'),
              controller: cardCountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: editorMono(size: 13, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (text) =>
                  onCardCountChanged?.call(int.tryParse(text.trim()) ?? 0),
            ),
          ),
          _StepButton(
            key: const Key('editeur-cartes-plus'),
            icon: Icons.add,
            tooltip: 'Une carte de plus',
            onPressed: () => onCardCountChanged?.call(cardCount + 1),
          ),
        ],
      ),
    );
  }
}

/// Un cran du nombre de cartes.
class _StepButton extends StatelessWidget {
  const _StepButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? EditorColors.faint : EditorColors.accent,
          ),
        ),
      ),
    );
  }
}

/// L'etat du fichier, en pastille : `Nouveau fichier`, `Relu du disque`,
/// `Non chargé`.
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final EntityFileStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      EntityFileStatus.newFile =>
        ('Nouveau fichier', Icons.note_add, EditorColors.accent),
      EntityFileStatus.loaded =>
        ('Relu du disque', Icons.task_alt, AppColors.success),
      EntityFileStatus.notLoaded =>
        ('Non chargé', Icons.sync_problem, AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Recomposer `content_editor_screen.dart`**

**Imports** : retirer `tree_level.dart` ; ajouter `../widgets/screen_scaffold.dart`, `../widgets/content_editor/editor_action_bar.dart`, `editor_app_bar.dart`, `editor_button.dart`, `editor_panel.dart`, `editor_segmented.dart`, `editor_style.dart`, `editor_toolbar.dart`, `entity_explorer.dart`, `field_anchors.dart`, `reference_panel.dart`. Retirer `app_colors.dart` s'il n'est plus utilisé.

**État** : ajouter `final FieldAnchors _anchors = FieldAnchors();` (commentaire : les ancres des champs, pour que le bandeau d'issue y ramene).

**Supprimer** : `_form`, `_targetLevel`, `_ownerImage`, `_entityFormRow`, `_outcome`, `_knownValuesPanel`. Garder tout le reste tel quel (`_ownerColor`, `_ownerClassJson`, `_ensureCatalog`, `_knownValuesFor`, `_assetField`, …), en ajustant seulement ce qui est dit ci-dessous.

**`build`** :

```dart
  @override
  Widget build(BuildContext context) {
    final root = ref.watch(projectRootProvider);

    return ScreenScaffold(
      appBar: EditorAppBar(rootPath: root),
      body: root == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Cette application ne tourne pas depuis une arborescence "
                  "source : aucun répertoire parent ne porte à la fois "
                  "pubspec.yaml et assets/data/. L'éditeur ne peut pas savoir "
                  "où écrire, et refuse donc de s'ouvrir.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: EditorColors.muted, fontSize: 14),
                ),
              ),
            )
          : _workspace(root),
    );
  }
```

**`_workspace`** — reprend les corps des `onSelected` de l'actuel `_form`, commentaires compris :

```dart
  /// La barre d'outils — les niveaux Type et Action de l'arbre —, puis le
  /// formulaire une fois les deux choisis. Rien ne se replie vers le haut :
  /// choisir un niveau n'efface jamais celui du dessus, seulement ce qui
  /// pendait dessous.
  Widget _workspace(String root) {
    final hasForm = _category != null && _mode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorToolbar(
          selected: _category,
          onSelected: (category) => setState(() {
            // La barre rappelle aussi le choix courant : le retaper ne change
            // rien, et ne doit pas effacer la saisie.
            if (category == _category) return;
            // Changer de type referme tout ce qui pendait dessous : une cible
            // d'une autre categorie n'a plus de sens.
            _category = category;
            _mode = null;
            _target = null;
            _targetOwner = null;
            _loadCategory();
          }),
          trailing: _category == null
              ? null
              : EditorSegmented<_EditorMode>(
                  selected: _mode,
                  segments: const [
                    EditorSegment(
                      value: _EditorMode.create,
                      label: 'Créer',
                      icon: Icons.add,
                    ),
                    EditorSegment(
                      value: _EditorMode.modify,
                      label: 'Modifier',
                      icon: Icons.edit,
                    ),
                  ],
                  onSelected: (mode) => setState(() {
                    // (corps actuel du `onSelected` du niveau Action, a
                    // l'identique, commentaires compris)
                  }),
                ),
        ),
        Expanded(child: hasForm ? _editing(root) : _idle()),
      ],
    );
  }
```

Le corps du `onSelected` des modes est **exactement** celui de l'actuel `TreeLevel(depth: 1, …)` : garde `if (value == _mode) return;`, `_mode = value as _EditorMode;` devenant `_mode = mode;`, remise à zéro de `_target`/`_targetOwner`, `_seedDocument(_templateSeed())`, `_loadedPath = null`, vidage des trois tables d'import — commentaires compris. Ne pas laisser le commentaire entre parenthèses ci-dessus : il désigne ce corps.

**`_idle`** :

```dart
  /// Rien a editer encore : ce qu'il reste a choisir, et l'issue du dernier
  /// geste. Une creation referme la branche : son compte rendu doit rester
  /// visible ici.
  Widget _idle() {
    final banner = outcomeBannerFor(
      failure: _failure,
      faults: _faults,
      report: _report,
      onJump: _anchors.reveal,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 20, 26, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: EditorColors.faint,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _category == null
                      ? 'Choisir un type dans la barre ci-dessus.'
                      : "Choisir l'action au bout de la barre : créer une "
                          'entité neuve, ou en modifier une existante.',
                  style: const TextStyle(
                    color: EditorColors.muted,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (banner != null) ...[const SizedBox(height: 16), banner],
        ],
      ),
    );
  }
```

**`_editing`** :

```dart
  /// L'explorateur en mode Modifier, le formulaire et sa barre d'actions, et
  /// le panneau de reference quand il y a la place.
  Widget _editing(String root) {
    _ensureCatalog(root);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sous cette largeur, le panneau de reference ecrasait les champs.
        final showReference = constraints.maxWidth >= 1100;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_mode == _EditorMode.modify)
              SizedBox(width: 240, child: _explorer(root)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _entityForm(root)),
                  _actionBar(root),
                ],
              ),
            ),
            if (showReference)
              SizedBox(
                width: 300,
                child: ReferencePanel(
                  values: _knownValuesFor(root),
                  entityCount: _byOwner.values
                      .fold<int>(0, (sum, ids) => sum + ids.length),
                ),
              ),
          ],
        );
      },
    );
  }
```

**`_explorer`** — le corps du `onSelected` est celui de l'actuel `_targetLevel`, commentaires (a) compris :

```dart
  /// Le niveau Entite de l'arbre : ce qui existe, groupe par proprietaire et
  /// colore par lui.
  Widget _explorer(String root) {
    return EntityExplorer(
      idsByOwner: _byOwner,
      selectedOwner: _targetOwner,
      selectedId: _target,
      colorOf: (owner) => owner == null
          ? kNeutralOwnerColor
          : _ownerColor(root, owner) ?? kNeutralOwnerColor,
      onSelected: (owner, id) {
        setState(() {
          _targetOwner = owner;
          _target = id;
          // (a) Choisir une entite ici designe reellement la cible : sans
          // cette ligne, le surlignage divergeait en silence de ce que
          // « Charger » et « Écrire » visaient.
          _id.text = id;
        });
        // Choisir, c'est charger : sans relecture, le formulaire montrait le
        // gabarit — le meme pour toutes les entites — ou le contenu de
        // l'entite choisie juste avant. « Charger » ne sert plus qu'a relire
        // un identifiant tape a la main.
        _load(root);
      },
    );
  }
```

**`_faultsByField`, `_identityColor`, `_note`** :

```dart
  /// Le message de la premiere faute de chaque champ nomme : c'est lui que
  /// le champ affiche.
  Map<String, String> _faultsByField() {
    final byField = <String, String>{};
    for (final fault in _faults) {
      final field = fault.field;
      if (field != null) byField.putIfAbsent(field, () => fault.message);
    }
    return byField;
  }

  /// La teinte de la tuile d'en-tete : la classe proprietaire d'une carte, ou
  /// le `themeColor` d'une classe. `null` : l'accent.
  Color? _identityColor(String root) {
    final owner = _targetOwner;
    if (_descriptor.supportsHeroClass && owner != null) {
      return _ownerColor(root, owner);
    }
    if (_category == EntityCategory.heroClass && !_rawView) {
      final hex = _document!.root['themeColor'];
      return hex is String ? hexToColor(hex) : null;
    }
    return null;
  }

  /// La ligne d'aide de la barre d'actions : ce que feront les boutons, ou ce
  /// qui les arrete.
  String _note() {
    final count = _faults.length;
    if (count == 1) return "1 faute · rien n'est écrit tant qu'elle reste";
    if (count > 1) return "$count fautes · rien n'est écrit tant qu'il en reste";
    if (_mode == _EditorMode.modify) {
      return "Changer l'identifiant désigne un autre fichier : il faut le "
          "recharger avant d'écrire";
    }
    if (_isClassRecipe && _cardCountValue > 0) {
      final cards =
          _cardCountValue == 1 ? 'sa carte' : 'ses $_cardCountValue cartes';
      return 'Valider vérifie sans écrire · Écrire valide, puis écrit la '
          'classe et $cards';
    }
    return 'Valider vérifie sans écrire · Écrire valide, puis écrit le fichier';
  }
```

**`_entityForm`** (remplace `_entityFormRow`) :

```dart
  Widget _entityForm(String root) {
    final draft = _draft();
    final isModification = _mode == _EditorMode.modify;
    final faults = _faultsByField();

    return EntityForm(
      descriptor: _descriptor,
      isModification: isModification,
      idController: _id,
      onIdentityChanged: () => setState(() {}),
      pathPreview: draft.path,
      status: !isModification
          ? EntityFileStatus.newFile
          : _loadedPath == draft.path
              ? EntityFileStatus.loaded
              : EntityFileStatus.notLoaded,
      identityColor: _identityColor(root),
      proseControllers: _prose,
      ownerClassIds: isModification ? const [] : _ownerClassIds,
      selectedOwner: _targetOwner,
      onOwnerSelected: (value) => setState(() => _targetOwner = value),
      ownerColorOf: (classId) => _ownerColor(root, classId),
      mechanics: _mechanicsView(root, faults),
      rawView: _rawView,
      onToggleRaw: _toggleRaw,
      resources: _resources(root, faults),
      faults: faults,
      anchors: _anchors,
      showSignatureCards: _isClassRecipe,
      cardCountController: _cardCount,
      cardCount: _cardCountValue,
      onCardCountChanged: (n) => setState(() => _setCardCount(n)),
      cardIds: _cardIds,
      cardNameFr: _cardNameFr,
      cardNameEn: _cardNameEn,
    );
  }
```

**`_mechanicsView(String root, Map<String, String> faults)`** : la vue brute devient

```dart
      return Padding(
        padding: const EdgeInsets.all(14),
        child: TextField(
          key: const Key('editeur-json-brut'),
          controller: _raw,
          maxLines: 14,
          style: editorMono(size: 13, color: EditorColors.soft),
          decoration: editorInputDecoration(),
        ),
      );
```

et le `DocumentForm` perd `assetField:` et gagne `faults: faults, anchors: _anchors,` (le reste inchangé).

**`_resources`** (nouveau) et **`_assetField`** :

```dart
  /// La section Ressources : les requises d'abord. Absente en vue brute — le
  /// texte y fait foi, et un champ qui ecrirait dans le document le
  /// contredirait.
  Widget? _resources(String root, Map<String, String> faults) {
    if (_rawView || _descriptor.assetKeys.isEmpty) return null;
    final slots = [
      for (final entry in _descriptor.assetKeys.entries)
        if (entry.value.isRequired) entry,
      for (final entry in _descriptor.assetKeys.entries)
        if (!entry.value.isRequired) entry,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: separatedRows([
        for (final entry in slots)
          KeyedSubtree(
            key: _anchors.keyFor(entry.key),
            child: _assetField(root, entry.key, entry.value, faults[entry.key]),
          ),
      ]),
    );
  }
```

`_assetField` gagne un quatrième paramètre `String? errorText` transmis aux deux `AssetField` qu'il construit (`errorText: errorText,`).

**`_actionBar`** :

```dart
  Widget _actionBar(String root) {
    return EditorActionBar(
      banner: outcomeBannerFor(
        failure: _failure,
        faults: _faults,
        report: _report,
        onJump: _anchors.reveal,
      ),
      note: _note(),
      noteIsAlarm: _faults.isNotEmpty,
      actions: [
        if (_mode == _EditorMode.modify)
          EditorButton(
            label: 'Charger',
            icon: Icons.sync,
            tone: EditorButtonTone.quiet,
            onPressed: () => _load(root),
          ),
        EditorButton(
          label: 'Valider',
          icon: Icons.fact_check,
          onPressed: () => setState(() => _faults = _judge(root).faults),
        ),
        // Le seul geste qui engage le disque est le seul bouton plein.
        EditorButton(
          label: 'Écrire',
          icon: Icons.save,
          tone: EditorButtonTone.primary,
          onPressed: () => _write(root),
        ),
      ],
    );
  }
```

Mettre à jour la documentation de tête de l'écran et les commentaires qui citent `_form`, `_outcome`, `TreeLevel` ou « le panneau de valeurs connues » pour qu'ils nomment les nouveaux widgets (`_workspace`, `_idle`, `outcomeBannerFor`, `EditorToolbar`, `ReferencePanel`).

- [ ] **Step 6: Supprimer l'arbre**

```bash
git rm lib/ui/widgets/content_editor/tree_level.dart
```

Run: `grep -rn "TreeLevel\|TreeChoice\|tree_level\|imagePath:" lib test --include=*.dart`
Expected: aucune ligne sous `lib/ui/` ni `test/widget/content_editor*` (d'autres `imagePath` du jeu, hors éditeur, peuvent exister).

- [ ] **Step 7: Vérifier**

Run: `flutter test test/widget/content_editor_screen_test.dart test/widget/content_editor/`
Expected: PASS.

Si un test **préexistant** échoue parce qu'un widget est hors de vue ou mal atteint à 800×600 (taille par défaut des tests), corriger la mise en page (compacité, passage à la ligne) avant de toucher au test. Un test ne change que s'il observait une structure disparue ; chaque test modifié au-delà de l'étape 1 est nommé dans le rapport, avec la raison.

Run: `flutter test`
Expected: toute la suite PASS.

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add -A lib/ui test/widget
git commit -m "feat(editeur): l ecran recompose en editeur, explorateur et barre d actions" -m "Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

