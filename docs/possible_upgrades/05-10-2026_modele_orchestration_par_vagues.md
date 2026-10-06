# Modèle — l'orchestration d'un chantier livré par vagues

**Date** : 05/10/2026 — **réorganisé le 06/10** autour d'un répertoire par chantier, à la demande du propriétaire.
**Rôle** : ce qu'il faut pour ouvrir et dérouler un chantier livré par vagues. On y trouve les couches, l'arborescence, les fichiers à copier, les changements de méthode, les agents, l'outillage, puis l'adoption et la migration du chantier en cours.
**Origine** : le [fichier d'orchestration du chantier en cours](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), dont il garde l'ossature, et l'[audit du 05/10](05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md), dont il intègre les recommandations. **★Rn** marque ce qui diffère du fichier actuel et renvoie à la recommandation n de l'audit (§4). Le découpage en couches et en répertoires développe R6 ; R14 à R18 et la correction de R1 viennent de la seconde passe de l'audit (§6, 06/10).
**Statut** : proposition. **Rien n'est adopté** : le fichier du chantier en cours reste la seule référence de ce chantier, et aucun des répertoires décrits ici n'existe encore. §8 dit comment adopter le modèle, en tout ou en partie.

**Comment le lire** :

| § | Contenu |
|:---|:---|
| 1 | Les cinq couches : qui porte quoi |
| 2 | L'arborescence `docs/chantiers/` |
| 3 | Ouvrir un chantier, dans l'ordre |
| 4 | Les fichiers à copier : `orchestration.md`, `etat.json`, `fiche.md`, `compte-rendu.md`, `suivi.md` |
| 5 | La méthode : ce qui change dans le cycle actuel |
| 6 | Les agents et leurs gabarits |
| 7 | L'outillage — des esquisses, rien n'est installé |
| 8 | L'adoption, et la migration du chantier en cours |

---

## 1. Les cinq couches ★R6

Le fichier actuel mêle, en 636 lignes, une méthode qui ne change pas d'un chantier à l'autre, les gabarits des agents, l'état du chantier et les fiches de toutes ses vagues. Chaque session relit le tout. Le modèle range ces contenus en cinq couches, chacune à sa place.

| Couche | Où | Ce qu'elle porte | Qui l'écrit | Quand elle change |
|:---|:---|:---|:---|:---|
| **Agents** | `.claude/agents/<rôle>.md` | Un fichier par rôle : sa mission, ses outils, son modèle, ses consignes fixes | Le propriétaire, par un ADR | Rarement |
| **Méthode** | `.claude/skills/orchestration-par-vagues/` | Le cycle d'une vague, les portes, l'arbre de décision générique, les garde-fous de jugement, les arrêts | Le propriétaire, par un ADR ; le skill porte un numéro de version | Rarement |
| **Outillage** | `tool/vagues/`, `.claude/hooks/` | Les scripts (porte d'entrée, mesure de session, vérification des références) et les hooks (garde-fou, état à l'ouverture) | Une tâche de plan, avec ses tests | Rarement |
| **Chantier** | `docs/chantiers/<chantier>/` | L'ordre des vagues et sa raison, l'état, le journal, la cohérence, l'oracle, le récit non technique | La vague 0, puis chaque vague pour l'état et le journal | À l'ouverture, puis à chaque étape (l'état) ou à chaque jalon (le journal) |
| **Vague** | `docs/chantiers/<chantier>/vagues/<NN>-…/` | La fiche, les specs, les plans, le compte rendu | La vague 0 pour la fiche, l'éclaireur pour sa mise à jour, la vague elle-même pour le reste | Pendant la vague, puis plus jamais, sauf par une session de correction |

**Ce qu'une session d'orchestrateur lit, avant et après** :

| | Aujourd'hui | Avec les couches |
|:---|:---|:---|
| La méthode | Les §3 à §6 du fichier, environ 280 lignes, gabarits compris | Le `SKILL.md`, plus court : les gabarits partent dans les fichiers d'agents, que seuls les sous-agents lisent, et les garde-fous mécaniques dans les hooks |
| Le chantier | Les §0 à §2 et §7 du fichier, dont un journal aux cellules de plus de 200 mots | `etat.json` (une quinzaine de lignes) et `orchestration.md`, au journal réduit aux jalons |
| Les fiches | Les neuf fiches, environ 180 lignes | La seule fiche de sa vague |

Le total devrait tomber à environ la moitié de ce qu'une session lit aujourd'hui. C'est une estimation, à vérifier par la mesure de session (§7.4). Surtout, chaque session ne lit plus que ce qui la concerne. Le relais de l'orchestrateur à chaque fin de plan (★R17) empêche en plus son contexte de grandir pendant toute une vague.

---

## 2. L'arborescence ★R6

```
docs/chantiers/
├── _modele/                                   # ce qu'on copie pour ouvrir un chantier (§4)
│   ├── orchestration.md
│   ├── etat.json
│   ├── suivi.md
│   └── vagues/
│       └── NN-vX.Y.Z-nom/
│           ├── fiche.md
│           └── compte-rendu.md
├── economie-et-catalogue/                     # un chantier = un dossier
│   ├── orchestration.md                       # comment et quand : vagues, ordre, journal, cohérence, oracle
│   ├── etat.json                              # où en est le chantier, lu par les scripts et les hooks
│   ├── suivi.md                               # ce que chaque vague apporte au jeu, sans technique
│   └── vagues/
│       ├── 00-methode/                        # vague sans version
│       │   └── fiche.md
│       ├── 01-v0.5.3-puissance-et-runes/
│       │   ├── fiche.md
│       │   ├── spec-p43-e0.md
│       │   ├── spec-p43-e1.md
│       │   ├── plan-p43-e0.md
│       │   ├── plan-p43-e1.md
│       │   └── compte-rendu.md
│       ├── 02-v0.5.4-fusion-forge/
│       │   ├── fiche.md
│       │   ├── spec-p43-e2.md
│       │   ├── plan-p43-e2-partie-1.md
│       │   ├── plan-p43-e2-partie-2.md
│       │   ├── verifications-p43-e2.md        # ★R15 options écartées, tours de vérification
│       │   └── compte-rendu.md
│       ├── …
│       └── cloture/
│           └── fiche.md
└── <prochain-chantier>/
```

**Les règles de nommage**

- **Le dossier d'un chantier** : son nom en minuscules, sans accent, les mots séparés par des tirets, sans date — `economie-et-catalogue`. Il vit aussi longtemps que le chantier, puis reste en place comme historique.
- **Le dossier d'une vague** : `<NN>-v<x.y.z>-<nom>`, où `NN` est le numéro de la vague sur deux chiffres. La vague 0 s'écrit `00-<nom>`, la clôture `cloture`.
  - Le numéro vient d'abord : il ne change jamais et garde l'ordre de tri. Une version peut se décaler si un correctif s'intercale entre deux vagues (c'est un cas d'arrêt du fichier actuel, §6) ; on renomme alors le dossier par `git mv`, et c'est le seul cas où un dossier de vague change de nom.
- **Les specs et les plans** portent l'identifiant de leur lot : `spec-<lot>.md`, `plan-<lot>.md`, `plan-<lot>-partie-<k>.md`, par exemple `plan-p43-e3-partie-1.md`.
  - Ce nom est unique dans tout le dépôt, et ce n'est pas un détail : SDD range son registre sous `.superpowers/sdd/<nom du plan>/`, et deux plans de même nom pourraient partager un registre.
  - La date n'est plus dans le nom : elle est dans l'en-tête du document et dans l'historique git.
