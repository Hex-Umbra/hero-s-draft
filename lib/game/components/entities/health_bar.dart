import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HealthBarComponent extends PositionComponent {
  final double barWidth;
  final double barHeight;
  final Color barColor;

  double _currentPv;
  double _maxPv;

  late final RectangleComponent _background;
  late final RectangleComponent _foreground;
  late final TextComponent _text;

  HealthBarComponent({
    required this.barWidth,
    required this.barHeight,
    required double currentPv,
    required double maxPv,
    this.barColor = const Color(0xFFC0392B),
  }) : _currentPv = currentPv,
       _maxPv = maxPv,
       super(size: Vector2(barWidth, barHeight));

  @override
  Future<void> onLoad() async {
    // Fond de la barre
    _background = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF2C3E50).withAlpha(200),
    );
    add(_background);

    // Barre de progression
    _foreground = RectangleComponent(
      size: Vector2((_currentPv / _maxPv) * barWidth, barHeight),
      paint: Paint()..color = barColor,
    );
    add(_foreground);

    // Bordure
    add(
      RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      ),
    );

    // Texte (Valeurs numériques)
    _text = TextComponent(
      text: '${_currentPv.toInt()} / ${_maxPv.toInt()}',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: size / 2,
    );
    add(_text);
  }

  void updateValues(double current, double max) {
    _currentPv = current;
    _maxPv = max;

    // Mise à jour visuelle
    final progress = (_currentPv / _maxPv).clamp(0.0, 1.0);
    _foreground.size.x = progress * barWidth;
    _text.text = '${_currentPv.toInt()} / ${_maxPv.toInt()}';
  }
}
