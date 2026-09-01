/// Les 22 moments de jeu que le code peut declarer.
///
/// Un appelant declare un moment, jamais un fichier : c'est ce qui permet
/// de garder toute la resolution — et donc la gestion de l'asset absent —
/// dans `AudioDirector`.
///
/// L'audit du 25/07 listait 15 identifiants, dont trois variantes de
/// `card_play`. Ces trois-la ne sont pas des moments distincts : ce sont
/// trois resolutions du moment `cardPlay`, decidees par la donnee.
///
/// Meme principe pour les rouleaux : `reelLand` est UN moment dont la
/// donnee choisit le son selon la rarete revelee, via `byAnimation`. Deux
/// raretes peuvent pointer le meme son tant qu'un bruitage distinct n'est
/// pas source, sans toucher une ligne de code.
enum GameMoment {
  cardHover('card_hover'),
  cardPickup('card_pickup'),
  cardPlay('card_play'),
  impact('impact'),
  impactCrit('impact_crit'),
  armorHit('armor_hit'),

  /// Gain d'armure. Distinct d'[armorHit], qui est le coup *encaisse* par
  /// l'armure : les deux evenements sont opposes et partageaient le meme
  /// son avant le 2026-08-29.
  armorGain('armor_gain'),
  heal('heal'),
  enemyAttack('enemy_attack'),
  enemyDeath('enemy_death'),
  cardDraw('card_draw'),
  manaGain('mana_gain'),
  insufficientMana('insufficient_mana'),
  turnStart('turn_start'),
  turnEnd('turn_end'),

  /// Validation d'un bouton d'interface. Emis par `GameButton`, donc par
  /// tout menu sans cablage ecran par ecran.
  uiTap('ui_tap'),

  /// Choix d'un noeud sur la carte du monde.
  mapNodeSelect('map_node_select'),

  /// Selection d'une carte dans un draft (deck de depart, repos, boss).
  draftCardPick('draft_card_pick'),

  /// Une relique defile dans le carrousel. Emis une fois par relique : la
  /// courbe `easeOutCubic` du carrousel espace les emissions d'elle-meme,
  /// d'ou le ralentissement facon machine a sous, sans code de cadence.
  carouselTick('carousel_tick'),

  /// Le carrousel s'immobilise sur la relique gagnee.
  carouselLand('carousel_land'),

  /// Une carte defile dans un rouleau de draft de niveau.
  reelTick('reel_tick'),

  /// Le rouleau revele sa carte. Resolu par rarete via `byAnimation`.
  reelLand('reel_land');

  const GameMoment(this.jsonKey);

  /// Cle correspondante dans la section `moments` de `assets/data/audio.json`.
  final String jsonKey;
}
