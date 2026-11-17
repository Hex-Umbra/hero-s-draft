import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

/// L'eclair radial d'un porteur de Feu qui explose (spec P-53, §5.2, F-a) : un
/// disque orange qui s'ouvre jusqu'a [radius] et s'efface, un seul par
/// porteur quel que soit son nombre de tranches, puis [onComplete] et le
/// retrait.
class FireBurst extends PositionComponent {
  FireBurst({
    required Vector2 position,
    required this.radius,
    this.onComplete,
  }) : super(
          position: position,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
          priority: _burstPriority,
        );

  static const Color core = Color(0xFFFF6D00);
  static const Color edge = Color(0xFFFFAB40);
  static const double seconds = 0.35;

  /// Au-dessus des cartes, sous les textes flottants.
  static const int _burstPriority = 150;

  final double radius;
  final void Function()? onComplete;

  double _age = 0;
  bool _done = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_done) return;
    _age += dt;
    if (_age >= seconds) {
      _done = true;
      onComplete?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / seconds).clamp(0.0, 1.0);
    final reach = radius * Curves.easeOutCubic.transform(t);
    if (reach <= 0) return;
    final alpha = 1 - Curves.easeIn.transform(t);
    final center = Offset(radius, radius);
    final shader = RadialGradient(
      colors: [
        core.withValues(alpha: alpha),
        edge.withValues(alpha: alpha * 0.8),
        edge.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: reach));
    canvas.drawCircle(center, reach, Paint()..shader = shader);
  }
}

/// La boule de feu qu'une explosion lance vers un voisin (spec P-53, §5.2,
/// F-a) : elle file de [from] a [to], puis [onArrive] et le retrait.
class Fireball extends PositionComponent {
  Fireball({
    required Vector2 from,
    required this.to,
    required this.onArrive,
  }) : super(
          position: from.clone(),
          size: Vector2.all(_ballRadius * 2),
          anchor: Anchor.center,
          priority: _ballPriority,
        );

  static const double seconds = 0.25;

  static const int _ballPriority = 160;
  static const double _ballRadius = 10;

  final Vector2 to;
  final void Function() onArrive;

  @override
  Future<void> onLoad() async {
    add(
      MoveEffect.to(
        to,
        EffectController(duration: seconds, curve: Curves.easeIn),
        onComplete: () {
          onArrive();
          removeFromParent();
        },
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(_ballRadius, _ballRadius);
    canvas.drawCircle(
      center,
      _ballRadius,
      Paint()
        ..color = FireBurst.edge
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(center, _ballRadius * 0.55, Paint()..color = FireBurst.core);
  }
}
