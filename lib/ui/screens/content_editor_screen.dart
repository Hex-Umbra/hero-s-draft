import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data/game_data_registry.dart';
import '../../services/content_editor/content_editor_providers.dart';
import '../../services/content_editor/entity_descriptor.dart';
import '../../services/content_editor/entity_draft.dart';
import '../../services/content_editor/entity_validator.dart';
import '../../services/content_editor/entity_writer.dart';
import '../../services/content_editor/known_values.dart';

/// Editeur de contenu. **Hors run** : il ne touche a aucun etat de jeu, et le
/// verrou de persistance du lot 1 ne le concerne pas.
///
/// Les libelles sont en francais dans le code, exception delibaree et limitee
/// a cet ecran : ajouter des cles ARB pour un outil jamais publie serait un
/// cout pur.
class ContentEditorScreen extends ConsumerStatefulWidget {
  const ContentEditorScreen({super.key});

  @override
  ConsumerState<ContentEditorScreen> createState() =>
      _ContentEditorScreenState();
}

class _ContentEditorScreenState extends ConsumerState<ContentEditorScreen> {
  EntityCategory _category = EntityCategory.card;
  bool _isModification = false;
  String? _heroClass;

  final TextEditingController _id = TextEditingController();
  final TextEditingController _mechanics = TextEditingController();
  final Map<String, TextEditingController> _prose = {};

  List<ValidationFault> _faults = const [];
  WriteReport? _report;
  String? _failure;

  /// La table des valeurs connues, et la categorie pour laquelle elle a ete
  /// calculee. Voir [_knownValuesFor].
  EntityCategory? _valuesFor;
  Map<String, List<String>> _values = const {};

  EntityDescriptor get _descriptor => kEntityDescriptors[_category]!;

  @override
  void initState() {
    super.initState();
    _loadCategory();
  }

  @override
  void dispose() {
    _id.dispose();
    _mechanics.dispose();
    for (final controller in _prose.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadCategory() {
    _mechanics.text = _descriptor.template;
    for (final controller in _prose.values) {
      controller.dispose();
    }
    _prose.clear();
    for (final base in _descriptor.bilingualBases) {
      for (final suffix in const ['fr', 'en']) {
        _prose['${base}_$suffix'] = TextEditingController();
      }
    }
    _faults = const [];
    _report = null;
    _failure = null;
  }

  EntityDraft _draft() => EntityDraft(
        descriptor: _descriptor,
        id: _id.text.trim(),
        heroClass: _descriptor.supportsHeroClass ? _heroClass : null,
        isModification: _isModification,
        bilingual: {
          for (final entry in _prose.entries) entry.key: entry.value.text,
        },
        mechanics: _mechanics.text,
      );

  List<ValidationFault> _validate(String root) => EntityValidator(
        fs: ref.read(contentFileSystemProvider)!,
        rootPath: root,
        registry: GameDataRegistry.instance,
      ).validate(_draft());

  Future<void> _write(String root) async {
    final faults = _validate(root);
    setState(() {
      _faults = faults;
      _report = null;
      _failure = null;
    });
    // Decision E6 : rien n'est ecrit avant que la validation entiere passe.
    if (faults.isNotEmpty) return;

    try {
      final report = await EntityWriter(
        fs: ref.read(contentFileSystemProvider)!,
        rootPath: root,
      ).write(_draft());
      if (mounted) {
        setState(() {
          _report = report;
          // L'entite ecrite vient d'ajouter ses valeurs au vocabulaire.
          _valuesFor = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _failure = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = ref.watch(projectRootProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Editeur de contenu')),
      body: root == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Cette application ne tourne pas depuis une arborescence "
                  "source : aucun repertoire parent ne porte a la fois "
                  "pubspec.yaml et assets/data/. L'editeur ne peut pas savoir "
                  "ou ecrire, et refuse donc de s'ouvrir.",
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _form(root),
    );
  }

  Widget _form(String root) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            // Les champs defilent seuls, dans leur propre `Expanded` : le
            // champ JSON (14 lignes) a lui seul depasse la hauteur d'un
            // panneau, et une simple `ListView` ne construit que les enfants
            // proches de la fenetre visible — les boutons plus bas n'y
            // seraient jamais, invisibles aux tests comme au clic. Valider,
            // Ecrire et l'issue restent donc **hors** du defilement, toujours
            // a portee.
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _identityTriangle(root),
                        const Divider(),
                        for (final entry in _prose.entries)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextField(
                              controller: entry.value,
                              decoration:
                                  InputDecoration(labelText: entry.key),
                            ),
                          ),
                        const Divider(),
                        TextField(
                          controller: _mechanics,
                          maxLines: 14,
                          style: const TextStyle(fontFamily: 'monospace'),
                          decoration: const InputDecoration(
                            labelText: 'Mecanique (JSON)',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _faults = _validate(root)),
                      child: const Text('Valider'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _write(root),
                      child: const Text('Ecrire'),
                    ),
                  ],
                ),
                _outcome(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _knownValuesPanel(root)),
        ],
      ),
    );
  }

