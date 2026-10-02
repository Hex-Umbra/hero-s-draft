# P-43 E2, partie 1 — La fusion devient la forge — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** La rune quitte le feu de camp pour la fusion : chaque fusion 3 → 1 garde toutes les runes de ses trois exemplaires et en offre une parmi trois, tirées par le prédicat au rang que la fusion atteint (`minFusionRank`, une rune par type) ; le feu affûte une rune d'un niveau contre `50 × niveau` or ; la capacité de forge, la session de forge et les fentes achetées disparaissent ; le tutoriel enseigne le choix de la rune. La Forge de Fusion, la boutique et `pools` / `stackable` restent ceux d'aujourd'hui : c'est la partie 2.

**Architecture:** `ForgeUpgradeData` gagne `minFusionRank`, obligatoire dans le fichier ; `ForgeRuneRules.isEligible` le compare au rang de la carte qui reçoit la rune et refuse toute rune qu'elle porte déjà (conditions 7 et 8 de la spec §4.3). `ForgeRuneRules.drawRunes`, fonction pure, tire jusqu'à trois runes éligibles, pondérées, sans remise ; l'écran de deck l'appelle sur la carte que `DeckNotifier.mergeCards` rend — l'héritage calculé dedans, sans troncature —, puis ouvre `ForgeUpgradeDialog`, réduit au choix, qui pose `id:1` par `addForgeUpgrade`. L'affûtage vit dans `GoldManager.sharpenRune` (payer et écrire, ou rien), ses formules dans `ForgeRuneRules` (`sharpenCost`, `canSharpen`, `replaceRune`) ; le feu y mène par sa sélection et un dialogue neuf, `SharpenRuneDialog`. `ForgeSlotRow` devient la ligne de rune des deux dialogues. Le tutoriel appelle `drawRunes` sur son propre registre (ADR-081).

**Tech Stack:** Flutter 3.41 / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-02-p43-e2-fusion-forge-design.md` — §10, « Partie 1 ». À lire **en entier** : la partie 1 renvoie à §1.2 (A1 à A20 et les trois tableaux « Tranchés… »), §3, §4.1 à §4.7, §4.10, §4.12 à §4.14, §5, §6, §7, §8 (dont « La partie de chaque suppression » et « Les tests qui suivent »), §9 et §11. Le déroulé du programme fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (fiche §8.2). E1 est fusionné : le prédicat, `boundLevel`, `consolidate`, `parseRef` / `levelsOf`, `EffectiveCard` existent, aucune tâche ne les réécrit au-delà de ce que la spec E2 demande.

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier, et la copie périmée d'un fichier disparu continue d'être chargée ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer` ;
- aucun worktree.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.4-p43-e2-fusion-forge`, la branche courante. Il **ne crée aucune branche**, ne bascule sur aucune autre, ne commite rien sur `main`. Pas de worktree, même si le skill d'exécution en propose un.
- **La base de tests : 1375**, le total de `flutter test` sur la branche le 2026-10-02 (`90dd137`). Chaque tâche donne le total attendu — 1375, plus les tests qu'elle ajoute, moins ceux qu'elle retire, comptés sur les blocs de test que le plan écrit (un cas réécrit compte pour zéro ; un `for` qui engendre des tests compte pour ce qu'il engendre) :

  | Tâche | Ajoutés | Retirés | Total |
  |:---|---:|---:|---:|
  | 1 — le prédicat | 46 | 23 | 1398 |
  | 2 — la capacité | 5 | 5 | 1398 |
  | 3 — la fusion offre une rune | 13 | 7 | 1404 |
  | 4 — le feu affûte | 19 | 2 | 1421 |
  | 5 — le tutoriel | 5 | 0 | 1426 |

  Task 1 : la matrice du catalogue perd ses 23 cas à la rareté de donnée et en gagne 40 (17 cartes neutres aux rangs 1 et 2, six signatures à leur rareté `unique`).
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-02 sur `90dd137`, avant toute tâche. Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le périmètre : la partie 1, et elle seule** (spec §10). Rien du Puits — `ForgeFusionScreen`, `fusionOptionsFor`, `FusionOption`, le placement à 25 % restent tels quels —, rien de la boutique au-delà de la borne des pré-forgées par `fusionRank` (ni copie du deck, ni étal retenu, ni `drawRunes` dans les pré-forgées), aucune des trois runes neuves, ni `reduceCost` / `critBonus` / `addExhaust`, ni le badge (A13), ni `{val}` (A14), ni `runeIcons` / `runeColors` (A19), ni la suppression de `pools` et de `stackable`, ni la simulation.
- **Le point propre au lot** (fiche §8.2, spec §4.10, §4.11, §10 « Entre les deux parties ») : à la fin de la partie 1, **la capacité n'a plus aucun lecteur** ; **la session de forge et les fentes achetées non plus** ; `pools` n'est plus lu que par le tirage des pré-forgées (`shop_controller.dart`) et l'éditeur ; `stackable` que par `consolidate`, `fusionOptionsFor`, le niveau des pré-forgées et l'éditeur. Aucune tâche n'ajoute de lecteur à `pools` ni à `stackable`.
- **La simulation** (spec §9) : la partie 1 ne touche pas `tool/simulations/d26_economy_sim.dart` ni `tool/simulations/d26_reference_output.md` — **aucune tâche ne modifie `tool/`**. Le script lit dans `assets/data/forge_upgrades/` les champs `id`, `weight` et `eligibleCardTypes` et plante sur un champ qu'il attend et qui manque : **aucune tâche ne change le `weight` d'une rune, ni ses `eligibleCardTypes`, ni ne retire un champ qu'il lit** ; `minFusionRank`, champ neuf, lui est indifférent, et `baseMaxForgeUpgrades` n'est pas lu (`cardFromJson`). Le réalignement (premier temps) et `spectral` (second temps) sont des tâches de la partie 2 ; aucune tâche ne lance le script.
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). `RunState` perd quatre clés, `CardData` perd `baseMaxForgeUpgrades` : une sauvegarde plus ancienne les porte, la lecture les ignore. Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version ; rien de cela n'est testé.
- **Le tutoriel ne référence aucun provider** (ADR-081) : il appelle `ForgeRuneRules`, fonction pure, sur `TutorialEngine.data` ; `test/tutorial/tutorial_isolation_test.dart` reste vert. Il ne nomme aucun id de carte hors de `TutorialFixtureIds`.
- **Aucun id de rune livrée en littéral dans `lib/`** : `test/unit/rune_ids_in_code_test.dart` le garde.
- **Les lints** (`flutter_lints` 6) que le code du plan respecte : `sort_child_properties_last`, `use_build_context_synchronously` (`mounted` / `context.mounted` après chaque `await`), `curly_braces_in_flow_control_structures` (accolades à toute boucle), `no_leading_underscores_for_local_identifiers` (aucune fonction locale en `_`).

## Review Focus

Les trois cas que la spec implique sans qu'un test de son §8 les pose, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **Une rune dont le fichier déclare `weight: 0`** — rien ne l'interdit (`ForgeUpgradeData.fromJson` lit tout entier). Un tirage pondéré naïf lève sur `Random.nextInt(0)` ou ne la tire jamais, ce qui défait D65 (« jamais aucune tant qu'une existe »). Test : Task 3, `forge_rune_rules_test.dart`, « des runes de poids nul se tirent encore ».
2. **L'or tout juste suffisant** — `spendGold` accepte l'égalité ; l'affûtage aussi, et laisse 0. Test : Task 4, `run_controller_test.dart`, « depense 50 x n … » (100 or pour `sharp:2`).
3. **Une référence de rune mal formée** (`test_rune`, sans niveau) — l'analyseur unique la refuse, la prise montre l'emoji par défaut au lieu de deviner un id. Test : Task 2, `ui_card_rune_sockets_test.dart`, « une reference mal formee prend l emoji par defaut ».

## Ce que le plan précise ou corrige de la spec

Constaté en re-mesurant le code sur `90dd137` ; aucun n'amende un arbitrage.

1. **L'ordre des tâches est forcé par deux coutures.** `ForgeUpgradeDialog` sert aujourd'hui la forge du feu ; le réduire au choix de la fusion (Task 3) sans que le feu change le laisserait sans lecteur si l'affûtage venait d'abord. Et `GoldManager` n'a qu'une méthode, `buyBonusForgeSlot`, que A3 supprime avec le dialogue. D'où : Task 3 réduit le dialogue et supprime la session, les fentes achetées et `GoldManager` — **la forge du feu y appelle le dialogue réduit, avec une offre de `drawRunes`, le temps d'une tâche** (six lignes de `rest_card_selection_screen.dart` que Task 4 remplace) ; Task 4 remplace la forge du feu par l'affûtage et **recrée `lib/game/controllers/run/gold_manager.dart`** pour `sharpenRune` (A16). Garder une classe vide une tâche durant serait du code mort ; `CLAUDE.md`, qui cite le fichier, est de nouveau exact à la fin de Task 4.
2. **Le prédicat vient en premier (Task 1)** : il change ce que la forge du feu, encore vivante, propose à une commune — plus rien (condition 7). Trois cas de `forge_upgrade_dialog_test.dart` et un de `rest_card_selection_screen_test.dart` passent à une carte peu commune ou rare dans Task 1 ; ces deux fichiers sont réécrits en Task 3 et Task 4.
3. **Le repli du tirage des pré-forgées devient mort en Task 1.** `shop_controller.dart:135-136` retire sans exclusion quand le premier tirage échoue ; avec la condition 8, les runes exclues du premier tirage — celles que la carte porte — sont déjà refusées par le prédicat : le second appel rend toujours `null` quand le premier l'a rendu. Il part, avec le commentaire `:132-134` (« deux `sharp` restent possibles, « une rune par type » est E2 »), devenu faux. Le reste du tirage par `pools` reste jusqu'en partie 2.
4. **`card_rarity_test.dart` perd son assistant `_cardData` (`:5-18`) et l'import de `card_instance.dart`** avec le groupe de capacité : seul ce groupe les lisait. La spec (§8, « Les tests qui suivent ») ne les voyait que perdre leur paramètre.
5. **`run_state_persistence_test.dart` perd la rune de son `setUp` (`:29-40`) et l'import de `forge_upgrade_data.dart`** avec les champs de forge (Task 3) : sans eux, rien ne la lit. La spec rangeait `:38` (son `pools`) parmi les runes construites qui perdent `pools` en partie 2 : elle n'y sera plus.
6. **Une aide de plus dans le modèle, `ForgeUpgradeData.nameAt(level, locale)`** (Task 3) : la règle des infobulles d'E1 (« le niveau s'écrit quand `maxLevel` n'est pas 1 ») a trois lecteurs en partie 1 — l'infobulle (`tooltipLine`), la ligne de rune, le dialogue de fusion (`deck_screen.dart:284`, §4.11). Un fait, un endroit.
7. **`ForgeSlotRow` reçoit des textes prêts**, plus la carte ni l'or : `rune`, `title`, `description`, `actionLabel`, `onAction` (Task 3), puis `detail` (Task 4, la ligne de niveau de l'affûtage). Chaque écran calcule ce qu'il montre — le niveau 1 à la fusion, le gain marginal à l'affûtage (§4.7). Les deux tables de couleurs et d'icônes restent privées jusqu'à A19 (partie 2).
8. **`ForgeCardPreview` perd la capacité, et seulement elle** (§4.5 : `:10`, `:37`, `:80-81`, `:100`) : l'étiquette « CAPACITÉ », les prises vides et le compte « n / max » partent ; la carte et une prise par rune restent.
9. **`ForgeUpgradeDialog(card, offer)` reçoit les ids** que `drawRunes` rend, et les lit par `ForgeUpgradeData.getById` — le registre dont l'offre est tirée.
10. **Les helpers de sélection du feu** : `RestCardSelectionScreen.isForge` devient `isSharpen` (le mode change de sens) ; le refus d'une carte sans rune affûtable lit `ForgeRuneRules.hasSharpenableRune`, que lisent aussi l'option inactive du feu — deux lecteurs d'un même prédicat. `ForgeRuneRules.replaceRune` réécrit une référence à sa place ; la partie 2 pourra le réutiliser pour le Puits (« remplace la référence donnée à sa place »).
11. **`forge_rune_rules_test.dart` : `_cardWith` gagne un lecteur** (le groupe de l'affûtage, Task 4). La spec (§8, ligne « Le tirage ») le disait seul lu par le groupe `fusionOptionsFor` et supprimé avec lui en partie 2 : la partie 2 le garde.
12. **Le tutoriel attend le choix** : `_isStepActionComplete` (`tutorial_screen.dart:72-74`) ne libère SUIVANT qu'une fois la rune choisie, ou quand aucune ne s'offre — l'étape enseigne un choix (A18), comme le dialogue du jeu ne se ferme que par lui (A1). Conséquence mesurée : au parcours de `tutorial_merge_transition_test.dart` (Paladin, cinq premières cartes du pool), la carte semée devient *Éveil* — dont la fusion offre *Endurci* — et non plus *Concentration*, dont la première fusion n'offre rien.
13. **La prose de l'étape de fusion vient avec le tutoriel (Task 5)**, celle du repos avec l'affûtage (Task 4) : chaque texte change dans la tâche qui change ce qu'il dit.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/forge_upgrade_data.dart` | `minFusionRank` (1) ; `nameAt` (3) | 1, 3 |
| `lib/game/services/forge_rune_rules.dart` | Conditions 7 et 8 du prédicat (1) ; `drawRunes` (3) ; `sharpenBaseCost`, `sharpenCost`, `canSharpen`, `hasSharpenableRune`, `replaceRune` (4) | 1, 3, 4 |
| `assets/data/forge_upgrades/*.json` (huit) | `minFusionRank` | 1 |
| `lib/services/content_editor/entity_descriptor.dart` | Gabarit de rune : `minFusionRank` (1) ; gabarit de carte sans `baseMaxForgeUpgrades` (2) | 1, 2 |
| `lib/game/controllers/shop_controller.dart` | Repli mort du tirage (1) ; borne des pré-forgées par `fusionRank` (2) | 1, 2 |
| `lib/models/data/card_data.dart`, `lib/models/card_instance.dart` | La capacité supprimée | 2 |
| `assets/data/classes/*/cards/*.json` (six) | Sans `baseMaxForgeUpgrades` | 2 |
| `lib/game/controllers/deck_controller.dart` | `mergeCards(ids)` sans troncature (2), qui rend la carte (3) | 2, 3 |
| `lib/ui/screens/deck_screen.dart` | Plus d'étape de capacité (2) ; l'offre, le `context` stable, les runes de l'étape 1 (3) | 2, 3 |
| `lib/ui/widgets/ui_card.dart`, `lib/ui/widgets/ui_card/card_rune_sockets.dart`, `lib/ui/widgets/ui_card/ui_card_helpers.dart` | Une prise par rune ; l'emoji par `parseRef` | 2 |
| `lib/game/components/widgets/card_text_renderer.dart` | Une prise par rune ; l'emoji par `parseRef` (Flame) | 2 |
| `lib/game/components/card_component.dart` | L'en-tête « === RUNES === » de l'infobulle Flame | 3 |
| `lib/ui/widgets/forge/forge_card_preview.dart` | Sans capacité | 2 |
| `lib/ui/widgets/forge_upgrade_dialog.dart` | Sans capacité (2) ; réduit au choix de la fusion (3) | 2, 3 |
| `lib/ui/widgets/forge/forge_slot_row.dart` | La ligne de rune (3) ; sa ligne de détail (4) | 3, 4 |
| `lib/ui/widgets/forge/forge_buy_slot_button.dart` | Supprimé | 3 |
| `lib/game/controllers/run_controller.dart` | Session et fentes supprimées (3) ; `sharpenRune` (4) | 3, 4 |
| `lib/game/controllers/run/gold_manager.dart` | Supprimé avec `buyBonusForgeSlot` (3) ; recréé pour `sharpenRune` (4) | 3, 4 |
| `lib/ui/widgets/debug/tabs/debug_run_tab.dart` | La ligne « Slots de forge bonus » | 3 |
| `lib/ui/widgets/forge/sharpen_rune_dialog.dart` *(nouveau)* | Le dialogue d'affûtage | 4 |
| `lib/ui/screens/rest_card_selection_screen.dart` | Sans le refus d'une carte pleine (2) ; la forge par le dialogue réduit (3) ; le mode affûtage (4) | 2, 3, 4 |
| `lib/ui/screens/rest_screen.dart` | `_leave` sans session (3) ; AFFÛTER, le retour système qui résout le nœud (4) | 3, 4 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_localizations*.dart` | Les chaînes de la fusion (3) et de l'affûtage (4) | 3, 4 |
| `lib/tutorial/tutorial_data.dart` | La prose du repos (4) et de l'étape de fusion (5) | 4, 5 |
| `lib/tutorial/widgets/tutorial_node_types_widget.dart` | Le repos | 4 |
| `lib/tutorial/tutorial_engine.dart`, `lib/tutorial/tutorial_screen.dart`, `lib/tutorial/widgets/tutorial_merge_widget.dart` | L'offre, le choix, le semis (A18) | 5 |
| `test/unit/forge_upgrades_catalog_test.dart` | Les huit runes et la matrice aux rangs 1 et 2 (réécrit) | 1 |
| `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_eligibility_test.dart` | `minFusionRank`, le prédicat (1) ; `nameAt` (3) | 1, 3 |
| `test/unit/forge_rune_rules_test.dart` | Le groupe `stackable` gagne la clé (1) ; `drawRunes` (3) ; l'affûtage (4) | 1, 3, 4 |
| `test/unit/content_editor/fixtures.dart`, `entity_validator_test.dart`, `entity_descriptor_test.dart` | L'éditeur | 1, 2 |
| `test/unit/card_rarity_test.dart`, `decoupled_forge_test.dart`, `deck_controller_test.dart`, `deck_state_persistence_test.dart` | La capacité supprimée, `mergeCards(ids)` | 2, 3 |
| `test/unit/shop_controller_test.dart` | La borne des pré-forgées par `fusionRank` | 2 |
| `test/widget/ui_card_rune_sockets_test.dart` | Les prises | 2 |
| `test/widget/deck_screen_test.dart` | La fusion à l'écran | 2, 3 |
| `test/widget/forge_upgrade_dialog_test.dart` | Le dialogue de fusion (réécrit en 3) | 1, 3 |
| `test/unit/run_controller_test.dart`, `test/unit/run_state_persistence_test.dart` | Session supprimée (3) ; `sharpenRune` (4) | 3, 4 |
| `test/widget/sharpen_rune_dialog_test.dart` *(nouveau)* | Le dialogue d'affûtage | 4 |
| `test/widget/rest_card_selection_screen_test.dart`, `test/widget/rest_screen_test.dart` | Le feu (réécrits en 4) | 1, 2, 4 |
| `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_merge_transition_test.dart`, `test/widget/tutorial_merge_widget_test.dart` *(nouveau)* | Le tutoriel | 5 |

---

### Task 1: Une rune par type, au rang de la carte qui la reçoit — `minFusionRank` et le prédicat

D48 et D3 entrent dans le prédicat (spec §4.3) : chaque rune déclare `minFusionRank`, obligatoire, entier d'au moins 1 (A8) ; `ForgeRuneRules.isEligible` le compare au rang de la carte qui reçoit la rune (condition 7) et refuse toute rune que la carte porte déjà, plafond atteint ou non (condition 8, dont la règle D75 d'E1 devient un cas). Les lecteurs d'aujourd'hui du prédicat — la forge du feu, sa sélection, les pré-forgées de la boutique — l'appliquent aussitôt ; la fusion le lira en Task 3. La condition de coût garde `card.currentCost`, égal au coût de la donnée tant qu'aucune sorte ne le change (A15, partie 2). La matrice du test de catalogue passe aux rangs 1 et 2 (§8, ligne « Les onze runes »).

Changements de jeu de la tâche, voulus : une commune ne reçoit plus aucune rune — la boutique ne lui en pré-forge aucune, la forge du feu la refuse avec son motif (`forgeNoEligibleRune`) jusqu'à ce que l'affûtage la remplace (Task 4) ; *Véloce* et *Économe* ne s'offrent qu'à une carte rare ou au-delà ; une carte ne reçoit jamais deux fois la même rune, ni en boutique ni au feu.

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart:17-19`, `:64-65`, `:88`, `:174` (avant `_readDeltas`), `:198`
- Modify: `lib/game/services/forge_rune_rules.dart:96-102`, `:118`, `:132-133`
- Modify: `lib/game/controllers/shop_controller.dart:126-137`
- Modify: les huit fichiers de `assets/data/forge_upgrades/` — une clé `minFusionRank` après `color`
- Modify: `lib/services/content_editor/entity_descriptor.dart:331-334`, `:368-371`, `:376`
- Test: `test/unit/forge_upgrade_data_test.dart:9-17`, après `:212` (groupe neuf)
- Test: `test/unit/forge_upgrades_catalog_test.dart` (réécrit en entier)
- Test: `test/unit/rune_eligibility_test.dart:14-17`, `:33-36`, `:38-57`, `:131-140`
- Test: `test/unit/forge_rune_rules_test.dart:60-63`, `:72-75`
- Test: `test/unit/content_editor/fixtures.dart:53` ; `test/unit/content_editor/entity_validator_test.dart:595`, après `:648` (cas neuf) ; `test/unit/content_editor/entity_descriptor_test.dart:264`
- Test: `test/widget/forge_upgrade_dialog_test.dart:84-85`, `:95-96`, `:107-109` ; `test/widget/rest_card_selection_screen_test.dart:70-71`, `:89-91`

**Interfaces:**
- Consumes: `CardRarity.fusionRank` (E1, `card_data.dart:36-42`) ; `ForgeUpgradeData.levelsOf` (E1).
- Produces:
  - `final int ForgeUpgradeData.minFusionRank` — obligatoire dans le fichier (`FormatException` si absente, non entière ou inférieure à 1), `1` par défaut au constructeur, écrite par `toJson`.
  - `ForgeRuneRules.isEligible(ForgeUpgradeData rune, CardInstance card, Iterable<ForgeUpgradeData> catalog)` — signature inchangée ; vrai seulement si, en plus des conditions d'E1, `rune.minFusionRank <= card.rarity.fusionRank` et la carte ne porte pas `rune.id`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'maxLevel': null,
```

with:

```dart
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'minFusionRank': 1,
      'maxLevel': null,
```

Then replace:

```dart
      final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));
      expect(ForgeUpgradeData.fromJson(capped.toJson()).maxLevel, 2);
    });
  });
```

with:

```dart
      final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));
      expect(ForgeUpgradeData.fromJson(capped.toJson()).maxLevel, 2);
    });
  });

  // Spec P-43 E2, A8 : la cle est obligatoire, un entier d'au moins 1.
  group('minFusionRank', () {
    test('lu dans le fichier ; 1 au constructeur', () {
      expect(
        ForgeUpgradeData.fromJson(_json({'minFusionRank': 2})).minFusionRank,
        2,
      );
      expect(
        const ForgeUpgradeData(
          id: 'x',
          nameEn: 'x',
          nameFr: 'x',
          descriptionEn: '',
          descriptionFr: '',
          icon: '',
          color: '',
          pools: ['common'],
        ).minFusionRank,
        1,
      );
    });

    test('refuse une rune sans minFusionRank', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('minFusionRank')),
          _refused('minFusionRank'));
    });

    test('refuse un minFusionRank nul, negatif, decimal ou null', () {
      for (final bad in [0, -1, 1.5, null]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'minFusionRank': bad})),
            _refused('minFusionRank'),
            reason: '$bad');
      }
    });

    test('toJson ecrit minFusionRank', () {
      final rune = ForgeUpgradeData.fromJson(_json({'minFusionRank': 2}));
      expect(rune.toJson(), containsPair('minFusionRank', 2));
      expect(ForgeUpgradeData.fromJson(rune.toJson()).minFusionRank, 2);
    });
  });
```

In `test/unit/rune_eligibility_test.dart`, replace:

```dart
  List<String> excludesRunes = const [],
  int? maxLevel,
  List<CardDelta> deltas = const [],
}) =>
```

with:

```dart
  List<String> excludesRunes = const [],
  int? maxLevel,
  int minFusionRank = 1,
  List<CardDelta> deltas = const [],
}) =>
```

Then replace:

```dart
      excludesRunes: excludesRunes,
      maxLevel: maxLevel,
      deltas: deltas,
    );
```

with:

```dart
      excludesRunes: excludesRunes,
      maxLevel: maxLevel,
      minFusionRank: minFusionRank,
      deltas: deltas,
    );
```

Then replace the whole `_card` helper (`:38-57`):

```dart
CardInstance _card({
  CardType type = CardType.attack,
  int cost = 1,
  bool isExhaust = false,
  List<CardEffect> effects = const [CardEffect(type: 'damage', value: 6)],
  List<String> runes = const [],
}) =>
    CardInstance(
      data: CardData(
        id: 'test_card',
        cost: cost,
        type: type,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        isExhaust: isExhaust,
        effects: effects,
      ),
      forgeUpgrades: runes,
    );
```

with:

```dart
/// Une carte de test, peu commune par défaut : le rang 1 qu'atteint une
/// première fusion, où toute rune de `minFusionRank` 1 peut s'offrir (spec
/// P-43 E2, §8).
CardInstance _card({
  CardType type = CardType.attack,
  CardRarity rarity = CardRarity.uncommon,
  int cost = 1,
  bool isExhaust = false,
  List<CardEffect> effects = const [CardEffect(type: 'damage', value: 6)],
  List<String> runes = const [],
}) =>
    CardInstance(
      data: CardData(
        id: 'test_card',
        cost: cost,
        type: type,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        isExhaust: isExhaust,
        effects: effects,
      ),
      rarity: rarity,
      forgeUpgrades: runes,
    );
```

Then replace the two cases `:131-140`:

```dart
  test('le plafond atteint par deux exemplaires additionnes', () {
    final rune = _rune('capped', maxLevel: 2);
    expect(_eligible(rune, _card(runes: const ['capped:1'])), isTrue);
    expect(_eligible(rune, _card(runes: const ['capped:1', 'capped:1'])),
        isFalse);
  });

  test('une rune sans plafond se repropose', () {
    expect(_eligible(_rune('sharp'), _card(runes: const ['sharp:5'])), isTrue);
  });
