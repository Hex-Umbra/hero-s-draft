# P-43 E3, partie 1 — La boucle — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ce que la run gagne à chaque combat, et ce qu'elle en mesure : chaque combat normal ou d'élite fait trouver une carte commune — une seconde à 25 % en élite —, que deux reliques rares modulent (le *Registre des primes*, la *Sacoche du glaneur*) ; la main maximale devient une stat de run ; le prix d'un niveau se lit dans une table par acte, en donnée (`assets/data/xp_curve.json`) ; la difficulté lit 2 × Σ `fusionRank` à la place du nombre de cartes ; la fiche des probabilités perd sa section « Draft standard » et lit ses chances sur le tirage. Le boss « XP », l'affûtage sans or, les événements, *Transcendance*, *Sagesse* et les seuils sont la partie 2.

**Architecture:** `GameConstants.cardDrops` (une `CardDropRule` par `MapNodeType`) est tiré par une fonction pure, `CardDrops.roll` ; `RewardController.handleVictory` en tire les cartes parmi `isOfferableTo`, communes, dans `RewardState.foundCards`, que `collectGoldAndXp` ajoute au deck et que `GameScreen` notifie (`rewardCardFound`). Les reliques A et C posent deux règles de run (`RunState.extraCombatCards`, `eliteCardChanceBonus`) par `PlayerStatsManager.applyRunRuleModifier`, défaites symétriquement. `RunState.maxHandSize` remplace `GameConstants.maxHandSize` sur les six chemins de pioche. `XpCurveData` est chargé par `GameDataLoader.loadDocument`, porté par `GameDataRegistry.xpCurve` et servi par `xpCurveProvider` ; le palier est **dérivé** de l'acte (`EntityStats.xpToNextLevel` disparaît) ; le tutoriel lit la courbe sur son registre (`TutorialEngine.xpThreshold`). `DeckState.fusionRankSum` nourrit `EncounterSystem.calculateBudget(deckFusionRanks:)`. `LevelUpRewardService.slotRarityChances` partage les poids de `rollRarity` avec la fiche des probabilités.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`, `Provider`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-03-p43-e3-trouvaille-et-progression-design.md` — §10, « Partie 1 ». À lire **en entier** : la partie 1 renvoie à §1.2 (A1 à A28, C1 à C5, les trois levées du propriétaire — tous acquis, aucun ne se rouvre ici), §3.1 à §3.3, §3.8, §4.1 à §4.5, §5.1, §5.3, §5.4, §6, §7, §8 (dont « Les titres suivent les attentes », « Et les commentaires », « Les tests qui suivent sans changer », « Le piège du montage » et les commandes de contrôle), §9 et §11. Le déroulé du programme fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (fiche §8.3). E2 est fusionné : `fusionRank`, `drawRunes`, `isOfferableTo`, `consolidate` existent, aucune tâche ne les réécrit.

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` — ou un fichier plat neuf que `pubspec.yaml` ne déclare pas encore — demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.5-p43-e3-trouvaille`, la branche courante. Il **ne crée aucune branche**, ne bascule sur aucune autre, ne commite rien sur `main`. Pas de worktree, même si le skill d'exécution en propose un.
- **`sync_assets` et le document plat.** `tool/sync_assets.dart` déclare des **dossiers** (`_directoriesWithFiles`, `sync_assets.dart:147-165`), jamais des fichiers : `assets/data/` est déjà déclaré (`pubspec.yaml:35`) parce qu'il porte `audio.json` et `patch_notes.json`. `xp_curve.json` y entre donc sans toucher `pubspec.yaml`, et les deux reliques neuves vont dans `assets/data/relics/`, déjà déclaré : **aucune tâche ne lance la régénération** ; la vérification finale lance `dart run tool/sync_assets.dart --check`, qui doit sortir en 0.
- **La base de tests : 1480**, le total de `flutter test` sur la branche le 2026-10-03 (`2c1d8f4`), relevé par une exécution complète, toute verte. Chaque tâche donne le total attendu — 1480, plus les tests qu'elle ajoute, moins ceux qu'elle retire, comptés sur les blocs `test(` et `testWidgets(` que le plan écrit (un par bloc ; un `group` ne compte pas ; un cas réécrit compte pour zéro) :

  | Tâche | Ajoutés | Retirés | Total |
  |:---|---:|---:|---:|
  | 1 — la DDA | 1 | 0 | 1481 |
  | 2 — la main | 9 | 0 | 1490 |
  | 3 — la courbe d'XP, la run | 20 | 4 | 1506 |
  | 4 — la courbe d'XP, le tutoriel | 2 | 0 | 1508 |
  | 5 — la trouvaille | 14 | 0 | 1522 |
  | 6 — les reliques A et C | 6 | 0 | 1528 |
  | 7 — la fiche des probabilités | 6 | 0 | 1534 |

  Task 3 : `xp_scaling_test.dart` perd ses quatre cas `:37-84` et en gagne sept (le palier dérivé) ; les treize autres ajouts sont des cas neufs.
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-03 sur `2c1d8f4`, dont `lib/`, `test/`, `assets/` et `tool/` égalent `9282513`, la base de la spec (`git diff --stat 9282513 HEAD -- lib test assets tool` vide). Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le périmètre : la partie 1, et elle seule** (spec §10). Rien de la partie 2 n'entre ici : ni `DeckNotifier.raiseRuneLevel`, ni `binary`, ni `RunState.runeCapBonus` ni `extraBossRuneSharpens`, ni `capBonus`, ni `GameConstants.bossXpRuneSharpens`, ni `RewardState.sharpenedRunes`, ni la *Meule*, ni les deux événements, ni *Transcendance*, ni *Sagesse* mythique, ni les seuils de *Bénédiction* et de *Flux*, ni `luckLevelRewardSubtitle`, ni l'infobulle du boss « XP ». **La carte bonus du boss « XP » reste vivante** (`rolledBonusCard`, sa notification `game_screen.dart:129-135`, le test `reward_controller_test.dart:284`) : la partie 2 la supprime.
- **La simulation** (spec §9, §10) : **aucune tâche ne touche `tool/`** — ni `tool/simulations/d26_economy_sim.dart`, ni sa référence. Le réalignement et les trois changements voulus sont la fin de la partie 2. Les reliques A et C et `xp_curve.json`, écrits ici, ne changent rien à ce que le script mesure entre les deux parties, où aucune relance ne tourne ; les deux fichiers de relique **déclarent leur `"id"`**, que le chargeur du script lit en dur (`d26_economy_sim.dart:756`). Aucune tâche ne change une valeur qu'il tient en dur, ni un autre fichier qu'il lit.
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). `RunState` gagne trois clés, relues à leur défaut si absentes ; `EntityStats` perd `xpToNextLevel`, que la lecture ignore.
- **Le tutoriel ne référence aucun provider** (ADR-081) : il lit la courbe sur son registre (`TutorialEngine.data.xpCurve!`) ; `test/tutorial/tutorial_isolation_test.dart` reste vert.
- **Les lints** (`flutter_lints` 6, qui inclut `lints/recommended`) que le code du plan respecte : `curly_braces_in_flow_control_structures` (un `if` sur plusieurs lignes prend des accolades), `use_build_context_synchronously`, `sort_child_properties_last`, `no_leading_underscores_for_local_identifiers` (aucune fonction locale en `_`) ; et l'analyseur refuse un import devenu inutile — chaque tâche qui retire le dernier lecteur d'un import retire l'import (`dart:math` de `player_stats_manager.dart`, `game_constants.dart` de quatre fichiers en Task 2).

## Review Focus

Les cinq cas que la spec implique sans qu'un test de son §8 les pose, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **Un pool de trouvaille vide** — un catalogue où la classe ne peut recevoir aucune carte (seulement des signatures et des statuts). Un tirage naïf lève sur `nextInt(0)` en pleine victoire ; attendu : aucune carte trouvée, aucune exception, le deck inchangé. Test : Task 5, `reward_controller_test.dart`, « sans carte offerte, la trouvaille ne donne rien ».
2. **Une main déjà au-delà de la borne** — le champ « Main max » du menu de debug abaissé sous la main en cours (9 cartes, borne 7). Attendu : la pioche du tour n'ajoute rien et ne retire rien. Test : Task 2, `hand_size_bound_test.dart`, « une main deja au-dela de la borne ne pioche rien et ne perd rien ».
3. **Un palier qui baisse sous l'XP accumulée** — l'acte 8 (1100) passe à 9 (1040) avec 1050 XP en poche. Attendu : rien ne se perd, le niveau se gagne au gain suivant, un seul. Test : Task 3, `xp_scaling_test.dart`, « un palier qui baisse sous l XP accumulee donne le niveau au gain suivant ».
4. **Une courbe d'XP fautive** — un `0`, un négatif, un décimal ou une liste vide dans `xp_curve.json`. Un palier nul ferait boucler `gainXp` sans fin ; attendu : le chargement refuse, en nommant le champ. Tests : Task 3, `xp_curve_data_test.dart`, les trois cas « refuse ».
5. **Un bonus d'élite au-delà de 100** — quatre *Registres des primes* portent le jet à 125. Attendu : deux cartes, jamais trois, aucune exception. Test : Task 5, `card_drops_test.dart`, « le bonus ne vaut que pour le premier jet : a 75 et au-dela de 100, toujours deux cartes ».

## Ce que le plan précise ou corrige de la spec

Constaté en re-mesurant le code sur `2c1d8f4` ; aucun point n'amende un arbitrage, aucun ne change une valeur mesurée.

1. **Le découpage en sept tâches.** La DDA (1) et la main (2) sont indépendantes. La courbe d'XP se coupe en deux tâches qui ont chacune leur lecteur de production : la run (3 — le chargement, `xpCurveProvider`, `gainXp`, les écrans) et le tutoriel (4 — son moteur, sa barre, sa prose). Entre les deux, le tutoriel garde sa propre formule, et le commentaire `tutorial_engine.dart:510-511` (« même formule que `PlayerStatsManager.gainXp` ») est faux une tâche durant : Task 4 le réécrit, dans la partie qui le rend faux (spec §8, « Et les commentaires »). La trouvaille (5) vient après la courbe : `collectGoldAndXp` appelle `gainXp`, et le conteneur de `reward_controller_test.dart` reçoit sa courbe en Task 3. Les reliques A et C (6) viennent après la trouvaille, qui lit leurs deux règles. La fiche des probabilités (7) est indépendante.
2. **`HeroMiniStatsPanel._buildXpBar` reçoit `dynamic stats`** (`hero_mini_stats_panel.dart:169`) : `dart analyze` ne verrait pas `stats.xpToNextLevel` survivre à la suppression du champ — l'erreur ne viendrait qu'à l'exécution. Task 3 type le paramètre en `EntityStats`.
3. **`tutorial_play_card_widget.dart:742-743` écrit un `10` littéral**, et non `GameConstants.maxHandSize` : ce n'est pas aujourd'hui un lecteur de la constante. Task 2 lui fait lire `GameConstants.startingMaxHandSize` (spec §5.3).
4. **« *Frénésie* sur une main pleine »** (spec §8) ne s'obtient pas par une carte qui tue : `applyPlayerCardPlay` retire la carte de la main (`combat_controller.dart:225`) avant de compter les morts (`:274`). Le test appelle `RunController.onEnemyKilled()`, qui déclenche le passif sur une main restée pleine — le chemin du menu de debug (`setEnemyHp`) et des files d'ennemis. La carte `draw` et la rune `quick`, elles, se résolvent avant que la carte quitte la main : elles se testent jouées sur une main pleine.
5. **Le `Random` de la trouvaille** est un paramètre nommé optionnel de `handleVictory`, `Random? random` (spec §4.1 : « le `Random` est passé, pour les tests ») ; `GameScreen` n'en passe pas. Les tests à tirages connus lisent `ScriptedRandom`, un `Random` à script, dans un fichier d'aide neuf, `test/unit/scripted_random.dart` (deux lecteurs : `card_drops_test`, `reward_controller_test`). Les reliques livrées se lisent par une aide neuve de `test/unit/shipped_data.dart`, `shippedRelic(id)`, sur le modèle de `shippedRune`.
6. **`CardDrops.roll` porte ses deux bonus dès Task 5** — la fonction pure et son test sont une unité (spec §4.1, §8) — ; `handleVictory` les lit en Task 6, qui crée les deux règles de run qu'ils transportent.
7. **`startNewRun` pose `maxHandSize` par le défaut du constructeur** : il construit une `RunState` neuve (`run_controller.dart:210-231`) sans passer la valeur ; aucune ligne ne s'y ajoute, le test « l écrivain » le garde.
8. **Le test de persistance de `RunState` se coupe en deux cas**, chacun dans la tâche qui ajoute ses champs : `maxHandSize` (Task 2), puis `extraCombatCards` et `eliteCardChanceBonus` (Task 6).
9. **`xp_scaling_test.dart:37-84`** : quatre cas deviennent sept (spec §8, « Le palier dérivé » : six attentes, plus « sous le palier, sans niveau », que le fichier garde aujourd'hui).
10. **Les commentaires que la partie rend faux, au-delà du minimum de la spec** (§8, « Et les commentaires », règle du n° 3) : `debug_actions.dart:65-70` et `debug_hero_tab.dart:147-148` (« le seuil d'XP se recalcule » — il est dérivé), `card_data.dart:158-159` (les pools d'offre de `isOfferableTo` gagnent la trouvaille), `player_stats_manager.dart:298-301` (le commentaire d'`increase_cards_per_turn` vaut pour les deux `effectType` neufs), `game_data_service.dart:51-52` et `game_data_loader.dart:69-70` (le registre charge aussi un document), `run_controller.dart:301-303` et `player_stats_manager.dart:110-112` (la doc de `gainXp`).
11. **`entity_id_convention_test.dart:21-22`** exclut les documents de configuration par un ensemble constant ; la condition sur trois noms tiendrait sur plusieurs lignes, où le lint `curly_braces_in_flow_control_structures` exigerait des accolades.
12. **Les deux formes laissées au plan.** `loadDocument` : `_read` est généralisé à un chemin (`String key`), et `loadAll` comme `loadDocument` l'appellent — le drapeau `cache: false` et son commentaire (`game_data_loader.dart:163-170`) restent en un seul endroit. Les poids de `rollRarity` : une fonction privée, `_slotWeights(int luck)`, qui rend un enregistrement de quatre poids ; la chance mythique reste dans `rollRarity`.
13. **Le relais `RunController.applyRunRuleModifier` (`run_controller.dart:297-299`) ne change pas** (levée du second arrêt, n° 9).

**Prémisses de la spec re-mesurées** : chaque `fichier:ligne` que la partie 1 utilise a été relu sur `2c1d8f4` et tombe juste ; les comptes cités (78 `GameDataRegistry(`, 22 lignes `playerCardsCount`, 88 fichiers d'entité, 52 fichiers de contenu audio, `ProbabilitiesDialog`, `GameScreen(`, `MapNodeWidget`, `calculateDraftProbabilities` et `gainLevel` absents de `test/`) se vérifient. **Aucune prémisse fausse** ; les points 2 à 4 ci-dessus sont des précisions.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/game/controllers/deck_controller.dart` | `DeckState.fusionRankSum` | 1 |
| `lib/game/systems/encounter_system.dart`, `lib/game/controllers/combat_controller.dart`, `lib/game/services/combat_debug_logger.dart` | `playerCardsCount` → `deckFusionRanks` ; le journal en rangs | 1 |
| `lib/ui/screens/game_screen.dart` | La DDA lit `fusionRankSum` (1) ; la notification `rewardCardFound` (5) | 1, 5 |
| `lib/game/game_constants.dart` | `startingMaxHandSize` (2) ; `CardDropRule`, `cardDrops` (5) | 2, 5 |
| `lib/game/controllers/run_controller.dart` | `RunState.maxHandSize` (2) ; `extraCombatCards`, `eliteCardChanceBonus` (6) ; la doc de `gainXp` (3) | 2, 3, 6 |
| `lib/game/controllers/combat/turn_phase_manager.dart`, `lib/game/services/effects/strategies.dart`, `lib/game/systems/passives/passive_strategies.dart` | Les chemins de pioche lisent la stat | 2 |
| `lib/game/services/debug_actions.dart` | `drawCards` lit la stat (2) ; `gainLevel` lit la courbe (3) | 2, 3 |
| `lib/ui/widgets/debug/tabs/debug_run_tab.dart` | Le champ « Main max » | 2 |
| `lib/tutorial/widgets/tutorial_play_card_widget.dart` | « Main max : » lit `startingMaxHandSize` | 2 |
| `assets/data/xp_curve.json` *(nouveau)* | La table d'XP par acte (D67) | 3 |
| `lib/models/data/xp_curve_data.dart` *(nouveau)* | `XpCurveData`, `thresholdFor` | 3 |
| `lib/services/game_data_loader.dart` | `loadDocument`, `_read` sur un chemin | 3 |
| `lib/services/game_data_service.dart` | Le chargement de la courbe ; `xpCurveProvider` | 3 |
| `lib/models/data/game_data_registry.dart` | `xpCurve` | 3 |
| `lib/game/controllers/run/player_stats_manager.dart` | `gainXp` au palier dérivé (3) ; deux accumulateurs et deux `effectType` (6) | 3, 6 |
| `lib/models/entity_stats.dart` | `xpToNextLevel` supprimé | 3 |
| `lib/ui/widgets/map/hero_mini_stats_panel.dart`, `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` | Le palier lu sur la courbe | 3 |
| `CLAUDE.md` | `xp_curve.json`, `xp_curve_data.dart` | 3 |
| `lib/tutorial/tutorial_engine.dart`, `lib/tutorial/widgets/tutorial_xp_widget.dart`, `lib/tutorial/tutorial_prose.dart`, `lib/tutorial/tutorial_screen.dart` | `xpThreshold`, `fillXpPlaceholders` | 4 |
| `lib/tutorial/tutorial_data.dart` | La prose XP (4) ; la prose des nœuds Combat et Élite (5) | 4, 5 |
| `lib/game/systems/card_drops.dart` *(nouveau)* | `CardDrops.roll` | 5 |
| `lib/game/controllers/reward_controller.dart` | `foundCards`, la trouvaille (5) ; les bonus des reliques (6) | 5, 6 |
| `lib/models/data/card_data.dart` | La doc de `fusionRank`, qui nomme ses lecteurs ; celle d'`isOfferableTo` | 1, 5 |
| `lib/tutorial/widgets/tutorial_node_types_widget.dart` | Combat et Élite | 5 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_localizations*.dart` | `rewardCardFound`, `tooltipEliteDesc` | 5 |
| `assets/data/relics/bounty_ledger.json`, `assets/data/relics/gleaners_pouch.json` *(nouveaux)* | Les reliques A et C | 6 |
| `lib/game/services/level_up_reward_service.dart` | `_slotWeights`, `slotRarityChances` | 7 |
| `lib/ui/widgets/map/dialogs/probabilities_dialog.dart` | La section retirée, les chances du tirage | 7 |
| `test/unit/deck_controller_test.dart`, `test/encounter_system_test.dart`, `test/unit/combat_debug_logger_test.dart` | La DDA | 1 |
| `test/unit/hand_size_bound_test.dart` *(nouveau)*, `test/unit/combat_controller_test.dart` | La borne de la main | 2 |
| `test/unit/run_state_persistence_test.dart` | Les clés neuves | 2, 6 |
| `test/unit/xp_curve_data_test.dart` *(nouveau)*, `test/unit/game_data_loader_test.dart`, `test/unit/xp_scaling_test.dart`, `test/unit/debug_actions_test.dart`, `test/widget/map_screen_test.dart`, `test/widget/debug_drawer_test.dart`, `test/widget/starter_deck_draft_screen_test.dart` | La courbe, le palier, ses écrans | 3 |
| `test/unit/real_bundle_load_test.dart`, `test/unit/entity_id_convention_test.dart` | La donnée livrée | 3, 6 |
| `test/unit/reward_controller_test.dart` | La courbe du conteneur (3) ; la trouvaille (5) ; les reliques (6) | 3, 5, 6 |
| `test/tutorial/tutorial_engine_test.dart`, `test/tutorial/tutorial_prose_test.dart` | Le tutoriel | 4 |
| `test/unit/scripted_random.dart` *(nouveau)*, `test/unit/card_drops_test.dart` *(nouveau)*, `test/unit/signature_cards_transition_test.dart` *(nouveau)* | La trouvaille | 5 |
| `test/unit/shipped_data.dart`, `test/unit/relic_exchange_test.dart`, `test/unit/audio/audio_catalogue_test.dart` | Les reliques livrées | 6 |
| `test/unit/probabilities_test.dart`, `test/widget/probabilities_dialog_test.dart` *(nouveau)* | La fiche | 7 |

---

### Task 1: La difficulté lit la qualité du deck — `fusionRankSum` et `deckFusionRanks`

D47, D59 (spec §4.5, A12) : le terme de deck de `PlayerPower` devient 2 × Σ `fusionRank` à la place de `playerCardsCount × 2` ; les quatre autres termes, l'`ExpectedPower` et le budget ne changent pas. `DeckState` porte la somme ; `EncounterSystem` reste une fonction pure sur des entiers, dont le paramètre est renommé `deckFusionRanks` dans `calculateBudget`, `generateEnemiesForLevel`, `CombatController.initializeCombat` et `CombatDebugLogger`. L'écran de combat passe `fusionRankSum`. Le journal de debug écrit « Σ rangs : N » et « 2 × Σ rangs ».

Changement de jeu de la tâche, voulu (spec §11) : la difficulté ne grandit plus avec la taille du deck — un deck de communes et de signatures pèse 0, quelle que soit sa taille. Avec le deck de départ (communes et signatures), le budget baisse de 2 × le nombre de cartes ; la trouvaille de Task 5 n'alourdit donc pas les combats.

**Files:**
- Modify: `lib/game/controllers/deck_controller.dart:49-55` (après `copyableCards`)
- Modify: `lib/game/systems/encounter_system.dart:93`, `:97-101`, `:220`, `:235`
- Modify: `lib/game/controllers/combat_controller.dart:49`, `:62`, `:103`, `:116`
- Modify: `lib/game/services/combat_debug_logger.dart:17`, `:62`, `:69-70`
- Modify: `lib/ui/screens/game_screen.dart:262`
- Modify: `lib/models/data/card_data.dart:34-36` (la documentation de `fusionRank`, qui nomme ses lecteurs)
- Test: `test/unit/deck_controller_test.dart:254-256` (cas neuf après `copyableCards`)
- Test: `test/encounter_system_test.dart:122`, `:139`, `:157`, `:175`, `:322`, `:536-575`
- Test: `test/unit/combat_debug_logger_test.dart:1-4`, `:8-46` (cas réécrit), `:57`

**Interfaces:**
- Consumes: `CardRarity.fusionRank` (`card_data.dart:37-43`).
- Produces:
  - `int get DeckState.fusionRankSum` — Σ `card.rarity.fusionRank` sur `masterDeck`.
  - `EncounterSystem.calculateBudget({…, required int deckFusionRanks, …})` ; `EncounterSystem.generateEnemiesForLevel(…, {…, int deckFusionRanks = 0, …})` ; `CombatController.initializeCombat(…, {…, int deckFusionRanks = 0, …})` ; `CombatDebugLogger.logCombatInitialization({…, required int deckFusionRanks, …})`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/deck_controller_test.dart`, replace:

```dart
      expect(DeckState(masterDeck: [strike, signature]).copyableCards, [strike]);
    });
  });
```

with:

```dart
      expect(DeckState(masterDeck: [strike, signature]).copyableCards, [strike]);
    });

    // Le terme de deck de la difficulte (spec P-43 E3, §4.5, A12) : la somme
    // des rangs de fusion, et non le nombre de cartes.
    test('fusionRankSum additionne les rangs de fusion du master deck', () {
      final signature = CardInstance(
        data: const CardData(
          id: 'holy_shield',
          cost: 1,
          type: CardType.skill,
          category: CardCategory.characterSpecific,
          rarity: CardRarity.unique,
          target: CardTarget.self,
          effects: [],
        ),
      );
      CardInstance strikeAt(CardRarity rarity) =>
          CardInstance(data: _card('strike').data, rarity: rarity);

      expect(const DeckState().fusionRankSum, 0);
      // Des communes et une signature `unique` : rang 0, quelle que soit la
      // taille du deck.
      expect(
        DeckState(masterDeck: [
          for (var i = 0; i < 20; i++) _card('c$i'),
          signature,
        ]).fusionRankSum,
        0,
      );
      // 1 + 2 + 3 + 4, de peu commune a legendaire ; la commune ne compte pas.
      expect(
        DeckState(masterDeck: [
          strikeAt(CardRarity.uncommon),
          strikeAt(CardRarity.rare),
          strikeAt(CardRarity.epic),
          strikeAt(CardRarity.legendary),
          _card('c'),
        ]).fusionRankSum,
        10,
      );
    });
  });
```

In `test/encounter_system_test.dart`, replace **every** occurrence (five : `:122`, `:139`, `:157`, `:175`, `:322`) of:

```dart
        playerCardsCount: 20,
```

with:

```dart
        deckFusionRanks: 20,
```

Then replace (`:536-552`):

```dart
    test('calculateBudget includes playerCardsCount in playerPower and the (act-1)*10 bonus in finalBudget', () {
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 3,
        act: 2,
        playerMaxHp: 100,
        playerMight: 0,
        playerMaxMana: 3,
        playerRelicsCount: 2,
        playerCardsCount: 10,
        isBoss: false,
        isElite: true,
      );

      // playerPower = 100 + (0*10) + (3*15) + (2*5) + (10*2) = 175
```

with:

```dart
    test('calculateBudget counts 2 x deckFusionRanks in playerPower and the (act-1)*10 bonus in finalBudget', () {
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 3,
        act: 2,
        playerMaxHp: 100,
        playerMight: 0,
        playerMaxMana: 3,
        playerRelicsCount: 2,
        deckFusionRanks: 10,
        isBoss: false,
        isElite: true,
      );

      // playerPower = 100 + (0*10) + (3*15) + (2*5) + 2 x 10 rangs = 175 :
      // dix rangs de fusion pesent 20 (spec P-43 E3, §4.5).
```

Then replace (`:563-572`):

```dart
    test('calculateBudget matches the zero-cards, act-1 baseline used elsewhere', () {
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerMight: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
        playerCardsCount: 0,
```

with:

```dart
    test('calculateBudget matches the zero-fusion-rank, act-1 baseline used elsewhere', () {
      // Un deck de communes et de signatures : zero rang, donc zero terme de
      // deck, quelle que soit sa taille.
      final budget = EncounterSystem.calculateBudget(
        playerLevel: 1,
        act: 1,
        playerMaxHp: 100,
        playerMight: 0,
        playerMaxMana: 3,
        playerRelicsCount: 0,
        deckFusionRanks: 0,
```

In `test/unit/combat_debug_logger_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/combat_debug_logger.dart';
```

with:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/combat_debug_logger.dart';
```

Then replace the first case (`:8-45`) from its title through its `returnsNormally`:

```dart
    test('logCombatInitialization executes without errors', () {
      final mockEnemy = EnemyData(
```

with:

```dart
    test('logCombatInitialization ecrit le terme de deck en rangs de fusion', () {
      // Le journal passe par `debugPrint` (`combat_debug_logger.dart:123`) :
      // on le capture pour lire ce qu'il ecrit (spec P-43 E3, §4.5, §8).
      final printed = StringBuffer();
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) =>
          printed.writeln(message);
      addTearDown(() => debugPrint = original);

      final mockEnemy = EnemyData(
```

Then, in the same case, replace:

```dart
          playerRelicsCount: 2,
          playerCardsCount: 5,
```

with:

```dart
          playerRelicsCount: 2,
          deckFusionRanks: 5,
```

Then replace the end of that same case:

```dart
          enemyDataList: [mockEnemy],
          isBoss: false,
          isElite: false,
        );
      }, returnsNormally);
    });
```

with:

```dart
          enemyDataList: [mockEnemy],
          isBoss: false,
          isElite: false,
        );
      }, returnsNormally);

      final log = printed.toString();
      expect(log, contains('Σ rangs : 5'));
      expect(log, contains('(2 × Σ rangs)'));
      expect(log, contains('(2 × 5)'));
      expect(log, isNot(contains('Cards')));
      expect(log, isNot(contains('cardsCount')));
    });
