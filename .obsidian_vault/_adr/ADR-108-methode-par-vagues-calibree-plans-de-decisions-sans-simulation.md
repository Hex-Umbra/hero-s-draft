---
description: Amends ADR-102 and ADR-103 after measuring three delivered waves — plans record decisions instead of transcribing code, spec verification is differential from the second round with a criteria-based severity grid, every question carries a class (technical, product, decision) and a per-wave autonomy level, the spec keeps only its choices, no wave re-runs the simulation, the technical report is capped at 150 lines with the manual test book in its own file, tooling versions are recorded; wave 4 is the measured trial
---

# ADR-108 — La Méthode par Vagues, Calibrée après Trois Vagues : des Plans de Décisions, une Vérification qui Converge, des Questions Classées, Plus de Simulation, un Compte Rendu Court

### Statut

✅ Accepté — 2026-10-13, par le propriétaire, sur l'[audit du workflow](../../docs/possible_upgrades/05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md) et ses recommandations R1 à R3, R14 à R16, R22, R24 et R31 (§6.6).
**Amende [ADR-102](ADR-102-chantier-par-vagues-une-version-par-vague.md)** sur D2 (la forme des plans, le cycle), D3 (la boucle de vérification) et D4 (l'arbitrage, la valeur mesurée) ; **amende [ADR-103](ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md)** : D5 retirée, D6 précisée. **Décision de méthode, sans code** : `lib/`, `test/` et `assets/` sont inchangés. Vaut pour les vagues 4 à 7 du programme P-43 → P-42 → P-44 lot 1, la vague 4 étant l'essai mesuré (D8).

### Contexte

Trois vagues sont livrées et mesurées ([audit](../../docs/possible_upgrades/05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md), §1.2). Les specs et les plans prennent 73 à 76 % des jetons de chaque vague, l'implémentation 5 à 8 % ; le coût passe de 172 à 273 puis 389 $ au tarif de l'API, de 0,040 à 0,068 $ par ligne de code ajoutée. Les plans transcrivent le code : celui de la partie 2 d'E3 fait 11 136 lignes et 673 blocs, et ses vérificateurs le rejouent dans un clone. La vérification de la spec a cessé de converger : six tours et trois arrêts en vague 3, chaque tour confiant la spec entière à un panel neuf, les constats « moyens » étant pour l'essentiel des trous de test. Le gabarit de plan imposait la transcription (« cite le code tel qu'il est »), avec pour modèle de forme le plan de P-49, 3 627 lignes et 249 blocs.

Le propriétaire a aussi constaté que **la simulation a pris plus d'ampleur que prévu** : conçue pour éclairer le brainstorm, elle a été réalignée à chaque vague par une tâche de plan, relancée en deux temps, sa référence recommitée (quatre mesures complètes en vague 3), et sa règle de « valeur mesurée » gouvernait l'arbitrage. Elle consomme des jetons et du temps sans servir une décision de vague. Enfin, aucune règle ne bornait le compte rendu technique : 281, 439 puis 509 lignes, dont un tiers de méthode de mesure recopiée à chaque fois, alors que le suivi non technique est borné à une dizaine de lignes par vague depuis ADR-103 D6.

Une seconde chose manquait : aucune mesure de qualité. Les défauts remontés par le test manuel du propriétaire ne sont notés nulle part, et sans eux une économie de coût ne se juge pas.

### Décision

**D1 — Un plan consigne des décisions, il ne transcrit pas le code** *(amende ADR-102 D2 et sa conséquence « la forme des specs et des plans »)*. Par tâche : les fichiers, les signatures exactes, les valeurs de la spec, les tests nommés avec leur assertion clé, la commande de vérification, le total de tests attendu. Le code n'est écrit en entier que pour les **tâches à risque** que la fiche ou le prompt de lancement nomme, et pour un algorithme que la spec impose ligne à ligne. Le plan ouvre par une section *Review Focus* : au plus cinq modes d'échec qu'aucun test ne garde encore, chacun confié à une tâche. Le plan de P-49 n'est plus le modèle de forme ; le premier plan écrit ainsi et jugé bon le devient. Le vérificateur de plan ne rejoue dans un clone que les tâches à risque ; pour les autres, il contrôle les signatures, les tests nommés et le décompte.

**D2 — La vérification converge** *(amende ADR-102 D3)*. La gravité suit une grille à critères : *bloquant* contredit une décision acquise ou rend l'implémentation impossible ; *moyen* produirait un comportement faux ou un test rouge que l'étape suivante ne verrait pas ; *mineur* et *rédaction* se corrigent au passage. Un trou de test n'est pas un constat de spec : il descend au *Review Focus* du plan. Dès le deuxième tour, la vérification est **différentielle** : un vérificateur neuf ne relit que les corrections et ce qu'elles touchent, avec les arbitrages déjà tranchés, qu'il ne rouvre pas sans preuve neuve. Un consolidateur de panel ne relève une gravité qu'avec une preuve reproduite par commande. La limite de trois tours demeure ; ce qui suit dépend de D3.

**D3 — Chaque question a une classe, et chaque vague un niveau d'autonomie** *(amende ADR-102 D4)*. **T**, technique, invisible du joueur : l'orchestrateur tranche par l'arbre de décision. **P**, produit, visible du joueur : le propriétaire tranche, avant la vague, dans la fiche ou le prompt de lancement ; sans réponse, le document se termine autour d'elle et l'arrêt vient quand il ne reste qu'elle et ses semblables, posées en une fois. **D**, qui ne se tranche qu'en amendant une décision acquise, valeur mesurée comprise : arrêt. Dans le doute entre T et P, c'est P ; entre P et D, c'est D. Après trois tours sans convergence : D ou P, arrêt ; T seulement, l'autonomie décide — `strict`, arrêt ; `continu`, l'orchestrateur applique les corrections recommandées, les consigne à part, et lance un dernier tour différentiel. L'autonomie est `strict` par défaut.

**D4 — La spec ne garde que ses choix** *(complète ADR-103 D6)*. Par arbitrage, le choix et sa raison, en un paragraphe. Les options écartées et le journal des tours de vérification vont dans un fichier de vérifications voisin, `<spec>-verifications.md`, tenu par l'orchestrateur et lu par le vérificateur en mode différentiel seulement. Le compte rendu y renvoie au lieu de recopier.

**D5 — Plus de simulation dans une vague** *(retire ADR-103 D5 ; amende ADR-102 D4, filtre 2)*. Aucune vague ne relance, ne réaligne ni ne compare `tool/simulations/d26_economy_sim.dart`. Le script et sa sortie de référence restent dans le dépôt, figés sur l'état que la vague 3 a laissé (`d8b2aef`), comme instrument et trace du brainstorm ; ils peuvent cesser de tourner quand une vague change un schéma qu'ils lisent, et le prochain brainstorm qui en aurait besoin les réalignera. Une valeur mesurée (D56 à D62, D67) est une décision acquise comme les autres : en changer une est une question de classe D. Les valeurs jouées sans décision (D63, les défauts du script) sont des valeurs de spec, de classe P. L'étape 3.6 du cycle est retirée, son numéro conservé pour les renvois des trois premières vagues.

**D6 — Un compte rendu court, et les tests manuels en fichier** *(précise ADR-103 D6)*. Le compte rendu technique tient en **150 lignes au plus**, corrections comprises : une page pour le propriétaire en tête (ce qu'il faut tester d'abord, les arbitrages visibles du joueur, ceux faits sans lui, les risques, trois commandes), les chiffres de la branche, une ligne par arbitrage, le renvoi aux tests manuels, ce qui est périmé, cinq leçons au plus, et **une seule table** de statistiques. Les définitions et la méthode de mesure s'écrivent une fois, dans le README du répertoire des comptes rendus, et ne se recopient plus. Le cahier de test manuel devient un fichier voisin, écrit par un agent et **rempli par le propriétaire** : le nombre de ses ❌ est la mesure de qualité de la vague. Le menu de debug ne change pas. Le suivi non technique garde sa règle : deux paragraphes, une dizaine de lignes par vague.

**D7 — L'outillage est noté.** Les versions de Superpowers et de Claude Code sont relevées à la porte d'entrée et écrites au §1 de chaque compte rendu. Aucune montée de version pendant le chantier ; entre deux chantiers, notes de version lues.

**D8 — La vague 4 est un essai mesuré ; le reste des blueprints attend.** La vague 4 se déroule sous D1 à D7 et son compte rendu se compare aux trois précédents, sur les mêmes définitions, plus les défauts au test du propriétaire. À la vague 5, le propriétaire garde, ajuste ou revient en arrière. Le [modèle](../../docs/possible_upgrades/05-10-2026_modele_orchestration_par_vagues.md), le [guide](../../docs/possible_upgrades/07-10-2026_guide_du_workflow_par_vagues.md) et la [proposition `memory-bank-sync`](../../docs/possible_upgrades/06-10-2026_memory_bank_sync_adapte_aux_vagues.md) sont figés comme blueprints : `docs/chantiers/`, les skills de méthode, les agents, les hooks, les scripts et le vault généré ne s'installent pas avant la clôture du chantier. Statut des recommandations de l'audit : R1 à R3, R14 à R16, R22 et R31 adoptées (R31 à l'essai aux vagues 6 et 7) ; R21 et R24 écartées, avec toute estimation de coût à l'avance ; R4 à R13, R17 à R20, R23, R25 à R30 différées.

### Preuves dans le code

Aucun code : la décision porte sur la manière de travailler.

| Élément | Emplacement |
|:---|:---|
| Les mesures et les recommandations | [audit](../../docs/possible_upgrades/05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md), §1.2, §4, §6 |
| Le cycle amendé : vérification, plan, simulation retirée, compte rendu, tests manuels | [fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §3.1, §3.3, §3.4, §3.6, §3.8, §3.10 |
| Les gabarits : vérificateur de spec, rédacteur et vérificateur de plan, rédacteur des tests manuels | même fichier, §4.1 à §4.4, §4.7 |
| Les classes et l'arbre ; les garde-fous et les arrêts | même fichier, §5, §6 |
| Le script de simulation hors du cycle | même fichier, §7.3 ; `CLAUDE.md`, § Tooling ; [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md) |
| La forme du compte rendu, des tests manuels et de la table de statistiques | `docs/superpowers/reports/README.md` |
| Les trois blueprints figés | `docs/possible_upgrades/05-10-2026_modele_orchestration_par_vagues.md`, `07-10-2026_guide_du_workflow_par_vagues.md`, `06-10-2026_memory_bank_sync_adapte_aux_vagues.md` |

### Conséquences

- **ADR-102 et ADR-103 restent la méthode** ; là où ils divergent de celui-ci pour les vagues 4 à 7, celui-ci a raison. Le fichier d'orchestration reste le seul texte de méthode du chantier en cours : aucun skill de méthode, aucun agent de `.claude/agents/`, aucun hook n'est installé.
- **Le ratio documentation sur code doit baisser**, et le coût par ligne de code avec lui : c'est ce que la vague 4 mesure. Une spec moins relue peut laisser passer un défaut ; c'est le compteur de ❌ des tests manuels qui le dira, et c'est la raison de D6.
- **Le script de simulation peut dériver du schéma des données** sans que rien ne le signale ; il reste `dart analyze` propre, et c'est la seule exigence qui lui reste.
- **La règle « valeur mesurée » devient une règle d'autorité**, non de mesure : une valeur de D56 à D62 ou de D67 se change comme toute décision acquise, par le propriétaire.
- **Le propriétaire écrit davantage avant une vague** — les réponses aux questions P, l'autonomie, les tâches à risque — et moins pendant : c'est le déplacement voulu des heures humaines en amont.
- **Deux fichiers de plus par vague** — les vérifications d'une spec, les tests manuels —, et un compte rendu quatre fois plus court.
- **Les trois comptes rendus existants gardent leur forme** : un ADR n'est pas rétroactif. Leur ligne « défauts au test du propriétaire » vaut zéro, faute de session de correction ouverte.
- **Ce qui ne change pas** : une vague par version, une session par vague, le propriétaire garde le test, la PR, la fusion et le tag ; les lots en série ; le vérificateur n'est jamais le rédacteur ; `patch-notes-writer` et `memory-bank-sync` à la fin, avant la fusion.
