import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data/game_data_registry.dart';
import '../../services/content_editor/class_recipe.dart';
import '../../services/content_editor/content_editor_providers.dart';
import '../../services/content_editor/entity_catalog.dart';
import '../../services/content_editor/entity_descriptor.dart';
import '../../services/content_editor/entity_draft.dart';
import '../../services/content_editor/entity_validator.dart';
import '../../services/content_editor/entity_writer.dart';
import '../../services/content_editor/known_values.dart';
import '../../services/content_editor/placeholder_filler.dart';
import '../theme/app_colors.dart';
import '../widgets/content_editor/choice_button.dart';
import '../widgets/content_editor/color_field.dart';
import '../widgets/content_editor/entity_form.dart';
import '../widgets/content_editor/tree_level.dart';

/// Le niveau 1 de l'arbre : creer une entite neuve, ou modifier une existante.
enum _EditorMode { create, modify }

/// La couleur d'une classe dont `themeColor` n'a pas encore ete choisi : le
/// meme magenta que le gabarit, pour qu'un oubli se voie.
const Color _kUnsetThemeColor = Color(0xFFFF00FF);

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
  // Les trois niveaux de l'arbre. Rien ne se replie vers le haut : descendre
  // d'un niveau n'efface jamais celui du dessus, seulement ce qui pendait
  // dessous (voir les `onSelected` de chaque niveau, dans `_form`).
  EntityCategory? _category;
  _EditorMode? _mode;
  String? _target;
  String? _targetOwner;

  final TextEditingController _id = TextEditingController();
  final Map<String, TextEditingController> _prose = {};

  /// La boite JSON unique, en modification seulement — voir `EntityForm`.
  final TextEditingController _mechanics = TextEditingController();

  /// Un controleur par cle du gabarit (hors `themeColor`), en creation
  /// seulement.
  final Map<String, TextEditingController> _mechanicsFields = {};

  /// `themeColor`, hors `_mechanicsFields` : porte par un `ColorField`.
  Color _themeColor = _kUnsetThemeColor;

  /// Une selection par `referenceKeys` du descripteur — `passiveTrait` pour
  /// une classe.
  Map<String, String?> _referenceSelections = {};

  // La recette de classe (creation seulement) : combien de cartes de
  // signature, et pour chacune ses controleurs.
  final TextEditingController _cardCount = TextEditingController(text: '0');
  int _cardCountValue = 0;
  final List<TextEditingController> _cardIds = [];
  final List<TextEditingController> _cardNameFr = [];
  final List<TextEditingController> _cardNameEn = [];

  List<ValidationFault> _faults = const [];
  WriteReport? _report;
  String? _failure;

  /// Le chemin dont le contenu est actuellement dans le formulaire, relu du
  /// disque. `null` tant que rien n'a ete charge.
  ///
  /// En modification, l'ecriture le compare au chemin vise : le triangle
  /// d'identite reste saisissable — c'est ainsi qu'on **designe** la cible —
  /// mais il ne peut pas servir a deplacer ce qui a ete charge.
  String? _loadedPath;

  /// Deux espaces, comme `EntityWriter` et comme les fichiers du depot : ce
  /// qui est relu s'affiche exactement comme il sera reecrit.
  static const JsonEncoder _indented = JsonEncoder.withIndent('  ');

  /// La table des valeurs connues, et la categorie pour laquelle elle a ete
  /// calculee. Voir [_knownValuesFor].
  EntityCategory? _valuesFor;
  Map<String, List<String>> _values = const {};

  /// Ce que le disque montre, et la categorie pour laquelle il a ete lu. Voir
  /// [_ensureCatalog].
  EntityCategory? _catalogFor;
  Map<String?, List<String>> _byOwner = const {};
  List<String> _ownerClassIds = const [];
  Map<String, List<String>> _references = const {};
  final Map<String, Map<String, dynamic>?> _ownerJson = {};

  EntityDescriptor get _descriptor => kEntityDescriptors[_category]!;

  /// Une classe en creation entraine ses cartes de signature en un seul
  /// geste : c'est `ClassRecipe`, pas un `EntityDraft` isole, qui doit etre
  /// ecrit.
  bool get _isClassRecipe =>
      _category == EntityCategory.heroClass && _mode == _EditorMode.create;

  @override
  void dispose() {
    _id.dispose();
    _mechanics.dispose();
    for (final controller in _prose.values) {
      controller.dispose();
    }
    for (final controller in _mechanicsFields.values) {
      controller.dispose();
    }
    _cardCount.dispose();
    for (final controller in _cardIds) {
      controller.dispose();
    }
    for (final controller in _cardNameFr) {
      controller.dispose();
    }
    for (final controller in _cardNameEn) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadCategory() {
    // Un identifiant tape pour une categorie ne designe rien dans une autre :
    // garde, il restait affiche sous le nouveau formulaire comme s'il lui
    // appartenait.
    _id.clear();
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

    for (final controller in _mechanicsFields.values) {
      controller.dispose();
    }
    _mechanicsFields.clear();
    final template = _descriptor.decodeTemplate();
    template.forEach((key, value) {
      if (key == 'themeColor') return; // porte par le ColorField, a part
      _mechanicsFields[key] = TextEditingController(text: _initialFieldText(value));
    });
    final themeHex = template['themeColor'];
    _themeColor = themeHex is String
        ? (hexToColor(themeHex) ?? _kUnsetThemeColor)
        : _kUnsetThemeColor;
    _referenceSelections = {
      for (final key in _descriptor.referenceKeys.keys) key: null,
    };

    _setCardCount(0);

    _loadedPath = null;
    _faults = const [];
    _report = null;
    _failure = null;
  }

  /// Le texte initial d'un champ de creation, a partir de la valeur du
  /// gabarit : brut pour une chaine ou un nombre, JSON compact pour une liste
  /// ou un objet — `effects`, `intents`, `choices`.
  String _initialFieldText(Object? value) {
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value);
  }

  /// Convertit le texte saisi dans un champ de creation, en s'appuyant sur le
  /// **type de la valeur du gabarit** comme reference : un entier reste un
  /// entier, une liste reste une liste. Une saisie illisible retombe sur la
  /// valeur du gabarit plutot que de faire echouer la composition — la
  /// validation, elle, la jugera.
  Object? _coerce(String text, Object? templateValue) {
    final trimmed = text.trim();
    if (templateValue is int) {
      return int.tryParse(trimmed) ?? templateValue;
    }
    if (templateValue is double) {
      return num.tryParse(trimmed) ?? templateValue;
    }
    if (templateValue is bool) {
      if (trimmed == 'true') return true;
      if (trimmed == 'false') return false;
      return templateValue;
    }
    if (templateValue is List || templateValue is Map) {
      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return templateValue;
      }
    }
    return trimmed;
  }

  /// Le corps JSON compose depuis les champs de creation : un par cle du
  /// gabarit, plus `themeColor` et les `referenceKeys` selectionnees.
  String _composeCreateMechanics() {
    final template = _descriptor.decodeTemplate();
    final result = <String, dynamic>{};
    template.forEach((key, value) {
      if (key == 'themeColor') return;
      final controller = _mechanicsFields[key];
      result[key] = controller == null ? value : _coerce(controller.text, value);
    });
    if (_descriptor.category == EntityCategory.heroClass) {
      result['themeColor'] = colorToHex(_themeColor);
    }
    _referenceSelections.forEach((key, value) {
      if (value != null && value.isNotEmpty) result[key] = value;
    });
    return jsonEncode(result);
  }

  void _setCardCount(int n) {
    if (n < 0) n = 0;
    while (_cardIds.length < n) {
      _cardIds.add(TextEditingController());
      _cardNameFr.add(TextEditingController());
      _cardNameEn.add(TextEditingController());
    }
    while (_cardIds.length > n) {
      _cardIds.removeLast().dispose();
      _cardNameFr.removeLast().dispose();
      _cardNameEn.removeLast().dispose();
    }
    _cardCountValue = n;
    _cardCount.text = '$n';
  }

  EntityDraft _draft() => EntityDraft(
        descriptor: _descriptor,
        id: _id.text.trim(),
        heroClass: _descriptor.supportsHeroClass ? _targetOwner : null,
        isModification: _mode == _EditorMode.modify,
        bilingual: {
          for (final entry in _prose.entries) entry.key: entry.value.text,
        },
        mechanics: _mode == _EditorMode.modify
            ? _mechanics.text
            : _composeCreateMechanics(),
      );

  /// La recette d'une classe entiere : elle-meme, puis ses cartes de
  /// signature, dans l'ordre qu'exige `ClassRecipe.toDrafts()`.
  ClassRecipe _recipe() => ClassRecipe(
        id: _id.text.trim(),
        bilingual: {
          for (final entry in _prose.entries) entry.key: entry.value.text,
        },
        mechanics: _composeCreateMechanics(),
        signatureCards: [
          for (var i = 0; i < _cardCountValue; i++)
            SignatureCardInput(
              id: _cardIds[i].text.trim(),
              bilingual: {
                'name_fr': _cardNameFr[i].text,
                'name_en': _cardNameEn[i].text,
              },
            ),
        ],
      );

  /// Le document tel qu'il sera ecrit, et les fautes qui s'y opposent.
  ///
  /// **Un seul lieu pour les deux boutons.** « Valider » jugeait auparavant
  /// `_draft()` — un brouillon isole, non rempli, sans les cartes de la
  /// recette ni les fautes de `ClassRecipe.faults()` — la ou « Écrire » juge
  /// ceci. Deux cartes de signature homonymes, ou une carte non nommee,
  /// passaient donc Valider en silence et etaient refusees par Ecrire. Un
  /// bouton qui valide autre chose que ce qui sera ecrit est pire qu'un bouton
  /// absent.
  ///
  /// Le remplissage precede la validation, et cet ordre n'est pas negociable :
  /// la famille bilingue refuse la prose vide, c'est-a-dire exactement ce que
  /// `fillPlaceholders` est charge de fournir.
  ({List<EntityDraft> drafts, List<ValidationFault> faults}) _judge(
    String root,
  ) {
    final recipe = _isClassRecipe ? _recipe() : null;
    final drafts = recipe?.toDrafts() ?? [fillPlaceholders(_draft())];

    final validator = EntityValidator(
      fs: ref.read(contentFileSystemProvider)!,
      rootPath: root,
      registry: GameDataRegistry.instance,
    );

    return (
      drafts: drafts,
      faults: [
        // Les fautes de la recette d'abord : `EntityValidator` juge un
        // brouillon a la fois et ne peut pas voir que deux cartes de signature
        // partagent un identifiant — seule la recette voit l'ensemble.
        if (recipe != null) ...recipe.faults(),
        for (final draft in drafts) ...validator.validate(draft),
      ],
    );
  }

  /// Signale une impossibilite par le canal deja utilise pour les fautes de
  /// validation : c'est la meme place a l'ecran, et le formulaire n'est pas
  /// touche.
  void _refuse(String message) => setState(() {
        _faults = [ValidationFault(message)];
        _report = null;
        _failure = null;
      });

  /// Relit le fichier vise et le repartit dans le formulaire : la prose
  /// bilingue dans ses champs, tout le reste dans la boite JSON.
  ///
  /// **Sans cette relecture, « Modifier » ecrit le gabarit par-dessus la
  /// cible** : toute cle que le gabarit ne porte pas — le `skills` d'une
  /// classe, son `passiveTrait`, les `effects` d'une carte, les `intents` d'un
  /// ennemi — disparaitrait en silence, validation passee et ecriture reussie.
  void _load(String root) {
    final draft = _draft();
    final fs = ref.read(contentFileSystemProvider)!;
    final absolute = '$root/${draft.path}';

    if (!fs.fileExists(absolute)) {
      _refuse('aucun fichier à charger en ${draft.path}');
      return;
    }

    final Map<String, dynamic> document;
    try {
      document = jsonDecode(fs.readFile(absolute)) as Map<String, dynamic>;
    } catch (e) {
      // Un fichier retouche a la main peut ne plus decoder : le dire vaut
      // mieux que de lever depuis un rappel de bouton.
      _refuse('${draft.path} ne se relit pas : $e');
      return;
    }

    setState(() {
      // Les cles de `_prose` **sont** les cles bilingues de la categorie.
      for (final entry in _prose.entries) {
        final value = document[entry.key];
        entry.value.text = value is String ? value : '';
      }
      // Ni `id`, qui a son propre champ, ni le chemin de l'image, que
      // l'ecrivain calcule : les remettre dans la boite en ferait des valeurs
      // saisies a la main, ce que l'outil existe justement pour eviter.
      _mechanics.text = _indented.convert({
        for (final entry in document.entries)
          if (entry.key != 'id' &&
              entry.key != _descriptor.imagePathKey &&
              !_prose.containsKey(entry.key))
            entry.key: entry.value,
      });
      _loadedPath = draft.path;
      _faults = const [];
      _report = null;
      _failure = null;
    });
  }

  Future<void> _write(String root) async {
    // Le triangle d'identite designe la cible sans jamais la deplacer : en
    // modification, on n'ecrit que sur un fichier qui vient d'etre relu. Le
    // changer apres coup invalide le chargement, et l'ecriture est refusee
    // plutot que d'ecraser une entite avec le contenu d'une autre.
    if (_mode == _EditorMode.modify && _loadedPath != _draft().path) {
      _refuse(
        'charger le fichier avant de le modifier : sans sa relecture, seul le '
        'gabarit serait écrit',
      );
      return;
    }

    final writer = EntityWriter(
      fs: ref.read(contentFileSystemProvider)!,
      rootPath: root,
    );

    // Exactement ce que « Valider » vient de juger, ou aurait juge : le
    // document est construit une seule fois, par `_judge`.
    final (:drafts, :faults) = _judge(root);
    setState(() {
      _faults = faults;
      _report = null;
      _failure = null;
    });
    // Decision E6 : rien n'est ecrit avant que la validation entiere passe.
    if (faults.isNotEmpty) return;

    try {
      final report = await writer.writeAll(drafts);
      if (mounted) {
        setState(() {
          _report = report;
          // L'entite ecrite vient d'ajouter ses valeurs au vocabulaire, et un
          // fichier a l'arborescence.
          _valuesFor = null;
          _catalogFor = null;
          // Retour a la branche 0 : la nouvelle entite n'est pas dans le
          // registre avant le redemarrage a chaud, et ouvrir son formulaire ferait
          // croire le contraire. Le compte rendu, lui, reste affiche — voir
          // `_form`.
          if (drafts.any((d) => !d.isModification)) {
            _category = null;
            _mode = null;
            _target = null;
            _targetOwner = null;
          }
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
      appBar: AppBar(title: const Text('Éditeur de contenu')),
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
                ),
              ),
            )
          : _form(root),
    );
  }

  /// Les trois niveaux de l'arbre, puis — une fois un type et un mode choisis
  /// — le formulaire d'entite lui-meme.
  ///
  /// Le compte rendu (`_outcome`) est rendu **une seule fois**, a l'un des
  /// deux endroits selon qu'une branche est ouverte : dans le formulaire tant
  /// qu'il est visible, ou ici quand la branche vient de se refermer — sans
  /// quoi une creation qui revient a la branche 0 ferait disparaitre son
  /// propre compte rendu.
  Widget _form(String root) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TreeLevel(
            caption: 'Type',
            choices: [
              for (final descriptor in kEntityDescriptors.values)
                TreeChoice(value: descriptor.category, label: descriptor.label),
            ],
            selected: _category,
            onSelected: (value) => setState(() {
              // Changer de type referme tout ce qui pendait dessous : une
              // cible d'une autre categorie n'a plus de sens.
              _category = value as EntityCategory;
              _mode = null;
              _target = null;
              _targetOwner = null;
              _loadCategory();
            }),
          ),
          if (_category != null)
            TreeLevel(
              depth: 1,
              caption: 'Action',
              choices: const [
                TreeChoice(value: _EditorMode.create, label: 'Créer'),
                TreeChoice(value: _EditorMode.modify, label: 'Modifier'),
              ],
              selected: _mode,
              onSelected: (value) => setState(() {
                _mode = value as _EditorMode;
                _target = null;
                _targetOwner = null;
              }),
            ),
          if (_mode == _EditorMode.modify) _targetLevel(root),
          if (_category != null && _mode != null)
            Expanded(child: _entityFormRow(root))
          else
            _outcome(),
        ],
      ),
    );
  }

  /// Le niveau 2 : ce qui existe, groupe par proprietaire et colore par lui.
  Widget _targetLevel(String root) {
    _ensureCatalog(root);
    final byOwner = _byOwner;

    final choices = <TreeChoice>[];
    // Les neutres d'abord, puis chaque classe en bloc : le groupement se voit
    // sans qu'il faille un niveau de plus.
    final owners = byOwner.keys.whereType<String>().toList()..sort();
    for (final owner in [null, ...owners]) {
      for (final id in byOwner[owner] ?? const <String>[]) {
        choices.add(TreeChoice(
          value: '${owner ?? ''}/$id',
          label: id,
          identityColor: owner == null
              ? kNeutralOwnerColor
              : _ownerColor(root, owner) ?? kNeutralOwnerColor,
          imagePath: owner == null ? null : _ownerImage(root, owner),
        ));
      }
    }

    return TreeLevel(
      depth: 2,
      caption: 'Entité',
      choices: choices,
      selected: _target == null ? null : '${_targetOwner ?? ''}/$_target',
      onSelected: (value) {
        setState(() {
          final parts = (value as String).split('/');
          _targetOwner = parts.first.isEmpty ? null : parts.first;
          _target = parts.last;
          // (a) Choisir une entite ici designe reellement la cible : sans
          // cette ligne, le surlignage divergeait en silence de ce que
          // « Charger » et « Écrire » visaient — `_target` changeait, l'usager
          // le voyait selectionne, mais le triangle d'identite pointait
          // ailleurs.
          _id.text = _target!;
        });
        // Choisir, c'est charger : sans relecture, la boite JSON montrait le
        // gabarit — le meme pour toutes les entites — ou le contenu de
        // l'entite choisie juste avant. « Charger » ne sert plus qu'a relire
        // un identifiant tape a la main.
        _load(root);
      },
    );
  }

  /// `themeColor` de `assets/data/classes/<owner>/class.json`. `null` si le
  /// fichier manque ou ne decode pas — un dossier incomplet ne doit pas faire
  /// tomber l'ecran.
  Color? _ownerColor(String root, String owner) {
    final hex = _ownerClassJson(root, owner)?['themeColor'];
    return hex is String ? hexToColor(hex) : null;
  }

  /// L'icone de la classe proprietaire, ou a defaut sa carte. Meme tolerance
  /// aux dossiers incomplets que [_ownerColor].
  String? _ownerImage(String root, String owner) {
    final json = _ownerClassJson(root, owner);
    if (json == null) return null;
    final icon = json['iconPath'];
    if (icon is String) return icon;
    final classCard = json['classCard'];
    return classCard is String ? classCard : null;
  }

  /// Le contenu decode de `assets/data/classes/<owner>/class.json`, ou `null`
  /// si le fichier manque ou ne decode pas.
  ///
  /// Retenu par proprietaire, et vide par [_ensureCatalog] : chaque bouton de
  /// carte de classe demande sa couleur **et** son image, et `build` est
  /// relance a chaque frappe. Sans cette table, une liste de vingt cartes de
  /// classe relisait et decodait le meme fichier quarante fois par caractere
  /// tape.
  Map<String, dynamic>? _ownerClassJson(String root, String owner) {
    if (_ownerJson.containsKey(owner)) return _ownerJson[owner];

    final fs = ref.read(contentFileSystemProvider)!;
    final path = '$root/assets/data/classes/$owner/class.json';
    Map<String, dynamic>? result;
    if (fs.fileExists(path)) {
      try {
        final decoded = jsonDecode(fs.readFile(path));
        if (decoded is Map<String, dynamic>) result = decoded;
      } catch (_) {
        // Un dossier incomplet ne doit pas faire tomber l'ecran.
      }
    }
    return _ownerJson[owner] = result;
  }

  /// Lit le disque **une fois par categorie**, et retient ce qu'il a vu.
  ///
  /// Meme patron que [_knownValuesFor], et pour la meme raison : chacun de ces
  /// appels a `entityIdsByOwner` enumere une arborescence entiere, et `build`
  /// est relance a **chaque frappe** dans le champ identifiant. La table est
  /// donc retenue tant que la categorie ne change pas, et invalidee apres une
  /// ecriture — qui, elle, ajoute un fichier.
  ///
  /// A n'appeler qu'une categorie choisie : [_descriptor] la suppose.
  void _ensureCatalog(String root) {
    if (_catalogFor == _category) return;
    final fs = ref.read(contentFileSystemProvider)!;

    _byOwner = entityIdsByOwner(fs, root, _descriptor);

    // (b) La rangee de pastilles de proprietaire n'existe que pour une carte,
    // et seulement en creation : `EntityForm` ne la montre pas autrement.
    // Enumerer les classes en modification etait un calcul pur perdu.
    _ownerClassIds = _descriptor.supportsHeroClass
        ? (List<String>.from(
            entityIdsByOwner(
                  fs,
                  root,
                  kEntityDescriptors[EntityCategory.heroClass]!,
                )[null] ??
                const <String>[],
          )..sort())
        : const [];

    // Le catalogue de chaque `referenceKeys` du descripteur — tire de
    // `entityIdsByOwner`, jamais de `knownValues` : ce dernier ne liste que
    // les valeurs deja employees, et un passif jamais utilise y serait
    // invisible.
    _references = {
      for (final entry in _descriptor.referenceKeys.entries)
        entry.key: [
          for (final ids
              in entityIdsByOwner(fs, root, kEntityDescriptors[entry.value]!)
                  .values)
            ...ids,
        ]..sort(),
    };

    _ownerJson.clear();
    _catalogFor = _category;
  }

  /// Le formulaire d'une entite, et a droite le panneau de valeurs connues.
  Widget _entityFormRow(String root) {
    _ensureCatalog(root);
    final draft = _draft();
    final isModification = _mode == _EditorMode.modify;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: EntityForm(
            descriptor: _descriptor,
            isModification: isModification,
            idController: _id,
            onIdentityChanged: () => setState(() {}),
            pathPreview: draft.path,
            proseControllers: _prose,
            onLoad: isModification ? () => _load(root) : null,
            ownerClassIds: isModification ? const [] : _ownerClassIds,
            selectedOwner: _targetOwner,
            onOwnerSelected: (value) => setState(() => _targetOwner = value),
            ownerColorOf: (classId) => _ownerColor(root, classId),
            mechanicsController: isModification ? _mechanics : null,
            templateFieldControllers: isModification ? const {} : _mechanicsFields,
            themeColor: isModification || _descriptor.category != EntityCategory.heroClass
                ? null
                : _themeColor,
            onThemeColorChanged: (color) => setState(() => _themeColor = color),
            referenceOptions: isModification ? const {} : _references,
            referenceSelections: _referenceSelections,
            onReferenceSelected: (key, value) => setState(() {
              _referenceSelections = {..._referenceSelections, key: value};
            }),
            showSignatureCards: _isClassRecipe,
            cardCountController: _cardCount,
            cardCount: _cardCountValue,
            onCardCountChanged: (n) => setState(() => _setCardCount(n)),
            cardIds: _cardIds,
            cardNameFr: _cardNameFr,
            cardNameEn: _cardNameEn,
            onValidate: () => setState(() => _faults = _judge(root).faults),
            onWrite: () => _write(root),
            outcome: _outcome(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _knownValuesPanel(root)),
      ],
    );
  }

  /// L'issue du dernier geste, coloree par sa nature : un refus en rouge, une
  /// ecriture en vert, et en ambre ce qu'il reste a faire pour la voir.
  Widget _outcome() {
    const refused = TextStyle(color: AppColors.danger);
    if (_failure != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text('Échec : $_failure', style: refused),
      );
    }
    if (_faults.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final fault in _faults) Text('• $fault', style: refused),
          ],
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
          for (final path in report.written)
            Text(
              'Écrit : $path',
              style: const TextStyle(color: AppColors.success),
            ),
          if (report.syncFailed)
            Text('sync_assets a échoué : ${report.sync!.output}', style: refused),
          // §6.3 de la spec : pour une creation, le redemarrage a chaud a ete
          // verifie a la main le 2026-09-14 ; la modification reste en test.
          Text(
            report.createdEntity
                ? 'Redémarrage à chaud pour charger la nouvelle entité.'
                : 'Redémarrage à chaud pour voir la modification.',
            style: const TextStyle(color: AppColors.warning),
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
          'Valeurs déjà utilisées',
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