```

Then, in the second case (`:57`), replace:

```dart
          playerCardsCount: 0,
```

with:

```dart
          deckFusionRanks: 0,
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/deck_controller_test.dart test/encounter_system_test.dart test/unit/combat_debug_logger_test.dart`
Expected: FAIL à la compilation — `The getter 'fusionRankSum' isn't defined for the type 'DeckState'` et `No named parameter with the name 'deckFusionRanks'`.

- [ ] **Step 3: La somme des rangs sur `DeckState`**

In `lib/game/controllers/deck_controller.dart`, replace:

```dart
  List<CardInstance> get copyableCards =>
      masterDeck.where((card) => card.rarity.isAcquirable).toList();
```

with:

```dart
  List<CardInstance> get copyableCards =>
      masterDeck.where((card) => card.rarity.isAcquirable).toList();

  /// La somme des rangs de fusion du master deck — 0 pour une commune comme
  /// pour une signature `unique` : la difficulté en lit le double, à la place
  /// du nombre de cartes (spec P-43 E3, §4.5, A12 ; D47, D59).
  int get fusionRankSum =>
      masterDeck.fold(0, (sum, card) => sum + card.rarity.fusionRank);
```

- [ ] **Step 4: `deckFusionRanks` dans le moteur de rencontre**

In `lib/game/systems/encounter_system.dart`, replace:

```dart
    required int playerRelicsCount,
    required int playerCardsCount,
    required bool isBoss,
    required bool isElite,
  }) {
    final double playerPower = playerMaxHp +
        (playerMight * 10.0) +
        (playerMaxMana * 15.0) +
        (playerRelicsCount * 5.0) +
        (playerCardsCount * 2.0);
```

with:

```dart
    required int playerRelicsCount,
    required int deckFusionRanks,
    required bool isBoss,
    required bool isElite,
  }) {
    // Le terme de deck lit la qualité du deck, et non sa taille : deux fois
    // la somme de ses rangs de fusion (spec P-43 E3, §4.5 ; D47, D59).
    final double playerPower = playerMaxHp +
        (playerMight * 10.0) +
        (playerMaxMana * 15.0) +
        (playerRelicsCount * 5.0) +
        (deckFusionRanks * 2.0);
```

Then replace (`:220`):

```dart
    int playerRelicsCount = 0,
    int playerCardsCount = 0,
    String? bossEnemyId,
  }) {
    if (availableEnemies.isEmpty) return [];
```

with:

```dart
    int playerRelicsCount = 0,
    int deckFusionRanks = 0,
    String? bossEnemyId,
  }) {
    if (availableEnemies.isEmpty) return [];
```

Then replace (`:235`):

```dart
      playerRelicsCount: playerRelicsCount,
      playerCardsCount: playerCardsCount,
      isBoss: isBoss,
```

with:

```dart
      playerRelicsCount: playerRelicsCount,
      deckFusionRanks: deckFusionRanks,
      isBoss: isBoss,
```

In `lib/game/controllers/combat_controller.dart`, replace (`:49`):

```dart
    int playerCardsCount = 0,
```

with:

```dart
    int deckFusionRanks = 0,
```

Then replace **every** occurrence (three : `:62`, `:103`, `:116`) of:

```dart
      playerCardsCount: playerCardsCount,
```

with:

```dart
      deckFusionRanks: deckFusionRanks,
```

In `lib/game/services/combat_debug_logger.dart`, replace:

```dart
    required int playerCardsCount,
```

with:

```dart
    required int deckFusionRanks,
```

Then replace:

```dart
    buffer.writeln(buildLine('  • Max HP: ${playerMaxHp.toString().padRight(4)} Might: ${playerMight.toString().padRight(4)} Max Mana: ${playerMaxMana.toString().padRight(4)} Relics: ${playerRelicsCount.toString().padRight(4)} Cards: ${playerCardsCount.toString().padRight(4)}'));
```

with:

```dart
    buffer.writeln(buildLine('  • Max HP: ${playerMaxHp.toString().padRight(4)} Might: ${playerMight.toString().padRight(4)} Max Mana: ${playerMaxMana.toString().padRight(4)} Relics: ${playerRelicsCount.toString().padRight(4)} Σ rangs : ${deckFusionRanks.toString().padRight(4)}'));
```

Then replace:

```dart
    buffer.writeln(buildLine('  • PlayerPower formula: maxHP + (might * 10) + (maxMana * 15) + (relicsCount * 5) + (cardsCount * 2)'));
    final pPowerCalc = '    $playerMaxHp + ($playerMight * 10) + ($playerMaxMana * 15) + ($playerRelicsCount * 5) + ($playerCardsCount * 2) = $playerPower';
```

with:

```dart
    buffer.writeln(buildLine('  • PlayerPower formula: maxHP + (might * 10) + (maxMana * 15) + (relicsCount * 5) + (2 × Σ rangs)'));
    final pPowerCalc = '    $playerMaxHp + ($playerMight * 10) + ($playerMaxMana * 15) + ($playerRelicsCount * 5) + (2 × $deckFusionRanks) = $playerPower';
```

In `lib/ui/screens/game_screen.dart`, replace (`:262`):

```dart
            playerCardsCount: ref.read(deckProvider).masterDeck.length,
```

with:

```dart
            deckFusionRanks: ref.read(deckProvider).fusionRankSum,
```

La documentation de `CardRarity.fusionRank` énumère ses lecteurs ; la difficulté en devient un quatrième (vérification du plan, constat mineur). In `lib/models/data/card_data.dart`, replace:

```dart
  /// (ADR-026). `minFusionRank` le compare (`ForgeRuneRules.isEligible`), G1
  /// compte ses paliers (`scaleValue`), il borne les runes d'une pré-forgée
  /// (`ShopController`).
```

with:

```dart
  /// (ADR-026). `minFusionRank` le compare (`ForgeRuneRules.isEligible`), G1
  /// compte ses paliers (`scaleValue`), il borne les runes d'une pré-forgée
  /// (`ShopController`), et la difficulté en somme le double
  /// (`DeckState.fusionRankSum`).
```

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/deck_controller_test.dart` — Expected: `+27: All tests passed!`
Run: `flutter test test/encounter_system_test.dart` — Expected: `+25: All tests passed!`
Run: `flutter test test/unit/combat_debug_logger_test.dart` — Expected: `+2: All tests passed!`
Run: `git grep -n -e playerCardsCount -- lib test` — Expected: aucune sortie.
Run: `git grep -n -e cardsCount -- lib` — Expected: aucune sortie.
Run: `git grep -n fusionRankSum -- lib/ui/screens/game_screen.dart` — Expected: une ligne, l'argument `deckFusionRanks:` de l'appel de la DDA.

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1481: All tests passed!` (1480 + 1 : `fusionRankSum`).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/controllers/deck_controller.dart lib/game/systems/encounter_system.dart lib/game/controllers/combat_controller.dart lib/game/services/combat_debug_logger.dart lib/ui/screens/game_screen.dart lib/models/data/card_data.dart test/unit/deck_controller_test.dart test/encounter_system_test.dart test/unit/combat_debug_logger_test.dart
git commit -F- <<'EOF'
feat(dda): la difficulte lit les rangs de fusion du deck, et non sa taille

Le terme de deck de PlayerPower devient deux fois la somme des rangs de
fusion : une commune et une signature pesent zero. DeckState porte la
somme, EncounterSystem la recoit sous le nom deckFusionRanks, et le
journal de debug ecrit la formule en rangs.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: La main maximale devient une stat de run — `RunState.maxHandSize` et ses six lecteurs

D2, D25 (spec §4.3, A6, A11) : `GameConstants.maxHandSize` devient `startingMaxHandSize`, la valeur de départ d'une stat de run ; `RunState.maxHandSize` est sérialisée et lue par les six chemins qui ajoutent une carte à la main — la main d'ouverture, la pioche du tour, la carte `draw`, la rune `quick` (même stratégie), *Frénésie*, le menu de debug. `DeckNotifier.startCombat` et `drawCards` gardent leur paramètre : seule la valeur passée change. Le menu de debug gagne « Main max » ; la phrase de rappel du tutoriel lit la valeur de départ. Aucun accumulateur, aucune relique (A11). Un test garde la borne sur chacun des six chemins.

Changement de jeu de la tâche : aucun — la valeur reste 10 ; elle change de place.

**Files:**
- Modify: `lib/game/game_constants.dart:33-36`
- Modify: `lib/game/controllers/run_controller.dart:11` (import), `:33-36` (champ), `:73-74`, `:87-88`, `:101`, `:117`, `:152`
- Modify: `lib/game/controllers/combat/turn_phase_manager.dart:13`, `:40`, `:56`
- Modify: `lib/game/services/effects/strategies.dart:12`, `:152`
- Modify: `lib/game/systems/passives/passive_strategies.dart:6`, `:219`
- Modify: `lib/game/services/debug_actions.dart:14`, `:88-93`
- Modify: `lib/ui/widgets/debug/tabs/debug_run_tab.dart:51-58`
- Modify: `lib/tutorial/widgets/tutorial_play_card_widget.dart:1-8` (import), `:741-743`
- Test: `test/unit/hand_size_bound_test.dart` *(nouveau)*
- Test: `test/unit/run_state_persistence_test.dart:1-7` (import), `:76-77` (cas neuf)
- Test: `test/unit/combat_controller_test.dart:364`, `:511`, `:704`, `:726`

**Interfaces:**
- Consumes: `DeckNotifier.startCombat({required int handSize, required int maxHandSize})`, `DeckNotifier.drawCards(int amount, {required int maxHandSize})` (`deck_controller.dart:158`, `:218`, inchangés) ; `shippedRuneRegistry` (`test/unit/shipped_data.dart`).
- Produces:
  - `GameConstants.startingMaxHandSize` (`static const int`, 10) — `GameConstants.maxHandSize` n'existe plus.
  - `RunState.maxHandSize` (`int`, défaut `GameConstants.startingMaxHandSize`) ; `RunState.copyWith({…, int? maxHandSize, …})` ; clé JSON `maxHandSize`, absente → `startingMaxHandSize`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/hand_size_bound_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/debug_run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/services/debug_actions.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

import 'shipped_data.dart';

/// La borne de la main sur chacun des six chemins qui ajoutent une carte à
/// la main (spec P-43 E3, §4.3, A6, A11) : la main d'ouverture, la pioche du
/// tour, une carte `draw`, la rune `quick`, *Frénésie*, le menu de debug.
///
/// La borne vaut ici 7, et non la main de départ (10) : un chemin qui lirait
/// encore une constante piocherait au-delà. Chaque cas vérifie aussi la
/// conservation des piles — rien ne se perd, rien ne se double.
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );
  const berserker = HeroData(
    id: 'berserker',
    classCard: 'berserker.png',
    maxHp: 80,
    maxMana: 3,
  );

  /// *Frénésie*, qui fait piocher trois cartes par ennemi abattu.
  const frenzy = PassiveData(
    id: 'frenzy',
    trigger: RelicTrigger.onEnemyKilled,
    effectType: 'frenzy',
    value: 2,
    duration: 1,
    draw: 3,
  );

  /// Une carte sans effet, gratuite, qui ne vise que le héros.
  CardInstance filler(String id) => CardInstance(
        data: CardData(
          id: id,
          cost: 0,
          type: CardType.skill,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.self,
          effects: const [],
        ),
      );

  List<CardInstance> fillers(String prefix, int count) =>
      [for (var i = 0; i < count; i++) filler('${prefix}_$i')];

  late ProviderContainer container;
  late RunController run;
  late DeckNotifier deck;
  late CombatController combat;

  setUp(() {
    // La rune `quick` telle que le jeu la livre : `EffectiveCard` lit le
    // catalogue du registre.
    shippedRuneRegistry(const ['quick']);
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    deck = container.read(deckProvider.notifier);
    combat = container.read(combatProvider.notifier);
  });

  tearDown(() => container.dispose());

  /// Une run de [hero] dont la main maximale vaut 7.
  void startRun({
    HeroData hero = paladin,
    PassiveData? passive,
    int cardsPerTurn = 5,
    bool debug = false,
  }) {
    // Avant `startNewRun` : c'est lui qui rend effectif le mode demandé.
    if (debug) container.read(debugRunProvider.notifier).requestDebugRun();
    run.startNewRun(hero, passive);
    run.updateState(
      run.currentState.copyWith(maxHandSize: 7, cardsPerTurn: cardsPerTurn),
    );
  }

  /// Pose [hand] en main et [drawPile] en pioche ; le deck est les deux.
  void seedPiles(List<CardInstance> hand, List<CardInstance> drawPile) {
    deck.initializeStarterDeck([...hand, ...drawPile]);
    deck.state = deck.state.copyWith(
      hand: hand,
      drawPile: drawPile,
      discardPile: const [],
      exhaustPile: const [],
    );
  }

  DeckState piles() => container.read(deckProvider);

  /// La conservation : pioche + main + défausse + épuisement = deck.
  void expectConserved() {
    final s = piles();
    expect(
      s.drawPile.length +
          s.hand.length +
          s.discardPile.length +
          s.exhaustPile.length,
      s.masterDeck.length,
    );
  }

  test('la main d ouverture s arrete a la borne', () {
    startRun(cardsPerTurn: 9);
    deck.initializeStarterDeck(fillers('c', 12));

    combat.startPlayerCombat();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('la pioche du tour s arrete a la borne', () {
    startRun();
    deck.initializeStarterDeck(fillers('c', 12));
    combat.startPlayerCombat();
    expect(piles().hand, hasLength(5));

    combat.startPlayerTurn();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('une carte draw jouee sur une main pleine ne pioche rien', () {
    startRun();
    final drawThree = CardInstance(
      data: const CardData(
        id: 'draw_three',
        cost: 0,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [CardEffect(type: 'draw', value: 3)],
      ),
    );
    seedPiles([drawThree, ...fillers('h', 6)], fillers('p', 5));

    // L'effet se résout avant que la carte quitte la main : la main est
    // pleine, à 7, quand la carte pioche.
    combat.applyPlayerCardPlay(drawThree);

    expect(piles().hand, hasLength(6));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('la rune quick jouee sur une main pleine ne pioche rien', () {
    startRun();
    final swift = CardInstance(
      data: const CardData(
        id: 'swift',
        cost: 0,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: [],
      ),
      rarity: CardRarity.rare,
      forgeUpgrades: const ['quick:1'],
    );
    // La rune ajoute bien une pioche : sans la borne, la carte piocherait.
    expect(swift.effective.addedEffects.map((e) => e.type), ['draw']);
    seedPiles([swift, ...fillers('h', 6)], fillers('p', 5));

    combat.applyPlayerCardPlay(swift);

    expect(piles().hand, hasLength(6));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('Frenesie sur une main pleine ne pioche rien', () {
    startRun(hero: berserker, passive: frenzy);
    seedPiles(fillers('h', 7), fillers('p', 5));

    // Un ennemi abattu sans carte jouee — la file d'ennemis, le menu de
    // debug : une carte qui tue a deja quitte la main quand les morts se
    // comptent (`combat_controller.dart:225`, `:274`).
    run.onEnemyKilled();

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('le menu de debug pioche jusqu a la borne', () {
    startRun(debug: true);
    seedPiles(fillers('h', 5), fillers('p', 7));

    DebugActions.drawCards(container.read, 5);

    expect(piles().hand, hasLength(7));
    expect(piles().drawPile, hasLength(5));
    expectConserved();
  });

  test('une main deja au-dela de la borne ne pioche rien et ne perd rien', () {
    // Le champ « Main max » du menu de debug abaisse la borne sous la main en
    // cours : la pioche suivante n'ajoute rien, et ne retire rien.
    startRun();
    seedPiles(fillers('h', 9), fillers('p', 3));

    combat.startPlayerTurn();

    expect(piles().hand, hasLength(9));
    expect(piles().drawPile, hasLength(3));
    expectConserved();
  });

  test('startNewRun pose la main de depart : apres une run a 7, la suivante '
      'repart a 10', () {
    expect(GameConstants.startingMaxHandSize, 10);
    expect(run.currentState.maxHandSize, GameConstants.startingMaxHandSize);
    startRun();
    expect(run.currentState.maxHandSize, 7);

    run.startNewRun(paladin);

    expect(run.currentState.maxHandSize, GameConstants.startingMaxHandSize);
  });
}
```

In `test/unit/run_state_persistence_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
```

Then replace:

```dart
      final legacy = Map<String, dynamic>.from(json)..remove('cardsPerTurn');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.cardsPerTurn, 5);
    });
```

with:

```dart
      final legacy = Map<String, dynamic>.from(json)..remove('cardsPerTurn');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.cardsPerTurn, 5);
    });

    // La main maximale, stat de run (spec P-43 E3, §4.3, §8).
    test('maxHandSize round-trip et vaut la main de depart quand la cle '
        'manque', () {
      final json = buildRunState().copyWith(maxHandSize: 7).toJson();
      expect(json['maxHandSize'], 7);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.maxHandSize, 7);

      final legacy = Map<String, dynamic>.from(json)..remove('maxHandSize');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.maxHandSize, GameConstants.startingMaxHandSize);
    });
```

In `test/unit/combat_controller_test.dart`, replace **every** occurrence (four : `:364`, `:511`, `:704`, `:726`) of:

```dart
GameConstants.maxHandSize
```

with:

```dart
GameConstants.startingMaxHandSize
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/hand_size_bound_test.dart test/unit/run_state_persistence_test.dart test/unit/combat_controller_test.dart`
Expected: FAIL à la compilation — `The getter 'startingMaxHandSize' isn't defined for the type 'GameConstants'` et `No named parameter with the name 'maxHandSize'`.

- [ ] **Step 3: La constante renommée**

In `lib/game/game_constants.dart`, replace:

```dart
  // --- DECK RULES ---
  /// Nombre maximum de cartes en main. Au-delà, la pioche s'interrompt sans
  /// consommer de carte ni déclencher de remélange (règle « arrêt net »).
  static const int maxHandSize = 10;
```

with:

```dart
  // --- DECK RULES ---
  /// La main maximale au début d'une run (D25) : la stat vit sur
  /// `RunState.maxHandSize`, que lisent les six chemins de pioche — au-delà,
  /// la pioche s'interrompt sans consommer de carte ni déclencher de
  /// remélange (règle « arrêt net »). Aucun chemin de pioche ne lit cette
  /// valeur-ci.
  static const int startingMaxHandSize = 10;
```

- [ ] **Step 4: La stat sur `RunState`**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
import '../../services/map_generator_service.dart';
```

with:

```dart
import '../../services/map_generator_service.dart';
import '../game_constants.dart';
```

Then replace:

```dart
  final int cardsPerTurn;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
```

with:

```dart
  final int cardsPerTurn;

  /// La main maximale (spec P-43 E3, §4.3 ; D2, D25) : toute pioche s'arrête
  /// à elle. Une stat de run, propre au joueur comme [cardsPerTurn] :
  /// `GameConstants.startingMaxHandSize` au départ, par le défaut du
  /// constructeur — `startNewRun` construit une run neuve —, et le menu de
  /// debug l'écrit. Aucune relique ne la modifie encore (A11).
  final int maxHandSize;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
```

Then replace:

```dart
    this.cardsPerTurn = 5,
    this.statRules = const [],
  });
```

with:

```dart
    this.cardsPerTurn = 5,
    this.maxHandSize = GameConstants.startingMaxHandSize,
    this.statRules = const [],
  });
