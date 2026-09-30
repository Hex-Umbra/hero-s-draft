---
description: A programme delivered by waves — one wave per game version, one session per wave, an orchestrator that arbitrates spec questions, while the owner keeps manual test, PR, tag and merge
---

# ADR-102 — Un Chantier par Vagues : une Version par Vague, une Session par Vague, et le Propriétaire Garde le Tag

### Statut

✅ Accepté — 2026-10-01, par le propriétaire (brainstorm v3, décision D69). **Décision de méthode,
sans code** : rien n'est livré par cet ADR, `lib/`, `test/` et `assets/` sont inchangés depuis
[ADR-101](ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md). **Vaut pour le seul
programme P-43 → P-42 → P-44 lot 1** ; hors de lui, le rythme « une session par phase » suivi
jusqu'ici reste la règle.

### Contexte

Les trois chantiers qui restaient du programme « Identité de classe & catalogue » — P-42, P-43,
P-44 — ont été reconçus par un brainstorm (22/09 → 01/10), relu en quatre passes et adossé à une
simulation de l'économie de deck. Il en sort un découpage : cinq lots pour P-43 (E0 à E4), trois
tranches pour P-42, et le premier lot de P-44 livré avec la première tranche.

Jusqu'ici, chaque phase d'un lot avait sa session : la spec, le plan, la passe de correction du
plan, l'implémentation, puis la synchronisation après fusion — le propriétaire collant un prompt à
chaque étape. C'est ce qui a livré P-41 en quatre lots et sept parties. Appliqué à ce programme,
le même rythme demandait plusieurs dizaines de sessions avant la deuxième tranche de cartes.

Deux faits pesaient en plus :

- **La version n'était pas planifiée par lot.** La note `0.5.2` a été rouverte en place six fois
  pour les lots de P-41 avant d'être taguée (`progress.md`, §4). Ce programme change la boucle de
  jeu à presque chaque lot : le joueur doit pouvoir dire quelle version a apporté quoi.
- **Les vrais défauts d'un document sortent d'un lecteur qui ne l'a pas écrit et qui lit le code.**
  La quatrième passe de revue du brainstorm n'a trouvé aucune contradiction entre décisions ; ses
  deux constats de fond sont venus de la lecture des chemins de code qu'une spec aurait à parcourir.

### Décision

**D1 — Une vague est une version du jeu, une session, un orchestrateur.** Le programme se livre en
vagues successives ; chacune regroupe un ou plusieurs lots et se clôt sur une version. La table des
vagues et de leurs versions vit dans le fichier d'orchestration, et nulle part ailleurs.

**D2 — Le cycle d'une vague est fixe** : une porte d'entrée vérifiée par commande ; une branche
dans le checkout principal ; la spec ; le plan ; l'implémentation ; `patch-notes-writer` à la
version de la vague, puis `memory-bank-sync` ; le journal et un compte rendu ; l'arrêt. À
l'intérieur d'une vague, les lots et les parties d'un lot se déroulent **en série** : le document
suivant s'écrit sur le code que le précédent a laissé sur la branche, jamais sur une prévision.

**D3 — Le vérificateur n'est jamais le rédacteur.** La spec, puis le plan, sont écrits par un
agent, contrôlés par un autre qui part d'un contexte neuf, corrigés, puis revérifiés par un
troisième — jusqu'à ce qu'il ne reste aucun constat bloquant ni moyen. La boucle est bornée à
trois tours ; au-delà, la vague s'arrête et rend la main.

**D4 — L'orchestrateur arbitre seul les questions de spec**, par un arbre de décision qui retient
l'option la plus cohérente avec le jeu : une décision acquise d'abord, une valeur mesurée ensuite,
puis les principes du brainstorm, le mécanisme plutôt que le cas, l'architecture du dépôt, ce que
le joueur lit, le périmètre. **Il n'amende jamais une décision acquise et ne change jamais une
valeur mesurée sans relancer la simulation** : si une question ne se tranche qu'à ce prix, la vague
s'arrête. Chaque arbitrage est consigné dans la spec et dans le compte rendu.

