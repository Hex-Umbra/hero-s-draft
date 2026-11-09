# Vérifications — plan de la partie 2, tranche 1 et P-44 lot 1

**Plan** : [`2026-11-03-p42-tranche-1-p44-lot-1-partie-2.md`](2026-11-03-p42-tranche-1-p44-lot-1-partie-2.md) · **Spec** : [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §10 partie 2 · **Vague** : 5, `0.5.7` · **Base de tests** : 1811 (03/11, `1b2008e`) · **Tâche à risque** : la Task 6, le masquage des passifs sans lot (O5) · **Autonomie** : `continu`.
Tenu par l'orchestrateur (ADR-108 D4) : les questions nées à l'écriture, puis le journal des tours.

## Les questions nées à l'écriture — toutes de classe T, confirmées par l'orchestrateur

| # | Question | Choix du rédacteur | Filtre |
|:---:|:---|:---|:---:|
| PM1 | Le médaillon rouge de la ressource qui manque | Pour les trois ressources, mana compris — la lettre de spec §4.1 ; sur la face Flame seule après le tour 1 (`isShort` retiré, faute de lecteur) | 6 |
| PM2 | Où s'écrit la Puissance par coup | Dans l'infobulle Flame seulement : `UiCard` ne connaît pas le héros | 5 |
| PM3 | Un multi-coups `allEnemies` | La clé `cardDescDamageHits`, sans « à tous les ennemis » ; aucune carte de `0.5.7` n'en porte | 7 |
| PM4 | Le `{status}` de `cardScaleTargetStatus` | Le nom de `createStatus` ; aucune carte de `0.5.7` ne lit cette source, à revoir en tranche 3 | 7 |
| PM5 | Animations des 17 cartes ; empilement des médaillons | Le vocabulaire des neutres ; PV (goutte) et Armure (écu) sous le mana | 6, 8 |
| PM6 | Un groupe vide du draft ; une carte hors quota au tutoriel | Aucune section ; un refus sans notification, comme au-delà de 5 aujourd'hui | 8 |
| PM7 | Emplacements et couleur | `StarterDraft` sous `lib/game/systems/`, `CardRuleTexts` sous `lib/game/services/` ; la pastille d'un passif dans l'éditeur prend la couleur de sa classe | 5 |

**Laissé hors de la partie 2** : `ProportionalStatus`, importé par `lib/models/enemy_instance.dart` depuis `lib/game/` (aucune tâche de la partie 2 ne touche ces fichiers) — au Review Focus de la partie 3 ou à la file.

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, Task 6 rejouée dans un clone (+7, aucun rouge venu d'elle ; matrice de forge des 17 cartes sans écart) | neuf, seul | 0 | 2 | 7 | 4 | Les treize, par le rédacteur repris ; aucun contesté. Les deux moyens : `document_form_test` qui rougit sous le gabarit de passif, le trou de `takeDamage` sur plusieurs coups. Total final 1914 → **1915** | Choix de l'orchestrateur : un vrai test pour l'Armure sur plusieurs coups (*Rafale d'étincelles*), `isShort` retiré faute de lecteur, la recette de classe de l'éditeur sans carte (commentaires réécrits). Ajouté au passage par l'orchestrateur : le commentaire de `document_form_test.dart:175`, que le rédacteur signalait |
| 2 | différentiel | neuf, seul | 0 | 1 | 2 | 5 | Les huit, par le rédacteur repris ; aucun contesté. Le moyen : le test de la leçon du tutoriel ne mordait pas — un deck sans Compétence d'Armure valide faisait revenir le moteur aux fixtures, et un critère oublié (*Sang versé* sans payer ses PV) restait vert ; les deux decks réécrits pour que chaque critère oublié fasse entrer sa carte en main. Total inchangé, 1915 | La ligne PM1 de ce fichier alignée par l'orchestrateur |
| 3 | différentiel | neuf, seul | 0 | 0 | 1 | 3 | **Prêt.** Les huit corrections du tour 2 tiennent ; chaque critère du test de la leçon mord, prouvé contre `tutorial_engine.dart`. Un mineur (l'échec du Step 2 de la Task 8 est de compilation) et trois rédactions (*Mur de fer*, `card_data.dart:306-307`, le test de `:290` cité par son titre), corrigés au passage par l'orchestrateur | — |
