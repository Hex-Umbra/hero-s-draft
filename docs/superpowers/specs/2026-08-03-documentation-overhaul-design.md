# Refonte de la Gestion Documentaire — Design

**Date** : 2026-08-03
**Statut** : Spec validée, prête pour plan d'implémentation
**Périmètre** : `.obsidian_vault/`, `docs/`, `CLAUDE.md`, `GEMINI.md`, et les deux skills rédacteurs de documentation (`memory-bank-sync`, `patch-notes-writer`)
**Hors périmètre** : tout fichier de `lib/`, `test/`, `assets/` — à l'exception du champ `version:` de `pubspec.yaml` (§5.5)

---

## 1. Problème

La documentation du projet compte 107 fichiers `.md` pour 23 294 lignes. Le memory bank Obsidian — présenté comme source de vérité — en pèse 5 811 lignes (~630 Ko) réparties sur 5 fichiers.

Le skill qui le maintient (`.agents/skills/business_analyst_product_manager.md`, 36 lignes) lui ordonne de « lire le vault » avant d'écrire. C'est physiquement impraticable à cette taille. L'agent en lit donc des fragments et écrit à partir de ce qu'il croit savoir. **C'est la cause mécanique unique de toutes les dérives constatées ci-dessous.**

### 1.1 Dérives factuelles constatées

Vérifiées contre le code le 2026-08-03 (`flutter test`, `dart analyze`, `find`, `wc -l`, lecture directe des fichiers).

| Affirmation documentée | Localisation | Réalité mesurée |
|:---|:---|:---|
| « ~11 600 lignes dans `lib/` (~79 fichiers) » | `progress.md` en-tête | 36 343 lignes, 169 fichiers |
| « 9 fichiers JSON » | `progress.md` en-tête | 10 |
| « 145+ tests » | `progress.md` en-tête | 212 |
| « 106 tests, couverture 23 % » | `progress.md` §1 Fiabilité | 212 — contredit l'en-tête du même fichier |
| « 211/211 » | `activeContext.md`, ADR-072, `progress.md` §7 | 212 |
| `map_screen.dart` 2 471 lignes, chantier critique | `activeContext.md` §3, `progress.md` §4 | 418 lignes — chantier clos |
| `game_screen.dart` 1 667 lignes à décomposer | `activeContext.md` §3 | 555 lignes — clos |
| « Paralléliser les I/O de `GameDataService` » = prochaine étape n°1 | `activeContext.md` §3 | Déjà fait : `Future.wait` en `lib/services/game_data_service.dart:52` |
| `RunPersistenceManager` (chargement/sauvegarde) | `progress.md:57` et `CLAUDE.md` | Fichier supprimé ; `systemPatterns.md:104` documente correctement sa suppression → contradiction interne au vault |
| « `// TODO: Audio Hook` disséminés » | `progress.md` §2 | 1 occurrence |
| « Menu de patch notes » marqué non implémenté | `progress.md` §3 | `lib/ui/screens/patch_notes_screen.dart` existe |

### 1.2 Chemins morts

Cassés par le commit `776eb7a` (« Organisation of docs »), jamais répercutés dans le vault :

- `progress.md` §6 pointe vers `docs/reward_and_luck_system.md`, `docs/système_de_passifs.md`, `docs/world_map_system.md`, `docs/stratégies_migrations.md` — les 4 sont dans `docs/archives/`.
- `progress.md` §6 cite `docs/lessons/flame_riverpod_sync.md` et `state_immutability.md` — ces fichiers n'existent pas (réels : `concept_mastery.md`, `flame_mastery.md`, `riverpod_mastery.md`).
- `progress.md` §6 annonce 22 fichiers dans `done/` (réel : 28) et 4 rapports Gemini (réel : 5).
- `progress.md` §5 cite `docs/analysis_reports/6_analyse_game_balance.md` — réel : `docs/possible_upgrades/_archives/6_analyse_game_balance.md`.

### 1.3 Incohérences structurelles

