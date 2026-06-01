import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';

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
    final selectedCard = await _showCardSelector(
      title: l10n.restCampForgeTitle,
      subtitle: l10n.restCampForgeSubtitle,
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).upgradeCard(selectedCard.uniqueId);

      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = selectedCard.data.getName(locale);
        context.showNotification(
          l10n.restCampSnackbarForge(cardName, selectedCard.level + 1),
          type: NotificationType.warning,
        );
      }
    }
  }

  void _removeCard() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final selectedCard = await _showCardSelector(
      title: l10n.restCampRemoveTitle,
      subtitle: l10n.restCampRemoveSubtitle,
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

  Future<CardInstance?> _showCardSelector({
    required String title,
    required String subtitle,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return showModalBottomSheet<CardInstance>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2C),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const Divider(color: Colors.white24, height: 32),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final deck = ref.watch(deckProvider).masterDeck;
                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 180,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: deck.length,
                      itemBuilder: (context, index) {
                        final card = deck[index];
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pop(card),
                          child: UiCard(
                            title: card.data.getName(locale),
                            description: card.data.getDescription(locale),
                            cost: card.data.cost,
                            level: card.level,
                            effects: card.data.effects,
                            type: card.data.type,
                            isExhaust: card.data.isExhaust,
                            rarity: l10n.levelLabel(card.level),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;

    return PopScope(
      canPop: _actionTaken,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                const Color(0xFF1A0A00).withAlpha(180), // Ambiance feu de camp
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    color: Colors.orangeAccent,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.restCampTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.restCampSubtitle,
                    style: TextStyle(
                      color: Colors.white.withAlpha(150),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 60),
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
                    const SizedBox(height: 20),
                    _RestOption(
                      icon: Icons.auto_fix_high,
                      title: l10n.restCampForge,
                      description: l10n.restCampForgeDesc,
                      onTap: _upgradeCard,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      onPressed: _leave,
                      child: Text(
                        l10n.restCampProceed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RestOption extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withAlpha(100), width: 2),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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
    );
  }
}
