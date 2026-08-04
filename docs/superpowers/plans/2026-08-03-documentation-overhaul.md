# Refonte de la Gestion Documentaire — Plan d'Implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ramener le memory bank de 5 811 à moins de 1 500 lignes sans perte d'information, et remplacer les deux skills rédacteurs de documentation par des skills Claude Code dont chaque source déclarée existe réellement.

**Architecture:** Le `decisionLog` monolithique est éclaté en 77 fichiers ADR plus un index ; les 4 autres fichiers du vault sont réécrits après archivage verbatim de leur version actuelle ; la roadmap devient `docs/ROADMAP.md`, source unique du « reste à faire » ; deux skills (`memory-bank-sync`, `patch-notes-writer`) portent désormais des règles vérifiables qui empêchent la dérive de revenir.

**Tech Stack:** Markdown, Python 3 (scripts de découpe et de contrôle, jetables), git, Flutter/Dart (commandes de vérification uniquement).

**Spec:** `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`

## Global Constraints

- **Langue** : tout le contenu documentaire produit est en **français**. Les frontmatter `description:` des skills sont en anglais (ils pilotent le déclenchement automatique).
- **Branche** : tout le travail se fait sur `docs/memory-bank-overhaul`. Rien n'est commité sur `main`.
- **Aucun fichier de `lib/`, `test/` ou `assets/` n'est modifié.** Seule exception autorisée sur tout le plan : le champ `version:` de `pubspec.yaml` (Tâche 10).
- **On déplace, on ne résume pas** : toute ligne retirée d'un fichier vivant doit exister verbatim dans `.obsidian_vault/_archive/`.
- **Plafonds de lignes** — `activeContext.md` ≤ 120, `progress.md` ≤ 300, `productContext.md` ≤ 120, `systemPatterns.md` ≤ 120, `decisionLog.md` ≤ 250. Les trois derniers sont des **index** ; leur contenu vit en fiches adressables sous `_adr/`, `_rules/` et `_patterns/`.
- **Référence temporelle** : les fichiers produits datent du **2026-08-03**.
- **Mesures de référence prises le 2026-08-03** (à re-mesurer, pas à recopier) : 212 tests au vert, `dart analyze` à 0 issue, 169 fichiers Dart dans `lib/` pour 36 343 lignes, 10 fichiers JSON dans `assets/data/`.
- **Répertoire de travail des scripts jetables** : `C:\Users\Gpdac\AppData\Local\Temp\claude\C--Users-Gpdac-Documents-GameDev-and-Godot-Roguelike-Card-Game-roguelike-card-game\f035a3db-f1c3-43d5-b643-44499cdeff9a\scratchpad`. Aucun script ne doit être commité dans le dépôt.
- **Encodage** : tous les fichiers écrits en UTF-8 sans BOM, fins de ligne LF (git convertira). La console Windows est en cp1252 : **préfixer tout appel Python de `PYTHONIOENCODING=utf-8`**, sans quoi un simple `print` contenant un emoji lève `UnicodeEncodeError` alors que le traitement lui-même est correct. Les lectures et écritures de fichiers passent toujours par `io.open(..., encoding="utf-8")`.

> [!NOTE]
> **Le script de la Tâche 4 a été validé à blanc le 2026-08-03** contre `decisionLog.md` : 77 titres ADR détectés, et les 4 clés de renumérotation correspondent exactement aux titres réels. L'assertion `len(heads) == 77` est donc un garde-fou de régression, pas une hypothèse.

---

## Structure des fichiers

**Créés :**

| Chemin | Responsabilité |
|:---|:---|
| `.claude/skills/memory-bank-sync/SKILL.md` | Règles de maintenance du vault et de `docs/ROADMAP.md` |
| `.claude/skills/patch-notes-writer/SKILL.md` | Règles de rédaction du patch note joueur et de la version |
| `.obsidian_vault/_adr/ADR-0XX-<slug>.md` (×77) | Un ADR par fichier, corps intégral |
| `.obsidian_vault/_archive/2026-08-03-<nom>.md` (×5) | Copie verbatim des 5 fichiers du vault avant refonte |
| `.obsidian_vault/_archive/2026-08-03-<nom>-historique.md` | Sections historiques retirées des fichiers réécrits |
| `docs/ROADMAP.md` | Source unique du « reste à faire » (issu de `roadmap_priorisee_31-07-2026.md`) |

**Modifiés :**

| Chemin | Nature |
|:---|:---|
| `.obsidian_vault/_memory_bank/decisionLog.md` | Remplacé par un index d'ADR |
| `.obsidian_vault/_memory_bank/progress.md` | Réécrit, métriques re-mesurées |
| `.obsidian_vault/_memory_bank/productContext.md` | Purgé des sections historiques |
| `.obsidian_vault/_memory_bank/systemPatterns.md` | Purgé des sections datées |
| `.obsidian_vault/_memory_bank/activeContext.md` | Réduit à une fenêtre glissante |
| `CLAUDE.md` | Correction + section « Carte de la documentation » |
| `GEMINI.md` | Réduit à un pointeur |
| `pubspec.yaml` | Champ `version:` uniquement |

**Supprimés / déplacés :**

| Chemin | Destination |
|:---|:---|
| `.agents/skills/business_analyst_product_manager.md` | Supprimé (remplacé par le skill) |
| `.agents/skills/patch_notes_writer.md` | Supprimé (remplacé par le skill) |
| `.obsidian_vault/business_analyst_product_manager_config.md` | `.obsidian_vault/_archive/` |
| `.obsidian_vault/flutter_game_designer_config.md` | `.obsidian_vault/_archive/` |
| `task.md` (racine) | `docs/archives/2026-07-01-task-forge-fusion.md` |
| `docs/backlog_and_roadmap_report_22072026.md` | `docs/archives/` |
| `docs/roadmap_priorisee_31-07-2026.md` | `docs/ROADMAP.md` |

---

## Tâche 1 : Branche et filet de sécurité

**Files:**
- Create: `.obsidian_vault/_archive/2026-08-03-{activeContext,progress,productContext,systemPatterns,decisionLog}.md`
- Commit: `docs/roadmap_priorisee_31-07-2026.md` (actuellement non suivi par git)

**Interfaces:**
- Consumes: rien.
- Produces: la branche `docs/memory-bank-overhaul` et 5 fichiers d'archive verbatim sur lesquels toutes les tâches suivantes s'appuient pour garantir l'absence de perte.

- [ ] **Étape 1 : Créer la branche depuis `main` à jour**

```bash
git checkout main && git pull --ff-only && git checkout -b docs/memory-bank-overhaul
```

- [ ] **Étape 2 : Committer la roadmap non suivie, telle quelle**

Elle suit le checkout et n'a donc pas bougé. Aucune modification de son contenu à ce stade.

```bash
git add docs/roadmap_priorisee_31-07-2026.md
git commit -m "docs: track the 31/07 prioritised roadmap before reorganising docs"
```

- [ ] **Étape 3 : Archiver verbatim les 5 fichiers du vault**

```bash
mkdir -p .obsidian_vault/_archive
for f in activeContext progress productContext systemPatterns decisionLog; do
  cp ".obsidian_vault/_memory_bank/$f.md" ".obsidian_vault/_archive/2026-08-03-$f.md"
done
```

- [ ] **Étape 4 : Vérifier que l'archive est bit-à-bit identique**

```bash
for f in activeContext progress productContext systemPatterns decisionLog; do
  diff -q ".obsidian_vault/_memory_bank/$f.md" ".obsidian_vault/_archive/2026-08-03-$f.md" || echo "ÉCART: $f"
done
wc -l .obsidian_vault/_archive/2026-08-03-*.md
```

Attendu : aucune ligne « ÉCART », et un total de **5 811** lignes.

- [ ] **Étape 5 : Écrire l'avertissement de l'archive**

Créer `.obsidian_vault/_archive/README.md` :

```markdown
# Archive du memory bank

Contenu figé, conservé pour la traçabilité. **Ne jamais éditer, ne jamais recharger comme source de vérité.**

Les fichiers `2026-08-03-*.md` sont la copie verbatim des 5 fichiers du memory bank juste avant la refonte documentaire du 3 août 2026 (voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md`).

