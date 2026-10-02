import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';

/// Le bloc central de la carte de combat ne chevauche plus l'en-tête : neuf
/// runes font deux rangées de prises, et `spectral` montre le badge « Usage
/// unique » sur une attaque (spec P-43 E2, partie 2).
void main() {
  test('le bloc central reste centre tant que l en-tete le laisse', () {
    // 196 de haut, un bloc de 22 : centre a 98 - 11 + 5 = 92.
    expect(
      CardTextRenderer.centerBlockTop(
        cardHeight: 196,
        blockHeight: 22,
        headerBottom: 70,
      ),
      92,
    );
  });

  // Review Focus 5.
  test('il descend sous les prises et le badge quand ils le depassent', () {
    expect(
      CardTextRenderer.centerBlockTop(
        cardHeight: 196,
        blockHeight: 34,
        headerBottom: 99.5,
      ),
      99.5,
    );
  });
}
