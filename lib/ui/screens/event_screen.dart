import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/run_controller.dart';
import '../../models/data/event_data.dart';
import '../../services/game_data_service.dart';
import '../../models/status_effect.dart';

class EventScreen extends ConsumerStatefulWidget {
  const EventScreen({super.key});

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  EventData? _event;
  EventChoice? _selectedChoice;
  bool _isResolved = false;

  @override
  void initState() {
    super.initState();
    _pickRandomEvent();
  }

  void _pickRandomEvent() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    if (gameData.events.isNotEmpty) {
      final random = Random();
      setState(() {
        _event = gameData.events[random.nextInt(gameData.events.length)];
      });
    }
  }

  void _handleChoice(EventChoice choice) {
    setState(() {
      _selectedChoice = choice;
      _isResolved = true;
    });

    final runController = ref.read(runProvider.notifier);

    for (var action in choice.actions) {
      switch (action.type) {
        case 'gain_gold':
          runController.gainGold(action.value as int);
          break;
        case 'spend_gold':
          runController.spendGold(action.value as int);
          break;
        case 'take_damage':
          runController.takeDamage(action.value as int);
          break;
        case 'heal':
          runController.heal(action.value as int);
          break;
        case 'gain_max_hp':
          runController.applyHeroStatModifier(maxPvAcc: action.value as int);
          break;
        case 'gain_strength':
          runController.addStatus(
            StatusEffect(
              id: 'strength',
              name: 'Force',
              type: StatusType.buff,
              value: action.value as int,
              duration: 3,
            ),
          );
          break;
        case 'gain_relic':
          // Pour l'instant on ignore ou on ajoute une relique fixe de test
          break;
      }
    }
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  Widget _buildActionBadge(EventAction action) {
    IconData icon;
    Color iconColor;
    Color textColor;
    Color bgColor;
    String text;

    switch (action.type) {
      case 'gain_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withAlpha(30);
        text = '+${action.value} Or';
        break;
      case 'spend_gold':
        icon = Icons.monetization_on;
        iconColor = Colors.amber;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withAlpha(30);
        text = '-${action.value} Or';
        break;
      case 'take_damage':
        icon = Icons.favorite_border;
        iconColor = Colors.redAccent;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withAlpha(30);
        text = '-${action.value} PV';
        break;
      case 'heal':
        icon = Icons.favorite;
        iconColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withAlpha(30);
        text = '+${action.value} PV';
        break;
      case 'gain_max_hp':
        icon = Icons.add_box;
        iconColor = Colors.pinkAccent;
        textColor = Colors.pinkAccent;
        bgColor = Colors.pink.withAlpha(30);
        text = '+${action.value} PV Max';
        break;
      case 'gain_strength':
        icon = Icons.bolt;
        iconColor = Colors.orangeAccent;
        textColor = Colors.orangeAccent;
        bgColor = Colors.orange.withAlpha(30);
        text = '+${action.value} Force';
        break;
      case 'gain_relic':
        icon = Icons.auto_awesome;
        iconColor = Colors.purpleAccent;
        textColor = Colors.purpleAccent;
        bgColor = Colors.purple.withAlpha(30);
        text = '+1 Relique';
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
        border: Border.all(
          color: textColor.withAlpha(80),
          width: 1.5,
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.remove_circle_outline, color: Colors.white54, size: 22),
          SizedBox(width: 10),
          Text(
            'Aucun effet',
            style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;
    final currentPv = heroStats.currentPv;
    final maxPv = heroStats.maxPv;
    final gold = runState.gold;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF0D1A2E).withAlpha(180),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
            child: Column(
              children: [
                // Barre de statistiques (PV & Or)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge des PV
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            '$currentPv / $maxPv PV',
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            '$gold Or',
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
                const Icon(Icons.help_outline, color: Colors.blueAccent, size: 60),
                const SizedBox(height: 15),
                Text(
                  _event!.title,
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
                            !_isResolved ? _event!.description : _selectedChoice!.resultText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (_isResolved) ...[
                          const SizedBox(height: 25),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                "EFFETS APPLIQUÉS",
                                style: TextStyle(
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
                              children: _selectedChoice!.actions.isEmpty
                                  ? [_buildNoEffectBadge()]
                                  : _selectedChoice!.actions
                                      .map((action) => _buildActionBadge(action))
                                      .toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isResolved)
                  ..._event!.choices.map((choice) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _EventOptionButton(
                          text: choice.text,
                          onPressed: () => _handleChoice(choice),
                        ),
                      ))
                else
                  _EventOptionButton(
                    text: 'CONTINUER',
                    onPressed: _leave,
                    highlight: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool highlight;

  const _EventOptionButton({
    required this.text,
    required this.onPressed,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: highlight ? Colors.white12 : Colors.black45,
          foregroundColor: Colors.white,
          side: BorderSide(
            color: highlight ? Colors.blueAccent : Colors.white24,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
