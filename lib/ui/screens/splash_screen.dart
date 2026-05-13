import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/game_data_service.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameData = ref.watch(gameDataLoaderProvider);

    return Scaffold(
      body: Center(
        child: gameData.when(
          data: (_) =>
              const HomeScreen(), // Si les données sont chargées, on affiche l'écran d'accueil
          loading: () =>
              const CircularProgressIndicator(), // Pendant le chargement
          error: (error, stack) =>
              Text('Erreur de chargement: $error'), // En cas d'erreur
        ),
      ),
    );
  }
}
