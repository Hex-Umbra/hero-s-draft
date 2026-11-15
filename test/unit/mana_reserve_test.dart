import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/systems/mana_reserve.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Le calcul unique de la banque de mana (D30 ; plan 2026-11-15, A2) : ce
/// qui passe en réserve, et si le plafond en retient.
void main() {
  const reserve = PassiveData(
    id: 'channeling',
    trigger: RelicTrigger.endOfTurn,
    effectType: ManaReserve.effectType,
    value: 0,
    mastery: PassiveMastery(
      field: 'value',
      perPoint: 1,
      descriptionEn: '+{amount}',
      descriptionFr: '+{amount}',
    ),
  );

  const flux = PassiveData(
    id: 'mana_flux',
    trigger: RelicTrigger.onSkillPlayed,
    effectType: 'mana_flux',
    value: 1,
    threshold: 3,
  );

  EntityStats hero({
    int mana = 0,
    int mastery = 0,
    List<StatusEffect> statuses = const [],
  }) =>
      EntityStats(
        maxPv: 60,
        currentPv: 60,
        maxMana: 3,
        currentMana: mana,
        armure: 0,
        might: 0,
        mastery: mastery,
        statuses: statuses,
      );

  test('sans passif a reserve, aucun apercu', () {
    expect(ManaReserve.preview(null, hero(mana: 2)), isNull);
    expect(ManaReserve.preview(flux, hero(mana: 2)), isNull);
  });

  test('sous le plafond : tout le mana non depense, sans plafond', () {
    expect(
      ManaReserve.preview(reserve, hero(mana: 2)),
      (banked: 2, capped: false),
    );
  });

  test('au plafond exact : tout, et le plafond ne retient rien', () {
    expect(
      ManaReserve.preview(reserve, hero(mana: 3)),
      (banked: 3, capped: false),
    );
  });

  test('au-dela du plafond : le plafond, qui retient le reste', () {
    expect(
      ManaReserve.preview(reserve, hero(mana: 5)),
      (banked: 3, capped: true),
    );
  });

  test('le plafond suit le Mana max du heros, pas un 3 en dur', () {
    final bigger = hero(mana: 6).copyWith(maxMana: 4);

    expect(ManaReserve.preview(reserve, bigger), (banked: 4, capped: true));
  });

  test('la valeur du passif releve le plafond', () {
    expect(
      ManaReserve.preview(reserve.withMastery(2), hero(mana: 5)),
      (banked: 5, capped: false),
    );
  });

  test('forRun applique la Maitrise effective, statuts compris', () {
    final run = RunState(
      currentLevel: 1,
      heroClassId: 'mage',
      activePassive: reserve,
      heroStats: hero(
        mana: 6,
        mastery: 1,
        statuses: const [
          StatusEffect(
            id: 'mastery',
            name: 'Maitrise',
            type: StatusType.buff,
            value: 1,
            duration: 99,
          ),
        ],
      ),
    );

    // Plafond 3 + 2 : la Maîtrise de la classe et celle d'un statut.
    expect(ManaReserve.forRun(run), (banked: 5, capped: true));
  });
}
