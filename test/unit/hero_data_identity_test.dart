import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
  Map<String, dynamic> base() => {
        'id': 'gambler',
        'name_fr': 'Le Parieur',
        'name_en': 'Gambler',
        'description_fr': 'Manipule les probabilites.',
        'description_en': 'Plays the odds.',
        'classCard': 'assets/data/classes/gambler/gambler.png',
        'maxHp': 100,
        'maxMana': 3,
        'baseDamage': 5,
      };

  test('classCard est lu, et iconPath vaut null quand il est absent', () {
    final hero = HeroData.fromJson(base());
    expect(hero.classCard, 'assets/data/classes/gambler/gambler.png');
    expect(hero.iconPath, isNull);
  });

  test('iconPath est lu quand il est present', () {
    final hero = HeroData.fromJson(
      base()..['iconPath'] = 'assets/data/classes/gambler/icon.png',
    );
    expect(hero.iconPath, 'assets/data/classes/gambler/icon.png');
  });

  test('themeColor decode #RRGGBB en ARGB opaque', () {
    final hero = HeroData.fromJson(base()..['themeColor'] = '#B71C1C');
    expect(hero.themeColor, 0xFFB71C1C);
  });

  // Une couleur fausse ne doit pas faire echouer le chargement du jeu entier :
  // `fromJson` est une couche de compatibilite, pas un validateur. C'est
  // l'editeur qui refuse d'ecrire une couleur malformee, pas le chargeur qui
  // refuse de demarrer.
  test('une themeColor malformee vaut null plutot que de lever', () {
    for (final bad in const ['B71C1C', '#XYZ', '#B71C1', '', '#B71C1CFF']) {
      expect(
        HeroData.fromJson(base()..['themeColor'] = bad).themeColor,
        isNull,
        reason: 'valeur refusee : "$bad"',
      );
    }
  });
}
