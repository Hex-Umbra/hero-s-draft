# Proposition — `memory-bank-sync`, adapté au workflow par vagues

**Date** : 06/10/2026
**Objet** : la recommandation R20 de l'[audit du 05/10](05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md) (§6.3) — un vault qui renvoie au code au lieu de le recopier. Ce document propose une version adaptée du skill [`memory-bank-sync`](../../.claude/skills/memory-bank-sync/SKILL.md), son texte complet compris (§6).
**Statut** : proposition. **Le skill en place n'est pas modifié.** L'adopter, c'est remplacer son `SKILL.md` par celui du §6, écrire un ADR qui précise ADR-102 D8 (où s'écrit l'état d'une livraison), et suivre la migration du §7.
**Mesuré le 06/10**, sur `0ec09ab` : les trois commits de synchronisation des vagues (`c4de883`, `db52110`, `80a040b`), les 27 fiches `_rules`, les 45 fiches `_patterns` et les deux index.

---

## 0. En bref

1. **Le skill garde ses neuf garanties** : re-mesurer avant d'écrire, plafonds, archivage, source unique, protocole ADR, périmètre, ancre, protocole des fiches, propriété de la version. Elles marchent.
2. **Ce qui change, c'est ce qu'une fiche contient.** Elle énonce la règle et ce que voit le joueur. Elle donne ses invariants, chacun avec le test qui le garde. Elle nomme les porteurs (le symbole, le fichier de donnée, l'écran). Elle reçoit ses valeurs d'un bloc généré. Elle ne recopie plus à la main un taux, un coût ni un plafond.
3. **Une fiche ne parle plus jamais de l'état d'une branche.** Écrite sur la branche d'une vague, elle est en attente par construction ; la fusion la rend vraie sur `main`, sans qu'on la retouche. L'état d'une livraison vit dans git, `etat.json`, le journal et `activeContext.md`.
4. **Un ADR ancien n'est plus retouché pour dire « complété par » ni « fusionné le »** : seulement quand sa validité change. Les liens entrants, Obsidian les montre.
5. **Le périmètre d'une passe se calcule** à partir du diff et des porteurs cités par les fiches, au lieu de se deviner. Ce calcul ne devient fiable qu'au fil de la migration : sur les fiches d'aujourd'hui, il en rate les deux tiers (§2, C4).
6. **La migration est progressive** : une fiche passe au nouveau format la première fois qu'une passe la touche.

---

## 1. Ce que la synchronisation fait aujourd'hui, mesuré

| | Vague 1 (`c4de883`) | Vague 2 (`db52110`) | Vague 3 (`80a040b`) |
|:---|---:|---:|---:|
| Fichiers touchés par la passe | 33 | 46 | 58 |
| … dont fiches `_rules` et `_patterns` (sur 72) | 21 | 29 | 36 |
| … dont ADR anciens retouchés | 3 | 9 | 14 |
| Jetons des deux skills de fin de vague | 44,6 M | 55,2 M | 79,3 M |

Ce que montrent les fiches et les index :

- **36 fiches sur 72 parlent d'une branche ou d'une vague** : « branche de la vague 2, en attente du propriétaire », puis, à la vague suivante, « vague 2, fusionnée dans `main` le 2026-10-03 ». C'est la lecture qu'a faite le skill d'ADR-102 D8 (« la mémoire note une vague livrée comme livrée sur la branche, en attente »), appliquée aux fiches autant qu'à `activeContext.md`.
- **Les ADR anciens reçoivent des « Complété le … par ADR-107 (… livré sur la branche de la vague 3, en attente du propriétaire) »**. ADR-096 en est un exemple. En vague 2, trois ADR ont été retouchés pour « noter la fusion de la vague 1 ».
- **Les deux index ont une colonne « Lignes »**, re-mesurée à chaque passe (`productContext.md`, `systemPatterns.md`). Chaque fiche touchée oblige donc aussi à réécrire l'index.
- **Les fiches recopient des valeurs.** 62 lignes de `_rules/` portent un taux, un décimal ou un multiplicateur. Exemples : `_rules/02-4` donne les multiplicateurs de rareté (×1,2 à ×2,0), et `_rules/03-7` dit « soigne 30 % » et « 50 or × son niveau ».
- **Seules 16 fiches sur 72 citent un test.**

**Ce qu'il faut en attendre, honnêtement.** Les retouches *uniquement* d'état sont rares : 1 fichier sur 36 en vague 2, 8 sur 47 en vague 3. Les autres portent du vrai contenu, où l'état est mélangé au texte. Retirer l'état allège donc les phrases, mais ne réduit pas beaucoup le nombre de fichiers. Le gain principal doit venir de fiches qui recopient moins : quand une valeur change, une fiche qui la cite par son porteur, ou la reçoit d'un bloc généré, n'a plus à être réécrite. C'est à mesurer, vague après vague, par la ligne « fichiers touchés par `memory-bank-sync` » du tableau de bord (audit, R9).

---

## 2. Les cinq changements

| # | Changement | Ce qu'il retire | Garantie du §6 |
|:---:|:---|:---|:---|
| **C1** | Une fiche dit ce qui est vrai là où elle est écrite : aucun état de branche, de fusion ni de tag | La réécriture d'une phrase d'état à la vague suivante | G13 |
| **C2** | Une fiche pointe : règle, ce que voit le joueur, invariants avec leur test, porteurs, pourquoi, constats | Les valeurs et le code paraphrasés, qui se périment | G10 |
| **C3** | Les valeurs d'une fiche viennent d'un bloc généré depuis la donnée ou une constante | La recopie à la main des tables et des chiffres | G12 |
| **C4** | Le périmètre de la passe se calcule : le diff, croisé avec les porteurs que les fiches citent | La relecture du vault pour deviner ce qui a bougé — **à terme** : rejoué sur la vague 3, le calcul ne trouve que 16 fiches candidates, dont 11 parmi les 36 réellement touchées, parce que les fiches d'aujourd'hui citent rarement leurs porteurs par chemin | G11 |
| **C5** | Moins d'écritures qui ne disent rien : pas de « complété par » dans un ADR ancien, plus de colonne « Lignes » dans les index | Des fichiers touchés sans que leur contenu change | G5, G2 |

---

## 3. Le format d'une fiche, et un exemple réel

### 3.1. Le gabarit

```markdown
<!-- fiche:v2 -->
### <n.m>. <Nom du système>

> <La règle, en une ou deux phrases, telle qu'elle est vraie sur la branche où la fiche est écrite.>

**Ce que voit le joueur** — <ce qui se passe à l'écran, avec les mots du jeu.>

| Invariant | Gardé par |
|:---|:---|
| <ce qui est toujours vrai> | `test/<chemin>_test.dart` › « <nom du test> » |

| Porteur | Où |
|:---|:---|
| <la règle> | `lib/<chemin>.dart` › `<Classe.membre>` |
| <les valeurs> | `assets/data/<dossier>/` |
| <l'écran> | `lib/ui/screens/<écran>.dart` |

**Valeurs**

<!-- genere:debut vue=<nom de la vue> -->
<!-- genere:fin -->

**Pourquoi** — [ADR-0XX](../_adr/ADR-0XX-<slug>.md) · [ADR-0YY](../_adr/ADR-0YY-<slug>.md)

**Constats** — <ce que la fiche a relevé en pointant : une valeur sans porteur unique, un invariant sans test. Un constat se route vers la ROADMAP ; la fiche ne corrige rien.>
```

Les règles :
- **Un invariant sans test s'écrit « aucun test »** dans la colonne « Gardé par ». C'est un constat, pas un oubli à cacher.
- **Aucune valeur de jeu n'est recopiée à la main.** Elle vient d'un bloc généré. Si le générateur ne sait pas la produire, on cite son porteur (« `ForgeRuneRules.sharpenCost` ») au lieu de son chiffre.
- **Les symboles se citent par leur nom**, `chemin › Classe.membre`, jamais par un numéro de ligne, qui bouge à chaque vague.

### 3.2. Exemple : la fiche du feu de camp

**Aujourd'hui** — `_rules/03-7-feu-de-camp-repos.md`, 28 lignes. Extrait de son point 2 :

> **Affûter** — à la place de l'ancienne forge depuis le lot E2 de P-43 ([ADR-106], vague 2, fusionnée dans `main` le 2026-10-03) : **une rune d'une carte gagne un niveau, contre 50 or × son niveau** […] **Le feu n'est plus la seule source d'affûtage** sur la branche de la vague 3 (en attente du propriétaire — [ADR-107]) : […]

Cette fiche a été retouchée en vague 2 pour dire « branche de la vague 2, en attente », puis en vague 3 pour dire « fusionnée le 2026-10-03 ». Elle porte deux chiffres à la main.

**Au nouveau format** — les symboles et les tests ci-dessous existent, vérifiés le 06/10 :

```markdown
<!-- fiche:v2 -->
### 3.7. 🏕️ Feu de camp

> Une seule action par visite, parmi trois : se reposer, affûter une rune, oublier une carte. Une fois l'action faite, toute sortie résout le nœud.

**Ce que voit le joueur** — trois boutons. *Affûter* reste inactif, avec son motif, quand aucune rune du deck ne peut monter. Sinon, il ouvre la sélection : une carte sans rune affûtable y est grisée. Un dialogue liste ensuite les runes de la carte, chacune avec ce que son niveau suivant ajoute et son prix. Annuler ramène à la sélection.

| Invariant | Gardé par |
|:---|:---|
| Les trois actions sont proposées | `test/widget/rest_screen_test.dart` › « RestScreen renders the three action buttons » |
| *Affûter* est inactif, avec son motif, sans rune qui puisse monter | `test/widget/rest_screen_test.dart` › « AFFUTER est inactive, avec son motif, quand aucune rune du… » |
| Affûter monte une rune d'un niveau, une seule | `test/widget/rest_screen_test.dart` › « Affuter monte une rune d un niveau, notifie, et clot les… » |
| Une carte sans rune affûtable est refusée, avec son motif | `test/widget/rest_card_selection_screen_test.dart` › « une carte sans rune est grisee et refusee, avec son motif » |
| Le prix d'un niveau croît avec le niveau | `test/unit/forge_rune_rules_test.dart` › « sharpenCost : 50 or par niveau porte (D20, D63) » |
| Le repos soigne une part fixe des PV maximum | `test/widget/rest_screen_test.dart` › « Tapping Heal restores 30% of max HP… » |

| Porteur | Où |
|:---|:---|
| Le prix de l'affûtage | `lib/game/services/forge_rune_rules.dart` › `ForgeRuneRules.sharpenCost` |
| L'affûtage payé | `lib/game/controllers/run_controller.dart` › `RunController.sharpenRune`, qui délègue à `GoldManager.sharpenRune` |
| L'écran, et la règle « une action par visite » | `lib/ui/screens/rest_screen.dart` › `RestScreen` |

**Valeurs**

<!-- genere:debut vue=constante source=lib/game/services/forge_rune_rules.dart nom=sharpenBaseCost libelle="Prix d'un niveau d'affûtage, par niveau porté (or)" -->
| Valeur | Porteur |
|:---|:---|
| Prix d'un niveau d'affûtage, par niveau porté (or) : **50** | `ForgeRuneRules.sharpenBaseCost` |
<!-- genere:fin -->

**Pourquoi** — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md) (l'affûtage remplace la forge) · [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md) (les autres sources d'affûtage)

**Constats** — le soin du repos (30 % des PV maximum) n'a pas de porteur : il est écrit en dur deux fois dans `lib/ui/screens/rest_screen.dart`, et la même valeur revient une troisième fois, pour le soin vendu à la boutique, dans `lib/ui/screens/shop_screen.dart`. C'est de la logique de jeu dans la couche UI, ce que `CLAUDE.md` interdit. À router vers la ROADMAP.
```

Ce que l'exemple montre :
- **Le changement d'E3** (« le feu n'est plus la seule source d'affûtage ») ne se recopie plus ici. Il vit dans la fiche des sources d'affûtage et dans ADR-107 ; celle-ci y renvoie par « Pourquoi ».
- **La date de fusion n'y figure plus** : git la connaît.
- **En pointant, la fiche trouve un vrai défaut** que la paraphrase cachait : le 30 % sans porteur, écrit en dur dans l'interface, et répété pour la boutique.

---

## 4. Les blocs générés

### 4.1. Le principe

Un bloc s'ouvre par `<!-- genere:debut vue=<nom> … -->` et se ferme par `<!-- genere:fin -->`. Un script réécrit son contenu ; personne ne l'édite à la main, pas même le skill. Le script a un mode `--check` qui sort en 1 si un bloc a dérivé, comme `tool/sync_assets.dart --check`. Ce mode peut aller dans la CI (audit, R19).

Le script ne sait produire que deux sortes de vues, pour rester petit :
- **une table depuis un dossier de données** (`assets/data/<dossier>/*.json`), avec les colonnes que la vue définit ;
- **une constante littérale du code**, lue dans `static const <nom> = <valeur>;` d'un fichier Dart, par une expression régulière, sans importer le code.

Une valeur que ni l'une ni l'autre ne sait lire — un `0.3` en dur dans un écran — n'a pas de porteur. Elle va aux constats, pas dans un bloc.

### 4.2. Exemple : la table des runes, générée depuis `assets/data/forge_upgrades/`

Ce bloc irait dans `_rules/03-8`. La table ci-dessous a été produite le 06/10 depuis les onze fichiers du dossier. C'est un prototype de la vue, écrit en Python dans le scratchpad, parce que ce conteneur n'a pas le SDK Dart ; le vrai script serait en Dart, comme le reste de `tool/`.

```markdown
<!-- genere:debut vue=runes source=assets/data/forge_upgrades -->
| Rune | id | Rang de fusion minimal | Types de carte | Effets requis | Niveau maximal | Poids |
|:---|:---|---:|:---|:---|---:|---:|
| Brûlant | `burning` | 1 | attack | aucun | — | 80 |
| Allégé | `cheap` | 1 | tous | aucun | 1 | 50 |
| Économe | `eco` | 2 | attack, skill, power | aucun | 1 | 40 |
| Persistant | `enduring` | 1 | attack, skill, power | aucun | 1 | 30 |
| Congelant | `freezing` | 1 | attack | aucun | 1 | 80 |
| Endurci | `hardened` | 1 | tous | armor | — | 100 |
| Précis | `precise` | 1 | tous | damage | 10 | 50 |
| Véloce | `quick` | 2 | attack, skill, power | aucun | 1 | 60 |
| Tranchant | `sharp` | 1 | tous | damage | — | 100 |
| Surchargé | `shocking` | 1 | attack | aucun | — | 80 |
| Spectral | `spectral` | 1 | tous | damage | — | 50 |
<!-- genere:fin -->
```

Lu dans le code pour que la vue dise vrai :
- une clé `eligibleCardTypes` absente signifie « tous les types » ;
- `maxLevel: null` signifie « sans plafond » (`ForgeUpgradeData`, D27) ;
- les exclusions (`excludesEffects`, `excludesRunes`, `requiresExhaust`) ne sont pas dans la table.

La fiche nomme donc le prédicat complet comme porteur : `lib/game/services/forge_rune_rules.dart` › `ForgeRuneRules.isEligible`. Une vue montre des valeurs ; elle ne remplace pas la règle.

### 4.3. Le script

`tool/vault_valeurs.dart` :
- en Dart pur (`dart:io`, `dart:convert`), propre à `dart analyze`, testé par `test/unit/vault_valeurs_test.dart` comme `sync_assets` l'est ;
- `dart run tool/vault_valeurs.dart` réécrit tous les blocs de `_rules/` et `_patterns/` ;
- `--check` ne réécrit rien et sort en 1 si un bloc diffère ;
- une vue est une fonction nommée du script (`runes`, `constante`, …). En ajouter une, c'est une tâche de plan, avec son test.

La section « Tooling » de `CLAUDE.md` le nomme, à côté de `sync_assets.dart` et du script de simulation.

---

## 5. Le skill dans une vague

**Ce que l'orchestrateur lui donne** (gabarit §4.5 du fichier d'orchestration, à retoucher) :
- la branche et le numéro de la vague ;
- la liste « Pour `memory-bank-sync` » de la fiche de vague : ADR à ouvrir ou à amender, fiches à corriger — un minimum ;
- la base et le total de tests.

