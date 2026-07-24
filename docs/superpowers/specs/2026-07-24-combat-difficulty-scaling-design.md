# Scaling de difficulté combat — Conception (documentation, non implémenté)

Date : 2026-07-24
Statut : **Design validé et implémenté** (voir `docs/superpowers/plans/2026-07-24-combat-difficulty-scaling.md`). Ce document reste la référence pour les valeurs numériques et les décisions de conception.

## 1. Contexte et problème identifié

L'analyse de `math_combat.md` (logs de debug de combat) et du code source associé a révélé deux problèmes distincts dans le système actuel de génération d'ennemis (`lib/game/systems/encounter_system.dart`, `lib/game/controllers/combat_controller.dart`).

### 1.1 Double comptage de l'acte (bug principal)

`getEnemyLevel()` intègre déjà l'acte :
```
enemyLevel = playerLevel + (act - 1) * 2 + nodeModifier
```
Mais `getHpMultiplier()` / `getDamageMultiplier()` réappliquent l'acte une seconde fois, indépendamment :
```
hpMult  = (1 + 0.06 * (enemyLevel - 1)) * (1 + 0.35 * (act - 1)) * bossOrEliteMult
dmgMult = (1 + 0.04 * (enemyLevel - 1)) * (1 + 0.25 * (act - 1)) * bossOrEliteMult
```
L'acte contribue donc deux fois : une fois via `enemyLevel`, une fois via le facteur direct. Le `finalBudget` (nombre/variété d'ennemis) ne grandit lui que linéairement (`+25/acte`), donc rien ne compense cette accélération côté "puissance individuelle par ennemi".

Preuve chiffrée (niveau joueur constant = 1, nœud normal, effet de l'acte isolé) :

| Acte | enemyLevel | HP mult. | Dmg mult. |
|---|---|---|---|
| 1 | 1 | 1.00 | 1.00 |
| 2 | 3 | 1.51 | 1.35 |
| 3 | 5 | 2.11 | 1.74 |
| 4 | 7 | 2.79 | 2.17 |
| 5 | 9 | 3.55 | 2.64 |

Le jeu autorisant un nombre d'actes **non plafonné** (`map_progression_manager.dart:advanceToNextWorld` incrémente `act` indéfiniment, `map_content_placer.dart:10` gère déjà `act >= 5`), cette formule devient rapidement absurde en mode long (ex. acte 25 : HP mult. ≈ x36 rien que par l'acte).

### 1.2 Dérive entre le log de debug et le calcul réel

`combat_controller.dart:92-108` recalcule `playerPower`/`finalBudget` en dupliquant `encounter_system.dart:106-131`, mais les deux versions ont divergé :
- Le log omet `+ (playerCardsCount * 2.0)` dans `playerPower`.
- Le log omet `+ (act - 1) * 10.0` dans `finalBudget`.

`math_combat.md` sous-estime donc le vrai budget utilisé pour choisir les ennemis, et l'écart grandit avec l'acte.

## 2. Objectifs de la refonte

- Scaling **logique et doux sur les premiers actes** (pas de bond brutal entre acte 1 et acte 2-3).
- Scaling qui **accélère avec les actes suivants**, pour un mode "endless" qui reste jouable longtemps puis devient volontairement très difficile.
- Un **jalon de difficulté lisible tous les 5 actes** (palier) et un **jalon de contenu tous les 10 actes** (nouveau tier d'ennemi).
- Éliminer la possibilité structurelle de double-comptage (pas juste patcher les symptômes).
- Aligner le log de debug sur le calcul réellement utilisé par le jeu (à traiter dans une implémentation future).

## 3. Conception retenue

### 3.1 Principe : séparation stricte Niveau ↔ Acte

`enemyLevel` ne dépend plus que du niveau du joueur et du type de nœud — plus jamais de l'acte :
```
enemyLevel = playerLevel + nodeModifier   // élite: +1, boss: +2
```
L'acte devient un facteur **entièrement distinct**, appliqué en plus. Cette séparation rend le double-comptage impossible par construction (l'acte n'apparaît plus qu'à un seul endroit du calcul).

### 3.2 Facteur d'acte : palier géométrique tous les 5 actes + rampe douce intra-palier

```
bracket        = floor((act - 1) / 5)        // 0 pour actes 1-5, 1 pour 6-10, 2 pour 11-15, ...
actInBracket   = (act - 1) % 5                // position dans le palier, 0 à 4

bracketMult_HP  = 1.35 ^ bracket
bracketMult_DMG = 1.25 ^ bracket

intraRamp_HP    = 1 + actInBracket * 0.05
intraRamp_DMG   = 1 + actInBracket * 0.03

actFactor_HP    = bracketMult_HP  * intraRamp_HP
actFactor_DMG   = bracketMult_DMG * intraRamp_DMG
```

