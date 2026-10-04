---
description: Every fight finds a common card drawn from what the class may receive (one more at 25% on elites, two rare relics modulate it); max hand size becomes a run stat; a level's price is a per-act table in data; adaptive difficulty reads twice the deck's fusion-rank sum instead of its size; sharpening leaves the campfire — the XP boss, a legendary relic, an event and a mythic cap raise; a relic-trading event; Wisdom becomes mythic; Blessing and Mana Flux read their thresholds in data. Amends ADR-078 D3; completes ADR-096, ADR-097 D3, ADR-098, ADR-099 D1, ADR-101, ADR-105 D7 and ADR-106
---

# ADR-107 — Trouvaille et Progression : une Carte après Chaque Combat, la Main en Stat de Run, l'XP par Acte, la Difficulté sur les Rangs, l'Affûtage hors du Feu

### Statut

✅ Accepté — 2026-10-04 (P-43, lot **E3** ; brainstorm v3, décisions D1, D2, D11, D23, D24, D25,
D31, D42, D43, D47, D57 à D60, D62, D63 — Q15 — et D67). **Livré sur la branche
`feat/v0.5.5-p43-e3-trouvaille` — vague 3 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Spec `2c1d8f4`, convergée au
sixième tour de vérification après trois arrêts de la vague, chacun levé par le propriétaire le
2026-10-03 ; plans `7a4f0d7` (partie 1, la boucle) et `a7e0635` (partie 2, les sources) ; code
`3d58c2f`..`83cf7c7` et le correctif de revue `9b0e2e5` (partie 1), `d6924f7`..`7e29709` et le
correctif `8fc7da5` (partie 2) ; quatre commits du script de simulation `ca0ba2f`..`d8b2aef`,
référence recommitée `11410f3`.
**Amende** [ADR-078](ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md) (D3).
**Complète** [ADR-096](ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md),
[ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md) (D3),
[ADR-098](ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md),
[ADR-099](ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md) (D1),
[ADR-101](ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md),
[ADR-105](ADR-105-moteur-de-runes-data-driven.md) (D7) et
[ADR-106](ADR-106-fusion-egale-forge.md) — chacun ne change que de Statut.
Conception : [spec E3](../../docs/superpowers/specs/2026-10-03-p43-e3-trouvaille-et-progression-design.md) —
§1.2 porte les vingt-huit arbitrages A1 à A28 et les questions tranchées à chaque correction (C1 à
C5, levées des trois arrêts), avec leurs options écartées et leurs motifs, que ce fichier ne
recopie pas ; plans [partie 1](../../docs/superpowers/plans/2026-10-03-p43-e3-trouvaille-et-progression-partie-1.md)
et [partie 2](../../docs/superpowers/plans/2026-10-04-p43-e3-trouvaille-et-progression-partie-2.md) ;
arbitrages et décisions d'exécution au
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-04-economie-et-catalogue-vague-3-compte-rendu.md),
§2.

### Contexte

Jusqu'à E2 ([ADR-106](ADR-106-fusion-egale-forge.md)), la fusion donnait la rune mais restait rare :
la forge du feu avait disparu, et les doublons ne venaient que des récompenses de boss, de la
boutique et des Miroirs — un combat normal ne rapportait aucune carte. Le prix d'un niveau suivait
`100 × 1,5^(n−1)`, stocké sur le héros (`EntityStats.xpToNextLevel`) ; la difficulté adaptative
comptait les cartes du deck (`playerCardsCount × 2`), si bien qu'une carte de plus durcissait les
combats ; la main maximale était une constante (`GameConstants.maxHandSize`, ADR-078 D3), et un
testeur avait rapporté une « pioche infinie ». Le brainstorm v3 fait de la carte trouvée après
chaque combat le moteur des fusions (D1, D31), de la main une stat de run (D2, D25), de la courbe
d'XP une table par acte en donnée (D24, D58, D67), du terme de deck de la DDA la qualité du deck
(D47, D59), et sort l'affûtage du feu (D42) ; il ajoute un échange de relique (D23, D63), passe
*Sagesse* en mythique (D11) et met en donnée les seuils de deux passifs (D43, D60). Les valeurs de
D56 à D62 et de D67 sont mesurées par la simulation et livrées telles quelles.

