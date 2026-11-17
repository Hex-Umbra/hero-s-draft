# Vague 7 — `0.5.9` — les charges élémentaires (P-53) — compte rendu

**Branche** : `feat/v0.5.9-p53-charges-elementaires` · **Spec** : [P-53](../specs/2026-11-15-p53-charges-elementaires-design.md) ([vérifications](../specs/2026-11-15-p53-charges-elementaires-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-11-15-p53-charges-elementaires-partie-1.md) ([vérifications](../plans/2026-11-15-p53-charges-elementaires-partie-1-verifications.md)) · **Maquettes** : [les cinq questions P](../../presentations/2026-11-15_charges_elementaires_maquettes.pptx), [Q-P1](../../presentations/2026-11-16_charges_elementaires_q-p1_maquettes.pptx) · **Forme** : [README](README.md).

*Ouvert à la fin du plan de la partie 1 (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

*S'écrit à la §3.8.*

## 1. La branche et ses chiffres

| Partie | Commits de code | Tests | `dart analyze` | Superpowers | Claude Code |
|:---|:---|:---|:---|:---|:---|
| 1 | 13 (`7a256deb..b155d6a2`, après la levée `b88dfd34`) | 1682 → **1766** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans les fichiers de vérifications de la [spec](../specs/2026-11-15-p53-charges-elementaires-design-verifications.md) et du [plan](../plans/2026-11-15-p53-charges-elementaires-partie-1-verifications.md).

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| P-a | Les noms affichés | P | Gel, Feu, Foudre ; Freeze, Burn, Shock ; états Gelé / Frozen et Chargé / Charged ; les runes gardent leurs noms (propriétaire, 15/11) | — |
| P-b | Les valeurs des dix contenus relus | P | *Embrasement* 3 Feu, *Congelant* 1 Gel par niveau, les huit autres inchangés (propriétaire, 15/11) | — |
| P-c | La forme des trois animations | P | G-a la gangue, F-a l'onde, L-b le halo — contre la recommandation L-a (propriétaire, 15/11) ; partie 2 | — |
| P-d | Ce qui protège des dégâts du Feu | P | L'Armure absorbe, ni Vulnérable, ni critique, ni Faiblesse (propriétaire, 15/11) | — |
| P-e | Une section « Charges » au menu de debug | P | Oui, onglet Combat (propriétaire, 15/11) | — |
| Q-P1 | Où le joueur lit la règle du Gel sur le héros (`heroDescription`) | P | Nulle part en `0.5.9` : aucun ennemi ne pose de charge, la ligne du héros gelé dit l'effet ; le texte reste dans le fichier du Gel (propriétaire, 16/11) | — |
| A1-A3 | Un fichier par élément sous `charges/`, l'id du statut ; `ChargeData`, un provider qui retombe sur un catalogue vide ; la validation au chargement | T | spec §1.3 | 1, 5 |
| A4-A9 | Les points restent des statuts, une seule pose ; la piste sur `EntityStats`, hors sauvegarde ; le tic épargne les charges ; la durée d'un effet de charge ni lue ni affichée ; le seuil par porteur ; deux fermetures de phase | T | spec §1.3 | 1, 4, 5, 7, 8 |
| A10-A13 | Le Feu se résout d'abord ; une vague est simultanée ; le contrôleur joue la chaîne vague par vague, Flame l'appelle ; l'ennemi gelé se lit sur l'état avant que Flame l'anime | T | spec §1.3 | 1, 5, 6 |
| A14-A19 | Le pipeline reçoit le catalogue ; arrondi à la demie supérieure ; les textes viennent du fichier ; onzième catégorie de l'éditeur ; l'exemple de l'étude à ses valeurs ; deux parties, l'animation en dernier | T | spec §1.3 | 5, 7, 8 |
| Q1 | La ligne du gel en attente déborde du panneau du héros | T | Pas de colonne de durée, libellé replié sur deux lignes ; au-delà de la réserve de 120 px, la liste défile, barre visible | 6, 7 |
| Q2 | Transmettre les coups un à un à Flame | T | Par l'état : chaque coup note son bonus sur le défenseur (`EntityStats.chargeHits`, hors sauvegarde), testé en tête du plan de la partie 2, avant toute animation | 5 |
| A12 · §4.10 | Le compte rendu de vague et le délai de vague, à la partie 2 | T | Le compte rendu perd ses dégâts nominaux, les dégâts se lisent sur les PV (P-d) ; 800 ms par vague (0,6 s + 0,2 s, §5.2) — spec amendée | 8, 6 |
| Q-P2 | Ce qui s'affiche à chaque coup sous le seuil de Foudre | P | (c) : chaque coup affiche son « +N », sous le seuil comme chargé, dans le même jaune `#FFEA00` ; le halo dit qui est chargé (propriétaire, 17/11) | — |

**Décisions de SDD, partie 1** (registre recopié avant sa suppression ; balayage préalable, douze tâches, une passe de correction en Task 3 ; revue d'ensemble sur `b88dfd34..1979ba1f`, « prête avec corrections », une passe) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S0 | Balayage préalable du plan (22 paires de tâches, 12 tâches, totaux concordants, aucune contradiction avec la spec) : dix points tranchés avant la Task 1 — S1, S2, S4 ci-dessous ; les sept autres sans coût (attribution des commits, `game_screen.dart` dans la Task 5, un `!` sur un champ que la validation garantit, les lignes du plan relocalisées par nom, un ennemi non boss au test du debug, deux appels de `createStatus` laissés, une aide de test partagée) | T | — |
| S1 | L'arrondi `(v × pct + 50) ~/ 100` a une seule définition, la fonction `halfUp` de `charge_data.dart` ; le `ChargeRules.halfUp` du plan n'est pas créé | T | Un renommage |
| S2 | `ChargeData.belowValue` exposé dès Task 1 (les jetons, puis le tutoriel le lisent) | T | Un accesseur à déplacer |
| S3 | `ChargeLine.value` ne porte la valeur de rupture qu'une fois la charge rompue, 0 sous le seuil (spec §5.1 : « la valeur de la rupture en vigueur ») ; le bonus sous le seuil se lit par `ChargeRules.hitBonus` | T | Un lecteur de partie 2 lirait la mauvaise source |
| S4 | Le test 3 de symétrie (« les dégâts de ses statuts ne sont pas réduits ») réécrit pour asserter : piste du héros mise en `brokenActive`, Feu résolu sur un ennemi, 12 ; la garantie reste structurelle | T | Un test qui documente plus qu'il ne protège |
| S5 | Le déclin à travers les processeurs asserté dans deux tests nommés de Task 6, sans test neuf (2 → 1 Gel, ennemi et héros) | T | — |
| S6 | Les dégâts du compte rendu de vague sont nominaux (avant Armure) ; Flame n'en tire aucun chiffre affiché | T | Un chiffre faux en partie 2 |
| S7 | Le test A14 de l'intention pose le Gel par `ChargeRules.pose` une fois le barème du Gel retiré ; le titre du test du tutoriel dit Feu | T | — |
| S8 | Revue d'ensemble, corrigé : la pose de *Nova de givre* sur tous les ennemis testée (boss et non-boss, 1765 → 1766) ; la clé d'un message d'erreur de validation ; une virgule déplacée dans les deux ARB | T | — |
| S9 | **Un défaut antérieur à la vague, porté à la file** : la fin de la phase ennemie se joue après une victoire constatée par les statuts (en `0.5.9` : *Bénédiction* soigne d'un tour de trop) ; **bloquant pour le premier contenu qui pose du Feu ou du Poison sur le héros** | T | Un soin de trop, déjà présent en `0.5.8` |
| S10 | Aux tests manuels : les dégâts du Feu affichés en vert sur un ennemi empoisonné (à régler avec l'animation F-a) ; l'éditeur de contenu qui déborde à 600 px de haut avec onze onglets | T | — |
| S11 | À la partie 2 : les champs du compte rendu de vague et `ChargeTrack.ruptures`, écrits sans lecteur dans `lib/`, se lisent ou se retirent ; à la file : les tests sans surcharge qui lancent le chargement du registre en arrière-plan | T | Du code sans lecteur à la fin de la vague |

## 3. Les tests manuels

*S'écrit à la §3.8.*

## 4. Trouvé périmé, et pour la file

- **La fin de la phase ennemie après une victoire** (S9) : `_enemyRipostePhase` ne regarde jamais `isCombatEnded` ; garde suggérée dans `startPlayerTurn` et `endEnemyTurn`, avec un test.
- **Le chargement du registre en arrière-plan dans les tests** (S11) : un harnais de test commun qui surcharge le provider.
- **`entity_writer_test.dart`** (« une sauvegarde ratée ne laisse aucune copie partielle ») a échoué une fois en suite complète pendant la partie 1, vert seul et aux exécutions suivantes : un test de fichiers temporaires, étranger au diff, à surveiller.
- **Une aide de test pour les cartes de lot** : `shippedCard(id)` ne lit que `cards/<id>.json` à plat ; le test de *Nova de givre* lit son JSON de lot directement.

## 5. Les leçons

*S'écrit à la §3.8.*

## 6. Les statistiques de la session

*Mesurées à la §3.8.*
