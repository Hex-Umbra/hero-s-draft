import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/charge_track.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/hud/enemy_sheet_view.dart';

/// Ce que la fiche d'un ennemi écrit, et où son cadre se pose (spec P-05,
/// §4.4 et §4.6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChargeCatalog charges;
  setUpAll(() async {
    charges = (await loadGameDataRegistry(rootBundle)).charges;
  });

  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  const goblin = EnemyData(
    id: 'goblin',
    nameFr: 'Gobelin',
    nameEn: 'Goblin',
    maxHp: 14,
    baseDamage: 2,
    spritePath: '',
  );

  /// 9/14 PV, 4 d'armure, Puissance 2 plus un bonus de +2 : l'attaque de 2
  /// s'écrit 4, la Puissance aussi.
  EnemyInstance enemy({
    EnemyIntent? intent,
    int armor = 4,
    bool withBonus = true,
    Map<String, ChargeTrack> tracks = const {},
  }) =>
      EnemyInstance(
        data: goblin,
        stats: EntityStats(
          maxPv: 14,
          currentPv: 9,
          armure: armor,
          might: 2,
          statuses: [
            if (withBonus)
              const StatusEffect(
                id: 'might',
                name: 'Puissance',
                type: StatusType.buff,
                value: 2,
                duration: 99,
              ),
            const StatusEffect(
              id: 'poison',
              name: 'Poison',
              type: StatusType.debuff,
              value: 2,
              duration: 3,
            ),
          ],
          charges: tracks,
        ),
        currentIntent: intent,
      );

  EnemyIntent attack(int value) =>
      EnemyIntent(type: IntentType.attack, value: value);

  EnemySheetView sheet(EnemyInstance e, AppLocalizations l10n) =>
      EnemySheetView.of(e,
          charges: charges, l10n: l10n, locale: l10n.localeName);

  test('la fiche d un ennemi, en francais', () {
    final view = sheet(enemy(intent: attack(2)), fr);

    expect(view.title, 'GOBELIN');
    expect(view.level, 'Niv. 1');
    expect(view.hp, 'PV 9/14');
    expect(view.armor, 'Armure 4');
    expect(view.might, 'Puissance 4');
    expect(view.intentName, 'Attaque Rapide');
    expect(view.intentSentence, 'Attaquera le héros pour 4 dégâts.');
    expect(view.bonuses, hasLength(1));
    expect(view.alterations, hasLength(1));
    expect(view.alterations.single.text, endsWith('· encore 3 tours'));
  });

  test('la fiche d un ennemi, en anglais', () {
    final view = sheet(enemy(intent: attack(2)), en);

    expect(view.title, 'GOBLIN');
    expect(view.level, 'Lvl. 1');
    expect(view.hp, 'HP 9/14');
    expect(view.armor, 'Armor 4');
    expect(view.might, 'Might 4');
    expect(view.intentName, 'Quick Attack');
    expect(view.intentSentence, 'Will attack the hero for 4 damage.');
    expect(view.alterations.single.text, endsWith('· 3 turns left'));
  });

  test('un ennemi gele dit qu il ne fait rien', () {
    final frozen = charges['freeze']!;
    final view = sheet(
      enemy(intent: attack(2), tracks: {
        'freeze': ChargeTrack(
          threshold: 3,
          ruptures: 1,
          state: ChargeState.brokenPending,
          rupture: frozen.ruptureFor(ChargeBearer.enemy),
        ),
      }),
      fr,
    );

    expect(view.intentSentence, 'Gelé : ne fait rien ce tour');
  });

  test('sans intention', () {
    final view = sheet(enemy(), fr);

    expect(view.intentSentence, 'Intention pas encore connue.');
    expect(view.intentName, isEmpty);
    expect(view.pips.single.waiting, isTrue);
  });

  test('sans bonus, pas de section bonus (B34)', () {
    final view = sheet(enemy(withBonus: false), fr);

    expect(view.bonuses, isEmpty);
  });

  test('l armure se montre a 0', () {
    final view = sheet(enemy(armor: 0), fr);

    expect(view.armor, 'Armure 0');
  });

  test('1 degat au singulier', () {
    const rat = EnemyData(
      id: 'rat',
      nameFr: 'Rat',
      nameEn: 'Rat',
      maxHp: 14,
      baseDamage: 1,
      spritePath: '',
    );
    final weak = EnemyInstance(
      data: rat,
      stats: EntityStats(maxPv: 14, currentPv: 14, armure: 0, might: 1),
      currentIntent: attack(1),
    );

    expect(sheet(weak, fr).intentSentence, 'Attaquera le héros pour 1 dégât.');
  });

  const screen = Size(1280, 800);

  test('le cadre se pose a droite s il tient', () {
    final topLeft = SheetPlacement.topLeftFor(
      card: Rect.fromLTWH(100, 100, 200, 300),
      screen: screen,
    );

    expect(topLeft, const Offset(324, 100));
  });

  test('sinon a gauche', () {
    final topLeft = SheetPlacement.topLeftFor(
      card: const Rect.fromLTRB(900, 100, 1100, 400),
      screen: screen,
    );

    expect(topLeft.dx, 566);
  });

  test('sans place des deux cotes, du cote le plus large, borne', () {
    final topLeft = SheetPlacement.topLeftFor(
      card: const Rect.fromLTRB(200, 100, 450, 400),
      screen: const Size(600, 800),
    );

    expect(topLeft.dx, 16);
  });

  test('le haut ne monte pas au-dessus de la marge', () {
    final topLeft = SheetPlacement.topLeftFor(
      card: Rect.fromLTWH(100, 4, 200, 300),
      screen: screen,
    );

    expect(topLeft.dy, 16);
  });
}