```

Then replace:

```dart
    int? cardsPerTurn,
    List<StatRule>? statRules,
  }) {
```

with:

```dart
    int? cardsPerTurn,
    int? maxHandSize,
    List<StatRule>? statRules,
  }) {
```

Then replace:

```dart
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
```

with:

```dart
      cardsPerTurn: cardsPerTurn ?? this.cardsPerTurn,
      maxHandSize: maxHandSize ?? this.maxHandSize,
```

Then replace:

```dart
        'cardsPerTurn': cardsPerTurn,
      };
```

with:

```dart
        'cardsPerTurn': cardsPerTurn,
        'maxHandSize': maxHandSize,
      };
```

Then replace:

```dart
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
```

with:

```dart
      cardsPerTurn: json['cardsPerTurn'] as int? ?? 5,
      maxHandSize:
          json['maxHandSize'] as int? ?? GameConstants.startingMaxHandSize,
```

- [ ] **Step 5: Les six chemins lisent la stat**

In `lib/game/controllers/combat/turn_phase_manager.dart`, delete the line:

```dart
import '../../game_constants.dart';
```

Then replace:

```dart
    deckController.startCombat(
      handSize: runController.currentState.cardsPerTurn,
      maxHandSize: GameConstants.maxHandSize,
    );
```

with:

```dart
    deckController.startCombat(
      handSize: runController.currentState.cardsPerTurn,
      maxHandSize: runController.currentState.maxHandSize,
    );
```

Then replace:

```dart
    ref.read(deckProvider.notifier).drawCards(
          runController.currentState.cardsPerTurn,
          maxHandSize: GameConstants.maxHandSize,
        );
```

with:

```dart
    ref.read(deckProvider.notifier).drawCards(
          runController.currentState.cardsPerTurn,
          maxHandSize: runController.currentState.maxHandSize,
        );
```

In `lib/game/services/effects/strategies.dart`, delete the line:

```dart
import '../../game_constants.dart';
```

Then replace:

```dart
    deckController.drawCards(scaledValue, maxHandSize: GameConstants.maxHandSize);
```

with:

```dart
    // La carte `draw` et la rune `quick` (un `addEffect draw`) passent toutes
    // deux ici : la borne est la stat de run (spec P-43 E3, §4.3).
    deckController.drawCards(
      scaledValue,
      maxHandSize: runController.currentState.maxHandSize,
    );
```

In `lib/game/systems/passives/passive_strategies.dart`, delete the line:

```dart
import '../../game_constants.dart';
```

Then replace:

```dart
          .drawCards(passive.draw, maxHandSize: GameConstants.maxHandSize);
```

with:

```dart
          .drawCards(passive.draw, maxHandSize: run.currentState.maxHandSize);
```

In `lib/game/services/debug_actions.dart`, delete the line:

```dart
import '../game_constants.dart';
```

Then replace:

```dart
    read(
      deckProvider.notifier,
    ).drawCards(amount, maxHandSize: GameConstants.maxHandSize);
```

with:

```dart
    read(
      deckProvider.notifier,
    ).drawCards(amount, maxHandSize: read(runProvider).maxHandSize);
```

- [ ] **Step 6: Le champ de debug et la phrase du tutoriel**

In `lib/ui/widgets/debug/tabs/debug_run_tab.dart`, replace:

```dart
        DebugNumberField(
          label: 'Cartes par tour',
          value: run.cardsPerTurn,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(cardsPerTurn: v),
          ),
        ),
```

with:

```dart
        DebugNumberField(
          label: 'Cartes par tour',
          value: run.cardsPerTurn,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(cardsPerTurn: v),
          ),
        ),
        DebugNumberField(
          label: 'Main max',
          value: run.maxHandSize,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(maxHandSize: v),
          ),
        ),
```

In `lib/tutorial/widgets/tutorial_play_card_widget.dart`, replace:

```dart
import '../../models/card_instance.dart';
```

with:

```dart
import '../../game/game_constants.dart';
import '../../models/card_instance.dart';
```

Then replace:

```dart
                    isFrench
                        ? 'Pioche : 5 cartes par tour · Main max : 10'
                        : 'Draw: 5 cards per turn · Max hand: 10',
```

with:

```dart
                    isFrench
                        ? 'Pioche : 5 cartes par tour · Main max : '
                            '${GameConstants.startingMaxHandSize}'
                        : 'Draw: 5 cards per turn · Max hand: '
                            '${GameConstants.startingMaxHandSize}',
```

- [ ] **Step 7: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/hand_size_bound_test.dart` — Expected: `+8: All tests passed!`
Run: `flutter test test/unit/run_state_persistence_test.dart` — Expected: `+4: All tests passed!`
Run: `flutter test test/unit/combat_controller_test.dart test/unit/passives_berserker_test.dart test/unit/deck_controller_test.dart test/unit/debug_actions_test.dart test/tutorial/` — Expected: `All tests passed!`
Run: `git grep -n "GameConstants.maxHandSize" -- lib test` — Expected: aucune sortie.
Run: `git grep -n "maxHandSize: GameConstants" -- lib` — Expected: aucune sortie.

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1490: All tests passed!` (1481 + 9 : la borne +8, la persistance +1).

- [ ] **Step 9: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/game_constants.dart lib/game/controllers/run_controller.dart lib/game/controllers/combat/turn_phase_manager.dart lib/game/services/effects/strategies.dart lib/game/systems/passives/passive_strategies.dart lib/game/services/debug_actions.dart lib/ui/widgets/debug/tabs/debug_run_tab.dart lib/tutorial/widgets/tutorial_play_card_widget.dart test/unit/hand_size_bound_test.dart test/unit/run_state_persistence_test.dart test/unit/combat_controller_test.dart
git commit -F- <<'EOF'
feat(main): la main maximale devient une stat de run

RunState porte maxHandSize, posee a GameConstants.startingMaxHandSize au
depart et ecrite par le menu de debug. Les six chemins qui ajoutent une
carte a la main la lisent : main d ouverture, pioche du tour, carte draw,
rune quick, Frenesie, menu de debug. Un test garde la borne sur chacun.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: La courbe d'XP en donnée — `xp_curve.json`, `xpCurveProvider`, le palier dérivé de l'acte

D24, D58, D67 (spec §3.2, §4.4, A1, A8, A9, A27) : la table par acte vit dans `assets/data/xp_curve.json`, un document plat à côté d'`audio.json` ; `XpCurveData` la lit et la valide (liste non vide d'entiers ≥ 1) ; `GameDataLoader.loadDocument` la charge par le `bundle`, `cache: false`, son erreur accumulée avec celles des entités — **à la différence d'`audio.json`, la courbe fait échouer le démarrage**. `GameDataRegistry.xpCurve` est optionnelle (A27) ; `xpCurveProvider` la sert, et lève une `StateError` explicite sans elle. Le palier n'est plus stocké : `gainXp` relit `thresholdFor(acte)` à chaque niveau, `EntityStats.xpToNextLevel` disparaît avec ses lecteurs — la barre d'XP de la carte du monde, le libellé « XP (seuil N) » et « Gagner un niveau » du menu de debug. Les tests qui lisent le palier reçoivent une courbe (« Le piège du montage »). `CLAUDE.md` nomme le document et son modèle.

Changement de jeu de la tâche, voulu (spec §11) : un niveau coûte 115 XP à l'acte 1, 200 à l'acte 2, … 1015 à l'acte 15 et au-delà — de quoi gagner deux niveaux par acte —, au lieu de 100 × 1,5^(niveau − 1). Le tutoriel garde sa propre formule jusqu'à Task 4.

**Files:**
- Create: `assets/data/xp_curve.json`
- Create: `lib/models/data/xp_curve_data.dart`
- Modify: `lib/services/game_data_loader.dart:69-75`, `:97-104`, `:161-183`
- Modify: `lib/services/game_data_service.dart:12-15`, `:51-52`, `:134-153`, après `:162`
- Modify: `lib/models/data/game_data_registry.dart:8-9`, `:24-26`, `:39-40`
- Modify: `lib/game/controllers/run/player_stats_manager.dart:1`, `:11`, `:110-144`
- Modify: `lib/game/controllers/run_controller.dart:301-303`
- Modify: `lib/models/entity_stats.dart:18`, `:36`, `:55`, `:73`, `:103`, `:126`
- Modify: `lib/ui/widgets/map/hero_mini_stats_panel.dart:1-5`, `:12-13`, `:163`, `:169-182`
- Modify: `lib/ui/widgets/debug/tabs/debug_hero_tab.dart:1-10`, `:21-22`, `:141-148`
- Modify: `lib/game/services/debug_actions.dart:1-13` (import), `:65-76`
- Modify: `CLAUDE.md:43`, `:76`
- Test: `test/unit/xp_curve_data_test.dart` *(nouveau)*
- Test: `test/unit/game_data_loader_test.dart` (groupe neuf en fin de fichier)
- Test: `test/unit/real_bundle_load_test.dart:70-72`, après `:111` (cas neuf)
- Test: `test/unit/entity_id_convention_test.dart:14-25`
- Test: `test/unit/xp_scaling_test.dart:1-85` (le premier groupe réécrit)
- Test: `test/unit/reward_controller_test.dart:1-15` (imports), `:113-115`
- Test: `test/unit/debug_actions_test.dart:1-16` (imports), `:30-36`, après `:88` (cas neuf)
- Test: `test/widget/map_screen_test.dart:1-31`, `:49`, `:115`, `:162`, `:209`, `:276`, fin de fichier (cas neuf)
- Test: `test/widget/debug_drawer_test.dart:1-20` (imports), `:126-131`, fin de fichier (cas neuf)
- Test: `test/widget/starter_deck_draft_screen_test.dart:1-15` (import), `:192-200`

**Interfaces:**
- Consumes: `RunState.act` ; `RunController.updateState(RunState)` ; `RefReader` (`save_service.dart:18`).
- Produces:
  - `class XpCurveData` (`lib/models/data/xp_curve_data.dart`) : `const XpCurveData(List<int> xpPerLevelByAct)` ; `final List<int> xpPerLevelByAct` ; `int thresholdFor(int act)` — `xpPerLevelByAct[min(max(act, 1), length) − 1]` ; `factory XpCurveData.fromJson(Map<String, dynamic> json)` — `FormatException` dont le message nomme `xpPerLevelByAct` si la liste manque, est vide, ou porte une valeur non entière ou inférieure à 1.
  - `Future<T?> GameDataLoader.loadDocument<T>(String path, T Function(Map<String, dynamic>) fromJson)` — `null` sur une erreur, accumulée.
  - `final XpCurveData? GameDataRegistry.xpCurve` (paramètre nommé optionnel `xpCurve`).
  - `final xpCurveProvider = Provider<XpCurveData>(…)` dans `lib/services/game_data_service.dart`.
  - `EntityStats` sans `xpToNextLevel` (ni champ, ni paramètre, ni clé JSON).

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/xp_curve_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';

/// La courbe d'XP (spec P-43 E3, §3.2, §8 ; D24, D58, D67).
void main() {
  const d67 = [
    115, 200, 310, 480, 590, 775, 955, 1100, //
    1040, 1185, 1370, 1370, 1300, 1375, 1015,
  ];

  Matcher refused() => throwsA(
        isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('xpPerLevelByAct'),
        ),
      );

  test('lit la table par acte : 115 a l acte 1, 1015 a l acte 15', () {
    final curve = XpCurveData.fromJson({'xpPerLevelByAct': d67});

    expect(curve.xpPerLevelByAct, d67);
    expect(curve.thresholdFor(1), 115);
    expect(curve.thresholdFor(15), 1015);
  });

  test('au-dela de la table, la derniere valeur ; en dessous de l acte 1, '
      'la premiere', () {
    final curve = XpCurveData.fromJson({'xpPerLevelByAct': d67});

    expect(curve.thresholdFor(16), 1015);
    expect(curve.thresholdFor(40), 1015);
    expect(curve.thresholdFor(0), 115);
  });

  test('refuse une table absente ou vide', () {
    expect(() => XpCurveData.fromJson(const {}), refused());
    expect(
      () => XpCurveData.fromJson(const {'xpPerLevelByAct': []}),
      refused(),
    );
  });

  test('refuse un palier nul ou negatif : gainXp bouclerait sans fin', () {
    for (final bad in [0, -5]) {
      expect(
        () => XpCurveData.fromJson({
          'xpPerLevelByAct': [115, bad],
        }),
        refused(),
        reason: '$bad',
      );
    }
  });

  test('refuse un palier non entier', () {
    for (final bad in <Object?>[115.5, '115', null]) {
      expect(
        () => XpCurveData.fromJson({
          'xpPerLevelByAct': [bad],
        }),
        refused(),
        reason: '$bad',
      );
    }
  });
}
```

In `test/unit/game_data_loader_test.dart`, replace the end of the file:

```dart
    test('sans erreur, throwIfFailed ne leve pas', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));
      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      loader.throwIfFailed();
    });
  });
}
```

with:

```dart
    test('sans erreur, throwIfFailed ne leve pas', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/a.json': '{"id":"a","label":"A"}',
      }));
      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      loader.throwIfFailed();
    });
  });

  // Un document plat, comme `xp_curve.json` (spec P-43 E3, §3.2) : ni motif,
  // ni injection, ni id — et son erreur fait echouer le chargement avec
  // celles des entites.
  group('GameDataLoader — document plat', () {
    test('un document present est lu, sans erreur', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{"id":"curve","label":"Courbe"}',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      loader.throwIfFailed();
      expect(thing?.label, 'Courbe');
    });

    test('un document absent rend null, et son erreur remonte avec celles '
        'des entites, en une fois', () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/things/casse.json': '{ pas du json',
      }));

      await loader.loadAll<Thing>([
        EntitySource('assets/data/things/*.json', Thing.fromJson),
      ]);
      final missing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(missing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) {
          final message = e.toString();
          return message.contains('2 erreur(s)') &&
              message.contains('curve.json') &&
              message.contains('casse.json');
        })),
      );
    });

    test('un document illisible rend null et son erreur est accumulee',
        () async {
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{ ceci n est pas du json',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(thing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) => e.toString().contains('curve.json'))),
      );
    });

    test('un fromJson qui leve rend null et son erreur est accumulee',
        () async {
      // `Thing.fromJson` exige un `label` : son absence leve.
      final loader = GameDataLoader(FakeBundle({
        'assets/data/curve.json': '{"id":"curve"}',
      }));

      final thing =
          await loader.loadDocument('assets/data/curve.json', Thing.fromJson);

      expect(thing, isNull);
      expect(
        () => loader.throwIfFailed(),
        throwsA(predicate((e) => e.toString().contains('curve.json'))),
      );
    });
  });
}
```

In `test/unit/real_bundle_load_test.dart`, replace:

```dart
    // Les deux documents de configuration restent a plat.
    expect(json, contains('assets/data/audio.json'));
    expect(json, contains('assets/data/patch_notes.json'));
  });
```

with:

```dart
    // Les trois documents de configuration restent a plat.
    expect(json, contains('assets/data/audio.json'));
    expect(json, contains('assets/data/patch_notes.json'));
    expect(json, contains('assets/data/xp_curve.json'));
  });
```

Then replace the end of the file:

```dart
    final ids = registry.relics.map((r) => r.id).toList();
    expect(ids, orderedEquals(List<String>.of(ids)..sort()));
  });
}
```

with:

```dart
    final ids = registry.relics.map((r) => r.id).toList();
    expect(ids, orderedEquals(List<String>.of(ids)..sort()));
  });

  // La table de D67, valeur par valeur (spec P-43 E3, §3.2, §8).
  test('la courbe d XP livree est celle de D67', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.xpCurve, isNotNull);
    expect(registry.xpCurve!.xpPerLevelByAct, [
      115, 200, 310, 480, 590, 775, 955, 1100, //
      1040, 1185, 1370, 1370, 1300, 1375, 1015,
    ]);
  });
}
```

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
const _pattern = r'^[a-z0-9_]+$';

Iterable<File> _entityFiles() sync* {
  for (final entity in Directory('assets/data').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last;
    // Les deux documents de configuration ne sont pas des entites.
    if (name == 'patch_notes.json' || name == 'audio.json') continue;
    yield entity;
  }
}
```

with:

```dart
const _pattern = r'^[a-z0-9_]+$';

/// Les trois documents de configuration, a plat dans `assets/data/` : ce ne
/// sont pas des entites (spec P-43 E3, §3.2, §8).
const _configDocuments = {'patch_notes.json', 'audio.json', 'xp_curve.json'};

Iterable<File> _entityFiles() sync* {
  for (final entity in Directory('assets/data').listSync(recursive: true)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.json')) continue;
    final name = entity.uri.pathSegments.last;
    if (_configDocuments.contains(name)) continue;
    yield entity;
  }
}
```

Replace the whole first group of `test/unit/xp_scaling_test.dart` — the imports and everything from `void main() {` through the closing `});` of `group('XP and Level Up Unit Tests', …)` (`:1-85`) — with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// La courbe de D67, écrite ici et non lue dans le fichier : ces cas gardent
/// la règle du palier ; `real_bundle_load_test.dart` garde la donnée livrée.
const _d67 = XpCurveData([
  115, 200, 310, 480, 590, 775, 955, 1100, //
  1040, 1185, 1370, 1370, 1300, 1375, 1015,
]);

void main() {
  // Le palier est dérivé de l'acte, jamais stocké (spec P-43 E3, §4.4, A8).
  group('XP and Level Up Unit Tests', () {
    late ProviderContainer container;
    late RunController runController;

    final testHero = HeroData(
      id: 'paladin',
      nameEn: 'Paladin',
      nameFr: 'Paladin',
      descriptionEn: 'Holy knight',
      descriptionFr: 'Chevalier sacre',
      classCard: 'paladin.png',
      maxHp: 80,
      maxMana: 3,
      luck: 1,
      mastery: 0,
    );

    setUp(() {
      // Un conteneur nu : la courbe est surchargée, le chargeur jamais lu
      // (spec P-43 E3, §8, « Le piège du montage »).
      container = ProviderContainer(
        overrides: [xpCurveProvider.overrideWithValue(_d67)],
      );
      runController = container.read(runProvider.notifier);
      runController.startNewRun(testHero);
    });

    tearDown(() {
      container.dispose();
    });

    /// Place la run à l'acte [act], sans régénérer la carte.
    void moveToAct(int act) => runController.updateState(
          runController.currentState.copyWith(act: act),
        );

    test('au depart : niveau 1, 0 XP, et le palier de l acte 1 vaut 115', () {
      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 0);
      expect(
        container
            .read(xpCurveProvider)
            .thresholdFor(runController.currentState.act),
        115,
      );
    });

    test('gainXp ajoute l XP sous le palier, sans niveau', () {
      expect(runController.gainXp(114), isFalse);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 1);
      expect(stats.xp, 114);
      expect(runController.currentState.pendingDrafts, 0);
    });

    test('gainXp passe un niveau au palier de l acte et reporte l excedent',
        () {
      expect(runController.gainXp(120), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 5); // 120 - 115
      expect(runController.currentState.pendingDrafts, 1);
    });

    test('plusieurs niveaux d un coup, au palier de l acte a chaque niveau',
        () {
      // 260 = 115 + 115 + 30 : le palier ne grandit plus avec le niveau.
      expect(runController.gainXp(260), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 3);
      expect(stats.xp, 30);
      expect(runController.currentState.pendingDrafts, 2);
    });

    test('le palier suit l acte courant', () {
      moveToAct(2);

      expect(runController.gainXp(199), isFalse); // 200 a l acte 2
      expect(runController.gainXp(1), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 0);
    });

    test('un palier qui baisse sous l XP accumulee donne le niveau au gain '
        'suivant', () {
      moveToAct(8);
      expect(runController.gainXp(1050), isFalse); // 1100 a l acte 8

      moveToAct(9);
      // Changer d'acte ne fait rien gagner : le palier n'est lu qu'au gain.
      expect(runController.currentState.heroStats.level, 1);
      expect(runController.currentState.heroStats.xp, 1050);

      expect(runController.gainXp(1), isTrue); // 1051 >= 1040
      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 11);
      expect(runController.currentState.pendingDrafts, 1);
    });

    test('au-dela de la table, la derniere valeur', () {
      moveToAct(20);

      expect(runController.gainXp(1014), isFalse); // 1015 au-dela de l acte 15
      expect(runController.gainXp(1), isTrue);

      final stats = runController.currentState.heroStats;
      expect(stats.level, 2);
      expect(stats.xp, 0);
    });
  });
```

In `test/unit/reward_controller_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:flame/extensions.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:flame/extensions.dart';
```

Then replace:

```dart
    setUp(() {
      container = ProviderContainer();
      rewardController = container.read(rewardProvider.notifier);
```

with:

```dart
    setUp(() {
      // `collectGoldAndXp` appelle `gainXp`, qui lit le palier : un conteneur
      // nu reçoit la courbe surchargée (spec P-43 E3, §8, « Le piège du
      // montage »).
      container = ProviderContainer(
        overrides: [
          xpCurveProvider.overrideWithValue(const XpCurveData([115, 200])),
        ],
      );
      rewardController = container.read(rewardProvider.notifier);
```

In `test/unit/debug_actions_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/entity_stats.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
```

Then replace:

```dart
/// Une run *debug*, seule dans laquelle `DebugActions` accepte d'agir.
ProviderContainer _startedRun() {
  final container = ProviderContainer();
```

with:

```dart
/// La courbe de D67 : `gainLevel` lit le palier de l'acte courant (spec P-43
/// E3, §4.4).
const _d67 = XpCurveData([
  115, 200, 310, 480, 590, 775, 955, 1100, //
  1040, 1185, 1370, 1370, 1300, 1375, 1015,
]);

/// Une run *debug*, seule dans laquelle `DebugActions` accepte d'agir.
ProviderContainer _startedRun() {
  final container = ProviderContainer(
    overrides: [xpCurveProvider.overrideWithValue(_d67)],
  );
```

Then replace:

```dart
      expect(container.read(runProvider).act, 2);
      expect(container.read(runProvider).mapNodes, isNot(same(mapBefore)));
      expect(container.read(runProvider).currentNodeId, isNull);
    });
  });
```

with:

```dart
      expect(container.read(runProvider).act, 2);
      expect(container.read(runProvider).mapNodes, isNot(same(mapBefore)));
      expect(container.read(runProvider).currentNodeId, isNull);
    });

    test('gainLevel fait gagner exactement un niveau, au palier de l acte '
        'courant', () {
      final container = _startedRun();
      addTearDown(container.dispose);

      DebugActions.gainLevel(container.read);
      expect(container.read(runProvider).heroStats.level, 2);
      expect(container.read(runProvider).heroStats.xp, 0);
      expect(container.read(runProvider).pendingDrafts, 1);

      // A l'acte 9, le palier vaut 1040 : un niveau, ni moins, ni plus.
      DebugActions.updateRun(container.read, (s) => s.copyWith(act: 9));
      DebugActions.gainLevel(container.read);
      expect(container.read(runProvider).heroStats.level, 3);
      expect(container.read(runProvider).heroStats.xp, 0);
      expect(container.read(runProvider).pendingDrafts, 2);
    });
  });
```

In `test/widget/map_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
```

Then replace:

```dart
// MapScreen's dash-line animation repeats forever, so pumpAndSettle() never
// terminates here; pump a fixed duration instead to let transitions finish.
```

with:

```dart
/// Le panneau du héros lit le palier d'XP dès la première image
/// (`map_screen.dart:299`) : chaque conteneur, nu, reçoit une courbe surchargée
/// — lire le provider d'origine lancerait le vrai chargeur (spec P-43 E3, §8,
/// « Le piège du montage »).
ProviderContainer _container() => ProviderContainer(
      overrides: [
        xpCurveProvider.overrideWithValue(const XpCurveData([115, 200])),
      ],
    );

// MapScreen's dash-line animation repeats forever, so pumpAndSettle() never
// terminates here; pump a fixed duration instead to let transitions finish.
```

