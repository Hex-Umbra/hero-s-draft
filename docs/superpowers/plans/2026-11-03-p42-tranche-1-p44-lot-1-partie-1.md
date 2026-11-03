# P-42 tranche 1 et P-44 lot 1, partie 1 — Le moteur de P-44 lot 1, sur les 17 neutres — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, le jeu est celui de `0.5.6` avec cinq runes de plus à la fusion (*Perforant*, *Vampirique*, *Ricochant*, *Résonant*, *Transfusion*), des statuts qui comptent leurs points (Vulnérable, Faiblesse, Gel, au barème de P-1 (a)) et la Puissance qui les nourrit — et un moteur qui sait déjà payer des PV et de l'Armure, frapper plusieurs fois et grandir avec une ressource, prouvé par les tests, sans qu'aucune carte livrée ne s'en serve encore.

**Architecture:** `CardEffect` gagne `hits`, `mightRatio` et `scaleWith` ; `CardData` gagne `hpCost` et `armorCost` (A9). La résolution d'une carte suit l'ordre de spec §4.7 dans `EffectResolver.resolveCard` : `canPlayCard` (dont `canAfford`, une seule règle, A10), le paiement en une écriture hors du pipeline, une résolution des effets (terme `scaleWith` et bonus unique de statut calculés au résolveur, A11, A15), l'écho, puis *Transfusion*. Les runes neuves sont cinq sortes de `CardDelta` lues par `EffectiveCard` ; `piercing` vit dans `EntityStats.takeDamage` (A16), `splash` et `lifesteal` dans `DamageEffectStrategy`, qui boucle sur les coups. Le barème des statuts proportionnels vit en un seul endroit, à côté du pipeline, et nourrit le pipeline, l'intention ennemie et tous les textes qui le chiffrent.

**Tech Stack:** Flutter / Dart 3, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md` — §10 « Partie 1 » pour le périmètre ; §3.1, §3.5 (*Trait de Glace*), §3.6, §4.1 à §4.7, §5.2 et §6.1 (les lignes de la partie 1), §6.2 (la galerie, le tableau et la prose du Gel), §7 (le descripteur de rune), §9 (les lignes marquées 1). Les décisions de §1 — dont les réponses du propriétaire de §1.2 (P-1 (a), P-3 (a)) et les arbitrages A1 à A38 de §1.3 — sont acquises : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md`.

Réponses du propriétaire reprises telles quelles (spec §1.2) : **P-1 (a)** — 25 % par point, plafonnés : Vulnérable +25 % de dégâts subis par point, 4 points au plus (+100 %) ; Faiblesse −25 % de dégâts infligés par point, 2 au plus (−50 %) ; Gel −25 % à l'attaque par point, 3 au plus (−75 %) ; *Trait de Glace* Gel 1 → 2, `freezing` 2 points par niveau, *Marque du Mage* Vulnérable 1 → 2. **P-3 (a)** — l'écho ne déclenche aucun événement « carte jouée » : ni passif, ni relique, ni compteur de cartes jouées. **Q11** — un seul bonus de Puissance de statut par carte (A15 : par résolution, le premier `apply_status`, tous statuts confondus).

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

S'y ajoutent :

- **jamais `git stash`, jamais `git commit --amend`** ; messages de commit en **ASCII**, sans accent.

Propres à cette partie :

