import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart' hide Image;
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../heros_draft_game.dart';
import 'entities/enemy_card.dart';

class CardComponent extends PositionComponent with DragCallbacks, TapCallbacks, HasGameReference<HerosDraftGame> {
  final CardInstance card;
  // ...
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
  
  bool isDragging = false;
  
  // Paramètres visuels
  static const double cardWidth = 100;
  static const double cardHeight = 140;

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
  Future<void> onLoad() async {
    // Nom de la carte
    nameText = TextComponent(
      text: card.data.name,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      position: Vector2(size.x / 2, 10),
      anchor: Anchor.topCenter,
    );
    add(nameText);

    // Coût en mana
    costText = TextComponent(
      text: '${card.currentCost}',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      position: Vector2(10, 10),
    );
    add(costText);

    // Description (simplifiée pour l'instant)
    descriptionText = TextComponent(
      text: _buildDescription(),
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      position: Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
      size: Vector2(size.x - 20, size.y / 2),
    );
    add(descriptionText);
    
    // TODO: Ajouter spritePath si on a des images
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
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    isDragging = true;
    priority = 100; // Mettre la carte au premier plan
    
    // Sauvegarde la position d'origine (calculée par le fan layout)
    originalPosition = position.clone();
    originalAngle = angle;
    
    // La carte se remet droite
    angle = 0;
    scale = Vector2.all(1.2); // S'agrandit
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.localDelta;
    
    // Gestion du ciblage (Arrow)
    if (card.data.target == CardTarget.singleEnemy) {
      EnemyCard? hoveredEnemy = _findHoveredEnemy(position);
      game.highlightEnemy(hoveredEnemy);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    isDragging = false;
    
    EnemyCard? targetedEnemy;
    if (card.data.target == CardTarget.singleEnemy) {
       targetedEnemy = game.highlightedEnemy;
    }

    bool played = game.tryPlayCard(this, targetedEnemy);

    if (!played) {
      // Retour à la main
      _returnToHand();
    }
    
    game.highlightEnemy(null);
  }
  
  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    isDragging = false;
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
    // Animation de retour
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
    
    priority = 10;
  }
}
