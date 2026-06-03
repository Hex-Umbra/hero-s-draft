class HeroData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String iconPath;
  final int maxHp;
  final int maxMana;
  final int baseDamage;
  final int luck;
  final int armorMastery;
  final String? passiveTrait;
  final List<String> skills;

  const HeroData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.iconPath,
    required this.maxHp,
    required this.maxMana,
    required this.baseDamage,
    this.luck = 0,
    this.armorMastery = 0,
    this.passiveTrait,
    this.skills = const [],
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;
  String getDescription(String locale) =>
      locale == 'fr' ? descriptionFr : descriptionEn;

  factory HeroData.fromJson(Map<String, dynamic> json) {
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

    return HeroData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      descriptionEn: dEn,
      descriptionFr: dFr,
      iconPath: json['iconPath'] as String,
      maxHp: json['maxHp'] as int,
      maxMana: json['maxMana'] as int,
      baseDamage: json['baseDamage'] as int,
      luck: json['luck'] as int? ?? 0,
      armorMastery: json['armorMastery'] as int? ?? 0,
      passiveTrait: json['passiveTrait'] as String?,
      skills: (json['skills'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}
