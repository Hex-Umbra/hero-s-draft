# Plan d'Implémentation Unifié - Refactoring de la Rareté, Équilibrage des Cartes & Système de Forge

Ce document définit un plan d'implémentation complet et harmonisé pour les systèmes de combat et de cartes de *Hero's Draft*. Il combine l'activation des effets élémentaires, le refactoring de la rareté dynamique, l'application des rééquilibrages de cartes et la refonte complète du système de la Forge.

---

## 🎯 1. Axe 1 : Activation et Résolution des Effets Élémentaires

Les statuts élémentaires (`burn`, `freeze`, `shock`) et le statut standard `vulnerable` doivent être pleinement intégrés dans les calculs de combat et nettoyés à chaque tour ou après résolution.

### A. Brûlure (`burn`)
* **Mécanique** : Inflige des dégâts de feu égaux à la valeur du statut au début du tour de la cible. Après l'application des dégâts, la valeur diminue de 1 et la durée diminue également de 1.
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `startEnemyTurn`, récupérer la somme des statuts `burn` actifs, l'appliquer comme dégâts (`updatedStats.takeDamage(burnDamage)`).
* **Code Cible - [entity_stats.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart)** :
  * Modifier `tickStatuses()` pour réduire de 1 la valeur du statut `burn` en plus de réduire sa durée.

### B. Gel (`freeze`)
* **Mécanique** : Réduit les dégâts de la prochaine attaque de l'ennemi de 50%. Après cette attaque, la durée du gel doit être décrémentée (et le statut retiré s'il tombe à 0).
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `resolveEnemyIntent`, sous le cas `IntentType.attack` :
    * Si l'ennemi possède le statut `freeze`, appliquer la réduction : `dmg = (intent.value * 0.5).round();`.
    * Décrémenter immédiatement la durée du gel de l'ennemi après cette résolution pour éviter que le gel n'affecte plusieurs attaques dans le même tour s'il n'avait qu'une durée de 1.

### C. Électrocution (`shock`)
* **Mécanique** : Ajoute la valeur du statut `shock` aux dégâts de chaque attaque directe subie par la cible. La durée diminue de 1 à la fin du tour.
* **Code Cible - [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart)** :
  * Dans `resolveCard`, case `damage` (pour cible unique et multi-cibles) :
    * Vérifier la présence de `shock` sur le défenseur et ajouter sa valeur : `dmg += shockStatus.value`.

### D. Vulnérable (`vulnerable`)
* **Mécanique** : Augmente les dégâts subis par la cible de 50% (+50% dégâts reçus).
* **Code Cible - [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart)** :
  * Lors du calcul des dégâts reçus par l'ennemi, appliquer le multiplicateur si l'ennemi est vulnérable : `dmg = (dmg * 1.5).round();`.
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `resolveEnemyIntent`, sous le cas `IntentType.attack`, si le héros possède le statut `vulnerable`, les dégâts infligés au héros sont augmentés : `dmg = (dmg * 1.5).round();`.

---

## 🧠 2. Axe 2 : Système de Rareté Dynamique & Fusion Dual-Path

La rareté d'une carte n'est plus statique et liée à son modèle de base (`CardData.rarity`), mais devient une propriété d'instance (`CardInstance.rarity`).

### A. Rareté comme Multiplicateur de Statistique (Stats de base)
Chaque carte possède des effets dont la valeur s'adapte à sa rareté et à son niveau :
$$\text{scaledValue} = \text{round}\left(\text{baseValue} \times \text{rarityMultiplier} \times \left(1 + (\text{level} - 1) \times 0.5\right)\right)$$

| Rareté | Multiplicateur |
| :--- | :---: |
| **Commun (Common)** | `1.0x` |
| **Peu Commun (Uncommon)** | `1.2x` |
| **Rare** | `1.4x` |
| **Épique (Epic)** | `1.6x` |
| **Légendaire (Legendary)** | `2.0x` |

