# P-43 E2, partie 2 — Le Puits, la boutique, les trois runes — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le Puits d'échange remplace la Forge de Fusion — tous les trois actes, une rune contre une autre aux deux tiers de son niveau, `50 × niveau` or, un échange par visite ; la boutique vend la copie d'une carte du deck et retient son étal entier à son nœud ; ses pré-forgées tirent leurs runes comme la fusion ; `pools` et `stackable` disparaissent ; `{val}` vaut pour toute sorte chiffrée ; *Allégé*, *Précis* et *Spectral* rejoignent les huit runes ; le badge « Usage unique » dit vrai et ne chevauche plus rien ; le script de simulation est réaligné, puis son `spectral` aligné sur D33.

**Architecture:** `ForgeRuneRules` gagne les fonctions pures du Puits (`wellBaseCost`, `wellCost`, `wellLevel`, `wellOptions`) et perd `fusionOptionsFor`, `FusionOption`, `isStackable` ; `GoldManager.exchangeRune` paie et écrit, ou rien, à côté de `sharpenRune` ; `ForgeFusionScreen` est réécrit en place, son état de visite local, son retour système résolvant le nœud après un échange. `ShopState` gagne `deckCopy` et `nodeId` ; `ShopController` tire l'étal une fois par nœud et l'oublie par un écouteur (`ref.listen`) sur `currentNodeId` ; ses pré-forgées passent par `ForgeRuneRules.drawRunes`. `CardDelta` gagne trois sortes (`reduceCost`, `critBonus`, `addExhaust`) que lisent `EffectiveCard`, `CardInstance.currentCost` / `exhaustsOnPlay`, `DamagePipeline` et le prédicat (sur le catalogue reçu). Les tables `runeIcons` / `runeColors` sortent de la ligne de rune. Le script de simulation lit ses runes par une liste d'ordre explicite.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Flame, Riverpod 2.6 (`Notifier`), `flutter_test`, `flutter gen-l10n`, `dart run` (script de simulation hors paquet).

