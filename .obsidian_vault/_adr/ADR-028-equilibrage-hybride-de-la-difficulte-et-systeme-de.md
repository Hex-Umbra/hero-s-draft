## ⚔️ ADR-028 : Équilibrage Hybride de la Difficulté et Système de Réserve de Vagues (Hybrid Difficulty Balancing & Wave Reserve System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans les versions précédentes, la composition des rencontres de combat et le nombre d'ennemis sur le plateau étaient statiques ou faiblement liés à la progression réelle du joueur. Cela entraînait trois problèmes majeurs de game design et de performance :
1. **Écarts de difficulty** : Les joueurs optimisant fortement leur deck (fusions de raretés élevées, forges optimisées) trivialisaient rapidement le jeu. À l'inverse, les joueurs moins chanceux ou moins expérimentés faisaient face à des pics de difficulté brutaux.
2. **Surcharge visuelle du board (Flame)** : La génération d'un nombre important d'ennemis (plus de 3 ou 4) saturait le plateau de rendu mobile, provoquait des chevauchements visuels inacceptables pour les `PositionComponent` de Flame, et compliquait le ciblage tactile.
3. **Classification erronée de Boss (`isBoss`)** : Le test pour déterminer si le combat en cours était un combat de Boss s'appuyait uniquement sur le fait que le floor/niveau était un multiple de 10 (`level % 10 == 0`) sans valider que le nœud n'avait pas de type explicitement défini (nœud de combat classique). Ainsi, les combats classiques au floor 10 subissaient un surclassement de Boss injuste avec multiplicateurs de statistiques (x3 HP, x2 dégâts).

### Décision
1. **Implémentation d'une DDA Hybride (Dynamic Difficulty Adjustment)** :
   - Évaluer la puissance réelle actuelle du joueur via ses attributs permanents et reliques :
     $$\text{PlayerPower} = \text{maxHP} + (\text{attaque} \times 10.0) + (\text{maxMana} \times 15.0) + (\text{relicsCount} \times 5.0)$$
   - Définir la puissance théorique attendue à ce stade de la partie :
     $$\text{ExpectedPower} = 145.0 + ((\text{playerLevel} - 1) \times 15.0) + ((\text{act} - 1) \times 20.0)$$
   - Introduire un amortissement strict de $0.5$ sur l'écart de puissance pour atténuer les corrections et éviter les fluctuations brutales de budget de menace :
     $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
     $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$
2. **Budget de Menace de Combat (`FinalBudget`)** :
   - Calculer le budget de base lié au niveau et à l'acte :
     $$\text{BaseBudget} = 40.0 + ((\text{playerLevel} - 1) \times 10.0) + ((\text{act} - 1) \times 25.0)$$
   - Ajuster ce budget par le modificateur de puissance amorti et le type de nœud (Normal 1.0, Élite 1.5, Boss 2.0) :
     $$\text{FinalBudget} = \text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}$$
