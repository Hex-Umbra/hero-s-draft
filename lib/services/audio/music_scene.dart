/// Les quatre ambiances musicales du jeu. Une scene, une piste.
enum MusicScene {
  /// Accueil, Deck, Reglages (heritee), Notes de version, Dictionnaire,
  /// Selection de classe.
  menu('menu'),

  /// Carte du monde, Boutique, Evenement, Repos, Selection de carte au
  /// repos, Forge, Echange de reliques, Draft de recompense, Draft de deck
  /// initial, Draft de carte de boss.
  map('map'),

  /// Combat standard et elite.
  combat('combat'),

  /// Combat de boss.
  boss('boss');

  const MusicScene(this.jsonKey);

  final String jsonKey;
}
