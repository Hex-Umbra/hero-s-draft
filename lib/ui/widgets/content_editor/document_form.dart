import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/content_editor/editor_document.dart';
import '../../../services/content_editor/entity_descriptor.dart';
import '../../../services/content_editor/field_kind.dart';
import '../../../services/content_editor/field_path.dart';
import 'choice_button.dart';
import 'color_field.dart';

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
    final keys = <String>[
      for (final key in root.keys)
        if (_isField(key)) key,
      for (final key in descriptor.assetKeys.keys)
        if (!root.containsKey(key)) key,
      for (final key in descriptor.referenceKeys.keys)
        if (!root.containsKey(key)) key,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final key in keys) _field([key], root[key])],
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

  Widget _field(FieldPath path, Object? value) {
    final descriptor = widget.descriptor;
    final pattern = patternOf(path);
    final kind = inferFieldKind(
      path: path,
      value: value,
      descriptor: descriptor,
      hasModelElement: value is List && _document.modelElementFor(path) != null,
    );

    switch (kind) {
      case FieldKind.asset:
        return widget.assetField(pattern, descriptor.assetKeys[pattern]!);
      case FieldKind.reference:
        return _choices(
          path,
          widget.referenceOptions[pattern] ?? const [],
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
          noneSelected: value == null,
          onNone: () {
            _document.removeAt(path);
            widget.onChanged();
          },
        );
      case FieldKind.color:
        return _labelled(
          path,
          ColorField(
            key: Key('editeur-champ-${labelOf(path)}'),
            value: hexToColor(value is String ? value : '') ??
                const Color(0xFFFF00FF),
            onChanged: (color) => _set(path, colorToHex(color)),
          ),
        );
      case FieldKind.enumChoice:
        return _choices(
          path,
          descriptor.enumKeys[pattern]!,
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
        );
      case FieldKind.enumMulti:
        final options = descriptor.enumListKeys[pattern]!;
        // Une valeur qui n'est pas une liste (vue brute, fichier retouche)
        // ne selectionne rien : la validation dira pourquoi elle est refusee.
        final selected = {
          ...(value is List ? value.whereType<String>() : const <String>[]),
        };
        return _choices(
          path,
          options,
          isSelected: selected.contains,
          onTap: (option) => _set(path, [
            for (final o in options)
              if (selected.contains(o) != (o == option)) o,
          ]),
        );
      case FieldKind.vocabulary:
        // La valeur fautive reste visible, et choisie : la validation dira
        // pourquoi elle est refusee.
        final options = {
          ...?widget.vocabulary[pattern],
          if (value is String && value.isNotEmpty) value,
        }.toList();
        return _choices(
          path,
          options,
          isSelected: (option) => value == option,
          onTap: (option) => _set(path, option),
        );
      case FieldKind.boolean:
        return SwitchListTile(
          key: Key('editeur-champ-${labelOf(path)}'),
          contentPadding: EdgeInsets.zero,
          title: Text(_name(path)),
          value: value! as bool,
          onChanged: (checked) => _set(path, checked),
        );
      case FieldKind.integer:
        return _textField(path, '$value', (text) {
          final parsed = int.tryParse(text.trim());
          if (parsed == null) {
            _document.reportConversion(path, '« $text » n\'est pas un entier');
            widget.onChanged();
          } else {
            _set(path, parsed);
          }
        }, keyboard: TextInputType.number);
      case FieldKind.decimal:
        return _textField(path, '$value', (text) {
          final parsed = double.tryParse(text.trim());
          if (parsed == null) {
            _document.reportConversion(path, '« $text » n\'est pas un nombre');
            widget.onChanged();
          } else {
            _set(path, parsed);
          }
        }, keyboard: const TextInputType.numberWithOptions(decimal: true));
      case FieldKind.text:
        return _textField(path, value! as String, (text) => _set(path, text));
      case FieldKind.objectList:
        return _objectList(path, value! as List);
      case FieldKind.stringList:
        return _stringList(path, (value! as List).cast<String>());
      case FieldKind.object:
        return _labelled(
          path,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _objectFields(path, value! as Map<String, dynamic>),
          ),
        );
      case FieldKind.rawJson:
        return _textField(path, jsonEncode(value), (text) {
          try {
            _set(path, jsonDecode(text));
          } on FormatException {
            _document.reportConversion(path, 'JSON invalide');
            widget.onChanged();
          }
        });
    }
  }

  /// Le dernier segment nomme du chemin : `type` pour `effects[0].type`.
  String _name(FieldPath path) =>
      path.lastWhere((segment) => segment is String) as String;

  Widget _labelled(FieldPath path, Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_name(path), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            child,
          ],
        ),
      );

  Widget _choices(
    FieldPath path,
    List<String> options, {
    required bool Function(String option) isSelected,
    required void Function(String option) onTap,
    VoidCallback? onNone,
    bool noneSelected = false,
  }) {
    return _labelled(
      path,
      Wrap(
        key: Key('editeur-champ-${labelOf(path)}'),
        spacing: 4,
        runSpacing: 4,
        children: [
          if (onNone != null)
            ChoiceButton(label: 'aucun', isSelected: noneSelected, onTap: onNone),
          for (final option in options)
            ChoiceButton(
              label: option,
              isSelected: isSelected(option),
              onTap: () => onTap(option),
            ),
        ],
      ),
    );
  }

  Widget _textField(
    FieldPath path,
    String initial,
    ValueChanged<String> onChanged, {
    TextInputType? keyboard,
  }) {
    final label = labelOf(path);
    final controller = _controllers.putIfAbsent(
      label,
      () => TextEditingController(text: initial),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        key: Key('editeur-champ-$label'),
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: _name(path),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _objectList(FieldPath path, List<dynamic> list) {
    final label = labelOf(path);
    return _labelled(
      path,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < list.length; i++)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._objectFields(
                        [...path, i], list[i] as Map<String, dynamic>),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: Key('editeur-retirer-$label[$i]'),
                        onPressed: () {
                          _document.removeElement(path, i);
                          widget.onStructureChanged();
                        },
                        child: const Text('Retirer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          TextButton.icon(
            key: Key('editeur-ajouter-$label'),
            onPressed: () {
              if (_document.addElement(path)) widget.onStructureChanged();
            },
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  /// Les champs d'un objet ; une paire `x_fr` / `x_en` tient sur une rangee,
  /// francais a gauche.
  List<Widget> _objectFields(FieldPath prefix, Map<String, dynamic> map) {
    final widgets = <Widget>[];
    for (final entry in map.entries) {
      final key = entry.key;
      if (key.endsWith('_en') &&
          map.containsKey('${key.substring(0, key.length - 3)}_fr')) {
        continue; // rendu avec sa paire francaise
      }
      final english = key.endsWith('_fr')
          ? '${key.substring(0, key.length - 3)}_en'
          : null;
      if (english != null && map[english] is String && entry.value is String) {
        widgets.add(Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field([...prefix, key], entry.value)),
            const SizedBox(width: 8),
            Expanded(child: _field([...prefix, english], map[english])),
          ],
        ));
        continue;
      }
      widgets.add(_field([...prefix, key], entry.value));
    }
    return widgets;
  }

  Widget _stringList(FieldPath path, List<String> list) {
    final label = labelOf(path);
    return _labelled(
      path,
      Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < list.length; i++)
            InputChip(
              label: Text(list[i]),
              onDeleted: () {
                _document.setAt(path, [...list]..removeAt(i));
                widget.onStructureChanged();
              },
            ),
          SizedBox(
            width: 160,
            child: TextField(
              key: Key('editeur-ajouter-$label'),
              decoration: const InputDecoration(hintText: 'ajouter…'),
              onSubmitted: (text) {
                final added = text.trim();
                if (added.isEmpty) return;
                _document.setAt(path, [...list, added]);
                widget.onStructureChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}
