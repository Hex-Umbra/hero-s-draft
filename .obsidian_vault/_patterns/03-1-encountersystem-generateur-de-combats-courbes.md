### 3.1. `EncounterSystem` — Générateur de Combats & Courbes d'Équilibrage

**Type** : Classe statique utilitaire (sans état, appelée lors de l'initialisation du combat).

**Méthode** :
```dart
static List<EnemyData> generateEnemiesForLevel(
  int level,
  List<EnemyData> availableEnemies, {
  MapNodeType? nodeType,
  int playerLevel = 1,
  int act = 1,
  int playerMaxHp = 100,
  int playerAttaque = 0,
  int playerMaxMana = 3,
  int playerRelicsCount = 0,
  int playerCardsCount = 0,
})
```

**Logique de Dimensionnement et Algorithme d'Équilibrage** :
1. **Évaluation de la Puissance Réelle du Joueur (`PlayerPower`)** :
   $$\text{PlayerPower} = \text{playerMaxHp} + (\text{playerAttaque} \times 10.0) + (\text{playerMaxMana} \times 15.0) + (\text{playerRelicsCount} \times 5.0) + (\text{playerCardsCount} \times 2.0)$$
2. **Puissance Théorique Attendue (`ExpectedPower`)** :
   $$\text{ExpectedPower} = 145.0 + ((\text{playerLevel} - 1) \times 15.0) + ((\text{act} - 1) \times 20.0)$$
3. **Budget de Base théorique (`BaseBudget`)** :
   $$\text{BaseBudget} = 40.0 + ((\text{playerLevel} - 1) \times 10.0) + ((\text{act} - 1) \times 25.0)$$
4. **Calcul du Budget Final (`FinalBudget`)** :
   Le ratio de puissance est pondéré par un facteur d'amortissement de $0.5$ pour stabiliser la courbe, et un bonus fixe de $+10.0$ par acte supplémentaire au-delà de l'acte 1 est appliqué :
   $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
   $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$
   $$\text{FinalBudget} = (\text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}) + ((\text{act} - 1) \times 10.0)$$
   *(Avec `NodeMultiplier` = 1.0 pour normal, 1.5 pour élite, 2.0 pour boss)*

5. **Formule du Niveau Ennemi (`getEnemyLevel`)** — *branche `feature/combat_scaling`, mergée vers `main` (voir ADR-070)* :
   $$EnemyLevel = \max(1, PlayerLevel + NodeModifier)$$
   *(Avec `NodeModifier` = 2 pour boss, 1 pour élite, 0 sinon). L'Acte n'apparaît plus dans cette formule — voir point 5bis.*

   La classification de Boss suit la règle unifiée :
   ```dart
   final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
   ```
   Si `isBoss` est vrai, `NodeModifier` est de `2` et `NodeMultiplier` de `2.0` (pour le budget) ou `3.0` (pour HP de base) et `2.0` (pour l'attaque de base). Si `isElite` est vrai (`nodeType == MapNodeType.elite`), `NodeModifier` est de `1` et `NodeMultiplier` de `1.5`. Sinon, ils valent respectivement `0` et `1.0`.

5bis. **Facteur d'Acte en Escalier Géométrique (`getHpActFactor`/`getDamageActFactor`)** — remplace l'ancien terme linéaire direct qui, combiné à l'Acte déjà présent dans `enemyLevel`, provoquait un double comptage (ADR-070) ; cadence resserrée de 5 à 2 actes par ADR-072 (branche `fix/combat_scaling`, mergée vers `main` via PR #22) :
   ```dart
   static int getActBracket(int act) => ((act - 1) / 2).floor();
   static int getActPositionInBracket(int act) => (act - 1) % 2;
   static double getHpActFactor(int act) =>
       pow(1.35, getActBracket(act)) * (1.0 + getActPositionInBracket(act) * 0.05);
   static double getDamageActFactor(int act) =>
       pow(1.25, getActBracket(act)) * (1.0 + getActPositionInBracket(act) * 0.03);
   ```
   Chaque palier de **2 actes** multiplie géométriquement (x1.35 HP / x1.25 Dégâts, composé — bases inchangées depuis ADR-070), la rampe intra-palier restant douce (max +5% HP / +3% Dégâts en fin de palier, un seul acte de ramp désormais) et se réinitialisant à chaque nouveau palier. Trajectoire résultante non plafonnée assumée (ADR-072) : facteur HP ≈ x3.49 à l'Acte 10, ≈ x36.64 à l'Acte 25.

5ter. **Déblocage de Tier d'Ennemi (`getUnlockedTier`)** — tous les 5 actes, plafonné à `maxTierAuthored = 3` (cadence resserrée de 10 à 5 actes par ADR-072) :
   ```dart
   static int getUnlockedTier(int act) {
     final unlocked = 1 + ((act - 1) / 5).floor();
     return unlocked > maxTierAuthored ? maxTierAuthored : unlocked;
   }
   ```
   `generateEnemiesForLevel` filtre `availableEnemies` à `tier <= unlockedTier` avant la sélection par budget (repli sur le pool complet non filtré si ce filtre viderait la liste de candidats). **Gating strict** : le Squelette (tier 2) n'est plus sélectionnable avant l'Acte 6 (tier 3 avant l'Acte 11).

6. **Formule du CombatRating de l'Ennemi** :
   Le coût de menace de chaque type d'ennemi est évalué à l'aide de ses statistiques simulées mises à l'échelle pour le niveau de combat, en atténuant l'impact des PV bruts (divisé par 4) et en augmentant l'impact des dégâts (multiplié par 2) pour favoriser l'apparition de groupes d'ennemis :
   $$\text{CombatRating} = (\text{tier} \times 15.0) + \frac{\text{HP\_Scalé}}{4.0} + (\text{Dégâts\_Scalés} \times 2.0) \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
   Où :
   - $$\text{HP\_Scalé} = \text{round}(\text{maxHp} \times \text{HpMultiplier})$$ avec $\text{HpMultiplier} = (1.0 + 0.06 \times (EnemyLevel - 1)) \times ActFactor_{HP} \times NodeMultiplier$
   - $$\text{Dégâts\_Scalés} = \text{round}(\text{baseDamage} \times \text{DamageMultiplier})$$ avec $\text{DamageMultiplier} = (1.0 + 0.04 \times (EnemyLevel - 1)) \times ActFactor_{Dmg} \times NodeMultiplier$
   - $ActFactor_{HP}$/$ActFactor_{Dmg}$ = `getHpActFactor(act)`/`getDamageActFactor(act)` du point 5bis.

7. **Sélection Procédurale par Budget** :
   - Filtre d'abord le pool d'ennemis candidats par tier débloqué (point 5ter).
   - Initialise `remainingBudget = FinalBudget`.
   - Boucle tant que le budget est positif et que la limite de 10 monstres (actifs + réserve) n'est pas atteinte.
   - Filtre les candidats dont le `CombatRating` individuel est inférieur ou égal à `remainingBudget`.
   - Si des candidats existent, tire aléatoirement l'un d'eux, l'ajoute au combat et déduit sa valeur du budget.
   - **Fallback** : Si aucun monstre ne rentre (budget insuffisant pour le plus petit monstre), ajoute d'office le monstre au plus petit `CombatRating` pour garantir au moins une menace.