**Ce que le skill fait, dans l'ordre** :
1. `git log <last-sync>..HEAD` (G7).
2. Il calcule les fiches candidates (G11) et y ajoute la liste de l'orchestrateur.
3. Il ouvre l'ADR de la vague. Son Statut se date une fois : « ✅ Accepté — <date>, livré par la vague N du chantier `<chantier>` ».
4. Pour chaque fiche candidate : il la migre au format v2 si elle ne l'est pas, puis met à jour la règle, les invariants et les porteurs.
5. Il lance `dart run tool/vault_valeurs.dart`.
6. Il met à jour `activeContext.md` et `progress.md`. **Ce sont les deux seuls fichiers qui disent « livrée sur la branche `<branche>`, en attente du test, de la PR, de la fusion et du tag »**, et qui notent la clôture de la vague précédente.
7. Il exécute la checklist.

**Ce qu'il rend** :
- les fichiers écrits ;
- les fiches candidates examinées et laissées telles quelles, avec leur raison ;
- les fiches migrées en v2 dans la passe, et le nombre de fiches encore en v1 ;
- le résultat du générateur ;
- les constats relevés.

---

## 6. Le `SKILL.md` proposé

Le texte complet, à substituer au fichier actuel le jour de l'adoption. Les garanties 1 à 9 reprennent celles d'aujourd'hui ; ce qui change y est marqué **(v2)**.

