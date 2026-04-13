import 'package:flutter/material.dart';

class UiCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onTap;

  const UiCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF2C3E50),
          border: Border.all(color: Colors.amber, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(128), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Text(description, style: const TextStyle(color: Colors.amberAccent, fontSize: 14), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
