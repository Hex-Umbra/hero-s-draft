# P-43 E3, partie 2 — Les sources — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Les sources de la vague : le boss « XP » monte une rune au lieu de donner une carte, et la *Meule* en monte une de plus par exemplaire ; deux événements neufs, le *Colporteur* (la relique la plus faible contre de l'or, ou contre des soins sous la moitié des PV) et le *Rémouleur* (une rune choisie contre 10 % des PV max) ; *Sagesse* devient mythique et *Transcendance* relève pour la run le plafond d'un type de rune, que lit chaque écrivain de niveau ; *Bénédiction* et *Flux de Mana* lisent leurs seuils dans la donnée, et la Maîtrise dit son effet réel ; enfin la simulation lit les entrées du brainstorm dans leurs fichiers, puis retire la relique B, l'événement de D29, et joue la table d'XP du jeu.

**Architecture:** `DeckNotifier.raiseRuneLevel` devient l'unique écrivain d'un niveau de rune hors de la fusion et du Puits : le feu (qui paie, par `GoldManager.sharpenRune`), le boss « XP » et le *Rémouleur* l'appellent. Le boss « XP » tire ses paires (carte, rune) par `ForgeRuneRules.sharpenablePairs` dans `collectGoldAndXp` et les dit par `RewardState.sharpenedRunes`, que `GameScreen` relit après la collecte. Les événements gagnent quatre actions composables et une condition de PV ; `EventController.isChoiceSelectable` calcule les deux faits (`hasTradedRelic`, `hasSharpenableRune`) que `EventChoice.isSelectable` reçoit. `RunState.runeCapBonus`, écrit par *Transcendance* (`RunController.raiseRuneCap`), est passé en `capBonus` à chaque règle qui borne un niveau, par les contrôleurs puis par les écrans. `PassiveData.describeMastery` dit l'écart effectif de la Maîtrise, plancher compris. La simulation se réaligne d'abord sans changer sa sortie, puis change en trois commits, chacun fumé par `--quick`.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`, `Provider`, `FutureProvider`), `flutter_test`, `flutter gen-l10n` ; le script `tool/simulations/d26_economy_sim.dart` (Dart pur, `dart:` seulement).

**Spec:** `docs/superpowers/specs/2026-10-03-p43-e3-trouvaille-et-progression-design.md` — §10, « Partie 2 ». À lire **en entier** : la partie 2 renvoie à §1.2 (A1 à A28, C1 à C5, les trois levées du propriétaire — tous acquis, aucun ne se rouvre ici), §3.3 à §3.8, §4.6 à §4.13, §5.1 à §5.4, §6, §7, §8 (chaque ligne marquée partie 2, « Et les commentaires », « Les tests qui suivent sans changer » et les commandes de contrôle), §9 et §11. Le déroulé du programme fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (§3.5, §3.6, §7.3). La partie 1 est faite (`3d58c2f..9b0e2e5`) : `fusionRankSum`, `startingMaxHandSize`, `xp_curve.json` et `xpCurveProvider`, la trouvaille (`cardDrops`, `CardDrops.roll`, `foundCards`), les reliques A et C (`extraCombatCards`, `eliteCardChanceBonus`, `applyRunRuleModifier`), `slotRarityChances` existent ; aucune tâche ne les réécrit.

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>` ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.5-p43-e3-trouvaille`, la branche courante. Il **ne crée aucune branche**, ne bascule sur aucune autre, ne commite rien sur `main`. Pas de worktree, même si le skill d'exécution en propose un.
- **L'invariant de la partie** (spec §10), tenu tâche par tâche : pas de code sans lecteur — un paramètre arrive avec son premier lecteur (`levels` de `raiseRuneLevel` avec le *Rémouleur*, `capBonus` avec les lecteurs du bonus) ; un test qui garde un comportement vivant n'est réécrit que dans la tâche qui change ce comportement ; un commentaire rendu faux est réécrit dans la tâche qui le rend faux.
- **`sync_assets`.** Les fichiers neufs vont dans `assets/data/relics/`, `events/` et `level_up_rewards/`, déjà déclarés (`pubspec.yaml:47-51`) : **aucune tâche ne lance la régénération** ; la vérification finale lance `dart run tool/sync_assets.dart --check`, qui doit sortir en 0.
- **La base de tests : 1535**, le total de `flutter test` sur la branche à `30027a9`, la fin de la partie 1, relevé le 2026-10-04 par une exécution complète, toute verte. Chaque tâche donne le total attendu — 1535, plus les tests qu'elle ajoute, moins ceux qu'elle retire, comptés sur les blocs `test(` et `testWidgets(` que le plan écrit (un par bloc ; un `group` ne compte pas ; un cas réécrit compte pour zéro) :

  | Tâche | Ajoutés | Retirés | Total |
  |:---|---:|---:|---:|
  | 1 — `raiseRuneLevel` | 3 | 0 | 1538 |
  | 2 — le boss « XP » | 5 | 1 | 1542 |
  | 3 — la *Meule*, le plafond des notifications | 6 | 0 | 1548 |
  | 4 — le *Colporteur* | 15 | 0 | 1563 |
  | 5 — le *Rémouleur* | 12 | 0 | 1575 |
  | 6 — *Sagesse* mythique, la fiche des probabilités | 2 | 0 | 1577 |
  | 7 — *Transcendance* | 13 | 0 | 1590 |
  | 8 — le bonus de plafond, règles et contrôleurs | 10 | 0 | 1600 |
  | 9 — le bonus de plafond, la fusion et les écrans ; `nameAt` | 7 | 0 | 1607 |
  | 10 — les seuils, `describeMastery` | 15 | 0 | 1622 |
  | 11 à 14 — la simulation | 0 | 0 | 1622 |

  Task 2 : `reward_controller_test.dart` perd le cas de la carte bonus (`:320-383`) ; les autres ajouts sont des cas neufs.
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-04 sur `30027a9`. La spec les mesurait sur `9282513`, avant la partie 1, qui en a décalé une partie dans `lib/` et `test/` (voir « Ce que le plan précise ») ; `tool/` n'a pas changé depuis (`git diff --stat 9282513 30027a9 -- tool` vide), et les lignes du script citées par la spec tombent juste. Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le périmètre : la partie 2, et elle seule** (spec §10). Rien de la partie 1 ne se réécrit ; rien de P-42 ni de P-44 n'entre.
- **La simulation** (spec §9 ; orchestration §3.6, §7.3) : les Tasks 11 à 14 sont **les dernières** et les seules à toucher `tool/`. La Task 11 réaligne sans changer une valeur en dur — chaque fichier neuf prend la place exacte de son entrée en dur — et vient après la dernière tâche qui touche `assets/data/` (Task 10) ; aucune retouche de la donnée ne la suit. Les Tasks 12 à 14 portent chacune **un** changement voulu, un commit du script chacune. Chaque tâche se fume par `--quick` ; **aucune ne lance la mesure complète ni ne recommite `d26_reference_output.md`** : l'orchestrateur relance chaque commit à part, explique l'écart et recommite. `<tmp>` désigne un dossier temporaire **hors du dépôt** (le dossier de travail temporaire de la session) ; la fumée du réalignement y extrait la base de la vague par `git archive 9282513 tool/simulations assets/data`.
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). `RunState` gagne `extraBossRuneSharpens` et `runeCapBonus`, relus à leur défaut si absents ; `EventState.tradedRelic` n'est pas sauvegardé (l'écran d'événement ne se sauvegarde pas en cours).
- **Le tutoriel ne référence aucun provider** (ADR-081) : sa prose du boss « XP » change en texte, son draft passe `currentMastery` lu sur son propre état ; `test/tutorial/tutorial_isolation_test.dart` reste vert.
- **Les lints** (`flutter_lints` 6) que le code du plan respecte : `curly_braces_in_flow_control_structures`, `use_build_context_synchronously` (chaque `await` d'un écran est suivi de `if (!mounted) return;`), `sort_child_properties_last`, `no_leading_underscores_for_local_identifiers` ; et l'analyseur refuse un import devenu inutile — chaque tâche qui retire le dernier lecteur d'un import retire l'import.

## Review Focus

Les cinq cas que la spec implique sans qu'un test de son §8 les pose tous, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **Un boss « XP » sur un deck sans rune qui puisse monter** — un deck de début de run sans rune, ou dont chaque rune est à son plafond. Un tirage naïf lève sur `nextInt(0)` en pleine victoire, ou boucle à chercher une paire ; attendu : rien ne monte, `sharpenedRunes` vide, la notification « aucune rune » (A5), aucune exception. Test : Task 2, `reward_controller_test.dart`, « sans rune qui puisse monter, rien ne monte, et la liste vide le … ».
2. **Le *Colporteur* sur un inventaire vide** — l'événement tiré avant toute relique. Attendu : l'écran s'ouvre sans exception, les deux choix d'échange sont inactifs, chacun dit « Aucune relique à céder », le choix de partir reste offert. Tests : Task 4, `event_controller_test.dart`, « aucune relique visee sur un inventaire vide, ni sans action … » ; `event_screen_test.dart`, « sans relique, les deux echanges sont inactifs et le disent ».
3. **Le *Rémouleur* abandonné en route** — le joueur ouvre la sélection, puis revient sans choisir de carte ou de rune. Attendu : rien n'est résolu, aucun PV perdu, le nœud n'est pas terminé, l'événement reste ouvert. Test : Task 5, `event_screen_test.dart`, « annuler la selection ne resout rien, ne coute rien ».
4. **Une rune relevée par *Transcendance*, puis affûtée, fusionnée ou reçue** — un lecteur qui oublierait `capBonus` rendrait la mythique sans effet, ou rabattrait la rune à son plafond de base. Attendu : le feu, la fusion, le Puits, les pré-forgées, le boss « XP » et le *Rémouleur* lisent le plafond effectif. Tests : Task 8, « un plafond releve laisse affuter une rune plafonnee, au prix du feu », « la rune recue entre au plafond effectif … », « une pre-forgee est bornee par le plafond effectif de la run », « un plafond releve rend une rune plafonnee de nouveau tirable », « le bonus de plafond rend le Remouleur possible … » ; Task 9, « AFFUTER s active sur une rune plafonnee quand la run releve … », « trois rares a Econome 1 fusionnent en epique a Econome 2 … ».
5. ***Affinité* offerte à un *Flux de Mana* déjà à son plancher** — la carte annoncerait « -3 Compétence à réunir » sans que rien ne change. Attendu : le repli « … sans effet sur votre passif ». Test : Task 10, `draft_screen_test.dart`, « a Maitrise effective 1, les rouleaux disent le repli ».

## Ce que le plan précise ou corrige de la spec

Constaté en re-mesurant le code sur `30027a9` ; aucun point n'amende un arbitrage, aucun ne change une valeur mesurée.

1. **Le découpage en quinze tâches**, chacune avec son lecteur de production. `raiseRuneLevel` (1) naît sous sa forme la plus courte avec son seul appelant d'alors, le feu ; `levels` arrive avec le *Rémouleur* (5), `capBonus` avec les lecteurs du bonus (8) — la signature de §4.7 est atteinte en Task 8. Le boss « XP » (2) lit la Task 1 ; la *Meule* (3) change le nombre de tirages de la Task 2. Le *Colporteur* (4) vient après la *Meule* : `loseRelic` défait aussi sa règle de run. Le *Rémouleur* (5) suit le *Colporteur*, dont il étend `isSelectable`, `isChoiceSelectable` et l'écran ; `isSelectable` reçoit chaque fait avec l'action qui le lit (`hasTradedRelic` en 4, `hasSharpenableRune` en 5). *Sagesse* (6) précède *Transcendance* (7), qui ajoute une quatrième mythique aux mêmes attentes. *Transcendance* écrit le bonus avec ses deux lecteurs du draft (`raisableCaps`, la modale) ; les écrivains de niveau le lisent en 8 (règles, contrôleurs) et 9 (la fusion — `consolidate`, `mergeCards` —, avec son seul appelant, l'écran de deck ; les autres écrans). Les seuils (10) sont indépendants. La simulation (11 à 14) vient en dernier, la Task 11 après la dernière retouche de `assets/data/`.
2. **Trois états transitoires, internes à la branche, jamais livrés** : entre les Tasks 7 et 8, *Transcendance* relève un plafond que seuls `raisableCaps` et la modale lisent ; entre les Tasks 8 et 9, la fusion de l'écran de deck borne encore au plafond de base — `consolidate` et `mergeCards` reçoivent leur `capBonus` en Task 9, avec leur seul appelant de production —, et l'option du feu, la sélection d'affûtage (que `EventController.isChoiceSelectable` déclare pourtant possible au *Rémouleur*), le dialogue d'affûtage et le Puits jugent encore sans le bonus, que la Task 9 leur passe (vérification du plan, tour 2) ; entre les Tasks 2 et 3, le tirage du boss ne lit que la constante. Chaque tâche reste verte.
3. **Les formes que la spec laisse au plan.** `typedef SharpenablePair = ({CardInstance card, ForgeUpgradeData rune, int level})` (`forge_rune_rules.dart`), `typedef SharpenedRune = ({String cardUniqueId, String runeId, int level})` (`reward_controller.dart`, le niveau **atteint**), `typedef RaisableCap = ({ForgeUpgradeData rune, int cap})`. `sharpenedRunes` vaut `null` hors d'un boss « XP » et `const []` posé par `handleVictory` sur un boss « XP », rempli par `collectGoldAndXp` (C1.1). `GoldManager.sharpenRune` et `exchangeRune` prennent `capBonus` **requis** — leur seul appelant, `RunController`, le passe toujours, et l'analyseur désigne un oubli — ; partout ailleurs il est optionnel, à défaut neutre (A17). `RestCardSelectionScreen` et `SharpenRuneDialog` gagnent `bool isFree = false` : en mode gratuit, le bouton dit « Choisir », le dialogue n'écrit rien et rend la rune, la sélection rend la paire, et `EventController.selectChoice(…, sharpenTarget:)` résout le choix. `PassiveData.describeMastery` rend `null` quand rien ne change, ce qui donne aux trois lecteurs leur repli. `EventController.isChoiceSelectable(choice, runeCatalog)` reçoit le catalogue que l'écran lit déjà sur le chargeur.
4. **Le plafond des notifications** (exigence de l'orchestrateur, compte rendu de la vague §2.3, S6). Relevé sur le code de la partie 2, l'étape « or et XP » empile au plus **cinq** messages dans un cas réaliste : une élite à seconde carte avec passage de niveau (« RELIQUE OBTENUE », « VICTOIRE », deux « Carte trouvée », « LEVEL UP »), un combat normal sous deux *Sacoches*, un boss « XP » sous deux *Meules*. Le plafond passe de 4 à 5, `NotificationNotifier.maxVisible`, une constante qui porte ce relevé ; au-delà, la plus ancienne part — en pratique le message de remélange de la fin du combat, déjà lu. A10 garde une notification par carte trouvée. Test neuf : `test/unit/notification_notifier_test.dart` (Task 3).
5. **La rangée de plus de la fiche des probabilités** (exigence de l'orchestrateur, S7). Quand la Task 6 rouvre `probabilities_dialog_test.dart`, le cas de Chance 5 trouve aussi, une fois chacun, « 2.0% » (la légendaire à Chance 0) et « 4.5% » (à Chance 5), et vérifie que la seconde rangée est sous la première : l'ordre des rangées est gardé.
6. **La simulation.** Le chargeur reconnaît un fichier qui « joue » une entrée du brainstorm à son `effectType` (reliques), à ses types d'action (événements) ou à son effet (`raiseRuneCap`), et lève s'il n'est pas celui qui y est rangé, ou si un fichier rangé manque. `relicD31A`, `relicD31C` et `relicD42` deviennent des accesseurs sur `data`, construits par `placedRelic`, qui vérifie la rareté. Les offres de mythique perdent leur type nullable. En Task 13, la documentation de `pickThree` perd « D29 » ; en Task 14, l'en-tête du script nomme la courbe d'XP parmi les données relues, la colonne « Valeur calée » de la table de calibration devient « Valeur » (sa première ligne est une table lue — un écart de libellé de plus, dit d'avance), et la variante de levier « **table par acte, 2 niv./acte** (réf.) » garde son libellé — la spec ne la nomme pas, et la table de D67 est celle que la référence calait sur deux niveaux par acte en `37aa9d5` (spec §1.3).
7. **Les lignes que la partie 1 a décalées**, re-mesurées (la spec reste juste sur le fond, ses numéros dérivent) : `reward_controller_test.dart`, les quatre lectures de `rolledBonusCard`, `:146`, `:341`, `:359`, `:373` dans la spec → `:175`, `:377`, `:395`, `:409` (`git grep -n rolledBonusCard -- test`) ; `nodeQuotas`, `game_constants.dart:25-31` → `:29-35` ; le terme de deck de la DDA, `encounter_system.dart:101` → `:103` ; `applyRelicEffect` et `removeRelicEffect`, `player_stats_manager.dart:239` et `:438` → `:245` et `:452`, `exchangeRelics` en `:480` ; `_armorPerTranche`, `passive_strategies.dart:146` → `:147` ; `mergeCards`, `deck_controller.dart:300` ; `generateChoices`, `level_up_reward_service.dart:131` ; le sous-titre de la fiche, `probabilities_dialog.dart:167-168`.

**Prémisses de la spec re-mesurées** : chaque `fichier:ligne` que la partie 2 utilise a été relu sur `30027a9` ; les numéros décalés par la partie 1 sont au point 7, les lignes du script tombent juste, les comptes (27 reliques, 5 événements, 8 récompenses, 90 fichiers d'entité, 54 fichiers de contenu audio à la fin de la partie 1 ; sept lignes « actuelle » dans `d26_reference_output.md`) se vérifient. **Aucune prémisse fausse.**

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/game/controllers/deck_controller.dart` | `raiseRuneLevel` (1), `levels` (5), `capBonus` sur `raiseRuneLevel` (8), sur `mergeCards` (9) | 1, 5, 8, 9 |
| `lib/game/controllers/run/gold_manager.dart` | `sharpenRune` appelle `raiseRuneLevel` (1) ; `capBonus` requis (8) | 1, 8 |
| `lib/game/game_constants.dart` | `bossXpRuneSharpens` (2), sa documentation (3) | 2, 3 |
| `lib/game/services/forge_rune_rules.dart` | `SharpenablePair`, `sharpenablePairs` (2) ; la doc de `hasSharpenableRune` (5) ; `RaisableCap`, `raisableCaps` (7) ; `capBonus` (8), sur `consolidate` et `_bounded` (9) | 2, 5, 7, 8, 9 |
| `lib/game/controllers/reward_controller.dart` | `rolledBonusCard` retiré, `SharpenedRune`, `sharpenedRunes` (2) ; la *Meule* (3) ; le bonus (8) | 2, 3, 8 |
| `lib/ui/screens/game_screen.dart` | La notification des runes montées | 2 |
| `lib/ui/widgets/map/map_node_widget.dart` | L'infobulle du boss « XP » | 2 |
| `lib/tutorial/tutorial_data.dart`, `lib/tutorial/widgets/tutorial_node_types_widget.dart` | La prose du boss « XP » | 2 |
| `lib/models/data/card_data.dart` | La doc d'`isOfferableTo` | 2 |
| `assets/data/relics/grindstone.json` *(nouveau)* | La *Meule* | 3 |
| `lib/game/controllers/run_controller.dart` | `extraBossRuneSharpens` (3) ; `loseRelic` (4) ; `runeCapBonus`, `raiseRuneCap` (7) ; les relais du feu et du Puits (8) | 3, 4, 7, 8 |
| `lib/game/controllers/run/player_stats_manager.dart` | La règle de run de la *Meule* (3) ; un commentaire (7) | 3, 7 |
| `lib/ui/widgets/notification_overlay.dart` | `maxVisible`, 5 | 3 |
| `assets/data/events/relic_peddler.json` *(nouveau)* | Le *Colporteur* | 4 |
| `assets/data/events/wandering_grinder.json` *(nouveau)* | Le *Rémouleur* | 5 |
| `lib/models/data/event_data.dart` | `requiresHpBelowPercent`, `isSelectable` et ses faits, les quatre actions, leurs bornes | 4, 5 |
| `lib/models/event_state.dart` | `tradedRelic` | 4 |
| `lib/game/controllers/event_controller.dart` | `isChoiceSelectable`, la relique visée, les quatre actions (4, 5) ; le bonus (8) | 4, 5, 8 |
| `lib/ui/screens/event_screen.dart` | Les badges, le retour système (4) ; la sélection sans or (5) | 4, 5 |
| `lib/ui/screens/rest_card_selection_screen.dart`, `lib/ui/widgets/forge/sharpen_rune_dialog.dart` | Le mode `isFree` (5) ; le bonus (9) | 5, 9 |
| `assets/data/level_up_rewards/wisdom.json` | *Sagesse* mythique | 6 |
| `lib/models/data/level_up_reward_data.dart` | La doc d'`inPool` (6) ; `raiseRuneCap`, `raisableRune` (7) ; `describe` et `currentMastery` (10) | 6, 7, 10 |
| `lib/ui/widgets/map/dialogs/probabilities_dialog.dart` | La parenthèse lue sur la donnée | 6 |
| `assets/data/level_up_rewards/transcendence.json` *(nouveau)* | *Transcendance* | 7 |
| `assets/data/forge_upgrades/enduring.json`, `assets/data/forge_upgrades/cheap.json` | `"binary": true` | 7 |
| `lib/models/data/forge_upgrade_data.dart` | `binary` (7) ; `boundLevel` (8) ; `nameAt` (9) | 7, 8, 9 |
| `lib/services/content_editor/entity_descriptor.dart` | Le gabarit de rune | 7 |
| `lib/game/services/level_up_reward_service.dart` | `hasRaisableRune`, `isRuneCapOption` | 7 |
| `lib/ui/screens/draft_screen.dart` | La modale de *Transcendance* (7) ; `currentMastery` (10) | 7, 10 |
| `lib/game/controllers/shop_controller.dart` | Les pré-forgées lisent le bonus | 8 |
| `lib/ui/screens/deck_screen.dart`, `lib/ui/screens/rest_screen.dart`, `lib/ui/screens/forge_fusion_screen.dart` | Les écrans lisent le bonus | 9 |
| `assets/data/passives/blessing.json`, `assets/data/passives/mana_flux.json` | `threshold` 5, `floor` 2 | 10 |
| `lib/models/data/passive_data.dart` | `floor`, `describeMastery` | 10 |
| `lib/game/systems/passives/passive_strategies.dart` | *Bénédiction* lit sa tranche ; le plancher codé de *Flux* retiré | 10 |
| `lib/ui/widgets/draft/draft_choice_labels.dart`, `lib/tutorial/widgets/tutorial_draft_widget.dart`, `lib/ui/widgets/map/dialogs/stats_dialog.dart`, `lib/ui/widgets/class_passive_list.dart` | Les lecteurs de `describeMastery` et de `currentMastery` | 10 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_localizations*.dart` | `tooltipBossXpDesc` (2) ; `eventTradeRelic`, `eventGiveRelic`, `eventNoRelicToGive` (4) ; `eventSharpenRune` (5) ; `luckLevelRewardSubtitle` (6) ; `runeCapTitle`, `runeCapLine`, `runeCapRaised` (7) | 2, 4, 5, 6, 7 |
| `tool/simulations/d26_economy_sim.dart` | Le réalignement (11) ; la relique B (12) ; l'événement de D29 (13) ; la table d'XP lue, les libellés « d'avant E3 » (14) | 11, 12, 13, 14 |
| `test/unit/deck_controller_test.dart` | `raiseRuneLevel` | 1, 5, 8 |
| `test/unit/reward_controller_test.dart` | Le boss « XP » (2), la *Meule* (3), le bonus (8) | 2, 3, 8 |
| `test/unit/forge_rune_rules_test.dart` | `sharpenablePairs` (2), `raisableCaps` (7), le bonus (8, 9) | 2, 7, 8, 9 |
| `test/unit/signature_cards_transition_test.dart` | La clause du boss « XP » | 2 |
| `test/unit/relic_exchange_test.dart`, `test/unit/notification_notifier_test.dart` *(nouveau)*, `test/unit/audio/audio_catalogue_test.dart` | La *Meule*, le plafond des notifications | 3 |
| `test/unit/run_state_persistence_test.dart` | Les clés neuves de `RunState` | 3, 7 |
| `test/unit/real_bundle_load_test.dart`, `test/unit/entity_id_convention_test.dart` | La donnée livrée | 3, 4, 5, 7 |
| `test/unit/event_controller_test.dart`, `test/widget/event_screen_test.dart` *(nouveau)* | Les deux événements (4, 5) ; le bonus (8) | 4, 5, 8 |
| `test/widget/rest_card_selection_screen_test.dart`, `test/widget/sharpen_rune_dialog_test.dart` | Le mode `isFree` (5) ; le bonus (9) | 5, 9 |
| `test/widget/probabilities_dialog_test.dart` | Le conteneur surchargé, la parenthèse, la rangée de plus | 6, 7 |
| `test/unit/level_up_rewards_catalog_test.dart`, `test/unit/level_up_reward_values_test.dart`, `test/unit/level_up_reward_apply_test.dart`, `test/unit/level_up_reward_requirement_test.dart`, `test/tutorial/tutorial_prose_test.dart` | Le catalogue des récompenses | 6, 7, 10 |
| `test/widget/draft_screen_test.dart` | Les mythiques et la vue large `_largeView` des deux cas qui les révèlent, « DraftScreen reveals mythic bonus choices… » et « Le Miroir de montee de niveau… » (6) ; *Transcendance* (7) ; la Maîtrise (10) | 6, 7, 10 |
| `test/unit/forge_upgrade_data_test.dart`, `test/unit/forge_upgrades_catalog_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/run_controller_test.dart`, `test/unit/level_up_reward_data_test.dart` | `binary`, `runeCapBonus`, le bonus, `describe` | 7, 8, 9, 10 |
| `test/unit/shop_controller_test.dart` | Les pré-forgées | 8 |
| `test/widget/deck_screen_test.dart`, `test/widget/rest_screen_test.dart`, `test/widget/forge_fusion_screen_test.dart` | Les écrans lisent le bonus | 9 |
| `test/unit/passive_data_test.dart`, `test/unit/passives_mage_test.dart`, `test/unit/passives_paladin_test.dart`, `test/unit/draft_choice_labels_test.dart`, `test/widget/stats_dialog_test.dart` *(nouveau)* | Les seuils, `describeMastery` | 10 |

---

### Task 1: L'affûtage sans or — `DeckNotifier.raiseRuneLevel`, que `GoldManager.sharpenRune` appelle

A13 (spec §4.7) : trois sources neuves montent une rune sans or — le boss « XP » (Task 2), la *Meule* (Task 3), le *Rémouleur* (Task 5) — à côté du feu, qui paie. L'écriture `id:n → id:n+1` vit désormais à un seul endroit, `DeckNotifier.raiseRuneLevel` ; `GoldManager.sharpenRune` garde son contrat (« payer et écrire, ou rien » : il refuse avant de dépenser si l'écriture serait refusée), paie, puis l'appelle. Cette tâche pose la méthode sous sa forme la plus courte, avec son seul appelant d'aujourd'hui : le paramètre `levels` arrive avec le *Rémouleur* (Task 5), qui en est le seul lecteur, et `capBonus` avec les lecteurs du bonus de plafond (Task 8) — la signature de la spec (§4.7) est atteinte à la Task 8.

**Files:**
- Modify: `lib/game/controllers/deck_controller.dart:352-362` (après `setForgeUpgrades`)
- Modify: `lib/game/controllers/run/gold_manager.dart:16-51` (`sharpenRune`)
- Test: `test/unit/deck_controller_test.dart` (un groupe neuf, en fin de fichier)

**Interfaces:**
- Consumes: `ForgeUpgradeData.getById`, `ForgeUpgradeData.levelsOf`, `ForgeUpgradeData.boundLevel(int requested, {int carried = 0})`, `ForgeRuneRules.replaceRune(List<String>, String, String)`, `DeckNotifier.setForgeUpgrades(String, List<String>)`.
- Produces: `bool DeckNotifier.raiseRuneLevel(String cardId, String runeId)` — vrai si la rune a monté d'un niveau ; faux, sans rien toucher, si la carte n'est pas dans le deck, ne porte pas la rune, si la rune est absente du registre ou à son plafond. Lu par `GoldManager.sharpenRune` (ici), `RewardController` (Task 2), `EventController` (Task 5).

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/deck_controller_test.dart`, replace:

```dart
    test('un pouvoir est epuise meme s il porte Persistant', () {
      final card = cardWith(type: CardType.power, isExhaust: false, runes: const ['enduring:1']);
      play(card);
      expect(notifier.state.exhaustPile, [card]);
    });
  });
}
```

with:

```dart
    test('un pouvoir est epuise meme s il porte Persistant', () {
      final card = cardWith(type: CardType.power, isExhaust: false, runes: const ['enduring:1']);
      play(card);
      expect(notifier.state.exhaustPile, [card]);
    });
  });

  // L'affûtage sans or, l'écriture que partagent le feu et les sources d'E3
  // (spec P-43 E3, §4.7, A13).
  group('DeckNotifier.raiseRuneLevel', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      shippedRuneRegistry(const ['burning', 'eco', 'sharp']);
      container = ProviderContainer();
      notifier = container.read(deckProvider.notifier);
    });

    tearDown(() => container.dispose());

    /// Une Frappe rare portant [runes], posée dans le deck.
    CardInstance seed(List<String> runes) {
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: runes,
      );
      notifier.addCardToMasterDeck(card);
      return card;
    }

    List<String> runesOf(CardInstance card) => notifier.state.masterDeck
        .singleWhere((c) => c.uniqueId == card.uniqueId)
        .forgeUpgrades;

    test('reecrit id:n en id:n+1 a sa place', () {
      final card = seed(const ['burning:1', 'sharp:2', 'eco:1']);

      expect(notifier.raiseRuneLevel(card.uniqueId, 'sharp'), isTrue);

      expect(runesOf(card), ['burning:1', 'sharp:3', 'eco:1']);
    });

    test('refuse une rune a son plafond, sans rien toucher', () {
      final card = seed(const ['sharp:2', 'eco:1']);

      expect(notifier.raiseRuneLevel(card.uniqueId, 'eco'), isFalse);

      expect(runesOf(card), ['sharp:2', 'eco:1']);
    });

    test('refuse une carte absente, une rune non portee ou absente du '
        'registre, sans rien toucher', () {
      final card = seed(const ['sharp:2', 'legacy:1']);

      expect(notifier.raiseRuneLevel('absente', 'sharp'), isFalse);
      expect(notifier.raiseRuneLevel(card.uniqueId, 'burning'), isFalse);
      expect(notifier.raiseRuneLevel(card.uniqueId, 'legacy'), isFalse);

      expect(runesOf(card), ['sharp:2', 'legacy:1']);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/deck_controller_test.dart --plain-name "DeckNotifier.raiseRuneLevel"`
Expected: FAIL à la compilation — `The method 'raiseRuneLevel' isn't defined for the type 'DeckNotifier'`.

- [ ] **Step 3: La méthode**

In `lib/game/controllers/deck_controller.dart`, replace:

```dart
  /// Met à jour les runes d'une carte après fusion
  void setForgeUpgrades(String uniqueId, List<String> upgrades) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          return c.copyWith(forgeUpgrades: upgrades);
        }
        return c;
      }).toList(),
    );
  }
```

with:

```dart
  /// Met à jour les runes d'une carte après fusion
  void setForgeUpgrades(String uniqueId, List<String> upgrades) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          return c.copyWith(forgeUpgrades: upgrades);
        }
        return c;
      }).toList(),
    );
  }

  /// Monte d'un niveau la rune [runeId] de la carte [cardId] du master deck,
  /// sans or (spec P-43 E3, §4.7, A13) : l'écriture que partagent le feu —
  /// `GoldManager.sharpenRune`, qui paie d'abord — et les sources d'E3. Le
  /// niveau est borné par le plafond de la rune (D72). Refuse — sans rien
  /// toucher — si la carte n'est pas dans le deck, ne porte pas la rune, si
  /// la rune est absente du registre, ou si son plafond ne la laisse pas
  /// monter ; sinon réécrit `id:n` en `id:n+1` à sa place. Rend vrai si la
  /// rune a monté.
  bool raiseRuneLevel(String cardId, String runeId) {
    final card =
        state.masterDeck.where((c) => c.uniqueId == cardId).firstOrNull;
    final level = card == null
        ? null
        : ForgeUpgradeData.levelsOf(card.forgeUpgrades)[runeId];
    final rune = ForgeUpgradeData.getById(runeId);
    if (card == null || level == null || rune == null) return false;
    final raised = rune.boundLevel(1, carried: level);
    if (raised == 0) return false;
    setForgeUpgrades(
      cardId,
      ForgeRuneRules.replaceRune(
        card.forgeUpgrades,
        runeId,
        '$runeId:${level + raised}',
      ),
    );
    return true;
  }
```

- [ ] **Step 4: Le feu l'appelle après avoir payé**

In `lib/game/controllers/run/gold_manager.dart`, replace:

```dart
  /// Affûte la rune [runeId] de la carte [cardId] du deck : un niveau de plus
  /// (D4), contre `ForgeRuneRules.sharpenCost(niveau)` or (D20). Refuse —
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond, ou si l'or manque. Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(String cardId, String runeId) {
```

with:

```dart
  /// Affûte la rune [runeId] de la carte [cardId] du deck : un niveau de plus
  /// (D4), contre `ForgeRuneRules.sharpenCost(niveau)` or (D20). Refuse —
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond, ou si l'or manque : l'écriture
  /// refusée ne coûte rien. L'écriture est celle des sources sans or,
  /// `DeckNotifier.raiseRuneLevel` (spec P-43 E3, §4.7, A13). Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(String cardId, String runeId) {
```

Then replace:

```dart
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.sharpenCost(level))) {
      return false;
    }
    ref.read(deckProvider.notifier).setForgeUpgrades(
          cardId,
          ForgeRuneRules.replaceRune(
            card.forgeUpgrades,
            runeId,
            '$runeId:${level + 1}',
          ),
        );
    return true;
  }
```

with:

```dart
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.sharpenCost(level))) {
      return false;
    }
    // `canSharpen` vient de dire ce que `raiseRuneLevel` vérifie : payée,
    // l'écriture a lieu.
    return ref.read(deckProvider.notifier).raiseRuneLevel(cardId, runeId);
  }
```

Le texte remplacé ne contient qu'un seul `spendGold(ForgeRuneRules.sharpenCost(level))` : celui de `exchangeRune` lit `wellCost`.

- [ ] **Step 5: Les tests passent, le feu aussi**

Run: `flutter test test/unit/deck_controller_test.dart test/unit/run_controller_test.dart test/widget/rest_screen_test.dart test/widget/sharpen_rune_dialog_test.dart`
Expected: PASS — les trois cas neufs, et les cinq cas de `RunController.sharpenRune` (`run_controller_test.dart:274-349`), inchangés, qui gardent le contrat du feu : `id:n+1` à sa place contre `50 × n`, aucun or dépensé au plafond, faute d'or, sur une rune non portée ou absente du registre.

- [ ] **Step 6: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1538: All tests passed!` (1535 + 3)

- [ ] **Step 7: Commit**

```bash
git add lib/game/controllers/deck_controller.dart lib/game/controllers/run/gold_manager.dart test/unit/deck_controller_test.dart
git commit -F - <<'EOF'
feat(forge): l affutage ecrit par DeckNotifier.raiseRuneLevel

La reecriture id:n en id:n+1 vit a un seul endroit, que partageront le
boss XP, la Meule et le Remouleur. Le feu verifie, paie, puis l appelle :
une ecriture refusee ne coute rien.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 2: Le boss « XP » monte une rune au lieu de donner une carte

D42(a), A5, A14, A25 (spec §4.6, §5.1, §5.3) : la carte bonus du boss « XP » disparaît — `RewardState.rolledBonusCard`, son tirage, son ajout au deck, sa notification — ; à sa place, à la collecte, `GameConstants.bossXpRuneSharpens` tirages, chacun une paire (carte, rune) au hasard parmi celles du deck dont la rune peut encore monter (`ForgeRuneRules.sharpenablePairs`), montée d'un niveau par `DeckNotifier.raiseRuneLevel` (Task 1). `RewardState.sharpenedRunes` dit ce qui a monté : `null` hors d'un boss « XP », vide pour un boss « XP » sans paire (C1.1) — `restCampSharpenNone` (A5). L'écran relit l'état **après** `collectGoldAndXp` (sa copie est prise avant). L'infobulle du nœud dit enfin le triple et la rune ; la prose du tutoriel aussi. La transition E3 → E4 gagne sa clause du boss.

La *Meule* (une rune de plus par exemplaire) est la Task 3, avec le plafond des notifications de l'étape « or et XP » ; le bonus de plafond de *Transcendance*, lu par le tirage, est la Task 8.

**Files:**
- Modify: `lib/game/game_constants.dart:40-43` (après `cardDrops`)
- Modify: `lib/game/services/forge_rune_rules.dart:1-11` (le `typedef`), `:147-157` (après `hasSharpenableRune`)
- Modify: `lib/game/controllers/reward_controller.dart:1-12` (imports), `:14-77` (`RewardState`), `:201-254` (`handleVictory`), `:256-276` (`collectGoldAndXp`)
- Modify: `lib/ui/screens/game_screen.dart:129-146`
- Modify: `lib/ui/widgets/map/map_node_widget.dart:59-61`
- Modify: `lib/l10n/app_en.arb:119`, `lib/l10n/app_fr.arb:69` ; régénérés : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/tutorial/tutorial_data.dart:86-88` (en), `:103-105` (fr) ; `lib/tutorial/widgets/tutorial_node_types_widget.dart:103-104`
- Modify: `lib/models/data/card_data.dart:160` (la documentation d'`isOfferableTo`, qui nomme encore le « bonus de boss »)
- Test: `test/unit/reward_controller_test.dart:175`, `:320-383` (supprimé), `:385-410` et `:435-451` (réécrits), un groupe neuf en fin de fichier
- Test: `test/unit/forge_rune_rules_test.dart:206-221` (un cas après `hasSharpenableRune`)
- Test: `test/unit/signature_cards_transition_test.dart:17-23` (documentation), un cas neuf en fin de fichier

**Interfaces:**
- Consumes: `bool DeckNotifier.raiseRuneLevel(String cardId, String runeId)` (Task 1) ; `ForgeRuneRules.canSharpen(ForgeUpgradeData, int)`.
- Produces:
  - `GameConstants.bossXpRuneSharpens` (`int`, 1) ;
  - `typedef SharpenablePair = ({CardInstance card, ForgeUpgradeData rune, int level});` et `static List<SharpenablePair> ForgeRuneRules.sharpenablePairs(Iterable<CardInstance> deck, Iterable<ForgeUpgradeData> catalog)` — `level`, le niveau porté ; la Task 8 y ajoute `{Map<String, int> capBonus = const {}}` ;
  - `typedef SharpenedRune = ({String cardUniqueId, String runeId, int level});` (dans `reward_controller.dart`) et `RewardState.sharpenedRunes` (`List<SharpenedRune>?`, le niveau **atteint**) ;
  - `RewardState.rolledBonusCard` n'existe plus.
  - La clé ARB `tooltipBossXpDesc`.

- [ ] **Step 1: Les tests de la récompense**

In `test/unit/reward_controller_test.dart`, replace (`:174-175` — la ligne `rolledBonusCard` seule apparaît aussi en `:409`, dans le cas que le troisième remplacement réécrit en entier ; la paire de lignes, elle, est unique) :

```dart
      expect(rewardController.state.rolledCards, isEmpty);
      expect(rewardController.state.rolledBonusCard, isNull);
```

with:

```dart
      expect(rewardController.state.rolledCards, isEmpty);
      // Hors d'un boss « XP », aucune rune ne monte (spec P-43 E3, §4.6).
      expect(rewardController.state.sharpenedRunes, isNull);
```

Then delete the case that opens with `    test('le bonus de boss d un mage ne tire jamais la signature d une autre classe', () {` (`:320-383`), up to and including its closing `    });`, and the blank line that follows it — le filtre de classe qu'il gardait est gardé depuis la partie 1 par « la trouvaille ne tire que ce que la classe peut recevoir, jamais une unique » (spec §8, « Le boss « XP » »).

Then replace:

```dart
    test('handleVictory rolls a bonus card excluding status/unique cards, only for a doubleXp boss node', () {
      for (var i = 0; i < 30; i++) {
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
          allRelics: allRelics,
          allCards: allCards,
          luck: 0,
          act: 1,
        );
        final bonus = rewardController.state.rolledBonusCard;
        expect(bonus, isNotNull);
        expect(bonus!.type, isNot(CardType.status));
        expect(bonus.rarity, isNot(CardRarity.unique));
      }

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.rolledBonusCard, isNull);
    });
```

with:

```dart
    test('le boss XP ne donne plus de carte : sa victoire attend la collecte '
        'pour monter une rune, et rien ne monte hors de lui', () {
      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.doubleXp),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.foundCards, isEmpty);
      expect(rewardController.state.rolledCards, isEmpty);
      // Vide, et non nulle : le discriminant d'un boss « XP » (C1.1).
      expect(rewardController.state.sharpenedRunes, isEmpty);

      rewardController.handleVictory(
        defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
        currentNode: makeNode(),
        allRelics: allRelics,
        allCards: allCards,
        luck: 0,
        act: 1,
      );
      expect(rewardController.state.sharpenedRunes, isNull);
    });
```

Then replace:

```dart
    test('collectGoldAndXp reports whether the player leveled up and adds the bonus card', () {
```

with:

```dart
    test('collectGoldAndXp reports whether the player leveled up, and the XP '
        'boss adds no card', () {
```

and, in that same case, replace:

```dart
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore + 1);
```

with:

```dart
      expect(container.read(deckProvider).masterDeck.length, deckSizeBefore);
```

Then add the group at the end of the file — replace:

```dart
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

with:

```dart
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

    // Le boss « XP » : plus de carte, une rune du deck monte d'un niveau, sans
    // or (spec P-43 E3, §4.6, §8 ; D42(a), A5, A14).
    group('le boss XP', () {
      setUp(() {
        shippedRuneRegistry(const ['eco', 'sharp']);
      });

      final xpBoss = makeNode(
        type: MapNodeType.boss,
        bossRewardType: BossRewardType.doubleXp,
      );

      /// Une Frappe rare portant [runes], posée dans le deck.
      CardInstance seedRare(List<String> runes) {
        final card = CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: runes,
        );
        deckNotifier.addCardToMasterDeck(card);
        return card;
      }

      List<String> runesOf(CardInstance card) => container
          .read(deckProvider)
          .masterDeck
          .singleWhere((c) => c.uniqueId == card.uniqueId)
          .forgeUpgrades;

      /// Une victoire sur [node], puis l'or et l'XP collectés.
      void winAndCollect(MapNode node) {
        rewardController.handleVictory(
          defeatedEnemies: [makeEnemy(xp: 10, gold: 10)],
          currentNode: node,
          allRelics: allRelics,
          allCards: allCards,
          luck: 0,
          act: 1,
        );
        rewardController.collectGoldAndXp();
      }

      test('une rune sous son plafond monte d un niveau, jamais une rune '
          'plafonnee', () {
        final capped = seedRare(const ['eco:1']);
        final sharp = seedRare(const ['sharp:1']);

        // Chaque tirage voit le précédent : Tranchant monte à chaque boss.
        for (var i = 0; i < 5; i++) {
          winAndCollect(xpBoss);
          expect(rewardController.state.sharpenedRunes, [
            (cardUniqueId: sharp.uniqueId, runeId: 'sharp', level: i + 2),
          ]);
        }

        expect(runesOf(sharp), ['sharp:6']);
        expect(runesOf(capped), ['eco:1']);
      });

      // A5 : fréquent en début de run, le deck n'a pas de rune affûtable.
      test('sans rune qui puisse monter, rien ne monte, et la liste vide le '
          'dit', () {
        final capped = seedRare(const ['eco:1']);

        winAndCollect(xpBoss);

        expect(rewardController.state.sharpenedRunes, isEmpty);
        expect(runesOf(capped), ['eco:1']);
      });

      test('hors du boss XP, aucune rune ne monte', () {
        final sharp = seedRare(const ['sharp:1']);

        for (final node in [
          makeNode(),
          makeNode(type: MapNodeType.elite),
          makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.cards),
          makeNode(
            type: MapNodeType.boss,
            bossRewardType: BossRewardType.improvedRelic,
          ),
        ]) {
          winAndCollect(node);
          expect(rewardController.state.sharpenedRunes, isNull,
              reason: '${node.type.name} ${node.bossRewardType?.name}');
        }
        expect(runesOf(sharp), ['sharp:1']);
      });
    });
  });
}
```

- [ ] **Step 2: Le test des paires**

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
      expect(
        ForgeRuneRules.hasSharpenableRune(
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });
  });
```

with:

```dart
      expect(
        ForgeRuneRules.hasSharpenableRune(
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });

    // Les paires que tire le boss « XP » (spec P-43 E3, §4.6, A14).
    test('sharpenablePairs : les paires sous leur plafond, dans l ordre du '
        'deck puis des runes de chaque carte', () {
      final catalog = [_rune('sharp'), _rune('eco', maxLevel: 1)];
      final first = _cardWith(['eco:1', 'sharp:2']);
      final bare = _cardWith([]);
      final last = _cardWith(['sharp:1', 'absente:1']);

      expect(
        [
          for (final pair in ForgeRuneRules.sharpenablePairs(
              [first, bare, last], catalog))
            (pair.card.uniqueId, pair.rune.id, pair.level),
        ],
        [(first.uniqueId, 'sharp', 2), (last.uniqueId, 'sharp', 1)],
      );
    });
  });
```

- [ ] **Step 3: La clause du boss « XP » de la transition E3 → E4**

In `test/unit/signature_cards_transition_test.dart`, replace:

```dart
/// La transition E3 → E4 (spec P-43 E3, §4.13, §8) : jusqu'à E4, les
/// signatures restent des cartes du deck — exclues de la trouvaille par
/// `unique`, sans rune offerte, au rang 0 pour la difficulté. Sur le
/// registre réel.
///
/// La clause du boss « XP » — il ne monte jamais une rune de signature —
/// vient en partie 2, avec le boss.
```

with:

```dart
/// La transition E3 → E4 (spec P-43 E3, §4.13, §8) : jusqu'à E4, les
/// signatures restent des cartes du deck — exclues de la trouvaille par
/// `unique`, sans rune offerte, au rang 0 pour la difficulté, et jamais
/// montées par le boss « XP », faute de rune. Sur le registre réel.
```

Then replace the end of the file:

```dart
      expect(deck.fusionRankSum, 0, reason: hero.id);
    }
  });
}
```

with:

```dart
      expect(deck.fusionRankSum, 0, reason: hero.id);
    }
  });

  test('le boss XP ne monte jamais une rune de signature : aucune n en '
      'porte', () {
    final xpBoss = MapNode(
      id: 'node_9_0',
      floor: 9,
      type: MapNodeType.boss,
      connections: const [],
      position: Vector2.zero(),
      bossRewardType: BossRewardType.doubleXp,
    );

    for (final hero in registry.heroes) {
      final container = ProviderContainer(
        overrides: [xpCurveProvider.overrideWithValue(registry.xpCurve!)],
      );
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(hero);
      final deck = container.read(deckProvider.notifier);
      final signatures = [
        for (final id in hero.skills)
          CardInstance(data: registry.cards.singleWhere((c) => c.id == id)),
      ];
      for (final card in signatures) {
        deck.addCardToMasterDeck(card);
      }
      // Une carte qui porte une rune : sans elle, le boss ne monterait rien
      // d'office, et la clause ne prouverait rien.
      deck.addCardToMasterDeck(CardInstance(
        data: registry.cards.singleWhere((c) => c.id == 'strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['sharp:1'],
      ));
      final rewards = container.read(rewardProvider.notifier);

      for (var i = 0; i < 20; i++) {
        rewards.handleVictory(
          defeatedEnemies: const [],
          currentNode: xpBoss,
          allRelics: registry.relics,
          allCards: registry.cards,
          luck: 0,
          act: 1,
        );
        rewards.collectGoldAndXp();
        final sharpened = rewards.state.sharpenedRunes!;
        expect(sharpened, hasLength(1), reason: hero.id);
        expect(
          signatures.map((c) => c.uniqueId),
          isNot(contains(sharpened.single.cardUniqueId)),
          reason: hero.id,
        );
      }
      for (final card in container.read(deckProvider).masterDeck) {
        if (signatureIds.contains(card.data.id)) {
          expect(card.forgeUpgrades, isEmpty,
              reason: '${hero.id} : ${card.data.id}');
        }
      }
    }
  });
}
```

- [ ] **Step 4: Les lancer pour les voir échouer**

Run: `flutter test test/unit/reward_controller_test.dart test/unit/forge_rune_rules_test.dart test/unit/signature_cards_transition_test.dart`
Expected: FAIL à la compilation — `The getter 'sharpenedRunes' isn't defined for the type 'RewardState'`, `The method 'sharpenablePairs' isn't defined for the type 'ForgeRuneRules'`.

- [ ] **Step 5: La constante**

In `lib/game/game_constants.dart`, replace:

```dart
    MapNodeType.elite: (guaranteed: 1, extraChances: [25]),
  };
```

with:

```dart
    MapNodeType.elite: (guaranteed: 1, extraChances: [25]),
  };

  // --- BOSS « XP » (D42) ---
  /// Les runes que la récompense du boss « XP » monte d'un niveau (D42(a)),
  /// tirées parmi les paires (carte, rune) du deck dont la rune peut encore
  /// monter.
  static const int bossXpRuneSharpens = 1;
```

- [ ] **Step 6: Les paires**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
import '../../models/effective_card.dart';

/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
```

with:

```dart
import '../../models/effective_card.dart';

/// Une rune d'une carte du deck, au niveau [level] que la carte porte.
typedef SharpenablePair = ({
  CardInstance card,
  ForgeUpgradeData rune,
  int level,
});

/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
```

Then replace:

```dart
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null && canSharpen(rune, entry.value);
      });
```

with:

```dart
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null && canSharpen(rune, entry.value);
      });

  /// Les paires (carte, rune) de [deck] dont la rune peut encore monter d'un
  /// niveau — celles que tire le boss « XP » (spec P-43 E3, §4.6, A14) —,
  /// dans l'ordre du deck puis des runes de chaque carte. Une rune absente du
  /// [catalog] ne se monte pas.
  static List<SharpenablePair> sharpenablePairs(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final pairs = <SharpenablePair>[];
    for (final card in deck) {
      for (final MapEntry(key: id, value: level)
          in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries) {
        final rune = catalog.where((r) => r.id == id).firstOrNull;
        if (rune != null && canSharpen(rune, level)) {
          pairs.add((card: card, rune: rune, level: level));
        }
      }
    }
    return pairs;
  }
```

- [ ] **Step 7: La récompense**

In `lib/game/controllers/reward_controller.dart`, replace:

```dart
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../../models/card_instance.dart';
import '../../models/map_node.dart';
import '../../models/enemy_instance.dart';
import '../game_constants.dart';
import '../systems/card_drops.dart';
```

with:

```dart
import '../../models/data/relic_data.dart';
import '../../models/data/card_data.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../models/card_instance.dart';
import '../../models/map_node.dart';
import '../../models/enemy_instance.dart';
import '../game_constants.dart';
import '../services/forge_rune_rules.dart';
import '../systems/card_drops.dart';
```

Then replace:

```dart
class RewardState {
  final int goldGained;
```

with:

```dart
/// Une rune montée par le boss « XP » : l'exemplaire qui la porte, son id, et
/// le niveau qu'elle atteint (spec P-43 E3, §3.8).
typedef SharpenedRune = ({String cardUniqueId, String runeId, int level});

class RewardState {
  final int goldGained;
```

Then replace:

```dart
  final bool isResolved;
  final CardData? rolledBonusCard;

  /// Les cartes trouvées à la victoire (spec P-43 E3, §4.1 ; D1) : tirées
  /// par `handleVictory`, toujours communes, elles rejoignent le deck à
  /// `collectGoldAndXp`, sans refus.
  final List<CardInstance> foundCards;
```

with:

```dart
  final bool isResolved;

  /// Les cartes trouvées à la victoire (spec P-43 E3, §4.1 ; D1) : tirées
  /// par `handleVictory`, toujours communes, elles rejoignent le deck à
  /// `collectGoldAndXp`, sans refus.
  final List<CardInstance> foundCards;

  /// Les runes que le boss « XP » a montées (spec P-43 E3, §4.6 ; D42(a),
  /// C1.1), une entrée par rune, au niveau atteint, écrites par
  /// `collectGoldAndXp`. `null` hors d'un boss « XP » ; vide pour un boss
  /// « XP » dont aucune rune ne pouvait monter (A5) — le discriminant que lit
  /// l'écran.
  final List<SharpenedRune>? sharpenedRunes;
```

Then replace:

```dart
    this.isResolved = false,
    this.rolledBonusCard,
    this.foundCards = const [],
  });
```

with:

```dart
    this.isResolved = false,
    this.foundCards = const [],
    this.sharpenedRunes,
  });
```

Then replace:

```dart
    bool? isResolved,
    CardData? rolledBonusCard,
    List<CardInstance>? foundCards,
  }) {
```

with:

```dart
    bool? isResolved,
    List<CardInstance>? foundCards,
    List<SharpenedRune>? sharpenedRunes,
  }) {
```

Then replace:

```dart
      rolledBonusCard: rolledBonusCard ?? this.rolledBonusCard,
      foundCards: foundCards ?? this.foundCards,
    );
```

with:

```dart
      foundCards: foundCards ?? this.foundCards,
      sharpenedRunes: sharpenedRunes ?? this.sharpenedRunes,
    );
```

Then, in `handleVictory`, replace:

```dart
    // 5. La trouvaille (spec P-43 E3, §4.1 ; D1, D31) : des cartes tirées
    // uniformément, avec remise, parmi celles que la classe peut recevoir —
    // le prédicat de la carte bonus (ADR-101) —, toujours communes, donc sans
    // rune. Pool vide : aucune carte, sans repli (ADR-101 D4).
```

with:

```dart
    // 5. La trouvaille (spec P-43 E3, §4.1 ; D1, D31) : des cartes tirées
    // uniformément, avec remise, parmi celles que la classe peut recevoir —
    // le prédicat d'offre unique (ADR-101) —, toujours communes, donc sans
    // rune. Pool vide : aucune carte, sans repli (ADR-101 D4).
```

Then replace:

```dart
    CardData? rolledBonusCard;
    if (currentNode.bossRewardType == BossRewardType.doubleXp) {
      final heroClassId = ref.read(runProvider).heroClassId;
      final validCards =
          allCards.where((c) => c.isOfferableTo(heroClassId)).toList();
      if (validCards.isNotEmpty) {
        rolledBonusCard = validCards[Random().nextInt(validCards.length)];
      }
    }

    state = RewardState(
```

with:

```dart
    state = RewardState(
```

Then replace:

```dart
      isResolved: false,
      rolledBonusCard: rolledBonusCard,
      foundCards: foundCards,
    );
  }
```

with:

```dart
      isResolved: false,
      foundCards: foundCards,
      // Le boss « XP » monte ses runes à la collecte : une liste vide ici le
      // désigne (C1.1).
      sharpenedRunes: currentNode.bossRewardType == BossRewardType.doubleXp
          ? const []
          : null,
    );
  }
```

Then replace:

```dart
    final leveledUp = ref.read(runProvider.notifier).gainXp(state.xpGained);

    if (state.rolledBonusCard != null) {
      ref.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(data: state.rolledBonusCard!));
    }

    // Les cartes trouvées rejoignent le deck, sans refus (spec P-43 E3, §4.1).
    final deck = ref.read(deckProvider.notifier);
    for (final card in state.foundCards) {
      deck.addCardToMasterDeck(card);
    }

    state = state.copyWith(isGoldXpCollected: true);
    _checkResolution();

    return leveledUp;
  }
```

with:

```dart
    final leveledUp = ref.read(runProvider.notifier).gainXp(state.xpGained);

    // Les cartes trouvées rejoignent le deck, sans refus (spec P-43 E3, §4.1).
    final deck = ref.read(deckProvider.notifier);
    for (final card in state.foundCards) {
      deck.addCardToMasterDeck(card);
    }

    state = state.copyWith(
      isGoldXpCollected: true,
      sharpenedRunes:
          state.sharpenedRunes == null ? null : _sharpenRandomRunes(),
    );
    _checkResolution();

    return leveledUp;
  }

  /// La récompense du boss « XP » (spec P-43 E3, §4.6 ; D42(a), A5, A14) :
  /// [GameConstants.bossXpRuneSharpens] tirages, chacun une paire (carte,
  /// rune) au hasard parmi celles du deck dont la rune peut encore monter,
  /// montée d'un niveau, sans or ; chaque tirage voit le précédent. Sans
  /// paire, rien ne monte.
  List<SharpenedRune> _sharpenRandomRunes() {
    final deck = ref.read(deckProvider.notifier);
    final catalog = GameDataRegistry.instance?.forgeUpgrades ??
        const <ForgeUpgradeData>[];
    final rng = Random();
    final sharpened = <SharpenedRune>[];
    for (var i = 0; i < GameConstants.bossXpRuneSharpens; i++) {
      final pairs = ForgeRuneRules.sharpenablePairs(
        ref.read(deckProvider).masterDeck,
        catalog,
      );
      if (pairs.isEmpty) break;
      final pair = pairs[rng.nextInt(pairs.length)];
      if (deck.raiseRuneLevel(pair.card.uniqueId, pair.rune.id)) {
        sharpened.add((
          cardUniqueId: pair.card.uniqueId,
          runeId: pair.rune.id,
          level: pair.level + 1,
        ));
      }
    }
    return sharpened;
  }
```

`CardData` reste importé : `handleVictory` reçoit `List<CardData> allCards`.

- [ ] **Step 8: L'écran de combat dit les runes montées**

In `lib/ui/screens/game_screen.dart`, replace:

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

with:

```dart
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

      // Les runes du boss « XP » (spec P-43 E3, §4.6, A5) : montées par
      // `collectGoldAndXp`, après la copie prise plus haut — l'écran relit
      // l'état. `null` hors d'un boss « XP » ; vide, aucune rune ne pouvait
      // monter.
      final sharpened = ref.read(rewardProvider).sharpenedRunes;
      if (sharpened != null) {
        if (sharpened.isEmpty) {
          context.showNotification(l10n.restCampSharpenNone);
        }
        final deck = ref.read(deckProvider).masterDeck;
        final runes =
            ref.read(gameDataLoaderProvider).requireValue.forgeUpgrades;
        for (final rune in sharpened) {
          final card =
              deck.where((c) => c.uniqueId == rune.cardUniqueId).firstOrNull;
          context.showNotification(
            l10n.restCampSnackbarSharpen(
              runes
                      .where((r) => r.id == rune.runeId)
                      .firstOrNull
                      ?.getName(locale) ??
                  rune.runeId,
              rune.level,
              card?.data.getName(locale) ?? '',
            ),
            type: NotificationType.success,
          );
        }
      }
```

- [ ] **Step 9: L'infobulle du nœud**

In `lib/l10n/app_en.arb`, replace:

```json
  "tooltipBossDesc": "Defeat the guardian of this floor to complete the act!",
```

with:

```json
  "tooltipBossDesc": "Defeat the guardian of this floor to complete the act!",
  "tooltipBossXpDesc": "Triple XP and gold, and one rune in your deck gains a level, if any still can.",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "tooltipBossDesc": "Battez le gardien de cet étage pour compléter l'acte !",
```

with:

```json
  "tooltipBossDesc": "Battez le gardien de cet étage pour compléter l'acte !",
  "tooltipBossXpDesc": "Le triple d'XP et d'or, et une rune de votre deck, si l'une peut encore monter, gagne un niveau.",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés, `String get tooltipBossXpDesc;` dans `app_localizations.dart`.

In `lib/ui/widgets/map/map_node_widget.dart`, replace:

```dart
        } else if (widget.node.bossRewardType == BossRewardType.doubleXp) {
          final isFr = Localizations.localeOf(context).languageCode == 'fr';
          return (isFr ? "Boss (XP & Or x2)" : "Boss (2x XP & Gold)", l10n.tooltipBossDesc);
```

with:

```dart
        } else if (widget.node.bossRewardType == BossRewardType.doubleXp) {
          // Le triple, et la rune (spec P-43 E3, §4.6, A25).
          return (l10n.legendBossXp, l10n.tooltipBossXpDesc);
```

- [ ] **Step 10: La prose du tutoriel et la documentation du prédicat d'offre**

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        '• 💀 Boss: three at the summit, one reward each — cards, triple XP '
        'and gold, or an improved relic. Choosing the Boss is choosing the '
        'reward.',
```

with:

```dart
        '• 💀 Boss: three at the summit, one reward each — cards, triple XP '
        'and gold with one rune raised a level if any still can, or an '
        'improved relic. Choosing the Boss is choosing the reward.',
```

Then replace:

```dart
        '• 💀 Boss : trois au sommet, une récompense chacun — des cartes, le '
        'triple d\'XP et d\'or, ou une relique améliorée. Choisir le Boss, '
        'c\'est choisir la récompense.',
```

with:

```dart
        '• 💀 Boss : trois au sommet, une récompense chacun — des cartes, le '
        'triple d\'XP et d\'or avec une rune montée d\'un niveau si l\'une '
        'peut encore monter, ou une relique améliorée. Choisir le Boss, '
        'c\'est choisir la récompense.',
```

In `lib/tutorial/widgets/tutorial_node_types_widget.dart`, replace:

```dart
      descEn: 'Rewards triple XP and gold.',
      descFr: 'Offre le triple d\'XP et d\'or.',
```

with:

```dart
      descEn: 'Rewards triple XP and gold, and raises a rune if any still can.',
      descFr: 'Offre le triple d\'XP et d\'or, et monte une rune si l\'une '
          'peut encore monter.',
```

In `lib/models/data/card_data.dart`, replace:

```dart
  /// un pool d'offre — boutique, bonus de boss, trouvaille ?
```

with:

```dart
  /// un pool d'offre — boutique, trouvaille ?
```

- [ ] **Step 11: Les tests passent**

Run: `flutter test test/unit/reward_controller_test.dart test/unit/forge_rune_rules_test.dart test/unit/signature_cards_transition_test.dart`
Expected: PASS.

- [ ] **Step 12: Analyse, commandes de contrôle et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e rolledBonusCard -e "XP & Or x2" -e "2x XP" -- lib test`
Expected: aucune sortie.

Run: `git grep -n sharpenedRunes -- lib/ui/screens/game_screen.dart`
Expected: une ligne — `final sharpened = ref.read(rewardProvider).sharpenedRunes;`.

Run: `git grep -n "rewardState.sharpenedRunes" -- lib`
Expected: aucune sortie — la copie `rewardState` est prise avant `collectGoldAndXp` (spec §8).

Run: `git grep -n tooltipBossXpDesc -- lib/ui/widgets/map/map_node_widget.dart`
Expected: une ligne.

Run: `flutter test`
Expected: `+1542: All tests passed!` (1538 + 3 + 1 + 1 − 1)

- [ ] **Step 13: Commit**

```bash
git add lib/game/game_constants.dart lib/game/services/forge_rune_rules.dart lib/game/controllers/reward_controller.dart lib/ui/screens/game_screen.dart lib/ui/widgets/map/map_node_widget.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_node_types_widget.dart lib/models/data/card_data.dart test/unit/reward_controller_test.dart test/unit/forge_rune_rules_test.dart test/unit/signature_cards_transition_test.dart
git commit -F - <<'EOF'
feat(boss): le boss XP monte une rune au lieu de donner une carte

La carte bonus disparait. A la collecte, une paire carte et rune tiree
parmi celles qui peuvent encore monter gagne un niveau, sans or ; sans
paire, rien ne monte et l ecran le dit. L infobulle dit enfin le triple
et la rune, la prose du tutoriel aussi. La transition E3 vers E4 garde
que le boss ne monte jamais une rune de signature.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 3: La *Meule*, et le plafond des notifications de la victoire

D42(a), A3 (spec §3.3, §4.2, §4.6) : la relique légendaire de D42(a), `relics/grindstone.json`, monte une rune de plus par exemplaire au boss « XP ». Sa règle de run, `RunState.extraBossRuneSharpens`, est posée à l'acquisition et retirée symétriquement — l'Autel aujourd'hui, l'échange du *Colporteur* à la Task 4 —, sur le modèle exact des deux reliques de la partie 1. Le tirage du boss passe de `GameConstants.bossXpRuneSharpens` à `bossXpRuneSharpens + extraBossRuneSharpens`.

**Le plafond des notifications** (exigence de l'orchestrateur, compte rendu de la vague §2.3, S6). `NotificationNotifier.show` garde au plus quatre notifications et retire la plus ancienne (`notification_overlay.dart:35-40`). L'étape « or et XP » de `GameScreen._presentNextReward` empile ses messages dans la même image ; relevés sur le code de la partie 2, nœud par nœud :

| Nœud | Messages de l'étape, dans l'ordre | Nombre |
|:---|:---|---:|
| Combat normal | « VICTOIRE », une « Carte trouvée » par carte — 1 + une par *Sacoche du glaneur* —, « LEVEL UP » | 3 + *Sacoches* |
| Élite | « RELIQUE OBTENUE » (poussée par le carrousel juste avant, `game_screen.dart:204`), « VICTOIRE », une ou deux « Carte trouvée » (`cardDrops` : un seul jet), « LEVEL UP » | 5 au plus |
| Boss « XP » | « VICTOIRE », une notification par rune montée — 1 + une par *Meule* — ou « aucune rune » (A5), « LEVEL UP » | 3 + *Meules* |
| Boss « relique » | « RELIQUE OBTENUE », « VICTOIRE », « LEVEL UP » | 3 |
| Boss « cartes » | « VICTOIRE », « LEVEL UP » | 2 |

Le cas réaliste le plus chargé est **cinq** : une élite à seconde carte avec un passage de niveau — quelle que soit la donnée des reliques —, un combat normal sous deux *Sacoches*, un boss « XP » sous deux *Meules* (une légendaire). Le combat lui-même ne pousse qu'une notification, le remélange (`game_screen.dart:436`), affichée 3,5 s : si elle est encore là, c'est elle, la plus ancienne et déjà lue, qui part. Le plafond passe donc à 5, une constante nommée qui porte ce relevé ; au-delà — trois exemplaires d'une même relique rare —, la plus ancienne part, et l'écran garde sa hauteur bornée (cinq tuiles, deux lignes pour « VICTOIRE » et « RELIQUE OBTENUE » : environ 290 px, que tient un téléphone en paysage). A10 garde une notification par carte trouvée : c'est le plafond qui change, pas le nombre de messages. La superposition ne change pas autrement.

**Files:**
- Create: `assets/data/relics/grindstone.json`
- Modify: `lib/game/controllers/run_controller.dart:46-52`, `:91-92`, `:108-109`, `:125-126`, `:144-145`, `:183-184` (`RunState.extraBossRuneSharpens`)
- Modify: `lib/game/controllers/run/player_stats_manager.dart:99-118` (`applyRunRuleModifier`), `:304-318` (`applyRelicEffect`), `:470-476` (`removeRelicEffect`)
- Modify: `lib/game/game_constants.dart` (la documentation de `bossXpRuneSharpens`, écrite en Task 2)
- Modify: `lib/game/controllers/reward_controller.dart` (`_sharpenRandomRunes`, écrit en Task 2)
- Modify: `lib/ui/widgets/notification_overlay.dart:22-40`
- Test: `test/unit/relic_exchange_test.dart` (un cas en fin de groupe), `test/unit/run_state_persistence_test.dart` (un cas), `test/unit/reward_controller_test.dart` (deux cas dans le groupe « le boss XP »), `test/unit/notification_notifier_test.dart` *(nouveau)*
- Test: `test/unit/real_bundle_load_test.dart:24`, `:36`, `:96` ; `test/unit/entity_id_convention_test.dart:67-74` ; `test/unit/audio/audio_catalogue_test.dart:51-52`

**Interfaces:**
- Consumes: `RewardController._sharpenRandomRunes` (Task 2) ; `PlayerStatsManager.applyRunRuleModifier`.
- Produces: `RunState.extraBossRuneSharpens` (`int`, 0 ; sérialisé) ; l'`effectType` `increase_boss_rune_sharpens` ; `NotificationNotifier.maxVisible` (`static const int`, 5).

- [ ] **Step 1: Les tests qui échouent**

In `test/unit/relic_exchange_test.dart`, replace:

```dart
      inventoryController.addRelic(ledger);
      inventoryController.addRelic(ledger);
      expect(runController.state.eliteCardChanceBonus, 50);

      runController.exchangeRelics([ledger], gained);
      expect(runController.state.eliteCardChanceBonus, 25);
    });
  });
}
```

with:

```dart
      inventoryController.addRelic(ledger);
      inventoryController.addRelic(ledger);
      expect(runController.state.eliteCardChanceBonus, 50);

      runController.exchangeRelics([ledger], gained);
      expect(runController.state.eliteCardChanceBonus, 25);
    });

    // La *Meule* (spec P-43 E3, §4.2) : la même symétrie.
    test('increase_boss_rune_sharpens s applique, s additionne et se retire',
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
      final grindstone = shippedRelic('grindstone');
      expect(grindstone.rarity, RelicRarity.legendary);
      expect(runController.state.extraBossRuneSharpens, 0);

      inventoryController.addRelic(grindstone);
      inventoryController.addRelic(grindstone);
      expect(runController.state.extraBossRuneSharpens, 2);

      runController.exchangeRelics([grindstone], gained);
      expect(runController.state.extraBossRuneSharpens, 1);
    });
  });
}
```

In `test/unit/run_state_persistence_test.dart`, replace:

```dart
      expect(restoredLegacy.extraCombatCards, 0);
      expect(restoredLegacy.eliteCardChanceBonus, 0);
    });
```

with:

```dart
      expect(restoredLegacy.extraCombatCards, 0);
      expect(restoredLegacy.eliteCardChanceBonus, 0);
    });

    // La règle de run de la *Meule* (spec P-43 E3, §3.8, §8).
    test('extraBossRuneSharpens round-trip et vaut 0 quand la cle manque', () {
      final json =
          buildRunState().copyWith(extraBossRuneSharpens: 2).toJson();
      expect(json['extraBossRuneSharpens'], 2);

      final (restored, _) = RunState.fromJsonWithReport(json);
      expect(restored.extraBossRuneSharpens, 2);

      final legacy = Map<String, dynamic>.from(json)
        ..remove('extraBossRuneSharpens');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.extraBossRuneSharpens, 0);
    });
```

In `test/unit/reward_controller_test.dart`, in the group `le boss XP` (Task 2), replace:

```dart
          winAndCollect(node);
          expect(rewardController.state.sharpenedRunes, isNull,
              reason: '${node.type.name} ${node.bossRewardType?.name}');
        }
        expect(runesOf(sharp), ['sharp:1']);
      });
    });
```

with:

```dart
          winAndCollect(node);
          expect(rewardController.state.sharpenedRunes, isNull,
              reason: '${node.type.name} ${node.bossRewardType?.name}');
        }
        expect(runesOf(sharp), ['sharp:1']);
      });

      // La *Meule*, lue par la récompense (spec P-43 E3, §4.6, §8 ; A3).
      test('la Meule monte une rune de plus au boss XP', () {
        inventoryController.addRelic(shippedRelic('grindstone'));
        final sharp = seedRare(const ['sharp:1']);

        winAndCollect(xpBoss);

        // Deux tirages, le second voit le premier.
        expect(rewardController.state.sharpenedRunes, [
          (cardUniqueId: sharp.uniqueId, runeId: 'sharp', level: 2),
          (cardUniqueId: sharp.uniqueId, runeId: 'sharp', level: 3),
        ]);
        expect(runesOf(sharp), ['sharp:3']);
      });

      test('la Meule ne monte rien hors du boss XP', () {
        inventoryController.addRelic(shippedRelic('grindstone'));
        final sharp = seedRare(const ['sharp:1']);

        for (final node in [
          makeNode(),
          makeNode(type: MapNodeType.boss, bossRewardType: BossRewardType.cards),
          makeNode(
            type: MapNodeType.boss,
            bossRewardType: BossRewardType.improvedRelic,
          ),
        ]) {
          winAndCollect(node);
          expect(rewardController.state.sharpenedRunes, isNull,
              reason: '${node.type.name} ${node.bossRewardType?.name}');
        }
        expect(runesOf(sharp), ['sharp:1']);
      });
    });
```

Create `test/unit/notification_notifier_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';

/// Le plafond des notifications visibles (compte rendu de la vague 3, §2.3,
/// S6) : l'étape « or et XP » de la victoire empile ses messages dans la
/// même image, et aucun ne doit partir avant d'être vu.
void main() {
  ProviderContainer newContainer() {
    final container = ProviderContainer();
    // Démonter le conteneur annule les minuteurs de 3,5 s.
    addTearDown(container.dispose);
    return container;
  }

  List<String> messagesOf(ProviderContainer container) =>
      [for (final n in container.read(notificationProvider)) n.message];

  test('une elite a seconde carte et passage de niveau garde ses cinq '
      'messages, apres le remelange du dernier tour', () {
    final container = newContainer();
    final notifications = container.read(notificationProvider.notifier);
    // La fin du combat a laissé un message, déjà lu.
    notifications.show('🔄 Remélange de la défausse');

    const step = [
      '👑 RELIQUE OBTENUE : 📜 Registre des primes (RARE)',
      '⚔️ VICTOIRE ! +40 Or et +30 XP gagnés',
      '🃏 Carte trouvée : Frappe',
      '🃏 Carte trouvée : Défense',
      '🎉 LEVEL UP !',
    ];
    for (final message in step) {
      notifications.show(message);
    }

    expect(messagesOf(container), step);
  });

  test('un message au-dela du plafond retire le plus ancien, et lui seul', () {
    final container = newContainer();
    final notifications = container.read(notificationProvider.notifier);
    const count = NotificationNotifier.maxVisible + 1;

    for (var i = 1; i <= count; i++) {
      notifications.show('message $i');
    }

    expect(messagesOf(container), [
      for (var i = 2; i <= count; i++) 'message $i',
    ]);
  });
}
```

- [ ] **Step 2: Les lancer pour les voir échouer**

Run: `flutter test test/unit/relic_exchange_test.dart test/unit/run_state_persistence_test.dart test/unit/reward_controller_test.dart test/unit/notification_notifier_test.dart`
Expected: FAIL à la compilation — `extraBossRuneSharpens` n'existe pas, `maxVisible` non plus.

- [ ] **Step 3: La relique**

Create `assets/data/relics/grindstone.json` — l'`id` déclaré, que le chargeur du script de simulation lit en dur (spec §3.3, §9) :

```json
{
  "id": "grindstone",
  "name_en": "Grindstone",
  "name_fr": "Meule",
  "description_en": "The XP Boss reward raises one more rune by a level, if any still can.",
  "description_fr": "La récompense du Boss d'XP fait gagner un niveau à une rune de plus, si l'une peut encore monter.",
  "trigger": "startOfRun",
  "effectType": "increase_boss_rune_sharpens",
  "value": 1,
  "rarity": "legendary",
  "emoji": "⚙️"
}
```

`assets/data/relics/` est déjà déclaré dans `pubspec.yaml` : aucune régénération.

- [ ] **Step 4: La règle de run**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  final int extraCombatCards;
  final int eliteCardChanceBonus;
```

with:

```dart
  final int extraCombatCards;
  final int eliteCardChanceBonus;

  /// La règle de run de la *Meule* (spec P-43 E3, §4.2, §4.6 ; D42(a), A3) :
  /// les runes que le boss « XP » monte en plus de
  /// `GameConstants.bossXpRuneSharpens`, +1 par exemplaire.
  final int extraBossRuneSharpens;
```

Then replace `    this.eliteCardChanceBonus = 0,` with:

```dart
    this.eliteCardChanceBonus = 0,
    this.extraBossRuneSharpens = 0,
```

Then replace `    int? eliteCardChanceBonus,` with:

```dart
    int? eliteCardChanceBonus,
    int? extraBossRuneSharpens,
```

Then replace `      eliteCardChanceBonus: eliteCardChanceBonus ?? this.eliteCardChanceBonus,` with:

```dart
      eliteCardChanceBonus: eliteCardChanceBonus ?? this.eliteCardChanceBonus,
      extraBossRuneSharpens:
          extraBossRuneSharpens ?? this.extraBossRuneSharpens,
```

Then replace `        'eliteCardChanceBonus': eliteCardChanceBonus,` with:

```dart
        'eliteCardChanceBonus': eliteCardChanceBonus,
        'extraBossRuneSharpens': extraBossRuneSharpens,
```

Then replace `      eliteCardChanceBonus: json['eliteCardChanceBonus'] as int? ?? 0,` with:

```dart
      eliteCardChanceBonus: json['eliteCardChanceBonus'] as int? ?? 0,
      extraBossRuneSharpens: json['extraBossRuneSharpens'] as int? ?? 0,
```

Chacun de ces six textes ne paraît qu'une fois dans le fichier.

In `lib/game/controllers/run/player_stats_manager.dart`, replace:

```dart
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

with:

```dart
  /// Le seul à recevoir les deux règles de trouvaille et celle de la
  /// *Meule* : seules les reliques les écrivent, par `applyRelicEffect` et
  /// `removeRelicEffect` (spec P-43 E3, §3.8, §4.2).
  void applyRunRuleModifier({
    int cardsPerTurnAcc = 0,
    int extraCombatCardsAcc = 0,
    int eliteCardChanceAcc = 0,
    int extraBossRuneSharpensAcc = 0,
  }) {
    final run = controller.currentState;
    controller.updateState(
      run.copyWith(
        cardsPerTurn: run.cardsPerTurn + cardsPerTurnAcc,
        extraCombatCards: run.extraCombatCards + extraCombatCardsAcc,
        eliteCardChanceBonus: run.eliteCardChanceBonus + eliteCardChanceAcc,
        extraBossRuneSharpens:
            run.extraBossRuneSharpens + extraBossRuneSharpensAcc,
      ),
    );
  }
```

Then replace:

```dart
      // Ces trois effectTypes n'ont de sens qu'en `startOfRun` : une variante
```

with:

```dart
      // Ces quatre effectTypes n'ont de sens qu'en `startOfRun` : une variante
```

Then replace:

```dart
      case 'increase_elite_card_chance':
        applyRunRuleModifier(eliteCardChanceAcc: relic.value);
        break;
```

with:

```dart
      case 'increase_elite_card_chance':
        applyRunRuleModifier(eliteCardChanceAcc: relic.value);
        break;
      // La *Meule* (spec P-43 E3, §4.2) : une rune de plus au boss « XP ».
      case 'increase_boss_rune_sharpens':
        applyRunRuleModifier(extraBossRuneSharpensAcc: relic.value);
        break;
```

Then replace:

```dart
        case 'increase_elite_card_chance':
          applyRunRuleModifier(eliteCardChanceAcc: -relic.value);
          break;
      }
```

with:

```dart
        case 'increase_elite_card_chance':
          applyRunRuleModifier(eliteCardChanceAcc: -relic.value);
          break;
        case 'increase_boss_rune_sharpens':
          applyRunRuleModifier(extraBossRuneSharpensAcc: -relic.value);
          break;
      }
```

Le relais `RunController.applyRunRuleModifier` ne change pas (levée du second arrêt, n° 9).

- [ ] **Step 5: Le tirage du boss lit la règle**

In `lib/game/game_constants.dart`, replace:

```dart
  /// Les runes que la récompense du boss « XP » monte d'un niveau (D42(a)),
  /// tirées parmi les paires (carte, rune) du deck dont la rune peut encore
  /// monter.
  static const int bossXpRuneSharpens = 1;
```

with:

```dart
  /// Les runes que la récompense du boss « XP » monte d'un niveau (D42(a)),
  /// tirées parmi les paires (carte, rune) du deck dont la rune peut encore
  /// monter ; la *Meule* en ajoute une par exemplaire
  /// (`RunState.extraBossRuneSharpens`).
  static const int bossXpRuneSharpens = 1;
```

In `lib/game/controllers/reward_controller.dart`, replace:

```dart
  /// [GameConstants.bossXpRuneSharpens] tirages, chacun une paire (carte,
  /// rune) au hasard parmi celles du deck dont la rune peut encore monter,
  /// montée d'un niveau, sans or ; chaque tirage voit le précédent. Sans
  /// paire, rien ne monte.
  List<SharpenedRune> _sharpenRandomRunes() {
    final deck = ref.read(deckProvider.notifier);
    final catalog = GameDataRegistry.instance?.forgeUpgrades ??
        const <ForgeUpgradeData>[];
    final rng = Random();
    final sharpened = <SharpenedRune>[];
    for (var i = 0; i < GameConstants.bossXpRuneSharpens; i++) {
```

with:

```dart
  /// [GameConstants.bossXpRuneSharpens] tirages, plus un par *Meule*
  /// (`RunState.extraBossRuneSharpens`, A3), chacun une paire (carte, rune)
  /// au hasard parmi celles du deck dont la rune peut encore monter, montée
  /// d'un niveau, sans or ; chaque tirage voit le précédent. Sans paire,
  /// rien ne monte.
  List<SharpenedRune> _sharpenRandomRunes() {
    final deck = ref.read(deckProvider.notifier);
    final catalog = GameDataRegistry.instance?.forgeUpgrades ??
        const <ForgeUpgradeData>[];
    final rng = Random();
    final sharpened = <SharpenedRune>[];
    final draws = GameConstants.bossXpRuneSharpens +
        ref.read(runProvider).extraBossRuneSharpens;
    for (var i = 0; i < draws; i++) {
```

- [ ] **Step 6: Le plafond des notifications**

In `lib/ui/widgets/notification_overlay.dart`, replace:

```dart
class NotificationNotifier extends StateNotifier<List<GameNotification>> {
  final Map<String, Timer> _timers = {};
```

with:

```dart
class NotificationNotifier extends StateNotifier<List<GameNotification>> {
  /// Les notifications visibles à la fois, au plus. L'étape « or et XP » de
  /// la victoire (`GameScreen._presentNextReward`) empile les siennes dans la
  /// même image (spec P-43 E3, §4.1, §4.6 ; A10) : la relique d'une élite,
  /// poussée juste avant, « VICTOIRE », une « Carte trouvée » par carte, une
  /// notification par rune que monte le boss « XP », « LEVEL UP ». Cinq au
  /// plus dans un cas réaliste — une élite à seconde carte avec un passage
  /// de niveau, un combat normal sous deux *Sacoches du glaneur*, un boss
  /// « XP » sous deux *Meules* — ; un message laissé par la fin du combat,
  /// déjà lu, part le premier.
  static const int maxVisible = 5;

  final Map<String, Timer> _timers = {};
```

Then replace:

```dart
    // Supprime la plus ancienne si le stack dépasse 4 notifications actives
    if (state.length >= 4) {
```

with:

```dart
    // Au-delà de [maxVisible], la plus ancienne part.
    if (state.length >= maxVisible) {
```

- [ ] **Step 7: Les comptes de la donnée livrée**

In `test/unit/real_bundle_load_test.dart`, replace `  test('le manifeste declare les 90 fichiers d entite, par categorie', () async {` with `  test('le manifeste declare les 91 fichiers d entite, par categorie', () async {`, replace `    expect(countUnder('assets/data/relics/', 4), 27, reason: 'reliques');` with `    expect(countUnder('assets/data/relics/', 4), 28, reason: 'reliques');`, and replace `    expect(registry.relics, hasLength(27));` with `    expect(registry.relics, hasLength(28));`.

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 90 fichiers d entite', () {
    // 17 cartes neutres + 27 reliques (dont le Registre des primes et la
    // Sacoche du glaneur, P-43 E3) + 5 evenements + 11 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 90,
        reason: '17 cartes neutres + 27 reliques + 5 evenements + 11 '
            'ameliorations de forge + 9 passifs + 8 recompenses de niveau + '
            '3 class.json + 6 cartes de classe + 4 enemy.json');
  });
```

with:

```dart
  test('il y a bien 91 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 5 evenements + 11
    // ameliorations de forge + 9 passifs + 8 recompenses de niveau + 3
    // class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 91,
        reason: '17 cartes neutres + 28 reliques + 5 evenements + 11 '
            'ameliorations de forge + 9 passifs + 8 recompenses de niveau + '
            '3 class.json + 6 cartes de classe + 4 enemy.json');
  });
```

In `test/unit/audio/audio_catalogue_test.dart`, replace:

```dart
      expect(contentFiles.length, 54,
          reason: '17 cartes + 27 reliques + 6 cartes de classe + 4 ennemis');
```

with:

```dart
      expect(contentFiles.length, 55,
          reason: '17 cartes + 28 reliques + 6 cartes de classe + 4 ennemis');
```

- [ ] **Step 8: Les tests passent**

Run: `flutter test test/unit/relic_exchange_test.dart test/unit/run_state_persistence_test.dart test/unit/reward_controller_test.dart test/unit/notification_notifier_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/audio/audio_catalogue_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: PASS — `shipped_entities_round_trip_test.dart` réécrit `grindstone.json` à l'identique : son `effectType` neuf est admis par le vocabulaire lu sur le disque (spec §6).

- [ ] **Step 9: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1548: All tests passed!` (1542 + 1 + 1 + 2 + 2)

- [ ] **Step 10: Commit**

```bash
git add assets/data/relics/grindstone.json lib/game/controllers/run_controller.dart lib/game/controllers/run/player_stats_manager.dart lib/game/game_constants.dart lib/game/controllers/reward_controller.dart lib/ui/widgets/notification_overlay.dart test/unit/relic_exchange_test.dart test/unit/run_state_persistence_test.dart test/unit/reward_controller_test.dart test/unit/notification_notifier_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/audio/audio_catalogue_test.dart
git commit -F - <<'EOF'
feat(reliques): la Meule monte une rune de plus au boss XP

Une relique legendaire porte une regle de run, posee a l acquisition et
retiree symetriquement. Le plafond des notifications passe de quatre a
cinq : une elite a seconde carte avec un passage de niveau empile cinq
messages dans la meme image, et aucun ne doit partir avant d etre vu.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 4: Le *Colporteur* — l'échange de relique, la condition de PV, le retour système

D23, D63 (Q15), A2, A19, A20, A22 (spec §3.4, §4.9, §5.1) : un événement neuf, `events/relic_peddler.json`, cède la relique la plus faible — tirée une fois, à l'ouverture, au hasard parmi les ex æquo, gardée dans `EventState.tradedRelic` — contre 40 or × (rang + 1), ou, sous la moitié des PV, contre 20 % des PV max. Deux actions composables (`trade_relic`, `heal_percent`) et une condition de choix (`requiresHpBelowPercent`) ; `RunController.loseRelic` défait la règle de run de la relique cédée. `EventChoice.isSelectable` reçoit le fait `hasTradedRelic` calculé (C4.4, C4.5) par `EventController.isChoiceSelectable`, que l'écran appelle à la place d'`isSelectable` — le seul appelant qui lui fournit l'or et les PV. Les badges nomment la relique et son prix ; sans relique visée, « Aucune relique à céder » (propriétaire, n° 5). Le retour système, après un choix, résout le nœud (A22).

Le *Rémouleur* — `lose_hp_percent`, `sharpen_rune`, le fait `hasSharpenableRune`, la sélection sans or — est la Task 5 : `isSelectable` ne reçoit ici que le fait que lit une action de cette tâche.

**Files:**
- Create: `assets/data/events/relic_peddler.json`
- Modify: `lib/models/data/event_data.dart:1`, `:47-127` (`EventChoice`, `EventAction`)
- Modify: `lib/models/event_state.dart`
- Modify: `lib/game/controllers/event_controller.dart:15-42`, `:44-133`
- Modify: `lib/game/controllers/run_controller.dart:403-413` (`loseRelic`)
- Modify: `lib/ui/screens/event_screen.dart:75-140`, `:209-274`, `:321-323`, `:528`
- Modify: `lib/l10n/app_en.arb:676`, `lib/l10n/app_fr.arb:254` ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Test: `test/unit/event_controller_test.dart` (un groupe neuf), `test/widget/event_screen_test.dart` *(nouveau — aucun test n'ouvre `EventScreen` aujourd'hui : `git grep -l EventScreen -- test` est vide)*
- Test: `test/unit/real_bundle_load_test.dart:24`, `:37`, `:97` ; `test/unit/entity_id_convention_test.dart` (le cas des fichiers d'entité)

**Interfaces:**
- Consumes: `RunController.removeRelicEffect(RelicData)`, `InventoryController.removeRelics(List<String>)`, `RunController.heal(int)`.
- Produces:
  - `EventChoice.requiresHpBelowPercent` (`int?`) ; `bool EventChoice.isSelectable(int currentHp, int currentGold, int currentMaxHp, {required bool hasTradedRelic})` — la Task 5 y ajoute `required bool hasSharpenableRune` ;
  - `int EventAction.hpPercentOf(int maxHp)`, `int EventAction.tradeGoldFor(RelicRarity rarity)` ;
  - `EventState.tradedRelic` (`RelicData?`) ;
  - `bool EventController.isChoiceSelectable(EventChoice choice)` — la Task 5 y ajoute `Iterable<ForgeUpgradeData> runeCatalog` ;
  - `void RunController.loseRelic(RelicData relic)` ;
  - les clés ARB `eventTradeRelic` (`{relic}`, `{amount}`), `eventGiveRelic` (`{relic}`), `eventNoRelicToGive`.

- [ ] **Step 1: Les tests du contrôleur**

In `test/unit/event_controller_test.dart`, replace the imports:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

void main() {
```

with:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import 'shipped_data.dart';

void main() {
  // Le registre réel, pour les événements livrés.
  TestWidgetsFlutterBinding.ensureInitialized();

```

Then replace the end of the file:

```dart
      expect(chosen.id, 'r_common');
      expect(inventoryController.state.relics.contains(chosen), true);
    });
  });
}
```

with:

```dart
      expect(chosen.id, 'r_common');
      expect(inventoryController.state.relics.contains(chosen), true);
    });
  });

  // Le Colporteur (spec P-43 E3, §3.4, §4.9 ; D23, D63, A2, A19, A20) et les
  // faits que reçoit `EventChoice.isSelectable` (C4.4, C4.5).
  group('le Colporteur', () {
    late ProviderContainer container;
    late EventController events;
    late RunController run;
    late InventoryController inventory;
    late EventData peddler;

    const paladin = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    RelicData relic(String id, RelicRarity rarity) => RelicData(
          id: id,
          nameEn: id,
          nameFr: id,
          trigger: RelicTrigger.startOfCombat,
          effectType: 'gain_armor',
          value: 1,
          rarity: rarity,
          emoji: '⬜',
        );

    setUpAll(() async {
      peddler = (await loadGameDataRegistry(rootBundle))
          .events
          .singleWhere((e) => e.id == 'relic_peddler');
    });

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      events = container.read(eventProvider.notifier);
      run = container.read(runProvider.notifier);
      inventory = container.read(inventoryProvider.notifier);
      run.startNewRun(paladin);
    });

    EventChoice sale() => peddler.choices[0];
    EventChoice remedies() => peddler.choices[1];

    test('la relique visee est la plus faible, au hasard parmi les ex aequo',
        () {
      inventory.addRelic(relic('rare', RelicRarity.rare));
      inventory.addRelic(relic('first', RelicRarity.common));
      inventory.addRelic(relic('second', RelicRarity.common));

      final seen = <String>{};
      for (var i = 0; i < 50; i++) {
        events.setEvent(peddler);
        seen.add(events.state.tradedRelic!.id);
      }
      expect(seen, {'first', 'second'});
    });

    test('aucune relique visee sur un inventaire vide, ni sans action '
        'trade_relic', () {
      events.setEvent(peddler);
      expect(events.state.tradedRelic, isNull);

      inventory.addRelic(relic('common', RelicRarity.common));
      events.setEvent(EventData(id: 'other', choices: [
        EventChoice(actions: [EventAction(type: 'gain_gold', value: 10)]),
      ]));
      expect(events.state.tradedRelic, isNull);
    });

    test('vendre cede la relique visee contre 40 or par rang, et defait sa '
        'regle de run', () {
      // La Sacoche du glaneur, rare (rang 2) : 40 × 3 or ; `loseRelic`
      // défait sa règle de run.
      inventory.addRelic(shippedRelic('gleaners_pouch'));
      expect(run.currentState.extraCombatCards, 1);
      final goldBefore = inventory.state.gold;
      events.setEvent(peddler);

      events.selectChoice(sale(), const []);

      expect(inventory.state.relics, isEmpty);
      expect(run.currentState.extraCombatCards, 0);
      expect(inventory.state.gold, goldBefore + 120);
    });

    test('les remedes cedent la relique sans or et soignent 20 % des PV max, '
        'arrondis', () {
      // 87 PV max : 20 % font 17,4, arrondis à 17 (`.round()`).
      run.applyHeroStatModifier(maxPvAcc: -13);
      run.takeDamage(50);
      expect(run.currentState.heroStats.currentPv, 37);
      inventory.addRelic(relic('common', RelicRarity.common));
      final goldBefore = inventory.state.gold;
      events.setEvent(peddler);

      events.selectChoice(remedies(), const []);

      expect(inventory.state.relics, isEmpty);
      expect(inventory.state.gold, goldBefore);
      expect(run.currentState.heroStats.currentPv, 37 + 17);
    });

    test('isChoiceSelectable : la vente suit la relique visee', () {
      events.setEvent(peddler);
      expect(events.isChoiceSelectable(sale()), isFalse);

      inventory.addRelic(relic('common', RelicRarity.common));
      events.setEvent(peddler);
      expect(events.isChoiceSelectable(sale()), isTrue);
    });

    // L'or, lu sur l'inventaire (n° 1 du tour 5) : avec le cas des remèdes de
    // l'écran, il épingle les trois entiers positionnels d'`isSelectable`.
    test('isChoiceSelectable lit l or de l inventaire', () {
      final offering = EventChoice(
        actions: [EventAction(type: 'spend_gold', value: 40)],
      );
      events.setEvent(EventData(id: 'altar', choices: [offering]));

      inventory.reset(initialGold: 39);
      expect(events.isChoiceSelectable(offering), isFalse);

      inventory.reset(initialGold: 40);
      expect(events.isChoiceSelectable(offering), isTrue);
    });

    test('isSelectable : un choix trade_relic suit le fait hasTradedRelic', () {
      expect(sale().isSelectable(100, 0, 100, hasTradedRelic: false), isFalse);
      expect(sale().isSelectable(100, 0, 100, hasTradedRelic: true), isTrue);
    });

    test('requiresHpBelowPercent se lit dans la donnee : sur 100 PV max, 29 '
        'passe a 30 %, 30 non', () {
      final choice = EventChoice.fromJson({
        'text_fr': 'Boire',
        'requiresHpBelowPercent': 30,
        'actions': <dynamic>[],
      });
      expect(choice.requiresHpBelowPercent, 30);
      expect(choice.isSelectable(29, 0, 100, hasTradedRelic: false), isTrue);
      expect(choice.isSelectable(30, 0, 100, hasTradedRelic: false), isFalse);

      for (final bad in <Object>[0, 101, '50']) {
        expect(
          () => EventChoice.fromJson({
            'requiresHpBelowPercent': bad,
            'actions': <dynamic>[],
          }),
          throwsFormatException,
          reason: '$bad',
        );
      }
    });

    test('les valeurs de trade_relic et heal_percent sont bornees au '
        'chargement', () {
      for (final (type, bad) in <(String, Object)>[
        ('trade_relic', -1),
        ('trade_relic', '40'),
        ('heal_percent', 0),
        ('heal_percent', 101),
      ]) {
        expect(
          () => EventAction.fromJson({'type': type, 'value': bad}),
          throwsFormatException,
          reason: '$type $bad',
        );
      }
      expect(
          EventAction.fromJson({'type': 'trade_relic', 'value': 0}).value, 0);
      expect(
          EventAction.fromJson({'type': 'heal_percent', 'value': 100}).value,
          100);
    });

    test('le Colporteur livre : ses actions, et la moitie des PV pour les '
        'remedes', () {
      List<(String, Object?)> actionsOf(EventChoice choice) =>
          [for (final a in choice.actions) (a.type, a.value)];

      expect(peddler.choices, hasLength(3));
      expect(actionsOf(sale()), [('trade_relic', 40)]);
      expect(sale().requiresHpBelowPercent, isNull);
      expect(actionsOf(remedies()),
          [('trade_relic', 0), ('heal_percent', 20)]);
      expect(remedies().requiresHpBelowPercent, 50);
      expect(peddler.choices[2].actions, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Le test de l'écran**

Create `test/widget/event_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/event_screen.dart';

import '../unit/shipped_data.dart';

/// L'écran d'événement, sur les événements livrés (spec P-43 E3, §4.9, §8,
/// « L'écran d'événement »).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  const sale =
      'Vendre votre relique la plus faible (+40 à +200 Or selon sa rareté)';
  const remedies = "L'échanger contre des remèdes (+20 % des PV max, si vos "
      'PV sont sous la moitié)';
  const leave = 'Passer votre chemin (Rien)';

  late GameDataRegistry shipped;
  setUpAll(() async {
    shipped = await loadGameDataRegistry(rootBundle);
  });

  EventData eventOf(String id) =>
      shipped.events.singleWhere((e) => e.id == id);

  /// Une run neuve, au premier nœud de sa carte, sur un registre dont le
  /// seul événement est [event] : `initState` en tire un au hasard parmi
  /// `events` (`event_screen.dart:24-29`), et un `setEvent` posé avant le
  /// premier pump serait écrasé. [prepare] agit avant l'ouverture —
  /// l'échange vise sa relique à l'ouverture (A20).
  Future<ProviderContainer> startRun(
    WidgetTester tester,
    EventData event, {
    void Function(ProviderContainer container)? prepare,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry = GameDataRegistry(
      enemies: const [],
      heroes: const [hero],
      cards: shipped.cards,
      events: [event],
      passives: const [],
      relics: shipped.relics,
      forgeUpgrades: shipped.forgeUpgrades,
    );
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);
    // L'écran appelle `.requireValue` dans `initState` : le futur doit être
    // résolu avant le premier pump.
    await container.read(gameDataLoaderProvider.future);

    final run = container.read(runProvider.notifier);
    run.startNewRun(hero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    prepare?.call(container);
    return container;
  }

  Widget app(ProviderContainer container, Widget home) =>
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
          locale: const Locale('fr', ''),
          home: home,
        ),
      );

  /// L'écran d'événement en page d'accueil.
  Future<ProviderContainer> pumpEvent(
    WidgetTester tester,
    EventData event, {
    void Function(ProviderContainer container)? prepare,
  }) async {
    final container = await startRun(tester, event, prepare: prepare);
    await tester.pumpWidget(app(container, const EventScreen()));
    await tester.pumpAndSettle();
    return container;
  }

  /// L'écran poussé sur une vraie pile, comme la carte du monde le pousse :
  /// le retour système a une page où revenir.
  Future<ProviderContainer> pushEvent(
    WidgetTester tester,
    EventData event,
  ) async {
    final container = await startRun(tester, event);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EventScreen()),
            ),
            child: const Text('Ouvrir l evenement'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir l evenement'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Le bouton du choix dont le texte est [text] est-il actif ?
  bool enabled(WidgetTester tester, String text) =>
      tester
          .widget<ElevatedButton>(find.ancestor(
            of: find.text(text),
            matching: find.byType(ElevatedButton),
          ))
          .onPressed !=
      null;

  bool currentNodeCompleted(ProviderContainer container) {
    final run = container.read(runProvider);
    return run.mapNodes
        .singleWhere((n) => n.id == run.currentNodeId)
        .isCompleted;
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
  }

  void carryBandage(ProviderContainer container) => container
      .read(inventoryProvider.notifier)
      .addRelic(shippedRelic('bandage'));

  // A22 : le mécanisme du feu et du Puits.
  group('le retour systeme', () {
    testWidgets('apres un choix, il resout le noeud et ferme l ecran, une '
        'seule fois', (tester) async {
      final container = await pushEvent(tester, eventOf('relic_peddler'));

      await tester.tap(find.text(leave));
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(find.byType(EventScreen), findsNothing);
      expect(find.text('Ouvrir l evenement'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      // `completeCurrentNode` pousse le point de sauvegarde : un cran, donc
      // un seul `_leave`.
      expect(container.read(checkpointProvider), 1);
    });

    testWidgets('avant tout choix, il ne fait rien', (tester) async {
      final container = await pushEvent(tester, eventOf('relic_peddler'));

      await pressBack(tester);

      expect(find.byType(EventScreen), findsOneWidget);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });

  group('le Colporteur', () {
    testWidgets('les badges nomment la relique visee et son prix',
        (tester) async {
      await pumpEvent(tester, eventOf('relic_peddler'), prepare: carryBandage);

      // Le Bandage de voyage, commun (rang 0) : 40 or.
      expect(find.text('Cède Bandage de voyage : +40 Or'), findsOneWidget);
      expect(find.text('Cède Bandage de voyage'), findsOneWidget);
      expect(find.text('+20 PV'), findsOneWidget);
    });

    testWidgets('sans relique, les deux echanges sont inactifs et le disent',
        (tester) async {
      await pumpEvent(tester, eventOf('relic_peddler'));

      expect(tester.takeException(), isNull);
      expect(find.text('Aucune relique à céder'), findsNWidgets(2));
      expect(enabled(tester, sale), isFalse);
      expect(enabled(tester, remedies), isFalse);
      expect(enabled(tester, leave), isTrue);
    });

    // Avec le cas de l'or du contrôleur, ce cas épingle les trois entiers
    // positionnels d'`isSelectable` (n° 1 du tour 5) : les PV, les PV max.
    testWidgets('les remedes ne s offrent que sous la moitie des PV',
        (tester) async {
      final container = await pumpEvent(
        tester,
        eventOf('relic_peddler'),
        prepare: carryBandage,
      );
      expect(enabled(tester, sale), isTrue);
      expect(enabled(tester, remedies), isFalse);

      container.read(runProvider.notifier).takeDamage(60);
      await tester.pump();

      expect(enabled(tester, remedies), isTrue);
    });
  });
}
```

- [ ] **Step 3: Les lancer pour les voir échouer**

Run: `flutter test test/unit/event_controller_test.dart test/widget/event_screen_test.dart`
Expected: FAIL — à la compilation (`tradedRelic`, `isChoiceSelectable`, `requiresHpBelowPercent`, `hasTradedRelic` n'existent pas), et `relic_peddler` absent du registre.

- [ ] **Step 4: L'événement**

Create `assets/data/events/relic_peddler.json` — l'`id` déclaré, que lit en dur le chargeur du script de simulation (spec §3.3, §9) :

```json
{
  "id": "relic_peddler",
  "title_en": "The Peddler",
  "title_fr": "Le Colporteur",
  "description_en": "A sharp-eyed peddler weighs your relics. 'I'll take the least precious one — for gold, or for my remedies if you need them.'",
  "description_fr": "Un colporteur au regard vif soupèse vos reliques. « Je prends la moins précieuse — contre de l'or, ou contre mes remèdes si vous en avez besoin. »",
  "choices": [
    {
      "text_en": "Sell your weakest relic (+40 to +200 Gold depending on its rarity)",
      "text_fr": "Vendre votre relique la plus faible (+40 à +200 Or selon sa rareté)",
      "result_text_en": "The peddler weighs the relic, nods, and counts out his coins.",
      "result_text_fr": "Le colporteur soupèse la relique, hoche la tête et vous compte ses pièces.",
      "actions": [
        {
          "type": "trade_relic",
          "value": 40
        }
      ]
    },
    {
      "text_en": "Trade it for remedies (+20% max HP, if your HP is below half)",
      "text_fr": "L'échanger contre des remèdes (+20 % des PV max, si vos PV sont sous la moitié)",
      "result_text_en": "He takes the relic and hands you a bitter vial. Your wounds close.",
      "result_text_fr": "Il emporte la relique et vous tend une fiole amère. Vos blessures se referment.",
      "requiresHpBelowPercent": 50,
      "actions": [
        {
          "type": "trade_relic",
          "value": 0
        },
        {
          "type": "heal_percent",
          "value": 20
        }
      ]
    },
    {
      "text_en": "Move on (Nothing)",
      "text_fr": "Passer votre chemin (Rien)",
      "result_text_en": "The peddler shrugs and goes on his way.",
      "result_text_fr": "Le colporteur hausse les épaules et reprend sa route.",
      "actions": []
    }
  ]
}
```

`assets/data/events/` est déjà déclaré : aucune régénération.

- [ ] **Step 5: Le modèle**

In `lib/models/data/event_data.dart`, add at the top of the file the import:

```dart
import 'relic_data.dart';

```

Then replace everything from `class EventChoice {` to the end of the file with:

```dart
class EventChoice {
  final String textEn;
  final String textFr;
  final String resultTextEn;
  final String resultTextFr;
  final List<EventAction> actions;

  /// Le choix ne se prend que sous ce pourcentage des PV max — les remèdes du
  /// *Colporteur* (spec P-43 E3, §4.9, A19). `null` : aucune condition de PV.
  final int? requiresHpBelowPercent;

  EventChoice({
    this.textEn = '',
    this.textFr = '',
    this.resultTextEn = '',
    this.resultTextFr = '',
    required this.actions,
    this.requiresHpBelowPercent,
  });

  String getText(String locale) => locale == 'fr' ? textFr : textEn;
  String getResultText(String locale) =>
      locale == 'fr' ? resultTextFr : resultTextEn;

  /// Le choix peut-il être pris ? Les PV, l'or et les PV max, lus par
  /// l'appelant ; [hasTradedRelic], qu'une relique est visée par l'échange
  /// (A20) — un fait que le modèle reçoit calculé : ce fichier n'importe rien
  /// de `lib/game/` (spec P-43 E3, §4.9 ; C4.4, C4.5). Son appelant de jeu
  /// est `EventController.isChoiceSelectable`.
  bool isSelectable(
    int currentHp,
    int currentGold,
    int currentMaxHp, {
    required bool hasTradedRelic,
  }) {
    final hpCap = requiresHpBelowPercent;
    if (hpCap != null && currentHp * 100 >= currentMaxHp * hpCap) {
      return false;
    }
    for (final action in actions) {
      if (action.type == 'take_damage') {
        final damage = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (currentHp <= damage) {
          return false;
        }
      } else if (action.type == 'spend_gold') {
        final cost = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (currentGold < cost) {
          return false;
        }
      } else if (action.type == 'gain_max_hp') {
        final val = action.value is int
            ? action.value as int
            : int.tryParse(action.value.toString()) ?? 0;
        if (val < 0 && currentMaxHp <= -val) {
          return false;
        }
      } else if (action.type == 'trade_relic') {
        if (!hasTradedRelic) return false;
      }
    }
    return true;
  }

  factory EventChoice.fromJson(Map<String, dynamic> json) {
    final tEn = json['text_en'] as String? ?? json['text'] as String? ?? '';
    final tFr = json['text_fr'] as String? ?? json['text'] as String? ?? '';
    final rEn =
        json['result_text_en'] as String? ??
        json['resultText'] as String? ??
        '';
    final rFr =
        json['result_text_fr'] as String? ??
        json['resultText'] as String? ??
        '';

    return EventChoice(
      textEn: tEn,
      textFr: tFr,
      resultTextEn: rEn,
      resultTextFr: rFr,
      actions: (json['actions'] as List)
          .map((a) => EventAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      requiresHpBelowPercent: _readHpPercent(json['requiresHpBelowPercent']),
    );
  }

  /// `requiresHpBelowPercent` : absent, ou un entier de 1 à 100.
  static int? _readHpPercent(Object? raw) {
    if (raw == null) return null;
    if (raw is! int || raw < 1 || raw > 100) {
      throw FormatException(
        'requiresHpBelowPercent vaut un entier de 1 à 100 — reçu : $raw',
      );
    }
    return raw;
  }
}

class EventAction {
  /// Le type d'action, que résout la table d'`EventController.selectChoice`.
  final String type;
  final dynamic value;

  EventAction({required this.type, required this.value});

  /// Le montant d'une action en pourcentage des PV max — `heal_percent` —,
  /// arrondi comme le script de simulation (`.round()` ; spec P-43 E3, §4.9).
  int hpPercentOf(int maxHp) => (maxHp * (value as int) / 100).round();

  /// L'or que rapporte `trade_relic` pour une relique de [rarity] : `value`
  /// par rang, commune = 1 (D63 ; spec P-43 E3, A2).
  int tradeGoldFor(RelicRarity rarity) => (value as int) * (rarity.index + 1);

  /// Les bornes de `value` des actions d'E3 (spec P-43 E3, §3.8, §4.9) : un
  /// entier, refusé hors bornes au chargement ; `max` nul, sans borne haute.
  static const Map<String, ({int min, int? max})> _bounds = {
    'trade_relic': (min: 0, max: null),
    'heal_percent': (min: 1, max: 100),
  };

  factory EventAction.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final value = json['value'];
    final bounds = _bounds[type];
    if (bounds != null) {
      final max = bounds.max;
      if (value is! int ||
          value < bounds.min ||
          (max != null && value > max)) {
        throw FormatException(
          '$type : value vaut un entier '
          '${max == null ? "d'au moins ${bounds.min}" : 'de ${bounds.min} à $max'}'
          ' — reçu : $value',
        );
      }
    }
    return EventAction(type: type, value: value);
  }
}
```

Le commentaire `// gain_gold, take_damage, heal, gain_relic` du champ `type` (`:119`), que la tâche rend faux (spec §8, « Et les commentaires »), devient un renvoi à la table qui fait foi.

In `lib/models/event_state.dart`, replace the whole file with:

```dart
import 'data/event_data.dart';
import 'data/relic_data.dart';

class EventState {
  final EventData? activeEvent;
  final EventChoice? selectedChoice;
  final bool isResolved;

  /// La relique que vise l'échange de l'événement (spec P-43 E3, §4.9, A20) :
  /// tirée une fois, à l'ouverture, nommée sur les badges ; `null` si
  /// l'événement n'échange rien ou que l'inventaire est vide.
  final RelicData? tradedRelic;

  const EventState({
    this.activeEvent,
    this.selectedChoice,
    this.isResolved = false,
    this.tradedRelic,
  });

  EventState copyWith({
    EventData? activeEvent,
    EventChoice? selectedChoice,
    bool? isResolved,
    bool clearSelectedChoice = false,
  }) {
    return EventState(
      activeEvent: activeEvent ?? this.activeEvent,
      selectedChoice: clearSelectedChoice
          ? null
          : (selectedChoice ?? this.selectedChoice),
      isResolved: isResolved ?? this.isResolved,
      tradedRelic: tradedRelic,
    );
  }
}
```

- [ ] **Step 6: Le contrôleur et `loseRelic`**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  void exchangeRelics(List<RelicData> sacrificed, RelicData gained) {
    _playerStatsManager.exchangeRelics(sacrificed, gained);
  }
```

with:

```dart
  void exchangeRelics(List<RelicData> sacrificed, RelicData gained) {
    _playerStatsManager.exchangeRelics(sacrificed, gained);
  }

  /// Cède une relique de l'inventaire (spec P-43 E3, §4.9 ; D23) : sa règle
  /// de run défaite, puis la relique retirée — la symétrie de l'Autel.
  void loseRelic(RelicData relic) {
    removeRelicEffect(relic);
    ref.read(inventoryProvider.notifier).removeRelics([relic.id]);
  }
```

In `lib/game/controllers/event_controller.dart`, replace:

```dart
    final random = Random();
    final chosen = events[random.nextInt(events.length)];
    state = EventState(
      activeEvent: chosen,
      selectedChoice: null,
      isResolved: false,
    );
  }

  /// Initialise un événement spécifique (utile pour les tests unitaires)
  void setEvent(EventData event) {
    state = EventState(
      activeEvent: event,
      selectedChoice: null,
      isResolved: false,
    );
  }
```

with:

```dart
    final random = Random();
    final chosen = events[random.nextInt(events.length)];
    state = EventState(
      activeEvent: chosen,
      selectedChoice: null,
      isResolved: false,
      tradedRelic: _drawTradedRelic(chosen),
    );
  }

  /// Initialise un événement spécifique (utile pour les tests unitaires)
  void setEvent(EventData event) {
    state = EventState(
      activeEvent: event,
      selectedChoice: null,
      isResolved: false,
      tradedRelic: _drawTradedRelic(event),
    );
  }

  /// La relique que vise l'échange (spec P-43 E3, §4.9, A20) : tirée une
  /// fois, à l'ouverture, parmi celles de plus petite rareté — au hasard
  /// parmi les ex æquo, les reliques d'E3 comprises, comme à l'Autel —, si
  /// l'événement porte une action `trade_relic` et que l'inventaire n'est
  /// pas vide ; `null` sinon.
  RelicData? _drawTradedRelic(EventData event) {
    final trades = event.choices.any(
        (choice) => choice.actions.any((a) => a.type == 'trade_relic'));
    final relics = ref.read(inventoryProvider).relics;
    if (!trades || relics.isEmpty) return null;
    final lowest = relics.map((r) => r.rarity.index).reduce(min);
    final weakest = [
      for (final r in relics)
        if (r.rarity.index == lowest) r,
    ];
    return weakest[Random().nextInt(weakest.length)];
  }

  /// Ce choix peut-il être pris ? (spec P-43 E3, §4.9 ; C4.4) Le seul
  /// calcul des faits que reçoit `EventChoice.isSelectable` — les PV et l'or
  /// lus sur la run et l'inventaire, `hasTradedRelic` sur la relique visée.
  /// L'écran l'appelle pour chaque bouton de choix.
  bool isChoiceSelectable(EventChoice choice) {
    final hero = ref.read(runProvider).heroStats;
    return choice.isSelectable(
      hero.currentPv,
      ref.read(inventoryProvider).gold,
      hero.maxPv,
      hasTradedRelic: state.tradedRelic != null,
    );
  }
```

Then replace:

```dart
        case 'gain_might':
          runController.applyHeroStatModifier(mightAcc: action.value as int);
          break;
```

with:

```dart
        case 'gain_might':
          runController.applyHeroStatModifier(mightAcc: action.value as int);
          break;
        // La relique visée à l'ouverture (A20) quitte l'inventaire, sa règle
        // de run défaite, contre `value` or par rang de rareté.
        case 'trade_relic':
          final relic = state.tradedRelic;
          if (relic != null) {
            runController.loseRelic(relic);
            inventoryController.gainGold(action.tradeGoldFor(relic.rarity));
          }
          break;
        case 'heal_percent':
          runController.heal(action
              .hpPercentOf(runController.currentState.heroStats.maxPv));
          break;
```

`selectChoice` passe l'état par `state.copyWith(selectedChoice: choice, isResolved: true)` avant la boucle : `tradedRelic` y survit (Step 5). `min` vient de `dart:math`, déjà importé.

- [ ] **Step 7: Les clés ARB**

In `lib/l10n/app_en.arb`, replace:

```json
  "eventGainRelic": "+1 Relic",
```

with:

```json
  "eventGainRelic": "+1 Relic",
  "eventTradeRelic": "Give up {relic}: +{amount} Gold",
  "@eventTradeRelic": {
    "placeholders": {
      "relic": { "type": "String" },
      "amount": { "type": "int" }
    }
  },
  "eventGiveRelic": "Give up {relic}",
  "@eventGiveRelic": {
    "placeholders": {
      "relic": { "type": "String" }
    }
  },
  "eventNoRelicToGive": "No relic to give up",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "eventGainRelic": "+1 Relique",
```

with:

```json
  "eventGainRelic": "+1 Relique",
  "eventTradeRelic": "Cède {relic} : +{amount} Or",
  "eventGiveRelic": "Cède {relic}",
  "eventNoRelicToGive": "Aucune relique à céder",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés.

- [ ] **Step 8: L'écran**

In `lib/ui/screens/event_screen.dart`, replace:

```dart
  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }
```

with:

```dart
  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  /// Le badge d'une action `trade_relic` (spec P-43 E3, §4.9, §5.1) : la
  /// relique visée et son prix, ou qu'il n'y a rien à céder.
  String _tradeRelicText(AppLocalizations l10n, EventAction action) {
    final relic = ref.read(eventProvider).tradedRelic;
    if (relic == null) return l10n.eventNoRelicToGive;
    final name = relic.getName(Localizations.localeOf(context).languageCode);
    final gold = action.tradeGoldFor(relic.rarity);
    return gold > 0
        ? l10n.eventTradeRelic(name, gold)
        : l10n.eventGiveRelic(name);
  }

  /// Le montant d'une action en pourcentage des PV max du héros.
  int _hpPercent(EventAction action) =>
      action.hpPercentOf(ref.read(runProvider).heroStats.maxPv);
```

Then, in `_buildActionBadge`, replace:

```dart
        bgColor = Colors.purple.withValues(alpha: 0.12);
        text = l10n.eventGainRelic;
        break;
```

with:

```dart
        bgColor = Colors.purple.withValues(alpha: 0.12);
        text = l10n.eventGainRelic;
        break;
      case 'trade_relic':
        icon = Icons.swap_horiz;
        iconColor = Colors.amber;
        textColor = Colors.amberAccent;
        bgColor = Colors.amber.withValues(alpha: 0.12);
        text = _tradeRelicText(l10n, action);
        break;
      case 'heal_percent':
        icon = Icons.favorite;
        iconColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.12);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
```

Then, in `_buildCompactActionBadge`, replace:

```dart
        bgColor = Colors.purple.withValues(alpha: 0.08);
        text = l10n.eventGainRelic;
        break;
```

with:

```dart
        bgColor = Colors.purple.withValues(alpha: 0.08);
        text = l10n.eventGainRelic;
        break;
      case 'trade_relic':
        icon = Icons.swap_horiz;
        iconColor = Colors.amber;
        textColor = Colors.amberAccent;
        bgColor = Colors.amber.withValues(alpha: 0.08);
        text = _tradeRelicText(l10n, action);
        break;
      case 'heal_percent':
        icon = Icons.favorite;
        iconColor = Colors.greenAccent;
        textColor = Colors.greenAccent;
        bgColor = Colors.green.withValues(alpha: 0.08);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
```

Then replace:

```dart
    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      canPop: eventState.isResolved,
```

with:

```dart
    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      // Le retour système n'est jamais un pop direct (spec P-43 E3, §4.9,
      // A22) : avant tout choix il reste bloqué ; après, il résout le nœud par
      // le chemin de « Continuer », comme au feu et au Puits — sans quoi la
      // carte laisserait rentrer dans le nœud et tirer un second événement.
      // Le pop de `_leave` repasse ici avec `didPop` vrai : rien à refaire.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && eventState.isResolved) _leave();
      },
```

Then replace:

```dart
                  final isSelectable = choice.isSelectable(currentPv, gold, maxPv);
```

with:

```dart
                  // Les faits de la condition, calculés par le contrôleur
                  // (spec P-43 E3, §4.9 ; C4.4).
                  final isSelectable = ref
                      .read(eventProvider.notifier)
                      .isChoiceSelectable(choice);
```

L'écran regarde déjà l'événement, la run et l'inventaire (`:306`, `:314-315`) : le bouton suit chacune des entrées. `currentPv`, `maxPv` et `gold` restent lus par la barre de statistiques.

- [ ] **Step 9: Les comptes de la donnée livrée**

In `test/unit/real_bundle_load_test.dart`, replace `  test('le manifeste declare les 91 fichiers d entite, par categorie', () async {` with `  test('le manifeste declare les 92 fichiers d entite, par categorie', () async {`, replace `    expect(countUnder('assets/data/events/', 4), 5, reason: 'evenements');` with `    expect(countUnder('assets/data/events/', 4), 6, reason: 'evenements');`, and replace `    expect(registry.events, hasLength(5));` with `    expect(registry.events, hasLength(6));`.

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 91 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 5 evenements + 11
    // ameliorations de forge + 9 passifs + 8 recompenses de niveau + 3
    // class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 91,
        reason: '17 cartes neutres + 28 reliques + 5 evenements + 11 '
```

with:

```dart
  test('il y a bien 92 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 6 evenements (dont le
    // Colporteur) + 11 ameliorations de forge + 9 passifs + 8 recompenses de
    // niveau + 3 class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 92,
        reason: '17 cartes neutres + 28 reliques + 6 evenements + 11 '
```

- [ ] **Step 10: Les tests passent**

Run: `flutter test test/unit/event_controller_test.dart test/widget/event_screen_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: PASS — `relic_peddler.json` se réécrit à l'identique : ses deux types d'action et `requiresHpBelowPercent` passent par `EventChoice.fromJson` et `EventAction.fromJson`, que la famille 7 du validateur appelle (spec §6).

- [ ] **Step 11: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1563: All tests passed!` (1548 + 10 + 5)

- [ ] **Step 12: Commit**

```bash
git add assets/data/events/relic_peddler.json lib/models/data/event_data.dart lib/models/event_state.dart lib/game/controllers/event_controller.dart lib/game/controllers/run_controller.dart lib/ui/screens/event_screen.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/unit/event_controller_test.dart test/widget/event_screen_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart
git commit -F - <<'EOF'
feat(evenements): le Colporteur echange la relique la plus faible

Un evenement neuf cede la relique de plus petite rarete, visee a l
ouverture, contre 40 or par rang, ou sous la moitie des PV contre 20 pour
cent des PV max. Les badges la nomment ; sans relique, les echanges sont
inactifs et le disent. Le controleur calcule les faits de la condition
de choix. Apres un choix, le retour systeme resout le noeud : on ne
rejoue plus un evenement dans le meme noeud.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 5: Le *Rémouleur* — l'affûtage contre des PV, la sélection sans or

D42(b), A4, A19, A21 (spec §3.4, §4.7, §4.9, §5.1) : un événement neuf, `events/wandering_grinder.json`, monte d'un niveau une rune que le joueur choisit, contre 10 % des PV max. Deux actions (`lose_hp_percent`, `sharpen_rune`) ; `isSelectable` reçoit le second fait calculé, `hasSharpenableRune`, que `EventController.isChoiceSelectable` tire du deck et du catalogue des runes, comme l'option du feu. Le joueur choisit la carte puis la rune dans la sélection du feu, **sans or** : `RestCardSelectionScreen` et `SharpenRuneDialog` gagnent un mode `isFree` — le bouton dit « Choisir » (`fusionRuneChoose`), sans coût ni condition d'or, et le dialogue n'écrit rien : il rend la rune, la sélection rend la paire, et `selectChoice` résout le choix — la perte de PV, puis `DeckNotifier.raiseRuneLevel(…, levels: value)`. Annuler n'engage rien. L'écran du feu garde son comportement.

**Files:**
- Create: `assets/data/events/wandering_grinder.json`
- Modify: `lib/models/data/event_data.dart` (`isSelectable`, `hpPercentOf`, `_bounds` — écrits en Task 4)
- Modify: `lib/game/controllers/event_controller.dart:1-7` (imports), `isChoiceSelectable` (Task 4), `:44-52` (`selectChoice`) et ses cas
- Modify: `lib/game/controllers/deck_controller.dart` (`raiseRuneLevel`, Task 1)
- Modify: `lib/game/services/forge_rune_rules.dart:147-149` (la documentation de `hasSharpenableRune`)
- Modify: `lib/ui/screens/event_screen.dart:1-13` (imports), `:32-68` (`_handleChoice`), les deux `switch` de badges, `:306` et l'appel d'`isChoiceSelectable` (Task 4)
- Modify: `lib/ui/screens/rest_card_selection_screen.dart:16-33`, `:52-55`
- Modify: `lib/ui/widgets/forge/sharpen_rune_dialog.dart:15-56`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb` (`eventSharpenRune`) ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Test: `test/unit/event_controller_test.dart` (le groupe « le Colporteur » de la Task 4, un groupe neuf), `test/widget/event_screen_test.dart` (Task 4), `test/widget/rest_card_selection_screen_test.dart:17-57`, `test/widget/sharpen_rune_dialog_test.dart:24-69`, `test/unit/deck_controller_test.dart` (le groupe de la Task 1)
- Test: `test/unit/real_bundle_load_test.dart` (comptes), `test/unit/entity_id_convention_test.dart`

**Interfaces:**
- Consumes: `EventChoice.isSelectable`, `EventController.isChoiceSelectable`, `EventAction.hpPercentOf` (Task 4) ; `ForgeRuneRules.hasSharpenableRune(CardInstance, Iterable<ForgeUpgradeData>)`.
- Produces:
  - `bool EventChoice.isSelectable(int currentHp, int currentGold, int currentMaxHp, {required bool hasTradedRelic, required bool hasSharpenableRune})` — sa forme finale (spec §3.8) ;
  - `bool EventController.isChoiceSelectable(EventChoice choice, Iterable<ForgeUpgradeData> runeCatalog)` — sa forme finale (C4.4) ;
  - `RelicData? EventController.selectChoice(EventChoice choice, List<RelicData> allRelics, {double? mockRoll, int? mockRelicIndex, ({String cardId, String runeId})? sharpenTarget})` ;
  - `bool DeckNotifier.raiseRuneLevel(String cardId, String runeId, {int levels = 1})` ;
  - `RestCardSelectionScreen({…, bool isFree = false})`, `SharpenRuneDialog({…, bool isFree = false})` ;
  - la clé ARB `eventSharpenRune` (`{amount}`).

- [ ] **Step 1: Les tests du contrôleur**

In `test/unit/event_controller_test.dart`, in the group `le Colporteur` (Task 4), replace each of the two `events.isChoiceSelectable(sale())` with `events.isChoiceSelectable(sale(), const [])`, each of the two `events.isChoiceSelectable(offering)` with `events.isChoiceSelectable(offering, const [])`, each of the three `hasTradedRelic: false)` with `hasTradedRelic: false, hasSharpenableRune: false)`, and the one `hasTradedRelic: true)` with `hasTradedRelic: true, hasSharpenableRune: false)` — des cas réécrits : ils gardent ce qu'ils gardaient.

Then add the imports — replace:

```dart
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
```

with:

```dart
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
```

and replace:

```dart
import 'package:roguelike_card_game/models/data/event_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

Then replace the end of the file:

```dart
      expect(remedies().requiresHpBelowPercent, 50);
      expect(peddler.choices[2].actions, isEmpty);
    });
  });
}
```

with:

```dart
      expect(remedies().requiresHpBelowPercent, 50);
      expect(peddler.choices[2].actions, isEmpty);
    });
  });

  // Le Rémouleur (spec P-43 E3, §3.4, §4.9 ; D42(b), A4, A19, A21).
  group('le Remouleur', () {
    late ProviderContainer container;
    late EventController events;
    late RunController run;
    late InventoryController inventory;
    late List<ForgeUpgradeData> runes;
    late EventData grinder;

    const paladin = HeroData(
      id: 'paladin',
      classCard: 'paladin.png',
      maxHp: 100,
      maxMana: 3,
    );

    setUpAll(() async {
      grinder = (await loadGameDataRegistry(rootBundle))
          .events
          .singleWhere((e) => e.id == 'wandering_grinder');
    });

    setUp(() {
      // Les runes livrées, que `raiseRuneLevel` lit dans le registre.
      runes = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      container = ProviderContainer();
      addTearDown(container.dispose);
      events = container.read(eventProvider.notifier);
      run = container.read(runProvider.notifier);
      inventory = container.read(inventoryProvider.notifier);
      run.startNewRun(paladin);
      events.setEvent(grinder);
    });

    EventChoice hand() => grinder.choices[0];

    /// Une Frappe rare portant [carried], posée dans le deck.
    CardInstance seedRare(List<String> carried) {
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: carried,
      );
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
      return card;
    }

    List<String> runesOf(CardInstance card) => container
        .read(deckProvider)
        .masterDeck
        .singleWhere((c) => c.uniqueId == card.uniqueId)
        .forgeUpgrades;

    test('confier une rune perd 10 % des PV max, arrondis, et monte la paire '
        'choisie, sans or', () {
      // 87 PV max : 10 % font 8,7, arrondis à 9 (`.round()`).
      run.applyHeroStatModifier(maxPvAcc: -13);
      final card = seedRare(const ['sharp:1']);
      final goldBefore = inventory.state.gold;

      events.selectChoice(
        hand(),
        const [],
        sharpenTarget: (cardId: card.uniqueId, runeId: 'sharp'),
      );

      expect(run.currentState.heroStats.currentPv, 87 - 9);
      expect(runesOf(card), ['sharp:2']);
      expect(inventory.state.gold, goldBefore);
    });

    test('isChoiceSelectable : le Remouleur suit les runes du deck qui '
        'peuvent monter', () {
      seedRare(const ['eco:1']);
      expect(events.isChoiceSelectable(hand(), runes), isFalse);

      seedRare(const ['sharp:1']);
      expect(events.isChoiceSelectable(hand(), runes), isTrue);
    });

    test('isSelectable : sharpen_rune suit hasSharpenableRune ; '
        'lose_hp_percent refuse des PV au plus egaux a son cout', () {
      expect(
        hand().isSelectable(100, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: false),
        isFalse,
      );
      expect(
        hand().isSelectable(100, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isTrue,
      );
      // 10 % de 100 PV max : à 10 PV le choix tuerait, à 11 non.
      expect(
        hand().isSelectable(10, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isFalse,
      );
      expect(
        hand().isSelectable(11, 0, 100,
            hasTradedRelic: false, hasSharpenableRune: true),
        isTrue,
      );
    });

    test('les valeurs de lose_hp_percent et sharpen_rune sont bornees au '
        'chargement', () {
      for (final (type, bad) in <(String, Object)>[
        ('lose_hp_percent', 0),
        ('lose_hp_percent', 101),
        ('sharpen_rune', 0),
        ('sharpen_rune', '1'),
      ]) {
        expect(
          () => EventAction.fromJson({'type': type, 'value': bad}),
          throwsFormatException,
          reason: '$type $bad',
        );
      }
      expect(
          EventAction.fromJson({'type': 'lose_hp_percent', 'value': 100})
              .value,
          100);
      expect(EventAction.fromJson({'type': 'sharpen_rune', 'value': 1}).value,
          1);
    });

    test('le Remouleur livre : ses actions', () {
      expect(grinder.choices, hasLength(2));
      expect(
        [for (final a in hand().actions) (a.type, a.value)],
        [('lose_hp_percent', 10), ('sharpen_rune', 1)],
      );
      expect(grinder.choices[1].actions, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Les tests de l'écran, de la sélection et du dialogue**

In `test/widget/event_screen_test.dart` (Task 4), replace:

```dart
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/event_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/event_data.dart';
```

Then replace:

```dart
import 'package:roguelike_card_game/ui/screens/event_screen.dart';
```

with:

```dart
import 'package:roguelike_card_game/ui/screens/event_screen.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
```

Then replace:

```dart
  const leave = 'Passer votre chemin (Rien)';
```

with:

```dart
  const leave = 'Passer votre chemin (Rien)';
  const handRune = 'Lui confier une rune (-10 % des PV max, +1 niveau de rune)';
```

Then replace:

```dart
  /// premier pump serait écrasé. [prepare] agit avant l'ouverture —
  /// l'échange vise sa relique à l'ouverture (A20).
  Future<ProviderContainer> startRun(
    WidgetTester tester,
    EventData event, {
    void Function(ProviderContainer container)? prepare,
  }) async {
```

with:

```dart
  /// premier pump serait écrasé. Le deck reçoit [deck] ; [prepare] agit
  /// avant l'ouverture — l'échange vise sa relique à l'ouverture (A20).
  Future<ProviderContainer> startRun(
    WidgetTester tester,
    EventData event, {
    List<CardInstance> deck = const [],
    void Function(ProviderContainer container)? prepare,
  }) async {
```

Then replace:

```dart
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    prepare?.call(container);
    return container;
  }
```

with:

```dart
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    for (final card in deck) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    prepare?.call(container);
    return container;
  }
```

Then replace:

```dart
  Future<ProviderContainer> pumpEvent(
    WidgetTester tester,
    EventData event, {
    void Function(ProviderContainer container)? prepare,
  }) async {
    final container = await startRun(tester, event, prepare: prepare);
```

with:

```dart
  Future<ProviderContainer> pumpEvent(
    WidgetTester tester,
    EventData event, {
    List<CardInstance> deck = const [],
    void Function(ProviderContainer container)? prepare,
  }) async {
    final container =
        await startRun(tester, event, deck: deck, prepare: prepare);
```

Then replace the end of the file:

```dart
      container.read(runProvider.notifier).takeDamage(60);
      await tester.pump();

      expect(enabled(tester, remedies), isTrue);
    });
  });
}
```

with:

```dart
      container.read(runProvider.notifier).takeDamage(60);
      await tester.pump();

      expect(enabled(tester, remedies), isTrue);
    });
  });

  group('le Remouleur', () {
    /// Une Frappe rare portant Tranchant 1 : la rune peut monter.
    CardInstance sharpStrike() => CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['sharp:1'],
        );

    testWidgets('inactif sur un deck sans rune affutable, ses badges disent '
        'le prix et le gain', (tester) async {
      await pumpEvent(
        tester,
        eventOf('wandering_grinder'),
        deck: [CardInstance(data: shippedCard('defend_basic'))],
      );

      expect(enabled(tester, handRune), isFalse);
      expect(enabled(tester, leave), isTrue);
      expect(find.text('-10 PV'), findsOneWidget);
      expect(find.text('+1 niveau de rune'), findsOneWidget);
    });

    testWidgets('il affute la rune choisie, sans or, contre 10 % des PV max',
        (tester) async {
      final container = await pumpEvent(
        tester,
        eventOf('wandering_grinder'),
        deck: [sharpStrike(), CardInstance(data: shippedCard('defend_basic'))],
      );
      final goldBefore = container.read(inventoryProvider).gold;

      await tester.tap(find.text(handRune));
      await tester.pumpAndSettle();

      // La sélection du feu, sans or : la carte sans rune est grisée.
      final cards = find.byType(UiCard);
      expect(cards, findsNWidgets(2));
      expect(tester.widget<UiCard>(cards.at(1)).isGrayedOut, isTrue);

      await tester.tap(cards.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir'));
      await tester.pumpAndSettle();

      expect(find.byType(RestCardSelectionScreen), findsNothing);
      expect(container.read(deckProvider).masterDeck.first.forgeUpgrades,
          ['sharp:2']);
      expect(container.read(runProvider).heroStats.currentPv, 90);
      expect(container.read(inventoryProvider).gold, goldBefore);
      expect(find.text('CONTINUER'), findsOneWidget);
    });

    testWidgets('annuler la selection ne resout rien, ne coute rien',
        (tester) async {
      final container = await pumpEvent(
        tester,
        eventOf('wandering_grinder'),
        deck: [sharpStrike()],
      );

      await tester.tap(find.text(handRune));
      await tester.pumpAndSettle();
      expect(find.byType(RestCardSelectionScreen), findsOneWidget);

      await pressBack(tester);

      expect(find.byType(RestCardSelectionScreen), findsNothing);
      expect(container.read(runProvider).heroStats.currentPv, 100);
      expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
          ['sharp:1']);
      expect(container.read(eventProvider).isResolved, isFalse);
      expect(enabled(tester, handRune), isTrue);
    });
  });
}
```

In `test/widget/rest_card_selection_screen_test.dart`, replace:

```dart
/// Monte la sélection de l'affûtage sur un deck d'une seule [card], avec les
/// huit runes livrées.
Future<ProviderContainer> _pumpSharpenSelection(
  WidgetTester tester,
  CardInstance card,
) async {
```

with:

```dart
/// Monte la sélection de l'affûtage sur un deck d'une seule [card], avec les
/// runes livrées ; [isFree] : le mode sans or du *Rémouleur*.
Future<ProviderContainer> _pumpSharpenSelection(
  WidgetTester tester,
  CardInstance card, {
  bool isFree = false,
}) async {
```

Then replace:

```dart
        home: const RestCardSelectionScreen(
          title: 'AFFÛTER UNE RUNE',
          subtitle: 'Choisissez une carte, puis la rune qui gagne un niveau.',
          isSharpen: true,
        ),
```

with:

```dart
        home: RestCardSelectionScreen(
          title: 'AFFÛTER UNE RUNE',
          subtitle: 'Choisissez une carte, puis la rune qui gagne un niveau.',
          isSharpen: true,
          isFree: isFree,
        ),
```

Then replace the end of the file:

```dart
    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(container.read(notificationProvider), isEmpty);

    await _settleNotifications(tester);
  });
}
```

with:

```dart
    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(container.read(notificationProvider), isEmpty);

    await _settleNotifications(tester);
  });

  // Le Rémouleur (spec P-43 E3, §4.9, A21) : la sélection du feu, sans or.
  testWidgets('sans or, la carte ouvre le dialogue qui dit Choisir',
      (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['sharp:1'],
    );
    await _pumpSharpenSelection(tester, card, isFree: true);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(find.text('Choisir'), findsOneWidget);
    expect(find.textContaining('Affûter —'), findsNothing);
  });
}
```

In `test/widget/sharpen_rune_dialog_test.dart`, replace:

```dart
/// Ouvre le dialogue d'affûtage sur [card], posée dans le deck, avec [gold]
/// or, par `showDialog` au-dessus d'une page — comme la sélection du feu ;
/// [onClosed] reçoit ce sur quoi il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card, {
  required int gold,
  ValueChanged<String?>? onClosed,
}) async {
```

with:

```dart
/// Ouvre le dialogue d'affûtage sur [card], posée dans le deck, avec [gold]
/// or, par `showDialog` au-dessus d'une page — comme la sélection du feu ;
/// [isFree] : le mode sans or du *Rémouleur* ; [onClosed] reçoit ce sur quoi
/// il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card, {
  required int gold,
  bool isFree = false,
  ValueChanged<String?>? onClosed,
}) async {
```

Then replace `                  builder: (_) => SharpenRuneDialog(card: card),` with `                  builder: (_) => SharpenRuneDialog(card: card, isFree: isFree),`.

Then replace the end of the file:

```dart
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 900);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:3', 'eco:1']);
  });
}
```

with:

```dart
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 900);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:3', 'eco:1']);
  });

  // Le Rémouleur (spec P-43 E3, §4.9, A21) : choisir, sans payer ni écrire.
  testWidgets('sans or, Choisir rend la rune sans rien ecrire ni payer',
      (tester) async {
    String? closedOn;
    final container = await _openDialog(
      tester,
      _rareStrike(const ['sharp:2', 'eco:1']),
      gold: 0,
      isFree: true,
      onClosed: (id) => closedOn = id,
    );

    expect(find.text('Niveau 2 → 3'), findsOneWidget);
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 0);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:2', 'eco:1']);
  });

  testWidgets('sans or, une rune a son plafond dit Niveau maximal, inactive',
      (tester) async {
    await _openDialog(tester, _rareStrike(const ['eco:1']),
        gold: 0, isFree: true);

    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.text('Choisir'), findsNothing);
  });
}
```

In `test/unit/deck_controller_test.dart`, in the group `DeckNotifier.raiseRuneLevel` (Task 1), replace:

```dart
      expect(runesOf(card), ['sharp:2', 'legacy:1']);
    });
  });
}
```

with:

```dart
      expect(runesOf(card), ['sharp:2', 'legacy:1']);
    });

    // Le Rémouleur monte de `value` niveaux (spec P-43 E3, §4.9).
    test('monte de levels niveaux, bornes par le plafond de la rune', () {
      shippedRuneRegistry(const ['precise']);
      final low = seed(const ['precise:1']);
      final high = seed(const ['precise:9']);

      expect(notifier.raiseRuneLevel(low.uniqueId, 'precise', levels: 2),
          isTrue);
      expect(notifier.raiseRuneLevel(high.uniqueId, 'precise', levels: 3),
          isTrue);

      // Précis plafonne à 10 (D72).
      expect(runesOf(low), ['precise:3']);
      expect(runesOf(high), ['precise:10']);
    });
  });
}
```

- [ ] **Step 3: Les lancer pour les voir échouer**

Run: `flutter test test/unit/event_controller_test.dart test/widget/event_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/unit/deck_controller_test.dart`
Expected: FAIL à la compilation — `hasSharpenableRune`, `sharpenTarget`, `levels`, `isFree` n'existent pas.

- [ ] **Step 4: L'événement**

Create `assets/data/events/wandering_grinder.json` (l'`id` déclaré, spec §3.3) :

```json
{
  "id": "wandering_grinder",
  "title_en": "The Knife-Grinder",
  "title_fr": "Le Rémouleur",
  "description_en": "A knife-grinder turns his wheel by the roadside. He sharpens anything — but takes his fee in blood.",
  "description_fr": "Un rémouleur fait tourner sa meule au bord du chemin. Il affûte tout — mais se paie en sang.",
  "choices": [
    {
      "text_en": "Hand him a rune (-10% max HP, +1 rune level)",
      "text_fr": "Lui confier une rune (-10 % des PV max, +1 niveau de rune)",
      "result_text_en": "The wheel sings, a drop of your blood beads on the stone — and the rune glows brighter.",
      "result_text_fr": "La meule chante, une goutte de votre sang perle sur la pierre — et la rune brille plus fort.",
      "actions": [
        {
          "type": "lose_hp_percent",
          "value": 10
        },
        {
          "type": "sharpen_rune",
          "value": 1
        }
      ]
    },
    {
      "text_en": "Move on (Nothing)",
      "text_fr": "Passer votre chemin (Rien)",
      "result_text_en": "You leave the knife-grinder to his wheel.",
      "result_text_fr": "Vous laissez le rémouleur à sa meule.",
      "actions": []
    }
  ]
}
```

- [ ] **Step 5: Le modèle**

In `lib/models/data/event_data.dart`, replace:

```dart
  /// Le choix peut-il être pris ? Les PV, l'or et les PV max, lus par
  /// l'appelant ; [hasTradedRelic], qu'une relique est visée par l'échange
  /// (A20) — un fait que le modèle reçoit calculé : ce fichier n'importe rien
  /// de `lib/game/` (spec P-43 E3, §4.9 ; C4.4, C4.5). Son appelant de jeu
  /// est `EventController.isChoiceSelectable`.
  bool isSelectable(
    int currentHp,
    int currentGold,
    int currentMaxHp, {
    required bool hasTradedRelic,
  }) {
```

with:

```dart
  /// Le choix peut-il être pris ? Les PV, l'or et les PV max, lus par
  /// l'appelant ; [hasTradedRelic], qu'une relique est visée par l'échange
  /// (A20), et [hasSharpenableRune], qu'une rune du deck peut encore monter
  /// — deux faits que le modèle reçoit calculés : ce fichier n'importe rien
  /// de `lib/game/` (spec P-43 E3, §4.9 ; C4.4, C4.5). Son appelant de jeu
  /// est `EventController.isChoiceSelectable`.
  bool isSelectable(
    int currentHp,
    int currentGold,
    int currentMaxHp, {
    required bool hasTradedRelic,
    required bool hasSharpenableRune,
  }) {
```

Then replace:

```dart
      } else if (action.type == 'trade_relic') {
        if (!hasTradedRelic) return false;
      }
```

with:

```dart
      } else if (action.type == 'trade_relic') {
        if (!hasTradedRelic) return false;
      } else if (action.type == 'lose_hp_percent') {
        // La règle de `take_damage` : le choix ne tue pas.
        if (currentHp <= action.hpPercentOf(currentMaxHp)) return false;
      } else if (action.type == 'sharpen_rune') {
        if (!hasSharpenableRune) return false;
      }
```

Then replace:

```dart
  /// Le montant d'une action en pourcentage des PV max — `heal_percent` —,
```

with:

```dart
  /// Le montant d'une action en pourcentage des PV max — `heal_percent`,
  /// `lose_hp_percent` —,
```

Then replace:

```dart
    'trade_relic': (min: 0, max: null),
    'heal_percent': (min: 1, max: 100),
  };
```

with:

```dart
    'trade_relic': (min: 0, max: null),
    'heal_percent': (min: 1, max: 100),
    'lose_hp_percent': (min: 1, max: 100),
    'sharpen_rune': (min: 1, max: null),
  };
```

- [ ] **Step 6: Le contrôleur, et `raiseRuneLevel` qui monte de `levels`**

In `lib/game/controllers/deck_controller.dart`, replace:

```dart
  /// Monte d'un niveau la rune [runeId] de la carte [cardId] du master deck,
  /// sans or (spec P-43 E3, §4.7, A13) : l'écriture que partagent le feu —
  /// `GoldManager.sharpenRune`, qui paie d'abord — et les sources d'E3. Le
  /// niveau est borné par le plafond de la rune (D72). Refuse — sans rien
  /// toucher — si la carte n'est pas dans le deck, ne porte pas la rune, si
  /// la rune est absente du registre, ou si son plafond ne la laisse pas
  /// monter ; sinon réécrit `id:n` en `id:n+1` à sa place. Rend vrai si la
  /// rune a monté.
  bool raiseRuneLevel(String cardId, String runeId) {
```

with:

```dart
  /// Monte de [levels] niveaux — un par défaut — la rune [runeId] de la
  /// carte [cardId] du master deck, sans or (spec P-43 E3, §4.7, A13) :
  /// l'écriture que partagent le feu — `GoldManager.sharpenRune`, qui paie
  /// d'abord — et les sources d'E3. Les niveaux montés sont bornés par le
  /// plafond de la rune (D72). Refuse — sans rien toucher — si la carte n'est
  /// pas dans le deck, ne porte pas la rune, si la rune est absente du
  /// registre, ou si son plafond ne la laisse pas monter ; sinon réécrit
  /// `id:n` en `id:n+k` à sa place, `k` le nombre borné. Rend vrai si la
  /// rune a monté.
  bool raiseRuneLevel(String cardId, String runeId, {int levels = 1}) {
```

Then replace `    final raised = rune.boundLevel(1, carried: level);` with `    final raised = rune.boundLevel(levels, carried: level);`.

In `lib/game/controllers/event_controller.dart`, replace:

```dart
import '../../models/data/relic_data.dart';
import 'run_controller.dart';
import 'inventory_controller.dart';
```

with:

```dart
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/relic_data.dart';
import '../services/forge_rune_rules.dart';
import 'deck_controller.dart';
import 'run_controller.dart';
import 'inventory_controller.dart';
```

Then replace:

```dart
  /// Ce choix peut-il être pris ? (spec P-43 E3, §4.9 ; C4.4) Le seul
  /// calcul des faits que reçoit `EventChoice.isSelectable` — les PV et l'or
  /// lus sur la run et l'inventaire, `hasTradedRelic` sur la relique visée.
  /// L'écran l'appelle pour chaque bouton de choix.
  bool isChoiceSelectable(EventChoice choice) {
    final hero = ref.read(runProvider).heroStats;
    return choice.isSelectable(
      hero.currentPv,
      ref.read(inventoryProvider).gold,
      hero.maxPv,
      hasTradedRelic: state.tradedRelic != null,
    );
  }
```

with:

```dart
  /// Ce choix peut-il être pris ? (spec P-43 E3, §4.9 ; C4.4) Le seul
  /// calcul des faits que reçoit `EventChoice.isSelectable` — les PV et l'or
  /// lus sur la run et l'inventaire, `hasTradedRelic` sur la relique visée,
  /// `hasSharpenableRune` sur le deck et [runeCatalog], comme l'option du feu
  /// (`rest_screen.dart`). L'écran l'appelle pour chaque bouton de choix,
  /// avec le catalogue des runes du registre.
  bool isChoiceSelectable(
    EventChoice choice,
    Iterable<ForgeUpgradeData> runeCatalog,
  ) {
    final hero = ref.read(runProvider).heroStats;
    return choice.isSelectable(
      hero.currentPv,
      ref.read(inventoryProvider).gold,
      hero.maxPv,
      hasTradedRelic: state.tradedRelic != null,
      hasSharpenableRune: ref.read(deckProvider).masterDeck.any(
          (card) => ForgeRuneRules.hasSharpenableRune(card, runeCatalog)),
    );
  }
```

Then replace:

```dart
  /// Gère la sélection et la résolution d'un choix d'événement
  ///
  /// Retourne la relique obtenue si le choix comprenait une action 'gain_relic', sinon null.
  RelicData? selectChoice(
    EventChoice choice,
    List<RelicData> allRelics, {
    double? mockRoll, // Permet d'injecter un jet de dé fixe pour les tests
    int? mockRelicIndex, // Permet d'injecter l'index de sélection de relique pour les tests
  }) {
```

with:

```dart
  /// Gère la sélection et la résolution d'un choix d'événement
  ///
  /// Retourne la relique obtenue si le choix comprenait une action 'gain_relic', sinon null.
  /// [sharpenTarget] : la carte et la rune qu'une action `sharpen_rune`
  /// monte — le joueur les a choisies dans la sélection sans or, avant
  /// l'appel (spec P-43 E3, §4.9, A21).
  RelicData? selectChoice(
    EventChoice choice,
    List<RelicData> allRelics, {
    double? mockRoll, // Permet d'injecter un jet de dé fixe pour les tests
    int? mockRelicIndex, // Permet d'injecter l'index de sélection de relique pour les tests
    ({String cardId, String runeId})? sharpenTarget,
  }) {
```

Then replace:

```dart
        case 'heal_percent':
          runController.heal(action
              .hpPercentOf(runController.currentState.heroStats.maxPv));
          break;
```

with:

```dart
        case 'heal_percent':
          runController.heal(action
              .hpPercentOf(runController.currentState.heroStats.maxPv));
          break;
        case 'lose_hp_percent':
          runController.takeDamage(action
              .hpPercentOf(runController.currentState.heroStats.maxPv));
          break;
        // La paire que le joueur a choisie (A21), montée sans or.
        case 'sharpen_rune':
          if (sharpenTarget != null) {
            ref.read(deckProvider.notifier).raiseRuneLevel(
                  sharpenTarget.cardId,
                  sharpenTarget.runeId,
                  levels: action.value as int,
                );
          }
          break;
```

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
  /// [card] porte-t-elle une rune que l'affûtage peut monter ? Une rune
  /// absente du [catalog] ne se monte pas. Lu par l'option du feu et par sa
  /// sélection (spec P-43 E2, A4).
```

with:

```dart
  /// [card] porte-t-elle une rune que l'affûtage peut monter ? Une rune
  /// absente du [catalog] ne se monte pas. Lu par l'option du feu, par sa
  /// sélection (spec P-43 E2, A4) et par la condition du *Rémouleur*,
  /// `EventController.isChoiceSelectable` (spec P-43 E3, §4.9).
```

- [ ] **Step 7: La sélection et le dialogue sans or**

In `lib/ui/screens/rest_card_selection_screen.dart`, replace:

```dart
/// La sélection d'une carte du deck, au feu de camp : pour en affûter une
/// rune, ou pour l'oublier.
class RestCardSelectionScreen extends ConsumerWidget {
  final String title;
  final String subtitle;

  /// Vrai pour l'affûtage (spec P-43 E2, A4, §4.7) : une carte sans rune
  /// affûtable est grisée et refusée au toucher, avec son motif ; une autre
  /// ouvre le dialogue d'affûtage, et l'écran se ferme sur la carte et la
  /// rune affûtée. Faux pour l'oubli : l'écran se ferme sur la carte touchée.
  final bool isSharpen;

  const RestCardSelectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSharpen,
  });
```

with:

```dart
/// La sélection d'une carte du deck : au feu de camp, pour en affûter une
/// rune ou pour l'oublier ; au *Rémouleur*, pour en affûter une sans or.
class RestCardSelectionScreen extends ConsumerWidget {
  final String title;
  final String subtitle;

  /// Vrai pour l'affûtage (spec P-43 E2, A4, §4.7) : une carte sans rune
  /// affûtable est grisée et refusée au toucher, avec son motif ; une autre
  /// ouvre le dialogue d'affûtage, et l'écran se ferme sur la carte et la
  /// rune choisie. Faux pour l'oubli : l'écran se ferme sur la carte touchée.
  final bool isSharpen;

  /// Vrai pour l'affûtage sans or du *Rémouleur* (spec P-43 E3, §4.9, A21) :
  /// le dialogue rend la rune choisie, sans coût ni condition d'or, et
  /// n'écrit rien — l'événement la monte. Faux au feu, qui paie. Sans effet
  /// hors de l'affûtage.
  final bool isFree;

  const RestCardSelectionScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isSharpen,
    this.isFree = false,
  });
```

Then replace `      builder: (context) => SharpenRuneDialog(card: card),` with `      builder: (context) => SharpenRuneDialog(card: card, isFree: isFree),`.

In `lib/ui/widgets/forge/sharpen_rune_dialog.dart`, replace:

```dart
/// affûtage par visite (D14). Annuler, ou la croix, le ferme sur `null` et
/// ramène à la sélection.
class SharpenRuneDialog extends ConsumerWidget {
  final CardInstance card;

  const SharpenRuneDialog({super.key, required this.card});
```

with:

```dart
/// affûtage par visite (D14). Annuler, ou la croix, le ferme sur `null` et
/// ramène à la sélection.
///
/// Sans or ([isFree] — le *Rémouleur*, spec P-43 E3, §4.9, A21) : le bouton
/// dit « Choisir », sans coût ni condition d'or, et n'écrit rien — il ferme
/// le dialogue sur l'id de la rune, que l'événement monte lui-même.
class SharpenRuneDialog extends ConsumerWidget {
  final CardInstance card;

  /// Vrai au *Rémouleur* : choisir, sans payer ni écrire.
  final bool isFree;

  const SharpenRuneDialog({
    super.key,
    required this.card,
    this.isFree = false,
  });
```

Then replace:

```dart
    Widget row(ForgeUpgradeData rune, int level) {
      final sharpenable = ForgeRuneRules.canSharpen(rune, level);
      final cost = ForgeRuneRules.sharpenCost(level);
      return ForgeSlotRow(
        rune: rune,
        title: rune.getName(locale),
        // Une rune au plafond n'a pas de niveau suivant : pas de ligne de
        // niveau, son bouton dit « Niveau maximal ».
        detail: sharpenable ? l10n.sharpenLevel(level, level + 1) : null,
        description: rune.getDescription(1, locale, card.data, card.rarity,
            carried: level),
        actionLabel:
            sharpenable ? l10n.sharpenAction(cost) : l10n.runeMaxLevel,
        onAction: sharpenable && gold >= cost
            ? () {
                if (ref
                    .read(runProvider.notifier)
                    .sharpenRune(card.uniqueId, rune.id)) {
                  Navigator.of(context).pop(rune.id);
                }
              }
            : null,
      );
    }
```

with:

```dart
    Widget row(ForgeUpgradeData rune, int level) {
      final sharpenable = ForgeRuneRules.canSharpen(rune, level);
      final cost = ForgeRuneRules.sharpenCost(level);
      final String actionLabel;
      final VoidCallback? onAction;
      if (!sharpenable) {
        actionLabel = l10n.runeMaxLevel;
        onAction = null;
      } else if (isFree) {
        actionLabel = l10n.fusionRuneChoose;
        onAction = () => Navigator.of(context).pop(rune.id);
      } else {
        actionLabel = l10n.sharpenAction(cost);
        onAction = gold >= cost
            ? () {
                if (ref
                    .read(runProvider.notifier)
                    .sharpenRune(card.uniqueId, rune.id)) {
                  Navigator.of(context).pop(rune.id);
                }
              }
            : null;
      }
      return ForgeSlotRow(
        rune: rune,
        title: rune.getName(locale),
        // Une rune au plafond n'a pas de niveau suivant : pas de ligne de
        // niveau, son bouton dit « Niveau maximal ».
        detail: sharpenable ? l10n.sharpenLevel(level, level + 1) : null,
        description: rune.getDescription(1, locale, card.data, card.rarity,
            carried: level),
        actionLabel: actionLabel,
        onAction: onAction,
      );
    }
```

- [ ] **Step 8: La clé ARB**

In `lib/l10n/app_en.arb`, replace:

```json
  "eventNoRelicToGive": "No relic to give up",
```

with:

```json
  "eventNoRelicToGive": "No relic to give up",
  "eventSharpenRune": "+{amount} rune level",
  "@eventSharpenRune": {
    "placeholders": {
      "amount": { "type": "int" }
    }
  },
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "eventNoRelicToGive": "Aucune relique à céder",
```

with:

```json
  "eventNoRelicToGive": "Aucune relique à céder",
  "eventSharpenRune": "+{amount} niveau de rune",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés.

- [ ] **Step 9: L'écran**

In `lib/ui/screens/event_screen.dart`, replace:

```dart
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/event_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/data/event_data.dart';
```

with:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/event_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/event_data.dart';
```

Then replace:

```dart
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';
```

with:

```dart
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';
import 'rest_card_selection_screen.dart';
```

Then replace:

```dart
  void _handleChoice(EventChoice choice) {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    final chosenRelic = ref
        .read(eventProvider.notifier)
        .selectChoice(
          choice,
          gameData.relics,
        );
```

with:

```dart
  /// La paire (carte, rune) que le joueur confie au *Rémouleur* (spec P-43
  /// E3, §4.9, A21) : la sélection du feu, sans or ; `null` s'il annule.
  Future<({String cardId, String runeId})?> _pickSharpenTarget() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await Navigator.of(context).push<(CardInstance, String)>(
      MaterialPageRoute(
        builder: (_) => RestCardSelectionScreen(
          title: l10n.restCampSharpenTitle,
          subtitle: l10n.restCampSharpenSubtitle,
          isSharpen: true,
          isFree: true,
        ),
      ),
    );
    if (picked == null) return null;
    final (card, runeId) = picked;
    return (cardId: card.uniqueId, runeId: runeId);
  }

  Future<void> _handleChoice(EventChoice choice) async {
    // Annuler la sélection n'engage rien : le choix n'est pas pris, les PV
    // ne sont pas payés (A21).
    final sharpens = choice.actions.any((a) => a.type == 'sharpen_rune');
    final sharpenTarget = sharpens ? await _pickSharpenTarget() : null;
    if (!mounted || (sharpens && sharpenTarget == null)) return;

    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    final chosenRelic = ref
        .read(eventProvider.notifier)
        .selectChoice(
          choice,
          gameData.relics,
          sharpenTarget: sharpenTarget,
        );
```

Then, in `_buildActionBadge`, replace:

```dart
        bgColor = Colors.green.withValues(alpha: 0.12);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
```

with:

```dart
        bgColor = Colors.green.withValues(alpha: 0.12);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
      case 'lose_hp_percent':
        icon = Icons.favorite_border;
        iconColor = Colors.redAccent;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.12);
        text = l10n.eventLoseHp(_hpPercent(action));
        break;
      case 'sharpen_rune':
        icon = Icons.auto_fix_high;
        iconColor = Colors.amberAccent;
        textColor = Colors.amberAccent;
        bgColor = Colors.amber.withValues(alpha: 0.12);
        text = l10n.eventSharpenRune(action.value as int);
        break;
```

Then, in `_buildCompactActionBadge`, replace:

```dart
        bgColor = Colors.green.withValues(alpha: 0.08);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
```

with:

```dart
        bgColor = Colors.green.withValues(alpha: 0.08);
        text = l10n.eventGainHp(_hpPercent(action));
        break;
      case 'lose_hp_percent':
        icon = Icons.favorite_border;
        iconColor = Colors.redAccent;
        textColor = Colors.redAccent;
        bgColor = Colors.red.withValues(alpha: 0.08);
        text = l10n.eventLoseHp(_hpPercent(action));
        break;
      case 'sharpen_rune':
        icon = Icons.auto_fix_high;
        iconColor = Colors.amberAccent;
        textColor = Colors.amberAccent;
        bgColor = Colors.amber.withValues(alpha: 0.08);
        text = l10n.eventSharpenRune(action.value as int);
        break;
```

Then replace:

```dart
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
```

with:

```dart
    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    // Le bouton du *Rémouleur* suit le deck (spec P-43 E3, §4.9).
    ref.watch(deckProvider);
    final runeCatalog =
        ref.read(gameDataLoaderProvider).requireValue.forgeUpgrades;
```

Then replace:

```dart
                  final isSelectable = ref
                      .read(eventProvider.notifier)
                      .isChoiceSelectable(choice);
```

with:

```dart
                  final isSelectable = ref
                      .read(eventProvider.notifier)
                      .isChoiceSelectable(choice, runeCatalog);
```

- [ ] **Step 10: Les comptes de la donnée livrée**

In `test/unit/real_bundle_load_test.dart`, replace `  test('le manifeste declare les 92 fichiers d entite, par categorie', () async {` with `  test('le manifeste declare les 93 fichiers d entite, par categorie', () async {`, replace `    expect(countUnder('assets/data/events/', 4), 6, reason: 'evenements');` with `    expect(countUnder('assets/data/events/', 4), 7, reason: 'evenements');`, and replace `    expect(registry.events, hasLength(6));` with `    expect(registry.events, hasLength(7));`.

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 92 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 6 evenements (dont le
    // Colporteur) + 11 ameliorations de forge + 9 passifs + 8 recompenses de
    // niveau + 3 class.json + 6 cartes de classe + 4 enemy.json.
    expect(_entityFiles().length, 92,
        reason: '17 cartes neutres + 28 reliques + 6 evenements + 11 '
```

with:

```dart
  test('il y a bien 93 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 7 evenements (dont le
    // Colporteur et le Remouleur) + 11 ameliorations de forge + 9 passifs +
    // 8 recompenses de niveau + 3 class.json + 6 cartes de classe + 4
    // enemy.json.
    expect(_entityFiles().length, 93,
        reason: '17 cartes neutres + 28 reliques + 7 evenements + 11 '
```

- [ ] **Step 11: Les tests passent**

Run: `flutter test test/unit/event_controller_test.dart test/widget/event_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/unit/deck_controller_test.dart test/widget/rest_screen_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: PASS — l'écran du feu (`rest_screen_test.dart`) garde son comportement.

- [ ] **Step 12: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n "isSelectable(" -- lib`
Expected: deux lignes — la déclaration (`lib/models/data/event_data.dart`) et l'appel d'`EventController.isChoiceSelectable` (`lib/game/controllers/event_controller.dart`) : l'écran passe par le contrôleur.

Run: `flutter test`
Expected: `+1575: All tests passed!` (1563 + 5 + 3 + 1 + 2 + 1)

- [ ] **Step 13: Commit**

```bash
git add assets/data/events/wandering_grinder.json lib/models/data/event_data.dart lib/game/controllers/event_controller.dart lib/game/controllers/deck_controller.dart lib/game/services/forge_rune_rules.dart lib/ui/screens/event_screen.dart lib/ui/screens/rest_card_selection_screen.dart lib/ui/widgets/forge/sharpen_rune_dialog.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/unit/event_controller_test.dart test/widget/event_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/unit/deck_controller_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart
git commit -F - <<'EOF'
feat(evenements): le Remouleur monte une rune contre des PV

Un evenement neuf monte d un niveau la rune que le joueur choisit, contre
10 pour cent des PV max. La selection et le dialogue du feu gagnent un
mode sans or : le bouton dit Choisir, rien ne se paie ni ne s ecrit avant
que l evenement resolve le choix. Annuler n engage rien. Le choix est
inactif sans rune qui puisse monter.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 6: *Sagesse* devient mythique, et la fiche des probabilités nomme ses mythiques depuis la donnée

D11, D62 (spec §3.5, §4.10, §5.1 ; propriétaire n° 7, C3.2, C4.2) : `wisdom.json` passe au pool `mythic`, `values: {"mythic": 1}` à la place de ses cinq paliers — le chargeur refuse une mythique de stat sans valeur `mythic` (`level_up_reward_data.dart:283-286`) ; son jet est le sien (`level_up_reward_service.dart:169-187`), sans code ; `PlayerStatsManager.applyLevelUpReward` l'applique comme avant, +1 `maxMana`. Les trois emplacements tirent désormais parmi cinq. La documentation d'`inPool` est réécrite (spec §3.8) : la parenthèse des « six tirables » est fausse, et ses lecteurs sont trois. La fiche des probabilités ne nomme plus ses mythiques en dur, « (Trèfle / Miroir) » (`probabilities_dialog.dart:167-168`) : elle les lit sur le chargeur, par `inPool`, et les passe à `luckLevelRewardSubtitle`. Son fichier de test surcharge alors le chargeur pour tous ses cas (C4.2), et gagne la rangée de plus que demande l'orchestrateur (compte rendu §2.3, S7).

*Transcendance*, la quatrième mythique, est la Task 7 : les attentes qui nomment les mythiques changent de nouveau là, pour la mythique que cette tâche-là ajoute.

**Files:**
- Modify: `assets/data/level_up_rewards/wisdom.json`
- Modify: `lib/models/data/level_up_reward_data.dart:170-181` (la documentation d'`inPool`)
- Modify: `lib/ui/widgets/map/dialogs/probabilities_dialog.dart:1-8` (imports), `:62-77` (`build`), `:166-168` (le sous-titre)
- Modify: `lib/l10n/app_en.arb:91-96`, `lib/l10n/app_fr.arb:46` ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Test: `test/widget/probabilities_dialog_test.dart` (tous ses cas, deux de plus)
- Test: `test/unit/level_up_rewards_catalog_test.dart:16-62`, `:64-101` ; `test/unit/level_up_reward_values_test.dart:48-57`, `:127-131`, `:173`, `:197-209`, `:256-261`, `:281` ; `test/unit/level_up_reward_apply_test.dart:86-95` ; `test/unit/level_up_reward_requirement_test.dart:62-77`
- Test: `test/tutorial/tutorial_prose_test.dart:14-27`, `:29-53`, `:63-74` ; `test/widget/draft_screen_test.dart:35-38`, `:45` (le helper `_largeView`, avant `_wrap`), `:182-183` (le cas « DraftScreen reveals mythic bonus choices… »), `:194-196`, `:212-221`, `:239-240` (le cas « Le Miroir de montee de niveau… », la vue large seule)

**Interfaces:**
- Consumes: `LevelUpRewardData.inPool(List<LevelUpRewardData>, RewardPool)` ; `gameDataLoaderProvider`.
- Produces: la clé ARB `luckLevelRewardSubtitle` (`{mythicNames}`, `String`). Le catalogue : cinq tirables, trois mythiques (`wisdom`, `lucky_clover`, `mirror`, par `displayOrder` 4, 7, 8). Dans `test/widget/draft_screen_test.dart`, le helper de fichier `void _largeView(WidgetTester tester)` (1600 × 900, remis à zéro par `addTearDown`), que la Task 7 réutilise.

- [ ] **Step 1: Les tests de la fiche**

In `test/widget/probabilities_dialog_test.dart`, replace:

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
```

with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/level_up_reward_data.dart';
import 'package:roguelike_card_game/models/reward_rarity.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/probabilities_dialog.dart';

/// La fiche des probabilités de la carte du monde (spec P-43 E3, §5.1, §8 ;
/// C4.1, C4.2, C4.7). Elle lit la run et le chargeur, qui lui donne ses
/// mythiques : chaque cas surcharge le chargeur et le résout avant le premier
/// pump — sans quoi le vrai chargeur se lancerait (« Le piège du montage »).
///
```

Then replace:

```dart
void main() {
  testWidgets('la section du draft standard a quitte la fiche, en francais',
      (tester) async {
```

with:

```dart
/// Un conteneur dont le chargeur est surchargé par [registry], et résolu.
Future<ProviderContainer> _containerOn(GameDataRegistry registry) async {
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  await container.read(gameDataLoaderProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry shipped;
  setUpAll(() async {
    shipped = await loadGameDataRegistry(rootBundle);
  });

  testWidgets('la section du draft standard a quitte la fiche, en francais',
      (tester) async {
```

Then replace each of the three occurrences of:

```dart
    final container = ProviderContainer();
    addTearDown(container.dispose);
```

with:

```dart
    final container = await _containerOn(shipped);
```

Then replace the end of the file:

```dart
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('7.0%'), findsOneWidget);
  });
}
```

with:

```dart
    expect(find.text('52.0%'), findsOneWidget);
    expect(find.text('7.0%'), findsOneWidget);
    // Une autre rareté, et l'ordre des rangées (S7) : la légendaire, à
    // Chance 0 puis à Chance 5, sur la première rangée, au-dessus de la
    // commune.
    expect(find.text('2.0%'), findsOneWidget);
    expect(find.text('4.5%'), findsOneWidget);
    expect(tester.getTopLeft(find.text('4.5%')).dy,
        lessThan(tester.getTopLeft(find.text('7.0%')).dy));
  });

  // La parenthèse des mythiques, lue sur la donnée (propriétaire n° 7, C3.2).
  testWidgets('la parenthese nomme les mythiques de la donnee, en francais et '
      'en anglais', (tester) async {
    final container = await _containerOn(shipped);

    await _openDialog(tester, container, const Locale('fr', ''));
    expect(
      find.text("Chances d'obtenir chaque rareté d'option lors de la montée "
          'de niveau (options mythiques, tirées à part : Sagesse / Trèfle à '
          '4 feuilles / Miroir)'),
      findsOneWidget,
    );

    // Un arbre neuf : la fiche ouverte en français reste sinon au-dessus.
    await tester.pumpWidget(const SizedBox());
    await _openDialog(tester, container, const Locale('en', ''));
    expect(
      find.text('Chances of getting each option rarity when leveling up '
          '(mythic options, rolled separately: Wisdom / 4-Leaf Clover / '
          'Mirror)'),
      findsOneWidget,
    );
  });

  testWidgets('sur un registre a une seule mythique, la parenthese ne nomme '
      'qu elle', (tester) async {
    const talisman = LevelUpRewardData(
      id: 'talisman',
      nameFr: 'Talisman',
      nameEn: 'Talisman',
      descriptionFr: '+{amount} Chance',
      descriptionEn: '+{amount} Luck',
      effect: RewardEffect.stat,
      stat: RewardStat.luck,
      pool: RewardPool.mythic,
      values: {RewardRarity.mythic: 1},
    );
    final container = await _containerOn(GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [],
      levelUpRewards: const [talisman],
    ));

    await _openDialog(tester, container, const Locale('fr', ''));

    expect(
      find.text("Chances d'obtenir chaque rareté d'option lors de la montée "
          'de niveau (options mythiques, tirées à part : Talisman)'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 2: Les tests du catalogue et de ses lecteurs**

In `test/unit/level_up_rewards_catalog_test.dart`, replace:

```dart
  /// La table d'aujourd'hui, à valeurs identiques (spec §8.1 : « à valeurs
  /// identiques »). Le plateau de Sagesse entre `uncommon` et `rare` est
  /// assumé et appartient à P-16 (§8.4).
```

with:

```dart
  /// La table des cinq récompenses tirables, à valeurs identiques (spec
  /// P-41, §8.1 : « à valeurs identiques »). *Sagesse* n'en est plus :
  /// mythique depuis D11, son plateau a disparu avec ses paliers (spec P-43
  /// E3, §3.5).
```

Then delete the `'wisdom'` entry of `attendu`:

```dart
    'wisdom': {
      RewardRarity.common: 1,
      RewardRarity.uncommon: 2,
      RewardRarity.rare: 2,
      RewardRarity.epic: 3,
      RewardRarity.legendary: 4,
    },
```

Then replace:

```dart
      {...attendu.keys, 'lucky_clover', 'mirror'},
```

with:

```dart
      {...attendu.keys, 'wisdom', 'lucky_clover', 'mirror'},
```

Then replace `  test('les six récompenses tirables portent la table d aujourd hui', () async {` with `  test('les cinq récompenses tirables portent la table d aujourd hui', () async {`.

Then replace:

```dart
  test('les deux mythiques sont hors du tirage des trois emplacements', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final mythiques = registry.levelUpRewards
        .where((r) => r.pool == RewardPool.mythic)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(mythiques.map((r) => r.id), ['lucky_clover', 'mirror']);
    expect(mythiques.first.amountFor(RewardRarity.mythic), 1);
    expect(mythiques.last.effect, RewardEffect.cloneCard);
  });
```

with:

```dart
  test('les trois mythiques sont hors du tirage des trois emplacements', () async {
    final registry = await loadGameDataRegistry(rootBundle);
    final mythiques = registry.levelUpRewards
        .where((r) => r.pool == RewardPool.mythic)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    expect(mythiques.map((r) => r.id), ['wisdom', 'lucky_clover', 'mirror']);
    // Par id, et non par place : la place change avec le catalogue.
    final byId = {for (final r in mythiques) r.id: r};
    expect(byId['wisdom']!.stat, RewardStat.maxMana);
    expect(byId['wisdom']!.amountFor(RewardRarity.mythic), 1);
    expect(byId['lucky_clover']!.amountFor(RewardRarity.mythic), 1);
    expect(byId['mirror']!.effect, RewardEffect.cloneCard);
  });
```

In `test/unit/level_up_reward_values_test.dart`, delete the `'wisdom'` entry of `_attendu` and its comment:

```dart
  // Sagesse plafonne à 2 sur deux paliers consécutifs : `round(1 × 1,5)` et
  // `round(1 × 2,0)` donnaient tous deux 2. Comportement existant, recopié
  // dans `wisdom.json` tel quel plutôt que corrigé au passage (spec §8.4).
  'wisdom': {
    RewardRarity.common: 1,
    RewardRarity.uncommon: 2,
    RewardRarity.rare: 2,
    RewardRarity.epic: 3,
    RewardRarity.legendary: 4,
  },
```

Then replace:

```dart
    test('la table est respectée sur les 30 combinaisons', () {
      // `generateChoices` tire sa récompense et sa rareté au hasard. On balaie
      // assez large pour voir les 30 combinaisons : la plus rare est un
      // légendaire d'une récompense donnée, à environ 0,33 % par choix à
      // chance 0, soit ~100 occurrences attendues sur 30 000 tirages.
```

with:

```dart
    test('la table est respectée sur les 25 combinaisons', () {
      // `generateChoices` tire sa récompense et sa rareté au hasard. On balaie
      // assez large pour voir les 25 combinaisons : la plus rare est un
      // légendaire d'une récompense donnée, à environ 0,4 % par choix à
      // chance 0, soit ~120 occurrences attendues sur 30 000 tirages.
```

Then replace `    test('les six récompenses tirables sont toutes atteignables', () {` with `    test('les cinq récompenses tirables sont toutes atteignables', () {`.

Then replace:

```dart
      for (final id in _attendu.keys) {
        // Sagesse a un plateau assumé entre peu commun et rare.
        final strict = id != 'wisdom';

        for (var i = 1; i < ordre.length; i++) {
          final precedent = observedValues[id]![ordre[i - 1]]!.single;
          final courant = observedValues[id]![ordre[i]]!.single;
          expect(
            courant,
            strict ? greaterThan(precedent) : greaterThanOrEqualTo(precedent),
```

with:

```dart
      for (final id in _attendu.keys) {
        for (var i = 1; i < ordre.length; i++) {
          final precedent = observedValues[id]![ordre[i - 1]]!.single;
          final courant = observedValues[id]![ordre[i]]!.single;
          expect(
            courant,
            greaterThan(precedent),
```

Then replace:

```dart
    // Ce que le passage en donnée ne doit surtout pas changer : le Trèfle et
    // le Miroir n'entrent jamais dans la table des trois emplacements, et
    // chacun a son propre jet, à 0,5 % à chance nulle. Avant ce chantier, les
    // deux étaient construits hors du tirage, ce qui le garantissait par
    // construction ; en donnée, c'est `pool` qui le garantit — donc un test.
```

with:

```dart
    // Ce que le passage en donnée ne doit surtout pas changer : les
    // mythiques — le Trèfle, le Miroir, et *Sagesse* depuis D11 (spec P-43
    // E3, §4.10) — n'entrent jamais dans la table des trois emplacements, et
    // chacune a son propre jet, à 0,5 % à chance nulle (D62). Avant P-41, le
    // Trèfle et le Miroir étaient construits hors du tirage, ce qui le
    // garantissait par construction ; en donnée, c'est `pool` qui le garantit
    // — donc un test.
```

Then replace `      final comptes = <String, int>{'lucky_clover': 0, 'mirror': 0};` with `      final comptes = <String, int>{'wisdom': 0, 'lucky_clover': 0, 'mirror': 0};`.

In `test/unit/level_up_reward_apply_test.dart`, replace:

```dart
  test('Sagesse monte le mana max', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.maxMana;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('wisdom', RewardRarity.legendary)); // +4

    expect(container.read(runProvider).heroStats.maxMana, avant + 4);
  });
```

with:

```dart
  test('Sagesse, mythique, monte le mana max de 1', () {
    final container = freshRun();
    final avant = container.read(runProvider).heroStats.maxMana;

    container
        .read(runProvider.notifier)
        .applyLevelUpReward(choice('wisdom', RewardRarity.mythic)); // +1

    expect(container.read(runProvider).heroStats.maxMana, avant + 1);
  });
```

In `test/unit/level_up_reward_requirement_test.dart`, replace:

```dart
  test('un passif avec Maitrise laisse les six types tirables', () {
    expect(
      tirees(activePassive: passif(mastery: bloc)),
      {'vitality', 'sharpening', 'affinity', 'wisdom', 'precision', 'ferocity'},
    );
  });

  test('un passif sans Maitrise retire l Affinite de la table', () {
    final vues = tirees(activePassive: passif());
    expect(vues, isNot(contains('affinity')));
    // Les cinq autres restent : la table rétrécit, elle ne se vide pas.
    expect(
      vues,
      {'vitality', 'sharpening', 'wisdom', 'precision', 'ferocity'},
    );
  });
```

with:

```dart
  test('un passif avec Maitrise laisse les cinq types tirables', () {
    expect(
      tirees(activePassive: passif(mastery: bloc)),
      {'vitality', 'sharpening', 'affinity', 'precision', 'ferocity'},
    );
  });

  test('un passif sans Maitrise retire l Affinite de la table', () {
    final vues = tirees(activePassive: passif());
    expect(vues, isNot(contains('affinity')));
    // Les quatre autres restent : la table rétrécit, elle ne se vide pas.
    expect(
      vues,
      {'vitality', 'sharpening', 'precision', 'ferocity'},
    );
  });
```

In `test/tutorial/tutorial_prose_test.dart`, replace:

```dart
      'Trois options sont tirées parmi six types — Vitalité, Aiguisage, '
      'Affinité, Sagesse, Précision, Férocité — et jusqu\'à deux options '
      'Mythiques peuvent s\'y ajouter : Trèfle à 4 feuilles et Miroir.',
```

with:

```dart
      'Trois options sont tirées parmi cinq types — Vitalité, Aiguisage, '
      'Affinité, Précision, Férocité — et jusqu\'à trois options Mythiques '
      'peuvent s\'y ajouter : Sagesse, Trèfle à 4 feuilles et Miroir.',
```

Then replace:

```dart
      'Vitalité, Aiguisage, Affinité, Sagesse, Précision, Férocité',
    );
    expect(
      fillRewardPlaceholders('{rollableNames}', rewards, isFrench: false),
      'Vitality, Sharpening, Affinity, Wisdom, Precision, Ferocity',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: true),
      'Trèfle à 4 feuilles et Miroir',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      '4-Leaf Clover and Mirror',
    );
  });
```

with:

```dart
      'Vitalité, Aiguisage, Affinité, Précision, Férocité',
    );
    expect(
      fillRewardPlaceholders('{rollableNames}', rewards, isFrench: false),
      'Vitality, Sharpening, Affinity, Precision, Ferocity',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: true),
      'Sagesse, Trèfle à 4 feuilles et Miroir',
    );
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      'Wisdom, 4-Leaf Clover and Mirror',
    );
  });
```

Then replace:

```dart
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      '4-Leaf Clover and Mirror',
    );
    expect(
      fillRewardPlaceholders('{rollableCount}', rewards, isFrench: false),
      'six',
    );
```

with:

```dart
    expect(
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: false),
      'Wisdom, 4-Leaf Clover and Mirror',
    );
    expect(
      fillRewardPlaceholders('{rollableCount}', rewards, isFrench: false),
      'five',
    );
```

In `test/widget/draft_screen_test.dart`, replace:

```dart
/// Pins the hero's luck stat very low so the two "level-up" mythic rolls
/// (Trèfle à 4 feuilles / Miroir) can never trigger, keeping tests that
/// don't care about the mythic flow deterministic (mythicChance = 0.5 +
/// luck * 0.15, which is guaranteed negative here).
```

with:

```dart
/// Pins the hero's luck stat very low so the level-up mythic rolls — one per
/// mythic reward of the catalogue — can never trigger, keeping tests that
/// don't care about the mythic flow deterministic (mythicChance = 0.5 +
/// luck * 0.15, which is guaranteed negative here).
```

Then replace:

```dart
      // forceLegendary guarantees both extra "level-up" rolls come back
      // mythic (see DraftScreen._rollRarity), so the mythic reveal flow is
      // deterministic regardless of the hero's luck stat.
```

with:

```dart
      // forceLegendary guarantees every mythic roll comes back mythic (see
      // LevelUpRewardService.rollRarity), so the mythic reveal flow is
      // deterministic regardless of the hero's luck stat.
```

Then replace:

```dart
      // Mythic choices ("Trèfle à 4 feuilles" and "Miroir") are now revealed
      // alongside the base 3 in the main grid.
      expect(find.text('Trèfle à 4 feuilles'), findsOneWidget);
      expect(find.text('Miroir'), findsOneWidget);
      expect(find.byType(DraftCardReel), findsNWidgets(5));
```

with:

```dart
      // The three mythic choices (Sagesse, Trèfle à 4 feuilles, Miroir) are
      // now revealed alongside the base 3 in the main grid.
      expect(find.text('Sagesse'), findsOneWidget);
      expect(find.text('Trèfle à 4 feuilles'), findsOneWidget);
      expect(find.text('Miroir'), findsOneWidget);
      expect(find.byType(DraftCardReel), findsNWidgets(6));
```

Six rouleaux sur une rangée débordent la surface de test par défaut (800 × 600 : « A RenderFlex overflowed by 26 pixels ») : les deux cas qui révèlent les mythiques — celui-ci et « Le Miroir de montee de niveau… », que la tâche ne touche pas autrement — reçoivent une vue large, par un helper du fichier que la Task 7 réutilise. Replace:

```dart
Widget _wrap(ProviderContainer container, Widget child, {String locale = 'fr'}) {
```

with:

```dart
/// Une vue large (spec P-43 E3, §4.10) : les mythiques se révèlent dans la
/// même rangée que les trois emplacements — six rouleaux depuis que *Sagesse*
/// est mythique, sept avec *Transcendance* —, que la surface de test par
/// défaut (800 × 600) ne tient pas.
void _largeView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(ProviderContainer container, Widget child, {String locale = 'fr'}) {
```

Then replace:

```dart
    'DraftScreen reveals mythic bonus choices and only allows selection once resolved',
    (WidgetTester tester) async {
```

with:

```dart
    'DraftScreen reveals mythic bonus choices and only allows selection once resolved',
    (WidgetTester tester) async {
      _largeView(tester);
```

Then replace:

```dart
    'Le Miroir de montee de niveau ne propose jamais de copier une carte unique',
    (WidgetTester tester) async {
```

with:

```dart
    'Le Miroir de montee de niveau ne propose jamais de copier une carte unique',
    (WidgetTester tester) async {
      _largeView(tester);
```

Deux cas retouchés, aucun ajouté : le total ne bouge pas.

- [ ] **Step 3: Les lancer pour les voir échouer**

Run: `flutter test test/widget/probabilities_dialog_test.dart test/unit/level_up_rewards_catalog_test.dart test/unit/level_up_reward_values_test.dart test/unit/level_up_reward_apply_test.dart test/unit/level_up_reward_requirement_test.dart test/tutorial/tutorial_prose_test.dart test/widget/draft_screen_test.dart`
Expected: FAIL — `wisdom` encore tirable (les ensembles de tirables, la prose, le catalogue, six rouleaux attendus pour cinq), la parenthèse écrite en dur.

- [ ] **Step 4: La donnée**

Replace the whole content of `assets/data/level_up_rewards/wisdom.json` with:

```json
{
  "id": "wisdom",
  "name_fr": "Sagesse",
  "name_en": "Wisdom",
  "description_fr": "+{amount} Mana Max",
  "description_en": "+{amount} Max Mana",
  "effect": "stat",
  "stat": "maxMana",
  "pool": "mythic",
  "displayOrder": 4,
  "values": {
    "mythic": 1
  }
}
```

Sa valeur, 1, est celle que joue la simulation (`d26_economy_sim.dart:2655`, `:2660`) ; son `displayOrder`, 4, ne change pas.

- [ ] **Step 5: La documentation d'`inPool`**

In `lib/models/data/level_up_reward_data.dart`, replace:

```dart
  /// Le tri est porteur : il fixe l'ordre d'apparition des mythiques et
  /// l'ordre des noms dans la prose du tutoriel — pas celui du tirage, qui
  /// est uniforme et donc indifférent à l'ordre de la liste (ce qui
  /// préserve le tirage d'origine, c'est qu'il y ait exactement six
  /// tirables, verrouillé par un test).
  ///
  /// **Deux lecteurs** passent par ici, le tirage (`LevelUpRewardService`)
  /// et la prose du tutoriel (`tutorial_prose.dart`) : un filtre ajouté à
  /// l'un doit l'être ici, pour les deux.
```

with:

```dart
  /// Le tri est porteur : il fixe l'ordre d'apparition des mythiques et
  /// l'ordre des noms dans la prose du tutoriel et dans la fiche des
  /// probabilités — pas celui du tirage, qui est uniforme et donc
  /// indifférent à l'ordre de la liste (le tirage est uniforme parmi les
  /// tirables, cinq depuis que *Sagesse* est mythique (D11), compte
  /// verrouillé par un test).
  ///
  /// **Trois lecteurs** passent par ici, le tirage (`LevelUpRewardService`),
  /// la prose du tutoriel (`tutorial_prose.dart`) et la fiche des
  /// probabilités (`probabilities_dialog.dart`) : un filtre ajouté à l'un
  /// doit l'être ici, pour les trois.
```

- [ ] **Step 6: La fiche des probabilités**

In `lib/l10n/app_en.arb`, replace:

```json
  "currentLuck": "Your Luck: {luck}",
  "@currentLuck": {
    "placeholders": {
      "luck": { "type": "int" }
    }
  },
```

with:

```json
  "currentLuck": "Your Luck: {luck}",
  "@currentLuck": {
    "placeholders": {
      "luck": { "type": "int" }
    }
  },
  "luckLevelRewardSubtitle": "Chances of getting each option rarity when leveling up (mythic options, rolled separately: {mythicNames})",
  "@luckLevelRewardSubtitle": {
    "placeholders": {
      "mythicNames": { "type": "String" }
    }
  },
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "currentLuck": "Votre Chance : {luck}",
```

with:

```json
  "currentLuck": "Votre Chance : {luck}",
  "luckLevelRewardSubtitle": "Chances d'obtenir chaque rareté d'option lors de la montée de niveau (options mythiques, tirées à part : {mythicNames})",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés, `String luckLevelRewardSubtitle(String mythicNames);`.

In `lib/ui/widgets/map/dialogs/probabilities_dialog.dart`, replace:

```dart
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/level_up_reward_service.dart';
import '../../../../models/reward_rarity.dart';
```

with:

```dart
import '../../../../game/controllers/run_controller.dart';
import '../../../../game/services/level_up_reward_service.dart';
import '../../../../models/data/level_up_reward_data.dart';
import '../../../../models/reward_rarity.dart';
import '../../../../services/game_data_service.dart';
```

Then replace:

```dart
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runProvider);
    final int luck = runState.heroStats.luck;
```

with:

```dart
  Widget build(BuildContext context, WidgetRef ref) {
    final runState = ref.watch(runProvider);
    // Les mythiques se nomment depuis la donnée (spec P-43 E3, §5.1 ;
    // propriétaire n° 7, C3.2) : le chargeur, comme la fiche des stats —
    // jamais le registre global (A9).
    final gameData = ref.watch(gameDataLoaderProvider).value;
    if (gameData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final int luck = runState.heroStats.luck;
```

Then replace:

```dart
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GameDialog(
```

with:

```dart
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final mythicNames = [
      for (final reward in LevelUpRewardData.inPool(
          gameData.levelUpRewards, RewardPool.mythic))
        reward.getName(locale),
    ].join(' / ');

    return GameDialog(
```

Then replace:

```dart
                      subtitle: locale == 'fr'
                          ? "Chances d'obtenir chaque rareté d'option lors de la montée de niveau (Trèfle / Miroir)"
                          : "Chances of getting each option rarity when leveling up (Clover / Mirror)",
```

with:

```dart
                      subtitle: l10n.luckLevelRewardSubtitle(mythicNames),
```

La couche UI lit un modèle et un provider de service, comme la fiche des stats : aucune entorse aux couches (spec §5.1).

- [ ] **Step 7: Les tests passent**

Run: `flutter test test/widget/probabilities_dialog_test.dart test/unit/level_up_rewards_catalog_test.dart test/unit/level_up_reward_values_test.dart test/unit/level_up_reward_apply_test.dart test/unit/level_up_reward_requirement_test.dart test/tutorial/tutorial_prose_test.dart test/widget/draft_screen_test.dart test/unit/level_up_reward_data_test.dart test/unit/draft_choice_labels_test.dart test/widget/draft_card_reel_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: PASS.

- [ ] **Step 8: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e "Trèfle / Miroir" -e "Clover / Mirror" -- lib`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1577: All tests passed!` (1575 + 2)

- [ ] **Step 9: Commit**

```bash
git add assets/data/level_up_rewards/wisdom.json lib/models/data/level_up_reward_data.dart lib/ui/widgets/map/dialogs/probabilities_dialog.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/widget/probabilities_dialog_test.dart test/unit/level_up_rewards_catalog_test.dart test/unit/level_up_reward_values_test.dart test/unit/level_up_reward_apply_test.dart test/unit/level_up_reward_requirement_test.dart test/tutorial/tutorial_prose_test.dart test/widget/draft_screen_test.dart
git commit -F - <<'EOF'
feat(recompenses): Sagesse devient une recompense mythique

Sagesse quitte les trois emplacements, qui tirent parmi cinq, et gagne
son propre jet, a plus 1 Mana max. La fiche des probabilites ne nomme
plus ses mythiques en dur : elle les lit dans la donnee. Son test garde
une rangee de plus et l ordre des rangees.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 7: *Transcendance* — la mythique qui relève le plafond d'un type de rune

D42(c), D62, A15, A16 (spec §3.5, §3.7, §3.8, §4.8, §5.1) : une quatrième mythique, `level_up_rewards/transcendence.json`, `effect: raiseRuneCap`, `requires: raisableRune`. Elle n'est tirée que si le deck porte une rune **à son plafond effectif**, ni sans plafond ni `binary` (`ForgeRuneRules.raisableCaps`) — l'écran de draft calcule ce fait sur le deck et le bonus de la run, et le passe à `generateChoices(hasRaisableRune:)`. Choisie, elle ouvre une modale non refermable, sur le modèle du clonage : une ligne par candidate, « Niveau maximal n → n+1 » ; le toucher appelle `RunController.raiseRuneCap`, qui monte de 1 `RunState.runeCapBonus[id]`, notifie `runeCapRaised`, et termine le draft. `binary` (A16) entre dans le modèle de rune, vrai sur `enduring` et `cheap`, et dans le gabarit de l'éditeur.

Cette tâche pose le bonus et ses deux lecteurs du draft — `raisableCaps` et la modale. Les écrivains de niveau qui le lisent — la borne, la fusion, les pré-forgées, le feu, le Puits, le boss « XP », le *Rémouleur* — sont les Tasks 8 et 9 : entre les deux, *Transcendance* relève un plafond que rien d'autre ne lit encore, un état interne à la partie, jamais livré.

**Files:**
- Create: `assets/data/level_up_rewards/transcendence.json`
- Modify: `assets/data/forge_upgrades/enduring.json:24`, `assets/data/forge_upgrades/cheap.json:14` (`"binary": true`)
- Modify: `lib/models/data/forge_upgrade_data.dart:43-104` (`binary`, `fromJson`), `:200-221` (`toJson`)
- Modify: `lib/services/content_editor/entity_descriptor.dart:360-391` (le gabarit de rune et son commentaire)
- Modify: `lib/game/controllers/run_controller.dart` (`RunState.runeCapBonus` ; `raiseRuneCap`, après `loseRelic` de la Task 4)
- Modify: `lib/game/services/forge_rune_rules.dart` (`RaisableCap`, `raisableCaps`)
- Modify: `lib/models/data/level_up_reward_data.dart:6-13`, `:31-40`, `:45-49`, `:162-168`
- Modify: `lib/game/services/level_up_reward_service.dart:27-29`, `:131-142`
- Modify: `lib/game/controllers/run/player_stats_manager.dart:75`
- Modify: `lib/ui/screens/draft_screen.dart:1-20` (imports), `:103-110` (`initState`), `:591-649` (après `_showCloneModal`), `:651-672` (`_onChoiceSelected`)
- Modify: `lib/l10n/app_en.arb:421`, `lib/l10n/app_fr.arb:168` ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Test: `test/unit/forge_upgrade_data_test.dart:312-329`, un groupe neuf ; `test/unit/forge_upgrades_catalog_test.dart:239-258`, un cas ; `test/unit/content_editor/entity_descriptor_test.dart:259-272` ; `test/unit/forge_rune_rules_test.dart:12-29`, un groupe neuf ; `test/unit/run_state_persistence_test.dart` ; `test/unit/run_controller_test.dart`
- Test: `test/unit/level_up_reward_data_test.dart` (groupe « lecture ») ; `test/unit/level_up_reward_requirement_test.dart:56-60`, trois cas ; `test/unit/level_up_rewards_catalog_test.dart` (Task 6) ; `test/tutorial/tutorial_prose_test.dart` (Task 6) ; `test/widget/probabilities_dialog_test.dart` (Task 6) ; `test/widget/draft_screen_test.dart`, deux cas
- Test: `test/unit/real_bundle_load_test.dart`, `test/unit/entity_id_convention_test.dart` (comptes)

**Interfaces:**
- Consumes: `LevelUpRewardService.generateChoices`, `LevelUpRewardData.isAvailableWith`, `DraftScreen._showCloneModal` (le modèle de la modale).
- Produces:
  - `ForgeUpgradeData.binary` (`bool`, faux par défaut ; refusé avec un `maxLevel` autre que 1 ; toujours écrit par `toJson`, C1.3) ;
  - `RunState.runeCapBonus` (`Map<String, int>`, vide ; sérialisé) et `void RunController.raiseRuneCap(String runeId)` ;
  - `typedef RaisableCap = ({ForgeUpgradeData rune, int cap});` et `static List<RaisableCap> ForgeRuneRules.raisableCaps(Iterable<CardInstance> deck, Iterable<ForgeUpgradeData> catalog, {Map<String, int> capBonus = const {}})` — `cap`, le plafond effectif ;
  - `RewardEffect.raiseRuneCap`, `RewardRequirement.raisableRune`, `bool LevelUpRewardData.isAvailableWith(PassiveData? passive, {bool hasRaisableRune = false})` ;
  - `LevelUpRewardService.generateChoices({…, bool hasRaisableRune = false})`, `bool DraftChoice.isRuneCapOption` ;
  - les clés ARB `runeCapTitle`, `runeCapLine` (`{from}`, `{to}`), `runeCapRaised` (`{runeName}`, `{level}`).

- [ ] **Step 1: Les tests de `binary`**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
      'requiresExhaust',
      'requiresMinCost',
      'maxLevel',
      'deltas',
      'weight',
      'emoji',
    });
  });
```

with:

```dart
      'requiresExhaust',
      'requiresMinCost',
      'maxLevel',
      'binary',
      'deltas',
      'weight',
      'emoji',
    });
  });

  // A16 : une rune binaire n'a qu'un niveau qui compte (spec P-43 E3, §3.8).
  group('binary', () {
    test('lu ; faux s il est absent ; toujours ecrit par toJson', () {
      expect(ForgeUpgradeData.fromJson(_json()).binary, isFalse);
      expect(ForgeUpgradeData.fromJson(_json()).toJson(),
          containsPair('binary', false));
      final cheap =
          ForgeUpgradeData.fromJson(_json({'maxLevel': 1, 'binary': true}));
      expect(cheap.binary, isTrue);
      expect(ForgeUpgradeData.fromJson(cheap.toJson()).binary, isTrue);
    });

    test('refuse une rune binaire de plafond autre que 1, et une valeur non '
        'booleenne', () {
      for (final maxLevel in [null, 2]) {
        expect(
          () => ForgeUpgradeData.fromJson(
              _json({'maxLevel': maxLevel, 'binary': true})),
          _refused('binary'),
          reason: '$maxLevel',
        );
      }
      expect(() => ForgeUpgradeData.fromJson(_json({'binary': 'oui'})),
          _refused('binary'));
    });
  });
```

In `test/unit/forge_upgrades_catalog_test.dart`, replace:

```dart
      'excludesRunes',
      'maxLevel',
      'deltas',
      'weight',
      'emoji',
    };
```

with:

```dart
      'excludesRunes',
      'maxLevel',
      'binary',
      'deltas',
      'weight',
      'emoji',
    };
```

Then replace:

```dart
  test('la matrice couvre les 23 cartes livrees', () {
```

with:

```dart
  // A16 : les runes dont le plafond ne monte jamais (spec P-43 E3, §3.7).
  test('enduring et cheap sont binaires, les neuf autres non', () {
    expect(registry.forgeUpgrades, hasLength(11));
    expect(
      {
        for (final rune in registry.forgeUpgrades)
          if (rune.binary) rune.id,
      },
      {'enduring', 'cheap'},
    );
  });

  test('la matrice couvre les 23 cartes livrees', () {
```

In `test/unit/content_editor/entity_descriptor_test.dart`, in the expected keys of `EntityCategory.forgeUpgrade`, replace:

```dart
        'requiresMinCost',
        'maxLevel',
        'deltas',
```

with:

```dart
        'requiresMinCost',
        'maxLevel',
        'binary',
        'deltas',
```

- [ ] **Step 2: Les tests des candidates, du bonus et de la mythique**

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
ForgeUpgradeData _rune(
  String id, {
  int? maxLevel,
  int minFusionRank = 1,
  int weight = 10,
}) =>
    ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      minFusionRank: minFusionRank,
      maxLevel: maxLevel,
      weight: weight,
    );
```

with:

```dart
ForgeUpgradeData _rune(
  String id, {
  int? maxLevel,
  bool binary = false,
  int minFusionRank = 1,
  int weight = 10,
}) =>
    ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      minFusionRank: minFusionRank,
      maxLevel: maxLevel,
      binary: binary,
      weight: weight,
    );
```

Then replace:

```dart
  // Le Puits d'echange (spec P-43 E2, A5, A6, §4.8).
  group('le Puits', () {
```

with:

```dart
  // Les candidates de Transcendance (spec P-43 E3, §4.8 ; A15, A16).
  group('raisableCaps', () {
    final catalog = [
      _rune('sharp'),
      _rune('enduring', maxLevel: 1, binary: true),
      _rune('eco', maxLevel: 1),
      _rune('capped', maxLevel: 2),
    ];

    List<(String, int)> candidatesOf(
      List<CardInstance> deck, {
      Map<String, int> capBonus = const {},
    }) =>
        [
          for (final (:rune, :cap)
              in ForgeRuneRules.raisableCaps(deck, catalog, capBonus: capBonus))
            (rune.id, cap),
        ];

    test('les runes portees a leur plafond, sans les binaires ni les runes '
        'sans plafond, une fois chacune, dans l ordre du catalogue', () {
      expect(
        candidatesOf([
          _cardWith(['capped:2', 'sharp:9']),
          _cardWith(['eco:1', 'enduring:1']),
          _cardWith(['eco:1', 'capped:1']),
        ]),
        [('eco', 1), ('capped', 2)],
      );
    });

    test('le plafond effectif compte : une rune relevee n est plus candidate '
        'avant d y remonter', () {
      expect(
        candidatesOf([_cardWith(['eco:1']), _cardWith(['capped:2'])],
            capBonus: {'eco': 1}),
        [('capped', 2)],
      );
      expect(candidatesOf([_cardWith(['eco:2'])], capBonus: {'eco': 1}),
          [('eco', 2)]);
    });
  });

  // Le Puits d'echange (spec P-43 E2, A5, A6, §4.8).
  group('le Puits', () {
```

In `test/unit/run_state_persistence_test.dart`, replace:

```dart
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.extraBossRuneSharpens, 0);
    });
```

with:

```dart
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.extraBossRuneSharpens, 0);
    });

    // Le bonus de plafond de Transcendance (spec P-43 E3, §3.8, §8).
    test('runeCapBonus round-trip et vaut vide quand la cle manque', () {
      final json = buildRunState()
          .copyWith(runeCapBonus: {'eco': 1, 'quick': 2})
          .toJson();
      expect(json['runeCapBonus'], {'eco': 1, 'quick': 2});

      final (restored, _) =
          RunState.fromJsonWithReport(jsonDecode(jsonEncode(json)));
      expect(restored.runeCapBonus, {'eco': 1, 'quick': 2});

      final legacy = Map<String, dynamic>.from(json)..remove('runeCapBonus');
      final (restoredLegacy, _) = RunState.fromJsonWithReport(legacy);
      expect(restoredLegacy.runeCapBonus, isEmpty);
    });
```

and add at the top of the same file the import `import 'dart:convert';` — le passage par `jsonEncode` puis `jsonDecode` relit la table telle qu'une sauvegarde la rend, `Map<String, dynamic>`.

In `test/unit/run_controller_test.dart`, replace:

```dart
  // Payer et ecrire, ou rien (spec P-43 E2, §4.7, A16).
  group('RunController.sharpenRune', () {
```

with:

```dart
  // Transcendance (spec P-43 E3, §4.8 ; D42(c), A15).
  test('raiseRuneCap monte de 1 le plafond d un type de rune, pour la run',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final run = container.read(runProvider.notifier);

    run.raiseRuneCap('eco');
    run.raiseRuneCap('eco');
    run.raiseRuneCap('quick');

    expect(container.read(runProvider).runeCapBonus, {'eco': 2, 'quick': 1});
  });

  // Payer et ecrire, ou rien (spec P-43 E2, §4.7, A16).
  group('RunController.sharpenRune', () {
```

In `test/unit/level_up_reward_data_test.dart`, replace:

```dart
  group('lecture', () {
    test('une récompense de stat porte sa table par rareté', () {
```

with:

```dart
  group('lecture', () {
    // Transcendance (spec P-43 E3, §3.5, §3.8 ; D42(c), A15).
    test('une récompense qui relève un plafond de rune se lit, avec son '
        'exigence', () {
      final transcendence = LevelUpRewardData.fromJson({
        'id': 'transcendence',
        'name_fr': 'Transcendance',
        'name_en': 'Transcendence',
        'description_fr': 'Plafond de rune +1',
        'description_en': 'Rune cap +1',
        'effect': 'raiseRuneCap',
        'requires': 'raisableRune',
        'pool': 'mythic',
        'values': <String, dynamic>{},
      });

      expect(transcendence.effect, RewardEffect.raiseRuneCap);
      expect(transcendence.stat, isNull);
      expect(transcendence.requires, RewardRequirement.raisableRune);
    });

    test('une récompense de stat porte sa table par rareté', () {
```

In `test/unit/level_up_reward_requirement_test.dart`, replace:

```dart
  test('aucune autre récompense n exige quoi que ce soit', () {
    for (final reward in rewards.where((r) => r.id != 'affinity')) {
      expect(reward.requires, isNull, reason: reward.id);
    }
  });
```

with:

```dart
  test('hors d Affinite et de Transcendance, aucune récompense n exige quoi '
      'que ce soit', () {
    for (final reward in rewards
        .where((r) => r.id != 'affinity' && r.id != 'transcendence')) {
      expect(reward.requires, isNull, reason: reward.id);
    }
  });

  // Transcendance (spec P-43 E3, §4.8 ; A15) : tirée seulement si une rune du
  // deck est à son plafond effectif.
  test('transcendence.json declare son exigence', () {
    final transcendence = rewards.firstWhere((r) => r.id == 'transcendence');
    expect(transcendence.requires, RewardRequirement.raisableRune);
    expect(transcendence.effect, RewardEffect.raiseRuneCap);
    expect(transcendence.pool, RewardPool.mythic);
  });

  test('isAvailableWith : Transcendance suit le fait de la rune, Affinite '
      'n en depend pas', () {
    final transcendence = rewards.firstWhere((r) => r.id == 'transcendence');
    final affinity = rewards.firstWhere((r) => r.id == 'affinity');

    expect(transcendence.isAvailableWith(null), isFalse);
    expect(transcendence.isAvailableWith(null, hasRaisableRune: true), isTrue);
    expect(affinity.isAvailableWith(passif(mastery: bloc)), isTrue);
    expect(affinity.isAvailableWith(passif(), hasRaisableRune: true), isFalse);
  });

  test('generateChoices sous forceLegendary sort Transcendance avec une rune '
      'a relever, jamais sans', () {
    List<String> mythicsOf({required bool hasRaisableRune}) => [
          for (final choice in LevelUpRewardService.generateChoices(
            rewards: rewards,
            luck: 0,
            forceLegendary: true,
            hasRaisableRune: hasRaisableRune,
          ).skip(3))
            choice.data.id,
        ];

    expect(mythicsOf(hasRaisableRune: true),
        ['wisdom', 'lucky_clover', 'mirror', 'transcendence']);
    expect(mythicsOf(hasRaisableRune: false),
        ['wisdom', 'lucky_clover', 'mirror']);
  });
```

In `test/unit/level_up_rewards_catalog_test.dart` (Task 6), replace:

```dart
  test('les huit récompenses se chargent depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.levelUpRewards, hasLength(8));
    expect(
      registry.levelUpRewards.map((r) => r.id).toSet(),
      {...attendu.keys, 'wisdom', 'lucky_clover', 'mirror'},
    );
  });
```

with:

```dart
  test('les neuf récompenses se chargent depuis le vrai bundle', () async {
    final registry = await loadGameDataRegistry(rootBundle);

    expect(registry.levelUpRewards, hasLength(9));
    expect(
      registry.levelUpRewards.map((r) => r.id).toSet(),
      {...attendu.keys, 'wisdom', 'lucky_clover', 'mirror', 'transcendence'},
    );
  });
```

Then replace:

```dart
  test('les trois mythiques sont hors du tirage des trois emplacements', () async {
```

with:

```dart
  test('les quatre mythiques sont hors du tirage des trois emplacements', () async {
```

Then replace:

```dart
    expect(mythiques.map((r) => r.id), ['wisdom', 'lucky_clover', 'mirror']);
```

with:

```dart
    expect(mythiques.map((r) => r.id),
        ['wisdom', 'lucky_clover', 'mirror', 'transcendence']);
```

Then replace:

```dart
    expect(byId['mirror']!.effect, RewardEffect.cloneCard);
  });
```

with:

```dart
    expect(byId['mirror']!.effect, RewardEffect.cloneCard);
    expect(byId['transcendence']!.effect, RewardEffect.raiseRuneCap);
  });
```

Then replace `  test('les huit récompenses portent leurs deux langues', () async {` with `  test('les neuf récompenses portent leurs deux langues', () async {`, and replace `    expect(rangs, [1, 2, 3, 4, 5, 6, 7, 8]);` with `    expect(rangs, [1, 2, 3, 4, 5, 6, 7, 8, 9]);`.

In `test/tutorial/tutorial_prose_test.dart` (Task 6), replace:

```dart
      'Affinité, Précision, Férocité — et jusqu\'à trois options Mythiques '
      'peuvent s\'y ajouter : Sagesse, Trèfle à 4 feuilles et Miroir.',
```

with:

```dart
      'Affinité, Précision, Férocité — et jusqu\'à quatre options Mythiques '
      'peuvent s\'y ajouter : Sagesse, Trèfle à 4 feuilles, Miroir et '
      'Transcendance.',
```

Then replace:

```dart
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: true),
      'Sagesse, Trèfle à 4 feuilles et Miroir',
```

with:

```dart
      fillRewardPlaceholders('{mythicNames}', rewards, isFrench: true),
      'Sagesse, Trèfle à 4 feuilles, Miroir et Transcendance',
```

Then replace each of the two occurrences of `      'Wisdom, 4-Leaf Clover and Mirror',` with `      'Wisdom, 4-Leaf Clover, Mirror and Transcendence',`.

In `test/widget/probabilities_dialog_test.dart` (Task 6), replace:

```dart
          'de niveau (options mythiques, tirées à part : Sagesse / Trèfle à '
          '4 feuilles / Miroir)'),
```

with:

```dart
          'de niveau (options mythiques, tirées à part : Sagesse / Trèfle à '
          '4 feuilles / Miroir / Transcendance)'),
```

and replace:

```dart
          '(mythic options, rolled separately: Wisdom / 4-Leaf Clover / '
          'Mirror)'),
```

with:

```dart
          '(mythic options, rolled separately: Wisdom / 4-Leaf Clover / '
          'Mirror / Transcendence)'),
```

In `test/widget/draft_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_card.dart';
```

with:

```dart
import 'package:roguelike_card_game/ui/widgets/draft/draft_choice_card.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
```

Then replace (Task 6):

```dart
      // The three mythic choices (Sagesse, Trèfle à 4 feuilles, Miroir) are
      // now revealed alongside the base 3 in the main grid.
```

with:

```dart
      // The three mythic choices (Sagesse, Trèfle à 4 feuilles, Miroir) are
      // now revealed alongside the base 3 in the main grid. Transcendance
      // stays out: no rune of this empty deck is at its cap.
```

Then replace the end of the file:

```dart
      expect(find.text('Frappe'), findsOneWidget);
      expect(find.text('Bouclier Sacre'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
```

with:

```dart
      expect(find.text('Frappe'), findsOneWidget);
      expect(find.text('Bouclier Sacre'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  // Transcendance (spec P-43 E3, §4.8, §8 ; A15) : l'écran lit le deck et le
  // bonus de plafond de la run.
  // Sept rouleaux, dont quatre dans la révélation : la vue large du fichier
  // (`_largeView`, Task 6).
  group('Transcendance', () {
    /// Un conteneur sur le registre réel, résolu, dont le deck porte une
    /// Frappe rare à Économe 1 — à son plafond.
    Future<ProviderContainer> ecoDeck() async {
      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
      );
      addTearDown(container.dispose);
      await container.read(gameDataLoaderProvider.future);
      container.read(deckProvider.notifier).addCardToMasterDeck(CardInstance(
            data: registry.cards.singleWhere((c) => c.id == 'strike_basic'),
            rarity: CardRarity.rare,
            forgeUpgrades: const ['eco:1'],
          ));
      return container;
    }

    testWidgets('une rune a son plafond fait sortir Transcendance, dont la '
        'modale releve le plafond, le notifie et termine le draft',
        (WidgetTester tester) async {
      _largeView(tester);
      final container = await ecoDeck();
      bool draftCompleted = false;

      await tester.pumpWidget(_wrap(
        container,
        DraftScreen(
          onDraftComplete: () => draftCompleted = true,
          forceLegendary: true,
        ),
      ));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 15000));

      expect(find.byType(DraftCardReel), findsNWidgets(7));
      await tester.tap(find.text('Transcendance'));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 800));

      expect(find.text('Choisissez la rune dont le plafond monte'),
          findsOneWidget);
      expect(find.text('Niveau maximal 1 → 2'), findsOneWidget);

      await tester.tap(find.text('Économe'));
      await tester.pump();

      expect(container.read(runProvider).runeCapBonus, {'eco': 1});
      expect(draftCompleted, isTrue);
      expect(container.read(notificationProvider).last.message,
          'Économe peut désormais monter jusqu\'au niveau 2.');

      // Le minuteur de la notification expire avant le démontage.
      await _advance(tester, const Duration(seconds: 4));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('le plafond releve, la rune n y est plus : Transcendance ne '
        'sort pas', (WidgetTester tester) async {
      _largeView(tester);
      final container = await ecoDeck();
      container.read(runProvider.notifier).raiseRuneCap('eco');

      await tester.pumpWidget(_wrap(
        container,
        DraftScreen(onDraftComplete: () {}, forceLegendary: true),
      ));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 15000));

      expect(find.byType(DraftCardReel), findsNWidgets(6));
      expect(find.text('Transcendance'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
```

- [ ] **Step 3: Les lancer pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/forge_rune_rules_test.dart test/unit/run_state_persistence_test.dart test/unit/run_controller_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_reward_requirement_test.dart test/unit/level_up_rewards_catalog_test.dart test/tutorial/tutorial_prose_test.dart test/widget/probabilities_dialog_test.dart test/widget/draft_screen_test.dart`
Expected: FAIL — à la compilation (`binary`, `raisableCaps`, `runeCapBonus`, `raiseRuneCap`, `raiseRuneCap`/`raisableRune` des énumérations, `hasRaisableRune` n'existent pas).

- [ ] **Step 4: `binary`, le modèle et la donnée**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
  final int? maxLevel;

  /// Ce que fait la rune : des sortes de delta, déclarées par niveau (spec
```

with:

```dart
  final int? maxLevel;

  /// La rune n'a qu'un niveau qui compte : un second ne lui ajouterait rien
  /// — `enduring`, `cheap` (spec P-43 E3, §3.7, A16). Son plafond ne monte
  /// jamais : *Transcendance* ne la propose pas. Absente du fichier, fausse ;
  /// vraie, elle exige `maxLevel: 1`.
  final bool binary;

  /// Ce que fait la rune : des sortes de delta, déclarées par niveau (spec
```

Then replace:

```dart
    this.maxLevel,
    this.deltas = const [],
```

with:

```dart
    this.maxLevel,
    this.binary = false,
    this.deltas = const [],
```

Then replace:

```dart
  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ForgeUpgradeData(
```

with:

```dart
  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final maxLevel = _readMaxLevel(id, json);
    return ForgeUpgradeData(
```

Then replace:

```dart
      maxLevel: _readMaxLevel(id, json),
      deltas: _readDeltas(id, json['deltas']),
```

with:

```dart
      maxLevel: maxLevel,
      binary: _readBinary(id, json['binary'], maxLevel),
      deltas: _readDeltas(id, json['deltas']),
```

Then replace:

```dart
  /// La clé est obligatoire (spec P-43 E2, A8) : un entier d'au moins 1.
```

with:

```dart
  /// `binary` : absente, fausse ; sinon un booléen, vrai seulement avec
  /// `maxLevel: 1` — une rune binaire n'a qu'un niveau (spec P-43 E3, A16).
  static bool _readBinary(String id, Object? raw, int? maxLevel) {
    if (raw == null) return false;
    if (raw is! bool) {
      throw FormatException('$id : binary vaut true ou false — reçu : $raw');
    }
    if (raw && maxLevel != 1) {
      throw FormatException(
        '$id : une rune binary a maxLevel 1 — reçu : $maxLevel',
      );
    }
    return raw;
  }

  /// La clé est obligatoire (spec P-43 E2, A8) : un entier d'au moins 1.
```

Then replace:

```dart
      'maxLevel': maxLevel,
      'deltas': [for (final delta in deltas) delta.toJson()],
```

with:

```dart
      'maxLevel': maxLevel,
      'binary': binary,
      'deltas': [for (final delta in deltas) delta.toJson()],
```

In `assets/data/forge_upgrades/enduring.json` and in `assets/data/forge_upgrades/cheap.json`, replace:

```json
  "maxLevel": 1,
  "deltas": [
```

with:

```json
  "maxLevel": 1,
  "binary": true,
  "deltas": [
```

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // `maxLevel` y vaut 1, une valeur prudente : un plafond oublie ne laisse
    // pas monter une rune sans fin (spec P-43 E1, §6). `minFusionRank` y vaut
```

with:

```dart
    // `maxLevel` y vaut 1, une valeur prudente : un plafond oublie ne laisse
    // pas monter une rune sans fin (spec P-43 E1, §6). `binary` y vaut false :
    // une rune binaire le declare, avec `maxLevel: 1` (spec P-43 E3, A16).
    // `minFusionRank` y vaut
```

Then replace:

```dart
  "requiresMinCost": 0,
  "maxLevel": 1,
  "deltas": [
```

with:

```dart
  "requiresMinCost": 0,
  "maxLevel": 1,
  "binary": false,
  "deltas": [
```

- [ ] **Step 5: Le bonus de la run**

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  final int extraBossRuneSharpens;
```

with:

```dart
  final int extraBossRuneSharpens;

  /// Le bonus de plafond de rune de la run (spec P-43 E3, §4.8 ; D42(c),
  /// A15, A17) : par id de rune, les niveaux que *Transcendance* ajoute à son
  /// `maxLevel`, sur toutes les cartes. Vide au départ ; écrit par
  /// `RunController.raiseRuneCap`.
  final Map<String, int> runeCapBonus;
```

Then replace `    this.extraBossRuneSharpens = 0,` with:

```dart
    this.extraBossRuneSharpens = 0,
    this.runeCapBonus = const {},
```

Then replace `    int? extraBossRuneSharpens,` with:

```dart
    int? extraBossRuneSharpens,
    Map<String, int>? runeCapBonus,
```

Then replace:

```dart
      extraBossRuneSharpens:
          extraBossRuneSharpens ?? this.extraBossRuneSharpens,
```

with:

```dart
      extraBossRuneSharpens:
          extraBossRuneSharpens ?? this.extraBossRuneSharpens,
      runeCapBonus: runeCapBonus ?? this.runeCapBonus,
```

Then replace `        'extraBossRuneSharpens': extraBossRuneSharpens,` with:

```dart
        'extraBossRuneSharpens': extraBossRuneSharpens,
        'runeCapBonus': runeCapBonus,
```

Then replace `      extraBossRuneSharpens: json['extraBossRuneSharpens'] as int? ?? 0,` with:

```dart
      extraBossRuneSharpens: json['extraBossRuneSharpens'] as int? ?? 0,
      runeCapBonus: {
        for (final MapEntry(:key, :value)
            in (json['runeCapBonus'] as Map<String, dynamic>? ?? const {})
                .entries)
          key: value as int,
      },
```

Then replace (Task 4):

```dart
  void loseRelic(RelicData relic) {
    removeRelicEffect(relic);
    ref.read(inventoryProvider.notifier).removeRelics([relic.id]);
  }
```

with:

```dart
  void loseRelic(RelicData relic) {
    removeRelicEffect(relic);
    ref.read(inventoryProvider.notifier).removeRelics([relic.id]);
  }

  /// Relève de 1 le plafond du type de rune [runeId], sur toutes les cartes,
  /// pour toute la run — *Transcendance* (spec P-43 E3, §4.8 ; D42(c), A15).
  void raiseRuneCap(String runeId) {
    state = state.copyWith(runeCapBonus: {
      ...state.runeCapBonus,
      runeId: (state.runeCapBonus[runeId] ?? 0) + 1,
    });
  }
```

- [ ] **Step 6: Les candidates**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
/// Une rune d'une carte du deck, au niveau [level] que la carte porte.
typedef SharpenablePair = ({
  CardInstance card,
  ForgeUpgradeData rune,
  int level,
});
```

with:

```dart
/// Une rune d'une carte du deck, au niveau [level] que la carte porte.
typedef SharpenablePair = ({
  CardInstance card,
  ForgeUpgradeData rune,
  int level,
});

/// Une rune que *Transcendance* peut relever, à son plafond effectif [cap].
typedef RaisableCap = ({ForgeUpgradeData rune, int cap});
```

Then replace:

```dart
  /// `b`, le coût d'un niveau d'affûtage par niveau porté (D63 ; spec P-43
```

with:

```dart
  /// Les runes de [deck] que *Transcendance* peut relever (spec P-43 E3,
  /// §4.8 ; D42(c), A15, A16) : celles qu'une carte porte à leur plafond
  /// effectif — `maxLevel` plus [capBonus] pour leur id —, ni sans plafond
  /// ni `binary`, une fois chacune, dans l'ordre du [catalog], avec ce
  /// plafond. Lues par l'écran de draft, pour la condition `raisableRune`
  /// et pour la modale.
  static List<RaisableCap> raisableCaps(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) {
    final carried = <String, int>{};
    for (final card in deck) {
      for (final MapEntry(key: id, value: level)
          in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries) {
        carried[id] = max(carried[id] ?? 0, level);
      }
    }
    return [
      for (final rune in catalog)
        if (rune.maxLevel case final maxLevel?
            when !rune.binary &&
                (carried[rune.id] ?? 0) >=
                    maxLevel + (capBonus[rune.id] ?? 0))
          (rune: rune, cap: maxLevel + (capBonus[rune.id] ?? 0)),
    ];
  }

  /// `b`, le coût d'un niveau d'affûtage par niveau porté (D63 ; spec P-43
```

- [ ] **Step 7: La récompense, son exigence et son tirage**

In `lib/models/data/level_up_reward_data.dart`, replace:

```dart
  /// Elle ouvre le clonage d'une carte — le Miroir. Aucune stat.
  cloneCard,
}
```

with:

```dart
  /// Elle ouvre le clonage d'une carte — le Miroir. Aucune stat.
  cloneCard,

  /// Elle relève de 1 le plafond d'un type de rune, pour la run —
  /// *Transcendance* (spec P-43 E3, §4.8 ; D42(c)). Aucune stat.
  raiseRuneCap,
}
```

Then replace:

```dart
  /// Le passif actif doit déclarer un bloc `mastery` : sans lui, un point de
  /// Maîtrise n'augmente rien (spec P-49, §3.3).
  passiveMastery,
}
```

with:

```dart
  /// Le passif actif doit déclarer un bloc `mastery` : sans lui, un point de
  /// Maîtrise n'augmente rien (spec P-49, §3.3).
  passiveMastery,

  /// Une rune du deck doit être à son plafond effectif, ni sans plafond ni
  /// binaire : sans elle, *Transcendance* n'aurait rien à relever (spec
  /// P-43 E3, §4.8, A15).
  raisableRune,
}
```

Then replace:

```dart
/// carrousel. Elles sont désormais huit fichiers sous
/// `assets/data/level_up_rewards/`.
```

with:

```dart
/// carrousel. Elles sont désormais des fichiers sous
/// `assets/data/level_up_rewards/` — neuf depuis *Transcendance* (P-43 E3).
```

Then replace:

```dart
  /// Cette récompense peut-elle être tirée dans une run dont le passif actif
  /// est [passive] ? Un passif absent ne déclare aucune Maîtrise : la
  /// récompense serait tout aussi inerte (décision 2 du plan).
  bool isAvailableWith(PassiveData? passive) => switch (requires) {
        null => true,
        RewardRequirement.passiveMastery => passive?.mastery != null,
      };
```

with:

```dart
  /// Cette récompense peut-elle être tirée dans une run dont le passif actif
  /// est [passive], et dont le deck porte une rune à relever si
  /// [hasRaisableRune] ? Un passif absent ne déclare aucune Maîtrise : la
  /// récompense serait tout aussi inerte (décision 2 du plan). Le fait de la
  /// rune vient de l'appelant, qui lit le deck et la run (spec P-43 E3,
  /// §4.8, C2.4) ; faux par défaut, comme dans `generateChoices`.
  bool isAvailableWith(PassiveData? passive, {bool hasRaisableRune = false}) =>
      switch (requires) {
        null => true,
        RewardRequirement.passiveMastery => passive?.mastery != null,
        RewardRequirement.raisableRune => hasRaisableRune,
      };
```

In `lib/game/services/level_up_reward_service.dart`, replace:

```dart
  /// Le Miroir : la seule récompense qui ouvre une modale au lieu de monter
  /// une stat.
  bool get isCloneOption => data.effect == RewardEffect.cloneCard;
```

with:

```dart
  /// Le Miroir : il ouvre la modale de clonage au lieu de monter une stat.
  bool get isCloneOption => data.effect == RewardEffect.cloneCard;

  /// *Transcendance* : elle ouvre la modale des plafonds de rune au lieu de
  /// monter une stat (spec P-43 E3, §4.8).
  bool get isRuneCapOption => data.effect == RewardEffect.raiseRuneCap;
```

Then replace:

```dart
    bool forceLegendary = false,
    PassiveData? activePassive,
  }) {
    final rng = Random();
    // Le filtre s'applique à la table des trois emplacements comme aux
    // mythiques : une exigence est une propriété de la récompense, pas du
    // groupe de tirage (spec P-41, §8.2).
    final eligible =
        rewards.where((reward) => reward.isAvailableWith(activePassive)).toList();
```

with:

```dart
    bool forceLegendary = false,
    PassiveData? activePassive,
    bool hasRaisableRune = false,
  }) {
    final rng = Random();
    // Le filtre s'applique à la table des trois emplacements comme aux
    // mythiques : une exigence est une propriété de la récompense, pas du
    // groupe de tirage (spec P-41, §8.2). [hasRaisableRune] : le deck porte
    // une rune à son plafond effectif (spec P-43 E3, §4.8, A15).
    final eligible = rewards
        .where((reward) => reward.isAvailableWith(
              activePassive,
              hasRaisableRune: hasRaisableRune,
            ))
        .toList();
```

In `lib/game/controllers/run/player_stats_manager.dart`, replace:

```dart
    // Le Miroir : il ouvre une modale de clonage, il ne monte rien.
```

with:

```dart
    // Le Miroir et *Transcendance* ouvrent chacun leur modale : aucun ne
    // monte de stat.
```

- [ ] **Step 8: Les clés ARB**

In `lib/l10n/app_en.arb`, replace:

```json
  "chooseCardToClone": "Choose a card to clone",
```

with:

```json
  "chooseCardToClone": "Choose a card to clone",
  "runeCapTitle": "Choose the rune whose cap rises",
  "runeCapLine": "Max level {from} → {to}",
  "@runeCapLine": {
    "placeholders": {
      "from": { "type": "int" },
      "to": { "type": "int" }
    }
  },
  "runeCapRaised": "{runeName} can now reach level {level}.",
  "@runeCapRaised": {
    "placeholders": {
      "runeName": { "type": "String" },
      "level": { "type": "int" }
    }
  },
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "chooseCardToClone": "Choisissez une carte à cloner",
```

with:

```json
  "chooseCardToClone": "Choisissez une carte à cloner",
  "runeCapTitle": "Choisissez la rune dont le plafond monte",
  "runeCapLine": "Niveau maximal {from} → {to}",
  "runeCapRaised": "{runeName} peut désormais monter jusqu'au niveau {level}.",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés.

- [ ] **Step 9: L'écran de draft et la modale**

In `lib/ui/screens/draft_screen.dart`, replace:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/services/level_up_reward_service.dart';
```

with:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../game/services/level_up_reward_service.dart';
```

Then replace:

```dart
import '../widgets/draft/draft_choice_labels.dart';
import '../widgets/relic_carousel/draft_card_reel.dart';
```

with:

```dart
import '../widgets/draft/draft_choice_labels.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/relic_carousel/draft_card_reel.dart';
```

Then replace:

```dart
    _choices = LevelUpRewardService.generateChoices(
      rewards: ref.read(gameDataLoaderProvider).requireValue.levelUpRewards,
      luck: ref.read(runProvider).heroStats.luck,
      forceLegendary: widget.forceLegendary,
      activePassive: ref.read(runProvider).activePassive,
    );
```

with:

```dart
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    final run = ref.read(runProvider);
    _choices = LevelUpRewardService.generateChoices(
      rewards: gameData.levelUpRewards,
      luck: run.heroStats.luck,
      forceLegendary: widget.forceLegendary,
      activePassive: run.activePassive,
      // *Transcendance* n'est tirée que si une rune du deck est à son
      // plafond effectif (spec P-43 E3, §4.8, A15).
      hasRaisableRune: ForgeRuneRules.raisableCaps(
        ref.read(deckProvider).masterDeck,
        gameData.forgeUpgrades,
        capBonus: run.runeCapBonus,
      ).isNotEmpty,
    );
```

Then replace:

```dart
  void _onChoiceSelected(
    DraftChoice choice,
    int index,
  ) {
```

with:

```dart
  /// La modale de *Transcendance* (spec P-43 E3, §4.8 ; D42(c), A15) : une
  /// ligne par rune que le deck porte à son plafond effectif — son nom, son
  /// plafond et le suivant —, non refermable ; le toucher relève ce plafond
  /// pour la run, le notifie, puis termine le draft. Sans candidate —
  /// impossible sous `requires: raisableRune` —, le draft se termine, comme
  /// le clonage sans option.
  void _showRuneCapModal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final candidates = ForgeRuneRules.raisableCaps(
      ref.read(deckProvider).masterDeck,
      ref.read(gameDataLoaderProvider).requireValue.forgeUpgrades,
      capBonus: ref.read(runProvider).runeCapBonus,
    );

    if (candidates.isEmpty) {
      _finishDraft(ref);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return GameDialog(
          showCloseButton: false,
          title: Text(l10n.runeCapTitle),
          content: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (:rune, :cap) in candidates)
                    ListTile(
                      leading: Text(
                        rune.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      title: Text(
                        rune.getName(locale),
                        style: const TextStyle(color: Colors.amber),
                      ),
                      subtitle: Text(
                        l10n.runeCapLine(cap, cap + 1),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      onTap: () {
                        ref.read(runProvider.notifier).raiseRuneCap(rune.id);
                        Navigator.of(ctx).pop();
                        context.showNotification(
                          l10n.runeCapRaised(rune.getName(locale), cap + 1),
                          type: NotificationType.success,
                        );
                        _finishDraft(ref);
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onChoiceSelected(
    DraftChoice choice,
    int index,
  ) {
```

Then replace:

```dart
      if (choice.isCloneOption) {
        _showCloneModal(context, ref);
        return;
      }
```

with:

```dart
      if (choice.isCloneOption) {
        _showCloneModal(context, ref);
        return;
      }
      if (choice.isRuneCapOption) {
        _showRuneCapModal(context, ref);
        return;
      }
```

- [ ] **Step 10: La mythique**

Create `assets/data/level_up_rewards/transcendence.json` (l'`id` déclaré, spec §3.3) :

```json
{
  "id": "transcendence",
  "name_fr": "Transcendance",
  "name_en": "Transcendence",
  "description_fr": "Le niveau maximal d'un type de rune de votre deck monte de 1, sur toutes vos cartes, pour toute la run",
  "description_en": "One rune type in your deck can climb one level higher on every card, for the rest of the run",
  "shortDescription_fr": "Plafond de rune +1",
  "shortDescription_en": "Rune cap +1",
  "effect": "raiseRuneCap",
  "requires": "raisableRune",
  "pool": "mythic",
  "displayOrder": 9,
  "values": {}
}
```

In `test/unit/real_bundle_load_test.dart`, replace `  test('le manifeste declare les 93 fichiers d entite, par categorie', () async {` with `  test('le manifeste declare les 94 fichiers d entite, par categorie', () async {`, and replace:

```dart
    expect(countUnder('assets/data/level_up_rewards/', 4), 8,
        reason: 'recompenses de niveau');
```

with:

```dart
    expect(countUnder('assets/data/level_up_rewards/', 4), 9,
        reason: 'recompenses de niveau');
```

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 93 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 7 evenements (dont le
    // Colporteur et le Remouleur) + 11 ameliorations de forge + 9 passifs +
    // 8 recompenses de niveau + 3 class.json + 6 cartes de classe + 4
    // enemy.json.
    expect(_entityFiles().length, 93,
        reason: '17 cartes neutres + 28 reliques + 7 evenements + 11 '
            'ameliorations de forge + 9 passifs + 8 recompenses de niveau + '
```

with:

```dart
  test('il y a bien 94 fichiers d entite', () {
    // 17 cartes neutres + 28 reliques (dont le Registre des primes, la
    // Sacoche du glaneur et la Meule, P-43 E3) + 7 evenements (dont le
    // Colporteur et le Remouleur) + 11 ameliorations de forge + 9 passifs +
    // 9 recompenses de niveau (dont Transcendance) + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 94,
        reason: '17 cartes neutres + 28 reliques + 7 evenements + 11 '
            'ameliorations de forge + 9 passifs + 9 recompenses de niveau + '
```

- [ ] **Step 11: Les tests passent**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/content_editor test/unit/forge_rune_rules_test.dart test/unit/run_state_persistence_test.dart test/unit/run_controller_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_reward_requirement_test.dart test/unit/level_up_rewards_catalog_test.dart test/unit/level_up_reward_values_test.dart test/tutorial test/widget/probabilities_dialog_test.dart test/widget/draft_screen_test.dart test/widget/draft_card_reel_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart`
Expected: PASS — `shipped_entities_round_trip_test.dart` réécrit `enduring.json`, `cheap.json` et `transcendence.json` à l'identique, `raiseRuneCap` et `raisableRune` admis par les énumérations que lit l'éditeur (spec §6) ; le tutoriel ne passe pas `hasRaisableRune` et ne tire jamais *Transcendance*.

- [ ] **Step 12: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1590: All tests passed!` (1577 + 2 + 1 + 2 + 1 + 1 + 1 + 3 + 2)

- [ ] **Step 13: Commit**

```bash
git add assets/data/level_up_rewards/transcendence.json assets/data/forge_upgrades/enduring.json assets/data/forge_upgrades/cheap.json lib/models/data/forge_upgrade_data.dart lib/services/content_editor/entity_descriptor.dart lib/game/controllers/run_controller.dart lib/game/services/forge_rune_rules.dart lib/models/data/level_up_reward_data.dart lib/game/services/level_up_reward_service.dart lib/game/controllers/run/player_stats_manager.dart lib/ui/screens/draft_screen.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/forge_rune_rules_test.dart test/unit/run_state_persistence_test.dart test/unit/run_controller_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_reward_requirement_test.dart test/unit/level_up_rewards_catalog_test.dart test/tutorial/tutorial_prose_test.dart test/widget/probabilities_dialog_test.dart test/widget/draft_screen_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart
git commit -F - <<'EOF'
feat(recompenses): Transcendance releve le plafond d un type de rune

Une mythique neuve, tiree seulement si le deck porte une rune a son
plafond effectif, ni sans plafond ni binaire. Sa modale propose ces
runes ; le choix releve de 1 leur plafond pour la run, sur toutes les
cartes. Enduring et cheap se declarent binaires : leur plafond ne monte
jamais.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 8: Le bonus de plafond, lu par les règles et les contrôleurs

A17, D72 (spec §3.8, §4.8, §8, « Le bonus de plafond » et « … lu par ses lecteurs ») : le plafond effectif d'une rune est `maxLevel + RunState.runeCapBonus[id]` ; il borne chaque endroit qui écrit un niveau. `ForgeUpgradeData.boundLevel` gagne `{int capBonus = 0}` ; `ForgeRuneRules.canSharpen`, `hasSharpenableRune`, `wellLevel` et `sharpenablePairs` gagnent `{Map<String, int> capBonus = const {}}`, lu par id de rune — **optionnels, à défaut neutre** : les appels de test d'aujourd'hui compilent tels quels (A17). `DeckNotifier.raiseRuneLevel` le gagne aussi. Chaque appelant de production de cette tâche passe le bonus de la run : `GoldManager` (le feu et le Puits, par les relais de `RunController`, qui le lisent sur leur propre état), les pré-forgées de la boutique, le tirage du boss « XP », la condition et l'action du *Rémouleur*. `dart analyze` ne désigne pas un appelant qui l'oublierait — le paramètre est optionnel — : ce sont les tests de cette tâche qui le gardent, chacun sur un `eco:1` sans bonus, puis après `raiseRuneCap('eco')`.

La fusion — `ForgeRuneRules.consolidate`, sa borne `_bounded` et `DeckNotifier.mergeCards` — gagne son bonus en Task 9, avec son seul appelant de production, l'écran de deck : posé ici, le paramètre de `mergeCards` n'aurait aucun appelant qui le passe, ni celui de `consolidate`, que seul `mergeCards` appelle (pas de code sans lecteur). Les écrans — la fusion de l'écran de deck, l'option du feu, la sélection, le dialogue, le Puits — et le nom d'une rune au-delà de son plafond de base (A18) sont la Task 9.

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart:323-330` (`boundLevel`)
- Modify: `lib/game/services/forge_rune_rules.dart` (`canSharpen`, `hasSharpenableRune`, `sharpenablePairs`, `wellLevel`)
- Modify: `lib/game/controllers/deck_controller.dart` (`raiseRuneLevel`)
- Modify: `lib/game/controllers/run/gold_manager.dart` (`sharpenRune`, `exchangeRune`) ; `lib/game/controllers/run_controller.dart:490-498` (les deux relais)
- Modify: `lib/game/controllers/shop_controller.dart:58-73` (`_rollRandomUpgrade`)
- Modify: `lib/game/controllers/reward_controller.dart` (`_sharpenRandomRunes`, Tasks 2 et 3)
- Modify: `lib/game/controllers/event_controller.dart` (`isChoiceSelectable`, le cas `sharpen_rune` — Task 5)
- Test: `test/unit/forge_upgrade_data_test.dart:523-547` ; `test/unit/forge_rune_rules_test.dart` ; `test/unit/deck_controller_test.dart` ; `test/unit/run_controller_test.dart:274-421` ; `test/unit/shop_controller_test.dart:344-389` ; `test/unit/reward_controller_test.dart` ; `test/unit/event_controller_test.dart` ; `test/widget/event_screen_test.dart`

**Interfaces:**
- Consumes: `RunState.runeCapBonus`, `RunController.raiseRuneCap` (Task 7).
- Produces (formes finales, spec §3.8, §4.7) :
  - `int ForgeUpgradeData.boundLevel(int requested, {int carried = 0, int capBonus = 0})` ;
  - `ForgeRuneRules.canSharpen(ForgeUpgradeData rune, int level, {Map<String, int> capBonus = const {}})`, `hasSharpenableRune(CardInstance card, Iterable<ForgeUpgradeData> catalog, {…})`, `wellLevel(ForgeUpgradeData received, int givenLevel, {…})`, `sharpenablePairs(Iterable<CardInstance> deck, Iterable<ForgeUpgradeData> catalog, {…})` ;
  - `bool DeckNotifier.raiseRuneLevel(String cardId, String runeId, {int levels = 1, Map<String, int> capBonus = const {}})` ;
  - `consolidate` et `mergeCards` gagnent le leur en Task 9.
  - `bool GoldManager.sharpenRune(String cardId, String runeId, {required Map<String, int> capBonus})`, `bool GoldManager.exchangeRune(String cardId, String givenId, String receivedId, {required Map<String, int> capBonus})` — requis : leur seul appelant, `RunController`, le passe toujours.

- [ ] **Step 1: Les tests des règles**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
    test('jamais negatif', () {
      expect(capped.boundLevel(1, carried: 3), 0);
    });
  });
```

with:

```dart
    test('jamais negatif', () {
      expect(capped.boundLevel(1, carried: 3), 0);
    });

    // Le plafond effectif (spec P-43 E3, §4.8, A17).
    test('le bonus de plafond s ajoute au plafond, et rien a une rune sans '
        'plafond', () {
      expect(capped.boundLevel(3, capBonus: 1), 3);
      expect(capped.boundLevel(1, carried: 2, capBonus: 1), 1);
      expect(capped.boundLevel(1, carried: 3, capBonus: 1), 0);
      expect(uncapped.boundLevel(3, carried: 5, capBonus: 1), 3);
    });
  });
```

In `test/unit/forge_rune_rules_test.dart`, replace (Task 2):

```dart
        [(first.uniqueId, 'sharp', 2), (last.uniqueId, 'sharp', 1)],
      );
    });
  });
```

with:

```dart
        [(first.uniqueId, 'sharp', 2), (last.uniqueId, 'sharp', 1)],
      );
    });

    test('canSharpen, hasSharpenableRune et sharpenablePairs lisent le bonus '
        'de plafond, par id de rune', () {
      final eco = _rune('eco', maxLevel: 1);
      final card = _cardWith(['eco:1']);

      expect(ForgeRuneRules.canSharpen(eco, 1), isFalse);
      expect(ForgeRuneRules.canSharpen(eco, 1, capBonus: {'eco': 1}), isTrue);
      expect(ForgeRuneRules.canSharpen(eco, 2, capBonus: {'eco': 1}), isFalse);
      expect(
          ForgeRuneRules.canSharpen(eco, 1, capBonus: {'quick': 1}), isFalse);
      expect(ForgeRuneRules.hasSharpenableRune(card, [eco]), isFalse);
      expect(
        ForgeRuneRules.hasSharpenableRune(card, [eco], capBonus: {'eco': 1}),
        isTrue,
      );
      expect(ForgeRuneRules.sharpenablePairs([card], [eco]), isEmpty);
      expect(
        [
          for (final pair in ForgeRuneRules.sharpenablePairs([card], [eco],
              capBonus: {'eco': 1}))
            (pair.rune.id, pair.level),
        ],
        [('eco', 1)],
      );
    });
  });
```

Then replace:

```dart
    test('wellLevel : borne par le plafond de la rune recue — Tranchant 9 '
        'contre Econome 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 9), 1);
    });
```

with:

```dart
    test('wellLevel : borne par le plafond de la rune recue — Tranchant 9 '
        'contre Econome 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 9), 1);
    });

    test('wellLevel : borne par le plafond effectif — Tranchant 3 contre '
        'Econome, 2 sous un bonus de 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 3), 1);
      expect(
        ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 3,
            capBonus: {'eco': 1}),
        2,
      );
    });
```

- [ ] **Step 2: Les tests des contrôleurs**

In `test/unit/deck_controller_test.dart`, in the group `DeckNotifier.raiseRuneLevel`, replace (Task 5):

```dart
      // Précis plafonne à 10 (D72).
      expect(runesOf(low), ['precise:3']);
      expect(runesOf(high), ['precise:10']);
    });
```

with:

```dart
      // Précis plafonne à 10 (D72).
      expect(runesOf(low), ['precise:3']);
      expect(runesOf(high), ['precise:10']);
    });

    // Le plafond effectif (spec P-43 E3, §4.7, §4.8 ; A17).
    test('monte une rune plafonnee sous un bonus de plafond, jusqu au plafond '
        'effectif', () {
      final card = seed(const ['eco:1']);

      expect(notifier.raiseRuneLevel(card.uniqueId, 'eco'), isFalse);
      expect(
          notifier.raiseRuneLevel(card.uniqueId, 'eco', capBonus: {'eco': 1}),
          isTrue);
      expect(runesOf(card), ['eco:2']);
      expect(
          notifier.raiseRuneLevel(card.uniqueId, 'eco', capBonus: {'eco': 1}),
          isFalse);
      expect(runesOf(card), ['eco:2']);
    });
```

In `test/unit/run_controller_test.dart`, replace:

```dart
      expect(run.sharpenRune(card.uniqueId, 'legacy'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['legacy:1']);
    });
  });
```

with:

```dart
      expect(run.sharpenRune(card.uniqueId, 'legacy'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['legacy:1']);
    });

    // Transcendance, lue par le feu (spec P-43 E3, §4.8, §8 ; A17).
    test('un plafond releve laisse affuter une rune plafonnee, au prix du feu',
        () {
      final card = seed(const ['eco:1'], gold: 100);
      expect(run.sharpenRune(card.uniqueId, 'eco'), isFalse);
      expect(container.read(inventoryProvider).gold, 100);

      run.raiseRuneCap('eco');
      expect(run.sharpenRune(card.uniqueId, 'eco'), isTrue);

      expect(container.read(inventoryProvider).gold, 50);
      expect(runesOf(card), ['eco:2']);
    });
  });
```

Then replace:

```dart
      expect(run.exchangeRune(card.uniqueId, 'burning', 'eco'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:3']);
    });
  });
}
```

with:

```dart
      expect(run.exchangeRune(card.uniqueId, 'burning', 'eco'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:3']);
    });

    // Transcendance, lue par le Puits (spec P-43 E3, §4.8, §8 ; A17) : les
    // deux tiers de 3 font 2.
    test('la rune recue entre au plafond effectif : Econome 1 sans bonus, 2 '
        'avec', () {
      final first = seed(const ['sharp:3'], gold: 1000);
      expect(run.exchangeRune(first.uniqueId, 'sharp', 'eco'), isTrue);
      expect(runesOf(first), ['eco:1']);

      run.raiseRuneCap('eco');
      final second = seed(const ['sharp:3'], gold: 1000);
      expect(run.exchangeRune(second.uniqueId, 'sharp', 'eco'), isTrue);
      expect(runesOf(second), ['eco:2']);
    });
  });
}
```

In `test/unit/shop_controller_test.dart`, replace:

```dart
      expect(rolled, {'capped:1'});
    });
```

with:

```dart
      expect(rolled, {'capped:1'});
    });

    // Transcendance, lue par les pré-forgées (spec P-43 E3, §4.8, §8 ; A17).
    test('une pre-forgee est bornee par le plafond effectif de la run', () {
      addTearDown(
        () => GameDataRegistry(
          enemies: const [],
          heroes: const [],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        ),
      );
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [
          ForgeUpgradeData(
            id: 'capped',
            nameEn: 'Capped',
            nameFr: 'Plafonnee',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            maxLevel: 1,
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));
      runController.raiseRuneCap('capped');

      // La boutique n'a pas de couture `Random` (`shop_controller.dart:156`) :
      // 200 étals, où les tirages à 2 et 3 sont bornés au plafond effectif.
      final rolled = <String>{};
      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          rolled.addAll(card.forgeUpgrades);
        }
      }

      expect(rolled, {'capped:1', 'capped:2'});
    });
```

In `test/unit/reward_controller_test.dart`, in the group `le boss XP`, replace (Task 3):

```dart
      test('la Meule ne monte rien hors du boss XP', () {
```

with:

```dart
      // Transcendance, lue par le tirage (spec P-43 E3, §4.8, §8 ; A17).
      test('un plafond releve rend une rune plafonnee de nouveau tirable', () {
        final capped = seedRare(const ['eco:1']);

        winAndCollect(xpBoss);
        expect(rewardController.state.sharpenedRunes, isEmpty);

        runController.raiseRuneCap('eco');
        winAndCollect(xpBoss);
        expect(rewardController.state.sharpenedRunes, [
          (cardUniqueId: capped.uniqueId, runeId: 'eco', level: 2),
        ]);
        expect(runesOf(capped), ['eco:2']);
      });

      test('la Meule ne monte rien hors du boss XP', () {
```

In `test/unit/event_controller_test.dart`, in the group `le Remouleur` (Task 5), replace:

```dart
    test('le Remouleur livre : ses actions', () {
```

with:

```dart
    // Transcendance, lue par la condition et par l'action (spec P-43 E3,
    // §4.8, §4.9 ; A17).
    test('le bonus de plafond rend le Remouleur possible sur une rune '
        'plafonnee, et l action la monte', () {
      final card = seedRare(const ['eco:1']);
      expect(events.isChoiceSelectable(hand(), runes), isFalse);

      run.raiseRuneCap('eco');
      expect(events.isChoiceSelectable(hand(), runes), isTrue);

      events.selectChoice(
        hand(),
        const [],
        sharpenTarget: (cardId: card.uniqueId, runeId: 'eco'),
      );
      expect(runesOf(card), ['eco:2']);
    });

    test('le Remouleur livre : ses actions', () {
```

In `test/widget/event_screen_test.dart`, in the group `le Remouleur` (Task 5), replace:

```dart
    testWidgets('annuler la selection ne resout rien, ne coute rien',
        (tester) async {
```

with:

```dart
    // Le bonus de plafond, lu par la condition que l'écran demande au
    // contrôleur (spec P-43 E3, §4.8, §4.9 ; A17).
    testWidgets('le bonus de plafond de la run rend le choix actif sur une '
        'rune plafonnee', (tester) async {
      final container = await pumpEvent(
        tester,
        eventOf('wandering_grinder'),
        deck: [
          CardInstance(
            data: shippedCard('strike_basic'),
            rarity: CardRarity.rare,
            forgeUpgrades: const ['eco:1'],
          ),
        ],
      );
      expect(enabled(tester, handRune), isFalse);

      container.read(runProvider.notifier).raiseRuneCap('eco');
      await tester.pump();

      expect(enabled(tester, handRune), isTrue);
    });

    testWidgets('annuler la selection ne resout rien, ne coute rien',
        (tester) async {
```

- [ ] **Step 3: Les lancer pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/forge_rune_rules_test.dart test/unit/deck_controller_test.dart test/unit/run_controller_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/unit/event_controller_test.dart test/widget/event_screen_test.dart`
Expected: FAIL — à la compilation (`capBonus` n'existe pas sur `boundLevel` ni sur les règles), puis, une fois les règles écrites, les cas des contrôleurs : `eco:1` reste plafonnée.

- [ ] **Step 4: La borne et les règles**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
  /// La borne de niveau (D72, D75) : [requested] sans plafond ; sinon ce
  /// qu'il reste sous `maxLevel` une fois comptés les [carried] niveaux que la
  /// carte porte déjà — jamais négatif (spec P-43 E1, §4.7).
  int boundLevel(int requested, {int carried = 0}) {
    final cap = maxLevel;
    if (cap == null) return requested;
    return max(0, min(requested, cap - carried));
  }
```

with:

```dart
  /// La borne de niveau (D72, D75) : [requested] sans plafond ; sinon ce
  /// qu'il reste sous le plafond effectif — `maxLevel` plus le [capBonus] de
  /// la run pour cette rune (spec P-43 E3, §4.8, A17) — une fois comptés les
  /// [carried] niveaux que la carte porte déjà ; jamais négatif (spec P-43
  /// E1, §4.7).
  int boundLevel(int requested, {int carried = 0, int capBonus = 0}) {
    final cap = maxLevel;
    if (cap == null) return requested;
    return max(0, min(requested, cap + capBonus - carried));
  }
```

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
  /// La rune [rune], portée au niveau [level], peut-elle monter d'un niveau ?
  /// Son `maxLevel` le dit, par la borne (D72).
  static bool canSharpen(ForgeUpgradeData rune, int level) =>
      rune.boundLevel(1, carried: level) >= 1;
```

with:

```dart
  /// La rune [rune], portée au niveau [level], peut-elle monter d'un niveau ?
  /// Son plafond effectif le dit — `maxLevel` plus [capBonus] pour son id —,
  /// par la borne (D72 ; spec P-43 E3, A17).
  static bool canSharpen(
    ForgeUpgradeData rune,
    int level, {
    Map<String, int> capBonus = const {},
  }) =>
      rune.boundLevel(1, carried: level, capBonus: capBonus[rune.id] ?? 0) >=
      1;
```

Then replace (Task 5):

```dart
  /// [card] porte-t-elle une rune que l'affûtage peut monter ? Une rune
  /// absente du [catalog] ne se monte pas. Lu par l'option du feu, par sa
  /// sélection (spec P-43 E2, A4) et par la condition du *Rémouleur*,
  /// `EventController.isChoiceSelectable` (spec P-43 E3, §4.9).
  static bool hasSharpenableRune(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
  ) =>
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null && canSharpen(rune, entry.value);
      });
```

with:

```dart
  /// [card] porte-t-elle une rune que l'affûtage peut monter, sous son
  /// plafond effectif ([capBonus], spec P-43 E3, A17) ? Une rune absente du
  /// [catalog] ne se monte pas. Lu par l'option du feu, par sa sélection
  /// (spec P-43 E2, A4) et par la condition du *Rémouleur*,
  /// `EventController.isChoiceSelectable` (spec P-43 E3, §4.9).
  static bool hasSharpenableRune(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) =>
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null &&
            canSharpen(rune, entry.value, capBonus: capBonus);
      });
```

Then replace (Task 2):

```dart
  /// Les paires (carte, rune) de [deck] dont la rune peut encore monter d'un
  /// niveau — celles que tire le boss « XP » (spec P-43 E3, §4.6, A14) —,
  /// dans l'ordre du deck puis des runes de chaque carte. Une rune absente du
  /// [catalog] ne se monte pas.
  static List<SharpenablePair> sharpenablePairs(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog,
  ) {
```

with:

```dart
  /// Les paires (carte, rune) de [deck] dont la rune peut encore monter d'un
  /// niveau sous son plafond effectif ([capBonus], A17) — celles que tire le
  /// boss « XP » (spec P-43 E3, §4.6, A14) —, dans l'ordre du deck puis des
  /// runes de chaque carte. Une rune absente du [catalog] ne se monte pas.
  static List<SharpenablePair> sharpenablePairs(
    Iterable<CardInstance> deck,
    Iterable<ForgeUpgradeData> catalog, {
    Map<String, int> capBonus = const {},
  }) {
```

Then replace:

```dart
        if (rune != null && canSharpen(rune, level)) {
          pairs.add((card: card, rune: rune, level: level));
        }
```

with:

```dart
        if (rune != null && canSharpen(rune, level, capBonus: capBonus)) {
          pairs.add((card: card, rune: rune, level: level));
        }
```

Then replace:

```dart
  /// niveau 1, puis bornés par le plafond de [received] (D72).
  static int wellLevel(ForgeUpgradeData received, int givenLevel) =>
      received.boundLevel((2 * givenLevel + 1) ~/ 3);
```

with:

```dart
  /// niveau 1, puis bornés par le plafond effectif de [received] — son
  /// `maxLevel` plus [capBonus] pour son id (D72 ; spec P-43 E3, A17).
  static int wellLevel(
    ForgeUpgradeData received,
    int givenLevel, {
    Map<String, int> capBonus = const {},
  }) =>
      received.boundLevel(
        (2 * givenLevel + 1) ~/ 3,
        capBonus: capBonus[received.id] ?? 0,
      );
```

- [ ] **Step 5: Le deck**

In `lib/game/controllers/deck_controller.dart`, replace (Task 5):

```dart
  /// d'abord — et les sources d'E3. Les niveaux montés sont bornés par le
  /// plafond de la rune (D72). Refuse — sans rien toucher — si la carte n'est
  /// pas dans le deck, ne porte pas la rune, si la rune est absente du
  /// registre, ou si son plafond ne la laisse pas monter ; sinon réécrit
  /// `id:n` en `id:n+k` à sa place, `k` le nombre borné. Rend vrai si la
  /// rune a monté.
  bool raiseRuneLevel(String cardId, String runeId, {int levels = 1}) {
```

with:

```dart
  /// d'abord — et les sources d'E3. Les niveaux montés sont bornés par le
  /// plafond effectif de la rune — `maxLevel` plus [capBonus] pour son id
  /// (D72, A17). Refuse — sans rien toucher — si la carte n'est pas dans le
  /// deck, ne porte pas la rune, si la rune est absente du registre, ou si
  /// son plafond ne la laisse pas monter ; sinon réécrit `id:n` en `id:n+k`
  /// à sa place, `k` le nombre borné. Rend vrai si la rune a monté.
  bool raiseRuneLevel(
    String cardId,
    String runeId, {
    int levels = 1,
    Map<String, int> capBonus = const {},
  }) {
```

Then replace `    final raised = rune.boundLevel(levels, carried: level);` with:

```dart
    final raised = rune.boundLevel(levels,
        carried: level, capBonus: capBonus[runeId] ?? 0);
```

- [ ] **Step 6: Le feu et le Puits**

In `lib/game/controllers/run/gold_manager.dart`, replace (Task 1):

```dart
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond, ou si l'or manque : l'écriture
  /// refusée ne coûte rien. L'écriture est celle des sources sans or,
  /// `DeckNotifier.raiseRuneLevel` (spec P-43 E3, §4.7, A13). Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(String cardId, String runeId) {
```

with:

```dart
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond effectif — `maxLevel` plus
  /// [capBonus] pour son id (A17) —, ou si l'or manque : l'écriture refusée
  /// ne coûte rien. L'écriture est celle des sources sans or,
  /// `DeckNotifier.raiseRuneLevel` (spec P-43 E3, §4.7, A13). Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(
    String cardId,
    String runeId, {
    required Map<String, int> capBonus,
  }) {
```

Then replace `        !ForgeRuneRules.canSharpen(rune, level)) {` with `        !ForgeRuneRules.canSharpen(rune, level, capBonus: capBonus)) {`.

Then replace:

```dart
    return ref.read(deckProvider.notifier).raiseRuneLevel(cardId, runeId);
```

with:

```dart
    return ref
        .read(deckProvider.notifier)
        .raiseRuneLevel(cardId, runeId, capBonus: capBonus);
```

Then replace:

```dart
  /// [receivedId] (D6, D39 ; spec P-43 E2, A5, §4.8) : la rune reçue prend
  /// sa place, au niveau `ForgeRuneRules.wellLevel`, contre
```

with:

```dart
  /// [receivedId] (D6, D39 ; spec P-43 E2, A5, §4.8) : la rune reçue prend
  /// sa place, au niveau `ForgeRuneRules.wellLevel` sous son plafond
  /// effectif ([capBonus], spec P-43 E3, A17), contre
```

Then replace:

```dart
  bool exchangeRune(String cardId, String givenId, String receivedId) {
```

with:

```dart
  bool exchangeRune(
    String cardId,
    String givenId,
    String receivedId, {
    required Map<String, int> capBonus,
  }) {
```

Then replace `            '$receivedId:${ForgeRuneRules.wellLevel(received, level)}',` with:

```dart
            '$receivedId:'
            '${ForgeRuneRules.wellLevel(received, level, capBonus: capBonus)}',
```

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  /// Affûte une rune d'une carte du deck, contre de l'or (spec P-43 E2,
  /// §4.7) ; voir `GoldManager.sharpenRune`.
  bool sharpenRune(String cardId, String runeId) =>
      _goldManager.sharpenRune(cardId, runeId);

  /// Échange au Puits une rune d'une carte du deck contre une autre, contre
  /// de l'or (spec P-43 E2, §4.8) ; voir `GoldManager.exchangeRune`.
  bool exchangeRune(String cardId, String givenId, String receivedId) =>
      _goldManager.exchangeRune(cardId, givenId, receivedId);
```

with:

```dart
  /// Affûte une rune d'une carte du deck, contre de l'or (spec P-43 E2,
  /// §4.7), sous le plafond effectif de la run (spec P-43 E3, A17) ; voir
  /// `GoldManager.sharpenRune`.
  bool sharpenRune(String cardId, String runeId) =>
      _goldManager.sharpenRune(cardId, runeId, capBonus: state.runeCapBonus);

  /// Échange au Puits une rune d'une carte du deck contre une autre, contre
  /// de l'or (spec P-43 E2, §4.8), sous le plafond effectif de la run (spec
  /// P-43 E3, A17) ; voir `GoldManager.exchangeRune`.
  bool exchangeRune(String cardId, String givenId, String receivedId) =>
      _goldManager.exchangeRune(
        cardId,
        givenId,
        receivedId,
        capBonus: state.runeCapBonus,
      );
```

- [ ] **Step 7: La boutique, le boss « XP », le *Rémouleur***

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
  /// s'il ne lui en reste aucune : la carte en reçoit une de moins. Son niveau
  /// est tiré 80 · 15 · 5 %, puis borné par le plafond de la rune (D72) ; la
  /// carte n'en porte aucun niveau, le prédicat refusant une rune portée.
```

with:

```dart
  /// s'il ne lui en reste aucune : la carte en reçoit une de moins. Son niveau
  /// est tiré 80 · 15 · 5 %, puis borné par le plafond effectif de la rune —
  /// son `maxLevel` plus le bonus de la run (D72 ; spec P-43 E3, A17) ; la
  /// carte n'en porte aucun niveau, le prédicat refusant une rune portée.
```

Then replace:

```dart
    return '${rune.id}:${rune.boundLevel(tier)}';
```

with:

```dart
    final capBonus = ref.read(runProvider).runeCapBonus[rune.id] ?? 0;
    return '${rune.id}:${rune.boundLevel(tier, capBonus: capBonus)}';
```

In `lib/game/controllers/reward_controller.dart`, replace (Task 3):

```dart
  /// au hasard parmi celles du deck dont la rune peut encore monter, montée
  /// d'un niveau, sans or ; chaque tirage voit le précédent. Sans paire,
  /// rien ne monte.
```

with:

```dart
  /// au hasard parmi celles du deck dont la rune est sous son plafond
  /// effectif — le bonus de la run compris (A17) —, montée d'un niveau, sans
  /// or ; chaque tirage voit le précédent. Sans paire, rien ne monte.
```

Then replace:

```dart
    final draws = GameConstants.bossXpRuneSharpens +
        ref.read(runProvider).extraBossRuneSharpens;
    for (var i = 0; i < draws; i++) {
      final pairs = ForgeRuneRules.sharpenablePairs(
        ref.read(deckProvider).masterDeck,
        catalog,
      );
      if (pairs.isEmpty) break;
      final pair = pairs[rng.nextInt(pairs.length)];
      if (deck.raiseRuneLevel(pair.card.uniqueId, pair.rune.id)) {
```

with:

```dart
    final run = ref.read(runProvider);
    final draws =
        GameConstants.bossXpRuneSharpens + run.extraBossRuneSharpens;
    for (var i = 0; i < draws; i++) {
      final pairs = ForgeRuneRules.sharpenablePairs(
        ref.read(deckProvider).masterDeck,
        catalog,
        capBonus: run.runeCapBonus,
      );
      if (pairs.isEmpty) break;
      final pair = pairs[rng.nextInt(pairs.length)];
      if (deck.raiseRuneLevel(
        pair.card.uniqueId,
        pair.rune.id,
        capBonus: run.runeCapBonus,
      )) {
```

In `lib/game/controllers/event_controller.dart`, replace (Task 5):

```dart
  /// lus sur la run et l'inventaire, `hasTradedRelic` sur la relique visée,
  /// `hasSharpenableRune` sur le deck et [runeCatalog], comme l'option du feu
  /// (`rest_screen.dart`). L'écran l'appelle pour chaque bouton de choix,
  /// avec le catalogue des runes du registre.
  bool isChoiceSelectable(
    EventChoice choice,
    Iterable<ForgeUpgradeData> runeCatalog,
  ) {
    final hero = ref.read(runProvider).heroStats;
    return choice.isSelectable(
      hero.currentPv,
      ref.read(inventoryProvider).gold,
      hero.maxPv,
      hasTradedRelic: state.tradedRelic != null,
      hasSharpenableRune: ref.read(deckProvider).masterDeck.any(
          (card) => ForgeRuneRules.hasSharpenableRune(card, runeCatalog)),
    );
  }
```

with:

```dart
  /// lus sur la run et l'inventaire, `hasTradedRelic` sur la relique visée,
  /// `hasSharpenableRune` sur le deck et [runeCatalog], sous le plafond
  /// effectif de la run (A17), comme l'option du feu (`rest_screen.dart`).
  /// L'écran l'appelle pour chaque bouton de choix, avec le catalogue des
  /// runes du registre.
  bool isChoiceSelectable(
    EventChoice choice,
    Iterable<ForgeUpgradeData> runeCatalog,
  ) {
    final run = ref.read(runProvider);
    final hero = run.heroStats;
    return choice.isSelectable(
      hero.currentPv,
      ref.read(inventoryProvider).gold,
      hero.maxPv,
      hasTradedRelic: state.tradedRelic != null,
      hasSharpenableRune: ref.read(deckProvider).masterDeck.any(
            (card) => ForgeRuneRules.hasSharpenableRune(
              card,
              runeCatalog,
              capBonus: run.runeCapBonus,
            ),
          ),
    );
  }
```

Then replace:

```dart
            ref.read(deckProvider.notifier).raiseRuneLevel(
                  sharpenTarget.cardId,
                  sharpenTarget.runeId,
                  levels: action.value as int,
                );
```

with:

```dart
            ref.read(deckProvider.notifier).raiseRuneLevel(
                  sharpenTarget.cardId,
                  sharpenTarget.runeId,
                  levels: action.value as int,
                  capBonus: runController.currentState.runeCapBonus,
                );
```

- [ ] **Step 8: Les tests passent**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/forge_rune_rules_test.dart test/unit/deck_controller_test.dart test/unit/decoupled_forge_test.dart test/unit/run_controller_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/unit/event_controller_test.dart test/widget/event_screen_test.dart`
Expected: PASS — et les appels d'aujourd'hui, sans bonus (`forge_rune_rules_test.dart`, `forge_upgrade_data_test.dart`, `deck_controller_test.dart`, `decoupled_forge_test.dart`), inchangés.

- [ ] **Step 9: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e "boundLevel(" -e "consolidate(" -e "canSharpen(" -e "hasSharpenableRune(" -e "wellLevel(" -e "sharpenablePairs(" -e "raiseRuneLevel(" -- lib/game`
Expected: chaque appel de production sous `lib/game/` passe un `capBonus` — sauf ceux qui, dans `forge_rune_rules.dart`, relaient le paramètre qu'ils reçoivent (`canSharpen` dans `hasSharpenableRune` et `sharpenablePairs`), la déclaration de chaque fonction, et les deux appels de la fusion, `boundLevel(tier)` dans `_bounded` et `consolidate(` dans `mergeCards`, que la Task 9 complète. Les écrans sont la Task 9.

Run: `flutter test`
Expected: `+1600: All tests passed!` (1590 + 1 + 2 + 1 + 2 + 1 + 1 + 1 + 1)

- [ ] **Step 10: Commit**

```bash
git add lib/models/data/forge_upgrade_data.dart lib/game/services/forge_rune_rules.dart lib/game/controllers/deck_controller.dart lib/game/controllers/run/gold_manager.dart lib/game/controllers/run_controller.dart lib/game/controllers/shop_controller.dart lib/game/controllers/reward_controller.dart lib/game/controllers/event_controller.dart test/unit/forge_upgrade_data_test.dart test/unit/forge_rune_rules_test.dart test/unit/deck_controller_test.dart test/unit/run_controller_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/unit/event_controller_test.dart test/widget/event_screen_test.dart
git commit -F - <<'EOF'
feat(forge): les controleurs lisent le plafond releve par Transcendance

La borne, les pre-forgees, le feu, le Puits, le boss XP et le Remouleur
lisent le bonus de plafond de la run, par id de rune. Le parametre reste
optionnel pour les appels sans bonus ; chaque appelant de jeu le passe,
et un test le garde sur une rune plafonnee, sans bonus puis apres. La
fusion le recoit avec l ecran de deck.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 9: Le bonus de plafond, lu par la fusion et les écrans — et le nom d'une rune au-delà de son plafond

A17, A18 (spec §4.8, §8, « Le bonus de plafond, lu par ses lecteurs ») : la fusion gagne son bonus — `ForgeRuneRules.consolidate`, sa borne `_bounded` et `DeckNotifier.mergeCards`, dont l'écran de deck est le seul appelant de production : le paramètre naît ici avec lui (pas de code sans lecteur) — ; les écrans qui jugent ou écrivent un niveau passent `RunState.runeCapBonus` aux règles — l'écran de deck à `mergeCards`, l'option du feu et la sélection d'affûtage (dans ses deux modes, le feu et le *Rémouleur*) à `hasSharpenableRune`, le dialogue d'affûtage à `canSharpen`, le Puits à `wellLevel`. Chacun est gardé par un test de widget sur un `eco:1`, sans bonus puis après `raiseRuneCap('eco')` : sans lui, *Transcendance* serait sans effet au feu comme à l'événement (constat n° 2 du tour 3). `ForgeUpgradeData.nameAt` écrit le niveau dès qu'il dépasse 1 : un `eco:2` s'affiche « Économe 2 » (A18).

**Files:**
- Modify: `lib/game/services/forge_rune_rules.dart:14-42` (`consolidate`, `_bounded`)
- Modify: `lib/game/controllers/deck_controller.dart:292-322` (`mergeCards`)
- Modify: `lib/ui/screens/deck_screen.dart:1-20` (import), `:238-246` (`_performMerge`)
- Modify: `lib/ui/screens/rest_screen.dart:126-131`
- Modify: `lib/ui/screens/rest_card_selection_screen.dart:1-14` (import), `:68-69`, `:118-119`
- Modify: `lib/ui/widgets/forge/sharpen_rune_dialog.dart` (`build`, `row` — Task 5)
- Modify: `lib/ui/screens/forge_fusion_screen.dart:250` (`_optionRow`)
- Modify: `lib/models/data/forge_upgrade_data.dart:295-300` (`nameAt`)
- Test: `test/unit/forge_rune_rules_test.dart` (un cas, après « une rune absente du registre n a pas de plafond »), `test/widget/deck_screen_test.dart`, `test/widget/rest_screen_test.dart`, `test/widget/rest_card_selection_screen_test.dart`, `test/widget/sharpen_rune_dialog_test.dart`, `test/widget/forge_fusion_screen_test.dart:173-191` (un cas après), `test/unit/forge_upgrade_data_test.dart:440-449` (réécrit)

**Interfaces:**
- Consumes: les signatures de la Task 8, dont `int ForgeUpgradeData.boundLevel(int requested, {int carried = 0, int capBonus = 0})` ; `RunController.raiseRuneCap` (Task 7).
- Produces: `static List<String> ForgeRuneRules.consolidate(Iterable<String> runes, {Map<String, int> capBonus = const {}})` ; `CardInstance? DeckNotifier.mergeCards(List<String> selectedIds, {Map<String, int> capBonus = const {}})` — leurs formes finales (spec §3.8) ; `String ForgeUpgradeData.nameAt(int level, String locale)` — le niveau écrit dès que `maxLevel` n'est pas 1 **ou** que `level` dépasse 1.

- [ ] **Step 1: Les tests**

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
    test('une rune absente du registre n a pas de plafond', () {
      expect(ForgeRuneRules.consolidate(['legacy:1', 'legacy:1']), ['legacy:2']);
    });
```

with:

```dart
    test('une rune absente du registre n a pas de plafond', () {
      expect(ForgeRuneRules.consolidate(['legacy:1', 'legacy:1']), ['legacy:2']);
    });

    // Le bonus de plafond de Transcendance (spec P-43 E3, §4.8, A17).
    test('un bonus de plafond borne la somme au plafond effectif', () {
      expect(ForgeRuneRules.consolidate(['eco:1', 'eco:1', 'eco:1']),
          ['eco:1']);
      expect(
        ForgeRuneRules.consolidate(['eco:1', 'eco:1', 'eco:1'],
            capBonus: {'eco': 1}),
        ['eco:2'],
      );
    });
```

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
  // La regle des infobulles, que suivent la ligne de rune et le dialogue de
  // fusion (spec P-43 E2, §4.11).
  test('nameAt n ecrit le niveau que d une rune a plusieurs niveaux', () {
    final sharp = ForgeUpgradeData.fromJson(_json({'name_fr': 'Tranchant'}));
    final eco = ForgeUpgradeData.fromJson(
        _json({'name_fr': 'Économe', 'maxLevel': 1}));
    expect(sharp.nameAt(1, 'fr'), 'Tranchant 1');
    expect(sharp.nameAt(3, 'fr'), 'Tranchant 3');
    expect(eco.nameAt(1, 'fr'), 'Économe');
  });
```

with:

```dart
  // La regle des infobulles, que suivent la ligne de rune et le dialogue de
  // fusion (spec P-43 E2, §4.11) ; une rune de plafond 1 montee au-dela par
  // Transcendance ecrit son niveau (spec P-43 E3, A18).
  test('nameAt ecrit le niveau d une rune a plusieurs niveaux, ou montee '
      'au-dela de 1', () {
    final sharp = ForgeUpgradeData.fromJson(_json({'name_fr': 'Tranchant'}));
    final eco = ForgeUpgradeData.fromJson(
        _json({'name_fr': 'Économe', 'maxLevel': 1}));
    expect(sharp.nameAt(1, 'fr'), 'Tranchant 1');
    expect(sharp.nameAt(3, 'fr'), 'Tranchant 3');
    expect(eco.nameAt(1, 'fr'), 'Économe');
    expect(eco.nameAt(2, 'fr'), 'Économe 2');
  });
```

In `test/widget/deck_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
```

with:

```dart
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
```

Then replace the end of the file:

```dart
    expect(find.byType(UiCard), findsNWidgets(2));
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });
}
```

with:

```dart
    expect(find.byType(UiCard), findsNWidgets(2));
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });

  // Transcendance, lue par la fusion de l'écran de deck (spec P-43 E3, §4.8,
  // §8 ; A17) : sans le bonus de la run, la somme serait bornée à 1.
  testWidgets('trois rares a Econome 1 fusionnent en epique a Econome 2 sous '
      'le plafond releve de la run', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['eco:1'],
        ),
    ]);
    container.read(runProvider.notifier).raiseRuneCap('eco');

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();
    // L'offre de la carte fusionnée — Tranchant au moins s'y offre.
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    final merged = container.read(deckProvider).masterDeck.single;
    expect(merged.rarity, CardRarity.epic);
    expect(ForgeUpgradeData.levelsOf(merged.forgeUpgrades)['eco'], 2);
    await settle(tester);
  });
}
```

In `test/widget/rest_screen_test.dart`, replace:

```dart
  testWidgets(
    'Tapping Heal restores 30% of max HP and shows a success notification',
```

with:

```dart
  // Transcendance, lue par l'option du feu (spec P-43 E3, §4.8, §8 ; A17).
  testWidgets('AFFUTER s active sur une rune plafonnee quand la run releve '
      'son plafond', (WidgetTester tester) async {
    final container = await pumpRestScreen(
      tester,
      registry: shippedRegistry(),
      deck: [
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.rare,
          forgeUpgrades: const ['eco:1'],
        ),
      ],
    );
    expect(find.text('Aucune rune de votre deck ne peut gagner de niveau.'),
        findsOneWidget);

    container.read(runProvider.notifier).raiseRuneCap('eco');
    await tester.pumpAndSettle();

    expect(find.text('Aucune rune de votre deck ne peut gagner de niveau.'),
        findsNothing);
    await tester.tap(find.text('AFFÛTER'));
    await tester.pumpAndSettle();
    expect(find.byType(RestCardSelectionScreen), findsOneWidget);
  });

  testWidgets(
    'Tapping Heal restores 30% of max HP and shows a success notification',
```

In `test/widget/rest_card_selection_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
```

with:

```dart
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
```

Then replace (Task 5):

```dart
    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(find.text('Choisir'), findsOneWidget);
    expect(find.textContaining('Affûter —'), findsNothing);
  });
}
```

with:

```dart
    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(find.text('Choisir'), findsOneWidget);
    expect(find.textContaining('Affûter —'), findsNothing);
  });

  // Transcendance, lue par la sélection dans ses deux modes — le feu et le
  // Rémouleur (spec P-43 E3, §4.8, §8 ; A17 ; constat n° 2 du tour 3).
  for (final isFree in [false, true]) {
    testWidgets('${isFree ? 'sans or' : 'au feu'}, une rune plafonnee se '
        'grise, puis ouvre le dialogue sur Niveau 1 -> 2 sous un plafond '
        'releve', (tester) async {
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['eco:1'],
      );
      final container =
          await _pumpSharpenSelection(tester, card, isFree: isFree);

      expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(find.byType(SharpenRuneDialog), findsNothing);
      expect(container.read(notificationProvider).last.message,
          'Aucune rune de cette carte ne peut gagner de niveau.');

      container.read(runProvider.notifier).raiseRuneCap('eco');
      await tester.pumpAndSettle();

      expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isFalse);
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(find.byType(SharpenRuneDialog), findsOneWidget);
      expect(find.text('Niveau 1 → 2'), findsOneWidget);

      await _settleNotifications(tester);
    });
  }
}
```

In `test/widget/sharpen_rune_dialog_test.dart`, replace:

```dart
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
```

with:

```dart
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
```

Then replace (Task 5):

```dart
    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.text('Choisir'), findsNothing);
  });
}
```

with:

```dart
    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.text('Choisir'), findsNothing);
  });

  // Transcendance, lue par le dialogue (spec P-43 E3, §4.8, §8 ; A17).
  testWidgets('une rune plafonnee dit Niveau maximal, puis Niveau 1 -> 2 '
      'sous un plafond releve', (tester) async {
    final container =
        await _openDialog(tester, _rareStrike(const ['eco:1']), gold: 1000);
    expect(_button(tester, 'Niveau maximal').onPressed, isNull);

    container.read(runProvider.notifier).raiseRuneCap('eco');
    await tester.pump();

    expect(find.text('Niveau 1 → 2'), findsOneWidget);
    expect(_button(tester, 'Affûter — 50 or').onPressed, isNotNull);
  });
}
```

In `test/widget/forge_fusion_screen_test.dart`, replace:

```dart
    expect(find.text('Reçue au niveau 2'), findsOneWidget);
    expect(find.text('Reçue au niveau 1'), findsOneWidget);
  });
```

with:

```dart
    expect(find.text('Reçue au niveau 2'), findsOneWidget);
    expect(find.text('Reçue au niveau 1'), findsOneWidget);
  });

  // Transcendance, lue par le Puits (spec P-43 E3, §4.8, §8 ; A17).
  testWidgets('sous un plafond releve, Econome est recue au niveau 2',
      (tester) async {
    final container =
        await pumpWell(tester, deck: [strike(const ['sharp:3'])]);
    container.read(runProvider.notifier).raiseRuneCap('eco');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tranchant 3'));
    await tester.pumpAndSettle();

    // Brûlant et Économe aux deux tiers de 3 : 2 l'une et l'autre, Économe
    // sous son plafond effectif.
    expect(find.text('Reçue au niveau 2'), findsNWidgets(2));
    expect(find.text('Reçue au niveau 1'), findsNothing);
  });
```

- [ ] **Step 2: Les lancer pour les voir échouer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/forge_upgrade_data_test.dart test/widget/deck_screen_test.dart test/widget/rest_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/widget/forge_fusion_screen_test.dart`
Expected: FAIL — à la compilation, `consolidate` ne connaît pas `capBonus` ; puis `Économe 2` attendu, `Économe` rendu ; `eco` reste à 1 après la fusion ; la carte reste grisée, le dialogue dit « Niveau maximal », le Puits « Reçue au niveau 1 » : les écrans ne lisent pas encore le bonus.

- [ ] **Step 3: Le nom**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
  /// Le nom de la rune au niveau [level] : le niveau ne s'écrit que si la
  /// rune en a plus d'un (`maxLevel` autre que 1). La règle des infobulles
  /// (spec P-43 E1, §5.2), que suivent aussi la ligne de rune et le dialogue
  /// de fusion (spec P-43 E2, §4.11).
  String nameAt(int level, String locale) =>
      maxLevel == 1 ? getName(locale) : '${getName(locale)} $level';
```

with:

```dart
  /// Le nom de la rune au niveau [level] : le niveau s'écrit dès que la rune
  /// en a plus d'un (`maxLevel` autre que 1) ou qu'elle dépasse 1 — montée
  /// au-delà de son plafond de base par le bonus de *Transcendance* (spec
  /// P-43 E3, A18). La règle des infobulles (spec P-43 E1, §5.2), que suivent
  /// aussi la ligne de rune et le dialogue de fusion (spec P-43 E2, §4.11).
  String nameAt(int level, String locale) => maxLevel == 1 && level <= 1
      ? getName(locale)
      : '${getName(locale)} $level';
```

- [ ] **Step 4: La fusion**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// leurs niveaux s'additionnent, bornés par son `maxLevel` — le surplus se
  /// perd, une rune de plafond 1 reste au niveau 1 (spec P-43 E1, A9 ; spec
  /// P-43 E2, §4.6). Une référence mal formée ou de niveau nul est
  /// ignorée. Deux runes qui s'excluent (`excludesRunes`, dans un sens ou
  /// l'autre) ne sont jamais réunies : la première arrivée est gardée, car la
  /// fusion ne doit pas rouvrir ce que ferment D44, D51 et D61.
  static List<String> consolidate(Iterable<String> runes) {
```

with:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// leurs niveaux s'additionnent, bornés par son plafond effectif —
  /// `maxLevel` plus [capBonus] pour son id (spec P-43 E3, A17) — : le
  /// surplus se perd, une rune de plafond 1 sans bonus reste au niveau 1
  /// (spec P-43 E1, A9 ; spec P-43 E2, §4.6). Une référence mal formée ou de
  /// niveau nul est ignorée. Deux runes qui s'excluent (`excludesRunes`, dans
  /// un sens ou l'autre) ne sont jamais réunies : la première arrivée est
  /// gardée, car la fusion ne doit pas rouvrir ce que ferment D44, D51 et D61.
  static List<String> consolidate(
    Iterable<String> runes, {
    Map<String, int> capBonus = const {},
  }) {
```

Then replace `      result.add('$id:${_bounded(id, tier)}');` with `      result.add('$id:${_bounded(id, tier, capBonus[id] ?? 0)}');`.

Then replace:

```dart
  /// [tier] borné par le plafond de la rune [id] (D72) ; une rune absente du
  /// registre n'en a pas.
  static int _bounded(String id, int tier) =>
      ForgeUpgradeData.getById(id)?.boundLevel(tier) ?? tier;
```

with:

```dart
  /// [tier] borné par le plafond effectif de la rune [id] (D72, A17) ; une
  /// rune absente du registre n'en a pas.
  static int _bounded(String id, int tier, int capBonus) =>
      ForgeUpgradeData.getById(id)?.boundLevel(tier, capBonus: capBonus) ??
      tier;
```

In `lib/game/controllers/deck_controller.dart`, replace:

```dart
  /// P-43 E2, §4.6) : `ForgeRuneRules.consolidate` additionne les niveaux
  /// d'une même rune, bornés par son plafond, et écarte une rune exclue par
  /// une rune gardée avant elle ; aucun plafond de runes par carte. Rend la
  /// carte créée — l'écran de deck tire sur elle l'offre de runes (§4.5) —,
  /// ou `null` si la fusion est refusée.
  CardInstance? mergeCards(List<String> selectedIds) {
```

with:

```dart
  /// P-43 E2, §4.6) : `ForgeRuneRules.consolidate` additionne les niveaux
  /// d'une même rune, bornés par son plafond effectif — [capBonus], le bonus
  /// de la run que passe l'écran de deck (spec P-43 E3, A17) —, et écarte une
  /// rune exclue par une rune gardée avant elle ; aucun plafond de runes par
  /// carte. Rend la carte créée — l'écran de deck tire sur elle l'offre de
  /// runes (§4.5) —, ou `null` si la fusion est refusée.
  CardInstance? mergeCards(
    List<String> selectedIds, {
    Map<String, int> capBonus = const {},
  }) {
```

Then replace:

```dart
      forgeUpgrades: ForgeRuneRules.consolidate(
        selectedCards.expand((card) => card.forgeUpgrades),
      ),
```

with:

```dart
      forgeUpgrades: ForgeRuneRules.consolidate(
        selectedCards.expand((card) => card.forgeUpgrades),
        capBonus: capBonus,
      ),
```

`dart analyze` reste propre : le paramètre de `mergeCards` a son appelant à l'étape suivante, l'écran de deck.

- [ ] **Step 5: Les écrans**

In `lib/ui/screens/deck_screen.dart`, replace:

```dart
import '../../game/controllers/deck_controller.dart';
```

with:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/run_controller.dart';
```

Then replace:

```dart
    final merged = widget.ref.read(deckProvider.notifier).mergeCards(
          widget.duplicates
              .where((c) => _selectedCardIds.contains(c.uniqueId))
              .map((c) => c.uniqueId)
              .toList(),
        );
```

with:

```dart
    final merged = widget.ref.read(deckProvider.notifier).mergeCards(
          widget.duplicates
              .where((c) => _selectedCardIds.contains(c.uniqueId))
              .map((c) => c.uniqueId)
              .toList(),
          // Le plafond effectif de la run (spec P-43 E3, §4.8, A17).
          capBonus: widget.ref.read(runProvider).runeCapBonus,
        );
```

In `lib/ui/screens/rest_screen.dart`, replace:

```dart
    // L'option d'affûtage se montre inactive, avec son motif, quand aucune
    // rune du deck ne peut monter (spec P-43 E2, A4).
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final canSharpen = ref
        .watch(deckProvider)
        .masterDeck
        .any((card) => ForgeRuneRules.hasSharpenableRune(card, catalog));
```

with:

```dart
    // L'option d'affûtage se montre inactive, avec son motif, quand aucune
    // rune du deck ne peut monter (spec P-43 E2, A4) sous le plafond effectif
    // de la run (spec P-43 E3, A17).
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final canSharpen = ref.watch(deckProvider).masterDeck.any(
          (card) => ForgeRuneRules.hasSharpenableRune(
            card,
            catalog,
            capBonus: runState.runeCapBonus,
          ),
        );
```

In `lib/ui/screens/rest_card_selection_screen.dart`, replace:

```dart
import '../../game/controllers/deck_controller.dart';
```

with:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/run_controller.dart';
```

Then replace:

```dart
    final deck = ref.watch(deckProvider).masterDeck;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
```

with:

```dart
    final deck = ref.watch(deckProvider).masterDeck;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    // Le plafond effectif de la run (spec P-43 E3, §4.8, A17), au feu comme
    // au *Rémouleur*.
    final capBonus = ref.watch(runProvider).runeCapBonus;
```

Then replace:

```dart
                        final sharpenable = isSharpen &&
                            ForgeRuneRules.hasSharpenableRune(card, catalog);
```

with:

```dart
                        final sharpenable = isSharpen &&
                            ForgeRuneRules.hasSharpenableRune(
                              card,
                              catalog,
                              capBonus: capBonus,
                            );
```

In `lib/ui/widgets/forge/sharpen_rune_dialog.dart`, replace:

```dart
    final gold = ref.watch(inventoryProvider).gold;
```

with:

```dart
    final gold = ref.watch(inventoryProvider).gold;
    // Le plafond effectif de la run (spec P-43 E3, §4.8, A17).
    final capBonus = ref.watch(runProvider).runeCapBonus;
```

Then replace `      final sharpenable = ForgeRuneRules.canSharpen(rune, level);` with:

```dart
      final sharpenable =
          ForgeRuneRules.canSharpen(rune, level, capBonus: capBonus);
```

In `lib/ui/screens/forge_fusion_screen.dart`, replace:

```dart
    final level = ForgeRuneRules.wellLevel(received, givenLevel);
```

with:

```dart
    // Sous le plafond effectif de la run (spec P-43 E3, §4.8, A17).
    final level = ForgeRuneRules.wellLevel(
      received,
      givenLevel,
      capBonus: ref.watch(runProvider).runeCapBonus,
    );
```

`_optionRow` est appelé par `build` : `ref.watch` y est permis.

- [ ] **Step 6: Les tests passent**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/forge_upgrade_data_test.dart test/unit/deck_controller_test.dart test/unit/decoupled_forge_test.dart test/widget/deck_screen_test.dart test/widget/rest_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/widget/forge_fusion_screen_test.dart test/widget/event_screen_test.dart`
Expected: PASS — et les appels de `consolidate` et de `mergeCards` sans bonus (`forge_rune_rules_test.dart`, `deck_controller_test.dart`, `decoupled_forge_test.dart`), inchangés.

- [ ] **Step 7: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n "runeCapBonus" -- lib/ui`
Expected: des lignes dans `deck_screen.dart`, `rest_screen.dart`, `rest_card_selection_screen.dart`, `forge_fusion_screen.dart`, `draft_screen.dart` (Task 7, deux) et `widgets/forge/sharpen_rune_dialog.dart` — chaque écran qui juge ou écrit un niveau.

Run: `git grep -n -A6 -e "boundLevel(" -e "consolidate(" -e "mergeCards(" -- lib/game lib/ui`
Expected: hors la déclaration de chaque fonction, chaque appel de production porte son argument `capBonus:` dans les lignes affichées — sur la ligne même (`_bounded`, `canSharpen`, la boutique) ou quelques lignes plus bas (`wellLevel`, `raiseRuneLevel`, `consolidate` dans `mergeCards`, `mergeCards` dans `deck_screen.dart`) : la fusion est le dernier écrivain de niveau à le recevoir.

Run: `flutter test`
Expected: `+1607: All tests passed!` (1600 + 1 + 1 + 1 + 2 + 1 + 1)

- [ ] **Step 8: Commit**

```bash
git add lib/game/services/forge_rune_rules.dart lib/game/controllers/deck_controller.dart lib/models/data/forge_upgrade_data.dart lib/ui/screens/deck_screen.dart lib/ui/screens/rest_screen.dart lib/ui/screens/rest_card_selection_screen.dart lib/ui/widgets/forge/sharpen_rune_dialog.dart lib/ui/screens/forge_fusion_screen.dart test/unit/forge_rune_rules_test.dart test/unit/forge_upgrade_data_test.dart test/widget/deck_screen_test.dart test/widget/rest_screen_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/sharpen_rune_dialog_test.dart test/widget/forge_fusion_screen_test.dart
git commit -F - <<'EOF'
feat(forge): les ecrans lisent le plafond releve, et le nom dit le niveau

La fusion recoit le bonus de plafond de la run avec son seul appelant,
l ecran de deck ; l option du feu, la selection dans ses deux modes, le
dialogue d affutage et le Puits le passent aussi. Une rune de plafond 1
montee au-dela affiche son niveau : Econome 2.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 10: Les seuils de *Bénédiction* et de *Flux de Mana* en donnée, et l'effet affiché de la Maîtrise

D43, D60, A23, A24, C1.2, C2.6 (spec §3.6, §4.11, §5.2) : *Bénédiction* lit sa tranche dans `blessing.json`, `"threshold": 5` — la constante `_armorPerTranche` disparaît, un seuil sous 1 ne fait rien (A24). Le bloc `mastery` gagne `floor`, déclaré sur *Flux de Mana* seulement (`"floor": 2`) : `PassiveData.withMastery` l'applique, le plancher codé de `ManaFluxPassive` (inerte) disparaît (A23). `floor` est refusé au chargement sur un `perPoint` qui n'est pas négatif, ou au-dessus de la valeur de base du paramètre. `PassiveMastery.describe` cède la place à `PassiveData.describeMastery(locale, from:, to:)` : `{amount}` dit l'écart **effectif** du paramètre, plancher compris, et la méthode rend `null` quand rien ne change. Ses trois lecteurs : la fiche des stats (de 0 à la Maîtrise effective — aucune ligne si rien ne change), l'écran de sélection (de 0 à 1), la carte d'*Affinité* (de la Maîtrise effective à la même plus le gain tiré — sans changement, le repli d'`affinity.json`). Pour la carte d'*Affinité*, `LevelUpRewardData.describe` et `DraftChoiceLabels.getChoiceDescription` gagnent `currentMastery`, **requis** (C1.2) : `dart analyze` désigne chacun des quatre appelants de production.

**Files:**
- Modify: `assets/data/passives/blessing.json`, `assets/data/passives/mana_flux.json`
- Modify: `lib/models/data/passive_data.dart:1-3` (import), `:19-71` (`PassiveMastery`), `:90-92` (doc de `threshold`), `:131-146` (`withMastery`), `:166-204` (`fromJson`)
- Modify: `lib/game/systems/passives/passive_strategies.dart:99-118` (`ManaFluxPassive`), `:136-157` (`BlessingPassive`)
- Modify: `lib/models/data/level_up_reward_data.dart:132-150` (`describe`)
- Modify: `lib/ui/widgets/draft/draft_choice_labels.dart:39-56`
- Modify: `lib/ui/screens/draft_screen.dart:136-138` (`build`), `:253`, `:346`, `:472`
- Modify: `lib/tutorial/widgets/tutorial_draft_widget.dart:89-93`
- Modify: `lib/ui/widgets/map/dialogs/stats_dialog.dart:55-60`
- Modify: `lib/ui/widgets/class_passive_list.dart:181`, `:240-252`
- Test: `test/unit/passive_data_test.dart:144-160`, `:200-215`, un groupe neuf ; `test/unit/passives_mage_test.dart:59-70`, `:327-356`, un cas ; `test/unit/passives_paladin_test.dart:45-56`, deux cas, un cas
- Test: `test/unit/draft_choice_labels_test.dart:54-111` ; `test/unit/level_up_reward_data_test.dart:165-207` ; `test/unit/level_up_rewards_catalog_test.dart:115-116` ; `test/widget/draft_screen_test.dart` (deux cas) ; `test/widget/stats_dialog_test.dart` *(nouveau — aucun test n'ouvre `StatsDialog` : `git grep -n StatsDialog -- test` est vide)*

**Interfaces:**
- Consumes: `PassiveData.withMastery`, `EntityStats.effectiveMastery`.
- Produces:
  - `PassiveMastery.floor` (`int?`) ; `PassiveMastery.describe` n'existe plus ;
  - `String? PassiveData.describeMastery(String locale, {required int from, required int to})` ;
  - `String LevelUpRewardData.describe(String locale, {required int amount, PassiveData? passive, required int currentMastery})` ;
  - `static String DraftChoiceLabels.getChoiceDescription(AppLocalizations l10n, DraftChoice choice, {PassiveData? passive, required int currentMastery})`.

- [ ] **Step 1: Les tests du modèle**

In `test/unit/passive_data_test.dart`, replace:

```dart
  group('PassiveMastery.describe', () {
    test('{amount} vaut perPoint fois les points', () {
      expect(regen().mastery!.describe('fr', 3), '+3 Armure en fin de tour');
      expect(regen().mastery!.describe('en', 1), '+1 Block at end of turn');
    });

    test('le signe est porte par le texte, pas par {amount}', () {
      final mastery = PassiveMastery.fromJson({
        ...masteryJson(),
        'perPoint': -2,
        'description_fr': 'Seuil -{amount}',
      });
      expect(mastery.describe('fr', 2), 'Seuil -4');
    });
  });
```

with:

```dart
  // L'effet de la Maîtrise, dit par l'écart effectif du paramètre (spec P-43
  // E3, §4.11, A23).
  group('PassiveData.describeMastery', () {
    test('{amount} vaut l ecart du parametre entre les deux nombres de points',
        () {
      expect(regen().describeMastery('fr', from: 0, to: 3),
          '+3 Armure en fin de tour');
      expect(regen().describeMastery('en', from: 2, to: 3),
          '+1 Block at end of turn');
    });

    test('le signe est porte par le texte, pas par {amount}', () {
      final passive = PassiveData.fromJson({
        ...passiveJson(),
        'mastery': {
          ...masteryJson(),
          'perPoint': -2,
          'description_fr': 'Seuil -{amount}',
        },
      });
      // `value` 2 : deux points la portent à −2, un écart de 4.
      expect(passive.describeMastery('fr', from: 0, to: 2), 'Seuil -4');
    });
  });
```

Then replace:

```dart
    // `perPoint` negatif : un seuil baisse quand la Maitrise monte. Borner le
    // resultat est l'affaire de la strategie qui le lit (spec P-49, §6.2).
    test('la Maitrise sait faire baisser un seuil', () {
```

with:

```dart
    // `perPoint` negatif : un seuil baisse quand la Maitrise monte. Un
    // plancher, s'il est declare, vit dans `withMastery` (spec P-43 E3, A23) ;
    // celui-ci n'en a pas.
    test('la Maitrise sait faire baisser un seuil', () {
```

and, in that same case, replace:

```dart
      expect(passive.mastery!.describe('fr', 2), '-2 Competence a reunir');
```

with:

```dart
      expect(passive.describeMastery('fr', from: 0, to: 2),
          '-2 Competence a reunir');
```

Then replace the end of the file:

```dart
    test('les trois parametres que la Maitrise peut viser sont declares', () {
      expect(PassiveMastery.fields, ['value', 'duration', 'threshold']);
    });
  });
}
```

with:

```dart
    test('les trois parametres que la Maitrise peut viser sont declares', () {
      expect(PassiveMastery.fields, ['value', 'duration', 'threshold']);
    });
  });

  // Le plancher de la Maîtrise (spec P-43 E3, §3.6, §4.11 ; D43, D60, A23).
  group('le plancher', () {
    Map<String, dynamic> fluxJson({int? floor = 2, int perPoint = -1}) => {
          ...passiveJson(),
          'threshold': 3,
          'mastery': {
            'field': 'threshold',
            'perPoint': perPoint,
            'floor': ?floor,
            'description_en': '-{amount} Skill to gather',
            'description_fr': '-{amount} Competence a reunir',
          },
        };

    test('lu dans le bloc mastery ; absent, aucun plancher', () {
      expect(PassiveData.fromJson(fluxJson()).mastery!.floor, 2);
      expect(PassiveData.fromJson(fluxJson(floor: null)).mastery!.floor,
          isNull);
    });

    test('refuse un plancher sur un perPoint qui n est pas negatif', () {
      expect(() => PassiveData.fromJson(fluxJson(perPoint: 1)),
          throwsFormatException);
    });

    test('refuse un plancher au-dessus de la valeur de base du parametre', () {
      expect(() => PassiveData.fromJson(fluxJson(floor: 4)),
          throwsFormatException);
      expect(PassiveData.fromJson(fluxJson(floor: 3)).mastery!.floor, 3);
    });

    test('withMastery ne descend jamais sous le plancher', () {
      final flux = PassiveData.fromJson(fluxJson());
      expect(flux.withMastery(1).threshold, 2);
      expect(flux.withMastery(9).threshold, 2);
    });

    test('describeMastery dit l ecart effectif, plancher compris, et rien '
        'quand rien ne change', () {
      final flux = PassiveData.fromJson(fluxJson());
      expect(flux.describeMastery('fr', from: 0, to: 9),
          '-1 Competence a reunir');
      expect(flux.describeMastery('fr', from: 1, to: 2), isNull);
    });
  });
}
```

- [ ] **Step 2: Les tests des stratégies et des passifs livrés**

In `test/unit/passives_mage_test.dart`, replace:

```dart
        mastery: const PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          descriptionEn: '-{amount} Skill to gather',
          descriptionFr: '-{amount} Competence a reunir',
        ),
```

with:

```dart
        // Comme `mana_flux.json` : sans plancher, 3 − 2 points ferait 1.
        mastery: const PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          floor: 2,
          descriptionEn: '-{amount} Skill to gather',
          descriptionFr: '-{amount} Competence a reunir',
        ),
```

Then replace:

```dart
    test('la Maitrise fait baisser le seuil', () {
      run.startNewRun(master, manaFlux(threshold: 3));
      seedEnemy();

      // 3 − 2 points de Maitrise : une Compétence suffit.
      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    // Ce test ne distingue pas le plancher de son absence : le declencheur
    // ne se resout qu'au premier `onSkillPlayed`, ou le compteur vaut deja 1
    // et `1 >= threshold` est vrai que `threshold` vaille 1 ou un negatif
    // profond. Le plancher n'a d'effet observable qu'ailleurs (une future
    // lecture de `passive.threshold` par l'UI, par exemple) ; ce test
    // documente l'intention de la strategie, pas un comportement qu'il
    // pourrait a lui seul faire echouer.
    test('le seuil ne descend jamais sous une Competence', () {
```

with:

```dart
    test('la Maitrise fait baisser le seuil, jusqu a son plancher', () {
      run.startNewRun(master, manaFlux(threshold: 3));
      seedEnemy();

      // 3 − 2 points de Maitrise font 1, que le plancher porte à 2.
      playSkills(1);
      expect(stats().currentMana, 3, reason: 'une seule ne suffit plus');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });

    // Le plancher vit dans `PassiveData.withMastery` (spec P-43 E3, A23) : à
    // Maitrise 9, le seuil de 3 tomberait à −6, il reste à 2.
    test('le seuil ne descend jamais sous son plancher', () {
```

and, at the end of that same case, replace:

```dart
      run.startNewRun(veryMasterful, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });
```

with:

```dart
      run.startNewRun(veryMasterful, manaFlux(threshold: 3));
      seedEnemy();

      playSkills(1);
      expect(stats().currentMana, 3, reason: 'une Compétence ne suffit pas');

      playSkills(1);
      expect(stats().currentMana, 3 + 1);
    });
```

Then replace:

```dart
    test('les neuf passifs sont livres, et spell_armor n y est plus', () async {
```

with:

```dart
    // D43, D60 (spec P-43 E3, §3.6).
    test('mana_flux.json porte son plancher, 2', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final flux = registry.passives.singleWhere((p) => p.id == 'mana_flux');
      expect(flux.threshold, 3);
      expect(flux.mastery!.field, 'threshold');
      expect(flux.mastery!.floor, 2);
    });

    test('les neuf passifs sont livres, et spell_armor n y est plus', () async {
```

In `test/unit/passives_paladin_test.dart`, replace:

```dart
  PassiveData blessing({int value = 1}) => PassiveData(
        id: 'blessing',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'blessing',
        value: value,
```

with:

```dart
  // `threshold` comme `blessing.json` : sans lui, 0, la tranche ne soigne
  // plus rien (spec P-43 E3, A24).
  PassiveData blessing({int value = 1, int threshold = 5}) => PassiveData(
        id: 'blessing',
        trigger: RelicTrigger.startOfTurn,
        effectType: 'blessing',
        value: value,
        threshold: threshold,
```

Then replace:

```dart
    test('la Maitrise augmente les PV par tranche', () {
      run.startNewRun(master, blessing());
      setHero(armure: 10, currentPv: 50);

      run.startTurn();

      // 2 tranches de 5, et (1 + 2) PV par tranche.
      expect(stats().currentPv, 50 + 2 * 3);
    });
  });
```

with:

```dart
    test('la Maitrise augmente les PV par tranche', () {
      run.startNewRun(master, blessing());
      setHero(armure: 10, currentPv: 50);

      run.startTurn();

      // 2 tranches de 5, et (1 + 2) PV par tranche.
      expect(stats().currentPv, 50 + 2 * 3);
    });

    // La tranche en donnée (spec P-43 E3, A24).
    test('la tranche est le seuil du passif', () {
      run.startNewRun(paladin, blessing(threshold: 4));
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      // 12 d'armure, une tranche de 4 : 3 PV.
      expect(stats().currentPv, 50 + 3);
    });

    test('un seuil sous 1 ne soigne rien, sans lever', () {
      run.startNewRun(paladin, blessing(threshold: 0));
      setHero(armure: 12, currentPv: 50);

      run.startTurn();

      expect(stats().currentPv, 50);
    });
  });
```

Then replace:

```dart
      expect(available, ['regen_armor', 'fervor', 'blessing']);
    });
  });
}
```

with:

```dart
      expect(available, ['regen_armor', 'fervor', 'blessing']);
    });

    // D60 (spec P-43 E3, §3.6) : la tranche en donnée, la Maîtrise sur la
    // valeur, sans plancher.
    test('blessing.json porte sa tranche, 5, et sa Maitrise sur la valeur',
        () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final blessing =
          registry.passives.singleWhere((p) => p.id == 'blessing');
      expect(blessing.threshold, 5);
      expect(blessing.mastery!.field, 'value');
      expect(blessing.mastery!.floor, isNull);
    });
  });
}
```

- [ ] **Step 3: Les tests des textes**

In `test/unit/draft_choice_labels_test.dart`, replace:

```dart
      DraftChoiceLabels.getChoiceDescription(fr, affinity, passive: regen()),
```

with:

```dart
      DraftChoiceLabels.getChoiceDescription(fr, affinity,
          passive: regen(), currentMastery: 0),
```

Then replace:

```dart
      DraftChoiceLabels.getChoiceDescription(en, affinity, passive: regen()),
```

with:

```dart
      DraftChoiceLabels.getChoiceDescription(en, affinity,
          passive: regen(), currentMastery: 0),
```

Then replace:

```dart
        passive: regen(perPoint: 2),
      ),
```

with:

```dart
        passive: regen(perPoint: 2),
        currentMastery: 0,
      ),
```

Then replace `      DraftChoiceLabels.getChoiceDescription(fr, affinity),` with `      DraftChoiceLabels.getChoiceDescription(fr, affinity, currentMastery: 0),`.

Then replace:

```dart
      DraftChoiceLabels.getChoiceDescription(fr, choice('vitality', RewardRarity.epic)),
```

with:

```dart
      DraftChoiceLabels.getChoiceDescription(
          fr, choice('vitality', RewardRarity.epic),
          currentMastery: 0),
```

Then replace:

```dart
      DraftChoiceLabels.getChoiceDescription(en, choice('ferocity', RewardRarity.legendary)),
```

with:

```dart
      DraftChoiceLabels.getChoiceDescription(
          en, choice('ferocity', RewardRarity.legendary),
          currentMastery: 0),
```

Then replace:

```dart
          passive: regen(),
        );
        expect(rendu, isNot(contains('{')), reason: '${reward.id} / ${rarity.name}');
      }
    }
  });
}
```

with:

```dart
          passive: regen(),
          currentMastery: 0,
        );
        expect(rendu, isNot(contains('{')), reason: '${reward.id} / ${rarity.name}');
      }
    }
  });

  // Le plancher de Flux, lu depuis la Maîtrise effective (spec P-43 E3,
  // §4.11, A23 ; C1.2).
  test('Affinite sur Flux dit l ecart effectif depuis la Maitrise passee, '
      'puis le repli au plancher', () {
    const flux = PassiveData(
      id: 'mana_flux',
      nameFr: 'Flux de Mana',
      nameEn: 'Mana Flux',
      trigger: RelicTrigger.onSkillPlayed,
      effectType: 'mana_flux',
      value: 1,
      threshold: 3,
      mastery: PassiveMastery(
        field: 'threshold',
        perPoint: -1,
        floor: 2,
        descriptionEn: '-{amount} Skill to gather',
        descriptionFr: '-{amount} Compétence à réunir',
      ),
    );
    final affinity = choice('affinity', RewardRarity.uncommon); // +2

    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity,
          passive: flux, currentMastery: 0),
      'Flux de Mana : -1 Compétence à réunir',
    );
    expect(
      DraftChoiceLabels.getChoiceDescription(fr, affinity,
          passive: flux, currentMastery: 1),
      '+2 Maîtrise, sans effet sur votre passif',
    );
  });
}
```

In `test/unit/level_up_reward_data_test.dart`, the seven calls of `describe` gain `currentMastery: 0` — des cas réécrits, qui gardent ce qu'ils gardaient. Replace `vitality.describe('fr', amount: 15)` with `vitality.describe('fr', amount: 15, currentMastery: 0)`, `vitality.describe('en', amount: 15)` with `vitality.describe('en', amount: 15, currentMastery: 0)`, `affinity.describe('fr', amount: 2, passive: regen(mastery: masteryBlock))` with `affinity.describe('fr', amount: 2, passive: regen(mastery: masteryBlock), currentMastery: 0)`, `affinity.describe('en', amount: 2, passive: regen(mastery: masteryBlock))` with `affinity.describe('en', amount: 2, passive: regen(mastery: masteryBlock), currentMastery: 0)`, `affinity.describe('fr', amount: 3),` with `affinity.describe('fr', amount: 3, currentMastery: 0),`, `affinity.describe('fr', amount: 3, passive: regen())` with `affinity.describe('fr', amount: 3, passive: regen(), currentMastery: 0)`, and `vitality.describe('fr', amount: 5, passive: regen(mastery: masteryBlock))` with `vitality.describe('fr', amount: 5, passive: regen(mastery: masteryBlock), currentMastery: 0)` — chaque texte ne paraît qu'une fois. Then replace:

```dart
    test('une description sans placeholder de passif ignore le passif', () {
```

with:

```dart
    // La Maîtrise effective (spec P-43 E3, §4.11, A23 ; C1.2).
    test('{effect} part de la Maitrise effective : un gain qui ne change '
        'rien rend le repli', () {
      final affinity = LevelUpRewardData.fromJson(affinityJson());
      const flux = PassiveData(
        id: 'mana_flux',
        nameFr: 'Flux de Mana',
        nameEn: 'Mana Flux',
        trigger: RelicTrigger.onSkillPlayed,
        effectType: 'mana_flux',
        value: 1,
        threshold: 3,
        mastery: PassiveMastery(
          field: 'threshold',
          perPoint: -1,
          floor: 2,
          descriptionEn: '-{amount} Skill to gather',
          descriptionFr: '-{amount} Compétence à réunir',
        ),
      );

      expect(
        affinity.describe('fr', amount: 3, passive: flux, currentMastery: 0),
        'Flux de Mana : -1 Compétence à réunir',
      );
      expect(
        affinity.describe('fr', amount: 3, passive: flux, currentMastery: 1),
        '+3 Maîtrise, sans effet sur votre passif',
      );
    });

    test('une description sans placeholder de passif ignore le passif', () {
```

In `test/unit/level_up_rewards_catalog_test.dart`, replace:

```dart
        reward.describe('fr', amount: 1),
        isNot(reward.describe('en', amount: 1)),
```

with:

```dart
        reward.describe('fr', amount: 1, currentMastery: 0),
        isNot(reward.describe('en', amount: 1, currentMastery: 0)),
```

In `test/widget/draft_screen_test.dart`, replace the end of the file (Task 7):

```dart
      expect(find.byType(DraftCardReel), findsNWidgets(6));
      expect(find.text('Transcendance'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
```

with:

```dart
      expect(find.byType(DraftCardReel), findsNWidgets(6));
      expect(find.text('Transcendance'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  // La Maîtrise de la run, lue par l'écran (spec P-43 E3, §4.11, §8 ; C1.2).
  group('la Maitrise de la run', () {
    /// Une run de mage sous *Flux de Mana*, à [mastery] points de Maîtrise,
    /// sur un registre dont la seule récompense tirable est *Affinité* : les
    /// trois emplacements la tirent, avec remise.
    Future<ProviderContainer> fluxRun(int mastery) async {
      final data = GameDataRegistry(
        enemies: const [],
        heroes: registry.heroes,
        cards: registry.cards,
        events: const [],
        passives: registry.passives,
        relics: const [],
        forgeUpgrades: registry.forgeUpgrades,
        levelUpRewards: [
          registry.levelUpRewards.singleWhere((r) => r.id == 'affinity'),
        ],
      );
      final container = ProviderContainer(
        overrides: [gameDataLoaderProvider.overrideWith((ref) => data)],
      );
      addTearDown(container.dispose);
      await container.read(gameDataLoaderProvider.future);
      final run = container.read(runProvider.notifier);
      run.startNewRun(
        data.heroes.singleWhere((h) => h.id == 'mage'),
        data.passives.singleWhere((p) => p.id == 'mana_flux'),
      );
      final state = container.read(runProvider);
      run.updateState(state.copyWith(
        heroStats: state.heroStats.copyWith(mastery: mastery),
      ));
      return container;
    }

    testWidgets('a Maitrise effective 1, les rouleaux disent le repli',
        (WidgetTester tester) async {
      final container = await fluxRun(1);

      await tester.pumpWidget(
          _wrap(container, DraftScreen(onDraftComplete: () {})));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 4500));

      // Seuil 2 à Maîtrise 1 : tout gain bute sur le plancher.
      expect(find.textContaining('sans effet sur votre passif'),
          findsNWidgets(3));
      expect(find.textContaining('Compétence à réunir'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a Maitrise effective 0, Flux de Mana : -1 Competence a '
        'reunir, quel que soit le gain', (WidgetTester tester) async {
      final container = await fluxRun(0);

      await tester.pumpWidget(
          _wrap(container, DraftScreen(onDraftComplete: () {})));
      await tester.pump();
      await _advance(tester, const Duration(milliseconds: 4500));

      expect(find.text('Flux de Mana : -1 Compétence à réunir'),
          findsNWidgets(3));

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
```

Create `test/widget/stats_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/map/dialogs/stats_dialog.dart';

/// La fiche des stats de la carte du monde dit ce que la Maîtrise change
/// vraiment au passif actif (spec P-43 E3, §4.11, §8 ; C2.6).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  /// Une run de mage sous *Flux de Mana*, à [mastery] points de Maîtrise,
  /// fiche ouverte par `StatsDialog.show`.
  Future<void> openOnFlux(WidgetTester tester, int mastery) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);
    await container.read(gameDataLoaderProvider.future);
    final run = container.read(runProvider.notifier);
    run.startNewRun(
      registry.heroes.singleWhere((h) => h.id == 'mage'),
      registry.passives.singleWhere((p) => p.id == 'mana_flux'),
    );
    final state = container.read(runProvider);
    run.updateState(state.copyWith(
      heroStats: state.heroStats.copyWith(mastery: mastery),
    ));

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
          locale: const Locale('fr', ''),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => StatsDialog.show(context),
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

  testWidgets('Flux a Maitrise 9 dit -1 Competence a reunir, et non -9',
      (tester) async {
    await openOnFlux(tester, 9);

    expect(find.text('Maîtrise : -1 Compétence à réunir'), findsOneWidget);
    expect(find.textContaining('-9'), findsNothing);
  });

  testWidgets('a Maitrise 0, aucune ligne de Maitrise', (tester) async {
    await openOnFlux(tester, 0);

    expect(find.textContaining('à réunir'), findsNothing);
  });
}
```

- [ ] **Step 4: Les lancer pour les voir échouer**

Run: `flutter test test/unit/passive_data_test.dart test/unit/passives_mage_test.dart test/unit/passives_paladin_test.dart test/unit/draft_choice_labels_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_rewards_catalog_test.dart test/widget/draft_screen_test.dart test/widget/stats_dialog_test.dart`
Expected: FAIL — à la compilation (`floor`, `describeMastery`, `currentMastery` n'existent pas), puis les seuils : *Bénédiction* à 4 soigne par tranches de 5, *Flux* passe sous 2.

- [ ] **Step 5: La donnée**

In `assets/data/passives/blessing.json`, replace:

```json
  "value": 1,
  "displayOrder": 3,
```

with:

```json
  "value": 1,
  "threshold": 5,
  "displayOrder": 3,
```

Replace the whole content of `assets/data/passives/mana_flux.json` with:

```json
{
  "id": "mana_flux",
  "name_en": "Mana Flux",
  "name_fr": "Flux de Mana",
  "description_en": "Every 3 Skills played in a combat, gain 1 Mana for the current turn. Mastery lowers this threshold, never below 2.",
  "description_fr": "Toutes les 3 Compétences jouées dans un combat, gagne 1 Mana pour le tour en cours. La Maîtrise abaisse ce seuil, jamais sous 2.",
  "classes": ["mage"],
  "trigger": "onSkillPlayed",
  "effectType": "mana_flux",
  "value": 1,
  "threshold": 3,
  "displayOrder": 3,
  "mastery": {
    "field": "threshold",
    "perPoint": -1,
    "floor": 2,
    "description_en": "-{amount} Skill to gather",
    "description_fr": "-{amount} Compétence à réunir"
  }
}
```

- [ ] **Step 6: Le modèle du passif**

In `lib/models/data/passive_data.dart`, replace:

```dart
import 'relic_data.dart';
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';
```

with:

```dart
import 'dart:math' show max;

import 'relic_data.dart';
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';
```

Then replace:

```dart
  /// Ce qu'un point ajoute au paramètre. Jamais nul ; négatif pour un
  /// paramètre qui baisse avec la Maîtrise, comme un seuil.
  final int perPoint;

  /// L'effet, avec `{amount}` à la place de la valeur.
  final String descriptionEn;
  final String descriptionFr;

  const PassiveMastery({
    required this.field,
    required this.perPoint,
    this.descriptionEn = '',
    this.descriptionFr = '',
  });

  /// L'effet de [points] de Maîtrise : `{amount}` y devient
  /// `|perPoint × points|`, le texte portant le sens (spec P-49, §6.5).
  String describe(String locale, int points) =>
      (locale == 'fr' ? descriptionFr : descriptionEn)
          .replaceAll('{amount}', (perPoint * points).abs().toString());
```

with:

```dart
  /// Ce qu'un point ajoute au paramètre. Jamais nul ; négatif pour un
  /// paramètre qui baisse avec la Maîtrise, comme un seuil.
  final int perPoint;

  /// La valeur sous laquelle la Maîtrise ne fait pas descendre le paramètre
  /// — le seuil de *Flux de Mana*, jamais sous 2 (D43, D60 ; spec P-43 E3,
  /// A23). `null` : aucun plancher. N'a de sens que sur un [perPoint]
  /// négatif ; `PassiveData.withMastery` l'applique.
  final int? floor;

  /// L'effet, avec `{amount}` à la place de la valeur — que
  /// `PassiveData.describeMastery` remplit.
  final String descriptionEn;
  final String descriptionFr;

  const PassiveMastery({
    required this.field,
    required this.perPoint,
    this.floor,
    this.descriptionEn = '',
    this.descriptionFr = '',
  });
```

Then replace:

```dart
    return PassiveMastery(
      field: field,
      perPoint: perPoint,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
    );
  }
}
```

with:

```dart
    final floor = json['floor'];
    if (floor != null && (floor is! int || perPoint >= 0)) {
      throw FormatException(
        'mastery.floor vaut un entier, sur un perPoint négatif — reçu : floor '
        '$floor, perPoint $perPoint',
      );
    }
    return PassiveMastery(
      field: field,
      perPoint: perPoint,
      floor: floor as int?,
      descriptionEn: descriptionEn,
      descriptionFr: descriptionFr,
    );
  }
}
```

Then replace:

```dart
  /// Le nombre d'occurrences à réunir avant que le passif agisse — le seuil de
  /// *Flux de Mana*. 0 : aucun seuil, le passif agit à chaque déclenchement.
  final int threshold;
```

with:

```dart
  /// Un seuil, que lit la stratégie du passif (spec P-43 E3, A24) : les
  /// Compétences à réunir avant que *Flux de Mana* agisse — 0 : à chaque
  /// déclenchement — ; l'armure survivante d'une tranche de *Bénédiction* —
  /// sous 1, aucune tranche.
  final int threshold;
```

Then replace:

```dart
  /// Ce passif avec [points] de Maîtrise appliqués au paramètre que désigne
  /// [mastery] (spec P-49, §6.2). Rendu tel quel sans [mastery] ou à 0 point.
  /// Borner le résultat est l'affaire de la stratégie qui le lit.
  PassiveData withMastery(int points) {
    final m = mastery;
    if (m == null || points == 0) return this;
    final delta = m.perPoint * points;
    return switch (m.field) {
      'value' => _copyWith(value: value + delta),
      'duration' => _copyWith(duration: duration + delta),
      'threshold' => _copyWith(threshold: threshold + delta),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }
```

with:

```dart
  /// Ce passif avec [points] de Maîtrise appliqués au paramètre que désigne
  /// [mastery] (spec P-49, §6.2), jamais sous son plancher s'il en déclare un
  /// (spec P-43 E3, A23). Rendu tel quel sans [mastery] ou à 0 point.
  PassiveData withMastery(int points) {
    final m = mastery;
    if (m == null || points == 0) return this;
    int mastered(int base) {
      final raised = base + m.perPoint * points;
      final floor = m.floor;
      return floor == null ? raised : max(floor, raised);
    }

    return switch (m.field) {
      'value' => _copyWith(value: mastered(value)),
      'duration' => _copyWith(duration: mastered(duration)),
      'threshold' => _copyWith(threshold: mastered(threshold)),
      // `fromJson` refuse tout autre champ ; un passif construit en code avec
      // un champ inconnu ignore sa Maîtrise plutôt que de lever en combat.
      _ => this,
    };
  }

  /// L'effet de la Maîtrise qui passe de [from] à [to] points, dans le texte
  /// du bloc `mastery` (spec P-43 E3, §4.11, A23) : `{amount}` y devient
  /// l'écart du paramètre visé entre ces deux nombres de points, plancher
  /// compris — ce que le joueur gagne vraiment, le texte portant le sens.
  /// `null` sans bloc `mastery`, ou quand l'écart est nul : rien ne change.
  String? describeMastery(String locale, {required int from, required int to}) {
    final m = mastery;
    if (m == null) return null;
    final amount = (_parameterOf(withMastery(to), m.field) -
            _parameterOf(withMastery(from), m.field))
        .abs();
    if (amount == 0) return null;
    return (locale == 'fr' ? m.descriptionFr : m.descriptionEn)
        .replaceAll('{amount}', '$amount');
  }

  /// Le paramètre [field] de [passive], parmi ceux qu'une Maîtrise peut viser.
  static int _parameterOf(PassiveData passive, String field) =>
      switch (field) {
        'value' => passive.value,
        'duration' => passive.duration,
        'threshold' => passive.threshold,
        _ => 0,
      };
```

Then replace:

```dart
    return PassiveData(
      id: json['id'] as String,
```

with:

```dart
    final passive = PassiveData(
      id: json['id'] as String,
```

and replace:

```dart
      mastery:
          masteryJson == null ? null : PassiveMastery.fromJson(masteryJson),
    );
  }
```

with:

```dart
      mastery:
          masteryJson == null ? null : PassiveMastery.fromJson(masteryJson),
    );
    // Un plancher au-dessus de la valeur de base mordrait sans Maîtrise
    // (spec P-43 E3, A23).
    final mastery = passive.mastery;
    final floor = mastery?.floor;
    if (mastery != null &&
        floor != null &&
        floor > _parameterOf(passive, mastery.field)) {
      throw FormatException(
        'mastery.floor ($floor) dépasse la valeur de base de '
        '${mastery.field} (${_parameterOf(passive, mastery.field)})',
      );
    }
    return passive;
  }
```

- [ ] **Step 7: Les stratégies**

In `lib/game/systems/passives/passive_strategies.dart`, replace:

```dart
    // La Maîtrise fait baisser le seuil (`perPoint` négatif) : le borner est
    // l'affaire de la stratégie qui le lit (spec P-49, §6.2). Une Compétence
    // sur une, jamais moins.
    final threshold = passive.threshold < 1 ? 1 : passive.threshold;
    final count =
        PassiveCounters.bump(run, passive, scope: CounterScope.combat);
    if (count < threshold) return;
```

with:

```dart
    // Le seuil arrive Maîtrise appliquée, plancher compris
    // (`PassiveData.withMastery`, spec P-43 E3, A23) ; le compteur vaut au
    // moins 1 : un seuil de 0 agit à chaque Compétence.
    final count =
        PassiveCounters.bump(run, passive, scope: CounterScope.combat);
    if (count < passive.threshold) return;
```

Then replace:

```dart
/// `blessing` : chaque tranche de 5 points d'armure survivante devient `value`
/// PV.
```

with:

```dart
/// `blessing` : chaque tranche de `threshold` points d'armure survivante
/// devient `value` PV — `blessing.json` en déclare 5 (D60 ; spec P-43 E3,
/// A24).
```

Then replace:

```dart
  const BlessingPassive();

  /// L'armure qu'il faut pour une tranche. Valeur d'équilibrage : les gains
  /// d'armure du jeu vont de 5 à 15 points.
  static const int _armorPerTranche = 5;

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    final tranches = (event.survivingArmor ?? 0) ~/ _armorPerTranche;
```

with:

```dart
  const BlessingPassive();

  @override
  void resolve(PassiveData passive, PassiveEvent event, RunController run) {
    // Un seuil sous 1 ne fait rien : pas d'exception en combat (A24).
    if (passive.threshold < 1) return;
    final tranches = (event.survivingArmor ?? 0) ~/ passive.threshold;
```

- [ ] **Step 8: Les textes et leurs lecteurs**

In `lib/models/data/level_up_reward_data.dart`, replace:

```dart
  /// La description affichée sur la carte de draft.
  ///
  /// Un gabarit qui nomme `{passive}` ou `{effect}` a besoin d'un passif actif
  /// **qui déclare une Maîtrise** : sans lui, c'est [fallbackDescriptionFr] qui
  /// sert. C'est la règle, unique, qui remplace la branche `case affinity` de
  /// l'ancien `DraftChoiceLabels`.
  String describe(String locale, {required int amount, PassiveData? passive}) {
    final isFr = locale == 'fr';
    final main = isFr ? descriptionFr : descriptionEn;
    final fallback = isFr ? fallbackDescriptionFr : fallbackDescriptionEn;
    final mastery = passive?.mastery;
    final needsPassive = main.contains('{passive}') || main.contains('{effect}');
    final template = needsPassive && mastery == null ? fallback ?? main : main;

    return template
        .replaceAll('{amount}', '$amount')
        .replaceAll('{passive}', passive?.getName(locale) ?? '')
        .replaceAll('{effect}', mastery?.describe(locale, amount) ?? '');
  }
```

with:

```dart
  /// La description affichée sur la carte de draft.
  ///
  /// Un gabarit qui nomme `{passive}` ou `{effect}` a besoin d'un passif actif
  /// **dont la Maîtrise change quelque chose** : `{effect}` dit ce que
  /// [amount] points ajoutés à la Maîtrise effective [currentMastery]
  /// changent vraiment, plancher compris (spec P-43 E3, §4.11, A23) ; sans
  /// passif à Maîtrise, ou sans changement, c'est [fallbackDescriptionFr] qui
  /// sert. C'est la règle, unique, qui remplace la branche `case affinity` de
  /// l'ancien `DraftChoiceLabels`.
  String describe(
    String locale, {
    required int amount,
    PassiveData? passive,
    required int currentMastery,
  }) {
    final isFr = locale == 'fr';
    final main = isFr ? descriptionFr : descriptionEn;
    final fallback = isFr ? fallbackDescriptionFr : fallbackDescriptionEn;
    final effect = passive?.describeMastery(
      locale,
      from: currentMastery,
      to: currentMastery + amount,
    );
    final needsPassive = main.contains('{passive}') || main.contains('{effect}');
    final template = needsPassive && effect == null ? fallback ?? main : main;

    return template
        .replaceAll('{amount}', '$amount')
        .replaceAll('{passive}', passive?.getName(locale) ?? '')
        .replaceAll('{effect}', effect ?? '');
  }
```

In `lib/ui/widgets/draft/draft_choice_labels.dart`, replace:

```dart
  /// [passive] est le passif actif : une récompense dont le gabarit nomme
  /// `{passive}` ou `{effect}` se décrit par ce que la Maîtrise tirée lui
  /// apporte — c'est le cas d'*Affinité* (spec P-49, §6.5). Les autres
  /// l'ignorent, sans qu'aucune branche ne les distingue.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice, {
    PassiveData? passive,
  }) =>
      choice.data.describe(
        l10n.localeName,
        amount: choice.amount,
        passive: passive,
      );
```

with:

```dart
  /// [passive] est le passif actif, [currentMastery] la Maîtrise effective du
  /// héros : une récompense dont le gabarit nomme `{passive}` ou `{effect}`
  /// se décrit par ce que la Maîtrise tirée change vraiment, à partir de
  /// celle qu'il a — c'est le cas d'*Affinité* (spec P-49, §6.5 ; spec P-43
  /// E3, §4.11, C1.2). Les autres l'ignorent, sans qu'aucune branche ne les
  /// distingue.
  static String getChoiceDescription(
    AppLocalizations l10n,
    DraftChoice choice, {
    PassiveData? passive,
    required int currentMastery,
  }) =>
      choice.data.describe(
        l10n.localeName,
        amount: choice.amount,
        passive: passive,
        currentMastery: currentMastery,
      );
```

In `lib/ui/screens/draft_screen.dart`, replace:

```dart
    final activePassive = ref.watch(runProvider.select((s) => s.activePassive));
```

with:

```dart
    final activePassive = ref.watch(runProvider.select((s) => s.activePassive));
    // La Maîtrise effective, d'où part l'effet d'*Affinité* (spec P-43 E3,
    // §4.11, C1.2).
    final currentMastery = ref.watch(
        runProvider.select((s) => s.heroStats.effectiveMastery));
```

Then, after each of the three lines `passive: activePassive,` (`:253`, `:346`, `:472` — les trois appels de `DraftChoiceLabels.getChoiceDescription`), add a line `currentMastery: currentMastery,` at the same indentation.

In `lib/tutorial/widgets/tutorial_draft_widget.dart`, replace:

```dart
                          passive: widget.engine.mockState.activePassive,
                        );
```

with:

```dart
                          passive: widget.engine.mockState.activePassive,
                          // Le moteur du tutoriel, sans provider (ADR-081).
                          currentMastery: widget
                              .engine.mockState.heroStats.effectiveMastery,
                        );
```

In `lib/ui/widgets/map/dialogs/stats_dialog.dart`, replace:

```dart
    // L'effet de la Maîtrise acquise sur le passif actif, s'il en tire un
    // (spec P-49, §6.5).
    final mastery = passive?.mastery;
    final masteryEffect = mastery != null && stats.effectiveMastery > 0
        ? mastery.describe(locale, stats.effectiveMastery)
        : null;
```

with:

```dart
    // Ce que la Maîtrise acquise change vraiment au passif actif, plancher
    // compris (spec P-49, §6.5 ; spec P-43 E3, §4.11, A23) : si rien ne
    // change, pas de ligne.
    final masteryEffect = stats.effectiveMastery > 0
        ? passive?.describeMastery(locale,
            from: 0, to: stats.effectiveMastery)
        : null;
```

In `lib/ui/widgets/class_passive_list.dart`, replace:

```dart
    final mastery = passive.mastery;
```

with:

```dart
    // Ce qu'un point de Maîtrise change au passif (spec P-43 E3, §4.11, A23).
    final masteryEffect = passive.describeMastery(locale, from: 0, to: 1);
```

Then replace `                    if (mastery != null) ...[` with `                    if (masteryEffect != null) ...[`, and replace:

```dart
                        l10n.passiveMasteryAtStart(
                          classMastery,
                          mastery.describe(locale, 1),
                        ),
```

with:

```dart
                        l10n.passiveMasteryAtStart(
                          classMastery,
                          masteryEffect,
                        ),
```

- [ ] **Step 9: Les tests passent**

Run: `flutter test test/unit/passive_data_test.dart test/unit/passives_mage_test.dart test/unit/passives_paladin_test.dart test/unit/draft_choice_labels_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_rewards_catalog_test.dart test/widget/draft_screen_test.dart test/widget/stats_dialog_test.dart test/widget/class_selection_screen_test.dart test/tutorial test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: PASS — `class_selection_screen_test.dart` (l'écran de sélection, de 0 à 1 point : les passifs sans plancher affichent ce qu'ils affichaient) et les tests du tutoriel (`TutorialDraftWidget`) inchangés ; `mana_flux.json` et `blessing.json` se réécrivent à l'identique.

- [ ] **Step 10: Analyse, commandes et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e _armorPerTranche -e "mastery.describe(" -e "mastery!.describe(" -e "threshold < 1 ? 1" -- lib test`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1622: All tests passed!` (1607 + 5 + 1 + 3 + 1 + 1 + 2 + 2)

- [ ] **Step 11: Commit**

```bash
git add assets/data/passives/blessing.json assets/data/passives/mana_flux.json lib/models/data/passive_data.dart lib/game/systems/passives/passive_strategies.dart lib/models/data/level_up_reward_data.dart lib/ui/widgets/draft/draft_choice_labels.dart lib/ui/screens/draft_screen.dart lib/tutorial/widgets/tutorial_draft_widget.dart lib/ui/widgets/map/dialogs/stats_dialog.dart lib/ui/widgets/class_passive_list.dart test/unit/passive_data_test.dart test/unit/passives_mage_test.dart test/unit/passives_paladin_test.dart test/unit/draft_choice_labels_test.dart test/unit/level_up_reward_data_test.dart test/unit/level_up_rewards_catalog_test.dart test/widget/draft_screen_test.dart test/widget/stats_dialog_test.dart
git commit -F - <<'EOF'
feat(passifs): les seuils de Benediction et de Flux en donnee

La tranche de Benediction se lit dans blessing.json. Le bloc mastery
gagne un plancher, 2 sur Flux de Mana seulement, que withMastery
applique ; le plancher code, inerte, disparait. L effet affiche de la
Maitrise dit ce qu elle change vraiment : la fiche des stats, l ecran de
selection et la carte d Affinite partent de la Maitrise effective.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 11: La simulation lit les entrées du brainstorm dans leurs fichiers (premier temps)

Spec §9, premier temps ; orchestration §3.6, §7.3 ligne 3 ; D73. Le script tire ses listes **par index** : les six fichiers d'E3 qui doublonnent une entrée en dur — les reliques A, C et D42(a) (`bounty_ledger`, `gleaners_pouch`, `grindstone`), les événements de D23 et de D42(b) (`relic_peddler`, `wandering_grinder`), la mythique de D42(c) (`transcendence`) — y entreraient deux fois, rangés au milieu des listes lues. Chaque fichier prend **la place exacte** de son entrée en dur — même liste, même position, même définition — et sort de la liste que le chargeur lit :

- **les reliques** : le chargeur écarte de `data.relics` les trois fichiers, qu'il reconnaît à l'`effectType` que joue chacune des trois entrées ; les définitions elles-mêmes, `relicD31A`, `relicD31C`, `relicD42`, cèdent la place à des valeurs construites sur leur fichier — l'id du fichier compris, pour que tous leurs lecteurs suivent (la variante `forced`, la réserve, la trouvaille, le boss « XP », le compte `d31Copies`, par `copies()`) —, avec `trigger: 'special'` comme leur entrée (lues `startOfRun`, l'échange de relique les céderait, `:3077`, et l'Autel les sacrifierait, `:3149`, `:3161`), leur rareté lue **et vérifiée** égale à celle de l'entrée (`StateError` sinon), leur effet et leur valeur ceux de l'entrée. Les deux listes `const` qui les rangent (`:2101`, `:2508`) perdent `const`. B reste en dur ;
- **les événements** : le chargeur écarte de `data.events` les deux fichiers, qu'il reconnaît à leurs types d'action (`trade_relic`, `sharpen_rune`) ; la liste tirée garde `[...data.events, 'd29_fusion', <D23>, <D42(b)>]`, les deux ids aux places de `'d23_relic'` et `'d42b_sharpen'`, toujours résolus par `_eventRelicTrade` et `_eventSharpen` ;
- **la mythique** : le chargeur écarte de `data.rewards` le fichier d'effet `raiseRuneCap` ; il prend la place du `null`, **en dernier** des mythiques, et les tests qui reconnaissaient le `null` (`:2664`, `:2675`) le reconnaissent par son id ; les listes d'offres perdent leur type nullable, qu'aucune valeur ne prend plus ;
- un fichier qui joue une entrée du brainstorm — par son `effectType`, ses types d'action, son effet — sans être celui qui y est rangé lève une erreur, comme la liste d'ordre des runes (`:847-850`) ; un fichier rangé qui manque aussi ;
- les commentaires qui citent du code qu'E3 change sont rafraîchis, sans toucher au calcul : `:41`, `:49`, `:145`, `:156-157`, `:1189-1191`, `:2155`, `:2571`, `:2593`, `:2646` (C2.2 ; second arrêt n° 4) ;
- **les trois libellés imprimés** qui disent « actuelle » (`:2046`, `:3733`, `:3745`) **ne changent pas ici** : ils s'écrivent dans la sortie, dont le diff doit rester vide. La Task 14 les renomme.

**Aucune valeur que le script tient en dur ne change.** Rien d'autre ne change ce qu'il lit : `wisdom.json` (`values.mythic` 1, égal au repli `?? 1`, `:2655`, `:2660`), `blessing.json` et `mana_flux.json` (le script ne lit le seuil que de *Flux*, et joue en dur le plancher 2 et la tranche de 5, `:2153`, `:2157`), `binary` (non lu) et `xp_curve.json` (non lu au premier temps). **L'écart attendu : aucun**, la ligne « Données lues » comprise — elle écrit la longueur des listes lues (`:3873-3877`), que les fichiers écartés laissent à 25 reliques, 8 récompenses, 17 runes, 5 événements (spec §1.3, première prémisse). La fumée compare deux `--quick` : le script et la donnée de la base de la vague (`9282513`, avant la partie 1 — après elle, les reliques A et C doublonnent déjà, et la fumée sur la branche n'est plus un témoin), puis le script réaligné sur la donnée de la vague.

**Aucune tâche ne touche `assets/data/` après celle-ci** ; elle n'y touche pas elle-même. La mesure complète est l'affaire de l'orchestrateur.

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:41`, `:49`, `:145`, `:156-157`, `:689-697`, `:699-712` (`GameData`), `:751-778` (reliques, récompenses), `:883-898` (événements, `return`), `:1189-1191`, `:2101`, `:2155`, `:2508`, `:2571`, `:2593`, `:2639-2668`, `:2670`, `:2675`, `:2694`, `:2704`, `:2976-2989`

**Interfaces:**
- Consumes: les fichiers `assets/data/relics/{bounty_ledger,gleaners_pouch,grindstone}.json`, `assets/data/events/{relic_peddler,wandering_grinder}.json`, `assets/data/level_up_rewards/transcendence.json` — chacun déclare son `"id"`, que le chargeur lit en dur (spec §3.3).
- Produces: `GameData.relicD31A`, `relicD31C`, `relicD42` (`RelicDef`), `GameData.ceilingReward` (`RewardDef`) ; les constantes `brainstormRelicFiles`, `eventD23`, `eventD42b`, `brainstormEventFiles`, `ceilingRewardId`. Les listes `data.relics`, `data.rewards`, `data.events` gardent leur contenu et leur ordre d'avant E3.

- [ ] **Step 1: Mesurer l'avant**

`<tmp>` est un dossier temporaire **hors du dépôt** — le dossier de travail temporaire de la session.

Run: `mkdir -p <tmp>/d26_base && git archive 9282513 tool/simulations assets/data | tar -x -C <tmp>/d26_base`
Run, depuis `<tmp>/d26_base` : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_base.md`
Expected: environ une minute ; la ligne `écrit : <tmp>/d26_base.md` sur la sortie d'erreur ; `<tmp>/d26_base.md` porte « Données lues : 4 ennemis, 17 neutres (noyau de 9), 25 reliques (+ 4 du brainstorm), 8 récompenses de niveau, 17 runes, 5 événements (+ 3 du brainstorm). » Le script n'importe que des bibliothèques `dart:` et trouve `assets/data/` en remontant depuis son propre dossier : il tourne hors de tout paquet, sur la donnée extraite.

- [ ] **Step 2: Les commentaires qu'E3 rend faux (sans effet sur la sortie)**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
const maxHandSize = 10; // game_constants.dart:36
```

with:

```dart
const maxHandSize = 10; // GameConstants.startingMaxHandSize ; une stat de run depuis E3 (RunState.maxHandSize)
```

Then replace:

```dart
/// Quotas de types de nœuds par carte — game_constants.dart:25-31, dans
```

with:

```dart
/// Quotas de types de nœuds par carte — game_constants.dart:29-35, dans
```

Then replace:

```dart
  /// Q17 : 'current' (100 × 1,5^(n−1), player_stats_manager.dart:127),
```

with:

```dart
  /// Q17 : 'current' (la courbe d'avant E3, 100 × 1,5^(n−1)),
```

Then replace:

```dart
  /// D47 : terme de deck de `PlayerPower`. < 0 = formule actuelle, cartes × 2
  /// (encounter_system.dart:101) ; sinon k × Σ `fusionRank`. DÉFAUT k = 2 (D59 ;
```

with:

```dart
  /// D47 : terme de deck de `PlayerPower`. < 0 = la formule d'avant E3,
  /// cartes × 2 ; sinon k × Σ `fusionRank`, la formule du jeu depuis E3
  /// (encounter_system.dart:103, k = 2). DÉFAUT k = 2 (D59 ;
```

Then replace:

```dart
/// PlayerPower et budget final — encounter_system.dart:86-131 ; le terme de
/// deck `deckTerm` est `cartes × 2` aujourd'hui (:101), `k × Σ fusionRank`
/// sous D47.
```

with:

```dart
/// PlayerPower et budget final — encounter_system.dart:86-131 ; le terme de
/// deck `deckTerm` est `k × Σ fusionRank` sous D47 — celui du jeu depuis E3
/// (:103, k = 2) — ; `cartes × 2` était la formule d'avant E3.
```

Then replace:

```dart
  /// Bénédiction : tranche de 5 (passive_strategies.dart:146), ou D43 :
  /// `threshold: 3`, Maîtrise sur le seuil, plancher 2.
```

with:

```dart
  /// Bénédiction : tranche de 5 — celle de `blessing.json`, `threshold: 5`
  /// (D60), que le script joue en dur —, ou D43 : `threshold: 3`, Maîtrise
  /// sur le seuil, plancher 2.
```

Then replace:

```dart
  /// player_stats_manager.dart:239-303 et :435-455.
```

with:

```dart
  /// player_stats_manager.dart:249-458 et :460-489.
```

Ces deux plages sont celles d'`applyRelicEffect` et de `removeRelicEffect` après les Tasks 3 et 7 ; avant d'écrire, les mesurer : `grep -n -e "void applyRelicEffect" -e "void removeRelicEffect" -e "void exchangeRelics" lib/game/controllers/run/player_stats_manager.dart` — la première plage va de `applyRelicEffect` à deux lignes avant `removeRelicEffect`, la seconde de `removeRelicEffect` à deux lignes avant `exchangeRelics`. Si la commande rend d'autres numéros, ce sont les siens qui s'écrivent.

Then replace:

```dart
        _ => (100 * pow(1.5, level - 1)).round(), // player_stats_manager.dart:127
```

with:

```dart
        _ => (100 * pow(1.5, level - 1)).round(), // la courbe d'avant E3
```

Le commentaire de `:41` nomme la constante et la stat sans citer de ligne ; celui de `:49` cite `nodeQuotas`, que la partie 1 a décalée de quatre lignes (le `typedef CardDropRule` et son import) et que la partie 2 ne déplace plus — le mesurer aussi : `grep -n "nodeQuotas" lib/game/game_constants.dart` rend la ligne de la déclaration, `:29`, dont le bloc finit en `:35`. Le commentaire de `:2646` (*Sagesse* « pas de valeur `mythic` en donnée ») est réécrit au Step 4, avec le bloc qu'il précède.

- [ ] **Step 3: Les entrées du brainstorm, en fichiers**

Replace:

```dart
/// Synthèse des reliques ajoutées par le brainstorm, absentes des données.
/// D31 : A « monte la chance de seconde carte en élite » (rareté DÉFAUT rare),
/// B « une épique » (+1 %), C « une carte garantie de plus » (DÉFAUT rare).
/// D42a : une légendaire porte au-delà de 1 le nombre de runes affûtées par
/// la récompense de boss « XP ».
const relicD31A = RelicDef('d31_a_elite', 2, 'special', 'd31a', 0);
const relicD31B = RelicDef('d31_b_lucky', 3, 'special', 'd31b', 0);
const relicD31C = RelicDef('d31_c_extra', 2, 'special', 'd31c', 0);
const relicD42 = RelicDef('d42_whetstone', 4, 'special', 'd42', 1);
```

with:

```dart
/// Les reliques du brainstorm. D31 : A « monte la chance de seconde carte en
/// élite » (rare), B « une épique » (+1 %), C « une carte garantie de plus »
/// (rare). D42a : une légendaire porte au-delà de 1 le nombre de runes
/// affûtées par la récompense de boss « XP ». A, C et D42a sont des fichiers
/// depuis E3 (`brainstormRelicFiles`) : leurs définitions se construisent sur
/// eux au chargement (`GameData.load`), à la place exacte de leur entrée en
/// dur ; B reste en dur.
RelicDef get relicD31A => data.relicD31A;
const relicD31B = RelicDef('d31_b_lucky', 3, 'special', 'd31b', 0);
RelicDef get relicD31C => data.relicD31C;
RelicDef get relicD42 => data.relicD42;

/// Les entrées du brainstorm que la donnée du jeu porte depuis E3 (spec P-43
/// E3, §3.3 à §3.5, §9) : chaque fichier prend la place exacte de son entrée
/// en dur — même liste, même position, même définition — et sort de la liste
/// que lit le chargeur, tirée par index (D73). Chacune se reconnaît à ce
/// qu'elle joue : un autre fichier qui le jouerait lève une erreur, comme la
/// liste d'ordre des runes. Les reliques, par leur `effectType` :
const brainstormRelicFiles = {
  'increase_elite_card_chance': 'bounty_ledger', // D31, A
  'increase_combat_card_drops': 'gleaners_pouch', // D31, C
  'increase_boss_rune_sharpens': 'grindstone', // D42a
};

/// Les événements de D23 et de D42b, par le type d'action qui les désigne ;
/// le script les résout toujours par `_eventRelicTrade` et `_eventSharpen`.
const eventD23 = 'relic_peddler';
const eventD42b = 'wandering_grinder';
const brainstormEventFiles = {
  'trade_relic': eventD23,
  'sharpen_rune': eventD42b,
};

/// La mythique de D42c, d'effet `raiseRuneCap` : elle prend la place du
/// `null` qui la jouait, en dernier des mythiques.
const ceilingRewardId = 'transcendence';
```

Then replace:

```dart
class GameData {
  GameData._(this.enemies, this.neutrals, this.relics, this.rewards,
      this.classes, this.passives, this.runes, this.events);
```

with:

```dart
class GameData {
  GameData._(this.enemies, this.neutrals, this.relics, this.rewards,
      this.classes, this.passives, this.runes, this.events, this.relicD31A,
      this.relicD31C, this.relicD42, this.ceilingReward);
```

Then replace:

```dart
  final List<RuneDef> runes;
  final List<EventDef> events;
```

with:

```dart
  final List<RuneDef> runes;
  final List<EventDef> events;

  /// Les reliques A, C et D42a, construites sur leur fichier, et la mythique
  /// de D42c (`brainstormRelicFiles`, `ceilingRewardId`).
  final RelicDef relicD31A;
  final RelicDef relicD31C;
  final RelicDef relicD42;
  final RewardDef ceilingReward;
```

Then replace:

```dart
    final relics = <RelicDef>[
      for (final f in _jsonFiles('$root/relics'))
        () {
          final j = _json(f.path);
          return RelicDef(
            j['id'] as String,
            relicRarities.indexOf(j['rarity'] as String),
            j['trigger'] as String,
            j['effectType'] as String,
            j['value'] as int? ?? 0,
          );
        }(),
    ];

    final rewards = <RewardDef>[
      for (final f in _jsonFiles('$root/level_up_rewards'))
        () {
          final j = _json(f.path);
          return RewardDef(
            j['id'] as String,
            j['effect'] as String,
            j['stat'] as String? ?? '',
            j['pool'] as String,
            (j['values'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, v as int)),
          );
        }(),
    ];
```

with:

```dart
    // Les reliques : les fichiers triés, sauf ceux qui jouent une entrée du
    // brainstorm, gardés à part pour prendre la place de leur entrée en dur,
    // en queue de la réserve.
    final relics = <RelicDef>[];
    final brainstormRelics = <String, Map<String, dynamic>>{};
    for (final f in _jsonFiles('$root/relics')) {
      final j = _json(f.path);
      final id = j['id'] as String;
      final effect = j['effectType'] as String;
      final entry = brainstormRelicFiles[effect];
      if (entry != null || brainstormRelicFiles.containsValue(id)) {
        if (entry != id) {
          throw StateError('relique « $id » (${f.path}) : elle joue une entrée '
              'du brainstorm sans y être rangée — brainstormRelicFiles');
        }
        brainstormRelics[id] = j;
        continue;
      }
      relics.add(RelicDef(
        id,
        relicRarities.indexOf(j['rarity'] as String),
        j['trigger'] as String,
        effect,
        j['value'] as int? ?? 0,
      ));
    }
    // L'entrée en dur que remplace le fichier [id] : la rareté lue doit être
    // la sienne ; l'effet et la valeur restent ceux que joue le script ;
    // `trigger: 'special'`, comme l'entrée.
    RelicDef placedRelic(String id, int rarity, String effect, int value) {
      final j = brainstormRelics[id] ??
          (throw StateError('relique « $id » : son fichier manque'));
      final read = relicRarities.indexOf(j['rarity'] as String);
      if (read != rarity) {
        throw StateError('relique « $id » : rareté ${j['rarity']}, quand '
            'l\'entrée en dur qu\'elle remplace est ${relicRarities[rarity]}');
      }
      return RelicDef(id, read, 'special', effect, value);
    }

    // Les récompenses : les fichiers triés, sauf la mythique de D42c.
    final rewards = <RewardDef>[];
    RewardDef? ceiling;
    for (final f in _jsonFiles('$root/level_up_rewards')) {
      final j = _json(f.path);
      final reward = RewardDef(
        j['id'] as String,
        j['effect'] as String,
        j['stat'] as String? ?? '',
        j['pool'] as String,
        (j['values'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v as int)),
      );
      if (reward.effect == 'raiseRuneCap' || reward.id == ceilingRewardId) {
        if (reward.id != ceilingRewardId) {
          throw StateError('récompense « ${reward.id} » (${f.path}) : elle '
              'joue la mythique de D42c sans y être rangée — ceilingRewardId');
        }
        ceiling = reward;
        continue;
      }
      rewards.add(reward);
    }
```

Then replace:

```dart
    final events = <EventDef>[
      for (final f in _jsonFiles('$root/events'))
        () {
          final j = _json(f.path);
          return EventDef(j['id'] as String, [
            for (final c in (j['choices'] as List))
              [
                for (final a in ((c as Map<String, dynamic>)['actions'] as List? ?? const []))
                  ((a as Map<String, dynamic>)['type'] as String, a['value'] as int? ?? 0),
              ],
          ]);
        }(),
    ];

    return GameData._(
        enemies, neutrals, relics, rewards, classes, passives, runes, events);
  }
```

with:

```dart
    // Les événements : les fichiers triés, sauf D23 et D42b, que la liste
    // tirée range à la place de leur entrée en dur (`visitEvent`).
    final events = <EventDef>[];
    final brainstormEvents = <String>{};
    for (final f in _jsonFiles('$root/events')) {
      final j = _json(f.path);
      final id = j['id'] as String;
      final choices = [
        for (final c in (j['choices'] as List))
          [
            for (final a in ((c as Map<String, dynamic>)['actions'] as List? ?? const []))
              ((a as Map<String, dynamic>)['type'] as String, a['value'] as int? ?? 0),
          ],
      ];
      final entries = {
        for (final choice in choices)
          for (final (type, _) in choice)
            ?brainstormEventFiles[type],
      };
      if (entries.isNotEmpty || brainstormEventFiles.containsValue(id)) {
        if (entries.length != 1 || entries.single != id) {
          throw StateError('événement « $id » (${f.path}) : il joue une entrée '
              'du brainstorm sans y être rangé — brainstormEventFiles');
        }
        brainstormEvents.add(id);
        continue;
      }
      events.add(EventDef(id, choices));
    }
    for (final id in brainstormEventFiles.values) {
      if (!brainstormEvents.contains(id)) {
        throw StateError('événement « $id » : son fichier manque');
      }
    }

    return GameData._(
      enemies,
      neutrals,
      relics,
      rewards,
      classes,
      passives,
      runes,
      events,
      placedRelic('bounty_ledger', 2, 'd31a', 0),
      placedRelic('gleaners_pouch', 2, 'd31c', 0),
      placedRelic('grindstone', 4, 'd42', 1),
      ceiling ??
          (throw StateError('récompense « $ceilingRewardId » : son fichier '
              'manque')),
    );
  }
```

Les trois entrées en dur qu'ils remplacent jouaient `RelicDef('d31_a_elite', 2, 'special', 'd31a', 0)`, `RelicDef('d31_c_extra', 2, 'special', 'd31c', 0)` et `RelicDef('d42_whetstone', 4, 'special', 'd42', 1)` : même rareté — vérifiée —, même `trigger`, même effet, même valeur ; seul l'id change, et tous ses lecteurs le lisent sur la définition.

- [ ] **Step 4: Leurs lecteurs**

Replace:

```dart
      for (final r in const [relicD31A, relicD31B, relicD31C]) {
```

with:

```dart
      for (final r in [relicD31A, relicD31B, relicD31C]) {
```

Then replace:

```dart
        if (p.d31Relics == 'pool') ...const [relicD31A, relicD31B, relicD31C],
```

with:

```dart
        if (p.d31Relics == 'pool') ...[relicD31A, relicD31B, relicD31C],
```

Then replace:

```dart
    final offers = <(RewardDef?, int)>[];
```

with:

```dart
    final offers = <(RewardDef, int)>[];
```

Then replace:

```dart
    // Les mythiques ; `null` est celle de D42c (+1 au `maxLevel` d'une rune).
    // DÉFAUT : Sagesse mythique à +1 (D11, pas de valeur `mythic` en donnée).
    final mythics = <RewardDef?>[
      for (final r in data.rewards)
        if (poolOf(r) == 'mythic') r,
      null,
    ];
    if (p.mythicMode == 'pool') {
      if (rollRewardRarity(levelReward: true) == 'mythic') {
        final r = mythics[rng.nextInt(mythics.length)];
        offers.add((r, r?.values['mythic'] ?? 1));
      }
    } else {
      for (final r in mythics) {
        if (rollRewardRarity(levelReward: true) == 'mythic') {
          offers.add((r, r?.values['mythic'] ?? 1));
        }
      }
    }
    if (offers.any((o) => o.$1 == null)) inc('ceilingOffers');
    _chooseReward(offers);
  }

  void _chooseReward(List<(RewardDef?, int)> offers) {
    for (final (r, amount) in offers) {
      if (r?.id == 'wisdom') {
```

with:

```dart
    // Les mythiques ; la dernière est celle de D42c (+1 au `maxLevel` d'une
    // rune), `transcendence.json`, à la place du `null` qui la jouait avant
    // E3. Sagesse mythique à +1 (D11) : `wisdom.json` porte `values.mythic`
    // 1, égal au repli `?? 1`.
    final mythics = <RewardDef>[
      for (final r in data.rewards)
        if (poolOf(r) == 'mythic') r,
      data.ceilingReward,
    ];
    if (p.mythicMode == 'pool') {
      if (rollRewardRarity(levelReward: true) == 'mythic') {
        final r = mythics[rng.nextInt(mythics.length)];
        offers.add((r, r.values['mythic'] ?? 1));
      }
    } else {
      for (final r in mythics) {
        if (rollRewardRarity(levelReward: true) == 'mythic') {
          offers.add((r, r.values['mythic'] ?? 1));
        }
      }
    }
    if (offers.any((o) => o.$1.id == ceilingRewardId)) inc('ceilingOffers');
    _chooseReward(offers);
  }

  void _chooseReward(List<(RewardDef, int)> offers) {
    for (final (r, amount) in offers) {
      if (r.id == 'wisdom') {
```

Then replace:

```dart
    if (offers.any((o) => o.$1 == null)) {
      // Une rune binaire ne gagne rien à un niveau de plus.
```

with:

```dart
    if (offers.any((o) => o.$1.id == ceilingRewardId)) {
      // Une rune binaire ne gagne rien à un niveau de plus.
```

Then replace:

```dart
    if (offers.any((o) => o.$1?.effect == 'cloneCard') && hasPair && !p.onlyFind) {
```

with:

```dart
    if (offers.any((o) => o.$1.effect == 'cloneCard') && hasPair && !p.onlyFind) {
```

Then replace:

```dart
      if (r == null || r.effect != 'stat') continue;
```

with:

```dart
      if (r.effect != 'stat') continue;
```

`transcendence.json` a l'effet `raiseRuneCap`, jamais `stat` : la mythique saute ce score comme le `null` le sautait.

Then replace:

```dart
      'd29_fusion',
      'd23_relic',
      'd42b_sharpen',
      if (p.exchange == 'event') 'exchange',
    ];
    switch (ids[rng.nextInt(ids.length)]) {
      case 'd29_fusion':
        _eventFusion();
      case 'd23_relic':
        _eventRelicTrade();
      case 'd42b_sharpen':
        _eventSharpen();
```

with:

```dart
      'd29_fusion',
      eventD23,
      eventD42b,
      if (p.exchange == 'event') 'exchange',
    ];
    switch (ids[rng.nextInt(ids.length)]) {
      case 'd29_fusion':
        _eventFusion();
      case eventD23:
        _eventRelicTrade();
      case eventD42b:
        _eventSharpen();
```

- [ ] **Step 5: Analyse**

Run: `dart analyze`
Expected: `No issues found!` — le script en fait partie (`CLAUDE.md`, « Tooling »).

Run: `git grep -n -e "'d23_relic'" -e "'d42b_sharpen'" -e "d31_a_elite" -e "d31_c_extra" -e "d42_whetstone" -e "const \[relicD31A" -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie.

- [ ] **Step 6: La fumée — un diff vide**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_realigned.md`
Expected: environ une minute ; `écrit : <tmp>/d26_realigned.md`.

Run: `git diff --no-index <tmp>/d26_base.md <tmp>/d26_realigned.md`
Expected: code de sortie 0, rien d'affiché — les deux sorties sont identiques, ligne « Données lues » comprise (25 reliques, 8 récompenses, 5 événements). Tout écart est un réalignement faux : la tâche ne se commite pas.

- [ ] **Step 7: La suite**

Run: `flutter test`
Expected: `+1622: All tests passed!` — rien sous `lib/` ni `test/` n'a changé.

- [ ] **Step 8: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): le script lit les entrees du brainstorm dans leurs fichiers

Les reliques A, C et de la Meule, les evenements du Colporteur et du
Remouleur, la mythique Transcendance prennent chacun la place exacte de
leur entree en dur et sortent des listes lues ; un fichier qui jouerait
une entree sans y etre range leve une erreur. Les commentaires qui
citaient du code change par E3 sont rafraichis. Aucune valeur jouee ne
change : le mode rapide rend la meme sortie qu a la base de la vague.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 12: La simulation retire la relique B (second temps, relance 1)

D57, A28 (spec §9, second temps, 1) : la relique B n'existe pas. Elle quitte la réserve et la variante `forced` ; `relicBPerCopy` et ses deux jets disparaissent, avec la variante « B +2 % par exemplaire » ; B sort du compte `d31Copies` ; la variante de référence « **A +25 %, B +1 %, dans la réserve** (réf.) » devient « **A +25 %, dans la réserve** (réf.) », « A, B, C tenues dès l'acte 1 » devient « A et C tenues dès l'acte 1 », et « (+ 4 du brainstorm) » devient « (+ 3 du brainstorm) ». **Un changement voulu** : sa sortie diffère de celle de la Task 11 — B ne prend plus sa place dans la réserve, et ses jets ne consomment plus le générateur. La fumée vérifie que le script tourne ; **l'orchestrateur** relance la mesure complète sur ce commit, explique l'écart et recommite la référence (orchestration §3.6) — aucune tâche du plan ne le fait.

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:73-79` (`Params`), `:105-119`, `:185-236`, la définition de `relicD31B` et sa documentation (Task 11), `:2101`, `:2508`, `:2809-2818` (`visitCombat`), `:3311-3312`, `:3680-3684`, `:3875`

**Interfaces:**
- Consumes: le script réaligné (Task 11).
- Produces: `Params` sans `relicBPerCopy` ; la réserve `[...data.relics, A, C, D42a]`.

- [ ] **Step 1: La relique B quitte le script**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
    this.relicAEliteBonus = 0.25,
    this.relicBPerCopy = 0.01,
    this.d31Relics = 'pool',
```

with:

```dart
    this.relicAEliteBonus = 0.25,
    this.d31Relics = 'pool',
```

Then replace:

```dart
  /// D31, relique B (épique) : +1 % par exemplaire d'une seconde carte en
  /// combat normal et d'une troisième en élite.
  final double relicBPerCopy;

  /// Les trois reliques de D31 : 'pool' (dans la réserve de reliques, A et C
  /// rares, B épique — DÉFAUT), 'forced' (tenues dès l'acte 1, borne haute),
  /// 'absent'.
  final String d31Relics;
```

with:

```dart
  /// Les deux reliques de D31, A et C, rares — B, que D57 supprime, n'existe
  /// plus : 'pool' (dans la réserve de reliques — DÉFAUT), 'forced' (tenues
  /// dès l'acte 1, borne haute), 'absent'.
  final String d31Relics;
```

Then replace:

```dart
    double? relicAEliteBonus,
    double? relicBPerCopy,
    String? d31Relics,
```

with:

```dart
    double? relicAEliteBonus,
    String? d31Relics,
```

Then replace:

```dart
        relicAEliteBonus: relicAEliteBonus ?? this.relicAEliteBonus,
        relicBPerCopy: relicBPerCopy ?? this.relicBPerCopy,
        d31Relics: d31Relics ?? this.d31Relics,
```

with:

```dart
        relicAEliteBonus: relicAEliteBonus ?? this.relicAEliteBonus,
        d31Relics: d31Relics ?? this.d31Relics,
```

Then replace:

```dart
        normalGuaranteed, eliteExtra, relicAEliteBonus, relicBPerCopy,
        d31Relics, mirrorPool, exchange, wellEvery, altar, sharpenB, wellBase,
```

with:

```dart
        normalGuaranteed, eliteExtra, relicAEliteBonus,
        d31Relics, mirrorPool, exchange, wellEvery, altar, sharpenB, wellBase,
```

Then replace (Task 11):

```dart
/// Les reliques du brainstorm. D31 : A « monte la chance de seconde carte en
/// élite » (rare), B « une épique » (+1 %), C « une carte garantie de plus »
/// (rare). D42a : une légendaire porte au-delà de 1 le nombre de runes
/// affûtées par la récompense de boss « XP ». A, C et D42a sont des fichiers
/// depuis E3 (`brainstormRelicFiles`) : leurs définitions se construisent sur
/// eux au chargement (`GameData.load`), à la place exacte de leur entrée en
/// dur ; B reste en dur.
RelicDef get relicD31A => data.relicD31A;
const relicD31B = RelicDef('d31_b_lucky', 3, 'special', 'd31b', 0);
RelicDef get relicD31C => data.relicD31C;
```

with:

```dart
/// Les reliques du brainstorm. D31 : A « monte la chance de seconde carte en
/// élite » (rare), C « une carte garantie de plus » (rare) — B, que D57
/// supprime, n'existe plus. D42a : une légendaire porte au-delà de 1 le
/// nombre de runes affûtées par la récompense de boss « XP ». Toutes sont des
/// fichiers depuis E3 (`brainstormRelicFiles`) : leurs définitions se
/// construisent sur eux au chargement (`GameData.load`), à la place exacte
/// de leur entrée en dur.
RelicDef get relicD31A => data.relicD31A;
RelicDef get relicD31C => data.relicD31C;
```

Then replace:

```dart
      for (final r in [relicD31A, relicD31B, relicD31C]) {
```

with:

```dart
      for (final r in [relicD31A, relicD31C]) {
```

Then replace:

```dart
        if (p.d31Relics == 'pool') ...[relicD31A, relicD31B, relicD31C],
```

with:

```dart
        if (p.d31Relics == 'pool') ...[relicD31A, relicD31C],
```

Then replace:

```dart
    // D31 : la table `cardDrops`, puis les reliques A, B, C.
    var n = elite ? 1 : p.normalGuaranteed + copies(relicD31C.id);
    if (elite) {
      if (rng.nextDouble() < p.eliteExtra + p.relicAEliteBonus * copies(relicD31A.id)) {
        n++;
        if (rng.nextDouble() < p.relicBPerCopy * copies(relicD31B.id)) n++;
      }
    } else if (rng.nextDouble() < p.relicBPerCopy * copies(relicD31B.id)) {
      n++;
    }
```

with:

```dart
    // D31 : la table `cardDrops`, puis les reliques A et C (D57).
    var n = elite ? 1 : p.normalGuaranteed + copies(relicD31C.id);
    if (elite &&
        rng.nextDouble() < p.eliteExtra + p.relicAEliteBonus * copies(relicD31A.id)) {
      n++;
    }
```

Then replace:

```dart
      'd31Copies': (copies(relicD31A.id) + copies(relicD31B.id) + copies(relicD31C.id))
          .toDouble(),
```

with:

```dart
      'd31Copies': (copies(relicD31A.id) + copies(relicD31C.id)).toDouble(),
```

Then replace:

```dart
        Variant('**A +25 %, B +1 %, dans la réserve** (réf.)', ref),
        Variant('A +15 %', ref.copyWith(relicAEliteBonus: 0.15)),
        Variant('A +50 %', ref.copyWith(relicAEliteBonus: 0.5)),
        Variant('B +2 % par exemplaire', ref.copyWith(relicBPerCopy: 0.02)),
        Variant('A, B, C tenues dès l’acte 1', ref.copyWith(d31Relics: 'forced')),
```

with:

```dart
        Variant('**A +25 %, dans la réserve** (réf.)', ref),
        Variant('A +15 %', ref.copyWith(relicAEliteBonus: 0.15)),
        Variant('A +50 %', ref.copyWith(relicAEliteBonus: 0.5)),
        Variant('A et C tenues dès l’acte 1', ref.copyWith(d31Relics: 'forced')),
```

Then replace:

```dart
      '${data.relics.length} reliques (+ 4 du brainstorm), '
```

with:

```dart
      '${data.relics.length} reliques (+ 3 du brainstorm), '
```

- [ ] **Step 2: Analyse et contrôle**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e relicD31B -e relicBPerCopy -e d31_b_lucky -e "B +" -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie.

- [ ] **Step 3: La fumée**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_b.md`
Expected: environ une minute ; `écrit : <tmp>/d26_b.md` ; la ligne « Données lues » dit « 25 reliques (+ 3 du brainstorm) ». Contre la fumée de la Task 11, si elle est encore là, `git diff --no-index <tmp>/d26_realigned.md <tmp>/d26_b.md` rend un écart : c'est le changement voulu, que l'orchestrateur mesure et explique — la tâche ne s'y juge pas.

- [ ] **Step 4: La suite**

Run: `flutter test`
Expected: `+1622: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): la relique B quitte le script (D57)

B sort de la reserve et de la variante forcee ; ses deux jets, son
levier et sa variante disparaissent, et le compte des reliques de D31 ne
compte plus qu A et C. La mesure complete revient a l orchestrateur.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 13: La simulation retire l'événement de fusion de D29 (second temps, relance 2)

D56, A28 (spec §9, second temps, 2) : l'événement de fusion de D29 sort du chantier. `'d29_fusion'` quitte la liste tirée des événements, avec `_eventFusion` ; sa mesure, « Fusions par l'événement D29 (cumul) », ne compte plus rien et quitte la sortie — sa ligne des tables de référence, sa colonne des annexes, son libellé court ; « (+ 3 du brainstorm) » devient « (+ 2 du brainstorm) ». **Un changement voulu**, relancé à part de la relique B (D73) : la liste tirée raccourcit d'un élément. La fumée vérifie que le script tourne ; l'orchestrateur relance, explique et recommite.

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:2019` (`metricDefs`), `:2380` (documentation de `pickThree`), `:2976-2989` (`visitEvent`), `:3055-3070` (`_eventFusion`), `:3548` (`annexMetrics`), `:3559` (`shortLabels`), `:3877`

**Interfaces:**
- Consumes: le script de la Task 12.
- Produces: la liste tirée `[...data.events, D23, D42b]` (et `exchange` sous sa variante) ; plus de mesure `fusionsEvent`.

- [ ] **Step 1: L'événement de D29 quitte le script**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
  ('fusions', 'Fusions de 3 copies (cumul)', 0),
  ('fusionsEvent', 'Fusions par l’événement D29 (cumul)', 0),
```

with:

```dart
  ('fusions', 'Fusions de 3 copies (cumul)', 0),
```

Then replace (Task 11):

```dart
      'd29_fusion',
      eventD23,
      eventD42b,
      if (p.exchange == 'event') 'exchange',
    ];
    switch (ids[rng.nextInt(ids.length)]) {
      case 'd29_fusion':
        _eventFusion();
      case eventD23:
```

with:

```dart
      eventD23,
      eventD42b,
      if (p.exchange == 'event') 'exchange',
    ];
    switch (ids[rng.nextInt(ids.length)]) {
      case eventD23:
```

Then delete the method `_eventFusion` and its documentation — the whole block:

```dart
  /// D29 (Q18, DÉFAUT validé) : 10 % des PV max + 30 or × rang visé ; trois
  /// cartes de même rareté, la gagnante tirée, les runes héritées (D13).
  void _eventFusion() {
    if (deck.length < 12) return;
    final three = pickThree();
    if (three == null) return;
    final hpCost = (maxHp * 0.10).round();
    final goldCost = 30 * (three.first.rank + 1);
    if (gold < goldCost || hp <= hpCost + 1) return;
    if (passive.id != 'rage' && hp < maxHp * 0.3) return;
    spend(goldCost);
    hp -= hpCost;
    fuseInto(three, three[rng.nextInt(3)].def);
    inc('fusionsEvent');
    fuseAll();
  }

```

(the blank line after it included). `pickThree`, `fuseInto` et `fuseAll` gardent leurs autres appelants (l'échange 3 → 1, la fusion).

`pickThree` ne sert plus que l'échange 3 → 1 de D8 : sa documentation, qui cite D29, devient fausse ici. Replace:

```dart
  /// Trois cartes de même rang, les moins utiles, hors paires (D29, D8).
```

with:

```dart
  /// Trois cartes de même rang, les moins utiles, hors paires (D8).
```

Then replace:

```dart
  'deck', 'fusions', 'fusionsEvent', 'bestRank', 'runes', 'runeSum', 'runeMax',
```

with:

```dart
  'deck', 'fusions', 'bestRank', 'runes', 'runeSum', 'runeMax',
```

Then replace:

```dart
  'fusions': 'Fusions',
  'fusionsEvent': 'Fusions D29',
```

with:

```dart
  'fusions': 'Fusions',
```

Then replace:

```dart
      '${data.events.length} événements (+ 3 du brainstorm).');
```

with:

```dart
      '${data.events.length} événements (+ 2 du brainstorm).');
```

- [ ] **Step 2: Analyse et contrôle**

Run: `dart analyze`
Expected: `No issues found!` — sans `_eventFusion`, aucun membre ne reste sans lecteur (`fuseInto` sert la fusion, `pickThree` l'échange 3 → 1).

Run: `git grep -n -e d29_fusion -e _eventFusion -e fusionsEvent -e D29 -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie.

- [ ] **Step 3: La fumée**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_d29.md`
Expected: environ une minute ; `écrit : <tmp>/d26_d29.md` ; « 5 événements (+ 2 du brainstorm) » ; aucune ligne « Fusions par l’événement D29 », aucune colonne « Fusions D29 ». L'écart avec la fumée de la Task 12 est le changement voulu, que l'orchestrateur mesure et explique.

- [ ] **Step 4: La suite**

Run: `flutter test`
Expected: `+1622: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): l evenement de fusion de D29 quitte le script (D56)

Il sort de la liste tiree des evenements, avec sa resolution ; sa mesure
ne compte plus rien et quitte la sortie. La mesure complete revient a l
orchestrateur.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 14: La simulation lit la table d'XP du jeu, et dit « d'avant E3 » ce que le jeu n'a plus (second temps, relance 3)

Spec §9, second temps, 3 : la référence joue `xpTable` lu dans `assets/data/xp_curve.json` (`xpPerLevelByAct`, D67) au lieu de la table calée (`final ref = t2;`, `:3842`). **La calibration reste affichée** (`:3880-3887`) : ses variantes « 3 niv./acte » et « palier constant » restent calées ; la ligne « Table par acte (réf.) », qui désigne `t2`, devient « Table par acte, calée », et une ligne « Table par acte (réf., `xp_curve.json`) » écrit la table lue — la sortie recommitée, que la vague suivante relira, dit laquelle sert de référence. **La même tâche renomme les trois libellés imprimés** gardés au premier temps (`:2046`, `:3733`, `:3745`) en « d’avant E3 ». **Un changement voulu** : la référence jouait la table recalée après la vague 2, à −25 à +40 XP de D67 selon l'acte (spec §1.3) ; et un écart de libellé, dit d'avance, sur huit lignes de la référence : les sept qui écrivent aujourd'hui « actuelle » (64, 665, 673, 687, 703, 710, 724 de `d26_reference_output.md`) et l'en-tête de la table de calibration (ligne 9, « Valeur calée » devenu « Valeur ») — plus, dans cette table, la ligne « Table par acte (réf.) » (ligne 11) renommée « Table par acte, calée » et la ligne neuve « Table par acte (réf., `xp_curve.json`) » qui la précède. La fumée vérifie que le script tourne ; l'orchestrateur relance, explique et recommite.

La variante du levier « Forme de la courbe d'XP » qui joue la référence garde son libellé, « **table par acte, 2 niv./acte** (réf.) » (`:3734`) : la spec ne le nomme pas parmi les libellés qui changent, et il reste vrai — la table de D67 est la table par acte calée sur deux niveaux par acte, telle que la référence la calait en `37aa9d5` (spec §1.3).

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:7-9` (l'en-tête : les données relues), `GameData` (son constructeur et ses champs, tels que la Task 11 les écrit), le `return` de `GameData.load` (Task 11), `:2046`, `:3733`, `:3745`, `:3842`, `:3882-3883`

**Interfaces:**
- Consumes: le script de la Task 13 ; `assets/data/xp_curve.json` (partie 1), `{"xpPerLevelByAct": [115, …, 1015]}`.
- Produces: `GameData.xpCurve` (`List<int>`) ; la référence `base.copyWith(xpCurve: 'perAct', xpTable: data.xpCurve)`.

- [ ] **Step 1: Le script lit la courbe**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
// avec son `fichier:ligne` ; les DONNÉES (ennemis, neutres, signatures,
// reliques, récompenses de niveau, runes, passifs, classes) sont relues dans
// assets/data/ à chaque lancement.
```

with:

```dart
// avec son `fichier:ligne` ; les DONNÉES (ennemis, neutres, signatures,
// reliques, récompenses de niveau, runes, passifs, classes, courbe d'XP) sont
// relues dans assets/data/ à chaque lancement.
```

Then replace (Task 11):

```dart
class GameData {
  GameData._(this.enemies, this.neutrals, this.relics, this.rewards,
      this.classes, this.passives, this.runes, this.events, this.relicD31A,
      this.relicD31C, this.relicD42, this.ceilingReward);
```

with:

```dart
class GameData {
  GameData._(this.enemies, this.neutrals, this.relics, this.rewards,
      this.classes, this.passives, this.runes, this.events, this.relicD31A,
      this.relicD31C, this.relicD42, this.ceilingReward, this.xpCurve);
```

Then replace (Task 11):

```dart
  final RelicDef relicD42;
  final RewardDef ceilingReward;
```

with:

```dart
  final RelicDef relicD42;
  final RewardDef ceilingReward;

  /// La table d'XP par acte du jeu, `xpPerLevelByAct` de `xp_curve.json`
  /// (D67) : la référence la joue (`main`) ; la calibration reste affichée.
  final List<int> xpCurve;
```

Then replace (Task 11):

```dart
    return GameData._(
      enemies,
```

with:

```dart
    // La courbe d'XP (D67) : refusée comme le jeu la refuse
    // (`XpCurveData.fromJson`) — une liste non vide d'entiers ≥ 1.
    final xpCurve = [
      for (final x in _json('$root/xp_curve.json')['xpPerLevelByAct'] as List)
        x as int,
    ];
    if (xpCurve.isEmpty || xpCurve.any((x) => x < 1)) {
      throw StateError('xp_curve.json : xpPerLevelByAct doit être une liste '
          'non vide d’entiers ≥ 1');
    }

    return GameData._(
      enemies,
```

Then replace (Task 11):

```dart
      ceiling ??
          (throw StateError('récompense « $ceilingRewardId » : son fichier '
              'manque')),
    );
  }
```

with:

```dart
      ceiling ??
          (throw StateError('récompense « $ceilingRewardId » : son fichier '
              'manque')),
      xpCurve,
    );
  }
```

- [ ] **Step 2: La référence joue la table lue ; la calibration dit laquelle**

Replace:

```dart
  final ref = t2;
```

with:

```dart
  // La référence joue la table du jeu (D67) ; les tables calées restent
  // affichées, et leurs variantes jouées par les leviers.
  final ref = base.copyWith(xpCurve: 'perAct', xpTable: data.xpCurve);
```

Then replace:

```dart
  table(out, ['Forme', 'Cible', 'Valeur calée'], [
    ['Table par acte (réf.)', '2 niv./acte', t2.xpTable.join(' · ')],
```

with:

```dart
  table(out, ['Forme', 'Cible', 'Valeur'], [
    ['Table par acte (réf., `xp_curve.json`)', 'D67', ref.xpTable.join(' · ')],
    ['Table par acte, calée', '2 niv./acte', t2.xpTable.join(' · ')],
```

`t2` garde un lecteur, la ligne calée ; `base` en gagne un. L'en-tête de colonne « Valeur calée » devient « Valeur » : sa première ligne est désormais une table **lue**, et non calée.

- [ ] **Step 3: Les trois libellés « actuelle »**

Replace:

```dart
  ('budgetCur', 'Budget sous la DDA actuelle (cartes × 2)', 0),
```

with:

```dart
  ('budgetCur', 'Budget sous la DDA d’avant E3 (cartes × 2)', 0),
```

Then replace:

```dart
        Variant('actuelle, 100 × 1,5^(n−1)', ref.copyWith(xpCurve: 'current')),
```

with:

```dart
        Variant('d’avant E3, 100 × 1,5^(n−1)', ref.copyWith(xpCurve: 'current')),
```

Then replace:

```dart
        Variant('actuelle, cartes × 2', ref.copyWith(ddaK: -1)),
```

with:

```dart
        Variant('d’avant E3, cartes × 2', ref.copyWith(ddaK: -1)),
```

L'apostrophe est la typographique (`’`, U+2019), comme dans « l’acte » partout ailleurs dans les chaînes du script.

- [ ] **Step 4: Analyse et contrôle**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n "actuelle" -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie — la Task 11 a déjà réécrit le commentaire de `ddaK` (`:156`).

Run: `git grep -n "final ref = t2" -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie.

- [ ] **Step 5: La fumée**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_xp.md`
Expected: environ une minute ; `écrit : <tmp>/d26_xp.md`. La table de calibration a pour en-tête `| Forme | Cible | Valeur |` et porte cinq lignes, dont `| Table par acte (réf., `xp_curve.json`) | D67 | 115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015 |` et `| Table par acte, calée | 2 niv./acte | … |`.

Run: `grep -c -e "actuelle" -e "Valeur calée" <tmp>/d26_xp.md`
Expected: `0`.

Run: `grep -c "avant E3" <tmp>/d26_xp.md`
Expected: `7` — les sept lignes qui écrivent « actuelle » dans la référence d'aujourd'hui.

- [ ] **Step 6: La suite**

Run: `flutter test`
Expected: `+1622: All tests passed!`

- [ ] **Step 7: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): la reference joue la table d xp du jeu (D67)

La reference lit xpPerLevelByAct dans xp_curve.json au lieu de la table
calee, toujours affichee avec ses variantes ; la colonne de la
calibration dit Valeur, et non plus Valeur calee. Les trois libelles qui
disaient actuelle ce que le jeu n a plus disent d avant E3. La mesure
complete revient a l orchestrateur.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
EOF
```

---

### Task 15: Vérification finale de la vague

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf — une tâche du code avant la Task 11, jamais une retouche de `assets/data/` après elle (spec §9) —, et cette tâche se rejoue en entier. `<base>` désigne le commit qui **ajoute** ce plan — un commit ultérieur sur le plan ne le déplace pas : `git log --diff-filter=A --format=%H -- docs/superpowers/plans/2026-10-04-p43-e3-trouvaille-et-progression-partie-2.md` ; si la commande ne rend rien (le plan n'a pas été commité), `30027a9`.

**Files:** aucun.

**Interfaces:**
- Consumes: la partie 2 entière.
- Produces: la branche `feat/v0.5.5-p43-e3-trouvaille`, la vague implémentée — rien de poussé, aucune PR. Les quatre mesures complètes de la simulation, la note de version et la synchronisation de la mémoire reviennent à l'orchestrateur (voir la fin du plan).

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1622: All tests passed!` — 1535 + 87, dont `tutorial_isolation_test.dart` (ADR-081), `real_bundle_load_test.dart` (94 fichiers d'entité, 28 reliques, 7 événements, 9 récompenses de niveau), `entity_id_convention_test.dart` (94), `audio_catalogue_test.dart` (55 fichiers de contenu), `shipped_entities_round_trip_test.dart` (chaque fichier livré, les quatre neufs et les cinq retouchés compris, se réécrit à l'identique), `notification_notifier_test.dart` (le plafond de cinq) et les tests de widget de l'écran d'événement, de la fiche des probabilités, de la fiche des stats et du draft.

Run: `flutter gen-l10n`, puis `git status --short lib/l10n`
Expected: aucune sortie — les trois `lib/l10n/app_localizations*.dart` commités sont ceux que les ARB produisent.

- [ ] **Step 2: Les trois commandes de la fin de la vague (spec §8)**

Run: `git grep -n -e "GameConstants.maxHandSize" -e playerCardsCount -e rolledBonusCard -e "pow(1.5" -e calculateDraftProbabilities -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e xpToNextLevel -e _armorPerTranche -e "XP & Or x2" -e "2x XP" -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e cardsCount -- lib`
Expected: aucune sortie (sur `lib` seul : l'assertion d'absence de `combat_debug_logger_test.dart` écrit le littéral).

- [ ] **Step 3: Les cinq commandes de l'écran de combat et de la carte du monde (spec §8)**

Run: `git grep -n fusionRankSum -- lib/ui/screens/game_screen.dart`
Expected: une ligne — l'argument `deckFusionRanks:` de l'appel de la DDA.

Run: `git grep -n sharpenedRunes -- lib/ui/screens/game_screen.dart`
Expected: au moins une ligne — `final sharpened = ref.read(rewardProvider).sharpenedRunes;` (Task 2).

Run: `git grep -n "rewardState.sharpenedRunes" -- lib`
Expected: aucune sortie — la copie `rewardState` est prise avant `collectGoldAndXp`.

Run: `git grep -n rewardCardFound -- lib/ui/screens/game_screen.dart`
Expected: au moins une ligne — la notification de la trouvaille (partie 1).

Run: `git grep -n tooltipBossXpDesc -- lib/ui/widgets/map/map_node_widget.dart`
Expected: une ligne — la description de l'infobulle du boss « XP » (Task 2).

- [ ] **Step 4: Les lecteurs de la partie 2**

Run: `git grep -n "raiseRuneLevel(" -- lib`
Expected: la déclaration (`lib/game/controllers/deck_controller.dart`) et trois appels, un dans chacun de `lib/game/controllers/run/gold_manager.dart` (le feu), `lib/game/controllers/reward_controller.dart` (le boss « XP ») et `lib/game/controllers/event_controller.dart` (le *Rémouleur*) — aucun sous `lib/ui/` : un écran n'écrit jamais un niveau.

Run: `git grep -n "isSelectable(" -- lib`
Expected: deux lignes — la déclaration (`lib/models/data/event_data.dart`) et l'appel d'`EventController.isChoiceSelectable` (`lib/game/controllers/event_controller.dart`).

Run: `git grep -n "runeCapBonus" -- lib/ui`
Expected: des lignes dans `deck_screen.dart`, `rest_screen.dart`, `rest_card_selection_screen.dart`, `forge_fusion_screen.dart`, `draft_screen.dart` et `widgets/forge/sharpen_rune_dialog.dart`, et dans aucun autre fichier de `lib/ui/`.

Run: `git grep -n "describeMastery(" -- lib`
Expected: quatre lignes — la déclaration (`lib/models/data/passive_data.dart`) et ses trois lecteurs, `lib/models/data/level_up_reward_data.dart` (la carte d'*Affinité*), `lib/ui/widgets/map/dialogs/stats_dialog.dart` et `lib/ui/widgets/class_passive_list.dart`.

Run: `git grep -n -e "mastery.describe(" -e "mastery!.describe(" -e "threshold < 1 ? 1" -e "Trèfle / Miroir" -e "Clover / Mirror" -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e bossXpRuneSharpens -e extraBossRuneSharpens -- lib`
Expected: des lignes dans `lib/game/game_constants.dart` (la constante), `lib/game/controllers/run_controller.dart` (le champ de `RunState`), `lib/game/controllers/run/player_stats_manager.dart` (la règle de run de la *Meule*) et `lib/game/controllers/reward_controller.dart` (le tirage), et dans aucun autre.

Run: `git grep -n "maxVisible" -- lib`
Expected: des lignes dans `lib/ui/widgets/notification_overlay.dart` seulement — la constante, `5`, et sa lecture.

- [ ] **Step 5: La donnée, la simulation, ce qui n'est pas à nous**

Run: `git diff --name-only <base>..HEAD -- assets`
Expected: exactement neuf fichiers — `assets/data/events/relic_peddler.json`, `assets/data/events/wandering_grinder.json`, `assets/data/forge_upgrades/cheap.json`, `assets/data/forge_upgrades/enduring.json`, `assets/data/level_up_rewards/transcendence.json`, `assets/data/level_up_rewards/wisdom.json`, `assets/data/passives/blessing.json`, `assets/data/passives/mana_flux.json`, `assets/data/relics/grindstone.json`.

Run: `git log --oneline --name-only <base>..HEAD -- assets tool/simulations`
Expected: en tête, les quatre commits de la simulation (Tasks 14, 13, 12, 11, du plus récent au plus ancien), qui ne touchent que `tool/simulations/d26_economy_sim.dart` ; sous eux seulement, les commits qui touchent `assets/data/` (Tasks 10, 7, 6, 5, 4, 3) — aucune retouche de la donnée après le réalignement (spec §9).

Run: `git diff --name-only <base>..HEAD -- tool`
Expected: une seule ligne, `tool/simulations/d26_economy_sim.dart` — la référence `d26_reference_output.md` n'a pas bougé : l'orchestrateur la recommite.

Run: `git diff --stat <base>..HEAD -- site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni `site/`, ni la note de version, ni la version, ni `pubspec.yaml` (aucun dossier neuf sous `assets/`), ni un fichier généré de plateforme.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0.

- [ ] **Step 6: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline <base>..HEAD`
Expected: au moins les quatorze commits des Tasks 1 à 14, plus les commits de correction éventuels. Rien n'est poussé.

---

## Ce que le plan laisse à l'orchestrateur

Aucune tâche de ce plan ne les fait (orchestration §3.5, §3.6 ; spec §9, §11) :

1. **Les quatre mesures complètes de la simulation**, chacune sur son commit, extrait **hors du dépôt** par `git archive <commit> tool/simulations assets/data` dans le dossier temporaire de la session, l'une après l'autre :
   - le réalignement (Task 11) : **diff entièrement vide** contre `tool/simulations/d26_reference_output.md`, ligne « Données lues » comprise ; un écart est un réalignement faux, et la Task 11 se reprend ;
   - la relique B retirée (Task 12), puis l'événement de D29 retiré (Task 13) : chacun un écart voulu, expliqué au compte rendu, la référence recommitée ;
   - la table d'XP lue dans `xp_curve.json` (Task 14) : l'écart de la table — la référence jouait la table recalée après la vague 2, à −25 à +40 XP de D67 selon l'acte (spec §1.3) — et l'écart de libellé, dit d'avance, sur huit lignes — les sept qui écrivaient « actuelle » et l'en-tête « Valeur calée » de la table de calibration, devenu « Valeur » —, plus la ligne « Table par acte (réf.) » renommée « Table par acte, calée » et la ligne neuve « Table par acte (réf., `xp_curve.json`) » qui la précède ; la référence recommitée.
2. **Le compte rendu de la vague** et son entrée non technique dans `docs/suivi_vagues_chantier/` (modèle `_modele_suivi.md`).
3. **La note de version `0.5.5`** (`patch-notes-writer`), dont la spec §11 donne le contenu joueur, et **`memory-bank-sync`**, dont la spec §11 donne l'ADR neuf et les fiches à réécrire ou relire. Constaté en écrivant ce plan, à ajouter à sa liste : le plafond des notifications passe de quatre à cinq (`NotificationNotifier.maxVisible`, Task 3) ; `GoldManager.sharpenRune` et `exchangeRune` prennent `capBonus` requis, et `sharpenRune` délègue l'écriture à `DeckNotifier.raiseRuneLevel` (Tasks 1, 8) ; `RestCardSelectionScreen` et `SharpenRuneDialog` ont un mode gratuit (`isFree`, Task 5) ; l'en-tête de la simulation compte la courbe d'XP parmi les données relues (Task 14).
4. **Le test, la fusion et l'étiquette** : le propriétaire teste, fusionne, puis étiquette (orchestration §3.5).