- **La branche.** Le plan s'exécute sur `feat/v0.5.7-p42-tranche-1-p44-lot-1`, la branche courante, dans le checkout principal. Il ne crée aucune branche, n'en change pas, ne commite rien sur `main`, ne pousse rien. Pas de worktree.
- **La base de tests** : `flutter test` rend **1701** sur la branche (mesuré le 03/11). Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ». **Total attendu en fin de plan : 1811** (+110, aucun retiré).
- **Les références `fichier:ligne`** ont été relues le 2026-11-03 sur `0b902e9`. Une tâche qui modifie un fichier décale les lignes des suivantes : l'implémenteur se fie au symbole nommé, la ligne n'est qu'un repère.
- **Aucune carte livrée ne porte de coût combiné, de coups ni de `scaleWith`** dans cette partie (spec §10, l'invariant) : seuls `ice_bolt.json`, `mage_mark.json`, `freezing.json` et les cinq runes neuves changent sous `assets/data/`. Aucun dossier neuf : `sync_assets` n'a rien à déclarer. Le rendu des coûts, des coups et de la croissance (médaillons, badge `3×3`, lignes `cardCost*`, `cardScale*`, `cardDescDamageHits`) est de la partie 2 ; aucune de ces clés ARB n'est ajoutée ici.
- **`passive` n'existe pas encore** (partie 2). Une carte à coût combiné se construit, dans un test, par le **constructeur** `CardData(…, hpCost:, armorCost:)` ; seuls les tests de chargement de `card_costs_test.dart` passent par `CardData.fromJson`, et toujours par l'aide `costed(…)` de ce fichier — la partie 2 y ajoutera `passive` en un seul endroit quand A8 refusera un coût en PV sur une neutre.
- **`assets/data/passives/mage_mark.json` garde `"trigger": "onAttackPlayed"`** ; `onDamagingCardPlayed` n'apparaît nulle part (D34).
- **`tool/simulations/` ne change pas** (ADR-108 D5).

## Review Focus

Cinq modes d'échec que la spec implique pour la partie 1 et qu'aucun test ne garde encore, du plus probable au moins probable ; chacun est confié à la tâche qui écrit le test qui le garde.

1. **Un champ d'effet perdu en route.** `EffectiveCard._withValue` (`effective_card.dart:139-144`) reconstruit `CardEffect` sur quatre champs : toute rareté ou toute rune ferait d'un multi-coups un coup unique et effacerait `scaleWith`, sans qu'un test de `fromJson` le voie. → **Task 1** (`multi_hit_test` « une carte epique garde ses coups, son mightRatio et son scaleWith par card.effective ») et **Task 2** (les tests de résolution de `scale_with_test` et `multi_hit_test` passent par `resolveCard`, dont une carte épique).
2. **Un paiement qui fuit.** Une carte refusée qui écrit quelque chose ; des PV égaux au coût acceptés ; la rareté qui multiplie `hpCost` ; un débit qui passe par `takeDamage` et réveille *Ferveur* ; deux écritures d'état ; un remboursement de *Transfusion* payé deux fois sous l'écho. → **Task 7** (`card_costs_test`, vingt tests).
3. **L'écho pris pour un second jeu.** Un écho qui déclenche *Flux de Mana*, compte dans `cardsPlayedThisTurn`, repaie, rebouge la carte de pile, retire un jet, ou partage le bonus de statut de la première résolution. → **Task 6** (`rune_resolution_test` « l echo ne declenche aucun evenement carte jouee », « un seul jet », « jet reussi … sans rien payer » ; `effect_resolver_test` « l echo recoit son propre bonus de statut »).
4. **L'éclaboussure hors des règles de sa cible.** Un `splash` qui ne passe pas le pipeline de sa cible (son critique, son Électrocution, sa Vulnérabilité), ignore son Armure ou `piercing`, ou n'entre pas dans le vol de vie. → **Task 5** (cinq tests de `rune_resolution_test`, groupe *Ricochant*).
5. **La saturation mal lue par *Transcendance*.** `raisableCaps` qui repropose `piercing` à 4, `lifesteal` à 5 ou `echo` à 7 ; qui écarte `lifesteal` 4, `echo` 4 ou 6, `splash` 3 ; ou qui écarte toute rune sans delta (une liste vide est « toute saturée » pour `every`). → **Task 4** (deux tests), **Task 5** (un), **Task 6** (un), et les tests existants de `forge_rune_rules_test.dart:279-320`, dont le catalogue n'a pas de deltas et doit continuer de passer.

**Les autres trous**, ceux de la section « Pour le Review Focus des plans » des vérifications et ceux relevés en écrivant ce plan, chacun confié :

| Trou | Tâche, test ou vérification |
|:---|:---|
| `real_bundle_load_test.dart:101-104` : les runes à `maxLevel == 1` | Task 3 (`[cheap, eco, enduring, quick]`), Task 7 (`[cheap, eco, enduring, quick, transfusion]`) |
| `rune_ids_in_code_test.dart:31-36` : l'id de rune `lifesteal` est aussi l'id du statut de Vol de vie, écrit en littéral à quatre endroits de `lib/` (`strategies.dart:76`, `player_stats_manager.dart:538`, `status_indicator.dart:155`, `status_effects_panel.dart:111`) : le test rougit dès que `lifesteal.json` existe | Task 4, exception nommée dans le test (question T, voir le compte rendu) |
| `deck_screen_test.dart:255-279` : la liste en dur des runes qu'une Frappe peu commune peut tirer — une rune neuve tirée au hasard la rougit **par intermittence** | Tasks 4, 5, 6 (la liste suit la matrice) |
| `ratio` 0,3 refusé ; 0,2, 0,1, 1 et 1,5 acceptés | Task 1, `scale_with_test` |
| La galerie (Gel) et le tableau (Vulnérable, Faiblesse) du tutoriel lus sur le barème, entrées non `const` | Task 3, `tutorial_elements_widget_test.dart` *(nouveau)*, en français et en anglais |
| La prose des étapes `elements` et `enemies` : ni « divise par deux », ni « halves », ni pourcentage | Task 3, `tutorial_prose_test.dart` |
| Les parenthèses de l'infobulle Flutter lues sur le barème | Task 3, `ui_card_values_test.dart` |
| L'infobulle Flame sans `buildContext` : le `fallback` vide de `getTranslation` (`card_component.dart:110-122`) donnerait « () » | Task 3 : la parenthèse ne s'écrit pas quand la traduction est vide (décision T, faute de banc Flame — spec §9, « la face Flame au test manuel ») ; Task 8 : grep des pourcentages en dur |
| Le relais `consumeResource` (`run_controller.dart:557-560`) change de signature ; son appelant `passives_mage_test.dart:141` | Task 7 : l'appel `consumeResource(mana: 3)` compile tel quel et reste vert |
| Écho sur une carte `singleEnemy` dont la cible meurt à la première résolution | Task 6, « la cible meurt a la premiere resolution » |
| `splash` : un critique par cible, `piercing`, vol de vie statut et rune | Task 5 |
| Q11 : *Boule de Feu* + *Brûlant*, *Coup de Tonnerre* + *Brûlant*, un statut sur soi | Task 2 ; l'écho, Task 6 |
| Le commentaire de `MageMarkPassive` (`passive_strategies.dart:52-63`) dit que le pipeline ne lit pas l'intensité | Task 3, réécrit |
| `referential_integrity_test.dart:16-23` : `_effectOf` est un `switch` exhaustif sur `CardDelta`, qui ne compile plus à la première sorte neuve | Tasks 4 à 7, un bras par sorte |

**Reportés aux parties 2 et 3**, hors de ce plan : `forge_upgrades_catalog_test.dart:176-194` qui nomme `focus` et `demon_form` (partie 2, à la suppression et au déplacement) ; tout ce qui lit `passive` ; Q11 sur une signature à deux statuts d'évolution, `nextPendingEvolution`, `{val}` d'une majeure `reduceCost` (partie 3).

---

## Carte des fichiers

| Fichier | Rôle | Tâche |
|:---|:---|:---:|
| `lib/models/data/card_data.dart` | `CardEffect.hits`, `mightRatio`, `scaleWith`, `copyWithValue`, `checkScaleTarget` ; `ScaleWith`, `ScaleSource` ; `ScaleWith.termFor` ; `CardData.hpCost`, `armorCost`, `_readCosts`, `toJson` | 1, 2, 7 |
| `lib/models/data/signature_data.dart` | La règle de cible de `scaleWith` sur une signature | 1 |
| `lib/models/effective_card.dart` | `_withValue` par `copyWithValue` ; A14 ; les lectures des runes neuves | 1, 4, 5, 6, 7 |
| `lib/models/combat_state.dart` | `lastPlayedTurn`, `playedOnLastPlayedTurn`, `cardsPlayedThisTurn`, `recordCardPlayed` | 2 |
| `lib/game/controllers/combat_controller.dart` | `_afterCardPlayed` compte la carte jouée | 2 |
| `lib/game/services/effect_resolver.dart` | `scaleTerm`, `_resolveEffects`, Q11 ; l'écho ; `canAfford`, le paiement, *Transfusion* | 2, 6, 7 |
| `lib/game/services/effects/strategies.dart` | Multi-coups et `mightRatio` ; le bonus de statut retiré ; `piercing`, `lifesteal`, `splash` | 2, 4, 5 |
| `lib/game/services/proportional_status.dart` *(nouveau)* | Le barème de P-1 | 3 |
| `lib/game/services/damage_pipeline.dart`, `lib/models/enemy_instance.dart` | Faiblesse, Vulnérable, Gel au barème | 3 |
| `lib/game/systems/passives/passive_strategies.dart` | Commentaire de `MageMarkPassive` | 3 |
| `lib/game/components/card_component.dart` | Parenthèses de statut (Flame) ; `canAfford` | 3, 7 |
| `lib/ui/widgets/ui_card/ui_card_helpers.dart` | Parenthèses de statut (Flutter) | 3 |
| `lib/tutorial/widgets/tutorial_elements_widget.dart`, `lib/tutorial/tutorial_data.dart` | Galerie, tableau, prose du Gel | 3 |
| `lib/l10n/app_fr.arb`, `app_en.arb` (+ trois `app_localizations*.dart` régénérés) | `statusWeaknessHint`, `statusVulnerableHint`, `statusFreezeHint` | 3 |
| `assets/data/cards/ice_bolt.json`, `assets/data/passives/mage_mark.json`, `assets/data/forge_upgrades/freezing.json` | Recalibrages de P-1 | 3 |
| `lib/models/data/card_delta.dart` | Cinq sortes, `saturatesAt` | 4, 5, 6, 7 |
| `lib/models/data/forge_upgrade_data.dart` | `_valueAdded` ; `eligibleTargets` ; `requiresCost` | 4, 5, 6, 7 |
| `lib/game/services/forge_rune_rules.dart` | `raisableCaps` saturée ; `isEligible` lit `eligibleTargets`, `requiresCost` | 4, 5, 7 |
| `lib/models/entity_stats.dart` | `takeDamage(…, armorPiercePercent:, armorPierceFloor:)` | 4 |
| `lib/ui/widgets/forge/rune_style.dart` | Cinq icônes, cinq couleurs | 4, 5, 6, 7 |
| `assets/data/forge_upgrades/{piercing,lifesteal,splash,echo,transfusion}.json` *(nouveaux)* | Les cinq runes | 4, 5, 6, 7 |
| `lib/services/content_editor/entity_descriptor.dart` | Descripteur de rune : `eligibleTargets`, `requiresCost` | 5, 7 |
| `lib/game/systems/cost_rules.dart` *(nouveau)* | `CostRules.canPay`, la règle des trois bornes | 7 |
| `lib/game/controllers/run/player_stats_manager.dart`, `lib/game/controllers/run_controller.dart` | `consumeResource({mana, hp, armor})`, `refundHp` | 7 |
| `test/unit/multi_hit_test.dart`, `scale_with_test.dart`, `card_catalog_test.dart`, `card_costs_test.dart`, `test/widget/tutorial_elements_widget_test.dart` *(nouveaux)* | — | 1, 2, 3, 7 |
| Les autres tests touchés | Nommés tâche par tâche | 1 à 7 |

Ordre : les tâches 1 et 2 posent le modèle et la résolution ; la 3 est indépendante (le barème) ; les runes viennent ensuite, une tâche par mécanisme, chacune avec son fichier et son lecteur — aucune rune livrée ne reste sans moteur entre deux tâches. **La tâche à risque, le paiement (Task 7), vient en dernier** : elle écrit `resolveCard` sous sa forme finale, écho (Task 6) compris, et livre *Transfusion*, qui n'a de sens qu'avec un coût en PV. Les comptes de runes avancent d'une tâche à l'autre :

| Après la tâche | `forge_upgrades/` et `registry.forgeUpgrades` | Fichiers d'entité (`entity_id_convention_test`) | `runeIds` (`rune_ids_in_code_test`) |
|:---:|:---:|:---:|:---:|
| base | 11 | 94 | 11 |
| 4 | 13 | 96 | 13 |
| 5 | 14 | 97 | 14 |
| 6 | 15 | 98 | 15 |
| 7 | 16 | 99 | 16 |

---

### Task 1: Le modèle d'effet — `hits`, `mightRatio`, `scaleWith`, et la vue jouée qui les garde

Additive : aucune carte livrée ne porte ces champs ; rien ne change de comportement.

**Files:**
- Modify: `lib/models/data/card_data.dart:75-103` (`CardEffect`), `:148-195` (`CardData.fromJson`), `lib/models/data/signature_data.dart:60-130`, `lib/models/effective_card.dart:62-73`, `:139-144`
- Test: `test/unit/multi_hit_test.dart`, `test/unit/scale_with_test.dart`, `test/unit/card_catalog_test.dart` *(nouveaux)*

**Interfaces:**
- Produces :
  - `enum ScaleSource { armor, missingHp, cardsPlayedThisTurn, enemiesAlive, targetStatus, targetMissingHp }` (noms exacts de la spec §4.2).
  - `class ScaleWith` — `const ScaleWith({required ScaleSource source, required double ratio, String? statusId})` ; `factory ScaleWith.fromJson(Map<String, dynamic> json)` ; `Map<String, dynamic> toJson()`. Son calcul, `termFor`, vient avec son lecteur, à la Task 2.
  - `CardEffect` gagne `final int hits` (défaut 1), `final double mightRatio` (défaut 1), `final ScaleWith? scaleWith` (défaut `null`), tous trois paramètres nommés du constructeur `const` ; `CardEffect copyWithValue(int value)` (copie **tous** les champs, la valeur changée) ; `static void checkScaleTarget(Iterable<CardEffect> effects, CardTarget target, {required String owner})` — lève `FormatException` nommant `scaleWith.source` si un effet porte `targetStatus` ou `targetMissingHp` et que `target != CardTarget.singleEnemy`.
  - `EffectiveCard._withValue` disparaît : ses deux lecteurs appellent `copyWithValue`.

- [ ] **Step 1: Écrire les tests qui échouent**

Chaque refus s'asserte `throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('<clé>')))`.

`test/unit/multi_hit_test.dart`, groupe `chargement` :
- `hits et mightRatio absents valent 1` — `CardEffect.fromJson({'type': 'damage', 'value': 3})` : `hits` 1, `mightRatio` 1.0, `scaleWith` null.
- `hits sous 1 ou non entier est refuse, nomme` — `hits` 0 puis 1.5 : clé `hits`.
- `mightRatio hors de ]0, 1] est refuse, nomme` — 0, −0.5, 1.5 : clé `mightRatio` ; 1 et 0.5 acceptés.
- `hits et mightRatio sur un effet autre que damage sont refuses` — `{'type': 'armor', 'value': 2, 'hits': 2}` → `hits` ; `{'type': 'heal', …, 'mightRatio': 0.5}` → `mightRatio`.
- `toJson n ecrit hits et mightRatio que hors de leur defaut ; l aller-retour les garde` — un effet par défaut n'a ni `hits` ni `mightRatio` dans `toJson()` ; `{damage 3, hits 3, mightRatio 0.5}` revient identique par `fromJson(toJson())`.

Groupe `la vue jouee` (cartes construites par le constructeur, registre de runes livrées par `shippedRuneRegistry(const ['sharp'])` de `shipped_data.dart`) :
- `une carte epique garde ses coups, son mightRatio et son scaleWith par card.effective` — effets `[damage 3, hits 3, mightRatio 0.5]` et `[armor 2, scaleWith armor 0.2]` à `CardRarity.epic` : `effective.effects[0]` vaut (6, 3, 0.5), `effective.effects[1]` vaut (5, `ScaleSource.armor`, 0.2) — les valeurs de G1, `CardRarity.scaleValue`.
- `A14 : Tranchant 1 sur 3 x 3 donne +1 par coup` — commune `[damage 3, hits 3, mightRatio 0.5]`, `sharp:1` : `effective.effects.single.value` 4, `hits` 3.
- `A14 : Tranchant 5 sur 3 x 3 donne +3 par coup, pas +5` — `sharp:5` : valeur 6 (bonus sur 9 : `max((15×5×9 + 50) ~/ 100, 5)` = 7, `ceil(7 / 3)` = 3).

`test/unit/scale_with_test.dart`, groupe `chargement` :
- `scaleWith se lit : source, ratio, statusId` — `{'source': 'targetStatus', 'ratio': 1, 'statusId': 'poison'}` sur une carte `singleEnemy` : les trois champs.
- `ratio 0,3 est refuse ; 0,2, 0,1, 1 et 1,5 sont acceptes` — 0.3 → clé `ratio` ; les quatre autres se lisent.
- `ratio nul ou negatif est refuse` — 0 et −1 : clé `ratio`.
- `source inconnue est refusee, nommee` — `'block'` : clé `scaleWith.source`.
- `statusId exige pour targetStatus, refuse ailleurs` — `targetStatus` sans `statusId` → `statusId` ; `armor` avec `statusId` → `statusId` (décision T : un champ sans lecteur ne passe pas en silence).
- `scaleWith refuse sur draw et gain_mana, et sur un effet a hits 2` — trois refus, clé `scaleWith`.
- `targetStatus et targetMissingHp refuses hors d une cible unique` — `CardData.fromJson` d'une carte `allEnemies`, puis `self`, et `SignatureData.fromJson` d'une signature `allEnemies` : clé `scaleWith.source`.
- `toJson ecrit scaleWith, et l aller-retour le garde` — `CardEffect.fromJson(e.toJson())` rend même source, ratio, statusId.

`test/unit/card_catalog_test.dart` *(nouveau ; sur `loadGameDataRegistry(rootBundle)`, la partie 2 y ajoutera D17, D45, D50)* :
- `D38 : la somme hits x mightRatio ne depasse pas le cout en mana + 1, cartes et signatures` — pour chaque `registry.cards` (coût `cost`) et chaque `registry.signatures` (coût `cost`, A33), Σ sur les effets `damage` de `hits × mightRatio` ≤ coût + 1 (à 10⁻⁹ près) ; la liste des fautives est vide.
- `D38 : un effet a plusieurs coups declare mightRatio < 1` — aucun effet de carte ni de signature à `hits ≥ 2` et `mightRatio ≥ 1`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/multi_hit_test.dart test/unit/scale_with_test.dart test/unit/card_catalog_test.dart`
Expected: échec de compilation — `ScaleWith`, `ScaleSource`, `hits`, `mightRatio`, `scaleWith` n'existent pas.

- [ ] **Step 3: Implémenter**

- `CardEffect.fromJson` — `hits` : absent 1, sinon entier ≥ 1 ; `mightRatio` : absent 1, sinon nombre dans ]0, 1] ; l'un ou l'autre présent sur un `type` autre que `damage` → refus (spec §3.1). `scaleWith` : absent `null` ; présent → refus si `type` est `draw` ou `gain_mana` (G2, ce que la rareté gèle ne grandit pas), ou si `hits ≥ 2` ; sinon `ScaleWith.fromJson`. Chaque message nomme la clé.
- `ScaleWith.fromJson` — `source` parmi `ScaleSource.values` par `name` ; `ratio` un `num` > 0, converti en `double` ; **sous 1, refusé si `(1 / ratio − (1 / ratio).round()).abs() > 1e-9`** (A11 : le texte de la partie 2 écrit `1 / ratio` en tranches entières) ; `statusId` texte non vide exigé si `source == targetStatus`, refusé sinon.
- `CardEffect.toJson` écrit `hits` si ≠ 1, `mightRatio` si ≠ 1, `scaleWith` s'il est présent.
- `CardData.fromJson` et `SignatureData.fromJson` appellent `CardEffect.checkScaleTarget(effects, target, owner: id)` une fois `effects` et `target` lus (spec §3.1 : « la cible étant la sienne »).
- `EffectiveCard.apply`, cas `PercentBonusDelta` (`effective_card.dart:64-73`) — **A14, la formule imposée** : avec `h = effects[i].hits` et `B = atRarity[i].value`, le bonus par coup vaut `delta.bonusFor(B, level)` si `h == 1` (la formule d'E1, inchangée), sinon `(delta.bonusFor(B × h, level) + h − 1) ~/ h` (le bonus sur le total, plancher compris, réparti vers le haut).
- `_atRarity` et le cas `PercentBonusDelta` appellent `copyWithValue` ; `_withValue` est supprimé.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/multi_hit_test.dart test/unit/scale_with_test.dart test/unit/card_catalog_test.dart`
Expected: tout passe (8 + 8 + 2).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1719** (1701 + 18).

- [ ] **Step 6: Commit**

`git add lib/models/data/card_data.dart lib/models/data/signature_data.dart lib/models/effective_card.dart test/unit/multi_hit_test.dart test/unit/scale_with_test.dart test/unit/card_catalog_test.dart` puis `git commit` — `feat(moteur): hits, mightRatio et scaleWith sur les effets`.

---

### Task 2: La résolution — le terme `scaleWith`, les cartes jouées ce tour, un seul bonus de statut, les coups

**Files:**
- Modify: `lib/models/data/card_data.dart` (`ScaleWith.termFor`), `lib/models/combat_state.dart:9-75`, `lib/game/controllers/combat_controller.dart:296-321` (`_afterCardPlayed`), `lib/game/services/effect_resolver.dart:121-155`, `lib/game/services/effects/strategies.dart:16-80` (`DamageEffectStrategy`), `:160-206` (`ApplyStatusEffectStrategy`, le bonus `:174-176`)
- Test: `test/unit/combat_state_test.dart`, `test/unit/combat_signature_test.dart`, `test/unit/scale_with_test.dart`, `test/unit/multi_hit_test.dart`, `test/unit/effect_resolver_test.dart`

**Interfaces:**
- Consumes : `CardEffect.hits`, `mightRatio`, `scaleWith`, `ScaleWith` (Task 1).
- Produces :
  - `int ScaleWith.termFor(int quantity)` = `(quantity × ratio + 1e-9).floor()` (A11, arrondi vers le bas, la tolérance de `StatRule.convertedAmount`, `stat_rule.dart:91-96`).
  - `CombatState` gagne `final int lastPlayedTurn` et `final int playedOnLastPlayedTurn` (défauts 0, dans le constructeur et `copyWith`, **jamais sérialisés** — le précédent de `signaturesReadyOn`, `combat_state.dart:19-24`) ; `int get cardsPlayedThisTurn` (le second si le premier vaut `turnCount`, 0 sinon) ; `CombatState recordCardPlayed()` (A12).
  - `static int EffectResolver.scaleTerm(CardEffect effect, {required EntityStats hero, required CombatState combat, String? targetId})` — 0 sans `scaleWith`, sinon `scaleWith.termFor(quantité)`, la quantité de spec §4.2 : `hero.armure` ; `hero.maxPv − hero.currentPv` ; `combat.cardsPlayedThisTurn` ; le nombre d'ennemis de `combat.enemies` à `currentPv > 0` ; la somme des `value` des statuts `statusId` de l'ennemi `targetId` ; `maxPv − currentPv` de cet ennemi (0 s'il est introuvable). Lue par la résolution ; la partie 2 la lira pour le badge.
  - `static void EffectResolver._resolveEffects(CardInstance card, EffectiveCard effective, RunController runController, DeckNotifier deckController, CombatController combatController, String? selectedEnemyId, EffectRegistry registry)` — **une** résolution des effets ; la Task 6 l'appellera une seconde fois pour l'écho.

- [ ] **Step 1: Écrire les tests qui échouent**

`combat_state_test.dart` :
- `cardsPlayedThisTurn vaut 0 sur un etat neuf, et 0 au tour suivant` — neuf : 0 ; `recordCardPlayed()` au tour 1 puis `copyWith(turnCount: 2)` : 0.
- `recordCardPlayed compte dans le tour courant` — deux appels au tour 3 : 2 ; `toJson()` ne porte ni `lastPlayedTurn` ni `playedOnLastPlayedTurn`.

`combat_signature_test.dart`, groupe « ce qui ecoute une carte jouee » :
- `une signature jouee compte dans cardsPlayedThisTurn, comme une carte` — une carte par `applyPlayerCardPlay`, puis une signature par `playSignature` : `combat.currentState.cardsPlayedThisTurn` vaut 1 puis 2.

`scale_with_test.dart`, au groupe `chargement` :
- `termFor arrondit vers le bas` — 0,2 × 14 → 2 ; 0,1 × 30 → 3 ; 0,2 × 15 → 3 ; 1 × 7 → 7 ; 1,5 × 3 → 4.

`scale_with_test.dart`, groupe `resolution` — l'environnement de `rune_resolution_test.dart:20-89` (registre livré, Paladin, un ennemi à 100 PV, `play` par `EffectResolver.resolveCard`), cartes construites :
- `armor : le terme lit l Armure du heros` — Armure 7, `[damage 2, scaleWith armor 1]` : l'ennemi perd 9.
- `missingHp : PV max moins PV courants` — héros à 70/100, `[damage 4, scaleWith missingHp 0.2]` : 4 + 6 = 10.
- `cardsPlayedThisTurn : les jeux d avant celui-ci` — l'état porte deux `recordCardPlayed()` au tour courant ; `[damage 1, scaleWith cardsPlayedThisTurn 1]` : 3.
- `enemiesAlive : un ennemi a 0 PV ne compte pas` — trois ennemis dont un à 0 PV, `allEnemies` `[damage 1, scaleWith enemiesAlive 1]` : chaque vivant perd 3.
- `targetStatus : la somme des entrees du statut sur la cible` — deux entrées `poison` de sources distinctes (2 et 3), `[damage 1, scaleWith targetStatus 1 poison]` : 6.
- `targetMissingHp : les PV manquants de la cible` — ennemi à 60/100, `[damage 1, scaleWith targetMissingHp 0.1]` : 5.
- `la rarete ne multiplie pas le terme` — épique `[damage 5, scaleWith armor 1]`, Armure 4 : 8 + 4 = 12 (et non G1 de 9).
- `l Armure d un effet precedent compte pour le suivant` — Armure 0, `[armor 5]` puis `[armor 1, scaleWith armor 1]` : Armure finale 11.

`multi_hit_test.dart`, groupe `resolution` — même environnement, le Mage pour la Puissance de Compétence :
- `la Puissance par coup vaut floor(bonus x mightRatio)` — Puissance temporaire 3, Compétence `[damage 3, hits 3, mightRatio 0.5]` : 3 × (3 + 1) = 12.
- `l Electrocution compte a chaque coup` — ennemi sous Électrocution 2, `[damage 3, hits 3, mightRatio 0.5]` : 15.
- `le critique se tire a chaque coup` — `precise:20` (100 points) : 3 × round(3 × 1,5) = 15, et non round(9 × 1,5) = 14.
- `une cible unique morte perd les coups restants` — ennemi à 5 PV, Vol de vie (statut) armé à 99, héros à 50 : ennemi à 0, héros à 56 (deux coups comptés, pas trois).
- `allEnemies : chaque coup frappe chaque ennemi vivant, jamais un mort` — deux ennemis dont un à 0 PV, Vol de vie à 99, héros à 50, `allEnemies` `[damage 3, hits 2, mightRatio 0.5]` : le vivant perd 6, le mort reste à 0, héros à 56.

`effect_resolver_test.dart`, groupe neuf `Q11 : un seul bonus de statut par resolution` — son propre `setUpAll` (registre livré) et son conteneur ; le Mage, Puissance temporaire 2 :
- `Boule de Feu et Brulant : la Brulure de la rune recoit la Puissance, celle de la carte non` — `fireball`, `burning:1` : une entrée `burn` de valeur 5 (1 + 2, puis 2), durée 2.
- `Coup de Tonnerre et Brulant : la Brulure de la rune la recoit, l Electrocution non` — `thunder_clap`, `burning:1` : `burn` 3, `shock` 1.
- `sans rune, le premier statut de la carte recoit le bonus` — `poison_stab` : `poison` 1 + 2 = 3.
- `une carte sur soi : aucun de ses statuts ne recoit de Puissance` — Compétence `self` `[apply_status might 1, apply_status armor_regen 2]` : l'entrée `might` de la carte vaut 1, `armor_regen` 2.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/combat_state_test.dart test/unit/combat_signature_test.dart test/unit/scale_with_test.dart test/unit/multi_hit_test.dart test/unit/effect_resolver_test.dart`
Expected: échec de compilation (`termFor`, `recordCardPlayed`, `cardsPlayedThisTurn`), puis les valeurs (un seul coup, un terme ignoré, deux bonus).

- [ ] **Step 3: Implémenter**

- `_afterCardPlayed` écrit `state = state.recordCardPlayed()` en tête (A12 : une signature compte, résolue comme une carte ; aucune remise à zéro au tour).
- `resolveCard` : la boucle `:141-152` devient l'appel de `_resolveEffects`. **`_resolveEffects`, l'ordre de spec §4.7, étape 3** : un drapeau « bonus de statut à donner », vrai à l'entrée ; pour chaque effet de `[...effective.addedEffects, ...effective.effects]`, dans l'ordre, la valeur jouée est `effect.value + scaleTerm(effect, hero: <stats du héros lues à cet instant>, combat: combatController.currentState, targetId: selectedEnemyId)` ; si l'effet est un `apply_status` et que le drapeau est vrai, elle gagne `heroStats.statusBonusFor(card.data.target)` et le drapeau tombe — que le bonus vaille 0 ou non (A15) ; puis la stratégie du registre reçoit cette valeur en `scaledValue`.
- `ApplyStatusEffectStrategy` pose `scaledValue` tel quel : la ligne `statusBonusFor` (`:174-176`) part, et le commentaire dit que le bonus vient du résolveur.
- `DamageEffectStrategy.resolve` — **l'ordre de spec §4.3** : pour `h` de 1 à `effect.hits`, relire les ennemis de `combatController.currentState` ; les cibles du coup sont l'ennemi `selectedEnemyId` s'il vit (`currentPv > 0`) pour `singleEnemy` — mort ou absent, les coups restants sont perdus, la boucle s'arrête —, chaque ennemi vivant pour `allEnemies` ; pour chaque cible, dégâts initiaux `scaledValue + (damageBonusFor(type) × mightRatio + 1e-9).floor()` (A13), puis `DamagePipeline.calculate` (critique et Électrocution par coup), puis `takeDamage`, et `dealt +=` les dégâts du pipeline ; après tous les coups, `_payLifesteal(dealt)` une fois, comme aujourd'hui.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1740** (1719 + 2 + 1 + 1 + 8 + 5 + 4). `might_orientation_test.dart:200-250` reste vert sans retouche : ses cartes ne portent qu'un statut chacune.

- [ ] **Step 6: Commit**

`git add` des cinq fichiers de `lib/` (`card_data.dart`, pour `termFor`, et `combat_state.dart`, `combat_controller.dart`, `effect_resolver.dart`, `strategies.dart`) et des cinq tests nommés, puis `git commit` — `feat(moteur): terme scaleWith, multi-coups et bonus de statut unique`.

---

### Task 3: Les statuts proportionnels — le barème de P-1, ses recalibrages et tous les textes qui le chiffrent

**Files:**
- Create: `lib/game/services/proportional_status.dart`, `test/widget/tutorial_elements_widget_test.dart`
- Modify: `lib/game/services/damage_pipeline.dart:18-22`, `:50-54` (et leurs commentaires) ; `lib/models/enemy_instance.dart:28-30` ; `lib/game/systems/passives/passive_strategies.dart:52-63` (commentaire) ; `lib/game/components/card_component.dart:371-401` ; `lib/ui/widgets/ui_card/ui_card_helpers.dart:374-404` ; `lib/tutorial/widgets/tutorial_elements_widget.dart:7-23`, `:41-121`, `:262-300`, `:392-394`, `:441-465` ; `lib/tutorial/tutorial_data.dart:227-228`, `:236-237`, `:255`, `:267-268` ; `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` ; `assets/data/cards/ice_bolt.json`, `assets/data/passives/mage_mark.json`, `assets/data/forge_upgrades/freezing.json`
- Test: `test/unit/damage_pipeline_test.dart`, `test/unit/effect_resolver_test.dart`, `test/unit/rune_resolution_test.dart`, `test/unit/passives_mage_test.dart`, `test/widget/ui_card_values_test.dart`, `test/tutorial/tutorial_prose_test.dart`, `test/unit/combat_controller_test.dart:632`, `:672`, `:707`, `test/unit/forge_upgrade_data_test.dart:459`, `test/unit/forge_upgrades_catalog_test.dart:54-60`, `:109-114`, `test/unit/real_bundle_load_test.dart:101-104`

**Interfaces:**
- Produces :
  - `class ProportionalStatus` (`proportional_status.dart`) — `final String id`, `final int percentPerPoint`, `final int maxPoints` ; `int get maxPercent` (= `percentPerPoint × maxPoints`) ; `int pointsOn(EntityStats stats)` (la somme des `value` des entrées de cet `id`, bornée à `[0, maxPoints]`) ; `int percentOn(EntityStats stats)` (= `percentPerPoint × pointsOn`). Trois constantes, **les seules valeurs du barème dans tout le code** : `static const vulnerable = ProportionalStatus._('vulnerable', 25, 4)`, `weakness = ('weakness', 25, 2)`, `freeze = ('freeze', 25, 3)`.
  - Trois clés ARB à deux paramètres `int` (`percent`, `max`), textes de spec §6.1 mot pour mot — `statusWeaknessHint` : « −{percent} % de dégâts infligés par point, jusqu'à −{max} % » / « −{percent}% damage dealt per point, down to −{max}% » ; `statusVulnerableHint` : « +{percent} % de dégâts subis par point, jusqu'à +{max} % » / « +{percent}% damage taken per point, up to +{max}% » ; `statusFreezeHint` : « −{percent} % à la prochaine attaque par point, jusqu'à −{max} % » / « −{percent}% to the next attack per point, down to −{max}% ». Elles se remplissent toujours de `(percentPerPoint, maxPercent)`.
  - `ElementStatusInfo` (`tutorial_elements_widget.dart:7-23`) porte `name` et `desc` déjà résolus dans la langue active ; `_elements` et `_missingStatuses` deviennent des fonctions de `(AppLocalizations l10n, bool isFrench)`, appelées dans `build` (spec §6.2 : les entrées cessent d'être `const`).

- [ ] **Step 1: Écrire les tests qui échouent, réécrire ceux que le barème change**

`damage_pipeline_test.dart` :
- `le bareme de P-1 : 25 % par point ; Vulnerable 4, Faiblesse 2, Gel 3 points au plus` — les trois constantes : `(percentPerPoint, maxPoints, maxPercent)` valent (25, 4, 100), (25, 2, 50), (25, 3, 75).
- `Vulnerable : +25 % par point, plafonne a +100 %` — 10 dégâts contre 1, 2, 4, 6 points : 13, 15, 20, 20.
- `Faiblesse : -25 % par point, plafonnee a -50 %` — attaquant à 1, 2, 3 points, 10 dégâts : 8, 5, 5.
- `les points se lisent sur la somme des entrees de meme id` — deux entrées `vulnerable` de 1, de sources `'a'` et `'b'` : 10 → 15.

`effect_resolver_test.dart`, groupe `EntityStats & StatusEffect` :
- `le Gel reduit l intention de 25 % par point, 3 points au plus` — ennemi `baseDamage` 10, `might` 10, intention d'attaque 10, Gel 1, 2, 3, 5 points : `effectiveIntent.value` 8, 5, 3, 3.

`rune_resolution_test.dart`, groupe des statuts de rune :
- `Trait de Glace pose 2 Gel : -50 %, l effet d avant` — `play(card('ice_bolt'))` : une entrée `freeze` de valeur 2, `ProportionalStatus.freeze.percentOn(enemy())` vaut 50.
- `Congelant 1 pose 2 Gel : -50 %` — `strike_basic` + `freezing:1` : même assertion.

`passives_mage_test.dart`, groupe `le catalogue` :
- `mage_mark.json pose 2 Vulnerable pendant 2 tours : +50 %` — la `PassiveData` livrée : `value` 2, `duration` 2, `trigger` `onAttackPlayed` ; `ProportionalStatus.vulnerable.percentPerPoint × 2` vaut 50.

`ui_card_values_test.dart` :
- `l infobulle dit le bareme de Faiblesse, Vulnerable et Gel` — une carte construite à trois `apply_status` (`weakness`, `vulnerable`, `freeze`) : l'infobulle (`_tooltip`) contient `'(${l10n.statusWeaknessHint(25, 50)})'`, `'(${l10n.statusVulnerableHint(25, 100)})'`, `'(${l10n.statusFreezeHint(25, 75)})'` — les nombres passés par `ProportionalStatus.<statut>.percentPerPoint` et `.maxPercent`, jamais en littéral — et ne contient ni `25%` ni `50%`.

`test/widget/tutorial_elements_widget_test.dart` *(nouveau ; `TutorialElementsWidget(engine: TutorialEngine(data: await buildTutorialTestRegistry()))`, vue de 1600 × 1200 comme `tutorial_armor_step_test.dart:12-30` ; finir par `pumpWidget(const SizedBox())` pour couper le `Timer.periodic` du widget)* :
- `la galerie et le tableau lisent le bareme, en francais` — `find.text` trouve, une fois chacun, `l10n.statusFreezeHint(…)` (galerie), `statusVulnerableHint(…)` et `statusWeaknessHint(…)` (tableau), remplis de `ProportionalStatus.<statut>.percentPerPoint` et `.maxPercent` ; les trois textes d'aujourd'hui (`'Réduit les dégâts de la prochaine attaque ennemie de 50%.'`, `'+50 % de dégâts subis'`, `'-25 % de dégâts infligés'`) ne se trouvent plus. La simulation `10 -> 5` (`:221`) reste (spec §6.2).
- `la galerie et le tableau lisent le bareme, en anglais` — même chose sous `Locale('en')`.

`tutorial_prose_test.dart` :
- `le Gel ne se chiffre plus dans les etapes elements et enemies` — pour les étapes `TutorialStepType.elements` et `TutorialStepType.enemies`, `bodyFr` et `bodyEn` ne contiennent ni `divise par deux`, ni `halves`, ni `%` ; l'étape `elements` contient la phrase de spec §6.2 mot pour mot (« • ❄️ Gel : réduit leur prochaine attaque, d'autant plus qu'il compte de points, jusqu'à un plafond. … » / « • ❄️ Freeze: reduces their next attack, more with each point, up to a cap. … ») ; l'étape `enemies` finit par « …et baisse tant qu'il est Gelé. » / « …and drops while they are Frozen. ».

Réécrits, sans changer le total :
- `combat_controller_test.dart` (« Burn, Freeze, and Shock status effects… ») : les trois statuts posés à `value: 1` (`:632` Gel, `:672` et `:707` Vulnérable) passent à `value: 2` — les nombres attendus (5, 8, 9) et les commentaires restent justes sous le barème.
- `forge_upgrade_data_test.dart:459` : `text('freezing', 1)` vaut `'Applique 2 Gel'`.
- `forge_upgrades_catalog_test.dart` : `_status` (`:54-60`) gagne un paramètre nommé `valuePerLevel` (défaut 1) ; l'entrée `freezing` (`:109-114`) vaut `maxLevel: null`, `deltas: [_status('freeze', valuePerLevel: 2)]`.
- `real_bundle_load_test.dart:101-104` : `['cheap', 'eco', 'enduring', 'quick']`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/damage_pipeline_test.dart test/unit/effect_resolver_test.dart test/unit/rune_resolution_test.dart test/unit/passives_mage_test.dart test/widget/ui_card_values_test.dart test/widget/tutorial_elements_widget_test.dart test/tutorial/tutorial_prose_test.dart test/unit/combat_controller_test.dart test/unit/forge_upgrade_data_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/real_bundle_load_test.dart`
Expected: échec — `ProportionalStatus` et les trois clés n'existent pas.

- [ ] **Step 3: Implémenter**

- Le pipeline : Faiblesse, `p = weakness.percentOn(attackerStats)` ; si `p > 0`, `totalDamage = (totalDamage × (100 − p) / 100).round()`. Vulnérable, `p = vulnerable.percentOn(defenderStats)` ; si `p > 0`, `(totalDamage × (100 + p) / 100).round()`. L'ordre des étapes et l'arrondi au plus proche ne changent pas (spec §4.4) ; les deux commentaires disent le barème sans pourcentage en dur.
- `effectiveIntent` : `p = freeze.percentOn(stats)` ; si `p > 0`, `finalValue = (finalValue × (100 − p) / 100).round()`. L'usure du Gel (`turn_phase_manager.dart:116-128`) et son tic (`entity_stats.dart:145-147`) ne changent pas.
- Les deux infobulles — Flutter (`ui_card_helpers.dart:374-404`) et Flame (`card_component.dart:371-401`) : la parenthèse de Faiblesse, Vulnérable et Gel devient `'  (<clé status…Hint remplie du barème>)\n'`, en lieu des deux textes en dur. **Côté Flame**, par `getTranslation((l) => l.status…Hint(…))` sans `fallback` ; **une traduction vide n'écrit aucune ligne** (décision T : sans `buildContext`, pas de « () », et aucune troisième copie du texte dans le code).
- Le tutoriel : les trois entrées lisent leur clé `status…Hint` sans parenthèses (C2.2) ; les autres gardent leurs textes ; `_buildGallery` et `_buildStatusRow` lisent `name` et `desc`. La prose : les quatre lignes nommées, aux textes de spec §6.2, mot pour mot.
- Les données : `ice_bolt.json` — Gel `value` 2, descriptions « Inflige 4 dégâts. Applique 2 Gel. » / « Deal 4 damage. Apply 2 Freeze. » ; `mage_mark.json` — `value` 2, descriptions de spec §3.3 mot pour mot, `trigger` inchangé ; `freezing.json` — `maxLevel` `null`, `valuePerLevel` 2 (A23).
- Le commentaire de `MageMarkPassive` (`passive_strategies.dart:52-63`) : le pipeline lit désormais l'intensité, au barème ; la Maîtrise allonge toujours la durée.
- `flutter gen-l10n`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1752** (1740 + 4 + 1 + 2 + 1 + 1 + 2 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin des fichiers nommés, les trois `lib/l10n/app_localizations*.dart` compris, puis `git commit` — `feat(statuts): bareme proportionnel de P-1, recalibrages et textes`.

---

### Task 4: *Perforant* et *Vampirique* — deux sortes de delta, l'absorption, le soin de la rune, la saturation

**Files:**
- Create: `assets/data/forge_upgrades/piercing.json`, `assets/data/forge_upgrades/lifesteal.json`
- Modify: `lib/models/data/card_delta.dart:13-47`, `lib/models/effective_card.dart:11-95`, `lib/models/data/forge_upgrade_data.dart:275-289`, `lib/game/services/forge_rune_rules.dart:155-175`, `lib/models/entity_stats.dart:194-214`, `lib/game/services/effects/strategies.dart:16-80`, `lib/ui/widgets/forge/rune_style.dart:6-35`
- Test: `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_resolution_test.dart`, `test/unit/forge_rune_rules_test.dart`, `test/unit/forge_upgrades_catalog_test.dart`, `test/unit/real_bundle_load_test.dart:25`, `:38`, `:100`, `test/unit/entity_id_convention_test.dart:67-77`, `test/unit/rune_ids_in_code_test.dart:31-36`, `test/unit/referential_integrity_test.dart:16-23`, `test/widget/deck_screen_test.dart:255-279`

**Interfaces:**
- Consumes : la boucle des coups de `DamageEffectStrategy` (Task 2).
- Produces :
  - `CardDelta` gagne `bool saturatesAt(int level) => false` (surchargé par les sortes en pourcentage qui valent 100 au plus, A22), et deux sortes : `final class ArmorPierceDelta` (`type` `armorPierce`) et `final class LifestealPercentDelta` (`type` `lifestealPercent`), chacune `const …({required int valuePercentPerLevel})`, lue par `_positive`, `toJson` `{'type', 'valuePercentPerLevel'}`, `saturatesAt(level) => valuePercentPerLevel × level >= 100`. `typeNames` gagne leurs deux noms.
  - `EffectiveCard` gagne `final int armorPiercePercent`, `armorPierceLevel`, `lifestealPercent`, `lifestealLevel` — sommes, sur les paires (delta, niveau), de `valuePercentPerLevel × L` et de `L` (spec §4.6).
  - `EntityStats takeDamage(int amount, {bool isCrit = false, int armorPiercePercent = 0, int armorPierceFloor = 0})` (A16).

- [ ] **Step 1: Écrire les tests qui échouent**

`forge_upgrade_data_test.dart`, groupe `deltas` :
- `armorPierce et lifestealPercent se lisent et s ecrivent ; un pourcentage nul est refuse` — aller-retour `fromJson`/`toJson` ; `valuePercentPerLevel` 0 → clé `valuePercentPerLevel`.

Groupe `{val}` :
- `{val} : Perforant 1 vaut 25, Perforant 5 borne a 100, Vampirique 2 vaut 40` — sur `shippedRune('piercing')` et `shippedRune('lifesteal')` : « Ignore 25 % de l'Armure de la cible », « Ignore 100 % … », « Soigne 40 % des dégâts infligés ».

`rune_resolution_test.dart`, groupe neuf `Perforant` (ennemi armé par `combat.updateEnemyStats`) :
- `Perforant 1 contre 10 Armure : 3 ignores` — `heavy_strike` + `piercing:1` : ennemi (95 PV, 3 Armure) ; sans rune, (98, 0).
- `Perforant : au moins L, jamais plus que l Armure presente` — `strike_basic` + `piercing:1` contre 1 Armure : (94, 1) ; contre 0 Armure : (94, 0).
- `Perforant 4 : toute l Armure ignoree, et gardee` — `strike_basic` + `piercing:4` contre 10 Armure : (94, 10).

Groupe neuf `Vampirique` (héros à 50 PV) :
- `Vampirique 1 : 20 % des degats infliges, demie vers le haut` — `heavy_strike` + `lifesteal:1` : héros à 52.
- `Vampirique : au moins L, jamais plus que les degats infliges` — carte `[damage 1]` + `lifesteal:1` : 51 ; carte `[damage 2]` + `lifesteal:3` : 52.
- `Vampirique et le Vol de vie de Soif de Sang soignent tous deux, une fois par carte` — Vol de vie (statut) à 2 par `run.applyLifestealBuff`, `strike_basic` + `lifesteal:1` : 50 + 2 + 1 = 53.

`forge_rune_rules_test.dart`, groupe `raisableCaps` (catalogue local de runes construites, deltas déclarés) :
- `une rune dont chaque delta est sature n est pas proposee : Perforant a 4, Vampirique a 5` — `piercing` (`maxLevel` 4) portée à 4 : absente ; `lifesteal` (`maxLevel` 3) portée à 5 sous un `capBonus` de 2 : absente.
- `Vampirique 4 reste proposee` — portée à 4 sous un `capBonus` de 1 : `('lifesteal', 4)` présente.

`forge_upgrades_catalog_test.dart` : `_expected` gagne `piercing` et `lifesteal`, aux valeurs du Step 3 (**+2** tests, par la boucle `$id declare ce que la spec fixe`).

Réécrits, sans changer le total : `_attackRank1` (`:162-170`) gagne `piercing`, `lifesteal` ; « enduring et cheap sont binaires, les neuf autres non » devient « … les onze autres non », `hasLength(13)` ; `real_bundle_load_test` — forge 13 (`:38` et `:100`), titre du manifeste 96 fichiers (`:25`) ; `entity_id_convention_test` 96, raison « 13 ameliorations de forge » ; `rune_ids_in_code_test` — `hasLength(13)`, et le motif exclut les ids d'une liste nommée `{'lifesteal'}`, avec la raison : « aussi l'id du statut de Vol de vie (P-41), que lib/ nomme en littéral » ; `referential_integrity_test._effectOf` gagne deux bras `=> null` ; `deck_screen_test.dart:255-279` — commentaire et liste `isIn` gagnent `piercing`, `lifesteal`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/rune_resolution_test.dart test/unit/forge_rune_rules_test.dart test/unit/forge_upgrades_catalog_test.dart`
Expected: échec — les sortes `armorPierce`, `lifestealPercent` et les fichiers de rune n'existent pas.

- [ ] **Step 3: Implémenter**

- Les fichiers — sur le modèle de `sharp.json`, `minFusionRank` 1, `weight` 50, `eligibleEffects: ["damage"]` (spec §3.6, D63) :

| Fichier | `name_fr` / `name_en` | `description_fr` / `description_en` | `maxLevel` | `deltas` | `icon`, `color`, `emoji` |
|:---|:---|:---|:---:|:---|:---|
| `piercing.json` | Perforant / Piercing | « Ignore {val} % de l'Armure de la cible » / « Ignores {val}% of the target's Block » | 4 | `armorPierce`, 25 | `navigation_rounded`, `indigoAccent`, 🗡️ |
| `lifesteal.json` | Vampirique / Vampiric | « Soigne {val} % des dégâts infligés » / « Heals {val}% of the damage dealt » | 3 | `lifestealPercent`, 20 | `water_drop_rounded`, `deepOrangeAccent`, 🩸 |

- `runeIcons` et `runeColors` gagnent ces noms (`Icons.navigation_rounded`, `Icons.water_drop_rounded`, `Colors.indigoAccent`, `Colors.deepOrangeAccent`).
- `_valueAdded` : `ArmorPierceDelta() => min(100, valuePercentPerLevel × level)`, `LifestealPercentDelta() => valuePercentPerLevel × level` (spec §3.6 : `{val}` rend le pourcentage du niveau).
- `raisableCaps` : à la garde `!rune.binary` (`:170`) s'ajoute « non saturée à `cap` », où saturée veut dire `rune.deltas.isNotEmpty && rune.deltas.every((d) => d.saturatesAt(cap))` — **le `isNotEmpty` est voulu** : les runes construites sans delta des tests existants (`forge_rune_rules_test.dart:279-320`) restent candidates.
- `takeDamage` — **la formule imposée (spec §4.6, A16)** : avec `A = armure` et `p = min(100, armorPiercePercent)`, l'Armure ignorée vaut `I = p > 0 ? min(A, max((p × A + 50) ~/ 100, armorPierceFloor)) : 0` ; l'Armure qui protège est `A − I` ; la part ignorée ne protège pas et n'est pas consommée : après le coup, l'Armure vaut `I + max(0, A − I − amount)` et les PV perdent `max(0, amount − (A − I))`. Sans perforation, le résultat est celui d'aujourd'hui.
- `DamageEffectStrategy` : chaque `takeDamage` reçoit `armorPiercePercent: effective.armorPiercePercent`, `armorPierceFloor: effective.armorPierceLevel`. Après les coups et le Vol de vie du statut, si `effective.lifestealLevel > 0` et `dealt ≥ 1` : `runController.heal(min(dealt, max((effective.lifestealPercent × dealt + 50) ~/ 100, effective.lifestealLevel)))`, sans critique (A18).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/rune_resolution_test.dart test/unit/forge_rune_rules_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/rune_ids_in_code_test.dart test/unit/referential_integrity_test.dart test/widget/deck_screen_test.dart`
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1764** (1752 + 2 + 6 + 2 + 2).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(runes): Perforant et Vampirique`.

---

### Task 5: *Ricochant* et `eligibleTargets`

**Files:**
- Create: `assets/data/forge_upgrades/splash.json`
- Modify: `lib/models/data/card_delta.dart`, `lib/models/effective_card.dart`, `lib/models/data/forge_upgrade_data.dart:24-113`, `:224-246`, `:275-289`, `lib/game/services/forge_rune_rules.dart:67-111`, `lib/game/services/effects/strategies.dart:16-80`, `lib/ui/widgets/forge/rune_style.dart`, `lib/services/content_editor/entity_descriptor.dart:361-428`
- Test: `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_eligibility_test.dart`, `test/unit/rune_resolution_test.dart`, `test/unit/forge_rune_rules_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart:286-300`, `test/unit/forge_upgrades_catalog_test.dart:16-52`, `:162-194`, `:227-259`, `:261-270`, `test/unit/referential_integrity_test.dart:16-23`, et les comptes (tableau de la carte des fichiers)

**Interfaces:**
- Consumes : `takeDamage(…, armorPiercePercent:, armorPierceFloor:)`, les lectures de `lifesteal` (Task 4).
- Produces :
  - `final class SplashPercentDelta` (`type` `splashPercent`, `valuePercentPerLevel`, non saturante) ; `CardDelta.typeNames` gagne `splashPercent` (le descripteur et `splash.json` l'exigent : `enumKeys['deltas[].type']` lit cette liste) ; `EffectiveCard.splashPercent`.
  - `ForgeUpgradeData.eligibleTargets` — `final List<String>? eligibleTargets` : `null` = toute cible ; lue par `_readNames(…, allowEmpty: false)`, chaque nom parmi `CardTarget.values` (refus nommé sinon) ; écrite par `toJson` si non nulle (A21).

- [ ] **Step 1: Écrire les tests qui échouent**

`forge_upgrade_data_test.dart` :
- `eligibleTargets : absente toute cible ; vide ou nom inconnu refuses ; aller-retour` — absente → `null` ; `[]` et `['enemy']` → clé `eligibleTargets` ; `['singleEnemy']` revient par `toJson`.
- `splashPercent se lit et s ecrit ; {val} Ricochant 3 vaut 75` — « Touche aussi les autres ennemis pour 75 % des dégâts ».

`rune_eligibility_test.dart` :
- `eligibleTargets : Ricochant refuse une carte allEnemies, accepte une singleEnemy` — `sweep` refusée, `strike_basic` acceptée, toutes deux peu communes.

`rune_resolution_test.dart`, groupe neuf `Ricochant` (trois ennemis à 100 PV ; la cible est le premier) :
- `Ricochant 1 : chaque autre ennemi vivant prend 25 % du coup, demie vers le haut, au moins 1` — `strike_basic` + `splash:1` : (94, 98, 98) ; carte `[damage 1]` + `splash:1` : (99, 99, 99) ; un ennemi à 0 PV ne reçoit rien.
- `l eclaboussure passe le pipeline de sa cible : son Electrocution et sa Vulnerabilite` — le deuxième ennemi sous Électrocution 2 et Vulnérable 2 : 2 + 2 = 4, × 1,5 → il finit à 94.
- `l eclaboussure est absorbee par l Armure de sa cible, Perforant compris` — deuxième ennemi à 5 Armure ; `splash:1` seul : (100 PV, 3 Armure) ; `splash:1` et `piercing:4` : (98, 5).
- `les eclaboussures comptent dans le vol de vie, statut et rune` — héros à 50, Vol de vie (statut) à 99, `strike_basic` + `splash:1` + `lifesteal:1` : dégâts 6 + 2 + 2 = 10 ; héros à 50 + 10 + 2 = 62.
- `un critique se tire pour chaque cible` — `precise:20` et `splash:1` : la cible perd 9, chacun des deux autres 3 (la base de l'éclaboussure, 2, prise avant le pipeline puis critiquée).

`forge_rune_rules_test.dart`, groupe `raisableCaps` :
- `Ricochant a son plafond 3 est propose` — `('splash', 3)` présente.

`entity_descriptor_test.dart` :
- `eligibleTargets est une liste de CardTarget, au gabarit` — `enumListKeys['eligibleTargets']` égale les noms de `CardTarget.values` ; le gabarit décodé porte les quatre.

`forge_upgrades_catalog_test.dart` : `_expected` gagne `splash` (**+1**). `_declared` et `_rune` gagnent `eligibleTargets` (défaut `null`) ; `read` (`:228-248`) gagne `'eligibleTargets'`.

Réécrits, sans changer le total : la matrice — un ensemble neuf `_singleTargetRank1 = {..._attackRank1, 'splash'}` (et son rang 2) pour `strike_basic`, `heavy_strike`, `fireball`, `ice_bolt`, `poison_stab`, `quick_attack`, `thunder_clap` ; `sweep` et `warcry` gardent `_attackRank1` ; le test des binaires, « les douze autres », `hasLength(14)` ; la table du gabarit de `entity_descriptor_test.dart:286-300` gagne `'eligibleTargets'` ; les comptes de la Task 4 passent à 14 / 97 / 14 ; `referential_integrity_test._effectOf` (`:16-23`, `switch` exhaustif sur la `sealed class`) gagne `SplashPercentDelta() => null` ; `deck_screen_test` gagne `splash`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/rune_eligibility_test.dart test/unit/rune_resolution_test.dart test/unit/forge_rune_rules_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/forge_upgrades_catalog_test.dart`
Expected: échec — `eligibleTargets`, `splashPercent` et `splash.json` n'existent pas.

- [ ] **Step 3: Implémenter**

- `splash.json` : Ricochant / Ricocheting ; « Touche aussi les autres ennemis pour {val} % des dégâts » / « Also hits the other enemies for {val}% of the damage » ; `minFusionRank` 1, `weight` 50, `eligibleEffects: ["damage"]`, `eligibleTargets: ["singleEnemy"]`, `maxLevel` 3, `deltas: [{splashPercent, 25}]`, `scatter_plot_rounded`, `limeAccent`, 💥. `rune_style.dart` gagne ces deux noms.
- `isEligible` lit `eligibleTargets` comme `eligibleCardTypes` (`:72-73`), sur `card.data.target.name`. `_valueAdded` : `SplashPercentDelta() => valuePercentPerLevel × level`.
- `DamageEffectStrategy`, **A17** : pour chaque coup d'une carte `singleEnemy` dont `effective.splashPercent > 0`, une fois la cible frappée, chaque **autre** ennemi vivant reçoit une base `max(1, (splashPercent × pre + 50) ~/ 100)`, où `pre` est la valeur initiale du coup avant pipeline (valeur jouée, terme, Puissance du coup) ; cette base passe `DamagePipeline.calculate` contre **cette** cible (son critique, avec le `critChanceBonus` de la carte), puis son `takeDamage`, perforation comprise ; ses dégâts s'ajoutent à `dealt`. Un coup perdu (cible morte) ne ricoche pas.
- Le descripteur de rune : `enumListKeys` gagne `'eligibleTargets': _names(CardTarget.values)` ; le gabarit porte `"eligibleTargets": ["singleEnemy", "allEnemies", "self", "none"]`, l'équivalent honnête de l'absence, par la raison écrite pour `eligibleCardTypes` (`entity_descriptor.dart:397-402`).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, plus `test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/rune_ids_in_code_test.dart test/unit/referential_integrity_test.dart test/widget/deck_screen_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1775** (1764 + 2 + 1 + 5 + 1 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(runes): Ricochant et eligibleTargets`.

---

### Task 6: *Résonant* — l'écho, une seconde résolution qui n'est pas un second jeu

**Files:**
- Create: `assets/data/forge_upgrades/echo.json`
- Modify: `lib/models/data/card_delta.dart`, `lib/models/effective_card.dart`, `lib/models/data/forge_upgrade_data.dart:275-289`, `lib/game/services/effect_resolver.dart:121-155`, `lib/ui/widgets/forge/rune_style.dart`
- Test: `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_eligibility_test.dart`, `test/unit/rune_resolution_test.dart`, `test/unit/effect_resolver_test.dart`, `test/unit/forge_rune_rules_test.dart`, `test/unit/forge_upgrades_catalog_test.dart`, `test/unit/referential_integrity_test.dart:16-23`, et les comptes

**Interfaces:**
- Consumes : `_resolveEffects` (Task 2), `ScriptedRandom` (`test/unit/scripted_random.dart`).
- Produces :
  - `final class EchoChanceDelta` (`type` `echoChance`, `valuePercentPerLevel`, `saturatesAt(level) => valuePercentPerLevel × level >= 100`) ; `CardDelta.typeNames` gagne `echoChance` (le descripteur et `echo.json` l'exigent) ; `EffectiveCard.echoChance`.
  - `EffectResolver.resolveCard(…, EffectRegistry registry, {Random? random})` — le générateur du jet, `Random()` par défaut ; `CombatController` ne le passe pas.

- [ ] **Step 1: Écrire les tests qui échouent**

`forge_upgrade_data_test.dart` :
- `echoChance se lit et s ecrit ; {val} Resonant 2 vaut 30` — « 30 % de chances de se rejouer ».

`rune_eligibility_test.dart` :
- `Resonant : refuse une carte qui pioche ou rend du mana, ou qui porte Econome ou Veloce` — `quick_attack` (pioche) refusée ; `defend_basic` rare portant `eco:1`, puis `quick:1`, refusée ; `defend_basic` rare nue acceptée.

`rune_resolution_test.dart`, groupe neuf `Resonant` (le `play` du fichier gagne un `Random? random` qu'il passe à `resolveCard`) :
- `jet reussi : les effets se resolvent une seconde fois, sans rien payer` — `strike_basic` + `echo:1`, `ScriptedRandom([0])`, mana 9 : ennemi à 88, mana 8.
- `jet manque : une seule resolution` — `ScriptedRandom([99])` : ennemi à 94.
- `un seul jet : jamais de troisieme resolution` — `echo:7` (105 %), `ScriptedRandom([0, 0])` : ennemi à 88.
- `la cible meurt a la premiere resolution : les degats se perdent, les effets sur soi se rejouent` — deux ennemis, la cible à 6 PV et un second, vivant, à 100 PV ; Attaque `singleEnemy` `[damage 6, armor 3]` + `echo:7` sur la cible : elle est à 0, **le second reste à 100** (l'écho vise la même cible, jamais une autre), héros à 6 Armure (décision T, voir le compte rendu : « sur la même cible si elle vit » vise les effets qui la frappent ; un effet sur soi se rejoue).
- `l echo ne declenche aucun evenement carte jouee` — le Mage sous le `mana_flux` livré (seuil 3), deux Compétences `self` `[armor 1]` à coût 0 portant `echo:7`, mises en main et jouées par `combat.applyPlayerCardPlay` : mana inchangé (quatre Compétences comptées l'auraient monté de 1), `cardsPlayedThisTurn` 2, défausse de 2 cartes (P-3 (a)).

`effect_resolver_test.dart`, groupe `Q11` :
- `l echo recoit son propre bonus de statut` — Mage, Puissance 2, `poison_stab` + `echo:7` : `poison` 2 × (1 + 2) = 6.

`forge_rune_rules_test.dart`, groupe `raisableCaps` :
- `Resonant : propose a 4 et a 6, ecarte a 7` — `echo` (`maxLevel` 4) portée à 4 : `('echo', 4)` ; à 6 sous `capBonus` 2 : `('echo', 6)` ; à 7 sous `capBonus` 3 : absente.

`forge_upgrades_catalog_test.dart` : `_expected` gagne `echo` (**+1**).

Réécrits, sans changer le total : la matrice gagne `echo` aux rangs 1 et 2 de `strike_basic`, `heavy_strike`, `fireball`, `ice_bolt`, `poison_stab`, `thunder_clap`, `sweep`, `warcry`, `defend_basic`, `iron_wall`, `heal_potion`, `demon_form`, `metallicize` — ni `quick_attack`, `awakening` (pioche), `concentration`, `focus` ; le test des binaires, « les treize autres », `hasLength(15)` ; comptes 15 / 98 / 15 ; `referential_integrity_test._effectOf` gagne `EchoChanceDelta() => null` ; `deck_screen_test` gagne `echo`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/forge_upgrade_data_test.dart test/unit/rune_eligibility_test.dart test/unit/rune_resolution_test.dart test/unit/effect_resolver_test.dart test/unit/forge_rune_rules_test.dart test/unit/forge_upgrades_catalog_test.dart`
Expected: échec — `echoChance`, `echo.json` et le paramètre `random` n'existent pas.

- [ ] **Step 3: Implémenter**

- `echo.json` : Résonant / Echoing ; « {val} % de chances de se rejouer » / « {val}% chance to play again » ; `minFusionRank` 1, `weight` 50, `excludesEffects: ["draw", "gain_mana"]`, `excludesRunes: ["eco", "quick"]` (A19 : des règles d'éligibilité en donnée), `maxLevel` 4, `deltas: [{echoChance, 15}]`, `replay_rounded`, `deepPurpleAccent`, 🔁. `rune_style.dart` gagne ces deux noms ; `_valueAdded` : `valuePercentPerLevel × level`.
- `resolveCard`, **l'étape 4 de spec §4.7** : après la première `_resolveEffects`, si `effective.echoChance > 0` et `(random ?? Random()).nextInt(100) < effective.echoChance`, une seconde `_resolveEffects` — même cible, sans paiement, sans second jet ; `_resolveEffects` remet son drapeau de bonus à chaque appel, l'écho reçoit donc le sien (A15). Rien d'autre : les piles et `_afterCardPlayed` restent au contrôleur, qui ne voit qu'un jeu.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, plus `test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/rune_ids_in_code_test.dart test/unit/referential_integrity_test.dart test/widget/deck_screen_test.dart`
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1785** (1775 + 1 + 1 + 5 + 1 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(runes): Resonant, une seconde resolution`.

---

### Task 7: Les coûts combinés et *Transfusion* — tâche à risque

**Le code s'écrit ici en entier.** D40, spec §4.1, A9, A10, A20 : `canAfford`, le débit hors du pipeline, des PV strictement supérieurs au coût, la rareté qui ne multiplie jamais `costs`, l'ordre des opérations, les cas limites.

**Files:**
- Create: `lib/game/systems/cost_rules.dart`, `assets/data/forge_upgrades/transfusion.json`, `test/unit/card_costs_test.dart`
- Modify: `lib/models/data/card_data.dart:105-211`, `lib/game/services/effect_resolver.dart:103-155`, `lib/game/controllers/run/player_stats_manager.dart:500-522`, `lib/game/controllers/run_controller.dart:557-560`, `lib/game/components/card_component.dart:53-57`, `lib/models/data/card_delta.dart`, `lib/models/effective_card.dart`, `lib/models/data/forge_upgrade_data.dart`, `lib/game/services/forge_rune_rules.dart:67-111`, `lib/ui/widgets/forge/rune_style.dart`, `lib/services/content_editor/entity_descriptor.dart:361-428`
- Test: `test/unit/card_costs_test.dart`, `test/unit/card_catalog_test.dart`, `test/unit/forge_upgrade_data_test.dart`, `test/unit/rune_eligibility_test.dart`, `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/forge_upgrades_catalog_test.dart`, `test/unit/real_bundle_load_test.dart:101-104`, et les comptes

**Interfaces:**
- Consumes : `_resolveEffects`, `resolveCard(…, {Random? random})`, `EffectiveCard.echoChance` (Tasks 2, 6).
- Produces :
  - `CardData` gagne `final int hpCost`, `final int armorCost` (paramètres nommés, défaut 0).
  - `extension CostRules on EntityStats { bool canPay({int mana = 0, int hp = 0, int armor = 0}) }`.
  - `static bool EffectResolver.canAfford(CardInstance card, EntityStats heroStats)`.
  - `bool RunController.consumeResource({int mana = 0, int hp = 0, int armor = 0})` et `void RunController.refundHp(int amount)`, relais de `PlayerStatsManager` ; le paramètre `hpPercent` disparaît (aucun appelant, `git grep -n "hpPercent:"` ne rend que le relais).
  - `final class RefundHpCostDelta` (`type` `refundHpCost`, `valuePercentPerLevel`) ; `EffectiveCard.hpRefundPercent`.
  - `ForgeUpgradeData.requiresCost` — `final String? requiresCost` ; `static const requiresCostValues = ['hp']` (A20 : `"armor"` n'aurait pas de lecteur).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/card_costs_test.dart` :

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
import 'package:roguelike_card_game/services/game_data_service.dart';

/// Les coûts combinés (D40 ; spec P-42 T1 et P-44 lot 1, §4.1, A9, A10,
/// A20) : la forme, la règle d'accessibilité, le paiement hors du pipeline,
/// *Transfusion*.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Une carte à `costs` telle qu'un fichier la porte. La partie 2 ajoutera
  /// ici `passive` : A8 refusera un coût en PV sur une neutre.
  Map<String, dynamic> costed(Object? costs) => {
        'id': 'test_costs',
        'type': 'attack',
        'target': 'singleEnemy',
        'effects': [
          {'type': 'damage', 'value': 1},
        ],
        'costs': costs,
      };

  Matcher refused(String key) => throwsA(isA<FormatException>()
      .having((e) => e.message, 'message', contains(key)));

  group('la forme (A9)', () {
    test('cost et costs ensemble sont refuses', () {
      expect(
        () => CardData.fromJson({...costed({'mana': 0, 'hp': 3}), 'cost': 1}),
        refused('"cost" et "costs"'),
      );
    });

    test('costs.mana absent ou negatif est refuse', () {
      expect(() => CardData.fromJson(costed({'hp': 3})), refused('costs.mana'));
      expect(() => CardData.fromJson(costed({'mana': -1, 'hp': 3})),
          refused('costs.mana'));
    });

    test('costs sans hp ni armor est refuse', () {
      expect(() => CardData.fromJson(costed({'mana': 1})),
          refused('sans "hp" ni "armor"'));
    });

    test('costs.discard est refusee, nommee', () {
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 2, 'discard': 1})),
          refused('costs.discard'));
    });

    test('costs.hp ou costs.armor a 0 est refuse', () {
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 0, 'armor': 2})),
          refused('costs.hp'));
      expect(() => CardData.fromJson(costed({'mana': 0, 'hp': 2, 'armor': 0})),
          refused('costs.armor'));
    });

    test('toJson ecrit costs ou cost, et l aller-retour garde les trois', () {
      final card = CardData.fromJson(costed({'mana': 1, 'hp': 3, 'armor': 2}));
      expect((card.cost, card.hpCost, card.armorCost), (1, 3, 2));
      final json = card.toJson();
      expect(json.containsKey('cost'), isFalse);
      final back = CardData.fromJson(json);
      expect((back.cost, back.hpCost, back.armorCost), (1, 3, 2));

      final manaOnly = costed(null)..remove('costs');
      manaOnly['cost'] = 2;
      final plain = CardData.fromJson(manaOnly);
      expect(plain.toJson()['cost'], 2);
      expect(plain.toJson().containsKey('costs'), isFalse);
    });

    test('une CardInstance a costs survit a l aller-retour de sauvegarde', () {
      final card = CardInstance(
        data: CardData.fromJson(costed({'mana': 0, 'armor': 4})),
        rarity: CardRarity.rare,
      );
      final back = CardInstance.fromJson(card.toJson());
      expect((back.data.cost, back.data.hpCost, back.data.armorCost), (0, 0, 4));
      expect(back.rarity, CardRarity.rare);
    });
  });

  group('le jeu', () {
    late GameDataRegistry registry;
    late ProviderContainer container;
    late RunController run;
    late CombatController combat;
    late String enemyId;

    setUpAll(() async {
      registry = await loadGameDataRegistry(rootBundle);
    });

    void startAs(String heroId, [String? passiveId]) => run.startNewRun(
          registry.heroes.singleWhere((h) => h.id == heroId),
          passiveId == null
              ? null
              : registry.passives.singleWhere((p) => p.id == passiveId),
        );

    setUp(() {
      container = ProviderContainer();
      run = container.read(runProvider.notifier);
      combat = container.read(combatProvider.notifier);
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

    EntityStats hero() => run.currentState.heroStats;

    void setHero({int? mana, int? pv, int? armor}) =>
        run.updateState(run.currentState.copyWith(
          heroStats: hero().copyWith(
            currentMana: mana,
            currentPv: pv,
            armure: armor,
          ),
        ));

    CardInstance card({
      int mana = 0,
      int hp = 0,
      int armor = 0,
      List<CardEffect> effects = const [CardEffect(type: 'damage', value: 1)],
      CardRarity rarity = CardRarity.common,
      List<String> runes = const [],
    }) =>
        CardInstance(
          data: CardData(
            id: 'test_costs',
            cost: mana,
            hpCost: hp,
            armorCost: armor,
            type: CardType.attack,
            rarity: CardRarity.common,
            target: CardTarget.singleEnemy,
            effects: effects,
          ),
          rarity: rarity,
          forgeUpgrades: runes,
        );

    bool play(CardInstance card) => EffectResolver.resolveCard(
          card,
          run,
          container.read(deckProvider.notifier),
          combat,
          enemyId,
          container.read(effectRegistryProvider),
        );

    group('canAfford (A10)', () {
      test('PV egaux au cout : refusee ; cout + 1 : acceptee', () {
        setHero(mana: 3, pv: 3);
        expect(EffectResolver.canAfford(card(hp: 3), hero()), isFalse);
        setHero(pv: 4);
        expect(EffectResolver.canAfford(card(hp: 3), hero()), isTrue);
      });

      test('Armure egale au cout : acceptee ; un de moins : refusee', () {
        setHero(mana: 3, armor: 4);
        expect(EffectResolver.canAfford(card(armor: 4), hero()), isTrue);
        setHero(armor: 3);
        expect(EffectResolver.canAfford(card(armor: 4), hero()), isFalse);
      });

      test('le mana d abord : sans mana, refusee malgre PV et Armure', () {
        setHero(mana: 1, pv: 50, armor: 10);
        expect(EffectResolver.canAfford(card(mana: 2, hp: 3, armor: 2), hero()),
            isFalse);
      });

      test('la rarete ne multiplie jamais les couts : une epique a 3 PV coute 3',
          () {
        setHero(mana: 3, pv: 4);
        final epic = card(hp: 3, rarity: CardRarity.epic);
        expect(EffectResolver.canAfford(epic, hero()), isTrue);
        expect(play(epic), isTrue);
        expect(hero().currentPv, 1);
      });
    });

    group('le paiement (§4.1)', () {
      test('une carte refusee n ecrit rien', () {
        setHero(mana: 3, pv: 3, armor: 2);
        var writes = 0;
        container.listen(runProvider, (_, _) => writes++);

        expect(play(card(hp: 3, armor: 1)), isFalse);

        expect(writes, 0);
        expect((hero().currentMana, hero().currentPv, hero().armure), (3, 3, 2));
        expect(combat.currentState.enemies.single.stats.currentPv, 100);
      });

      test('consumeResource debite mana, PV et Armure en une seule ecriture', () {
        setHero(mana: 3, pv: 50, armor: 5);
        var writes = 0;
        container.listen(runProvider, (_, _) => writes++);

        expect(run.consumeResource(mana: 1, hp: 3, armor: 2), isTrue);

        expect(writes, 1);
        expect((hero().currentMana, hero().currentPv, hero().armure), (2, 47, 3));

        // Par resolveCard aussi : une carte sans effet n'ecrit que son
        // paiement.
        writes = 0;
        expect(play(card(mana: 1, hp: 3, armor: 2, effects: const [])), isTrue);
        expect(writes, 1);
        expect((hero().currentMana, hero().currentPv, hero().armure), (1, 44, 1));
      });

      test('PV payes jusqu a 1 : la carte se resout jusqu au bout', () {
        setHero(mana: 3, pv: 4);
        expect(play(card(hp: 3)), isTrue);
        expect(hero().currentPv, 1);
        expect(combat.currentState.enemies.single.stats.currentPv, 99);
      });

      test('aucun onDamageTaken : Ferveur ne monte pas sur l Armure depensee', () {
        startAs('paladin', 'fervor');
        setHero(mana: 3, armor: 6);
        expect(play(card(armor: 4)), isTrue);
        expect(hero().armure, 2);
        expect(hero().statuses.where((s) => s.id == 'might'), isEmpty);
      });

      test('sous Rage, les PV payes comptent dans la Puissance du tour suivant',
          () {
        startAs('berserker', 'rage');
        setHero(mana: 3, pv: 80);
        expect(play(card(hp: 10)), isTrue);
        run.startTurn();
        final might = hero().statuses.where((s) => s.id == 'might');
        expect(might.fold<int>(0, (sum, s) => sum + s.value), 2);
      });

      test('Allege ne touche que le mana', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(mana: 1, hp: 3, rarity: CardRarity.rare,
            runes: const ['cheap:1'])), isTrue);
        expect((hero().currentMana, hero().currentPv), (3, 47));
      });
    });

    group('Transfusion (A20)', () {
      test('rend 2 sur un cout de 3, apres la resolution', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(hp: 3, runes: const ['transfusion:1'])), isTrue);
        expect(hero().currentPv, 49);
      });

      test('jamais au-dela des PV max', () {
        setHero(mana: 3, pv: 99);
        expect(play(card(hp: 3, runes: const ['transfusion:1'], effects: const [
          CardEffect(type: 'heal', value: 5),
        ])), isTrue);
        expect(hero().currentPv, 100);
      });

      test('une seule fois, apres l echo', () {
        setHero(mana: 3, pv: 50);
        expect(play(card(hp: 3, runes: const ['echo:7', 'transfusion:1'])),
            isTrue);
        expect(hero().currentPv, 49);
        expect(combat.currentState.enemies.single.stats.currentPv, 98);
      });
    });
  });
}
```

Les quatre autres :
- `forge_upgrade_data_test.dart` — `requiresCost n admet que hp ; refundHpCost se lit et s ecrit ; {val} Transfusion vaut 50` : `'armor'` et `'mana'` → clé `requiresCost` ; « Rend 50 % du coût en PV ».
- `rune_eligibility_test.dart` — `requiresCost hp : Transfusion refuse une carte sans cout en PV` : une Attaque peu commune à `hpCost` 3 acceptée, la même à `hpCost` 0 refusée ; et `requiresMinCost lit le mana : une carte a 0 mana et 4 Armure ne recoit ni Allege ni Econome` (spec §4.1, la ligne `cheap` : *Percée*, rare, à `cost` 0 et `armorCost` 4).
- `card_catalog_test.dart` — `aucune carte livree ne porte hpCost ni armorCost` : sur le registre livré, aucune `registry.cards` à `hpCost` ou `armorCost` non nul (D17 et l'invariant de spec §10 ; la partie 2 restreindra le test aux neutres, quand les lots en porteront).
- `entity_descriptor_test.dart` — `requiresCost : hp seulement, absente du gabarit` : `enumKeys['requiresCost']` égale `ForgeUpgradeData.requiresCostValues` ; `decodeTemplate()` ne porte pas la clé.
- `forge_upgrades_catalog_test.dart` : `_expected` gagne `transfusion` (**+1**) ; `_declared` et `_rune` gagnent `requiresCost` ; `read` gagne `'requiresCost'`.

Réécrits, sans changer le total : le test des binaires — `{'enduring', 'cheap', 'transfusion'}`, « enduring, cheap et transfusion sont binaires, les treize autres non », `hasLength(16)` ; `real_bundle_load_test.dart:101-104` : `['cheap', 'eco', 'enduring', 'quick', 'transfusion']` ; comptes 16 / 99 / 16 ; la matrice ne change pas (aucune neutre ne coûte de PV) ; `referential_integrity_test._effectOf` gagne son bras.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/card_costs_test.dart test/unit/card_catalog_test.dart test/unit/forge_upgrade_data_test.dart test/unit/rune_eligibility_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/forge_upgrades_catalog_test.dart`
Expected: échec de compilation — `hpCost`, `canAfford`, `consumeResource(hp:)`, `requiresCost` n'existent pas.