Pour retrouver une information retirée d'un fichier vivant : chercher ici d'abord, puis dans `git log`.
```

- [ ] **Étape 6 : Committer**

```bash
git add .obsidian_vault/_archive/
git commit -m "docs: archive the memory bank verbatim before the overhaul"
```

---

## Tâche 2 : Skill `memory-bank-sync`

**Files:**
- Create: `.claude/skills/memory-bank-sync/SKILL.md`
- Delete: `.agents/skills/business_analyst_product_manager.md`
- Move: `.obsidian_vault/business_analyst_product_manager_config.md`, `.obsidian_vault/flutter_game_designer_config.md` → `.obsidian_vault/_archive/`

**Interfaces:**
- Consumes: l'archive de la Tâche 1 (le skill y renvoie).
- Produces: le fichier de règles que les Tâches 4 à 11 appliquent, et que la Tâche 12 utilise comme checklist finale.

- [ ] **Étape 1 : Créer le fichier du skill**

Écrire `.claude/skills/memory-bank-sync/SKILL.md` avec exactement ce contenu :

````markdown
---
name: memory-bank-sync
description: Use after any implementation, merge, or design decision lands in Hero's Draft — updates .obsidian_vault/_memory_bank/ and docs/ROADMAP.md. Verifies every metric against the code before writing, enforces per-file line caps, archives instead of appending, and keeps ADR numbering collision-free.
---

# Synchronisation du memory bank

Tu maintiens la documentation développeur de **Hero's Draft**. Tu traduis ce qui a été livré en connaissance produit structurée, et tu empêches la dérive entre la documentation et le code.

Écris en **français**. Le frontmatter `description` reste en anglais.

## Ce que tu écris

| Fichier | Plafond | Contenu |
|:---|---:|:---|
| `.obsidian_vault/_memory_bank/activeContext.md` | 120 l. | Focus courant, 3 dernières livraisons, prochaine étape |
| `.obsidian_vault/_memory_bank/progress.md` | 300 l. | État du construit, métriques datées, 10 dernières releases |
| `.obsidian_vault/_memory_bank/productContext.md` | 400 l. | Règles métier du jeu tel qu'il est |
| `.obsidian_vault/_memory_bank/systemPatterns.md` | 400 l. | Architecture et conventions actuelles |
| `.obsidian_vault/_memory_bank/decisionLog.md` | 250 l. | Index des ADR (tableau seul) |
| `.obsidian_vault/_adr/ADR-0XX-<slug>.md` | — | Un fichier par décision |
| `docs/ROADMAP.md` | — | Le reste à faire, priorisé |

## Ce que tu ne touches jamais

- `assets/data/patch_notes.json` et `pubspec.yaml` — domaine de `patch-notes-writer`.
- Tout fichier de `lib/`, `test/`, `assets/`.
- `.obsidian_vault/_archive/` — en lecture seule, définitivement.

## Garantie 1 — Vérifier avant d'écrire

> **Aucun chiffre ne peut être écrit s'il ne provient pas d'une commande lancée dans la session en cours.**

| Fait | Commande |
|:---|:---|
| Nombre de tests | `flutter test` → lire le `+N` final |
| Analyse statique | `dart analyze` |
| Fichiers Dart | `find lib -name "*.dart" \| wc -l` |
| Lignes de code | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | `ls assets/data/*.json \| wc -l` |
| Versions | lire `pubspec.yaml` et la 1ʳᵉ entrée de `assets/data/patch_notes.json` |
| Ce qui a changé | `git log <last-sync>..HEAD --oneline` |
| Taille d'un fichier cité comme chantier | `wc -l <fichier>` |

Tout bloc de métriques porte `**Vérifié le YYYY-MM-DD**`.

Ne jamais reprendre un chiffre depuis un document — même depuis ce vault. Les chiffres se re-mesurent.

## Garantie 2 — Plafonds durs

En fin de passe :

```bash
wc -l .obsidian_vault/_memory_bank/*.md
```

Un dépassement se corrige en **archivant**, jamais en tronquant ni en condensant.

## Garantie 3 — Archiver, pas empiler

- `activeContext.md` : **FIFO strict à 3 livraisons**. La 4ᵉ pousse la plus ancienne vers `.obsidian_vault/_archive/`.
- `progress.md`, historique des releases : **10 entrées**. Le reste vers l'archive.
- Règle générale : *une passe se termine avec autant ou moins de lignes qu'elle n'a commencé, sauf changement structurel du jeu.*

## Garantie 4 — Source unique

| Fait | Vit uniquement dans |
|:---|:---|
| *Pourquoi* une décision a été prise | `_adr/ADR-0XX.md` |
| *Ce qui est construit* | `progress.md` |
| *Ce sur quoi on travaille* | `activeContext.md` |
| *Ce qui reste à faire* | `docs/ROADMAP.md` |
| *Règle de jeu* | `productContext.md` |

**On lie, on ne recopie pas.** Deux formulations du même fait sont deux occasions de diverger.

## Garantie 5 — Protocole ADR

1. Le nouveau numéro est `max(index) + 1`, **lu dans l'index**, jamais deviné.
2. Un fichier par ADR, nommé `ADR-0XX-<slug-kebab>.md`.
3. Structure imposée : `### Statut`, `### Contexte`, `### Décision`, `### Preuves dans le code`, `### Conséquences`.
4. Un ADR publié n'est **jamais** renuméroté ni réécrit. S'il est dépassé, changer son `### Statut` et lier son successeur.
5. Ajouter la ligne correspondante dans l'index `decisionLog.md`, qui reste trié par numéro décroissant.

## Garantie 6 — Périmètre

Tu connais ces cinq emplacements et tu sais lequel répond à quelle question :

| Question | Emplacement |
|:---|:---|
| Ce qui existe | `.obsidian_vault/_memory_bank/` |
| Ce qui reste à faire | `docs/ROADMAP.md` |
| Ce qui est conçu mais pas construit | `docs/superpowers/specs/` et `plans/` |
| Ce qui est exploré, pas tranché | `docs/possible_upgrades/` |
| Ce que voit le joueur | `assets/data/patch_notes.json` |

**Devoir explicite** : quand un chantier `P-xx` est livré, le cocher dans `docs/ROADMAP.md` **dans la même passe**.

## Garantie 7 — Ancre de synchronisation

`activeContext.md` commence par :

```
<!-- last-sync: YYYY-MM-DD | commit: <sha> -->
```

**Commence toujours ta passe par** `git log <sha>..HEAD --oneline` pour savoir exactement ce qui a changé depuis la dernière synchronisation. Ne relis pas le vault entier pour le deviner.

Termine toujours ta passe en mettant l'ancre à jour avec le `sha` de `HEAD`.

## Checklist de fin de passe

À **exécuter**, pas à cocher de mémoire :

- [ ] `wc -l .obsidian_vault/_memory_bank/*.md` → tous sous leur plafond
- [ ] Chaque chemin cité existe : extraire les chemins et les tester avec `test -e`
- [ ] `pubspec.yaml`, `patch_notes.json` et le vault annoncent la même version — sinon le signaler explicitement
- [ ] Index ADR : numéros uniques et triés
- [ ] Aucune métrique sans `**Vérifié le ...**`
- [ ] Ancre `last-sync` à jour
- [ ] Chantiers livrés cochés dans `docs/ROADMAP.md`

## Style

Markdown structuré et sobre. Utiliser les panneaux `> [!IMPORTANT]` et `> [!NOTE]` pour les invariants de gameplay et les patterns d'architecture — pas pour du commentaire ordinaire.
````

- [ ] **Étape 2 : Supprimer l'ancien skill et archiver les configs**

```bash
git rm .agents/skills/business_analyst_product_manager.md
git mv .obsidian_vault/business_analyst_product_manager_config.md .obsidian_vault/_archive/
git mv .obsidian_vault/flutter_game_designer_config.md .obsidian_vault/_archive/
```

- [ ] **Étape 3 : Vérifier que le skill est bien formé et que ses chemins existent**

```bash
head -5 .claude/skills/memory-bank-sync/SKILL.md
grep -oE '`[^`]*\.(md|json|yaml|dart)`|`[^`]*/`' .claude/skills/memory-bank-sync/SKILL.md \
  | tr -d '`' | grep -v '<' | sort -u \
  | while read p; do [ -e "$p" ] || echo "CHEMIN ABSENT: $p"; done
