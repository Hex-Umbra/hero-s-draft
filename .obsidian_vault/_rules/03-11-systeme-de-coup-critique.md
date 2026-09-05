### 3.11. 🎯 Système de Coup Critique (Critical Hit System)

Le coup critique introduit un élément probabiliste d'amplification des effets offensifs et curatifs du joueur et des ennemis :
- **Attributs Fondamentaux** (`EntityStats`) :
  - `critChance` : Le taux de base (en %) pour déclencher un coup critique (défaut: `0`).
  - `critMultiplier` : Le coefficient de multiplication des dégâts ou des soins (défaut: `1.5`).
- **Calcul en Combat & État Déterministe (v0.1.7)** :
  - La chance critique effective est calculée dynamiquement par le getter `effectiveCritChance` qui combine `critChance` permanente et les éventuels bonus temporaires issus du statut `crit_chance`.
  - **Suivi d'État Précis** : Au lieu de se baser sur des seuils de dégâts arbitraires lors de l'affichage, l'état de coup critique est formellement propagé et suivi au niveau du modèle d'état (`EntityStats.lastActionWasCrit`). Ce flag booléen est calculé lors des jets de dés en phase métier (`EffectResolver` et `CombatController`) et stocké temporairement dans les statistiques de l'entité, permettant à la couche de rendu Flame d'obtenir une source de vérité absolue pour déclencher les effets esthétiques associés.
- **Mécanismes d'Impact** :
  - **Dégâts des Cartes** (`EffectResolver._calculateDamage`) : Les attaques physiques ou magiques du joueur ont une probabilité égale à `effectiveCritChance` de voir leurs dégâts totaux multipliés par `critMultiplier` (arrondi).
  - **Soins des Cartes** (`EffectResolver.resolveCard` case 'heal') : Les soins appliqués au héros ont une chance de coup critique qui multiplie le soin par `critMultiplier`.
  - **Dégâts des Ennemis** (`CombatController.resolveEnemyIntent` case 'attack') : Les attaques d'intentions des ennemis effectuent également un jet de critique basé sur leur propre `effectiveCritChance`, multipliant les dégâts infligés au héros par leur `critMultiplier`.
- **Récompenses de Draft de Niveau (Level Up)** :
  - **Précision** : Augmente de façon permanente `critChance` (de +1% à +5% selon la rareté de la récompense).
  - **Férocité** : Augmente de façon permanente `critMultiplier` (en ajoutant de +0.10 à +0.50 au multiplicateur via l'accumulateur `critDamageAcc`).
- **Éléments de Données & Reliques** :
  - Les ennemis (`assets/data/enemies/<id>/enemy.json`) possèdent des chances de critiques de base distinctes (slime: 5%, gobelin: 10%, squelette: 10%, orc furieux: 15%).
  - Deux nouvelles reliques spécifiques aux critiques ont été intégrées sous `assets/data/relics/` via l'effet `gain_crit` :
    - *Focus Lens* (`critical_lens`, Rare, trigger: `startOfCombat`) : confère un buff temporaire de $+15\%$ de critique en combat.
    - *Lucky Charm* (`lucky_charm`, Uncommon, trigger: `startOfRun`) : confère un bonus permanent de $+10\%$ de critique pour toute la run.
