# Modèle — l'orchestration d'un chantier livré par vagues

**Date** : 05/10/2026 ; réorganisé le 06/10 (un répertoire par chantier) ; complété le 07/10 (skills, annexes A et B). **Condensé le 08/10** : même numérotation, gabarits, scripts et skills inchangés, moins de récit.
**Rôle** : ce qui s'installe ou se copie : couches, arborescence, fichiers à copier, changements de méthode, gabarits des agents, outillage, les deux skills, adoption et migration. **Comment tout cela fonctionne** est dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md) ; **pourquoi**, dans l'[audit](05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md), dont ★Rn cite les recommandations.
**Qui le lit** : le propriétaire, et la session qui installera la méthode (elle copie les annexes et le §7). Aucun agent de vague n'a à le charger.
**Origine** : le [fichier d'orchestration du chantier en cours](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), dont il garde l'ossature.
**Statut** : proposition. **Rien n'est adopté** ; aucun des répertoires décrits n'existe. §8 dit comment adopter, en tout ou en partie.

**Comment le lire** :

| § | Contenu |
|:---|:---|
| 1 | Les cinq couches : qui porte quoi |
| 1 bis | Le workflow en graphes → le guide |
| 2 | L'arborescence `docs/chantiers/` |
| 3 | Les phases du workflow → le guide |
| 4 | Les fichiers à copier : `orchestration.md`, `etat.json`, `fiche.md`, `compte-rendu.md`, `suivi.md`, `tests-manuels.md` |
| 5 | La méthode : ce qui change dans le cycle actuel |
| 6 | Les gabarits des agents |
| 7 | L'outillage — des esquisses, rien n'est installé |
| 8 | L'adoption, et la migration du chantier en cours |
| A | La phase 1 prête à installer : le `SKILL.md` d'`ouverture-de-chantier`, ses agents, le script de squelette |
| B | Le squelette du `SKILL.md` de `/vague`, pour la phase 2 |

---

## 1. Les cinq couches ★R6

Le fichier actuel mêle en 636 lignes la méthode, les gabarits, l'état et les fiches de toutes les vagues ; chaque session relit le tout. Cinq couches, chacune à sa place :

| Couche | Où | Ce qu'elle porte | Qui l'écrit | Quand elle change |
|:---|:---|:---|:---|:---|
| **Agents** | `.claude/agents/<rôle>.md` | Un fichier par rôle : sa mission, ses outils, son modèle, ses consignes fixes | Le propriétaire, par un ADR | Rarement |
| **Méthode** | `.claude/skills/ouverture-de-chantier/` (phase 1) et `.claude/skills/vague/` (phases 2 et 3) — la méthode garde son nom, `orchestration-par-vagues`, et sa version | Le cycle d'une vague, les portes, l'arbre de décision générique, les garde-fous de jugement, les arrêts | Le propriétaire, par un ADR ; le skill porte un numéro de version | Rarement |
| **Outillage** | `tool/vagues/`, `tool/chantiers/`, `.claude/hooks/` | Les scripts (porte d'entrée, mesure de session, vérification des références) et les hooks (garde-fou, état à l'ouverture) | Une tâche de plan, avec ses tests | Rarement |
| **Chantier** | `docs/chantiers/<chantier>/` | L'ordre des vagues et sa raison, l'état, le journal, la cohérence, l'oracle, le récit non technique | La vague 0, puis chaque vague pour l'état et le journal | À l'ouverture, puis à chaque étape (l'état) ou à chaque jalon (le journal) |
| **Vague** | `docs/chantiers/<chantier>/vagues/<NN>-…/` | La fiche, la conception d'un lot lourd, les plans, les vérifications, les tests manuels, le compte rendu | La vague 0 pour la fiche, l'éclaireur pour sa mise à jour, la vague elle-même pour le reste | Pendant la vague, puis plus jamais, sauf par une session de correction |

**Ce qu'une session d'orchestrateur lit** : aujourd'hui, la méthode (§3 à §6, ≈ 280 lignes), le chantier (§0 à §2 et §7, journal aux cellules de plus de 200 mots) et les neuf fiches (≈ 180 lignes). Avec les couches : le `SKILL.md` (gabarits dans les fichiers d'agents, garde-fous dans les hooks), `etat.json` et un `orchestration.md` réduit aux jalons, la seule fiche de sa vague. Environ la moitié, à vérifier par la mesure de session (§7.4) ; le relais ★R17 empêche en plus le contexte de grandir sur toute une vague.

---

## 1 bis. Le workflow en graphes

Les graphes et la définition de « la méthode » ★R23 sont dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md), §1 et §7 à §10. Quand la méthode change, ils changent dans le même commit.

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
│           ├── verifications-LOT.md
│           ├── tests-manuels.md
│           └── compte-rendu.md
├── economie-et-catalogue/                     # un chantier = un dossier
│   ├── orchestration.md                       # comment et quand : vagues, ordre, journal, cohérence, oracle
│   ├── etat.json                              # où en est le chantier, lu par les scripts et les hooks
│   ├── suivi.md                               # ce que chaque vague apporte au jeu, sans technique
│   └── vagues/
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
│       │   ├── tests-manuels.md               # ★R22 ce que le propriétaire teste à la main, et ce qu'il a trouvé
│       │   └── compte-rendu.md
│       ├── …
│       └── cloture/
│           └── fiche.md
└── <prochain-chantier>/
```

**Les règles de nommage**

- **Chantier** : minuscules, sans accent, tirets, sans date (`economie-et-catalogue`) ; reste en place comme historique.
- **Vague** : `<NN>-v<x.y.z>-<nom>` ; la clôture s'écrit `cloture` ; la vague 0 n'a pas de dossier (c'est la phase 1, sur `docs/ouverture-<chantier>`). Le numéro vient d'abord et ne change jamais ; un décalage de version (correctif intercalé) se règle par `git mv`, seul cas de renommage.
- **Conceptions et plans** : `conception-<lot>.md`, `plan-<lot>.md`, `plan-<lot>-partie-<k>.md`. Nom unique dans le dépôt : SDD range son registre sous `.superpowers/sdd/<nom du plan>/`. Pas de date dans le nom.
- **Conception** ★R31 : lot lourd seulement ; un lot léger ou standard n'a ni spec ni conception (guide §8.6). Les specs du chantier en cours gardent `spec-<lot>.md` à la migration.
- **`verifications-<lot>.md`** ★R15 : options écartées et journal des tours ; le document ne garde que la décision et sa raison.
- **`tests-manuels.md`** ★R22, un par vague, rempli par le propriétaire (§4.6). **`compte-rendu.md`**, un par vague ; une correction y ajoute sa section.

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
| Qu'a-t-elle décidé, livré, coûté ? | `vagues/<NN>-…/compte-rendu.md`, et ses conceptions et ses plans |
| Quelles options a-t-on écartées ? Comment la conception ou le plan a-t-il convergé ? | `vagues/<NN>-…/verifications-<lot>.md` |
| Que faut-il tester à la main, et qu'a-t-on trouvé ? | `vagues/<NN>-…/tests-manuels.md` |
| Qu'apporte-t-elle au jeu ? | `suivi.md` |
| Comment s'ouvre un chantier ? Comment une vague se déroule-t-elle ? | le [guide](07-10-2026_guide_du_workflow_par_vagues.md), pour les comprendre ; les skills `ouverture-de-chantier` et `vague`, pour les dérouler |
| Pourquoi la méthode est-elle ainsi ? | les ADR de méthode |

---

## 3. Les phases du workflow

Quatre phases : 0 brainstorm ; 1 ouverture, `/ouverture-de-chantier` ; 2 une vague, `/vague` ; 3 clôture, même skill. Déroulé dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md), §6 à §13. Ce qui s'installe est ici : annexe A (phase 1), annexe B (`vague`), §6 (agents de la phase 2).

---

## 4. Les fichiers à copier

Les `<…>` se remplissent, les commentaires HTML se retirent.

### 4.1. `orchestration.md`

Les sections gardent la numérotation du fichier actuel jusqu'à §2 ; les fiches en sortent. Le fichier devrait tenir en 150 à 250 lignes.

~~~~markdown
# Orchestration — <le chantier en clair>, de `<version de départ>` à `<version visée>`

**Date** : <JJ/MM/AAAA>
**Statut** : **ce fichier fait foi pour le déroulé du chantier** — l'ordre des vagues, ce que chacune livre, sa version. **L'état courant est dans [`etat.json`](etat.json)**, les fiches et les documents de chaque vague dans [`vagues/`](vagues/). **Les décisions de conception ne sont pas ici** : leur source de vérité est <lien vers le brainstorm>, §<n> (D1 à D<n>). En cas d'écart, le brainstorm a raison sur le *quoi*, ce fichier sur le *comment* et le *quand*.
**Méthode** : `orchestration-par-vagues`, version <n> — les skills `ouverture-de-chantier` et `vague`. Ce fichier n'en précise que ce qui est propre au chantier (§3).
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
     - `arret_ouvert` non nul : ne reprends que par `/vague <chantier> levee <ce qui lève l'arrêt>`.
   - **Une reprise ne détruit rien** : un arbre sale se range par `git stash push -u`, un commit rouge se corrige par un commit.
