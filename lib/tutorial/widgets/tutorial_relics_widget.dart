import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialRelicsWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialRelicsWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialRelicsWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
