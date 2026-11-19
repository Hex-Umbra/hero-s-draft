import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/hand_geometry.dart';

/// La géométrie de la main en éventail : l'écart entre deux cartes selon la
/// taille de l'écran, et l'arbitre qui désigne la carte survolée.
void main() {
  group('handAngleStep', () {
    // Les entrées que `LayoutSystem` calcule pour un écran donné.
    double stepFor(double width, double height, int count) {
      final scaleFactor = (height / 800).clamp(0.85, 2.5);
      return handAngleStep(
        count: count,
        availableWidth: width - 2 * GameConstants.handSideReserve,
        cardWidth: GameConstants.cardWidth * scaleFactor * 0.88,
        radius: height * 1.5,
      );
    }

    // L'écart horizontal moyen entre deux centres voisins, sur le cercle.
    double meanSpacing(double height, int count, double step) {
      final radius = height * 1.5;
      return 2 * radius * sin(step * (count - 1) / 2) / (count - 1);
    }

    test("1280x720, 10 cartes : l'éventail s'élargit à la largeur libre", () {
      final step = stepFor(1280, 720, 10);
      expect(meanSpacing(720, 10, 0.04), closeTo(43.0, 0.5));
      // (1280 - 2 x 286 - 110,88) / 9 : les cartes extrêmes touchent les
      // réserves des panneaux.
      expect(meanSpacing(720, 10, step), closeTo(66.35, 0.1));
      expect(step, greaterThan(0.04));
      expect(step, lessThan(handMaxAngleStep));
    });

    test("1920x1080, 10 cartes : plafonné à l'écart d'une main de cinq", () {
      expect(stepFor(1920, 1080, 10), handMaxAngleStep);
    });

    test("une fenêtre étroite garde l'écart d'origine, jamais plus serré", () {
      expect(stepFor(800, 600, 10), closeTo(0.04, 1e-12));
      expect(stepFor(400, 600, 10), closeTo(0.04, 1e-12));
    });

    test("7 cartes : la largeur libre ou la règle d'origine, la plus large",
        () {
      // En 1280x720, la largeur libre dépasse même l'écart maximal.
      expect(stepFor(1280, 720, 7), handMaxAngleStep);
      // En 1024x768, elle ne donnerait que 0,048 : la règle d'origine reste.
      expect(stepFor(1024, 768, 7), closeTo(0.4 / 7, 1e-12));
    });

    test("cinq cartes ou moins : l'écart maximal", () {
      for (final count in [1, 2, 3, 4, 5]) {
        expect(stepFor(1280, 720, count), handMaxAngleStep);
      }
    });
  });

  group('pickHoveredCard', () {
    // Trois cartes de 100 x 140 alignées, à 40 l'une de l'autre : moins
    // d'une demi-largeur, la bande visible de la carte du milieu, [90, 130],
    // tient entière dans le rectangle de sa voisine de gauche, [50, 150].
    const row = [
      HandCardPose(x: 100, y: 0, angle: 0),
      HandCardPose(x: 140, y: 0, angle: 0),
      HandCardPose(x: 180, y: 0, angle: 0),
    ];

    int? pick(
      List<HandCardPose> cards,
      double x,
      double y, {
      int? current,
    }) =>
        pickHoveredCard(
          cards: cards,
          pointerX: x,
          pointerY: y,
          width: 100,
          height: 140,
          hoverScale: 1.2,
          current: current,
        );

    test("la bande visible d'une carte du milieu lui appartient", () {
      expect(pick(row, 110, 0), 1);
      expect(pick(row, 125, 0), 1);
      expect(pick(row, 70, 0), 0);
      expect(pick(row, 200, 0), 2);
    });

    test("la carte la plus haute l'emporte, quelle que soit la survolée", () {
      expect(pick(row, 110, 0, current: 0), 1);
      expect(pick(row, 140, 0, current: 1), 2);
      expect(pick(row, 70, 0, current: 2), 0);
    });

    test('hystérésis : le bord de la carte grossie la garde survolée', () {
      // Au-dessus des cartes au repos (demi-hauteur 70), dans le rectangle
      // agrandi de la carte du milieu (demi-hauteur 84).
      expect(pick(row, 140, -78, current: 1), 1);
      expect(pick(row, 140, -78), isNull);
      // Hors du rectangle agrandi : plus rien.
      expect(pick(row, 140, -90, current: 1), isNull);
      // À droite de la dernière carte, dans sa demi-largeur agrandie (60).
      expect(pick(row, 235, 0, current: 2), 2);
      expect(pick(row, 235, 0), isNull);
    });

    test('une carte qui ne peut pas être survolée laisse voir la suivante',
        () {
      const entering = [
        HandCardPose(x: 100, y: 0, angle: 0),
        HandCardPose(x: 140, y: 0, angle: 0, hoverable: false),
        HandCardPose(x: 180, y: 0, angle: 0),
      ];
      expect(pick(entering, 110, 0), 0);
      expect(pick(entering, 125, 0), 0);
      expect(pick(entering, 190, 0), 2);
      // Ni survolée ni gardée par l'hystérésis.
      expect(pick(entering, 140, -78, current: 1), isNull);
    });

    test('aucune carte sous le pointeur, ou une main vide', () {
      expect(pick(row, 500, 0), isNull);
      expect(pick(const [], 100, 0), isNull);
      expect(pick(const [], 100, 0, current: 0), isNull);
    });

    test('le rectangle tourne avec la carte, dans le sens horaire', () {
      // Penchée vers la droite : son coin haut droit descend à (68,5 ; -52,1).
      const tilted = [HandCardPose(x: 0, y: 0, angle: 0.3)];
      expect(pick(tilted, 64, -50), 0);
      expect(pick(tilted, -64, -50), isNull);
    });

    test('une carte grossie se lit à sa taille', () {
      const focused = [HandCardPose(x: 0, y: 0, angle: 0, scale: 1.25)];
      expect(pick(focused, 60, 0), 0);
      expect(pick(focused, 64, 0), isNull);
    });
  });
}
