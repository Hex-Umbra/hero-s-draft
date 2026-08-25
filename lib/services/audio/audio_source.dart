/// Implemente par les modeles de donnees qui peuvent porter un son propre.
///
/// [sfx] est le niveau 1 de la chaine de repli, [animation] le niveau 2.
/// Les deux sont optionnels : une entite qui n'implemente rien de particulier
/// laisse le moment se resoudre sur son defaut.
abstract class AudioSource {
  String? get sfx;
  String? get animation;
}