Le saut de palier est **géométrique** (composé) : chaque palier de 5 actes multiplie par un ratio fixe, ce qui fait naturellement accélérer la difficulté globale dans la durée, sans qu'aucun palier individuel n'ait besoin d'un réglage différent. La rampe intra-palier reste faible (max +20% HP / +12% dégâts en fin de palier) et **se réinitialise** à chaque nouveau palier — la progression ressemble à un escalier avec une légère pente sur chaque marche plutôt qu'à une pente continue et infinie.

Nouvelles formules complètes :
```
hpMult  = (1 + 0.06 * (enemyLevel - 1)) * actFactor_HP  * bossOrEliteMult
dmgMult = (1 + 0.04 * (enemyLevel - 1)) * actFactor_DMG * bossOrEliteMult
```
(`bossOrEliteMult` inchangé : élite x1.5, boss x3.0 ou x1.0 pour les boss custom.)

### 3.3 Comparaison ancien vs nouveau (effet de l'acte isolé, niveau joueur constant)

| Acte | HP mult. ancien (double-compté) | HP mult. nouveau | Dmg mult. ancien | Dmg mult. nouveau |
|---|---|---|---|---|
| 1 | 1.00 | 1.00 | 1.00 | 1.00 |
| 5 | 3.55 | 1.20 | 2.64 | 1.12 |
| 10 | ≈8.15 | 1.62 | ≈5.31 | 1.40 |
| 15 | ≈14.7 | 2.19 | ≈8.75 | 1.75 |
| 25 | ≈36.5 | 3.98 | ≈18.2 | 2.73 |

Le nouveau système reste doux sur les 5 premiers actes (objectif principal de cette conception) puis accélère palier après palier, sans jamais retomber dans l'explosion incontrôlée de l'ancienne formule.

### 3.4 Déblocage de tier d'ennemi tous les 10 actes

```
unlockedTier = min(MAX_TIER_AUTHORED, 1 + floor((act - 1) / 10))
```
`availableEnemies` est filtré à `tier <= unlockedTier` avant d'être passé à la génération d'ennemis. Une fois `MAX_TIER_AUTHORED` (3 aujourd'hui) atteint, le pool reste plafonné à ce tier et c'est `actFactor_HP`/`actFactor_DMG` qui continue de porter la difficulté au-delà.

**Décision explicite validée** : ce gating est **strict**, y compris pour les tiers déjà présents dans le pool de contenu actuel. Concrètement, le Squelette (tier 2) — qui apparaît aujourd'hui dès l'Acte 2 via la sélection "molle" par budget/CombatRating — ne sera plus disponible avant l'**Acte 11** une fois ce système en place. C'est un changement de contenu volontaire : la montée en gamme des ennemis devient un jalon narratif prévisible plutôt qu'un effet de bord du budget. **Implication contenu** : il faudra prévoir d'autres ennemis de tier 1 pour maintenir la variété sur les actes 1-10, la diversité pour les actes 11+ reposant sur l'ajout d'ennemis supplémentaires dans les tiers déjà débloqués (pas uniquement sur le déblocage du tier suivant).

### 3.5 Budget de combat (nombre/variété d'ennemis) — inchangé

`ExpectedPower` (+20/acte) et `BaseBudget` (+25/acte) restent linéaires, tels quels. Le palier ne s'applique qu'à la puissance individuelle des ennemis (HP/dégâts), pas à leur nombre — pour éviter des combats à rallonge avec un nombre d'ennemis qui explose en fin de run.

### 3.6 Logging (à corriger dans une implémentation future, pas dans cette phase)

Le calcul dupliqué entre `combat_controller.dart` et `encounter_system.dart` doit être unifié en une seule fonction source de vérité, pour que `math_combat.md` reflète toujours exactement ce qui est utilisé par le jeu. À date, deux écarts connus sont à corriger :
- `playerPower` du log omet `playerCardsCount * 2.0`.
- `finalBudget` du log omet `+ (act - 1) * 10.0`.

## 4. Hors périmètre de cette conception

- Aucune modification de code n'est faite dans cette phase — ce document sert uniquement de référence pour une implémentation ultérieure.
- La formule de sélection d'ennemis par budget (`CombatRating` vs `remainingBudget`) n'est pas modifiée.
- Les multiplicateurs boss/élite (x1.5 / x3.0) ne sont pas modifiés.
- Le contenu des nouveaux ennemis nécessaires pour peupler les tiers 1-10 puis 11+ est un chantier de contenu séparé, non traité ici.

## 5. Paramètres numériques à valider en jeu (réglables)

| Paramètre | Valeur proposée |
|---|---|
| `bracketMult_HP` (base géométrique) | 1.35 par palier de 5 actes |
| `bracketMult_DMG` (base géométrique) | 1.25 par palier de 5 actes |
| `intraRamp_HP` (pas par acte dans le palier) | +0.05 |
| `intraRamp_DMG` (pas par acte dans le palier) | +0.03 |
| Taille de palier de difficulté | 5 actes |
| Taille de palier de déblocage de tier | 10 actes |

Ces valeurs sont un point de départ cohérent avec l'objectif "doux en début, accéléré ensuite" ; à ajuster par playtest lors de l'implémentation.
