import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialMapNode {
  final Offset position;
  final String nameEn;
  final String nameFr;
  final String descEn;
  final String descFr;
  final IconData icon;
  final Color color;

  const TutorialMapNode({
    required this.position,
    required this.nameEn,
    required this.nameFr,
    required this.descEn,
    required this.descFr,
    required this.icon,
    required this.color,
  });
}

class TutorialMapWidget extends StatefulWidget {
  final TutorialEngine engine;
  const TutorialMapWidget({super.key, required this.engine});

  @override
  State<TutorialMapWidget> createState() => _TutorialMapWidgetState();
}

class _TutorialMapWidgetState extends State<TutorialMapWidget> {
  TutorialMapNode? _selectedNode;

  static const List<TutorialMapNode> _nodes = [
    TutorialMapNode(
      position: Offset(160, 220),
      nameEn: 'Combat Encounter',
      nameFr: 'Rencontre de Combat',
      descEn: 'Fight base monsters to gain XP and gold.',
      descFr:
          'Affrontez des monstres de base pour gagner de l\'XP et de l\'or.',
      icon: Icons.flash_on,
      color: Colors.white70,
    ),
    TutorialMapNode(
      position: Offset(80, 130),
      nameEn: 'Shop',
      nameFr: 'Boutique',
      descEn: 'Buy new cards, remove cards, or purchase relics.',
      descFr:
          'Achetez de nouvelles cartes, retirez-en ou procurez-vous des reliques.',
      icon: Icons.shopping_cart_outlined,
      color: Colors.amber,
    ),
    TutorialMapNode(
      position: Offset(240, 130),
      nameEn: 'Rest Site',
      nameFr: 'Zone de Repos',
      descEn: 'Heal your HP or forge cards to upgrade them.',
      descFr: 'Soignez vos PV ou forgez des cartes pour les améliorer.',
      icon: Icons.nightlight_round,
      color: Colors.greenAccent,
    ),
    TutorialMapNode(
      position: Offset(160, 40),
      nameEn: 'Elite Combat',
      nameFr: 'Combat Élite',
      descEn: 'Defeat strong foes to claim powerful Relics.',
      descFr:
          'Battez des ennemis redoutables pour obtenir de puissantes Reliques.',
      icon: Icons.warning_amber_rounded,
      color: Colors.redAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 260,
          child: Stack(
            children: [
              // Starry/grid space background simulation
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _selectedNode = null;
                    });
                  },
                  child: CustomPaint(painter: StarryGridPainter()),
                ),
              ),

              // Custom painter for node connections
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: MapConnectionsPainter()),
                ),
              ),

              // Map Nodes
              ..._nodes.map((node) {
                final isSelected = _selectedNode == node;
                return Positioned(
                  left: node.position.dx - 25,
                  top: node.position.dy - 25,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedNode = isSelected ? null : node;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2A2A40)
                            : const Color(0xFF131A2D),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.yellow : node.color,
                          width: isSelected ? 3.5 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isSelected ? Colors.yellow : node.color)
                                .withOpacity(0.3),
                            blurRadius: isSelected ? 12 : 6,
                            spreadRadius: isSelected ? 3 : 1,
                          ),
                        ],
                      ),
                      child: Icon(node.icon, color: node.color, size: 26),
                    ),
                  ),
                );
              }),

              // Instruction Tip
              if (_selectedNode == null)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFrench
                              ? '💡 Touchez un nœud pour voir l\'effet'
                              : '💡 Tap a node to inspect its effect',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),

              // Glassmorphic Tooltip Panel
              Positioned(
                left: 16,
                right: 16,
                top: (_selectedNode != null && _selectedNode!.position.dy > 150)
                    ? 16
                    : null,
                bottom: (_selectedNode == null || _selectedNode!.position.dy <= 150)
                    ? 16
                    : null,
                child: IgnorePointer(
                  ignoring: true,
                  child: AnimatedOpacity(
                    opacity: _selectedNode != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _selectedNode == null
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B).withOpacity(0.95),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedNode!.color.withOpacity(0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _selectedNode!.icon,
                                      color: _selectedNode!.color,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFrench
                                          ? _selectedNode!.nameFr
                                          : _selectedNode!.nameEn,
                                      style: TextStyle(
                                        color: _selectedNode!.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isFrench
                                      ? _selectedNode!.descFr
                                      : _selectedNode!.descEn,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MapConnectionsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF64748B).withOpacity(0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const combat = Offset(160, 220);
    const shop = Offset(80, 130);
    const rest = Offset(240, 130);
    const elite = Offset(160, 40);

    // Draw connection path
    _drawDashedLine(canvas, combat, shop, pathPaint);
    _drawDashedLine(canvas, combat, rest, pathPaint);
    _drawDashedLine(canvas, shop, elite, pathPaint);
    _drawDashedLine(canvas, rest, elite, pathPaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5;
    const double dashSpace = 4;
    double distance = (p2 - p1).distance;
    int dashCount = (distance / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      double startPercent = (i * (dashWidth + dashSpace)) / distance;
      double endPercent = (startPercent + (dashWidth / distance)).clamp(
        0.0,
        1.0,
      );
      canvas.drawLine(
        Offset.lerp(p1, p2, startPercent)!,
        Offset.lerp(p1, p2, endPercent)!,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarryGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid lines (very subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withOpacity(0.2)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw some random small stars
    final starPaint = Paint()..color = Colors.white.withOpacity(0.3);
    final points = [
      const Offset(40, 60),
      const Offset(280, 80),
      const Offset(60, 240),
      const Offset(290, 210),
      const Offset(110, 160),
      const Offset(210, 100),
    ];
    for (final pt in points) {
      canvas.drawCircle(pt, 1.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
