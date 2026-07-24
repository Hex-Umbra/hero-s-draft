import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/notification_overlay.dart';
import 'game/controllers/checkpoint_controller.dart';

import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HerosDraftApp()));
}

class HerosDraftApp extends ConsumerWidget {
  const HerosDraftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Force l'activation de l'écoute d'autosave dès le démarrage de l'app.
    ref.watch(autosaveOrchestratorProvider);

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
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GameNotificationOverlay(),
          ],
        );
      },
    );
  }
}
