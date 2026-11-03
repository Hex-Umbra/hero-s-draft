# P-42 tranche 1 et P-44 lot 1, partie 2 — La forme C et les trois lots — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, trois passifs se jouent avec leur lot de six cartes — *Régénération d'Armure* et le Rempart, *Rage* et le Sang, *Flux de Mana* et l'Arcaniste —, les six autres quittent la sélection, *Focalisation* a disparu, *Forme Démoniaque* est une carte du Sang ; les cartes disent sur leur face leurs coûts en PV et en Armure, leurs coups et leur croissance ; le draft de départ fait choisir 2 cartes du lot et 3 neutres, au jeu comme au tutoriel ; l'éditeur de contenu sait écrire une carte de lot. Les signatures restent celles d'E4.

**Architecture:** Une carte de lot se dit par `CardData.passive`, injecté par le répertoire (`cards/<passif>/<id>.json`, forme C) ; la source neutre l'injecte à `null`. Le prédicat d'offre unique devient `isOfferable(String? activePassiveId)` ; la disponibilité d'un passif devient « éligible et pourvu d'un lot », dans `availablePassivesFor`, sans liste en dur. Le vocabulaire de `feeds` et la règle « une carte de lot touche son passif, ne coûte pas d'Armure sous une classe qui la convertit » vivent dans deux fonctions pures du modèle, que lisent le chargeur, le test de données et l'éditeur. Le draft de départ devient une règle pure à deux groupes et deux quotas (`StarterDraft`), que lisent l'écran du jeu et celui du tutoriel. Les textes de coût, de coups et de croissance passent par un seul module de textes (`CardRuleTexts`), lu par les deux infobulles, Flutter et Flame.

**Tech Stack:** Flutter / Dart 3, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md` — §10 « Partie 2 » pour le périmètre ; §3.2 (la forme C), §3.3 (les passifs), §3.4 (les trois lots), §3.5 (les neutres), §4.8 (l'offre et le masquage), §4.9 et §5.3 (le draft de départ), §5.2 (les lignes marquées 2), §6.1 (les clés de la partie 2), §6.2 (le draft du tutoriel, `starterPool`, la leçon), §7 (les lignes marquées 2), §9 (les lignes marquées 2), §11 (`CLAUDE.md`, `README.md`). Les décisions de §1 — les réponses du propriétaire de §1.2 (dont Q9 et O5) et les arbitrages A1 à A34 de §1.3 — sont acquises : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md`.

Réponses du propriétaire reprises telles quelles (spec §1.2) : **Q9** — le draft de départ propose 2 cartes du lot du passif choisi et 3 neutres. **O5** — un passif dont le dossier `cards/<passif>/` est vide n'est pas proposé à la sélection : une règle dans `availablePassivesFor`, sans liste en dur. **Q8** — pas de carte-pont : chaque lot atteint ses six cartes seul.

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées (comme au plan de la partie 1) :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier, et la copie périmée d'un fichier disparu continue d'être chargée ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit (`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

S'y ajoutent :

- **jamais `git stash`, jamais `git commit --amend`** ; messages de commit en **ASCII**, sans accent.

Propres à cette partie :

- **La branche.** Le plan s'exécute sur `feat/v0.5.7-p42-tranche-1-p44-lot-1`, la branche courante, dans le checkout principal. Il ne crée aucune branche, n'en change pas, ne commite rien sur `main`, ne pousse rien. Pas de worktree. Le fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_…`) est modifié dans l'arbre de travail par l'orchestrateur : **ne jamais l'indexer**.
- **La base de tests** : `flutter test` rend **1811** sur la branche (mesuré le 03/11, à la fin de la partie 1). Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ». **Total attendu en fin de plan : 1915** (+106 ajoutés, 2 retirés — les deux tests de matrice de `focus`, Task 5 —, soit +104).
- **Les références `fichier:ligne`** ont été relues le 2026-11-03 sur `1b2008e`. Une tâche qui modifie un fichier décale les lignes des suivantes : l'implémenteur se fie au symbole nommé, la ligne n'est qu'un repère.
- **Le répertoire impose `passive`** : aucun fichier de carte ne l'écrit, ni de lot ni neutre. Trois dossiers neufs sous `assets/data/cards/` (Task 5) : `dart run tool/sync_assets.dart` les déclare ; après la suppression de `focus.json` et le déplacement de `demon_form.json`, `rm -rf build/unit_test_assets` avant tout `real_bundle_load_test`.
- **Les signatures ne changent pas** dans cette partie : ni `SignatureInstance`, ni `signature_bar.dart`, ni `SignatureData` (partie 3).
- **`assets/data/passives/mage_mark.json` garde `"trigger": "onAttackPlayed"`** ; `onDamagingCardPlayed` n'apparaît nulle part (D34). **`tool/simulations/` ne change pas** (ADR-108 D5).

## Review Focus

Cinq modes d'échec que la spec implique pour la partie 2 et qu'aucun test ne garde encore, du plus probable au moins probable ; chacun est confié à la tâche qui écrit le test qui le garde.

1. **Le masquage qui ment ou qui vide.** Un passif sans lot encore proposé ; une classe qui perd son seul passif ; un registre de test construit à la main qui perd ses passifs en silence, ou un test du tutoriel « choisir un autre passif » qui devient vrai sans rien prouver, l'autre passif étant le même. → **Task 6** (`passive_availability_test`, quatre tests ; `referential_integrity_test`, deux ; `class_selection_screen_test`, un ; les registres de test réécrits).
2. **Une carte de lot perdue à la sauvegarde.** `toJson` sans `passive` : au rechargement, `CardInstance.fromJson` lève (A8) sur la carte à `costs` avant tout `getById`, sans `catch` (`DeckState._decodePile`, `deck_controller.dart:78-80`) — ce n'est pas une carte perdue, c'est toute la relecture du deck qui échoue. → **Task 1** (`deck_state_persistence_test` « une carte de lot a costs survit a l aller-retour »).
3. **La carte d'un autre lot offerte.** Boutique, trouvaille, draft de départ ou `starterPool` du tutoriel qui oublient le passif actif, ou une run sans passif à qui l'on offre un lot. → **Task 2** (deux cents étals, deux cents trouvailles) ; **Task 7** et **Task 8** (le draft).
4. **Une face de carte qui ment sur ce qu'elle coûte ou frappe.** Un médaillon PV ou Armure absent, `3×3` absent, le badge Flame qui ajoute la Puissance entière à chaque coup au lieu de `floor(bonus × mightRatio)` (`card_text_renderer.dart:96-110`), le terme `scaleWith` ignoré en combat, un médaillon rouge sur la mauvaise ressource. → **Task 4** (`ui_card_values_test`, `card_text_renderer_test`, `card_rule_texts_test`, `card_costs_test`).
5. **Un deck de départ hors quotas.** Cinq neutres ou trois cartes du lot acceptées ; « Valider » actif à 4 + 1 ; un lot de moins de deux cartes qui bloque la validation. → **Task 7** (`starter_draft_test`, `starter_deck_draft_screen_test`) ; **Task 8** (le tutoriel suit).

**Les autres trous** — ceux de la section « Pour le Review Focus des plans » des vérifications qui touchent la partie 2, ceux du §4 du compte rendu de la partie 1, et ceux relevés en écrivant ce plan —, chacun confié :

