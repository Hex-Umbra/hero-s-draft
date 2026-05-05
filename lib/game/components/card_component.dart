import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../heros_draft_game.dart';
import 'entities/enemy_card.dart';

class CardComponent extends PositionComponent with DragCallbacks, TapCallbacks, HoverCallbacks, HasGameReference<HerosDraftGame> {
  final CardInstance card;

  @override
  void onLongTapDown(TapDownEvent event) {
    game.onShowTooltip(card.data.name, _buildDetailedDescription());
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.onHideTooltip();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    game.onHideTooltip();
  }

  String _buildDetailedDescription() {
    String desc = '${card.data.description}\n\n';
    for (var effect in card.data.effects) {
      if (effect.type == 'damage') desc += '• Dégâts: ${effect.value}\n';
      if (effect.type == 'heal') desc += '• Soin: ${effect.value}\n';
      if (effect.type == 'armor') desc += '• Armure: ${effect.value}\n';
      if (effect.type == 'draw') desc += '• Pioche: ${effect.value} cartes\n';
    }
    return desc.trim();
  }
  
  Vector2 originalPosition = Vector2.zero();
  double originalAngle = 0;
  int basePriority = 10;
  
  bool isDragging = false;
  bool _isHoveringCancelZone = false;

  @override
  bool isHovered = false;
  
  // Paramètres visuels
  static const double cardWidth = 140;
  static const double cardHeight = 196;

  final Paint backgroundPaint = Paint()..color = const Color(0xFF2A2A3D);
  final Paint borderPaint = Paint()
    ..color = Colors.blueAccent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
    
  late TextComponent nameText;
  late TextComponent costText;
  late TextComponent descriptionText;

  CardComponent(this.card) : super(size: Vector2(cardWidth, cardHeight)) {
    anchor = Anchor.center;
  }

  @override
  void onHoverEnter() {
    if (isDragging) return;
    game.setHoveredCard(this);
  }

  @override
  void onHoverExit() {
    if (isDragging) return;
    if (game.hoveredCard == this) {
      game.setHoveredCard(null);
    }
  }

  @override
  Future<void> onLoad() async {
    // Nom de la carte
    nameText = TextComponent(
      text: card.data.name,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      position: Vector2(size.x / 2, 12),
      anchor: Anchor.topCenter,
    );
    add(nameText);

    // Coût en mana
    costText = TextComponent(
      text: '${card.currentCost}',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      position: Vector2(12, 12),
    );
    add(costText);

    // Description (simplifiée pour l'instant)
    descriptionText = TextComponent(
      text: _buildDescription(),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      position: Vector2(size.x / 2, size.y / 2 + 20),
      anchor: Anchor.center,
      size: Vector2(size.x - 24, size.y / 2),
    );
    add(descriptionText);
  }

