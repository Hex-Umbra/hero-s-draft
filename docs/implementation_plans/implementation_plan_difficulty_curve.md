# Équilibrage de la Courbe de Difficulté des Combats

Ce plan décrit l'implémentation d'un système de budget unifié basé sur le **score de menace final (`CombatRating`)** des ennemis et une **formule d'équilibrage hybride** (progression linéaire combinée à un ajustement dynamique selon la puissance réelle du joueur).

## User Review Required

> [!IMPORTANT]
> Voici les détails de la formule mathématique hybride validée :
> 
> 1. **Puissance Réelle du Joueur (`PlayerPower`)** :
>    $$\text{PlayerPower} = \text{maxHP} + (\text{attaque} \times 10) + (\text{maxMana} \times 15) + (\text{relicsCount} \times 5)$$
> 
> 2. **Puissance Théorique Attendue (`ExpectedPower`)** :
>    $$\text{ExpectedPower} = 145 + [(\text{playerLevel} - 1) \times 15] + [(\text{act} - 1) \times 20]$$
> 
> 3. **Budget de Base théorique (`BaseBudget`)** :
>    $$\text{BaseBudget} = 40 + [(\text{playerLevel} - 1) \times 10] + [(\text{act} - 1) \times 25]$$
> 
> 4. **Calcul du Budget Final du Combat (`FinalBudget`)** :
>    $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
>    $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$
>    $$\text{FinalBudget} = \text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}$$
>    *(Avec `NodeMultiplier` = 1.0 pour normal, 1.5 pour élite, 2.0 pour boss)*

## Proposed Changes

### 1. Data Layer & Models

#### [MODIFY] [combat_state.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev and Godot/Roguelike Card Game/roguelike_card_game/lib/models/combat_state.dart)
Ajouter le champ `pendingEnemies` pour stocker la file de réserve des ennemis.
```dart
class CombatState {
  final List<EnemyInstance> enemies; // Ennemis actifs à l'écran (max 5)
  final List<EnemyInstance> pendingEnemies; // Ennemis en réserve
  final List<EnemyInstance> defeatedEnemies;
  ...
```
Mettre à jour `copyWith`, `fromJson` et `toJson` pour supporter `pendingEnemies`.

### 2. State & Control Layer

#### [MODIFY] [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev and Godot/Roguelike Card Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)
1. Extraire les coefficients de mise à l'échelle (HP et dégâts) dans des variables statiques ou des méthodes d'aide accessibles par le générateur de combat.
2. Adapter `initializeCombat` :
   * Appeler le générateur de combat en passant l'acte, le niveau de run, le niveau du joueur et les stats du joueur pour le calcul du budget final.
   * Prendre les 5 premiers ennemis générés et les mettre dans `enemies` (actifs), et le reste dans `pendingEnemies` (réserve).
3. Mettre à jour `_cleanDeadEnemies` :
   * Quand un ennemi meurt, si `enemies.length < 5` et `pendingEnemies` n'est pas vide, transférer le premier ennemi de réserve vers la liste active (et lancer `_rollIntent` sur lui).
   * La victoire est prononcée uniquement si la liste active ET la réserve sont vides.

### 3. Generation System

#### [MODIFY] [encounter_system.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev and Godot/Roguelike Card Game/roguelike_card_game/lib/game/systems/encounter_system.dart)
Refondre le générateur pour utiliser le budget unifié hybride :

##### 1. Calcul du Score de Menace (`CombatRating`)
Pour chaque ennemi disponible, on calcule sa `CombatRating` exacte en simulant ses statistiques finales (HP, Armure, Dégâts, Critique) après application des multiplicateurs de combat (niveau, acte, élite/boss) :
$$\text{CombatRating} = (\text{tier} \times 10) + \text{HP\_Scalé} + \text{Armure\_Scalée} + \text{Dégâts\_Scalés} \times (1 + \frac{\text{critChance}}{100})$$

##### 2. Sélection Procedurale (Strictement inférieure ou égale au budget)
1. Commencer avec `remainingBudget = FinalBudget`.
2. Tant que `remainingBudget > 0` et que le nombre de slots max (limité par exemple à 10 au total, réserve comprise) n'est pas dépassé :
   * Filtrer les ennemis disponibles ayant `CombatRating <= remainingBudget`.
   * Si la liste est vide (aucun ennemi restant ne rentre dans le budget), s'arrêter.
   * Choisir un ennemi aléatoire parmi les candidats valides, le rajouter à la liste globale du combat, et déduire sa `CombatRating` de `remainingBudget`.
3. S'assurer d'avoir au moins 1 ennemi (fallback sur le Slime/Gobelin de base si le budget est trop restreint pour contenir même le plus petit ennemi).

## Verification Plan

### Automated Tests
* Créer des tests unitaires dans [test/encounter_system_test.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev and Godot/Roguelike Card Game/roguelike_card_game/test/encounter_system_test.dart) pour valider :
  * Le bon calcul des `CombatRating` selon le niveau de mise à l'échelle.
  * Que la somme des `CombatRating` respecte strictement le budget maximum alloué au combat (somme <= budget).
  * Le fonctionnement des vagues (transfert de `pendingEnemies` vers `enemies` lors de la mort d'un ennemi actif).

### Manual Verification
* Lancer des combats d'Élite / de Boss dans différents actes et vérifier visuellement l'arrivée progressive des renforts à l'écran lors des éliminations.
