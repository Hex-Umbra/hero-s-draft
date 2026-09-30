# Orchestration — le chantier « Économie unifiée et catalogue », de `0.5.2` à `0.6.0`, vague par vague

**Date** : 01/10/2026 — réécrit le même jour pour la méthode par vagues (brainstorm, D69).
**Statut** : **ce fichier fait foi pour le déroulé du chantier** — l'ordre des vagues, ce que chacune livre, sa version, son état. **Les décisions de conception ne sont pas ici** : leur source de vérité est le brainstorm v3, [`22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md`](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 (D1 à D69). Ce fichier les cite, il ne les recopie pas ; en cas d'écart, le brainstorm a raison sur le *quoi*, ce fichier sur le *comment* et le *quand*.
**Périmètre** : ce qui a été brainstormé — **P-43** « Économie unifiée » (lots E0 à E4), **P-42** « Catalogue par lots de passif » (tranches 1 à 3) et **P-44 lot 1**. Hors périmètre, après `0.6.0` : P-44 lots 2 à 4 (derrière P-05) et P-16 (calibration).
**Sources** : le brainstorm v3 ; sa revue, [`29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md`](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md) ; le rapport de simulation, [`30-09-2026_simulation_D26_economie_Fable5.md`](30-09-2026_simulation_D26_economie_Fable5.md) ; `docs/ROADMAP.md` §4.
**Vérifié contre** : `main` à `b4f0884` — code identique à `3b8c66f`, 1187 tests.

---

## 0. Pour la session qui ouvre ce fichier

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.**

1. Lis `CLAUDE.md`, puis ce fichier en entier, puis le brainstorm v3 — au moins son en-tête, §1, §3 et §11.
2. **Trouve ta vague** : dans le journal (§2), la première dont l'état n'est pas « close ». Si elle est « en cours », reprends-la à l'étape que le journal indique.
3. **Passe la porte d'entrée** (§3.1). Si elle ne passe pas, arrête-toi et dis pourquoi : ne commence jamais une vague sur une base que tu n'as pas vérifiée.
4. **Déroule le cycle** (§3), dans l'ordre, en **déléguant** la rédaction, la vérification et l'implémentation à des agents (§4). Tu gardes le fil, pas le détail.
5. **Arbitre seul** les questions que la fiche de ta vague (§8) laisse ouvertes, par l'arbre de décision de §5. Tu ne demandes rien au propriétaire en cours de vague, sauf dans les cas d'arrêt de §6.
6. **Arrête-toi à la porte de sortie** (§3.9). Tu ne pousses rien, tu n'ouvres pas de PR, tu ne poses pas de tag, tu ne fusionnes pas : c'est le propriétaire qui teste, ouvre la PR, pose le tag et fusionne.

**Le prompt qui lance une vague** — le même pour toutes, à coller dans une session neuve :

````
Tu travailles dans le dépôt Hero's Draft (Flutter, Flame, Riverpod, 100 % data-driven). Lis `CLAUDE.md` d'abord, puis `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` en entier : ce fichier fait foi. Tu es l'orchestrateur de la prochaine vague de son journal (§2). Déroule son cycle (§3) en orchestrant des sous-agents (§4) — la délégation est demandée, y compris par un workflow si tu en as l'outil —, arbitre seul selon §5, respecte les garde-fous de §6 et arrête-toi à la porte de sortie. Réponds et écris en français.
````

---

## 1. Les vagues et les versions

Le jeu est en `0.5.2`. Chaque vague livre une version ; `0.6.0` clôt le chantier.