~~~~markdown
---
name: memory-bank-sync
description: Use after any implementation, merge, or design decision lands in Hero's Draft — updates .obsidian_vault/_memory_bank/ (three capped indexes), the addressable sheets under _adr/, _rules/ and _patterns/, and docs/ROADMAP.md. Sheets point to the code, data and tests that carry each rule instead of restating them, receive their values from generated blocks, and never record branch or merge state. Verifies every metric against the code before writing, scopes each pass from the git diff, enforces line caps, archives instead of appending, and keeps ADR numbering collision-free.
---

# Synchronisation du memory bank

Tu maintiens la documentation développeur de **Hero's Draft**. Tu traduis ce qui a été livré en connaissance produit structurée, et tu empêches la dérive entre la documentation et le code. **(v2)** Le vault décrit ce qui est vrai là où il est écrit, et renvoie au code, à la donnée et aux tests pour le détail : il ne les recopie pas.

Écris en **français**. Le frontmatter `description` reste en anglais.

## Ce que tu écris

| Fichier | Plafond | Contenu |
|:---|---:|:---|
| `.obsidian_vault/_memory_bank/activeContext.md` | 240 l. | Focus courant, 3 dernières livraisons, prochaine étape — **et l'état des livraisons en cours** |
| `.obsidian_vault/_memory_bank/progress.md` | 600 l. | État du construit, métriques datées, 10 dernières releases |
| `.obsidian_vault/_memory_bank/productContext.md` | 240 l. | **Index** des fiches de règles métier (tableau seul) |
| `.obsidian_vault/_memory_bank/systemPatterns.md` | 300 l. | **Index** des fiches d'architecture (tableau seul) |
| `.obsidian_vault/_memory_bank/decisionLog.md` | 500 l. | **Index** des ADR (tableau seul) |
| `.obsidian_vault/_adr/ADR-0XX-<slug>.md` | 300 l. | Une fiche par décision |
| `.obsidian_vault/_rules/<slug>.md` | 300 l. | Une fiche par système de jeu, au format de la Garantie 10 |
| `.obsidian_vault/_patterns/<slug>.md` | 300 l. | Une fiche par domaine d'architecture, au format de la Garantie 10 |
| `docs/ROADMAP.md` | — | Le reste à faire, priorisé |

