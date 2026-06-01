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

  bool _areStatusListsEqual(
    List<StatusEffect> list1,
    List<StatusEffect> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      final s1 = list1[i];
      final s2 = list2[i];
      if (s1.id != s2.id ||
          s1.value != s2.value ||
          s1.duration != s2.duration) {
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
      for (var icon in currentIcons) icon.status.id: icon,
    };

    final Set<String> newIds = list.map((s) => s.id).toSet();

    // Supprimer les icônes obsolètes
    for (var icon in currentIcons) {
      if (!newIds.contains(icon.status.id)) {
        remove(icon);
      }
    }

    // Mettre à jour ou ajouter les icônes actives (empilées verticalement)
    double currentY = 0;
    for (var status in list) {
      final existingIcon = iconMap[status.id];
      if (existingIcon != null) {
        existingIcon.updateStatus(status);
        existingIcon.position = Vector2(0, currentY);
      } else {
        final icon = _StatusIcon(
          status: status,
          position: Vector2(0, currentY),
        );
        add(icon);
      }
      currentY +=
          36; // Espacement vertical suffisant pour loger l'icône, le texte à droite et les tours en bas
    }
  }
}

class _StatusIcon extends PositionComponent {
  StatusEffect status;
  TextComponent? _valueText;
  TextComponent? _durationText;

  _StatusIcon({required this.status, super.position})
    : super(size: Vector2(20, 20));

  @override
  Future<void> onLoad() async {
    // Emoji de fond centré dans la zone de l'icône (20x20)
    add(
      TextComponent(
        text: _getEmoji(status.id),
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 14)),
      ),
    );

    // 1. Valeur (Dégâts / Puissance) : à droite de l'icône (x=24, y=10)
    _valueText = TextComponent(
      text: status.value.toString(),
      anchor: Anchor.centerLeft,
      position: Vector2(22, size.y / 2),
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: 10,
          color: status.type == StatusType.buff
              ? Colors.greenAccent
              : Colors.redAccent,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
    add(_valueText!);

    // 2. Durée (Nombre de tours restants) : en bas de l'icône (x=10, y=22)
    _durationText = TextComponent(
      text: status.duration.toString(),
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 1),
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 8.5,
          color: Colors.amberAccent,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
          ],
        ),
      ),
    );
    add(_durationText!);
  }

  void updateStatus(StatusEffect newStatus) {
    status = newStatus;
    _valueText?.text = status.value.toString();
    _durationText?.text = status.duration.toString();
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
        return '✊';
      case 'armor_regen':
        return '🛡️';
      case 'lifesteal':
        return '🧛';
      case 'burn':
        return '🔥';
      case 'freeze':
        return '❄️';
      case 'shock':
        return '⚡';
      default:
        return '✨';
    }
  }
}
