/// Les quatre ambiances musicales du jeu. Une scene, une piste.
enum MusicScene {
  /// Accueil, Reglages, Notes de version, Dictionnaire, Selection de classe.
  menu('menu'),

  /// Carte du monde, Boutique, Evenement, Repos, Forge, Echange de reliques.
  map('map'),

  /// Combat standard et elite.
  combat('combat'),

  /// Combat de boss.
  boss('boss');

  const MusicScene(this.jsonKey);

  final String jsonKey;
}
