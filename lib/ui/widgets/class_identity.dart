import 'package:flutter/material.dart';
import '../../models/data/hero_data.dart';

/// L'identite visuelle d'une classe, lue dans sa donnee — jamais deduite de
/// son identifiant.
///
/// Une classe creee par l'editeur de contenu doit s'afficher partout avec sa
/// propre couleur et sa propre image, sans une ligne de code : c'est pourquoi
/// aucun ecran ne compare `hero.id` a un nom de classe.
class ClassIdentity {
  ClassIdentity._();

  /// La couleur d'une classe dont `class.json` ne porte pas de `themeColor`,
  /// ou en porte une malformee.
  static const Color fallbackColor = Colors.blue;

  static Color colorOf(HeroData hero) =>
      hero.themeColor == null ? fallbackColor : Color(hero.themeColor!);

  /// L'image de la classe : la vraie icone si elle existe, la carte de classe
  /// sinon. Le repli evite un carre magenta tant qu'aucune icone n'est
  /// dessinee.
  static String imageOf(HeroData hero) => hero.iconPath ?? hero.classCard;

  /// Le degrade des boutons teintes par la classe : du sombre vers le clair,
  /// dans la teinte de la classe.
  ///
  /// Derive de la seule couleur. Il ne remplace aucune table : l'ancien bouton
  /// reconnaissait le paladin en comparant sa couleur a `Colors.blue`, si bien
  /// que toute classe inconnue heritait du degrade du paladin.
  static LinearGradient gradientOf(Color color) {
    final hsl = HSLColor.fromColor(color);
    return LinearGradient(
      colors: [
        hsl.withLightness(hsl.lightness * 0.6).toColor(),
        hsl.withLightness((hsl.lightness + 0.1).clamp(0.0, 0.6)).toColor(),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// La pastille ronde de la classe.
///
/// Deux precautions pour un seul `Image.asset`, et les deux comptent parce que
/// les ecrans qui la montrent sont ouverts par les joueurs :
///
/// - **`cacheWidth`.** Flame tient son propre cache d'images, distinct de
///   l'`ImageCache` de Flutter. `Image.asset` decode donc la carte de classe
///   une **seconde** fois, a pleine resolution : 1696 x 2528 x 4 octets, soit
///   ~17 Mo, pour un disque de quelques dizaines de points.
/// - **`errorBuilder`.** [ClassIdentity.imageOf] peut designer une `iconPath`
///   qui n'existe pas : `EntityWriter._placeClassIcon` sort en silence quand
///   son placeholder source est absent, et le `class.json` ecrit designe alors
///   un fichier jamais depose. Sans repli, l'ecran **leve**, et rien ne
///   l'attrape.
class ClassAvatar extends StatelessWidget {
  const ClassAvatar({super.key, required this.hero, this.diameter = 36});

  final HeroData hero;

  /// Le diametre a l'ecran, en points. C'est lui qui borne le decodage.
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final path = ClassIdentity.imageOf(hero);
    return ClipOval(
      child: _asset(
        context,
        path,
        // Se replier sur la carte de classe n'a de sens que si ce n'est pas
        // elle qui vient d'echouer : sinon le repli echouerait pareil.
        fallback: path == hero.classCard ? null : hero.classCard,
      ),
    );
  }

  Widget _asset(BuildContext context, String path, {String? fallback}) {
    return Image.asset(
      path,
      width: diameter,
      height: diameter,
      fit: BoxFit.cover,
      // La cible est un cercle de [diameter] points : decoder plus large ne
      // gagne rien a l'ecran et coute la difference en memoire.
      cacheWidth: (diameter * MediaQuery.devicePixelRatioOf(context)).round(),
      errorBuilder: (innerContext, _, _) => fallback == null
          // Dernier cran : la couleur de la classe, plutot qu'une exception.
          ? SizedBox(
              width: diameter,
              height: diameter,
              child: ColoredBox(color: ClassIdentity.colorOf(hero)),
            )
          : _asset(innerContext, fallback),
    );
  }
}
