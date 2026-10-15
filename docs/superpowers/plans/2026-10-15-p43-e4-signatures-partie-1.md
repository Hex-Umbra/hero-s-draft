# P-43 E4, partie 1 — Les signatures : la donnée, le modèle, le moteur, la sauvegarde — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, aucune signature n'est une carte — ni dans le registre, ni dans un deck, ni dans un pool, ni dans une sauvegarde — et le moteur sait les jouer, prouvé sans écran : les six fichiers vivent sous `classes/<id>/skills/`, lus par un `SignatureData` propre ; `RunState.signatures` les porte, relues de la classe ; `CombatController.playSignature` les résout comme une carte, avec une recharge de deux tours remise à zéro à chaque combat ; `unique`, `isAcquirable`, `CardCategory` et `CardData.heroClass` disparaissent ; le draft de départ, le tutoriel et l'éditeur de contenu suivent.

**Architecture:** Un modèle à part (`SignatureData`, `registry.signatures`) tient les signatures hors de tout pool par construction ; elles se jouent par une **vue de carte** (`SignatureInstance.asCard`) que `EffectResolver.resolveCard` et les stratégies lisent sans changer. La recharge est un tour de disponibilité (`CombatState.signaturesReadyOn`), écrit au jeu, lu par soustraction, jamais décompté ni sérialisé. Le jeu d'une carte et celui d'une signature partagent une seule suite — passifs, reliques, nettoyage —, extraite d'`applyPlayerCardPlay`. La liste des signatures de la run vit dans `RunState`, relue de la classe à la reprise comme `statRules`.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `tool/sync_assets.dart`.

**Spec:** `docs/superpowers/specs/2026-10-15-p43-e4-signatures-design.md` — §11 « Partie 1 » pour le périmètre, toute la spec pour le contenu, les lignes « 1 » de la table §10. Les décisions de §1 (D49, D41, D53, D7, D28 ; les réponses du propriétaire de §1.2, dont Q-P1 (a) et Q-P2 (a) ; A1 à A13) sont acquises : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-15-p43-e4-signatures-design-verifications.md`.

Réponses du propriétaire, reprises telles quelles (spec §1.2) : recharge 2 pour les six aux coûts d'aujourd'hui (Châtiment 1, Bouclier Sacré 1, Frappe Téméraire 2, Posture de Rage 1, Projectile Magique 1, Surtension de Mana 0) ; l'épuisement disparaît ; une signature jouée déclenche les passifs de son type ; **Q-P1 (a)** — les quatre reliques (*Amulette du Mage*, *Plume de scribe* sur `onCardPlayed` ; *Shuriken*, *Croc Kunaï* sur `onAttackPlayed`) voient une signature jouée par le même événement que les passifs, un seul chemin dans le code ; **Q-P2 (a)** — tutoriel : la prose seule (partie 2).

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
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit (`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres au lot :

- **La branche.** Le plan s'exécute sur `feat/v0.5.6-p43-e4-signatures`, la branche courante, dans le checkout principal. Il ne crée aucune branche, n'en change pas, ne commite rien sur `main`, ne pousse rien. Pas de worktree.
- **La base de tests** : `flutter test` rend **1625** sur la branche aujourd'hui. Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ».
- **Aucun test neuf ne porte un littéral que vise la commande de §12** : ni `'unique'`, `"unique"`, `` `unique` ``, ni `CardCategory`, `isOfferableTo`, `isAcquirable`, `characterSpecific`, `isUnique`, `rarityUnique`. Pour éprouver un refus de `rarity`, la valeur est `'rare'`. Avant la Task 7, `CardData` exige `category` à la construction (`card_data.dart:144`) : un `CardData` neuf d'un test des Tasks 1 à 6 se construit par `CardData.fromJson` sans clé `category` — que `fromJson` remplit d'ici là par son repli `global` (`card_data.dart:196-199`), et qu'il refusera seulement si elle est présente après la Task 7.
- **`tool/simulations/` ne change pas** : le script lit `classes/*/cards/` et cessera de tourner (spec §2, ADR-108 D5) ; il reste `dart analyze` propre — il n'importe rien de `lib/`.
- **`assets/data/passives/mage_mark.json` ne change pas** (spec §4.5).
- **Les références `fichier:ligne`** de ce plan ont été relues le 2026-10-15 sur `6cf2789`. Une tâche qui modifie un fichier décale les lignes des tâches suivantes : l'implémenteur se fie au symbole nommé, la ligne n'est qu'un repère.
- **Ce que la partie 1 laisse en place, voulu** (spec §11) : entre les deux parties, une run démarre à 5 cartes sans signature accessible à l'écran ; la prose du tutoriel (`tutorial_data.dart:35-44`, `:281`, `:297-298`) et le libellé « Ajoutées d'office » du bandeau du deck de départ restent ceux d'aujourd'hui — la partie 2 les réécrit. Aucune clé ARB n'est ajoutée ici.

## Review Focus

Cinq modes d'échec que la spec implique et qu'aucun test ne garde encore, du plus grave au moins grave ; chacun est confié à la tâche qui écrit le test qui le garde.

1. **Un refus qui laisse une trace.** `playSignature` refusée — tour ennemi, combat fini, signature hors de la run, en recharge, `singleEnemy` sans `enemyId` malgré une sélection restante, mana insuffisant — doit rendre `false` sans avoir payé de mana, déplacé la sélection ni posé de recharge. → **Task 4** (`combat_signature_test.dart` : cinq tests de refus, dont « mana insuffisant » qui asserte `selectedEnemyId` inchangé, et le refus en recharge dans le test « recharge 2 »).
2. **Une signature jouée qui n'atteint pas tout ce qui écoute une carte jouée**, ou une extraction qui change le jeu d'une carte : passifs du type (*Soif de Sang* par `reckless_strike`, *Flux de Mana* par `magic_missile`, *Marque du Mage* muette sur `magic_missile`), reliques de Q-P1 (*Amulette du Mage*, *Shuriken*), et `applyPlayerCardPlay` aux mêmes événements qu'avant. → **Task 4** (cinq tests de `combat_signature_test.dart`, un test neuf de `combat_controller_test.dart`).
3. **Une recharge décalée d'un tour, ou qui survit au combat.** Jouée au tour T avec `cooldown` 2 : refusée à T et T+1, prête à T+2 ; `cooldown` 1 : prête à T+1 ; un `initializeCombat` neuf rend tout prêt. → **Task 4** (trois tests) et `combat_state_test.dart` (la dérivation).
4. **Une signature écrite dans la sauvegarde, ou relue d'ailleurs que de la classe** : `masterDeck` sans signature, aucune clé `signatures` ni id de signature dans le JSON, relecture par `skills` ; classe inconnue → liste vide ; id de `skills` absent du registre → reprise refusée (question T tranchée, voir Task 3). → **Task 3** (`save_service_test.dart`, `run_state_persistence_test.dart`).
5. **Une signature redevenue carte** — dans `registry.cards`, homonyme d'une carte, dans le deck de départ ou le pool du draft. → **Task 2** (`referential_integrity_test.dart` « aucun id de signature n'est un id de carte » ; deck de départ à 5 cartes, écran et tutoriel) et **Task 3** (la run reçoit les signatures de la classe).

**Les autres trous remontés par la vérification de la spec** (section « Pour le Review Focus du plan »), chacun confié à un test nommé :

| Trou | Tâche, test |
|:---|:---|
| Audio des signatures contrôlé (`/skills/`) | Task 2, `audio_catalogue_test` |
| La forge à 17 cartes | Task 2, `forge_upgrades_catalog_test` « la matrice couvre les 17 cartes livrées » |
| Le draft de départ (`starter_deck_draft_screen_test.dart:286`, `:304-307`) ; `tutorial_starter_draft_test.dart:58-73` | Task 2 (5 cartes), Task 3 (signatures de la run), Task 7 (pool `isOfferable`) |
| Le test de régression `smite` du tutoriel (`tutorial_engine_test.dart:603-630`) | Task 2, reformulé sur une attaque à Armure synthétique |
| `tutorial_engine_test.dart:527` devenu trivial | Task 2, titre reformulé sur l'amorce de la Fusion |
| `sync_assets --check` après le déplacement | Task 2 et Task 8 |
| L'éditeur : 9 catégories, chemin `skills/`, round-trip du descripteur de signature construit sans `heroClass` dans le document, la recette qui écrit une signature qui se valide | Task 5 |
| Une signature neuve sans propriétaire dans l'éditeur | Task 5, `entity_validator_test` (question T tranchée) |
| Une neutre homonyme d'une signature : l'éditeur ne la voit pas, seul le test d'intégrité la voit (`entity_validator_test.dart:70-88` à reformuler) | Task 2 (ids disjoints), Task 5 (reformulation) |
| `RunState.copyWith` garde `signatures` | Task 3, `run_state_persistence_test` |
| `copyableCards` rend une liste neuve et modifiable | Task 6, `deck_controller_test` |
| `shop_controller_test.dart:629-646` sans leurre vérifie encore le tirage | Task 6, deux cartes copiables légitimes |
| Les tests dont l'objet disparaît, retirés ou réécrits ; aucune fixture ni locale orpheline (`shop_screen_test`, `shop_controller_test`, `reward_controller_test`) | Tasks 2, 6, 7 |
| `CardData.fromJson` refuse `heroClass` et `category`, nommés ; `toJson` ne les écrit plus ; une `CardInstance` sauvée puis relue passe | Task 7, `card_offer_filter_test` |
| Le `git grep` de §12 vide ; la suite complète verte en fin de partie 1 | Task 8 |

**Reportés au plan de la partie 2** : la priorité des états de la barre, le ciblage depuis Flame (carte focalisée prioritaire, annulation), l'onglet « Signatures » du dictionnaire en troisième position, le bandeau du tutoriel ; et `SignatureData.getDescription`, sans lecteur avant les tuiles (arbitrage de l'orchestrateur, T, filtre 5).

---

## Carte des fichiers

| Fichier | Rôle | Tâche |
|:---|:---|:---:|
| `lib/models/data/signature_data.dart` *(nouveau)* | `SignatureData` : la donnée d'une signature, ses règles de chargement | 1 |
| `lib/models/signature_instance.dart` *(nouveau)* | `SignatureInstance` : la signature telle qu'elle se joue, et sa vue de carte | 1, 7 |
| `lib/models/data/game_data_registry.dart` | `signatures`, défaut `const []` | 1 |
| `lib/models/data/hero_skills_link.dart` | `getSignatures` ; `getHeroCards` retirée | 1, 2 |
| `assets/data/classes/<c>/cards/*.json` → `assets/data/classes/<c>/skills/*.json` | Les six fichiers déplacés | 2 |
| `pubspec.yaml` (section `assets:` seule) | Régénérée par `sync_assets` | 2 |
| `lib/services/game_data_service.dart` | La source des signatures remplace celle des cartes de classe ; plus d'injection de `category` | 2, 7 |
| `lib/services/game_data_loader.dart` | Commentaires d'exemple (`skills/`) | 2 |
| `lib/ui/screens/starter_deck_draft_screen.dart` | Deck de 5 cartes ; signatures à la run ; pool `isOfferable` | 2, 3, 7 |
| `lib/tutorial/tutorial_engine.dart`, `tutorial_fixtures.dart`, `widgets/tutorial_starter_deck_widget.dart` | Les deux lectures du tutoriel ; `fixtures.signature` ; `starterPool` par `isOfferable` | 2, 7 |
| `lib/game/controllers/run_controller.dart` | `RunState.signatures`, `startNewRun`, relecture | 3 |
| `lib/models/combat_state.dart` | `signaturesReadyOn`, `signatureTurnsLeft`, `isSignatureReady` | 4 |
| `lib/game/controllers/combat_controller.dart` | `playSignature`, `_afterCardPlayed` | 4 |
| `lib/services/content_editor/{entity_descriptor,entity_catalog,entity_draft,entity_validator,entity_writer,class_recipe}.dart` | La neuvième catégorie | 2 (une ligne), 5 |
| `lib/ui/screens/content_editor_screen.dart`, `lib/ui/widgets/content_editor/{entity_form,editor_style}.dart` | Libellés, tri des fautes, icône | 5, 6 |
| `lib/models/data/card_data.dart` | Purge : `unique`, `isAcquirable` ; `CardCategory`, `heroClass`, `isOfferable`, refus | 6, 7 |
| `lib/models/data/model_extensions.dart`, `lib/game/components/card_component.dart`, `lib/ui/widgets/ui_card.dart`, `lib/ui/widgets/ui_card/{polychromatic_border,ui_card_helpers}.dart`, `lib/ui/theme/{app_colors,game_theme_extension}.dart` | Les bras et branches `unique` | 6 |
| `lib/game/controllers/{deck_controller,shop_controller,reward_controller}.dart`, `lib/game/services/forge_rune_rules.dart` | `copyableCards`, B5, prix, commentaires ; prédicat d'offre | 6, 7 |
| `CLAUDE.md`, `README.md` | L'arbre `skills/` ; la règle des champs imposés | 2, 7 |
| `test/unit/signature_data_test.dart`, `signature_instance_test.dart`, `combat_signature_test.dart`, `combat_state_test.dart` *(nouveaux)* | — | 1, 4 |
| `test/unit/signature_cards_transition_test.dart` | **Supprimé** (A12) | 2 |
| Les autres tests touchés | Nommés tâche par tâche | 1 à 7 |

