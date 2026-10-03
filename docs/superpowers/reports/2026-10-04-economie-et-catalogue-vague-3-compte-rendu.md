# Vague 3 — `0.5.5` — E3, trouvaille et progression — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.3.
**Branche** : `feat/v0.5.5-p43-e3-trouvaille`, ouverte le 03/10/2026 depuis `main` à `bca35c5` (fusion de la vague 2).
**Ouvert le** : 04/10/2026, à la fin du plan de la partie 1 (§3.5). Complété à la fin de la vague (§3.8).
**État** : **en cours** — la partie 1 est implémentée ; restent le plan et l'implémentation de la partie 2, la simulation, la note de version et la mémoire.

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (03/10) | `main` propre et à jour à `bca35c5` (fusion de la vague 2) ; `v0.5.4` posé sur `main`, release publiée ; trois porteurs de version à `0.5.4` ; `dart analyze` propre ; **1480 tests** — la base de la vague (`9282513`) |
| Trois arrêts et leurs levées | Spec non convergée au troisième tour (`0a4eaa0`), au quatrième (`cf61ff8`), au cinquième (`84ff409`) ; chaque arrêt levé par le propriétaire le 03/10, reprise sans `stash` (arbre propre, `dart analyze` propre, 1480 tests verts) |
| Spec E3 | Convergée au sixième tour, `2c1d8f4` |
| E3, partie 1 | Plan `7a4f0d7` ; sept commits de code `3d58c2f`..`83cf7c7` et un correctif de la revue d'ensemble ``9b0e2e5`` ; **1535 tests** (+55), `dart analyze` propre |

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

---

## 5. Trouvé périmé, et pour la file

*Ouvert à la fin de la partie 1 ; complété à la fin de la vague.*

**Ce que le plan de la partie 1 a précisé en re-mesurant** : `HeroMiniStatsPanel._buildXpBar` recevait `dynamic stats` — l'analyseur n'aurait pas vu `xpToNextLevel` survivre à sa suppression ; il est typé `EntityStats` ; `tutorial_play_card_widget.dart` écrivait un `10` littéral et non la constante ; « *Frénésie* sur une main pleine » ne s'obtient pas par une carte qui tue, qui quitte la main avant le décompte des morts — le test passe par `RunController.onEnemyKilled()`.

**À reprendre dans le plan de la partie 2** :
- le plafond de quatre notifications de l'étape « or et XP » (S6), avec la liste complète des messages que la partie 2 y ajoute ;
- une rangée de plus gardée dans `probabilities_dialog_test.dart` (S7) ;
- pour `memory-bank-sync`, constaté par le plan : `_rules/03-4` cite `GameConstants.maxHandSize`, devenu `startingMaxHandSize` ; `_patterns/02-1` le palier stocké, désormais dérivé ; `_patterns/17-00` le chargeur, qui gagne `loadDocument`.

**Pour la file** :
- **l'écart de la section « Butin de Reliques » de la fiche des probabilités** (levée du troisième arrêt, n° 2 ; spec §5.4), antérieur à E3 et hors du lot : dès Chance 10, la fiche normalise ses quatre poids (5,71 / 14,29 / 32,38 / 47,62) quand la relique d'élite et celle de `gain_relic` se tirent en cascade sur les mêmes poids (6 / 15 / 34 / 45) ; la relique du boss « relique » se tire sur ses propres poids, qui suivent l'acte, quand le sous-titre de la section la range avec les élites et les événements ; et `probabilities_test.dart:104-126` verrouille la normalisation sur sa propre copie de la formule (`:26-54`), et non sur la fiche — à reprendre avec l'écart ;
- `DebugActions.gainLevel` peut donner deux niveaux quand le champ « XP » du menu de debug porte déjà plus de deux paliers moins un (antérieur, debug seul).
