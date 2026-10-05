# Modèle — le fichier d'orchestration d'un chantier livré par vagues

**Date** : 05/10/2026
**Rôle** : le squelette à copier pour ouvrir un chantier livré par vagues. Il sert de pendant à [`_modele_suivi.md`](../suivi_vagues_chantier/_modele_suivi.md), qui fixe le récit non technique ; celui-ci fixe le déroulé technique.
**Origine** : le [fichier d'orchestration du chantier en cours](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), dont il garde l'ossature, et l'[audit du 05/10](05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md), dont il intègre les recommandations. **★Rn** marque ce qui diffère du fichier actuel et renvoie à la recommandation n de l'audit, §4.
**Statut** : proposition. **Rien n'est adopté** : le fichier du chantier en cours reste la seule référence de ce chantier. §6 dit comment adopter le modèle, en tout ou en partie.

**Comment le lire** :

| § | Contenu |
|:---|:---|
| 1 | Où vit chaque chose : la méthode d'un côté, le chantier de l'autre |
| 2 | Ouvrir un chantier, dans l'ordre |
| 3 | Le squelette du fichier de chantier, à copier |
| 4 | Les gabarits des agents |
| 5 | Les annexes mécaniques — des esquisses, rien n'est installé |
| 6 | L'adoption |

---

## 1. Deux étages : la méthode et le chantier ★R6

Le fichier actuel mêle deux choses : une **méthode**, qui ne change pas d'un chantier à l'autre, et un **chantier**, qui vit le temps de ses vagues. Les séparer allège ce que chaque session relit et rend la méthode réutilisable.

| Contenu | Méthode — un exemplaire pour le dépôt | Chantier — un fichier par programme |
|:---|:---:|:---:|
| Le cycle d'une vague (portes, spec, plan, implémentation, fin de vague) | ✔ | |
| Les gabarits des agents et leurs rôles | ✔ | |
| Les filtres génériques de l'arbre de décision (mécanisme, architecture, lisibilité, périmètre) | ✔ | |
| Les filtres propres au programme (décisions acquises, valeurs mesurées, principes) | | ✔ |
| Les garde-fous mécaniques et la liste des arrêts | ✔ | |
| Les vagues, leurs versions, leur ordre et sa raison | | ✔ |
| L'état, le journal, les arrêts, le tableau de bord | | ✔ |
| La cohérence : décisions → vagues, transitions, oracle | | ✔ |
| Les fiches de vague | | ✔ |
| Les leçons de chaque vague | | ✔ — les amendements qu'elles proposent vont à la méthode |

**Deux manières d'appliquer ce tableau**, selon ce que le propriétaire décide :

- **A — sans skill.** La méthode reste dans les §3 à §6 du fichier de chantier, comme aujourd'hui. On copie ces sections depuis le fichier actuel et on y applique les ★ de §3 bis. Coût nul, mais chaque chantier recopie la méthode.
- **B — avec un skill.** La méthode vit dans `.claude/skills/orchestration-par-vagues/` (§5.4) et ses agents dans `.claude/agents/` (§5.1). Le fichier de chantier ne garde que ce qui lui est propre et cite le skill par sa version. Il tombe à 200 à 300 lignes.

Le squelette de §3 est écrit pour B. En A, ses §3 à §6 se remplissent avec le texte du fichier actuel.

---

## 2. Ouvrir un chantier, dans l'ordre

1. **Le brainstorm** fixe les décisions du propriétaire, numérotées `D1`… et dites acquises. C'est la source de vérité du *quoi*.
2. **La revue** confronte le brainstorm au code. ★R12 : l'agent qui vérifie contre le code reçoit d'abord des **questions neutres** (« comment le jeu calcule-t-il X ? »), sans les conclusions du brainstorm. La comparaison ne vient qu'ensuite. Les passes s'enchaînent jusqu'à zéro constat bloquant.
3. **L'oracle**, si le chantier touche des valeurs : une simulation, ou tout autre programme dont la sortie complète devient une référence suivie par git.
4. **Le fichier de chantier**, copié depuis §3 et nommé `<JJ-MM-AAAA>_orchestration_<chantier>.md`.
5. **Le suivi**, copié depuis `_modele_suivi.md`.
6. **La vague 0** : la ROADMAP redécoupée (une ligne par chantier, qui renvoie au fichier) ; un ADR de méthode si le chantier s'écarte de la méthode commune ; une ligne dans `docs/INDEX.md` ; une ligne dans la table « Documentation Map » de `CLAUDE.md`.
7. **Le rodage**, en session neuve, avant la vague 1 — c'est la « *shakedown cruise* » des migrations d'Anthropic, et ta sixième passe de revue. On rejoue la porte d'entrée de la vague 1, on remplit chaque gabarit de §4 avec la fiche 1, et on corrige le fichier. Une passe suffit ; une seconde seulement si la première change le cycle.

---

## 3. Le squelette du fichier de chantier

Ce qui suit se copie tel quel ; les `<…>` se remplissent et les commentaires HTML se retirent.

~~~~markdown
# Orchestration — <le chantier en clair>, de `<version de départ>` à `<version visée>`, vague par vague

**Date** : <JJ/MM/AAAA>
**Statut** : **ce fichier fait foi pour le déroulé du chantier** — l'ordre des vagues, ce que chacune livre, sa version, son état. **Les décisions de conception ne sont pas ici** : leur source de vérité est <lien vers le brainstorm>, §<n> (D1 à D<n>). Ce fichier les cite, il ne les recopie pas ; en cas d'écart, le brainstorm a raison sur le *quoi*, ce fichier sur le *comment* et le *quand*.
**Méthode** : le skill `orchestration-par-vagues`, version <n> <!-- ★R6 ; en A : « §3 à §6 de ce fichier » -->
**Périmètre** : <ce qui a été brainstormé>. Hors périmètre : <ce qui vient après>.
**Sources** : <brainstorm> ; <revue> ; <rapport de l'oracle et sa sortie de référence> ; `docs/ROADMAP.md` §<n>.
**Ce que les vagues écrivent** : l'état et le journal (§2, ici) ; un compte rendu par vague, `docs/superpowers/reports/<AAAA-MM-JJ>-<chantier>-vague-<N>-compte-rendu.md` ; le suivi en clair, `docs/suivi_vagues_chantier/<chantier>.md`.
**Vérifié contre** : `main` à `<sha>` (<date>) — <N> tests verts, `dart analyze` propre. Rodé le <date> : <ce que le rodage a rejoué>.

<!-- ★R7 — l'état, lisible par machine. Réécrit à chaque étape, dans le commit du document que l'étape produit, sur la branche de la vague. -->
```yaml
chantier: <id-du-chantier>
vague: <N>
etat: a_faire            # a_faire | en_cours | livree_sur_branche | close
etape: "-"               # "<lot> · <3.x> · <fait|en cours>"
branche: null
base_tests: <N>
total_tests: <N>
autonomie: strict        # strict | continu — ★R3, fixé par le prompt de lancement
arret_ouvert: null       # "<JJ/MM> · <étape> · <classe> · <motif en une ligne>" — le détail est dans le compte rendu
```

---

## 0. Pour la session qui ouvre ce fichier

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.** Tu gardes le fil, pas le détail : tu délègues la rédaction, la vérification et l'implémentation, et tu n'implémentes rien toi-même.

1. Lis `CLAUDE.md`, ce fichier en entier, puis <les sections du brainstorm à lire>.
2. **Trouve ta vague** — sur les branches d'abord, parce que l'état vit sur la branche de la vague :
   `git fetch` puis `git branch -a --list '<motif des branches de vague>' --no-merged origin/main`.
   - *Aucune branche ouverte* : bascule sur `main`, tire-le en avance rapide, lis l'état. Ta vague est la première « à faire ». Après la dernière vague, tu es la session de clôture (§8.<n>).
   - *Une branche ouverte* : bascule dessus et lis l'état **de la branche**.
     - « en cours » : reprends à l'étape notée, sur un arbre propre, `dart analyze` propre, tests verts ;
     - « livrée sur branche » : tu es une session de correction (§3.10) ;
     - `arret_ouvert` non nul : ne reprends que si le prompt dit ce qui a levé l'arrêt.
   - **Une reprise ne détruit rien** : un arbre sale se range par `git stash push -u`, un commit rouge se corrige par un commit.
3. **Passe la porte d'entrée** : `tool/vagues/porte_entree <version précédente> <branche de la vague>` ★R5. Elle rend 0, ou la liste de ce qui échoue ; dans ce cas, arrête-toi et dis pourquoi.
4. **Déroule le cycle** de la méthode, avec la fiche de ta vague (§8).
5. **Arbitre** les questions de classe T. Les questions de classe P t'arrivent tranchées par le propriétaire, ou t'arrêtent ; celles de classe D t'arrêtent (§5) ★R3.
6. **Arrête-toi à la porte de sortie.** Tu ne pousses rien, n'ouvres pas de PR, ne fusionnes pas, ne poses pas de tag.

**Le prompt qui lance une vague** :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `<chemin de ce fichier>` en entier : ce fichier fait foi. Tu es l'orchestrateur d'une vague : trouve laquelle comme son §0 le dit. Déroule son cycle avec le skill `orchestration-par-vagues`, en déléguant à des sous-agents, arbitre selon §5, respecte les garde-fous et arrête-toi à la porte de sortie. Autonomie : <strict | continu>. Réponses du propriétaire aux questions de l'éclaireur : <collées ici, ou « aucune »>. Réponds et écris en français.
````

**Le prompt d'une session de correction** :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `<chemin de ce fichier>` en entier. Tu ouvres une session de correction (méthode §3.10) sur la vague livrée sur la branche courante : lis son compte rendu, puis corrige ce qui suit, sans rien rouvrir d'autre. <ce que le test a trouvé ; les arbitrages renversés>. Réponds et écris en français.
````

**Le prompt de l'éclaireur** ★R8 — à lancer pendant le test du propriétaire, sur la branche livrée :

````
Tu travailles dans le dépôt <projet>. Lis `CLAUDE.md`, puis `<chemin de ce fichier>`. Tu es l'éclaireur de la vague <N+1> (méthode §4.6) : tu ne modifies que la fiche §8.<N+1> de ce fichier, en un seul commit sur la branche courante, et rien d'autre. Re-mesure son « État mesuré », liste les prémisses fausses, et rédige ses questions de classe P avec leurs options et ta recommandation. Ne pousse rien. Réponds et écris en français.
````

---

## 1. Les vagues et les versions

| Vague | Version | Lots | Cérémonie ★R11 | Ce que le joueur voit | Dépend de | Branche | Critère de sortie — ce qui doit être VRAI |
|:---:|:---|:---|:---|:---|:---|:---|:---|
| **0** | — | Méthode et ROADMAP | — | Rien | — | `docs/vague-0-<chantier>` | La ROADMAP renvoie à ce fichier ; l'ADR de méthode est écrit |
| **1** | `<x.y.z>` | <lots> | standard | <une phrase> | 0 | `feat/v<x.y.z>-<id>` | <deux ou trois faits vérifiables, chacun avec sa commande ou son test> |
| … | | | | | | | |
| **Clôture** | — | — | — | Rien | la dernière | `docs/cloture-<chantier>` | Le journal, la mémoire, la ROADMAP et le suivi disent le chantier clos |

**Un lot est ce qui reçoit une spec.** <Ce qui, dans ce chantier, n'est pas un lot au sens du cycle.>

**Pourquoi cet ordre.** <Une phrase par dépendance : ce que la vague N+1 lit de la vague N.>

**Dans une vague, tout se déroule en série.** Un lot après l'autre, une partie après l'autre : le document suivant s'écrit sur le code que le précédent a laissé sur la branche, jamais sur une prévision.

---

## 2. Le journal, les arrêts, le tableau de bord

**Le journal** a une ligne par vague, que chaque étape réécrit en même temps que le bloc d'état, dans le commit du document qu'elle note, sur la branche de la vague. Sur `main`, une vague commencée reste « à faire » jusqu'à sa fusion : c'est attendu.

| Vague | Version | État | Étape | Branche | Spec(s) | Plan(s) | Compte rendu | Tests | Livrée le | Close le |
|:---:|:---|:---|:---|:---|:---|:---|:---|---:|:---|:---|
| 0 | — | à faire | — | — | — | — | — | <base> | — | — |

**Les arrêts** — une ligne par arrêt, **une ligne de texte par cellule**. Le récit, les constats ouverts et les recommandations vont dans le compte rendu de la vague, qui s'ouvre au premier arrêt s'il n'existe pas encore.

| Vague | Date | Étape | Classe (P · D · autre) | Motif | Levée |
|:---:|:---|:---|:---|:---|:---|

**Le tableau de bord** ★R9 — une ligne par vague livrée, remplie par §3.8 de la méthode, depuis `tool/vagues/mesure_session` ★R5. C'est ce tableau qui dit si la méthode dérive.

| Vague | Coût (API) | Durée | Agents | Tours de spec | Tours de plan | Arrêts | Lignes de plan / lignes de code | Défauts au test du propriétaire | Leçon principale |
|:---:|---:|---:|---:|---:|---:|---:|---:|---:|:---|

---

## 3–6. La méthode

<!-- En B : une ligne — « Le cycle, les rôles, les gabarits, l'arbre de décision et les garde-fous sont ceux du skill `orchestration-par-vagues`, version <n>. Ce fichier n'en précise que ce qui suit. » — suivie des seules précisions propres au chantier :
- les filtres 1 à 3 de l'arbre de décision (décisions acquises, valeurs mesurées, principes du brainstorm) ;
- les commandes de l'oracle ;
- les contraintes du dépôt que les hooks ne couvrent pas ;
- les exceptions aux garde-fous, s'il y en a.
En A : les §3 à §6 du fichier actuel, avec les ★ du modèle (§3 bis du modèle). -->

---

## 7. La cohérence des lots — vérifiée le <date>

### 7.1. Chaque décision a une vague

| Famille | Décisions | Lot | Vague |
|:---|:---|:---|:---:|

**Vérifié par commande** : chaque `D<n>` du brainstorm apparaît dans au moins une fiche de §8, ou sur la ligne « Après `<version visée>` » ou « Méthode » de cette table. Une décision sans vague bloque la vague 1 — c'est la barrière de couverture de GSD.

### 7.2. Les transitions entre lots

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|

### 7.3. Ce que l'oracle impose

<Ce que l'oracle lit, ce qu'il tient en dur, et pour chaque vague : ce qui casse ou dérive, et ce que le plan doit réaligner. La règle des deux temps — d'abord le réalignement seul, diff vide ; puis chaque changement voulu, relancé à part, référence recommitée — est celle de la méthode.>

---

## 8. Les fiches de vague

« État mesuré » date du <JJ/MM> sur `<sha>` : **à revérifier, pas à croire**. L'éclaireur ★R8 le re-mesure avant chaque vague. Les listes « Pour `memory-bank-sync` » sont des minimums.

### 8.<N>. Vague <N> — `<version>` — <lots>

**Cérémonie** : léger | standard | lourd ★R11 — **Tâches à risque** : <celles dont le plan écrit le code entier, et que le vérificateur rejoue> ★R1
**Éclairée le** : <JJ/MM, sur `<sha>`> ★R8 — <ses prémisses corrigées, en une ligne>

#### <Lot> — <titre>

**Fichiers** : `<AAAA-MM-JJ>-<id>-<sujet>-design.md` pour la spec, le même nom sans `-design` pour le plan.
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
**Oracle** : <ce que le lot ne doit pas toucher sans relance ; ce que le plan réaligne>.
**Pour `memory-bank-sync`** : ADR <à ouvrir ou à amender> ; fiches <_rules et _patterns>.
**Ce que le joueur voit** : <ce que la note de version et le suivi diront>.

---

## 9. Les points ouverts

<Ce qui reste à trancher et n'appartient à aucune vague, avec qui le tranche et quand.>

## 10. Les leçons et les amendements proposés ★R9

Une ligne par leçon retenue par une vague : **non évidente, durable, qui change quelque chose**. Les autres restent dans le compte rendu.

| Vague | Leçon | Ce qu'elle propose | Décision du propriétaire |
|:---:|:---|:---|:---|
| <N> | <la leçon, une phrase> | amender la méthode §<n> · une ligne de `CLAUDE.md` · rien | <acceptée le JJ/MM · refusée · en attente> |
~~~~

### 3 bis. Les ★ de la méthode — ce qui change dans le cycle actuel

En A, ces changements s'appliquent aux §3 à §6 recopiés du fichier actuel. En B, ils sont dans le skill.

| Étape | Aujourd'hui | Avec le modèle |
|:---|:---|:---|
| **3.1 Porte d'entrée** | Neuf vérifications rejouées une à une par le modèle | ★R5 Un script, `tool/vagues/porte_entree`, qui lit aussi le bloc d'état ★R7 et le confronte aux branches. La table des vérifications reste, comme documentation du script |
| **3.3 Spec** | Rédiger → vérifier la spec entière → corriger → revérifier la spec entière, trois tours, puis arrêt | ★R5 `tool/vagues/verifier_references` avant toute vérification humaine ou agent : chaque `chemin`, `chemin:ligne` et symbole cité existe.<br>★R2 Le premier tour vérifie tout. **Les suivants sont différentiels** : les corrections et ce qu'elles touchent, par un vérificateur neuf. La grille de gravité a ses critères (§4.2). **Un trou de test n'est pas un constat de spec** : il descend au *Review Focus* du plan.<br>★R3 Après trois tours : en *strict*, l'arrêt ; en *continu*, la correction des constats de classe T, consignée, puis un dernier tour différentiel. L'arrêt ne vient que pour un constat P ou D |
| **3.4 Plan** | Le code de chaque tâche, écrit en entier ; le plan rejoué dans un clone par son rédacteur puis par son vérificateur | ★R1 **Le plan consigne des décisions** : fichiers, signatures, valeurs, tests nommés et leur assertion clé, commande de vérification, total attendu. Le code n'est écrit en entier que pour les **tâches à risque** de la fiche, et pour un algorithme imposé par la spec.<br>Une section *Review Focus* en tête : les cinq modes d'échec au plus que la spec implique et qu'aucun test ne garde encore.<br>Auto-revue : un plan plus de trois fois plus long que sa spec est une transcription. Seules les tâches à risque sont rejouées dans un clone |
| **3.5 Implémentation** | SDD ; dix contraintes recopiées à chaque agent | Inchangé sur le fond. ★R4 Les contraintes que le hook `garde_vague` garantit (push, PR, `dart format`, `git add -A`, worktree, `reset --hard`, `clean`) sortent des gabarits ; restent celles qu'aucun outil ne vérifie : données bilingues, id = nom de fichier, trois couches, pas de code mort, fichiers générés à ne pas indexer |
| **3.6 bis Convergence** | — | ★R13 Le code de la vague terminé, un agent relit les décisions de chaque spec comme une intention, face au code de la branche (§4.7). Ses écarts deviennent une tâche de correction, ou un constat consigné au compte rendu |
| **3.8 Compte rendu** | Arbitrages, cahier de test, oracle, trouvé périmé, statistiques mesurées par un script réécrit à chaque vague | ★R5 `tool/vagues/mesure_session` mesure les statistiques, avec les mêmes définitions pour toutes les vagues.<br>★R9 Une section « Leçons », cinq au plus, chacune avec son amendement proposé ; la ligne de la vague au tableau de bord ; les arbitrages faits sans le propriétaire (autonomie *continu*) séparés des autres |
| **3.9 Porte de sortie** | L'arrêt | Inchangé, plus ★R8 : le propriétaire lance l'éclaireur de la vague suivante pendant qu'il teste |
| **§4 Délégation** | Gabarits dans le fichier | ★R6 En B, des agents définis dans `.claude/agents/`, avec leurs outils et leur modèle ; les vérificateurs n'ont pas d'outil d'édition (§5.1) |
| **§5 Arbitrage** | Arbre à 8 filtres | ★R3 Une classe par question avant l'arbre : **T**, technique, tranchée par l'orchestrateur ; **P**, visible du joueur, tranchée par le propriétaire, de préférence avant la vague ; **D**, qui amende une décision acquise : arrêt |
| **§6 Garde-fous** | Texte | ★R4 `main` protégé sur GitHub ; le hook `garde_vague` (§5.2) ; ne restent en texte que les garde-fous de jugement : n'amender aucune décision acquise, ne pas élargir le périmètre, ne pas dire clos ce qui ne l'est pas |

---

## 4. Les gabarits des agents

Les gabarits du fichier actuel (§4.1 à §4.6) restent la base. On ne donne ici que ceux qui changent, et les deux nouveaux. **Règles communes**, inchangées :
- un agent part d'un contexte neuf, et reçoit tout ce qu'il lui faut par chemin de fichier ;
- le vérificateur n'est jamais le rédacteur ;
- un constat se prouve par une commande ou une citation ;
- l'orchestrateur ne garde de chaque agent que sa conclusion.

**Les rôles** ★R6 :

| Rôle | Agent (en B) | Modèle | Outils | Reçoit | Rend |
|:---|:---|:---|:---|:---|:---|
| Rédacteur de spec | `redacteur-spec` | le plus capable | lecture, écriture sous `docs/` | la fiche, le gabarit §4.1 | le chemin, la table des arbitrages |
| Vérificateur de spec | `verificateur-spec` | le plus capable | lecture, Bash, aucun outil d'édition | la spec, la fiche, le mode (complet ou différentiel) | la table de constats, « prête » ou « à corriger » |
| Rédacteur de plan | `redacteur-plan` | le plus capable | lecture, écriture sous `docs/` | la spec, la base de tests, les tâches à risque | le chemin, la carte des fichiers |
| Vérificateur de plan | `verificateur-plan` | le plus capable | lecture, Bash, aucun outil d'édition ; un clone jetable | le plan, la spec, la base de tests | la table de constats, « prêt » ou « à corriger » |
| Correcteur | `correcteur` | le plus capable | lecture, écriture sous `docs/` | le document et les constats | les constats traités, un par un |
| Implémenteur, relecteur | ceux de SDD | intermédiaire | ceux de SDD | la fiche de tâche de SDD | ceux de SDD |
| Éclaireur ★R8 | `eclaireur` | le plus capable | lecture, Bash, édition de la seule fiche | la fiche N+1, la branche N | les prémisses corrigées, les questions P |
| Convergence ★R13 | `verificateur-convergence` | le plus capable | lecture, Bash, aucun outil d'édition | les specs de la vague, la branche | la table des écarts |

### 4.2. Vérificateur de spec ★R2

````
Tu vérifies une spec que tu n'as pas écrite. Lis `CLAUDE.md` d'abord. Tu ne modifies aucun fichier.

La spec : <chemin>. Le lot : <lot>. Ses décisions : <liste D, avec leurs réserves>, texte dans <brainstorm> §<n>.
Mode : <complet — tout le document | différentiel — seulement les corrections listées ci-dessous et ce qu'elles touchent>.
<En différentiel : les corrections du tour précédent, avec les sections modifiées ; les arbitrages déjà tranchés par l'orchestrateur — ne les rouvre pas sans preuve neuve.>

Commence par lancer `tool/vagues/verifier_references <chemin de la spec>` et reporte ce qu'il rend.

Vérifie, chaque point par une commande ou une citation, jamais de mémoire :
1. Chaque décision du lot est couverte dans la part que la fiche lui donne, et aucune n'est contredite — cite la ligne du brainstorm.
2. Chaque item de « La spec doit fixer » est fixé, et chaque critère de sortie de la fiche a sa preuve prévue.
3. Chaque question de « À arbitrer » est tranchée, avec ses options, sa classe et son motif ; aucun arbitrage n'amende une décision acquise ni ne change une valeur mesurée.
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

### 4.3. Rédacteur de plan ★R1

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis `<chemin de la spec>` <§ de la partie>. Modèle de forme : `<plan de référence>` — but, architecture, contraintes globales, carte des fichiers, tâches titrées `### Task N: …`.

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

### 4.4. Vérificateur de plan ★R1

Celui du fichier actuel, avec deux changements :
- « **rejoue dans un clone les seules tâches à risque** : <liste> ; pour les autres, vérifie que les signatures existent ou sont créées par une tâche antérieure, que les tests nommés gardent ce que la spec demande, et que le décompte des tests tombe juste » ;
- « **vérifie la section Review Focus** : chaque mode d'échec est attribué à une tâche, qui écrit le test qui le garde ».

### 4.6. Éclaireur de la vague suivante ★R8

````
Tu es l'éclaireur de la vague <N+1> du fichier `<chemin>`. Lis `CLAUDE.md`, puis ce fichier en entier, puis la fiche §8.<N+1>. La vague <N> est livrée sur la branche courante et attend le test du propriétaire : c'est sur elle que tu mesures.

1. Re-mesure chaque ligne de « État mesuré » sur la branche courante, par commande. Corrige celles qui ont bougé, en citant le symbole plutôt que la ligne.
2. Liste les prémisses de la fiche que le code de la vague <N> rend fausses, et dis pour chacune si elle change le périmètre du lot.
3. Pour chaque question de « À arbitrer », donne sa classe (T · P · D). Pour chaque question de classe P, écris les options, ce que le joueur verrait avec chacune, et ta recommandation.
4. Ajoute les questions de classe P que la re-mesure fait apparaître.

Tu ne modifies que la fiche §8.<N+1>, en un seul commit sur la branche courante : il part dans `main` avec la vague <N>, sans PR de plus. Tu ne touches ni au code, ni à l'état, ni au journal, et tu ne pousses rien. Rends les questions de classe P, prêtes à recevoir la réponse du propriétaire — dans le prompt de lancement de la vague <N+1>, ou dans la dernière colonne de la table « À arbitrer » avant la fusion.
````

### 4.7. Vérificateur de convergence ★R13

````
Tu vérifies qu'une vague livre ce que ses specs décident. Lis `CLAUDE.md`. Tu ne modifies aucun fichier.

Les specs : <chemins>, sections « Décisions » et « Critères de sortie ». La branche : <branche>, depuis `<commit de départ de la vague>`.

Pour chaque décision et chaque critère de sortie : trouve le code et le test qui le portent, par une commande, et dis « livré », « partiel » ou « absent ». Puis cherche l'inverse : un comportement neuf du diff qu'aucune ligne des specs ne demande.
Ne juge ni le style ni la structure : la revue d'ensemble de SDD l'a fait.

Rends une table : décision ou critère, verdict, preuve, et pour chaque « partiel » ou « absent » la correction proposée. Puis la liste du code sans ligne de spec.
````

---

## 5. Les annexes mécaniques — des esquisses

**Rien de cette section n'est installé.** Chaque esquisse s'adopte par une tâche de plan, avec ses tests, et se valide contre la documentation de Claude Code du jour ([hooks](https://code.claude.com/docs/en/hooks), [sub-agents](https://code.claude.com/docs/en/sub-agents), [skills](https://code.claude.com/docs/en/skills)).

### 5.1. Un agent en lecture seule ★R6

`.claude/agents/verificateur-spec.md` :

```markdown
---
name: verificateur-spec
description: Vérifie une spec de lot qu'il n'a pas écrite, contre le brainstorm et le code de la branche, et rend une table de constats prouvés. À utiliser à l'étape 3.3 d'une vague.
tools: Read, Grep, Glob, Bash
model: <le plus capable>
---
<Le corps du gabarit §4.2 de ce modèle, sans ses parties variables : elles arrivent par le message de l'orchestrateur.>
```

Sans `Write` ni `Edit` dans `tools`, l'agent n'a plus d'outil d'édition. Il garde `Bash`, nécessaire à ses preuves par commande, et `Bash` peut écrire : une règle de permission ou un hook propre à l'agent ferme ce reste, si l'expérience montre qu'il le faut.

### 5.2. Le hook `garde_vague` ★R4

`.claude/hooks/garde_vague.sh` — testé le 05/10 sur un dépôt jetable :
- **bloqués** : `git push`, `git add .`, `git add -A`, `dart format`, `gh pr create`, `git reset --hard`, `git worktree add`, `git clean` ;
- **laissés passer** : `git add <chemin>`, `git tag -l`, `dart analyze`, `gh pr view`, `git reset HEAD~1`, et tout ce qui se fait hors d'une branche de vague.

```bash
#!/usr/bin/env bash
# Bloque les gestes de livraison quand la branche courante est une branche de vague.
cmd=$(jq -r '.tool_input.command // empty')
branche=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null)
case "$branche" in
  feat/v[0-9]*|docs/cloture-chantier-*) ;;
  *) exit 0 ;;
esac
interdit='(^|[;&|[:space:]])(git[[:space:]]+(push|clean|worktree[[:space:]]+add|reset[[:space:]]+--hard|add[[:space:]]+(-A|--all|\.)([[:space:]]|$))|gh[[:space:]]+(pr[[:space:]]+(create|merge)|release)|dart[[:space:]]+format)'
if printf '%s' "$cmd" | grep -Eq "$interdit"; then
  echo "Garde-fou de vague : « $cmd » est interdit sur la branche $branche (orchestration, §6)." >&2
  exit 2
fi
exit 0
```

Branché dans `.claude/settings.json` :

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/garde_vague.sh" }
        ]
      }
    ]
  }
}
```

**Pourquoi par branche et non par règle de permission** : une règle `deny` sur `git push` dans les réglages du projet bloquerait aussi les sessions qui doivent pousser leur branche, comme les sessions cloud. Le hook ne mord que sur une branche de vague. Il ne remplace pas la **protection de `main` sur GitHub** (PR obligatoire, CI verte), qui est le vrai verrou de « jamais sur `main` ».

### 5.3. La porte d'entrée en script ★R5

Esquisse de `tool/vagues/porte_entree.sh` : chaque ligne reprend une vérification de la table §3.1 du fichier actuel. Une version en Dart, propre à `dart analyze`, irait sous `tool/` comme le script de simulation.

```bash
#!/usr/bin/env bash
# Usage : tool/vagues/porte_entree.sh <version précédente> <branche de la vague>
set -u
prev="$1"; branche="$2"; echec=0
ok() { printf '✅ %s\n' "$1"; }
ko() { printf '❌ %s\n' "$1"; echec=1; }

