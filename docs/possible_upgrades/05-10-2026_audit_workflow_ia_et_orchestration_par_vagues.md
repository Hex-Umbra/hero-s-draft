# Audit — le développement assisté par IA de Hero's Draft, comparé à ce que font les autres

**Date** : 05/10/2026
**Objet** : la chaîne brainstorm → revue → spec → plan → exécution, et sa forme la plus récente, le [fichier d'orchestration par vagues](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) (ADR-102, amendé par ADR-103). La comparer à ce que publient les développeurs qui travaillent de la même manière, et en tirer un modèle d'orchestration réutilisable.
**Livrable compagnon** : [`05-10-2026_modele_orchestration_par_vagues.md`](05-10-2026_modele_orchestration_par_vagues.md) — le modèle, qui reprend ton cycle et y intègre les recommandations de §4.
**Méthode** :
- le dépôt relevé à `0ec09ab` : le fichier d'orchestration, ADR-102 et ADR-103, les trois comptes rendus de vague (leurs §1 et §6), le brainstorm v3 et sa revue, les specs et les plans des vagues 1 à 3, et `git diff --shortstat` sur les trois commits de fusion ;
- trois recherches web menées en parallèle le 05/10, chacune par un agent : les forums et les praticiens, les frameworks, la documentation officielle d'Anthropic ;
- les sources dont dépend une recommandation, contrôlées directement le même jour : les notes de version de Superpowers, la page « Best practices » de Claude Code, trois articles d'Anthropic et le guide de GSD.

**Limites** : Reddit et Hacker News refusent l'outil de recherche. Les forums ne sont donc couverts que par des extraits de recherche et par les dépôts GitHub qui en sont issus. Plusieurs blogs (harper.blog, martinfowler.com, humanlayer.dev, simonwillison.net) n'ont été lus que par extraits ; ils sont marqués *(secondaire)* en annexe A.
**Statut** : exploration. **Rien n'est tranché ici.** Adopter une recommandation change la méthode d'ADR-102 et d'ADR-103 : c'est une décision du propriétaire, qui passerait par un nouvel ADR et par la correction du fichier d'orchestration.

---

## 0. Verdict en huit lignes

1. **Sur cinq points, ta méthode est en avance sur ce qui se publie.** Les décisions et le déroulé ont chacun leur autorité. Le vérificateur ne relit jamais son propre travail et doit prouver chaque constat. Les portes d'entrée et de sortie se vérifient par commande. L'arbitrage suit un arbre écrit. Et tu mesures le coût de chaque vague : aucune des sources lues ne le fait.
2. **Ton ossature recoupe ce que les outils les plus mûrs ont trouvé chacun de leur côté.** GSD a le même étagement (milestone → phase → plan), un `STATE.md` et des décisions numérotées `D-01`. Le harnais d'Anthropic garde une unité par session, un journal et git comme état. BMAD finit chaque epic par une rétrospective. Tu n'es pas sur une voie isolée.
3. **Le problème principal est dans tes propres chiffres.** La rédaction et la vérification des specs et des plans prennent 73 à 76 % des jetons, l'implémentation 5 à 8 %. Le coût passe de 172 $ à 273 $ puis 389 $. La spec demande 2 tours de vérification par lot, puis 4, puis 6. Une vague écrit 3 à 3,5 lignes de documentation par ligne de code.
4. **Tes plans transcrivent le code.** Ceux de la vague 3 font 16 654 lignes, dont 673 blocs de code dans le seul plan de la partie 2. Leurs vérificateurs — et, en vagues 1 et 2, leurs rédacteurs aussi — les rejouent dans un clone. Superpowers a corrigé exactement ce défaut le 25/09 (v6.4.2) : « *A plan records decisions. It's not a transcript of the code.* »
5. **La boucle de vérification de la spec a cessé de converger.** Chaque tour confie la spec entière à un vérificateur neuf et vise zéro constat moyen : en vague 3, il a fallu six tours, trois arrêts et quatre sessions (22, 15, 13, 12 puis 7 constats, avant « prête »). La documentation officielle de Claude Code le dit : un relecteur à qui l'on demande des trous en trouve, même quand le travail est sain.
6. **Tes garde-fous sont du texte**, recopié dans chaque gabarit. Claude Code sait les rendre déterministes : règles de permission, hooks. GitHub sait protéger `main` ; ADR-103 relève que ce n'est pas fait.
7. **Il manque deux choses que tout le monde a ajoutées en 2026** : une boucle d'apprentissage d'une vague à l'autre (*compound*, rétrospective), et une cérémonie proportionnée au lot.
8. **Rien de cela ne change l'ossature.** Le modèle compagnon garde ton cycle et y ajoute treize changements, classés en §4 par rapport gain / coût.

---

## 1. Ton workflow, tel qu'il tourne

### 1.1. La chaîne

| Étape | Document | Ce qui la distingue |
|:---|:---|:---|
| Brainstorm | [brainstorm v3](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md) | Décisions numérotées D1 à D75, dites « acquises », amendées en place (barrées, avec renvoi) |
| Vérification et recherche | [revue](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md) | Six passes et un contrôle ciblé ; 35 références contrôlées ; un agent `game_designer` ; une simulation jetable |
| Mesure | [simulation D26](30-09-2026_simulation_D26_economie_Fable5.md), `tool/simulations/` | 2 700 runs ; la sortie de référence devient un oracle de non-régression (un diff) |
| Orchestration | [fichier d'orchestration](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) — 636 lignes, environ 54 000 jetons à chaque lecture | 8 vagues, une version chacune ; journal ; cycle en 10 étapes ; 6 gabarits d'agents ; arbre de décision à 8 filtres ; garde-fous ; une fiche par vague |
| Une vague | spec → plan(s) → SDD → simulation → `patch-notes-writer` → `memory-bank-sync` → compte rendu et suivi → arrêt | Vérificateur ≠ rédacteur ; preuve par commande ; boucle bornée à 3 tours ; le propriétaire teste, fusionne, tague |

### 1.2. Ce que coûtent les trois vagues livrées

Les chiffres viennent des §1 et §6 des trois comptes rendus. Les lignes ajoutées viennent de `git diff --shortstat` sur chaque commit de fusion.

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
| Lignes ajoutées dans `lib/`, `test/` et `assets/` | 4 325 | 4 963 | 5 692 |
| Lignes ajoutées dans `docs/` et le vault | 13 210 | 15 632 | 20 104 |
| Défauts remontés par ton test manuel | non noté | non noté | non noté |

La dernière ligne n'est pas un oubli de ce tableau : **aucun document ne la tient.** Aucune session de correction n'a été ouverte, ce qui suggère zéro défaut à ton test. C'est pourtant la seule mesure de qualité qui permettrait de juger si une économie de coût dégrade le résultat (§5).

### 1.3. Ce qui marche, et qu'il faut garder

- **Deux autorités qui ne se recopient pas** : le brainstorm dit le *quoi*, l'orchestration le *comment* et le *quand*, la ROADMAP renvoie aux deux. C'est la règle « une source de vérité par artefact » du [playbook SDLC d'Anthropic](https://claude.com/blog/the-ai-native-sdlc-playbook). Yegge montre l'inverse : 605 plans en markdown concurrents, et des agents qui « *get dementia* ».
- **Le vérificateur n'est jamais le rédacteur, et il prouve ses constats.** Anthropic l'a mesuré : « *tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work* » ([harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- **Des portes vérifiées par commande** : à l'entrée, la CI, le tag et les porteurs de version ; à la sortie, tes gestes (test, PR, fusion, tag). C'est le placement que recommande le playbook : l'approbation humaine aux portes de livraison, pas pendant la construction.
- **Une reprise sur disque.** Le journal vit sur la branche, et §0.2 dit à une session comment retrouver sa vague. C'est le `claude-progress.txt` du [harnais long d'Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents), et le `STATE.md` de GSD.
- **L'autonomie déléguée par écrit** : l'arbre de décision de §5. Rare ailleurs. Superpowers s'en approche avec les *rulings* de SDD (des décisions consignées plutôt que des arrêts), que ton §3.5 recopie déjà dans le compte rendu.
- **Un oracle propre au domaine** : la simulation comparée à une référence suivie par git, en deux temps. Le post d'Anthropic sur le [compilateur C](https://www.anthropic.com/engineering/building-c-compiler) le dit : sans un vérificateur « *nearly perfect* », l'agent résout le mauvais problème.
- **La mesure de chaque vague** — temps, agents, jetons, coût. Aucune source lue ne mesure ainsi le coût par unité livrée. C'est elle qui rend possibles les constats de §1.4.
- **Le suivi non technique** : peu coûteux, et sans équivalent dans les outils lus.

### 1.4. Ce que les chiffres montrent

1. **Le coût est en amont du code.** L'implémentation coûte 28 $ en vague 3 sur 389 $. La spec en coûte 193 $, les plans 86 $. Optimiser l'exécution, par exemple avec le mode d'exécution intégré de Superpowers (moitié moins cher que SDD sur les modèles intermédiaires, selon ses notes de version), ne gagnerait que quelques pour cent.
2. **Les plans réécrivent le code.** En moyenne, une tâche du plan E3 partie 2 fait 740 lignes. Les vérificateurs rejouent les plans « tâche par tâche hors du dépôt ». Le code est donc écrit jusqu'à trois fois : dans le plan, dans le clone du vérificateur, puis par l'implémenteur.
3. **La vérification de la spec a une cible mobile.** En vague 3, les quatre premiers tours confient chacun la spec entière à un panel neuf, qui relit tout et rend encore 22, puis 15, 13 et 12 constats. Seuls les tours centrés sur les corrections finissent par converger : le cinquième rend 7 constats, dont un moyen, et le sixième rend « prête ».
4. **La gravité se gonfle au moment de consolider.** Au quatrième tour de la vague 3, les trois vérificateurs ont rendu « prête ». Le consolidateur a remonté deux constats de mineur à moyen, et la vague s'est arrêtée.
5. **Beaucoup de constats « moyens » sont des trous de test.** Le troisième tour de la vague 3 en a rendu trois sur trois. Un trou de test relève du plan, pas de la spec.
6. **Les arrêts coûtent surtout de l'attente.** Tu as levé les quatre arrêts le jour même, en partant chaque fois des recommandations du §13 de la spec. Sur les 32 points des trois levées de la vague 3, tu en as suivi 23 tels que recommandés. Pour les 9 autres, tu as choisi une variante : certaines touchent ce que le joueur voit (un badge, une infobulle, la parenthèse des mythiques), d'autres la forme technique (le relais sans accumulateur, les faits passés à `isSelectable`). Le premier arrêt de la vague 3 a coûté 15 h 55 d'attente ; les deux suivants, quelques minutes.
7. **La documentation croît plus vite que le code.** Sur trois vagues, la spec passe de 641 à 1 878 lignes et le ratio documentation / code reste au-dessus de 3. HumanLayer est revenu sur sa propre méthode en mars 2026 pour cette raison : « *a 1,000-line plan produces ~1,000 lines of code* », donc relire le plan n'épargne rien.

---

## 2. Ce que font les autres

### 2.1. La même chaîne, partout

Praticiens et outils convergent sur la même suite : clarifier, une question à la fois ; écrire une spec ; écrire un plan ; exécuter dans un contexte neuf ; vérifier ; commiter.

| Qui | Étapes | Artefacts | Ce qui est propre à chacun |
|:---|:---|:---|:---|
| **Harper Reed** (2025) *(secondaire)* | idée → spec → plan de prompts → exécution | `spec.md`, `prompt_plan.md`, `todo.md` | Les cases à cocher portent l'état d'une session à l'autre. Il dit lui-même que la méthode est « *single player* » |
| **Superpowers** (v6.4.2, 25/09/2026) | brainstorming → spec → plan → SDD → revue de branche | `docs/superpowers/specs/`, `plans/`, registre `.superpowers/sdd/<plan>/` | Cérémonie proportionnée (spike / bounded / architectural, v6.3) ; plans réduits aux décisions, avec une section *Review Focus* (v6.4) ; un relecteur par tâche (v6.0) |
| **HumanLayer → QRSPI** (2025 → mars 2026) *(secondaire)* | Questions → Research → Design (~200 lignes) → Structure → Plan → Implement | `thoughts/shared/research/`, `plans/` | Recherche « à l'aveugle » : des questions neutres sur le code, rédigées sans montrer les conclusions visées ; moins de 40 consignes par étape |
| **Ralph** (Huntley) | boucle : une tâche, des tests, un commit, la sortie | `specs/*.md`, `IMPLEMENTATION_PLAN.md`, `AGENTS.md` limité à 60 lignes | « *The plan is disposable* » ; un nouveau mode d'échec donne une ligne de garde-fou (*sign*) |
| **Compound Engineering** (Every) | brainstorm → plan → work → review → **compound** | `docs/plans/`, `docs/solutions/` | Chaque cycle consigne ses leçons, et la planification suivante les relit |
| **Spec Kit** (v1.1.0, 02/10/2026) | constitution → specify → clarify → plan → tasks → analyze → implement → **converge** | `constitution.md`, `specs/###/…`, `tasks.md` avec les marques `[P]` | `analyze` : contrôle de cohérence en lecture seule, gravités, taux de couverture ; `converge` : la spec relue comme intention face au code ; préréglage léger « TinySpec » |
| **Kiro** *(extraits)* | requirements (EARS) → design → tasks | `.kiro/specs/<f>/`, `.kiro/steering/` | Critères d'acceptation « QUAND… ALORS LE SYSTÈME… » ; chaque tâche renvoie à ses exigences |
| **BMAD** (v6.12) | analyst → PM → architect → dev | PRD, architecture, `tickets.toml`, `sprint-status.yaml` | Une **rétrospective par epic, preuves à l'appui**, dont les actions sont vérifiées à l'epic suivant ; seul un humain passe un ticket à `done` |
| **Anthropic**, [Best practices](https://code.claude.com/docs/en/best-practices) | explore → plan → implement → commit | `SPEC.md`, puis une session neuve pour l'exécuter | « *If you could describe the diff in one sentence, skip the plan* » ; un relecteur adverse dans un contexte neuf |

### 2.2. Au niveau d'un programme : qui fait comme toi

**Attention au vocabulaire.** Chez toi, une *vague* est une version livrée en série. Chez GSD et Kiro, une *wave* est un paquet d'unités indépendantes exécutées **en parallèle**, calculé sur un graphe de dépendances. Ta vague correspond à une *phase* de GSD, à un *epic* de BMAD, à un *track* de Conductor. Ton programme correspond à un *milestone* de GSD.

- **GSD** (dépôt archivé le 26/06/2026 ; `open-gsd/gsd-core` le continue selon des sources tierces) est le plus proche. Ses fichiers vivent sous `.planning/` :
  - `ROADMAP.md` donne, pour chaque phase : *Goal*, *Depends on*, *Requirements*, *Success Criteria (what must be TRUE)*, *Plans* ;
  - `STATE.md` tient la position courante, les blocages, les décisions et la continuité de session ;
  - les décisions sont numérotées `D-01`, `D-02`… Une barrière bloquante exige que chacune apparaisse dans au moins un plan ;
  - le vérificateur de plan refuse une tâche sans commande de vérification automatique ;
  - une phase n'est close que si un `VERIFICATION.md` qui passe existe sur disque. Une case cochée n'est qu'une annotation ;
  - le mode `/gsd-quick` traite les petites corrections sans cérémonie.
- **BMAD** : une session de construction est l'unité, un epic en regroupe plusieurs. Le *readiness gate* rend PASS, CONCERNS ou FAIL. La rétrospective est fondée sur des preuves. Sa variante **BMad Loop** est un orchestrateur Python déterministe, « *No LLM in the control loop* ».
- **Conductor** (Gemini) : un registre `tracks.md` et, à la fin de chaque phase, un protocole de vérification dont le rapport est attaché en *git notes*.
- **Dépôts communautaires « wave »** :
  - [claude-wave-orchestration](https://github.com/warao-shikyo/claude-wave-orchestration) publie un `ANTI-PATTERNS.md` concret : l'orchestrateur n'implémente rien ; un résumé court pour l'orchestrateur, un long pour l'humain ; le périmètre se fige à la création du plan ; un signal STOP explicite ;
  - [wave-planning](https://github.com/ArunPrakashG/wave-planning) utilise un bloc d'état dans le plan et choisit le modèle selon le risque de la tâche.

### 2.3. Ce qui a changé en 2026

1. **La cérémonie se proportionne à la tâche** : Superpowers 6.3, Spec Kit TinySpec, Kiro Quick Plan, GSD quick. La doc d'Anthropic dit de sauter le plan quand le diff tient en une phrase.
2. **Les plans maigrissent.** Superpowers 6.4.2 : un plan donne les signatures, les assertions, les valeurs et la commande de vérification, sans le code. Son auto-revue compare sa longueur à celle de la spec : « *a plan several times longer than the spec is a transcript* ». Ses notes de version annoncent une planification environ quatre fois plus rapide et trois fois moins gourmande en jetons. Elles donnent pour motif l'excès de zèle des modèles de pointe actuels quand ils écrivent un plan.
3. **L'état se lit par machine.** `feature_list.json` (Anthropic), `STATE.md` avec frontmatter (GSD), `sprint-status.yaml` (BMAD), `state.json` (wave-skills). Anthropic dit avoir choisi le JSON parce que le modèle « *is less likely to inappropriately change or overwrite JSON files compared to Markdown* ».
4. **Le contrôle se fait par script, la création par le modèle.** BMad Loop, les scripts bash de CCPM, les workflows YAML de Spec Kit avec leurs étapes *gate*. Côté Claude Code : hooks, `/goal`, workflows.
5. **La boucle se ferme** : `converge` de Spec Kit, plans de comblement de GSD (*gap-closure*), étape *compound* d'Every.
6. **Le processus se corrige, pas le livrable.** Anthropic, [migrations à grande échelle](https://claude.com/blog/ai-code-migration) : « *you don't fix the code. You fix the process (loop) that produced the code* » ; « *Front-load the human hours* » ; « *Make the work queue mechanical and resumable* » ; « *Review loop results, not code* ».

### 2.4. Les critiques qui reviennent

| Critique | Qui | Ce qui te concerne |
|:---|:---|:---|
| **Mer de markdown** : 1 300 lignes pour afficher une date, 2 000 lignes pour une seule phase de plan | Zaninotto (marmelab), Scott Logic, Böckeler *(secondaire)* | Ratio documentation / code supérieur à 3 (§1.2) |
| **Relire du markdown est plus pénible que relire du code**, et les plans n'épargnent pas la lecture | Böckeler ; Horthy *(secondaire)* | Tu ne relis pas les plans : les vérificateurs le font. Le coût passe dans les jetons |
| **Un relecteur trouve toujours quelque chose**, et poursuivre chaque constat mène à la sur-ingénierie | [Best practices](https://code.claude.com/docs/en/best-practices) | §1.4, points 3 et 4 |
| **Trop de consignes** : un prompt ou un `CLAUDE.md` trop long est suivi en partie | Best practices ; Horthy (150 à 200 consignes au plus) | 636 lignes d'orchestration ; des contraintes recopiées dans chaque gabarit |
| **Dérive documentaire** : des documents périmés ou concurrents égarent les agents | Yegge ; Böckeler (des *sensors* contre la dérive) | Les références `fichier:ligne` se périment de vague en vague, et chaque fiche doit être « à revérifier, pas à croire » |
| **Coût et latence** : « *10x more tokens* », une heure pour une ligne en SDD | Commentaires HN sur Superpowers *(secondaire)* | §1.2 |
| **Dette cognitive** : le développeur perd le modèle mental d'un code qu'il n'a pas écrit | Willison ; l'« usine sans humain » de Dex Horthy (HumanLayer), dégradée en trois mois *(secondaire)* | Tu testes le comportement ; rien ne t'aide à lire le code |

### 2.5. Ce que dit Anthropic, en résumé

- **Chaîne et portes** : une suite fixe d'étapes, une barrière programmatique entre deux. Des conditions d'arrêt, dont un nombre maximal d'itérations ([Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)).
- **Une unité par session**, terminée dans un état propre, fusionnable, commitée et notée au journal. En ouvrant la session : lire `git log` et le journal, lancer un test de fumée ([harnais long](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).
- **Un contrat avant le code** : le générateur et l'évaluateur s'accordent sur ce que « fini » veut dire avant d'écrire une ligne (*sprint contract*, [harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps)).
- **Quatre degrés de barrière** pour la vérification : dans le prompt, par `/goal`, par un hook `Stop`, par un sous-agent vérificateur. Montrer les preuves plutôt qu'affirmer le succès ([Best practices](https://code.claude.com/docs/en/best-practices)).
- **Les skills conseillent, les hooks garantissent** : « *A skill is an advisory control while a hook is the deterministic layer behind it.* » Et : « *an agent fixing code must not be able to weaken the check on that code* » ([playbook SDLC](https://claude.com/blog/the-ai-native-sdlc-playbook)).
- **Le harnais se réexamine** : « *every component in a harness encodes an assumption about what the model can't do on its own, and those assumptions are worth stress testing* ». Une étape qui ne rapporte plus son coût se retire au changement de modèle (harness design).
- **Divulgation progressive** : un `SKILL.md` de moins de 500 lignes qui renvoie à des fichiers ; un `CLAUDE.md` de moins de 200 lignes ; les sous-agents définis dans `.claude/agents/` avec leurs outils et leur modèle ([skills](https://code.claude.com/docs/en/skills), [memory](https://code.claude.com/docs/en/memory), [sub-agents](https://code.claude.com/docs/en/sub-agents)).

---

## 3. La comparaison, point par point

Légende du verdict : ✅ en avance · 🟰 aligné · 🟠 à combler.

| Dimension | Toi | Les autres | Verdict |
|:---|:---|:---|:---:|
| Découpage d'un programme | Vagues = versions en série, lots, parties | GSD : milestone → phase → plan ; BMAD : initiative → epic → story | 🟰 |
| Source de vérité des décisions | Brainstorm §1, D1 à D75, acquises | GSD `CONTEXT.md` `D-xx` ; Spec Kit `constitution.md` | ✅ — plus strict, mais amendé en place dans un document de 561 lignes |
| Couverture décisions → lots | Table §7.1, vérifiée à la main par deux passes | GSD : barrière bloquante automatique | 🟰 |
| État et reprise | Journal markdown sur la branche ; algorithme §0.2 | `STATE.md`, `state.json`, `feature_list.json` | 🟰 — mais rien ne le lit par machine, et les cellules « Arrêts » font plus de 200 mots |
| Portes d'entrée et de sortie | Table de commandes, rejouée à la main | GSD *disk-strict* ; Conductor *git notes* ; BMAD *readiness gate* | ✅ sur le contenu, 🟠 sur la forme : pas de script |
| Vérification de la spec | Panel neuf, preuves, 4 gravités, 3 tours | Spec Kit `analyze` ; Superpowers : 3 itérations au plus ; Anthropic : seulement ce qui touche la correction | ✅ sur le principe, 🟠 sur la convergence |
| Épaisseur du plan | Transcription du code, rejouée deux fois | Superpowers 6.4.2 : des décisions ; QRSPI : un plan issu d'un *structure outline* | 🟠 |
| Vérification de l'implémentation | SDD : une revue par tâche, une revue d'ensemble | Pareil ; Spec Kit `converge` ajoute la spec relue face au code | 🟰, sans la relecture de la spec face au code |
| Oracle propre au domaine | La simulation, son diff de référence | Rare | ✅ |
| Arbitrage autonome | Arbre à 8 filtres, arbitrages consignés | Superpowers : *rulings* ; ailleurs, on s'arrête | ✅ — mais il ne distingue pas la question produit de la question technique |
| Garde-fous | Texte, dans chaque gabarit | Hooks, permissions, protection de branche | 🟠 |
| Parallélisme | Tout en série ; panels de vérification en parallèle | GSD et CCPM : worktrees par plan ou par epic | 🟰 — ton ordre est forcé (§1 de l'orchestration), et le parallélisme n'apporterait rien |
| Cérémonie proportionnée | La même pour tous les lots (le « poids » ne règle que le découpage en parties) | Généralisée en 2026 | 🟠 |
| Apprentissage d'une vague à l'autre | « Trouvé périmé » dans le compte rendu ; amendements par revue avant la vague 1 | Compound `docs/solutions/` ; rétrospective BMAD | 🟠 |
| Mesure | Temps, agents, jetons, coût, par étape | Quasi absente | ✅ — mais le script de mesure se réécrit à chaque vague, et la qualité n'est pas mesurée |
| Communication non technique | Suivi des vagues, notes de version | Absente | ✅ |
| Clôture du programme | Une session de clôture | GSD : audit des points ouverts à la fin d'un milestone | 🟰 |

---

## 4. Recommandations, classées

Chaque recommandation donne le constat, ce que font les autres, la proposition et son coût. Le [modèle compagnon](05-10-2026_modele_orchestration_par_vagues.md) les intègre, marquées ★ et numérotées Rn.

### Priorité 1 — fort gain, faible coût

**R1. Des plans qui consignent des décisions, pas du code.**
- *Constat* : les plans prennent 38 %, 37 % puis 24 % des jetons des trois vagues. Ils transcrivent le code (673 blocs dans un seul plan), et leurs rédacteurs comme leurs vérificateurs les rejouent dans un clone (§1.4, point 2).
- *Ailleurs* : Superpowers v6.4.2 et QRSPI.
- *Proposition* : par tâche, donner les fichiers, les signatures exactes, les valeurs de la spec, les tests nommés avec leur assertion clé, la commande de vérification et le total de tests attendu. Le code complet ne s'écrit que pour un algorithme imposé par la spec, ou pour une tâche marquée « à risque » par la fiche. Le plan ouvre sur une section *Review Focus* : les cinq modes d'échec au plus que la spec implique et qu'aucun test ne garde encore. Le vérificateur contrôle la cohérence et le décompte des tests ; il ne rejoue dans un clone que les tâches à risque. Ajouter un contrôle d'auto-revue : un plan plus de trois fois plus long que sa spec est une transcription.
- *Coût* : réécrire les gabarits §4.3 et §4.4. Mettre Superpowers à jour en v6.4.2 ou plus apporte une partie du changement d'office.
- *Gain attendu* : à mesurer. Superpowers annonce environ trois fois moins de jetons pour la planification.

**R2. Une vérification de spec qui converge.**
- *Constat* : §1.4, points 3 à 5.
- *Ailleurs* : Anthropic, « *flag only gaps that affect correctness or the stated requirements* » ; Superpowers v5.0.4 a relevé le seuil des constats bloquants et réduit sa grille à 4 ou 5 catégories ; les migrations d'Anthropic, deux relecteurs et un troisième qui départage.
- *Proposition*, en quatre règles :
  1. **Une grille de gravité avec des critères** : *bloquant* contredit une décision acquise ou rend l'implémentation impossible ; *moyen* produirait un comportement faux ou un test rouge que le plan ne verrait pas.
  2. **Un trou de test n'est pas un constat de spec** : il descend dans le *Review Focus* du plan (R1).
  3. **À partir du deuxième tour, la vérification est différentielle** : un vérificateur neuf, centré sur les corrections et sur ce qu'elles touchent, comme les tours 5 et 6 de la vague 3. Une relecture complète n'est refaite que si une correction change le périmètre.
  4. **Un consolidateur ne relève la gravité d'un constat qu'avec une preuve reproduite** par une commande ; il le dit en clair.
- *Coût* : réécrire le gabarit §4.2 et le texte de §3.3.

**R3. N'arrêter la vague que pour ce qui t'appartient.**
- *Constat* : quatre arrêts, tous levés à partir des recommandations, avec une variante sur un point sur trois environ (§1.4, point 6). L'arrêt sert donc à quelque chose. Mais il bloque toute la vague pour des questions qui auraient pu être posées avant, ou regroupées.
- *Ailleurs* : Superpowers, des décisions consignées plutôt que des arrêts (les *rulings* de SDD) ; les migrations d'Anthropic, « *Front-load the human hours* ».
- *Proposition* : chaque question reçoit une classe.
  - **T** — technique, invisible du joueur : l'orchestrateur tranche, comme aujourd'hui.
  - **P** — produit, visible du joueur : elle t'appartient. L'éclaireur (R8) la pose **avant** la vague, ou elle attend, regroupée avec les autres, dans un seul arrêt.
  - **D** — elle amende une décision acquise : arrêt, comme aujourd'hui.

  Après trois tours sans convergence, la suite dépend d'un **niveau d'autonomie** que tu fixes dans le prompt de lancement :
  - *strict* : l'arrêt d'aujourd'hui ;
  - *continu* : si tous les constats ouverts sont de classe T et ont une correction recommandée, l'orchestrateur l'applique, la consigne et ouvre un dernier tour différentiel. Il ne s'arrête que s'il reste un constat P ou D.

  Le risque du niveau *continu* est connu : tu as déjà choisi des variantes techniques, et en renverser une après l'implémentation coûte une session de correction. Le compte rendu doit donc séparer clairement les arbitrages faits sans toi.
- *Coût* : réécrire §5 et §6 ; ajouter une colonne « classe » à la liste « À arbitrer » des fiches.

**R4. Des garde-fous mécaniques plutôt que du texte.**
- *Constat* : « jamais `git push`, jamais `dart format`, jamais `git add -A`, jamais de worktree, jamais `reset --hard` » est recopié dans §3.5, §4.3, §6 et chaque plan. ADR-103 le reconnaît : `main` n'est pas protégé côté GitHub, la règle « ne tient que par le texte ».
- *Ailleurs* : Anthropic, les hooks sont « *deterministic* », `CLAUDE.md` est « *advisory* ».
- *Proposition* :
  - **(a)** protéger `main` sur GitHub : PR obligatoire, CI verte ;
  - **(b)** un hook `PreToolUse` qui bloque les gestes interdits, seulement quand la branche courante est une branche de vague (esquisse dans le modèle, §5.2). Une règle de permission globale ne convient pas : les sessions cloud, comme celle qui écrit cet audit, doivent pousser leur branche ;
  - **(c)** une fois les garde-fous en place, retirer leur texte des gabarits : moins de consignes, mieux suivies.
- *Coût* : environ une heure pour (a) et (b), à tester sur une branche jetable.

**R5. Des scripts pour tout ce qui se calcule.**
- *Constat* : la porte d'entrée est une table de neuf commandes, rejouée à la main par le modèle. Le script de mesure des statistiques « s'écrit dans le scratchpad, il n'entre pas dans le dépôt » (§3.8) : il est réécrit à chaque vague, et rien ne garantit que les définitions restent les mêmes d'une vague à l'autre. Le décompte des tests attendus par tâche et l'existence des `fichier:ligne` cités se vérifient aussi par calcul.
- *Ailleurs* : BMad Loop (« *No LLM in the control loop* ») ; CCPM ; Anthropic, « *Make review adversarial and verification mechanical* ».
- *Proposition* : sous `tool/vagues/`, trois scripts, propres à `dart analyze` s'ils sont en Dart :
  - `porte_entree` : rend 0 ou la liste des échecs ;
  - `mesure_session` : les statistiques de §3.8, mêmes définitions pour toutes les vagues ;
  - `verifier_references` : chaque `chemin:ligne` et chaque symbole cité existe.

  Les vérificateurs les lancent avant de lire.
- *Coût* : une petite vague d'outillage, ou une tâche de plan, plus la section « Tooling » de `CLAUDE.md`, qui annonce aujourd'hui deux scripts sous `tool/`.

### Priorité 2 — structurant, à décider avant le prochain chantier

**R6. Séparer la méthode du chantier.**
- *Constat* : sur les 636 lignes du fichier d'orchestration, environ 300 sont génériques : le cycle §3, les gabarits §4, l'arbre §5 et les garde-fous §6. Le reste est propre au chantier. Chaque session relit les deux, soit environ 54 000 jetons, et le prochain chantier devra tout recopier.
- *Ailleurs* : skills d'Anthropic (divulgation progressive, moins de 500 lignes) ; tous les frameworks séparent la méthode, installée une fois, de l'instance de projet.
- *Proposition* :
  - un skill de projet `.claude/skills/orchestration-par-vagues/` : `SKILL.md` porte le cycle ; `references/` porte les gabarits ; `scripts/` porte R5 ;
  - des sous-agents dans `.claude/agents/` (rédacteur, vérificateur sans outil d'édition, correcteur, éclaireur), chacun avec ses outils et son modèle ;
  - le fichier de chantier ne garde que l'en-tête, l'état, les vagues, le journal, la cohérence, les fiches et les rétrospectives : 200 à 300 lignes.
- *Coût* : une demi-journée, plus un ADR. **Pas pendant le chantier en cours** : on ne change pas de méthode entre la vague 4 et la vague 5 sans raison. À la clôture, ou à une vague 0 du chantier suivant.

**R7. Un état lisible par machine en tête du fichier.**
- *Proposition* : un bloc YAML en tête du fichier de chantier (vague courante, état, étape, branche, base de tests, arrêt ouvert). Le journal reste, avec des cellules courtes ; le récit d'un arrêt part dans le compte rendu.
- Un hook `SessionStart` peut afficher ce bloc à l'ouverture. Le script de porte d'entrée (R5) le lit et contrôle sa cohérence avec les branches.
- *Ailleurs* : `feature_list.json` (Anthropic), `STATE.md` (GSD).

**R8. Un éclaireur pour la vague suivante, pendant ton test.**
- *Constat* : entre la porte de sortie et la vague suivante, la machine attend ton test et ta fusion. Puis la vague suivante découvre que sa fiche est périmée (« à revérifier, pas à croire ») et rencontre ses questions de produit en pleine spec.
- *Proposition* : une session courte, lancée sur la branche livrée, qui n'écrit que la fiche N+1, en un commit qui part dans `main` avec la vague. Elle re-mesure la fiche, liste ses prémisses fausses et rédige les questions de classe P (R3), chacune avec ses options et une recommandation. Tu y réponds avec ta fusion, et la vague N+1 part avec ses réponses.
- *Ailleurs* : « *Front-load the human hours* » ; le *readiness gate* de BMAD ; `analyze` de Spec Kit avant l'implémentation.
- *Coût* : un gabarit de plus. Une session courte par vague, sans écriture hors de la fiche.

**R9. Une rétrospective qui modifie la méthode.**
- *Constat* : le compte rendu dit ce qui est périmé et mesure le coût, mais rien ne transforme une leçon en changement de méthode. La vague 3 a coûté 42 % de plus que la vague 2 pour une raison identifiée (la spec), sans que la méthode en tire une règle.
- *Ailleurs* : `docs/solutions/` d'Every, avec un filtre : « *non-obvious, durable, material* » ; la rétrospective BMAD, qui vérifie les actions de la précédente ; Anthropic, « *you fix the process* ».
- *Proposition* : une section « Leçons » en fin de compte rendu, cinq au plus, chacune soit **un amendement proposé à la méthode**, soit une ligne de `CLAUDE.md`, soit rien. Plus un tableau de bord dans le fichier de chantier : une ligne par vague (coût, tours de spec, arrêts, défauts trouvés à ton test), pour voir la dérive d'un coup d'œil.

### Priorité 3 — à essayer sur une vague, puis garder ou retirer

**R10. Des références par symbole plutôt que par ligne** dans les fiches et les specs (`effect_resolver.dart › createStatus` plutôt que `:16-93`). Les lignes bougent à chaque vague, les symboles rarement. Les plans, écrits juste avant d'être exécutés, gardent les lignes.

**R11. Une cérémonie proportionnée au lot.** La fiche donne une classe au lot :
- *léger* : spec et plan fusionnés, un tour de vérification ;
- *standard* : le cycle d'aujourd'hui ;
- *lourd* : un panel, et un découpage en parties.

Les vagues 6 et 7 (« moyen : une spec, un plan ») s'y prêtent, et une revue de brainstorm peut se fondre dans la vérification de la spec pour un sujet borné.

**R12. Une recherche « à l'aveugle » dans la revue d'un brainstorm** (QRSPI). L'agent qui confronte un brainstorm au code reçoit d'abord des questions neutres (« comment le jeu calcule-t-il X ? »), sans les conclusions du brainstorm. La comparaison vient ensuite. C'est l'antidote au biais de confirmation. Ta revue du 29/09 a trouvé 27 affirmations exactes sur 35 : l'essai dirait si une recherche neutre en trouve davantage de fausses.

**R13. Une passe de convergence en fin de vague** (`converge` de Spec Kit, le vérificateur de GSD). Un agent relit les décisions de la spec comme une intention, face au code de la branche, et liste les écarts : une ligne de la spec sans code, ou du code sans ligne de la spec. La revue d'ensemble de SDD compare le code au plan ; aucune étape ne le compare à la spec. Une lecture guidée du diff, pour toi, peut s'y joindre : c'est la réponse de Willison à la dette cognitive.

### Ce que je ne recommande pas

- **Paralléliser l'implémentation** (vagues au sens de GSD, worktrees de CCPM, agent teams) : ton ordre est forcé, chaque vague s'écrit sur le code de la précédente, et les fichiers générés par Flutter rendent les fusions coûteuses. La doc d'Anthropic déconseille les agent teams pour les « *sequential tasks, same-file edits* ». Le parallélisme reste utile en lecture seule : panels, éclaireur, recherche.
- **Changer de framework** (Spec Kit, BMAD, GSD) : tu perdrais l'intégration avec tes ADR, ton vault et tes skills. Leurs idées s'empruntent une à une.
- **Retirer le vérificateur indépendant** pour économiser : il est l'épine dorsale de la méthode. Il faut le calibrer (R2), pas le supprimer.
- **L'autonomie complète** (boucle Ralph, `/lfg`, « usine sans humain ») : l'expérience de Dex Horthy chez HumanLayer, de juillet à novembre 2025, a dégradé un code en trois mois alors que chaque PR passait ses tests. Ta porte de sortie humaine est au bon endroit.
- **Les essaims de type Ruflo** : leur surcoût de coordination est la critique principale qu'on leur fait.

---

## 5. Un essai mesuré, sur la vague 4

Tu mesures déjà chaque vague : la vague 4 peut servir d'expérience au lieu d'un changement à l'aveugle.

1. **Avant** : trancher R1, R2 et R3, et seulement eux. R4 et R5 sont de l'outillage, sans effet sur le contenu. Les écrire dans un ADR qui amende ADR-103, et dans le fichier d'orchestration (§3.3, §3.4, §4.2 à §4.4, §5, §6).
2. **Ajouter la mesure qui manque** : le nombre de défauts remontés par ton test manuel et par une éventuelle session de correction, dans le compte rendu de la vague 4, et rétroactivement pour les vagues 1 à 3 (zéro, sauf erreur).
3. **Comparer** la vague 4 aux vagues 1 à 3 : coût par lot, tours de vérification, arrêts, lignes de plan par ligne de code, défauts à ton test. Le compte rendu fait déjà la comparaison de coût avec la vague précédente.
4. **Décider** à la vague 5 : garder, ajuster ou revenir en arrière. Un résultat à défauts constants et coût réduit valide l'essai ; une hausse des défauts le dément.

---

## Annexe A — Sources

*Lu directement* : contrôlé le 05/10 par l'auteur de cet audit ou par un agent de recherche. *(secondaire)* : connu par des extraits de recherche ou par un résumé tiers.

**Anthropic**
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) — 19/12/2024
- [How we built our multi-agent research system](https://www.anthropic.com/engineering/multi-agent-research-system) — 13/06/2025
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — 29/09/2025
- [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) — 26/11/2025
- [Building a C compiler with a team of parallel Claudes](https://www.anthropic.com/engineering/building-c-compiler) — 05/02/2026
- [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) — 24/03/2026, **lu directement**
- [How Anthropic runs large-scale code migrations with Claude Code](https://claude.com/blog/ai-code-migration) — 16/07/2026, **lu directement**
- [The AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) — 21/08/2026, **lu directement**
- Documentation de Claude Code : [Best practices](https://code.claude.com/docs/en/best-practices) (**lu directement**), [sub-agents](https://code.claude.com/docs/en/sub-agents), [skills](https://code.claude.com/docs/en/skills), [hooks](https://code.claude.com/docs/en/hooks), [memory](https://code.claude.com/docs/en/memory), [`/goal`](https://code.claude.com/docs/en/goal), [workflows](https://code.claude.com/docs/en/workflows), [agent teams](https://code.claude.com/docs/en/agent-teams)

**Frameworks**
- [obra/superpowers — RELEASE-NOTES](https://github.com/obra/superpowers/blob/main/RELEASE-NOTES.md) — v5.0.0 à v6.4.2 (25/09/2026), **lu directement**
- [GSD — USER-GUIDE](https://github.com/gsd-build/get-shit-done/blob/main/docs/USER-GUIDE.md) — archivé le 26/06/2026, **lu directement**, et [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core)
- [github/spec-kit](https://github.com/github/spec-kit) — v1.1.0, 02/10/2026, et sa [lettre de juin 2026](https://github.com/github/spec-kit/blob/main/newsletters/2026-June.md)
- [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) — v6.12, et [bmad-loop](https://github.com/bmad-code-org/bmad-loop)
- [OpenSpec](https://github.com/Fission-AI/OpenSpec) · [CCPM](https://github.com/automazeio/ccpm) · [Taskmaster](https://github.com/eyaltoledano/claude-task-master) · [Agent OS](https://github.com/buildermethods/agent-os) · [Compound Engineering](https://github.com/EveryInc/compound-engineering-plugin) · [Conductor](https://github.com/gemini-cli-extensions/conductor)
- Kiro, [kiro.dev/docs/specs](https://kiro.dev/docs/specs/) *(extraits)*

**Praticiens et critiques**
- Harper Reed, [My LLM codegen workflow atm](https://harper.blog/2025/02/16/my-llm-codegen-workflow-atm/) — 02/2025 *(secondaire)*
- Jesse Vincent, [Superpowers](https://blog.fsck.com/2025/10/09/superpowers/) — 10/2025 *(secondaire)*
- HumanLayer, [advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents) — 08/2025 ; la conférence de mars 2026 sur QRSPI *(secondaire)* ; une mise en œuvre, [matanshavit/qrspi](https://github.com/matanshavit/qrspi) ; l'expérience d'« usine sans humain », [résumée par ZenML](https://www.zenml.io/llmops-database/engineering-the-software-factory-why-model-training-limits-matter-for-production-code-generation) *(secondaire)*
- Geoffrey Huntley, [Ralph](https://ghuntley.com/ralph/), et [how-to-ralph-wiggum](https://github.com/ghuntley/how-to-ralph-wiggum)
- Every, [Compound engineering](https://every.to/guides/compound-engineering) *(secondaire)*
- Steve Yegge, [Beads](https://github.com/steveyegge/beads)
- Birgitta Böckeler, l'article sur Kiro, spec-kit et Tessl sur martinfowler.com — fin 2025 *(secondaire)*
- François Zaninotto, [The Waterfall Strikes Back](https://marmelab.com/blog/2025/11/12/spec-driven-development-waterfall-strikes-back.html) — 12/11/2025 *(secondaire)*
- Simon Willison, [Agentic Engineering Patterns](https://simonwillison.net/2026/Feb/23/agentic-engineering-patterns/) — 02/2026 *(secondaire)*
- Peter Steinberger, [Just Talk To It](https://steipete.me/posts/just-talk-to-it) — 14/10/2025 *(secondaire)*
- Addy Osmani, [The code agent orchestra](https://addyosmani.com/blog/code-agent-orchestra/) *(secondaire)*
- Emschwartz, [A rave review of Superpowers](https://emschwartz.me/a-rave-review-of-superpowers-for-claude-code/) — 04/2026 *(secondaire)*
- Dépôts communautaires : [claude-wave-orchestration](https://github.com/warao-shikyo/claude-wave-orchestration), [wave-planning](https://github.com/ArunPrakashG/wave-planning), [wave-skills](https://github.com/nicotrop/wave-skills)

## Annexe B — Le vocabulaire comparé

| Chez toi | GSD | BMAD | Spec Kit | Superpowers | Anthropic (harnais) |
|:---|:---|:---|:---|:---|:---|
| Chantier, programme | Milestone | Initiative | — | — | Projet |
| Vague (une version) | Phase | Epic | — | Sous-projet | — |
| Lot, partie | Plan | Story | Feature | Spec + plan | Feature |
| Tâche | Task | Ticket | Task | Task | — |
| Décision acquise `Dn` | `D-xx` dans `CONTEXT.md` | — | Principe de la constitution | — | — |
| Journal d'avancement | `STATE.md` | `sprint-status.yaml` | Cases de `tasks.md` | Registre SDD | `claude-progress.txt` |
| Porte d'entrée | — | Readiness gate | Constitution check | — | Routine d'ouverture de session |
| Compte rendu | `SUMMARY.md`, `VERIFICATION.md` | Rétrospective | — | — | — |
| Vague au sens de GSD et Kiro (lot parallèle) | Wave | — | Tâches `[P]` | — | — |