- **Les vérifications** ★R15 : `verifications-<lot>.md` garde ce que la spec n'a pas à porter — les options écartées de chaque arbitrage, et le journal des tours de vérification de la spec et du plan. La spec ne garde que la décision retenue et sa raison.
- **Le compte rendu** s'appelle `compte-rendu.md`, un par vague. Une session de correction y ajoute sa section, elle n'ouvre pas de fichier.

**Ce qui reste hors du dossier d'un chantier**

| Contenu | Où | Pourquoi |
|:---|:---|:---|
| Le brainstorm, sa revue, le rapport de l'oracle | `docs/possible_upgrades/` | C'est de l'exploration, antérieure au chantier ; `orchestration.md` y renvoie depuis son en-tête |
| Le script de l'oracle et sa sortie de référence | `tool/` | C'est du code, qui passe `dart analyze` |
| Les ADR, les règles, les patterns | `.obsidian_vault/` | Ils survivent au chantier |
| La note de version | `assets/data/patch_notes.json` | Elle appartient à `patch-notes-writer` |
| Les specs et les plans hors chantier | `docs/superpowers/specs/` et `plans/`, comme aujourd'hui | Un travail isolé n'a pas besoin de dossier de chantier |

**Une question, un fichier**

| Question | Fichier |
|:---|:---|
| Où en est le chantier ? Quelle vague, quelle étape, quelle branche ? | `etat.json` |
| Dans quel ordre, et pourquoi ? Qu'est-ce qui a été livré, quand ? | `orchestration.md` |
| Que doit faire la vague N, et qu'est-ce que le propriétaire a déjà tranché pour elle ? | `vagues/<NN>-…/fiche.md` |
| Qu'a-t-elle décidé, livré, coûté ? Que faut-il tester ? | `vagues/<NN>-…/compte-rendu.md`, et ses specs |
| Quelles options a-t-on écartées ? Comment la spec a-t-elle convergé ? | `vagues/<NN>-…/verifications-<lot>.md` |
| Qu'apporte-t-elle au jeu ? | `suivi.md` |
| Comment une vague se déroule-t-elle ? | le skill `orchestration-par-vagues` |
| Pourquoi la méthode est-elle ainsi ? | les ADR de méthode |

---

## 3. Ouvrir un chantier, dans l'ordre

1. **Le brainstorm** fixe les décisions du propriétaire, numérotées `D1`… et dites acquises. C'est la source de vérité du *quoi*.
2. **La revue** confronte le brainstorm au code. ★R12 : l'agent qui vérifie contre le code reçoit d'abord des **questions neutres** (« comment le jeu calcule-t-il X ? »), sans les conclusions du brainstorm. La comparaison ne vient qu'ensuite. Les passes s'enchaînent jusqu'à zéro constat bloquant.
3. **L'oracle**, si le chantier touche des valeurs : une simulation, ou tout autre programme dont la sortie complète devient une référence suivie par git.
4. **Le dossier du chantier** : copier `docs/chantiers/_modele/` vers `docs/chantiers/<chantier>/`, puis :
   - remplir `orchestration.md` (§4.1) ;
   - créer **un dossier par vague, avec sa fiche** (§4.3), clôture comprise ;
   - initialiser `etat.json` sur la vague 0 (§4.2) ;
   - remplir l'en-tête et « Le chantier en quelques lignes » de `suivi.md`.
5. **La vague 0** :
   - la ROADMAP redécoupée, une ligne par chantier qui renvoie à son dossier ;
   - un ADR de méthode si le chantier s'écarte du skill ;
   - **une seule ligne dans `docs/INDEX.md`**, qui renvoie au dossier : les specs, plans et comptes rendus des vagues s'y trouvent, et le journal de `orchestration.md` les liste. L'index n'a plus à recevoir une ligne par document de vague.
   - `CLAUDE.md` ne bouge pas : sa table « Documentation Map » renvoie une fois pour toutes à `docs/chantiers/` (§8.2).
6. **Le rodage**, en session neuve, avant la vague 1 — c'est la « *shakedown cruise* » des migrations d'Anthropic, et ta sixième passe de revue. On rejoue la porte d'entrée de la vague 1, on remplit chaque gabarit de §6 avec la fiche 1, et on corrige ce qui accroche. Une passe suffit ; une seconde seulement si la première change le cycle.

---

## 4. Les fichiers à copier

Les `<…>` se remplissent, les commentaires HTML se retirent.

### 4.1. `orchestration.md`

Les sections gardent la numérotation du fichier actuel jusqu'à §2 ; les fiches en sortent. Le fichier devrait tenir en 150 à 250 lignes.

~~~~markdown
# Orchestration — <le chantier en clair>, de `<version de départ>` à `<version visée>`

**Date** : <JJ/MM/AAAA>
**Statut** : **ce fichier fait foi pour le déroulé du chantier** — l'ordre des vagues, ce que chacune livre, sa version. **L'état courant est dans [`etat.json`](etat.json)**, les fiches et les documents de chaque vague dans [`vagues/`](vagues/). **Les décisions de conception ne sont pas ici** : leur source de vérité est <lien vers le brainstorm>, §<n> (D1 à D<n>). En cas d'écart, le brainstorm a raison sur le *quoi*, ce fichier sur le *comment* et le *quand*.
**Méthode** : le skill `orchestration-par-vagues`, version <n>. Ce fichier n'en précise que ce qui est propre au chantier (§3).
**Périmètre** : <ce qui a été brainstormé>. Hors périmètre : <ce qui vient après>.
**Sources** : <brainstorm> ; <revue> ; <rapport de l'oracle et sa sortie de référence> ; `docs/ROADMAP.md` §<n>.
**Le récit non technique** : [`suivi.md`](suivi.md).
**Vérifié contre** : `main` à `<sha>` (<date>) — <N> tests verts, `dart analyze` propre. Rodé le <date> : <ce que le rodage a rejoué>.

---

## 0. Pour la session qui ouvre ce fichier

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.** Tu gardes le fil, pas le détail : tu délègues la rédaction, la vérification et l'implémentation aux agents de `.claude/agents/`, et tu n'implémentes rien toi-même.

1. Lis `CLAUDE.md`, puis ce fichier, puis <les sections du brainstorm à lire>.
2. **Trouve ta vague** — sur les branches d'abord, parce que l'état vit sur la branche de la vague :
   `git fetch` puis `git branch -a --list '<motif des branches de vague>' --no-merged origin/main`.
   - *Aucune branche ouverte* : bascule sur `main`, tire-le en avance rapide, lis `etat.json`. Ta vague est la suivante dans la table §1. Après la dernière vague, tu es la session de clôture.
   - *Une branche ouverte* : bascule dessus et lis `etat.json` **de la branche**.
     - `en_cours` : reprends à l'étape notée, sur un arbre propre, `dart analyze` propre, tests verts ;
     - `livree_sur_branche` : tu es une session de correction ;
     - `arret_ouvert` non nul : ne reprends que si le prompt dit ce qui a levé l'arrêt.
   - **Une reprise ne détruit rien** : un arbre sale se range par `git stash push -u`, un commit rouge se corrige par un commit.
3. **Lis la fiche de ta vague**, `vagues/<NN>-…/fiche.md`, et le compte rendu de la vague précédente : ses sections « Leçons » et « Pour la file ».
4. **Passe la porte d'entrée** : `tool/vagues/porte_entree.sh docs/chantiers/<chantier> <branche de la vague>` ★R5. Elle rend 0, ou la liste de ce qui échoue ; dans ce cas, arrête-toi et dis pourquoi.
5. **Déroule le cycle** du skill. Arbitre les questions de classe T. Celles de classe P t'arrivent tranchées dans la fiche, ou t'arrêtent ; celles de classe D t'arrêtent ★R3.
6. **Arrête-toi à la porte de sortie.** Tu ne pousses rien, n'ouvres pas de PR, ne fusionnes pas, ne poses pas de tag.

