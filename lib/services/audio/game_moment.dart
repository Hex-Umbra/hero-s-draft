/// Les 14 moments de jeu que le code peut declarer.
///
/// Un appelant declare un moment, jamais un fichier : c'est ce qui permet
/// de garder toute la resolution — et donc la gestion de l'asset absent —
/// dans `AudioDirector`.
///
/// L'audit du 25/07 listait 15 identifiants, dont trois variantes de
/// `card_play`. Ces trois-la ne sont pas des moments distincts : ce sont
/// trois resolutions du moment `cardPlay`, decidees par la donnee.
enum GameMoment {
  cardHover('card_hover'),
  cardPickup('card_pickup'),
  cardPlay('card_play'),
  impact('impact'),
  impactCrit('impact_crit'),
  armorHit('armor_hit'),
  heal('heal'),
  enemyAttack('enemy_attack'),
  enemyDeath('enemy_death'),
  cardDraw('card_draw'),
  manaGain('mana_gain'),
  insufficientMana('insufficient_mana'),
  turnStart('turn_start'),
  turnEnd('turn_end');

  const GameMoment(this.jsonKey);

  /// Cle correspondante dans la section `moments` de `assets/data/audio.json`.
  final String jsonKey;
}