**Spec:** `docs/superpowers/specs/2026-10-02-p43-e2-fusion-forge-design.md` — §10, « Partie 2 ». À lire **en entier** : la partie 2 renvoie à §1.2 (A1 à A20 et les trois tableaux « Tranchés… », dont la décision du propriétaire sur l'étal de boutique et ses suites 2 bis, 2 ter, 2 quater), §3, §4.1 à §4.3, §4.8, §4.9, §4.11 à §4.14, §5, §6, §7, §8, §9 en entier, §11. Le déroulé fait foi dans `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` (fiche §8.2, §3.6, §7.3). **La partie 1 est implémentée sur la branche** (`3eafb5e`..`1407e2e`, plan `docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-1.md`) : `minFusionRank`, les conditions 7 et 8 du prédicat, `drawRunes`, `nameAt`, le dialogue de fusion réduit au choix, l'affûtage (`GoldManager.sharpenRune`, `sharpenCost`, `canSharpen`, `hasSharpenableRune`, `replaceRune`), le retour système du feu, la capacité supprimée, le tutoriel du choix — **aucune tâche ne les réécrit**. Le compte rendu `docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md`, §2.2 et §2.3, dit ce que la partie 1 a tranché en route ; sa décision S6 renvoie quatre points à ce plan, placés chacun dans la tâche qui touche son code.

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
- **La base de tests : 1426**, le total de `flutter test` sur la branche le 2026-10-02 (`5f1c3b3`). Chaque tâche donne le total attendu — 1426, plus les tests qu'elle ajoute, moins ceux qu'elle retire, comptés sur les blocs de test que le plan écrit (un cas réécrit ou renommé compte pour zéro ; un `for` qui engendre des tests compte pour ce qu'il engendre). Chaque total a été **mesuré** en rejouant le plan sur une extraction de `5f1c3b3` hors du dépôt :

  | Tâche | Ajoutés | Retirés | Total |
  |:---|---:|---:|---:|
  | 1 — le Puits d'échange | 21 | 12 | 1435 |
  | 2 — les pré-forgées par `drawRunes` | 1 | 1 | 1435 |
  | 3 — la copie du deck, l'étal retenu | 15 | 0 | 1450 |
  | 4 — `pools` et `stackable` supprimés | 2 | 2 | 1450 |
  | 5 — `{val}` pour toute sorte chiffrée | 3 | 0 | 1453 |
  | 6 — *Allégé*, *Précis*, *Spectral* | 22 | 0 | 1475 |
  | 7 — le badge, les prises, l'en-tête des runes | 5 | 0 | 1480 |
  | 8 — la simulation réalignée | 0 | 0 | 1480 |
  | 9 — le `spectral` de la simulation | 0 | 0 | 1480 |

  Task 1 : `forge_rune_rules_test.dart` perd les 6 cas de `fusionOptionsFor` et gagne 6 cas du Puits ; `run_controller_test.dart` gagne 6 cas ; `forge_fusion_screen_test.dart` passe de 5 cas à 7 ; `map_content_placer_test.dart`, neuf, en porte 2 ; `decoupled_forge_test.dart` perd la simulation de la Forge de Fusion.
- **Les `fichier:ligne`** des sections « Files » sont mesurés le 2026-10-02 sur `5f1c3b3`, avant toute tâche. Une tâche qui retouche un fichier qu'une tâche précédente a déjà modifié désigne l'endroit par le texte à remplacer : **c'est ce texte qui fait foi**, pas le numéro.
- **Le périmètre : la partie 2, et elle seule** (spec §10). Rien de ce que la partie 1 a livré n'est réécrit — le prédicat, `drawRunes`, l'affûtage, le dialogue de fusion, le feu, la capacité. Seules exceptions, dites où elles tombent : le commentaire de `replaceRune` (Task 1) et celui de `ForgeSlotRow` (Task 1), qui gagnent le Puits ; la condition de coût du prédicat (Task 6), que la spec renvoie à la partie 2 (A15).
- **Le point propre au lot** (spec §4.11, §10) : à la fin de la partie 2, **`pools`, `stackable`, la capacité, les fentes et la session de forge n'ont plus aucun lecteur** dans `lib/`, `test/`, `assets/` et `tool/` — `git grep -w` ne rend que les trois homonymes de la spec (Task 10). Les deux tests qui gardent leur absence (Task 4) l'écrivent **sans les nommer** : ils comparent l'ensemble des clés.
- **La simulation** (spec §9 ; orchestration §3.6, §7.3 ligne 2) : `tool/simulations/d26_economy_sim.dart` lit dans `assets/data/forge_upgrades/` les champs `id`, `weight` et `eligibleCardTypes`. **Aucune tâche ne change le `weight` d'une rune existante ni ses `eligibleCardTypes`** ; les trois fichiers neufs portent `weight: 50` et **aucun** `eligibleCardTypes`. Le réalignement (Task 8) vient **après toute tâche qui touche `assets/data/`** ; l'alignement de `spectral` (Task 9) est une tâche à part, **la dernière à toucher le script** ; aucune tâche ne touche `assets/data/` après Task 8. **Aucune tâche ne lance la mesure complète** : l'orchestrateur la lance sur le commit de Task 8 puis sur celui de Task 9 (spec §9). `tool/simulations/d26_reference_output.md` n'est touché par aucune tâche.
- **Sauvegarde : aucune étape de migration**, `SaveMigrator.currentVersion` ne bouge pas (spec §7). L'étal retenu de la boutique ne se sauvegarde pas ; `ShopState.toJson` / `fromJson`, sans lecteur, n'apprennent ni `deckCopy` ni `nodeId`. Avant la `1.0.0`, une sauvegarde n'a pas à survivre à un changement de version ; rien de cela n'est testé.
- **Le tutoriel ne référence aucun provider** (ADR-081) ; `test/tutorial/tutorial_isolation_test.dart` reste vert.
- **Aucun id de rune livrée en littéral dans `lib/`** — les trois neuves comprises : `test/unit/rune_ids_in_code_test.dart` le garde.
- **Les lints** (`flutter_lints` 6) que le code du plan respecte : `sort_child_properties_last`, `use_build_context_synchronously`, `curly_braces_in_flow_control_structures`, `no_leading_underscores_for_local_identifiers`.

## Review Focus

Les cinq cas que la spec implique sans qu'un test de son §8 les pose, les plus susceptibles de mordre un joueur ; chacun a son test dans la tâche qui possède le code :

1. **L'or tout juste suffisant au Puits** — 150 or pour donner `sharp:3`, et le Puits vide la bourse au lieu de refuser. Test : Task 1, `run_controller_test.dart`, « depense 50 x L et met la rune recue a sa place, aux deux tiers ».
2. **Une rune donnée qui n'a aucune remplaçante** — une *Défense* peu commune qui porte *Endurci*, sur un catalogue sans *Allégé* (celui du test, une liste fixe de quatre runes livrées ; sur le catalogue livré après la Task 6, *Allégé* la remplacerait) : rien ne peut la remplacer, et la ligne ne doit pas ouvrir une liste vide. Test : Task 1, `forge_fusion_screen_test.dart`, « une rune sans remplacante se montre inactive, avec son motif ».
3. **Une méthode de la boutique appelée juste après un changement de nœud** — l'étal oublié par un `ref.watch` laisse le Notifier « périmé », et le premier `ref.read` d'une méthode y lève une assertion de Riverpod (mesuré : sept tests rouges sous `ref.watch`, « Cannot use ref functions after the dependency of a provider changed but before the provider rebuilt »). Test : Task 3, `shop_controller_test.dart`, les quatre cas « … retire l etal », qui rappellent `initializeShop` aussitôt après le départ.
4. **Une carte à 1 Mana qui porte *Allégé*** — elle ne coûte plus rien, et *Économe* (`requiresMinCost: 1`) ne doit plus s'y offrir, même jugée sur un registre qui n'est pas celui du jeu (le tutoriel). Test : Task 6, `rune_eligibility_test.dart`, « le cout courant se lit apres les runes portees, sur le catalogue recu ».
5. **Une carte de combat qui porte six runes ou plus et *Spectral*** — deux rangées de prises, puis le badge « Usage unique », poussent l'en-tête sous le haut des effets centrés. Test : Task 7, `card_text_renderer_layout_test.dart`, « il descend sous les prises et le badge quand ils le depassent ».

## Ce que le plan précise ou corrige de la spec

Constaté en re-mesurant le code sur `5f1c3b3` et en rejouant le plan sur une extraction hors du dépôt ; aucun n'amende un arbitrage.

1. **La tournure Riverpod de l'étal retenu : `ref.listen`, pas `ref.watch`** (spec §4.9, tableau du tour 3, 2 ter). Essayé : `ref.watch(runProvider.select(...))` dans `build` marque le Notifier périmé dès que le nœud change, et tout `ref.read` d'une de ses méthodes avant une lecture de `state` lève `_assertNotOutdated` — `initializeShop` lit `runProvider` en tête : sept tests rouges. Un écouteur remet l'état à `const ShopState()` au changement même ; les méthodes gardent leurs lectures. Un test garde la remise à zéro (Task 3).
2. **Le cas « la boutique ne tire une rune non cumulable qu'au tier 1 » (`shop_controller_test.dart:504-551`) est supprimé en Task 2**, et non réécrit « plafond 1 » comme le dit la spec (§8, ligne « La boutique ») : `steadfast` à `maxLevel: 1` en ferait la copie exacte du cas `capped` voisin (`:344-389`, `maxLevel: 1`, acte 3, `{'capped:1'}`), qui garde déjà le plafond 1. Le cas tombe dans la tâche qui supprime ce qu'il gardait, la lecture de `isStackable` par la boutique (règle du n° 5 de la levée de l'arrêt).
3. **Les deux tests qui gardent l'absence de `pools` et `stackable` ne les nomment pas** (Task 4) : « toJson n ecrit que les cles du modele » compare l'ensemble exact des clés écrites ; « chaque cle d un fichier de rune est lue par le modele » vérifie chaque clé de chaque fichier contre celles que le modèle lit. Plus forts que la spec (§8 : « aucune ne déclare `pools` ni `stackable` », « `toJson` aller-retour sans `pools` ni `stackable` ») — une clé inconnue quelconque est prise —, ils laissent les commandes de §4.11 ne rendre que les trois homonymes.
4. **Les cas `{val}` neufs — `addEffect` (Task 5), `reduceCost` et `critBonus` (Task 6) — s'écrivent dans `forge_upgrade_data_test.dart`**, le fichier du modèle qui calcule `{val}`, et non dans `decoupled_forge_test.dart` (spec §8, « `{val}` (`:141-171`) étendu aux sortes neuves »). Ce dernier garde ses deux cas `{val}` de `percentBonus` (`:132-149`), que la partie 2 ne touche pas : les cas de `{val}` vivent donc dans deux fichiers, comme avant la partie 2 — les neufs rejoignent le modèle au lieu d'allonger le fichier de la Forge.
5. **Deux tests que la spec (§8) ne liste pas suivent les trois runes neuves** (Task 6) : `test/unit/entity_id_convention_test.dart:64-71` compte 85 fichiers d'entité, 88 désormais ; `test/widget/deck_screen_test.dart:256-270` attend une rune parmi les quatre de la partie 1 — sur le catalogue livré, la Frappe peu commune s'en voit offrir sept, et le cas rougit au hasard (mesuré : rouge sur un passage complet, vert seul).
6. **`ShopScreen.build` est remplacé en entier** (Task 3) : retirer le `PopScope` qui l'enveloppe laisserait 170 lignes décalées de deux espaces, et `dart format` est proscrit. La réécriture range au passage les cartes en vente et la copie du deck dans une même zone défilante : la copie, posée sous un `Expanded`, déborderait une colonne basse. L'état vide garde son `Center` et son aspect.
7. **Le test de l'écran du Puits remplace `gameDataLoaderProvider`** (Task 1), comme `rest_screen_test.dart` : sans cela, la vraie donnée se charge en tâche de fond pendant le test et remplace le registre — mesuré : cinq remplaçantes au lieu de deux.
8. **`damage_pipeline_test.dart` construit `EntityStats` avec `might: 0`**, paramètre requis (`lib/models/entity_stats.dart:31`).
9. **La fumée de Task 8 est un diff, pas une simple exécution** : `--quick` du script d'avant, sur la donnée d'avant (extraite par `git archive` du commit qui ajoute ce plan), puis `--quick` du script réaligné sur la donnée de la vague, doivent rendre deux sorties **identiques à l'octet** — mesuré. C'est le critère du premier temps (D73) en une minute, avant la mesure complète de l'orchestrateur. Mesuré aussi : le script **non** réaligné, sur la donnée de la vague, lit « 20 runes ».
10. **Le commentaire d'en-tête du script est corrigé en Task 8**, à la demande de l'orchestrateur : il dit encore le script « JETABLE … ni committé » (`d26_economy_sim.dart:3-4`), alors que le script est suivi par git depuis le 01/10 (`b691392`), et sa sortie de référence aussi (`37aa9d5`, `tool/simulations/d26_reference_output.md`). Task 8 est la première à éditer le script depuis : elle le corrige, sans toucher à rien de ce qu'il calcule.
11. **La ligne « Données lues » compte les runes, pas les fichiers** (`d26_economy_sim.dart:3840`, `data.runes.length`) : 17 avant et après le réalignement, comme le dit la spec §9 — et non « les fichiers », comme le disent l'orchestration §3.6 et §7.3. Rien n'est à écrire d'avance pour elle au premier temps.
12. **L'en-tête « ⚙️ Upgrades: » de l'infobulle Flutter** (`ui_card_helpers.dart:423`, renvoyé par S6) passe par une clé ARB neuve, `tooltipRunes` (« Runes : » / « Runes: ») : la règle de §5.3 veut qu'un texte réécrit sous `lib/ui/` passe par l'ARB ; son jumeau Flame, « === RUNES === », reste en ligne (couche Flame).
13. **Le débordement des prises en combat, mesuré** (renvoyé par S6). Une carte livrée porte au plus **neuf** runes après la partie 2 : le *Cri de Guerre* (attaque, 2 Mana, dégâts et armure), à partir d'épique — `sharp`, `hardened`, `burning`, `freezing`, `shocking`, `precise`, `spectral`, `quick`, et `cheap` **ou** `eco` (exclusion D51) ; huit pour les autres attaques. Une rare n'en porte que quatre au plus (trois peu communes à une rune, plus l'offre). Neuf runes font deux rangées de prises (`card_text_renderer.dart:366`). Sur une carte de 196 px, l'en-tête d'un nom d'une ligne finit vers y ≈ 37, deux rangées le portent à ≈ 73, le badge « Usage unique » — que *Spectral* montre désormais sur une attaque — à ≈ 87 ; les effets centrés d'une carte à statut (icône de 19 px et minuterie, ≈ 34 px) commencent vers y ≈ 86 : contact ou chevauchement de quelques pixels, et d'une quinzaine pour un nom sur deux lignes (*COUP DE TONNERRE*). Les hauteurs exactes dépendent de la police de la plateforme ; le chevauchement est possible, Task 7 le rend impossible : le bloc central ne monte jamais au-dessus du bas de l'en-tête.
14. **Les références de la spec que la partie 1 a déplacées**, re-mesurées : le prédicat lit le coût en `forge_rune_rules.dart:122` ; `DamagePipeline` du tutoriel en `tutorial_engine.dart:401` (spec `:391`) ; le coût dans le rendu Flame en `card_text_renderer.dart:500` (spec `:519`) ; le badge Flame en `:415` (spec `:434`), le badge Flutter lu en `ui_card.dart:76` puis `:120` (spec `:79`, `:124`) ; `forge_rune_rules_test.dart` : groupe `stackable` `:68-96`, cas « non cumulable » `:106-115`, cas `legacy` `:121-123`, `fusionOptionsFor` `:156-202` ; `decoupled_forge_test.dart` : simulation de la Forge `:181-243`, cas non cumulable `:276-303`, `enduring` `:74-85` ; `shop_controller_test.dart` : `steadfast` `:504-551`, `capped` `:344-389`, Miroir `:251-282`.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/game/services/forge_rune_rules.dart` | Le Puits, `FusionOption` et `fusionOptionsFor` supprimés (1) ; `isStackable` supprimé, `consolidate` sans branche (4) ; le coût du prédicat par l'applicateur (6) | 1, 4, 6 |
| `lib/game/controllers/run/gold_manager.dart`, `lib/game/controllers/run_controller.dart` | `exchangeRune` | 1 |
| `lib/ui/screens/forge_fusion_screen.dart` | Le Puits, réécrit | 1 |
| `lib/services/map/map_content_placer.dart` | Le Puits tous les trois actes | 1 |
| `lib/ui/widgets/map/map_node_widget.dart`, `lib/ui/widgets/map/map_legend.dart` | `wellName`, `wellDesc` | 1 |
| `lib/ui/widgets/forge/forge_slot_row.dart` | Son commentaire (1) ; les tables de `rune_style.dart` (6) | 1, 6 |
| `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/l10n/app_localizations*.dart` | Le Puits (1), la copie du deck (3), l'en-tête des runes (7) | 1, 3, 7 |
| `lib/tutorial/tutorial_data.dart`, `lib/tutorial/widgets/tutorial_node_types_widget.dart` | La prose du Puits (1) et de la boutique (3) | 1, 3 |
| `lib/game/controllers/shop_controller.dart` | Les pré-forgées par `drawRunes` (2) ; la copie, l'étal retenu, `clearCloneOptions` supprimé (3) | 2, 3 |
| `lib/models/shop_state.dart` | `deckCopy`, `nodeId` | 3 |
| `lib/ui/screens/shop_screen.dart` | La copie à part, le `PopScope` supprimé | 3 |
| `lib/game/controllers/deck_controller.dart` | Le commentaire de `copyableCards` | 3 |
| `lib/models/data/forge_upgrade_data.dart` | `pools`, `stackable` supprimés (4) ; `{val}` général (5) et des sortes neuves (6) | 4, 5, 6 |
| `lib/services/content_editor/entity_descriptor.dart` | `requiredKeys`, le gabarit de rune (4) ; le commentaire des icônes (6) | 4, 6 |
| `assets/data/forge_upgrades/*.json` (huit) | Sans `pools` ni `stackable` (4) ; cinq descriptions à `{val}` (5) | 4, 5 |
| `assets/data/forge_upgrades/cheap.json`, `precise.json`, `spectral.json` *(nouveaux)* | Les trois runes | 6 |
| `lib/models/data/card_delta.dart`, `lib/models/effective_card.dart`, `lib/models/card_instance.dart` | Les trois sortes, l'applicateur, `currentCost`, `exhaustsOnPlay` | 6 |
| `lib/game/services/damage_pipeline.dart`, `lib/game/services/effects/strategies.dart` | `critChanceBonus` | 6 |
| `lib/ui/widgets/forge/rune_style.dart` *(nouveau)* | `runeIcons`, `runeColors` | 6 |
| `lib/game/components/widgets/card_text_renderer.dart`, `lib/game/components/card_component.dart`, `lib/game/components/visual_effects/card_animator.dart`, `lib/ui/widgets/ui_card.dart` | Les quatre lecteurs de l'épuisement ; le bloc central sous l'en-tête | 7 |
| `lib/ui/widgets/ui_card/ui_card_helpers.dart` | L'en-tête des runes | 7 |
| `tool/simulations/d26_economy_sim.dart` | Réaligné (8) ; `spectral` sur D33 (9) | 8, 9 |
| `test/unit/forge_rune_rules_test.dart` | Le Puits (1) ; `stackable` (4) | 1, 4 |
| `test/unit/run_controller_test.dart` | `exchangeRune`, refus de `sharpenRune` | 1 |
| `test/widget/forge_fusion_screen_test.dart` | Le Puits (réécrit) | 1 |
| `test/unit/map_content_placer_test.dart` *(nouveau)* | Le placement | 1 |
| `test/unit/decoupled_forge_test.dart` | La simulation de la Forge (1) ; `pools`, plafond 1 (4) | 1, 4 |
| `test/unit/shop_controller_test.dart` | Les pré-forgées (2) ; la copie, l'étal (3) ; `pools` (4) | 2, 3, 4 |
| `test/widget/shop_screen_test.dart` | La copie, le retour, le Miroir | 3 |
| `test/unit/forge_upgrade_data_test.dart` | Les clés (4) ; `{val}` (5, 6) ; les sortes (6) | 4, 5, 6 |
| `test/unit/forge_upgrades_catalog_test.dart` | Les clés (4) ; onze runes, la matrice (6) | 4, 6 |
| `test/unit/real_bundle_load_test.dart` | Le plafond 1 (4) ; onze runes (6) | 4, 6 |
| `test/unit/effective_card_test.dart`, `rune_eligibility_test.dart`, `save_catalog_lookups_test.dart`, `deck_state_persistence_test.dart`, `test/widget/ui_card_rune_sockets_test.dart` | Sans `pools` (4) ; les sortes, A15 (6) | 4, 6 |
| `test/unit/content_editor/fixtures.dart`, `entity_validator_test.dart`, `known_values_test.dart`, `field_kind_test.dart`, `entity_descriptor_test.dart`, `test/widget/content_editor/document_form_test.dart` | L'éditeur sans `pools` | 4 |
| `test/unit/damage_pipeline_test.dart` *(nouveau)* | `critChanceBonus` | 6 |
| `test/unit/rune_resolution_test.dart`, `test/unit/deck_controller_test.dart`, `test/unit/referential_integrity_test.dart`, `test/unit/rune_ids_in_code_test.dart`, `test/unit/entity_id_convention_test.dart`, `test/widget/deck_screen_test.dart`, `test/tutorial/tutorial_engine_test.dart` | Les trois runes livrées | 6 |
| `test/widget/ui_card_values_test.dart` | Le badge, l'en-tête | 7 |
| `test/unit/card_text_renderer_layout_test.dart` *(nouveau)* | Le bloc central | 7 |

---

### Task 1: Le Puits d'échange remplace la Forge de Fusion

Le nœud `forgeFusion` devient le Puits (spec §4.8, A5, A6) : placé à coup sûr aux actes 3, 6, 9…, sur un combat ou un événement des étages 3 à 7 ; l'écran montre les cartes qui portent une rune, la rune à donner, puis **toutes** ses remplaçantes — jugées par le prédicat sur la carte sans la rune donnée —, chacune à son niveau d'arrivée (deux tiers du niveau donné, arrondis, au moins 1, bornés) et au prix `50 × niveau donné`. Un échange par visite ; après lui, le retour système résout le nœud par le chemin de la sortie ; sans échange, il ferme l'écran sans le résoudre. L'échange payant vit dans `GoldManager.exchangeRune` (A16), ses formules dans `ForgeRuneRules`. `FusionOption` et `fusionOptionsFor` disparaissent avec la Forge de Fusion. Les textes joueur qui la nommaient — en-tête, infobulle, légende, tutoriel — nomment le Puits (§5.4, §5.5, §5.7). S6 : `sharpenRune` gagne ses refus pour une rune non portée et pour une rune absente du registre, testés à côté de ceux d'`exchangeRune`.

Changements de jeu de la tâche, voulus : le Puits remplace la Forge de Fusion, garanti tous les trois actes au lieu d'une chance de 25 % à chaque acte ; aux actes 1, 2, 4, 5, 7… il n'y en a plus.

**Files:**
- Modify: `lib/game/services/forge_rune_rules.dart:6-28` (`FusionOption`, la doc de la classe), `:67-96` (`fusionOptionsFor`), `:206-218` (`replaceRune`, puis le Puits)
- Modify: `lib/game/controllers/run/gold_manager.dart:2-3`, `:50-51`
- Modify: `lib/game/controllers/run_controller.dart:458-462`
- Rewrite: `lib/ui/screens/forge_fusion_screen.dart` (447 lignes)
- Modify: `lib/services/map/map_content_placer.dart:23-24`
- Modify: `lib/ui/widgets/map/map_node_widget.dart:54-61` ; `lib/ui/widgets/map/map_legend.dart:114-120`
- Modify: `lib/ui/widgets/forge/forge_slot_row.dart:5-8`
- Modify: `lib/l10n/app_en.arb:488` ; `lib/l10n/app_fr.arb:202` ; régénérés : `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_fr.dart`
- Modify: `lib/tutorial/tutorial_data.dart:82`, `:96-97`, `:276`, `:292-293` ; `lib/tutorial/widgets/tutorial_node_types_widget.dart:84-87`
- Test: `test/unit/forge_rune_rules_test.dart:156-202` (supprimé), après `:302` (groupe neuf)
- Test: `test/unit/run_controller_test.dart` après `:330`
- Test: `test/widget/forge_fusion_screen_test.dart` (réécrit en entier)
- Test: `test/unit/map_content_placer_test.dart` (nouveau)
- Test: `test/unit/decoupled_forge_test.dart:181-243` (supprimé)

**Interfaces:**
- Consumes: `ForgeRuneRules.isEligible` (partie 1, conditions 7 et 8), `ForgeRuneRules.replaceRune`, `ForgeUpgradeData.boundLevel`, `levelsOf`, `nameAt`, `getDescription` ; `ForgeSlotRow(rune, title, detail, description, actionLabel, onAction)` ; `RunController.completeCurrentNode`, `checkpointProvider`.
- Produces:
  - `static const int ForgeRuneRules.wellBaseCost = 50` ;
  - `static int ForgeRuneRules.wellCost(int givenLevel)` → `wellBaseCost * givenLevel` ;
  - `static int ForgeRuneRules.wellLevel(ForgeUpgradeData received, int givenLevel)` → `received.boundLevel((2 * givenLevel + 1) ~/ 3)` ;
  - `static List<ForgeUpgradeData> ForgeRuneRules.wellOptions(CardInstance card, String givenId, Iterable<ForgeUpgradeData> catalog)` — les runes du catalogue, dans son ordre, que le prédicat accepte sur la carte sans la rune donnée, la rune donnée exclue ;
  - `bool GoldManager.exchangeRune(String cardId, String givenId, String receivedId)` et `bool RunController.exchangeRune(...)`, qui y délègue ;
  - les clés ARB `wellTitle`, `wellName`, `wellDesc`, `wellEmpty`, `wellPickCard`, `wellNoOption`, `wellReceive(int level)`, `wellExchange(int cost)`, `wellDone(String oldRune, String newRune, int level)`, `wellLeave`.

- [ ] **Step 1: Écrire les tests des règles et de l'opération**

In `test/unit/forge_rune_rules_test.dart`, delete the whole group `ForgeRuneRules.fusionOptionsFor` (`:156-202`) : from the line `  group('ForgeRuneRules.fusionOptionsFor', () {` up to and including the blank line before `  // L'offre de la fusion (spec P-43 E2, A2, §4.4).`. `_cardWith` (`:34-45`) **reste** : le groupe de l'affûtage le lit.

Then, at the end of the file, replace:

```dart
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });
  });
}
```

with:

```dart
            _cardWith(['eco:1', 'sharp:3']), catalog),
        isTrue,
      );
    });
  });

  // Le Puits d'echange (spec P-43 E2, A5, A6, §4.8).
  group('le Puits', () {
    const given = [1, 2, 3, 4, 5, 6, 9, 12];

    test('wellCost : 50 or par niveau de la rune donnee (A6, D39)', () {
      expect([for (final level in given) ForgeRuneRules.wellCost(level)],
          [50, 100, 150, 200, 250, 300, 450, 600]);
    });

    test('wellLevel : les deux tiers, arrondis au plus proche, au moins 1 '
        '(D39)', () {
      expect(
        [for (final level in given) ForgeRuneRules.wellLevel(_rune('x'), level)],
        [1, 1, 2, 3, 3, 4, 6, 8],
      );
    });

    test('wellLevel : borne par le plafond de la rune recue — Tranchant 9 '
        'contre Econome 1', () {
      expect(ForgeRuneRules.wellLevel(_rune('eco', maxLevel: 1), 9), 1);
    });

    // Les runes livrees, par une liste fixe : le cas ne bouge pas quand une
    // rune s'ajoute au catalogue.
    List<String> optionsOf(
      CardInstance card,
      String givenId,
      List<String> ids,
    ) =>
        [
          for (final rune in ForgeRuneRules.wellOptions(
              card, givenId, [for (final id in ids) shippedRune(id)]))
            rune.id,
        ];

    test('wellOptions : toutes les eligibles, la rune donnee exclue', () {
      final strike = CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['sharp:2'],
      );
      expect(
        optionsOf(
            strike, 'sharp', const ['burning', 'freezing', 'hardened', 'sharp']),
        ['burning', 'freezing'],
      );
    });

    test('wellOptions : jugee sans la rune donnee — Persistant donne, Econome '
        'possible sur une rare', () {
      final potion = CardInstance(
        data: shippedCard('heal_potion'),
        rarity: CardRarity.rare,
        forgeUpgrades: const ['enduring:1'],
      );
      expect(optionsOf(potion, 'enduring', const ['eco', 'enduring', 'quick']),
          ['eco', 'quick']);
    });

    test('wellOptions : au rang de la carte', () {
      final potion = CardInstance(
        data: shippedCard('heal_potion'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['enduring:1'],
      );
      expect(optionsOf(potion, 'enduring', const ['eco', 'enduring', 'quick']),
          isEmpty);
    });
  });
}
```

In `test/unit/run_controller_test.dart`, replace:

```dart
    test('refuse faute d or, sans rien toucher', () {
      final card = seed(const ['sharp:2'], gold: 99);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isFalse);

      expect(container.read(inventoryProvider).gold, 99);
      expect(runesOf(card), ['sharp:2']);
    });
  });
}
```

with:

```dart
    test('refuse faute d or, sans rien toucher', () {
      final card = seed(const ['sharp:2'], gold: 99);

      expect(run.sharpenRune(card.uniqueId, 'sharp'), isFalse);

      expect(container.read(inventoryProvider).gold, 99);
      expect(runesOf(card), ['sharp:2']);
    });

    test('refuse une rune que la carte ne porte pas, sans rien toucher', () {
      final card = seed(const ['sharp:2'], gold: 1000);

      expect(run.sharpenRune(card.uniqueId, 'burning'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:2']);
    });

    test('refuse une rune absente du registre, sans rien toucher', () {
      final card = seed(const ['legacy:1'], gold: 1000);

      expect(run.sharpenRune(card.uniqueId, 'legacy'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['legacy:1']);
    });
  });

  // Le Puits : payer et ecrire, ou rien (spec P-43 E2, §4.8, A16).
  group('RunController.exchangeRune', () {
    late ProviderContainer container;
    late RunController run;

    setUp(() {
      shippedRuneRegistry(const ['burning', 'eco', 'hardened', 'quick', 'sharp']);
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

    // Review Focus 1 : l'or tout juste suffisant.
    test('depense 50 x L et met la rune recue a sa place, aux deux tiers', () {
      final card = seed(const ['sharp:3', 'quick:1'], gold: 150);

      expect(run.exchangeRune(card.uniqueId, 'sharp', 'burning'), isTrue);

      expect(container.read(inventoryProvider).gold, 0);
      expect(runesOf(card), ['burning:2', 'quick:1']);
    });

    test('refuse une rune recue hors wellOptions, sans rien toucher', () {
      final card = seed(const ['sharp:3', 'quick:1'], gold: 1000);

      // Endurci ne vise que l'armure ; Veloce est deja portee.
      expect(run.exchangeRune(card.uniqueId, 'sharp', 'hardened'), isFalse);
      expect(run.exchangeRune(card.uniqueId, 'sharp', 'quick'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:3', 'quick:1']);
    });

    test('refuse faute d or, sans rien toucher', () {
      final card = seed(const ['sharp:3'], gold: 149);

      expect(run.exchangeRune(card.uniqueId, 'sharp', 'burning'), isFalse);

      expect(container.read(inventoryProvider).gold, 149);
      expect(runesOf(card), ['sharp:3']);
    });

    test('refuse une rune donnee que la carte ne porte pas, sans rien '
        'toucher', () {
      final card = seed(const ['sharp:3'], gold: 1000);

      expect(run.exchangeRune(card.uniqueId, 'burning', 'eco'), isFalse);

      expect(container.read(inventoryProvider).gold, 1000);
      expect(runesOf(card), ['sharp:3']);
    });
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/run_controller_test.dart`
Expected: FAIL à la compilation — `wellCost`, `wellLevel`, `wellOptions` et `exchangeRune` ne sont pas définis. Les deux refus neufs de `sharpenRune` passeraient déjà : la partie 1 les tient (`gold_manager.dart:20-35`) ; ils manquaient à ses tests (S6).

- [ ] **Step 3: Écrire les règles du Puits et l'échange payant**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
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

with:

```dart
  /// [refs] où la référence de la rune [runeId] cède la place à
  /// [replacement], à sa place (spec P-43 E2, §4.7, §4.8) : l'affûtage la
  /// réécrit `id:n+1`, le Puits y met la rune reçue. Une référence mal formée
  /// reste telle quelle.
  static List<String> replaceRune(
    List<String> refs,
    String runeId,
    String replacement,
  ) =>
      [
        for (final ref in refs)
          ForgeUpgradeData.parseRef(ref)?.$1 == runeId ? replacement : ref,
      ];

  /// La base du prix du Puits d'échange (spec P-43 E2, A6) : distincte de
  /// [sharpenBaseCost] — deux prix que la mesure fait varier séparément.
  static const wellBaseCost = 50;

  /// Le coût d'un échange au Puits : la base fois le niveau de la rune
  /// donnée (D6, D39).
  static int wellCost(int givenLevel) => wellBaseCost * givenLevel;

  /// Le niveau auquel [received] entre au Puits contre une rune de niveau
  /// [givenLevel] (D39) : les deux tiers, arrondis au plus proche — deux
  /// tiers d'un entier ne tombent jamais sur une demie —, au moins 1 dès le
  /// niveau 1, puis bornés par le plafond de [received] (D72).
  static int wellLevel(ForgeUpgradeData received, int givenLevel) =>
      received.boundLevel((2 * givenLevel + 1) ~/ 3);

  /// Les runes du [catalog] qui peuvent remplacer la rune [givenId] de
  /// [card] au Puits (spec P-43 E2, A5, §4.8) : toutes celles que le
  /// prédicat accepte sur la carte **sans** la rune donnée, à son rang — une
  /// exclusion que l'échange défait ne refuse rien —, la rune donnée
  /// exclue. Dans l'ordre du catalogue.
  static List<ForgeUpgradeData> wellOptions(
    CardInstance card,
    String givenId,
    Iterable<ForgeUpgradeData> catalog,
  ) {
    final without = card.copyWith(forgeUpgrades: [
      for (final ref in card.forgeUpgrades)
        if (ForgeUpgradeData.parseRef(ref)?.$1 != givenId) ref,
    ]);
    return [
      for (final rune in catalog)
        if (rune.id != givenId && isEligible(rune, without, catalog)) rune,
    ];
  }
}
```

In `lib/game/controllers/run/gold_manager.dart`, replace:

```dart
import '../../../models/data/forge_upgrade_data.dart';
import '../../services/forge_rune_rules.dart';
```

with:

```dart
import '../../../models/data/forge_upgrade_data.dart';
import '../../../models/data/game_data_registry.dart';
import '../../services/forge_rune_rules.dart';
```

Then replace the end of the file:

```dart
          ),
        );
    return true;
  }
}
```

with:

```dart
          ),
        );
    return true;
  }

  /// Échange au Puits la rune [givenId] de la carte [cardId] du deck contre
  /// [receivedId] (D6, D39 ; spec P-43 E2, A5, §4.8) : la rune reçue prend
  /// sa place, au niveau `ForgeRuneRules.wellLevel`, contre
  /// `ForgeRuneRules.wellCost(niveau donné)` or. Refuse — sans rien toucher —
  /// si la carte ne porte pas la rune donnée, si la rune reçue n'est pas
  /// parmi `ForgeRuneRules.wellOptions`, ou si l'or manque. Rend vrai si
  /// l'échange a eu lieu.
  bool exchangeRune(String cardId, String givenId, String receivedId) {
    final card = ref
        .read(deckProvider)
        .masterDeck
        .where((c) => c.uniqueId == cardId)
        .firstOrNull;
    final level = card == null
        ? null
        : ForgeUpgradeData.levelsOf(card.forgeUpgrades)[givenId];
    if (card == null || level == null) return false;
    final received = ForgeRuneRules.wellOptions(
      card,
      givenId,
      GameDataRegistry.instance?.forgeUpgrades ?? const [],
    ).where((r) => r.id == receivedId).firstOrNull;
    if (received == null) return false;
    if (!ref
        .read(inventoryProvider.notifier)
        .spendGold(ForgeRuneRules.wellCost(level))) {
      return false;
    }
    ref.read(deckProvider.notifier).setForgeUpgrades(
          cardId,
          ForgeRuneRules.replaceRune(
            card.forgeUpgrades,
            givenId,
            '$receivedId:${ForgeRuneRules.wellLevel(received, level)}',
          ),
        );
    return true;
  }
}
```

In `lib/game/controllers/run_controller.dart`, replace:

```dart
  bool sharpenRune(String cardId, String runeId) =>
      _goldManager.sharpenRune(cardId, runeId);
}
```

with:

```dart
  bool sharpenRune(String cardId, String runeId) =>
      _goldManager.sharpenRune(cardId, runeId);

  /// Échange au Puits une rune d'une carte du deck contre une autre, contre
  /// de l'or (spec P-43 E2, §4.8) ; voir `GoldManager.exchangeRune`.
  bool exchangeRune(String cardId, String givenId, String receivedId) =>
      _goldManager.exchangeRune(cardId, givenId, receivedId);
}
```

- [ ] **Step 4: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_rune_rules_test.dart test/unit/run_controller_test.dart`
Expected: PASS.

- [ ] **Step 5: Réécrire le test de l'écran du Puits**

Replace the whole content of `test/widget/forge_fusion_screen_test.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/checkpoint_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/screens/forge_fusion_screen.dart';
import 'package:roguelike_card_game/ui/widgets/forge/forge_slot_row.dart';
import 'package:roguelike_card_game/ui/widgets/notification_overlay.dart';
import 'package:roguelike_card_game/ui/widgets/ui_card.dart';

import '../unit/shipped_data.dart';

/// Le Puits d'échange (spec P-43 E2, A5, §4.8), sur les runes livrées.
void main() {
  const hero = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );

  /// Une Frappe rare portant [runes].
  CardInstance strike(List<String> runes) => CardInstance(
        data: shippedCard('strike_basic'),
        rarity: CardRarity.rare,
        forgeUpgrades: runes,
      );

  /// Une run neuve, au premier nœud de sa carte, avec [deck] pour deck et
  /// [gold] or. Une liste fixe de runes livrées : le cas ne bouge pas quand
  /// une rune s'ajoute au catalogue. Le chargeur de données est remplacé :
  /// sans cela, la vraie donnée se charge en tâche de fond et remplace le
  /// registre pendant le test.
  ProviderContainer startRun(
    WidgetTester tester, {
    required List<CardInstance> deck,
    int gold = 1000,
  }) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final registry =
        shippedRuneRegistry(const ['burning', 'eco', 'hardened', 'sharp']);
    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => registry)],
    );
    addTearDown(container.dispose);

    final run = container.read(runProvider.notifier);
    run.startNewRun(hero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    container.read(inventoryProvider.notifier).reset(initialGold: gold);
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

  /// Le Puits en page d'accueil.
  Future<ProviderContainer> pumpWell(
    WidgetTester tester, {
    required List<CardInstance> deck,
    int gold = 1000,
  }) async {
    final container = startRun(tester, deck: deck, gold: gold);
    await tester.pumpWidget(app(container, const ForgeFusionScreen()));
    await tester.pumpAndSettle();
    return container;
  }

  /// Le Puits poussé sur une vraie pile, comme la carte du monde le pousse :
  /// le retour système a une page où revenir.
  Future<ProviderContainer> pushWell(
    WidgetTester tester, {
    required List<CardInstance> deck,
  }) async {
    final container = startRun(tester, deck: deck);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForgeFusionScreen()),
            ),
            child: const Text('Ouvrir le Puits'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir le Puits'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Échange Tranchant 3, sur la seule carte du deck, contre Brûlant : la
  /// carte, la rune donnée, puis la première remplaçante.
  Future<void> exchangeSharp(WidgetTester tester) async {
    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tranchant 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Échanger — 150 or').first);
    await tester.pumpAndSettle();
  }

  // La notification se ferme d'elle-même après 3,5 s.
  Future<void> settleNotification(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
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

  testWidgets('les cartes qui portent une rune, et elles seules',
      (tester) async {
    await pumpWell(tester, deck: [
      strike(const ['sharp:2']),
      CardInstance(data: shippedCard('defend_basic')),
    ]);

    expect(find.text('PUITS D\'ÉCHANGE'), findsOneWidget);
    expect(find.text('Choisissez une carte, puis la rune à donner.'),
        findsOneWidget);
    expect(find.byType(UiCard), findsOneWidget);
  });

  testWidgets('les remplacantes d une rune : toutes, a leur niveau d arrivee, '
      'au cout de la rune donnee', (tester) async {
    await pumpWell(tester, deck: [strike(const ['sharp:3'])]);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tranchant 3'));
    await tester.pumpAndSettle();

    // Brulant aux deux tiers de 3, Econome borne a 1 ; Endurci ne vise que
    // l'armure.
    expect(find.byType(ForgeSlotRow), findsNWidgets(2));
    expect(find.text('Échanger — 150 or'), findsNWidgets(2));
    expect(find.text('Reçue au niveau 2'), findsOneWidget);
    expect(find.text('Reçue au niveau 1'), findsOneWidget);
  });

  testWidgets('un echange par visite : le Puits echange, puis ne propose plus '
      'que la sortie', (tester) async {
    final card = strike(const ['sharp:3']);
    final container = await pumpWell(tester, deck: [card], gold: 300);

    await exchangeSharp(tester);

    expect(container.read(deckProvider).masterDeck.single.forgeUpgrades,
        ['burning:2']);
    expect(container.read(inventoryProvider).gold, 150);
    expect(container.read(notificationProvider).last.message,
        'Tranchant devient Brûlant (niveau 2).');
    // L'or suffirait a un second echange : rien ne le propose plus.
    expect(find.byType(UiCard), findsNothing);
    expect(find.byType(ForgeSlotRow), findsNothing);
    expect(find.text('Quitter le Puits'), findsOneWidget);

    await settleNotification(tester);
  });

  // Review Focus 2.
  testWidgets('une rune sans remplacante se montre inactive, avec son motif',
      (tester) async {
    // Une Defense peu commune, sur ce catalogue sans Allege : ni degats, ni
    // rang 2.
    await pumpWell(tester, deck: [
      CardInstance(
        data: shippedCard('defend_basic'),
        rarity: CardRarity.uncommon,
        forgeUpgrades: const ['hardened:1'],
      ),
    ]);

    await tester.tap(find.byType(UiCard));
    await tester.pumpAndSettle();
    expect(find.text('Aucune autre rune ne peut la remplacer.'),
        findsOneWidget);

    await tester.tap(find.text('Endurci 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ForgeSlotRow), findsNothing);
  });

  testWidgets('un deck sans rune montre l ecran vide et la sortie',
      (tester) async {
    await pumpWell(tester, deck: [CardInstance(data: shippedCard('defend_basic'))]);

    expect(find.text('Aucune carte de votre deck ne porte de rune à échanger.'),
        findsOneWidget);
    expect(find.text('Quitter le Puits'), findsOneWidget);
  });

  // Spec P-43 E2, A5 : apres un echange, toute sortie resout le noeud ; sans
  // echange, le joueur peut revenir.
  group('le retour systeme', () {
    testWidgets('apres un echange, il resout le noeud et ferme l ecran, une '
        'seule fois', (tester) async {
      final container = await pushWell(tester, deck: [strike(const ['sharp:3'])]);

      await exchangeSharp(tester);
      await pressBack(tester);

      expect(find.byType(ForgeFusionScreen), findsNothing);
      expect(find.text('Ouvrir le Puits'), findsOneWidget);
      expect(currentNodeCompleted(container), isTrue);
      expect(container.read(checkpointProvider), 1);

      await settleNotification(tester);
    });

    testWidgets('sans echange, il ferme l ecran et le noeud reste non resolu',
        (tester) async {
      final container = await pushWell(tester, deck: [strike(const ['sharp:3'])]);

      await pressBack(tester);

      expect(find.byType(ForgeFusionScreen), findsNothing);
      expect(currentNodeCompleted(container), isFalse);
      expect(container.read(checkpointProvider), 0);
    });
  });
}
```

- [ ] **Step 6: Lancer le test de l'écran pour le voir échouer**

Run: `flutter test test/widget/forge_fusion_screen_test.dart`
Expected: FAIL — l'écran d'aujourd'hui (la Forge de Fusion) ne connaît ni « PUITS D'ÉCHANGE », ni les remplaçantes.

- [ ] **Step 7: Les chaînes du Puits**

In `lib/l10n/app_en.arb`, replace:

```json
  "runeMaxLevel": "Max level",
```

with:

```json
  "runeMaxLevel": "Max level",
  "wellTitle": "EXCHANGE WELL",
  "wellName": "Exchange Well",
  "wellDesc": "Swap one of a card's runes for another, for gold.",
  "wellEmpty": "No card in your deck carries a rune to swap.",
  "wellPickCard": "Choose a card, then the rune to give up.",
  "wellNoOption": "No other rune can replace it.",
  "wellReceive": "Received at level {level}",
  "@wellReceive": {
    "placeholders": {
      "level": { "type": "int" }
    }
  },
  "wellExchange": "Swap — {cost} gold",
  "@wellExchange": {
    "placeholders": {
      "cost": { "type": "int" }
    }
  },
  "wellDone": "{oldRune} becomes {newRune} (level {level}).",
  "@wellDone": {
    "placeholders": {
      "oldRune": { "type": "String" },
      "newRune": { "type": "String" },
      "level": { "type": "int" }
    }
  },
  "wellLeave": "Leave the Well",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "runeMaxLevel": "Niveau maximal",
```

with:

```json
  "runeMaxLevel": "Niveau maximal",
  "wellTitle": "PUITS D'ÉCHANGE",
  "wellName": "Puits d'échange",
  "wellDesc": "Échangez une rune d'une carte contre une autre, contre de l'or.",
  "wellEmpty": "Aucune carte de votre deck ne porte de rune à échanger.",
  "wellPickCard": "Choisissez une carte, puis la rune à donner.",
  "wellNoOption": "Aucune autre rune ne peut la remplacer.",
  "wellReceive": "Reçue au niveau {level}",
  "wellExchange": "Échanger — {cost} or",
  "wellDone": "{oldRune} devient {newRune} (niveau {level}).",
  "wellLeave": "Quitter le Puits",
```

Run: `flutter gen-l10n`
Expected: les trois `lib/l10n/app_localizations*.dart` régénérés, qui exposent les dix clés.

- [ ] **Step 8: Réécrire l'écran du Puits, retirer la Forge de Fusion**

Replace the whole content of `lib/ui/screens/forge_fusion_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/forge/forge_slot_row.dart';
import '../widgets/game_button.dart';
import '../widgets/gold_indicator.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/page_header.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/ui_card.dart';

/// Le Puits d'échange (D6, D22 ; spec P-43 E2, A5, §4.8) : une rune d'une
/// carte contre n'importe quelle autre que le prédicat lui permet, aux deux
/// tiers de son niveau, contre `50 × niveau` or. Un échange par visite : fait,
/// l'écran ne propose plus que la sortie, et toute sortie résout le nœud. Le
/// nœud garde son type `forgeFusion`, l'écran son nom (A17).
class ForgeFusionScreen extends ConsumerStatefulWidget {
  const ForgeFusionScreen({super.key});

  @override
  ConsumerState<ForgeFusionScreen> createState() => _ForgeFusionScreenState();
}

class _ForgeFusionScreenState extends ConsumerState<ForgeFusionScreen> {
  /// La carte choisie, par son identifiant : elle se relit dans le deck.
  String? _cardId;

  /// La rune à donner, sur la carte choisie.
  String? _givenId;

  /// Un échange par visite (spec P-43 E2, A5) : un état de déroulé de
  /// l'écran, qui ne lui survit pas — toute sortie après l'échange résout le
  /// nœud.
  bool _exchanged = false;

  /// Les runes du [catalog] que [card] porte, chacune à son niveau.
  static List<(ForgeUpgradeData, int)> _runesOf(
    CardInstance card,
    List<ForgeUpgradeData> catalog,
  ) =>
      [
        for (final MapEntry(key: id, value: level)
            in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
          if (catalog.where((r) => r.id == id).firstOrNull case final rune?)
            (rune, level),
      ];

  void _exchange(
    CardInstance card,
    ForgeUpgradeData given,
    ForgeUpgradeData received,
    int level,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    if (!ref
        .read(runProvider.notifier)
        .exchangeRune(card.uniqueId, given.id, received.id)) {
      return;
    }
    setState(() => _exchanged = true);
    context.showNotification(
      l10n.wellDone(given.getName(locale), received.getName(locale), level),
      type: NotificationType.success,
    );
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final gold = ref.watch(inventoryProvider).gold;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final cards = [
      for (final card in ref.watch(deckProvider).masterDeck)
        if (_runesOf(card, catalog).isNotEmpty) card,
    ];
    final selected = cards.where((c) => c.uniqueId == _cardId).firstOrNull;

    final Widget content;
    if (_exchanged) {
      content = const Center(
        child: Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
      );
    } else if (cards.isEmpty) {
      content = Center(
        child: Text(
          l10n.wellEmpty,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      content = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.wellPickCard,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: 120,
                    child: UiCard.fromInstance(
                      card: card,
                      locale: locale,
                      l10n: l10n,
                      isSelected: card.uniqueId == _cardId,
                      onTap: () => setState(() {
                        _cardId = card.uniqueId;
                        _givenId = null;
                      }),
                    ),
                  ),
              ],
            ),
            if (selected != null) ..._runeChoice(selected, catalog, gold),
          ],
        ),
      );
    }

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      // Avant tout échange, le retour ferme l'écran sans résoudre le nœud :
      // le joueur peut revenir. Après, il le résout par le chemin de la
      // sortie ; le pop de `_leave` repasse ici avec `didPop` vrai (A5).
      canPop: !_exchanged,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      appBar: PageHeader(
        title: l10n.wellTitle,
        showBackButton: false,
        isParchment: false,
        actions: const [GoldIndicator()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            const SizedBox(height: 24),
            Center(
              child: GameButton(
                text: l10n.wellLeave,
                onPressed: _leave,
                baseColor: Colors.deepPurpleAccent,
                height: 48,
                width: 220,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Les runes de [card], la rune à donner choisie parmi elles, puis toutes
  /// ses remplaçantes (spec P-43 E2, A5, §4.8). Une rune sans remplaçante se
  /// montre inactive, avec son motif.
  List<Widget> _runeChoice(
    CardInstance card,
    List<ForgeUpgradeData> catalog,
    int gold,
  ) {
    final runes = _runesOf(card, catalog);
    final given = runes.where((r) => r.$1.id == _givenId).firstOrNull;
    return [
      const SizedBox(height: 24),
      for (final (rune, level) in runes) _givenTile(card, rune, level, catalog),
      if (given case (final rune, final level)) ...[
        const SizedBox(height: 16),
        for (final received in ForgeRuneRules.wellOptions(card, rune.id, catalog))
          _optionRow(card, rune, level, received, gold),
      ],
    ];
  }

  /// Une rune de la carte, à donner.
  Widget _givenTile(
    CardInstance card,
    ForgeUpgradeData rune,
    int level,
    List<ForgeUpgradeData> catalog,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final hasOption =
        ForgeRuneRules.wellOptions(card, rune.id, catalog).isNotEmpty;
    return ListTile(
      enabled: hasOption,
      selected: rune.id == _givenId,
      leading: Text(rune.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        rune.nameAt(level, locale),
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: hasOption
          ? null
          : Text(
              l10n.wellNoOption,
              style: const TextStyle(color: Colors.white54),
            ),
      onTap: () => setState(() => _givenId = rune.id),
    );
  }

  /// Une remplaçante de [given], portée au niveau [givenLevel] : son niveau
  /// d'arrivée, ce qu'elle fait sur la carte, et « Échanger — coût or »,
  /// inactif faute d'or.
  Widget _optionRow(
    CardInstance card,
    ForgeUpgradeData given,
    int givenLevel,
    ForgeUpgradeData received,
    int gold,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final level = ForgeRuneRules.wellLevel(received, givenLevel);
    final cost = ForgeRuneRules.wellCost(givenLevel);
    return ForgeSlotRow(
      rune: received,
      title: received.getName(locale),
      detail: l10n.wellReceive(level),
      description:
          received.getDescription(level, locale, card.data, card.rarity),
      actionLabel: l10n.wellExchange(cost),
      onAction: gold >= cost
          ? () => _exchange(card, given, received, level)
          : null,
    );
  }
}
```

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
/// Une fusion que propose la Forge de Fusion : toutes les runes d'un même id
/// portées par une carte, réunies en une seule dont le tier est la somme.
class FusionOption {
  final String upgradeId;
  final List<String> originalUpgrades;
  final int totalTier;
  final int cost;

  FusionOption({
    required this.upgradeId,
    required this.originalUpgrades,
    required this.totalTier,
    required this.cost,
  });
}

/// Règles de combinaison des runes de forge, notées `id:tier`.
///
/// La Forge de Fusion et la fusion 3→1 additionnent les tiers des runes de
/// même id. Une rune non cumulable (`ForgeUpgradeData.stackable`) n'a pas de
/// tier qui vaille : elle n'est jamais proposée à la fusion, et une fusion 3→1
/// n'en garde qu'un exemplaire, au tier 1. Les références se lisent par
/// l'analyseur unique du modèle, `ForgeUpgradeData.parseRef` (ADR-094 D5).
class ForgeRuneRules {
```

with:

```dart
/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
/// fusion 3→1 (D13), son offre, l'affûtage au feu de camp et l'échange au
/// Puits (spec P-43 E2). Une rune non cumulable (`ForgeUpgradeData.stackable`)
/// n'a pas de niveau qui vaille : une fusion 3→1 n'en garde qu'un exemplaire,
/// au niveau 1. Les références se lisent par l'analyseur unique du modèle,
/// `ForgeUpgradeData.parseRef` (ADR-094 D5).
class ForgeRuneRules {
```

Then delete `fusionOptionsFor` (`:67-96`) : from the line `  /// Fusions que la Forge de Fusion propose pour [card] : une par id de rune` up to and including the blank line before `  /// La rune [rune] peut-elle s'offrir à [card] ? Le prédicat unique de`. `_bounded` reste : `consolidate` le lit.

In `test/unit/decoupled_forge_test.dart`, delete the test `Identical upgrades fusion simulation calculations and costs` (`:181-243`) : from `    test('Identical upgrades fusion simulation calculations and costs', () {` up to and including the blank line before `    List<CardInstance> threeCopies(List<String> runes) => List.generate(`. Il simulait la Forge de Fusion sans lire de code ; `threeCopies`, que lisent les cas de `mergeCards`, reste.

In `lib/ui/widgets/forge/forge_slot_row.dart`, replace:

```dart
/// La ligne d'une rune, commune aux écrans qui en proposent une — le choix
/// de la fusion, l'affûtage du feu (spec P-43 E2, §4.5) : l'icône et la
/// couleur de la rune, un titre, sa description, et un bouton dont l'écran
/// donne le libellé et l'état.
```

with:

```dart
/// La ligne d'une rune, commune aux écrans qui en proposent une — le choix
/// de la fusion, l'affûtage du feu, l'échange au Puits (spec P-43 E2,
/// §4.5) : l'icône et la couleur de la rune, un titre, sa description, et un
/// bouton dont l'écran donne le libellé et l'état.
```

- [ ] **Step 9: Lancer le test de l'écran pour le voir passer**

Run: `flutter test test/widget/forge_fusion_screen_test.dart test/unit/decoupled_forge_test.dart`
Expected: PASS — 7 cas pour l'écran.

- [ ] **Step 10: Le placement, tous les trois actes — test**

Create `test/unit/map_content_placer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/services/map_generator_service.dart';

/// Le placement du Puits d'échange (D22 ; spec P-43 E2, §4.8), sur le modèle
/// de `relic_exchange_test.dart` : la carte réelle, tirée plusieurs fois.
void main() {
  test('aux actes 3, 6 et 9 : un Puits, etage 3 a 7, ancien combat ou '
      'evenement', () {
    for (final act in const [3, 6, 9]) {
      for (var trial = 0; trial < 10; trial++) {
        final wells = MapGeneratorService.generateMap(act: act)
            .where((n) => n.type == MapNodeType.forgeFusion)
            .toList();
        expect(wells, hasLength(1), reason: 'acte $act');
        final well = wells.single;
        expect(well.floor, inInclusiveRange(3, 7), reason: 'acte $act');
        expect(well.originalType, isIn([MapNodeType.combat, MapNodeType.event]),
            reason: 'acte $act');
      }
    }
  });

  test('aux actes 1, 2, 4, 5 et 7 : aucun Puits', () {
    for (final act in const [1, 2, 4, 5, 7]) {
      for (var trial = 0; trial < 10; trial++) {
        expect(
          MapGeneratorService.generateMap(act: act)
              .where((n) => n.type == MapNodeType.forgeFusion),
          isEmpty,
          reason: 'acte $act',
        );
      }
    }
  });
}
```

Run: `flutter test test/unit/map_content_placer_test.dart`
Expected: FAIL — à 25 % par acte, l'acte 3 manque son Puits les trois quarts du temps, et les actes 1, 2, 4… en reçoivent un.

- [ ] **Step 11: Le placement — code**

In `lib/services/map/map_content_placer.dart`, replace:

```dart
    // 25% chance to place a forgeFusion node on floors 3 to 7
    if (random.nextDouble() < 0.25) {
```

with:

```dart
    // Le Puits d'échange, garanti tous les trois actes (D22 ; spec P-43 E2,
    // §4.8), sur un combat ou un événement des étages 3 à 7. Le nœud garde
    // son type `forgeFusion` (A17).
    if (act % 3 == 0) {
```

L'Autel est placé avant (`:10-21`) : un nœud devenu Autel n'est plus un combat ni un événement, il n'est plus candidat — rien à écrire.

Run: `flutter test test/unit/map_content_placer_test.dart test/unit/relic_exchange_test.dart`
Expected: PASS.

- [ ] **Step 12: La carte du monde et le tutoriel nomment le Puits**

In `lib/ui/widgets/map/map_node_widget.dart`, replace:

```dart
      case MapNodeType.forgeFusion:
        final isFr = Localizations.localeOf(context).languageCode == 'fr';
        return (
          isFr ? "Forge de Fusion" : "Fusion Forge",
          isFr
              ? "Fusionnez des runes identiques sur vos cartes contre de l'or pour cumuler leurs effets."
              : "Merge identical runes on your cards for gold to combine their effects."
        );
```

with:

```dart
      case MapNodeType.forgeFusion:
        return (l10n.wellName, l10n.wellDesc);
```

In `lib/ui/widgets/map/map_legend.dart`, replace:

```dart
            label: Localizations.localeOf(context).languageCode == 'fr'
                ? "Forge de Fusion"
                : "Fusion Forge",
```

with:

```dart
            label: l10n.wellName,
```

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        '• 🧩 Fusion Forge: merge a card\'s duplicate upgrades, for gold.\n'
```

with:

```dart
        '• 🧩 Exchange Well: swap one of a card\'s runes for another, for '
        'gold — every third act.\n'
```

Then replace:

```dart
        '• 🧩 Forge de Fusion : fusionner les améliorations dupliquées d\'une '
        'carte, contre de l\'or.\n'
```

with:

```dart
        '• 🧩 Puits d\'échange : échanger une rune d\'une carte contre une '
        'autre, contre de l\'or — tous les trois actes.\n'
```

Then replace:

```dart
        '**The Fusion Forge is a separate, paid system** — a dedicated map '
```

with:

```dart
        '**The Exchange Well is a separate, paid system** — a dedicated map '
```

Then replace:

```dart
        'classe sont uniques, et une carte unique ne fusionne jamais. **La '
        'Forge de Fusion est un système distinct et payant** — un nœud dédié '
```

with:

```dart
        'classe sont uniques, et une carte unique ne fusionne jamais. **Le '
        'Puits d\'échange est un système distinct et payant** — un nœud dédié '
```

In `lib/tutorial/widgets/tutorial_node_types_widget.dart`, replace:

```dart
      titleEn: 'Fusion Forge',
      titleFr: 'Forge de Fusion',
      descEn: 'Merge duplicate upgrades, for gold.',
      descFr: 'Fusionne les améliorations dupliquées, contre de l\'or.',
```

with:

```dart
      titleEn: 'Exchange Well',
      titleFr: 'Puits d\'échange',
      descEn: 'Swap a rune for another, for gold.',
      descFr: 'Échangez une rune contre une autre, contre de l\'or.',
```

Aucun test ne lit ces textes (re-mesuré : `git grep` de « Forge de Fusion », « Fusion Forge » et « distinct et payant » sous `test/` ne rend rien).

- [ ] **Step 13: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e fusionOptionsFor -e FusionOption -e 'Forge de Fusion' -e 'Fusion Forge' -e 'FORGE DE FUSION' -e 'FUSION FORGE' -- lib test`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1435: All tests passed!` (1426 + 21 − 12).

- [ ] **Step 14: Commit**

```bash
git add lib/game/services/forge_rune_rules.dart lib/game/controllers/run/gold_manager.dart lib/game/controllers/run_controller.dart lib/ui/screens/forge_fusion_screen.dart lib/services/map/map_content_placer.dart lib/ui/widgets/map/map_node_widget.dart lib/ui/widgets/map/map_legend.dart lib/ui/widgets/forge/forge_slot_row.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_node_types_widget.dart test/unit/forge_rune_rules_test.dart test/unit/run_controller_test.dart test/widget/forge_fusion_screen_test.dart test/unit/map_content_placer_test.dart test/unit/decoupled_forge_test.dart
git commit -F - <<'EOF'
feat(puits): le Puits d echange remplace la Forge de Fusion, tous les trois actes

Une rune d une carte contre toute autre que le predicat lui permet, jugee
sans la rune donnee, aux deux tiers de son niveau, pour 50 or par niveau
donne ; un echange par visite, et apres lui le retour systeme resout le
noeud. GoldManager.exchangeRune paie et ecrit, ou rien ; FusionOption et
fusionOptionsFor disparaissent. La carte du monde et le tutoriel nomment
le Puits. sharpenRune gagne les tests de ses refus.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 2: Les pré-forgées de la boutique tirent leurs runes comme la fusion

Chaque rune d'une pré-forgée vient de `ForgeRuneRules.drawRunes(instance, catalog, rng, count: 1)` — le prédicat au rang de la carte, pondéré par `weight`, sur la carte avec les runes déjà tirées (spec §4.9, A12) ; son niveau reste tiré 80 · 15 · 5 %, puis borné par le plafond de la rune, sans `isStackable`. Le ciblage par `pools` et ses trois aides (`_getEligibleUpgradesForPool`, `_rollUpgradeId`, `_rollWeighted`) disparaissent : la boutique n'est plus un lecteur ni de `pools` ni de `isStackable` (§4.11). S6 : le test des pré-forgées gagne la garde « au moins une carte de rang ≥ 2 a été tirée ».

Changement de jeu de la tâche, voulu : une pré-forgée ne voit plus ses runes ciblées par sa rareté (65 % du pool commun pour une rare, etc.) : elle les tire parmi toutes celles qui lui sont permises, à leur poids, comme la fusion. Le nombre de runes (au plus `fusionRank`) et le prix ne changent pas.

**Files:**
- Modify: `lib/game/controllers/shop_controller.dart:6` (import de `forge_upgrade_data.dart`), `:50-155` (le tirage)
- Test: `test/unit/shop_controller_test.dart:479-501` (la garde), `:504-551` (supprimé, remplacé)

**Interfaces:**
- Consumes: `ForgeRuneRules.drawRunes(CardInstance card, Iterable<ForgeUpgradeData> catalog, Random rng, {required int count})` (partie 1) ; `ForgeUpgradeData.boundLevel`.
- Produces: rien de neuf ; `_rollRandomUpgrade(CardInstance card, Random rng)` garde sa signature, et `_generateShopCardInstance` ne change pas.

- [ ] **Step 1: Écrire le test qui échoue**

In `test/unit/shop_controller_test.dart`, delete the test `la boutique ne tire une rune non cumulable qu au tier 1` (`:504-551`) — from `    test('la boutique ne tire une rune non cumulable qu au tier 1', () {` up to and including the blank line before `    group('filtre de classe sur le pool de boutique', () {` — and put in its place:

```dart
    // Le tirage de la fusion, sans ciblage par rarete (D68 ; spec P-43 E2,
    // A12, §4.9) : une peu commune recoit l'une ou l'autre rune.
    test('une pre-forgee tire parmi toutes les runes eligibles, a leur poids',
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
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [
          ForgeUpgradeData(
            id: 'alpha',
            nameEn: 'Alpha',
            nameFr: 'Alpha',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['rare'],
          ),
          ForgeUpgradeData(
            id: 'beta',
            nameEn: 'Beta',
            nameFr: 'Beta',
            descriptionEn: '',
            descriptionFr: '',
            icon: '',
            color: '',
            pools: ['common'],
          ),
        ],
      );
      runController.updateState(container.read(runProvider).copyWith(act: 3));

      final onUncommon = <String>{};
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(testCardPool, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.rarity != CardRarity.uncommon) continue;
          onUncommon.addAll([
            for (final ref in card.forgeUpgrades)
              ForgeUpgradeData.parseRef(ref)!.$1,
          ]);
        }
      }

      expect(onUncommon, {'alpha', 'beta'});
    });

```

Le cas supprimé gardait la lecture de `isStackable` par la boutique, que cette tâche retire ; réécrit « plafond 1 » (`steadfast` à `maxLevel: 1`), il serait la copie exacte du cas `une rune plafonnee n est jamais tiree au-dessus de son plafond` (`:344-389`), qui garde déjà le plafond 1. Les `pools:` du cas neuf partent en Task 4, avec le paramètre.

Then, in the test `une pre-forgee porte au plus fusionRank runes, distinctes, et jamais Econome ni Veloce sous la rare`, replace:

```dart
      var runed = 0;
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          final ids = [
```

with:

```dart
      var runed = 0;
      var rareOrAbove = 0;
      for (var i = 0; i < 300; i++) {
        shopController.initializeShop(cards, 0);
        for (final card in shopController.state.cardsForSale) {
          if (card.rarity.fusionRank >= 2) rareOrAbove++;
          final ids = [
```

and replace:

```dart
      // Garde contre un test qui passerait a vide.
      expect(runed, greaterThan(0));
    });
```

with:

```dart
      // Gardes contre un test qui passerait a vide : des cartes runees, et
      // des cartes de rang 2 au moins, ou la borne et Econome s'eprouvent.
      expect(runed, greaterThan(0));
      expect(rareOrAbove, greaterThan(0));
    });
```

(Le texte « Garde contre un test qui passerait a vide. » suivi de `expect(runed, greaterThan(0));` n'apparaît qu'une fois ; le premier cas des pré-forgées dit « Garde contre un test qui passerait à vide. », avec un accent, et garde `checked`.)

- [ ] **Step 2: Lancer le test pour le voir échouer**

Run: `flutter test test/unit/shop_controller_test.dart --plain-name "toutes les runes eligibles"`
Expected: FAIL — `Expected: Set:['alpha', 'beta']  Actual: Set:['beta']` : le ciblage d'aujourd'hui donne le pool commun à une peu commune, puis se replie sur lui.

- [ ] **Step 3: Tirer par `drawRunes`**

In `lib/game/controllers/shop_controller.dart`, delete the import:

```dart
import '../../models/data/forge_upgrade_data.dart';
```

Then replace the whole block from the comment `  /// Les runes éligibles du pool [poolName] pour [card], hors celles déjà` (`:50`) up to and including the closing `  }` of `_rollRandomUpgrade` (`:155`) — `_getEligibleUpgradesForPool`, `_rollUpgradeId`, `_rollWeighted` et `_rollRandomUpgrade` — with:

```dart
  /// Tire une rune pour [card], qui porte déjà les runes tirées avant elle :
  /// une parmi celles que le prédicat accepte au rang de la carte, pondérées
  /// par `weight` — le tirage de la fusion (spec P-43 E2, A12, §4.9). `null`
  /// s'il ne lui en reste aucune : la carte en reçoit une de moins. Son niveau
  /// est tiré 80 · 15 · 5 %, puis borné par le plafond de la rune (D72) ; la
  /// carte n'en porte aucun niveau, le prédicat refusant une rune portée.
  String? _rollRandomUpgrade(CardInstance card, Random rng) {
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final drawn = ForgeRuneRules.drawRunes(card, catalog, rng, count: 1);
    if (drawn.isEmpty) return null;
    final rune = catalog.firstWhere((r) => r.id == drawn.single);
    final roll = rng.nextInt(100);
    final tier = roll < 80 ? 1 : (roll < 95 ? 2 : 3);
    return '${rune.id}:${rune.boundLevel(tier)}';
  }
```

La ligne vide qui précède `  /// Helper pour tirer la rareté finale d'une carte selon l'acte` reste.

- [ ] **Step 4: Lancer les tests de la boutique**

Run: `flutter test test/unit/shop_controller_test.dart`
Expected: PASS — 19 cas, dont `une rune plafonnee n est jamais tiree au-dessus de son plafond` (`{'capped:1'}`) et la Concentration pré-forgée qui ne porte que Véloce.

- [ ] **Step 5: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e "isStackable(" -e "pools" -- lib/game/controllers/shop_controller.dart`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1435: All tests passed!` (1435 + 1 − 1).

- [ ] **Step 6: Commit**

```bash
git add lib/game/controllers/shop_controller.dart test/unit/shop_controller_test.dart
git commit -F - <<'EOF'
feat(boutique): les pre-forgees tirent leurs runes comme la fusion

Chaque rune vient de drawRunes, au rang de la carte, pesee par weight ;
le niveau reste tire 80, 15, 5 pour cent puis borne par le plafond. Le
ciblage par pools et la lecture de isStackable quittent la boutique. Le
test des pre-forgees garde aussi le passage par une carte de rang 2.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 3: La boutique vend la copie du deck, et retient son étal à son nœud

La boutique montre une carte de plus, à part : la copie d'une carte tirée uniformément dans `DeckState.copyableCards`, même rareté, sans ses runes, identifiant neuf, au prix d'une carte de sa rareté (D46, A11) ; la relance de l'étal ne la touche pas. **L'étal entier** — cartes en vente, copie, soin acheté, options et prix du Miroir — est tiré une fois par nœud de boutique (`ShopState.nodeId`) et retenu, achats compris, jusqu'à ce que le nœud courant de la run change (décision du propriétaire ; 2 bis, 2 ter, 2 quater) : un écouteur `ref.listen` sur `currentNodeId` remet l'état à `const ShopState()`. Sans nœud courant, chaque appel tire. `clearCloneOptions` et le `PopScope` de `ShopScreen`, qui ne servait qu'à l'appeler, disparaissent : le Miroir repart avec l'étal, au nœud suivant (point 5 d'ADR-067, amendé à `memory-bank-sync`). La prose de la boutique dit la copie (§5.5).

Changements de jeu de la tâche, voulus : la copie du deck s'achète en boutique ; sortir de la boutique par le retour puis y revenir rend le même étal, la même copie, les mêmes options du Miroir à leur prix — ce qui a été acheté reste acheté. On ne peut plus retirer l'étal gratuitement.

**Files:**
- Modify: `lib/models/shop_state.dart:3-30`
- Modify: `lib/game/controllers/shop_controller.dart:14-17` (`build`), `:229-254` (`initializeShop`), `:364-375` (`clearCloneOptions`)
- Modify: `lib/game/controllers/deck_controller.dart:49-53` (le commentaire de `copyableCards`)
- Modify: `lib/ui/screens/shop_screen.dart:287-483` (la méthode `build`, remplacée ; `_buyDeckCopy` avant elle)
- Modify: `lib/l10n/app_en.arb:431` ; `lib/l10n/app_fr.arb:178` ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Modify: `lib/tutorial/tutorial_data.dart:76-77`, `:90-91` ; `lib/tutorial/widgets/tutorial_node_types_widget.dart:53-56`
- Test: `test/unit/shop_controller_test.dart:251-282` (le Miroir), avant `:553` (deux groupes neufs)
- Test: `test/widget/shop_screen_test.dart:212-313` (le Miroir), à la fin (deux cas neufs)

**Interfaces:**
- Consumes: `DeckState.copyableCards` ; `ShopController.getCardPrice` ; `RunState.currentNodeId`, `RunController.travelToNode`, `advanceToNextWorld`, `startNewRun`, `hydrate`.
- Produces:
  - `final CardInstance? ShopState.deckCopy`, `final String? ShopState.nodeId` ; `ShopState.copyWith({…, bool removeDeckCopy = false})` ;
  - `bool ShopController.buyDeckCopy()` ;
  - `ShopController.initializeShop(List<CardData> allCards, int bonusShopCards)` — signature inchangée, retient l'étal du nœud courant ;
  - `ShopController.clearCloneOptions()` supprimé ;
  - les clés ARB `shopDeckCopy`, `shopDeckCopyDesc`.

- [ ] **Step 1: Écrire les tests du contrôleur**

In `test/unit/shop_controller_test.dart`, replace:

```dart
    test('cloneCard price doubles on subsequent purchases and resets on clearCloneOptions', () {
```

with:

```dart
    test('cloneCard price doubles on subsequent purchases and resets at the next node', () {
```

Then replace:

```dart
      // Réinitialisation de la boutique (sortie du shop)
      shopController.clearCloneOptions();
      expect(shopController.state.clonePrice, 150);
```

with:

```dart
      // Le Miroir repart avec l'etal, au noeud suivant (spec P-43 E2, A11).
      runController.travelToNode('node_suivant');
      expect(shopController.state.clonePrice, 150);
```

Then, just before the line `    group('filtre de classe sur le pool de boutique', () {`, insert:

```dart
    // La copie du deck (D46 ; spec P-43 E2, A11, §4.9).
    group('la copie du deck', () {
      const signature = CardData(
        id: 'signature_paladin',
        cost: 1,
        type: CardType.skill,
        category: CardCategory.characterSpecific,
        heroClass: 'paladin',
        rarity: CardRarity.unique,
        target: CardTarget.self,
        effects: [],
      );

      test('tiree des cartes copiables du deck : meme rarete, sans rune, '
          'identifiant neuf', () {
        final source = CardInstance(
          data: testCardPool[0],
          rarity: CardRarity.rare,
          forgeUpgrades: const ['sharp:2'],
        );
        deckNotifier.initializeStarterDeck(
            [source, CardInstance(data: signature)]);

        for (var i = 0; i < 50; i++) {
          shopController.initializeShop(testCardPool, 0);
          final copy = shopController.state.deckCopy!;
          expect(copy.data.id, source.data.id);
          expect(copy.rarity, CardRarity.rare);
          expect(copy.forgeUpgrades, isEmpty);
          expect(copy.uniqueId, isNot(source.uniqueId));
        }
      });

      test('sans carte copiable, pas de copie', () {
        shopController.initializeShop(testCardPool, 0);
        expect(shopController.state.deckCopy, isNull);

        deckNotifier.initializeStarterDeck([CardInstance(data: signature)]);
        shopController.initializeShop(testCardPool, 0);
        expect(shopController.state.deckCopy, isNull);
      });

      test('au prix d une carte de sa rarete : 25, 50, 100, 150, 200', () {
        final prices = <int>[];
        for (final rarity in const [
          CardRarity.common,
          CardRarity.uncommon,
          CardRarity.rare,
          CardRarity.epic,
          CardRarity.legendary,
        ]) {
          deckNotifier.initializeStarterDeck([
            CardInstance(
              data: testCardPool[0],
              rarity: rarity,
              forgeUpgrades: const ['sharp:1'],
            ),
          ]);
          shopController.initializeShop(testCardPool, 0);
          prices.add(
              ShopController.getCardPrice(shopController.state.deckCopy!));
        }
        expect(prices, [25, 50, 100, 150, 200]);
      });

      test('buyDeckCopy depense son prix, l ajoute au deck et la retire de '
          'l etal', () {
        deckNotifier.initializeStarterDeck(
            [CardInstance(data: testCardPool[0], rarity: CardRarity.rare)]);
        shopController.initializeShop(testCardPool, 0);
        final copy = shopController.state.deckCopy!;

        // 100 or : le prix d'une rare, tout juste.
        expect(shopController.buyDeckCopy(), isTrue);

        expect(inventoryController.state.gold, 0);
        expect(deckNotifier.state.masterDeck.map((c) => c.uniqueId),
            contains(copy.uniqueId));
        expect(shopController.state.deckCopy, isNull);
        expect(shopController.buyDeckCopy(), isFalse);
      });

      test('buyDeckCopy refuse faute d or, sans rien toucher', () {
        deckNotifier.initializeStarterDeck(
            [CardInstance(data: testCardPool[0], rarity: CardRarity.epic)]);
        shopController.initializeShop(testCardPool, 0);
        final copy = shopController.state.deckCopy;

        // 150 or pour une epique, 100 en poche.
        expect(shopController.buyDeckCopy(), isFalse);

        expect(inventoryController.state.gold, 100);
        expect(deckNotifier.state.masterDeck, hasLength(1));
        expect(shopController.state.deckCopy, same(copy));
      });

      test('rerollCards garde la copie', () {
        deckNotifier.initializeStarterDeck([CardInstance(data: testCardPool[0])]);
        shopController.initializeShop(testCardPool, 0);
        final copy = shopController.state.deckCopy;

        expect(shopController.rerollCards(15, testCardPool, 0), isTrue);

        expect(shopController.state.deckCopy, same(copy));
      });
    });

    // L'etal entier, tire une fois par noeud de boutique et retenu, achats
    // compris, jusqu'a ce que le noeud courant change (spec P-43 E2, A11,
    // §4.9).
    group('l etal retenu a son noeud', () {
      setUp(() {
        deckNotifier.initializeStarterDeck([CardInstance(data: testCardPool[0])]);
        inventoryController.gainGold(1000);
        runController.travelToNode('node_3_1');
      });

      test('deux initializeShop au meme noeud rendent le meme etal, achats '
          'compris', () {
        shopController.initializeShop(testCardPool, 0);
        final bought = shopController.state.cardsForSale.first;
        shopController.buyCard(bought, ShopController.getCardPrice(bought));
        shopController.buyHeal(30, 30);
        shopController.buyDeckCopy();
        shopController.setCloneOptions([CardInstance(data: testCardPool[1])]);
        shopController.cloneCard(deckNotifier.state.masterDeck.first);
        final kept = shopController.state;

        shopController.initializeShop(testCardPool, 0);

        expect(shopController.state, same(kept));
        expect(kept.cardsForSale, isNot(contains(bought)));
        expect(kept.deckCopy, isNull);
        expect(kept.purchasedHeal, isTrue);
        expect(kept.cloneOptions, hasLength(1));
        expect(kept.clonePrice, 300);
      });

      test('une relance payante est retenue de meme', () {
        shopController.initializeShop(testCardPool, 0);
        final copy = shopController.state.deckCopy;
        shopController.rerollCards(15, testCardPool, 0);
        final rerolled = shopController.state.cardsForSale;

        shopController.initializeShop(testCardPool, 0);

        expect(shopController.state.cardsForSale, same(rerolled));
        expect(shopController.state.deckCopy, same(copy));
      });

      // Review Focus 3 : ce qui change le noeud courant de la run retire
      // l'etal, et la boutique se rappelle aussitot sans erreur.
      final departures = <String, void Function(RunController)>{
        'un autre noeud': (run) => run.travelToNode('node_4_2'),
        'un acte neuf': (run) => run.advanceToNextWorld(),
        'une run neuve': (run) => run.startNewRun(dummyHero),
        'une sauvegarde chargee sur un autre noeud': (run) => run
            .hydrate(run.currentState.copyWith(currentNodeId: 'node_7_0')),
      };
      for (final MapEntry(key: name, value: depart) in departures.entries) {
        test('$name retire l etal', () {
          shopController.initializeShop(testCardPool, 0);
          shopController.setCloneOptions([CardInstance(data: testCardPool[1])]);
          final first = shopController.state;

          depart(runController);

          expect(shopController.state.cardsForSale, isEmpty);
          expect(shopController.state.deckCopy, isNull);
          expect(shopController.state.cloneOptions, isEmpty);
          expect(shopController.state.nodeId, isNull);
          shopController.initializeShop(testCardPool, 0);
          expect(shopController.state, isNot(same(first)));
          expect(shopController.state.cardsForSale, isNotEmpty);
        });
      }

      test('sans noeud courant, chaque appel tire', () {
        runController.startNewRun(dummyHero);
        shopController.initializeShop(testCardPool, 0);
        final first = shopController.state;

        shopController.initializeShop(testCardPool, 0);

        expect(shopController.state, isNot(same(first)));
        expect(shopController.state.nodeId, isNull);
      });
    });

```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/shop_controller_test.dart`
Expected: FAIL à la compilation — `deckCopy`, `nodeId` et `buyDeckCopy` ne sont pas définis.

- [ ] **Step 3: L'étal retenu et la copie, dans le contrôleur**

In `lib/models/shop_state.dart`, replace:

```dart
class ShopState {
  final List<CardInstance> cardsForSale;
  final bool purchasedHeal;
  final List<CardInstance> cloneOptions;
  final int clonePurchasedCount;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
    this.cloneOptions = const [],
    this.clonePurchasedCount = 0,
  });

  int get clonePrice => 150 << clonePurchasedCount;

  ShopState copyWith({
    List<CardInstance>? cardsForSale,
    bool? purchasedHeal,
    List<CardInstance>? cloneOptions,
    int? clonePurchasedCount,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
      cloneOptions: cloneOptions ?? this.cloneOptions,
      clonePurchasedCount: clonePurchasedCount ?? this.clonePurchasedCount,
    );
  }
```

with:

```dart
/// L'étal de la boutique, tiré une fois par nœud de boutique et retenu,
/// achats compris, jusqu'à ce que le nœud courant de la run change (spec P-43
/// E2, A11, §4.9).
class ShopState {
  final List<CardInstance> cardsForSale;
  final bool purchasedHeal;
  final List<CardInstance> cloneOptions;
  final int clonePurchasedCount;

  /// La copie d'une carte du deck (D46) : même rareté, sans ses runes ;
  /// `null` si le deck n'a aucune carte copiable, ou une fois achetée.
  final CardInstance? deckCopy;

  /// Le nœud courant de la run pour lequel l'étal a été tiré ; `null` sans
  /// nœud courant.
  final String? nodeId;

  const ShopState({
    this.cardsForSale = const [],
    this.purchasedHeal = false,
    this.cloneOptions = const [],
    this.clonePurchasedCount = 0,
    this.deckCopy,
    this.nodeId,
  });

  int get clonePrice => 150 << clonePurchasedCount;

  /// [removeDeckCopy] retire la copie du deck de l'étal, une fois achetée.
  ShopState copyWith({
    List<CardInstance>? cardsForSale,
    bool? purchasedHeal,
    List<CardInstance>? cloneOptions,
    int? clonePurchasedCount,
    bool removeDeckCopy = false,
  }) {
    return ShopState(
      cardsForSale: cardsForSale ?? this.cardsForSale,
      purchasedHeal: purchasedHeal ?? this.purchasedHeal,
      cloneOptions: cloneOptions ?? this.cloneOptions,
      clonePurchasedCount: clonePurchasedCount ?? this.clonePurchasedCount,
      deckCopy: removeDeckCopy ? null : deckCopy,
      nodeId: nodeId,
    );
  }
```

`toJson` / `fromJson`, sans lecteur, ne changent pas (spec §3.4, §7).

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
class ShopController extends Notifier<ShopState> {
  @override
  ShopState build() {
    return const ShopState();
  }
```

with:

```dart
class ShopController extends Notifier<ShopState> {
  /// L'étal est oublié dès que le nœud courant de la run change — le départ
  /// vers un autre nœud, un acte, une run, une sauvegarde chargée ailleurs
  /// (spec P-43 E2, A11, §4.9). Rentrer dans le même nœud ne le change pas.
  /// Un écouteur, et non `ref.watch` : celui-ci laisserait le Notifier
  /// périmé entre le changement de nœud et la lecture suivante de `state`,
  /// et tout `ref.read` de ses méthodes y lèverait l'assertion de Riverpod.
  @override
  ShopState build() {
    ref.listen(
      runProvider.select((run) => run.currentNodeId),
      (previous, next) => state = const ShopState(),
    );
    return const ShopState();
  }
```

Then replace the whole `initializeShop` — from `  /// Initialise la boutique avec une sélection aléatoire de cartes de jeu` up to and including its closing `  }`, just before `  /// Achète une carte spécifique de la boutique` — with:

```dart
  /// Tire l'étal — les cartes en vente et la copie d'une carte du deck — pour
  /// le nœud courant de la run, et le note (spec P-43 E2, A11, §4.9). Un
  /// étal déjà tiré pour ce nœud est retenu tel quel, achats compris :
  /// sortir puis revenir ne le retire pas. Sans nœud courant, chaque appel
  /// tire.
  void initializeShop(List<CardData> allCards, int bonusShopCards) {
    final nodeId = ref.read(runProvider).currentNodeId;
    if (nodeId != null && state.nodeId == nodeId) return;

    final rng = Random();
    final eligibleCards = _getEligibleCards(allCards)..shuffle(rng);
    final count = min(eligibleCards.length, 3 + bonusShopCards);
    final int act = ref.read(runProvider).act;

    state = ShopState(
      cardsForSale: [
        for (final cardData in eligibleCards.take(count))
          _generateShopCardInstance(cardData, act, rng),
      ],
      deckCopy: _drawDeckCopy(rng),
      nodeId: nodeId,
    );
  }

  /// La copie d'une carte tirée uniformément parmi les cartes copiables du
  /// deck (D46 ; ADR-094 D2) : même rareté, sans ses runes, identifiant neuf ;
  /// `null` si le deck n'en a aucune (ADR-101 D4).
  CardInstance? _drawDeckCopy(Random rng) {
    final copyable = ref.read(deckProvider).copyableCards;
    if (copyable.isEmpty) return null;
    final source = copyable[rng.nextInt(copyable.length)];
    return CardInstance(data: source.data, rarity: source.rarity);
  }

  /// Achète la copie du deck, au prix d'une carte de sa rareté (spec P-43
  /// E2, A11) : elle rejoint le deck et quitte l'étal. Faux sans copie ou
  /// faute d'or, sans rien toucher.
  bool buyDeckCopy() {
    final copy = state.deckCopy;
    if (copy == null ||
        !ref.read(inventoryProvider.notifier).spendGold(getCardPrice(copy))) {
      return false;
    }
    ref.read(deckProvider.notifier).addCardToMasterDeck(copy);
    state = state.copyWith(removeDeckCopy: true);
    return true;
  }
```

`_getEligibleCards` rend une liste neuve : la mélanger en place ne touche rien. Une liste éligible vide donne un étal sans carte, comme aujourd'hui, et la copie reste tirée.

In `lib/game/controllers/deck_controller.dart`, replace:

```dart
  /// Cartes du master deck qu'une récompense peut copier : draft de boss,
  /// Miroir Magique, Miroir de montée de niveau.
  ///
  /// Liste neuve et modifiable à chaque appel : les trois appelants la
  /// mélangent en place sans toucher à l'état.
```

with:

```dart
  /// Cartes du master deck qu'une récompense peut copier : draft de boss,
  /// Miroir Magique, Miroir de montée de niveau, copie du deck en boutique.
  ///
  /// Liste neuve et modifiable à chaque appel : ses appelants la mélangent ou
  /// y tirent sans toucher à l'état.
```

- [ ] **Step 4: Lancer les tests du contrôleur pour les voir passer**

Run: `flutter test test/unit/shop_controller_test.dart`
Expected: PASS — 32 cas (19 + 13).

- [ ] **Step 5: Écrire les tests de l'écran**

In `test/widget/shop_screen_test.dart`, replace:

```dart
    'ShopScreen Magic Mirror clones/caches options and clears them on deactivate',
```

with:

```dart
    'ShopScreen Magic Mirror clones/caches options and clears them at the next node',
```

Then replace:

```dart
      // Verify cloneOptions is cleared upon ShopScreen deactivation
      expect(container.read(shopProvider).cloneOptions, isEmpty);
```

with:

```dart
      // Le Miroir repart avec l'etal, au noeud suivant (spec P-43 E2, A11) :
      // la sortie ne vide rien.
      expect(container.read(shopProvider).cloneOptions, equals(options1));
      runNotifier.travelToNode('node_suivant');
      expect(container.read(shopProvider).cloneOptions, isEmpty);
```

Then, at the end of the file (the end of `Le Miroir Magique ne propose jamais de copier une carte unique`), replace:

```dart
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
```

with:

```dart
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
    },
  );

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

  /// Une run neuve, au premier nœud de sa carte, avec une Frappe pour deck
  /// et 1000 or.
  ProviderContainer startRun(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [gameDataLoaderProvider.overrideWith((ref) => mockRegistry)],
    );
    addTearDown(container.dispose);
    final run = container.read(runProvider.notifier);
    run.startNewRun(mockHero);
    run.travelToNode(container.read(runProvider).mapNodes.first.id);
    container.read(inventoryProvider.notifier).reset(initialGold: 1000);
    container
        .read(deckProvider.notifier)
        .addCardToMasterDeck(CardInstance(data: mockCards[0]));
    return container;
  }

  // D46 ; spec P-43 E2, A11, §4.9.
  testWidgets('la copie du deck se montre a part, sous COPIE DE VOTRE DECK, '
      'et s achete au prix de sa rarete', (WidgetTester tester) async {
    final container = startRun(tester);
    await tester.pumpWidget(app(container, const Scaffold(body: ShopScreen())));
    await tester.pumpAndSettle();

    expect(find.text('COPIE DE VOTRE DECK'), findsOneWidget);
    expect(find.text('Même rareté, sans ses runes.'), findsOneWidget);
    // Les trois cartes en vente, puis la copie.
    expect(find.byType(UiCard), findsNWidgets(4));

    await tester.ensureVisible(find.byType(UiCard).last);
    await tester.tap(find.byType(UiCard).last);
    await tester.pumpAndSettle();

    expect(container.read(deckProvider).masterDeck, hasLength(2));
    expect(container.read(inventoryProvider).gold, 1000 - 25);
    expect(find.text('COPIE DE VOTRE DECK'), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
  });

  // Decide par le proprietaire le 02/10/2026 (spec P-43 E2, A11) : l'etal
  // entier est retenu a son noeud.
  testWidgets('sortir par le retour puis revenir garde le meme etal et la '
      'meme copie', (WidgetTester tester) async {
    final container = startRun(tester);
    await tester.pumpWidget(app(
      container,
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShopScreen()),
            ),
            child: const Text('Ouvrir la boutique'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Ouvrir la boutique'));
    await tester.pumpAndSettle();

    // Le Miroir tire ses options, puis un clone double son prix.
    await tester.tap(find.text('Miroir Magique'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(
      container
          .read(shopProvider.notifier)
          .cloneCard(container.read(deckProvider).masterDeck.first),
      isTrue,
    );
    final before = container.read(shopProvider);

    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(ShopScreen), findsNothing);
    final run = container.read(runProvider);
    expect(
      run.mapNodes.singleWhere((n) => n.id == run.currentNodeId).isCompleted,
      isFalse,
    );

    await tester.tap(find.text('Ouvrir la boutique'));
    await tester.pumpAndSettle();

    final after = container.read(shopProvider);
    expect(after, same(before));
    expect(after.deckCopy, isNotNull);
    expect(after.cloneOptions, isNotEmpty);
    expect(after.clonePrice, 300);
    expect(find.text('COPIE DE VOTRE DECK'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
```

Le premier cas du fichier (`ShopScreen shows correct cards…`) compte trois puis quatre `UiCard` : son deck est vide, aucune copie ne s'y ajoute.

- [ ] **Step 6: Lancer les tests de l'écran pour les voir échouer**

Run: `flutter test test/widget/shop_screen_test.dart`
Expected: FAIL — l'écran ne montre pas la copie, et le `PopScope` vide encore le Miroir.

- [ ] **Step 7: Les chaînes de la copie**

In `lib/l10n/app_en.arb`, replace:

```json
  "shopCloneDesc": "Clone a card from your deck",
```

with:

```json
  "shopCloneDesc": "Clone a card from your deck",
  "shopDeckCopy": "COPY FROM YOUR DECK",
  "shopDeckCopyDesc": "Same rarity, without its runes.",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "shopCloneDesc": "Clone une carte de votre deck",
```

with:

```json
  "shopCloneDesc": "Clone une carte de votre deck",
  "shopDeckCopy": "COPIE DE VOTRE DECK",
  "shopDeckCopyDesc": "Même rareté, sans ses runes.",
```

Run: `flutter gen-l10n`

- [ ] **Step 8: L'écran — la copie à part, plus de `PopScope`**

In `lib/ui/screens/shop_screen.dart`, replace the whole `build` method — from `  @override\n  Widget build(BuildContext context) {` (`:287-288`) up to and including the `  }` that closes it (`:483`), just before the final `}` of `_ShopScreenState` and `class _ShopServiceWidget extends StatefulWidget {` — with:

```dart
  void _buyDeckCopy(CardInstance copy) {
    if (ref.read(shopProvider.notifier).buyDeckCopy()) {
      final locale = Localizations.localeOf(context).languageCode;
      context.showNotification(
        AppLocalizations.of(context)!.purchased(copy.data.getName(locale)),
        type: NotificationType.success,
      );
    } else {
      context.showNotification(
        AppLocalizations.of(context)!.notEnoughGold,
        type: NotificationType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final runState = ref.watch(runProvider);
    final inventoryState = ref.watch(inventoryProvider);
    final shopState = ref.watch(shopProvider);
    final int healPrice = 30;
    final int healAmount = (runState.heroStats.maxPv * 0.3).round();
    final l10n = AppLocalizations.of(context)!;
    // L'état vide d'aujourd'hui, centré dans la zone des cartes ; au-dessus
    // d'une copie du deck encore en vente, centré en tête de la zone.
    final emptyStock = Center(
      child: Text(
        l10n.noCardsInStock,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 18,
        ),
      ),
    );

    final appBar = PageHeader(
      title: l10n.shop,
      showBackButton: false,
      isParchment: false,
      actions: const [
        GoldIndicator(isParchment: false),
      ],
    );

    // Le retour système quitte la boutique sans résoudre le nœud ni rien
    // vider : l'étal reste celui du nœud, achats compris, jusqu'au départ
    // vers un autre (spec P-43 E2, A11, §4.9).
    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: appBar,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main Section (75%) - Cards for Sale, then the copy of the deck
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.cardsForSale,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: shopState.cardsForSale.isEmpty &&
                            shopState.deckCopy == null
                        ? emptyStock
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (shopState.cardsForSale.isEmpty)
                                  emptyStock
                                else
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 20,
                                    children:
                                        shopState.cardsForSale.map((card) {
                                      final int price =
                                          ShopController.getCardPrice(card);
                                      return SizedBox(
                                        width: 150,
                                        child: _ShopCardItem(
                                          card: card,
                                          price: price,
                                          onPressed: () =>
                                              _buyCard(card, price),
                                          canAfford:
                                              inventoryState.gold >= price,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                // La copie d'une carte du deck, à part des
                                // cartes en vente (D46 ; spec P-43 E2, A11).
                                if (shopState.deckCopy case final copy?) ...[
                                  const SizedBox(height: 28),
                                  Text(
                                    l10n.shopDeckCopy,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.shopDeckCopyDesc,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 150,
                                    child: _ShopCardItem(
                                      card: copy,
                                      price: ShopController.getCardPrice(copy),
                                      onPressed: () => _buyDeckCopy(copy),
                                      canAfford: inventoryState.gold >=
                                          ShopController.getCardPrice(copy),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: Colors.white24, width: 40),
            // Sidebar Section (25%) - Services
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.services,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          _ShopServiceWidget(
                            icon: Icons.refresh,
                            iconColor: Colors.tealAccent,
                            title: l10n.shopReroll,
                            description: l10n.shopRerollDesc,
                            price: 15,
                            onPressed: inventoryState.gold >= 15
                                ? () => _rerollCards(15)
                                : null,
                            buttonColor: Colors.teal.shade800,
                            canAfford: inventoryState.gold >= 15,
                          ),
                          _ShopServiceWidget(
                            icon: Icons.local_hospital,
                            iconColor: Colors.greenAccent,
                            title: l10n.healingPotion,
                            description: l10n.restoresHp(healAmount),
                            price: healPrice,
                            onPressed: shopState.purchasedHeal ||
                                    inventoryState.gold < healPrice
                                ? null
                                : () => _buyHeal(healPrice, healAmount),
                            buttonColor: Colors.green.shade800,
                            canAfford: inventoryState.gold >= healPrice &&
                                !shopState.purchasedHeal,
                          ),
                          _ShopServiceWidget(
                            icon: Icons.delete_forever,
                            iconColor: Colors.redAccent,
                            title: l10n.shopPurge,
                            description: l10n.shopPurgeDesc,
                            price: 75,
                            onPressed: inventoryState.gold >= 75
                                ? () => _showRemovalModal(75)
                                : null,
                            buttonColor: Colors.red.shade800,
                            canAfford: inventoryState.gold >= 75,
                          ),
                          _ShopServiceWidget(
                            icon: Icons.add_shopping_cart,
                            iconColor: Colors.amberAccent,
                            title: l10n.shopExpand,
                            description: l10n.shopExpandDesc,
                            price: 100,
                            onPressed: inventoryState.gold >= 100
                                ? () => _expandShop(100)
                                : null,
                            buttonColor: Colors.amber.shade800,
                            canAfford: inventoryState.gold >= 100,
                          ),
                          _ShopServiceWidget(
                            icon: Icons.content_copy,
                            iconColor: Colors.blueAccent,
                            title: l10n.shopClone,
                            description: l10n.shopCloneDesc,
                            price: shopState.clonePrice,
                            onPressed:
                                inventoryState.gold >= shopState.clonePrice
                                    ? () => _showCloneModal()
                                    : null,
                            buttonColor: Colors.blue.shade800,
                            canAfford:
                                inventoryState.gold >= shopState.clonePrice,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GameButton(
                    text: l10n.leaveShop,
                    onPressed: () {
                      ref.read(runProvider.notifier).completeCurrentNode();
                      Navigator.of(context).pop();
                    },
                    baseColor: Colors.blueAccent,
                    height: 54,
                    fontSize: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
```

Ce qui change, hors de la réindentation qu'impose le `PopScope` retiré : le `PopScope` (`:307-313`) et son appel à `clearCloneOptions` disparaissent ; les cartes en vente et la copie partagent une même zone défilante, la copie sous `shopDeckCopy`. **L'état vide ne change pas d'aspect** : sans carte ni copie, son texte reste dans son `Center`, au milieu de la zone, comme aujourd'hui ; seule une copie encore en vente le fait passer, toujours centré, en tête de la zone défilante, au-dessus d'elle. Les services, le soin, la purge, l'agrandissement, le Miroir et « Quitter » ne changent pas.

In `lib/game/controllers/shop_controller.dart`, replace:

```dart
  /// Définit les options persistantes pour le clonage de cartes
  void setCloneOptions(List<CardInstance> options) {
    state = state.copyWith(cloneOptions: options);
  }

  /// Nettoie les options de clonage et réinitialise le coût du miroir à 0
  void clearCloneOptions() {
    state = state.copyWith(
      cloneOptions: const [],
      clonePurchasedCount: 0,
    );
  }
}
```

with:

```dart
  /// Définit les options persistantes pour le clonage de cartes
  void setCloneOptions(List<CardInstance> options) {
    state = state.copyWith(cloneOptions: options);
  }
}
```

- [ ] **Step 9: Lancer les tests de l'écran pour les voir passer**

Run: `flutter test test/widget/shop_screen_test.dart test/unit/shop_controller_test.dart`
Expected: PASS — 5 cas pour l'écran, 32 pour le contrôleur.

- [ ] **Step 10: La prose de la boutique**

In `lib/tutorial/tutorial_data.dart`, replace:

```dart
        '• 🏪 Shop: buy cards, reroll the stock, buy a potion, purge a card, '
        'expand the stock or clone a card. No relics.\n'
```

with:

```dart
        '• 🏪 Shop: buy cards, reroll the stock, buy a potion, purge a card, '
        'expand the stock, clone a card or buy a copy of one of yours. No '
        'relics.\n'
```

Then replace:

```dart
        'potion, purger une carte, agrandir le stock ou cloner. Aucune relique.\n'
```

with:

```dart
        'potion, purger une carte, agrandir le stock, cloner ou acheter la '
        'copie d\'une de vos cartes. Aucune relique.\n'
```

In `lib/tutorial/widgets/tutorial_node_types_widget.dart`, replace:

```dart
      descEn: 'Buy cards, reroll stock, purge a card. No relics.',
      descFr:
          'Achetez des cartes, relancez le stock, purgez-en une. Aucune '
          'relique.',
```

with:

```dart
      descEn: 'Buy cards or a copy of yours, reroll stock, purge a card. No '
          'relics.',
      descFr:
          'Achetez des cartes ou la copie d\'une des vôtres, relancez le '
          'stock, purgez-en une. Aucune relique.',
```

- [ ] **Step 11: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n clearCloneOptions -- lib test`
Expected: aucune sortie.

Run: `git grep -n PopScope -- lib/ui/screens/shop_screen.dart`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1450: All tests passed!` (1435 + 15).

- [ ] **Step 12: Commit**

```bash
git add lib/models/shop_state.dart lib/game/controllers/shop_controller.dart lib/game/controllers/deck_controller.dart lib/ui/screens/shop_screen.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_node_types_widget.dart test/unit/shop_controller_test.dart test/widget/shop_screen_test.dart
git commit -F - <<'EOF'
feat(boutique): la copie du deck, et l etal retenu a son noeud

La boutique vend la copie d une carte tiree dans le deck, meme rarete,
sans ses runes, au prix de sa rarete ; la relance ne la touche pas.
L etal entier, Miroir compris, est tire une fois par noeud de boutique et
retenu, achats compris, jusqu a ce que le noeud courant change : un
ecouteur sur currentNodeId le remet a zero. clearCloneOptions et le
PopScope de la boutique disparaissent.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 4: `pools` et `stackable` disparaissent, avec leurs derniers lecteurs

Après Tasks 1 et 2, `pools` n'est plus lu que par le modèle et l'éditeur ; `stackable` que par le modèle, `ForgeRuneRules.isStackable` et sa branche de `consolidate` (spec §4.11, §10). Les deux champs partent du modèle, des huit fichiers et du gabarit de l'éditeur, dont `requiredKeys` ne garde rien (§6) ; `isStackable` part avec sa branche : `boundLevel` donne déjà 1 à une rune de plafond 1 (§4.6). Les tests qui gardaient `stackable` se défont avec lui (n° 5 et 5 bis de la levée de l'arrêt) : le groupe `stackable` disparaît, les cas « non cumulable » deviennent des cas de plafond 1, leurs attentes inchangées, `enduring` y prenant `maxLevel: 1` ; le cas `legacy` devient « une rune absente du registre n'a pas de plafond ». Toute rune construite en Dart perd `pools:` ; les exemples de clé de liste de l'éditeur en prennent une autre. Deux tests neufs gardent l'absence des deux clés **sans les nommer**.

Aucun changement de jeu : `enduring`, seule rune non cumulable, a déjà `maxLevel: 1`. La simulation ne lit ni `pools` ni `stackable` (spec §9) ; aucun `weight` ni `eligibleCardTypes` ne bouge.

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart:18`, `:44-47`, `:70`, `:78`, `:95`, `:108`, `:219`, `:227`
- Modify: `lib/game/services/forge_rune_rules.dart` — la doc de la classe (écrite en Task 1), `:32-35` (`isStackable`), `:37-42` et `:51` (`consolidate`), `:104-106` (la doc du prédicat)
- Modify: `lib/services/content_editor/entity_descriptor.dart:330-335`, `:378`, `:385`
- Modify: `assets/data/forge_upgrades/{burning,eco,enduring,freezing,hardened,quick,sharp,shocking}.json` — le bloc `"pools"` (`:10-14` ou moins) ; `enduring.json:27` (`"stackable"`)
- Test: `test/unit/forge_upgrade_data_test.dart:11`, `:231`, après `:255` (cas neuf)
- Test: `test/unit/forge_upgrades_catalog_test.dart:1-56`, `:88`, `:98`, `:127`, `:132`, `:148-149`, avant `:209` (cas neuf)
- Test: `test/unit/forge_rune_rules_test.dart:12-32` (`_rune`), `:61`, `:68-96` (supprimé), `:99`, `:106`, `:113`, `:121`
- Test: `test/unit/real_bundle_load_test.dart:97-101`
- Test: `test/unit/decoupled_forge_test.dart:41`, `:55`, `:69`, `:82-84`, `:276`
- Test: `test/unit/effective_card_test.dart:39` ; `test/unit/rune_eligibility_test.dart:28` ; `test/unit/save_catalog_lookups_test.dart:111` ; `test/unit/deck_state_persistence_test.dart:52` ; `test/unit/shop_controller_test.dart:373` et les deux runes de Task 2 ; `test/widget/ui_card_rune_sockets_test.dart:112`, `:156`
- Test: `test/unit/content_editor/fixtures.dart:53` ; `entity_validator_test.dart:205-206`, `:595` ; `known_values_test.dart:52-59` ; `field_kind_test.dart:69` ; `entity_descriptor_test.dart:263`, `:270` ; `test/widget/content_editor/document_form_test.dart:84`

**Interfaces:**
- Consumes: `ForgeUpgradeData.boundLevel` ; `ForgeRuneRules._bounded`.
- Produces: `ForgeUpgradeData` sans `pools` ni `stackable` — le constructeur ne prend plus `pools:` (il était `required`) ni `stackable:` ; `ForgeRuneRules.isStackable` supprimé ; `consolidate(Iterable<String> runes)` inchangé en signature, sans branche.

- [ ] **Step 1: Écrire les deux tests qui gardent l'absence**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
      expect(ForgeUpgradeData.fromJson(rune.toJson()).minFusionRank, 2);
    });
  });
```

with:

```dart
      expect(ForgeUpgradeData.fromJson(rune.toJson()).minFusionRank, 2);
    });
  });

  // Spec P-43 E2, §4.11 : les cles que le modele ne lit plus ne s'ecrivent
  // plus.
  test('toJson n ecrit que les cles du modele', () {
    expect(ForgeUpgradeData.fromJson(_json()).toJson().keys.toSet(), {
      'id',
      'name_en',
      'name_fr',
      'description_en',
      'description_fr',
      'icon',
      'color',
      'minFusionRank',
      'requiresExhaust',
      'requiresMinCost',
      'maxLevel',
      'deltas',
      'weight',
      'emoji',
    });
  });
```

In `test/unit/forge_upgrades_catalog_test.dart`, replace:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
```

with:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
```

Then replace:

```dart
  test('la matrice couvre les 23 cartes livrees', () {
```

with:

```dart
  // Spec P-43 E2, §4.11 : une cle qu'aucun modele ne lit passerait le
  // chargement en silence, comme toute cle inconnue ; aucun fichier n'en
  // porte.
  test('chaque cle d un fichier de rune est lue par le modele', () {
    const read = {
      'id',
      'name_en',
      'name_fr',
      'description_en',
      'description_fr',
      'icon',
      'color',
      'minFusionRank',
      'eligibleCardTypes',
      'eligibleEffects',
      'excludesEffects',
      'requiresExhaust',
      'requiresMinCost',
      'excludesRunes',
      'maxLevel',
      'deltas',
      'weight',
      'emoji',
    };
    final offenders = [
      for (final file in Directory('assets/data/forge_upgrades').listSync())
        if (file is File && file.path.endsWith('.json'))
          for (final key in (jsonDecode(file.readAsStringSync())
                  as Map<String, dynamic>)
              .keys)
            if (!read.contains(key)) '${file.path} : $key',
    ];
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('la matrice couvre les 23 cartes livrees', () {
```

- [ ] **Step 2: Lancer les deux tests pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart --plain-name "toJson n ecrit que"`
Expected: FAIL — `toJson` écrit encore les deux clés.

Run: `flutter test test/unit/forge_upgrades_catalog_test.dart --plain-name "chaque cle d un fichier"`
Expected: FAIL — les huit fichiers portent la clé de pool, `enduring.json` aussi la clé de cumul.

- [ ] **Step 3: Retirer les deux champs du modèle, des règles, de l'éditeur et de la donnée**

In `lib/models/data/forge_upgrade_data.dart`:

1. Delete the line `  final List<String> pools;` (`:18`).
2. Delete:

```dart
  /// Une rune cumulable additionne ses tiers : deux `sharp:1` valent un
  /// `sharp:2`. Une rune non cumulable est binaire — `enduring` retire
  /// l'épuisement ou non — et n'a qu'un tier, 1 (voir `ForgeRuneRules`).
  final bool stackable;

```

3. In the constructor, delete the line `    required this.pools,` (`:70`) and the line `    this.stackable = true,` (`:78`).
4. In `fromJson`, delete the line `      pools: List<String>.from(json['pools'] as List? ?? []),` (`:95`) and the line `      stackable: json['stackable'] as bool? ?? true,` (`:108`).
5. In `toJson`, delete the line `      'pools': pools,` (`:219`) and the line `      'stackable': stackable,` (`:227`).

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
/// fusion 3→1 (D13), son offre, l'affûtage au feu de camp et l'échange au
/// Puits (spec P-43 E2). Une rune non cumulable (`ForgeUpgradeData.stackable`)
/// n'a pas de niveau qui vaille : une fusion 3→1 n'en garde qu'un exemplaire,
/// au niveau 1. Les références se lisent par l'analyseur unique du modèle,
/// `ForgeUpgradeData.parseRef` (ADR-094 D5).
```

with:

```dart
/// Les règles des runes de forge, notées `id:niveau` : l'héritage de la
/// fusion 3→1 (D13), son offre, l'affûtage au feu de camp et l'échange au
/// Puits (spec P-43 E2). Les références se lisent par l'analyseur unique du
/// modèle, `ForgeUpgradeData.parseRef` (ADR-094 D5).
```

Then delete:

```dart
  /// Une rune absente du registre est traitée comme cumulable, ce qu'étaient
  /// toutes les runes avant l'apparition du champ.
  static bool isStackable(String runeId) =>
      ForgeUpgradeData.getById(runeId)?.stackable ?? true;

```

Then replace:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// les tiers d'une rune cumulable s'additionnent, bornés par son `maxLevel`
  /// — le surplus se perd (spec P-43 E1, A9) ; une rune non cumulable est
  /// gardée une fois au tier 1. Une référence mal formée ou de tier nul est
  /// ignorée. Deux runes qui s'excluent (`excludesRunes`, dans un sens ou
```

with:

```dart
  /// Réunit les runes de même id, dans l'ordre de leur première apparition :
  /// leurs niveaux s'additionnent, bornés par son `maxLevel` — le surplus se
  /// perd, une rune de plafond 1 reste au niveau 1 (spec P-43 E1, A9 ; spec
  /// P-43 E2, §4.6). Une référence mal formée ou de niveau nul est
  /// ignorée. Deux runes qui s'excluent (`excludesRunes`, dans un sens ou
```

(les deux lignes suivantes du commentaire, sur les runes qui s'excluent, ne changent pas).

Then replace `      result.add('$id:${isStackable(id) ? _bounded(id, tier) : 1}');` with `      result.add('$id:${_bounded(id, tier)}');`.

Then replace:

```dart
  /// elle-même en boutique. [catalog] sert à lire les exclusions des runes
  /// que la carte porte déjà. `pools` n'en est pas une condition : c'est le
  /// ciblage par rareté des tirages, qui le gardent (D68).
```

with:

```dart
  /// elle-même en boutique et au Puits. [catalog] sert à lire les exclusions
  /// des runes que la carte porte déjà.
```

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // `pools` est la seule cle que la famille 3 exige : les autres cles
    // obligatoires d'une rune — `deltas`, `maxLevel` (spec P-43 E1, §3.1) et
    // `minFusionRank` (spec P-43 E2, A8) — sont refusees par
    // `ForgeUpgradeData.fromJson` lui-meme, que la famille 7 appelle. Un fait
    // a un seul endroit.
    requiredKeys: const {'pools'},
```

with:

```dart
    // La famille 3 n'exige aucune cle : les cles obligatoires d'une rune —
    // `deltas`, `maxLevel` (spec P-43 E1, §3.1) et `minFusionRank` (spec
    // P-43 E2, A8) — sont refusees par `ForgeUpgradeData.fromJson` lui-meme,
    // que la famille 7 appelle. Un fait a un seul endroit.
    requiredKeys: const {},
```

Then, in the rune template, delete the line `  "pools": ["common"],` (`:378`) and the line `  "stackable": true,` (`:385`).

In each of the eight files of `assets/data/forge_upgrades/`, delete the `"pools"` block, just after `"minFusionRank"` :

| Fichier | Bloc supprimé |
|:---|:---|
| `burning.json`, `freezing.json`, `hardened.json`, `sharp.json`, `shocking.json` | `  "pools": [` / `    "common",` / `    "uncommon",` / `    "rare"` / `  ],` (`:10-14`) |
| `quick.json` | `  "pools": [` / `    "uncommon",` / `    "rare"` / `  ],` (`:10-13`) |
| `eco.json`, `enduring.json` | `  "pools": [` / `    "rare"` / `  ],` (`:10-12`) |

For example, in `sharp.json`, replace:

```json
  "minFusionRank": 1,
  "pools": [
    "common",
    "uncommon",
    "rare"
  ],
  "eligibleEffects": [
```

with:

```json
  "minFusionRank": 1,
  "eligibleEffects": [
```

In `enduring.json`, also delete the line `  "stackable": false,` (`:27`), just before `"maxLevel": 1`. Rien d'autre ne change dans les fichiers.

Run: `rm -rf build/unit_test_assets`

- [ ] **Step 4: Les tests qui suivent sans changer ce qu'ils vérifient**

`dart analyze` liste alors chaque rune construite avec `pools:` ou `stackable:`. Delete the `pools:` line of each Dart-built rune:

| Fichier | Ligne supprimée |
|:---|:---|
| `test/unit/deck_state_persistence_test.dart:52` | `            pools: ['common'],` |
| `test/unit/decoupled_forge_test.dart:41`, `:55` | `            pools: ['common'],` |
| `test/unit/decoupled_forge_test.dart:69`, `:82` | `            pools: ['rare'],` |
| `test/unit/effective_card_test.dart:39` | `      pools: const ['common'],` |
| `test/unit/rune_eligibility_test.dart:28` | `      pools: const ['common'],` |
| `test/unit/save_catalog_lookups_test.dart:111` | `            pools: ['common'],` |
| `test/unit/shop_controller_test.dart:373` (`capped`) | `            pools: ['common', 'uncommon', 'rare'],` |
| `test/unit/shop_controller_test.dart`, `alpha` et `beta` (Task 2) | `            pools: ['rare'],` et `            pools: ['common'],` |
| `test/widget/ui_card_rune_sockets_test.dart:112`, `:156` | `          pools: ['common'],` |
| `test/unit/forge_upgrade_data_test.dart:231` | `          pools: ['common'],` |

In `test/unit/decoupled_forge_test.dart`, replace:

```dart
            requiresExhaust: true,
            stackable: false,
```

with:

```dart
            requiresExhaust: true,
            maxLevel: 1,
```

and replace `    test('mergeCards garde une seule rune non cumulable, au tier 1', () {` with `    test('mergeCards garde une rune de plafond 1 au niveau 1', () {` — son attente, `['enduring:1']`, ne change pas.

In `test/unit/shop_controller_test.dart`, in the case `une rune plafonnee n est jamais tiree au-dessus de son plafond`, replace the comment that the disappearance of the cumul makes false:

```dart
      // Cumulable, comme eco aujourd'hui : le tirage la monterait a 2 ou 3.
```

with:

```dart
      // Sans plafond, le tirage la monterait a 2 ou 3.
```

In `test/unit/forge_rune_rules_test.dart`, replace:

```dart
ForgeUpgradeData _rune(
  String id, {
  bool stackable = true,
  int? maxLevel,
```

with:

```dart
ForgeUpgradeData _rune(
  String id, {
  int? maxLevel,
```

then replace:

```dart
      pools: const ['common'],
      minFusionRank: minFusionRank,
      stackable: stackable,
```

with:

```dart
      minFusionRank: minFusionRank,
```

then replace `        _rune('enduring', stackable: false),` with `        _rune('enduring', maxLevel: 1),`. Then delete the whole group `ForgeUpgradeData.stackable` (`:68-96`) — from `  group('ForgeUpgradeData.stackable', () {` up to and including the blank line before `  group('ForgeRuneRules.consolidate', () {`. Then rename four cases of `ForgeRuneRules.consolidate`, their bodies unchanged:

| Avant | Après |
|:---|:---|
| `additionne les tiers des runes cumulables de meme id` | `additionne les niveaux des runes de meme id` |
| `garde une rune non cumulable une seule fois, au tier 1` | `garde une rune de plafond 1 une seule fois, au niveau 1` |
| `ramene au tier 1 une rune non cumulable deja montee` | `ramene au niveau 1 une rune de plafond 1 deja montee` |
| `traite une rune absente du registre comme cumulable` | `une rune absente du registre n a pas de plafond` |

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
      'id': 'sharp',
      'pools': ['common'],
      'minFusionRank': 1,
```

with:

```dart
      'id': 'sharp',
      'minFusionRank': 1,
```

In `test/unit/forge_upgrades_catalog_test.dart`:
- delete the line `const _threePools = ['common', 'uncommon', 'rare'];` ;
- in `_declared`, delete the lines `      'pools': rune.pools,` and `      'stackable': rune.stackable,` ;
- in `_rune`, delete the parameters `  List<String> pools = _threePools,` and `  bool stackable = true,`, and the map lines `      'pools': pools,` and `      'stackable': stackable,` ;
- in `_expected`, delete `    pools: const ['uncommon', 'rare'],` (`quick`), `    pools: const ['rare'],` (`eco`, `enduring`) and `    stackable: false,` (`enduring`) ;
- replace the two comment lines

```dart
/// la table de la spec P-43 E2, §4.12, sans les trois runes de la partie 2.
/// `pools` mis à part, que le tirage de la boutique applique encore.
```

with:

```dart
/// la table de la spec P-43 E2, §4.12, sans les trois runes neuves.
```

In `test/unit/real_bundle_load_test.dart`, replace:

```dart
    expect(
      registry.forgeUpgrades.where((u) => !u.stackable).map((u) => u.id),
      ['enduring'],
    );
```

with:

```dart
    expect(
      registry.forgeUpgrades.where((u) => u.maxLevel == 1).map((u) => u.id),
      ['eco', 'enduring', 'freezing', 'quick'],
    );
```

In the editor tests:
- `test/unit/content_editor/fixtures.dart` : delete `      'pools': ['common'],` (`:53`) ;
- `test/unit/content_editor/entity_validator_test.dart` : replace

```dart
          mechanics: '{"pools": ["common"], '
              '"eligibleCardTypes": ["attack", "sortilege"]}',
```

with

```dart
          mechanics: '{"eligibleCardTypes": ["attack", "sortilege"]}',
```

(ce brouillon s'arrête à l'énumération, avant `fromJson`), and replace `            mechanics: '{"pools": ["common"], "minFusionRank": 1, '` with `            mechanics: '{"minFusionRank": 1, '` ;
- `test/unit/content_editor/known_values_test.dart` : replace

```dart
    write('assets/data/forge_upgrades/a.json',
        '{"pools": ["common", "rare"]}');
    write('assets/data/forge_upgrades/b.json', '{"pools": ["rare"]}');
```

with

```dart
    write('assets/data/forge_upgrades/a.json',
        '{"eligibleCardTypes": ["attack", "skill"]}');
    write('assets/data/forge_upgrades/b.json',
        '{"eligibleCardTypes": ["skill"]}');
```

and `    expect(values['pools'], ['common', 'rare']);` with `    expect(values['eligibleCardTypes'], ['attack', 'skill']);` ;
- `test/unit/content_editor/field_kind_test.dart` : replace `    expect(kindOf(forge, const ['pools'], ['common']), FieldKind.stringList);` with

```dart
    expect(kindOf(forge, const ['excludesEffects'], ['draw']),
        FieldKind.stringList);
```

- `test/widget/content_editor/document_form_test.dart` : replace `      'pools': ['common'],` (`:84`) with `      'excludesEffects': ['draw'],` ;
- `test/unit/content_editor/entity_descriptor_test.dart` : in the expected keys of `EntityCategory.forgeUpgrade`, delete `        'pools',` (`:263`) and `        'stackable',` (`:270`).

- [ ] **Step 5: Lancer les tests touchés**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/forge_rune_rules_test.dart test/unit/decoupled_forge_test.dart test/unit/real_bundle_load_test.dart test/unit/shop_controller_test.dart test/unit/content_editor test/widget/content_editor/document_form_test.dart`
Expected: PASS, dont `shipped_entities_round_trip_test.dart` (les huit runes, sans `pools`, valident et se réécrivent à l'identique : `requiredKeys` est vide).

- [ ] **Step 6: Analyse, suite et commandes de contrôle**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1450: All tests passed!` (1450 + 2 − 2).

Run: `git grep -n -w pools -- lib test assets tool`
Expected: les homonymes seuls — `lib/models/data/card_data.dart` (« les trois pools » d'affichage) et `test/unit/audio/flame_audio_backend_pool_test.dart`.

Run: `git grep -n -w stackable -- lib test assets tool`
Expected: une ligne, l'homonyme `lib/models/status_effect.dart` (le commentaire de `StatusEffect.combine`).

Run: `git grep -n "isStackable(" -- lib test`
Expected: aucune sortie.

- [ ] **Step 7: Commit**

```bash
git add lib/models/data/forge_upgrade_data.dart lib/game/services/forge_rune_rules.dart lib/services/content_editor/entity_descriptor.dart assets/data/forge_upgrades test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/forge_rune_rules_test.dart test/unit/real_bundle_load_test.dart test/unit/decoupled_forge_test.dart test/unit/effective_card_test.dart test/unit/rune_eligibility_test.dart test/unit/save_catalog_lookups_test.dart test/unit/deck_state_persistence_test.dart test/unit/shop_controller_test.dart test/widget/ui_card_rune_sockets_test.dart test/unit/content_editor/fixtures.dart test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/known_values_test.dart test/unit/content_editor/field_kind_test.dart test/unit/content_editor/entity_descriptor_test.dart test/widget/content_editor/document_form_test.dart
git commit -F - <<'EOF'
refactor(runes): pools et stackable disparaissent

Leurs derniers lecteurs sont partis : les deux champs quittent le modele,
les huit fichiers et le gabarit de l editeur, dont requiredKeys ne garde
rien. isStackable et sa branche de consolidate disparaissent, le plafond 1
de maxLevel suffit. Deux tests gardent l absence des cles par l ensemble
des cles que le modele lit.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 5: `{val}` dit ce que toute rune chiffrée ajoute à la carte

`{val}` ne valait que pour `percentBonus` (spec A14, §5.2 ; E-S5 de la vague 1). Il se calcule désormais sur **le premier delta chiffré** de la rune : `percentBonus`, le bonus marginal que donne l'applicateur (inchangé) ; `addEffect`, `valuePerLevel × L` ; un delta sans chiffre (`removeExhaust`) est passé. Les cinq descriptions à effet ajouté — `burning`, `freezing`, `shocking`, `quick`, `eco` — passent de `{tier}` à `{val}`. Les sortes neuves (`reduceCost`, `critBonus`, `addExhaust`) s'y ajoutent en Task 6, dans le même `switch`.

Aucun changement à l'écran : pour les huit runes livrées, `valuePerLevel` vaut 1, et `{val}` égale l'ancien `{tier}`.

**Files:**
- Modify: `lib/models/data/forge_upgrade_data.dart:239-273` (`getDescription`, `_addedTo`)
- Modify: `assets/data/forge_upgrades/{burning,freezing,shocking,quick,eco}.json:5-6`
- Test: `test/unit/forge_upgrade_data_test.dart:5` (import), avant `:290` (groupe neuf)

**Interfaces:**
- Consumes: `EffectiveCard.apply`.
- Produces: `ForgeUpgradeData.getDescription(int level, String locale, CardData card, CardRarity rarity, {int carried = 0})` — signature inchangée ; `{val}` lu sur le premier delta chiffré, par une méthode privée `_valueAdded` dont le `switch` sur `CardDelta` est exhaustif (Task 6 y ajoute ses trois cas).

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/data/game_data_registry.dart';

import 'shipped_data.dart';
```

Then replace:

```dart
  // La regle des infobulles, que suivent la ligne de rune et le dialogue de
  // fusion (spec P-43 E2, §4.11).
```

with:

```dart
  // `{val}` pour toute sorte chiffree (spec P-43 E2, A14, §5.2).
  group('{val}', () {
    const strike = CardData(
      id: 'strike_basic',
      cost: 1,
      type: CardType.attack,
      category: CardCategory.global,
      rarity: CardRarity.common,
      target: CardTarget.singleEnemy,
      effects: [CardEffect(type: 'damage', value: 30)],
    );

    test('sur addEffect : la valeur par niveau fois le niveau, pas le '
        'niveau', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': 'Pioche +{val}',
        'deltas': [
          {'type': 'addEffect', 'effect': 'draw', 'valuePerLevel': 2},
        ],
      }));
      expect(rune.getDescription(3, 'fr', strike, CardRarity.common),
          'Pioche +6');
    });

    test('lit le premier delta chiffre', () {
      // Le pourcentage donnerait 15 % x 2 x 30 = 9 ; le premier delta
      // chiffre est le mana rendu, 1 par niveau.
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '+{val}',
        'deltas': [
          {'type': 'removeExhaust'},
          {'type': 'addEffect', 'effect': 'gain_mana', 'valuePerLevel': 1},
          {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 15},
        ],
      }));
      expect(rune.getDescription(2, 'fr', strike, CardRarity.common), '+2');
    });

    test('les cinq runes a effet ajoute disent leur valeur, que l ecran '
        'montrait deja', () {
      final card = shippedCard('strike_basic');
      String text(String id, int level) =>
          shippedRune(id).getDescription(level, 'fr', card, CardRarity.common);
      expect(text('burning', 3), 'Applique 3 Brûlure');
      expect(text('freezing', 1), 'Applique 1 Gel');
      expect(text('shocking', 2), 'Applique 2 Électrocution');
      expect(text('quick', 1), 'Pioche +1 carte(s)');
      expect(text('eco', 1), "Gagne +1 Mana à l'utilisation");
    });
  });

  // La regle des infobulles, que suivent la ligne de rune et le dialogue de
  // fusion (spec P-43 E2, §4.11).
```

- [ ] **Step 2: Les cinq descriptions, puis lancer les tests pour les voir échouer**

In each of `assets/data/forge_upgrades/burning.json`, `freezing.json`, `shocking.json`, `quick.json` and `eco.json`, replace `{tier}` with `{val}` in `description_en` and in `description_fr` (deux occurrences par fichier, aucune autre) :

| Fichier | `description_en` | `description_fr` |
|:---|:---|:---|
| `burning.json` | `Applies {val} Burn` | `Applique {val} Brûlure` |
| `freezing.json` | `Applies {val} Freeze` | `Applique {val} Gel` |
| `shocking.json` | `Applies {val} Shock` | `Applique {val} Électrocution` |
| `quick.json` | `Draw +{val} card(s)` | `Pioche +{val} carte(s)` |
| `eco.json` | `Gains +{val} Mana on play` | `Gagne +{val} Mana à l'utilisation` |

Run: `flutter test test/unit/forge_upgrade_data_test.dart`
Expected: FAIL — les trois cas neufs : `{val}` vaut 0 hors pourcentage (« Pioche +0 », « +9 », « Applique 0 Brûlure »).

- [ ] **Step 3: `{val}` sur le premier delta chiffré**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
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
```

with:

```dart
  /// La description de la rune au niveau [level], sur [card] à [rarity] (spec
  /// P-43 E1, §5.1) : `{tier}` est le niveau ; `{percent}`, le pourcentage de
  /// ce niveau ; `{val}`, ce que la rune ajoute à **cette** carte au-delà des
  /// [carried] niveaux qu'elle en porte déjà, sur son premier delta chiffré
  /// (spec P-43 E2, A14, §5.2) — 0 si elle n'en a pas.
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
        .replaceAll('{val}', '${_valueAdded(card, rarity, level, carried)}');
  }

  /// `{val}` : ce que le premier delta chiffré de la rune ajoute à [card] —
  /// le gain que joue le moteur, l'applicateur le calcule quand il dépend de
  /// la carte ; un delta sans chiffre est passé.
  int _valueAdded(CardData card, CardRarity rarity, int level, int carried) {
    for (final delta in deltas) {
      final value = switch (delta) {
        PercentBonusDelta() =>
          _percentAdded(card, rarity, level, carried, delta),
        AddEffectDelta() => delta.valuePerLevel * level,
        RemoveExhaustDelta() => null,
      };
      if (value != null) return value;
    }
    return 0;
  }

  /// Le bonus marginal de [bonus] sur le premier effet propre du type visé,
  /// 0 si la carte n'en a pas.
  static int _percentAdded(
    CardData card,
    CardRarity rarity,
    int level,
    int carried,
    PercentBonusDelta bonus,
  ) {
    final index = card.effects.indexWhere((e) => e.type == bonus.effect);
```

La suite de l'ancienne `_addedTo` (`if (index == -1) return 0;`, `valueAt`, le retour) reste telle quelle, dans `_percentAdded`.

- [ ] **Step 4: Lancer les tests pour les voir passer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/decoupled_forge_test.dart test/widget/ui_card_values_test.dart`
Expected: PASS — l'infobulle dit toujours « Véloce : Pioche +1 carte(s) ».

- [ ] **Step 5: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1453: All tests passed!` (1450 + 3).

- [ ] **Step 6: Commit**

```bash
git add lib/models/data/forge_upgrade_data.dart assets/data/forge_upgrades/burning.json assets/data/forge_upgrades/freezing.json assets/data/forge_upgrades/shocking.json assets/data/forge_upgrades/quick.json assets/data/forge_upgrades/eco.json test/unit/forge_upgrade_data_test.dart
git commit -F - <<'EOF'
feat(runes): val dit ce que toute rune chiffree ajoute a la carte

val se lit sur le premier delta chiffre de la rune : le bonus marginal
d un pourcentage, la valeur par niveau d un effet ajoute. Les cinq runes
a effet ajoute ecrivent val au lieu de tier, sans changer a l ecran.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 6: *Allégé*, *Précis* et *Spectral* rejoignent les huit runes

Trois sortes de delta neuves, une par mécanisme (spec §4.1, A10) : `reduceCost` (la carte coûte `valuePerLevel × L` de moins, plancher 0, la rareté sans effet), `critBonus` (+`valuePerLevel × L` points de critique sur les dégâts de la carte), `addExhaust` (la carte s'épuise, et l'emporte sur `removeExhaust`). L'applicateur les calcule (`EffectiveCard.cost`, `critChanceBonus`, `addsExhaust`, §4.2) ; `CardInstance.currentCost` lit `effective.cost`, et donc ses lecteurs sans qu'ils changent ; `exhaustsOnPlay` lit `addsExhaust` ; `DamagePipeline.calculate` gagne `critChanceBonus`, que `DamageEffectStrategy` lui passe ; le prédicat calcule le coût courant par l'applicateur **sur le catalogue reçu** (A15). `{val}` gagne les deux sortes chiffrées (A14). Les trois fichiers entrent (§3.1, §3.2), sans `eligibleCardTypes`, au poids 50 ; leurs icônes et couleurs entrent dans deux tables `const` publiques, `runeIcons` et `runeColors` (`lib/ui/widgets/forge/rune_style.dart`, A19), que lisent la ligne de rune et le test d'intégrité. La matrice du catalogue gagne les trois runes (§4.12).

Changements de jeu de la tâche, voulus : *Allégé*, *Précis* et *Spectral* s'offrent à la fusion et en boutique ; une carte *Spectrale* s'épuise (le badge suit en Task 7).

**Files:**
- Modify: `lib/models/data/card_delta.dart:17`, `:29`, après `:151` (trois classes)
- Modify: `lib/models/effective_card.dart:1`, `:10-14`, `:23-24`, `:38-39`, `:55-64`
- Modify: `lib/models/card_instance.dart:22`, `:29-35`
- Modify: `lib/game/services/damage_pipeline.dart:6-11`, `:24`
- Modify: `lib/game/services/effects/strategies.dart:28`, `:36-40`, `:49-53`
- Modify: `lib/game/services/forge_rune_rules.dart:4` (import), `:121-122` (le coût du prédicat)
- Modify: `lib/models/data/forge_upgrade_data.dart` — `_valueAdded` (Task 5), et une aide `_costCut`
- Create: `assets/data/forge_upgrades/cheap.json`, `precise.json`, `spectral.json`
- Create: `lib/ui/widgets/forge/rune_style.dart`
- Modify: `lib/ui/widgets/forge/forge_slot_row.dart:3` (import), `:32-76` (les deux tables privées), `:80-81`
- Modify: `lib/services/content_editor/entity_descriptor.dart:342-345` (le commentaire des icônes)
- Test: `test/unit/forge_upgrade_data_test.dart` (groupes `deltas` et `{val}`)
- Test: `test/unit/effective_card_test.dart:1-4` (imports), avant `:217`
- Test: `test/unit/damage_pipeline_test.dart` (nouveau)
- Test: `test/unit/rune_eligibility_test.dart` avant `:123`
- Test: `test/unit/rune_resolution_test.dart` avant `:130`
- Test: `test/unit/deck_controller_test.dart:469`, avant `:521`
- Test: `test/unit/referential_integrity_test.dart:12`, `:15-19`, avant `:79`
- Test: `test/unit/forge_upgrades_catalog_test.dart:66-69`, `:126-139`, `:143-144`, `:148`, `:160-165`, `:181`
- Test: `test/unit/real_bundle_load_test.dart:38`, `:97`, et la liste du plafond 1 (Task 4)
- Test: `test/unit/rune_ids_in_code_test.dart:33` ; `test/unit/entity_id_convention_test.dart:64-71` ; `test/widget/deck_screen_test.dart:256-270` ; `test/tutorial/tutorial_engine_test.dart:361-363` (commentaire)

**Interfaces:**
- Consumes: `EffectiveCard.apply`, `EffectiveCard.runeDeltas` ; `CardDelta._positive` ; `ForgeRuneRules.isEligible` (partie 1).
- Produces:
  - `final class ReduceCostDelta extends CardDelta { const ReduceCostDelta({required int valuePerLevel}); final int valuePerLevel; }` — `toJson` `{'type': 'reduceCost', 'valuePerLevel': …}` ;
  - `final class CritBonusDelta extends CardDelta { const CritBonusDelta({required int valuePerLevel}); final int valuePerLevel; }` — `toJson` `{'type': 'critBonus', 'valuePerLevel': …}` ;
  - `final class AddExhaustDelta extends CardDelta { const AddExhaustDelta(); }` — `toJson` `{'type': 'addExhaust'}` ;
  - `CardDelta.typeNames` : six noms ;
  - `final int EffectiveCard.cost`, `final int EffectiveCard.critChanceBonus`, `final bool EffectiveCard.addsExhaust` ;
  - `int CardInstance.currentCost` → `effective.cost` ; `bool CardInstance.exhaustsOnPlay` → pouvoir, ou `addsExhaust`, ou `isExhaust ∧ ¬removesExhaust` ;
  - `DamagePipeline.calculate({…, int critChanceBonus = 0})` ;
  - `const Map<String, IconData> runeIcons`, `const Map<String, Color> runeColors` (`rune_style.dart`).

- [ ] **Step 1: Écrire les tests du moteur**

In `test/unit/forge_upgrade_data_test.dart`, replace:

```dart
    test('refuse une rune sans deltas', () {
```

with:

```dart
    test('lit les trois sortes neuves', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'deltas': [
          {'type': 'reduceCost', 'valuePerLevel': 1},
          {'type': 'critBonus', 'valuePerLevel': 5},
          {'type': 'addExhaust'},
        ],
      }));

      final [cut, crit, exhaust] = rune.deltas;
      expect(cut, isA<ReduceCostDelta>().having((d) => d.valuePerLevel, 'valuePerLevel', 1));
      expect(crit, isA<CritBonusDelta>().having((d) => d.valuePerLevel, 'valuePerLevel', 5));
      expect(exhaust, isA<AddExhaustDelta>());
    });

    test('refuse un reduceCost ou un critBonus sans valuePerLevel strictement '
        'positif', () {
      for (final type in ['reduceCost', 'critBonus']) {
        for (final bad in [
          <String, dynamic>{},
          {'valuePerLevel': 0},
          {'valuePerLevel': -1},
        ]) {
          expect(
            () => ForgeUpgradeData.fromJson(_json({
              'deltas': [
                {'type': type, ...bad},
              ],
            })),
            _refused('valuePerLevel'),
            reason: '$type $bad',
          );
        }
      }
    });

    test('refuse une rune sans deltas', () {
```

Then replace:

```dart
      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(
        [for (final delta in restored.deltas) delta.toJson()],
        [for (final delta in rune.deltas) delta.toJson()],
      );
    });
  });
```

with:

```dart
      final restored = ForgeUpgradeData.fromJson(rune.toJson());
      expect(
        [for (final delta in restored.deltas) delta.toJson()],
        [for (final delta in rune.deltas) delta.toJson()],
      );
    });

    test('toJson fait l aller-retour des sortes neuves', () {
      const deltas = [
        {'type': 'reduceCost', 'valuePerLevel': 1},
        {'type': 'critBonus', 'valuePerLevel': 5},
        {'type': 'addExhaust'},
      ];
      final rune = ForgeUpgradeData.fromJson(_json({'deltas': deltas}));
      expect(
        [
          for (final delta
              in ForgeUpgradeData.fromJson(rune.toJson()).deltas)
            delta.toJson(),
        ],
        deltas,
      );
    });
  });
```

Then, in the group `{val}` (Task 5), replace:

```dart
      expect(rune.getDescription(2, 'fr', strike, CardRarity.common), '+2');
    });
```

with:

```dart
      expect(rune.getDescription(2, 'fr', strike, CardRarity.common), '+2');
    });

    test('sur reduceCost : la baisse marginale, plancher 0 compris', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '-{val}',
        'deltas': [
          {'type': 'reduceCost', 'valuePerLevel': 1},
        ],
      }));
      // La Frappe coute 1 : un niveau la porte a 0, un second n'ote plus rien.
      expect(rune.getDescription(1, 'fr', strike, CardRarity.common), '-1');
      expect(
        rune.getDescription(1, 'fr', strike, CardRarity.common, carried: 1),
        '-0',
      );
    });

    test('sur critBonus : la valeur par niveau fois le niveau', () {
      final rune = ForgeUpgradeData.fromJson(_json({
        'description_fr': '+{val}%',
        'deltas': [
          {'type': 'critBonus', 'valuePerLevel': 5},
        ],
      }));
      expect(rune.getDescription(3, 'fr', strike, CardRarity.common), '+15%');
    });
```

In `test/unit/effective_card_test.dart`, replace:

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
```

with:

```dart
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/card_delta.dart';
import 'package:roguelike_card_game/models/data/forge_upgrade_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
```

Then replace:

```dart
  test('effects a la longueur et l ordre des effets de la donnee', () {
```

with:

```dart
  // Les trois sortes neuves (spec P-43 E2, §4.1, §4.2).
  group('reduceCost, critBonus, addExhaust', () {
    CardData costing(int cost) => CardData(
          id: 'test_card',
          cost: cost,
          type: CardType.attack,
          category: CardCategory.global,
          rarity: CardRarity.common,
          target: CardTarget.singleEnemy,
          effects: [_damage(6)],
        );
    const cut = ReduceCostDelta(valuePerLevel: 1);

    test('reduceCost : le cout moins valuePerLevel x niveau, plancher 0, la '
        'rarete sans effet', () {
      expect(
          EffectiveCard.apply(costing(2), CardRarity.common, [(cut, 1)]).cost,
          1);
      expect(
          EffectiveCard.apply(costing(1), CardRarity.common, [(cut, 3)]).cost,
          0);
      expect(
          EffectiveCard.apply(costing(2), CardRarity.legendary, const []).cost,
          2);
    });

    test('critBonus : additionne dans critChanceBonus', () {
      const crit = CritBonusDelta(valuePerLevel: 5);
      expect(
        EffectiveCard.apply(
                costing(1), CardRarity.common, [(crit, 2), (crit, 1)])
            .critChanceBonus,
        15,
      );
      expect(
        EffectiveCard.apply(costing(1), CardRarity.common, const [])
            .critChanceBonus,
        0,
      );
    });

    test('addExhaust leve addsExhaust, quel que soit le niveau', () {
      for (final level in [1, 3]) {
        expect(
          EffectiveCard.apply(costing(1), CardRarity.common,
              [(const AddExhaustDelta(), level)]).addsExhaust,
          isTrue,
          reason: 'niveau $level',
        );
      }
      expect(
        EffectiveCard.apply(costing(1), CardRarity.common, const [])
            .addsExhaust,
        isFalse,
      );
    });

    // Deux pourcentages sur un meme effet s'additionnent, sans se composer.
    test('sharp et spectral s additionnent, chacun sur la valeur a la '
        'rarete', () {
      // 10 en commune, 14 en rare : +2 a 15 %, +6 a 40 %.
      const spectral =
          PercentBonusDelta(effect: 'damage', valuePercentPerLevel: 40);
      expect(
        _values(EffectiveCard.apply(_card([_damage(10)]), CardRarity.rare,
            [(_sharp, 1), (spectral, 1)])),
        [14 + 2 + 6],
      );
    });
  });

  // CardInstance lit l'applicateur sur le registre (spec P-43 E2, §4.2,
  // A10).
  group('CardInstance', () {
    setUp(() {
      GameDataRegistry(
        enemies: const [],
        heroes: const [],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: [
          _rune('leger', const [ReduceCostDelta(valuePerLevel: 1)]),
          _rune('ephemere', const [AddExhaustDelta()]),
          _rune('tenace', const [RemoveExhaustDelta()]),
        ],
      );
    });

    CardInstance carrying(List<String> runes, {bool isExhaust = false}) =>
        CardInstance(
          data: CardData(
            id: 'test_card',
            cost: 2,
            type: CardType.attack,
            category: CardCategory.global,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            isExhaust: isExhaust,
            effects: [_damage(6)],
          ),
          forgeUpgrades: runes,
        );

    test('currentCost est le cout de l applicateur', () {
      expect(carrying(const []).currentCost, 2);
      expect(carrying(const ['leger:1']).currentCost, 1);
    });

    test('exhaustsOnPlay : addExhaust epuise, et l emporte sur removeExhaust',
        () {
      expect(carrying(const ['ephemere:1']).exhaustsOnPlay, isTrue);
      expect(
        carrying(const ['tenace:1', 'ephemere:1'], isExhaust: true)
            .exhaustsOnPlay,
        isTrue,
      );
      expect(carrying(const ['tenace:1'], isExhaust: true).exhaustsOnPlay,
          isFalse);
    });
  });

  test('effects a la longueur et l ordre des effets de la donnee', () {
```

Create `test/unit/damage_pipeline_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/services/damage_pipeline.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

/// Le critique que la carte jouée ajoute à celui de l'attaquant (spec P-43
/// E2, §4.2, A10) : `precise`.
void main() {
  // Ni critique, ni statut : seul le bonus de la carte peut critiquer.
  EntityStats stats() =>
      EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0);

  test('critChanceBonus s ajoute au jet : a 100 points, le coup est critique',
      () {
    for (var i = 0; i < 20; i++) {
      final (damage, isCrit) = DamagePipeline.calculate(
        initialDamage: 10,
        attackerStats: stats(),
        defenderStats: stats(),
        critChanceBonus: 100,
      );
      expect((damage, isCrit), (15, true));
    }
  });

  test('0 par defaut : le jet d aujourd hui, sans critique a 0 %', () {
    for (var i = 0; i < 20; i++) {
      expect(
        DamagePipeline.calculate(
          initialDamage: 10,
          attackerStats: stats(),
          defenderStats: stats(),
        ),
        (10, false),
      );
    }
  });
}
```

In `test/unit/rune_eligibility_test.dart`, replace:

```dart
  group('la symetrie des exclusions (D51, D61)', () {
```

with:

```dart
  // A15, Review Focus 4 : le cout courant, par l'applicateur sur le
  // catalogue recu — aucun registre global n'existe dans ce fichier.
  test('le cout courant se lit apres les runes portees, sur le catalogue '
      'recu', () {
    final light = _rune('light', deltas: const [
      ReduceCostDelta(valuePerLevel: 1),
    ]);
    final rune = _rune('eco', requiresMinCost: 1);
    expect(_eligible(rune, _card(cost: 1)), isTrue);
    expect(_eligible(rune, _card(cost: 1, runes: const ['light:1']), [light]),
        isFalse);
    expect(_eligible(rune, _card(cost: 2, runes: const ['light:1']), [light]),
        isTrue);
  });

  group('la symetrie des exclusions (D51, D61)', () {
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/effective_card_test.dart test/unit/damage_pipeline_test.dart test/unit/rune_eligibility_test.dart`
Expected: FAIL à la compilation — `ReduceCostDelta`, `CritBonusDelta`, `AddExhaustDelta`, `cost`, `critChanceBonus`, `addsExhaust` et le paramètre `critChanceBonus` ne sont pas définis.

- [ ] **Step 3: Les trois sortes**

In `lib/models/data/card_delta.dart`, replace:

```dart
  static const typeNames = ['percentBonus', 'addEffect', 'removeExhaust'];
```

with:

```dart
  static const typeNames = [
    'percentBonus',
    'addEffect',
    'removeExhaust',
    'reduceCost',
    'critBonus',
    'addExhaust',
  ];
```

Then replace:

```dart
      'removeExhaust' => const RemoveExhaustDelta(),
```

with:

```dart
      'removeExhaust' => const RemoveExhaustDelta(),
      'reduceCost' =>
        ReduceCostDelta(valuePerLevel: _positive(json, 'valuePerLevel')),
      'critBonus' =>
        CritBonusDelta(valuePerLevel: _positive(json, 'valuePerLevel')),
      'addExhaust' => const AddExhaustDelta(),
```

Then append at the end of the file, after `RemoveExhaustDelta`:

```dart

/// La carte coûte `valuePerLevel × L` Mana de moins, jamais moins de 0 ; la
/// rareté ne change jamais le coût (spec P-43 E2, §4.1) : `cheap`.
final class ReduceCostDelta extends CardDelta {
  const ReduceCostDelta({required this.valuePerLevel});

  final int valuePerLevel;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'reduceCost', 'valuePerLevel': valuePerLevel};
}

/// +`valuePerLevel × L` points de pourcentage de critique sur les dégâts de
/// la carte (spec P-43 E2, §4.1) : `precise`.
final class CritBonusDelta extends CardDelta {
  const CritBonusDelta({required this.valuePerLevel});

  final int valuePerLevel;

  @override
  Map<String, dynamic> toJson() =>
      {'type': 'critBonus', 'valuePerLevel': valuePerLevel};
}

/// La carte s'épuise, quel que soit le niveau, et l'emporte sur
/// [RemoveExhaustDelta] (D33 ; spec P-43 E2, A10) : `spectral`.
final class AddExhaustDelta extends CardDelta {
  const AddExhaustDelta();

  @override
  Map<String, dynamic> toJson() => {'type': 'addExhaust'};
}
```

L'éditeur de contenu lit `CardDelta.typeNames` pour l'énumération `deltas[].type` (`entity_descriptor.dart:338`) : il connaît les six sortes sans autre changement (spec §6).

- [ ] **Step 4: L'applicateur et la carte**

In `lib/models/effective_card.dart`, replace:

```dart
import 'data/card_data.dart';
```

with:

```dart
import 'dart:math' show max;

import 'data/card_data.dart';
```

Then replace:

```dart
  const EffectiveCard._({
    required this.addedEffects,
    required this.effects,
    required this.removesExhaust,
  });
```

with:

```dart
  const EffectiveCard._({
    required this.addedEffects,
    required this.effects,
    required this.removesExhaust,
    required this.cost,
    required this.critChanceBonus,
    required this.addsExhaust,
  });
```

Then replace:

```dart
  /// Vrai si un delta lève l'épuisement de la carte.
  final bool removesExhaust;
```

with:

```dart
  /// Vrai si un delta lève l'épuisement de la carte.
  final bool removesExhaust;

  /// Le coût en Mana que la carte demande : celui de la donnée, moins ce que
  /// les deltas lui retirent, jamais sous 0 — la rareté ne le change jamais
  /// (spec P-43 E2, §4.2).
  final int cost;

  /// Les points de pourcentage de critique que les deltas ajoutent aux dégâts
  /// de la carte (spec P-43 E2, §4.2).
  final int critChanceBonus;

  /// Vrai si un delta épuise la carte ; l'emporte sur [removesExhaust] (spec
  /// P-43 E2, A10).
  final bool addsExhaust;
```

Then replace:

```dart
    final added = <CardEffect>[];
    var removesExhaust = false;
```

with:

```dart
    final added = <CardEffect>[];
    var removesExhaust = false;
    var costReduction = 0;
    var critChanceBonus = 0;
    var addsExhaust = false;
```

Then replace:

```dart
        case RemoveExhaustDelta():
          removesExhaust = true;
      }
    }

    return EffectiveCard._(
      addedEffects: List.unmodifiable(added),
      effects: List.unmodifiable(effects),
      removesExhaust: removesExhaust,
    );
```

with:

```dart
        case RemoveExhaustDelta():
          removesExhaust = true;
        case ReduceCostDelta():
          costReduction += delta.valuePerLevel * level;
        case CritBonusDelta():
          critChanceBonus += delta.valuePerLevel * level;
        case AddExhaustDelta():
          addsExhaust = true;
      }
    }

    return EffectiveCard._(
      addedEffects: List.unmodifiable(added),
      effects: List.unmodifiable(effects),
      removesExhaust: removesExhaust,
      cost: max(0, data.cost - costReduction),
      critChanceBonus: critChanceBonus,
      addsExhaust: addsExhaust,
    );
```

In `lib/models/card_instance.dart`, replace:

```dart
  int get currentCost => data.cost;
```

with:

```dart
  /// Le coût que la carte demande, ses runes appliquées (spec P-43 E2,
  /// §4.2).
  int get currentCost => effective.cost;
```

Then replace:

```dart
  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte `isExhaust` l'est sauf si une de ses runes lève l'épuisement,
  /// **quel que soit son niveau** (ADR-094 D4) : c'est la donnée de la rune
  /// qui le dit (`removeExhaust`), plus son id.
  bool get exhaustsOnPlay =>
      data.type == CardType.power ||
      (data.isExhaust && !effective.removesExhaust);
```

with:

```dart
  /// La carte est-elle épuisée une fois jouée ? Un pouvoir l'est toujours ;
  /// une carte qu'une rune épuise aussi (`addExhaust`, D33), même si une
  /// autre lève l'épuisement (spec P-43 E2, A10) ; une carte `isExhaust` l'est
  /// sauf si une de ses runes lève l'épuisement, **quel que soit son niveau**
  /// (ADR-094 D4) : c'est la donnée de la rune qui le dit, plus son id.
  bool get exhaustsOnPlay {
    if (data.type == CardType.power) return true;
    final effective = this.effective;
    return effective.addsExhaust ||
        (data.isExhaust && !effective.removesExhaust);
  }
```

`currentCost` garde ses lecteurs, qui ne changent pas : la résolution (`effect_resolver.dart:109`, `:134`), la carte Flame (`card_component.dart:56`, `:322` ; `card_text_renderer.dart:500`), la carte Flutter (`ui_card.dart:69`), le tutoriel (`tutorial_engine.dart:386`, `:391` ; `tutorial/widgets/tutorial_cards_widget.dart:119-120`).

- [ ] **Step 5: Le critique de la carte**

In `lib/game/services/damage_pipeline.dart`, replace:

```dart
class DamagePipeline {
  static (int damage, bool isCrit) calculate({
    required int initialDamage,
    required EntityStats attackerStats,
    required EntityStats defenderStats,
    bool canCrit = true,
  }) {
```

with:

```dart
class DamagePipeline {
  /// [critChanceBonus] : les points de pourcentage de critique que la carte
  /// jouée ajoute à ceux de l'attaquant — ses runes (`critBonus`, spec P-43
  /// E2, §4.2) ; 0 pour un ennemi.
  static (int damage, bool isCrit) calculate({
    required int initialDamage,
    required EntityStats attackerStats,
    required EntityStats defenderStats,
    bool canCrit = true,
    int critChanceBonus = 0,
  }) {
```

Then replace:

```dart
      if (random.nextInt(100) < attackerStats.effectiveCritChance) {
```

with:

```dart
      if (random.nextInt(100) <
          attackerStats.effectiveCritChance + critChanceBonus) {
```

In `lib/game/services/effects/strategies.dart`, in `DamageEffectStrategy.resolve`, replace:

```dart
    int dealt = 0;

    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
```

with:

```dart
    int dealt = 0;
    // Le critique que les runes de la carte ajoutent (spec P-43 E2, §4.2).
    final critChanceBonus = card.effective.critChanceBonus;

    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId != null) {
```

Then, in each of the two calls to `DamagePipeline.calculate` of this strategy (`:36-40` and `:49-53`), add the argument after `defenderStats: enemy.stats,`:

```dart
          critChanceBonus: critChanceBonus,
```

Les appels des ennemis (`turn_phase_manager.dart:109`) et du tutoriel (`tutorial_engine.dart:401`) gardent 0. Le soin (`strategies.dart:94-97`) ne lit pas le bonus : *Précis* ne s'offre qu'aux cartes de dégâts (A9).

- [ ] **Step 6: Le coût du prédicat, sur le catalogue reçu (A15)**

In `lib/game/services/forge_rune_rules.dart`, replace:

```dart
import '../../models/data/forge_upgrade_data.dart';
```

with:

```dart
import '../../models/data/forge_upgrade_data.dart';
import '../../models/effective_card.dart';
```

Then replace:

```dart
    if (rune.requiresExhaust && !card.data.isExhaust) return false;
    if (card.currentCost < rune.requiresMinCost) return false;
```

with:

```dart
    if (rune.requiresExhaust && !card.data.isExhaust) return false;

    // Le coût courant, par l'applicateur sur [catalog] — jamais sur le
    // registre global : le tutoriel juge sur le sien (spec P-43 E2, A15).
    final cost = EffectiveCard.apply(
      card.data,
      card.rarity,
      EffectiveCard.runeDeltas(card.forgeUpgrades, catalog),
    ).cost;
    if (cost < rune.requiresMinCost) return false;
```

- [ ] **Step 7: `{val}` des deux sortes chiffrées, et le `switch` du test d'intégrité**

In `lib/models/data/forge_upgrade_data.dart`, replace:

```dart
        AddEffectDelta() => delta.valuePerLevel * level,
        RemoveExhaustDelta() => null,
      };
```

with:

```dart
        AddEffectDelta() => delta.valuePerLevel * level,
        RemoveExhaustDelta() => null,
        ReduceCostDelta() => _costCut(card, rarity, level, carried, delta),
        CritBonusDelta() => delta.valuePerLevel * level,
        AddExhaustDelta() => null,
      };
```

Then replace:

```dart
    return valueAt(carried + level) - valueAt(carried);
  }
```

with:

```dart
    return valueAt(carried + level) - valueAt(carried);
  }

  /// La baisse de coût marginale de [cut] sur [card], plancher 0 compris.
  static int _costCut(
    CardData card,
    CardRarity rarity,
    int level,
    int carried,
    ReduceCostDelta cut,
  ) {
    int costAt(int total) =>
        EffectiveCard.apply(card, rarity, [(cut, total)]).cost;
    return costAt(carried) - costAt(carried + level);
  }
```

In `test/unit/referential_integrity_test.dart`, the `switch` of `_effectOf` (`:15-19`) is no longer exhaustive (`CardDelta` est scellée) ; replace:

```dart
      RemoveExhaustDelta() => null,
    };
```

with:

```dart
      RemoveExhaustDelta() => null,
      ReduceCostDelta() => null,
      CritBonusDelta() => null,
      AddExhaustDelta() => null,
    };
```

Aucune des trois ne nomme un type d'effet (spec §8, « Les tests qui suivent »).

- [ ] **Step 8: Lancer les tests du moteur pour les voir passer**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/effective_card_test.dart test/unit/damage_pipeline_test.dart test/unit/rune_eligibility_test.dart test/unit/referential_integrity_test.dart test/unit/rune_resolution_test.dart test/unit/deck_controller_test.dart`
Expected: PASS.

- [ ] **Step 9: Écrire les tests des trois runes livrées**

In `test/unit/forge_upgrades_catalog_test.dart`, replace:

```dart
/// Les huit runes, telles que les specs P-43 E1 (§3.2) et E2 (§3.2) les
/// fixent : `minFusionRank` 2 pour `quick` et `eco` (D48), 1 pour les six
/// autres (A7). Les `weight` et les `eligibleCardTypes` sont ceux que la
/// simulation lit : ils ne bougent pas (spec P-43 E2, §9).
```

with:

```dart
/// Les onze runes, telles que les specs P-43 E1 (§3.2) et E2 (§3.2) les
/// fixent : `minFusionRank` 2 pour `quick` et `eco` (D48), 1 pour les neuf
/// autres (A7, D63). Les `weight` et les `eligibleCardTypes` sont ceux que la
/// simulation lit : ils ne bougent pas, et les trois runes neuves n'ont pas
/// d'`eligibleCardTypes` (spec P-43 E2, §3.2, §9).
```

Then replace the end of `_expected`:

```dart
    deltas: const [
      {'type': 'removeExhaust'},
    ],
    weight: 30,
  ),
};
```

with:

```dart
    deltas: const [
      {'type': 'removeExhaust'},
    ],
    weight: 30,
  ),
  'cheap': _rune(
    requiresMinCost: 1,
    excludesRunes: const ['eco'],
    maxLevel: 1,
    deltas: const [
      {'type': 'reduceCost', 'valuePerLevel': 1},
    ],
    weight: 50,
  ),
  'precise': _rune(
    eligibleEffects: const ['damage'],
    maxLevel: 10,
    deltas: const [
      {'type': 'critBonus', 'valuePerLevel': 5},
    ],
    weight: 50,
  ),
  'spectral': _rune(
    eligibleEffects: const ['damage'],
    maxLevel: null,
    deltas: const [
      {'type': 'percentBonus', 'effect': 'damage', 'valuePercentPerLevel': 40},
      {'type': 'addExhaust'},
    ],
    weight: 50,
  ),
};
```

Then replace:

```dart
const _attackRank1 = {'sharp', 'burning', 'freezing', 'shocking'};
const _attackRank2 = {..._attackRank1, 'quick', 'eco'};
```

with:

```dart
const _attackRank1 = {
  'sharp',
  'burning',
  'freezing',
  'shocking',
  'cheap',
  'precise',
  'spectral',
};
const _attackRank2 = {..._attackRank1, 'quick', 'eco'};
```

Then replace `/// la table de la spec P-43 E2, §4.12, sans les trois runes neuves.` (écrit en Task 4) with `/// la table de la spec P-43 E2, §4.12.`, and replace:

```dart
  'awakening': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'defend_basic': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'iron_wall': ({'hardened'}, {'hardened', 'quick', 'eco'}),
  'heal_potion': ({'enduring'}, {'enduring', 'quick', 'eco'}),
  'demon_form': (<String>{}, {'quick', 'eco'}),
  'metallicize': (<String>{}, {'quick', 'eco'}),
```

with:

```dart
  'awakening': ({'hardened', 'cheap'}, {'hardened', 'cheap', 'quick', 'eco'}),
  'defend_basic': ({'hardened', 'cheap'}, {'hardened', 'cheap', 'quick', 'eco'}),
  'iron_wall': ({'hardened', 'cheap'}, {'hardened', 'cheap', 'quick', 'eco'}),
  'heal_potion': ({'enduring', 'cheap'}, {'enduring', 'cheap', 'quick', 'eco'}),
  'demon_form': ({'cheap'}, {'cheap', 'quick', 'eco'}),
  'metallicize': ({'cheap'}, {'cheap', 'quick', 'eco'}),
```

(*Concentration* et *Focalisation*, à 0 Mana, ne changent pas : *Allégé* veut un coût d'au moins 1.) Then replace `/// Les huit runes livrées, et l'offre qu'elles font aux 23 cartes livrées` with `/// Les onze runes livrées, et l'offre qu'elles font aux 23 cartes livrées`.

In `test/unit/rune_resolution_test.dart`, replace:

```dart
  group('les statuts des runes : addStatus, sans source (spec E0, A4)', () {
```

with:

```dart
  // Les trois runes neuves, sur les vraies cartes (spec P-43 E2, §4.1, §4.2).
  group('Allege, Precis et Spectral', () {
    test('Allege : la Frappe ne coute plus de mana', () {
      play(card('strike_basic', runes: const ['cheap:1']));
      expect(hero().currentMana, 9);
    });

    test('Precis : le critique de la carte s ajoute a celui du heros', () {
      // 50 % du heros et 50 % de Precis 10 : le coup est critique, x1,5.
      run.updateState(run.currentState
          .copyWith(heroStats: hero().copyWith(critChance: 50)));
      play(card('strike_basic', runes: const ['precise:10']));
      expect(enemy().currentPv, 100 - 9);
    });

    test('Spectral 1 sur une Frappe commune : +40 % de la base, +2', () {
      play(card('strike_basic', runes: const ['spectral:1']));
      expect(enemy().currentPv, 100 - (6 + 2));
    });
  });

  group('les statuts des runes : addStatus, sans source (spec E0, A4)', () {
```

In `test/unit/deck_controller_test.dart`, replace:

```dart
      shippedRuneRegistry(const ['enduring']);
```

with:

```dart
      shippedRuneRegistry(const ['enduring', 'spectral']);
```

Then replace:

```dart
    test('un pouvoir est epuise meme s il porte Persistant', () {
```

with:

```dart
    // D33, A10 : la carte s'epuise, meme portant Persistant.
    test('Spectral epuise la carte, meme portant Persistant', () {
      final plain = cardWith(isExhaust: false, runes: const ['spectral:1']);
      final both =
          cardWith(runes: const ['enduring:1', 'spectral:1']);
      play(plain);
      play(both);
      expect(notifier.state.exhaustPile, [plain, both]);
      expect(notifier.state.discardPile, isEmpty);
    });

    test('un pouvoir est epuise meme s il porte Persistant', () {
```

In `test/unit/referential_integrity_test.dart`, replace:

```dart
import 'package:roguelike_card_game/services/game_data_service.dart';
```

with:

```dart
import 'package:roguelike_card_game/services/game_data_service.dart';
import 'package:roguelike_card_game/ui/widgets/forge/rune_style.dart';
```

Then replace:

```dart
  test('chaque id d excludesRunes designe une rune livree', () {
```

with:

```dart
  // Un nom que les tables ne connaissent pas retomberait en silence sur du
  // gris et une icone d'aide (spec P-43 E2, A19).
  test('chaque icone et chaque couleur de rune livree est connue des tables',
      () {
    final offenders = [
      for (final rune in registry.forgeUpgrades) ...[
        if (!runeIcons.containsKey(rune.icon)) '${rune.id} → icone "${rune.icon}"',
        if (!runeColors.containsKey(rune.color))
          '${rune.id} → couleur "${rune.color}"',
      ],
    ];

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('chaque id d excludesRunes designe une rune livree', () {
```

In `test/unit/real_bundle_load_test.dart`, replace `    expect(countUnder('assets/data/forge_upgrades/', 4), 8, reason: 'forge');` with `    expect(countUnder('assets/data/forge_upgrades/', 4), 11, reason: 'forge');`, `    expect(registry.forgeUpgrades, hasLength(8));` with `    expect(registry.forgeUpgrades, hasLength(11));`, and `      ['eco', 'enduring', 'freezing', 'quick'],` (Task 4) with `      ['cheap', 'eco', 'enduring', 'freezing', 'quick'],`.

In `test/unit/rune_ids_in_code_test.dart`, replace `    expect(runeIds, hasLength(8), reason: 'les huit runes livrees');` with `    expect(runeIds, hasLength(11), reason: 'les onze runes livrees');`.

In `test/unit/entity_id_convention_test.dart`, replace:

```dart
  test('il y a bien 85 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 8 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 85,
        reason: '17 cartes neutres + 25 reliques + 5 evenements + 8 '
```

with:

```dart
  test('il y a bien 88 fichiers d entite', () {
    // 17 cartes neutres + 25 reliques + 5 evenements + 11 ameliorations de
    // forge + 9 passifs + 8 recompenses de niveau + 3 class.json + 6 cartes
    // de classe + 4 enemy.json.
    expect(_entityFiles().length, 88,
        reason: '17 cartes neutres + 25 reliques + 5 evenements + 11 '
```

In `test/widget/deck_screen_test.dart` (la fusion de trois Frappes tire son offre sur tout le catalogue livré), replace:

```dart
    // Peu commune : Tranchant, Brulant, Congelant et Surcharge s'offrent ;
    // trois sont tirees.
```

with:

```dart
    // Peu commune : Tranchant, Brulant, Congelant, Surcharge, Allege, Precis
    // et Spectral s'offrent ; trois sont tirees.
```

and replace:

```dart
    expect(id, isIn(['sharp', 'burning', 'freezing', 'shocking']));
```

with:

```dart
    expect(
      id,
      isIn([
        'sharp',
        'burning',
        'freezing',
        'shocking',
        'cheap',
        'precise',
        'spectral',
      ]),
    );
```

In `test/tutorial/tutorial_engine_test.dart`, replace the comment:

```dart
      // Par la fonction du jeu, sur le registre du tutoriel (spec P-43 E2,
      // A18) : Tranchant, Brulant, Congelant et Surcharge s'offrent a une
      // Frappe peu commune, trois sont tirees.
```

with:

```dart
      // Par la fonction du jeu, sur le registre du tutoriel (spec P-43 E2,
      // A18) : Tranchant, Brulant, Congelant, Surcharge, Allege, Precis et
      // Spectral s'offrent a une Frappe peu commune, trois sont tirees.
```

- [ ] **Step 10: Lancer les tests des runes livrées pour les voir échouer**

Run: `flutter test test/unit/forge_upgrades_catalog_test.dart test/unit/rune_resolution_test.dart test/unit/deck_controller_test.dart`
Expected: FAIL — les trois fichiers n'existent pas (`shippedRune('spectral')` ne trouve pas son fichier, le registre n'a que huit runes) ; `referential_integrity_test.dart` ne compile pas encore (`rune_style.dart` manque).

- [ ] **Step 11: Les trois fichiers, les tables d'icônes et de couleurs**

Create `assets/data/forge_upgrades/cheap.json`:

```json
{
  "id": "cheap",
  "name_en": "Light",
  "name_fr": "Allégé",
  "description_en": "Costs {val} less Mana (never below 0)",
  "description_fr": "Coûte {val} Mana de moins (jamais sous 0)",
  "icon": "savings_rounded",
  "color": "tealAccent",
  "minFusionRank": 1,
  "requiresMinCost": 1,
  "excludesRunes": [
    "eco"
  ],
  "maxLevel": 1,
  "deltas": [
    {
      "type": "reduceCost",
      "valuePerLevel": 1
    }
  ],
  "weight": 50,
  "emoji": "🪙"
}
```

Create `assets/data/forge_upgrades/precise.json`:

```json
{
  "id": "precise",
  "name_en": "Precise",
  "name_fr": "Précis",
  "description_en": "+{val}% critical chance on the card's damage",
  "description_fr": "+{val}% de chance de critique sur les dégâts de la carte",
  "icon": "gps_fixed_rounded",
  "color": "pinkAccent",
  "minFusionRank": 1,
  "eligibleEffects": [
    "damage"
  ],
  "maxLevel": 10,
  "deltas": [
    {
      "type": "critBonus",
      "valuePerLevel": 5
    }
  ],
  "weight": 50,
  "emoji": "🎯"
}
```

Create `assets/data/forge_upgrades/spectral.json`:

```json
{
  "id": "spectral",
  "name_en": "Spectral",
  "name_fr": "Spectral",
  "description_en": "+{val} Damage on the card (+{percent}% of base, at least +{tier}); the card exhausts",
  "description_fr": "+{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier}) ; la carte s'épuise",
  "icon": "blur_on_rounded",
  "color": "purpleAccent",
  "minFusionRank": 1,
  "eligibleEffects": [
    "damage"
  ],
  "maxLevel": null,
  "deltas": [
    {
      "type": "percentBonus",
      "effect": "damage",
      "valuePercentPerLevel": 40
    },
    {
      "type": "addExhaust"
    }
  ],
  "weight": 50,
  "emoji": "👻"
}
```

Le contenu est celui de la spec (§3.1, §3.2, §5.1), sur la mise en page des huit fichiers voisins. **Aucun des trois ne porte `eligibleCardTypes`** : le script de simulation le lit (spec §9).

Create `lib/ui/widgets/forge/rune_style.dart`:

```dart
import 'package:flutter/material.dart';

/// Les icônes que nomme le champ `icon` d'une rune (spec P-43 E2, A19). Un
/// nom absent retombe sur `Icons.help_outline` ; le test d'intégrité exige
/// que chaque rune livrée ait le sien.
const Map<String, IconData> runeIcons = {
  'hardware_rounded': Icons.hardware_rounded,
  'shield_rounded': Icons.shield_rounded,
  'local_fire_department_rounded': Icons.local_fire_department_rounded,
  'ac_unit_rounded': Icons.ac_unit_rounded,
  'flash_on_rounded': Icons.flash_on_rounded,
  'style_rounded': Icons.style_rounded,
  'diamond_rounded': Icons.diamond_rounded,
  'hourglass_bottom_rounded': Icons.hourglass_bottom_rounded,
  'savings_rounded': Icons.savings_rounded,
  'gps_fixed_rounded': Icons.gps_fixed_rounded,
  'blur_on_rounded': Icons.blur_on_rounded,
};

/// Les couleurs que nomme le champ `color` d'une rune (spec P-43 E2, A19). Un
/// nom absent retombe sur le gris ; le test d'intégrité exige que chaque rune
/// livrée ait la sienne.
const Map<String, Color> runeColors = {
  'redAccent': Colors.redAccent,
  'blueAccent': Colors.blueAccent,
  'orangeAccent': Colors.orangeAccent,
  'lightBlueAccent': Colors.lightBlueAccent,
  'amberAccent': Colors.amberAccent,
  'amber': Colors.amber,
  'cyanAccent': Colors.cyanAccent,
  'greenAccent': Colors.greenAccent,
  'tealAccent': Colors.tealAccent,
  'pinkAccent': Colors.pinkAccent,
  'purpleAccent': Colors.purpleAccent,
};
```

In `lib/ui/widgets/forge/forge_slot_row.dart`, replace:

```dart
import '../game_button.dart';
```

with:

```dart
import '../game_button.dart';
import 'rune_style.dart';
```

Then delete the two private methods `_getUpgradeColorFromString` and `_getUpgradeIconFromString` (`:32-76`) — from `  Color _getUpgradeColorFromString(String colorStr) {` up to and including the blank line before `  @override` — and replace:

```dart
    final color = _getUpgradeColorFromString(rune.color);
    final icon = _getUpgradeIconFromString(rune.icon);
```

with:

```dart
    // Un nom inconnu retombe sur du gris et une icône d'aide (A19).
    final color = runeColors[rune.color] ?? Colors.grey;
    final icon = runeIcons[rune.icon] ?? Icons.help_outline;
```

In `lib/services/content_editor/entity_descriptor.dart`, replace:

```dart
    // `color` et `icon` ne sont pas un hex ni un texte libre : ce sont des
    // noms que `forge_slot_row.dart` traduit un a un (`amberAccent`,
    // `flash_on_rounded`), et un nom inconnu y retombe en silence sur du gris
    // et `Icons.help_outline`. Les huit ameliorations livrees les emploient.
```

with:

```dart
    // `color` et `icon` ne sont pas un hex ni un texte libre : ce sont des
    // noms que `runeColors` et `runeIcons` (`lib/ui/widgets/forge/
    // rune_style.dart`) traduisent un a un (`amberAccent`,
    // `flash_on_rounded`), et un nom inconnu y retombe sur du gris et
    // `Icons.help_outline` ; le test d'integrite exige que chaque rune livree
    // ait les siens (spec P-43 E2, A19). Les onze runes livrees les emploient.
```

- [ ] **Step 12: Lancer les tests des runes livrées pour les voir passer**

Run: `flutter test test/unit/forge_upgrades_catalog_test.dart test/unit/rune_resolution_test.dart test/unit/deck_controller_test.dart test/unit/referential_integrity_test.dart test/unit/real_bundle_load_test.dart test/unit/rune_ids_in_code_test.dart test/unit/entity_id_convention_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart test/widget/deck_screen_test.dart`
Expected: PASS — le catalogue compte 53 cas (11 déclarations, les clés lues, la couverture, 34 de matrice, 6 signatures) ; les onze runes valident dans l'éditeur et se réécrivent à l'identique.

- [ ] **Step 13: Analyse, suite et contrôles**

Run: `dart analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: `+1475: All tests passed!` (1453 + 22 : 5 du modèle, 6 de l'applicateur, 2 de la chaîne de dégâts, 1 du prédicat, 3 de la résolution, 1 de l'épuisement, 1 d'intégrité, 3 du catalogue).

Run: `git grep -nE "['\"](sharp|hardened|quick|eco|burning|freezing|shocking|enduring|cheap|precise|spectral)['\"]" -- lib`
Expected: aucune sortie.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0 — les trois fichiers entrent dans un dossier déjà déclaré.

- [ ] **Step 14: Commit**

```bash
git add lib/models/data/card_delta.dart lib/models/effective_card.dart lib/models/card_instance.dart lib/game/services/damage_pipeline.dart lib/game/services/effects/strategies.dart lib/game/services/forge_rune_rules.dart lib/models/data/forge_upgrade_data.dart lib/ui/widgets/forge/rune_style.dart lib/ui/widgets/forge/forge_slot_row.dart lib/services/content_editor/entity_descriptor.dart assets/data/forge_upgrades/cheap.json assets/data/forge_upgrades/precise.json assets/data/forge_upgrades/spectral.json test/unit/forge_upgrade_data_test.dart test/unit/effective_card_test.dart test/unit/damage_pipeline_test.dart test/unit/rune_eligibility_test.dart test/unit/rune_resolution_test.dart test/unit/deck_controller_test.dart test/unit/referential_integrity_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/real_bundle_load_test.dart test/unit/rune_ids_in_code_test.dart test/unit/entity_id_convention_test.dart test/widget/deck_screen_test.dart test/tutorial/tutorial_engine_test.dart
git commit -F - <<'EOF'
feat(runes): Allege, Precis et Spectral rejoignent les huit runes

Trois sortes de delta, une par mecanisme : reduceCost baisse le cout,
plancher 0 ; critBonus ajoute au critique de la carte, que DamagePipeline
recoit ; addExhaust epuise la carte et l emporte sur removeExhaust.
currentCost et exhaustsOnPlay lisent l applicateur, le predicat juge le
cout sur le catalogue recu. Les trois fichiers entrent au poids 50, sans
types de carte ; runeIcons et runeColors sortent de la ligne de rune.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 7: Le badge « Usage unique » dit vrai, les prises ne chevauchent plus les effets, l'infobulle nomme les runes

Trois points qui touchent les rendus de la carte. **A13** : les quatre lecteurs qui disaient l'épuisement d'après la donnée seule — le badge Flame (`card_text_renderer.dart:415`), l'avertissement de l'infobulle Flame (`card_component.dart:340`), les particules (`card_animator.dart:157`) et le badge Flutter (`ui_card.dart:76`) — lisent `CardInstance.exhaustsOnPlay` ; les particules continuent d'ignorer les pouvoirs. Le badge apparaît sur une carte *Spectrale* et quitte une carte *Persistante*. **Le débordement des prises** (S6 ; mesure dans « Ce que le plan précise », n° 13) : le bloc central de la carte de combat — description ou effets — ne monte plus au-dessus du bas de l'en-tête (prises de rune et badge), par une fonction pure, `CardTextRenderer.centerBlockTop`, que teste un test unitaire (le rendu Flame n'a pas de test de widget). **L'en-tête « ⚙️ Upgrades: »** de l'infobulle Flutter (`ui_card_helpers.dart:423`, S6), en anglais dans les deux langues, devient `⚙️ ` + une clé ARB neuve, `tooltipRunes` (« Runes : » / « Runes: ») — le traitement de §5.7, sous la règle ARB de §5.3 ; son jumeau Flame dit déjà « === RUNES === ».

Changements de jeu de la tâche, voulus : le badge dit la règle que joue le moteur (note de version, spec §11) ; sur une carte qui porte six runes ou plus et *Spectral*, les effets descendent sous le badge au lieu de le chevaucher.

**Files:**
- Modify: `lib/game/components/widgets/card_text_renderer.dart:1` (import), `:414-416`, `:436-445`, `:465`, avant `:532`
- Modify: `lib/game/components/card_component.dart:340`
- Modify: `lib/game/components/visual_effects/card_animator.dart:157`
- Modify: `lib/ui/widgets/ui_card.dart:76`
- Modify: `lib/ui/widgets/ui_card/ui_card_helpers.dart:423`
- Modify: `lib/l10n/app_en.arb:524` ; `lib/l10n/app_fr.arb:218` ; régénérés : les trois `lib/l10n/app_localizations*.dart`
- Test: `test/widget/ui_card_values_test.dart:55`, à la fin (trois cas)
- Test: `test/unit/card_text_renderer_layout_test.dart` (nouveau)

**Interfaces:**
- Consumes: `CardInstance.exhaustsOnPlay` (Task 6).
- Produces: `static double CardTextRenderer.centerBlockTop({required double cardHeight, required double blockHeight, required double headerBottom})` → `max(headerBottom, cardHeight / 2 - blockHeight / 2 + 5)` ; la clé ARB `tooltipRunes`.

- [ ] **Step 1: Écrire les tests qui échouent**

In `test/widget/ui_card_values_test.dart`, replace:

```dart
  setUpAll(() => shippedRuneRegistry(const ['sharp', 'quick']));
```

with:

```dart
  setUpAll(() => shippedRuneRegistry(
      const ['enduring', 'quick', 'sharp', 'spectral']));
```

Then, at the end of the file, replace the closing lines of the last test and of `main`:

```dart
    final tooltip = _tooltip(tester);
    expect(tooltip, contains('Véloce : Pioche +1 carte(s)'));
    expect(tooltip, isNot(contains('Véloce 1')));
  });
}
```

with:

```dart
    final tooltip = _tooltip(tester);
    expect(tooltip, contains('Véloce : Pioche +1 carte(s)'));
    expect(tooltip, isNot(contains('Véloce 1')));
  });

  // Spec P-43 E2, §5.7 : l'en-tete nomme les runes, plus la forge.
  testWidgets('l infobulle ouvre les runes par leur nom', (tester) async {
    await _pumpCard(
      tester,
      CardInstance(
        data: shippedCard('strike_basic'),
        forgeUpgrades: const ['quick:1'],
      ),
    );

    final tooltip = _tooltip(tester);
    expect(tooltip, contains('⚙️ Runes :'));
    expect(tooltip, isNot(contains('Upgrades')));
  });

  // Le badge dit la regle que joue le moteur (spec P-43 E2, A13).
  group('le badge Usage unique', () {
    testWidgets('une carte Spectrale le montre', (tester) async {
      await _pumpCard(
        tester,
        CardInstance(
          data: shippedCard('strike_basic'),
          rarity: CardRarity.uncommon,
          forgeUpgrades: const ['spectral:1'],
        ),
      );
      expect(find.text('USAGE UNIQUE'), findsOneWidget);
    });

    testWidgets('une Potion de Soin Persistante ne le montre plus',
        (tester) async {
      await _pumpCard(
        tester,
        CardInstance(
          data: shippedCard('heal_potion'),
          rarity: CardRarity.uncommon,
          forgeUpgrades: const ['enduring:1'],
        ),
      );
      expect(find.text('USAGE UNIQUE'), findsNothing);
    });
  });
}
```

Create `test/unit/card_text_renderer_layout_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/widgets/card_text_renderer.dart';

/// Le bloc central de la carte de combat ne chevauche plus l'en-tête : neuf
/// runes font deux rangées de prises, et `spectral` montre le badge « Usage
/// unique » sur une attaque (spec P-43 E2, partie 2).
void main() {
  test('le bloc central reste centre tant que l en-tete le laisse', () {
    // 196 de haut, un bloc de 22 : centre a 98 - 11 + 5 = 92.
    expect(
      CardTextRenderer.centerBlockTop(
        cardHeight: 196,
        blockHeight: 22,
        headerBottom: 70,
      ),
      92,
    );
  });

  // Review Focus 5.
  test('il descend sous les prises et le badge quand ils le depassent', () {
    expect(
      CardTextRenderer.centerBlockTop(
        cardHeight: 196,
        blockHeight: 34,
        headerBottom: 99.5,
      ),
      99.5,
    );
  });
}
```

- [ ] **Step 2: Lancer les tests pour les voir échouer**

Run: `flutter test test/widget/ui_card_values_test.dart test/unit/card_text_renderer_layout_test.dart`
Expected: FAIL — `centerBlockTop` n'est pas défini ; l'infobulle dit « ⚙️ Upgrades: » ; le badge suit la donnée (absent sur la Frappe *Spectrale*, présent sur la *Potion* *Persistante*).

- [ ] **Step 3: Les quatre lecteurs de l'épuisement**

In `lib/game/components/widgets/card_text_renderer.dart`, replace:

```dart
    // Badge Usage Unique (fixe)
    final showExhaustBadge = card.card.data.isExhaust || card.card.data.type == CardType.power;
```

with:

```dart
    // Badge Usage Unique (fixe) : la carte s'épuise-t-elle, runes comprises
    // (spec P-43 E2, A13) ?
    final showExhaustBadge = card.card.exhaustsOnPlay;
```

In `lib/game/components/card_component.dart`, replace:

```dart
    if (card.data.type == CardType.power || card.data.isExhaust) {
```

with:

```dart
    if (card.exhaustsOnPlay) {
```

In `lib/game/components/visual_effects/card_animator.dart`, replace:

```dart
      if (card.card.data.isExhaust) {
        spawnExhaustParticles(card.position);
```

with:

```dart
      // Les runes comprises (spec P-43 E2, A13) ; un pouvoir, comme
      // aujourd'hui, sans particules.
      if (card.card.exhaustsOnPlay && card.card.data.type != CardType.power) {
        spawnExhaustParticles(card.position);
```

In `lib/ui/widgets/ui_card.dart`, replace:

```dart
      isExhaust: card.data.isExhaust,
```

with:

```dart
      isExhaust: card.exhaustsOnPlay,
```

(`UiCard.fromData`, `:106`, lit `card.isExhaust` d'une `CardData` sans instance : aucun appelant ne lui passe de rune — inchangé.)

- [ ] **Step 4: Le bloc central sous l'en-tête**

In `lib/game/components/widgets/card_text_renderer.dart`, replace:

```dart
import 'package:flame/components.dart';
```

with:

```dart
import 'dart:math' show max;

import 'package:flame/components.dart';
```

Then replace:

```dart
    // Le badge de ciblage textuel a été supprimé.

    // Description (centrée parfaitement sur la carte)
    if (descPainter != null) {
      descPainter!.paint(
        canvas,
        Offset(
          size.x / 2 - descPainter!.width / 2,
          (size.y / 2) - descPainter!.height / 2 + 5,
        ),
      );
```

with:

```dart
    // Le badge de ciblage textuel a été supprimé.

    // Le bas de l'en-tête : les prises de rune, puis le badge.
    final headerBottom = currentY + (showExhaustBadge ? 14 + spacing : 0);

    // Description (centrée sur la carte, sous l'en-tête)
    if (descPainter != null) {
      descPainter!.paint(
        canvas,
        Offset(
          size.x / 2 - descPainter!.width / 2,
          centerBlockTop(
            cardHeight: size.y,
            blockHeight: descPainter!.height,
            headerBottom: headerBottom,
          ),
        ),
      );
```

Then replace:

```dart
      double startY = (size.y / 2) - maxHeight / 2 + 5;
```

with:

```dart
      double startY = centerBlockTop(
        cardHeight: size.y,
        blockHeight: maxHeight,
        headerBottom: headerBottom,
      );
```

Then replace:

```dart
  /// L'emoji d'une rune, par l'analyseur unique des références (spec P-43
```

with:

```dart
  /// Le haut du bloc central — la description ou les effets — de hauteur
  /// [blockHeight] : centré sur la carte, mais jamais au-dessus de
  /// [headerBottom], le bas des prises de rune et du badge « Usage unique ».
  /// Une carte porte jusqu'à neuf runes — deux rangées de prises — et
  /// `spectral` montre le badge sur une attaque (spec P-43 E2, partie 2).
  static double centerBlockTop({
    required double cardHeight,
    required double blockHeight,
    required double headerBottom,
  }) =>
      max(headerBottom, cardHeight / 2 - blockHeight / 2 + 5);

  /// L'emoji d'une rune, par l'analyseur unique des références (spec P-43
```

Le badge occupe 14 px à partir de `currentY` (`:418-422`) ; le type de carte reste en bas, à y = 175 (`:529`), sous tout bloc central que la borne peut faire descendre.

- [ ] **Step 5: L'en-tête des runes de l'infobulle Flutter**

In `lib/l10n/app_en.arb`, replace:

```json
  "fusionRuneChoose": "Choose",
```

with:

```json
  "fusionRuneChoose": "Choose",
  "tooltipRunes": "Runes:",
```

In `lib/l10n/app_fr.arb`, replace:

```json
  "fusionRuneChoose": "Choisir",
```

with:

```json
  "fusionRuneChoose": "Choisir",
  "tooltipRunes": "Runes :",
```

Run: `flutter gen-l10n`

In `lib/ui/widgets/ui_card/ui_card_helpers.dart`, replace:

```dart
    desc += '\n⚙️ Upgrades:\n${upgradeDescs.map((u) => '• $u').join('\n')}\n';
```

with:

```dart
    desc += '\n⚙️ ${l10n.tooltipRunes}\n'
        '${upgradeDescs.map((u) => '• $u').join('\n')}\n';
```

(`l10n` est déjà lu en tête de `buildDetailedDescription`, `:256`.)

- [ ] **Step 6: Lancer les tests pour les voir passer**

Run: `flutter test test/widget/ui_card_values_test.dart test/unit/card_text_renderer_layout_test.dart`
Expected: PASS — 9 cas pour la carte, 2 pour le bloc central.

- [ ] **Step 7: Analyse, suite et commande de contrôle d'A13**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n "data.isExhaust" -- lib/game/components lib/ui`
Expected: aucune sortie — les quatre lecteurs lisent `exhaustsOnPlay` (spec A13). Le prédicat, qui lit à bon droit l'épuisement de la donnée pour `requiresExhaust`, est hors de ces deux dossiers.

Run: `git grep -n " Upgrades:" -- lib`
Expected: aucune sortie.

Run: `flutter test`
Expected: `+1480: All tests passed!` (1475 + 5).

- [ ] **Step 8: Commit**

```bash
git add lib/game/components/widgets/card_text_renderer.dart lib/game/components/card_component.dart lib/game/components/visual_effects/card_animator.dart lib/ui/widgets/ui_card.dart lib/ui/widgets/ui_card/ui_card_helpers.dart lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart test/widget/ui_card_values_test.dart test/unit/card_text_renderer_layout_test.dart
git commit -F - <<'EOF'
fix(carte): le badge Usage unique dit vrai, les prises ne chevauchent plus les effets

Les quatre lecteurs de l epuisement lisent exhaustsOnPlay : le badge
apparait sur une carte Spectrale et quitte une carte Persistante. Le bloc
central de la carte de combat ne monte plus au-dessus des prises de rune
et du badge, deux rangees de prises comprises. L infobulle ouvre ses runes
par une cle traduite au lieu de Upgrades.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 8: La simulation lit ses runes par une liste d'ordre explicite (premier temps)

Le script de simulation tire ses runes **par index**, rangées « fichiers triés, puis entrées en dur » (`d26_economy_sim.dart:822-859`). Les trois fichiers de Task 6 y entreraient deux fois — par la branche par défaut du `switch` (`:845`), sans leur condition, et par leurs entrées en dur (`:850`, `:854`, `:858`) —, rangés au milieu des huit : mesuré, le script d'aujourd'hui lit « 20 runes » sur la donnée de la vague. Le réalignement (spec §9 ; orchestration §3.6, §7.3 ligne 2 ; D73) : une **liste d'ordre explicite des 17 ids**, dans l'ordre d'aujourd'hui ; pour chacun, le fichier s'il existe — `weight` et `eligibleCardTypes` lus comme aujourd'hui, `needs` et `excludes` donnés par le `switch`, qui gagne trois cas reproduisant les entrées en dur (`cheap` : `cost1`, `excludes: ['eco']` ; `precise`, `spectral` : `damage`) —, l'entrée en dur sinon ; un fichier dont l'id n'est pas dans la liste lève une erreur. Les trois entrées en dur que les fichiers remplacent disparaissent : chaque fichier prend leur place exacte, même liste, même position, même définition. **Aucune valeur que le script tient en dur ne change.** Le commentaire d'en-tête, qui dit encore le script « jetable … ni committé », est corrigé, à la demande de l'orchestrateur : le script est suivi par git depuis le 01/10, et sa sortie de référence aussi (« Ce que le plan précise », n° 10).

La tâche vient après toute tâche qui touche `assets/data/` (Tasks 4, 5, 6) ; **aucune ne la suit**. Sa fumée est un diff : `--quick` du script et de la donnée d'avant la partie 2, puis `--quick` du script réaligné sur la donnée de la vague, doivent être **identiques à l'octet** — ligne « Données lues » comprise : elle compte les runes, 17 des deux côtés (`:3840`). La mesure complète est l'affaire de l'orchestrateur (spec §9).

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:3-5` (en-tête), `:822-859` (le chargement des runes)

**Interfaces:**
- Consumes: les fichiers `assets/data/forge_upgrades/*.json` (`id`, `weight`, `eligibleCardTypes`) ; `RuneDef(String id, int weight, {List<String> types, String needs, List<String> excludes})`.
- Produces: `GameData.runes`, les mêmes 17 `RuneDef` dans le même ordre qu'avant la vague.

- [ ] **Step 1: Mesurer l'avant**

`<base>` est le commit qui **ajoute** ce plan — un commit ultérieur sur le plan ne le déplace pas — : `git log --diff-filter=A --format=%H -- docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-2.md`. **L'orchestrateur commite le plan avant la Task 1** ; si la commande ne rend rien, `<base>` est `5f1c3b3`, la tête de la branche quand le plan a été écrit. À ce commit, la donnée est celle d'avant la partie 2 et le script celui d'aujourd'hui. `<tmp>` est un dossier temporaire **hors du dépôt** (le dossier de travail temporaire de la session).

Run: `mkdir -p <tmp>/d26_avant && git archive <base> tool/simulations assets/data | tar -x -C <tmp>/d26_avant`
Run, depuis `<tmp>/d26_avant` : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_avant.md`
Expected: environ une minute ; la ligne `écrit : <tmp>/d26_avant.md` sur la sortie d'erreur ; `<tmp>/d26_avant.md` porte « Données lues : 4 ennemis, 17 neutres (noyau de 9), 25 reliques (+ 4 du brainstorm), 8 récompenses de niveau, 17 runes, 5 événements (+ 3 du brainstorm). » Le script n'importe que des bibliothèques `dart:` et trouve `assets/data/` en remontant depuis son propre dossier (`:401-408`) : il tourne hors de tout paquet, sur la donnée extraite.

- [ ] **Step 2: Réaligner**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
// Script JETABLE, hors du code du jeu : ni déclaré dans pubspec.yaml, ni
// importé par lib/, ni committé. Il n'importe rien de lib/ : Flame, donc
// Flutter, refuse `dart run`. Les FORMULES du jeu y sont portées, chacune
```

with:

```dart
// Script hors du code du jeu, suivi par git avec sa sortie de référence
// (d26_reference_output.md, à côté) : ni déclaré dans pubspec.yaml, ni
// importé par lib/, ni un test. Il n'importe rien de lib/ : Flame, donc
// Flutter, refuse `dart run`. Les FORMULES du jeu y sont portées, chacune
```

Then replace:

```dart
    // Les runes : les 8 d'aujourd'hui (poids et types lus dans la donnée),
    // plus celles du §8. Éligibilité en donnée (D44).
    final runes = <RuneDef>[];
    for (final f in _jsonFiles('$root/forge_upgrades')) {
      final j = _json(f.path);
      final id = j['id'] as String;
      final weight = j['weight'] as int? ?? 50;
      final types = [for (final t in (j['eligibleCardTypes'] as List? ?? const [])) t as String];
      runes.add(switch (id) {
```

with:

```dart
    // Les runes, dans l'ordre que la référence a mesuré — les huit fichiers
    // d'avant E2 triés, puis les neuf du §8 — : la liste est tirée par index,
    // et un fichier neuf rangé au milieu décalerait tous les tirages (D73 ;
    // spec P-43 E2, §9). Chacune vient de son fichier s'il existe — poids et
    // types lus dans la donnée, condition et exclusions données par le
    // `switch` —, de son entrée en dur sinon. Éligibilité en donnée (D44).
    const runeOrder = [
      'burning', 'eco', 'enduring', 'freezing', 'hardened', 'quick', 'sharp',
      'shocking', 'cheap', 'piercing', 'lifesteal', 'transfusion', 'precise',
      'splash', 'echo', 'retain', 'spectral',
    ];
    // §8 — les runes sans fichier. DÉFAUT : poids 50, `minFusionRank` 1.
    const hardRunes = {
      'piercing': RuneDef('piercing', 50, needs: 'damage'),
      'lifesteal': RuneDef('lifesteal', 50, needs: 'damage'),
      'transfusion': RuneDef('transfusion', 50, needs: 'hpCost'), // D40
      'splash': RuneDef('splash', 50, needs: 'singleDamage'),
      'echo': RuneDef('echo', 50),
      'retain': RuneDef('retain', 50),
    };
    final fromFiles = <String, RuneDef>{};
    for (final f in _jsonFiles('$root/forge_upgrades')) {
      final j = _json(f.path);
      final id = j['id'] as String;
      if (!runeOrder.contains(id)) {
        throw StateError('rune « $id » (${f.path}) absente de runeOrder : '
            'lui donner sa place dans la liste tirée par index');
      }
      final weight = j['weight'] as int? ?? 50;
      final types = [for (final t in (j['eligibleCardTypes'] as List? ?? const [])) t as String];
      fromFiles[id] = switch (id) {
```

Then replace:

```dart
        'enduring' => RuneDef(id, weight,
            types: types, needs: 'exhaustNoEngine', excludes: const ['eco', 'quick']),
        _ => RuneDef(id, weight, types: types),
      });
    }
    // §8 — runes nouvelles. DÉFAUT : poids 50, `minFusionRank` 1.
    runes.addAll(const [
      RuneDef('cheap', 50, needs: 'cost1', excludes: ['eco']),
      RuneDef('piercing', 50, needs: 'damage'),
      RuneDef('lifesteal', 50, needs: 'damage'),
      RuneDef('transfusion', 50, needs: 'hpCost'), // D40
      RuneDef('precise', 50, needs: 'damage'),
      RuneDef('splash', 50, needs: 'singleDamage'),
      RuneDef('echo', 50),
      RuneDef('retain', 50),
      RuneDef('spectral', 50, needs: 'damage'),
    ]);
```

with:

```dart
        'enduring' => RuneDef(id, weight,
            types: types, needs: 'exhaustNoEngine', excludes: const ['eco', 'quick']),
        // §8, fichiers d'E2 (spec P-43 E2, §3.2) : la définition qu'avait leur
        // entrée en dur.
        'cheap' => RuneDef(id, weight, needs: 'cost1', excludes: const ['eco']),
        'precise' => RuneDef(id, weight, needs: 'damage'),
        'spectral' => RuneDef(id, weight, needs: 'damage'),
        _ => RuneDef(id, weight, types: types),
      };
    }
    final runes = [
      for (final id in runeOrder)
        fromFiles[id] ??
            hardRunes[id] ??
            (throw StateError('rune « $id » : ni fichier ni entrée en dur')),
    ];
```

Les trois cas neufs du `switch` ne passent pas `types:`, comme `sharp` et `hardened` : la définition de leur entrée en dur n'en avait pas. Leur `weight` vient du fichier, 50, celui de l'entrée en dur.

- [ ] **Step 3: Analyse**

Run: `dart analyze`
Expected: `No issues found!` — le script en fait partie (`CLAUDE.md`, « Tooling »).

- [ ] **Step 4: La fumée — un diff vide**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_apres.md`
Expected: environ une minute ; `écrit : <tmp>/d26_apres.md`.

Run: `git diff --no-index <tmp>/d26_avant.md <tmp>/d26_apres.md`
Expected: code de sortie 0, rien d'affiché — les deux sorties sont identiques, « 17 runes » compris. Tout écart est un réalignement faux : la tâche ne se commite pas.

- [ ] **Step 5: La suite**

Run: `flutter test`
Expected: `+1480: All tests passed!` — rien sous `lib/` ni `test/` n'a changé.

- [ ] **Step 6: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): le script lit ses runes par une liste d ordre explicite

Les 17 runes gardent l ordre que la reference a mesure : chacune vient de
son fichier s il existe, de son entree en dur sinon, et un fichier hors de
la liste leve une erreur. cheap, precise et spectral prennent la place
exacte de leur entree en dur. Aucune valeur jouee ne change : le mode
rapide rend la meme sortie qu avant la partie 2. L en-tete ne dit plus le
script jetable.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 9: Le `spectral` de la simulation suit D33 (second temps)

Le seul changement voulu du script, **dans une tâche à part, après le réalignement, et la dernière à toucher le script** (spec §9, A10 ; tranché par l'orchestrateur au tour 1). Le script multiplie aujourd'hui par `1 + 0,4 × niveau` la valeur par coup **Puissance et `sharp` compris**, dans l'estimation de l'IA (`:1700`, `:1702`), la résolution (`:1894`, `:1902`) et la valeur d'une pose (`:2202`). Le jeu suit D33 : +40 % de la valeur de base à la rareté, par niveau, au moins +1 par niveau, **ajoutés** à la valeur — jamais multipliant la Puissance, la part de `sharp` ni le terme `scaleWith`. `percentRuneBonus` prend le pourcentage `p` en paramètre et s'écrit **exactement** `max((p / 100 * level * cardValue).round(), level)` : `15 / 100` est le même flottant que le littéral `0.15`, et l'évaluation de gauche à droite garde les mêmes produits intermédiaires — `sharp` et `hardened` ne bougent pas au bit près (spec §9 : un autre ordre diffère sur 60 des 6 030 couples mesurés). L'épuisement (`:1849-1852`) et la pénalité que l'IA lui donne (`:2251`) ne changent pas.

Aucune tâche ne touche `assets/data/` ni le script après celle-ci. La fumée est un `--quick` qui se termine ; sa sortie **diffère** de celle de Task 8, c'est voulu. **L'orchestrateur** relance la mesure complète, explique l'écart et recommite la référence (orchestration §3.6, second temps).

**Files:**
- Modify: `tool/simulations/d26_economy_sim.dart:1262-1265` (`percentRuneBonus`), `:1640-1654` (`_perHit`, `_armorOf`), `:1699-1702` (`estimate`), `:1893-1902` (`_dealDamage`), `:2190-2208` (`staticValue`)

**Interfaces:**
- Consumes: `scaled(int base, int rank)` ; `CardInst.runes`.
- Produces: `int percentRuneBonus(int cardValue, int level, int p)` — quatre appelants à 15 (`sharp`, `hardened`), deux à 40 (`spectral`).

- [ ] **Step 1: La forme de D33**

In `tool/simulations/d26_economy_sim.dart`, replace:

```dart
/// Rune en pourcentage (D33, §8) : +15 % de la valeur de base de la carte
/// par niveau, au moins +1 par niveau.
int percentRuneBonus(int cardValue, int level) =>
    max((0.15 * level * cardValue).round(), level);
```

with:

```dart
/// Rune en pourcentage (D33, §8) : +[p] % de la valeur de base de la carte
/// par niveau, au moins +1 par niveau — `sharp` et `hardened` à 15,
/// `spectral` à 40 (spec P-43 E2, A10, §9). L'ordre des opérations est celui
/// d'avant le paramètre : `15 / 100` est le même flottant que `0.15`, et le
/// produit se fait de gauche à droite — `sharp` et `hardened` ne bougent pas
/// au bit près.
int percentRuneBonus(int cardValue, int level, int p) =>
    max((p / 100 * level * cardValue).round(), level);
```

Then replace:

```dart
  /// Valeur par coup avant Puissance : base au rang, part de `sharp` (D33),
  /// terme `scaleWith` jamais multiplié par la rareté (§9.2 #1).
  double _perHit(CardInst c, Eff e) {
    final base = scaled(e.value, c.rank);
    final sharp = c.runes['sharp'];
    final share =
        sharp == null ? 0.0 : percentRuneBonus(max(0, base) * e.hits, sharp) / e.hits;
    return base + share + _scaleTerm(e);
  }
```

with:

```dart
  /// Valeur par coup avant Puissance : base au rang, parts de `sharp` et de
  /// `spectral` (D33 ; spec P-43 E2, A10), terme `scaleWith` jamais multiplié
  /// par la rareté (§9.2 #1). Chaque part se calcule sur la base au rang,
  /// coups additionnés puis répartis ; aucune ne porte sur l'autre.
  double _perHit(CardInst c, Eff e) {
    final base = scaled(e.value, c.rank);
    final sharp = c.runes['sharp'];
    final spectral = c.runes['spectral'];
    final share = sharp == null
        ? 0.0
        : percentRuneBonus(max(0, base) * e.hits, sharp, 15) / e.hits;
    final spectralShare = spectral == null
        ? 0.0
        : percentRuneBonus(max(0, base) * e.hits, spectral, 40) / e.hits;
    return base + share + spectralShare + _scaleTerm(e);
  }
```

Then replace `    return base + (h == null ? 0 : percentRuneBonus(base, h));` (`_armorOf`) with `    return base + (h == null ? 0 : percentRuneBonus(base, h, 15));`.

Then, in `estimate`, replace:

```dart
        case 'damage':
          final spectral = 1 + 0.4 * (r['spectral'] ?? 0);
          for (final f in d.target == Tgt.all ? active : [tgt]) {
            var x = (_perHit(c, e) + mt * mightRatioOf(d, e, run.p)) * spectral;
```

with:

```dart
        case 'damage':
          for (final f in d.target == Tgt.all ? active : [tgt]) {
            var x = _perHit(c, e) + mt * mightRatioOf(d, e, run.p);
```

Then, in `_dealDamage`, replace:

```dart
    final mt = mightFor(c.def.type) * mightRatioOf(c.def, e, run.p);
    final spectral = 1 + 0.4 * (r['spectral'] ?? 0);
    final critChance = run.crit + 5 * (r['precise'] ?? 0);
```

with:

```dart
    final mt = mightFor(c.def.type) * mightRatioOf(c.def, e, run.p);
    final critChance = run.crit + 5 * (r['precise'] ?? 0);
```

and replace `        var x = (_perHit(c, e) + mt) * spectral;` with `        var x = _perHit(c, e) + mt;`.

Then, in `staticValue`, replace:

```dart
          final sharp = r['sharp'];
          final bonus = sharp == null ? 0 : percentRuneBonus(max(0, val) * e.hits, sharp);
```

with:

```dart
          final sharp = r['sharp'];
          final spectral = r['spectral'];
          final bonus = (sharp == null
                  ? 0
                  : percentRuneBonus(max(0, val) * e.hits, sharp, 15)) +
              (spectral == null
                  ? 0
                  : percentRuneBonus(max(0, val) * e.hits, spectral, 40));
```

then delete the line `          dmg *= 1 + 0.4 * (r['spectral'] ?? 0);` (`:2202`), and replace `          final a = val + (h == null ? 0 : percentRuneBonus(val, h));` with `          final a = val + (h == null ? 0 : percentRuneBonus(val, h, 15));`.

À 40 %, `0,4 × niveau × valeur` ne tombe jamais sur une demie exacte : l'arrondi du script et l'arithmétique entière du jeu (`(40 L B + 50) ~/ 100`) coïncident (spec §9).

- [ ] **Step 2: Analyse et contrôle**

Run: `dart analyze`
Expected: `No issues found!`

Run: `git grep -n -e "0.4 \* (r\['spectral'\]" -e "\* spectral" -- tool/simulations/d26_economy_sim.dart`
Expected: aucune sortie — les trois multiplications ont disparu.

Run: `git grep -n "percentRuneBonus(" -- tool/simulations/d26_economy_sim.dart`
Expected: sept lignes — la définition, quatre appels à 15, deux à 40.

- [ ] **Step 3: La fumée**

Run, depuis la racine du dépôt : `dart run tool/simulations/d26_economy_sim.dart --quick --out <tmp>/d26_spectral.md`
Expected: environ une minute ; `écrit : <tmp>/d26_spectral.md` ; la ligne « Données lues » dit toujours « 17 runes ». Un `git diff --no-index <tmp>/d26_apres.md <tmp>/d26_spectral.md` rend un écart : c'est le changement voulu, que l'orchestrateur mesure et explique.

- [ ] **Step 4: La suite**

Run: `flutter test`
Expected: `+1480: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add tool/simulations/d26_economy_sim.dart
git commit -F - <<'EOF'
chore(simulation): spectral suit D33, la Puissance hors du pourcentage

Le script multipliait la valeur par coup, Puissance et sharp compris, par
1 + 0,4 x niveau. Il ajoute desormais, comme le jeu, 40 pour cent de la
valeur de base au rang par niveau, au moins 1 par niveau, a cote de la
part de sharp. percentRuneBonus prend le pourcentage dans l ordre des
operations d avant : sharp et hardened ne bougent pas. La mesure complete
revient a l orchestrateur.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
```

---

### Task 10: Vérification finale

Rien à écrire ni à commiter : la tâche constate. Si une vérification échoue, la tâche qui possède le code la corrige par un commit neuf, et cette tâche se rejoue en entier. `<base>` désigne le commit qui **ajoute** ce plan : `git log --diff-filter=A --format=%H -- docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-2.md`. L'orchestrateur commite le plan avant la Task 1 ; si la commande ne rend rien, `<base>` est `5f1c3b3`.

**Files:** aucun.

**Interfaces:**
- Consumes: la partie 2 entière.
- Produces: la branche `feat/v0.5.4-p43-e2-fusion-forge`, E2 implémenté — rien de poussé, aucune PR. Suivent, hors de ce plan : les deux mesures complètes de la simulation par l'orchestrateur, puis la note de version et la mémoire (orchestration §3.6, §3.7).

- [ ] **Step 1: Analyse et suite**

Run: `dart analyze`
Expected: `No issues found!` — le script de simulation compris.

Run: `flutter test`
Expected: `+1480: All tests passed!` — 1426 + 54, dont `tutorial_isolation_test.dart` (ADR-081), `rune_ids_in_code_test.dart` (onze runes, aucun id en littéral dans `lib/`), `real_bundle_load_test.dart` (onze runes ; plafond 1 : `cheap`, `eco`, `enduring`, `freezing`, `quick`), `shipped_entities_round_trip_test.dart` (chaque fichier livré, les trois runes neuves comprises, se réécrit à l'identique) et `entity_id_convention_test.dart` (88 fichiers d'entité).

- [ ] **Step 2: Ce qui a disparu (spec §4.11, A3, A13)**

Run: `git grep -n -w pools -- lib test assets tool`
Expected: les homonymes seuls — le commentaire de `CardData.compareByDisplayOrder` (`lib/models/data/card_data.dart`, « les trois pools » d'affichage) et la variable locale de `test/unit/audio/flame_audio_backend_pool_test.dart`.

Run: `git grep -n -w stackable -- lib test assets tool`
Expected: une ligne, le commentaire de `StatusEffect.combine` (`lib/models/status_effect.dart`).

Run: `git grep -n -e forgeCapacity -e forgeCapacityAt -e baseMaxForgeUpgrades -- lib test assets tool`
Expected: aucune sortie.

Run: `git grep -n -e totalMaxForgeUpgrades -e 'totalSlots:' -e 'this.totalSlots' -e 'isStackable(' -e fusionOptionsFor -e FusionOption -e _capacity -- lib test`
Expected: aucune sortie.

Run: `git grep -n -e forgeSlots -e bonusForgeSlots -e forgeTargetCardId -e forgeTargetSessions -e setForgeSession -e clearForgeSession -e buyBonusForgeSlot -e ForgeBuySlotButton -e rerollCost -e resetForgeTarget -- lib test`
Expected: aucune sortie.

Run: `git grep -n -w ForgeSlot -- lib test`
Expected: aucune sortie.

Run: `git grep -n "data.isExhaust" -- lib/game/components lib/ui`
Expected: aucune sortie (A13).

Run: `git grep -n -e 'Forge de Fusion' -e 'Fusion Forge' -e 'FORGE DE FUSION' -e 'FUSION FORGE' -e ' Upgrades:' -e clearCloneOptions -- lib test`
Expected: aucune sortie — les textes de la forge de la partie 2 (§5.7) et l'en-tête renvoyé par S6.

- [ ] **Step 3: Les lecteurs que la spec attend**

Run: `git grep -n "drawRunes(" -- lib`
Expected: quatre lignes — la déclaration (`forge_rune_rules.dart`), l'offre de la fusion (`deck_screen.dart`), l'étape de fusion du tutoriel (`tutorial_engine.dart`), les pré-forgées (`shop_controller.dart`).

Run: `git grep -n "isEligible(" -- lib`
Expected: la déclaration, `drawRunes` et `wellOptions` dans `forge_rune_rules.dart`, le semis de l'étape de fusion dans `tutorial_engine.dart` — ni la boutique, ni un écran.

Run: `git grep -n -e "wellOptions(" -e "exchangeRune(" -- lib`
Expected: `forge_rune_rules.dart` (la déclaration), `gold_manager.dart`, `run_controller.dart` et `forge_fusion_screen.dart`.

Run: `git grep -nE "['\"](sharp|hardened|quick|eco|burning|freezing|shocking|enduring|cheap|precise|spectral)['\"]" -- lib`
Expected: aucune sortie.

- [ ] **Step 4: La donnée, la simulation, ce qui ne se touche pas**

Run: `git diff <base>..HEAD --name-only -- assets`
Expected: exactement les onze fichiers de `assets/data/forge_upgrades/` — les huit d'avant et `cheap.json`, `precise.json`, `spectral.json`.

Run: `git diff <base>..HEAD -- assets/data/forge_upgrades/burning.json assets/data/forge_upgrades/eco.json assets/data/forge_upgrades/enduring.json assets/data/forge_upgrades/freezing.json assets/data/forge_upgrades/hardened.json assets/data/forge_upgrades/quick.json assets/data/forge_upgrades/sharp.json assets/data/forge_upgrades/shocking.json | grep -E '^[-+] ' | grep -vE '^-  "pools": \[$|^-    "(common|uncommon|rare)",?$|^-  \],$|^-  "stackable": false,$|^[-+]  "description_(en|fr)": '`
Expected: aucune sortie — dans les huit fichiers d'avant, seuls le bloc de pool, la clé de cumul d'`enduring` et les cinq descriptions ont changé : aucun `weight`, aucun élément d'`eligibleCardTypes`.

Run: `grep -c '"eligibleCardTypes"' assets/data/forge_upgrades/cheap.json assets/data/forge_upgrades/precise.json assets/data/forge_upgrades/spectral.json`
Expected: `0` pour chacun.

Run: `git diff --stat <base>..HEAD -- tool`
Expected: une ligne, `tool/simulations/d26_economy_sim.dart` — ni la référence, ni `sync_assets.dart`.

Run: `git diff --stat <base>..HEAD -- site assets/data/patch_notes.json pubspec.yaml macos linux windows`
Expected: aucune sortie — ni `site/`, ni la note de version, ni la version, ni un fichier généré de plateforme.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de sortie 0.

- [ ] **Step 5: L'arbre**

Run: `git status --short`
Expected: aucune sortie. Si des fichiers générés de plateforme apparaissent : `git restore macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`, puis relancer.

Run: `git log --oneline <base>..HEAD`
Expected: au moins les neuf commits des Tasks 1 à 9, plus les commits de correction éventuels. Rien n'est poussé.

---

## Ce que le plan laisse à l'orchestrateur

Hors des tâches, pour mémoire :

1. **Les deux mesures complètes de la simulation** (spec §9 ; orchestration §3.6). La première tourne sur le commit de Task 8, extrait hors du dépôt par `git archive <commit de Task 8> tool/simulations assets/data` ; diff vide attendu contre `tool/simulations/d26_reference_output.md`, ligne « Données lues » comprise (elle compte 17 runes). La seconde, sur le commit de Task 9 — qui est aussi l'état de la tête de branche pour ce que le script lit — ; son écart s'explique dans le compte rendu, et la référence est recommitée.
2. **Pour la note de version** (spec §11) : le Puits tous les trois actes ; la copie du deck ; l'étal retenu à son nœud, qui ferme un défaut antérieur (le retirage gratuit de l'étal entier, Miroir compris) ; les trois runes ; le badge qui dit vrai ; les pré-forgées tirées comme la fusion, sans ciblage par rareté (Task 2).
3. **Pour `memory-bank-sync`** (spec §11) : l'ADR neuf amende ADR-067, point 5 — le Miroir repart au nœud suivant, non plus à chaque sortie ; la boutique lit le nœud courant par un `ref.listen` (premier écouteur d'un Notifier de `lib/game/controllers/`) ; `ForgeSlotRow` est la ligne de rune des trois écrans, ses icônes et couleurs dans `rune_style.dart` ; le rendu Flame borne son bloc central sous l'en-tête (`CardTextRenderer.centerBlockTop`).
4. **À signaler au propriétaire** : *Précis* au niveau 10 ajoute 50 points de critique à la carte — un héros à 50 % critique alors à coup sûr ; c'est la table du brainstorm (§8, `maxLevel` 10), le plan ne la discute pas.