```

with:

```dart
  // D3 : une seule rune de chaque type par carte (spec P-43 E2, §4.3,
  // condition 8) ; le plafond atteint d'E1 (D75) en est un cas.
  test('une rune portee sous son plafond ne se repropose pas', () {
    final rune = _rune('capped', maxLevel: 2);
    expect(_eligible(rune, _card()), isTrue);
    expect(_eligible(rune, _card(runes: const ['capped:1'])), isFalse);
  });

  test('une rune sans plafond portee ne se repropose pas', () {
    expect(_eligible(_rune('sharp'), _card(runes: const ['sharp:5'])), isFalse);
  });

  // D48 : la condition 7, contre le rang de la carte qui recoit la rune.
  test('minFusionRank contre le rang de la carte qui recoit la rune', () {
    final rank1 = _rune('sharp');
    final rank2 = _rune('quick', minFusionRank: 2);
    expect(_eligible(rank1, _card(rarity: CardRarity.common)), isFalse);
    expect(_eligible(rank1, _card(rarity: CardRarity.unique)), isFalse);
    expect(_eligible(rank1, _card()), isTrue);
    expect(_eligible(rank2, _card()), isFalse);
    expect(_eligible(rank2, _card(rarity: CardRarity.rare)), isTrue);
  });
```

Replace the whole of `test/unit/forge_upgrades_catalog_test.dart` with:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _threePools = ['common', 'uncommon', 'rare'];
const _allTypes = ['attack', 'skill', 'power'];

/// Ce que déclare une rune, sous une forme comparable.
Map<String, Object?> _declared(ForgeUpgradeData rune) => {
      'pools': rune.pools,
      'minFusionRank': rune.minFusionRank,
      'eligibleCardTypes': rune.eligibleCardTypes,
      'eligibleEffects': rune.eligibleEffects,
      'excludesEffects': rune.excludesEffects,
      'requiresExhaust': rune.requiresExhaust,
      'requiresMinCost': rune.requiresMinCost,
      'excludesRunes': rune.excludesRunes,
      'stackable': rune.stackable,
      'maxLevel': rune.maxLevel,
      'deltas': [for (final delta in rune.deltas) delta.toJson()],
      'weight': rune.weight,
    };

Map<String, Object?> _rune({
  List<String> pools = _threePools,
  int minFusionRank = 1,
  List<String>? eligibleCardTypes,
  List<String>? eligibleEffects,
  List<String> excludesEffects = const [],
  bool requiresExhaust = false,
  int requiresMinCost = 0,
  List<String> excludesRunes = const [],
  bool stackable = true,
  required int? maxLevel,
  required List<Map<String, Object?>> deltas,
  required int weight,
}) =>
    {
      'pools': pools,
      'minFusionRank': minFusionRank,
      'eligibleCardTypes': eligibleCardTypes,
      'eligibleEffects': eligibleEffects,
      'excludesEffects': excludesEffects,
      'requiresExhaust': requiresExhaust,
      'requiresMinCost': requiresMinCost,
      'excludesRunes': excludesRunes,
      'stackable': stackable,
      'maxLevel': maxLevel,
      'deltas': deltas,
      'weight': weight,
    };

Map<String, Object?> _status(String statusId) => {
      'type': 'addEffect',
      'effect': 'apply_status',
      'valuePerLevel': 1,
      'statusId': statusId,
      'durationPerLevel': 1,
    };

/// Les huit runes, telles que les specs P-43 E1 (§3.2) et E2 (§3.2) les
/// fixent : `minFusionRank` 2 pour `quick` et `eco` (D48), 1 pour les six
/// autres (A7). Les `weight` et les `eligibleCardTypes` sont ceux que la
/// simulation lit : ils ne bougent pas (spec P-43 E2, §9).
final _expected = <String, Map<String, Object?>>{
  'sharp': _rune(
    eligibleEffects: const ['damage'],
    maxLevel: null,
    deltas: const [
      {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
    ],
    weight: 100,
  ),
  'hardened': _rune(
    eligibleEffects: const ['armor'],
    maxLevel: null,
    deltas: const [
      {'type': 'percentBonus', 'effect': 'armor', 'valuePercentPerLevel': 15},
    ],
    weight: 100,
  ),
  'quick': _rune(
    pools: const ['uncommon', 'rare'],
    minFusionRank: 2,
    eligibleCardTypes: _allTypes,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
    ],
    weight: 60,
  ),
  'eco': _rune(
    pools: const ['rare'],
    minFusionRank: 2,
    eligibleCardTypes: _allTypes,
    requiresMinCost: 1,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'gain_mana', 'valuePerLevel': 1},
    ],
    weight: 40,
  ),
  'burning': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: null,
    deltas: [_status('burn')],
    weight: 80,
  ),
  'freezing': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: 1,
    deltas: [_status('freeze')],
    weight: 80,
  ),
  'shocking': _rune(
    eligibleCardTypes: const ['attack'],
    maxLevel: null,
    deltas: [_status('shock')],
    weight: 80,
  ),
  'enduring': _rune(
    pools: const ['rare'],
    eligibleCardTypes: _allTypes,
    excludesEffects: const ['gain_mana', 'draw'],
    requiresExhaust: true,
    excludesRunes: const ['eco', 'quick'],
    stackable: false,
    maxLevel: 1,
    deltas: const [
      {'type': 'removeExhaust'},
    ],
    weight: 30,
  ),
};

/// Ce que la première fusion d'une attaque de dégâts lui offre (rang 1), puis
/// la deuxième (rang 2).
const _attackRank1 = {'sharp', 'burning', 'freezing', 'shocking'};
const _attackRank2 = {..._attackRank1, 'quick', 'eco'};

/// La matrice de l'offre aux 17 cartes neutres livrées, sans rune, au rang
/// qu'atteint leur première fusion (peu commune), puis leur deuxième (rare) :
/// la table de la spec P-43 E2, §4.12, sans les trois runes de la partie 2.
/// `pools` mis à part, que le tirage de la boutique applique encore.
const _offers = <String, (Set<String>, Set<String>)>{
  'strike_basic': (_attackRank1, _attackRank2),
  'heavy_strike': (_attackRank1, _attackRank2),
  'fireball': (_attackRank1, _attackRank2),
  'ice_bolt': (_attackRank1, _attackRank2),
  'poison_stab': (_attackRank1, _attackRank2),
  'quick_attack': (_attackRank1, _attackRank2),
  'sweep': (_attackRank1, _attackRank2),
  'thunder_clap': (_attackRank1, _attackRank2),
  'warcry': ({..._attackRank1, 'hardened'}, {..._attackRank2, 'hardened'}),
  'awakening': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'defend_basic': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'iron_wall': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'heal_potion': ({'enduring'}, {'enduring', 'quick', 'eco'}),
  'demon_form': (<String>{}, {'quick', 'eco'}),
  'metallicize': (<String>{}, {'quick', 'eco'}),
  'concentration': (<String>{}, {'quick'}),
  'focus': (<String>{}, {'quick'}),
};

/// Les six signatures, `unique` : rang 0, elles ne fusionnent jamais et
/// aucune rune ne s'offre à elles (spec P-43 E2, §4.12).
const _signatures = {
  'reckless_strike',
  'rage_form',
  'magic_missile',
  'mana_surge',
  'smite',
  'holy_shield',
};

/// Les huit runes livrées, et l'offre qu'elles font aux 23 cartes livrées
/// (spec P-43 E1, §3.2, §4.8 ; spec P-43 E2, §3.2, §4.12, §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  CardData cardOf(String id) => registry.cards.singleWhere((c) => c.id == id);

  Set<String> offeredTo(CardInstance card) => {
        for (final rune in registry.forgeUpgrades)
          if (ForgeRuneRules.isEligible(rune, card, registry.forgeUpgrades))
            rune.id,
      };

  // `maxLevel` et `minFusionRank` sont obligatoires au chargement : une rune
  // chargée porte les deux clés.
  for (final MapEntry(key: id, value: expected) in _expected.entries) {
    test('$id declare ce que la spec fixe', () {
      final rune = registry.forgeUpgrades.singleWhere((r) => r.id == id);
      expect(_declared(rune), expected);
    });
  }

  test('la matrice couvre les 23 cartes livrees', () {
    expect(registry.cards.map((c) => c.id).toSet(),
        {..._offers.keys, ..._signatures});
  });

  for (final MapEntry(key: cardId, value: (rank1, rank2)) in _offers.entries) {
    for (final (rarity, runes) in [
      (CardRarity.uncommon, rank1),
      (CardRarity.rare, rank2),
    ]) {
      test('$cardId ${rarity.name} recoit ${runes.length} rune(s)', () {
        expect(
          offeredTo(CardInstance(data: cardOf(cardId), rarity: rarity)),
          runes,
        );
      });
    }
  }

  for (final cardId in _signatures) {
    test('$cardId, unique, ne recoit aucune rune', () {
      final card = CardInstance(data: cardOf(cardId));
      expect(card.rarity, CardRarity.unique);
      expect(offeredTo(card), isEmpty);
    });
  }
}
```

In `test/unit/content_editor/entity_validator_test.dart`, replace:

```dart
            mechanics: '{"pools": ["common"], "color": "$color", '
```

with:

```dart
            mechanics: '{"pools": ["common"], "minFusionRank": 1, '
                '"color": "$color", '
```

Then replace:

```dart
    test('maxLevel 0 est refuse par la famille 7', () {
      final faults = withRunes().validate(runeDraft({'maxLevel': 0}));
      expect(faults.single.message, contains('maxLevel'));
    });
```

with:

```dart
    test('maxLevel 0 est refuse par la famille 7', () {
      final faults = withRunes().validate(runeDraft({'maxLevel': 0}));
      expect(faults.single.message, contains('maxLevel'));
    });

    test('minFusionRank 0 est refuse par la famille 7', () {
      final faults = withRunes().validate(runeDraft({'minFusionRank': 0}));
      expect(faults.single.message, contains('minFusionRank'));
    });
```

In `test/unit/content_editor/fixtures.dart`, replace:

```dart
      'pools': ['common'],
      'maxLevel': null,
```

with:

```dart
      'pools': ['common'],
      'minFusionRank': 1,
      'maxLevel': null,
```

In `test/unit/content_editor/entity_descriptor_test.dart`, in the expected keys of `EntityCategory.forgeUpgrade`, replace:

```dart
        'color',
        'pools',
        'eligibleCardTypes',
```

with:

```dart
        'color',
        'pools',
        'minFusionRank',
        'eligibleCardTypes',
```

In `test/unit/forge_rune_rules_test.dart`, the `stackable` group reads two runes by `fromJson`, which now demands the key (spec §8 : the group gains it in part 1 and disappears in part 2). Replace:

```dart
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
        'maxLevel': null,
```

with:

```dart
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
        'minFusionRank': 1,
        'maxLevel': null,
```

Then replace:

```dart
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'stackable': false,
```

with:

```dart
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'minFusionRank': 1,
        'stackable': false,
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/rune_eligibility_test.dart test/unit/forge_upgrades_catalog_test.dart`
Expected: FAIL à la compilation — `The getter 'minFusionRank' isn't defined for the type 'ForgeUpgradeData'` et `No named parameter with the name 'minFusionRank'`.

- [ ] **Step 3: Le modèle — `minFusionRank`**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
  final String color;
  final List<String> pools;
  final List<String>? eligibleCardTypes;
```

with:

```dart
  final String color;
  final List<String> pools;

  /// Le rang de fusion minimal de la carte qui reçoit la rune (D48 ; spec
  /// P-43 E2, A8, §4.3) : `eco` et `quick` attendent une carte rare. La clé
  /// est obligatoire dans le fichier, un entier d'au moins 1 — une commune ne
  /// porte jamais de rune ; le constructeur en laisse 1 aux tests.
  final int minFusionRank;
  final List<String>? eligibleCardTypes;
```

Then replace:

```dart
    required this.pools,
    this.eligibleCardTypes,
```

with:

```dart
    required this.pools,
    this.minFusionRank = 1,
    this.eligibleCardTypes,
```

Then replace:

```dart
      pools: List<String>.from(json['pools'] as List? ?? []),
```

with:

```dart
      pools: List<String>.from(json['pools'] as List? ?? []),
      minFusionRank: _readMinFusionRank(id, json['minFusionRank']),
