import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/stats_dialog.dart';

void main() {
  const hero = HeroData(
    id: 'gambler',
    nameFr: 'Le Parieur',
    nameEn: 'Gambler',
    classCard: 'assets/data/classes/gambler/gambler.png',
    themeColor: 0xFF00A88F, // aucune des trois couleurs en dur
    maxHp: 100,
    maxMana: 3,
    baseDamage: 5,
  );

  test('la couleur vient de la donnee', () {
    expect(StatsDialog.classColorOf(hero), const Color(0xFF00A88F));
  });

  test('une classe sans themeColor retombe sur le bleu d origine', () {
    const plain = HeroData(
      id: 'plain',
      classCard: 'assets/data/classes/plain/plain.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );
    expect(StatsDialog.classColorOf(plain), Colors.blue);
  });

  test('l image affichee est l icone quand elle existe, la carte sinon', () {
    expect(StatsDialog.classImageOf(hero),
        'assets/data/classes/gambler/gambler.png');

    const withIcon = HeroData(
      id: 'gambler',
      classCard: 'assets/data/classes/gambler/gambler.png',
      iconPath: 'assets/data/classes/gambler/icon.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );
    expect(StatsDialog.classImageOf(withIcon),
        'assets/data/classes/gambler/icon.png');
  });
}
