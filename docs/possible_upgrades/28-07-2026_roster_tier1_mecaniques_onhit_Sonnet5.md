# Roster Tier 1 Étendu & Mécaniques On-Hit — Hero's Draft

**Date** : 28/07/2026
**Contexte** : Suite directe de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` — ce document fait passer les 5 candidats Tier 1 du statut "concept/flavor" à un design concret et implémentable : stats calibrées, extension d'architecture (`onHitEffect`, esquive), et formule de `combatRating` mise à jour.
**Statut** : Brainstorm validé par échange (design complet, architecture + stats + formule figées) — **rien encore implémenté**. Prêt à passer en spec/plan d'implémentation dédié.
**Roster actuel** (`assets/data/enemies.json`) : Slime (tier 1), Gobelin (tier 1), Squelette (tier 2), Orc Furieux (tier 3). `maxTierAuthored = 3`.

---

## 0. Pourquoi ce roster a de la valeur avec le scaling actuel

Point de départ de ce brainstorm : dans `EncounterSystem.calculateCombatRating`, le rating d'un ennemi est

```
rating = (tier × 15) + (hpScale / 4) + (damageScale × 2 × (1 + critChance / 100))
```

où `hpScale`/`damageScale` appliquent le **même** facteur d'acte géométrique (`getHpActFactor`/`getDamageActFactor`, ADR-070/072) quel que soit le tier. Un ennemi tier-1 ne devient donc **jamais obsolète** dans l'algorithme de sélection par budget — il reste structurellement moins cher (terme `tier × 15` plus bas + stats de base plus faibles) qu'un tier 2/3. Et comme `getMaxEnemiesForNormalCombat(act)` croît à chaque acte, le budget doit être rempli avec un nombre croissant d'ennemis : les tier-1 continueront d'être piochés comme remplissage bon marché **à tous les actes, pas seulement Actes 1-5**.

Conséquence pour ce brainstorm : élargir le roster tier-1 n'est pas seulement un correctif de la fenêtre resserrée par ADR-072 (backlog déjà documenté dans `progress.md` §3) — c'est un investissement en variété qui profite à **toute la durée d'une run endless**, puisque le rôle de "chair à canon" budgétaire ne disparaît jamais.

---

## 1. Architecture — nouveau hook générique d'effets d'intention

Constat de départ (vérifié dans le code) : `IntentType` compte une valeur `debuffDeck` déclarée mais jamais implémentée (`turn_phase_manager.dart:110-111`, `case` vide). Aujourd'hui, aucune intention ennemie n'applique de statut au joueur, ne vole d'or, ni ne fait esquiver l'ennemi — seuls `attack` (dégâts directs), `defend` (armure) et `buff` (force auto-appliquée) sont résolus.

### 1.1. `EnemyIntent.onHitEffect`

Nouveau champ optionnel sur `EnemyIntent`, résolu uniquement quand l'intent est de type `attack` (les intents `defend`/`buff` ne touchent jamais le joueur) :

```json
{
  "type": "attack",
  "value": 2,
  "onHitEffect": { "kind": "applyStatus", "statusId": "poison", "value": 2, "duration": 3 }
}
```

`kind` ∈ `applyStatus` / `lifesteal` / `stealGold` :
- **`applyStatus`** : applique un `StatusEffect` existant (`statusId`, `value`, `duration`) au joueur — réutilise les statuts déjà implémentés (`poison`, `burn`, `freeze`, `shock`, `vulnerable`, `weakness`).
- **`lifesteal`** : soigne l'ennemi d'un pourcentage (`value`, ex. 50) des dégâts qu'il vient d'infliger.
- **`stealGold`** : retire un pourcentage (`value`, ex. 5) de l'or actuel du joueur via `InventoryController`.

### 1.2. `EnemyEffectResolver` (nouveau)

Petite classe statique dédiée (`lib/game/services/enemy_effect_resolver.dart`), une branche par `kind` — miroir direct du pattern Strategy/Registry déjà utilisé pour les effets de cartes joueur (`EffectStrategy`/`EffectRegistry`). Appelée depuis `TurnPhaseManager.resolveEnemyIntent`, juste après le calcul de dégâts existant dans le `case IntentType.attack:` (`turn_phase_manager.dart:63-87`).

### 1.3. Esquive (`evadeChance`)

Nouveau champ `evadeChance` (int %, défaut 0) sur `EnemyData` et sur `EntityStats` — seedé exactement comme `critChance` l'est déjà aujourd'hui, au même endroit du code : `combat_controller.dart:152-159` (`EntityStats(..., critChance: data.critChance)` → ajouter `evadeChance: data.evadeChance`).

`DamagePipeline.calculate` gagne une étape 0, avant weakness/crit/shock/vulnerable : si le `defenderStats.evadeChance` déclenche (jet aléatoire), retourne `(0, false)` immédiatement. La fonction étant déjà partagée dans les deux sens (joueur→ennemi et ennemi→joueur), l'esquive est réutilisable pour un futur ennemi/héros/relique sans travail supplémentaire — seul Kobold Éclaireur l'utilise dans cette passe.

**Aucun changement à `EncounterSystem` dans cette section** — la sélection par budget reste inchangée ; seuls le contenu (JSON) et un petit résolveur s'ajoutent.

### 1.4. Modularité des `onHitEffect` — un réglage par ennemi, jamais un préréglage partagé

Point de conception explicitement validé pendant l'échange : `onHitEffect` n'est **jamais** un catalogue de presets partagés ni un enum de "types" à magnitude implicite. C'est un objet inline déclaré dans l'entrée JSON de **chaque** ennemi individuellement, avec ses propres `statusId`, `value` et `duration`. Rien n'empêche deux ennemis différents de partager le même `kind` (`applyStatus`) avec des paramètres totalement différents — par exemple une future "Araignée Géante" (tier 3, roster du 27/07) pourrait appliquer un poison `value: 5, duration: 5` sans toucher à la définition de l'Araignée Venimeuse tier-1 (`value: 2, duration: 3`) définie en Section 2.

**Principe à préserver pour toute extension future du roster** : ne jamais factoriser les `onHitEffect` derrière une bibliothèque de presets nommés — chaque ennemi règle sa propre intensité indépendamment, dans sa propre entrée `enemies.json`. La table de la Section 2 fixe des valeurs de départ pour ce roster précis, pas des constantes globales du moteur.

---

## 2. Roster complet (7 ennemis tier-1)

Stats calibrées pour rester dans la fourchette de `combatRating` de Slime/Gobelin à l'Acte 1 (détail des calculs en Section 3). Chaque nouvel ennemi exploite un axe mécanique distinct, sans doublon :

| Ennemi | HP | Dégâts | Crit | Mécanique | `onHitEffect` / trait |
|---|---|---|---|---|---|
| **Slime** *(existant)* | 18 | 4 | 5% | — | — |
| **Gobelin** *(existant)* | 28 | 5 | 10% | — | — |
| **Rat Géant** | 14 | 5 | 5% | Fodder pur — référence "chair à canon" | aucun |
| **Corbeau Charognard** | 16 | 4 | 5% | Vol de vie léger | `lifesteal` : soigne le Corbeau de 50% des dégâts infligés |
| **Araignée Venimeuse** | 16 | 2 | 5% | Dégâts directs faibles, menace différée | `applyStatus` : poison (valeur 2, durée 3) |
| **Bandit de Grand Chemin** | 24 | 4 | 5% | Pression économique | `stealGold` : vole 5% de l'or actuel du joueur |
| **Kobold Éclaireur** | 14 | 4 | 5% | Défensif (pas un `onHitEffect`, un trait passif) | `evadeChance` : 20% d'esquiver les attaques du joueur |

Tous ont un intent unique répété — cohérent avec le pattern Tier 1 déjà établi par Slime/Gobelin (le cycle à 2/3 intents reste réservé aux tiers 2-3, cf. Squelette/Orc Furieux).

### Exemple JSON complet (Araignée Venimeuse)

```json
{
  "id": "araignee_venimeuse",
  "name_en": "Venomous Spider",
  "name_fr": "Araignée Venimeuse",
  "maxHp": 16,
  "baseDamage": 2,
  "spritePath": "enemy_spider.png",
  "tier": 1,
  "xp": 30,
  "critChance": 5,
  "gold": 10,
  "intents": [
    {
      "type": "attack",
      "value": 2,
      "onHitEffect": { "kind": "applyStatus", "statusId": "poison", "value": 2, "duration": 3 }
    }
  ]
}
```

**Pourquoi ce dosage précis** : avec des dégâts directs quasi nuls, l'Araignée serait mécaniquement "gratuite" en budget sans son poison — le terme `utilityThreat` (Section 3) compense partiellement ça ; le reste est un choix de design assumé (une menace différée qui punit l'inattention plutôt que l'alpha strike).

Le roster reste extensible : les tiers 2-5 déjà brainstormés dans `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` pourront réutiliser `onHitEffect`/`evadeChance` tels quels (aucun nouveau champ à inventer), et les Variantes d'Élite du même document consommeront le même mécanisme (`Ardent` → `applyStatus burn`, `Vampirique` → `lifesteal`, etc. — voir Section 4).

---

## 3. Formule `combatRating` étendue

Nouveau terme `utilityThreat`, ajouté à la formule existante :

```dart
static double _utilityThreat(EnemyData data) {
  final bool hasOnHitEffect = data.intents
      ?.any((i) => i.onHitEffect != null) ?? false;
  return (hasOnHitEffect ? 6.0 : 0.0) + (data.evadeChance * 0.3);
}

