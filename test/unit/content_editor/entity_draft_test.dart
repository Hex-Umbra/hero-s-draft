import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';

import 'fixtures.dart';

/// Un brouillon minimal pour n'importe quelle categorie, avec sa prose
/// bilingue propre : c'est le descripteur qui dit lesquelles.
EntityDraft draftFor(EntityDescriptor descriptor, {String? mechanics}) =>
    EntityDraft(
      descriptor: descriptor,
      id: 'entite_de_test',
      bilingual: {
        for (final base in descriptor.bilingualBases) ...{
          '${base}_fr': 'texte',
          '${base}_en': 'text',
        },
      },
      mechanics: mechanics ?? descriptor.template,
    );

void main() {
  test('le document porte l identifiant, la prose, puis la mecanique', () {
    // L'ordre des fichiers existants, donc le diff minimal d'une
    // modification. `Map` et `jsonDecode` preservent l'ordre d'insertion :
    // c'est ce que cette assertion fixe.
    expect(
      fixtureRelicDraft().compose().keys.toList(),
      [
        'id',
        'name_en',
        'name_fr',
        'description_en',
        'description_fr',
        'trigger',
        'effectType',
        'value',
        'rarity',
        'emoji',
      ],
    );
  });

  group('le formulaire fait autorite sur le corps JSON', () {
    test('une prose doublee dans le corps ne gagne pas', () {
      // Le corps est etale **apres** la prose : sans retrait prealable, un
      // `name_fr` vide colle dans la boite JSON ecraserait le champ que la
      // famille 5 vient de juger non vide, et l'entite serait ecrite sans nom.
      final composed = fixtureRelicDraft(
        mechanics: '{"name_fr": "", "description_en": "vole la place", '
            '"trigger": "startOfCombat", "effectType": "gain_armor", '
            '"value": 5, "rarity": "common"}',
      ).compose();

      expect(composed['name_fr'], 'Talisman de fer');
      expect(composed['description_en'], 'Gain 5 armor at the start of combat.');
      // Et le doublon ne survit pas non plus en fin de document : il est
      // retire, pas seulement recouvert.
      expect(
        composed.keys.where((k) => k == 'name_fr'),
        hasLength(1),
      );
    });

    test('un identifiant double dans le corps ne gagne pas', () {
      // Le validateur refuse deja un `id` different (famille 3) ; ce qui est
      // fixe ici, c'est que la valeur ecrite vient du triangle d'identite,
      // qui decide aussi du **chemin** du fichier.
      final composed = fixtureRelicDraft(
        mechanics: '{"id": "talisman_de_fer", "trigger": "startOfCombat", '
            '"effectType": "gain_armor", "value": 5, "rarity": "common"}',
      ).compose();

      expect(composed['id'], 'talisman_de_fer');
      expect(composed.keys.first, 'id');
      expect(composed.keys.where((k) => k == 'id'), hasLength(1));
    });
  });

  test('le chemin d image n existe que pour les categories en dossier', () {
    for (final descriptor in kEntityDescriptors.values) {
      final composed = draftFor(descriptor).compose();
      final key = descriptor.imagePathKey;

      if (key == null) {
        // Les cinq categories a plat. L'assertion qui compte est que
        // `compose()` ait seulement **rendu** : le marqueur null-aware est
        // pose cote CLE, et la forme cote valeur que propose `dart fix`
        // (`imagePathKey!: ?imagePath`) leve ici, le `!` s'evaluant avant que
        // le `?` ne puisse court-circuiter.
        expect(composed.containsKey('classCard'), isFalse,
            reason: descriptor.label);
        expect(composed.containsKey('spritePath'), isFalse,
            reason: descriptor.label);
      } else {
        // Un chemin d'asset complet, derive de l'identifiant : c'est
        // exactement ce qu'une saisie manuelle rate.
        expect(
          composed[key],
          descriptor.imagePathOf('entite_de_test'),
          reason: descriptor.label,
        );
        // Et il a le dernier mot : l'outil le calcule, on ne le saisit pas.
        expect(composed.keys.last, key, reason: descriptor.label);
      }
    }
  });

  test('le chemin du fichier suit le triangle d identite', () {
    final card = kEntityDescriptors[EntityCategory.card]!;
    expect(draftFor(card).path, 'assets/data/cards/entite_de_test.json');
    expect(
      EntityDraft(
        descriptor: card,
        id: 'smite',
        heroClass: 'paladin',
        bilingual: const {},
        mechanics: card.template,
      ).path,
      'assets/data/classes/paladin/cards/smite.json',
    );
  });
}
