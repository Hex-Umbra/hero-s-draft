import 'package:flutter/material.dart';

/// Les icônes que nomme le champ `icon` d'une rune (spec P-43 E2, A19). Un
/// nom absent retombe sur `Icons.help_outline` ; le test d'intégrité exige
/// que chaque rune livrée ait le sien.
const Map<String, IconData> runeIcons = {
  'hardware_rounded': Icons.hardware_rounded,
  'shield_rounded': Icons.shield_rounded,
  'local_fire_department_rounded': Icons.local_fire_department_rounded,
  'ac_unit_rounded': Icons.ac_unit_rounded,
  'flash_on_rounded': Icons.flash_on_rounded,
  'style_rounded': Icons.style_rounded,
  'diamond_rounded': Icons.diamond_rounded,
  'hourglass_bottom_rounded': Icons.hourglass_bottom_rounded,
  'savings_rounded': Icons.savings_rounded,
  'gps_fixed_rounded': Icons.gps_fixed_rounded,
  'blur_on_rounded': Icons.blur_on_rounded,
};

/// Les couleurs que nomme le champ `color` d'une rune (spec P-43 E2, A19). Un
/// nom absent retombe sur le gris ; le test d'intégrité exige que chaque rune
/// livrée ait la sienne.
const Map<String, Color> runeColors = {
  'redAccent': Colors.redAccent,
  'blueAccent': Colors.blueAccent,
  'orangeAccent': Colors.orangeAccent,
  'lightBlueAccent': Colors.lightBlueAccent,
  'amberAccent': Colors.amberAccent,
  'amber': Colors.amber,
  'cyanAccent': Colors.cyanAccent,
  'greenAccent': Colors.greenAccent,
  'tealAccent': Colors.tealAccent,
  'pinkAccent': Colors.pinkAccent,
  'purpleAccent': Colors.purpleAccent,
};
