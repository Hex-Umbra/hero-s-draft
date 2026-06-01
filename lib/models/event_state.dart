import 'data/event_data.dart';

class EventState {
  final EventData? activeEvent;
  final EventChoice? selectedChoice;
  final bool isResolved;

  const EventState({
    this.activeEvent,
    this.selectedChoice,
    this.isResolved = false,
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
    );
  }
}
