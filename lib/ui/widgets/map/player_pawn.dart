import 'package:flutter/material.dart';
import 'package:flame/extensions.dart' hide Matrix4;

class PlayerPawn extends StatelessWidget {
  final Vector2 position;

  const PlayerPawn({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutBack, // Petit effet de ressort lors de l'arrivée
      left: position.x - 20,
      top: position.y - 65 + 80.0, // Un peu au dessus du centre du node
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withAlpha(150),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin,
              color: Colors.blueAccent,
              size: 32,
            ),
          ),
          CustomPaint(size: const Size(10, 10), painter: PawnPointerPainter()),
        ],
      ),
    );
  }
}

class PawnPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
