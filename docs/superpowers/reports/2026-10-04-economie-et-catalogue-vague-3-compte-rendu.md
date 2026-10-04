# Vague 3 — `0.5.5` — E3, trouvaille et progression — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.3.
**Branche** : `feat/v0.5.5-p43-e3-trouvaille`, ouverte le 03/10/2026 depuis `main` à `bca35c5` (fusion de la vague 2).
**Ouvert le** : 04/10/2026, à la fin du plan de la partie 1 (§3.5). Complété à la fin de la vague (§3.8).
**État** : **livrée sur la branche** le 04/10/2026 — en attente du test, de la PR, de la fusion et du tag du propriétaire.

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (03/10) | `main` propre et à jour à `bca35c5` (fusion de la vague 2) ; `v0.5.4` posé sur `main`, release publiée ; trois porteurs de version à `0.5.4` ; `dart analyze` propre ; **1480 tests** — la base de la vague (`9282513`) |
| Trois arrêts et leurs levées | Spec non convergée au troisième tour (`0a4eaa0`), au quatrième (`cf61ff8`), au cinquième (`84ff409`) ; chaque arrêt levé par le propriétaire le 03/10, reprise sans `stash` (arbre propre, `dart analyze` propre, 1480 tests verts) |
| Spec E3 | Convergée au sixième tour, `2c1d8f4` |
| E3, partie 1 | Plan `7a4f0d7` ; sept commits de code `3d58c2f`..`83cf7c7` et un correctif de la revue d'ensemble `9b0e2e5` ; **1535 tests** (+55), `dart analyze` propre |
| E3, partie 2 | Plan `a7e0635` ; dix commits de code `d6924f7`..`7e29709`, quatre commits du script de simulation `ca0ba2f`..`d8b2aef` et un correctif de la revue d'ensemble `8fc7da5` ; **1625 tests** (+90), `dart analyze` propre |
| Simulation (3.6) | Quatre mesures complètes, une par commit du script ; le réalignement au diff vide ; la référence recommitée sur la sortie de `d8b2aef` (`11410f3`) — §4 |
| Note de version (3.7) | « Le Temps des Trouvailles », `0.5.5` (`b6abcb5`) ; les trois porteurs de version concordent (`verify_version.sh 0.5.5`), le site n'écrit plus `0.5.4`, `node --test` 20 verts, `test_scripts.sh` 57 verts |
| Mémoire (3.7) | `memory-bank-sync` (`80a040b`) : ADR-107 « trouvaille et progression », qui amende ADR-078 D3 et complète huit ADR ; une trentaine de fiches `_rules` et `_patterns` ; la clôture de la vague 2 notée |
| Fin de vague | **1625 tests**, tous verts, sur une base de 1480 ; `dart analyze` propre ; la branche compte 36 commits ; rien de poussé |

---

## 2. La table des arbitrages

Chaque question tranchée, ses options, le filtre de l'arbre (orchestration §5) qui a départagé, et le choix. Le propriétaire les lit au moment de son test ; un arbitrage qu'il renverse se corrige sur la branche avant la fusion (§3.10).

### 2.1. Spec E3 — [`2026-10-03-p43-e3-trouvaille-et-progression-design.md`](../specs/2026-10-03-p43-e3-trouvaille-et-progression-design.md), §1.2

Les vingt-huit arbitrages de la rédaction, puis ceux des cinq corrections et des trois levées, tels que la spec les consigne — le détail de chacun, ses options écartées et ses motifs, est à sa place dans la spec, et les renvois « § » des tableaux ci-dessous sont ceux de la spec.

**La boucle de vérification de la spec** : six tours. Les quatre premiers chacun par un panel neuf — trois vérificateurs, un par angle, puis un consolidateur qui rend une seule table ; les deux derniers par un vérificateur neuf, seul, centré sur les corrections du tour précédent.

| Tour | Constats | Suite |
|:---|:---|:---|
| 1 | 6 moyens, 13 mineurs, 3 de rédaction | Corrigés par le rédacteur, repris ; A8 à A28 confirmés, A1 et A7 reconsignés ; C1 |
| 2 | 2 moyens (aucun test ne reliait les reliques A et C à la trouvaille ; `loadDocument` sans `cache: false`), 10 mineurs, 3 de rédaction | Corrigés, avec une passe ciblée sur les liaisons non testées ; C2 |
| 3 | **3 moyens** (trois trous de test : la transition E3 → E4 lisait la rareté de l'instance, toujours `common` ; le bonus de *Transcendance* sans lecteur testé au feu et au *Rémouleur* ; deux lecteurs d'écran sans test ni commande) | **Vague arrêtée** (§3.3, §6) ; arrêt levé par le propriétaire, treize constats corrigés par un correcteur neuf ; C3 |
| 4 | **2 moyens** (une barrière de contrôle qui se contredisait ; un test de catalogue resté rouge en partie 2), 9 mineurs, 1 de rédaction | **Vague arrêtée de nouveau** ; levée par le propriétaire, douze constats corrigés ; C4 |
| 5 | **1 moyen** (`EventController.isChoiceSelectable`, que la correction créait, seul à fournir l'or à la condition des choix d'événement, sans test), 4 mineurs, 2 de rédaction | **Vague arrêtée une troisième fois** ; levée par le propriétaire le 03/10 dans le prompt de cette session, sept constats corrigés par un correcteur neuf ; C5.1 |
| 6 | 0 bloquant, 0 moyen, 2 mineurs, 2 de rédaction | Corrigés au passage par l'orchestrateur, sans nouveau tour ; **prête** |

**Au tour 6, les choix de l'orchestrateur** : pour le n° 1 (la première commande de contrôle n'est vide qu'à la fin de la vague), la seconde forme que proposait le vérificateur — la partie 1 reçoit ses deux commandes propres, vides à sa fin (§8 de la spec), parce que le plan de la partie 1 en avait besoin comme porte de fin de partie ; les trois autres, tels que le vérificateur les proposait. **À la relecture de la correction du tour 5**, il a confirmé C5.1 et le fait que la re-mesure avait ajouté au n° 2 (la relique du boss « relique », tirée sur ses propres poids, consignée hors du lot avec l'écart de « Butin de Reliques »).

#### Les vingt-huit arbitrages de la rédaction — récapitulatif

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Où vivent les tables (Q5) | `cardDrops` : `GameConstants` · document plat · nœud ; XP : constante · document plat | `cardDrops` : 7 écarte le nœud, la proposition de Q5, 5 neutre, 8 tranche ; XP : 1 | `GameConstants.cardDrops` ; `assets/data/xp_curve.json` |
| A2 | Échange de relique (D63, Q15) | D63 · relique choisie · or et PV · PV à toute santé | 2 puis 7 | D63 tel qu'écrit — pas de second temps |
| A3 | Relique de D42(a) | +1 par exemplaire · +2 · non cumulable | 2 puis 7 | +1 par exemplaire — pas de second temps |
| A4 | Événement de D42(b) | +1 contre 10 % PV max · contre or · gratuit | 2 puis 7 | +1 niveau contre 10 % des PV max — pas de second temps |
| A5 | Boss « XP » sans rune affûtable | rien et un message · une carte · or ou XP · boss non proposé | 1 ; 2 ; 6 | Rien ne monte ; `restCampSharpenNone` |
| A6 | D25, la « pioche infinie » | migrer · attendre la reproduction | 1 | Non reproduit (15 920 contrôles) ; `maxHandSize` migre ; ADR-078 D3 amendé ; un test par chemin |
| A7 | Découpage | une partie · les deux parties de la fiche · les deux parties complétées | l'orchestration (§1, §3.4) écarte une partie ; 5 | Deux parties : la boucle, puis les sources ; ce que lit la seule partie 2 y vient (§10) |
| A8 | Palier d'XP | stocké au niveau · stocké et recalculé à l'acte · dérivé | 2 puis 5 | Dérivé de l'acte ; `EntityStats.xpToNextLevel` supprimé |
| A9 | Couture de la courbe | registre global · `Provider` · paramètre | 5 | `xpCurveProvider` |
| A10 | Carte trouvée, à l'écran | notification · écran de révélation · rien | 6 puis 7 | Une notification par carte, `rewardCardFound` |
| A11 | `maxHandSize` | la stat · + accumulateur · + relique | 3 ; 5 | La stat seule ; `GameConstants.startingMaxHandSize` ; un champ de debug |
| A12 | Σ `fusionRank` | `DeckState` · en ligne · liste passée | 5 | `DeckState.fusionRankSum` ; `deckFusionRanks` |
| A13 | Affûtage sans or | `DeckNotifier` · `GoldManager(free)` · trois copies | 5 | `DeckNotifier.raiseRuneLevel`, que `GoldManager` appelle |
| A14 | Tirage du boss « XP » | paires (carte, rune) · carte puis rune | 2 | Paires sous le plafond effectif, séquentiel |
| A15 | Mythique D42(c) | type · instance ; à leur plafond · toute plafonnée ; condition · inactive | 2 ; 2 ; 5 | Un type pour la run ; candidates à leur plafond, sauf binaires, le joueur choisit ; `requires: raisableRune` |
| A16 | Runes binaires | champ `binary` · liste dans la mythique · déduit des deltas | 1 puis 4 | `binary: true` sur `enduring` et `cheap` |
| A17 | Bonus de plafond | paramètre `capBonus` · lecture au fond · catalogue de run | 1 puis 5 | `capBonus` optionnel, à défaut neutre, sur `boundLevel`, `ForgeRuneRules` et `mergeCards` |
| A18 | `nameAt` | niveau écrit au-delà de 1 · inchangé | 6 | Le niveau s'écrit dès qu'il dépasse 1 |
| A19 | Mécanique des événements | actions composables · actions dédiées · écrans | 5 puis 4 | `trade_relic`, `heal_percent`, `lose_hp_percent`, `sharpen_rune`, `requiresHpBelowPercent` |
| A20 | Relique visée | tirée à l'ouverture · au choix | 6 | Tirée à l'ouverture, nommée sur les badges ; sans elle, « Aucune relique à céder », choix inactifs |
| A21 | Rune de l'événement d'affûtage | choisie · tirée | 2 puis 6 | Le joueur choisit, sans or ; annuler n'engage rien |
| A22 | Retour après un choix d'événement | résout le nœud · drapeau · tel quel | 3 puis 5 | Le retour résout le nœud, comme au feu et au Puits |
| A23 | Plancher de *Flux* | `withMastery` · stratégie ; textes effectifs · inchangés | 1 ; 6 | `withMastery` ; `{amount}` effectif ; plancher codé supprimé |
| A24 | Seuil de *Bénédiction* | lu en donnée, sans effet sous 1 · refusé au chargement | 5 | Lu en donnée ; test de catalogue |
| A25 | Infobulle du boss « XP » | titre et description justes · inchangée | 6 | `legendBossXp` et `tooltipBossXpDesc` |
| A26 | Prose XP du tutoriel | placeholders · chiffres | 5 | `{xpAct1}`, `{xpAct2}` |
| A27 | Courbe dans le registre | requise · optionnelle | 5 | Optionnelle, comme `levelUpRewards` ; sans elle, tout lecteur du palier lève ; le tutoriel lit `data.xpCurve!` |
| A28 | Relances du second temps | trois · deux | 1 (D73) | Trois : B, puis D29, puis la table d'XP |

