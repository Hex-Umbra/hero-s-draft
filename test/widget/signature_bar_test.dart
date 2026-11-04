import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/hud/signature_bar.dart';

void main() {
  test('la priorite des etats : inactive, recharge, mana, armee, disponible', () {
    SignatureTileState of({
      bool interactive = true,
      int turnsLeft = 0,
      bool affordable = true,
      bool armed = false,
    }) => signatureTileStateOf(
      interactive: interactive,
      turnsLeft: turnsLeft,
      affordable: affordable,
      armed: armed,
    );

    expect(of(), SignatureTileState.available);
    expect(of(armed: true), SignatureTileState.armed);
    expect(of(affordable: false, armed: true), SignatureTileState.unaffordable);
    expect(
      of(turnsLeft: 2, affordable: false, armed: true),
      SignatureTileState.recharging,
    );
    expect(
      of(interactive: false, turnsLeft: 2, affordable: false, armed: true),
      SignatureTileState.inactive,
    );
  });

  test('signatureBandPlacement : centree, decalee, reduite, plancher', () {
    final centered = signatureBandPlacement(available: 800, natural: 176);
    expect(centered.scale, 1);
    expect(centered.top, 312);

    final shifted = signatureBandPlacement(available: 800, natural: 500);
    expect(shifted.scale, 1);
    expect(shifted.top, 100);

    final reduced = signatureBandPlacement(available: 800, natural: 600);
    expect(reduced.scale, closeTo(520 / 600, 1e-9));
    expect(reduced.top, 80);

    final floor = signatureBandPlacement(available: 400, natural: 176);
    expect(floor.scale, 0.75);
    expect(floor.top, 80);
    expect(floor.top + floor.scale * 176 > 400 - 200, isTrue);
  });
}
