import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/map_node.dart';

class MapConnectionPainter extends CustomPainter {
  final List<MapNode> nodes;
  final Animation<double> animation;
  final Set<(String, String)> highlightedConnections;
  final bool isParchmentMode;

  MapConnectionPainter({
    required this.nodes,
    required this.animation,
    this.highlightedConnections = const {},
    this.isParchmentMode = false,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBase = Paint()
      ..color = isParchmentMode
          ? const Color(0xFF4A3728).withAlpha(80) // Brun encre dilué
          : Colors.white.withAlpha(60)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintHighlight = Paint()
      ..color = isParchmentMode
          ? const Color(0xFF8B4513) // Brun sienne pour la surbrillance
          : Colors.blueAccent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final double dashLength = 12.0;
    final double dashSpace = 8.0;
    final double totalDash = dashLength + dashSpace;
    final double phase = animation.value * totalDash * 2;

    for (var node in nodes) {
      for (var targetId in node.connections) {
        try {
          final targetNode = nodes.firstWhere((n) => n.id == targetId);
          final bool isHighlighted = highlightedConnections.contains((
            node.id,
            targetId,
          ));
          final paint = isHighlighted ? paintHighlight : paintBase;

          final Offset A = Offset(node.position.x, node.position.y + 80.0);
          final Offset B = Offset(
            targetNode.position.x,
            targetNode.position.y + 80.0,
          );

          final double dx = B.dx - A.dx;
          final double dy = B.dy - A.dy;
          final double L = sqrt(dx * dx + dy * dy);
          if (L == 0) continue;

          final double ux = dx / L;
          final double uy = dy / L;

          // Clamped math-based dashes to prevent WASM path allocation heap leak
          double currentDist = (phase % totalDash) - totalDash;
          while (currentDist < L) {
            final double start = currentDist.clamp(0.0, L);
            final double end = (currentDist + dashLength).clamp(0.0, L);

            if (start < end) {
              canvas.drawLine(
                Offset(A.dx + ux * start, A.dy + uy * start),
                Offset(A.dx + ux * end, A.dy + uy * end),
                paint,
              );
            }
            currentDist += totalDash;
          }
        } catch (e) {
          // Ignorer si la cible n'existe pas
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapConnectionPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.animation != animation ||
      oldDelegate.highlightedConnections != highlightedConnections;
}
