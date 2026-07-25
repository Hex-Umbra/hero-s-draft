# 🗂️ Hero's Draft — Roadmap d'Améliorations

> Idées regroupées par domaine fonctionnel, avec actions concrètes et fichiers impactés.

---

## 1. ⚔️ Équilibrage des Ennemis (Scaling, Armure, Intentions)

### Idées concernées
- Modifier la formule de scaling des ennemis (HP et attaque trop rapides)
- Rendre l'armure des ennemis progressive selon les actes et les types de nœuds
- Cacher les intentions ennemies au fur et à mesure de la run ou pour des ennemis spécifiques
- Ajouter une statistique de critique pour les dégâts et les soins (joueur + ennemi)

### Fichiers impactés
- [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) — formules de scaling HP/ATK/Armure (L48-L63)
- [enemy_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/enemy_data.dart) — ajouter champ `baseArmor`, `canHideIntent`, `critChance`
- [enemies.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/enemies.json) — données de base de chaque ennemi
- [enemy_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/enemy_instance.dart) — logique `effectiveIntent`, masquage d'intent
- [entity_stats.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart) — ajouter stat `critChance`, `critMultiplier`

### Actions concrètes

#### A. Revoir les formules de scaling
Les multiplicateurs actuels dans `initializeCombat()` sont :
```dart
// Actuel — trop agressif
hpMultiplier  = (1.0 + 0.12 * (enemyLevel-1)) * (1.0 + 0.40 * (act-1)) * nodeMultiplier;
damageMultiplier = (1.0 + 0.08 * (enemyLevel-1)) * (1.0 + 0.30 * (act-1)) * nodeMultiplier;
```

> [!WARNING]
> Le scaling exponentiel (level × act) crée une courbe qui dépasse rapidement la progression du joueur. Proposer une courbe logarithmique ou des paliers.

**Actions :**
1. Réduire les coefficients par-niveau : `0.12 → 0.06` pour HP, `0.08 → 0.04` pour ATK
2. Réduire les coefficients par-acte : `0.40 → 0.20` pour HP, `0.30 → 0.15` pour ATK
3. Optionnel : plafonner le multiplicateur max par acte
4. Tester avec des simulations sur les actes 1 à 10

#### B. Armure progressive des ennemis
Actuellement les ennemis spawn toujours avec `armure: 0`. Rendre l'armure contextuelle :

**Actions :**
1. Ajouter `baseArmor` dans `EnemyData` et `enemies.json` (par défaut `0` pour les ennemis basiques)
2. Dans `initializeCombat()`, calculer l'armure de spawn :
   - **Combat normal** : `baseArmor` = 0 pour actes 1-3, puis `baseArmor * (1 + 0.1 * (act - 3))` à partir de l'acte 4
   - **Elite** : `baseArmor * (1 + 0.15 * (act - 1))` dès l'acte 1
   - **Boss** : `baseArmor * (1 + 0.2 * (act - 1))` dès l'acte 1
3. Mettre à jour `enemies.json` avec des valeurs de base : `"baseArmor": 0` (slime), `"baseArmor": 3` (gobelin), `"baseArmor": 5` (squelette), `"baseArmor": 8` (orc)

