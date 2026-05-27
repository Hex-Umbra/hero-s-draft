import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/event_state.dart';
import '../../models/data/event_data.dart';
import '../../models/data/relic_data.dart';
import 'run_controller.dart';
import 'inventory_controller.dart';

class EventController extends StateNotifier<EventState> {
  EventController() : super(const EventState());

  /// Sélectionne un événement aléatoire parmi la liste disponible
  void initializeEvent(List<EventData> events) {
    if (events.isEmpty) {
      state = const EventState(activeEvent: null, selectedChoice: null, isResolved: false);
      return;
    }

    final random = Random();
    final chosen = events[random.nextInt(events.length)];
    state = EventState(
      activeEvent: chosen,
      selectedChoice: null,
      isResolved: false,
    );
  }

  /// Initialise un événement spécifique (utile pour les tests unitaires)
  void setEvent(EventData event) {
    state = EventState(
      activeEvent: event,
      selectedChoice: null,
      isResolved: false,
    );
  }

  /// Gère la sélection et la résolution d'un choix d'événement
  ///
  /// Retourne la relique obtenue si le choix comprenait une action 'gain_relic', sinon null.
  RelicData? selectChoice(
    EventChoice choice,
    RunController runController,
    InventoryController inventoryController,
    List<RelicData> allRelics, {
    double? mockRoll, // Permet d'injecter un jet de dé fixe pour les tests
    int? mockRelicIndex, // Permet d'injecter l'index de sélection de relique pour les tests
  }) {
    state = state.copyWith(
      selectedChoice: choice,
      isResolved: true,
    );

    RelicData? chosenRelic;

    for (var action in choice.actions) {
      switch (action.type) {
        case 'gain_gold':
          inventoryController.gainGold(action.value as int);
          break;
        case 'spend_gold':
          inventoryController.spendGold(action.value as int);
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
          runController.applyHeroStatModifier(attackAcc: action.value as int);
          break;
        case 'gain_relic':
          if (allRelics.isNotEmpty) {
            final luck = runController.currentState.heroStats.luck;
            final double roll = mockRoll ?? (Random().nextDouble() * 100);

            final double legChance = 1.0 + luck * 0.5;
            final double epicChance = 5.0 + luck * 1.0;
            final double rareChance = 14.0 + luck * 2.0;
            final double uncommonChance = 20.0 + luck * 3.0;

            RelicRarity rarity;
            double currentRoll = roll;

            if (currentRoll < legChance) {
              rarity = RelicRarity.legendary;
            } else {
              currentRoll -= legChance;
              if (currentRoll < epicChance) {
                rarity = RelicRarity.epic;
              } else {
                currentRoll -= epicChance;
                if (currentRoll < rareChance) {
                  rarity = RelicRarity.rare;
                } else {
                  currentRoll -= rareChance;
                  if (currentRoll < uncommonChance) {
                    rarity = RelicRarity.uncommon;
                  } else {
                    rarity = RelicRarity.common;
                  }
                }
              }
            }

            var filtered = allRelics.where((r) => r.rarity == rarity).toList();
            if (filtered.isEmpty) {
              filtered = allRelics.where((r) => r.rarity == RelicRarity.common).toList();
              if (filtered.isEmpty) {
                filtered = allRelics;
              }
            }

            final rng = Random();
            final index = mockRelicIndex ?? rng.nextInt(filtered.length);
            chosenRelic = filtered[index % filtered.length];
            inventoryController.addRelic(chosenRelic);
          }
          break;
      }
    }

    return chosenRelic;
  }
}

final eventProvider = StateNotifierProvider<EventController, EventState>((ref) {
  return EventController();
});
