# Vérifications — plan de la partie 1, tranche 1 et P-44 lot 1

**Plan** : [`2026-11-03-p42-tranche-1-p44-lot-1-partie-1.md`](2026-11-03-p42-tranche-1-p44-lot-1-partie-1.md) · **Spec** : [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §10 partie 1 · **Vague** : 5, `0.5.7` · **Base de tests** : 1701 (03/11, `0b902e9`) · **Tâche à risque** : la Task 7, le paiement des coûts en PV et en Armure (D40) · **Autonomie** : `continu`.
Tenu par l'orchestrateur (ADR-108 D4) : les questions nées à l'écriture, puis le journal des tours.

## Les questions nées à l'écriture — toutes de classe T, confirmées par l'orchestrateur

| # | Question | Choix du rédacteur | Filtre |
|:---:|:---|:---|:---:|
| PL1 | `rune_ids_in_code_test` et l'id `lifesteal`, aussi celui du statut de Vol de vie (quatre littéraux dans `lib/`) | Le test exclut l'id par une liste nommée, avec sa raison — seule issue sans renommer une rune que D65 nomme | 1 |
| PL2 | L'écho quand la cible unique meurt à la première résolution | Les dégâts sont perdus, les effets sur soi se rejouent (« sur la même cible si elle vit » vise les effets qui la frappent) ; aucune carte de `0.5.7` n'est concernée | 6 |
| PL3 | L'infobulle Flame sans `buildContext` | La parenthèse de statut ne s'écrit pas, plutôt qu'une troisième copie du texte | 5 |
| PL4 | `statusId` dans `scaleWith` | Refusé sur toute source autre que `targetStatus` | 5 |
| PL5 | Le son `insufficientMana` de `consumeResource` | Joué à tout refus ; chemin inatteignable par `resolveCard`, qui vérifie avant | 8 |
| PL6 | Les dégâts « infligés » de *Vampirique* | Ceux qui sortent du pipeline, comme le statut de Vol de vie | 1 |
| PL7 | La galerie du tutoriel | Des entrées `ElementStatusInfo(name, desc)` traduites, construites dans `build` | 5 |
| PL8 | Où vivent les tests de Q11 | `effect_resolver_test.dart`, dans un groupe qui charge son registre | 5 |

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, Task 7 rejouée dans un clone (20 tests de `card_costs_test` verts, suite à 1730 avec les runes posées) | neuf, seul | 0 | 1 | 4 | 4 | Les neuf, par le rédacteur repris. Le moyen : l'écho « vise la même cible » sans test (un seul ennemi). Total final 1810 → **1811** (le test de D17 sur les cartes livrées) | Choix de l'orchestrateur : le garde de D17 en vrai test (+1), `termFor` déplacé en Task 2 avec son lecteur. Contesté par le rédacteur avec preuve, accepté : `signature_data.dart:60-130`, non `:59-130` |
