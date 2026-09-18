import '../../../game/services/level_up_reward_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/data/passive_data.dart';
import '../../../models/reward_rarity.dart';

/// Dérive les libellés localisés d'un [DraftChoice] (titre, description et
/// rareté) tel que généré par [LevelUpRewardService.generateChoices].
///
/// Extrait de `DraftScreen` (`_getChoiceTitle` / `_getChoiceDescription` /
/// `_rarityToString`) pour être partagé, à l'identique, avec
/// `TutorialDraftWidget` : les deux doivent afficher exactement les mêmes
/// libellés pour un même [DraftChoice], sans dupliquer la correspondance
/// type -> texte localisé. Ne dépend que d'[AppLocalizations] et des
/// modèles — jamais de `BuildContext` ni de Riverpod, pour rester
/// consommable depuis `lib/tutorial/`.
class DraftChoiceLabels {
  const DraftChoiceLabels._();

  /// Libellé de rareté affiché sur la carte de draft.
  static String rarityToString(AppLocalizations l10n, RewardRarity rarity) {
    switch (rarity) {
      case RewardRarity.mythic:
        return l10n.localeName == 'fr' ? 'MYTHIQUE' : 'MYTHIC';
      case RewardRarity.legendary:
        return l10n.rarityLegendary;
      case RewardRarity.epic:
        return l10n.rarityEpic;
      case RewardRarity.rare:
        return l10n.rarityRare;
      case RewardRarity.uncommon:
        return l10n.rarityUncommon;
      case RewardRarity.common:
        return l10n.rarityCommon;
    }
  }

  /// Titre affiché pour ce choix de draft.
  static String getChoiceTitle(AppLocalizations l10n, DraftChoice choice) =>
      choice.data.getName(l10n.localeName);

  /// Description (avec la valeur du gain) affichée pour ce choix de draft.
  ///
  /// [passive] est le passif actif : une récompense dont le gabarit nomme
  /// `{passive}` ou `{effect}` se décrit par ce que la Maîtrise tirée lui
  /// apporte — c'est le cas d'*Affinité* (spec P-49, §6.5). Les autres
  /// l'ignorent, sans qu'aucune branche ne les distingue.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice, {
    PassiveData? passive,
  }) =>
      choice.data.describe(
        l10n.localeName,
        amount: choice.amount,
        passive: passive,
      );
}
