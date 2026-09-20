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
    this.withIcon = true,
  });

  final String id;
  final Map<String, String> bilingual;

  /// Faux quand l'emplacement de l'icone a ete retire (« aucune ») : la
  /// classe est alors ecrite sans `iconPath`, et sans icone deposee.
  final bool withIcon;

  /// Le corps saisi pour la classe. Ce qu'il ne porte pas, le gabarit le
  /// complete.
  final String mechanics;

  final List<SignatureCardInput> signatureCards;

  /// L'identifiant du passif de départ que la recette écrit.
  ///
  /// **Dérivé de l'identifiant de la classe**, comme le chemin de son icône :
  /// il ne se saisit pas. Une classe sans aucun passif disponible afficherait
  /// un choix vide à la sélection et ferait rougir
  /// `referential_integrity_test` (spec P-41, §9.2) ; la garantir revient à
  /// écrire ce passif dans la même transaction. L'auteur le renomme ensuite
  /// comme n'importe quelle entité, et sa prose `[À REMPLIR]` le lui
  /// rappellera.
  String get starterPassiveId => id;

  /// Les brouillons, **dans l'ordre d'écriture**.
  ///
  /// La classe d'abord : `_registerSignatureCard` lève `StateError` si une
  /// carte de classe est écrite avant le `class.json` qui doit la déclarer,
  /// et le passif de départ la **nomme**, donc elle doit exister avant lui.
  /// Son `skills` reste absent : l'écrivain l'alimente carte par carte, si
  /// bien que chaque état intermédiaire respecte la bijection exigée par
  /// `EntityValidator._signatureCards`.
  List<EntityDraft> toDrafts() {
    final classDescriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    final passiveDescriptor = kEntityDescriptors[EntityCategory.passive]!;
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
      fillPlaceholders(
        EntityDraft(
          descriptor: passiveDescriptor,
          id: starterPassiveId,
          // Aucune prose saisie : `fillPlaceholders` écrit `[À REMPLIR]`,
          // volontairement voyant. Inventer un nom ferait passer un squelette
          // pour un choix.
          bilingual: const {},
          mechanics: _starterPassiveMechanics,
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

  /// Le corps du passif de départ : le gabarit de la catégorie, plus la seule
  /// clé que la recette impose — `classes`.
  ///
  /// Sans elle, le passif serait ouvert à **toutes** les classes (spec P-49,
  /// §3.2) et viendrait polluer le pool des trois livrées. C'est la même
  /// doctrine que `iconPath` : ce que le geste impose, la recette l'écrit.
  String get _starterPassiveMechanics {
    final decoded = jsonDecode(
      kEntityDescriptors[EntityCategory.passive]!.template,
    ) as Map<String, dynamic>;
    decoded['classes'] = [id];
    return jsonEncode(decoded);
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
  ///
  /// Le passif de départ n'y figure pas : son identifiant est celui de la
  /// classe, que `EntityValidator._identity` juge déjà, et il ne peut donc ni
  /// être vide ni faire doublon avec une carte de signature — qui vit dans un
  /// autre répertoire.
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

  /// Le corps de la classe, augmente du chemin de son icone — ou prive de
  /// lui si [withIcon] est faux.
  ///
  /// Il est **derive de l'identifiant**, comme celui de la carte de classe :
  /// une icone ne se saisit pas, elle se depose. L'ecrire ici plutot que de
  /// laisser l'auteur ajouter la cle plus tard evite la dette qu'on ne voit
  /// qu'au moment ou elle coute.
  String get _mechanicsWithIcon {
    try {
      final decoded = jsonDecode(mechanics) as Map<String, dynamic>;
      if (withIcon) {
        decoded['iconPath'] = 'assets/data/classes/$id/icon.png';
      } else {
        decoded.remove('iconPath');
      }
      return jsonEncode(decoded);
    } catch (_) {
      // Corps illisible : `EntityValidator` dira pourquoi, et son message vaut
      // mieux qu'un ecrasement silencieux.
      return mechanics;
    }
  }
}
