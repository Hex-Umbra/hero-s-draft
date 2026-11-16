import 'package:roguelike_card_game/models/data/charge_data.dart';

/// Une charge construite à la main, qui passe la validation d'`fromJson` (spec
/// P-53, A3) : seuil 3, sans croissance ni surcharge ni déclin, une rupture
/// `amplifyHits` de 2 par point qui dure. [overrides] remplace ou ajoute des
/// clés du fichier ; une valeur `null` retire la clé.
ChargeData testCharge([Map<String, dynamic> overrides = const {}]) {
  final json = <String, dynamic>{
    'id': 'test_charge',
    'name_fr': 'Charge d essai',
    'name_en': 'Test charge',
    'description_fr': 'Une charge d essai.',
    'description_en': 'A test charge.',
    'brokenName_fr': 'Rompue',
    'brokenName_en': 'Broken',
    'threshold': 3,
    'thresholdGrowth': 0,
    'overcharge': false,
    'decay': 0,
    'breaksOn': 'threshold',
    'belowThresholdPercent': 50,
    'rupture': {'kind': 'amplifyHits', 'bonusPerPoint': 2},
    ...overrides,
  }..removeWhere((_, value) => value == null);
  return ChargeData.fromJson(json);
}