| Vague | Version | Lots | Ce que le joueur voit | Branche | Poids |
|:---:|:---|:---|:---|:---|:---|
| **0** | — | Méthode et ROADMAP | Rien | `docs/vague-0-roadmap-et-methode` | Documentation seule |
| **1** | **`0.5.3`** | **E0** et **E1** | Les garde-fous de Puissance (le Berserker convertit moitié moins d'armure) ; `sharp` change de formule ; la boucle ne change pas | `feat/v0.5.3-p43-e0-e1` | Deux lots, une spec et un plan chacun |
| **2** | **`0.5.4`** | **E2** | Fusion = forge : une rune à chaque fusion, affûtage au feu, Puits d'échange, copie du deck en boutique | `feat/v0.5.4-p43-e2-fusion-forge` | Lourd : une spec, deux parties |
| **3** | **`0.5.5`** | **E3** | Une carte après chaque combat, deux niveaux par acte, sources d'affûtage, événement de relique | `feat/v0.5.5-p43-e3-trouvaille` | Lourd : une spec, deux parties |
| **4** | **`0.5.6`** | **E4** | Deux compétences de classe hors du deck, dès le premier tour, à recharge | `feat/v0.5.6-p43-e4-signatures` | Lourd : une spec, deux parties |
| **5** | **`0.5.7`** | **Tranche 1** et **P-44 lot 1** | Trois lots de cartes (Rempart, Sang, Arcaniste), les mécanismes de profondeur, les évolutions de signature | `feat/v0.5.7-p42-tranche-1-p44-lot-1` | Le plus lourd : une spec, trois parties |
| **6** | **`0.5.8`** | **Tranche 2** | Trois lots de plus (Croisé, Vampire, Voile), Canalisation en banque de mana | `feat/v0.5.8-p42-tranche-2` | Moyen |
| **7** | **`0.6.0`** | **Tranche 3** | Les trois derniers lots (Sanctifié, Carnage, Marque) : neuf passifs jouables, chantier clos | `feat/v0.6.0-p42-tranche-3` | Moyen, plus la clôture |

**Pourquoi cet ordre est forcé.** E1 avant E2 : la fusion propose une rune que seul l'applicateur d'E1 sait appliquer. E2 avant E3 : les cartes trouvées ont besoin de leur puits, la fusion (D56). E3 avant E4 : c'est D31, dans E3, qui rend les signatures-cartes invisibles (D53). E4 avant la tranche 1 : l'écran d'évolution écrit sur `SignatureInstance`, qu'E4 crée. P-44 lot 1 avec la tranche 1 : sans `costs.hp` ni `scaleWith`, le lot Sang tombe à deux cartes (brainstorm §11, ligne P-44). Les tranches 2 et 3 s'écrivent sur les mécanismes que la tranche 1 a livrés.

**Dans une vague, tout se déroule en série.** Un lot après l'autre, une partie après l'autre : la spec ou le plan suivant s'écrit sur le code que le précédent a laissé sur la branche, jamais sur une prévision.

---

## 2. Le journal d'avancement

Chaque vague le met à jour elle-même, à chaque étape franchie. États : *à faire* · *en cours* (avec l'étape) · *livrée sur branche* (en attente du propriétaire) · *close* (fusionnée, taguée, CI/CD verte).

| Vague | Version | État | Étape | Branche | Spec(s) | Plan(s) | Tests | Livrée le | Close le |
|:---:|:---|:---|:---|:---|:---|:---|---:|:---|:---|
| 0 | — | **close** | — | `main`, par exception | — | — | 1187 | 01/10 | 01/10 |
| 1 | `0.5.3` | à faire | — | — | — | — | — | — | — |
| 2 | `0.5.4` | à faire | — | — | — | — | — | — | — |
| 3 | `0.5.5` | à faire | — | — | — | — | — | — | — |
| 4 | `0.5.6` | à faire | — | — | — | — | — | — | — |
| 5 | `0.5.7` | à faire | — | — | — | — | — | — | — |
| 6 | `0.5.8` | à faire | — | — | — | — | — | — | — |
| 7 | `0.6.0` | à faire | — | — | — | — | — | — | — |

**Préalable fait** : le dossier du chantier — brainstorm, revue, simulation et son script, ce fichier — est commité et poussé sur `main` (01/10, `3cd743f`..`b4f0884`).

**La vague 0 est faite** (01/10) : dans la session d'orchestration, directement sur `main`, à la demande du propriétaire — sans branche, par exception à §3.2. La ROADMAP est redécoupée, la méthode est consignée dans ADR-102, les trois retouches au brainstorm sont appliquées. **La prochaine vague est la vague 1** ; sa porte d'entrée n'attend aucun tag.

---

## 3. Le cycle d'une vague

Neuf étapes. La vague 0 n'a ni spec, ni plan, ni code, ni version : elle ne fait que 3.1, 3.2, sa fiche (§8.0), 3.8 et 3.9.

### 3.1. La porte d'entrée

À vérifier par commande, jamais de mémoire. Un seul échec arrête la session.

| Vérification | Commande | Attendu |
|:---|:---|:---|
| L'arbre est propre, sur `main`, à jour | `git status -sb` · `git fetch` · `git rev-list --left-right --count main...origin/main` | Rien à commiter, `0 0` |
| La vague précédente est fusionnée | `git log --oneline -15 main` ; `git branch --merged main` | Ses commits sont dans `main` |
| Sa version est taguée *(à partir de la vague 2)* | `git tag -l "v<version précédente>"` | Le tag existe |
| Sa CI/CD est entièrement verte | `gh run list --branch main --limit 5` · `gh run list --workflow release.yml --limit 3` · `gh release view v<version>` | Tous les jobs verts, la release existe. **Si `gh` ne joint pas l'API** : demande au propriétaire de le confirmer, et note dans le journal que c'est lui qui l'a dit |
| Les trois porteurs de version concordent | `pubspec.yaml` (`version:`), la première entrée de `assets/data/patch_notes.json`, l'entrée `current` de `site/_site/versions.json` | Tous trois à la version précédente |
| `main` est sain | `dart analyze` · `flutter test` | `No issues found!` · tout vert — **le total est la base de tests de la vague**, à écrire au journal |

Puis passe la vague précédente à « close » dans le journal, avec la date.

### 3.2. La branche

Crée la branche de la vague (§1) depuis `main`, dans le checkout principal — jamais de worktree. **Tous les commits de la vague vont sur cette branche**, spec et plan compris : `main` ne bouge que par la fusion du propriétaire. Passe la vague à « en cours ».

### 3.3. La spec — écrire, vérifier, corriger, revérifier

Pour chaque lot de la vague, dans l'ordre :

1. Un **agent rédacteur** écrit la spec dans `docs/superpowers/specs/<date>-<id>-<sujet>-design.md`, sur le modèle de `2026-09-16-p49-passifs-partages-design.md`, à partir de la fiche de la vague (§8) et du gabarit de §4.1. Il ne code rien.
2. Un **agent vérificateur**, neuf, qui n'a pas écrit la spec, la contrôle (gabarit §4.2) et rend une table de constats, chacun avec sa gravité : *bloquant*, *moyen*, *mineur*, *rédaction*.
3. S'il y a un constat bloquant ou moyen : renvoie les constats au rédacteur, qui corrige ; puis un **nouveau** vérificateur revérifie. **Boucle jusqu'à zéro constat bloquant ou moyen.** Au-delà de trois tours sans convergence, arrête la vague (§6).
4. Commite la spec sur la branche. Note-la au journal.

Une spec de lot lourd **propose son découpage en parties** et l'invariant qui justifie l'ordre ; la fiche de la vague en donne une proposition.

### 3.4. Le plan — écrire, vérifier, corriger, revérifier

Pour chaque lot, et pour chaque partie d'un lot lourd — **le plan de la partie 2 s'écrit après l'implémentation de la partie 1** :

1. Un **agent rédacteur** écrit le plan avec `superpowers:writing-plans`, dans `docs/superpowers/plans/<date>-<id>-<sujet>.md`, sur le modèle de `2026-09-16-p49-passifs-partages.md` (gabarit §4.3). Le plan ne crée pas de branche : celle de la vague existe.
2. Un **agent vérificateur** neuf le passe au crible contre la spec et contre le code de la branche (gabarit §4.4).
3. Même boucle qu'en 3.3, même limite de trois tours.
4. Commite le plan. Note-le au journal.

### 3.5. L'implémentation — par délégation

Exécute chaque plan avec `superpowers:subagent-driven-development` : un agent implémenteur neuf par tâche, une revue après chacune, une revue d'ensemble à la fin. Sur la branche de la vague. Contraintes, à redire à chaque agent :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ; ne jamais commiter les registrants générés (`macos/Flutter/GeneratedPluginRegistrant.swift`, `linux/flutter/`, `windows/flutter/`) ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

### 3.6. La simulation, quand la fiche la demande

`dart run tool/simulations/d26_economy_sim.dart --out <fichier>` — 8 à 10 minutes, en arrière-plan. Le script lit `assets/data/` : la vague qui change un schéma ou un dossier qu'il parse le réaligne dans son plan, puis relance (§7.3). **À valeurs inchangées, les chiffres de D56 à D63 et D67 doivent se retrouver** : un écart arrête la vague (§6). Le script reste `dart analyze` propre.

### 3.7. Les deux skills du projet

Dans cet ordre, une fois le code terminé et vert, chacun délégué à un agent qui invoque le skill :

1. **`patch-notes-writer`**, avec **la version de la vague** (§1), imposée : il préfixe l'entrée dans `assets/data/patch_notes.json`, aligne `pubspec.yaml` et `site/_site/versions.json`, rafraîchit les liens de repli et le libellé de version de `site/index.html` et `site/versions.html`. Vérifie ensuite que les trois porteurs de version concordent, et que `grep -rn '<version précédente>' site/*.html` ne rend rien.
2. **`memory-bank-sync`** : clore le ou les lots dans `docs/ROADMAP.md`, mettre à jour `activeContext.md` et `progress.md` avec des chiffres re-mesurés, ouvrir les ADR et corriger les fiches `_rules` et `_patterns` que la fiche de la vague nomme. **La livraison se note « livrée sur la branche `<branche>`, version `<v>`, en attente du test, de la PR, du tag et de la fusion du propriétaire »** — jamais « fusionnée » ni « publiée », ce n'est pas encore vrai. Il note aussi la clôture de la vague précédente, que la porte d'entrée vient de constater.

Commite les deux sur la branche.

### 3.8. Le journal et le compte rendu

Passe la vague à « livrée sur branche » dans le journal (§2), avec la date et le total de tests ; commite. Puis rends au propriétaire un compte rendu qui tient seul :

- la branche, la version, le nombre de commits, le total de tests, `dart analyze` ;
- **la table des arbitrages** : chaque question tranchée, ses options, le choix et son motif (§5) ;
- **le cahier de test manuel** : ce qu'il faut jouer pour voir chaque changement, classe et passif compris, et ce qui doit rester inchangé ;
- le résultat de la simulation si elle a tourné ;
- ce qui a été trouvé périmé dans le brainstorm en le re-mesurant, et ce qui mérite d'entrer dans la file.

### 3.9. La porte de sortie

**Arrête-toi.** La suite est au propriétaire, dans cet ordre : il teste à la main, ouvre la PR, pose le tag `v<version>`, fusionne dans `main`, et la CI/CD tourne. La vague suivante ne s'ouvre que lorsque sa porte d'entrée constate tout cela.

Si le test du propriétaire fait remonter un défaut, il rouvre une session sur la même branche : la vague reste « livrée sur branche » jusqu'à la fusion.

---

## 4. Déléguer — les agents et leurs gabarits

**Règles.** Un agent part d'un contexte neuf : donne-lui tout ce qu'il lui faut, par chemin de fichier, et rien de ton historique. **Le vérificateur n'est jamais le rédacteur.** Un vérificateur prouve chaque constat par une commande ou une citation ; un constat sans preuve ne compte pas. Tu ne gardes de chaque agent que sa conclusion : le chemin du document, la table de constats, le total de tests. Pour l'équilibrage des cartes (vagues 5 à 7), l'agent rédacteur prend le rôle décrit dans `.agents/skills/game_designer.md`.

### 4.1. Rédacteur de spec

````
Tu écris une spec de conception pour le dépôt Hero's Draft. Lis `CLAUDE.md` d'abord. Écris en français.

Produit : `docs/superpowers/specs/<date>-<id>-<sujet>-design.md`, sur le modèle de `docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md` — décisions, périmètre, données, moteur, textes joueur, éditeur, sauvegarde, tests, documentation et livraison, alternatives écartées. Aucun code, aucune donnée modifiée.

Le lot : <lot, version, une phrase>.
Les décisions acquises qu'il livre : <liste D> — leur texte exact est dans `docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md` §1, source de vérité. Tu ne les rediscutes pas et tu n'en amendes aucune.
À lire en entier avant d'écrire : <la liste « À lire » de la fiche>.
État mesuré le 30/09, à revérifier par commande sur la branche courante : <la liste « État mesuré » de la fiche>. Toute référence `fichier:ligne` que tu écris, tu l'as lue toi-même aujourd'hui.
Ce que la spec doit fixer : <la liste de la fiche>.
Les questions ouvertes : <la liste de la fiche>. Pour chacune, écris les options, évalue-les selon l'arbre de décision de `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §5, retiens-en une et consigne l'arbitrage dans la section « Décisions » de la spec. Si une question ne se tranche qu'en amendant une décision acquise, ne tranche pas : signale-le.
Ce que la spec ne doit pas absorber : <la liste de la fiche>.
<Si lot lourd : propose le découpage en parties et l'invariant qui justifie l'ordre ; proposition de départ : …>

Rends : le chemin du fichier, la table des arbitrages, et toute prémisse du brainstorm trouvée fausse en la re-mesurant.
````

### 4.2. Vérificateur de spec

````
Tu vérifies une spec que tu n'as pas écrite. Lis `CLAUDE.md` d'abord. Tu ne modifies aucun fichier.

La spec : <chemin>. Le lot : <lot>. Ses décisions : <liste D>, texte dans le brainstorm v3 §1.

Vérifie, chaque point par une commande ou une citation, jamais de mémoire :
1. Chaque `fichier:ligne` cité existe et dit ce que la spec lui fait dire, sur la branche courante.
2. Chaque décision du lot est couverte ; aucune n'est contredite — cite la ligne du brainstorm.
3. Rien de « ce que la spec ne doit pas absorber » n'y est entré : <liste>.
4. Chaque question ouverte est tranchée, avec ses options et son motif ; aucun arbitrage n'amende une décision acquise ni ne change une valeur mesurée par la simulation.
5. Les transitions avec les lots voisins sont traitées : <lignes de §7.2 qui concernent le lot>.
6. Les règles du dépôt tiennent : trois couches séparées, donnée bilingue, id = nom de fichier, un fait à un seul endroit, pas de code sans lecteur.
7. Les tests sont nommés, et chacun garde une chose précise.
8. <Le point propre au lot, donné par la fiche.>

Rends une table : numéro, où, constat, preuve, gravité (bloquant / moyen / mineur / rédaction), correction proposée. Puis une ligne : « prête » ou « à corriger ».
````

### 4.3. Rédacteur de plan

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis `<chemin de la spec>` <§ de la partie>. Modèle de forme : `docs/superpowers/plans/2026-09-16-p49-passifs-partages.md` — but, architecture, contraintes globales, carte des fichiers, tâches à cases à cocher. Cite le code tel qu'il est sur la branche courante : re-mesure chaque `fichier:ligne`, jamais de mémoire. Base de tests : <N>, et chaque tâche donne le total attendu. Le plan ne crée pas de branche : il s'exécute sur `<branche de la vague>`. Contraintes globales : celles de l'orchestration §3.5. <Si la fiche demande la simulation : une tâche réaligne le script et le relance.> Ne touche à aucun fichier de `lib/`, `assets/` ni `test/`. Rends le chemin du plan et sa carte des fichiers.
````

### 4.4. Vérificateur de plan

````
Passe de vérification du plan `<chemin>`, contre la spec `<chemin>` <§> et le code de la branche courante. Tu ne modifies aucun fichier.

Vérifie, chaque point par une commande, jamais de mémoire :
- ce que le plan croit avoir à faire et qui est déjà fait par un lot précédent — toute tâche qui le réécrit est à supprimer ;
- les chemins et numéros de ligne cités, un par un ;
- le total de tests attendu à chaque tâche ;
- que chaque tâche laisse `dart analyze` propre et `flutter test` vert, et qu'aucune n'introduit de code sans lecteur ;
- que chaque exigence de la spec a sa tâche, et qu'aucune tâche ne sort de la spec ;
- <le point propre au lot, donné par la fiche>.

Rends une table : tâche, constat, preuve, gravité (bloquant / moyen / mineur), correction proposée. Puis une ligne : « prêt » ou « à corriger ».
````

### 4.5. Les skills de fin de vague

````
Invoque le skill `patch-notes-writer`. Version imposée : <version de la vague>. Ce qui est livré : <plans de la vague>. Ce que le joueur voit : <ligne de la fiche>. Écris l'entrée, aligne les trois porteurs de version et les liens de repli du site, et rends la version écrite et la liste des fichiers touchés.
````

````
Invoque le skill `memory-bank-sync`. Livré sur la branche `<branche>`, version <v>, **en attente du test, de la PR, du tag et de la fusion du propriétaire** — écris-le ainsi, jamais « fusionné » ni « publié ». Clos <lots> dans `docs/ROADMAP.md` §4, mets à jour `activeContext.md` et `progress.md` avec des chiffres re-mesurés (base <N> tests), ouvre les ADR <liste de la fiche>, corrige les fiches <liste de la fiche>. Note aussi la clôture de la vague précédente : fusionnée le <date>, taguée `v<version>`, CI/CD verte. Rends la liste des fichiers écrits.
````

---

## 5. Arbitrer — l'arbre de décision

Le propriétaire a délégué l'arbitrage des questions de spec (D69). Pour chaque question ouverte, écris les options, puis passe-les dans l'ordre par ces filtres ; le premier qui départage tranche.

1. **Une décision acquise.** Une option qui contredit une décision de D1 à D69 est écartée. Si *toutes* les options en contredisent une, ce n'est plus un arbitrage : arrête la vague (§6).
2. **Une valeur mesurée.** Une option qui change une valeur de D56 à D63 ou de D67 sans relance de la simulation est écartée (brainstorm §12, ligne 1).
3. **Les trois principes du brainstorm** (§3) : P1 — pas de contenu qui ne porte pas de décision ; P2 — chaque carte d'un lot nourrit son passif ; P3 — la fusion est le moteur de progression, rien ne court-circuite la chaîne trouvaille → fusion → rune → affûtage.
4. **Le mécanisme plutôt que le cas.** Entre une règle en donnée, réutilisable, et un cas écrit en Dart pour une carte ou une rune, la règle en donnée. Si les options sont les valeurs d'un même mécanisme, livre le mécanisme et choisis la valeur.
5. **L'architecture du dépôt.** Les trois couches de `CLAUDE.md` ; le répertoire porte l'appartenance ; un seul prédicat par question (`isOfferableTo`, `availablePassivesFor`) ; aucun champ que le répertoire impose.
6. **Ce que le joueur lit.** L'option dont l'effet se lit sur la carte, sur le HUD ou dans la description, sans règle cachée.
7. **Le périmètre.** L'option qui n'élargit pas la vague ni n'avale un lot voisin.
8. **À égalité**, la plus simple à défaire.

**Chaque arbitrage est consigné**, dans la section « Décisions » de la spec et dans le compte rendu de la vague : la question, les options, le filtre qui a tranché, le choix. Le propriétaire les lit au moment de son test ; un arbitrage qu'il renverse se corrige sur la branche avant la fusion.

---

## 6. Les garde-fous

**Ce que l'orchestrateur ne fait jamais** :

- pousser, ouvrir une PR, poser un tag, fusionner, ou commiter sur `main` ;
- amender une décision acquise du brainstorm, ou changer une valeur mesurée sans relancer la simulation ;
- élargir le périmètre : ni P-44 lots 2 à 4, ni P-16, ni un rééquilibrage que la fiche n'appelle pas ;
- éditer `assets/data/patch_notes.json` à la main, ou changer une version autrement que par `patch-notes-writer` ;
- lancer `dart format`, utiliser un worktree, sauter un hook, écrire du code par heredoc ;
- faire de la compatibilité des sauvegardes un sujet : avant la `1.0.0` elles ne se transfèrent pas d'une version à l'autre.

**Quand la vague s'arrête et rend la main**, avec l'état exact dans le journal :

- la porte d'entrée ne passe pas ;
- trois tours de vérification sans convergence, sur une spec ou sur un plan ;
- une question ne se tranche qu'en amendant une décision acquise ;
- la simulation ne retrouve pas les chiffres du rapport à valeurs inchangées ;
- un test reste rouge, ou `dart analyze` sale, après deux tentatives de correction d'une même tâche ;
- le code de `main` contredit une prémisse de la fiche au point de changer le périmètre du lot.

Une vague interrompue se reprend dans une session neuve, à l'étape que le journal indique.

---

## 7. La cohérence des lots — vérifiée le 01/10

### 7.1. Chaque décision a un lot

Les décisions du §1 du brainstorm ont été relues une à une contre la table des lots de son §11.

| Famille | Décisions | Lot | Vague |
|:---|:---|:---|:---:|
| Garde-fous de Puissance | D36, D37 | E0 | 1 |
| Moteur de runes | D27, D33, D44, D51, D61, D68 ; D28 pour le renommage `fusionRank` ; G1, G2 (§4.5) | E1 | 1 |
| Fusion, affûtage, Puits, boutique | D3, D5, D6, D13, D14, D20, D22, D32, D39, D46, D48, D63 (`b` = 50), D65 (`cheap`, `precise`, `spectral`) ; D28 pour la capacité et les pré-forgées | E2 | 2 |
| Trouvaille, main, XP, DDA, sources, seuils | D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57 à D60, D62, D63 (Q15), D67 | E3 | 3 |
| Signatures | D7 (forme), D41, D49, D53 ; D28 (`magic_missile` en Compétence) | E4 | 4 |
| Catalogue et profondeur | D8, D9, D10, D12, D15, D16, D17, D19, D21, D34 (ordre des tranches), D38, D40, D45, D50, D54, D63 (Q9), D65 (cinq runes), D66 | Tranche 1 + P-44 lot 1 | 5 |
| Tranche 2 | D30 (Voile), D35 (Vampire) | Tranche 2 | 6 |
| Tranche 3 | D34 (déclencheur de Marque), D55 (*Prière*) | Tranche 3 | 7 |
| Après `0.6.0` | D29, D52, D56 ; Q4, Q18 ; §9.2 #5 à #9 ; D65 (`retain`) | P-16 · P-44 lots 2 à 4 | — |
| Méthode | D26 (faite), D64, D65, D66, D68, D69 | Ce fichier | 0 |

Les items non numérotés ont aussi leur vague : `wisdom.json` en `mythic` (§5) en vague 3 ; `EntitySource('cards/*/*.json')`, `isOfferableTo` étendu, `PassiveData.classes` à une seule classe (§6) et le validateur `costs.armor` (§7.4) en vague 5.

### 7.2. Les transitions entre lots

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|
| E0 → E1 *(même vague)* | Aucun : indépendants en code | — |
| E1 → E2 | La forge du feu et le nœud Forge de Fusion vivent encore ; E1 leur laisse `pools`, `stackable` et la capacité en lecture | D68 |
| E2 → E3 | La forge du feu a disparu, la trouvaille n'existe pas encore : les runes ne viennent que de la fusion, les doublons du boss « cartes » et de la boutique seulement — **en `0.5.4` les fusions sont rares** | Voulu (brainstorm §11, ligne E3). La spec E2 et la note joueur le disent |
| E3 → E4 | Les signatures sont encore des cartes : exclues de la trouvaille par `unique` (`isOfferableTo`), sans rune, `fusionRank` 0 pour la DDA | Un test dans E3 le garde |
| E4 → tranche 1 | Les signatures sont des compétences sans évolution ; le deck ne connaît que les 17 neutres | La tranche 1 ajoute `evolutions` et l'écran |
| Tranche 1 → 2 → 3 | Six passifs masqués, puis trois ; `fireball` reste neutre jusqu'au lot Marque, son id de tutoriel ne change pas | Le masquage est arbitré en vague 5 (O5) |
| Tranches → P-44 lots 2 à 4 | Trois cartes attendent un mécanisme hors périmètre : Rempart (épines), Voile (`retain`), Carnage (*Forge de guerre*) | **Elles ne s'écrivent pas avant `0.6.0`** ; chaque lot atteint ses 5 cartes sans elles ; la vague 7 les porte en ROADMAP sur la ligne de P-44 |

### 7.3. Ce que le script de simulation impose

`tool/simulations/d26_economy_sim.dart` lit `assets/data/` au lancement (`:723-845`) : les ennemis, **les cartes de `cards/` à plat**, les reliques, `level_up_rewards/`, `forge_upgrades/` (`id`, `weight`, `eligibleCardTypes` — il ignore `pools`) et le bloc `mastery` des passifs. Ses lots et ses runes neuves sont **codés en dur** (`:825-845`, un `switch` par id).

| Vague | Ce qui casse ou dérive | À faire dans le plan |
|:---:|:---|:---|
| 1 | Rien : ni `pools` ni `eligibleEffects` ne sont lus | Pas de relance |
| 2 | `cheap`, `precise`, `spectral` apparaissent en fichiers : le `switch` les prend par défaut **en plus** des runes codées en dur — doublon probable | Réaligner le chargeur, relancer : mêmes chiffres attendus |
| 3 | `level_up_rewards/` gagne des `effect` neufs que le chargeur peut refuser ; `wisdom.json` change de pool | Réaligner, relancer : D56 à D63 et D67 doivent se retrouver |
| 4 | `classes/*/cards/` devient `skills/` ; les signatures sont codées en dur | Vérifier le chemin, relancer |
| 5 | `cards/<passif>/` apparaît : selon que le chargeur descend ou non dans les sous-dossiers, les cartes de lot passent pour des neutres ou sont ignorées | Faire lire les lots réels à la place des lots génériques, relancer : **première mesure sur les vraies cartes** — l'écart avec le rapport §2.2 est une information, pas un arrêt |
| 6, 7 | Trois lots réels de plus à chaque fois | Relancer ; la vague 7 donne la mesure des neuf lots, point de départ de P-16 |

---

## 8. Les fiches de vague

Chaque fiche donne à l'orchestrateur la matière des gabarits de §4. « État mesuré » date du 30/09 sur `3b8c66f` : **à revérifier, pas à croire** — les vagues précédentes ont déplacé les lignes.

### 8.0. Vague 0 — la méthode et la ROADMAP

✅ **Faite le 01/10**, dans la session d'orchestration, directement sur `main`, à la demande du propriétaire. Ce qui suit est ce qu'elle avait à faire et a fait — à une nuance près : les chiffres des constats de P-16 sont restés dans le rapport de simulation, **liés et non recopiés** dans la ROADMAP, comme `memory-bank-sync` l'impose.

**Ni version, ni spec, ni code.** Branche prévue `docs/vague-0-roadmap-et-methode` — non utilisée.

1. **Trois retouches au brainstorm**, arbitrées par l'orchestrateur (§5 ; elles n'amendent aucune décision, elles comblent trois oublis) :
   - au nœud C2 du graphe de §11 : « Marque du Mage sur la première carte de dégâts (D34) avec le lot Marque » ;
   - au graphe de §11 : un nœud `P44d["P-44 lot 4<br/>effets interactifs (B19) · CardTarget.none · costs.discard"]` après `P44c` — le « lot propre » de §9.2 #9 — et la ligne P-44 de la table « La roadmap à redécouper » passe à quatre lots ;
   - en §7.3, ligne Arcaniste : « une Compétence multi-coups à écrire en tranche 1 (§7.4) ».
2. **`memory-bank-sync`**, avec ces consignes :
   - `docs/ROADMAP.md` §4 — **P-43** devient « Économie unifiée », premier chantier, lots E0 à E4 ; **P-42** devient « Catalogue par lots de passif », trois tranches, après E4 ; **P-44** devient quatre lots, le premier avec la tranche 1. **La ROADMAP garde une ligne par chantier et renvoie à ce fichier** pour les vagues, les versions et l'avancement : aucun fait n'est écrit aux deux endroits.
   - L'encart « un seul programme en cinq lots, à ne pas ré-ordonner » est réécrit : l'ordre est P-43 → P-42 → P-44, par D64, et la méthode est celle de D69.
   - La phrase « P-42 ira au numéro suivant, qui reste à décider » est remplacée par le renvoi à §1 de ce fichier : `0.5.3` à `0.6.0`.
   - **P-18** : ses deux points restants sont annulés par D2 et D3. **P-16** hérite cinq constats, avec leurs chiffres à k = 2 (rapport §7.2) : reliques de mana ; un puits d'or à créer (5 596 or dorment à l'acte 15) ; la survie après l'acte 5 ; la boucle XP / niveau ennemi (D58) ; l'échange 3 → 1 et l'événement de fusion (D29, D56 ; Q4, Q18).
   - §9 « Séquencement » : le jalon en cours est ce chantier.
   - **Un ADR pour la méthode** : un chantier par vagues, une version par vague, une session par vague, l'orchestrateur arbitre, le propriétaire teste, tague et fusionne (D69).
   - `_patterns/` : une fiche pour le script de simulation (§7.3) ; `_rules` périmées relevées par la revue §9 (`01-00`, `03-8` sur `eco`, `04-00` sur `strength`) : marquées « change avec la vague 1 ou 2 ».
   - `CLAUDE.md`, table « Documentation Map » : une ligne — *le chantier en cours, vague par vague* → ce fichier.
   - `activeContext.md` : focus = vague 1.
