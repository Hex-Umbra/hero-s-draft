import 'package:flutter/material.dart';

/// Tooltip de description de carte en combat, ancré au-dessus de la main du joueur.
class CombatTooltipOverlay extends StatelessWidget {
  final bool visible;
  final String? title;
  final String? description;
  final Color borderColor;

  const CombatTooltipOverlay({
    super.key,
    required this.visible,
    required this.title,
    required this.description,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 270,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: IgnorePointer(
          ignoring: !visible,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C).withAlpha(245),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(185),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (title ?? '').toUpperCase(),
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