**Le prompt qui lance une vague** :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `docs/chantiers/<chantier>/orchestration.md` : ce fichier fait foi. Tu es l'orchestrateur d'une vague : trouve laquelle comme son §0 le dit, puis lis sa fiche. Déroule son cycle avec le skill `orchestration-par-vagues`, en déléguant aux agents du dépôt, arbitre selon le skill, respecte les garde-fous et arrête-toi à la porte de sortie. Autonomie : <strict | continu>. Réponds et écris en français.
````

**Le prompt d'une session de correction** :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `docs/chantiers/<chantier>/orchestration.md`. Tu ouvres une session de correction sur la vague livrée sur la branche courante : lis son compte rendu, puis corrige ce qui suit, sans rien rouvrir d'autre. <ce que le test a trouvé ; les arbitrages renversés>. Réponds et écris en français.
````

**Le prompt de l'éclaireur** ★R8 — à lancer pendant le test du propriétaire, sur la branche livrée :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `docs/chantiers/<chantier>/orchestration.md`. Tu es l'éclaireur de la vague suivante : utilise l'agent `eclaireur` sur sa fiche, `vagues/<NN+1>-…/fiche.md`. Il ne modifie que cette fiche, en un seul commit sur la branche courante. Ne pousse rien. Réponds et écris en français.
````

---

## 1. Les vagues et les versions

| Vague | Version | Dossier | Lots | Cérémonie ★R11 | Ce que le joueur voit | Dépend de | Branche | Critère de sortie — ce qui doit être VRAI |
|:---:|:---|:---|:---|:---|:---|:---|:---|:---|
| **0** | — | [`00-methode`](vagues/00-methode/) | Méthode et ROADMAP | — | Rien | — | `docs/vague-0-<chantier>` | La ROADMAP renvoie à ce dossier ; l'ADR de méthode est écrit |
| **1** | `<x.y.z>` | [`01-v<x.y.z>-<nom>`](vagues/01-v<x.y.z>-<nom>/) | <lots> | standard | <une phrase> | 0 | `feat/v<x.y.z>-<id>` | <deux ou trois faits, chacun avec sa commande ou son test> |
| … | | | | | | | | |
| **Clôture** | — | [`cloture`](vagues/cloture/) | — | — | Rien | la dernière | `docs/cloture-<chantier>` | Le journal, la mémoire, la ROADMAP et le suivi disent le chantier clos |

**Un lot est ce qui reçoit une spec.** <Ce qui, dans ce chantier, n'est pas un lot au sens du cycle.>

**Pourquoi cet ordre.** <Une phrase par dépendance : ce que la vague N+1 lit de la vague N.>

**Dans une vague, tout se déroule en série.** Un lot après l'autre, une partie après l'autre : le document suivant s'écrit sur le code que le précédent a laissé sur la branche, jamais sur une prévision.

---

## 2. Le journal, les arrêts, le tableau de bord

**L'étape fine n'est pas ici** : elle est dans `etat.json`, que chaque étape réécrit. **Le journal ne bouge qu'aux jalons** :
- à l'ouverture d'une vague : elle passe à « en cours », la précédente à « close » ;
- à sa livraison : elle passe à « livrée sur branche » ;
- à une session de correction : la date de la correction s'ajoute.

Chaque mise à jour se commite sur la branche de la vague, dans le commit du document qu'elle accompagne.

| Vague | Version | État | Tests (base → total) | Compte rendu | Livrée le | Close le |
|:---:|:---|:---|---:|:---|:---|:---|
| 0 | — | à faire | — | — | — | — |

**Les arrêts** — une ligne par arrêt, **une ligne de texte par cellule**. Le récit, les constats ouverts et les recommandations vont dans le compte rendu de la vague, qui s'ouvre au premier arrêt s'il n'existe pas encore.

| Vague | Date | Étape | Classe (P · D · autre) | Motif | Levée |
|:---:|:---|:---|:---|:---|:---|

**Le tableau de bord** ★R9 — une ligne par vague livrée, remplie à la fin de la vague depuis `tool/vagues/mesure_session` ★R5. C'est ce tableau qui dit si la méthode dérive.

| Vague | Coût (API) | Durée | Agents | Tours de spec | Tours de plan | Arrêts | Lignes de plan / lignes de code | Défauts au test du propriétaire | Leçon principale |
|:---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|

---

## 3. Ce que ce chantier précise de la méthode

- **Les filtres 1 à 3 de l'arbre de décision** : <les décisions acquises, et ce qu'elles interdisent> ; <les valeurs mesurées, et ce qui en change une> ; <les principes du brainstorm>.
- **L'oracle** : <la commande, sa durée, sa référence, ce qui l'arrête>.
- **Les contraintes du dépôt que les hooks ne couvrent pas** : <données bilingues, fichiers générés, `flutter gen-l10n`…>.
- **Les exceptions aux garde-fous** : <aucune, ou lesquelles et pourquoi>.

---

## 4. La cohérence des lots — vérifiée le <date>

### 4.1. Chaque décision a une vague

| Famille | Décisions | Lot | Vague |
|:---|:---|:---|:---:|

**Vérifié par commande** : chaque `D<n>` du brainstorm apparaît dans au moins une `fiche.md` de `vagues/`, ou sur la ligne « Après `<version visée>` » ou « Méthode » de cette table. Une décision sans vague bloque la vague 1 — c'est la barrière de couverture de GSD.

### 4.2. Les transitions entre lots

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|

### 4.3. Ce que l'oracle impose

<Ce que l'oracle lit, ce qu'il tient en dur, et pour chaque vague : ce qui casse ou dérive, et ce que le plan doit réaligner.>

---

## 5. Les points ouverts

<Ce qui reste à trancher et n'appartient à aucune vague, avec qui le tranche et quand.>

## 6. Les leçons et les amendements proposés ★R9

Une ligne par leçon retenue par une vague : **non évidente, durable, qui change quelque chose**. Les autres restent dans le compte rendu.

| Vague | Leçon | Ce qu'elle propose | Décision du propriétaire |
|:---:|:---|:---|:---|
| <N> | <la leçon, une phrase> | amender le skill §<n> · un agent · une ligne de `CLAUDE.md` · rien | <acceptée le JJ/MM · refusée · en attente> |
~~~~

### 4.2. `etat.json` ★R7

L'état courant du chantier, pour les machines : le script de porte d'entrée, les hooks, et toute session qui ouvre le chantier. Un exemple, avec les valeurs qu'aurait aujourd'hui le chantier en cours sur la branche de sa vague 3 :

```json
{
  "chantier": "economie-et-catalogue",
  "methode": "orchestration-par-vagues@1",
  "chantier_clos": false,
  "vague": 3,
  "dossier": "vagues/03-v0.5.5-trouvaille",
  "branche": "feat/v0.5.5-p43-e3-trouvaille",
  "version_du_jeu": "0.5.5",
  "etat": "livree_sur_branche",
  "etape": "3.8 · fait",
  "base_tests": 1480,
  "total_tests": 1625,
  "autonomie": "strict",
  "arret_ouvert": null,
  "outillage": { "superpowers": null, "claude_code": null },
  "maj": "2026-10-04"
}
```