3. **Lis la fiche de ta vague**, `vagues/<NN>-…/fiche.md`, et le compte rendu de la vague précédente : ses sections « Leçons » et « Pour la file ».
4. **Passe la porte d'entrée** : `tool/vagues/porte_entree.sh docs/chantiers/<chantier> <branche de la vague>` ★R5. Elle rend 0, ou la liste de ce qui échoue ; dans ce cas, arrête-toi et dis pourquoi.
5. **Déroule le cycle** du skill. Arbitre les questions de classe T. Celles de classe P t'arrivent tranchées dans la fiche, ou t'arrêtent ; celles de classe D t'arrêtent ★R3.
6. **Arrête-toi à la porte de sortie.** Tu ne pousses rien, n'ouvres pas de PR, ne fusionnes pas, ne poses pas de tag.

**Les commandes** — elles remplacent les prompts à coller :

- `/vague <chantier>` : ouvre la vague suivante, ou reprend celle qui est en cours ;
- `/vague <chantier> correction <ce que le test a trouvé ; les arbitrages renversés>` : une session de correction sur la vague livrée ;
- `/vague <chantier> eclaireur` : l'éclaireur de la vague suivante, pendant ton test ★R8 ;
- `/vague <chantier> levee <ce qui lève l'arrêt>` : lève un arrêt, puis reprend.

Le niveau d'autonomie de chaque vague se fixe dans l'en-tête de sa fiche, avant la fusion de la vague précédente ★R3 ; l'ouverture de la vague le recopie dans `etat.json`, pour une reprise.

---

## 1. Les vagues et les versions

| Vague | Version | Dossier | Lots | Cérémonie ★R11 | Ce que le joueur voit | Dépend de | Branche | Critère de sortie — ce qui doit être VRAI |
|:---:|:---|:---|:---|:---|:---|:---|:---|:---|
| **0** | — | — | L'ouverture du chantier (phase 1) | — | Rien | — | `docs/ouverture-<chantier>` | Le dossier du chantier est rempli et relu ; la ROADMAP y renvoie |
| **1** | `<x.y.z>` | [`01-v<x.y.z>-<nom>`](vagues/01-v<x.y.z>-<nom>/) | <lots> | standard | <une phrase> | 0 | `feat/v<x.y.z>-<id>` | <deux ou trois faits, chacun avec sa commande ou son test> |
| … | | | | | | | | |
| **Clôture** | — | [`cloture`](vagues/cloture/) | — | — | Rien | la dernière | `docs/cloture-<chantier>` | Le journal, la mémoire, la ROADMAP et le suivi disent le chantier clos |

**Un lot est ce qui reçoit un plan** — et une conception, s'il est lourd. <Ce qui, dans ce chantier, n'est pas un lot au sens du cycle.>

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

| Vague | Coût (API) | Durée | Agents | Tours de conception | Tours de plan | Arrêts | Lignes de plan / lignes de code | Défauts au test du propriétaire | Leçon principale |
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
  "etape": "fin · sortie · fait",
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
| `etape` | `"<portée> · <étape> · <fait \| en cours>"` — la portée est le lot, avec sa partie, ou `fin` ; les étapes sont nommées par le guide, §8.3 | Le grain fin que le journal ne porte plus ; ce que lit une reprise |
| `autonomie` | `strict` · `continu` | Fixée dans la fiche de la vague, recopiée ici à son ouverture, pour une reprise ★R3 |
| `arret_ouvert` | `null` · `"<JJ/MM> · <étape> · <classe> · <motif en une ligne>"` | Le détail est dans le compte rendu |
| `chantier_clos` | `false` · `true` | Passé à `true` par la session de clôture, seule |
| `outillage` | `{ "superpowers": "<version ou sha>", "claude_code": "<version>" }` | ★R14 Relevé à l'ouverture du chantier, affiché par la porte d'entrée, recopié au §1 de chaque compte rendu ; ne change qu'entre deux chantiers. `null` dans l'exemple : aucune vague ne l'a relevé à ce jour |

**Les règles** :
- seul l'orchestrateur l'écrit, à chaque étape, dans le commit du document que l'étape produit, sur la branche de la vague ;
- on ne retire jamais un champ ;
- la porte d'entrée le valide (`jq empty`) avant tout le reste.

### 4.3. `vagues/<NN>-…/fiche.md`

Écrite à l'ouverture du chantier ; mise à jour par l'éclaireur avant la vague ★R8 ; figée ensuite.

~~~~markdown
# Vague <N> — `<version>` — <lots>

**Cérémonie** : léger | standard | lourd ★R11 — **Tâches à risque** : <celles dont le plan écrit le code entier, et que le vérificateur rejoue> ★R1
**Autonomie** : strict | continu ★R3 — fixée par le propriétaire avant la fusion de la vague précédente ; `strict` par défaut
**Mesurée le** : <JJ/MM, sur `<sha>`> — **éclairée le** : <JJ/MM, sur `<sha>`, ses prémisses corrigées en une ligne> ★R8

## <Lot> — <titre>

**Fichiers** : `plan-<lot>.md` — ou, pour un lot lourd, `conception-<lot>.md` puis `plan-<lot>-partie-<k>.md` —, et `verifications-<lot>.md`, dans ce dossier ★R31.
**Décisions** : D<n>, D<m> — avec les réserves que la fiche leur met.
**À lire** : <chemins>.
**État mesuré** ★R10 — par symbole, pas par ligne :
- `lib/<chemin>.dart › <Classe>.<méthode>` — <ce qu'il fait aujourd'hui>.

**Le lot doit fixer** : <liste — ce que la conception, ou les décisions de conception du plan, doivent trancher>.
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

Squelette copié à `branche` ; rempli dès la fin du premier plan (SDD supprime son registre), complété en fin de vague. Les sections des trois comptes rendus existants, plus deux ★.

~~~~markdown
# Vague <N> — `<version>` — <lots> — compte rendu

**Chantier** : [orchestration](../../orchestration.md) · **Fiche** : [fiche.md](fiche.md) · **Vérifications** : `verifications-<lot>.md` · **Branche** : `<branche>`

