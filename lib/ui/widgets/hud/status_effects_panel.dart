import 'package:flutter/material.dart';
import '../../../models/status_effect.dart';

class StatusEffectsPanel extends StatelessWidget {
  final List<StatusEffect> statuses;

  const StatusEffectsPanel({
    super.key,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withAlpha(240),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withAlpha(100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(150),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Row(
            children: [
              Icon(
                Icons.offline_bolt,
                color: Colors.cyanAccent,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                "EFFETS DU JOUEUR",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 12),
          if (statuses.isEmpty)
            const Text(
              "Aucun effet actif",
              style: TextStyle(
                color: Colors.white30,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...statuses.map((status) {
              IconData icon;
              Color color;
              String label;

              switch (status.id) {
                case 'strength':
                  icon = Icons.flash_on;
                  color = Colors.orangeAccent;
                  label = 'Attaque : +${status.value}';
                  break;
                case 'poison':
                  icon = Icons.sick;
                  color = const Color(0xFF69F0AE);
                  label = 'Poison : ${status.value}';
                  break;
                case 'metallicize':
                  icon = Icons.shield;
                  color = Colors.cyanAccent;
                  label = 'Métallisation : +${status.value}';
                  break;
                default:
                  icon = status.type == StatusType.buff
                      ? Icons.arrow_upward
                      : Icons.arrow_downward;
                  color = status.type == StatusType.buff
                      ? Colors.greenAccent
                      : Colors.redAccent;
                  label = '${status.name} : ${status.value}';
                  break;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${status.duration} trs',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
