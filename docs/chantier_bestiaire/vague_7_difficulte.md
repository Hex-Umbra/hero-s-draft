# Vague 7 — `0.6.7` — la refonte de la difficulté

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 23/11 (B64, B69). **Cette vague n'a pas encore sa matière** : elle l'aura d'un cadrage — un brainstorm avec le propriétaire —, tenu après la vague 6, sur ses tests des tiers 1 à 3 et de leurs intentions. Cette fiche tient ce qui est déjà su : son objet, ce qui s'y réexamine, ce que l'audit a lu dans le code. Elle se complète quand le cadrage est clos.

**Poids** : à dire par le cadrage.

## Ce qu'elle livre

**La difficulté retravaillée dans son ensemble** (B64) : sa formule et sa mise à l'échelle. Elle vient après le tier 3, pour se régler sur des ennemis qui existent et qui ont été joués, et avant les tiers 4 et 5, qui se construiront sur la formule revue (B69).

## Prérequis — avant l'ouverture

1. **Les tiers 1 à 3 livrés et joués** : les notes du propriétaire sur ce qu'il a ressenti, acte par acte, avec les nouvelles intentions.
2. **Le cadrage de la difficulté**, dont les réponses deviennent des décisions B. Ce qu'il doit trancher :
   - **la cible** : à quel moment d'une run le jeu doit se jouer serré, et ce qu'un tier neuf doit changer pour le joueur. Un fait du propriétaire, le 23/11 : ses runs atteignent l'acte 20 et au-delà, mais très difficilement ;
   - **la formule** : le budget d'un combat, le prix d'un ennemi, ce qui grandit avec l'acte et avec le niveau, le nombre d'ennemis par combat ;
   - **le prix d'un effet** (B58, +6 pour tout effet) : un prix par mécanisme, ou un autre calcul ;
   - **la cadence des tiers** (B60, un tier tous les cinq actes) ;
   - **l'échelle des doses** : ce que deviennent, d'un acte à l'autre, les statuts et les charges qu'un ennemi pose ; la riposte (B71) en est la première réponse ;
   - **la table d'XP** au-delà de l'acte 15, et le revenu d'XP et d'or, qui se compte par ennemi vaincu ;
   - **les combats d'élite et de boss** : leurs multiplicateurs.
3. **Un instrument de mesure** — proposé à l'audit, **non décidé** : un tableau de ce que le tirage des combats produit, acte par acte, calculé depuis les formules du jeu. Il demande de rendre injectable le tirage aléatoire du système de rencontres. Il peut se poser plus tôt, dans la vague du socle, pour que chaque vague de tier voie ce qu'elle change.

## Ce que l'audit du 23/11 a lu dans le code

À revérifier avant de s'y appuyer. Tout est dans `lib/game/systems/encounter_system.dart`.

- **Le budget d'un combat** croît en ligne droite : `(40 + 10 × (niveau − 1) + 25 × (acte − 1))`, modulé par la puissance du héros et multiplié par 1,5 pour une élite, par 2 pour un boss.
- **Les PV et les dégâts d'un ennemi** croissent en puissance : ×1,35 et ×1,25 tous les deux actes, plus 6 % et 4 % par niveau. Le niveau d'un ennemi est celui du héros.
- **Le prix d'un ennemi** : `tier × 15 + PV / 4 + dégâts × 2 × (1 + critique)`, sur ses PV et ses dégâts mis à l'échelle. Le terme du tier, et le +6 d'un effet, ne suivent pas l'échelle.
- **Le nombre d'ennemis** : un de plus par acte en combat normal, un de plus tous les deux actes en élite, tous les cinq actes en boss ; le plateau en porte cinq, le reste attend en réserve.
- **Le tirage** est uniforme parmi les ennemis que le budget restant permet, et se rabat sur le moins cher.
- **Un boss** est un ennemi ordinaire à ×3 en PV et en dégâts.
- **La table d'XP** (`assets/data/xp_curve.json`) a quinze entrées ; au-delà, la dernière se répète.
- La simulation du chantier précédent est gelée (ADR-108) et s'arrête à l'acte 15 : aucune vague ne la relance.

## Ne pas absorber

Aucun ennemi neuf, aucun mécanisme du catalogue : les tiers 4 et 5 ont leurs vagues, qui suivent celle-ci.

## Fichiers, porte d'entrée, tâches à risque

À écrire quand le cadrage est clos. La porte d'entrée sera celle de l'orchestration §3.1, sur la vague 6 ; la branche, `feat/v0.6.7-difficulte`.