Then replace **every** occurrence (five : `:49`, `:115`, `:162`, `:209`, `:276`) of:

```dart
ProviderContainer();
```

with:

```dart
_container();
```

Then replace the end of the file:

```dart
      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Open Map'), findsOneWidget);
    },
  );
}
```

with:

```dart
      expect(find.byType(MapScreen), findsNothing);
      expect(find.text('Open Map'), findsOneWidget);
    },
  );

  // Le palier est celui de l'acte courant (spec P-43 E3, §4.4, §8).
  testWidgets('la barre d XP lit le palier de l acte courant', (
    WidgetTester tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    final runNotifier = container.read(runProvider.notifier);
    runNotifier.startNewRun(
      const HeroData(
        id: 'test_hero',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        classCard: 'test',
        maxHp: 10,
        maxMana: 3,
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en', ''), Locale('fr', '')],
          home: MapScreen(),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('XP: 0/115'), findsOneWidget);

    runNotifier.updateState(runNotifier.currentState.copyWith(act: 2));
    await _settle(tester);

    expect(find.text('XP: 0/200'), findsOneWidget);
  });
}
```

In `test/widget/debug_drawer_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/might_target.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/might_target.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
```

Then replace:

```dart
  PassiveData? activePassive,
}) {
  final container = ProviderContainer();
```

with:

```dart
  PassiveData? activePassive,
}) {
  // Hors combat, le premier onglet, « Heros », lit le palier d'XP de l'acte
  // (`debug_hero_tab.dart`) : la courbe est surchargée ici, pour tous les
  // appelants (spec P-43 E3, §8, « Le piège du montage »).
  final container = ProviderContainer(
    overrides: [
      xpCurveProvider.overrideWithValue(const XpCurveData([115, 200])),
    ],
  );
```

Then replace the end of the file:

```dart
    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack, MightTarget.skill},
    );
  });
}
```

with:

```dart
    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack, MightTarget.skill},
    );
  });

  testWidgets('l onglet Heros dit le palier d XP de l acte courant', (
    tester,
  ) async {
    sizeScreen(tester);
    final container = _debugRunContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);
    await tester.tap(find.text('Heros'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('XP  (seuil 115)'));
    expect(find.text('XP  (seuil 115)'), findsOneWidget);
  });
}
```

In `test/widget/starter_deck_draft_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
```

Then replace:

```dart
  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [mockHero],
    cards: mockCards,
    events: [],
    passives: [mockPassive],
    relics: [],
    forgeUpgrades: [],
  );
```

with:

```dart
  // Le draft fini, l'écran pousse la carte du monde, dont le panneau du
  // héros lit le palier d'XP : le registre porte une courbe (spec P-43 E3,
  // §8, « Le piège du montage » — le chargeur est résolu à ce moment-là).
  final mockRegistry = GameDataRegistry(
    enemies: [],
    heroes: [mockHero],
    cards: mockCards,
    events: [],
    passives: [mockPassive],
    relics: [],
    forgeUpgrades: [],
    xpCurve: const XpCurveData([115, 200]),
  );
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/xp_curve_data_test.dart test/unit/game_data_loader_test.dart test/unit/xp_scaling_test.dart`
Expected: FAIL à la compilation — `Target of URI doesn't exist: 'package:roguelike_card_game/models/data/xp_curve_data.dart'` et `The method 'loadDocument' isn't defined for the type 'GameDataLoader'`.

- [ ] **Step 3: Le document et son modèle**

Create `assets/data/xp_curve.json`:

```json
{
  "xpPerLevelByAct": [115, 200, 310, 480, 590, 775, 955, 1100, 1040, 1185, 1370, 1370, 1300, 1375, 1015]
}
```

Create `lib/models/data/xp_curve_data.dart`:

```dart
import 'dart:math' show max, min;

/// La courbe d'XP de la run (spec P-43 E3, §3.2 ; D24, D58, D67) : le prix
/// d'un niveau, par acte, lu dans `assets/data/xp_curve.json`.
///
/// Un document de configuration, pas une entité : ni id, ni dossier, hors de
/// l'éditeur de contenu, comme `audio.json`. Le palier d'un niveau en est
/// **dérivé** à chaque lecture, jamais stocké (A8).
class XpCurveData {
  /// Le prix d'un niveau à l'acte 1, 2, … ; la dernière valeur vaut pour
  /// tout acte au-delà de la table (D67).
  final List<int> xpPerLevelByAct;

  const XpCurveData(this.xpPerLevelByAct);

  /// Le palier d'XP à l'acte [act] : l'acte borné à 1 en dessous, la
  /// dernière valeur répétée au-delà de la table.
  int thresholdFor(int act) =>
      xpPerLevelByAct[min(max(act, 1), xpPerLevelByAct.length) - 1];

  /// Refuse une table absente ou vide, et tout palier qui n'est pas un
  /// entier d'au moins 1 : un palier nul ferait boucler `gainXp` sans fin.
  factory XpCurveData.fromJson(Map<String, dynamic> json) {
    final raw = json['xpPerLevelByAct'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException(
        'xp_curve : "xpPerLevelByAct" doit etre une liste non vide d entiers',
      );
    }
    final values = <int>[];
    for (final value in raw) {
      if (value is! int || value < 1) {
        throw FormatException(
          'xp_curve : "xpPerLevelByAct" porte "$value" ; un palier est un '
          'entier d au moins 1',
        );
      }
      values.add(value);
    }
    return XpCurveData(List.unmodifiable(values));
  }
}
```

- [ ] **Step 4: Le chargeur lit un document plat**

In `lib/services/game_data_loader.dart`, replace:

```dart
/// Charge les entites du jeu depuis un [AssetBundle], une categorie a la fois,
/// en accumulant les erreurs plutot qu en levant a la premiere.
```

with:

```dart
/// Charge les entites du jeu depuis un [AssetBundle], une categorie a la fois,
/// et ses documents plats ([loadDocument]), en accumulant les erreurs plutot
/// qu en levant a la premiere.
```

Then replace:

```dart
      final matches = _match(source.pattern);
      final raws = await Future.wait(matches.map(_read));
```

with:

```dart
      final matches = _match(source.pattern);
      final raws = await Future.wait(matches.map((match) => _read(match.key)));
```

Then replace the whole of `_read` (`:161-183`) — **pas** un remplacement de `match.key` dans tout le fichier : `_applyInjection` en porte deux autres, qui restent —:

```dart
  Future<Map<String, dynamic>?> _read(_Match match) async {
    try {
      // `cache: false` : l'appelant fait son propre cache — c'est
      // `GameDataRegistry`, resolu une fois par `gameDataLoaderProvider`. Le SDK
      // lui-meme procede ainsi dans `loadStructuredData`. Trois consequences, dans
      // cet ordre d'importance : (1) le devtool d'edition relit le disque a chaud
      // au lieu de servir un `Future` deja regle ; (2) les ~40 Ko de chaines ne
      // sont pas retenus apres le demarrage ; (3) sous `flutter test`, un `Future`
      // mis en cache dans la zone d'un test termine ne se resout jamais depuis un
      // nouveau test — NE PAS retirer ce drapeau sans traiter les trois.
      final decoded = jsonDecode(await bundle.loadString(match.key, cache: false));
      if (decoded is! Map<String, dynamic>) {
        _errors.add(
          '${match.key} : le fichier doit contenir un objet JSON, pas un ${decoded.runtimeType}',
        );
        return null;
      }
      return decoded;
    } catch (e) {
      _errors.add('${match.key} : ${e.toString().replaceAll('\n', ' ')}');
      return null;
    }
  }
```

with:

```dart
  /// Charge un document plat — un fichier de configuration, pas une
  /// categorie d entites : ni motif, ni injection, ni id (spec P-43 E3, §3.2).
  ///
  /// Le fichier absent, un JSON illisible ou un [fromJson] qui leve rendent
  /// `null` et accumulent leur faute avec celles des entites, que
  /// [throwIfFailed] remonte en une fois. Lu par [_read], donc avec
  /// `cache: false`, pour les memes raisons.
  Future<T?> loadDocument<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final raw = await _read(path);
    if (raw == null) return null;
    try {
      return fromJson(raw);
    } catch (e) {
      _errors.add('$path : ${e.toString().replaceAll('\n', ' ')}');
      return null;
    }
  }

  /// Lit et decode un fichier JSON du bundle : une entite de [loadAll] ou un
  /// document de [loadDocument].
  Future<Map<String, dynamic>?> _read(String key) async {
    try {
      // `cache: false` : l'appelant fait son propre cache — c'est
      // `GameDataRegistry`, resolu une fois par `gameDataLoaderProvider`. Le SDK
      // lui-meme procede ainsi dans `loadStructuredData`. Trois consequences, dans
      // cet ordre d'importance : (1) le devtool d'edition relit le disque a chaud
      // au lieu de servir un `Future` deja regle ; (2) les ~40 Ko de chaines ne
      // sont pas retenus apres le demarrage ; (3) sous `flutter test`, un `Future`
      // mis en cache dans la zone d'un test termine ne se resout jamais depuis un
      // nouveau test — NE PAS retirer ce drapeau sans traiter les trois.
      final decoded = jsonDecode(await bundle.loadString(key, cache: false));
      if (decoded is! Map<String, dynamic>) {
        _errors.add(
          '$key : le fichier doit contenir un objet JSON, pas un ${decoded.runtimeType}',
        );
        return null;
      }
      return decoded;
    } catch (e) {
      _errors.add('$key : ${e.toString().replaceAll('\n', ' ')}');
      return null;
    }
  }
```

(À vérifier après coup : `git grep -n "match.key" -- lib/services/game_data_loader.dart` rend trois lignes — l'appel de `loadAll`, `matches.map((match) => _read(match.key))`, et les deux messages d'erreur d'`_applyInjection` —, aucune de `_read`.)

- [ ] **Step 5: Le registre porte la courbe, le provider la sert**

In `lib/models/data/game_data_registry.dart`, replace:

```dart
import 'level_up_reward_data.dart';
import 'audio_data.dart';
```

with:

```dart
import 'level_up_reward_data.dart';
import 'audio_data.dart';
import 'xp_curve_data.dart';
```

Then replace:

```dart
  final List<LevelUpRewardData> levelUpRewards;

  final AudioData audio;
```

with:

```dart
  final List<LevelUpRewardData> levelUpRewards;

  /// La courbe d'XP (spec P-43 E3, §3.2, A27). Optionnelle, comme
  /// [levelUpRewards], pour ne pas casser les dizaines de registres de test :
  /// `loadGameDataRegistry` la renseigne toujours ; un registre construit à
  /// la main peut ne pas la porter, et tout lecteur du palier lève alors —
  /// `xpCurveProvider` par une `StateError` explicite.
  final XpCurveData? xpCurve;

  final AudioData audio;
```

Then replace:

```dart
    this.levelUpRewards = const [],
    this.audio = const AudioData.disabled(),
```

with:

```dart
    this.levelUpRewards = const [],
    this.xpCurve,
    this.audio = const AudioData.disabled(),
```

In `lib/services/game_data_service.dart`, replace:

```dart
import '../models/data/audio_data.dart';
import 'game_data_loader.dart';
```

with:

```dart
import '../models/data/audio_data.dart';
import '../models/data/xp_curve_data.dart';
import 'game_data_loader.dart';
```

Then replace:

```dart
/// Construit le registre complet : les entites depuis [bundle], l audio
/// depuis `rootBundle`.
```

with:

```dart
/// Construit le registre complet : les entites et la courbe d XP depuis
/// [bundle], l audio depuis `rootBundle`.
```

Then replace:

```dart
  // Une fois seulement, a la fin : les fautes de toutes les categories sont
  // remontees ensemble. Corriger une faute par cycle de rebuild, fichier par
  // fichier, serait invivable.
  loader.throwIfFailed();
```

with:

```dart
  // La courbe d XP (spec P-43 E3, §3.2 ; D24) : un document plat, a cote
  // d `audio.json` — mais, a sa difference, elle fait echouer le demarrage.
  final xpCurve = await loader.loadDocument(
    'assets/data/xp_curve.json',
    XpCurveData.fromJson,
  );

  // Une fois seulement, a la fin : les fautes de toutes les categories sont
  // remontees ensemble. Corriger une faute par cycle de rebuild, fichier par
  // fichier, serait invivable.
  loader.throwIfFailed();
```

Then replace:

```dart
    levelUpRewards: levelUpRewards,
    audio: audio,
  );
}
```

with:

```dart
    levelUpRewards: levelUpRewards,
    xpCurve: xpCurve,
    audio: audio,
  );
}
```

Then replace the end of the file:

```dart
final gameDataLoaderProvider = FutureProvider<GameDataRegistry>(
  (ref) => loadGameDataRegistry(rootBundle),
);
```

with:

```dart
final gameDataLoaderProvider = FutureProvider<GameDataRegistry>(
  (ref) => loadGameDataRegistry(rootBundle),
);

/// La courbe d XP du registre charge (spec P-43 E3, §3.2, A9) : un provider,
/// et non `GameDataRegistry.instance`, pour qu un test la surcharge
/// (`overrideWithValue`) sans dependre d un registre statique reste d un
/// autre test.
///
/// Un registre construit a la main peut ne pas la porter (A27) : la lire
/// alors est une faute de montage, signalee comme telle.
final xpCurveProvider = Provider<XpCurveData>((ref) {
  final curve = ref.watch(gameDataLoaderProvider).requireValue.xpCurve;
  if (curve == null) {
    throw StateError(
      'xpCurveProvider : le registre charge ne porte pas de courbe d XP '
      '(assets/data/xp_curve.json). Un registre de test qui lit le palier '
      'doit en recevoir une, ou le test doit surcharger xpCurveProvider.',
    );
  }
  return curve;
});
```

- [ ] **Step 6: `gainXp` au palier dérivé ; `xpToNextLevel` disparaît**

In `lib/game/controllers/run/player_stats_manager.dart`, delete the line:

```dart
import 'dart:math';
```

Then replace:

```dart
import '../../../services/audio/audio_providers.dart';
```

with:

```dart
import '../../../services/audio/audio_providers.dart';
import '../../../services/game_data_service.dart';
```

Then replace the whole `gainXp` (`:110-144`):

```dart
  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    if (amount <= 0) return false;

    var currentStats = controller.currentState.heroStats;
    int newXp = currentStats.xp + amount;
    int currentLevel = currentStats.level;
    int currentXpToNext = currentStats.xpToNextLevel;
    bool leveledUp = false;
    int levelsGained = 0;

    while (newXp >= currentXpToNext) {
      newXp -= currentXpToNext;
      currentLevel++;
      // Formule d'XP requise pour le nouveau niveau: 100 * (1.5 ^ (level - 1))
      currentXpToNext = (100 * pow(1.5, currentLevel - 1)).round();
      leveledUp = true;
      levelsGained++;
    }

    controller.updateState(
      controller.currentState.copyWith(
        heroStats: currentStats.copyWith(
          level: currentLevel,
          xp: newXp,
          xpToNextLevel: currentXpToNext,
        ),
        pendingDrafts: controller.currentState.pendingDrafts + levelsGained,
      ),
    );

    return leveledUp;
  }
```

with:

```dart
  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Le palier est celui de l'acte courant, lu sur la courbe d'XP et relu à
  /// chaque niveau (spec P-43 E3, §4.4, A8) : il n'est stocké nulle part. Un
  /// palier qui a baissé sous l'XP accumulée — de l'acte 8 à l'acte 9 —
  /// donne donc le niveau au gain suivant.
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    if (amount <= 0) return false;

    final curve = ref.read(xpCurveProvider);
    final run = controller.currentState;
    var xp = run.heroStats.xp + amount;
    var level = run.heroStats.level;
    var levelsGained = 0;

    while (xp >= curve.thresholdFor(run.act)) {
      xp -= curve.thresholdFor(run.act);
      level++;
      levelsGained++;
    }

    controller.updateState(
      run.copyWith(
        heroStats: run.heroStats.copyWith(level: level, xp: xp),
        pendingDrafts: run.pendingDrafts + levelsGained,
      ),
    );

    return levelsGained > 0;
  }
```

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  /// Ajoute de l'Expérience au joueur.
  /// Gère les montées de niveaux successives avec conservation de l'XP excédentaire (carry-over).
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    return _playerStatsManager.gainXp(amount);
  }
```

with:

```dart
  /// Ajoute de l'Expérience au joueur, au palier de l'acte courant ; voir
  /// `PlayerStatsManager.gainXp`.
  /// Retourne [true] si au moins un niveau a été gagné.
  bool gainXp(int amount) {
    return _playerStatsManager.gainXp(amount);
  }
```

In `lib/models/entity_stats.dart`, delete the four lines:

```dart
  final int xpToNextLevel;
```

```dart
    this.xpToNextLevel = 100,
```

```dart
    int? xpToNextLevel,
```

```dart
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
```

Then delete:

```dart
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
```

Then delete:

```dart
    'xpToNextLevel': xpToNextLevel,
```

- [ ] **Step 7: Les écrans et le menu de debug lisent la courbe**

In `lib/ui/widgets/map/hero_mini_stats_panel.dart`, replace:

```dart
import '../../../game/controllers/run_controller.dart';
```

with:

```dart
import '../../../game/controllers/run_controller.dart';
import '../../../models/entity_stats.dart';
import '../../../services/game_data_service.dart';
```

Then replace:

```dart
    final runState = ref.watch(runProvider);
    final stats = runState.heroStats;
```

with:

```dart
    final runState = ref.watch(runProvider);
    final stats = runState.heroStats;
    // Le palier de l'acte courant, dérivé de la courbe (spec P-43 E3, §4.4).
    final xpThreshold = ref.watch(xpCurveProvider).thresholdFor(runState.act);
```

Then replace:

```dart
          _buildXpBar(context, stats, locale),
```

with:

```dart
          _buildXpBar(context, stats, xpThreshold, locale),
