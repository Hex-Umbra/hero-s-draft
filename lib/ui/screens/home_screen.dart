import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'class_selection_screen.dart';
import 'card_dictionary_screen.dart';
import '../../tutorial/tutorial_screen.dart';
import '../../tutorial/tutorial_progress_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "HERO'S DRAFT",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Roguelike Deckbuilder MVP",
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                backgroundColor: Colors.blueAccent,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ClassSelectionScreen(),
                  ),
                );
              },
              child: const Text('JOUER', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
            FutureBuilder<bool>(
              future: TutorialProgressService.hasCompletedTutorial(),
              builder: (context, snapshot) {
                final isCompleted = snapshot.data ?? false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        side: const BorderSide(color: Colors.white70, width: 2),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TutorialScreen(),
                          ),
                        );
                        // Refresh the UI to update the 'NEW' badge state
                        setState(() {});
                      },
                      child: const Text(
                        'TUTORIEL',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                    if (!isCompleted)
                      Positioned(
                        right: -10,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
                side: const BorderSide(color: Colors.white70, width: 2),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CardDictionaryScreen(),
                  ),
                );
              },
              child: const Text(
                'DICTIONNAIRE',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

