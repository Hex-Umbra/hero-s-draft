import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/enemy_intent.dart';
import 'package:roguelike_card_game/ui/widgets/hud/combat_side_panels.dart';
import 'package:roguelike_card_game/ui/widgets/hud/enemy_intents_panel.dart';

/// Les calculs du panneau des intentions ennemies : sa hauteur bornée, la
/// valeur de sa pastille compacte et la phrase de son infobulle.
void main() {
  final fr = lookupAppLocalizations(const Locale('fr'));
  final en = lookupAppLocalizations(const Locale('en'));

  EnemyIntent intent(IntentType type, int value) =>
      EnemyIntent(type: type, value: value);

  group('intentsPanelMaxHeight', () {
    test('le haut du panneau s\'arrête sous le compteur de tour', () {
      expect(CombatSidePanels.intentsPanelMaxHeight(600), 149);
      expect(CombatSidePanels.intentsPanelMaxHeight(768), 233);
      expect(CombatSidePanels.intentsPanelMaxHeight(1080), 389);
    });

    test('le haut ne dépasse pas le bas du compteur, plus la marge', () {
      for (final h in [600.0, 768.0, 1080.0]) {
        final top = h -
            CombatSidePanels.intentsPanelBottom -
            CombatSidePanels.intentsPanelMaxHeight(h);
        expect(
          top,
          h / 2 +
              CombatSidePanels.turnCounterBottomFromMiddle +
              CombatSidePanels.intentsPanelMargin,
        );
      }
    });

    test('un écran trop bas garde la hauteur minimale', () {
      expect(
        CombatSidePanels.intentsPanelMaxHeight(400),
        CombatSidePanels.intentsPanelMinHeight,
      );
    });
  });

  group('compactValue', () {
    test('une attaque montre ses dégâts nus', () {
      expect(EnemyIntentsPanel.compactValue(intent(IntentType.attack, 12)), '12');
    });

    test('la défense et le buff montrent un gain signé', () {
      expect(EnemyIntentsPanel.compactValue(intent(IntentType.defend, 10)), '+10');
      expect(EnemyIntentsPanel.compactValue(intent(IntentType.buff, 2)), '+2');
    });
  });

  group('explanation', () {
    test('chaque type d\'intention a sa phrase, avec le nom et la valeur', () {
      expect(
        EnemyIntentsPanel.explanation(
          fr,
          intent: intent(IntentType.attack, 25),
          enemyName: 'Gobelin',
        ),
        'À son tour, Gobelin attaquera le héros pour 25 dégâts.',
      );
      expect(
        EnemyIntentsPanel.explanation(
          fr,
          intent: intent(IntentType.attack, 1),
          enemyName: 'Gobelin',
        ),
        'À son tour, Gobelin attaquera le héros pour 1 dégât.',
      );
      expect(
        EnemyIntentsPanel.explanation(
          fr,
          intent: intent(IntentType.defend, 10),
          enemyName: 'Gobelin',
        ),
        'À son tour, Gobelin gagnera 10 d\'Armure.',
      );
      expect(
        EnemyIntentsPanel.explanation(
          en,
          intent: intent(IntentType.buff, 2),
          enemyName: 'Goblin',
        ),
        'On its turn, Goblin will gain 2 Might.',
      );
    });

    test('les quatre paliers d\'attaque partagent la même phrase', () {
      for (final value in [4, 8, 15, 22]) {
        expect(
          EnemyIntentsPanel.explanation(
            en,
            intent: intent(IntentType.attack, value),
            enemyName: 'Goblin',
          ),
          'On its turn, Goblin will attack the hero for $value damage.',
        );
      }
    });

    test('un ennemi gelé dit qu\'il ne fera rien, à la place', () {
      expect(
        EnemyIntentsPanel.explanation(
          fr,
          intent: intent(IntentType.attack, 12),
          enemyName: 'Gobelin',
          skippedState: 'Gelé',
        ),
        fr.intentSkipped('Gelé'),
      );
    });

    test('sans intention, la phrase dit qu\'elle n\'est pas encore connue', () {
      expect(
        EnemyIntentsPanel.explanation(
          en,
          intent: null,
          enemyName: 'Goblin',
        ),
        en.intentWaitingExplanation('Goblin'),
      );
    });
  });
}