- [ ] **Step 3: La règle — `lib/game/systems/cost_rules.dart`**

```dart
import '../../models/entity_stats.dart';

/// La règle d'accessibilité des coûts combinés (D40 ; spec P-42 T1 et P-44
/// lot 1, §4.1, A10) : la seule écriture des trois bornes.
/// `EffectResolver.canAfford` la lit pour une carte ;
/// `PlayerStatsManager.consumeResource` avant de débiter.
extension CostRules on EntityStats {
  /// Vrai si le héros peut payer [mana], [hp] et [armor] : le mana courant ;
  /// des PV **strictement** supérieurs au coût en PV — une carte ne tue jamais
  /// son porteur ; une Armure au moins égale au coût en Armure.
  bool canPay({int mana = 0, int hp = 0, int armor = 0}) =>
      currentMana >= mana && (hp == 0 || currentPv > hp) && armure >= armor;
}
```

- [ ] **Step 4: La forme — `CardData`**

Les deux champs, après `cost`, et leurs paramètres `this.hpCost = 0, this.armorCost = 0` :

```dart
  /// Le coût en PV et en Armure (D40) : jamais lu par la rareté, jamais
  /// touché par une rune — `cheap` ne réduit que [cost], le mana.
  final int hpCost;
  final int armorCost;
```

