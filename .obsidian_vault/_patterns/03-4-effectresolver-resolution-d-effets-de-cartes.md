### 3.4. `EffectResolver` — Résolution d'Effets de Cartes

**Type** : Classe statique utilitaire (`lib/game/services/effect_resolver.dart`).

**Méthodes principales** :

#### `canPlayCard(CardInstance, RunState, String? selectedEnemyId) → bool`
- Vérifie : mana suffisant (≥ `currentCost`), carte non-status, carte ciblée → `selectedEnemyId` requis.

#### `resolveCard(CardInstance, RunController, DeckNotifier, CombatController, String?) → bool`
1. Déduit le coût en mana de la carte.
2. Itère sur la liste des effets `cardData.effects` (List\<CardEffect\>).
3. Calcule la valeur mise à l'échelle pour chaque effet selon le niveau de la carte :
   $$scaledValue = baseValue \times (1 + (level - 1) \times 0.5)$$
4. Délègue l'exécution de l'effet à la stratégie correspondante enregistrée dans l' **`EffectRegistry`** sous `lib/game/services/effects/` :
   - **Strategy Pattern (Extensibilité)** : Au lieu d'un switch/case monolithique, le système instancie des classes implémentant l'interface `EffectStrategy`.
   - **6 Stratégies Spécifiques** :
     - `DamageEffectStrategy` : Gère le calcul des dégâts physiques/magiques (via `DamagePipeline`), l'application aux cibles (mono ou multi-ennemis) et les statuts associés.
     - `HealEffectStrategy` : Gère les soins prodigués avec prise en compte des chances critiques.
     - `ArmorEffectStrategy` : Traite la génération d'armure intégrant la Maîtrise d'Armure effective.
     - `GainManaEffectStrategy` : Gère les gains de mana (restauration ou surcapacité temporaire).
     - `DrawEffectStrategy` : Déclenche la pioche de cartes dans le deck.
     - `ApplyStatusEffectStrategy` : Gère l'application d'effets de statut (buffs/debuffs) sur soi ou sur la cible.

#### `DamagePipeline.calculate`
Le calcul des dégâts physiques, magiques et des intentions d'attaques ennemies est entièrement délégué à la méthode statique unifiée `DamagePipeline.calculate(int initialDamage, EntityStats attackerStats, EntityStats defenderStats)` dans `lib/game/services/damage_pipeline.dart`. 

Le calcul s'exécute selon les étapes logiques strictes suivantes :
1. **Faiblesse (Attaquant)** : Dégâts réduits de 25% (multiplication par `0.75` puis arrondi) si le statut `weakness` est présent sur l'attaquant.
2. **Coup Critique** : Jet probabiliste basé sur `effectiveCritChance` de l'attaquant. En cas de succès, dégâts multipliés par `critMultiplier` de l'attaquant et assignation à `true` de `lastActionWasCrit` sur l'attaquant pour guider le rendu des tremblements, flashs et particules de la couche Flame.
3. **Choc (Défenseur)** : Ajout de la valeur brute cumulée du statut `shock` sur le défenseur.
4. **Vulnérabilité (Défenseur)** : Dégâts augmentés de 50% (multiplication par `1.5` puis arrondi) si le statut `vulnerable` est présent sur le défenseur.

Il retourne un tuple `(int finalDamage, bool isCrit)`.

**Statuts créables et gérés** : `poison`, `strength`, `weakness`, `strength_regen`, `armor_regen`, `burn` (Brûlure), `freeze` (Gel), `shock` (Électrocution), `vulnerable` (Vulnérable), `crit_chance` (Chance de critique temporaire).
