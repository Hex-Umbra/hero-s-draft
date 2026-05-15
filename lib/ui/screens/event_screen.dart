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

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              children: [
                const Icon(Icons.help_outline, color: Colors.blueAccent, size: 60),
                const SizedBox(height: 20),
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
                const SizedBox(height: 40),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
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
