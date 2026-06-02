import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialXpWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialXpWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialXpWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
