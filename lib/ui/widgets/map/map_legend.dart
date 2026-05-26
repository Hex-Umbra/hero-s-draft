import 'package:flutter/material.dart';

class LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const LegendItem({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF4A3728).withAlpha(230), // Brun foncé
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD2B48C)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'LÉGENDE',
            style: TextStyle(
              color: Color(0xFFE8D5B5), // Couleur parchemin
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Divider(color: Colors.white24),
          LegendItem(
            icon: Icons.flash_on,
            color: Colors.white,
            label: 'Combat',
          ),
          LegendItem(
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent,
            label: 'Élite',
          ),
          LegendItem(
            icon: Icons.shopping_cart_outlined,
            color: Colors.amber,
            label: 'Boutique',
          ),
          LegendItem(
            icon: Icons.nightlight_round,
            color: Colors.greenAccent,
            label: 'Repos',
          ),
          LegendItem(
            icon: Icons.help_outline,
            color: Colors.blueAccent,
            label: 'Événement',
          ),
          LegendItem(
            icon: Icons.dangerous,
            color: Colors.purpleAccent,
            label: 'Boss',
          ),
        ],
      ),
    );
  }
}
