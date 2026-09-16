# Archive — historique des releases sorti de `progress.md` le 2026-09-16

Rotation FIFO du tableau `## 4. Historique des releases (10 dernières)` de
`_memory_bank/progress.md` : l'entrée `0.5.2` y est entrée, la plus ancienne en est
sortie. Ligne conservée **verbatim**, jamais réécrite.

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v3.2.0** | 2026-07-24 | Système de Sauvegarde et Persistance de Run (Autosave) | Résolution du point bloquant de commercialisation ADR-011 : `SaveService` (`shared_preferences`, slot unique, JSON versionné) sauvegardant `RunState`/`DeckState`/`InventoryState`/`SkillState` à chaque checkpoint carte (`checkpointProvider`/`autosaveOrchestratorProvider`), jamais en cours de combat. Bouton "Continuer" et dialogue de confirmation sur `HomeScreen`. Dégradation gracieuse du contenu manquant (cartes/reliques/upgrades/passifs supprimés du catalogue) avec avertissement nommé au joueur. Sauvegarde corrompue traitée comme échec total sans récupération partielle. Sauvegarde effacée à la mort du héros. Suppression du stub mort `RunPersistenceManager`. Voir ADR-069. |
