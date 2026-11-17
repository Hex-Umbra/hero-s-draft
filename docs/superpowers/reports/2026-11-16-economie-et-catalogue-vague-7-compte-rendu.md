# Vague 7 — `0.5.9` — les charges élémentaires (P-53) — compte rendu

**Branche** : `feat/v0.5.9-p53-charges-elementaires` · **Spec** : [P-53](../specs/2026-11-15-p53-charges-elementaires-design.md) ([vérifications](../specs/2026-11-15-p53-charges-elementaires-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-11-15-p53-charges-elementaires-partie-1.md) ([vérifications](../plans/2026-11-15-p53-charges-elementaires-partie-1-verifications.md)), [partie 2](../plans/2026-11-16-p53-charges-elementaires-partie-2.md) ([vérifications](../plans/2026-11-16-p53-charges-elementaires-partie-2-verifications.md)) · **Maquettes** : [les cinq questions P](../../presentations/2026-11-15_charges_elementaires_maquettes.pptx), [Q-P1](../../presentations/2026-11-16_charges_elementaires_q-p1_maquettes.pptx), [Q-P2](../../presentations/2026-11-16_charges_elementaires_q-p2_maquettes.pptx) · **Forme** : [README](README.md).

*Ouvert à la fin du plan de la partie 1 (§3.5), fermé à la §3.8.*

## 0. Pour le propriétaire

**À tester d'abord**, par risque (le détail est au [fichier des tests manuels](2026-11-16-economie-et-catalogue-vague-7-tests-manuels.md)) :

1. **La chaîne du Feu** (T1, T2, T13) : trois vagues l'une après l'autre, 48 / 64 / 48 lus sur les cartes ; aucune carte ne doit garder ses PV d'avant une vague, aucun ennemi tué au milieu ne doit rester affiché.
2. **Feu et Poison** (T3) : le Feu en rouge, le Poison en vert — le défaut S10 de la partie 1, corrigé par l'onde.
3. **L'ennemi gelé** (T4, T5) : la gangue naît une fois, éclate à son action, ne survit pas au gel ; dites si le serrement se voit sous le sursaut du coup (S16).
4. **La Foudre** (T6 à T8, T10, T12) : le « +N » jaune sur les trois chemins — carte, signature, héros —, ni oublié ni doublé ; le halo s'éteint en fin de phase.
5. **Le héros gelé ou porteur** (T9, T11) : gangue pâle et givre aux coins pendant son tour gelé ; l'éclair, ou le rougeoiement après le flash rouge.

**Les arbitrages que le joueur verra** : vos réponses P-a à P-e, Q-P1 (d) et Q-P2 (c) ; le délai de vague à 800 ms ; un seul « +N 🔥 » par voisin et par vague ; un éclair par porteur, quelles que soient ses tranches ; le héros porteur sous le seuil qui rougeoie ; le givre aux coins sous les cartes de la main.

**Faits sans vous** (autonomie `continu`) : les arbitrages T du §2, et deux retouches — la note de `0.5.9` ne dit pas le Gel du héros, qu'aucun ennemi ne pose encore (Q-P1 (d)) ; T23 des tests manuels pointe l'onglet « Heros » du debug.

**Risques connus** : le rendu visuel n'a aucun test automatique (D77) — vos tests M16 sont sa seule garde ; une boule de feu très en retard (moteur figé) relâcherait trop tôt la vague suivante, sans perte d'état ; le défaut antérieur S9 (un tour ennemi joué après la victoire) reste à la file.

**Rejouer l'essentiel** : `flutter test test/unit/charge_rules_test.dart test/unit/charge_symmetry_test.dart test/unit/multi_hit_test.dart` · `dart analyze` · `bash .github/scripts/verify_version.sh 0.5.9`.

## 1. La branche et ses chiffres

| Partie | Commits de code | Tests | `dart analyze` | Superpowers | Claude Code |
|:---|:---|:---|:---|:---|:---|
| 1 | 13 (`7a256deb..b155d6a2`, après la levée `b88dfd34`) | 1682 → **1766** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |
| 2 | 6 (`f0e7bb47..21050357`, après la levée `71af72ba`) | 1766 → **1772** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |

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
| Note | La note de `0.5.9` annonçait le Gel du héros | T | Puce retirée : aucun ennemi ne pose de charge en `0.5.9`, et Q-P1 (d) ne montre cette règle nulle part | 6 |

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

**Décisions de SDD, partie 2** (registre recopié avant sa suppression ; balayage préalable sans conflit, cinq tâches, deux passes de correction ; revue d'ensemble sur `71af72ba..21050357`, « prête à fusionner », 0 critique, 0 important, sans passe) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S12 | Le test 1 de Task 1 se lit « 2 Foudre posées, puis `noteHit` → `[ChargeHit(2)]` ; une de plus, puis `noteHit` → `[ChargeHit(2), ChargeHit(6)]` » : `pose` ne note aucun coup | T | Une assertion à réécrire |
| S13 | Task 3, corrigé en revue : la gangue choisit serrement (ennemi) et givre aux coins (héros) par la sorte de rupture, non par la valeur d'opacité | T | — |
| S14 | Task 4, corrigé en revue : le rougeoiement et l'éclair du héros se jouent après le flash des dégâts, et une teinte du sprite remplace vraiment la précédente (`_replaceSpriteTint`) — l'ancien retrait ne trouvait rien | T | — |
| S15 | Task 5, la vérification finale, rejouée par l'orchestrateur sans implémenteur (aucun fichier) | T | — |
| S16 | Revue d'ensemble, aux tests manuels : le serrement de la gangue (3 %) ne se voit pas sous le sursaut du coup de *Trait de Glace* (22 %), deux `ScaleEffect` imbriqués s'additionnant — M16-G1 dira s'il faut le jouer après le sursaut ; un porteur sous le seuil, voisin d'un porteur qui explose, rougeoie deux fois (debug seulement) | T | Un serrement invisible |

## 3. Les tests manuels

[26 tests](2026-11-16-economie-et-catalogue-vague-7-tests-manuels.md), dont M16 en onze points et les points S10 ; à remplir par le propriétaire.

## 4. Trouvé périmé, et pour la file

- **La fin de la phase ennemie après une victoire** (S9) : `_enemyRipostePhase` ne regarde jamais `isCombatEnded` ; garde suggérée dans `startPlayerTurn` et `endEnemyTurn`, avec un test.
- **Le chargement du registre en arrière-plan dans les tests** (S11) : un harnais de test commun qui surcharge le provider.
- **`entity_writer_test.dart`** (« une sauvegarde ratée ne laisse aucune copie partielle ») a échoué une fois en suite complète pendant la partie 1, vert seul et aux exécutions suivantes : un test de fichiers temporaires, étranger au diff, à surveiller.
- **Les rendus Flame de la partie 2** (revue d'ensemble, mineurs) : `FrostVignette` recrée quatre dégradés plein écran à chaque frame d'un tour gelé, `ChargeHalo` et `FireBurst` leur `Paint` ; la règle « 1,5 largeur de carte » de l'éclair est écrite deux fois — à mettre en cache et en commun au prochain passage.
- **Une aide de test pour les cartes de lot** : `shippedCard(id)` ne lit que `cards/<id>.json` à plat ; le test de *Nova de givre* lit son JSON de lot directement.

## 5. Les leçons

1. **Trois arrêts P, dont deux nés des plans** (Q-P1, Q-P2), chacun une session de plus. Écrire le plan pour toutes les options a rendu la levée de Q-P2 d'un seul commit, sans nouveau tour. Amendement proposé : au §4.3, un rédacteur de plan qui pose une question P l'écrit pour toutes ses options, la recommandée appliquée.
2. **Un vérificateur bloqué vingt minutes** sur une recherche `find /` laissée en arrière-plan, sans rien rendre. Amendement proposé : aux gabarits §4.2, §4.4 et de revue, « aucune commande en arrière-plan, aucune recherche sur le disque entier ; les sources de Flame sont dans le cache de `pub` ».
3. **Sans test d'écran (D77), la revue par tâche est la seule garde automatique de Flame** : elle a trouvé deux vrais défauts — un rôle lu sur une opacité, une teinte jamais retirée. Rien.
4. **La note de version annonçait une règle que le joueur ne rencontre pas.** Amendement proposé : le gabarit §4.5 transmet aussi ce que la note ne doit pas dire (les réponses P qui cachent une règle).
5. **Un plan de décisions pour du Flame tient** : quatre tâches sans code écrit d'avance, deux passes de correction en tout. Rien.

## 6. Les statistiques de la session

**Mesuré le 17/11/2026 à 09:39**, avant le commit de §3.8 — sessions : 4 (`6e0e7bc0`, `c30d4a04`, `c2298e26`, `bb0be5f8`) · arrêts : 3 (15/11, 16/11, 16/11) · durée : du 15/11 à 20:36 au 17/11 à 09:38, dont 4 h 28 de temps actif des orchestrateurs · tours de spec : 4 · tours de plan : 5 (3 + 2)
Prix lus le 17/11 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,1014 $ (BCE, 16/11) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | 1 h 52 | 2 h 10 | 2 h 14 | 26 min | 4 h 28 | **11 h 11** |
| Agents — Opus / Sonnet / Haiku | 7 / 0 / 0 | 9 / 0 / 0 | 8 / 29 / 2 | 1 / 2 / 0 | 4 / 0 / 0 | **29 / 31 / 2** |
| Appels au modèle | 538 | 521 | 593 | 149 | 373 | **2 174** |
| Jetons traités, dont hors cache | 119,76 M · 2,63 M | 109,08 M · 4,03 M | 67,17 M · 3,52 M | 37,47 M · 0,60 M | 92,64 M · 1,29 M | **426,12 M · 12,06 M** |
| Sortie (minimum) | 608 k | 656 k | 594 k | 150 k | 298 k | **2 306 k** |
| Coût API — $ / € | 48,60 / 44,13 | 54,14 / 49,16 | 29,92 / 27,17 | 12,18 / 11,06 | 34,46 / 31,29 | **179,30 / 162,80** |

*Hors cache* : l'entrée hors cache et les écritures en cache. La session `9549eeda` (préparation, avant l'ouverture de la branche) et l'agent de cette mesure ne sont pas comptés. Les maquettes des cinq questions P comptent à la spec, celles de Q-P1 et Q-P2 aux plans ; la porte d'entrée et les levées d'arrêt à l'orchestrateur.
