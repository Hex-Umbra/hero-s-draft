import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../game_constants.dart';

/// Le voile noir qui estompe la scène Flame pendant la fiche d'un ennemi
/// (spec P-05 vague 1, A11) : décor, héros, main et autres ennemis. Sans
/// `TapCallbacks`, il ne reçoit aucun appui : un toucher passe à ce qu'il
/// couvre.
class InspectionVeil extends RectangleComponent {
  /// L'opacité du voile posé.
  static const double shownOpacity = 0.55;

  InspectionVeil({required Vector2 size})
      : super(
          size: size,
          priority: GameConstants.priorityInspectionVeil,
          paint: Paint()..color = Colors.black.withValues(alpha: 0),
        );

  void show() => _fadeTo(shownOpacity);

  void hide() => _fadeTo(0);

  /// Le fondu en cours, gardé ici : ajouté dans la même image, il n'est pas
  /// encore dans `children`, et ouvrir puis fermer dans la même image
  /// additionnerait les deux fondus.
  OpacityEffect? _fade;

  void _fadeTo(double opacity) {
    _fade?.removeFromParent();
    add(
      _fade = OpacityEffect.to(
        opacity,
        EffectController(duration: GameConstants.inspectionSeconds),
      ),
    );
  }
}
