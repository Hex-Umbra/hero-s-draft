## 📈 ADR-072 : Resserrement de la Cadence du Scaling de Difficulté — Palier tous les 2 Actes & Tier tous les 5 Actes (branche `fix/combat_scaling`, suite d'ADR-070/ADR-071)

### Statut
✅ Accepté, Implémenté & **Mergé vers `main`** (branche `fix/combat_scaling`, commits `97c5fcb` puis `8bc1920`, 2026-07-26 — design et plan aux commits `940d548`/`0505d89` ; mergé via PR #22, commit de merge `b32e9e9`, 2026-07-26, aux côtés d'ADR-073) — suite de tests complète **211/211** au vert, `dart analyze` propre. Patch note joueur (v0.4.6, « Le Défi S'Intensifie ») rédigé par le sub-agent `patch_notes_writer` — voir `assets/data/patch_notes.json`.

### Contexte
Après le merge d'ADR-070/ADR-071 vers `main` (PR #20 + #21, patch note v0.4.5), un retour de playtest externe indique que **le joueur monte en puissance plus vite que les ennemis** : la difficulté reste perçue comme trop facile sur une portion significative de la run, malgré le palier géométrique HP/Dégâts (x1.35/x1.25 tous les 5 actes) et le déblocage de tier tous les 10 actes introduits par ADR-070. Deux options ont été envisagées — nerfer la puissance du joueur, ou accélérer le scaling ennemi en gardant les valeurs numériques actuelles mais en resserrant la cadence des paliers. La seconde a été retenue : l'objectif produit explicite est une **courbe de difficulté exponentielle assumée**, sans plafond ni plateau, cohérente avec la philosophie endless déjà actée par ADR-070/071.

Design : `docs/superpowers/specs/2026-07-26-difficulty-scaling-acceleration-design.md`. Plan : `docs/superpowers/plans/2026-07-26-difficulty-scaling-acceleration.md`.

### Décision
1. **Palier du facteur d'Acte (HP/Dégâts) resserré de 5 à 2 actes** : `EncounterSystem._actBracketSize` passe de `5` à `2` (commit `97c5fcb`). Les bases géométriques (x1.35 HP / x1.25 Dégâts par palier) et la rampe intra-palier (+5%/acte HP, +3%/acte Dégâts, réinitialisée à chaque palier) restent **strictement inchangées** — seule la fréquence de composition du palier change. `getActBracket`, `getActPositionInBracket`, `getHpActFactor`, `getDamageActFactor` gardent leur implémentation et leur signature, ils consomment simplement une constante plus petite.
2. **Cadence de déblocage de tier resserrée de 10 à 5 actes** : `EncounterSystem._tierUnlockBracketSize` passe de `10` à `5` (commit `8bc1920`). Tier 2 (Squelette) débloqué dès l'**Acte 6** (au lieu de l'Acte 11), tier 3 dès l'**Acte 11** (au lieu de l'Acte 21). `maxTierAuthored` reste `3`, inchangé.
3. **Rien d'autre ne change** : les formules de budget (`ExpectedPower`/`BaseBudget`/`FinalBudget`/`PowerModifier`/`NodeMultiplier`), le plafond du nombre d'ennemis par acte (ADR-071, `getMaxEnemiesForNormalCombat/Elite/Boss`), et la puissance du joueur (aucun nerf) sont explicitement hors périmètre et non modifiés.
4. **Trajectoire du facteur HP résultant** (base x1.35 inchangée, palier 5→2 actes) :

   | Acte | HP (ancien palier=5) | HP (nouveau palier=2) | Dégâts (ancien) | Dégâts (nouveau) |
   |---|---|---|---|---|
   | 10 | x1.62 | x3.49 | x1.40 | x2.51 |
   | 15 | x2.19 | x8.17 | x1.75 | x4.77 |
   | 20 | x2.95 | x15.64 | x2.19 | x7.67 |
   | 25 | x3.99 | x36.64 | x2.73 | x14.55 |

   Le temps de doublement de la puissance HP passe de ~11.5 actes à ~4.6 actes (Dégâts : ~15.5 → ~6.2 actes).