### Décision

**La trouvaille (D1, D31, D57 ; A1, A10).**
- `GameConstants.cardDrops`, une table par `MapNodeType` à côté de `nodeQuotas` : combat, 1 carte
  garantie ; élite, 1 garantie et un jet à 25 % ; tout autre type — le boss —, aucune. Le tirage
  est une fonction pure, `CardDrops.roll` : les garanties, puis un jet par chance, l'arrêt au
  premier raté.
- Les cartes sont tirées uniformément, avec remise, par `RewardController.handleVictory` parmi
  `allCards.where((c) => c.isOfferableTo(heroClassId))` — le prédicat d'ADR-101, lu à la place de
  la carte bonus du boss « XP », qui disparaît —, **toujours communes, donc sans rune**, ajoutées au
  deck sans refus par `collectGoldAndXp`, une notification `rewardCardFound` par carte. Pool vide :
  aucune carte (ADR-101 D4).
- Deux reliques rares, en règles de run symétriques (`applyRunRuleModifier`) : la *Sacoche du
  glaneur* (+1 carte garantie en combat normal, `RunState.extraCombatCards`), le *Registre des
  primes* (+25 points sur le jet d'élite, `RunState.eliteCardChanceBonus`). La relique B n'existe
  pas (D57).

**La main (D2, D25 ; A6, A11) — amende ADR-078 D3.**
- `RunState.maxHandSize`, sérialisée, posée à `GameConstants.startingMaxHandSize` (10) par une run
  neuve, écrite par le champ « Main max » du menu de debug ; aucun accumulateur ni relique (A11).
- **Les six chemins** qui ajoutent une carte à la main la lisent, tous par `_drawInto` : la main
  d'ouverture et la pioche du tour (`TurnPhaseManager`), la carte `draw` et la rune `quick`
  (`DrawEffectStrategy`), *Frénésie* (`FrenzyPassive`), le menu de debug (`DebugActions.drawCards`).
  `DeckNotifier.startCombat` et `drawCards` gardent leur paramètre : seule la valeur passée change.
- **La « pioche infinie » n'est pas reproduite** (A6) : un test exploratoire, écrit puis supprimé,
  a fait 15 920 contrôles sur le registre réel — *Frénésie*, trois *Besaces*, douze cartes par tour,
  un deck saturé de pioche — sans jamais dépasser 10 cartes en main ni rompre la conservation des
  piles. Le testeur a vu le cyclage — la pioche qui tourne le deck plusieurs fois par tour —, ou
  joué une version antérieure à la borne. `hand_size_bound_test.dart` garde la borne sur chacun des
  six chemins, sur une main à 7.

**L'expérience (D24, D58, D67 ; A1, A8, A9, A26, A27).**
- `assets/data/xp_curve.json`, un document plat : `xpPerLevelByAct`, 115 · 200 · 310 · 480 · 590 ·
  775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015, la dernière valeur répétée
  au-delà. `XpCurveData` le refuse vide ou avec un palier sous 1 ; `GameDataLoader.loadDocument`
  le charge avec `cache: false`, accumule sa faute avec celles des entités, et **son absence fait
  échouer le démarrage**.
- **Le palier est dérivé de l'acte, jamais stocké** (A8) : `xpCurveProvider.thresholdFor(act)`, relu
  à chaque tour de la boucle de `gainXp` ; `EntityStats.xpToNextLevel` disparaît. La courbe arrive
  par un `Provider` (A9), surchargeable en test ; `GameDataRegistry.xpCurve` est optionnel (A27), et
  tout lecteur du palier lève sans elle. Le tutoriel lit `data.xpCurve!.thresholdFor(1)` sur son
  registre, et sa prose par `{xpAct1}`, `{xpAct2}` (A26).

**La difficulté adaptative (D47, D59 ; A12).** Le terme de deck de `PlayerPower` devient
**2 × Σ `fusionRank`** (`DeckState.fusionRankSum`, passé en `deckFusionRanks`) — 0 pour une
commune comme pour une signature `unique`. Les autres termes, l'`ExpectedPower` et le budget ne
changent pas ; le journal de debug écrit « Σ rangs » et « 2 × Σ rangs ».

**L'affûtage hors du feu (D42 ; A3 à A5, A13, A14, A21).**
- **Une écriture partagée** (A13) : `DeckNotifier.raiseRuneLevel(cardId, runeId, {levels,
  capBonus})`, qui refuse sans rien toucher, puis réécrit `id:n` en `id:n+k` à sa place.
  `GoldManager.sharpenRune` vérifie, paie, puis l'appelle — « payer et écrire, ou rien » tient.
- **Le boss « XP »** ne donne plus de carte : `GameConstants.bossXpRuneSharpens` (1) +
  `RunState.extraBossRuneSharpens` tirages, chacun une paire au hasard parmi
  `ForgeRuneRules.sharpenablePairs` (A14) ; sans paire, rien ne monte, `restCampSharpenNone` le dit
  (A5). `RewardState.sharpenedRunes` est `null` hors d'un boss « XP », vide sans paire (C1.1).
  L'infobulle dit « le triple » et la rune (A25).
- **La *Meule*** (légendaire) : +1 tirage par exemplaire (A3).
- **Le *Rémouleur*** (événement) : +1 niveau d'une rune que le joueur choisit, sans or, contre 10 %
  des PV max (A4, A21) — la sélection et le dialogue du feu en mode sans or (`isFree`).

**Le plafond relevé (D42(c), D72 ; A15 à A18).**
- ***Transcendance***, une mythique (`effect: raiseRuneCap`, `requires: raisableRune`) : le
  plafond d'un **type** de rune monte de 1 pour la run (`RunController.raiseRuneCap`,
  `RunState.runeCapBonus`) ; le joueur choisit parmi les runes portées à leur plafond effectif, ni
  sans plafond ni `binary` (`ForgeRuneRules.raisableCaps`).