**Un seul mécanisme, appliqué trois fois : index + fiches adressables.** Les trois index ne contiennent que des tableaux de liens. Le contenu vit dans les fiches, jamais dans l'index.

## Ce que tu ne touches jamais

- `assets/data/patch_notes.json` et `pubspec.yaml` — domaine de `patch-notes-writer`.
- Tout fichier de `lib/`, `test/`, `assets/`.
- `.obsidian_vault/_archive/` — en lecture seule, définitivement.
- **(v2)** L'intérieur d'un bloc `<!-- genere:debut … -->` … `<!-- genere:fin -->` : seul `tool/vault_valeurs.dart` l'écrit (Garantie 12).
- **(v2)** Un ADR ancien dont la validité ne change pas (Garantie 5, point 6).

## Garantie 1 — Vérifier avant d'écrire

> **Aucun chiffre ne peut être écrit s'il ne provient pas d'une commande lancée dans la session en cours.**

| Fait | Commande |
|:---|:---|
| Nombre de tests | `flutter test` → lire le `+N` final |
| Analyse statique | `dart analyze` |
| Fichiers Dart | `find lib -name "*.dart" \| wc -l` |
| Lignes de code | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | `find assets/data -name '*.json' \| wc -l` |
| Versions | lire `pubspec.yaml` et la 1ʳᵉ entrée de `assets/data/patch_notes.json` |
| Ce qui a changé | `git log <last-sync-sha>..HEAD --oneline` |
| **(v2)** Les fiches candidates | la commande de la Garantie 11 |
| **(v2)** Les valeurs d'une fiche | `dart run tool/vault_valeurs.dart` |
| Taille d'un fichier cité comme chantier | `wc -l <fichier>` |

