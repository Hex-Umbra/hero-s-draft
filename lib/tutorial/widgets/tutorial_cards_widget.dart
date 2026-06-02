import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialCardsWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialCardsWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialCardsWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
