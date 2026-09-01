/// Implemente par les modeles de donnees qui peuvent porter un son propre.
///
/// [sfx] est le niveau 1 de la chaine de repli, [animation] le niveau 2.
/// Les deux sont optionnels : une entite qui n'implemente rien de particulier
/// laisse le moment se resoudre sur son defaut.
abstract class AudioSource {
  String? get sfx;
  String? get animation;
}

/// Source sans entite : porte une cle de variante et rien d'autre.
///
/// [AudioSource.animation] n'est pas une animation au sens strict, c'est la
/// **cle de variante** que `moments.byAnimation` consulte au niveau 2 de la
/// chaine de repli. Les cartes y mettent leur type d'animation ; un rouleau
/// de draft y met la rarete revelee. Le mecanisme est le meme, seule la
/// valeur change — d'ou cette classe, qui evite d'inventer un modele de
/// donnees juste pour transporter une chaine.
class VariantAudioSource implements AudioSource {
  const VariantAudioSource(this.animation);

  @override
  final String? animation;

  /// Toujours nul : une source sans entite n'a pas de son propre a declarer,
  /// sinon elle court-circuiterait la variante qu'elle vient justement poser.
  @override
  String? get sfx => null;
}
