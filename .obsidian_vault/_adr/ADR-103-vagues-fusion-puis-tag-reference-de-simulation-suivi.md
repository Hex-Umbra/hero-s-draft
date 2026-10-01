---
description: Amends ADR-102 before the first wave — the owner merges then tags, a wave never runs delivery steps inherited from the plan template or from subagent-driven-development, the simulation is diffed against a tracked reference output in two steps (realign, then change), each wave leaves a written report and a plain-language entry in the wave log, and a closing session ends the programme after the last tag
---

# ADR-103 — La Méthode par Vagues, Relue avant la Première : la Fusion puis le Tag, une Référence de Simulation, un Compte Rendu Écrit et un Suivi en Clair

### Statut

✅ Accepté — 2026-10-01, par le propriétaire (brainstorm v3, décisions D70, D71, D73 et D74).
**Amende [ADR-102](ADR-102-chantier-par-vagues-une-version-par-vague.md)** sur trois de ses
décisions — D2 (le cycle), D5 (les gestes du propriétaire) et D8 (ce que la mémoire note) — et le
complète sur la simulation et sur la clôture. **Décision de méthode, sans code** : `lib/`, `test/`
et `assets/` sont inchangés. Vaut, comme ADR-102, pour le seul programme P-43 → P-42 → P-44
lot 1 — **sauf le répertoire de suivi et son modèle (D6), posés pour tout chantier livré par
vagues**.

### Contexte