#### Tranchés par l'orchestrateur — questions apparues à la correction du premier tour

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C1.1 | Le discriminant de `RewardState.sharpenedRunes` | liste nullable · booléen `isXpBossReward` à côté | 5 — un seul champ porte les deux faits | Nullable : `null` hors d'un boss « XP », vide pour un boss « XP » sans rune affûtable | §3.8, §4.6 |
| C1.2 | La Maîtrise effective dans les textes | requise dans `getChoiceDescription` seul · dans `getChoiceDescription` et `LevelUpRewardData.describe` | 5 — l'analyseur garde toute la chaîne | `currentMastery` requis dans les deux | §3.8, §4.11, §8 |
| C1.3 | `binary` dans `toJson` | toujours écrit · écrit seulement à vrai | 5 — le précédent de `requiresExhaust` | Toujours écrit | §3.8, §8 |
| C1.4 | Le filtre qui tranche A7 | 8 · 5 | — | 5 : sous l'autre découpage, un plan pourrait poser en partie 1 du code que seule la partie 2 lit | A7 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du deuxième tour

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C2.1 | La commande de contrôle du renommage | `playerCardsCount` seul · élargie | 5 — elle garde le renommage sans test | Élargie *(sa forme est le constat 4 du tour 3, puis le n° 1 du tour 4, §13)* | §8 |
| C2.2 | Le recalage des commentaires du script | tous les renvois · les six renvois mesurés | 7 | Les six renvois mesurés *(dix depuis le n° 4 du tour 4, §13)* | §9 |
| C2.3 | La clause de transition E3 → E4 | par `handleVictory` · par une fonction extraite | 8 | Par `handleVictory`, sur le registre réel | §4.13, §8 |
| C2.4 | Le défaut de `hasRaisableRune` dans `isAvailableWith` | faux · requis | 8, et l'accord avec `generateChoices` | Faux par défaut ; les appels à un argument compilent | §3.8 |
| C2.5 | Les deux lecteurs de `GameScreen`, qu'aucun test ne monte | commandes de contrôle · fonction pure extraite · test de widget de `GameScreen` | 7 — le lot ne prend pas en charge les tests de `GameScreen` —, puis 8 | Des commandes de contrôle | §8 |
| C2.6 | `StatsDialog`, sans aucun test | un test de widget neuf · le seul cas unitaire de `describeMastery` | 6 — le joueur pourrait lire « -9 » au lieu de « -1 » | Un test de widget neuf | §8 |

#### Tranchés par le propriétaire — la levée de l'arrêt (03/10)

Ce sont les recommandations que l'orchestrateur avait consignées à l'arrêt du troisième tour, acceptées par le
propriétaire quand il a levé l'arrêt (§13).

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| n° 1 | La forme du test qui garde l'absence de signature dans la trouvaille | la rareté de l'instance trouvée · la donnée de la carte trouvée · la donnée de la carte, et en plus, pour la transition E3 → E4, aucun id de signature | — : l'instance est construite `common` (§4.1), une assertion sur `card.rarity` ne garderait rien | Les deux formes ensemble : `card.data.rarity` jamais `unique` et `card.data.heroClass` jamais une autre classe, dans les deux tests ; en plus, dans la transition, aucun `card.data.id` parmi les six signatures du registre (C3.1) ; « toutes communes », sur `card.rarity`, reste | §4.1, §8 |
| n° 5 | Le badge `trade_relic` sans relique visée | pas de badge · un badge qui dit qu'il n'y a rien à céder | 6 — le joueur lit pourquoi le choix est inactif | `eventNoRelicToGive`, « Aucune relique à céder » · "No relic to give up" ; les choix d'échange restent inactifs | A20, §4.9, §5.1, §8, §10 |
| n° 7 | La parenthèse « (Trèfle / Miroir) » de la fiche des probabilités | remplie depuis les mythiques en donnée · retirée · consignée hors d'E3 | 5 ne départage pas (la retirer supprime aussi le doublon) ; 6 retient la forme qui dit au joueur quelles options sont mythiques | Remplie depuis `LevelUpRewardData.inPool(rewards, RewardPool.mythic)`, par une clé ARB neuve à placeholder, `luckLevelRewardSubtitle` (`{mythicNames}`), en partie 2 (C3.2) | §3.8, §5.1, §8, §10 |
| n° 8 | L'infobulle d'élite, `tooltipEliteDesc`, qui ne dit que la relique | réécrite en partie 1 · laissée telle quelle, consignée en §5.4 | 6 — la carte du monde dit de l'élite ce qu'en dit le tutoriel | Réécrite en partie 1 : « Un combat bien plus rude : une relique garantie, et une carte — parfois deux. » · "A much tougher fight: a guaranteed relic, and a card — sometimes two." | §5.1, §10 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du troisième tour

Tranchées par l'arbre de décision (orchestration §5) à la correction ; l'orchestrateur les relit et peut les renverser.

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C3.1 | D'où le test de la transition E3 → E4 lit les six signatures | les `skills` des classes du registre · les cartes `unique` du registre · une liste écrite dans le test | 4 écarte la liste écrite, un cas qui ne suit pas le registre ; 5 retient les `skills` : une signature est ce que la classe déclare et ce que son dossier porte (`referential_integrity_test.dart:211-229`) — les cartes `unique` relisent la rareté, l'entrée même du prédicat que la clause garde, et répéteraient sa première forme | `registry.heroes.expand((h) => h.skills)` (`HeroData.skills`, `hero_data.dart:44`), dont le test vérifie d'abord qu'il compte six ids | §8 |
| C3.2 | Qui compose les noms des mythiques de la fiche des probabilités | `build` lui-même : la lecture de `inPool`, les noms dans la locale, joints par « / » · une fonction pure de la couche UI, testée seule, que `build` appelle | 1 à 7 ne départagent pas — la lecture reste dans la couche UI pour les deux, et le joueur lit la même parenthèse ; 8 retient la première : aucune fonction neuve, et le test de widget, qu'exige de toute façon un lecteur qu'aucun test n'ouvre (le précédent de C2.6), garde la lecture et l'affichage ensemble | Dans `build` ; un test de widget neuf, `probabilities_dialog_test.dart` *(créé dès la partie 1 depuis le second arrêt, C4.1)* | §5.1, §8 |

#### Tranchés par le propriétaire — la levée du second arrêt (03/10)