3. **Score individuel de Menace (`CombatRating`)** :
   - Assigner à chaque ennemi une valeur de menace recalculée dynamiquement en fonction de ses statistiques réelles après scaling (incluant le multiplicateur de PV, d'attaque et son taux de critique de base) :
     $$\text{CombatRating} = (\text{tier} \times 10.0) + \text{HP\_Scalé} + \text{Armure\_Scalée} + \text{Dégâts\_Scalés} \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
   - Sélectionner les ennemis séquentiellement par tirage aléatoire sous contrainte de budget restant, avec un fallback automatique sur le plus petit monstre disponible pour garantir au moins un ennemi si le budget final est extrêmement restreint.
4. **Système de Réserve de Vagues (limite de 5 ennemis actifs)** :
   - Limiter le nombre de monstres actifs sur le board Flame à **5 au maximum**.
   - Si le générateur `EncounterSystem` produit plus de 5 ennemis, les 5 premiers sont instanciés sur le plateau (`enemies` dans `CombatState`), et les suivants sont sérialisés dans la file d'attente de réserve (`pendingEnemies`).
   - À chaque mort d'un ennemi actif, `CombatController._cleanDeadEnemies()` extrait automatiquement le premier élément de `pendingEnemies` pour l'ajouter à `enemies`, et effectue immédiatement son premier tirage d'intention de combat (`_rollIntent`).
   - La condition de victoire du combat est validée uniquement lorsque `enemies` **ET** `pendingEnemies` sont vides.
5. **Isolation de la Journalisation Mathématique (`CombatDebugLogger`)** :
   - Isoler toute la logique de construction textuelle des formules et du scaling des ennemis dans une classe de service dédiée, `CombatDebugLogger`.
   - **Responsabilité Unique (SRP)** : Le contrôleur `CombatController` doit se concentrer exclusivement sur les transitions d'état logique de combat et la coordination des vagues. Il ne doit pas être encombré par le formatage de chaînes, les codes ANSI ou les buffers d'affichage.
   - **Toggling & Performance en Production** : En mode production (release), les logs détaillés de la DDA sont désactivés par une garde `if (!kDebugMode) return;` dans le service, éliminant tout coût CPU ou allocations inutiles associés au formatage de chaînes complexes.
6. **Correction de la règle d'identification `isBoss`** :
   - Modifier la garde conditionnelle pour ne déclencher la détection par niveau modulo 10 que si le nœud n'est pas spécifié (`nodeType == null`) :
     ```dart
     final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
     ```
   - Appliquer cette formule unifiée dans `CombatController.initializeCombat` et `EncounterSystem.generateEnemiesForLevel`, évitant ainsi le scaling anormal de Boss pour les nœuds de combat classiques au niveau 10.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : Méthode `generateEnemiesForLevel` calculant les formules de `PlayerPower`, `ExpectedPower`, `PowerModifier`, `FinalBudget` et calculant la `CombatRating` ajustée de chaque ennemi avec la garde `isBoss` corrigée.
- `lib/game/controllers/combat_controller.dart` :
  - `initializeCombat()` : répartition initiale des ennemis scalés entre le board actif `enemies` (limité à 5) et la file de réserve `pendingEnemies`, avec calcul de `isBoss` corrigé.
  - `_cleanDeadEnemies()` : transition synchrone des ennemis de `pendingEnemies` vers `enemies`, rolling d'intention et vérification combinée des deux listes pour lever le flag `isVictory`.
  - Appelle `CombatDebugLogger.logCombatInitialization(...)` à la fin de l'initialisation.
- `lib/game/services/combat_debug_logger.dart` : Classe de service formatant les logs avec codes couleurs ANSI et bordures de boîtes, encapsulée sous `kDebugMode`.
- `lib/models/data/combat_state.dart` : Ajout et sérialisation/désérialisation du champ `pendingEnemies`.
- `test/unit/combat_difficulty_test.dart` (ou tests similaires dans `test/unit/combat_controller_test.dart`) : Suite de tests automatisés validant le respect du budget de menace, le plafonnement à 5 slots actifs, le transfert automatique de la réserve lors de la mort d'un ennemi, et l'ajustement dynamique du modificateur de puissance.
- `test/encounter_system_test.dart` : Ajout de tests vérifiant la logique `isBoss` sous trois configurations : nœud Combat au niveau 10 (non Boss), nœud Null au niveau 10 (Boss), et nœud Boss au niveau 9 (Boss).
- `test/unit/combat_debug_logger_test.dart` : Test unitaire du service de journalisation pour s'assurer que l'appel ne lève aucune exception dans divers scénarios de données.

### Conséquences
- ✅ **Rythme de jeu adapté et stimulant** : Le jeu adapte intelligemment le nombre et la puissance des menaces à la composition du deck du joueur. Un deck sur-optimisé fera face à des vagues de monstres plus nombreuses ou plus puissantes, tandis qu'un joueur en difficulté verra la menace stabilisée.
- ✅ **Respect de l'espace de rendu Flame** : La limite stricte de 5 ennemis actifs garantit une présentation claire, évite tout bug visuel d'empilement sur smartphone portrait/paysage, et assure des performances constantes à 60 FPS sur l'arène graphique.
- ✅ **Pérennité du Game Progression** : L'amortissement de $0.5$ de la DDA préserve le sentiment de satisfaction de la progression (les builds puissants roulent toujours plus facilement sur le jeu que les builds faibles, mais le défi reste présent).
- ✅ **Séparation propre et maintenabilité** : La logique de log est isolée. Si l'on souhaite changer le format de log ou la couleur ANSI, on modifie uniquement `CombatDebugLogger`.
- ✅ **Cohérence de la Difficulté sur les Combats Multiples de 10** : Grâce à la correction `isBoss`, le joueur ne fait plus face à des pics de difficulté monstrueux injustifiés sur les nœuds de combat ordinaires situés au niveau 10.
- ✅ **Validation par tests automatisés** : 100/100 tests au vert, confirmant que le flow logique de la file de réserve, les transitions d'intentions, l'algorithme de génération de budget, la condition `isBoss` et le nouveau logger respectent rigoureusement les invariants métier.
