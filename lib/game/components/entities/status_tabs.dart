import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../../game_constants.dart';
import '../../systems/status_readout.dart';

/// La languette d'un côté d'une carte de combat : les bonus à gauche, les
/// altérations et les charges à droite (spec P-05, §5.3). Au repos, l'émoji et
/// la valeur dessous ; déroulée, le nom, la valeur et la durée. Elle ne décide
/// rien : elle montre les entrées que sa carte lui donne. Son [position] et sa
/// [size] sont le rectangle dessiné, en unités de la carte ; elle ne reçoit
/// aucun appui, sa carte le prend sur [zoneLocalRects] (A17).
class StatusTabs extends PositionComponent {
  StatusTabs({
    required this.side,
    required this.anchorRect,
  }) : super(priority: _priority) {
    _target = _emptyRect;
    position.setValues(_target.left, _target.top);
  }

  final StatusSide side;

  /// Le rectangle auquel la languette s'attache, dans la carte : le gabarit
  /// d'un ennemi (B77), la carte entière du héros.
  final Rect anchorRect;

  /// Au-dessus de la gangue (4) et du halo (5) que porte la carte.
  static const int _priority = 6;

  static const double _top = 11;
  static const double _restPitch = 31;
  static const double _restPadding = 3;
  static const double _restValueTop = 17;
  static const double _minWidth = 30;
  static const double _maxWidth = 120;
  static const double _padX = 8;
  static const double _padY = 4;
  static const double _emojiBox = 16;
  static const double _textGap = 6;
  static const double _pitch = 22;
  static const double _pitchWithSubtitle = 30;
  static const double _radius = 4;
  static const double _seconds = 0.1;

  static const double _textX = _padX + _emojiBox + _textGap;
  static const double _maxTextWidth = _maxWidth - _textX - _padX;
  static const double _maxRestValueWidth = GameConstants.statusTabRestWidth - 2 * _restPadding;

  static final Paint _fill = Paint()..color = const Color(0xFF14141E);
  static final Paint _stroke = Paint()
    ..color = const Color(0xFF766734)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  final List<_TabRow> _rows = [];
  bool _unfolded = false;
  bool _inward = false;
  late Rect _target;

  /// Range les entrées, de haut en bas. Une entrée déjà montrée, reconnue à sa
  /// clé, se met à jour en place.
  void setEntries(List<StatusReadout> entries) {
    final known = {for (final row in _rows) row.entryKey: row};
    final rows = <_TabRow>[];
    for (final entry in entries) {
      final row = known.remove(entry.key);
      if (row != null) {
        row.show(entry);
        rows.add(row);
      } else {
        final fresh = _TabRow(entry);
        add(fresh);
        rows.add(fresh);
      }
    }
    for (final stale in _rows) {
      if (!rows.contains(stale)) stale.removeFromParent();
    }
    _rows
      ..clear()
      ..addAll(rows);
    _layoutRows();
    _goTo(_currentTarget, animate: isMounted);
  }

  /// Déroule ou replie la languette, en 0,1 s ; [inward] la déroule par-dessus
  /// le gabarit de sa carte (B39).
  void setUnfolded(bool unfolded, {bool inward = false}) {
    final nextInward = unfolded && inward;
    if (unfolded == _unfolded && nextInward == _inward) return;
    _unfolded = unfolded;
    _inward = nextInward;
    _layoutRows();
    _goTo(_currentTarget, animate: isMounted);
  }

  /// La largeur déroulée, en unités de la carte : celle du contenu, bornée à
  /// `[30, 120]` ; 0 sans entrée.
  double get unfoldedWidth {
    if (_rows.isEmpty) return 0;
    final text = _rows.map((row) => row.openTextWidth).reduce(max);
    return (_textX + text + _padX).clamp(_minWidth, _maxWidth);
  }

  /// Le rectangle au repos dans la carte, nul sans entrée.
  Rect? get restLocalRect => _rows.isEmpty ? null : _restRect;

  /// Le rectangle dessiné dans la carte, nul sans entrée.
  Rect? get localRect => _rows.isEmpty
      ? null
      : Rect.fromLTWH(position.x, position.y, size.x, size.y);

  /// La part de la languette dans la zone de sa carte (spec P-05, §4.5), en
  /// unités de la carte : son rectangle au repos et son rectangle dessiné ;
  /// rien sans entrée. Le survol et l'appui lisent la même.
  Iterable<Rect> get zoneLocalRects => [restLocalRect, localRect].nonNulls;

  double get _restX => side == StatusSide.left
      ? anchorRect.left + GameConstants.statusTabOverlap - GameConstants.statusTabRestWidth
      : anchorRect.right - GameConstants.statusTabOverlap;

  double get _topY => anchorRect.top + _top;

  Rect get _emptyRect => Rect.fromLTWH(_restX, _topY, 0, 0);

  Rect get _restRect => Rect.fromLTWH(
        _restX,
        _topY,
        GameConstants.statusTabRestWidth,
        2 * _restPadding + _rows.length * _restPitch,
      );

