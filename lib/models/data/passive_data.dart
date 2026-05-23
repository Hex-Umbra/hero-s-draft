import 'relic_data.dart';

class PassiveData {
  final String id;
  final String name;
  final String description;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_armor', 'berserker_armor', 'spell_armor'
  final int value;

  const PassiveData({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.effectType,
    required this.value,
  });

  factory PassiveData.fromJson(Map<String, dynamic> json) {
    return PassiveData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      trigger: RelicTrigger.values.firstWhere((e) => e.name == json['trigger']),
      effectType: json['effectType'] as String,
      value: json['value'] as int,
    );
  }

  static PassiveData fallback(String id) {
    switch (id) {
      case 'regenArmor':
        return const PassiveData(
          id: 'regenArmor',
          name: 'Régénération d\'Armure',
          description: 'Gagne 2 points d\'Armure (+ Maîtrise) automatiquement à la fin de chaque tour.',
          trigger: RelicTrigger.endOfTurn,
          effectType: 'gain_armor',
          value: 2,
        );
      case 'berserkerArmor':
        return const PassiveData(
          id: 'berserkerArmor',
          name: 'Armure du Berserker',
          description: 'Gagne 1 point d\'Armure (+ Maîtrise) au début du tour pour chaque tranche de 10 PV manquants.',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'berserker_armor',
          value: 1,
        );
      case 'spellArmor':
        return const PassiveData(
          id: 'spellArmor',
          name: 'Armure Magique',
          description: 'Gagne 1 point d\'Armure (+ Maîtrise) instantanément chaque fois que vous jouez une carte Compétence.',
          trigger: RelicTrigger.onCardPlayed,
          effectType: 'spell_armor',
          value: 1,
        );
      default:
        return const PassiveData(
          id: 'none',
          name: 'Aucun',
          description: '',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'none',
          value: 0,
        );
    }
  }
}
