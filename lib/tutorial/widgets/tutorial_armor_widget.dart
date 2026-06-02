import 'package:flutter/material.dart';
import '../tutorial_engine.dart';

class TutorialArmorWidget extends StatelessWidget {
  final TutorialEngine engine;
  const TutorialArmorWidget({super.key, required this.engine});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'TutorialArmorWidget Placeholder',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
