import 'package:uuid/uuid.dart';
import 'data/card_data.dart';

class CardInstance {
  final String uniqueId;
  final CardData data;
  int level;
  int? temporaryCost;

  CardInstance({
    String? uniqueId,
    required this.data,
    this.level = 1,
    this.temporaryCost,
  }) : uniqueId = uniqueId ?? const Uuid().v4();

  int get currentCost => temporaryCost ?? data.cost;

  CardInstance copyWith({
    String? uniqueId,
    CardData? data,
    int? level,
    int? temporaryCost,
  }) {
    return CardInstance(
      uniqueId: uniqueId ?? this.uniqueId,
      data: data ?? this.data,
      level: level ?? this.level,
      temporaryCost: temporaryCost ?? this.temporaryCost,
    );
  }
}