Tout bloc de métriques porte `**Vérifié le YYYY-MM-DD**`.

Ne jamais reprendre un chiffre depuis un document — même depuis ce vault. Les chiffres se re-mesurent.

## Garantie 2 — Plafonds durs

> **Arbitrage du propriétaire, 2026-09-21 : tous les plafonds ont doublé.** `activeContext` 120 → 240, `progress` 300 → 600, `productContext` 120 → 240, `systemPatterns` 150 → 300, `decisionLog` 250 → 500, et chaque fiche de `_adr/`, `_rules/`, `_patterns/` 150 → 300. Ce qui ne change pas : la FIFO à 3 livraisons, les 10 releases de `progress`, et la règle d'archiver plutôt que d'empiler.

En fin de passe, mesurer les index **et** les fiches :

```bash
wc -l .obsidian_vault/_memory_bank/*.md
wc -l .obsidian_vault/_adr/*.md .obsidian_vault/_patterns/*.md .obsidian_vault/_rules/*.md \
  | sort -rn | head -5
```

**(v2)** Les index ne portent pas de colonne « Lignes » : le plafond se mesure en fin de passe, il ne se recopie pas. Une fiche touchée n'oblige plus à réécrire son index.

Un dépassement d'index se corrige en **archivant**, jamais en tronquant ni en condensant. Un dépassement de fiche se corrige en la **redécoupant** (Garantie 8).

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
| **(v2)** *Une valeur de jeu* (taux, coût, plafond, poids) | la donnée sous `assets/data/`, ou la constante du code — une fiche la reçoit d'un bloc généré, ou cite son porteur |
| **(v2)** *L'état d'une livraison* (sur branche, fusionnée, taguée) | git, le journal et `etat.json` du chantier ; `activeContext.md` et `progress.md` pour le vault — jamais une fiche ni un ADR |

**On lie, on ne recopie pas.** Deux formulations du même fait sont deux occasions de diverger.

Le numéro de version n'est **jamais recopié dans le vault** : il appartient à `patch-notes-writer`, qui l'écrit dans ses deux fichiers. Le vault y renvoie.

