import 'package:flutter/material.dart';
import '../../models/data/effect_icon_table.dart';

/// Les icônes que nomme le champ `icon` d'une évolution de signature et d'une
/// sorte de `effect_icons.json` (spec §3.7, A35, A39). Un nom absent retombe
/// sur `Icons.help_outline` ; le test d'intégrité exige que chaque nom livré
/// y figure.
const Map<String, IconData> effectIcons = {
  'hardware_rounded': Icons.hardware_rounded,
  'shield_rounded': Icons.shield_rounded,
  'favorite_rounded': Icons.favorite_rounded,
  'flare_rounded': Icons.flare_rounded,
  'bolt_rounded': Icons.bolt_rounded,
  'autorenew_rounded': Icons.autorenew_rounded,
  'trending_down_rounded': Icons.trending_down_rounded,
  'gps_fixed_rounded': Icons.gps_fixed_rounded,
  'local_fire_department_rounded': Icons.local_fire_department_rounded,
  'style_rounded': Icons.style_rounded,
  'fast_forward_rounded': Icons.fast_forward_rounded,
  'rocket_launch_rounded': Icons.rocket_launch_rounded,
  'all_out_rounded': Icons.all_out_rounded,
  'savings_rounded': Icons.savings_rounded,
  'diamond_rounded': Icons.diamond_rounded,
  'science_rounded': Icons.science_rounded,
  'ac_unit_rounded': Icons.ac_unit_rounded,
  'flash_on_rounded': Icons.flash_on_rounded,
};

/// Les couleurs que nomme le champ `color` d'une évolution et d'une sorte
/// d'effet. Un nom absent retombe sur le gris.
const Map<String, Color> effectColors = {
  'redAccent': Colors.redAccent,
  'blueAccent': Colors.blueAccent,
  'pinkAccent': Colors.pinkAccent,
  'amber': Colors.amber,
  'orangeAccent': Colors.orangeAccent,
  'purpleAccent': Colors.purpleAccent,
  'deepOrangeAccent': Colors.deepOrangeAccent,
  'tealAccent': Colors.tealAccent,
  'yellowAccent': Colors.yellowAccent,
  'deepPurpleAccent': Colors.deepPurpleAccent,
  'cyanAccent': Colors.cyanAccent,
  'greenAccent': Colors.greenAccent,
  'lightBlueAccent': Colors.lightBlueAccent,
  'amberAccent': Colors.amberAccent,
};

/// L'icône et la couleur de [kind] : celles de [table], ou l'icône d'aide et
/// le gris pour une sorte absente ou un nom inconnu.
({IconData icon, Color color}) effectVisualsOf(
  EffectIconTable table,
  String kind,
) {
  final entry = table.entryOf(kind);
  return (
    icon: effectIcons[entry?.icon] ?? Icons.help_outline,
    color: effectColors[entry?.color] ?? Colors.grey,
  );
}

/// Comme [effectVisualsOf], mais `null` pour une sorte absente de [table] :
/// ce que lit le panneau des statuts pour garder son icône d'aujourd'hui.
({IconData icon, Color color})? effectVisualsOrNull(
  EffectIconTable table,
  String kind,
) =>
    table.entryOf(kind) == null ? null : effectVisualsOf(table, kind);