  Rect get _unfoldedRect {
    final width = unfoldedWidth;
    final x = switch ((side, _inward)) {
      (StatusSide.left, false) => anchorRect.left + GameConstants.statusTabOverlap - width,
      (StatusSide.left, true) => anchorRect.left,
      (StatusSide.right, false) => anchorRect.right - GameConstants.statusTabOverlap,
      (StatusSide.right, true) => anchorRect.right - width,
    };
    final height = _rows.fold(2 * _padY, (sum, row) => sum + row.pitch);
    return Rect.fromLTWH(x, _topY, width, height);
  }

  Rect get _currentTarget {
    if (_rows.isEmpty) return _emptyRect;
    return _unfolded ? _unfoldedRect : _restRect;
  }

  void _layoutRows() {
    var y = _unfolded ? _padY : _restPadding;
    for (final row in _rows) {
      row.layout(unfolded: _unfolded, top: y);
      y += _unfolded ? row.pitch : _restPitch;
    }
  }

  void _goTo(Rect target, {required bool animate}) {
    if (target == _target) return;
    _target = target;
    removeAll(children.whereType<Effect>());
    if (!animate) {
      position.setValues(target.left, target.top);
      size.setValues(target.width, target.height);
      return;
    }
    add(
      MoveEffect.to(
        Vector2(target.left, target.top),
        EffectController(duration: _seconds),
      ),
    );
    add(
      SizeEffect.to(
        Vector2(target.width, target.height),
        EffectController(duration: _seconds),
      ),
    );
  }

  /// Le cadre, puis ce qui dépasse du cadre est coupé : les entrées que les
  /// enfants dessinent, pendant que le cadre grandit ou rétrécit.
  @override
  void render(Canvas canvas) {
    final frame = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(_radius),
    );
    if (_rows.isNotEmpty) {
      canvas.drawRRect(frame, _fill);
      canvas.drawRRect(frame.deflate(0.5), _stroke);
    }
    canvas.clipRRect(frame);
  }
}

/// Une entrée de la languette : ses deux dessins, au repos et déroulé, dont
/// un seul se voit.
class _TabRow extends PositionComponent {
  _TabRow(StatusReadout entry) : entryKey = entry.key {
    _rest.addAll([_restEmoji, _restValue]);
    _open.addAll([_openEmoji, _title, _subtitle]);
    addAll([_rest, _open]);
    show(entry);
  }

  /// La clé de l'entrée montrée (`StatusReadout.key`).
  final String entryKey;

  final _rest = _Layer();
  final _open = _Layer();
  final _restEmoji = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameConstants.statusTabRestWidth / 2, 0),
    textRenderer: _emojiPaint,
  );
  final _restValue = TextComponent(
    anchor: Anchor.topCenter,
    position: Vector2(GameConstants.statusTabRestWidth / 2, StatusTabs._restValueTop),
  );
  final _openEmoji = TextComponent(
    anchor: Anchor.center,
    textRenderer: _emojiPaint,
  );
  final _title = TextComponent(textRenderer: _titlePaint);
  final _subtitle = TextComponent(textRenderer: _subtitlePaint);

  ReadoutTone? _tone;
  bool _hasSubtitle = false;

  static final _emojiPaint = TextPaint(style: const TextStyle(fontSize: 14));
  static final _titlePaint = TextPaint(
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Color(0xFFF7F7FA),
    ),
  );
  static final _subtitlePaint = TextPaint(
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.bold,
      color: Color(0xFFFFD740),
    ),
  );

  double get pitch =>
      _hasSubtitle ? StatusTabs._pitchWithSubtitle : StatusTabs._pitch;

  double get openTextWidth => max(_title.width, _subtitle.width);

  void show(StatusReadout entry) {
    _restEmoji.text = entry.emoji;
    _openEmoji.text = entry.emoji;
    if (entry.tone != _tone) {
      _tone = entry.tone;
      _restValue.textRenderer = TextPaint(
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: StatusReadout.toneColor(entry.tone),
        ),
      );
    }
    _restValue.text = entry.restValue;
    final width = _restValue.width;
    _restValue.scale = Vector2.all(
      width > StatusTabs._maxRestValueWidth
          ? StatusTabs._maxRestValueWidth / width
          : 1,
    );
    _title.text = _clip(entry.title, _titlePaint);
    final subtitle = entry.subtitle;
    _hasSubtitle = subtitle != null;
    _subtitle.text = subtitle == null ? '' : _clip(subtitle, _subtitlePaint);
  }

  void layout({required bool unfolded, required double top}) {
    position.setValues(0, top);
    _rest.isVisible = !unfolded;
    _open.isVisible = unfolded;
    _openEmoji.position.setValues(
      StatusTabs._padX + StatusTabs._emojiBox / 2,
      pitch / 2,
    );
    _title.position.setValues(StatusTabs._textX, _hasSubtitle ? 3 : 5);
    _subtitle.position.setValues(StatusTabs._textX, 15);
  }

  /// Le texte coupé par des points de suspension s'il dépasse la largeur
  /// déroulée la plus grande.
  static String _clip(String text, TextPaint paint) {
    bool fits(String candidate) =>
        paint.getLineMetrics(candidate).width <= StatusTabs._maxTextWidth;
    if (fits(text)) return text;
    var end = text.length;
    while (end > 0 && !fits('${text.substring(0, end)}…')) {
      end--;
    }
    return '${text.substring(0, end)}…';
  }
}

class _Layer extends PositionComponent with HasVisibility {}
