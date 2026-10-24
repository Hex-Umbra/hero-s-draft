# Vérifications — plan E4 partie 1

**Plan** : [`2026-10-15-p43-e4-signatures-partie-1.md`](2026-10-15-p43-e4-signatures-partie-1.md) · **Spec** : [`2026-10-15-p43-e4-signatures-design.md`](../specs/2026-10-15-p43-e4-signatures-design.md), §11 partie 1 · **Vague** : 4, `0.5.6`, branche `feat/v0.5.6-p43-e4-signatures` · **Autonomie** : `continu` · **Base de tests** : 1625 · **Tâches à risque** : Task 3 (sauvegarde), Task 4 (combat).
Tenu par l'orchestrateur (ADR-108 D4) : les options que le plan a écartées, puis le journal des tours.

## Les options écartées

Questions de classe T nées à l'écriture du plan, tranchées par le rédacteur, confirmées par l'orchestrateur.

| # | Question | Options écartées, et le filtre qui les écarte | Retenu |
|:---:|:---|:---|:---|
| PL1 | Un id de `skills` absent du registre à la reprise | L'ignorer sans rien dire (le lien de classe refuse déjà ce cas ailleurs, filtre 5) · un `MissingSaveItem` (la signature n'est pas dans la sauvegarde, A8 ; filtre 5) | Fail-fast : `getSignatures` lève, `SaveService.load` efface la sauvegarde |
| PL2 | Une signature neuve sans propriétaire dans l'éditeur | Laisser `_construct` lever (message opaque) · retirer la pastille « Neutre » et présélectionner une classe (élargit, filtre 7) | Faute d'identité nommée `heroClass` |
| PL3 | Prose de `SignatureData` | `''` par défaut comme `CardData` (filtre 5) | Les quatre clés exigées, non vides |
| PL4 | Vocabulaire du type d'une signature | Recopier la liste dans le descripteur (filtre 5, un fait à un endroit) | `SignatureData.playableTypes` |
| PL5 | Répertoire du descripteur de signature | `directory: 'classes'` · une liste à plat `assets/data/skills/` que rien ne charge (filtre 5) | `directory: 'skills'`, catalogue `classes/*/skills/` |
| PL6 | « La signature est dans la run » | Comparer les instances (une run rechargée les reconstruit ; filtre 1, A8) | Comparer par id |
| PL7 | Nom dans la recette de classe | Garder `signatureCards` (filtre 1, D49 : « signature ») | `ClassRecipe.signatures` |
| PL8 | Régression `smite` du tutoriel (`tutorial_engine_test:603-630`) | Retirer le test (la garde perd son test, filtre 5) · retirer la garde (filtre 7) | Reformulé sur une attaque à Armure synthétique |
| PL9 | Moment d'écrire `CLAUDE.md:89` et `README.md:93` | Avec le déplacement : phrase fausse de Task 2 à Task 7 (filtre 5) | En Task 7 |
| PL10 | Découpage de l'éditeur | Tout l'éditeur dans Task 2 (filtre 8) | Une ligne en Task 2, la neuvième catégorie en Task 5 |

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, rejeu de T3 et T4 dans un clone | neuf, seul | 0 | 2 | 5 | 0 | Rejeu : `dart analyze` propre, 1644 tests verts (1661 − 17 tests de Task 1 non rejoués), `combat_signature_test` 16/16 ; trois mutations rougissent les tests (id absent filtré, recharge `cooldown − 1`, reliques retirées de la suite commune). Les deux moyens — le test de régression `smite` du tutoriel rouge (deck sans Compétence à Armure, repli sur les fixtures) ; `entity_validator_test.dart:495-516` rouge sous PL2 — et les cinq mineurs, par le rédacteur repris | **Tranché par l'orchestrateur, mineur n° 7** (T, filtre 5) : `SignatureData.getDescription`, sans lecteur en partie 1, est reporté à la partie 2 ; écarté : le faire lire par un seul test (du code sans lecteur dans `lib/`) |
| 2 | différentiel | neuf, seul | 0 | 1 | 1 | 2 | Les sept corrections du tour 1 jugées justes ; la régression `smite` rejouée dans le clone, verte, et rouge sous deux mutations. Le moyen naît de la correction 6 : une Compétence construite par `fromJson` sans `target` retombe sur `singleEnemy` et le test neuf de `combat_controller_test` rougirait. Plus `content_editor_screen_test.dart:1063-1100` mal rangé (mineur) et deux rédactions — par le rédacteur repris | — |
| 3 | différentiel | neuf, seul | 0 | 0 | 1 | 1 | **Prêt.** Les quatre corrections du tour 2 tiennent ; la correction 1 rejouée dans le clone (63 tests verts) et rouge sous mutation ; la correction 4 simulée (`dart analyze` propre). Le mineur (commentaires `class_recipe_test.dart:221-223`) et la rédaction (`content_editor_screen.dart:793-795`) corrigés au passage par l'orchestrateur | — |
