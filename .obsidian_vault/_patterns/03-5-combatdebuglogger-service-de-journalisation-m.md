### 3.5. `CombatDebugLogger` — Service de Journalisation Mathématique du Combat

**Type** : Service de journalisation dédié (`lib/game/services/combat_debug_logger.dart`).

**Responsabilités** :
- **Séparation des Responsabilités (SRP)** : Centraliser le formatage et l'affichage des logs détaillés d'initialisation de combat (DDA, calculs de budgets, modificateurs et ennemis générés), déchargeant ainsi `CombatController` de toute logique d'affichage textuelle.
- **Journalisation Conditionnelle** : Encapsuler les appels de log dans un wrapper `kDebugMode` (de `package:flutter/foundation.dart`) pour garantir qu'aucun traitement de journalisation ni de surcharge de StringBuffer ne s'exécute ou ne consomme de ressources en production (mode release).
- **Stylisation ANSI et Structure Visuelle** : Structurer les sorties de log sous forme d'un tableau délimité par des bordures en boîte ANSI (`┌`, `│`, `└`) avec des codes de couleurs ANSI (vert pour les calculs réussis, jaune pour les en-têtes de sections, magenta pour les ennemis scalés, rouge pour le titre de combat, cyan pour les bordures) pour une lisibilité maximale dans les consoles de débogage.

**Structure de Log d'Initialisation** :
1. **👤 Statistiques Joueur** : Level, Act, type de nœud, HP, Puissance (`Might`), Mana, nombre de Reliques, et le terme de deck — « Cards » jusqu'à la vague 2, **« Σ rangs »** (`deckFusionRanks`) sur la branche de la vague 3 ([ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)).
2. **📊 Formules et Calculs (DDA)** : Formule et évaluation de `PlayerPower`, `ExpectedPower`, `BaseBudget`, `PowerRatio`, `PowerModifier` et `FinalBudget`. La formule écrite en clair dit « 2 × Σ rangs » à la place de « cardsCount * 2 », dans son texte comme dans son calcul ([`_rules/02-6`](../_rules/02-6-equilibrage-hybride-budget-de-menace-et-reser.md)).
3. **⚙️ Détails du Scaling** : Niveau calculé des ennemis, multiplicateurs de HP et de dégâts appliqués.
4. **👾 Liste des Ennemis Générés** : Nom (EN), Tier, HP finaux après scaling, Dégâts finaux après scaling, et `CombatRating` calculé.
