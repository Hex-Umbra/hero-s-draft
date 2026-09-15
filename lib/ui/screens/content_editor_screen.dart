import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/data/game_data_registry.dart';
import '../../services/content_editor/audio_catalog.dart';
import '../../services/content_editor/class_recipe.dart';
import '../../services/content_editor/content_editor_providers.dart';
import '../../services/content_editor/editor_document.dart';
import '../../services/content_editor/entity_catalog.dart';
import '../../services/content_editor/entity_descriptor.dart';
import '../../services/content_editor/entity_draft.dart';
import '../../services/content_editor/entity_validator.dart';
import '../../services/content_editor/entity_writer.dart';
import '../../services/content_editor/known_values.dart';
import '../../services/content_editor/pending_import.dart';
import '../../services/content_editor/placeholder_filler.dart';
import '../widgets/content_editor/asset_field.dart';
import '../widgets/content_editor/choice_button.dart';
import '../widgets/content_editor/color_field.dart';
import '../widgets/content_editor/document_form.dart';
import '../widgets/content_editor/editor_action_bar.dart';
import '../widgets/content_editor/editor_app_bar.dart';
import '../widgets/content_editor/editor_button.dart';
import '../widgets/content_editor/editor_panel.dart';
import '../widgets/content_editor/editor_segmented.dart';
import '../widgets/content_editor/editor_style.dart';
import '../widgets/content_editor/editor_toolbar.dart';
import '../widgets/content_editor/entity_explorer.dart';
import '../widgets/content_editor/entity_form.dart';
import '../widgets/content_editor/field_anchors.dart';
import '../widgets/content_editor/reference_panel.dart';
import '../widgets/screen_scaffold.dart';

/// Le niveau 1 de l'arbre : creer une entite neuve, ou modifier une existante.
enum _EditorMode { create, modify }

