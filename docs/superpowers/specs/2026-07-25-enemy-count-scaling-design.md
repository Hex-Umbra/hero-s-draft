# Plafonds d'ennemis croissants par acte — Conception

Date : 2026-07-25
Statut : Design validé, pas encore implémenté. Ce document sert de référence pour l'implémentation.

## 1. Contexte et problème identifié

Après correctif de la dérive log/calcul réel (`docs/superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md` §3.6, corrigé le 2026-07-24 dans le commit `24d3148`), le nouveau `combat_math.md` a permis de confirmer qu'un combat élite en début d'Acte 2 (Niveau 3) générait légitimement 3 ennemis (Slime + Gobelin + Slime, CR total 123.7 ≤ `FinalBudget` réel 128.67) — ce n'était pas un bug de calcul, mais le résultat attendu du système de budget existant.

Le vrai problème identifié : le multiplicateur de nœud élite (`NodeMultiplier ×1.5`) combiné à la contribution de `playerCardsCount`/`playerRelicsCount` et au bonus `+(act-1)*10` fait grimper le budget assez vite, alors que le pool d'ennemis disponible reste strictement limité au tier 1 (Slime, Gobelin — CR ~30-48) jusqu'à l'Acte 11 (gating validé dans le design du 2026-07-24 §3.4). Un budget élite conçu pour "un ennemi plus costaud" se traduit alors par plusieurs ennemis faibles empilés, faute d'une option tier-1 plus chère en CR pour absorber ce budget en un ou deux adversaires.

## 2. Objectif

Introduire un plafond sur le nombre d'ennemis générés, qui grandit avec les actes (pour rester cohérent avec la philosophie "endless" déjà adoptée pour le scaling HP/dégâts), différencié par type de nœud :
- Les combats normaux gagnent en ampleur le plus vite.
- Les élites gagnent en ampleur plus lentement.
- Les boss restent des affrontements resserrés le plus longtemps.

## 3. Conception retenue

### 3.1 Trois fonctions en escalier linéaire, une par type de nœud

Toutes ancrées à 1 ennemi à l'Acte 1, croissance de +1 par palier, sans plafond ultime :

```
maxEnemies_normal(act) = 1 + floor((act - 1) / 1)   // +1 tous les actes
maxEnemies_elite(act)  = 1 + floor((act - 1) / 2)   // +1 tous les 2 actes
maxEnemies_boss(act)   = 1 + floor((act - 1) / 5)   // +1 tous les 5 actes
```

Table de valeurs (illustrative) :

| Acte | Normal | Élite | Boss |
|---|---|---|---|
| 1 | 1 | 1 | 1 |
| 2 | 2 | 1 | 1 |
| 3 | 3 | 2 | 1 |
| 4 | 4 | 2 | 1 |
| 5 | 5 | 3 | 1 |
| 6 | 6 | 3 | 2 |
| 10 | 10 | 5 | 2 |
| 11 | 11 | 6 | 3 |

### 3.2 Câblage dans `generateEnemiesForLevel`

Dans `lib/game/systems/encounter_system.dart`, la boucle de sélection budgétaire utilise aujourd'hui une limite générique fixe :
```dart
while (remainingBudget > 0 && generatedEnemies.length < 10) { ... }
```
Elle devient :
```dart
final int maxEnemies = isBoss
    ? getMaxEnemiesForBoss(act)
    : (isElite ? getMaxEnemiesForElite(act) : getMaxEnemiesForNormalCombat(act));

while (remainingBudget > 0 && generatedEnemies.length < maxEnemies) { ... }
```
Les trois fonctions publiques (`getMaxEnemiesForNormalCombat`, `getMaxEnemiesForElite`, `getMaxEnemiesForBoss`) partagent une implémentation commune via un helper privé `_maxEnemiesFromStep(act, stepSize)` pour éviter la duplication de la formule `1 + floor((act-1)/stepSize)`.

Rien d'autre ne change dans la boucle : le budget continue de déterminer *si* on peut se permettre d'atteindre ce plafond (le `remainingBudget > 0` et le filtre `rating <= remainingBudget` restent identiques), le plafond n'est qu'une borne supplémentaire sur `generatedEnemies.length`.

### 3.3 Budget non utilisé quand le plafond est atteint

Si le plafond est atteint avant que le budget soit épuisé, le budget restant est simplement perdu — les ennemis déjà choisis gardent leurs stats normales (scalées par niveau/acte comme aujourd'hui, sans bonus compensatoire). Choix délibéré pour rester simple.

### 3.4 Pas de plafond ultime

Contrairement à l'ancienne limite fixe de 10, il n'y a plus de plafond absolu — la croissance continue indéfiniment avec les actes, cohérent avec la philosophie déjà adoptée pour `getHpActFactor`/`getDamageActFactor` (`docs/superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md` §3.2). En pratique, ce système reste auto-limité en fin de run très avancée : le coût `CombatRating` par ennemi grandit lui aussi via le facteur d'acte en escalier (HP/dégâts), donc le budget redevient naturellement le facteur limitant même sans plafond dur sur le nombre — les deux mécanismes (plafond de comptage + coût croissant par ennemi) se relaient dans le temps plutôt que de se cumuler.

### 3.5 Système de vagues — inchangé

Le mécanisme existant (`CombatController.initializeCombat`) qui répartit les ennemis générés entre `enemies` (max 5 actifs à l'écran) et `pendingEnemies` (réserve, remplacement automatique à la mort d'un ennemi actif) n'est pas modifié. Il absorbe déjà nativement tout total généré au-delà de 5, quel que soit le plafond calculé ici.

### 3.6 Conséquence assumée : les combats normaux sont aussi resserrés

Ce système s'applique symétriquement à tous les types de nœuds, y compris les combats normaux. Concrètement, un combat normal qui pouvait atteindre 3 ennemis dès l'Acte 2 sous l'ancien système (observé dans `combat_math.md`, Acte 2/Niveau 4 : 3 Slimes, budget 96.63) serait désormais plafonné à 2 ennemis (`maxEnemies_normal(2) = 2`), même si le signalement initial ne portait que sur les élites/boss. C'est une décision explicite : le système reste cohérent et symétrique plutôt que d'être une rustine ciblée uniquement sur les élites/boss.

## 4. Hors périmètre

- Les formules de budget (`ExpectedPower`, `BaseBudget`, `FinalBudget`, `PowerModifier`) ne sont pas modifiées — seule la borne supérieure du nombre d'ennemis change.
- Le filtrage par tier d'ennemi débloqué (`getUnlockedTier`) n'est pas modifié.
- L'algorithme de sélection budgétaire lui-même (candidats `rating <= remainingBudget`, choix aléatoire, fallback au plus faible `CombatRating`) n'est pas modifié.
- Le système de vagues actives/réserve (`enemies`/`pendingEnemies`, max 5 actifs) n'est pas modifié.

## 5. Paramètres numériques à valider en jeu (réglables)

| Paramètre | Valeur retenue |
|---|---|
| Base (Acte 1) — tous types de nœud | 1 |
| Palier de croissance — Normal | tous les 1 acte |
| Palier de croissance — Élite | tous les 2 actes |
| Palier de croissance — Boss | tous les 5 actes |
| Incrément par palier | +1 |
| Plafond ultime | Aucun |
