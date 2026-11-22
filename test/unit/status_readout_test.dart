import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/status_readout.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les entrées de languette et leur écriture, sur le catalogue livré (spec
/// P-05, §4.3).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChargeCatalog charges;
  setUpAll(() async {
    charges = (await loadGameDataRegistry(rootBundle)).charges;
  });

  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  StatusEffect might({int value = 2, int duration = 99, String? sourceId}) =>
      StatusEffect(
        id: 'might',
        name: 'Puissance',
        type: StatusType.buff,
        value: value,
        duration: duration,
        sourceId: sourceId,
      );

  StatusEffect poison({int value = 2, int duration = 3}) => StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: value,
        duration: duration,
      );

  StatusEffect point(String chargeId, int value) => StatusEffect(
        id: chargeId,
        name: chargeId,
        type: StatusType.debuff,
        value: value,
        duration: 1,
      );

  ChargeTrack track(
    String chargeId,
    ChargeState state, {
    ChargeBearer bearer = ChargeBearer.enemy,
    int? threshold,
  }) {
    final charge = charges[chargeId]!;
    return ChargeTrack(
      threshold: threshold ?? charge.startThreshold(bearer),
      ruptures: state == ChargeState.none ? 0 : 1,
      state: state,
      rupture: charge.ruptureFor(bearer),
    );
  }

  EntityStats stats({
    List<StatusEffect> statuses = const [],
    Map<String, ChargeTrack> tracks = const {},
  }) =>
      EntityStats(
        maxPv: 20,
        currentPv: 20,
        armure: 0,
        might: 0,
        statuses: statuses,
        charges: tracks,
      );

  ({List<StatusReadout> left, List<StatusReadout> right}) read(
    EntityStats entity,
    AppLocalizations l10n, {
    String? counterId,
  }) =>
      StatusReadout.of(entity, charges, l10n, l10n.localeName,
          counterId: counterId);

  StatusReadout onlyRight(EntityStats entity, AppLocalizations l10n) =>
      read(entity, l10n).right.single;

  test('les bonus a gauche ; a droite les alterations puis les charges', () {
    final mixed = stats(
      statuses: [
        might(),
        poison(),
        const StatusEffect(
          id: 'weakness',
          name: 'Faiblesse',
          type: StatusType.debuff,
          value: 1,
          duration: 2,
        ),
        point('freeze', 2),
        point('burn', 5),
      ],
      tracks: {
        'freeze': track('freeze', ChargeState.none, threshold: 3),
        'burn': track('burn', ChargeState.none),
      },
    );

    final readout = read(mixed, fr);

    expect(readout.left.map((e) => e.key), ['might:']);
    expect(readout.right.map((e) => e.key),
        ['poison:', 'weakness:', 'charge:freeze', 'charge:burn']);
  });

  test('deux Puissances de sources differentes font deux entrees', () {
    final readout = read(
      stats(statuses: [
        might(sourceId: 'card'),
        might(sourceId: 'relic'),
      ]),
      fr,
    );

    expect(readout.left, hasLength(2));
    expect(readout.left.map((e) => e.key), ['might:card', 'might:relic']);
  });

  test('un bonus : sa valeur au repos, son nom et +valeur deroules, FR et EN',
      () {
    final entity = stats(statuses: [might(duration: 3)]);

    final inFrench = read(entity, fr).left.single;
    expect(inFrench.restValue, '2');
    expect(inFrench.title, 'Puissance +2');
    expect(inFrench.subtitle, '3 tours');
    expect(inFrench.turnsLeft, 3);
    expect(inFrench.tone, ReadoutTone.buff);

    final inEnglish = read(entity, en).left.single;
    expect(inEnglish.title, 'Might +2');
    expect(inEnglish.subtitle, '3 turns');
  });

  test('une alteration : son nom et sa valeur, sa duree au pluriel et au '
      'singulier', () {
    final two = onlyRight(stats(statuses: [poison(duration: 2)]), fr);
    expect(two.title, 'Poison 2');
    expect(two.subtitle, '2 tours');
    expect(onlyRight(stats(statuses: [poison(duration: 2)]), en).subtitle,
        '2 turns');

    final one = stats(statuses: [poison(duration: 1)]);
    expect(onlyRight(one, fr).subtitle, '1 tour');
    expect(onlyRight(one, en).subtitle, '1 turn');
  });

  test('une duree de 99 n ecrit ni duree ni tours restants (B34)', () {
    final forever = read(stats(statuses: [might(duration: 99)]), fr).left.single;

    expect(forever.subtitle, isNull);
    expect(forever.turnsLeft, isNull);
  });

  test('une charge sous son seuil garde son compte', () {
    final frozen = stats(
      statuses: [point('freeze', 2)],
      tracks: {'freeze': track('freeze', ChargeState.none, threshold: 3)},
    );

    final inFrench = onlyRight(frozen, fr);
    expect(inFrench.restValue, '2/3');
    expect(inFrench.title, 'Gel 2/3');
    expect(inFrench.subtitle, isNull);
    expect(inFrench.turnsLeft, isNull);
    expect(onlyRight(frozen, en).title, 'Freeze 2/3');
  });

  test('le Feu ecrit ses points', () {
    final burning = stats(
      statuses: [point('burn', 5)],
      tracks: {'burn': track('burn', ChargeState.none)},
    );

    final entry = onlyRight(burning, fr);
    expect(entry.restValue, '5');
    expect(entry.title, 'Feu 5');
    expect(onlyRight(burning, en).title, 'Burn 5');
  });

  test('un ennemi gele montre le nom de son etat (B33)', () {
    final frozen = stats(
      tracks: {'freeze': track('freeze', ChargeState.brokenPending)},
    );

    final inFrench = onlyRight(frozen, fr);
    expect(inFrench.restValue, 'Gelé');
    expect(inFrench.title, 'Gelé');
    final inEnglish = onlyRight(frozen, en);
    expect(inEnglish.restValue, 'Frozen');
    expect(inEnglish.title, 'Frozen');
  });

  test('un heros gele : l etat et la baisse de degats, au prochain tour puis '
      'ce tour', () {
    EntityStats hero(ChargeState state) => stats(tracks: {
          'freeze': track('freeze', state, bearer: ChargeBearer.hero),
        });

    final pending = hero(ChargeState.brokenPending);
    expect(onlyRight(pending, fr).title, 'Gelé');
    expect(onlyRight(pending, fr).subtitle, '−50 % de dégâts au prochain tour');
    expect(onlyRight(pending, en).subtitle, '−50% damage next turn');

    final active = hero(ChargeState.brokenActive);
    expect(onlyRight(active, fr).subtitle, '−50 % de dégâts ce tour');
    expect(onlyRight(active, en).subtitle, '−50% damage this turn');
  });

  test('la Foudre chargee est jaune, en attente comme active ; sous le seuil '
      'elle est rouge (B32)', () {
    EntityStats shock(ChargeState state, int points) => stats(
          statuses: [point('shock', points)],
          tracks: {'shock': track('shock', state)},
        );

    final active = onlyRight(shock(ChargeState.brokenActive, 3), fr);
    expect(active.tone, ReadoutTone.charged);
    expect(active.restValue, '3');
    expect(active.title, 'Chargé 3');
    expect(active.subtitle, '+6 par coup');
    final inEnglish = onlyRight(shock(ChargeState.brokenActive, 3), en);
    expect(inEnglish.title, 'Charged 3');
    expect(inEnglish.subtitle, '+6 per hit');

    expect(onlyRight(shock(ChargeState.brokenPending, 3), fr).tone,
        ReadoutTone.charged);
    expect(onlyRight(shock(ChargeState.none, 2), fr).tone, ReadoutTone.debuff);
  });

  test('toute autre charge et toute alteration sont rouges, tout bonus vert',
      () {
    final entity = stats(
      statuses: [might(), poison(), point('burn', 5)],
      tracks: {
        'burn': track('burn', ChargeState.none),
        'freeze': track('freeze', ChargeState.brokenPending),
      },
    );

    final readout = read(entity, fr);
    expect(readout.left.single.tone, ReadoutTone.buff);
    expect(readout.right.map((e) => e.tone), everyElement(ReadoutTone.debuff));

    expect(StatusReadout.toneColor(ReadoutTone.buff), const Color(0xFF69F0AE));
    expect(StatusReadout.toneColor(ReadoutTone.debuff), const Color(0xFFFF5252));
    expect(StatusReadout.toneColor(ReadoutTone.charged), Colors.yellowAccent);
  });

  test('chaque alteration porte sa ligne d aide, FR et EN', () {
    final entity = stats(
      statuses: [
        poison(),
        const StatusEffect(
          id: 'weakness',
          name: 'Faiblesse',
          type: StatusType.debuff,
          value: 1,
          duration: 2,
        ),
        const StatusEffect(
          id: 'vulnerable',
          name: 'Vulnérable',
          type: StatusType.debuff,
          value: 1,
          duration: 2,
        ),
      ],
    );

    Map<String, String?> hints(AppLocalizations l10n) =>
        {for (final e in read(entity, l10n).right) e.key: e.hint};

    expect(hints(fr)['weakness:'], "−25 % de dégâts infligés par point, jusqu'à −50 %");
    expect(hints(fr)['vulnerable:'], "+25 % de dégâts subis par point, jusqu'à +100 %");
    expect(hints(fr)['poison:'], 'Subit 2 dégâts au début de son tour');
    expect(hints(en)['poison:'], 'Takes 2 damage at the start of its turn');
  });

  test('chaque bonus porte sa ligne d aide, FR et EN', () {
    StatusEffect buff(String id, int value) => StatusEffect(
          id: id,
          name: id,
          type: StatusType.buff,
          value: value,
          duration: 2,
        );
    final entity = stats(statuses: [
      might(value: 3),
      buff('might_regen', 1),
      buff('armor_regen', 2),
      buff('mana_regen', 1),
      buff('hp_regen', 4),
    ]);

    Map<String, String?> hints(AppLocalizations l10n) =>
        {for (final e in read(entity, l10n).left) e.key: e.hint};

    expect(hints(fr), {
      'might:': '+3 aux dégâts de ses attaques',
      'might_regen:': 'Gagne 1 Puissance au début de son tour',
      'armor_regen:': 'Gagne 2 Armure au début de son tour',
      'mana_regen:': 'Gagne 1 Mana au début de son tour',
      'hp_regen:': 'Récupère 4 PV au début de son tour',
    });
    expect(hints(en)['might:'], '+3 damage on its attacks');
    expect(hints(en)['hp_regen:'], 'Recovers 4 HP at the start of its turn');
  });

  test('un statut de relique n a pas de ligne d aide', () {
    final entity = stats(statuses: [
      const StatusEffect(
        id: 'kunai_charge',
        name: 'Charge Kunaï',
        type: StatusType.buff,
        value: 1,
        duration: 99,
      ),
    ]);

    expect(read(entity, fr).left.single.hint, isNull);
  });

  test('une charge porte sa phrase courte, sous le seuil comme rompue', () {
    final entity = stats(
      statuses: [point('freeze', 2), point('burn', 5), point('shock', 3)],
      tracks: {
        'freeze': track('freeze', ChargeState.none),
        'burn': track('burn', ChargeState.none),
        'shock': track('shock', ChargeState.brokenActive),
      },
    );

    Map<String, String?> hints(AppLocalizations l10n) =>
        {for (final e in read(entity, l10n).right) e.key: e.hint};

    expect(hints(fr), {
      'charge:freeze': 'Au seuil, gèle : perd sa prochaine action.',
      'charge:burn':
          'Brûle à son tour ; chaque tranche de 3 explose sur ses voisins.',
      'charge:shock': 'Les coups reçus font +1 par point, +2 au seuil.',
    });
    expect(hints(en)['charge:freeze'],
        'At the threshold, freezes: loses its next action.');
    expect(
      onlyRight(
        stats(tracks: {'freeze': track('freeze', ChargeState.brokenPending)}),
        fr,
      ).hint,
      'Au seuil, gèle : perd sa prochaine action.',
    );
  });

  test('une charge sur le heros n a pas de ligne d aide : son sous-titre dit '
      'l effet', () {
    final hero = stats(tracks: {
      'freeze': track('freeze', ChargeState.brokenPending,
          bearer: ChargeBearer.hero),
    });

    expect(onlyRight(hero, fr).hint, isNull);
    expect(onlyRight(hero, fr).subtitle, '−50 % de dégâts au prochain tour');
  });

  test('le compteur d un passif se nomme Compteur, Counter', () {
    final entity = stats(statuses: [
      const StatusEffect(
        id: 'mage_mark_count',
        name: 'Compteur',
        type: StatusType.buff,
        value: 1,
        duration: 99,
      ),
    ]);

    expect(read(entity, fr, counterId: 'mage_mark_count').left.single.title,
        'Compteur +1');
    expect(read(entity, en, counterId: 'mage_mark_count').left.single.title,
        'Counter +1');
  });

  test('les emojis : 💎 pour la Source de Mana, 💖 pour la Source de Vie', () {
    expect(statusEmoji('mana_regen'), '💎');
    expect(statusEmoji('hp_regen'), '💖');
    expect(statusEmoji('poison'), '🧪');
    expect(statusEmoji('inconnu'), '✨');
  });
}