## Garantie 5 — Protocole ADR

1. Le nouveau numéro est `max(index) + 1`, **lu dans l'index**, jamais deviné.
2. Un fichier par ADR, nommé `ADR-0XX-<slug-kebab>.md`.
3. Structure imposée : `### Statut`, `### Contexte`, `### Décision`, `### Preuves dans le code`, `### Conséquences`.
4. Un ADR publié n'est **jamais** renuméroté ni réécrit. S'il est dépassé, changer son `### Statut` et lier son successeur.
5. Ajouter la ligne correspondante dans l'index `decisionLog.md`, qui reste trié par numéro décroissant.
6. **(v2)** **Un ADR ancien n'est touché que si sa validité change** : amendé, remplacé, rendu caduc — son Statut le dit et lie le successeur. « Complété par » et « note la fusion de » ne s'écrivent pas : Obsidian montre les liens entrants, et `grep -l ADR-0XX .obsidian_vault/_adr` les liste.
7. **(v2)** **Le Statut d'un ADR se date une fois**, à son écriture : « ✅ Accepté — <date>, livré par la vague N du chantier `<chantier>` ». La fusion et le tag ne s'y notent pas : ce sont des faits de git.

## Garantie 6 — Périmètre

| Question | Emplacement |
|:---|:---|
| Ce qui existe | `.obsidian_vault/_memory_bank/` |
| Ce qui reste à faire | `docs/ROADMAP.md` |
| Ce qui est conçu mais pas construit | `docs/superpowers/specs/` et `plans/` — ou le dossier de vague d'un chantier |
| Ce qui est exploré, pas tranché | `docs/possible_upgrades/` |
| Ce qui se déroule par vagues | le fichier d'orchestration du chantier, et son `etat.json` |
| Ce que voit le joueur | `assets/data/patch_notes.json` |

**Devoir explicite** : quand un chantier `P-xx` est livré, le cocher dans `docs/ROADMAP.md` **dans la même passe**.

## Garantie 7 — Ancre de synchronisation

`activeContext.md` commence par :

```
<!-- last-sync: YYYY-MM-DD | commit: <last-sync-sha> -->
```

**Commence toujours ta passe par** `git log <last-sync-sha>..HEAD --oneline`. Ne relis pas le vault entier pour deviner ce qui a changé. Termine toujours ta passe en mettant l'ancre à jour avec le `sha` de `HEAD`.

## Garantie 8 — Protocole des fiches (`_rules/`, `_patterns/`)

1. **Une fiche par système de jeu** sous `_rules/`, **une fiche par domaine d'architecture** sous `_patterns/`. Une règle nouvelle crée ou modifie *une* fiche.
2. **Ne jamais réinjecter le contenu d'une fiche dans son index.**
3. **Toute fiche dépassant 300 lignes est redécoupée au niveau `###`**, et l'index mis à jour dans la même passe. On redécoupe, on ne condense pas.
4. Nommage `<slug-kebab>.md`, préfixé du numéro de section qu'il porte dans l'index, pour que le tri alphabétique soit le tri de l'index.
5. L'index et le répertoire restent en **bijection** : aucune fiche sans ligne d'index, aucune ligne d'index sans fiche. Vérifier, ne pas supposer.
6. **(v2)** Chaque fiche suit le format de la Garantie 10 et commence par `<!-- fiche:v2 -->`. Une fiche encore à l'ancien format se migre la première fois qu'une passe la touche (Garantie 14).

## Garantie 9 — Propriété du numéro de version

**Tu enregistres, tu ne décides pas.** Le numéro de version appartient au skill `patch-notes-writer`.

- Le schéma interne **`v3.x` est gelé**. Les lignes existantes de l'historique des releases de `progress.md` le conservent ; **aucune entrée nouvelle ne l'emploie**.
- Toute ligne ajoutée à l'historique des releases est **clé sur la version publiée dans `assets/data/patch_notes.json`**, lue et non devinée.
- Si aucun patch note n'a encore été rédigé pour la livraison que tu documentes, **n'invente pas de numéro** : décris la livraison sans clé de version et signale-le dans ton rapport.

## Garantie 10 — (v2) Une fiche pointe, elle ne recopie pas

Une fiche dit, dans cet ordre :

1. **La règle**, en une ou deux phrases, telle qu'elle est vraie sur la branche où la fiche est écrite.
2. **Ce que voit le joueur**, avec les mots du jeu.
3. **Les invariants**, en table : chacun avec le test qui le garde, `test/<chemin>_test.dart` › « <nom du test> ». Un invariant sans test s'écrit « aucun test » : c'est un constat.
4. **Les porteurs**, en table : le symbole (`lib/<chemin>.dart` › `Classe.membre`), le dossier de données, l'écran. **Jamais un numéro de ligne.**
5. **Les valeurs**, dans un bloc généré (Garantie 12). Une valeur que le générateur ne sait pas produire se cite par son porteur, pas par son chiffre.
6. **Pourquoi** : les liens vers les ADR.
7. **Constats** : ce que la fiche a relevé en pointant — une valeur sans porteur unique, une règle dans la mauvaise couche, un invariant sans test. Un constat se signale dans ton rapport pour la ROADMAP ; tu ne corriges rien hors du vault.

