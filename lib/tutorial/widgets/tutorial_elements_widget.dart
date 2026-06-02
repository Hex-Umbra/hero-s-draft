import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialElementsWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialElementsWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialElementsWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