- **`binary`** (A16) : un champ de rune, vrai sur `enduring` et `cheap`, refusé avec un `maxLevel`
  autre que 1.
- **Le bonus de plafond** (A17) : un paramètre `capBonus` nommé, optionnel, à défaut neutre, sur
  `boundLevel`, les fonctions de `ForgeRuneRules` qui le lisent et `mergeCards` ; **requis** sur
  `GoldManager.sharpenRune` et `exchangeRune`, dont `RunController` est le seul appelant. Chaque
  appelant de production passe `RunState.runeCapBonus` ; des tests en gardent chacun.
- **`nameAt`** écrit le niveau dès qu'il dépasse 1 (A18).

**Les événements (D23, D63 ; A2, A19, A20, A22).**
- Quatre actions composables, bornées au chargement : `trade_relic` (la relique visée contre
  `value × (rang + 1)` or), `heal_percent`, `lose_hp_percent`, `sharpen_rune` (valeur 1 seule
  admise, `8fc7da5`) ; une condition de choix, `requiresHpBelowPercent`. Le *Colporteur* les écrit :
  la relique la plus faible contre 40 à 200 or, ou contre 20 % des PV max sous la moitié des PV.
- La relique visée est tirée à l'ouverture (`EventState.tradedRelic`) et nommée sur les badges ;
  sans elle, « Aucune relique à céder » et les choix d'échange inactifs (A20) ; elle part par
  `RunController.loseRelic`, sa règle de run défaite.
- `EventChoice.isSelectable` reçoit deux **faits calculés**, `hasTradedRelic` et
  `hasSharpenableRune`, requis — `lib/models/` n'importe rien de `lib/game/` — ; les calcule le seul
  `EventController.isChoiceSelectable` (C4.4, C4.5).
- **Un choix fait, le retour système résout le nœud** (A22) — il rejouait un événement dans le même
  nœud.

***Sagesse* (D11, D62).** Mythique, `values.mythic: 1` ; son plateau disparaît avec ses paliers.
Neuf récompenses : cinq tirables, quatre mythiques, chacune son jet.

**Les seuils (D43, D60 ; A23, A24).** *Bénédiction* lit sa tranche dans `threshold` (5), rien sous
1 ; le bloc `mastery` gagne `floor`, 2 sur *Flux de Mana* seulement, appliqué par
`PassiveData.withMastery` — le plancher codé, inerte, disparaît. `PassiveData.describeMastery(from,
to)` dit l'écart effectif ; ses trois lecteurs reçoivent la Maîtrise effective (`currentMastery`,
requis, C1.2).

