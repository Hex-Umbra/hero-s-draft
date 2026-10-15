import '../../services/audio/audio_source.dart';
import 'card_data.dart';

/// Une signature de classe : une compétence à recharge, qui n'entre jamais
/// dans le deck (spec P-43 E4, §3.1).
///
/// Ce n'est pas une carte : sans rareté, sans épuisement, sans catégorie. Le
/// chargeur injecte [heroClass] depuis le dossier de la classe.
class SignatureData implements AudioSource {
  /// Les types qu'une signature peut avoir : `status` n'est pas jouable.
  static const Set<CardType> playableTypes = {
    CardType.attack,
    CardType.skill,
    CardType.power,
  };

  final String id;
  final String heroClass;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final int cost;

  /// Le nombre de tours de recharge après usage, au moins 1 (D54).
  final int cooldown;
  final CardType type;
  final CardTarget target;
  @override
  final String? animation;
  @override
  final String? sfx;
  final List<CardEffect> effects;

  const SignatureData({
    required this.id,
    required this.heroClass,
    this.nameEn = '',
    this.nameFr = '',
    this.descriptionEn = '',
    this.descriptionFr = '',
    required this.cost,
    required this.cooldown,
    required this.type,
    this.target = CardTarget.singleEnemy,
    this.animation,
    this.sfx,
    required this.effects,
  });

  String getName(String locale) => locale == 'fr' ? nameFr : nameEn;

  /// Ces clés appartiennent à une carte : les accepter silencieusement serait
  /// promettre un comportement que le moteur ne tient pas (spec A11).
  static const _forbiddenKeys = ['rarity', 'isExhaust', 'category'];

  factory SignatureData.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Signature: "id" absent ou vide');
    }
    FormatException fault(String key, String why) =>
        FormatException('Signature "$id": "$key" $why');

    for (final key in _forbiddenKeys) {
      if (json.containsKey(key)) {
        throw fault(key, 'est interdit sur une signature');
      }
    }

    String text(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw fault(key, 'doit etre une chaine non vide');
      }
      return value;
    }

    int integer(String key, int min) {
      final value = json[key];
      if (value is! int || value < min) {
        throw fault(key, 'doit etre un entier >= $min');
      }
      return value;
    }

    final heroClass = text('heroClass');
    final nameEn = text('name_en');
    final nameFr = text('name_fr');
    final descriptionEn = text('description_en');
    final descriptionFr = text('description_fr');
    final cost = integer('cost', 0);
    final cooldown = integer('cooldown', 1);

    final type = SignatureData.playableTypes
        .where((t) => t.name == json['type'])
        .firstOrNull;
    if (type == null) {
      throw fault('type', 'doit etre attack, skill ou power');
    }

    final rawEffects = json['effects'];
    if (rawEffects is! List || rawEffects.isEmpty) {
      throw fault('effects', 'doit etre une liste non vide');
    }

    return SignatureData(
      id: id,
      heroClass: heroClass,
      nameEn: nameEn,
      nameFr: nameFr,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
      cost: cost,
      cooldown: cooldown,
      type: type,
      target: CardTarget.values.firstWhere(
        (e) => e.name == json['target'],
        orElse: () => CardTarget.singleEnemy,
      ),
      animation: json['animation'] as String?,
      sfx: json['sfx'] as String?,
      effects: rawEffects
          .map((e) => CardEffect.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