Ce qui n'entre pas dans une fiche : une paraphrase du code ; un état de branche (Garantie 13) ; une valeur recopiée à la main ; l'historique de la règle, qui vit dans les ADR.

## Garantie 11 — (v2) Le périmètre se calcule

Les fiches candidates d'une passe sont celles dont un porteur ou un test cité a changé depuis l'ancre :

```bash
git diff --name-only <last-sync-sha>..HEAD -- lib assets/data test \
  | while read -r chemin; do
      grep -lF "$chemin" .obsidian_vault/_rules/*.md .obsidian_vault/_patterns/*.md
    done | sort -u
```

S'y ajoutent les fiches que l'orchestrateur nomme. **Cette liste est un minimum.** Tu lis aussi le diff de `lib/` pour y trouver un système neuf ou supprimé, qui crée ou retire une fiche, et une règle qui change dans un fichier que les fiches ne citent pas encore. Tant que des fiches restent à l'ancien format, qui cite peu de chemins, ce calcul en rate beaucoup : la lecture du diff reste alors la vraie source du périmètre.

Une fiche candidate que tu laisses telle quelle figure dans ton rapport, avec sa raison. Une fiche qui n'est pas candidate n'est pas relue.

## Garantie 12 — (v2) Les blocs générés

- Un bloc s'ouvre par `<!-- genere:debut vue=<nom> … -->` et se ferme par `<!-- genere:fin -->`. Son contenu appartient à `tool/vault_valeurs.dart`.
- **Tu lances `dart run tool/vault_valeurs.dart`** après avoir écrit les fiches, et tu commites ce qu'il a réécrit dans la même passe.
- Pour qu'une fiche reçoive une valeur, tu ajoutes un bloc, avec une vue que le script connaît. Une vue qui n'existe pas encore ne s'invente pas : tu cites le porteur, et tu signales la vue manquante dans ton rapport.
- `dart run tool/vault_valeurs.dart --check` doit sortir en 0 en fin de passe.

## Garantie 13 — (v2) Ce qui est vrai là où c'est écrit

**Une fiche et un ADR décrivent ce qui est vrai sur la branche où ils sont écrits.** Écrits sur la branche d'une vague, ils sont en attente par construction ; la fusion les rend vrais sur `main` sans qu'on les retouche.

- **Jamais dans une fiche ni dans un ADR** : « sur la branche de la vague N », « en attente du propriétaire », « fusionnée le », « taguée ».
- **L'état d'une livraison s'écrit dans `activeContext.md` et `progress.md` seulement.** Pour une vague livrée sur sa branche : « livrée sur la branche `<branche>` — vague N du chantier `<chantier>`, en attente du test, de la PR, de la fusion et du tag du propriétaire ». La clôture de la vague précédente, que la porte d'entrée a constatée, s'y note aussi, et nulle part ailleurs.

## Garantie 14 — (v2) Migrer en touchant

- Une fiche sans la ligne `<!-- fiche:v2 -->` est à l'ancien format.
- **Tu la migres la première fois qu'une passe la touche**, et seulement alors. Une passe ne migre pas de fiche qu'elle n'avait pas à toucher.
- Migrer, c'est réécrire la fiche au format de la Garantie 10, sans perdre une règle ni un invariant. Les valeurs recopiées partent dans un bloc généré, ou cèdent la place à leur porteur. Les mentions d'état partent (Garantie 13).
- Ton rapport donne le nombre de fiches encore à l'ancien format : `grep -L 'fiche:v2' .obsidian_vault/_rules/*.md .obsidian_vault/_patterns/*.md | wc -l`.

## Checklist de fin de passe

À **exécuter**, pas à cocher de mémoire :

