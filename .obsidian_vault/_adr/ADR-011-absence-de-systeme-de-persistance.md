## 💾 ADR-011 : Absence de Système de Persistance

### Statut
✅ **Résolu par ADR-069** (v3.2.0, Système de Sauvegarde de Run — Autosave). Section conservée pour la traçabilité historique du problème d'origine.

### Contexte
L'état logique de la run (`RunState`, `DeckState`, `CombatState`, `InventoryState`) réside uniquement en mémoire vive. Aucune dépendance de persistance (`shared_preferences`, `sqlite`) n'est dans le `pubspec.yaml`.

### Décision Actuelle
Pas de sauvegarde. Fermer l'app ou crash = perte totale de progression.

### Sérialisation Existante
Certains modèles ont déjà `fromJson`/`toJson` (`CombatState`, `EnemyInstance`, `EntityStats`, `StatusEffect`, `MapNode`), mais d'autres non (`CardInstance`, `InventoryState`, `SkillState`).

### Conséquences
- ❌ **Bloquant pour la commercialisation** : inacceptable pour un jeu mobile.
- 📋 **Identifié comme refactoring Phase 4** : créer un `SaveService` avec auto-save après chaque action majeure.