## 0. Pour le propriétaire — une page ★R16
<!-- trente lignes au plus : ce qu'il faut tester d'abord, par risque ; les arbitrages que le joueur verra ; ceux faits sans toi ; les risques connus ; les trois commandes qui rejouent l'essentiel -->
## 1. La branche et ses chiffres
<!-- ★R14 avec les versions de l'outillage -->
## 2. La table des arbitrages
<!-- par conception, par plan, puis les décisions de SDD, plan après plan — une ligne par arbitrage, le détail et les options écartées restant dans verifications-<lot>.md ★R15 ; ★R3 les arbitrages faits sans le propriétaire, en autonomie « continu », dans une sous-section à part ; ★R17 une passation de dix lignes à chaque fin de plan, si l'orchestrateur est relayé -->
## 3. Les tests manuels
<!-- ★R22 renvoi à tests-manuels.md, et ses résultats une fois le test fait : K ✅, L ❌, M non testés -->
## 4. L'oracle
## 5. Trouvé périmé, et pour la file
## 6. Les leçons ★R9
<!-- cinq au plus, chacune : la leçon, la preuve, l'amendement proposé (skill, agent, CLAUDE.md, ou rien) -->
## 7. Les statistiques de la session
<!-- produites par `tool/vagues/mesure_session` ★R5 — mêmes définitions à chaque vague ; plus une ligne : les défauts remontés par le test du propriétaire, comptés dans tests-manuels.md -->
## Corrections du <JJ/MM/AAAA>
<!-- une section par session de correction, qui finit par ses propres statistiques -->
~~~~

### 4.5. `suivi.md`

Le squelette de §5 de `docs/suivi_vagues_chantier/_modele_suivi.md`, dont les règles (§1 à §4) deviennent `docs/chantiers/_modele/suivi.md`. Deux retouches : l'en-tête renvoie à `orchestration.md` du même dossier ; le nom du chantier sort du fichier.

### 4.6. `vagues/<NN>-…/tests-manuels.md` ★R22

Écrit par `redacteur-tests-manuels` à la place de l'ancien cahier du compte rendu ; rempli et commité par le propriétaire ; ses ❌ ouvrent une correction et remplissent la colonne « Défauts » du tableau de bord. Le menu de debug ne change pas.

~~~~markdown
# Vague <N> — `<version>` — tests manuels

**Branche** : `<branche>` · **Compte rendu** : [compte-rendu.md](compte-rendu.md)
**Testé le** : <JJ/MM/AAAA>, sur `<sha>`, sur <plateforme>
**Résultat** : <K> ✅ · <L> ❌ · <M> non testés

## À tester d'abord
<!-- les tests, du plus risqué au moins risqué : une ligne chacun, avec son numéro -->

## T1 — <ce qui est testé, en clair>

- **Atteindre la situation** : <en jouant, ou par les onglets du menu de debug — lesquels, quelles valeurs>
- **Faire** : <les étapes>
- **Attendu** : <ce que l'écran doit montrer, chiffres compris>
- **Ne doit pas changer** : <ce qui reste identique>
- **Résultat** : ✅ · ❌ · non testé — <ce qui a été vu, si ❌>

## Défauts trouvés

| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
~~~~

---

## 5. La méthode : ce qui change dans le cycle actuel

Le cycle actuel (§3.1 à §3.10) devient le corps du skill `vague` (annexe B) ; correspondance des noms dans le guide, annexe A.

| Étape | Aujourd'hui | Avec le modèle |
|:---|:---|:---|
| **Lecture d'ouverture** | Tout le fichier d'orchestration | ★R6 `etat.json`, `orchestration.md`, la fiche de la vague, et les leçons de la vague précédente |
| **3.1 Porte d'entrée** | Neuf vérifications rejouées une à une par le modèle | ★R5 `tool/vagues/porte_entree.sh`, qui valide aussi `etat.json` et vérifie que la branche annoncée figure dans la table des vagues (§7.3) |
| **3.2 Branche** | Créer la branche ; journal à « en cours », précédente à « close » | Inchangé. Plus `etat.json` pointé sur la nouvelle vague, dans le même premier commit. Le dossier de la vague existe déjà depuis l'ouverture du chantier |
| **3.3 Spec** | Rédiger → vérifier tout → corriger → revérifier tout, trois tours, puis arrêt ; écrite dans `docs/superpowers/specs/` | ★R31 **Plus de spec.** Un lot lourd a sa conception, `conception-<lot>.md`, dans le dossier de la vague ; un lot léger ou standard passe directement au plan. Ce qui suit vaut pour la conception.<br>★R5 `tool/vagues/verifier_references` avant toute vérification.<br>★R2 Le premier tour vérifie tout, les suivants seulement les corrections et ce qu'elles touchent ; la grille de gravité a ses critères ; un trou de test descend au *Review Focus* du plan.<br>★R3 Après trois tours : en *strict*, l'arrêt ; en *continu*, la correction des constats de classe T, consignée, puis un dernier tour différentiel |
| **3.4 Plan** | Le code de chaque tâche écrit en entier, rejoué dans un clone ; écrit dans `docs/superpowers/plans/` | Le plan s'écrit **dans le dossier de la vague**, `plan-<lot>[-partie-<k>].md`.<br>★R1 Il consigne des décisions : fichiers, signatures, valeurs, tests nommés et leur assertion, commande de vérification, total attendu. Le code n'est écrit en entier que pour les tâches à risque de la fiche.<br>Une section *Review Focus* en tête ; une auto-revue de longueur : aucun bloc de code hors des tâches à risque et, pour un lot lourd, pas plus du triple de la conception |
| **Historique de la spec** | Dans la spec : options écartées (§1.2), journal des tours (§13) | ★R15 Dans `verifications-<lot>.md` ; la conception ou le plan ne garde que la décision retenue et sa raison, et le vérificateur ne lit ce fichier qu'en mode différentiel |
| **3.5 Implémentation** | SDD ; dix contraintes recopiées à chaque agent | Inchangé sur le fond. ★R4 Les contraintes que le hook `garde_vague` garantit sortent des gabarits ; restent celles qu'aucun outil ne vérifie |
| **Fin de plan** (`3.5 · fait`) | L'orchestrateur continue, son contexte grandit | ★R17 Passation de dix lignes au compte rendu, `etat.json` à jour, fin de session ; `/vague <chantier>` relance la suite, par la reprise (guide, §8.10) |
| **3.6 bis Convergence** | — | ★R13 Un agent relit les décisions de chaque conception et de chaque plan face au code de la branche ; ses écarts deviennent une tâche ou un constat consigné |
| **3.7 Skills, 3.8 Documents** | Les skills, puis le compte rendu, le suivi et le journal | Les trois documents de fin — tests manuels, compte rendu, suivi — s'écrivent en parallèle, par trois agents, **avant** les skills ; les statistiques se mesurent en dernier, à la porte de sortie (guide, §8.13 à §8.15) |
| **3.8 Compte rendu** | Un fichier dans `docs/superpowers/reports/` ; les statistiques mesurées par un script réécrit à chaque vague | `compte-rendu.md` **dans le dossier de la vague**.<br>★R5 `tool/vagues/mesure_session` pour les statistiques.<br>★R9 La section « Leçons » ; la ligne de la vague au tableau de bord de `orchestration.md`.<br>★R22 Le cahier de test manuel devient `tests-manuels.md`, que le propriétaire remplit |
| **3.9 Porte de sortie** | L'arrêt | Inchangé, plus ★R8 : le propriétaire lance l'éclaireur de la vague suivante pendant qu'il teste |
| **Arrêt, relais, livraison** | Rien ne prévient le propriétaire | ★R18 Le hook `prevenir` lui envoie un message (§7.6) |
| **Arbitrage** | Arbre à 8 filtres | ★R3 Une classe par question avant l'arbre : **T**, technique, tranchée par l'orchestrateur ; **P**, visible du joueur, tranchée par le propriétaire, de préférence dans la fiche avant la vague ; **D**, qui amende une décision acquise : arrêt |
| **Garde-fous** | Texte | ★R4 `main` protégé sur GitHub ; le hook `garde_vague` ; ne restent en texte que les garde-fous de jugement |

