import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

Matcher refusing(String key) => throwsA(
      isA<FormatException>().having((e) => e.message, 'message', contains(key)),
    );

Map<String, dynamic> minor({String id = 'zeal'}) => {
      'id': id,
      'tier': 'minor',
      'name_fr': 'Zèle',
      'name_en': 'Zeal',
      'description_fr': '+{val} dégâts',
      'description_en': '+{val} damage',
      'deltas': [
        {'type': 'flatBonus', 'effect': 'damage', 'valuePerLevel': 2},
      ],
      'icon': 'hardware_rounded',
      'color': 'redAccent',
    };

Map<String, dynamic> devastation() => {
      'id': 'devastation',
      'tier': 'major',
      'name_fr': 'Dévastation',
      'name_en': 'Devastation',
      'description_fr': "+10 dégâts, recharge allongée d'un tour",
      'description_en': '+10 damage, cooldown one turn longer',
      'deltas': [
        {'type': 'flatBonus', 'effect': 'damage', 'valuePerLevel': 10},
      ],
      'cooldown': 1,
      'excludes': ['haste'],
      'icon': 'rocket_launch_rounded',
      'color': 'yellowAccent',
    };

Map<String, dynamic> ardor() => {
      'id': 'ardor',
      'tier': 'minor',
      'name_fr': 'Ardeur',
      'name_en': 'Ardor',
      'description_fr': '+{val} % de critique',
      'description_en': '+{val}% critical chance',
      'deltas': [
        {'type': 'critBonus', 'valuePerLevel': 5},
      ],
      'icon': 'flare_rounded',
      'color': 'amber',
    };

Map<String, dynamic> haste() => {
      'id': 'haste',
      'tier': 'major',
      'name_fr': 'Célérité',
      'name_en': 'Haste',
      'description_fr': "Recharge réduite d'un tour",
      'description_en': 'Cooldown one turn shorter',
      'cooldown': -1,
      'icon': 'fast_forward_rounded',
      'color': 'tealAccent',
    };

Map<String, dynamic> signature({
  String target = 'singleEnemy',
  List<Map<String, dynamic>>? evolutions,
  String? descriptionFr,
  String? descriptionEn,
  List<Map<String, dynamic>>? effects,
}) =>
    {
      'id': 'smite',
      'heroClass': 'paladin',
      'name_en': 'Smite',
      'name_fr': 'Châtiment',
      'description_en': descriptionEn ?? 'Deal {damage} damage.',
      'description_fr': descriptionFr ?? 'Inflige {damage} dégâts.',
      'cost': 1,
      'cooldown': 2,
      'type': 'attack',
      'target': target,
      'effects': effects ??
          [
            {'type': 'damage', 'value': 6},
          ],
      'evolutions': ?evolutions,
    };

SignatureEvolutionData evolution(Map<String, dynamic> json) =>
    SignatureEvolutionData.fromJson(json);

