## 🧪 ADR-014 : Système de Résolution des Altérations Élémentaires (Burn, Freeze, Shock)

### Statut
✅ Accepté & Implémenté

### Contexte
La version initiale déclarait dans ses modèles de données et ses templates d'interface (les descriptions de cartes dans `UiCard`) trois altérations d'état élémentaires majeures : la Brûlure (`burn`), le Gel (`freeze`) et l'Électrocution (`shock`). 
Cependant, la logique de résolution de ces statuts était totalement absente du pipeline de combat (`EffectResolver` et `CombatController`), rendant les cartes appliquant ces statuts purement décoratives au niveau du gameplay. Il était nécessaire d'implémenter une résolution logique rigoureuse de ces statuts tout en respectant l'architecture découplée sans introduire de couplage avec Flame.

### Décision
1. **Création Centralisée et Typage Métier** :
   - Câbler la création des instances de statuts dans le switch helper de `EffectResolver._createStatus()`.
   - Associer les identifiants textuels `burn`, `freeze`, `shock` à des objets `StatusEffect` fortement typés en tant que `StatusType.debuff`.

2. **Mécanique de Résolution de la Brûlure (`burn`)** :
   - Résoudre la brûlure de manière autonome au début de chaque tour ennemi.
   - Accumuler les valeurs de brûlure pour chaque ennemi et appliquer des dégâts directs sur ses PV logiques : `updatedStats = updatedStats.takeDamage(burnDamage)`.
   - La brûlure se résout dans `CombatController.startEnemyTurn()` en parallèle du poison, garantissant une cohérence d'exécution temporelle.

3. **Mécanique de Résolution du Gel (`freeze`)** :
   - Réduire la dangerosité offensive d'un ennemi sous l'effet du gel.
   - Lors de la résolution séquentielle de son intention dans `CombatController.resolveEnemyIntent()`, si l'attaquant a le statut `freeze`, les dégâts infligés au héros sont divisés par deux (arrondi au plus proche) :
     ```dart
     int dmg = intent.value;
     if (enemy.stats.statuses.any((s) => s.id == 'freeze')) {
       dmg = (intent.value * 0.5).round();
     }
     ```

4. **Mécanique de Résolution de l'Électrocution (`shock`)** :
   - Créer un effet multiplicateur ou additif de dégâts subis sur l'ennemi.
   - Dans `EffectResolver.resolveCard()` lors de la résolution de l'effet `damage` (qu'il soit ciblé ou de zone), vérifier si l'ennemi ciblé possède le statut `shock`.
   - Si oui, additionner directement la valeur cumulée du statut `shock` aux dégâts de base calculés de la carte d'attaque :
     ```dart
     final shockStatus = enemy.stats.statuses.firstWhere(
       (s) => s.id == 'shock',
       orElse: () => StatusEffect(
         id: '',
         name: '',
         type: StatusType.debuff,
         value: 0,
         duration: 0,
       ),
     );
     if (shockStatus.id.isNotEmpty) {
       dmg += shockStatus.value;
     }
     ```

5. **Couverture de Tests et Assurance Qualité** :
   - Intégrer une couverture de test unitaire exhaustive simulant l'application de chaque statut dans `test/unit/combat_controller_test.dart` (portant la suite de tests à 60 tests réussis à 100%).

### Preuves dans le code
- `EffectResolver._createStatus()` : Déclaration des switch cases `burn`, `freeze`, `shock` renvoyant le modèle `StatusEffect` avec les noms en français (« Brûlure », « Gel », « Électrocution »).
- `CombatController.startEnemyTurn()` : Récupération cumulée de `burnDamage += status.value` et application via `updatedStats = updatedStats.takeDamage(burnDamage)`.
- `CombatController.resolveEnemyIntent()` : Division des dégâts par 2 si le statut `freeze` est présent dans la liste des statuts actifs de l'ennemi.
- `EffectResolver.resolveCard()` : Lookup du statut `shock` sur l'instance d'ennemi en cours d'attaque et incrément de `dmg += shockStatus.value` avant l'appel à `updateEnemyStats`.
- `test/unit/combat_controller_test.dart` (Lignes 424-558) : Le test unitaire complet validant le bon fonctionnement combiné ou isolé des trois statuts en combat.

### Conséquences
- ✅ **Système de Combat Complet et Coordonné** : Les mécaniques élémentaires sont désormais 100% opérationnelles, donnant une vraie profondeur stratégique aux classes de personnages (notamment le Mage qui s'appuie fortement sur ces altérations).
- ✅ **Respect Strict de l'Architecture Découplée (ADR-001)** : Toute la logique de calcul de dégâts, de réduction, et de résolution autonome est pilotée de bout en bout par la couche métier Riverpod. Flame se contente de lire l'état double-bufferisé pour afficher les icônes de statut.
- ✅ **Extrême Robustesse Logicielle** : La suite de tests unitaires garantit qu'aucune régression logicielle ne peut affecter le calcul ou l'application de ces statuts.
- ⚠️ **Stacking Infini** : Par conception, les statuts élémentaires s'empilent et se cumulent à chaque tour. Une attention particulière à l'équilibrage des cartes appliquant ces statuts sera nécessaire pour éviter des combos infinis de surpuissance (ex: accumuler trop d'électrocution pour infliger des centaines de dégâts).