```

Then replace:

```dart
  Widget _buildXpBar(BuildContext context, dynamic stats, String locale) {
    final double progress = stats.xpToNextLevel > 0
        ? (stats.xp / stats.xpToNextLevel).clamp(0.0, 1.0)
        : 0.0;
```

with:

```dart
  /// [stats] est typé : un `dynamic` laisserait passer à l'analyse la lecture
  /// d'un champ disparu. [threshold] vaut au moins 1, la courbe le garantit
  /// au chargement.
  Widget _buildXpBar(
    BuildContext context,
    EntityStats stats,
    int threshold,
    String locale,
  ) {
    final double progress = (stats.xp / threshold).clamp(0.0, 1.0);
```

Then replace:

```dart
              'XP: ${stats.xp}/${stats.xpToNextLevel}',
```

with:

```dart
              'XP: ${stats.xp}/$threshold',
```

In `lib/ui/widgets/debug/tabs/debug_hero_tab.dart`, replace:

```dart
import '../../../../models/might_target.dart';
```

with:

```dart
import '../../../../models/might_target.dart';
import '../../../../services/game_data_service.dart';
```

Then replace:

```dart
    final run = ref.watch(runProvider);
    final stats = run.heroStats;

    return ListView(
```

with:

```dart
    final run = ref.watch(runProvider);
    final stats = run.heroStats;
    final xpThreshold = ref.watch(xpCurveProvider).thresholdFor(run.act);

    return ListView(
```

Then replace:

```dart
        DebugNumberField(
          label: 'XP  (seuil ${stats.xpToNextLevel})',
          value: stats.xp,
          onSubmitted: (v) =>
              DebugActions.updateHeroStats(ref.read, (s) => s.copyWith(xp: v)),
        ),
        // Le champ ci-dessus n'ecrase qu'une statistique. Ce bouton emprunte le
        // vrai chemin : seuil d'XP recalcule et draft de recompense ouvert.
```

with:

```dart
        DebugNumberField(
          label: 'XP  (seuil $xpThreshold)',
          value: stats.xp,
          onSubmitted: (v) =>
              DebugActions.updateHeroStats(ref.read, (s) => s.copyWith(xp: v)),
        ),
        // Le champ ci-dessus n'ecrase qu'une statistique. Ce bouton emprunte le
        // vrai chemin : l'XP portee au palier de l'acte, et le draft de
        // recompense ouvert.
```

In `lib/game/services/debug_actions.dart`, replace:

```dart
import '../../services/save_service.dart' show RefReader;
```

with:

```dart
import '../../services/game_data_service.dart';
import '../../services/save_service.dart' show RefReader;
```

Then replace:

```dart
  /// Fait gagner exactement un niveau, par le **vrai** chemin.
  ///
  /// Ecrire `level` a la main ne fait qu'ecraser une statistique : ni le seuil
  /// d'XP ne se recalcule, ni le draft de recompense ne s'ouvre. `gainXp` fait
  /// les trois, dont l'incrementation de `pendingDrafts` — c'est elle qui fait
  /// apparaitre l'overlay de montee de niveau sur la carte.
  static void gainLevel(RefReader read) {
    if (!_allowed(read)) return;
    final stats = read(runProvider).heroStats;
    final missing = stats.xpToNextLevel - stats.xp;
    read(runProvider.notifier).gainXp(missing > 0 ? missing : 1);
  }
```

with:

```dart
  /// Fait gagner exactement un niveau, par le **vrai** chemin.
  ///
  /// Ecrire `level` a la main ne fait qu'ecraser une statistique : l'XP
  /// accumulee n'est pas consommee et le draft de recompense ne s'ouvre pas.
  /// `gainXp` fait les deux, dont l'incrementation de `pendingDrafts` —
  /// c'est elle qui fait apparaitre l'overlay de montee de niveau sur la
  /// carte. Le palier est celui de l'acte courant, lu sur la courbe (spec
  /// P-43 E3, §4.4).
  static void gainLevel(RefReader read) {
    if (!_allowed(read)) return;
    final run = read(runProvider);
    final threshold = read(xpCurveProvider).thresholdFor(run.act);
    final missing = threshold - run.heroStats.xp;
    read(runProvider.notifier).gainXp(missing > 0 ? missing : 1);
  }
```

- [ ] **Step 8: `CLAUDE.md` nomme le document et son modèle**

In `CLAUDE.md`, replace:

```
├── audio.json, patch_notes.json    # flat: single configuration documents, not catalogues
```

with:

```
├── audio.json, patch_notes.json, xp_curve.json    # flat: single configuration documents, not catalogues
```

Then replace:

```
`level_up_reward_data.dart`, `audio_data.dart`), aggregated via `game_data_registry.dart`.
```

with:

```
`level_up_reward_data.dart`, `audio_data.dart`, `xp_curve_data.dart`), aggregated via `game_data_registry.dart`.
```

- [ ] **Step 9: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/xp_curve_data_test.dart` — Expected: `+5: All tests passed!`
Run: `flutter test test/unit/game_data_loader_test.dart` — Expected: `+15: All tests passed!`
Run: `flutter test test/unit/real_bundle_load_test.dart` — Expected: `+4: All tests passed!` (si un compte rougit sur un fichier disparu : supprimer `build/unit_test_assets`, relancer).
Run: `flutter test test/unit/xp_scaling_test.dart` — Expected: `+9: All tests passed!`
Run: `flutter test test/unit/debug_actions_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/widget/map_screen_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/widget/debug_drawer_test.dart` — Expected: `+8: All tests passed!`
Run: `flutter test test/unit/entity_id_convention_test.dart test/unit/reward_controller_test.dart test/widget/starter_deck_draft_screen_test.dart` — Expected: `+21: All tests passed!` (3 + 15 + 3).
Run: `flutter test test/widget/tutorial_class_step_test.dart test/widget/tutorial_armor_step_test.dart test/widget/tutorial_starter_draft_test.dart test/widget/tutorial_merge_widget_test.dart test/widget/tutorial_play_card_step_test.dart test/widget/tutorial_merge_transition_test.dart` — Expected: `All tests passed!` — ces tests reconstruisent le registre à chaque `testWidgets` : sans `cache: false` sur la lecture du document, ils se bloqueraient dès le deuxième (spec §8, « Le chargement d'un document »).
Run: `git grep -n xpToNextLevel -- lib` — Expected: les lignes du tutoriel seulement (`lib/tutorial/tutorial_engine.dart`, `lib/tutorial/widgets/tutorial_xp_widget.dart`), que Task 4 retire.
Run: `dart run tool/sync_assets.dart --check` — Expected: code de sortie 0 (`assets/data/` est déjà déclaré).

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1506: All tests passed!` (1490 + 20 − 4 : la courbe +5, le document +4, la donnée livrée +1, le palier dérivé +7 −4, la carte +1, le tiroir +1, `gainLevel` +1).

- [ ] **Step 11: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add assets/data/xp_curve.json lib/models/data/xp_curve_data.dart lib/services/game_data_loader.dart lib/services/game_data_service.dart lib/models/data/game_data_registry.dart lib/game/controllers/run/player_stats_manager.dart lib/game/controllers/run_controller.dart lib/models/entity_stats.dart lib/ui/widgets/map/hero_mini_stats_panel.dart lib/ui/widgets/debug/tabs/debug_hero_tab.dart lib/game/services/debug_actions.dart CLAUDE.md test/unit/xp_curve_data_test.dart test/unit/game_data_loader_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/xp_scaling_test.dart test/unit/reward_controller_test.dart test/unit/debug_actions_test.dart test/widget/map_screen_test.dart test/widget/debug_drawer_test.dart test/widget/starter_deck_draft_screen_test.dart
git commit -F- <<'EOF'
feat(xp): le prix d un niveau est une table par acte, en donnee

assets/data/xp_curve.json porte la table de D67, chargee comme document
plat par GameDataLoader.loadDocument, servie par xpCurveProvider. Le
palier n est plus stocke : gainXp relit celui de l acte courant a chaque
niveau, et EntityStats perd xpToNextLevel. La carte du monde et le menu
de debug lisent la courbe.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Le tutoriel lit la courbe — `TutorialEngine.xpThreshold` et la prose XP

A26, A27 (spec §4.4, §5.3) : le tutoriel perd son propre palier (`mockState.xpToNextLevel`) et sa formule géométrique ; un getter de l'engine, `TutorialEngine.xpThreshold`, rend `data.xpCurve!.thresholdFor(1)` — la même fonction pure, sur son registre (ADR-081), qui passe toujours par `loadGameDataRegistry` et porte donc la courbe ; le tutoriel est à l'acte 1. `gainXp` et la barre d'XP du tutoriel le lisent. L'étape « L'Expérience » remplace « 100, puis 150, puis 225 » par deux placeholders, `{xpAct1}` et `{xpAct2}`, que remplit `fillXpPlaceholders`, fonction pure de `tutorial_prose.dart`, appelée par `TutorialScreen` à côté de `fillRewardPlaceholders`.

Changement de jeu de la tâche, voulu : au tutoriel, un niveau coûte 115 XP — il faut abattre quatre Gobelins (35 XP) au lieu de trois ; la prose dit « 115 XP à l'acte 1, 200 à l'acte 2 ».

**Files:**
- Modify: `lib/tutorial/tutorial_engine.dart:38`, `:87`, `:509-532`
- Modify: `lib/tutorial/widgets/tutorial_xp_widget.dart:58-60`, `:121`
- Modify: `lib/tutorial/tutorial_prose.dart:1`, fin de fichier
- Modify: `lib/tutorial/tutorial_screen.dart:150-154`
- Modify: `lib/tutorial/tutorial_data.dart:305-306`, `:316-317`
- Test: `test/tutorial/tutorial_engine_test.dart:391-403`, `:406-423`, `:697`
- Test: `test/tutorial/tutorial_prose_test.dart:1-6` (import), fin de fichier (deux cas neufs)

**Interfaces:**
- Consumes: `XpCurveData.thresholdFor(int act)` et `GameDataRegistry.xpCurve` (Task 3).
- Produces:
  - `int get TutorialEngine.xpThreshold` — `TutorialMockState.xpToNextLevel` n'existe plus.
  - `String fillXpPlaceholders(String body, XpCurveData curve)` (`lib/tutorial/tutorial_prose.dart`).

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/tutorial/tutorial_engine_test.dart`, replace (`:391-403`):

```dart
    test('gainXp déclenche un passage de niveau au-delà de xpToNextLevel', () {
      expect(engine.mockState.playerLevel, 1);
      expect(engine.mockState.playerXp, 0);

      engine.gainXp(35);
      expect(engine.mockState.playerXp, 35);
      engine.gainXp(35);
      expect(engine.mockState.playerXp, 70);
      engine.gainXp(35);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.playerXp, 5); // 105 - 100
    });
```

with:

```dart
    test('gainXp déclenche un passage de niveau au-delà du palier de l\'acte',
        () {
      expect(engine.mockState.playerLevel, 1);
      expect(engine.mockState.playerXp, 0);

      engine.gainXp(35);
      expect(engine.mockState.playerXp, 35);
      engine.gainXp(35);
      expect(engine.mockState.playerXp, 70);
      engine.gainXp(35);
      // 105 XP : sous le palier de l'acte 1, 115 — pas encore de niveau.
      expect(engine.mockState.playerLevel, 1);
      expect(engine.mockState.playerXp, 105);

      engine.gainXp(35);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.playerXp, 25); // 140 - 115
    });
```

Then replace (`:406-423`):

```dart
  group('Progression d\'XP', () {
    test('le palier suit 100 x 1,5^(niveau-1)', () {
      expect(engine.mockState.xpToNextLevel, 100);

      engine.gainXp(100);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.xpToNextLevel, 150);
    });

    test('l\'XP excédentaire est reportée et les drafts s\'empilent', () {
      engine.gainXp(260); // 100 -> niv.2, 150 -> niv.3, reste 10

      expect(engine.mockState.playerLevel, 3);
      expect(engine.mockState.playerXp, 10);
      expect(engine.pendingDrafts, 2);
    });
  });
```

with:

```dart
  group('Progression d\'XP', () {
    // Le palier est lu sur la courbe du registre, à l'acte 1 (spec P-43 E3,
    // §4.4) : le même à chaque niveau.
    test('le palier est celui de l\'acte, à chaque niveau', () {
      expect(engine.xpThreshold, 115);

      engine.gainXp(115);

      expect(engine.mockState.playerLevel, 2);
      expect(engine.mockState.playerXp, 0);
      expect(engine.xpThreshold, 115);
    });

    test('l\'XP excédentaire est reportée et les drafts s\'empilent', () {
      engine.gainXp(260); // 115 -> niv.2, 115 -> niv.3, reste 30

      expect(engine.mockState.playerLevel, 3);
      expect(engine.mockState.playerXp, 30);
      expect(engine.pendingDrafts, 2);
    });
  });
```

Then replace (`:697-698`):

```dart
      engine.gainXp(100);
      expect(engine.pendingDrafts, 1);
```

with:

```dart
      engine.gainXp(115);
      expect(engine.pendingDrafts, 1);
```

In `test/tutorial/tutorial_prose_test.dart`, replace:

```dart
import 'package:roguelike_card_game/services/game_data_service.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/xp_curve_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
```

Then replace the end of the file:

```dart
  test('un texte sans placeholder traverse inchangé', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    const corps = 'Les reliques donnent des bonus passifs.';

    expect(fillRewardPlaceholders(corps, rewards, isFrench: true), corps);
  });
}
```

with:

```dart
  test('un texte sans placeholder traverse inchangé', () async {
    final rewards = (await loadGameDataRegistry(rootBundle)).levelUpRewards;
    const corps = 'Les reliques donnent des bonus passifs.';

    expect(fillRewardPlaceholders(corps, rewards, isFrench: true), corps);
  });

  // Les paliers de l'étape « L'Expérience » se lisent sur la courbe (spec
  // P-43 E3, §5.3, A26).
  test('les paliers de l acte 1 et de l acte 2 sont lus sur la courbe',
      () async {
    final curve = (await loadGameDataRegistry(rootBundle)).xpCurve!;

    expect(fillXpPlaceholders('{xpAct1} puis {xpAct2}', curve), '115 puis 200');
    // Une autre courbe, d'autres nombres : la prose ne recopie rien.
    expect(
      fillXpPlaceholders('{xpAct1} puis {xpAct2}', const XpCurveData([70, 90])),
      '70 puis 90',
    );
  });

  test('aucun placeholder ne survit dans l étape XP', () async {
    final data = await loadGameDataRegistry(rootBundle);
    final etape =
        kTutorialSteps.firstWhere((s) => s.type == TutorialStepType.xp);

    for (final corps in [etape.bodyFr, etape.bodyEn]) {
      final rendu = fillXpPlaceholders(
        fillRewardPlaceholders(
          corps,
          data.levelUpRewards,
          isFrench: corps == etape.bodyFr,
        ),
        data.xpCurve!,
      );
      expect(rendu, isNot(contains('{')));
      expect(rendu, contains('115'));
      expect(rendu, contains('200'));
    }
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/tutorial/tutorial_engine_test.dart test/tutorial/tutorial_prose_test.dart`
Expected: FAIL à la compilation — `The getter 'xpThreshold' isn't defined for the type 'TutorialEngine'` et `The function 'fillXpPlaceholders' isn't defined`.

- [ ] **Step 3: Le moteur du tutoriel lit la courbe**

In `lib/tutorial/tutorial_engine.dart`, delete the line (`:38`):

```dart
  int xpToNextLevel = 100;
```

Then, in `resetScratch()`, delete the line (`:87`):

```dart
    xpToNextLevel = 100;
```

Then replace (`:510-532`):

```dart
  /// Même formule que `PlayerStatsManager.gainXp` : report de l'excédent et
  /// palier géométrique `100 × 1,5^(niveau-1)`.
  void gainXp(int amount) {
    if (amount <= 0) return;

    var xp = mockState.playerXp + amount;
    var level = mockState.playerLevel;
    var threshold = mockState.xpToNextLevel;
    var drafts = mockState.pendingDrafts;

    while (xp >= threshold) {
      xp -= threshold;
      level++;
      threshold = (100 * pow(1.5, level - 1)).round();
      drafts++;
    }

    mockState.playerXp = xp;
    mockState.playerLevel = level;
    mockState.xpToNextLevel = threshold;
    mockState.pendingDrafts = drafts;
    notifyListeners();
  }
```

with:

```dart
  /// Le palier d'XP du tutoriel : celui de l'acte 1 — le tutoriel s'y joue —,
  /// lu sur la courbe de son registre (spec P-43 E3, §4.4 ; ADR-081). Le
  /// registre du tutoriel passe toujours par `loadGameDataRegistry`, qui
  /// porte la courbe (A27).
  int get xpThreshold => data.xpCurve!.thresholdFor(1);

  /// Même règle que `PlayerStatsManager.gainXp` : report de l'excédent, et
  /// le palier de l'acte, le même à chaque niveau.
  void gainXp(int amount) {
    if (amount <= 0) return;

    var xp = mockState.playerXp + amount;
    var level = mockState.playerLevel;
    var drafts = mockState.pendingDrafts;

    while (xp >= xpThreshold) {
      xp -= xpThreshold;
      level++;
      drafts++;
    }

    mockState.playerXp = xp;
    mockState.playerLevel = level;
    mockState.pendingDrafts = drafts;
    notifyListeners();
  }
```

(`dart:math` reste importé : `Random`, `:103`, le lit encore.)

In `lib/tutorial/widgets/tutorial_xp_widget.dart`, replace:

```dart
    final state = widget.engine.mockState;
    final progress = (state.playerXp / state.xpToNextLevel).clamp(0.0, 1.0);
```

with:

```dart
    final state = widget.engine.mockState;
    final threshold = widget.engine.xpThreshold;
    final progress = (state.playerXp / threshold).clamp(0.0, 1.0);
```

Then replace:

```dart
                            '${state.playerXp}/${state.xpToNextLevel} XP',
```

with:

```dart
                            '${state.playerXp}/$threshold XP',
```

- [ ] **Step 4: La prose XP par ses placeholders**

In `lib/tutorial/tutorial_prose.dart`, replace:

```dart
import '../models/data/level_up_reward_data.dart';
```

with:

```dart
import '../models/data/level_up_reward_data.dart';
import '../models/data/xp_curve_data.dart';
```

Then append at the end of the file:

```dart

/// Remplit, dans [body], les deux paliers d'XP que la prose de l'étape
/// « L'Expérience » laisse à la courbe (spec P-43 E3, §5.3, A26) :
/// `{xpAct1}` et `{xpAct2}`, le prix d'un niveau à l'acte 1 et à l'acte 2.
///
/// Fonction **pure**, comme [fillRewardPlaceholders] : la courbe vient du
/// registre du tutoriel (ADR-081). Un texte qui ne nomme aucun placeholder
/// traverse inchangé.
String fillXpPlaceholders(String body, XpCurveData curve) => body
    .replaceAll('{xpAct1}', '${curve.thresholdFor(1)}')
    .replaceAll('{xpAct2}', '${curve.thresholdFor(2)}');
```

In `lib/tutorial/tutorial_screen.dart`, replace:

```dart
            final stepBody = fillRewardPlaceholders(
              isFrench ? currentStep.bodyFr : currentStep.bodyEn,
              widget.data.levelUpRewards,
              isFrench: isFrench,
            );
```

with:

```dart
            final stepBody = fillXpPlaceholders(
              fillRewardPlaceholders(
                isFrench ? currentStep.bodyFr : currentStep.bodyEn,
                widget.data.levelUpRewards,
                isFrench: isFrench,
              ),
              widget.data.xpCurve!,
            );
```

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        'Defeating enemies grants XP. Each level costs more than the last: '
        '100, then 150, then 225, and so on.\n\n'
```

with:

```dart
        'Defeating enemies grants XP. A level\'s price depends on the act: '
        '{xpAct1} XP in act 1, {xpAct2} in act 2, and so on — about two '
        'levels per act.\n\n'
```

Then replace:

```dart
        'Vaincre des ennemis rapporte de l\'XP. Chaque niveau coûte plus cher '
        'que le précédent : 100, puis 150, puis 225, et ainsi de suite.\n\n'
```

with:

```dart
        'Vaincre des ennemis rapporte de l\'XP. Le prix d\'un niveau dépend de '
        'l\'acte : {xpAct1} XP à l\'acte 1, {xpAct2} à l\'acte 2, et ainsi de '
        'suite — de quoi gagner deux niveaux par acte.\n\n'
```

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/tutorial/tutorial_engine_test.dart` — Expected: `+51: All tests passed!`
Run: `flutter test test/tutorial/tutorial_prose_test.dart` — Expected: `+8: All tests passed!`
Run: `flutter test test/tutorial/` — Expected: `All tests passed!` (dont `tutorial_isolation_test.dart` : aucun provider, ni `GameDataRegistry.instance`, dans `lib/tutorial/`).
Run: `flutter test test/widget/tutorial_class_step_test.dart test/widget/tutorial_armor_step_test.dart test/widget/tutorial_starter_draft_test.dart test/widget/tutorial_merge_widget_test.dart test/widget/tutorial_play_card_step_test.dart test/widget/tutorial_merge_transition_test.dart` — Expected: `All tests passed!`
Run: `git grep -n -e xpToNextLevel -e "pow(1.5" -- lib test` — Expected: aucune sortie.

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1508: All tests passed!` (1506 + 2 : la prose XP).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/tutorial/tutorial_engine.dart lib/tutorial/widgets/tutorial_xp_widget.dart lib/tutorial/tutorial_prose.dart lib/tutorial/tutorial_screen.dart lib/tutorial/tutorial_data.dart test/tutorial/tutorial_engine_test.dart test/tutorial/tutorial_prose_test.dart
git commit -F- <<'EOF'
feat(tutoriel): le palier d xp du tutoriel se lit sur la courbe

Le tutoriel perd son palier geometrique : TutorialEngine.xpThreshold lit
le palier de l acte 1 sur la courbe de son registre, et la barre d XP le
lit aussi. L etape de l experience nomme les paliers des actes 1 et 2 par
deux placeholders, remplis depuis la courbe.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: La trouvaille — `cardDrops`, `CardDrops.roll`, `foundCards`, `rewardCardFound`

D1, D31 (spec §3.1, §4.1, A1, A10 ; propriétaire n° 1 et n° 8 ; C3.1) : après un combat normal, une carte ; après une élite, une garantie et une seconde à 25 % ; le boss garde sa récompense. Les cartes sont tirées uniformément, avec remise, parmi `isOfferableTo` — le prédicat de la carte bonus (ADR-101) —, chacune **commune**, donc sans rune ; pool vide : aucune carte, sans repli (ADR-101 D4). `collectGoldAndXp` les ajoute au deck, sans refus ; l'écran de combat les notifie une par une (`rewardCardFound`), **à côté** de la notification de la carte bonus, qui reste jusqu'en partie 2. L'infobulle d'élite et la prose des nœuds Combat et Élite du tutoriel disent la carte. Le test de la transition E3 → E4 naît, sans sa clause du boss « XP ».

Changements de jeu de la tâche, voulus (spec §11) : une carte commune après chaque combat normal, une ou deux après une élite ; la notification « 🃏 Carte trouvée : … » ; l'infobulle d'élite et le tutoriel le disent. Le boss « XP » donne encore sa carte bonus (partie 2).

**Files:**
- Modify: `lib/game/game_constants.dart:1-2` (le `typedef` au niveau du fichier), après `:31` (`cardDrops`)
- Create: `lib/game/systems/card_drops.dart`
- Modify: `lib/game/controllers/reward_controller.dart:1-10`, `:12-67`, `:75-82`, après `:184`, `:196-208`, `:211-225`
- Modify: `lib/ui/screens/game_screen.dart:129-135`
- Modify: `lib/models/data/card_data.dart:158-159`
- Modify: `lib/l10n/app_en.arb:50`, `:105` ; `lib/l10n/app_fr.arb:27`, `:60` ; régénérés par `flutter gen-l10n` : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/tutorial/tutorial_data.dart:74-75`, `:90-91`
- Modify: `lib/tutorial/widgets/tutorial_node_types_widget.dart:37-38`, `:45-46`
- Create: `test/unit/scripted_random.dart`
- Test: `test/unit/card_drops_test.dart` *(nouveau)*
- Test: `test/unit/reward_controller_test.dart:1-16` (imports), après `:111` (aide), `:127-147` (cas réécrit), fin du groupe (groupe neuf)
- Test: `test/unit/signature_cards_transition_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `CardData.isOfferableTo(String heroClassId)` (`card_data.dart:170-173`) ; `DeckNotifier.addCardToMasterDeck(CardInstance)` ; `DeckState.fusionRankSum` (Task 1) ; `ForgeRuneRules.drawRunes(CardInstance, Iterable<ForgeUpgradeData>, Random, {required int count})` ; `xpCurveProvider` surchargé dans `reward_controller_test.dart` (Task 3).
- Produces:
  - `typedef CardDropRule = ({int guaranteed, List<int> extraChances});` (`lib/game/game_constants.dart`, niveau du fichier).
  - `GameConstants.cardDrops` (`static const Map<MapNodeType, CardDropRule>`) — combat `(guaranteed: 1, extraChances: [])`, élite `(guaranteed: 1, extraChances: [25])`.
  - `CardDrops.roll(CardDropRule? rule, {int extraGuaranteed = 0, int firstExtraBonus = 0, required Random rng}) → int` (`lib/game/systems/card_drops.dart`).
  - `RewardState.foundCards` (`List<CardInstance>`, défaut `const []`) ; `RewardState.copyWith({…, List<CardInstance>? foundCards, …})`.
  - `RewardController.handleVictory({…, Random? random})`.
  - ARB : `rewardCardFound(String cardName)` ; `tooltipEliteDesc` réécrite.
  - `class ScriptedRandom implements Random` (`test/unit/scripted_random.dart`) : `ScriptedRandom(List<int> script)` ; `nextInt(max)` rend la valeur suivante du script modulo `max`, le script repris au début.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/scripted_random.dart`:

```dart
import 'dart:math';

/// Un `Random` dont chaque tirage est écrit d'avance (spec P-43 E3, §8 :
/// « sur un `Random` dont le premier tirage est connu »). `nextInt(max)` rend
/// la valeur suivante du script, ramenée sous `max` ; au bout du script, il
/// reprend au début.
///
/// Un script `[24]` fait passer le jet de la seconde carte d'élite
/// (24 < 25), `[25]` le fait manquer ; ramenée sous la taille d'un pool, la
/// même valeur désigne aussi la carte tirée.
class ScriptedRandom implements Random {
  ScriptedRandom(this.script);

  final List<int> script;
  var _next = 0;

  @override
  int nextInt(int max) => script[_next++ % script.length] % max;

  @override
  double nextDouble() =>
      throw UnsupportedError('ScriptedRandom ne tire que des entiers');

  @override
  bool nextBool() =>
      throw UnsupportedError('ScriptedRandom ne tire que des entiers');
}
```

Create `test/unit/card_drops_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/card_drops.dart';
import 'package:roguelike_card_game/models/map_node.dart';

import 'scripted_random.dart';

/// Le tirage de la trouvaille (spec P-43 E3, §4.1, §8 ; D1, D31, D57) :
/// combien de cartes un combat gagné fait trouver.
void main() {
  final combat = GameConstants.cardDrops[MapNodeType.combat];
  final elite = GameConstants.cardDrops[MapNodeType.elite];

  test('un combat normal : une carte garantie', () {
    expect(CardDrops.roll(combat, rng: ScriptedRandom([0])), 1);
    expect(CardDrops.roll(combat, rng: ScriptedRandom([99])), 1);
  });

  test('extraGuaranteed s ajoute aux cartes garanties', () {
    expect(
      CardDrops.roll(combat, extraGuaranteed: 1, rng: ScriptedRandom([0])),
      2,
    );
  });

  test('une elite : une seconde carte si le jet passe sous 25', () {
    expect(CardDrops.roll(elite, rng: ScriptedRandom([24])), 2);
    expect(CardDrops.roll(elite, rng: ScriptedRandom([25])), 1);
  });

  test('le bonus ne vaut que pour le premier jet : a 75 et au-dela de 100, '
      'toujours deux cartes', () {
    for (var roll = 0; roll < 100; roll++) {
      expect(
        CardDrops.roll(elite, firstExtraBonus: 75, rng: ScriptedRandom([roll])),
        2,
        reason: 'jet $roll, bonus 75',
      );
      // Quatre Registres des primes : 125 — deux cartes, jamais trois.
      expect(
        CardDrops.roll(elite, firstExtraBonus: 100, rng: ScriptedRandom([roll])),
        2,
        reason: 'jet $roll, bonus 100',
      );
    }
  });

  test('une regle absente — le boss — ne donne rien', () {
    expect(GameConstants.cardDrops[MapNodeType.boss], isNull);
    expect(
      CardDrops.roll(
        null,
        extraGuaranteed: 1,
        firstExtraBonus: 75,
        rng: ScriptedRandom([0]),
      ),
      0,
    );
  });

  test('les jets s arretent au premier rate', () {
    const rule = (guaranteed: 1, extraChances: [50, 50]);

    expect(CardDrops.roll(rule, rng: ScriptedRandom([10, 10])), 3);
    expect(CardDrops.roll(rule, rng: ScriptedRandom([10, 90])), 2);
    // Le premier jet rate : le second, qui passerait, n'est pas tire.
    expect(CardDrops.roll(rule, rng: ScriptedRandom([90, 10])), 1);
    // Le bonus ne porte que le premier jet : le second rate a 90.
    expect(
      CardDrops.roll(rule, firstExtraBonus: 50, rng: ScriptedRandom([90, 90])),
      2,
    );
  });
}
```

In `test/unit/reward_controller_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

with:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
```

Then replace:

```dart
import 'package:flame/extensions.dart';
```

with:

```dart
import 'package:flame/extensions.dart';

import 'scripted_random.dart';
```

Then replace:

```dart
        heroClass: 'paladin',
        effects: [],
      ),
    ];

    setUp(() {
```

with:

```dart
        heroClass: 'paladin',
        effects: [],
      ),
    ];

    /// Le nombre de cartes trouvées à une victoire sur [node], les tirages de
    /// la trouvaille écrits d'avance par [script] (spec P-43 E3, §8).
    int foundOn(MapNode node, List<int> script) {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: node,
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
        random: ScriptedRandom(script),
      );
      return rewardController.state.foundCards.length;
    }

    setUp(() {
```

Then replace (`:127-147`):

```dart
    test('handleVictory sums gold/xp across enemies with per-level scaling, no relic/cards on a normal combat node', () {
```

with:

```dart
    test('handleVictory sums gold/xp across enemies with per-level scaling, no relic nor boss clone but one found card on a normal combat node', () {
```

Then replace, in that same case:

```dart
      expect(rewardController.state.rolledRelic, isNull);
      expect(rewardController.state.rolledCards, isEmpty);
      expect(rewardController.state.rolledBonusCard, isNull);
    });
```

with:

```dart
      expect(rewardController.state.rolledRelic, isNull);
      expect(rewardController.state.rolledCards, isEmpty);
      expect(rewardController.state.rolledBonusCard, isNull);
      // La trouvaille (spec P-43 E3, §4.1) : `c_normal`, la seule carte que
      // le paladin puisse recevoir — `c_status` est un statut, `c_unique`
      // une signature.
      expect(
        rewardController.state.foundCards.map((c) => c.data.id),
        ['c_normal'],
      );
    });
```

Then replace the end of the file:

```dart
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore);
      expect(rewardController.state.isCardsProcessed, isTrue);
      expect(rewardController.state.isResolved, isTrue);
    });
  });
}
```

with:

```dart
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore);
      expect(rewardController.state.isCardsProcessed, isTrue);
      expect(rewardController.state.isResolved, isTrue);
    });

    // La trouvaille (spec P-43 E3, §4.1, §8 ; D1, D31).
    group('la trouvaille', () {
      test('une carte en combat, une ou deux en elite, aucune au boss', () {
        expect(foundOn(makeNode(), [99]), 1);
        expect(foundOn(makeNode(type: MapNodeType.elite), [24]), 2);
        expect(foundOn(makeNode(type: MapNodeType.elite), [25]), 1);
        for (final reward in BossRewardType.values) {
          expect(
            foundOn(
              makeNode(type: MapNodeType.boss, bossRewardType: reward),
              [0],
            ),
            0,
            reason: reward.name,
          );
        }
      });

      test('les cartes trouvees sont communes et sans rune', () {
        const rare = CardData(
          id: 'c_rare',
          cost: 1,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.rare,
          target: CardTarget.singleEnemy,
          effects: [],
        );
        final rng = Random(3);
        final seen = <String>{};

        for (var i = 0; i < 100; i++) {
          rewardController.handleVictory(
            defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
            currentNode: makeNode(),
            allRelics: allRelics,
            allCards: [...allCards, rare],
            luck: 0,
            act: 1,
            random: rng,
          );
          for (final card in rewardController.state.foundCards) {
            expect(card.rarity, CardRarity.common, reason: card.data.id);
            expect(card.forgeUpgrades, isEmpty, reason: card.data.id);
            seen.add(card.data.id);
          }
        }

        // La rare de la donnee est trouvee, et trouvee commune.
        expect(seen, {'c_normal', 'c_rare'});
      });

      test('collectGoldAndXp ajoute les cartes trouvees au deck, une seule '
          'fois', () {
        expect(foundOn(makeNode(type: MapNodeType.elite), [24]), 2);
        final found = rewardController.state.foundCards;

        rewardController.collectGoldAndXp();
        expect(
          container.read(deckProvider).masterDeck.map((c) => c.uniqueId),
          found.map((c) => c.uniqueId),
        );

        // Idempotent : un second appel n'ajoute rien.
        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, hasLength(2));
      });

      test('la trouvaille ne tire que ce que la classe peut recevoir, jamais '
          'une unique', () {
        const mage = HeroData(
          id: 'mage',
          nameEn: 'Mage',
          nameFr: 'Mage',
          classCard: 'mage.png',
          maxHp: 80,
          maxMana: 4,
          luck: 0,
          mastery: 0,
        );
        runController.startNewRun(mage);

        CardData classCard(String id, String heroClass, CardRarity rarity) =>
            CardData(
              id: id,
              cost: 1,
              type: CardType.attack,
              category: CardCategory.characterSpecific,
              heroClass: heroClass,
              rarity: rarity,
              target: CardTarget.singleEnemy,
              effects: const [],
            );
        final mixedCards = [
          ...allCards,
          classCard('mage_rare', 'mage', CardRarity.rare),
          classCard('paladin_rare', 'paladin', CardRarity.rare),
          classCard('berserker_rare', 'berserker', CardRarity.rare),
          // Une unique de la classe du joueur : sa signature.
          classCard('mage_signature', 'mage', CardRarity.unique),
        ];
        final rng = Random(11);
        final seen = <String>{};

        for (var i = 0; i < 200; i++) {
          rewardController.handleVictory(
            defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
            currentNode: makeNode(),
            allRelics: allRelics,
            allCards: mixedCards,
            luck: 0,
            act: 1,
            random: rng,
          );
          // La donnee de la carte, jamais `card.rarity` : l'instance est
          // construite commune (spec §4.1), l'assertion ne garderait rien.
          for (final card in rewardController.state.foundCards) {
            expect(card.data.heroClass, anyOf(isNull, 'mage'),
                reason: card.data.id);
            expect(card.data.rarity, isNot(CardRarity.unique),
                reason: card.data.id);
            seen.add(card.data.id);
          }
        }

        // Les cartes de la classe du joueur sont admises.
        expect(seen, contains('mage_rare'));
      });

      test('sans carte offerte, la trouvaille ne donne rien, sans lever', () {
        // Seulement un statut et une signature : aucune carte offerte.
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: makeNode(type: MapNodeType.elite),
          allRelics: allRelics,
          allCards: [allCards[1], allCards[2]],
          luck: 0,
          act: 1,
          random: ScriptedRandom([0]),
        );
        expect(rewardController.state.foundCards, isEmpty);

        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, isEmpty);
      });
    });
  });
}
```

Create `test/unit/signature_cards_transition_test.dart`:

```dart
import 'dart:math';

import 'package:flame/extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/reward_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// La transition E3 → E4 (spec P-43 E3, §4.13, §8) : jusqu'à E4, les
/// signatures restent des cartes du deck — exclues de la trouvaille par
/// `unique`, sans rune offerte, au rang 0 pour la difficulté. Sur le
/// registre réel.
///
/// La clause du boss « XP » — il ne monte jamais une rune de signature —
/// vient en partie 2, avec le boss.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  late Set<String> signatureIds;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
    // Ce que chaque classe déclare, et que son dossier porte
    // (`referential_integrity_test.dart:211-229`) — C3.1.
    signatureIds = registry.heroes.expand((h) => h.skills).toSet();
  });

  test('la trouvaille ne donne jamais une signature, ni une carte d une autre '
      'classe', () {
    // Un ensemble vide rendrait la clause vraie d'office (C3.1).
    expect(signatureIds, hasLength(6));

    for (final hero in registry.heroes) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      final rewards = container.read(rewardProvider.notifier);
      final rng = Random(7);
      final node = MapNode(
        id: 'node_0_0',
        floor: 0,
        type: MapNodeType.combat,
        connections: const [],
        position: Vector2.zero(),
      );

      for (var i = 0; i < 200; i++) {
        rewards.handleVictory(
          defeatedEnemies: const [],
          currentNode: node,
          allRelics: registry.relics,
          allCards: registry.cards,
          luck: 0,
          act: 1,
          random: rng,
        );
        // La donnée de la carte, jamais `card.rarity`, que l'instance porte
        // `common` (spec §4.1) : l'assertion ne garderait rien.
        for (final card in rewards.state.foundCards) {
          final reason = '${hero.id} : ${card.data.id}';
          expect(card.data.rarity, isNot(CardRarity.unique), reason: reason);
          expect(card.data.heroClass, anyOf(isNull, hero.id), reason: reason);
          expect(signatureIds, isNot(contains(card.data.id)), reason: reason);
        }
      }
    }
  });

  test('une signature ne recoit aucune rune offerte', () {
    for (final id in signatureIds) {
      final signature = registry.cards.singleWhere((c) => c.id == id);
      expect(
        ForgeRuneRules.drawRunes(
          CardInstance(data: signature),
          registry.forgeUpgrades,
          Random(1),
          count: 3,
        ),
        isEmpty,
        reason: id,
      );
    }
  });

  test('un deck des deux signatures et de communes pese zero pour la '
      'difficulte', () {
    final neutrals = registry.cards.where((c) => c.heroClass == null).take(5);

    for (final hero in registry.heroes) {
      final deck = DeckState(masterDeck: [
        for (final id in hero.skills)
          CardInstance(data: registry.cards.singleWhere((c) => c.id == id)),
        for (final card in neutrals)
          CardInstance(data: card, rarity: CardRarity.common),
      ]);
      expect(deck.fusionRankSum, 0, reason: hero.id);
    }
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/card_drops_test.dart test/unit/reward_controller_test.dart test/unit/signature_cards_transition_test.dart`
Expected: FAIL à la compilation — `Target of URI doesn't exist: 'package:roguelike_card_game/game/systems/card_drops.dart'`, `The getter 'cardDrops' isn't defined for the type 'GameConstants'` et `No named parameter with the name 'random'`.

- [ ] **Step 3: La table et son tirage**

In `lib/game/game_constants.dart`, replace:

```dart
import 'package:flame/components.dart';
import 'package:roguelike_card_game/models/map_node.dart';

class GameConstants {
```

with:

```dart
import 'package:flame/components.dart';
import 'package:roguelike_card_game/models/map_node.dart';

/// Une règle de trouvaille : [guaranteed] cartes garanties, puis des jets
/// successifs, en pourcentage — le premier raté arrête.
typedef CardDropRule = ({int guaranteed, List<int> extraChances});

class GameConstants {
```

Then replace:

```dart
    MapNodeType.event: (min: 4, max: 9),
  };
```

with:

```dart
    MapNodeType.event: (min: 4, max: 9),
  };

  // --- TROUVAILLE (D1, D31, D57) ---
  /// Les cartes trouvées après un combat, par type de nœud. Un type absent
  /// n'en donne aucune : le boss garde sa récompense (D1).
  static const Map<MapNodeType, CardDropRule> cardDrops = {
    MapNodeType.combat: (guaranteed: 1, extraChances: []),
    MapNodeType.elite: (guaranteed: 1, extraChances: [25]),
  };
```

Create `lib/game/systems/card_drops.dart`:

```dart
import 'dart:math';

import '../game_constants.dart';

/// Le tirage de la trouvaille (spec P-43 E3, §4.1 ; D1, D31, D57) : combien
/// de cartes un combat gagné fait trouver. Fonction pure ; lesquelles, c'est
/// `RewardController.handleVictory` qui les tire.
abstract final class CardDrops {
  /// [rule] nulle — un type de nœud absent de `GameConstants.cardDrops`, le
  /// boss — : aucune carte. Sinon `guaranteed + extraGuaranteed`, puis un
  /// jet par chance de `extraChances`, la première augmentée de
  /// [firstExtraBonus] : une carte de plus si `rng.nextInt(100) < chance`,
  /// l'arrêt au premier raté.
  static int roll(
    CardDropRule? rule, {
    int extraGuaranteed = 0,
    int firstExtraBonus = 0,
    required Random rng,
  }) {
    if (rule == null) return 0;
    var count = rule.guaranteed + extraGuaranteed;
    for (var i = 0; i < rule.extraChances.length; i++) {
      final chance = rule.extraChances[i] + (i == 0 ? firstExtraBonus : 0);
      if (rng.nextInt(100) >= chance) break;
      count++;
    }
    return count;
  }
}
```

- [ ] **Step 4: La récompense tire les cartes trouvées et les ajoute au deck**

In `lib/game/controllers/reward_controller.dart`, replace:

```dart
import '../../models/enemy_instance.dart';
import 'inventory_controller.dart';
```

with:

```dart
import '../../models/enemy_instance.dart';
import '../game_constants.dart';
import '../systems/card_drops.dart';
import 'inventory_controller.dart';
```

Then replace:

```dart
  final bool isResolved;
  final CardData? rolledBonusCard;

  const RewardState({
```

with:

```dart
  final bool isResolved;
  final CardData? rolledBonusCard;

  /// Les cartes trouvées à la victoire (spec P-43 E3, §4.1 ; D1) : tirées
  /// par `handleVictory`, toujours communes, elles rejoignent le deck à
  /// `collectGoldAndXp`, sans refus.
  final List<CardInstance> foundCards;

  const RewardState({
```

Then replace:

```dart
    this.isResolved = false,
    this.rolledBonusCard,
  });
```

with:

```dart
    this.isResolved = false,
    this.rolledBonusCard,
    this.foundCards = const [],
  });
```

Then replace:

```dart
    bool? isResolved,
    CardData? rolledBonusCard,
  }) {
```

with:

```dart
    bool? isResolved,
    CardData? rolledBonusCard,
    List<CardInstance>? foundCards,
  }) {
```

Then replace:

```dart
      rolledBonusCard: rolledBonusCard ?? this.rolledBonusCard,
    );
  }
}
```

with:

```dart
      rolledBonusCard: rolledBonusCard ?? this.rolledBonusCard,
      foundCards: foundCards ?? this.foundCards,
    );
  }
}
```

Then replace:

```dart
  void handleVictory({
    required List<EnemyInstance> defeatedEnemies,
    required MapNode currentNode,
    required List<RelicData> allRelics,
    required List<CardData> allCards,
    required int luck,
    required int act,
  }) {
```

with:

```dart
  /// [random] : le tirage de la trouvaille — combien de cartes, lesquelles.
  /// Passé par les tests pour connaître ses jets (spec P-43 E3, §4.1) ; en
  /// jeu, un `Random` neuf. Les autres tirages de la victoire n'en dépendent
  /// pas.
  void handleVictory({
    required List<EnemyInstance> defeatedEnemies,
    required MapNode currentNode,
    required List<RelicData> allRelics,
    required List<CardData> allCards,
    required int luck,
    required int act,
    Random? random,
  }) {
```

Then replace:

```dart
            forgeUpgrades: candidates[i].forgeUpgrades,
          ));
        }
      }
    }

    CardData? rolledBonusCard;
```

with:

```dart
            forgeUpgrades: candidates[i].forgeUpgrades,
          ));
        }
      }
    }

    // 5. La trouvaille (spec P-43 E3, §4.1 ; D1, D31) : des cartes tirées
    // uniformément, avec remise, parmi celles que la classe peut recevoir —
    // le prédicat de la carte bonus (ADR-101) —, toujours communes, donc sans
    // rune. Pool vide : aucune carte, sans repli (ADR-101 D4).
    final run = ref.read(runProvider);
    final rng = random ?? Random();
    final offerable =
        allCards.where((c) => c.isOfferableTo(run.heroClassId)).toList();
    final foundCards = <CardInstance>[];
    if (offerable.isNotEmpty) {
      final count = CardDrops.roll(
        GameConstants.cardDrops[currentNode.type],
        rng: rng,
      );
      for (var i = 0; i < count; i++) {
        foundCards.add(CardInstance(
          data: offerable[rng.nextInt(offerable.length)],
          rarity: CardRarity.common,
        ));
      }
    }

    CardData? rolledBonusCard;
```

Then replace:

```dart
      isResolved: false,
      rolledBonusCard: rolledBonusCard,
    );
  }
```

with:

```dart
      isResolved: false,
      rolledBonusCard: rolledBonusCard,
      foundCards: foundCards,
    );
  }
```

Then replace:

```dart
    if (state.rolledBonusCard != null) {
      ref.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: state.rolledBonusCard!));
    }
```

with:

```dart
    if (state.rolledBonusCard != null) {
      ref.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: state.rolledBonusCard!));
    }

    // Les cartes trouvées rejoignent le deck, sans refus (spec P-43 E3, §4.1).
    final deck = ref.read(deckProvider.notifier);
    for (final card in state.foundCards) {
      deck.addCardToMasterDeck(card);
    }
```

In `lib/models/data/card_data.dart`, replace:

```dart
  /// Cette carte peut-elle être proposée au héros de classe [heroClassId] par
  /// un pool d'offre — boutique, bonus de boss ?
```

with:

```dart
  /// Cette carte peut-elle être proposée au héros de classe [heroClassId] par
  /// un pool d'offre — boutique, bonus de boss, trouvaille ?
```

- [ ] **Step 5: Les textes — la notification, l'infobulle d'élite, le tutoriel**

In `lib/l10n/app_en.arb`, replace:

```
  "combatReward": "COMBAT REWARD",
```

with:

```
  "combatReward": "COMBAT REWARD",
  "rewardCardFound": "🃏 Card found: {cardName}",
  "@rewardCardFound": {
    "placeholders": {
      "cardName": { "type": "String" }
    }
  },
```

Then replace:

```
  "tooltipEliteDesc": "A much tougher fight, but guarantees a relic reward.",
```

with:

```
  "tooltipEliteDesc": "A much tougher fight: a guaranteed relic, and a card — sometimes two.",
```

In `lib/l10n/app_fr.arb`, replace:

```
  "combatReward": "RÉCOMPENSE DE COMBAT",
```

with:

```
  "combatReward": "RÉCOMPENSE DE COMBAT",
  "rewardCardFound": "🃏 Carte trouvée : {cardName}",
```

Then replace:

```
  "tooltipEliteDesc": "Un combat bien plus rude, mais garantit l'obtention d'une relique.",
```

with:

```
  "tooltipEliteDesc": "Un combat bien plus rude : une relique garantie, et une carte — parfois deux.",
```

Run: `flutter gen-l10n` — Expected: les trois `lib/l10n/app_localizations*.dart` régénérés, `rewardCardFound(String cardName)` dans `app_localizations.dart`.

In `lib/ui/screens/game_screen.dart`, replace:

```dart
      if (rewardState.rolledBonusCard != null) {
        final bonusCardName = locale == 'fr' ? rewardState.rolledBonusCard!.nameFr : rewardState.rolledBonusCard!.nameEn;
        context.showNotification(
          '🎁 ${locale == 'fr' ? 'Carte Bonus obtenue : $bonusCardName' : 'Bonus Card obtained: $bonusCardName'}',
          type: NotificationType.success,
        );
      }
```

with:

```dart
      if (rewardState.rolledBonusCard != null) {
        final bonusCardName = locale == 'fr' ? rewardState.rolledBonusCard!.nameFr : rewardState.rolledBonusCard!.nameEn;
        context.showNotification(
          '🎁 ${locale == 'fr' ? 'Carte Bonus obtenue : $bonusCardName' : 'Bonus Card obtained: $bonusCardName'}',
          type: NotificationType.success,
        );
      }

      // Une notification par carte trouvée, qui la nomme (spec P-43 E3,
      // §4.1, A10) : elle entre au deck sans refus. Tirées par
      // `handleVictory`, elles se lisent sur la copie prise plus haut.
      final l10n = AppLocalizations.of(context)!;
      for (final card in rewardState.foundCards) {
        context.showNotification(
          l10n.rewardCardFound(card.data.getName(locale)),
          type: NotificationType.success,
        );
      }
```

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        '• ⚔️ Combat: a standard fight, for gold and XP.\n'
        '• 👑 Elite: a hard fight that rewards a Relic.\n'
```

with:

```dart
        '• ⚔️ Combat: a standard fight, for gold, XP and a card.\n'
        '• 👑 Elite: a hard fight that rewards a Relic and a card — sometimes '
        'two.\n'
```

Then replace:

```dart
        '• ⚔️ Combat : affrontement standard, pour l\'or et l\'XP.\n'
        '• 👑 Élite : combat difficile qui récompense par une Relique.\n'
```

with:

```dart
        '• ⚔️ Combat : affrontement standard, pour l\'or, l\'XP et une carte.\n'
        '• 👑 Élite : combat difficile qui récompense par une Relique et une '
        'carte — parfois deux.\n'
```

In `lib/tutorial/widgets/tutorial_node_types_widget.dart`, replace:

```dart
      descEn: 'Fight base monsters for gold & XP.',
      descFr: 'Combattez des monstres pour de l\'or et XP.',
```

with:

```dart
      descEn: 'Fight base monsters for gold, XP and a card.',
      descFr: 'Combattez des monstres pour de l\'or, de l\'XP et une carte.',
```

Then replace:

```dart
      descEn: 'Difficult fight. Rewards a Relic.',
      descFr: 'Combat difficile. Offre une Relique.',
```

with:

```dart
      descEn: 'Difficult fight. Rewards a Relic and a card.',
      descFr: 'Combat difficile. Offre une Relique et une carte.',
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/card_drops_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/unit/reward_controller_test.dart` — Expected: `+20: All tests passed!`
Run: `flutter test test/unit/signature_cards_transition_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/tutorial/ test/unit/card_offer_filter_test.dart` — Expected: `All tests passed!`
Run: `git grep -n rewardCardFound -- lib/ui/screens/game_screen.dart` — Expected: au moins une ligne (spec §8, quatrième commande sur l'écran de combat).
Run: `git grep -n rolledBonusCard -- lib` — Expected: des lignes dans `lib/game/controllers/reward_controller.dart` et `lib/ui/screens/game_screen.dart` — la carte bonus reste jusqu'en partie 2.

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1522: All tests passed!` (1508 + 14 : le tirage +6, la récompense +5, la transition +3).

- [ ] **Step 8: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/game_constants.dart lib/game/systems/card_drops.dart lib/game/controllers/reward_controller.dart lib/ui/screens/game_screen.dart lib/models/data/card_data.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_node_types_widget.dart test/unit/scripted_random.dart test/unit/card_drops_test.dart test/unit/reward_controller_test.dart test/unit/signature_cards_transition_test.dart
git commit -F- <<'EOF'
feat(trouvaille): chaque combat rapporte une carte commune

GameConstants.cardDrops donne une carte en combat normal, une garantie
et une seconde a 25 pour cent en elite ; CardDrops.roll la tire. La
victoire tire les cartes parmi celles que la classe peut recevoir,
communes, et les ajoute au deck ; l ecran les notifie une par une.
L infobulle d elite et le tutoriel le disent. Un test garde la
transition vers E4 : aucune signature dans la trouvaille.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: Les reliques A et C — le *Registre des primes* et la *Sacoche du glaneur*

D31, D57 (spec §3.3, §4.1, §4.2) : deux reliques rares, `startOfRun`, dont l'effet est une règle de run posée à l'acquisition et retirée symétriquement — sur le modèle exact d'`increase_cards_per_turn`, ce qui garde l'Autel de toute fuite. `RunState` gagne `extraCombatCards` et `eliteCardChanceBonus` (en points de pourcentage) ; `PlayerStatsManager.applyRunRuleModifier`, le seul à les recevoir, gagne deux accumulateurs (le relais de `RunController` n'en gagne aucun, levée du second arrêt n° 9) ; `applyRelicEffect` et `removeRelicEffect` gagnent les deux `effectType`. `handleVictory` passe la *Sacoche* (C) au seul combat normal, le *Registre* (A) à la seule élite. Les comptes du catalogue livré suivent : 27 reliques, 90 fichiers d'entité, 54 fichiers de contenu audio.

Changements de jeu de la tâche, voulus (spec §11) : deux reliques rares entrent dans les tirages de reliques — le *Registre des primes* (+25 % de seconde carte en élite, par exemplaire) et la *Sacoche du glaneur* (une carte de plus en combat normal, par exemplaire).

**Files:**
- Create: `assets/data/relics/bounty_ledger.json`, `assets/data/relics/gleaners_pouch.json`
- Modify: `lib/game/controllers/run_controller.dart` (les champs, le constructeur, `copyWith`, `toJson`, `fromJsonWithReport`, tels que Task 2 les a laissés)
- Modify: `lib/game/controllers/run/player_stats_manager.dart:99-108`, `:298-304`, `:453-455`
- Modify: `lib/game/controllers/reward_controller.dart` (l'appel de `CardDrops.roll`, tel que Task 5 l'a laissé)
- Test: `test/unit/shipped_data.dart:1-6` (import), après `:22` (aide)
- Test: `test/unit/relic_exchange_test.dart:1-8` (import), après `:149` (deux cas neufs)
- Test: `test/unit/run_state_persistence_test.dart` (cas neuf après celui de `maxHandSize`, Task 2)
- Test: `test/unit/reward_controller_test.dart:1-20` (import), fin du groupe `la trouvaille` (groupe neuf)
- Test: `test/unit/real_bundle_load_test.dart:24`, `:36`, `:95`
- Test: `test/unit/entity_id_convention_test.dart:64-71`
- Test: `test/unit/audio/audio_catalogue_test.dart:51-52`

**Interfaces:**
- Consumes: `CardDrops.roll(…, extraGuaranteed:, firstExtraBonus:, rng:)` et `foundOn` (Task 5) ; `InventoryController.addRelic(RelicData)` (`inventory_controller.dart:27-32`) ; `RunController.exchangeRelics(List<RelicData>, RelicData)`.
- Produces:
  - `RunState.extraCombatCards` (`int`, 0) et `RunState.eliteCardChanceBonus` (`int`, 0, en points de pourcentage) ; `copyWith({…, int? extraCombatCards, int? eliteCardChanceBonus, …})` ; clés JSON `extraCombatCards`, `eliteCardChanceBonus`, absentes → 0.
  - `PlayerStatsManager.applyRunRuleModifier({int cardsPerTurnAcc = 0, int extraCombatCardsAcc = 0, int eliteCardChanceAcc = 0})`.
  - `effectType` `increase_combat_card_drops` et `increase_elite_card_chance`.
  - `RelicData shippedRelic(String id)` (`test/unit/shipped_data.dart`).

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/shipped_data.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
```

Then replace:

```dart
/// Une carte neutre telle que le jeu la livre (`assets/data/cards/`).
CardData shippedCard(String id) =>
    CardData.fromJson(_shipped('assets/data/cards/$id.json', id));
```

with:

```dart
/// Une carte neutre telle que le jeu la livre (`assets/data/cards/`).
CardData shippedCard(String id) =>
    CardData.fromJson(_shipped('assets/data/cards/$id.json', id));

/// Une relique telle que le jeu la livre (`assets/data/relics/`).
RelicData shippedRelic(String id) =>
    RelicData.fromJson(_shipped('assets/data/relics/$id.json', id));
```

In `test/unit/relic_exchange_test.dart`, replace:

```dart
import 'package:roguelike_card_game/services/map_generator_service.dart';
```

with:

```dart
import 'package:roguelike_card_game/services/map_generator_service.dart';

import 'shipped_data.dart';
```

Then replace the end of the file:

```dart
      runController.exchangeRelics([satchel], filler);
      expect(runController.state.cardsPerTurn, 5);
      expect(
        inventoryController.state.relics.any((r) => r.id == 'scholars_satchel'),
        isFalse,
      );
    });
  });
}
```

with:

```dart
      runController.exchangeRelics([satchel], filler);
      expect(runController.state.cardsPerTurn, 5);
      expect(
        inventoryController.state.relics.any((r) => r.id == 'scholars_satchel'),
        isFalse,
      );
    });

    // Les deux reliques de la trouvaille (spec P-43 E3, §4.2) : une règle de
    // run posée à l'acquisition, rendue à l'échange, deux exemplaires
    // additionnés.
    test('increase_combat_card_drops s applique, s additionne et se retire',
        () {
      const gained = RelicData(
        id: 'gained',
        nameEn: 'Gained',
        trigger: RelicTrigger.startOfCombat,
        effectType: 'gain_armor',
        value: 1,
        rarity: RelicRarity.common,
        emoji: '⬜',
      );
      final pouch = shippedRelic('gleaners_pouch');
      expect(runController.state.extraCombatCards, 0);

      inventoryController.addRelic(pouch);
      inventoryController.addRelic(pouch);
      expect(runController.state.extraCombatCards, 2);

      runController.exchangeRelics([pouch], gained);
      expect(runController.state.extraCombatCards, 1);
    });

    test('increase_elite_card_chance s applique, s additionne et se retire',
        () {
      const gained = RelicData(
        id: 'gained',
        nameEn: 'Gained',
        trigger: RelicTrigger.startOfCombat,
        effectType: 'gain_armor',
        value: 1,
        rarity: RelicRarity.common,
        emoji: '⬜',
      );
      final ledger = shippedRelic('bounty_ledger');
      expect(runController.state.eliteCardChanceBonus, 0);

      inventoryController.addRelic(ledger);
      inventoryController.addRelic(ledger);
      expect(runController.state.eliteCardChanceBonus, 50);

      runController.exchangeRelics([ledger], gained);
      expect(runController.state.eliteCardChanceBonus, 25);
    });
  });
}
```

In `test/unit/run_state_persistence_test.dart`, replace:

```dart
      final legacy = Map<String, dynamic>.from(json)..remove('maxHandSize');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.maxHandSize, GameConstants.startingMaxHandSize);
    });
