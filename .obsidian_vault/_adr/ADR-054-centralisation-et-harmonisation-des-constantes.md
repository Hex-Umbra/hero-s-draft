## 🛠️ ADR-054 : Centralisation et Harmonisation des Constantes (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. De nombreux délais temporels liés au déroulement des phases de combat (timing après dash, riposte, résolution des intentions, ticks de statut) étaient codés en dur avec des `Duration(milliseconds: ...)` au sein du orchestrateur de jeu `HerosDraftGame`.
2. Les configurations visuelles et physiques de l'affichage des textes flottants (`FloatingText`), comme les tailles de police pour les différents types de texte (dégâts, critique, poison, bouclier), les durées d'animations (fondu, échelle, dérive, suppression) et les calculs physiques de drift (angle de rotation de naissance, vitesse de dérive X, drift Y d'oscillation), étaient également codés en dur avec des magic numbers.
3. Ces valeurs disséminées nuisaient à la maintenance à long terme, rendant difficile l'ajustement global de la vitesse de jeu ou de la physique des textes flottants de dégâts.

### Décision
1. **Centralisation dans `GameConstants`** : Regrouper toutes les constantes concernées au sein de `lib/game/game_constants.dart` sous la forme de champs statiques typés et documentés (ex: `combatDelayHeroDashMs`, `floatingTextFontSizeCrit`, etc.).
2. **Refactoring de `HerosDraftGame`** : Remplacer toutes les instanciations de `Duration` utilisant des valeurs entières littérales dans le code de combat par des références aux constantes de délais de `GameConstants`.
3. **Refactoring de `FloatingText`** : Remplacer l'intégralité des nombres magiques de taille, durée, et drift par les nouvelles constantes de `GameConstants`, standardisant ainsi les trajectoires et l'affichage visuel des nombres flottants.

### Preuves dans le code
- [game_constants.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/game_constants.dart) : Déclaration et documentation détaillée des constantes sous `GameConstants`.
- [floating_text.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/floating_text.dart) : Utilisation des constantes `GameConstants.floatingText*`.
- [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) : Utilisation des constantes `GameConstants.combatDelay*Ms`.

### Conséquences
- ✅ **Éradication de la Dette Technique (Nombres Magiques)** : Disparition complète des valeurs littérales en dur liées aux timings de combat et à l'affichage des textes flottants, améliorant drastiquement la maintenabilité et la lisibilité du code.
- ✅ **Facilité d'Ajustement du Gameplay** : La modification globale du rythme du jeu (vitesse des tours, durée des ripostes) ou du rendu visuel des dégâts se fait désormais en un point unique (`GameConstants`).
- ✅ **Homogénéité Visuelle** : Uniformisation parfaite des trajectoires et des tailles des textes de dégâts.
- ✅ **Zéro Régression** : Les tests unitaires (108/108) passent sans modification de comportement fonctionnel et `dart analyze` ne signale aucune erreur.