Ce sont les recommandations que l'orchestrateur avait consignées au §13 à l'arrêt du quatrième tour, acceptées par le
propriétaire quand il a levé le second arrêt. Une ligne pour chaque constat dont la correction avait plusieurs formes ;
les n° 2, 5, 6, 7, 11 et 12 sont corrigés tels que le consolidateur les proposait (§13).

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| n° 1 | La commande de contrôle sur `cardsCount`, que contredit l'assertion d'absence du test du journal | `-e cardsCount` sorti dans une commande à part, sur `lib` seul · la commande inchangée, l'assertion d'absence dite comme sa seule ligne attendue | 8 — l'assertion du test reste celle que §8 prescrit | La première : `git grep -n -e cardsCount -- lib`, résultat vide ; `-e playerCardsCount` reste sur `lib test` | §8 |
| n° 3 | Les commentaires qu'E3 rend faux | la liste complétée, chaque ligne dans sa partie · une règle générale · les deux | 4 — la règle plutôt que le cas ; la liste guide le plan | Les deux : la règle — tout commentaire ou documentation que le lot rend faux est réécrit dans la partie qui le rend faux —, puis les lignes du constat comme un minimum, chacune dans sa partie (C4.6) | §8, « Et les commentaires » ; §10 |
| n° 4 | Les commentaires et les libellés du script qui disent « actuel » ce qu'E3 change | commentaires et libellés au premier temps · les commentaires au premier temps, les libellés à la relance 3 du second | 1 — D73 : le premier temps garde le diff vide ; un libellé imprimé qui change est un écart | La seconde : les quatre commentaires rafraîchis au premier temps, diff vide ; les trois libellés renommés « d’avant E3 » à la relance 3, l'écart de libellé dit d'avance et expliqué au compte rendu | §9 |
| n° 8 | La section « Draft standard de récompenses » de la fiche des probabilités | consignée hors du lot, en §5.4 · son sous-titre réécrit en partie 1 · retirée en partie 1 | 6 passe avant 7 — consignée, elle laisse lire, à côté d'une carte toujours commune (D1), cinq chances de rareté qu'aucun mécanisme ne tire ; réécrire son seul sous-titre laisse ces lignes sous une phrase qui les dément | Retirée en partie 1 ; `calculateDraftProbabilities` perd sa branche `isLevelReward: false` *(puis disparaît avec son dernier lecteur, C4.7)* ; un test de widget garde l'absence de la section (C4.1 à C4.3) | §5.1, §5.4, §8, §10, §11 |
| n° 9 | Les accumulateurs du relais `RunController.applyRunRuleModifier` | aucun, seul `PlayerStatsManager.applyRunRuleModifier` les reçoit · les trois, avec un test qui passe par le relais | 5 — pas de code sans lecteur | Aucun : le relais garde son seul `cardsPerTurnAcc` | §3.8, §4.2 |
| n° 10 | Ce que reçoit `EventChoice.isSelectable` | des faits calculés, `hasTradedRelic` et `hasSharpenableRune` · de quoi les calculer, `ForgeRuneRules` appelé depuis le modèle | 5 — les couches de `CLAUDE.md` : `lib/models/` n'importe rien de `lib/game/` | Des faits calculés hors du modèle, avec le bonus de plafond de la run, `RunState.runeCapBonus` (A17) ; qui les calcule, et sous quelle forme : C4.4, C4.5 | §3.8, §4.8, §4.9, §8, §10 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du quatrième tour

