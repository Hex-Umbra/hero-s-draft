import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
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
  /// Une action par visite (D14 ; spec P-43 E2, A4) : le repos, l'affûtage
  /// ou l'oubli fait, les trois options disparaissent. Un état de déroulé de
  /// l'écran, qui ne lui survit pas : toute sortie après une action résout
  /// le nœud (`_leave`).
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

  void _sharpenRune() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final result = await Navigator.of(context).push<(CardInstance, String)>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampSharpenTitle,
          subtitle: l10n.restCampSharpenSubtitle,
          isSharpen: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final (card, runeId) = result;
    setState(() {
      _actionTaken = true;
    });
    // `card` est la carte d'avant l'affûtage : la rune y porte un niveau de
    // moins que ce que `sharpenRune` vient d'écrire.
    final level =
        (ForgeUpgradeData.levelsOf(card.forgeUpgrades)[runeId] ?? 0) + 1;
    context.showNotification(
      l10n.restCampSnackbarSharpen(
        ForgeUpgradeData.getById(runeId)?.getName(locale) ?? runeId,
        level,
        card.data.getName(locale),
      ),
      type: NotificationType.success,
    );
  }

  void _removeCard() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final selectedCard = await Navigator.of(context).push<CardInstance>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampRemoveTitle,
          subtitle: l10n.restCampRemoveSubtitle,
          isSharpen: false,
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
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;
    // L'option d'affûtage se montre inactive, avec son motif, quand aucune
    // rune du deck ne peut monter (spec P-43 E2, A4) sous le plafond effectif
    // de la run (spec P-43 E3, A17).
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final canSharpen = ref.watch(deckProvider).masterDeck.any(
          (card) => ForgeRuneRules.hasSharpenableRune(
            card,
            catalog,
            capBonus: runState.runeCapBonus,
          ),
        );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      // Le retour système n'est jamais un pop direct (spec P-43 E2, A4) :
      // avant toute action il reste bloqué ; après, il résout le nœud par le
      // chemin de « Continuer ». Le pop de `_leave` repasse ici avec `didPop`
      // vrai : rien à refaire.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _actionTaken) _leave();
      },
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
                title: l10n.restCampSharpen,
                description: canSharpen
                    ? l10n.restCampSharpenDesc
                    : l10n.restCampSharpenNone,
                onTap: canSharpen ? _sharpenRune : null,
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

  /// `null` : l'option est inactive — grisée, sans effet au toucher ; sa
  /// description dit pourquoi.
  final VoidCallback? onTap;
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
    final enabled = widget.onTap != null;
    final color = enabled ? widget.color : Colors.grey;
    final hovered = enabled && _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 320,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hovered
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hovered ? color : color.withAlpha(100),
                  width: 2,
                ),
                boxShadow: [
                  if (hovered)
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: color, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: color,
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