[ -z "$(git status --porcelain)" ] && ok "arbre propre" || ko "arbre sale — git status"
git fetch -q origin
[ "$(git rev-list --left-right --count main...origin/main)" = "0	0" ] && ok "main à jour" || ko "main et origin/main divergent"
[ -z "$(git branch -a --list "*$branche")" ] && ok "branche absente" || ko "$branche existe : vague commencée, voir §0"
git merge-base --is-ancestor "v$prev" main 2>/dev/null && ok "v$prev est dans main" || ko "tag v$prev absent de main"
[ "$(gh run list --branch main --limit 1 --json conclusion -q '.[0].conclusion' 2>/dev/null)" = "success" ] \
  && ok "CI de main verte" || ko "CI de main non verte, ou gh injoignable — demander au propriétaire"
bash .github/scripts/verify_version.sh "$prev" >/dev/null && ok "porteurs de version à $prev" || ko "porteurs de version discordants"
dart analyze >/dev/null 2>&1 && ok "dart analyze propre" || ko "dart analyze sale"
sortie=$(flutter test 2>&1); code=$?
total=$(printf '%s\n' "$sortie" | tail -1 | grep -oE '\+[0-9]+' | head -1 | tr -d '+')
[ "$code" -eq 0 ] && ok "flutter test vert — base : ${total:-?}" || ko "flutter test rouge"