void main() {
  test('une evolution complete se lit', () {
    final e = evolution(devastation());
    expect(e.id, 'devastation');
    expect(e.tier, EvolutionTier.major);
    expect(e.nameFr, 'Dévastation');
    expect(e.nameEn, 'Devastation');
    expect(e.deltas, [isA<FlatBonusDelta>()]);
    expect((e.deltas.single as FlatBonusDelta).valuePerLevel, 10);
    expect(e.cooldown, 1);
    expect(e.target, isNull);
    expect(e.excludes, ['haste']);
    expect(e.icon, 'rocket_launch_rounded');
    expect(e.color, 'yellowAccent');
    expect(e.isVerbal, isFalse);
  });

  test('un tier inconnu est refuse, nomme', () {
    expect(() => evolution(minor()..['tier'] = 'legendary'), refusing('tier'));
  });

  test('une sorte de delta hors des quatre est refusee, nommee, percentBonus '
      'compris', () {
    for (final kind in ['percentBonus', 'armorPierce']) {
      final json = minor()
        ..['deltas'] = [
          {'type': kind, 'effect': 'damage', 'valuePercentPerLevel': 5},
        ];
      expect(() => evolution(json), refusing(kind));
    }
  });

  test('target, cooldown et excludes sur une mineure sont refuses (D54)', () {
    expect(() => evolution(minor()..['target'] = 'allEnemies'),
        refusing('target'));
    expect(() => evolution(minor()..['cooldown'] = 1), refusing('cooldown'));
    expect(() => evolution(minor()..['excludes'] = ['haste']),
        refusing('excludes'));
  });

  test('target autre que allEnemies, cooldown nul : refuses', () {
    expect(
        () => evolution(haste()
          ..remove('cooldown')
          ..['target'] = 'self'),
        refusing('target'));
    expect(() => evolution(haste()..['cooldown'] = 0), refusing('cooldown'));
  });

  test('une evolution sans aucun changement est refusee', () {
    expect(() => evolution(minor()..remove('deltas')), refusing('deltas'));
  });

  test('icon ou color absents ou vides : refuses', () {
    expect(() => evolution(minor()..remove('icon')), refusing('icon'));
    expect(() => evolution(minor()..['icon'] = ''), refusing('icon'));
    expect(() => evolution(minor()..remove('color')), refusing('color'));
    expect(() => evolution(minor()..['color'] = ''), refusing('color'));
  });

  test('chiffree et verbale a la fois : refusee', () {
    final addAndCooldown = haste()
      ..['deltas'] = [
        {
          'type': 'addEffect',
          'effect': 'apply_status',
          'statusId': 'weakness',
          'valuePerLevel': 1,
          'durationPerLevel': 2,
        },
      ];
    expect(() => evolution(addAndCooldown), refusing('verbale'));

    final targetAndFlat = devastation()
      ..['target'] = 'allEnemies'
      ..remove('cooldown')
      ..remove('excludes');
    expect(() => evolution(targetAndFlat), refusing('verbale'));
  });

  test('un texte bilingue manquant est refuse', () {
    expect(() => evolution(minor()..remove('name_en')), refusing('name_en'));
    expect(() => evolution(minor()..['description_fr'] = ''),
        refusing('description_fr'));
  });

  test('le pool : evolutions absente, vide ou sans mineure, refusee', () {
    expect(() => SignatureData.fromJson(signature()), refusing('evolutions'));
    expect(() => SignatureData.fromJson(signature(evolutions: [])),
        refusing('evolutions'));
    expect(() => SignatureData.fromJson(signature(evolutions: [haste()])),
        refusing('mineure'));
  });

  test('le pool : ids en double ou hors snake_case refuses', () {
    expect(
        () => SignatureData.fromJson(
            signature(evolutions: [minor(), minor()])),
        refusing('zeal'));
    expect(
        () => SignatureData.fromJson(
            signature(evolutions: [minor(id: 'Zeal')])),
        refusing('Zeal'));
  });

  test('le pool : une majeure target sur une signature qui ne vise pas un '
      'ennemi unique est refusee', () {
    final radiance = haste()
      ..['id'] = 'radiance'
      ..remove('cooldown')
      ..['target'] = 'allEnemies';
    expect(
        () => SignatureData.fromJson(signature(
              target: 'self',
              effects: [
                {'type': 'armor', 'value': 4},
              ],
              descriptionFr: 'Donne {armor} d\'Armure.',
              descriptionEn: 'Gain {armor} Block.',
              evolutions: [ardor(), radiance],
            )),
        refusing('target'));
  });

  test('le pool : excludes vers un id inconnu ou une mineure est refuse', () {
    expect(
        () => SignatureData.fromJson(signature(
            evolutions: [minor(), devastation()..['excludes'] = ['ghost']])),
        refusing('ghost'));
    expect(
        () => SignatureData.fromJson(signature(
            evolutions: [minor(), devastation()..['excludes'] = ['zeal']])),
        refusing('zeal'));
  });

  test('les gabarits : un {cle} sans effet propre, ou un effet vise par '
      'flatBonus sans son {cle}, refuses', () {
    expect(
        () => SignatureData.fromJson(signature(
              descriptionFr: 'Inflige {heal} dégâts.',
              evolutions: [minor()],
            )),
        refusing('{heal}'));
    expect(
        () => SignatureData.fromJson(signature(
              descriptionEn: 'Deal damage.',
              evolutions: [minor()],
            )),
        refusing('{damage}'));
  });

  test('getDescription remplit le gabarit des valeurs de base', () {
    final s = SignatureData.fromJson(signature(
      target: 'self',
      effects: [
        {
          'type': 'apply_status',
          'statusId': 'might',
          'value': 2,
          'duration': 1,
        },
        {'type': 'draw', 'value': 1},
      ],
      descriptionFr: 'Applique {might} Puissance ce tour-ci. Pioche {draw} '
          'carte(s).',
      descriptionEn: 'Apply {might} Might this turn. Draw {draw} card(s).',
      evolutions: [ardor()],
    ));
    expect(s.getDescription('fr'),
        'Applique 2 Puissance ce tour-ci. Pioche 1 carte(s).');
    expect(s.getDescription('en'),
        'Apply 2 Might this turn. Draw 1 card(s).');

    final plain = SignatureData.fromJson(signature(
      descriptionFr: 'Frappe.',
      descriptionEn: 'Strike.',
      evolutions: [ardor()],
    ));
    expect(plain.getDescription('fr'), 'Frappe.');
  });

  test('{val} : valuePerLevel x L ; pour reduceCost, la baisse reelle bornee '
      'au cout', () {
    expect(evolution(minor()).getDescription(2, 'fr', cost: 1), '+4 dégâts');
    expect(evolution(ardor()).getDescription(1, 'en', cost: 1),
        '+5% critical chance');

    final cut = haste()
      ..remove('cooldown')
      ..['id'] = 'devotion'
      ..['description_fr'] = '-{val}'
      ..['deltas'] = [
        {'type': 'reduceCost', 'valuePerLevel': 1},
      ];
    expect(evolution(cut).getDescription(1, 'fr', cost: 1), '-1');
    expect(evolution(cut).getDescription(1, 'fr', cost: 0), '-0');
  });

  group('les six pools livres', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    late List<SignatureData> signatures;

    setUpAll(() async {
      signatures = (await loadGameDataRegistry(rootBundle)).signatures;
    });

    String ids(SignatureData s, EvolutionTier tier) => [
          for (final e in s.evolutions)
            if (e.tier == tier) e.id,
        ].join(' ');

    test('les six pools sont ceux de spec 3.7 : trois mineures, quatre '
        'majeures (Q6)', () {
      final actual = {
        for (final s in signatures)
          s.id: (
            ids(s, EvolutionTier.minor),
            ids(s, EvolutionTier.major),
          ),
      };
      expect(actual, {
        'smite': (
          'zeal aegis ardor',
          'haste sentence radiance devotion',
        ),
        'holy_shield': (
          'ward mercy resolve',
          'haste consecration inspiration lasting_aegis',
        ),
        'reckless_strike': (
          'brutality instinct shatter',
          'haste devastation cleave composure',
        ),
        'rage_form': (
          'anger hide second_wind',
          'haste berserk rally fury',
        ),
        'magic_missile': (
          'acuity precision ember',
          'haste overload nova exposure',
        ),
        'mana_surge': (
          'mana_shield attunement clarity',
          'foresight glyph empower serenity',
        ),
      });

      SignatureEvolutionData pick(String signatureId, String id) => signatures
          .firstWhere((s) => s.id == signatureId)
          .evolutions
          .firstWhere((e) => e.id == id);
      final devastationData = pick('reckless_strike', 'devastation');
      expect(devastationData.cooldown, 1);
      expect((devastationData.deltas.single as FlatBonusDelta).valuePerLevel,
          10);
      final overload = pick('magic_missile', 'overload');
      expect(overload.cooldown, 1);
      expect((overload.deltas.single as FlatBonusDelta).valuePerLevel, 8);
    });

    test('haste porte dans ses cinq pools la meme icone, la meme couleur, le '
        'meme texte ; les exclusions sont declarees des deux cotes', () {
      final hastes = {
        for (final s in signatures)
          s.id: s.evolutions.where((e) => e.id == 'haste').firstOrNull,
      };
      expect(hastes['mana_surge'], isNull);
      final present = hastes.values.whereType<SignatureEvolutionData>();
      expect(present, hasLength(5));
      final shapes = {
        for (final h in present)
          (h.icon, h.color, h.nameFr, h.nameEn, h.descriptionFr,
              h.descriptionEn, h.cooldown),
      };
      expect(shapes, hasLength(1));
      expect(present.first.cooldown, -1);

      SignatureEvolutionData pick(String signatureId, String id) => signatures
          .firstWhere((s) => s.id == signatureId)
          .evolutions
          .firstWhere((e) => e.id == id);
      for (final (signatureId, other) in [
        ('reckless_strike', 'devastation'),
        ('magic_missile', 'overload'),
      ]) {
        final h = pick(signatureId, 'haste');
        final o = pick(signatureId, other);
        expect(h.excludes, contains(other));
        expect(o.excludes, contains('haste'));
        expect(h.excludesOrIsExcludedBy(o), isTrue);
      }
    });
  });
}
