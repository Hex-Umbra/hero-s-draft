import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/notification_overlay.dart';
import 'rest_card_selection_screen.dart';
import '../widgets/screen_scaffold.dart';

class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  bool _actionTaken = false;

  void _heal() {
    final l10n = AppLocalizations.of(context)!;
    final runController = ref.read(runProvider.notifier);
    final maxHp = runController.currentState.heroStats.maxPv;
    final healAmount = (maxHp * 0.3).round();

    runController.heal(healAmount);

    setState(() {
      _actionTaken = true;
    });

    context.showNotification(
      l10n.restCampSnackbarHeal(healAmount),
      type: NotificationType.success,
    );
  }

  void _upgradeCard() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampForgeTitle,
          subtitle: l10n.restCampForgeSubtitle,
          isForge: true,
        ),
      ),
    );

    final card = result?['card'] as CardInstance?;
    if (card != null) {
      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = card.data.getName(locale);
        context.showNotification(
          locale == 'fr'
              ? "$cardName a reçu l'amélioration !"
              : "$cardName was upgraded!",
          type: NotificationType.warning,
        );
      }
    }
  }

  void _removeCard() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final selectedCard = await Navigator.of(context).push<CardInstance>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampRemoveTitle,
          subtitle: l10n.restCampRemoveSubtitle,
          isForge: false,
        ),
      ),
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).removeCardById(selectedCard.uniqueId);

      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = selectedCard.data.getName(locale);
        context.showNotification(
          l10n.restCampSnackbarRemove(cardName),
          type: NotificationType.error,
        );
      }
    }
  }

  void _leave() {
    ref.read(runProvider.notifier).clearForgeSession();
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      canPop: _actionTaken,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight_round,
              color: Colors.orangeAccent,
              size: 80,
            ),
            AppSpacing.heightMd,
            Text(
              l10n.restCampTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            AppSpacing.heightSm,
            Text(
              l10n.restCampSubtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            AppSpacing.heightXxl,
            if (!_actionTaken) ...[
              _RestOption(
                icon: Icons.favorite,
                title: l10n.restCampRest,
                description: l10n.restCampRestDesc(
                  (heroStats.maxPv * 0.3).round(),
                ),
                onTap: _heal,
                color: Colors.greenAccent,
              ),
              AppSpacing.heightMd,
              _RestOption(
                icon: Icons.auto_fix_high,
                title: l10n.restCampForge,
                description: l10n.restCampForgeDesc,
                onTap: _upgradeCard,
                color: Colors.amberAccent,
              ),
              AppSpacing.heightMd,
              _RestOption(
                icon: Icons.delete_sweep,
                title: l10n.restCampRemove,
                description: l10n.restCampRemoveDesc,
                onTap: _removeCard,
                color: Colors.redAccent,
              ),
            ] else ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              AppSpacing.heightLg,
              GameButton(
                text: l10n.restCampProceed,
                onPressed: _leave,
                baseColor: Colors.white70,
                height: 54,
                width: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Color color;

  const _RestOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
  });

  @override
  State<_RestOption> createState() => _RestOptionState();
}

class _RestOptionState extends State<_RestOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 320,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.color.withValues(alpha: 0.15)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isHovered ? widget.color : widget.color.withAlpha(100),
                  width: 2,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: widget.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.heightXs,
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
