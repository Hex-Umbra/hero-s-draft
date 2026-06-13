import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game_constants.dart';


class FloatingText extends TextComponent with HasPaint {
  final bool isCritical;
  final bool isUpward;
  final bool isPoison;
  final bool isShield;

  final Color baseColor;
  final List<Shadow> baseShadows;
  double _opacity = 1.0;

  FloatingText({
    required String text,
    required Color color,
    required Vector2 position,
    this.isCritical = false,
    this.isUpward = true,
    this.isPoison = false,
    this.isShield = false,
  }) : baseColor = color,
       baseShadows = [
         Shadow(
           color: Colors.black.withValues(alpha: 0.9),
           offset: const Offset(2, 2),
           blurRadius: 4,
         ),
         if (isCritical) ...[
           const Shadow(
             color: Colors.orangeAccent,
             offset: Offset.zero,
             blurRadius: 8,
           ),
           const Shadow(
             color: Colors.redAccent,
             offset: Offset.zero,
             blurRadius: 16,
           ),
         ],
         if (isPoison) ...[
           const Shadow(
             color: Colors.greenAccent,
             offset: Offset.zero,
             blurRadius: 6,
           ),
           const Shadow(
             color: Colors.lightGreenAccent,
             offset: Offset.zero,
             blurRadius: 12,
           ),
         ],
         if (isShield) ...[
           const Shadow(
             color: Colors.cyanAccent,
             offset: Offset.zero,
             blurRadius: 6,
           ),
           const Shadow(
             color: Colors.blueAccent,
             offset: Offset.zero,
             blurRadius: 12,
           ),
         ],
       ],
       super(
         text: '${isCritical ? "💥 CRIT " : (isPoison ? "🧪 " : (isShield ? "🛡️ " : ""))}$text',
         position: position,
         anchor: Anchor.center,
         textRenderer: TextPaint(
           style: TextStyle(
             color: color,
             fontSize: isCritical
                 ? GameConstants.floatingTextFontSizeCritical
                 : (isPoison
                     ? GameConstants.floatingTextFontSizePoison
                     : GameConstants.floatingTextFontSizeStandard),
             fontWeight: FontWeight.bold,
             shadows: [
               Shadow(
                 color: Colors.black.withValues(alpha: 0.9),
                 offset: const Offset(2, 2),
                 blurRadius: 4,
               ),
               if (isCritical) ...[
                 const Shadow(
                   color: Colors.orangeAccent,
                   offset: Offset.zero,
                   blurRadius: 8,
                 ),
                 const Shadow(
                   color: Colors.redAccent,
                   offset: Offset.zero,
                   blurRadius: 16,
                 ),
               ],
               if (isPoison) ...[
                 const Shadow(
                   color: Colors.greenAccent,
                   offset: Offset.zero,
                   blurRadius: 6,
                 ),
                 const Shadow(
                   color: Colors.lightGreenAccent,
                   offset: Offset.zero,
                   blurRadius: 12,
                 ),
               ],
               if (isShield) ...[
                 const Shadow(
                   color: Colors.cyanAccent,
                   offset: Offset.zero,
                   blurRadius: 6,
                 ),
                 const Shadow(
                   color: Colors.blueAccent,
                   offset: Offset.zero,
                   blurRadius: 12,
                 ),
               ],
             ],
           ),
         ),
       );

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    if (_opacity == value) return;
    _opacity = value;
    paint.color = paint.color.withValues(alpha: value);
    _updateTextStyle();
  }

  void _updateTextStyle() {
    textRenderer = TextPaint(
      style: TextStyle(
        color: baseColor.withValues(alpha: _opacity),
        fontSize: isCritical
            ? GameConstants.floatingTextFontSizeCritical
            : (isPoison
                ? GameConstants.floatingTextFontSizePoison
                : GameConstants.floatingTextFontSizeStandard),
        fontWeight: FontWeight.bold,
        shadows: baseShadows.map((shadow) {
          return Shadow(
            color: shadow.color.withValues(alpha: shadow.color.a * _opacity),
            offset: shadow.offset,
            blurRadius: shadow.blurRadius,
          );
        }).toList(),
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    final random = Random();

    // TODO: Audio Hook - sfx_ui_pop (Jouer un son de 'pop' lors de l'apparition du texte)

    // Initialisation de l'échelle pour l'effet "pop"
    scale = Vector2.all(0.1);

    // Rotation aléatoire subtile sur la naissance
    final double randomRotation = (random.nextDouble() - 0.5) * GameConstants.floatingTextRotationFactor;
    add(
      RotateEffect.to(
        randomRotation,
        EffectController(duration: GameConstants.floatingTextDurationBirthRotation, curve: Curves.easeOut),
      ),
    );

    // Trajectoire aléatoire en arc de cercle
    final double driftX = (random.nextDouble() - 0.5) * GameConstants.floatingTextDriftXMax;
    double driftY =
        GameConstants.floatingTextDriftYStandardBase + random.nextDouble() * GameConstants.floatingTextDriftYStandardRandomRange; // Base positive (vers le bas)

    if (isUpward) {
      driftY = -driftY; // Inverser pour aller vers le haut
    }

    // 1. Effet d'Échelle (Pop ou Critique Punchy)
    if (isCritical) {
      add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.5),
            EffectController(duration: GameConstants.floatingTextDurationCritInitialPop, curve: Curves.elasticOut),
          ),
          ScaleEffect.to(
            Vector2.all(1.15),
            EffectController(duration: GameConstants.floatingTextDurationCritInitialReturn, curve: Curves.easeOut),
          ),
          ScaleEffect.to(
            Vector2.all(1.3),
            EffectController(duration: GameConstants.floatingTextDurationCritPulse, alternate: true, infinite: true),
          ),
        ]),
      );
    } else {
      add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: GameConstants.floatingTextDurationStandardBounce, curve: Curves.bounceOut),
        ),
      );
    }

    // 2. Mouvement (Drift)
    if (isPoison) {
      add(
        MoveEffect.by(
          Vector2(0, GameConstants.floatingTextDriftYPoisonBase - random.nextDouble() * GameConstants.floatingTextDriftYPoisonRandomRange),
          EffectController(duration: GameConstants.floatingTextDurationDriftPoison, curve: Curves.easeOutQuad),
        ),
      );
    } else if (isShield) {
      add(
        MoveEffect.by(
          Vector2(driftX * GameConstants.floatingTextDriftXShieldMultiplier, GameConstants.floatingTextDriftYShieldBase - random.nextDouble() * GameConstants.floatingTextDriftYShieldRandomRange),
          EffectController(duration: GameConstants.floatingTextDurationDriftShield, curve: Curves.easeOutQuad),
        ),
      );
    } else {
      add(
        MoveEffect.by(
          Vector2(driftX, driftY),
          EffectController(duration: GameConstants.floatingTextDurationDriftStandard, curve: Curves.easeOutCubic),
        ),
      );
    }

    // 3. Fondu (Fade out)
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: GameConstants.floatingTextDurationFadeOut, curve: Curves.easeIn),
      ),
    );

    add(RemoveEffect(delay: GameConstants.floatingTextDurationRemoveDelay));
  }

  double _time = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isPoison) {
      _time += dt;
      // Add slight horizontal sin wave
      position.x += sin(_time * 10) * 0.8;
    }
  }
}