- [ ] `wc -l .obsidian_vault/_memory_bank/*.md` → tous sous leur plafond
- [ ] `wc -l .obsidian_vault/_adr/*.md .obsidian_vault/_patterns/*.md .obsidian_vault/_rules/*.md | sort -rn | head -5` → la plus grande fiche sous 300 l.
- [ ] Bijection index ↔ fiches pour les trois paires (`decisionLog`/`_adr`, `productContext`/`_rules`, `systemPatterns`/`_patterns`)
- [ ] Chaque chemin cité existe : extraire les chemins entre backticks *et* les cibles de liens markdown `](...)`, et les tester avec `test -e`. Les exceptions connues de la version précédente du skill restent valables, ainsi que l'avertissement : un nom de branche entre backticks n'est pas un chemin.
- [ ] **(v2)** Chaque symbole cité comme porteur existe : `grep -n "<membre>" <chemin>` le trouve
- [ ] **(v2)** Chaque test cité dans « Gardé par » existe : `grep -F "<nom du test>" <chemin>` le trouve
- [ ] **(v2)** `dart run tool/vault_valeurs.dart --check` sort en 0
- [ ] **(v2)** Aucune mention d'état dans les fiches touchées : `grep -nE "sur la branche|en attente du propriétaire|fusionnée? (dans|le)" <fiches touchées>` ne rend rien
- [ ] **(v2)** Aucun ADR ancien touché sans changement de validité
- [ ] **(v2)** Le nombre de fiches encore à l'ancien format, dans le rapport
- [ ] `pubspec.yaml` et la 1ʳᵉ entrée de `patch_notes.json` annoncent la même version — et le vault ne la recopie pas
- [ ] Index ADR : numéros uniques et triés
- [ ] Aucune métrique sans `**Vérifié le ...**`
- [ ] Ancre `last-sync` à jour
- [ ] Chantiers livrés cochés dans `docs/ROADMAP.md`

## Style

Markdown structuré et sobre. Les panneaux `> [!IMPORTANT]` et `> [!NOTE]` sont réservés aux invariants de gameplay et aux patterns d'architecture, pas au commentaire ordinaire. **(v2)** Les tables d'invariants et de porteurs sont la forme normale d'une fiche ; la prose sert à « Ce que voit le joueur » et aux constats.
~~~~

**Note sur la checklist** : la liste complète des exceptions de chemins de la version actuelle (ADR-001, ADR-005, ADR-007, ADR-069, ADR-080, les catalogues abolis par P-48, la chaîne de compétences supprimée par P-40, le service de tutoriel supprimé) est à recopier telle quelle à l'adoption. Elle n'est pas reproduite ici pour ne pas créer une seconde copie qui divergerait.

---

## 7. La migration

| Étape | Quoi | Quand | Coût |
|:---:|:---|:---|:---|
| **1** | **C1 et C5, sans outil.** Plus d'état de branche dans les fiches neuves ou retouchées ; plus de « complété par » dans un ADR ancien ; la colonne « Lignes » retirée des deux index. Un ADR précise ADR-102 D8 : l'état d'une livraison ne s'écrit que dans `activeContext.md` et `progress.md`. Le gabarit §4.5 du fichier d'orchestration suit | Dès la vague 4, si tu le décides — rien à construire | Une passe sur les deux index |
| **2** | **Le générateur** : `tool/vault_valeurs.dart`, ses deux premières vues (`runes`, `constante`), son test, son `--check` (en CI si R19 est retenu) ; la section « Tooling » de `CLAUDE.md` | Une tâche de plan d'une vague, ou une petite vague d'outillage | Un script court, un test |
| **3** | **Le nouveau `SKILL.md`** (§6) | Entre deux vagues, la précédente fusionnée — on ne change pas de skill au milieu d'une vague | Le remplacement du fichier |
| **4** | **Migrer en touchant** : chaque passe migre les fiches qu'elle touche, et compte celles qui restent | À chaque vague, ensuite | Rien de plus que la passe |
| **5** | **Le nettoyage des mentions d'état** dans les 36 fiches qui en portent, en une passe mécanique. Les ADR anciens gardent les leurs : ce sont des textes historiques (Garantie 3) | À la session de clôture du chantier, quand toutes les vagues sont fusionnées | Une passe |

**Ce qu'il faut mesurer pour savoir si ça marche**, vague après vague : les fichiers touchés par la passe (33, 46, 58 aujourd'hui), les ADR anciens retouchés (3, 9, 14), les jetons de la fin de vague, et le nombre de fiches encore à l'ancien format.

## 8. Les risques

- **Des fiches plus sèches à lire dans Obsidian.** La partie « Ce que voit le joueur » reste en prose, et les blocs générés gardent les chiffres visibles. Si le vault devient illisible pour toi, c'est un échec de la proposition, quoi que disent les compteurs.
- **Le générateur est du code à maintenir.** Deux vues pour commencer ; une vue de plus seulement quand une fiche en a besoin.
- **Le périmètre calculé rate ce qui change sans toucher un porteur cité.** Rejoué sur la vague 3 avec les fiches d'aujourd'hui, il en trouve 11 sur 36. Il ne vaut qu'à mesure que les fiches citent leurs porteurs par chemin. La liste de l'orchestrateur et la lecture du diff de `lib/` restent donc obligatoires (G11) : le périmètre calculé est un plancher, pas un plafond.
- **Un renommage de test casse une fiche.** C'est voulu : la checklist le voit (« chaque test cité existe »). Sans ce lien, le même renommage passerait inaperçu.
