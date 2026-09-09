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

  group('la pastille de classe', () {
    // `classImageOf` peut designer une `iconPath` qui n'existe pas :
    // `EntityWriter._placeClassIcon` sort en silence quand le placeholder
    // source est absent, et le `class.json` ecrit designe alors un fichier
    // jamais depose. Sans repli, le dialogue leve a son ouverture — et c'est
    // un ecran que les joueurs ouvrent.
    const withMissingIcon = HeroData(
      id: 'gambler',
      classCard: 'assets/data/classes/gambler/gambler.png',
      iconPath: 'assets/data/classes/gambler/icon.png',
      maxHp: 100,
      maxMana: 3,
      baseDamage: 5,
    );

    Future<Image> pumpAvatar(WidgetTester tester, HeroData hero) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ClassAvatar(hero: hero))),
      );
      return tester.widget<Image>(find.byType(Image));
    }

    testWidgets('le decodage est borne a la taille de rendu', (tester) async {
      // Flame tient son propre cache, distinct de l'`ImageCache` de Flutter :
      // sans `cacheWidth`, `Image.asset` decode la carte de classe une seconde
      // fois a pleine resolution — 1696 x 2528 x 4 octets, ~17 Mo, pour un
      // avatar de 36 points.
      final image = await pumpAvatar(tester, withMissingIcon);

      expect(image.image, isA<ResizeImage>());
      expect(
        (image.image as ResizeImage).width,
        (36 * tester.view.devicePixelRatio).round(),
      );
    });

    testWidgets('une image introuvable replie sur la carte de classe',
        (tester) async {
      final image = await pumpAvatar(tester, withMissingIcon);
      expect(image.errorBuilder, isNotNull);

      final fallback = image.errorBuilder!(
        tester.element(find.byType(ClassAvatar)),
        'introuvable',
        null,
      );

      expect(fallback, isA<Image>());
      final provider = (fallback as Image).image as ResizeImage;
      expect(
        (provider.imageProvider as AssetImage).assetName,
        withMissingIcon.classCard,
        reason: 'le repli du §3.3 doit montrer la carte de classe',
      );
    });

    testWidgets('la carte de classe absente ne fait pas lever non plus',
        (tester) async {
      // Le second cran du repli : se rabattre sur `classCard` n'a pas de sens
      // quand c'est elle qui vient d'echouer. On montre alors un disque teinte
      // plutot que de laisser l'exception remonter.
      const noIcon = HeroData(
        id: 'gambler',
        classCard: 'assets/data/classes/gambler/gambler.png',
        maxHp: 100,
        maxMana: 3,
        baseDamage: 5,
      );
      final image = await pumpAvatar(tester, noIcon);

      final fallback = image.errorBuilder!(
        tester.element(find.byType(ClassAvatar)),
        'introuvable',
        null,
      );
      expect(fallback, isNot(isA<Image>()));
    });
  });
}
