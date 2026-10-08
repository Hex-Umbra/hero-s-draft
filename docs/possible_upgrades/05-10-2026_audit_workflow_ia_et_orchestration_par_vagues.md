# Audit — le développement assisté par IA de Hero's Draft, comparé à ce que font les autres

**Date** : 05/10/2026 ; seconde passe le 06/10 (§6) ; R31 et les phases le 07/10 (§6.7). **Condensé le 08/10** : même numérotation, même contenu décisionnel, moins de récit.
**Objet** : la chaîne brainstorm → revue → spec → plan → exécution et le [fichier d'orchestration par vagues](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) (ADR-102, ADR-103), mesurés sur trois vagues et comparés à ce que publient praticiens, frameworks et Anthropic.
**Compagnons** : le [modèle](05-10-2026_modele_orchestration_par_vagues.md) (ce qui s'installe) et le [guide](07-10-2026_guide_du_workflow_par_vagues.md) (comment ça marche). Ce document dit *pourquoi*.
**Qui le lit** : le propriétaire, pour décider. Aucun agent de vague n'a à le charger ; la méthode qu'ils suivent est dans le fichier d'orchestration, puis dans les skills.
**Méthode** : dépôt à `0ec09ab` (orchestration, ADR-102/103, trois comptes rendus, brainstorm v3 et revue, specs et plans des vagues 1 à 3, `git diff --shortstat` des trois fusions) ; trois recherches web par agents le 05/10 ; sources clés relues directement (annexe A). Reddit et Hacker News inaccessibles ; les blogs marqués *(secondaire)* ne sont connus que par extraits.
**Statut** : exploration. Adopter une recommandation amende ADR-102 et ADR-103 : décision du propriétaire, par un ADR et la correction du fichier d'orchestration. Les décisions déjà prises sont au §6.6.

---

## 0. Verdict en neuf lignes

1. **Sur cinq points, la méthode est en avance** : deux autorités distinctes (quoi / comment), vérificateur ≠ rédacteur avec preuve par commande, portes vérifiées par commande, arbitrage par arbre écrit, coût mesuré par vague.
2. **L'ossature recoupe GSD (milestone → phase → plan, `STATE.md`, `D-01`), le harnais d'Anthropic (une unité par session, journal, git comme état) et BMAD (rétrospective par epic).**
3. **Le problème est dans les chiffres** : specs et plans prennent 73 à 76 % des jetons, l'implémentation 5 à 8 % ; 172 → 273 → 389 $ ; 2, 4 puis 6 tours de spec ; 3 à 3,5 lignes de documentation par ligne de code.
4. **Les plans transcrivent le code** : 16 654 lignes en vague 3, 673 blocs de code dans le seul plan E3 partie 2, rejoués dans un clone par leurs vérificateurs. Superpowers 6.4.2 : « *A plan records decisions. It's not a transcript of the code.* »
5. **La vérification de spec ne converge plus** : chaque tour confie la spec entière à un panel neuf ; vague 3, six tours, trois arrêts, 22 → 15 → 13 → 12 → 7 constats. Un relecteur à qui l'on demande des trous en trouve.
6. **Les garde-fous sont du texte**, recopié dans chaque gabarit ; `main` n'est pas protégé (ADR-103).
7. **Il manque** une boucle d'apprentissage entre vagues et une cérémonie proportionnée au lot.
8. **Rien ne change l'ossature** : treize changements classés en §4, dix-sept de plus en §6.
9. **Correction de R1 (§6.1)** : la transcription vient du gabarit et du plan modèle, pas de la version du plugin.

---

## 1. Le workflow, tel qu'il tourne

### 1.1. La chaîne

| Étape | Document | Ce qui la distingue |
|:---|:---|:---|
| Brainstorm | [brainstorm v3](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md) | D1 à D75, « acquises », amendées en place |
| Vérification | [revue](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md) | Six passes, 35 références contrôlées, agent `game_designer`, simulation jetable |
| Mesure | [simulation D26](30-09-2026_simulation_D26_economie_Fable5.md), `tool/simulations/` | 2 700 runs ; la sortie de référence est un oracle de non-régression |
| Orchestration | [fichier d'orchestration](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), 636 lignes, ≈ 54 000 jetons par lecture | 8 vagues, journal, cycle en 10 étapes, 6 gabarits, arbre à 8 filtres, garde-fous, une fiche par vague |
| Une vague | spec → plan(s) → SDD → simulation → `patch-notes-writer` → `memory-bank-sync` → compte rendu, suivi → arrêt | Vérificateur ≠ rédacteur ; preuve par commande ; 3 tours ; le propriétaire teste, fusionne, tague |

### 1.2. Ce que coûtent les trois vagues livrées

Sources : §1 et §6 des comptes rendus ; `git diff --shortstat` des commits de fusion.

| | Vague 1 (E0 + E1) | Vague 2 (E2) | Vague 3 (E3) |
|:---|---:|---:|---:|
| Durée de bout en bout | 8 h 07 | 11 h 16 | 28 h 55, dont 12 h 57 de travail |
| Sessions / arrêts | 1 / 0 | 2 / 1 | 4 / 3 |
| Tours de vérification de la spec | 2 par lot | 4 | 6 |
| Agents | 43 | 52 | 81 |
| Coût au tarif de l'API | 171,66 $ | 272,90 $ | 388,75 $ |
| Jetons : spec et plans | 73 % | 76 % | 76 % |
| Jetons : implémentation | 7 % | 8 % | 5 % |
| Lignes de spec / de plans | 1 618 / 10 574 | 1 692 / 12 582 | 1 878 / 16 654 |
| Lignes ajoutées dans `lib/`, `test/`, `assets/` | 4 325 | 4 963 | 5 692 |
| Lignes ajoutées dans `docs/` et le vault | 13 210 | 15 632 | 20 104 |
| Coût par ligne de code ajoutée | 0,040 $ | 0,055 $ | 0,068 $ |
| Défauts remontés par le test manuel | non noté | non noté | non noté |

Aucun document ne tient la dernière ligne ; aucune session de correction n'a été ouverte, ce qui suggère zéro. C'est pourtant la seule mesure de qualité qui permettrait de juger une économie (§5).

### 1.3. Ce qui marche, à garder

- **Deux autorités** : brainstorm (quoi), orchestration (comment, quand), ROADMAP qui renvoie. Règle « une source de vérité par artefact » du [playbook SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook).
- **Vérificateur ≠ rédacteur, preuves exigées** — Anthropic : « *tuning a standalone evaluator to be skeptical turns out to be far more tractable* » ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- **Portes par commande**, approbation humaine aux portes de livraison seulement.
- **Reprise sur disque** : journal sur la branche, algorithme §0.2 — le `claude-progress.txt` d'Anthropic, le `STATE.md` de GSD.
- **Autonomie déléguée par écrit** : l'arbre de décision ; les *rulings* de SDD en sont le proche.
- **Oracle propre au domaine** : la simulation diffée contre une référence suivie par git.
- **Mesure de chaque vague** ; **suivi non technique**. Sans équivalent ailleurs.

### 1.4. Ce que les chiffres montrent

1. **Le coût est en amont du code** : vague 3, implémentation 28 $, spec 193 $, plans 86 $. Optimiser l'exécution gagnerait quelques pour cent.
2. **Les plans réécrivent le code** : 740 lignes par tâche en moyenne (E3 partie 2) ; le code est écrit jusqu'à trois fois (plan, clone du vérificateur, implémenteur).
3. **La vérification de spec a une cible mobile** : quatre tours complets par panel neuf (22, 15, 13, 12 constats) ; seuls les tours centrés sur les corrections convergent (7, puis « prête »).
4. **La gravité gonfle à la consolidation** : au quatrième tour, trois « prête », deux constats remontés de mineur à moyen par le consolidateur, arrêt.
5. **Beaucoup de « moyens » sont des trous de test** (trois sur trois au troisième tour) : ils relèvent du plan.
6. **Les arrêts coûtent de l'attente** : quatre arrêts levés le jour même depuis les recommandations ; 23 points sur 32 suivis tels quels, 9 variantes. Premier arrêt de la vague 3 : 15 h 55 d'attente.
7. **La documentation croît plus vite que le code** (ratio > 3). HumanLayer a abandonné sa méthode pour cette raison : « *a 1,000-line plan produces ~1,000 lines of code* ».

---

## 2. Ce que font les autres

### 2.1. La même chaîne, partout

Clarifier, spec, plan, exécuter dans un contexte neuf, vérifier, commiter.

| Qui | Étapes | Propre à chacun |
|:---|:---|:---|
| **Harper Reed** (2025) *(secondaire)* | idée → spec → plan de prompts → exécution | Cases cochées comme état ; « *single player* » |
| **Superpowers** (v6.4.2, 25/09/2026) | brainstorming → spec → plan → SDD → revue | Cérémonie proportionnée (v6.3) ; plans réduits aux décisions, *Review Focus* (v6.4) ; un relecteur par tâche (v6.0) |
| **HumanLayer → QRSPI** (2026) *(secondaire)* | Questions → Research → Design → Structure → Plan → Implement | Recherche « à l'aveugle » ; < 40 consignes par étape |
| **Ralph** (Huntley) | boucle : une tâche, tests, commit | « *The plan is disposable* » ; un échec = une ligne de garde-fou |
| **Compound Engineering** (Every) | brainstorm → plan → work → review → **compound** | Chaque cycle consigne ses leçons |
| **Spec Kit** (v1.1.0) | constitution → specify → clarify → plan → tasks → analyze → implement → **converge** | `analyze` en lecture seule ; `converge` relit la spec face au code ; TinySpec |
| **Kiro** *(extraits)* | requirements (EARS) → design → tasks | Chaque tâche renvoie à ses exigences |
| **BMAD** (v6.12) | analyst → PM → architect → dev | Rétrospective par epic, preuves à l'appui ; seul un humain passe à `done` |
| **Anthropic**, [Best practices](https://code.claude.com/docs/en/best-practices) | explore → plan → implement → commit | « *If you could describe the diff in one sentence, skip the plan* » |

### 2.2. Au niveau d'un programme

**Vocabulaire** : chez GSD et Kiro, une *wave* est un paquet parallèle ; ta vague est une *phase* GSD, un *epic* BMAD ; ton programme, un *milestone* GSD (annexe B).

- **GSD** (archivé le 26/06/2026, continué par `open-gsd/gsd-core`) : `.planning/ROADMAP.md` (Goal, Depends on, Success Criteria), `STATE.md`, décisions `D-01`, barrière bloquante « chaque décision dans un plan », vérificateur qui refuse une tâche sans commande de vérification, phase close seulement par un `VERIFICATION.md` qui passe, `/gsd-quick`.
- **BMAD** : *readiness gate* PASS / CONCERNS / FAIL ; **BMad Loop**, orchestrateur Python « *No LLM in the control loop* ».
- **Conductor** (Gemini) : `tracks.md`, rapport de vérification en *git notes*.
- **Dépôts « wave »** : [claude-wave-orchestration](https://github.com/warao-shikyo/claude-wave-orchestration) (`ANTI-PATTERNS.md` : l'orchestrateur n'implémente rien, résumé court pour lui, long pour l'humain, périmètre figé, STOP explicite) ; [wave-planning](https://github.com/ArunPrakashG/wave-planning) (bloc d'état dans le plan, modèle selon le risque).

### 2.3. Ce qui a changé en 2026

1. **Cérémonie proportionnée** : Superpowers 6.3, TinySpec, Kiro Quick Plan, GSD quick.
2. **Plans maigres** : Superpowers 6.4.2 donne signatures, assertions, valeurs, commande ; auto-revue de longueur (« *a plan several times longer than the spec is a transcript* ») ; planification annoncée ≈ 4× plus rapide, 3× moins de jetons.
3. **État lisible par machine** : `feature_list.json`, `STATE.md`, `sprint-status.yaml`, `state.json`. Anthropic préfère le JSON, que le modèle réécrit moins volontiers que du Markdown.
4. **Contrôle par script, création par le modèle** : BMad Loop, CCPM, étapes *gate* de Spec Kit ; hooks, `/goal`, workflows côté Claude Code.
5. **La boucle se ferme** : `converge`, *gap-closure*, *compound*.
6. **On corrige le processus, pas le livrable** ([migrations](https://claude.com/blog/ai-code-migration)) : « *Front-load the human hours* », « *Make the work queue mechanical and resumable* », « *Review loop results, not code* ».

### 2.4. Les critiques qui reviennent

| Critique | Qui | Ce qui te concerne |
|:---|:---|:---|
| Mer de markdown | Zaninotto, Scott Logic, Böckeler *(secondaire)* | Ratio documentation / code > 3 |
| Relire du markdown n'épargne rien | Böckeler ; Horthy | Les vérificateurs relisent à ta place : le coût passe en jetons |
| Un relecteur trouve toujours quelque chose | Best practices | §1.4, points 3 et 4 |
| Trop de consignes | Best practices ; Horthy (150 à 200 au plus) | 636 lignes, contraintes recopiées dans chaque gabarit |
| Dérive documentaire | Yegge ; Böckeler | Les `fichier:ligne` se périment ; fiches « à revérifier, pas à croire » |
| Coût et latence (« *10x more tokens* ») | HN sur Superpowers *(secondaire)* | §1.2 |
| Dette cognitive | Willison ; l'« usine sans humain » de Horthy | Rien ne t'aide à lire le code |

### 2.5. Ce que dit Anthropic

- Suite fixe d'étapes, barrière programmatique entre deux, nombre maximal d'itérations ([agents](https://www.anthropic.com/engineering/building-effective-agents)).
- Une unité par session, état propre et commité ; à l'ouverture, `git log`, journal, test de fumée ([harnais](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
- Un contrat « fini » entre générateur et évaluateur avant le code ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- Quatre barrières : prompt, `/goal`, hook `Stop`, sous-agent vérificateur ; montrer les preuves ([Best practices](https://code.claude.com/docs/en/best-practices)).
- « *A skill is an advisory control while a hook is the deterministic layer* » ; « *an agent fixing code must not be able to weaken the check* » ([playbook](https://claude.com/blog/the-ai-native-sdlc-playbook)).
- Chaque composant du harnais encode une hypothèse à retester à chaque changement de modèle.
- Divulgation progressive : `SKILL.md` < 500 lignes, `CLAUDE.md` < 200, sous-agents dans `.claude/agents/` avec outils et modèle.

---

## 3. La comparaison, point par point

✅ en avance · 🟰 aligné · 🟠 à combler.

| Dimension | Toi | Les autres | Verdict |
|:---|:---|:---|:---:|
| Découpage d'un programme | Vagues, lots, parties | GSD, BMAD | 🟰 |
| Source des décisions | Brainstorm, D1 à D75 | `CONTEXT.md`, `constitution.md` | ✅ — mais amendé en place dans 561 lignes |
| Couverture décisions → lots | Table §7.1, à la main | GSD : barrière automatique | 🟰 |
| État et reprise | Journal markdown, §0.2 | `STATE.md`, `state.json` | 🟰 — rien ne le lit par machine |
| Portes | Table de commandes, à la main | GSD, Conductor, BMAD | ✅ contenu, 🟠 pas de script |
| Vérification de la spec | Panel neuf, 4 gravités, 3 tours | Spec Kit `analyze` ; Anthropic : correction seulement | ✅ principe, 🟠 convergence |
| Épaisseur du plan | Transcription | Superpowers 6.4.2 ; QRSPI | 🟠 |
| Vérification de l'implémentation | SDD | Pareil + `converge` | 🟰, sans relecture spec ↔ code |
| Oracle | Simulation diffée | Rare | ✅ |
| Arbitrage autonome | Arbre à 8 filtres | *Rulings* ; sinon arrêt | ✅ — sans distinguer produit et technique |
| Garde-fous | Texte | Hooks, permissions, protection de branche | 🟠 |
| Parallélisme | Série ; panels en parallèle | Worktrees | 🟰 — l'ordre est forcé |
| Cérémonie proportionnée | Une seule | Généralisée | 🟠 |
| Apprentissage entre vagues | « Trouvé périmé » | *compound*, rétrospective | 🟠 |
| Mesure | Par étape | Quasi absente | ✅ — script réécrit à chaque vague, qualité non mesurée |
| Communication non technique | Suivi | Absente | ✅ |
| Clôture | Session de clôture | Audit de milestone | 🟰 |

---

## 4. Recommandations, classées

Le [modèle](05-10-2026_modele_orchestration_par_vagues.md) les intègre, marquées ★Rn.

### Priorité 1 — fort gain, faible coût

**R1. Des plans qui consignent des décisions, pas du code.** Plans : 38 %, 37 %, 24 % des jetons ; rejoués dans un clone. *Proposition* : par tâche, fichiers, signatures exactes, valeurs de la spec, tests nommés avec assertion clé, commande de vérification, total de tests attendu. Code complet seulement pour un algorithme imposé ou une tâche « à risque » nommée par la fiche. Section *Review Focus* en tête (cinq modes d'échec au plus, sans test). Le vérificateur contrôle cohérence et décompte ; il ne rejoue que les tâches à risque. Auto-revue : plus de trois fois la spec = transcription. *Coût* : gabarits §4.3, §4.4, **et le plan cité comme modèle** (§6.1).

**R2. Une vérification de spec qui converge.** Quatre règles : (1) grille de gravité avec critères — *bloquant* contredit une décision acquise ou rend l'implémentation impossible, *moyen* produirait un comportement faux ou un test rouge que le plan ne verrait pas ; (2) un trou de test n'est pas un constat de spec, il descend au *Review Focus* ; (3) dès le deuxième tour, vérification **différentielle** par un vérificateur neuf centré sur les corrections, relecture complète seulement si le périmètre change ; (4) un consolidateur ne relève une gravité qu'avec une preuve reproduite par commande. *Coût* : §3.3, §4.2.

**R3. N'arrêter que pour ce qui t'appartient.** Chaque question reçoit une classe : **T** technique, l'orchestrateur tranche ; **P** produit, visible du joueur, posée **avant** la vague par l'éclaireur (R8) ou regroupée en un seul arrêt ; **D** amende une décision acquise, arrêt. Après trois tours sans convergence, un **niveau d'autonomie** fixé dans le prompt : *strict* (arrêt) ou *continu* (l'orchestrateur applique les corrections recommandées des constats T, les consigne à part, lance un dernier tour différentiel). *Coût* : §5, §6, colonne « classe » des fiches.

**R4. Des garde-fous mécaniques.** (a) protéger `main` sur GitHub ; (b) hook `PreToolUse` qui bloque les gestes interdits sur une branche de vague seulement (modèle §7.2) — pas de règle de permission globale, les sessions cloud doivent pousser ; (c) retirer ensuite leur texte des gabarits. *Coût* : une heure.

**R5. Des scripts pour ce qui se calcule.** `tool/vagues/` : `porte_entree` (0 ou la liste des échecs), `mesure_session` (mêmes définitions à chaque vague), `verifier_references` (chaque `chemin:ligne` et symbole cité existe). Les vérificateurs les lancent avant de lire. *Coût* : une tâche de plan, section « Tooling » de `CLAUDE.md`.

### Priorité 2 — structurant, avant le prochain chantier

**R6. Séparer la méthode du chantier.** ≈ 300 lignes génériques sur 636, relues à chaque session (≈ 54 000 jetons). Un skill `orchestration-par-vagues` (`SKILL.md`, `references/`, `scripts/`), des sous-agents dans `.claude/agents/`, un fichier de chantier réduit à 150 à 250 lignes, l'état dans `etat.json`, un dossier par vague sous `docs/chantiers/<chantier>/` (modèle §1, §2). **Pas pendant le chantier en cours.**

**R7. Un état lisible par machine** (`etat.json`), affiché par un hook `SessionStart`, lu par la porte d'entrée.

**R8. Un éclaireur pour la vague suivante, pendant ton test** : session courte sur la branche livrée, qui re-mesure la fiche N+1, liste ses prémisses fausses, rédige les questions P avec options et recommandation, en un commit qui part avec la vague.

**R9. Une rétrospective qui modifie la méthode** : section « Leçons » (cinq au plus, chacune un amendement proposé ou rien) ; tableau de bord dans le fichier de chantier, une ligne par vague.

### Priorité 3 — à essayer sur une vague

**R10. Références par symbole** (`effect_resolver.dart › createStatus`) dans fiches et specs ; les plans gardent les lignes.
**R11. Cérémonie proportionnée** : *léger* (spec et plan fusionnés, un tour), *standard* (le cycle), *lourd* (panel, parties).
**R12. Recherche « à l'aveugle »** dans la revue d'un brainstorm (QRSPI) : questions neutres d'abord, comparaison ensuite.
**R13. Passe de convergence** en fin de vague : les décisions de la spec relues face au code de la branche ; écarts listés.

### Ce que je ne recommande pas

Paralléliser l'implémentation (ordre forcé, fichiers générés par Flutter) ; changer de framework (perte des ADR, du vault, des skills) ; retirer le vérificateur indépendant (à calibrer, R2) ; l'autonomie complète (l'expérience HumanLayer a dégradé un code en trois mois) ; les essaims.

---

## 5. Un essai mesuré, sur la vague 4

1. **Avant** : trancher R1, R2, R3, et seulement eux, par un ADR qui amende ADR-103, et dans le fichier d'orchestration (§3.3, §3.4, §4.2 à §4.4, §5, §6).
2. **Figer l'outillage** (R14).
3. **Ajouter la mesure qui manque** : défauts remontés par ton test manuel, pour la vague 4 et rétroactivement 1 à 3.
4. **Comparer** la vague 4 aux vagues 1 à 3 : coût par lot, tours, arrêts, lignes de plan par ligne de code, défauts.
5. **Décider** à la vague 5 : garder, ajuster, revenir en arrière.

---

## 6. Seconde passe — 06/10

Même arbre, relu du côté de la fin de vague, du vault, de la forme des specs, du test manuel, de la CI. Pages lues le 06/10 : [code intelligence](https://code.claude.com/docs/en/plugins/code-intelligence), [routines](https://code.claude.com/docs/en/routines), [marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference).

### 6.1. Une correction à R1

Les six plans d'octobre ont déjà une section `## Review Focus` (Superpowers 6.4.1) : la version installée est récente. Pourtant le plan E3 partie 2 fait 11 136 lignes et 673 blocs. **C'est le gabarit §4.3 qui impose la transcription** (« Cite le code tel qu'il est sur la branche courante ») et le plan modèle de P-49 (3 627 lignes, 249 blocs). Mettre le plugin à jour n'y changerait rien.

### 6.2. Priorité 1 — avant ou pendant la vague 4

**R14. Figer l'outillage.** Aucun compte rendu ne note la version de Superpowers ni de Claude Code, alors que la méthode dépend du comportement interne de SDD, changé trois fois en six mois. Noter les versions dans `etat.json` et au §1 de chaque compte rendu ; mieux, épingler Superpowers par une marketplace de projet avec un `sha` ; ne monter qu'entre deux chantiers.

**R15. Sortir l'historique de la spec.** Dans la spec E3, arbitrages avec options écartées (§1.2, ≈ 470 lignes) et journal des tours (§13, 193 lignes) font plus du tiers de 1 878 lignes, relus à chaque tour. La spec ne garde que la décision retenue et sa raison ; le reste va dans `verifications-<lot>.md`, lu seulement en mode différentiel.

**R16. Une page pour toi en tête du compte rendu** (trente lignes au plus) : quoi tester d'abord par risque, arbitrages visibles du joueur, arbitrages faits sans toi, risques, trois commandes.

**R17. Relayer l'orchestrateur à chaque fin de plan.** Dernière session de la vague 3 : 300 appels, 133 millions de jetons relus du cache, 40,85 $, contexte croissant. À chaque « `3.5 · fait` », passation de dix lignes, `etat.json` à jour, fin de session ; le même prompt relance. Contrepartie : un prompt de plus par plan. À mesurer.

**R18. Être prévenu d'un arrêt ou d'une fin de vague.** Premier arrêt de la vague 3 à 04:36, reprise à 20:31. Hook `Stop` qui lit `etat.json` et envoie un message par un webhook **dédié** (Discord, Slack, ntfy), distinct de celui des releases (modèle §7.6).

**R19. Barrière contre la dérive documentaire en CI** : `verifier_references` et un contrôle des liens relatifs sur `docs/` et le vault, à chaque PR, qui échoue fermé.

### 6.3. Priorité 2

**R20. Un vault qui renvoie au code.** `memory-bank-sync` corrige 21, 28, puis ≈ 30 fiches par vague ; 58 fichiers touchés en vague 3 ; les deux skills de fin passent de 44,6 à 79,3 millions de jetons. Les fiches recopient des valeurs et parlent d'« état sur la branche ». (a) une fiche énonce règle et invariant et renvoie au test et au symbole ; (b) les chiffres sont générés entre marqueurs par un script sous `tool/` ; (c) jamais d'état de branche. Détail : [proposition du 06/10](06-10-2026_memory_bank_sync_adapte_aux_vagues.md).

**R21. Relier chaque décision à ses tests** (`tags: ['D31']`). *Écarté le 06/10 : le brainstorm reste un brainstorm.*

**R22. Le cahier de test manuel en scénarios chargeables.** *Retenu sous une autre forme : le menu de debug ne change pas ; le cahier devient un fichier `tests-manuels.md` que le propriétaire remplit (modèle §4.6).*

**R23. Un banc d'essai pour la méthode** : cinq cas figés (la spec E3 avant ses tours 3 et 4, la spec E2 avant son tour 3, deux specs convergées) ; on y passe le gabarit du vérificateur et l'on compte les constats connus retrouvés et les « moyens » inventés. *Précisé : « la méthode » est le workflow, résumé en graphes dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md) §1 ; le banc reste une idée.*

**R24. Mesurer l'amont** (brainstorm, revue, simulation). *Écarté, avec toute estimation de coût à l'avance.*

**R25. Un agent `game-designer`** dans `.claude/agents/`, avec outils et modèle, à la place du rôle de `.agents/skills/game_designer.md`.

### 6.4. Priorité 3 — plus tard

**R26. LSP Dart** par un plugin local (`.lsp.json` : `dart language-server --protocol=lsp`) : erreurs après chaque édition, navigation par symbole pour les vérificateurs. Ne démarre pas en session cloud.
**R27. Enchaîner les vagues sans coller de prompt** : routine Claude Code sur `release.published`. Prérequis : environnement cloud avec Flutter, hooks de R4.
**R28. Tests ciblés pendant une tâche, suite complète en fin de tâche** — gain borné (2 h 51 d'implémentation sur 12 h 57).
**R29. Tag posé par la CI après la fusion** — à ta décision (ADR-102 te le réserve).
**R30. Budget par vague qui prévient sans arrêter** : au-delà d'une fois et demie la médiane, ou de trois tours de spec, alerte (R18) et poursuite.

### 6.5. Écartés

Découper `CLAUDE.md` par chemin (126 lignes, sous le seuil) ; écrire la spec N+1 pendant le test de N (R8 en prend la part sans risque).

### 6.6. L'ordre, et les décisions du propriétaire au 07/10

1. **Avant la vague 4** : R14, R1 corrigé, R2, R3 ; R15, R16, R18, R22.
2. **Vagues 4 à 7** : R4, R5, R19 ; R17 mesuré ; R9 ; R8 ; R13.
3. **À la clôture** : migration vers `docs/chantiers/`, R6, R20, R25, R23.
4. **Selon les résultats** : R26 à R30.

| Statut | Recommandations |
|:---|:---|
| **Retenues** | R14, R15, R16, R17 ; R18 par un webhook dédié ; R22 en fichier de tests manuels, sans toucher au menu de debug ; R25 ; R31 |
| **Écartées** | R21 ; R24 et toute estimation de coût à l'avance |
| **Précisée** | R23 : la méthode est le workflow ; le banc reste une idée |
| **À l'état d'idée** | R20, détaillée par la [proposition `memory-bank-sync`](06-10-2026_memory_bank_sync_adapte_aux_vagues.md) |
| **Pour plus tard** | R26 à R30 |

Aucune de ces décisions n'est encore portée par un ADR.

### 6.7. Ajouté le 07/10 — les phases, et la spec qui disparaît

**R31. Plus de spec séparée pour un lot léger ou standard.** *Retenu.* Avec R1, spec et plan se recouvrent ; mais le brainstorm ne tient pas lieu de spec (la spec E3 tranchait 28 arbitrages de *comment*, 21 apparus en l'écrivant). La cérémonie décide : **léger ou standard**, la fiche puis un plan qui ouvre par ses décisions de conception — une rédaction, une boucle ; **lourd**, une conception courte (200 à 300 lignes) pour le lot, puis un plan par partie, écrit après l'implémentation de la précédente. À essayer aux vagues 6 et 7, pas en vague 4 (lourde, et déjà l'essai de R1 à R3). Guide, §8.6 à §8.8.

**Quatre phases** : 0 brainstorm (le tien) ; 1 ouverture d'un chantier, skill `ouverture-de-chantier` (modèle, annexe A) ; 2 une vague, skill `/vague` (annexe B) ; 3 clôture, même skill. Déroulé dans le [guide](07-10-2026_guide_du_workflow_par_vagues.md).

---

## Annexe A — Sources

*Lu directement* sauf *(secondaire)* : extraits ou résumé tiers.

**Anthropic** — [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) (12/2024) · [multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) (06/2025) · [context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (09/2025) · [harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (11/2025) · [C compiler](https://www.anthropic.com/engineering/building-c-compiler) (02/2026) · [harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps) (03/2026) · [evals](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (01/2026) · [code migrations](https://claude.com/blog/ai-code-migration) (07/2026) · [SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) (08/2026) · docs Claude Code : [Best practices](https://code.claude.com/docs/en/best-practices), [code intelligence](https://code.claude.com/docs/en/plugins/code-intelligence), [routines](https://code.claude.com/docs/en/routines), [marketplace](https://code.claude.com/docs/en/plugins/marketplace-reference), [sub-agents](https://code.claude.com/docs/en/sub-agents), [skills](https://code.claude.com/docs/en/skills), [hooks](https://code.claude.com/docs/en/hooks), [memory](https://code.claude.com/docs/en/memory), [`/goal`](https://code.claude.com/docs/en/goal), [workflows](https://code.claude.com/docs/en/workflows), [agent teams](https://code.claude.com/docs/en/agent-teams).

**Frameworks** — [Superpowers RELEASE-NOTES](https://github.com/obra/superpowers/blob/main/RELEASE-NOTES.md) v5.0.0 à v6.4.2 · [GSD USER-GUIDE](https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md), [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core) · [spec-kit](https://github.com/github/spec-kit) v1.1.0, [lettre de juin 2026](https://github.com/github/spec-kit/blob/main/newsletters/2026-June.md) · [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) v6.12, [bmad-loop](https://github.com/bmad-code-org/bmad-loop) · [OpenSpec](https://github.com/Fission-AI/OpenSpec) · [CCPM](https://github.com/automazeio/ccpm) · [Taskmaster](https://github.com/eyaltoledano/claude-task-master) · [Agent OS](https://github.com/buildermethods/agent-os) · [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) · [Conductor](https://github.com/gemini-cli-extensions/conductor) · [Kiro specs](https://kiro.dev/docs/specs/) *(extraits)*.

**Praticiens** — Harper Reed, [My LLM codegen workflow](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/) *(secondaire)* · Jesse Vincent, [Superpowers](https://blog.fsck.com/2025/10/09/superpowers/) *(secondaire)* · HumanLayer, [advanced-context-engineering](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents), [qrspi](https://github.com/matanshavit/qrspi), [l'usine sans humain, résumé ZenML](https://www.zenml.io/llmops-database/engineering-the-software-factory-why-model-training-limits-matter-for-production-code-generation) *(secondaire)* · Huntley, [Ralph](https://ghuntley.com/ralph/), [how-to-ralph-wiggum](https://github.com/ghuntley/how-to-ralph-wiggum) · Every, [Compound engineering](https://every.to/guides/compound-engineering) *(secondaire)* · Yegge, [Beads](https://github.com/steveyegge/beads) · Böckeler (martinfowler.com) *(secondaire)* · Zaninotto, [The Waterfall Strikes Back](https://marmelab.com/blog/2025/11/12/spec-driven-development-waterfall-strikes-back.html) *(secondaire)* · Willison, [Agentic Engineering Patterns](https://simonwillison.net/2026/Feb/23/agentic-engineering-patterns/) *(secondaire)* · Steinberger, [Just Talk To It](https://steipete.me/posts/just-talk-to-it) *(secondaire)* · Osmani, [code agent orchestra](https://addyosmani.com/blog/code-agent-orchestra/) *(secondaire)* · Emschwartz, [rave review of Superpowers](https://emschwartz.me/a-rave-review-of-superpowers-for-claude-code/) *(secondaire)* · [claude-wave-orchestration](https://github.com/warao-shikyo/claude-wave-orchestration), [wave-planning](https://github.com/ArunPrakashG/wave-planning), [wave-skills](https://github.com/nicotrop/wave-skills).

## Annexe B — Le vocabulaire comparé

| Chez toi | GSD | BMAD | Spec Kit | Superpowers | Anthropic |
|:---|:---|:---|:---|:---|:---|
| Chantier | Milestone | Initiative | — | — | Projet |
| Vague (une version) | Phase | Epic | — | Sous-projet | — |
| Lot, partie | Plan | Story | Feature | Spec + plan | Feature |
| Tâche | Task | Ticket | Task | Task | — |
| Décision acquise `Dn` | `D-xx` | — | Principe de constitution | — | — |
| Journal | `STATE.md` | `sprint-status.yaml` | `tasks.md` | Registre SDD | `claude-progress.txt` |
| Porte d'entrée | — | Readiness gate | Constitution check | — | Routine d'ouverture |
| Compte rendu | `SUMMARY.md`, `VERIFICATION.md` | Rétrospective | — | — | — |
| Vague au sens GSD / Kiro | Wave | — | Tâches `[P]` | — | — |
