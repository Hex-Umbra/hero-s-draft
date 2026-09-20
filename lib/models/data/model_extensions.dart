import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_colors.dart';
import 'card_data.dart';
import 'relic_data.dart';
import 'stat_rule.dart';
import '../enemy_intent.dart';
import '../might_target.dart';

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

extension MightTargetsLabels on Set<MightTarget> {
  /// Ce que renforce la Puissance, en abrégé et dans l'ordre de [MightTarget],
  /// quel que soit l'ordre du `Set` : « Compétences · Altérations » (spec P-41,
  /// §7.4).
  String shortLabel(AppLocalizations l10n) => [
        for (final target in MightTarget.values)
          if (contains(target))
            switch (target) {
              MightTarget.attack => l10n.mightTargetAttackShort,
              MightTarget.skill => l10n.mightTargetSkillShort,
              MightTarget.alteration => l10n.mightTargetAlterationShort,
            },
      ].join(' · ');

  /// Ce que renforce la Puissance, en toutes lettres et dans l'ordre de
  /// [MightTarget] : « les dégâts de vos Compétences et vos altérations »
  /// (spec P-41, §7.4). Deux cibles jointes par « et », trois par une virgule
  /// puis « et ».
  String longLabel(AppLocalizations l10n) {
    final parts = [
      for (final target in MightTarget.values)
        if (contains(target))
          switch (target) {
            MightTarget.attack => l10n.mightTargetAttackLong,
            MightTarget.skill => l10n.mightTargetSkillLong,
            MightTarget.alteration => l10n.mightTargetAlterationLong,
          },
    ];
    if (parts.length < 2) return parts.join();
    final debut = parts.sublist(0, parts.length - 1).join(', ');
    return '$debut ${l10n.listJoinAnd} ${parts.last}';
  }

  /// La phrase que lit le joueur à la sélection de classe (spec P-41, §8.3).
  /// Générée depuis l'orientation, jamais écrite classe par classe : c'est la
  /// règle d'ADR-090.
  String sentence(AppLocalizations l10n) =>
      l10n.mightTargetsSentence(longLabel(l10n));
}

extension StatRuleLabel on StatRule {
  /// La règle en clair : « Son Armure devient de la Puissance pour un tour. »
  ///
  /// Générée à partir de la règle, jamais écrite classe par classe
  /// (spec P-41, §8.3). Le `switch` est **exhaustif** sur le triplet
  /// (ressource, mode, cible) : ajouter une valeur à l'une des trois
  /// énumérations sans son libellé ne compile plus.
  String describe(AppLocalizations l10n) => switch ((stat, mode, to)) {
        (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertArmorToMight(duration),
        (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleConvertManaToMight(duration),
      };

  /// Le titre court du panneau de démonstration du tutoriel : ce que la
  /// ressource devient, en majuscules comme les titres voisins.
  ///
  /// Même `switch` **exhaustif** sur le triplet (ressource, mode, cible) que
  /// [describe] : ajouter une valeur à l'une des trois énumérations sans son
  /// libellé ne compile plus.
  String shortTitle(AppLocalizations l10n) => switch ((stat, mode, to)) {
        (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleArmorToMightTitle,
        (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleManaToMightTitle,
      };
}
