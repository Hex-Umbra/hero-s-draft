/// Le palier de rareté d'une récompense de niveau.
///
/// Rangé ici, et non dans le service qui le tire, parce que la donnée le lit :
/// `LevelUpRewardData` porte une table de valeurs indexée par ce palier, et
/// `lib/models/data/` ne peut pas importer `lib/game/services/` sans inverser
/// les couches. Précédent : `lib/models/might_target.dart`.
///
/// **L'ordre des valeurs est croissant et il est lu comme tel** : les tests de
/// valeurs vérifient qu'une récompense progresse de [common] à [legendary].
/// [mythic] n'est rendu que par un tirage de niveau (`isLevelReward: true`).
enum RewardRarity { common, uncommon, rare, epic, legendary, mythic }