- **Quatre collisions d'ADR**, pas une. `decisionLog.md` contient 77 sections ADR pour seulement 73 numéros distincts (`ADR-001` à `ADR-073`, sans trou) :

  | N° | Entrée A | Entrée B |
  |:---|:---|:---|
  | `ADR-028` | Équilibrage Hybride & Réserve de Vagues (l. 1127) | Synchronisation du Bouton Fin de Tour (l. 2502) |
  | `ADR-067` | Clés Dupliquées de Notification, v0.2.8 (l. 241) | Équilibrage Économie & Miroir Magique, v0.2.9 (l. 2594) |
  | `ADR-068` | Forge de Fusion, v3.1.0 (l. 193) | Système d'Événements, v0.3.0 (l. 2626) |
  | `ADR-069` | Système de Sauvegarde, v3.2.0 (l. 151) | Clarté du Mana des Reliques, v3.0.1 (l. 2670) |

  Cause identifiée : le bloc de bas de fichier forme une séquence cohérente (`066`→`067`→`068`→`069` pour v0.2.7→v0.2.9→v0.3.0→v3.0.1) ; les entrées v3.x ajoutées en tête ont réutilisé `067`/`068`/`069` sans consulter le bas du fichier. `ADR-028` (l. 2502) est en outre mal classé, inséré entre `ADR-064` et `ADR-065`. Aucun index n'existe pour rendre ces collisions visibles.
- **Trois schémas de version simultanés** : `pubspec.yaml` = `0.1.0+1`, `patch_notes.json` = `0.4.7`, vault = `v3.5.1`. L'historique des releases mélange `v3.5.1`, `v0.3.0`, `v0.2.10` (placé au-dessus de `v0.2.2`), `v0.2.04`, `v0.2.00` — non monotone.
- **`activeContext.md` n'est pas un contexte actif** : 350 de ses 387 lignes sont un journal append-only remontant à v0.2.4 (juin). Quatre items consécutifs numérotés « 2. ». Duplique `progress.md` §7 et `decisionLog.md`.
- **`productContext.md`** : §3.10 intercalée entre §3.7 et §3.8 ; §9/§10/§11 sont des rapports de sprint historiques (v0.0.97 → v0.2.2), pas du contexte produit.

### 1.4 Obsolescence et roadmaps concurrentes

Le vault n'a pas bougé depuis le 2026-07-27 (commit `3f79a90`). Depuis : 8 brainstorms (25/07 → 31/07), le patch note v0.4.7, et `docs/roadmap_priorisee_31-07-2026.md` — **non suivi par git** et cité nulle part dans le vault.

Cinq roadmaps coexistent : `progress.md` §3 (backlog), `progress.md` §4 (phases « semaines 1-2/3-4… »), `backlog_and_roadmap_report_22072026.md` (auto-déclaré remplacé), `docs/possible_upgrades/upgrade_ideas.md`, et la roadmap priorisée du 31/07. Cette dernière avait déjà diagnostiqué 6 de ces problèmes dans sa §8 — et le vault ne l'a jamais intégrée.

### 1.5 Instructions agent contradictoires

- `CLAUDE.md` cite `run_persistence_manager.dart` (supprimé), ne mentionne ni `SaveService` ni `checkpoint_controller.dart` (le plus gros système livré en juillet), et ne dit rien des conventions de `docs/`.
- `GEMINI.md` est un doublon divergent : il impose un workflow d'agents obligatoire absent de `CLAUDE.md` et présente les dossiers `.agents/orchestrator|worker_m1|…` comme des sous-agents actifs, alors que `CLAUDE.md` les qualifie de répertoires vides. Aucune règle ne dit lequel fait autorité.
- `.obsidian_vault/business_analyst_product_manager_config.md` est une troisième copie verbatim du prompt du skill, plus un appel `define_subagent` qui n'existe pas dans Claude Code. Idem pour `flutter_game_designer_config.md`.

### 1.6 Le skill `patch_notes_writer` écrit à partir de sources mortes

`.agents/skills/patch_notes_writer.md` ordonne de lire cinq sources « avant d'écrire un mot ». Trois sont inexploitables :

