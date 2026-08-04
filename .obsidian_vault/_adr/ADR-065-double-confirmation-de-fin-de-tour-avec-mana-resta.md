## 🛡️ ADR-065 : Double Confirmation de Fin de Tour avec Mana Restant (v0.2.6)

### Statut
✅ Accepté & Implémenté (v0.2.6)

### Contexte
Dans les jeux de cartes et roguelike deckbuilders, passer son tour accidentellement alors qu'il reste de l'énergie ou des cristaux de mana non consommés est une source majeure de frustration pour le joueur. Auparavant, le clic sur le bouton "Fin de tour" passait le tour instantanément s'il restait du mana, sans aucune garde-fou.

### Décision
- Introduire une garde-fou d'avertissement ("remainingManaWarning") lorsque le joueur tente de finir son tour alors que son mana actuel est supérieur à 0.
- Implémenter ce garde-fou sous la forme d'un panneau d'avertissement affiché au-dessus du bouton de fin de tour.
- Demander une double confirmation : le premier clic intercepte l'action et affiche l'alerte locale, et le second clic consécutif valide définitivement la fin du tour.
- Réinitialiser cet état d'avertissement de manière dynamique si le joueur décide de jouer une carte (`onPlayCard`), ou lorsqu'un nouveau tour joueur débute (`_startPlayerNewTurn()`), pour éviter d'exiger une double confirmation inutile s'il a consommé tout son mana par la suite.

### Preuves dans le code
- [app_en.arb](../../lib/l10n/app_en.arb) & [app_fr.arb](../../lib/l10n/app_fr.arb) : Ajout de la clé bilingue `remainingManaWarning`.
- [game_screen.dart](../../lib/ui/screens/game_screen.dart) :
  - Ajout de la variable d'état local `bool _showRemainingManaWarning = false;`.
  - Intégration de la logique de validation et de double clic dans le callback `onPressed` du bouton de fin de tour.
  - Réinitialisation de `_showRemainingManaWarning` dans `_startPlayerNewTurn()` et `onPlayCard`.

### Conséquences
- ✅ **Sécurité UX accrue** : Élimination des passes de tour involontaires avec du mana disponible.
- ✅ **Comportement intuitif** : Le message d'avertissement s'affiche au même emplacement que l'avertissement de mana vide, offrant une cohérence visuelle.
- ✅ **Zéro Régression** : La suite de tests unitaires (108/108) et l'analyse statique du linter sont validées avec succès.
