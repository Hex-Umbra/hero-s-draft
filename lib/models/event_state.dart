import 'data/event_data.dart';
import 'data/relic_data.dart';

class EventState {
  final EventData? activeEvent;
  final EventChoice? selectedChoice;
  final bool isResolved;

  /// La relique que vise l'échange de l'événement (spec P-43 E3, §4.9, A20) :
  /// tirée une fois, à l'ouverture, nommée sur les badges ; `null` si
  /// l'événement n'échange rien ou que l'inventaire est vide.
  final RelicData? tradedRelic;

  const EventState({
    this.activeEvent,
    this.selectedChoice,
    this.isResolved = false,
    this.tradedRelic,
  });

  EventState copyWith({
    EventData? activeEvent,
    EventChoice? selectedChoice,
    bool? isResolved,
    bool clearSelectedChoice = false,
  }) {
    return EventState(
      activeEvent: activeEvent ?? this.activeEvent,
      selectedChoice: clearSelectedChoice
          ? null
          : (selectedChoice ?? this.selectedChoice),
      isResolved: isResolved ?? this.isResolved,
      tradedRelic: tradedRelic,
    );
  }
}
