# Orchestration — le chantier « Économie unifiée et catalogue », de `0.5.2` à `0.6.0`, vague par vague

**Date** : 01/10/2026 — réécrit le même jour pour la méthode par vagues (brainstorm, D69), puis corrigé après la cinquième passe de revue (revue §14 ; brainstorm, D70 et D71) et après la sixième (revue §15 ; D72 à D74), puis après un contrôle ciblé du texte neuf (revue §16 ; D75).
**Statut** : **ce fichier fait foi pour le déroulé du chantier** — l'ordre des vagues, ce que chacune livre, sa version, son état. **Les décisions de conception ne sont pas ici** : leur source de vérité est le brainstorm v3, [`22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md`](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 (D1 à D75). Ce fichier les cite, il ne les recopie pas ; en cas d'écart, le brainstorm a raison sur le *quoi*, ce fichier sur le *comment* et le *quand*.
**Périmètre** : ce qui a été brainstormé — **P-43** « Économie unifiée » (lots E0 à E4), **P-42** « Catalogue par lots de passif » (tranches 1 à 3) et **P-44 lot 1**. Hors périmètre, après `0.6.0` : P-44 lots 2 à 4 (derrière P-05) et P-16 (calibration).
**Sources** : le brainstorm v3 ; sa revue, [`29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md`](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md) ; le rapport de simulation, [`30-09-2026_simulation_D26_economie_Fable5.md`](30-09-2026_simulation_D26_economie_Fable5.md), et la sortie de référence du script, `tool/simulations/d26_reference_output.md` ; `docs/ROADMAP.md` §4.
**Ce que les vagues écrivent** : le journal (§2, ici) ; un compte rendu technique par vague, dans `docs/superpowers/reports/` ; et le suivi en clair du chantier, [`docs/suivi_vagues_chantier/economie_unifiee_et_catalogue.md`](../suivi_vagues_chantier/economie_unifiee_et_catalogue.md) — ce que chaque vague apporte au jeu et pourquoi (D71).
**Vérifié contre** : `main` à `25c36ba` (01/10) — `lib/`, `test/` et `assets/` identiques à `3b8c66f`, `tool/` a gagné le script de simulation ; 1187 tests verts, `dart analyze` propre. Relu par la cinquième passe de la revue (§14) : les 136 références de code des fiches, le cycle contre la CI/CD et les skills, les renvois documentaires. Relu par la sixième (§15), sur l'arbre d'après correction : la porte d'entrée de la vague 1 jouée commande par commande, la simulation relancée en entier — identique à sa référence —, la fiche 8.1 lue à la place des agents qui la recevront. Contrôlé une dernière fois sur ce texte neuf (§16) : la porte d'entrée rejouée, le cycle à deux lots déroulé pour E0 puis E1, les gabarits remplis avec la fiche 8.1, ses références ajoutées sondées dans le code.

---

## 0. Pour la session qui ouvre ce fichier

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.**

1. Lis `CLAUDE.md`, puis ce fichier en entier, puis le brainstorm v3 — au moins son en-tête, §1, §3 et §11.
2. **Trouve ta vague.** Le journal (§2) vit dans ce fichier et tous les commits d'une vague vont sur sa branche : sur `main`, une vague commencée reste « à faire » jusqu'à sa fusion. Regarde donc d'abord les branches — `git fetch`, puis `git branch -a --list '*feat/v0.*' '*docs/cloture-chantier-*' --no-merged origin/main` (le second motif est celui de la branche de clôture) :
   - **aucune branche de vague non fusionnée** : bascule sur `main` et tire-le en avance rapide (permis, §3.1), puis lis son journal — ta vague est **la première ligne à l'état « à faire »**. Une vague que le journal de `main` dit « livrée sur branche » est fusionnée : c'est la précédente, que ta porte d'entrée contrôle (§3.1) et que tu passes à « close » en §3.2. Passe la porte d'entrée et déroule le cycle (§3). **Après la vague 7, la première ligne « à faire » est la clôture** : tu es la session de clôture (§8.8, D74) ;
   - **une branche de vague existe** : la vague est commencée. Bascule dessus et lis le journal **de la branche**. « En cours » : reprends à l'étape que le journal indique — une reprise ne repasse pas la porte d'entrée, elle vérifie seulement que l'arbre est propre, que `dart analyze` est propre et que `flutter test` est vert. **Une reprise ne détruit rien** : si seuls les fichiers générés de §3.5 sont modifiés, restaure-les ; un arbre sale pour une autre raison se range par `git stash push -u`, noté sur la ligne « Arrêts » (§2) ; un commit rouge se corrige par un commit, jamais par une réécriture de l'historique — et si tu ne sais pas le corriger, arrête-toi (§6). En 3.5, l'étape exacte se lit dans le registre de SDD (`.superpowers/sdd/`, un dossier par plan) et dans `git log` ; de 3.6 à 3.8, dans le journal et dans `git log` — un commit de `patch-notes-writer` sur la branche dit que la note est écrite, et le skill ne réécrit jamais une version. **Une ligne « Arrêts » ouverte pour ta vague** (§6) : lis son motif ; ne reprends que si le propriétaire dit, dans le prompt, ce qui a levé l'arrêt, et que la levée est sur la branche — note-la sur la même ligne ; sinon, arrête-toi de nouveau et dis-le, sans rien écrire. « Livrée sur branche » : tu es une session de correction (§3.10), et tu attends du propriétaire la liste de ce qu'il a trouvé.
3. **Passe la porte d'entrée** (§3.1) quand tu ouvres une vague. Si elle ne passe pas, arrête-toi et dis pourquoi : ne commence jamais une vague sur une base que tu n'as pas vérifiée.
4. **Déroule le cycle** (§3), dans l'ordre, en **déléguant** la rédaction, la vérification et l'implémentation à des agents (§4). Tu gardes le fil, pas le détail.
5. **Arbitre seul** les questions que la fiche de ta vague (§8) laisse ouvertes, par l'arbre de décision de §5. Tu ne demandes rien au propriétaire en cours de vague, sauf dans les cas d'arrêt de §6.
6. **Arrête-toi à la porte de sortie** (§3.9). Tu ne pousses rien, tu n'ouvres pas de PR, tu ne fusionnes pas, tu ne poses pas de tag : c'est le propriétaire qui teste, ouvre la PR, fusionne et pose le tag (D70).

**Le prompt qui lance une vague** — le même pour toutes, à coller dans une session neuve :

````
Tu travailles dans le dépôt Hero's Draft (Flutter, Flame, Riverpod, 100 % data-driven). Lis `CLAUDE.md` d'abord, puis `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` en entier : ce fichier fait foi. Tu es l'orchestrateur d'une vague : trouve laquelle comme son §0 le dit — la prochaine du journal, ou celle qu'une branche a déjà commencée. Déroule son cycle (§3) en orchestrant des sous-agents (§4) — la délégation est demandée, y compris par un workflow si tu en as l'outil —, arbitre seul selon §5, respecte les garde-fous de §6 et arrête-toi à la porte de sortie. Réponds et écris en français.
````

Après un arrêt (§6), le propriétaire ajoute à ce prompt ce qui a levé l'arrêt. Le prompt d'une session de correction est en §3.10.

---

## 1. Les vagues et les versions

Le jeu est en `0.5.2`. Chaque vague, sauf la vague 0, livre une version ; `0.6.0` est la dernière, et une session de clôture, sans version, ferme le chantier après elle (D74).

