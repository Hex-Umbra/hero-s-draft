import 'package:flutter/material.dart';
import '../../../game/systems/cost_rules.dart';

/// Le médaillon d'un coût de carte : le mana (cyan), les PV (goutte rouge) ou
/// l'Armure (écu gris-bleu). Le rouge d'une ressource qui manque vit sur la face
/// Flame, qui connaît les ressources du héros.
class CardCostMedallion extends StatelessWidget {
  final CostResource resource;
  final int amount;

  const CardCostMedallion({
    super.key,
    required this.resource,
    required this.amount,
  });

  Color get _color => switch (resource) {
        CostResource.mana => Colors.cyanAccent,
        CostResource.hp => Colors.redAccent,
        CostResource.armor => Colors.blueGrey.shade200,
      };

  IconData? get _icon => switch (resource) {
        CostResource.mana => null,
        CostResource.hp => Icons.water_drop_rounded,
        CostResource.armor => Icons.shield_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0D1B2A),
        border: Border.all(
          color: _color,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (icon != null)
            Icon(icon, size: 20, color: _color.withValues(alpha: 0.25)),
          Text(
            '$amount',
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
