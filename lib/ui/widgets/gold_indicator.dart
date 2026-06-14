import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/inventory_controller.dart';

class GoldIndicator extends ConsumerWidget {
  final bool isParchment;

  const GoldIndicator({
    super.key,
    this.isParchment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryState = ref.watch(inventoryProvider);
    final color = isParchment ? const Color(0xFF8B4513) : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 4),
          Text(
            '${inventoryState.gold}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