```

with:

```dart
      final legacy = Map<String, dynamic>.from(json)..remove('maxHandSize');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.maxHandSize, GameConstants.startingMaxHandSize);
    });

    // Les deux règles de trouvaille des reliques (spec P-43 E3, §3.8, §8).
    test('extraCombatCards et eliteCardChanceBonus round-trip et valent 0 '
        'quand la cle manque', () {
      final json = buildRunState()
          .copyWith(extraCombatCards: 2, eliteCardChanceBonus: 50)
          .toJson();
      expect(json['extraCombatCards'], 2);
      expect(json['eliteCardChanceBonus'], 50);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.extraCombatCards, 2);
      expect(restored.eliteCardChanceBonus, 50);

      final legacy = Map<String, dynamic>.from(json)
        ..remove('extraCombatCards')
        ..remove('eliteCardChanceBonus');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.extraCombatCards, 0);
      expect(restoredLegacy.eliteCardChanceBonus, 0);
    });
```

In `test/unit/reward_controller_test.dart`, replace:

```dart
import 'scripted_random.dart';
```

with:

```dart
import 'scripted_random.dart';
import 'shipped_data.dart';
```

Then replace the end of the file (the last case of the group `la trouvaille`, Task 5):

```dart
        expect(rewardController.state.foundCards, isEmpty);

        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, isEmpty);
      });
    });
  });
}
```

with:

```dart
        expect(rewardController.state.foundCards, isEmpty);

        rewardController.collectGoldAndXp();
        expect(container.read(deckProvider).masterDeck, isEmpty);
      });
    });

    // Les bonus des reliques, lus par `handleVictory` (spec P-43 E3, §4.1) :
    // C ne touche que le combat normal, A que l'élite (D31, D57).
    group('les reliques de la trouvaille', () {
      test('la Sacoche du glaneur ajoute une carte au combat normal, jamais a '
          'l elite', () {
        inventoryController.addRelic(shippedRelic('gleaners_pouch'));

        expect(foundOn(makeNode(), [99]), 2);
        expect(foundOn(makeNode(type: MapNodeType.elite), [25]), 1);
      });

      test('trois Registres des primes portent le jet d elite a 100, jamais '
          'le combat normal', () {
        for (var i = 0; i < 3; i++) {
          inventoryController.addRelic(shippedRelic('bounty_ledger'));
        }
        expect(runController.state.eliteCardChanceBonus, 75);

        // 99 rate a 25, passe a 100.
        expect(foundOn(makeNode(type: MapNodeType.elite), [99]), 2);
        expect(foundOn(makeNode(), [0]), 1);
      });

      test('aucune des deux ne fait trouver une carte au boss', () {
        inventoryController.addRelic(shippedRelic('gleaners_pouch'));
        inventoryController.addRelic(shippedRelic('bounty_ledger'));

        for (final reward in BossRewardType.values) {
          expect(
            foundOn(
              makeNode(type: MapNodeType.boss, bossRewardType: reward),
              [0],
            ),
            0,
            reason: reward.name,
          );
        }
      });
    });
  });
}
```

In `test/unit/real_bundle_load_test.dart`, replace:

```dart
  test('le manifeste declare les 85 fichiers d entite, par categorie', () async {
```

with:

```dart
  test('le manifeste declare les 90 fichiers d entite, par categorie', () async {
```

Then replace:

```dart
    expect(countUnder('assets/data/relics/', 4), 25, reason: 'reliques');
```

with:

```dart
    expect(countUnder('assets/data/relics/', 4), 27, reason: 'reliques');
```

Then replace:

```dart
    expect(registry.relics, hasLength(25));
```

with:

```dart
    expect(registry.relics, hasLength(27));
```

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 88 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 11 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 88,
        reason: '17 cartes neutres + 25 reliques + 5 evenements + 11 '
```

with:

```dart
  test('il y a bien 90 fichiers d entite', () {
    // 17 cartes neutres + 27 reliques (dont le Registre des primes et la
    // Sacoche du glaneur, P-43 E3) + 5 evenements + 11 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 90,
        reason: '17 cartes neutres + 27 reliques + 5 evenements + 11 '
```

In `test/unit/audio/audio_catalogue_test.dart`, replace:

```dart
      expect(contentFiles.length, 52,
          reason: '17 cartes + 25 reliques + 6 cartes de classe + 4 ennemis');
```

with:

```dart
      expect(contentFiles.length, 54,
          reason: '17 cartes + 27 reliques + 6 cartes de classe + 4 ennemis');
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/relic_exchange_test.dart test/unit/run_state_persistence_test.dart test/unit/reward_controller_test.dart`
Expected: FAIL à la compilation — `The getter 'extraCombatCards' isn't defined for the type 'RunState'` et `No named parameter with the name 'extraCombatCards'`.

- [ ] **Step 3: Les deux fichiers de relique**

Create `assets/data/relics/bounty_ledger.json`:

```json
{
  "id": "bounty_ledger",
  "name_en": "Bounty Ledger",
  "name_fr": "Registre des primes",
  "description_en": "After an elite fight, +25% chance to find a second card.",
  "description_fr": "Après un combat d'élite, +25 % de chance de trouver une seconde carte.",
  "trigger": "startOfRun",
  "effectType": "increase_elite_card_chance",
  "value": 25,
  "rarity": "rare",
  "emoji": "📜"
}
```

Create `assets/data/relics/gleaners_pouch.json`:

```json
{
  "id": "gleaners_pouch",
  "name_en": "Gleaner's Pouch",
  "name_fr": "Sacoche du glaneur",
  "description_en": "After a normal fight, find one more card.",
  "description_fr": "Après un combat normal, trouvez une carte de plus.",
  "trigger": "startOfRun",
  "effectType": "increase_combat_card_drops",
  "value": 1,
  "rarity": "rare",
  "emoji": "👝"
}
```

(Les deux déclarent leur `"id"`, égal au nom du fichier : le chargeur du script de simulation le lit en dur, `d26_economy_sim.dart:756` — spec §3.3, §9.)

- [ ] **Step 4: Les deux règles de run sur `RunState`**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  final int maxHandSize;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
```

with:

```dart
  final int maxHandSize;

  /// Les deux règles de trouvaille que portent les reliques (spec P-43 E3,
  /// §4.1, §4.2 ; D31, D57) : [extraCombatCards] cartes garanties de plus
  /// après un combat normal (la *Sacoche du glaneur*, +1 par exemplaire), et
  /// [eliteCardChanceBonus] points de pourcentage de plus au jet de la
  /// seconde carte d'élite (le *Registre des primes*, +25 par exemplaire).
  final int extraCombatCards;
  final int eliteCardChanceBonus;

  /// Les règles de stat de la classe (spec P-41, §7.1), pour la même raison
```

Then replace:

```dart
    this.maxHandSize = GameConstants.startingMaxHandSize,
    this.statRules = const [],
  });
```

with:

```dart
    this.maxHandSize = GameConstants.startingMaxHandSize,
    this.extraCombatCards = 0,
    this.eliteCardChanceBonus = 0,
    this.statRules = const [],
  });
