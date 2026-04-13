# Documentation des Classes : Hero's Draft

Ce document répertorie l'ensemble des classes jouables actuellement intégrées au jeu "Hero's Draft", leurs caractéristiques de départ, le fonctionnement de leurs mécaniques spéciales (qui partagent un cooldown de 3 tours), ainsi que la cartographie des fichiers du code source responsables de ces mécaniques.

---

## 1. Le Paladin (Orienté Survie)
Le Paladin est la classe la plus endurante. Elle se base sur la gestion de l'armure et l'augmentation conditionnelle de sa faible force de frappe grâce à ses buffs.

### Statistiques de Base
- **PV (Points de Vie)** : `100`
- **Armure de départ** : `20`
- **Attaque** : `5`
- **Défense** : `0.1` (10% de réduction des dégâts)

### Compétences Spéciales
1. **Bouclier (+15 Armure)** : Injecte instantanément de manière inconditionnelle 15 points d'armures supplémentaires aux statistiques du héros (Déclenché via `useArmorRestoreSpecial`).
2. **Rage (+15% PV Max en Attaque)** : Applique une altération temporelle au Héros. Son attaque totale sera augmentée d'un montant plat équivalent à `15%` de ses PV Max lors des 2 prochains tours (Déclenché via `useAttackBuffSpecial`).

---

## 2. Le Mage (Orienté Altération / Zone)
Le Mage possède de bonnes frappes moyennes, très peu de défense, mais est la seule classe capable de toucher plusieurs ennemis en un seul tour, ou d'abattre de puissants éclairs mortels.

### Statistiques de Base
- **PV (Points de Vie)** : `60`
- **Armure de départ** : `5`
- **Attaque** : `10`
- **Défense** : `0.05` (5% de réduction des dégâts)

### Compétences Spéciales
1. **Nova (AoE de 20%)** : Inflige instantanément `20%` de l'Attaque totale du Mage à **tous** les adversaires présents sur le terrain sans distinction. Cette compétence n'a pas besoin de cible pour être lancée.
2. **Frappe de Foudre (150% Cible)** : Foudroie un ennemi sélectionné, lui infligeant `150%` de la valeur de l'Attaque totale. Nécessite qu'un ennemi soit actuellement ciblé.

---

## 3. Le Berserker (Orienté Dégâts purs)
Le Berserker n'a aucune armure ni aucune stat de protection (Défense à 0). Il doit se reposer strictement sur l'agression, la mitigation de l'armure adverse, et la ponction de vie pour survivre.

### Statistiques de Base
- **PV (Points de Vie)** : `80`
- **Armure de départ** : `0`
- **Attaque** : `15`
- **Défense** : `0.0` (Aucune réduction des dégâts)

### Compétences Spéciales
1. **Vampirisme (3 Tours)** : Lance une charge de Lifesteal (`lifestealDuration = 3`) sur le héros. Pendant les 3 prochains tours, `25%` des dégâts occasionnés *via l'attaque de base sur les cibles* sont aspirés et soignent les Points de vie du Héros. (Mécanique gérée via `useBerserkerLifesteal` et calculée dans `executeTurn`).
2. **Perce-Armure (Vol 15%)** : Lance une frappe brutale de `100%` de l'Attaque (comme une attaque normale) mais ce coup n'affecte pas l'Armure adverse : le coup frappe directement **les PV adverses**. En parallèle de la frappe, `15%` de l'armure totale qu'avait ce monstre sont convertis en statistiques d'Armure pour le Berserker.

---

## Architecture des Fichiers Associés

Derrière ces différentes mécaniques, la logique est segmentée parmi les fichiers suivants :

* **`lib/data/models/player_class.dart`** : 
  * C'est le Data Model pur.
  * Définit l'énumération `PlayerClassType`, construit les entités `PlayerClass.paladin`, `mage`, etc..., et fournit les statistiques brutes (`EntityStats`) à l'initialisation.
* **`lib/ui/screens/class_selection_screen.dart`** :
  * C'est le Widget parent où le joueur effectue son choix en début de partie en fonction d'un mapping des classes disponibles.
* **`lib/ui/screens/game_screen.dart`** :
  * Définit l'affichage adaptatif des boutons d'attaque spéciale (HUD). Selon le `runState.heroClass`, ce fichier affiche tantôt les boutons du Mage avec telle couleur, ou ceux du Berserker en interdisant le clic s'il n'y a pas de cible (`_game.selectedEnemy == null`).
* **`lib/game/controllers/run_controller.dart`** :
  * Point central du gestionnaire de State de la session.
  * C'est ici que sont définies les stockages temporaires des buffs (`attackBuffDuration`, `lifestealDuration`), ainsi que l'application purement statistique des sorts agissant sur le joueur (ex: l'apport des 15 d'armure du Paladin).
* **`lib/game/heros_draft_game.dart`** :
  * C'est l'exécuteur Flame Game pour les scripts qui interagissent avec les ennemis ou le feu de l'action.
  * Contient les scripts asynchrones `executeMageAoe()`, `executeMageTargeted()`, et `executeBerserkerTargeted()`.
  * Contient également l'intercepteur de vie pour la logique de Vol de Vie des attaques classiques (via l'appel du `onPlayerHeal(heal)`).
