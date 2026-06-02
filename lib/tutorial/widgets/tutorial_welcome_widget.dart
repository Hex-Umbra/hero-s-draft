import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialWelcomeWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialWelcomeWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialWelcomeWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
