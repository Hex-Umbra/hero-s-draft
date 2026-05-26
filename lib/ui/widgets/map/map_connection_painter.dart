import 'dart:ui' as ui;
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
    final double phase = animation.value * (dashLength + dashSpace) * 2;

    for (var node in nodes) {
      for (var targetId in node.connections) {
        try {
          final targetNode = nodes.firstWhere((n) => n.id == targetId);
          final bool isHighlighted =
              highlightedConnections.contains((node.id, targetId));
          final paint = isHighlighted ? paintHighlight : paintBase;

          final Path path = Path()
            ..moveTo(node.position.x, node.position.y + 80.0)
            ..lineTo(targetNode.position.x, targetNode.position.y + 80.0);

          for (final ui.PathMetric metric in path.computeMetrics()) {
            double distance = phase - (dashLength + dashSpace) * 2;
            bool draw = true;
            while (distance < metric.length) {
              final double len = draw ? dashLength : dashSpace;
              if (draw) {
                final double start = distance < 0 ? 0 : distance;
                final double end = (distance + len > metric.length)
                    ? metric.length
                    : distance + len;
                if (start < end) {
                  canvas.drawPath(metric.extractPath(start, end), paint);
                }
              }
              distance += len;
              draw = !draw;
            }
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