/// Editeur de contenu. **Hors run** : il ne touche a aucun etat de jeu, et le
/// verrou de persistance du lot 1 ne le concerne pas.
///
/// La barre d'outils (`EditorToolbar`) choisit le type et l'action ; viennent
/// ensuite le formulaire (`EntityForm`) et sa barre d'actions
/// (`EditorActionBar`), l'explorateur (`EntityExplorer`) a gauche en mode
/// Modifier, et le panneau de reference (`ReferencePanel`) a droite quand la
/// place le permet.
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
  // dessous (voir les `onSelected` de chaque niveau, dans `_workspace` et
  // `_explorer`).
  EntityCategory? _category;
  _EditorMode? _mode;
  String? _target;
  String? _targetOwner;

  final TextEditingController _id = TextEditingController();
  final Map<String, TextEditingController> _prose = {};

  /// Le document de la mecanique — voir `EditorDocument`.
  EditorDocument? _document;

  /// Change a chaque remplacement ou changement de structure du document :
  /// `DocumentForm` est alors recree, ses controleurs avec lui.
  int _revision = 0;

  /// La vue « JSON brut », et son texte.
  bool _rawView = false;
  final TextEditingController _raw = TextEditingController();

  /// Les imports en attente d'« Écrire » : cle de ressource -> fichier choisi.
  /// La destination est recalculee au moment de juger, l'identifiant pouvant
  /// changer d'ici la.
  final Map<String, String> _importSources = {};
  final Map<String, String> _importSoundIds = {};

  /// Les octets d'image deja lus, par chemin : une carte de classe pese
  /// 6,5 Mo, et `build` est relance a chaque frappe.
  final Map<String, Uint8List?> _images = {};

  /// Les sons d'`audio.json`, lus avec le catalogue de la categorie.
  List<String> _soundIds = const [];

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

  /// Les ancres des champs, pour que le bandeau d'issue y ramene.
  final FieldAnchors _anchors = FieldAnchors();

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
    _raw.dispose();
    for (final controller in _prose.values) {
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
    for (final controller in _prose.values) {
      controller.dispose();
    }
    _prose.clear();
    for (final base in _descriptor.bilingualBases) {
      for (final suffix in const ['fr', 'en']) {
        _prose['${base}_$suffix'] = TextEditingController();
      }
    }

    _seedDocument(_templateSeed());

    _setCardCount(0);

    // Une autre entite prend la place : un import en attente pour l'ancienne
    // n'a plus de sens.
    _importSources.clear();
    _importSoundIds.clear();
    _images.clear();

    _loadedPath = null;
    _faults = const [];
    _report = null;
    _failure = null;
  }

  /// Le document de depart d'un formulaire neuf : le gabarit, plus, pour une
  /// classe en creation, l'emplacement de son icone. Present d'emblee, il
  /// montre le chemin calcule et « aucune » le retire vraiment ; sa valeur
  /// n'est jamais saisie, `compose()` la recalcule.
  Map<String, dynamic> _templateSeed() => {
        ..._descriptor.decodeTemplate(),
        if (_isClassRecipe) 'iconPath': 'icon.png',
      };

  /// Remplace le document, et referme la vue brute.
  void _seedDocument(Map<String, dynamic> seed) {
    _document = EditorDocument(
      seed,
      requiredKeys: _descriptor.requiredKeys,
      template: _descriptor.decodeTemplate(),
    );
    _revision++;
    _rawView = false;
  }

  /// Le texte que juge la validation : la vue brute telle quelle, ou le
  /// document, regle d'omission appliquee.
  String _mechanicsText() => _rawView ? _raw.text : _document!.toMechanics();

  void _toggleRaw() {
    if (!_rawView) {
      setState(() {
        _raw.text = _indented.convert(_document!.root);
        _rawView = true;
      });
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(_raw.text);
    } on FormatException catch (e) {
      _refuse('le JSON brut ne se relit pas : ${e.message}');
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      _refuse('le JSON brut ne se relit pas : il doit être un objet');
      return;
    }
    final Map<String, dynamic> map = decoded;
    setState(() {
      _seedDocument(map);
      _faults = const [];
    });
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
        mechanics: _mechanicsText(),
      );

  /// La recette d'une classe entiere : elle-meme, puis ses cartes de
  /// signature, dans l'ordre qu'exige `ClassRecipe.toDrafts()`.
  ClassRecipe _recipe() => ClassRecipe(
        id: _id.text.trim(),
        bilingual: {
          for (final entry in _prose.entries) entry.key: entry.value.text,
        },
        mechanics: _mechanicsText(),
        // « aucune » a retire l'emplacement de l'icone : la recette ne le
        // remet pas. Une vue brute illisible garde le defaut ; la validation
        // la refusera de toute facon.
        withIcon: _currentMechanics()?.containsKey('iconPath') ?? true,
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
      imports: _pendingImports(),
    );

    return (
      drafts: drafts,
      faults: [
        // Les fautes de conversion du document d'abord : une saisie illisible
        // (« 1a » pour un entier) ne decode meme pas en un brouillon coherent.
        if (!_rawView) ..._document!.conversionFaults,
        // Les fautes de la recette ensuite : `EntityValidator` juge un
        // brouillon a la fois et ne peut pas voir que deux cartes de signature
        // partagent un identifiant — seule la recette voit l'ensemble.
        if (recipe != null) ...recipe.faults(),
        for (final draft in drafts) ...validator.validate(draft),
      ],
    );
  }

  /// Le corps courant du formulaire — vue document, ou vue brute decodee.
  /// `null` si la vue brute ne decode pas en objet : la validation la
  /// refusera de toute facon, inutile de deviner ici.
  Map<String, dynamic>? _currentMechanics() {
    if (!_rawView) return _document!.root;
    try {
      final decoded = jsonDecode(_raw.text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  /// Les imports choisis, prets pour le validateur ou l'ecrivain.
  ///
  /// Un import reste dans `_importSources` jusqu'a « Écrire » ou un
  /// changement d'entite, mais le corps qu'il devait alimenter peut avoir
  /// change sous lui entre-temps — la vue brute retouchee a la main, ou la
  /// cle simplement retiree du formulaire. Un tel import est **orphelin** :
  /// il ne correspond plus a ce que le formulaire montre, et l'ecrire
  /// copierait un fichier et declarerait un son que rien ne reference. Une
  /// image obligatoire, elle, n'est jamais dans le corps (l'ecrivain la
  /// calcule) : son import reste toujours retenu.
  List<PendingImport> _pendingImports() {
    final id = _id.text.trim();
    final mechanics = _currentMechanics();
    final imports = <PendingImport>[];
    for (final entry in _importSources.entries) {
      final key = entry.key;
      final slot = _descriptor.assetKeys[key]!;
      if (slot.kind == AssetKind.sound) {
        final soundId = _importSoundIds[key]!;
        if (mechanics != null && mechanics[key] != soundId) continue;
        imports.add(PendingImport.sound(
          key: key,
          sourcePath: entry.value,
          soundId: soundId,
        ));
      } else {
        if (!slot.isRequired &&
            mechanics != null &&
            !mechanics.containsKey(key)) {
          continue;
        }
        imports.add(PendingImport.image(
          descriptor: _descriptor,
          id: id,
          key: key,
          sourcePath: entry.value,
        ));
      }
    }
    return imports;
  }

  /// Ouvre le selecteur pour [key], puis — pour un son — demande son
  /// identifiant. Rien n'est copie ici : l'import entre dans la meme
  /// transaction que l'entite, et n'agit qu'au moment d'« Écrire ».
  Future<void> _importAsset(String key, AssetSlot slot) async {
    // Sous Windows et Linux, la fenetre du selecteur ne bloque pas celle de
    // Flutter : l'usager peut changer d'entite pendant qu'elle est ouverte.
    // Le document capture avant l'attente sert de temoin — s'il a change au
    // reveil, l'import ne vise plus le formulaire courant et est abandonne.
    final document = _document;
    final picked =
        await ref.read(assetPickerProvider).pickFile(extensions: slot.extensions);
    if (picked == null || !mounted || !identical(document, _document)) return;
    final source = picked.replaceAll(r'\', '/');

    if (slot.kind == AssetKind.sound) {
      final soundId = await showDialog<String>(
        context: context,
        builder: (_) => _SoundIdDialog(initial: _id.text.trim()),
      );
      if (soundId == null ||
          soundId.isEmpty ||
          !mounted ||
          !identical(document, _document)) {
        return;
      }
      setState(() {
        _importSources[key] = source;
        _importSoundIds[key] = soundId;
        _document!.setAt([key], soundId);
      });
      return;
    }

    setState(() {
      _importSources[key] = source;
      // Une image optionnelle (`iconPath`) n'est ecrite que si le corps la
      // porte : l'importer la fait entrer. Pas avec `''`, que la regle
      // d'omission retirerait — avec le chemin, que `compose()` recalcule.
      if (!slot.isRequired) {
        _document!.setAt([key], _descriptor.imagePathOf(_id.text.trim(), key));
      }
      _images.remove(source);
    });
  }

  /// Les octets d'un fichier image, retenus par chemin : `build` est relance
  /// a chaque frappe, et une carte de classe pese 6,5 Mo.
  Uint8List? _bytesOf(String absolute) => _images.putIfAbsent(absolute, () {
        final fs = ref.read(contentFileSystemProvider)!;
        return fs.fileExists(absolute) ? fs.readBytes(absolute) : null;
      });

  /// Signale une impossibilite par le canal deja utilise pour les fautes de
  /// validation : c'est la meme place a l'ecran, et le formulaire n'est pas
  /// touche.
  void _refuse(String message) => setState(() {
        _faults = [ValidationFault(message)];
        _report = null;
        _failure = null;
      });

  /// Relit le fichier vise et le repartit dans le formulaire : la prose
  /// bilingue dans ses champs, tout le reste dans le document dont la
  /// mecanique est inferee — et que la vue JSON brute montre telle quelle.
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
      // Ni `id`, qui a son propre champ, ni une image obligatoire, que
      // l'ecrivain calcule : les remettre dans le document en ferait des
      // valeurs saisies a la main, ce que l'outil existe justement pour
      // eviter.
      _seedDocument({
        for (final entry in document.entries)
          if (entry.key != 'id' &&
              !_descriptor.isComputedImage(entry.key) &&
              !_prose.containsKey(entry.key))
            entry.key: entry.value,
      });
      // Le fichier relu remplace le formulaire : un import en attente visait
      // l'ancien contenu.
      _importSources.clear();
      _importSoundIds.clear();
      _images.clear();
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
      final report = await writer.writeAll(drafts, imports: _pendingImports());
      if (mounted) {
        setState(() {
          _report = report;
          // L'entite ecrite vient d'ajouter ses valeurs au vocabulaire, et un
          // fichier a l'arborescence.
          _valuesFor = null;
          _catalogFor = null;
          // Les imports viennent d'etre copies et declares : plus rien n'est
          // en attente.
          _importSources.clear();
          _importSoundIds.clear();
          _images.clear();
          // Retour a la branche 0 : la nouvelle entite n'est pas dans le
          // registre avant le redemarrage a chaud, et ouvrir son formulaire ferait
          // croire le contraire. Le compte rendu, lui, reste affiche — voir
          // `_idle`.
          if (drafts.any((d) => !d.isModification)) {
            _category = null;
            _mode = null;
            _target = null;
            _targetOwner = null;
            // Le document part avec la branche : un selecteur encore ouvert
            // qui reviendrait ensuite le trouverait identique a son temoin,
            // et viserait un formulaire qui n'existe plus.
            _document = null;
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
                    // Retaper le mode courant ne reensemence pas le document.
                    if (mode == _mode) return;
                    _mode = mode;
                    _target = null;
                    _targetOwner = null;
                    _seedDocument(_templateSeed());
                    _loadedPath = null;
                    // Rien de choisi encore sous ce mode : un import en
                    // attente visait le formulaire precedent.
                    _importSources.clear();
                    _importSoundIds.clear();
                    _images.clear();
                  }),
                ),
        ),
        Expanded(child: hasForm ? _editing(root) : _idle()),
      ],
    );
  }

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
          // « Charger » et « Écrire » visaient — `_target` changeait, l'usager
          // le voyait selectionne, mais le triangle d'identite pointait
          // ailleurs.
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

  /// `themeColor` de `assets/data/classes/<owner>/class.json`. `null` si le
  /// fichier manque ou ne decode pas — un dossier incomplet ne doit pas faire
  /// tomber l'ecran.
  Color? _ownerColor(String root, String owner) {
    final hex = _ownerClassJson(root, owner)?['themeColor'];
    return hex is String ? hexToColor(hex) : null;
  }

  /// Le contenu decode de `assets/data/classes/<owner>/class.json`, ou `null`
  /// si le fichier manque ou ne decode pas.
  ///
  /// Retenu par proprietaire, et vide par [_ensureCatalog] : l'explorateur,
  /// les pastilles et l'en-tete demandent chacun sa couleur, et `build` est
  /// relance a chaque frappe. Sans cette table, une liste de vingt cartes de
  /// classe relisait et decodait le meme fichier a chaque caractere tape.
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

    _soundIds = soundIds(fs, root);

    _ownerJson.clear();
    _catalogFor = _category;
  }

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

  Widget _mechanicsView(String root, Map<String, String> faults) {
    if (_rawView) {
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
    }
    return DocumentForm(
      key: ValueKey(_revision),
      document: _document!,
      descriptor: _descriptor,
      onChanged: () => setState(() {}),
      onStructureChanged: () => setState(() {
        _document!.clearConversions();
        _revision++;
      }),
      referenceOptions: _references,
      vocabulary: vocabularyOf(_descriptor, _knownValuesFor(root)),
      faults: faults,
      anchors: _anchors,
    );
  }

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

  Widget _assetField(
    String root,
    String key,
    AssetSlot slot,
    String? errorText,
  ) {
    final document = _document!;
    final source = _importSources[key];
    final pending = source == null
        ? null
        : 'à importer : ${source.substring(source.lastIndexOf('/') + 1)}';

    if (slot.kind == AssetKind.sound) {
      final value = document.root[key];
      return AssetField(
        fieldKey: key,
        slot: slot,
        value: value is String ? value : null,
        soundIds: _soundIds,
        pendingLabel: pending,
        errorText: errorText,
        onSelectSound: (id) => setState(() {
          _importSources.remove(key);
          _importSoundIds.remove(key);
          document.setAt([key], id);
        }),
        onClear: () => setState(() {
          _importSources.remove(key);
          _importSoundIds.remove(key);
          document.removeAt([key]);
        }),
        onImport: () => _importAsset(key, slot),
      );
    }

    final id = _id.text.trim();
    final relative = _descriptor.imagePathOf(id, key);
    final present = slot.isRequired || document.root.containsKey(key);
    return AssetField(
      fieldKey: key,
      slot: slot,
      value: present ? relative : null,
      imageBytes: source != null
          ? _bytesOf(source)
          : (present && id.isNotEmpty && relative != null
              ? _bytesOf('$root/$relative')
              : null),
      pendingLabel: pending,
      errorText: errorText,
      onClear: () => setState(() {
        _importSources.remove(key);
        document.removeAt([key]);
      }),
      onImport: () => _importAsset(key, slot),
    );
  }

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

  /// Le panneau de reference (`ReferencePanel`) relit tout le repertoire de la
  /// categorie : hors de question de le faire a chaque frappe. La table est donc retenue tant que la categorie
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
}

/// Demande l'identifiant d'un son importe. Un `StatefulWidget` pour que son
/// controleur vive exactement autant que le dialogue — le liberer a la
/// fermeture le ferait servir, dispose, pendant l'animation de sortie.
class _SoundIdDialog extends StatefulWidget {
  const _SoundIdDialog({required this.initial});

  final String initial;

  @override
  State<_SoundIdDialog> createState() => _SoundIdDialogState();
}

class _SoundIdDialogState extends State<_SoundIdDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identifiant du son'),
      content: TextField(
        key: const Key('editeur-import-son-id'),
        controller: _controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Importer'),
        ),
      ],
    );
  }
}