3. **Porte de sortie** : pas de tag. La vague 1 exige seulement que la vague 0 soit fusionnée.

### 8.1. Vague 1 — `0.5.3` — E0 et E1

Deux lots, en série : E0 en entier (spec, plan, implémentation), puis E1. Branche `feat/v0.5.3-p43-e0-e1`.

#### E0 — un statut `might` par source, `ratio` de conversion

**Décisions** : D36, D37 (D66, D68).

- **D36.** `EntityStats.addStatus` (`entity_stats.dart:134-139`) fusionne deux `might` de durées différentes en un seul, valeur sommée, durée maximale (`StatusEffect.combine`, `isStackable` vrai par défaut, `status_effect.dart:17`) : `demon_form` (2 pendant 4 tours) puis `iron_wall` chez le Berserker (10 pendant 1 tour) donne Puissance 12 pendant 4 tours. Demain `StatusEffect` porte l'id de ce qui l'a posé et `addStatus` ne fusionne que même statut *et* même source ; `effectiveMight` somme déjà toutes les entrées, `tickStatuses` les vieillit séparément, le HUD affiche la somme.
- **D37.** Un champ `ratio` (défaut 1) sur `stat_rule.dart`, appliqué par `StatGains._convert`, à 0,5 arrondi à l'entier supérieur dans `classes/berserker/class.json` : 6 → 3, 5 → 3, 1 → 1.

