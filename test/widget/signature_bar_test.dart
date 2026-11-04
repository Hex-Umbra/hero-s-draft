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
}
