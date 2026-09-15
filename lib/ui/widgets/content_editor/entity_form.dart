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
          const TextSpan(
            text: '/',
            style: TextStyle(color: EditorColors.crumbSeparator),
          ),
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
