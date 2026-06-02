import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialMapWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialMapWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialMapWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