Le fichier d'orchestration écrit le 2026-10-01 devait pouvoir être collé dans une session neuve et
dérouler une vague sans que le propriétaire intervienne. Avant de lancer la première, il a été relu
contre ce qu'il suppose : les décisions du brainstorm, le code, la chaîne de release, les deux
skills du projet et les skills d'exécution — cinquième passe de la
[revue](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §14.

Le fond tenait : aucune décision contredite, aucune valeur mesurée mal recopiée, l'ordre des vagues
conforme. Le mode d'emploi, lui, ne tenait pas à quatre endroits :

- **Le plan cité comme modèle livre.** Il ouvre par une tâche de documentation sur `main` et finit
  par la synchronisation de la mémoire et la clôture de branche ; l'outil d'exécution par agents
  enchaîne de lui-même sur un menu « fusionner, pousser, ouvrir une PR ». Un orchestrateur fidèle
  au modèle aurait fait ce qu'ADR-102 D5 lui interdit.
- **Le journal vit sur la branche de la vague.** Sur `main`, une vague commencée reste « à faire »
  jusqu'à sa fusion : une session rouverte sur `main` la recommençait, et rien ne disait quoi faire
  d'une vague livrée que le test du propriétaire renvoie en correction.
- **« La relance doit retrouver les chiffres » n'avait pas de référence.** Le rapport de simulation
  porte deux passes à deux réglages, aucune sortie brute n'était suivie par git, aucune tolérance
  n'était dite.
- **L'ordre « PR, tag, fusion » n'était pas celui de la pratique** : les trois derniers tags ont
  été posés après la fusion, sur un commit de `main`.

Le propriétaire a ajouté une demande : pouvoir suivre le chantier sans lire ni le code ni le
journal technique.

**Le fichier corrigé a été rejoué le même jour** — sixième passe, §15 de la même revue : la porte
d'entrée de la première vague lancée commande par commande, la simulation relancée en entier,
identique à sa référence. Trois choses manquaient encore à la méthode : les décisions prises
pendant l'exécution par agents étaient supprimées avec l'espace de travail de l'outil avant que le
compte rendu s'écrive ; un réalignement du script et un changement voulu, mêlés dans la même
relance, donnaient un écart qu'on ne pouvait plus attribuer ; et rien ne disait qui passe la
dernière vague à « close ».

### Décision

**D1 — La fusion, puis le tag** *(amende ADR-102 D5)*. Le propriétaire teste, ouvre la PR, la
fusionne dans `main` par un commit de fusion, puis pose le tag sur ce commit. La release ne sort
donc jamais avant la fusion, et la porte d'entrée de la vague suivante vérifie que le tag est un
ancêtre de `main`.

**D2 — Une vague ne livre rien, même par héritage** *(précise ADR-102 D2 et D5)*. Un plan ne
contient ni tâche de documentation sur `main`, ni tâche de livraison ; il n'invoque aucun skill de
synchronisation ni de clôture de branche. L'orchestrateur n'invoque pas la clôture de branche à la
fin de l'exécution par agents. Le vérificateur de plan tient une telle tâche pour un constat
bloquant.

**D3 — On cherche sa vague sur les branches avant de la chercher dans le journal.** Une branche de
vague non fusionnée dit que la vague est commencée : la session bascule dessus et lit le journal
de la branche. « En cours » se reprend à l'étape notée, sans repasser la porte d'entrée ; « livrée
sur branche » ouvre une **session de correction**. Toute mise à jour du journal est commitée sur
la branche, avec le document qu'elle note. **Une reprise ne détruit rien** : un arbre sale se
range, un commit rouge se corrige par un commit, l'historique d'une branche ne se réécrit pas.

**D4 — La session de correction rouvre les documents de la vague en place.** Tant que la vague
n'est pas taguée, sa note de version et ses ADR ne sont pas publiés : ils se reprennent sur la
branche, par exception à la règle qui protège les notes et les ADR publiés. Un arbitrage que le
propriétaire renverse amende la spec ; il ne devient pas une décision acquise du brainstorm.

**D5 — La simulation se compare à une sortie de référence suivie par git, en deux temps**, pas
aux chiffres de son rapport. Le plan réaligne le script ; c'est l'orchestrateur qui le lance.
**Premier temps, le réalignement seul** : aucune valeur que le script tient en dur ne change,
chaque fichier neuf prend la place exacte de son entrée en dur, et la relance rend un diff vide —
hors la ligne de la sortie qui compte les fichiers lus. **Second temps, chaque changement voulu**
— une valeur jouée que l'arbitrage remplace, une entrée retirée —, relancé à part : l'écart est
attribué par construction, et la référence recommitée. Un écart inexpliqué arrête la vague. Le
diff vide prouve que le script n'a pas bougé ; il ne valide pas les données de la vague.

**D6 — Une vague laisse deux écrits de plus que son code** *(complète ADR-102 D2)*. Un **compte
rendu technique** en fichier — arbitrages, cahier de test manuel, résultat de la simulation —, que
la session de correction relit ; **il s'ouvre à la fin du premier plan**, parce que l'outil
d'exécution supprime son registre de décisions à la fin de chaque plan, et qu'une décision prise
au nom du propriétaire ne doit pas mourir avec lui. Et sa section dans le **suivi des vagues** :
pourquoi cette vague, ce qu'elle apporte au jeu, sans technique, pour quelqu'un qui joue et ne lit
pas le code. Le suivi a son répertoire, un fichier par chantier, et un modèle commun qui en fixe
l'en-tête, l'organisation et la manière d'écrire.

**D7 — La mémoire ne clôt que ce qui est clos** *(précise ADR-102 D8)*. `docs/ROADMAP.md` ne
bouge que lorsqu'une de ses lignes se clôt — un chantier `P-xx`, ou le lot 1 de P-44, seul lot de
P-44 dans le programme —, jamais pour un lot E ni pour une tranche : l'avancement par lot reste au
journal du fichier d'orchestration. La liste de fiches qu'une vague donne à la synchronisation est
un minimum, pas un périmètre.

**D8 — Une session de clôture ferme le chantier.** Une vague passe à « close » dans le premier
commit de la suivante ; après la dernière, le même prompt collé une fois de plus ouvre une session
qui passe la porte d'entrée sur le dernier tag, ouvre une branche de documentation, note la
clôture dans le journal, la mémoire, la ROADMAP et le suivi, et s'arrête : une PR à fusionner, pas
de tag. Aucune vague ne dit le chantier clos avant que sa dernière version soit publiée.

### Preuves dans le code

Aucun code : la décision porte sur la manière de travailler.

| Élément | Emplacement |
|:---|:---|
| Les décisions du propriétaire | [brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1, D70, D71, D73 et D74 |
| Les constats et les arbitrages des deux passes | [revue du brainstorm v3](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §14 et §15 |
| Le cycle corrigé, la session de correction, les gabarits, la session de clôture | [fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §0, §3, §4, §6 et §8.8 |
| La sortie de référence de la simulation | `tool/simulations/d26_reference_output.md` — voir [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md) |
| Le suivi des vagues, et son modèle | `docs/suivi_vagues_chantier/economie_unifiee_et_catalogue.md` ; `docs/suivi_vagues_chantier/_modele_suivi.md` |
| Les comptes rendus de vague | `docs/superpowers/reports/` — ouvert le 2026-10-01, rempli à partir de la première vague |
| Le tag déclenche la release, quel que soit l'ordre | `.github/workflows/release.yml` ; [ADR-079](ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md) |
| Le plan cité comme modèle, et ce qu'il ne faut pas en reprendre | `docs/superpowers/plans/2026-09-16-p49-passifs-partages.md` — sa première tâche, et les étapes de livraison de sa dernière |

### Conséquences

- **ADR-102 reste la décision de méthode** ; cet ADR en corrige l'ordre de sortie et en borne le
  cycle. Là où les deux divergent, celui-ci a raison.
- **`main` n'est pas protégé côté GitHub** : « ne jamais commiter sur `main` » ne tient que par le
  texte du fichier d'orchestration et par la vérification du plan.
- **La porte d'entrée autorise l'orchestrateur à basculer sur `main` et à le tirer en avance
  rapide** : après une fusion faite sur GitHub, le `main` local est en retard, et ce n'est pas un
  commit sur `main`.
- **Le script de simulation devient un test de non-régression au sens strict** — un diff —, ce qui
  demande à chaque réalignement de garder l'ordre des listes qu'il tire au sort, et coûte une
  relance de plus par changement voulu.
- **Une vague écrit dans trois endroits en plus de son code** : le journal, qu'ADR-102 posait
  déjà, et les deux écrits de D6. Le journal et le compte rendu sont techniques ; le suivi ne
  l'est pas, et aucun des trois ne recopie les deux autres.
- **Le programme compte une session de plus que de vagues** : la clôture, sans version ni tag.
- **Une transition est assumée et non corrigée** : quand la signature offensive du Mage devient
  une Compétence, *Marque du Mage* ne se déclenche plus sur elle jusqu'à ce que son lot de cartes
  arrive — le périmètre des vagues n'a pas bougé pour l'éviter, la note de version le dit.
