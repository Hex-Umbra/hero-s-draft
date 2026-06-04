import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/map_node.dart';

class MapNodeWidget extends StatefulWidget {
  final MapNode node;
  final bool isAvailable;
  final bool isCurrent;
  final VoidCallback onTap;
  final Function(String, String) onShowTooltip;
  final VoidCallback onHideTooltip;
  final VoidCallback onHoverEnter;
  final VoidCallback onHoverExit;

  const MapNodeWidget({
    super.key,
    required this.node,
    required this.isAvailable,
    required this.isCurrent,
    required this.onTap,
    required this.onShowTooltip,
    required this.onHideTooltip,
    required this.onHoverEnter,
    required this.onHoverExit,
  });

  @override
  State<MapNodeWidget> createState() => _MapNodeWidgetState();
}

class _MapNodeWidgetState extends State<MapNodeWidget> {
  bool _isHovered = false;

  (String, String) _getTooltipData(AppLocalizations l10n) {
    if (widget.node.type == MapNodeType.boss && widget.node.bossEnemyId != null) {
      final isFr = Localizations.localeOf(context).languageCode == 'fr';
      if (widget.node.bossEnemyId == 'boss_card_giver') {
        return (
          isFr ? "BOSS : DÉMON" : "BOSS: DEMON",
          isFr ? "Récompense : 1 à 3 cartes au choix" : "Reward: 1 to 3 cards of choice"
        );
      } else if (widget.node.bossEnemyId == 'boss_xp_multiplier') {
        return (
          isFr ? "BOSS : DRAGON" : "BOSS: DRAGON",
          isFr ? "Récompense : XP Double" : "Reward: Double XP"
        );
      } else if (widget.node.bossEnemyId == 'boss_relic_improved') {
        return (
          isFr ? "BOSS : LICHE" : "BOSS: LICH",
          isFr ? "Récompense : Relique Améliorée" : "Reward: Improved Relic"
        );
      }
    }

    switch (widget.node.type) {
      case MapNodeType.combat:
        return (l10n.tooltipCombatTitle, l10n.tooltipCombatDesc);
      case MapNodeType.elite:
        return (l10n.tooltipEliteTitle, l10n.tooltipEliteDesc);
      case MapNodeType.shop:
        return (l10n.tooltipShopTitle, l10n.tooltipShopDesc);
      case MapNodeType.rest:
        return (l10n.tooltipRestTitle, l10n.tooltipRestDesc);
      case MapNodeType.event:
        return (l10n.tooltipEventTitle, l10n.tooltipEventDesc);
      case MapNodeType.boss:
        return (l10n.tooltipBossTitle, l10n.tooltipBossDesc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    IconData icon;
    Color color;

    switch (widget.node.type) {
      case MapNodeType.combat:
        icon = Icons.flash_on;
        color = Colors.white70;
        break;
      case MapNodeType.elite:
        icon = Icons.warning_amber_rounded;
        color = Colors.redAccent;
        break;
      case MapNodeType.shop:
        icon = Icons.shopping_cart_outlined;
        color = Colors.amber;
        break;
      case MapNodeType.rest:
        icon = Icons.nightlight_round;
        color = Colors.greenAccent;
        break;
      case MapNodeType.event:
        icon = Icons.help_outline;
        color = Colors.blueAccent;
        break;
      case MapNodeType.boss:
        // Differentiate boss icons by reward type
        if (widget.node.bossEnemyId == 'boss_card_giver') {
          icon = Icons.style; // Cards reward
          color = Colors.orangeAccent;
        } else if (widget.node.bossEnemyId == 'boss_xp_multiplier') {
          icon = Icons.auto_awesome; // XP reward
          color = Colors.cyanAccent;
        } else if (widget.node.bossEnemyId == 'boss_relic_improved') {
          icon = Icons.diamond; // Relic reward
          color = Colors.deepPurpleAccent;
        } else {
          icon = Icons.dangerous;
          color = Colors.purpleAccent;
        }
        break;
    }

    final tooltipData = _getTooltipData(l10n);

    return Positioned(
      left: widget.node.position.x - 35,
      top: widget.node.position.y - 35 + 80.0,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovered = true);
          widget.onHoverEnter();
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          widget.onHoverExit();
        },
        cursor: widget.isAvailable
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.isAvailable ? widget.onTap : null,
          onLongPressStart: (_) =>
              widget.onShowTooltip(tooltipData.$1, tooltipData.$2),
          onLongPressEnd: (_) => widget.onHideTooltip(),
          child: Column(
            children: [
              Opacity(
                opacity: widget.node.isCompleted
                    ? 0.4
                    : (widget.isAvailable ? 1.0 : 0.2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isHovered && widget.isAvailable ? 85 : 70,
                  height: _isHovered && widget.isAvailable ? 85 : 70,
                  decoration: BoxDecoration(
                    color: widget.isCurrent
                        ? const Color(0xFF2A2A40)
                        : const Color(0xFF1A1A2E),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isCurrent
                          ? Colors.yellow
                          : (_isHovered && widget.isAvailable
                                ? Colors.white
                                : (widget.isAvailable
                                      ? color
                                      : color.withAlpha(128))),
                      width: widget.isCurrent || _isHovered ? 4 : 2,
                    ),
                    boxShadow:
                        (widget.isCurrent || (_isHovered && widget.isAvailable))
                        ? [
                            BoxShadow(
                              color: (widget.isCurrent ? Colors.yellow : color)
                                  .withAlpha(128),
                              blurRadius: _isHovered ? 20 : 15,
                              spreadRadius: _isHovered ? 4 : 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    icon,
                    color: widget.isAvailable || widget.isCurrent
                        ? color
                        : color.withAlpha(128),
                    size: _isHovered && widget.isAvailable ? 42 : 35,
                  ),
                ),
              ),
              if (widget.node.isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
