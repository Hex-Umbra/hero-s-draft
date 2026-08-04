---
name: memory-bank-sync
description: Use after any implementation, merge, or design decision lands in Hero's Draft — updates .obsidian_vault/_memory_bank/ (three capped indexes), the addressable sheets under _adr/, _rules/ and _patterns/, and docs/ROADMAP.md. Verifies every metric against the code before writing, enforces line caps on indexes and sheets alike, archives instead of appending, and keeps ADR numbering collision-free.
---

# Synchronisation du memory bank

Tu maintiens la documentation développeur de **Hero's Draft**. Tu traduis ce qui a été livré en connaissance produit structurée, et tu empêches la dérive entre la documentation et le code.

Écris en **français**. Le frontmatter `description` reste en anglais.

## Ce que tu écris

| Fichier | Plafond | Contenu |
|:---|---:|:---|
| `.obsidian_vault/_memory_bank/activeContext.md` | 120 l. | Focus courant, 3 dernières livraisons, prochaine étape |
| `.obsidian_vault/_memory_bank/progress.md` | 300 l. | État du construit, métriques datées, 10 dernières releases |
| `.obsidian_vault/_memory_bank/productContext.md` | 120 l. | **Index** des fiches de règles métier (tableau seul) |
| `.obsidian_vault/_memory_bank/systemPatterns.md` | 120 l. | **Index** des fiches d'architecture (tableau seul) |
| `.obsidian_vault/_memory_bank/decisionLog.md` | 250 l. | **Index** des ADR (tableau seul) |
| `.obsidian_vault/_adr/ADR-0XX-<slug>.md` | 150 l. | Une fiche par décision |
| `.obsidian_vault/_rules/<slug>.md` | 150 l. | Une fiche par système de jeu |
| `.obsidian_vault/_patterns/<slug>.md` | 150 l. | Une fiche par domaine d'architecture |
| `docs/ROADMAP.md` | — | Le reste à faire, priorisé |

**Un seul mécanisme, appliqué trois fois : index + fiches adressables.** Les trois
index (`decisionLog`, `productContext`, `systemPatterns`) ne contiennent que des
tableaux de liens. Le contenu vit dans les fiches, jamais dans l'index.

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
| Ce qui a changé | `git log <last-sync-sha>..HEAD --oneline` |
| Taille d'un fichier cité comme chantier | `wc -l <fichier>` |

Tout bloc de métriques porte `**Vérifié le YYYY-MM-DD**`.

Ne jamais reprendre un chiffre depuis un document — même depuis ce vault. Les chiffres se re-mesurent.

## Garantie 2 — Plafonds durs

En fin de passe, mesurer les index **et** les fiches :

```bash
wc -l .obsidian_vault/_memory_bank/*.md
wc -l .obsidian_vault/_adr/*.md .obsidian_vault/_patterns/*.md .obsidian_vault/_rules/*.md \
  | sort -rn | head -5
```

Les fiches sont plafonnées comme les index : sans mesure, elles regrossissent sans
que rien ne le signale.

Un dépassement d'index se corrige en **archivant**, jamais en tronquant ni en
condensant. Un dépassement de fiche se corrige en la **redécoupant** (voir Garantie 8).

## Garantie 3 — Archiver, pas empiler

- `activeContext.md` : **FIFO strict à 3 livraisons**. La 4ᵉ pousse la plus ancienne vers `.obsidian_vault/_archive/`.
- `progress.md`, historique des releases : **10 entrées**. Le reste vers l'archive.
- Règle générale : *une passe se termine avec autant ou moins de lignes qu'elle n'a commencé, sauf changement structurel du jeu.*
- Dans un texte conservé pour sa valeur historique (« telles quelles »), seuls les **chemins de fichiers** peuvent être corrigés pour rester résolvables. Les chiffres, les dates et les affirmations restent intouchables.

## Garantie 4 — Source unique

| Fait | Vit uniquement dans |
|:---|:---|
| *Pourquoi* une décision a été prise | `_adr/ADR-0XX.md` |
| *Ce qui est construit* | `progress.md` |
| *Ce sur quoi on travaille* | `activeContext.md` |
| *Ce qui reste à faire* | `docs/ROADMAP.md` |
| *Règle de jeu* | `_rules/<slug>.md` — `productContext.md` n'en porte que le lien |
| *Pattern d'architecture* | `_patterns/<slug>.md` — `systemPatterns.md` n'en porte que le lien |
| *Numéro de version* | `pubspec.yaml` + 1ʳᵉ entrée de `assets/data/patch_notes.json` |

**On lie, on ne recopie pas.** Deux formulations du même fait sont deux occasions de diverger.

