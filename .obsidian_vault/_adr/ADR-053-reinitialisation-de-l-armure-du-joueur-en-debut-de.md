## 🛡️ ADR-053 : Réinitialisation de l'Armure du Joueur en Début de Tour & Suppression de l'Animation (v0.1.8)

### Statut
✅ Accepté & Implémenté (v0.1.8)

### Contexte
1. Auparavant, l'armure (`armure`) du joueur persistait indéfiniment d'un tour sur l'autre s'il ne subissait pas d'attaque ennemie. Cela posait un problème d'équilibrage majeur : des reliques (comme le Talisman de Fer `iron_talisman`) ou des passifs de classe (tels que la régénération d'armure du Paladin `regenArmor` ou l'armure de début de tour du Berserker `berserkerArmor`) généraient de l'armure cumulative à chaque début de tour, permettant au joueur d'accumuler une armure infinie et de devenir virtuellemment invincible.
2. Pour corriger cela, l'armure du joueur devait être remise à 0 au début de chaque tour.
3. Néanmoins, en effectuant cette réinitialisation (par exemple, passage de 15 d'armure à 0 d'armure au démarrage du tour), la mise à jour des statistiques de l'entité (`HeroCard.updateStats()`) dans la couche graphique de Flame interprétait ce changement d'armure comme une perte standard (similaire à des dégâts). Cela déclenchait à tort une animation de tremblement de bouclier (`shieldHitAnimation`) et l'apparition de textes flottants négatifs d'armure (ex: "-15 🛡️"), induisant faussement le joueur en erreur en lui faisant croire qu'il venait d'être touché. Cette pollution visuelle transitoire devait impérativement être supprimée lors de la phase de reset.

### Décision
1. **Reset d'Armure Métier** : Modifier `RunController.startTurn()` pour fixer `armure: 0` dès le premier bloc de mise à jour de l'état `state.copyWith(...)`. Ce reset est effectué en amont afin que les reliques de début de tour (`RelicTrigger.startOfTurn`) et les effets de statut (comme `armor_regen`) s'exécutent immédiatement après, garantissant que le joueur commence son tour uniquement avec l'armure valide octroyée par ses bonus.
2. **Drapeau de Suppression d'Animation** : Ajouter une variable booléenne transitoire `suppressArmorChangeAnimation` (valeur par défaut `false`) au sein du composant de rendu `HeroCard`.
3. **Suppression Conditionnelle des Popups** : Dans la méthode de rafraîchissement visuel `HeroCard.updateStats()`, soumettre le déclenchement visuel de la perte d'armure (secousses `shieldHitAnimation` et instantation de `FloatingText` négatifs) à la condition `if (!suppressArmorChangeAnimation)`. En fin d'exécution de `updateStats()`, réinitialiser systématiquement `suppressArmorChangeAnimation` à `false`.
4. **Activation de la Suppression** : Dans `game_screen.dart` lors de l'appel à `_startPlayerNewTurn()`, forcer `_game.heroCard?.suppressArmorChangeAnimation = true;` juste avant de notifier le `runProvider` de démarrer le nouveau tour (`startTurn()`). Cela garantit que la mise à jour graphique consécutive au reset à 0 ignore les effets visuels de hit.

### Preuves dans le code
- `lib/game/controllers/run_controller.dart` : Réinitialisation à 0 de l'armure dans `startTurn()` avant l'itération des reliques et buffs.
- `lib/game/components/entities/hero_card.dart` : Variable `suppressArmorChangeAnimation` et embranchement conditionnel pour le rendu de perte de bouclier dans `updateStats()`.
- `lib/ui/screens/game_screen.dart` : Assignation à `true` de `suppressArmorChangeAnimation` dans `_startPlayerNewTurn()`.

### Conséquences
- ✅ **Intégrité de l'Équilibrage de Combat** : L'armure est correctement restreinte au tour en cours. La synergie avec les reliques et statuts de début de tour fonctionne de manière prévisible sans accumulation infinie exploitée.
- ✅ **Clarté Visuelle & Propreté des Transitions** : Les tours commencent sereinement sans faux popups négatifs ni animations d'impact parasites. La transition de tour est esthétique et fluide.
- ✅ **Robustesse et Qualité du Code** : La modification respecte le découplage MVC/Flux. Les tests automatisés continuent de passer avec succès (108/108 tests valides) et le linter est impeccable.
