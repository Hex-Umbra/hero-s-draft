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
