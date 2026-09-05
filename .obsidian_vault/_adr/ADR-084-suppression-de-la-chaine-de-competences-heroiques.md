### Statut

✅ **Livré le 2026-09-04**, commit `ced306e`, bloc 1 du chantier P-40.
Retire du jeu un système décrit par [ADR-003](ADR-003-architecture-100-data-driven.md) parmi
les huit catalogues d'origine. **14 fiches du vault nommaient un de ses symboles** —
`git grep -lE 'SkillController|SkillState|SkillData|skillProvider|tickCooldowns|triggerSkill|onExecuteSkill|skill_controller|skill_data|skills\.json' ac37596 -- .obsidian_vault/_rules/ .obsidian_vault/_patterns/`
— et trois de plus le décrivaient en prose sans le nommer (`_rules/03-3`, `_rules/03-13`,
`_rules/09-1`). `_rules/05-00` et `_patterns/02-7`, entièrement consacrées à lui, sont
archivées verbatim dans `../_archive/2026-09-05-competences-heroiques.md` ; les autres n'en
portaient qu'une mention ou une colonne, corrigées sur place, leur reste étant vivant.
Une première estimation à trois, faite sans lancer ce `grep`, avait manqué les autres.

### Contexte

Le système de compétences héroïques — 6 compétences, 2 par classe — était présent dans le
dépôt depuis les premières versions : un catalogue `assets/data/skills.json`, un modèle
`SkillData`, un état `SkillState`, un `SkillController` avec ses cooldowns, deux méthodes
`executeSkill`, un callback `onExecuteSkill`, et un champ `skills` dans la sauvegarde.

**Il n'avait aucun point d'entrée.** Personne n'appelait `HerosDraftGame.executeSkill`, et
aucun bouton de compétence n'existait dans `lib/ui/`. Le joueur ne pouvait donc, par aucun
chemin, déclencher une compétence.

Pire : les 6 entrées de `skills.json` ne correspondaient à **aucun identifiant réel**. Le
champ `skills` d'une classe pointait vers ses cartes de signature, pas vers ce catalogue. Les
deux ensembles n'avaient jamais été reliés.

`SkillData` portait par ailleurs la seule violation d'une règle explicite du projet : un
`final String name` unique là où `CLAUDE.md` impose `_fr`/`_en` sur toute entrée à texte
visible. Le chantier P-26 prévoyait de le localiser.

Deux voies : brancher le système, ou le supprimer. Le brancher aurait demandé de concevoir
une UI, d'équilibrer six compétences jamais jouées, et de relier deux ensembles
d'identifiants disjoints — pour une mécanique qu'aucune spec ne réclamait.

### Décision

**D1 — Supprimer la chaîne entière plutôt que la brancher.** Un système sans appelant n'est
pas une fonctionnalité en attente : c'est du code que la relecture, les tests et les
chantiers de données doivent porter sans contrepartie.

**D2 — Localiser plutôt que supprimer aurait été le mauvais ordre.** Le tiers « `SkillData`
bilingue » de P-26 est **annulé** : on ne traduit pas en deux langues un modèle destiné à
disparaître.

**D3 — Conserver les deux homonymes, explicitement.** `HeroData.skills` est la liste des `id`
des deux cartes de signature d'une classe, lue par le tutoriel et le draft de départ ; elle
n'a aucun rapport avec ce système. `applyLifestealBuff` vit dans `RunController`, pas dans le
système de compétences, et P-41 s'en sert — elle reste, désormais sans point d'entrée.

**D4 — Aucune migration de sauvegarde.** Les trois lignes de `save_service.dart` (écriture,
lecture, hydratation) partent **ensemble** : une sauvegarde existante conserve une clé
`skills` simplement jamais relue. `schemaVersion` reste à 1. Un test épingle cette garantie
avant la suppression.

### Preuves dans le code

- **Absents du dépôt** : `assets/data/skills.json`, `lib/models/data/skill_data.dart`,
  `lib/models/skill_state.dart`, `lib/game/controllers/skill_controller.dart`.
- `GameDataRegistry` (`lib/models/data/game_data_registry.dart`) n'expose plus de champ
  `skills` — sept listes d'entités et `audio`.
- `HeroData.skills` et `HeroSkillsLink.getHeroCards()`
  (`lib/models/data/hero_skills_link.dart`) subsistent, appelés par
  `lib/ui/screens/starter_deck_draft_screen.dart`.
- `applyLifestealBuff` subsiste en **paire** : `RunController.applyLifestealBuff`
  (`lib/game/controllers/run_controller.dart:438`) n'a plus aucun appelant et délègue à
  `PlayerStatsManager.applyLifestealBuff` (`lib/game/controllers/run/player_stats_manager.dart:475`),
  que rien d'autre n'appelle. C'est la façade qui est morte, pas l'implémentation — vérifié
  le 2026-09-05, `grep -rn "applyLifestealBuff" lib/ test/` rendant exactement trois lignes.
- Compatibilité de sauvegarde couverte par `test/unit/save_service_test.dart`.

### Conséquences

- ✅ **−544 lignes** pour +49, sur 34 fichiers.
- ✅ **Débloque le chantier P-48** : tous ses chiffrages supposaient ce catalogue purgé.
- ✅ La violation `_fr`/`_en` de `CLAUDE.md` disparaît par suppression, pas par traduction.
- ⚠️ **8 tests disparaissent avec le système qu'ils couvraient** (385 → 377 au moment du
  commit) : `skill_controller_test`, `skill_state_persistence_test`, un test de
  `notifier_hydrate_test`, le bloc `executeSkill` de `combat_controller_test`. Le garde-fou
  de compatibilité en rend un.
- ⚠️ **La façade `RunController.applyLifestealBuff` est sans appelant.** Conservée sur
  avertissement explicite ; P-41 doit la reprendre ou la supprimer avec son implémentation.
- ⚠️ **Deux vestiges non prévus par cette décision subsistent** (relevés le 2026-09-05,
  à traiter dans P-40 bloc 3) : `RunController.tickCooldown()` (`run_controller.dart:423`),
  sans appelant, dont le corps se réduit à `startTurn()` ; et la doc de
  `TurnPhaseManager.startPlayerTurn` (`turn_phase_manager.dart:43-44`), qui annonce encore des
  « cooldowns ». Un troisième — un **texte vu par le joueur**, dans
  `lib/tutorial/tutorial_data.dart`, promettant que gagner un combat réinitialisait les temps
  de recharge — a été **corrigé le 2026-09-05** dans les deux langues.
- ⚠️ **P-26 perd un tiers de son périmètre.** Restent le `GameDataRegistry` en `Map` O(1) et
  `MapNode` découplé de `Vector2`.
- ⚠️ Restent ouverts dans P-40 : le bloc 2 (trois bugs confirmés) et le bloc 3 (dix dérives
  documentaires) — `docs/ROADMAP.md`.
