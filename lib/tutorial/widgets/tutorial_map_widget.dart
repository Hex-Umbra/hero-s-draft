import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialMapNode {
  final Offset relativePosition;
  final String nameEn;
  final String nameFr;
  final IconData icon;
  final Color color;

  const TutorialMapNode({
    required this.relativePosition,
    required this.nameEn,
    required this.nameFr,
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
      relativePosition: Offset(0.5, 0.8),
      nameEn: 'Combat Encounter',
      nameFr: 'Rencontre de Combat',
      icon: Icons.flash_on,
      color: Colors.white70,
    ),
    TutorialMapNode(
      relativePosition: Offset(0.25, 0.5),
      nameEn: 'Shop',
      nameFr: 'Boutique',
      icon: Icons.shopping_cart_outlined,
      color: Colors.amber,
    ),
    TutorialMapNode(
      relativePosition: Offset(0.75, 0.5),
      nameEn: 'Rest Site',
      nameFr: 'Zone de Repos',
      icon: Icons.nightlight_round,
      color: Colors.greenAccent,
    ),
    TutorialMapNode(
      relativePosition: Offset(0.5, 0.2),
      nameEn: 'Elite Combat',
      nameFr: 'Combat Élite',
      icon: Icons.warning_amber_rounded,
      color: Colors.redAccent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isFrench = Localizations.localeOf(context).languageCode == 'fr';

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              // Ensure we don't have negative or infinite sizing issues
              final mapWidth = width.isFinite && width > 0 ? width : 320.0;
              final mapHeight = height.isFinite && height > 0 ? height : 260.0;

              return SizedBox(
                width: mapWidth,
                height: mapHeight,
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
                        child: CustomPaint(
                          painter: MapConnectionsPainter(
                            _nodes.map((node) => Offset(
                              node.relativePosition.dx * mapWidth,
                              node.relativePosition.dy * mapHeight,
                            )).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Map Nodes
                    ...List.generate(_nodes.length, (index) {
                      final node = _nodes[index];
                      final isSelected = _selectedNode == node;
                      final nodeX = node.relativePosition.dx * mapWidth;
                      final nodeY = node.relativePosition.dy * mapHeight;

                      return Positioned(
                        left: nodeX - 25,
                        top: nodeY - 25,
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
                                      .withValues(alpha: 0.3),
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
                                    ? '💡 Touchez un nœud pour vous y engager'
                                    : '💡 Tap a node to commit to it',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Glassmorphic Tooltip Panel — libellé d'engagement, pas
                    // une description : sur la vraie carte, toucher un nœud
                    // engage le déplacement immédiatement, sans aperçu.
                    Positioned(
                      left: 16,
                      right: 16,
                      top: (_selectedNode != null && _selectedNode!.relativePosition.dy > 0.5)
                          ? 16
                          : null,
                      bottom: (_selectedNode == null || _selectedNode!.relativePosition.dy <= 0.5)
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
                                    color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _selectedNode!.color.withValues(alpha: 0.55),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
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
                                            ? 'Vous y allez.'
                                            : 'You are going there.',
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
              );
            },
          ),
        ),
        _buildFloorStructureReminder(isFrench),
      ],
    );
  }

  /// Rappel textuel sous la mini-carte : celle-ci n'illustre que 4 nœuds pour
  /// rester lisible, la vraie carte en compte dix fois plus (dix planchers).
  Widget _buildFloorStructureReminder(bool isFrench) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Text(
        isFrench
            ? '10 planchers, de 2 à 5 nœuds chacun.'
            : '10 floors, 2 to 5 nodes each.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class MapConnectionsPainter extends CustomPainter {
  final List<Offset> points;
  MapConnectionsPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (points.length < 4) return;
    final combat = points[0];
    final shop = points[1];
    final rest = points[2];
    final elite = points[3];

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
  bool shouldRepaint(covariant MapConnectionsPainter oldDelegate) =>
      oldDelegate.points != points;
}

class StarryGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw background grid lines (very subtle)
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw some random small stars relative to size
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
    final points = [
      Offset(size.width * 0.125, size.height * 0.23),
      Offset(size.width * 0.875, size.height * 0.3),
      Offset(size.width * 0.187, size.height * 0.92),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.34, size.height * 0.61),
      Offset(size.width * 0.65, size.height * 0.38),
    ];
    for (final pt in points) {
      canvas.drawCircle(pt, 1.5, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