Dans `fromJson`, `cost: json['cost'] as int` devient `cost: mana, hpCost: hpCost, armorCost: armorCost`, après `final (mana, hpCost, armorCost) = _readCosts(json);` ; la lecture :

```dart
  static const _costKeys = {'mana', 'hp', 'armor'};

  /// A9 : `cost` (le mana seul) ou `costs`, jamais les deux. `costs` exige
  /// `mana` (entier >= 0) et au moins un de `hp`, `armor` (entier >= 1) ;
  /// toute autre clé est refusée, nommée — `discard` est P-44 lot 4.
  static (int, int, int) _readCosts(Map<String, dynamic> json) {
    FormatException fault(String why) =>
        FormatException('CardData "${json['id']}": $why');

    if (!json.containsKey('costs')) return (json['cost'] as int, 0, 0);
    if (json.containsKey('cost')) {
      throw fault('"cost" et "costs" ensemble sont refusés : l\'un ou l\'autre');
    }
    final costs = json['costs'];
    if (costs is! Map<String, dynamic>) {
      throw fault('"costs" doit être un objet — reçu : $costs');
    }
    for (final key in costs.keys) {
      if (!_costKeys.contains(key)) throw fault('"costs.$key" est refusée');
    }
    final mana = costs['mana'];
    if (mana is! int || mana < 0) {
      throw fault('"costs.mana" doit être un entier >= 0 — reçu : $mana');
    }
    int extra(String key) {
      final value = costs[key];
      if (value == null) return 0;
      if (value is! int || value < 1) {
        throw fault('"costs.$key" doit être un entier >= 1 — reçu : $value');
      }
      return value;
    }

    final hp = extra('hp');
    final armor = extra('armor');
    if (hp == 0 && armor == 0) {
      throw fault('"costs" sans "hp" ni "armor" : écrire "cost"');
    }
    return (mana, hp, armor);
  }
```

