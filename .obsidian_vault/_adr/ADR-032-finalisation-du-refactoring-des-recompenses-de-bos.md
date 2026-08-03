## 🏆 ADR-032 : Finalisation du Refactoring des Récompenses de Boss (Boss Rewards Finalization)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour finaliser le refactoring des récompenses post-combat initié dans la version 0.0.94, il était nécessaire d'intégrer pleinement les comportements et mécaniques propres aux 3 boss thématiques situés à l'étage 9 de la carte. Précédemment, les récompenses n'offraient pas le niveau d'interactivité requis (les tirages de cartes de boss n'avaient pas d'écran dédié et les probabilités de reliques étaient fixes). Le but était de concevoir un écran de sélection de cartes complet et obligatoire pour le Boss 1, de doubler les récompenses d'or et d'XP pour le Boss 2, et de concevoir une progression probabiliste de drop de relique dynamique selon l'acte en cours pour le Boss 3.

### Décision
1. **Écran de Clonage Dédié pour Boss 1 (`BossCardDraftScreen`)** :
   - Créer `BossCardDraftScreen` dans `lib/ui/screens/boss_card_draft_screen.dart` s'appuyant sur le widget unifié `UiCard` contraint dans des dimensions fixes de `140x220`.
   - Proposer au joueur 5 cartes aléatoires issues de son propre deck actuel.
   - Forcer le joueur à sélectionner **exactement 2 cartes** à dupliquer/cloner dans son deck avant d'activer le bouton de validation.
   - Intégrer cet écran via des redirections de navigation appropriées depuis `GameScreen`.
2. **Triplement des Récompenses Boss 2 (XP/Or x3 + Carte Aléatoire)** :
   - Tripler à la fois l'Or et l'XP de combat calculés lors de la victoire contre le boss du nœud central (x=1) dans `RewardController`.
   - Octroyer au joueur une carte aléatoire du jeu tirée du catalogue général, en excluant les cartes uniques de classe et les cartes de statut.
   - Mettre à jour les tooltips dans `MapNodeWidget` et les étiquettes de légende de `MapLegend` en français ("Boss (XP & Or x3 + Carte)") et en anglais ("Boss (3x XP & Gold + Card)").
3. **Chances de Reliques Évolutives Boss 3** :
   - Fixer la chance de base Légendaire à **10.0%** (uniquement scalable par la statistique de Chance/Luck du joueur).
   - Diminuer la chance Commune de base démarrant à **40.0%** de **10% par acte** : `commonChance = max(0.0, 40.0 - (act - 1) * 10.0)`.
   - Distribuer proportionnellement la baisse de chance Commune (soit `90.0 - commonChance`) entre Uncommon, Rare, et Epic selon leurs parts relatives (respectivement 20/85, 35/85, 30/85), plus le bonus de luck.
   - Si la chance Commune atteint 0.0% (à l'Acte 5), commencer à diminuer la chance d'Atypique (Uncommon) de **10% par acte** à partir de sa base maximale de `(20.0 / 85.0) * 90.0` : `baseUncommonChance = max(0.0, maxUncommonBase - (act - 5) * 10.0)`.
   - Distribuer proportionnellement cette réduction de Uncommon (soit `90.0 - baseUncommonChance`) vers Rare et Epic selon leurs parts relatives de base (35/65, 30/65).
   - Logique de tirage cumulée intégrée au sein de `RewardController`.
4. **Correction du Tirage de Relique pour Boss 1 et Boss 2** :
   - Restreindre le tirage de relique dans le pipeline de récompenses aux seuls nœuds Élite ou Boss de type `BossRewardType.improvedRelic` (Boss 3).
   - Précédemment, la condition vérifiait simplement si le nœud était de type `MapNodeType.boss` sans valider son `bossRewardType`, ce qui faisait que Boss 1 (choix de cartes) et Boss 2 (Double XP & Or) tiraient et attribuaient par erreur une relique au joueur.
   - Corriger cette logique à la ligne 100 (lignes 100-101) de `lib/game/controllers/reward_controller.dart` :
     ```dart
     if (currentNode.type == MapNodeType.elite || (currentNode.type == MapNodeType.boss && isImprovedRelic)) {
     ```

### Preuves dans le code
- `lib/ui/screens/boss_card_draft_screen.dart` : Création de la vue GridView responsive, de la gestion de sélection de 5 cartes du deck pour en cloner 2, et du bouton de confirmation.
- `lib/game/controllers/reward_controller.dart` : Calcul conditionnel des chances de reliques Boss 3 (`isImprovedRelic`) indexé sur l'Act, restriction du tirage de relique aux seuls nœuds Élite ou Boss 3, application du multiplicateur x3 pour l'XP et l'Or sur Boss 2, et distribution d'une carte aléatoire du jeu hors uniques/statuts.
- `lib/ui/widgets/map/map_legend.dart` & `lib/ui/widgets/map/map_node_widget.dart` : Affichage localisé des tooltips et légende ("Boss (XP & Or x3 + Carte)" / "Boss (3x XP & Gold + Card)").

### Conséquences
- ✅ **Game Feel Premium** : Le joueur fait face à des opportunités de choix marquantes pour le Boss 1, à une économie relancée pour le Boss 2, et à des drops haut de gamme cohérents avec l'Acte pour le Boss 3.
- ✅ **Correction de la Distribution de Butin** : Éradication du bug de distribution indue de reliques sur les Boss 1 et 2, garantissant l'intégrité de l'économie des récompenses de fin d'acte et l'alignement sur les spécifications de design initiales.
- ✅ **Absence de Régression Technique** : Intégration transparente au sein du `RewardController` existant.
- ✅ **Respect de la Règle i18n** : Traduction intégrale des dialogues et tooltips.