**À lire** : brainstorm §1 (D36, D37, D66, D68), §11 ligne E0, §7.2 ; revue §8.1 R3 et §8.2 idées 2 et 3 ; ADR-097, ADR-090, ADR-100, ADR-081 ; spec de P-41, §7 et §9.1.
**État mesuré** : `stat_rule.dart` (`RuleMode { convert }` seul ; `stat`, `mode`, `to`, `duration`) ; `StatGains._convert` dans `player_stats_manager.dart` ; le tutoriel (P-41 lot D) mesure le gain réel par `StatGains.apply` et **génère** le titre de l'étape « Armure & Dégâts » et la règle en clair ; la carte de classe affiche la règle générée ; l'éditeur refuse un `mode` inconnu sur `statRules`.
**La spec doit fixer** : les textes générés qui doivent dire « 6 armure → 3 Puissance » ; `ratio` dans le vocabulaire de l'éditeur et l'onglet Héros du menu de debug ; que la sauvegarde n'est pas concernée (les statuts ne sont pas persistés — à vérifier) ; les tests : `demon_form` puis `iron_wall` donne deux effets vieillis séparément, l'arrondi sur 1, 5 et 6, le tutoriel ne casse pas.
**À arbitrer** : l'identité d'une source — l'id de carte ou l'`uniqueId` de l'instance, et ce que « la même carte rejouée s'additionne » veut dire avec deux exemplaires dans le deck ; la borne de `ratio` dans l'éditeur.
**Ne pas absorber** : rien d'E1 ; ni `mightRatio` (D38) ni le budget de Puissance ; aucun rééquilibrage de carte.
**Point propre au vérificateur** : aucune tâche ne touche `forge_upgrade_data.dart` ni `effect_resolver.dart`.