| Trou | Tâche, test ou vérification |
|:---|:---|
| `forge_upgrades_catalog_test.dart:227-279` : la matrice nomme `focus` et `demon_form`, et ne couvre que 17 cartes | Task 5 : 33 entrées, `focus` retirée, 17 entrées neuves |
| Une neutre qui déclare `"passive": null` est refusée | Task 1, `game_data_loader_injection_test` |
| Une carte de lot à `costs` survit à `DeckState._decodePile` | Task 1 (Review Focus n° 2) |
| Les registres de test construits à la main et `passives_*_test` (`passives_paladin_test.dart:210`, `passives_berserker_test.dart:252`, `passives_mage_test.dart:365`) | Task 6. Mesuré le 03/11 : seuls `class_selection_screen_test` (`_registryOf`, `:345-358`) et `passive_availability_test` (`registryOf`, `:37-45`) bâtissent à la main un registre lu par `availablePassivesFor` ; le tutoriel lit le registre livré ; `passive_absent_test` ne lit pas `availablePassivesFor` et ne change pas |
| Refus à l'écran : `hero_card.dart:87` lit `CardComponent.canAfford`, qui lit `EffectResolver.canAfford` depuis la partie 1 ; `signature_bar.dart:114` lit `currentMana >= signature.cost` | `hero_card` : rien à faire. La barre : une signature ne coûte que du mana (`SignatureData` n'a ni `hpCost` ni `armorCost`) ; le coût évolué est de la partie 3, qui réécrit la tuile |
| D50 : compter par passif pourvu d'un lot, signatures exclues | Task 5, `card_catalog_test` |
| Compte rendu §4 — le descripteur de carte exige `cost` (`entity_descriptor.dart:214`) | Task 1 (`CardData.fromJson` nomme l'absence des deux clés) et Task 9 (`requiredKeys: {'type'}`, `alternativeKeys`) |
| Compte rendu §4 — la règle de mana du tutoriel (`tutorial_engine.dart:368`) | Task 8 : `playCard` lit `CostRules.canPay(mana: …)`, la borne du jeu ; PV et Armure n'y entrent jamais, la leçon écartant les cartes à coûts (A30), ce que le test de la leçon garde |
| Compte rendu §4 — la règle de mana de la barre de signatures (`signature_bar.dart:114`) | Partie 3 (la tuile lit `SignatureInstance`) |
| Compte rendu §4 — `SignatureInstance` construit un `CardData` sans `hpCost` ni `armorCost` (`signature_instance.dart:20-36`) | Aucune action : `SignatureData` n'a pas de coût autre que le mana, les valeurs par défaut (0) sont justes ; la partie 3 réécrit `asCard` |
| Compte rendu §4 — `scaleTerm` lit une cible morte pour `targetStatus` et `targetMissingHp` (`effect_resolver.dart:235-236`) | Task 4 : une cible à `currentPv <= 0` vaut 0, `scale_with_test` |
| Compte rendu §4 — `ProportionalStatus` sous `lib/game/services/`, importé par `lib/models/enemy_instance.dart` | Hors de cette partie : aucune tâche ne touche `enemy_instance.dart` ni `proportional_status.dart`. Au Review Focus de la partie 3, ou à la file de la clôture |
| Compte rendu §4 — éclaboussure à plusieurs coups ; une cible `allEnemies` qui meurt au premier coup | Task 5, `multi_hit_test`, avec *Rafale d'étincelles* |
| Compte rendu §4 — `takeDamage` sans test direct : l'Armure absorbée sur plusieurs coups, le plafond à 100 % | L'Armure sur plusieurs coups : Task 5, `multi_hit_test` « Rafale d etincelles : l Armure de la cible absorbe coup apres coup ». Le plafond (`p = min(100, …)`, partie 1) n'a pas de lecteur au-delà de 100 en `0.5.7` : `piercing` plafonne à 4 (100 %) et *Transcendance* ne le relève pas au-delà de 4 (A22) ; « Perforant 4 : toute l Armure ignoree, et gardee » (`rune_resolution_test`, partie 1) tient la borne atteinte |
| Compte rendu §4 — les gardes de D38 vides tant qu'aucune carte ne porte `hits` | Task 5 : *Rafale d'étincelles* les rend mordantes, sans retouche du test |
| Compte rendu §4 — la ligne Flame vide sans contexte | Task 4 : les textes passent par `CardRuleTexts`, testé avec une vraie `AppLocalizations` ; sans `buildContext`, `getTranslation` rend `''` et la ligne ne s'écrit pas (la règle de la partie 1) ; la face Flame au test manuel |
| `audio_catalogue_test.dart:38-52` : `Directory('assets/data/cards').listSync()` ne descend pas dans les dossiers de lot, dont les cartes peuvent porter un `sfx` | Task 5 : `recursive: true`, 71 fichiers |
| `tutorial_engine_test.dart:568` lit `focus` | Task 5 |
| Le remplissage du gabarit d'éditeur pose `cost` sur une carte saisie en `costs`, que `CardData.fromJson` refuse alors | Task 9, `alternativeKeys`, `placeholder_filler_test` |
| L'unicité d'un id de carte dans l'éditeur, entre neutres et lots (le chargeur les déduplique ensemble) | Task 9 : `card` et `lotCard` lisent tous deux tous les ids de `registry.cards` |
| `entity_descriptor_test.dart:33-35` compte les `EntitySource(` : 10 dès la Task 1, quand la catégorie `lotCard` n'arrive qu'à la Task 9 | Task 1 relève le compte à 10 et le dit dans le commentaire du test ; Task 9 relève les catégories à 10 |
| `TutorialFixtureIds` nomme toujours `strike_basic`, `defend_basic`, `fireball`, qui restent sous `cards/` | Task 10, vérification |
| Une sauvegarde de `0.5.6` sous un passif masqué reprend avec lui (`run_controller.dart:191` lit `PassiveData.getById`, pas la disponibilité) ; `focus` y est retirée comme élément manquant (spec §2.1, §8) | Aucune action ni test : le comportement est celui d'aujourd'hui, et les sauvegardes ne se transfèrent pas avant la `1.0.0` |

**Reportés à la partie 3**, hors de ce plan : tout ce qui touche les évolutions, la tuile de combat, `levelLabel`, `SignatureTile`, Q11 sur une signature à deux statuts d'évolution.

---

## Carte des fichiers

| Fichier | Rôle | Tâche |
|:---|:---|:---:|
| `lib/models/data/card_data.dart` | `CardData.passive`, A8, `toJson`, `_readCosts` ; `isOfferable(String?)` ; `CardEffect.mightPerHit` | 1, 2, 4 |
| `lib/services/game_data_service.dart` | `cardSources` : la source neutre et la source de lot | 1 |
| `lib/game/controllers/shop_controller.dart`, `reward_controller.dart` | L'offre lit le passif actif | 2 |
| `lib/models/data/passive_data.dart` | `classes` à une classe, `feeds` | 3 |
| `lib/models/data/passive_feeds.dart` *(nouveau)* | Le vocabulaire de `feeds` (A6) et ce qu'une carte touche | 3 |
| `lib/models/data/lot_rules.dart` *(nouveau)* | Les fautes d'une carte de lot (D45, A7) | 3 |
| `assets/data/passives/*.json` (neuf) | `feeds` | 3 |
| `lib/game/systems/cost_rules.dart` | `CostResource`, `missingFor` | 4 |
| `lib/game/services/card_rule_texts.dart` *(nouveau)* | Lignes de coût, de coups, de croissance | 4 |
| `lib/game/services/effect_resolver.dart`, `effects/strategies.dart` | `scaleTerm` ignore une cible morte ; `mightPerHit` | 4 |
| `lib/ui/widgets/ui_card/card_cost_medallion.dart` *(renommé de `card_mana_medallion.dart`)*, `ui_card.dart`, `card_compact_description.dart`, `ui_card_helpers.dart` | Rendu Flutter | 4 |
| `lib/game/components/widgets/card_text_renderer.dart`, `card_component.dart` | Rendu Flame | 4 |
| `lib/l10n/app_fr.arb`, `app_en.arb` (+ trois `app_localizations*.dart`) | Clés de §6.1 | 4, 7 |
| `assets/data/cards/{regen_armor,rage,mana_flux}/*.json` *(17 nouveaux)*, `cards/rage/demon_form.json` *(déplacé)*, `cards/focus.json` *(supprimé)*, `pubspec.yaml` (section `assets:`) | Les trois lots | 5 |
| `CLAUDE.md`, `README.md` | L'arbre et la phrase des champs imposés | 5 |
| `lib/game/systems/passive_availability.dart` | Le masquage | 6 |
| `lib/game/systems/starter_draft.dart` *(nouveau)* | Deux groupes, deux quotas | 7 |
| `lib/ui/screens/starter_deck_draft_screen.dart` | Deux sections | 7 |
| `lib/tutorial/tutorial_fixtures.dart`, `tutorial_engine.dart`, `tutorial_data.dart`, `widgets/tutorial_starter_deck_widget.dart` | Le tutoriel | 2, 8 |
| `lib/services/content_editor/*.dart` (`entity_descriptor`, `entity_draft`, `entity_catalog`, `entity_validator`, `entity_writer`, `placeholder_filler`, `known_values`, `class_recipe`), `lib/ui/screens/content_editor_screen.dart`, `lib/ui/widgets/content_editor/{entity_form,editor_style}.dart` | `lotCard`, la propriété à deux sortes | 3 (passif), 9 |
| `test/unit/lot_card_fixture.dart`, `lot_rules_test.dart`, `card_rule_texts_test.dart`, `card_text_renderer_test.dart`, `starter_draft_test.dart` *(nouveaux)* | — | 3, 4, 6, 7 |
| Les autres tests touchés | Nommés tâche par tâche | 1 à 9 |

Ordre : la forme et l'injection (1), puis l'offre (2) et les passifs (3), qui ne changent rien au jeu tant qu'aucune carte ne porte de passif ; le rendu (4) avant les données (5), pour qu'aucune carte livrée ne reste sans sa face ; **la tâche à risque, le masquage (6), après les données** — avant elles, aucune classe n'aurait de passif disponible ; puis le draft (7), le tutoriel (8), l'éditeur (9), et la vérification (10).

| Après la tâche | `registry.cards` (neutres / lot) | Fichiers d'entité | `EntitySource(` / catégories d'éditeur | Passifs disponibles par classe |
|:---:|:---:|:---:|:---:|:---:|
| base | 17 / 0 | 99 | 9 / 9 | 3 |
| 1 | 17 / 0 | 99 | 10 / 9 | 3 |
| 5 | 15 / 18 | 115 | 10 / 9 | 3 |
| 6 | 15 / 18 | 115 | 10 / 9 | 1 |
| 9 | 15 / 18 | 115 | 10 / 10 | 1 |

---

### Task 1: La forme C au chargeur — `CardData.passive`, l'injection, A8

Additive pour le jeu : aucune carte livrée ne porte encore de passif.

**Files:**
- Modify: `lib/models/data/card_data.dart:260-300` (champs, constructeur), `:310-364` (`fromJson`), `:371-405` (`_readCosts`), `:407-428` (`toJson`) ; `lib/services/game_data_service.dart:53-83`
- Test: `test/unit/game_data_loader_injection_test.dart`, `test/unit/card_costs_test.dart:25-33` (l'aide `costed`), `test/unit/deck_state_persistence_test.dart`, `test/unit/card_offer_filter_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart:21-36`

**Interfaces:**
- Produces :
  - `CardData` gagne `final String? passive` (paramètre nommé `this.passive`, défaut `null` : neutre). `fromJson` le lit (`json['passive'] as String?`) ; `toJson` l'écrit s'il n'est pas nul (spec §3.1).
  - A8 : `fromJson` lève `FormatException` dont le message contient `passive` si `passive == null` et `hpCost > 0 || armorCost > 0`.
  - `_readCosts` : ni `cost` ni `costs` → `FormatException` nommant `"cost" ou "costs"` (au lieu du `TypeError` de `json['cost'] as int`).
  - `final List<EntitySource<CardData>> cardSources` (top-level, `game_data_service.dart`) — exactement deux sources, lues par `loadGameDataRegistry` : `EntitySource('assets/data/cards/*.json', CardData.fromJson, inject: (c) => {'id': c[0], 'passive': null})` et `EntitySource('assets/data/cards/*/*.json', CardData.fromJson, inject: (c) => {'id': c[1], 'passive': c[0]})` (A2). Le commentaire de `loadGameDataRegistry` dit « dix sources ».

- [ ] **Step 1: Écrire les tests qui échouent**

`game_data_loader_injection_test.dart`, groupe neuf `la forme C (A2)` — `GameDataLoader(FakeBundle({...})).loadAll<CardData>(cardSources)` ; une carte minimale s'écrit `{"cost": 1, "type": "skill", "target": "self", "effects": []}` ; un refus s'asserte par `expect(loader.throwIfFailed, throwsA(isA<Exception>().having((e) => '$e', 'message', allOf(contains(<clé>), contains(<chemin>)))))` :
- `cards/<passif>/<id>.json injecte passive, cards/<id>.json l injecte a null` — `cards/mana_flux/kindle.json` et `cards/strike.json` : `{(c.id, c.passive)}` vaut `{('kindle', 'mana_flux'), ('strike', null)}`.
- `passive declare dans une carte de lot est refuse, nomme` — `cards/mana_flux/kindle.json` portant `"passive": "mana_flux"` : `passive`, le chemin.
- `une neutre qui declare passive, meme a null, est refusee` — `cards/strike.json` portant `"passive": null` : `passive`.
- `un meme id sous deux dossiers est refuse` — `cards/strike.json` et `cards/rage/strike.json` : `declare deux fois`.

`card_costs_test.dart` — l'aide `costed` gagne `'passive': 'rage'` (son commentaire le dit : A8 est en place) ; au groupe `la forme (A9)` :
- `A8 : un cout en PV ou en Armure sur une neutre est refuse` — `costed({'mana': 0, 'hp': 3})..remove('passive')`, puis la même à `armor` : `refused('passive')`.
- `ni cost ni costs : refuse, nomme` — `costed(null)..remove('costs')` : `refused('"cost" ou "costs"')`.

`deck_state_persistence_test.dart` :
- `une carte de lot a costs survit a l aller-retour de DeckState` — registre construit portant `CardData(id: 'breach', passive: 'regen_armor', cost: 0, armorCost: 4, type: attack, …)` ; un `DeckState` dont `masterDeck` porte une instance rare de cette carte ; `DeckState.fromJsonWithReport(state.toJson())` : rapport vide, `(data.passive, data.cost, data.armorCost)` vaut `('regen_armor', 0, 4)`, rareté rare.

`card_offer_filter_test.dart` :
- `toJson ecrit passive s il n est pas nul, et l aller-retour le garde ; une neutre ne l ecrit pas` — `CardData.fromJson({..._json(), 'passive': 'rage'})` : `toJson()['passive']` vaut `'rage'`, `CardInstance.fromJson(instance.toJson()).data.passive` vaut `'rage'` ; `_json()` seul : `toJson()` n'a pas la clé.

Réécrit, sans changer le total : `entity_descriptor_test.dart` « aucune source de chargement n a ete ajoutee sans descripteur » attend **10** ; son commentaire dit que la seconde source de cartes reçoit son descripteur, `lotCard`, à la Task 9 du plan de la partie 2 (le test des catégories garde 9 jusque-là).

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/game_data_loader_injection_test.dart test/unit/card_costs_test.dart test/unit/deck_state_persistence_test.dart test/unit/card_offer_filter_test.dart test/unit/content_editor/entity_descriptor_test.dart`
Expected: échec de compilation — `cardSources` et `CardData.passive` n'existent pas.

- [ ] **Step 3: Implémenter**

- `CardData` : le champ, le paramètre, la lecture, A8 juste après `_readCosts`, l'écriture dans `toJson` (après `id`). Le commentaire du champ : injecté par le répertoire, `null` veut dire neutre (A1), jamais écrit dans un fichier (A2).
- `_readCosts` : `if (!json.containsKey('cost')) throw fault('"cost" ou "costs" est exigé')` avant `json['cost'] as int`.
- `game_data_service.dart` : `cardSources`, avec un commentaire qui cite A2 — la source neutre injecte `passive: null` pour que `_applyInjection` (`game_data_loader.dart:215-249`) refuse une neutre qui le déclarerait ; le nombre de segments sépare les deux sources ; la déduplication est commune.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1819** (1811 + 4 + 2 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` des deux fichiers de `lib/` et des cinq tests, puis `git commit` — `feat(cartes): forme C, passive injecte par le repertoire`.

---

### Task 2: L'offre — `isOfferable(String? activePassiveId)` et ses quatre lecteurs

**Files:**
- Modify: `lib/models/data/card_data.dart:306-308` ; `lib/game/controllers/shop_controller.dart:51-53` ; `lib/game/controllers/reward_controller.dart:220` ; `lib/ui/screens/starter_deck_draft_screen.dart:55-56` ; `lib/tutorial/tutorial_fixtures.dart:66-70` ; `lib/tutorial/widgets/tutorial_starter_deck_widget.dart:41`
- Test: `test/unit/card_offer_filter_test.dart`, `test/unit/shop_controller_test.dart`, `test/unit/reward_controller_test.dart`, `test/widget/starter_deck_draft_screen_test.dart:289-351`, `test/tutorial/tutorial_fixtures_test.dart:123-130`, `test/tutorial/tutorial_engine_test.dart:456`, `:472`, `:502`, `test/widget/tutorial_starter_draft_test.dart:49`, `:60`, `:88`

**Interfaces:**
- Consumes : `CardData.passive` (Task 1).
- Produces :
  - `bool CardData.isOfferable(String? activePassiveId) => type != CardType.status && (passive == null || passive == activePassiveId);` — le getter disparaît (A3) ; son commentaire nomme les quatre lecteurs et dit qu'une run sans passif ne se voit offrir que des neutres. Le nom `isOfferableTo` n'est pas repris.
  - `List<CardData> TutorialFixtures.starterPool(String? activePassiveId)` — méthode à la place du getter ; le widget du draft du tutoriel passe `engine.mockState.activePassive?.id`. (La Task 8 la remplace par `starterDraft`.)
  - La boutique lit `ref.read(runProvider).activePassive?.id` ; la trouvaille aussi ; l'écran de draft lit `widget.passive?.id`.

- [ ] **Step 1: Écrire les tests qui échouent**

`card_offer_filter_test.dart`, groupe `CardData.isOfferable` :
- `une carte de lot n est offerte qu a son passif ; sans passif, aucune` — une carte construite `passive: 'rage'` : `isOfferable('rage')` vrai, `isOfferable('fervor')` faux, `isOfferable(null)` faux ; la même en `CardType.status` : faux pour `'rage'`.

`shop_controller_test.dart` :
- `deux cents etals n offrent jamais la carte d un autre lot` — registre : les cartes neutres du fichier, deux cartes `passive: 'rage'`, deux `passive: 'fervor'` ; run démarrée avec le passif `rage` ; deux cents `initializeShop` à des nœuds distincts (ou `rerollCards`, selon l'aide du fichier) : aucune carte en vente n'a `passive == 'fervor'`, et au moins une a `passive == 'rage'` (le filtre ne jette pas tous les lots).

`reward_controller_test.dart`, groupe `la trouvaille` :
- `deux cents trouvailles n offrent jamais la carte d un autre lot` — même registre, même passif, deux cents générations de récompense de combat à `random` graine fixe : aucune `foundCards` de `fervor`, au moins une de `rage`.

Réécrits, sans changer le total :
- `card_offer_filter_test.dart` « toute carte qui n est pas un statut est offerte, a toute rarete » → `isOfferable(null)` ; « une carte de statut n est jamais offerte » → `isOfferable(null)`.
- `starter_deck_draft_screen_test.dart` « le pool du draft de depart est celui d isOfferable » : le registre gagne une carte `passive: 'regen_armor'` (le passif de l'écran) et une `passive: 'fervor'` ; `UiCard` 11 (la première oui, la seconde non).
- `tutorial_fixtures_test.dart` « le pool de depart est celui du predicat d offre » → `starterPool('regen_armor')` vaut `data.cards.where((c) => c.isOfferable('regen_armor'))` trié.
- `tutorial_engine_test.dart:456`, `:472`, `:502` et `tutorial_starter_draft_test.dart:49`, `:60`, `:88` : `starterPool` → `starterPool(null)` (moteur) ou `starterPool(engine.mockState.activePassive?.id)` (widget).

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/card_offer_filter_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/widget/starter_deck_draft_screen_test.dart test/tutorial/tutorial_fixtures_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_starter_draft_test.dart`
Expected: échec de compilation — `isOfferable` est un getter.

- [ ] **Step 3: Implémenter** — le prédicat, puis ses quatre lecteurs, chacun en une ligne ; le commentaire de `CardData.compareByDisplayOrder` (`card_data.dart:443-448`) nomme `TutorialFixtures.starterPool` : inchangé.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1822** (1819 + 1 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(offre): isOfferable lit le passif actif`.

---

### Task 3: Les passifs — `classes` à une classe, `feeds`, la règle des cartes de lot

**Files:**
- Create: `lib/models/data/passive_feeds.dart`, `lib/models/data/lot_rules.dart`, `test/unit/lot_rules_test.dart`
- Modify: `lib/services/content_editor/class_recipe.dart:108-113` (commentaire) ; `lib/models/data/passive_data.dart:116-139`, `:192-208` (`_copyWith`), `:210-261` (`fromJson`) ; les neuf `assets/data/passives/*.json` ; `lib/services/content_editor/entity_descriptor.dart:298-334` (descripteur de passif)
- Test: `test/unit/passive_data_test.dart`, `test/unit/referential_integrity_test.dart`, `test/unit/content_editor/fixtures.dart:42-51`, `test/unit/content_editor/entity_descriptor_test.dart:274-283`, `:347-351`, `test/unit/content_editor/entity_validator_test.dart:423-470`, `test/widget/content_editor/document_form_test.dart:155-161`, `test/widget/content_editor_screen_test.dart:695-696` (commentaire)

**Interfaces:**
- Produces :
  - `PassiveData` gagne `final List<String> feeds` (paramètre nommé `this.feeds = const []` : un passif construit en code par un test n'en a pas besoin) ; `_copyWith` le recopie.
  - `PassiveData.fromJson` (A5, A6) : `classes` absente → `FormatException` nommant `classes` ; liste de longueur ≠ 1 → idem ; `feeds` absente, non-liste, vide ou d'éléments non textuels → `FormatException` nommant `feeds` ; chaque entrée passe `PassiveFeeds.faultOf`, une faute → `FormatException` nommant `feeds` et l'entrée. Le commentaire du champ `classes` cesse de dire « `null` : toutes » pour la donnée : il reste nullable pour les passifs construits en code (A5), et **amende ADR-096 D1**.
  - `abstract final class PassiveFeeds` (`passive_feeds.dart`, n'importe que `card_data.dart`) :
    - `static const cardTypes = ['attack', 'skill', 'power']` ; `static const effectTypes = ['damage', 'armor', 'heal', 'draw', 'gain_mana', 'apply_status']` ;
    - `static String? faultOf(String entry)` — `null` si `entry` est dans l'une des cinq formes d'A6 : un type de carte, un type d'effet, `status:<id>` (id non vide), `cost:hp` ou `cost:armor`, `scale:<ScaleSource.name>` ; sinon une phrase qui nomme l'entrée ;
    - `static Set<String> exhibitedBy(CardData card)` — ce que la carte montre, dans le vocabulaire de `feeds` : son type ; le type de chacun de ses effets ; `status:<statusId>` de chaque `apply_status` ; `cost:hp` si `hpCost > 0`, `cost:armor` si `armorCost > 0` ; `scale:<source>` de chaque `scaleWith` (A6, et la lecture de D45 par C1.3 : un coût est une touche) ;
    - `static bool touches(CardData card, Iterable<String> feeds) => feeds.any(exhibitedBy(card).contains)`.
  - `abstract final class LotRules` (`lot_rules.dart`) :
    - `static bool convertsArmor(HeroData hero)` — une `statRules` de `stat == RuleStat.armor` et `mode == RuleMode.convert` (A7, lu sur la règle et non sur l'id `berserker`) ;
    - `static List<String> faultsOf(CardData card, {required PassiveData passive, HeroData? heroClass})` — vide si la carte est bonne ; sinon, dans cet ordre, « ne touche aucune entrée de `feeds` de `<passive.id>` » (D45) et, si `card.armorCost > 0` et `heroClass` convertit l'Armure, « coûte de l'Armure sous `<heroClass.id>`, qui convertit son Armure » (A7). Aucune règle sur `hpCost` (D40). Lue par `card_catalog_test` (Task 5) et le validateur de l'éditeur (Task 9).
  - Le descripteur de passif : `requiredKeys` gagne `classes` et `feeds` ; le gabarit gagne `"classes": ["paladin"]` et `"feeds": ["armor"]` ; le commentaire « Absente du gabarit : sans `classes`, le passif est ouvert à toutes les classes » disparaît, celui de `displayOrder` dit que la disponibilité exige aussi un lot (O5). `ClassRecipe._starterPassiveMechanics` (`class_recipe.dart:114-120`) remplace déjà `classes` : son code ne change pas, mais son commentaire (`:108-113`, « Sans elle, le passif serait ouvert a **toutes** les classes ») et son pendant de test (`content_editor_screen_test.dart:695-696`) deviennent faux sous A5 ; ils disent désormais que sans `classes` le chargement échoue (A5), et que la recette remplace le `["paladin"]` du gabarit par la classe créée.

Les neuf `feeds`, à écrire après `classes` dans chaque fichier, mot pour mot (spec §3.3) :

| Fichier | `feeds` |
|:---|:---|
| `regen_armor.json` | `["armor", "status:armor_regen", "scale:armor", "cost:armor"]` |
| `fervor.json` | `["armor", "attack"]` |
| `blessing.json` | `["armor", "status:armor_regen", "status:weakness", "heal"]` |
| `rage.json` | `["cost:hp", "scale:missingHp", "armor", "status:might", "status:might_regen"]` |
| `bloodthirst.json` | `["attack"]` |
| `frenzy.json` | `["scale:targetMissingHp", "scale:enemiesAlive"]` |
| `mana_flux.json` | `["skill"]` |
| `channeling.json` | `["power"]` |
| `mage_mark.json` | `["damage", "status:vulnerable", "scale:targetStatus"]` |

- [ ] **Step 1: Écrire les tests qui échouent**

`passive_data_test.dart` — `passiveJson()` gagne `'classes': ['paladin']` et `'feeds': ['armor']`. Groupe `classes`, réécrit (trois tests, même compte) : `absente : refusee, nommee` ; `une classe : lue` ; `vide ou de deux classes : refusee` (`[]` puis `['paladin', 'mage']`, clé `classes`). Groupe neuf `feeds` :
- `feeds absente, vide ou non textuelle est refusee` — sans la clé, `[]`, `[1]` : clé `feeds`.
- `feeds admet ses cinq formes` — `['attack', 'gain_mana', 'status:burn', 'cost:hp', 'scale:missingHp']` se lit tel quel.
- `une entree hors des cinq formes est refusee, nommee` — `'block'`, `'status:'`, `'cost:mana'`, `'scale:speed'`, `'status'` : chacune nommée dans le message.
- `la Maitrise garde classes et feeds` — `regen().withMastery(2)` : `classes` et `feeds` identiques à ceux de `regen()`.

`test/unit/lot_rules_test.dart` *(nouveau ; cartes et passifs construits)* :
- `une carte touche feeds par son type, un effet, un statut pose, un cout, une source de scaleWith` — cinq cartes, chacune ne montrant qu'une de ces cinq formes, contre un `feeds` qui ne porte qu'elle : `PassiveFeeds.touches` vrai ; `exhibitedBy` d'une Attaque `[damage 2, scaleWith armor 1]` à `armorCost` 4 vaut `{'attack', 'damage', 'scale:armor', 'cost:armor'}`.
- `une carte qui ne touche rien est signalee` — une Attaque `[damage 6]` sous un passif `feeds: ['skill']` : `faultsOf` a une entrée, qui nomme le passif.
- `costs.armor est une faute sous une classe qui convertit l Armure, pas ailleurs` — une carte à `armorCost` 4 qui touche son `feeds` : sous un `HeroData` portant `StatRule` armor → convert, une faute qui nomme la classe ; sous un héros sans règle, aucune.
- `costs.hp n est jamais une faute d A7` — la même carte à `hpCost` 4 sous la classe qui convertit : aucune faute.

`referential_integrity_test.dart` :
- `chaque status:<id> de feeds est fabrique par createStatus` — pour chaque entrée `status:<id>` des passifs livrés, `EffectResolver.createStatus(id, 1, 1)` n'est pas nul.
- `les feeds livres sont ceux de spec §3.3` — `{for (p in registry.passives) p.id: p.feeds}` égale la table ci-dessus.

Réécrits, sans changer le total :
- `content_editor/fixtures.dart` : `fixturePassive(String id, {String heroClass = 'paladin', List<String> feeds = const ['armor']})` écrit `classes: [heroClass]` et `feeds`.
- `entity_descriptor_test.dart` : la table des gabarits, passif, gagne `classes` et `feeds` ; « classes est atteignable par le catalogue, pas par le gabarit » devient `classes et feeds sont exiges, et au gabarit (A5, A6)` — `requiredKeys` contient les deux, le gabarit les porte, `referenceListKeys` vaut toujours `{'classes': EntityCategory.heroClass}`.
- `test/widget/content_editor/document_form_test.dart:155-161` (« absente, elle se coche », groupe des listes de références) : le document part du gabarit, qui porte désormais `classes` ; le test retire `classes` du document avant de cocher `paladin`, l'attendu `['paladin']` ne change pas. Dans le même groupe, « decocher la derniere retire la cle » (`:174-184`) passe toujours, mais son commentaire (`:175`, « l'absence vaut « toutes » ») devient faux sous A5, où l'absence est refusée : il est réécrit (l'absence fait échouer le chargement, A5).
- `entity_validator_test.dart`, groupe « famille 6 — listes de references » : « sans classes, le passif est ouvert a toutes et passe » devient `sans classes, le passif est refuse` (le brouillon retire `classes` du gabarit : une faute au champ `classes`) ; « des classes existantes passent » devient `une classe existante passe` (`['paladin']`) ; « une classe inconnue est refusee » passe à `['paladn']`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/passive_data_test.dart test/unit/lot_rules_test.dart test/unit/referential_integrity_test.dart test/unit/content_editor/ test/widget/content_editor/`
Expected: échec de compilation — `feeds`, `PassiveFeeds`, `LotRules` n'existent pas.

- [ ] **Step 3: Implémenter** — les deux fichiers neufs, puis `PassiveData`, puis les neuf JSON, puis le descripteur.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/real_bundle_load_test.dart` (les neuf passifs se chargent).
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1832** (1822 + 4 + 4 + 2).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(passifs): classes a une classe et feeds`.

---

### Task 4 (interface): Le rendu des cartes — médaillons, coups, croissance

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 5 (amendement 2). Aucune carte livrée ne porte encore de coût combiné, de coups ni de croissance : les tests construisent leurs cartes.

**Files:**
- Create: `lib/game/services/card_rule_texts.dart`, `test/unit/card_rule_texts_test.dart`, `test/unit/card_text_renderer_test.dart`
- Rename: `lib/ui/widgets/ui_card/card_mana_medallion.dart` → `card_cost_medallion.dart` (`git mv`)
- Modify: `lib/models/data/card_data.dart` (`CardEffect`) ; `lib/game/services/effects/strategies.dart:46-51` ; `lib/game/services/effect_resolver.dart:235-236` ; `lib/game/systems/cost_rules.dart` ; `lib/ui/widgets/ui_card.dart:304-311` ; `lib/ui/widgets/ui_card/card_compact_description.dart:73-125` ; `lib/ui/widgets/ui_card/ui_card_helpers.dart:313-316`, `:339-357` ; `lib/game/components/widgets/card_text_renderer.dart:96-166`, `:513-540` ; `lib/game/components/card_component.dart:307-309`, `:332-358` ; `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`
- Test: `test/widget/ui_card_values_test.dart`, `test/unit/card_costs_test.dart`, `test/unit/scale_with_test.dart`

**Interfaces:**
- Produces :
  - `int CardEffect.mightPerHit(int damageBonus) => (damageBonus * mightRatio + 1e-9).floor();` (A13) — lu par `DamageEffectStrategy` (qui remplace son calcul en ligne), le badge et l'infobulle Flame.
  - `EffectResolver.scaleTerm` : la cible se cherche parmi les ennemis à `currentPv > 0` ; une cible morte ou absente vaut 0 pour `targetStatus` et `targetMissingHp` (compte rendu §4).
  - `cost_rules.dart` : `enum CostResource { mana, hp, armor }` ; sur l'extension `CostRules`, `Set<CostResource> missingFor({int mana = 0, int hp = 0, int armor = 0})` — chaque ressource dont **sa** borne de `canPay` échoue (même règle, une borne à la fois : PV strictement supérieurs au coût).
  - `abstract final class CardRuleTexts` (`card_rule_texts.dart`) — la seule écriture de ces lignes, lue par les deux infobulles :
    - `static List<String> extraCosts(AppLocalizations l10n, CardData card)` — `cardCostHp(hpCost)` puis `cardCostArmor(armorCost)`, chacun s'il est non nul ;
    - `static String damage(AppLocalizations l10n, {required int amount, required int hits, required bool allEnemies})` — `cardDescDamageHits(amount, hits)` si `hits ≥ 2` (toute cible : aucune clé AoE à coups dans §6.1, aucune carte de `0.5.7` n'en porte), sinon `cardDescDamageAll` ou `cardDescDamage` ;
    - `static String scale(AppLocalizations l10n, ScaleWith scale)` — sous 1, la clé `…Per` de la source avec `per = (1 / ratio).round()` ; au-delà, la clé nue avec `ratio` écrit sans décimale inutile (`1`, `1,5` en français, `1.5` en anglais, selon `l10n.localeName`) ; `targetStatus` nomme le statut par `EffectResolver.createStatus(statusId, 0, 0)?.name`, l'id à défaut (aucune carte de `0.5.7` ne lit cette source).
  - `class CardCostMedallion extends StatelessWidget` — `const CardCostMedallion({super.key, required CostResource resource, required int amount})` ; remplace `CardManaMedallion` (un seul lecteur, `ui_card.dart:310`). Mana : l'aspect d'aujourd'hui (cyan). PV : bord et chiffre `Colors.redAccent`, goutte (`Icons.water_drop_rounded`) pâle derrière le chiffre. Armure : bord et chiffre `Colors.blueGrey.shade200`, écu (`Icons.shield_rounded`) pâle derrière. Pas d'état « manque » côté Flutter : `UiCard` ne connaît pas les ressources du héros, aucun lecteur ne le passerait ; le rouge d'une ressource qui manque (spec §4.1) vit sur la face Flame, qui les connaît.
  - `UiCard` : sous le médaillon de mana (`top: -9, left: -9`), une colonne à gauche porte un médaillon par coût non nul, PV puis Armure, lus sur `data`.
  - `CardCompactDescription` : un effet `damage` à `hits ≥ 2` écrit `'$valeur×$hits'` (`3×3`) ; avec un bonus de rune, `'$base'`, `' +$bonus🔨'`, puis `'×$hits'`.
  - `static String CardTextRenderer.badgeValue(CardEffect effect, {int damageBonus = 0, int scaleTerm = 0})` — `effect.value + scaleTerm`, plus `effect.mightPerHit(damageBonus)` pour un `damage`, suivi de `×hits` si `hits ≥ 2`. `refreshVisuals` le lit, `damageBonus` de `game.heroCard` comme aujourd'hui, `scaleTerm` par `EffectResolver.scaleTerm(effect, hero: …, combat: game.currentCombatState, targetId: null)` quand la run et le combat sont connus, 0 sinon (spec §5.2 : le terme des sources du héros ; une source de cible, sans cible avant le jeu, vaut 0). `render` dessine sous le médaillon de mana (`(6, 6)`) un médaillon par coût non nul, dans l'ordre PV puis Armure, aux centres `(6, 32)` puis `(6, 58)`, sans trou ; chacun des trois passe au rouge — bord et chiffre `Colors.red`, fond rouge sombre — selon `missingFor` sur les stats du héros (aucun sans run).
  - Les infobulles — Flutter (`buildDetailedDescription`) et Flame (`card_component.dart`) : après la ligne `… Mana`, une ligne `'  <texte>'` par entrée d'`extraCosts` ; la ligne de dégâts par `CardRuleTexts.damage` (Flame : `amount` = valeur jouée + terme + `mightPerHit`, à la place de `+ damageBonus` entier, `:332-345` ; Flutter : la valeur jouée, sans héros, comme aujourd'hui) ; après la ligne d'un effet à `scaleWith`, une ligne `'  (<CardRuleTexts.scale>)'`. Côté Flame, chaque texte passe par `getTranslation` ; vide, la ligne ne s'écrit pas.
  - Quinze clés ARB, textes de spec §6.1 **mot pour mot** : `cardCostHp`, `cardCostArmor` (`amount` int) ; `cardDescDamageHits` (`amount`, `hits` int) ; `cardScaleArmor`, `cardScaleMissingHp`, `cardScaleCardsPlayed`, `cardScaleEnemiesAlive`, `cardScaleTargetMissingHp` (`ratio` String) ; `cardScaleTargetStatus` (`ratio` String, `status` String) ; les six `…Per` (`per` int ; `cardScaleTargetStatusPer` gagne `status` String).

- [ ] **Step 1: Écrire les tests qui échouent**

`ui_card_values_test.dart` (cartes construites, `_pumpCard`, français) :
- `une carte a 1 mana et 6 Armure montre deux medaillons, une a 0 mana et 4 PV aussi` — `find.byType(CardCostMedallion)` deux fois chacune ; les chiffres `'1'` et `'6'`, puis `'0'` et `'4'` dans les médaillons.
- `un multi-coups montre valeur×coups` — Compétence `[apply_status shock 1, damage 3 hits 3 mightRatio 0.5]` : `_body('3×3')` trouvé une fois.
- `l infobulle dit les couts en PV et en Armure` — Attaque à `cost` 1, `hpCost` 3, `armorCost` 2 : `_tooltip` contient `l10n.cardCostHp(3)` et `l10n.cardCostArmor(2)`.
- `l infobulle dit les coups et la croissance` — Compétence `[damage 3 hits 3 0.5]` : contient `l10n.cardDescDamageHits(3, 3)` ; Compétence `[armor 6, scaleWith armor 0.2]` : contient `l10n.cardScaleArmorPer(5)` ; Attaque `[damage 2, scaleWith armor 1]` : contient `l10n.cardScaleArmor('1')`.

`test/unit/card_rule_texts_test.dart` *(nouveau ; `lookupAppLocalizations(const Locale('fr'))` et `('en')`)* :
- `un ratio sous 1 s ecrit en tranches, un ratio d au moins 1 tel quel, pour les six sources` — pour chaque `ScaleSource`, `ratio` 0.2 rend la clé `…Per(5, …)`, `ratio` 1 la clé nue `('1', …)` ; `ratio` 1.5 rend `'1,5'` en français, `'1.5'` en anglais.
- `les degats : une ligne a coups au-dela d un coup` — `hits` 3 → `cardDescDamageHits(3, 3)` ; `hits` 1 → `cardDescDamage(3)`, ou `cardDescDamageAll(3)` sous `allEnemies`.
- `les couts : PV puis Armure, rien pour le mana seul` — `(cost 1, hp 3, armor 2)` → `[cardCostHp(3), cardCostArmor(2)]` ; `(cost 2)` → `[]`.
- `targetStatus nomme le statut` — `scaleWith targetStatus 1 vulnerable` : le texte contient `'Vulnérable'`.

`test/unit/card_text_renderer_test.dart` *(nouveau ; la face Flame faute de banc, spec §9 : ses calculs, statiques)* :
- `le badge d un multi-coups dit valeur×coups, la Puissance par coup arrondie vers le bas` — `badgeValue([damage 3 hits 3 0.5], damageBonus: 3)` vaut `'4×3'` ; `damageBonus: 1` → `'3×3'`.
- `le badge d un effet a scaleWith ajoute le terme` — `badgeValue([damage 2 scaleWith armor 1], scaleTerm: 7)` vaut `'9'` ; `[armor 6 scaleWith armor 0.2]`, `scaleTerm: 2`, `damageBonus: 5` → `'8'` (la Puissance ne touche que les dégâts).

`card_costs_test.dart`, groupe `canAfford (A10)` :
- `missingFor nomme la seule ressource qui manque` — héros (mana 3, PV 4, Armure 2), coûts (1, 4, 3) : `{CostResource.hp, CostResource.armor}` ; (4, 3, 2) : `{CostResource.mana}`.

`scale_with_test.dart`, groupe `resolution` :
- `une cible morte ne nourrit ni targetStatus ni targetMissingHp` — `EffectResolver.scaleTerm` sur une carte `[damage 1, scaleWith targetMissingHp 1]` dont l'ennemi désigné est à 0/100 PV : 0 ; à 60/100 : 40 ; une carte `[damage 1, scaleWith targetStatus 1 vulnerable]` dont l'ennemi désigné, à 0 PV, porte 2 Vulnérable : 0 ; vivant, 2.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/ui_card_values_test.dart test/unit/card_rule_texts_test.dart test/unit/card_text_renderer_test.dart test/unit/card_costs_test.dart test/unit/scale_with_test.dart`
Expected: échec de compilation — `CardCostMedallion`, `CardRuleTexts`, `badgeValue`, `missingFor` et les clés n'existent pas.

- [ ] **Step 3: Implémenter** — les clés ARB et `flutter gen-l10n` d'abord, puis le modèle (`mightPerHit`), `scaleTerm`, `missingFor`, `CardRuleTexts`, le médaillon, `UiCard`, le corps, l'infobulle Flutter, puis la face et l'infobulle Flame. `strategies.dart` lit `mightPerHit` à la place de son calcul en ligne : `multi_hit_test` reste vert sans retouche.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/multi_hit_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1844** (1832 + 4 + 4 + 2 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin (le renommage par `git mv`, les trois `app_localizations*.dart`), puis `git commit` — `feat(rendu): medaillons PV et Armure, coups et croissance`.

---

### Task 5 (interface): Les trois lots — 17 cartes neuves, `focus` supprimée, `demon_form` déplacée

Tâche d'interface : les noms et textes de dix-sept cartes arrivent à l'écran ; l'orchestrateur trie les mineurs visibles avant la Task 6.

**Files:**
- Create: les 17 fichiers du tableau ci-dessous
- Move: `git mv assets/data/cards/demon_form.json assets/data/cards/rage/demon_form.json` (contenu inchangé, `mkdir -p` du dossier d'abord)
- Delete: `git rm assets/data/cards/focus.json`
- Modify: `pubspec.yaml` (section `assets:`, par `dart run tool/sync_assets.dart`) ; `CLAUDE.md:78-79`, `:89` ; `README.md:69`, `:93-96`
- Test: `test/unit/card_catalog_test.dart`, `test/unit/forge_upgrades_catalog_test.dart:227-279`, `:281`, `:359-361`, `test/unit/multi_hit_test.dart`, `test/widget/ui_card_values_test.dart`, `test/unit/real_bundle_load_test.dart:36`, `:97`, `test/unit/entity_id_convention_test.dart:67-77`, `test/unit/audio/audio_catalogue_test.dart:38-52`, `test/tutorial/tutorial_engine_test.dart:564-577`

**Interfaces:**
- Consumes : `PassiveFeeds.touches`, `LotRules.faultsOf` (Task 3) ; le rendu (Task 4).
- Produces : les données, dont lisent les tâches 6 à 9.

**Les cartes** — chaque fichier a la forme de `demon_form.json` et ses clés dans cet ordre : `id`, `name_en`, `name_fr`, `description_en`, `description_fr`, `cost` **ou** `costs`, `type`, `rarity` (`common` partout), `target`, `animation`, `effects`. Ni `passive`, ni `isExhaust`, ni `sfx` (spec §3.4 : aucune à épuisement hors les Pouvoirs, que le moteur épuise déjà, `card_instance.dart:36-41`). Les noms et descriptions sont ceux de spec §3.4, **mot pour mot** ; les animations sont un choix T du plan, sur le vocabulaire des neutres (`melee`, `magic`, `buff`, `fire`, `ice`, `lightning`).

| Fichier | Nom FR / EN | Coût | Type, cible, animation | Effets | Description FR / EN |
|:---|:---|:---|:---|:---|:---|
| `regen_armor/bulwark.json` | Muraille / Bulwark | `"cost": 2` | skill, self, buff | `armor` 12 | « Gagne 12 d'Armure. » / « Gain 12 Block. » |
| `regen_armor/bastion.json` | Bastion / Bastion | `"cost": 3` | power, self, buff | `apply_status` `armor_regen` 3, `duration` 4 | « Pendant 4 tours, gagne 3 Armure au début du tour. » / « For 4 turns, gain 3 Block at the start of your turn. » |
| `regen_armor/rampart_slam.json` | Rempart brisé / Rampart Slam | `"cost": 1` | attack, singleEnemy, melee | `damage` 2, `scaleWith {source: armor, ratio: 1}` | « Inflige 2 dégâts, +1 par point d'Armure. » / « Deal 2 damage, +1 per point of Block. » |
| `regen_armor/fortify.json` | Fortification / Fortify | `"cost": 1` | skill, self, buff | `armor` 6, `scaleWith {armor, 0.2}` | « Gagne 6 d'Armure, +1 par tranche de 5 d'Armure. » / « Gain 6 Block, +1 per 5 Block you have. » |
| `regen_armor/breach.json` | Percée / Breach | `"costs": {"mana": 0, "armor": 4}` | attack, singleEnemy, melee | `damage` 10 | « Coûte 4 Armure. Inflige 10 dégâts. » / « Costs 4 Block. Deal 10 damage. » |
| `regen_armor/shield_burst.json` | Éclat de bouclier / Shield Burst | `"costs": {"mana": 1, "armor": 6}` | attack, allEnemies, magic | `damage` 8 | « Coûte 6 Armure. Inflige 8 dégâts à tous les ennemis. » / « Costs 6 Block. Deal 8 damage to all enemies. » |
| `rage/bloodletting.json` | Sang versé / Bloodletting | `"costs": {"mana": 0, "hp": 4}` | attack, singleEnemy, melee | `damage` 8 | « Coûte 4 PV. Inflige 8 dégâts. » / « Costs 4 HP. Deal 8 damage. » |
| `rage/blood_pact.json` | Pacte de sang / Blood Pact | `"costs": {"mana": 1, "hp": 3}` | skill, self, buff | `draw` 2 | « Coûte 3 PV. Pioche 2 cartes. » / « Costs 3 HP. Draw 2 cards. » |
| `rage/last_breath.json` | Dernier souffle / Last Breath | `"cost": 2` | attack, singleEnemy, melee | `damage` 4, `scaleWith {missingHp, 0.2}` | « Inflige 4 dégâts, +1 par tranche de 5 PV manquants. » / « Deal 4 damage, +1 per 5 missing HP. » |
| `rage/blood_fury.json` | Fureur sanguine / Blood Fury | `"cost": 1` | skill, self, buff | `apply_status` `might` 1, `duration` 1, `scaleWith {missingHp, 0.1}` | « Gagne 1 Puissance ce tour, +1 par tranche de 10 PV manquants. » / « Gain 1 Might this turn, +1 per 10 missing HP. » |
| `rage/trance.json` | Transe / Trance | `"cost": 2` | power, self, buff | `apply_status` `might_regen` 1, `duration` 3 | « Pendant 3 tours, gagne 1 Puissance au début du tour. » / « For 3 turns, gain 1 Might at the start of your turn. » |
| `mana_flux/arcane_shard.json` | Éclat / Arcane Shard | `"cost": 1` | skill, singleEnemy, magic | `damage` 5 | « Inflige 5 dégâts. » / « Deal 5 damage. » |
| `mana_flux/arcane_wave.json` | Onde / Arcane Wave | `"cost": 2` | skill, allEnemies, magic | `damage` 4 | « Inflige 4 dégâts à tous les ennemis. » / « Deal 4 damage to all enemies. » |
| `mana_flux/kindle.json` | Embrasement / Kindle | `"cost": 1` | skill, singleEnemy, fire | `apply_status` `burn` 4, `duration` 3 | « Applique 4 Brûlure. » / « Apply 4 Burn. » |
| `mana_flux/spark_barrage.json` | Rafale d'étincelles / Spark Barrage | `"cost": 2` | skill, singleEnemy, lightning | `apply_status` `shock` 1, `duration` 1 ; puis `damage` 3, `hits` 3, `mightRatio` 0.5 | « Applique 1 Électrocution, puis inflige 3 dégâts 3 fois. » / « Apply 1 Shock, then deal 3 damage 3 times. » |
| `mana_flux/frost_nova.json` | Nova de givre / Frost Nova | `"cost": 2` | skill, allEnemies, ice | `apply_status` `freeze` 2, `duration` 1 | « Applique 2 Gel à tous les ennemis. » / « Apply 2 Freeze to all enemies. » |
| `mana_flux/discharge.json` | Décharge / Discharge | `"cost": 3` | skill, singleEnemy, lightning | `damage` 12 ; puis `apply_status` `vulnerable` 2, `duration` 2 | « Inflige 12 dégâts. Applique 2 Vulnérable pendant 2 tours. » / « Deal 12 damage. Apply 2 Vulnerable for 2 turns. » |

**La documentation** (spec §11) : `CLAUDE.md`, après l'entrée des neutres (`:78-79`, deux lignes), `├── cards/<passive>/<id>.json         # lot cards: the folder is the passive` ; `CLAUDE.md:89`, « …and so do `heroClass` and `category` in a card file » devient « …and so do `heroClass`, `category` and `passive` in any card file » ; après `README.md:69`, `├── cards/<passif>/<id>.json      # carte de lot : le dossier est le passif` ; la note de `README.md:93-96` (la carte nommée en `:95`) gagne `passive` dans tout fichier de carte.

- [ ] **Step 1: Écrire les tests qui échouent**

`card_catalog_test.dart` (registre livré) — « aucune carte livree ne porte hpCost ni armorCost » devient `D17 : aucune neutre ne porte de cout autre que du mana` (même compte, `passive == null`). Neufs :
- `les 18 cartes de lot sont celles de spec §3.4` — une table du test, par id : `(passive, cost, hpCost, armorCost, type, target, [(type, statusId, value, duration, hits, mightRatio, scaleWith.source, scaleWith.ratio)])`, recopiée du tableau ci-dessus ; `{for (c in registry.cards.where((c) => c.passive != null)) c.id: …}` l'égale.
- `les trois lots : six cartes chacun, communes, aucune isExhaust` — comptes par passif `{'regen_armor': 6, 'rage': 6, 'mana_flux': 6}` ; toutes `common`, `isExhaust` faux.
- `D45 : chaque carte de lot touche une entree des feeds de son passif` — `PassiveFeeds.touches(card, passive.feeds)` pour chacune ; la liste des fautives est vide.
- `A7 : aucune carte de lot ne coute d Armure sous une classe qui convertit l Armure` — `LotRules.faultsOf` avec la classe de `passive.classes!.single` : aucune faute (ce test et le précédent forment, ensemble, l'appel de `faultsOf` sur tout le registre).
- `D50 : par passif pourvu d un lot, au plus deux cartes offertes a cout total nul, toutes isExhaust ; aucun lot n en porte plus d une` — pour chaque passif d'au moins une carte de lot : parmi `registry.cards.where((c) => c.isOfferable(p))`, celles à `cost + hpCost + armorCost == 0` sont au plus deux et toutes `isExhaust` ; parmi celles du lot, au plus une. Signatures exclues (vérifications, tour 1).
- `D12 : chaque mecanisme a ses cartes` — au moins deux cartes à `hpCost > 0`, deux à `armorCost > 0`, deux à `scaleWith` `armor`, deux à `scaleWith` `missingHp`, une à `hits ≥ 2`.
- `une carte a scaleWith garde une valeur de base d au moins 1` (spec §1.3, fin d'A38 ; G1).

`forge_upgrades_catalog_test.dart` — `_offers` passe à **33** entrées : `focus` sort ; `demon_form` garde la sienne ; dix-sept entrées neuves, rang 1 (peu commune) puis rang 2 (rare), avec un ensemble neuf `_skillDamageRank1 = {'sharp', 'precise', 'spectral', 'piercing', 'lifesteal', 'cheap'}` et `_skillDamageRank2 = {..._skillDamageRank1, 'quick', 'eco'}` (une Compétence de dégâts n'a ni `burning`, ni `freezing`, ni `shocking`, réservées aux Attaques) :

| Cartes | Rang 1 | Rang 2 |
|:---|:---|:---|
| `bulwark`, `fortify` | `{'hardened', 'cheap', 'echo'}` | `+ 'quick', 'eco'` |
| `bastion`, `blood_fury`, `trance`, `kindle`, `frost_nova` | `{'cheap', 'echo'}` | `+ 'quick', 'eco'` |
| `rampart_slam`, `last_breath` | `{..._singleTargetRank1, 'echo'}` | `{..._singleTargetRank2, 'echo'}` |
| `shield_burst` | `{..._attackRank1, 'echo'}` | `{..._attackRank2, 'echo'}` |
| `breach` (0 mana : ni `cheap`, ni `eco`) | `{..._singleTargetRank1.difference({'cheap'}), 'echo'}` | rang 1 `+ 'quick'` |
| `bloodletting` (0 mana, 4 PV) | rang 1 de `breach` `+ 'transfusion'` | rang 2 de `breach` `+ 'transfusion'` |
| `blood_pact` (pioche : pas d'`echo`) | `{'cheap', 'transfusion'}` | `+ 'quick', 'eco'` |
| `arcane_shard`, `spark_barrage`, `discharge` | `{..._skillDamageRank1, 'splash', 'echo'}` | `{..._skillDamageRank2, 'splash', 'echo'}` |
| `arcane_wave` | `{..._skillDamageRank1, 'echo'}` | `{..._skillDamageRank2, 'echo'}` |

Le test « la matrice couvre les 17 cartes livrees » devient « … les 33 cartes livrees », et les deux commentaires qui disent 17 suivent (**+32** tests : 17 × 2 neufs, 2 retirés avec `focus`).

`multi_hit_test.dart`, groupe `resolution` (le Mage, Puissance 0) :
- `Rafale d etincelles et Ricochant : chaque coup eclabousse` — trois ennemis à 100 ; la carte livrée `spark_barrage` + `splash:1` : la cible finit à 88 (l'Électrocution posée d'abord, 3 + 1 par coup), chacun des deux autres à 97 (1 par coup, le plancher).
- `allEnemies : un ennemi mort au premier coup ne recoit pas le second` — héros à 50 sous Vol de vie (statut) à 99, ennemis à 100 et à 2 PV, carte `allEnemies [damage 3 hits 2 0.5]` : (94, 0), héros à 59 (trois coups comptés, pas quatre).
- `Rafale d etincelles : l Armure de la cible absorbe coup apres coup` — un ennemi à 100 PV et 5 Armure ; la carte livrée `spark_barrage` sans rune : assertion : l'état final, (93 PV, 0 Armure) ; le détail coup par coup en est le calcul — chaque coup vaut 4 (3 + l'Électrocution posée d'abord), le premier laisse 1 Armure, le deuxième la prend puis 3 PV, le troisième 4 PV. L'aide `foe` gagne un paramètre `armor`.

`ui_card_values_test.dart` :
- `les cartes livrees se rendent : Percee montre son medaillon d Armure, Rafale d etincelles son 3×3` — `registry.cards` livré (`loadGameDataRegistry`) : `breach` montre deux `CardCostMedallion` (`'0'`, `'4'`) ; `spark_barrage` montre `_body('3×3')`.

Réécrits, sans changer le total : `real_bundle_load_test` — `countUnder('assets/data/cards/', 4)` vaut **15** (raison « cartes neutres »), une assertion neuve dans le même test `countUnder('assets/data/cards/', 5)` vaut **18** (« cartes de lot »), le titre dit 115, `registry.cards` **33** et son commentaire ; `entity_id_convention_test` — **115**, raison « 15 cartes neutres + 18 cartes de lot + … » ; `audio_catalogue_test` — `Directory('assets/data/cards').listSync(recursive: true)`, **71**, raison « 15 cartes neutres + 18 cartes de lot + 28 reliques + 6 signatures + 4 ennemis » ; `tutorial_engine_test.dart:564-577` (« sans carte dont la fusion offre une rune, la Fusion seme la premiere carte fusionnable ») — `focus` devient, en tête du deck, une carte construite de rareté `legendary` (non fusionnable), suivie de `concentration` : l'attendu reste `concentration`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/card_catalog_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/multi_hit_test.dart test/widget/ui_card_values_test.dart`
Expected: échec — aucune carte de lot dans le registre.

- [ ] **Step 3: Écrire les données**

Le déplacement, la suppression, les dix-sept fichiers ; `dart run tool/sync_assets.dart` (trois lignes neuves sous `assets:`, `pubspec.yaml` sans autre changement — `git diff pubspec.yaml` le montre) ; `rm -rf build/unit_test_assets` ; la documentation.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/card_catalog_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/multi_hit_test.dart test/widget/ui_card_values_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/audio/audio_catalogue_test.dart test/tutorial/tutorial_engine_test.dart test/unit/referential_integrity_test.dart test/unit/sync_assets_test.dart` puis `dart run tool/sync_assets.dart --check` (code 0).
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1887** (1844 + 7 + 32 + 3 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin (les dix-sept fichiers, le déplacement, la suppression, `pubspec.yaml`, `CLAUDE.md`, `README.md`, les tests), puis `git commit` — `feat(lots): Rempart, Sang et Arcaniste, focus retiree`.

---

### Task 6 (interface): Le masquage des passifs sans lot — tâche à risque

**Le code s'écrit ici en entier.** O5, spec §4.8, A4 : un passif dont aucune carte du registre ne porte le passif n'est pas proposé, sans liste en dur ; le Mage démarre sur *Flux de Mana*, au jeu comme au tutoriel ; les registres de test qui attendent un passif disponible lui donnent une carte de lot. Tâche d'interface : l'écran de sélection de classe ne montre plus qu'un passif par classe ; l'orchestrateur trie les mineurs visibles avant la Task 7.

**Files:**
- Create: `test/unit/lot_card_fixture.dart`
- Modify: `lib/game/systems/passive_availability.dart:1-29`
- Test: `test/unit/passive_availability_test.dart` (réécrit), `test/unit/referential_integrity_test.dart:146-160`, `test/widget/class_selection_screen_test.dart:345-395`, `:732-770`, `test/tutorial/tutorial_test_registry.dart`, `test/unit/passives_paladin_test.dart:206-213`, `test/unit/passives_berserker_test.dart:248-255`, `test/unit/passives_mage_test.dart:362-369`, `test/tutorial/tutorial_fixtures_test.dart:44-56`, `test/tutorial/tutorial_engine_test.dart:235-286`, `test/widget/tutorial_class_step_test.dart:10-33`, `:84-135`

**Interfaces:**
- Consumes : `CardData.passive` (Task 1) ; les trois lots (Task 5).
- Produces : `availablePassivesFor(HeroData hero, GameDataRegistry registry)` — même signature, disponibilité = éligible **et** pourvu d'un lot ; `CardData lotCardFor(String passiveId, {CardType type = CardType.skill})` (aide de test) ; `buildTutorialTestRegistry({Set<String> openedPassives = const {}})`.

- [ ] **Step 1: L'aide de test — `test/unit/lot_card_fixture.dart`**

```dart
import 'package:roguelike_card_game/models/data/card_data.dart';

/// Une carte de lot minimale pour [passiveId] (spec P-42 T1 et P-44 lot 1,
/// §4.8). Le masquage ne lit d'une carte que son passif : un registre
/// construit à la main qui attend un passif disponible lui en donne une.
CardData lotCardFor(String passiveId, {CardType type = CardType.skill}) =>
    CardData(
      id: 'lot_$passiveId',
      passive: passiveId,
      cost: 1,
      type: type,
      rarity: CardRarity.common,
      target: CardTarget.self,
      effects: const [CardEffect(type: 'armor', value: 1)],
    );
```

- [ ] **Step 2: Écrire les tests qui échouent — `test/unit/passive_availability_test.dart`, en entier**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';

import 'lot_card_fixture.dart';

/// Le point d'accès unique aux passifs d'une classe (spec P-49, §4) :
/// disponible vaut éligible et pourvu d'un lot (spec P-42 T1 et P-44 lot 1,
/// §4.8, O5).
void main() {
  const paladin = HeroData(
    id: 'paladin',
    classCard: 'paladin.png',
    maxHp: 100,
    maxMana: 3,
  );
  const mage = HeroData(
    id: 'mage',
    classCard: 'mage.png',
    maxHp: 60,
    maxMana: 3,
  );

  PassiveData passive(
    String id, {
    List<String>? classes,
    int displayOrder = 0,
  }) =>
      PassiveData(
        id: id,
        trigger: RelicTrigger.startOfTurn,
        effectType: 'gain_armor',
        value: 1,
        classes: classes,
        displayOrder: displayOrder,
      );

  /// Un registre dont chaque passif a son lot, sauf si [cards] est donné.
  GameDataRegistry registryOf(
    List<PassiveData> passives, {
    List<CardData>? cards,
  }) =>
      GameDataRegistry(
        enemies: const [],
        heroes: const [paladin, mage],
        cards: cards ?? [for (final p in passives) lotCardFor(p.id)],
        events: const [],
        passives: passives,
        relics: const [],
        forgeUpgrades: const [],
      );

  List<String> idsFor(HeroData hero, GameDataRegistry registry) =>
      availablePassivesFor(hero, registry).map((p) => p.id).toList();

  test('un passif qui declare une classe n est disponible que pour elle', () {
    final registry = registryOf([passive('ward', classes: ['paladin'])]);
    expect(idsFor(paladin, registry), ['ward']);
    expect(idsFor(mage, registry), isEmpty);
  });

  test('un passif sans classes est disponible pour toutes', () {
    final registry = registryOf([passive('aegis')]);
    expect(idsFor(paladin, registry), ['aegis']);
    expect(idsFor(mage, registry), ['aegis']);
  });

  test('un passif partage entre deux classes l est pour les deux', () {
    final registry = registryOf([
      passive('bond', classes: ['paladin', 'mage']),
    ]);
    expect(idsFor(paladin, registry), ['bond']);
    expect(idsFor(mage, registry), ['bond']);
  });

  test('tries par id, pas par ordre de lecture', () {
    final registry = registryOf([
      passive('zeal'),
      passive('aegis'),
      passive('mind', classes: ['paladin']),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'mind', 'zeal']);
  });

  test('le catalogue du registre n est pas reordonne', () {
    final registry = registryOf([passive('zeal'), passive('aegis')]);
    availablePassivesFor(paladin, registry);
    expect(registry.passives.map((p) => p.id), ['zeal', 'aegis']);
    expect(registry.cards.map((c) => c.id), ['lot_zeal', 'lot_aegis']);
  });

  test('le rang d affichage passe avant l id', () {
    final registry = registryOf([
      passive('aegis', displayOrder: 3),
      passive('zeal', displayOrder: 1),
      passive('mind', displayOrder: 2),
    ]);
    expect(idsFor(paladin, registry), ['zeal', 'mind', 'aegis']);
  });

  test('a rang egal, l id tranche : l ordre reste deterministe', () {
    final registry = registryOf([
      passive('zeal', displayOrder: 1),
      passive('aegis', displayOrder: 1),
    ]);
    expect(idsFor(paladin, registry), ['aegis', 'zeal']);
  });

  group('O5 : un passif sans lot n est pas disponible', () {
    test('sans carte de lot, absent ; avec une, present', () {
      final ward = passive('ward', classes: ['paladin']);
      expect(idsFor(paladin, registryOf([ward], cards: const [])), isEmpty);
      expect(
        idsFor(paladin, registryOf([ward], cards: [lotCardFor('ward')])),
        ['ward'],
      );
    });

    test('la carte de lot d un autre passif ne l ouvre pas', () {
      final registry = registryOf(
        [
          passive('ward', classes: ['paladin']),
          passive('zeal', classes: ['paladin']),
        ],
        cards: [lotCardFor('zeal')],
      );
      expect(idsFor(paladin, registry), ['zeal']);
    });

    test('une carte de lot de type quelconque suffit', () {
      for (final type in CardType.values) {
        final registry = registryOf(
          [passive('ward', classes: ['paladin'])],
          cards: [lotCardFor('ward', type: type)],
        );
        expect(idsFor(paladin, registry), ['ward'], reason: type.name);
      }
    });

    test('une neutre n ouvre aucun passif', () {
      const neutral = CardData(
        id: 'strike',
        cost: 1,
        type: CardType.attack,
        rarity: CardRarity.common,
        target: CardTarget.singleEnemy,
        effects: [],
      );
      final registry = registryOf(
        [passive('ward', classes: ['paladin'])],
        cards: const [neutral],
      );
      expect(idsFor(paladin, registry), isEmpty);
    });
  });
}
```

Les registres réels et construits — tests réécrits, ou neufs, dans les fichiers nommés :

`referential_integrity_test.dart`, à côté de « chaque classe a au moins un passif disponible » (`:146-160`), qui ne change pas :

```dart
  // O5 (spec P-42 T1 et P-44 lot 1, §4.8) : la disponibilité se lit sur le
  // registre. Aucun passif n'est nommé : la tranche qui livre un lot n'a
  // rien à réécrire ici.
  test('un passif est disponible pour sa classe si et seulement si il a un lot',
      () {
    final withLot = registry.cards.map((c) => c.passive).nonNulls.toSet();
    final offenders = <String>[];
    for (final hero in registry.heroes) {
      final available =
          availablePassivesFor(hero, registry).map((p) => p.id).toSet();
      for (final passive in registry.passives) {
        if (!(passive.classes?.contains(hero.id) ?? true)) continue;
        if (available.contains(passive.id) != withLot.contains(passive.id)) {
          offenders.add('${hero.id} → ${passive.id}');
        }
      }
    }
    expect(withLot, isNotEmpty);
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // Le nom du dossier est l'id du passif (spec §3.2) : un dossier mal nommé
  // ouvrirait un passif qui n'existe pas, et n'en ouvrirait aucun.
  test('chaque dossier de cards/ est l id d un passif', () {
    final passiveIds = registry.passives.map((p) => p.id).toSet();
    final folders = [
      for (final entity in Directory('assets/data/cards').listSync())
        if (entity is Directory)
          entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ];
    expect(folders, isNotEmpty);
    expect(folders.where((f) => !passiveIds.contains(f)), isEmpty);
  });
```

`passives_paladin_test.dart:206-213`, `passives_berserker_test.dart:248-255`, `passives_mage_test.dart:362-369` — chacun réécrit sur la disponibilité livrée :

```dart
    test('le Paladin ne propose que la Regeneration d Armure, seule pourvue '
        'd un lot (O5)', () async {
      final registry = await loadGameDataRegistry(rootBundle);
      final hero = registry.heroes.firstWhere((h) => h.id == 'paladin');
      final available = availablePassivesFor(hero, registry).map((p) => p.id);

      expect(available, ['regen_armor']);
    });
```

et de même `'le Berserker ne propose que Rage, seul pourvu d un lot (O5)'` → `['rage']`, `'le Mage demarre sur Flux de Mana, seul pourvu d un lot (O5)'` → `['mana_flux']`.

`class_selection_screen_test.dart` — `_registryOf` et `_buildAndReady` (`:345-395`) donnent son lot à chaque passif, sauf ceux qu'un test retire :

```dart
import '../unit/lot_card_fixture.dart'; // parmi les imports du fichier

GameDataRegistry _registryOf(
  List<HeroData> heroes, {
  List<PassiveData> passives = const [],
  List<SignatureData> signatures = const [],
  Set<String> withoutLot = const {},
}) => GameDataRegistry(
  enemies: const [],
  heroes: heroes,
  // Un passif n'est disponible que pourvu d'un lot (O5) : chacun reçoit une
  // carte de lot, sauf ceux que le test veut masquer.
  cards: [
    for (final passive in passives)
      if (!withoutLot.contains(passive.id)) lotCardFor(passive.id),
  ],
  events: const [],
  passives: passives,
  relics: const [],
  forgeUpgrades: const [],
  signatures: signatures,
);
```

`_buildAndReady` gagne le paramètre nommé `Set<String> withoutLot = const {}` et le passe à `_registryOf`. Au groupe « le passif montre est lu par le point d acces unique » (`:732`) :

```dart
    testWidgets('un passif sans carte de lot n est pas propose (O5)', (
      WidgetTester tester,
    ) async {
      await _buildAndReady(
        tester,
        passives: const [ward, aegis],
        withoutLot: const {'aegis'},
      );

      await _appuyerSurLaCarte(tester, 'Paladin');
      expect(_dansLaCarte('Paladin', find.text('Ward')), findsOneWidget);
      expect(find.text('Aegis'), findsNothing);
    });
```

`test/tutorial/tutorial_test_registry.dart` — un second passif ouvert à la demande, pour les tests qui changent de passif :

```dart
import 'package:flutter/services.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

import '../unit/lot_card_fixture.dart';

/// Registre bati sur les vraies donnees du depot, par le vrai chargeur.
///
/// Les tests du tutoriel utilisent les vraies donnees plutot que des fixtures
/// inventees : c est precisement la fidelite qu on cherche a garantir. Passer
/// par `loadGameDataRegistry` plutot que par `dart:io` ajoute une garantie —
/// ces tests exercent desormais le meme chemin de chargement que
/// l application, motifs de chemin et injection compris.
///
/// **Asynchrone** parce que le chargeur lit le bundle. Les fichiers de
/// `test/tutorial/` construisent le registre une seule fois, dans un
/// `setUpAll`. Ceux de `test/widget/` (`tutorial_class_step_test.dart`,
/// `tutorial_starter_draft_test.dart`, `tutorial_merge_transition_test.dart`)
/// le reconstruisent a chaque `testWidgets` : `GameDataRegistry` ecrit un
/// singleton statique dans son constructeur (`game_data_registry.dart:33`),
/// mais `cache: false` (`game_data_loader.dart`) rend chaque reconstruction
/// sure — sans lui, le `Future` de lecture mis en cache dans la zone d un
/// test deja termine ne se resoudrait jamais depuis le suivant.
///
/// Le registre livré n'ouvre qu'un passif par classe (O5, spec P-42 T1 et
/// P-44 lot 1, §4.8). [openedPassives] en ouvre d'autres, chacun par une
/// carte de lot de test : un test qui change de passif garde ainsi un choix
/// à faire, au lieu de « changer » pour le même.
Future<GameDataRegistry> buildTutorialTestRegistry({
  Set<String> openedPassives = const {},
}) async {
  final shipped = await loadGameDataRegistry(rootBundle);
  if (openedPassives.isEmpty) return shipped;
  return GameDataRegistry(
    enemies: shipped.enemies,
    heroes: shipped.heroes,
    cards: [
      ...shipped.cards,
      for (final id in openedPassives) lotCardFor(id),
    ],
    events: shipped.events,
    passives: shipped.passives,
    relics: shipped.relics,
    forgeUpgrades: shipped.forgeUpgrades,
    levelUpRewards: shipped.levelUpRewards,
    signatures: shipped.signatures,
    xpCurve: shipped.xpCurve,
    audio: shipped.audio,
  );
}
```

`tutorial_fixtures_test.dart:44-56` — l'attendu du Mage devient `'mana_flux'`, et le commentaire dit pourquoi (O5 : le seul passif du Mage pourvu d'un lot).

`tutorial_engine_test.dart`, groupe « Le choix du passif » (`:235-286`) — en tête du groupe, ses tests inchangés :

```dart
  group('Le choix du passif', () {
    // Le registre livré n'ouvre qu'un passif par classe (O5) : Bénédiction et
    // Marque du Mage, ouvertes par une carte de lot de test, gardent à ces
    // tests un second passif à choisir. Le registre ouvert reste le
    // singleton de la fin du fichier : il ne diffère du livré que par ces
    // deux cartes, qu'aucun autre groupe ne lit.
    late GameDataRegistry opened;

    setUpAll(() async {
      opened = await buildTutorialTestRegistry(
        openedPassives: const {'blessing', 'mage_mark'},
      );
    });

    setUp(() {
      engine = TutorialEngine(data: opened);
      engine.prepareStep(engine.currentStepIndex);
    });
```

`tutorial_class_step_test.dart` — `_pump(WidgetTester tester, {Set<String> openedPassives = const {}})` passe le paramètre à `buildTutorialTestRegistry` ; « toucher un passif deplie le retient » et « retaper une classe deja choisie ne reinitialise pas son passif » appellent `_pump(tester, openedPassives: const {'mage_mark'})` ; « choisir une classe l ecrit dans la tranche persistante » (`:132`) attend `'mana_flux'` sur le registre livré — le Mage démarre sur *Flux de Mana* au tutoriel (`tutorial_engine.dart:138-146`).

- [ ] **Step 3: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/passive_availability_test.dart test/unit/referential_integrity_test.dart test/unit/passives_paladin_test.dart test/unit/passives_berserker_test.dart test/unit/passives_mage_test.dart test/widget/class_selection_screen_test.dart test/tutorial/ test/widget/tutorial_class_step_test.dart`
Expected: échec — trois des quatre tests d'O5 (« une carte de lot de type quelconque suffit » passe aussi contre l'ancienne fonction, qui ouvre tout passif éligible), le test de disponibilité du registre réel, le test d'écran et les trois `passives_*` (le registre livré rend encore trois passifs par classe), `tutorial_fixtures_test` et `tutorial_class_step_test.dart:132` (`channeling`).

- [ ] **Step 4: Implémenter — `lib/game/systems/passive_availability.dart`, en entier**

```dart
import '../../models/data/game_data_registry.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/passive_data.dart';

/// Le point d'accès unique aux passifs qu'une classe peut prendre
/// (spec P-49, §4 ; spec P-42 T1 et P-44 lot 1, §4.8).
///
/// Tout lecteur qui choisit un passif passe par ici : l'écran de sélection,
/// le tutoriel. Aucun ne lit `PassiveData.classes` ni les lots lui-même.
/// Disponible vaut **éligible et pourvu d'un lot** : la classe figure dans
/// `classes`, et au moins une carte du registre porte ce passif, de quelque
/// type qu'elle soit (O5 : un passif dont le dossier `cards/<passif>/` est
/// vide ne se propose pas — un dossier vide n'existant pas au manifeste, la
/// règle se lit sur le registre, A4). Aucune liste de passifs n'est écrite
/// nulle part : le lot d'une tranche suivante ouvre son passif sans rien
/// changer ici. Le jour où la méta-progression (P-13) filtrera les passifs
/// débloqués, elle ajoutera sa condition dans cette fonction, sans toucher à
/// ses lecteurs.
///
/// Triés par `displayOrder` puis par `id` : le rang est déclaré par la donnée,
/// et l'`id` tranche à rang égal — pour ne dépendre ni de l'ordre de lecture
/// des fichiers ni de l'alphabet (spec P-41, §8.3).
/// Fonction pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
List<PassiveData> availablePassivesFor(
  HeroData hero,
  GameDataRegistry registry,
) {
  final withLot = registry.cards.map((card) => card.passive).nonNulls.toSet();
  return registry.passives
      .where((passive) =>
          (passive.classes?.contains(hero.id) ?? true) &&
          withLot.contains(passive.id))
      .toList()
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
}
```

- [ ] **Step 5: Lancer les tests, constater le succès**

Run: la commande du Step 3.
Expected: tout passe. Puis mesurer qu'aucun autre registre construit n'est touché : `git grep -n "availablePassivesFor\|ClassSelectionScreen\|TutorialEngine(" -- test` ne rend que les fichiers de cette tâche, `home_screen_menu_test.dart` et `home_screen_save_test.dart` (registres à `passives: const []`, qui n'attendent aucun passif), et les tests du tutoriel sur le registre livré.

- [ ] **Step 6: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1894** (1887 + 4 + 2 + 1).

- [ ] **Step 7: Commit**

`git add` par chemin, puis `git commit` — `feat(passifs): un passif sans lot quitte la selection`.

---

### Task 7 (interface): Le draft de départ — deux groupes, deux quotas

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 8.

**Files:**
- Create: `lib/game/systems/starter_draft.dart`, `test/unit/starter_draft_test.dart`
- Modify: `lib/ui/screens/starter_deck_draft_screen.dart:36-206` ; `lib/l10n/app_fr.arb:223-227`, `lib/l10n/app_en.arb` (mêmes clés)
- Test: `test/widget/starter_deck_draft_screen_test.dart`, `test/widget/starter_deck_draft_order_test.dart`

**Interfaces:**
- Consumes : `CardData.isOfferable(String?)` (Task 2).
- Produces :
  - `class StarterDraft` (`starter_draft.dart`, pur ; Q9, spec §4.9) :
    - `static const int deckSize = 5` ; `static const int lotQuotaCap = 2` ;
    - `factory StarterDraft.of(Iterable<CardData> cards, String? activePassiveId)` — les cartes `isOfferable(activePassiveId)`, triées par `CardData.compareByDisplayOrder`, séparées en `lot` (`passive != null`) et `neutrals` ;
    - `final List<CardData> lot`, `final List<CardData> neutrals` ; `List<CardData> get pool` (le lot puis les neutres) ;
    - `int get lotQuota => min(lotQuotaCap, lot.length)` ; `int get neutralQuota => deckSize - lotQuota` ;
    - `bool accepts(Iterable<CardData> chosen, CardData card)` — vrai si les cartes de `chosen` du groupe de `card` sont moins nombreuses que son quota ;
    - `bool isComplete(Iterable<CardData> chosen)` — exactement `lotQuota` du lot et `neutralQuota` neutres.
  - L'écran : `StarterDraft.of(gameData.cards, widget.passive?.id)` à la place de `_draftPool` ; deux sections dans un seul défilement, le lot puis les neutres, chacune un titre — `draftDeckLotSection(<nom du passif dans la langue>)`, `draftDeckNeutralSection` — et son compteur `draftDeckQuota(choisis, quota)` ; un groupe vide (run sans passif) n'a pas de section. Toucher une carte au-delà de son quota refuse et notifie `draftDeckSnackbarMaxLot(quota)` ou `draftDeckSnackbarMaxNeutral(quota)` en `NotificationType.warning`, comme aujourd'hui (`:68-85`) ; « Valider » s'active à `isComplete`. `CardDraftLayout` garde `draftDeckSelectedCount` (le total sous la grille, C1.6). Le deck : les cinq cartes choisies (E4). L'opacité « plafond atteint » (`:152-160`) se lit par groupe.
  - ARB, textes de spec §6.1 **mot pour mot** : `draftDeckSubtitle` réécrite ; `draftDeckLotSection` (`passive` String) ; `draftDeckNeutralSection` ; `draftDeckQuota` (`picked`, `quota` int) ; `draftDeckSnackbarMaxLot`, `draftDeckSnackbarMaxNeutral` (`quota` int). `draftDeckSnackbarMax` **supprimée** (C1.6).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/starter_draft_test.dart` *(nouveau ; cartes construites)* :
- `le pool : le lot du passif actif puis les neutres, chacun trie ; ni statut ni autre lot` — trois cartes de `rage` (raretés et coûts mêlés), deux de `fervor`, quatre neutres dont un statut : `lot` vaut les trois de `rage` triées, `neutrals` les trois neutres non statut triées ; `StarterDraft.of(cards, null).lot` est vide.
- `les quotas : 2 et 3, ajustes quand le lot a moins de deux cartes` — lot de 6 : (2, 3) ; de 1 : (1, 4) ; de 0 : (0, 5).
- `accepts refuse au-dela du quota de son groupe` — deux du lot choisies : une troisième du lot refusée, une neutre acceptée ; trois neutres : une quatrième refusée.
- `isComplete a 2 + 3, ou aux quotas ajustes` — lot de six : (2, 3) vrai ; (1, 4), (2, 2), (3, 2) faux ; lot d'une carte : (1, 4) vrai ; sans lot : (0, 5) vrai.

`starter_deck_draft_screen_test.dart` — `mockCards` gagne trois cartes `passive: 'regen_armor'` (`lot_1` à `lot_3`) et une `passive: 'fervor'` :
- Réécrit, même compte : « StarterDeckDraftScreen allows independent duplicate card selection » — 13 `UiCard` (3 du lot, 10 neutres, pas celle de `fervor`) ; il choisit deux cartes du lot et trois neutres ; l'aller-retour d'une sélection, le compteur total, puis le deck de cinq, sans signature, comme aujourd'hui.
- `deux sections titrees, chacune son compteur` — `find.text(l10n.draftDeckLotSection("Régénération d'Armure"))`, `find.text(l10n.draftDeckNeutralSection)`, `'0/2'` et `'0/3'` trouvés ; après une carte du lot, `'1/2'`.
- `au-dela d un quota, refus et notification` — trois cartes du lot touchées : `'2/2'`, la troisième non sélectionnée, le texte de `draftDeckSnackbarMaxLot(2)` affiché ; de même quatre neutres et `draftDeckSnackbarMaxNeutral(3)`.
- `Valider ne s active qu a 2 + 3` — à 2 + 2, puis 1 + 3, le bouton `draftDeckProceed` est inactif (`CardDraftLayout.isConfirmEnabled` faux) ; à 2 + 3, actif.

Réécrits, même compte : « le pool du draft de depart est celui d isOfferable » (Task 2) compte ses cartes par section ; `starter_deck_draft_order_test.dart` (un test) : son registre (`:88-96`), aujourd'hui sans carte de lot ni passif, gagne des cartes de lot d'un passif déclaré dans `passives`, déclarées dans le désordre comme le reste du pool, et l'écran (`:124`) reçoit ce passif au lieu de `passive: null` ; l'attendu devient l'ordre par section — le lot trié, puis les neutres triés.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/starter_draft_test.dart test/widget/starter_deck_draft_screen_test.dart test/widget/starter_deck_draft_order_test.dart`
Expected: échec de compilation — `StarterDraft` et les clés n'existent pas.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n`, la règle, puis l'écran.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1901** (1894 + 4 + 3). `git grep -n "draftDeckSnackbarMax\b" -- lib test` ne rend rien.

- [ ] **Step 6: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(draft): deux cartes du lot et trois neutres`.

---

### Task 8 (interface): Le tutoriel — le draft à 2 + 3, la leçon sans mécanisme, une règle de mana

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 9.

**Files:**
- Modify: `lib/tutorial/tutorial_fixtures.dart:66-70` ; `lib/models/data/card_data.dart:306-308` et `:443-448` (les commentaires d'`isOfferable` et de `compareByDisplayOrder`) ; `lib/tutorial/widgets/tutorial_starter_deck_widget.dart:9-95` ; `lib/tutorial/tutorial_data.dart:36-37`, `:43-44` ; `lib/tutorial/tutorial_engine.dart:237-275` (la leçon), `:367-374` (`playCard`)
- Test: `test/widget/tutorial_starter_draft_test.dart`, `test/tutorial/tutorial_engine_test.dart`, `test/tutorial/tutorial_fixtures_test.dart:123-130`, `test/tutorial/tutorial_prose_test.dart`

**Interfaces:**
- Consumes : `StarterDraft` (Task 7) ; `CostRules.canPay` (partie 1).
- Produces :
  - `StarterDraft TutorialFixtures.starterDraft(String? activePassiveId) => StarterDraft.of(registry.cards, activePassiveId)` — remplace `starterPool` (Task 2) ; ses lecteurs de test passent à `starterDraft(…).pool`. Les commentaires de `CardData.isOfferable` (`card_data.dart:306-307`, réécrit en Task 2 sur ses quatre lecteurs) et de `CardData.compareByDisplayOrder` (`:446`), qui nomment `TutorialFixtures.starterPool`, nomment `StarterDraft` : le premier dit boutique, trouvaille et `StarterDraft` (que lisent le draft de départ et le tutoriel), le second l'écran du draft et le tutoriel par `StarterDraft`.
  - `TutorialStarterDeckWidget` : le draft de `fixtures.starterDraft(engine.mockState.activePassive?.id)` ; « Choisissez 5 cartes » et `'n / 5'` (`:55-70`) cèdent la place aux deux sections et à leurs compteurs, mêmes clés que le jeu (`draftDeckLotSection`, `draftDeckNeutralSection`, `draftDeckQuota`) ; une carte refusée au-delà de son quota ne se sélectionne pas (sans notification : le tutoriel n'en a pas) ; `setStarterDeck(isComplete ? sélection : [])`. Le commentaire de tête dit que le pool est celui de `StarterDeckDraftScreen`, par `StarterDraft`. Le bandeau des signatures ne change pas.
  - L'étape « Votre deck de départ » : la première phrase devient celle de spec §6.2, **mot pour mot** — FR « Choisissez 2 cartes du lot de votre passif et 3 cartes neutres : elles forment votre deck de départ, celui avec lequel vous jouerez le reste du tutoriel. » ; EN « Pick 2 cards from your passive's set and 3 neutral cards: they form your starting deck, the one you will play the rest of the tutorial with. » La suite, sur les signatures, ne change pas.
  - A30 : `_isEnemyTargetingAttack` et `_isArmorGivingSkill` écartent une carte « à mécanisme » — `hpCost > 0`, `armorCost > 0`, ou un effet à `hits ≥ 2` ou à `scaleWith` —, par un prédicat privé du moteur ; le repli sur les fixtures existe déjà.
  - `playCard` : `if (!mockState.heroStats.canPay(mana: card.currentCost)) return false;` — la borne du jeu (`cost_rules.dart`), au lieu de la comparaison recopiée (`:368`) ; PV et Armure n'y entrent pas, A30 écartant de la leçon toute carte qui en coûte.

- [ ] **Step 1: Écrire les tests qui échouent**

`tutorial_starter_draft_test.dart` (le Paladin, *Régénération d'Armure*) :
- Neuf : `deux sections, le lot de Regeneration d Armure puis les neutres, compteurs 0/2 et 0/3` — les titres `draftDeckLotSection("Régénération d'Armure")` et `draftDeckNeutralSection`, `'0/2'`, `'0/3'` ; chaque carte de `starterDraft('regen_armor').lot` a sa clé `tutorial-pool-<id>`, aucune carte de `rage` ni de `mana_flux`.
- Réécrits, même compte : « le compteur démarre à 0/5 » → « les compteurs demarrent a 0/2 et 0/3 » ; « sélectionner 1 seule carte laisse le deck vide » → une carte du lot, `'1/2'`, deck vide ; « selectionner 5 cartes remplit le deck » → deux du lot, trois neutres, `'2/2'`, `'3/3'`, deck de 5 sans signature ; « la sélection est bornée à 5 » → « … bornee par les quotas » : trois cartes du lot et quatre neutres touchées, `'2/2'`, `'3/3'`, deck de 5.

`tutorial_engine_test.dart`, groupe « Semis des étapes Fusion et Jouer des cartes » :
- `la lecon ecarte une carte a couts, a coups ou a scaleWith` — deck `[bloodletting, rampart_slam, <Attaque construite singleEnemy [damage 2, hits 2, mightRatio 0.5]>, iron_wall]` : la main semée est `[strike_basic, defend_basic]` — *Défense de fer* est une Compétence d'Armure valide, seule l'attaque manque ; chaque critère oublié (coût en PV, croissance, coups) ferait entrer sa carte en main à côté d'elle (`tutorial_engine.dart:247-275`, `attack ??=`, `armorSkill ??=`) ; deck `[breach, heavy_strike, fortify, iron_wall]` : la main semée est `[heavy_strike, iron_wall]` — `armorCost` écarte *Percée* des attaques, le `scaleWith` de *Fortification* l'écarte des Compétences d'Armure.

`tutorial_prose_test.dart` :
- `l etape du deck de depart dit 2 du lot et 3 neutres` — `TutorialStepType.starterDeck` : `bodyFr` et `bodyEn` commencent par les phrases ci-dessus, mot pour mot.

Réécrits, même compte : `tutorial_fixtures_test.dart:123-130` — « le pool de départ est celui du prédicat d offre » lit `starterDraft('regen_armor')` : `lot` est le Rempart trié, `neutrals` les 15 neutres triées, `pool.every((c) => c.isOfferable('regen_armor'))` ; les lecteurs de `starterPool(…)` de la Task 2 passent à `starterDraft(…).pool`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/tutorial_starter_draft_test.dart test/tutorial/`
Expected: échec — `starterDraft` n'existe pas, la leçon garde `bloodletting` (la première Attaque `singleEnemy` du deck, `tutorial_engine.dart:250-253`), la prose dit « 5 cartes ».

- [ ] **Step 3: Implémenter** — les fixtures, le widget, la prose, la leçon, `playCard`. `tutorial_isolation_test.dart` reste vert : `starter_draft.dart` et `cost_rules.dart` n'importent pas Riverpod.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/widget/tutorial_play_card_step_test.dart test/widget/tutorial_merge_transition_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1904** (1901 + 1 + 1 + 1). `git grep -n "starterPool" -- lib test` ne rend rien.

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(tutoriel): draft a deux quotas, lecon sans mecanisme`.

---

### Task 9: L'éditeur de contenu — la carte de lot, dixième catégorie

**Files:**
- Modify: `lib/services/content_editor/class_recipe.dart:49-56` (le commentaire de `starterPassiveId`) ; `lib/services/content_editor/entity_descriptor.dart:19-32`, `:66-201`, `:209-243` ; `entity_draft.dart` ; `entity_catalog.dart` ; `entity_validator.dart:100-150`, `:555-627` ; `entity_writer.dart:270-290` ; `placeholder_filler.dart` ; `known_values.dart:51-60` ; `class_recipe.dart:96-105` ; `lib/ui/screens/content_editor_screen.dart:264`, `:860-970` ; `lib/ui/widgets/content_editor/entity_form.dart:282-300` ; `lib/ui/widgets/content_editor/editor_style.dart:107-117`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`, `entity_catalog_test.dart`, `entity_validator_test.dart`, `placeholder_filler_test.dart`, `shipped_entities_round_trip_test.dart`, `entity_draft_test.dart`, `entity_writer_test.dart`, `class_recipe_test.dart`, `fixtures.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes : `CardData.passive`, A8 (Task 1) ; `LotRules`, `PassiveFeeds` (Task 3) ; les lots livrés (Task 5).
- Produces :
  - `EntityCategory.lotCard` (dixième, après `card`) ; le commentaire de l'énumération dit dix sources pour dix catégories.
  - `enum EntityOwnerKind { heroClass, passive }` ; `EntityDescriptor.ownerKind` (`EntityOwnerKind?`, défaut `null`) **remplace** `supportsHeroClass` (A31 : la propriété à deux sortes). `String pathOf(String id, {String? owner})` — `heroClass` : `assets/data/classes/$owner/$directory/$id.json` ; `passive` : `assets/data/$directory/$owner/$id.json` ; sinon comme aujourd'hui.
  - `EntityDescriptor.alternativeKeys` (`Map<String, String>`, défaut vide) — clé du gabarit → clé qui la remplace : le remplissage ne pose pas la première quand la seconde est saisie. Carte et carte de lot : `{'cost': 'costs'}`.
  - Descripteur de carte (neutre seulement, spec §7) : `requiredKeys: {'type'}` (compte rendu §4 : `cost` ou `costs`, `CardData.fromJson` nomme l'absence des deux) ; `forbiddenKeys` gagne `passive` ; `enumKeys` gagne `'effects[].scaleWith.source': _names(ScaleSource.values)` ; `hits`, `mightRatio` et `costs` passent par le formulaire selon leur type JSON (`inferFieldKind`), et par `construct` pour leurs bornes. Gabarit inchangé.
  - Descripteur `lotCard` : `label: 'Carte de lot'`, `directory: 'cards'`, `ownerKind: EntityOwnerKind.passive`, les clés, énumérations, vocabulaires, ressources, `alternativeKeys` et le gabarit de la carte neutre ; `construct: CardData.fromJson`. Icône `Icons.collections_bookmark` dans `kCategoryIcons`.
  - `EntityDraft.owner` (`String?`) **remplace** `heroClass` ; `path => descriptor.pathOf(id, owner: owner)`. Tous ses lecteurs suivent (`placeholder_filler`, `entity_writer._registerSignature` sur `ownerKind == heroClass`, `class_recipe`, l'écran, le formulaire — ancre et clé de faute `'owner'`).
  - `entityFiles` : `ownerKind == passive` → pour chaque entrée de `assets/data/cards` qui n'est pas un `.json`, ses `.json` ; `entityIdsByOwner` : propriétaire `segments[3]` pour les deux sortes.
  - `knownValues` : la signature lit `[signature, card, lotCard]`, la carte `[card, lotCard]`, la carte de lot `[lotCard, card]` — un même vocabulaire.
  - `EntityValidator` : `_identity` — forme du propriétaire (`field: 'owner'`) ; propriétaire exigé si `ownerKind != null` (message nommant classe ou passif), refusé sinon ; sous `passive`, avec un registre, un passif inconnu du registre est refusé. `_construct` augmente le document de `heroClass` ou de `passive` selon `ownerKind`, jamais écrit dans le fichier. Famille neuve `_lotCard`, après `_construct` : avec un registre, `LotRules.faultsOf(CardData.fromJson({...compose(), 'passive': owner}), passive: <du registre>, heroClass: <la classe de passive.classes.single>)`, une `ValidationFault` par faute ; sans registre, sautée. `_registryIdsOf` : `card` et `lotCard` rendent tous deux les ids de `registry.cards` (un id ne se répète pas d'un dossier à l'autre, A2).
  - Deux commentaires que O5 rend faux (Task 6) se réécrivent : `class_recipe.dart:49-56` et `content_editor_screen_test.dart:686-688` disent qu'écrire le passif de départ garantit à la classe un passif disponible ; ils disent désormais que la recette écrit ce passif mais aucune carte, et que la classe créée n'a de passif jouable qu'une fois une carte de lot de ce passif écrite (catégorie `lotCard`) — jusque-là, sa sélection n'offre aucun passif.
  - L'écran : le propriétaire d'une carte de lot se choisit en pastilles, une par passif (`entityIdsByOwner` du descripteur de passif), colorée par le `themeColor` de la classe du passif ; celui d'une signature, comme aujourd'hui.

- [ ] **Step 1: Écrire les tests qui échouent**

`entity_descriptor_test.dart` :
- Neuf : `une carte de lot va dans cards/<passif>/` — `kEntityDescriptors[EntityCategory.lotCard]!.pathOf('kindle', owner: 'mana_flux')` vaut `assets/data/cards/mana_flux/kindle.json`.
- Neuf : `carte et carte de lot lisent scaleWith.source sur ScaleSource, et refusent passive` — `enumKeys['effects[].scaleWith.source']` vaut `_names(ScaleSource.values)` pour les deux ; `forbiddenKeys` des deux contient `passive` ; `requiredKeys` des deux vaut `{'type'}` ; `alternativeKeys` des deux vaut `{'cost': 'costs'}`.
- Réécrits : « la table couvre toutes les valeurs de EntityCategory » → `hasLength(10)` ; « seule la signature accepte une classe » → `la signature a pour proprietaire une classe, la carte de lot un passif, aucune autre` ; la table des gabarits gagne `lotCard` (les clés de la carte) ; « les vocabulaires fermes cote moteur sont declares » gagne `lotCard` ; le test de `pathOf` d'une signature passe par `owner:` ; le commentaire du compte des sources (Task 1) perd sa note.

`entity_catalog_test.dart` :
- `les cartes de lot se rangent sous leur passif, les neutres sans proprietaire` — bac à sable `cards/strike.json`, `cards/rage/bloodletting.json`, `cards/mana_flux/kindle.json` : `entityIdsByOwner` du descripteur de lot vaut `{'mana_flux': ['kindle'], 'rage': ['bloodletting']}`, celui de la carte `{null: ['strike']}`.

`entity_validator_test.dart`, groupe neuf `la carte de lot (A31)` — registre `fixtureRegistry(heroes: [fixtureHero('paladin'), <berserker portant la règle armor → convert>], passives: [fixturePassive('regen_armor', feeds: ['armor', 'cost:armor']), fixturePassive('rage', heroClass: 'berserker', feeds: ['cost:hp', 'cost:armor'])])` :
- `sans proprietaire, refusee` — une faute au champ `owner`.
- `un passif proprietaire inconnu est refuse` — `owner: 'zeal'` : champ `owner`, le message nomme `zeal`.
- `une carte de lot qui ne touche pas feeds est refusee` — Compétence `[draw 1]` sous `regen_armor` : une faute qui nomme `regen_armor`.
- `costs.armor sous une classe qui convertit l Armure est refuse` — `costs {mana 0, armor 4}` sous `rage` : une faute qui nomme la classe.
- `une neutre a costs.hp est refusee par le modele (A8)` — descripteur `card`, `costs {mana 0, hp 3}` : une faute du modèle qui contient `passive`.

`placeholder_filler_test.dart` :
- `le gabarit ne pose pas cost quand costs est saisi` — création d'une carte de lot au corps `{"costs": {"mana": 0, "hp": 4}, "type": "attack"}` : le document rempli n'a pas `cost`, a `costs`.

`shipped_entities_round_trip_test.dart` : `modifierDraft` lit le propriétaire `segments[3]` quand `descriptor.ownerKind != null` (signature sous `classes/`, carte de lot sous `cards/`) ; la boucle sur les descripteurs donne **un test de plus**, « Carte de lot : chaque fichier livre se modifie a l identique » (18 fichiers), sans autre code.

`content_editor_screen_test.dart` :
- `Carte de lot : les pastilles de proprietaire sont les passifs` — catégorie `lotCard` en création, bac à sable à deux passifs (`passives/regen_armor.json`, `passives/rage.json`) : deux pastilles, aux ids des passifs (`regen_armor`, `rage` — l'écran lit `entityIdsByOwner`) ; toucher l'une fixe le chemin affiché à `cards/<passif>/`.

Réécrits, même compte : partout où un test passe `heroClass:` à `EntityDraft` ou lit `supportsHeroClass` (`entity_descriptor_test`, `entity_draft_test`, `entity_validator_test`, `entity_writer_test`, `placeholder_filler_test`, `class_recipe_test`, `shipped_entities_round_trip_test`, `content_editor_screen_test`) : `owner:`, `ownerKind`, et la clé de faute `'owner'`. Les deux tests qui énumèrent les types de l'éditeur — `content_editor_screen_test.dart:127-137` (« les neuf types sont des boutons ») et `content_editor/editor_toolbar_test.dart:23-30` (« les neuf types sont des onglets ») — deviennent « les dix types », leur liste gagnant `'Carte de lot'` après `'Carte'`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/content_editor/ test/widget/content_editor_screen_test.dart test/widget/content_editor/`
Expected: échec de compilation — `EntityCategory.lotCard`, `ownerKind`, `owner`, `alternativeKeys` n'existent pas.

- [ ] **Step 3: Implémenter** — le descripteur et l'énumération, le brouillon, le catalogue, les valeurs connues, le validateur, le remplissage, l'écrivain, la recette, puis l'écran et le formulaire.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1915** (1904 + 2 + 1 + 5 + 1 + 1 + 1). `git grep -n "supportsHeroClass" -- lib test` ne rend rien.

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(editeur): la carte de lot, dixieme categorie`.

---

### Task 10: Vérification finale (orchestrateur)

Aucun fichier modifié : des commandes, jouées par l'orchestrateur, sans agent.

- [ ] **Step 1: L'analyse** — `dart analyze` → `No issues found!`
- [ ] **Step 2: La suite** — `rm -rf build/unit_test_assets` puis `flutter test` → `All tests passed!`, **1915**.
- [ ] **Step 3: Le point propre au vérificateur (spec §11)** — `flutter test test/unit/card_catalog_test.dart --reporter expanded` → verts, nommément : « D45 : chaque carte de lot touche une entree des feeds de son passif », « D17 : aucune neutre ne porte de cout autre que du mana », « D50 : … aucun lot n en porte plus d une », « D38 : la somme hits x mightRatio ne depasse pas le cout en mana + 1, cartes et signatures », « D38 : un effet a plusieurs coups declare mightRatio < 1 ».
- [ ] **Step 4: Les greps de la spec (§11, « Ce que le vérificateur contrôle »)**
  - `git grep -n "onDamagingCardPlayed" -- lib test assets` → rien (D34) ; `grep -c '"trigger": "onAttackPlayed"' assets/data/passives/mage_mark.json` → `1`.
  - `ls assets/data/cards/focus.json assets/data/cards/demon_form.json` → deux « No such file » ; `ls assets/data/cards/rage/demon_form.json` → le fichier.
  - `ls assets/data/cards/strike_basic.json assets/data/cards/defend_basic.json assets/data/cards/fireball.json` → les trois, que `TutorialFixtureIds` (`tutorial_fixtures.dart:18-20`) nomme toujours.
  - `git diff main -- tool/simulations` → vide.
  - `dart run tool/sync_assets.dart --check` → code de sortie 0.
- [ ] **Step 5: Les greps propres à la partie 2**
  - `git grep -n '"passive"' -- assets/data/cards` → rien (le répertoire impose `passive`).
  - `git grep -nE "isOfferable[^(]" -- lib test` → rien qu'en commentaire, ou en titre de groupe ou de test (`card_offer_filter_test.dart:34`, `group('CardData.isOfferable', …)` ; `starter_deck_draft_screen_test.dart:290`, « le pool du draft de depart est celui d isOfferable … ») : le prédicat prend toujours le passif actif.
  - `git grep -n "starterPool\|supportsHeroClass\|draftDeckSnackbarMax\b\|CardManaMedallion" -- lib test` → rien.
  - `git grep -n "'focus'" -- lib test` → rien.
  - `git diff --name-only 1b2008e -- assets/data` → exactement les dix-sept cartes neuves, `cards/rage/demon_form.json`, `cards/demon_form.json` et `cards/focus.json` (supprimées) et les neuf `passives/*.json`.
  - `git status --short` → seul le fichier d'orchestration, que l'orchestrateur tient ; aucun `generated_plugin*` ni `GeneratedPluginRegistrant.swift` modifié.