```

Attendu : le frontmatter affiche `name: memory-bank-sync`. Les seuls chemins signalés absents doivent être `.obsidian_vault/_adr/` et `docs/ROADMAP.md`, créés respectivement aux Tâches 4 et 10. Tout autre chemin absent est un défaut à corriger immédiatement.

- [ ] **Étape 4 : Committer**

```bash
git add .claude/skills/memory-bank-sync/SKILL.md
git commit -m "docs: add memory-bank-sync skill, retire the BA/PM prompt and its duplicate configs"
```

---

## Tâche 3 : Skill `patch-notes-writer`

**Files:**
- Create: `.claude/skills/patch-notes-writer/SKILL.md`
- Delete: `.agents/skills/patch_notes_writer.md`

**Interfaces:**
- Consumes: rien de ce plan.
- Produces: la règle de propriété de la version appliquée par la Tâche 10 (resync de `pubspec.yaml`) et référencée par `CLAUDE.md` en Tâche 11.

- [ ] **Étape 1 : Créer le fichier du skill**

Écrire `.claude/skills/patch-notes-writer/SKILL.md` avec exactement ce contenu :

````markdown
---
name: patch-notes-writer
description: Use after an implementation lands in Hero's Draft to write the player-facing patch note — prepends a new semver entry to assets/data/patch_notes.json and keeps pubspec.yaml in sync. Writes French player-facing prose only, never developer jargon, and never edits existing entries.
---

# Rédaction des patch notes

Tu es le chroniqueur de **Hero's Draft**. Tu écris ce que le joueur lit dans le jeu.

Tu es invoqué en fin de phase d'implémentation, une fois `dart analyze` propre.

## Tes deux seuls fichiers

1. `assets/data/patch_notes.json` — la nouvelle entrée de version.
2. `pubspec.yaml` — le champ `version:`, aligné sur elle.

**Ne touche à aucun autre fichier.**

## 1. Sources

Lis ceci avant d'écrire un mot :

| Source | Ce que tu y trouves |
|:---|:---|
| `docs/superpowers/plans/<date>-<sujet>.md` | Ce qui était prévu, tâche par tâche |
| `docs/superpowers/specs/<date>-<sujet>-design.md` | L'intention et les arbitrages |
| `git log <base>..HEAD --oneline` et `git diff <base>..HEAD --name-only` | Ce qui a **réellement** été livré |
| `.obsidian_vault/_adr/ADR-0XX-*.md` | Le *pourquoi*, et les trade-offs à ne pas vendre comme des gains |

`<base>` est le point de départ de la branche ou le commit du dernier patch note — **jamais `HEAD~1`**, qui ne verrait qu'un commit sur une branche qui en compte souvent plus de dix.

> **Règle de préséance : en cas de divergence entre un plan et l'historique git, git fait foi.** Un plan décrit une intention, un commit décrit un fait.

**Ne lis jamais `task.md` à la racine** : fichier périmé conservé pour l'historique.

## 2. Schéma JSON

`assets/data/patch_notes.json` est un tableau ordonné du plus récent au plus ancien.

```json
{
  "version": "X.Y.Z",
  "date": "YYYY-MM-DD",
  "title": "Titre court et évocateur, en français",
  "sections": [
    {
      "category": "Nom de catégorie en français",
      "emoji": "un seul emoji",
      "entries": [
        "Une phrase complète par changement, en français."
      ]
    }
  ]
}
```

Catégories autorisées — libellés exacts, l'UI les affiche tels quels :

| `category` | `emoji` | Quand |
|:---|:---:|:---|
| `Nouvelles Fonctionnalités` | ✨ | Nouveaux écrans, mécaniques, systèmes |
| `Améliorations` | ⚡ | Améliorations de l'existant (UX, performance) |
| `Équilibrage` | ⚖️ | Stats, coûts, probabilités |
| `Corrections` | 🐛 | Bugs, crashes, défauts d'affichage |
| `Technique` | 🔧 | Refactors, architecture, dépendances |

N'inclus que les catégories ayant au moins une entrée. Ordre imposé : Nouvelles Fonctionnalités, Améliorations, Équilibrage, Corrections, Technique.

## 3. Règles de rédaction

**Version** — semver `MAJOR.MINOR.PATCH`. `MINOR` pour une livraison de fonctionnalité, `PATCH` pour des correctifs ou du polish. Ne jamais réutiliser ni écraser un numéro existant.

**Titre** — 3 à 6 mots, évocateur, en français. Ne répète pas le numéro de version. Exemples : « La Grande Refonte », « Le Défi S'Intensifie ».

**Entrées** — une phrase complète par entrée, en français, du point de vue du joueur. Aucun jargon technique (`StateNotifier`, `Riverpod`, `rootBundle`…). Sois précis : « Le sort "Boule de feu" coûte désormais 2 mana au lieu de 3 » plutôt que « Coût réduit ». Maximum 8 entrées par catégorie.

**Date** — la date réelle du jour, au format `YYYY-MM-DD`.

## 4. Propriété du numéro de version

Tu décides du numéro de version, donc **tu l'écris aux deux endroits** :

1. `assets/data/patch_notes.json` — nouvelle entrée en tête du tableau.
2. `pubspec.yaml` — champ `version: <version>+<build>`, en incrémentant le build.

Exemple : entrée `0.4.8` → `version: 0.4.8+1` dans `pubspec.yaml`.

C'est la seule chose qui empêche les deux fichiers de diverger, et le job CI `verify-version` compare le tag git à `pubspec.yaml`.

## 5. Déroulé

1. Lire les sources du §1 et déterminer `<base>`.
2. Lire la version courante en tête de `patch_notes.json`, calculer la suivante.
3. Rédiger les entrées, les regrouper par catégorie, plafonner à 8.
4. Insérer le nouvel objet en position `[0]`. Ne toucher à aucun objet existant.
5. Mettre `pubspec.yaml` à jour.
6. Vérifier : `python -c "import json;json.load(open('assets/data/patch_notes.json',encoding='utf-8'))"` puis `flutter pub get`.
7. Rapporter : version écrite, nombre d'entrées par catégorie, incertitudes éventuelles.

## 6. Garde-fous

- **Ne supprime jamais** une entrée existante.
- **Ne modifie jamais** une entrée existante, pas même une faute de frappe.
- **N'invente jamais** une fonctionnalité non confirmée par les sources.
- Si un item prévu n'a pas été livré, **ne le mentionne pas**.
- Dans le doute sur une livraison, **omets-la** et signale l'incertitude dans ton rapport.
- Le JSON doit rester valide à tout instant : pas de virgule finale, pas de commentaire.
````

- [ ] **Étape 2 : Supprimer l'ancien skill**

```bash
git rm .agents/skills/patch_notes_writer.md
ls .agents/skills/
```

Attendu : `game_designer.md` seul subsiste.

- [ ] **Étape 3 : Vérifier que chaque source déclarée existe**

```bash
for p in docs/superpowers/plans docs/superpowers/specs assets/data/patch_notes.json pubspec.yaml; do
  [ -e "$p" ] && echo "OK  $p" || echo "ABSENT $p"
done
grep -c "task.md" .claude/skills/patch-notes-writer/SKILL.md
```

Attendu : quatre lignes `OK`, et exactement **1** occurrence de `task.md` — celle de l'interdiction.

- [ ] **Étape 4 : Committer**

```bash
git add .claude/skills/patch-notes-writer/SKILL.md
git commit -m "docs: add patch-notes-writer skill with live sources and version ownership"
```

---

## Tâche 4 : Éclatement du `decisionLog` en 77 fichiers ADR

**Files:**
- Create: `.obsidian_vault/_adr/ADR-001-*.md` … `ADR-077-*.md`
- Read-only source: `.obsidian_vault/_archive/2026-08-03-decisionLog.md`

**Interfaces:**
- Consumes: l'archive verbatim produite en Tâche 1.
- Produces: 77 fichiers ADR et `scratchpad/adr_manifest.tsv` (colonnes : `numéro`, `ancien_numéro`, `slug`, `titre`, `lignes`), consommé par la Tâche 5 pour bâtir l'index.

- [ ] **Étape 1 : Écrire le script de découpe**

Créer `<scratchpad>/split_adr.py` :

```python
import io, os, re, unicodedata

SRC = ".obsidian_vault/_archive/2026-08-03-decisionLog.md"
OUT = ".obsidian_vault/_adr"

# Renumérotation des 4 collisions. Clé = ligne de titre exacte du doublon à renuméroter.
RENUMBER = {
    "## \U0001F6E0\uFE0F ADR-068 : Introduction de la Forge de Fusion Procédurale et Forge Pilotée par les Données (v3.1.0)": "074",
    "## \U0001F6E0\uFE0F ADR-067 : Résolution Robuste des Clés Dupliquées dans l'Overlay de Notification (v0.2.8)": "075",
    "## \U0001F9ED ADR-028 : Synchronisation Synchrone du Bouton Fin de Tour": "076",
    "## \u26A1 ADR-069 : Clarté Visuelle du Mana des Reliques en Combat (v3.0.1)": "077",
}

def slug(title):
    t = re.sub(r"^##\s*\S*\s*ADR-\d+\s*:\s*", "", title).strip()
    t = re.sub(r"\(.*?\)", "", t)
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode()
    t = re.sub(r"[^a-zA-Z0-9]+", "-", t).strip("-").lower()
    return t[:50].rstrip("-")

lines = io.open(SRC, encoding="utf-8").read().split("\n")
heads = [i for i, l in enumerate(lines) if re.match(r"^##\s.*ADR-\d+", l)]
assert len(heads) == 77, "attendu 77 titres ADR, trouve %d" % len(heads)

os.makedirs(OUT, exist_ok=True)
manifest = []
for k, start in enumerate(heads):
    end = heads[k + 1] if k + 1 < len(heads) else len(lines)
    head = lines[start]
    old = re.search(r"ADR-(\d+)", head).group(1)
    new = RENUMBER.get(head, old)
    body = lines[start:end]
    # Retire les separateurs '---' de fin de section
    while body and body[-1].strip() in ("", "---"):
        body.pop()
    if new != old:
        body[0] = head.replace("ADR-" + old, "ADR-" + new, 1)
        body.insert(1, "")
        body.insert(2, "> [!NOTE]")
        body.insert(3, "> Renumeroté de `ADR-%s` en `ADR-%s` le 2026-08-03 : le numero `ADR-%s` etait porte par deux decisions distinctes. Voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1." % (old, new, old))
    s = slug(head)
    path = os.path.join(OUT, "ADR-%s-%s.md" % (new, s))
    io.open(path, "w", encoding="utf-8", newline="\n").write("\n".join(body) + "\n")
    manifest.append((new, old, s, head, len(body)))

with io.open(os.path.join(os.environ["SCRATCH"], "adr_manifest.tsv"), "w", encoding="utf-8", newline="\n") as f:
    for new, old, s, head, n in sorted(manifest, key=lambda r: r[0]):
        f.write("%s\t%s\t%s\t%s\t%d\n" % (new, old, s, head.replace("\t", " "), n))

