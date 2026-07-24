import 'package:flutter/material.dart';

/// Bulle d'information affichée au survol/tap d'un noeud de la carte du monde.
class MapTooltipOverlay extends StatelessWidget {
  final String? title;
  final String? description;

  const MapTooltipOverlay({super.key, this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 40,
      right: 40,
      top: 100,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF4ECD8), // Fond papier
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8B4513), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? '',
                style: const TextStyle(
                  color: Color(0xFF8B4513), // Brun sienne
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(color: Colors.black12),
              Text(
                description ?? '',
                style: const TextStyle(
                  color: Color(0xFF4A3728), // Brun sombre
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
