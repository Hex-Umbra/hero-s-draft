import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialNodeTypesWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialNodeTypesWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialNodeTypesWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
