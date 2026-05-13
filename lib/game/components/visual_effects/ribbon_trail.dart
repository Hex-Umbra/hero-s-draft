import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

/// Un composant qui dessine une traînée fluide en forme de ruban derrière un objet.
class RibbonTrail extends Component {
  final List<Vector2> _points = [];
  final int _maxPoints;
  final double _startWidth;
  final Color _glowColor;
  final Color _coreColor;

  bool _isActive = true;

  RibbonTrail({
    int maxPoints = 20,
    double startWidth = 30.0,
    Color glowColor = Colors.amber,
    Color coreColor = Colors.white,
    int priority = 0,
  })  : _maxPoints = maxPoints,
        _startWidth = startWidth,
        _glowColor = glowColor,
        _coreColor = coreColor {
    this.priority = priority;
  }

  /// Ajoute un nouveau point à la traînée.
  void addPoint(Vector2 pos) {
    if (!_isActive) return;
    
    // Éviter d'ajouter des points trop proches pour garder une courbe fluide
    if (_points.isNotEmpty && (_points.first - pos).length < 3) return;
    
    _points.insert(0, pos.clone());
    if (_points.length > _maxPoints) {
      _points.removeLast();
    }
  }

  /// Arrête d'ajouter des points et laisse la traînée s'effacer naturellement.
  void stop() {
    _isActive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Si la traînée est arrêtée ou si on veut qu'elle défile, on retire les points les plus vieux
    if (!_isActive && _points.isNotEmpty) {
      _points.removeLast();
    } else if (_isActive && _points.length >= _maxPoints) {
      // Optionnel: on pourrait aussi retirer les points ici si on veut une longueur fixe
      // Mais addPoint s'en occupe déjà.
    }

    if (_points.isEmpty && !_isActive) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_points.length < 3) return;

    final path = Path();
    final List<Offset> leftSide = [];
    final List<Offset> rightSide = [];

    for (int i = 0; i < _points.length; i++) {
      final p = _points[i];
      Vector2 direction;
      
      if (i < _points.length - 1) {
        direction = (_points[i + 1] - p).normalized();
      } else {
        direction = (p - _points[i - 1]).normalized();
      }
      
      // Calcul de la normale (perpendiculaire au mouvement)
      final normal = Vector2(-direction.y, direction.x);
      
      // Largeur décroissante (tapering)
      final width = _startWidth * (1.0 - (i / _maxPoints));
      
      leftSide.add((p + normal * (width / 2)).toOffset());
      rightSide.add((p - normal * (width / 2)).toOffset());
    }

    // Construction du polygone du ruban
    path.moveTo(leftSide[0].dx, leftSide[0].dy);
    for (int i = 1; i < leftSide.length; i++) {
      path.lineTo(leftSide[i].dx, leftSide[i].dy);
    }
    for (int i = rightSide.length - 1; i >= 0; i--) {
      path.lineTo(rightSide[i].dx, rightSide[i].dy);
    }
    path.close();

    // 1. Lueur extérieure (Glow)
    final glowPaint = Paint()
      ..color = _glowColor.withAlpha(120)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // 2. Cœur brillant (Core)
    final corePaint = Paint()
      ..color = _coreColor.withAlpha(220)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, corePaint);
  }
}
