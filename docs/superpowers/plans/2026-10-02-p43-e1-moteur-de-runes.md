# P-43 E1 — Le moteur de runes data-driven — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Une rune déclare dans son fichier ce qu'elle fait (`deltas`, une liste typée), où elle s'offre (un prédicat d'éligibilité unique) et jusqu'où elle monte (`maxLevel`, lu par une seule borne aux quatre endroits qui écrivent un niveau) ; un applicateur unique, `EffectiveCard`, calcule la carte telle qu'elle se joue — rareté (G1, G2) et runes comprises — pour le moteur comme pour les rendus ; `sharp` et `hardened` passent à +15 % de la base par niveau, au moins +1 ; la boucle de jeu ne change pas.

**Architecture:** `CardDelta` (`lib/models/data/card_delta.dart`) est un vocabulaire fermé de trois sortes — `percentBonus`, `addEffect`, `removeExhaust` — que `ForgeUpgradeData.deltas` lit dans le fichier de rune. `EffectiveCard.apply` (`lib/models/effective_card.dart`), fonction pure, reçoit des paires *(delta, niveau)* et rend les effets ajoutés, les effets propres à leur valeur jouée — G1 par `CardRarity.scaleValue`, G2 par une constante — et la levée de l'épuisement ; `EffectiveCard.runeDeltas` traduit les runes d'une carte en paires, exemplaires additionnés, et la vague 5 y traduira de même les évolutions de signature. `EffectResolver.resolveCard` confie chaque effet, ceux des runes d'abord, au registre de stratégies ; les rendus Flame et Flutter et le tutoriel lisent l'applicateur. `ForgeUpgradeData` porte l'analyseur unique des références (`parseRef`, `levelsOf`), la borne `boundLevel` et les lignes d'infobulle ; `ForgeRuneRules.isEligible` est le prédicat, lu par la forge du feu, la boutique et la sélection du feu. `CardRarity.fusionRank` remplace `forgeSlotBonus` et compte les paliers de G1.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-02-p43-e1-moteur-de-runes-design.md` — à lire **en entier**, ses arbitrages A1 à A13 compris. Le déroulé du programme fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (fiche §8.1, partie E1). E0 est implémenté sur la branche : `StatusEffect.sourceId`, `StatusSource`, `createStatus(..., {sourceId})` et `StatRule.ratio` existent, aucune tâche ne les réécrit.

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
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.3-p43-e0-e1`, la branche courante. Il **ne crée aucune branche**, ne bascule sur aucune autre, ne commite rien sur `main`. Pas de worktree, même si le skill d'exécution en propose un.
- **La base de tests : 1228**, le total de `flutter test` sur la branche le 2026-10-02 (`229bce6`, après E0). Chaque tâche donne le total attendu, recompté sur les blocs de test qu'elle écrit — **et mesuré** en rejouant le plan tâche par tâche sur une copie neuve du dépôt à `229bce6`, les blocs « replace / with » appliqués tels qu'écrits ici, le 2026-10-02 :

  | Tâche | Ajoutés | Retirés | Total |
  |:---|---:|---:|---:|
  | 1 — le moteur | 40 | 1 | 1267 |
  | 2 — G1 et G2 | 8 | 0 | 1275 |
  | 3 — les rendus | 4 | 0 | 1279 |
  | 4 — les textes | 12 | 0 | 1291 |
  | 5 — l'éligibilité | 60 | 0 | 1351 |
  | 6 — la borne | 11 | 0 | 1362 |
  | 7 — le refus du feu | 4 | 0 | 1366 |
  | 8 — l'éditeur | 7 | 0 | 1373 |

  Le test retiré en Task 1 n'est écrit nulle part : `test/unit/stat_gains_test.dart:20` engendre un cas par valeur de `GainSource`, et `rune` disparaît (A2). Un cas remplacé en Task 4 (`decoupled_forge_test.dart:112-119`) compte pour zéro. `dart analyze` est propre à la fin de chaque tâche du rejeu.
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-02 sur `229bce6`, avant toute tâche. Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le point propre au lot**, à respecter dans chaque tâche : `pools`, `stackable` et la capacité gardent leurs lecteurs, et aucune tâche ne leur en ajoute ; **aucun écran ne change de déroulé** ; les seuls changements visibles sont ceux que la spec livre (§10 et §4.8) : la formule de `sharp` et `hardened` (D33) ; l'offre de runes du feu et de la boutique, filtrée par l'éligibilité en donnée (D44, D51, D61, D75) ; le plafond `maxLevel` aux quatre endroits qui écrivent un niveau — la fusion de cartes, le nœud Forge de Fusion, le tirage de niveau du feu et celui des pré-forgées (D27, D72) ; les valeurs que G1 et G2 corrigent ; la pose des statuts élémentaires par `addStatus`, sans source (A4 de la spec E0) ; le son du gain de mana pour `eco` (conséquence d'A2) ; et les retouches de texte que la spec liste (infobulles, tutoriel, refus au feu A11). Aucune rune neuve, rien d'E2 (fusion qui propose une rune, héritage, affûtage, Puits, copie du deck, `minFusionRank`, suppression de `pools`, de `stackable` ou de la capacité).
- **La simulation** (fiche §8.1, fichier d'orchestration §7.3) : aucun réalignement. **Aucune tâche ne touche le `weight` d'aucune des huit runes de `assets/data/forge_upgrades/`, ni l'`eligibleCardTypes` des six autres que `sharp` et `hardened`**, ni `tool/simulations/d26_economy_sim.dart`, ni `tool/simulations/d26_reference_output.md`. L'orchestrateur relancera la simulation à la fin de la vague ; aucune tâche ne la lance.
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version ; le format `id:niveau` de `CardInstance.forgeUpgrades` ne change pas.
- **Le passage unique d'ADR-095 tient** : tout gain passe encore par `StatGains.apply` (`test/unit/stat_gain_single_passage_test.dart` n'est pas touché). **Le tutoriel ne référence aucun provider** (ADR-081) : il lit l'applicateur, fonction pure, par `CardInstance.effective`, qui lit le registre statique comme `ForgeUpgradeData.getById` (`test/tutorial/tutorial_isolation_test.dart` reste vert).
- **Les tests tirés au hasard.** La forge du feu tire ses fentes avec un `Random()` sans graine, la boutique aussi : les tests qui vérifient ce que ces tirages ne proposent **jamais** (Tasks 5 et 6) font assez de tirages — relances, boutiques successives — pour échouer avec une probabilité qui dépasse 99 % avant la tâche ; une fois la tâche faite, ils ne peuvent pas réussir à tort.

## Review Focus

Les cinq cas que la spec implique sans qu'un test de son §8 les pose, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **Une valeur nulle à une rareté haute** — G1 (`max(round(base × m), v + 1)`) ferait gagner 1 par palier à un effet de valeur 0 sans la garde « base nulle rendue telle quelle ». Test : Task 2, `effective_card_test.dart`, « une valeur nulle reste nulle a toute rarete ».
2. **Une sauvegarde d'avant `0.5.3` au-delà d'un plafond** — `eco:3`, ou deux `eco:1` : la borne ne rend jamais un niveau négatif, le prédicat ne repropose pas la rune, la Forge de Fusion ne vend pas une fusion qui perdrait un niveau. Tests : Task 5, `forge_upgrade_data_test.dart` (« jamais negatif ») et `rune_eligibility_test.dart` (« une carte deja au-dela du plafond… ») ; Task 6, `forge_fusion_screen_test.dart` (« a card whose fusion would lose a level is not listed »).
3. **Une rune qu'une sauvegarde porte et que le catalogue n'a plus** (`legacy:2`) — l'applicateur l'ignore, l'infobulle ne lui écrit pas de ligne, le prédicat ne la lit pas. Tests : Task 1, `effective_card_test.dart` (« runeDeltas ignore … un id hors du catalogue ») ; Task 4, `forge_upgrade_data_test.dart` (« tooltipLines : … rien pour une rune absente du registre ») ; Task 5, `rune_eligibility_test.dart` (« une rune portee absente du catalogue est ignoree »).
4. **`{val}` sur une carte qui n'a pas l'effet visé** — *Endurci* sur une carte sans armure, d'une sauvegarde d'avant le lot : la description dit « +0 », jamais une exception ou un chiffre faux. Test : Task 4, `decoupled_forge_test.dart`, « {val} vaut 0 sur une carte sans l effet que la rune vise ».
5. **Le Berserker et *Endurci*** — le bonus de la rune reste dans le gain d'armure de la carte, comme l'ancien code l'y ajoutait déjà (`effect_resolver.dart:238-239` ; le gain séparé de `:256-261` ne visait qu'une carte sans armure) : un seul gain, converti une fois au `ratio` de la classe. Sous D33, *Défense* 5 + *Endurci* 1 = 6 → 3 Puissance (7 → 4 avant le lot) : une classe qui convertit son armure, sur une valeur que D33 change, qu'aucun test du §8 ne joue. Test : Task 1, `rune_resolution_test.dart`, « le Berserker convertit en une fois l armure de la carte et celle de la rune ».

## Ce que le plan précise ou corrige de la spec

Constaté en rédigeant le plan, et en le rejouant ; aucun n'amende un arbitrage.

1. **Un rendu de la spec est du code mort.** `CardTextRenderer.buildDescription()` (`card_text_renderer.dart:355-491`), comptée par la spec parmi les sites (« le rendu Flame de la carte, l'infobulle », §4.2, §5.2), n'a aucun appelant ; l'infobulle Flame est `CardComponent.buildDetailedDescription` (appelée par `card_animation_system.dart:102`). Task 3 la supprime au lieu de la réécrire.
2. **Un test disparaît avec `GainSource.rune`** : `stat_gains_test.dart:20` engendre un cas par valeur de l'énumération (Task 1, −1).
3. **`stat_gains_characterization_test.dart:193-196`** (« rune eco », sur une carte de coût 0) a besoin, comme `:116-119`, d'un registre qui porte la rune : sans lui, l'applicateur n'applique rien. Il montre aussi que `requiresMinCost` est une règle d'**offre**, pas d'application : `eco` portée par une carte gratuite (une sauvegarde) rend toujours son mana.
4. **L'ordre de la borne et d'A12.** Borner le tirage des pré-forgées par « ce que la carte porte déjà » sans que le prédicat lise les runes déjà tirées laisserait le repli sans exclusion retirer une rune plafonnée, que la borne ramènerait au niveau 0 (`eco:0`). Task 6 fait donc ensemble la borne des pré-forgées et la lecture des runes tirées (A12) ; le refus du feu (A11) suit en Task 7.
5. **`UiCard` perd aussi son champ `effects`** : il doublait `data.effects`, que l'applicateur lit ; son seul appelant par le constructeur nu, `hud_and_targeting_badge_test.dart`, passe une `CardData` (Task 3).
6. **Le corps compact garde « base +bonus🔨 »** en lisant l'applicateur deux fois, sans puis avec les runes (Task 3) : la forme d'aujourd'hui, sur les valeurs de l'applicateur.
7. **Deux aides que la spec ne nomme pas** : `EffectiveCard.withRunes(data, rarity, runes)`, l'applicateur sur le catalogue du registre, que lisent `CardInstance.effective` et les deux rendus Flutter ; `ForgeUpgradeData.tooltipLine` / `tooltipLines`, la ligne d'infobulle de §5.2, écrite une fois dans le modèle et lue par l'infobulle Flame et l'infobulle Flutter — aucun mélange de couches.
8. **La forme de l'applicateur** : `CardDelta` est une classe scellée ; chaque sorte porte son calcul (`PercentBonusDelta.bonusFor`, `AddEffectDelta.effectAt`), et `EffectiveCard.apply` les compose par un `switch` exhaustif **par sorte** — jamais par rune (A1).
9. **Le gabarit de l'éditeur suit le modèle tâche par tâche** : `deltas` en Task 1 (obligatoire dès qu'il est lu), `maxLevel` en Task 4, les champs d'éligibilité en Task 5, sans quoi « tous les gabarits franchissent les sept familles » (`entity_validator_test.dart:496-517`) rougirait entre deux tâches. Le commentaire `entity_descriptor.dart:330-332` (« ne lève sur rien d'autre que `id` ») devient faux dès Task 1 et y est corrigé.
10. **G1 en peu commune** : pour les valeurs de dégâts et d'armure des cartes livrées (3 et plus), G1 rend en peu commune ce que rendait l'arrondi d'aujourd'hui (3 → 4, 4 → 5) ; la fusion du tutoriel (commune → peu commune) ne change donc aucun chiffre que le tutoriel joue. Le test du tutoriel (Task 3) prend une carte de base 1.
11. **La matrice de §4.8 est juste** : `forge_upgrades_catalog_test.dart` (Task 5) la vérifie sur les 23 cartes et les huit runes réelles, et passe.
12. **Un changement de comportement latent : la cible des statuts de rune.** L'ancien bloc élémentaire ne posait un statut de rune que sur l'ennemi visé ou sur tous les ennemis (`effect_resolver.dart:207-230`) ; `ApplyStatusEffectStrategy`, par laquelle il passe désormais (A2), lit `card.data.target` et pose le statut sur le héros pour une carte `self` (`strategies.dart:175-194`). Une Attaque `target: self` portant `burning`, `freezing` ou `shocking` brûlerait, gèlerait ou électrocuterait donc le héros. Aucune carte livrée n'est concernée — les 12 Attaques visent `singleEnemy` ou `allEnemies` —, mais l'éditeur permet d'en écrire une : l'éligibilité des runes élémentaires (`eligibleCardTypes: ["attack"]`) ne lit pas la cible de la carte. Arbitrage de l'orchestrateur (filtre 7) : **pas de code dans E1**, le cas est consigné ici et laissé pour la suite.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/card_delta.dart` *(nouveau)* | `CardDelta` et ses trois sortes, leur lecture JSON, `typeNames` | 1 |
| `lib/models/effective_card.dart` *(nouveau)* | L'applicateur : `apply`, `runeDeltas`, `withRunes` (1) ; G2 (2) | 1, 2 |
| `lib/models/data/card_data.dart` | `CardRarity.multiplier` (1) ; `fusionRank`, `scaleValue` — G1 (2) | 1, 2 |
| `lib/models/data/forge_upgrade_data.dart` | `deltas`, `parseRef`, `levelsOf` (1) ; `maxLevel`, `getDescription`, `tooltipLine(s)`, sans `valueMultiplier` (4) ; éligibilité, `boundLevel` (5) | 1, 4, 5 |
| `lib/models/card_instance.dart` | `effective`, `exhaustsOnPlay` sur la donnée (1) ; sans `rarityMultiplier` (3) | 1, 3 |
| `lib/game/services/effect_resolver.dart` | `resolveCard` : un seul chemin d'effets | 1 |
| `lib/game/systems/stat_gains.dart` | `GainSource.rune` supprimé | 1 |
| `lib/game/services/forge_rune_rules.dart` | L'analyseur du modèle (1) ; `isEligible` (5) ; `consolidate`, `fusionOptionsFor` bornés (6) | 1, 5, 6 |
| `assets/data/forge_upgrades/*.json` (huit) | `deltas` (1) ; `maxLevel`, descriptions de `sharp` et `hardened` (4) ; éligibilité (5) | 1, 4, 5 |
| `lib/services/content_editor/entity_descriptor.dart` | Le gabarit de rune (1, 4, 5) ; le descripteur complet (8) | 1, 4, 5, 8 |
| `lib/tutorial/tutorial_data.dart`, `lib/tutorial/widgets/tutorial_merge_widget.dart` | La prose de la rareté (§5.4) | 2 |
| `lib/ui/widgets/ui_card.dart`, `lib/ui/widgets/ui_card/ui_card_helpers.dart`, `lib/ui/widgets/ui_card/card_compact_description.dart` | Les rendus Flutter sur l'applicateur (3) ; lignes de runes et emoji en donnée (4) | 3, 4 |
| `lib/game/components/card_component.dart`, `lib/game/components/widgets/card_text_renderer.dart` | Les rendus Flame sur l'applicateur, code mort supprimé (3) ; lignes de runes en donnée (4) | 3, 4 |
| `lib/tutorial/tutorial_engine.dart`, `lib/tutorial/widgets/tutorial_play_card_widget.dart` | Le tutoriel sur l'applicateur | 3 |
| `lib/ui/widgets/forge/forge_slot_row.dart`, `lib/ui/widgets/forge/forge_card_preview.dart` | La fente et la prévisualisation de la forge en donnée | 4 |
| `lib/ui/widgets/forge_upgrade_dialog.dart` | La fente reçoit la carte (4) ; l'offre par le prédicat (5) ; le tirage borné (6) ; sans repli `'sharp'` (7) | 4, 5, 6, 7 |
| `lib/game/controllers/shop_controller.dart` | L'offre par le prédicat (5) ; le tirage borné, sur la carte et ses runes déjà tirées, sans repli (6) | 5, 6 |
| `lib/ui/screens/rest_card_selection_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_localizations*.dart` | Le refus du feu, `forgeNoEligibleRune` | 7 |
| `lib/services/content_editor/known_values.dart` | `vocabularyOf` lit les motifs `clé[]` sous la clé nue | 8 |
| `test/unit/shipped_data.dart` *(nouveau, sans `main`)* | Runes et cartes livrées, lues par leur vrai `fromJson` | 1, 3, 5 |
| `test/unit/effective_card_test.dart` *(nouveau)* | L'applicateur, G1, G2 | 1, 2 |
| `test/unit/forge_upgrade_data_test.dart` *(nouveau)* | Le modèle de rune | 1, 4, 5 |
| `test/unit/rune_resolution_test.dart` *(nouveau)* | La résolution sur les vraies cartes et les vraies runes | 1, 2 |
| `test/unit/rune_eligibility_test.dart` *(nouveau)* | Le prédicat, condition par condition | 5 |
| `test/unit/forge_upgrades_catalog_test.dart` *(nouveau)* | Les huit runes livrées, la matrice de l'offre | 5 |
| `test/unit/rune_ids_in_code_test.dart` *(nouveau)* | Ni id de rune ni `rarityMultiplier` dans `lib/` | 7 |
| `test/widget/ui_card_values_test.dart` *(nouveau)* | Les rendus Flutter : chiffres et lignes de runes | 3, 4 |
| `test/widget/forge_upgrade_dialog_test.dart` *(nouveau)* | L'offre et les fentes du feu | 4, 5, 6 |
| `test/widget/rest_card_selection_screen_test.dart` *(nouveau)* | Le refus du feu | 7 |
| `test/unit/card_rarity_test.dart`, `stat_gains_characterization_test.dart`, `might_orientation_test.dart`, `deck_controller_test.dart`, `referential_integrity_test.dart` | Rareté ; runes jouées sur un registre qui les porte ; intégrité | 1, 2, 5 |
| `test/unit/forge_rune_rules_test.dart`, `decoupled_forge_test.dart`, `shop_controller_test.dart`, `test/widget/forge_fusion_screen_test.dart` | Fusion, descriptions, boutique, Forge de Fusion | 1, 4, 5, 6 |
| `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_merge_transition_test.dart`, `test/widget/hud_and_targeting_badge_test.dart`, `test/widget/ui_card_rune_sockets_test.dart` | Tutoriel ; `UiCard` | 2, 3, 4 |
| `test/unit/content_editor/entity_descriptor_test.dart`, `entity_validator_test.dart`, `field_kind_test.dart`, `known_values_test.dart`, `fixtures.dart` | L'éditeur | 1, 4, 5, 8 |

---


### Task 1: Le moteur lit la rune dans son fichier — `CardDelta`, l'applicateur, la résolution

Le cœur d'A1 et d'A2 : une rune déclare ses `deltas`, l'applicateur `EffectiveCard` calcule la carte telle qu'elle se joue, et `EffectResolver.resolveCard` confie chaque effet — ceux des runes d'abord — au registre de stratégies. Le `switch` des runes, le bloc élémentaire, le multiplicateur écrit en ligne et l'armure de rune à part disparaissent ; `GainSource.rune` perd ses deux producteurs et disparaît. Le multiplicateur de rareté reste celui d'aujourd'hui jusqu'à Task 2 (G1, G2) : il passe sur `CardRarity.multiplier`, que `CardInstance.rarityMultiplier` relaie à ses six autres lecteurs — les rendus et le tutoriel — jusqu'à Task 3. `valueMultiplier` reste lu par la description de la forge et le rendu Flame jusqu'à Task 4 : `sharp.json` et `hardened.json` le gardent, à côté de leurs `deltas`.

Changements de jeu de la tâche, voulus (spec §4.4, §4.8) : `sharp` et `hardened` donnent 15 % de la valeur de l'effet à la rareté de la carte par niveau, au moins +1 (D33) ; les statuts des runes élémentaires sont posés par `addStatus`, sans source, et rejoignent le statut que la cible porte déjà (A4 de la spec E0) ; le mana d'`eco` passe par `GainManaEffectStrategy` et fait entendre le son du gain de mana (A2) ; `hardened` sur une carte sans armure ne donne plus rien.

**Files:**
- Create: `lib/models/data/card_delta.dart`
- Create: `lib/models/effective_card.dart`
- Modify: `lib/models/data/card_data.dart:38-41` (après `forgeSlotBonus`)
- Modify: `lib/models/data/forge_upgrade_data.dart:1-3`, `:21-40`, `:42-45`, `:57-58`, `:63-64`, `:76-77`, `:94`
- Modify: `lib/models/card_instance.dart:1-2`, `:26-50`
- Modify: `lib/game/services/forge_rune_rules.dart:20-25`, `:34-55`, `:62-64`, `:73`
- Modify: `lib/game/services/effect_resolver.dart:8-11`, `:137-265`
- Modify: `lib/game/systems/stat_gains.dart:11-14`
- Modify: `lib/services/content_editor/entity_descriptor.dart:330-333`, `:355-357`
- Modify: les huit fichiers de `assets/data/forge_upgrades/` — une clé `deltas` avant `weight`
- Create: `test/unit/shipped_data.dart` (aide de test, sans `main`)
- Test: `test/unit/effective_card_test.dart`, `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_resolution_test.dart` *(nouveaux)*
- Test: `test/unit/card_rarity_test.dart:68` ; `test/unit/stat_gains_characterization_test.dart:17-23`, `:46-49`, `:116-119` ; `test/unit/might_orientation_test.dart:18`, `:126-130` ; `test/unit/deck_controller_test.dart:7`, `:444-451` ; `test/unit/forge_rune_rules_test.dart:53-69` ; `test/unit/referential_integrity_test.dart:1-8`, `:40-45` ; `test/unit/content_editor/entity_descriptor_test.dart:265-268` ; `test/unit/content_editor/entity_validator_test.dart:595` ; `test/unit/stat_gains_test.dart:20` (inchangé : sa boucle sur `GainSource.values` perd le cas `rune`)

**Interfaces:**
- Consumes: `EffectResolver.createStatus(String statusId, int value, int duration, {String? sourceId})`, tel qu'E0 l'a laissé ; les stratégies d'`effect_strategy.dart` et de `strategies.dart`, inchangées.
- Produces:
  - `sealed class CardDelta` (`lib/models/data/card_delta.dart`) — `static const List<String> typeNames` (`['percentBonus', 'addEffect', 'removeExhaust']`) ; `factory CardDelta.fromJson(Map<String, dynamic>)`, qui lève `FormatException` ; `Map<String, dynamic> toJson()`. Trois sortes : `PercentBonusDelta({required String effect, required int valuePercentPerLevel})` avec `int bonusFor(int base, int level)` — la seule écriture de la formule de D33 ; `AddEffectDelta({required String effect, required int valuePerLevel, String? statusId, int? durationPerLevel})` avec `CardEffect effectAt(int level)` ; `RemoveExhaustDelta()`.
  - `class EffectiveCard` (`lib/models/effective_card.dart`) — `List<CardEffect> addedEffects`, `List<CardEffect> effects` (alignée sur `CardData.effects`), `bool removesExhaust` ; `static EffectiveCard apply(CardData data, CardRarity rarity, Iterable<(CardDelta, int)> deltas)` ; `static Iterable<(CardDelta, int)> runeDeltas(List<String> runes, Iterable<ForgeUpgradeData> catalog)` ; `static EffectiveCard withRunes(CardData data, CardRarity rarity, List<String> runes)`, sur le catalogue de `GameDataRegistry.instance`.
  - `ForgeUpgradeData.deltas` (`List<CardDelta>`, défaut `const []` au constructeur, obligatoire et non vide dans le fichier) ; `static (String, int)? ForgeUpgradeData.parseRef(String ref)` ; `static Map<String, int> ForgeUpgradeData.levelsOf(Iterable<String> refs)` — l'analyseur unique, qui remplace `ForgeRuneRules._tierOf`.
  - `double get CardRarity.multiplier` ; `EffectiveCard get CardInstance.effective`.
  - Aide de test `test/unit/shipped_data.dart` : `ForgeUpgradeData shippedRune(String id)` ; `GameDataRegistry shippedRuneRegistry(List<String> runeIds, {List<CardData> cards = const []})`.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/shipped_data.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

/// Les entités telles que le jeu les livre, lues dans leur fichier par leur
/// vrai `fromJson`, l'id injecté comme le fait le chargeur : un test du moteur
/// de runes joue la donnée, pas une recopie (spec P-43 E1, §8).
Map<String, dynamic> _shipped(String path, String id) => {
      ...jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>,
      'id': id,
    };

ForgeUpgradeData shippedRune(String id) => ForgeUpgradeData.fromJson(
      _shipped('assets/data/forge_upgrades/$id.json', id),
    );

/// Construit — et installe, `GameDataRegistry` étant un singleton — un
/// registre qui ne porte que les runes livrées [runeIds] et les [cards].
GameDataRegistry shippedRuneRegistry(
  List<String> runeIds, {
  List<CardData> cards = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: cards,
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [for (final id in runeIds) shippedRune(id)],
    );
```

Create `test/unit/effective_card_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/effective_card.dart';

CardData _card(List<CardEffect> effects) => CardData(
      id: 'test_card',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: effects,
    );

CardEffect _damage(int value) => CardEffect(type: 'damage', value: value);

const _sharp = PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 15);
const _hardened = PercentBonusDelta(effect: 'armor', valuePercentPerLevel: 15);
const _burn = AddEffectDelta(
  effect: 'apply_status',
  valuePerLevel: 1,
  statusId: 'burn',
  durationPerLevel: 1,
);
const _draw = AddEffectDelta(effect: 'draw', valuePerLevel: 1);

List<int> _values(EffectiveCard card) => [for (final e in card.effects) e.value];

ForgeUpgradeData _rune(String id, List<CardDelta> deltas) => ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      deltas: deltas,
    );

/// L'applicateur : la carte telle qu'elle se joue (spec P-43 E1, §4.1, §4.2).
void main() {
  group('percentBonus', () {
    test('la table de D33 sur une carte commune', () {
      // Spec §4.8 : le bonus des niveaux 1 a 4 selon la valeur de l'effet.
      const expected = {
        7: [1, 2, 3, 4],
        8: [1, 2, 4, 5],
        10: [2, 3, 5, 6],
        12: [2, 4, 5, 7],
      };
      expected.forEach((base, bonuses) {
        for (var level = 1; level <= 4; level++) {
          final card = EffectiveCard.apply(
            _card([_damage(base)]),
            CardRarity.common,
            [(_sharp, level)],
          );
          expect(_values(card), [base + bonuses[level - 1]],
              reason: 'base $base, niveau $level');
        }
      });
    });

    test('la base est la valeur de l effet a la rarete de la carte', () {
      // Frappe : 6 en commune, 10 en epique, 12 en legendaire.
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(6)]), CardRarity.epic, [(_sharp, 1)])),
        [10 + 2],
      );
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(6)]), CardRarity.legendary, [(_sharp, 2)])),
        [12 + 4],
      );
    });

    test('l arithmetique est entiere : 15 % x 3 x 30 donne 14', () {
      // 0,15 x 3 x 30 vaut 13,499... en virgule flottante (spec P-43 E1, A7).
      expect(
        _values(EffectiveCard.apply(
            _card([_damage(30)]), CardRarity.common, [(_sharp, 3)])),
        [30 + 14],
      );
    });

    test('chaque effet du type vise est servi', () {
      expect(
        _values(EffectiveCard.apply(_card([_damage(6), _damage(10)]),
            CardRarity.common, [(_sharp, 1)])),
        [6 + 1, 10 + 2],
      );
    });

    test('un pourcentage ne touche que le type qu il vise', () {
      final card = _card([_damage(6), const CardEffect(type: 'armor', value: 5)]);
      expect(
        _values(EffectiveCard.apply(card, CardRarity.common, [(_hardened, 1)])),
        [6, 5 + 1],
      );
    });

    test('deux pourcentages sur un meme effet ne se composent pas', () {
      // Chacun sur la valeur a la rarete, 10 : +2 et +2, et non +2 puis
      // 15 % de 12.
      expect(
        _values(EffectiveCard.apply(_card([_damage(10)]), CardRarity.common,
            [(_sharp, 1), (_sharp, 1)])),
        [10 + 2 + 2],
      );
    });
  });

  group('addEffect', () {
    test('valeur et duree par niveau', () {
      final card = EffectiveCard.apply(
        _card([_damage(6)]),
        CardRarity.common,
        [(_burn, 2), (_draw, 1)],
      );
      expect(
        card.addedEffects.map((e) => (e.type, e.value, e.statusId, e.duration)),
        [('apply_status', 2, 'burn', 2), ('draw', 1, null, null)],
      );
    });

    test('ni multiplie par la rarete ni vise par un pourcentage', () {
      const strike = AddEffectDelta(effect: 'damage', valuePerLevel: 3);
      final card = EffectiveCard.apply(
        _card([_damage(6)]),
        CardRarity.legendary,
        [(strike, 1), (_sharp, 1)],
      );
      expect(card.addedEffects.single.value, 3);
      expect(_values(card), [12 + 2]);
    });
  });

  test('removeExhaust leve l epuisement, quel que soit le niveau', () {
    for (final level in [1, 3]) {
      expect(
        EffectiveCard.apply(_card(const []), CardRarity.common,
            [(const RemoveExhaustDelta(), level)]).removesExhaust,
        isTrue,
        reason: 'niveau $level',
      );
    }
    expect(
      EffectiveCard.apply(_card(const []), CardRarity.common, const [])
          .removesExhaust,
      isFalse,
    );
  });

  test('effects a la longueur et l ordre des effets de la donnee', () {
    final data = _card([
      _damage(6),
      const CardEffect(
          type: 'apply_status', value: 1, statusId: 'poison', duration: 2),
      const CardEffect(type: 'draw', value: 1),
    ]);
    final card = EffectiveCard.apply(
        data, CardRarity.common, [(_burn, 1), (_sharp, 1)]);
    expect(card.effects.map((e) => e.type), data.effects.map((e) => e.type));
  });

  test('apply ne lit aucune rune : des paires d une autre provenance suffisent',
      () {
    // La couture des evolutions de signature (vague 5) : un delta construit
    // hors de tout fichier de rune, sans catalogue.
    final fromElsewhere = <(CardDelta, int)>[
      (const PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 50), 2),
    ];
    expect(
      _values(EffectiveCard.apply(
          _card([_damage(6)]), CardRarity.common, fromElsewhere)),
      [6 + 6],
    );
  });

  group('runeDeltas', () {
    final catalog = [
      _rune('quick', const [_draw]),
      _rune('sharp', const [_sharp]),
    ];

    test('additionne les exemplaires, dans l ordre de premiere apparition', () {
      expect(
        EffectiveCard.runeDeltas(
            const ['quick:1', 'sharp:1', 'sharp:2'], catalog).toList(),
        [(_draw, 1), (_sharp, 3)],
      );
    });

    test('ignore une reference mal formee ou de niveau nul, et un id hors du '
        'catalogue', () {
      expect(
        EffectiveCard.runeDeltas(const ['sharp', 'sharp:0', 'legacy:2'], catalog),
        isEmpty,
      );
    });
  });
}
```

Create `test/unit/forge_upgrade_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'deltas': [
        {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
      ],
      ...overrides,
    };

