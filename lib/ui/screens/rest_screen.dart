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
    final runController = ref.read(runProvider.notifier);
    final maxHp = runController.currentState.heroStats.maxPv;
    final healAmount = (maxHp * 0.3).round();
    
    runController.heal(healAmount);
    
    setState(() {
      _actionTaken = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Repos terminé. Vous avez récupéré $healAmount PV.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _upgradeCard() async {
    final selectedCard = await _showCardSelector(
      title: 'FORGER UNE CARTE',
      subtitle: 'Choisissez une carte à améliorer définitivement.',
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).upgradeCard(selectedCard.uniqueId);
      
      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedCard.data.name} a été améliorée au Niveau ${selectedCard.level + 1} !'),
            backgroundColor: Colors.amber,
          ),
        );
      }
    }
  }

  void _removeCard() async {
    final selectedCard = await _showCardSelector(
      title: 'OUBLIER UNE CARTE',
      subtitle: 'Choisissez une carte à retirer définitivement de votre deck.',
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).removeCardById(selectedCard.uniqueId);
      
      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedCard.data.name} a été retirée du deck.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<CardInstance?> _showCardSelector({required String title, required String subtitle}) {
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
                            title: card.data.name,
                            description: card.data.description,
                            cost: card.data.cost,
                            level: card.level,
                            effects: card.data.effects,
                            rarity: 'Niveau ${card.level}',
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
                const Text(
                  'ZONE DE REPOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Le crépitement du feu vous apaise...',
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
                    title: 'SE REPOSER',
                    description: 'Restaure 30% des PV Max (${(heroStats.maxPv * 0.3).round()} PV)',
                    onTap: _heal,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 20),
                  _RestOption(
                    icon: Icons.auto_fix_high,
                    title: 'FORGER',
                    description: 'Améliore définitivement une carte de votre deck.',
                    onTap: _upgradeCard,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 20),
                  _RestOption(
                    icon: Icons.delete_sweep,
                    title: 'OUBLIER',
                    description: 'Retire définitivement une carte de votre deck.',
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
                    child: const Text(
                      'CONTINUER LA ROUTE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
