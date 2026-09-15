import 'package:flutter/material.dart';

import '../../../services/content_editor/entity_descriptor.dart';
import '../../theme/app_colors.dart';

/// Les couleurs de l'editeur de contenu (spec D10), tirees d'`AppColors` quand
/// le jeu les porte deja. Propres a cet ecran : le reste du jeu n'a ni puits
/// de saisie ni panneaux d'inspecteur.
abstract final class EditorColors {
  /// Barre d'outils, explorateur, panneau de reference.
  static const Color side = Color(0xFF10101F);

  /// Barre de titre, barre d'actions.
  static const Color bar = Color(0xFF13132A);
  static const Color panel = AppColors.surfaceDark;
  static const Color panelHead = Color(0xFF1E1E36);

  /// Le fond d'une saisie.
  static const Color well = Color(0xFF0E0E1C);
  static const Color chip = Color(0xFF16162A);
  static const Color chipBorder = Color(0xFF45456A);
  static const Color line = Color(0xFF26263E);
  static const Color lineStrong = AppColors.darkBorder;
  static const Color keyText = Color(0xFFAFC0C9);
  static const Color soft = Color(0xFFC5D0D6);
  static const Color muted = AppColors.textSecondary;

  /// Le plus discret des textes encore lisibles : 5:1 sur `side` et `panel`.
  static const Color faint = Color(0xFF7A8E9A);
  static const Color accent = AppColors.neonBlue;
  static const Color accentInk = Color(0xFF00141B);

  /// Celle du tiroir de debug : le badge DEBUG dit la meme chose.
  static const Color debug = Colors.deepPurpleAccent;
}

/// Les cles JSON, chemins et identifiants : ce que l'auteur retrouvera tel
/// quel dans le fichier.
TextStyle editorMono({
  double size = 12.5,
  Color color = EditorColors.keyText,
  FontWeight? weight,
}) =>
    TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Consolas', 'Menlo', 'Roboto Mono'],
      fontSize: size,
      color: color,
      fontWeight: weight,
    );

/// L'icone de chaque type : dans la barre d'outils, et sur la tuile de
/// l'en-tete du fichier.
const Map<EntityCategory, IconData> kCategoryIcons = {
  EntityCategory.card: Icons.style,
  EntityCategory.relic: Icons.diamond,
  EntityCategory.passive: Icons.auto_awesome,
  EntityCategory.event: Icons.explore,
  EntityCategory.forgeUpgrade: Icons.hardware,
  EntityCategory.heroClass: Icons.shield,
  EntityCategory.enemy: Icons.pest_control,
};

/// Les couleurs de rarete du jeu, pour les options d'une cle `rarity`.
const Map<String, Color> kRarityColors = {
  'common': AppColors.rarityCommon,
  'uncommon': AppColors.rarityUncommon,
  'rare': AppColors.rarityRare,
  'epic': AppColors.rarityEpic,
  'legendary': AppColors.rarityLegendary,
  'unique': AppColors.rarityUnique,
};

/// Le puits d'une saisie : fond sombre, bord qui s'allume au focus, rouge
/// quand une faute vise le champ. Le message, lui, est affiche par la rangee
/// (`PropertyRow`), jamais par le champ.
InputDecoration editorInputDecoration({
  String? hintText,
  bool hasError = false,
}) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(7)),
        borderSide: BorderSide(color: color, width: width),
      );
  final rest = hasError ? AppColors.danger : EditorColors.lineStrong;
  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(color: EditorColors.faint),
    isDense: true,
    filled: true,
    fillColor: EditorColors.well,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    border: border(rest, 1),
    enabledBorder: border(rest, 1),
    focusedBorder:
        border(hasError ? AppColors.danger : EditorColors.accent, 1.5),
  );
}
