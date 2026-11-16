import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../models/charge_track.dart';
import '../../../models/data/charge_data.dart';
import '../../../models/status_effect.dart';
import '../../systems/charge_rules.dart';

class StatusIndicator extends PositionComponent {
  List<StatusEffect> statuses;

  /// Une ligne par charge portée, dessinée après les statuts, sans durée
  /// (spec P-53, §5.1).
  List<ChargeLine> chargeLines;

  /// Le nom de l'état rompu d'une charge, dans la langue active.
  final String Function(String chargeId) brokenNameOf;

  StatusIndicator({
    required this.statuses,
    required this.chargeLines,
    required this.brokenNameOf,
    super.position,
  });

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

  /// Un gel consommé ne change que la piste : la comparaison porte aussi sur
  /// les lignes des charges, sans quoi l'indicateur ne se redessinerait pas.
  void updateStatuses(
    List<StatusEffect> newStatuses,
    List<ChargeLine> newChargeLines,
  ) {
    if (_areStatusListsEqual(newStatuses, statuses) &&
        listEquals(newChargeLines, chargeLines)) {
      return;
    }
    statuses = List.from(newStatuses);
    chargeLines = List.from(newChargeLines);
    _refresh();
  }

  void _refresh() {
    final views = [
      for (final status in statuses) _IconView.ofStatus(status),
      for (final line in chargeLines) _IconView.ofCharge(line, brokenNameOf),
    ];

    // Récupérer les icônes existantes pour faire une mise à jour en place (reconciliation)
    final currentIcons = children.whereType<_StatusIcon>().toList();
    final Map<String, _StatusIcon> iconMap = {
      for (var icon in currentIcons) icon.view.key: icon,
    };

    final Set<String> newKeys = views.map((v) => v.key).toSet();

    // Supprimer les icônes obsolètes
    for (var icon in currentIcons) {
      if (!newKeys.contains(icon.view.key)) {
        remove(icon);
      }
    }

    // Mettre à jour ou ajouter les icônes actives (empilées verticalement)
    double currentY = 0;
    for (var view in views) {
      final existingIcon = iconMap[view.key];
      if (existingIcon != null) {
        existingIcon.updateView(view);
        existingIcon.position = Vector2(0, currentY);
      } else {
        final icon = _StatusIcon(
          view: view,
          position: Vector2(0, currentY),
        );
        add(icon);
      }
      currentY +=
          36; // Espacement vertical suffisant pour loger l'icône, le texte à droite et les tours en bas
    }
  }
}

/// Ce qu'une icône écrit : son émoji, sa valeur à droite, et en dessous la
/// durée d'un statut ou le nom de l'état rompu d'une charge.
class _IconView {
  final String key;
  final String emoji;
  final String value;
  final Color valueColor;
  final String caption;

  const _IconView({
    required this.key,
    required this.emoji,
    required this.value,
    required this.valueColor,
    required this.caption,
  });

  factory _IconView.ofStatus(StatusEffect status) => _IconView(
        key: status.id,
        emoji: _getEmoji(status.id),
        value: status.value.toString(),
        valueColor: status.type == StatusType.buff
            ? Colors.greenAccent
            : Colors.redAccent,
        caption: status.duration.toString(),
      );

  /// Spec P-53, §5.1 : « 🔥 5 » pour le Feu, « ❄ 2/3 » sous le seuil, « ⚡ 4 »
  /// en jaune vif sous-titré de l'état pour la Foudre chargée, « ❄ » sous-titré
  /// de l'état pour l'ennemi gelé.
  factory _IconView.ofCharge(
    ChargeLine line,
    String Function(String chargeId) brokenNameOf,
  ) {
    final broken = line.kind != RuptureKind.explode &&
        line.state != ChargeState.none;
    final charged = broken && line.kind == RuptureKind.amplifyHits;
    return _IconView(
      key: 'charge:${line.chargeId}',
      emoji: _getEmoji(line.chargeId),
      value: switch (line) {
        ChargeLine(kind: RuptureKind.explode) => '${line.points}',
        ChargeLine(state: ChargeState.none) =>
          '${line.points}/${line.threshold}',
        ChargeLine(kind: RuptureKind.amplifyHits) => '${line.points}',
        _ => '',
      },
      valueColor: charged ? Colors.yellowAccent : Colors.redAccent,
      caption: broken ? brokenNameOf(line.chargeId) : '',
    );
  }
}

class _StatusIcon extends PositionComponent {
  _IconView view;
  TextComponent? _valueText;
  TextComponent? _captionText;

  _StatusIcon({required this.view, super.position})
    : super(size: Vector2(20, 20));

  @override
  Future<void> onLoad() async {
    // Emoji de fond centré dans la zone de l'icône (20x20)
    add(
      TextComponent(
        text: view.emoji,
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(style: const TextStyle(fontSize: 14)),
      ),
    );

    // 1. Valeur (Dégâts / Puissance / points de charge) : à droite de l'icône (x=24, y=10)
    _valueText = TextComponent(
      text: view.value,
      anchor: Anchor.centerLeft,
      position: Vector2(22, size.y / 2),
      textRenderer: _valuePaint(view.valueColor),
    );
    add(_valueText!);

    // 2. Durée (Nombre de tours restants) ou état rompu d'une charge : en bas de l'icône (x=10, y=22)
    _captionText = TextComponent(
      text: view.caption,
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
    add(_captionText!);
  }

  TextPaint _valuePaint(Color color) => TextPaint(
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 2.0, offset: Offset(1, 1)),
          ],
        ),
      );

  void updateView(_IconView newView) {
    if (newView.valueColor != view.valueColor) {
      _valueText?.textRenderer = _valuePaint(newView.valueColor);
    }
    view = newView;
    _valueText?.text = view.value;
    _captionText?.text = view.caption;
  }
}

String _getEmoji(String id) {
  switch (id) {
    case 'poison':
      return '🧪';
    case 'might':
      return '⚡';
    case 'weakness':
      return '🥀';
    case 'vulnerable':
      return '🎯';
    case 'might_regen':
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