**La fiche des probabilités (C4.7, n° 7 et n° 8 des levées).** La section « Draft standard de
récompenses », qu'aucun tirage ne servait, est retirée ; la « Récompense de niveau » lit ses chances
sur `LevelUpRewardService.slotRarityChances`, les poids de `rollRarity` réunis en un seul endroit, et
nomme ses mythiques depuis la donnée (`luckLevelRewardSubtitle`). `calculateDraftProbabilities`
disparaît.

**Ce que ces décisions font aux ADR antérieurs** — chacun ne change que de Statut et lie celui-ci :

| ADR | Amendé, ou complété, ainsi |
|:---|:---|
| ADR-078 D3 | **Amendée** : `maxHandSize` n'est plus une constante mais une stat de run, `RunState.maxHandSize` ; la borne tient sur les six chemins, chacun gardé par un test ; la « pioche infinie » n'est pas reproduite. D1, D2, D4 à D7 tiennent |
| ADR-096 | Complété : le bloc `mastery` gagne `floor`, appliqué par `withMastery` ; `describeMastery` remplace `PassiveMastery.describe` |
| ADR-097 D3 | Complété : la tranche de *Bénédiction* se lit en donnée (`threshold`) |
| ADR-098 | Complété : neuf récompenses, cinq tirables ; *Sagesse* mythique sans son plateau ; l'effet `raiseRuneCap` ; `inPool` a un troisième lecteur, la fiche des probabilités |
| ADR-099 D1 | Complété : l'exigence `raisableRune` ; `isAvailableWith(passive, {hasRaisableRune = false})`, calculé par l'écran de draft sur le deck |
| ADR-101 | Complété : la trouvaille, lecteur d'`isOfferableTo` à la place de la carte bonus |
| ADR-105 D7 | Complété : `boundLevel` gagne `capBonus`, et `raiseRuneLevel` est un écrivain de plus |
| ADR-106 | Complété : `boundLevel` et ses lecteurs gagnent le bonus de plafond ; `nameAt` ; `raiseRuneLevel` partagé par le feu et les trois sources ; le plafond des notifications passe à 5 |

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| La trouvaille | `lib/game/game_constants.dart` — `CardDropRule`, `cardDrops`, `bossXpRuneSharpens`, `startingMaxHandSize` ; `lib/game/systems/card_drops.dart` ; `lib/game/controllers/reward_controller.dart` — `foundCards`, `sharpenedRunes`, `_sharpenRandomRunes` |
| Les règles de run | `lib/game/controllers/run_controller.dart` — `RunState` (cinq champs), `raiseRuneCap`, `loseRelic` ; `lib/game/controllers/run/player_stats_manager.dart` — `applyRunRuleModifier`, `gainXp`, les trois `effectType` symétriques |
| La main | `turn_phase_manager.dart`, `effects/strategies.dart` (`DrawEffectStrategy`), `passives/passive_strategies.dart` (`FrenzyPassive`), `debug_actions.dart`, `debug_run_tab.dart` |
| L'XP | `lib/models/data/xp_curve_data.dart` ; `lib/services/game_data_loader.dart` — `loadDocument` ; `lib/services/game_data_service.dart` — `xpCurveProvider` ; `lib/models/data/game_data_registry.dart` — `xpCurve` ; `assets/data/xp_curve.json` |
| La DDA | `lib/game/systems/encounter_system.dart` — `deckFusionRanks` ; `deck_controller.dart` — `fusionRankSum` ; `combat_debug_logger.dart` |
| L'affûtage et le plafond | `deck_controller.dart` — `raiseRuneLevel`, `mergeCards(…, capBonus)` ; `forge_rune_rules.dart` — `sharpenablePairs`, `raisableCaps`, `capBonus` ; `forge_upgrade_data.dart` — `binary`, `boundLevel`, `nameAt` ; `gold_manager.dart` ; `shop_controller.dart` |
| Les événements | `event_controller.dart` — `_drawTradedRelic`, `isChoiceSelectable`, les quatre actions ; `event_data.dart` — `requiresHpBelowPercent`, bornes, `isSelectable` ; `event_state.dart` — `tradedRelic` ; `event_screen.dart` |
| Les récompenses et passifs | `level_up_reward_data.dart` — `raiseRuneCap`, `raisableRune`, `describe(currentMastery)` ; `level_up_reward_service.dart` — `slotRarityChances`, `hasRaisableRune`, `isRuneCapOption` ; `passive_data.dart` — `floor`, `describeMastery` ; `draft_screen.dart` — `_showRuneCapModal` |
| Les écrans | `game_screen.dart` ; `sharpen_rune_dialog.dart`, `rest_card_selection_screen.dart` (`isFree`) ; `probabilities_dialog.dart` ; `map_node_widget.dart` ; `notification_overlay.dart` — `maxVisible = 5` |
| La donnée | `relics/bounty_ledger.json`, `gleaners_pouch.json`, `grindstone.json` ; `events/relic_peddler.json`, `wandering_grinder.json` ; `level_up_rewards/transcendence.json`, `wisdom.json` ; `passives/blessing.json`, `mana_flux.json` ; `forge_upgrades/enduring.json`, `cheap.json` |
| Tests neufs | `card_drops_test`, `hand_size_bound_test`, `xp_curve_data_test`, `notification_notifier_test`, `signature_cards_transition_test` (`test/unit/`) ; `probabilities_dialog_test`, `stats_dialog_test`, `event_screen_test` (`test/widget/`) ; cas ajoutés à `reward_controller_test`, `event_controller_test`, `deck_controller_test`, `forge_rune_rules_test`, `game_data_loader_test`, `relic_exchange_test`, `run_state_persistence_test`, `draft_screen_test` et d'autres |