### B. Double Voie de Fusion (Merge) dans [deck_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/deck_controller.dart)
Le niveau d'une carte augmente **uniquement via fusion** (la Forge ne permet plus de monter le niveau directement, éliminant le risque de sur-optimisation gratuite).
1. **Fusion de Niveau (Forge)** : Si le joueur fusionne 3 exemplaires de **même Rareté** et de **même Niveau** (inférieur à 3), la carte résultante passe au **Niveau + 1** (la rareté reste identique).
2. **Fusion de Rareté (Évolution)** : Si le joueur réunit 3 exemplaires de **Niveau 3** (Max) d'une **même Rareté**, ils fusionnent pour donner 1 exemplaire de **Niveau 1** de la **Rareté supérieure** (ex: Commun Lvl 3 x3 ➔ Peu Commun Lvl 1 x1).
* *Note sur les améliorations* : Lors d'une fusion, la carte résultante hérite des améliorations de forge appliquées aux cartes d'origine (jusqu'à sa limite maximale de capacité).

---

## 🛠️ 3. Axe 3 : Nouveau Système de Forge Découplé

La Forge ne permet plus de monter les niveaux des cartes. Elle offre désormais des **bonifications uniques et variées** pour rendre chaque carte unique, sous contrainte d'une limite d'améliorations.

### A. Capacité d'Améliorations à la Forge
Chaque carte possède une capacité maximale d'améliorations de forge qui dépend de sa rareté actuelle et d'une limite de base définie dans le JSON :
$$\text{maxForgeUpgrades} = \text{baseMaxForgeUpgrades} + \text{rarityIndex}$$

| Rareté actuelle | Bonus de Capacité | Capacité Totale (si base = 1) |
| :--- | :---: | :---: |
| **Commun (Common)** | `+0` | `1` |
| **Peu Commun (Uncommon)** | `+1` | `2` |
| **Rare** | `+2` | `3` |
| **Épique (Epic)** | `+3` | `4` |
| **Légendaire (Legendary)** | `+4` | `5` |

### B. Options d'Améliorations Variées (Effets Additionnels)
Lorsqu'un joueur choisit d'améliorer une carte à la Forge, le jeu lui propose **3 options aléatoires** parmi celles qui sont compatibles avec sa carte :

1. **Tranchant (Sharp)** : Ajoute `+2 Dégâts` (uniquement sur les cartes infligeant des dégâts).
2. **Endurci (Hardened)** : Ajoute `+2 Armure` (uniquement sur les cartes octroyant de l'armure).
3. **Véloce (Quick)** : Piochez 1 carte supplémentaire lors du jeu de cette carte.
4. **Économe (Eco)** : Restitue 1 point de Mana lors du jeu de cette carte.
5. **Persistant (Enduring)** : La carte perd l'effet d'épuisement (`isExhaust: false` forcé, uniquement pour les cartes ayant `isExhaust: true` d'origine et hors cartes Pouvoir).
6. **Brûlant (Burning)** : Applique 1 Brûlure (valeur 1, durée 1) (uniquement sur cartes d'Attaque).
7. **Congelant (Freezing)** : Applique 1 Gel (valeur 1, durée 1) (uniquement sur cartes d'Attaque).
8. **Surchargé (Shocking)** : Applique 1 Électrocution (valeur 1, durée 1) (uniquement sur cartes d'Attaque).

---

## ⚖️ 4. Équilibrage des Cartes de Base (cards.json)

Les cartes ciblées reçoivent les ajustements de base suivants, qui se combineront ensuite avec les multiplicateurs de rareté et les améliorations de la forge :

1. **`holy_shield`** (Paladin - Rare de base) :
   * **Coût** : 1 | **Effets** : 8 Armure, 2 Soin | **Modif** : Ajout de `"isExhaust": true`
   * *Synergie Forge* : Le joueur peut choisir d'appliquer l'amélioration de forge **Persistant** (Enduring) pour supprimer cet Exhaust, rendant la carte infiniment jouable dans un combat au prix d'une fente d'amélioration.
2. **`warcry`** (Global - Épique de base) :
   * **Coût** : 2 | **Effets** : 4 Dégâts de zone (AOE), 4 Armure.
3. **`mana_surge`** (Mage - Peu Commun de base) :
   * **Coût** : 0 | **Effets** : Gain de 1 Mana, Pioche 1 carte | **Modif** : `"isExhaust": true`
4. **`concentration`** (Global - Commun de base) :
   * **Coût** : 0 | **Effets** : Pioche 2 cartes | **Modif** : `"isExhaust": true`
5. **`poison_stab`** (Global - Commun de base) :
   * **Coût** : 1 | **Effets** : 5 Dégâts directs, 4 Poison (durée 3).

---

## 📂 5. Modifications Logiques et Modèles du Code

### Modèle `CardData` (`lib/models/data/card_data.dart`)
* Ajouter le champ `final int maxForgeUpgrades;` (par défaut `1`).
* Charger ce champ depuis le constructeur et `fromJson`.

### Modèle `CardInstance` (`lib/models/card_instance.dart`)
* Ajouter les champs :
  * `CardRarity rarity;` (dynamique, par défaut `data.rarity`).
  * `final List<String> forgeUpgrades;` (liste des identifiants d'améliorations appliquées).
* Mettre à jour `copyWith` et les constructeurs.
* Ajouter le getter de capacité :
  ```dart
  int get totalMaxForgeUpgrades => data.maxForgeUpgrades + rarity.index;
  ```

### Résolution des Effets (`lib/game/services/effect_resolver.dart`)
* Intégrer les bonus de forge appliqués à l'instance de carte jouée :
  * Si `forgeUpgrades` contient `'sharp'` : ajouter 2 aux dégâts.
  * Si `forgeUpgrades` contains `'hardened'` : ajouter 2 à l'armure.
  * Si `forgeUpgrades` contains `'quick'` : déclencher une pioche : `deckController.drawCards(1)`.
  * Si `forgeUpgrades` contains `'eco'` : ajouter 1 mana : `runController.gainResource(mana: 1)`.
  * Si `forgeUpgrades` contains `'burning'`, `'freezing'`, `'shocking'` : appliquer le statut correspondant sur la cible.

### Contrôleur de Deck (`lib/game/controllers/deck_controller.dart`)
* Dans `playCard` :
  * Si la carte possède l'amélioration `'enduring'`, forcer `isExhaust = false` lors du traitement (sauf type `power`).
* Dans `mergeCards` :
  * Regrouper par ID, niveau ET rareté.
  * Fusion de Rareté : 3 cartes de Niveau 3 d'une Rareté R ➔ 1 carte de Niveau 1 de Rareté R+1.
  * Transférer et fusionner les améliorations de forge des anciennes cartes vers la nouvelle (dans la limite de sa capacité maximale).
* Ajouter une méthode `applyForgeUpgrade(String uniqueId, String upgradeId)` pour appliquer l'amélioration choisie.

### Écran de la Forge (`lib/ui/screens/rest_screen.dart`)
* Remplacer l'amélioration automatique de niveau (`_upgradeCard`) par une sélection d'options :
  1. Le joueur choisit sa carte.
  2. Si `forgeUpgrades.length >= totalMaxForgeUpgrades`, afficher un message d'avertissement.
  3. Sinon, générer 3 options d'améliorations aléatoires compatibles (en excluant les doublons et les améliorations invalides pour le type de carte).
  4. Afficher un dialogue de sélection.
  5. Une fois choisie, appeler `deckNotifier.applyForgeUpgrade(...)`.

### Rendu de la description des cartes (`lib/ui/widgets/ui_card.dart` & `lib/game/components/card_component.dart`)
* Dynamiquement concaténer à la description textuelle les bonus appliqués (ex: `+2 Dégâts (Tranchant)`, `Pioche +1 (Véloce)`).

---

## 🧪 6. Plan de Test et de Validation

1. **Vérification Statique** : `dart analyze` pour éliminer tout avertissement.
2. **Tests Unitaires** :
   * Tester la fusion de Rareté (Commun Lvl 3 x3 ➔ Peu Commun Lvl 1).
   * Tester la limite `totalMaxForgeUpgrades` pour s'assurer qu'un joueur ne peut pas outrepasser la capacité de forge.
   * Tester l'application des effets de forge en combat (`sharp`, `eco`, etc.).
3. **Tests Manuels** :
   * Visiter le feu de camp, forger une carte et valider que 3 options variées sont bien proposées.
   * Jouer la carte modifiée et vérifier l'application effective du bonus en combat.