Matcher _refused(String fragment) => throwsA(
      isA<FormatException>()
          .having((e) => e.message, 'message', contains(fragment)),
    );

/// Le modèle de rune (spec P-43 E1, §3.1, §3.3).
void main() {
  group('deltas', () {
    test('lit les trois sortes', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {'type': 'percentBonus', 'effect': 'armor', 'valuePercentPerLevel': 15},
          {
            'type': 'addEffect',
            'effect': 'apply_status',
            'valuePerLevel': 1,
            'statusId': 'burn',
            'durationPerLevel': 1,
          },
          {'type': 'removeExhaust'},
        ],
      }));

      final [percent, added, removed] = rune.deltas;
      expect(
        percent,
        isA<PercentBonusDelta>()
            .having((d) => d.effect, 'effect', 'armor')
            .having((d) => d.valuePercentPerLevel, 'valuePercentPerLevel', 15),
      );
      expect(
        added,
        isA<AddEffectDelta>()
            .having((d) => d.effect, 'effect', 'apply_status')
            .having((d) => d.valuePerLevel, 'valuePerLevel', 1)
            .having((d) => d.statusId, 'statusId', 'burn')
            .having((d) => d.durationPerLevel, 'durationPerLevel', 1),
      );
      expect(removed, isA<RemoveExhaustDelta>());
    });

    test('refuse une rune sans deltas', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('deltas')),
          _refused('deltas'));
    });

    test('refuse une liste de deltas vide', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'deltas': []})),
          _refused('deltas'));
    });

    test('refuse un type inconnu', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {'type': 'bonus'},
          ],
        })),
        _refused('bonus'),
      );
    });

    test('refuse un pourcentage sans effet vise', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {'type': 'percentBonus', 'valuePercentPerLevel': 15},
          ],
        })),
        _refused('effect'),
      );
    });

    test('refuse un pourcentage nul ou negatif', () {
      for (final percent in [0, -15]) {
        expect(
          () => ForgeUpgradeData.fromJson(_json({
            'deltas': [
              {
                'type': 'percentBonus',
                'effect': 'damage',
                'valuePercentPerLevel': percent,
              },
            ],
          })),
          _refused('valuePercentPerLevel'),
          reason: '$percent',
        );
      }
    });

    test('refuse un apply_status sans statusId', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {
              'type': 'addEffect',
              'effect': 'apply_status',
              'valuePerLevel': 1,
              'durationPerLevel': 1,
            },
          ],
        })),
        _refused('statusId'),
      );
    });

    test('refuse un apply_status sans durationPerLevel', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'deltas': [
            {
              'type': 'addEffect',
              'effect': 'apply_status',
              'valuePerLevel': 1,
              'statusId': 'burn',
            },
          ],
        })),
        _refused('durationPerLevel'),
      );
    });

    test('refuse statusId ou durationPerLevel sur un autre type d effet', () {
      for (final extra in [
        {'statusId': 'burn'},
        {'durationPerLevel': 1},
      ]) {
        expect(
          () => ForgeUpgradeData.fromJson(_json({
            'deltas': [
              {
                'type': 'addEffect',
                'effect': 'draw',
                'valuePerLevel': 1,
                ...extra,
              },
            ],
          })),
          _refused('apply_status'),
          reason: '$extra',
        );
      }
    });

    test('toJson fait l aller-retour', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {
            'type': 'addEffect',
            'effect': 'apply_status',
            'valuePerLevel': 1,
            'statusId': 'shock',
            'durationPerLevel': 1,
          },
          {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
          {'type': 'removeExhaust'},
        ],
      }));

      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(
        [for (final delta in restored.deltas) delta.toJson()],
        [for (final delta in rune.deltas) delta.toJson()],
      );
    });
  });

  group('references id:niveau', () {
    test('parseRef lit une reference, ou rien', () {
      expect(ForgeUpgradeData.parseRef('sharp:2'), ('sharp', 2));
      for (final bad in ['sharp', 'sharp:0', 'sharp:-1', 'sharp:x', 'sharp:1:2']) {
        expect(ForgeUpgradeData.parseRef(bad), isNull, reason: bad);
      }
    });

    test('levelsOf additionne les exemplaires dans l ordre de premiere '
        'apparition', () {
      final levels = ForgeUpgradeData.levelsOf(
          const ['quick:1', 'sharp:1', 'quick:2', 'sharp:2']);
      expect(levels.entries.map((e) => (e.key, e.value)),
          [('quick', 3), ('sharp', 3)]);
    });

    test('levelsOf ignore une reference mal formee ou de niveau nul', () {
      expect(
        ForgeUpgradeData.levelsOf(const ['sharp', 'sharp:0', 'sharp:x', 'eco:1']),
        {'eco': 1},
      );
    });
  });
}
```

Create `test/unit/rune_resolution_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les runes livrées, jouées sur les vraies cartes par
/// `EffectResolver.resolveCard` (spec P-43 E1, §4.4, §4.8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  late ProviderContainer container;
  late RunController run;
  late CombatController combat;
  late DeckNotifier deck;
  late String enemyId;

  // `setUpAll` : `GameDataRegistry` ecrit un singleton statique, un seul
  // registre par fichier.
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  void startAs(String heroId) =>
      run.startNewRun(registry.heroes.singleWhere((h) => h.id == heroId));

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
    // Le Paladin : ni Puissance ni critique au depart, les chiffres sont nets.
    startAs('paladin');
    final enemy = EnemyInstance(
      data: registry.enemies.first,
      stats: EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0),
    );
    enemyId = enemy.id;
    combat.state = CombatState(
      enemies: [enemy],
      selectedEnemyId: enemyId,
      turnPhase: TurnPhase.player,
    );
  });

  tearDown(() => container.dispose());

  CardInstance card(
    String id, {
    CardRarity? rarity,
    List<String> runes = const [],
  }) =>
      CardInstance(
        data: registry.cards.singleWhere((c) => c.id == id),
        rarity: rarity,
        forgeUpgrades: runes,
      );

  EntityStats hero() => run.currentState.heroStats;
  EntityStats enemy() => combat.currentState.enemies.single.stats;
  List<StatusEffect> enemyStatuses(String id) =>
      enemy().statuses.where((s) => s.id == id).toList();

  void play(CardInstance card) {
    // Assez de mana pour jouer plusieurs cartes dans un meme cas.
    run.updateState(run.currentState
        .copyWith(heroStats: hero().copyWith(currentMana: 9)));
    final played = EffectResolver.resolveCard(
      card,
      run,
      deck,
      combat,
      enemyId,
      container.read(effectRegistryProvider),
    );
    expect(played, isTrue);
  }

  group('Tranchant et Endurci : 15 % de la base par niveau, au moins +1', () {
    test('Tranchant 1 sur une Frappe commune : +1', () {
      play(card('strike_basic', runes: const ['sharp:1']));
      expect(enemy().currentPv, 100 - (6 + 1));
    });

    test('Tranchant 2 sur une Frappe legendaire : +4', () {
      play(card('strike_basic',
          rarity: CardRarity.legendary, runes: const ['sharp:2']));
      expect(enemy().currentPv, 100 - (12 + 4));
    });

    test('Endurci 1 sur une Defense : +1', () {
      play(card('defend_basic', runes: const ['hardened:1']));
      expect(hero().armure, 5 + 1);
    });

    test('Endurci 1 sur un Mur de Fer : +2', () {
      play(card('iron_wall', runes: const ['hardened:1']));
      expect(hero().armure, 10 + 2);
    });
  });

  group('les effets ajoutes passent par le registre de strategies', () {
    test('Veloce pioche une carte', () {
      final waiting = card('defend_basic');
      deck.state = deck.state.copyWith(drawPile: [waiting]);

      play(card('strike_basic', runes: const ['quick:1']));

      expect(deck.state.hand.map((c) => c.uniqueId), [waiting.uniqueId]);
    });

    test('Econome rend un mana', () {
      play(card('strike_basic', runes: const ['eco:1']));
      expect(hero().currentMana, 9 - 1 + 1);
    });
  });

  group('les statuts des runes : addStatus, sans source (spec E0, A4)', () {
    test('Coup de Tonnerre et Surcharge, trois fois : 5, 7 puis 9 degats', () {
      // Chaque choc de rune rejoint le choc en cours, que `DamagePipeline`
      // lit : +3 et +5 au lieu de +2 et +3.
      final hp = <int>[];
      for (var i = 0; i < 3; i++) {
        play(card('thunder_clap', runes: const ['shocking:1']));
        hp.add(enemy().currentPv);
      }
      expect(hp, [100 - 5, 100 - 5 - 7, 100 - 5 - 7 - 9]);
      expect(enemyStatuses('shock').map((s) => (s.value, s.sourceId)),
          [(6, null)]);
    });

    test('Brulant 2, joue deux fois : une brulure de 4 pour 2 tours', () {
      for (var i = 0; i < 2; i++) {
        play(card('strike_basic', runes: const ['burning:2']));
      }
      expect(
        enemyStatuses('burn').map((s) => (s.value, s.duration, s.sourceId)),
        [(4, 2, null)],
      );
    });

    test('Congelant, joue deux fois : une seule entree de gel', () {
      for (var i = 0; i < 2; i++) {
        play(card('strike_basic', runes: const ['freezing:1']));
      }
      expect(enemyStatuses('freeze'), hasLength(1));
    });

    test('Boule de Feu et Brulant 1 : une brulure de 3 pour 2 tours', () {
      // La rune pose avant la carte, dont la brulure rejoint la sienne.
      play(card('fireball', runes: const ['burning:1']));
      expect(enemyStatuses('burn').map((s) => (s.value, s.duration)), [(3, 2)]);
    });
  });

  test('le Berserker convertit en une fois l armure de la carte et celle de '
      'la rune', () {
    // Defense (5) et Endurci 1 (+1) : un seul gain de 6, converti a 0,5.
    startAs('berserker');

    play(card('defend_basic', runes: const ['hardened:1']));

    expect(hero().armure, 0);
    expect(
      hero().statuses.where((s) => s.id == 'might').map((s) => s.value),
      [3],
    );
  });
}
```

In `test/unit/card_rarity_test.dart`, replace:

```dart
  group('CardRarity.isAcquirable', () {
```

with:

```dart
  group('CardRarity.multiplier', () {
    test('un multiplicateur par palier, 1 hors de l echelle', () {
      expect(
        [for (final rarity in _ladder) rarity.multiplier],
        [1.0, 1.2, 1.4, 1.6, 2.0],
      );
      expect(CardRarity.unique.multiplier, 1.0);
    });
  });

  group('CardRarity.isAcquirable', () {
```

In `test/unit/stat_gains_characterization_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/status_effect.dart';

/// Fige le comportement des gains d'armure, de mana et de puissance tel qu'il
/// était avant leur passage par `StatGains` (spec P-41, §4.1). Ces tests
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu. Une seule valeur a
/// changé depuis, voulue : Armure du Berserker avec de la Maîtrise (P-49).
```

with:

```dart
import 'package:roguelike_card_game/models/status_effect.dart';

import 'shipped_data.dart';

/// Fige le comportement des gains d'armure, de mana et de puissance tel qu'il
/// était avant leur passage par `StatGains` (spec P-41, §4.1). Ces tests
/// passent sur le code d'origine et restent inchangés après la conversion :
/// c'est la preuve que le lot A ne change rien au jeu. Deux valeurs ont changé
/// depuis, voulues : Armure du Berserker avec de la Maîtrise (P-49), et
/// Endurci sur une carte sans armure, qui ne donne plus rien (P-43 E1).
```

Then replace:

```dart
  late ProviderContainer container;
  late RunController run;

  setUp(() {
```

with:

```dart
  late ProviderContainer container;
  late RunController run;

  // Les runes que ces cas jouent, telles que le jeu les livre : le moteur les
  // lit dans le registre (spec P-43 E1, §4.4).
  setUpAll(() => shippedRuneRegistry(const ['hardened', 'eco']));

  setUp(() {
```

Then replace:

```dart
    test('rune hardened sur une carte sans effet d armure', () {
      play(card(CardType.attack, const [], runes: const ['hardened:1']));
      expect(heroStats().armure, 2);
    });
```

with:

```dart
    // Endurci ne vise que l'armure que la carte donne déjà (D61) : sur une
    // carte sans effet d'armure, elle ne donne plus rien (spec P-43 E1, §4.4).
    test('rune hardened sur une carte sans effet d armure : aucune armure', () {
      play(card(CardType.attack, const [], runes: const ['hardened:1']));
      expect(heroStats().armure, 0);
    });
```

In `test/unit/might_orientation_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/status_effect.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/status_effect.dart';

import 'shipped_data.dart';
```

Then replace:

```dart
    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      run.startNewRun(mage);
```

with:

```dart
    setUp(() {
      // Brûlant, tel que le jeu le livre : le moteur lit la rune dans le
      // registre (spec P-43 E1, §4.4).
      shippedRuneRegistry(const ['burning']);
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
      run.startNewRun(mage);
```

In `test/unit/deck_controller_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';

import 'shipped_data.dart';
```

Then replace:

```dart
  group('DeckNotifier.playCard — epuisement', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(deckProvider.notifier);
    });
```

with:

```dart
  group('DeckNotifier.playCard — epuisement', () {
    late ProviderContainer container;
    late DeckNotifier notifier;

    setUp(() {
      // Persistant, tel que le jeu le livre : l'épuisement lit la donnée de
      // la rune, plus son id (spec P-43 E1, §4.5).
      shippedRuneRegistry(const ['enduring']);
      container = ProviderContainer();
      notifier = container.read(deckProvider.notifier);
    });
```

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
    test('une rune est cumulable par defaut', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
      });
      expect(rune.stackable, isTrue);
    });

    test('le JSON declare une rune non cumulable, et toJson la conserve', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'stackable': false,
      });
      expect(rune.stackable, isFalse);
      expect(ForgeUpgradeData.fromJson(rune.toJson()).stackable, isFalse);
    });
```

with:

```dart
    test('une rune est cumulable par defaut', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'sharp',
        'pools': ['common'],
        'deltas': [
          {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
        ],
      });
      expect(rune.stackable, isTrue);
    });

    test('le JSON declare une rune non cumulable, et toJson la conserve', () {
      final rune = ForgeUpgradeData.fromJson({
        'id': 'enduring',
        'pools': ['rare'],
        'stackable': false,
        'deltas': [
          {'type': 'removeExhaust'},
        ],
      });
      expect(rune.stackable, isFalse);
      expect(ForgeUpgradeData.fromJson(rune.toJson()).stackable, isFalse);
    });
```

In `test/unit/referential_integrity_test.dart`, replace:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategies.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
```

with:

```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/effect_resolver.dart';
import 'package:roguelike_card_game/game/services/effects/effect_strategy.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_strategies.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le type d'effet qu'un delta nomme, s'il en nomme un.
String? _effectOf(CardDelta delta) => switch (delta) {
      PercentBonusDelta(:final effect) => effect,
      AddEffectDelta(:final effect) => effect,
      RemoveExhaustDelta() => null,
    };
```

Then replace:

```dart
        if (!PassiveStrategies.byEffectType.containsKey(passive.effectType))
          '${passive.id} → effectType "${passive.effectType}" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
```

with:

```dart
        if (!PassiveStrategies.byEffectType.containsKey(passive.effectType))
          '${passive.id} → effectType "${passive.effectType}" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Un type d'effet que nomme une rune et qu'aucune stratégie ne résout ne
  // ferait rien en jeu (spec P-43 E1, A13).
  test('chaque type d effet que nomme une rune a sa strategie', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final strategies = container.read(effectRegistryProvider);

    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final delta in rune.deltas)
          if (_effectOf(delta) case final type?
              when strategies.get(type) == null)
            '${rune.id} → type d effet "$type" sans stratégie',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque statut que pose une rune est fabrique par createStatus', () {
    final statuses = {
      for (final rune in registry.forgeUpgrades)
        for (final delta in rune.deltas)
          if (delta case AddEffectDelta(:final statusId?)) statusId,
    };
    expect(statuses, isNotEmpty, reason: 'aucune rune ne pose de statut');

    final offenders = [
      for (final statusId in statuses)
        if (EffectResolver.createStatus(statusId, 1, 1) == null)
          'statut "$statusId" que createStatus ne fabrique pas',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:

```dart
        'valueMultiplier',
        'weight',
        'emoji',
      },
```

with:

```dart
        'valueMultiplier',
        'deltas',
        'weight',
        'emoji',
      },
```

In `test/unit/content_editor/entity_validator_test.dart`, replace:

```dart
            mechanics: '{"pools": ["common"], "color": "$color"}',
```

with:

```dart
            mechanics: '{"pools": ["common"], "color": "$color", '
                '"deltas": [{"type": "removeExhaust"}]}',
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/effective_card_test.dart test/unit/forge_upgrade_data_test.dart test/unit/rune_resolution_test.dart`
Expected: échec à la compilation — `card_delta.dart` et `effective_card.dart` n'existent pas, `ForgeUpgradeData` n'a ni `deltas`, ni `parseRef`, ni `levelsOf`.

- [ ] **Step 3: `CardDelta` et `CardRarity.multiplier`**

Create `lib/models/data/card_delta.dart`:

```dart
import 'dart:math' show max;

import 'card_data.dart';

/// Une opération sur une carte, déclarée par niveau : ce qu'une rune fait, en
/// donnée (spec P-43 E1, A1, §4.1).
///
/// Le vocabulaire est **fermé** : une sorte neuve s'écrit ici une fois, par
/// mécanisme, avec le lecteur de son lot — jamais un `case` par rune.
/// L'applicateur (`EffectiveCard.apply`) reçoit des paires *(delta, niveau)* ;
/// une rune en fournit par `EffectiveCard.runeDeltas`, et la vague 5 y
/// traduira de même les évolutions de signature.
sealed class CardDelta {
  const CardDelta();

  /// Les `type` qu'un fichier peut déclarer.
  static const typeNames = ['percentBonus', 'addEffect', 'removeExhaust'];

  /// Lit une entrée de `deltas`. Lève `FormatException` sur un type inconnu ou
  /// un paramètre manquant : `GameDataLoader` accumule le refus.
  factory CardDelta.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    return switch (type) {
      'percentBonus' => PercentBonusDelta(
          effect: _text(json, 'effect'),
          valuePercentPerLevel: _positive(json, 'valuePercentPerLevel'),
        ),
      'addEffect' => AddEffectDelta._fromJson(json),
      'removeExhaust' => const RemoveExhaustDelta(),
      _ => throw FormatException(
          'deltas.type : valeur "$type" inconnue — attendu : '
          '${typeNames.join(', ')}',
        ),
    };
  }

  Map<String, dynamic> toJson();

  static String _text(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('deltas.$key : texte obligatoire — reçu : $value');
    }
    return value;
  }

  static int _positive(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int || value <= 0) {
      throw FormatException(
        'deltas.$key : entier strictement positif obligatoire — reçu : $value',
      );
    }
    return value;
  }
}

/// Chaque effet **propre** de la carte de type [effect] gagne un pourcentage
/// de sa valeur à la rareté de la carte (D33) : `sharp`, `hardened`.
final class PercentBonusDelta extends CardDelta {
  const PercentBonusDelta({
    required this.effect,
    required this.valuePercentPerLevel,
  });

  final String effect;
  final int valuePercentPerLevel;

  /// Le bonus au niveau [level] — total des exemplaires — sur la valeur
  /// [base] : `p × L × B` %, arrondi au plus proche, la demie vers le haut, en
  /// arithmétique entière, et au moins [level] (D33, spec P-43 E1, A7). La
  /// seule écriture de la formule.
  int bonusFor(int base, int level) =>
      max((valuePercentPerLevel * level * base + 50) ~/ 100, level);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'percentBonus',
        'effect': effect,
        'valuePercentPerLevel': valuePercentPerLevel,
      };
}

/// Ajoute à la carte un effet de valeur `valuePerLevel × L` — et, pour un
/// `apply_status`, de durée `durationPerLevel × L` —, résolu avant ceux de la
/// carte, jamais multiplié par la rareté ni visé par un pourcentage : `quick`,
/// `eco`, les trois runes élémentaires.
final class AddEffectDelta extends CardDelta {
  const AddEffectDelta({
    required this.effect,
    required this.valuePerLevel,
    this.statusId,
    this.durationPerLevel,
  });

  /// `statusId` et `durationPerLevel` sont exigés pour un `apply_status`, et
  /// refusés pour tout autre type d'effet.
  factory AddEffectDelta._fromJson(Map<String, dynamic> json) {
    final effect = CardDelta._text(json, 'effect');
    final valuePerLevel = CardDelta._positive(json, 'valuePerLevel');
    if (effect != 'apply_status') {
      if (json.containsKey('statusId') || json.containsKey('durationPerLevel')) {
        throw FormatException(
          'deltas : statusId et durationPerLevel ne valent que pour '
          'apply_status — reçus pour "$effect"',
        );
      }
      return AddEffectDelta(effect: effect, valuePerLevel: valuePerLevel);
    }
    return AddEffectDelta(
      effect: effect,
      valuePerLevel: valuePerLevel,
      statusId: CardDelta._text(json, 'statusId'),
      durationPerLevel: CardDelta._positive(json, 'durationPerLevel'),
    );
  }

  final String effect;
  final int valuePerLevel;
  final String? statusId;
  final int? durationPerLevel;

  /// L'effet ajouté au niveau [level].
  CardEffect effectAt(int level) {
    final duration = durationPerLevel;
    return CardEffect(
      type: effect,
      value: valuePerLevel * level,
      statusId: statusId,
      duration: duration == null ? null : duration * level,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'addEffect',
        'effect': effect,
        'valuePerLevel': valuePerLevel,
        if (statusId != null) 'statusId': statusId,
        if (durationPerLevel != null) 'durationPerLevel': durationPerLevel,
      };
}

/// La carte ne s'épuise plus, quel que soit le niveau (ADR-094 D4) :
/// `enduring`.
final class RemoveExhaustDelta extends CardDelta {
  const RemoveExhaustDelta();

  @override
  Map<String, dynamic> toJson() => {'type': 'removeExhaust'};
}
```

In `lib/models/data/card_data.dart`, replace:

```dart
        CardRarity.legendary => 4,
      };

  /// Une carte de cette rareté peut-elle entrer dans le deck en cours de run :
```

with:

```dart
        CardRarity.legendary => 4,
      };

  /// Le multiplicateur de valeur de cette rareté, que l'applicateur lit
  /// (`EffectiveCard`). 1,0 pour `unique`, hors de l'échelle.
  double get multiplier => switch (this) {
        CardRarity.common || CardRarity.unique => 1.0,
        CardRarity.uncommon => 1.2,
        CardRarity.rare => 1.4,
        CardRarity.epic => 1.6,
        CardRarity.legendary => 2.0,
      };

  /// Une carte de cette rareté peut-elle entrer dans le deck en cours de run :
```

- [ ] **Step 4: Le modèle de rune — `deltas` et l'analyseur unique des références**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
import 'package:flutter/foundation.dart';
import 'game_data_registry.dart';
import '../missing_save_item.dart';
```

with:

```dart
import 'package:flutter/foundation.dart';
import 'card_delta.dart';
import 'game_data_registry.dart';
import '../missing_save_item.dart';
```

Then replace:

```dart
  final int valueMultiplier;
  final int weight;
  final String emoji;

  const ForgeUpgradeData({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.color,
    required this.pools,
    this.eligibleCardTypes,
    this.requiresExhaust = false,
    this.stackable = true,
    this.valueMultiplier = 1,
    this.weight = 10,
    this.emoji = '🔮',
  });
```

with:

```dart
  final int valueMultiplier;

  /// Ce que fait la rune : des sortes de delta, déclarées par niveau (spec
  /// P-43 E1, A1, §4.1). Obligatoire et non vide dans le fichier ; le
  /// constructeur en laisse aux tests une liste vide, qui ne fait rien.
  final List<CardDelta> deltas;
  final int weight;
  final String emoji;

  const ForgeUpgradeData({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.color,
    required this.pools,
    this.eligibleCardTypes,
    this.requiresExhaust = false,
    this.stackable = true,
    this.valueMultiplier = 1,
    this.deltas = const [],
    this.weight = 10,
    this.emoji = '🔮',
  });
```

Then replace:

```dart
  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    return ForgeUpgradeData(
      id: json['id'] as String,
      nameEn: json['name_en'] as String? ?? '',
```

with:

```dart
  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ForgeUpgradeData(
      id: id,
      nameEn: json['name_en'] as String? ?? '',
```

Then replace:

```dart
      valueMultiplier: json['valueMultiplier'] as int? ?? 1,
      weight: json['weight'] as int? ?? 10,
```

with:

```dart
      valueMultiplier: json['valueMultiplier'] as int? ?? 1,
      deltas: _readDeltas(id, json['deltas']),
      weight: json['weight'] as int? ?? 10,
```

Then replace:

```dart
  Map<String, dynamic> toJson() {
    return {
```

with:

```dart
  static List<CardDelta> _readDeltas(String id, Object? raw) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException(
        '$id : deltas doit être une liste non vide — reçu : $raw',
      );
    }
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          CardDelta.fromJson(entry)
        else
          throw FormatException('$id : deltas porte "$entry", pas un objet'),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
```

Then replace:

```dart
      'valueMultiplier': valueMultiplier,
      'weight': weight,
```

with:

```dart
      'valueMultiplier': valueMultiplier,
      'deltas': [for (final delta in deltas) delta.toJson()],
      'weight': weight,
```

Then replace:

```dart
  static ForgeUpgradeData? getById(String id) {
```

with:

```dart
  /// Lit **une** référence `id:niveau` : `(id, niveau)`, ou `null` si elle est
  /// mal formée ou de niveau nul. L'unique analyseur des références de rune
  /// (ADR-094 D5) : toute règle qui lit un niveau passe par lui ou par
  /// [levelsOf].
  static (String, int)? parseRef(String ref) {
    final parts = ref.split(':');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[1]);
    return level != null && level > 0 ? (parts[0], level) : null;
  }

  /// Les niveaux de [refs], additionnés par id dans l'ordre de leur première
  /// apparition — le niveau que joue le moteur (D75) ; une référence que
  /// [parseRef] refuse est ignorée.
  static Map<String, int> levelsOf(Iterable<String> refs) {
    final levels = <String, int>{};
    for (final ref in refs) {
      final parsed = parseRef(ref);
      if (parsed == null) continue;
      final (id, level) = parsed;
      levels[id] = (levels[id] ?? 0) + level;
    }
    return levels;
  }

  static ForgeUpgradeData? getById(String id) {
```

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
/// Règles de combinaison des runes de forge, notées `id:tier`.
///
/// La Forge de Fusion et la fusion 3→1 additionnent les tiers des runes de
/// même id. Une rune non cumulable (`ForgeUpgradeData.stackable`) n'a pas de
/// tier qui vaille : elle n'est jamais proposée à la fusion, et une fusion 3→1
/// n'en garde qu'un exemplaire, au tier 1.
```

with:

```dart
/// Règles de combinaison des runes de forge, notées `id:tier`.
///
/// La Forge de Fusion et la fusion 3→1 additionnent les tiers des runes de
/// même id. Une rune non cumulable (`ForgeUpgradeData.stackable`) n'a pas de
/// tier qui vaille : elle n'est jamais proposée à la fusion, et une fusion 3→1
/// n'en garde qu'un exemplaire, au tier 1. Les références se lisent par
/// l'analyseur unique du modèle, `ForgeUpgradeData.parseRef` (ADR-094 D5).
```

Then replace:

```dart
  /// Tier d'une référence `id:tier`, ou `null` si elle est mal formée ou de
  /// tier nul : les deux combinaisons l'ignorent alors de la même façon.
  static int? _tierOf(String rune) {
    final parts = rune.split(':');
    if (parts.length != 2) return null;
    final tier = int.tryParse(parts[1]);
    return tier != null && tier > 0 ? tier : null;
  }

  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1.
  static List<String> consolidate(Iterable<String> runes) {
    final tiers = <String, int>{};
    for (final rune in runes) {
      final tier = _tierOf(rune);
      if (tier == null) continue;
      final id = rune.split(':').first;
      tiers[id] = isStackable(id) ? (tiers[id] ?? 0) + tier : 1;
    }
    return [for (final entry in tiers.entries) '${entry.key}:${entry.value}'];
  }
```

with:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée.
  static List<String> consolidate(Iterable<String> runes) => [
        for (final MapEntry(key: id, value: tier)
            in ForgeUpgradeData.levelsOf(runes).entries)
          '$id:${isStackable(id) ? tier : 1}',
      ];
```

Then replace:

```dart
    for (final rune in card.forgeUpgrades) {
      if (_tierOf(rune) == null) continue;
      groups.putIfAbsent(rune.split(':').first, () => []).add(rune);
```

with:

```dart
    for (final rune in card.forgeUpgrades) {
      final parsed = ForgeUpgradeData.parseRef(rune);
      if (parsed == null) continue;
      groups.putIfAbsent(parsed.$1, () => []).add(rune);
```

Then replace:

```dart
        totalTier: runes.fold(0, (sum, rune) => sum + (_tierOf(rune) ?? 0)),
```

with:

```dart
        totalTier: runes.fold(
          0,
          (sum, rune) => sum + (ForgeUpgradeData.parseRef(rune)?.$2 ?? 0),
        ),
```

- [ ] **Step 5: L'applicateur et l'instance**

Create `lib/models/effective_card.dart`:

```dart
import 'data/card_data.dart';
import 'data/card_delta.dart';
import 'data/forge_upgrade_data.dart';
import 'data/game_data_registry.dart';

/// La carte telle qu'elle se joue : ses effets à sa rareté, ses runes
/// appliquées. Le moteur la lit, et lui seul calcule ces valeurs (spec P-43
/// E1, §4.2).
class EffectiveCard {
  const EffectiveCard._({
    required this.addedEffects,
    required this.effects,
    required this.removesExhaust,
  });

  /// Les effets que les deltas ajoutent, résolus avant ceux de la carte.
  final List<CardEffect> addedEffects;

  /// Les effets propres de la carte, à leur valeur jouée, alignés un à un sur
  /// `CardData.effects` : un rendu peut les lire en regard.
  final List<CardEffect> effects;

  /// Vrai si un delta lève l'épuisement de la carte.
  final bool removesExhaust;

  /// La couture commune aux runes et, en vague 5, aux évolutions de
  /// signature : une fonction pure, qui ne lit ni registre ni rune — elle
  /// reçoit des paires *(delta, niveau)*.
  static EffectiveCard apply(
    CardData data,
    CardRarity rarity,
    Iterable<(CardDelta, int)> deltas,
  ) {
    final atRarity = [
      for (final effect in data.effects) _atRarity(effect, rarity),
    ];
    final effects = List<CardEffect>.of(atRarity);
    final added = <CardEffect>[];
    var removesExhaust = false;

    for (final (delta, level) in deltas) {
      switch (delta) {
        case PercentBonusDelta():
          // Sur la valeur à la rareté, jamais sur un bonus déjà ajouté : deux
          // pourcentages sur un même effet ne se composent pas.
          for (var i = 0; i < effects.length; i++) {
            if (effects[i].type != delta.effect) continue;
            effects[i] = _withValue(
              effects[i],
              effects[i].value + delta.bonusFor(atRarity[i].value, level),
            );
          }
        case AddEffectDelta():
          added.add(delta.effectAt(level));
        case RemoveExhaustDelta():
          removesExhaust = true;
      }
    }

    return EffectiveCard._(
      addedEffects: List.unmodifiable(added),
      effects: List.unmodifiable(effects),
      removesExhaust: removesExhaust,
    );
  }

  /// Les runes d'une carte traduites en paires *(delta, niveau)* : les
  /// exemplaires d'un même id additionnés (D75, A7), dans l'ordre de leur
  /// première apparition. Une référence mal formée ou de niveau nul est
  /// ignorée ; un id absent du catalogue n'a pas de delta.
  static Iterable<(CardDelta, int)> runeDeltas(
    List<String> runes,
    Iterable<ForgeUpgradeData> catalog,
  ) sync* {
    for (final MapEntry(key: id, value: level)
        in ForgeUpgradeData.levelsOf(runes).entries) {
      final rune = catalog.where((r) => r.id == id).firstOrNull;
      if (rune == null) continue;
      for (final delta in rune.deltas) {
        yield (delta, level);
      }
    }
  }

  /// [data] à [rarity], portant [runes], sur le catalogue du registre — comme
  /// `ForgeUpgradeData.getById`.
  static EffectiveCard withRunes(
    CardData data,
    CardRarity rarity,
    List<String> runes,
  ) =>
      apply(
        data,
        rarity,
        runeDeltas(runes, GameDataRegistry.instance?.forgeUpgrades ?? const []),
      );

  static CardEffect _atRarity(CardEffect effect, CardRarity rarity) =>
      _withValue(effect, (effect.value * rarity.multiplier).round());

  static CardEffect _withValue(CardEffect effect, int value) => CardEffect(
        type: effect.type,
        value: value,
        statusId: effect.statusId,
        duration: effect.duration,
      );
}
```

In `lib/models/card_instance.dart`, replace:

```dart
import 'package:uuid/uuid.dart';
import 'data/card_data.dart';
```

with:

```dart
import 'package:uuid/uuid.dart';
import 'data/card_data.dart';
import 'effective_card.dart';
```

Then replace:

```dart
  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte `isExhaust` l'est sauf si elle porte la rune `enduring`,
  /// **quel que soit son tier** : la fusion de runes et la fusion 3→1 en ont
  /// produit des tiers supérieurs, qu'une sauvegarde peut encore contenir.
  bool get exhaustsOnPlay =>
      data.type == CardType.power ||
      (data.isExhaust &&
          !forgeUpgrades.any((rune) => rune.split(':').first == 'enduring'));

  double get rarityMultiplier {
    switch (rarity) {
      case CardRarity.common:
        return 1.0;
      case CardRarity.uncommon:
        return 1.2;
      case CardRarity.rare:
        return 1.4;
      case CardRarity.epic:
        return 1.6;
      case CardRarity.legendary:
        return 2.0;
      case CardRarity.unique:
        return 1.0;
    }
  }
```

with:

```dart
  /// La carte telle qu'elle se joue — sa rareté et ses runes appliquées, sur
  /// le catalogue du registre (spec P-43 E1, §4.2).
  EffectiveCard get effective =>
      EffectiveCard.withRunes(data, rarity, forgeUpgrades);

  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte `isExhaust` l'est sauf si une de ses runes lève l'épuisement,
  /// **quel que soit son niveau** (ADR-094 D4) : c'est la donnée de la rune
  /// qui le dit (`removeExhaust`), plus son id.
  bool get exhaustsOnPlay =>
      data.type == CardType.power ||
      (data.isExhaust && !effective.removesExhaust);

  double get rarityMultiplier => rarity.multiplier;
```

- [ ] **Step 6: La résolution — plus de `switch`, un seul chemin d'effets**

In `lib/game/services/effect_resolver.dart`, replace:

```dart
import '../systems/stat_gains.dart';
import '../systems/power_rules.dart';
import 'effects/effect_strategy.dart';
import '../game_constants.dart';
```

with:

```dart
import 'effects/effect_strategy.dart';
```

Then replace:

```dart
    runController.consumeResource(mana: card.currentCost);

    int extraDamage = 0;
    int extraArmor = 0;
    int extraDraw = 0;
    int extraMana = 0;
    int elementBurn = 0;
    int elementFreeze = 0;
    int elementShock = 0;

    for (var upgrade in card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      switch (id) {
        case 'sharp':
          extraDamage += 2 * k;
          break;
        case 'hardened':
          extraArmor += 2 * k;
          break;
        case 'quick':
          extraDraw += k;
          break;
        case 'eco':
          extraMana += k;
          break;
        case 'burning':
          elementBurn += k;
          break;
        case 'freezing':
          elementFreeze += k;
          break;
        case 'shocking':
          elementShock += k;
          break;
      }
    }

    if (extraDraw > 0) {
      deckController.drawCards(extraDraw, maxHandSize: GameConstants.maxHandSize);
    }
    if (extraMana > 0) {
      runController.grant(
        StatGain(GainResource.mana, extraMana, GainSource.rune),
      );
    }

    // Apply elemental statuses if this is an Attack card
    if (card.data.type == CardType.attack) {
      final List<StatusEffect> extraStatuses = [];
      // Même règle qu'un statut posé par la carte (`PowerRules`) : ces runes
      // sont résolues ici, hors du registre de stratégies.
      final bonus =
          runController.currentState.heroStats.statusBonusFor(card.data.target);
      if (elementBurn > 0) {
        final st = createStatus('burn', elementBurn + bonus, elementBurn);
        if (st != null) extraStatuses.add(st);
      }
      if (elementFreeze > 0) {
        final st = createStatus('freeze', elementFreeze + bonus, elementFreeze);
        if (st != null) extraStatuses.add(st);
      }
      if (elementShock > 0) {
        final st = createStatus('shock', elementShock + bonus, elementShock);
        if (st != null) extraStatuses.add(st);
      }

      if (extraStatuses.isNotEmpty) {
        if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
          final enemyIndex = combatController.currentState.enemies
              .indexWhere((e) => e.id == selectedEnemyId);
          if (enemyIndex != -1) {
            final enemy = combatController.currentState.enemies[enemyIndex];
            combatController.updateEnemyStats(
              enemy.id,
              enemy.stats.copyWith(
                statuses: [...enemy.stats.statuses, ...extraStatuses],
              ),
            );
          }
        } else if (card.data.target == CardTarget.allEnemies) {
          for (var enemy in combatController.currentState.enemies) {
            combatController.updateEnemyStats(
              enemy.id,
              enemy.stats.copyWith(
                statuses: [...enemy.stats.statuses, ...extraStatuses],
              ),
            );
          }
        }
      }
    }

    for (var effect in card.data.effects) {
      final int baseValue = effect.value;
      int scaledValue = (baseValue * card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }

      final strategy = registry.get(effect.type);
      if (strategy != null) {
        strategy.resolve(
          card: card,
          effect: effect,
          scaledValue: scaledValue,
          runController: runController,
          deckController: deckController,
          combatController: combatController,
          selectedEnemyId: selectedEnemyId,
        );
      }
    }

    final hasArmorEffect = card.data.effects.any((e) => e.type == 'armor');
    if (!hasArmorEffect && extraArmor > 0) {
      runController.grant(
        StatGain(GainResource.armor, extraArmor, GainSource.rune),
      );
    }

    return true;
  }
}
```

with:

```dart
    runController.consumeResource(mana: card.currentCost);

    // Les effets que les runes ajoutent d'abord, puis ceux de la carte, à leur
    // valeur jouée — rareté et runes comprises : l'applicateur est seul à la
    // calculer, et les stratégies du registre seules à résoudre un effet,
    // ceux des runes compris (spec P-43 E1, A2, §4.4). Les statuts des runes
    // sont donc posés par `addStatus`, sans source (spec P-43 E0, A4).
    final effective = card.effective;
    for (final effect in [...effective.addedEffects, ...effective.effects]) {
      registry.get(effect.type)?.resolve(
            card: card,
            effect: effect,
            scaledValue: effect.value,
            runController: runController,
            deckController: deckController,
            combatController: combatController,
            selectedEnemyId: selectedEnemyId,
          );
    }

    return true;
  }
}
```

In `lib/game/systems/stat_gains.dart`, replace:

```dart
enum GainSource {
  card,
  rune,
  passive,
```

with:

```dart
enum GainSource {
  card,
  passive,
```

- [ ] **Step 7: Les huit fichiers de rune déclarent leurs `deltas`**

In `assets/data/forge_upgrades/sharp.json`, replace:

```json
  "valueMultiplier": 2,
  "weight": 100,
```

with:

```json
  "valueMultiplier": 2,
  "deltas": [
    {
      "type": "percentBonus",
      "effect": "damage",
      "valuePercentPerLevel": 15
    }
  ],
  "weight": 100,
```

In `assets/data/forge_upgrades/hardened.json`, replace:

```json
  "valueMultiplier": 2,
  "weight": 100,
```

with:

```json
  "valueMultiplier": 2,
  "deltas": [
    {
      "type": "percentBonus",
      "effect": "armor",
      "valuePercentPerLevel": 15
    }
  ],
  "weight": 100,
```

In `assets/data/forge_upgrades/quick.json`, replace:

```json
  "weight": 60,
```

with:

```json
  "deltas": [
    {
      "type": "addEffect",
      "effect": "draw",
      "valuePerLevel": 1
    }
  ],
  "weight": 60,
```

In `assets/data/forge_upgrades/eco.json`, replace:

```json
  "weight": 40,
```

with:

```json
  "deltas": [
    {
      "type": "addEffect",
      "effect": "gain_mana",
      "valuePerLevel": 1
    }
  ],
  "weight": 40,
```

In `assets/data/forge_upgrades/burning.json`, replace:

```json
  "weight": 80,
```

with:

```json
  "deltas": [
    {
      "type": "addEffect",
      "effect": "apply_status",
      "valuePerLevel": 1,
      "statusId": "burn",
      "durationPerLevel": 1
    }
  ],
  "weight": 80,
```

In `assets/data/forge_upgrades/freezing.json`, replace:

```json
  "weight": 80,
```

with:

```json
  "deltas": [
    {
      "type": "addEffect",
      "effect": "apply_status",
      "valuePerLevel": 1,
      "statusId": "freeze",
      "durationPerLevel": 1
    }
  ],
  "weight": 80,
```

In `assets/data/forge_upgrades/shocking.json`, replace:

```json
  "weight": 80,
```

with:

```json
  "deltas": [
    {
      "type": "addEffect",
      "effect": "apply_status",
      "valuePerLevel": 1,
      "statusId": "shock",
      "durationPerLevel": 1
    }
  ],
  "weight": 80,
```

In `assets/data/forge_upgrades/enduring.json`, replace:

```json
  "weight": 30,
```

with:

```json
  "deltas": [
    {
      "type": "removeExhaust"
    }
  ],
  "weight": 30,
```

- [ ] **Step 8: Le gabarit de l'éditeur porte `deltas`**

`deltas` devient obligatoire : sans lui, le gabarit de rune ne franchirait plus la famille 7 (`entity_validator_test.dart:496-517`).

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // `ForgeUpgradeData.fromJson` ne leve sur rien d'autre que `id` : toutes
    // les autres cles ont un defaut. C'est la categorie ou la validation
    // declarative fait tout le travail.
    requiredKeys: const {'pools'},
```

with:

```dart
    // `pools` est la seule cle que la famille 3 exige : les autres cles
    // obligatoires d'une rune — `deltas`, et ce que la spec P-43 E1 y ajoute
    // (§3.1) — sont refusees par `ForgeUpgradeData.fromJson` lui-meme, que la
    // famille 7 appelle. Un fait a un seul endroit.
    requiredKeys: const {'pools'},
```

Then replace:

```dart
  "stackable": true,
  "valueMultiplier": 1,
  "weight": 10,
```

with:

```dart
  "stackable": true,
  "valueMultiplier": 1,
  "deltas": [
    { "type": "percentBonus", "effect": "damage", "valuePercentPerLevel": 15 }
  ],
  "weight": 10,
```

- [ ] **Step 9: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/effective_card_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/unit/forge_upgrade_data_test.dart` — Expected: `+13: All tests passed!`
Run: `flutter test test/unit/rune_resolution_test.dart` — Expected: `+11: All tests passed!`
Run: `flutter test test/unit/card_rarity_test.dart test/unit/stat_gains_characterization_test.dart test/unit/might_orientation_test.dart test/unit/deck_controller_test.dart test/unit/forge_rune_rules_test.dart test/unit/referential_integrity_test.dart test/unit/content_editor/` — Expected: `All tests passed!`

- [ ] **Step 10: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1267: All tests passed!` (1228 + 13 + 13 + 11 + 1 + 2 − 1 : `test/unit/stat_gains_test.dart:20` engendre un test par valeur de `GainSource`, et `rune` n'en est plus une — le cas « armure de source rune » disparaît avec elle).

- [ ] **Step 11: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/card_delta.dart lib/models/effective_card.dart lib/models/data/card_data.dart lib/models/data/forge_upgrade_data.dart lib/models/card_instance.dart lib/game/services/forge_rune_rules.dart lib/game/services/effect_resolver.dart lib/game/systems/stat_gains.dart lib/services/content_editor/entity_descriptor.dart assets/data/forge_upgrades test/unit/shipped_data.dart test/unit/effective_card_test.dart test/unit/forge_upgrade_data_test.dart test/unit/rune_resolution_test.dart test/unit/card_rarity_test.dart test/unit/stat_gains_characterization_test.dart test/unit/might_orientation_test.dart test/unit/deck_controller_test.dart test/unit/forge_rune_rules_test.dart test/unit/referential_integrity_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart
git commit -F- <<'EOF'
feat(runes): le moteur lit la rune dans son fichier

Une rune declare ses deltas, trois sortes typees ; l applicateur
EffectiveCard calcule la carte telle qu elle se joue, et la resolution
confie chaque effet au registre de strategies, ceux des runes d abord.
Tranchant et Endurci donnent 15 pour cent de la base par niveau, au
moins 1 ; les statuts des runes se posent par addStatus, sans source ;
le mana d Econome passe par la strategie de gain de mana.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: G1 et G2 — la rareté par paliers, `fusionRank`

G1 : à chaque palier de rareté, une valeur prend le multiplicateur du palier et au moins 1 de plus que la précédente — dégâts, armure, soin, valeur d'un statut (A5). G2 : la pioche et le mana rendu ne grandissent plus avec la rareté, et G1 s'arrête aux effets que la rareté multiplie (A6). `CardRarity.forgeSlotBonus` devient `fusionRank`, mêmes valeurs (D28) : la capacité le lit encore, G1 compte ses paliers — son second lecteur. La prose du tutoriel qui dit la rareté comme un pur multiplicateur suit (§5.4). Les rendus lisent encore `CardInstance.rarityMultiplier` jusqu'à Task 3 : la tâche change ce que la carte **joue**, Task 3 ce qu'elle **affiche**.

Changements de jeu de la tâche, voulus (spec §4.3, §4.8) : les valeurs 1 à 4 grandissent d'au moins 1 par palier (*Coup Empoisonné* légendaire : 7 dégâts et 5 Poison au lieu de 6 et 2 ; *Forme Démoniaque* légendaire : 6 Puissance au lieu de 4) ; 5 et plus ne changent pas ; la pioche et le mana d'une carte gardent la valeur de sa donnée (*Concentration* légendaire : 2 cartes au lieu de 4).

**Files:**
- Modify: `lib/models/data/card_data.dart:1-3`, `:30-39`, le getter `multiplier` de Task 1, `:141-143`
- Modify: `lib/models/effective_card.dart` (`_atRarity` de Task 1)
- Modify: `lib/tutorial/tutorial_data.dart:134-136`, `:147-149`, `:268-269`, `:281-282`
- Modify: `lib/tutorial/widgets/tutorial_merge_widget.dart:264-266`
- Test: `test/unit/effective_card_test.dart` (groupe neuf), `test/unit/card_rarity_test.dart` (groupe neuf), `test/unit/rune_resolution_test.dart` (un cas), `test/widget/tutorial_merge_transition_test.dart:136-138`

**Interfaces:**
- Consumes: `CardRarity.multiplier`, `EffectiveCard.apply` (Task 1).
- Produces: `int get CardRarity.fusionRank` (à la place de `forgeSlotBonus`, mêmes valeurs) ; `int CardRarity.scaleValue(int base)` ; la constante G2 de l'applicateur, `EffectiveCard._frozenByRarity` (`{'draw', 'gain_mana'}`), seul endroit qui la lise.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/effective_card_test.dart`, replace:

```dart
void main() {
  group('percentBonus', () {
```

with:

```dart
void main() {
  group('G1 et G2', () {
    // Spec §4.3 : la valeur d'un effet, de commune a legendaire.
    List<int> ladder(CardEffect effect) => [
          for (final rarity in const [
            CardRarity.common,
            CardRarity.uncommon,
            CardRarity.rare,
            CardRarity.epic,
            CardRarity.legendary,
          ])
            EffectiveCard.apply(_card([effect]), rarity, const [])
                .effects
                .single
                .value,
        ];

    test('G1 : chaque palier ajoute au moins 1 aux petites valeurs', () {
      expect(ladder(_damage(1)), [1, 2, 3, 4, 5]);
      expect(ladder(_damage(2)), [2, 3, 4, 5, 6]);
      expect(ladder(_damage(3)), [3, 4, 5, 6, 7]);
      expect(ladder(_damage(4)), [4, 5, 6, 7, 8]);
    });

    test('G1 : a partir de 5, la valeur multipliee d aujourd hui', () {
      expect(ladder(_damage(5)), [5, 6, 7, 8, 10]);
      expect(ladder(_damage(12)), [12, 14, 17, 19, 24]);
    });

    test('G1 vaut pour le soin et pour la valeur d un statut', () {
      expect(ladder(const CardEffect(type: 'heal', value: 3)), [3, 4, 5, 6, 7]);
      expect(
        ladder(const CardEffect(
            type: 'apply_status', value: 1, statusId: 'poison', duration: 2)),
        [1, 2, 3, 4, 5],
      );
    });

    test('unique rend la base', () {
      expect(
        EffectiveCard.apply(_card([_damage(1)]), CardRarity.unique, const [])
            .effects
            .single
            .value,
        1,
      );
    });

    test('G2 : la pioche et le mana ne grandissent pas avec la rarete', () {
      expect(ladder(const CardEffect(type: 'draw', value: 2)), [2, 2, 2, 2, 2]);
      expect(
          ladder(const CardEffect(type: 'gain_mana', value: 1)), [1, 1, 1, 1, 1]);
    });

    // Review Focus 1 : sans sa garde, une valeur nulle gagnerait 1 par palier.
    test('une valeur nulle reste nulle a toute rarete', () {
      expect(ladder(_damage(0)), [0, 0, 0, 0, 0]);
    });
  });

  group('percentBonus', () {
```

In `test/unit/card_rarity_test.dart`, replace:

```dart
  group('CardRarity.multiplier', () {
```

with:

```dart
  group('CardRarity.fusionRank', () {
    test('le nombre de fusions qui menent a la rarete, 0 hors de l echelle', () {
      expect([for (final rarity in _ladder) rarity.fusionRank], [0, 1, 2, 3, 4]);
      expect(CardRarity.unique.fusionRank, 0);
    });
  });

  group('CardRarity.multiplier', () {
```

In `test/unit/rune_resolution_test.dart`, replace:

```dart
  test('le Berserker convertit en une fois l armure de la carte et celle de '
```

with:

```dart
  test('G1 : un Coup Empoisonne legendaire inflige 7 degats et pose 5 Poison',
      () {
    play(card('poison_stab', rarity: CardRarity.legendary));
    expect(enemy().currentPv, 100 - 7);
    expect(
      enemyStatuses('poison').map((s) => (s.value, s.duration)),
      [(5, 2)],
    );
  });

  test('le Berserker convertit en une fois l armure de la carte et celle de '
```

In `test/widget/tutorial_merge_transition_test.dart`, replace:

```dart
      await tester.pump(const Duration(milliseconds: 200)); // callback différé de 150 ms

      await _tapNext(tester); // -> 12 L'Expérience & le Level Up
```

with:

```dart
      await tester.pump(const Duration(milliseconds: 200)); // callback différé de 150 ms
      // L'encart dit ce qui est vrai de toute carte fusionnée, une carte dont
      // aucun chiffre ne grandit comprise (spec P-43 E1, §5.4).
      expect(find.text('Même coût, rareté supérieure.'), findsOneWidget);

      await _tapNext(tester); // -> 12 L'Expérience & le Level Up
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/effective_card_test.dart test/unit/card_rarity_test.dart test/unit/rune_resolution_test.dart test/widget/tutorial_merge_transition_test.dart`
Expected: échec à la compilation — `CardRarity` n'a pas de `fusionRank`.

- [ ] **Step 3: `fusionRank` et G1**

In `lib/models/data/card_data.dart`, replace:

```dart
import 'package:flutter/foundation.dart';
import '../../services/audio/audio_source.dart';
import 'game_data_registry.dart';
```

with:

```dart
import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import '../../services/audio/audio_source.dart';
import 'game_data_registry.dart';
```

Then replace:

```dart
  /// Emplacements de rune que cette rareté ajoute à `baseMaxForgeUpgrades`.
  ///
  /// Nul pour `unique` : une carte de classe a une capacité fixe (ADR-026).
  int get forgeSlotBonus => switch (this) {
        CardRarity.common || CardRarity.unique => 0,
        CardRarity.uncommon => 1,
        CardRarity.rare => 2,
        CardRarity.epic => 3,
        CardRarity.legendary => 4,
      };
```

with:

```dart
  /// Le nombre de fusions qu'il a fallu pour atteindre cette rareté : 0 à 4
  /// de `common` à `legendary`, 0 pour `unique`, qui ne fusionne jamais
  /// (ADR-026). La capacité de forge le lit (`forgeCapacityAt`) en attendant
  /// E2, et G1 compte ses paliers (`scaleValue`).
  int get fusionRank => switch (this) {
        CardRarity.common || CardRarity.unique => 0,
        CardRarity.uncommon => 1,
        CardRarity.rare => 2,
        CardRarity.epic => 3,
        CardRarity.legendary => 4,
      };
```

Then replace:

```dart
  /// Le multiplicateur de valeur de cette rareté, que l'applicateur lit
  /// (`EffectiveCard`). 1,0 pour `unique`, hors de l'échelle.
  double get multiplier => switch (this) {
        CardRarity.common || CardRarity.unique => 1.0,
        CardRarity.uncommon => 1.2,
        CardRarity.rare => 1.4,
        CardRarity.epic => 1.6,
        CardRarity.legendary => 2.0,
      };
```

with:

```dart
  /// Le multiplicateur du palier de cette rareté, que G1 applique palier par
  /// palier (`scaleValue`). 1,0 pour `unique`, hors de l'échelle.
  double get multiplier => switch (this) {
        CardRarity.common || CardRarity.unique => 1.0,
        CardRarity.uncommon => 1.2,
        CardRarity.rare => 1.4,
        CardRarity.epic => 1.6,
        CardRarity.legendary => 2.0,
      };

  /// Les paliers de l'échelle de fusion au-delà de `common`, dans l'ordre.
  static const _fusionSteps = [
    CardRarity.uncommon,
    CardRarity.rare,
    CardRarity.epic,
    CardRarity.legendary,
  ];

  /// G1 : [base] à cette rareté. À chaque palier franchi depuis `common` —
  /// [fusionRank] paliers —, la valeur prend le multiplicateur du palier, et
  /// au moins 1 de plus que la précédente : une fusion augmente d'au moins 1
  /// chaque chiffre que la rareté multiplie (brainstorm §4.5, spec P-43 E1,
  /// A5, §4.3). Une base nulle ou négative est rendue telle quelle.
  int scaleValue(int base) {
    if (base <= 0) return base;
    var value = base;
    for (final step in _fusionSteps.take(fusionRank)) {
      value = max((base * step.multiplier).round(), value + 1);
    }
    return value;
  }
```

Then replace:

```dart
  /// Nombre de runes de forge qu'une carte de ce modèle porte à [rarity].
  int forgeCapacityAt(CardRarity rarity) =>
      baseMaxForgeUpgrades + rarity.forgeSlotBonus;
```

with:

```dart
  /// Nombre de runes de forge qu'une carte de ce modèle porte à [rarity].
  int forgeCapacityAt(CardRarity rarity) =>
      baseMaxForgeUpgrades + rarity.fusionRank;
```

- [ ] **Step 4: G2 dans l'applicateur**

In `lib/models/effective_card.dart`, replace:

```dart
  static CardEffect _atRarity(CardEffect effect, CardRarity rarity) =>
      _withValue(effect, (effect.value * rarity.multiplier).round());
```

with:

```dart
  /// G2 : la pioche et le mana rendu ne grandissent pas avec la rareté — la
  /// seule écriture de la règle (brainstorm §4.5, spec P-43 E1, A6, §4.3).
  static const _frozenByRarity = {'draw', 'gain_mana'};

  /// L'effet à la rareté de la carte : G1 (`CardRarity.scaleValue`), sauf
  /// pour ce que G2 gèle.
  static CardEffect _atRarity(CardEffect effect, CardRarity rarity) =>
      _frozenByRarity.contains(effect.type)
          ? effect
          : _withValue(effect, rarity.scaleValue(effect.value));
```

- [ ] **Step 5: La prose du tutoriel**

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        'The damage printed on a card is not the final number: your Hero\'s '
        'Might is added on top, depending on what their class strengthens, and '
        'rarity multiplies the base value.',
```

with:

```dart
        'The damage printed on a card is not the final number: your Hero\'s '
        'Might is added on top, depending on what their class strengthens, and '
        'rarity raises the base value.',
```

Then replace:

```dart
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'la Puissance de votre héros s\'y ajoute, selon ce que renforce sa '
        'classe, et la rareté multiplie la valeur de base.',
```

with:

```dart
        'Les dégâts imprimés sur une carte ne sont pas le chiffre final : '
        'la Puissance de votre héros s\'y ajoute, selon ce que renforce sa '
        'classe, et la rareté augmente la valeur de base.',
```

Then replace:

```dart
        'Rarity **never changes a card\'s Mana cost** — it multiplies its '
        'values: ×1.2 uncommon, ×1.4 rare, ×1.6 epic, ×2.0 legendary.\n\n'
```

with:

```dart
        'Rarity **never changes a card\'s Mana cost** — it raises its values: '
        '×1.2 uncommon, ×1.4 rare, ×1.6 epic, ×2.0 legendary, and always by at '
        'least 1 per merge. Cards drawn and Mana gained do not grow with '
        'rarity.\n\n'
```

Then replace:

```dart
        'La rareté **ne change jamais le coût en Mana** — elle multiplie les '
        'valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire.\n\n'
```

with:

```dart
        'La rareté **ne change jamais le coût en Mana** — elle augmente les '
        'valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire, et '
        'toujours d\'au moins 1 à chaque fusion. La pioche et le Mana qu\'une '
        'carte rend ne grandissent pas avec la rareté.\n\n'
```

In `lib/tutorial/widgets/tutorial_merge_widget.dart`, replace:

```dart
                      isFrench
                          ? 'Même coût. Valeurs ×1,2.'
                          : 'Same cost. Values ×1.2.',
```

with:

```dart
                      isFrench
                          ? 'Même coût, rareté supérieure.'
                          : 'Same cost, higher rarity.',
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/effective_card_test.dart` — Expected: `+19: All tests passed!`
Run: `flutter test test/unit/card_rarity_test.dart` — Expected: `+10: All tests passed!`
Run: `flutter test test/unit/rune_resolution_test.dart` — Expected: `+12: All tests passed!`
Run: `flutter test test/widget/tutorial_merge_transition_test.dart test/tutorial/` — Expected: `All tests passed!`

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1275: All tests passed!` (1267 + 6 + 1 + 1).

- [ ] **Step 8: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/card_data.dart lib/models/effective_card.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_merge_widget.dart test/unit/effective_card_test.dart test/unit/card_rarity_test.dart test/unit/rune_resolution_test.dart test/widget/tutorial_merge_transition_test.dart
git commit -F- <<'EOF'
feat(rarete): chaque fusion augmente d au moins 1 ce qu elle multiplie

G1 : a chaque palier, une valeur prend le multiplicateur du palier et
au moins 1 de plus que la precedente ; G2 : la pioche et le mana rendu
ne grandissent plus avec la rarete. forgeSlotBonus devient fusionRank,
memes valeurs. Le tutoriel dit la rarete comme elle joue.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: Les rendus et le tutoriel lisent l'applicateur

Les huit sites qui multipliaient la rareté — et les cinq qui écrivaient « +2 par niveau » — lisent désormais `EffectiveCard` (§4.2) : le moteur et ce que le joueur voit ne peuvent plus diverger. `UiCard` porte la `CardData` et la `CardRarity` de la carte à la place du multiplicateur ; ses deux rendus appellent l'applicateur. `CardInstance.rarityMultiplier` perd son dernier lecteur et disparaît. Les lignes de runes des infobulles restent écrites en dur jusqu'à Task 4.

**Écart constaté à la spec** : `CardTextRenderer.buildDescription()` (`lib/game/components/widgets/card_text_renderer.dart:355-491`), que la spec compte parmi les rendus (« le rendu Flame de la carte, l'infobulle », §4.2 et §5.2), n'a **aucun appelant** (`git grep -n "buildDescription" -- lib test` ne rend que sa déclaration) : l'infobulle Flame est `CardComponent.buildDetailedDescription`, appelée par `card_animation_system.dart:102`. Le code mort n'est pas réécrit : il est supprimé (`CLAUDE.md`, « No dead code »). Les rendus réels restent six : les pastilles Flame, l'infobulle Flame, l'infobulle et le corps Flutter, le jeu et la valeur affichée du tutoriel.

Changements visibles de la tâche, voulus : les chiffres qu'affichent la carte, ses infobulles et le tutoriel sont ceux que joue le moteur depuis Tasks 1 et 2 — G1, G2, `sharp` et `hardened` en pourcentage.

**Files:**
- Modify: `lib/models/card_instance.dart` (le getter `rarityMultiplier` de Task 1)
- Modify: `lib/ui/widgets/ui_card.dart:18-22`, `:37-41`, `:66-70`, `:84-86`, `:98-102`, `:157-164`, `:275-279`
- Modify: `lib/ui/widgets/ui_card/ui_card_helpers.dart:1-3`, `:255-267`, `:331-332`, `:344-366`
- Modify: `lib/ui/widgets/ui_card/card_compact_description.dart:1-3`, `:5-25`, `:42-65`, `:164`
- Modify: `lib/game/components/card_component.dart:344-364`
- Modify: `lib/game/components/widgets/card_text_renderer.dart:95-122`, `:213`, `:353-493` (suppression de `buildDescription`)
- Modify: `lib/tutorial/tutorial_engine.dart:385-386`
- Modify: `lib/tutorial/widgets/tutorial_play_card_widget.dart:10-11`, `:24-31`
- Modify: `test/unit/shipped_data.dart` (`shippedCard`)
- Test: `test/widget/ui_card_values_test.dart` *(nouveau)* ; `test/tutorial/tutorial_engine_test.dart:92-98` (un cas) ; `test/widget/hud_and_targeting_badge_test.dart:58-63`

**Interfaces:**
- Consumes: `EffectiveCard.apply`, `EffectiveCard.withRunes`, `CardInstance.effective` (Task 1), G1 et G2 (Task 2).
- Produces: `UiCard({..., CardData? data, CardRarity cardRarity = CardRarity.common, ...})` — les champs `rarityMultiplier` et `effects` disparaissent ; `UiCard.fromData` perd son paramètre `rarityMultiplier`. `buildDetailedDescription(context, {required String title, required String description, required CardData? data, required CardRarity cardRarity, required List<String> forgeUpgrades, ...})`. `CardCompactDescription({required String description, required CardData? data, required CardRarity cardRarity, required List<String> forgeUpgrades, ...})`. Aide de test : `CardData shippedCard(String id)`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/shipped_data.dart`, replace:

```dart
ForgeUpgradeData shippedRune(String id) => ForgeUpgradeData.fromJson(
      _shipped('assets/data/forge_upgrades/$id.json', id),
    );
```

with:

```dart
ForgeUpgradeData shippedRune(String id) => ForgeUpgradeData.fromJson(
      _shipped('assets/data/forge_upgrades/$id.json', id),
    );

/// Une carte neutre telle que le jeu la livre (`assets/data/cards/`).
CardData shippedCard(String id) =>
    CardData.fromJson(_shipped('assets/data/cards/$id.json', id));
```

Create `test/widget/ui_card_values_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_compact_description.dart';

import '../unit/shipped_data.dart';

Future<void> _pumpCard(WidgetTester tester, CardInstance card) async {
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
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 140,
            height: 196,
            child: Builder(
              builder: (context) => UiCard.fromInstance(
                card: card,
                locale: 'fr',
                l10n: AppLocalizations.of(context)!,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Le texte de l'infobulle de la carte.
String _tooltip(WidgetTester tester) =>
    tester.widget<Tooltip>(find.byType(Tooltip)).richMessage!.toPlainText();

/// Un texte du corps de la carte.
Finder _body(String text) => find.descendant(
      of: find.byType(CardCompactDescription),
      matching: find.text(text),
    );

/// Les rendus Flutter de la carte lisent l'applicateur : ce qu'ils montrent
/// est ce que le moteur joue (spec P-43 E1, §4.2).
void main() {
  setUpAll(() => shippedRuneRegistry(const ['sharp']));

  testWidgets('une Frappe legendaire portant Tranchant 2 montre 16 degats',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2'],
      ),
    );

    expect(_tooltip(tester), contains('Inflige 16 dégâts.'));
    expect(_body('12'), findsOneWidget);
    expect(_body(' +4🔨'), findsOneWidget);
  });

  testWidgets('une Frappe epique portant deux Tranchant 1 montre 13 degats',
      (tester) async {
    // 10 a la rarete, et le bonus du niveau total 2 : +3, pas deux fois +2.
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.epic,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      ),
    );

    expect(_tooltip(tester), contains('Inflige 13 dégâts.'));
    expect(_body('10'), findsOneWidget);
    expect(_body(' +3🔨'), findsOneWidget);
  });

  testWidgets('un Eveil epique montre 7 Armure et pioche 1 carte',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(data: shippedCard('awakening'), rarity: CardRarity.epic),
    );

    expect(_tooltip(tester),
        allOf(contains('Donne 7 Armure.'), contains('Pioche 1 cartes.')));
    expect(_body('7'), findsOneWidget);
    expect(_body('1'), findsOneWidget);
  });
}
```

In `test/tutorial/tutorial_engine_test.dart`, replace:

```dart
    test('une carte trop chère n\'est pas jouée', () {
      engine.seedHand([TutorialFixtureIds.fireball]);
      engine.setMana(0);

      expect(engine.playCard(engine.mockState.hand.first), isFalse);
      expect(engine.mockState.hand, hasLength(1));
    });
```

with:

```dart
    test('une carte trop chère n\'est pas jouée', () {
      engine.seedHand([TutorialFixtureIds.fireball]);
      engine.setMana(0);

      expect(engine.playCard(engine.mockState.hand.first), isFalse);
      expect(engine.mockState.hand, hasLength(1));
    });

    test('une carte peu commune joue sa valeur a la rarete, par l applicateur',
        () {
      // G1 : une valeur de 1 en commune vaut 2 en peu commune (spec P-43 E1,
      // §4.3) ; le tutoriel joue ce que le jeu joue (ADR-081).
      engine.seedEnemy();
      const tap = CardData(
        id: 'tutorial_tap',
        cost: 0,
        type: CardType.attack,
        category: CardCategory.global,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [CardEffect(type: 'damage', value: 1)],
      );
      final card = CardInstance(data: tap, rarity: CardRarity.uncommon);
      engine.mockState.hand = [card];

      engine.playCard(card);

      expect(engine.mockState.enemy!.stats.currentPv,
          engine.fixtures.trainingEnemy.maxHp - 2);
    });
```

In `test/widget/hud_and_targeting_badge_test.dart`, replace:

```dart
              child: UiCard(
                title: title,
                description: 'Test description',
                targetType: targetType,
                effects: effects,
              ),
```

with:

```dart
              child: UiCard(
                title: title,
                description: 'Test description',
                targetType: targetType,
                data: CardData(
                  id: 'test_card',
                  cost: 1,
                  type: CardType.attack,
                  category: CardCategory.global,
                  rarity: CardRarity.common,
                  target: targetType,
                  effects: effects,
                ),
              ),
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/widget/ui_card_values_test.dart test/tutorial/tutorial_engine_test.dart test/widget/hud_and_targeting_badge_test.dart`
Expected: échec à la compilation — `UiCard` n'a pas de paramètre `data`. (Sans `hud_and_targeting_badge_test.dart`, deux cas de `ui_card_values_test.dart` échouent — 14 et non 13 dégâts, 6 et non 7 Armure, pioche 2 — et le cas du tutoriel rend 1 dégât et non 2 ; le cas de la *Frappe* légendaire passe déjà : 2 × 2 et 15 % de 12 × 2 donnent tous deux +4.)

- [ ] **Step 3: `UiCard` porte la carte et sa rareté**

In `lib/ui/widgets/ui_card.dart`, replace:

```dart
  final int? level;
  final double rarityMultiplier;
  final List<String> forgeUpgrades;
  final int forgeCapacity;
  final List<CardEffect>? effects;
```

with:

```dart
  final int? level;

  /// La carte, que ses rendus lisent par l'applicateur avec [cardRarity] et
  /// [forgeUpgrades] (spec P-43 E1, §4.2). Absente, le corps ne montre que
  /// [description].
  final CardData? data;

  /// La rareté de jeu de la carte ; [rarity] en est le libellé traduit.
  final CardRarity cardRarity;
  final List<String> forgeUpgrades;
  final int forgeCapacity;
```

Then replace:

```dart
    this.level,
    this.rarityMultiplier = 1.0,
    this.forgeUpgrades = const [],
    this.forgeCapacity = 1,
    this.effects,
```

with:

```dart
    this.level,
    this.data,
    this.cardRarity = CardRarity.common,
    this.forgeUpgrades = const [],
    this.forgeCapacity = 1,
```

Then replace:

```dart
      level: 1,
      rarityMultiplier: card.rarityMultiplier,
      forgeUpgrades: card.forgeUpgrades,
      forgeCapacity: card.forgeCapacity,
      effects: card.data.effects,
```

with:

```dart
      level: 1,
      data: card.data,
      cardRarity: card.rarity,
      forgeUpgrades: card.forgeUpgrades,
      forgeCapacity: card.forgeCapacity,
```

Then replace:

```dart
    required AppLocalizations l10n,
    double rarityMultiplier = 1.0,
    List<String> forgeUpgrades = const [],
```

with:

```dart
    required AppLocalizations l10n,
    List<String> forgeUpgrades = const [],
```

Then replace:

```dart
      level: 1,
      rarityMultiplier: rarityMultiplier,
      forgeUpgrades: forgeUpgrades,
      forgeCapacity: card.forgeCapacityAt(card.rarity),
      effects: card.effects,
```

with:

```dart
      level: 1,
      data: card,
      cardRarity: card.rarity,
      forgeUpgrades: forgeUpgrades,
      forgeCapacity: card.forgeCapacityAt(card.rarity),
```

Then replace:

```dart
              text: buildDetailedDescription(
                context,
                title: title,
                description: description,
                rarityMultiplier: rarityMultiplier,
                forgeUpgrades: forgeUpgrades,
                effects: effects,
                target: target,
```

with:

```dart
              text: buildDetailedDescription(
                context,
                title: title,
                description: description,
                data: data,
                cardRarity: cardRarity,
                forgeUpgrades: forgeUpgrades,
                target: target,
```

Then replace:

```dart
                              child: CardCompactDescription(
                                description: description,
                                rarityMultiplier: rarityMultiplier,
                                forgeUpgrades: forgeUpgrades,
                                effects: effects,
```

with:

```dart
                              child: CardCompactDescription(
                                description: description,
                                data: data,
                                cardRarity: cardRarity,
                                forgeUpgrades: forgeUpgrades,
```

- [ ] **Step 4: Les deux rendus Flutter**

In `lib/ui/widgets/ui_card/ui_card_helpers.dart`, replace:

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/card_data.dart';
```

with:

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/card_data.dart';
import '../../../models/effective_card.dart';
```

Then replace:

```dart
String buildDetailedDescription(
  BuildContext context, {
  required String title,
  required String description,
  required double rarityMultiplier,
  required List<String> forgeUpgrades,
  List<CardEffect>? effects,
  String? target,
  CardTarget? targetType,
  String? rarity,
  CardType? type,
  int? cost,
}) {
```

with:

```dart
String buildDetailedDescription(
  BuildContext context, {
  required String title,
  required String description,
  required CardData? data,
  required CardRarity cardRarity,
  required List<String> forgeUpgrades,
  String? target,
  CardTarget? targetType,
  String? rarity,
  CardType? type,
  int? cost,
}) {
```

Then replace:

```dart
  String desc = details.isNotEmpty ? '$details\n' : '';
  final elementalType = determineDamageType(title, effects);
```

with:

```dart
  String desc = details.isNotEmpty ? '$details\n' : '';
  final effects = data?.effects;
  final elementalType = determineDamageType(title, effects);
```

Then replace:

```dart
  if (effects == null || effects.isEmpty) {
    return desc + description;
  }

  int extraDamage = 0;
  int extraArmor = 0;
  for (var upgrade in forgeUpgrades) {
    final parts = upgrade.split(':');
    if (parts.length != 2) continue;
    final id = parts[0];
    final k = int.tryParse(parts[1]) ?? 0;
    if (k <= 0) continue;
    if (id == 'sharp') extraDamage += 2 * k;
    if (id == 'hardened') extraArmor += 2 * k;
  }

  for (var effect in effects) {
    int scaledValue = (effect.value * rarityMultiplier).round();
    if (effect.type == 'damage') {
      scaledValue += extraDamage;
    } else if (effect.type == 'armor') {
      scaledValue += extraArmor;
    }
```

with:

```dart
  if (data == null || data.effects.isEmpty) {
    return desc + description;
  }

  // Les valeurs que la carte joue — rareté et runes comprises — viennent de
  // l'applicateur, seul à les calculer (spec P-43 E1, §4.2).
  for (final effect
      in EffectiveCard.withRunes(data, cardRarity, forgeUpgrades).effects) {
    final scaledValue = effect.value;
```

In `lib/ui/widgets/ui_card/card_compact_description.dart`, replace:

```dart
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import 'ui_card_helpers.dart';
```

with:

```dart
import 'package:flutter/material.dart';
import '../../../models/data/card_data.dart';
import '../../../models/effective_card.dart';
import 'ui_card_helpers.dart';
```

Then replace:

```dart
class CardCompactDescription extends StatelessWidget {
  final String description;
  final double rarityMultiplier;
  final List<String> forgeUpgrades;
  final List<CardEffect>? effects;
  final CardTarget? targetType;
  final String? target;

  const CardCompactDescription({
    super.key,
    required this.description,
    required this.rarityMultiplier,
    required this.forgeUpgrades,
    this.effects,
    this.targetType,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    if (effects == null || effects!.isEmpty) {
```

with:

```dart
class CardCompactDescription extends StatelessWidget {
  final String description;

  /// La carte, que l'applicateur lit avec [cardRarity] et [forgeUpgrades]
  /// (spec P-43 E1, §4.2) ; absente, le corps ne montre que [description].
  final CardData? data;
  final CardRarity cardRarity;
  final List<String> forgeUpgrades;
  final CardTarget? targetType;
  final String? target;

  const CardCompactDescription({
    super.key,
    required this.description,
    required this.data,
    required this.cardRarity,
    required this.forgeUpgrades,
    this.targetType,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    final data = this.data;
    if (data == null || data.effects.isEmpty) {
```

Then replace:

```dart
    final List<Widget> badges = [];
    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    final isAllEnemies = resolveTarget(targetType, target) == CardTarget.allEnemies;

    for (int i = 0; i < effects!.length; i++) {
      final effect = effects![i];
      int baseValue = (effect.value * rarityMultiplier).round();
      int bonusValue = 0;
      if (effect.type == 'damage') {
        bonusValue = extraDamage;
      } else if (effect.type == 'armor') {
        bonusValue = extraArmor;
      }
```

with:

```dart
    final List<Widget> badges = [];
    // La valeur à la rareté, puis ce que les runes y ajoutent : deux lectures
    // de l'applicateur, seul à calculer l'une et l'autre (spec P-43 E1, §4.2).
    final atRarity = EffectiveCard.apply(data, cardRarity, const []).effects;
    final played =
        EffectiveCard.withRunes(data, cardRarity, forgeUpgrades).effects;

    final isAllEnemies = resolveTarget(targetType, target) == CardTarget.allEnemies;

    for (int i = 0; i < played.length; i++) {
      final effect = played[i];
      final baseValue = atRarity[i].value;
      final bonusValue = effect.value - baseValue;
```

Then replace:

```dart
      if (i < effects!.length - 1) {
```

with:

```dart
      if (i < played.length - 1) {
```

- [ ] **Step 5: Les rendus Flame**

In `lib/game/components/card_component.dart`, replace:

```dart
    final damageBonus = game.heroCard?.stats.damageBonusFor(card.data.type) ?? 0;

    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    for (var effect in card.data.effects) {
      int scaledValue = (effect.value * card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }
```

with:

```dart
    final damageBonus = game.heroCard?.stats.damageBonusFor(card.data.type) ?? 0;

    // Les valeurs que la carte joue — rareté et runes comprises — viennent de
    // l'applicateur, seul à les calculer (spec P-43 E1, §4.2).
    for (final effect in card.effective.effects) {
      final scaledValue = effect.value;
```

In `lib/game/components/widgets/card_text_renderer.dart`, replace:

```dart
      final damageBonus = card.game.heroCard?.stats.damageBonusFor(card.card.data.type) ?? 0;

      int extraDamage = 0;
      int extraArmor = 0;
      for (var upgrade in card.card.forgeUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final k = int.tryParse(parts[1]) ?? 0;
        if (k <= 0) continue;
        final upgradeData = ForgeUpgradeData.getById(id);
        final multiplier = upgradeData?.valueMultiplier ?? 1;
        if (id == 'sharp') extraDamage += multiplier * k;
        if (id == 'hardened') extraArmor += multiplier * k;
      }

      final isAllEnemies = card.card.data.target == CardTarget.allEnemies;

      for (int i = 0; i < card.card.data.effects.length; i++) {
        final effect = card.card.data.effects[i];
        int scaledValue = (effect.value * card.card.rarityMultiplier).round();
        if (effect.type == 'damage') {
          scaledValue += extraDamage;
        } else if (effect.type == 'armor') {
          scaledValue += extraArmor;
        }

        int valueToDisplay = scaledValue;
```

with:

```dart
      final damageBonus = card.game.heroCard?.stats.damageBonusFor(card.card.data.type) ?? 0;

      final isAllEnemies = card.card.data.target == CardTarget.allEnemies;

      // Les valeurs que la carte joue — rareté et runes comprises — viennent
      // de l'applicateur, seul à les calculer (spec P-43 E1, §4.2).
      final effects = card.card.effective.effects;
      for (int i = 0; i < effects.length; i++) {
        final effect = effects[i];
        final scaledValue = effect.value;

        int valueToDisplay = scaledValue;
```

Then replace:

```dart
        if (i < card.card.data.effects.length - 1) {
```

with:

```dart
        if (i < effects.length - 1) {
```

La méthode morte `buildDescription` s'en va (voir l'écart en tête de tâche). Then replace:

```dart
  }

  String buildDescription() {
    String desc = '';
    final damageBonus = card.game.heroCard?.stats.damageBonusFor(card.card.data.type) ?? 0;

    int extraDamage = 0;
    int extraArmor = 0;
    for (var upgrade in card.card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      if (id == 'sharp') extraDamage += 2 * k;
      if (id == 'hardened') extraArmor += 2 * k;
    }

    for (var effect in card.card.data.effects) {
      int scaledValue = (effect.value * card.card.rarityMultiplier).round();
      if (effect.type == 'damage') {
        scaledValue += extraDamage;
      } else if (effect.type == 'armor') {
        scaledValue += extraArmor;
      }

      if (effect.type == 'damage') {
        final totalDmg = scaledValue + damageBonus;
        if (card.card.data.target == CardTarget.allEnemies) {
          desc +=
              '${card.getTranslation((l) => l.cardDescDamageAll(totalDmg), fallback: "Inflige $totalDmg dégâts à tous les ennemis.")}\n';
        } else {
          desc +=
              '${card.getTranslation((l) => l.cardDescDamage(totalDmg), fallback: "Inflige $totalDmg dégâts.")}\n';
        }
      }
      if (effect.type == 'heal') {
        desc +=
            '${card.getTranslation((l) => l.cardDescHeal(scaledValue), fallback: "Soigne $scaledValue PV.")}\n';
      }
      if (effect.type == 'armor') {
        desc +=
            '${card.getTranslation((l) => l.cardDescArmor(scaledValue), fallback: "Donne $scaledValue Armure.")}\n';
      }
      if (effect.type == 'gain_mana') {
        desc +=
            '${card.getTranslation((l) => l.cardDescGainMana(scaledValue), fallback: "Gagne $scaledValue Mana.")}\n';
      }
      if (effect.type == 'draw') {
        desc +=
            '${card.getTranslation((l) => l.cardDescDraw(scaledValue), fallback: "Pioche $scaledValue cartes.")}\n';
      }
      if (effect.type == 'apply_status') {
        final duration = effect.duration ?? 1;
        switch (effect.statusId) {
          case 'might':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusMight(scaledValue, duration), fallback: "Gagne $scaledValue Puissance pendant $duration tours.")}\n';
            break;
          case 'armor_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusArmorRegen(scaledValue, duration), fallback: "Pendant $duration tours, gagne $scaledValue Armure au début du tour.")}\n';
            break;
          case 'poison':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusPoisonDuration(scaledValue, duration), fallback: "Applique $scaledValue Poison pendant $duration tours.")}\n';
            break;
          case 'weakness':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusWeaknessDuration(scaledValue, duration), fallback: "Applique $scaledValue Faiblesse pendant $duration tours.")}\n';
            break;
          case 'vulnerable':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusVulnerableDuration(scaledValue, duration), fallback: "Applique $scaledValue Vulnérable pendant $duration tours.")}\n';
            break;
          case 'might_regen':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusMightRegen(scaledValue, duration), fallback: "Gagne $scaledValue Éveil de Puissance pendant $duration tours.")}\n';
            break;
          case 'burn':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusBurnDuration(scaledValue, duration), fallback: "Applique $scaledValue Brûlure pendant $duration tours.")}\n';
            break;
          case 'freeze':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusFreezeDuration(scaledValue, duration), fallback: "Applique $scaledValue Gel pendant $duration tours.")}\n';
            break;
          case 'shock':
            desc +=
                '${card.getTranslation((l) => l.cardDescStatusShockDuration(scaledValue, duration), fallback: "Applique $scaledValue Électrocution pendant $duration tours.")}\n';
            break;
        }
      }
    }
    if (desc.isEmpty) {
      desc = card.card.data.getDescription(card.activeLocale);
    }

    final List<String> upgradeDescs = [];
    final activeLocale = card.activeLocale;
    for (var upgrade in card.card.forgeUpgrades) {
      final parts = upgrade.split(':');
      if (parts.length != 2) continue;
      final id = parts[0];
      final k = int.tryParse(parts[1]) ?? 0;
      if (k <= 0) continue;
      switch (id) {
        case 'sharp':
          upgradeDescs.add(activeLocale == 'fr' ? 'Tranchant $k (+${2 * k} Dégâts)' : 'Sharp $k (+${2 * k} Damage)');
          break;
        case 'hardened':
          upgradeDescs.add(activeLocale == 'fr' ? 'Endurci $k (+${2 * k} Armure)' : 'Hardened $k (+${2 * k} Armor)');
          break;
        case 'quick':
          upgradeDescs.add(activeLocale == 'fr' ? 'Véloce $k (+$k Carte(s) piochée(s))' : 'Quick $k (+$k Card(s) drawn)');
          break;
        case 'eco':
          upgradeDescs.add(activeLocale == 'fr' ? 'Économe $k (+$k Mana)' : 'Eco $k (+$k Mana)');
          break;
        case 'burning':
          upgradeDescs.add(activeLocale == 'fr' ? 'Brûlant $k (Applique $k Brûlure)' : 'Burning $k (Apply $k Burn)');
          break;
        case 'freezing':
          upgradeDescs.add(activeLocale == 'fr' ? 'Congelant $k (Applique $k Gel)' : 'Freezing $k (Apply $k Freeze)');
          break;
        case 'shocking':
          upgradeDescs.add(activeLocale == 'fr' ? 'Surchargé $k (Applique $k Électrocution)' : 'Shocking $k (Apply $k Shock)');
          break;
        case 'enduring':
          upgradeDescs.add(activeLocale == 'fr' ? 'Persistant' : 'Enduring');
          break;
      }
    }
    if (upgradeDescs.isNotEmpty) {
      desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => "• $u").join('\n')}\n';
    }

    return desc.trim();
  }

  void render(Canvas canvas, Vector2 size) {
```

with:

```dart
  }

  void render(Canvas canvas, Vector2 size) {
```

- [ ] **Step 6: Le tutoriel, et la fin de `rarityMultiplier`**

In `lib/tutorial/tutorial_engine.dart`, replace:

```dart
    for (final effect in card.data.effects) {
      final scaled = (effect.value * card.rarityMultiplier).round();
```

with:

```dart
    for (final effect in card.effective.effects) {
      final scaled = effect.value;
```

In `lib/tutorial/widgets/tutorial_play_card_widget.dart`, replace:

```dart
/// Valeur imprimée sur la carte, multipliée par la rareté — utilisée pour le
/// texte flottant déclenché par le chemin tap-puis-tap.
```

with:

```dart
/// Valeur imprimée sur la carte, à sa rareté, telle que l'applicateur la
/// calcule — utilisée pour le texte flottant déclenché par le chemin
/// tap-puis-tap.
```

Then replace:

```dart
int _damageValue(CardInstance card) {
  for (final effect in card.data.effects) {
    if (effect.type == 'damage') {
      return (effect.value * card.rarityMultiplier).round();
    }
  }
  return 0;
}
```

with:

```dart
int _damageValue(CardInstance card) {
  for (final effect in card.effective.effects) {
    if (effect.type == 'damage') return effect.value;
  }
  return 0;
}
```

In `lib/models/card_instance.dart`, replace:

```dart
      (data.isExhaust && !effective.removesExhaust);

  double get rarityMultiplier => rarity.multiplier;
```

with:

```dart
      (data.isExhaust && !effective.removesExhaust);
```

- [ ] **Step 7: Lancer les tests pour les voir passer**

Run: `flutter test test/widget/ui_card_values_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/tutorial/ test/widget/hud_and_targeting_badge_test.dart test/widget/ui_card_rune_sockets_test.dart test/widget/tutorial_play_card_step_test.dart test/widget/tutorial_merge_transition_test.dart` — Expected: `All tests passed!`
Run: `git grep -n "rarityMultiplier\|buildDescription()" -- lib` — Expected: aucune sortie.

- [ ] **Step 8: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1279: All tests passed!` (1275 + 3 + 1).

- [ ] **Step 9: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/card_instance.dart lib/ui/widgets/ui_card.dart lib/ui/widgets/ui_card/ui_card_helpers.dart lib/ui/widgets/ui_card/card_compact_description.dart lib/game/components/card_component.dart lib/game/components/widgets/card_text_renderer.dart lib/tutorial/tutorial_engine.dart lib/tutorial/widgets/tutorial_play_card_widget.dart test/unit/shipped_data.dart test/widget/ui_card_values_test.dart test/tutorial/tutorial_engine_test.dart test/widget/hud_and_targeting_badge_test.dart
git commit -F- <<'EOF'
feat(rendus): la carte affiche ce que le moteur joue

Les rendus Flame et Flutter et le tutoriel lisent l applicateur au lieu
de multiplier la rarete et d ajouter deux par niveau de rune. UiCard
porte la carte et sa rarete ; rarityMultiplier disparait, et avec lui
la description morte du rendu Flame, que rien n appelait.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: Les textes des runes viennent de la donnée — `maxLevel`, descriptions, infobulles, forge

A4 : nom, description et emoji d'une rune sont lus dans son fichier, les chiffres sur l'applicateur ; les `switch` d'affichage par id disparaissent. `getDescription` reçoit la carte, sa rareté et le niveau que la carte porte déjà (§5.1) ; `valueMultiplier` perd ses derniers lecteurs et quitte le modèle et les fichiers. Les infobulles écrivent une ligne par rune, au niveau total de ses exemplaires, et le niveau seulement si la rune en a plus d'un (§5.2) — d'où `maxLevel`, clé obligatoire (A8), qui entre ici avec son premier lecteur ; Task 5 lui donne le prédicat, Task 6 les quatre endroits qui écrivent un niveau. Les descriptions de `sharp` et `hardened` disent le pourcentage (§5.1).

Changements visibles de la tâche, voulus (§4.8, §5.1, §5.2) : les descriptions des runes sont les mêmes sur la carte, dans ses infobulles et à la forge ; une fente de la forge dit le gain réel de la rune sur la carte forgée ; l'infobulle écrit « Véloce » et non « Véloce 1 », quand la fente de la forge et le dialogue de fusion gardent leur suffixe de niveau, lu sur `stackable`, jusqu'à E2.

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart` (réécrit en entier : `maxLevel`, `getDescription`, `tooltipLine`, `tooltipLines` ; `valueMultiplier` supprimé)
- Modify: les huit fichiers de `assets/data/forge_upgrades/` — `maxLevel` ; `sharp` et `hardened` perdent `valueMultiplier` et prennent leurs descriptions de §5.1
- Modify: `lib/ui/widgets/forge/forge_slot_row.dart:1-5`, `:7-23`, `:27-134`, `:187-201`
- Modify: `lib/ui/widgets/forge_upgrade_dialog.dart:431-432`
- Modify: `lib/game/components/card_component.dart:6-7`, `:452-506`
- Modify: `lib/ui/widgets/ui_card/ui_card_helpers.dart` (imports de Task 3), `:215-237`, `:443-479`
- Modify: `lib/ui/widgets/forge/forge_card_preview.dart:4-5`, `:19-45`, `:97`
- Modify: `lib/services/content_editor/entity_descriptor.dart:347-348` et le gabarit de Task 1
- Test: `test/unit/forge_upgrade_data_test.dart` (deux groupes neufs) ; `test/unit/decoupled_forge_test.dart:1-7`, `:9-44`, `:112-119` ; `test/widget/ui_card_values_test.dart` (trois cas) ; `test/widget/ui_card_rune_sockets_test.dart:4-8`, `:83-85` (un cas) ; `test/widget/forge_upgrade_dialog_test.dart` *(nouveau)*
- Test: `test/unit/forge_rune_rules_test.dart` (les deux `fromJson` de Task 1) ; `test/widget/forge_fusion_screen_test.dart:10-11`, `:52-55` ; `test/unit/content_editor/entity_descriptor_test.dart` (la table de Task 1) ; `test/unit/content_editor/entity_validator_test.dart` (le brouillon de couleur de Task 1) ; `test/unit/content_editor/field_kind_test.dart:64`

**Interfaces:**
- Consumes: `EffectiveCard.apply`, `PercentBonusDelta`, `ForgeUpgradeData.levelsOf` (Task 1) ; `UiCard.data`, `UiCard.cardRarity`, `buildDetailedDescription(..., data, cardRarity, ...)` (Task 3).
- Produces:
  - `int? ForgeUpgradeData.maxLevel` — `null` : sans plafond ; défaut `null` au constructeur.
  - `String ForgeUpgradeData.getDescription(int level, String locale, CardData card, CardRarity rarity, {int carried = 0})` — `{tier}`, `{percent}`, `{val}`.
  - `String ForgeUpgradeData.tooltipLine(int level, String locale, CardData card, CardRarity rarity)` ; `static List<String> ForgeUpgradeData.tooltipLines(List<String> runes, String locale, CardData card, CardRarity rarity)`.
  - `ForgeSlotRow({..., required CardInstance card, ...})`.
  - `getRuneEmoji(String upgrade)` (`ui_card_helpers.dart`) lit la donnée ; `ForgeCardPreview` l'appelle.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'deltas': [
```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

/// Un fichier de rune minimal et valide : chaque test n'y change que ce qu'il
/// veut casser.
Map<String, dynamic> _json([Map<String, dynamic> overrides = const {}]) => {
      'id': 'sharp',
      'pools': ['common'],
      'maxLevel': null,
      'deltas': [
```

Then replace:

```dart
  group('references id:niveau', () {
```

with:

```dart
  group('maxLevel', () {
    test('null : sans plafond ; un entier : le plafond', () {
      expect(ForgeUpgradeData.fromJson(_json()).maxLevel, isNull);
      expect(ForgeUpgradeData.fromJson(_json({'maxLevel': 1})).maxLevel, 1);
    });

    test('refuse une rune sans maxLevel', () {
      expect(() => ForgeUpgradeData.fromJson(_json()..remove('maxLevel')),
          _refused('maxLevel'));
    });

    test('refuse un maxLevel nul, negatif ou decimal', () {
      for (final bad in [0, -1, 1.5]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'maxLevel': bad})),
            _refused('maxLevel'),
            reason: '$bad');
      }
    });

    test('toJson ecrit maxLevel, meme nul', () {
      expect(ForgeUpgradeData.fromJson(_json()).toJson(),
          containsPair('maxLevel', null));
      final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));
      expect(ForgeUpgradeData.fromJson(capped.toJson()).maxLevel, 2);
    });
  });

  // Review Focus 3 : une sauvegarde peut porter une rune que le catalogue n'a
  // plus.
  test('tooltipLines : une ligne par id au niveau total, rien pour une rune '
      'absente du registre', () {
    GameDataRegistry(
      enemies: const [],
      heroes: const [],
      cards: const [],
      events: const [],
      passives: const [],
      relics: const [],
      forgeUpgrades: [
        ForgeUpgradeData.fromJson(_json(
            {'name_fr': 'Tranchant', 'description_fr': '+{val} Dégâts'})),
      ],
    );
    const strike = CardData(
      id: 'strike_basic',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    expect(
      ForgeUpgradeData.tooltipLines(const ['sharp:1', 'legacy:2', 'sharp:2'],
          'fr', strike, CardRarity.common),
      ['Tranchant 3 : +3 Dégâts'],
    );
  });

  group('references id:niveau', () {
```

In `test/unit/decoupled_forge_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

Then replace:

```dart
void main() {
  group('Decoupled Forge Unit Tests', () {
    // Initialise le registre statique avec de fausses améliorations pour les tests
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage',
            descriptionFr: '+{val} Dégâts',
            icon: 'hardware_rounded',
            color: 'redAccent',
            pools: ['common'],
            valueMultiplier: 2,
            weight: 100,
          ),
          const ForgeUpgradeData(
            id: 'hardened',
            nameEn: 'Hardened',
            nameFr: 'Endurci',
            descriptionEn: '+{val} Block',
            descriptionFr: '+{val} Armure',
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
            valueMultiplier: 2,
            weight: 80,
          ),
```

with:

```dart
void main() {
  group('Decoupled Forge Unit Tests', () {
    // Frappe : 6 degats en commune, 10 en epique.
    const strike = CardData(
      id: 'strike',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 6)],
    );

    // Initialise le registre statique avec de fausses améliorations pour les tests
    setUp(() {
      GameDataRegistry(
        enemies: [],
        heroes: [],
        cards: [],
        events: [],
        passives: [],
        relics: [],
        forgeUpgrades: [
          const ForgeUpgradeData(
            id: 'sharp',
            nameEn: 'Sharp',
            nameFr: 'Tranchant',
            descriptionEn: '+{val} Damage ({percent}%, {tier})',
            descriptionFr: '+{val} Dégâts ({percent}%, {tier})',
            icon: 'hardware_rounded',
            color: 'redAccent',
            pools: ['common'],
            deltas: [
              PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 15),
            ],
            weight: 100,
          ),
          const ForgeUpgradeData(
            id: 'hardened',
            nameEn: 'Hardened',
            nameFr: 'Endurci',
            descriptionEn: '+{val} Block ({percent}%, {tier})',
            descriptionFr: '+{val} Armure ({percent}%, {tier})',
            icon: 'shield_rounded',
            color: 'blueAccent',
            pools: ['common'],
            deltas: [
              PercentBonusDelta(effect: 'armor', valuePercentPerLevel: 15),
            ],
            weight: 80,
          ),
```

Then replace:

```dart
    test('ForgeUpgradeData resolves correct translations and calculated values', () {
      final sharp = ForgeUpgradeData.getById('sharp');
      expect(sharp, isNotNull);
      expect(sharp!.getName('fr'), 'Tranchant');
      expect(sharp.getName('en'), 'Sharp');
      expect(sharp.getDescription(3, 'fr'), '+6 Dégâts');
      expect(sharp.getDescription(3, 'en'), '+6 Damage');
    });
```

with:

```dart
    test('ForgeUpgradeData dit son nom, et sa description sur la carte', () {
      final sharp = ForgeUpgradeData.getById('sharp');
      expect(sharp, isNotNull);
      expect(sharp!.getName('fr'), 'Tranchant');
      expect(sharp.getName('en'), 'Sharp');
      // 6 en commune : +1 au niveau 1 ; 10 en epique : 15 % x 2 x 10 = +3.
      expect(sharp.getDescription(1, 'fr', strike, CardRarity.common),
          '+1 Dégâts (15%, 1)');
      expect(sharp.getDescription(2, 'en', strike, CardRarity.epic),
          '+3 Damage (30%, 2)');
    });

    test('{val} dit le gain marginal sur une carte qui porte deja la rune', () {
      // Frappe epique (10) portant Tranchant 1 (+2) : une fente Tranchant 1 la
      // mene au niveau 2 (+3), soit +1 (spec P-43 E1, §5.1).
      expect(
        ForgeUpgradeData.getById('sharp')!
            .getDescription(1, 'fr', strike, CardRarity.epic, carried: 1),
        '+1 Dégâts (15%, 1)',
      );
    });

    // Review Focus 4 : une sauvegarde peut porter Endurci sur une carte sans
    // armure.
    test('{val} vaut 0 sur une carte sans l effet que la rune vise', () {
      expect(
        ForgeUpgradeData.getById('hardened')!
            .getDescription(1, 'fr', strike, CardRarity.common),
        '+0 Armure (15%, 1)',
      );
    });
```

In `test/widget/ui_card_values_test.dart`, replace:

```dart
  setUpAll(() => shippedRuneRegistry(const ['sharp']));
```

with:

```dart
  setUpAll(() => shippedRuneRegistry(const ['sharp', 'quick']));
```

Then replace:

```dart
    expect(_body('7'), findsOneWidget);
    expect(_body('1'), findsOneWidget);
  });
}
```

with:

```dart
    expect(_body('7'), findsOneWidget);
    expect(_body('1'), findsOneWidget);
  });

  testWidgets('l infobulle ecrit Tranchant au niveau qu il joue',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.legendary,
        forgeUpgrades: const ['sharp:2'],
      ),
    );

    expect(
      _tooltip(tester),
      contains('Tranchant 2 : +4 Dégâts sur la carte (+30% de la base, au '
          'moins +2)'),
    );
  });

  testWidgets('deux Tranchant 1 font une seule ligne, au niveau total',
      (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.epic,
        forgeUpgrades: const ['sharp:1', 'sharp:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(
      tooltip,
      contains('Tranchant 2 : +3 Dégâts sur la carte (+30% de la base, au '
          'moins +2)'),
    );
    expect('Tranchant'.allMatches(tooltip), hasLength(1));
  });

  testWidgets('une rune a niveau unique s ecrit sans niveau', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        forgeUpgrades: const ['quick:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(tooltip, contains('Véloce : Pioche +1 carte(s)'));
    expect(tooltip, isNot(contains('Véloce 1')));
  });
}
```

In `test/widget/ui_card_rune_sockets_test.dart`, replace:

```dart
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_rune_sockets.dart';
```

with:

```dart
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card/card_rune_sockets.dart';
```

Then replace:

```dart
    expect(_socketCount(tester), 5);
  });
}
```

with:

```dart
    expect(_socketCount(tester), 5);
  });

  testWidgets('l emoji d une prise vient de la donnee de la rune', (
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
        data: _cardData(CardRarity.common, 1),
        forgeUpgrades: const ['test_rune:1'],
      ),
    );

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

Create `test/widget/forge_upgrade_dialog_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';

import '../unit/shipped_data.dart';

/// Monte le dialogue de la forge du feu sur [card]. Une [session] — les
/// fentes `id:niveau:relances` qu'une forge en cours a sauvegardées — fixe les
/// fentes ; sans elle, le dialogue les tire.
Future<ProviderContainer> _pumpDialog(
  WidgetTester tester,
  CardInstance card, {
  List<String>? session,
}) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(inventoryProvider.notifier).reset(initialGold: 100000);
  if (session != null) {
    container.read(runProvider.notifier).setForgeSession(card.uniqueId, session);
  }

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
        home: ForgeUpgradeDialog(card: card),
      ),
    ),
  );
  await tester.pump();
  return container;
}

/// L'offre de la forge du feu (spec P-43 E1, §4.6, §4.7, §5.1).
void main() {
  testWidgets('une fente Tranchant 1 dit son gain sur une Frappe epique qui '
      'en porte deja un', (tester) async {
    shippedRuneRegistry(const ['sharp']);
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      rarity: CardRarity.epic,
      forgeUpgrades: const ['sharp:1'],
    );

    await _pumpDialog(tester, card, session: const ['sharp:1:0']);

    // 10 a la rarete : Tranchant 1 donne +2, Tranchant 2 +3 — la fente
    // ajoute +1, ce que le moteur jouera.
    expect(
      find.text('+1 Dégâts sur la carte (+15% de la base, au moins +1)'),
      findsOneWidget,
    );
  });
}
```

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
        'id': 'sharp',
        'pools': ['common'],
        'deltas': [
```

with:

```dart
        'id': 'sharp',
        'pools': ['common'],
        'maxLevel': null,
        'deltas': [
```

Then replace:

```dart
        'stackable': false,
        'deltas': [
```

with:

```dart
        'stackable': false,
        'maxLevel': 1,
        'deltas': [
```

In `test/widget/forge_fusion_screen_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

Then replace:

```dart
    eligibleCardTypes: ['attack'],
    valueMultiplier: 2,
    weight: 100,
    emoji: '⚔️',
```

with:

```dart
    eligibleCardTypes: ['attack'],
    deltas: [PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 15)],
    weight: 100,
    emoji: '⚔️',
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:

```dart
        'valueMultiplier',
        'deltas',
```

with:

```dart
        'maxLevel',
        'deltas',
```

In `test/unit/content_editor/entity_validator_test.dart`, replace:

```dart
                '"deltas": [{"type": "removeExhaust"}]}',
```

with:

```dart
                '"maxLevel": 1, "deltas": [{"type": "removeExhaust"}]}',
```

In `test/unit/content_editor/field_kind_test.dart`, replace:

```dart
    expect(kindOf(forge, const ['valueMultiplier'], 1.5), FieldKind.decimal);
```

with:

```dart
    expect(kindOf(hero, const ['statRules', 0, 'ratio'], 0.5), FieldKind.decimal);
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/decoupled_forge_test.dart test/widget/ui_card_values_test.dart test/widget/ui_card_rune_sockets_test.dart test/widget/forge_upgrade_dialog_test.dart`
Expected: échec à la compilation — `maxLevel`, `tooltipLines` et la nouvelle signature de `getDescription` n'existent pas.

- [ ] **Step 3: Le modèle de rune**

Replace the whole content of `lib/models/data/forge_upgrade_data.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'card_data.dart';
import 'card_delta.dart';
import 'game_data_registry.dart';
import '../effective_card.dart';
import '../missing_save_item.dart';

class ForgeUpgradeData {
  final String id;
  final String nameEn;
  final String nameFr;
  final String descriptionEn;
  final String descriptionFr;
  final String icon;
  final String color;
  final List<String> pools;
  final List<String>? eligibleCardTypes;
  final bool requiresExhaust;

  /// Une rune cumulable additionne ses tiers : deux `sharp:1` valent un
  /// `sharp:2`. Une rune non cumulable est binaire — `enduring` retire
  /// l'épuisement ou non — et n'a qu'un tier, 1 (voir `ForgeRuneRules`).
  final bool stackable;

  /// Le niveau le plus haut que la rune atteint sur une carte, exemplaires
  /// additionnés ; `null` : sans plafond (D27, spec P-43 E1, A8). La clé est
  /// obligatoire dans le fichier, `null` compris ; le constructeur laisse aux
  /// tests une rune sans plafond.
  final int? maxLevel;

  /// Ce que fait la rune : des sortes de delta, déclarées par niveau (spec
  /// P-43 E1, A1, §4.1). Obligatoire et non vide dans le fichier ; le
  /// constructeur en laisse aux tests une liste vide, qui ne fait rien.
  final List<CardDelta> deltas;
  final int weight;
  final String emoji;

  const ForgeUpgradeData({
    required this.id,
    required this.nameEn,
    required this.nameFr,
    required this.descriptionEn,
    required this.descriptionFr,
    required this.icon,
    required this.color,
    required this.pools,
    this.eligibleCardTypes,
    this.requiresExhaust = false,
    this.stackable = true,
    this.maxLevel,
    this.deltas = const [],
    this.weight = 10,
    this.emoji = '🔮',
  });

  factory ForgeUpgradeData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return ForgeUpgradeData(
      id: id,
      nameEn: json['name_en'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionFr: json['description_fr'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
      pools: List<String>.from(json['pools'] as List? ?? []),
      eligibleCardTypes: json['eligibleCardTypes'] != null
          ? List<String>.from(json['eligibleCardTypes'] as List)
          : null,
      requiresExhaust: json['requiresExhaust'] as bool? ?? false,
      stackable: json['stackable'] as bool? ?? true,
      maxLevel: _readMaxLevel(id, json),
      deltas: _readDeltas(id, json['deltas']),
      weight: json['weight'] as int? ?? 10,
      emoji: json['emoji'] as String? ?? '🔮',
    );
  }

  /// La clé est obligatoire (D27) : `null` pour « sans plafond », sinon un
  /// entier d'au moins 1 — une sentinelle dirait « aucun » par un nombre
  /// (spec P-43 E1, A8).
  static int? _readMaxLevel(String id, Map<String, dynamic> json) {
    if (!json.containsKey('maxLevel')) {
      throw FormatException(
        '$id : maxLevel est obligatoire — null pour « sans plafond »',
      );
    }
    final value = json['maxLevel'];
    if (value == null) return null;
    if (value is! int || value < 1) {
      throw FormatException(
        '$id : maxLevel vaut null ou un entier d\'au moins 1 — reçu : $value',
      );
    }
    return value;
  }

  static List<CardDelta> _readDeltas(String id, Object? raw) {
    if (raw is! List || raw.isEmpty) {
      throw FormatException(
        '$id : deltas doit être une liste non vide — reçu : $raw',
      );
    }
    return [
      for (final entry in raw)
        if (entry is Map<String, dynamic>)
          CardDelta.fromJson(entry)
        else
          throw FormatException('$id : deltas porte "$entry", pas un objet'),
    ];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_fr': nameFr,
      'description_en': descriptionEn,
      'description_fr': descriptionFr,
      'icon': icon,
      'color': color,
      'pools': pools,
      if (eligibleCardTypes != null) 'eligibleCardTypes': eligibleCardTypes,
      'requiresExhaust': requiresExhaust,
      'stackable': stackable,
      'maxLevel': maxLevel,
      'deltas': [for (final delta in deltas) delta.toJson()],
      'weight': weight,
      'emoji': emoji,
    };
  }

  String getName(String locale) {
    return locale == 'fr' ? nameFr : nameEn;
  }

  /// La description de la rune au niveau [level], sur [card] à [rarity] (spec
  /// P-43 E1, §5.1) : `{tier}` est le niveau ; `{percent}`, le pourcentage de
  /// ce niveau ; `{val}`, ce que la rune ajoute à **cette** carte au-delà des
  /// [carried] niveaux qu'elle en porte déjà — le gain que joue le moteur,
  /// calculé par l'applicateur sur le premier effet propre du type visé, 0 si
  /// la carte n'en a pas.
  String getDescription(
    int level,
    String locale,
    CardData card,
    CardRarity rarity, {
    int carried = 0,
  }) {
    final template = locale == 'fr' ? descriptionFr : descriptionEn;
    final bonus = deltas.whereType<PercentBonusDelta>().firstOrNull;
    return template
        .replaceAll('{tier}', '$level')
        .replaceAll('{percent}', '${(bonus?.valuePercentPerLevel ?? 0) * level}')
        .replaceAll('{val}', '${_addedTo(card, rarity, level, carried, bonus)}');
  }

  static int _addedTo(
    CardData card,
    CardRarity rarity,
    int level,
    int carried,
    PercentBonusDelta? bonus,
  ) {
    if (bonus == null) return 0;
    final index = card.effects.indexWhere((e) => e.type == bonus.effect);
    if (index == -1) return 0;
    int valueAt(int total) =>
        EffectiveCard.apply(card, rarity, [(bonus, total)]).effects[index].value;
    return valueAt(carried + level) - valueAt(carried);
  }

  /// La ligne de la rune dans l'infobulle d'une carte, au niveau [level] que
  /// joue le moteur — le total de ses exemplaires (spec P-43 E1, §5.2) :
  /// `<nom>[ <niveau>] : <description>`. Le niveau ne s'écrit que si la rune
  /// en a plus d'un (`maxLevel` autre que 1).
  String tooltipLine(int level, String locale, CardData card, CardRarity rarity) {
    final name = maxLevel == 1 ? getName(locale) : '${getName(locale)} $level';
    return '$name : ${getDescription(level, locale, card, rarity)}';
  }

  /// Les lignes des runes [runes] dans l'infobulle de [card] à [rarity] : une
  /// par id, au niveau total de ses exemplaires ([levelsOf]) ; une rune absente
  /// du registre n'en a pas.
  static List<String> tooltipLines(
    List<String> runes,
    String locale,
    CardData card,
    CardRarity rarity,
  ) =>
      [
        for (final MapEntry(key: id, value: level) in levelsOf(runes).entries)
          if (getById(id) case final rune?)
            rune.tooltipLine(level, locale, card, rarity),
      ];

  /// Lit **une** référence `id:niveau` : `(id, niveau)`, ou `null` si elle est
  /// mal formée ou de niveau nul. L'unique analyseur des références de rune
  /// (ADR-094 D5) : toute règle qui lit un niveau passe par lui ou par
  /// [levelsOf].
  static (String, int)? parseRef(String ref) {
    final parts = ref.split(':');
    if (parts.length != 2) return null;
    final level = int.tryParse(parts[1]);
    return level != null && level > 0 ? (parts[0], level) : null;
  }

  /// Les niveaux de [refs], additionnés par id dans l'ordre de leur première
  /// apparition — le niveau que joue le moteur (D75) ; une référence que
  /// [parseRef] refuse est ignorée.
  static Map<String, int> levelsOf(Iterable<String> refs) {
    final levels = <String, int>{};
    for (final ref in refs) {
      final parsed = parseRef(ref);
      if (parsed == null) continue;
      final (id, level) = parsed;
      levels[id] = (levels[id] ?? 0) + level;
    }
    return levels;
  }

  static ForgeUpgradeData? getById(String id) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return null;
    try {
      return registry.forgeUpgrades.firstWhere((u) => u.id == id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ForgeUpgradeData.getById: no upgrade found for id "$id" ($e)');
      }
      return null;
    }
  }

  static (List<String>, List<MissingSaveItem>) filterValidRefs(
    List<dynamic>? raw,
  ) {
    final kept = <String>[];
    final missing = <MissingSaveItem>[];
    for (final entry in (raw ?? const [])) {
      final ref = entry as String;
      final id = ref.split(':').first;
      if (getById(id) != null) {
        kept.add(ref);
      } else {
        missing.add(
          MissingSaveItem(
            id: id,
            nameFr: id,
            nameEn: id,
            category: 'forgeUpgrade',
          ),
        );
      }
    }
    return (kept, missing);
  }
}
```

- [ ] **Step 4: Les huit fichiers**

In `assets/data/forge_upgrades/sharp.json`, replace:

```json
  "description_en": "+{val} Damage on the card",
  "description_fr": "+{val} Dégâts sur la carte",
```

with:

```json
  "description_en": "+{val} Damage on the card (+{percent}% of base, at least +{tier})",
  "description_fr": "+{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier})",
```

Then replace:

```json
  "valueMultiplier": 2,
  "deltas": [
```

with:

```json
  "maxLevel": null,
  "deltas": [
```

In `assets/data/forge_upgrades/hardened.json`, replace:

```json
  "description_en": "+{val} Block on the card",
  "description_fr": "+{val} Armure sur la carte",
```

with:

```json
  "description_en": "+{val} Block on the card (+{percent}% of base, at least +{tier})",
  "description_fr": "+{val} Armure sur la carte (+{percent}% de la base, au moins +{tier})",
```

Then replace:

```json
  "valueMultiplier": 2,
  "deltas": [
```

with:

```json
  "maxLevel": null,
  "deltas": [
```

In `assets/data/forge_upgrades/quick.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": 1,
  "deltas": [
```

In `assets/data/forge_upgrades/eco.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": 1,
  "deltas": [
```

In `assets/data/forge_upgrades/burning.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": null,
  "deltas": [
```

In `assets/data/forge_upgrades/freezing.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": 1,
  "deltas": [
```

In `assets/data/forge_upgrades/shocking.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": null,
  "deltas": [
```

In `assets/data/forge_upgrades/enduring.json`, replace:

```json
  "deltas": [
```

with:

```json
  "maxLevel": 1,
  "deltas": [
```

- [ ] **Step 5: La fente de la forge**

In `lib/ui/widgets/forge/forge_slot_row.dart`, replace:

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../forge_upgrade_dialog.dart'; // Pour ForgeSlot
import '../game_button.dart';
```

with:

```dart
import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../../models/card_instance.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../forge_upgrade_dialog.dart'; // Pour ForgeSlot
import '../game_button.dart';
```

Then replace:

```dart
class ForgeSlotRow extends StatelessWidget {
  final ForgeSlot slot;
  final int currentGold;
  final String locale;
  final AppLocalizations l10n;
  final VoidCallback onReroll;
  final VoidCallback onSelect;

  const ForgeSlotRow({
    super.key,
    required this.slot,
    required this.currentGold,
    required this.locale,
    required this.l10n,
    required this.onReroll,
    required this.onSelect,
  });
```

with:

```dart
class ForgeSlotRow extends StatelessWidget {
  final ForgeSlot slot;

  /// La carte que la forge améliore : la fente dit ce que la rune lui ajoute
  /// (spec P-43 E1, §5.1).
  final CardInstance card;
  final int currentGold;
  final String locale;
  final AppLocalizations l10n;
  final VoidCallback onReroll;
  final VoidCallback onSelect;

  const ForgeSlotRow({
    super.key,
    required this.slot,
    required this.card,
    required this.currentGold,
    required this.locale,
    required this.l10n,
    required this.onReroll,
    required this.onSelect,
  });
```

Les quatre `switch` de secours par id s'en vont (§5.2). Then replace:

```dart
  }

  String _getUpgradeName(String upgrade) {
    final parts = upgrade.split(':');
    final id = parts[0];
    final tier = parts.length > 1 ? parts[1] : '1';
    final isFr = locale == 'fr';

    switch (id) {
      case 'sharp':
        return isFr ? 'Tranchant $tier' : 'Sharp $tier';
      case 'hardened':
        return isFr ? 'Endurci $tier' : 'Hardened $tier';
      case 'burning':
        return isFr ? 'Brûlant $tier' : 'Burning $tier';
      case 'freezing':
        return isFr ? 'Congelant $tier' : 'Freezing $tier';
      case 'shocking':
        return isFr ? 'Surchargé $tier' : 'Shocking $tier';
      case 'quick':
        return isFr ? 'Véloce $tier' : 'Quick $tier';
      case 'eco':
        return isFr ? 'Économe $tier' : 'Eco $tier';
      case 'enduring':
        return isFr ? 'Persistant' : 'Enduring';
      default:
        return id;
    }
  }

  String _getUpgradeDescription(String upgrade) {
    final parts = upgrade.split(':');
    final id = parts[0];
    final tierStr = parts.length > 1 ? parts[1] : '1';
    final tier = int.tryParse(tierStr) ?? 1;
    final isFr = locale == 'fr';

    switch (id) {
      case 'sharp':
        final val = 2 * tier;
        return isFr ? '+$val Dégâts sur la carte' : '+$val Damage on the card';
      case 'hardened':
        final val = 2 * tier;
        return isFr ? '+$val Armure sur la carte' : '+$val Block on the card';
      case 'burning':
        return isFr ? 'Applique $tier Brûlure' : 'Applies $tier Burn';
      case 'freezing':
        return isFr ? 'Applique $tier Gel' : 'Applies $tier Freeze';
      case 'shocking':
        return isFr ? 'Applique $tier Électrocution' : 'Applies $tier Shock';
      case 'quick':
        return isFr ? 'Pioche +$tier carte(s)' : 'Draw +$tier card(s)';
      case 'eco':
        return isFr ? 'Gagne +$tier Mana à l\'utilisation' : 'Gains +$tier Mana on play';
      case 'enduring':
        return isFr ? 'Retire Épuisement (Exhaust)' : 'Removes Exhaust';
      default:
        return '';
    }
  }

  IconData _getUpgradeIcon(String id) {
    switch (id) {
      case 'sharp':
        return Icons.hardware_rounded;
      case 'hardened':
        return Icons.shield_rounded;
      case 'burning':
        return Icons.local_fire_department_rounded;
      case 'freezing':
        return Icons.ac_unit_rounded;
      case 'shocking':
        return Icons.flash_on_rounded;
      case 'quick':
        return Icons.style_rounded;
      case 'eco':
        return Icons.diamond_rounded;
      case 'enduring':
        return Icons.hourglass_bottom_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Color _getUpgradeColor(String id) {
    switch (id) {
      case 'sharp':
        return Colors.redAccent;
      case 'hardened':
        return Colors.blueAccent;
      case 'burning':
        return Colors.orangeAccent;
      case 'freezing':
        return Colors.lightBlueAccent;
      case 'shocking':
        return Colors.amberAccent;
      case 'quick':
        return Colors.amber;
      case 'eco':
        return Colors.cyanAccent;
      case 'enduring':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Color _getUpgradeColorFromString(String colorStr) {
```

with:

```dart
  }

  Color _getUpgradeColorFromString(String colorStr) {
```

Then replace:

```dart
    final upgradeData = ForgeUpgradeData.getById(upgradeId);

    // Extraction dynamique avec conservation des fallbacks
    final upgradeColor = upgradeData != null
        ? _getUpgradeColorFromString(upgradeData.color)
        : _getUpgradeColor(upgradeId);
    final upgradeIcon = upgradeData != null
        ? _getUpgradeIconFromString(upgradeData.icon)
        : _getUpgradeIcon(upgradeId);
    final upgradeName = upgradeData != null
        ? upgradeData.getName(locale) + (upgradeData.stackable ? ' $tier' : '')
        : _getUpgradeName(slot.upgrade);
    final upgradeDesc = upgradeData != null
        ? upgradeData.getDescription(tier, locale)
        : _getUpgradeDescription(slot.upgrade);
```

with:

```dart
    final upgradeData = ForgeUpgradeData.getById(upgradeId);

    // Une rune absente du registre s'affiche sous son id, sans description,
    // avec l'icône et la couleur par défaut (spec P-43 E1, §5.2).
    final upgradeColor = _getUpgradeColorFromString(upgradeData?.color ?? '');
    final upgradeIcon = _getUpgradeIconFromString(upgradeData?.icon ?? '');
    final upgradeName = upgradeData != null
        ? upgradeData.getName(locale) + (upgradeData.stackable ? ' $tier' : '')
        : upgradeId;
    // Ce que la fente ajoute à cette carte, au-delà de ce que la carte porte
    // déjà de cette rune (spec P-43 E1, §5.1).
    final upgradeDesc = upgradeData?.getDescription(
          tier,
          locale,
          card.data,
          card.rarity,
          carried: ForgeUpgradeData.levelsOf(card.forgeUpgrades)[upgradeId] ?? 0,
        ) ??
        '';
```

In `lib/ui/widgets/forge_upgrade_dialog.dart`, replace:

```dart
                                    ..._slots.map((slot) => ForgeSlotRow(
                                          slot: slot,
```

with:

```dart
                                    ..._slots.map((slot) => ForgeSlotRow(
                                          slot: slot,
                                          card: widget.card,
```

- [ ] **Step 6: Les infobulles et les emoji**

In `lib/game/components/card_component.dart`, replace:

```dart
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
```

with:

```dart
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/forge_upgrade_data.dart';
```

Then replace:

```dart
    if (card.forgeUpgrades.isNotEmpty) {
      desc += '\n\n${activeLocale == 'fr' ? '=== AMÉLIORATIONS DE LA FORGE ===' : '=== FORGE UPGRADES ==='}';
      for (var upgrade in card.forgeUpgrades) {
        final parts = upgrade.split(':');
        final id = parts[0];
        final tierStr = parts.length > 1 ? parts[1] : '1';
        final tier = int.tryParse(tierStr) ?? 1;
        final isFr = activeLocale == 'fr';
        
        String upgName = '';
        String upgDesc = '';
        
        switch (id) {
          case 'sharp':
            upgName = isFr ? 'Tranchant $tier' : 'Sharp $tier';
            final val = 2 * tier;
            upgDesc = isFr ? '+$val Dégâts sur la carte' : '+$val Damage on the card';
            break;
          case 'hardened':
            upgName = isFr ? 'Endurci $tier' : 'Hardened $tier';
            final val = 2 * tier;
            upgDesc = isFr ? '+$val Armure sur la carte' : '+$val Block on the card';
            break;
          case 'burning':
            upgName = isFr ? 'Brûlant $tier' : 'Burning $tier';
            upgDesc = isFr ? 'Applique $tier Brûlure' : 'Applies $tier Burn';
            break;
          case 'freezing':
            upgName = isFr ? 'Congelant $tier' : 'Freezing $tier';
            upgDesc = isFr ? 'Applique $tier Gel' : 'Applies $tier Freeze';
            break;
          case 'shocking':
            upgName = isFr ? 'Surchargé $tier' : 'Shocking $tier';
            upgDesc = isFr ? 'Applique $tier Électrocution' : 'Applies $tier Shock';
            break;
          case 'quick':
            upgName = isFr ? 'Véloce $tier' : 'Quick $tier';
            upgDesc = isFr ? 'Pioche +$tier carte(s)' : 'Draw +$tier card(s)';
            break;
          case 'eco':
            upgName = isFr ? 'Économe $tier' : 'Eco $tier';
            upgDesc = isFr ? 'Gagne +$tier Mana à l\'utilisation' : 'Gains +$tier Mana on play';
            break;
          case 'enduring':
            upgName = isFr ? 'Persistant' : 'Enduring';
            upgDesc = isFr ? 'Retire Épuisement (Exhaust)' : 'Removes Exhaust';
            break;
          default:
            upgName = id;
            upgDesc = '';
        }
        
        desc += '\n• $upgName : $upgDesc';
      }
    }
```

with:

```dart
    // Une ligne par rune, au niveau total de ses exemplaires — celui que joue
    // le moteur —, lue dans la donnée (spec P-43 E1, §5.2).
    final runeLines = ForgeUpgradeData.tooltipLines(
        card.forgeUpgrades, activeLocale, card.data, card.rarity);
    if (runeLines.isNotEmpty) {
      desc += '\n\n${activeLocale == 'fr' ? '=== AMÉLIORATIONS DE LA FORGE ===' : '=== FORGE UPGRADES ==='}';
      for (final line in runeLines) {
        desc += '\n• $line';
      }
    }
```

In `lib/ui/widgets/ui_card/ui_card_helpers.dart`, replace:

```dart
import '../../../models/data/card_data.dart';
import '../../../models/effective_card.dart';
```

with:

```dart
import '../../../models/data/card_data.dart';
import '../../../models/data/forge_upgrade_data.dart';
import '../../../models/effective_card.dart';
```

Then replace:

```dart
String getRuneEmoji(String upgrade) {
  final id = upgrade.split(':')[0];
  switch (id) {
    case 'sharp':
      return '⚔️';
    case 'hardened':
      return '🛡️';
    case 'quick':
      return '🪶';
    case 'eco':
      return '💎';
    case 'burning':
      return '🔥';
    case 'freezing':
      return '❄️';
    case 'shocking':
      return '⚡';
    case 'enduring':
      return '⏳';
    default:
      return '🔮';
  }
}
```

with:

```dart
/// L'emoji d'une rune, lu dans sa donnée comme le rendu Flame le lit déjà
/// (spec P-43 E1, §5.2) ; une rune absente du registre prend l'emoji par
/// défaut.
String getRuneEmoji(String upgrade) =>
    ForgeUpgradeData.getById(upgrade.split(':')[0])?.emoji ?? '🔮';
```

Then replace:

```dart
  final List<String> upgradeDescs = [];
  for (var upgrade in forgeUpgrades) {
    final parts = upgrade.split(':');
    if (parts.length != 2) continue;
    final id = parts[0];
    final k = int.tryParse(parts[1]) ?? 0;
    if (k <= 0) continue;
    switch (id) {
      case 'sharp':
        upgradeDescs.add(activeLocale == 'fr' ? 'Tranchant $k (+${2 * k} Dégâts)' : 'Sharp $k (+${2 * k} Damage)');
        break;
      case 'hardened':
        upgradeDescs.add(activeLocale == 'fr' ? 'Endurci $k (+${2 * k} Armure)' : 'Hardened $k (+${2 * k} Armor)');
        break;
      case 'quick':
        upgradeDescs.add(activeLocale == 'fr' ? 'Véloce $k (+$k Carte(s) piochée(s))' : 'Quick $k (+$k Card(s) drawn)');
        break;
      case 'eco':
        upgradeDescs.add(activeLocale == 'fr' ? 'Économe $k (+$k Mana)' : 'Eco $k (+$k Mana)');
        break;
      case 'burning':
        upgradeDescs.add(activeLocale == 'fr' ? 'Brûlant $k (Applique $k Brûlure)' : 'Burning $k (Apply $k Burn)');
        break;
      case 'freezing':
        upgradeDescs.add(activeLocale == 'fr' ? 'Congelant $k (Applique $k Gel)' : 'Freezing $k (Apply $k Freeze)');
        break;
      case 'shocking':
        upgradeDescs.add(activeLocale == 'fr' ? 'Surchargé $k (Applique $k Électrocution)' : 'Shocking $k (Apply $k Shock)');
        break;
      case 'enduring':
        upgradeDescs.add(activeLocale == 'fr' ? 'Persistant' : 'Enduring');
        break;
    }
  }
  if (upgradeDescs.isNotEmpty) {
    desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
  }
```

with:

```dart
  // Une ligne par rune, au niveau total de ses exemplaires — celui que joue
  // le moteur —, lue dans la donnée (spec P-43 E1, §5.2).
  final upgradeDescs = ForgeUpgradeData.tooltipLines(
      forgeUpgrades, activeLocale, data, cardRarity);
  if (upgradeDescs.isNotEmpty) {
    desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
  }
```

In `lib/ui/widgets/forge/forge_card_preview.dart`, replace:

```dart
import '../../../models/card_instance.dart';
import '../ui_card.dart';
```

with:

```dart
import '../../../models/card_instance.dart';
import '../ui_card.dart';
import '../ui_card/ui_card_helpers.dart';
```

Then replace:

```dart
  });

  String _getRuneEmoji(String upgrade) {
    final id = upgrade.split(':')[0];
    switch (id) {
      case 'sharp':
        return '⚔️';
      case 'hardened':
        return '🛡️';
      case 'quick':
        return '🪶';
      case 'eco':
        return '💎';
      case 'burning':
        return '🔥';
      case 'freezing':
        return '❄️';
      case 'shocking':
        return '⚡';
      case 'enduring':
        return '⏳';
      default:
        return '🔮';
    }
  }

  @override
```

with:

```dart
  });

  @override
```

Then replace:

```dart
                          _getRuneEmoji(upgrade),
```

with:

```dart
                          getRuneEmoji(upgrade),
```

- [ ] **Step 7: Le gabarit de l'éditeur porte `maxLevel`**

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // qu'il ne veut pas.
    template: '''
```

with:

```dart
    // qu'il ne veut pas.
    //
    // `maxLevel` y vaut 1, une valeur prudente : un plafond oublie ne laisse
    // pas monter une rune sans fin (spec P-43 E1, §6).
    template: '''
```

Then replace:

```dart
  "stackable": true,
  "valueMultiplier": 1,
  "deltas": [
```

with:

```dart
  "stackable": true,
  "maxLevel": 1,
  "deltas": [
```

- [ ] **Step 8: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart` — Expected: `+18: All tests passed!`
Run: `flutter test test/unit/decoupled_forge_test.dart` — Expected: `+8: All tests passed!`
Run: `flutter test test/widget/ui_card_values_test.dart` — Expected: `+6: All tests passed!`
Run: `flutter test test/widget/ui_card_rune_sockets_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/widget/forge_upgrade_dialog_test.dart` — Expected: `+1: All tests passed!`
Run: `flutter test test/unit/forge_rune_rules_test.dart test/widget/forge_fusion_screen_test.dart test/unit/content_editor/ test/unit/real_bundle_load_test.dart` — Expected: `All tests passed!`
Run: `git grep -n "valueMultiplier" -- lib assets test` — Expected: aucune sortie.

- [ ] **Step 9: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1291: All tests passed!` (1279 + 5 + 2 + 3 + 1 + 1).

- [ ] **Step 10: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/forge_upgrade_data.dart assets/data/forge_upgrades lib/ui/widgets/forge/forge_slot_row.dart lib/ui/widgets/forge_upgrade_dialog.dart lib/game/components/card_component.dart lib/ui/widgets/ui_card/ui_card_helpers.dart lib/ui/widgets/forge/forge_card_preview.dart lib/services/content_editor/entity_descriptor.dart test/unit/forge_upgrade_data_test.dart test/unit/decoupled_forge_test.dart test/widget/ui_card_values_test.dart test/widget/ui_card_rune_sockets_test.dart test/widget/forge_upgrade_dialog_test.dart test/unit/forge_rune_rules_test.dart test/widget/forge_fusion_screen_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/field_kind_test.dart
git commit -F- <<'EOF'
feat(runes): les textes des runes viennent de leur fichier

Chaque rune declare son maxLevel ; sa description recoit la carte, sa
rarete et ce que la carte porte deja, et dit le gain que joue le moteur.
Les infobulles ecrivent une ligne par rune au niveau total de ses
exemplaires ; les switch d affichage par id et valueMultiplier
disparaissent. Tranchant et Endurci disent leur pourcentage.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: L'éligibilité en donnée — le prédicat et l'offre du feu et de la boutique

D44, D51, D61, D75 : toute règle d'éligibilité est un champ du fichier de rune — `eligibleEffects`, `excludesEffects`, `requiresMinCost`, `excludesRunes` s'ajoutent à `eligibleCardTypes` et `requiresExhaust` —, et un seul prédicat, `ForgeRuneRules.isEligible`, les lit, sur le modèle d'`isOfferableTo` (A3). Ses deux premiers lecteurs sont les tirages du feu et de la boutique, qui gardent `pools` comme ciblage par rareté (D68). Sa condition 7 (D75) lit la borne `ForgeUpgradeData.boundLevel`, qui entre ici ; Task 6 lui donne les quatre endroits qui écrivent un niveau. Le refus de la sélection du feu (A11) est Task 7 ; la boutique qui lit les runes déjà tirées (A12) est Task 6.

Changements de jeu de la tâche, voulus (§4.8) : `hardened` ne s'offre plus qu'à une carte qui donne de l'Armure, `sharp` à toute carte de dégâts (D61) ; plus d'`eco` sur une carte gratuite (D44) ; plus d'`enduring` sur une carte qui pioche ou rend du mana, ni avec `eco` ou `quick` sur une même carte, dans un sens comme dans l'autre (D44, D51) ; `eco`, `quick`, `freezing` et `enduring` ne se reproposent plus à une carte qui les porte (D75). **Aucun `weight` ne change, ni l'`eligibleCardTypes` des six runes autres que `sharp` et `hardened`** (spec §3.2, §9).

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart` (le fichier de Task 4 : quatre champs, leur lecture, `toJson`, `boundLevel`)
- Modify: `lib/game/services/forge_rune_rules.dart` (`isEligible`, après `fusionOptionsFor`)
- Modify: `lib/ui/widgets/forge_upgrade_dialog.dart:80-101`
- Modify: `lib/game/controllers/shop_controller.dart:50-75`
- Modify: `assets/data/forge_upgrades/sharp.json`, `hardened.json`, `eco.json`, `enduring.json`
- Modify: `lib/services/content_editor/entity_descriptor.dart:343-344` et le gabarit
- Modify: `test/unit/shipped_data.dart` (`shippedRuneIds`, `shippedNeutralCards`)
- Test: `test/unit/rune_eligibility_test.dart`, `test/unit/forge_upgrades_catalog_test.dart` *(nouveaux)* ; `test/unit/forge_upgrade_data_test.dart` (deux groupes) ; `test/unit/referential_integrity_test.dart` (un cas, et le cas des types d'effet de Task 1) ; `test/widget/forge_upgrade_dialog_test.dart` (deux cas) ; `test/unit/shop_controller_test.dart:1-11`, `:300-303` (un cas) ; `test/unit/content_editor/entity_descriptor_test.dart` (la table)

**Interfaces:**
- Consumes: `ForgeUpgradeData.levelsOf`, `ForgeUpgradeData.maxLevel` (Tasks 1, 4) ; `CardInstance.currentCost`.
- Produces:
  - `List<String>? ForgeUpgradeData.eligibleEffects` (`null` : toute carte) ; `List<String> excludesEffects` (défaut `const []`) ; `int requiresMinCost` (défaut 0) ; `List<String> excludesRunes` (défaut `const []`).
  - `int ForgeUpgradeData.boundLevel(int requested, {int carried = 0})` — `requested` sans plafond ; sinon `min(requested, maxLevel − carried)`, jamais négatif.
  - `static bool ForgeRuneRules.isEligible(ForgeUpgradeData rune, CardInstance card, Iterable<ForgeUpgradeData> catalog)`.
  - Aide de test : `List<String> shippedRuneIds()`, `List<CardData> shippedNeutralCards()`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/shipped_data.dart`, replace:

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

/// Les ids des fichiers d'un dossier livré, triés.
List<String> _idsIn(String directory) => [
      for (final file in Directory(directory).listSync())
        if (file is File && file.path.endsWith('.json'))
          file.uri.pathSegments.last.replaceAll('.json', ''),
    ]..sort();

/// Les ids des runes livrées.
List<String> shippedRuneIds() => _idsIn('assets/data/forge_upgrades');

/// Les cartes neutres livrées.
List<CardData> shippedNeutralCards() =>
    [for (final id in _idsIn('assets/data/cards')) shippedCard(id)];
```

Create `test/unit/rune_eligibility_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';

ForgeUpgradeData _rune(
  String id, {
  List<String>? eligibleCardTypes,
  List<String>? eligibleEffects,
  List<String> excludesEffects = const [],
  bool requiresExhaust = false,
  int requiresMinCost = 0,
  List<String> excludesRunes = const [],
  int? maxLevel,
  List<CardDelta> deltas = const [],
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
      eligibleCardTypes: eligibleCardTypes,
      eligibleEffects: eligibleEffects,
      excludesEffects: excludesEffects,
      requiresExhaust: requiresExhaust,
      requiresMinCost: requiresMinCost,
      excludesRunes: excludesRunes,
      maxLevel: maxLevel,
      deltas: deltas,
    );

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

bool _eligible(
  ForgeUpgradeData rune,
  CardInstance card, [
  List<ForgeUpgradeData> others = const [],
]) =>
    ForgeRuneRules.isEligible(rune, card, [rune, ...others]);

/// Le prédicat d'éligibilité, condition par condition (spec P-43 E1, §4.6).
void main() {
  test('le type de carte', () {
    final rune = _rune('burning', eligibleCardTypes: const ['attack']);
    expect(_eligible(rune, _card()), isTrue);
    expect(_eligible(rune, _card(type: CardType.skill)), isFalse);
  });

  test('un effet propre du type vise', () {
    final rune = _rune('hardened', eligibleEffects: const ['armor']);
    expect(_eligible(rune, _card()), isFalse);
    expect(
      _eligible(
        rune,
        _card(effects: const [
          CardEffect(type: 'damage', value: 4),
          CardEffect(type: 'armor', value: 4),
        ]),
      ),
      isTrue,
    );
  });

  test('un effet exclu', () {
    final rune = _rune('enduring', excludesEffects: const ['draw']);
    expect(_eligible(rune, _card()), isTrue);
    expect(
      _eligible(
        rune,
        _card(effects: const [
          CardEffect(type: 'damage', value: 3),
          CardEffect(type: 'draw', value: 1),
        ]),
      ),
      isFalse,
    );
  });

  test('l epuisement', () {
    final rune = _rune('enduring', requiresExhaust: true);
    expect(_eligible(rune, _card()), isFalse);
    expect(_eligible(rune, _card(isExhaust: true)), isTrue);
  });

  test('le cout courant atteint le minimum', () {
    final rune = _rune('eco', requiresMinCost: 1);
    expect(_eligible(rune, _card(cost: 0)), isFalse);
    expect(_eligible(rune, _card(cost: 1)), isTrue);
  });

  group('la symetrie des exclusions (D51, D61)', () {
    final eco = _rune('eco');
    final enduring = _rune('enduring', excludesRunes: const ['eco']);

    test('une rune portee qui exclut la candidate la refuse', () {
      expect(_eligible(eco, _card(runes: const ['enduring:1']), [enduring]),
          isFalse);
    });

    test('une candidate qui exclut une rune portee est refusee', () {
      expect(_eligible(enduring, _card(runes: const ['eco:1']), [eco]),
          isFalse);
    });
  });

  test('le plafond atteint par deux exemplaires additionnes', () {
    final rune = _rune('capped', maxLevel: 2);
    expect(_eligible(rune, _card(runes: const ['capped:1'])), isTrue);
    expect(_eligible(rune, _card(runes: const ['capped:1', 'capped:1'])),
        isFalse);
  });

  test('une rune sans plafond se repropose', () {
    expect(_eligible(_rune('sharp'), _card(runes: const ['sharp:5'])), isTrue);
  });

  test('un effet ajoute par une rune ne compte pas', () {
    // Veloce fait piocher la carte, mais la pioche n'est pas un effet propre.
    final quick = _rune('quick', deltas: const [
      AddEffectDelta(effect: 'draw', valuePerLevel: 1),
    ]);
    final card = _card(runes: const ['quick:1']);
    expect(_eligible(_rune('enduring', excludesEffects: const ['draw']), card,
        [quick]), isTrue);
    expect(_eligible(_rune('scribe', eligibleEffects: const ['draw']), card,
        [quick]), isFalse);
  });

  test('une rune portee absente du catalogue est ignoree', () {
    final rune = _rune('enduring', excludesRunes: const ['legacy']);
    expect(_eligible(rune, _card(runes: const ['legacy:1'])), isTrue);
  });

  // Review Focus 2 : une sauvegarde d'avant 0.5.3 peut porter eco:3.
  test('une carte deja au-dela du plafond ne se voit pas reproposer la rune',
      () {
    expect(_eligible(_rune('eco', maxLevel: 1), _card(runes: const ['eco:3'])),
        isFalse);
  });
}
```

Create `test/unit/forge_upgrades_catalog_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

const _threePools = ['common', 'uncommon', 'rare'];
const _allTypes = ['attack', 'skill', 'power'];

/// Ce que déclare une rune, sous une forme comparable.
Map<String, Object?> _declared(ForgeUpgradeData rune) => {
      'pools': rune.pools,
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

/// Les huit runes, telles que la spec P-43 E1 les fixe (§3.2). Les `weight`
/// et les `eligibleCardTypes` des six runes autres que `sharp` et `hardened`
/// sont ceux que la simulation lit : ils ne bougent pas (§9).
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
    eligibleCardTypes: _allTypes,
    maxLevel: 1,
    deltas: const [
      {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 1},
    ],
    weight: 60,
  ),
  'eco': _rune(
    pools: const ['rare'],
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

const _attack = {'sharp', 'burning', 'freezing', 'shocking', 'quick', 'eco'};

/// La matrice de l'offre sur les 23 cartes livrées, sans rune, à leur rareté de
/// donnée — `pools` mis à part, que les tirages appliquent ensuite (§4.8).
const _offers = <String, Set<String>>{
  'strike_basic': _attack,
  'heavy_strike': _attack,
  'fireball': _attack,
  'ice_bolt': _attack,
  'poison_stab': _attack,
  'quick_attack': _attack,
  'sweep': _attack,
  'thunder_clap': _attack,
  'reckless_strike': _attack,
  'magic_missile': _attack,
  'warcry': {..._attack, 'hardened'},
  'smite': {..._attack, 'hardened'},
  'awakening': {'hardened', 'quick', 'eco'},
  'defend_basic': {'hardened', 'quick', 'eco'},
  'iron_wall': {'hardened', 'quick', 'eco'},
  'holy_shield': {'hardened', 'quick', 'eco', 'enduring'},
  'heal_potion': {'quick', 'eco', 'enduring'},
  'demon_form': {'quick', 'eco'},
  'metallicize': {'quick', 'eco'},
  'rage_form': {'quick', 'eco'},
  'concentration': {'quick'},
  'focus': {'quick'},
  'mana_surge': {'quick'},
};

/// Les huit runes livrées, et l'offre qu'elles font aux 23 cartes livrées
/// (spec P-43 E1, §3.2, §4.8, §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;

  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  // `maxLevel` est obligatoire au chargement (A8) : une rune chargée porte la
  // clé, `null` compris.
  for (final MapEntry(key: id, value: expected) in _expected.entries) {
    test('$id declare ce que la spec fixe', () {
      final rune = registry.forgeUpgrades.singleWhere((r) => r.id == id);
      expect(_declared(rune), expected);
    });
  }

  test('la matrice couvre les 23 cartes livrees', () {
    expect(registry.cards.map((c) => c.id).toSet(), _offers.keys.toSet());
  });

  for (final MapEntry(key: cardId, value: runes) in _offers.entries) {
    test('$cardId recoit ${runes.length} rune(s)', () {
      final card =
          CardInstance(data: registry.cards.singleWhere((c) => c.id == cardId));
      expect(
        {
          for (final rune in registry.forgeUpgrades)
            if (ForgeRuneRules.isEligible(rune, card, registry.forgeUpgrades))
              rune.id,
        },
        runes,
      );
    });
  }
}
```

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
  group('references id:niveau', () {
```

with:

```dart
  group('eligibilite', () {
    test('lit les champs d eligibilite', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'eligibleEffects': ['damage'],
        'excludesEffects': ['draw'],
        'requiresMinCost': 1,
        'excludesRunes': ['eco'],
      }));
      expect(rune.eligibleEffects, ['damage']);
      expect(rune.excludesEffects, ['draw']);
      expect(rune.requiresMinCost, 1);
      expect(rune.excludesRunes, ['eco']);
    });

    test('absents : toute carte, aucune exclusion, aucun cout minimal', () {
      final rune = ForgeUpgradeData.fromJson(_json());
      expect(rune.eligibleEffects, isNull);
      expect(rune.excludesEffects, isEmpty);
      expect(rune.requiresMinCost, 0);
      expect(rune.excludesRunes, isEmpty);
    });

    test('refuse eligibleEffects vide, eligible a rien', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'eligibleEffects': []})),
          _refused('eligibleEffects'));
    });

    test('accepte excludesEffects vide : aucune exclusion', () {
      expect(
        ForgeUpgradeData.fromJson(_json({'excludesEffects': []}))
            .excludesEffects,
        isEmpty,
      );
    });

    test('refuse un requiresMinCost negatif ou non entier', () {
      for (final bad in [-1, 1.5]) {
        expect(() => ForgeUpgradeData.fromJson(_json({'requiresMinCost': bad})),
            _refused('requiresMinCost'),
            reason: '$bad');
      }
    });

    test('refuse excludesRunes vide', () {
      expect(() => ForgeUpgradeData.fromJson(_json({'excludesRunes': []})),
          _refused('excludesRunes'));
    });

    test('refuse son propre id dans excludesRunes', () {
      expect(
        () => ForgeUpgradeData.fromJson(_json({
          'excludesRunes': ['eco', 'sharp'],
        })),
        _refused('excludesRunes'),
      );
    });

    test('toJson fait l aller-retour des champs d eligibilite', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'eligibleEffects': ['armor'],
        'excludesEffects': ['gain_mana', 'draw'],
        'requiresMinCost': 1,
        'excludesRunes': ['quick'],
      }));
      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(restored.eligibleEffects, ['armor']);
      expect(restored.excludesEffects, ['gain_mana', 'draw']);
      expect(restored.requiresMinCost, 1);
      expect(restored.excludesRunes, ['quick']);
    });
  });

  group('boundLevel', () {
    final uncapped = ForgeUpgradeData.fromJson(_json());
    final capped = ForgeUpgradeData.fromJson(_json({'maxLevel': 2}));

    test('sans plafond : la demande', () {
      expect(uncapped.boundLevel(3), 3);
      expect(uncapped.boundLevel(3, carried: 5), 3);
    });

    test('un plafond borne la demande', () {
      expect(capped.boundLevel(1), 1);
      expect(capped.boundLevel(3), 2);
    });

    test('ce que la carte porte deja compte', () {
      expect(capped.boundLevel(3, carried: 1), 1);
      expect(capped.boundLevel(1, carried: 2), 0);
    });

    // Review Focus 2 : une sauvegarde d'avant 0.5.3 peut porter plus que le
    // plafond.
    test('jamais negatif', () {
      expect(capped.boundLevel(1, carried: 3), 0);
    });
  });

  group('references id:niveau', () {
```

In `test/unit/referential_integrity_test.dart`, replace:

```dart
    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final delta in rune.deltas)
          if (_effectOf(delta) case final type?
              when strategies.get(type) == null)
            '${rune.id} → type d effet "$type" sans stratégie',
    ];
```

with:

```dart
    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final type in {
          ...?rune.eligibleEffects,
          ...rune.excludesEffects,
          for (final delta in rune.deltas) ?_effectOf(delta),
        })
          if (strategies.get(type) == null)
            '${rune.id} → type d effet "$type" sans stratégie',
    ];
```

Then replace:

```dart
  test('chaque statut que pose une rune est fabrique par createStatus', () {
```

with:

```dart
  test('chaque id d excludesRunes designe une rune livree', () {
    final known = registry.forgeUpgrades.map((r) => r.id).toSet();
    final offenders = [
      for (final rune in registry.forgeUpgrades)
        for (final id in rune.excludesRunes)
          if (!known.contains(id)) '${rune.id} → excludesRunes "$id" introuvable',
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque statut que pose une rune est fabrique par createStatus', () {
```

In `test/widget/forge_upgrade_dialog_test.dart`, replace:

```dart
/// L'offre de la forge du feu (spec P-43 E1, §4.6, §4.7, §5.1).
void main() {
```

with:

```dart
/// Les fentes `id:niveau` que la forge propose à [card] : celles de départ,
/// puis celles de [rerolls] relances de la première.
Future<Set<String>> _offeredSlots(
  WidgetTester tester,
  CardInstance card, {
  int rerolls = 20,
}) async {
  final container = await _pumpDialog(tester, card);
  Iterable<String> slots() =>
      (container.read(runProvider).forgeTargetSessions[card.uniqueId] ??
              const <String>[])
          .map((slot) => slot.split(':').take(2).join(':'));

  final offered = {...slots()};
  for (var i = 0; i < rerolls; i++) {
    await tester.tap(find.byIcon(Icons.autorenew).first);
    await tester.pump();
    offered.addAll(slots());
  }
  return offered;
}

Set<String> _ids(Set<String> slots) =>
    {for (final slot in slots) slot.split(':').first};

/// L'offre de la forge du feu (spec P-43 E1, §4.6, §4.7, §5.1).
void main() {
  testWidgets('aucune fente ne propose Endurci sur une Frappe', (tester) async {
    shippedRuneRegistry(const ['sharp', 'hardened']);

    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('strike_basic')));

    expect(_ids(offered), {'sharp'});
  });

  testWidgets('aucune fente ne propose Econome sur une Concentration',
      (tester) async {
    // Une carte gratuite, qui pioche : seule Veloce lui reste (D44).
    shippedRuneRegistry(const ['eco', 'quick']);

    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('concentration')));

    expect(_ids(offered), {'quick'});
  });

```

In `test/unit/shop_controller_test.dart`, replace:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/shop_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
```

with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/game/controllers/shop_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/services/forge_rune_rules.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';

import 'shipped_data.dart';
```

Then replace:

```dart
      expect(rolled, {CardRarity.epic, CardRarity.legendary});
    });

    test('la boutique ne tire une rune non cumulable qu au tier 1', () {
```

with:

```dart
      expect(rolled, {CardRarity.epic, CardRarity.legendary});
    });

    test('la boutique ne pose une premiere rune qu eligible a la carte', () {
      // Les runes et les cartes livrees ; le registre vide le remplace en
      // sortie, comme au cas suivant.
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
      final catalog = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.forgeUpgrades.isEmpty) continue;
          final (id, _) = ForgeUpgradeData.parseRef(card.forgeUpgrades.first)!;
          final rune = catalog.singleWhere((r) => r.id == id);
          expect(
            ForgeRuneRules.isEligible(
                rune, card.copyWith(forgeUpgrades: const []), catalog),
            isTrue,
            reason: '${card.data.id} : ${card.forgeUpgrades}',
          );
        }
      }
    });

    test('la boutique ne tire une rune non cumulable qu au tier 1', () {
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:

```dart
        'pools',
        'eligibleCardTypes',
        'requiresExhaust',
        'stackable',
```

with:

```dart
        'pools',
        'eligibleCardTypes',
        'eligibleEffects',
        'excludesEffects',
        'requiresExhaust',
        'requiresMinCost',
        'stackable',
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/rune_eligibility_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/forge_upgrade_data_test.dart`
Expected: échec à la compilation — `ForgeUpgradeData` n'a ni `eligibleEffects`, ni `excludesEffects`, ni `requiresMinCost`, ni `excludesRunes`, ni `boundLevel` ; `ForgeRuneRules.isEligible` n'existe pas.

- [ ] **Step 3: Le modèle — quatre champs et la borne**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
import 'package:flutter/foundation.dart';
import 'card_data.dart';
```

with:

```dart
import 'dart:math' show max, min;

import 'package:flutter/foundation.dart';
import 'card_data.dart';
```

Then replace:

```dart
  final List<String>? eligibleCardTypes;
  final bool requiresExhaust;
```

with:

```dart
  final List<String>? eligibleCardTypes;

  /// Les types d'effet dont la carte doit porter au moins un, parmi ses effets
  /// propres ; `null` : toute carte (D61). Jamais vide : `[]` serait « éligible
  /// à rien ».
  final List<String>? eligibleEffects;

  /// Les types d'effet qu'aucun effet propre de la carte ne doit porter (D44).
  final List<String> excludesEffects;
  final bool requiresExhaust;

  /// Le coût courant minimal de la carte (D44, D61) : `eco` ne vient pas sur
  /// une carte gratuite.
  final int requiresMinCost;

  /// Les runes avec lesquelles celle-ci ne cohabite pas sur une carte (D51) ;
  /// le prédicat lit la règle dans les deux sens (D61).
  final List<String> excludesRunes;
```

Then replace:

```dart
    this.eligibleCardTypes,
    this.requiresExhaust = false,
```

with:

```dart
    this.eligibleCardTypes,
    this.eligibleEffects,
    this.excludesEffects = const [],
    this.requiresExhaust = false,
    this.requiresMinCost = 0,
    this.excludesRunes = const [],
```

Then replace:

```dart
      requiresExhaust: json['requiresExhaust'] as bool? ?? false,
      stackable: json['stackable'] as bool? ?? true,
      maxLevel: _readMaxLevel(id, json),
```

with:

```dart
      eligibleEffects:
          _readNames(id, json, 'eligibleEffects', allowEmpty: false),
      excludesEffects:
          _readNames(id, json, 'excludesEffects', allowEmpty: true) ??
              const [],
      requiresExhaust: json['requiresExhaust'] as bool? ?? false,
      requiresMinCost: _readMinCost(id, json['requiresMinCost']),
      excludesRunes: _readExcludedRunes(id, json),
      stackable: json['stackable'] as bool? ?? true,
      maxLevel: _readMaxLevel(id, json),
```

Then replace:

```dart
  /// La clé est obligatoire (D27) : `null` pour « sans plafond », sinon un
```

with:

```dart
  /// Une liste de noms facultative : `null` si la clé est absente. Une liste
  /// vide n'est admise que si [allowEmpty] — `eligibleEffects: []` serait
  /// « éligible à rien », `excludesRunes: []` ne dirait rien.
  static List<String>? _readNames(
    String id,
    Map<String, dynamic> json,
    String key, {
    required bool allowEmpty,
  }) {
    final raw = json[key];
    if (raw == null) return null;
    if (raw is! List ||
        raw.any((name) => name is! String) ||
        (raw.isEmpty && !allowEmpty)) {
      throw FormatException(
        '$id : $key doit être une liste ${allowEmpty ? '' : 'non vide '}de '
        'noms — reçu : $raw',
      );
    }
    return List<String>.unmodifiable(raw);
  }

  static int _readMinCost(String id, Object? raw) {
    if (raw == null) return 0;
    if (raw is! int || raw < 0) {
      throw FormatException(
        '$id : requiresMinCost vaut un entier d\'au moins 0 — reçu : $raw',
      );
    }
    return raw;
  }

  /// Absente : aucune. Sinon une liste non vide d'ids de rune, qui ne nomme
  /// pas la rune elle-même ; l'existence des ids, que le chargeur ne voit pas,
  /// est vérifiée par le test d'intégrité et par l'éditeur (spec P-43 E1,
  /// §3.1).
  static List<String> _readExcludedRunes(String id, Map<String, dynamic> json) {
    final runes = _readNames(id, json, 'excludesRunes', allowEmpty: false);
    if (runes == null) return const [];
    if (runes.contains(id)) {
      throw FormatException(
        '$id : excludesRunes ne peut pas nommer la rune elle-même',
      );
    }
    return runes;
  }

  /// La clé est obligatoire (D27) : `null` pour « sans plafond », sinon un
```

Then replace:

```dart
      if (eligibleCardTypes != null) 'eligibleCardTypes': eligibleCardTypes,
      'requiresExhaust': requiresExhaust,
```

with:

```dart
      if (eligibleCardTypes != null) 'eligibleCardTypes': eligibleCardTypes,
      if (eligibleEffects != null) 'eligibleEffects': eligibleEffects,
      if (excludesEffects.isNotEmpty) 'excludesEffects': excludesEffects,
      'requiresExhaust': requiresExhaust,
      'requiresMinCost': requiresMinCost,
      if (excludesRunes.isNotEmpty) 'excludesRunes': excludesRunes,
```

Then replace:

```dart
  /// Lit **une** référence `id:niveau` : `(id, niveau)`, ou `null` si elle est
```

with:

```dart
  /// La borne de niveau (D72, D75) : [requested] sans plafond ; sinon ce
  /// qu'il reste sous `maxLevel` une fois comptés les [carried] niveaux que la
  /// carte porte déjà — jamais négatif (spec P-43 E1, §4.7).
  int boundLevel(int requested, {int carried = 0}) {
    final cap = maxLevel;
    if (cap == null) return requested;
    return max(0, min(requested, cap - carried));
  }

  /// Lit **une** référence `id:niveau` : `(id, niveau)`, ou `null` si elle est
```

- [ ] **Step 4: Le prédicat**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }
}
```

with:

```dart
        cost: 80 * (runes.length - 1),
      ));
    });
    return options;
  }

  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de
  /// l'éligibilité (D44, D51, D61, D75 ; spec P-43 E1, A3, §4.6) : une
  /// fonction pure, sur le modèle de `CardData.isOfferableTo` — toute règle
  /// est un champ du fichier de rune, aucune n'est un `case` par id. [catalog]
  /// sert à lire les exclusions des runes que la carte porte déjà. `pools`
  /// n'en est pas une condition : c'est le ciblage par rareté des tirages,
  /// qui le gardent (D68).
  static bool isEligible(
    ForgeUpgradeData rune,
    CardInstance card,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final types = rune.eligibleCardTypes;
    if (types != null && !types.contains(card.data.type.name)) return false;

    // Les effets propres de la carte, jamais ceux qu'une rune lui ajoute.
    final own = {for (final effect in card.data.effects) effect.type};
    final wanted = rune.eligibleEffects;
    if (wanted != null && !wanted.any(own.contains)) return false;
    if (rune.excludesEffects.any(own.contains)) return false;

    if (rune.requiresExhaust && !card.data.isExhaust) return false;
    if (card.currentCost < rune.requiresMinCost) return false;

    // La symétrie des exclusions : une rune portée absente du catalogue est
    // ignorée.
    final carried = ForgeUpgradeData.levelsOf(card.forgeUpgrades);
    for (final id in carried.keys) {
      final other = catalog.where((r) => r.id == id).firstOrNull;
      if (other == null) continue;
      if (rune.excludesRunes.contains(id) ||
          other.excludesRunes.contains(rune.id)) {
        return false;
      }
    }

    // D75 : une rune dont la carte a atteint le plafond ne se repropose pas.
    return rune.boundLevel(1, carried: carried[rune.id] ?? 0) >= 1;
  }
}
```

- [ ] **Step 5: Les deux offres lisent le prédicat**

In `lib/ui/widgets/forge_upgrade_dialog.dart`, replace:

```dart
  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return [];

    final eligible = <String>[];
    for (final upgrade in registry.forgeUpgrades) {
      if (!upgrade.pools.contains(poolName)) continue;

      // Card type specific exclusions:
      if (upgrade.eligibleCardTypes != null &&
          !upgrade.eligibleCardTypes!.contains(card.data.type.name)) {
        continue;
      }

      if (upgrade.requiresExhaust && !card.data.isExhaust) {
        continue;
      }

      eligible.add(upgrade.id);
    }
    return eligible;
  }
```

with:

```dart
  /// Les runes éligibles du pool [poolName] pour [card] : `pools` reste le
  /// ciblage par rareté du tirage, tout le reste est le prédicat, lu dans la
  /// donnée (spec P-43 E1, §4.6).
  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return [];

    final catalog = registry.forgeUpgrades;
    return [
      for (final upgrade in catalog)
        if (upgrade.pools.contains(poolName) &&
            ForgeRuneRules.isEligible(upgrade, card, catalog))
          upgrade.id,
    ];
  }
```

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
  /// Helper pour obtenir les upgrades éligibles selon le pool de rareté et le type de carte
  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName, List<String> currentRolls) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return [];

    final eligible = <String>[];
    for (final upgrade in registry.forgeUpgrades) {
      if (!upgrade.pools.contains(poolName)) continue;

      final alreadyInRolls = currentRolls.any((u) => u.split(':')[0] == upgrade.id);
      if (alreadyInRolls) continue;

      // Exclusions spécifiques au type de carte:
      if (upgrade.eligibleCardTypes != null &&
          !upgrade.eligibleCardTypes!.contains(card.data.type.name)) {
        continue;
      }

      if (upgrade.requiresExhaust && !card.data.isExhaust) {
        continue;
      }

      eligible.add(upgrade.id);
    }
    return eligible;
  }
```

with:

```dart
  /// Les runes éligibles du pool [poolName] pour [card], hors celles déjà
  /// tirées ([currentRolls]) : `pools` reste le ciblage par rareté du tirage,
  /// tout le reste est le prédicat, lu dans la donnée (spec P-43 E1, §4.6).
  List<String> _getEligibleUpgradesForPool(CardInstance card, String poolName, List<String> currentRolls) {
    final registry = GameDataRegistry.instance;
    if (registry == null) return [];

    final catalog = registry.forgeUpgrades;
    return [
      for (final upgrade in catalog)
        if (upgrade.pools.contains(poolName) &&
            !currentRolls.any((u) => u.split(':')[0] == upgrade.id) &&
            ForgeRuneRules.isEligible(upgrade, card, catalog))
          upgrade.id,
    ];
  }
```

- [ ] **Step 6: Les fichiers de rune déclarent leur éligibilité**

In `assets/data/forge_upgrades/sharp.json`, replace:

```json
  "eligibleCardTypes": [
    "attack"
  ],
  "maxLevel": null,
```

with:

```json
  "eligibleEffects": [
    "damage"
  ],
  "maxLevel": null,
```

In `assets/data/forge_upgrades/hardened.json`, replace:

```json
  "eligibleCardTypes": [
    "attack",
    "skill"
  ],
  "maxLevel": null,
```

with:

```json
  "eligibleEffects": [
    "armor"
  ],
  "maxLevel": null,
```

In `assets/data/forge_upgrades/eco.json`, replace:

```json
  "maxLevel": 1,
```

with:

```json
  "requiresMinCost": 1,
  "maxLevel": 1,
```

In `assets/data/forge_upgrades/enduring.json`, replace:

```json
  "requiresExhaust": true,
```

with:

```json
  "requiresExhaust": true,
  "excludesEffects": [
    "gain_mana",
    "draw"
  ],
  "excludesRunes": [
    "eco",
    "quick"
  ],
```

- [ ] **Step 7: Le gabarit de l'éditeur**

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // absente, la cle vaut « tous les types » (`shop_controller.dart:65` ne
    // filtre que si elle est non nulle), tandis qu'une liste vide n'aurait
```

with:

```dart
    // absente, la cle vaut « tous les types » (`ForgeRuneRules.isEligible` ne
    // filtre que si elle est presente), tandis qu'une liste vide n'aurait
```

Then replace:

```dart
    // pas monter une rune sans fin (spec P-43 E1, §6).
```

with:

```dart
    // pas monter une rune sans fin (spec P-43 E1, §6). `eligibleEffects` y
    // porte l'exemple du delta, `damage` ; `excludesRunes` n'y figure pas :
    // absente, elle vaut « aucune », comme `classes` d'un passif.
```

Then replace:

```dart
  "eligibleCardTypes": ["attack", "skill", "power", "status"],
  "requiresExhaust": false,
  "stackable": true,
```

with:

```dart
  "eligibleCardTypes": ["attack", "skill", "power", "status"],
  "eligibleEffects": ["damage"],
  "excludesEffects": [],
  "requiresExhaust": false,
  "requiresMinCost": 0,
  "stackable": true,
```

- [ ] **Step 8: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/rune_eligibility_test.dart` — Expected: `+12: All tests passed!`
Run: `flutter test test/unit/forge_upgrades_catalog_test.dart` — Expected: `+32: All tests passed!`
Run: `flutter test test/unit/forge_upgrade_data_test.dart` — Expected: `+30: All tests passed!`
Run: `flutter test test/unit/referential_integrity_test.dart` — Expected: `+10: All tests passed!`
Run: `flutter test test/widget/forge_upgrade_dialog_test.dart` — Expected: `+3: All tests passed!`
Run: `flutter test test/unit/shop_controller_test.dart test/unit/content_editor/ test/unit/real_bundle_load_test.dart` — Expected: `All tests passed!`

- [ ] **Step 9: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1351: All tests passed!` (1291 + 12 + 32 + 12 + 1 + 2 + 1).

- [ ] **Step 10: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/models/data/forge_upgrade_data.dart lib/game/services/forge_rune_rules.dart lib/ui/widgets/forge_upgrade_dialog.dart lib/game/controllers/shop_controller.dart assets/data/forge_upgrades lib/services/content_editor/entity_descriptor.dart test/unit/shipped_data.dart test/unit/rune_eligibility_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/forge_upgrade_data_test.dart test/unit/referential_integrity_test.dart test/widget/forge_upgrade_dialog_test.dart test/unit/shop_controller_test.dart test/unit/content_editor/entity_descriptor_test.dart
git commit -F- <<'EOF'
feat(runes): l eligibilite d une rune est un champ de son fichier

Un seul predicat, ForgeRuneRules.isEligible, lit le type de carte, les
effets propres vises ou exclus, l epuisement, le cout courant, les runes
exclues dans les deux sens et le plafond deja atteint. La forge du feu
et la boutique le lisent ; pools reste leur ciblage par rarete. Endurci
ne vient plus que sur une carte d armure, Econome plus sur une carte
gratuite, Persistant plus avec la pioche ni avec Econome ou Veloce.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: La borne `maxLevel` aux quatre endroits qui écrivent un niveau, et la boutique qui lit ses tirages

D72 : `ForgeUpgradeData.boundLevel` borne la fusion de cartes (`consolidate`, A9 — le surplus se perd), le nœud Forge de Fusion (`fusionOptionsFor`, A10 — une fusion qui perdrait un niveau n'est pas proposée), le tirage de niveau du feu et celui des pré-forgées (§4.7). La boutique lit désormais la carte **avec les runes déjà tirées** : le prédicat de Task 5 y écarte une rune plafonnée déjà posée, et une carte à qui ne reste aucune rune éligible en reçoit moins — le repli sur `'sharp'` disparaît (A12). Le repli sans exclusion reste, pour les runes sans plafond : deux `sharp` sur une pré-forgée restent possibles, « une rune par type » est E2.

Le tirage du feu est borné **par ce que la carte porte déjà** : le prédicat ne lui propose qu'une rune dont le plafond n'est pas atteint, la borne rend donc toujours un niveau d'au moins 1 — le repli du feu sur `'sharp'`, rune sans plafond, aussi. Ce repli disparaît en Task 7 avec le refus de la sélection (A11).

Changements de jeu de la tâche, voulus (§4.8) : `eco`, `quick`, `freezing` et `enduring` ne dépassent plus le niveau 1 — au feu, à la fusion de cartes, à la Forge de Fusion, en boutique — et une pré-forgée n'en porte plus deux exemplaires ; une pré-forgée sans rune éligible en porte une de moins.

**Files:**
- Modify: `lib/game/services/forge_rune_rules.dart` (`consolidate` de Task 1), `:57-59`, et le corps de `fusionOptionsFor` de Task 1
- Modify: `lib/ui/widgets/forge_upgrade_dialog.dart:186`
- Modify: `lib/game/controllers/shop_controller.dart:136-141`, `:154`, `:215-222`
- Test: `test/unit/forge_rune_rules_test.dart:8-18`, `:44-48`, et deux groupes (quatre cas) ; `test/unit/decoupled_forge_test.dart` (le registre de Task 4, deux cas) ; `test/widget/forge_fusion_screen_test.dart` (un cas) ; `test/unit/shop_controller_test.dart` (trois cas) ; `test/widget/forge_upgrade_dialog_test.dart` (un cas)

**Interfaces:**
- Consumes: `ForgeUpgradeData.boundLevel`, `ForgeRuneRules.isEligible` (Task 5) ; `ForgeUpgradeData.levelsOf`, `parseRef` (Task 1).
- Produces: `consolidate` et `fusionOptionsFor` bornés ; `ShopController._rollRandomUpgrade(CardInstance card, Random rng)` rend `String?` et lit la carte avec ses runes déjà tirées.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
ForgeUpgradeData _rune(String id, {bool stackable = true}) => ForgeUpgradeData(
      id: id,
      nameEn: id,
      nameFr: id,
      descriptionEn: '',
      descriptionFr: '',
      icon: '',
      color: '',
      pools: const ['common'],
      stackable: stackable,
    );
```

with:

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

Then replace:

```dart
      forgeUpgrades: [
        _rune('sharp'),
        _rune('hardened'),
        _rune('enduring', stackable: false),
      ],
```

with:

```dart
      forgeUpgrades: [
        _rune('sharp'),
        _rune('hardened'),
        _rune('enduring', stackable: false),
        _rune('eco', maxLevel: 1),
        _rune('capped', maxLevel: 2),
      ],
```

Then replace:

```dart
    test('traite une rune absente du registre comme cumulable', () {
```

with:

```dart
    test('borne la somme au plafond de la rune : le surplus se perd', () {
      expect(ForgeRuneRules.consolidate(['capped:1', 'capped:2']), ['capped:2']);
    });

    test('traite une rune absente du registre comme cumulable', () {
```

Then replace:

```dart
    test('jamais de fusion pour une rune non cumulable', () {
```

with:

```dart
    test('deux eco:1 : aucune option, la fusion perdrait un niveau', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['eco:1', 'eco:1'])),
        isEmpty,
      );
    });

    test('1 + 1 sous un plafond de 2 : proposee', () {
      final options =
          ForgeRuneRules.fusionOptionsFor(_cardWith(['capped:1', 'capped:1']));
      expect(options.single.totalTier, 2);
    });

    test('2 + 1 sous un plafond de 2 : non proposee', () {
      expect(
        ForgeRuneRules.fusionOptionsFor(_cardWith(['capped:2', 'capped:1'])),
        isEmpty,
      );
    });

    test('jamais de fusion pour une rune non cumulable', () {
```

In `test/unit/decoupled_forge_test.dart`, replace:

```dart
          const ForgeUpgradeData(
            id: 'enduring',
```

with:

```dart
          const ForgeUpgradeData(
            id: 'eco',
            nameEn: 'Eco',
            nameFr: 'Économe',
            descriptionEn: 'Gains +{tier} Mana on play',
            descriptionFr: 'Gagne +{tier} Mana à l\'utilisation',
            icon: 'diamond_rounded',
            color: 'cyanAccent',
            pools: ['rare'],
            maxLevel: 1,
            deltas: [AddEffectDelta(effect: 'gain_mana', valuePerLevel: 1)],
            weight: 40,
          ),
          const ForgeUpgradeData(
            id: 'enduring',
```

Then replace:

```dart
    test('mergeCards garde une seule rune non cumulable, au tier 1', () {
```

with:

```dart
    List<CardInstance> threeCopies(List<String> runes) => List.generate(
          3,
          (_) => CardInstance(data: strike, forgeUpgrades: runes),
        );

    test('mergeCards borne trois eco:1 a eco:1 (spec P-43 E1, A9)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final copies = threeCopies(const ['eco:1']);
      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.initializeStarterDeck(copies);

      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        const ['eco:1', 'eco:1', 'eco:1'],
      );

      expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
          ['eco:1']);
    });

    test('mergeCards additionne trois sharp:1 en sharp:3', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final copies = threeCopies(const ['sharp:1']);
      final deckNotifier = container.read(deckProvider.notifier);
      deckNotifier.initializeStarterDeck(copies);

      deckNotifier.mergeCards(
        copies.map((c) => c.uniqueId).toList(),
        const ['sharp:1', 'sharp:1', 'sharp:1'],
      );

      expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
          ['sharp:3']);
    });

    test('mergeCards garde une seule rune non cumulable, au tier 1', () {
```

In `test/widget/forge_fusion_screen_test.dart`, replace:

```dart
  const enduringUpgrade = ForgeUpgradeData(
```

with:

```dart
  const ecoUpgrade = ForgeUpgradeData(
    id: 'eco',
    nameEn: 'Eco',
    nameFr: 'Économe',
    descriptionEn: 'Gains +{tier} Mana on play',
    descriptionFr: 'Gagne +{tier} Mana à l\'utilisation',
    icon: 'diamond_rounded',
    color: 'cyanAccent',
    pools: ['rare'],
    maxLevel: 1,
    deltas: [AddEffectDelta(effect: 'gain_mana', valuePerLevel: 1)],
  );

  const enduringUpgrade = ForgeUpgradeData(
```

Then replace:

```dart
    forgeUpgrades: const [sharpUpgrade, enduringUpgrade],
```

with:

```dart
    forgeUpgrades: const [sharpUpgrade, ecoUpgrade, enduringUpgrade],
```

Then replace:

```dart
  testWidgets(
    'lists a card with two identical upgrades as fusable',
```

with:

```dart
  testWidgets(
    'a card whose fusion would lose a level is not listed (spec P-43 E1, A10)',
    (WidgetTester tester) async {
      // Deux eco:1, d'une sauvegarde d'avant 0.5.3 : les reunir donnerait
      // eco:1 contre 80 or.
      final cappedCard = CardInstance(
        data: strikeCard,
        forgeUpgrades: const ['eco:1', 'eco:1'],
      );

      await pumpForgeFusionScreen(tester, masterDeck: [cappedCard]);

      expect(
        find.text('No cards in your deck have identical runes to merge.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'lists a card with two identical upgrades as fusable',
```

In `test/unit/shop_controller_test.dart`, replace:

```dart
    test('la boutique ne tire une rune non cumulable qu au tier 1', () {
```

with:

```dart
    test('une rune plafonnee n est jamais tiree au-dessus de son plafond', () {
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
      // Cumulable, comme eco aujourd'hui : le tirage la monterait a 2 ou 3.
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
            pools: ['common', 'uncommon', 'rare'],
            maxLevel: 1,
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final rolled = <String>{};
      for (var i = 0; i < 200; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          rolled.addAll(card.forgeUpgrades);
        }
      }

      expect(rolled, {'capped:1'});
    });

    test('une pre-forgee ne porte que des runes eligibles a ses runes deja '
        'tirees, jamais au-dela d un plafond (spec P-43 E1, A12)', () {
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
      final catalog = shippedRuneRegistry(shippedRuneIds()).forgeUpgrades;
      final cards = shippedNeutralCards();
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          for (var n = 0; n < card.forgeUpgrades.length; n++) {
            final (id, _) = ForgeUpgradeData.parseRef(card.forgeUpgrades[n])!;
            final before = card.copyWith(
                forgeUpgrades: card.forgeUpgrades.sublist(0, n));
            expect(
              ForgeRuneRules.isEligible(
                  catalog.singleWhere((r) => r.id == id), before, catalog),
              isTrue,
              reason: '${card.data.id} : ${card.forgeUpgrades}',
            );
          }
          ForgeUpgradeData.levelsOf(card.forgeUpgrades).forEach((id, level) {
            final cap = catalog.singleWhere((r) => r.id == id).maxLevel;
            expect(level, lessThanOrEqualTo(cap ?? level),
                reason: '${card.data.id} : ${card.forgeUpgrades}');
          });
        }
      }
    });

    test('une Concentration pre-forgee porte au plus une rune, Veloce', () {
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
      final concentration = shippedCard('concentration');
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final carried = <String>{};
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop([concentration], 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.forgeUpgrades.isNotEmpty) {
            carried.add(card.forgeUpgrades.join(','));
          }
        }
      }

      expect(carried, {'quick:1'});
    });

    test('la boutique ne tire une rune non cumulable qu au tier 1', () {
```

In `test/widget/forge_upgrade_dialog_test.dart`, replace:

```dart
  testWidgets('une fente Tranchant 1 dit son gain sur une Frappe epique qui '
```

with:

```dart
  testWidgets('Econome n est jamais tiree au-dessus du niveau 1',
      (tester) async {
    // Seule rune du catalogue : chaque fente la tire, a un niveau de 1 a 3
    // avant la borne (spec P-43 E1, §4.7).
    shippedRuneRegistry(const ['eco']);

    final offered = await _offeredSlots(
        tester, CardInstance(data: shippedCard('strike_basic')),
        rerolls: 30);

    expect(offered, {'eco:1'});
  });

  testWidgets('une fente Tranchant 1 dit son gain sur une Frappe epique qui '
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/decoupled_forge_test.dart test/widget/forge_fusion_screen_test.dart test/unit/shop_controller_test.dart test/widget/forge_upgrade_dialog_test.dart`
Expected: FAIL, neuf cas — `consolidate` rend `capped:3` et `eco:3`, `fusionOptionsFor` propose de réunir deux `eco:1` et `capped:2` + `capped:1` (la Forge de Fusion liste la carte), la boutique et le feu tirent `capped:2`, `eco:2` ou `eco:3`, une *Concentration* reçoit `quick` deux fois. Deux cas passent déjà et fixent ce qui ne doit pas bouger : « 1 + 1 sous un plafond de 2 : proposée » et « trois `sharp:1` en `sharp:3` ». Les cas tirés au hasard échouent avec une probabilité qui dépasse 99 % ; aucun ne peut réussir à tort une fois la tâche faite.

- [ ] **Step 3: La fusion de cartes et la Forge de Fusion**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée.
  static List<String> consolidate(Iterable<String> runes) => [
        for (final MapEntry(key: id, value: tier)
            in ForgeUpgradeData.levelsOf(runes).entries)
          '$id:${isStackable(id) ? tier : 1}',
      ];
```

with:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, bornés par son `maxLevel`
  /// — le surplus se perd (spec P-43 E1, A9) ; une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée.
  static List<String> consolidate(Iterable<String> runes) => [
        for (final MapEntry(key: id, value: tier)
            in ForgeUpgradeData.levelsOf(runes).entries)
          '$id:${isStackable(id) ? _bounded(id, tier) : 1}',
      ];

  /// [tier] borné par le plafond de la rune [id] (D72) ; une rune absente du
  /// registre n'en a pas.
  static int _bounded(String id, int tier) =>
      ForgeUpgradeData.getById(id)?.boundLevel(tier) ?? tier;
```

Then replace:

```dart
  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or.
```

with:

```dart
  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune
  /// cumulable que la carte porte au moins deux fois, au coût de
  /// `80 × (N - 1)` or — et seulement si la somme tient sous le plafond de la
  /// rune : une fusion qui perdrait un niveau n'est pas proposée (spec P-43
  /// E1, A10).
```

Then replace:

```dart
      if (runes.length < 2 || !isStackable(id)) return;
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: runes.fold(
          0,
          (sum, rune) => sum + (ForgeUpgradeData.parseRef(rune)?.$2 ?? 0),
        ),
        cost: 80 * (runes.length - 1),
      ));
```

with:

```dart
      if (runes.length < 2 || !isStackable(id)) return;
      final totalTier = runes.fold(
        0,
        (sum, rune) => sum + (ForgeUpgradeData.parseRef(rune)?.$2 ?? 0),
      );
      if (_bounded(id, totalTier) != totalTier) return;
      options.add(FusionOption(
        upgradeId: id,
        originalUpgrades: runes,
        totalTier: totalTier,
        cost: 80 * (runes.length - 1),
      ));
```

- [ ] **Step 4: Le tirage du feu**

In `lib/ui/widgets/forge_upgrade_dialog.dart`, replace:

```dart
    return '$rolledId:$tier';
```

with:

```dart
    // Le niveau que la fente affiche est celui que la carte recevra : borné
    // par le plafond de la rune, ce que la carte en porte déjà compris (D72,
    // spec P-43 E1, §4.7).
    final carried =
        ForgeUpgradeData.levelsOf(card.forgeUpgrades)[rolledId] ?? 0;
    final level = ForgeUpgradeData.getById(rolledId)
            ?.boundLevel(tier, carried: carried) ??
        tier;
    return '$rolledId:$level';
```

- [ ] **Step 5: Le tirage des pré-forgées**

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
  /// Helper privé pour générer un upgrade de forge aléatoire avec son tier
  String _rollRandomUpgrade(CardInstance card, List<String> existingUpgrades, Random rng) {
    final excludedIds = existingUpgrades.map((u) => u.split(':')[0]).toList();
    String? rolledId = _rollUpgradeId(card, rng, excludedIds);
    rolledId ??= _rollUpgradeId(card, rng, []);
    rolledId ??= 'sharp';
```

with:

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

Then replace:

```dart
    return '$rolledId:$tier';
```

with:

```dart
    // Borné par le plafond de la rune, ce que la carte en porte déjà compris
    // (D72, spec P-43 E1, §4.7).
    final carried =
        ForgeUpgradeData.levelsOf(card.forgeUpgrades)[rolledId] ?? 0;
    final level = ForgeUpgradeData.getById(rolledId)
            ?.boundLevel(tier, carried: carried) ??
        tier;
    return '$rolledId:$level';
```

Then replace:

```dart
    if (upgradesToRoll > 0) {
      final List<String> upgrades = [];
      for (int i = 0; i < upgradesToRoll; i++) {
        final newUpgrade = _rollRandomUpgrade(instance, upgrades, rng);
        upgrades.add(newUpgrade);
      }
      instance = instance.copyWith(forgeUpgrades: upgrades);
    }
```

with:

```dart
    for (int i = 0; i < upgradesToRoll; i++) {
      final newUpgrade = _rollRandomUpgrade(instance, rng);
      // Une carte à qui ne reste aucune rune éligible en reçoit moins (A12).
      if (newUpgrade == null) break;
      instance = instance.copyWith(
        forgeUpgrades: [...instance.forgeUpgrades, newUpgrade],
      );
    }
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_rune_rules_test.dart` — Expected: `+14: All tests passed!`
Run: `flutter test test/unit/decoupled_forge_test.dart` — Expected: `+10: All tests passed!`
Run: `flutter test test/widget/forge_fusion_screen_test.dart test/unit/shop_controller_test.dart test/widget/forge_upgrade_dialog_test.dart test/unit/deck_controller_test.dart` — Expected: `All tests passed!`

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1362: All tests passed!` (1351 + 4 + 2 + 1 + 3 + 1).

- [ ] **Step 8: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/game/services/forge_rune_rules.dart lib/ui/widgets/forge_upgrade_dialog.dart lib/game/controllers/shop_controller.dart test/unit/forge_rune_rules_test.dart test/unit/decoupled_forge_test.dart test/widget/forge_fusion_screen_test.dart test/unit/shop_controller_test.dart test/widget/forge_upgrade_dialog_test.dart
git commit -F- <<'EOF'
feat(runes): maxLevel borne les quatre endroits qui ecrivent un niveau

La fusion de cartes borne la somme, la Forge de Fusion ne propose plus
une fusion qui perdrait un niveau, et les tirages du feu et des
pre-forgees comptent ce que la carte porte deja. La boutique lit la
carte avec ses runes deja tirees : une pre-forgee sans rune eligible en
recoit moins, et le repli sur Tranchant disparait.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 7: Le feu refuse une carte sans rune éligible — et plus aucun id de rune dans `lib/`

A11 : la sélection du feu refuse, avec un message, une carte à qui aucune rune du catalogue ne peut plus s'offrir — comme elle refuse une carte pleine — au lieu d'ouvrir une forge vide ou de retomber sur `'sharp'` ; le prédicat de Task 5 est son troisième lecteur. Le repli du dialogue sur `'sharp'` disparaît : `_rollSlotUpgrade` rend `null` quand rien n'est éligible, ce que la sélection écarte en amont. Avec lui part le dernier id de rune écrit en dur dans `lib/` : un test le garde désormais, et garde la fin de `rarityMultiplier` (§8).

Changement visible de la tâche, voulu (§4.8, §5.3) : une carte qui ne peut plus recevoir aucune rune — *Concentration* peu commune portant `quick:1`, *Forme Démoniaque* rare portant `eco:1` et `quick:1` — est refusée à la forge du feu de camp, avec le message « Aucune rune ne peut être ajoutée à cette carte. ». Le déroulé ne change pas : c'est le refus d'aujourd'hui, avec un motif de plus ; le message de la carte pleine (`rest_card_selection_screen.dart:31-36`) n'est pas touché.

**Files:**
- Modify: `lib/l10n/app_en.arb:470`, `lib/l10n/app_fr.arb:196` ; régénérés par `flutter gen-l10n` : `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/ui/screens/rest_card_selection_screen.dart:4-5`, `:37-40`
- Modify: `lib/ui/widgets/forge_upgrade_dialog.dart:169-173`, `:189-233`, `:247-249`, `:265-266`
- Test: `test/widget/rest_card_selection_screen_test.dart`, `test/unit/rune_ids_in_code_test.dart` *(nouveaux)*

**Interfaces:**
- Consumes: `ForgeRuneRules.isEligible` (Task 5) ; `AppLocalizations.forgeNoEligibleRune` (généré à l'étape 3).
- Produces: `String? _ForgeUpgradeDialogState._rollSlotUpgrade(CardInstance card, List<String> excludedIds)` — `null` si aucune rune n'est éligible.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/widget/rest_card_selection_screen_test.dart`:

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
import 'package:roguelike_card_game/ui/widgets/forge_upgrade_dialog.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Monte la sélection de la forge du feu sur un deck d'une seule [card], avec
/// les huit runes livrées.
Future<ProviderContainer> _pumpForgeSelection(
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
          title: 'FORGER UNE CARTE',
          subtitle: 'Choisissez une carte à améliorer définitivement.',
          isForge: true,
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

/// Le refus de la sélection du feu (spec P-43 E1, A11, §5.3).
void main() {
  testWidgets('une Concentration peu commune portant Veloce est refusee, avec '
      'le motif', (tester) async {
    // Sa fente libre ne peut rien recevoir : Veloce est sa seule rune
    // eligible, et son plafond est atteint.
    final card = CardInstance(
      data: shippedCard('concentration'),
      rarity: CardRarity.uncommon,
      forgeUpgrades: const ['quick:1'],
    );
    final container = await _pumpForgeSelection(tester, card);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        'Aucune rune ne peut être ajoutée à cette carte.');

    await _settleNotifications(tester);
  });

  testWidgets('une carte pleine garde son message', (tester) async {
    final card = CardInstance(
      data: shippedCard('strike_basic'),
      forgeUpgrades: const ['sharp:1'],
    );
    final container = await _pumpForgeSelection(tester, card);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();

    expect(find.byType(ForgeUpgradeDialog), findsNothing);
    expect(container.read(notificationProvider).last.message,
        "Cette carte a atteint sa capacité maximale d'améliorations de forge !");

    await _settleNotifications(tester);
  });
}
```

Create `test/unit/rune_ids_in_code_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Les runes sont des fichiers : aucun id de rune livrée n'est écrit en dur
/// dans `lib/`, et le multiplicateur de rareté n'a plus qu'un endroit,
/// l'applicateur (spec P-43 E1, A1, A4, §8). Sur le modèle de
/// `stat_gain_single_passage_test.dart`.
void main() {
  final runeIds = [
    for (final file in Directory('assets/data/forge_upgrades').listSync())
      if (file is File && file.path.endsWith('.json'))
        file.uri.pathSegments.last.replaceAll('.json', ''),
  ];

  /// Les endroits de `lib/` où [pattern] apparaît, `chemin:ligne : extrait`.
  List<String> offendersOf(RegExp pattern) {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final source = entity.readAsStringSync();
      for (final match in pattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('$path:$line : ${match.group(0)}');
      }
    }
    return offenders;
  }

  test('aucun id de rune livree n est ecrit en litteral dans lib', () {
    expect(runeIds, hasLength(8), reason: 'les huit runes livrees');
    final offenders =
        offendersOf(RegExp('''['"](${runeIds.join('|')})['"]'''));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le multiplicateur de rarete n est plus calcule hors de l applicateur',
      () {
    final offenders = offendersOf(RegExp(r'\brarityMultiplier\b'));
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/widget/rest_card_selection_screen_test.dart test/unit/rune_ids_in_code_test.dart`
Expected: FAIL, deux cas — la *Concentration* ouvre le dialogue de la forge, qui lui tire `'sharp'` par repli ; `forge_upgrade_dialog.dart` écrit encore `'sharp'`. Le cas de la carte pleine et celui de `rarityMultiplier` passent déjà (Task 3).

- [ ] **Step 3: Le message**

In `lib/l10n/app_en.arb`, replace:

```json
  "restCampForgeSubtitle": "Choose a card to permanently upgrade.",
```

with:

```json
  "restCampForgeSubtitle": "Choose a card to permanently upgrade.",
  "forgeNoEligibleRune": "No rune can be added to this card.",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "restCampForgeSubtitle": "Choisissez une carte à améliorer définitivement.",
```

with:

```json
  "restCampForgeSubtitle": "Choisissez une carte à améliorer définitivement.",
  "forgeNoEligibleRune": "Aucune rune ne peut être ajoutée à cette carte.",
```

Run: `flutter gen-l10n`
Expected: aucune erreur ; `git status --short lib/l10n` montre les deux ARB et les trois `app_localizations*.dart` modifiés.

- [ ] **Step 4: La sélection du feu refuse**

In `lib/ui/screens/rest_card_selection_screen.dart`, replace:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../models/card_instance.dart';
```

with:

```dart
import '../../game/controllers/deck_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/game_data_registry.dart';
```

Then replace:

```dart
        return;
      }

      final selectedUpgrade = await showDialog<String>(
```

with:

```dart
        return;
      }

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
```

- [ ] **Step 5: Le dialogue perd son repli sur `'sharp'`**

In `lib/ui/widgets/forge_upgrade_dialog.dart`, replace:

```dart
  String _rollSlotUpgrade(CardInstance card, List<String> excludedIds) {
    final rand = Random();
    String? rolledId = _rollUpgradeId(card, rand, excludedIds);
    rolledId ??= _rollUpgradeId(card, rand, []);
    rolledId ??= 'sharp';
```

with:

```dart
  /// Tire une fente pour [card]. `null` seulement si aucune rune du catalogue
  /// ne s'offre à la carte — la sélection du feu refuse une telle carte avant
  /// d'ouvrir le dialogue (spec P-43 E1, A11).
  String? _rollSlotUpgrade(CardInstance card, List<String> excludedIds) {
    final rand = Random();
    final rolledId = _rollUpgradeId(card, rand, excludedIds) ??
        _rollUpgradeId(card, rand, []);
    if (rolledId == null) return null;
```

Then replace:

```dart
  List<ForgeSlot> _generateInitialSlots(CardInstance card) {
    final List<ForgeSlot> slots = [];
    final List<String> excludedIds = [];
    final rand = Random();

    final upg1 = _rollSlotUpgrade(card, excludedIds);
    slots.add(ForgeSlot(index: 0, upgrade: upg1));
    excludedIds.add(upg1.split(':')[0]);

    if (rand.nextDouble() < 0.50) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 1, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.25) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 2, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.10) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 3, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    if (rand.nextDouble() < 0.02) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      slots.add(ForgeSlot(index: 4, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    // Add existing bonus slots
    final runState = ref.read(runProvider);
    final bonusCount = runState.bonusForgeSlots;
    for (int i = 0; i < bonusCount; i++) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      final newIndex = slots.isEmpty ? 0 : slots.map((s) => s.index).reduce(max) + 1;
      slots.add(ForgeSlot(index: newIndex, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    return slots;
  }
```

with:

```dart
  List<ForgeSlot> _generateInitialSlots(CardInstance card) {
    final List<ForgeSlot> slots = [];
    final List<String> excludedIds = [];
    final rand = Random();

    // Une fente de plus, à l'indice [index] — aucune si rien ne s'offre à la
    // carte (A11).
    void addSlot(int index) {
      final upg = _rollSlotUpgrade(card, excludedIds);
      if (upg == null) return;
      slots.add(ForgeSlot(index: index, upgrade: upg));
      excludedIds.add(upg.split(':')[0]);
    }

    addSlot(0);
    if (rand.nextDouble() < 0.50) addSlot(1);
    if (rand.nextDouble() < 0.25) addSlot(2);
    if (rand.nextDouble() < 0.10) addSlot(3);
    if (rand.nextDouble() < 0.02) addSlot(4);

    // Add existing bonus slots
    final runState = ref.read(runProvider);
    final bonusCount = runState.bonusForgeSlots;
    for (int i = 0; i < bonusCount; i++) {
      addSlot(slots.isEmpty ? 0 : slots.map((s) => s.index).reduce(max) + 1);
    }

    return slots;
  }
```

Then replace:

```dart
        final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
        _slots[slotIdx].upgrade = newUpgrade;
        _slots[slotIdx].rerollsCount += 1;
```

with:

```dart
        final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
        if (newUpgrade == null) return;
        _slots[slotIdx].upgrade = newUpgrade;
        _slots[slotIdx].rerollsCount += 1;
```

Then replace:

```dart
      final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
      final newIndex = _slots.isEmpty ? 0 : _slots.map((s) => s.index).reduce(max) + 1;
```

with:

```dart
      final newUpgrade = _rollSlotUpgrade(widget.card, excludedIds);
      if (newUpgrade == null) return;
      final newIndex = _slots.isEmpty ? 0 : _slots.map((s) => s.index).reduce(max) + 1;
```

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/widget/rest_card_selection_screen_test.dart` — Expected: `+2: All tests passed!`
Run: `flutter test test/unit/rune_ids_in_code_test.dart` — Expected: `+2: All tests passed!`
Run: `flutter test test/widget/forge_upgrade_dialog_test.dart test/widget/rest_screen_test.dart` — Expected: `All tests passed!`

- [ ] **Step 7: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1366: All tests passed!` (1362 + 2 + 2).

- [ ] **Step 8: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`. Les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit.

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/ui/screens/rest_card_selection_screen.dart lib/ui/widgets/forge_upgrade_dialog.dart test/widget/rest_card_selection_screen_test.dart test/unit/rune_ids_in_code_test.dart
git commit -F- <<'EOF'
feat(forge): le feu refuse une carte qui ne peut plus recevoir de rune

La selection de la forge du feu refuse, avec un message, une carte a
qui aucune rune ne peut plus s offrir, comme elle refuse une carte
pleine. Le dialogue perd son repli sur Tranchant ; plus aucun id de
rune n est ecrit dans lib, ce qu un test garde desormais.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 8: L'éditeur de contenu — le descripteur de rune et le vocabulaire des listes

§6 et A13 : le descripteur de rune lit `deltas[].type` sur `CardDelta.typeNames` (ADR-100 D1), fait d'`excludesRunes` une liste de références de rune (le mécanisme de P-49 : une case par rune, une liste vide refusée) et ferme le vocabulaire des types d'effet qu'une rune nomme — `eligibleEffects[]`, `excludesEffects[]`, `deltas[].effect`, `deltas[].statusId`, des motifs d'**éléments**. `vocabularyOf` lit, pour un motif `clé[]`, les valeurs que `knownValues` range sous la clé nue ; `knownValues` et le panneau de référence qui le lit ne changent pas. Le gabarit a pris `deltas` (Task 1), `maxLevel` (Task 4) et les champs d'éligibilité (Task 5) avec les tâches qui les rendaient obligatoires ou les lisaient : il est complet.

Aucun changement de jeu.

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart:5`, `:334-339`
- Modify: `lib/services/content_editor/known_values.dart:77-86`
- Modify: `test/unit/content_editor/fixtures.dart:1-8`, `:46-60` (`fixtureRune`, et `forgeUpgrades` dans `fixtureRegistry`)
- Test: `test/unit/content_editor/entity_descriptor_test.dart:4`, `:218-220`, `:375-384` ; `test/unit/content_editor/entity_validator_test.dart:600-605` (un groupe) ; `test/unit/content_editor/known_values_test.dart:122-128` (un cas)

**Interfaces:**
- Consumes: `CardDelta.typeNames` (Task 1) ; `ForgeUpgradeData.fromJson` et ses refus (Tasks 1, 4, 5).
- Produces: le descripteur de rune complet ; `vocabularyOf` qui lit la clé nue pour un motif `clé[]`. Aide de test : `ForgeUpgradeData fixtureRune(String id)`, `fixtureRegistry({..., List<ForgeUpgradeData> forgeUpgrades = const []})`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/content_editor/fixtures.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';

```

with:

```dart
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/services/content_editor/entity_descriptor.dart';
import 'package:roguelike_card_game/services/content_editor/entity_draft.dart';

```

Then replace:

```dart
GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<HeroData> heroes = const [],
  List<PassiveData> passives = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: heroes,
      cards: cards,
      events: const [],
      passives: passives,
      relics: const [],
      forgeUpgrades: const [],
      audio: const AudioData.disabled(),
    );
```

with:

```dart
ForgeUpgradeData fixtureRune(String id) => ForgeUpgradeData.fromJson({
      'id': id,
      'name_en': 'x',
      'name_fr': 'x',
      'description_en': 'x',
      'description_fr': 'x',
      'pools': ['common'],
      'maxLevel': null,
      'deltas': [
        {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
      ],
    });

GameDataRegistry fixtureRegistry({
  List<CardData> cards = const [],
  List<HeroData> heroes = const [],
  List<PassiveData> passives = const [],
  List<ForgeUpgradeData> forgeUpgrades = const [],
}) =>
    GameDataRegistry(
      enemies: const [],
      heroes: heroes,
      cards: cards,
      events: const [],
      passives: passives,
      relics: const [],
      forgeUpgrades: forgeUpgrades,
      audio: const AudioData.disabled(),
    );
```

In `test/unit/content_editor/entity_descriptor_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
```

Then replace:

```dart
  // - `classes` d'un passif, qui est une `referenceListKeys` : absente, elle
  //   ouvre le passif a toutes les classes (spec P-49, §3.2). L'assertion
  //   qui suit la table le verifie ;
```

with:

```dart
  // - `classes` d'un passif, qui est une `referenceListKeys` : absente, elle
  //   ouvre le passif a toutes les classes (spec P-49, §3.2). L'assertion
  //   qui suit la table le verifie ;
  // - `excludesRunes` d'une rune, `referenceListKeys` elle aussi : absente,
  //   elle vaut « aucune » (spec P-43 E1, §6) ;
```

Then replace:

```dart
  // `forge_slot_row.dart` lit `color` et `icon` par leur nom (`amberAccent`,
  // `flash_on_rounded`) et retombe en silence sur du gris et
  // `Icons.help_outline` : ce sont des vocabulaires du moteur, pas un hex.
  test('la couleur et l icone d une amelioration de forge sont des noms du '
      'moteur', () {
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
    expect(forge.vocabularyKeys, {'color', 'icon'});
    expect(forge.hexColorKeys, isEmpty);
  });
}
```

with:

```dart
  // `forge_slot_row.dart` lit `color` et `icon` par leur nom (`amberAccent`,
  // `flash_on_rounded`) et retombe en silence sur du gris et
  // `Icons.help_outline` : ce sont des vocabulaires du moteur, pas un hex.
  // Les types d'effet qu'une rune nomme ne sont connus que du registre de
  // strategies : des motifs d'elements (spec P-43 E1, A13).
  test('la couleur, l icone et les types d effet d une amelioration de forge '
      'sont des noms du moteur', () {
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
    expect(forge.vocabularyKeys, {
      'color',
      'icon',
      'eligibleEffects[]',
      'excludesEffects[]',
      'deltas[].effect',
      'deltas[].statusId',
    });
    expect(forge.hexColorKeys, isEmpty);
  });

  test('le type d un delta est lu sur le parseur (ADR-100 D1)', () {
    expect(
      kEntityDescriptors[EntityCategory.forgeUpgrade]!.enumKeys['deltas[].type'],
      CardDelta.typeNames,
    );
  });

  test('excludesRunes designe des runes, et manque au gabarit', () {
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
    expect(forge.referenceListKeys,
        {'excludesRunes': EntityCategory.forgeUpgrade});
    expect(forge.decodeTemplate().containsKey('excludesRunes'), isFalse);
  });
}
```

In `test/unit/content_editor/entity_validator_test.dart`, replace:

```dart
      // Le nom du gabarit passe dans une arborescence vide.
      expect(validatorWith().validate(withColor('amberAccent')), isEmpty);
    });
  });

  group('famille ressources', () {
```

with:

```dart
      // Le nom du gabarit passe dans une arborescence vide.
      expect(validatorWith().validate(withColor('amberAccent')), isEmpty);
    });
  });

  group('une rune de forge (spec P-43 E1, §6)', () {
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;

    EntityDraft runeDraft(Map<String, dynamic> changes) => EntityDraft(
          descriptor: forge,
          id: 'eclat',
          bilingual: const {
            'name_fr': 'x',
            'name_en': 'x',
            'description_fr': 'x',
            'description_en': 'x',
          },
          mechanics: jsonEncode({...forge.decodeTemplate(), ...changes}),
        );

    EntityValidator withRunes() => validatorWith(
          registry: fixtureRegistry(forgeUpgrades: [fixtureRune('sharp')]),
        );

    test('excludesRunes vide est refuse par la famille 6', () {
      final faults = withRunes().validate(runeDraft({'excludesRunes': []}));
      expect(faults.single.field, 'excludesRunes');
    });

    test('excludesRunes inconnu est refuse par la famille 6, connu passe', () {
      final faults = withRunes().validate(runeDraft({
        'excludesRunes': ['sharpp'],
      }));
      expect(faults.single.field, 'excludesRunes');
      expect(faults.single.message, contains('sharpp'));

      expect(
        withRunes().validate(runeDraft({
          'excludesRunes': ['sharp'],
        })),
        isEmpty,
      );
    });

    test('maxLevel 0 est refuse par la famille 7', () {
      final faults = withRunes().validate(runeDraft({'maxLevel': 0}));
      expect(faults.single.message, contains('maxLevel'));
    });

    test('un type d effet inconnu d eligibleEffects est refuse, damage passe',
        () {
      final faults = withRunes().validate(runeDraft({
        'eligibleEffects': ['damge'],
      }));
      expect(faults.single.field, 'eligibleEffects[0]');

      expect(
        withRunes().validate(runeDraft({
          'eligibleEffects': ['damage'],
        })),
        isEmpty,
      );
    });
  });

  group('famille ressources', () {
```

In `test/unit/content_editor/known_values_test.dart`, replace:

```dart
  test('vocabularyOf ajoute les valeurs du gabarit a celles du disque', () {
    final relic = kEntityDescriptors[EntityCategory.relic]!;
    expect(vocabularyOf(relic, const {'effectType': ['heal']})['effectType'],
        ['gain_armor', 'heal']);
    expect(vocabularyOf(relic, const {})['effectType'], ['gain_armor']);
  });
}
```

with:

```dart
  test('vocabularyOf ajoute les valeurs du gabarit a celles du disque', () {
    final relic = kEntityDescriptors[EntityCategory.relic]!;
    expect(vocabularyOf(relic, const {'effectType': ['heal']})['effectType'],
        ['gain_armor', 'heal']);
    expect(vocabularyOf(relic, const {})['effectType'], ['gain_armor']);
  });

  test('vocabularyOf lit sous la cle nue les elements d une liste de chaines',
      () {
    // `knownValues` range les elements de `excludesEffects` sous la cle nue ;
    // le motif d'elements `excludesEffects[]` les y lit (spec P-43 E1, A13).
    write('assets/data/forge_upgrades/enduring.json',
        '{"excludesEffects": ["gain_mana", "draw"]}');
    final forge = kEntityDescriptors[EntityCategory.forgeUpgrade]!;
    final known = knownValues(fs, root, forge);

    expect(known['excludesEffects'], ['draw', 'gain_mana']);
    expect(vocabularyOf(forge, known)['excludesEffects[]'],
        ['draw', 'gain_mana']);
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/content_editor/`
Expected: FAIL, sept cas — le descripteur n'a ni `deltas[].type`, ni `excludesRunes`, ni les quatre motifs d'éléments (`excludesRunes: []` et `["sharpp"]` ne sont alors refusés que par la famille 7, sans nommer le champ, ou pas du tout ; `"damge"` passe le vocabulaire) ; `vocabularyOf` ne lit pas `excludesEffects[]`. Le cas `maxLevel: 0` passe déjà : la famille 7 appelle `fromJson`, qui le refuse depuis Task 4.

- [ ] **Step 3: Le descripteur de rune**

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
import '../../models/data/card_data.dart';
```

with:

```dart
import '../../models/data/card_data.dart';
import '../../models/data/card_delta.dart';
```

Then replace:

```dart
    enumListKeys: {'eligibleCardTypes': _names(CardType.values)},
    // `color` et `icon` ne sont pas un hex ni un texte libre : ce sont des
    // noms que `forge_slot_row.dart` traduit un a un (`amberAccent`,
    // `flash_on_rounded`), et un nom inconnu y retombe en silence sur du gris
    // et `Icons.help_outline`. Les huit ameliorations livrees les emploient.
    vocabularyKeys: const {'color', 'icon'},
```

with:

```dart
    enumListKeys: {'eligibleCardTypes': _names(CardType.values)},
    // Le type d'un delta, lu sur le parseur (ADR-100 D1).
    enumKeys: {'deltas[].type': CardDelta.typeNames},
    // `excludesRunes` nomme des runes : une liste non vide d'ids existants,
    // une case par rune (spec P-43 E1, §6). Absente : aucune.
    referenceListKeys: const {'excludesRunes': EntityCategory.forgeUpgrade},
    // `color` et `icon` ne sont pas un hex ni un texte libre : ce sont des
    // noms que `forge_slot_row.dart` traduit un a un (`amberAccent`,
    // `flash_on_rounded`), et un nom inconnu y retombe en silence sur du gris
    // et `Icons.help_outline`. Les huit ameliorations livrees les emploient.
    //
    // Les types d'effet qu'une rune nomme, et le statut qu'elle pose, ne sont
    // connus que du registre de strategies et de `createStatus` : des motifs
    // d'**elements**, admis s'ils sont deja employes par un fichier de rune ou
    // par le gabarit (spec P-43 E1, A13 ; `vocabularyOf`).
    vocabularyKeys: const {
      'color',
      'icon',
      'eligibleEffects[]',
      'excludesEffects[]',
      'deltas[].effect',
      'deltas[].statusId',
    },
```

- [ ] **Step 4: Le vocabulaire des éléments d'une liste de chaînes**

In `lib/services/content_editor/known_values.dart`, replace:

```dart
/// seule carte (spec §4.5).
Map<String, List<String>> vocabularyOf(
  EntityDescriptor descriptor,
  Map<String, List<String>> known,
) {
  final template = descriptor.decodeTemplate();
  return {
    for (final pattern in descriptor.vocabularyKeys)
      pattern: ({
        ...?known[pattern],
```

with:

```dart
/// seule carte (spec §4.5).
///
/// [knownValues] range les éléments d'une liste de chaînes sous la clé nue
/// (`excludesEffects`) : un motif d'éléments (`excludesEffects[]`) les lit
/// là (spec P-43 E1, A13).
Map<String, List<String>> vocabularyOf(
  EntityDescriptor descriptor,
  Map<String, List<String>> known,
) {
  final template = descriptor.decodeTemplate();
  return {
    for (final pattern in descriptor.vocabularyKeys)
      pattern: ({
        ...?known[pattern],
        if (pattern.endsWith('[]'))
          ...?known[pattern.substring(0, pattern.length - 2)],
```

- [ ] **Step 5: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/content_editor/` — Expected: `All tests passed!`, dont `shipped_entities_round_trip_test.dart` : les huit fichiers de rune, `enduring.json` et ses `excludesEffects` compris, se valident et se réécrivent à l'identique.
Run: `flutter test test/widget/content_editor/ test/widget/content_editor_screen_test.dart` — Expected: `All tests passed!`

- [ ] **Step 6: Vérification complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1373: All tests passed!` (1366 + 2 + 4 + 1).

- [ ] **Step 7: Commit**

Run: `git status --short` — si un fichier généré de plateforme apparaît : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`.

```bash
git add lib/services/content_editor/entity_descriptor.dart lib/services/content_editor/known_values.dart test/unit/content_editor/fixtures.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/known_values_test.dart
git commit -F- <<'EOF'
feat(editeur): le descripteur de rune connait ses deltas et ses exclusions

Le type d un delta est lu sur CardDelta.typeNames, excludesRunes est une
liste de references de rune, et les types d effet qu une rune nomme
forment un vocabulaire ferme, lu sur les fichiers et le gabarit.
vocabularyOf lit sous la cle nue les elements d une liste de chaines.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 9: Vérification finale

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf, et cette tâche se rejoue en entier. `<base>` désigne le commit du plan : `git log -1 --format=%H -- docs/superpowers/plans/2026-10-02-p43-e1-moteur-de-runes.md`.

**Files:** aucun.

**Interfaces:**
- Consumes: tout le lot.
- Produces: la branche `feat/v0.5.3-p43-e0-e1`, E0 et E1 implémentés — rien de poussé, aucune PR. La relance de la simulation est celle de l'orchestrateur, à la fin de la vague (fichier d'orchestration, §3.6) ; aucune tâche ne la lance.

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1373: All tests passed!` — 1228 + 145, dont `stat_gain_single_passage_test.dart` (ADR-095), `tutorial_isolation_test.dart` (ADR-081), `real_bundle_load_test.dart` (huit runes, `enduring` seule non cumulable) et `shipped_entities_round_trip_test.dart`, inchangés et verts.

- [ ] **Step 2: Ce qui a disparu (spec §2, §3.3, A2, A4)**

Run: `git grep -n "rarityMultiplier\|forgeSlotBonus\|valueMultiplier\|GainSource\.rune" -- lib test assets tool`
Expected: une seule ligne, le motif du garde-fou lui-même — `test/unit/rune_ids_in_code_test.dart:41:    final offenders = offendersOf(RegExp(r'\brarityMultiplier\b'));`.

Run: `git grep -nE "['\"](sharp|hardened|quick|eco|burning|freezing|shocking|enduring)['\"]" -- lib`
Expected: aucune sortie — aucun id de rune livrée n'est écrit dans `lib/` (A1, A4, A11, A12).

Run: `git grep -n "buildDescription()" -- lib`
Expected: aucune sortie (Task 3).

- [ ] **Step 3: La donnée que lit la simulation (spec §3.2, §9)**

Run: `git diff <base>..HEAD -- assets/data/forge_upgrades | grep -E '^[-+] +"(weight|eligibleCardTypes)"'`
Expected: exactement deux lignes, celles de `sharp` et de `hardened` :
```
-  "eligibleCardTypes": [
-  "eligibleCardTypes": [
```
Aucun `weight` ne bouge, ni l'`eligibleCardTypes` des six autres runes.

Run: `git diff --stat <base>..HEAD -- tool site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni la simulation et sa référence, ni `site/`, ni la note de version, ni la version, ni un fichier généré de plateforme.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0 — aucun fichier ni dossier neuf sous `assets/`.

- [ ] **Step 4: `pools`, `stackable` et la capacité gardent leurs lecteurs, et eux seuls (D68, §4.9)**

Run: `git grep -n "\.pools\b\|isStackable(\|\.stackable\b\|forgeCapacity" -- lib`
Expected: les lecteurs d'avant le lot, et aucun neuf —
- `pools` : les deux tirages, `forge_upgrade_dialog.dart` (dans `_getEligibleUpgradesForPool`) et `shop_controller.dart` (idem) ;
- `stackable` : `ForgeRuneRules.isStackable` (`forge_rune_rules.dart`), lu par `consolidate`, `fusionOptionsFor` et les deux tirages (`forge_upgrade_dialog.dart`, `shop_controller.dart`) ; l'affichage du niveau, `forge/forge_slot_row.dart` et `deck_screen.dart` (deux lignes) ;
- la capacité : `card_instance.dart` (`forgeCapacity`), `card_data.dart` (`forgeCapacityAt`, et la doc de `fusionRank` qui le nomme), `deck_controller.dart`, `deck_screen.dart`, `shop_controller.dart`, `rest_card_selection_screen.dart`, `forge_upgrade_dialog.dart`, `card_text_renderer.dart`, `ui_card.dart` (cinq lignes) ;
- les déclarations de `ForgeUpgradeData` (`required this.pools`, `this.stackable = true`).

Run: `git grep -n "isEligible(" -- lib`
Expected: la déclaration dans `forge_rune_rules.dart`, et ses trois lecteurs : `forge_upgrade_dialog.dart`, `shop_controller.dart`, `rest_card_selection_screen.dart` (§4.6).

Run: `git grep -n "boundLevel(" -- lib`
Expected: la déclaration dans `forge_upgrade_data.dart`, et ses cinq lecteurs : `forge_rune_rules.dart` (`_bounded`, que lisent `consolidate` et `fusionOptionsFor` ; et le prédicat), `forge_upgrade_dialog.dart`, `shop_controller.dart` (§4.7).

- [ ] **Step 5: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline <base>..HEAD`
Expected: les huit commits du lot (Tasks 1 à 8). Rien n'est poussé.

---

## Ce que le plan laisse à E2 et aux suivants

Repris de la spec, §2 « Hors d'E1 » et §4.10, pour mémoire — aucune tâche ne les fait :

1. **E2** : la fusion qui propose une rune, l'héritage de D13 sans plafond de runes par carte, l'affûtage, le Puits, la copie du deck en boutique, les pré-forgées bornées par `fusionRank` ; la suppression de la capacité (`baseMaxForgeUpgrades`, ses sept lecteurs), de `pools` et de `stackable` — qui gardent ici tous leurs lecteurs, dont le suffixe de niveau de la fente de la forge et du dialogue de fusion (`forge_slot_row.dart`, `deck_screen.dart`) ; `minFusionRank` ; « une rune par type » hors des runes que D75 ferme à leur plafond ; `cheap`, `precise`, `spectral` et leurs sortes de delta — la donnée de `cheap` tient déjà dans `requiresMinCost` et `excludesRunes`. **Constat pour E2** (spec A6) : sous le prédicat d'E2, la première fusion d'une *Concentration* n'aura aucune rune éligible.
2. **Vague 5 (P-44 lot 1)** : `requiresCost` et `costs` ; les cinq runes de pipeline et leurs sortes de delta ; les évolutions de signature, qui traduiront leurs `SignatureEvolutionData` en paires *(delta, niveau)* pour `EffectiveCard.apply` ; la valeur de `freeze` lue, et `freezing` qui perd son plafond.
3. **Non planifié, signalé pour la file** : le badge « Usage unique » (`ui_card.dart`, `card_component.dart`) et les particules d'épuisement ignorent encore *Persistant* (ADR-094, Conséquences) ; leur faire lire `EffectiveCard.removesExhaust` serait un changement visible que le lot n'annonce pas.
4. **La fin de la vague** : la relance de la simulation par l'orchestrateur (diff strictement vide attendu contre `tool/simulations/d26_reference_output.md`), puis `patch-notes-writer` et `memory-bank-sync` — dont l'ADR « moteur de runes data-driven » qui amende ADR-094 et complète ADR-061 (spec §10).
5. **Note pour cet ADR** : l'éligibilité des runes élémentaires ne lit pas la cible de la carte ; une Attaque `target: self` portant une rune élémentaire poserait son statut sur le héros (« Ce que le plan précise ou corrige de la spec », point 12). Aucune carte livrée ne l'est ; à trancher quand une carte ou une rune le rendra possible — par une condition de cible en donnée, comme celle que `splash` demandera en vague 5 (spec §4.1).