Ordre et atomicité : les tâches 1 et 3 à 5 sont additives ; la tâche 2 est **grosse par atomicité** — dès que les fichiers quittent `cards/`, le registre réel perd six cartes, et tout ce qui les lisait (draft, tutoriel, bijection de l'éditeur sur le vrai disque, cinq tests du bundle réel) doit suivre dans le même commit. La sauvegarde (Task 3) vient **après** le déplacement : `class_identity_test.dart:130-145` relit une run par `fromJsonWithReport` sur le vrai registre, et `getSignatures` lèverait tant que `registry.signatures` est vide. Les deux purges (Tasks 6 et 7) viennent en dernier ; chacune est atomique à la compilation (un enum ou un champ retiré casse tous ses lecteurs d'un coup), d'où leur taille.

---

### Task 1: Le modèle — `SignatureData`, `SignatureInstance`, le registre, le lien de classe

Additive : rien de ce qui existe ne change de comportement.

**Files:**
- Create: `lib/models/data/signature_data.dart`, `lib/models/signature_instance.dart`
- Modify: `lib/models/data/game_data_registry.dart:12-52`, `lib/models/data/hero_skills_link.dart`
- Test: `test/unit/signature_data_test.dart` *(nouveau)*, `test/unit/signature_instance_test.dart` *(nouveau)*, `test/unit/hero_skills_link_test.dart`

**Interfaces:**
- Consumes: `CardType`, `CardTarget`, `CardEffect`, `CardData`, `CardRarity` (`card_data.dart`), `AudioSource` (`lib/services/audio/audio_source.dart`), `CardInstance`.
- Produces:
  - `class SignatureData implements AudioSource` — `const SignatureData({required String id, required String heroClass, String nameEn = '', String nameFr = '', String descriptionEn = '', String descriptionFr = '', required int cost, required int cooldown, required CardType type, CardTarget target = CardTarget.singleEnemy, String? animation, String? sfx, required List<CardEffect> effects})` ; champs finaux de mêmes noms ; `static const Set<CardType> playableTypes = {CardType.attack, CardType.skill, CardType.power}` ; `String getName(String locale)` (comme `CardData` ; son lecteur est le bandeau du tutoriel, Task 2) — **pas de `getDescription`** : aucun lecteur en partie 1, la partie 2 l'ajoute avec les tuiles ; `factory SignatureData.fromJson(Map<String, dynamic> json)`. Ni `toJson`, ni `getById` (spec §3.1).
  - `class SignatureInstance` — `const SignatureInstance(this.data)` ; `final SignatureData data` ; `int get cost` ; `int get cooldown` ; `CardInstance get asCard`.
  - `GameDataRegistry.signatures` — `final List<SignatureData> signatures`, paramètre nommé `this.signatures = const []`.
  - `extension HeroSkillsLink on HeroData` gagne `List<SignatureData> getSignatures(GameDataRegistry gameData)`.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/signature_data_test.dart` — un `Map<String, dynamic> valid()` local : `id` `smite`, `heroClass` `paladin`, les quatre proses, `cost` 1, `cooldown` 2, `type` `attack`, `target` `singleEnemy`, `animation` `melee`, `sfx` `hit`, `effects` `[{type: damage, value: 6}, {type: armor, value: 4}]`. Chaque refus s'asserte `throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('<clé>')))` :
- `une signature valide se lit entiere` — chaque champ égale la donnée ; `isA<AudioSource>()` ; `effects` de longueur 2, `effects.first.value` 6.
- `cooldown absent est refuse` — clé `cooldown`.
- `cooldown 0 est refuse` — clé `cooldown` (0 est le plancher de *Célérité*, D54).
- `cooldown negatif est refuse` — clé `cooldown`.
- `cost absent ou negatif est refuse` — deux assertions, clé `cost`.
- `type status ou inconnu est refuse` — `status` puis `inconnu`, clé `type`.
- `rarity est refusee, nommee` — `'rarity': 'rare'`, clé `rarity`.
- `isExhaust est refuse, nomme` — `'isExhaust': false`, clé `isExhaust` (même `false` : la clé est une promesse que le moteur ne tient pas, A11).
- `category est refusee, nommee` — `'category': 'global'`, clé `category`.
- `effects vide ou absent est refuse` — deux assertions, clé `effects`.
- `heroClass absent est refuse` — clé `heroClass` (exigé : le chargeur l'injecte depuis le dossier).
- `une prose absente ou vide est refusee, nommee` — `name_en` retiré, puis `description_fr` vide : clé nommée à chaque fois.
- `target absente vaut singleEnemy` — `target` retiré → `CardTarget.singleEnemy`.

`test/unit/signature_instance_test.dart` — sur une `SignatureData` construite (type `skill`, cible `self`, `cost` 1, `cooldown` 2, effets `armor` 8 et `heal` 2, `animation` `buff`, `sfx` `shield`) :
- `cost et cooldown rendent la donnee` — 1 et 2.
- `asCard reprend id, noms, descriptions, type, cible, cout, animation, sfx et effets` — `asCard.data.<champ>` égale la donnée, `effects.map((e) => e.value)` `[8, 2]`.
- `asCard est commune, sans rune, et ne s epuise pas` — `asCard.rarity` et `asCard.data.rarity` `CardRarity.common` ; `forgeUpgrades` vide ; `data.isExhaust` faux ; `exhaustsOnPlay` faux.
- `effective rend les valeurs du fichier` — `asCard.effective.cost` 1, `asCard.effective.effects.map((e) => e.value)` `[8, 2]`, `asCard.currentCost` 1 (G1 à `fusionRank` 0, `card_data.dart:69-76`).

`test/unit/hero_skills_link_test.dart` — le test existant (`getHeroCards`) reste jusqu'à la Task 2 ; deux tests neufs sur un registre construit avec `signatures` :
- `getSignatures rend les signatures dans l ordre de skills` — `skills: ['b', 'a']` → ids `['b', 'a']`.
- `une signature introuvable leve au lieu d etre avalee` — `skills: ['absente']` → `throwsStateError`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_data_test.dart test/unit/signature_instance_test.dart test/unit/hero_skills_link_test.dart`
Expected: échec de compilation — `SignatureData`, `SignatureInstance`, `getSignatures` n'existent pas.

- [ ] **Step 3: Implémenter**

