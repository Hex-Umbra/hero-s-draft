import 'package:flutter/material.dart';
import 'app_colors.dart';

class GameThemeExtension extends ThemeExtension<GameThemeExtension> {
  final Color rarityCommon;
  final Color rarityUncommon;
  final Color rarityRare;
  final Color rarityEpic;
  final Color rarityLegendary;
  final Color rarityUnique;

  final Color statHp;
  final Color statMana;
  final Color statGold;
  final Color statArmor;

  final Color neonGlow;
  final Color neonPurple;
  final Color neonPink;

  const GameThemeExtension({
    required this.rarityCommon,
    required this.rarityUncommon,
    required this.rarityRare,
    required this.rarityEpic,
    required this.rarityLegendary,
    required this.rarityUnique,
    required this.statHp,
    required this.statMana,
    required this.statGold,
    required this.statArmor,
    required this.neonGlow,
    required this.neonPurple,
    required this.neonPink,
  });

  // Default instance for neon dark theme
  factory GameThemeExtension.dark() {
    return const GameThemeExtension(
      rarityCommon: AppColors.rarityCommon,
      rarityUncommon: AppColors.rarityUncommon,
      rarityRare: AppColors.rarityRare,
      rarityEpic: AppColors.rarityEpic,
      rarityLegendary: AppColors.rarityLegendary,
      rarityUnique: AppColors.rarityUnique,
      statHp: AppColors.statHp,
      statMana: AppColors.statMana,
      statGold: AppColors.statGold,
      statArmor: AppColors.statArmor,
      neonGlow: AppColors.neonGlow,
      neonPurple: AppColors.neonPurple,
      neonPink: AppColors.neonPink,
    );
  }

  // Default instance for light parchment theme
  factory GameThemeExtension.light() {
    return const GameThemeExtension(
      rarityCommon: Color(0xFF78909C),
      rarityUncommon: Color(0xFF2E7D32),
      rarityRare: Color(0xFF1565C0),
      rarityEpic: Color(0xFF6A1B9A),
      rarityLegendary: Color(0xFFE65100),
      rarityUnique: Color(0xFF00838F),
      statHp: Color(0xFFC62828),
      statMana: Color(0xFF1565C0),
      statGold: Color(0xFFF57F17),
      statArmor: Color(0xFF37474F),
      neonGlow: Color(0xFF00ACC1),
      neonPurple: Color(0xFF6A1B9A),
      neonPink: Color(0xFFC2185B),
    );
  }

  @override
  GameThemeExtension copyWith({
    Color? rarityCommon,
    Color? rarityUncommon,
    Color? rarityRare,
    Color? rarityEpic,
    Color? rarityLegendary,
    Color? rarityUnique,
    Color? statHp,
    Color? statMana,
    Color? statGold,
    Color? statArmor,
    Color? neonGlow,
    Color? neonPurple,
    Color? neonPink,
  }) {
    return GameThemeExtension(
      rarityCommon: rarityCommon ?? this.rarityCommon,
      rarityUncommon: rarityUncommon ?? this.rarityUncommon,
      rarityRare: rarityRare ?? this.rarityRare,
      rarityEpic: rarityEpic ?? this.rarityEpic,
      rarityLegendary: rarityLegendary ?? this.rarityLegendary,
      rarityUnique: rarityUnique ?? this.rarityUnique,
      statHp: statHp ?? this.statHp,
      statMana: statMana ?? this.statMana,
      statGold: statGold ?? this.statGold,
      statArmor: statArmor ?? this.statArmor,
      neonGlow: neonGlow ?? this.neonGlow,
      neonPurple: neonPurple ?? this.neonPurple,
      neonPink: neonPink ?? this.neonPink,
    );
  }

  @override
  GameThemeExtension lerp(ThemeExtension<GameThemeExtension>? other, double t) {
    if (other is! GameThemeExtension) {
      return this;
    }
    return GameThemeExtension(
      rarityCommon: Color.lerp(rarityCommon, other.rarityCommon, t)!,
      rarityUncommon: Color.lerp(rarityUncommon, other.rarityUncommon, t)!,
      rarityRare: Color.lerp(rarityRare, other.rarityRare, t)!,
      rarityEpic: Color.lerp(rarityEpic, other.rarityEpic, t)!,
      rarityLegendary: Color.lerp(rarityLegendary, other.rarityLegendary, t)!,
      rarityUnique: Color.lerp(rarityUnique, other.rarityUnique, t)!,
      statHp: Color.lerp(statHp, other.statHp, t)!,
      statMana: Color.lerp(statMana, other.statMana, t)!,
      statGold: Color.lerp(statGold, other.statGold, t)!,
      statArmor: Color.lerp(statArmor, other.statArmor, t)!,
      neonGlow: Color.lerp(neonGlow, other.neonGlow, t)!,
      neonPurple: Color.lerp(neonPurple, other.neonPurple, t)!,
      neonPink: Color.lerp(neonPink, other.neonPink, t)!,
    );
  }
}
