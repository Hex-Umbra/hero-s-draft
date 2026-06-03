# Progression XP, Niveaux, Scaling Ennemi et Carrousel Vertical de Draft

## Description

Afin de réguler l'inflation de puissance et de renforcer la gratification du joueur, nous remplaçons le système d'attribution systématique de récompense de Draft après chaque combat par un **Système d'Expérience (XP) et de Niveaux**. 

De plus, pour conserver un défi stimulant tout au long de la partie, les **statistiques des ennemis sont mises à l'échelle dynamiquement** selon le Niveau du Joueur, le numéro de l'Acte en cours et la nature du nœud (Normal, Élite, Boss). L'XP remportée à la fin d'un combat dépendra précisément des types d'ennemis éliminés et de leur niveau respectif.

Enfin, lors du passage de niveau, l'apparition des choix de caractéristiques (l'écran de **Draft**) bénéficiera d'une **animation séquentielle de carrousel vertical** (style *Vampire Survivors* ou *MegaBonk*). Les cartes de récompense défileront du haut vers le bas l'une après l'autre avant de se figer, avec une animation dorée ultra-premium et explosive si une récompense Légendaire (4ème ou 5ème option) fait son apparition.

---

## User Review Required

> [!IMPORTANT]
> **Formule d'XP Requise pour le Joueur (Level Up Threshold)**
> Nous proposons une courbe exponentielle souple pour que les premiers niveaux se gagnent rapidement, puis se stabilisent :
> $$\text{XP Nécessaire} = 100 \times (1.5)^{\text{Niveau} - 1}$$
> Exemples de paliers :
> * Niveau 1 → 2 : **100 XP**
> * Niveau 2 → 3 : **150 XP**
> * Niveau 3 → 4 : **225 XP**
> * Niveau 4 → 5 : **337 XP**
> *(Il n'y aura aucun niveau maximal imposé au joueur ; la courbe gère naturellement la fin de partie).*

> [!IMPORTANT]
> **Formule de Niveau des Ennemis (Enemy Level)**
> Le niveau des ennemis s'aligne sur le niveau du joueur avec un décalage indexé sur l'Acte et le type de nœud :
> $$\text{Niveau Ennemi} = \text{Niveau Joueur} + (\text{Acte} - 1) \times 2 + \text{Modificateur de Nœud}$$
> * **Modificateurs de Nœud** :
>   * Combat Normal : `+0`
>   * Combat Élite : `+1`
>   * Boss de l'Acte : `+2`
> *(Exemple : Si le joueur est Niveau 3 dans l'Acte 2, un ennemi Normal sera Niveau 5, un Élite sera Niveau 6, et le Boss sera Niveau 7).*

> [!IMPORTANT]
> **Formules de Scaling des Statistiques Ennemies**
> Les PV Max et l'Attaque de base des monstres sont ajustés selon leur Niveau et l'Acte en cours :
> * **HP Multiplier** :
>   $$\text{Mult}_{\text{HP}} = (1.0 + 0.12 \times (\text{Niveau Ennemi} - 1)) \times (1.0 + 0.4 \times (\text{Acte} - 1)) \times \text{NodeMultiplier}$$
> * **Damage Multiplier** :
>   $$\text{Mult}_{\text{Dmg}} = (1.0 + 0.08 \times (\text{Niveau Ennemi} - 1)) \times (1.0 + 0.3 \times (\text{Acte} - 1)) \times \text{NodeMultiplier}$$
> * **NodeMultiplier** : `1.0` (Normal), `1.5` (Élite), `3.0` (Boss).

> [!IMPORTANT]
> **Formule d'XP Rapportée par un Ennemi**
> Chaque ennemi a une valeur d'XP de base dans son JSON. L'XP finale gagnée augmente de 10% par niveau au-dessus du niveau 1 :
> $$\text{XP Gagnée} = \text{XP de Base} \times (1.0 + 0.10 \times (\text{Niveau Ennemi} - 1))$$

---

## Open Questions

> [!NOTE]
> **Q1 — Débordement d'XP (Carry-over)** : En cas de gros gain d'XP déclenchant un Level Up, l'XP restante doit-elle être conservée pour le niveau suivant ? → **Oui, validé par l'utilisateur.** (ex: s'il a 90/100 XP et gagne 30 XP, il passe niveau 2 avec 20/150 XP).
>
> **Q2 — Crochets Audio sur le Carrousel Vertical** : Devons-nous réutiliser des signaux de ticks sonores lors du défilement des cartes de draft ? → **Oui**, l'implémentation inclura des crochets `onCardTick` et `onCardLand` pour chaque carte se révélant l'une après l'autre.

---

## Proposed Changes

### 1. Données de Jeu (`assets/data/enemies.json`)

#### [MODIFY] [`enemies.json`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev and Godot/Roguelike Card Game/roguelike_card_game/assets/data/enemies.json)

Ajouter une propriété `"xp"` (valeur d'XP de base) pour chaque type d'ennemi :
* `slime` : `"xp": 25`
* `gobelin` : `"xp": 35`
* `squelette` : `"xp": 50`
* `orc` : `"xp": 100`

---

### 2. Modèles de Données

#### [MODIFY] [`enemy_data.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/enemy_data.dart)
Ajouter le champ `final int xp` à la classe `EnemyData` et l'extraire du JSON (valeur par défaut : `20`).

#### [MODIFY] [`entity_stats.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart)
Ajouter à `EntityStats` les champs de progression (utilisés pour le joueur et les ennemis) :
* `final int level` (par défaut `1`)
* `final int xp` (par défaut `0`)
* `final int xpToNextLevel` (par défaut `100`)

Mettre à jour `copyWith`, `fromJson` et `toJson` en conséquence.

---

### 3. Logique Métier de Progression (`RunController`)

#### [MODIFY] [`run_controller.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart)
Ajouter les fonctionnalités dans le `RunController` :

* **Calcul de l'XP requise** :
  ```dart
  int calculateXpNeeded(int currentLevel) {
    return (100 * pow(1.5, currentLevel - 1)).round();
  }
  ```
* **Méthode `gainXp(int amount)`** :
  Prend l'XP, l'ajoute à `xp`, et gère une boucle de `while (xp >= xpToNextLevel)` pour accumuler les niveaux.
  Retourne un booléen `true` si au moins un niveau a été gagné (pour déclencher le Draft UI).

---

### 4. Mise à l'Échelle des Ennemis (`CombatController`)

#### [MODIFY] [`combat_controller.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)

Dans `initializeCombat(int playerLevel, MapNodeType? nodeType, List<EnemyData> enemyDataList, int act)` :
* Calculer le niveau de l'ennemi (`enemyLevel`) selon la formule ci-dessus.
* Calculer les multiplicateurs de PV et d'Attaque basés sur l'Acte et le niveau de l'ennemi.
* Instancier les `EntityStats` de l'ennemi avec ces valeurs adaptées et affecter le champ `level: enemyLevel`.
* Mettre à jour la signature de `initializeCombat` pour lui passer également `runState.act` et `runState.heroStats.level`.

---

### 5. Intégration de la Victoire (`GameScreen`)

#### [MODIFY] [`game_screen.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart)

Mettre à jour `_handleCombatVictory()` et le point de départ du combat :
* Au début du combat, appeler `combatController.initializeCombat(...)` en transmettant l'acte en cours et le niveau du joueur.
* Lors de la victoire de combat, calculer l'XP totale accumulée :
  ```dart
  int totalXp = 0;
  for (var enemy in combatState.enemies) {
    totalXp += (enemy.data.xp * (1.0 + 0.10 * (enemy.stats.level - 1))).round();
  }
  ```
* Appliquer l'XP au héros via `gainXp(totalXp)`.
* Si montée de niveau (`leveledUp = true`) :
  * Déclencher une notification festive « LEVEL UP ! » et activer `_showDraft = true` pour choisir une récompense de caractéristiques.
  * Si aucune montée de niveau, rediriger directement vers la carte (ou vers le draft classique si c'était le boss de fin d'acte).

---

### 6. Interface Graphique (HUD / Map)

#### [MODIFY] [`hero_mini_stats_panel.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/map/hero_mini_stats_panel.dart)
Ajouter un affichage élégant de l'expérience et du niveau du Héros :
* Un badge circulaire ou rectangulaire stylisé brun et or indiquant `Niv. X`.
* Une barre de progression horizontale d'XP couleur jaune or ou ambre dorée (`Colors.amber`), affichant la jauge de progression avec le texte compact `XP: 75/100`.

#### [MODIFY] [`enemy_intents_panel.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/hud/enemy_intents_panel.dart)
Rendre le niveau des ennemis visible dans le panneau d'intentions en combat en modifiant le libellé de leur nom :
`name` → `${name} (Niv. ${enemy.stats.level})`

---

### 7. Animation séquentielle de Carrousel de Draft (`DraftScreen`)

#### [NEW] `lib/ui/widgets/relic_carousel/draft_card_reel.dart`
Nouveau widget encapsulant un **rouleau séquentiel vertical** pour chaque carte de choix :
* **Reel Spin Animation** : Le composant commence dans un état "en rotation", faisant défiler rapidement vers le bas des silhouettes ou des cartes factices floues.
* **Lancement séquentiel** : Reçoit un index et un délai de départ.
  * La carte 1 commence immédiatement à tourner, décélère et se verrouille à `t=0.8s`.
  * La carte 2 commence à décélérer dès que la carte 1 se fige, et se verrouille à `t=1.4s`.
  * La carte 3 se verrouille à `t=2.0s`.
* **Célébration Légendaire Spéciale (4ème Option)** :
  * Si l'option est de rareté Légendaire, son défilement est prolongé, accompagné de secousses d'écran légères (`shaking effect`) et de l'apparition de particules dorées flamboyantes et d'une onde de choc Canvas dorée lors du verrouillage final !

#### [MODIFY] [`draft_screen.dart`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart)
Remplacer l'affichage brut de `UiCard` dans les colonnes/lignes par le nouveau composant `DraftCardReel` en lui passant les choix et les indices pour un affichage rythmé et dynamique.

---

## Verification Plan

### Automated Tests
* Écrire une suite de tests unitaires dans `test/unit/xp_scaling_test.dart` validant :
  1. Le calcul correct de l'XP requise pour les niveaux 1, 2, 3.
  2. Le comportement cumulatif et le débordement de `gainXp` (carry-over).
  3. Le bon calcul du niveau de l'ennemi et de ses statistiques à l'échelle (multiplicateurs PV/Attaque) pour l'Acte 1 et l'Acte 2.
* Lancer `dart analyze` et s'assurer que tout compile avec 0 warning.

### Manual Verification
1. Lancer le jeu en mode combat.
2. Vérifier que les monstres affichent leur niveau dans le panneau des intentions (ex: `Slime (Niv. 1)`).
3. Gagner le combat, constater le gain d'XP calculé sur les monstres vaincus.
4. Vérifier que l'XP augmente sur le `HeroMiniStatsPanel` de la carte.
5. Déclencher un Level Up et vérifier la transition fluide vers l'écran de Draft.
6. Constater l'apparition séquentielle et rythmée des cartes de récompenses de haut en bas.
