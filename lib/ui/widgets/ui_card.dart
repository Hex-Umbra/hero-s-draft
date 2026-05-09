import 'package:flutter/material.dart';

class UiCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const UiCard({
    super.key,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 70 / 110,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            border: Border.all(color: Colors.amber, width: 1.0),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title, 
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, height: 1.0), 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        description, 
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, height: 1.1), 
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