| Champ | Valeurs | Sens |
|:---|:---|:---|
| `version_du_jeu` | `"x.y.z"` | La version du jeu **à la sortie** de la vague courante. Pour une vague sans version, c'est celle d'avant (la vague 0 du chantier en cours aurait `"0.5.2"`). La porte d'entrée de la vague suivante vérifie que son tag est dans `main` |
| `etat` | `en_cours` · `livree_sur_branche` · `faite` | `faite` pour une vague sans version (vague 0, clôture). Une vague passe « close » dans le journal, à l'ouverture de la suivante ; `etat.json` pointe alors déjà sur la suivante |
| `etape` | `"<lot> · <3.x> · <fait \| en cours>"` | Le grain fin que le journal ne porte plus |
| `autonomie` | `strict` · `continu` | Fixée par le prompt de lancement, recopiée ici pour une reprise ★R3 |
| `arret_ouvert` | `null` · `"<JJ/MM> · <étape> · <classe> · <motif en une ligne>"` | Le détail est dans le compte rendu |
| `chantier_clos` | `false` · `true` | Passé à `true` par la session de clôture, seule |
| `outillage` | `{ "superpowers": "<version ou sha>", "claude_code": "<version>" }` | ★R14 Relevé à l'ouverture du chantier, affiché par la porte d'entrée, recopié au §1 de chaque compte rendu ; ne change qu'entre deux chantiers. `null` dans l'exemple : aucune vague ne l'a relevé à ce jour |

**Les règles** :
- seul l'orchestrateur l'écrit, à chaque étape, dans le commit du document que l'étape produit, sur la branche de la vague ;
- on ne retire jamais un champ ;
- la porte d'entrée le valide (`jq empty`) avant tout le reste.

### 4.3. `vagues/<NN>-…/fiche.md`

Écrite à l'ouverture du chantier, pour chaque vague. L'éclaireur la met à jour avant que la vague s'ouvre ★R8. Ensuite, plus personne n'y touche : ce que la vague a fait est dans son compte rendu.

~~~~markdown
# Vague <N> — `<version>` — <lots>

**Cérémonie** : léger | standard | lourd ★R11 — **Tâches à risque** : <celles dont le plan écrit le code entier, et que le vérificateur rejoue> ★R1
**Mesurée le** : <JJ/MM, sur `<sha>`> — **éclairée le** : <JJ/MM, sur `<sha>`, ses prémisses corrigées en une ligne> ★R8

## <Lot> — <titre>

**Fichiers** : `spec-<lot>.md` et `plan-<lot>.md` (ou `plan-<lot>-partie-<k>.md`), dans ce dossier.
**Décisions** : D<n>, D<m> — avec les réserves que la fiche leur met.
**À lire** : <chemins>.
**État mesuré** ★R10 — par symbole, pas par ligne :
- `lib/<chemin>.dart › <Classe>.<méthode>` — <ce qu'il fait aujourd'hui>.

**La spec doit fixer** : <liste>.
**Critères de sortie** — ce qui doit être VRAI à la fin du lot, chacun avec sa preuve :
- <fait> — <test nommé ou commande, et ce qu'elle rend>.

**À arbitrer** ★R3 :

| # | Question | Classe | Options | Recommandation de l'éclaireur | Réponse du propriétaire (classe P) |
|:---:|:---|:---:|:---|:---|:---|

**Ne pas absorber** : <ce qui appartient à un lot voisin ou à plus tard>.
**Transitions** : <les lignes de `orchestration.md` §4.2 qui concernent ce lot>.
**Oracle** : <ce que le lot ne doit pas toucher sans relance ; ce que le plan réaligne>.
**Pour `memory-bank-sync`** : ADR <à ouvrir ou à amender> ; fiches <_rules et _patterns> — un minimum.
**Ce que le joueur voit** : <ce que la note de version et le suivi diront>.
~~~~

### 4.4. `vagues/<NN>-…/compte-rendu.md`

Ouvert à la fin du premier plan, par sa table des arbitrages — SDD supprime son registre de décisions à la fin de chaque plan. Complété à la fin de la vague. Les sections sont celles des trois comptes rendus existants, plus deux ★.

~~~~markdown
# Vague <N> — `<version>` — <lots> — compte rendu

**Chantier** : [orchestration](../../orchestration.md) · **Fiche** : [fiche.md](fiche.md) · **Vérifications** : `verifications-<lot>.md` · **Branche** : `<branche>`

## 0. Pour le propriétaire — une page ★R16
<!-- trente lignes au plus : ce qu'il faut tester d'abord, par risque ; les arbitrages que le joueur verra ; ceux faits sans toi ; les risques connus ; les trois commandes qui rejouent l'essentiel -->
## 1. La branche et ses chiffres
<!-- ★R14 avec les versions de l'outillage -->
## 2. La table des arbitrages
<!-- par spec, par plan, puis les décisions de SDD, plan après plan — une ligne par arbitrage, le détail et les options écartées restant dans verifications-<lot>.md ★R15 ; ★R3 les arbitrages faits sans le propriétaire, en autonomie « continu », dans une sous-section à part ; ★R17 une passation de dix lignes à chaque fin de plan, si l'orchestrateur est relayé -->
## 3. Le cahier de test manuel
## 4. L'oracle
## 5. Trouvé périmé, et pour la file
## 6. Les leçons ★R9
<!-- cinq au plus, chacune : la leçon, la preuve, l'amendement proposé (skill, agent, CLAUDE.md, ou rien) -->
## 7. Les statistiques de la session
<!-- produites par `tool/vagues/mesure_session` ★R5 — mêmes définitions à chaque vague ; plus une ligne : les défauts remontés par le test du propriétaire -->
## Corrections du <JJ/MM/AAAA>
<!-- une section par session de correction, qui finit par ses propres statistiques -->
~~~~

### 4.5. `suivi.md`

Inchangé sur le fond : c'est le squelette de §5 de `docs/suivi_vagues_chantier/_modele_suivi.md`. Les règles d'écriture de ce modèle (§1 à §4) deviennent `docs/chantiers/_modele/suivi.md`. Deux retouches seulement : l'en-tête renvoie à `orchestration.md` du même dossier, et le fichier ne porte plus le nom du chantier, puisque son dossier le porte.

---

## 5. La méthode : ce qui change dans le cycle actuel

Le cycle du fichier actuel (§3.1 à §3.10) devient le corps du skill `orchestration-par-vagues`. Ses étapes ne changent pas ; voici ce qui change dans chacune.

