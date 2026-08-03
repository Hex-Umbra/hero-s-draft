## 🐛 ADR-073 : Réactivité du Bouton « Continuer » de `HomeScreen` après Retour via `popUntil` (branche `fix/combat_scaling`)

### Statut
✅ Accepté, Implémenté & **Mergé vers `main`** (branche `fix/combat_scaling`, commit `17564b4`, mergé aux côtés d'ADR-072 via PR #22, commit de merge `b32e9e9`, 2026-07-26).

### Contexte
`HomeScreen._continueGame()` et `_startNewGame()` naviguent vers `MapScreen`/`ClassSelectionScreen` via `Navigator.push`, mais les deux points de retour vers l'accueil — le menu pause et l'écran de mort (`GameOverScreen`) — utilisent `Navigator.popUntil((route) => route.isFirst)` plutôt qu'un `push` qui recréerait l'écran. `HomeScreen` ne se reconstruit donc pas à son retour, et son `FutureProvider` sur `SaveService.hasSave()` n'était réévalué qu'à la création initiale du widget. Conséquence : le bouton « Continuer » pouvait afficher un état obsolète — rester visible après une défaite ayant effacé la sauvegarde, ou rester absent après le démarrage d'une nouvelle run — jusqu'à un redémarrage complet de l'application.

### Décision
`_continueGame()` et `_startNewGame()` attendent désormais (`await`) l'issue de leur `Navigator.push` respectif et appellent `setState(() {})` à son retour, forçant la reconstruction de `HomeScreen` et la réévaluation de `SaveService.hasSave()` quel que soit le chemin de retour emprunté (pop simple depuis un écran poussé, ou `popUntil` depuis la pause/la mort).

### Preuves dans le code
- `lib/ui/screens/home_screen.dart` : `await Navigator.push(...)` suivi de `setState(() {})` dans `_continueGame()` et `_startNewGame()`.
- `test/widget/home_screen_save_test.dart` (nouveau, 95 lignes) : couvre la réactivité du bouton après un retour simulé de pause et après une défaite.

### Conséquences
- ✅ **Bouton « Continuer » toujours synchronisé** avec l'état réel de la sauvegarde, sans nécessiter de redémarrage de l'application.
- ✅ **Aucune régression** : le chemin de navigation initial (`push`) n'est pas modifié, seule la réaction au retour change.
- ✅ **Mergé vers `main`** dans la même PR (#22) qu'ADR-072.
