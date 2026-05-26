import 'package:flutter/material.dart';
import '../sword_icon.dart';

class PlayerHealthBar extends StatelessWidget {
  final int currentPv;
  final int maxPv;
  final int armure;
  final int effectiveAttaque;

  const PlayerHealthBar({
    super.key,
    required this.currentPv,
    required this.maxPv,
    required this.armure,
    required this.effectiveAttaque,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      children: [
        // 1. Stats à gauche (alignés à droite pour s'accoler à la barre de vie)
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dégâts d'Attaque (Rouge Gradient, sans fond)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFF2A2A),
                      Color(0xFFFF7A7A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SwordIcon(size: 20, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$effectiveAttaque',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Armure (Bleu Gradient, sans fond, toujours affiché)
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF2196F3),
                      Color(0xFF00E5FF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$armure',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14), // Espacement avec la barre de vie
              ],
            ),
          ),
        ),

        // 2. Barre de vie progressive centrée (Largeur fixe de 26% de l'écran)
        SizedBox(
          width: screenWidth * 0.26,
          child: Container(
            height: 26,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withAlpha(50),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                children: [
                  // Remplissage PV (Vert - Core interne avec padding)
                  if (maxPv > 0 && currentPv > 0)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (currentPv / maxPv).clamp(0.0, 1.0),
                      heightFactor: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3.0, horizontal: 1.5),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF1E824C), // Vert forêt foncé
                                Color(0xFF27AE60), // Vert éclatant
                                Color(0xFF58D68D), // Vert doux / menthe
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Remplissage Armure (Bleu Translucide - Englobant avec 0.5px de padding)
                  if (armure > 0 && maxPv > 0)
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (armure / maxPv).clamp(0.0, 1.0),
                      heightFactor: 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 0.5, horizontal: 0.5),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent.withValues(alpha: 0.45),
                                Colors.lightBlueAccent.withValues(alpha: 0.65),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.7),
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Texte des PV
                  Center(
                    child: Text(
                      '$currentPv / $maxPv PV',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Espaceur symétrique à droite (pour garantir le centrage parfait de la barre de vie)
        const Expanded(
          flex: 1,
          child: SizedBox(),
        ),
      ],
    );
  }
}