- `SignatureData.fromJson` — règles de la spec §3.1, chaque faute en `FormatException` qui nomme la clé et l'id : `rarity`, `isExhaust`, `category` présents → refus (A11) ; `heroClass` chaîne non vide exigée ; `name_en`, `name_fr`, `description_en`, `description_fr` chaînes non vides exigées, **sans repli** sur `name` / `description` ; `cost` entier ≥ 0 exigé ; `cooldown` entier ≥ 1 exigé ; `type` parmi `playableTypes` (par `name`) ; `target` comme une carte (`orElse: singleEnemy`, `card_data.dart:205-208`) ; `effects` liste non vide, chaque élément par `CardEffect.fromJson` ; `animation`, `sfx` facultatifs.
- `SignatureInstance` — `cost` et `cooldown` rendent `data.cost` et `data.cooldown` (la vague 5 y appliquera les évolutions). `asCard` construit à chaque appel une `CardInstance` neuve sur un `CardData` qui reprend `id`, les quatre proses, `cost` (le getter, pas `data.cost`), `type`, `target`, `animation`, `sfx`, `effects`, avec `rarity: CardRarity.common`, `isExhaust: false`, et `category: CardCategory.global` — ce dernier argument part à la Task 7. Aucune rune.
- `GameDataRegistry` : le champ et son paramètre, documenté comme `levelUpRewards` (défaut vide pour ne pas casser les registres de test).
- `getSignatures` : `skills` mappés sur `gameData.signatures` par `firstWhere` **sans** `orElse` — fail-fast, comme `getHeroCards` (`hero_skills_link.dart:7-9`).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/signature_data_test.dart test/unit/signature_instance_test.dart test/unit/hero_skills_link_test.dart`
Expected: tout passe (13 + 4 + 3).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1644** (1625 + 13 + 4 + 2).

- [ ] **Step 6: Commit**

`git add lib/models/data/signature_data.dart lib/models/signature_instance.dart lib/models/data/game_data_registry.dart lib/models/data/hero_skills_link.dart test/unit/signature_data_test.dart test/unit/signature_instance_test.dart test/unit/hero_skills_link_test.dart` puis `git commit` — `feat(signatures): le modele SignatureData et sa vue de carte`.

---

### Task 2: Le déplacement — les six fichiers sous `skills/`, le chargeur, le draft, le tutoriel

**Grosse par atomicité** (voir la carte des fichiers) : à la fin de cette tâche, aucune signature n'est plus dans `registry.cards`, et tout lecteur a suivi.

**Files:**
- Move (`git mv`) et Modify : `assets/data/classes/paladin/cards/{smite,holy_shield}.json`, `assets/data/classes/berserker/cards/{reckless_strike,rage_form}.json`, `assets/data/classes/mage/cards/{magic_missile,mana_surge}.json` → `…/skills/<id>.json`
- Modify: `pubspec.yaml` (section `assets:` par l'outil), `lib/services/game_data_service.dart:52-91`, `:151-162`, `lib/services/game_data_loader.dart:6-12`, `:21-26` (commentaires), `lib/models/data/hero_skills_link.dart`, `lib/ui/screens/starter_deck_draft_screen.dart:10`, `:89-117`, `lib/tutorial/tutorial_engine.dart:167-190`, `:251-262`, `:424-430`, `lib/tutorial/tutorial_fixtures.dart`, `lib/tutorial/widgets/tutorial_starter_deck_widget.dart:41-44`, `lib/services/content_editor/entity_validator.dart:514`, `:526`, `:531`, `CLAUDE.md:47`, `:72`, `:80`, `README.md:64`, `:69-74`
- Delete: `test/unit/signature_cards_transition_test.dart`
- Test: `test/unit/real_bundle_load_test.dart`, `test/unit/referential_integrity_test.dart`, `test/unit/forge_upgrades_catalog_test.dart`, `test/unit/audio/audio_catalogue_test.dart`, `test/unit/hero_skills_link_test.dart`, `test/tutorial/tutorial_engine_test.dart`, `test/tutorial/tutorial_fixtures_test.dart`, `test/widget/tutorial_starter_draft_test.dart`, `test/widget/starter_deck_draft_screen_test.dart`, `test/unit/content_editor/entity_validator_test.dart:409-470`

**Interfaces:**
- Consumes: `SignatureData.fromJson`, `GameDataRegistry.signatures` (Task 1).
- Produces: `registry.signatures` peuplé (6) par `loadGameDataRegistry` ; `TutorialFixtures.signature(String id) → SignatureData` ; `HeroSkillsLink.getHeroCards` n'existe plus.

- [ ] **Step 1: Réécrire les tests, constater qu'ils échouent**

- `real_bundle_load_test.dart` — `:68` garde `6` (profondeur 6 inchangée), raison « signatures » ; `:95` `registry.cards` `hasLength(17)` ; dans le même test, `registry.signatures` `hasLength(6)` et la table des six, qui fige les valeurs du propriétaire et D28 : `{for (final s in registry.signatures) s.id: (s.heroClass, s.cost, s.cooldown, s.type)}` égale `smite (paladin, 1, 2, attack)`, `holy_shield (paladin, 1, 2, skill)`, `reckless_strike (berserker, 2, 2, attack)`, `rage_form (berserker, 1, 2, skill)`, `magic_missile (mage, 1, 2, skill)`, `mana_surge (mage, 0, 2, skill)`. Le test du manifeste garde ses 94 fichiers.
- `referential_integrity_test.dart:157-183` réécrit — `chaque id de skills est une signature de sa classe, rangee sous elle` : pour chaque id de `hero.skills`, une `registry.signatures` de cet id existe, son `heroClass` vaut `hero.id`, et `assets/data/classes/<hero>/skills/<id>.json` existe.
- `referential_integrity_test.dart:211-229` réécrit — `chaque dossier skills contient exactement les signatures de sa classe` : `Directory('assets/data/classes/<hero>/skills')`, même filtre `.json`, égal à `hero.skills.toSet()`.
- `referential_integrity_test.dart`, neuf — `aucun id de signature n est un id de carte` : `registry.signatures` non vide, et l'intersection des ids de `registry.signatures` et de `registry.cards` est vide (garde à la fois les pools, le `masterDeck` et les sources de statut `card:<id>`).
- `forge_upgrades_catalog_test.dart` — `_signatures` (`:196-205`) et la boucle `:302-308` retirés (**−6**) ; `:283` devient `la matrice couvre les 17 cartes livrees`, `registry.cards` égal à `_offers.keys.toSet()` ; le commentaire `:207` dit 17.
- `audio/audio_catalogue_test.dart:44` — le filtre devient `/skills/` ; le compte reste **55**, la raison dit « 6 signatures ».
- `hero_skills_link_test.dart` — le test de `getHeroCards` retiré (**−1**).
- `tutorial_engine_test.dart` — `:461` `expectedSize` vaut `5` ; `:467-484` titre `setStarterDeck([]) vide le deck` ; `:507` `hasLength(5)` ; `:518-541` titre `la Fusion seme 3 exemplaires d une carte du deck`, l'assertion `:527` et le commentaire `:524-526` partent, l'amorce (`:531-539`) reste ; `:602-630` reformulé — `Jouer des cartes n utilise jamais une attaque qui donne aussi de l Armure comme geste d attaque` : `setStarterDeck([attaqueArmure, engine.fixtures.card('heavy_strike'), engine.fixtures.card('iron_wall')])` où `attaqueArmure` est construite par `CardData.fromJson` sans `category` (attaque, `'target': 'singleEnemy'` explicite, effets `damage` et `armor`) ; `iron_wall` est indispensable : la leçon exige les deux gestes, et sans Compétence `self` à Armure dans le deck `_seedPlayCardHand` se replie sur les fixtures (`tutorial_engine.dart:272-275`), si bien que `heavy_strike` n'arriverait jamais en main ; `prepareStep(7)` ; la main ne contient pas l'id d'`attaqueArmure` et contient `heavy_strike`.
- `tutorial_fixtures_test.dart`, deux neufs — `la fixture signature resout les six signatures` (pour chaque héros des fixtures, chaque id de `skills` résout une `SignatureData` de ce `heroClass`, six en tout) ; dans « Politique fail-fast », `une signature absente leve` (`throwsStateError`).
- `tutorial_starter_draft_test.dart` — `:58` titre `selectionner 5 cartes remplit le deck des 5 cartes choisies, sans signature` : `hasLength(5)`, aucun id parmi `holy_shield`, `smite` ; `:86` `hasLength(5)`.
- `starter_deck_draft_screen_test.dart` — la `CardData` `holy_shield` sort de `mockCards` (ce n'est plus une carte) ; `:280-292` : le deck fait **5** cartes, toutes `slash*`/`shield*`, aucune `holy_shield`. `mockHero.skills` reste `['holy_shield']` (lu à la Task 3).
- `content_editor/entity_validator_test.dart:409-470` — le groupe devient `bijection skills <-> skills/` : le bac à sable écrit `classes/gambler/skills/`, les messages attendus disent `skills/`.

Run: `flutter test test/unit/real_bundle_load_test.dart test/unit/referential_integrity_test.dart test/tutorial/`
Expected: FAIL (le registre porte encore 23 cartes, `registry.signatures` est vide, `fixtures.signature` n'existe pas).

- [ ] **Step 2: Déplacer et corriger les six fichiers**

Par fichier : `git mv assets/data/classes/<c>/cards/<id>.json assets/data/classes/<c>/skills/<id>.json`, puis : `"rarity"` retiré ; `"isExhaust"` retiré (`holy_shield`, `mana_surge`) ; `"cooldown": 2` inséré juste après `"cost"` ; `magic_missile` passe à `"type": "skill"` (D28). Noms, descriptions, cibles, effets, `animation` inchangés ; aucun `heroClass`. `class.json` ne change pas.

- [ ] **Step 3: Le chargeur, le lien, le draft, le tutoriel, l'éditeur, la doc**

- `loadGameDataRegistry` : la source `classes/*/cards/*.json` (`:82-90`) est retirée ; une `loader.loadAll<SignatureData>([EntitySource('assets/data/classes/*/skills/*.json', SignatureData.fromJson, inject: (c) => {'id': c[1], 'heroClass': c[0]})])` est ajoutée — neuf `EntitySource(` en tout, compte inchangé (`entity_descriptor_test.dart:35`) — et passée en `signatures:` au registre. La source neutre garde son injection de `category` jusqu'à la Task 7.
- `game_data_loader.dart` : les deux exemples de commentaire disent `classes/paladin/skills/smite.json` (« une signature du paladin ») et `classes/*/skills/*.json`.
- `hero_skills_link.dart` : `getHeroCards` retirée ; l'import de `card_data.dart` part s'il n'a plus de lecteur.
- `StarterDeckDraftScreen._startAdventure` : le deck est **les 5 cartes choisies**, rien d'autre ; `getHeroCards`, la locale `gameData` (`:92`, dont c'était le seul lecteur — `unused_local_variable`) et l'import de `hero_skills_link.dart` partent (la Task 3, Step 4, rétablit les deux derniers) ; le filtre du pool ne change pas encore (Task 7).
- `TutorialEngine.setStarterDeck` : `masterDeck` = les cartes choisies, sans lecture de `chosenHero` ; la doc (`:167-172`) le dit. Les commentaires `:251-262` (la régression `smite`) et `:424-430` (« cartes de classe, rareté `unique` ») sont réécrits sans `smite` ni `unique` : la garde `_isEnemyTargetingAttack` écarte toute attaque qui donne aussi de l'Armure, et la Fusion sème la première carte du deck qui fusionne.
- `TutorialFixtures.signature(String id)` → `registry.signatures.firstWhere((s) => s.id == id)`, fail-fast comme `card`.
- `tutorial_starter_deck_widget.dart:41-44` : la liste lue devient `chosenHero?.skills.map(widget.engine.fixtures.signature)` (`List<SignatureData>`, variable `signatures`) ; le bandeau garde son libellé, lu par `getName(locale)` (réécrit en partie 2).
- `entity_validator.dart:514` : le dossier lu par `_signatureCards` devient `classes/<id>/skills` ; ses deux messages disent `skills/`. Rien d'autre de l'éditeur ne change ici (Task 5) : sans cette ligne, chaque `class.json` livré échouerait la bijection sur le vrai disque (`shipped_entities_round_trip_test.dart`).
- `CLAUDE.md:47` (`classes/*/skills/*.json`), `:72` (« A signature filed under `assets/data/classes/paladin/skills/` *is* a paladin signature »), `:80` (`skills/<id>.json`) ; `README.md:64-65` (une signature rangée dans `classes/paladin/skills/`), `:74` (`skills/<id>.json # signatures de la classe`). `CLAUDE.md:89` et `README.md:93` attendent la Task 7, où leur nouvelle phrase devient vraie.
- Supprimer `test/unit/signature_cards_transition_test.dart` (**−4**, A12).

- [ ] **Step 4: Régénérer les assets et purger le cache de test**

Run: `dart run tool/sync_assets.dart` → `pubspec.yaml` déclare `assets/data/classes/<c>/skills/` à la place des trois `cards/` (`:38`, `:40`, `:42`), rien d'autre ne bouge (`version:` intact). Puis `dart run tool/sync_assets.dart --check` → code de sortie 0. Puis `rm -rf build/unit_test_assets`.

- [ ] **Step 5: Lancer les tests ciblés**

Run: `flutter test test/unit/real_bundle_load_test.dart test/unit/referential_integrity_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/audio/ test/tutorial/ test/widget/tutorial_starter_draft_test.dart test/widget/starter_deck_draft_screen_test.dart test/unit/content_editor/`
Expected: tout passe.

- [ ] **Step 6: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1636** (1644 − 6 − 4 − 1 + 1 + 2) ; `git grep -n "getHeroCards" -- lib test` → vide ; `git grep -nE "classes/[^ ]*/cards" -- lib ':!lib/services/content_editor'` → vide (dans l'éditeur, `entity_catalog.dart:33`, `:67` et `entity_descriptor.dart:174` répondent encore jusqu'à la Task 5, qui passe le grep complet).

- [ ] **Step 7: Commit**

`git add` par chemin (les six déplacements, `pubspec.yaml`, les fichiers de `lib/`, `CLAUDE.md`, `README.md`, les tests, la suppression) puis `git commit` — `feat(signatures): les six signatures quittent les cartes pour skills`.

---

### Task 3: La sauvegarde — `RunState.signatures`, relues de la classe, jamais sérialisées *(tâche à risque)*

**Files:**
- Modify: `lib/game/controllers/run_controller.dart:1-23`, `:24-223`, `:266-290` ; `lib/ui/screens/starter_deck_draft_screen.dart:112-117`
- Test: `test/unit/save_service_test.dart`, `test/unit/run_state_persistence_test.dart`, `test/widget/starter_deck_draft_screen_test.dart`

**Interfaces:**
- Consumes: `SignatureData`, `SignatureInstance`, `GameDataRegistry.signatures`, `getSignatures` (Task 1) ; les six signatures dans le registre réel (Task 2).
- Produces: `RunState.signatures` (`List<SignatureInstance>`, défaut `const []`) ; `RunState.copyWith({…, List<SignatureInstance>? signatures})` ; `RunController.startNewRun(HeroData chosenClass, [PassiveData? activePassive, List<SignatureData> signatures = const []])`.

**Question T tranchée — un id de `skills` absent du registre à la reprise.** Choix : **fail-fast** — `getSignatures` lève, `SaveService.load` attrape (`save_service.dart:135-140`), efface la sauvegarde et rend `success: false`, le chemin d'une sauvegarde illisible. Écartées : filtrer l'id en silence (filtre 5 — un seul lien de classe, `hero_skills_link.dart` refuse déjà tout filtrage silencieux) ; un `MissingSaveItem` (filtre 5 — la signature n'est pas dans la sauvegarde, A8 : le rapport mentirait, et n'a ni nom ni catégorie à donner). Le cas ne survient pas avec les données livrées : `referential_integrity_test` le garde (Task 2).

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/save_service_test.dart`, imports ajoutés : `deck_controller.dart`, `card_instance.dart`, `card_data.dart`, `hero_skills_link.dart`, `signature_data.dart`. En tête du groupe `SaveService` :

```dart
    const smite = SignatureData(
      id: 'smite',
      heroClass: 'paladin',
      nameEn: 'Smite',
      nameFr: 'Châtiment',
      descriptionEn: 'Deal 6 damage.',
      descriptionFr: 'Inflige 6 dégâts.',
      cost: 1,
      cooldown: 2,
      type: CardType.attack,
      effects: [CardEffect(type: 'damage', value: 6)],
    );
    const holyShield = SignatureData(
      id: 'holy_shield',
      heroClass: 'paladin',
      nameEn: 'Holy Shield',
      nameFr: 'Bouclier Sacré',
      descriptionEn: 'Gain 8 Block.',
      descriptionFr: "Donne 8 d'Armure.",
      cost: 1,
      cooldown: 2,
      type: CardType.skill,
      target: CardTarget.self,
      effects: [CardEffect(type: 'armor', value: 8)],
    );
