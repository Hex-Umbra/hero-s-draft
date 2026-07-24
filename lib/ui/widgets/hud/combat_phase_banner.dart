import 'package:flutter/material.dart';

/// Bandeau central "Tour du Joueur" / "Tour de l'Ennemi" affiché en transition de phase.
class CombatPhaseBanner extends StatelessWidget {
  final String text;

  const CombatPhaseBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(180),
            border: Border.symmetric(
              horizontal: BorderSide(
                color: Colors.amber.withAlpha(200),
                width: 2,
              ),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}