| Vague | Version | Lots | Ce que le joueur voit | Branche | Poids |
|:---:|:---|:---|:---|:---|:---|
| **0** | — | Méthode et ROADMAP | Rien | `docs/vague-0-roadmap-et-methode` | Documentation seule |
| **1** | **`0.5.3`** | **E0** et **E1** | Les garde-fous de Puissance (le Berserker convertit moitié moins d'armure) ; `sharp` change de formule ; la boucle ne change pas | `feat/v0.5.3-p43-e0-e1` | Deux lots, une spec et un plan chacun |
| **2** | **`0.5.4`** | **E2** | Fusion = forge : une rune à chaque fusion, affûtage au feu, Puits d'échange, copie du deck en boutique | `feat/v0.5.4-p43-e2-fusion-forge` | Lourd : une spec, deux parties |
| **3** | **`0.5.5`** | **E3** | Une carte après chaque combat, deux niveaux par acte, sources d'affûtage, événement de relique | `feat/v0.5.5-p43-e3-trouvaille` | Lourd : une spec, deux parties |
| **4** | **`0.5.6`** | **E4** | Deux compétences de classe hors du deck, dès le premier tour, à recharge | `feat/v0.5.6-p43-e4-signatures` | Lourd : une spec, deux parties |
| **5** | **`0.5.7`** | **Tranche 1** et **P-44 lot 1** | Trois lots de cartes (Rempart, Sang, Arcaniste), les mécanismes de profondeur, les évolutions de signature | `feat/v0.5.7-p42-tranche-1-p44-lot-1` | Le plus lourd : une spec, trois parties |
| **6** | **`0.5.8`** | **Tranche 2** | Trois lots de cartes de plus (Croisé, Vampire, Voile), Canalisation en banque de mana | `feat/v0.5.8-p42-tranche-2` | Moyen : une spec, un plan |
| **7** | **`0.6.0`** | **Tranche 3** | Les trois derniers lots de cartes (Sanctifié, Carnage, Marque) : neuf passifs jouables | `feat/v0.6.0-p42-tranche-3` | Moyen : une spec, un plan |
| **Clôture** | — | — | Rien | `docs/cloture-chantier-economie-et-catalogue` | Documentation seule (§8.8) |

**Un lot, dans ce fichier, est ce qui reçoit une spec** : E0, E1, E2, E3, E4, et chaque tranche — la tranche 1 et P-44 lot 1 n'en font qu'une, en trois parties. Un **lot de cartes** (Rempart, Sang, Arcaniste…) n'est pas un lot au sens du cycle : les trois lots de cartes d'une tranche s'écrivent dans la même spec.

**Pourquoi cet ordre est forcé.** E1 avant E2 : la fusion propose une rune que seul l'applicateur d'E1 sait appliquer. E2 avant E3 : les cartes trouvées ont besoin de leur puits, la fusion (D56). E3 avant E4 : c'est D31, dans E3, qui rend les signatures-cartes invisibles (D53). E4 avant la tranche 1 : l'écran d'évolution écrit sur `SignatureInstance`, qu'E4 crée. P-44 lot 1 avec la tranche 1 : sans `costs.hp` ni `scaleWith`, le lot Sang tombe à deux cartes (brainstorm §11, ligne P-44). Les tranches 2 et 3 s'écrivent sur les mécanismes que la tranche 1 a livrés.

**Dans une vague, tout se déroule en série.** Un lot après l'autre, une partie après l'autre : la spec ou le plan suivant s'écrit sur le code que le précédent a laissé sur la branche, jamais sur une prévision.

---

## 2. Le journal d'avancement

Chaque vague le met à jour elle-même, à chaque étape franchie. États : *à faire* · *en cours* (avec l'étape) · *livrée sur branche* (en attente du propriétaire) · *close* (fusionnée, taguée, CI/CD verte).

**Le journal a une ligne par vague, que chaque étape réécrit.** « Étape » s'écrit `<lot> · <3.3, 3.4 ou 3.5> · <fait ou en cours>` — `E0 · 3.5 · fait`, `E1 · 3.3 · en cours` ; pour un lot lourd, la partie suit le lot. Les étapes de la vague entière s'écrivent sans lot : `3.2 · fait` au premier commit, puis, le dernier lot implémenté, `3.6 · fait`, `3.7 · en cours` et `3.7 · fait` (§3.6, §3.7). « Tests » s'écrit `base → total` : la base relevée à la porte d'entrée, puis le total à chaque fin d'implémentation. « Spec(s) » et « Plan(s) » reçoivent un lien par document, à mesure.

**Toute mise à jour du journal est commitée sur la branche de la vague**, dans le même commit que le document qu'elle note — la spec, le plan, et à la fin de chaque implémentation le compte rendu de la vague, qui s'ouvre là (§3.5) — jamais sur `main`, jamais laissée dans l'arbre de travail. Sur `main`, une vague reste donc « à faire » jusqu'à sa fusion : c'est attendu, et c'est pourquoi §0.2 regarde d'abord les branches.

| Vague | Version | État | Étape | Branche | Spec(s) | Plan(s) | Tests | Livrée le | Close le |
|:---:|:---|:---|:---|:---|:---|:---|---:|:---|:---|
| 0 | — | **close** | — | `main`, par exception | — | — | 1187 | 01/10 | 01/10 |
| 1 | `0.5.3` | **close** | — | `feat/v0.5.3-p43-e0-e1` | [E0](../superpowers/specs/2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md) · [E1](../superpowers/specs/2026-10-02-p43-e1-moteur-de-runes-design.md) | [E0](../superpowers/plans/2026-10-01-p43-e0-puissance-par-source-et-ratio.md) · [E1](../superpowers/plans/2026-10-02-p43-e1-moteur-de-runes.md) | 1187 → 1375 | 02/10 | 02/10 |
| 2 | `0.5.4` | **close** | — | `feat/v0.5.4-p43-e2-fusion-forge` | [E2](../superpowers/specs/2026-10-02-p43-e2-fusion-forge-design.md) | [E2 partie 1](../superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-1.md) · [E2 partie 2](../superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-2.md) | 1375 → 1426 → 1480 | 02/10 | 03/10 |
| 3 | `0.5.5` | **en cours** | E3 partie 2 · 3.4 · fait | `feat/v0.5.5-p43-e3-trouvaille` | [E3](../superpowers/specs/2026-10-03-p43-e3-trouvaille-et-progression-design.md) | [E3 partie 1](../superpowers/plans/2026-10-03-p43-e3-trouvaille-et-progression-partie-1.md) · [E3 partie 2](../superpowers/plans/2026-10-04-p43-e3-trouvaille-et-progression-partie-2.md) | 1480 → 1535 | — | — |
| 4 | `0.5.6` | à faire | — | — | — | — | — | — | — |
| 5 | `0.5.7` | à faire | — | — | — | — | — | — | — |
| 6 | `0.5.8` | à faire | — | — | — | — | — | — | — |
| 7 | `0.6.0` | à faire | — | — | — | — | — | — | — |
| Clôture | — | à faire | — | — | — | — | — | — | — |

**La ligne « Clôture » n'a que deux états** : *à faire*, puis *faite* avec sa date. Sa branche ne porte ni code, ni version, ni tag : le seul geste qui lui reste est sa fusion, et ce qu'elle écrit devient vrai sur `main` au moment où elle y entre (§8.8).

**Arrêts** — une ligne par vague arrêtée avant sa porte de sortie : la date, l'étape, le motif (§6) — et, à la reprise, ce qui a levé l'arrêt (§0.2) ; une reprise y note aussi le `stash` qu'elle a fait, et ce qu'il range.

| Vague | Date | Étape | Motif | Levée |
|:---:|:---|:---|:---|:---|
| 2 | 02/10 | E2 · 3.3, troisième tour de vérification de la spec | **Trois tours sans convergence** (§3.3, §6) : le troisième vérificateur rend encore deux constats moyens — le découpage des tests entre les deux parties laisserait la partie 1 rouge (`forge_upgrades_catalog_test`) ; la copie du deck en boutique se retire gratuitement par un retour puis une nouvelle entrée, ce qui défait D46. La spec est commitée en l'état, non convergée ; les constats ouverts et les arbitrages que l'orchestrateur recommande sont en son §13. Aucune question n'exige d'amender une décision acquise | **Levé le 02/10 par le propriétaire**, dans le prompt de la session de reprise : il accepte les arbitrages recommandés au §13 de la spec — boutique : l'option (a), étendue à l'étal entier — et demande la correction puis un quatrième tour. Reprise sans `stash` (arbre propre, `dart analyze` propre, 1375 tests verts) ; les onze constats corrigés, six questions apparues à la correction tranchées par l'orchestrateur ; **quatrième tour : prête** — 0 bloquant, 0 moyen, 5 mineurs et 4 de rédaction corrigés au passage (spec, §1.2 et §13) |
| 3 | 03/10 | E3 · 3.3, troisième tour de vérification de la spec | **Trois tours sans convergence** (§3.3, §6) — chaque tour par un panel neuf de trois vérificateurs et un consolidateur ; 22, puis 15, puis 13 constats. Le troisième rend encore trois constats moyens, trois trous de test : le test de la transition E3 → E4 lit la rareté de l'instance trouvée, toujours `common`, et ne garde donc rien ; la sélection d'affûtage et le choix du *Rémouleur* lisent le bonus de plafond de *Transcendance* sans qu'aucun test le prouve ; la notification de la carte trouvée et l'infobulle neuve du boss « XP » n'ont ni test ni commande de contrôle. La spec est commitée en l'état, non convergée ; les constats ouverts et ce que l'orchestrateur recommande sont en son §13. Aucune question n'exige d'amender une décision acquise ni ne change une valeur mesurée | **Levé le 03/10 par le propriétaire**, dans le prompt de la session de reprise : il accepte les recommandations du §13 de la spec — n° 1 à 4, 6 et 9 à 13 tels que le vérificateur les proposait, le n° 1 sous ses deux formes ; n° 5, un badge « Aucune relique à céder » ; n° 7, la parenthèse des mythiques remplie depuis la donnée ; n° 8, l'infobulle d'élite réécrite en partie 1 — et demande la correction, puis un quatrième tour par un panel neuf ; la suite du cycle seulement s'il rend « prête ». Reprise sans `stash` (arbre propre, `dart analyze` propre, 1480 tests verts) ; les treize constats corrigés par un correcteur neuf, deux questions tranchées par l'orchestrateur (C3.1, C3.2). **Quatrième tour : à corriger** — ligne suivante |
| 3 | 03/10 | E3 · 3.3, quatrième tour de vérification de la spec | **Le quatrième tour, que la levée autorisait, ne rend pas « prête »** : 12 constats — **2 moyens**, 9 mineurs, 1 de rédaction. Les trois vérificateurs du panel rendent « prête » ; le consolidateur, qui vérifie par une commande chaque constat qu'il garde moyen, en remonte deux de mineur à moyen, et son verdict est celui du tour, comme aux trois premiers : la barrière de contrôle de fin de vague se contredit (`-e cardsCount` sur `test/`, où l'assertion d'absence prévue écrit ce littéral) ; `level_up_rewards_catalog_test.dart:101` et `:68-71` resteraient rouges en partie 2 sous l'ordre neuf des mythiques, qu'aucune ligne ne réécrit. La spec est commitée en l'état — les treize corrections du troisième tour comprises —, constats du quatrième non corrigés ; ils sont en son §13, avec ce que l'orchestrateur recommande, dont la forme d'un cinquième tour. Aucune question n'exige d'amender une décision acquise ni ne change une valeur mesurée | **Levé le 03/10 par le propriétaire**, dans le prompt de la session de reprise : il accepte les recommandations du §13 de la spec — n° 1, 2, 5, 6, 7, 11, 12 tels que le consolidateur les proposait, le n° 1 sous sa première forme ; n° 3, la règle générale et les dix lignes comme un minimum ; n° 4, en deux temps ; n° 8, la section « Draft standard » retirée en partie 1 ; n° 9, le relais sans accumulateur ; n° 10, des faits calculés passés à `isSelectable` — et demande la correction, puis un cinquième tour par un vérificateur neuf, centré sur les douze corrections ; la suite du cycle seulement s'il rend « prête ». Reprise sans `stash` (arbre propre, `dart analyze` propre, 1480 tests verts) ; les douze constats corrigés par un correcteur neuf, six questions tranchées à la correction (C4.1 à C4.6) et confirmées, une septième tranchée par l'orchestrateur à sa relecture (C4.7 : les chances de la section « Récompense de niveau », alignées sur le tirage). **Cinquième tour : à corriger** — ligne suivante |
| 3 | 03/10 | E3 · 3.3, cinquième tour de vérification de la spec | **Le cinquième tour, que la levée autorisait, ne rend pas « prête »** : 7 constats — **1 moyen**, 4 mineurs, 2 de rédaction —, par un vérificateur seul, centré sur les douze corrections et les arbitrages C4, qui confirme tout ce que la correction touchait. Le moyen porte sur du code que la correction a créé : `EventController.isChoiceSelectable` (C4.4) devient le seul calcul de la condition d'or des choix d'événement, et aucun test ne la garde — quatre événements sur cinq portent un `spend_gold`, et un oubli laisserait la suite verte avec une relique gratuite. La spec est commitée en l'état — les douze corrections du quatrième tour et C4 comprises —, constats du cinquième non corrigés ; ils sont en son §13, avec ce que l'orchestrateur recommande, dont la forme d'un sixième tour. Aucune question n'exige d'amender une décision acquise ni ne change une valeur mesurée | **Levé le 03/10 par le propriétaire**, dans le prompt de la session de reprise : il accepte les recommandations du §13 de la spec — n° 1 et 3 à 7 tels que le vérificateur les proposait, le n° 7 compris ; n° 2, l'écart de « Butin de Reliques » consigné hors du lot (filtre 7) et porté à la file par le compte rendu de la vague — et demande la correction, puis un sixième tour par un vérificateur neuf, seul, centré sur les sept corrections ; la suite du cycle seulement s'il rend « prête ». Reprise sans `stash` (arbre propre, `dart analyze` propre, 1480 tests verts) ; les sept constats corrigés par un correcteur neuf, une question tranchée à la correction (C5.1) et confirmée par l'orchestrateur, avec un fait ajouté au n° 2 à la re-mesure (la relique du boss « relique », tirée sur ses propres poids). **Sixième tour : prête** — 0 bloquant, 0 moyen, 2 mineurs et 2 de rédaction corrigés au passage (spec, §8, §5.4, A5, §1.2 et §13) |

**Préalable fait** : le dossier du chantier — brainstorm, revue, simulation et son script, ce fichier — est commité et poussé sur `main` (01/10, `3cd743f`..`b4f0884`).

**La vague 0 est faite** (01/10) : dans la session d'orchestration, directement sur `main`, à la demande du propriétaire — sans branche, par exception à §3.2. La ROADMAP est redécoupée, la méthode est consignée dans ADR-102, les trois retouches au brainstorm sont appliquées. **La prochaine vague est la vague 1** ; sa porte d'entrée n'attend aucun tag.

**La cinquième passe de revue est appliquée** (01/10, revue §14) : le cycle, les gabarits et les fiches ci-dessous en portent les corrections ; la sortie de référence de la simulation est produite (§3.6) ; le suivi des vagues est ouvert (D71) ; la méthode amendée est consignée dans ADR-103.

**La sixième passe de revue est appliquée** (01/10, revue §15) : la porte d'entrée de la vague 1 a été jouée et passe ; la simulation relancée rend sa référence à l'identique. Vingt-six constats corrigés ici, et trois décisions : `maxLevel` partout où un niveau s'écrit (D72, fiche 8.1), la simulation en deux temps (D73, §3.6), la session de clôture (D74, §8.8).

**Le contrôle ciblé est appliqué** (01/10, revue §16) : rejoué sur le texte neuf de la sixième passe, il a trouvé trois défauts de la fiche E1 et douze retouches du cycle et des gabarits — quinze constats corrigés ici, et une décision : un plafond atteint sur une carte ne se repropose pas (D75, fiche 8.1).

**Le compte rendu gagne les statistiques de la session** (02/10, à la demande du propriétaire, après la livraison de la vague 1) : le temps, les agents, les jetons et le coût au tarif de l'API, mesurés dans les transcriptions — §3.8 pour chaque vague, §3.10 pour une session de correction ; le modèle est le §6 du compte rendu de la vague 1.

---

## 3. Le cycle d'une vague

Neuf étapes. **3.3 à 3.5 forment une boucle, lot par lot puis partie par partie** : pour une vague à deux lots, la spec, le plan et l'implémentation du premier sont finis avant que la spec du second s'écrive. 3.6 se fait une fois, le code de la vague terminé. La vague 0 n'avait ni spec, ni plan, ni code, ni version : elle n'avait à faire que 3.1, 3.2, sa fiche (§8.0), 3.8 et 3.9 — et elle a été faite sans branche ni compte rendu en fichier (§2). La session de clôture est du même genre : 3.1, 3.2, sa fiche (§8.8), puis elle s'arrête.

### 3.1. La porte d'entrée

À vérifier par commande, jamais de mémoire. Un seul échec arrête la session. **Tu peux basculer et tirer** : `git switch main` puis `git pull --ff-only` ne sont pas des commits sur `main` — après une fusion faite sur GitHub, le `main` local est en retard et c'est à toi de le rattraper.

| Vérification | Commande | Attendu |
|:---|:---|:---|
| L'arbre est propre, sur `main`, à jour | `git status -sb` · `git fetch` · `git rev-list --left-right --count main...origin/main` | Rien à commiter, `0 0`. **Si seuls les fichiers générés que §3.5 nomme sont modifiés** — le test manuel du propriétaire les régénère — : `git restore` sur ces chemins, et la porte continue |
| La branche de ta vague n'existe pas encore | `git branch -a --list '*<branche de la vague>'` | Vide — sinon la vague est commencée, retourne à §0.2. Une branche sans aucun commit propre, créée puis interrompue : reprends en §3.2 |
| La vague précédente est fusionnée | `git log --oneline -15 main` ; `git branch --merged main` | Ses commits sont dans `main` |
| Sa version est taguée, sur un commit de `main` *(à partir de la vague 2)* | `git tag -l "v<version précédente>"` · `git merge-base --is-ancestor v<version précédente> main` | Le tag existe et il est dans `main` |
| Sa CI/CD est verte | `gh run list --branch main --limit 1` · à partir de la vague 2 : `gh run list --workflow release.yml --limit 3` · `gh release view v<version précédente>` (en vague 1 : `v0.5.2`) | Le run CI **du commit de tête de `main`** est `success` — un run `cancelled`, remplacé par un push plus récent, ne compte pas ; le run Release du tag est vert et la release existe. **Un run `queued` ou `in_progress` s'attend** (`gh run watch <id>` — la CI dure trois à quatre minutes, la release huit à neuf) : il n'arrête pas la session, seul son échec le fait. **Si `gh` ne joint pas l'API** : demande au propriétaire de le confirmer, et note dans le journal que c'est lui qui l'a dit |
| Les trois porteurs de version concordent | `bash .github/scripts/verify_version.sh <version précédente>` — `pubspec.yaml` (`version:`), la première entrée de `assets/data/patch_notes.json`, l'entrée `current` de `site/_site/versions.json` | Tous trois à la version précédente |
| `main` est sain | `dart analyze` · `flutter test` | `No issues found!` · tout vert — **le total est la base de tests de la vague**, à écrire au journal |

### 3.2. La branche

Crée la branche de la vague (§1) depuis `main`, dans le checkout principal — jamais de worktree. **Tous les commits de la vague vont sur cette branche**, spec et plan compris : `main` ne bouge que par la fusion du propriétaire. Puis, dans le journal : passe ta vague à « en cours », avec la base de tests et l'étape `3.2 · fait`, et la vague précédente à « close », avec la date que la porte d'entrée vient de constater. C'est le premier commit de la branche.

### 3.3. La spec — écrire, vérifier, corriger, revérifier

Pour le lot en cours :

1. Un **agent rédacteur** écrit la spec dans `docs/superpowers/specs/<AAAA-MM-JJ>-<id>-<sujet>-design.md`, sur le modèle de `2026-09-16-p49-passifs-partages-design.md`, à partir de la fiche de la vague (§8) et du gabarit de §4.1. `<id>-<sujet>` est donné par la ligne « Fichiers » de la fiche. Il ne code rien.
2. Un **agent vérificateur**, neuf, qui n'a pas écrit la spec, la contrôle (gabarit §4.2) et rend une table de constats, chacun avec sa gravité : *bloquant*, *moyen*, *mineur*, *rédaction*.
3. S'il y a un constat bloquant ou moyen : renvoie les constats à un **correcteur** — le rédacteur repris avec son contexte si ton outil le permet, sinon un agent neuf, par le gabarit §4.6 ; puis un **nouveau** vérificateur revérifie. **Boucle jusqu'à zéro constat bloquant ou moyen.** Un tour, c'est une vérification : la troisième qui rend encore un constat bloquant ou moyen arrête la vague (§6). Les constats mineurs et de rédaction se corrigent au passage, sans nouveau tour. **Un constat que le correcteur conteste, ou une question que la spec a tranchée sans que la fiche la pose** (§4.2, point 4) : c'est toi qui le tranches (§5) avant le tour suivant — il se consigne comme un arbitrage, le vérificateur suivant le reçoit avec ton choix, et ce n'est plus un constat ouvert.
4. Commite la spec sur la branche, avec sa ligne dans `docs/INDEX.md` (§1 de l'index) et la ligne de la vague mise à jour au journal (§2) — un seul commit.

Une spec de lot lourd **propose son découpage en parties** et l'invariant qui justifie l'ordre ; la fiche de la vague en donne une proposition.

### 3.4. Le plan — écrire, vérifier, corriger, revérifier

Pour le lot en cours, et pour chaque partie d'un lot lourd — **le plan de la partie 2 s'écrit après l'implémentation de la partie 1** :

1. Un **agent rédacteur** écrit le plan avec `superpowers:writing-plans`, dans `docs/superpowers/plans/<AAAA-MM-JJ>-<id>-<sujet>.md`, sur le modèle de `2026-09-16-p49-passifs-partages.md` pour la forme (gabarit §4.3). **Le plan ne crée pas de branche et ne livre rien** : le modèle ouvre par une tâche de documentation sur `main` et finit par la synchronisation et la livraison — cette tâche et ces étapes-là ne se reprennent pas. **La base de tests du plan, `<N>`, est le total de `flutter test` sur la branche au moment où il s'écrit** : la base de la vague pour le premier plan, le total que le plan précédent a laissé pour les suivants — relève-le avant de déléguer.
2. Un **agent vérificateur** neuf le passe au crible contre la spec et contre le code de la branche (gabarit §4.4).
3. Même boucle qu'en 3.3, même correcteur, même limite de trois tours.
4. Commite le plan, avec sa ligne dans `docs/INDEX.md` et la ligne de la vague mise à jour au journal.

### 3.5. L'implémentation — par délégation

Exécute chaque plan avec `superpowers:subagent-driven-development` (SDD) : un agent implémenteur neuf par tâche, une revue après chacune, une revue d'ensemble à la fin. Sur la branche de la vague. **À partir du second plan d'une vague, la base de cette revue d'ensemble est le commit où le plan commence**, et non `git merge-base main HEAD`, que SDD propose par défaut : les lots déjà revus n'y reviennent pas.

**À la fin de SDD, n'invoque pas `superpowers:finishing-a-development-branch`** — le skill y enchaîne de lui-même, et propose de fusionner, de pousser ou d'ouvrir une PR : rien de cela n'est à toi. La branche reste en l'état, la suite est le lot ou la partie qui suit, puis 3.6 à 3.9.

**Deux règles d'arrêt, chacune son domaine.** Un test rouge ou un `dart analyze` sale qui survit à deux tentatives de correction d'une même tâche arrête la vague (§6) : cette règle prime. Pour les constats de ses revues, SDD suit ses propres tours.

**Les décisions de SDD s'écrivent à la fin de chaque plan, pas à la fin de la vague.** SDD tient ses décisions dans un registre (`.superpowers/sdd/`, ignoré par git), les recopie dans son message final sous « Rulings I made », puis **supprime son espace de travail** : après cela elles n'existent plus que dans ta conversation, qu'une compaction ou une reprise efface. Donc, à la fin de chaque exécution, **avant cette suppression** : recopie ces décisions dans le compte rendu de la vague (§3.8) — tu l'ouvres au premier plan, par sa table des arbitrages, avec sa ligne dans `docs/INDEX.md` (§1 de l'index) —, relève le total de `flutter test`, passe la ligne du journal à `<lot> · 3.5 · fait`, et commite le compte rendu et le journal ensemble.

Contraintes, à redire à chaque agent :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier, et la copie périmée d'un fichier disparu continue d'être chargée ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

### 3.6. La simulation, quand la fiche la demande

`dart run tool/simulations/d26_economy_sim.dart --out <fichier>` — 7 à 10 minutes (422 s le 01/10, 462 s sous charge). `--quick` (environ une minute, 25 runs) sert de fumée après un réalignement, jamais de mesure.

- **Qui fait quoi.** Le script lit `assets/data/` : la vague qui change un schéma ou un dossier qu'il parse le **réaligne dans une tâche de son plan** (§7.3). C'est **l'orchestrateur** qui le lance, en arrière-plan, une fois le code de la vague terminé et vert — pas un implémenteur.
- **La référence.** `tool/simulations/d26_reference_output.md` est la sortie complète du script, suivie par git, produite le 01/10 sur `main` à `25c36ba` — et retrouvée à l'identique par une seconde relance le même jour (revue §15). Les chiffres du rapport ne sont pas la référence : ses §2 à §4 sont la première passe, à k = 5, et seul son §7 est à k = 2 — ils servent à lire, pas à comparer.
- **La commande.** Lance avec `--out` vers un fichier **hors de l'arbre suivi**, propre à la vague — `.superpowers/d26_vague_<N>.md`, ignoré par git —, **que tu supprimes avant de lancer** : le script n'écrit sa sortie qu'à la toute fin, et s'il plante, un fichier resté là d'un lancement précédent se comparerait à sa place. Attends la ligne `écrit : <chemin>` sur la sortie d'erreur. **Tant qu'il tourne, ni changement de branche ni écriture sous `assets/data/`** : chaque lot de runs relit les données — §3.7, dont le premier skill écrit `assets/data/patch_notes.json`, attend donc la ligne `écrit :`. Puis `git diff --no-index <référence> <sortie>` — code 0, rien d'affiché : identique.
- **Le critère, en deux temps (D73).** Le script est déterministe — graine fixe, fichiers triés —, mais chaque run tire tout d'un seul générateur : une liste plus longue d'un élément décale tous les tirages qui suivent, et la sortie change partout. Un réalignement et un changement voulu dans la même relance donnent donc un écart qu'on ne peut plus attribuer. Alors :
  1. **Le réalignement seul.** Le plan réaligne le script sans rien changer aux valeurs qu'il tient en dur : chaque fichier neuf **prend la place exacte de son entrée en dur**, dans la même liste, à la même position, avec la même définition (§7.3). Relance : **le diff est vide**, à une exception écrite d'avance — la ligne « Données lues », qui compte les fichiers et bouge dès qu'une vague en crée. Commite le script réaligné.
  2. **Chaque changement voulu**, s'il y en a — une valeur jouée que l'arbitrage remplace, une entrée que le brainstorm a retirée : un commit du script, une relance, l'écart expliqué dans le compte rendu, et **la référence recommitée**. La vague suivante se compare à la tienne.
  **Un écart que tu n'expliques pas arrête la vague** (§6) — et au premier temps, tout écart hors de la ligne « Données lues » est inexpliqué.
- **Ce que le diff vide prouve.** Que le script n'a pas bougé — c'est un test de non-régression du script, pas une validation des données de la vague : il joue par exemple, jusqu'à la vague 5, six runes qui n'ont pas encore de fichier.

Le script reste `dart analyze` propre. La relance comparée et ses commits faits, le journal passe à `3.6 · fait`, dans le dernier d'entre eux ; une vague qui n'a rien à commiter — la vague 1 : diff vide, ni script ni référence touchés — le laisse dire par le premier commit de §3.7.

### 3.7. Les deux skills du projet

Dans cet ordre, une fois le code terminé et vert, chacun délégué à un agent qui invoque le skill :

1. **`patch-notes-writer`**, avec **la version de la vague** (§1), imposée — elle prime sur la règle « `MINOR` pour une fonctionnalité » du skill, qui donnerait `0.6.0` dès la vague 1 (D69). Il préfixe l'entrée dans `assets/data/patch_notes.json`, aligne `pubspec.yaml` et `site/_site/versions.json`, rafraîchit les liens de repli et le libellé de version de `site/index.html` et `site/versions.html`. Vérifie ensuite : `bash .github/scripts/verify_version.sh <version de la vague>` ; `grep -rn '<version précédente>' site/*.html` ne rend rien ; et ce que la CI lancera sur la PR puisque `site/` a bougé — `node --test` lancé depuis `site/`, et `bash .github/scripts/test_scripts.sh`.
2. **`memory-bank-sync`** : mettre à jour `activeContext.md` et `progress.md` avec des chiffres re-mesurés, ouvrir les ADR et corriger les fiches `_rules` et `_patterns` que la fiche de la vague nomme. Quatre précisions :
   - **la liste de la fiche est un minimum** : le skill corrige toute fiche que le diff de la branche périme (`git diff main...HEAD --stat`) ;
   - **« amender un ADR »** veut dire : le nouvel ADR porte l'amendement, l'ancien ne change que de Statut et lie son successeur — un ADR publié ne se réécrit pas ;
   - **`docs/ROADMAP.md` ne bouge que lorsqu'une de ses lignes se clôt** : P-43 en vague 4, P-42 en vague 7 — et P-44 lot 1 en vague 5, seul lot de P-44 dans le programme, que la ROADMAP nomme. Jamais pour un lot E ni pour une tranche : elle ne garde qu'une ligne par chantier ; l'avancement par lot reste au journal (§2), nulle part ailleurs ;
   - **la livraison se note « livrée sur la branche `<branche>` — vague N du fichier d'orchestration, en attente du test, de la PR, de la fusion et du tag du propriétaire »** — jamais « fusionnée » ni « publiée », ce n'est pas encore vrai. Le numéro de version ne se recopie pas dans le vault : il n'y apparaît que comme clé de l'historique des releases de `progress.md` (règle du skill). À partir de la vague 2, il note aussi la clôture de la vague précédente, que la porte d'entrée a constatée ; celle de la vague 7 est notée par la session de clôture (§8.8).

Commite chacun sur la branche, la ligne du journal dans le même commit : `3.7 · en cours` après la note, `3.7 · fait` après la mémoire.

### 3.8. Le compte rendu, le suivi et le journal

Trois écritures, un commit, puis un message court au propriétaire qui donne les trois chemins.

1. **Le compte rendu technique**, dans `docs/superpowers/reports/<AAAA-MM-JJ>-economie-et-catalogue-vague-<N>-compte-rendu.md` — un fichier, pas un message : la session de correction (§3.10) le relira. **Il existe déjà** : tu l'as ouvert à la fin du premier plan, par sa table des arbitrages (§3.5), et sa date est celle de ce jour-là. Tu le complètes ici pour qu'il tienne seul :
   - la branche, la version, le nombre de commits, le total de tests, `dart analyze` ;
   - **la table des arbitrages** : chaque question tranchée, ses options, le choix et son motif (§5), et les décisions de SDD, recopiées plan après plan ;
   - **le cahier de test manuel** : ce qu'il faut jouer pour voir chaque changement, classe et passif compris, et ce qui doit rester inchangé ;
   - le résultat de la simulation si elle a tourné, temps par temps (§3.6) : diff vide au réalignement, puis chaque changement voulu et l'écart qu'il laisse ;
   - ce qui a été trouvé périmé dans le brainstorm ou dans la fiche en le re-mesurant, et ce qui mérite d'entrer dans la file ;
   - **les statistiques de la session** — le temps, les agents, les jetons et le coût au tarif de l'API —, en dernière section. Le modèle est le §6 du compte rendu de la vague 1 ([`2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md`](../superpowers/reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md)) : mêmes tableaux, mêmes définitions, pour que les vagues se comparent. **Mesurées, jamais estimées**, juste avant le commit de §3.8 — ce qui suit n'y est pas compté, et la section le dit :
     - *les sources* : les transcriptions de Claude Code, sous `~/.claude/projects/<dossier du projet>/` — `<id de session>.jsonl` pour l'orchestrateur (l'id de session est le nom de son dossier scratchpad), et, sous `<id de session>/subagents/`, un `.jsonl` et un `.meta.json` (description, modèle demandé, profondeur) par sous-agent, reprises par message comprises. Un message de l'assistant s'écrit sur plusieurs lignes : son `usage` se compte **une fois par identifiant de message**. Le script de mesure s'écrit dans le scratchpad, il n'entre pas dans le dépôt ;
     - *le temps* : le début (la première ligne de la session), la fin (le dernier message de l'orchestrateur avant la mesure), la durée, et la durée de chaque étape du cycle d'après les heures des commits de la branche, en heure locale ; le temps actif de l'orchestrateur et celui, cumulé, des sous-agents (somme des écarts de moins de dix minutes entre lignes successives) ;
     - *les agents* : le total, l'orchestrateur compris, par rôle (rédacteurs, vérificateurs, implémenteurs, relecteurs, revues d'ensemble, skills) et par modèle ; les reprises par message ; le nombre d'appels au modèle ;
     - *les jetons* : par rôle et par modèle, puis par étape — entrée hors cache, écriture en cache, lecture du cache, sortie, total traité ;
     - *le coût au tarif de l'API* : chaque catégorie de jetons multipliée par son prix, modèle par modèle ; les écritures en cache au prix de leur durée, que le champ `cache_creation` de chaque appel ventile (`ephemeral_5m_input_tokens`, `ephemeral_1h_input_tokens`) ; la réflexion comptée dans la sortie, comme l'API la facture. Les prix se lisent **le jour même** sur la [page des tarifs](https://platform.claude.com/docs/en/about-claude/pricing), en dollars, et se convertissent en euros au dernier taux de référence de la BCE (`https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml`), date et taux écrits dans la section. Vérifier dans les `usage` qu'aucun supplément ne s'applique — recherches web (`server_tool_use`), mode rapide (`speed`), routage aux États-Unis (`inference_geo`) — et le dire. Ventiler par rôle, par catégorie et par étape, en dollars et en euros. C'est le coût qu'aurait la session facturée à l'API, pas la facture de l'abonnement du propriétaire : la section le précise.
2. **Le suivi des vagues** du chantier, [`docs/suivi_vagues_chantier/economie_unifiee_et_catalogue.md`](../suivi_vagues_chantier/economie_unifiee_et_catalogue.md) (D71) : ajoute la section de ta vague à la suite des précédentes, et mets à jour la ligne « Avancement » de son en-tête. **La forme et la manière sont fixées par le modèle du répertoire**, [`_modele_suivi.md`](../suivi_vagues_chantier/_modele_suivi.md) — lis-le avant d'écrire : deux paragraphes courts, **pourquoi cette vague** et **ce qu'elle apporte au jeu**, écrits **sans technique**, pour quelqu'un qui joue au jeu et ne lit pas le code ; un identifiant de la fiche se traduit par le nom que le jeu affiche. La matière : la ligne « ce que le joueur voit » de ta fiche, le « pourquoi cet ordre » de §1, et ce que la vague a réellement livré — pas ce qui était prévu. Tu l'écris toi-même : c'est toi qui as le fil.
3. **Le journal** (§2) : passe la vague à « livrée sur branche », avec la date et le total de tests.

La ligne du compte rendu est dans `docs/INDEX.md` depuis son ouverture (§3.5), celle du suivi aussi : retouche-les s'il le faut, et commite les trois ensemble.

### 3.9. La porte de sortie

**Arrête-toi.** La suite est au propriétaire, dans cet ordre (D70) : il teste à la main, ouvre la PR, **la fusionne dans `main` par un commit de fusion**, puis **pose le tag `v<version>` sur ce commit de fusion** et le pousse — c'est le tag qui déclenche la release. La vague suivante ne s'ouvre que lorsque sa porte d'entrée constate tout cela. **Après la vague 7, c'est la session de clôture qui le constate** (§8.8) : le propriétaire colle le même prompt une fois de plus.

Si le test du propriétaire fait remonter un défaut, ou s'il renverse un arbitrage, il rouvre une session sur la même branche, **avant la fusion** : c'est une session de correction (§3.10), et la vague reste « livrée sur branche ».

### 3.10. La session de correction

Elle s'ouvre par ce prompt, que le propriétaire complète :

````
Tu travailles dans le dépôt Hero's Draft. Lis `CLAUDE.md`, puis `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` en entier. Tu ouvres une session de correction (§3.10) sur la vague livrée sur la branche courante : lis son compte rendu, puis corrige ce qui suit, sans rien rouvrir d'autre. <ce que le test a trouvé ; les arbitrages renversés>. Réponds et écris en français.
````

1. Bascule sur la branche de la vague ; arbre propre, `dart analyze`, `flutter test`. Lis le compte rendu de la vague (§3.8).
2. Corrige par délégation — un agent implémenteur par défaut, une revue —, sous les contraintes de §3.5. **Un arbitrage renversé** : la spec amende sa section « Décisions » en disant que le propriétaire a tranché, le code suit ; l'arbitrage ne devient pas une décision acquise du brainstorm.
3. **Tant que la vague n'est pas taguée, ses documents se rouvrent en place** : la note de version n'est pas publiée, les ADR écrits sur la branche non plus. Relance `patch-notes-writer` en lui demandant de **reprendre l'entrée de la version de la vague** sans en créer une neuve — par exception à sa règle, qui protège les notes publiées — et `memory-bank-sync` si un fait du vault a changé. **Si la correction touche une donnée que le script de simulation lit** (§7.3), relance-le comme un changement voulu (§3.6, second temps) et recommite la référence.
4. Complète le compte rendu d'une section « Corrections du <JJ/MM/AAAA> », qui finit par **les statistiques de la session de correction**, mesurées comme en §3.8 sur sa propre transcription ; reprends la section de la vague dans le suivi (§3.8) si ce qu'elle apporte au jeu a changé ; le journal reste à « livrée sur branche », la date de la correction en plus. Commite, et arrête-toi : les gestes de sortie restent au propriétaire.

---

## 4. Déléguer — les agents et leurs gabarits

**Règles.** Un agent part d'un contexte neuf : donne-lui tout ce qu'il lui faut, par chemin de fichier, et rien de ton historique. **Le vérificateur n'est jamais le rédacteur.** Un vérificateur prouve chaque constat par une commande ou une citation ; un constat sans preuve ne compte pas. Tu ne gardes de chaque agent que sa conclusion : le chemin du document, la table de constats, le total de tests. Pour l'équilibrage des cartes (vagues 5 à 7), l'agent rédacteur prend le rôle décrit dans `.agents/skills/game_designer.md`.

### 4.1. Rédacteur de spec

````
Tu écris une spec de conception pour le dépôt Hero's Draft. Lis `CLAUDE.md` d'abord. Écris en français.

Produit : `docs/superpowers/specs/<AAAA-MM-JJ>-<id>-<sujet>-design.md`, sur le modèle de `docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md` — décisions, périmètre, données, moteur, textes joueur, éditeur, sauvegarde, tests, documentation et livraison, alternatives écartées. Aucun code, aucune donnée modifiée.

Le lot : <lot, version, une phrase>.
Les décisions acquises qu'il livre : <liste D, avec les réserves que la fiche leur met> — leur texte exact est dans `docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md` §1 <— et §4.5 pour G1 et G2, si le lot les livre>, source de vérité. Tu ne les rediscutes pas et tu n'en amendes aucune.
À lire en entier avant d'écrire : <la liste « À lire » de la fiche>.
État mesuré le 30/09, recontrôlé le 01/10, à revérifier par commande sur la branche courante : <la liste « État mesuré » de la fiche, et les puces qui détaillent ses décisions s'il y en a>. Toute référence `fichier:ligne` que tu écris, tu l'as lue toi-même aujourd'hui.
Ce que la spec doit fixer : <la liste « La spec doit fixer » de la fiche>.
Les questions à arbitrer : <la liste « À arbitrer » de la fiche>. Pour chacune, écris les options, évalue-les selon l'arbre de décision de `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §5, retiens-en une et consigne l'arbitrage dans la section « Décisions » de la spec. Si une question ne se tranche qu'en amendant une décision acquise, ne tranche pas : signale-le.
Ce que la spec ne doit pas absorber : <la liste « Ne pas absorber » de la fiche>.
Documentation et livraison : <les lignes « Pour `memory-bank-sync` » et « Ce que le joueur voit » de la fiche — pour un lot qui partage sa vague, la part marquée à son nom>. Cette rubrique du modèle ne se reprend pas telle quelle : la spec nomme les ADR et les fiches que le lot périme et ce que le joueur verra, mais elle ne prévoit ni lien dans `docs/ROADMAP.md`, ni note de version propre au lot — la note est celle de la vague, écrite à la fin par un autre agent.
<Si la simulation est concernée : la ligne « Simulation » de la fiche — ce que le lot ne doit pas toucher sans relance, ce que le plan devra réaligner.>
<Si lot lourd : propose le découpage en parties et l'invariant qui justifie l'ordre ; proposition de départ : …>

Rends : le chemin du fichier, la table des arbitrages, et toute prémisse du brainstorm ou de la fiche trouvée fausse en la re-mesurant.
````

### 4.2. Vérificateur de spec

````
Tu vérifies une spec que tu n'as pas écrite. Lis `CLAUDE.md` d'abord. Tu ne modifies aucun fichier.

La spec : <chemin>. Le lot : <lot>. Ses décisions : <liste D, avec les réserves que la fiche leur met>, texte dans `docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md` §1 <— et §4.5 pour G1 et G2, si le lot les livre>.

Vérifie, chaque point par une commande ou une citation, jamais de mémoire :
1. Chaque `fichier:ligne` cité existe et dit ce que la spec lui fait dire, sur la branche courante.
2. Chaque décision du lot est couverte, dans la part que la fiche lui donne ; aucune n'est contredite — cite la ligne du brainstorm.
3. Chaque item de « La spec doit fixer » est fixé : <la liste de la fiche>.
4. Chaque question de « À arbitrer » est tranchée, avec ses options et son motif : <la liste de la fiche>. Aucun arbitrage n'amende une décision acquise ni ne change une valeur mesurée par la simulation. Une question que la spec a tranchée sans que la fiche la pose est un constat de gravité mineure, à signaler avec son arbitrage : l'orchestrateur le consigne.
5. Rien de « Ne pas absorber » n'y est entré : <la liste de la fiche>.
6. Les transitions avec les lots voisins sont traitées : <lignes de §7.2 qui concernent le lot>.
7. Les règles du dépôt tiennent : trois couches séparées, donnée bilingue, id = nom de fichier, un fait à un seul endroit, pas de code sans lecteur.
8. Les tests sont nommés, et chacun garde une chose précise.
9. <Le point propre au lot, donné par la fiche — lu pour une spec : « la spec ne prévoit pas… ».>
<Au deuxième et au troisième tour : les constats des tours précédents que l'orchestrateur a tranchés, avec son choix — ne les rouvre pas sans preuve neuve.>

Rends une table : numéro, où, constat, preuve, gravité (bloquant / moyen / mineur / rédaction), correction proposée. Puis une ligne : « prête » ou « à corriger ».
````

### 4.3. Rédacteur de plan

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis `<chemin de la spec>` <§ de la partie>. Modèle de forme : `docs/superpowers/plans/2026-09-16-p49-passifs-partages.md` — but, architecture, contraintes globales, carte des fichiers, tâches à cases à cocher, titrées `### Task N: …` (le mot « Task », que l'outil d'exécution cherche). Cite le code tel qu'il est sur la branche courante : re-mesure chaque `fichier:ligne`, jamais de mémoire. Base de tests : <N, le total de `flutter test` sur la branche aujourd'hui>, et chaque tâche donne le total attendu — N, plus les tests qu'elle ajoute, moins ceux qu'elle retire, comptés sur les blocs de test que le plan écrit.

Ce que le plan ne reprend PAS du modèle : ni « Task 0 » de documentation ou de branche, ni tâche de livraison. Le plan ne crée pas de branche — il s'exécute sur `<branche de la vague>` —, ne commite rien sur `main`, ne pousse rien, n'ouvre pas de PR, et n'invoque ni `memory-bank-sync`, ni `patch-notes-writer`, ni `finishing-a-development-branch`. Sa dernière tâche est la vérification finale : `dart analyze`, `flutter test`, les greps de la spec.

Contraintes globales : celles de `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §3.5, recopiées dans le plan. <Si la fiche demande un réalignement de la simulation : une tâche réaligne `tool/simulations/d26_economy_sim.dart` sans changer aucune valeur qu'il tient en dur — chaque fichier neuf prend la place exacte de son entrée en dur, même liste, même position, même définition (§3.6 et §7.3 du même fichier) — et le fume par `--quick` ; un changement voulu d'une valeur jouée est une tâche à part, après elle ; aucune tâche ne lance la mesure complète, c'est l'orchestrateur qui le fait.> <Sinon : ce que la ligne « Simulation » de la fiche interdit de toucher.> Ne touche à aucun fichier de `lib/`, `assets/` ni `test/`. Rends le chemin du plan et sa carte des fichiers.
````

### 4.4. Vérificateur de plan

````
Passe de vérification du plan `<chemin>`, contre la spec `<chemin>` <§> et le code de la branche courante. Tu ne modifies aucun fichier. Base de tests du plan : <N>.

Vérifie, chaque point par une commande, jamais de mémoire :
- ce que le plan croit avoir à faire et qui est déjà fait par un lot précédent — toute tâche qui le réécrit est à supprimer ;
- les chemins et numéros de ligne cités, un par un ;
- le total de tests attendu à chaque tâche : N, plus les tests ajoutés, moins les tests retirés, recomptés sur les blocs de test du plan ;
- que chaque tâche laisse `dart analyze` propre et `flutter test` vert, et qu'aucune n'introduit de code sans lecteur ;
- que chaque exigence de la spec a sa tâche, et qu'aucune tâche ne sort de la spec ;
- qu'aucune tâche ne crée de branche, ne commite sur `main`, ne pousse, n'ouvre de PR, ni n'invoque `memory-bank-sync`, `patch-notes-writer` ou `finishing-a-development-branch` — une telle tâche est un constat bloquant ;
- que les tâches sont titrées `### Task N: …` ;
- <s'il y a un réalignement de la simulation : que sa tâche ne change aucune valeur que le script tient en dur, et qu'un changement voulu a sa tâche à part> ;
- <le point propre au lot, donné par la fiche>.

<Au deuxième et au troisième tour : les constats des tours précédents que l'orchestrateur a tranchés, avec son choix — ne les rouvre pas sans preuve neuve.>

Rends une table : tâche, constat, preuve, gravité (bloquant / moyen / mineur), correction proposée. Puis une ligne : « prêt » ou « à corriger ».
````

### 4.5. Les skills de fin de vague

````
Invoque le skill `patch-notes-writer`. Version imposée : <version de la vague> — elle prime sur la règle MINOR / PATCH du skill (décision du propriétaire, brainstorm D69). Ce qui est livré : <plans de la vague>. Ce que le joueur voit : <ligne de la fiche, et ce qu'elle demande de dire dans la note>. Écris l'entrée, aligne les trois porteurs de version et les liens de repli du site, et rends la version écrite et la liste des fichiers touchés.
````

````
Invoque le skill `memory-bank-sync`. Livré sur la branche `<branche>` — vague <N> du fichier d'orchestration, **en attente du test, de la PR, de la fusion et du tag du propriétaire** : écris-le ainsi, jamais « fusionné » ni « publié », et sans recopier le numéro de version hors de l'historique des releases. Mets à jour `activeContext.md` et `progress.md` avec des chiffres re-mesurés (total <N> tests, sur une base de <B>). Ouvre les ADR <liste de la fiche> — amender un ADR, c'est en ouvrir un qui porte l'amendement, l'ancien ne change que de Statut. Corrige les fiches <liste de la fiche> : cette liste est un minimum, corrige toute fiche que `git diff main...HEAD` périme. `docs/ROADMAP.md` : <« n'y touche pas, aucune de ses lignes ne se clôt » ou « clos P-xx »> — l'avancement par lot ne s'y écrit pas. <À partir de la vague 2 : note aussi la clôture de la vague précédente — fusionnée le <JJ/MM/AAAA>, taguée, CI/CD verte.> Rends la liste des fichiers écrits.
````

### 4.6. Correcteur de spec ou de plan

Quand le rédacteur ne peut pas être repris avec son contexte :

````
Tu corriges <une spec | un plan> que tu n'as pas <écrite | écrit> : `<chemin>`. Lis `CLAUDE.md` d'abord, puis le document en entier <et, pour un plan, la spec `<chemin>`>. Voici les constats d'un vérificateur indépendant : <la table, avec ses preuves>. Corrige ces constats, et rien d'autre : ne réécris pas ce qui n'est pas visé, ne rouvre aucun arbitrage que les constats ne contestent pas. Toute ligne `fichier:ligne` que tu touches, tu la re-mesures sur la branche courante. Si un constat te paraît faux, ne le corrige pas : dis-le, avec ta preuve. Ne touche à aucun fichier de `lib/`, `assets/` ni `test/`. Rends la liste des constats traités, un par un, et ce que tu as changé.
````

---

## 5. Arbitrer — l'arbre de décision

Le propriétaire a délégué l'arbitrage des questions de spec (D69). Pour chaque question à arbitrer — celles que la fiche pose, et celles que la rédaction fait apparaître —, écris les options, puis passe-les dans l'ordre par ces filtres ; le premier qui départage tranche.

1. **Une décision acquise.** Une option qui contredit une décision de D1 à D75 est écartée. Si *toutes* les options en contredisent une, ce n'est plus un arbitrage : arrête la vague (§6).
2. **Une valeur mesurée.** Une option qui change une valeur de D56 à D62 ou de D67 sans relance de la simulation est écartée (brainstorm §12, ligne 1). **Les valeurs de D63 sont des valeurs de spec, non mesurées**, comme les défauts que le script joue sans qu'une décision les fixe (rapport §1.2 ; les fiches les nomment) : elles se confirment ou se remplacent — et en remplacer une, c'est un changement voulu : une relance à part, l'écart expliqué, la référence recommitée (§3.6, second temps).
3. **Les trois principes du brainstorm** (§3) : P1 — pas de contenu qui ne porte pas de décision ; P2 — chaque carte d'un lot nourrit son passif ; P3 — la fusion est le moteur de progression, rien ne court-circuite la chaîne trouvaille → fusion → rune → affûtage.
4. **Le mécanisme plutôt que le cas.** Entre une règle en donnée, réutilisable, et un cas écrit en Dart pour une carte ou une rune, la règle en donnée. Si les options sont les valeurs d'un même mécanisme, livre le mécanisme et choisis la valeur.
5. **L'architecture du dépôt.** Les trois couches de `CLAUDE.md` ; le répertoire porte l'appartenance ; un seul prédicat par question (`isOfferableTo`, `availablePassivesFor`) ; aucun champ que le répertoire impose.
6. **Ce que le joueur lit.** L'option dont l'effet se lit sur la carte, sur le HUD ou dans la description, sans règle cachée.
7. **Le périmètre.** L'option qui n'élargit pas la vague ni n'avale un lot voisin.
8. **À égalité**, la plus simple à défaire.

**Chaque arbitrage est consigné**, dans la section « Décisions » de la spec et dans le compte rendu de la vague (§3.8) : la question, les options, le filtre qui a tranché, le choix. Le propriétaire les lit au moment de son test ; un arbitrage qu'il renverse se corrige sur la branche avant la fusion (§3.10).

---

## 6. Les garde-fous

**Ce que l'orchestrateur ne fait jamais** :

- pousser, ouvrir une PR, poser un tag, fusionner, ou commiter sur `main` — basculer sur `main` et le tirer en avance rapide, à la porte d'entrée, n'en est pas ;
- invoquer `superpowers:finishing-a-development-branch`, ou laisser un plan le faire ;
- amender une décision acquise du brainstorm, ou changer une valeur mesurée sans relancer la simulation ;
- élargir le périmètre : ni P-44 lots 2 à 4, ni P-16, ni un rééquilibrage que la fiche n'appelle pas ;
- éditer `assets/data/patch_notes.json` à la main, ou changer une version autrement que par `patch-notes-writer` ;
- lancer `dart format`, utiliser un worktree, sauter un hook, écrire du code par heredoc ;
- détruire pour ranger : ni `git reset --hard`, ni `git clean`, ni réécriture d'un commit — un arbre sale se range par `git stash push -u`, un commit rouge se corrige par un commit (§0.2) ;
- dire clos ce qui ne l'est pas : une vague est « livrée sur branche » jusqu'à ce qu'une porte d'entrée constate sa fusion et son tag, et le chantier ne se dit clos que dans la session de clôture (§8.8) ;
- faire de la compatibilité des sauvegardes un sujet : avant la `1.0.0` elles ne se transfèrent pas d'une version à l'autre.

**Quand la vague s'arrête et rend la main**, avec l'état exact dans le journal et le motif sur la ligne « Arrêts » — commités sur la branche. À la porte d'entrée, aucune branche n'existe encore : rien ne s'écrit, le motif est dit au propriétaire dans le message d'arrêt :

- la porte d'entrée ne passe pas ;
- trois tours de vérification sans convergence, sur une spec ou sur un plan ;
- une question ne se tranche qu'en amendant une décision acquise ;
- la simulation montre, contre sa référence, un écart que la vague n'explique pas ;
- un test reste rouge, ou `dart analyze` sale, après deux tentatives de correction d'une même tâche ;
- le code de `main` contredit une prémisse de la fiche au point de changer le périmètre du lot ;
- un numéro de version est à décaler — un correctif s'est intercalé entre deux vagues : la table de §1 est aussi écrite dans D69, que tu n'amendes pas.

Une vague interrompue se reprend dans une session neuve, **sur sa branche**, à l'étape que le journal de la branche indique ; une vague arrêtée, seulement une fois l'arrêt levé (§0.2).

---

## 7. La cohérence des lots — vérifiée le 01/10

### 7.1. Chaque décision a un lot

Les décisions du §1 du brainstorm ont été relues une à une contre la table des lots de son §11, puis une seconde fois par la cinquième passe de la revue.

| Famille | Décisions | Lot | Vague |
|:---|:---|:---|:---:|
| Garde-fous de Puissance | D36, D37 | E0 | 1 |
| Moteur de runes | D4 (le niveau d'une rune, borné), D27, D33 (`sharp`, `hardened`), D44 et D51 (la part des huit runes d'aujourd'hui), D61, D68, D72, D75 ; D28 pour le renommage `fusionRank` ; G1, G2 (§4.5 — des propositions, non des décisions acquises) | E1 | 1 |
| Fusion, affûtage, Puits, boutique | D3, D4 (le niveau monté contre de l'or), D5, D6, D13, D14, D20, D22, D32, D33 (`spectral`), D39, D44 et D51 (la donnée de `cheap`), D46, D48, D63 (`b` = 50), D65 (`cheap`, `precise`, `spectral`) ; D28 pour la capacité et les pré-forgées | E2 | 2 |
| Trouvaille, main, XP, DDA, sources, seuils | D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57 à D60, D62, D63 (Q15), D67 | E3 | 3 |
| Signatures | D7 (forme), D41, D49, D53 ; D28 (`magic_missile` en Compétence) | E4 | 4 |
| Catalogue et profondeur | D4 et D18 (les runes de mécanisme), D7 (les évolutions), D8, D9, D10, D12, D15, D16, D17, D19, D21, D28 (`focus` supprimée), D33 et D35 (`piercing`, `lifesteal`), D34 (ordre des tranches), D38, D40, D44 (`requiresCost` de `transfusion`), D45, D50, D54, D63 (Q9), D65 (cinq runes), D66 | Tranche 1 + P-44 lot 1 | 5 |
| Tranche 2 | D30 (Voile), D35 (Vampire) | Tranche 2 | 6 |
| Tranche 3 | D34 (déclencheur de Marque), D55 (*Prière*) | Tranche 3 | 7 |
| Après `0.6.0` | D29, D52, D56 ; Q4, Q18 ; §9.2 #5 à #9 ; D65 (`retain`) | P-16 · P-44 lots 2 à 4 | — |
| Méthode | D26 (faite), D64, D65, D66, D68, D69, D70, D71, D73, D74 | Ce fichier | 0 |

Les items non numérotés ont aussi leur vague : `wisdom.json` en `mythic` (§5) en vague 3 ; `EntitySource('cards/*/*.json')`, `isOfferableTo` étendu, `PassiveData.classes` à une seule classe (§6) et le validateur `costs.armor` (§7.4) en vague 5.

### 7.2. Les transitions entre lots

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|
| E0 → E1 *(même vague)* | Aucun état transitoire, mais deux fichiers en commun. `effect_resolver.dart` porte trois endroits : la fabrique de statuts (`createStatus`, `:16-93`, E0), le `switch` des runes (`:142-164`, E1), et **la pose des statuts des runes élémentaires** (`:176-220`), qui appelle la fabrique d'E0 depuis du code de rune — E0 n'y change que l'appel à `createStatus`, E1 réécrit le bloc. `entity_descriptor.dart` porte le vocabulaire de `statRules` (E0) et le descripteur de rune (`:326-360`, E1) | La fiche 8.1 le dit aux deux lots ; la spec E0 tranche la portée de la règle et le sort des statuts élémentaires, la spec E1 la suit |
| E1 → E2 | La forge du feu et le nœud Forge de Fusion vivent encore ; E1 leur laisse `pools`, `stackable` et la capacité en lecture | D68 |
| E2 → E3 | La forge du feu a disparu, la trouvaille n'existe pas encore : les runes ne viennent que de la fusion, les doublons du boss « cartes » et de la boutique seulement — **en `0.5.4` les fusions sont rares** | Voulu (brainstorm §11, ligne E3). La spec E2 et la note joueur le disent |
| E3 → E4 | Les signatures sont encore des cartes : exclues de la trouvaille par `unique` (`isOfferableTo`), sans rune, `fusionRank` 0 pour la DDA | Un test dans E3 le garde |
| E4 → tranche 1 | Les signatures sont des compétences sans évolution ; le deck ne connaît que les 17 neutres | La tranche 1 ajoute `evolutions` et l'écran |
| E4 → tranche 3 | `magic_missile` devient une Compétence en `0.5.6` (D28) : *Marque du Mage*, encore sur `onAttackPlayed`, **ne se déclenche plus sur la signature du Mage** ; le passif est ensuite masqué en `0.5.7` et `0.5.8` | Voulu — arbitré le 01/10 (revue §14, A2) : le déclencheur de D34 reste en vague 7, le périmètre des vagues ne bouge pas. La spec E4 et la note de `0.5.6` le disent |
| Tranche 1 → 2 → 3 | Six passifs masqués, puis trois — le joueur perd en `0.5.7` six passifs qu'il avait en `0.5.6`, la note le dit ; `fireball` reste neutre jusqu'au lot Marque, son id de tutoriel ne change pas | Le masquage est arbitré en vague 5 (O5) |
| Tranches → P-44 lots 2 à 4 | Trois cartes attendent un mécanisme hors périmètre : Rempart (épines), Voile (`retain`), Carnage (*Forge de guerre*) | **Elles ne s'écrivent pas avant `0.6.0`** ; chaque lot atteint ses 5 cartes sans elles ; la session de clôture les porte en ROADMAP sur la ligne de P-44 (§8.8) |

### 7.3. Ce que le script de simulation impose

`tool/simulations/d26_economy_sim.dart` lit `assets/data/` au lancement (`GameData.load`, `:722-877`) : les ennemis ; **les cartes de `cards/` à plat** — son chargeur ne descend pas dans les sous-dossiers (`_jsonFiles`, `:413-421`) ; les reliques ; `level_up_rewards/` ; `forge_upgrades/` (`id`, `weight`, `eligibleCardTypes` — il ignore `pools`) ; `events/` (`:861-873`) ; `class.json` (`maxHp`, `maxMana`, `critChance`, `mastery`, `mightTargets`, et de `statRules` le seul mode `convert`, `:808-816`) ; **les signatures, dans `classes/<id>/cards/`** (`:797-807` — leur coût, leur type, leurs effets) ; et des passifs `value`, `duration`, `threshold` et le bloc `mastery` (`:779-791`). Son chargeur lit par clé : un champ neuf ne le fait ni planter ni dériver ; un champ **absent** ou une valeur non entière là où il attend un entier le fait planter.

**Sont codés en dur** : cinq des huit runes d'aujourd'hui, redéfinies par un `switch` (`:830-846`) ; les neuf runes neuves (`:848-859`) ; les lots, dont les cartes survivantes prises par id (`lotCards`, `:500` et suivantes) ; trois événements (`:2940` et suivantes), quatre reliques (`:693-696`, versées dans la réserve en `:2470-2474`) et la mythique de D42(c) (`:2609-2615`) ; la recharge des signatures (`:803`) et le type de `magic_missile` (`:805`) ; le `ratio` 0,5 du Berserker (`:1441`), les `minFusionRank` (`:1267-1269`) et la table des `maxLevel` (`:1274` et suivantes). La relique B, que D57 supprime, et l'événement de fusion de D29, que D56 sort du chantier, y sont encore joués — par défaut, donc dans la référence.

**Trois choses que la table ci-dessous suppose.** Les listes sont tirées **par index** : runes, reliques, événements et récompenses sont rangés « fichiers triés par nom, puis entrées en dur », et un fichier neuf se range au milieu des autres — d'où la règle du réalignement, §3.6 : chaque fichier neuf prend la place exacte de son entrée en dur. La cinquième ligne de la sortie, « Données lues », **compte les fichiers** (`:3837-3841`) : elle bouge dès qu'une vague en crée un, et c'est le seul écart admis au premier temps. Et **la table d'XP n'est pas lue : elle est recalée à chaque lancement** (`:3801-3806`) — elle égale celle de D67 aujourd'hui (référence, ligne 11).

| Vague | Ce qui casse ou dérive | À faire dans le plan |
|:---:|:---|:---|
| 1 | Rien, **tant qu'E1 ne touche ni le `weight` d'aucune des huit runes** (`:828`), **ni l'`eligibleCardTypes` des six autres que `sharp` et `hardened`** (`:829`, `:834-835`) : `ratio`, `maxLevel` et l'éligibilité par effet sont en dur ; les champs neufs d'E0 et d'E1 sont ignorés | **Relancer quand même**, sans réalignement : diff strictement vide attendu — huit minutes en arrière-plan, et la réserve est prouvée au lieu d'être supposée (D73) |
| 2 | `cheap`, `precise`, `spectral` apparaissent en fichiers : le `switch` les prend par défaut (`:845`) **en plus** des entrées en dur (`:850`, `:854`, `:858`) — doublon, et rangés au milieu des huit | Premier temps : une liste d'ordre explicite des 17 ids dans le script — pour chacun, le fichier s'il existe, l'entrée en dur sinon ; un fichier dont l'id n'y est pas lève une erreur. Diff vide, « 17 runes » compris. Second temps seulement si un arbitrage remplace une valeur jouée (§8.2) |
| 3 | Les reliques A et C, la légendaire de D42(a), les événements d'affûtage et d'échange de relique, la mythique de D42(c) deviennent des fichiers : doublons avec les entrées en dur, rangés au milieu des listes tirées par index (`:2517-2522`, `:2940-2947`, `:2602-2626`). Le chargeur accepte tout `effect` de récompense : le risque est muet — une liste plus longue, un jet de plus par niveau. `wisdom.json` : le script force déjà son pool (`:2594`), mais lira sa valeur `mythic` (`:2619`) | Premier temps : chaque fichier remplace son entrée en dur à la même position — les reliques en queue, dans l'ordre A, B, C, D42(a), avec leur `trigger: 'special'` ; les deux événements aux places de `d23_relic` et `d42b_sharpen` ; la mythique de D42(c) **en dernier**. Diff vide **hors la ligne « Données lues »**, dont l'écart attendu s'écrit d'avance. Second temps : le retrait de la relique B et de l'événement de D29, relancé à part, référence recommitée ; **et la référence du script lit désormais la table d'XP du jeu**, que cette vague écrit en donnée — la calibration reste affichée à côté |
| 4 | `classes/*/cards/` devient `skills/` : **le script plante** — `listSync` sur un dossier absent (`:798`) ; le schéma des signatures change | Premier temps : réaligner le chemin, **lire la recharge et le type dans le fichier** à la place des deux valeurs en dur. Diff vide si l'arbitrage garde la recharge de 2 et les coûts d'aujourd'hui ; sinon c'est un second temps |
| 5 | `cards/<passif>/` apparaît : **les cartes de lot sont ignorées** par le chargeur ; `demon_form`, déplacée, fait planter `survivor()` (`:501`, `:572`) ; `focus` disparaît | Faire lire les lots réels à la place des lots génériques, relancer : **première mesure sur les vraies cartes** — un changement voulu d'un bout à l'autre, l'écart avec la référence est une information, pas un arrêt ; la référence est recommitée |
| 6 | Trois lots réels de plus | Relancer, recommiter la référence |
| 7 | Trois lots de plus ; `metallicize`, `warcry` et les quatre élémentaires, déplacées, font planter `survivor()` (`:556`, `:610`, `:635-638`) | Réaligner, relancer ; la mesure des neuf lots est le point de départ de P-16 |

---

## 8. Les fiches de vague

Chaque fiche donne à l'orchestrateur la matière des gabarits de §4. « État mesuré » date du 30/09 sur `3b8c66f`, recontrôlé le 01/10 (revue §14) : **à revérifier, pas à croire** — les vagues précédentes ont déplacé les lignes. Les listes « pour `memory-bank-sync` » sont des minimums (§3.7).

### 8.0. Vague 0 — la méthode et la ROADMAP

✅ **Faite le 01/10**, dans la session d'orchestration, directement sur `main`, à la demande du propriétaire. Ce qui suit est ce qu'elle avait à faire et a fait — à trois nuances près. Les chiffres des constats de P-16 sont restés dans le rapport de simulation, **liés et non recopiés** dans la ROADMAP, comme `memory-bank-sync` l'impose. Les trois fiches `_rules` périmées ont été **corrigées sur le code d'aujourd'hui** (`0fd60c4`), pas « marquées » en attente d'une vague. Et la phrase « P-42 ira au numéro suivant » a été annotée, pas remplacée.

**Ni version, ni spec, ni code.** Branche prévue `docs/vague-0-roadmap-et-methode` — non utilisée.

1. **Trois retouches au brainstorm**, arbitrées par l'orchestrateur (§5 ; elles n'amendent aucune décision, elles comblent trois oublis) :
   - au nœud C2 du graphe de §11 : « Marque du Mage sur la première carte de dégâts (D34) avec le lot Marque » ;
   - au graphe de §11 : un nœud `P44d["P-44 lot 4<br/>effets interactifs (B19) · CardTarget.none · costs.discard"]` après `P44c` — le « lot propre » de §9.2 #9 — et la ligne P-44 de la table « La roadmap à redécouper » passe à quatre lots ;
   - en §7.3, ligne Arcaniste : « une Compétence multi-coups à écrire en tranche 1 (§7.4) ».
2. **`memory-bank-sync`**, avec ces consignes :
   - `docs/ROADMAP.md` §4 — **P-43** devient « Économie unifiée », premier chantier, lots E0 à E4 ; **P-42** devient « Catalogue par lots de passif », trois tranches, après E4 ; **P-44** devient quatre lots, le premier avec la tranche 1. **La ROADMAP garde une ligne par chantier et renvoie à ce fichier** pour les vagues, les versions et l'avancement : aucun fait n'est écrit aux deux endroits.
   - L'encart « un seul programme en cinq lots, à ne pas ré-ordonner » est réécrit : l'ordre est P-43 → P-42 → P-44, par D64, et la méthode est celle de D69.
   - La phrase « P-42 ira au numéro suivant, qui reste à décider » est remplacée par le renvoi à §1 de ce fichier : `0.5.3` à `0.6.0`.
   - **P-18** : ses deux points restants sont annulés par D2 et D3. **P-16** hérite cinq constats, avec leurs chiffres à k = 2 quand le rapport en donne (§5, §7.2, §7.3 — les reliques de mana n'ont pas de mesure) : reliques de mana ; un puits d'or à créer (5 596 or dorment à l'acte 15) ; la survie après l'acte 5 ; la boucle XP / niveau ennemi (D58) ; l'échange 3 → 1 et l'événement de fusion (D29, D56 ; Q4, Q18).
   - §9 « Séquencement » : le jalon en cours est ce chantier.
   - **Un ADR pour la méthode** : un chantier par vagues, une version par vague, une session par vague, l'orchestrateur arbitre, le propriétaire teste, tague et fusionne (D69 — ordre amendé depuis par D70 : la fusion, puis le tag).
   - `_patterns/` : une fiche pour le script de simulation (§7.3) ; `_rules` périmées relevées par la revue §9 (`01-00`, `03-8` sur `eco`, `04-00` sur `strength`) : marquées « change avec la vague 1 ou 2 ».
   - `CLAUDE.md`, table « Documentation Map » : une ligne — *le chantier en cours, vague par vague* → ce fichier.
   - `activeContext.md` : focus = vague 1.
3. **Porte de sortie** : pas de tag. La vague 1 exige seulement que la vague 0 soit fusionnée.

### 8.1. Vague 1 — `0.5.3` — E0 et E1

Deux lots, en série : E0 en entier (spec, plan, implémentation), puis E1. Branche `feat/v0.5.3-p43-e0-e1`. Les lignes « Ce que le joueur voit » et « Pour `memory-bank-sync` », en fin de fiche, sont celles de la vague : chaque élément y porte son lot, et chaque rédacteur de spec reçoit sa part (§4.1).

#### E0 — un statut `might` par source, `ratio` de conversion

**Fichiers** : `<AAAA-MM-JJ>-p43-e0-puissance-par-source-et-ratio-design.md` pour la spec, le même nom sans `-design` pour le plan.
**Décisions** : D36, D37 (D66).

- **D36.** `EntityStats.addStatus` (`entity_stats.dart:134-139`) fusionne deux `might` de durées différentes en un seul, valeur sommée, durée maximale (`StatusEffect.combine`, `isStackable` vrai par défaut, `status_effect.dart:17`) : `demon_form` (2 pendant 4 tours) puis `iron_wall` chez le Berserker (10 pendant 1 tour) donne Puissance 12 pendant 4 tours. Demain `StatusEffect` porte l'id de ce qui l'a posé et `addStatus` ne fusionne que même statut *et* même source ; `effectiveMight` somme déjà toutes les entrées, `tickStatuses` les vieillit séparément. À l'écran : la barre de vie affiche la somme (`hud/player_health_bar.dart:134`), le panneau des statuts une ligne par entrée (`hud/status_effects_panel.dart:74-84`) — donc deux lignes « Puissance » après E0.
- **D37.** Un champ `ratio` (défaut 1) sur `stat_rule.dart`, appliqué par `StatGains._convert`, à 0,5 arrondi à l'entier supérieur dans `classes/berserker/class.json` : 6 → 3, 5 → 3, 1 → 1.

**À lire** : brainstorm §1 (D36, D37, D66), §11 ligne E0, §7.2 ; revue §8.1 R3 et §8.2 idées 2 et 3 — l'idée 2 pour le diagnostic seulement : elle propose de fusionner « à durée égale », le mécanisme retenu est celui de D36 ; ADR-097, ADR-095, ADR-099, ADR-100, ADR-081 ; la spec de P-41, `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, §7 et §9.1 ; `_rules/08-00`, et les deux fiches que le lot périme — `_rules/04-00` (la fusion des statuts) et `_rules/02-2` (la conversion du Berserker).
**État mesuré** :
- la règle de classe : `stat_rule.dart` (`RuleMode { convert }` seul ; `stat`, `mode`, `to`, `duration`) ; `StatGains._convert` dans `lib/game/systems/stat_gains.dart:77-110`, appelé par `apply` (`:52-71`) — `player_stats_manager.dart` ne fait qu'appeler `StatGains.apply` ;
- **neuf sites fabriquent un `might`, un seul part d'une carte** : la carte (`strategies.dart:164-189`, par `EffectResolver.createStatus`, `effect_resolver.dart:16-93`) ; la conversion de classe (`stat_gains.dart:98-106` — l'`iron_wall` de D36 naît là, d'un `GainSource.card` sans id) ; les passifs Ferveur, Rage et Frénésie (`passive_strategies.dart:15-21`, appelé `:130`, `:174`, `:215`) ; trois reliques (`player_stats_manager.dart:255`, `:350`, `:384`) ; `might_regen` (`status_effect_processor.dart:35`, `:96`) ; une intention ennemie (`turn_phase_manager.dart:143`) ;
- **`addStatus` sert presque tous les statuts**, héros et ennemis, et trois lecteurs supposent une entrée par id : `damage_pipeline.dart:31-43` (`firstWhere` sur `shock`), `strategies.dart:71-74` (`buffs.first` sur `lifesteal`), les charges de relique (`player_stats_manager.dart:305-306`, `:339-340`, `:373-374`, `:407-408`) ; `test/unit/effect_resolver_test.dart:44-63` fige la fusion de deux `poison` ;
- **une pose de statut n'y passe pas** : les runes élémentaires (`effect_resolver.dart:176-220`) fabriquent `burn`, `freeze` et `shock` par `createStatus` et les **concatènent** à la liste de l'ennemi (`:205`, `:214`), sans fusion — deux `shock` coexistent déjà, et `damage_pipeline` n'en lit qu'un. Ce bloc est du code de rune : **E0 n'y change que l'appel à `createStatus`**, si sa signature bouge ; c'est E1 qui le réécrit ;
- le tutoriel (P-41 lot D) mesure le gain réel par `StatGains.apply`. Le titre de l'étape « Armure & Dégâts » est statique (`tutorial_data.dart:177-178`) ; sont **générés** le titre du panneau et la règle en clair (`StatRuleLabel`, `model_extensions.dart:154` et suivantes), par des chaînes ARB paramétrées par la seule durée (`app_fr.arb:108-109`) ; la carte de classe affiche la même règle ; l'éditeur refuse un `mode` inconnu sur `statRules` ;
- la sauvegarde : le format porte les statuts (`entity_stats.dart:82-88`, `:129`), mais la liste est toujours vide à l'écriture (`map_progression_manager.dart:37`).

**La spec doit fixer** : les textes générés qui doivent dire « 6 armure → 3 Puissance », chaînes ARB comprises ; `ratio` dans le vocabulaire de l'éditeur et l'onglet Héros du menu de debug ; l'affichage du panneau des statuts quand deux Puissances coexistent ; la sauvegarde — rien à migrer, `StatusEffect.fromJson` tolère l'absence du champ neuf ; les tests : `demon_form` puis `iron_wall` donne deux effets vieillis séparément, l'arrondi sur 1, 5 et 6, le tutoriel ne casse pas.
**À arbitrer** : **l'identité d'une source**, pour chacune de ses six natures — une carte (l'id de carte ou l'`uniqueId` de l'instance, et ce que « la même carte rejouée s'additionne » veut dire avec deux exemplaires dans le deck), la règle de classe, un passif, une relique, un statut qui en pose un autre, un ennemi ; **la portée de la règle** — `might` seul, ce que dit le titre de D36, ou tout statut, ce que dit son texte : dans le second cas les trois lecteurs ci-dessus et le test de `poison` sont dans le lot, et la spec dit ce que la règle fait des statuts que les runes élémentaires posent hors d'`addStatus` ; la borne de `ratio` dans l'éditeur.
**Ne pas absorber** : rien d'E1 ; ni `mightRatio` (D38) ni le budget de Puissance ; aucun rééquilibrage de carte.
**Point propre au vérificateur** : rien — ni dans la spec, ni dans une tâche du plan — ne touche `forge_upgrade_data.dart`, le `switch` des runes d'`effect_resolver.dart` (`:142-164`) ni la logique de son bloc élémentaire (`:176-220`, hors l'appel à `createStatus`) — la fabrique `createStatus` du même fichier, elle, est dans le lot.
**Simulation** : E0 ajoute `ratio` à `class.json`, que le script ignore — son taux est en dur. Aucun réalignement.

#### E1 — le moteur de runes data-driven

**Fichiers** : `<AAAA-MM-JJ>-p43-e1-moteur-de-runes-design.md` pour la spec, le même nom sans `-design` pour le plan.
**Décisions** : D4 (le niveau d'une rune, borné), D27, D33 (`sharp`, `hardened`), D44 et D51 **pour les huit runes d'aujourd'hui** — `requiresMinCost` et `excludesRunes` servent dès E1 (`eco`, `enduring`) et recevront telle quelle la donnée de `cheap` en E2 ; `requiresCost` (`transfusion`) entre en vague 5 avec `costs` (D40, fiche 8.5) : E1 ne l'écrit pas —, D61, D68, D72, D75 ; D28 pour le seul renommage `forgeSlotBonus` → `fusionRank` ; G1 et G2 (brainstorm §4.5) — **des propositions que D68 met dans E1, non des décisions acquises** : leur rencontre et la portée de G1 s'arbitrent par §5. **E1 ne change pas la boucle de jeu** (D68) : `pools`, `stackable` et la capacité restent en lecture pour la forge du feu et le nœud Forge de Fusion.

**À lire** : **la spec E0, section « Décisions »** — la portée de la règle et le sort des statuts que les runes élémentaires posent, que la spec E1 suit ; brainstorm §1 (D72, qui corrige le mécanisme de D68, et D75, qui le précise), §4.2 (modèle de rune, esquisse `sharp.json`, prédicat du geste de fusion), §4.4 avant-dernier point (« le prérequis moteur » : l'applicateur que les évolutions de signature partageront en code), §4.5, §8 en entier, §11 ligne E1 ; revue §2.1 (les sept lecteurs de la capacité : E1 n'en touche aucun), §3.5, §13 IV3 et IV4, §15 W1 ; ADR-094, ADR-061, ADR-100 ; les fiches que le lot périme — `_rules/03-8`, `_rules/02-4`, `_patterns/10-00`.
**État mesuré** :
- la donnée : `forge_upgrade_data.dart` (`pools`, `valueMultiplier`, `eligibleCardTypes`, `stackable`, `requiresExhaust`), dont le gabarit de description `{val}` = palier × `valueMultiplier` (`:86-92`, lu par `forge/forge_slot_row.dart:200`), qui ne sait pas dire « 15 % de la base » ; le descripteur de rune de l'éditeur, `entity_descriptor.dart:326-360` (`requiredKeys: {'pools'}`), et `:238` pour `baseMaxForgeUpgrades` dans le gabarit de carte ;
- l'effet : `effect_resolver.dart:142-164`, le `switch` — il couvre **sept** runes ; `enduring` est lue par `CardInstance.exhaustsOnPlay` (`card_instance.dart:30-33`) ; `:176-220`, **la pose des statuts des runes élémentaires** — hors du registre de stratégies, sans `addStatus`, avec une éligibilité en dur (`type == attack`, `:177`) : ce bloc est à E1 ; `:222-228`, le multiplicateur de rareté, aussi sur `draw` et `gain_mana` ; `card_instance.dart:35-50` (paliers et collisions d'arrondi) ;
- **la formule de `sharp` et `hardened`, « +2 par niveau », est écrite à six endroits** : `effect_resolver.dart:144,147` ; `card_text_renderer.dart:106-108` (par `valueMultiplier`) et `:367-368` (en dur) ; `card_component.dart:354-355` ; `ui_card/ui_card_helpers.dart:356-357` ; `ui_card/card_compact_description.dart:51-52` ;
- les ids de rune en dur dans des `switch` d'affichage : `card_text_renderer.dart:459-481`, `card_component.dart:465-495`, `forge/forge_slot_row.dart:36-127`, `forge/forge_card_preview.dart:24-38`, `ui_card/ui_card_helpers.dart:218-232` et `:451-472` ;
- **quatre endroits écrivent un niveau de rune, et `maxLevel` les borne tous dès E1 (D72)** : `ForgeRuneRules.consolidate` (`forge_rune_rules.dart:46-52`) — qui ne sert **que** la fusion de cartes 3 → 1 (`deck_controller.dart:315`, `deck_screen.dart:226`) ; `fusionOptionsFor` (`:60-78`), dont le nœud Forge de Fusion écrit la somme telle quelle (`forge_fusion_screen.dart:55`) ; le tirage de niveau de la forge du feu (`forge_upgrade_dialog.dart:176-185` — niveau 2 à 15 %, niveau 3 à 5 %, sur toute rune cumulable) ; le même tirage sur les pré-forgées de la boutique (`shop_controller.dart:144-153`). `eco`, `quick` et `freezing` sont cumulables aujourd'hui : `stackable` vaut `true` par défaut (`forge_upgrade_data.dart:56`), seule `enduring` le met à `false` ;
- **une carte peut porter deux exemplaires d'une même rune** : le feu ajoute sans regarder l'id (`deck_controller.dart:344-349`) et son offre ne filtre pas ce que la carte porte (`forge_upgrade_dialog.dart:80-101`), quand la boutique écarte les ids déjà portés (`shop_controller.dart:138`) ; le moteur additionne les exemplaires (`effect_resolver.dart:136-154`) — deux `eco:1` rendent 2, et la Forge de Fusion, bornée, les réunirait en `eco:1` contre 80 or. D75 ferme ce chemin dès E1. Et `freezing:k` pose un `freeze` qui dure `k` attaques ennemies (`effect_resolver.dart:188`, `turn_phase_manager.dart:117-123`) : son plafond à 1 se voit ;
- l'offre : `forge_upgrade_dialog.dart:80-101` et `shop_controller.dart:51-75` (les deux lecteurs de l'éligibilité) ; `card_data.dart:33-39` et `:142-143`.

**La spec doit fixer** : un seul prédicat d'éligibilité, fonction pure, sur le modèle d'`isOfferableTo` — `eligibleCardTypes` ou `eligibleEffects`, `requiresExhaust`, `requiresMinCost` sur le coût courant, `excludesEffects`, `excludesRunes` symétrique, et le plafond déjà atteint sur la carte, exemplaires additionnés (D75) ; `maxLevel` de chaque rune d'aujourd'hui selon la table de §8, lu par **une** fonction que les quatre endroits ci-dessus appellent (D72), et ce que la fusion de cartes fait de deux niveaux dont la somme dépasse le plafond ; ce que devient la pose des statuts élémentaires (`:176-220`) sous l'applicateur ; la formule de `sharp` et `hardened` à **un** endroit, lue par les six sites d'aujourd'hui, et le gabarit de description qui la dit ; G1 et G2 ; le renommage et l'amendement d'ADR-094 ; les huit JSON — ce qui s'ajoute, ce qui **reste** ; le descripteur de l'éditeur ; les tests, dont un test de données par rune.
**À arbitrer** : **la forme de l'applicateur de deltas** — comment une rune déclare son effet en donnée pour couvrir les huit d'aujourd'hui, les trois d'E2 et les six de P-44 sans en écrire aucune de neuve, et la couture que les évolutions de signature réutiliseront en code sans confondre les deux systèmes ; ce que deviennent les `switch` d'affichage — en donnée dès E1, ou laissés à E2 ; **la rencontre de G1 et de G2** — G2 gèle le multiplicateur de rareté sur `draw` et `gain_mana`, et `concentration` (`draw 2`) comme `focus` (`gain_mana 1`) ne portent rien d'autre : ce que gagne à la fusion une carte dont tous les effets sont gelés, alors que G1 veut qu'une fusion change toujours un chiffre ; et la portée de G1 sur `heal` et `apply_status` ; ce que propose la Forge de Fusion quand la somme dépasse le plafond — sans objet en partie neuve sous D75, mais la fonction de D72 doit le dire : proposition, une fusion qui perdrait un niveau n'est pas proposée.
**Ne pas absorber** : la fusion, l'héritage, l'affûtage, le Puits, la boutique, les pré-forgées, la suppression de la capacité, de `pools` et de `stackable`, `minFusionRank`, « une rune par type » hors des runes que D75 ferme à leur plafond — tout cela est E2 ; aucune rune neuve ; les évolutions de signature.
**Point propre au vérificateur** : `pools`, `stackable` et la capacité gardent leurs lecteurs ; **aucun écran ne change de déroulé**. Les seuls changements visibles sont ceux que le lot livre : la formule de `sharp` et `hardened` (D33) ; l'offre de runes de la forge du feu et de la boutique, filtrée par l'éligibilité en donnée (D44, D51, D61, D75) ; le plafond `maxLevel` partout où un niveau s'écrit — la fusion de cartes, le nœud Forge de Fusion, le tirage de niveau du feu et celui des pré-forgées (D27, D72) : une spec ou une tâche qui borne l'un de ces quatre endroits est dans le lot ; les valeurs que G1 et G2 corrigent.

**Simulation** : aucun réalignement, tant qu'E1 ne touche ni le `weight` d'aucune des huit runes ni l'`eligibleCardTypes` des six autres que `sharp` et `hardened` (§7.3, ligne 1) — une consigne à redonner au rédacteur de la spec et à celui du plan. **L'orchestrateur relance quand même** à la fin de la vague : diff strictement vide attendu (D73).
**Ce que le joueur voit en `0.5.3`** : *(E0)* le Berserker convertit moitié moins d'armure en Puissance ; deux bonus de Puissance de durées différentes ne se confondent plus ; *(E1)* `sharp` et `hardened` donnent +15 % de la base par niveau, au moins +1, au lieu de +2 ; `hardened` n'est plus proposée sur une carte sans armure, où elle ne faisait rien ; la forge ne propose plus `eco` sur une carte gratuite ni `enduring` sur une carte qui pioche ou rend du mana ; `eco` et `quick` ne dépassent plus le niveau 1 — ni au feu, ni à la fusion, ni à la Forge de Fusion, ni en boutique —, et une carte n'en porte plus deux exemplaires ; `freezing` ne dépasse plus le niveau 1 non plus : son gel ralentit une attaque ennemie, et non plus deux ou trois ; une fusion change toujours au moins un chiffre de dégâts ou d'armure, et ne multiplie plus la pioche ni le mana rendu. *(`sharp` devient éligible aux Compétences de dégâts, D61 ; aucune des 23 cartes d'aujourd'hui n'en est une : cela ne se verra qu'avec le lot Arcaniste, en vague 5 — la note de `0.5.3` n'en parle pas.)* **La ligne se réécrit sur ce que la vague a livré**, arbitrage de G1 et G2 compris.
**Pour `memory-bank-sync`** : *(E0)* ADR « un statut par source et `ratio` » ; fiches `_rules/04-00` (la fusion des statuts) et `_rules/02-2` (la conversion du Berserker) ; *(E1)* ADR « moteur de runes data-driven », qui amende ADR-094 ; fiches `_rules/03-8` (le filtrage par effet, `maxLevel`, le plafond atteint qui ne se repropose plus — D75 ; la description d'`eco` est déjà corrigée), `_rules/02-4` et `_patterns/10-00` (`forgeSlotBonus` → `fusionRank`).

### 8.2. Vague 2 — `0.5.4` — E2, fusion = forge

**Fichiers** : `<AAAA-MM-JJ>-p43-e2-fusion-forge-design.md` pour la spec ; `<AAAA-MM-JJ>-p43-e2-fusion-forge-partie-<n>.md` pour chaque plan.
**Décisions** : D3, D4 (le niveau monté contre de l'or), D5, D6, D13, D14, D20, D22, D28, D32, D33 (`spectral`), D39, D44 et D51 (la donnée de `cheap` : `requiresMinCost: 1`, `excludesRunes: ["eco"]`), D46, D48, D63 (`b` = 50), D65, D68. Branche `feat/v0.5.4-p43-e2-fusion-forge`. **Le cœur de P3** : E2 supprime `pools`, `stackable` et la capacité avec les deux écrans qui les lisaient.

**À lire** : brainstorm §4.2 en entier, §4.3, §8 (lignes `cheap`, `precise`, `spectral` ; table des `maxLevel` ; paragraphe D65), §11 ligne E2, §12 lignes 1 et 2 ; **revue §2.1 en entier** (les sept lecteurs de la capacité, les six tests à réécrire, les ADR et fiches à amender), §11 S4 et S6, §13 IV3, IV5 et IV8, annexe A n° 29 (la fusion du tutoriel) ; rapport **§1.2** (les valeurs par défaut que la simulation a jouées), §2.3, §3.6, §3.8, §3.13, §3.15, §7.2 et §7.3 ; ADR-074, ADR-094, ADR-101, et pour l'histoire de la fusion et de la forge ADR-024, ADR-025, ADR-039.
**État mesuré** : `deck_controller.dart:288` (`mergeCards`), `:314-321` (héritage tronqué) ; `deck_screen.dart:200-231` ; `forge_upgrade_dialog.dart:32,51` ; `run_controller.dart:32-33` (`forgeSlots`, `forgeTargetCardId`) ; `rest_screen.dart:29` ; `rest_card_selection_screen.dart:30` ; `forge_fusion_screen.dart:102,112` et `forge_rune_rules.dart:60-78` (`fusionOptionsFor`) ; `map_content_placer.dart:24-36` ; `shop_controller.dart:188-205` et `:341-355` ; `shop_state.dart:16` ; `card_data.dart:142-143` ; `card_instance.dart:24` ; `ui_card.dart:69,101,241` ; `card_text_renderer.dart:519` ; `tutorial_engine.dart:451`.
**La spec doit fixer** : le geste de fusion (`ForgeUpgradeDialog` rappelé depuis l'écran de deck, le prédicat d'E1 comparé au rang **atteint**, moins de 3 runes si moins sont éligibles, jamais aucune tant qu'une existe) ; l'héritage par `consolidate` (D13) ; l'affûtage (une rune, un niveau, `b × niveau`, une fois par visite, `maxLevel` respecté) ; le Puits (toutes les runes éligibles au sens de §4.2 ; la rune reçue entre aux deux tiers du niveau de la rune donnée, arrondi au plus proche, **au moins 1**, puis borné par son `maxLevel` ; le coût est `base × niveau` **de la rune donnée** ; garanti tous les 3 actes sur les étages 3 à 7) ; la boutique (copie du deck, même rang, sans rune ; pré-forgées bornées par `fusionRank`) ; `minFusionRank` — `eco` et `quick` à 2 (D48), les trois runes neuves à 1, poids 50 (D63) ; le tutoriel (`:451`) ; les tests de la revue §2.1.
**À arbitrer** : l'écran d'affûtage et la manière de tenir « une fois par visite » ; l'écran du Puits ; ce que `forgeTargetCardId` désigne désormais ; la table de prix de la copie du deck ; **trois valeurs que la simulation a jouées sans qu'une décision les fixe** (rapport §1.2 — des valeurs de spec, à confirmer ou à remplacer en relançant) : la `base` du Puits, 50 or ; le `minFusionRank` 1 des six runes existantes autres qu'`eco` et `quick` (script `:1267-1269`) — alors qu'`enduring` n'est aujourd'hui que dans le pool `rare` ; et l'éligibilité de `precise` et de `spectral`, jouées sur les seules cartes de dégâts (script `:854`, `:858`) ; le découpage en parties.
**Parties proposées** : (1) la fusion propose une rune, l'héritage, la capacité supprimée, l'affûtage — la boucle change une fois ; (2) le Puits, la boutique, les trois runes, `minFusionRank`, `pools` et `stackable` supprimés.
**Ne pas absorber** : la trouvaille, `maxHandSize`, l'XP, la DDA, *Sagesse*, les sources d'affûtage hors feu, l'événement de relique (E3) ; les signatures (E4) ; les runes de pipeline (vague 5).
**Point propre au vérificateur** : après E2, plus aucun lecteur de `pools`, de `stackable` ni de la capacité (`git grep -w`).
**Simulation** : premier temps — réaligner le chargeur sur les trois fichiers neufs par une liste d'ordre explicite (§7.3, ligne 2), relancer : diff vide contre la référence. Second temps, **seulement si** un arbitrage remplace l'une des trois valeurs jouées ci-dessus ou le poids 50 des runes neuves : une relance par valeur, l'écart expliqué, la référence recommitée (§3.6).
**Ce que le joueur voit en `0.5.4`** : chaque fusion donne une rune parmi trois ; le feu de camp affûte ; le Puits d'échange remplace la Forge de Fusion ; la boutique vend une copie d'une carte du deck. **À dire dans la note** : les fusions restent rares jusqu'à la version suivante.
**Pour `memory-bank-sync`** : ADR « fusion = forge », qui amende ADR-074 et ADR-094 ; fiches `_rules/02-3`, `02-4`, `03-7`, `03-8` ; `_patterns/10-00` (`pools`, `stackable`, la capacité) et `_patterns/20-00` (ce que le script lit).

### 8.3. Vague 3 — `0.5.5` — E3, trouvaille et progression

**Fichiers** : `<AAAA-MM-JJ>-p43-e3-trouvaille-et-progression-design.md` pour la spec ; `<AAAA-MM-JJ>-p43-e3-trouvaille-et-progression-partie-<n>.md` pour chaque plan.
**Décisions** : D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57, D58, D59, D60, D62, D63 (Q15), D67. Branche `feat/v0.5.5-p43-e3-trouvaille`. **Les valeurs de D57 à D60 et de D67 sont mesurées** (rapport §4, §7) : la vague les livre, elle ne les rediscute pas. Celles de D63 et les deux défauts ci-dessous sont des valeurs de spec.

**À lire** : brainstorm §4.1 en entier, §4.3, §5, l'encadré de §2 sur la « pioche infinie », §11 ligne E3 et nœud R, §13 Q5 et Q15 ; revue §3.1 E2, §3.2 E3, §8.1 R5 et R8, §8.2 idées 5, 7 et 12 (les sources de D42, D43 et D47), §9 — **D43 et D47 y sont de ce lot ; la survie, l'or et la boucle XP vont à P-16, pas ici** —, annexe A n° 5, 11, 12, 13, 20, 23 ; rapport **§1.2**, §2.1, §3.1, §3.3, §3.9 à §3.11, §3.16, §4, §5, **§7.1**, §7.2 et §7.3 ; ADR-078, ADR-098, ADR-099, ADR-101.
**État mesuré** : `reward_controller.dart:75-82`, `:83-165` (`:86` le +10 % d'XP par niveau), `:168-195` (`:186-194` le `doubleXp` et sa carte bonus) ; `game_constants.dart:36` ; `deck_controller.dart:200` ; `run_controller.dart:41` et `player_stats_manager.dart:102-108` ; `player_stats_manager.dart:127` ; `encounter_system.dart:97-120` (`:97-101` la formule de `PlayerPower`), `:136-148` ; `level_up_reward_service.dart:38-148` ; `level_up_reward_data.dart:7-11`, `:277` ; `event_controller.dart:80-100` ; `passive_strategies.dart:108,146`.
**La spec doit fixer** : la table `cardDrops` par type de nœud et les reliques A (rare) et C (rare au moins), par `applyRunRuleModifier` ; `maxHandSize` en stat de run ; l'XP en table par acte — 115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015, dernière valeur répétée au-delà ; **le terme de deck de `PlayerPower`** devient 2 × Σ `fusionRank` à la place de `playerCardsCount × 2` — les autres termes (PV max, Puissance, mana, reliques) ne bougent pas ; `wisdom.json` en `pool: mythic` **avec `values.mythic: 1`** — le chargeur du jeu refuse une mythique de stat sans cette valeur (`level_up_reward_data.dart:283-285`), et 1 est la valeur que la simulation a jouée ; le boss « XP » sans carte, une rune du deck monte d'un niveau ; la relique légendaire de D42(a) — défaut joué : +1 rune affûtée par exemplaire ; l'événement d'affûtage de D42(b) — défaut joué : +1 niveau contre 10 % des PV max ; la récompense mythique qui monte un `maxLevel` ; l'événement d'échange de relique ; `threshold` de Bénédiction en donnée à 5 et `floor: 2` sur Flux ; le test qui garde la transition E3 → E4.
**À arbitrer** : où vivent les tables (Q5 : `cardDrops` dans `GameConstants` tant que le socle de carte n'existe pas ; la table d'XP « en donnée » — un document plat ou une constante nommée) ; les valeurs de D63 pour l'échange de relique (Q15) et les deux défauts ci-dessus : à confirmer, ou à remplacer **en relançant** (§5, filtre 2) ; ce que fait le boss « XP » quand aucune rune n'est sous son `maxLevel` ; le découpage en parties ; **D25 et la « pioche infinie »** — le bug du testeur n'a pas été reproduit : cherche à le reproduire par un test ; reproduit, c'est un correctif de cette vague ; non reproduit, `maxHandSize` migre quand même (D2) et l'ADR de la vague amende ADR-078 D3 en disant que le testeur a vu le cyclage.
**Parties proposées** : (1) la boucle — `cardDrops`, reliques, main, XP, DDA ; (2) les sources — boss « XP », relique légendaire, événements, mythique `maxLevel`, *Sagesse*, seuils.
**Ne pas absorber** : les reliques de mana, le puits d'or, la survie, la boucle XP / niveau ennemi, l'échange 3 → 1, l'événement de fusion (P-16) ; les signatures (E4) ; aucun rééquilibrage.
**Point propre au vérificateur** : aucune valeur de D56 à D62 ni de D67 n'a changé ; le réalignement du script est une tâche du plan.
**Simulation** : premier temps — réaligner sur les fichiers neufs, reliques, événements, mythique, `level_up_rewards/`, chacun à la place exacte de son entrée en dur (§7.3, ligne 3), relancer : diff vide **hors la ligne « Données lues »**, dont l'écart s'écrit d'avance dans le plan. Second temps, un commit et une relance chacun : le retrait de la relique B et de l'événement de D29 ; la table d'XP lue dans la donnée du jeu au lieu d'être recalée — la calibration reste affichée à côté ; et toute valeur jouée que l'arbitrage a remplacée. La référence est recommitée.
**Ce que le joueur voit en `0.5.5`** : une carte après chaque combat, une seconde possible en élite ; deux niveaux par acte ; des sources d'affûtage hors du feu ; un événement pour échanger une relique. La note la plus longue du chantier.
**Pour `memory-bank-sync`** : ADR « trouvaille et progression », qui amende ADR-078 D3 ; fiches `_rules/01-00`, `02-6` (la formule de `PlayerPower`), `02-1` (le boss « XP » n'octroie plus de carte), `03-4` (la main), `08-00` et `_patterns/02-1` (le palier d'XP) ; `_patterns/20-00`.

### 8.4. Vague 4 — `0.5.6` — E4, les signatures en compétences de classe

**Fichiers** : `<AAAA-MM-JJ>-p43-e4-signatures-design.md` pour la spec ; `<AAAA-MM-JJ>-p43-e4-signatures-partie-<n>.md` pour chaque plan.
**Décisions** : D49, D41, D53 ; D7 pour la forme ; D28 (`magic_missile` en Compétence). Branche `feat/v0.5.6-p43-e4-signatures`. Le modèle d'évolution et son écran sont **la vague 5** (D53) : E4 leur réserve le champ.

**À lire** : brainstorm, bloc « Vocabulaire », **§4.4** (forme, moteur, à revoir, esquisse `smite.json`, point « Stockage », point `magic_missile`), §5, §6, §11 ligne E4 ; revue §2.1, §11 — son paragraphe d'objet, où les deux lignes du tutoriel sont vérifiées —, annexe A n° 3, 24, 25, annexe B.2 ; rapport **§1.2** (la recharge de 2, valeur par défaut que la simulation a jouée) ; ADR-084, ADR-086, ADR-094, ADR-101, ADR-081, ADR-100.
**État mesuré** : `hero_data.dart:44` (`skills`) ; `hero_skills_link.dart:6-13` ; `starter_deck_draft_screen.dart:57` ; `game_data_service.dart:76-89` ; `card_data.dart:7`, `:22-28`, `:44`, `:136-139` ; `deck_controller.dart:158` ; `effect_resolver.dart:104-106` ; `combat_state.dart` ; `power_rules.dart` ; `tutorial_engine.dart:175` ; `tutorial_starter_deck_widget.dart:41` ; `save_service.dart` ; `passives/mage_mark.json` (`trigger: onAttackPlayed`) ; le HUD est en Flutter (`lib/ui/widgets/hud/`), la main en Flame.
**La spec doit fixer** : `classes/<id>/skills/<id>.json`, l'`EntitySource`, `sync_assets` ; la recharge dans l'état de combat, remise à zéro à chaque combat, jamais sauvegardée ; la résolution — mana, `resolveCard`, mise en recharge ; la suppression de `CardRarity.unique`, d'`isAcquirable` et de `CardCategory.characterSpecific` ; la barre au HUD et ses états ; le tutoriel (`:175`, `:41`) ; le draft de départ à 5 cartes ; la sauvegarde (les signatures sortent du `masterDeck`, sans migration) ; l'onglet du dictionnaire ; la carte de classe ; `magic_missile` en `type: skill`, **et ce que cela fait à *Marque du Mage* en `0.5.6`** (§7.2 : le passif ne se déclenche plus sur la signature, voulu) ; les tests.
**À arbitrer** : **le modèle** — un `SignatureData` propre ou un `CardData` restreint ; **une signature compte-t-elle comme une carte jouée pour les déclencheurs de passif** — `onSkillPlayed` de Flux de Mana avec `magic_missile`, `onAttackPlayed` de Soif de Sang avec `reckless_strike` et de *Marque du Mage* avec les signatures restées des Attaques ; « résolue comme une carte » penche pour oui ; le coût et la recharge de chaque signature — **la recharge de 2 pour les six et leurs coûts d'aujourd'hui sont les valeurs que la simulation a jouées** (script `:803` ; rapport §1.2) : des valeurs de spec, à confirmer, ou à remplacer en relançant ; ce que devient l'enum `CardCategory` si `global` reste seule ; les signatures dans l'éditeur de contenu, ou non pour ce lot ; les noms du modèle — ADR-084 a supprimé une chaîne de compétences à recharge et interdit ses noms dans le vault (`SkillData`, `SkillController`, `tickCooldowns`…) : d'autres noms, ou l'ADR de la vague lève l'interdit ; le découpage en parties.
**Parties proposées** : (1) donnée, modèle, moteur, sauvegarde, tests ; (2) HUD, tutoriel, draft, dictionnaire, sélection de classe.
**Ne pas absorber** : le modèle d'évolution, les pools et l'écran (vague 5) ; **le déclencheur `onDamagingCardPlayed` de D34** (vague 7 — il n'existe pas aujourd'hui) ; toute carte, toute rune ; un rééquilibrage des six signatures.
**Point propre au vérificateur** : plus aucune signature dans le `masterDeck` ni dans un pool d'offre ; `unique` et `characterSpecific` n'ont plus d'occurrence (`git grep -w`) ; le déclencheur de *Marque du Mage* n'a pas changé.
**Simulation** : premier temps — réaligner `classes/<id>/cards` → `skills` (`:798`), sans quoi le script plante, et lui faire lire la recharge et le type dans le fichier à la place des deux valeurs en dur (`:803`, `:805`) ; relancer : diff vide si l'arbitrage a gardé la recharge de 2 et les coûts d'aujourd'hui. Sinon, second temps : l'écart expliqué, la référence recommitée (§3.6).
**Ce que le joueur voit en `0.5.6`** : deux compétences de classe toujours disponibles, dès le premier tour, avec un temps de recharge. **À dire dans la note** : le Projectile Magique devient une Compétence et ne déclenche plus *Marque du Mage*.
**Pour `memory-bank-sync`** : ADR « signatures hors du deck », qui amende ADR-094, ADR-101 et ADR-084 ; fiches `_rules/02-3`, `02-2` (les cartes de signature), `07-00` ; `_patterns/20-00` ; **P-43 se clôt dans `docs/ROADMAP.md`**.

### 8.5. Vague 5 — `0.5.7` — la tranche 1 et P-44 lot 1

**Décisions** : D4 et D18 (les runes de mécanisme), D7 (les évolutions), D8, D9, D10, D12, D15, D16, D17, D19, D21, D28 (`focus` supprimée), D33 et D35 (`piercing` et `lifesteal` en pourcentage ; `lifesteal` soin propre à la carte), D34 (l'ordre : Rempart, Sang, Arcaniste), D38, D40, D44 (`requiresCost`), D45, D50, D54, D63 (Q9), D65 (`piercing`, `lifesteal`, `splash`, `echo`, `transfusion`), D66. Branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`. **Fichiers** : `<AAAA-MM-JJ>-p42-tranche-1-p44-lot-1-design.md` pour la spec ; `<AAAA-MM-JJ>-p42-tranche-1-p44-lot-1-partie-<n>.md` pour chaque plan. **Les cartes sont des ordres de grandeur** : la spec les fixe, le plan les écrit, le test du propriétaire les corrige. Le rédacteur prend le rôle `game_designer`.

**À lire** : brainstorm §3, **§6 en entier**, §7 (intro ; lignes Rempart, Sang avec sa note, Arcaniste), **§7.4 en entier**, §8 (les cinq runes), **§9 en entier**, **§4.4** (le modèle d'évolution), §5, §10 lignes 2 et 3, §11 nœuds C1 et P44a, §12, §13 Q6 à Q11 ; revue §7 idées 2.6 à 2.8, §8.1 R3 et R6, **annexe B en entier**, §11 S1, S11, S20, §13 IV9 ; rapport §1.2, §2.2, §3.12, §5 ; ADR-086, ADR-101, ADR-096, ADR-061, ADR-097, ADR-081.
**État mesuré** : `game_data_service.dart:76-89` (pas de source `cards/*/*.json`) ; `passive_data.dart:105` ; `passive_availability.dart` (« débloqué vaut tous », aucun masquage) ; `power_rules.dart:17-32` ; `strategies.dart:49`, `:61,69` (`_payLifesteal`), `:94` (le soin passe par le critique — le coût en PV n'est pas un soin négatif), `:147`, `:166-167` ; `effect_resolver.dart:104-106`, `:177-184`, `:204-205`, `:222-228` (la rareté ne multiplie jamais le terme `scaleWith`) ; `damage_pipeline.dart:15-18`, `:46-49` ; `turn_phase_manager.dart:107` et `enemy_instance.dart:28-29` (`freeze`) ; `passive_strategies.dart:85` ; `player_stats_manager.dart:472` ; `draft_screen.dart`, `DraftCardReel` (`_patterns/05-9`), `pendingDrafts` (`_rules/01-00`, `_patterns/02-1` ; `_rules/03-10` pour le draft de niveau différé) ; `tutorial_fixtures.dart:17-19` ; `entity_id_convention_test`, `referential_integrity_test`.
**La spec doit fixer** : le moteur — `scaleWith` sur six sources, `hits`, `mightRatio` et son test (Σ `hits` × `mightRatio` ≤ coût + 1), les statuts proportionnels et `freezing` qui perd son `maxLevel: 1`, `costs` et ses trois règles (D40), le validateur `costs.armor` dans un lot Berserker, la recalibration de *Marque du Mage*, les cinq runes — dont `requiresCost: "hp"` sur `transfusion` (D44) ; la forme C — `EntitySource('cards/*/*.json')`, `passive` injecté, `isOfferableTo` étendu d'une ligne, `classes` à une seule classe, le draft de départ, `feeds` et son test, le test des cartes gratuites (D50) ; les cartes — 5 à 6 par lot, bilingues, au moins une par mécanisme assigné : Rempart (`scaleWith: armor`, `costs.armor` — *Rempart brisé*, *Percée* à 0 mana), Sang (`costs.hp`, `scaleWith: missingHp` — *Sang versé*, *Dernier souffle* ; *Transe* pose `might_regen`, l'orphelin d'août ; `demon_form` déplacée), Arcaniste (Compétences de dégâts à 1, altération pure, **une Compétence multi-coups** — O4) ; `focus` supprimée ; les évolutions — `SignatureEvolutionData`, les pools des six signatures, `SignatureInstance.evolutions`, *Célérité* majeure (D54), l'écran par `pendingDrafts`, la sauvegarde.
**À arbitrer** : Q6 (3-4 mineures, 4-5 majeures, le repli) ; Q7 (deux majeures contradictoires : un champ `excludes` ou des pools sans conflit) ; Q8 (cartes-pont) ; Q9 (draft de départ, défaut 2 + 3) ; Q10 (`category: global` + `passive`, ou une valeur `lot`) ; Q11 (le double bonus de Puissance) ; **O5, le masquage des six passifs** — proposition : un passif dont le dossier `cards/<passif>/` est vide n'est pas disponible, dans `availablePassivesFor` ; le découpage en parties.
**Parties proposées** : (1) **le moteur P-44 lot 1 sur les 17 neutres**, avec les cinq runes — rien de visible, tout testé ; (2) **la forme C et les trois lots**, le masquage, les tests de données ; (3) **les évolutions et leur écran**.
**Ne pas absorber** : les six autres lots, D30, le déclencheur de D34, D55 ; P-44 lots 2 à 4 ; P-16 ; `maxMana` reste 3.
**Point propre au vérificateur** : chaque carte de lot touche une entrée de `feeds` ; aucune neutre ne porte de coût autre que du mana (D17) ; aucun lot ne dépasse une carte à coût total nul.
**Simulation** : faire lire au script les lots réels (§7.3, ligne 5), relancer — première mesure sur les vraies cartes, sur la table d'XP du jeu et non une table recalée (§7.3, ligne 3) ; la référence recommitée est celle que la vague 6 lira.
**Ce que le joueur voit en `0.5.7`** : le deckbuilding existe — trois passifs jouables avec leur lot, les mécanismes de profondeur, les évolutions de signature. **À dire dans la note** : six passifs quittent la sélection jusqu'à ce que leur lot de cartes arrive, dans les deux versions suivantes.
**Pour `memory-bank-sync`** : ADR « forme C et lots par passif » ; ADR « évolutions de signature » ; ADR « profondeur, lot 1 » ; les fiches `_rules` des cartes et des statuts ; `_patterns/20-00` ; **P-44 lot 1 se clôt dans `docs/ROADMAP.md`**.

### 8.6. Vague 6 — `0.5.8` — la tranche 2

**Un lot, trois lots de cartes** — une spec, un plan : **Croisé** (Paladin, *Ferveur*), **Vampire** (Berserker, *Soif de Sang*), **Voile** (Mage, *Canalisation*) — un par classe comme la tranche 1, Voile fixé par D66. L'orchestrateur peut re-arbitrer cette composition (O3) si la vague 5 a appris quelque chose qui la contredit ; il le dit. **Décisions** : D30, D35, D16, D17, D45, D50. Branche `feat/v0.5.8-p42-tranche-2`. **Fichiers** : `<AAAA-MM-JJ>-p42-tranche-2-design.md` pour la spec, le même nom sans `-design` pour le plan.

**À lire** : brainstorm §7.1 ligne Croisé, §7.2 ligne Vampire, §7.3 ligne Voile et la note, §7.4, §5, §1 (D30, D35) ; revue §7 idées 2.5, 2.7, 2.8, §12 T6 (*Barrière* re-valuée), annexe B.3 et B.4 ; la spec, les ADR et le compte rendu de la vague 5 ; la référence de simulation recommitée en vague 5 (`tool/simulations/d26_reference_output.md`).
**La spec doit fixer** : **D30** — Canalisation devient une banque de mana : `channeling.json` change d'`effectType`, `startTurn` lit la réserve, plafond `maxMana` plus 1 par point de Maîtrise, Mage uniquement ; le statut `mana_regen` sur le modèle de `might_regen` (*Méditation*) ; les cartes — Croisé (*Riposte*, *Jugement*, *Marteau sacré* en multi-coups), Vampire (Attaques à 1 qui piochent : *Morsure*, *Curée* ; *Lacération*, la carte à 0 du lot ; *Frénésie sanglante* en `scaleWith: cardsPlayedThisTurn`), Voile (*Barrière*, *Méditation*, *Sceau*) — complétées à 5 ou 6 par lot ; le démasquage des trois passifs ; les textes joueur de Canalisation.
**À arbitrer** : les cartes qui complètent chaque lot ; la courbe de coûts de Voile (des tours à 5-6 mana, sans carte à 0) ; les cartes-pont si Q8 les a retenues.
**Ne pas absorber** : la carte `retain` de Voile (P-44 lot 3, après `0.6.0`) ; la tranche 3.
**Point propre au vérificateur** : D50 tient pour Berserker · Vampire (`concentration` et *Lacération*, deux cartes gratuites, épuisables) ; aucune carte ne suppose un mécanisme hors périmètre.
**Simulation** : relancer sur six lots réels, recommiter la référence.
**Ce que le joueur voit en `0.5.8`** : trois passifs de plus avec leurs cartes ; Canalisation garde le mana non dépensé pour le tour suivant.
**Pour `memory-bank-sync`** : ADR pour la banque de mana si le mécanisme le justifie ; les fiches des passifs.

### 8.7. Vague 7 — `0.6.0` — la tranche 3

**Un lot, trois lots de cartes** — une spec, un plan : **Sanctifié** (Paladin, *Bénédiction*), **Carnage** (Berserker, *Frénésie*), **Marque** (Mage, *Marque du Mage*). **Décisions** : D34 (le déclencheur), D55, D43 (la variante « armure conservée », qui attendait ce lot), D16, D17, D45, D50. Branche `feat/v0.6.0-p42-tranche-3`. **Fichiers** : `<AAAA-MM-JJ>-p42-tranche-3-design.md` pour la spec, le même nom sans `-design` pour le plan.

**À lire** : brainstorm §7.1 ligne Sanctifié et la note, §7.2 ligne Carnage et la note, §7.3 ligne Marque et « Une tension levée, une gardée », §13 Q11 et Q12, §1 (D34, D43, D55, D60) ; revue §8.1 R6 et R8, §12 T6 (*Vigile* retirée), annexe B.1 ; les specs et les comptes rendus des vagues 5 et 6.
**La spec doit fixer** : **D34** — *Marque du Mage* se déclenche sur la première **carte de dégâts** du tour (`onDamagingCardPlayed`, à créer), Attaque ou Compétence — ce qui rend au passif la signature du Mage, perdue en `0.5.6` (§7.2) ; les quatre élémentaires déplacées dans le lot Marque — **`fireball` garde son id**, le tutoriel le lit (`tutorial_fixtures.dart:17-19`) ; **D55** — *Prière* et le statut `hp_regen` ; `weakness`, le dernier orphelin d'août, posé par *Sommation* et *Édit* ; `metallicize` déplacée dans Sanctifié, `warcry` dans Carnage ; les cartes — Sanctifié, Carnage (*Moulinet*, *Tourbillon*, *Coup de grâce*, *Exécution* en `scaleWith: targetMissingHp`), Marque (*Exploitation* en `scaleWith: targetStatus`, *Salve* en multi-coups) — complétées à 5 ou 6 ; les neuf passifs démasqués.
**À arbitrer** : Q12 (les élémentaires restent des Attaques — le brainstorm penche pour oui) ; Q11 si la vague 5 l'a laissée ouverte ; la variante « armure conservée » de D43 pour Sanctifié, ou rien ; les cartes qui complètent.
**Ne pas absorber** : *Forge de guerre* de Carnage (production de cartes, P-44 lot 3) ; les épines de Rempart (P-44 lot 2) ; P-16.
**Point propre au vérificateur** : le tutoriel tourne toujours avec `fireball` ; les neuf lots passent D45 et D50 ; aucun passif n'est resté masqué.
**Simulation** : réaligner sur les six cartes déplacées (§7.3, ligne 7), relancer sur les neuf lots — la mesure de référence que P-16 reprendra.
**Ce que le joueur voit en `0.6.0`** : neuf passifs jouables, chacun avec son lot.
**Pour `memory-bank-sync`** : les ADR et les fiches de la tranche ; **P-42 se clôt dans `docs/ROADMAP.md`**, comme P-43 en vague 4. La vague 7 écrit sa section dans le suivi, comme les autres, et s'arrête « livrée sur branche » : **elle ne dit pas le chantier clos** — c'est la session de clôture qui le fait, une fois `0.6.0` taguée (§8.8).

### 8.8. La clôture — sans version, après le tag de `0.6.0`

**Ni spec, ni plan, ni code, ni version, ni tag** (D74). Le propriétaire colle le prompt de §0 une fois de plus ; la session ne trouve plus de vague « à faire », seulement la ligne « Clôture ». Branche `docs/cloture-chantier-economie-et-catalogue`.

1. **La porte d'entrée** (§3.1), entière, sur la vague 7 : fusionnée, `v0.6.0` posé sur un commit de `main`, release publiée, CI verte, trois porteurs de version à `0.6.0`, `dart analyze` et `flutter test`.
2. **La branche** (§3.2). Premier commit, le journal : la vague 7 passe à « close », avec la date constatée ; la ligne « Clôture » passe à « faite », avec la date du jour.
3. **`memory-bank-sync`**, délégué, avec ces consignes : noter la clôture de la vague 7 — fusionnée, taguée, CI/CD verte — et celle du chantier ; dans `docs/ROADMAP.md`, porter **les trois cartes dues** (épines, `retain`, *Forge de guerre*) sur la ligne de P-44 et mettre à jour les constats de P-16 avec la mesure des neuf lots ; `activeContext.md` : le focus revient à la ROADMAP ; un ADR de clôture si le chantier a appris quelque chose de la méthode qui vaille pour le prochain.
4. **Le suivi des vagues** : le « Bilan du chantier » que le modèle prévoit, et l'en-tête passe à « Chantier clos ». Tu l'écris toi-même, à partir des sept sections et des comptes rendus.
5. **Ce fichier** : son en-tête passe à « chantier clos le `<JJ/MM/AAAA>` » et sa ligne de fin le dit. **Il ne se déplace pas** : une douzaine de fichiers y renvoient par chemin.
6. **Arrête-toi.** Message au propriétaire : la branche, ce qu'elle écrit. Il ouvre la PR et la fusionne — pas de test manuel, pas de tag. Ce que la branche dit clos le devient sur `main` au moment où elle y entre.

---

## 9. Les points ouverts

| # | Quoi | État |
|:---:|:---|:---|
| O1 | D34, le déclencheur de *Marque du Mage*, sans lot | **Vague 7**, avec le lot Marque — confirmé le 01/10 (revue §14, A2) ; la transition de `0.5.6` est en §7.2 ; ✅ graphe du brainstorm retouché le 01/10 |
| O2 | P-44 lot 4 absent du graphe du brainstorm | ✅ **Retouché le 01/10** ; le lot lui-même est hors périmètre |
| O3 | La composition des tranches 2 et 3 | **Fixée par défaut** : Croisé, Vampire, Voile puis Sanctifié, Carnage, Marque ; re-arbitrable en vague 6 |
| O4 | Arcaniste sans carte multi-coups | **Vague 5** |
| O5 | Le masquage des six passifs | **Vague 5**, à arbitrer ; proposition en §8.5 |
| O6 | Le numéro de version | ✅ **Tranché le 01/10** : `0.5.3` à `0.6.0`, §1 |
| O7 | La ROADMAP à redécouper | ✅ **Fait le 01/10** (ADR-102) |
| O8 | Le commit du dossier | ✅ **Fait le 01/10** |
| O9 | La relecture de ce fichier avant la vague 1 | ✅ **Faite et appliquée trois fois le 01/10** : revue §14 (V1 à V26) — l'ordre des gestes de sortie est D70, la référence de simulation est produite ; revue §15 (W1 à W26), porte d'entrée jouée et simulation relancée — D72, D73, D74 ; contrôle ciblé du texte neuf, revue §16 (X1 à X15) — D75 |
| O10 | Un suivi lisible sans technique | ✅ **Ouvert le 01/10** (D71) : `docs/suivi_vagues_chantier/`, un fichier par chantier selon le modèle du répertoire ; celui de ce chantier reçoit une section par vague, écrite en §3.8 |
| O11 | Qui clôt le chantier après la vague 7 | ✅ **Tranché le 01/10** (D74) : une session de clôture, par le même prompt, sur une branche de documentation — §8.8 |
| O12 | Où `maxLevel` s'applique dès E1 | ✅ **Tranché le 01/10** (D72) : aux quatre endroits qui écrivent un niveau de rune — fiche 8.1 |
| O13 | Le critère de la simulation quand une vague change une valeur | ✅ **Tranché le 01/10** (D73) : deux temps, le réalignement seul puis chaque changement voulu — §3.6, §7.3 |
| O14 | Deux exemplaires d'une rune plafonnée sur une même carte, en `0.5.3` | ✅ **Tranché le 01/10** (D75) : le prédicat d'E1 ne repropose plus une rune dont le plafond est atteint sur la carte, exemplaires additionnés — fiche 8.1 |

---

*Orchestration. Ce fichier fait foi pour le déroulé ; le brainstorm v3 pour les décisions. Prochaine étape : la vague 1, par le prompt de §0.*