```

Then replace:

```dart
    int? maxHandSize,
    List<StatRule>? statRules,
  }) {
```

with:

```dart
    int? maxHandSize,
    int? extraCombatCards,
    int? eliteCardChanceBonus,
    List<StatRule>? statRules,
  }) {
```

Then replace:

```dart
      maxHandSize: maxHandSize ?? this.maxHandSize,
```

with:

```dart
      maxHandSize: maxHandSize ?? this.maxHandSize,
      extraCombatCards: extraCombatCards ?? this.extraCombatCards,
      eliteCardChanceBonus: eliteCardChanceBonus ?? this.eliteCardChanceBonus,
```

Then replace:

```dart
        'maxHandSize': maxHandSize,
      };
```

with:

```dart
        'maxHandSize': maxHandSize,
        'extraCombatCards': extraCombatCards,
        'eliteCardChanceBonus': eliteCardChanceBonus,
      };
```

Then replace:

```dart
      maxHandSize:
          json['maxHandSize'] as int? ?? GameConstants.startingMaxHandSize,
```

with:

```dart
      maxHandSize:
          json['maxHandSize'] as int? ?? GameConstants.startingMaxHandSize,
      extraCombatCards: json['extraCombatCards'] as int? ?? 0,
      eliteCardChanceBonus: json['eliteCardChanceBonus'] as int? ?? 0,
```

- [ ] **Step 5: Les accumulateurs et les deux `effectType`**

In `lib/game/controllers/run/player_stats_manager.dart`, replace:

```dart
  /// Applique un modificateur aux règles de run propres au joueur.
  /// Distinct d'`applyHeroStatModifier`, qui opère sur `EntityStats` — lequel
  /// est partagé avec les ennemis et n'a donc pas à porter de notion de deck.
  void applyRunRuleModifier({int cardsPerTurnAcc = 0}) {
    controller.updateState(
      controller.currentState.copyWith(
        cardsPerTurn: controller.currentState.cardsPerTurn + cardsPerTurnAcc,
      ),
    );
  }
```

with:

```dart
  /// Applique un modificateur aux règles de run propres au joueur.
  /// Distinct d'`applyHeroStatModifier`, qui opère sur `EntityStats` — lequel
  /// est partagé avec les ennemis et n'a donc pas à porter de notion de deck.
  /// Le seul à recevoir les deux règles de trouvaille : seules les reliques
  /// les écrivent, par `applyRelicEffect` et `removeRelicEffect` (spec P-43
  /// E3, §3.8, §4.2).
  void applyRunRuleModifier({
    int cardsPerTurnAcc = 0,
    int extraCombatCardsAcc = 0,
    int eliteCardChanceAcc = 0,
  }) {
    final run = controller.currentState;
    controller.updateState(
      run.copyWith(
        cardsPerTurn: run.cardsPerTurn + cardsPerTurnAcc,
        extraCombatCards: run.extraCombatCards + extraCombatCardsAcc,
        eliteCardChanceBonus: run.eliteCardChanceBonus + eliteCardChanceAcc,
      ),
    );
  }
```

Then replace:

```dart
      // Cet effectType n'a de sens qu'en `startOfRun` : une variante par combat
      // ou par tour cumulerait indéfiniment. Aucune garde n'est posée ici, le
      // contrat étant porté par la donnée (`assets/data/relics/`) et par le `case`
      // symétrique de `removeRelicEffect`.
      case 'increase_cards_per_turn':
        applyRunRuleModifier(cardsPerTurnAcc: relic.value);
        break;
```

with:

```dart
      // Ces trois effectTypes n'ont de sens qu'en `startOfRun` : une variante
      // par combat ou par tour cumulerait indéfiniment. Aucune garde n'est
      // posée ici, le contrat étant porté par la donnée (`assets/data/relics/`)
      // et par les `case` symétriques de `removeRelicEffect`.
      case 'increase_cards_per_turn':
        applyRunRuleModifier(cardsPerTurnAcc: relic.value);
        break;
      // Les deux règles de trouvaille (spec P-43 E3, §4.2) : la *Sacoche du
      // glaneur* et le *Registre des primes*.
      case 'increase_combat_card_drops':
        applyRunRuleModifier(extraCombatCardsAcc: relic.value);
        break;
      case 'increase_elite_card_chance':
        applyRunRuleModifier(eliteCardChanceAcc: relic.value);
        break;
```

Then replace:

```dart
        case 'increase_cards_per_turn':
          applyRunRuleModifier(cardsPerTurnAcc: -relic.value);
          break;
      }
```

with:

```dart
        case 'increase_cards_per_turn':
          applyRunRuleModifier(cardsPerTurnAcc: -relic.value);
          break;
        case 'increase_combat_card_drops':
          applyRunRuleModifier(extraCombatCardsAcc: -relic.value);
          break;
        case 'increase_elite_card_chance':
          applyRunRuleModifier(eliteCardChanceAcc: -relic.value);
          break;
      }
```

- [ ] **Step 6: La trouvaille lit les deux règles**

In `lib/game/controllers/reward_controller.dart`, replace:

```dart
      final count = CardDrops.roll(
        GameConstants.cardDrops[currentNode.type],
        rng: rng,
      );
```

with:

```dart
      // Les deux règles des reliques : C (+1 carte garantie) au seul combat
      // normal, A (+N points au premier jet) à la seule élite — jamais l'une
      // sur le nœud de l'autre, ni sur un boss (D31, D57).
      final count = CardDrops.roll(
        GameConstants.cardDrops[currentNode.type],
        extraGuaranteed:
            currentNode.type == MapNodeType.combat ? run.extraCombatCards : 0,
        firstExtraBonus:
            currentNode.type == MapNodeType.elite ? run.eliteCardChanceBonus : 0,
        rng: rng,
      );
```

- [ ] **Step 7: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/relic_exchange_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/unit/run_state_persistence_test.dart` — Expected: `+5: All tests passed!`
Run: `flutter test test/unit/reward_controller_test.dart` — Expected: `+23: All tests passed!`
Run: `flutter test test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/audio/audio_catalogue_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart test/unit/referential_integrity_test.dart` — Expected: `All tests passed!` (chaque relique livrée, les deux neuves comprises, se réécrit à l'identique dans l'éditeur ; si `real_bundle_load_test` rougit sur un compte, supprimer `build/unit_test_assets` et relancer).
Run: `git grep -n '"id"' -- assets/data/relics/bounty_ledger.json assets/data/relics/gleaners_pouch.json` — Expected: deux lignes, `"id": "bounty_ledger"` et `"id": "gleaners_pouch"`.
Run: `git grep -n "extraCombatCardsAcc\|eliteCardChanceAcc" -- lib/game/controllers/run_controller.dart` — Expected: aucune sortie — le relais n'en gagne aucun.

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1528: All tests passed!` (1522 + 6 : l'échange +2, la persistance +1, les bonus lus par la récompense +3).

- [ ] **Step 9: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add assets/data/relics/bounty_ledger.json assets/data/relics/gleaners_pouch.json lib/game/controllers/run_controller.dart lib/game/controllers/run/player_stats_manager.dart lib/game/controllers/reward_controller.dart test/unit/shipped_data.dart test/unit/relic_exchange_test.dart test/unit/run_state_persistence_test.dart test/unit/reward_controller_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/audio/audio_catalogue_test.dart
git commit -F- <<'EOF'
feat(reliques): le registre des primes et la sacoche du glaneur

Deux reliques rares posent une regle de run a l acquisition et la
rendent a l echange : la sacoche ajoute une carte garantie apres un
combat normal, le registre ajoute 25 points au jet de la seconde carte
d elite. La trouvaille les lit, chacune sur son seul type de noeud.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: La fiche des probabilités lit le tirage — `slotRarityChances`, la section « Draft standard » retirée

Levée du second arrêt n° 8, C4.1, C4.2, C4.7 (spec §3.8, §5.1, §5.4) : la section « Draft standard de récompenses » annonçait, « en fin de combat standard », cinq chances de rareté qu'aucune récompense ne tire, quand la carte trouvée est toujours commune — elle part, avec son titre et son sous-titre en ligne et ses deux lectures. La section « Récompense de niveau » affichait 0,5 / 4,5 / 15 / 20 (+ Chance × 0,5 / 1,5 / 3 / 4), qu'aucun tirage n'utilise : elle lit désormais `LevelUpRewardService.slotRarityChances`, la distribution de `rollRarity(luck, isLevelReward: false)`, dont les quatre poids vivent en un seul endroit, `_slotWeights`, que les deux lisent. `calculateDraftProbabilities` disparaît avec ses dernières lectures. **La distribution de `rollRarity` ne change pas** : ses trois tests d'échantillonnage restent verts sans retouche. Le sous-titre « (Trèfle / Miroir) » et la section « Butin de Reliques » ne changent pas (partie 2 ; §5.4). Le conteneur du test ne porte que la run : en partie 1, la fiche ne lit que `runProvider`.

Changements de jeu de la tâche, voulus (spec §11, une des trois corrections) : la fiche ne montre plus les raretés d'un « draft standard » de fin de combat, et les chances de rareté de la montée de niveau sont les vraies — 2 / 6 / 16 / 24 / 52 à Chance 0.

**Files:**
- Modify: `lib/game/services/level_up_reward_service.dart:49-62`, après `:87` (deux fonctions)
- Modify: `lib/ui/widgets/map/dialogs/probabilities_dialog.dart:1-6`, `:30-65`, `:102-106`, `:199-240`, `:249-278`
- Test: `test/unit/probabilities_test.dart` (groupe neuf en fin de fichier)
- Test: `test/widget/probabilities_dialog_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `RewardRarity` (`lib/models/reward_rarity.dart`).
- Produces:
  - `static Map<RewardRarity, double> LevelUpRewardService.slotRarityChances(int luck)` — cinq clés, de `common` à `legendary`, sans `mythic`, de somme 100 ; de la légendaire à la peu commune, chaque rareté prend son poids borné entre 0 et ce qui reste de 100, la commune le reste.
  - `static ({double legendary, double epic, double rare, double uncommon}) LevelUpRewardService._slotWeights(int luck)` (privée).
  - `ProbabilitiesDialog.calculateDraftProbabilities` n'existe plus.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/probabilities_test.dart`, replace the end of the file:

```dart
    test('calculateRelicProbabilities with luck = 10', () {
      final probs = calculateRelicProbabilities(10);
      expect(probs['legendary']!, closeTo(5.71, 0.01));
      expect(probs['epic']!, closeTo(14.29, 0.01));
      expect(probs['rare']!, closeTo(32.38, 0.01));
      expect(probs['uncommon']!, closeTo(47.62, 0.01));
      expect(probs['common'], 0.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });
  });
}
```

with:

