---
description: Closing record of the "unified economy and catalogue" programme (waves 0 to 8, 0.5.2 to 0.6.0) — gathers the method amendments the owner adopted during waves 4 to 6 and that later waves confirmed, which until now lived only in the wave reports; keeps apart, as proposals the owner has not adopted, the amendments raised by waves 7 and 8 (one of them established twice); records that R31 was tried once without a verdict and that closing the programme lifts the freeze ADR-108 D8 put on the blueprints, their installation remaining the owner's decision
---

# ADR-120 — Ce que le Chantier « Économie Unifiée et Catalogue » Lègue à la Méthode par Vagues

### Statut

✅ Accepté — 2026-11-19, session de clôture du chantier
([fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§8.9, point 3 ; brainstorm v3 D74). **Décision de méthode, sans code.** Ne décide rien de neuf : il
rassemble ce que les §5 « Les leçons » des comptes rendus des vagues 4 à 8 établissent, et sépare ce
que le propriétaire a adopté de ce qui n'est que proposé. **Complète
[ADR-108](ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md)** (D1
confirmée, D8 échue), qui ne change que de Statut ; confirme
[ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md). ADR-102 et ADR-103 restent la
méthode.

### Contexte

Le chantier est clos : neuf vagues, de la vague 0 à la vague 8, de `0.5.2` à `0.6.0`, la dernière
fusionnée par la PR #56 et taguée `v0.6.0` le 2026-11-19
([ADR-118](ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md)). Sa méthode tient en
quatre ADR — 102, 103, 108, 113 — et dans le fichier d'orchestration, qui « ne se déplace pas » et
reste le texte de *ce* chantier.

Depuis ADR-108, chaque compte rendu de vague finit par cinq leçons au plus, chacune avec
l'amendement de méthode qu'elle propose, ou « rien » (`docs/superpowers/reports/README.md`).
**Plusieurs de ces amendements ont été adoptés et appliqués dès la vague suivante, mais aucun n'est
écrit dans les gabarits du fichier d'orchestration** (§4, §5 ; recherche par `grep` le 2026-11-19) :
ils ne vivent que dans les §5 des comptes rendus et dans la mémoire de l'orchestrateur. Un prochain
chantier qui partirait des quatre ADR les perdrait. Les vagues 1 à 3 n'ont pas de §5 de leçons : leur
mesure est l'[audit](../../docs/possible_upgrades/05-10-2026_audit_workflow_ia_et_orchestration_par_vagues.md)
qu'ADR-108 a tranché.

### Décision

**D1 — Cinq amendements adoptés en cours de chantier font partie de la méthode par vagues.** Chacun
est né d'une leçon et a tenu à la vague suivante, selon son compte rendu :

| | Amendement | Né de | A tenu |
|:---|:---|:---|:---|
| A1 | À chaque tâche d'interface, l'orchestrateur trie les mineurs visibles du joueur avant la suivante | vague 4, §5.2 — trois défauts de mise en page notés mineurs, remontés seulement à la revue d'ensemble | vague 5, §5.1 (S11, S19, S20 corrigés) ; vague 6, §5.4 (trois écarts) |
| A2 | Une tâche de vérification pure — des commandes, aucun fichier — est jouée par l'orchestrateur, sans agent | vague 4, §5.4 | vague 5, §5.1 (S5, S13, S22 : un grep en défaut chacune) ; vague 6, §5.4 |
| A3 | La fiche d'une vague qui crée des écrans pose au propriétaire, avant la vague, le contenu de chacun | vague 4, §5.3 — deux arrêts pour trois questions P nées à l'écriture | vague 5, §5.1 : gardé, sans avoir empêché trois arrêts nés de PN12 (d) |
| A4 | Un vérificateur de plan recoupe chaque exemple tiré d'une donnée avec son fichier, et chaque promesse sur une bibliothèque avec sa source | vague 5, §5.2 — deux exemples du plan contredisaient le réel | vague 6, §5.4 (trois références et un compte corrigés au premier tour) |
| A5 | Une question P visible du joueur se pose avec ses maquettes | vague 5, §5.5 — PN12 tranchée en une réponse | vague 6, §5.2 (aucun arrêt) ; vague 8, §7 (six corrections sur maquettes) |

**D2 — ADR-108 D1 et ADR-113 sont confirmés par la mesure.** Les plans de décisions : vague 4, §5.1
(131 $ contre 389 $ en vague 3 ; spec et plans à 45 % du coût, contre 73 à 76 %) ; vague 7, §5.5 (un
plan de décisions pour du Flame, deux passes de correction) ; vague 8, §5.5 (sept tâches sans passe de
correction). Les tests sans écran : vague 5, §5.3 ; vague 7, §5.3 — la revue par tâche reste alors la
seule garde automatique de Flame, et elle a trouvé deux vrais défauts.

**D3 — Une proposition, établie deux fois, attend le propriétaire** : *une question P s'écrit pour
toutes ses options, la recommandée appliquée* — au plan (vague 7, §5.1 : Q-P2 levée en un commit) et
à la spec (vague 8, §5.1 : l'arrêt levé en un commit, sans tour). Elle n'est pas adoptée : elle
s'écrira au gabarit du prochain chantier s'il la retient.

**D4 — Quatre propositions, faites une fois, restent proposées** : aucune commande en arrière-plan ni
recherche sur le disque entier pour un vérificateur (vague 7, §5.2) ; le gabarit des skills de fin de
vague transmet aussi ce que la note de version ne doit pas dire (vague 7, §5.4) ; une question qui ne
fait qu'appliquer une règle acquise à un contenu neuf est T (vague 8, §5.2) ; un test rouge ne corrige
jamais une valeur de la spec, il remonte à l'orchestrateur (vague 8, §5.3).

**D5 — R31 n'a pas de verdict.** Le plan sans spec a été essayé une fois, en vague 6, et a tenu
(§5.1 : 30,54 $, trois tours, aucun arrêt) ; les vagues 7 et 8 ont gardé leur spec, et le verdict
reste au propriétaire.

### Preuves dans le code

Aucun code : la décision porte sur la manière de travailler.

| Élément | Emplacement |
|:---|:---|
| Les leçons et leurs amendements | §5 des comptes rendus `docs/superpowers/reports/2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md` à `docs/superpowers/reports/2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md` |
| Leur forme imposée | `docs/superpowers/reports/README.md` ; fichier d'orchestration §3.8 |
| Les gabarits qui ne les portent pas | fichier d'orchestration §4.1 à §4.7, §5 |
| Les blueprints figés jusqu'à la clôture | ADR-108 D8 |

### Conséquences

- **Le prochain chantier, s'il se livre par vagues, part d'ADR-102, 103, 108, 113 et de D1** ; D3 et
  D4 sont à trancher par le propriétaire à son ouverture, R31 aussi. Choisir ce chantier, et sa
  méthode, reste au propriétaire (`docs/ROADMAP.md`).
- **Le gel d'ADR-108 D8 est échu** : le modèle, le guide et la proposition `memory-bank-sync`
  peuvent désormais s'installer — rien ne s'installe sans décision du propriétaire.
- **Ce qui ne change pas** : le fichier d'orchestration reste le texte de ce chantier, figé, et les
  comptes rendus gardent leur forme.