#### C. Cacher les intentions ennemies
**Actions :**
1. Ajouter `canHideIntent: bool` dans `EnemyData` (default `false`)
2. Ajouter `hideIntentAfterAct: int?` dans `EnemyData` (ex: acte 3 → masque à partir de l'acte 3)
3. Dans `EnemyInstance`, ajouter une propriété computed `shouldShowIntent(int currentAct)` qui retourne `false` si `canHideIntent && currentAct >= hideIntentAfterAct`
4. Dans le rendu (game_screen / composant ennemi), afficher "❓" au lieu de l'icône d'intention quand masqué

#### D. Statistique de critique
**Actions :**
1. Ajouter dans `EntityStats` : `critChance` (int, 0-100, défaut 0), `critMultiplier` (double, défaut 1.5)
2. Ajouter dans `EnemyData` / `enemies.json` : `critChance` par ennemi
3. Modifier `takeDamage` / `EffectResolver` pour tirer un dé de critique lors de chaque attaque (joueur et ennemi)
4. Appliquer le critique aussi aux soins (heal × critMultiplier si crit)
5. Le joueur gagne du crit via reliques (`effectType: 'gain_crit'`) et récompenses de fin de combat

---

## 2. 🃏 Système de Cartes (Éléments, Fusion, Mana)

### Idées concernées
- Modifier les cartes élémentaires : certaines n'infligent pas de dégâts mais appliquent un effet plus puissant, d'autres font les deux mais avec un effet plus faible
- Équilibrer la fusion (3 cartes identiques) : ajouter des contreparties + augmenter le coût de mana par fusion/level
- Bien afficher les tooltips des cartes (mono-cible vs multi-cible) avec une icône claire

### Fichiers impactés
- [cards.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/cards.json) — données de chaque carte, effets, coûts
- [card_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/card_data.dart) — modèle `CardData`, `CardEffect`
- [card_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/card_instance.dart) — instance en jeu, level
- [deck_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/deck_controller.dart) — logique de fusion `mergeCards()`
- [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart) — affichage des tooltips et icônes
- [card_component.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/card_component.dart) — composant Flame des cartes

### Actions concrètes

#### A. Cartes élémentaires à double profil
Créer deux archétypes pour chaque élément :

| Type | Dégâts | Effet élémentaire | Exemple |
|------|--------|--------------------|---------|
| **Pur** | 0 | Fort (ex: Poison 6 / Burn 8 / Freeze 4) | "Vague toxique" |
| **Hybride** | Modéré | Faible (ex: Poison 2 / Burn 3 / Freeze 1) | "Lame empoisonnée" |

**Actions :**
1. Ajouter dans `cards.json` les variantes pures (pas de `damage` dans effects, seulement `apply_status`)
2. Augmenter la valeur/durée de l'effet pour les cartes pures (×2 à ×3 par rapport aux hybrides)
3. Les cartes pures pourraient coûter moins de mana (car pas de dégâts directs)
4. Mettre à jour les descriptions en/fr pour refléter les différences

#### B. Contreparties à la fusion
Actuellement `mergeCards()` fusionne 3 cartes en 1 de niveau supérieur sans coût.

**Actions :**
1. **Augmentation du coût de mana** : ajouter un champ `manaCostPerLevel: int` dans `CardData` ou utiliser une formule : `finalCost = baseCost + (level - 1)` → chaque fusion augmente le coût de mana de +1
2. Implémenter dans `CardInstance.currentCost` : retourner `data.cost + (level - 1)` au lieu de `data.cost`
3. **Alternative** : au lieu de +1 par niveau, augmenter tous les X niveaux (ex: +1 mana tous les 2 niveaux de fusion)
4. Mettre à jour l'affichage du coût de mana sur `UiCard` pour refléter le coût réel

#### C. Tooltips de ciblage
**Actions :**
1. Sous l'icône d'attaque de chaque carte, ajouter une icône de ciblage :
   - `singleEnemy` → icône cible unique (🎯)
   - `allEnemies` → icône multi-cible (💥 ou triple silhouette)
   - `self` → icône joueur (🛡️)
2. Utiliser l'enum `CardTarget` déjà existant dans `CardData`
3. Implémenter dans `UiCard` et `CardComponent` : une Row sous les dégâts avec l'icône de ciblage + texte descriptif

---

## 3. 💎 Système de Reliques (Équilibrage, Échange, Triggers)

### Idées concernées
- Trouver un intérêt pour les reliques de début/fin de tour
- Vérification complète de l'équilibrage des reliques et revoir la logique des triggers (ex: mana en début de tour)
- Nouvelle rencontre d'échange de reliques (3 reliques de même rareté → 1 de rareté supérieure)
- La statistique de critique pourra être gagnée via des reliques

### Fichiers impactés
- [relic_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/relic_data.dart) — modèle, triggers, raretés
- [relics.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/relics.json) — données de toutes les reliques
- [run_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart) — `applyRelicEffect()`, `startTurn()`, `startCombat()`
- [inventory_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/inventory_controller.dart) — gestion de l'inventaire des reliques

### Actions concrètes

#### A. Revoir la logique des triggers de reliques

> [!IMPORTANT]
> Actuellement, `energy_stone` (gain 1 mana en début de tour) est problématique : le mana est reset au max à chaque tour (`startTurn` ligne 365-367), puis les reliques `startOfTurn` ajoutent du mana **par-dessus** le max. Cela veut dire que cette relique donne effectivement +1 mana temporaire par tour, ce qui est extrêmement fort.

**Actions :**
1. **Revoir `energy_stone`** : changer son trigger en `startOfCombat` (gain permanent pour le combat) ou réduire sa rareté/valeur
2. **Audit complet** : passer chaque relique en revue et vérifier que le trigger a du sens :

| Relique | Trigger actuel | Problème | Proposition |
|---------|---------------|----------|-------------|
| `iron_talisman` | `startOfTurn` | OK — +2 armure/tour est raisonnable | ✅ Garder |
| `protection_rune` | `endOfTurn` | OK — l'armure de fin de tour protège avant le tour ennemi | ✅ Garder |
| `regen_ring` | `endOfTurn` | OK — heal de fin de tour | ✅ Garder |
| `energy_stone` | `startOfTurn` | Trop fort — bypass le cap de mana | ⚠️ Changer en `startOfCombat` ou ajouter +1 maxMana temporaire |
| `mana_crystal` | `startOfCombat` | OK | ✅ Garder |

3. **Intérêt des reliques de début/fin de tour** : Ajouter de nouveaux types d'effets pour ces triggers :
   - `startOfTurn` : draw +1 carte, réduction de coût d'une carte aléatoire
   - `endOfTurn` : si le joueur n'a pas utilisé tout son mana, convertir le mana restant en armure
4. Ajouter de nouvelles reliques avec l'effet `gain_crit` pour la stat de critique

#### B. Rencontre d'échange de reliques (Alchimiste / Forgeron de Reliques)

**Actions :**
1. Ajouter un nouveau type de nœud `MapNodeType.relicForge` dans [map_node.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/map_node.dart)
2. Logique d'apparition :
   - 100% de chance à chaque acte multiple de 5 (acte 5, 10, 15…)
   - 10% de chance à n'importe quel autre acte
3. Créer un nouvel écran `relic_forge_screen.dart` :
   - Afficher la relique de rareté supérieure proposée (tirée aléatoirement) dès l'entrée
   - Le joueur voit ce qu'il va recevoir avant de choisir
   - Interface de sélection : le joueur choisit 3 reliques de même rareté parmi son inventaire
   - Bouton "Échanger" + "Partir" sans échange
4. Table de conversion : `3 × common → 1 × uncommon`, `3 × uncommon → 1 × rare`, `3 × rare → 1 × epic`, `3 × epic → 1 × legendary`
5. Ajouter la méthode `exchangeRelics(List<RelicData> sacrificed, RelicData received)` dans `InventoryController`

---

## 4. 🎭 Événements & Rencontres

### Idées concernées
- L'Autel Mystérieux : ajouter une contrepartie au fait de recevoir une relique (actuellement déséquilibré)

### Fichiers impactés
- [events.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/events.json) — données de l'événement `mysterious_altar`
- [event_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/event_controller.dart) — résolution des actions

### Actions concrètes

> [!NOTE]
> Actuellement, l'Autel Mystérieux n'offre **pas** de relique directement. Les choix existants sont : `-15 PV / +1 ATK`, `-50 Or / +10 PV Max`, ou `Rien`. Le problème de "relique gratuite" semble concerner l'événement `goblin_merchant` (choix 3 : "L'aider à se cacher → +1 relique aléatoire" **sans contrepartie**).

**Actions :**
1. **Goblin Merchant** — Ajouter une contrepartie au choix "aider" :
   - Option : `-20 PV` (il vous griffe en paniquant) + `+1 relique`
   - Ou : perdre du temps → prochain combat avec un debuff "Fatigué" (−1 mana premier tour)
2. **Autel Mystérieux** — Si on veut ajouter une option relique :
   - Nouveau choix : "Sacrifier une carte de votre deck (supprimée) → +1 relique aléatoire"
   - Action types: `{ "type": "remove_random_card" }` + `{ "type": "gain_relic", "value": "random" }`
3. Vérifier tous les autres événements pour s'assurer qu'aucun ne donne de bénéfice sans coût

---

## 5. 🗺️ Génération de la Map & Chemins

### Idées concernées
- Empêcher la génération du même type de nœud consécutivement sur un chemin (pas 3 élites d'affilée, pas 3 repos d'affilée)
- Mettre un nombre min/max de chaque type de nœud sur la route (sauf combat : pas de limite)
- Changer le système pour proposer des divergences de chemins vers plusieurs boss différents

### Fichiers impactés
- [map_generator_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/map_generator_service.dart) — toute la logique de génération
- [map_node.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/map_node.dart) — types de nœuds, ajout `relicForge`
- [map_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/map_screen.dart) — rendu de la map, affichage des chemins divergents

### Actions concrètes

#### A. Anti-répétition de nœuds
**Actions :**
1. Modifier `_getRandomNodeType()` pour accepter un paramètre `MapNodeType? previousType`
2. Si le type tiré est identique au précédent, retirer et relancer le tirage
3. Implémenter une logique de "look-back" : vérifier les 2 nœuds parents (sur le chemin) pour éviter 3 du même type consécutifs
4. Exception : les nœuds `combat` n'ont **pas** de restriction de répétition

#### B. Quotas min/max par type de nœud
**Actions :**
1. Définir des constantes dans [game_constants.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/game_constants.dart) :
   ```dart
   static const nodeQuotas = {
     MapNodeType.elite: (min: 1, max: 2),
     MapNodeType.shop:  (min: 1, max: 2),
     MapNodeType.rest:  (min: 1, max: 3),
     MapNodeType.event: (min: 1, max: 3),
     // combat: pas de limite
   };
   ```
2. Après la génération initiale, valider les quotas et remplacer les nœuds excédentaires ou manquants
3. Garder les nœuds forcés (étage 0 = combat, étage 5 = chokepoint, avant-boss = repos, dernier = boss)

#### C. Chemins divergents vers des boss différents

> [!IMPORTANT]
> C'est un changement architectural majeur. Actuellement la map est un DAG (graphe acyclique dirigé) avec un seul boss en dernier étage. Proposer 2-3 chemins distincts avec des boss/récompenses différentes requiert de repenser la structure.

**Actions :**
1. Modifier la génération pour qu'à partir d'un certain étage (ex: étage 6 sur 10), la map se divise en 2-3 branches indépendantes
2. Chaque branche mène à un boss différent avec une récompense différente
3. Le joueur voit les 3 boss possibles sur la map et choisit son chemin
4. Ajouter des données de boss variés dans `enemies.json` (avec différentes récompenses de victoire)
5. Afficher sur le `map_screen` un aperçu du boss en bout de chaque branche

---

## 6. 🖥️ Interface de Combat & HUD

### Idées concernées
- Agrandir la taille des informations du joueur en combat / scale en fonction de l'écran
- Sur certains écrans les cartes ennemis sont trop proches, ce qui fait chevaucher les stats/buffs/debuffs
- Afficher correctement les tooltips de ciblage des cartes (mono vs multi-cible)
- Ajouter un badge avec le nombre total de cartes sur le bouton "Mon Deck" (map)

### Fichiers impactés
- [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) — HUD joueur, affichage des ennemis
- [map_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/map_screen.dart) — toolbar, badge du deck
- [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) — composants Flame du combat
- [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart) — widget carte, tooltips
- Widgets dans [hud/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/hud) — panneau de stats joueur

### Actions concrètes

#### A. Stats joueur responsive
**Actions :**
1. Utiliser `MediaQuery.of(context).size` pour calculer un `scaleFactor` basé sur la taille de l'écran
2. Appliquer ce facteur aux `fontSize`, padding, et taille des icônes du panneau HUD
3. Définir un min/max pour éviter que les textes soient illisibles ou gigantesques
4. Tester sur différentes résolutions (mobile, tablette, desktop)

#### B. Espacement des ennemis
**Actions :**
1. Dans le composant d'affichage des ennemis, calculer l'espacement dynamiquement en fonction du nombre d'ennemis : `spacing = screenWidth / (numEnemies + 1)`
2. Si plus de 2 ennemis, réduire la taille des sprites et des barres de stats
3. Positionner les buffs/debuffs en dessous de la barre de PV (et non à côté) quand l'espace est restreint
4. Ajouter un système de scroll horizontal si nécessaire (rare, 3+ ennemis)

#### C. Badge "Mon Deck" sur la toolbar
**Actions :**
1. Dans `map_screen.dart`, ajouter un `Badge` widget (identique à celui des reliques) sur le bouton "Mon Deck"
2. Lire `ref.watch(deckProvider).masterDeck.length` pour afficher le nombre total de cartes
3. Styler le badge de la même manière que celui des reliques (couleur, taille, position)

---

## 7. 🏕️ Zone de Repos & Forge

### Idées concernées
- La forge est trop forte : elle permet de monter de niveau n'importe quelle carte sans risque
- Ajouter un champ `maxForgeUpgrades` dans les cartes JSON pour limiter les améliorations à la forge
- Séparer niveau de carte (via merge uniquement) et améliorations de forge (bonifications uniques)
- La forge proposera des options d'amélioration variées rendant chaque carte unique

### Fichiers impactés
- [rest_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/rest_screen.dart) — interface de la forge
- [deck_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/deck_controller.dart) — `upgradeCard()` → refactorer
- [card_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/card_data.dart) — ajouter `maxForgeUpgrades`
- [card_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/card_instance.dart) — tracker les améliorations de forge
- [cards.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/cards.json) — ajouter le champ à chaque carte

### Actions concrètes

#### A. Limiter les améliorations de forge
**Actions :**
1. Ajouter `"maxForgeUpgrades": 2` (ou 1, 3 selon la carte) dans chaque carte de `cards.json`
2. Parser ce champ dans `CardData.fromJson()` : `maxForgeUpgrades: json['maxForgeUpgrades'] as int? ?? 2`
3. Ajouter `int forgeUpgradeCount = 0` dans `CardInstance` pour tracker le nombre d'améliorations forge
4. Dans `upgradeCard()` : vérifier `card.forgeUpgradeCount < card.data.maxForgeUpgrades` avant d'améliorer
5. Afficher visuellement sur la carte le nombre d'améliorations forge restantes (ex: ⬆️ 1/2)

#### B. Système de forge à options multiples
Remplacer l'upgrade simple (+1 level) par un choix entre plusieurs bonifications :

**Actions :**
1. Définir un enum `ForgeBonus` : `bonusDamage`, `bonusArmor`, `reduceCost`, `addEffect`, `bonusDuration`
2. Quand le joueur sélectionne une carte à la forge, générer 2-3 options aléatoires :
   - "+2 dégâts à tous les effets de type `damage`"
   - "-1 coût de mana (minimum 0)"
   - "+1 durée à tous les effets de type `apply_status`"
3. Stocker les bonus appliqués dans `CardInstance` : `List<ForgeBonus> forgeModifiers`
4. Appliquer les bonus dans `EffectResolver` lors de la résolution des effets
5. Afficher les bonus forge sur la carte (petites icônes ou texte coloré)

> [!NOTE]
> Avec ce changement, le `level` de la carte n'est plus modifié par la forge. Le level ne progresse que via le système de merge (3 cartes identiques → 1 de niveau supérieur).

---

## 8. 🎮 Méta-Fonctionnalités (Tutoriel, Patch Notes, Draft UX)

### Idées concernées
- Ajouter un tutoriel expliquant le gameplay, les cartes, le système de merge
- Menu de patch notes dans l'écran d'accueil basé sur les commits git
- Effet de hover et scale-up sur les cartes récompenses du draft

### Fichiers impactés
- [home_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/home_screen.dart) — bouton tutoriel + bouton patch notes
- [draft_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart) — animations hover/sélection
- Nouveau fichier `tutorial_screen.dart` ou système d'overlay
- Nouveau fichier `patch_notes_screen.dart`
- Nouveau fichier `assets/data/patch_notes.json`

### Actions concrètes

#### A. Tutoriel interactif
**Actions :**
1. Créer `lib/ui/screens/tutorial_screen.dart` avec un système de slides/étapes :
   - Étape 1 : "Comment jouer — Glisser une carte pour l'utiliser"
   - Étape 2 : "Le mana — Chaque carte coûte du mana"
   - Étape 3 : "La fusion — 3 cartes identiques = 1 carte améliorée"
   - Étape 4 : "Les éléments — Feu, Glace, Poison"
   - Étape 5 : "La map — Choisissez votre chemin"
2. Ajouter un bouton "📖 Tutoriel" sur le `home_screen.dart`
3. Afficher automatiquement le tutoriel lors de la première ouverture du jeu (via SharedPreferences `hasSeenTutorial`)
4. Utiliser des images/animations pour illustrer chaque concept

#### B. Patch Notes
**Actions :**
1. Créer `assets/data/patch_notes.json` :
   ```json
   [
     {
       "version": "0.3.0",
       "date": "2026-06-02",
       "title_en": "Elemental Overhaul",
       "title_fr": "Refonte Élémentaire",
       "changes": [
         { "type": "feature", "text_fr": "Nouveau système de cartes élémentaires", "text_en": "New elemental card system" },
         { "type": "balance", "text_fr": "Rééquilibrage du scaling ennemi", "text_en": "Enemy scaling rebalanced" },
         { "type": "fix", "text_fr": "Correction de l'affichage des buffs", "text_en": "Fixed buff display" }
       ]
     }
   ]
   ```
2. Créer `lib/ui/screens/patch_notes_screen.dart` :
   - Afficher chaque version en accordéon
   - Icônes par type : ✨ feature, ⚖️ balance, 🐛 fix, 🎨 UI
3. Ajouter un petit bouton discret en coin de `home_screen.dart` (ex: "📋 v0.3.0")
4. Maintenir ce fichier à jour à chaque release (peut être automatisé via un script qui parse les commits git)

#### C. Effets hover/sélection sur le draft
**Actions :**
1. Dans `draft_screen.dart`, envelopper chaque carte récompense dans un `MouseRegion` + `AnimatedScale` :
   - Hover : `scale: 1.05`, durée 200ms, courbe `easeOut`
   - Sélection : `scale: 1.15` + bordure dorée animée + particules/glow
2. Ajouter un `AnimatedContainer` pour l'effet de bordure lumineux lors de la sélection
3. Feedback haptique (vibration) sur mobile lors de la sélection

---

## 📊 Résumé & Priorisation suggérée

| Priorité | Groupe | Complexité | Impact |
|----------|--------|------------|--------|
| 🔴 Haute | 1. Équilibrage ennemis (scaling) | Moyenne | Critique pour le gameplay |
| 🔴 Haute | 2. Cartes élémentaires & fusion | Moyenne | Cœur du gameplay |
| 🔴 Haute | 3. Reliques (triggers & audit) | Faible-Moyenne | Équilibrage essentiel |
| 🟡 Moyenne | 5. Map (anti-répétition, quotas) | Moyenne | Qualité de la run |
| 🟡 Moyenne | 6. Interface combat & HUD | Faible | QoL et accessibilité |
| 🟡 Moyenne | 7. Forge (refonte) | Haute | Profondeur stratégique |
| 🟢 Basse | 4. Événements (Autel) | Faible | Équilibrage mineur |
| 🟢 Basse | 8. Méta (tutoriel, patch notes, UX draft) | Moyenne | Onboarding & polish |
| 🔵 Long terme | 3B. Rencontre échange reliques | Haute | Nouveau contenu |
| 🔵 Long terme | 5C. Chemins divergents multi-boss | Très haute | Refonte architecturale |
