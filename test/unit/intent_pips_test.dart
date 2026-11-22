import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/ui/widgets/hud/intent_pips.dart';

/// Les pastilles d'une intention, calculées sans écran (spec P-05, §4.2).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  EnemyIntent attack(int value) =>
      EnemyIntent(type: IntentType.attack, value: value);

  IntentPip single(EnemyIntent? intent, {bool skipped = false}) {
    final pips = IntentPips.of(intent, skipped: skipped, l10n: fr);
    expect(pips, hasLength(1));
    return pips.single;
  }

  test('chaque palier d attaque a son icone et sa couleur', () {
    final low = single(attack(5));
    expect(low.icon, Icons.bolt);
    expect(low.color, const Color(0xFFF39C12));
    expect(low.value, '5');

    final medium = single(attack(8));
    expect(medium.icon, Icons.flash_on);
    expect(medium.color, const Color(0xFFFF7675));
    expect(medium.value, '8');

    final heavy = single(attack(15));
    expect(heavy.icon, Icons.whatshot);
    expect(heavy.color, const Color(0xFFE74C3C));

    final devastating = single(attack(22));
    expect(devastating.icon, Icons.gavel);
    expect(devastating.color, const Color(0xFFC0392B));
  });

  test('les seuils 6, 12 et 20 ouvrent le palier suivant', () {
    for (final (below, at) in [(5, 6), (11, 12), (19, 20)]) {
      expect(single(attack(below)).icon, isNot(single(attack(at)).icon));
    }
  });

  test('la Defense prend le bouclier bleu, le Buff la fleche violette (B31)',
      () {
    final defend = single(EnemyIntent(type: IntentType.defend, value: 3));
    expect(defend.icon, Icons.shield);
    expect(defend.color, const Color(0xFF448AFF));
    expect(defend.value, '+3');

    final buff = single(EnemyIntent(type: IntentType.buff, value: 2));
    expect(buff.icon, Icons.trending_up);
    expect(buff.color, const Color(0xFFE040FB));
    expect(buff.value, '+2');
  });

  test('sans intention : le sablier, En attente... et waiting', () {
    final waiting = single(null);

    expect(waiting.icon, Icons.hourglass_empty);
    expect(waiting.color, Colors.white30);
    expect(waiting.waiting, isTrue);
    expect(waiting.struck, isFalse);
    expect(waiting.value, 'En attente...');
    expect(IntentPips.of(null, skipped: false, l10n: en).single.value,
        'Waiting...');
  });

  test('un ennemi gele garde icone et valeur, grisees et barrees', () {
    final frozen = single(attack(8), skipped: true);

    expect(frozen.icon, Icons.flash_on);
    expect(frozen.color, Colors.white38);
    expect(frozen.value, '8');
    expect(frozen.struck, isTrue);
    expect(frozen.waiting, isFalse);

    final idle = single(null, skipped: true);
    expect(idle.icon, Icons.hourglass_empty);
    expect(idle.waiting, isTrue);
    expect(idle.struck, isFalse);
  });

  test('of ne rend jamais plus d une pastille en 0.6.1', () {
    final intents = [
      for (final type in IntentType.values) EnemyIntent(type: type, value: 7),
      null,
    ];
    for (final intent in intents) {
      for (final skipped in [true, false]) {
        expect(IntentPips.of(intent, skipped: skipped, l10n: fr), hasLength(1));
      }
    }
  });
}