Tranchées par l'arbre de décision (orchestration §5) à la correction ; l'orchestrateur les relit et peut les renverser.
Il a confirmé C4.1 à C4.6 telles qu'elles sont écrites, et tranché lui-même C4.7 à sa relecture. Aucune ne se tranche
qu'en amendant une décision acquise, ni en changeant une valeur mesurée.

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C4.1 | Où vit le test qui garde l'absence de la section retirée, quand C3.2 créait `probabilities_dialog_test.dart` en partie 2 | un cas de `probabilities_dialog_test.dart`, créé en partie 1, que la partie 2 complète · un cas de `map_screen_test.dart`, qui ouvrirait la fiche par son bouton (`map_toolbar.dart:192`), et le fichier neuf en partie 2 | 1 à 7 ne départagent pas ; 8 retient la première : un fichier et un montage pour la fiche, et l'ouverture par le bouton n'ajoute rien à ce que le cas garde | Le fichier naît en partie 1 avec le cas de l'absence ; la partie 2 y ajoute celui de la parenthèse ; le choix de C3.2 ne change pas | §8, §10 |
| C4.2 | Le montage du fichier, d'une partie à l'autre | en partie 1, un conteneur qui ne porte que la run, puis, en partie 2, le chargeur surchargé et résolu pour tous ses cas · le chargeur surchargé dès la partie 1 | 5 — un chargeur surchargé que rien ne lit en partie 1 serait du code sans lecteur entre les deux parties (`CLAUDE.md`, « No dead code » ; l'invariant de §10) | La première : la fiche ne lit que `runProvider` en partie 1 (`probabilities_dialog.dart:99`) ; la partie 2, qui lui fait lire le chargeur, le surcharge et le résout avant le premier `pump`, pour tous ses cas — sans quoi les cas de la partie 1 lanceraient le vrai chargeur (« Le piège du montage ») | §8 |
| C4.3 | La section retirée dans la note de version (§11) | dite parmi les corrections · tue | 6 — le joueur voit une section quitter la fiche ; la note lui dit pourquoi | Parmi les corrections, qui restent trois après le n° 12 : l'infobulle du boss « XP », le retour système, la fiche des probabilités | §11 |
| C4.4 | Qui calcule les deux faits que reçoit `isSelectable` | `EventController`, par une méthode que l'écran appelle à la place de `isSelectable` · l'écran, à son appel (`event_screen.dart:528`), comme l'option du feu (`rest_screen.dart:128-131`) · chacun pour soi — l'écran pour le bouton, le contrôleur en garde dans `selectChoice` | 5 — un seul prédicat par question écarte la troisième, deux calculs d'un même fait ; et la logique métier vit dans les contrôleurs (`CLAUDE.md`, « State & business logic »), non dans un widget | `EventController.isChoiceSelectable(EventChoice choice, Iterable<ForgeUpgradeData> runeCatalog)`, que l'écran appelle (§4.9) | §3.8, §4.8, §4.9, §8 |
| C4.5 | Les deux faits : requis ou optionnels | `required` · optionnels, à défaut faux, comme `hasRaisableRune` (C2.4) | 5 — l'analyseur désigne l'appelant oublié, comme pour `currentMastery` (C1.2) ; le défaut de C2.4 servait des appels de test qui compilent tels quels, et `isSelectable` n'en a aucun (`git grep -n isSelectable -- test` vide), pour un seul appelant de production, `event_screen.dart:528`, qui change de toute façon | Requis | §3.8, §4.9 |
| C4.6 | La portée de la règle des commentaires (n° 3) | `lib/` et `test/`, le script suivant sa propre liste (§9) · aussi les renvois du script vers le code | 7 — la seconde rouvrirait C2.2, qui ne recale que les renvois que §9 nomme | `lib/` et `test/` ; le script suit §9, la documentation du dépôt suit `memory-bank-sync` (§11) | §8 |
| C4.7 *(tranché par l'orchestrateur à la relecture)* | Les chances que la section « Récompense de niveau » de la fiche affiche, qu'aucun tirage n'utilise : la fiche montre 0,5 / 4,5 / 15 / 20 (`probabilities_dialog.dart:34-37`, branche vraie), les trois emplacements tirent par `LevelUpRewardService.rollRarity(luck, isLevelReward: false)` (`level_up_reward_service.dart:116`) sur 2 / 6 / 16 / 24 (`:51-62`) — un écart antérieur à E3, mais E3 réécrit le sous-titre de cette section (n° 7) et ouvre un test de widget sur la fiche (C4.1) | (a) consignée hors du lot, en §5.4, et portée à la file par le compte rendu de la vague · (b) alignée, la fiche gardant sa propre copie des constantes, corrigée · (c) alignée, la fiche lisant les chances des emplacements sur `LevelUpRewardService`, une seule source des poids, partagée avec `rollRarity` | 1 à 5 n'écartent pas (a) — aucune décision, aucune valeur mesurée, `rollRarity` ne change pas — ; **6 l'écarte, comme au n° 8** : elle laisserait, sous le sous-titre neuf du n° 7, des lignes qui le démentent ; entre (b) et (c), **5** : un fait à un seul endroit — la copie de la fiche est précisément ce qui a divergé | (c), **en partie 1**, avec le retrait du n° 8 (même fichier, même fichier de test) : `LevelUpRewardService.slotRarityChances(int luck)` (§3.8) ; `calculateDraftProbabilities` disparaît (§5.1) | §3.8, §5.1, §5.4, §8, §10, §11 |

#### Tranchés par le propriétaire — la levée du troisième arrêt (03/10)

Ce sont les recommandations que l'orchestrateur avait consignées au §13 à l'arrêt du cinquième tour, acceptées par le
propriétaire quand il a levé le troisième arrêt. Une ligne pour chaque constat dont la correction avait plusieurs formes
ou options ; les n° 1, 3, 4, 5 et 6 sont corrigés tels que le vérificateur les proposait (§13).

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| n° 2 | L'écart des chiffres de la section « Butin de Reliques », antérieur à E3 : dès Chance 10, la fiche normalise ses quatre poids quand les tirages les prennent en cascade — et, trouvé à la re-mesure, la relique du boss « relique » se tire sur ses propres poids | consigné hors du lot, en §5.4, et porté à la file par le compte rendu de la vague · aligné comme C4.7, la fiche lisant ses chances sur les tirages | 7 — E3 ne réécrit pas cette section, ce qui la distingue de C4.7, où le filtre 6 écartait la consignation parce que le sous-titre neuf du n° 7 aurait été démenti par ses lignes | Consigné hors du lot : une phrase en §5.4, qui dit l'écart et le porte à la file par le compte rendu de la vague ; §5.1 y renvoie | §5.1, §5.4 |
| n° 7 | La réserve d'A5 dans la description de la *Meule*, le seul texte joueur du boss « XP » qui ne la porte pas | ajoutée · laissée, la réserve ne s'y lisant que par « de plus » (facultatif chez le vérificateur) | 6 — sans elle, la relique promet une rune de plus là où rien ne monte faute de paire sous son plafond (A5), une règle cachée ; les autres textes joueur du boss « XP » la disent depuis le n° 6 du tour 4 | Ajoutée : « … à une rune de plus, si l'une peut encore monter. » · "…, if any still can." | §3.3, A5 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du cinquième tour

Tranchées par l'arbre de décision (orchestration §5) à la correction ; l'orchestrateur les relit et peut les renverser.
Il a confirmé C5.1 telle qu'elle est écrite, et le fait que la re-mesure a ajouté au n° 2 — la relique du boss
« relique », tirée sur ses propres poids (`reward_controller.dart:114-135`), consignée hors du lot avec l'écart.
Aucune ne se tranche qu'en amendant une décision acquise, ni en changeant une valeur mesurée.

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C5.1 | Un cas qui garde la borne basse de `slotRarityChances`, que le n° 4 du tour 5 écrit : sous Chance −4, que seul le menu de debug atteint (`debug_hero_tab.dart:88`), un poids négatif s'affiche à 0 | aucun cas neuf · un quatrième cas dans `probabilities_test.dart`, `slotRarityChances(-6)` à 0 / 0 / 0 / 0 / 100 de la légendaire à la commune | 1 à 7 ne départagent pas — aucune décision, aucune valeur mesurée ; le joueur n'atteint jamais une Chance négative (§3.8), et le cas tiendrait dans un fichier que la partie 1 complète déjà ; 8 retient la première : rien à défaire | Aucun cas neuf : les trois cas de « Les chances des emplacements » restent | §3.8 |


### 2.2. Plan E3, partie 1 — [`2026-10-03-p43-e3-trouvaille-et-progression-partie-1.md`](../plans/2026-10-03-p43-e3-trouvaille-et-progression-partie-1.md)

Un tour de vérification. Le vérificateur a rejoué les Tasks 1 à 7 sur une extraction de `2c1d8f4` hors du dépôt — 186 remplacements, chaque texte « avant » trouvé une fois et une seule, `dart analyze` propre et `flutter test` vert après chaque tâche, totaux mesurés égaux aux annoncés (1481 · 1490 · 1506 · 1508 · 1522 · 1528 · 1534) ; une mutation de la borne de main a fait rougir les trois cas qui la gardent. **Prêt**, deux mineurs corrigés au passage par l'orchestrateur :

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| P1 | Une référence de ligne fausse (`tutorial_screen.dart:148-152`) | corrigée · laissée (le texte « avant » fait foi) | 8 | Corrigée, `:150-154` |
| P2 | La documentation de `CardRarity.fusionRank` énumère ses lecteurs ; la difficulté en devient un quatrième (constat facultatif) | la compléter en Task 1 · la laisser | La règle des commentaires de la spec (§8, n° 3 de la levée du second arrêt) : une liste de lecteurs qui en omet un se lit comme complète et trompe | Complétée en Task 1 ; `card_data.dart` entre dans son commit |

Les treize points par lesquels le plan précise ou corrige la spec sont dans sa section « Ce que le plan précise ou corrige de la spec » ; aucun n'amende un arbitrage, aucune prémisse de la spec n'a été trouvée fausse. Deux transitoires internes à la partie, signalés par le plan et jugés acceptables par le vérificateur : le commentaire `tutorial_engine.dart:510-511` faux entre les Tasks 3 et 4, et les deux bonus de `CardDrops.roll` sans lecteur de production entre les Tasks 5 et 6.

### 2.3. Les décisions de SDD — exécution du plan de la partie 1

Recopiées du registre de SDD avant la suppression de son espace de travail, dans l'ordre où elles ont été prises, chacune avec ce qu'elle coûte si elle est fausse. Implémenteurs et relecteurs Sonnet, revue d'ensemble Opus. Chaque revue de tâche a approuvé au premier passage : aucun tour de correction. La Task 8, qui n'écrit aucun code, a été jouée par l'orchestrateur : `dart analyze` propre, 1534 tests verts, chaque commande de contrôle de la partie 1 conforme.

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| S1 | Contrôle préalable : aucun conflit entre tâches à trancher | Les douze fichiers partagés par deux tâches ou plus touchent des régions distinctes ; le vérificateur du plan avait rejoué les sept tâches dans l'ordre | — |
| S2 | Task 6 : le commit `3f3fbcf` porte la ligne d'attribution de son implémenteur (« Claude Sonnet 5.5 ») au lieu de celle de la fiche — gardé tel quel | La réécriture d'un commit est interdite (orchestration §6), et la ligne nomme le modèle qui l'a écrit | Une ligne d'attribution hétérogène dans l'historique ; cosmétique |
| S3 | La revue d'ensemble prend pour base `7a4f0d7` (le commit du plan) et non `git merge-base main HEAD` | Entre les deux, seuls la spec, l'index et le journal changent, vérifiés par six tours ; le diff de code est identique | Aucun |
| S4 | Revue d'ensemble, n° 2 : aucun test ne prouvait que le démarrage échoue sans `xp_curve.json` — corrigé (`9b0e2e5`), un cas de `game_data_loader_test.dart`, preuve rouge (la lecture déplacée après `throwIfFailed`) puis verte | La spec (§3.2) promet le refus au démarrage | Un test de plus |
| S5 | Revue d'ensemble, n° 3 : l'arbre de `assets/data/` dans `CLAUDE.md` réaligné (`9b0e2e5`) | Cosmétique | Nul |
| S6 | Revue d'ensemble, n° 1 : le plafond de quatre notifications (`notification_overlay.dart:35-40`) peut retirer « RELIQUE OBTENUE », « VICTOIRE » ou une « Carte trouvée » quand l'étape « or et XP » en empile plus — **renvoyé au plan de la partie 2, comme exigence** | La partie 2 ajoute au même endroit une notification par rune affûtée (boss « XP », *Meule*) : le plafond se règle sur la liste complète (filtre 6, puis 7) | En `0.5.5` intermédiaire, jamais livrée, une notification peut se perdre dans un cas rare (élite à seconde carte et passage de niveau ; plusieurs *Sacoches*) |
| S7 | Task 7, mineur : `probabilities_dialog_test.dart` ne garde que la rangée de la commune — **renvoyé à la partie 2**, qui rouvre ce fichier (C4.2) : une ligne `findsOneWidget` sur une autre rareté garderait l'ordre des rangées | Les cinq valeurs sont gardées par les tests unitaires de `slotRarityChances` | L'ordre des rangées de la fiche non gardé jusque-là |

Mineurs différés pendant les revues de tâche, triés par la revue d'ensemble — **tous peuvent rester** : `encounter_system_test` garde `deckFusionRanks: 20` (le poids d'avant, 40, inchangé) ; pas de test de bout en bout « la taille du deck n'a plus d'effet » (les deux moitiés testées, le câblage gardé par une commande de contrôle) ; des numéros de ligne dans un commentaire de `hand_size_bound_test` ; `DrawEffectStrategy` sans garde propre (la borne vient de son paramètre) ; `DebugActions.gainLevel` donne deux niveaux si l'XP accumulée dépasse déjà deux paliers moins un (antérieur, menu de debug seul) ; l'ordre d'un import ; l'étape RED de la Task 3 non lancée à part ; `xpThreshold` relu à chaque tour de boucle ; `data.xpCurve!` sans garde (A27) ; le pool d'offre calculé deux fois et deux styles de localisation dans un même bloc de `GameScreen` (la partie 2 retire la carte bonus) ; un `RelicData` copié dans deux cas de test ; quatre alias locaux et un long commentaire dans `level_up_reward_service.dart`.

### 2.4. Plan E3, partie 2 — [`2026-10-04-p43-e3-trouvaille-et-progression-partie-2.md`](../plans/2026-10-04-p43-e3-trouvaille-et-progression-partie-2.md)

Quinze tâches, 1535 → 1622 tests : dix de code (l'affûtage sans or, le boss « XP » et la *Meule*, le plafond des notifications, les deux événements, *Sagesse*, *Transcendance* et le bonus de plafond, les seuils), quatre de simulation (le réalignement, puis les trois changements voulus), la vérification finale. Deux tours de vérification, chacun par un vérificateur neuf qui a rejoué les quatorze tâches sur une extraction de `30027a9` hors du dépôt, `dart analyze`, la suite entière et la fumée `--quick` après chaque tâche. Le premier : quatre moyens, trois mineurs. Le second : **prêt** — chaque tâche verte et propre sans correctif local, totaux mesurés égaux aux annoncés (1538 · 1542 · 1548 · 1563 · 1575 · 1577 · 1590 · 1600 · 1607 · 1622), la fumée réalignée au diff vide contre celle de la base `9282513` ; deux mineurs de texte corrigés au passage par l'orchestrateur (un transitoire entre les Tasks 8 et 9 à nommer en entier, deux lignes de calibration de plus dans l'écart de libellé annoncé de la Task 14).

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| P3 | Un texte « avant » présent deux fois dans `reward_controller_test.dart` (Task 2) *(moyen, tour 1)* | élargi d'une ligne · remplacements réordonnés | 8 | Élargi à la paire unique `:174-175` |
| P4 | Deux cas de `draft_screen_test.dart` rouges de la Task 6 à la Task 10 : six rouleaux mythiques débordent la surface de test de 800 × 600 *(moyen, tour 1)* | une vue large dans les deux cas · rien en jeu | 8 ; en jeu, le débordement demande trois mythiques ou plus dans un même draft, pratiquement inatteignable hors `forceLegendary` (D62) | Un helper de fichier `_largeView(tester)` en Task 6, que le groupe *Transcendance* de la Task 7 réutilise ; aucune tâche de mise en page |
| P5 | Deux lints `use_null_aware_elements` (Task 10, `passive_data_test.dart` ; Task 11, le script) *(moyens, tour 1)* | — | — | `'floor': ?floor,` ; `?brainstormEventFiles[type],` — la fumée réalignée reste au diff vide |
| P6 | `DeckNotifier.mergeCards(…, {capBonus})` né en Task 8 sans appelant qui le passe *(mineur, tour 1)* | le déplacer en Task 9, avec `deck_screen.dart` · le nommer parmi les transitoires | 5 — pas de code sans lecteur | Déplacé en Task 9 ; **et, accepté par l'orchestrateur, `ForgeRuneRules.consolidate` et sa borne avec lui**, `mergeCards` étant le seul appelant de production de `consolidate` (Task 8 : 1600 ; Task 9 : 1607) |
| P7 | L'en-tête « Valeur calée » de la table de calibration, au-dessus d'une ligne désormais lue dans `xp_curve.json` *(mineur, tour 1)* | renommé « Valeur » à la relance 3 · laissé | 6, appliqué au lecteur de la référence | Renommé, un écart de libellé de plus, annoncé |
| P8 | Le plafond des notifications (exigence S6) | le relevé du pire cas réaliste de l'étape « or et XP » sur le code de la partie 2 | — | **5 messages** — élite à seconde carte avec passage de niveau ; combat sous deux *Sacoches* ; boss « XP » sous deux *Meules* — recomptés par les deux vérificateurs ; `NotificationNotifier.maxVisible` à 5, gardé par `notification_notifier_test.dart` (une mutation à 4 rougit) |

Les précisions du plan sur la spec sont dans sa section « Ce que le plan précise ou corrige de la spec » ; aucune n'amende un arbitrage, aucune prémisse de la spec n'a été trouvée fausse — seuls des numéros de ligne déplacés par la partie 1. `capBonus` est **requis** sur `GoldManager.sharpenRune` et `exchangeRune`, leur seul appelant étant `RunController` : A17 ne le veut optionnel que sur `boundLevel`, `ForgeRuneRules` et `mergeCards`. Trois transitoires internes à la partie, jamais livrés : le tirage du boss qui ne lit que la constante entre les Tasks 2 et 3 ; *Transcendance* lue par `raisableCaps` et la modale seuls entre les Tasks 7 et 8 ; entre les Tasks 8 et 9, la fusion, le feu, la sélection d'affûtage, le dialogue et le Puits encore au plafond de base.

### 2.5. Les décisions de SDD — exécution du plan de la partie 2

Recopiées du registre de SDD avant la suppression de son espace de travail, dans l'ordre où elles ont été prises. Implémenteurs Sonnet, relecteurs Sonnet (Opus pour la Task 7, la plus grosse), revue d'ensemble Opus. Chaque revue de tâche a approuvé au premier passage : aucun tour de correction. La Task 15, qui n'écrit aucun code, a été jouée par l'orchestrateur : `dart analyze` propre, 1622 tests verts, `flutter gen-l10n` sans écart, chaque commande de contrôle de fin de vague conforme — les trois « vides à la fin de la vague » vides —, neuf fichiers sous `assets/`, les commits du script au-dessus des commits de donnée, `sync_assets --check` à 0. Les quatre mesures complètes de la simulation ont été lancées par l'orchestrateur, chacune sur son commit extrait hors du dépôt (§4).

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| S8 | Contrôle préalable : aucun conflit entre tâches à trancher | Les fichiers partagés par plusieurs tâches le sont en série ; le second vérificateur du plan avait rejoué les quatorze tâches dans l'ordre, sans correctif local | — |
| S9 | Revue d'ensemble, n° 1 : l'action `sharpen_rune` bornée à 1 au chargement — `8fc7da5` | A4 dit « +1 niveau », et le dialogue (« Niveau n → n+1 ») comme le badge ne savent montrer qu'un niveau : une donnée à 2 promettrait un niveau et en donnerait deux (filtre 6) | Un événement futur à +2 devra relever la borne et l'interface ensemble |
| S10 | Revue d'ensemble, n° 2 : le *Rémouleur* grisé dit pourquoi, par un badge « Aucune rune à affûter » / "No rune to sharpen" (`eventNoRuneToSharpen`) sur le modèle de « Aucune relique à céder » — `8fc7da5` | Question apparue à la revue d'ensemble : sans badge, le choix grisé sous « -10 PV » laisse croire à une affaire de PV, et le cas est fréquent en début de run (A5) ; filtre 6, avant le 7 | Une clé ARB et un badge de plus |
| S11 | Revue d'ensemble, n° 3 (un mineur différé de la Task 5) : le solde d'or masqué dans le dialogue d'affûtage en mode sans or — `8fc7da5` | Il suggérait un paiement qui n'a pas lieu (filtre 6) | Nul |
| S12 | Revue d'ensemble, n° 4 : deux commentaires — un renvoi à « Task 6 » dans un test, un commentaire mal recoupé de l'éditeur — `8fc7da5` | Un numéro de plan ne dit plus rien après la fusion | Nul |
| S13 | Les autres mineurs restent, triés par la revue d'ensemble ; deux partent à la file (§5) | Inatteignables par l'interface, antérieurs, ou imposés par le plan et justes aujourd'hui | Voir §5 |

Mineurs différés pendant les revues de tâche, **tous laissés** après le tri de la revue d'ensemble, sauf le solde d'or (S11) : le tirage de runes du boss sur un `Random()` interne (imposé par le plan) ; l'écran de combat sans test d'écran (C2.5, gardé par les commandes de contrôle) ; le minuteur d'une notification évincée non annulé (antérieur, inoffensif) ; des `case` de badge dupliqués entre les deux variantes (motif existant) ; l'action `sharpen_rune` sans effet si aucune cible n'est donnée après la perte de PV — inatteignable, l'écran pousse toujours la sélection (à la file) ; l'état de chargement nu de la fiche des probabilités (inatteignable) ; le double appel de `raisableCaps` dans l'écran de draft ; sept rouleaux mythiques sur une fenêtre moyenne (trois jets à 0,5 % simultanés au moins) ; un test de boutique probabiliste ; la relecture du bonus par ligne au Puits ; « jamais sous 2 » écrit en dur dans *Flux de Mana* (juste aujourd'hui, à la file) ; des lignes longues, des littéraux et un `x as int` dans le script.

---

## 3. Le cahier de test manuel

Une partie neuve à chaque série : les sauvegardes ne passent pas d'une version à l'autre avant la `1.0.0`. Le menu de debug donne les reliques, l'or, l'XP, la Chance et la Maîtrise ; le journal de debug d'un combat dit la difficulté. Jouer chacune des trois classes au moins une fois.

### 3.1. Une carte après chaque combat

- Gagner un combat normal : un message « Carte trouvée : <nom> » s'affiche, la carte est dans le deck, **commune**, et c'est une carte que la classe peut recevoir — une neutre ou une carte de sa classe, jamais celle d'une autre classe ni une carte de classe de départ.
- Gagner une élite : une carte toujours, une seconde environ une fois sur quatre, et la relique garantie.
- Battre un boss : pas de carte trouvée, sa récompense habituelle.
- Sur une dizaine de combats, les doublons arrivent : une fusion de trois devient possible dès l'acte 2 ou 3.
- L'infobulle d'élite de la carte du monde dit « une relique garantie, et une carte — parfois deux ».

### 3.2. Le *Registre des primes* et la *Sacoche du glaneur*

- Avec la *Sacoche du glaneur* (menu de debug) : **deux** cartes après chaque combat normal ; en élite, rien de plus.
- Avec le *Registre des primes* : la seconde carte d'élite devient bien plus fréquente (50 % avec un exemplaire, toujours à partir de trois) ; jamais plus de deux cartes par élite.
- Céder la *Sacoche* au *Colporteur* (§3.7) : le combat normal suivant ne donne plus qu'une carte.

### 3.3. Les niveaux

- À l'acte 1, la barre d'XP du héros se lit sur 115 ; à l'acte 2, sur 200 ; à l'acte 9, sur 1040. Environ deux niveaux par acte.
- « Gagner un niveau » du menu de debug donne exactement un niveau, au prix de l'acte courant.
- Le tutoriel annonce 115 XP au premier palier et 200 au suivant, et sa barre d'XP suit.

### 3.4. La difficulté

- Le journal de debug d'un combat écrit « Σ rangs : N » et la formule « 2 × Σ rangs » à la place du nombre de cartes.
- Un deck de 20 cartes communes affronte des combats de la même difficulté qu'un deck de 10 cartes communes ; un deck qui a beaucoup fusionné, des combats plus durs.

### 3.5. La main

- Le champ « Main max » du menu de debug règle la main maximale de la run (10 par défaut) : la pioche du tour, une carte qui pioche, la rune *Véloce* et *Frénésie* du Berserker s'arrêtent à cette borne, sans perdre de carte ; une main déjà au-delà ne pioche rien et ne perd rien.

### 3.6. Le boss d'XP et la *Meule*

- La carte du monde : l'infobulle du boss d'XP dit le triple d'XP et d'or, et qu'une rune du deck, si l'une peut encore monter, gagne un niveau.
- Le battre avec un deck qui porte des runes sous leur plafond : pas de carte bonus ; une rune monte d'un niveau, et un message dit laquelle et sur quelle carte.
- Le battre avec un deck sans rune affûtable (aucune rune, ou toutes à leur plafond, comme *Économe 1*) : rien ne monte, et le message « Aucune rune de votre deck ne peut gagner de niveau. » le dit.
- Avec la *Meule* : deux runes montent — deux messages. Avec deux *Meules*, trois.
- Une élite à seconde carte avec un passage de niveau empile cinq messages : aucun ne disparaît avant d'avoir été vu.

### 3.7. Les deux événements

- **Le *Rémouleur*** : choisir de monter une rune ouvre la sélection des cartes — celles sans rune affûtable sont grisées —, puis le dialogue de la rune, **sans prix ni solde d'or** ; « Choisir » monte la rune d'un niveau, retire 10 % des PV max, l'or ne bouge pas. Annuler la sélection ou le dialogue ne coûte rien et laisse l'événement ouvert. Sur un deck sans rune affûtable, le choix est grisé et dit « Aucune rune à affûter ».
- **Le *Colporteur*** : ses offres nomment la relique la plus faible portée (« Cède <nom> : +40 Or » pour une commune, jusqu'à +200 pour une légendaire) ; l'offre de soins n'est active que sous la moitié des PV, et rend 20 % des PV max. Sans relique : les deux offres sont grisées et disent « Aucune relique à céder ». Céder une relique qui changeait la run (la *Sacoche*, le *Registre*, la *Meule*) défait son effet.
- À un événement, après un choix, le retour système ferme l'écran et termine la visite : on ne rejoue pas un événement dans le même nœud. Avant tout choix, le retour ne résout rien.

### 3.8. *Sagesse*, *Transcendance* et la fiche des probabilités

- *Sagesse* n'apparaît plus parmi les trois options ordinaires d'une montée de niveau ; quand elle sort, à part, comme mythique, elle donne +1 Mana max.
- *Transcendance* n'est offerte que si une rune du deck est à son plafond — *Économe 1*, *Véloce 1*, *Congelant 1*… —, jamais pour *Allégé* ni *Persistant* ; la prendre ouvre une fenêtre qui fait choisir la sorte de rune, sans pouvoir la fermer autrement. Ensuite : *Économe* s'affûte au feu jusqu'au niveau 2, s'appelle « Économe 2 », et le boss d'XP, le *Rémouleur* et la fusion la portent eux aussi jusqu'à 2 ; le Puits, qui échange une rune, la reçoit jusqu'à 2.
- La fiche « Taux d'obtention des Raretés » : plus de section « Draft standard de récompenses » ; à Chance 0, la commune d'une montée de niveau à 52 %, la légendaire à 2 % ; la parenthèse nomme les options mythiques — Sagesse, Trèfle à 4 feuilles, Miroir, Transcendance. La section « Butin de Reliques » ne change pas (son écart avec les tirages part à la file, §5).

### 3.9. Les passifs

- **Mage, *Flux de Mana*** : à Maîtrise 0, trois Compétences rendent 1 Mana ; chaque point de Maîtrise en retire une, **jamais sous deux**. La fiche « Statistiques du Héros » et l'option *Affinité* disent l'effet réel — au plancher, l'*Affinité* s'annonce sans effet sur le passif.
- **Paladin, *Bénédiction*** : le soin par tranche de 5 d'Armure ne change pas.
- **Berserker** : rien de neuf hors des règles communes ; vérifier *Frénésie* sur une main pleine (§3.5).

### 3.10. Ce qui doit rester inchangé

- Le feu de camp : repos, affûtage payant (50 or × niveau) et oubli, un seul par visite ; le Puits d'échange ; la boutique et son étal ; la fusion de trois cartes et sa rune au choix.
- Les autres événements et reliques, leurs textes ; la section « Butin de Reliques » de la fiche des probabilités.
- Les cartes de classe de départ restent dans le deck, sans rune, et ne sont jamais trouvées après un combat (elles en sortent à la vague suivante).
- Le tutoriel se joue jusqu'au bout.

---

## 4. La simulation

`tool/simulations/d26_economy_sim.dart`, relancé en deux temps (§3.6, D73), chaque fois par l'orchestrateur sur une extraction hors du dépôt du commit mesuré (`git archive <commit> tool/simulations assets/data`, spec §9), sortie vers `.superpowers/`, comparée par `git diff --no-index`. Les quatre mesures sont complètes (300 runs par configuration, 200 par levier) ; chacune a pris de 381 à 415 s.

**Premier temps — le réalignement seul** (`ca0ba2f`, Task 11 de la partie 2). Les six entrées du brainstorm qu'E3 écrit en fichiers — les reliques A, C et de D42(a) (*Registre des primes*, *Sacoche du glaneur*, *Meule*), les événements de D23 et de D42(b) (*Colporteur*, *Rémouleur*), la mythique de D42(c) (*Transcendance*) — prennent la place exacte de leurs entrées en dur, rareté vérifiée. Mesure complète en 386 s : **diff vide** contre la référence, ligne « Données lues » comprise — elle compte les listes chargées, dont ces fichiers sont écartés (spec §1.3). La fumée `--quick` de la tâche l'avait déjà montré contre une fumée sur la base `9282513`.

**Second temps — trois changements voulus, une relance chacun** (A28). Chaque retrait d'une entrée tirée par index décale tous les tirages qui suivent (D73) : l'écart touche presque toutes les lignes, mais les grandeurs que les décisions mesurées supposent restent dans le bruit.

| Mesure, acte 15 (médiane, toutes configurations) | Réalignement `ca0ba2f` (= référence) | Relique B retirée `8c558bc` | Événement D29 retiré `2acfa6c` | Table d'XP du jeu `d8b2aef` |
|:---|---:|---:|---:|---:|
| Deck | 35 | 35 | 36 | 36 |
| Fusions | 45 | 45 | 46 | 46 |
| Σ niveaux de rune | 71 | 72 | 71 | 71 |
| Or en réserve | 5900 | 5936 | 6002 | 6023 |
| Niveau du héros | 30 | 30 | 30 | 30 |
| Dégâts / tour | 659 | 680 | 681 | 678 |
| `PlayerPower` (DDA) | 791 | 796 | 802 | 805 |
| Budget d'un combat normal | 786 | 788 | 791 | 791 |
| Quasi-morts | 234 | 228 | 226 | 229 |
| Lignes de la sortie qui changent | — | 497 sur 798 | 498 sur 797 | 479 sur 787 |

1. **La relique B retirée** (D57 ; `8c558bc`, mesure en 397 s). B quitte la réserve, sa variante `forced`, ses deux jets d'élite et le compte des exemplaires ; la variante de référence devient « A +25 %, dans la réserve », « A et C tenues dès l'acte 1 », et la ligne « Données lues » dit « 25 reliques (+ 3 du brainstorm) ». La variante « B +2 % par exemplaire » disparaît (798 → 797 lignes).
2. **L'événement de fusion de D29 retiré** (D56 ; `2acfa6c`, 415 s). Il quitte la liste des événements, avec sa résolution et la ligne « Fusions par l'événement D29 » des onze tables qui la portaient (797 → 787 lignes) ; « 5 événements (+ 2 du brainstorm) ». Il donnait une fusion par run en médiane : les fusions n'en perdent pas, la place qu'il occupait dans les tirages revient aux autres événements.
3. **La table d'XP du jeu** (D24, D67 ; `d8b2aef`, 381 s). La référence joue désormais `xp_curve.json` — 115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015 — au lieu de la table que le script recalait à chaque lancement (115 · 200 · 310 · 475 · 590 · 770 · 955 · 1080 · 1050 · 1190 · 1410 · 1345 · 1275 · 1380 · 1040 dans la référence d'avant, à −25 à +40 XP de D67 selon l'acte). **La calibration reste affichée** : une ligne « Table par acte (réf., `xp_curve.json`) » écrit la table lue, la ligne « Table par acte, calée » la table que la mesure recale encore (110 · 200 · 315 · 485 · 590 · 780 · 975 · 1085 · 1045 · 1190 · 1385 · 1365 · 1300 · 1340 · 1050), à quelques dizaines d'XP de D67 : le palier du jeu donne toujours deux niveaux par acte, le héros finit niveau 30. **L'écart de libellé, dit d'avance** : les trois libellés qui appelaient « actuelle » la DDA en `cartes × 2` et la courbe en `100 × 1,5^(n−1)` disent « d'avant E3 » (sept lignes), l'en-tête de colonne « Valeur calée » devient « Valeur », et la table de calibration gagne sa ligne neuve (787 → 788 lignes).

**Ce que les décisions mesurées supposent ne bouge pas.** Deck de 35 à 36 cartes et 45 à 46 fusions à l'acte 15 (D56, D67) ; héros niveau 30 ; la DDA à 2 × Σ `fusionRank` donne un budget de 791 à l'acte 15, contre 808 pour la formule d'avant E3 en `cartes × 2` (D59) ; les quasi-morts restent entre 226 et 234. L'or qui dort à l'acte 15 monte de 5 900 à 6 023 : le constat de P-16 sur le puits d'or se confirme, sans relance de plus.

**La référence est recommitée** sur la sortie de `d8b2aef` : la vague 4 se comparera à elle.

---

## 5. Trouvé périmé, et pour la file

*Ouvert à la fin de la partie 1 ; complété à la fin de la vague.*

**Ce que le plan de la partie 1 a précisé en re-mesurant** : `HeroMiniStatsPanel._buildXpBar` recevait `dynamic stats` — l'analyseur n'aurait pas vu `xpToNextLevel` survivre à sa suppression ; il est typé `EntityStats` ; `tutorial_play_card_widget.dart` écrivait un `10` littéral et non la constante ; « *Frénésie* sur une main pleine » ne s'obtient pas par une carte qui tue, qui quitte la main avant le décompte des morts — le test passe par `RunController.onEnemyKilled()`.

**Repris par la partie 2** : le plafond des notifications de l'étape « or et XP », porté à 5 (S6, §2.4 P8) ; une rangée de plus gardée dans `probabilities_dialog_test.dart` (S7).

**Pour `memory-bank-sync`**, constaté par les plans :
- par celui de la partie 2 : le plafond des notifications passe de quatre à cinq (`NotificationNotifier.maxVisible`) ; `GoldManager.sharpenRune` et `exchangeRune` prennent `capBonus` requis, et `sharpenRune` délègue l'écriture à `DeckNotifier.raiseRuneLevel` ; la sélection d'affûtage et son dialogue ont un mode sans or (`isFree`) ; l'en-tête du script de simulation compte la courbe d'XP parmi les données relues ;
- par celui de la partie 1 : `_rules/03-4` cite `GameConstants.maxHandSize`, devenu `startingMaxHandSize` ; `_patterns/02-1` le palier stocké, désormais dérivé ; `_patterns/17-00` le chargeur, qui gagne `loadDocument`.

**Pour la file** :
- **l'écart de la section « Butin de Reliques » de la fiche des probabilités** (levée du troisième arrêt, n° 2 ; spec §5.4), antérieur à E3 et hors du lot : dès Chance 10, la fiche normalise ses quatre poids (5,71 / 14,29 / 32,38 / 47,62) quand la relique d'élite et celle de `gain_relic` se tirent en cascade sur les mêmes poids (6 / 15 / 34 / 45) ; la relique du boss « relique » se tire sur ses propres poids, qui suivent l'acte, quand le sous-titre de la section la range avec les élites et les événements ; et `probabilities_test.dart:104-126` verrouille la normalisation sur sa propre copie de la formule (`:26-54`), et non sur la fiche — à reprendre avec l'écart ;
- `DebugActions.gainLevel` peut donner deux niveaux quand le champ « XP » du menu de debug porte déjà plus de deux paliers moins un (antérieur, debug seul) ;
- une garde dans l'action `sharpen_rune` qui refuserait le choix entier, avant la perte de PV, si la cible donnée n'est pas affûtable — inatteignable aujourd'hui, l'écran pousse toujours la sélection, qui ne propose que des cibles affûtables (S13) ;
- un placeholder `{floor}` dans les descriptions de passif : *Flux de Mana* écrit « jamais sous 2 » en dur, juste tant que son `floor` vaut 2 (S13).
- **pour la méthode** (orchestration §3.8) : les transcriptions de Claude Code n'enregistrent pas toujours la sortie finale d'un message — 149 appels de cette vague écrivent 1,09 million de caractères pour 2 132 jetons de sortie enregistrés —, si bien que la sortie mesurée, et son coût, sont des minimums (§6). Les vagues 1 et 2 se mesuraient de la même manière ; à dire dans le modèle des statistiques, ou à mesurer autrement.

---

## 6. Les statistiques de la session

**Mesurées, pas estimées** (orchestration §3.8). Elles viennent des transcriptions de Claude Code : `~/.claude/projects/<projet>/<id de session>.jsonl` pour l'orchestrateur, un fichier par sous-agent sous `…/<id de session>/subagents/` — y compris ceux des workflows (`subagents/workflows/`), qui ont porté les panels de vérification des deux premières sessions. Chaque appel au modèle est compté une fois par identifiant de message, au maximum de ses lignes. Le script de mesure est resté dans le dossier temporaire de la session.

**La vague a eu quatre sessions** :
- l'ouverture, arrêtée au troisième tour de la spec (`b21776e8-2c14-4e35-9bb4-bc6e1c692baf`) ;
- la première reprise, arrêtée au quatrième tour (`078209a6-8bb7-4601-a005-c948374f33b0`) ;
- la deuxième reprise, arrêtée au cinquième tour (`16918c25-844a-42bc-a57e-4e2307c5e64c`) ;
- la troisième reprise, qui l'a menée jusqu'ici (`2d8ca500-2027-47d1-8129-e1bb92a3d40b`).

Les quatre sont comptées, séparément puis ensemble. Les heures sont locales (UTC+2) ; les jalons viennent des commits de la branche. La mesure est faite le 04/10 à 06:48, juste avant le commit de §3.8 : ce qui suit — la fin de cette section et le commit — n'y est pas compté.

**Une limite de la mesure, constatée en la faisant** : les transcriptions n'enregistrent pas toujours la sortie finale d'un message. 149 appels y écrivent ensemble 1,09 million de caractères — les gros `Write` des plans et de la spec, 25 à 50 Ko chacun — pour 2 132 jetons de sortie enregistrés. **Les jetons de sortie ci-dessous sont donc un minimum**, et le coût de sortie avec eux ; les autres catégories (entrée, cache) ne sont pas touchées. La vague 2 se mesurait de la même manière (§5).

### 6.1. Le temps

| | |
|:---|:---|
| Début | **03/10/2026 à 01:53** — le prompt de lancement de l'ouverture |
| Premier arrêt | **04:36** — la spec non convergée au troisième tour est commitée (`0a4eaa0`) |
| Première reprise | **20:31** → **21:29**, le quatrième tour, le deuxième arrêt (`cf61ff8`) |
| Deuxième reprise | **21:37** → **22:31**, le cinquième tour, le troisième arrêt (`84ff409`) |
| Troisième reprise | **22:33** → le 04/10 à **06:48**, la mesure |
| Durée | **28 h 55** de bout en bout, dont **12 h 57 de travail** — 2 h 43, 1 h 04, 55 min et 8 h 15 — et 15 h 55 d'arrêt avant la première reprise |
| Temps actif des orchestrateurs | environ **4 h 32** (21, 16, 16 puis 219 min) — leurs tours de travail, en comptant les attentes de moins de dix minutes : ce temps chevauche en partie celui des agents |
| Temps actif cumulé des sous-agents | environ **14 h 10** (262, 89, 47 puis 452 min) — lancés l'un après l'autre, sauf les panels de vérification des deux premières sessions et les mesures de simulation, que l'orchestrateur a fait tourner pendant la fin de la partie 2 |

| Étape | De | À | Durée |
|:---|:---|:---|---:|
| Porte d'entrée et branche (3.1, 3.2) | 01:53 | 01:57 | 4 min |
| Spec — rédaction, trois tours, premier arrêt (3.3) | 01:57 | 04:36 | 2 h 39 |
| Spec — correction, quatrième tour, deuxième arrêt (3.3) | 20:31 | 21:29 | 58 min |
| Spec — correction, cinquième tour, troisième arrêt (3.3) | 21:37 | 22:31 | 54 min |
| Spec — correction, sixième tour (3.3) | 22:33 | 23:00 | 27 min |
| Plan de la partie 1 — un tour (3.4) | 23:00 | 00:18 | 1 h 18 |
| Partie 1 — huit tâches, revue d'ensemble, ouverture du compte rendu (3.5) | 00:18 | 01:13 | 55 min |
| Plan de la partie 2 — deux tours (3.4) | 01:13 | 04:13 | 3 h 00 |
| Partie 2 — quinze tâches, revue d'ensemble (3.5) | 04:13 | 06:09 | 1 h 56 |
| Simulation, quatre mesures complètes de 386, 397, 415 et 381 s (3.6) | 05:22 | 06:10 | pendant la partie 2 |
| Note de version et mémoire (3.7) | 06:10 | 06:45 | 35 min |
| Compte rendu, suivi, journal (3.8) | 06:45 | — | non compté |

La spec prend 4 h 58 en quatre sessions, les deux plans 4 h 18 ; l'implémentation des deux parties, 2 h 51.

### 6.2. Les agents

**81 agents** : quatre orchestrateurs, et **77 sous-agents** lancés par eux — 13, 5, 2 puis 57. Aucun sous-agent n'en a lancé d'autre.

Quatre ont été repris avec leur contexte, par message, **cinq fois** en tout : le rédacteur de la spec, deux fois, dans l'ouverture ; le correcteur de la première reprise et celui de la deuxième, une fois chacun ; le rédacteur du plan de la partie 2, une fois. Deux sous-agents ont épuisé leur contexte et ont été compactés en cours de travail : le rédacteur de la spec et celui du plan de la partie 2.

| Rôle | Ouverture | Reprise 1 | Reprise 2 | Reprise 3 | Modèle |
|:---|---:|---:|---:|---:|:---|
| Orchestrateurs | 1 | 1 | 1 | 1 | Opus 5.5 |
| Rédacteurs et correcteurs de la spec, rédacteurs des plans | 1 | 1 | 1 | 3 | Opus 5.5 |
| Vérificateurs de la spec (dont quatre consolidateurs) et des plans | 12 | 4 | 1 | 4 | Opus 5.5 |
| Implémenteurs (8 tâches et correctifs en partie 1, 15 en partie 2) | — | — | — | 23 | Sonnet 5.5 |
| Relecteurs de tâche | — | — | — | 21 | Sonnet 5.5, sauf un sur Opus 5.5 (Task 7 de la partie 2) |
| Revues ciblées des correctifs | — | — | — | 2 | Sonnet 5.5 |
| Revues d'ensemble des deux plans | — | — | — | 2 | Opus 5.5 |
| Skills de fin de vague (`patch-notes-writer`, `memory-bank-sync`) | — | — | — | 2 | Opus 5.5 |
| **Sous-agents** | **13** | **5** | **2** | **57** — 12 Opus 5.5, 45 Sonnet 5.5 | |

Appels au modèle : **4 446** en tout — 460 pour les orchestrateurs (65, 47, 48 puis 300), 3 569 pour les sous-agents sur Opus, 417 sur Sonnet.

### 6.3. Les jetons

| | Ouverture (Opus) | Reprise 1 (Opus) | Reprise 2 (Opus) | Reprise 3, orchestrateur (Opus) | Reprise 3, sous-agents Opus | Reprise 3, sous-agents Sonnet | **Total** |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Entrée hors cache | 3 150 | 1 208 | 462 | 718 | 2 670 | 836 | **9 044** |
| Écriture en cache | 7 731 436 | 1 968 703 | 960 644 | 1 159 400 | 6 377 618 | 2 983 492 | **21 181 293** |
| Lecture du cache | 474 858 328 | 159 048 465 | 53 843 413 | 132 906 170 | 437 574 938 | 29 722 820 | **1 287 954 134** |
| Sortie (minimum) | 331 003 | 138 592 | 127 850 | 249 724 | 340 619 | 190 522 | **1 378 310** |
| **Total traité** | 482 923 917 | 161 156 968 | 54 932 369 | 134 316 012 | 444 295 845 | 32 897 670 | **1 310 522 781** |

- **Environ 1,31 milliard de jetons traités**, dont 98,3 % relus depuis le cache. Hors lecture du cache, il en reste **22,6 millions**, dont au moins **1,38 million** de sortie.
- **La spec pèse 52 % du total** (682 millions, orchestrateurs non compris) : six tours, dont quatre par un panel de trois vérificateurs et un consolidateur, chacun relisant la spec entière et le code qu'elle cite.
- **Les deux plans en font 24 %** (310 millions) : chacun rejoué tâche par tâche hors du dépôt par ses vérificateurs.
- **L'implémentation n'en fait que 5 %** (70 millions), pour 48 agents en deux parties.

| Étape | Sous-agents | Temps actif | Jetons traités | Dont sortie |
|:---|---:|---:|---:|---:|
| Spec — rédaction, trois tours (ouverture) | 13 | 262 min | 467,6 M | 257 865 |
| Spec — correction, quatrième tour (reprise 1) | 5 | 89 min | 151,5 M | 81 808 |
| Spec — correction, cinquième tour (reprise 2) | 2 | 47 min | 45,3 M | 70 869 |
| Spec — correction, sixième tour (reprise 3) | 2 | 21 min | 17,6 M | 31 860 |
| Plan de la partie 1 | 2 | 75 min | 116,9 M | 138 061 |
| Partie 1 — implémentation | 17 | 44 min | 22,6 M | 66 566 |
| Plan de la partie 2 | 3 | 176 min | 193,4 M | 48 806 |
| Partie 2 — implémentation | 31 | 100 min | 47,4 M | 167 187 |
| Fin de vague — skills | 2 | 34 min | 79,3 M | 78 661 |
| Orchestrateurs | — | ≈ 272 min | 169,0 M | 436 627 |

### 6.4. Le coût au tarif de l'API

C'est ce que la vague aurait coûté facturée au tarif public de l'API Claude. Ce n'est pas une facture réelle, ni celle de l'abonnement du propriétaire.

**Méthode** :
- chaque catégorie de jetons est multipliée par son prix, modèle par modèle ;
- les écritures en cache sont comptées au prix de leur durée, que les transcriptions ventilent : les orchestrateurs écrivent leur cache pour une heure, les sous-agents pour cinq minutes ;
- les jetons de réflexion sont comptés dans la sortie, comme l'API les facture ;
- les prix sont ceux de la [page des tarifs](https://platform.claude.com/docs/en/about-claude/pricing), lus le 04/10/2026, en dollars — inchangés depuis la vague 2 ;
- la conversion se fait au dernier taux de référence de la BCE, celui du 02/10/2026 (le 04/10 est un dimanche), **1 € = 1,1225 $**.

**Aucun supplément ne s'applique**, vérifié dans chaque `usage` : aucune recherche web (`server_tool_use` vide), vitesse standard (`speed`), aucun routage aux États-Unis (`inference_geo` à `not_available`), palier standard.

| Prix, $ par million de jetons | Entrée | Écriture en cache, 5 min | Écriture en cache, 1 h | Lecture du cache | Sortie |
|:---|---:|---:|---:|---:|---:|
| Claude Opus 5.5 | 4,00 | 5,00 | 8,00 | 0,20 | 20,00 |
| Claude Sonnet 5.5 | 2,00 | 2,50 | 4,00 | 0,20 | 10,00 |

| | Dollars | **Euros** |
|:---|---:|---:|
| Ouverture — orchestrateur | 9,70 $ | **8,64 €** |
| Ouverture — sous-agents Opus 5.5 (13) | 132,56 $ | **118,09 €** |
| Reprise 1 — orchestrateur | 5,22 $ | **4,65 €** |
| Reprise 1 — sous-agents Opus 5.5 (5) | 40,04 $ | **35,67 €** |
| Reprise 2 — orchestrateur | 4,92 $ | **4,38 €** |
| Reprise 2 — sous-agents Opus 5.5 (2) | 13,93 $ | **12,41 €** |
| Reprise 3 — orchestrateur | 40,85 $ | **36,40 €** |
| Reprise 3 — sous-agents Opus 5.5 (12) | 126,23 $ | **112,45 €** |
| Reprise 3 — sous-agents Sonnet 5.5 (45) | 15,31 $ | **13,64 €** |
| **Total de la vague** | **388,75 $** | **346,33 €** |

**Par catégorie** :
- la lecture du cache : 66 % du coût (257,59 $, 229,48 €) ;
- l'écriture en cache : 27 % (105,46 $, 93,96 €) ;
- la sortie, au minimum : 7 % (25,66 $, 22,86 €) ;
- l'entrée hors cache : trois centimes.

| Étape | Sous-agents | Dollars | Euros |
|:---|---:|---:|---:|
| Spec — rédaction, trois tours (ouverture) | 13 | 132,56 $ | 118,09 € |
| Spec — correction, quatrième tour | 5 | 40,04 $ | 35,67 € |
| Spec — correction, cinquième tour | 2 | 13,93 $ | 12,41 € |
| Spec — correction, sixième tour | 2 | 6,46 $ | 5,76 € |
| Plan de la partie 1 | 2 | 34,28 $ | 30,54 € |
| Partie 1 — implémentation | 17 | 9,23 $ | 8,22 € |
| Plan de la partie 2 | 3 | 51,37 $ | 45,77 € |
| Partie 2 — implémentation | 31 | 19,20 $ | 17,11 € |
| Fin de vague — skills | 2 | 20,99 $ | 18,70 € |
| Orchestrateurs | — | 60,69 $ | 54,07 € |

**Par rôle** :

| Rôle | Dollars | Euros |
|:---|---:|---:|
| Vérificateurs | 156,04 $ | 139,01 € |
| Rédacteurs et correcteurs de la spec et des plans | 122,60 $ | 109,22 € |
| Orchestrateurs | 60,69 $ | 54,07 € |
| Les deux skills de fin de vague | 20,99 $ | 18,70 € |
| Relecteurs, revues ciblées et revues d'ensemble | 17,52 $ | 15,61 € |
| Implémenteurs | 10,91 $ | 9,72 € |

La spec fait 50 % du coût (193,00 $, ses quatre sessions de sous-agents), les deux plans 22 % (85,65 $) ; l'implémentation des deux parties, 7 % (28,43 $).

**Contre la vague 2** (272,90 $, 243,12 €), la vague 3 coûte 42 % de plus. L'écart vient de **la spec** : six tours, quatre sessions, et des panels de trois vérificateurs et d'un consolidateur aux quatre premiers tours — 193,00 $ à elle seule, contre 96,40 $ pour la spec de la vague 2. Les deux plans, rejoués hors du dépôt par leurs vérificateurs, coûtent à peu près ce que coûtaient ceux de la vague 2 (85,65 $ contre 98,83 $), et l'implémentation reste bon marché : une fiche par tâche, sur Sonnet 5.5.