| Étape | Aujourd'hui | Avec le modèle |
|:---|:---|:---|
| **Lecture d'ouverture** | Tout le fichier d'orchestration | ★R6 `etat.json`, `orchestration.md`, la fiche de la vague, et les leçons de la vague précédente |
| **3.1 Porte d'entrée** | Neuf vérifications rejouées une à une par le modèle | ★R5 `tool/vagues/porte_entree.sh`, qui valide aussi `etat.json` et vérifie que la branche annoncée figure dans la table des vagues (§7.3) |
| **3.2 Branche** | Créer la branche ; journal à « en cours », précédente à « close » | Inchangé. Plus `etat.json` pointé sur la nouvelle vague, dans le même premier commit. Le dossier de la vague existe déjà depuis l'ouverture du chantier |
| **3.3 Spec** | Rédiger → vérifier tout → corriger → revérifier tout, trois tours, puis arrêt ; écrite dans `docs/superpowers/specs/` | La spec s'écrit **dans le dossier de la vague**, `spec-<lot>.md`.<br>★R5 `tool/vagues/verifier_references` avant toute vérification.<br>★R2 Le premier tour vérifie tout, les suivants seulement les corrections et ce qu'elles touchent ; la grille de gravité a ses critères ; un trou de test descend au *Review Focus* du plan.<br>★R3 Après trois tours : en *strict*, l'arrêt ; en *continu*, la correction des constats de classe T, consignée, puis un dernier tour différentiel |
| **3.4 Plan** | Le code de chaque tâche écrit en entier, rejoué dans un clone ; écrit dans `docs/superpowers/plans/` | Le plan s'écrit **dans le dossier de la vague**, `plan-<lot>[-partie-<k>].md`.<br>★R1 Il consigne des décisions : fichiers, signatures, valeurs, tests nommés et leur assertion, commande de vérification, total attendu. Le code n'est écrit en entier que pour les tâches à risque de la fiche.<br>Une section *Review Focus* en tête ; une auto-revue de longueur (au-delà du triple de la spec, c'est une transcription) |
| **Historique de la spec** | Dans la spec : options écartées (§1.2), journal des tours (§13) | ★R15 Dans `verifications-<lot>.md` ; la spec ne garde que la décision retenue et sa raison, et le vérificateur ne lit ce fichier qu'en mode différentiel |
| **3.5 Implémentation** | SDD ; dix contraintes recopiées à chaque agent | Inchangé sur le fond. ★R4 Les contraintes que le hook `garde_vague` garantit sortent des gabarits ; restent celles qu'aucun outil ne vérifie |
| **Fin de plan** (`3.5 · fait`) | L'orchestrateur continue, son contexte grandit | ★R17 Passation de dix lignes au compte rendu, `etat.json` à jour, fin de session ; le même prompt relance la suite, par la reprise de §0 |
| **3.6 bis Convergence** | — | ★R13 Un agent relit les décisions de chaque spec face au code de la branche ; ses écarts deviennent une tâche ou un constat consigné |
| **3.8 Compte rendu** | Un fichier dans `docs/superpowers/reports/` ; les statistiques mesurées par un script réécrit à chaque vague | `compte-rendu.md` **dans le dossier de la vague**.<br>★R5 `tool/vagues/mesure_session` pour les statistiques.<br>★R9 La section « Leçons » ; la ligne de la vague au tableau de bord de `orchestration.md` |
| **3.9 Porte de sortie** | L'arrêt | Inchangé, plus ★R8 : le propriétaire lance l'éclaireur de la vague suivante pendant qu'il teste |
| **Arrêt, livraison** | Rien ne prévient le propriétaire | ★R18 Le hook `prevenir` lui envoie un message (§7.6) |
| **Arbitrage** | Arbre à 8 filtres | ★R3 Une classe par question avant l'arbre : **T**, technique, tranchée par l'orchestrateur ; **P**, visible du joueur, tranchée par le propriétaire, de préférence dans la fiche avant la vague ; **D**, qui amende une décision acquise : arrêt |
| **Garde-fous** | Texte | ★R4 `main` protégé sur GitHub ; le hook `garde_vague` ; ne restent en texte que les garde-fous de jugement |

---

## 6. Les agents et leurs gabarits ★R6

Chaque rôle devient un fichier de `.claude/agents/`. Sa partie fixe (mission, méthode, grille, format de sortie) vit dans le fichier ; sa partie variable (le lot, les chemins, les décisions, le mode) arrive par le message de l'orchestrateur.

**Règles communes**, inchangées :
- un agent part d'un contexte neuf, et reçoit tout ce qu'il lui faut par chemin de fichier ;
- le vérificateur n'est jamais le rédacteur ;
- un constat se prouve par une commande ou une citation ;
- l'orchestrateur ne garde de chaque agent que sa conclusion.

| Agent | Modèle | Outils | Reçoit | Écrit | Rend |
|:---|:---|:---|:---|:---|:---|
| `redacteur-spec` | le plus capable | lecture, Bash, édition | la fiche, le dossier de la vague | `spec-<lot>.md` | le chemin, la table des arbitrages |
| `verificateur-spec` | le plus capable | lecture, Bash, aucun outil d'édition | la spec, la fiche, le mode (complet ou différentiel) | rien | la table de constats, « prête » ou « à corriger » |
| `redacteur-plan` | le plus capable | lecture, Bash, édition | la spec, la base de tests, les tâches à risque | `plan-<lot>….md` | le chemin, la carte des fichiers, le rapport de longueur |
| `verificateur-plan` | le plus capable | lecture, Bash, aucun outil d'édition ; un clone jetable | le plan, la spec, la base de tests | rien | la table de constats, « prêt » ou « à corriger » |
| `correcteur` | le plus capable | lecture, Bash, édition | le document et les constats | le document | les constats traités, un par un |
| implémenteur, relecteur | intermédiaire | ceux de SDD | la fiche de tâche de SDD | le code | ceux de SDD |
| `verificateur-convergence` ★R13 | le plus capable | lecture, Bash, aucun outil d'édition | les specs de la vague, la branche | rien | la table des écarts |
| `eclaireur` ★R8 | le plus capable | lecture, Bash, édition de la seule fiche | la fiche N+1, la branche N | `fiche.md` de la vague N+1 | les prémisses corrigées, les questions P |

Les gabarits du fichier actuel (§4.1, rédacteur de spec ; §4.5, skills de fin ; §4.6, correcteur) restent la base, avec les chemins du dossier de la vague. Les quatre qui suivent changent sur le fond.

### 6.1. `verificateur-spec` ★R2

````
Tu vérifies une spec que tu n'as pas écrite. Lis `CLAUDE.md` d'abord. Tu ne modifies aucun fichier.

La spec : <dossier de la vague>/spec-<lot>.md. La fiche : <dossier de la vague>/fiche.md. Les décisions du lot : <liste D, avec leurs réserves>, texte dans <brainstorm> §<n>.
Mode : <complet — tout le document | différentiel — seulement les corrections listées ci-dessous et ce qu'elles touchent>.
<En différentiel : les corrections du tour précédent, avec les sections modifiées ; les arbitrages déjà tranchés par l'orchestrateur — ne les rouvre pas sans preuve neuve.>

Commence par lancer `tool/vagues/verifier_references <chemin de la spec>` et reporte ce qu'il rend.

Vérifie, chaque point par une commande ou une citation, jamais de mémoire :
1. Chaque décision du lot est couverte dans la part que la fiche lui donne, et aucune n'est contredite — cite la ligne du brainstorm.
2. Chaque item de « La spec doit fixer » est fixé, et chaque critère de sortie de la fiche a sa preuve prévue.
3. Chaque question de « À arbitrer » est tranchée, avec ses options, sa classe et son motif ; les réponses du propriétaire aux questions de classe P sont reprises telles quelles ; aucun arbitrage n'amende une décision acquise ni ne change une valeur mesurée.
4. Rien de « Ne pas absorber » n'y est entré ; les transitions avec les lots voisins sont traitées.
5. Les règles du dépôt tiennent : trois couches, donnée bilingue, id = nom de fichier, un fait à un seul endroit, pas de code sans lecteur.
6. <Le point propre au lot, donné par la fiche.>

La gravité suit cette grille, et rien d'autre :
- bloquant — contredit une décision acquise, ou rend l'implémentation impossible telle qu'écrite ;
- moyen — produirait un comportement faux, ou un test rouge, que le plan n'aurait aucune raison de voir ;
- mineur — imprécis, mais le plan le résoudra sans risque ;
- rédaction — la forme seulement.
Un test qui manque n'est pas un constat de spec : liste-le à part, sous « Pour le Review Focus du plan ».
Ne signale que ce qui touche la correction ou les exigences du lot. Une préférence n'est pas un constat.

Rends une table : numéro, où, constat, preuve, gravité, classe (T · P · D), correction proposée. Puis la liste « Pour le Review Focus du plan ». Puis une ligne : « prête » ou « à corriger ».
````

**Le consolidateur d'un panel**, quand il y en a un, reçoit en plus : « Tu ne relèves la gravité d'un constat qu'avec une preuve que tu as reproduite par une commande ; écris laquelle. »

### 6.2. `redacteur-plan` ★R1

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis `<dossier de la vague>/spec-<lot>.md` <§ de la partie>, dans `<dossier de la vague>/plan-<lot>[-partie-<k>].md`. Modèle de forme : `<plan de référence, lui-même un plan de décisions>` — but, architecture, contraintes globales, Review Focus, carte des fichiers, tâches titrées `### Task N: …`.

Le plan consigne des décisions, il ne transcrit pas le code. Pour chaque tâche :
- les fichiers touchés ;
- les signatures exactes de ce qui se crée ou change ;
- les valeurs que la spec impose ;
- les tests nommés, chacun avec son assertion clé ;
- la commande de vérification et ce qu'elle doit rendre ;
- le total de tests attendu : <N>, plus les tests ajoutés, moins les retirés.
Le code s'écrit en entier dans deux cas seulement : les tâches à risque — <liste de la fiche> — et un algorithme que la spec impose ligne à ligne.

En tête du plan, une section « Review Focus » : au plus cinq modes d'échec que la spec implique et qu'aucun test ne garde encore, chacun confié à la tâche qui l'écrira. <Les trous de test remontés par la vérification de la spec : …>
Avant de rendre, compare la longueur du plan à celle de la spec : au-delà du triple, remplace les corps de code des tâches non risquées par leurs signatures et leurs assertions.

Le plan ne crée pas de branche, ne commite rien sur `main`, ne pousse rien, n'ouvre pas de PR, n'invoque aucun skill de livraison ni de synchronisation. Sa dernière tâche est la vérification finale. Rends le chemin du plan, sa carte des fichiers et sa longueur rapportée à celle de la spec.
````

**Le plan de référence compte autant que le gabarit** (audit §6.1). Celui que le fichier actuel cite, le plan de P-49, transcrit le code : 3 627 lignes, 249 blocs. Le citer comme modèle imposerait la transcription quoi que dise le gabarit. Le premier plan écrit selon ce gabarit et jugé bon devient la référence des suivants.

### 6.3. `verificateur-plan` ★R1

Celui du fichier actuel (§4.4), avec deux changements :
- « **rejoue dans un clone les seules tâches à risque** : <liste> ; pour les autres, vérifie que les signatures existent ou sont créées par une tâche antérieure, que les tests nommés gardent ce que la spec demande, et que le décompte des tests tombe juste » ;
- « **vérifie la section Review Focus** : chaque mode d'échec est attribué à une tâche, qui écrit le test qui le garde ».

### 6.4. `eclaireur` ★R8

````
Tu es l'éclaireur de la vague <N+1> du chantier `docs/chantiers/<chantier>/`. Lis `CLAUDE.md`, puis `orchestration.md`, puis la fiche `vagues/<NN+1>-…/fiche.md`. La vague <N> est livrée sur la branche courante et attend le test du propriétaire : c'est sur elle que tu mesures.

1. Re-mesure chaque ligne de « État mesuré » sur la branche courante, par commande. Corrige celles qui ont bougé, en citant le symbole plutôt que la ligne.
2. Liste les prémisses de la fiche que le code de la vague <N> rend fausses, et dis pour chacune si elle change le périmètre du lot.
3. Pour chaque question de « À arbitrer », donne sa classe (T · P · D). Pour chaque question de classe P, écris les options, ce que le joueur verrait avec chacune, et ta recommandation.
4. Ajoute les questions de classe P que la re-mesure fait apparaître, et remplis la ligne « éclairée le » de l'en-tête.

Tu ne modifies que cette fiche, en un seul commit sur la branche courante : il part dans `main` avec la vague <N>, sans PR de plus. Tu ne touches ni au code, ni à `etat.json`, ni au journal, et tu ne pousses rien. Rends les questions de classe P. Le propriétaire y répond dans la dernière colonne de la table « À arbitrer », avant la fusion.
````

### 6.5. `verificateur-convergence` ★R13

````
Tu vérifies qu'une vague livre ce que ses specs décident. Lis `CLAUDE.md`. Tu ne modifies aucun fichier.

Les specs : `<dossier de la vague>/spec-*.md`, sections « Décisions » et « Critères de sortie ». La branche : <branche>, depuis `<commit de départ de la vague>`.

Pour chaque décision et chaque critère de sortie : trouve le code et le test qui le portent, par une commande, et dis « livré », « partiel » ou « absent ». Puis cherche l'inverse : un comportement neuf du diff qu'aucune ligne des specs ne demande.
Ne juge ni le style ni la structure : la revue d'ensemble de SDD l'a fait.

Rends une table : décision ou critère, verdict, preuve, et pour chaque « partiel » ou « absent » la correction proposée. Puis la liste du code sans ligne de spec.
````

---

## 7. L'outillage — des esquisses

**Rien de cette section n'est installé.** Chaque esquisse s'adopte par une tâche de plan, avec ses tests, et se valide contre la documentation de Claude Code du jour ([hooks](https://code.claude.com/docs/en/hooks), [sub-agents](https://code.claude.com/docs/en/sub-agents), [skills](https://code.claude.com/docs/en/skills)).

### 7.1. Un fichier d'agent

`.claude/agents/verificateur-spec.md` :

```markdown
---
name: verificateur-spec
description: Vérifie une spec de lot qu'il n'a pas écrite, contre le brainstorm et le code de la branche, et rend une table de constats prouvés. À utiliser à l'étape 3.3 d'une vague.
tools: Read, Grep, Glob, Bash
model: <le plus capable>
---
<Le corps du gabarit §6.1, sans ses parties variables : elles arrivent par le message de l'orchestrateur.>
```

Sans `Write` ni `Edit` dans `tools`, l'agent n'a plus d'outil d'édition. Il garde `Bash`, nécessaire à ses preuves par commande, et `Bash` peut écrire : une règle de permission ou un hook propre à l'agent ferme ce reste, si l'expérience montre qu'il le faut.

### 7.2. Le hook `garde_vague` ★R4

`.claude/hooks/garde_vague.sh` — testé le 05/10 sur un dépôt jetable :
- **bloqués** : `git push`, `git add .`, `git add -A`, `dart format`, `gh pr create`, `git reset --hard`, `git worktree add`, `git clean` ;
- **laissés passer** : `git add <chemin>`, `git tag -l`, `dart analyze`, `gh pr view`, `git reset HEAD~1`, et tout ce qui se fait hors d'une branche de vague.

```bash
#!/usr/bin/env bash
# Bloque les gestes de livraison quand la branche courante est une branche de vague.
cmd=$(jq -r '.tool_input.command // empty')
branche=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null)
case "$branche" in
  feat/v[0-9]*|docs/cloture-*) ;;
  *) exit 0 ;;
esac
interdit='(^|[;&|[:space:]])(git[[:space:]]+(push|clean|worktree[[:space:]]+add|reset[[:space:]]+--hard|add[[:space:]]+(-A|--all|\.)([[:space:]]|$))|gh[[:space:]]+(pr[[:space:]]+(create|merge)|release)|dart[[:space:]]+format)'
if printf '%s' "$cmd" | grep -Eq "$interdit"; then
  echo "Garde-fou de vague : « $cmd » est interdit sur la branche $branche (skill orchestration-par-vagues, garde-fous)." >&2
  exit 2
fi
exit 0
```

**Pourquoi par branche et non par règle de permission** : une règle `deny` sur `git push` dans les réglages du projet bloquerait aussi les sessions qui doivent pousser leur branche, comme les sessions cloud. Le hook ne mord que sur une branche de vague. Il ne remplace pas la **protection de `main` sur GitHub** (PR obligatoire, CI verte), qui est le vrai verrou de « jamais sur `main` ».

### 7.3. La porte d'entrée, qui lit `etat.json` ★R5

Esquisse de `tool/vagues/porte_entree.sh`. Chaque ligne reprend une vérification de la table §3.1 du fichier actuel, plus deux qui viennent de l'arborescence.

```bash
#!/usr/bin/env bash
# Usage : tool/vagues/porte_entree.sh <dossier du chantier> <branche de la nouvelle vague>
set -u
dossier="$1"; branche="$2"; etat="$dossier/etat.json"; echec=0
ok() { printf '✅ %s\n' "$1"; }
ko() { printf '❌ %s\n' "$1"; echec=1; }

jq empty "$etat" 2>/dev/null || { ko "etat.json illisible : $etat"; exit 1; }
version=$(jq -r '.version_du_jeu' "$etat")
case "$(jq -r '.etat' "$etat")" in
  livree_sur_branche|faite) ok "vague $(jq -r '.vague' "$etat") fusionnée, jeu en $version" ;;
  *) ko "etat.json : la vague précédente n'est ni livrée ni faite" ;;
esac
grep -qF "\`$branche\`" "$dossier/orchestration.md" && ok "$branche figure dans la table des vagues" || ko "$branche absente de orchestration.md §1"
[ -z "$(git status --porcelain)" ] && ok "arbre propre" || ko "arbre sale — git status"
git fetch -q origin
[ "$(git rev-list --left-right --count main...origin/main)" = $'0\t0' ] && ok "main à jour" || ko "main et origin/main divergent"
[ -z "$(git branch -a --list "*$branche")" ] && ok "branche absente" || ko "$branche existe : vague commencée, voir §0"
git merge-base --is-ancestor "v$version" main 2>/dev/null && ok "v$version est dans main" || ko "tag v$version absent de main"
[ "$(gh run list --branch main --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null)" = "success" ] \
  && ok "CI de main verte" || ko "CI de main non verte, ou gh injoignable — demander au propriétaire"
bash .github/scripts/verify_version.sh "$version" >/dev/null && ok "porteurs de version à $version" || ko "porteurs de version discordants"
dart analyze >/dev/null 2>&1 && ok "dart analyze propre" || ko "dart analyze sale"
sortie=$(flutter test 2>&1); code=$?
total=$(printf '%s\n' "$sortie" | tail -1 | grep -oE '\+[0-9]+' | head -1 | tr -d '+')
[ "$code" -eq 0 ] && ok "flutter test vert — base : ${total:-?}" || ko "flutter test rouge"

exit "$echec"
```

La version à écrire attend un run de CI `queued` ou `in_progress` au lieu d'échouer, et contrôle aussi la release du tag. Elle saute le contrôle du tag quand la vague précédente est la vague 0 d'un chantier qui démarre sur une version déjà publiée.

### 7.4. Les autres scripts ★R5

- `tool/vagues/mesure_session` — les statistiques de §3.8 du fichier actuel, calculées depuis les transcriptions de Claude Code : temps, agents, jetons comptés une fois par message, coût. Mêmes définitions pour toutes les vagues ; il sort la ligne du tableau de bord et la section 7 du compte rendu.
- `tool/vagues/verifier_references` — chaque `chemin`, `chemin:ligne` et symbole `chemin › Classe.méthode` cité par un document existe sur la branche courante.

En Dart, sous `tool/`, ils passent `dart analyze` comme le script de simulation, et la section « Tooling » de `CLAUDE.md` les nomme.

### 7.5. L'état à l'ouverture de session — facultatif

Un hook `SessionStart` peut afficher l'état des chantiers ouverts, pour qu'une session sache où elle en est avant même de lire :

```bash
#!/usr/bin/env bash
# .claude/hooks/etat_chantiers.sh — affiche l'état des chantiers ouverts à l'ouverture de session.
for f in "${CLAUDE_PROJECT_DIR:-.}"/docs/chantiers/*/etat.json; do
  case "$f" in */_modele/*) continue ;; esac
  [ -e "$f" ] || continue
  jq -r 'select(.chantier_clos | not)
    | "Chantier \(.chantier) — vague \(.vague), jeu en \(.version_du_jeu) : \(.etat), étape \(.etape), branche \(.branche // "-")"' "$f"
done
exit 0
```

### 7.6. Prévenir le propriétaire ★R18

Un hook `Stop`, qui ne parle que lorsqu'un chantier s'arrête ou livre, et une seule fois par événement. **Il passe par un webhook dédié**, distinct de celui des releases, pour que les alertes de travail ne se mêlent pas aux annonces publiques. La messagerie est au choix, par deux variables d'environnement locales :

| `ALERTE_FORMAT` | `ALERTE_URL` | Ce qui est envoyé |
|:---|:---|:---|
| `discord` | l'URL du webhook du salon | `{"content": "<message>"}` |
| `slack` | l'URL de l'*incoming webhook* | `{"text": "<message>"}` |
| `texte` | toute URL qui accepte du texte brut en POST — par exemple un sujet [ntfy](https://ntfy.sh), qui notifie le téléphone | le message seul |

```bash
#!/usr/bin/env bash
# .claude/hooks/prevenir.sh — hook Stop : prévient le propriétaire quand un chantier s'arrête ou livre.
[ -n "${ALERTE_URL:-}" ] || exit 0
racine="${CLAUDE_PROJECT_DIR:-.}"
mkdir -p "$racine/.superpowers"
for f in "$racine"/docs/chantiers/*/etat.json; do
  case "$f" in */_modele/*) continue ;; esac
  [ -e "$f" ] || continue
  msg=$(jq -r 'if .arret_ouvert then "Arrêt — \(.chantier), vague \(.vague) : \(.arret_ouvert)"
               elif .etat == "livree_sur_branche" then "Livrée — \(.chantier), vague \(.vague), sur \(.branche) : à toi de tester"
               else empty end' "$f")
  [ -n "$msg" ] || continue
  vu="$racine/.superpowers/dernier_message_$(basename "$(dirname "$f")")"
  [ "$(cat "$vu" 2>/dev/null)" = "$msg" ] && continue
  printf '%s' "$msg" > "$vu"
  case "${ALERTE_FORMAT:-texte}" in
    discord) corps=$(jq -n --arg m "$msg" '{content: $m}'); type='application/json' ;;
    slack)   corps=$(jq -n --arg m "$msg" '{text: $m}');    type='application/json' ;;
    *)       corps="$msg";                                  type='text/plain; charset=utf-8' ;;
  esac
  printf '%s' "$corps" | curl -fsS -H "Content-Type: $type" --data-binary @- "$ALERTE_URL" >/dev/null || true
done
exit 0
```

`.superpowers/` est déjà ignoré par git. Le hook ne bloque jamais la fin d'un tour : il sort toujours en 0. L'URL du webhook est un secret : elle reste dans l'environnement local, jamais dans le dépôt.

### 7.7. Le skill de méthode ★R6

```
.claude/skills/orchestration-par-vagues/
├── SKILL.md                   # quand l'utiliser, le cycle 3.1 à 3.10, l'arbre générique, les arrêts — moins de 500 lignes
└── references/
    ├── grille-gravite.md      # la grille de §6.1, avec des exemples tirés des vagues passées
    └── compte-rendu.md        # ce que §3.8 écrit, et les définitions des statistiques
```

- Le frontmatter porte `disable-model-invocation: true` : une vague se lance par le prompt du propriétaire, jamais d'elle-même.
- Les gabarits ne sont pas dans le skill : ils sont dans les fichiers d'agents (§6), que l'orchestrateur n'a pas à lire.
- Le skill porte un numéro de version, que `orchestration.md` et `etat.json` citent. En changer en cours de chantier est un amendement de méthode, consigné par un ADR.

---

## 8. L'adoption, et la migration du chantier en cours

### 8.1. Ce qui peut s'appliquer dès la vague 4, sans toucher à l'arborescence

Les gains de coût ne dépendent pas des répertoires. L'audit (§5) propose un essai mesuré sur la vague 4, dans le fichier d'orchestration actuel :

| Changement | Où, dans le fichier actuel |
|:---|:---|
| R1 — plans de décisions | §3.4, §4.3, §4.4 ; la ligne « Tâches à risque » dans les fiches 8.4 à 8.7 |
| R2 — vérification de spec qui converge | §3.3, §4.2 |
| R3 — classes de questions, autonomie | §0 (prompt), §3.3, §5, §6 |
| R4 — hook et protection de `main` | `.claude/`, GitHub ; §3.5 et §6 allégés |
| R5 — scripts | §3.1, §3.8, par une tâche de plan |
| R9 — leçons et tableau de bord | §2, §3.8 |
| R8 — éclaireur, à partir de la vague 5 | §0, §3.9, §4 |
| R13 — convergence | entre §3.6 et §3.7 |
| R14 — l'outillage figé et noté, **avant la vague 4** | §3.1 (la porte l'affiche), §3.8 (le compte rendu le note) |
| R15 — l'historique hors de la spec | §3.3, §4.1, §4.2 |
| R16 — une page pour le propriétaire | §3.8 |
| R17 — le relais de l'orchestrateur, sur une vague, mesuré | §0, §3.5 |
| R18 — le hook `prevenir` | `.claude/hooks/`, sans toucher au fichier |

### 8.2. L'arborescence : quand, et comment

**Trois moments possibles :**

| Moment | Pour | Contre |
|:---|:---|:---|
| **A — à la session de clôture du chantier en cours** (recommandé) | Aucune vague ouverte, aucun conflit ; la clôture écrit déjà dans le journal, la mémoire, la ROADMAP et le suivi | Le gain de lecture (§1) ne profite pas aux vagues 4 à 7 |
| **B — entre deux vagues**, après la fusion de la vague N et avant le lancement de N+1 | Les vagues restantes lisent déjà moins | Le prompt de lancement change de chemin en plein chantier ; une branche de documentation de plus à fusionner ; le risque d'oublier un lien dans un document que la vague suivante lit |
| **C — seulement pour le prochain chantier** | Aucun déplacement de fichier | Deux rangements coexistent : l'ancien chantier dans `possible_upgrades/` et `superpowers/`, les suivants dans `docs/chantiers/` |

**Jamais pendant qu'une branche de vague est ouverte** : elle modifie le fichier d'orchestration (son journal), et la migration le déplace.

**La migration, en A ou en B :**

1. Créer `docs/chantiers/_modele/` depuis §4, et `docs/chantiers/economie-et-catalogue/`.
2. Déplacer par `git mv`, pour garder l'historique (`git log --follow`) :

   | Aujourd'hui | Demain |
   |:---|:---|
   | `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` | `docs/chantiers/economie-et-catalogue/orchestration.md` — ses fiches (§8) partent dans les `fiche.md`, son journal fin dans `etat.json` |
   | `docs/suivi_vagues_chantier/economie_unifiee_et_catalogue.md` | `docs/chantiers/economie-et-catalogue/suivi.md` |
   | `docs/suivi_vagues_chantier/_modele_suivi.md` | `docs/chantiers/_modele/suivi.md` |
   | `docs/superpowers/specs/2026-10-0x-p43-<lot>-…-design.md` | `docs/chantiers/economie-et-catalogue/vagues/<NN>-…/spec-p43-<lot>.md` |
   | `docs/superpowers/plans/2026-10-0x-p43-<lot>-…[-partie-k].md` | `…/vagues/<NN>-…/plan-p43-<lot>[-partie-k].md` |
   | `docs/superpowers/reports/2026-10-0x-economie-et-catalogue-vague-<N>-compte-rendu.md` | `…/vagues/<NN>-…/compte-rendu.md` |
   | `docs/superpowers/reports/README.md` | retiré : son contenu est dans ce modèle (§2 et §4.4) |
   | Ce modèle | réparti entre `docs/chantiers/_modele/` et le skill |

3. **Réécrire les liens.** Mesuré le 06/10 : **34 fichiers, 137 occurrences**, hors `_archive/` (qui n'en contient aucune). Ils se répartissent ainsi :
   - les ADR 102 à 107 et la fiche `_patterns/20-00` ;
   - `activeContext.md` et `progress.md` ;
   - `CLAUDE.md`, `docs/INDEX.md`, `docs/ROADMAP.md` ;
   - les specs, plans et comptes rendus eux-mêmes ;
   - le brainstorm, la revue, le rapport de simulation, le fichier d'orchestration lui-même et ces deux documents.

   Les retrouver : `grep -rlE "01-10-2026_orchestration_chantier|suivi_vagues_chantier/|superpowers/reports/|superpowers/specs/2026-10-0|superpowers/plans/2026-10-0" --include='*.md' .`
4. **`CLAUDE.md`, table « Documentation Map »** : les deux lignes du chantier en cours (« The programme in progress, wave by wave » et « What each wave of a programme brought to the game ») sont remplacées par une seule, valable pour tous les chantiers. Par exemple :
   > | A programme delivered by waves | `docs/chantiers/<chantier>/` — `orchestration.md` (how and when), `etat.json` (where it stands), `suivi.md` (what each wave brings to the game, in plain language), `vagues/<NN>-v<x.y.z>-<name>/` (each wave's brief, specs, plans and report). The method is the `orchestration-par-vagues` skill; its agents live in `.claude/agents/` |
5. **`docs/INDEX.md`** : les lignes du chantier (orchestration, suivi, specs, plans, comptes rendus des vagues 1 à 3) se réduisent à une ligne vers le dossier ; `docs/suivi_vagues_chantier/` disparaît de la légende.
6. **Le skill `memory-bank-sync`** : vérifier qu'il ne cite aucun des anciens chemins (aucune occurrence le 06/10).
7. **Contrôler** : la recherche de l'étape 3 ne rend plus rien hors de `_archive/` ; chaque lien relatif de `docs/` et du vault pointe vers un fichier existant ; `dart analyze` et `flutter test` sont inchangés, puisque rien sous `lib/`, `test/` ou `assets/` ne bouge.
8. **Un ADR** consigne le tout. Il amende ADR-102 et ADR-103 sur la méthode (R1 à R13 retenus), et pose l'arborescence.

### 8.3. L'ordre recommandé

1. **Maintenant** : décider de l'essai de la vague 4 (§8.1, R1 à R3), et protéger `main`.
2. **Pendant les vagues 4 à 7** : outiller (R4, R5), ajouter les leçons et le tableau de bord (R9), l'éclaireur (R8) et la convergence (R13). Mesurer chaque vague contre les précédentes.
3. **À la clôture** : migrer vers `docs/chantiers/` (§8.2, moment A), extraire le skill et les agents, écrire l'ADR.
4. **Au prochain chantier** : l'ouvrir directement dans `docs/chantiers/`, depuis `_modele/`.
