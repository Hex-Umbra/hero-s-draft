import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/status_effect.dart';

class StatusIndicator extends PositionComponent {
  final List<StatusEffect> statuses;

  StatusIndicator({required this.statuses, super.position});

  @override
  Future<void> onLoad() async {
    _refresh();
  }

  void updateStatuses(List<StatusEffect> newStatuses) {
    if (newStatuses == statuses) return;
    _refresh(newStatuses);
  }

  void _refresh([List<StatusEffect>? newStatuses]) {
    removeAll(children.toList());
    
    final list = newStatuses ?? statuses;
    double currentX = 0;

    for (var status in list) {
      final icon = _StatusIcon(status: status, position: Vector2(currentX, 0));
      add(icon);
      currentX += 30; // Espacement entre les icônes
    }
  }
}

class _StatusIcon extends PositionComponent {
  final StatusEffect status;

  _StatusIcon({required this.status, super.position}) : super(size: Vector2(25, 25));

  @override
  Future<void> onLoad() async {
    // Emoji de fond
    add(TextComponent(
      text: _getEmoji(status.id),
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18),
      ),
    ));

    // Valeur/Durée en petit
    add(TextComponent(
      text: status.value.toString(),
      anchor: Anchor.bottomRight,
      position: size,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 12,
          color: status.type == StatusType.buff ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
    ));
  }

  String _getEmoji(String id) {
    switch (id) {
      case 'poison': return '🧪';
      case 'strength': return '💪';
      case 'weakness': return '🥀';
      case 'vulnerable': return '🎯';
      case 'strength_regen': return '🔥';
      case 'armor_regen': return '🛡️';
      case 'lifesteal': return '🧛';
      default: return '✨';
    }
  }
}