### Conséquences

- ✅ **Les fusions deviennent le rythme normal** : la simulation, au réalignement et aux trois
  changements voulus, garde un deck de 35 à 36 cartes et 45 à 46 fusions à l'acte 15, le héros au
  niveau 30, deux niveaux par acte (compte rendu §4).
- ✅ **Des cartes trouvées ne rendent plus les combats plus durs** : seule la qualité du deck pèse —
  à l'acte 15, un budget de 791 contre 808 pour la formule d'avant.
- ✅ **Deux corrections au passage** : l'infobulle du boss d'XP disait « x2 » ; le retour système
  d'un événement rejouait un événement dans le même nœud. Et la fiche des probabilités ne montre
  plus de chances qu'aucun tirage n'utilise.
- ✅ **La simulation suit le jeu** : réalignement à diff vide (`ca0ba2f`) ; la relique B (`8c558bc`),
  l'événement de D29 (`2acfa6c`) et la table d'XP du jeu (`d8b2aef`) relancés chacun à part, écarts
  expliqués, référence recommitée.
- ⚠️ **Le boss « XP » ne monte rien en début de run** : le deck porte peu de runes à l'acte 1 ; les
  textes le disent d'avance, « si l'une peut encore monter ».
- ⚠️ **L'or dort** : 6 023 or en médiane à l'acte 15, contre 5 900 — le constat de P-16 se confirme.
- ⚠️ **Le bonus de plafond est optionnel à défaut neutre** sur les fonctions pures : l'analyseur ne
  désigne pas un appelant de production qui l'oublierait ; les tests le gardent, et tout écrivain de
  niveau neuf devra le lire (vagues 5 et suivantes, avec `binary` sur `retain` et `transfusion`).
- ⚠️ **À la file** (compte rendu §5) : l'écart de la section « Butin de Reliques » de la fiche des
  probabilités, antérieur à E3 ; `DebugActions.gainLevel` peut donner deux niveaux ; une garde
  dans `sharpen_rune` sans cible, inatteignable ; un placeholder `{floor}` — *Flux de Mana* écrit
  « jamais sous 2 » en dur. Le tirage de runes du boss prend un `Random()` interne, et `GameScreen`
  n'a pas de test d'écran : ses lecteurs neufs sont gardés par des commandes de contrôle.
- ⚠️ **Sauvegardes** : `RunState` gagne cinq clés relues à leur défaut, `EntityStats` perd
  `xpToNextLevel` ; rien à migrer, et rien n'est testé de ce côté — les sauvegardes sont jetables
  avant la `1.0.0`.