  String _buildDescription() {
    String desc = '';
    for (var effect in card.data.effects) {
      if (effect.type == 'damage') desc += 'Inflige ${effect.value} dégâts.\n';
      if (effect.type == 'heal') desc += 'Soigne ${effect.value} PV.\n';
      if (effect.type == 'armor') desc += 'Donne ${effect.value} Armure.\n';
    }
    if (desc.isEmpty) desc = card.data.description;
    return desc;
  }

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));
    
    // Fond
    canvas.drawRRect(rrect, backgroundPaint);
    // Bordure
    canvas.drawRRect(rrect, borderPaint);
    
    super.render(canvas);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    game.setFocusedCard(this);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    removeAll(children.whereType<Effect>());
    isDragging = true;
    game.setFocusedCard(this); 
    priority = 200; 
    
    // On ne réinitialise plus originalPosition et originalAngle ici
    // car ils doivent conserver les valeurs du fan layout
    
    angle = 0;
    scale = Vector2.all(1.25); 
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    
    // Feedback visuel de zone de sécurité (annulation)
    bool isInCancelZone = position.y > game.size.y - 220;
    if (isInCancelZone != _isHoveringCancelZone) {
      _isHoveringCancelZone = isInCancelZone;
      _applyCancelZoneFeedback(_isHoveringCancelZone);
    }

    // Gestion du ciblage (Arrow) - Uniquement si on n'est pas en zone d'annulation
    if (card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = _isHoveringCancelZone ? null : _findHoveredEnemy(position);
      game.highlightEnemy(hoveredEnemy);
    }
  }

  void _applyCancelZoneFeedback(bool isCancelling) {
    removeAll(children.whereType<Effect>());
    if (isCancelling) {
      // Effet d'annulation : plus petit, transparent, bordure grise
      add(ScaleEffect.to(Vector2.all(0.9), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D).withAlpha(150);
      borderPaint.color = Colors.grey;
      
      final nameStyle = (nameText.textRenderer as TextPaint).style;
      final costStyle = (costText.textRenderer as TextPaint).style;
      final descStyle = (descriptionText.textRenderer as TextPaint).style;

      nameText.textRenderer = TextPaint(style: nameStyle.copyWith(color: Colors.white.withAlpha(150)));
      costText.textRenderer = TextPaint(style: costStyle.copyWith(color: Colors.lightBlueAccent.withAlpha(150)));
      descriptionText.textRenderer = TextPaint(style: descStyle.copyWith(color: Colors.white70.withAlpha(150)));
    } else {
      // Effet actif : grand, opaque, bordure bleue
      add(ScaleEffect.to(Vector2.all(1.25), EffectController(duration: 0.1)));
      backgroundPaint.color = const Color(0xFF2A2A3D);
      borderPaint.color = Colors.blueAccent;

      final nameStyle = (nameText.textRenderer as TextPaint).style;
      final costStyle = (costText.textRenderer as TextPaint).style;
      final descStyle = (descriptionText.textRenderer as TextPaint).style;

      nameText.textRenderer = TextPaint(style: nameStyle.copyWith(color: Colors.white));
      costText.textRenderer = TextPaint(style: costStyle.copyWith(color: Colors.lightBlueAccent));
      descriptionText.textRenderer = TextPaint(style: descStyle.copyWith(color: Colors.white70));
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    game.setFocusedCard(null); // On enlève le focus systématiquement
    
    if (_isHoveringCancelZone) {
      _returnToHand();
      game.highlightEnemy(null);
      return;
    }

    EnemyCard? targetedEnemy;
    if (card.data.target == CardTarget.singleEnemy) {
       targetedEnemy = game.highlightedEnemy;
    }

    bool played = game.tryPlayCard(this, targetedEnemy);

    if (!played) {
      _returnToHand();
    }
    
    game.highlightEnemy(null);
  }
  
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    isDragging = false;
    game.setFocusedCard(null);
    _returnToHand();
    game.highlightEnemy(null);
  }

  EnemyCard? _findHoveredEnemy(Vector2 canvasPos) {
    for (var enemy in game.enemyCards) {
      if (enemy.containsPoint(canvasPos)) {
        return enemy;
      }
    }
    return null;
  }

  void _returnToHand() {
    _isHoveringCancelZone = false;
    
    // Reset visual state
    backgroundPaint.color = const Color(0xFF2A2A3D);
    borderPaint.color = Colors.blueAccent;
    nameText.textRenderer = TextPaint(style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold));
    costText.textRenderer = TextPaint(style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 24, fontWeight: FontWeight.bold));
    descriptionText.textRenderer = TextPaint(style: const TextStyle(color: Colors.white70, fontSize: 14));

    removeAll(children.whereType<Effect>());

    add(
      MoveEffect.to(
        originalPosition,
        EffectController(duration: 0.2, curve: Curves.easeOut),
      ),
    );
    add(
      RotateEffect.to(
        originalAngle,
        EffectController(duration: 0.2, curve: Curves.easeOut),
      ),
    );
    add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.2, curve: Curves.easeOut),
      ),
    );
    
    priority = basePriority;
  }
}