| Source déclarée | État réel (vérifié le 2026-08-03) |
|:---|:---|
| `.gemini/antigravity/brain/<id>/implementation_plan.md` | `.gemini/` n'existe pas — vestige d'un workflow Antigravity/Gemini abandonné |
| `.gemini/antigravity/brain/<id>/walkthrough.md` | N'existe nulle part dans le dépôt |
| `task.md` (checklist des items `[x]`) | **Existe et est périmé** : checklist « Forge & Fusion » figée au commit `5cf0adb` (ère v3.1.0, 1er juillet) |
| `.obsidian_vault/_memory_bank/progress.md` + `activeContext.md` | Existe, mais c'est le vault dont §1.1 démontre la dérive |
| `git diff HEAD~1 --name-only` | Fonctionne, mais ne voit qu'un commit — inutilisable sur une branche de 13 commits comme `feat/save_run` |

Le cas `task.md` est le plus dangereux : ce n'est pas un chemin mort qui échouerait bruyamment, c'est un fichier présent, lisible et faux. Un agent suivant le skill à la lettre rédigerait des patch notes à partir d'une checklist de la Forge datée du 1er juillet.

Que cela ne se soit pas produit tient au fait que les rédactions récentes (v0.4.5 → v0.4.7) ont été pilotées manuellement depuis les vraies sources.

Le reste du skill (schéma JSON, catégories autorisées, règles de rédaction, garde-fous) est solide et nettement mieux écrit que celui du BA/PM : il est repris tel quel.

### 1.7 Ce qui manque au skill de memory bank actuel

| Garantie absente | Conséquence observée |
|:---|:---|
| Budget de taille | 630 Ko illisibles par l'agent censé les lire |
| Devoir de vérification | Métriques recopiées du récit, fausses d'un facteur 3 |
| Mandat de suppression / archivage | Append-only : rien n'a jamais été retiré |
| Règle de source unique | La règle 4 actuelle **prescrit** la duplication |
| Protocole de numérotation d'ADR | 4 collisions : ADR-028, 067, 068, 069 |
| Conscience de `docs/` hors vault | Specs, plans et brainstorms invisibles |
| Définition de « terminé » | Dérives jamais détectées |

---

## 2. Architecture cible

### 2.1 Le vault devient lisible d'un bloc

| Fichier | Actuel | Plafond cible | Contenu après refonte |
|:---|---:|---:|:---|
| `activeContext.md` | 387 l. | **120 l.** | Focus courant + 3 dernières livraisons max + prochaine étape (lien roadmap) |
| `progress.md` | 435 l. | **300 l.** | État du construit + métriques datées et vérifiées. Aucune roadmap. 10 dernières releases |
| `productContext.md` | 807 l. | **400 l.** | Règles métier du jeu tel qu'il est |
| `systemPatterns.md` | 1 478 l. | **400 l.** | Architecture et conventions actuelles |
| `decisionLog.md` | 2 704 l. | **250 l.** | Index d'ADR seul |
| **Total** | **5 811 l.** | **≈ 1 470 l.** | Chargeable intégralement par un agent |

**Éclatement des ADR** : un fichier par ADR dans `.obsidian_vault/_adr/ADR-0XX-slug.md`. `decisionLog.md` devient un index — tableau `N° / titre / date / statut / version / lien`. La traçabilité est intégralement conservée ; elle devient adressable au lieu d'être monolithique.

**Résolution des 4 collisions** — règle d'arbitrage, appliquée dans cet ordre :

1. **L'entrée qui a des références entrantes garde son numéro.** Seul `ADR-069` / Système de Sauvegarde est concerné : 8 références réparties sur 5 fichiers, dont `docs/ROADMAP.md`. Les renuméroter serait le plus coûteux et le plus risqué des choix.
2. **À défaut, l'entrée la plus ancienne garde son numéro** — c'est elle qui possédait le numéro en premier.
3. Les entrées renumérotées reçoivent `074`+ **par ordre croissant de ligne** dans le fichier source, et portent une note d'en-tête rappelant leur ancien numéro.

| Entrée renumérotée | Ancien | Nouveau | Motif |
|:---|:---:|:---:|:---|
| Forge de Fusion (v3.1.0), l. 193 | `068` | **`ADR-074`** | Aucune référence entrante ; l'entrée v0.3.0 est antérieure |
| Clés Dupliquées de Notification (v0.2.8), l. 241 | `067` | **`ADR-075`** | Aucune référence entrante ; l'entrée v0.2.9 est antérieure |
| Synchronisation du Bouton Fin de Tour, l. 2502 | `028` | **`ADR-076`** | Aucune référence entrante ; c'est l'entrée mal classée |
| Clarté du Mana des Reliques (v3.0.1), l. 2670 | `069` | **`ADR-077`** | Zéro référence entrante, face aux 8 du Système de Sauvegarde (règle 1) |

