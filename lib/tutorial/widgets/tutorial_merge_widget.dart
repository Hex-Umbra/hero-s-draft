import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialMergeWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialMergeWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialMergeWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