Le numéro de version n'est **jamais recopié dans le vault** : il appartient à
`patch-notes-writer`, qui l'écrit dans ses deux fichiers. Le vault y renvoie.
C'est précisément la ligne qui avait divergé (`progress.md` annonçait encore
`0.1.0+1` cinq commits après le passage à `0.4.7+1`).

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
<!-- last-sync: YYYY-MM-DD | commit: <last-sync-sha> -->
```

**Commence toujours ta passe par** `git log <last-sync-sha>..HEAD --oneline` pour savoir exactement ce qui a changé depuis la dernière synchronisation. Ne relis pas le vault entier pour le deviner.

Termine toujours ta passe en mettant l'ancre à jour avec le `sha` de `HEAD`.

## Garantie 8 — Protocole des fiches (`_rules/`, `_patterns/`)

Le mécanisme index + fiches de la Garantie 5 ne vaut pas que pour les ADR : il régit
aussi les règles de jeu et les patterns d'architecture.

1. **Une fiche par système de jeu** sous `_rules/`, **une fiche par domaine
   d'architecture** sous `_patterns/`. Une règle nouvelle crée ou modifie *une* fiche.
2. **Ne jamais réinjecter le contenu d'une fiche dans son index.** `productContext.md`
   et `systemPatterns.md` sont des tableaux de liens plafonnés à 120 lignes ; y écrire
   une règle plutôt que dans sa fiche orphelinise les fiches et reconstitue le
   monolithe que cette architecture a démonté.
3. **Toute fiche dépassant 150 lignes est redécoupée au niveau `###`**, et l'index mis
   à jour dans la même passe. On redécoupe, on ne condense pas.
4. Nommage `<slug-kebab>.md`, préfixé du numéro de section qu'il porte dans l'index
   (`03-13-persistance-de-run.md`), pour que le tri alphabétique soit le tri de l'index.
5. L'index et le répertoire restent en **bijection** : aucune fiche sans ligne d'index,
   aucune ligne d'index sans fiche. Vérifier, ne pas supposer.

## Garantie 9 — Propriété du numéro de version

**Tu enregistres, tu ne décides pas.** Le numéro de version appartient au skill
`patch-notes-writer`, qui l'écrit dans `assets/data/patch_notes.json` et `pubspec.yaml`.

- Le schéma interne **`v3.x` est gelé**. Les lignes existantes de l'historique des
  releases de `progress.md` le conservent pour leur valeur historique ; **aucune
  entrée nouvelle ne l'emploie**.
- Toute ligne ajoutée à l'historique des releases est **clé sur la version publiée
  dans `assets/data/patch_notes.json`** (`0.4.x`), lue et non devinée.
- Si aucun patch note n'a encore été rédigé pour la livraison que tu documentes,
  **n'invente pas de numéro** : décris la livraison sans clé de version et signale-le
  dans ton rapport pour que `patch-notes-writer` soit invoqué.

Trois schémas de version simultanés étaient l'un des symptômes d'origine de la dérive
documentaire. Un seul schéma vivant, un seul propriétaire.

## Checklist de fin de passe

À **exécuter**, pas à cocher de mémoire :

- [ ] `wc -l .obsidian_vault/_memory_bank/*.md` → tous sous leur plafond
- [ ] `wc -l .obsidian_vault/_adr/*.md .obsidian_vault/_patterns/*.md .obsidian_vault/_rules/*.md | sort -rn | head -5` → la plus grande fiche sous 150 l.
- [ ] Bijection index ↔ fiches pour les trois paires (`decisionLog`/`_adr`, `productContext`/`_rules`, `systemPatterns`/`_patterns`)
- [ ] Chaque chemin cité existe : extraire les chemins et les tester avec `test -e`
      — **extraire les deux formes** : les chemins entre backticks *et* les cibles de
      liens markdown `](...)`. Une extraction limitée aux backticks avait laissé passer
      53 liens absolus `file:///` dans 15 fiches d'ADR.
      **Exceptions connues, à ne pas corriger** — ces trois chemins n'ont jamais existé
      dans ce dépôt et sont cités dans des corps d'ADR gelés que la Garantie 5 interdit
      de réécrire :
      `docs/lessons/flame_riverpod_sync.md` (ADR-001, ADR-008),
      `docs/lessons/state_immutability.md` (ADR-005),
      `docs/implementation_plans/deck_merge_system.md` (ADR-007).
      Tout autre échec est un vrai défaut : le corriger ou le signaler.
- [ ] `pubspec.yaml` et la 1ʳᵉ entrée de `patch_notes.json` annoncent la même version — et le vault ne la recopie pas (Garantie 4)
- [ ] Index ADR : numéros uniques et triés
- [ ] Aucune métrique sans `**Vérifié le ...**`
- [ ] Ancre `last-sync` à jour
- [ ] Chantiers livrés cochés dans `docs/ROADMAP.md`

## Style

Markdown structuré et sobre. Utiliser les panneaux `> [!IMPORTANT]` et `> [!NOTE]` pour les invariants de gameplay et les patterns d'architecture — pas pour du commentaire ordinaire.
