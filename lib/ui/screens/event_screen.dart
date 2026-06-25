import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/event_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/data/event_data.dart';
import '../../models/data/relic_data.dart';
import '../../services/game_data_service.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';

class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final gameData = ref.read(gameDataLoaderProvider).requireValue;
      ref.read(eventProvider.notifier).initializeEvent(gameData.events);
    });
  }

  void _handleChoice(EventChoice choice) {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    final chosenRelic = ref
        .read(eventProvider.notifier)
        .selectChoice(
          choice,
          gameData.relics,
        );

    if (chosenRelic != null) {
      String rarityStr = '';
      switch (chosenRelic.rarity) {
        case RelicRarity.common:
          rarityStr = 'COMMUN';
          break;
        case RelicRarity.uncommon:
          rarityStr = 'PEU COMMUN';
          break;
        case RelicRarity.rare:
          rarityStr = 'RARE';
          break;
        case RelicRarity.epic:
          rarityStr = 'ÉPIQUE';
          break;
        case RelicRarity.legendary:
          rarityStr = 'LÉGENDAIRE';
          break;
      }

      final locale = Localizations.localeOf(context).languageCode;
      context.showNotification(
        '👑 ${locale == 'fr' ? 'RELIQUE OBTENUE' : 'RELIC OBTAINED'} : ${chosenRelic.emoji} ${chosenRelic.getName(locale)} ($rarityStr)',
        type: NotificationType.success,
      );
    }
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  Widget _buildActionBadge(BuildContext context, EventAction action) {
    IconData icon;
    Color iconColor;
    Color textColor;
    Color bgColor;
    String text;

    final l10n = AppLocalizations.of(context)!;

    switch (action.type) {
      case 'gain_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.12);
        text = l10n.eventGainGold(action.value);
        break;
      case 'spend_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.12);
        text = l10n.eventSpendGold(action.value);
        break;
      case 'take_damage':
        icon = Icons.favorite_border;
        iconColor = Colors.redAccent;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.12);
        text = l10n.eventLoseHp(action.value);
        break;
      case 'heal':
        icon = Icons.favorite;
        iconColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.12);
        text = l10n.eventGainHp(action.value);
        break;
      case 'gain_max_hp':
        icon = Icons.add_box;
        iconColor = Colors.pinkAccent;
        textColor = Colors.pinkAccent;
        bgColor = Colors.pink.withValues(alpha: 0.12);
        text = l10n.eventGainMaxHp(action.value);
        break;
      case 'gain_strength':
        icon = Icons.bolt;
        iconColor = Colors.orangeAccent;
        textColor = Colors.orangeAccent;
        bgColor = Colors.orange.withValues(alpha: 0.12);
        text = l10n.eventGainAttack(action.value);
        break;
      case 'gain_relic':
        icon = Icons.auto_awesome;
        iconColor = Colors.purpleAccent;
        textColor = Colors.purpleAccent;
        bgColor = Colors.purple.withValues(alpha: 0.12);
        text = l10n.eventGainRelic;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.white54;
        textColor = Colors.white70;
        bgColor = Colors.white.withAlpha(15);
        text = '${action.type}: ${action.value}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: textColor.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEffectBadge() {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_circle_outline,
            color: Colors.white54,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            locale == 'fr' ? 'Aucun effet' : 'No effect',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionBadge(BuildContext context, EventAction action) {
    IconData icon;
    Color iconColor;
    Color textColor;
    Color bgColor;
    String text;

    final l10n = AppLocalizations.of(context)!;

    switch (action.type) {
      case 'gain_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.08);
        text = l10n.eventGainGold(action.value);
        break;
      case 'spend_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.08);
        text = l10n.eventSpendGold(action.value);
        break;
      case 'take_damage':
        icon = Icons.favorite_border;
        iconColor = Colors.redAccent;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.08);
        text = l10n.eventLoseHp(action.value);
        break;
      case 'heal':
        icon = Icons.favorite;
        iconColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.08);
        text = l10n.eventGainHp(action.value);
        break;
      case 'gain_max_hp':
        icon = Icons.add_box;
        iconColor = Colors.pinkAccent;
        textColor = Colors.pinkAccent;
        bgColor = Colors.pink.withValues(alpha: 0.08);
        text = l10n.eventGainMaxHp(action.value);
        break;
      case 'gain_strength':
        icon = Icons.bolt;
        iconColor = Colors.orangeAccent;
        textColor = Colors.orangeAccent;
        bgColor = Colors.orange.withValues(alpha: 0.08);
        text = l10n.eventGainAttack(action.value);
        break;
      case 'gain_relic':
        icon = Icons.auto_awesome;
        iconColor = Colors.purpleAccent;
        textColor = Colors.purpleAccent;
        bgColor = Colors.purple.withValues(alpha: 0.08);
        text = l10n.eventGainRelic;
        break;
      default:
        icon = Icons.help_outline;
        iconColor = Colors.white54;
        textColor = Colors.white70;
        bgColor = Colors.white.withAlpha(10);
        text = '${action.type}: ${action.value}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventState = ref.watch(eventProvider);
    final activeEvent = eventState.activeEvent;

    if (activeEvent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final locale = Localizations.localeOf(context).languageCode;
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final heroStats = runState.heroStats;
    final currentPv = heroStats.currentPv;
    final maxPv = heroStats.maxPv;
    final gold = inventoryState.gold;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      canPop: eventState.isResolved,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        child: Column(
          children: [
            // Barre de statistiques (PV & Or)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge des PV
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.redAccent.withAlpha(80),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withAlpha(15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.favorite,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$currentPv / $maxPv ${locale == 'fr' ? 'PV' : 'HP'}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de l'or
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(25),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.amber.withAlpha(80),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(15),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$gold ${locale == 'fr' ? 'Or' : 'Gold'}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.help_outline,
              color: Colors.blueAccent,
              size: 60,
            ),
            const SizedBox(height: 15),
            Text(
              activeEvent.getTitle(locale),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 25),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        !eventState.isResolved
                            ? activeEvent.getDescription(locale)
                            : eventState.selectedChoice!.getResultText(
                                locale,
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    if (eventState.isResolved &&
                        eventState.selectedChoice != null) ...[
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.flash_on,
                            color: Colors.blueAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            locale == 'fr'
                                ? "EFFETS APPLIQUÉS"
                                : "EFFECTS APPLIED",
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              eventState.selectedChoice!.actions.isEmpty
                              ? [_buildNoEffectBadge()]
                              : eventState.selectedChoice!.actions
                                    .map(
                                      (action) => _buildActionBadge(
                                        context,
                                        action,
                                      ),
                                    )
                                    .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (!eventState.isResolved)
              ...activeEvent.choices.map(
                (choice) {
                  final isSelectable = choice.isSelectable(currentPv, gold, maxPv);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EventOptionButton(
                      text: choice.getText(locale),
                      onPressed: isSelectable ? () => _handleChoice(choice) : null,
                      badges: choice.actions
                          .map((action) => _buildCompactActionBadge(context, action))
                          .toList(),
                    ),
                  );
                },
              )
            else
              _EventOptionButton(
                text: locale == 'fr' ? 'CONTINUER' : 'CONTINUE',
                onPressed: _leave,
                highlight: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _EventOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool highlight;
  final List<Widget>? badges;

  const _EventOptionButton({
    required this.text,
    this.onPressed,
    this.highlight = false,
    this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onPressed != null;

    // Détermination des couleurs selon l'état
    final Color bgColor = isEnabled
        ? (highlight ? Colors.white12 : Colors.black45)
        : Colors.black.withValues(alpha: 0.2);
    final Color borderColor = isEnabled
        ? (highlight ? Colors.blueAccent : Colors.white24)
        : Colors.white10;
    final Color textColor = isEnabled
        ? Colors.white
        : Colors.white38;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.55,
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            disabledBackgroundColor: bgColor,
            disabledForegroundColor: textColor,
            side: BorderSide(
              color: borderColor,
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isEnabled ? 4 : 0,
            shadowColor: highlight ? Colors.blueAccent.withAlpha(50) : Colors.black38,
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: highlight || isEnabled ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
              if (badges != null && badges!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: badges!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
