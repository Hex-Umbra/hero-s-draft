# Accélération du Scaling de Difficulté Ennemi — Conception

Date : 2026-07-26
Statut : Design validé, pas encore implémenté. Ce document sert de référence pour l'implémentation.

## 1. Contexte et problème identifié

Après le merge de la refonte du scaling de difficulté (`feature/combat_scaling`, PR #20 + #21 — voir `decisionLog.md` ADR-070 et ADR-071), un retour de playtest externe indique que **le joueur monte en puissance plus vite que les ennemis** : la difficulté reste perçue comme trop facile sur une portion significative de la run, malgré le palier géométrique introduit par ADR-070 (x1.35 HP / x1.25 Dégâts tous les 5 actes) et le déblocage de tier tous les 10 actes.

Deux familles de solutions ont été envisagées :
1. Réduire la puissance du joueur (nerf de certains aspects early-game).
2. Accélérer le scaling ennemi, en gardant les valeurs numériques actuelles (bases géométriques, rampe intra-palier) mais en resserrant la cadence des paliers.

L'option 2 a été retenue. L'objectif produit explicite est de se rapprocher d'une **courbe de difficulté exponentielle assumée** : facile en début de run, puis une accélération continue qui ne s'arrête jamais (pas de plafond, pas de plateau).

## 2. Objectif

Resserrer la cadence des deux mécanismes de scaling ennemi introduits par ADR-070, sans toucher :
- aux bases géométriques (x1.35 HP / x1.25 Dégâts par palier),
- à la rampe intra-palier (+5%/acte HP, +3%/acte Dégâts, réinitialisée à chaque palier),
- aux formules de budget de combat (`ExpectedPower`, `BaseBudget`, `FinalBudget`, `PowerModifier`),
- au plafond du nombre d'ennemis par acte (ADR-071, `getMaxEnemiesForNormalCombat/Elite/Boss`),
- à la puissance du joueur (aucun nerf).

## 3. Conception retenue

### 3.1 Deux constantes modifiées dans `EncounterSystem`

`lib/game/systems/encounter_system.dart` :

```dart
static const int _actBracketSize = 5;          // → 2
static const int _tierUnlockBracketSize = 10;  // → 5
```

Aucune autre ligne de logique métier ne change — `getActBracket`, `getActPositionInBracket`, `getHpActFactor`, `getDamageActFactor`, `getUnlockedTier` gardent leur implémentation actuelle, qui consomme déjà ces constantes.

Conséquence sur le déblocage de tier : tier 2 dès l'Acte 6 (au lieu de 11), tier 3 dès l'Acte 11 (au lieu de 21), toujours plafonné à `maxTierAuthored = 3`.

### 3.2 Analyse de la courbe résultante (validée avec l'utilisateur)

Le facteur d'Acte (`base^bracket × rampe intra-palier`) est par construction une exponentielle sans plafond — resserrer le palier ne change pas la *forme* de la courbe, seulement son taux de composition, proportionnellement à la réduction de palier (5→2, soit x2.5) :

| | Palier actuel (5 actes) | Palier retenu (2 actes) |
|---|---|---|
| Temps de doublement HP | ~11.5 actes | ~4.6 actes |
| Temps de doublement Dégâts | ~15.5 actes | ~6.2 actes |

Trajectoire du facteur HP/Dégâts (base inchangée x1.35/x1.25) :

| Acte | HP (ancien palier=5) | HP (nouveau palier=2) | Dégâts (ancien) | Dégâts (nouveau) |
|---|---|---|---|---|
| 5 | x1.20 | x1.82 | x1.12 | x1.56 |
| 10 | x1.62 | x3.49 | x1.40 | x2.51 |
| 15 | x2.19 | x8.17 | x1.75 | x4.77 |
| 20 | x2.95 | x15.64 | x2.19 | x7.67 |
| 25 | x3.99 | x36.64 | x2.73 | x14.55 |
| 30 | x5.38 | x70.12 | x3.42 | x23.42 |

**Effet secondaire structurel identifié et assumé** : le budget de combat (`FinalBudget`) croît linéairement avec l'Acte (+25/acte pour `BaseBudget`, +10/acte en bonus fixe), alors que le coût individuel d'un ennemi (`CombatRating`) croît désormais exponentiellement via ce même facteur d'Acte. Une simulation illustrative (Slime tier 1, `playerLevel ≈ act` comme proxy) montre que le nombre d'ennemis effectivement finançables par combat **culmine vers l'Acte 10-12 puis redescend**, alors même que le plafond ADR-071 continue de croître — les combats glissent progressivement de "plusieurs ennemis faibles" vers "un seul ennemi de plus en plus surpuissant" (déjà géré sans crash par le fallback existant `generateEnemiesForLevel` : si aucun candidat n'entre dans le budget restant, l'ennemi au `CombatRating` le plus faible est choisi malgré tout). Ce glissement renforce la sensation de courbe exponentielle sans plafond recherchée, au-delà du seul multiplicateur HP/Dégâts.

### 3.3 Conséquences explicitement assumées

- **Fin de run endless plus punitive qu'aujourd'hui** : à l'Acte 25-30, le facteur HP (x36-70) redevient proche de l'ancien bug de double-comptage d'Acte qu'ADR-070 corrigeait (~x36.5 à l'Acte 25). Assumé : l'objectif produit est justement une difficulté qui ne cesse de grimper.
- **Backlog de contenu tier-1 aggravé** : la fenêtre où seul le tier 1 (Slime, Gobelin) est disponible passe de 10 à 5 actes (Actes 1-5 au lieu de 1-10). Le besoin de contenu ennemi tier-1 supplémentaire, déjà identifié dans ADR-070/`progress.md`, devient plus pressant.
- **Plafond de nombre d'ennemis (ADR-071) inchangé**, mais de moins en moins atteignable en pratique passé l'Acte ~12-15 pour les combats normaux, par l'effet budget-linéaire/coût-exponentiel décrit en 3.2.

## 4. Hors périmètre

- Aucun nerf de la puissance du joueur (option explicitement écartée pour cette itération).
- Les formules de budget (`ExpectedPower`, `BaseBudget`, `FinalBudget`, `PowerModifier`, `NodeMultiplier`) ne sont pas modifiées.
- Le plafond du nombre d'ennemis par acte (ADR-071, `getMaxEnemiesForNormalCombat/Elite/Boss`) n'est pas modifié.
- `maxTierAuthored` (toujours 3) et la logique de filtrage/repli par tier dans `generateEnemiesForLevel` ne changent pas.
- Le contenu tier-1 supplémentaire pour compenser la fenêtre resserrée (Actes 1-5) reste au backlog, non traité ici.

## 5. Code impacté

- `lib/game/systems/encounter_system.dart` : les deux constantes (§3.1) ; mise à jour des doc-comments qui mentionnent explicitement "5-act bracket" (lignes ~27, 30, 33) et "tier 2 from act 11, tier 3 from act 21" (ligne ~54) pour refléter les nouvelles valeurs.
- Aucun changement dans `combat_controller.dart` ou `combat_debug_logger.dart` — ces fichiers consomment déjà `getHpActFactor`/`getDamageActFactor`/`getUnlockedTier` sans dupliquer les constantes (cf. ADR-071).

## 6. Tests à mettre à jour

Dans `test/encounter_system_test.dart` :
- `getHpActFactor ramps gently within a 5-act bracket then jumps geometrically` (et son équivalent `getDamageActFactor`) : nouvelles valeurs attendues pour un palier de 2 actes (ex : Acte 3 → bracket 1/position 0, Acte 5 → bracket 2/position 0, etc.).
- `getUnlockedTier stays at 1 for acts 1-10, unlocks 2 at act 11, unlocks 3 at act 21, then caps` : à renommer et réécrire pour tier 2 dès l'Acte 6, tier 3 dès l'Acte 11.
- `generateEnemiesForLevel excludes tier 2 enemies before act 11` / `...allows tier 2 enemies starting at act 11` : bornes d'Acte à ajuster (11 → 6).
- `getHpMultiplier combines enemy level, act bracket and elite multiplier correctly` : le commentaire et la valeur numérique attendue (basés sur le facteur de palier à l'Acte 11) doivent être recalculés pour le nouveau palier.

## 7. Documentation à mettre à jour (post-implémentation)

- Nouvelle entrée `ADR-072` dans `decisionLog.md`, à la suite d'ADR-070/ADR-071, documentant ce changement de cadence avec la table de trajectoire et les trade-offs assumés (§3.3).
- `activeContext.md`, `progress.md`, `systemPatterns.md`, `productContext.md` : mise à jour des références à "tous les 5 actes" / "Acte 11 / Acte 21" pour le scaling de difficulté et le déblocage de tier.
- Patch note joueur : pas rédigé dans le cadre de ce spec (le fichier `patch_notes.json` est agent-managed par le sub-agent `patch_notes_writer`) — à signaler comme dû après implémentation.

## 8. Paramètres numériques retenus (résumé)

| Paramètre | Valeur actuelle | Valeur retenue |
|---|---|---|
| Palier du facteur d'Acte (HP/Dégâts) | 5 actes | **2 actes** |
| Base géométrique HP par palier | x1.35 | inchangé |
| Base géométrique Dégâts par palier | x1.25 | inchangé |
| Rampe intra-palier HP | +5%/acte | inchangé |
| Rampe intra-palier Dégâts | +3%/acte | inchangé |
| Cadence de déblocage de tier | 10 actes | **5 actes** |
| Plafond de tier (`maxTierAuthored`) | 3 | inchangé |
| Plafond du nombre d'ennemis (ADR-071) | +1/1/2/5 actes (normal/élite/boss) | inchangé |