---

## 6. Les gabarits des agents ★R6

Un fichier par rôle dans `.claude/agents/` : partie fixe dans le fichier, partie variable dans le message. **Le catalogue et les règles communes sont dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md), §4.3** ; ici, les seuls gabarits qui changent sur le fond. Les gabarits actuels §4.1 (base du `redacteur-conception`), §4.5 et §4.6 restent la base, avec les chemins du dossier de la vague ; les agents de la phase 1 sont en annexe A.2. ★R31 : pour un lot léger ou standard, `redacteur-plan` écrit aussi les décisions de conception, et `verificateur-plan` les vérifie avec la grille de §6.1.

### 6.1. `verificateur-conception` ★R2 — ancien vérificateur de spec

````
Tu vérifies une conception — ou les décisions de conception en tête d'un plan — que tu n'as pas écrite. Lis `CLAUDE.md` d'abord. Tu ne modifies aucun fichier.

Le document : <dossier de la vague>/conception-<lot>.md | plan-<lot>.md, section « Décisions de conception ». La fiche : <dossier de la vague>/fiche.md. Les décisions du lot : <liste D, avec leurs réserves>, texte dans <brainstorm> §<n>.
Mode : <complet — tout le document | différentiel — seulement les corrections listées ci-dessous et ce qu'elles touchent>.
<En différentiel : les corrections du tour précédent, avec les sections modifiées ; les arbitrages déjà tranchés par l'orchestrateur — ne les rouvre pas sans preuve neuve.>

Commence par lancer `tool/vagues/verifier_references <chemin du document>` et reporte ce qu'il rend.

Vérifie, chaque point par une commande ou une citation, jamais de mémoire :
1. Chaque décision du lot est couverte dans la part que la fiche lui donne, et aucune n'est contredite — cite la ligne du brainstorm.
2. Chaque item de « Le lot doit fixer » est fixé, et chaque critère de sortie de la fiche a sa preuve prévue.
3. Chaque question de « À arbitrer » est tranchée, avec ses options, sa classe et son motif ; les réponses du propriétaire aux questions de classe P sont reprises telles quelles ; aucun arbitrage n'amende une décision acquise ni ne change une valeur mesurée.
4. Rien de « Ne pas absorber » n'y est entré ; les transitions avec les lots voisins sont traitées.
5. Les règles du dépôt tiennent : trois couches, donnée bilingue, id = nom de fichier, un fait à un seul endroit, pas de code sans lecteur.
6. <Le point propre au lot, donné par la fiche.>

La gravité suit cette grille, et rien d'autre :
- bloquant — contredit une décision acquise, ou rend l'implémentation impossible telle qu'écrite ;
- moyen — produirait un comportement faux, ou un test rouge, que le plan n'aurait aucune raison de voir ;
- mineur — imprécis, mais le plan le résoudra sans risque ;
- rédaction — la forme seulement.
Un test qui manque n'est pas un constat de conception : liste-le à part, sous « Pour le Review Focus du plan ».
Ne signale que ce qui touche la correction ou les exigences du lot. Une préférence n'est pas un constat.

Rends une table : numéro, où, constat, preuve, gravité, classe (T · P · D), correction proposée. Puis la liste « Pour le Review Focus du plan ». Puis une ligne : « prête » ou « à corriger ».
````

**Le consolidateur d'un panel**, quand il y en a un, reçoit en plus : « Tu ne relèves la gravité d'un constat qu'avec une preuve que tu as reproduite par une commande ; écris laquelle. »

### 6.2. `redacteur-plan` ★R1

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis `<dossier de la vague>/fiche.md` — et, pour un lot lourd, `<dossier de la vague>/conception-<lot>.md` <§ de la partie> —, dans `<dossier de la vague>/plan-<lot>[-partie-<k>].md`. Modèle de forme : `<plan de référence, lui-même un plan de décisions>` — but, architecture, contraintes globales, Review Focus, carte des fichiers, tâches titrées `### Task N: …`.

Pour un lot léger ou standard, le plan ouvre, après son but, par ses décisions de conception : les arbitrages (le choix et sa raison ; les options écartées vont dans `verifications-<lot>.md`), les données, les interfaces, les textes joueur en `_fr` et `_en`, les critères de sortie de la fiche. Pour chaque question de classe T qu'elles posent, propose un choix : l'orchestrateur tranche.

Le plan consigne des décisions, il ne transcrit pas le code. Pour chaque tâche :
- les fichiers touchés ;
- les signatures exactes de ce qui se crée ou change ;
- les valeurs que les décisions imposent ;
- les tests nommés, chacun avec son assertion clé ;
- la commande de vérification et ce qu'elle doit rendre ;
- le total de tests attendu : <N>, plus les tests ajoutés, moins les retirés.
Le code s'écrit en entier dans deux cas seulement : les tâches à risque — <liste de la fiche> — et un algorithme que les décisions imposent ligne à ligne.

En tête du plan, une section « Review Focus » : au plus cinq modes d'échec que les décisions impliquent et qu'aucun test ne garde encore, chacun confié à la tâche qui l'écrira. <Les trous de test remontés par la vérification de la conception : …>
Avant de rendre, compte les blocs de code hors des tâches à risque : il n'en reste aucun, sauf un algorithme imposé ligne à ligne — remplace les autres par leurs signatures et leurs assertions. Pour un lot lourd, compare aussi la longueur du plan à celle de la conception : au-delà du triple, c'est une transcription.

Le plan ne crée pas de branche, ne commite rien sur `main`, ne pousse rien, n'ouvre pas de PR, n'invoque aucun skill de livraison ni de synchronisation. Sa dernière tâche est la vérification finale. Rends le chemin du plan, sa carte des fichiers, le nombre de blocs de code hors des tâches à risque et, pour un lot lourd, sa longueur rapportée à celle de la conception.
````

**Le plan de référence compte autant que le gabarit** (audit §6.1) : celui de P-49 transcrit (3 627 lignes, 249 blocs). Le premier plan écrit selon ce gabarit et jugé bon devient la référence.

### 6.3. `verificateur-plan` ★R1

Celui du fichier actuel (§4.4), avec deux changements :
- « **rejoue dans un clone les seules tâches à risque** : <liste> ; pour les autres, vérifie que les signatures existent ou sont créées par une tâche antérieure, que les tests nommés gardent ce que les décisions demandent, et que le décompte des tests tombe juste » ;
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
Tu vérifies qu'une vague livre ce que ses décisions écrites décident. Lis `CLAUDE.md`. Tu ne modifies aucun fichier.

Les décisions : `<dossier de la vague>/conception-*.md`, et la section « Décisions de conception » de chaque `plan-*.md` ; les critères de sortie : `<dossier de la vague>/fiche.md`. La branche : <branche>, depuis `<commit de départ de la vague>`.

Pour chaque décision et chaque critère de sortie : trouve le code et le test qui le portent, par une commande, et dis « livré », « partiel » ou « absent ». Puis cherche l'inverse : un comportement neuf du diff qu'aucune décision ne demande.
Ne juge ni le style ni la structure : la revue d'ensemble de SDD l'a fait.

Rends une table : décision ou critère, verdict, preuve, et pour chaque « partiel » ou « absent » la correction proposée. Puis la liste du code qu'aucune décision ne demande.
````

---

## 7. L'outillage — des esquisses

