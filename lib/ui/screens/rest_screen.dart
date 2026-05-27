import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../widgets/ui_card.dart';

class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  bool _actionTaken = false;

  void _heal() {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
    final runController = ref.read(runProvider.notifier);
    final maxHp = runController.currentState.heroStats.maxPv;
    final healAmount = (maxHp * 0.3).round();
    
    runController.heal(healAmount);
    
    setState(() {
      _actionTaken = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFr
              ? 'Repos terminé. Vous avez récupéré $healAmount PV.'
              : 'Rest complete. You recovered $healAmount HP.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _upgradeCard() async {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
    final selectedCard = await _showCardSelector(
      title: isFr ? 'FORGER UNE CARTE' : 'FORGE A CARD',
      subtitle: isFr
          ? 'Choisissez une carte à améliorer définitivement.'
          : 'Choose a card to permanently upgrade.',
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).upgradeCard(selectedCard.uniqueId);
      
      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = selectedCard.data.getName(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr
                  ? '$cardName a été améliorée au Niveau ${selectedCard.level + 1} !'
                  : '$cardName was upgraded to Level ${selectedCard.level + 1}!',
            ),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  void _removeCard() async {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
    final selectedCard = await _showCardSelector(
      title: isFr ? 'OUBLIER UNE CARTE' : 'REMOVE A CARD',
      subtitle: isFr
          ? 'Choisissez une carte à retirer définitivement de votre deck.'
          : 'Choose a card to permanently remove from your deck.',
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).removeCardById(selectedCard.uniqueId);
      
      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = selectedCard.data.getName(locale);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFr
                  ? '$cardName a été retirée du deck.'
                  : '$cardName was removed from your deck.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<CardInstance?> _showCardSelector({required String title, required String subtitle}) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';
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
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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
                            rarity: isFr ? 'Niveau ${card.level}' : 'Level ${card.level}',
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
    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;
    final locale = Localizations.localeOf(context).languageCode;
    final isFr = locale == 'fr';

    return Scaffold(
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
                  isFr ? 'ZONE DE REPOS' : 'REST CAMP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isFr
                      ? 'Le crépitement du feu vous apaise...'
                      : 'The crackling fire calms you...',
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
                    title: isFr ? 'SE REPOSER' : 'REST',
                    description: isFr
                        ? 'Restaure 30% des PV Max (${(heroStats.maxPv * 0.3).round()} PV)'
                        : 'Restores 30% of Max HP (${(heroStats.maxPv * 0.3).round()} HP)',
                    onTap: _heal,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 20),
                  _RestOption(
                    icon: Icons.auto_fix_high,
                    title: isFr ? 'FORGER' : 'FORGE',
                    description: isFr
                        ? 'Améliore définitivement une carte de votre deck.'
                        : 'Permanently upgrade a card in your deck.',
                    onTap: _upgradeCard,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 20),
                  _RestOption(
                    icon: Icons.delete_sweep,
                    title: isFr ? 'OUBLIER' : 'REMOVE',
                    description: isFr
                        ? 'Retire définitivement une carte de votre deck.'
                        : 'Permanently remove a card from your deck.',
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
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    ),
                    onPressed: _leave,
                    child: Text(
                      isFr ? 'CONTINUER LA ROUTE' : 'PROCEED ONWARD',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
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
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
