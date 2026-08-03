## 🎛️ ADR-057 : Décomposition des Contrôleurs Globaux en Managers Spécialisés (v0.2.10)

### Statut
✅ Accepté & Implémenté (v0.2.10)

### Contexte
Les contrôleurs `RunController` et `CombatController` constituaient des classes monolithiques (God Classes) centralisant des responsabilités excessivement diverses : cycle de vie du run, progression sur la carte, gains de ressources (or, XP, niveaux), sauvegarde persistance, altérations d'état, riposte ennemie et flux de tour de combat. Cette concentration nuisait à la lisibilité, augmentait le couplage et rendait difficile l'isolation des règles de calcul pour les tests.

### Décision
- **Pattern Façade** : Transformer `RunController` et `CombatController` en façades légères préservant l'intégralité de leur API publique pour éviter de casser le code de l'interface UI (widgets Flutter) et la suite de tests.
- **Extraction des Managers de Run** : Déléguer les traitements du run à 4 classes spécialisées situées dans le sous-dossier `lib/game/controllers/run/` :
  1. `PlayerStatsManager` : Gère les points de vie, le mana, l'armure, les statistiques permanentes et le traitement du système d'expérience (XP et gains de niveau).
  2. `MapProgressionManager` : Gère le parcours et la complétion des nœuds de la carte stratégique ainsi que la transition entre les actes.
  3. `RunPersistenceManager` : Reçoit l'état et prépare l'écriture ou le chargement.
  4. `GoldManager` : Encapsule les transactions d'or et l'achat progressif de slots de forge.
- **Extraction des Managers de Combat** : Déléguer les traitements du combat à 2 classes spécialisées situées dans le sous-dossier `lib/game/controllers/combat/` :
  1. `StatusEffectProcessor` : Centralise le calcul des altérations d'état (Poison, Brûlure, Régénération de Force, Maîtrise d'Armure) de façon unifiée pour le joueur et les ennemis.
  2. `TurnPhaseManager` : Orchestre la transition des phases de tour (Joueur / Ennemi) et le déroulement séquentiel de la riposte ennemie.

### Preuves dans le code
- [run_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart) : Instancie les 4 managers et leur délègue ses appels de fonctions.
- [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) : Délègue le traitement des statuts à `StatusEffectProcessor` et les phases de tours à `TurnPhaseManager`.
- Sous-dossier [run/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run/) : Contient les classes métiers isolées de gestion du run.
- Sous-dossier [combat/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat/) : Contient les classes métiers de gestion du combat.

### Conséquences
- ✅ **Respect Strict du Principe de Responsabilité Unique (SRP)** : Chaque fichier possède un domaine logique restreint (stats, progression, or, statuts, phases), simplifiant la lecture.
- ✅ **Sécurité de Refactoring (Zéro Régression)** : L'utilisation du pattern Façade a garanti une non-régression absolue de la suite de tests automatisés (108/108 passés avec succès).
- ✅ **Maintenance Facilitée** : Les corrections ou équilibrages (par exemple, la formule d'XP ou le comportement d'un statut) se font dans des gestionnaires isolés et documentés.
