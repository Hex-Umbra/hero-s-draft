import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'card_data.dart';
import 'relic_data.dart';
import '../enemy_intent.dart';

extension CardRarityExtension on CardRarity {
  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case CardRarity.common:
        return l10n.rarityCommon;
      case CardRarity.uncommon:
        return l10n.rarityUncommon;
      case CardRarity.rare:
        return l10n.rarityRare;
      case CardRarity.epic:
        return l10n.rarityEpic;
      case CardRarity.legendary:
        return l10n.rarityLegendary;
      case CardRarity.unique:
        return 'Unique';
    }
  }

  Color get color {
    switch (this) {
      case CardRarity.common:
        return AppColors.rarityCommon;
      case CardRarity.uncommon:
        return AppColors.rarityUncommon;
      case CardRarity.rare:
        return AppColors.rarityRare;
      case CardRarity.epic:
        return AppColors.rarityEpic;
      case CardRarity.legendary:
        return AppColors.rarityLegendary;
      case CardRarity.unique:
        return AppColors.rarityUnique;
    }
  }
}

extension CardTargetExtension on CardTarget {
  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case CardTarget.singleEnemy:
        return l10n.targetSingleEnemy;
      case CardTarget.allEnemies:
        return l10n.targetAllEnemies;
      case CardTarget.self:
        return l10n.targetSelf;
      case CardTarget.none:
        return l10n.targetNone;
    }
  }
}

extension RelicRarityExtension on RelicRarity {
  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case RelicRarity.common:
        return l10n.rarityCommon;
      case RelicRarity.uncommon:
        return l10n.rarityUncommon;
      case RelicRarity.rare:
        return l10n.rarityRare;
      case RelicRarity.epic:
        return l10n.rarityEpic;
      case RelicRarity.legendary:
        return l10n.rarityLegendary;
    }
  }

  Color get color {
    switch (this) {
      case RelicRarity.common:
        return AppColors.rarityCommon;
      case RelicRarity.uncommon:
        return AppColors.rarityUncommon;
      case RelicRarity.rare:
        return AppColors.rarityRare;
      case RelicRarity.epic:
        return AppColors.rarityEpic;
      case RelicRarity.legendary:
        return AppColors.rarityLegendary;
    }
  }
}

extension IntentTypeExtension on IntentType {
  String getLabel(AppLocalizations l10n, int value) {
    switch (this) {
      case IntentType.attack:
        if (value >= 20) {
          return l10n.intentDevastatingAttack(value);
        } else if (value >= 12) {
          return l10n.intentHeavyAttack(value);
        } else if (value >= 6) {
          return l10n.intentAttack(value);
        } else {
          return l10n.intentQuickAttack(value);
        }
      case IntentType.defend:
        return l10n.intentDefend(value);
      case IntentType.buff:
        return l10n.intentBuff(value);
    }
  }
}
