import 'relic_data.dart';

class PassiveData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final RelicTrigger trigger;
  final String effectType; // ex: 'gain_armor', 'berserker_armor', 'spell_armor'
  final int value;

  const PassiveData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.trigger,
    required this.effectType,
    required this.value,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory PassiveData.fromJson(Map<String, dynamic> json) {
    final nEn = json['name_en'] as String? ?? json['name'] as String? ?? '';
    final nFr = json['name_fr'] as String? ?? json['name'] as String? ?? '';
    final dEn =
        json['description_en'] as String? ??
        json['description'] as String? ??
        '';
    final dFr =
        json['description_fr'] as String? ??
        json['description'] as String? ??
        '';

    return PassiveData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
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
          nameEn: 'Armor Regeneration',
          nameFr: "Régénération d'Armure",
          descriptionEn:
              'Gain 2 Block (+ Mastery) automatically at the end of each turn.',
          descriptionFr:
              "Gagne 2 points d'Armure (+ Maîtrise) automatiquement à la fin de chaque tour.",
          trigger: RelicTrigger.endOfTurn,
          effectType: 'gain_armor',
          value: 2,
        );
      case 'berserkerArmor':
        return const PassiveData(
          id: 'berserkerArmor',
          nameEn: 'Berserker Armor',
          nameFr: 'Armure du Berserker',
          descriptionEn:
              'Gain 1 Block (+ Mastery) at the start of your turn for every 10 missing HP.',
          descriptionFr:
              "Gagne 1 point d'Armure (+ Maîtrise) au début du tour pour chaque tranche de 10 PV manquants.",
          trigger: RelicTrigger.startOfTurn,
          effectType: 'berserker_armor',
          value: 1,
        );
      case 'spellArmor':
        return const PassiveData(
          id: 'spellArmor',
          nameEn: 'Spell Armor',
          nameFr: 'Armure Magique',
          descriptionEn:
              'Gain 1 Block (+ Mastery) instantly each time you play a Skill card.',
          descriptionFr:
              "Gagne 1 point d'Armure (+ Maîtrise) instantanément chaque fois que vous jouez une carte Compétence.",
          trigger: RelicTrigger.onCardPlayed,
          effectType: 'spell_armor',
          value: 1,
        );
      default:
        return const PassiveData(
          id: 'none',
          nameEn: 'None',
          nameFr: 'Aucun',
          descriptionEn: '',
          descriptionFr: '',
          trigger: RelicTrigger.startOfTurn,
          effectType: 'none',
          value: 0,
        );
    }
  }
}
