import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/notification_overlay.dart';
import 'game/controllers/checkpoint_controller.dart';
import 'services/audio/audio_providers.dart';
import 'services/audio/flame_audio_backend.dart';

import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [audioBackendProvider.overrideWithValue(FlameAudioBackend())],
      child: const HerosDraftApp(),
    ),
  );
}

class HerosDraftApp extends ConsumerWidget {
  const HerosDraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force l'activation de l'écoute d'autosave dès le démarrage de l'app.
    ref.watch(autosaveOrchestratorProvider);
    // Hydrate les reglages audio persistes (volumes, coupure) une seule fois.
    ref.watch(audioSettingsHydrationProvider);
    // Reveille le systeme audio des le lancement. Les deux providers sont
    // paresseux : sans cela, ils n'existaient qu'au premier son demande, et
    // ce son-la arrivait donc avant la fin de son propre prechargement — il
    // etait abandonne. Le premier clic de menu etait muet. `watch` et non
    // `read` : les deux sont recrees quand le catalogue JSON acheve de
    // charger, et leur prechargement repart alors tout seul.
    ref.watch(audioDirectorProvider);
    ref.watch(musicConductorProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.darkNeonTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      home: const SplashScreen(),
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => ref.read(musicConductorProvider).unlock(),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const GameNotificationOverlay(),
            ],
          ),
        );
      },
    );
  }
}