**D5 — Le propriétaire garde le test, la PR, le tag et la fusion.** L'orchestrateur ne pousse
rien, n'ouvre pas de PR, ne pose pas de tag, ne fusionne pas, et ne commite jamais sur `main` :
tout ce qu'une vague écrit, spec et plan compris, va sur sa branche. La vague suivante n'ouvre que
lorsque sa porte d'entrée constate que la précédente est fusionnée, taguée, et que sa CI/CD est
verte.

**D6 — Deux autorités, qui ne se recopient pas.** Le fichier d'orchestration fait foi pour le
*déroulé* — vagues, versions, journal d'avancement, fiches de vague. Le brainstorm v3 reste la
source de vérité des *décisions de conception*. `docs/ROADMAP.md` garde une ligne par chantier et
renvoie au fichier d'orchestration.

**D7 — Le périmètre est ce qui a été brainstormé** : P-43, P-42 et P-44 lot 1. Les lots 2 à 4 de
P-44 et P-16 viennent après la dernière vague.

**D8 — La mémoire note une vague livrée comme « livrée sur la branche, en attente »**, jamais
comme fusionnée ni publiée : ce ne l'est pas encore quand `memory-bank-sync` tourne. La clôture
d'une vague — fusion, tag, CI/CD — se note à la vague suivante, qui vient de la constater.

### Preuves dans le code

Aucun code : la décision porte sur la manière de travailler. Ses preuves sont des documents et la
chaîne de release qu'elle respecte.

| Élément | Emplacement |
|:---|:---|
| La décision du propriétaire | [brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1, D69 — qui amende D64 |
| Les vagues, les versions, le journal, le cycle, l'arbre de décision, les garde-fous | [fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §1 à §6 |
| Les fiches de vague | même fichier, §8 |
| Le constat sur la lecture indépendante | [revue du brainstorm v3](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §13 |
| Le renvoi de la planification | `docs/ROADMAP.md`, §4 (programme P-40 à P-44) et §9 |
| Le renvoi des instructions | `CLAUDE.md`, table « Documentation Map » |
| Ce que déclenche un push sur `main` | `.github/workflows/ci.yml` — `push` et `pull_request` sur `main` |
| Ce que déclenche un tag | `.github/workflows/release.yml` — `push` d'un tag `v*.*.*` ; voir [`_patterns/15-00`](../_patterns/15-00-chaine-de-release-et-site-vitrine.md) et [ADR-079](ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md) |

### Conséquences

- **`docs/ROADMAP.md` ne tient plus le séquencement de ce programme.** Elle dit quels chantiers
  restent et dans quel ordre ; les vagues, leurs versions et leur état sont lus dans le fichier
  d'orchestration. Un fait écrit aux deux endroits serait une occasion de diverger.
- **La version est imposée à `patch-notes-writer`**, qui reste seul à l'écrire : une vague, un
  numéro, plus de note rouverte lot après lot. Le vault continue de ne pas la recopier.
- **`memory-bank-sync` tourne avant la fusion**, sur la branche de la vague — ce qui est nouveau :
  jusqu'ici il tournait après. D8 dit ce qu'il a le droit d'écrire.
- **Une vague peut être longue.** Les lots lourds se découpent en parties, et le journal du
  fichier d'orchestration note l'étape franchie : une vague interrompue se reprend dans une session
  neuve là où elle s'est arrêtée.
- **La porte d'entrée dépend de `gh`** pour constater la CI/CD. S'il ne joint pas l'API, elle
  demande au propriétaire de le confirmer et le note — elle ne suppose pas.
- **Les arbitrages de l'orchestrateur se relisent au moment du test.** Un arbitrage renversé se
  corrige sur la branche, avant la fusion ; il ne devient pas une décision acquise du brainstorm.
- **La vague 0 a fait exception.** Sans code ni version — la ROADMAP redécoupée, cet ADR, trois
  retouches au brainstorm —, elle a été faite le 2026-10-01 dans la session qui a écrit le fichier
  d'orchestration, directement sur `main`, à la demande du propriétaire.
- **Ce qui ne change pas** : une branche et jamais un worktree, `dart analyze` propre et les tests
  verts à chaque tâche, jamais de `dart format`, la forme des specs et des plans, et des
  sauvegardes qui ne se transfèrent pas d'une version à l'autre avant la `1.0.0`.