**Rien n'est installé.** Chaque esquisse s'adopte par une tâche de plan avec ses tests, validée contre la documentation du jour ([hooks](https://code.claude.com/docs/en/hooks), [sub-agents](https://code.claude.com/docs/en/sub-agents), [skills](https://code.claude.com/docs/en/skills)).

### 7.1. Un fichier d'agent

`.claude/agents/verificateur-conception.md` :

```markdown
---
name: verificateur-conception
description: Vérifie une conception de lot, ou les décisions de conception d'un plan, qu'il n'a pas écrite, contre le brainstorm, la fiche et le code de la branche, et rend une table de constats prouvés. À utiliser aux étapes conception et plan d'une vague.
tools: Read, Grep, Glob, Bash
model: <le plus capable>
---
<Le corps du gabarit §6.1, sans ses parties variables : elles arrivent par le message de l'orchestrateur.>
```

Sans `Write` ni `Edit`, pas d'outil d'édition ; `Bash` reste pour les preuves, et peut écrire : un hook propre à l'agent fermerait ce reste si besoin.

### 7.2. Le hook `garde_vague` ★R4

`.claude/hooks/garde_vague.sh`, testé le 05/10 et le 07/10 sur un dépôt jetable. Bloqués : `git push`, `git add .`, `git add -A`, `dart format`, `gh pr create`, `git reset --hard`, `git worktree add`, `git clean`. Laissés passer : `git add <chemin>`, `git tag -l`, `dart analyze`, `gh pr view`, `git reset HEAD~1`, et tout hors d'une branche de chantier.

```bash
#!/usr/bin/env bash
# Bloque les gestes de livraison quand la branche courante est une branche de chantier : vague, ouverture ou clôture.
cmd=$(jq -r '.tool_input.command // empty')
branche=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null)
case "$branche" in
  feat/v[0-9]*|docs/ouverture-*|docs/cloture-*) ;;
  *) exit 0 ;;
esac
interdit='(^|[;&|[:space:]])(git[[:space:]]+(push|clean|worktree[[:space:]]+add|reset[[:space:]]+--hard|add[[:space:]]+(-A|--all|\.)([[:space:]]|$))|gh[[:space:]]+(pr[[:space:]]+(create|merge)|release)|dart[[:space:]]+format)'
if printf '%s' "$cmd" | grep -Eq "$interdit"; then
  echo "Garde-fou de vague : « $cmd » est interdit sur la branche $branche (méthode orchestration-par-vagues, garde-fous)." >&2
  exit 2
fi
exit 0
```

Par branche et non par règle de permission : un `deny` global bloquerait aussi les sessions cloud, qui doivent pousser. Il ne remplace pas la **protection de `main` sur GitHub**, vrai verrou de « jamais sur `main` ».

### 7.3. La porte d'entrée, qui lit `etat.json` ★R5

Esquisse : les vérifications de la table §3.1 du fichier actuel, plus deux venues de l'arborescence.

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

La version à écrire attend un run `queued` ou `in_progress`, contrôle aussi la release, et saute le contrôle du tag après une vague 0.

### 7.4. Les autres scripts ★R5

- `tool/vagues/mesure_session` — les statistiques de §3.8, depuis les transcriptions : temps, agents, jetons comptés une fois par message, coût ; mêmes définitions à chaque vague ; sort la ligne du tableau de bord et le §7 du compte rendu.
- `tool/vagues/verifier_references` — chaque `chemin`, `chemin:ligne` et `chemin › Classe.méthode` cité existe sur la branche.

En Dart sous `tool/`, propres à `dart analyze`, nommés par la section « Tooling » de `CLAUDE.md`.

### 7.5. L'état à l'ouverture de session — facultatif

Un hook `SessionStart` affiche l'état des chantiers ouverts :

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

Un hook `Stop` qui ne parle qu'à un arrêt, un relais ou une livraison, une fois par événement, **par un webhook dédié**, distinct de celui des releases. Deux variables d'environnement locales :

| `ALERTE_FORMAT` | `ALERTE_URL` | Ce qui est envoyé |
|:---|:---|:---|
| `discord` | l'URL du webhook du salon | `{"content": "<message>"}` |
| `slack` | l'URL de l'*incoming webhook* | `{"text": "<message>"}` |
| `texte` | toute URL qui accepte du texte brut en POST — par exemple un sujet [ntfy](https://ntfy.sh), qui notifie le téléphone | le message seul |

```bash
#!/usr/bin/env bash
# .claude/hooks/prevenir.sh — hook Stop : prévient le propriétaire quand un chantier s'arrête, passe le relais ou livre.
[ -n "${ALERTE_URL:-}" ] || exit 0
racine="${CLAUDE_PROJECT_DIR:-.}"
mkdir -p "$racine/.superpowers"
for f in "$racine"/docs/chantiers/*/etat.json; do
  case "$f" in */_modele/*) continue ;; esac
  [ -e "$f" ] || continue
  msg=$(jq -r 'if .arret_ouvert then "Arrêt — \(.chantier), vague \(.vague) : \(.arret_ouvert)"
               elif .etat == "livree_sur_branche" then "Livrée — \(.chantier), vague \(.vague), sur \(.branche) (\(.etape), \(.maj)) : à toi de tester"
               elif ((.etape // "") | endswith(" · sdd · fait")) then "Relais — \(.chantier), vague \(.vague), \(.etape) : relance /vague \(.chantier)"
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

`.superpowers/` est ignoré par git. Le hook sort toujours en 0. L'URL est un secret, jamais dans le dépôt.

### 7.7. Les skills de méthode ★R6

```
.claude/skills/ouverture-de-chantier/
└── SKILL.md                   # la phase 1 — Annexe A
.claude/skills/vague/
├── SKILL.md                   # les phases 2 et 3 : le cycle 3.1 à 3.10, l'arbre générique, les arrêts — moins de 500 lignes
└── references/
    ├── grille-gravite.md      # la grille de §6.1, avec des exemples tirés des vagues passées
    └── compte-rendu.md        # la forme du compte rendu, et les définitions des statistiques
```

- `disable-model-invocation: true` sur les deux : lancés par ta commande seulement.
- Les gabarits sont dans les fichiers d'agents (§6), pas dans le skill.
- La méthode porte un numéro de version, cité par `orchestration.md` et `etat.json` ; en changer en cours de chantier est un amendement, par ADR.


### 7.8. L'enregistrement des hooks

Dans `.claude/settings.json`, suivi par git ; à valider contre la [documentation](https://code.claude.com/docs/en/hooks) à l'adoption :

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/garde_vague.sh\"" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/prevenir.sh\"" }]
      }
    ],
    "SessionStart": [
      {
        "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/etat_chantiers.sh\"" }]
      }
    ]
  }
}
```

`etat_chantiers` est facultatif.

---

## 8. L'adoption, et la migration du chantier en cours

### 8.1. Ce qui peut s'appliquer dès la vague 4, sans toucher à l'arborescence

Les gains de coût ne dépendent pas des répertoires (audit §5) :

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
| R31 — plus de spec pour un lot léger ou standard | à essayer aux vagues 6 et 7, que le fichier actuel dit déjà « moyen : une spec, un plan » ; pas en vague 4, qui est lourde et porte déjà l'essai de R1 à R3 |
| R16 — une page pour le propriétaire | §3.8 |
| R17 — le relais de l'orchestrateur, sur une vague, mesuré | §0, §3.5 |
| R18 — le hook `prevenir` | `.claude/hooks/`, sans toucher au fichier |
| R22 — les tests manuels en fichier | §3.8 : le cahier sort du compte rendu, dans un fichier voisin, `docs/superpowers/reports/<AAAA-MM-JJ>-economie-et-catalogue-vague-<N>-tests-manuels.md`, tant que l'arborescence n'a pas migré |

### 8.2. L'arborescence : quand, et comment

**Trois moments possibles :**

| Moment | Pour | Contre |
|:---|:---|:---|
| **A — à la session de clôture du chantier en cours** (recommandé) | Aucune vague ouverte, aucun conflit ; la clôture écrit déjà dans le journal, la mémoire, la ROADMAP et le suivi | Le gain de lecture (§1) ne profite pas aux vagues 4 à 7 |
| **B — entre deux vagues**, après la fusion de la vague N et avant le lancement de N+1 | Les vagues restantes lisent déjà moins | Le prompt de lancement change de chemin en plein chantier ; une branche de documentation de plus à fusionner ; le risque d'oublier un lien dans un document que la vague suivante lit |
| **C — seulement pour le prochain chantier** | Aucun déplacement de fichier | Deux rangements coexistent : l'ancien chantier dans `possible_upgrades/` et `superpowers/`, les suivants dans `docs/chantiers/` |

**Jamais pendant qu'une branche de vague est ouverte.**

**La migration :**

1. Créer `docs/chantiers/_modele/` depuis §4, et `docs/chantiers/economie-et-catalogue/`.
2. Déplacer par `git mv` :

   | Aujourd'hui | Demain |
   |:---|:---|
   | `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` | `docs/chantiers/economie-et-catalogue/orchestration.md` — ses fiches (§8) partent dans les `fiche.md`, son journal fin dans `etat.json` |
   | `docs/suivi_vagues_chantier/economie_unifiee_et_catalogue.md` | `docs/chantiers/economie-et-catalogue/suivi.md` |
   | `docs/suivi_vagues_chantier/_modele_suivi.md` | `docs/chantiers/_modele/suivi.md` |
   | `docs/superpowers/specs/2026-10-0x-p43-<lot>-…-design.md` | `docs/chantiers/economie-et-catalogue/vagues/<NN>-…/spec-p43-<lot>.md` |
   | `docs/superpowers/plans/2026-10-0x-p43-<lot>-…[-partie-k].md` | `…/vagues/<NN>-…/plan-p43-<lot>[-partie-k].md` |
   | `docs/superpowers/reports/2026-10-0x-economie-et-catalogue-vague-<N>-compte-rendu.md` | `…/vagues/<NN>-…/compte-rendu.md` |
   | `docs/superpowers/reports/README.md` | retiré : son contenu est dans ce modèle (§2 et §4.4) |
   | Ce modèle | réparti entre `docs/chantiers/_modele/`, les deux skills et leurs agents |
   | Le guide du workflow | `docs/chantiers/README.md`, à côté des chantiers qu'il explique |

3. **Réécrire les liens** : 34 fichiers, 137 occurrences le 06/10 (ADR 102 à 107, `_patterns/20-00`, `activeContext.md`, `progress.md`, `CLAUDE.md`, `INDEX.md`, `ROADMAP.md`, les specs, plans, comptes rendus, le brainstorm, la revue, le rapport de simulation, le fichier d'orchestration, ces documents). Les retrouver : `grep -rlE "01-10-2026_orchestration_chantier|suivi_vagues_chantier/|superpowers/reports/|superpowers/specs/2026-10-0|superpowers/plans/2026-10-0" --include='*.md' .`
4. **`CLAUDE.md`, « Documentation Map »** : les deux lignes du chantier en cours deviennent une seule, valable pour tous les chantiers :
   > | A programme delivered by waves | `docs/chantiers/<chantier>/` — `orchestration.md` (how and when), `etat.json` (where it stands), `suivi.md` (what each wave brings to the game, in plain language), `vagues/<NN>-v<x.y.z>-<name>/` (each wave's brief, design, plans, checks, manual tests and report). The method is the `ouverture-de-chantier` and `vague` skills, explained step by step in `docs/chantiers/README.md`; its agents live in `.claude/agents/` |
5. **`docs/INDEX.md`** : une ligne vers le dossier ; `docs/suivi_vagues_chantier/` sort de la légende.
6. **`memory-bank-sync`** ne cite aucun ancien chemin (vérifié le 06/10).
7. **Contrôler** : la recherche de l'étape 3 vide hors `_archive/` ; liens relatifs résolus ; `dart analyze` et `flutter test` inchangés.
8. **Un ADR** amende ADR-102 et ADR-103 et pose l'arborescence.

### 8.3. L'ordre recommandé

1. **Maintenant** : décider de l'essai de la vague 4 (§8.1, R1 à R3), et protéger `main`.
2. **Pendant les vagues 4 à 7** : outiller (R4, R5), ajouter les leçons et le tableau de bord (R9), l'éclaireur (R8) et la convergence (R13). Mesurer chaque vague contre les précédentes.
3. **À la clôture** : migrer vers `docs/chantiers/` (§8.2, moment A), installer les deux skills et leurs agents (Annexes A et B ; leur fonctionnement : le guide), écrire l'ADR.
4. **Au prochain chantier** : l'ouvrir par `/ouverture-de-chantier` (phase 1), directement dans `docs/chantiers/`.

---

## Annexe A — La phase 1, prête à installer

**Rien n'est installé.** À adopter par une tâche de plan, le script avec son test. `<le plus capable>` et `<intermédiaire>` sont à remplacer par les valeurs de `model:`. Format vérifié le 07/10 ([skills](https://code.claude.com/docs/en/skills), [sub-agents](https://code.claude.com/docs/en/sub-agents)).

### A.1. `.claude/skills/ouverture-de-chantier/SKILL.md`

~~~~markdown
---
name: ouverture-de-chantier
description: Opens a new Hero's Draft programme ("chantier") delivered by waves, from the owner's brainstorm — phase 1, which is wave 0. Checks the brainstorm is ready, runs a blind code review, proposes the wave breakdown and waits for the owner's approval, creates docs/chantiers/<chantier>/ from the template, dispatches agents to write orchestration.md, one brief per wave and suivi.md, checks everything, and stops on a documentation branch. Manual only.
disable-model-invocation: true
argument-hint: <chemin du brainstorm> <nom-du-chantier>
arguments: [brainstorm, chantier]
allowed-tools: Bash(git status *) Bash(git fetch *) Bash(git switch *) Bash(git add *) Bash(git commit *) Bash(jq *) Bash(bash tool/chantiers/squelette.sh *)
---

# Ouverture d'un chantier — phase 1

Tu ouvres le chantier **$chantier** à partir du brainstorm **$brainstorm**. Tu es l'orchestrateur de la phase : tu délègues l'écriture aux agents de `.claude/agents/`, tu gardes le fil, et tu n'écris toi-même que les messages au propriétaire, `etat.json`, la ligne de `docs/INDEX.md` et les commits. Écris en français.

À chaque commit, `etape` dans `etat.json` dit l'étape faite — `ouverture · squelette · fait`, `ouverture · orchestration · fait`, `ouverture · fiches · fait`, `ouverture · rodage · fait` : c'est ce qui permet la reprise (étape 1).

## L'état au lancement

!`git branch --show-current`
!`git status --short | head -20 || true`
!`ls docs/chantiers 2>/dev/null || echo "docs/chantiers n'existe pas encore"`

## Ce que tu ne fais jamais

- Toucher à `lib/`, `test/`, `assets/`, ou au brainstorm : tu signales, le propriétaire corrige.
- Inventer une décision : ce que le brainstorm ne tranche pas devient une question à arbitrer, dans la fiche de sa vague.
- Créer quoi que ce soit avant que le propriétaire ait validé le découpage.
- Pousser, ouvrir une PR, commiter sur `main`.
- Laisser deux agents écrire le même fichier, ou laisser un agent commiter : les agents écrivent, toi seul commites.

## Étape 1 — Les préconditions

Vérifie par commande, et arrête-toi au premier échec en disant lequel :
- l'arbre est propre, sur `main`, à jour : `git fetch`, puis `git rev-list --left-right --count main...origin/main` rend `0 0` ;
- `$brainstorm` existe ; `docs/chantiers/$chantier` n'existe pas ; `docs/chantiers/_modele/` existe ;
- `$chantier` est en minuscules, sans accent, ses mots séparés par des tirets.

**La reprise** : si la branche `docs/ouverture-$chantier` existe, avec un `etat.json` `en_cours`, ne t'arrête pas : bascule dessus, vérifie que l'arbre est propre, et reprends à l'étape qui suit la dernière notée dans `etape`.

## Étape 2 — Le brainstorm est-il prêt ?

Lis `$brainstorm` en entier. Il est prêt s'il a :
1. des décisions numérotées (`D1`…), chacune marquée acquise ou proposée ;
2. un périmètre écrit : ce qui entre, ce qui reste dehors ;
3. aucune question marquée bloquante ;
4. un ordre, ou les contraintes d'ordre entre les systèmes ;
5. si des valeurs de jeu sont décidées sur mesure : le rapport de l'oracle et sa sortie de référence, qui existent.

Sinon, arrête-toi et donne la liste de ce qui manque, point par point. Rien n'est créé.

## Étape 3 — La revue contre le code, en deux temps

1. Écris des questions neutres sur le code, une ou deux par système que le brainstorm touche : « comment le jeu fait-il X aujourd'hui ? où vit Y ? qui lit Z ? ». **Aucune question ne contient une conclusion du brainstorm.**
2. Lance `enqueteur-code` avec ces questions seules. Ne lui donne pas le brainstorm.
3. Lance `reviseur-brainstorm` avec le brainstorm et les réponses. Il écrit la revue dans `docs/possible_upgrades/<JJ-MM-AAAA>_revue_<nom du brainstorm>.md`, et rend sa table de constats.
4. Si un constat dit qu'une décision repose sur une lecture fausse du code : arrête-toi, et cite le constat et la décision. Le propriétaire corrige le brainstorm, puis relance. Les autres constats restent dans la revue.

## Étape 4 — Le découpage, que le propriétaire valide

1. Lance `decoupeur` avec le brainstorm et la revue. Il rend une table et un JSON, au format de l'annexe A.3 du modèle.
2. Vérifie que chaque décision du brainstorm a une vague, ou la mention « après le chantier » : les `D<n>` du brainstorm (`grep -oE 'D[0-9]+'`), comparés à ceux du JSON.
3. **Présente la table au propriétaire, et attends sa réponse.** S'il la modifie, relance `decoupeur` avec ses remarques. Ne continue qu'avec son accord explicite.
4. Écris le JSON validé dans `.superpowers/decoupage-$chantier.json`, que git ignore.

## Étape 5 — Le squelette

```bash
git switch -c docs/ouverture-$chantier
bash tool/chantiers/squelette.sh $chantier .superpowers/decoupage-$chantier.json
```

Commite le squelette et la revue de l'étape 3 : c'est le premier commit de la branche. Le script a déjà écrit `etape` à `ouverture · squelette · fait`.

## Étape 6 — `orchestration.md`

Lance `redacteur-orchestration` avec le brainstorm, la revue, le découpage validé et `docs/chantiers/$chantier/orchestration.md`. Vérifie avec `git status` qu'il n'a écrit que ce fichier, puis commite, avec `etape` à `ouverture · orchestration · fait`.

## Étape 7 — Les fiches et le suivi, en parallèle

Dans un même message, lance :
- un `redacteur-fiche` par dossier de `docs/chantiers/$chantier/vagues/`, chacun avec son seul dossier ;
- un `redacteur-suivi`, pour `docs/chantiers/$chantier/suivi.md`.

Attends-les tous. Vérifie avec `git status` que chacun n'a écrit que son fichier, puis commite, avec `etape` à `ouverture · fiches · fait`. Garde la liste des questions de classe P que chaque `redacteur-fiche` te rend.

## Étape 8 — Les contrôles

1. Par commande :
   - `jq empty docs/chantiers/$chantier/etat.json` ;
   - chaque `D<n>` du brainstorm apparaît dans une `fiche.md`, ou sur la ligne « après le chantier » de `orchestration.md` ;
   - chaque lien relatif des fichiers du chantier se résout.
2. Lance `verificateur-ouverture`. Si sa table a un constat bloquant ou moyen, lance `correcteur` avec la table, puis un `verificateur-ouverture` neuf. **Deux tours au plus** : s'il reste un constat bloquant ou moyen après le second, arrête-toi et rends la table au propriétaire.
3. Commite les corrections, avec `etape` à `ouverture · rodage · fait`.

## Étape 9 — La fin

1. Lance un agent qui invoque `memory-bank-sync` : la ligne du chantier dans `docs/ROADMAP.md`, qui renvoie à `docs/chantiers/$chantier/`.
2. Ajoute une ligne dans `docs/INDEX.md`, vers `docs/chantiers/$chantier/orchestration.md`.
3. Dans `etat.json` : `"etat": "faite"`, `"etape": "ouverture · fait"`.
4. Commite, et arrête-toi. Rends au propriétaire :
   - la branche `docs/ouverture-$chantier`, à relire et à fusionner — c'est la vague 0 ;
   - **toutes les questions de classe P**, vague par vague, avec leurs options et la recommandation de la fiche ;
   - le résumé de la revue et du rodage.
~~~~

### A.2. Les agents de la phase 1

Quatre fichiers en entier ; les quatre autres suivent la même forme, mission au guide §4.3 et §7.

`.claude/agents/enqueteur-code.md` :

```markdown
---
name: enqueteur-code
description: Answers neutral questions about how Hero's Draft works today, from the code only. Never reads a brainstorm, a spec or a plan. Used by phase 1 (ouverture-de-chantier) for the blind review.
tools: Read, Grep, Glob, Bash
model: <intermédiaire>
---
Tu réponds à des questions sur le code de Hero's Draft, tel qu'il est sur la branche courante. Tu ne lis aucun document de `docs/` ni du vault : seulement `lib/`, `assets/data/`, `test/` et `tool/`.

Pour chaque question : la réponse, en deux à cinq phrases ; les symboles qui la portent (`chemin › Classe.membre`) ; le test qui la garde, s'il existe ; ce que tu n'as pas pu établir. Une réponse sans preuve dans le code s'écrit « non établi ».

Tu ne modifies aucun fichier.
```

`.claude/agents/decoupeur.md` :

```markdown
---
name: decoupeur
description: Proposes how to split a Hero's Draft programme into waves, one game version each, from a ready brainstorm and its code review. Returns a table for the owner and a JSON for the skeleton script. Writes nothing.
tools: Read, Grep, Glob, Bash
model: <le plus capable>
---
Tu proposes le découpage d'un chantier en vagues. Une vague livre une version du jeu, et le jeu reste jouable à chaque version.

Lis le brainstorm, sa revue, `docs/ROADMAP.md`, et la version de départ dans `pubspec.yaml`. Rends :
1. une table : numéro, version, nom, lots, cérémonie (léger · standard · lourd), ce que le joueur voit, dépend de, critère de sortie ;
2. « pourquoi cet ordre » : une phrase par dépendance — ce que la vague N+1 lit de la vague N ;
3. la vague de chaque décision `D<n>`, ou « après le chantier » ;
4. le JSON du découpage, au format de l'annexe A.3 du modèle d'orchestration.

Un lot lourd est un lot qui demande plusieurs parties. Une décision qui ne se range nulle part est une question pour le propriétaire, pas un choix à faire à sa place. Tu ne modifies aucun fichier.
```

`.claude/agents/redacteur-fiche.md` :

```markdown
---
name: redacteur-fiche
description: Writes the brief (fiche.md) of one wave of a Hero's Draft programme, from the brainstorm, orchestration.md and the code. Edits only that file and never commits. Several run in parallel, one per wave.
tools: Read, Grep, Glob, Bash, Edit, Write
model: <le plus capable>
---
Tu écris la fiche d'une seule vague : `<dossier de la vague>/fiche.md`, dont le squelette est déjà en place. Tu ne modifies aucun autre fichier, et tu ne commites pas.

Lis `CLAUDE.md`, les décisions de ta vague dans le brainstorm, ta ligne du §1 et les transitions du §4.2 de `orchestration.md`, puis le code que ta vague touchera. Remplis chaque rubrique du squelette :
- « État mesuré » : re-mesuré par commande, cité par symbole (`chemin › Classe.membre`), jamais par numéro de ligne ;
- « À arbitrer » : chaque question avec sa classe — T, technique ; P, visible du joueur ; D, qui amenderait une décision acquise —, ses options et ta recommandation ;
- « Critères de sortie » : chacun avec le test ou la commande qui le prouvera.

Rends le chemin de la fiche, et la liste de ses questions de classe P.
```

`.claude/agents/verificateur-ouverture.md` :

```markdown
---
name: verificateur-ouverture
description: Checks a freshly opened Hero's Draft programme before its first wave — dry-runs the first wave's entry gate, and checks orchestration.md and every wave brief against the brainstorm and the code. Returns findings only.
tools: Read, Grep, Glob, Bash
model: <le plus capable>
---
Tu vérifies un chantier que tu n'as pas écrit : `docs/chantiers/<chantier>/`. Tu ne modifies aucun fichier.

1. Rejoue à blanc la porte d'entrée de la vague 1 : chaque vérification qui échouerait aujourd'hui, et pourquoi.
2. Pour chaque fiche : ses décisions sont celles du brainstorm, sans contradiction ; son « État mesuré » est vrai dans le code ; ses critères de sortie sont vérifiables.
3. Pour `orchestration.md` : aucune vague ne lit ce qu'une vague plus tardive crée ; chaque décision a une vague.

Chaque constat se prouve par une commande ou une citation. Rends une table : numéro, où, constat, preuve, gravité (bloquant · moyen · mineur · rédaction), correction proposée. Puis « prêt » ou « à corriger ».
```

`reviseur-brainstorm`, `redacteur-orchestration`, `redacteur-suivi`, `correcteur` : même forme, description en anglais, outils et modèle du guide §4.3, mission en corps.

### A.3. Le script de squelette, et le format du découpage

`tool/chantiers/squelette.sh`, testé le 07/10 sur un dépôt jetable :

```bash
#!/usr/bin/env bash
# Usage : tool/chantiers/squelette.sh <nom-du-chantier> <decoupage.json>
# Crée docs/chantiers/<nom>/ depuis docs/chantiers/_modele/ : fichiers racine, un dossier par vague,
# etat.json initial. N'écrit aucun contenu : les agents rempliront les squelettes.
set -euo pipefail
nom="$1"; decoupage="$2"; racine="docs/chantiers/$nom"; modele="docs/chantiers/_modele"
[ ! -e "$racine" ] || { echo "❌ $racine existe déjà" >&2; exit 1; }
jq -e '.vagues | length > 0' "$decoupage" >/dev/null || { echo "❌ découpage illisible ou vide" >&2; exit 1; }
mkdir -p "$racine/vagues"
cp "$modele/orchestration.md" "$modele/suivi.md" "$racine/"
jq -r '.vagues[].dossier' "$decoupage" | while read -r dossier; do
  mkdir -p "$racine/vagues/$dossier"
  cp "$modele/vagues/NN-vX.Y.Z-nom/fiche.md" "$racine/vagues/$dossier/fiche.md"
done
jq --arg nom "$nom" --arg jour "$(date +%F)" '{
  chantier: $nom, methode: .methode, chantier_clos: false,
  vague: 0, dossier: null, branche: ("docs/ouverture-" + $nom),
  version_du_jeu: .version_depart, etat: "en_cours", etape: "ouverture · squelette · fait",
  base_tests: null, total_tests: null, autonomie: "strict", arret_ouvert: null,
  outillage: .outillage, maj: $jour }' "$decoupage" > "$racine/etat.json"
echo "✅ $racine : $(jq '.vagues | length' "$decoupage") dossiers de vague, etat.json initial"
```

Le JSON que rend `decoupeur`, et que le script lit :

```json
{
  "methode": "orchestration-par-vagues@1",
  "version_depart": "0.6.0",
  "outillage": { "superpowers": "<version ou sha>", "claude_code": "<version>" },
  "vagues": [
    { "numero": 1, "version": "0.6.1", "nom": "<nom>", "dossier": "01-v0.6.1-<nom>",
      "lots": ["<lot>"], "ceremonie": "standard", "branche": "feat/v0.6.1-<lot>" },
    { "numero": 2, "version": "0.6.2", "nom": "<nom>", "dossier": "02-v0.6.2-<nom>",
      "lots": ["<lot>", "<lot>"], "ceremonie": "lourd", "branche": "feat/v0.6.2-<lots>" },
    { "numero": 99, "version": null, "nom": "cloture", "dossier": "cloture",
      "lots": [], "ceremonie": null, "branche": "docs/cloture-<chantier>" }
  ]
}
```

Vit le temps de la phase 1 sous `.superpowers/` ; ensuite la table du §1 de `orchestration.md` est la seule source.

---

## Annexe B — Le squelette du `SKILL.md` de `/vague`

À écrire en entier à l'adoption, depuis le guide §8 à §13 et le §5 de ce modèle ; sous 500 lignes, les détails dans `references/`.

~~~~markdown
---
name: vague
description: Runs the next step of a Hero's Draft programme delivered by waves — opens the next wave, resumes one in progress, lifts a stop, runs a correction session, the scout for the next wave, or the closing session, depending on etat.json and the branches. Manual only — phases 2 and 3 of the wave workflow.
disable-model-invocation: true
argument-hint: <nom-du-chantier> [eclaireur | correction <ce que le test a trouvé> | levee <ce qui lève l'arrêt>]
arguments: [chantier, mode]
---

# Une vague — phases 2 et 3

## L'état au lancement
!`git branch --show-current`
!`git status --short | head -20 || true`

## Trouver le mode
<la table du guide, §8.1 : ouvrir, reprendre, lever, corriger, éclairer, clore — d'après `docs/chantiers/$chantier/etat.json`, les branches, et `$mode`>

## Ouvrir une vague
1. `porte` — la porte d'entrée : `bash tool/vagues/porte_entree.sh docs/chantiers/$chantier <branche>`.
2. `branche` — la branche ; les squelettes de `compte-rendu.md`, `tests-manuels.md` et d'un `verifications-<lot>.md` par lot ; `etat.json` à `en_cours`, l'autonomie recopiée de la fiche ; le journal.
3. Pour chaque lot, en série : `conception` (lot lourd), puis `plan` pour chaque partie, chacun dans sa boucle de vérification ; puis `sdd` ; puis la passation, et la fin de la session (relais).
4. La fin de vague : `oracle` ; `convergence` ; `documents` — en parallèle `redacteur-tests-manuels`, `redacteur-compte-rendu` et `redacteur-suivi` ; `skills` — `patch-notes-writer`, puis `memory-bank-sync`.
5. `sortie` : `mesure_session`, les leçons, le journal, `etat.json` à `livree_sur_branche`, l'arrêt.

## Reprendre · Lever · Corriger · Éclairer · Clore
<une sous-section chacun : ce qu'il lit, ce qu'il écrit, où il s'arrête>

## La boucle de vérification
<le graphe 3 en texte : les contrôles par script, le vérificateur neuf, complet puis différentiel, la grille de gravité, les classes T · P · D, l'autonomie>

## Les garde-fous de jugement
<n'amender aucune décision acquise ; ne pas élargir le périmètre ; ne pas dire clos ce qui ne l'est pas — les garde-fous mécaniques sont dans le hook `garde_vague`>

## Les arrêts
<la liste du §6 du fichier d'orchestration actuel, plus les questions de classe P sans réponse>

## Pour aller plus loin
- la grille de gravité, avec ses exemples : [references/grille-gravite.md](references/grille-gravite.md)
- ce qu'écrit le compte rendu, et les définitions des statistiques : [references/compte-rendu.md](references/compte-rendu.md)
~~~~
