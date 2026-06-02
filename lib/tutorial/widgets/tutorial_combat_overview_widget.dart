import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialCombatOverviewWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialCombatOverviewWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialCombatOverviewWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
