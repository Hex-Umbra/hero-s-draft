# Menu de pause sur l'écran de la carte — Design

## Contexte et objectif

`GameScreen` (l'écran de combat) dispose déjà d'un menu de pause (`PauseDialog`) accessible via une icône flottante, avec deux actions : reprendre, ou retourner au menu principal. `MapScreen` (l'écran de la carte du monde) n'a aucun équivalent : le bouton/geste retour du système ferme directement l'écran sans confirmation, et il n'existe aucun moyen d'accéder au menu principal depuis la carte autrement qu'en tuant l'application.

Objectif : ajouter un menu de pause sur `MapScreen`, réutilisant `PauseDialog` tel quel, et faire en sorte que le bouton/geste retour ouvre ce menu au lieu de fermer l'écran.

## Décisions validées

1. **Portée** : réutilisation minimale de `PauseDialog` existant (mêmes boutons "Reprendre" / "Retour au menu principal"), pas de menu enrichi spécifique à la carte (pas de sauvegarde manuelle, pas de réglages, pas de raccourcis).
2. **Comportement du bouton retour** : le bouton physique Android / le geste retour du système ouvre le menu de pause au lieu de fermer l'écran directement.

## Design

### Composants touchés

- **`lib/ui/widgets/hud/dialogs/pause_dialog.dart`** — **aucune modification**. Le widget est déjà générique (deux `VoidCallback`, pas de logique de combat en dur) et convient tel quel.
- **`lib/ui/screens/map_screen.dart`** — seul fichier modifié :
  1. Ajout d'une icône de pause (`Icons.pause_circle_outline`) dans `actions:` de l'`AppBar` existant, à côté du `GoldIndicator` déjà présent.
  2. Passage de `canPop: false` et `onPopInvokedWithResult: (didPop, result) { if (!didPop) _showPauseMenu(); }` à `ScreenScaffold` (ces deux paramètres existent déjà sur `ScreenScaffold` et sont utilisés selon ce même schéma ailleurs dans le code, ex. `rest_screen.dart`, `event_screen.dart`) — aucune modification de `ScreenScaffold` nécessaire.
  3. Ajout d'une méthode privée `_showPauseMenu()` sur le `State` de `MapScreen` :
     ```dart
     void _showPauseMenu() {
       PauseDialog.show(
         context,
         onResume: () => Navigator.of(context).pop(),
         onExit: () => Navigator.of(context).popUntil((route) => route.isFirst),
       );
     }
     ```
     Contrairement à `GameScreen`, il n'y a pas d'appel `pauseEngine()`/`resumeEngine()` : `MapScreen` est un écran Flutter pur, sans instance Flame `Game`, donc rien à mettre en pause côté rendu.

### Comportement de sortie

"Retour au menu principal" ramène directement à l'écran d'accueil (`popUntil isFirst`), identique au comportement en combat. Aucune interaction avec le système de sauvegarde n'est nécessaire : la run n'est pas terminée, et le dernier checkpoint autosauvegardé (système de sauvegarde livré précédemment) reste valide — le joueur retrouve son état exact via "Continuer" au prochain lancement.

### Localisation

Les clés `l10n.pauseTitle`, `l10n.resumeCombat`, `l10n.backToMainMenu` existantes sont réutilisées telles quelles. `l10n.resumeCombat` ("Reprendre le combat" / équivalent) est à consonance combat ; il n'y a pas de combat en cours sur la carte, mais l'écart est mineur (le label reste globalement compréhensible en contexte "reprendre l'action en cours") et introduire une nouvelle clé dupliquée uniquement pour ce nuance de texte serait disproportionné pour ce module. Aucune clé n'est ajoutée ou modifiée.

## Tests

Ajout de tests widget dans `test/widget/map_screen_test.dart` (fichier existant) couvrant :
- Tap sur l'icône de pause ouvre `PauseDialog`.
- Tap sur "Reprendre" ferme le dialogue sans navigation supplémentaire.
- Simulation du bouton retour système (`didPop: false` via `PopScope`) ouvre le dialogue au lieu de fermer l'écran.
- Tap sur "Retour au menu principal" déclenche `popUntil isFirst`.

## Hors scope

- Pas de sauvegarde manuelle depuis le menu de pause.
- Pas d'accès aux réglages depuis ce menu.
- Pas de changement à `PauseDialog` ou à `GameScreen`.
- Pas de nouvelle clé de localisation.