print("fichiers ecrits: %d" % len(manifest))
print("renumerotes: %s" % [ (o, n) for n, o, _, _, _ in manifest if n != o ])
```

- [ ] **Étape 2 : Exécuter le script**

```bash
export SCRATCH="C:/Users/Gpdac/AppData/Local/Temp/claude/C--Users-Gpdac-Documents-GameDev-and-Godot-Roguelike-Card-Game-roguelike-card-game/f035a3db-f1c3-43d5-b643-44499cdeff9a/scratchpad"
PYTHONIOENCODING=utf-8 python "$SCRATCH/split_adr.py"
```

Attendu :
```
fichiers ecrits: 77
renumerotes: [('068', '074'), ('067', '075'), ('028', '076'), ('069', '077')]
```

Si l'assertion sur les 77 titres échoue, **arrêter** : la source n'est pas celle attendue.

- [ ] **Étape 3 : Vérifier le compte, l'unicité et l'absence de trou**

```bash
ls .obsidian_vault/_adr/*.md | wc -l
ls .obsidian_vault/_adr/ | grep -oE "ADR-[0-9]{3}" | sort | uniq -d
ls .obsidian_vault/_adr/ | grep -oE "[0-9]{3}" | sort -n | uniq | wc -l
```

Attendu : `77`, puis **aucune sortie** (zéro doublon), puis `77` (numéros 001 à 077, sans trou).

- [ ] **Étape 4 : Vérifier qu'aucun contenu n'a été perdu**

```bash
SRC=$(grep -vcE "^\s*(---)?\s*$" .obsidian_vault/_archive/2026-08-03-decisionLog.md)
OUTC=$(cat .obsidian_vault/_adr/*.md | grep -vcE "^\s*(---)?\s*$")
echo "source: $SRC  eclate: $OUTC  delta: $((OUTC-SRC))"
```

Attendu : `delta` compris entre **0 et 12** — les seules lignes non vides ajoutées sont les 3 lignes de note sur chacun des 4 ADR renumérotés. Un delta négatif signale une perte : **arrêter et diagnostiquer**.

- [ ] **Étape 5 : Vérifier que les 4 renumérotations portent leur note**

```bash
grep -l "Renumeroté de" .obsidian_vault/_adr/*.md
```

Attendu : exactement les 4 fichiers `ADR-074-*`, `ADR-075-*`, `ADR-076-*`, `ADR-077-*`.

- [ ] **Étape 6 : Committer**

```bash
git add .obsidian_vault/_adr/
git commit -m "docs: split decisionLog into 77 per-ADR files, resolving 4 numbering collisions"
```

---

## Tâche 5 : `decisionLog.md` devient un index

**Files:**
- Modify: `.obsidian_vault/_memory_bank/decisionLog.md` (remplacement intégral)
- Read-only: `<scratchpad>/adr_manifest.tsv`, `.obsidian_vault/_adr/*.md`

**Interfaces:**
- Consumes: les 77 fichiers `.obsidian_vault/_adr/*.md` produits par la Tâche 4. `adr_manifest.tsv` sert de contre-vérification manuelle, le générateur ne le lit pas.
- Produces: l'index que la Garantie 5 du skill exige de lire pour calculer `max(index) + 1`.

- [ ] **Étape 1 : Écrire le générateur d'index**

Créer `<scratchpad>/build_index.py` :

```python
import io, os, re, glob

rows = []
for path in sorted(glob.glob(".obsidian_vault/_adr/*.md")):
    txt = io.open(path, encoding="utf-8").read()
    head = txt.split("\n", 1)[0]
    num = re.search(r"ADR-(\d+)", head).group(1)
    title = re.sub(r"^##\s*\S*\s*ADR-\d+\s*:\s*", "", head).strip()
    m = re.search(r"###\s*Statut\s*\n+(.+)", txt)
    statut = m.group(1).strip() if m else ""
    icone = "✅" if statut.startswith("✅") else ("⚠️" if statut.startswith("⚠️") else "•")
    v = re.search(r"\bv[0-9]+\.[0-9]+\.[0-9]+\b", head + " " + statut)
    rows.append((num, title, icone, v.group(0) if v else "—", os.path.basename(path)))

rows.sort(key=lambda r: r[0], reverse=True)
out = [
    "# 📋 Index des Décisions Architecturales (Decision Log)",
    "",
    "Index des **ADR** (Architecture Decision Records) de **Hero's Draft**. Le corps de chaque décision vit dans son propre fichier sous `.obsidian_vault/_adr/`.",
    "",
    "> [!IMPORTANT]",
    "> **Plafond : 250 lignes.** Ce fichier est un index, jamais un contenu. Un nouvel ADR prend le numéro `max(index) + 1` lu ici, jamais un numéro deviné.",
    "",
    "**Vérifié le 2026-08-03** — %d décisions, numéros `ADR-001` à `ADR-%s`, sans doublon ni trou." % (len(rows), rows[0][0]),
    "",
    "| N° | Décision | Statut | Version | Fichier |",
    "|:---|:---|:---:|:---:|:---|",
]
for num, title, icone, ver, fn in rows:
    out.append("| `ADR-%s` | %s | %s | %s | [%s](../_adr/%s) |" % (num, title, icone, ver, fn, fn))
out += [
    "",
    "---",
    "",
    "## Renumérotations du 2026-08-03",
    "",
    "Quatre numéros portaient chacun deux décisions distinctes. Arbitrage : les références entrantes l'emportent, puis l'ancienneté. Détail en `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.",
    "",
    "| Ancien | Nouveau | Décision déplacée |",
    "|:---:|:---:|:---|",
    "| `ADR-068` | `ADR-074` | Forge de Fusion (v3.1.0) |",
    "| `ADR-067` | `ADR-075` | Clés Dupliquées de Notification (v0.2.8) |",
    "| `ADR-028` | `ADR-076` | Synchronisation du Bouton Fin de Tour |",
    "| `ADR-069` | `ADR-077` | Clarté du Mana des Reliques (v3.0.1) |",
    "",
]
io.open(".obsidian_vault/_memory_bank/decisionLog.md", "w", encoding="utf-8", newline="\n").write("\n".join(out))
print("lignes: %d, adr: %d" % (len(out), len(rows)))
```

- [ ] **Étape 2 : Exécuter et vérifier le plafond**

L'état du shell ne persiste pas entre deux appels : `SCRATCH` doit être ré-exporté ici.

```bash
export SCRATCH="C:/Users/Gpdac/AppData/Local/Temp/claude/C--Users-Gpdac-Documents-GameDev-and-Godot-Roguelike-Card-Game-roguelike-card-game/f035a3db-f1c3-43d5-b643-44499cdeff9a/scratchpad"
PYTHONIOENCODING=utf-8 python "$SCRATCH/build_index.py"
wc -l .obsidian_vault/_memory_bank/decisionLog.md
```

Attendu : `lignes: 9x, adr: 77`, et `wc -l` **≤ 250**.

- [ ] **Étape 3 : Vérifier que chaque lien de l'index pointe sur un fichier existant**

```bash
grep -oE "\(\.\./_adr/[^)]+\)" .obsidian_vault/_memory_bank/decisionLog.md \
  | tr -d '()' | sed 's|\.\./|.obsidian_vault/|' \
  | while read p; do [ -e "$p" ] || echo "LIEN MORT: $p"; done
```

Attendu : aucune sortie.

- [ ] **Étape 4 : Vérifier l'unicité et le tri**

```bash
grep -oE "ADR-[0-9]{3}" .obsidian_vault/_memory_bank/decisionLog.md | head -80 | sort | uniq -d
```

Attendu : aucune sortie.

- [ ] **Étape 5 : Committer**

```bash
git add .obsidian_vault/_memory_bank/decisionLog.md
git commit -m "docs: replace decisionLog body with a sorted ADR index"
```

---

## Tâche 6 : Réécriture de `progress.md`

**Files:**
- Modify: `.obsidian_vault/_memory_bank/progress.md`
- Create: `.obsidian_vault/_archive/2026-08-03-progress-historique.md`

**Interfaces:**
- Consumes: l'index de la Tâche 5 (pour les liens ADR).
- Produces: la base factuelle re-mesurée que les Tâches 7, 8 et 9 citent au lieu de la dupliquer.

- [ ] **Étape 1 : Re-mesurer toutes les métriques**

```bash
flutter test 2>&1 | tail -3
dart analyze 2>&1 | tail -3
find lib -name "*.dart" | wc -l
find lib -name "*.dart" -exec cat {} + | wc -l
ls assets/data/*.json | wc -l
grep -n "^version:" pubspec.yaml
python -c "import json;d=json.load(open('assets/data/patch_notes.json',encoding='utf-8'));print(d[0]['version'],d[0]['date'],d[0]['title'])"
```

Noter chaque valeur. **Ce sont les seuls chiffres autorisés dans le fichier.**

- [ ] **Étape 2 : Vérifier chaque chemin cité par l'ancien §6**

```bash
for p in docs/archives/reward_and_luck_system.md docs/archives/système_de_passifs.md \
         docs/archives/world_map_system.md docs/archives/stratégies_migrations.md \
         docs/possible_upgrades/upgrade_ideas.md docs/lessons \
         docs/analysis_reports/technical_debt_report_Opus4.6.md; do
  [ -e "$p" ] && echo "OK  $p" || echo "ABSENT $p"
done
ls docs/implementation_plans/done | wc -l
ls docs/analysis_reports/dette_technique_rapport_Gemini3.5*.md | wc -l
ls docs/lessons/
```

Les comptes obtenus remplacent « 22 fichiers » et « ×4 ». Les noms réels de `docs/lessons/` remplacent `flame_riverpod_sync.md` et `state_immutability.md`.

- [ ] **Étape 3 : Extraire l'historique vers l'archive**

Déplacer verbatim depuis `.obsidian_vault/_archive/2026-08-03-progress.md` vers `.obsidian_vault/_archive/2026-08-03-progress-historique.md` :
- l'intégralité du §7 « Historique des Releases » **sauf ses 10 entrées les plus récentes** ;
- l'intégralité du §4 « Chantiers de Refactoring Prioritaires » (remplacé par `docs/ROADMAP.md`) ;
- l'intégralité du §3 « Fonctionnalités Non Implémentées » (remplacé par `docs/ROADMAP.md`) ;
- l'intégralité du §5 « Problèmes d'Équilibrage » (repris par `docs/ROADMAP.md` P-17).

En-tête du fichier d'archive :

```markdown
# Archive — progress.md, sections historiques (2026-08-03)

Sections retirées de `progress.md` lors de la refonte documentaire du 3 août 2026. Conservées verbatim pour la traçabilité. **Ne pas éditer.**

Le backlog et les chantiers priorisés vivent désormais dans `docs/ROADMAP.md`.
```

- [ ] **Étape 4 : Réécrire `progress.md` selon cette structure exacte**

```markdown
# 📊 État du Projet & Progrès

> [!IMPORTANT]
> **Plafond : 300 lignes.** Ce fichier décrit **ce qui est construit**, jamais ce qui reste à faire — voir `docs/ROADMAP.md`.

## Métriques

**Vérifié le 2026-08-03**

| Métrique | Valeur | Commande |
|:---|:---|:---|
| Tests automatisés | <mesuré> au vert | `flutter test` |
| Analyse statique | <mesuré> | `dart analyze` |
| Fichiers Dart (`lib/`) | <mesuré> | `find lib -name "*.dart" \| wc -l` |
| Lignes de code (`lib/`) | <mesuré> | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | <mesuré> | `ls assets/data/*.json \| wc -l` |
| Version `pubspec.yaml` | <mesuré> | lecture directe |
| Version joueur | <mesuré> | 1ʳᵉ entrée de `patch_notes.json` |

## 1. Fonctionnalités opérationnelles

<Reprendre les sous-sections thématiques du §1 de l'archive — Sauvegarde, World Map,
Contrôleurs, Cartes/Deck, Combat, Passifs, i18n, Rendu, Statuts, Tutoriel — en
supprimant les colonnes de commentaire redondantes et en remplaçant toute mention
de décision par un lien vers `../_adr/ADR-0XX-*.md`. Corriger la ligne
`RunController` : retirer `RunPersistenceManager`, citer `SaveService` et
`checkpoint_controller.dart`.>

## 2. Dette métier assumée

<Reprendre le §2 de l'archive : Système Audio et Sérialisation partielle des modèles.
Corriger « TODO: Audio Hook disséminés » par le compte réel mesuré via
`grep -rn "TODO: Audio Hook" lib --include=*.dart | wc -l`.>

## 3. Références documentaires

**Vérifié le 2026-08-03** — chaque chemin testé avec `test -e`.

<Tableau des documents, avec les chemins corrigés de l'Étape 2 et les comptes réels.>

## 4. Historique des releases (10 dernières)

<Les 10 entrées les plus récentes du §7 de l'archive, telles quelles. Les antérieures
sont dans `.obsidian_vault/_archive/2026-08-03-progress-historique.md`.>

> [!NOTE]
> **Écart de schéma de version connu.** L'historique ci-dessus emploie un schéma
> interne (`v3.x`) distinct de la version joueur de `patch_notes.json` (`0.4.x`).
> Depuis le 2026-08-03, la version de référence est celle de `patch_notes.json`,
> maintenue conjointement avec `pubspec.yaml` par le skill `patch-notes-writer`.
```

- [ ] **Étape 5 : Vérifier le plafond et l'absence de chemin mort**

```bash
wc -l .obsidian_vault/_memory_bank/progress.md
grep -oE '`[^`]*\.(md|json|dart|yaml)`' .obsidian_vault/_memory_bank/progress.md \
  | tr -d '`' | sort -u \
  | while read p; do [ -e "$p" ] || echo "CHEMIN MORT: $p"; done
```

Attendu : **≤ 300** lignes, et aucun chemin mort.

- [ ] **Étape 6 : Vérifier qu'aucun chiffre périmé ne subsiste**

```bash
grep -nE "11 600|145\+|106 |211/211|2 471|1 667|~79 fichiers" .obsidian_vault/_memory_bank/progress.md
```

Attendu : aucune sortie.

- [ ] **Étape 7 : Committer**

```bash
git add .obsidian_vault/_memory_bank/progress.md .obsidian_vault/_archive/
git commit -m "docs: rewrite progress.md on re-measured metrics, archive backlog and old releases"
```

---

## Tâche 7 : `productContext.md` devient un index de fiches de règles

**Files:**
- Create: `.obsidian_vault/_archive/2026-08-03-productContext-sprints.md`
- Create: `.obsidian_vault/_rules/<NN>-<MM>-<slug>.md` (une fiche par système)
- Modify: `.obsidian_vault/_memory_bank/productContext.md` (remplacé par un index)

**Interfaces:**
- Consumes: `.obsidian_vault/_archive/2026-08-03-productContext.md` (copie verbatim de la Tâche 1).
- Produces: le script `split_vault_doc.py`, réutilisé tel quel par la Tâche 8, et les fiches de règles que `activeContext.md` (Tâche 9) référence sans les paraphraser.

> [!IMPORTANT]
> **Cette tâche a été redéfinie le 2026-08-04.** Sa version initiale visait un plafond de 400 lignes par simple archivage des §9-11. Mesure faite à l'exécution : ces trois sections ne pèsent que 87 lignes sur 808, laissant 721 lignes de **règles de jeu courantes et valides**. Atteindre 400 aurait exigé d'archiver du contenu vivant, ce que « on déplace, on ne résume pas » interdit. On applique donc le mécanisme déjà éprouvé sur les 77 ADR : index + fiches adressables.

- [ ] **Étape 1 : Archiver les sections de sprint et renuméroter les `### 3.x`**

Déplacer verbatim vers `.obsidian_vault/_archive/2026-08-03-productContext-sprints.md` les §9, §10 et §11 (rapports de sprint v0.0.97 → v0.2.2, 87 lignes).

En-tête du fichier d'archive :

```markdown
# Archive — productContext.md, rapports de sprint (2026-08-03)

Sections §9 à §11 retirées de `productContext.md` lors de la refonte du 3 août 2026 : rapports de sprint historiques (v0.0.97 → v0.2.2), sans valeur de règle métier courante. Conservées verbatim. **Ne pas éditer.**
```

Puis renuméroter les `### 3.x` dans leur ordre d'apparition physique — `### 3.10` est aujourd'hui intercalée entre `### 3.7` et `### 3.8`. Seul le numéro change ; le titre reste identique. Consigner la table avant→après.

- [ ] **Étape 2 : Écrire le script de découpe générique**

Créer `<scratchpad>/split_vault_doc.py`. Il sert aux Tâches 7 **et** 8 :

```python
import io, os, re, sys, unicodedata

SRC, OUT = sys.argv[1], sys.argv[2]
MAXLEN = 150

def slug(t):
    t = re.sub(r"^#+\s*", "", t)
    t = re.sub(r"^[\d.]+\.?\s*", "", t)
    t = re.sub(r"`([^`]*)`", r"\1", t)
    t = re.sub(r"\(.*?\)", "", t)
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode()
    t = re.sub(r"[^a-zA-Z0-9]+", "-", t).strip("-").lower()
    return t[:45].rstrip("-") or "section"

def num(t):
    m = re.match(r"^#+\s*(\d+(?:\.[\dA-Za-z]+)*)\.?\s", t)
    return m.group(1) if m else None

def trim(b):
    while b and b[-1].strip() in ("", "---"):
        b.pop()
    return b

lines = io.open(SRC, encoding="utf-8").read().split("\n")
h2 = [i for i, l in enumerate(lines) if re.match(r"^## ", l)]
assert h2, "aucune section ## dans %s" % SRC
os.makedirs(OUT, exist_ok=True)

chunks = []
for k, start in enumerate(h2):
    end = h2[k + 1] if k + 1 < len(h2) else len(lines)
    body = trim(lines[start:end])
    sec = num(lines[start]) or str(k + 1)
    subs = [j for j in range(1, len(body)) if re.match(r"^### \d+\.[\dA-Za-z]", body[j])]
    if len(body) <= MAXLEN or not subs:
        chunks.append((sec, "00", body[0], body))
        continue
    pre = trim(body[:subs[0]])
    if len(pre) > 1:
        chunks.append((sec, "00", pre[0], pre))
    for m, s in enumerate(subs):
        e = subs[m + 1] if m + 1 < len(subs) else len(body)
        sub = trim(body[s:e])
        sn = (num(body[s]) or "").split(".", 1)[-1].replace(".", "-") or str(m + 1)
        chunks.append((sec, sn, sub[0], sub))

seen, manifest = set(), []
for sec, sub, head, body in chunks:
    name = "%02d-%s-%s.md" % (int(re.match(r"\d+", sec).group()), sub, slug(head))
    assert name not in seen, "collision de nom de fichier: %s" % name
    seen.add(name)
    io.open(os.path.join(OUT, name), "w", encoding="utf-8", newline="\n").write("\n".join(body) + "\n")
    manifest.append((name, head, len(body)))

print("fiches: %d" % len(manifest))
print("plus grande fiche: %d lignes" % max(m[2] for m in manifest))
for n, h, c in sorted(manifest):
    print("%5d  %s" % (c, n))
```

Trois comportements sont voulus et ne doivent pas être « corrigés » :

- un `###` **non numéroté** (ex. `### Règles Métier et Équilibrage des Cartes` dans §2) reste attaché à la fiche de son grand frère numéroté — c'en est la suite ;
- un numéro non standard (`2.1.bis`) produit sa propre fiche ;
- une **collision de nom de fichier** lève l'assertion. Elle ne doit pas se produire : deux sections peuvent porter le même numéro, mais leurs titres diffèrent, donc leurs slugs aussi.

> [!IMPORTANT]
> **Le titre `## N. …` d'une section redécoupée n'atterrit dans aucune fiche** : le garde `if len(pre) > 1` écarte un préambule réduit à sa seule ligne de titre. C'est voulu — une fiche d'une ligne n'aurait pas de sens — mais le titre ne doit pas disparaître pour autant. **Son domicile est l'index** : l'Étape 5 en fait un sous-titre `###` de groupe, repris verbatim. Vérifier explicitement, avant de committer, que chaque titre de section d'origine se retrouve soit en tête d'une fiche, soit en sous-titre de groupe dans l'index.

- [ ] **Étape 3 : Découper**

```bash
export SCRATCH="C:/Users/Gpdac/AppData/Local/Temp/claude/C--Users-Gpdac-Documents-GameDev-and-Godot-Roguelike-Card-Game-roguelike-card-game/f035a3db-f1c3-43d5-b643-44499cdeff9a/scratchpad"
PYTHONIOENCODING=utf-8 python "$SCRATCH/split_vault_doc.py" .obsidian_vault/_memory_bank/productContext.md .obsidian_vault/_rules
```

Attendu : environ **25 fiches**, la plus grande sous 150 lignes. Un nombre très différent, ou une fiche au-delà de 150 lignes, signale un découpage manqué : **arrêter et rapporter**.

- [ ] **Étape 4 : Vérifier l'absence de perte**

```bash
SRC=$(grep -vcE "^\s*(---)?\s*$" .obsidian_vault/_memory_bank/productContext.md)
OUTC=$(cat .obsidian_vault/_rules/*.md | grep -vcE "^\s*(---)?\s*$")
echo "source: $SRC  fiches: $OUTC  delta: $((OUTC-SRC))"
```

Attendu : un delta **négatif et petit**, égal au nombre de lignes non vides de l'en-tête du fichier source (titre, chapeau, éventuel bloc de plafond) qui précèdent la première `##` et n'appartiennent donc à aucune fiche. Le calculer explicitement et vérifier que les deux valeurs coïncident. **Tout écart inexpliqué arrête la tâche.**

- [ ] **Étape 5 : Remplacer `productContext.md` par son index**

Structure exacte :

```markdown
# 🎯 Contexte Produit & Règles Métier — Index

> [!IMPORTANT]
> **Plafond : 120 lignes.** Ce fichier est un index, jamais un contenu. Chaque règle métier vit dans sa fiche sous `../_rules/`. Les arbitrages qui les ont produites vivent dans `../_adr/`.

**Vérifié le 2026-08-03** — <N> fiches, découpées depuis un `productContext.md` de <lignes réelles mesurées> lignes.

<Un bloc par section `##` d'origine, dans l'ordre numérique des sections :>

### <titre `## N. …` d'origine, texte repris verbatim>

| Domaine | Fiche | Lignes |
|:---|:---|---:|
<une ligne par fiche du groupe, triée par ordre **numérique** de sous-section (3.2 avant 3.10, jamais l'inverse) ; libellé repris du titre ; lien `[nom](../_rules/nom)`>

---

## Historique

Les rapports de sprint v0.0.97 → v0.2.2 (anciennes §9 à §11) sont dans `../_archive/2026-08-03-productContext-sprints.md`.

## Renumérotation des `### 3.x` du 2026-08-03

`### 3.10` était intercalée entre `### 3.7` et `### 3.8`. Les sous-sections ont été renumérotées dans leur ordre d'apparition physique.

<table avant→après issue de l'Étape 1>
```

- [ ] **Étape 6 : Vérifier plafond, liens et bijection**

```bash
wc -l .obsidian_vault/_memory_bank/productContext.md
ls .obsidian_vault/_rules/*.md | wc -l
grep -oE "\(\.\./_rules/[^)]+\)" .obsidian_vault/_memory_bank/productContext.md \
  | tr -d '()' | sed 's|\.\./|.obsidian_vault/|' \
  | while read p; do [ -e "$p" ] || echo "LIEN MORT: $p"; done
```

Attendu : **≤ 120** lignes ; aucun lien mort. Vérifier aussi la réciproque — chaque fiche du dossier a bien une ligne d'index — en comparant les deux listes triées.

- [ ] **Étape 7 : Committer**

```bash
git add .obsidian_vault/_memory_bank/productContext.md .obsidian_vault/_rules/ .obsidian_vault/_archive/
git commit -m "docs: split productContext into addressable rule sheets behind an index"
```

---

## Tâche 8 : `systemPatterns.md` devient un index de fiches d'architecture

**Files:**
- Create: `.obsidian_vault/_archive/2026-08-03-systemPatterns-historique.md`
- Create: `.obsidian_vault/_patterns/<NN>-<MM>-<slug>.md`
- Modify: `.obsidian_vault/_memory_bank/systemPatterns.md` (remplacé par un index)

**Interfaces:**
- Consumes: `split_vault_doc.py` de la Tâche 7, **réutilisé sans modification**.
- Produces: la description d'architecture que `CLAUDE.md` (Tâche 11) doit refléter sans la contredire.

- [ ] **Étape 1 : Archiver les sections datées par version**

Déplacer verbatim vers `.obsidian_vault/_archive/2026-08-03-systemPatterns-historique.md` les sections dont le titre porte un numéro de version : `## 13. … (Design System, v0.0.99)` (74 l.) et `## 14. … (UX Combat) (v0.1.00)` (83 l.).

Règle de tri, applicable à toute autre section suffixée d'une version : décrit-elle un pattern **encore en vigueur** ? Elle reste, débarrassée de son suffixe de version. Décrit-elle le **déroulé d'un chantier passé** ? Elle part à l'archive.

En-tête :

```markdown
# Archive — systemPatterns.md, sections datées (2026-08-03)

Sections retirées de `systemPatterns.md` lors de la refonte du 3 août 2026 : descriptions de chantiers d'architecture passés, rattachées à une version révolue. Conservées verbatim. **Ne pas éditer.**
```

- [ ] **Étape 2 : Corriger les faits d'architecture périmés**

```bash
ls lib/game/controllers/run/ lib/game/controllers/combat/ lib/game/controllers/
grep -n "run_persistence_manager\|RunPersistenceManager" .obsidian_vault/_memory_bank/systemPatterns.md
```

Le sous-dossier `run/` contient 3 fichiers, `combat/` en contient 2, et `checkpoint_controller.dart` existe à la racine des contrôleurs. Mentionner la **suppression** de `RunPersistenceManager` reste légitime — c'est un fait historique. Le présenter comme existant ne l'est pas.

Comme en Tâche 6 : toute affirmation numérique au présent que vous conservez doit être re-mesurée par commande. Une affirmation invérifiable se retire plutôt que de se recopier.

- [ ] **Étape 3 : Découper avec le script de la Tâche 7**

```bash
export SCRATCH="C:/Users/Gpdac/AppData/Local/Temp/claude/C--Users-Gpdac-Documents-GameDev-and-Godot-Roguelike-Card-Game-roguelike-card-game/f035a3db-f1c3-43d5-b643-44499cdeff9a/scratchpad"
PYTHONIOENCODING=utf-8 python "$SCRATCH/split_vault_doc.py" .obsidian_vault/_memory_bank/systemPatterns.md .obsidian_vault/_patterns
```

Attendu : environ **38 fiches**, la plus grande sous 150 lignes.

> [!NOTE]
> `## 2.` contient un `### 2.1.bis` et **deux sous-sections numérotées `### 2.5`** (`ShopController` et `Immutabilité Stricte des Modèles d'État`) — une collision du même type que celle des ADR. Les slugs diffèrent, donc les noms de fichiers aussi : le script ne lèvera pas d'assertion. **Signaler cette collision dans le rapport** : elle est réelle et devra être tranchée, mais pas dans cette tâche.

- [ ] **Étape 4 : Vérifier l'absence de perte**

Même contrôle qu'en Tâche 7 étape 4, avec `_patterns` à la place de `_rules`. Même exigence : delta négatif, petit, et intégralement expliqué par l'en-tête du fichier source.

- [ ] **Étape 5 : Remplacer `systemPatterns.md` par son index**

Même structure qu'en Tâche 7 étape 5 — **index groupé par section d'origine**, sous-titres `###` repris verbatim, lignes triées par ordre numérique de sous-section — avec :

- titre `# 🏗️ Architecture & Conception — Index` ;
- plafond **120 lignes** ;
- fiches sous `../_patterns/` ;
- une section « Historique » renvoyant à `../_archive/2026-08-03-systemPatterns-historique.md` ;
- une section « Collision de numérotation constatée » consignant le doublon `### 2.5` relevé à l'Étape 3.

- [ ] **Étape 6 : Vérifier plafond, liens et bijection**

Mêmes commandes qu'en Tâche 7 étape 6, avec `_patterns`. Attendu : **≤ 120** lignes, aucun lien mort, bijection index ↔ fiches dans les deux sens.

- [ ] **Étape 7 : Committer**

```bash
git add .obsidian_vault/_memory_bank/systemPatterns.md .obsidian_vault/_patterns/ .obsidian_vault/_archive/
git commit -m "docs: split systemPatterns into addressable pattern sheets behind an index"
```

---

## Tâche 9 : `activeContext.md` devient une fenêtre glissante

**Files:**
- Modify: `.obsidian_vault/_memory_bank/activeContext.md`
- Create: `.obsidian_vault/_archive/2026-08-03-activeContext-journal.md`

**Interfaces:**
- Consumes: `progress.md` (Tâche 6), l'index ADR (Tâche 5), `docs/ROADMAP.md` (Tâche 10 — le lien peut être écrit avant que le fichier existe, la Tâche 12 le validera).
- Produces: l'ancre `last-sync` que la Garantie 7 du skill exige.

- [ ] **Étape 1 : Extraire le journal complet vers l'archive**

Déplacer verbatim l'intégralité du §2 « Accomplissements Récents » de l'archive (les ~350 lignes, de v0.2.4 à ADR-073) vers `.obsidian_vault/_archive/2026-08-03-activeContext-journal.md`.

En-tête :

```markdown
# Archive — activeContext.md, journal des accomplissements (2026-08-03)

Journal append-only accumulé de juin à juillet 2026, retiré de `activeContext.md` lors de la refonte du 3 août. Le même contenu existe sous forme structurée dans `../_adr/` et dans l'historique des releases de `progress.md`. Conservé verbatim. **Ne pas éditer.**
```

- [ ] **Étape 2 : Relever le `sha` de `HEAD` pour l'ancre**

```bash
git rev-parse --short HEAD
```

- [ ] **Étape 3 : Réécrire `activeContext.md` selon cette structure exacte**

```markdown
<!-- last-sync: 2026-08-03 | commit: <sha de l'étape 2> -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

<3 à 6 lignes. À la date de rédaction : la refonte documentaire elle-même (branche
`docs/memory-bank-overhaul`), et le fait que la roadmap priorisée du 31/07 est
désormais `docs/ROADMAP.md`. Prochain chantier applicatif : P-02 (assainissement du
système de pioche), P-03 (audio) et P-04 (CI/CD) — P-01 étant clos.>

## 3 dernières livraisons

1. **Refonte documentaire** (2026-08-03) — <2 à 4 lignes + lien vers la spec>
2. **Réactivité du bouton « Continuer »** (2026-07-26) — <2 à 4 lignes + lien `../_adr/ADR-073-*.md`>
3. **Accélération de la cadence du scaling de difficulté** (2026-07-26) — <2 à 4 lignes + lien `../_adr/ADR-072-*.md`>

## Prochaine étape

Voir `docs/ROADMAP.md` — Jalon 1 « Socle » : P-02, P-04, P-03.
```

- [ ] **Étape 4 : Vérifier le plafond, l'ancre et l'absence de backlog**

```bash
wc -l .obsidian_vault/_memory_bank/activeContext.md
head -1 .obsidian_vault/_memory_bank/activeContext.md
grep -cE "^[0-9]+\." .obsidian_vault/_memory_bank/activeContext.md
```

Attendu : **≤ 120** lignes ; la 1ʳᵉ ligne est l'ancre `last-sync` ; au plus **3** items numérotés.

- [ ] **Étape 5 : Committer**

```bash
git add .obsidian_vault/_memory_bank/activeContext.md .obsidian_vault/_archive/
git commit -m "docs: reduce activeContext to a 3-delivery sliding window with a sync anchor"
```

---

## Tâche 10 : Roadmap, archives périphériques et resync de version

**Files:**
- Move: `docs/roadmap_priorisee_31-07-2026.md` → `docs/ROADMAP.md`
- Move: `docs/backlog_and_roadmap_report_22072026.md` → `docs/archives/`
- Move: `task.md` → `docs/archives/2026-07-01-task-forge-fusion.md`
- Modify: `docs/ROADMAP.md` (en-tête + P-01 coché), `pubspec.yaml` (champ `version:`)

**Interfaces:**
- Consumes: la règle de propriété de version du skill `patch-notes-writer` (Tâche 3).
- Produces: `docs/ROADMAP.md`, cible de tous les liens « reste à faire » écrits aux Tâches 6 et 9.

- [ ] **Étape 1 : Déplacer les fichiers en préservant l'historique**

```bash
git mv docs/roadmap_priorisee_31-07-2026.md docs/ROADMAP.md
git mv docs/backlog_and_roadmap_report_22072026.md docs/archives/
git mv task.md docs/archives/2026-07-01-task-forge-fusion.md
```

- [ ] **Étape 2 : Mettre à jour l'en-tête de `docs/ROADMAP.md`**

Remplacer la ligne `**Nature du document**` par :

```markdown
**Nature du document** : document de pilotage réutilisable — **source unique du « reste à faire »**. Il remplace `backlog_and_roadmap_report_22072026.md` (archivé), ainsi que les anciens §3 et §4 de `progress.md` (archivés). Maintenu par le skill `memory-bank-sync` : tout chantier livré y est coché dans la même passe.
```

- [ ] **Étape 3 : Cocher P-01 dans `docs/ROADMAP.md`**

Dans le tableau du Tier S, remplacer la ligne P-01 par :

```markdown
| ~~**P-01**~~ | ~~**Resynchroniser `pubspec.yaml`** (`0.1.0+1` → `0.4.7+1`) sur `patch_notes.json`~~ ✅ **Livré le 2026-08-03** — désormais maintenu automatiquement par le skill `patch-notes-writer` | — | — | — |
```

Dans la section `### P-01 — Resync de version`, ajouter en tête :

```markdown
> [!NOTE]
> ✅ **Clos le 2026-08-03.** La resynchronisation a été faite, et la propriété du numéro de version est désormais portée par le skill `.claude/skills/patch-notes-writer/SKILL.md`, qui l'écrit simultanément dans `patch_notes.json` et `pubspec.yaml`. L'écart ne peut plus se recreuser.
```

- [ ] **Étape 4 : Resynchroniser `pubspec.yaml`**

```bash
python -c "import json;print(json.load(open('assets/data/patch_notes.json',encoding='utf-8'))[0]['version'])"
```

Reporter la valeur obtenue dans `pubspec.yaml`, ligne 4, au format `version: <valeur>+1`. **Aucune autre ligne du fichier ne doit changer.**

- [ ] **Étape 5 : Vérifier que seule la ligne de version a bougé**

```bash
git diff --stat pubspec.yaml
git diff pubspec.yaml
flutter pub get 2>&1 | tail -3
```

Attendu : `1 insertion(+), 1 deletion(-)`, le diff ne montre que la ligne `version:`, et `flutter pub get` se termine sans erreur.

- [ ] **Étape 6 : Vérifier que plus aucun document ne pointe sur les anciens noms**

```bash
grep -rn "roadmap_priorisee_31-07-2026\|backlog_and_roadmap_report_22072026" \
  --include=*.md . | grep -v "^./docs/archives/" | grep -v "^./docs/superpowers/"
```

Attendu : aucune sortie. Les occurrences dans `docs/superpowers/` (spec et plan) sont historiques et légitimes.

- [ ] **Étape 7 : Committer**

```bash
git add -A docs/ pubspec.yaml
git commit -m "docs: promote the prioritised roadmap to docs/ROADMAP.md, close P-01 version resync"
```

---

## Tâche 11 : `CLAUDE.md` et `GEMINI.md`

**Files:**
- Modify: `CLAUDE.md`, `GEMINI.md`

**Interfaces:**
- Consumes: les deux skills (Tâches 2 et 3), `docs/ROADMAP.md` (Tâche 10), la description d'architecture de `systemPatterns.md` (Tâche 8).
- Produces: l'instruction faisant autorité pour toutes les sessions futures.

- [ ] **Étape 1 : Corriger la description des contrôleurs dans `CLAUDE.md`**

Dans la puce `RunController`, remplacer la liste des managers par la liste réelle — `player_stats_manager.dart`, `map_progression_manager.dart`, `gold_manager.dart` — et **retirer `run_persistence_manager.dart`**, supprimé du dépôt.

Ajouter juste après la puce `SkillController` :

```markdown
  - `CheckpointController` (`checkpoint_controller.dart`) — `checkpointProvider` / `autosaveOrchestratorProvider` : déclenche l'autosave à la résolution d'un nœud de carte.
```

Dans la section **Services**, ajouter :

```markdown
  - `SaveService` (`lib/services/save_service.dart`) — sérialise `RunState`/`DeckState`/`InventoryState`/`SkillState` en un blob JSON versionné sous une clé `shared_preferences` unique. Jamais appelé en cours de combat.
```

- [ ] **Étape 2 : Remplacer la puce `patch_notes.json` de la section « Repo-Specific Conventions »**

```markdown
- **`patch_notes.json` is agent-managed**: never hand-edit it. It is maintained by the `patch-notes-writer` skill (`.claude/skills/patch-notes-writer/SKILL.md`), which prepends a new semver entry, writes player-facing French only, and keeps `pubspec.yaml`'s `version:` field in sync with it. Those two files are its entire scope.
- **The memory bank is agent-managed**: `.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/` and `_patterns/` are maintained by the `memory-bank-sync` skill (`.claude/skills/memory-bank-sync/SKILL.md`). It re-measures every metric with a command before writing it, enforces per-file line caps, and archives rather than appends. `.obsidian_vault/_archive/` is read-only.
```

- [ ] **Étape 3 : Ajouter la section « Carte de la documentation » à `CLAUDE.md`**

À insérer avant la section « Repo-Specific Conventions » :

```markdown
## Documentation Map

One question, one place. Never duplicate a fact across two of these — link instead.

| Question | Location |
|:---|:---|
| Where to start | `.obsidian_vault/_memory_bank/` — five short files, three of them indexes |
| Why a decision was taken | `.obsidian_vault/_adr/` — one file per ADR, indexed by `_memory_bank/decisionLog.md` |
| A game rule | `.obsidian_vault/_rules/` — one sheet per system, indexed by `_memory_bank/productContext.md` |
| An architecture pattern | `.obsidian_vault/_patterns/` — one sheet per area, indexed by `_memory_bank/systemPatterns.md` |
| What is built, and the project metrics | `_memory_bank/progress.md` — every figure carries the date it was measured |
| What is being worked on right now | `_memory_bank/activeContext.md` — current focus plus the last three deliveries, nothing older |
| What is left to do | `docs/ROADMAP.md` — **the single planning source** |
| What is designed but not built | `docs/superpowers/specs/` and `docs/superpowers/plans/` |
| What is explored but not decided | `docs/possible_upgrades/` |
| What the player sees | `assets/data/patch_notes.json` |
| Frozen history | `.obsidian_vault/_archive/` and `docs/archives/` — read-only |

The three index files are capped and deliberately short: they exist to be read whole, then to point you at the one sheet you actually need. Never inline a sheet's content back into its index.

`CLAUDE.md` is the authoritative agent instruction file for this repository.
```

- [ ] **Étape 4 : Réduire `GEMINI.md` à un pointeur**

Remplacer l'intégralité du fichier par :

```markdown
# Hero's Draft — Gemini CLI

> **`CLAUDE.md` is the authoritative instruction file for this repository.** Read it first — project overview, commands, architecture, documentation map and conventions all live there. This file only records what is specific to the Gemini CLI.

## Language Rule

All responses, plans, summaries and questions addressed to the user must be written in **French**, without exception.

## Notes

- The `.agents/` directory holds a single active skill, `game_designer.md`. The `orchestrator/`, `worker_m1/`, `explorer_m1_*/`, `challenger_m1_*/`, `reviewer_m1_*/` and `auditor_m1/` folders are empty artefacts of a past multi-agent run — not templates, not active sub-agents.
- Documentation skills live in `.claude/skills/` (`memory-bank-sync`, `patch-notes-writer`). See `CLAUDE.md` for what each one owns.
```

