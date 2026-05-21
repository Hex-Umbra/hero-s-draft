import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../models/status_effect.dart';

class StatusIndicator extends PositionComponent {
  List<StatusEffect> statuses;

  StatusIndicator({required this.statuses, super.position});

  @override
  Future<void> onLoad() async {
    _refresh();
  }

  bool _areStatusListsEqual(List<StatusEffect> list1, List<StatusEffect> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final s1 = list1[i];
      final s2 = list2[i];
      if (s1.id != s2.id || s1.value != s2.value || s1.duration != s2.duration) {
        return false;
      }
    }
    return true;
  }

  void updateStatuses(List<StatusEffect> newStatuses) {
    if (_areStatusListsEqual(newStatuses, statuses)) return;
    statuses = List.from(newStatuses);
    _refresh(newStatuses);
  }

  void _refresh([List<StatusEffect>? newStatuses]) {
    final list = newStatuses ?? statuses;

    // Récupérer les icônes existantes pour faire une mise à jour en place (reconciliation)
    final currentIcons = children.whereType<_StatusIcon>().toList();
    final Map<String, _StatusIcon> iconMap = {
      for (var icon in currentIcons) icon.status.id: icon
    };

    final Set<String> newIds = list.map((s) => s.id).toSet();

    // Supprimer les icônes obsolètes
    for (var icon in currentIcons) {
      if (!newIds.contains(icon.status.id)) {
        remove(icon);
      }
    }

    // Mettre à jour ou ajouter les icônes actives
    double currentX = 0;
    for (var status in list) {
      final existingIcon = iconMap[status.id];
      if (existingIcon != null) {
        existingIcon.updateStatus(status);
        existingIcon.position = Vector2(currentX, 0);
      } else {
        final icon = _StatusIcon(status: status, position: Vector2(currentX, 0));
        add(icon);
      }
      currentX += 30; // Espacement entre les icônes
    }
  }
}

class _StatusIcon extends PositionComponent {
  StatusEffect status;
  TextComponent? _valueText;

  _StatusIcon({required this.status, super.position})
    : super(size: Vector2(25, 25));

  @override
  Future<void> onLoad() async {
    // Emoji de fond
    add(
      TextComponent(
        text: _getEmoji(status.id),
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 18)),
      ),
    );

    // Valeur/Durée en petit
    _valueText = TextComponent(
      text: status.value.toString(),
      anchor: Anchor.bottomRight,
      position: size,
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 12,
          color: status.type == StatusType.buff
              ? Colors.greenAccent
              : Colors.redAccent,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
    );
    add(_valueText!);
  }

  void updateStatus(StatusEffect newStatus) {
    status = newStatus;
    _valueText?.text = status.value.toString();
  }

  String _getEmoji(String id) {
    switch (id) {
      case 'poison':
        return '🧪';
      case 'strength':
        return '💪';
      case 'weakness':
        return '🥀';
      case 'vulnerable':
        return '🎯';
      case 'strength_regen':
        return '🔥';
      case 'armor_regen':
        return '🛡️';
      case 'lifesteal':
        return '🧛';
      default:
        return '✨';
    }
  }
}
