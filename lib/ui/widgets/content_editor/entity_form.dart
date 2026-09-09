import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import 'color_field.dart';

/// Le formulaire d'une entite : identite, proprietaire (carte), prose
/// bilingue, mecanique, puis les actions et leur issue.
///
/// **Purement presentationnel** : tout l'etat vit dans l'ecran appelant, sous
/// forme de `TextEditingController`s et de callbacks. Rien ici n'est
/// reconstruit a la volee — c'est ce qui permet a l'ecran de continuer a
/// afficher le compte rendu d'ecriture apres que ce widget ait disparu (retour
/// a la branche 0).
///
/// **Deux visages, selon [isModification]** :
/// - en creation, un champ par cle du gabarit (plus les cas particuliers —
///   `themeColor`, les `referenceKeys`, la recette de classe) ;
/// - en modification, la boite JSON unique deja livree : elle seule peut
///   porter des cles que le gabarit ignore (`sfx` d'une relique retouchee a la
///   main, par exemple), et la relecture (« Charger ») la repeuple entierement.
///   La scinder en champs par cle y ferait perdre silencieusement ces cles.
class EntityForm extends StatelessWidget {
  const EntityForm({
    super.key,
    required this.descriptor,
    required this.isModification,
    required this.idController,
    required this.onIdentityChanged,
    required this.pathPreview,
    required this.proseControllers,
    required this.onValidate,
    required this.onWrite,
    required this.outcome,
    this.onLoad,
    this.ownerClassIds = const [],
    this.selectedOwner,
    this.onOwnerSelected,
    this.ownerColorOf,
    this.mechanicsController,
    this.templateFieldControllers = const {},
    this.themeColor,
    this.onThemeColorChanged,
    this.referenceOptions = const {},
    this.referenceSelections = const {},
    this.onReferenceSelected,
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

  final Map<String, TextEditingController> proseControllers;

  /// Relit la cible depuis le disque, en modification seulement.
  final VoidCallback? onLoad;

  /// Rangee de pastilles de proprietaire, pour une carte en creation
  /// seulement : `Key('editeur-proprietaire-<classe>')` et
  /// `Key('editeur-proprietaire-neutre')`.
  final List<String> ownerClassIds;
  final String? selectedOwner;
  final ValueChanged<String?>? onOwnerSelected;
  final Color? Function(String classId)? ownerColorOf;

  /// La boite JSON unique, en modification seulement.
  final TextEditingController? mechanicsController;

  /// Un controleur par cle du gabarit (hors `themeColor`), en creation
  /// seulement.
  final Map<String, TextEditingController> templateFieldControllers;

  /// `themeColor`, porte par un [ColorField] plutot qu'un champ texte.
  final Color? themeColor;
  final ValueChanged<Color>? onThemeColorChanged;

  /// Une liste par `referenceKeys` du descripteur — `passiveTrait` pour une
  /// classe — tiree de `entityIdsByOwner`, jamais de `knownValues` : ce
  /// dernier ne liste que les valeurs deja employees.
  final Map<String, List<String>> referenceOptions;
  final Map<String, String?> referenceSelections;
  final void Function(String key, String? value)? onReferenceSelected;

  /// La recette de classe, pour une classe en creation seulement.
  final bool showSignatureCards;
  final TextEditingController? cardCountController;
  final int cardCount;
  final ValueChanged<int>? onCardCountChanged;
  final List<TextEditingController> cardIds;
  final List<TextEditingController> cardNameFr;
  final List<TextEditingController> cardNameEn;

  final VoidCallback onValidate;
  final VoidCallback onWrite;
  final Widget outcome;

  @override
  Widget build(BuildContext context) {
    final showOwnerPills = !isModification && descriptor.supportsHeroClass;

    return Column(
      children: [
        Expanded(
          // Voir la note de tete de fichier des l'ecran : un `ListView` ne
          // construit pas ses enfants hors ecran, et ce formulaire est plus
          // long qu'un panneau.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _identity(),
                if (showOwnerPills) ...[
                  const SizedBox(height: 12),
                  _ownerPills(),
                ],
                const Divider(),
                for (final entry in proseControllers.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextField(
                      controller: entry.value,
                      decoration: InputDecoration(labelText: entry.key),
                    ),
                  ),
                const Divider(),
                if (isModification) _mechanicsBox() else ..._mechanicsFields(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (onLoad != null) ...[
              TextButton(onPressed: onLoad, child: const Text('Charger')),
              const SizedBox(width: 12),
            ],
            TextButton(onPressed: onValidate, child: const Text('Valider')),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: onWrite, child: const Text('Écrire')),
          ],
        ),
        outcome,
      ],
    );
  }

  /// L'identifiant et le chemin qu'il calcule.
  Widget _identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('editeur-id'),
          controller: idController,
          // Saisissable en modification aussi : c'est le seul moyen de
          // **designer** l'entite a charger.
          onChanged: (_) => onIdentityChanged(),
          decoration: const InputDecoration(labelText: 'Identifiant'),
        ),
        const SizedBox(height: 8),
        Text(
          idController.text.trim().isEmpty ? '(identifiant requis)' : pathPreview,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ],
    );
  }

  /// (b) Le proprietaire d'une carte est un champ du formulaire, pas un
  /// niveau de l'arbre : la neutralite et chaque classe sont des pastilles,
  /// coloree par le `themeColor` de la classe.
  Widget _ownerPills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ownerPill(
          key: const Key('editeur-proprietaire-neutre'),
          label: 'Neutre',
          value: null,
          background: Colors.grey.shade300,
        ),
        for (final classId in ownerClassIds)
          _ownerPill(
            key: Key('editeur-proprietaire-$classId'),
            label: classId,
            value: classId,
            background: ownerColorOf?.call(classId) ?? Colors.grey.shade300,
          ),
      ],
    );
  }

  Widget _ownerPill({
    required Key key,
    required String label,
    required String? value,
    required Color background,
  }) {
    final isSelected = selectedOwner == value;
    return InkWell(
      key: key,
      onTap: () => onOwnerSelected?.call(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(label),
      ),
    );
  }

  /// En modification : la boite JSON unique, deja livree et conservee telle
  /// quelle — c'est elle qui porte les cles que le gabarit ignore.
  Widget _mechanicsBox() {
    return TextField(
      controller: mechanicsController,
      maxLines: 14,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: const InputDecoration(
        labelText: 'Mécanique (JSON)',
        alignLabelWithHint: true,
      ),
    );
  }

  /// En creation : un champ par cle du gabarit, plus les cas particuliers.
  List<Widget> _mechanicsFields() {
    return [
      for (final entry in templateFieldControllers.entries)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: entry.value,
            decoration: InputDecoration(labelText: entry.key),
          ),
        ),
      if (themeColor != null) _themeColorRow(),
      for (final entry in referenceOptions.entries)
        _referenceField(entry.key, entry.value),
      if (showSignatureCards) _signatureCards(),
    ];
  }

  Widget _themeColorRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text('themeColor'),
          const SizedBox(width: 12),
          ColorField(
            value: themeColor!,
            onChanged: (color) => onThemeColorChanged?.call(color),
          ),
        ],
      ),
    );
  }

  /// Le catalogue des identifiants d'une categorie referencee — le passif
  /// pour `passiveTrait` — jamais le seul vocabulaire deja employe.
  Widget _referenceField(String key, List<String> options) {
    final selected = referenceSelections[key];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in options)
                ChoiceChip(
                  label: Text(id),
                  selected: selected == id,
                  onSelected: (_) => onReferenceSelected?.call(key, id),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// La classe en creation entraine ses cartes de signature : combien, puis
  /// pour chacune son identifiant et son nom bilingue.
  Widget _signatureCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Cartes de signature',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        TextField(
          key: const Key('editeur-nombre-cartes'),
          controller: cardCountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Nombre de cartes'),
          onChanged: (text) =>
              onCardCountChanged?.call(int.tryParse(text.trim()) ?? 0),
        ),
        for (var i = 0; i < cardCount; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carte ${i + 1}'),
                TextField(
                  key: Key('editeur-carte-$i-id'),
                  controller: cardIds[i],
                  decoration: const InputDecoration(labelText: 'Identifiant'),
                ),
                TextField(
                  key: Key('editeur-carte-$i-nom-fr'),
                  controller: cardNameFr[i],
                  decoration: const InputDecoration(labelText: 'Nom (fr)'),
                ),
                TextField(
                  key: Key('editeur-carte-$i-nom-en'),
                  controller: cardNameEn[i],
                  decoration: const InputDecoration(labelText: 'Nom (en)'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