exit "$echec"
```

La version à écrire attend un run de CI `queued` ou `in_progress` au lieu d'échouer, contrôle aussi la release du tag, et confronte le bloc d'état ★R7 aux branches.

### 5.4. Le skill de méthode ★R6

```
.claude/skills/orchestration-par-vagues/
├── SKILL.md               # moins de 500 lignes : quand l'utiliser, le cycle 3.1 à 3.10, l'arbre générique, les arrêts
├── references/
│   ├── gabarits.md        # §4 : un gabarit par rôle
│   ├── grille-gravite.md  # la grille de §4.2, avec des exemples tirés des vagues passées
│   └── compte-rendu.md    # ce que §3.8 écrit, et les définitions des statistiques
└── scripts/               # ou sous tool/vagues/, s'ils doivent passer dart analyze
    ├── porte_entree.sh
    ├── verifier_references.dart
    └── mesure_session.dart
```

Le frontmatter porte `disable-model-invocation: true` : une vague se lance par le prompt du propriétaire, jamais d'elle-même. Le skill porte un numéro de version, que le fichier de chantier cite. Changer de version en cours de chantier est un amendement de méthode, consigné par un ADR.

---

## 6. L'adoption

**Pour le chantier en cours** — vagues 4 à 7 —, l'audit (§5) propose un essai mesuré sur la vague 4. Ce qui peut s'appliquer sans changer l'ossature :

| Changement | Applicable en cours de chantier | Où, dans le fichier actuel |
|:---|:---:|:---|
| R1 — plans de décisions | ✔ | §3.4, §4.3, §4.4 ; la ligne « Tâches à risque » dans les fiches 8.4 à 8.7 |
| R2 — vérification de spec qui converge | ✔ | §3.3, §4.2 |
| R3 — classes de questions, autonomie | ✔ | §0 (prompt), §3.3, §5, §6 |
| R4 — hook et protection de `main` | ✔ | `.claude/`, GitHub ; §3.5 et §6 allégés |
| R5 — scripts | ✔, par une tâche de plan | §3.1, §3.8 |
| R9 — leçons et tableau de bord | ✔ | §2, §3.8 |
| R8 — éclaireur | ✔, à partir de la vague 5 | §0, §3.9, §4 |
| R13 — convergence | ✔ | entre §3.6 et §3.7 |
| R6, R7, R10, R11 — skill, état YAML, références par symbole, cérémonie | **au prochain chantier** | — |

Adopter tout ou partie, c'est :
1. une décision du propriétaire, consignée dans le brainstorm du chantier (la méthode y est décidée : D69 à D74) ;
2. un ADR qui amende ADR-102 et ADR-103 ;
3. la correction du fichier d'orchestration, sur une branche de documentation fusionnée avant la vague suivante.

**Pour le prochain chantier**, le modèle quitte `possible_upgrades/` : par exemple vers `docs/orchestration/_modele_orchestration.md`, les fichiers de chantier rangés à côté. Ce répertoire neuf demande sa ligne dans la table « Documentation Map » de `CLAUDE.md`, et dans `docs/INDEX.md`.
