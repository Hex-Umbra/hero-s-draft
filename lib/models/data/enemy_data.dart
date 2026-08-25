import '../../services/audio/audio_source.dart';
import '../enemy_intent.dart';

class EnemyData implements AudioSource {
  final String id;
  final String nameEn;
  final String nameFr;
  final int maxHp;
  final int baseDamage;
  final String spritePath;
  final int tier;
  final int xp;
  final int critChance;
  final int gold;
  final List<EnemyIntent>? intents;
  @override
  final String? sfx; // Identifiant de son propre a l'ennemi (voir audio.json)

  @override
  String? get animation => null;

  const EnemyData({
    required this.id,
    this.nameEn = '',
    this.nameFr = '',
    required this.maxHp,
    required this.baseDamage,
    required this.spritePath,
    this.tier = 1,
    this.xp = 20,
    this.critChance = 0,
    this.gold = 10,
    this.intents,
    this.sfx,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  factory EnemyData.fromJson(Map<String, dynamic> json) {
    var intentsJson = json['intents'] as List?;
    List<EnemyIntent>? parsedIntents;
    if (intentsJson != null) {
      parsedIntents = intentsJson.map((e) => EnemyIntent.fromJson(e)).toList();
    }

    final nEn = json['name_en'] as String? ?? json['name'] as String? ?? '';
    final nFr = json['name_fr'] as String? ?? json['name'] as String? ?? '';

    return EnemyData(
      id: json['id'] as String,
      nameEn: nEn,
      nameFr: nFr,
      maxHp: json['maxHp'] as int,
      baseDamage: json['baseDamage'] as int,
      spritePath: json['spritePath'] as String,
      tier: json['tier'] as int? ?? 1,
      xp: json['xp'] as int? ?? 20,
      critChance: json['critChance'] as int? ?? 0,
      gold: json['gold'] as int? ?? 10,
      intents: parsedIntents,
      sfx: json['sfx'] as String?,
    );
  }
}