Résultat : 77 numéros distincts, `ADR-001` à `ADR-077`, sans trou ni doublon. `ADR-028` retrouve sa place par le tri de l'index.

**Archive** : `.obsidian_vault/_archive/2026-08-03-<nom>.md`, horodatée, jamais rechargée, jamais éditée.

### 2.2 Frontière vault / docs

| Question | Réponse unique |
|:---|:---|
| Ce qui **existe** (état, règles, décisions prises) | `.obsidian_vault/_memory_bank/` |
| Ce qui **reste à faire** (priorisé, estimé) | `docs/ROADMAP.md` |
| Ce qui est **conçu mais pas construit** | `docs/superpowers/specs/` + `docs/superpowers/plans/` |
| Ce qui est **exploré, pas encore tranché** | `docs/possible_upgrades/` |
| Ce que **voit le joueur** | `assets/data/patch_notes.json` |

`docs/roadmap_priorisee_31-07-2026.md` devient `docs/ROADMAP.md` — nom stable, sans date : une roadmap datée dans son nom se re-crée à chaque révision et reproduit le problème des cinq roadmaps concurrentes. `backlog_and_roadmap_report_22072026.md` est archivé.

### 2.3 Une seule autorité pour les instructions agent

- **`CLAUDE.md` fait autorité.** Corrigé (`RunPersistenceManager` retiré, `SaveService` et `checkpoint_controller.dart` ajoutés) et complété d'une section « Carte de la documentation » reprenant le tableau §2.2.
- **`GEMINI.md`** réduit à un pointeur vers `CLAUDE.md` plus les seules spécificités Gemini CLI.
- **`.obsidian_vault/business_analyst_product_manager_config.md` et `flutter_game_designer_config.md`** archivés.

---

## 3. Skill 1/2 — `memory-bank-sync` (documentation développeur)

**Emplacement** : `.claude/skills/memory-bank-sync/SKILL.md` — format natif de l'environnement, invocable via `/memory-bank-sync` et auto-déclenchable.
`.agents/skills/business_analyst_product_manager.md` est **supprimé**, pas conservé en doublon : les trois copies actuelles du même prompt sont précisément le symptôme à éliminer.

**Frontmatter** :

```yaml
---
name: memory-bank-sync
description: Use after any implementation, merge, or design decision lands in Hero's Draft — updates .obsidian_vault/_memory_bank/ and docs/ROADMAP.md. Verifies every metric against the code before writing, enforces per-file line caps, archives instead of appending, and keeps ADR numbering collision-free.
---
```

### 3.1 Garantie 1 — Vérifier avant d'écrire

> Aucun chiffre ne peut être écrit s'il ne provient pas d'une commande lancée dans la session en cours.

| Fait à documenter | Commande imposée |
|:---|:---|
| Nombre de tests | `flutter test` → lire le `+N` final |
| Analyse statique | `dart analyze` |
| Taille du code | `find lib -name "*.dart" \| wc -l` puis total de lignes |
| Fichiers de données | `ls assets/data/*.json \| wc -l` |
| Versions | `pubspec.yaml` + première entrée de `assets/data/patch_notes.json` |
| Ce qui a changé | `git log <dernière-synchro>..HEAD --oneline` |
| Taille d'un fichier cité comme chantier | `wc -l <fichier>` |

Chaque bloc de métriques porte `**Vérifié le YYYY-MM-DD**`.

### 3.2 Garantie 2 — Plafonds durs

`wc -l` sur les 5 fichiers en fin de passe, contre les plafonds du §2.1. Dépassement → **archiver**, jamais tronquer ni condenser. Les plafonds sont rappelés en en-tête de chaque fichier du vault.

### 3.3 Garantie 3 — Archiver, pas empiler

- `activeContext.md` : FIFO strict à 3 livraisons ; la 4ᵉ pousse la plus ancienne vers `_archive/`.
- `progress.md` §Releases : 10 dernières entrées ; le reste vers `_archive/`.
- Règle explicite : *une passe se termine avec autant ou moins de lignes qu'elle n'a commencé, sauf changement structurel du jeu.*