```

Puis, à la suite des tests existants :

```dart
    test('une run d E4 sauvee puis rechargee : le deck sans signature, les '
        'signatures relues de la classe, rien d ecrit', () async {
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'holy_shield'],
      );
      // Par `fromJson`, sans `category` : ce test traverse la Task 7 intact.
      final strike = CardData.fromJson(
          {'id': 'strike', 'cost': 1, 'type': 'attack', 'effects': <dynamic>[]});
      final registry = GameDataRegistry(
        enemies: const [],
        heroes: const [paladin],
        cards: [strike],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
        signatures: const [smite, holyShield],
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(runProvider.notifier)
          .startNewRun(paladin, null, paladin.getSignatures(registry));
      container.read(deckProvider.notifier).initializeStarterDeck(
          [for (var i = 0; i < 5; i++) CardInstance(data: strike)]);
      expect(
        container.read(runProvider).signatures.map((s) => s.data.id),
        ['smite', 'holy_shield'],
      );
      await SaveService.save(container.read);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('run_save')!;
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      expect((payload['run'] as Map<String, dynamic>).containsKey('signatures'),
          isFalse);
      expect(raw, isNot(contains('holy_shield')),
          reason: 'aucune signature ecrite, ni dans la run ni dans le deck');

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(result.missingItems, isEmpty);
      final deck = fresh.read(deckProvider).masterDeck;
      expect(deck, hasLength(5));
      expect(deck.map((c) => c.data.id), everyElement('strike'));
      expect(
        fresh.read(runProvider).signatures.map((s) => s.data.id),
        paladin.skills,
      );
    });

    test('une classe inconnue du registre reprend sans signature', () async {
      // Le registre du setUp ne connait aucune classe : les signatures
      // donnees au depart ne survivent pas a la reprise, preuve qu elles ne
      // sont pas lues dans la sauvegarde.
      const dummyHero = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(runProvider.notifier)
          .startNewRun(dummyHero, null, const [smite]);
      await SaveService.save(container.read);

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isTrue);
      expect(fresh.read(runProvider).signatures, isEmpty);
    });

    test('un id de skills absent du registre fait echouer la reprise et '
        'efface la sauvegarde', () async {
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'absente'],
      );
      GameDataRegistry(
        enemies: const [],
        heroes: const [paladin],
        cards: const [],
        events: const [],
        passives: const [],
        relics: const [],
        forgeUpgrades: const [],
        signatures: const [smite],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(runProvider.notifier).startNewRun(paladin);
      await SaveService.save(container.read);

      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);
      final result = await SaveService.load(fresh.read);

      expect(result.success, isFalse);
      expect(await SaveService.hasSave(), isFalse);
    });
```

Dans `test/unit/run_state_persistence_test.dart`, import de `card_data.dart`, `signature_data.dart`, `signature_instance.dart`, et un test :

```dart
    test('copyWith garde les signatures de la run', () {
      const signature = SignatureInstance(SignatureData(
        id: 'smite',
        heroClass: 'paladin',
        cost: 1,
        cooldown: 2,
        type: CardType.attack,
        effects: [CardEffect(type: 'damage', value: 6)],
      ));
      final run = RunState(
        currentLevel: 1,
        heroStats: EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0),
        heroClassId: 'paladin',
        signatures: const [signature],
      );

      expect(run.copyWith(currentLevel: 2).signatures, [signature]);
      expect(run.toJson().containsKey('signatures'), isFalse);
    });
```

(Si `EntityStats` n'est pas encore importé par ce fichier, l'importer depuis `models/entity_stats.dart`.)

Dans `test/widget/starter_deck_draft_screen_test.dart` : `mockRegistry` reçoit `signatures: [holy_shield]` — une `SignatureData` `holy_shield`, `heroClass` `paladin`, skill `self`, coût 1, recharge 2 — et le test `:207` asserte, après le tap, `container.read(runProvider).signatures.map((s) => s.data.id)` égal à `['holy_shield']`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/save_service_test.dart test/unit/run_state_persistence_test.dart test/widget/starter_deck_draft_screen_test.dart`
Expected: échec de compilation (`RunState.signatures`, troisième paramètre de `startNewRun`).

- [ ] **Step 3: Implémenter `RunState.signatures`**

Dans `lib/game/controllers/run_controller.dart`, imports ajoutés (forme des voisins) : `../../models/data/game_data_registry.dart`, `../../models/data/hero_skills_link.dart`, `../../models/data/signature_data.dart`, `../../models/signature_instance.dart`.

Le champ, après `statRules` :

```dart
  /// Les signatures de la run (spec P-43 E4, §9 ; A8), dans l'ordre de
  /// `HeroData.skills`. Hors du deck : le `masterDeck` n'en porte jamais.
  ///
  /// **Jamais sérialisées**, comme [statRules] : une signature d'E4 est du
  /// contenu, que `fromJsonWithReport` relit de la classe. La vague 5 y
  /// ajoutera ses évolutions — et leur sauvegarde — sans déplacer le champ.
  final List<SignatureInstance> signatures;
```

Le constructeur gagne `this.signatures = const [],` ; `copyWith` gagne `List<SignatureInstance>? signatures,` et `signatures: signatures ?? this.signatures,`. `toJson` ne change pas.

Dans `fromJsonWithReport`, après `statRules:` :

```dart
      signatures: _signaturesOf(json['heroClassId'] as String),
```

et, dans `RunState` :

```dart
  /// Les signatures de la classe [heroClassId], relues du registre chargé.
  /// Registre absent ou classe inconnue : aucune, comme `statRules`. Un id de
  /// `skills` absent du registre lève (`getSignatures`, fail-fast) : la
  /// sauvegarde est alors illisible, et `SaveService.load` l'efface.
  static List<SignatureInstance> _signaturesOf(String heroClassId) {
    final hero = HeroData.getById(heroClassId);
    if (hero == null) return const [];
    return [
      for (final data in hero.getSignatures(GameDataRegistry.instance!))
        SignatureInstance(data),
    ];
  }
```

`startNewRun` :

```dart
  void startNewRun(
    HeroData chosenClass, [
    PassiveData? activePassive,
    List<SignatureData> signatures = const [],
  ]) {
```

et, dans le `RunState(...)` qu'il construit, `signatures: [for (final data in signatures) SignatureInstance(data)],`. Un troisième **positionnel** optionnel : Dart n'admet pas un nommé à côté du positionnel `activePassive`, et la centaine d'appels de test reste inchangée.

- [ ] **Step 4: Le draft de départ donne ses signatures à la run**

Dans `StarterDeckDraftScreen._startAdventure`, rétablir la locale `final gameData = ref.read(gameDataLoaderProvider).requireValue;` (la Task 2 l'a retirée avec son seul lecteur, `getHeroCards` — `unused_local_variable` l'exigeait), réimporter `hero_skills_link.dart` ; l'appel devient `.startNewRun(widget.playerClass, widget.passive, widget.playerClass.getSignatures(gameData))` — l'unique appel de `lib/` (`starter_deck_draft_screen.dart:114-116`).

- [ ] **Step 5: Lancer les tests, constater le succès**

Run: `flutter test test/unit/save_service_test.dart test/unit/run_state_persistence_test.dart test/widget/starter_deck_draft_screen_test.dart test/unit/class_identity_test.dart`
Expected: tout passe — `class_identity_test` relit une run du Berserker sur le vrai registre, `getSignatures` y trouve ses deux signatures.

- [ ] **Step 6: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1640** (1636 + 3 + 1).

- [ ] **Step 7: Commit**

`git add lib/game/controllers/run_controller.dart lib/ui/screens/starter_deck_draft_screen.dart test/unit/save_service_test.dart test/unit/run_state_persistence_test.dart test/widget/starter_deck_draft_screen_test.dart` puis `git commit` — `feat(signatures): la run porte ses signatures, relues de la classe`.

---

### Task 4: Jouer une signature — la recharge, `playSignature`, la suite commune *(tâche à risque)*

**Files:**
- Modify: `lib/models/combat_state.dart`, `lib/game/controllers/combat_controller.dart:1-21`, `:207-276`
- Create: `test/unit/combat_signature_test.dart`, `test/unit/combat_state_test.dart`
- Test: `test/unit/combat_controller_test.dart`

**Interfaces:**
- Consumes: `SignatureInstance` (`cost`, `cooldown`, `asCard`), `RunState.signatures`, `startNewRun(…, signatures)` (Tasks 1, 3) ; `EffectResolver.canPlayCard` / `resolveCard` (`effect_resolver.dart:104-155`) ; `effectRegistryProvider`.
- Produces: `CombatState.signaturesReadyOn` (`Map<String, int>`, défaut vide, non modifiable), `CombatState.signatureTurnsLeft(String id) → int`, `CombatState.isSignatureReady(String id) → bool`, `CombatState.copyWith({…, Map<String, int>? signaturesReadyOn})` ; `CombatController.playSignature(SignatureInstance signature, {String? enemyId}) → bool`. La partie 2 lit ces quatre noms.

- [ ] **Step 1: Écrire le test du jeu d'une signature**

`test/unit/combat_signature_test.dart` :

```dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/controllers/combat_controller.dart';
import 'package:roguelike_card_game/game/controllers/deck_controller.dart';
import 'package:roguelike_card_game/game/controllers/inventory_controller.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/game_constants.dart';
import 'package:roguelike_card_game/game/systems/passives/passive_counters.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/hero_skills_link.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/signature_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/map_node.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Le jeu d'une signature (spec P-43 E4, §4.2 à §4.4) — tâche à risque.
///
/// Les signatures sont les vraies, lues du bundle. Le héros est neutre — ni
/// critique ni Maîtrise — pour que chaque compte soit exact.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDataRegistry registry;
  setUpAll(() async {
    registry = await loadGameDataRegistry(rootBundle);
  });

  late ProviderContainer container;
  late RunController run;
  late CombatController combat;
  late DeckNotifier deck;

  setUp(() {
    container = ProviderContainer();
    run = container.read(runProvider.notifier);
    combat = container.read(combatProvider.notifier);
    deck = container.read(deckProvider.notifier);
  });
  tearDown(() => container.dispose());

  EntityStats hero() => run.currentState.heroStats;
  EnemyInstance enemy() => combat.currentState.enemies.single;
  SignatureInstance signature(String id) =>
      run.currentState.signatures.singleWhere((s) => s.data.id == id);
  SignatureData shipped(String id) =>
      registry.signatures.singleWhere((s) => s.id == id);
  PassiveData passive(String id) =>
      registry.passives.singleWhere((p) => p.id == id);

  /// Une run de [classId] avec les vraies signatures de la classe (ou
  /// [signatures]), un deck de dix Frappes dont cinq en main, et un combat
  /// contre un Slime de 200 PV que personne ne cible encore.
  void start(
    String classId, {
    PassiveData? withPassive,
    List<SignatureData>? signatures,
  }) {
    run.startNewRun(
      HeroData(id: classId, classCard: '$classId.png', maxHp: 100, maxMana: 3),
      withPassive,
      signatures ??
          registry.heroes
              .singleWhere((h) => h.id == classId)
              .getSignatures(registry),
    );
    final strike = registry.cards.singleWhere((c) => c.id == 'strike_basic');
    deck.initializeStarterDeck(
        [for (var i = 0; i < 10; i++) CardInstance(data: strike)]);
    deck.startCombat(
        handSize: 5, maxHandSize: GameConstants.startingMaxHandSize);
    combat.updateState(CombatState(
      enemies: [
        EnemyInstance(
          data: registry.enemies.singleWhere((e) => e.id == 'slime'),
          stats: EntityStats(maxPv: 200, currentPv: 200, armure: 0, might: 0),
        ),
      ],
      turnPhase: TurnPhase.player,
    ));
  }

  /// Le tour ennemi puis l'ouverture du tour joueur suivant : `turnCount`
  /// monte d'un, le mana revient au maximum, l'armure à zéro.
  void nextTurn() {
    combat.startEnemyTurn();
    combat.endEnemyTurn();
    run.startTurn();
  }

  group('le jeu', () {
    test('paie le cout, resout, et met la signature en recharge', () {
      start('paladin');
      final target = enemy().id;

      expect(combat.playSignature(signature('smite'), enemyId: target), isTrue);

      expect(hero().currentMana, 3 - 1);
      expect(enemy().stats.currentPv, 200 - 6);
      expect(hero().armure, 4);
      expect(combat.currentState.selectedEnemyId, target);
      expect(combat.currentState.signatureTurnsLeft('smite'), 2);
      expect(combat.currentState.isSignatureReady('smite'), isFalse);
    });

    test('recharge 2 : refusee au meme tour, encore au suivant, prete au '
        'troisieme', () {
      start('paladin');
      final smite = signature('smite');
      expect(combat.playSignature(smite, enemyId: enemy().id), isTrue);

      expect(combat.playSignature(smite, enemyId: enemy().id), isFalse);
      nextTurn();
      expect(combat.currentState.signatureTurnsLeft('smite'), 1);
      expect(combat.playSignature(smite, enemyId: enemy().id), isFalse);
      nextTurn();
      expect(combat.currentState.isSignatureReady('smite'), isTrue);
      expect(combat.playSignature(smite, enemyId: enemy().id), isTrue);
    });

    test('recharge 1 : refusee au meme tour, prete au suivant', () {
      const quick = SignatureData(
        id: 'eclair_test',
        heroClass: 'paladin',
        nameEn: 'Test',
        nameFr: 'Test',
        descriptionEn: 'Test',
        descriptionFr: 'Test',
        cost: 0,
        cooldown: 1,
        type: CardType.skill,
        target: CardTarget.self,
        effects: [CardEffect(type: 'armor', value: 1)],
      );
      start('paladin', signatures: const [quick]);
      final eclair = signature('eclair_test');

      expect(combat.playSignature(eclair), isTrue);
      expect(combat.currentState.signatureTurnsLeft('eclair_test'), 1);
      expect(combat.playSignature(eclair), isFalse);
      nextTurn();
      expect(combat.playSignature(eclair), isTrue);
    });

    test('un initializeCombat neuf rend toutes les signatures pretes', () {
      start('paladin');
      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.currentState.isSignatureReady('holy_shield'), isFalse);

      combat.initializeCombat(1, MapNodeType.combat, registry.enemies);

      expect(combat.currentState.turnCount, 1);
      expect(combat.currentState.signaturesReadyOn, isEmpty);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });
  });

  group('les refus, sans effet', () {
    test('mana insuffisant : ni le mana, ni la recharge, ni la selection ne '
        'bougent', () {
      start('berserker');
      run.updateState(run.currentState
          .copyWith(heroStats: hero().copyWith(currentMana: 1)));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isFalse,
      );

      expect(hero().currentMana, 1);
      expect(enemy().stats.currentPv, 200);
      expect(combat.currentState.isSignatureReady('reckless_strike'), isTrue);
      expect(combat.currentState.selectedEnemyId, isNull);
    });

    test('cible unique sans enemyId : refusee malgre une selection restante',
        () {
      start('paladin');
      combat.selectEnemy(enemy().id); // laissee par une carte precedente

      expect(combat.playSignature(signature('smite')), isFalse);

      expect(hero().currentMana, 3);
      expect(enemy().stats.currentPv, 200);
      expect(combat.currentState.isSignatureReady('smite'), isTrue);
    });

    test('refusee au tour ennemi', () {
      start('paladin');
      combat.startEnemyTurn();

      expect(combat.playSignature(signature('holy_shield')), isFalse);

      expect(hero().armure, 0);
      expect(hero().currentMana, 3);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });

    test('refusee une fois le combat fini', () {
      start('paladin');
      combat.updateState(combat.currentState.copyWith(isCombatEnded: true));

      expect(combat.playSignature(signature('holy_shield')), isFalse);

      expect(hero().currentMana, 3);
      expect(combat.currentState.isSignatureReady('holy_shield'), isTrue);
    });

    test('une signature hors de la run est refusee', () {
      start('paladin');

      expect(
        combat.playSignature(SignatureInstance(shipped('mana_surge'))),
        isFalse,
      );

      expect(hero().currentMana, 3);
    });
  });

  group('hors des piles', () {
    test('main, pioche, defausse, epuisement et deck identiques', () {
      start('paladin');
      final before = container.read(deckProvider);

      expect(combat.playSignature(signature('holy_shield')), isTrue);

      final after = container.read(deckProvider);
      expect(after.hand, before.hand);
      expect(after.drawPile, before.drawPile);
      expect(after.discardPile, before.discardPile);
      expect(after.exhaustPile, before.exhaustPile);
      expect(after.masterDeck, before.masterDeck);
    });

    test('holy_shield et mana_surge ne s epuisent plus : rejouables a T+2',
        () {
      start('paladin',
          signatures: [shipped('holy_shield'), shipped('mana_surge')]);

      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.playSignature(signature('mana_surge')), isTrue);
      expect(container.read(deckProvider).exhaustPile, isEmpty);

      nextTurn();
      nextTurn();

      expect(combat.playSignature(signature('holy_shield')), isTrue);
      expect(combat.playSignature(signature('mana_surge')), isTrue);
      expect(container.read(deckProvider).exhaustPile, isEmpty);
    });
  });

  group('ce qui ecoute une carte jouee', () {
    test('reckless_strike arme Soif de Sang', () {
      start('berserker', withPassive: passive('bloodthirst'));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isTrue,
      );

      expect(hero().statuses.any((s) => s.id == 'lifesteal'), isTrue);
    });

    test('magic_missile, Competence depuis D28, fait monter Flux de Mana', () {
      final flux = passive('mana_flux');
      start('mage', withPassive: flux);

      expect(
        combat.playSignature(signature('magic_missile'), enemyId: enemy().id),
        isTrue,
      );

      expect(PassiveCounters.valueOf(run, flux), 1);
    });

    test('magic_missile ne pose pas Vulnerable sous Marque du Mage', () {
      start('mage', withPassive: passive('mage_mark'));

      expect(
        combat.playSignature(signature('magic_missile'), enemyId: enemy().id),
        isTrue,
      );

      expect(
          enemy().stats.statuses.any((s) => s.id == 'vulnerable'), isFalse);
    });

    test('l Amulette du Mage voit une signature jouee (Q-P1)', () {
      start('paladin');
      container.read(inventoryProvider.notifier).addRelic(
          registry.relics.singleWhere((r) => r.id == 'mage_amulet'));

      expect(combat.playSignature(signature('holy_shield')), isTrue);

      expect(hero().armure, 8 + 1);
    });

    test('le Shuriken compte reckless_strike comme une Attaque (Q-P1)', () {
      start('berserker');
      container.read(inventoryProvider.notifier).addRelic(
          registry.relics.singleWhere((r) => r.id == 'shuriken'));

      expect(
        combat.playSignature(signature('reckless_strike'), enemyId: enemy().id),
        isTrue,
      );

      expect(
        hero().statuses.singleWhere((s) => s.id == 'shuriken_charge').value,
        1,
      );
    });
  });
}
```

- [ ] **Step 2: Écrire les tests de l'état et de la suite commune**

`test/unit/combat_state_test.dart` *(nouveau)* :
- `la table est vide par defaut, et toute signature est prete` — `CombatState().signaturesReadyOn` vide ; `isSignatureReady('smite')` vrai ; `signatureTurnsLeft('smite')` 0.
- `signatureTurnsLeft se derive du tour courant, jamais negatif` — `signaturesReadyOn: {'smite': 3}` : `turnCount` 1 → 2, 2 → 1, 3 → 0 et prête, 5 → 0.
- `copyWith porte la table` — `copyWith(turnCount: 2).signaturesReadyOn` égal à `{'smite': 3}` ; `copyWith(signaturesReadyOn: const {})` la vide.
- `toJson n ecrit aucune cle de signature` — sur `signaturesReadyOn: {'smite': 3}`, aucune clé de `toJson()` ne contient `signature`, et `jsonEncode(toJson())` ne contient pas `smite`.