#### E1 — le moteur de runes data-driven

**Décisions** : D27, D33, D44, D51, D61, D68 ; D28 pour le seul renommage `forgeSlotBonus` → `fusionRank` ; G1, G2. **E1 ne change pas la boucle de jeu** (D68) : `pools`, `stackable` et la capacité restent en lecture pour la forge du feu et le nœud Forge de Fusion.

**À lire** : brainstorm §4.2 (modèle de rune, esquisse `sharp.json`, prédicat du geste de fusion), §4.4 dernier point (l'applicateur que les évolutions de signature partageront en code), §4.5, §8 en entier, §11 ligne E1 ; revue §2.1 (les sept lecteurs de la capacité : E1 n'en touche aucun), §3.5, §13 IV3 et IV4 ; ADR-094, ADR-061, ADR-100.
**État mesuré** : `forge_upgrade_data.dart` (`pools`, `valueMultiplier`, `eligibleCardTypes`, `stackable`, `requiresExhaust`) ; `entity_descriptor.dart:238` ; `card_text_renderer.dart:106` ; `effect_resolver.dart:142-174` (le `switch`), `:222-228` (multiplicateur de rareté, aussi sur `draw` et `gain_mana`) ; `card_instance.dart:35-50` (paliers et collisions d'arrondi) ; `forge_rune_rules.dart:46-52` (`consolidate`, le lecteur de `maxLevel` dès E1) ; `forge_upgrade_dialog.dart:80-86` et `shop_controller.dart:51-57` (les deux lecteurs de l'éligibilité) ; `card_data.dart:33-39` et `:142-143`.
**La spec doit fixer** : un seul prédicat d'éligibilité, fonction pure, sur le modèle d'`isOfferableTo` — `eligibleCardTypes` ou `eligibleEffects`, `requiresExhaust`, `requiresMinCost` sur le coût courant, `excludesEffects`, `excludesRunes` symétrique ; `maxLevel` de chaque rune d'aujourd'hui selon la table de §8, lu par `consolidate` ; G1 et G2 ; le renommage et l'amendement d'ADR-094 ; les huit JSON — ce qui s'ajoute, ce qui **reste** ; le descripteur de l'éditeur ; les tests, dont un test de données par rune.
**À arbitrer** : **la forme de l'applicateur de deltas** — comment une rune déclare son effet en donnée pour couvrir les huit d'aujourd'hui, les trois d'E2 et les six de P-44 sans en écrire aucune de neuve, et la couture que les évolutions de signature réutiliseront en code sans confondre les deux systèmes.
**Ne pas absorber** : la fusion, l'héritage, l'affûtage, le Puits, la boutique, les pré-forgées, la suppression de la capacité, de `pools` et de `stackable`, `minFusionRank`, « une rune par type » — tout cela est E2 ; aucune rune neuve ; les évolutions de signature.
**Point propre au vérificateur** : `pools`, `stackable` et la capacité gardent leurs lecteurs ; aucun écran ne change de comportement hors la formule de `sharp` et `hardened`.

