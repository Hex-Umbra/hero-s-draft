import 'dart:convert';

import 'package:meta/meta.dart';

import 'entity_descriptor.dart';
import 'entity_draft.dart';
import 'entity_validator.dart';
import 'placeholder_filler.dart';

/// Une carte de signature telle qu'on la saisit : un identifiant, et la prose
/// qu'on veut bien donner tout de suite.
@immutable
class SignatureCardInput {
  const SignatureCardInput({required this.id, this.bilingual = const {}});

  final String id;
  final Map<String, String> bilingual;
}

/// Une classe complete, en un geste.
///
/// Ce que la recette apporte n'est pas le lien `skills` — `EntityWriter` le
/// tient deja — mais **l'atomicite et l'ordre** : les identifiants des cartes
/// sont decides d'avance, la classe est ecrite avant elles, et l'ensemble
/// partage une transaction.
@immutable
class ClassRecipe {
  const ClassRecipe({
    required this.id,
    required this.bilingual,
    required this.mechanics,
    required this.signatureCards,
  });

  final String id;
  final Map<String, String> bilingual;

  /// Le corps saisi pour la classe. Ce qu'il ne porte pas, le gabarit le
  /// complete.
  final String mechanics;

  final List<SignatureCardInput> signatureCards;

  /// Les brouillons, **dans l'ordre d'ecriture**.
  ///
  /// La classe d'abord : `_registerSignatureCard` leve `StateError` si une
  /// carte de classe est ecrite avant le `class.json` qui doit la declarer.
  /// Et son `skills` reste absent : l'ecrivain l'alimente carte par carte, si
  /// bien que chaque etat intermediaire respecte la bijection exigee par
  /// `EntityValidator._signatureCards`.
  List<EntityDraft> toDrafts() {
    final classDescriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    final cardDescriptor = kEntityDescriptors[EntityCategory.card]!;

    return [
      fillPlaceholders(
        EntityDraft(
          descriptor: classDescriptor,
          id: id,
          bilingual: bilingual,
          mechanics: _mechanicsWithIcon,
        ),
      ),
      for (final card in signatureCards)
        fillPlaceholders(
          EntityDraft(
            descriptor: cardDescriptor,
            id: card.id,
            bilingual: card.bilingual,
            mechanics: '{}',
            heroClass: id,
          ),
        ),
    ];
  }

  /// Les fautes que seul l'ensemble de la recette peut voir.
  ///
  /// `EntityValidator` juge un brouillon a la fois : deux cartes de signature
  /// portant le meme identifiant lui paraissent chacune valide, puisque ni
  /// l'une ni l'autre n'est encore sur le disque au moment ou elles sont
  /// jugees. C'est a l'ecriture qu'elles se telescopent : `writeAll` les
  /// ecrit au meme chemin l'une apres l'autre, et la seconde ecrase la
  /// premiere sans faute affichee, sans message. A appeler **avant** la
  /// validation par brouillon, dans `_write`.
  List<ValidationFault> faults() {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final card in signatureCards) {
      // Un identifiant pas encore saisi n'est pas un doublon d'un autre
      // identifiant pas encore saisi. Sans cette garde, demander trois cartes
      // et n'en nommer qu'une ferait crier le formulaire pendant la frappe —
      // par-dessus la faute « un identifiant est requis », qui elle est juste
      // et que `EntityValidator._identity` produit deja pour chaque brouillon.
      if (card.id.isEmpty) continue;
      if (!seen.add(card.id)) duplicates.add(card.id);
    }
    return [
      for (final id in duplicates)
        ValidationFault(
          'deux cartes de signature portent l\'identifiant "$id"',
          field: 'skills',
        ),
    ];
  }

  /// Le corps de la classe, augmente du chemin de son icone.
  ///
  /// Il est **derive de l'identifiant**, comme celui de la carte de classe :
  /// une icone ne se saisit pas, elle se depose. L'ecrire ici plutot que de
  /// laisser l'auteur ajouter la cle plus tard evite la dette qu'on ne voit
  /// qu'au moment ou elle coute.
  String get _mechanicsWithIcon {
    try {
      final decoded = jsonDecode(mechanics) as Map<String, dynamic>;
      decoded['iconPath'] = 'assets/data/classes/$id/icon.png';
      return jsonEncode(decoded);
    } catch (_) {
      // Corps illisible : `EntityValidator` dira pourquoi, et son message vaut
      // mieux qu'un ecrasement silencieux.
      return mechanics;
    }
  }
}