`test/unit/combat_controller_test.dart`, un test neuf, groupe du jeu d'une carte — `applyPlayerCardPlay garde ses evenements : onCardPlayed puis le type, passifs puis reliques, puis le nettoyage` : héros sans passif, reliques `mage_amulet` (`onCardPlayed`, `gain_armor` 1) et `shuriken` (`onAttackPlayed`, `charge_might_combat` 1) construites dans le fichier ; l'Attaque et la Compétence par `CardData.fromJson`, sans `category` (contrainte globale) ; une Attaque `singleEnemy` à coût 0 et 999 dégâts sur l'ennemi sélectionné de 10 PV → Armure 1, `shuriken_charge` 1, l'ennemi passé de `enemies` à `defeatedEnemies`, la carte en défausse ; puis une Compétence `self` à coût 0 (`'target': 'self'` explicite : `fromJson` retombe sinon sur `singleEnemy`, `card_data.dart:205-208`, et la sélection a disparu avec l'ennemi, `combat_controller.dart:350-354`, si bien que `canPlayCard` la refuserait) → Armure 2, `shuriken_charge` toujours 1. L'Attaque porte de même `'target': 'singleEnemy'` explicite.

- [ ] **Step 3: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/combat_signature_test.dart test/unit/combat_state_test.dart test/unit/combat_controller_test.dart`
Expected: échec de compilation (`playSignature`, `signaturesReadyOn`, `signatureTurnsLeft`, `isSignatureReady`).

- [ ] **Step 4: Implémenter la recharge dans `CombatState`**

`import 'dart:math' show max;` en tête. Le champ, après `isVictory` :

```dart
  /// Par id de signature, le tour à partir duquel elle se rejoue (spec P-43
  /// E4, §4.2 ; A7). Absente : disponible. Écrite une fois, au jeu ; lue par
  /// soustraction ; jamais décomptée. Un `CombatState` neuf la porte vide —
  /// toutes les signatures sont prêtes au premier tour de chaque combat
  /// (D41). **Jamais sérialisée** : ni `toJson` ni `fromJson` ne la lisent.
  final Map<String, int> signaturesReadyOn;
```

Le constructeur gagne le paramètre `Map<String, int> signaturesReadyOn = const {},` et l'initialiseur `signaturesReadyOn = Map.unmodifiable(signaturesReadyOn)` (à côté des trois `List.unmodifiable`). `copyWith` gagne `Map<String, int>? signaturesReadyOn,` et `signaturesReadyOn: signaturesReadyOn ?? this.signaturesReadyOn,`. `fromJson` et `toJson` ne changent pas. Les deux lectures :

```dart
  /// Dans combien de tours joueur la signature [id] revient : 0 si elle est
  /// prête. Ne bouge pas pendant le tour ennemi.
  int signatureTurnsLeft(String id) {
    final readyOn = signaturesReadyOn[id];
    return readyOn == null ? 0 : max(0, readyOn - turnCount);
  }

  bool isSignatureReady(String id) => signatureTurnsLeft(id) == 0;
```

`initializeCombat` (`combat_controller.dart:177-186`) ne change pas : il construit un `CombatState` neuf, table vide.

- [ ] **Step 5: Implémenter `playSignature` et extraire la suite commune**

Dans `lib/game/controllers/combat_controller.dart`, import `'../../../models/signature_instance.dart'` (forme des voisins). `applyPlayerCardPlay` (`:207-276`) est remplacée par ces trois méthodes :

```dart
  /// Applique le jeu d'une carte par le joueur
  void applyPlayerCardPlay(CardInstance card) {
    final runController = ref.read(runProvider.notifier);
    final deckController = ref.read(deckProvider.notifier);

    // 1. Résolution des effets
    final success = EffectResolver.resolveCard(
      card,
      runController,
      deckController,
      this,
      state.selectedEnemyId,
      ref.read(effectRegistryProvider),
    );
    if (!success) return;

    // 2. Transmettre au deck que la carte est jouée
    deckController.playCard(card);

    // 3. La suite commune. `enemyId` n'est renseigné que pour une carte qui
    // vise un seul ennemi (contrat de `PassiveEvent.enemyId`) : une carte à
    // portée de groupe laisserait sinon une sélection résiduelle marquer un
    // seul ennemi.
    _afterCardPlayed(
      card,
      enemyId: card.data.target == CardTarget.singleEnemy
          ? state.selectedEnemyId
          : null,
    );
  }

  /// Joue une signature (spec P-43 E4, §4.3) : résolue comme une carte, par
  /// sa vue de carte, puis mise en recharge ; elle n'entre dans aucune pile.
  ///
  /// Rend `false` sans rien toucher si le tour n'est pas au joueur, si le
  /// combat est fini, si la signature n'est pas de la run, si elle recharge,
  /// si elle vise un seul ennemi sans [enemyId] — jamais la sélection
  /// restante d'une carte précédente —, ou si le mana manque.
  bool playSignature(SignatureInstance signature, {String? enemyId}) {
    final runController = ref.read(runProvider.notifier);
    final runState = runController.currentState;
    final id = signature.data.id;
    final card = signature.asCard;
    final isSingleTarget = card.data.target == CardTarget.singleEnemy;

    // 1. Les refus sans effet. La run se compare par id : une run rechargée
    // reconstruit ses instances (A8).
    if (state.turnPhase != TurnPhase.player || state.isCombatEnded) {
      return false;
    }
    if (!runState.signatures.any((s) => s.data.id == id)) return false;
    if (!state.isSignatureReady(id)) return false;
    if (isSingleTarget && enemyId == null) return false;

    // 2. Mana et cible, avant toute écriture.
    if (!EffectResolver.canPlayCard(card, runState, enemyId)) return false;

    // 3. La cible, comme l'écran la pose avant de jouer une carte, puis la
    // résolution, qui paie le mana. Le contrôle de l'étape 2 porte sur le
    // même état : elle réussit.
    if (isSingleTarget) selectEnemy(enemyId);
    EffectResolver.resolveCard(
      card,
      runController,
      ref.read(deckProvider.notifier),
      this,
      enemyId,
      ref.read(effectRegistryProvider),
    );

    // 4. La recharge : le tour à partir duquel elle se rejoue.
    state = state.copyWith(
      signaturesReadyOn: {
        ...state.signaturesReadyOn,
        id: state.turnCount + signature.cooldown,
      },
    );

    // 5. Aucune pile. 6. La suite commune.
    _afterCardPlayed(card, enemyId: isSingleTarget ? enemyId : null);
    return true;
  }

  /// Ce qui suit le jeu d'une carte comme celui d'une signature : les
  /// passifs (l'événement générique, puis celui du type), les reliques des
  /// mêmes événements, puis le nettoyage des morts. Un seul chemin : tout ce
  /// qui écoute une carte jouée voit une signature jouée (spec P-43 E4,
  /// §4.4 ; Q-P1).
  void _afterCardPlayed(CardInstance card, {required String? enemyId}) {
    final runController = ref.read(runProvider.notifier);

    TraitSystem.dispatch(
      runController,
      PassiveEvent(RelicTrigger.onCardPlayed, card: card, enemyId: enemyId),
    );
    final typedTrigger = switch (card.data.type) {
      CardType.attack => RelicTrigger.onAttackPlayed,
      CardType.skill => RelicTrigger.onSkillPlayed,
      CardType.power => RelicTrigger.onPowerPlayed,
      // Une carte Statut ne se joue pas (`EffectResolver.canPlayCard`).
      CardType.status => null,
    };
    if (typedTrigger != null) {
      TraitSystem.dispatch(
        runController,
        PassiveEvent(typedTrigger, card: card, enemyId: enemyId),
      );
    }

    runController.applyRelics(RelicTrigger.onCardPlayed);
    if (typedTrigger != null) runController.applyRelics(typedTrigger);

    cleanDeadEnemies();
  }
```

`runController.applyRelics(typedTrigger)` rend exactement la chaîne `if/else if` d'aujourd'hui (`:265-271`) : attaque, compétence, pouvoir, rien pour un statut.

- [ ] **Step 6: Lancer les tests, constater le succès**

Run: `flutter test test/unit/combat_signature_test.dart test/unit/combat_state_test.dart test/unit/combat_controller_test.dart test/unit/passives_mage_test.dart test/unit/passives_berserker_test.dart test/unit/passive_triggers_test.dart`
Expected: tout passe — les tests de passifs gardent le jeu d'une carte inchangé.

- [ ] **Step 7: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1661** (1640 + 16 + 4 + 1) ; `git diff main -- assets/data/passives/mage_mark.json` → vide.

- [ ] **Step 8: Commit**

`git add lib/models/combat_state.dart lib/game/controllers/combat_controller.dart test/unit/combat_signature_test.dart test/unit/combat_state_test.dart test/unit/combat_controller_test.dart` puis `git commit` — `feat(signatures): jouer une signature, sa recharge et la suite commune`.

---

### Task 5: L'éditeur de contenu — la neuvième catégorie

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart:18-32`, `:152-180`, `:201-240`, `lib/services/content_editor/entity_catalog.dart:4-41`, `lib/services/content_editor/entity_draft.dart:26-28`, `lib/services/content_editor/entity_validator.dart:55-63`, `:104-158`, `:474-553`, `:571-592`, `lib/services/content_editor/entity_writer.dart:192-211`, `:263-292` (et l'appel de `_registerSignatureCard`), `lib/services/content_editor/class_recipe.dart`, `lib/ui/screens/content_editor_screen.dart:262-290`, `:358-382`, `:930-944`, `lib/ui/widgets/content_editor/entity_form.dart:515-530`, `lib/ui/widgets/content_editor/editor_style.dart:107-116`
- Test: `test/unit/content_editor/{entity_descriptor_test,entity_draft_test,entity_catalog_test,known_values_test,entity_validator_test,entity_writer_test,class_recipe_test,shipped_entities_round_trip_test,fixtures}.dart`, `test/widget/content_editor_screen_test.dart`, `test/widget/content_editor/editor_toolbar_test.dart`

**Interfaces:**
- Consumes: `SignatureData.fromJson`, `SignatureData.playableTypes`, `GameDataRegistry.signatures` (Task 1) ; les fichiers sous `skills/` (Task 2).
- Produces: `EntityCategory.signature` (placé juste après `card`) ; `kEntityDescriptors[EntityCategory.signature]` ; `class SignatureInput { const SignatureInput({required String id, Map<String, String> bilingual = const {}}) }` ; `ClassRecipe.signatures` (`List<SignatureInput>`, remplace `signatureCards`).

**Le descripteur de signature** (spec §8) :

| Champ | Valeur |
|:---|:---|
| `label` | `Signature` |
| `directory` | `skills` (le sous-dossier de chaque classe) |
| `supportsHeroClass` | `true` — la signature seule ; la carte le perd |
| `requiredKeys` | `cost`, `cooldown`, `type` |
| `forbiddenKeys` | `heroClass`, `rarity`, `isExhaust`, `category` |
| `enumKeys` | `type` : les noms de `SignatureData.playableTypes` (`attack`, `skill`, `power`) ; `target` : `CardTarget.values` |
| `bilingualBases` | `name`, `description` |
| `assetKeys` | `sfx` : `AssetSlot.sound()` |
| `vocabularyKeys` | `animation`, `effects[].type`, `effects[].statusId` (comme la carte) |
| `construct` | `SignatureData.fromJson` |
| `template` | `cost` 1, `cooldown` 2, `type` `attack`, `target` `singleEnemy`, `animation` `melee`, `effects` `[{type: damage, value: 6}]` |

**Question T tranchée — une signature neuve sans propriétaire** (`draft.heroClass` nul). Choix : **refus à la famille 1** (identité), avant tout contrôle disque, par une `ValidationFault` de champ `heroClass` — la rangée des pastilles l'affiche déjà (`entity_form.dart:298`, `errorText: faults['heroClass']`). Écartées : laisser `_construct` lever (filtre 5 — message opaque, après un contrôle d'existence sur un chemin `assets/data/skills/<id>.json` qui n'est celui d'aucune signature) ; retirer la pastille « Neutre » et présélectionner une classe (filtre 1 — §8 garde le choix du propriétaire tel quel ; et il élargit, filtre 7).

- [ ] **Step 1: Réécrire et écrire les tests**

- `entity_descriptor_test.dart` — `:18` `hasLength(9)` ; le commentaire `:27-32` dit « neuf sources pour neuf catégories, sans écart » (le compte `:35` reste 9) ; `:66-72` devient `une signature va dans skills de sa classe` (`pathOf('smite', heroClass: 'paladin')` → `assets/data/classes/paladin/skills/smite.json`) ; `:132-139` devient `seule la signature accepte une classe` (`[EntityCategory.signature]`) ; la table des gabarits gagne `signature: {cost, cooldown, type, target, animation, effects}`, raison « neuf catégories » ; `sfx` est une ressource son des **quatre** catégories (signature comprise) ; les vocabulaires de la signature égalent ceux de la carte. Deux neufs : `la signature exige cost, cooldown et type, et refuse heroClass, rarity, isExhaust et category` ; `le type d une signature exclut status` (`enumKeys['type']` égal à `['attack', 'skill', 'power']`).
- `entity_draft_test.dart:113-123` — le chemin sous une classe se prouve sur le descripteur de signature : `assets/data/classes/paladin/skills/smite.json`.
- `entity_catalog_test.dart` — `les cartes sont groupees par proprietaire` se scinde en `les signatures sont groupees par classe` (`classes/paladin/skills/smite.json` → `byOwner` égal à `{'paladin': ['smite']}`, sans clé nulle) et `les cartes vivent a plat, sans proprietaire` (un `classes/paladin/skills/smite.json` présent n'apparaît pas : `byOwner` égal à `{null: ['frappe']}`) (**+1**).
- `known_values_test.dart:63-72` — `une carte est cherchee a plat, une signature sous chaque classe` : `animation` de la carte `['melee']`, de la signature `['buff']`.
- `fixtures.dart` — `fixtureRegistry` gagne un paramètre `List<SignatureData> signatures = const []` passé au registre ; `fixtureSignatureDraft({String id = 'eclair', String? heroClass = 'mage', String? mechanics})` (prose remplie, gabarit du descripteur par défaut).
- `entity_validator_test.dart` — `:63-88` reformulé : `un identifiant que le registre porte et que le disque ne montre pas est refuse` (la carte neutre `smite` au registre, chemin libre) ; le commentaire dit qu'une neutre homonyme d'une **signature** n'est vue que par `referential_integrity_test` (ids disjoints). Cinq neufs : `une signature neuve sans proprietaire est refusee, nommee heroClass` (`fixtureSignatureDraft(heroClass: null)` → une faute, champ `heroClass`, et rien n'est lu sur le disque) ; `une signature homonyme d une signature du registre est refusee` (registre `signatures: [smite]`, brouillon `smite` sous `mage`) ; `une signature portant rarity ou isExhaust est refusee` (champs nommés) ; `une signature valide passe la construction, heroClass ajoute au document construit` (faute vide ; et `draft.compose()` ne contient pas `heroClass`) ; `un descripteur sans propriete de classe ne recoit pas heroClass` (un descripteur de test dont `construct` capture son document : la clé `heroClass` en est absente). Le groupe de bijection (Task 2) prend le nom `_signatures`. `:770` (image optionnelle d'une classe en modification) crée `classes/barde/skills` au lieu de `cards`. `:495-516` (`tous les gabarits franchissent les sept familles`) passe `heroClass: descriptor.supportsHeroClass ? 'paladin' : null` au brouillon, et le commentaire le dit : une signature sans propriétaire est refusée dès la famille 1 (décompte inchangé).
- `entity_writer_test.dart` — le groupe `carte de classe` devient `signature` : `classCardDraft` → `signatureDraft` sur le descripteur de signature, chemins `classes/<c>/skills/` ; `seedClass` crée `skills/` ; `:344` devient `une classe nait avec un sous-dossier skills vide` ; les commentaires de `writeAll` disent `skills/`.
- `class_recipe_test.dart` — `SignatureInput`, `signatures:` ; `:40-41` chemins `classes/gambler/skills/pari_<n>.json` ; descripteur des brouillons `EntityCategory.signature` ; le message attendu devient `deux signatures portent` ; le test d'écriture complète (`:223-240`) lit `classes/gambler/skills` au lieu de `cards` (`:235` ; commentaires `:221-229`, qui citent `_registerSignatureCard`, « chaque carte de signature », « 2 cartes », `cards/pari_1.json`, `cards/pari_2.json` et « le contenu de cards/ » — ils deviennent `_registerSignature`, « chaque signature », « 2 signatures », `skills/…`) et asserte en plus que chaque signature écrite repasse `EntityValidator.validate` en modification, sans faute.
- Tout autre chemin `classes/<c>/cards` d'un bac à sable sous `test/unit/content_editor/` ou de `test/widget/content_editor_screen_test.dart` (dont `entity_writer_test.dart:504`, `:565` et `content_editor_screen_test.dart:1422`, `:1739`) devient `classes/<c>/skills` ; le grep du Step 5 le vérifie.
- `shipped_entities_round_trip_test.dart` — `isClassCard` devient `isSignature` (même lecture du segment de classe) ; la boucle gagne d'elle-même le test `Signature : chaque fichier livre se modifie a l identique` (**+1**), qui prouve le round-trip des six fichiers construits sans `heroClass` dans le document écrit.
- `editor_toolbar_test.dart:23` et `content_editor_screen_test.dart:126-137` — neuf types, `Signature` après `Carte`. Dans `content_editor_screen_test.dart`, partout où le test exerce un **propriétaire** (pastilles, couleur, chemin sous une classe, chargement depuis un dossier de classe), il passe de `Carte` à `Signature` et de `cards/` à `skills/` : `seedOwners` (`:78-92`), `seul le choix actif est marque choisi` (`:312-361`), `le formulaire annonce ce qu il edite` (`:363-396`), `les cartes portent la couleur de leur proprietaire` (`:429`), `creer une classe ecrit ses cartes et referme skills` (`:617`), `le proprietaire d une carte est un champ, pas un niveau` (`:867`), `choisir une carte de classe la charge depuis son dossier` (`:1354`), `taper dans le champ identifiant ne relit pas le disque` (`:1063-1100` — il garde la lecture d'un `class.json` par la couleur du groupe de propriétaire dans l'explorateur, `content_editor_screen.dart:793-795` : sans le tap sur `Signature` au lieu de `Carte` (`:1086`) et le dossier `skills/` (`:1073-1075`), aucun bouton de classe ne s'affiche et l'assertion sur `fs.reads` ne mesure plus rien) ; les messages attendus `deux cartes de signature` (`:748`, `:785`) deviennent `deux signatures`, et le préfixe `carte 1 :` (`:864`, `:1822`, commentaire `:1794`) devient `signature 1 :` ; les titres suivent. Partout où il exerce une carte **neutre**, il reste sur `Carte`. Les clés de widget (`editeur-carte-<n>-id`, `editeur-cartes-plus`…) ne changent pas.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/content_editor/ test/widget/content_editor_screen_test.dart test/widget/content_editor/`
Expected: FAIL (`EntityCategory.signature`, `SignatureInput`, `fixtureSignatureDraft` n'existent pas).

- [ ] **Step 3: Implémenter**

- `EntityCategory.signature`, juste après `card` ; la doc de l'enum dit neuf catégories pour neuf sources.
- `EntityDescriptor.pathOf` : pour `supportsHeroClass` avec une classe, `assets/data/classes/<heroClass>/<directory>/<id>.json` ; sans classe, le repli d'aujourd'hui (le validateur refuse avant). La doc de `supportsHeroClass` dit « la seule signature ». Le descripteur de carte perd `supportsHeroClass` ; son `forbiddenKeys` reste `heroClass`, `category`.
- `entityFiles` : pour un descripteur `supportsHeroClass`, les seuls `classes/*/<directory>/*.json`, sans liste à plat ; pour les autres, la liste à plat d'aujourd'hui. `entityIdsByOwner` ne change pas (sa branche `classes` lit déjà le segment de classe).
- `EntityDraft.heroClass` : doc « la classe propriétaire d'une signature, celle du dossier ; `null` pour toute autre catégorie ».
- `EntityValidator` : dans `_identity`, après le contrôle de forme du nom de classe, `supportsHeroClass` et `heroClass == null` → `[ValidationFault('une signature appartient à une classe : choisissez son propriétaire', field: 'heroClass')]` ; le commentaire `:136-138` parle d'une signature homonyme sous une autre classe. `_signatureCards` devient `_signatures` (doc `:55-62` et `:474-481` alignées, messages « la signature … »). `_construct` passe à `construct` le document de `draft.compose()` **augmenté de `'heroClass': draft.heroClass`** quand `draft.descriptor.supportsHeroClass` — le document écrit ne change pas. `_registryIdsOf` gagne `EntityCategory.signature → r.signatures`.
- `EntityWriter` : `_registerSignatureCard` → `_registerSignature` (doc : écrire une signature neuve l'inscrit dans `skills`, la bijection `skills` ↔ `skills/`) ; `_prepareFolder` crée `skills/`, **même vide** (le test d'intégrité y appelle `listSync()` sans garde).
- `ClassRecipe` : `SignatureCardInput` → `SignatureInput`, `signatureCards` → `signatures` (D49 : « on dit toujours signature ») ; les brouillons prennent le descripteur de signature ; le message de `faults()` devient `deux signatures portent l'identifiant "<id>"` ; la doc suit.
- `content_editor_screen.dart` : `_recipe()` passe `signatures:` ; `:362` trie sur `EntityCategory.signature` ; `:372-378` le préfixe `carte <n> :` devient `signature <n> :`, le commentaire parle du panneau des signatures ; `:936-942` « et sa signature » / « et ses N signatures ».
- `entity_form.dart:517-527` : la méthode et son titre deviennent `_signatures` / `Signatures`.
- `editor_style.dart` : `kCategoryIcons[EntityCategory.signature]` = `Icons.bolt`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/content_editor/ test/widget/content_editor_screen_test.dart test/widget/content_editor/`
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1670** (1661 + 2 + 1 + 5 + 1) ; `git grep -n "signatureCards\|SignatureCardInput\|_registerSignatureCard" -- lib test` → vide ; `git grep -nE "classes/[^ ]*/cards" -- lib test` → seul le bac à sable générique `test/unit/game_data_loader_test.dart:63-84` répond.

- [ ] **Step 6: Commit**

`git add` par chemin (les six fichiers de `lib/services/content_editor/`, les trois de `lib/ui/`, les tests) puis `git commit` — `feat(editeur): la signature, neuvieme categorie`.

---

### Task 6: La purge de `unique` et d'`isAcquirable`

**Atomique à la compilation** : retirer la valeur `CardRarity.unique` casse d'un coup chaque `switch` exhaustif et chaque test qui la construit.

**Files:**
- Modify: `lib/models/data/card_data.dart:11-82`, `:159-174`, `lib/models/data/model_extensions.dart:23-24`, `:40-41`, `lib/game/controllers/shop_controller.dart:47-48`, `:97-98`, `lib/game/controllers/deck_controller.dart:49-61`, `:95-100`, `:312-313`, `lib/game/services/forge_rune_rules.dart:92-93`, `lib/game/components/card_component.dart:137-160`, `:309-310`, `lib/ui/widgets/ui_card.dart:201`, `lib/ui/widgets/ui_card/polychromatic_border.dart` (`isUnique` : `:8`, `:16`, `:68`, `:85`, `:93`, `:99` et sa branche, `:220`), `lib/ui/widgets/ui_card/ui_card_helpers.dart:188-190`, `:289-290`, `lib/ui/theme/app_colors.dart:44`, `lib/ui/theme/game_theme_extension.dart` (`rarityUnique` : `:10`, `:27`, `:45`, `:64`, `:82`, `:97`, `:119`), `lib/ui/widgets/content_editor/editor_style.dart:125`
- Test: `test/unit/card_rarity_test.dart`, `test/unit/card_offer_filter_test.dart`, `test/unit/effective_card_test.dart`, `test/unit/deck_state_persistence_test.dart`, `test/unit/rune_eligibility_test.dart`, `test/widget/ui_card_rune_sockets_test.dart`, `test/unit/deck_controller_test.dart`, `test/unit/shop_controller_test.dart`, `test/widget/shop_screen_test.dart`, `test/widget/draft_screen_test.dart`, `test/unit/reward_controller_test.dart`, `test/widget/card_dictionary_screen_test.dart`

**Interfaces:**
- Produces: `CardRarity` à cinq valeurs (`common` … `legendary`) ; `next`, `fusionRank`, `multiplier` sur cinq bras ; `DeckState.copyableCards` = `List.of(masterDeck)` ; `CardData.isOfferableTo(String heroClassId)` = `type != CardType.status && (heroClass == null || heroClass == heroClassId)` jusqu'à la Task 7.

- [ ] **Step 1: Réécrire les tests**

- `card_rarity_test.dart` — `:27-29` et le groupe `:49-59` retirés (**−3**) ; les assertions `:35` et `:45` sur `unique` retirées ; un neuf, `CardRarity porte exactement les cinq paliers de l echelle` (`CardRarity.values` égal à `_ladder`) (**+1**).
- `card_offer_filter_test.dart:48-56` retiré (**−1**).
- `effective_card_test.dart:83-91` retiré (**−1**).
- `deck_state_persistence_test.dart:126-149`, les deux cas, retirés (**−2**) ; la fixture `holyShield` (`:23`) et son entrée au registre (`:39`) partent avec eux.
- `rune_eligibility_test.dart:169` — l'assertion retirée.
- `ui_card_rune_sockets_test.dart:69-74` — `une carte commune sans rune n affiche aucun emplacement`, sur `CardRarity.common`.
- `deck_controller_test.dart:240-254` — `copyableCards rend tout le master deck, dans une liste neuve` : `DeckState(masterDeck: [strike, defend]).copyableCards` égal à `[strike, defend]` ; la liste rendue n'est pas `identical` à `masterDeck` ; après `clear()` sur elle, `masterDeck` a toujours 2 cartes (trois appelants la mélangent sur place : `shop_screen.dart:210`, `draft_screen.dart:614`, `reward_controller.dart:202`). `:259-295` — la `signature` part, le deck de 20 communes pèse 0, le commentaire dit « des communes ».
- `shop_controller_test.dart:616-656` — la fixture `signature` (`:618-627`) part ; `:629-646` réécrit sans leurre : le deck porte la source rare à rune et une seconde carte légitime commune (`testCardPool[1]`) ; sur 50 tirages, chaque copie a l'id et la rareté de l'une des deux, aucune rune, un id neuf, et les deux ids sont tirés ; `:649-656` devient `un deck vide n a pas de copie` (les lignes `:653-655` partent).
- `shop_screen_test.dart:318-371` retiré (**−1**), avec la fixture `signatureCard` (`:87-100`).
- `draft_screen_test.dart:253-…` (« Le Miroir de montee de niveau ne propose jamais de copier une carte unique ») retiré (**−1**).
- `reward_controller_test.dart` — la fixture `c_unique` (`:108-117`) part ; `:302-319` retiré (**−1**) ; `:617-632` réécrit sur un statut seul (`allCards: [allCards[1]]`, commentaire « Seulement un statut ») ; le commentaire `:177-179` perd `c_unique` (l'assertion `:180-183` et celle de `:537` ne changent pas) ; dans `:556-615`, l'entrée `mage_signature` (`:586-587`) et l'assertion de rareté (`:607-608`) partent, le titre perd « jamais une unique » (la clause de classe part à la Task 7).
- `card_dictionary_screen_test.dart` — `atk_hero` passe en `CardRarity.rare`, `power_hero` en `CardRarity.epic` ; le commentaire `:12` ne porte plus le mot entre guillemets.

- [ ] **Step 2: Purger**

- `card_data.dart` : la valeur `unique`, ses bras de `next`, `fusionRank`, `multiplier` (`legendary => null`, `common => 0`, `common => 1.0`) et les commentaires qui la citent (`:21-23`, `:33`, `:47`) ; `isAcquirable` et sa doc (`:78-81`) ; la clause `rarity.isAcquirable` d'`isOfferableTo`, dont la doc ne cite plus `unique`.
- `model_extensions.dart`, `shop_controller.dart:47-48`, `card_component.dart:309-310` : les bras `unique`. `card_component.dart` : `getRarityColor` perd sa ligne `unique` ; `getRarityShineColors` perd la branche arc-en-ciel `unique` (`:148-…`) et garde le reste.
- `PolychromaticBorder` : le paramètre `isUnique`, son passage au peintre, la branche de peinture qu'il ouvre et son terme de `shouldRepaint` ; `ui_card.dart:201` cesse de le passer.
- `ui_card_helpers.dart:188-190`, `:289-290` : les branches de rareté `unique`. **`:17` reste** — `t.contains('unique')` y est le mot clé de cible « Cible unique », pas une rareté (spec §3.4).
- `AppColors.rarityUnique` ; `GameThemeExtension.rarityUnique` — champ, constructeur, thèmes clair et sombre, `copyWith`, `lerp` ; `kRarityColors['unique']` (`editor_style.dart:125`).
- `DeckState.copyableCards` : `List.of(masterDeck)` ; doc : le deck entier, liste neuve et modifiable, seul point des quatre sources de copie. La doc de `fusionRankSum` (`:57-59`) ne cite plus `unique`. La réparation B5 (`:95-99`) part : `kept.add(instance.copyWith(data: freshData, forgeUpgrades: validUpgrades))`. Le commentaire `:312-313` dit « une légendaire n'en a pas ».
- Commentaires réécrits sans `unique` : `shop_controller.dart:97-98` (l'échelle s'arrête d'elle-même à `legendary`), `forge_rune_rules.dart:92-93` (une commune, de rang 0, n'en reçoit aucune).

- [ ] **Step 3: Lancer les tests ciblés**

Run: `flutter test test/unit/card_rarity_test.dart test/unit/card_offer_filter_test.dart test/unit/effective_card_test.dart test/unit/deck_state_persistence_test.dart test/unit/rune_eligibility_test.dart test/unit/deck_controller_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/widget/`
Expected: tout passe.

- [ ] **Step 4: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` (aucune fixture ni locale orpheline) ; `flutter test` → `All tests passed!`, **total 1661** (1670 − 2 − 1 − 1 − 2 − 1 − 1 − 1) ; `git grep -nE "CardRarity\.unique|rarityUnique|isUnique|isAcquirable|'unique'|\"unique\"|\`unique\`" -- lib test assets | grep -v "contains('single')"` → vide.

- [ ] **Step 5: Commit**

`git add` par chemin puis `git commit` — `refactor(cartes): la rarete unique et isAcquirable disparaissent`.

---

### Task 7: La purge de `CardCategory` et de `CardData.heroClass` — le prédicat `isOfferable`

**Atomique à la compilation** : le paramètre requis `category` et le paramètre `heroClass` de `CardData` disparaissent pour tous leurs lecteurs, ~36 fichiers de test compris.

**Files:**
- Modify: `lib/models/data/card_data.dart:7-9`, `:116-237`, `lib/models/signature_instance.dart` (`asCard`), `lib/services/game_data_service.dart:71-81`, `lib/game/controllers/shop_controller.dart:54-57`, `lib/game/controllers/reward_controller.dart:215-221`, `lib/ui/screens/starter_deck_draft_screen.dart:51-63`, `lib/tutorial/tutorial_fixtures.dart:62-66`, `lib/services/content_editor/entity_validator.dart:200-204`, `lib/services/content_editor/entity_descriptor.dart` (commentaire du descripteur de carte, `:212-214`), `lib/game/services/forge_rune_rules.dart:62`, `CLAUDE.md:89`, `README.md:93-95`
- Test: tout fichier sous `test/` qui passe `category:` ou `heroClass:` à un `CardData` ou porte une clé `'category'` dans une carte — les fichiers de §10 (`git grep -lE "CardCategory|heroClass:" -- test`, hors `content_editor/` pour `heroClass`), `test/unit/audio/audio_source_models_test.dart:18`, `:40`, `test/unit/localization_test.dart:17`, `test/unit/content_editor/fixtures.dart:21`, et ceux qu'ont touchés les tâches 1 à 6 ; réécrits : `test/unit/card_offer_filter_test.dart`, `test/unit/shop_controller_test.dart:805-859`, `test/unit/reward_controller_test.dart:556-615`, `test/widget/starter_deck_draft_screen_test.dart:296-361`, `test/tutorial/tutorial_fixtures_test.dart:111-118`

**Interfaces:**
- Produces: `bool get isOfferable => type != CardType.status` (A13) ; `CardData` sans `category` ni `heroClass` ; `CardData.fromJson` lève une `FormatException` qui nomme `heroClass` ou `category` ; `toJson` ne les écrit plus.

- [ ] **Step 1: Réécrire les tests**

- `card_offer_filter_test.dart` — la fabrique `_card` perd `category` et `heroClass` ; le groupe devient `CardData.isOfferable`, cinq tests à la place des trois restants (**+2**) : `toute carte qui n est pas un statut est offerte, a toute rarete` (attaque, compétence, pouvoir × `CardRarity.values` → vrai) ; `une carte de statut n est jamais offerte` ; `CardData.fromJson refuse heroClass, en le nommant` ; `CardData.fromJson refuse category, en le nommant` (`throwsA(isA<FormatException>().having(… contains('<clé>')))`) ; `toJson n ecrit ni heroClass ni category, et une CardInstance sauvee se relit` (`CardInstance.fromJson(instance.toJson())` rend même id, rareté, runes).
- `shop_controller_test.dart:805-859` — le groupe `filtre de classe sur le pool de boutique` retiré (**−2**) : plus de clause de classe ; `isOfferable` est gardé par `card_offer_filter_test`.
- `reward_controller_test.dart:556-615` — `la trouvaille ne tire que des cartes offertes, jamais un statut` : le pool est `allCards` plus une attaque rare `c_rare_x` et un pouvoir `c_power` ; sur 200 tirages, chaque carte trouvée est l'une de `c_normal`, `c_rare_x`, `c_power`, jamais `c_status`, et `c_rare_x` comme `c_power` sont vus. Le héros mage et `classCard(...)` partent.
- `starter_deck_draft_screen_test.dart:296-361` — `le pool du draft de depart est celui d isOfferable : tout sauf un statut` : le registre porte les dix cartes de `mockCards` et une carte de statut `blessure` ; dix `UiCard`, `BLESSURE` absente ; le commentaire ne parle plus de `getHeroCards`.
- `tutorial_fixtures_test.dart:111-118` — `le pool de depart est celui du predicat d offre` : chaque carte de `starterPool` est `isOfferable`, et le pool égale `registry.cards` filtrées par `isOfferable` puis triées par `compareByDisplayOrder`.
- Partout ailleurs, `category:` et `heroClass:` sortent des `CardData` et `'category'` des cartes en map, **sans changer ce que le test vérifie** ; `card_dictionary_screen_test.dart` : `atk_hero` et `power_hero` deviennent des cartes comme les autres, le commentaire `:12` dit « un mélange de cartes ».

- [ ] **Step 2: Purger**

- `card_data.dart` : l'enum `CardCategory` ; les champs `category` et `heroClass`, leurs paramètres ; `fromJson` refuse les clés `heroClass` et `category` (une `FormatException` chacune, qui la nomme — l'appartenance vient du répertoire, A10) ; `toJson` ne les écrit plus ; `isOfferableTo` devient l'accesseur `isOfferable`, doc : « le prédicat d'offre unique (ADR-101 D1) : boutique, trouvaille, draft de départ, `starterPool` du tutoriel ; la vague 5 lui donnera le passif actif ».
- `SignatureInstance.asCard` : l'argument `category` part.
- `loadGameDataRegistry` : la source neutre n'injecte plus que `id` ; le commentaire `:71-75` dit que `heroClass` et `category` sont refusés par `CardData.fromJson`.
- Lecteurs : `ShopController._getEligibleCards` → `allCards.where((c) => c.isOfferable)` (la lecture de `heroClassId` part) ; `reward_controller.dart:221` → `c.isOfferable` (la variable `run` part si elle n'a plus d'autre lecteur) ; le draft de départ (`:55-57`) et `TutorialFixtures.starterPool` (`:63-64`) filtrent par `isOfferable`, triés comme aujourd'hui (A9).
- Commentaires : `entity_validator.dart:203` (la liste des énumérations à repli silencieux perd `CardCategory`) ; `forge_rune_rules.dart:62` (`CardData.isOfferable`) ; le commentaire du descripteur de carte dit que `CardData.fromJson` refuse aussi les deux clés.
- `CLAUDE.md:89` : « Never write a field the directory imposes: `heroClass` in a signature file fails the load, and so do `heroClass` and `category` in a card file. » ; `README.md:93-95` : la même règle en français.

- [ ] **Step 3: Lancer les tests ciblés**

Run: `flutter test test/unit/card_offer_filter_test.dart test/unit/shop_controller_test.dart test/unit/reward_controller_test.dart test/widget/starter_deck_draft_screen_test.dart test/tutorial/ test/unit/real_bundle_load_test.dart test/unit/save_service_test.dart`
Expected: tout passe — le bundle réel se charge sans `category` injectée.

- [ ] **Step 4: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1661** (1661 + 2 − 2) ; `git grep -nE "CardCategory|isOfferableTo|characterSpecific" -- lib test` → vide ; `git grep -n "heroClass" -- lib/models/data/card_data.dart` → ne répond que dans le refus de `fromJson` et sa doc.

- [ ] **Step 5: Commit**

`git add` par chemin puis `git commit` — `refactor(cartes): CardCategory et heroClass disparaissent, le predicat isOfferable`.

---

### Task 8: La vérification finale

Aucun fichier ne change, sauf correction d'un écart trouvé ici (qui suit alors la règle d'arrêt de §6 de l'orchestration).

- [ ] **Step 1: L'analyse et la suite**

Run: `rm -rf build/unit_test_assets` puis `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1661**.

- [ ] **Step 2: Les contrôles de la spec §12**

- `` git grep -nE "CardRarity\.unique|rarityUnique|isUnique|isAcquirable|characterSpecific|CardCategory|isOfferableTo|'unique'|\"unique\"|\`unique\`" -- lib test assets tool ':!tool/simulations' | grep -v "contains('single')" `` → vide.
- `git diff main -- assets/data/passives/mage_mark.json` → vide.
- `dart run tool/sync_assets.dart --check` → code de sortie 0.
- `git grep -nE "classes/[^ ]*/cards" -- lib test CLAUDE.md README.md` → seul `test/unit/game_data_loader_test.dart:63-84` répond : un bac à sable générique du comptage de segments, qui ne lit aucune donnée du jeu — exception admise.
- Aucune signature dans le `masterDeck` ni dans un pool : `flutter test test/unit/referential_integrity_test.dart test/widget/starter_deck_draft_screen_test.dart test/widget/tutorial_starter_draft_test.dart` → vert.

- [ ] **Step 3: L'état de la branche**

Run: `git status` → arbre propre (hors fichiers régénérés par `flutter`, à restaurer par `git restore`) ; `git log --oneline main..HEAD` → les sept commits de ce plan après ceux de la spec. Rien n'est poussé.