  Widget _identityTriangle(String root) {
    final draft = _draft();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // `Wrap` plutot que `Row` : l'intitule le plus long ("Amelioration de
        // forge") reste affiche meme quand une autre categorie est
        // selectionnee — `DropdownButton` dimensionne son bouton ferme sur le
        // plus large de ses items, pas sur celui qui est choisi — et un `Row`
        // sans enfant flexible deborderait plutot que de passer a la ligne.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            DropdownButton<EntityCategory>(
              value: _category,
              items: [
                for (final entry in kEntityDescriptors.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value.label),
                  ),
              ],
              onChanged: _isModification
                  ? null
                  : (value) => setState(() {
                        if (value == null) return;
                        _category = value;
                        _heroClass = null;
                        _loadCategory();
                      }),
            ),
            // Le triangle d'identite est **gele** en modification : il decide
            // ou est le fichier, et le deplacer serait un renommage — hors
            // perimetre (E1).
            Switch(
              value: _isModification,
              onChanged: (value) => setState(() => _isModification = value),
            ),
            Text(_isModification ? 'Modifier' : 'Creer'),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('editeur-id'),
                controller: _id,
                enabled: !_isModification,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Identifiant'),
              ),
            ),
            if (_descriptor.supportsHeroClass) ...[
              const SizedBox(width: 16),
              DropdownButton<String?>(
                value: _heroClass,
                hint: const Text('neutre'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('neutre')),
                  for (final hero in GameDataRegistry.instance?.heroes ??
                      const <dynamic>[])
                    DropdownMenuItem(
                      value: hero.id as String,
                      child: Text(hero.id as String),
                    ),
                ],
                onChanged: _isModification
                    ? null
                    : (value) => setState(() => _heroClass = value),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // Le retour le plus utile de l'ecran : la consequence du choix de
        // classe, montree avant l'ecriture.
        Text(
          draft.id.isEmpty ? '(identifiant requis)' : draft.path,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  Widget _outcome() {
    if (_failure != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text('Echec : $_failure'),
      );
    }
    if (_faults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final fault in _faults) Text('• $fault')],
        ),
      );
    }
    final report = _report;
    if (report == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final path in report.written) Text('Ecrit : $path'),
          if (report.syncFailed)
            Text('sync_assets a echoue : ${report.sync!.output}'),
          // Voir §6.3 de la spec : la regle conservatrice, jusqu'a ce que la
          // verification manuelle permette de la resserrer.
          Text(
            report.relaunchAdvised
                ? 'Relancer `flutter run` pour que la nouvelle entite soit '
                    'chargee : le manifeste d assets est produit a la '
                    'compilation.'
                : 'Redemarrage a chaud pour voir la modification.',
          ),
        ],
      ),
    );
  }

  /// Le panneau relit tout le repertoire de la categorie : hors de question de
  /// le faire a chaque frappe. La table est donc retenue tant que la categorie
  /// ne change pas, et invalidee apres une ecriture — qui, elle, ajoute une
  /// valeur.
  Map<String, List<String>> _knownValuesFor(String root) {
    if (_valuesFor != _category) {
      _values = knownValues(
        ref.read(contentFileSystemProvider)!,
        root,
        _descriptor,
      );
      _valuesFor = _category;
    }
    return _values;
  }

  Widget _knownValuesPanel(String root) {
    final values = _knownValuesFor(root);

    return ListView(
      children: [
        const Text(
          'Valeurs deja utilisees',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (final entry in values.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '${entry.key} : ${entry.value.join(', ')}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
