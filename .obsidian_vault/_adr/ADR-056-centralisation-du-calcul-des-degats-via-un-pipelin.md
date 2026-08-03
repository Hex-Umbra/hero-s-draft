## ⚔️ ADR-056 : Centralisation du Calcul des Dégâts via un Pipeline Unique (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. Les calculs de dégâts (physiques, magiques, compétences, intentions de monstres) étaient dispersés dans le code entre `EffectResolver` (pour les cartes de combat) et `CombatController` (pour les intentions des ennemis et les compétences du héros).
2. Cette duplication présentait un risque élevé de désynchronisation des modificateurs d'état lors des calculs (par exemple, des différences dans l'application de la faiblesse, de la vulnérabilité, du choc, ou des calculs de coup critique).
3. Il était indispensable d'unifier ce calcul sous un service unique afin de garantir que les règles de calcul de combat restent prévisibles, centralisées et faciles à équilibrer ou modifier à l'avenir.

### Décision
1. **Création de DamagePipeline** : Définir un service centralisé `DamagePipeline.calculate` (`lib/game/services/damage_pipeline.dart`) qui prend en charge toutes les étapes logiques de calcul de combat :
   - Étape 1 : Application de la réduction de 25% de dégâts si l'attaquant possède le statut `weakness`.
   - Étape 2 : Jet de coup critique basé sur `effectiveCritChance` de l'attaquant. Si réussi, application du multiplicateur `critMultiplier` et enregistrement du flag `lastActionWasCrit` sur l'attaquant (nécessaire pour les animations Flame).
   - Étape 3 : Ajout de la valeur de débuff `shock` accumulée par le défenseur.
   - Étape 4 : Application du bonus de dégâts de 50% si le défenseur possède le statut `vulnerable`.
2. **Refactoring des Appelants** : Remplacer les calculs dispersés dans `CombatController.executeSkill`, `CombatController.resolveEnemyIntent` et `EffectResolver._calculateDamage` par un appel unique à `DamagePipeline.calculate`.
3. **Garantie DRY** : Suppression complète des switches et logiques de statuts dupliquées pour le calcul de dégâts.

### Preuves dans le code
- [damage_pipeline.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/damage_pipeline.dart) : Création de la classe avec sa logique métier en 4 étapes.
- [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) : Utilisation du pipeline pour calculer les dégâts reçus ou infligés.
- [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart) : Suppression du calcul local au profit de l'appel au pipeline centralisé.

### Conséquences
- ✅ **Calculs de Combat Garantis Homogènes** : Le héros et les monstres sont soumis aux mêmes règles et mécaniques, sans dérive de calcul possible.
- ✅ **Facilité d'Équilibrage** : La modification d'un coefficient ou l'ajout d'une nouvelle règle de calcul de dégâts globale s'effectue en une seule ligne de code.
- ✅ **Lisibilité Accrue** : Réduction sensible de la taille de `EffectResolver` et de `CombatController` grâce à l'externalisation de la formule mathématique.
- ✅ **Zéro Régression** : Tous les tests unitaires et d'intégration existants (108) passent sans anomalie.
