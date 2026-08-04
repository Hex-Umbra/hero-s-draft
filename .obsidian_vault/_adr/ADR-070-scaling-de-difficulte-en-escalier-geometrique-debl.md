## ⚔️ ADR-070 : Scaling de Difficulté en Escalier Géométrique & Déblocage de Tier d'Ennemi (branche `feature/combat_scaling`)

### Statut
✅ Accepté, Implémenté & **Mergé vers `main`** (branche `feature/combat_scaling`, PR #20, 6 commits, mergé le 2026-07-25 — livré aux joueurs via le patch note v0.4.5 "La Difficulté Mieux Maîtrisée") — corrige un bug de régression introduit par ADR-066. Poursuivi par ADR-071 (plafonnement du nombre d'ennemis + résolution de la dérive log/calcul), mergé dans la même branche via PR #21.

### Contexte
L'analyse des logs de debug de combat (`math_combat.md`) a révélé que `EncounterSystem` comptait l'Acte **deux fois** dans le scaling de puissance des ennemis : une première fois à l'intérieur de `getEnemyLevel()` (`playerLevel + (act - 1) * 2 + nodeModifier`), une seconde fois directement dans `getHpMultiplier()`/`getDamageMultiplier()` (`(1 + 0.35 * (act - 1))` / `(1 + 0.25 * (act - 1))`, coefficients portés à ces valeurs par ADR-066). Le jeu autorisant un nombre d'actes non plafonné (mode endless), ce double comptage devenait rapidement absurde : Acte 25 ≈ x36.5 HP / x18.2 Dégâts par le seul effet de l'Acte, alors que le budget de nombre/variété d'ennemis (`finalBudget`) ne croît que linéairement (+25/acte) et ne compense en rien cette accélération de puissance individuelle. Spec : `docs/superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md`. Plan d'implémentation (6 tâches TDD) : `docs/superpowers/plans/2026-07-24-combat-difficulty-scaling.md`.

### Décision
1. **Séparation stricte Niveau ↔ Acte** : `getEnemyLevel()` ne dépend plus que du niveau du joueur et du type de nœud — `enemyLevel = max(1, playerLevel + nodeModifier)`. L'Acte n'apparaît plus **nulle part** dans ce calcul, rendant le double comptage structurellement impossible plutôt que patché.
2. **Facteur d'Acte en escalier géométrique (bracket de 5 actes)** : nouvelles fonctions statiques pures sur `EncounterSystem` — `getActBracket(act)`, `getActPositionInBracket(act)`, `getHpActFactor(act)`, `getDamageActFactor(act)` :
   - $bracket = \lfloor (act-1)/5 \rfloor$, $positionInBracket = (act-1) \bmod 5$
   - $ActFactor_{HP} = 1.35^{bracket} \times (1 + 0.05 \times positionInBracket)$ ; $ActFactor_{Dmg} = 1.25^{bracket} \times (1 + 0.03 \times positionInBracket)$
   - Chaque palier de 5 actes accélère géométriquement (composé), tandis que la rampe intra-palier reste douce (max +20% HP / +12% Dégâts en fin de palier) et **se réinitialise** à chaque nouveau palier — un escalier à pente légère plutôt qu'une pente continue infinie.
   - `getHpMultiplier`/`getDamageMultiplier` gardent leur signature externe inchangée mais remplacent leur terme d'Acte linéaire par `getHpActFactor(act)`/`getDamageActFactor(act)`.
3. **Déblocage de tier d'ennemi tous les 10 actes** : `getUnlockedTier(act) = min(maxTierAuthored, 1 + floor((act-1)/10))` (`maxTierAuthored = 3`). `generateEnemiesForLevel` filtre `availableEnemies` à `tier <= unlockedTier` avant la sélection par budget, avec repli automatique sur le pool complet non filtré si ce filtre viderait la liste de candidats (évite un crash si seul du contenu haut-tier est passé pour un acte bas).
4. **Gating strict assumé, y compris pour le contenu déjà existant** (décision explicite validée en brainstorming, pas un oversight) : le Squelette (tier 2), auparavant accessible dès l'Acte 2 via la sélection molle par budget/`CombatRating`, ne sera plus disponible avant l'**Acte 11** une fois ce système en place. La montée en gamme des ennemis devient un jalon narratif prévisible plutôt qu'un effet de bord du budget.
5. **Budget de combat inchangé** : `ExpectedPower`/`BaseBudget` restent strictement linéaires (+20/+25 par acte). Le palier ne s'applique qu'à la puissance individuelle des ennemis (HP/Dégâts), jamais à leur nombre, pour éviter des combats à rallonge en fin de run.
6. **Hors périmètre à l'origine, résolu ensuite (voir ADR-071)** : la dérive connue entre `math_combat.md` (log de debug) et le calcul réel utilisé par le jeu (le log omettait `playerCardsCount * 2.0` et `+(act-1)*10.0`) n'était **pas** corrigée dans cette phase initiale — seule la description textuelle de la formule `enemyLevel` dans `combat_debug_logger.dart` avait été mise à jour. Cette dérive a été corrigée juste après, avant le merge final de la branche (commit `24d3148`).

> [!IMPORTANT]
> **Conséquence produit assumée — Backlog de contenu créé** : le gating strict de tier réduit la variété d'ennemis des Actes 1-10 au roster tier-1 actuellement disponible (Slime, Gobelin) jusqu'à ce que davantage d'ennemis tier-1 soient rédigés. Ce n'est pas un oversight mais un compromis de design conscient — voir `progress.md` (backlog Contenu) pour l'item de suivi.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : `getActBracket`, `getActPositionInBracket`, `getHpActFactor`, `getDamageActFactor`, `getUnlockedTier`, `maxTierAuthored` ; `getEnemyLevel` sans paramètre `act` ; `getHpMultiplier`/`getDamageMultiplier` réécrits ; filtre `eligibleEnemies`/`enemyPool` dans `generateEnemiesForLevel`.
- `lib/game/controllers/combat_controller.dart` : suppression de l'argument `act:` dans l'appel à `EncounterSystem.getEnemyLevel(...)`.
- `lib/game/services/combat_debug_logger.dart` : description de formule `enemyLevel` corrigée (`max(1, playerLevel + nodeModifier)`).
- `test/encounter_system_test.dart` : nouveaux groupes de tests pour les helpers de bracket/tier, `getEnemyLevel` indépendant de l'Acte, `getHpMultiplier`/`getDamageMultiplier` non double-comptés, et filtrage par tier de `generateEnemiesForLevel` (avec repli sur pool complet).

### Conséquences
- ✅ **Difficulté bornée en mode endless** : plus d'explosion incontrôlée de la puissance ennemie aux actes tardifs ; Acte 25 passe de ≈x36.5 HP (ancien, double-compté) à ≈x3.98 HP (nouveau, escalier).
- ✅ **Jalons de difficulté et de contenu lisibles** : palier de puissance tous les 5 actes, palier de nouveau tier d'ennemi tous les 10 actes.
- ✅ **Double comptage rendu impossible par construction** : l'Acte n'apparaît plus qu'à un seul endroit du calcul (les facteurs de bracket), pas juste corrigé numériquement.
- ✅ **Zéro régression** : suite de tests complète 201/201 au vert, `dart analyze` propre, revue de code de branche complète passée (3 constats mineurs de documentation/hygiène traités ou classés).
- ⚠️ **Variété d'ennemis réduite Actes 1-10** : nécessite l'ajout de nouveaux ennemis tier-1 pour maintenir la diversité de combat en début de run (item de backlog créé, non traité dans cette phase).
- ✅ **Mergé vers `main`** : la branche `feature/combat_scaling` a été mergée en deux temps — PR #20 (ce travail) puis PR #21 (travail de suivi, voir ADR-071) — livré aux joueurs (patch note v0.4.5, "La Difficulté Mieux Maîtrisée").
- ✅ **Dérive log/calcul résolue** dans le prolongement de cette branche, avant le merge final — voir ADR-071.