Dans `toJson`, `'cost': cost,` devient :

```dart
        if (hpCost > 0 || armorCost > 0)
          'costs': {
            'mana': cost,
            if (hpCost > 0) 'hp': hpCost,
            if (armorCost > 0) 'armor': armorCost,
          }
        else
          'cost': cost,
```

- [ ] **Step 5: Le débit — `PlayerStatsManager` et son relais**

`player_stats_manager.dart:500-522`, à la place de l'ancien `consumeResource` :

```dart
  /// Débite le coût d'une carte — [mana], [hp], [armor] — en **une seule**
  /// écriture d'état (spec §4.1) : ni `takeDamage`, ni absorption, ni
  /// critique, ni vol de vie, ni `onDamageTaken`, ni soin négatif. Rend
  /// `false` sans rien écrire si `CostRules.canPay` refuse.
  bool consumeResource({int mana = 0, int hp = 0, int armor = 0}) {
    final stats = controller.currentState.heroStats;
    if (!stats.canPay(mana: mana, hp: hp, armor: armor)) {
      ref.read(audioDirectorProvider).onMoment(GameMoment.insufficientMana);
      return false;
    }
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: stats.copyWith(
          currentMana: stats.currentMana - mana,
          currentPv: stats.currentPv - hp,
          armure: stats.armure - armor,
        ),
      ),
    );
    return true;
  }

  /// Rend [amount] PV hors du pipeline et hors de [heal] — ni critique, ni
  /// soin —, borné aux PV max : le remboursement de *Transfusion* (A20).
  void refundHp(int amount) {
    final stats = controller.currentState.heroStats;
    controller.updateState(
      controller.currentState.copyWith(
        heroStats: stats.copyWith(
          currentPv: min(stats.maxPv, stats.currentPv + amount),
        ),
      ),
    );
  }
```

