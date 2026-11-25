import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// La gangue de glace d'une carte gelee (spec P-53, §5.2, G-a) : un voile
/// bleu glace borde de blanc qui monte du bas vers le haut a la pose, reste
/// tant que le gel dure, puis se brise en eclats ou fond.
class FrostShell extends PositionComponent {
  FrostShell({required Vector2 size, required this.opacity, super.position})
      : super(size: size, priority: _shellPriority);

  static const Color veilColor = Color(0xFF81D4FA);
  static const double enemyOpacity = 0.45;
  static const double heroOpacity = 0.25;

  /// La duree de la montee du voile, que le serrement de la carte partage.
  static const double riseSeconds = 0.4;

  static const int _shellPriority = 4;
  static const double _shatterSeconds = 0.4;
  static const double _fadeSeconds = 0.2;
  static const double _rimWidth = 2;
  static const int _minShards = 6;
  static const int _extraShards = 3;
  static const double _shardReach = 70;
  static const double _shardSize = 9;

  final double opacity;

  double _age = 0;
  double _fadeAge = 0;
  bool _fadingOut = false;
  double _shatterAge = 0;
  List<_Shard>? _shards;

  /// Les eclats projetes autour de la carte, puis le retrait de la gangue.
  void shatter() {
    if (_shards != null) return;
    final rand = Random();
    final count = _minShards + rand.nextInt(_extraShards);
    _shards = List.generate(count, (i) {
      final angle = (i + rand.nextDouble()) / count * 2 * pi;
      return _Shard(
        origin: Offset(rand.nextDouble() * size.x, rand.nextDouble() * size.y),
        direction: Offset(cos(angle), sin(angle)),
        reach: _shardReach * (0.6 + rand.nextDouble() * 0.6),
        size: _shardSize * (0.6 + rand.nextDouble() * 0.8),
        color: i.isEven ? Colors.white : veilColor,
        turn: rand.nextDouble() * pi,
      );
    });
  }

  /// Le fondu de sortie, puis le retrait de la gangue.
  void fadeOut() {
    _fadingOut = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_shards != null) {
      _shatterAge += dt;
      if (_shatterAge >= _shatterSeconds) removeFromParent();
    } else if (_fadingOut) {
      _fadeAge += dt;
      if (_fadeAge >= _fadeSeconds) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final shards = _shards;
    if (shards != null) {
      _renderShards(canvas, shards);
      return;
    }
    final rise = Curves.easeOut.transform((_age / riseSeconds).clamp(0.0, 1.0));
    final fade = _fadingOut ? 1 - _fadeAge / _fadeSeconds : 1.0;
    final top = size.y * (1 - rise);
    final rect = Rect.fromLTRB(0, top, size.x, size.y);
    canvas.drawRect(
      rect,
      Paint()..color = veilColor.withValues(alpha: (opacity * fade).clamp(0.0, 1.0)),
    );
    canvas.drawRect(
      rect.deflate(_rimWidth / 2),
      Paint()
        ..color = Colors.white.withValues(alpha: fade.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = _rimWidth,
    );
  }

  void _renderShards(Canvas canvas, List<_Shard> shards) {
    final t = (_shatterAge / _shatterSeconds).clamp(0.0, 1.0);
    final travel = Curves.easeOutCubic.transform(t);
    for (final shard in shards) {
      final center = shard.origin + shard.direction * (shard.reach * travel);
      final half = shard.size / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shard.turn + t * pi);
      final path = Path()
        ..moveTo(0, -half)
        ..lineTo(half * 0.7, half)
        ..lineTo(-half * 0.7, half)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = shard.color.withValues(alpha: 1 - t),
      );
      canvas.restore();
    }
  }
}

class _Shard {
  const _Shard({
    required this.origin,
    required this.direction,
    required this.reach,
    required this.size,
    required this.color,
    required this.turn,
  });

  final Offset origin;
  final Offset direction;
  final double reach;
  final double size;
  final Color color;
  final double turn;
}

/// Le givre bleu aux quatre coins de l'ecran, tant que le heros est gele (spec
/// P-53, §5.2, G-a). Il passe sous les cartes : il ne cache ni la main ni les
/// cartes.
class FrostVignette extends PositionComponent {
  FrostVignette({required Vector2 size, required int priority})
      : super(size: size, priority: priority);

  static const double _inSeconds = 0.3;
  static const double _outSeconds = 0.3;
  static const double _peakOpacity = 0.55;
  static const double _reachRatio = 0.4;

  double _age = 0;
  double _fadeAge = 0;
  bool _fadingOut = false;

  /// Le fondu de sortie, puis le retrait du givre.
  void fadeOut() {
    _fadingOut = true;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_fadingOut) {
      _fadeAge += dt;
      if (_fadeAge >= _outSeconds) removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final alive = (_age / _inSeconds).clamp(0.0, 1.0);
    final fade = _fadingOut ? 1 - _fadeAge / _outSeconds : 1.0;
    final alpha = (_peakOpacity * alive * fade).clamp(0.0, 1.0);
    final reach = min(size.x, size.y) * _reachRatio;
    final corners = [
      Offset.zero,
      Offset(size.x, 0),
      Offset(0, size.y),
      Offset(size.x, size.y),
    ];
    for (final corner in corners) {
      final shader = RadialGradient(
        colors: [
          FrostShell.veilColor.withValues(alpha: alpha),
          FrostShell.veilColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: corner, radius: reach));
      canvas.drawCircle(corner, reach, Paint()..shader = shader);
    }
  }
}
