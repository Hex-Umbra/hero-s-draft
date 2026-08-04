### 2.5. Bestiaire

**4 ennemis** définis dans `enemies.json` :

| ID | Nom | HP | Dégâts Base | Tier | Pattern d'Intentions | Crit Chance |
|:---|:---|:---|:---|:---|:---|:---|
| `slime` | Slime | 18 | 4 | 1 | [attack:4] — attaque unique répétée | 5% |
| `gobelin` | Gobelin | 28 | 5 | 1 | [attack:5] — attaque unique | 10% |
| `squelette` | Squelette | 22 | 8 | 2 | [attack:8, attack:10] — cycle 2 attaques | 10% |
| `orc` | Orc Furieux | 50 | 8 | 3 | [attack:8, buff:2, attack:12] — cycle 3 phases | 15% |

> [!IMPORTANT]
> **Refonte du Scaling de Difficulté par Acte — Escalier Géométrique & Déblocage de Tier (branche `feature/combat_scaling`, mergée vers `main` via PR #20, livrée en v0.4.5)** :
> L'ancien système comptait l'Acte **deux fois** : une fois dans `enemyLevel`, une seconde fois directement dans les multiplicateurs HP/Dégâts (introduits par ADR-066), provoquant une explosion de difficulté incontrôlée en mode endless (ex : Acte 25 ≈ x36.5 HP par le seul effet de l'Acte). La correction rend `enemyLevel` **strictement indépendant de l'Acte** — l'Acte n'apparaît plus que dans un facteur d'escalier géométrique dédié, ce qui rend le double comptage impossible par construction plutôt que patché numériquement. Voir `decisionLog.md` (ADR-070) pour l'arbitrage complet et `docs/superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md` pour les valeurs numériques détaillées.

> [!IMPORTANT]
> **Accélération de la Cadence du Scaling de Difficulté (branche `fix/combat_scaling`, mergée vers `main` via PR #22, ADR-072)** :
> Suite à un retour de playtest indiquant que le joueur monte en puissance plus vite que les ennemis, la *cadence* du système ci-dessus (bases numériques inchangées) a été resserrée : le palier géométrique HP/Dégâts passe de 5 à **2 actes**, et le déblocage de tier de 10 à **5 actes**. Conséquence assumée : une courbe de difficulté exponentielle sans plafond, plus punitive en fin de run endless (facteur HP à l'Acte 25 : x36.64, proche en magnitude de l'ancien bug de double-comptage corrigé par ADR-070) — trade-off explicitement voulu, pas une régression. Voir `decisionLog.md` (ADR-072) et `docs/superpowers/specs/2026-07-26-difficulty-scaling-acceleration-design.md`.

**Scaling de combat** (`CombatController.initializeCombat` / `EncounterSystem`) :
- **Niveau d'ennemi** ($EnemyLevel$) : $EnemyLevel = \max(1, PlayerLevel + NodeModifier)$, où $NodeModifier$ est de $+2$ pour un Boss et $+1$ pour un Élite. **L'Acte n'intervient plus dans ce calcul.**
- **Facteur d'Acte en escalier géométrique** (palier de **2 actes**, resserré de 5 à 2 actes par ADR-072) :
  - $bracket = \lfloor (Act - 1) / 2 \rfloor$, $positionInBracket = (Act - 1) \bmod 2$
  - $ActFactor_{HP} = 1.35^{bracket} \times (1 + 0.05 \times positionInBracket)$
  - $ActFactor_{Dmg} = 1.25^{bracket} \times (1 + 0.03 \times positionInBracket)$
  - Chaque palier de 2 actes accélère géométriquement (composé, bases inchangées), tandis que la rampe intra-palier reste douce (max +5% HP / +3% Dégâts en fin de palier, un seul acte de ramp désormais) et **se réinitialise** à chaque nouveau palier.
- **Multiplicateurs finaux appliqués aux statistiques de base de l'ennemi** :
  - **Multiplicateur HP** : $(1.0 + 0.06 \times (EnemyLevel - 1)) \times ActFactor_{HP} \times NodeMultiplier$
  - **Multiplicateur Dégâts** : $(1.0 + 0.04 \times (EnemyLevel - 1)) \times ActFactor_{Dmg} \times NodeMultiplier$
  - Où $NodeMultiplier$ vaut $3.0$ pour un Boss, $1.5$ pour un Élite, et $1.0$ sinon.
- **Déblocage de tier d'ennemi tous les 5 actes** (resserré de 10 à 5 actes par ADR-072) : $UnlockedTier = \min(3, 1 + \lfloor (Act - 1)/5 \rfloor)$. Le pool d'ennemis disponibles est filtré à `tier <= UnlockedTier` avant la sélection par budget (repli automatique sur le pool complet si ce filtre viderait la sélection). **Gating strict assumé** : le Squelette (tier 2), auparavant accessible dès l'Acte 2 via la sélection molle par budget, n'est plus disponible avant l'**Acte 6** (tier 3 avant l'**Acte 11**). Ce compromis de design conscient réduit la variété d'ennemis des Actes 1-5 (fenêtre resserrée depuis les Actes 1-10) au roster tier-1 actuel (Slime, Gobelin) jusqu'à l'ajout de nouveaux ennemis tier-1 (voir `docs/ROADMAP.md`, P-05).
- *Comparaison Acte 25 (effet de l'Acte isolé, niveau joueur constant) : ancien système double-compté ≈ x36.5 HP / x18.2 Dégâts → palier 5 actes (ADR-070) ≈ x3.99 HP / x2.73 Dégâts → palier 2 actes (ADR-072, actuel) ≈ x36.64 HP / x14.55 Dégâts.*

> [!IMPORTANT]
> **Règle de Détermination de Boss (`isBoss`)** :
> Un ennemi ou un combat est classifié comme de type Boss si et seulement si :
> 1. Le nœud de la carte est explicitement de type Boss (`nodeType == MapNodeType.boss`).
> 2. Le type de nœud n'est pas spécifié/null (`nodeType == null`) **ET** le niveau/floor de la run est supérieur à 0 et divisible par 10 (`level > 0 && level % 10 == 0`).
> 
> *Raison de la correction* : Auparavant, toute rencontre au floor 10 (ou multiple de 10) était tagguée comme Boss, même si le joueur se trouvait sur un nœud de combat standard (`MapNodeType.combat`), appliquant à tort un multiplicateur massif de statistiques ($3.0 \times$ HP / $2.0 \times$ Dégâts). La correction garantit que les modificateurs de boss ne s'appliquent pas aux nœuds de combat classiques, préservant ainsi l'équilibrage de la courbe de difficulté.


| Type | Multiplicateur HP de Base | Multiplicateur Attaque de Base | Nombre |
|:---|:---|:---|:---|
| Normal (level ≤5) | ×1.0 | ×1.0 | 1-2 |
| Normal (level >5) | ×1.0 | ×1.0 | 1-3 |
| Élite | ×1.5 | ×1.5 | 2-3 |
| Boss | ×3.0 | ×2.0 | 1 |