```

Then replace:

```dart
  static List<CardDelta> _readDeltas(String id, Object? raw) {
```

with:

```dart
  /// La clé est obligatoire (spec P-43 E2, A8) : un entier d'au moins 1.
  /// Facultative, elle laisserait une rune neuve s'offrir dès la première
  /// fusion faute de l'avoir dit — le précédent de `maxLevel`.
  static int _readMinFusionRank(String id, Object? raw) {
    if (raw is! int || raw < 1) {
      throw FormatException(
        '$id : minFusionRank est obligatoire, un entier d\'au moins 1 — '
        'reçu : $raw',
      );
    }
    return raw;
  }

  static List<CardDelta> _readDeltas(String id, Object? raw) {
```

Then replace:

```dart
      'pools': pools,
```

with:

```dart
      'pools': pools,
      'minFusionRank': minFusionRank,
```

- [ ] **Step 4: Les huit fichiers déclarent leur `minFusionRank`**

Dans chaque fichier de `assets/data/forge_upgrades/`, la ligne `color` gagne une ligne après elle — 2 pour `eco` et `quick` (D48), 1 pour les six autres (A7). Aucun `weight` ni aucun `eligibleCardTypes` ne change (spec §9).

| Fichier | Remplacer | Par |
|:---|:---|:---|
| `burning.json` | `  "color": "orangeAccent",` | `  "color": "orangeAccent",`<br>`  "minFusionRank": 1,` |
| `eco.json` | `  "color": "cyanAccent",` | `  "color": "cyanAccent",`<br>`  "minFusionRank": 2,` |
| `enduring.json` | `  "color": "greenAccent",` | `  "color": "greenAccent",`<br>`  "minFusionRank": 1,` |
| `freezing.json` | `  "color": "lightBlueAccent",` | `  "color": "lightBlueAccent",`<br>`  "minFusionRank": 1,` |
| `hardened.json` | `  "color": "blueAccent",` | `  "color": "blueAccent",`<br>`  "minFusionRank": 1,` |
| `quick.json` | `  "color": "amber",` | `  "color": "amber",`<br>`  "minFusionRank": 2,` |
| `sharp.json` | `  "color": "redAccent",` | `  "color": "redAccent",`<br>`  "minFusionRank": 1,` |
| `shocking.json` | `  "color": "amberAccent",` | `  "color": "amberAccent",`<br>`  "minFusionRank": 1,` |

Par exemple, `assets/data/forge_upgrades/eco.json` commence ainsi après la retouche :

```json
{
  "id": "eco",
  "name_en": "Eco",
  "name_fr": "Économe",
  "description_en": "Gains +{tier} Mana on play",
  "description_fr": "Gagne +{tier} Mana à l'utilisation",
  "icon": "diamond_rounded",
  "color": "cyanAccent",
  "minFusionRank": 2,
  "pools": [
    "rare"
  ],
```

- [ ] **Step 5: Le prédicat — les conditions 7 et 8**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D44, D51, D61, D75 ; spec P-43 E1, A3, §4.6) : une
  /// fonction pure, sur le modèle de `CardData.isOfferableTo` — toute règle
  /// est un champ du fichier de rune, aucune n'est un `case` par id. [catalog]
  /// sert à lire les exclusions des runes que la carte porte déjà. `pools`
  /// n'en est pas une condition : c'est le ciblage par rareté des tirages,
  /// qui le gardent (D68).
```

with:

```dart
  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D3, D44, D48, D51, D61 ; spec P-43 E1, A3, §4.6 ; spec
  /// P-43 E2, §4.3) : une fonction pure, sur le modèle de
  /// `CardData.isOfferableTo` — toute règle est un champ du fichier de rune,
  /// aucune n'est un `case` par id. [card] est la carte qui reçoit la rune, à
  /// son rang : la carte fusionnée au rang qu'elle atteint, la carte
  /// elle-même en boutique. [catalog] sert à lire les exclusions des runes
  /// que la carte porte déjà. `pools` n'en est pas une condition : c'est le
  /// ciblage par rareté des tirages, qui le gardent (D68).
```

Then replace:

```dart
    if (card.currentCost < rune.requiresMinCost) return false;
```

with:

```dart
    if (card.currentCost < rune.requiresMinCost) return false;

    // D48 : le rang de la carte qui reçoit la rune ; une commune et une
    // carte `unique`, de rang 0, n'en reçoivent aucune.
    if (rune.minFusionRank > card.rarity.fusionRank) return false;
```

Then replace:

```dart
    // D75 : une rune dont la carte a atteint le plafond ne se repropose pas.
    return rune.boundLevel(1, carried: carried[rune.id] ?? 0) >= 1;
```

with:

```dart
    // D3 : une seule rune de chaque type par carte — une rune portée ne se
    // repropose jamais, plafond atteint ou non (D75 en est un cas).
    return !carried.containsKey(rune.id);
```

- [ ] **Step 6: Le tirage des pré-forgées perd son repli devenu mort**

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
  /// Tire une rune pour [card], qui porte déjà les runes tirées avant elle :
  /// le prédicat les lit (spec P-43 E1, A12). `null` s'il ne lui reste aucune
  /// rune éligible : la carte en reçoit une de moins.
  String? _rollRandomUpgrade(CardInstance card, Random rng) {
    final excludedIds =
        card.forgeUpgrades.map((u) => u.split(':')[0]).toList();
    // Le repli sans exclusion ne repropose qu'une rune encore éligible, donc
    // sans plafond atteint : deux `sharp` restent possibles, « une rune par
    // type » est E2.
    final rolledId = _rollUpgradeId(card, rng, excludedIds) ??
        _rollUpgradeId(card, rng, []);
    if (rolledId == null) return null;
```

with:

```dart
  /// Tire une rune pour [card], qui porte déjà les runes tirées avant elle :
  /// le prédicat les lit (spec P-43 E1, A12) et n'en repropose aucune (D3).
  /// `null` s'il ne lui reste aucune rune éligible : la carte en reçoit une
  /// de moins.
  String? _rollRandomUpgrade(CardInstance card, Random rng) {
    final excludedIds =
        card.forgeUpgrades.map((u) => u.split(':')[0]).toList();
    final rolledId = _rollUpgradeId(card, rng, excludedIds);
    if (rolledId == null) return null;
```

- [ ] **Step 7: Le gabarit de rune de l'éditeur**

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // `pools` est la seule cle que la famille 3 exige : les autres cles
    // obligatoires d'une rune — `deltas`, et ce que la spec P-43 E1 y ajoute
    // (§3.1) — sont refusees par `ForgeUpgradeData.fromJson` lui-meme, que la
    // famille 7 appelle. Un fait a un seul endroit.
```

with:

```dart
    // `pools` est la seule cle que la famille 3 exige : les autres cles
    // obligatoires d'une rune — `deltas`, `maxLevel` (spec P-43 E1, §3.1) et
    // `minFusionRank` (spec P-43 E2, A8) — sont refusees par
    // `ForgeUpgradeData.fromJson` lui-meme, que la famille 7 appelle. Un fait
    // a un seul endroit.
```

Then replace:

```dart
    // `maxLevel` y vaut 1, une valeur prudente : un plafond oublie ne laisse
    // pas monter une rune sans fin (spec P-43 E1, §6). `eligibleEffects` y
    // porte l'exemple du delta, `damage` ; `excludesRunes` n'y figure pas :
    // absente, elle vaut « aucune », comme `classes` d'un passif.
```

with:

```dart
    // `maxLevel` y vaut 1, une valeur prudente : un plafond oublie ne laisse
    // pas monter une rune sans fin (spec P-43 E1, §6). `minFusionRank` y vaut
    // 1 : la rune s'offre des la premiere fusion ; `eco` et `quick` en
    // demandent 2 (spec P-43 E2, D48). `eligibleEffects` y porte l'exemple du
    // delta, `damage` ; `excludesRunes` n'y figure pas : absente, elle vaut
    // « aucune », comme `classes` d'un passif.
```

Then replace:

```dart
  "pools": ["common"],
  "eligibleCardTypes": ["attack", "skill", "power", "status"],
```

with:

```dart
  "pools": ["common"],
  "minFusionRank": 1,
  "eligibleCardTypes": ["attack", "skill", "power", "status"],
```

- [ ] **Step 8: Les tests de la forge du feu, sur une carte qui peut recevoir une rune**

La forge du feu vit jusqu'à Task 3 (son dialogue) et Task 4 (sa sélection) : ses tests passent sur une carte du rang qu'atteint une fusion, une commune ne recevant plus rien. Ces fichiers sont réécrits en Task 3 et Task 4.

In `test/widget/forge_upgrade_dialog_test.dart`, replace:

```dart
    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('strike_basic')));

    expect(_ids(offered), {'sharp'});
```

with:

```dart
    // Peu commune : une commune ne recoit plus de rune (spec P-43 E2, §4.3).
    final offered = await _offeredSlots(
        tester,
        CardInstance(
            data: shippedCard('strike_basic'), rarity: CardRarity.uncommon));

    expect(_ids(offered), {'sharp'});
```

Then replace:

```dart
    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('concentration')));
```

with:

```dart
    // Rare : Veloce attend le rang 2 (D48).
    final offered = await _offeredSlots(
        tester,
        CardInstance(
            data: shippedCard('concentration'), rarity: CardRarity.rare));
```

Then replace:

```dart
    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('strike_basic')),
        rerolls: 30);
```

with:

```dart
    // Rare : Econome attend le rang 2 (D48).
    final offered = await _offeredSlots(
        tester,
        CardInstance(data: shippedCard('strike_basic'), rarity: CardRarity.rare),
        rerolls: 30);
```

In `test/widget/rest_card_selection_screen_test.dart`, replace:

```dart
    // Sa fente libre ne peut rien recevoir : Veloce est sa seule rune
    // eligible, et son plafond est atteint.
```

with:

```dart
    // Rien ne s'offre a une peu commune qui pioche et ne coute rien : Veloce
    // attend le rang 2 (D48), et la carte la porte deja (D3).
```

Then replace:

```dart
  testWidgets('une Frappe commune sans rune ouvre le dialogue de forge',
      (tester) async {
    final card = CardInstance(data: shippedCard('strike_basic'));
```

with:

```dart
  testWidgets('une Frappe peu commune sans rune ouvre le dialogue de forge',
      (tester) async {
    final card = CardInstance(
        data: shippedCard('strike_basic'), rarity: CardRarity.uncommon);
```

- [ ] **Step 9: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart` — Expected: `+34: All tests passed!`
Run: `flutter test test/unit/rune_eligibility_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/unit/forge_upgrades_catalog_test.dart` — Expected: `+49: All tests passed!`
Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/shop_controller_test.dart test/unit/real_bundle_load_test.dart test/unit/content_editor/ test/widget/forge_upgrade_dialog_test.dart test/widget/rest_card_selection_screen_test.dart` — Expected: `All tests passed!`

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1398: All tests passed!` (1375 + 23 : la matrice +17 — 40 cas pour 23 —, le prédicat +1, le modèle +4, l'éditeur +1).

- [ ] **Step 11: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/forge_upgrade_data.dart lib/game/services/forge_rune_rules.dart lib/game/controllers/shop_controller.dart lib/services/content_editor/entity_descriptor.dart assets/data/forge_upgrades test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/rune_eligibility_test.dart test/unit/forge_rune_rules_test.dart test/unit/content_editor/fixtures.dart test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/entity_descriptor_test.dart test/widget/forge_upgrade_dialog_test.dart test/widget/rest_card_selection_screen_test.dart
git commit -F- <<'EOF'
feat(runes): une rune par type, au rang de la carte qui la recoit

Chaque rune declare minFusionRank, obligatoire : Veloce et Econome
attendent une carte rare. Le predicat compare ce rang a celui de la
carte qui recoit la rune et ne repropose jamais une rune portee. Une
commune ne recoit plus de rune ; la matrice du catalogue passe aux rangs
1 et 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: La capacité disparaît, la fusion garde toutes les runes

D28 (la capacité) et D13 (l'héritage) : `CardData.baseMaxForgeUpgrades`, `CardData.forgeCapacityAt` et `CardInstance.forgeCapacity` sont supprimés avec leurs sept lecteurs (spec §4.10) et la donnée qui les nourrissait — le gabarit de carte de l'éditeur, les six signatures. `DeckNotifier.mergeCards(ids)` calcule l'héritage lui-même, par `ForgeRuneRules.consolidate`, et ne le tronque plus (§4.6) : l'étape « Capacité de Forge Dépassée » de l'écran de deck disparaît, avec son lecteur de `stackable` (`deck_screen.dart:362`). Une carte montre une prise par rune portée, aucune vide, et l'emoji d'une prise passe par l'analyseur unique `parseRef` (E-S6). La borne des pré-forgées passe à `finalRarity.fusionRank` (D28, A20).

Changements de jeu de la tâche, voulus : plus de prises vides — une carte de classe sans rune n'en montre aucune ; une fusion garde toutes les runes de ses trois exemplaires, sans étape de choix ; une pré-forgée de la boutique porte au plus autant de runes que sa rareté a demandé de fusions ; la forge du feu ne refuse plus une carte « pleine ».

**Files:**
- Modify: `lib/models/data/card_data.dart:32-35`, `:133`, `:152`, `:176-178`, `:222`, `:242`
- Modify: `lib/models/card_instance.dart:24-25`
- Modify: `lib/game/controllers/deck_controller.dart:287-334`
- Modify: `lib/ui/screens/deck_screen.dart:7`, `:196-415`
- Modify: `lib/ui/widgets/forge_upgrade_dialog.dart:46`, `:51`, `:390`, `:395`
- Modify (réécrit en entier): `lib/ui/widgets/forge/forge_card_preview.dart`
- Modify: `lib/ui/widgets/ui_card.dart:28`, `:47`, `:76`, `:107`, `:244-247`
- Modify (réécrit en entier): `lib/ui/widgets/ui_card/card_rune_sockets.dart`
- Modify: `lib/ui/widgets/ui_card/ui_card_helpers.dart:217-221`
- Modify: `lib/game/components/widgets/card_text_renderer.dart:1`, `:361-425`, `:551-555`
- Modify: `lib/ui/screens/rest_card_selection_screen.dart:28-40`
- Modify: `lib/game/controllers/shop_controller.dart:198`
- Modify: `lib/services/content_editor/entity_descriptor.dart:236-239`
- Modify: les six fichiers `assets/data/classes/*/cards/*.json` — leur dernière clé
- Test: `test/unit/card_rarity_test.dart:1-18`, `:48-66`
- Test: `test/unit/decoupled_forge_test.dart:90-109`, `:278-281`, `:294-297`, `:324-327`
- Test: `test/unit/deck_controller_test.dart:7-9` (un import), `:11-23` (aide neuve après), `:85-183`, `:192`, `:210`, `:219`
- Test: `test/unit/shop_controller_test.dart` (un cas neuf, après `:458`)
- Test: `test/unit/deck_state_persistence_test.dart:33`
- Test: `test/widget/ui_card_rune_sockets_test.dart:53-86`, après `:128` (cas neuf)
- Test: `test/widget/rest_card_selection_screen_test.dart:103-118`
- Test: `test/widget/deck_screen_test.dart` (un cas neuf, en fin de fichier)
- Test: `test/unit/content_editor/entity_descriptor_test.dart:239`

**Interfaces:**
- Consumes: `ForgeRuneRules.consolidate` (E1) ; le prédicat de Task 1, lu par la boutique.
- Produces:
  - `void DeckNotifier.mergeCards(List<String> selectedIds)` — l'héritage calculé dedans, sans troncature ; Task 3 lui fait rendre la carte.
  - `CardRuneSockets({Key? key, required List<String> forgeUpgrades})` — une prise par référence.
  - `ForgeCardPreview({Key? key, required CardInstance card, required String locale, required AppLocalizations l10n})`.
  - `CardData` sans `baseMaxForgeUpgrades` ni `forgeCapacityAt` ; `CardInstance` sans `forgeCapacity` ; `UiCard` sans `forgeCapacity`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/deck_controller_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

import 'shipped_data.dart';
```

Then replace:

```dart
CardInstance _card(String id) => CardInstance(
      data: CardData(
        id: id,
        nameEn: id,
        nameFr: id,
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: const [],
      ),
    );
```

with:

```dart
CardInstance _card(String id) => CardInstance(
      data: CardData(
        id: id,
        nameEn: id,
        nameFr: id,
        cost: 1,
        type: CardType.skill,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.self,
        effects: const [],
      ),
    );

/// Un exemplaire commun d'une même carte, portant [runes].
CardInstance _strikeWith(List<String> runes) =>
    CardInstance(data: _card('strike').data, forgeUpgrades: runes);
```

Then replace the two cases `:85-183` — from `    test('mergeCards successfully upgrades rarity and merges forge upgrades', () {` to the end of `    test('mergeCards limits upgrades to the capacity of the next rarity level', () {` (its closing `    });`) — with:

```dart
    test('mergeCards monte la rarete et reunit les runes des trois exemplaires',
        () {
      final baseCardData = const CardData(
        id: 'strike',
        nameEn: 'Strike',
        nameFr: 'Frappe',
        descriptionEn: 'd',
        descriptionFr: 'd',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );

      final card1 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['sharp:1', 'hardened:1'],
      );
      final card2 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: ['sharp:1'],
      );
      final card3 = CardInstance(
        data: baseCardData,
        rarity: CardRarity.common,
        forgeUpgrades: [],
      );

      notifier.initializeStarterDeck([card1, card2, card3]);

      notifier.mergeCards([card1.uniqueId, card2.uniqueId, card3.uniqueId]);

      expect(notifier.state.masterDeck.length, 1);
      final mergedCard = notifier.state.masterDeck.first;
      expect(mergedCard.rarity, CardRarity.uncommon);
      expect(mergedCard.forgeUpgrades, ['sharp:2', 'hardened:1']);
    });

    // D13 : aucun plafond de runes par carte (spec P-43 E2, §4.6).
    test('mergeCards garde toutes les runes des trois exemplaires', () {
      final trio = [
        _strikeWith(const ['sharp:1', 'hardened:1']),
        _strikeWith(const ['burning:1']),
        _strikeWith(const ['shocking:1']),
      ];
      notifier.initializeStarterDeck(trio);

      notifier.mergeCards(trio.map((c) => c.uniqueId).toList());

      expect(
        notifier.state.masterDeck.single.forgeUpgrades,
        ['sharp:1', 'hardened:1', 'burning:1', 'shocking:1'],
      );
    });

    test('mergeCards additionne les niveaux d une meme rune : sharp:3, sharp:1 '
        'et burning:1 donnent sharp:4 et burning:1', () {
      final trio = [
        _strikeWith(const ['sharp:3']),
        _strikeWith(const ['sharp:1']),
        _strikeWith(const ['burning:1']),
      ];
      notifier.initializeStarterDeck(trio);

      notifier.mergeCards(trio.map((c) => c.uniqueId).toList());

      expect(notifier.state.masterDeck.single.forgeUpgrades,
          ['sharp:4', 'burning:1']);
    });

    // E-S3 : l'heritage suit la regle d'exclusion de `consolidate` (spec P-43
    // E2, §1.1, §4.6).
    test('mergeCards ecarte une rune exclue par une rune gardee avant elle',
        () {
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
      // Le catalogue livre : Persistant exclut Econome dans son fichier.
      shippedRuneRegistry(shippedRuneIds());
      final potions = [
        for (final runes in const [
          ['enduring:1'],
          ['eco:1'],
          <String>[],
        ])
          CardInstance(data: shippedCard('heal_potion'), forgeUpgrades: runes),
      ];
      notifier.initializeStarterDeck(potions);

      notifier.mergeCards(potions.map((c) => c.uniqueId).toList());

      expect(notifier.state.masterDeck.single.forgeUpgrades, ['enduring:1']);
    });
```

Then replace:

```dart
      notifier.mergeCards(copies.map((c) => c.uniqueId).toList(), const []);
```

with:

```dart
      notifier.mergeCards(copies.map((c) => c.uniqueId).toList());
```

Then replace both occurrences (Edit with `replace_all`) of:

```dart
      notifier.mergeCards(trio.map((c) => c.uniqueId).toList(), const []);
```

with:

```dart
      notifier.mergeCards(trio.map((c) => c.uniqueId).toList());
```

In `test/unit/decoupled_forge_test.dart`, delete the whole case `:90-109`, from `    test('Capacity limit calculation works as expected based on rarity', () {` to its closing `    });` and the blank line that follows it. Then replace:

```dart
      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        const ['eco:1', 'eco:1', 'eco:1'],
      );
```

with:

```dart
      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());
```

Then replace:

```dart
      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        const ['sharp:1', 'sharp:1', 'sharp:1'],
      );
```

with:

```dart
      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());
```

Then replace:

```dart
      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        ['enduring:1', 'enduring:1', 'enduring:1'],
      );
```

with:

```dart
      deckNotifier.mergeCards(copies.map((c) => c.uniqueId).toList());
```

In `test/unit/card_rarity_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

CardData _cardData({
  CardRarity rarity = CardRarity.common,
  int baseMaxForgeUpgrades = 1,
}) =>
    CardData(
      id: 'test_card',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.singleEnemy,
      effects: const [],
      baseMaxForgeUpgrades: baseMaxForgeUpgrades,
    );

```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

```

Then delete the whole group `:48-66` — from `  group('Capacite de forge', () {` to its closing `  });` and the blank line that follows it. Seul ce groupe lisait `_cardData` et `CardInstance` (plan, « Ce que le plan précise », point 4).

In `test/unit/deck_state_persistence_test.dart`, replace:

```dart
      effects: [],
      baseMaxForgeUpgrades: 5,
    );
```

with:

```dart
      effects: [],
    );
```

In `test/widget/ui_card_rune_sockets_test.dart`, replace `:53-86` — from `CardData _cardData(CardRarity rarity, int baseMaxForgeUpgrades) => CardData(` to the end of the case `'une carte globale legendaire affiche 5 emplacements'` (its closing `  });`) — with:

```dart
CardData _cardData(CardRarity rarity) => CardData(
      id: 'holy_shield',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacre',
      descriptionEn: 'Gain armor',
      descriptionFr: 'Gagne de l armure',
      cost: 1,
      type: CardType.skill,
      category: CardCategory.global,
      rarity: rarity,
      target: CardTarget.self,
      effects: const [],
    );

/// Une prise par rune portée, aucune vide (spec P-43 E2, §4.10).
void main() {
  testWidgets('une carte de classe sans rune n affiche aucun emplacement', (
    WidgetTester tester,
  ) async {
    await _pumpCard(tester, CardInstance(data: _cardData(CardRarity.unique)));

    expect(_socketCount(tester), 0);
  });

  testWidgets('une carte legendaire a deux runes affiche deux emplacements, '
      'aucun vide', (
    WidgetTester tester,
  ) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: _cardData(CardRarity.common),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2', 'burning:1'],
      ),
    );

    expect(_socketCount(tester), 2);
  });
```

Then, in the same file, replace the case `'l emoji d une prise vient de la donnee de la rune'` (which reads `_cardData(CardRarity.common, 1)`) line:

```dart
        data: _cardData(CardRarity.common, 1),
        forgeUpgrades: const ['test_rune:1'],
```

with:

```dart
        data: _cardData(CardRarity.common),
        forgeUpgrades: const ['test_rune:1'],
```

Then replace the end of the file:

```dart
    expect(
      find.descendant(
        of: find.byType(CardRuneSockets),
        matching: find.text('🧪'),
      ),
      findsOneWidget,
    );
  });
}
```

with:

```dart
    expect(
      find.descendant(
        of: find.byType(CardRuneSockets),
        matching: find.text('🧪'),
      ),
      findsOneWidget,
    );
  });

  // Review Focus 3 : une reference mal formee ne nomme aucune rune — l'emoji
  // passe par l'analyseur unique (spec P-43 E2, §1.3, E-S6).
  testWidgets('une reference mal formee prend l emoji par defaut', (
    WidgetTester tester,
  ) async {
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: const [
        ForgeUpgradeData(
          id: 'test_rune',
          nameEn: 'Test',
          nameFr: 'Test',
          descriptionEn: '',
          descriptionFr: '',
          icon: '',
          color: '',
          pools: ['common'],
          emoji: '🧪',
        ),
      ],
    );

    await _pumpCard(
      tester,
      CardInstance(
        data: _cardData(CardRarity.common),
        forgeUpgrades: const ['test_rune'],
      ),
    );

    Finder inSockets(String emoji) => find.descendant(
          of: find.byType(CardRuneSockets),
          matching: find.text(emoji),
        );
    expect(inSockets('🔮'), findsOneWidget);
    expect(inSockets('🧪'), findsNothing);
  });
}
```

In `test/widget/rest_card_selection_screen_test.dart`, delete the whole case `:103-118`, from `  testWidgets('une carte pleine garde son message', (tester) async {` to its closing `  });` and the blank line before it — la carte pleine n'existe plus.

In `test/unit/content_editor/entity_descriptor_test.dart`, in the expected keys of `EntityCategory.card`, replace:

```dart
        'effects',
        'baseMaxForgeUpgrades',
      },
```

with:

```dart
        'effects',
      },
```

In `test/widget/deck_screen_test.dart`, replace the end of the file:

```dart
      await tester.pumpWidget(buildApp(container, allowMerge: false));
      await tester.pumpAndSettle();
      expect(find.text('Fusion possible'), findsNothing);
    },
  );
}
```

with:

```dart
      await tester.pumpWidget(buildApp(container, allowMerge: false));
      await tester.pumpAndSettle();
      expect(find.text('Fusion possible'), findsNothing);
    },
  );

  // Spec P-43 E2, §4.5, §4.6 : plus d'etape de capacite, l'heritage entier.
  testWidgets(
    'trois Frappes runees differemment fusionnent sans etape de capacite, '
    'toutes leurs runes gardees',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final deckNotifier = container.read(deckProvider.notifier);
      for (final rune in const ['sharp:1', 'burning:1', 'shocking:1']) {
        deckNotifier.addCardToMasterDeck(
          CardInstance(data: strikeCard, forgeUpgrades: [rune]),
        );
      }

      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FUSIONNER (3)'));
      await tester.pumpAndSettle();

      expect(find.text('Capacité de Forge Dépassée'), findsNothing);
      final merged = container.read(deckProvider).masterDeck.single;
      expect(merged.rarity, CardRarity.uncommon);
      expect(merged.forgeUpgrades, ['sharp:1', 'burning:1', 'shocking:1']);

      // Les notifications expirent avant le demontage de l'arbre.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
```

In `test/unit/shop_controller_test.dart`, replace the end of the case `'une Concentration pre-forgee porte au plus une rune, Veloce'`:

```dart
      expect(carried, {'quick:1'});
    });
```

with:

```dart
      expect(carried, {'quick:1'});
    });

    // D28, D3, D48 : une pre-forgee porte au plus `fusionRank` runes,
    // distinctes, eligibles au rang de sa rarete (spec P-43 E2, §4.9, §8).
    test('une pre-forgee porte au plus fusionRank runes, distinctes, et jamais '
        'Econome ni Veloce sous la rare', () {
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
      shippedRuneRegistry(shippedRuneIds());
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      var runed = 0;
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          final ids = [
            for (final ref in card.forgeUpgrades)
              ForgeUpgradeData.parseRef(ref)!.$1,
          ];
          final reason = '${card.data.id} ${card.rarity.name} : '
              '${card.forgeUpgrades}';
          // Une commune, de rang 0, n'en porte aucune.
          expect(ids.length, lessThanOrEqualTo(card.rarity.fusionRank),
              reason: reason);
          expect(ids.toSet(), hasLength(ids.length), reason: reason);
          if (card.rarity.fusionRank < 2) {
            expect(ids, isNot(contains('eco')), reason: reason);
            expect(ids, isNot(contains('quick')), reason: reason);
          }
          if (ids.isNotEmpty) runed++;
        }
      }
      // Garde contre un test qui passerait a vide.
      expect(runed, greaterThan(0));
    });
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/deck_controller_test.dart test/unit/decoupled_forge_test.dart test/widget/ui_card_rune_sockets_test.dart test/widget/deck_screen_test.dart test/unit/shop_controller_test.dart`
Expected: FAIL — `deck_controller_test.dart` et `decoupled_forge_test.dart` ne compilent pas (`Too few positional arguments: 2 required, 1 given` sur `mergeCards`) ; les prises comptent encore cinq emplacements et le cas mal formé trouve `🧪` ; l'écran de deck ouvre l'étape « Capacité de Forge Dépassée » ; la boutique pré-forge encore deux runes sur une peu commune (la capacité, `1 + fusionRank`, le lui permet).

- [ ] **Step 3: Le modèle perd la capacité**

In `lib/models/data/card_data.dart`, replace:

```dart
  /// Le nombre de fusions qu'il a fallu pour atteindre cette rareté : 0 à 4
  /// de `common` à `legendary`, 0 pour `unique`, qui ne fusionne jamais
  /// (ADR-026). La capacité de forge le lit (`forgeCapacityAt`) en attendant
  /// E2, et G1 compte ses paliers (`scaleValue`).
```

with:

```dart
  /// Le nombre de fusions qu'il a fallu pour atteindre cette rareté : 0 à 4
  /// de `common` à `legendary`, 0 pour `unique`, qui ne fusionne jamais
  /// (ADR-026). `minFusionRank` le compare (`ForgeRuneRules.isEligible`), G1
  /// compte ses paliers (`scaleValue`), il borne les runes d'une pré-forgée
  /// (`ShopController`).
```

Then replace:

```dart
  final List<CardEffect> effects;
  final int baseMaxForgeUpgrades;
```

with:

```dart
  final List<CardEffect> effects;
```

Then replace:

```dart
    required this.effects,
    this.baseMaxForgeUpgrades = 1,
  });
```

with:

```dart
    required this.effects,
  });
```

Then delete:

```dart
  /// Nombre de runes de forge qu'une carte de ce modèle porte à [rarity].
  int forgeCapacityAt(CardRarity rarity) =>
      baseMaxForgeUpgrades + rarity.fusionRank;

```

Then replace:

```dart
          [],
      baseMaxForgeUpgrades: json['baseMaxForgeUpgrades'] as int? ?? 1,
    );
```

with:

```dart
          [],
    );
```

Then replace:

```dart
        'effects': effects.map((e) => e.toJson()).toList(),
        'baseMaxForgeUpgrades': baseMaxForgeUpgrades,
      };
```

with:

```dart
        'effects': effects.map((e) => e.toJson()).toList(),
      };
```

In `lib/models/card_instance.dart`, replace:

```dart
  int get currentCost => data.cost;

  /// Nombre de runes de forge que cette carte peut porter.
  int get forgeCapacity => data.forgeCapacityAt(rarity);

```

with:

```dart
  int get currentCost => data.cost;

```

- [ ] **Step 4: La fusion garde tout l'héritage**

In `lib/game/controllers/deck_controller.dart`, replace the whole method `:287-334` — from `  /// Fusionne 3 cartes identiques en une carte de rareté supérieure` to its closing `  }` — with:

```dart
  /// Fusionne trois exemplaires d'une même carte, à une même rareté, en une
  /// carte de la rareté suivante, qui garde toutes leurs runes (D13 ; spec
  /// P-43 E2, §4.6) : `ForgeRuneRules.consolidate` additionne les niveaux
  /// d'une même rune, bornés par son plafond, et écarte une rune exclue par
  /// une rune gardée avant elle ; aucun plafond de runes par carte.
  void mergeCards(List<String> selectedIds) {
    if (selectedIds.length != 3) return;
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);

    final List<CardInstance> selectedCards = [];
    for (var id in selectedIds) {
      final cardIdx = currentMasterDeck.indexWhere((c) => c.uniqueId == id);
      if (cardIdx != -1) {
        selectedCards.add(currentMasterDeck[cardIdx]);
      }
    }

    if (selectedCards.length == 3) {
      // Trois exemplaires d'une même carte à une même rareté, qui en a une
      // au-delà : ni une carte `unique` ni une légendaire n'en ont.
      final first = selectedCards[0];
      final nextRarity = first.rarity.next;
      if (nextRarity == null ||
          selectedCards.any((c) => c.data.id != first.data.id || c.rarity != first.rarity)) {
        return;
      }

      // Retire les 3 exemplaires, puis ajoute la carte de rareté supérieure
      currentMasterDeck.removeWhere((c) => selectedIds.contains(c.uniqueId));
      currentMasterDeck.add(
        CardInstance(
          data: first.data,
          rarity: nextRarity,
          forgeUpgrades: ForgeRuneRules.consolidate(
            selectedCards.expand((card) => card.forgeUpgrades),
          ),
        ),
      );

      state = state.copyWith(masterDeck: currentMasterDeck);
    }
  }
```

- [ ] **Step 5: L'écran de deck perd l'étape de capacité**

In `lib/ui/screens/deck_screen.dart`, delete the import that only `_proceedToUpgrades` read:

```dart
import '../../game/services/forge_rune_rules.dart';
```

Then replace the whole class `_MergeDialogState` (`:196-415`, to the end of the file) with:

```dart
class _MergeDialogState extends State<_MergeDialog> {
  final Set<String> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.duplicates.length == 3) {
      _selectedCardIds.addAll(widget.duplicates.map((c) => c.uniqueId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performMerge();
      });
    }
  }

  /// La fusion des trois exemplaires choisis : `mergeCards` en garde toutes
  /// les runes (spec P-43 E2, §4.6) — plus de capacité, plus d'étape de choix
  /// de l'héritage.
  void _performMerge() {
    widget.ref.read(deckProvider.notifier).mergeCards(
          widget.duplicates
              .where((c) => _selectedCardIds.contains(c.uniqueId))
              .map((c) => c.uniqueId)
              .toList(),
        );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GameDialog(
      glowColor: Colors.green,
      title: Text(
        l10n.confirmMerge,
      ),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez exactement 3 cartes à fusionner (Sélectionné: ${_selectedCardIds.length}/3)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.duplicates.length,
                itemBuilder: (context, index) {
                  final card = widget.duplicates[index];
                  final isSelected = _selectedCardIds.contains(card.uniqueId);
                  final upgradesText = card.forgeUpgrades.isEmpty
                      ? (locale == 'fr' ? '(Sans amélioration)' : '(No upgrade)')
                      : card.forgeUpgrades.map((u) {
                          final parts = u.split(':');
                          final id = parts[0];
                          final tier = parts.length > 1 ? parts[1] : '1';
                          final upgradeData = ForgeUpgradeData.getById(id);
                          return upgradeData != null
                              ? (upgradeData.stackable ? '${upgradeData.getName(locale)} $tier' : upgradeData.getName(locale))
                              : '$id $tier';
                        }).join(', ');
                  return CheckboxListTile(
                    title: Text(
                      '${card.data.getName(locale)} (${card.rarity.name.toUpperCase()})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Forge: $upgradesText',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    value: isSelected,
                    activeColor: Colors.green,
                    checkColor: Colors.black,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (_selectedCardIds.length < 3) {
                            _selectedCardIds.add(card.uniqueId);
                          }
                        } else {
                          _selectedCardIds.remove(card.uniqueId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        GameButton(
          text: l10n.cancel,
          baseColor: Colors.white70,
          onPressed: () => Navigator.of(context).pop(),
          height: 38,
          fontSize: 14,
        ),
        GameButton(
          text: 'Continuer',
          onPressed: _selectedCardIds.length == 3 ? _performMerge : null,
          baseColor: Colors.green,
          height: 38,
          fontSize: 14,
        ),
      ],
    );
  }
}
```

Le sous-titre de l'étape 1 (« Forge: … », et son lecteur de `stackable`) reste tel quel ici ; Task 3 le réécrit.

- [ ] **Step 6: Les rendus — une prise par rune, aucune vide**

Replace the whole of `lib/ui/widgets/ui_card/card_rune_sockets.dart` with:

```dart
import 'package:flutter/material.dart';
import 'ui_card_helpers.dart';

/// Une prise par rune portée, garnie de son emoji ; aucune vide — la
/// capacité n'existe plus (spec P-43 E2, §4.10).
class CardRuneSockets extends StatelessWidget {
  final List<String> forgeUpgrades;

  const CardRuneSockets({
    super.key,
    required this.forgeUpgrades,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58.0,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 2.0,
        runSpacing: 2.0,
        children: [
          ...forgeUpgrades.map((upgrade) => Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black45,
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 1.5,
                      spreadRadius: 0.25,
                    ),
                  ],
                ),
                child: Center(
                  child: FittedBox(
                    child: Text(
                      getRuneEmoji(upgrade),
                      style: const TextStyle(fontSize: 7.0),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
```

In `lib/ui/widgets/ui_card/ui_card_helpers.dart`, replace:

```dart
/// L'emoji d'une rune, lu dans sa donnée comme le rendu Flame le lit déjà
/// (spec P-43 E1, §5.2) ; une rune absente du registre prend l'emoji par
/// défaut.
String getRuneEmoji(String upgrade) =>
    ForgeUpgradeData.getById(upgrade.split(':')[0])?.emoji ?? '🔮';
```

with:

```dart
/// L'emoji d'une rune, lu dans sa donnée comme le rendu Flame le lit déjà
/// (spec P-43 E1, §5.2), par l'analyseur unique des références (spec P-43
/// E2, §1.3, E-S6) ; une référence mal formée, ou une rune absente du
/// registre, prend l'emoji par défaut.
String getRuneEmoji(String upgrade) =>
    switch (ForgeUpgradeData.parseRef(upgrade)) {
      (final id, _) => ForgeUpgradeData.getById(id)?.emoji ?? '🔮',
      null => '🔮',
    };
```

In `lib/ui/widgets/ui_card.dart`, replace:

```dart
  final List<String> forgeUpgrades;
  final int forgeCapacity;
  final CardType? type;
```

with:

```dart
  final List<String> forgeUpgrades;
  final CardType? type;
```

Then replace:

```dart
    this.forgeUpgrades = const [],
    this.forgeCapacity = 1,
    this.type,
```

with:

```dart
    this.forgeUpgrades = const [],
    this.type,
```

Then replace:

```dart
      forgeUpgrades: card.forgeUpgrades,
      forgeCapacity: card.forgeCapacity,
```

with:

```dart
      forgeUpgrades: card.forgeUpgrades,
```

Then replace:

```dart
      forgeUpgrades: forgeUpgrades,
      forgeCapacity: card.forgeCapacityAt(card.rarity),
```

with:

```dart
      forgeUpgrades: forgeUpgrades,
```

Then replace:

```dart
                                CardRuneSockets(
                                  forgeUpgrades: forgeUpgrades,
                                  totalSlots: forgeCapacity,
                                ),
```

with:

```dart
                                CardRuneSockets(forgeUpgrades: forgeUpgrades),
```

In `lib/game/components/widgets/card_text_renderer.dart`, delete the first line, `import 'dart:math' show max;` (its only reader was the capacity, `:365`). Then replace the sockets block `:361-425` — from `    // Rune sockets row instead of stars` to the closing `    }` of the outer `for (int r = 0; r < numRows; r++)` loop — with:

```dart
    // Une prise par rune portée, aucune vide (spec P-43 E2, §4.10).
    final int totalSlots = card.card.forgeUpgrades.length;

    final double socketDiameter = 14.0;
    final double socketRadius = 7.0;
    final double socketSpacing = 2.0;
    const int maxSlotsPerRow = 5;
    final int numRows = totalSlots == 0 ? 0 : (totalSlots + maxSlotsPerRow - 1) ~/ maxSlotsPerRow;

    for (int r = 0; r < numRows; r++) {
      final int rowStartIndex = r * maxSlotsPerRow;
      final int rowEndIndex = (rowStartIndex + maxSlotsPerRow < totalSlots)
          ? rowStartIndex + maxSlotsPerRow
          : totalSlots;
      final int rowSlotsCount = rowEndIndex - rowStartIndex;
      final double rowWidth = rowSlotsCount * socketDiameter + (rowSlotsCount - 1) * socketSpacing;
      final double startX = size.x / 2 - rowWidth / 2;
      final double socketsY = currentY + socketRadius + r * (socketDiameter + socketSpacing);

      for (int i = 0; i < rowSlotsCount; i++) {
        final int globalIndex = rowStartIndex + i;
        final double centerX = startX + i * (socketDiameter + socketSpacing) + socketRadius;
        final socketBgPaint = Paint()
          ..color = Colors.black45.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(centerX, socketsY), socketRadius, socketBgPaint);

        final socketBorderPaint = Paint()
          ..color = Colors.cyanAccent.withValues(alpha: 0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(Offset(centerX, socketsY), socketRadius, socketBorderPaint);

        final emoji = _getRuneEmoji(card.card.forgeUpgrades[globalIndex]);
        final emojiPainter = TextPainter(
          text: TextSpan(
            text: emoji,
            style: const TextStyle(fontSize: 8.0),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        emojiPainter.paint(
          canvas,
          Offset(centerX - emojiPainter.width / 2, socketsY - emojiPainter.height / 2),
        );
      }
    }
```

Then replace:

```dart
  String _getRuneEmoji(String upgrade) {
    final id = upgrade.split(':')[0];
    final upgradeData = ForgeUpgradeData.getById(id);
    return upgradeData?.emoji ?? '🔮';
  }
```

with:

```dart
  /// L'emoji d'une rune, par l'analyseur unique des références (spec P-43
  /// E2, §1.3, E-S6) ; une référence mal formée, ou une rune absente du
  /// registre, prend l'emoji par défaut.
  String _getRuneEmoji(String upgrade) =>
      switch (ForgeUpgradeData.parseRef(upgrade)) {
        (final id, _) => ForgeUpgradeData.getById(id)?.emoji ?? '🔮',
        null => '🔮',
      };
```

Replace the whole of `lib/ui/widgets/forge/forge_card_preview.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../ui_card.dart';
import '../ui_card/ui_card_helpers.dart';

/// La carte d'un dialogue de forge, et une prise par rune qu'elle porte —
/// aucune vide : la capacité n'existe plus (spec P-43 E2, §4.5, §4.10).
class ForgeCardPreview extends StatelessWidget {
  final CardInstance card;
  final String locale;
  final AppLocalizations l10n;

  const ForgeCardPreview({
    super.key,
    required this.card,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: UiCard.fromInstance(
            card: card,
            locale: locale,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 120.0,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              ...card.forgeUpgrades.map((upgrade) => Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black45,
                      border: Border.all(
                        color: Colors.cyanAccent,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                          blurRadius: 3.0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: FittedBox(
                        child: Text(
                          getRuneEmoji(upgrade),
                          style: const TextStyle(fontSize: 11.0),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
```

In `lib/ui/widgets/forge_upgrade_dialog.dart`, replace:

```dart
  late List<ForgeSlot> _slots;
  late int _totalMaxForgeUpgrades;

  @override
  void initState() {
    super.initState();
    _totalMaxForgeUpgrades = widget.card.forgeCapacity;

```

with:

```dart
  late List<ForgeSlot> _slots;

  @override
  void initState() {
    super.initState();

```

Then replace:

```dart
                        // Left panel: Card + capacity info
                        final cardPanel = SizedBox(
                          width: isDesktop ? 240 : double.infinity,
                          child: ForgeCardPreview(
                            card: widget.card,
                            totalMaxForgeUpgrades: _totalMaxForgeUpgrades,
                            locale: locale,
```

with:

```dart
                        // Left panel: Card
                        final cardPanel = SizedBox(
                          width: isDesktop ? 240 : double.infinity,
                          child: ForgeCardPreview(
                            card: widget.card,
                            locale: locale,
```

- [ ] **Step 7: Le feu ne refuse plus une carte pleine ; les pré-forgées bornées par le rang**

In `lib/ui/screens/rest_card_selection_screen.dart`, replace:

```dart
  void _onCardTapped(BuildContext context, WidgetRef ref, CardInstance card) async {
    final locale = Localizations.localeOf(context).languageCode;

    if (isForge) {
      if (card.forgeUpgrades.length >= card.forgeCapacity) {
        context.showNotification(
          locale == 'fr'
              ? "Cette carte a atteint sa capacité maximale d'améliorations de forge !"
              : "This card has reached its maximum forge upgrades capacity!",
          type: NotificationType.error,
        );
        return;
      }

      // Une carte à qui plus aucune rune ne peut s'offrir est refusée avant
```

with:

```dart
  void _onCardTapped(BuildContext context, WidgetRef ref, CardInstance card) async {
    if (isForge) {
      // Une carte à qui plus aucune rune ne peut s'offrir est refusée avant
```

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
    final int maxUpgrades = data.forgeCapacityAt(finalRarity);
```

with:

```dart
    // Une pré-forgée porte au plus autant de runes que sa rareté a demandé
    // de fusions — une commune n'en porte aucune (D28 ; spec P-43 E2, §4.9).
    final int maxUpgrades = finalRarity.fusionRank;
```

- [ ] **Step 8: La donnée — le gabarit de carte et les six signatures**

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
  "effects": [
    { "type": "damage", "value": 6 }
  ],
  "baseMaxForgeUpgrades": 1
}''',
```

with:

```dart
  "effects": [
    { "type": "damage", "value": 6 }
  ]
}''',
```

Dans chacun des six fichiers `assets/data/classes/berserker/cards/rage_form.json`, `assets/data/classes/berserker/cards/reckless_strike.json`, `assets/data/classes/mage/cards/magic_missile.json`, `assets/data/classes/mage/cards/mana_surge.json`, `assets/data/classes/paladin/cards/holy_shield.json` et `assets/data/classes/paladin/cards/smite.json`, replace the end of the file:

```json
  ],
  "baseMaxForgeUpgrades": 5
}
```

with:

```json
  ]
}
```

Run: `git grep -n baseMaxForgeUpgrades -- assets lib test`
Expected: aucune sortie.

- [ ] **Step 9: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/card_rarity_test.dart` — Expected: `+7: All tests passed!`
Run: `flutter test test/unit/decoupled_forge_test.dart` — Expected: `+9: All tests passed!`
Run: `flutter test test/unit/deck_controller_test.dart` — Expected: `+25: All tests passed!`
Run: `flutter test test/widget/ui_card_rune_sockets_test.dart` — Expected: `+4: All tests passed!`
Run: `flutter test test/widget/rest_card_selection_screen_test.dart` — Expected: `+2: All tests passed!`
Run: `flutter test test/widget/deck_screen_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/unit/deck_state_persistence_test.dart test/unit/shop_controller_test.dart test/unit/real_bundle_load_test.dart test/unit/content_editor/ test/widget/forge_upgrade_dialog_test.dart test/widget/ui_card_values_test.dart test/widget/forge_fusion_screen_test.dart` — Expected: `All tests passed!` Si `real_bundle_load_test` rougit sur une signature, supprimer `build/unit_test_assets` et relancer.

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1398: All tests passed!` (1398 + 0 : la capacité −3 dans `card_rarity_test`, −1 dans `decoupled_forge_test`, la carte pleine −1 ; l'héritage +2 — les niveaux additionnés, l'exclusion d'E-S3 —, l'emoji mal formé +1, l'écran de deck +1, la borne des pré-forgées +1).
Run: `git grep -n -e forgeCapacity -e forgeCapacityAt -e baseMaxForgeUpgrades -- lib test assets tool`
Expected: aucune sortie — la capacité n'a plus aucun lecteur (spec §4.11).

- [ ] **Step 11: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/card_data.dart lib/models/card_instance.dart lib/game/controllers/deck_controller.dart lib/ui/screens/deck_screen.dart lib/ui/widgets/forge_upgrade_dialog.dart lib/ui/widgets/forge/forge_card_preview.dart lib/ui/widgets/ui_card.dart lib/ui/widgets/ui_card/card_rune_sockets.dart lib/ui/widgets/ui_card/ui_card_helpers.dart lib/game/components/widgets/card_text_renderer.dart lib/ui/screens/rest_card_selection_screen.dart lib/game/controllers/shop_controller.dart lib/services/content_editor/entity_descriptor.dart assets/data/classes test/unit/card_rarity_test.dart test/unit/decoupled_forge_test.dart test/unit/deck_controller_test.dart test/unit/deck_state_persistence_test.dart test/widget/ui_card_rune_sockets_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/deck_screen_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/shop_controller_test.dart
git commit -F- <<'EOF'
feat(fusion): la capacite disparait, la fusion garde toutes les runes

Plus de capacite de forge : une prise par rune portee, aucune vide ; la
fusion garde les runes de ses trois exemplaires, sans plafond par carte
et sans etape de choix ; une pre-forgee porte au plus autant de runes que
sa rarete a demande de fusions. baseMaxForgeUpgrades quitte le modele,
l editeur et les six signatures.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Chaque fusion offre une rune parmi trois — `drawRunes`, le dialogue réduit au choix, la session de forge supprimée

Le cœur d'A1 et d'A2 (spec §4.4, §4.5) : `ForgeRuneRules.drawRunes`, fonction pure, tire jusqu'à trois runes éligibles, pondérées par `weight`, sans remise ; `DeckNotifier.mergeCards` rend la carte qu'il crée ; l'écran de deck tire l'offre sur elle — au rang qu'elle atteint — et ouvre `ForgeUpgradeDialog`, réduit au choix : ni annulation, ni retour, ni relance, ni fente achetée ; le choix pose `id:1` par `addForgeUpgrade`. Sans offre, la fusion se fait sans dialogue : `deckMergeSuccess`, puis `forgeNoEligibleRune`. `_confirmMerge` reçoit le `context` de l'écran, non celui de la case de la grille, que la fusion peut démonter. `ForgeSlotRow` devient la ligne de rune ; `ForgeBuySlotButton` disparaît. A3 : la session de forge et les fentes achetées n'ont plus de lecteur — `forgeSlots`, `forgeTargetCardId`, `forgeTargetSessions`, `bonusForgeSlots`, `setForgeSession`, `clearForgeSession`, `buyBonusForgeSlot` sont supprimés, avec la ligne du menu de debug et `GoldManager`, vide (Task 4 le recrée). Les textes de la forge de la partie 1 que la fusion lit suivent (§5.7) : le titre du dialogue, « OFFRES DE LA FORGE », le bouton « Forger », « Forge: » de l'étape 1 et l'en-tête de l'infobulle Flame.

**La forge du feu, d'ici Task 4**, appelle le même dialogue, sur une offre de `drawRunes` : une rune parmi trois, au niveau 1 (plan, « Ce que le plan précise », point 1). Task 4 remplace ce chemin par l'affûtage.

Changements de jeu de la tâche, voulus (spec §11) : chaque fusion offre une rune au choix parmi trois — moins quand moins sont permises —, au niveau 1, et le dialogue ne se ferme que par ce choix ; une fusion sans rune éligible le dit ; la forge du feu perd ses fentes tirées, ses relances, ses fentes achetées et la mémoire de sa session ; l'infobulle d'une carte en combat titre ses runes « === RUNES === ».

**Files:**
- Modify: `lib/game/services/forge_rune_rules.dart:1-2`, après `:134` (`drawRunes`)
- Modify: `lib/models/data/forge_upgrade_data.dart:253-260`
- Modify: `lib/game/controllers/deck_controller.dart` (`mergeCards`, tel que Task 2 l'a laissé)
- Modify (réécrit en entier): `lib/ui/widgets/forge_upgrade_dialog.dart`, `lib/ui/widgets/forge/forge_slot_row.dart`, `lib/ui/screens/deck_screen.dart`
- Delete: `lib/ui/widgets/forge/forge_buy_slot_button.dart`
- Modify: `lib/ui/screens/rest_card_selection_screen.dart:1`, `:42-59`
- Modify: `lib/ui/screens/rest_screen.dart:106`
- Modify: `lib/game/controllers/run_controller.dart:11`, `:21`, `:32-35`, `:77-80`, `:95-100`, `:115-122`, `:139-142`, `:152-164`, `:192-195`, `:216`, `:222`, `:503-523`
- Delete: `lib/game/controllers/run/gold_manager.dart`
- Modify: `lib/ui/widgets/debug/tabs/debug_run_tab.dart:59-66`
- Modify: `lib/game/components/card_component.dart:443`
- Modify: `lib/l10n/app_en.arb:497`, `lib/l10n/app_fr.arb:208` ; régénérés par `flutter gen-l10n` : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Test: `test/unit/forge_rune_rules_test.dart:1`, `:10-22`, après `:190` (groupe neuf)
- Test: `test/unit/forge_upgrade_data_test.dart` (après le cas `tooltipLines`)
- Test: `test/unit/deck_controller_test.dart` (les cas de `mergeCards`, tels que Task 2 les a laissés)
- Test: `test/widget/forge_upgrade_dialog_test.dart` (réécrit en entier)
- Test: `test/widget/deck_screen_test.dart:10-11`, `:55-56`, en fin de fichier (quatre cas neufs)
- Test: `test/unit/run_controller_test.dart:189-249`
- Test: `test/unit/run_state_persistence_test.dart:7`, `:29-40`, `:59-64`, `:79-84`, `:120-135`

**Interfaces:**
- Consumes: `ForgeRuneRules.isEligible` (Task 1) ; `void DeckNotifier.mergeCards(List<String>)` (Task 2) ; `ForgeCardPreview` (Task 2) ; `DeckNotifier.addForgeUpgrade(String uniqueId, String upgrade)` (`deck_controller.dart:344-354`, inchangé).
- Produces:
  - `static List<String> ForgeRuneRules.drawRunes(CardInstance card, Iterable<ForgeUpgradeData> catalog, Random rng, {required int count})` — Task 5 l'appelle sur le registre du tutoriel.
  - `CardInstance? DeckNotifier.mergeCards(List<String> selectedIds)` — la carte créée, `null` si la fusion est refusée.
  - `String ForgeUpgradeData.nameAt(int level, String locale)`.
  - `ForgeUpgradeDialog({Key? key, required CardInstance card, required List<String> offer})` — `ConsumerWidget` ; pose `id:1`, se ferme sur l'id choisi.
  - `ForgeSlotRow({Key? key, required ForgeUpgradeData rune, required String title, required String description, required String actionLabel, required VoidCallback? onAction})` — Task 4 lui ajoute `detail`.
  - ARB : `fusionRuneTitle`, `fusionRuneSubtitle`, `fusionRuneChoose`, `mergeRunesLabel(String runes)`, `mergeRunesNone`.
  - `RunState` sans `forgeSlots`, `forgeTargetCardId`, `forgeTargetSessions`, `bonusForgeSlots` ; `RunController` sans `setForgeSession`, `clearForgeSession`, `buyBonusForgeSlot` ni champ `_goldManager`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
```

with:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
```

Then replace the `_rune` helper (`:10-22`):

```dart
ForgeUpgradeData _rune(String id, {bool stackable = true, int? maxLevel}) =>
    ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      stackable: stackable,
      maxLevel: maxLevel,
    );
```

with:

```dart
ForgeUpgradeData _rune(
  String id, {
  bool stackable = true,
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
      pools: const ['common'],
      minFusionRank: minFusionRank,
      stackable: stackable,
      maxLevel: maxLevel,
      weight: weight,
    );
```

Then replace the end of the file:

```dart
    test('jamais de fusion pour une rune non cumulable', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['enduring:1', 'enduring:1'])),
        isEmpty,
      );
    });
  });
}
```

with:

```dart
    test('jamais de fusion pour une rune non cumulable', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['enduring:1', 'enduring:1'])),
        isEmpty,
      );
    });
  });

  // L'offre de la fusion (spec P-43 E2, A2, §4.4).
  group('ForgeRuneRules.drawRunes', () {
    // Une Frappe peu commune : le rang 1 qu'atteint une premiere fusion.
    final card = CardInstance(
      data: const CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [CardEffect(type: 'damage', value: 6)],
      ),
      rarity: CardRarity.uncommon,
    );
    // Refusee a une peu commune : elle attend le rang 2.
    final refused = _rune('refused', minFusionRank: 2);

    test('au plus count ids distincts, tous eligibles', () {
      const eligible = ['a', 'b', 'c', 'd', 'e'];
      final catalog = [for (final id in eligible) _rune(id), refused];
      for (var seed = 0; seed < 20; seed++) {
        final drawn =
            ForgeRuneRules.drawRunes(card, catalog, Random(seed), count: 3);
        expect(drawn, hasLength(3), reason: 'graine $seed');
        expect(drawn.toSet(), hasLength(3), reason: 'graine $seed');
        expect(drawn, everyElement(isIn(eligible)), reason: 'graine $seed');
      }
    });

    test('moins s il y en a moins', () {
      final drawn = ForgeRuneRules.drawRunes(
          card, [_rune('a'), _rune('b'), refused], Random(1),
          count: 3);
      expect(drawn.toSet(), {'a', 'b'});
    });

    test('aucune s il n y en a pas', () {
      expect(ForgeRuneRules.drawRunes(card, [refused], Random(1), count: 3),
          isEmpty);
    });

    test('le tirage suit weight', () {
      final catalog = [_rune('heavy', weight: 90), _rune('light', weight: 10)];
      final rng = Random(42);
      var heavy = 0;
      for (var i = 0; i < 2000; i++) {
        if (ForgeRuneRules.drawRunes(card, catalog, rng, count: 1).single ==
            'heavy') {
          heavy++;
        }
      }
      expect(heavy / 2000, inInclusiveRange(0.86, 0.94));
    });

    // Review Focus 1 : un fichier peut declarer weight 0 ; D65 veut une offre
    // tant qu'une rune est eligible.
    test('des runes de poids nul se tirent encore', () {
      final catalog = [_rune('a', weight: 0), _rune('b', weight: 0)];
      expect(
        ForgeRuneRules.drawRunes(card, catalog, Random(3), count: 3).toSet(),
        {'a', 'b'},
      );
    });
  });
}
```

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
      ['Tranchant 3 : +3 Dégâts'],
    );
  });
```

with:

```dart
      ['Tranchant 3 : +3 Dégâts'],
    );
  });

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

In `test/unit/deck_controller_test.dart`, replace:

```dart
      notifier.mergeCards([card1.uniqueId, card2.uniqueId, card3.uniqueId]);

      expect(notifier.state.masterDeck.length, 1);
      final mergedCard = notifier.state.masterDeck.first;
```

with:

```dart
      final merged =
          notifier.mergeCards([card1.uniqueId, card2.uniqueId, card3.uniqueId]);

      expect(notifier.state.masterDeck.length, 1);
      final mergedCard = notifier.state.masterDeck.first;
      // La carte rendue est celle que le deck porte : l'ecran de deck tire
      // l'offre sur elle (spec P-43 E2, §4.5).
      expect(merged, same(mergedCard));
```

Then replace:

```dart
      notifier.mergeCards(copies.map((c) => c.uniqueId).toList());

      expect(notifier.state.masterDeck, hasLength(3));
```

with:

```dart
      expect(notifier.mergeCards(copies.map((c) => c.uniqueId).toList()),
          isNull);

      expect(notifier.state.masterDeck, hasLength(3));
```

Then replace both occurrences (Edit with `replace_all`) of:

```dart
      notifier.mergeCards(trio.map((c) => c.uniqueId).toList());

      expect(notifier.state.masterDeck, trio);
```

with:

```dart
      expect(notifier.mergeCards(trio.map((c) => c.uniqueId).toList()), isNull);

      expect(notifier.state.masterDeck, trio);
```

Replace the whole of `test/widget/forge_upgrade_dialog_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';

import '../unit/shipped_data.dart';

/// Une Frappe peu commune : la carte qu'une première fusion de Frappes rend.
CardInstance _mergedStrike() => CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
    );

/// Ouvre le dialogue de fusion sur [card], posée dans le deck, par
/// `showDialog` au-dessus d'une page — comme l'écran de deck ; [onClosed]
/// reçoit ce sur quoi il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card,
  List<String> offer, {
  ValueChanged<String?>? onClosed,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  shippedRuneRegistry(const ['burning', 'sharp', 'shocking'],
      cards: [card.data]);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(deckProvider.notifier).addCardToMasterDeck(card);

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
              onPressed: () async {
                final chosen = await showDialog<String>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ForgeUpgradeDialog(card: card, offer: offer),
                );
                onClosed?.call(chosen);
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return container;
}

/// Le dialogue de fusion, réduit au choix (spec P-43 E2, A1, A2, §4.5).
void main() {
  testWidgets('une ligne par rune offerte : trois pour trois, une pour une',
      (tester) async {
    await _openDialog(
        tester, _mergedStrike(), const ['sharp', 'burning', 'shocking']);

    expect(find.text('FUSION — CHOISISSEZ UNE RUNE'), findsOneWidget);
    expect(find.byType(ForgeSlotRow), findsNWidgets(3));
    expect(find.text('Choisir'), findsNWidgets(3));
    // Au niveau 1, sur cette carte : 7 degats en peu commune, +1.
    expect(
      find.text('+1 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );

    // Le premier dialogue ne se ferme que par un choix : l'arbre est démonté
    // avant d'en ouvrir un second, sans quoi il resterait sur le Navigator.
    await tester.pumpWidget(const SizedBox());
    await _openDialog(tester, _mergedStrike(), const ['burning']);

    expect(find.byType(ForgeSlotRow), findsOneWidget);
    expect(find.text('Brûlant 1'), findsOneWidget);
  });

  testWidgets('ni Annuler, ni retour, ni relance, ni fente achetee',
      (tester) async {
    await _openDialog(tester, _mergedStrike(), const ['sharp', 'burning']);

    expect(find.text('Annuler'), findsNothing);
    expect(find.byIcon(Icons.autorenew), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline), findsNothing);

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsOneWidget);
  });

  testWidgets('le choix pose la rune au niveau 1 et ferme le dialogue sur elle',
      (tester) async {
    String? chosen;
    final container = await _openDialog(
      tester,
      _mergedStrike(),
      const ['sharp', 'burning'],
      onClosed: (id) => chosen = id,
    );

    await tester.tap(find.descendant(
      of: find.widgetWithText(ForgeSlotRow, 'Brûlant 1'),
      matching: find.text('Choisir'),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(chosen, 'burning');
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['burning:1']);
  });
}
```

In `test/widget/deck_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';

void main() {
```

with:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';

import '../unit/shipped_data.dart';

void main() {
```

Then replace:

```dart
        home: DeckScreen(allowMerge: allowMerge),
      ),
    );
  }
```

with:

```dart
        home: DeckScreen(allowMerge: allowMerge),
      ),
    );
  }

  /// Une vue large : le dialogue de fusion est plein écran.
  void largeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Un deck de [cards], sur le registre des runes livrées, que l'écran de
  /// deck lit pour tirer l'offre.
  ProviderContainer deckOf(List<CardInstance> cards) {
    shippedRuneRegistry(shippedRuneIds());
    final container = ProviderContainer();
    addTearDown(container.dispose);
    for (final card in cards) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
    return container;
  }

  List<String> messagesOf(ProviderContainer container) =>
      [for (final n in container.read(notificationProvider)) n.message];

  /// Laisse expirer les notifications avant de démonter l'arbre.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  }
```

Then replace the end of the file (the case Task 2 added):

```dart
      // Les notifications expirent avant le demontage de l'arbre.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
```

with:

```dart
      // Les notifications expirent avant le demontage de l'arbre.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );

  // Spec P-43 E2, A1, §4.5 : la fusion, puis le choix d'une rune.
  testWidgets('trois Frappes fusionnent, et la carte recoit la rune choisie '
      'parmi trois', (WidgetTester tester) async {
    largeView(tester);
    final strike = shippedCard('strike_basic');
    final container =
        deckOf([for (var i = 0; i < 3; i++) CardInstance(data: strike)]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Peu commune : Tranchant, Brulant, Congelant et Surcharge s'offrent ;
    // trois sont tirees.
    expect(find.byType(ForgeUpgradeDialog), findsOneWidget);
    expect(find.byType(ForgeSlotRow), findsNWidgets(3));
    expect(messagesOf(container), isEmpty);

    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    final merged = container.read(deckProvider).masterDeck.single;
    expect(merged.rarity, CardRarity.uncommon);
    final (id, level) = ForgeUpgradeData.parseRef(merged.forgeUpgrades.single)!;
    expect(level, 1);
    expect(id, isIn(['sharp', 'burning', 'freezing', 'shocking']));
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });

  testWidgets('trois Concentrations communes fusionnent sans choix : le '
      'succes, puis le motif', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(data: shippedCard('concentration')),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Peu commune, une carte gratuite qui pioche : aucune rune ne s'offre.
    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        isEmpty);
    expect(messagesOf(container), [
      'Fusion réussie : Concentration est maintenant Niveau 2 !',
      'Aucune rune ne peut être ajoutée à cette carte.',
    ]);
    await settle(tester);
  });

  testWidgets('le rang atteint : trois Concentrations peu communes, fusionnees '
      'en rare, n offrent que Veloce', (WidgetTester tester) async {
    largeView(tester);
    final container = deckOf([
      for (var i = 0; i < 3; i++)
        CardInstance(
          data: shippedCard('concentration'),
          rarity: CardRarity.uncommon,
        ),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();

    // Jugee au rang des exemplaires, peu commune, l'offre serait vide.
    expect(find.byType(ForgeSlotRow), findsOneWidget);
    expect(find.text('Véloce'), findsOneWidget);

    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();

    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['quick:1']);
    expect(messagesOf(container),
        ['Fusion réussie : Concentration est maintenant Niveau 3 !']);
    await settle(tester);
  });

  testWidgets('la case fusionnee sort de la grille : le succes s affiche '
      'quand meme', (WidgetTester tester) async {
    largeView(tester);
    final strike = shippedCard('strike_basic');
    final container = deckOf([
      CardInstance(data: strike, rarity: CardRarity.uncommon),
      CardInstance(data: shippedCard('defend_basic')),
      for (var i = 0; i < 3; i++) CardInstance(data: strike),
    ]);

    await tester.pumpWidget(buildApp(container));
    await tester.pumpAndSettle();
    await tester.tap(find.text('FUSIONNER (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir').first);
    await tester.pumpAndSettle();

    // Le groupe fusionne, dernier de la grille, en est sorti : la carte
    // fusionnee a rejoint la Frappe peu commune (`mergeCards` l'ajoute en
    // fin de deck), et sa case a ete demontee pendant le choix.
    expect(find.byType(UiCard), findsNWidgets(2));
    expect(messagesOf(container),
        ['Fusion réussie : Frappe est maintenant Niveau 2 !']);
    await settle(tester);
  });
}
```

In `test/unit/run_controller_test.dart`, delete the two cases of A3 (`:189-249`) — from `    test('Forge session: setForgeSession and clearForgeSession work correctly', () {` through the closing `    });` of `    test('buyBonusForgeSlot checks progressive cost and gold limits', () {` — and the blank line before the first, so that the group `RunController & RunState Tests` ends after the case `'startNewRun resets bonusShopCards to 0 and gold to 50 in inventory'`.

In `test/unit/run_state_persistence_test.dart`, delete the import:

```dart
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

Then replace:

```dart
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'enduring',
            nameEn: 'Enduring',
            nameFr: 'Increvable',
            descriptionEn: 'Never exhausts.',
            descriptionFr: "N'est jamais épuisée.",
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
          ),
        ],
      );
```

with:

```dart
        relics: [],
        forgeUpgrades: [],
      );
```

Then replace:

```dart
          currentNodeId: 'floor_3_node_1',
          forgeSlots: const ['enduring:1'],
          forgeTargetCardId: 'card-1',
          forgeTargetSessions: const {
            'card-1': ['enduring:1'],
          },
          bonusForgeSlots: 1,
          pendingDrafts: 2,
```

with:

```dart
          currentNodeId: 'floor_3_node_1',
          pendingDrafts: 2,
```

Then replace:

```dart
      expect(restored.currentNodeId, 'floor_3_node_1');
      expect(restored.forgeSlots, ['enduring:1']);
      expect(restored.forgeTargetCardId, 'card-1');
      expect(restored.forgeTargetSessions, {
        'card-1': ['enduring:1'],
      });
      expect(restored.bonusForgeSlots, 1);
      expect(restored.pendingDrafts, 2);
```

with:

```dart
      expect(restored.currentNodeId, 'floor_3_node_1');
      expect(restored.pendingDrafts, 2);
```

Then delete the whole case `:120-135` — from `    test('drops a missing forge upgrade id from forgeSlots and reports it', () {` to its closing `    });` — and the blank line before it.

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/forge_upgrade_data_test.dart test/unit/deck_controller_test.dart test/widget/forge_upgrade_dialog_test.dart test/widget/deck_screen_test.dart`
Expected: FAIL à la compilation — `The method 'drawRunes' isn't defined`, `The method 'nameAt' isn't defined`, `This expression has a type of 'void'` (`mergeCards`), `No named parameter with the name 'offer'` et `'rune'`.

- [ ] **Step 3: Le tirage — `drawRunes`**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
```

with:

```dart
import 'dart:math';

import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
```

Then replace the end of the file, as Task 1 left it:

```dart
    // D3 : une seule rune de chaque type par carte — une rune portée ne se
    // repropose jamais, plafond atteint ou non (D75 en est un cas).
    return !carried.containsKey(rune.id);
  }
}
```

with:

```dart
    // D3 : une seule rune de chaque type par carte — une rune portée ne se
    // repropose jamais, plafond atteint ou non (D75 en est un cas).
    return !carried.containsKey(rune.id);
  }

  /// Jusqu'à [count] ids **distincts** de runes du [catalog] que le prédicat
  /// accepte sur [card], tirés pondérés par `weight`, sans remise (D3, D65 ;
  /// spec P-43 E2, A2, §4.4) : moins s'il y en a moins, aucun s'il n'y en a
  /// pas. Une fonction pure, sur ses entrées ; [card] est la carte qui reçoit
  /// la rune — la carte fusionnée, au rang qu'elle atteint. Un poids nul ou
  /// négatif ne pèse rien ; des runes éligibles qui ne pèsent rien se tirent
  /// encore, à parts égales : jamais aucune tant qu'une existe (D65).
  static List<String> drawRunes(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
    Random rng, {
    required int count,
  }) {
    final pool = [
      for (final rune in catalog)
        if (isEligible(rune, card, catalog)) rune,
    ];
    final drawn = <String>[];
    while (drawn.length < count && pool.isNotEmpty) {
      final weights = [for (final rune in pool) max(0, rune.weight)];
      final total = weights.fold(0, (sum, weight) => sum + weight);
      var index = 0;
      if (total == 0) {
        index = rng.nextInt(pool.length);
      } else {
        var pick = rng.nextInt(total);
        while (pick >= weights[index]) {
          pick -= weights[index];
          index++;
        }
      }
      drawn.add(pool.removeAt(index).id);
    }
    return drawn;
  }
}
```

- [ ] **Step 4: Le nom d'une rune à un niveau — `nameAt`**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
  /// La ligne de la rune dans l'infobulle d'une carte, au niveau [level] que
  /// joue le moteur — le total de ses exemplaires (spec P-43 E1, §5.2) :
  /// `<nom>[ <niveau>] : <description>`. Le niveau ne s'écrit que si la rune
  /// en a plus d'un (`maxLevel` autre que 1).
  String tooltipLine(int level, String locale, CardData card, CardRarity rarity) {
    final name = maxLevel == 1 ? getName(locale) : '${getName(locale)} $level';
    return '$name : ${getDescription(level, locale, card, rarity)}';
  }
```

with:

```dart
  /// Le nom de la rune au niveau [level] : le niveau ne s'écrit que si la
  /// rune en a plus d'un (`maxLevel` autre que 1). La règle des infobulles
  /// (spec P-43 E1, §5.2), que suivent aussi la ligne de rune et le dialogue
  /// de fusion (spec P-43 E2, §4.11).
  String nameAt(int level, String locale) =>
      maxLevel == 1 ? getName(locale) : '${getName(locale)} $level';

  /// La ligne de la rune dans l'infobulle d'une carte, au niveau [level] que
  /// joue le moteur — le total de ses exemplaires (spec P-43 E1, §5.2) :
  /// `<nom>[ <niveau>] : <description>`.
  String tooltipLine(int level, String locale, CardData card, CardRarity rarity) =>
      '${nameAt(level, locale)} : ${getDescription(level, locale, card, rarity)}';
```

- [ ] **Step 5: `mergeCards` rend la carte qu'il crée**

In `lib/game/controllers/deck_controller.dart`, replace the whole method `mergeCards` as Task 2 left it — from `  /// Fusionne trois exemplaires d'une même carte, à une même rareté, en une` to its closing `  }` — with:

```dart
  /// Fusionne trois exemplaires d'une même carte, à une même rareté, en une
  /// carte de la rareté suivante, qui garde toutes leurs runes (D13 ; spec
  /// P-43 E2, §4.6) : `ForgeRuneRules.consolidate` additionne les niveaux
  /// d'une même rune, bornés par son plafond, et écarte une rune exclue par
  /// une rune gardée avant elle ; aucun plafond de runes par carte. Rend la
  /// carte créée — l'écran de deck tire sur elle l'offre de runes (§4.5) —,
  /// ou `null` si la fusion est refusée.
  CardInstance? mergeCards(List<String> selectedIds) {
    if (selectedIds.length != 3) return null;
    final selectedCards = [
      for (final id in selectedIds)
        ...state.masterDeck.where((c) => c.uniqueId == id),
    ];
    if (selectedCards.length != 3) return null;

    // Trois exemplaires d'une même carte à une même rareté, qui en a une
    // au-delà : ni une carte `unique` ni une légendaire n'en ont.
    final first = selectedCards.first;
    final nextRarity = first.rarity.next;
    if (nextRarity == null ||
        selectedCards.any((c) => c.data.id != first.data.id || c.rarity != first.rarity)) {
      return null;
    }

    final merged = CardInstance(
      data: first.data,
      rarity: nextRarity,
      forgeUpgrades: ForgeRuneRules.consolidate(
        selectedCards.expand((card) => card.forgeUpgrades),
      ),
    );
    // Retire les 3 exemplaires ; la carte fusionnée rejoint la fin du deck.
    state = state.copyWith(masterDeck: [
      ...state.masterDeck.where((c) => !selectedIds.contains(c.uniqueId)),
      merged,
    ]);
    return merged;
  }
```

- [ ] **Step 6: Les chaînes de la fusion**

In `lib/l10n/app_en.arb`, replace:

```json
  "confirmMerge": "Confirm Merge",
```

with:

```json
  "confirmMerge": "Confirm Merge",
  "mergeRunesLabel": "Runes: {runes}",
  "@mergeRunesLabel": {
    "placeholders": {
      "runes": { "type": "String" }
    }
  },
  "mergeRunesNone": "Runes: none",
  "fusionRuneTitle": "MERGE — CHOOSE A RUNE",
  "fusionRuneSubtitle": "The card keeps its three copies' runes and gains one more, at level 1.",
  "fusionRuneChoose": "Choose",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "confirmMerge": "Confirmer la fusion",
```

with:

```json
  "confirmMerge": "Confirmer la fusion",
  "mergeRunesLabel": "Runes : {runes}",
  "mergeRunesNone": "Runes : aucune",
  "fusionRuneTitle": "FUSION — CHOISISSEZ UNE RUNE",
  "fusionRuneSubtitle": "La carte garde les runes de ses trois exemplaires et en reçoit une de plus, au niveau 1.",
  "fusionRuneChoose": "Choisir",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `git status --short lib/l10n` montre les deux ARB et les trois `app_localizations*.dart` modifiés.

- [ ] **Step 7: La ligne de rune et le dialogue réduit au choix**

Replace the whole of `lib/ui/widgets/forge/forge_slot_row.dart` with:

```dart
import 'package:flutter/material.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../game_button.dart';

/// La ligne d'une rune, commune aux écrans qui en proposent une — le choix
/// de la fusion, l'affûtage du feu (spec P-43 E2, §4.5) : l'icône et la
/// couleur de la rune, un titre, sa description, et un bouton dont l'écran
/// donne le libellé et l'état.
class ForgeSlotRow extends StatelessWidget {
  final ForgeUpgradeData rune;
  final String title;
  final String description;
  final String actionLabel;

  /// L'action du bouton ; `null` : le bouton est inactif.
  final VoidCallback? onAction;

  const ForgeSlotRow({
    super.key,
    required this.rune,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  Color _getUpgradeColorFromString(String colorStr) {
    switch (colorStr) {
      case 'redAccent':
        return Colors.redAccent;
      case 'blueAccent':
        return Colors.blueAccent;
      case 'orangeAccent':
        return Colors.orangeAccent;
      case 'lightBlueAccent':
        return Colors.lightBlueAccent;
      case 'amberAccent':
        return Colors.amberAccent;
      case 'amber':
        return Colors.amber;
      case 'cyanAccent':
        return Colors.cyanAccent;
      case 'greenAccent':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getUpgradeIconFromString(String iconStr) {
    switch (iconStr) {
      case 'hardware_rounded':
        return Icons.hardware_rounded;
      case 'shield_rounded':
        return Icons.shield_rounded;
      case 'local_fire_department_rounded':
        return Icons.local_fire_department_rounded;
      case 'ac_unit_rounded':
        return Icons.ac_unit_rounded;
      case 'flash_on_rounded':
        return Icons.flash_on_rounded;
      case 'style_rounded':
        return Icons.style_rounded;
      case 'diamond_rounded':
        return Icons.diamond_rounded;
      case 'hourglass_bottom_rounded':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getUpgradeColorFromString(rune.color);
    final icon = _getUpgradeIconFromString(rune.icon);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withAlpha(100),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GameButton(
            text: actionLabel,
            onPressed: onAction,
            baseColor: color,
            height: 36,
            fontSize: 13,
          ),
        ],
      ),
    );
  }
}
```

Replace the whole of `lib/ui/widgets/forge_upgrade_dialog.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../l10n/app_localizations.dart';
import 'forge/forge_card_preview.dart';
import 'forge/forge_slot_row.dart';

/// Le dialogue de la fusion (spec P-43 E2, A1, A2, §4.5) : la carte fusionnée
/// et une ligne par rune de son [offer] — trois au plus, tirées par
/// `ForgeRuneRules.drawRunes` —, au niveau 1. Il ne se ferme que par un
/// choix : ni annulation, ni retour, ni relance, ni fente achetée. Le choix
/// pose `id:1` sur la carte par `DeckNotifier.addForgeUpgrade`, puis ferme
/// le dialogue sur l'id choisi. Le gabarit plein écran d'ADR-039 D4 reste.
class ForgeUpgradeDialog extends ConsumerWidget {
  final CardInstance card;

  /// Les ids des runes offertes, trois au plus.
  final List<String> offer;

  const ForgeUpgradeDialog({
    super.key,
    required this.card,
    required this.offer,
  });

  void _choose(BuildContext context, WidgetRef ref, String runeId) {
    ref.read(deckProvider.notifier).addForgeUpgrade(card.uniqueId, '$runeId:1');
    Navigator.of(context).pop(runeId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    final rows = [
      for (final id in offer)
        if (ForgeUpgradeData.getById(id) case final rune?)
          ForgeSlotRow(
            rune: rune,
            title: rune.nameAt(1, locale),
            description: rune.getDescription(1, locale, card.data, card.rarity),
            actionLabel: l10n.fusionRuneChoose,
            onAction: () => _choose(context, ref, id),
          ),
    ];

    // Ni annulation ni retour : le dialogue ne se ferme que par un choix (A1).
    return PopScope(
      canPop: false,
      child: Dialog.fullscreen(
        backgroundColor: const Color(0xFF0D0D1A),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black,
                  const Color(0xFF1E1000).withAlpha(180),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.fusionRuneTitle,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.fusionRuneSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth >= 720;
                          final cardPanel = SizedBox(
                            width: isDesktop ? 240 : double.infinity,
                            child: ForgeCardPreview(
                              card: card,
                              locale: locale,
                              l10n: l10n,
                            ),
                          );
                          final listPanel = Expanded(
                            child: ListView(children: rows),
                          );
                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                cardPanel,
                                const SizedBox(width: 48),
                                listPanel,
                              ],
                            );
                          }
                          return Column(
                            children: [
                              cardPanel,
                              const SizedBox(height: 24),
                              const Divider(color: Colors.white12),
                              const SizedBox(height: 12),
                              listPanel,
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

Run: `git rm lib/ui/widgets/forge/forge_buy_slot_button.dart`

- [ ] **Step 8: L'écran de deck — l'offre, le `context` stable, les runes de l'étape 1**

Replace the whole of `lib/ui/screens/deck_screen.dart` with:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/widgets/game_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/forge_upgrade_dialog.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

class DeckScreen extends ConsumerWidget {
  final bool allowMerge;
  const DeckScreen({super.key, this.allowMerge = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.menu);

    final deckState = ref.watch(deckProvider);
    final masterDeck = deckState.masterDeck;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    // Grouper les cartes pour identifier les fusions possibles
    final Map<String, List<CardInstance>> groups = {};
    for (var card in masterDeck) {
      final key = '${card.data.id}_${card.rarity.name}';
      groups.putIfAbsent(key, () => []).add(card);
    }

    final appBar = PageHeader(
      title: l10n.myDeck,
      showBackButton: true,
      isParchment: false,
    );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deckTotalCards(masterDeck.length),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  childAspectRatio: 70 / 110,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: groups.keys.length,
                // `_` et non `context` : la fusion se lance avec le `context`
                // de l'écran, que la grille ne démonte pas (spec P-43 E2,
                // §4.5).
                itemBuilder: (_, index) {
                  final key = groups.keys.elementAt(index);
                  final cardList = groups[key]!;
                  final card = cardList.first;
                  final count = cardList.length;
                  final canMerge = count >= 3;

                  return Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            UiCard.fromInstance(
                              card: card,
                              locale: locale,
                              l10n: l10n,
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  'x$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (card.rarity.next == null)
                        const SizedBox.shrink()
                      else if (canMerge && allowMerge)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () {
                            _confirmMerge(context, ref, cardList);
                          },
                          child: Text(
                            l10n.mergeLabel(3),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (canMerge && !allowMerge)
                        Text(
                          l10n.mergePossible,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          l10n.mergeMoreRequired(3 - count),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// La fusion, puis le choix d'une rune (spec P-43 E2, A1, §4.5). [context]
  /// est celui de l'écran, jamais celui de la case de la grille : la fusion
  /// reconstruit la grille, qui peut démonter la case qui l'a lancée pendant
  /// le dialogue de choix.
  void _confirmMerge(
    BuildContext context,
    WidgetRef ref,
    List<CardInstance> duplicates,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final merged = await showDialog<CardInstance>(
      context: context,
      builder: (ctx) => _MergeDialog(duplicates: duplicates, ref: ref),
    );
    if (merged == null || !context.mounted) return;

    // L'offre : une fonction pure, sur la carte que la fusion rend, au rang
    // qu'elle atteint ; l'état ne change que par `DeckNotifier`.
    final offer = ForgeRuneRules.drawRunes(
      merged,
      GameDataRegistry.instance?.forgeUpgrades ?? const <ForgeUpgradeData>[],
      Random(),
      count: 3,
    );
    if (offer.isNotEmpty) {
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ForgeUpgradeDialog(card: merged, offer: offer),
      );
      if (!context.mounted) return;
    }

    context.showNotification(
      l10n.deckMergeSuccess(merged.data.getName(locale), merged.rarity.index + 1),
      type: NotificationType.success,
    );
    // Sans rune éligible, la fusion s'est faite sans dialogue : le joueur lit
    // les deux faits, dans cet ordre (A1).
    if (offer.isEmpty) {
      context.showNotification(l10n.forgeNoEligibleRune);
    }
  }
}

class _MergeDialog extends StatefulWidget {
  final List<CardInstance> duplicates;
  final WidgetRef ref;

  const _MergeDialog({
    required this.duplicates,
    required this.ref,
  });

  @override
  State<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends State<_MergeDialog> {
  final Set<String> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.duplicates.length == 3) {
      _selectedCardIds.addAll(widget.duplicates.map((c) => c.uniqueId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performMerge();
      });
    }
  }

  /// La fusion des trois exemplaires choisis ; le dialogue se ferme sur la
  /// carte qu'elle rend, `null` si elle est refusée (spec P-43 E2, §4.5).
  void _performMerge() {
    final merged = widget.ref.read(deckProvider.notifier).mergeCards(
          widget.duplicates
              .where((c) => _selectedCardIds.contains(c.uniqueId))
              .map((c) => c.uniqueId)
              .toList(),
        );
    Navigator.of(context).pop(merged);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return GameDialog(
      glowColor: Colors.green,
      title: Text(
        l10n.confirmMerge,
      ),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez exactement 3 cartes à fusionner (Sélectionné: ${_selectedCardIds.length}/3)',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.duplicates.length,
                itemBuilder: (context, index) {
                  final card = widget.duplicates[index];
                  final isSelected = _selectedCardIds.contains(card.uniqueId);
                  // Le niveau que joue chaque rune, par l'analyseur unique,
                  // nommé selon la règle des infobulles (spec P-43 E2, §4.11,
                  // E-S6).
                  final runes = [
                    for (final MapEntry(key: id, value: level)
                        in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
                      ForgeUpgradeData.getById(id)?.nameAt(level, locale) ??
                          '$id $level',
                  ];
                  return CheckboxListTile(
                    title: Text(
                      '${card.data.getName(locale)} (${card.rarity.name.toUpperCase()})',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      runes.isEmpty
                          ? l10n.mergeRunesNone
                          : l10n.mergeRunesLabel(runes.join(', ')),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    value: isSelected,
                    activeColor: Colors.green,
                    checkColor: Colors.black,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (_selectedCardIds.length < 3) {
                            _selectedCardIds.add(card.uniqueId);
                          }
                        } else {
                          _selectedCardIds.remove(card.uniqueId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        GameButton(
          text: l10n.cancel,
          baseColor: Colors.white70,
          onPressed: () => Navigator.of(context).pop(),
          height: 38,
          fontSize: 14,
        ),
        GameButton(
          text: 'Continuer',
          onPressed: _selectedCardIds.length == 3 ? _performMerge : null,
          baseColor: Colors.green,
          height: 38,
          fontSize: 14,
        ),
      ],
    );
  }
}
```

- [ ] **Step 9: La forge du feu, le temps d'une tâche, par le dialogue réduit**

In `lib/ui/screens/rest_card_selection_screen.dart`, replace:

```dart
import 'package:flutter/material.dart';
```

with:

```dart
import 'dart:math';

import 'package:flutter/material.dart';
```

Then replace (the forge branch, as Task 2 left it):

```dart
      // Une carte à qui plus aucune rune ne peut s'offrir est refusée avant
      // le dialogue, avec son motif : la forge ne s'ouvre jamais vide (spec
      // P-43 E1, A11).
      final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
      if (!catalog
          .any((rune) => ForgeRuneRules.isEligible(rune, card, catalog))) {
        context.showNotification(
          AppLocalizations.of(context)!.forgeNoEligibleRune,
          type: NotificationType.error,
        );
        return;
      }

      final selectedUpgrade = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ForgeUpgradeDialog(card: card),
      );
```

with:

```dart
      // La forge du feu tire son offre comme la fusion (spec P-43 E2, §4.4) ;
      // une carte à qui aucune rune ne s'offre est refusée avant le
      // dialogue, avec son motif (spec P-43 E1, A11).
      final offer = ForgeRuneRules.drawRunes(
        card,
        GameDataRegistry.instance?.forgeUpgrades ?? const [],
        Random(),
        count: 3,
      );
      if (offer.isEmpty) {
        context.showNotification(
          AppLocalizations.of(context)!.forgeNoEligibleRune,
          type: NotificationType.error,
        );
        return;
      }

      final selectedUpgrade = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ForgeUpgradeDialog(card: card, offer: offer),
      );
```

In `lib/ui/screens/rest_screen.dart`, replace:

```dart
  void _leave() {
    ref.read(runProvider.notifier).clearForgeSession();
    ref.read(runProvider.notifier).completeCurrentNode();
```

with:

```dart
  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
```

- [ ] **Step 10: La session de forge et les fentes achetées disparaissent (A3)**

In `lib/game/controllers/run_controller.dart`, delete the two imports:

```dart
import '../../models/data/forge_upgrade_data.dart';
```

```dart
import 'run/gold_manager.dart';
```

Then replace:

```dart
  final PassiveData? activePassive; // Passif dynamique du héros
  final List<String> forgeSlots;
  final String? forgeTargetCardId;
  final Map<String, List<String>> forgeTargetSessions;
  final int bonusForgeSlots;
  final int pendingDrafts; // Nombre de drafts de montée de niveau en attente
```

with:

```dart
  final PassiveData? activePassive; // Passif dynamique du héros
  final int pendingDrafts; // Nombre de drafts de montée de niveau en attente
```

Then replace:

```dart
    this.activePassive,
    this.forgeSlots = const [],
    this.forgeTargetCardId,
    this.forgeTargetSessions = const {},
    this.bonusForgeSlots = 0,
    this.pendingDrafts = 0,
```

with:

```dart
    this.activePassive,
    this.pendingDrafts = 0,
```

Then replace:

```dart
    PassiveData? activePassive,
    List<String>? forgeSlots,
    String? forgeTargetCardId,
    bool resetForgeTargetCardId = false,
    Map<String, List<String>>? forgeTargetSessions,
    bool resetForgeTargetSessions = false,
    int? bonusForgeSlots,
    int? pendingDrafts,
```

with:

```dart
    PassiveData? activePassive,
    int? pendingDrafts,
```

Then replace:

```dart
      activePassive: activePassive ?? this.activePassive,
      forgeSlots: forgeSlots ?? this.forgeSlots,
      forgeTargetCardId: resetForgeTargetCardId
          ? null
          : (forgeTargetCardId ?? this.forgeTargetCardId),
      forgeTargetSessions: resetForgeTargetSessions
          ? const {}
          : (forgeTargetSessions ?? this.forgeTargetSessions),
      bonusForgeSlots: bonusForgeSlots ?? this.bonusForgeSlots,
      pendingDrafts: pendingDrafts ?? this.pendingDrafts,
```

with:

```dart
      activePassive: activePassive ?? this.activePassive,
      pendingDrafts: pendingDrafts ?? this.pendingDrafts,
```

Then replace:

```dart
        'activePassiveNameEn': activePassive?.nameEn,
        'forgeSlots': forgeSlots,
        'forgeTargetCardId': forgeTargetCardId,
        'forgeTargetSessions': forgeTargetSessions,
        'bonusForgeSlots': bonusForgeSlots,
        'pendingDrafts': pendingDrafts,
```

with:

```dart
        'activePassiveNameEn': activePassive?.nameEn,
        'pendingDrafts': pendingDrafts,
```

Then replace:

```dart
    final missing = <MissingSaveItem>[];

    final (forgeSlots, forgeSlotsMissing) =
        ForgeUpgradeData.filterValidRefs(json['forgeSlots'] as List<dynamic>?);
    missing.addAll(forgeSlotsMissing);

    final rawSessions =
        json['forgeTargetSessions'] as Map<String, dynamic>? ?? const {};
    final forgeTargetSessions = <String, List<String>>{};
    rawSessions.forEach((cardId, refs) {
      final (upgrades, sessionMissing) =
          ForgeUpgradeData.filterValidRefs(refs as List<dynamic>?);
      forgeTargetSessions[cardId] = upgrades;
      missing.addAll(sessionMissing);
    });

    final activePassiveId = json['activePassiveId'] as String?;
```

with:

```dart
    final missing = <MissingSaveItem>[];

    final activePassiveId = json['activePassiveId'] as String?;
```

Then replace:

```dart
      activePassive: activePassive,
      forgeSlots: forgeSlots,
      forgeTargetCardId: json['forgeTargetCardId'] as String?,
      forgeTargetSessions: forgeTargetSessions,
      bonusForgeSlots: json['bonusForgeSlots'] as int? ?? 0,
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
```

with:

```dart
      activePassive: activePassive,
      pendingDrafts: json['pendingDrafts'] as int? ?? 0,
```

Then replace:

```dart
  late final MapProgressionManager _mapProgressionManager;
  late final GoldManager _goldManager;
```

with:

```dart
  late final MapProgressionManager _mapProgressionManager;
```

Then replace:

```dart
    _mapProgressionManager = MapProgressionManager(this, ref);
    _goldManager = GoldManager(this, ref);
```

with:

```dart
    _mapProgressionManager = MapProgressionManager(this, ref);
```

Then replace:

```dart
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }

  void setForgeSession(String cardId, List<String> slots) {
    final updated = Map<String, List<String>>.from(state.forgeTargetSessions);
    updated[cardId] = slots;
    state = state.copyWith(
      forgeTargetSessions: updated,
      forgeTargetCardId: cardId,
      forgeSlots: slots,
    );
  }

  void clearForgeSession() {
    state = state.copyWith(
      resetForgeTargetCardId: true,
      forgeSlots: const [],
      resetForgeTargetSessions: true,
    );
  }

  bool buyBonusForgeSlot() {
    return _goldManager.buyBonusForgeSlot();
  }
}
```

with:

```dart
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }
}
```

Run: `git rm lib/game/controllers/run/gold_manager.dart` — sa seule méthode était `buyBonusForgeSlot` ; Task 4 recrée le fichier pour `sharpenRune` (A16).

In `lib/ui/widgets/debug/tabs/debug_run_tab.dart`, delete the field `:59-66`:

```dart
        DebugNumberField(
          label: 'Slots de forge bonus',
          value: run.bonusForgeSlots,
          onSubmitted: (v) => DebugActions.updateRun(
            ref.read,
            (s) => s.copyWith(bonusForgeSlots: v),
          ),
        ),
```

- [ ] **Step 11: L'en-tête de l'infobulle Flame**

In `lib/game/components/card_component.dart`, replace:

```dart
      desc += '\n\n${activeLocale == 'fr' ? '=== AMÉLIORATIONS DE LA FORGE ===' : '=== FORGE UPGRADES ==='}';
```

with:

```dart
      // Le même dans les deux langues, en ligne : la couche Flame, hors de la
      // règle ARB de `lib/ui/` (spec P-43 E2, §5.7).
      desc += '\n\n=== RUNES ===';
```

- [ ] **Step 12: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_rune_rules_test.dart` — Expected: `+20: All tests passed!`
Run: `flutter test test/unit/forge_upgrade_data_test.dart` — Expected: `+35: All tests passed!`
Run: `flutter test test/widget/forge_upgrade_dialog_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/widget/deck_screen_test.dart` — Expected: `+10: All tests passed!`
Run: `flutter test test/unit/run_controller_test.dart` — Expected: `+8: All tests passed!`
Run: `flutter test test/unit/run_state_persistence_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/unit/deck_controller_test.dart test/unit/decoupled_forge_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/rest_screen_test.dart test/widget/debug_drawer_test.dart test/unit/save_service_test.dart` — Expected: `All tests passed!`

- [ ] **Step 13: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1404: All tests passed!` (1398 + 6 : `drawRunes` +5, `nameAt` +1, l'écran de deck +4, le dialogue réécrit 3 pour 4 ; la session −2 dans `run_controller_test`, −1 dans `run_state_persistence_test`).
Run: `git grep -n -e forgeSlots -e bonusForgeSlots -e forgeTargetCardId -e forgeTargetSessions -e setForgeSession -e clearForgeSession -e buyBonusForgeSlot -e ForgeBuySlotButton -e rerollCost -e resetForgeTarget -- lib test`
Expected: aucune sortie (spec §4.11).
Run: `git grep -n -w ForgeSlot -- lib test`
Expected: aucune sortie.

- [ ] **Step 14: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`. Les deux suppressions (`git rm`) sont déjà indexées.

```bash
git add lib/game/services/forge_rune_rules.dart lib/models/data/forge_upgrade_data.dart lib/game/controllers/deck_controller.dart lib/ui/widgets/forge_upgrade_dialog.dart lib/ui/widgets/forge/forge_slot_row.dart lib/ui/screens/deck_screen.dart lib/ui/screens/rest_card_selection_screen.dart lib/ui/screens/rest_screen.dart lib/game/controllers/run_controller.dart lib/ui/widgets/debug/tabs/debug_run_tab.dart lib/game/components/card_component.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/unit/forge_rune_rules_test.dart test/unit/forge_upgrade_data_test.dart test/unit/deck_controller_test.dart test/widget/forge_upgrade_dialog_test.dart test/widget/deck_screen_test.dart test/unit/run_controller_test.dart test/unit/run_state_persistence_test.dart
git commit -F- <<'EOF'
feat(fusion): chaque fusion offre une rune parmi trois

La fusion rend la carte qu elle cree ; l ecran de deck tire sur elle
trois runes eligibles au plus, ponderees, sans remise, au rang atteint,
et le dialogue reduit au choix pose la rune au niveau 1. Sans rune
eligible, la fusion le dit. La session de forge, les relances et les
fentes achetees disparaissent, avec GoldManager et la ligne de debug.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Le feu affûte une rune — `sharpenRune`, le dialogue d'affûtage, le retour système qui résout le nœud

D4, D5, D14, D20, D63 (spec §4.7, A4, A16) : l'option « FORGER » du feu devient « AFFÛTER » — inactive, avec son motif, quand aucune rune du deck ne peut monter. La sélection grise et refuse une carte sans rune affûtable (`sharpenNothingOnCard`) et ouvre sur une autre le dialogue d'affûtage : une ligne par rune portée, son niveau et le suivant, le gain marginal, « Affûter — `coût` or », inactif au plafond (« Niveau maximal ») ou faute d'or. L'opération vit dans `GoldManager.sharpenRune` — payer et écrire, ou rien —, ses formules dans `ForgeRuneRules`. Affûter ferme le dialogue sur la rune, la sélection sur la carte et la rune, et le feu passe à « Continuer » : une seule rune, un seul niveau par visite. Le retour système, une action faite, résout le nœud par le chemin de « Continuer » ; avant toute action, il reste bloqué (A4, mécanisme). La forge du feu et ses textes disparaissent ; `forgeNoEligibleRune` ne reste lu que par l'écran de deck. La prose du repos suit (§5.5).

Changements de jeu de la tâche, voulus (spec §11) : le feu de camp affûte — une rune d'une carte gagne un niveau pour 50 or × son niveau, à la place du repos ou de l'oubli ; la forge du feu disparaît ; **une correction** : quitter le feu par le retour après avoir agi termine la visite, comme « Continuer » — plus de second repos, de second oubli ni de second affûtage par un aller-retour ; les cartes de classe ne reçoivent plus de rune (D7 : le feu était leur seule source).

**Files:**
- Modify: `lib/game/services/forge_rune_rules.dart` (après `drawRunes`, Task 3)
- Create: `lib/game/controllers/run/gold_manager.dart`
- Modify: `lib/game/controllers/run_controller.dart` (l'import, le champ, `build`, `sharpenRune`, tels que Task 3 les a laissés)
- Modify: `lib/ui/widgets/forge/forge_slot_row.dart` (`detail`)
- Create: `lib/ui/widgets/forge/sharpen_rune_dialog.dart`
- Modify (réécrit en entier): `lib/ui/screens/rest_card_selection_screen.dart`, `lib/ui/screens/rest_screen.dart`
- Modify: `lib/l10n/app_en.arb:445-446`, `:456-462`, `:469-471` ; `lib/l10n/app_fr.arb:187-188`, `:193`, `:195-197` ; régénérés par `flutter gen-l10n` : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/tutorial/tutorial_data.dart:78-79`, `:92-93` ; `lib/tutorial/widgets/tutorial_node_types_widget.dart:63-64`
- Test: `test/unit/forge_rune_rules_test.dart` (après le groupe `drawRunes`)
- Test: `test/unit/run_controller_test.dart:7-8`, en fin de fichier (groupe neuf)
- Test: `test/widget/sharpen_rune_dialog_test.dart` *(nouveau)*
- Test: `test/widget/rest_card_selection_screen_test.dart`, `test/widget/rest_screen_test.dart` (réécrits en entier)

**Interfaces:**
- Consumes: `ForgeSlotRow` (Task 3) ; `ForgeCardPreview` (Task 2) ; `ForgeUpgradeData.boundLevel`, `levelsOf`, `parseRef` (E1) ; `DeckNotifier.setForgeUpgrades(String uniqueId, List<String> upgrades)` (`deck_controller.dart:357-366`, inchangé) ; `InventoryController.spendGold(int amount) → bool`.
- Produces:
  - `ForgeRuneRules.sharpenBaseCost` (`50`), `static int sharpenCost(int level)`, `static bool canSharpen(ForgeUpgradeData rune, int level)`, `static bool hasSharpenableRune(CardInstance card, Iterable<ForgeUpgradeData> catalog)`, `static List<String> replaceRune(List<String> refs, String runeId, String replacement)`.
  - `GoldManager(Ref ref)` avec `bool sharpenRune(String cardId, String runeId)` ; `bool RunController.sharpenRune(String cardId, String runeId)`.
  - `SharpenRuneDialog({Key? key, required CardInstance card})` — se ferme sur l'id de la rune affûtée, `null` sur Annuler.
  - `RestCardSelectionScreen({Key? key, required String title, required String subtitle, required bool isSharpen})` — se ferme sur `(CardInstance, String)` à l'affûtage, sur la `CardInstance` à l'oubli.
  - `ForgeSlotRow.detail` (`String?`).
  - ARB : `restCampSharpen`, `restCampSharpenDesc`, `restCampSharpenNone`, `restCampSharpenTitle`, `restCampSharpenSubtitle`, `restCampSnackbarSharpen(String runeName, int level, String cardName)`, `sharpenNothingOnCard`, `sharpenAction(int cost)`, `sharpenLevel(int from, int to)`, `runeMaxLevel` ; `restCampForge`, `restCampForgeDesc`, `restCampForgeTitle`, `restCampForgeSubtitle`, `restCampSnackbarForge` supprimées.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_rune_rules_test.dart`, replace the end of the file (the last case of the `drawRunes` group, Task 3):

```dart
    test('des runes de poids nul se tirent encore', () {
      final catalog = [_rune('a', weight: 0), _rune('b', weight: 0)];
      expect(
        ForgeRuneRules.drawRunes(card, catalog, Random(3), count: 3).toSet(),
        {'a', 'b'},
      );
    });
  });
}
```

with:

```dart
    test('des runes de poids nul se tirent encore', () {
      final catalog = [_rune('a', weight: 0), _rune('b', weight: 0)];
      expect(
        ForgeRuneRules.drawRunes(card, catalog, Random(3), count: 3).toSet(),
        {'a', 'b'},
      );
    });
  });

  // L'affutage (spec P-43 E2, §4.7).
  group('l affutage', () {
    test('sharpenCost : 50 or par niveau porte (D20, D63)', () {
      expect(
        [for (var level = 1; level <= 4; level++) ForgeRuneRules.sharpenCost(level)],
        [50, 100, 150, 200],
      );
    });

    test('canSharpen : jusqu au plafond, sans fin sans plafond', () {
      expect(ForgeRuneRules.canSharpen(_rune('sharp'), 9), isTrue);
      expect(ForgeRuneRules.canSharpen(_rune('capped', maxLevel: 2), 1), isTrue);
      expect(
          ForgeRuneRules.canSharpen(_rune('capped', maxLevel: 2), 2), isFalse);
      expect(ForgeRuneRules.canSharpen(_rune('eco', maxLevel: 1), 1), isFalse);
    });

    test('hasSharpenableRune : une rune portee sous son plafond, et du '
        'catalogue', () {
      final catalog = [_rune('sharp'), _rune('eco', maxLevel: 1)];
      expect(ForgeRuneRules.hasSharpenableRune(_cardWith([]), catalog), isFalse);
      expect(ForgeRuneRules.hasSharpenableRune(_cardWith(['eco:1']), catalog),
          isFalse);
      expect(
          ForgeRuneRules.hasSharpenableRune(_cardWith(['absente:1']), catalog),
          isFalse);
      expect(
        ForgeRuneRules.hasSharpenableRune(
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });
  });
}
```

In `test/unit/run_controller_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/relic_data.dart';

void main() {
```

with:

```dart
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';

void main() {
```

Then replace the end of the file:

```dart
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
    });
  });
}
```

with:

```dart
      expect(runController.state.heroStats.armure, 3);
      expect(runController.state.heroStats.currentPv, 90);
    });
  });

  // Payer et ecrire, ou rien (spec P-43 E2, §4.7, A16).
  group('RunController.sharpenRune', () {
    late ProviderContainer container;
    late RunController run;

    setUp(() {
      shippedRuneRegistry(const ['burning', 'eco', 'sharp']);
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
    });

    tearDown(() => container.dispose());

    /// Une Frappe rare portant [runes], seule carte du deck, et [gold] or.
    CardInstance seed(List<String> runes, {required int gold}) {
      container.read(inventoryProvider.notifier).reset(initialGold: gold);
      final card = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: runes,
      );
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
      return card;
    }

    List<String> runesOf(CardInstance card) => container
        .read(deckProvider)
        .masterDeck
        .singleWhere((c) => c.uniqueId == card.uniqueId)
        .forgeUpgrades;

    // Review Focus 2 : l'or tout juste suffisant.
    test('depense 50 x n et ecrit id:n+1 a sa place', () {
      final card = seed(const ['burning:1', 'sharp:2', 'eco:1'], gold: 100);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isTrue);

      expect(container.read(inventoryProvider).gold, 0);
      expect(runesOf(card), ['burning:1', 'sharp:3', 'eco:1']);
    });

    test('refuse une rune a son plafond, sans rien toucher', () {
      final card = seed(const ['sharp:2', 'eco:1'], gold: 1000);

      expect(run.sharpenRune(card.uniqueId, 'eco'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:2', 'eco:1']);
    });

    test('refuse faute d or, sans rien toucher', () {
      final card = seed(const ['sharp:2'], gold: 99);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isFalse);

      expect(container.read(inventoryProvider).gold, 99);
      expect(runesOf(card), ['sharp:2']);
    });
  });
}
```

Create `test/widget/sharpen_rune_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/forge/sharpen_rune_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';

import '../unit/shipped_data.dart';

/// Une Frappe rare — 8 dégâts — portant [runes].
CardInstance _rareStrike(List<String> runes) => CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.rare,
      forgeUpgrades: runes,
    );

/// Ouvre le dialogue d'affûtage sur [card], posée dans le deck, avec [gold]
/// or, par `showDialog` au-dessus d'une page — comme la sélection du feu ;
/// [onClosed] reçoit ce sur quoi il se ferme.
Future<ProviderContainer> _openDialog(
  WidgetTester tester,
  CardInstance card, {
  required int gold,
  ValueChanged<String?>? onClosed,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  shippedRuneRegistry(const ['eco', 'sharp'], cards: [card.data]);
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(inventoryProvider.notifier).reset(initialGold: gold);
  container.read(deckProvider.notifier).addCardToMasterDeck(card);

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
              onPressed: () async {
                final sharpened = await showDialog<String>(
                  context: context,
                  builder: (_) => SharpenRuneDialog(card: card),
                );
                onClosed?.call(sharpened);
              },
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return container;
}

/// Le bouton de la ligne dont le libellé est [label].
GameButton _button(WidgetTester tester, String label) =>
    tester.widget<GameButton>(find.widgetWithText(GameButton, label));

/// Le dialogue d'affûtage (spec P-43 E2, A4, §4.7).
void main() {
  testWidgets('une ligne par rune portee ; Niveau 2 -> 3 et 100 or pour '
      'Tranchant 2', (tester) async {
    await _openDialog(tester, _rareStrike(const ['sharp:2', 'eco:1']),
        gold: 1000);

    expect(find.byType(ForgeSlotRow), findsNWidgets(2));
    expect(find.text('Niveau 2 → 3'), findsOneWidget);
    expect(_button(tester, 'Affûter — 100 or').onPressed, isNotNull);
  });

  testWidgets('une rune a son plafond : Niveau maximal, inactif, sans ligne '
      'de niveau', (tester) async {
    await _openDialog(tester, _rareStrike(const ['eco:1']), gold: 1000);

    expect(_button(tester, 'Niveau maximal').onPressed, isNull);
    expect(find.textContaining('Niveau 1 →'), findsNothing);
  });

  testWidgets('faute d or, Affuter est inactif', (tester) async {
    await _openDialog(tester, _rareStrike(const ['sharp:2']), gold: 99);

    expect(_button(tester, 'Affûter — 100 or').onPressed, isNull);
  });

  testWidgets('la description dit ce que le niveau de plus ajoute a cette '
      'carte', (tester) async {
    // 8 degats en rare : Tranchant 2 ajoute +2, Tranchant 3 +4 — le niveau
    // de plus ajoute +2 (spec P-43 E1, §5.1).
    await _openDialog(tester, _rareStrike(const ['sharp:2']), gold: 1000);

    expect(
      find.text('+2 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );
  });

  testWidgets('affuter monte la rune d un niveau et ferme le dialogue : '
      'aucun second affutage (D14)', (tester) async {
    String? closedOn;
    final container = await _openDialog(
      tester,
      _rareStrike(const ['sharp:2', 'eco:1']),
      gold: 1000,
      onClosed: (id) => closedOn = id,
    );

    await tester.tap(find.text('Affûter — 100 or'));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(closedOn, 'sharp');
    expect(container.read(inventoryProvider).gold, 900);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:3', 'eco:1']);
  });
}
```

Replace the whole of `test/widget/rest_card_selection_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/widgets/forge/sharpen_rune_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Monte la sélection de l'affûtage sur un deck d'une seule [card], avec les
/// huit runes livrées.
Future<ProviderContainer> _pumpSharpenSelection(
  WidgetTester tester,
  CardInstance card,
) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final registry = shippedRuneRegistry(shippedRuneIds(), cards: [card.data]);
  final container = ProviderContainer(
    overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
  );
  addTearDown(container.dispose);
  container.read(deckProvider.notifier).addCardToMasterDeck(card);

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
        home: const RestCardSelectionScreen(
          title: 'AFFÛTER UNE RUNE',
          subtitle: 'Choisissez une carte, puis la rune qui gagne un niveau.',
          isSharpen: true,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Une notification programme un minuteur de 3,5 s qu'aucun overlay ne
/// démonte ici : il doit expirer avant la fin du test.
Future<void> _settleNotifications(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpWidget(const SizedBox());
}

/// La sélection de l'affûtage (spec P-43 E2, A4, §4.7).
void main() {
  testWidgets('une carte sans rune est grisee et refusee, avec son motif',
      (tester) async {
    final card = CardInstance(
        data: shippedCard('strike_basic'), rarity: CardRarity.uncommon);
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune de cette carte ne peut gagner de niveau.');

    await _settleNotifications(tester);
  });

  testWidgets('une carte dont les runes sont a leur plafond est refusee de '
      'meme', (tester) async {
    // Une Concentration rare portant Veloce, plafonnee a 1.
    final card = CardInstance(
      data: shippedCard('concentration'),
      rarity: CardRarity.rare,
      forgeUpgrades: const ['quick:1'],
    );
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isTrue);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune de cette carte ne peut gagner de niveau.');

    await _settleNotifications(tester);
  });

  testWidgets('une carte portant une rune affutable ouvre le dialogue',
      (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['sharp:1'],
    );
    final container = await _pumpSharpenSelection(tester, card);

    expect(tester.widget<UiCard>(find.byType(UiCard)).isGrayedOut, isFalse);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(SharpenRuneDialog), findsOneWidget);
    expect(container.read(notificationProvider), isEmpty);

    await _settleNotifications(tester);
  });
}
```

Replace the whole of `test/widget/rest_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/screens/rest_card_selection_screen.dart';
import 'package:roguelike_card_game/ui/screens/rest_screen.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/models/card_instance.dart';

import '../unit/shipped_data.dart';

void main() {
  const mockHero = HeroData(
    id: 'paladin',
    nameEn: 'Paladin',
    nameFr: 'Paladin',
    descriptionEn: 'A holy knight',
    descriptionFr: 'Un saint chevalier',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
    luck: 0,
    mastery: 0,
  );

  const mockCard = CardData(
    id: 'strike',
    nameEn: 'Strike',
    nameFr: 'Frappe',
    descriptionEn: 'Deal 6 damage',
    descriptionFr: 'Inflige 6 dégâts',
    cost: 1,
    type: CardType.attack,
    category: CardCategory.global,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: [],
  );

  /// Une Frappe peu commune portant Tranchant 1 : la rune s'affûte pour
  /// 50 or, l'or d'une run neuve.
  CardInstance sharpStrike() => CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['sharp:1'],
      );

  /// Le registre des runes livrées, que le feu lit pour l'affûtage.
  GameDataRegistry shippedRegistry() => shippedRuneRegistry(
        shippedRuneIds(),
        cards: [shippedCard('strike_basic')],
      );

  /// Une run neuve, au premier nœud de sa carte, sur [registry] — un
  /// registre sans rune par défaut —, avec [deck] pour deck.
  ProviderContainer startRun(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) {
    // Rest option cards are wide; use a larger viewport so the column of
    // three options fits without a RenderFlex overflow.
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final data = registry ??
        GameDataRegistry(
          enemies: const [],
          heroes: const [mockHero],
          cards: const [mockCard],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
        );
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => data)],
    );
    addTearDown(container.dispose);

    final run = container.read(runProvider.notifier);
    run.startNewRun(mockHero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    for (final card in deck) {
      container.read(deckProvider.notifier).addCardToMasterDeck(card);
    }
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

  /// `RestScreen` en page d'accueil.
  Future<ProviderContainer> pumpRestScreen(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) async {
    final container = startRun(tester, registry: registry, deck: deck);
    await tester.pumpWidget(app(container, const RestScreen()));
    await tester.pumpAndSettle();
    return container;
  }

  /// `RestScreen` poussé sur une vraie pile, comme la carte du monde le
  /// pousse : le retour système a une page où revenir (le précédent de
  /// `map_screen_test.dart`).
  Future<ProviderContainer> pushRestScreen(
    WidgetTester tester, {
    GameDataRegistry? registry,
    List<CardInstance> deck = const [],
  }) async {
    final container = startRun(tester, registry: registry, deck: deck);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RestScreen()),
            ),
            child: const Text('Ouvrir le feu'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir le feu'));
    await tester.pumpAndSettle();
    return container;
  }

  // Notifications schedule a 3.5s auto-dismiss Timer via `showNotification`.
  // RestScreen never mounts a GameNotificationOverlay (that timer is only
  // cancelled by that widget's dispose), so tests that trigger a
  // notification must let the timer fire before the widget tree is torn
  // down, otherwise flutter_test fails with "Timer is still pending".
  Future<void> settlePendingNotificationTimers(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
  }

  /// Affûte Tranchant 1 de la seule carte du deck, par l'écran : l'option,
  /// la carte, puis le bouton du dialogue.
  Future<void> sharpenTheOnlyCard(WidgetTester tester) async {
    await tester.tap(find.text('AFFÛTER'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Affûter — 50 or'));
    await tester.pumpAndSettle();
  }

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

  testWidgets('RestScreen renders the three action buttons', (
    WidgetTester tester,
  ) async {
    await pumpRestScreen(tester);

    expect(find.text('SE REPOSER'), findsOneWidget);
    expect(find.text('AFFÛTER'), findsOneWidget);
    expect(find.text('OUBLIER'), findsOneWidget);
    expect(find.text('FORGER'), findsNothing);
  });

  testWidgets('AFFUTER est inactive, avec son motif, quand aucune rune du '
      'deck ne peut monter', (WidgetTester tester) async {
    await pumpRestScreen(tester, deck: [CardInstance(data: mockCard)]);

    expect(find.text('Aucune rune de votre deck ne peut gagner de niveau.'),
        findsOneWidget);

    await tester.tap(find.text('AFFÛTER'));
    await tester.pumpAndSettle();

    expect(find.byType(RestCardSelectionScreen), findsNothing);
    expect(find.text('SE REPOSER'), findsOneWidget);
  });

  testWidgets(
    'Tapping Heal restores 30% of max HP and shows a success notification',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final maxPv = container.read(runProvider).heroStats.maxPv;
      final healAmount = (maxPv * 0.3).round();

      // Damage the hero first (well below max) so we can observe an
      // uncapped heal, then verify the notification and state update.
      container.read(runProvider.notifier).takeDamage(healAmount + 5);
      final pvBeforeHeal = container.read(runProvider).heroStats.currentPv;

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();

      final pvAfterHeal = container.read(runProvider).heroStats.currentPv;
      // The heal amount (5 below max) should NOT get capped in this case.
      expect(pvAfterHeal, pvBeforeHeal + healAmount);

      final notifications = container.read(notificationProvider);
      expect(notifications, isNotEmpty);
      expect(notifications.last.type, NotificationType.success);
      expect(notifications.last.message, contains('$healAmount'));

      await settlePendingNotificationTimers(tester);
    },
  );

  testWidgets(
    'Tapping Heal near-full HP caps the restored amount at max HP',
    (WidgetTester tester) async {
      final container = await pumpRestScreen(tester);

      final maxPv = container.read(runProvider).heroStats.maxPv;
      container.read(runProvider.notifier).takeDamage(1);

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();

      expect(container.read(runProvider).heroStats.currentPv, maxPv);

      await settlePendingNotificationTimers(tester);
    },
  );

  testWidgets('Affuter monte une rune d un niveau, notifie, et clot les '
      'options (D14)', (WidgetTester tester) async {
    final container = await pumpRestScreen(
      tester,
      registry: shippedRegistry(),
      deck: [sharpStrike()],
    );

    await sharpenTheOnlyCard(tester);

    expect(find.byType(RestScreen), findsOneWidget);
    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['sharp:2']);
    expect(container.read(inventoryProvider).gold, 0);
    expect(container.read(notificationProvider).last.message,
        'Tranchant passe au niveau 2 sur Frappe !');
    // Une seule rune, un seul niveau par visite : les trois options ont
    // disparu, seul « Continuer » reste.
    expect(find.text('SE REPOSER'), findsNothing);
    expect(find.text('AFFÛTER'), findsNothing);
    expect(find.text('OUBLIER'), findsNothing);
    expect(find.text('CONTINUER LA ROUTE'), findsOneWidget);

    await settlePendingNotificationTimers(tester);
  });

  testWidgets(
    'Remove flow removes the selected card from the master deck',
    (WidgetTester tester) async {
      final cardToRemove = CardInstance(data: mockCard);
      final container = await pumpRestScreen(tester, deck: [cardToRemove]);

      await tester.tap(find.text('OUBLIER'));
      await tester.pumpAndSettle();

      // RestCardSelectionScreen renders the deck's single card as a UiCard;
      // tapping it triggers the real (non-sharpen) removal path, which pops
      // the navigator with the CardInstance directly.
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();

      expect(
        container
            .read(deckProvider)
            .masterDeck
            .any((c) => c.uniqueId == cardToRemove.uniqueId),
        isFalse,
      );

      final notifications = container.read(notificationProvider);
      expect(notifications, isNotEmpty);
      expect(notifications.last.type, NotificationType.error);
      expect(notifications.last.message, contains('Frappe'));

      await settlePendingNotificationTimers(tester);
    },
  );

  // Spec P-43 E2, A4 : apres une action, toute sortie de l'ecran resout le
  // noeud, que la carte du monde ne laisse plus rejouer.
  group('le retour systeme', () {
    testWidgets('apres un repos, il resout le noeud et ferme l ecran, une '
        'seule fois', (WidgetTester tester) async {
      final container = await pushRestScreen(tester);

      await tester.tap(find.text('SE REPOSER'));
      await tester.pumpAndSettle();
      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(find.text('Ouvrir le feu'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      // `completeCurrentNode` pousse le point de sauvegarde : un cran, donc
      // un seul `_leave`.
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('apres un affutage, de meme', (WidgetTester tester) async {
      final container = await pushRestScreen(
        tester,
        registry: shippedRegistry(),
        deck: [sharpStrike()],
      );

      await sharpenTheOnlyCard(tester);
      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('apres un oubli, de meme', (WidgetTester tester) async {
      final container =
          await pushRestScreen(tester, deck: [CardInstance(data: mockCard)]);

      await tester.tap(find.text('OUBLIER'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(UiCard));
      await tester.pumpAndSettle();
      expect(container.read(deckProvider).masterDeck, isEmpty);

      await pressBack(tester);

      expect(find.byType(RestScreen), findsNothing);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settlePendingNotificationTimers(tester);
    });

    testWidgets('avant toute action, il ne fait rien', (
      WidgetTester tester,
    ) async {
      final container = await pushRestScreen(tester);

      await pressBack(tester);

      expect(find.byType(RestScreen), findsOneWidget);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/run_controller_test.dart test/widget/sharpen_rune_dialog_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/rest_screen_test.dart`
Expected: FAIL à la compilation — `The method 'sharpenCost' isn't defined`, `The method 'sharpenRune' isn't defined for the type 'RunController'`, `Target of URI doesn't exist: '…/sharpen_rune_dialog.dart'`, `No named parameter with the name 'isSharpen'`.

- [ ] **Step 3: Les formules de l'affûtage**

In `lib/game/services/forge_rune_rules.dart`, replace the end of the file (the end of `drawRunes`, Task 3):

```dart
      drawn.add(pool.removeAt(index).id);
    }
    return drawn;
  }
}
```

with:

```dart
      drawn.add(pool.removeAt(index).id);
    }
    return drawn;
  }

  /// `b`, le coût d'un niveau d'affûtage par niveau porté (D63 ; spec P-43
  /// E2, §4.7).
  static const sharpenBaseCost = 50;

  /// Le coût pour monter d'un niveau une rune portée au niveau [level] : il
  /// croît avec le niveau de la rune, pas avec le rang de la carte (D20).
  static int sharpenCost(int level) => sharpenBaseCost * level;

  /// La rune [rune], portée au niveau [level], peut-elle monter d'un niveau ?
  /// Son `maxLevel` le dit, par la borne (D72).
  static bool canSharpen(ForgeUpgradeData rune, int level) =>
      rune.boundLevel(1, carried: level) >= 1;

  /// [card] porte-t-elle une rune que l'affûtage peut monter ? Une rune
  /// absente du [catalog] ne se monte pas. Lu par l'option du feu et par sa
  /// sélection (spec P-43 E2, A4).
  static bool hasSharpenableRune(
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
  ) =>
      ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries.any((entry) {
        final rune = catalog.where((r) => r.id == entry.key).firstOrNull;
        return rune != null && canSharpen(rune, entry.value);
      });

  /// [refs] où la référence de la rune [runeId] cède la place à
  /// [replacement], à sa place (spec P-43 E2, §4.7) : l'affûtage la réécrit
  /// `id:n+1`. Une référence mal formée reste telle quelle.
  static List<String> replaceRune(
    List<String> refs,
    String runeId,
    String replacement,
  ) =>
      [
        for (final ref in refs)
          ForgeUpgradeData.parseRef(ref)?.$1 == runeId ? replacement : ref,
      ];
}
```

- [ ] **Step 4: L'opération payante — `GoldManager.sharpenRune`**

Create `lib/game/controllers/run/gold_manager.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../../services/forge_rune_rules.dart';
import '../deck_controller.dart';
import '../inventory_controller.dart';

/// Les services de forge vendus contre de l'or (spec P-43 E2, A16) : la règle
/// « payer et écrire, ou rien » vit ici ; les formules, dans
/// `ForgeRuneRules`.
class GoldManager {
  final Ref ref;

  GoldManager(this.ref);

  /// Affûte la rune [runeId] de la carte [cardId] du deck : un niveau de plus
  /// (D4), contre `ForgeRuneRules.sharpenCost(niveau)` or (D20). Refuse —
  /// sans rien toucher — si la carte ne porte pas la rune, si la rune est
  /// absente du registre ou à son plafond, ou si l'or manque. Rend vrai si
  /// l'affûtage a eu lieu.
  bool sharpenRune(String cardId, String runeId) {
    final card = ref
        .read(deckProvider)
        .masterDeck
        .where((c) => c.uniqueId == cardId)
        .firstOrNull;
    final level = card == null
        ? null
        : ForgeUpgradeData.levelsOf(card.forgeUpgrades)[runeId];
    final rune = ForgeUpgradeData.getById(runeId);
    if (card == null ||
        level == null ||
        rune == null ||
        !ForgeRuneRules.canSharpen(rune, level)) {
      return false;
    }
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
}
```

In `lib/game/controllers/run_controller.dart`, replace:

```dart
import 'run/map_progression_manager.dart';
```

with:

```dart
import 'run/map_progression_manager.dart';
import 'run/gold_manager.dart';
```

Then replace:

```dart
  late final MapProgressionManager _mapProgressionManager;
```

with:

```dart
  late final MapProgressionManager _mapProgressionManager;
  late final GoldManager _goldManager;
```

Then replace:

```dart
    _mapProgressionManager = MapProgressionManager(this, ref);
```

with:

```dart
    _mapProgressionManager = MapProgressionManager(this, ref);
    _goldManager = GoldManager(ref);
```

Then replace the end of the class, as Task 3 left it:

```dart
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }
}
```

with:

```dart
  void applyLifestealBuff({required int value, required int duration}) {
    _playerStatsManager.applyLifestealBuff(value: value, duration: duration);
  }

  /// Affûte une rune d'une carte du deck, contre de l'or (spec P-43 E2,
  /// §4.7) ; voir `GoldManager.sharpenRune`.
  bool sharpenRune(String cardId, String runeId) =>
      _goldManager.sharpenRune(cardId, runeId);
}
```

- [ ] **Step 5: Les chaînes de l'affûtage**

In `lib/l10n/app_en.arb`, replace:

```json
  "restCampForge": "FORGE",
  "restCampForgeDesc": "Permanently upgrade a card in your deck.",
```

with:

```json
  "restCampSharpen": "SHARPEN",
  "restCampSharpenDesc": "One rune on one of your cards gains a level, for gold.",
  "restCampSharpenNone": "No rune in your deck can gain a level.",
```

Then replace:

```json
  "restCampSnackbarForge": "{cardName} was upgraded to Level {level}!",
  "@restCampSnackbarForge": {
    "placeholders": {
      "cardName": { "type": "String" },
      "level": { "type": "int" }
    }
  },
```

with:

```json
  "restCampSnackbarSharpen": "{runeName} reaches level {level} on {cardName}!",
  "@restCampSnackbarSharpen": {
    "placeholders": {
      "runeName": { "type": "String" },
      "level": { "type": "int" },
      "cardName": { "type": "String" }
    }
  },
```

Then replace:

```json
  "restCampForgeTitle": "FORGE A CARD",
  "restCampForgeSubtitle": "Choose a card to permanently upgrade.",
  "forgeNoEligibleRune": "No rune can be added to this card.",
```

with:

```json
  "restCampSharpenTitle": "SHARPEN A RUNE",
  "restCampSharpenSubtitle": "Choose a card, then the rune that gains a level.",
  "forgeNoEligibleRune": "No rune can be added to this card.",
  "sharpenNothingOnCard": "No rune on this card can gain a level.",
  "sharpenAction": "Sharpen — {cost} gold",
  "@sharpenAction": {
    "placeholders": {
      "cost": { "type": "int" }
    }
  },
  "sharpenLevel": "Level {from} → {to}",
  "@sharpenLevel": {
    "placeholders": {
      "from": { "type": "int" },
      "to": { "type": "int" }
    }
  },
  "runeMaxLevel": "Max level",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "restCampForge": "FORGER",
  "restCampForgeDesc": "Améliore définitivement une carte de votre deck.",
```

with:

```json
  "restCampSharpen": "AFFÛTER",
  "restCampSharpenDesc": "Une rune d'une de vos cartes gagne un niveau, contre de l'or.",
  "restCampSharpenNone": "Aucune rune de votre deck ne peut gagner de niveau.",
```

Then replace:

```json
  "restCampSnackbarForge": "{cardName} a été améliorée au Niveau {level} !",
```

with:

```json
  "restCampSnackbarSharpen": "{runeName} passe au niveau {level} sur {cardName} !",
```

Then replace:

```json
  "restCampForgeTitle": "FORGER UNE CARTE",
  "restCampForgeSubtitle": "Choisissez une carte à améliorer définitivement.",
  "forgeNoEligibleRune": "Aucune rune ne peut être ajoutée à cette carte.",
```

with:

```json
  "restCampSharpenTitle": "AFFÛTER UNE RUNE",
  "restCampSharpenSubtitle": "Choisissez une carte, puis la rune qui gagne un niveau.",
  "forgeNoEligibleRune": "Aucune rune ne peut être ajoutée à cette carte.",
  "sharpenNothingOnCard": "Aucune rune de cette carte ne peut gagner de niveau.",
  "sharpenAction": "Affûter — {cost} or",
  "sharpenLevel": "Niveau {from} → {to}",
  "runeMaxLevel": "Niveau maximal",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `git status --short lib/l10n` montre les deux ARB et les trois `app_localizations*.dart` modifiés. `dart analyze` signale à ce point `restCampForge*` non définis dans `rest_screen.dart` : les étapes 8 et 9 les remplacent.

- [ ] **Step 6: La ligne de rune gagne sa ligne de détail**

In `lib/ui/widgets/forge/forge_slot_row.dart`, replace:

```dart
  final ForgeUpgradeData rune;
  final String title;
  final String description;
```

with:

```dart
  final ForgeUpgradeData rune;
  final String title;

  /// Une ligne sous le titre — le niveau et le suivant, à l'affûtage ;
  /// `null` : aucune.
  final String? detail;
  final String description;
```

Then replace:

```dart
    required this.title,
    required this.description,
```

with:

```dart
    required this.title,
    this.detail,
    required this.description,
```

Then replace:

```dart
    final color = _getUpgradeColorFromString(rune.color);
    final icon = _getUpgradeIconFromString(rune.icon);
```

with:

```dart
    final color = _getUpgradeColorFromString(rune.color);
    final icon = _getUpgradeIconFromString(rune.icon);
    final detail = this.detail;
```

Then replace:

```dart
                const SizedBox(height: 4),
                Text(
                  description,
```

with:

```dart
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  description,
```

- [ ] **Step 7: Le dialogue d'affûtage**

Create `lib/ui/widgets/forge/sharpen_rune_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/inventory_controller.dart';
import '../../../game/controllers/run_controller.dart';
import '../../../game/services/forge_rune_rules.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../game_button.dart';
import '../game_dialog.dart';
import 'forge_card_preview.dart';
import 'forge_slot_row.dart';

/// Le dialogue d'affûtage (spec P-43 E2, A4, §4.7) : la carte, puis une ligne
/// par rune qu'elle porte — son nom, son niveau et le suivant, ce que le
/// niveau de plus ajoute à cette carte, et « Affûter — coût or », inactif au
/// plafond ou faute d'or. Affûter monte la rune par
/// `RunController.sharpenRune`, puis ferme le dialogue sur son id : un seul
/// affûtage par visite (D14). Annuler, ou la croix, le ferme sur `null` et
/// ramène à la sélection.
class SharpenRuneDialog extends ConsumerWidget {
  final CardInstance card;

  const SharpenRuneDialog({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final gold = ref.watch(inventoryProvider).gold;

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

    return GameDialog(
      glowColor: Colors.amberAccent,
      maxWidth: 640,
      title: Text(card.data.getName(locale)),
      content: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ForgeCardPreview(card: card, locale: locale, l10n: l10n),
            ),
            const SizedBox(height: 16),
            for (final MapEntry(key: id, value: level)
                in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
              if (ForgeUpgradeData.getById(id) case final rune?)
                row(rune, level),
          ],
        ),
      ),
      actions: [
        GameButton(
          text: l10n.cancel,
          baseColor: Colors.white70,
          onPressed: () => Navigator.of(context).pop(),
          height: 38,
          fontSize: 14,
        ),
      ],
    );
  }
}
```

- [ ] **Step 8: La sélection du feu en mode affûtage**

Replace the whole of `lib/ui/screens/rest_card_selection_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/ui_card.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/forge/sharpen_rune_dialog.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/page_header.dart';

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

  void _onCardTapped(
    BuildContext context,
    CardInstance card, {
    required bool sharpenable,
  }) async {
    if (!isSharpen) {
      Navigator.of(context).pop(card);
      return;
    }
    if (!sharpenable) {
      context.showNotification(
        AppLocalizations.of(context)!.sharpenNothingOnCard,
        type: NotificationType.error,
      );
      return;
    }

    final runeId = await showDialog<String>(
      context: context,
      builder: (context) => SharpenRuneDialog(card: card),
    );
    if (runeId != null && context.mounted) {
      Navigator.of(context).pop((card, runeId));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final deck = ref.watch(deckProvider).masterDeck;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];

    final appBar = PageHeader(
      title: title,
      showBackButton: true,
      isParchment: false,
      onBackPressed: () => Navigator.of(context).pop(null),
    );

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: appBar,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isMobile ? 12 : 15,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // CARD GRID
            Expanded(
              child: deck.isEmpty
                  ? Center(
                      child: Text(
                        locale == 'fr' ? 'Votre deck est vide' : 'Your deck is empty',
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile ? 140 : 180,
                        childAspectRatio: 70 / 110,
                        crossAxisSpacing: isMobile ? 8 : 16,
                        mainAxisSpacing: isMobile ? 8 : 16,
                      ),
                      itemCount: deck.length,
                      // La sélection se ferme par le `context` de l'écran,
                      // non par celui d'une case de la grille.
                      itemBuilder: (_, index) {
                        final card = deck[index];
                        final sharpenable = isSharpen &&
                            ForgeRuneRules.hasSharpenableRune(card, catalog);
                        return UiCard.fromInstance(
                          card: card,
                          locale: locale,
                          l10n: l10n,
                          isGrayedOut: isSharpen && !sharpenable,
                          onTap: () => _onCardTapped(
                            context,
                            card,
                            sharpenable: sharpenable,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 9: Le feu — AFFÛTER, et le retour système qui résout le nœud**

Replace the whole of `lib/ui/screens/rest_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import 'package:roguelike_card_game/ui/widgets/game_button.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/notification_overlay.dart';
import 'rest_card_selection_screen.dart';
import '../widgets/screen_scaffold.dart';

class RestScreen extends ConsumerStatefulWidget {
  const RestScreen({super.key});

  @override
  ConsumerState<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends ConsumerState<RestScreen> {
  /// Une action par visite (D14 ; spec P-43 E2, A4) : le repos, l'affûtage
  /// ou l'oubli fait, les trois options disparaissent. Un état de déroulé de
  /// l'écran, qui ne lui survit pas : toute sortie après une action résout
  /// le nœud (`_leave`).
  bool _actionTaken = false;

  void _heal() {
    final l10n = AppLocalizations.of(context)!;
    final runController = ref.read(runProvider.notifier);
    final maxHp = runController.currentState.heroStats.maxPv;
    final healAmount = (maxHp * 0.3).round();

    runController.heal(healAmount);

    setState(() {
      _actionTaken = true;
    });

    context.showNotification(
      l10n.restCampSnackbarHeal(healAmount),
      type: NotificationType.success,
    );
  }

  void _sharpenRune() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final result = await Navigator.of(context).push<(CardInstance, String)>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampSharpenTitle,
          subtitle: l10n.restCampSharpenSubtitle,
          isSharpen: true,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final (card, runeId) = result;
    setState(() {
      _actionTaken = true;
    });
    // `card` est la carte d'avant l'affûtage : la rune y porte un niveau de
    // moins que ce que `sharpenRune` vient d'écrire.
    final level =
        (ForgeUpgradeData.levelsOf(card.forgeUpgrades)[runeId] ?? 0) + 1;
    context.showNotification(
      l10n.restCampSnackbarSharpen(
        ForgeUpgradeData.getById(runeId)?.getName(locale) ?? runeId,
        level,
        card.data.getName(locale),
      ),
      type: NotificationType.success,
    );
  }

  void _removeCard() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final selectedCard = await Navigator.of(context).push<CardInstance>(
      MaterialPageRoute(
        builder: (context) => RestCardSelectionScreen(
          title: l10n.restCampRemoveTitle,
          subtitle: l10n.restCampRemoveSubtitle,
          isSharpen: false,
        ),
      ),
    );

    if (selectedCard != null) {
      ref.read(deckProvider.notifier).removeCardById(selectedCard.uniqueId);

      setState(() {
        _actionTaken = true;
      });

      if (mounted) {
        final cardName = selectedCard.data.getName(locale);
        context.showNotification(
          l10n.restCampSnackbarRemove(cardName),
          type: NotificationType.error,
        );
      }
    }
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final runState = ref.watch(runProvider);
    final heroStats = runState.heroStats;
    // L'option d'affûtage se montre inactive, avec son motif, quand aucune
    // rune du deck ne peut monter (spec P-43 E2, A4).
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final canSharpen = ref
        .watch(deckProvider)
        .masterDeck
        .any((card) => ForgeRuneRules.hasSharpenableRune(card, catalog));

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      // Le retour système n'est jamais un pop direct (spec P-43 E2, A4) :
      // avant toute action il reste bloqué ; après, il résout le nœud par le
      // chemin de « Continuer ». Le pop de `_leave` repasse ici avec `didPop`
      // vrai : rien à refaire.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _actionTaken) _leave();
      },
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.nightlight_round,
              color: Colors.orangeAccent,
              size: 80,
            ),
            AppSpacing.heightMd,
            Text(
              l10n.restCampTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            AppSpacing.heightSm,
            Text(
              l10n.restCampSubtitle,
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            AppSpacing.heightXxl,
            if (!_actionTaken) ...[
              _RestOption(
                icon: Icons.favorite,
                title: l10n.restCampRest,
                description: l10n.restCampRestDesc(
                  (heroStats.maxPv * 0.3).round(),
                ),
                onTap: _heal,
                color: Colors.greenAccent,
              ),
              AppSpacing.heightMd,
              _RestOption(
                icon: Icons.auto_fix_high,
                title: l10n.restCampSharpen,
                description: canSharpen
                    ? l10n.restCampSharpenDesc
                    : l10n.restCampSharpenNone,
                onTap: canSharpen ? _sharpenRune : null,
                color: Colors.amberAccent,
              ),
              AppSpacing.heightMd,
              _RestOption(
                icon: Icons.delete_sweep,
                title: l10n.restCampRemove,
                description: l10n.restCampRemoveDesc,
                onTap: _removeCard,
                color: Colors.redAccent,
              ),
            ] else ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              AppSpacing.heightLg,
              GameButton(
                text: l10n.restCampProceed,
                onPressed: _leave,
                baseColor: Colors.white70,
                height: 54,
                width: 220,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RestOption extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  /// `null` : l'option est inactive — grisée, sans effet au toucher ; sa
  /// description dit pourquoi.
  final VoidCallback? onTap;
  final Color color;

  const _RestOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    required this.color,
  });

  @override
  State<_RestOption> createState() => _RestOptionState();
}

class _RestOptionState extends State<_RestOption> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final color = enabled ? widget.color : Colors.grey;
    final hovered = enabled && _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 320,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: hovered
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: hovered ? color : color.withAlpha(100),
                  width: 2,
                ),
                boxShadow: [
                  if (hovered)
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: color, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.heightXs,
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 10: La prose du repos au tutoriel**

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        '• 🏕️ Rest: heal 30% of your max HP, forge a card, **or remove one '
        'from your deck**.\n'
```

with:

```dart
        '• 🏕️ Rest: heal 30% of your max HP, raise a rune by one level for '
        'gold, **or remove a card from your deck**.\n'
```

Then replace:

```dart
        '• 🏕️ Repos : soigner 30 % de vos PV max, forger une carte, **ou en '
        'retirer une de votre deck**.\n'
```

with:

```dart
        '• 🏕️ Repos : soigner 30 % de vos PV max, monter une rune d\'un niveau '
        'contre de l\'or, **ou retirer une carte de votre deck**.\n'
```

In `lib/tutorial/widgets/tutorial_node_types_widget.dart`, replace:

```dart
      descEn: 'Heal 30% max HP, forge, or remove a card.',
      descFr: 'Soignez 30 % des PV max, forgez ou retirez une carte.',
```

with:

```dart
      descEn: 'Heal 30% max HP, sharpen a rune, or remove a card.',
      descFr: 'Soignez 30 % des PV max, affûtez une rune ou retirez une carte.',
```

- [ ] **Step 11: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_rune_rules_test.dart` — Expected: `+23: All tests passed!`
Run: `flutter test test/unit/run_controller_test.dart` — Expected: `+11: All tests passed!`
Run: `flutter test test/widget/sharpen_rune_dialog_test.dart` — Expected: `+5: All tests passed!`
Run: `flutter test test/widget/rest_card_selection_screen_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/widget/rest_screen_test.dart` — Expected: `+10: All tests passed!`
Run: `flutter test test/widget/deck_screen_test.dart test/widget/forge_upgrade_dialog_test.dart test/tutorial/ test/widget/tutorial_merge_transition_test.dart` — Expected: `All tests passed!`

- [ ] **Step 12: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1421: All tests passed!` (1404 + 17 : le feu +5 — l'option inactive et quatre retours —, la sélection 3 pour 2, le dialogue +5, `sharpenRune` +3, les formules +3).
Run: `git grep -n -e isForge -e restCampForge -e restCampSnackbarForge -- lib test`
Expected: aucune sortie.
Run: `git grep -n forgeNoEligibleRune -- lib ':!lib/l10n'`
Expected: une seule ligne, `lib/ui/screens/deck_screen.dart` (§5.3 : la chaîne change de lecteur).

- [ ] **Step 13: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/services/forge_rune_rules.dart lib/game/controllers/run/gold_manager.dart lib/game/controllers/run_controller.dart lib/ui/widgets/forge/forge_slot_row.dart lib/ui/widgets/forge/sharpen_rune_dialog.dart lib/ui/screens/rest_card_selection_screen.dart lib/ui/screens/rest_screen.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_node_types_widget.dart test/unit/forge_rune_rules_test.dart test/unit/run_controller_test.dart test/widget/sharpen_rune_dialog_test.dart test/widget/rest_card_selection_screen_test.dart test/widget/rest_screen_test.dart
git commit -F- <<'EOF'
feat(feu): le feu de camp affute une rune contre de l or

L option FORGER devient AFFUTER : une rune d une carte gagne un niveau
pour 50 or par niveau porte, jusqu a son plafond, une fois par visite.
GoldManager.sharpenRune paie et ecrit, ou ne touche a rien. Apres une
action, le retour systeme resout le noeud comme Continuer : plus de
second repos, oubli ou affutage par un aller-retour.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: Le tutoriel enseigne le choix de la rune

A18 (spec §5.5) : l'étape de fusion du tutoriel tire son offre par la fonction du jeu, `ForgeRuneRules.drawRunes`, sur le registre du tutoriel — jamais sur celui du jeu (ADR-081) —, le joueur touche une rune, la carte la porte au niveau 1 ; sans offre, l'étape le dit. `_seedMergeHand` préfère la première carte du deck dont la fusion offre une rune, puis la première qui fusionne, puis les fixtures. SUIVANT attend le choix (plan, « Ce que le plan précise », point 12). La prose de l'étape de fusion suit, hors sa phrase sur la Forge de Fusion, que la partie 2 remplace par le Puits.

Changements visibles de la tâche, voulus : au tutoriel, la fusion offre une rune à choisir — « Choisissez une rune : », puis « Rune ajoutée : … », ou « Aucune rune ne peut s'ajouter à cette carte. » ; la carte semée est la première dont la fusion offre une rune ; la prose dit l'héritage entier et la rune au choix parmi trois.

**Files:**
- Modify: `lib/tutorial/tutorial_engine.dart:6`, `:11`, `:39-41`, `:83-85`, `:92-93`, `:416-458`
- Modify: `lib/tutorial/tutorial_screen.dart:72-74`
- Modify: `lib/tutorial/widgets/tutorial_merge_widget.dart:4-5`, `:64-67`, `:263-272`
- Modify: `lib/tutorial/tutorial_data.dart:272-276`, `:287-292`
- Test: `test/tutorial/tutorial_engine_test.dart:1-2`, `:348-359`, après `:514`
- Test: `test/widget/tutorial_merge_transition_test.dart` (avant le dernier `_tapNext`)
- Test: `test/widget/tutorial_merge_widget_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `ForgeRuneRules.drawRunes`, `ForgeRuneRules.isEligible` (Tasks 1, 3) ; `TutorialEngine.data` (le registre du tutoriel).
- Produces: `List<String> TutorialMockState.mergeOffer` (tranche scratch) ; `void TutorialEngine.chooseMergeRune(String runeId)` ; `ForgeUpgradeData? TutorialEngine.runeById(String id)` ; `TutorialEngine.mergeCards()` tire l'offre.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/tutorial/tutorial_engine_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
```

Then replace the case `:348-359`:

```dart
    test('mergeCards fusionne 3 exemplaires en une carte de rareté supérieure', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
      ]);

      engine.mergeCards();

      expect(engine.mockState.hand, hasLength(1));
      expect(engine.mockState.hand.first.rarity, CardRarity.uncommon);
    });
```

with:

```dart
    test('mergeCards fusionne 3 exemplaires et tire une offre de trois runes '
        'eligibles', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
      ]);

      engine.mergeCards();

      expect(engine.mockState.hand, hasLength(1));
      final merged = engine.mockState.hand.single;
      expect(merged.rarity, CardRarity.uncommon);
      // Par la fonction du jeu, sur le registre du tutoriel (spec P-43 E2,
      // A18) : Tranchant, Brulant, Congelant et Surcharge s'offrent a une
      // Frappe peu commune, trois sont tirees.
      final offer = engine.mockState.mergeOffer;
      expect(offer, hasLength(3));
      expect(offer.toSet(), hasLength(3));
      for (final id in offer) {
        final rune = data.forgeUpgrades.singleWhere((r) => r.id == id);
        expect(ForgeRuneRules.isEligible(rune, merged, data.forgeUpgrades),
            isTrue,
            reason: id);
      }
    });

    test('le choix pose la rune au niveau 1 et vide l offre', () {
      engine.seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
      ]);
      engine.mergeCards();
      final id = engine.mockState.mergeOffer.first;

      engine.chooseMergeRune(id);

      expect(engine.mockState.hand.single.forgeUpgrades, ['$id:1']);
      expect(engine.mockState.mergeOffer, isEmpty);
    });
```

Then replace the end of the case `'la Fusion se replie sur les fixtures si le deck est vide (étape 03 sautée)'`:

```dart
      expect(
        engine.mockState.hand.every((c) => c.data.id == TutorialFixtureIds.strike),
        isTrue,
      );
    });
```

with:

```dart
      expect(
        engine.mockState.hand.every((c) => c.data.id == TutorialFixtureIds.strike),
        isTrue,
      );
    });

    test('la Fusion seme la premiere carte du deck dont la fusion offre une '
        'rune', () {
      // Peu commune, Concentration n'a aucune rune ; Frappe Lourde en a.
      engine.setStarterDeck([
        engine.fixtures.card('concentration'),
        engine.fixtures.card('heavy_strike'),
      ]);

      engine.prepareStep(11);

      expect(
        engine.mockState.hand.every((c) => c.data.id == 'heavy_strike'),
        isTrue,
      );
    });

    test('sans carte dont la fusion offre une rune, la Fusion seme la '
        'premiere carte fusionnable', () {
      engine.setStarterDeck([
        engine.fixtures.card('concentration'),
        engine.fixtures.card('focus'),
      ]);

      engine.prepareStep(11);

      expect(
        engine.mockState.hand.every((c) => c.data.id == 'concentration'),
        isTrue,
      );
    });
```

In `test/widget/tutorial_merge_transition_test.dart`, replace:

```dart
      expect(find.text('Même coût, rareté supérieure.'), findsOneWidget);

      await _tapNext(tester); // -> 12 L'Expérience & le Level Up
```

with:

```dart
      expect(find.text('Même coût, rareté supérieure.'), findsOneWidget);

      // L'etape enseigne un choix (spec P-43 E2, A18) : SUIVANT attend la
      // rune. Au Paladin des cinq premieres cartes du pool, la carte semee
      // est Eveil, dont la premiere fusion offre Endurci.
      await tester.tap(find
          .byWidgetPredicate((widget) =>
              (widget.key?.toString() ?? '').contains('tutorial-merge-rune-'))
          .first);
      await tester.pump();
      expect(find.textContaining('Rune ajoutée : '), findsOneWidget);

      await _tapNext(tester); // -> 12 L'Expérience & le Level Up
```

Create `test/widget/tutorial_merge_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_merge_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// Monte l'étape de fusion sur trois exemplaires de [cardId], puis fusionne :
/// l'animation de 600 ms, puis le rappel différé de 150 ms. Jamais de
/// `pumpAndSettle()` : la carte fusionnée grandit par une animation
/// élastique.
Future<TutorialEngine> _merge(WidgetTester tester, String cardId) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.seedHand([cardId, cardId, cardId]);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialMergeWidget(engine: engine)),
    ),
  );
  await tester.tap(find.text('Sélectionner les 3 et fusionner'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 650));
  await tester.pump(const Duration(milliseconds: 200));
  return engine;
}

/// L'étape de fusion du tutoriel enseigne le choix d'une rune (spec P-43 E2,
/// A18, §5.5).
void main() {
  testWidgets('l offre se montre, et la rune choisie se dit', (tester) async {
    final engine = await _merge(tester, 'strike_basic');

    expect(find.text('Choisissez une rune :'), findsOneWidget);
    final id = engine.mockState.mergeOffer.first;
    final name = engine.runeById(id)!.getName('fr');

    await tester.tap(find.byKey(ValueKey('tutorial-merge-rune-$id')));
    await tester.pump();

    expect(engine.mockState.hand.single.forgeUpgrades, ['$id:1']);
    expect(find.text('Rune ajoutée : $name'), findsOneWidget);
  });

  testWidgets('sans rune eligible, l etape le dit', (tester) async {
    await _merge(tester, 'concentration');

    expect(find.text('Choisissez une rune :'), findsNothing);
    expect(find.text('Aucune rune ne peut s\'ajouter à cette carte.'),
        findsOneWidget);
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/tutorial/tutorial_engine_test.dart test/widget/tutorial_merge_widget_test.dart test/widget/tutorial_merge_transition_test.dart`
Expected: FAIL — `tutorial_engine_test.dart` et `tutorial_merge_widget_test.dart` ne compilent pas (`The getter 'mergeOffer' isn't defined`, `The method 'chooseMergeRune' isn't defined`, `'runeById'`) ; la transition ne trouve aucun bouton de rune.

- [ ] **Step 3: Le moteur du tutoriel tire l'offre et pose le choix**

In `lib/tutorial/tutorial_engine.dart`, replace:

```dart
import '../models/data/card_data.dart';
```

with:

```dart
import '../models/data/card_data.dart';
import '../models/data/forge_upgrade_data.dart';
```

Then replace:

```dart
import '../game/services/damage_pipeline.dart';
```

with:

```dart
import '../game/services/damage_pipeline.dart';
import '../game/services/forge_rune_rules.dart';
```

Then replace:

```dart
  bool hasDrafted = false;

  /// Statistiques de départ dérivées de la classe choisie, ou valeurs de
```

with:

```dart
  bool hasDrafted = false;

  /// L'offre de runes de la fusion de l'étape Fusion (spec P-43 E2, A18) :
  /// tirée à la fusion, vidée par le choix.
  List<String> mergeOffer = [];

  /// Statistiques de départ dérivées de la classe choisie, ou valeurs de
```

Then replace:

```dart
    pendingDrafts = 0;
    hasDrafted = false;
  }
}
```

with:

```dart
    pendingDrafts = 0;
    hasDrafted = false;
    mergeOffer = [];
  }
}
```

Then replace:

```dart
  int _currentStepIndex = 0;
  final TutorialMockState mockState = TutorialMockState();
```

with:

```dart
  int _currentStepIndex = 0;
  final TutorialMockState mockState = TutorialMockState();

  /// Le tirage de l'offre de fusion, sans graine, comme au jeu.
  final Random _rng = Random();
```

Then replace `_seedMergeHand` and `mergeCards` (`:416-458`) — from `  /// Sème la main de l'étape Fusion : trois copies d'une carte du deck du` to the closing `  }` of `mergeCards` — with:

```dart
  /// Sème la main de l'étape Fusion : trois copies d'une carte du deck du
  /// joueur — la première dont la fusion offre au moins une rune, puisque
  /// l'étape enseigne à en choisir une (spec P-43 E2, A18) ; à défaut, la
  /// première qui fusionne. Les cartes de classe (rareté `unique`) ne
  /// fusionnent jamais, l'étape l'enseigne elle-même. Repli sur les fixtures
  /// si le deck est vide ou n'en contient aucune hors classe (étape 03
  /// sautée).
  void _seedMergeHand() {
    CardData? fusible;
    CardData? offering;
    for (final instance in mockState.masterDeck) {
      final merged = instance.data.rarity.next;
      if (merged == null) continue;
      fusible ??= instance.data;
      final card = CardInstance(data: instance.data, rarity: merged);
      if (data.forgeUpgrades.any(
          (rune) => ForgeRuneRules.isEligible(rune, card, data.forgeUpgrades))) {
        offering = instance.data;
        break;
      }
    }

    final candidate = offering ?? fusible;
    if (candidate == null) {
      _seedHand([
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
        TutorialFixtureIds.strike,
      ]);
      return;
    }
    mockState.hand = List.generate(3, (_) => CardInstance(data: candidate));
  }

  /// Fusionne les 3 exemplaires de la main en une carte de rareté
  /// supérieure, comme `DeckNotifier.mergeCards`, puis tire l'offre de runes
  /// par la fonction du jeu, sur le registre du tutoriel (spec P-43 E2, A18 ;
  /// ADR-081) : trois au plus, aucune si aucune ne s'offre.
  void mergeCards() {
    if (mockState.hand.length != 3) return;
    final base = mockState.hand.first;
    final merged =
        CardInstance(data: base.data, rarity: base.rarity.next ?? base.rarity);
    mockState.hand = [merged];
    mockState.mergeOffer = ForgeRuneRules.drawRunes(
      merged,
      data.forgeUpgrades,
      _rng,
      count: 3,
    );
    notifyListeners();
  }

  /// Pose la rune [runeId], choisie dans l'offre, sur la carte fusionnée, au
  /// niveau 1 — comme le dialogue de fusion du jeu —, et vide l'offre.
  void chooseMergeRune(String runeId) {
    if (mockState.hand.length != 1 ||
        !mockState.mergeOffer.contains(runeId)) {
      return;
    }
    final merged = mockState.hand.single;
    mockState.hand = [
      merged.copyWith(forgeUpgrades: [...merged.forgeUpgrades, '$runeId:1']),
    ];
    mockState.mergeOffer = [];
    notifyListeners();
  }

  /// La rune [id] du registre du tutoriel, jamais de celui du jeu (ADR-081).
  ForgeUpgradeData? runeById(String id) =>
      data.forgeUpgrades.where((rune) => rune.id == id).firstOrNull;
```

In `lib/tutorial/tutorial_screen.dart`, replace:

```dart
      case TutorialStepType.merge:
        return engine.mockState.hand.length == 1 &&
            engine.mockState.hand.first.rarity != CardRarity.common;
```

with:

```dart
      case TutorialStepType.merge:
        // L'étape enseigne un choix : elle n'est franchie qu'une fois la rune
        // choisie, ou quand aucune ne s'offre (spec P-43 E2, A18).
        return engine.mockState.hand.length == 1 &&
            engine.mockState.hand.first.rarity != CardRarity.common &&
            engine.mockState.mergeOffer.isEmpty;
```

- [ ] **Step 4: L'étape de fusion montre l'offre, puis la rune posée**

In `lib/tutorial/widgets/tutorial_merge_widget.dart`, replace:

```dart
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';
```

with:

```dart
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../ui/widgets/ui_card.dart';
import '../tutorial_engine.dart';
```

Then replace:

```dart
  void _runMerge() {
    if (_isMerged || _controller.isAnimating) return;
    _controller.forward();
  }
```

with:

```dart
  void _runMerge() {
    if (_isMerged || _controller.isAnimating) return;
    _controller.forward();
  }

  /// Le nom d'une rune du registre du tutoriel.
  String _runeName(String id, String locale) =>
      widget.engine.runeById(id)?.getName(locale) ?? id;

  /// L'offre de la fusion, puis la rune posée (spec P-43 E2, A18, §5.5) : le
  /// joueur touche une rune, la carte la porte ; sans offre, l'étape le dit.
  Widget _runeChoice(CardInstance merged, bool isFrench, String locale) {
    final style = TextStyle(color: Colors.grey.shade300, fontSize: 12);
    final offer = widget.engine.mockState.mergeOffer;
    if (offer.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isFrench ? 'Choisissez une rune :' : 'Choose a rune:',
            style: style,
          ),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in offer)
                OutlinedButton(
                  key: ValueKey('tutorial-merge-rune-$id'),
                  onPressed: () =>
                      setState(() => widget.engine.chooseMergeRune(id)),
                  child: Text(_runeName(id, locale)),
                ),
            ],
          ),
        ],
      );
    }
    final added = merged.forgeUpgrades.isEmpty
        ? null
        : ForgeUpgradeData.parseRef(merged.forgeUpgrades.last);
    if (added == null) {
      return Text(
        isFrench
            ? 'Aucune rune ne peut s\'ajouter à cette carte.'
            : 'No rune can be added to this card.',
        style: style,
      );
    }
    final name = _runeName(added.$1, locale);
    return Text(
      isFrench ? 'Rune ajoutée : $name' : 'Rune added: $name',
      style: style,
    );
  }
```

Then replace:

```dart
                    Text(
                      isFrench
                          ? 'Même coût, rareté supérieure.'
                          : 'Same cost, higher rarity.',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
```

with:

```dart
                    Text(
                      isFrench
                          ? 'Même coût, rareté supérieure.'
                          : 'Same cost, higher rarity.',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 12,
                      ),
                    ),
                    if (hasMergedResult) ...[
                      const SizedBox(height: 8),
                      _runeChoice(hand.first, isFrench, locale),
                    ],
                  ],
                ),
```

- [ ] **Step 5: La prose de l'étape de fusion**

La phrase sur la Forge de Fusion reste : la partie 2 la remplace par le Puits (spec §5.5, §10).

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        'Forge upgrades carried by the three copies are inherited and merged, '
        'capped by the new rarity\'s capacity. Your class cards are unique, and '
        'unique cards never merge. **The Fusion Forge is a separate, paid '
        'system** — a dedicated map node, not to be confused with this free '
        'merging.',
```

with:

```dart
        'The runes of the three copies are all kept — the same rune adds up '
        'its levels — and the merged card **gains one more, chosen among '
        'three**, at level 1; Quick and Eco only appear from the second '
        'merge. Your class cards are unique, and unique cards never merge. '
        '**The Fusion Forge is a separate, paid system** — a dedicated map '
        'node, not to be confused with this free merging.',
```

Then replace:

```dart
        'Les améliorations de forge des trois exemplaires sont héritées et '
        'consolidées, dans la limite de la capacité de la nouvelle rareté. Vos '
        'cartes de classe sont uniques, et une carte unique ne fusionne jamais. '
        '**La Forge de Fusion est un système distinct et payant** — un nœud '
        'dédié de la carte du monde, à ne pas confondre avec cette '
        'fusion-ci, qui reste gratuite.',
```

with:

```dart
        'Les runes des trois exemplaires sont toutes conservées — une même '
        'rune additionne ses niveaux — et la carte fusionnée **en reçoit une '
        'de plus, au choix parmi trois**, au niveau 1 ; Véloce et Économe '
        'n\'apparaissent qu\'à partir de la deuxième fusion. Vos cartes de '
        'classe sont uniques, et une carte unique ne fusionne jamais. **La '
        'Forge de Fusion est un système distinct et payant** — un nœud dédié '
        'de la carte du monde, à ne pas confondre avec cette fusion-ci, qui '
        'reste gratuite.',
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/tutorial/` — Expected: `All tests passed!` (dont `tutorial_isolation_test.dart` : `lib/tutorial/` n'importe toujours aucun provider, et ne nomme pas `GameDataRegistry.instance`).
Run: `flutter test test/widget/tutorial_merge_widget_test.dart` — Expected: `+2: All tests passed!`
Run: `flutter test test/widget/tutorial_merge_transition_test.dart` — Expected: `+1: All tests passed!`

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1426: All tests passed!` (1421 + 5 : le moteur du tutoriel +3, l'étape de fusion +2).

- [ ] **Step 8: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/tutorial/tutorial_engine.dart lib/tutorial/tutorial_screen.dart lib/tutorial/widgets/tutorial_merge_widget.dart lib/tutorial/tutorial_data.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_merge_transition_test.dart test/widget/tutorial_merge_widget_test.dart
git commit -F- <<'EOF'
feat(tutoriel): l etape de fusion enseigne le choix d une rune

La fusion du tutoriel tire son offre par la fonction du jeu, sur son
propre registre, et le joueur choisit sa rune avant de poursuivre ; sans
offre, l etape le dit. La carte semee est la premiere du deck dont la
fusion offre une rune. La prose de l etape suit.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: Vérification finale

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf, et cette tâche se rejoue en entier. `<base>` désigne le commit qui **ajoute** le plan — un commit ultérieur sur le plan ne le déplace pas : `git log --diff-filter=A --format=%H -- docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-1.md`.

**Files:** aucun.

**Interfaces:**
- Consumes: la partie 1 entière.
- Produces: la branche `feat/v0.5.4-p43-e2-fusion-forge`, partie 1 implémentée — rien de poussé, aucune PR. Le plan de la partie 2 s'écrit sur ce code (orchestration §3.4).

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1426: All tests passed!` — 1375 + 51, dont `tutorial_isolation_test.dart` (ADR-081), `rune_ids_in_code_test.dart` (huit runes, aucun id en littéral dans `lib/`), `real_bundle_load_test.dart` (huit runes, `enduring` seule non cumulable) et `shipped_entities_round_trip_test.dart` (chaque fichier livré, runes et signatures comprises, se réécrit à l'identique), inchangés et verts.

- [ ] **Step 2: Ce qui a disparu (spec §4.10, §4.11, A3)**

Run: `git grep -n -e forgeCapacity -e forgeCapacityAt -e baseMaxForgeUpgrades -- lib test assets tool`
Expected: aucune sortie — la capacité n'a plus aucun lecteur.

Run: `git grep -n -e forgeSlots -e bonusForgeSlots -e forgeTargetCardId -e forgeTargetSessions -e setForgeSession -e clearForgeSession -e buyBonusForgeSlot -e ForgeBuySlotButton -e rerollCost -e resetForgeTarget -- lib test`
Expected: aucune sortie — la session de forge et les fentes achetées non plus.

Run: `git grep -n -w ForgeSlot -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e totalMaxForgeUpgrades -e 'totalSlots:' -e 'this.totalSlots' -e _capacity -- lib test`
Expected: aucune sortie. Les trois autres motifs de la quatrième commande de la spec (§4.11) — `isStackable(`, `fusionOptionsFor`, `FusionOption` — gardent leurs lecteurs jusqu'en partie 2 (Step 3).

Run: `git grep -n -e isForge -e restCampForge -e restCampSnackbarForge -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e 'AMÉLIORATION FORGE' -e 'OFFRES DE LA FORGE' -e 'Capacité de Forge' -e "'Forger'" -e 'AMÉLIORATIONS DE LA FORGE' -- lib`
Expected: aucune sortie — les textes de la forge de la partie 1 (§5.7) ont disparu de `lib/` (un test de l'écran de deck vérifie, lui, que « Capacité de Forge Dépassée » ne s'affiche plus).

- [ ] **Step 3: `pools` et `stackable` ne gardent que les lecteurs que la spec leur laisse (§10, « Entre les deux parties »)**

Run: `git grep -n -w pools -- lib`
Expected: des lignes dans ces cinq fichiers, et dans aucun autre :
- `lib/models/data/forge_upgrade_data.dart` — le champ, le constructeur, `fromJson`, `toJson` ;
- `lib/game/controllers/shop_controller.dart` — le tirage des pré-forgées (`_getEligibleUpgradesForPool` et son commentaire) ;
- `lib/game/services/forge_rune_rules.dart` — la doc du prédicat (« `pools` n'en est pas une condition ») ;
- `lib/services/content_editor/entity_descriptor.dart` — `requiredKeys`, son commentaire et le gabarit ;
- `lib/models/data/card_data.dart` — l'homonyme du commentaire de `compareByDisplayOrder` (« les trois pools » d'affichage).

Run: `git grep -n -w stackable -- lib`
Expected: des lignes dans `lib/models/data/forge_upgrade_data.dart` (le champ, le constructeur, `fromJson`, `toJson`), `lib/game/services/forge_rune_rules.dart` (`isStackable`, et la doc de la classe), `lib/services/content_editor/entity_descriptor.dart` (le gabarit) et l'homonyme de `lib/models/status_effect.dart` (le commentaire de `StatusEffect.combine`, « si stackable »), et dans aucun autre — ni `forge_slot_row.dart`, ni `deck_screen.dart`, ni `forge_upgrade_dialog.dart`.

Run: `git grep -n "isStackable(" -- lib`
Expected: quatre lignes — la définition et ses deux lecteurs dans `lib/game/services/forge_rune_rules.dart` (`consolidate`, `fusionOptionsFor`), et le niveau des pré-forgées dans `lib/game/controllers/shop_controller.dart`.

Run: `git grep -n "isEligible(" -- lib`
Expected: la déclaration et `drawRunes` dans `lib/game/services/forge_rune_rules.dart`, le tirage des pré-forgées dans `lib/game/controllers/shop_controller.dart`, le semis de l'étape de fusion dans `lib/tutorial/tutorial_engine.dart` — et aucun écran du feu.

Run: `git grep -n "drawRunes(" -- lib`
Expected: trois lignes — la déclaration (`forge_rune_rules.dart`), l'offre de la fusion (`deck_screen.dart`), l'étape de fusion du tutoriel (`tutorial_engine.dart`).

Run: `git grep -n forgeNoEligibleRune -- lib ':!lib/l10n'`
Expected: une ligne, `lib/ui/screens/deck_screen.dart`.

Run: `git grep -n "data.isExhaust" -- lib/game/components lib/ui`
Expected: les quatre lecteurs d'aujourd'hui, inchangés — le badge suit `exhaustsOnPlay` en partie 2 (A13).

- [ ] **Step 4: Aucun id de rune dans `lib/`, la donnée que lit la simulation intacte (spec §9)**

Run: `git grep -nE "['\"](sharp|hardened|quick|eco|burning|freezing|shocking|enduring)['\"]" -- lib`
Expected: aucune sortie.

Run: `git diff <base>..HEAD -- assets/data/forge_upgrades | grep -E '^[-+] ' | grep -v '"minFusionRank"'`
Expected: aucune sortie — la seule ligne que la partie 1 change dans un fichier de rune est celle de `minFusionRank` : aucun `weight` ne bouge, ni aucun élément d'un `eligibleCardTypes`, même écrit sur plusieurs lignes.

Run: `git diff <base>..HEAD --name-only -- assets`
Expected: exactement les huit fichiers de `assets/data/forge_upgrades/` et les six de `assets/data/classes/*/cards/`.

Run: `git diff --stat <base>..HEAD -- tool site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni la simulation et sa référence, ni `site/`, ni la note de version, ni la version, ni un fichier généré de plateforme.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0 — aucun dossier neuf sous `assets/`.

- [ ] **Step 5: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline <base>..HEAD`
Expected: au moins les cinq commits des Tasks 1 à 5, plus les commits de correction éventuels. Rien n'est poussé.

---

## Ce que le plan laisse à la partie 2

Repris de la spec, §10 « Partie 2 », pour mémoire — aucune tâche de ce plan ne les fait :

1. **Le Puits** (§4.8, A5) : le placement tous les trois actes, `ForgeFusionScreen` réécrit et son retour système, `GoldManager.exchangeRune` (à côté de `sharpenRune`), `wellOptions`, `wellLevel`, `wellCost`, `wellBaseCost` ; la carte du monde (`wellName`, `wellDesc`, `wellTitle`), la prose des nœuds du tutoriel et la phrase du Puits de l'étape de fusion ; `fusionOptionsFor` et `FusionOption` supprimés, `forge_fusion_screen_test.dart` réécrit. `ForgeRuneRules.replaceRune` et `ForgeSlotRow` (son `actionLabel` « Échanger — coût or ») sont prêts à servir.
2. **La boutique** (§4.9, A11, A12) : la copie du deck, l'étal retenu à son nœud — `ShopState.nodeId` et sa remise à zéro au changement de nœud courant —, `clearCloneOptions` et le `PopScope` de `ShopScreen` supprimés ; les pré-forgées par `drawRunes(count: 1)`, leur repli par `pools` supprimé.
3. **`pools` et `stackable` supprimés** avec leurs derniers lecteurs (§4.11) — dont le groupe `stackable` de `forge_rune_rules_test.dart`, les cas « non cumulable » devenus « plafond 1 », le renommage du cas `legacy`, l'assertion de `real_bundle_load_test.dart`, `requiredKeys` de l'éditeur. **Deux runes construites en Dart avec `pools: ['common']`, que ce plan ajoute et que la liste « Les tests qui suivent » de la spec (§8) ne compte pas**, perdent aussi le paramètre : celle du cas « lu dans le fichier ; 1 au constructeur » de `test/unit/forge_upgrade_data_test.dart` (Task 1) et celle du cas « une reference mal formee prend l emoji par defaut » de `test/widget/ui_card_rune_sockets_test.dart` (Task 2). **`_cardWith` reste** : le groupe de l'affûtage le lit (point 11 du plan).
4. **`cheap`, `precise`, `spectral`** : les trois fichiers, `reduceCost`, `critBonus`, `addExhaust`, le coût courant du prédicat lu sur le catalogue reçu (A15), le badge (A13), `{val}` général (A14), `runeIcons` / `runeColors` et le test d'intégrité (A19) ; la matrice du catalogue gagne les trois runes.
5. **La simulation** : le réalignement (premier temps, liste d'ordre explicite des 17 ids), puis `spectral` (second temps), dans une tâche à part ; les relances par l'orchestrateur.
6. **Pour la note de version et `memory-bank-sync`** (spec §11), constaté en écrivant ce plan : `GoldManager` a changé de méthode (`buyBonusForgeSlot` → `sharpenRune`) ; le libellé anglais « SHARPEN » du feu côtoie la récompense de niveau « Sharpening » (`assets/data/level_up_rewards/sharpening.json`, « Aiguisage » en français) — deux mots voisins pour deux choses, à signaler au propriétaire sans rien changer ici.
