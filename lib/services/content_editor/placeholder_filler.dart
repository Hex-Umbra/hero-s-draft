import 'dart:convert';

import 'entity_draft.dart';

/// Ce qu'on ecrit dans un champ de prose laisse vide. Volontairement voyant :
/// un nom oublie doit se lire comme tel dans le jeu, pas passer pour un choix.
const String kProsePlaceholderPrefix = '[À REMPLIR]';

/// Complete un brouillon incomplet.
///
/// **A appeler avant la validation**, jamais apres : la famille bilingue
/// refuse la prose vide, c'est-a-dire exactement ce qu'on est charge de
/// completer. Place ensuite, ce remplissage ne servirait a rien.
///
/// Ce qui est saisi n'est jamais ecrase — le formulaire prime toujours sur le
/// gabarit.
EntityDraft fillPlaceholders(EntityDraft draft) {
  final bilingual = <String, String>{...draft.bilingual};
  for (final base in draft.descriptor.bilingualBases) {
    for (final suffix in const ['fr', 'en']) {
      final key = '${base}_$suffix';
      if ((bilingual[key] ?? '').trim().isEmpty) {
        bilingual[key] = '$kProsePlaceholderPrefix ${draft.id}';
      }
    }
  }

  // En modification, le fichier fait foi : le gabarit ne le complete jamais.
  // Ses valeurs ne sont pas les defauts du modele (`xp` 35 d'un ennemi contre
  // 20, `animation` "melee" contre null, `displayOrder` 99 contre 0) : les
  // verser dans un fichier ecrit a la main changerait le jeu en silence, et
  // Modifier puis Ecrire sans rien toucher doit reecrire le fichier a
  // l'identique. Seule la prose vide recoit encore son placeholder.
  if (draft.isModification) {
    return EntityDraft(
      descriptor: draft.descriptor,
      id: draft.id,
      bilingual: bilingual,
      mechanics: draft.mechanics,
      heroClass: draft.heroClass,
      isModification: true,
    );
  }

  var mechanics = draft.mechanics;
  try {
    final decoded = jsonDecode(mechanics) as Map<String, dynamic>;
    draft.descriptor.decodeTemplate().forEach((key, fallback) {
      final value = decoded[key];
      if (value == null || (value is String && value.trim().isEmpty)) {
        decoded[key] = fallback;
      }
    });
    mechanics = const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    // Corps illisible : on le laisse tel quel pour que le validateur dise
    // pourquoi. Ecraser par le gabarit effacerait la saisie et la raison.
  }

  return EntityDraft(
    descriptor: draft.descriptor,
    id: draft.id,
    bilingual: bilingual,
    mechanics: mechanics,
    heroClass: draft.heroClass,
    isModification: draft.isModification,
  );
}
