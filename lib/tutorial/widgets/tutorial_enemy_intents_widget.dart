import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialEnemyIntentsWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialEnemyIntentsWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialEnemyIntentsWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
