# Plan d'Implémentation - Activation Élémentaire & Réflexion Rareté Dynamique

Ce plan décrit les modifications de code requises pour activer les statuts élémentaires (`burn`, `freeze`, `shock`) de l'Axe 1, et propose une analyse de conception de produit concernant l'évolution du système de rareté et de fusion.

---

## 🎯 Axe 1 : Activation des Effets Élémentaires (Brûlure, Gel, Électrocution)

### 1. [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart)
* **Création des statuts** : Modifier `_createStatus` pour enregistrer et instancier correctement les statuts :
  * `burn` (Brûlure) : Type `debuff`.
  * `freeze` (Gel) : Type `debuff`.
  * `shock` (Électrocution) : Type `debuff`.
* **Résolution de Électrocution (`shock`)** : Dans `resolveCard`, case `damage` :
  * Si l'ennemi ciblé ou touché possède le statut `shock`, ajouter sa valeur aux dégâts infligés : `dmg += shockValue`.

### 2. [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)
* **Dégâts de Brûlure (`burn`)** : Dans `startEnemyTurn` :
  * Récupérer la somme des statuts `burn` actifs de l'ennemi.
  * Appliquer des dégâts égaux à cette somme au début de son tour : `updatedStats.takeDamage(burnDamage)`.
* **Réduction de Gel (`freeze`)** : Dans `resolveEnemyIntent` :
  * Si l'intention de l'ennemi est de type `attack` et qu'il possède le statut `freeze`, réduire ses dégâts de moitié (`x 0.5`) : `int finalDamage = (intent.value * 0.5).round();`.

---

## 🧠 Réflexion Produit : Intérêt et Refonte de la Rareté & Fusion

Voici l'analyse demandée concernant la valeur de la rareté et sa place dans les calculs de game design :

### 1. Pourquoi la rareté ne compte pas dans la VPM brute ?
En game design, la rareté **ne doit pas** être un facteur d'équilibrage du coût en mana. Le mana représente le **tempo tactique** (ce que vous pouvez faire en 1 tour), tandis que la rareté représente le **tempo stratégique** (la difficulté à acquérir et à construire le deck) :
* Une carte rare *doit* avoir un ratio VPM volontairement supérieur (7.0 - 9.0) pour récompenser le joueur lorsqu'il la trouve. Si toutes les raretés avaient le même ratio, la pioche ou l'acquisition de cartes rares n'aurait aucune saveur.

### 2. Proposition de Système : Rareté Dynamique et Fusion Évolutive
Votre idée de décorréler la rareté d'une carte de son identité fixe est excellente et moderne (à la manière d'un ARPG ou de Roguelikes comme *Balatro* ou *TFT*). Voici une proposition d'architecture produit pour ce système :

#### A. Rareté comme Multiplicateur de Stat (Prefixes/Suffixes)
Au lieu d'avoir un "Frappe" toujours commun, chaque carte peut être générée avec des raretés différentes. La rareté applique un coefficient multiplicateur sur les valeurs de base (`baseValue`) et peut débloquer des effets secondaires :

| Rareté | Multiplicateur | Effet Additionnel Tactique (Exemple) |
| :--- | :---: | :--- |
| **Commun** | `1.0x` | Aucun |
| **Peu Commun** | `1.2x` | +1 Armure sur les attaques / +1 dégât sur les compétences |
| **Rare** | `1.4x` | La carte n'est plus épuisée (`isExhaust: false` si c'était le cas) |
| **Épique** | `1.6x` | Piochez 1 carte supplémentaire lors du jeu |
| **Légendaire** | `2.0x` | Restitue 1 mana lors du jeu (Tempo extrême) |

*Exemple* : Une "Frappe Commune" inflige 6 dégâts. Une "Frappe Légendaire" inflige 12 dégâts (12 VS, 1 mana = 12.0 VPM).

#### B. Impact sur le Système de Fusion (Merge)
Actuellement, la fusion combine 3 copies identiques pour augmenter le **Niveau** (Lvl 1 ➔ Lvl 2). Avec la rareté dynamique, nous pouvons concevoir deux voies de fusion complémentaires :

1. **Fusion de Niveau (Forge classique)** :
   * Fusionner 3 copies d'une carte de **même rareté** et de **même niveau** donne la même carte avec un **Niveau + 1** (augmente la valeur selon le coefficient de niveau actuel `+50%`).
2. **Fusion de Rareté (Évolution stellaire)** :
   * Si le joueur réunit 3 copies de **Niveau Max** (ex: Niv. 3) d'une même rareté, elles fusionnent pour donner 1 exemplaire de **Niveau 1** de la **Rareté supérieure** (Commun ➔ Peu Commun).
   * *Bénéfice produit* : Cela donne une utilité à toutes les cartes en surplus, même tard dans le run, en créant une courbe de progression addictive et claire à long terme.

---

## 🧪 Plan de Vérification (Axe 1)

* **dart analyze** : Validation de la non-régression de typage.
* **flutter test** : Passage de la suite complète des 59 tests.
* **Vérification en jeu** : Jouer un deck Mage pour tester l'application effective de `burn` sur l'ennemi et de `freeze` réduisant de moitié l'attaque de Goblin.
