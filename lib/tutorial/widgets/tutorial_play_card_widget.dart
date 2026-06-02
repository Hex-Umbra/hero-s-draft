import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialPlayCardWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialPlayCardWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialPlayCardWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
