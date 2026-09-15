import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/content_editor/editor_document.dart';
import '../../../services/content_editor/entity_descriptor.dart';
import '../../../services/content_editor/field_kind.dart';
import '../../../services/content_editor/field_path.dart';
import '../../theme/app_colors.dart';
import 'choice_button.dart';
import 'color_field.dart';
import 'editor_panel.dart';
import 'editor_style.dart';
import 'field_anchors.dart';
import 'form_blocks.dart';
import 'property_row.dart';

/// La mecanique d'une entite, **inferee du document** (spec §4).
///
/// Les champs viennent du document, plus les ressources et les references
/// qu'il ne porte pas encore. Aucune cle du fichier n'est perdue : une cle
/// inconnue recoit le widget de son type.
///
/// L'ecran recree ce widget (`ValueKey`) quand la structure change — un
/// element ajoute ou retire decale les libelles, donc les controleurs.
class DocumentForm extends StatefulWidget {
  const DocumentForm({
    super.key,
    required this.document,
    required this.descriptor,
    required this.onChanged,
    required this.onStructureChanged,
    required this.assetField,
    this.referenceOptions = const {},
    this.vocabulary = const {},
    this.faults = const {},
    this.anchors,
  });

  final EditorDocument document;
  final EntityDescriptor descriptor;

  /// Une valeur a change.
  final VoidCallback onChanged;

  /// Un element a ete ajoute ou retire.
  final VoidCallback onStructureChanged;

  final Widget Function(String key, AssetSlot slot) assetField;
  final Map<String, List<String>> referenceOptions;
  final Map<String, List<String>> vocabulary;

  /// Le message de la premiere faute de chaque champ, par libelle
  /// (`effects[0].value`) : le champ se borde de rouge et l'affiche dessous.
  final Map<String, String> faults;

  /// Ou poser l'ancre de chaque champ, pour que le bandeau d'issue y ramene.
  final FieldAnchors? anchors;

  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final Map<String, TextEditingController> _controllers = {};

  EditorDocument get _document => widget.document;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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
              EditorColors.colorFallback,
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
