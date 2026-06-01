class EventData {
  final String id;
  final String titleEn;
  final String titleFr;
  final String descriptionEn;
  final String descriptionFr;
  final List<EventChoice> choices;

  EventData({
    required this.id,
    this.titleEn = '',
    this.titleFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.choices,
  });

  String getTitle(String locale) => locale == 'fr' ? titleFr : titleEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory EventData.fromJson(Map<String, dynamic> json) {
    final tEn = json['title_en'] as String? ?? json['title'] as String? ?? '';
    final tFr = json['title_fr'] as String? ?? json['title'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    return EventData(
      id: json['id'] as String,
      titleEn: tEn,
      titleFr: tFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      choices: (json['choices'] as List)
          .map((c) => EventChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventChoice {
  final String textEn;
  final String textFr;
  final String resultTextEn;
  final String resultTextFr;
  final List<EventAction> actions;

  EventChoice({
    this.textEn = '',
    this.textFr = '',
    this.resultTextEn = '',
    this.resultTextFr = '',
    required this.actions,
  });

  String getText(String locale) => locale == 'fr' ? textFr : textEn;
  String getResultText(String locale) =>
      locale == 'fr' ? resultTextFr : resultTextEn;

  factory EventChoice.fromJson(Map<String, dynamic> json) {
    final tEn = json['text_en'] as String? ?? json['text'] as String? ?? '';
    final tFr = json['text_fr'] as String? ?? json['text'] as String? ?? '';
    final rEn =
        json['result_text_en'] as String? ??
        json['resultText'] as String? ??
        '';
    final rFr =
        json['result_text_fr'] as String? ??
        json['resultText'] as String? ??
        '';

    return EventChoice(
      textEn: tEn,
      textFr: tFr,
      resultTextEn: rEn,
      resultTextFr: rFr,
      actions: (json['actions'] as List)
          .map((a) => EventAction.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EventAction {
  final String type; // gain_gold, take_damage, heal, gain_relic
  final dynamic value;

  EventAction({required this.type, required this.value});

  factory EventAction.fromJson(Map<String, dynamic> json) {
    return EventAction(type: json['type'] as String, value: json['value']);
  }
}