- [ ] **Étape 5 : Vérifier que chaque chemin cité existe**

```bash
grep -ohE '`[^`]*\.(md|dart|json|yaml)`|`[^`]*/`' CLAUDE.md GEMINI.md \
  | tr -d '`' | grep -v '<' | sort -u \
  | while read p; do [ -e "$p" ] || echo "CHEMIN MORT: $p"; done
grep -n "run_persistence_manager" CLAUDE.md GEMINI.md
```

Attendu : aucune sortie pour les deux commandes.

- [ ] **Étape 6 : Committer**

```bash
git add CLAUDE.md GEMINI.md
git commit -m "docs: make CLAUDE.md authoritative with a documentation map, reduce GEMINI.md to a pointer"
```

---

## Tâche 12 : Vérification finale

**Files:**
- Aucun fichier créé ou modifié, sauf correctif si un contrôle échoue.

**Interfaces:**
- Consumes: le résultat de toutes les tâches précédentes.
- Produces: la preuve exécutée des 9 critères de réussite de la spec.

- [ ] **Étape 1 : Plafonds**

```bash
wc -l .obsidian_vault/_memory_bank/*.md
```

Attendu : `activeContext` ≤ 120, `progress` ≤ 300, `productContext` ≤ 120, `systemPatterns` ≤ 120, `decisionLog` ≤ 250, **total < 1 000**.

Puis la contrepartie — le contenu adressé par ces index doit exister :

```bash
ls .obsidian_vault/_adr/*.md | wc -l
ls .obsidian_vault/_rules/*.md | wc -l
ls .obsidian_vault/_patterns/*.md | wc -l
```

Attendu : `77`, puis ~25, puis ~38.

- [ ] **Étape 2 : Aucun chemin mort dans tout le vault**

```bash
grep -rohE '`[^`]*\.(md|dart|json|yaml)`' \
  .obsidian_vault/_memory_bank/ .obsidian_vault/_rules/ .obsidian_vault/_patterns/ .obsidian_vault/_adr/ \
  | tr -d '`' | grep -v '<' | sort -u \
  | while read p; do
      [ -e "$p" ] || [ -e ".obsidian_vault/_memory_bank/$p" ] || echo "CHEMIN MORT: $p"
    done
```

Attendu : aucune sortie.

Puis la bijection des trois index avec leurs fiches, dans les deux sens :

```bash
for d in _adr _rules _patterns; do
  case $d in
    _adr) f=decisionLog ;;
    _rules) f=productContext ;;
    _patterns) f=systemPatterns ;;
  esac
  echo "--- $d ---"
  grep -oE "\(\.\./$d/[^)]+\)" ".obsidian_vault/_memory_bank/$f.md" \
    | tr -d '()' | sed "s|^\.\./|.obsidian_vault/|" | sort -u > /tmp/liens.txt
  ls .obsidian_vault/$d/*.md | sort -u > /tmp/fiches.txt
  echo "liens sans fiche :"; comm -23 /tmp/liens.txt /tmp/fiches.txt
  echo "fiches sans lien :"; comm -13 /tmp/liens.txt /tmp/fiches.txt
done
```

Attendu : les six listes vides.

- [ ] **Étape 3 : Cohérence des versions**

```bash
grep "^version:" pubspec.yaml
python -c "import json;print(json.load(open('assets/data/patch_notes.json',encoding='utf-8'))[0]['version'])"
```

Attendu : le même numéro des deux côtés.

- [ ] **Étape 4 : Index ADR — unicité, tri, complétude**

```bash
ls .obsidian_vault/_adr/*.md | wc -l
ls .obsidian_vault/_adr/ | grep -oE "ADR-[0-9]{3}" | sort | uniq -d
grep -c "^| \`ADR-" .obsidian_vault/_memory_bank/decisionLog.md
```

Attendu : `77`, aucune sortie, `77`.

- [ ] **Étape 5 : Aucune métrique orpheline**

```bash
grep -c "Vérifié le" .obsidian_vault/_memory_bank/progress.md
grep -nE "11 600|145\+|211/211|2 471|1 667" .obsidian_vault/_memory_bank/*.md
```

Attendu : au moins **1** occurrence de « Vérifié le », et aucune sortie pour les chiffres périmés.

- [ ] **Étape 6 : Le code n'a pas été touché**

```bash
git diff main...HEAD --name-only | grep -E "^(lib|test|assets)/" 
dart analyze 2>&1 | tail -3
flutter test 2>&1 | tail -3
```

Attendu : **aucune sortie** pour le premier filtre ; `dart analyze` à 0 issue ; le même nombre de tests qu'à la Tâche 6.

- [ ] **Étape 7 : Aucune information perdue**

```bash
wc -l .obsidian_vault/_archive/2026-08-03-*.md | tail -1
git log --oneline main..HEAD
```

Attendu : l'archive contient au moins les 5 811 lignes d'origine, plus les sections extraites ; l'historique montre au moins **13 commits** de chantier (2 en Tâche 1, puis au moins 1 par tâche de 2 à 11), plus les commits de correctif issus des tours de revue.

- [ ] **Étape 8 : Les skills sont en place et invocables**

```bash
ls .claude/skills/*/SKILL.md
head -3 .claude/skills/memory-bank-sync/SKILL.md
head -3 .claude/skills/patch-notes-writer/SKILL.md
ls .agents/skills/
```

Attendu : deux fichiers `SKILL.md`, chacun avec un frontmatter `name:` correct ; `.agents/skills/` ne contient plus que `game_designer.md`.

- [ ] **Étape 9 : Committer le rapport de vérification s'il a nécessité des correctifs**

```bash
git status --porcelain
```

Si des correctifs ont été nécessaires, les committer :

```bash
git add -A
git commit -m "docs: fix issues found by the final verification pass"
```

---

## Récapitulatif des tâches

| # | Tâche | Livrable vérifiable |
|:---:|:---|:---|
| 1 | Branche et filet de sécurité | 5 archives bit-à-bit identiques, roadmap suivie par git |
| 2 | Skill `memory-bank-sync` | Frontmatter valide, chemins déclarés existants |
| 3 | Skill `patch-notes-writer` | 4 sources vivantes, `task.md` interdit |
| 4 | Éclatement du `decisionLog` | 77 fichiers, 0 doublon, delta de lignes ∈ [0, 12] |
| 5 | Index ADR | ≤ 250 l., 77 liens valides |
| 6 | Réécriture de `progress.md` | ≤ 300 l., 0 chemin mort, 0 chiffre périmé |
| 7 | `productContext.md` → index + fiches | ≤ 120 l., ~25 fiches, 0 lien mort, delta explique |
| 8 | `systemPatterns.md` → index + fiches | ≤ 120 l., ~38 fiches, 0 lien mort, delta explique |
| 9 | Fenêtre glissante `activeContext.md` | ≤ 120 l., ancre présente, ≤ 3 items |
| 10 | Roadmap, archives, resync | `pubspec.yaml` : 1 ligne changée, P-01 coché |
| 11 | `CLAUDE.md` / `GEMINI.md` | 0 chemin mort, 0 `run_persistence_manager` |
| 12 | Vérification finale | 9 critères de la spec, exécutés |