5. **Effet secondaire structurel identifié et assumé, non corrigé ici** : `FinalBudget` continue de croître linéairement avec l'Acte (+25/acte), alors que le coût individuel d'un ennemi (`CombatRating`) croît désormais exponentiellement via le facteur d'Acte resserré. Le nombre d'ennemis effectivement finançables par combat culmine vers l'Acte 10-12 puis redescend, glissant progressivement les combats de « plusieurs ennemis faibles » vers « un seul ennemi de plus en plus surpuissant » — déjà absorbé sans crash par le fallback existant de `generateEnemiesForLevel` (si aucun candidat n'entre dans le budget restant, l'ennemi au `CombatRating` le plus faible est choisi malgré tout). Ce glissement renforce, plutôt qu'il ne contredit, la courbe exponentielle sans plafond recherchée. Le plafond ADR-071 lui-même reste inchangé mais devient de moins en moins atteignable en pratique passé l'Acte ~12-15 pour les combats normaux.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : `_actBracketSize = 2` (ligne ~23), `_tierUnlockBracketSize = 5` (ligne ~24) ; doc-comments de `getActBracket`, `getActPositionInBracket`, `getHpActFactor`/`getDamageActFactor` et `getUnlockedTier` mis à jour pour refléter les nouvelles valeurs. Aucune autre ligne de logique métier modifiée.
- `test/encounter_system_test.dart` : valeurs attendues recalculées pour `getHpActFactor`/`getDamageActFactor` (palier de 2 actes), `getUnlockedTier` (tier 2 dès l'Acte 6, tier 3 dès l'Acte 11), `getHpMultiplier` (facteur de palier à l'Acte 11 recalculé), et bornes d'Acte des tests de filtrage tier de `generateEnemiesForLevel` (11 → 6). Suite complète 211/211 au vert.
- Aucun changement dans `lib/game/controllers/combat_controller.dart` ni `lib/game/services/combat_debug_logger.dart` — ces fichiers consomment déjà `getHpActFactor`/`getDamageActFactor`/`getUnlockedTier` et `calculateBudget()` sans dupliquer les constantes (cf. ADR-071), donc aucune dérive log/calcul possible par construction.

### Conséquences
- ✅ **Courbe de difficulté perçue accélérée dès le début de run**, répondant directement au retour de playtest (le joueur ne distance plus visiblement les ennemis sur les 10-15 premiers actes).
- ✅ **Zéro régression** : les bases géométriques, la rampe intra-palier, les formules de budget, le plafond d'ennemis (ADR-071) et la puissance du joueur sont bit-à-bit inchangés ; seules deux constantes entières changent de valeur. Suite de tests 211/211, `dart analyze` propre.
- ⚠️ **Fin de run endless plus punitive qu'auparavant, assumée** : à l'Acte 25, le facteur HP (x36.64) redevient proche en magnitude de l'ancien bug de double-comptage d'Acte qu'ADR-070 avait corrigé (~x36.5). C'est un trade-off explicite — l'objectif produit est justement une difficulté qui ne cesse de grimper.
- ⚠️ **Backlog de contenu tier-1 aggravé** (hérité d'ADR-070, non traité ici) : la fenêtre où seul le tier 1 (Slime, Gobelin) est disponible passe des Actes 1-10 aux Actes 1-5, rendant le besoin de contenu ennemi tier-1 supplémentaire plus pressant — voir `progress.md` (backlog Contenu).
- ⚠️ **Plafond du nombre d'ennemis (ADR-071) inchangé mais de moins en moins atteignable** en pratique passé l'Acte ~12-15 pour les combats normaux, du fait de l'effet budget-linéaire/coût-exponentiel décrit en Décision §5.
- ✅ **Mergé vers `main`** via PR #22 (commit de merge `b32e9e9`, 2026-07-26), aux côtés d'ADR-073 (réactivité du bouton « Continuer » de `HomeScreen`) ; patch note joueur (v0.4.6, « Le Défi S'Intensifie ») rédigé par le sub-agent `patch_notes_writer` — voir `assets/data/patch_notes.json`.