(imports : `../../systems/cost_rules.dart`, et `min` de `dart:math` s'il manque.) `run_controller.dart:557-560` :

```dart
  /// Débite le coût d'une carte ; voir `PlayerStatsManager.consumeResource`.
  bool consumeResource({int mana = 0, int hp = 0, int armor = 0}) =>
      _playerStatsManager.consumeResource(mana: mana, hp: hp, armor: armor);

  /// Le remboursement de *Transfusion* ; voir `PlayerStatsManager.refundHp`.
  void refundHp(int amount) => _playerStatsManager.refundHp(amount);
```

- [ ] **Step 6: L'ordre — `EffectResolver`**

`canPlayCard` (`effect_resolver.dart:104-119`) et `resolveCard` (`:122-155`), sous leur forme finale — `_resolveEffects` est celui de la Task 2, l'écho celui de la Task 6 :

```dart
  /// La seule règle d'accessibilité d'une carte (A10) : le mana courant,
  /// runes appliquées ; les coûts en PV et en Armure de la donnée, que ni la
  /// rareté ni une rune ne changent (D40). `canPlayCard` et
  /// `CardComponent.canAfford` la lisent.
  static bool canAfford(CardInstance card, EntityStats heroStats) =>
      heroStats.canPay(
        mana: card.currentCost,
        hp: card.data.hpCost,
        armor: card.data.armorCost,
      );

  /// Vérifie si la carte peut être jouée : ses coûts, puis les deux règles
  /// d'aujourd'hui — une carte Statut ne se joue pas, une cible unique exige
  /// un ennemi.
  static bool canPlayCard(
    CardInstance card,
    RunState runState,
    String? selectedEnemyId,
  ) {
    if (!canAfford(card, runState.heroStats)) return false;
    if (card.data.type == CardType.status) return false;
    if (card.data.target == CardTarget.singleEnemy && selectedEnemyId == null) {
      return false;
    }
    return true;
  }

  /// Joue une carte, dans l'ordre de spec §4.7 : (1) refusée, rien n'est
  /// écrit ; (2) le paiement ; (3) les effets ; (4) l'écho ; (5)
  /// *Transfusion*. Une carte payée se résout jusqu'au bout.
  static bool resolveCard(
    CardInstance card,
    RunController runController,
    DeckNotifier deckController,
    CombatController combatController,
    String? selectedEnemyId,
    EffectRegistry registry, {
    Random? random,
  }) {
    // 1.
    if (!canPlayCard(card, runController.currentState, selectedEnemyId)) {
      return false;
    }

    // 2. Une écriture, hors du pipeline. Le contrôle de l'étape 1 porte sur
    // le même état : le débit réussit.
    final hpCost = card.data.hpCost;
    if (!runController.consumeResource(
      mana: card.currentCost,
      hp: hpCost,
      armor: card.data.armorCost,
    )) {
      return false;
    }

    // 3. et 4. Une seconde résolution au plus, sans coût ni second jet (A19).
    final effective = card.effective;
    void resolveOnce() => _resolveEffects(card, effective, runController,
        deckController, combatController, selectedEnemyId, registry);
    resolveOnce();
    if (effective.echoChance > 0 &&
        (random ?? Random()).nextInt(100) < effective.echoChance) {
      resolveOnce();
    }

    // 5. La moitié du coût en PV, la demie vers le haut, une fois (A20).
    if (hpCost > 0 && effective.hpRefundPercent > 0) {
      runController.refundHp((effective.hpRefundPercent * hpCost + 50) ~/ 100);
    }
    return true;
  }
```

(imports : `dart:math` pour `Random`, `../../models/entity_stats.dart`, `../systems/cost_rules.dart`.)

- [ ] **Step 7: L'écran Flame — `CardComponent.canAfford`** (`card_component.dart:53-57`), avec l'import `import '../services/effect_resolver.dart';` parmi ceux de `card_component.dart:6-17`

```dart
  bool get canAfford {
    if (!isLoaded || !isMounted) return true;
    final heroStats = game.currentRunState?.heroStats;
    // Sans run, la règle d'avant : seule une carte gratuite passe.
    if (heroStats == null) return card.currentCost <= 0;
    return EffectResolver.canAfford(card, heroStats);
  }
```

Les trois refus à l'écran (`card_interaction_handler.dart:134-139`, `heros_draft_game.dart:328-331`, `hero_card.dart:87-88`) lisent ce getter et ne changent pas.

- [ ] **Step 8: *Transfusion***

- `RefundHpCostDelta` : `type` `refundHpCost`, `valuePercentPerLevel` lu par `_positive`, non saturant ; `typeNames` gagne le nom ; `EffectiveCard.hpRefundPercent` somme `valuePercentPerLevel × L` ; `_valueAdded` : `valuePercentPerLevel × level` ; `referential_integrity_test._effectOf` : `=> null`.
- `ForgeUpgradeData.requiresCost` : absent `null` ; présent, une valeur de `requiresCostValues`, sinon `FormatException` nommant `requiresCost` ; `toJson` l'écrit s'il est non nul. `isEligible` : `requiresCost == 'hp'` exige `card.data.hpCost >= 1` ; `requiresMinCost` lit toujours le mana courant (D61).
- `transfusion.json` : Transfusion / Transfusion ; « Rend {val} % du coût en PV » / « Refunds {val}% of the HP cost » ; `minFusionRank` 1, `weight` 50, `requiresCost: "hp"`, `maxLevel` 1, `binary: true`, `deltas: [{refundHpCost, 50}]`, `bloodtype_rounded`, `red`, 💉. `rune_style.dart` gagne `bloodtype_rounded` et `red`.
- Le descripteur de rune : `enumKeys` gagne `'requiresCost': ForgeUpgradeData.requiresCostValues` ; la clé n'entre pas au gabarit (absente, elle vaut « aucune exigence », comme `excludesRunes`), et le commentaire du gabarit le dit.

- [ ] **Step 9: Lancer les tests, constater le succès**

Run: `flutter test test/unit/card_costs_test.dart test/unit/card_catalog_test.dart test/unit/forge_upgrade_data_test.dart test/unit/rune_eligibility_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/forge_upgrades_catalog_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/rune_ids_in_code_test.dart test/unit/referential_integrity_test.dart test/unit/passives_mage_test.dart test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: tout passe ; `passives_mage_test.dart:141` (`run.consumeResource(mana: 3)`) compile sans retouche.

- [ ] **Step 10: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1811** (1785 + 20 + 1 + 2 + 1 + 1 + 1).

- [ ] **Step 11: Commit**

`git add` par chemin, puis `git commit` — `feat(couts): couts en PV et en Armure, Transfusion`.

---

### Task 8: Vérification finale (orchestrateur)

Aucun fichier modifié : des commandes, jouées par l'orchestrateur, sans agent.

- [ ] **Step 1: L'analyse** — `dart analyze` → `No issues found!`
- [ ] **Step 2: La suite** — `flutter test` → `All tests passed!`, **1811**.
- [ ] **Step 3: Les greps de la spec (§11, « Ce que le vérificateur contrôle », pour ce qui touche la partie 1)**
  - `git grep -n "onDamagingCardPlayed" -- lib test assets` → rien (D34).
  - `grep -c '"trigger": "onAttackPlayed"' assets/data/passives/mage_mark.json` → `1`.
  - `git diff main -- tool/simulations` → vide.
  - `dart run tool/sync_assets.dart --check` → code de sortie 0.
- [ ] **Step 4: Les greps propres à la partie 1**
  - `grep -nE "[0-9]+ ?%" lib/game/components/card_component.dart lib/ui/widgets/ui_card/ui_card_helpers.dart lib/tutorial/widgets/tutorial_elements_widget.dart` → rien (spec §4.4 : aucun texte n'écrit plus un pourcentage en dur ; le 03/11, ce grep rend exactement les dix-huit lignes de Faiblesse, Vulnérable et Gel que la Task 3 remplace).
  - `grep -n "divise par deux\|halves" lib/tutorial/tutorial_data.dart` → rien.
  - `git grep -n "hpPercent:" -- lib test` → rien (le paramètre de `consumeResource` a disparu).
  - `git diff --name-only main -- assets/data` → exactement `assets/data/cards/ice_bolt.json`, `assets/data/forge_upgrades/{echo,freezing,lifesteal,piercing,splash,transfusion}.json`, `assets/data/passives/mage_mark.json` (aucune carte ne porte encore `costs`, `hits` ni `scaleWith`).
  - `git status --short` → propre ; aucun `generated_plugin*` ni `GeneratedPluginRegistrant.swift` modifié.
