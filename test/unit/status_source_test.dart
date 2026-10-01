import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';

/// Un statut retient ce qui l'a posé, et ne rejoint qu'une entrée de même
/// statut et de même source (spec P-43 E0, D36, §4.1 à §4.3).
void main() {
  StatusEffect might(int value, int duration, {String? sourceId}) =>
      StatusEffect(
        id: 'might',
        name: 'Puissance',
        type: StatusType.buff,
        value: value,
        duration: duration,
        sourceId: sourceId,
      );

  EntityStats hero([List<StatusEffect> statuses = const []]) => EntityStats(
        maxPv: 80,
        currentPv: 80,
        armure: 0,
        might: 0,
        statuses: statuses,
      );

  List<StatusEffect> mightOf(EntityStats stats) =>
      stats.statuses.where((s) => s.id == 'might').toList();

  final demonForm = StatusSource.card('demon_form');
  final armorRule = StatusSource.rule('armor');

  group('StatusSource', () {
    test('les six formes', () {
      expect(StatusSource.card('demon_form'), 'card:demon_form');
      expect(StatusSource.rule('armor'), 'rule:armor');
      expect(StatusSource.passive('rage'), 'passive:rage');
      expect(StatusSource.relic('shuriken'), 'relic:shuriken');
      expect(StatusSource.status('might_regen'), 'status:might_regen');
      expect(StatusSource.enemy('orc'), 'enemy:orc');
    });
  });

  group('addStatus', () {
    test('meme statut et meme source : une entree, valeurs additionnees, duree la plus longue', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(3, 1, sourceId: demonForm));

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 3);
      expect(mightOf(stats).single.duration, 4);
    });

    test('sources differentes : deux entrees, chacune sa duree', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(5, 1, sourceId: armorRule));

      expect(
        mightOf(stats).map((s) => (s.sourceId, s.value, s.duration)),
        [(demonForm, 2, 4), (armorRule, 5, 1)],
      );
    });

    // A1 : hors de la Puissance, rien ne bouge — les statuts sont posés sans
    // source et fusionnent entre eux comme avant.
    test('deux statuts sans source fusionnent comme avant', () {
      const poison = StatusEffect(
        id: 'poison',
        name: 'Poison',
        type: StatusType.debuff,
        value: 3,
        duration: 2,
      );
      final stats = hero().addStatus(poison).addStatus(poison);

      expect(stats.statuses, hasLength(1));
      expect(stats.statuses.single.value, 3 + 3);
      expect(stats.statuses.single.sourceId, isNull);
    });

    test('un statut sans source ne rejoint pas une entree qui en a une', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .addStatus(might(1, 1));

      expect(mightOf(stats), hasLength(2));
    });
  });

  group('combine', () {
    test('rend l effet inchange si les sources different', () {
      final combined = might(2, 4, sourceId: demonForm)
          .combine(might(5, 1, sourceId: armorRule));

      expect(combined.value, 2);
      expect(combined.duration, 4);
      expect(combined.sourceId, demonForm);
    });
  });

  group('lecture et vieillissement', () {
    test('effectiveMight somme les entrees de toutes les sources', () {
      final stats = hero([
        might(2, 4, sourceId: demonForm),
        might(5, 1, sourceId: armorRule),
      ]);

      expect(stats.effectiveMight, 2 + 5);
    });

    test('tickStatuses vieillit chaque entree separement, sa source avec elle', () {
      final stats = hero([
        might(2, 4, sourceId: demonForm),
        might(5, 1, sourceId: armorRule),
      ]).tickStatuses();

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.sourceId, demonForm);
      expect(mightOf(stats).single.duration, 3);
    });
  });

  group('JSON', () {
    test('aller-retour avec une source', () {
      final restored =
          StatusEffect.fromJson(might(2, 4, sourceId: demonForm).toJson());

      expect(restored.sourceId, demonForm);
      expect(restored.value, 2);
      expect(restored.duration, 4);
    });

    test('une sauvegarde sans la cle se relit sans source', () {
      final restored = StatusEffect.fromJson(const {
        'id': 'might',
        'name': 'Puissance',
        'type': 'buff',
        'value': 2,
        'duration': 4,
        'isStackable': true,
      });

      expect(restored.sourceId, isNull);
    });

    test('aucune cle ecrite sans source', () {
      expect(might(2, 4).toJson().containsKey('sourceId'), isFalse);
    });
  });

  group('la meme carte rejouee', () {
    // D36 : « la même carte rejouée s'additionne comme aujourd'hui ». La
    // source traverse le tic, que `tickStatuses` reconstruit par `copyWith`.
    test('deux Forme Demoniaque a un tic d ecart : une entree de 4', () {
      final stats = hero()
          .addStatus(might(2, 4, sourceId: demonForm))
          .tickStatuses()
          .addStatus(might(2, 4, sourceId: demonForm));

      expect(mightOf(stats), hasLength(1));
      expect(mightOf(stats).single.value, 2 + 2);
      expect(mightOf(stats).single.duration, 4);
    });
  });
}
