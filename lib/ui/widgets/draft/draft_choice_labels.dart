import '../../../game/services/level_up_reward_service.dart';
import '../../../l10n/app_localizations.dart';

/// Dérive les libellés localisés d'un [DraftChoice] (titre, description et
/// rareté) tel que généré par [LevelUpRewardService.generateChoices].
///
/// Extrait de `DraftScreen` (`_getChoiceTitle` / `_getChoiceDescription` /
/// `_rarityToString`) pour être partagé, à l'identique, avec
/// `TutorialDraftWidget` : les deux doivent afficher exactement les mêmes
/// libellés pour un même [DraftChoice], sans dupliquer la correspondance
/// type -> texte localisé. Ne dépend que d'[AppLocalizations] et des
/// modèles de `level_up_reward_service.dart` — jamais de `BuildContext` ni
/// de Riverpod, pour rester consommable depuis `lib/tutorial/`.
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
  static String getChoiceTitle(AppLocalizations l10n, DraftChoice choice) {
    switch (choice.type) {
      case LevelUpRewardType.vitality:
        return l10n.draftChoiceVitality;
      case LevelUpRewardType.sharpening:
        return l10n.draftChoiceSharpening;
      case LevelUpRewardType.steelForge:
        return l10n.draftChoiceSteelForge;
      case LevelUpRewardType.wisdom:
        return l10n.draftChoiceWisdom;
      case LevelUpRewardType.luckyClover:
        return l10n.draftChoiceClover;
      case LevelUpRewardType.mirror:
        return l10n.draftChoiceMirror;
      case LevelUpRewardType.precision:
        return l10n.draftChoicePrecision;
      case LevelUpRewardType.ferocity:
        return l10n.draftChoiceFerocity;
    }
  }

  /// Description (avec la valeur du gain) affichée pour ce choix de draft.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice,
  ) {
    switch (choice.type) {
      case LevelUpRewardType.vitality:
        return l10n.draftChoiceVitalityDesc(choice.pvBoost);
      case LevelUpRewardType.sharpening:
        return l10n.draftChoiceSharpeningDesc(choice.atkBoost);
      case LevelUpRewardType.steelForge:
        return l10n.draftChoiceSteelForgeDesc(choice.armorBoost);
      case LevelUpRewardType.wisdom:
        return l10n.draftChoiceWisdomDesc(choice.manaBoost);
      case LevelUpRewardType.luckyClover:
        return l10n.draftChoiceCloverDesc(choice.luckBoost);
      case LevelUpRewardType.mirror:
        return l10n.draftChoiceMirrorDesc;
      case LevelUpRewardType.precision:
        return l10n.draftChoicePrecisionDesc(choice.critChanceBoost);
      case LevelUpRewardType.ferocity:
        return l10n.draftChoiceFerocityDesc(
          (choice.critDamageBoost * 100).round(),
        );
    }
  }
}
