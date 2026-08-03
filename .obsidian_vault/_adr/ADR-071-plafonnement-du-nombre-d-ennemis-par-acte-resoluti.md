## 🐛 ADR-071 : Plafonnement du Nombre d'Ennemis par Acte & Résolution de la Dérive Log/Calcul (branche `feature/combat_scaling`, suite d'ADR-070)

### Statut
✅ Accepté, Implémenté & **Mergé vers `main`** (branche `feature/combat_scaling`, PR #21, poursuite des commits sur la même branche après le merge initial d'ADR-070 via PR #20, 2026-07-25).

### Contexte
Après le merge de PR #20 (ADR-070), l'analyse du `combat_math.md` corrigé a révélé deux problèmes restants, tous deux explicitement différés par ADR-070 §6 :
1. **Dérive log/calcul confirmée** : `combat_controller.dart` dupliquait la formule `playerPower`/`finalBudget` d'`EncounterSystem` à des fins d'affichage seulement, et cette copie avait dérivé — elle omettait `playerCardsCount` dans `playerPower` et le bonus `+(act-1)*10` dans `finalBudget`, sous-estimant le budget réel utilisé pour générer les ennemis (de plus en plus au fil des cartes/actes accumulés).
2. **Nombre d'ennemis non plafonné de façon cohérente** : une fois le calcul de budget fiabilisé, il est apparu qu'un combat élite en début d'Acte 2 générait légitimement 3 ennemis faibles (Slime + Gobelin + Slime) au lieu d'un ou deux ennemis plus costauds — le multiplicateur de nœud élite (×1.5) combiné au gating strict de tier (ADR-070, tier 2 indisponible avant l'Acte 11) forçait le budget à s'écouler en empilant du tier 1 plutôt qu'en primant des ennemis plus rares.

Design : `docs/superpowers/specs/2026-07-25-enemy-count-scaling-design.md`. Plan : `docs/superpowers/plans/2026-07-25-enemy-count-scaling.md`.

### Décision
1. **Correction du log** : extraction d'un unique `EncounterSystem.calculateBudget()` utilisé à la fois par la génération réelle d'ennemis et par le log de debug (commit `24d3148`), éliminant structurellement tout risque de dérive future entre les deux.
2. **Plafond du nombre d'ennemis générés, croissant avec l'Acte, différencié par type de nœud**, ancré à 1 ennemi à l'Acte 1, sans plafond ultime (cohérence avec la philosophie endless d'ADR-070) :
   - `getMaxEnemiesForNormalCombat(act) = 1 + floor((act-1)/1)` (+1 par acte)
   - `getMaxEnemiesForElite(act) = 1 + floor((act-1)/2)` (+1 tous les 2 actes)
   - `getMaxEnemiesForBoss(act) = 1 + floor((act-1)/5)` (+1 tous les 5 actes)
   - Les trois partagent un helper privé `_maxEnemiesFromStep(act, stepSize)`.
3. **Câblage minimal dans `generateEnemiesForLevel`** : l'ancienne limite fixe (`generatedEnemies.length < 10`) est remplacée par le plafond act-scaled correspondant au type de nœud. Le budget continue de déterminer *si* le plafond est atteignable ; le plafond n'est qu'une borne supplémentaire.
4. **Budget non consommé au-delà du plafond est perdu**, sans bonus compensatoire aux ennemis déjà choisis — choix délibéré pour rester simple.
5. **Application symétrique assumée aux combats normaux** : le signalement initial ne portait que sur les élites/boss, mais le plafond s'applique aussi aux combats normaux (ex : 3 Slimes dès l'Acte 2 sous l'ancien système → plafonné à 2). Décision explicite de cohérence plutôt qu'un correctif ciblé.
6. **Système de vagues inchangé** (`enemies`/`pendingEnemies`, max 5 actifs) — il absorbe déjà nativement tout total généré au-delà de 5.
7. **Log de debug étendu** : `getMaxEnemiesFor{NormalCombat,Elite,Boss}(act)` est désormais loggé à côté des lignes de scaling HP/dégâts existantes.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : `_maxEnemiesFromStep`, `getMaxEnemiesForNormalCombat/Elite/Boss`, `calculateBudget()` (source de vérité unique), câblage dans `generateEnemiesForLevel`.
- `lib/game/controllers/combat_controller.dart` : appel à `EncounterSystem.calculateBudget()` au lieu d'une copie locale de la formule ; log du plafond d'ennemis.
- `lib/game/services/combat_debug_logger.dart` : ajout de `playerCardsCount` et du terme `+(act-1)*10` dans les lignes de formule affichées ; ajout des lignes de plafond d'ennemis.
- `test/encounter_system_test.dart`, `test/unit/combat_debug_logger_test.dart` : couverture des helpers de plafond, du budget unifié, et du cas combat normal à l'Acte 3 avec répartition vagues actives/réserve sous le nouveau plafond.

### Conséquences
- ✅ **Backlog ADR-070 §6 résolu** : le log de debug (`math_combat.md`) reflète désormais exactement le calcul réel de budget — plus de dérive entre le log et le comportement réel du jeu.
- ✅ **Combats mieux calibrés en début de run** : les élites/boss à faible Acte n'empilent plus artificiellement plusieurs ennemis tier-1 faibles pour épuiser un budget conçu pour un ennemi plus costaud.
- ✅ **Cohérence structurelle** : le plafond suit la même philosophie "escalier sans limite ultime" que le scaling HP/dégâts d'ADR-070, plutôt qu'une valeur fixe arbitraire (l'ancienne limite de 10).
- ✅ **Mergé vers `main`** dans la même PR (#21) qui a intégré l'ensemble de la branche `feature/combat_scaling`.
- ⚠️ **Backlog de contenu tier-1 toujours ouvert** (hérité d'ADR-070, non traité ici) : la variété d'ennemis des Actes 1-10 reste limitée à Slime/Gobelin.
- ✅ **Patch note joueur rédigé** : v0.4.7 "L'Équilibre des Effectifs" — voir `assets/data/patch_notes.json`.