// calculateCombatRating :
return (data.tier * 15.0)
     + (hpScale / 4.0)
     + (damageScale * 2.0) * (1.0 + data.critChance / 100.0)
     + _utilityThreat(data);
```

**Constantes choisies** : +6.0 flat pour tout ennemi portant un `onHitEffect` (poison/lifesteal/vol d'or traités comme équivalents en coût pour cette première passe — pas de pondération par `kind` ni par magnitude), et `evadeChance × 0.3` pour l'esquive (20% Kobold → +6.0, même ordre de grandeur).

**Pourquoi flat et non scalé par acte** : contrairement à `hpScale`/`damageScale`, `utilityThreat` ne passe pas par `getHpActFactor`/`getDamageActFactor`. Son poids relatif dans le rating total diminue donc mécaniquement à mesure que les actes avancent — ce qui est en fait cohérent avec l'objectif : le bump compte le plus tôt (Actes 1-5, exactement la fenêtre resserrée par ADR-072), et s'estompe naturellement en fin de run sans devenir un facteur de déséquilibre à recalibrer indéfiniment.

| Ennemi | Rating Acte 1 | Poids `utilityThreat` (Acte 1) | Rating Acte 11 (illustratif) | Poids `utilityThreat` (Acte 11) |
|---|---|---|---|---|
| Slime | 27.9 | 0% | 60.5 | 0% |
| Gobelin | 33.0 | 0% | — | 0% |
| Rat Géant | 29.0 | 0% | — | 0% |
| Corbeau Charognard | 33.4 | 18% | — | ~8% |
| Araignée Venimeuse | 29.2 | 21% | — | ~9% |
| Bandit de Grand Chemin | 35.4 | 17% | 73.2 | 8.2% |
| Kobold Éclaireur | 32.9 | 18% | — | ~8% |

*(Calculs Acte 11 illustratifs à `enemyLevel` constant pour isoler l'effet du facteur d'acte — le point à retenir est le ratio de dilution, pas la valeur absolue.)*

**Spread de rating à l'Acte 1** : 27.9 (Slime) → 35.4 (Bandit), écart de 7.5 points — comparable à l'écart Slime/Gobelin déjà existant (5.1 points). Aucun ennemi n'est un outlier qui monopoliserait ou serait exclu de la sélection par budget.

### 3.1. Amélioration potentielle à garder en mémoire — pondération par magnitude

Décision explicitement assumée pour cette passe : le bump `utilityThreat` est un flat booléen ("a un effet" / "n'en a pas"), **indépendant de la magnitude réelle** de l'effet (`value`/`duration` du `onHitEffect`, cf. §1.4). Un poison `value: 2, duration: 3` coûte donc actuellement le même +6.0 qu'un futur poison `value: 10, duration: 10` beaucoup plus dangereux.

C'est un choix défendable pour ce roster précis (les 4 effets introduits ici sont d'intensité comparable), mais **à revisiter dès que les tiers 2-5 ou les Variantes d'Élite introduiront des magnitudes très variables**. Piste retenue pour cette évolution future, à documenter/chiffrer dans un brainstorm dédié le moment venu : remplacer le flat `6.0` par un poids `kind`-spécifique multiplié par la magnitude normalisée de l'effet (ex. `poids(kind) × (value × duration)` pour un statut, `poids(kind) × value` pour un vol d'or en %), plutôt qu'un simple booléen "a un effet". Ne pas implémenter cette pondération avant qu'un cas d'usage réel (un ennemi à `onHitEffect` nettement plus fort qu'un autre) ne l'exige — cohérent avec la logique déjà appliquée à l'ensemble de ce roster tier-1 (Section 1.4) : les paramètres restent modulables par ennemi, la formule de coût associée peut suivre plus tard sans redesign du schéma de données.

---

## 4. Liens avec les autres brainstorms

- **`27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md`** : ce document opérationnalise directement la section "Tier 1" de ce brainstorm (5 candidats → stats + mécaniques concrètes). La section "Variantes d'Élite Adaptatives" du même document réutilise telle quelle l'architecture `onHitEffect` définie ici (§1) — un futur `EliteAffixData` pourra porter le même type d'objet effet plutôt que d'inventer un second système.
- **`28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md`** / **`28-07-2026_cadre_ennemi_procedural_Sonnet5.md`** : indépendants de ce document (rendu visuel du cadre), mais les 5 nouveaux ennemis de la Section 2 sont les premiers candidats concrets à habiller visuellement une fois l'un des deux pipelines de cadre tranché.
- **`27-07-2026_biomes_finale_sequence_historique_runs_Sonnet5.md`** : aucun couplage direct — le futur champ `EnemyData.biomes` (proposé dans ce document) pourra taguer les 7 ennemis de ce roster sans modification de leur `onHitEffect`/`evadeChance`.

---

## 5. Effort & risque

- **Code : petit-moyen.** Nouveau champ `onHitEffect` sur `EnemyIntent` (+ modèle associé), nouveau `EnemyEffectResolver` (3 branches), nouveau champ `evadeChance` sur `EnemyData`/`EntityStats` + 1 étape supplémentaire dans `DamagePipeline.calculate`, extension de `calculateCombatRating` (`_utilityThreat`). Aucun changement aux formules ADR-070/071/072 existantes.
- **Contenu : 5 nouvelles entrées bilingues** (`_fr`/`_en`) dans `enemies.json`, calibrées en Section 2.
- **Art : dépendance externe.** 5 nouveaux sprites à produire (`enemy_rat.png`, `enemy_corbeau.png`, `enemy_araignee.png`, `enemy_bandit.png`, `enemy_kobold.png`) — non traité par ce document, à coordonner avec le choix de pipeline de cadre (cadre PNG vs procédural, voir Section 4).
- **Risque principal** : aucun nouveau système de scaling n'est introduit (le budget/`combatRating` reste piloté par les mêmes leviers ADR déjà stabilisés) — le risque se limite à la calibration fine des 4 constantes `onHitEffect`/`evadeChance` proposées en Section 2, testable et ajustable indépendamment sans toucher à l'architecture.

---

## 6. Prochaines étapes possibles

1. Passer ce document par une spec d'implémentation dédiée (`docs/superpowers/specs/`) pour chiffrer les derniers détails d'API (signature exacte d'`EnemyEffectResolver`, sérialisation `onHitEffect` dans `EnemyIntent.toJson`/`fromJson`) puis un plan d'implémentation TDD, comme pour les chantiers ADR-070/071/072/073.
2. Lancer la production des 5 sprites en parallèle du code (dépendance externe la plus longue), une fois le pipeline de cadre (Section 4) tranché.
3. Une fois ce roster tier-1 livré et testé en jeu, reprendre les tiers 2-5 du document du 27/07 avec la même méthode (stats calibrées + `onHitEffect` réutilisant §1.4), puis les Variantes d'Élite en dernier (le chantier le plus ambitieux, cf. document source).
4. Revisiter la pondération flat de `utilityThreat` (§3.1) si un futur ennemi à `onHitEffect` de forte magnitude révèle que le flat +6.0 sous-évalue son coût réel en budget.