### 3.4 Garantie 4 — Source unique

Remplace la règle 4 actuelle, qui prescrit la duplication et est l'origine directe des contradictions internes.

| Fait | Vit uniquement dans | Ailleurs |
|:---|:---|:---|
| *Pourquoi* une décision a été prise | `_adr/ADR-0XX.md` | lien |
| *Ce qui est construit* | `progress.md` | lien |
| *Ce sur quoi on travaille* | `activeContext.md` | lien |
| *Ce qui reste à faire* | `docs/ROADMAP.md` | lien |
| *Règle de jeu* | `productContext.md` | lien |

> On lie, on ne recopie pas. Deux formulations du même fait sont deux occasions de diverger.

### 3.5 Garantie 5 — Protocole ADR

- Nouveau numéro = `max(index) + 1`, lu dans l'index, jamais deviné.
- Un fichier par ADR.
- Un ADR publié n'est jamais renuméroté ni réécrit : s'il est dépassé, on change son statut et on lie son successeur.
- Index trié, unicité des numéros vérifiée en fin de passe.

### 3.6 Garantie 6 — Périmètre élargi

Le skill connaît les cinq emplacements du §2.2 et porte un devoir explicite : **quand un chantier `P-xx` est livré, le cocher dans `docs/ROADMAP.md` dans la même passe.**

### 3.7 Garantie 7 — Ancre de synchronisation et auto-contrôle

En tête d'`activeContext.md` : `<!-- last-sync: YYYY-MM-DD | commit: <sha> -->`.
La passe suivante démarre par `git log <sha>..HEAD` : elle sait exactement ce qu'elle a manqué au lieu de relire l'intégralité du vault.

Checklist de fin de passe, à exécuter :

- [ ] Plafonds respectés (`wc -l`)
- [ ] Aucun chemin mort (chaque chemin cité testé avec `test -e`)
- [ ] Versions cohérentes entre `pubspec.yaml`, `patch_notes.json` et le vault — ou écart signalé explicitement
- [ ] Index ADR : numéros uniques et triés
- [ ] Aucune métrique sans date de vérification
- [ ] Ancre `last-sync` mise à jour

### 3.8 Garde-fous

Le skill **ne touche pas** à `assets/data/patch_notes.json` (domaine de `patch_notes_writer`), **ne touche pas** au code, **n'édite jamais** `_archive/`.

---

## 4. Skill 2/2 — `patch-notes-writer` (documentation joueur)

**Emplacement** : `.claude/skills/patch-notes-writer/SKILL.md`, invocable via `/patch-notes-writer`.
`.agents/skills/patch_notes_writer.md` est supprimé. `.agents/skills/` ne contient plus alors que `game_designer.md`.

**Frontmatter** :

```yaml
---
name: patch-notes-writer
description: Use after an implementation lands in Hero's Draft to write the player-facing patch note — prepends a new semver entry to assets/data/patch_notes.json and keeps pubspec.yaml in sync. Writes French player-facing prose only, never developer jargon, and never edits existing entries.
---
```

### 4.1 Sources réécrites sur ce qui existe réellement

Remplace intégralement le §1 de l'ancien skill (voir §1.6).

| Source | Rôle |
|:---|:---|
| `docs/superpowers/plans/<date>-<sujet>.md` | Ce qui était prévu, tâche par tâche |
| `docs/superpowers/specs/<date>-<sujet>-design.md` | L'intention et les arbitrages |
| `git log <base>..HEAD --oneline` et `git diff <base>..HEAD --name-only` | Ce qui a réellement été livré, sur toute la branche |
| `.obsidian_vault/_adr/ADR-0XX-*.md` | Le *pourquoi*, et les trade-offs à ne pas annoncer comme des gains |

**Règle de préséance** : en cas de divergence entre un plan et l'historique git, **git fait foi**. Un plan décrit une intention, un commit décrit un fait.

**Interdiction explicite** : ne jamais lire `task.md` à la racine — fichier périmé conservé pour l'historique (voir §5.5).

### 4.2 Propriété du numéro de version

Le skill qui décide du numéro de version l'écrit **aux deux endroits** :