```dart
    test('calculateRelicProbabilities with luck = 10', () {
      final probs = calculateRelicProbabilities(10);
      expect(probs['legendary']!, closeTo(5.71, 0.01));
      expect(probs['epic']!, closeTo(14.29, 0.01));
      expect(probs['rare']!, closeTo(32.38, 0.01));
      expect(probs['uncommon']!, closeTo(47.62, 0.01));
      expect(probs['common'], 0.0);

      final sum = probs.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });
  });

  // Les chances qu'affiche la fiche des probabilités, lues sur le tirage
  // lui-même — les poids que visent les deux premiers cas d'échantillonnage
  // ci-dessus (spec P-43 E3, §3.8, C4.7).
  group('LevelUpRewardService.slotRarityChances', () {
    double sumOf(Map<RewardRarity, double> chances) =>
        chances.values.reduce((a, b) => a + b);

    test('a Chance 0 : 2 / 6 / 16 / 24 / 52, de la legendaire a la commune',
        () {
      final chances = LevelUpRewardService.slotRarityChances(0);

      expect(chances, {
        RewardRarity.legendary: 2.0,
        RewardRarity.epic: 6.0,
        RewardRarity.rare: 16.0,
        RewardRarity.uncommon: 24.0,
        RewardRarity.common: 52.0,
      });
      expect(sumOf(chances), 100.0);
    });

    test('a Chance 5 : 4,5 / 13,5 / 31 / 44 / 7', () {
      final chances = LevelUpRewardService.slotRarityChances(5);

      expect(chances, {
        RewardRarity.legendary: 4.5,
        RewardRarity.epic: 13.5,
        RewardRarity.rare: 31.0,
        RewardRarity.uncommon: 44.0,
        RewardRarity.common: 7.0,
      });
      expect(sumOf(chances), 100.0);
    });

    test('a Chance 20, la cascade tronque : 12 / 36 / 52 / 0 / 0', () {
      final chances = LevelUpRewardService.slotRarityChances(20);

      expect(chances, {
        RewardRarity.legendary: 12.0,
        RewardRarity.epic: 36.0,
        RewardRarity.rare: 52.0,
        RewardRarity.uncommon: 0.0,
        RewardRarity.common: 0.0,
      });
      expect(chances.keys, isNot(contains(RewardRarity.mythic)));
      expect(sumOf(chances), 100.0);
    });
  });
}
```

Create `test/widget/probabilities_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/probabilities_dialog.dart';

/// La fiche des probabilités de la carte du monde (spec P-43 E3, §5.1, §8 ;
/// C4.1, C4.2, C4.7). En partie 1, elle ne lit que la run (`runProvider`) :
/// le conteneur ne porte rien d'autre.
///
/// Ouvre la fiche par `ProbabilitiesDialog.show`, sur un écran assez haut
/// pour que la zone défilante de la fiche soit à sa taille maximale.
Future<void> _openDialog(
  WidgetTester tester,
  ProviderContainer container,
  Locale locale,
) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', ''), Locale('fr', '')],
        locale: locale,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ProbabilitiesDialog.show(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('la section du draft standard a quitte la fiche, en francais',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _openDialog(tester, container, const Locale('fr', ''));

    // `_buildProbabilitySectionCard` écrit les titres en capitales.
    expect(find.text('DRAFT STANDARD DE RÉCOMPENSES'), findsNothing);
    expect(
      find.text(
        "Chances d'obtenir chaque rareté de carte/stat en fin de combat "
        'standard',
      ),
      findsNothing,
    );
    expect(find.text('RÉCOMPENSE DE NIVEAU'), findsOneWidget);
    expect(find.text('BUTIN DE RELIQUES'), findsOneWidget);
  });

  testWidgets('la section du draft standard a quitte la fiche, en anglais',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await _openDialog(tester, container, const Locale('en', ''));

    expect(find.text('STANDARD REWARD DRAFT'), findsNothing);
    expect(
      find.text(
        'Chances of getting each card/stat rarity at the end of standard '
        'combat',
      ),
      findsNothing,
    );
    expect(find.text('LEVEL REWARD'), findsOneWidget);
    expect(find.text('RELIC LOOT'), findsOneWidget);
  });

  testWidgets('la recompense de niveau affiche les chances du tirage',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final run = container.read(runProvider.notifier);
    run.updateState(
      run.currentState.copyWith(
        heroStats: run.currentState.heroStats.copyWith(luck: 5),
      ),
    );

    await _openDialog(tester, container, const Locale('fr', ''));

    // La commune à Chance 0, puis à Chance 5, selon `slotRarityChances` ;
    // aucune autre ligne de la fiche n'écrit ces deux textes, et l'ancienne
    // table afficherait « 60.0% » et « 15.0% ».
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('7.0%'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/probabilities_test.dart test/widget/probabilities_dialog_test.dart`
Expected: `probabilities_test.dart` FAIL à la compilation — `The method 'slotRarityChances' isn't defined for the type 'LevelUpRewardService'` ; `probabilities_dialog_test.dart` : 3 échecs — le titre « DRAFT STANDARD DE RÉCOMPENSES » et « STANDARD REWARD DRAFT » trouvés, « 52.0% » et « 7.0% » introuvables.

- [ ] **Step 3: Une seule table de poids, partagée par le tirage et la fiche**

In `lib/game/services/level_up_reward_service.dart`, replace:

```dart
    final rng = Random();
    double mythicChance = isLevelReward ? 0.5 : 0.0;
    double legendaryChance = 2.0;
    double epicChance = 6.0;
    double rareChance = 16.0;
    double uncommonChance = 24.0;

    if (isLevelReward) {
      mythicChance += luck * 0.15;
    }
    legendaryChance += luck * 0.5;
    epicChance += luck * 1.5;
    rareChance += luck * 3.0;
    uncommonChance += luck * 4.0;
```

with:

```dart
    final rng = Random();
    double mythicChance = isLevelReward ? 0.5 : 0.0;
    if (isLevelReward) {
      mythicChance += luck * 0.15;
    }
    final weights = _slotWeights(luck);
    final legendaryChance = weights.legendary;
    final epicChance = weights.epic;
    final rareChance = weights.rare;
    final uncommonChance = weights.uncommon;
```

Then replace:

```dart
    if (roll < uncommonChance) return RewardRarity.uncommon;

    return RewardRarity.common;
  }
```

with:

```dart
    if (roll < uncommonChance) return RewardRarity.uncommon;

    return RewardRarity.common;
  }

  /// Les poids, en pourcentage, des quatre raretés au-delà de la commune pour
  /// une Chance donnée : la seule table que lisent le tirage ([rollRarity]) et
  /// la fiche des probabilités ([slotRarityChances]) — sa copie dans la
  /// fiche est précisément ce qui avait divergé (spec P-43 E3, §3.8, C4.7).
  static ({double legendary, double epic, double rare, double uncommon})
      _slotWeights(int luck) => (
            legendary: 2.0 + luck * 0.5,
            epic: 6.0 + luck * 1.5,
            rare: 16.0 + luck * 3.0,
            uncommon: 24.0 + luck * 4.0,
          );

  /// Les chances, en pourcentage, de chaque rareté d'un des trois
  /// emplacements de la montée de niveau — la distribution de
  /// `rollRarity(luck, isLevelReward: false)` —, cinq clés de somme 100, sans
  /// `mythic`, qu'un emplacement ne tire jamais (spec P-43 E3, §3.8, C4.7).
  ///
  /// La troncature suit la cascade de [rollRarity] : de la légendaire à la
  /// peu commune, chaque rareté prend son poids borné entre 0 et ce qui reste
  /// de 100, la commune le reste. Les deux coïncident dès que les quatre
  /// poids sont positifs ou nuls — toute Chance ≥ −4, donc toute Chance d'une
  /// run ; en dessous, que seul le menu de debug atteint, la fiche affiche 0
  /// là où le tirage laisse un poids négatif mordre sur les raretés suivantes.
  /// Lue par la fiche des probabilités.
  static Map<RewardRarity, double> slotRarityChances(int luck) {
    final weights = _slotWeights(luck);
    var remaining = 100.0;
    double take(double weight) {
      final chance = weight.clamp(0.0, remaining);
      remaining -= chance;
      return chance;
    }

    final legendary = take(weights.legendary);
    final epic = take(weights.epic);
    final rare = take(weights.rare);
    final uncommon = take(weights.uncommon);
    return {
      RewardRarity.common: remaining,
      RewardRarity.uncommon: uncommon,
      RewardRarity.rare: rare,
      RewardRarity.epic: epic,
      RewardRarity.legendary: legendary,
    };
  }
```

- [ ] **Step 4: La fiche perd sa section et lit le tirage**

In `lib/ui/widgets/map/dialogs/probabilities_dialog.dart`, replace:

```dart
import '../../../../game/controllers/run_controller.dart';
```

with:

```dart
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/level_up_reward_service.dart';
import '../../../../models/reward_rarity.dart';
```

Then delete the whole of `calculateDraftProbabilities` (`:30-66`, the method and the blank line after it):

```dart
  static Map<String, double> calculateDraftProbabilities(
    int luck,
    bool isLevelReward,
  ) {
    double legendaryChance = isLevelReward ? 0.5 + luck * 0.5 : 1.0 + luck * 0.5;
    double epicChance = isLevelReward ? 4.5 + luck * 1.5 : 5.0 + luck * 1.5;
    double rareChance = isLevelReward ? 15.0 + luck * 3.0 : 14.0 + luck * 3.0;
    double uncommonChance = 20.0 + luck * 4.0;

    legendaryChance = legendaryChance.clamp(0.0, 100.0);
    epicChance = epicChance.clamp(0.0, 100.0);
    rareChance = rareChance.clamp(0.0, 100.0);
    uncommonChance = uncommonChance.clamp(0.0, 100.0);

    double pLeg = legendaryChance;
    double pEpic = epicChance;
    double pRare = rareChance;
    double pUncommon = uncommonChance;

    double sum = pLeg;
    pEpic = pEpic.clamp(0.0, 100.0 - sum);
    sum += pEpic;
    pRare = pRare.clamp(0.0, 100.0 - sum);
    sum += pRare;
    pUncommon = pUncommon.clamp(0.0, 100.0 - sum);
    sum += pUncommon;
    double pCommon = (100.0 - sum).clamp(0.0, 100.0);

    return {
      'legendary': pLeg,
      'epic': pEpic,
      'rare': pRare,
      'uncommon': pUncommon,
      'common': pCommon,
    };
  }

```

Then replace:

```dart
    final baseDraftStd = calculateDraftProbabilities(0, false);
    final curDraftStd = calculateDraftProbabilities(luck, false);

    final baseDraftLeg = calculateDraftProbabilities(0, true);
    final curDraftLeg = calculateDraftProbabilities(luck, true);
```

with:

```dart
    // Les chances d'un des trois emplacements de la montée de niveau, lues
    // sur le tirage lui-même : une seule table de poids, que `rollRarity`
    // partage (spec P-43 E3, §5.1, C4.7).
    final baseSlot = LevelUpRewardService.slotRarityChances(0);
    final curSlot = LevelUpRewardService.slotRarityChances(luck);
```

Then delete the first section card — the whole block from `_buildProbabilitySectionCard(` through its closing `),`, just before the « Récompense de niveau » card (`:199-240`) :

```dart
                    _buildProbabilitySectionCard(
                      title: locale == 'fr'
                          ? 'Draft standard de récompenses'
                          : 'Standard Reward Draft',
                      subtitle: locale == 'fr'
                          ? "Chances d'obtenir chaque rareté de carte/stat en fin de combat standard"
                          : "Chances of getting each card/stat rarity at the end of standard combat",
                      icon: Icons.style_outlined,
                      accentColor: Colors.cyanAccent,
                      rows: [
                        _buildProbabilityRow(
                          rarityName: l10n.rarityLegendary,
                          color: Colors.amber,
                          basePercent: baseDraftStd['legendary']!,
                          currentPercent: curDraftStd['legendary']!,
                        ),
                        _buildProbabilityRow(
                          rarityName: l10n.rarityEpic,
                          color: Colors.purpleAccent,
                          basePercent: baseDraftStd['epic']!,
                          currentPercent: curDraftStd['epic']!,
                        ),
                        _buildProbabilityRow(
                          rarityName: l10n.rarityRare,
                          color: Colors.blueAccent,
                          basePercent: baseDraftStd['rare']!,
                          currentPercent: curDraftStd['rare']!,
                        ),
                        _buildProbabilityRow(
                          rarityName: l10n.rarityUncommon,
                          color: Colors.greenAccent,
                          basePercent: baseDraftStd['uncommon']!,
                          currentPercent: curDraftStd['uncommon']!,
                        ),
                        _buildProbabilityRow(
                          rarityName: l10n.rarityCommon,
                          color: Colors.grey,
                          basePercent: baseDraftStd['common']!,
                          currentPercent: curDraftStd['common']!,
                        ),
                      ],
                    ),
```

Then, in the « Récompense de niveau » card that now opens the column, make these five replacements, each unique in the file:

| Replace | With |
|:---|:---|
| `basePercent: baseDraftLeg['legendary']!,` / `currentPercent: curDraftLeg['legendary']!,` | `basePercent: baseSlot[RewardRarity.legendary]!,` / `currentPercent: curSlot[RewardRarity.legendary]!,` |
| `basePercent: baseDraftLeg['epic']!,` / `currentPercent: curDraftLeg['epic']!,` | `basePercent: baseSlot[RewardRarity.epic]!,` / `currentPercent: curSlot[RewardRarity.epic]!,` |
| `basePercent: baseDraftLeg['rare']!,` / `currentPercent: curDraftLeg['rare']!,` | `basePercent: baseSlot[RewardRarity.rare]!,` / `currentPercent: curSlot[RewardRarity.rare]!,` |
| `basePercent: baseDraftLeg['uncommon']!,` / `currentPercent: curDraftLeg['uncommon']!,` | `basePercent: baseSlot[RewardRarity.uncommon]!,` / `currentPercent: curSlot[RewardRarity.uncommon]!,` |
| `basePercent: baseDraftLeg['common']!,` / `currentPercent: curDraftLeg['common']!,` | `basePercent: baseSlot[RewardRarity.common]!,` / `currentPercent: curSlot[RewardRarity.common]!,` |

(Chaque ligne du tableau est une paire de lignes consécutives du fichier. Le sous-titre « … (Trèfle / Miroir) » de cette section ne change pas en partie 1 ; la section « Butin de Reliques » non plus.)

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/probabilities_test.dart` — Expected: `+8: All tests passed!` (les trois cas d'échantillonnage de `rollRarity`, `:56-102`, inchangés et verts).
Run: `flutter test test/widget/probabilities_dialog_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/unit/level_up_reward_requirement_test.dart test/unit/level_up_reward_values_test.dart test/widget/draft_screen_test.dart` — Expected: `All tests passed!`
Run: `git grep -n calculateDraftProbabilities -- lib test` — Expected: aucune sortie.
Run: `git grep -n "isLevelReward" -- lib` — Expected: des lignes dans `lib/game/services/level_up_reward_service.dart` (le paramètre de `rollRarity`, ses lectures, ses deux passages dans `generateChoices`) et la documentation de `lib/models/reward_rarity.dart:10`, et dans aucun autre fichier — la fiche n'en lit plus.

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1534: All tests passed!` (1528 + 6 : les chances des emplacements +3, la fiche +3).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/services/level_up_reward_service.dart lib/ui/widgets/map/dialogs/probabilities_dialog.dart test/unit/probabilities_test.dart test/widget/probabilities_dialog_test.dart
git commit -F- <<'EOF'
fix(probabilites): la fiche lit les chances du tirage et perd le draft standard

La section du draft standard de fin de combat annoncait des raretes
qu aucune recompense ne tire : elle quitte la fiche. La section de la
recompense de niveau lit LevelUpRewardService.slotRarityChances, qui
partage avec rollRarity une seule table de poids. Le tirage ne change
pas.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: Vérification finale de la partie 1

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf, et cette tâche se rejoue en entier. `<base>` désigne le commit qui **ajoute** ce plan — un commit ultérieur sur le plan ne le déplace pas : `git log --diff-filter=A --format=%H -- docs/superpowers/plans/2026-10-03-p43-e3-trouvaille-et-progression-partie-1.md`.

**Files:** aucun.

**Interfaces:**
- Consumes: la partie 1 entière.
- Produces: la branche `feat/v0.5.5-p43-e3-trouvaille`, partie 1 implémentée — rien de poussé, aucune PR. Le plan de la partie 2 s'écrit sur ce code (orchestration §3.4).

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1534: All tests passed!` — 1480 + 54, dont `tutorial_isolation_test.dart` (ADR-081), `real_bundle_load_test.dart` (90 fichiers d'entité, 27 reliques, la courbe de D67), `entity_id_convention_test.dart` (90), `shipped_entities_round_trip_test.dart` (chaque relique livrée, les deux neuves comprises, se réécrit à l'identique) et les six tests de widget du tutoriel qui reconstruisent le registre à chaque `testWidgets` (le drapeau `cache: false` de `loadDocument`).

- [ ] **Step 2: Les commandes de contrôle de la partie 1 (spec §8)**

Run: `git grep -n -e "GameConstants.maxHandSize" -e playerCardsCount -e "pow(1.5" -e calculateDraftProbabilities -e xpToNextLevel -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e cardsCount -- lib`
Expected: aucune sortie (sur `lib` seul : l'assertion d'absence de `combat_debug_logger_test.dart` écrit le littéral).

Run: `git grep -n fusionRankSum -- lib/ui/screens/game_screen.dart`
Expected: une ligne — l'argument `deckFusionRanks:` de l'appel de la DDA.

Run: `git grep -n rewardCardFound -- lib/ui/screens/game_screen.dart`
Expected: au moins une ligne — la notification de la trouvaille.

Les trois commandes dites « vides à la fin de la vague » (spec §8) ne le sont pas ici, et c'est attendu : la première rend encore les lignes de `rolledBonusCard`, la deuxième celles de `_armorPerTranche`, de « XP & Or x2 » et de « 2x XP », que la partie 2 retire. Les deux commandes de l'écran de combat sur `sharpenedRunes` et celle de l'infobulle sur `tooltipBossXpDesc` concernent la partie 2.

- [ ] **Step 3: Rien de la partie 2 n'est entré (spec §10)**

Run: `git grep -n -e bossXpRuneSharpens -e extraBossRuneSharpens -e runeCapBonus -e capBonus -e raiseRuneLevel -e sharpenedRunes -e raisableCaps -e sharpenablePairs -e tradedRelic -e isChoiceSelectable -e describeMastery -e luckLevelRewardSubtitle -e tooltipBossXpDesc -e eventNoRelicToGive -- lib test assets`
Expected: aucune sortie.

Run: `git grep -n rolledBonusCard -- lib`
Expected: des lignes dans `lib/game/controllers/reward_controller.dart` et `lib/ui/screens/game_screen.dart`, et dans aucun autre fichier — la carte bonus du boss « XP » reste jusqu'en partie 2.

Run: `git grep -n -e grindstone -e relic_peddler -e wandering_grinder -e transcendence -- assets`
Expected: aucune sortie.

- [ ] **Step 4: La main, la courbe, la trouvaille — leurs lecteurs**

Run: `git grep -n "startingMaxHandSize" -- lib`
Expected: des lignes dans `lib/game/game_constants.dart` (la déclaration), `lib/game/controllers/run_controller.dart` (le défaut du constructeur, la relecture d'une clé absente) et `lib/tutorial/widgets/tutorial_play_card_widget.dart` (la phrase de rappel), et dans aucun autre.

Run: `git grep -n "\.maxHandSize" -- lib`
Expected: les six chemins — `lib/game/controllers/combat/turn_phase_manager.dart` (deux lignes), `lib/game/services/effects/strategies.dart`, `lib/game/systems/passives/passive_strategies.dart`, `lib/game/services/debug_actions.dart` —, plus `lib/ui/widgets/debug/tabs/debug_run_tab.dart` (le champ « Main max »), `lib/game/controllers/run_controller.dart` (`this.maxHandSize` du constructeur et de `copyWith`) et `lib/game/game_constants.dart` (la documentation de `startingMaxHandSize`, qui nomme `RunState.maxHandSize`), et dans aucun autre fichier.

Run: `git grep -n "xpCurveProvider" -- lib`
Expected: des lignes dans `lib/services/game_data_service.dart` (la déclaration et son message), `lib/models/data/game_data_registry.dart` (la documentation de `xpCurve`), `lib/game/controllers/run/player_stats_manager.dart`, `lib/ui/widgets/map/hero_mini_stats_panel.dart`, `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` et `lib/game/services/debug_actions.dart`, et dans aucun fichier de `lib/tutorial/`.

Run: `git grep -n "xpCurve!" -- lib`
Expected: deux lignes, `lib/tutorial/tutorial_engine.dart` (`xpThreshold`) et `lib/tutorial/tutorial_screen.dart` (`fillXpPlaceholders`).

Run: `git grep -n "CardDrops.roll(" -- lib`
Expected: une ligne — l'appel de `handleVictory` (`lib/game/controllers/reward_controller.dart`) ; la déclaration, `static int roll(` dans `lib/game/systems/card_drops.dart`, n'écrit pas le nom de la classe.

- [ ] **Step 5: La donnée, la simulation, ce qui n'est pas à nous**

Run: `git diff --name-only <base>..HEAD -- assets`
Expected: exactement trois fichiers — `assets/data/relics/bounty_ledger.json`, `assets/data/relics/gleaners_pouch.json`, `assets/data/xp_curve.json`.

Run: `git diff --stat <base>..HEAD -- tool site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni la simulation et sa référence, ni `site/`, ni la note de version, ni la version, ni un fichier généré de plateforme.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0 — aucun dossier neuf sous `assets/`.

- [ ] **Step 6: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline <base>..HEAD`
Expected: au moins les sept commits des Tasks 1 à 7, plus les commits de correction éventuels. Rien n'est poussé.

---

## Ce que le plan laisse à la partie 2

Repris de la spec, §10 « Partie 2 », pour mémoire — aucune tâche de ce plan ne les fait :

1. **L'affûtage sans or et le bonus de plafond, en tête** : `DeckNotifier.raiseRuneLevel` et `GoldManager.sharpenRune` qui l'appelle (§4.7) ; `binary` sur `enduring` et `cheap`, `RunState.runeCapBonus`, le `capBonus` de tous ses lecteurs (`boundLevel`, `consolidate`, `canSharpen`, `hasSharpenableRune`, `wellLevel`, `mergeCards`, les pré-forgées, le feu, le Puits), `raisableCaps`, `sharpenablePairs`, `nameAt` (§4.8, A16 à A18).
2. **Le boss « XP »** : la carte bonus, `rolledBonusCard` et sa notification (`game_screen.dart:129-135`) supprimées — dont le cas `reward_controller_test.dart:284-347`, le filtre de classe qu'il gardait étant gardé dès la partie 1 par le cas « la trouvaille ne tire que ce que la classe peut recevoir » —, l'affûtage aléatoire, `GameConstants.bossXpRuneSharpens`, `RunState.extraBossRuneSharpens`, `RewardState.sharpenedRunes`, la *Meule*, l'infobulle (`legendBossXp`, `tooltipBossXpDesc`), la prose du tutoriel (§4.6, §5.3) ; la clause du boss « XP » de `signature_cards_transition_test.dart`.
3. **Les deux événements** : le *Colporteur* et le *Rémouleur*, `trade_relic`, `heal_percent`, `lose_hp_percent`, `sharpen_rune`, `requiresHpBelowPercent`, `EventState.tradedRelic`, `RunController.loseRelic` (qui défait les règles de run de la partie 1 — un cas de `event_controller_test` cède la *Sacoche du glaneur*), `EventController.isChoiceSelectable`, les badges, la sélection d'affûtage sans or, le retour système qui résout le nœud (§4.9, A19 à A22).
4. **Les récompenses de niveau** : *Sagesse* mythique, *Transcendance*, `raiseRuneCap`, `raisableRune`, la modale, la documentation d'`inPool` ; la fiche des probabilités nomme ses mythiques par `luckLevelRewardSubtitle`, et `probabilities_dialog_test.dart` gagne le cas de la parenthèse — le conteneur du fichier surchargeant alors le chargeur pour tous ses cas, ceux de la partie 1 compris (C4.2).
5. **Les seuils** : `threshold` de *Bénédiction*, `floor` de *Flux de Mana*, `describeMastery` et ses trois lecteurs (§4.11, A23, A24).
6. **La simulation** : le réalignement (premier temps), puis les trois tâches du second temps — la relique B, l'événement de D29, la table d'XP lue dans `xp_curve.json` (§9) —, les dernières de la vague.
7. **Pour `memory-bank-sync` et la note de version** (spec §11), constaté en écrivant ce plan : la fiche `_rules/03-4` cite `GameConstants.maxHandSize`, devenu `startingMaxHandSize` ; `_patterns/02-1` le palier stocké, désormais dérivé ; `_patterns/17-00` le chargeur, qui gagne `loadDocument`.
