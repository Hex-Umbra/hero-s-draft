### 3.4. `EffectResolver` — Résolution d'Effets de Cartes

**Type** : Classe statique utilitaire (`lib/game/services/effect_resolver.dart`).

**Méthodes principales** :

#### `canPlayCard(CardInstance, RunState, String? selectedEnemyId) → bool`
- Vérifie : mana suffisant (≥ `currentCost`), carte non-status, carte ciblée → `selectedEnemyId` requis.

#### `resolveCard(CardInstance, RunController, DeckNotifier, CombatController, String?, EffectRegistry) → bool`
1. Déduit le coût en mana de la carte (`currentCost`).
2. Lit la carte **telle qu'elle se joue** : `card.effective`, l'`EffectiveCard` que calcule l'applicateur
   unique — rareté (G1, G2) et runes comprises ([`_patterns/10-00`](10-00-architecture-du-systeme-de-forge-et-de-fusion.md) §10.4).
3. Itère sur `addedEffects` (les effets que les runes ajoutent : pioche de `quick`, mana d'`eco`,
   statuts des runes élémentaires), **puis** sur `effects` (les effets propres, à leur valeur jouée),
   chaque valeur passée telle quelle en `scaledValue`. **Le résolveur n'a plus aucun code de rune** —
   ni `switch` par id, ni bloc élémentaire, ni multiplicateur en ligne, ni armure de rune à part —
   [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), qui complète
   [ADR-061](../_adr/ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md).
4. Délègue l'exécution de chaque effet à la stratégie correspondante enregistrée dans l' **`EffectRegistry`** sous `lib/game/services/effects/` :
   - **Strategy Pattern (Extensibilité)** : Au lieu d'un switch/case monolithique, le système instancie des classes implémentant l'interface `EffectStrategy`.
   - **6 Stratégies Spécifiques** :
     - `DamageEffectStrategy` : Gère le calcul des dégâts physiques/magiques (via `DamagePipeline`), l'application aux cibles (mono ou multi-ennemis) et les statuts associés.
     - `HealEffectStrategy` : Gère les soins prodigués avec prise en compte des chances critiques.
     - `ArmorEffectStrategy` : Traite la génération d'armure d'un effet de carte (`GainSource.card`) — la Maîtrise, elle, n'agit que sur les gains d'un passif ([`_patterns/03-3`](03-3-traitsystem-passifs-de-heros.md)), jamais sur ceux d'une carte.
     - `GainManaEffectStrategy` : Gère les gains de mana (restauration ou surcapacité temporaire).
     - `DrawEffectStrategy` : Déclenche la pioche de cartes dans le deck.
     - `ApplyStatusEffectStrategy` : Gère l'application d'effets de statut (buffs/debuffs) sur soi ou sur la cible, par `EntityStats.addStatus` ; la Puissance d'une carte porte la source `card:<id>`, tout autre statut aucune ([ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md)). Les statuts des runes élémentaires passent par elle — elle lit la cible de la carte : une Attaque `target: self` portant une rune élémentaire poserait le statut sur le héros (aucune carte livrée ; ADR-105, Conséquences).

#### `DamagePipeline.calculate`
Le calcul des dégâts physiques, magiques et des intentions d'attaques ennemies est entièrement délégué à la méthode statique unifiée `DamagePipeline.calculate(int initialDamage, EntityStats attackerStats, EntityStats defenderStats)` dans `lib/game/services/damage_pipeline.dart`. 

Le calcul s'exécute selon les étapes logiques strictes suivantes :
1. **Faiblesse (Attaquant)** : Dégâts réduits de 25% (multiplication par `0.75` puis arrondi) si le statut `weakness` est présent sur l'attaquant.
2. **Coup Critique** : Jet probabiliste basé sur `effectiveCritChance` de l'attaquant, plus le `critChanceBonus` de la carte — 0 par défaut, rempli par la rune *Précis* via `DamageEffectStrategy` ; les ennemis et le tutoriel passent 0 ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)). En cas de succès, dégâts multipliés par `critMultiplier` de l'attaquant et assignation à `true` de `lastActionWasCrit` sur l'attaquant pour guider le rendu des tremblements, flashs et particules de la couche Flame.
3. **Choc (Défenseur)** : Ajout de la valeur brute cumulée du statut `shock` sur le défenseur.
4. **Vulnérabilité (Défenseur)** : Dégâts augmentés de 50% (multiplication par `1.5` puis arrondi) si le statut `vulnerable` est présent sur le défenseur.

Il retourne un tuple `(int finalDamage, bool isCrit)`.

**Statuts que fabrique `EffectResolver.createStatus`** — re-lu le 2026-10-02 : `poison`, `might`, `weakness`, `vulnerable`, `might_regen`, `armor_regen`, `burn` (Brûlure), `freeze` (Gel), `shock` (Électrocution). Seule la branche `might` retient le paramètre facultatif `sourceId` (ADR-104). `strength` et `strength_regen`, que cette ligne citait, sont devenus `might` et `might_regen` avec [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) ; `crit_chance` n'est pas fabriqué ici.
