class EventData {
  final String id;
  final String title;
  final String description;
  final List<EventChoice> choices;

  EventData({
    required this.id,
    required this.title,
    required this.description,
    required this.choices,
  });

  factory EventData.fromJson(Map<String, dynamic> json) {
    return EventData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      choices: (json['choices'] as List)
          .map((c) => EventChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventChoice {
  final String text;
  final String resultText;
  final List<EventAction> actions;

  EventChoice({
    required this.text,
    required this.resultText,
    required this.actions,
  });

  factory EventChoice.fromJson(Map<String, dynamic> json) {
    return EventChoice(
      text: json['text'] as String,
      resultText: json['resultText'] as String,
      actions: (json['actions'] as List)
          .map((a) => EventAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventAction {
  final String type; // gain_gold, take_damage, heal, gain_relic
  final dynamic value;

  EventAction({
    required this.type,
    required this.value,
  });

  factory EventAction.fromJson(Map<String, dynamic> json) {
    return EventAction(
      type: json['type'] as String,
      value: json['value'],
    );
  }
}