**Simulation** : pas de relance.
**Ce que le joueur voit en `0.5.3`** : le Berserker convertit moitié moins d'armure en Puissance ; deux bonus de Puissance de durées différentes ne se confondent plus ; `sharp` et `hardened` donnent +15 % de la base par niveau, au moins +1, au lieu de +2.
**Pour `memory-bank-sync`** : ADR « un statut par source et `ratio` » ; ADR « moteur de runes data-driven », ADR-094 amendé ; fiche `_rules/03-8` (la description d'`eco`).

### 8.2. Vague 2 — `0.5.4` — E2, fusion = forge

**Décisions** : D3, D5, D6, D13, D14, D20, D22, D28, D32, D39, D46, D48, D63 (`b` = 50), D65, D68. Branche `feat/v0.5.4-p43-e2-fusion-forge`. **Le cœur de P3** : E2 supprime `pools`, `stackable` et la capacité avec les deux écrans qui les lisaient.

**À lire** : brainstorm §4.2 en entier, §4.3, §8 (lignes `cheap`, `precise`, `spectral` ; table des `maxLevel` ; paragraphe D65), §11 ligne E2, §12 lignes 1 et 2 ; **revue §2.1 en entier** (les sept lecteurs de la capacité, les six tests à réécrire, les ADR et fiches à amender), §11 S4 et S6, §13 IV3 et IV5 ; rapport §2.3, §3.6, §3.8, §3.15 ; ADR-074, ADR-094, ADR-101, ADR-078.
**État mesuré** : `deck_controller.dart:288` (`mergeCards`), `:314-321` (héritage tronqué) ; `deck_screen.dart:200-231` ; `forge_upgrade_dialog.dart:32,51` ; `run_controller.dart:32-33` (`forgeSlots`, `forgeTargetCardId`) ; `rest_screen.dart:29` ; `rest_card_selection_screen.dart:30` ; `forge_fusion_screen.dart:102,112` et `forge_rune_rules.dart:60-78` (`fusionOptionsFor`) ; `map_content_placer.dart:24-36` ; `shop_controller.dart:188-205` et `:341-355` ; `shop_state.dart:16` ; `card_data.dart:142-143` ; `card_instance.dart:24` ; `ui_card.dart:69,101,241` ; `card_text_renderer.dart:519` ; `tutorial_engine.dart:451`.
**La spec doit fixer** : le geste de fusion (`ForgeUpgradeDialog` rappelé depuis l'écran de deck, le prédicat d'E1 comparé au rang **atteint**, moins de 3 runes si moins sont éligibles, jamais aucune tant qu'une existe) ; l'héritage par `consolidate` (D13) ; l'affûtage (une rune, un niveau, `b × niveau`, une fois par visite, `maxLevel` respecté) ; le Puits (toutes les runes éligibles au sens de §4.2, deux tiers du niveau arrondi au plus proche et borné, `base × niveau`, garanti tous les 3 actes sur les étages 3 à 7) ; la boutique (copie du deck, même rang, sans rune ; pré-forgées bornées par `fusionRank`) ; les trois runes neuves, poids 50, `minFusionRank` 1 ; le tutoriel (`:451`) ; les tests de la revue §2.1.
**À arbitrer** : l'écran d'affûtage et la manière de tenir « une fois par visite » ; l'écran du Puits ; ce que `forgeTargetCardId` désigne désormais ; la table de prix de la copie du deck ; le découpage en parties.
**Parties proposées** : (1) la fusion propose une rune, l'héritage, la capacité supprimée, l'affûtage — la boucle change une fois ; (2) le Puits, la boutique, les trois runes, `minFusionRank`, `pools` et `stackable` supprimés.
**Ne pas absorber** : la trouvaille, `maxHandSize`, l'XP, la DDA, *Sagesse*, les sources d'affûtage hors feu, l'événement de relique (E3) ; les signatures (E4) ; les runes de pipeline (vague 5).
**Point propre au vérificateur** : après E2, plus aucun lecteur de `pools`, de `stackable` ni de la capacité (`git grep -w`).
**Simulation** : réaligner le chargeur sur les trois fichiers neufs, relancer, mêmes chiffres attendus.
**Ce que le joueur voit en `0.5.4`** : chaque fusion donne une rune parmi trois ; le feu de camp affûte ; le Puits d'échange remplace la Forge de Fusion ; la boutique vend une copie d'une carte du deck. **À dire dans la note** : les fusions restent rares jusqu'à la version suivante.
**Pour `memory-bank-sync`** : ADR « fusion = forge » ; ADR-074 et ADR-094 amendés ; fiches `_rules/02-3`, `02-4`, `03-7`, `03-8`.

### 8.3. Vague 3 — `0.5.5` — E3, trouvaille et progression

**Décisions** : D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57, D58, D59, D60, D62, D63 (Q15), D67. Branche `feat/v0.5.5-p43-e3-trouvaille`. **Les valeurs sont mesurées** (rapport §4, §7) : la vague les livre, elle ne les rediscute pas.

**À lire** : brainstorm §4.1 en entier, §4.3, §5, l'encadré de §2 sur la « pioche infinie », §11 ligne E3 et nœud R, §13 Q5 et Q15 ; revue §3.1 E2, §3.2 E3, §9 (les collatéraux sont à P-16, **pas ici**), annexe A n° 5, 11, 12, 13, 20, 23 ; rapport §2.1, §3.1, §3.3, §3.9 à §3.11, §3.16, §4, **§7.1** et §7.3 ; ADR-078, ADR-098, ADR-099, ADR-101.
**État mesuré** : `reward_controller.dart:75-82`, `:83-165` (`:86` le +10 % d'XP par niveau), `:168-195` (`:186-194` le `doubleXp` et sa carte bonus) ; `game_constants.dart:36` ; `deck_controller.dart:200` ; `run_controller.dart:41` et `player_stats_manager.dart:102-108` ; `player_stats_manager.dart:127` ; `encounter_system.dart:97-120` (`:101`), `:136-148` ; `level_up_reward_service.dart:38-148` ; `level_up_reward_data.dart:7-11`, `:277` ; `event_controller.dart:80-100` ; `passive_strategies.dart:107,146`.
**La spec doit fixer** : la table `cardDrops` par type de nœud et les reliques A (rare) et C (rare au moins), par `applyRunRuleModifier` ; `maxHandSize` en stat de run ; l'XP en table par acte — 115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015, dernière valeur répétée au-delà ; `PlayerPower` = 2 × Σ `fusionRank` ; `wisdom.json` en `mythic` ; le boss « XP » sans carte, une rune du deck monte d'un niveau ; la relique légendaire de D42(a) ; l'événement d'affûtage ; la récompense mythique qui monte un `maxLevel` ; l'événement d'échange de relique ; `threshold` de Bénédiction en donnée à 5 et `floor: 2` sur Flux ; le test qui garde la transition E3 → E4.
**À arbitrer** : où vivent les tables (Q5 : `cardDrops` dans `GameConstants` tant que le socle de carte n'existe pas ; la table d'XP « en donnée » — un document plat ou une constante nommée) ; les valeurs de D63 pour l'échange de relique (Q15), à confirmer ou remplacer en le disant ; ce que fait le boss « XP » quand aucune rune n'est sous son `maxLevel` ; le découpage en parties ; **D25 et la « pioche infinie »** — le bug du testeur n'a pas été reproduit : cherche à le reproduire par un test ; reproduit, c'est un correctif de cette vague ; non reproduit, `maxHandSize` migre quand même (D2) et ADR-078 D3 s'amende en disant que le testeur a vu le cyclage.
**Parties proposées** : (1) la boucle — `cardDrops`, reliques, main, XP, DDA ; (2) les sources — boss « XP », relique légendaire, événements, mythique `maxLevel`, *Sagesse*, seuils.
**Ne pas absorber** : les reliques de mana, le puits d'or, la survie, la boucle XP / niveau ennemi, l'échange 3 → 1, l'événement de fusion (P-16) ; les signatures (E4) ; aucun rééquilibrage.
**Point propre au vérificateur** : aucune valeur de D56 à D63 ni de D67 n'a changé ; la relance de la simulation est une tâche du plan.
**Simulation** : réaligner sur `level_up_rewards/`, relancer ; **les chiffres du rapport doivent se retrouver**, sinon arrêt.
**Ce que le joueur voit en `0.5.5`** : une carte après chaque combat, une seconde possible en élite ; deux niveaux par acte ; des sources d'affûtage hors du feu ; un événement pour échanger une relique. La note la plus longue du chantier.
**Pour `memory-bank-sync`** : ADR « trouvaille et progression » ; ADR-078 D3 amendé ; fiche `_rules/01-00`.

### 8.4. Vague 4 — `0.5.6` — E4, les signatures en compétences de classe

**Décisions** : D49, D41, D53 ; D7 pour la forme ; D28 (`magic_missile` en Compétence). Branche `feat/v0.5.6-p43-e4-signatures`. Le modèle d'évolution et son écran sont **la vague 5** (D53) : E4 leur réserve le champ.

**À lire** : brainstorm, bloc « Vocabulaire », **§4.4** (forme, moteur, à revoir, esquisse `smite.json`, point « Stockage », point `magic_missile`), §5, §6, §11 ligne E4 ; revue §2.1, annexe A n° 3, 24, 25, 29, annexe B.2 ; ADR-084, ADR-086, ADR-094, ADR-101, ADR-081, ADR-100.
**État mesuré** : `hero_data.dart:43` ; `hero_skills_link.dart:6-13` ; `starter_deck_draft_screen.dart:57` ; `game_data_service.dart:76-89` ; `card_data.dart:7`, `:22-28`, `:44`, `:136-139` ; `deck_controller.dart:158` ; `effect_resolver.dart:104-106` ; `combat_state.dart` ; `power_rules.dart` ; `tutorial_engine.dart:175` ; `tutorial_starter_deck_widget.dart:41` ; `save_service.dart` ; le HUD est en Flutter (`lib/ui/widgets/hud/`), la main en Flame.
**La spec doit fixer** : `classes/<id>/skills/<id>.json`, l'`EntitySource`, `sync_assets` ; la recharge dans l'état de combat, remise à zéro à chaque combat, jamais sauvegardée ; la résolution — mana, `resolveCard`, mise en recharge ; la suppression de `CardRarity.unique`, d'`isAcquirable` et de `CardCategory.characterSpecific`, ADR-094 et ADR-101 amendés ; la barre au HUD et ses états ; le tutoriel (`:175`, `:41`) ; le draft de départ à 5 cartes ; la sauvegarde (les signatures sortent du `masterDeck`, sans migration) ; l'onglet du dictionnaire ; la carte de classe ; `magic_missile` en `type: skill` ; les tests.
**À arbitrer** : **le modèle** — un `SignatureData` propre ou un `CardData` restreint ; **une signature compte-t-elle comme une carte jouée pour les déclencheurs de passif** (`onSkillPlayed` de Flux de Mana avec `magic_missile`, `onAttackPlayed` de Soif de Sang avec `reckless_strike`, `onDamagingCardPlayed` de Marque) — « résolue comme une carte » penche pour oui ; le coût et la recharge de chaque signature (l'esquisse dit 2) ; ce que devient l'enum `CardCategory` si `global` reste seule ; les signatures dans l'éditeur de contenu, ou non pour ce lot ; le découpage en parties.
**Parties proposées** : (1) donnée, modèle, moteur, sauvegarde, tests ; (2) HUD, tutoriel, draft, dictionnaire, sélection de classe.
**Ne pas absorber** : le modèle d'évolution, les pools et l'écran (vague 5) ; toute carte, toute rune ; un rééquilibrage des six signatures.
**Point propre au vérificateur** : plus aucune signature dans le `masterDeck` ni dans un pool d'offre ; `unique` et `characterSpecific` n'ont plus d'occurrence (`git grep -w`).
**Simulation** : vérifier le chemin `class.json`, relancer, mêmes chiffres attendus.
**Ce que le joueur voit en `0.5.6`** : deux compétences de classe toujours disponibles, dès le premier tour, avec un temps de recharge.
**Pour `memory-bank-sync`** : ADR « signatures hors du deck » ; ADR-094 et ADR-101 amendés ; fiche `_rules/02-3`.

### 8.5. Vague 5 — `0.5.7` — la tranche 1 et P-44 lot 1

**Décisions** : D8, D9, D10, D12, D15, D16, D17, D19, D21, D34 (l'ordre : Rempart, Sang, Arcaniste), D38, D40, D45, D50, D54, D63 (Q9), D65 (`piercing`, `lifesteal`, `splash`, `echo`, `transfusion`), D66. Branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`. **Les cartes sont des ordres de grandeur** : la spec les fixe, le plan les écrit, le test du propriétaire les corrige. Le rédacteur prend le rôle `game_designer`.

**À lire** : brainstorm §3, **§6 en entier**, §7 (intro ; lignes Rempart, Sang avec sa note, Arcaniste), **§7.4 en entier**, §8 (les cinq runes), **§9 en entier**, **§4.4** (le modèle d'évolution), §5, §10 lignes 2 et 3, §11 nœuds C1 et P44a, §12, §13 Q6 à Q11 ; revue §7 idées 2.6 à 2.8, §8.1 R3, R6, R8, **annexe B en entier**, §11 S1, S11, S20, §12 T6, §13 IV9 ; rapport §2.2, §3.12, §5 ; ADR-086, ADR-101, ADR-096, ADR-061, ADR-097, ADR-081.
**État mesuré** : `game_data_service.dart:76-89` (pas de source `cards/*/*.json`) ; `passive_data.dart:105` ; `passive_availability.dart` (« débloqué vaut tous », aucun masquage) ; `power_rules.dart:17-32` ; `strategies.dart:49`, `:61,69` (`_payLifesteal`), `:94` (le soin passe par le critique — le coût en PV n'est pas un soin négatif), `:147`, `:166-167` ; `effect_resolver.dart:104-106`, `:177-184`, `:204-205`, `:222-228` (la rareté ne multiplie jamais le terme `scaleWith`) ; `damage_pipeline.dart:15-18`, `:46-49` ; `turn_phase_manager.dart:107` et `enemy_instance.dart:28-29` (`freeze`) ; `passive_strategies.dart:85` ; `player_stats_manager.dart:472` ; `draft_screen.dart`, `DraftCardReel`, `pendingDrafts` (`_rules/03-10`) ; `tutorial_fixtures.dart:17-19` ; `entity_id_convention_test`, `referential_integrity_test`.
**La spec doit fixer** : le moteur — `scaleWith` sur six sources, `hits`, `mightRatio` et son test (Σ `hits` × `mightRatio` ≤ coût + 1), les statuts proportionnels et `freezing` qui perd son `maxLevel: 1`, `costs` et ses trois règles (D40), le validateur `costs.armor` dans un lot Berserker, la recalibration de *Marque du Mage*, les cinq runes ; la forme C — `EntitySource('cards/*/*.json')`, `passive` injecté, `isOfferableTo` étendu d'une ligne, `classes` à une seule classe, le draft de départ, `feeds` et son test, le test des cartes gratuites (D50) ; les cartes — 5 à 6 par lot, bilingues, au moins une par mécanisme assigné : Rempart (`scaleWith: armor`, `costs.armor` — *Rempart brisé*, *Percée* à 0 mana), Sang (`costs.hp`, `scaleWith: missingHp` — *Sang versé*, *Dernier souffle* ; *Transe* pose `might_regen`, l'orphelin d'août ; `demon_form` déplacée), Arcaniste (Compétences de dégâts à 1, altération pure, **une Compétence multi-coups** — O4) ; `focus` supprimée ; les évolutions — `SignatureEvolutionData`, les pools des six signatures, `SignatureInstance.evolutions`, *Célérité* majeure (D54), l'écran par `pendingDrafts`, la sauvegarde.
**À arbitrer** : Q6 (3-4 mineures, 4-5 majeures, le repli) ; Q7 (deux majeures contradictoires : un champ `excludes` ou des pools sans conflit) ; Q8 (cartes-pont) ; Q9 (draft de départ, défaut 2 + 3) ; Q10 (`category: global` + `passive`, ou une valeur `lot`) ; Q11 (le double bonus de Puissance) ; **O5, le masquage des six passifs** — proposition : un passif dont le dossier `cards/<passif>/` est vide n'est pas disponible, dans `availablePassivesFor` ; le découpage en parties.
**Parties proposées** : (1) **le moteur P-44 lot 1 sur les 17 neutres**, avec les cinq runes — rien de visible, tout testé ; (2) **la forme C et les trois lots**, le masquage, les tests de données ; (3) **les évolutions et leur écran**.
**Ne pas absorber** : les six autres lots, D30, le déclencheur de D34, D55 ; P-44 lots 2 à 4 ; P-16 ; `maxMana` reste 3.
**Point propre au vérificateur** : chaque carte de lot touche une entrée de `feeds` ; aucune neutre ne porte de coût autre que du mana (D17) ; aucun lot ne dépasse une carte à coût total nul.
**Simulation** : faire lire au script les lots réels, relancer — première mesure sur les vraies cartes.
**Ce que le joueur voit en `0.5.7`** : le deckbuilding existe — trois passifs jouables avec leur lot, les mécanismes de profondeur, les évolutions de signature.
**Pour `memory-bank-sync`** : ADR « forme C et lots par passif » ; ADR « évolutions de signature » ; ADR « profondeur, lot 1 » ; les fiches `_rules` des cartes et des statuts.

### 8.6. Vague 6 — `0.5.8` — la tranche 2

**Lots** : **Croisé** (Paladin, *Ferveur*), **Vampire** (Berserker, *Soif de Sang*), **Voile** (Mage, *Canalisation*) — une par classe comme la tranche 1, Voile fixé par D66. L'orchestrateur peut re-arbitrer cette composition (O3) si la vague 5 a appris quelque chose qui la contredit ; il le dit. **Décisions** : D30, D35, D16, D17, D45, D50. Branche `feat/v0.5.8-p42-tranche-2`.

**À lire** : brainstorm §7.1 ligne Croisé, §7.2 ligne Vampire, §7.3 ligne Voile et la note, §7.4, §5, §1 (D30, D35) ; revue §7 idées 2.5, 2.7, 2.8, annexe B.3 et B.4 ; la spec et les ADR de la vague 5 ; le rapport de la simulation relancée en vague 5.
**La spec doit fixer** : **D30** — Canalisation devient une banque de mana : `channeling.json` change d'`effectType`, `startTurn` lit la réserve, plafond `maxMana` plus 1 par point de Maîtrise, Mage uniquement ; le statut `mana_regen` sur le modèle de `might_regen` (*Méditation*) ; les cartes — Croisé (*Riposte*, *Jugement*, *Marteau sacré* en multi-coups), Vampire (Attaques à 1 qui piochent : *Morsure*, *Curée* ; *Lacération*, la carte à 0 du lot ; *Frénésie sanglante* en `scaleWith: cardsPlayedThisTurn`), Voile (*Barrière*, *Méditation*, *Sceau*) — complétées à 5 ou 6 par lot ; le démasquage des trois passifs ; les textes joueur de Canalisation.
**À arbitrer** : les cartes qui complètent chaque lot ; la courbe de coûts de Voile (des tours à 5-6 mana, sans carte à 0) ; les cartes-pont si Q8 les a retenues.
**Ne pas absorber** : la carte `retain` de Voile (P-44 lot 3, après `0.6.0`) ; la tranche 3.
**Point propre au vérificateur** : D50 tient pour Berserker · Vampire (`concentration` et *Lacération*, deux cartes gratuites, épuisables) ; aucune carte ne suppose un mécanisme hors périmètre.
**Simulation** : relancer sur six lots réels.
**Ce que le joueur voit en `0.5.8`** : trois passifs de plus avec leurs cartes ; Canalisation garde le mana non dépensé pour le tour suivant.
**Pour `memory-bank-sync`** : ADR pour la banque de mana si le mécanisme le justifie ; les fiches des passifs.

### 8.7. Vague 7 — `0.6.0` — la tranche 3 et la clôture

**Lots** : **Sanctifié** (Paladin, *Bénédiction*), **Carnage** (Berserker, *Frénésie*), **Marque** (Mage, *Marque du Mage*). **Décisions** : D34 (le déclencheur), D55, D43 (la variante « armure conservée », qui attendait ce lot), D16, D17, D45, D50. Branche `feat/v0.6.0-p42-tranche-3`.

**À lire** : brainstorm §7.1 ligne Sanctifié et la note, §7.2 ligne Carnage et la note, §7.3 ligne Marque et « Une tension levée, une gardée », §13 Q11 et Q12, §1 (D34, D43, D55, D60) ; revue §8.1 R6 et R8, annexe B.1 ; les specs des vagues 5 et 6.
**La spec doit fixer** : **D34** — *Marque du Mage* se déclenche sur la première **carte de dégâts** du tour (`onDamagingCardPlayed`), Attaque ou Compétence ; les quatre élémentaires déplacées dans le lot Marque — **`fireball` garde son id**, le tutoriel le lit (`tutorial_fixtures.dart:17-19`) ; **D55** — *Prière* et le statut `hp_regen` ; `weakness`, le dernier orphelin d'août, posé par *Sommation* et *Édit* ; `metallicize` déplacée dans Sanctifié, `warcry` dans Carnage ; les cartes — Sanctifié, Carnage (*Moulinet*, *Tourbillon*, *Coup de grâce*, *Exécution* en `scaleWith: targetMissingHp`), Marque (*Exploitation* en `scaleWith: targetStatus`, *Salve* en multi-coups) — complétées à 5 ou 6 ; les neuf passifs démasqués.
**À arbitrer** : Q12 (les élémentaires restent des Attaques — le brainstorm penche pour oui) ; Q11 si la vague 5 l'a laissée ouverte ; la variante « armure conservée » de D43 pour Sanctifié, ou rien ; les cartes qui complètent.
**Ne pas absorber** : *Forge de guerre* de Carnage (production de cartes, P-44 lot 3) ; les épines de Rempart (P-44 lot 2) ; P-16.
**Point propre au vérificateur** : le tutoriel tourne toujours avec `fireball` ; les neuf lots passent D45 et D50 ; aucun passif n'est resté masqué.
**Simulation** : relancer sur les neuf lots — la mesure de référence que P-16 reprendra.
**Ce que le joueur voit en `0.6.0`** : neuf passifs jouables, chacun avec son lot.
**La clôture du chantier**, par `memory-bank-sync` : P-43 et P-42 clos dans `docs/ROADMAP.md`, P-44 lot 1 clos ; **les trois cartes dues** (épines, `retain`, *Forge de guerre*) portées sur la ligne de P-44 ; les constats de P-16 mis à jour avec la mesure des neuf lots ; ce fichier passe en « chantier clos » et rejoint l'historique ; `activeContext.md` : le focus revient à la ROADMAP.

---

## 9. Les points ouverts

| # | Quoi | État |
|:---:|:---|:---|
| O1 | D34, le déclencheur de *Marque du Mage*, sans lot | **Vague 7**, avec le lot Marque ; ✅ graphe du brainstorm retouché le 01/10 |
| O2 | P-44 lot 4 absent du graphe du brainstorm | ✅ **Retouché le 01/10** ; le lot lui-même est hors périmètre |
| O3 | La composition des tranches 2 et 3 | **Fixée par défaut** : Croisé, Vampire, Voile puis Sanctifié, Carnage, Marque ; re-arbitrable en vague 6 |
| O4 | Arcaniste sans carte multi-coups | **Vague 5** |
| O5 | Le masquage des six passifs | **Vague 5**, à arbitrer ; proposition en §8.5 |
| O6 | Le numéro de version | ✅ **Tranché le 01/10** : `0.5.3` à `0.6.0`, §1 |
| O7 | La ROADMAP à redécouper | ✅ **Fait le 01/10** (ADR-102) |
| O8 | Le commit du dossier | ✅ **Fait le 01/10** |

---

*Orchestration. Ce fichier fait foi pour le déroulé ; le brainstorm v3 pour les décisions. Prochaine étape : la vague 1, par le prompt de §0.*
