import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/event_screen.dart';

/// Le badge `gain_max_hp` d'un événement : le signe suit la valeur, jamais
/// « +-12 PV Max » (La Fontaine Bénie, choix « Purifier son esprit »).
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('un gain de PV max garde son signe +', () {
    expect(EventScreen.maxHpText(fr, 8), '+8 PV Max');
    expect(EventScreen.maxHpText(en, 8), '+8 Max HP');
  });

  test('une perte de PV max s affiche avec un seul signe -', () {
    expect(EventScreen.maxHpText(fr, -12), '-12 PV Max');
    expect(EventScreen.maxHpText(en, -12), '-12 Max HP');
  });
}
