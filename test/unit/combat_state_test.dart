import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/combat_state.dart';

/// La table de recharge des signatures (spec P-43 E4, §4.2).
void main() {
  test('la table est vide par defaut, et toute signature est prete', () {
    final state = CombatState();

    expect(state.signaturesReadyOn, isEmpty);
    expect(state.isSignatureReady('smite'), isTrue);
    expect(state.signatureTurnsLeft('smite'), 0);
  });

  test('signatureTurnsLeft se derive du tour courant, jamais negatif', () {
    CombatState at(int turn) =>
        CombatState(turnCount: turn, signaturesReadyOn: const {'smite': 3});

    expect(at(1).signatureTurnsLeft('smite'), 2);
    expect(at(2).signatureTurnsLeft('smite'), 1);
    expect(at(3).signatureTurnsLeft('smite'), 0);
    expect(at(3).isSignatureReady('smite'), isTrue);
    expect(at(5).signatureTurnsLeft('smite'), 0);
  });

  test('copyWith porte la table', () {
    final state = CombatState(signaturesReadyOn: const {'smite': 3});

    expect(state.copyWith(turnCount: 2).signaturesReadyOn, {'smite': 3});
    expect(state.copyWith(signaturesReadyOn: const {}).signaturesReadyOn,
        isEmpty);
  });

  test('toJson n ecrit aucune cle de signature', () {
    final json =
        CombatState(signaturesReadyOn: const {'smite': 3}).toJson();

    expect(json.keys.any((k) => k.contains('signature')), isFalse);
    expect(jsonEncode(json).contains('smite'), isFalse);
  });
}
