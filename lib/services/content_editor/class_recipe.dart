import 'dart:convert';

import 'package:meta/meta.dart';

import 'entity_descriptor.dart';
import 'entity_draft.dart';
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
