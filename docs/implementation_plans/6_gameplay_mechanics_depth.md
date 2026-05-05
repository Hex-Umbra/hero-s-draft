# Plan d'Implémentation 6 : Profondeur du Gameplay & Mécaniques de Combat

Ce document détaille le plan pour implémenter la Section 1 de l'analyse technique des évolutions futures (`docs/possible_upgrades/2_analyse_techniques_evols.md`). L'objectif est d'ajouter de la profondeur stratégique via des systèmes d'altérations d'état, des types de cartes spéciaux et des reliques.

## Phase 1 : Système d'Altérations d'État (Buffs/Debuffs)

L'objectif est de remplacer les variables de durée hardcodées (ex: `attackBuffDuration`) par un système flexible et extensible.

### 1.1 Modélisation
- Créer un fichier `lib/models/status_effect.dart`.
- Définir la classe `StatusEffect` :
  - `id` (String) : Identifiant unique (ex: 'poison', 'strength').
  - `name` (String) : Nom affichable.
  - `type` (Enum) : `buff` ou `debuff`.
  - `value` (int) : Valeur de l'effet (ex: dégâts de poison par tour, bonus de force).
  - `duration` (int) : Nombre de tours restants.
  - `isStackable` (bool) : Si l'effet se cumule ou se rafraîchit.

### 1.2 Intégration dans les Statistiques
- Modifier `EntityStats` (`lib/data/models/entity_stats.dart`) :
  - Ajouter `final List<StatusEffect> statuses;`.
  - Mettre à jour `copyWith` et les constructeurs.
- Mettre à jour `RunState` pour utiliser ce nouveau champ au lieu des variables isolées.

### 1.3 Logique de Combat (EffectResolver)
- Mettre à jour `lib/game/services/effect_resolver.dart` :
  - Ajouter un type d'effet `apply_status` dans le switch.
  - Modifier `_calculateDamage` pour prendre en compte les buffs/debuffs de force/faiblesse.
  - Gérer l'application automatique des effets de début de tour (ex: dégâts de poison).

### 1.4 Maintenance de l'État (RunController)
- Dans `RunController.startTurn()` :
  - Parcourir les statuts de l'héro.
  - Décrémenter la durée de chaque statut.
  - Supprimer ceux dont la durée tombe à 0.
- Faire de même pour les ennemis lors de leur début de tour.

---

## Phase 2 : Types de Cartes Spéciaux (Pouvoirs et Malédictions)

### 2.1 Cartes de Pouvoir (Power)
- **Concept** : Cartes qui appliquent un effet permanent pour le reste du combat.
- **Action** :
  - Lorsqu'une carte de type `power` est jouée, elle n'est pas envoyée dans la défausse.
  - Elle ajoute un statut spécial ou modifie une liste `activePowers` dans `RunState`.

### 2.2 Cartes de Malédiction (Curse) et Statut
- **Concept** : Cartes nuisibles ajoutées au deck par les ennemis.
- **Action** :
  - Créer des cartes dans `cards.json` avec le type `curse`.
  - Ces cartes ont souvent un coût injouable ou des effets négatifs lors de la défausse/pioche.

---

## Phase 3 : Reliques et Objets Passifs

### 3.1 Architecture des Reliques
- Créer `lib/models/data/relic_data.dart`.
- Propriétés : `id`, `name`, `description`, `trigger` (Enum: startOfRun, startOfCombat, startOfTurn, onCardPlayed, etc.).

### 3.2 Gestion des Reliques
- Ajouter `List<RelicData> relics` à `RunState`.
- Implémenter une méthode `applyRelics(RelicTrigger trigger, ...)` dans `RunController`.
- Appeler cette méthode aux points d'ancrage stratégiques dans le code de combat et de navigation.

---

## Phase 4 : Interface Utilisateur (UI)

### 4.1 Visualisation des Statuts
- Créer un composant Flame `StatusIcon` (ou mettre à jour `lib/game/components/effect_icon.dart`).
- Afficher une ligne d'icônes sous la barre de vie des entités avec le compteur de durée.

### 4.2 Feedback Visuel
- Utiliser `floating_text.dart` pour afficher les dégâts de poison ou les gains de force.

---

## Phase 5 : Validation et Tests

- **Tests Unitaires** : 
  - Vérifier que le cumul de poison fonctionne.
  - Vérifier que la force augmente bien les dégâts calculés dans `EffectResolver`.
- **Tests d'Intégration** : 
  - Jouer une carte "Power" et vérifier que son effet persiste après plusieurs tours.
  - Ramasser une relique et vérifier son déclenchement.