1. `assets/data/patch_notes.json` — nouvelle entrée en tête du tableau.
2. `pubspec.yaml` — champ `version:`, aligné sur `<version>+<build>`.

Le garde-fou « ne toucher à aucun autre fichier » de l'ancien skill est assoupli **à ces deux fichiers exactement**, et à aucun autre.

Cette règle ferme définitivement le chantier **P-01** de la roadmap (écart `0.1.0+1` vs `0.4.7`) au lieu de le corriger une seule fois, et supprime la catégorie de bug à la source. Elle est aussi un prérequis strict de **P-04** (le job CI `verify-version` compare le tag git à `pubspec.yaml`).

### 4.3 Ce qui est repris tel quel

Le schéma JSON, les 5 catégories autorisées et leurs emoji, les règles de rédaction (§3.1 à §3.5 de l'ancien skill), le workflow en 6 étapes et les garde-fous (« ne jamais supprimer », « ne jamais modifier une entrée existante », « ne jamais halluciner ») sont conservés à l'identique. Seules les sources (§4.1) et la propriété de la version (§4.2) changent.

### 4.4 Articulation entre les deux skills

| | `patch-notes-writer` | `memory-bank-sync` |
|:---|:---|:---|
| Écrit dans | `assets/data/patch_notes.json`, `pubspec.yaml` | `_memory_bank/`, `_adr/`, `docs/ROADMAP.md` |
| Pour qui | Le joueur | Le développeur et les agents |
| Registre | Français joueur, zéro jargon | Technique, traçable |

Dépendance unique et à sens unique : **`memory-bank-sync` enregistre la version publiée par `patch-notes-writer`, il ne la décide pas.** L'absence de cette règle est ce qui a produit les trois schémas de version concurrents du §1.3.

---

## 5. Ordre d'exécution de la remise à plat

Principe directeur : **on déplace, on ne résume pas.** Toute ligne retirée d'un fichier vivant se retrouve verbatim dans `_archive/`.

### 5.1 Filet de sécurité — avant toute écriture

1. Branche dédiée `docs/memory-bank-overhaul`.
2. **Premier commit** : `docs/roadmap_priorisee_31-07-2026.md`, aujourd'hui non suivi par git. Seul fichier du dépôt qu'un `git clean` détruirait, et meilleur document de pilotage du projet.
3. Copie intégrale des 5 fichiers du vault vers `_archive/2026-08-03-<nom>.md`, committée telle quelle.

À partir de ce commit, l'information est doublement protégée (git + archive) et toutes les étapes suivantes sont réversibles.

### 5.2 Les deux skills d'abord

1. Écrire `.claude/skills/memory-bank-sync/SKILL.md` (§3), supprimer `.agents/skills/business_analyst_product_manager.md`, archiver les deux `.obsidian_vault/*_config.md`.
2. Écrire `.claude/skills/patch-notes-writer/SKILL.md` (§4), supprimer `.agents/skills/patch_notes_writer.md`.

L'ordre est intentionnel : la remise à plat devient le premier cas d'usage réel de `memory-bank-sync`, exécutée sous ses propres règles. Une règle impraticable sur 5 811 lignes se révèle immédiatement.

`patch-notes-writer` n'a pas de patch note à écrire dans ce chantier — aucune de ses étapes n'est visible du joueur. Il est migré ici parce qu'il rédige l'autre moitié de la documentation à partir des mêmes faits, et que laisser ses sources mortes en place (§1.6) rendrait la prochaine rédaction aussi peu fiable qu'aujourd'hui.

### 5.3 Éclatement du `decisionLog` — étape mécanique

Découpe par script sur les titres `^## .* ADR-(\d+)` vers `_adr/ADR-0XX-slug.md`, puis génération de l'index trié.

Contrôles automatiques :

- Nombre de fichiers produits = **77** = nombre de titres ADR dans la source.
- Somme des lignes produites ≈ 2 704 (aux séparateurs près).
- Numéros uniques dans l'index.

Seule intervention manuelle : renumérotation des **4 doublons** en `ADR-074` à `ADR-077` selon le tableau du §2.1, chacun avec une note d'en-tête rappelant son ancien numéro.

### 5.4 Réécriture des 4 fichiers restants

L'ordre conditionne l'absence de perte d'information :

1. **`progress.md`** — il porte les métriques, à re-mesurer par commande selon la garantie 1 (§3.1). Il redevient la base factuelle. Les dérives du §1.1 et les chemins morts du §1.2 sont corrigés par construction à cette étape.
2. **`productContext.md`** puis **`systemPatterns.md`** — purge des sections historiques datées vers l'archive, correction des références, renumérotation des §3.x de `productContext.md`.
3. **`activeContext.md` en dernier** — il ne peut descendre à 3 livraisons que si `progress.md` et les ADR ont déjà absorbé le reste. Le réduire en premier perdrait de l'information sans nouveau domicile.

### 5.5 Périphérie

- `git mv docs/roadmap_priorisee_31-07-2026.md docs/ROADMAP.md` (préserve l'historique).
- `backlog_and_roadmap_report_22072026.md` → `docs/archives/`.
- `task.md` (racine) → `docs/archives/2026-07-01-task-forge-fusion.md`. Il n'est plus une source de personne depuis §4.1 et sa présence à la racine invite à le relire comme s'il était courant.
- **Resync unique de `pubspec.yaml`** : `0.1.0+1` → `0.4.7+1`, aligné sur `patch_notes.json`. Fermeture du chantier **P-01**, cochée dans `docs/ROADMAP.md` — premier exercice réel de la garantie 6 (§3.6). Au-delà de cette fois, la synchronisation est portée par `patch-notes-writer` (§4.2).
- `CLAUDE.md` corrigé et complété (§2.3), avec les **deux** skills référencés à leur nouvel emplacement.
- `GEMINI.md` réduit à un pointeur.

### 5.6 Vérification finale

La checklist du §3.7 exécutée sur le résultat, plus `dart analyze` et `flutter test`.

Aucune étape de cette refonte ne touche à `lib/`, `test/` ni aux données de jeu : les deux commandes doivent rendre exactement `0 issue` et le même nombre de tests qu'avant. C'est le contrôle qu'aucun fichier source n'a été atteint par erreur.

Le seul fichier non documentaire modifié est `pubspec.yaml` (champ `version:` uniquement, §5.5). Contrôle dédié : `flutter pub get` doit rester silencieux et `git diff pubspec.yaml` ne doit montrer qu'une seule ligne changée.

---

## 6. Hors périmètre

| Écart connu | Raison de ne pas le traiter ici |
|:---|:---|
| Re-priorisation de la roadmap | Datée du 31/07 et solide. On la déplace, on ne la rejuge pas. |
| Les 8 brainstorms, specs et plans de `docs/` | Bien rangés et à jour, non concernés. |
| Tout fichier de `lib/`, `test/`, `assets/` | Strictement hors périmètre. `pubspec.yaml` est la seule exception, champ `version:` uniquement (§5.5). |
| `.agents/skills/game_designer.md` | Troisième skill du dossier, non concerné par la documentation. Sa migration éventuelle est une décision distincte ; `.agents/skills/` subsiste donc pour lui seul. |
| Les 10 répertoires vides `.agents/orchestrator|worker_m1|…` | Artefacts d'un workflow multi-agents passé. Les supprimer est sans risque mais sans rapport avec la documentation. |

---

## 7. Critères de réussite

1. Le vault total tient sous **1 500 lignes** et est chargeable intégralement par un agent.
2. Chaque métrique du vault porte une date de vérification et correspond à une commande reproductible.
3. Aucun chemin cité dans le vault n'est mort (`test -e` sur chacun).
4. Un seul document répond à « que reste-t-il à faire ? ».
5. Les numéros d'ADR sont uniques et l'index est trié.
6. Les deux skills vivent dans `.claude/skills/`, sont invocables par leur nom, et **chaque source qu'ils déclarent lire existe** (`test -e` sur chacune).
7. `pubspec.yaml`, `patch_notes.json` et le vault annoncent la même version, et un propriétaire unique est désigné pour l'y maintenir.
8. `flutter test` et `dart analyze` rendent **exactement le même résultat qu'avant la refonte** (mesuré à 212 tests et 0 issue le 2026-08-03) — aucune étape ne touchant au code, tout écart signale un fichier source atteint par erreur.
9. Aucune information n'a disparu : tout ce qui a été retiré est retrouvable verbatim dans `_archive/` ou dans l'historique git.
