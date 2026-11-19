### 3.4. `EffectResolver` — Résolution d'Effets de Cartes

**Type** : Classe statique utilitaire (`lib/game/services/effect_resolver.dart`).

**Méthodes principales** :

#### `canPlayCard(CardInstance, RunState, String? selectedEnemyId) → bool`
- Vérifie : `canAfford(card, heroStats)` — depuis la vague 5, la règle unique des coûts combinés,
  `CostRules.canPay` (mana courant, PV strictement supérieurs au coût en PV, Armure) —, carte
  non-status, carte ciblée → `selectedEnemyId` requis ([`_rules/03-14`](../_rules/03-14-couts-combines-croissance-et-multi-coups.md)).

#### `resolveCard(CardInstance, RunController, DeckNotifier, CombatController, String?, EffectRegistry) → bool`
1. Paie la carte par `consumeResource({mana, hp, armor})`, une seule écriture d'état (vague 5).
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
     - `ApplyStatusEffectStrategy` : Gère l'application d'effets de statut (buffs/debuffs) sur soi ou sur la cible, par `EntityStats.addStatus` ; la Puissance d'une carte porte la source `card:<id>`, tout autre statut aucune ([ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md)). Les statuts des runes élémentaires passent par elle — elle lit la cible de la carte : une Attaque `target: self` portant une rune élémentaire poserait le statut sur le héros (aucune carte livrée ; ADR-105, Conséquences). **Depuis la vague 7** (fusionnée dans `main` le 2026-11-18 par la PR #55 — [ADR-117](../_adr/ADR-117-les-charges-elementaires.md)), elle **aiguille** : un statut qui est une charge du catalogue (`chargeCatalogProvider`) passe par `ChargeRules.pose` — sur l'ennemi visé, sur chaque ennemi, ou sur le héros, chaque porteur avec sa piste —, les autres par `addStatus`. `DamageEffectStrategy` note à chaque coup le bonus de Foudre du défenseur (`ChargeRules.noteHit`, `EntityStats.chargeHits`) avant de lui appliquer les dégâts.

#### `DamagePipeline.calculate`
Le calcul des dégâts physiques, magiques et des intentions d'attaques ennemies est entièrement délégué à la méthode statique unifiée `DamagePipeline.calculate(initialDamage:, attackerStats:, defenderStats:, charges:)` dans `lib/game/services/damage_pipeline.dart` — le catalogue des charges est requis depuis la vague 7. 

Le calcul s'exécute selon les étapes logiques strictes suivantes :
1. **Faiblesse (Attaquant)** : Dégâts réduits de 25 % par point, 2 points au plus (`ProportionalStatus.weakness`, vague 5), puis arrondis.
1 bis. **Héros gelé (Attaquant)** : la rupture `weakenDealt` active de l'attaquant ôte encore son pourcentage, 50 % (`ChargeRules.weakenPercent`, vague 7), au même arrondi.
2. **Coup Critique** : Jet probabiliste basé sur `effectiveCritChance` de l'attaquant, plus le `critChanceBonus` de la carte — 0 par défaut, rempli par la rune *Précis* via `DamageEffectStrategy` ; les ennemis et le tutoriel passent 0 ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)). En cas de succès, dégâts multipliés par `critMultiplier` de l'attaquant et assignation à `true` de `lastActionWasCrit` sur l'attaquant pour guider le rendu des tremblements, flashs et particules de la couche Flame.
3. **Foudre (Défenseur)** : le bonus de la charge `amplifyHits` du défenseur, `ChargeRules.hitBonus` — +1 par point sous le seuil, +2 une fois chargé (vague 7 ; l'Électrocution ajoutait sa valeur brute).
4. **Vulnérabilité (Défenseur)** : Dégâts augmentés de 25 % par point, 4 points au plus (`ProportionalStatus.vulnerable`, vague 5), puis arrondis — le bonus de Foudre compris. `ProportionalStatus` ne porte plus que `vulnerable` et `weakness` : le Gel en est sorti à la vague 7.

Il retourne un tuple `(int finalDamage, bool isCrit)`.

**Statuts que fabrique `EffectResolver.createStatus`** — re-lu le 2026-11-15 : `poison`, `might`, `weakness`, `vulnerable`, `might_regen`, `mana_regen` (la *Source de Mana*, vague 6, [ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md)), `armor_regen`, `hp_regen` (la *Source de Vie*, buff, vague 8 sur sa branche, [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md) — re-lu le 2026-11-18) — re-lu le 2026-11-17 : `burn`, `freeze` et `shock` n'y sont plus depuis la vague 7, ce sont des charges, posées par `ChargeRules.pose`. Seule la branche `might` retient le paramètre facultatif `sourceId` (ADR-104). `strength` et `strength_regen`, que cette ligne citait, sont devenus `might` et `might_regen` avec [ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md) ; `crit_chance` n'est pas fabriqué ici. **Le `name` que pose la fabrique est français** et ne sert plus à l'affichage de la croissance : depuis la vague 8, `CardRuleTexts._statusName` lit le nom de la charge, sinon la clé ARB `statusName` à sélection sur l'id — un test garde l'accord du nom français de la clé et de celui de la fabrique, pas celui des noms anglais (S4 du compte rendu de la vague 8).

**Depuis le lot 1 de P-44** (vague 5, fusionnée dans `main` le 2026-11-09 —
[ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md)) :
chaque effet reçoit son terme de croissance, `EffectResolver.scaleTerm` (`floor(ratio × source)`,
lu au moment de l'effet), et le premier `apply_status` de la résolution le bonus de statut ;
`DamageEffectStrategy` boucle sur `hits` et sur les cibles vivantes, Puissance par coup
`floor(bonus × mightRatio)`, éclaboussure à chaque coup, vol de vie une fois ; après les effets,
`resolveCard` tire l'écho sur un `Random` facultatif, injectable pour les tests, puis rembourse
*Transfusion*. Ordre complet : [`_rules/03-14`](../_rules/03-14-couts-combines-croissance-et-multi-coups.md) §3.14.5.
