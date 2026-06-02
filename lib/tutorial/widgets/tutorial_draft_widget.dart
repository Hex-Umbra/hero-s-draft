import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialDraftWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialDraftWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialDraftWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
