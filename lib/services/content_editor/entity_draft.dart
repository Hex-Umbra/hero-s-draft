import 'dart:convert';

import 'package:meta/meta.dart';

import 'entity_descriptor.dart';

/// Ce que l'ecran compose et que le validateur juge.
///
/// Le triangle d'identite ([id], [heroClass]) et la prose ([bilingual]) sont
/// saisis dans des champs ; la mecanique reste du **texte** JSON, que le
/// validateur decode lui-meme afin de pouvoir dire pourquoi il ne decode pas.
@immutable
class EntityDraft {
  const EntityDraft({
    required this.descriptor,
    required this.id,
    required this.bilingual,
    required this.mechanics,
    this.heroClass,
    this.isModification = false,
  });

  final EntityDescriptor descriptor;
  final String id;

  /// La classe proprietaire, pour une carte de classe. `null` pour une carte
  /// neutre et pour toutes les autres categories.
  final String? heroClass;

  /// Les champs bilingues, sous leur cle complete : `name_fr`, `title_en`…
  final Map<String, String> bilingual;

  /// Le corps JSON tel que saisi.
  final String mechanics;

  /// En modification, le triangle d'identite est gele : il decide **ou** est
  /// le fichier, et le deplacer serait un renommage — hors perimetre (E1).
  final bool isModification;

  String get path => descriptor.pathOf(id, heroClass: heroClass);

  /// Le document final, dans l'ordre des fichiers existants : identifiant,
  /// prose, mecanique.
  ///
  /// **Leve si [mechanics] ne decode pas** : a n'appeler qu'apres la famille 2
  /// de la validation, ce que garantit `EntityValidator`.
  Map<String, dynamic> compose() {
    final decoded = jsonDecode(mechanics) as Map<String, dynamic>;

    // Le corps est etale **apres** la prose : un doublon y gagnerait la place
    // du champ que la validation vient de juger, et un `name_fr` vide colle
    // dans la vue JSON brute ferait ecrire une entite sans nom. On le retire
    // donc du corps plutot que de deplacer le bloc bilingue apres l'etalement —
    // ce qui changerait l'ordre des cles du document, et l'ordre est ce qui
    // rend le diff d'une modification lisible.
    final fromForm = {
      'id',
      for (final base in descriptor.bilingualBases) ...[
        '${base}_en',
        '${base}_fr',
      ],
    };
    decoded.removeWhere((key, _) => fromForm.contains(key));

    return {
      'id': id,
      for (final base in descriptor.bilingualBases) ...{
        '${base}_en': bilingual['${base}_en'] ?? '',
        '${base}_fr': bilingual['${base}_fr'] ?? '',
      },
      ...decoded,
      // Le chemin d'une image est **derive de l'identifiant**, donc calcule et
      // jamais saisi. Obligatoire, il est toujours ecrit ; optionnel
      // (`iconPath`), il ne l'est que si le corps le porte. Place apres la
      // mecanique pour que l'outil ait le dernier mot.
      for (final key in descriptor.imageKeys)
        if (descriptor.isComputedImage(key) || decoded.containsKey(key))
          key: descriptor.imagePathOf(id, key),
    };
  }
}
