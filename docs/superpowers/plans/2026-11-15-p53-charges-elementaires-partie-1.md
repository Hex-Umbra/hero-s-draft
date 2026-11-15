# P-53, les charges élémentaires — partie 1 : le cadre, le moteur, les contenus et ce que le joueur lit — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (méthode fixée par l'orchestrateur). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** le Gel, le Feu et la Foudre deviennent des charges en donnée — points qui s'accumulent jusqu'à un seuil où ils rompent —, jouées par un moteur symétrique héros / ennemis, et tout ce que le joueur lit (cartes, runes, panneaux, intentions, tutoriel) dit la règle que le moteur joue.

**Architecture :** un catalogue `assets/data/charges/<id>.json` lu par le chargeur dans `ChargeCatalog` et servi par `chargeCatalogProvider` ; les points restent des `StatusEffect`, le reste de l'état (seuil courant, ruptures, état, rupture en vigueur) vit sur une piste `ChargeTrack` portée par `EntityStats.charges`, hors sauvegarde ; toutes les règles sont des fonctions pures de `ChargeRules` (`lib/game/systems/charge_rules.dart`) que le contrôleur appelle, la chaîne du Feu se joue vague par vague et laisse un compte rendu dans `CombatState` que Flame lit. Flame ne gagne aucune animation dans cette partie.

**Tech Stack :** Flutter, Flame 1.17, Riverpod 2.5 (`Notifier`), `flutter_test`, ARB + `flutter gen-l10n`.

**Spec :** `docs/superpowers/specs/2026-11-15-p53-charges-elementaires-design.md` — §10 « Partie 1 », et tout ce qu'elle couvre : §1 à §9, les lignes « 1 » de §9 et de §9.1. Arbitrages A1 à A19 et réponses P-a à P-e : spec §1.2, §1.3 ; options écartées : `…-design-verifications.md` §1. **Ne rouvrir aucun de ces arbitrages.**

Branche : `feat/v0.5.9-p53-charges-elementaires`, sans en créer. Base de tests : **1682**. Total attendu à la fin : **1765**.

---

## Contraintes globales

Recopiées du fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §3.5) ; elles valent pour chaque tâche :

- `dart analyze` rend `No issues found!` et `flutter test` est entièrement vert **à la fin de chaque tâche**.
- Ne rien pousser, n'ouvrir aucune PR, ne rien commiter sur `main`, n'invoquer aucun skill de livraison — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync`.
- **Jamais `dart format`** ; Write / Edit plutôt que heredoc.
- Les fichiers que `flutter` régénère sont suivis par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification, `git add` **par chemin**, jamais `git add -A` ; les restaurer par `git restore` s'ils apparaissent modifiés.
- Après toute retouche d'un ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit.
- Après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge.
- Tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart`.
- Les trois couches de `CLAUDE.md` ne se mélangent pas (Flame lit l'état, ne calcule aucune règle) ; pas de code sans lecteur, pas de code mort, pas de bloc commenté.
- Commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/`.
- **Aucun test d'écran neuf** (D77) : aucun `testWidgets(` ajouté ; l'écran passe aux tests manuels (spec §9.1).
- Jamais `GameDataRegistry.instance` dans une règle : le catalogue arrive par `chargeCatalogProvider` (contrôleurs, stratégies), par le constructeur de `HerosDraftGame` (Flame), par paramètre (widgets) ou par `engine.data.charges` (tutoriel) — spec A2.
- Un test qui joue un contenu posant une charge, ou qui en pose une à la main par la règle, **surcharge `chargeCatalogProvider` avec le catalogue livré** par l'aide `shippedChargeOverride()` (Task 1) ; sans quoi rien n'est posé (A4) et le pipeline ne lit aucune Foudre (A14).

## Review Focus

Les cinq modes d'échec les plus risqués qu'aucun test ne garde encore (vérifications de la spec, §4 et §5) ; chacun a son test dans la tâche nommée.

1. **Le catalogue en test.** Un `ProviderContainer()` sans surcharge — tous les tests de combat d'aujourd'hui — lit `chargeCatalogProvider` : il doit rendre le catalogue vide **sans lever** (`valueOrNull`, jamais `requireValue`), sinon chaque test de combat rougit ; et un test qui joue une charge sans la surcharge ne pose rien, en silence. → **Task 1** écrit `chargeCatalogProvider rend le catalogue vide sans registre charge` ; **Task 3** pose la surcharge commune dans les quatre fichiers qui jouent une charge.
2. **La piste perdue.** `copyWith`, `takeDamage`, `addStatus` et `tickStatuses` gardent `EntityStats.charges` ; `toJson` ne l'écrit pas, `fromJson` la rend vide. Une piste perdue efface un gel en attente ou un seuil monté sans qu'aucun chiffre ne l'annonce. → **Task 3**.
3. **Le porteur que son Poison achève à son tour explose quand même** (A10) : le Feu se résout avant le Poison, et la mort ne se constate qu'au `cleanDeadEnemies` final. → **Task 5**.
4. **Le gel du héros en attente survit à la fermeture du tour du joueur** (un gel posé pendant son tour ne doit pas mourir avant d'avoir joué), devient actif au début de son tour suivant, finit à la fermeture de ce tour-là. → **Task 5**.
5. **L'ennemi gelé sans intention consomme son gel** (A13) : Flame appelle `onResolveEnemyIntent` avant le test `intent == null`, et le contrôleur consomme le gel avant de lire l'intention. → **Task 6**.

Les autres trous de test remontés par la vérification de la spec, un par tâche :

- la place du helper « début de phase ennemie complet », qui sert trois fichiers dont `test/encounter_system_test.dart` → Task 5 ; les appels qui ne compileront plus (§9 « Signatures qui changent ») → la tâche qui change chaque signature (Task 3 : `tickStatuses`, processeurs ; Task 4 : `DamagePipeline.calculate` ; Task 7 : `HerosDraftGame` ; Task 8 : `CardRuleTexts.scale`, `EffectLineTexts.phrase`) ;
- −50 % sur l'éclaboussure de *Ricochant* pour un héros gelé → Task 4 ;
- tous les ennemis d'un combat de boss au seuil 6, une élite à 3 → Task 6 ;
- *Rafale d'étincelles* 12 et 27 en toutes lettres → Task 4 ;
- la Puissance ajoutée avant le plafond du Gel → Task 3 ;
- `rune_resolution_test` aux PV `[95, 85, 71]` et Foudre `(6, null)` → Task 4 ;
- `CardRuleTexts.scale` sur une charge en `targetStatus` dit le nom, jamais l'id → Task 8 ;
- `DebugActions.skipEnemyPhase` saute les fermetures de phase : documenté, et un test le fixe → Task 11 ;
- `StatusIndicator` : une charge dessinée une fois, par sa ligne, aux deux chemins d'`EnemyCard` et dans son constructeur d'`onLoad` → Task 7 (paramètre obligatoire : le compilateur l'exige ; aucun test d'écran, D77) ;
- l'égalité de valeur de `ChargeLine` → Task 3 ;
- les bouchons des rappels neufs de `HerosDraftGame` dans `flame_image_prefix_test.dart` et `heros_draft_game_targeting_test.dart` → Task 7 ;
- `buildDetailedDescription` lu avec `listen: false` → Task 8 : six tests d'écran existants rendent des cartes (`git grep -ln UiCard -- test` : `event_screen_test`, `forge_fusion_screen_test`, `rest_card_selection_screen_test`, `rest_screen_test` ; `deck_screen_test` par `deck_screen.dart:95` ; `sharpen_rune_dialog_test` par `forge_card_preview.dart:28`), et `ui_card.dart:159` construit l'infobulle à chaque `build` ; les six sont sous `UncontrolledProviderScope`, et Task 8 les lance nommément ;
- les trois tests de `referential_integrity_test.dart` (`:198-217`, `:265-294`, `:346-361`) changent ensemble, titres compris → Task 3 ;
- la largeur utile du panneau du héros → Task 9 (décision Q1 ci-dessous, test manuel M9 et M12) ;
- le bonus par coup sur les deux chemins d'`EnemyCard` et sur le héros chargé (`hero_card.dart:173`) → **partie 2**, hors de ce plan (décision Q2) ;
- M8 corrigé recopié dans le fichier de tests manuels → **hors plan** : ce fichier est écrit par l'agent de §3.8 du fichier d'orchestration, à partir de la spec §9.1, qui porte déjà M8 corrigé.

## Décisions du plan

Classe T, tranchées par les filtres de §5 du fichier d'orchestration ; les options écartées sont dans le rendu du rédacteur.

- **Q1 — la ligne du gel en attente** (« Gelé : −50 % de dégâts au prochain tour », 248 px pour ~196 utiles). Les lignes de charge du panneau du héros n'ont pas de colonne de durée et leur libellé se replie sur deux lignes (`softWrap`, sans `maxLines` ni ellipse) ; le texte ne change pas. *Filtre 6* (le joueur lit tout le texte, à sa taille), puis *7* (élargir le panneau toucherait la mise en page de son jumeau et de la barre des signatures). **Quand ses lignes dépassent la réserve** (`CombatSidePanels.statusPanelReserve`, 120 px, `combat_side_panels.dart:17`, au-dessus de laquelle commence la bande des signatures, `signature_bar.dart:45-46`) — par exemple héros gelé en attente et Puissance, 131 px —, le panneau garde sa hauteur bornée à la réserve et sa liste défile, barre de défilement visible ; la barre des signatures ne bouge pas et aucun texte n'est coupé (*filtre 6* : le joueur lit le même texte en entier, en faisant défiler ; *7* : une réserve qui suivrait le contenu déplacerait la bande des signatures, A38 de la vague 5).
- **Q2 — transmettre les coups un à un à Flame** (L-b). **Ce plan ne le porte pas** (arbitrage confirmé par l'orchestrateur, *filtres 7 puis 8*) : le moyen se choisit avec l'affichage qu'il sert, qui est de la partie 2 (*7*), et ne rien écrire dans l'état aujourd'hui évite d'en retirer un champ si la partie 2 retient un autre moyen (*8*). **Si le plan de la partie 2 retient un passage par l'état, ce moyen et son test s'implémentent comme un complément de la partie 1 — règle, état, test automatique —, en tête du plan de la partie 2 et avant toute animation**, conformément à la spec §10 (la partie 2 elle-même reste sans test automatique). La partie 1 laisse le seul point de passage de chaque coup, `DamageEffectStrategy._strike`, et la règle qui chiffre le bonus, `ChargeRules.hitBonus` (Task 4), que ce moyen réutilisera.
- Le catalogue est une classe, `ChargeCatalog`, vide par défaut, sur le modèle d'`EffectIconTable` (*filtre 5*).
- La source des charges est déclarée une fois, en constante publique `chargeSource` à côté de `cardSources`, pour que le test d'injection la lise (*filtre 8*).
- `startEnemyTurn()` rend `bool` — vrai si une première vague du Feu s'est jouée — : Flame sait sans lire de provider s'il doit attendre une vague (*filtre 5*).
- Les porteurs de la vague suivante sont dans le compte rendu (`FireWaveReport.nextBearerIds`) : l'état, pas un champ du gestionnaire, porte la chaîne entre deux appels (*filtre 5*).
- Flame lit le compte rendu dans `StateSyncSystem` et pose la flamme existante (`effect_icon.dart:126`) sur chaque porteur résolu (*filtre 5*).
- Une résolution du Feu d'au moins une tranche compte une rupture (ruptures + 1, seuil + `thresholdGrowth`) : la même règle pour les quatre sortes ; invisible aux valeurs livrées (`thresholdGrowth: 0`) (*filtre 4*).
- Les jetons de `description` se remplissent avec `rupture`, ceux de `heroDescription` avec `heroRupture` (*filtre 5*).
- `ChargeLine.value` vaut le pourcentage pour `weakenDealt`, `points × bonusPerPoint` pour `amplifyHits`, 0 sinon (*filtre 8*).
- Le helper de test « début de phase ennemie complet » vit dans `test/unit/enemy_phase_helper.dart` (*filtre 8*).
- `DebugActions.clearCharges` vide les charges du héros et de tous les ennemis, un seul bouton ; les libellés du menu de debug restent en français écrit en dur, comme le reste du menu (*filtre 5*, précédent `debug_combat_tab.dart`).
- `DebugActions.skipEnemyPhase` ne joue aucune fermeture de phase : un raccourci de debug, documenté par son commentaire et un test (*filtre 8*).
- `ProportionalStatus.freeze` et `statusFreezeHint` disparaissent avec leur dernier lecteur, le tutoriel (Task 10) (*filtre 8*).

**Une question P reste ouverte** (Q-P1, signalée au rendu) : où le joueur lit-il `heroDescription` (« Sur vous : à 5, vos cartes et signatures infligent 50 % de dégâts en moins… ») ? La spec la fixe en donnée et la valide (A3), sans lui donner d'écran. Options : (a) dans l'infobulle des contenus qui posent du Gel, après la description de la charge (Task 8) ; (b) dans l'entrée Gel de la galerie du tutoriel (Task 10) ; (c) sur la ligne du héros gelé, dans son panneau (Task 9) ; (d) nulle part en `0.5.9` — recommandé : (d). **Appliquée à titre provisoire sous (d)** (provisoire) : le plan la livre en donnée validée et éditable, sans lecteur d'affichage ; une autre réponse du propriétaire ajoute une ligne à la tâche nommée.

---

## Carte des fichiers

| Fichier | Responsabilité | Tâches |
|:---|:---|:---:|
| `assets/data/charges/{freeze,burn,shock}.json` *(nouveaux)* | Les trois charges, valeurs de D84 à D86, noms de P-a, textes de spec §6.1 | 1 |
| `lib/models/data/charge_data.dart` *(nouveau)* | `ChargeData`, `ChargeRupture`, `ChargeCatalog`, `RuptureKind`, `ChargeBreaksOn`, `ChargeBearer` ; validation (A3), jetons (§6.1) | 1 |
| `lib/models/data/game_data_registry.dart` | `charges`, vide par défaut | 1 |
| `lib/services/game_data_service.dart` | `chargeSource`, la onzième source ; `chargeCatalogProvider` | 1 |
| `lib/services/content_editor/entity_descriptor.dart` | `EntityCategory.charge` et son descripteur | 1 |
| `pubspec.yaml` (section `assets:` seulement, par l'outil) ; `CLAUDE.md` ; `README.md` | `assets/data/charges/` ; la doc du dépôt (spec §3.3) | 1 |
| `lib/models/charge_track.dart` *(nouveau)* | `ChargeTrack`, `ChargeState` | 3 |
| `lib/models/entity_stats.dart` | `charges`, `clearCombatEffects()`, `tickStatuses(Set<String>)` | 3 |
| `lib/game/systems/charge_rules.dart` *(nouveau)* | Toutes les règles pures des charges, `ChargeLine` | 3, 4, 5, 6 |
| `lib/game/services/effect_resolver.dart` | `createStatus` perd `burn`, `freeze`, `shock` | 3 |
| `lib/game/services/effects/strategies.dart` | La pose aiguillée ; le pipeline reçoit le catalogue | 3, 4 |
| `lib/game/controllers/run_controller.dart`, `run/map_progression_manager.dart` | `updateHeroStats` ; une remise à zéro unique ; le tour du héros | 3, 5 |
| `lib/game/controllers/combat/status_effect_processor.dart` | Les statuts de début de tour, Feu du héros, déclins | 3, 5 |
| `lib/game/controllers/combat/turn_phase_manager.dart`, `combat_controller.dart` | Fermetures, chaîne du Feu, statuts ennemis, ennemi gelé | 3, 4, 5, 6 |
| `lib/game/services/damage_pipeline.dart` | Étape 1 bis `weakenDealt`, étape 3 `amplifyHits` | 4 |
| `lib/tutorial/tutorial_engine.dart` | Le pipeline reçoit `data.charges` | 4 |
| `lib/models/fire_wave_report.dart` *(nouveau)*, `lib/models/combat_state.dart` | Le compte rendu de vague, non sérialisé | 5 |
| `lib/models/enemy_instance.dart` | `skippingCharge`, `skipsAction` ; `effectiveIntent` sans Gel | 6 |
| `lib/game/heros_draft_game.dart`, `game_constants.dart`, `components/entities/enemy_card.dart`, `components/entities/status_indicator.dart`, `systems/state_sync_system.dart`, `lib/ui/screens/game_screen.dart` | Flame : catalogue, vagues une à une, ennemi gelé sans bond, indicateurs | 7 (et `game_screen.dart` en 5, 8, 9) |
| Les dix contenus (spec §3.4) | P-b et les textes de P-a | 2 |
| `lib/l10n/app_fr.arb`, `app_en.arb`, `app_localizations*.dart` | Clés à trous (spec §6.2) ; retrait des clés d'A16 | 8, 9, 10 |
| `lib/ui/widgets/ui_card/ui_card_helpers.dart`, `lib/game/components/card_component.dart`, `lib/game/services/card_rule_texts.dart`, `lib/game/services/effect_line_texts.dart`, `lib/ui/widgets/hud/signature_bar.dart` | Les textes des cartes et des signatures | 8 |
| `lib/ui/widgets/hud/status_effects_panel.dart`, `enemy_intents_panel.dart`, `combat_side_panels.dart` | Le panneau du héros, celui des intentions | 9 |
| `lib/tutorial/tutorial_data.dart`, `lib/tutorial/widgets/tutorial_elements_widget.dart`, `lib/game/services/proportional_status.dart` | Le tutoriel ; le Gel quitte le barème de P-1 | 10 |
| `lib/game/services/debug_actions.dart`, `lib/ui/widgets/debug/tabs/debug_combat_tab.dart` | L'entrée de debug (P-e) | 11 |
| `test/unit/charge_data_test.dart`, `charge_rules_test.dart`, `charge_symmetry_test.dart`, `enemy_phase_helper.dart` *(nouveaux)* ; `test/unit/shipped_data.dart` | Les tests neufs ; les aides `shippedChargeCatalog()`, `shippedChargeOverride()`, `runEnemyPhaseStart()` | 1, 3, 5, 6 |

---

### Task 1: Le cadre en donnée — les trois fichiers, le modèle, la source, le provider, l'éditeur

**Files :**
- Create : `assets/data/charges/freeze.json`, `burn.json`, `shock.json` ; `lib/models/data/charge_data.dart` ; `test/unit/charge_data_test.dart`
- Modify : `lib/models/data/game_data_registry.dart:43-62` ; `lib/services/game_data_service.dart:62-73`, `:91-190`, `:207` ; `lib/services/content_editor/entity_descriptor.dart:20-35`, `:262` ; `lib/services/content_editor/entity_validator.dart:687-712` ; `lib/ui/widgets/content_editor/editor_style.dart:107-118` ; `pubspec.yaml` (`assets:`) ; `CLAUDE.md:43`, `:76-85` ; `README.md:66-71` ; `test/unit/shipped_data.dart`
- Test : `test/unit/charge_data_test.dart` ; `test/unit/real_bundle_load_test.dart:25`, `:93-160` ; `test/unit/game_data_loader_injection_test.dart` ; `test/unit/entity_id_convention_test.dart:72-81` ; `test/unit/content_editor/entity_descriptor_test.dart:20`, `:39`, `:302-411` ; `test/widget/content_editor_screen_test.dart` (inchangé, lancé)

**Interfaces :**
- Produces, dans `charge_data.dart` :
  - `enum RuptureKind { skipAction, weakenDealt, explode, amplifyHits }`, `enum ChargeBreaksOn { threshold, bearerTurn }`, `enum ChargeBearer { enemy, boss, hero }` — noms des enums = valeurs JSON ;
  - `class ChargeRupture` (immuable, `==` et `hashCode`) : `final RuptureKind kind`, `final Map<String, int> params` ; getters `int get percent`, `damagePerPoint`, `explosionDamage`, `chargePerNeighbour`, `bonusPerPoint` ; `bool get lasts` (faux pour `explode` seul) ; `ChargeBreaksOn get moment` (`bearerTurn` pour `explode`, `threshold` sinon) ; `static const Map<RuptureKind, Set<String>> paramsOf` = `skipAction: {}`, `weakenDealt: {percent}`, `explode: {damagePerPoint, explosionDamage, chargePerNeighbour}`, `amplifyHits: {bonusPerPoint}` ;
  - `class ChargeData` : `id`, `nameFr`, `nameEn`, `brokenNameFr?`, `brokenNameEn?`, `descriptionFr`, `descriptionEn`, `heroDescriptionFr?`, `heroDescriptionEn?`, `threshold`, `bossThreshold?`, `heroThreshold?`, `thresholdGrowth`, `overcharge`, `decay`, `breaksOn`, `belowThresholdPercent?`, `rupture`, `heroRupture?` ; `factory ChargeData.fromJson(Map<String, dynamic>)` qui valide (A3) ; `Map<String, dynamic> toJson()` ; `int startThreshold(ChargeBearer)` (absent : `threshold`) ; `ChargeRupture ruptureFor(ChargeBearer)` (`heroRupture ?? rupture` pour `hero`) ; `String name(String locale)`, `String? brokenName(String locale)`, `String describe(String locale)` (la `description` remplie) ;
  - `class ChargeCatalog` : `const ChargeCatalog.empty()`, `factory ChargeCatalog.of(List<ChargeData>)`, `ChargeData? operator [](String id)`, `bool isCharge(String id)`, `Set<String> get ids`, `Iterable<ChargeData> get all`, `bool get isEmpty`.
- Produces, ailleurs : `GameDataRegistry.charges` (`ChargeCatalog`, défaut `const ChargeCatalog.empty()`) ; `final EntitySource<ChargeData> chargeSource = EntitySource('assets/data/charges/*.json', ChargeData.fromJson, inject: (c) => {'id': c[0]})` ; `final chargeCatalogProvider = Provider<ChargeCatalog>(…)` = `ref.watch(gameDataLoaderProvider).valueOrNull?.charges ?? const ChargeCatalog.empty()` ; `EntityCategory.charge` ; dans `test/unit/shipped_data.dart` : `ChargeCatalog shippedChargeCatalog()` (les fichiers de `assets/data/charges/` par leur `fromJson`, id injecté, comme `shippedRune`) et `Override shippedChargeOverride()` (`chargeCatalogProvider.overrideWithValue(shippedChargeCatalog())`).
- Le lecteur du catalogue arrive en Task 3 (la pose).

- [ ] **Step 1 : écrire `test/unit/charge_data_test.dart`** (20 tests + 1), sur une carte JSON de base au modèle de `freeze.json` modifiée par test ; chaque refus attend une `FormatException` dont le message contient la clé fautive :
  1. `une cle inconnue est refusee, nommee` — `"foo": 1` → message contient `foo` ;
  2. `un nom ou une description sans sa paire _fr / _en est refuse` — sans `name_en`, puis sans `description_fr` ;
  3. `un seuil inferieur a 1 est refuse` — `threshold`, `bossThreshold`, `heroThreshold` à 0, chacun ;
  4. `une montee ou un declin negatifs sont refuses` — `thresholdGrowth: -1`, `decay: -1` ;
  5. `une sorte de rupture inconnue est refusee` — `"kind": "stun"` ;
  6. `un parametre d une autre sorte est refuse` — `explode` avec `bonusPerPoint`, et `explode` sans `explosionDamage` ;
  7. `un parametre hors de ses bornes est refuse` — `percent` 0 et 101, `bonusPerPoint` 0, `damagePerPoint` −1 ;
  8. `belowThresholdPercent hors de [0, 100] est refuse` — −1 et 101 ;
  9. `belowThresholdPercent est exige pour explode et amplifyHits, refuse pour les autres` ;
  10. `une sorte et un moment incompatibles sont refuses` — `explode` + `breaksOn: threshold`, `skipAction` + `bearerTurn` ;
  11. `brokenName est exige pour une rupture qui dure, refuse pour explode` ;
  12. `heroDescription est exigee si et seulement si heroRupture` ;
  13. `un seuil de Feu de 2 est refuse, de 3 accepte` — la charge `burn` livrée à `threshold: 2` lève ; à 3, `fromJson` rend `threshold == 3` ;
  14. `les seuils du boss et du heros d un Feu suivent la meme regle` — `bossThreshold: 2`, `heroThreshold: 2` lèvent chacun ;
  15. `skipAction est refuse comme rupture du heros` — `rupture: skipAction` sans `heroRupture` lève ; avec `heroRupture: weakenDealt`, accepté ;
  16. `un jeton inconnu est refuse` — `"{damage}"` dans `description_fr` lève, message contient `damage` ;
  17. `le seuil de depart par porteur` — `freeze` : `startThreshold(enemy) == 3`, `(boss) == 6`, `(hero) == 5` ; sans `bossThreshold` ni `heroThreshold` : 3 partout ; `ruptureFor(hero).kind == weakenDealt`, `ruptureFor(enemy).kind == skipAction` ;
  18. `les jetons se remplissent, belowValue compris, la demie vers le haut` — `burn` livrée : `describe('fr')` contient `chaque tranche de 3 inflige 4 par point`, `12 dégâts et 1 Feu`, `le reste inflige 2 par point` ; `shock` livrée : `describe('en')` commence par `Each hit taken deals +1 per point` ; une `amplifyHits` à `bonusPerPoint: 3` donne `{belowValue}` = 2 (1,5 arrondi vers le haut, A15) ;
  19. `toJson puis fromJson rend la meme charge` — pour les trois fichiers livrés, `ChargeData.fromJson(c.toJson())` donne les mêmes champs, et `toJson()` égale le fichier (id compris) ;
  20. `ChargeCatalog : acces par id, ids, vide par defaut` — `ChargeCatalog.of([...])['burn']`, `ids == {burn, freeze, shock}`, `const ChargeCatalog.empty().isEmpty` ;
  21. **(Review Focus 1)** `chargeCatalogProvider rend le catalogue vide sans registre charge` — `final c = ProviderContainer(); addTearDown(c.dispose);` `c.read(chargeCatalogProvider).isEmpty` est vrai, sans exception.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/charge_data_test.dart` → échec de compilation (`charge_data.dart` absent).
- [ ] **Step 3 : écrire `charge_data.dart`** aux interfaces ci-dessus. Validation, dans cet ordre, chaque refus nommant la clé et la règle (spec A3, §3.1) : clés admises (celles de spec §3.1, `id` compris) ; paires `name`, `description` exigées ; `brokenName` exigée si `rupture` ou `heroRupture` dure, refusée sinon ; `heroDescription` exigée si et seulement si `heroRupture` ; seuils ≥ 1, `thresholdGrowth` ≥ 0, `decay` ≥ 0 ; `kind` connu, paramètres exactement ceux de `paramsOf[kind]`, bornes : `percent` 1 à 100, `bonusPerPoint` ≥ 1, ceux d'`explode` ≥ 0 ; `rupture.moment` et `heroRupture?.moment` égaux à `breaksOn` ; `belowThresholdPercent` exigé si une des deux ruptures est `explode` ou `amplifyHits`, refusé sinon, dans [0, 100] ; pour `explode`, chacun des trois seuils de départ > `2 × chargePerNeighbour` ; `ruptureFor(hero).kind != skipAction` ; jetons. Jetons admis (§6.1) : `name`, `threshold`, `bossThreshold`, `heroThreshold`, `growth`, `decay`, les paramètres de la rupture du texte (`rupture` pour `description`, `heroRupture` pour `heroDescription`), et `belowValue` quand `belowThresholdPercent` existe — `belowValue` = `(v × belowThresholdPercent + 50) ~/ 100`, `v` = `damagePerPoint` ou `bonusPerPoint` (A15). Les trois fichiers JSON : clés et valeurs de spec §3.1 mot pour mot, descriptions de spec §6.1 en `_fr` et `_en`.
- [ ] **Step 4 : brancher le chargeur.** `GameDataRegistry` : `this.charges = const ChargeCatalog.empty()`. `game_data_service.dart` : `chargeSource` à côté de `cardSources` ; dans `loadGameDataRegistry`, `ChargeCatalog.of(await loader.loadAll<ChargeData>([chargeSource]))`, passé au registre ; le commentaire « dix sources » devient « onze » ; `chargeCatalogProvider` à côté de `xpCurveProvider`, son commentaire dit pourquoi `valueOrNull`. Éditeur : `EntityCategory.charge` (commentaire « onze »), descripteur `label: 'Charge élémentaire'`, `directory: 'charges'`, `requiredKeys: {threshold, thresholdGrowth, overcharge, decay, breaksOn, rupture}`, `enumKeys: {breaksOn: ChargeBreaksOn, rupture.kind: RuptureKind, heroRupture.kind: RuptureKind}` lus sur les enums, `bilingualBases: ['name', 'description']` (les paires facultatives `brokenName` et `heroDescription` sont vérifiées par `fromJson`, comme celles des récompenses de niveau), `construct: ChargeData.fromJson`, `template` = le contenu de `burn.json` sans `id` ni prose — `threshold`, `thresholdGrowth`, `overcharge`, `decay`, `breaksOn`, `belowThresholdPercent`, `rupture` : comme tous les gabarits d'aujourd'hui, il ne porte pas la prose (elle vient des `bilingualBases`, et `compose` la retire du corps, `entity_draft.dart:56-63`), et le Feu est la seule charge livrée sans paire facultative (`brokenName`, `heroDescription`), écartées du gabarit à dessein comme celles des récompenses de niveau. Deux lecteurs exhaustifs de l'enum suivent : `EntityValidator._registryIdsOf` (`entity_validator.dart:687-712`, `switch` sans `default`, qui ne compilerait plus) gagne `case EntityCategory.charge: return r.charges.ids;` ; `kCategoryIcons` (`editor_style.dart:107-118`, lu par `editor_toolbar.dart:42` avec `!`) gagne `EntityCategory.charge: Icons.ac_unit`. Puis `dart run tool/sync_assets.dart` (ajoute `- assets/data/charges/`), `dart run tool/sync_assets.dart --check` → code 0.
- [ ] **Step 5 : les comptes et les tests de données.**
  - `entity_id_convention_test.dart:72-81` : 130 → **133**, titre et raison (`+ 3 charges`) ;
  - `real_bundle_load_test.dart` : titre `:25` 130 → 133 et `expect(countUnder('assets/data/charges/', 4), 3, reason: 'charges')` ; **test neuf** `le registre reel charge les trois charges aux valeurs de D84 a D86` — `registry.charges.ids == {freeze, burn, shock}` ; `freeze` : seuils 3 / 6 / 5, `thresholdGrowth` 1, `overcharge` faux, `decay` 1, `rupture.kind` `skipAction`, `heroRupture` `weakenDealt` 50 ; `burn` : 3, 0, vrai, 0, `explode` (4, 12, 1), `belowThresholdPercent` 50 ; `shock` : 3, 0, vrai, 1, `amplifyHits` 2, 50 (A18) ; les autres comptes ne changent pas ;
  - `game_data_loader_injection_test.dart` : **test neuf** `charges/<id>.json injecte l id` — un `FakeBundle` à `assets/data/charges/freeze.json` sans `id`, `loader.loadAll<ChargeData>([chargeSource])` rend `id == 'freeze'` ;
  - `entity_descriptor_test.dart:20` et `:39` : 10 → **11**, commentaires à jour ; la table du test `chaque gabarit porte exactement les cles attendues` (`:302-411`) gagne `EntityCategory.charge: {threshold, thresholdGrowth, overcharge, decay, breaksOn, belowThresholdPercent, rupture}`, et sa raison (`:402`) passe à « onze categories » ;
  - `shipped_entities_round_trip_test.dart` gagne de lui-même un test (`Charge élémentaire : chaque fichier livre se modifie a l identique`), qui doit passer.
- [ ] **Step 6 : la doc du dépôt** (spec §3.3). `CLAUDE.md:43` : `charge_data.dart` rejoint la liste des modèles ; l'arbre (`:78-79`) : `charges/` parmi les catalogues plats (« likewise relics/, events/, forge_upgrades/, passives/, level_up_rewards/, charges/ ») ; `:85` : « … forge upgrade, level-up reward or elemental charge ». `README.md:69-71` : `charges/` dans la ligne « idem pour ».
- [ ] **Step 7 : vérifier.** `flutter test test/unit/charge_data_test.dart test/unit/real_bundle_load_test.dart test/unit/game_data_loader_injection_test.dart test/unit/entity_id_convention_test.dart test/unit/content_editor/` et `flutter test test/widget/content_editor_screen_test.dart` (ses 27 `testWidgets` lisent `kCategoryIcons` par la barre d'outils) → `All tests passed!` ; `dart analyze` → `No issues found!` ; `flutter test` → **1706** (1682 + 21 + 1 + 1 + 1), tout vert.
- [ ] **Step 8 : commit.** `git add` par chemin des fichiers ci-dessus ; `git commit -m "feat(p53): le cadre des charges en donnee, trois fichiers et leur validation" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`.

### Task 2: Les dix contenus relus

**Files :**
- Modify : `assets/data/cards/fireball.json:6` ; `cards/thunder_clap.json:6` ; `cards/mana_flux/kindle.json:5-6`, `:16` ; `cards/mana_flux/spark_barrage.json:6` ; `forge_upgrades/burning.json:6` ; `forge_upgrades/shocking.json:6` ; `forge_upgrades/freezing.json:18` ; `classes/mage/skills/magic_missile.json:61`
- Test : `test/unit/card_catalog_test.dart:84-87` ; `test/unit/forge_upgrades_catalog_test.dart:116-121` ; `test/unit/forge_upgrade_data_test.dart:634-636` ; `test/unit/rune_resolution_test.dart:201-206`

**Interfaces :** aucune neuve. *Trait de Glace*, *Nova de givre*, *Congelant* gardent leurs textes ; aucun `statusId`, aucune `duration` ni `durationPerLevel` ne change (A1, A7). La tâche passe avant la pose : elle ne touche que la donnée, et les tests de la pose (Task 3) s'écrivent alors une fois, aux valeurs de P-b.

- [ ] **Step 1 : les tests.** `card_catalog_test.dart` : *Embrasement* `apply_status` **3** `burn` ; `forge_upgrades_catalog_test.dart` : `freezing` `_status('freeze')` (1 par niveau) ; `forge_upgrade_data_test.dart:634-636` : `Applique 3 Feu`, `Applique 1 Gel`, `Applique 2 Foudre` (P-a, P-b) ; `rune_resolution_test.dart:201-205` : titre `Congelant 1 pose 1 Gel : -25 %`, `[1]` et `ProportionalStatus.freeze.percentOn(enemy()) == 25` (le moteur d'avant ; la ligne `1/3` vient en Task 3) ; `Congelant, joue deux fois` (`:188-193`) garde une seule entrée. `flutter test` sur ces quatre fichiers → rouge.
- [ ] **Step 2 : les fichiers**, aux valeurs de spec §3.4 et aux textes de spec §6.1 : *Embrasement* `value` 4 → **3**, `description_fr` « Applique 3 Feu. », `description_en` « Apply 3 Burn. » ; *Congelant* `valuePerLevel` 2 → **1** ; `description_fr` de *Boule de Feu*, *Coup de Tonnerre*, *Rafale d'étincelles*, *Brûlant*, *Surchargé*, *Braise* : « Brûlure » → « Feu », « Électrocution » → « Foudre », mot pour mot comme la table de §6.1 ; leurs `description_en` ne changent pas.
- [ ] **Step 3 : vérifier.** `git grep -n "Brûlure\|Électrocution" -- assets ':!assets/data/patch_notes.json'` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1706**, sans test neuf.
- [ ] **Step 4 : commit.** `feat(p53): les dix contenus relus, Embrasement 3 Feu et Congelant 1 Gel`.

### Task 3: La pose et la piste — `ChargeTrack`, `ChargeRules.pose`, le tic qui épargne les charges

**Files :**
- Create : `lib/models/charge_track.dart` ; `lib/game/systems/charge_rules.dart` ; `test/unit/charge_rules_test.dart`
- Modify : `lib/models/entity_stats.dart:7-77`, `:144-162` ; `lib/game/services/effect_resolver.dart:24-115` ; `lib/game/services/effects/strategies.dart:221-267` ; `lib/game/controllers/run_controller.dart:333-336`, `:564-579`, `:609-612` ; `lib/game/controllers/run/map_progression_manager.dart:37` ; `lib/game/controllers/combat/status_effect_processor.dart:12-15`, `:61`, `:83`, `:133` ; `lib/game/controllers/combat/turn_phase_manager.dart:67` ; `lib/game/controllers/combat_controller.dart:352-360`
- Test : `test/unit/charge_rules_test.dart` ; `test/unit/effect_resolver_test.dart:83`, `:86`, `:320-430` ; `test/unit/status_source_test.dart:118`, `:160`, `:196` ; `test/unit/stat_gains_characterization_test.dart:146`, `:161`, `:288`, `:328` ; `test/unit/mana_regen_test.dart:38`, `:51` ; `test/unit/stat_rule_conversion_test.dart:143` ; `test/unit/rune_resolution_test.dart:44-61`, `:165-212` ; `test/unit/multi_hit_test.dart:200` ; `test/unit/might_orientation_test.dart:132`, `:240-251` ; `test/unit/referential_integrity_test.dart:198-217`, `:265-294`, `:346-361`

**Interfaces :**
- Consumes : `ChargeData`, `ChargeCatalog`, `ChargeBearer`, `ChargeRupture`, `RuptureKind` (Task 1) ; `chargeCatalogProvider`, `shippedChargeOverride()`, `shippedChargeCatalog()`.
- Produces :
  - `enum ChargeState { none, brokenPending, brokenActive }` ; `@immutable class ChargeTrack` : `final int threshold`, `final int ruptures`, `final ChargeState state`, `final ChargeRupture rupture` ; `factory ChargeTrack.start(ChargeData charge, ChargeBearer bearer)` (seuil de départ du porteur, 0 rupture, `none`, `charge.ruptureFor(bearer)`) ; `copyWith` ; `==` / `hashCode` ;
  - `EntityStats` : `final Map<String, ChargeTrack> charges` (constructeur `Map<String, ChargeTrack> charges = const {}`, stocké `Map.unmodifiable`), `copyWith({…, Map<String, ChargeTrack>? charges})` ; **ni `toJson` ni `fromJson` ne la lisent** ; `EntityStats clearCombatEffects()` = statuts et pistes vides ; `EntityStats tickStatuses(Set<String> chargeIds)` ;
  - `abstract final class ChargeRules` : `static int points(EntityStats stats, String chargeId)` (somme des entrées de l'id) ; `static ChargeBearer bearerOf(EnemyInstance enemy)` (`isBoss` → `boss`, sinon `enemy`) ; `static int halfUp(int value, int percent)` = `(value × percent + 50) ~/ 100` (A15) ; `static EntityStats pose(EntityStats stats, ChargeData charge, int points, ChargeBearer bearer)` ; `static List<ChargeLine> linesFor(EntityStats stats)` ;
  - `@immutable class ChargeLine` (dans `charge_rules.dart`) : `chargeId`, `points`, `threshold`, `state`, `kind`, `value` ; `==` / `hashCode` ;
  - `RunController.updateHeroStats(EntityStats Function(EntityStats) update)` ;
  - `StatusEffectProcessor.processPlayerStatuses(EntityStats stats, List<StatRule> rules, ChargeCatalog charges)` et `processEnemyStatuses(EntityStats stats, ChargeCatalog charges)` — ils ne font que passer `charges.ids` au tic dans cette tâche.

- [ ] **Step 1 : écrire `test/unit/charge_rules_test.dart`**, groupe « la pose » puis « les lignes », sur `shippedChargeCatalog()` et un `EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0)` :
  1. `sans surcharge, la pose est plafonnee au restant` — (a) Gel livré, 2 puis 2 sur un ennemi : gelé (`brokenPending`), Gel à 0, `ruptures == 1`, `threshold == 4`, rien de reporté ; (b) le plafond lui-même, sur une charge construite dans le test (comme A18) par `ChargeData.fromJson`, qui doit passer A3 — `id`, `name_fr`/`name_en`, `description_fr`/`description_en`, `brokenName_fr`/`brokenName_en` (rupture qui dure), `threshold: 3`, `thresholdGrowth: 0`, `overcharge: false`, `decay: 0`, `breaksOn: threshold`, `belowThresholdPercent: 50` (exigé pour `amplifyHits`), `rupture: {kind: amplifyHits, bonusPerPoint: 2}` : 2 puis 2 → `points == 3`, et une pose de plus n'ajoute rien ;
  2. `Gel : rupture a 3, Gel a 0, seuil a 4 puis 5` — 3 points : `points == 0`, piste `brokenPending`, `ruptures == 1`, `threshold == 4` ; consommée à la main (`state: none`), 4 points : `threshold == 5` ;
  3. `Gel : rien ne se pose sur un porteur gele` — gelé, `pose(…, 2, enemy)` rend la même instance (`same(stats)`) : `EntityStats` n'a pas de `==` ;
  4. `Gel : un boss a 6, le heros a 5` — 5 sur un `boss` : pas de rupture, `threshold == 6` ; 5 sur le `hero` : rupture, piste `weakenDealt` `brokenPending` ;
  5. `Foudre : chargee a 3, la surcharge libre` — 2 puis 1 : `brokenActive`, `points == 3` ; 2 de plus : `points == 5`, toujours `brokenActive`, `ruptures == 1` ;
  6. `Feu : surcharge libre, aucune rupture a la pose` — 9 points : `points == 9`, `state == none`, `ruptures == 0` ;
  7. `les points sont la somme des entrees de meme id` — deux entrées `shock` de sources différentes, 1 et 1 : `ChargeRules.points == 2` ; après une pose de 1, une seule entrée, valeur 3 ;
  8. `la forme de l entree : debuff, duree 1, retiree a 0` — après pose : une entrée `id` du catalogue, `type == debuff`, `duration == 1`, `name == nameFr` ; après la rupture du Gel, aucune entrée `freeze` ;
  9. `le tic laisse une charge intacte` — `tickStatuses({'burn'})` sur 4 Feu : `(value, duration) == (4, 1)` ; une entrée `poison` à durée 1 disparaît ;
  10. `la rupture en vigueur est copiee sur la piste` — Gel posé sur le héros : `track.rupture.kind == weakenDealt`, `percent == 50` ; sur un ennemi : `skipAction` ;
  11. **(Review Focus 2)** `la piste survit a takeDamage, addStatus, tickStatuses et copyWith ; toJson ne l ecrit pas` — après chacun, `charges` égale la piste d'avant ; `toJson()` n'a pas de clé `charges` ; `EntityStats.fromJson(stats.toJson()).charges` est vide ;
  12. `clearCombatEffects vide les statuts et les pistes` ;
  13. `une ligne par charge : points, seuil, etat et valeur` — Gel 2 sur un ennemi : `ChargeLine(freeze, 2, 3, none, skipAction, 0)` ; Foudre chargée à 4 : `(shock, 4, 3, brokenActive, amplifyHits, 8)` ; héros gelé : `(freeze, 0, 6, brokenPending, weakenDealt, 50)` ;
  14. `un ennemi gele a 0 point a sa ligne ; une charge a 0 non rompue n en a pas` ;
  15. `deux lignes egales sont egales` — deux `ChargeLine` aux mêmes champs : `==` et `hashCode` égaux ; un champ différent : inégales.
- [ ] **Step 2 : le test de la Puissance et du plafond.** Dans `effect_resolver_test.dart`, groupe Q11 (`:320-430`), **test neuf** `la Puissance s ajoute avant le plafond du Gel` — le Mage (Puissance 2) joue *Trait de Glace* : 2 + 2 = 4, plafonné à 3, l'ennemi est gelé (`skipAction` `brokenPending`, Gel 0, `ruptures == 1`).
- [ ] **Step 3 : faire rougir.** `flutter test test/unit/charge_rules_test.dart test/unit/effect_resolver_test.dart` → échec de compilation.
- [ ] **Step 4 : écrire `charge_track.dart`, `EntityStats`, `ChargeRules`.** `pose`, dans l'ordre de spec §4.2 : (1) piste lue, ou `ChargeTrack.start` ; (2) `overcharge` faux et état autre que `none` → stats inchangées ; (3) posé = tout, ou `min(points, seuil − points actuels)` sans surcharge ; posé ≤ 0 → stats inchangées ; (4) les entrées de l'id remplacées par une seule, à la somme ; (5) `breaksOn: threshold`, état `none`, somme ≥ seuil → rupture : `ruptures + 1`, `threshold + thresholdGrowth`, état `brokenPending` pour `skipAction` et `weakenDealt` (points à 0, entrée retirée), `brokenActive` pour `amplifyHits` (points gardés) ; (6) piste écrite. `linesFor` : une ligne par piste dont les points > 0 ou l'état ≠ `none`, `threshold` lu sur la piste, `value` selon « Décisions du plan ». `tickStatuses(chargeIds)` : les entrées dont l'id est dans `chargeIds` passent intactes, filtre `duration > 0` compris ; les deux exceptions en dur (`entity_stats.dart:147-158`) disparaissent (A6). `clearCombatEffects` remplace `run_controller.dart:568-569` (`statuses: []`) et `map_progression_manager.dart:37` (`heroStats.clearCombatEffects().copyWith(armure: 0)`).
- [ ] **Step 5 : aiguiller la pose et retirer les cas.** `createStatus` perd `burn`, `freeze`, `shock` (`effect_resolver.dart:88-111`). `ApplyStatusEffectStrategy.resolve` lit `runController.ref.read(chargeCatalogProvider)` ; un `statusId` du catalogue va à `ChargeRules.pose(…, scaledValue, …)` — `singleEnemy` : la cible, `ChargeRules.bearerOf(enemy)` ; `allEnemies` : chacun avec son porteur ; `self` : `runController.updateHeroStats((s) => ChargeRules.pose(s, charge, scaledValue, ChargeBearer.hero))` ; la durée de l'effet n'est pas lue (A7). Tout autre id : `createStatus` puis `addStatus` comme aujourd'hui. `RunController.updateHeroStats` écrit `state.copyWith(heroStats: update(state.heroStats))`. Les processeurs reçoivent le catalogue et passent `charges.ids` à `tickStatuses` ; leurs appelants : `run_controller.dart:609` (`ref.read(chargeCatalogProvider)`), `turn_phase_manager.dart:67` (`ref.read(chargeCatalogProvider)`). `CombatController.tickEnemyStatuses` (`combat_controller.dart:352-360`), sans appelant dans `lib/`, disparaît (A6).
- [ ] **Step 6 : les tests existants.**
  - `tickStatuses(…)` reçoit `const {}` : `effect_resolver_test.dart:83`, `:86` ; `status_source_test.dart:118`, `:160`, `:196` ;
  - les processeurs reçoivent `const ChargeCatalog.empty()` : `stat_gains_characterization_test.dart:146`, `:161`, `:288`, `:328` ; `mana_regen_test.dart:38`, `:51` ; `stat_rule_conversion_test.dart:143` — valeurs inchangées ;
  - **surcharge `shippedChargeOverride()`** des conteneurs de `rune_resolution_test.dart:45`, `multi_hit_test.dart:200`, `might_orientation_test.dart:132`, `effect_resolver_test.dart:329` (Review Focus 1) ;
  - `effect_resolver_test.dart` Q11 : *Boule de Feu* + *Brûlant* `(5, durée 1)` ; *Coup de Tonnerre* + *Brûlant* : 3 Feu, 1 Foudre ; *Braise* : 1 + 2 — valeurs de points inchangées ;
  - `rune_resolution_test.dart:165-212` : *Brûlant 2* deux fois `[(4, 1, null)]` ; *Boule de Feu* + *Brûlant 1* `[(3, 1)]` ; *Trait de Glace* : titre `Trait de Glace pose 2 Gel : 2/3, non gele`, `[2]` et `ChargeRules.linesFor(enemy()).single` à `(points 2, threshold 3, state none)` au lieu du pourcentage ; *Congelant 1* : `[1]` et la ligne `(points 1, threshold 3, state none)` au lieu du pourcentage ; *Congelant* joué deux fois : une entrée de 2 ; *Coup de Tonnerre* + *Surchargé* garde 5, 7, 9 et `(6, null)` jusqu'à Task 4 ;
  - `might_orientation_test.dart:240-251` : `(1 + 3, durée 1)`, inchangé ;
  - `referential_integrity_test.dart` : les trois tests (`:198-217`, `:265-294`, `:346-361`) passent à la règle « créé par `createStatus` ou charge du catalogue » (`registry.charges.isCharge(id)`), titres compris (« … est cree par createStatus ou est une charge du catalogue ») ; **test neuf** `chaque charge du catalogue a son entree status:<id> dans effect_icons.json` — pour chaque id de `registry.charges`, `registry.effectIcons.entryOf('status:$id')` non nul ; la liste des faces (`:303-314`) garde `burn`, `freeze`, `shock`. L'import de `proportional_status.dart` quitte `rune_resolution_test.dart` s'il n'y a plus de lecteur.
- [ ] **Step 7 : vérifier.** `flutter test test/unit/charge_rules_test.dart test/unit/effect_resolver_test.dart test/unit/rune_resolution_test.dart test/unit/referential_integrity_test.dart` → vert ; `dart analyze` → `No issues found!` ; `flutter test` → **1723** (1706 + 15 + 1 + 1).
- [ ] **Step 8 : commit.** `feat(p53): la pose des charges et leur piste, le tic les epargne`.

### Task 4: Le pipeline — le héros gelé et la Foudre

**Files :**
- Modify : `lib/game/services/damage_pipeline.dart:10-66` ; `lib/game/services/effects/strategies.dart:91-114` ; `lib/game/controllers/combat/turn_phase_manager.dart:108-112` ; `lib/tutorial/tutorial_engine.dart:410-414` ; `lib/game/systems/charge_rules.dart`
- Test : `test/unit/damage_pipeline_test.dart:17`, `:30`, `:52` et tests neufs ; `test/unit/multi_hit_test.dart` ; `test/unit/rune_resolution_test.dart:165-176`, `:369-390` ; `test/unit/combat_controller_test.dart:553-750`

**Interfaces :**
- Consumes : `ChargeRules.points`, `halfUp`, `pose` ; `ChargeTrack` (Task 3).
- Produces : `DamagePipeline.calculate({required int initialDamage, required EntityStats attackerStats, required EntityStats defenderStats, required ChargeCatalog charges, bool canCrit = true, int critChanceBonus = 0})` ; `ChargeRules.weakenPercent(EntityStats attacker)` → le `percent` de la piste `weakenDealt` `brokenActive`, 0 sinon ; `ChargeRules.hitBonus(EntityStats defender, ChargeCatalog charges)` → pour chaque charge dont la rupture en vigueur (celle de la piste, à défaut `charge.rupture`) est `amplifyHits` : `points × bonusPerPoint` si la piste est `brokenActive`, sinon `halfUp(points × bonusPerPoint, belowThresholdPercent)`.

- [ ] **Step 1 : les tests du pipeline**, dans `damage_pipeline_test.dart` (les trois appels existants reçoivent `charges: shippedChargeCatalog()`, valeurs inchangées) :
  1. `Foudre sous le seuil : +1 par point, apres le critique` — défenseur à 2 Foudre (posées par `ChargeRules.pose`), attaquant à 100 % de critique (`critChanceBonus: 100`) : 10 → 15 → **17** ;
  2. `Foudre chargee : +2 par point, que Vulnerable amplifie` — défenseur chargé à 3 Foudre et 2 Vulnérable, `canCrit: false` : (10 + 6) × 1,5 = **24** ;
  3. `gele et Faiblesse : 8 puis 6 puis 3` — attaquant 1 Faiblesse et piste `freeze` `weakenDealt` `brokenActive` : 8 → **3** (37,5 %, D84) ;
  4. `une rupture en attente ne reduit rien` — même attaquant, piste `brokenPending`, sans Faiblesse : 10 → **10**.
- [ ] **Step 2 : les tests de contenu**, catalogue surchargé (Task 3) :
  - `rune_resolution_test.dart:165-176` réécrit : titre `Coup de Tonnerre et Surcharge, trois fois : 5, 10 puis 14 degats` ; `hp == [95, 85, 71]` ; Foudre `[(6, null)]` (D86 : la deuxième pose de la rune amène la Foudre à 3, la cible est chargée) ;
  - **test neuf** `rune_resolution_test.dart`, groupe de l'éclaboussure : `le heros gele inflige -50 % a l eclaboussure de Ricochant aussi` — héros à piste `weakenDealt` `brokenActive`, trois ennemis, `strike_basic` + `splash:1` sur le premier : PV `[97, 99, 99]` au lieu de `[94, 98, 98]` — la part d'éclaboussure (2, calculée avant le pipeline) passe le pipeline avec le héros pour attaquant ;
  - **test neuf** `multi_hit_test.dart` : `Rafale d etincelles : 12 sur un ennemi neuf, 27 sur un ennemi a 2 points` — `playShipped('spark_barrage')` : `100 - 12` ; sur un ennemi à 2 Foudre posées par la règle : `100 - 27`, puis piste `brokenActive` ;
  - `multi_hit_test.dart` `l Electrocution compte a chaque coup` (`:264`) : 15, inchangé ; les deux *Rafale* existantes : 88, 97, 97 et 93, inchangés ; `rune_resolution_test.dart:369-390` : 94, 94, 98, inchangés.
- [ ] **Step 3 : faire rougir.** `flutter test test/unit/damage_pipeline_test.dart test/unit/multi_hit_test.dart test/unit/rune_resolution_test.dart` → échecs.
- [ ] **Step 4 : implémenter.** Étapes de spec §4.9 : 1 — Faiblesse, inchangée ; **1 bis** — `weakenPercent(attackerStats)` > 0 : `(total × (100 − p) / 100).round()`, l'arrondi de l'étape 1 ; 2 — critique, inchangé ; **3** — `total += ChargeRules.hitBonus(defenderStats, charges)`, à la place du `firstWhere('shock')` (`:37-50`) ; 4 — Vulnérable, inchangé. Les trois appelants passent le catalogue : `strategies.dart:98` (lu une fois dans `resolve` par `runController.ref.read(chargeCatalogProvider)`, passé à `_strike`), `turn_phase_manager.dart:108` (`ref.read(chargeCatalogProvider)`), `tutorial_engine.dart:410` (`data.charges`).
- [ ] **Step 5 : le test « Burn, Freeze, and Shock » survit jusqu'à Task 5.** `combat_controller_test.dart:553-750` : son conteneur reçoit `overrides: [shippedChargeOverride()]` — sa Foudre de 4 posée à la main, sans piste, vaut +4 sous le seuil (10 dégâts), ses autres valeurs ne changent pas.
- [ ] **Step 6 : vérifier.** `dart analyze` → `No issues found!` ; `flutter test` → **1729** (1723 + 4 + 2).
- [ ] **Step 7 : commit.** `feat(p53): le pipeline lit les charges, heros gele et Foudre`.

### Task 5: Le Feu, sa chaîne et l'ordre du tour

**Files :**
- Create : `lib/models/fire_wave_report.dart` ; `test/unit/enemy_phase_helper.dart`
- Modify : `lib/models/combat_state.dart` ; `lib/game/systems/charge_rules.dart` ; `lib/game/controllers/combat/status_effect_processor.dart:12-134` ; `lib/game/controllers/combat/turn_phase_manager.dart:59-92` ; `lib/game/controllers/combat_controller.dart:342-350`
- Test : `test/unit/charge_rules_test.dart` ; `test/unit/combat_controller_test.dart:223-308`, `:546`, `:553-750` ; `test/encounter_system_test.dart:372`, `:401`, `:415` ; `test/unit/xp_scaling_test.dart:231`

**Interfaces :**
- Consumes : `ChargeRules.pose`, `points`, `halfUp`, `bearerOf` (Task 3).
- Produces :
  - `fire_wave_report.dart` : `@immutable class FireSplash { final String targetId; final int damage; final int charge; }` ; `FireResolution { final String bearerId; final String chargeId; final int tranches; final int damage; final List<FireSplash> splashes; }` ; `FireWaveReport { final int wave; final List<FireResolution> resolved; final Set<String> nextBearerIds; }` ;
  - `CombatState.fireWaveReport` (`FireWaveReport?`), `copyWith({…, FireWaveReport? fireWaveReport, bool clearFireWaveReport = false})` ; **ni `toJson` ni `fromJson`** (spec §8) ;
  - `ChargeRules` : `static (int tranches, int selfDamage) explosion(int points, int threshold, ChargeRupture rupture, int belowThresholdPercent)` ; `static (List<EnemyInstance>, FireWaveReport?) fireWave(List<EnemyInstance> row, {required Set<String>? bearerIds, required int wave, required ChargeCatalog charges})` ; `static EntityStats resolveOwnFire(EntityStats stats, ChargeCatalog charges)` ; `static EntityStats decay(EntityStats stats, ChargeCatalog charges)` ; `static EntityStats closePhase(EntityStats stats, {required bool endsPlayerTurn})` ; `static EntityStats startBearerTurn(EntityStats stats)` ;
  - `CombatController` : `bool startEnemyTurn()`, `bool resolveNextFireWave()`, `void resolveEnemyStatuses()` (délèguent au gestionnaire) ;
  - `test/unit/enemy_phase_helper.dart` : `void runEnemyPhaseStart(CombatController combat)` = `startEnemyTurn()`, puis `resolveNextFireWave()` jusqu'à `false`, puis `resolveEnemyStatuses()`.

- [ ] **Step 1 : les tests purs**, `charge_rules_test.dart`, groupe « le Feu » — charges aux valeurs de l'exemple (4, 12, 3, 1) construites dans le test, pas lues dans les fichiers (A18) ; ennemis à 200 PV sauf mention :
  1. `5 points : 16 au porteur, 12 et 1 Feu a chaque voisin` ;
  2. `2 points : 4 au porteur, sans explosion` ;
  3. `un bout de rangee n a qu un voisin, un ennemi seul aucun` ;
  4. `le heros porteur : sa part seule` — `resolveOwnFire` sur 5 Feu : −16 PV, Feu 0 ;
  5. `l exemple de l etude : A 48, B 64, C 48, en trois vagues` — B à 9 Feu ; vague 1 rend `nextBearerIds == {A, C}`, vague 2 `{B}`, vague 3 `{}` ; PV perdus `[48, 64, 48]` ;
  6. `une vague est simultanee` — A et B à 3 Feu chacun, voisins : chacun prend 12 + 12, et la vague suivante a A et B, à 1 Feu chacun ;
  7. `un porteur que sa vague tue explose quand meme` — B à 9 Feu et 10 PV : ses voisins prennent 36 et 3 Feu ;
  8. `un mort pendant la chaine garde sa place et ne recoit plus rien` — C tué en vague 1 : en vague 2, l'explosion de B ne lui donne ni dégât ni Feu, et la rangée garde trois entrées ;
  9. `la chaine s arrete` — cinq ennemis à 9 Feu et 10 000 PV : `fireWave` répété rend `null` en un nombre fini de vagues (< 50), le Feu en jeu baissant strictement à chaque vague qui explose ;
  10. `l Armure absorbe le Feu ; ni Vulnerable ni critique` — porteur à 5 Armure et 2 Vulnérable, 3 Feu : 12 − 5 = 7 PV perdus (P-d) ;
  groupe « le déclin et les fermetures » :
  11. `declin : -1 sans rupture, jamais sous 0, aucun sur un porteur rompu` — Gel 2 → 1 ; Gel 0 → aucune entrée ; Gel rompu en attente : inchangé ; Feu (`decay: 0`) : inchangé ;
  12. `Foudre : retombe a 0 a la fermeture de phase, declin sous le seuil seulement` — chargée : `closePhase(endsPlayerTurn: false)` → points 0, `none` ; 2 points : `decay` → 1 ;
  13. **(Review Focus 4)** `le gel du heros en attente survit a la fermeture du tour du joueur` — `brokenPending` : `closePhase(endsPlayerTurn: true)` le garde ; `startBearerTurn` → `brokenActive` ; `closePhase(endsPlayerTurn: false)` le garde ; `closePhase(endsPlayerTurn: true)` → `none`.
- [ ] **Step 2 : les tests du contrôleur.** `combat_controller_test.dart` : le test « Burn, Freeze, and Shock » (`:553-750`) disparaît ; à sa place, groupe `Les charges au tour ennemi`, conteneurs à `shippedChargeOverride()`, charges posées par `ChargeRules.pose` :
  1. `le Feu se resout avant le Poison` — 3 Feu et 3 Poison, 20 PV : après `startEnemyTurn()`, 8 PV et Poison intact ; puis `resolveNextFireWave()` jusqu'à `false` et `resolveEnemyStatuses()` : 5 PV ;
  2. `les vagues une a une` — trois ennemis A, B, C à 200 PV, B à 9 Feu : `startEnemyTurn()` rend `true`, `fireWaveReport.wave == 1` ; `resolveNextFireWave()` `true` deux fois (vagues 2 et 3) puis `false`, `fireWaveReport` nul ; le compte rendu de la vague 1 porte B, 3 tranches, 36, et pour A et C 36 et 3 ;
  3. `cleanDeadEnemies apres les statuts, la rangee se resserre` — un voisin tué en vague 1 reste dans `enemies` jusqu'à `resolveEnemyStatuses()`, puis passe à `defeatedEnemies` ;
  4. **(Review Focus 3)** `un porteur que son Poison acheve a son tour explose quand meme` — B à 3 Feu, 15 Poison et 20 PV, entre A et C à 200 PV : après `startEnemyTurn()`, A et C ont perdu 12 et portent 1 Feu, B est vivant ; après `resolveNextFireWave()` jusqu'à `false` puis `resolveEnemyStatuses()`, A et C ont perdu 14 en tout (leur point de Feu, sous le seuil, fait `halfUp(1 × 4, 50) = 2` à la vague 2) et ne portent plus de Feu, et B est mort, sorti au `cleanDeadEnemies` final ;
  5. `un ennemi tue par une carte perd son Feu sans exploser` — 3 Feu, tué par une *Frappe* (`applyPlayerCardPlay`) : au `startEnemyTurn()` qui suit, aucun voisin ne prend de dégât, `startEnemyTurn()` rend `false` ;
  6. `les deux fermetures de phase` — Foudre chargée sur un ennemi : 0 après `startEnemyTurn()` ; rechargée pendant la phase, 0 après `endEnemyTurn()` ; idem sur le héros ;
  7. `le Feu d une explosion ne recoit aucun bonus de Puissance` — héros à `mightTargets: {alteration}` et 2 de Puissance ; une carte de test `apply_status burn 3` sur B pose 3 + 2 = 5 (une tranche) ; A et C reçoivent exactement 1 Feu chacun, non 3. (Une carte de test, et non *Embrasement*, pour que le test ne dépende pas d'une valeur du propriétaire, A18.)
- [ ] **Step 3 : le helper et l'ancien contrat** (A12) — `combat_controller_test.dart:289` et `:546`, `encounter_system_test.dart:372`, `:401`, `:415` (import `unit/enemy_phase_helper.dart`), `xp_scaling_test.dart:231` : `combatController.startEnemyTurn()` → `runEnemyPhaseStart(combatController)` ; valeurs attendues inchangées (17 PV, durée 1, …). `combat_signature_test.dart:93` et `:202` restent sur `startEnemyTurn()`.
- [ ] **Step 4 : faire rougir.** `flutter test test/unit/charge_rules_test.dart test/unit/combat_controller_test.dart` → échecs.
- [ ] **Step 5 : implémenter la vague** — l'algorithme que la spec impose (§4.7, A11), `fireWave` :
  1. Les charges du catalogue dont la rupture est `explode` ; les porteurs : ennemis de `row` vivants (PV > 0), dans `bearerIds` s'il n'est pas nul, portant > 0 point de l'une d'elles. Aucun → `(row, null)`.
  2. Pour chaque porteur et chaque telle charge, sur l'état **du début de la vague** : seuil = celui de la piste (à défaut `startThreshold(bearerOf)`) ; `explosion` donne `n = p ~/ T` et `n × T × damagePerPoint + halfUp(r × damagePerPoint, belowThresholdPercent)` ; l'entrée de la charge est retirée ; si `n ≥ 1`, la piste compte une rupture ; chaque voisin (index ± 1 dans `row`) vivant au début de la vague est noté pour `n × explosionDamage` et `n × chargePerNeighbour`.
  3. Tous les dégâts s'appliquent par `EntityStats.takeDamage` — l'Armure absorbe, hors pipeline (P-d) —, dans l'ordre de la rangée.
  4. Le Feu des explosions se pose par `ChargeRules.pose`, sans bonus de Puissance, sur les seules cibles vivantes après l'étape 3 ; celles qui ont reçu au moins un point forment `nextBearerIds`.
  5. Le compte rendu de la vague `wave` est rendu avec la rangée.
  Les morts restent dans `row` ; aucune borne de boucle (la validation l'assure, A3).
- [ ] **Step 6 : implémenter le tour.** `resolveOwnFire` : même arithmétique, sans voisin. `decay` : pour chaque charge du catalogue à `decay > 0`, si l'état est `none` (ou sans piste), points − `decay`, plancher 0, entrée retirée à 0. `closePhase` : `amplifyHits` `brokenActive` → entrée retirée, `none` ; si `endsPlayerTurn`, `weakenDealt` `brokenActive` → `none`. `startBearerTurn` : `weakenDealt` `brokenPending` → `brokenActive`.
  - `processPlayerStatuses` (spec §4.10) : `resolveOwnFire` d'abord, puis Poison, Éveil, le tic, Métallisation, Source de Mana comme aujourd'hui, puis `decay`, puis `startBearerTurn`.
  - `processEnemyStatuses` : le bloc Brûlure disparaît (`:87`, `:96-98`, `:105-107`) ; Poison, Éveil, Métallisation, le tic, puis `decay`.
  - `TurnPhaseManager.startEnemyTurn()` → `bool` : phase `enemy` ; fermeture du tour du joueur (`closePhase(endsPlayerTurn: true)`) sur le héros par `runController.updateHeroStats` et sur chaque ennemi ; vague 1 (`bearerIds: null, wave: 1`) écrite dans l'état (ou `clearFireWaveReport`) ; rend vrai si une vague s'est jouée.
  - `resolveNextFireWave()` : compte rendu nul ou `nextBearerIds` vide → `clearFireWaveReport`, `false` ; sinon la vague `wave + 1` sur ces porteurs, `true`.
  - `resolveEnemyStatuses()` : `processEnemyStatuses` pour chaque ennemi, `clearFireWaveReport`, puis `cleanDeadEnemies()`, une fois.
  - `endEnemyTurn()` : fermeture de la phase ennemie (`endsPlayerTurn: false`) sur le héros et chaque ennemi, puis les intentions comme aujourd'hui (`:81-91`).
  - `game_screen.dart:371-375`, en attendant Task 7 : `onStartEnemyTurn` enchaîne `startEnemyTurn()`, `resolveNextFireWave()` jusqu'à `false`, puis `resolveEnemyStatuses()` — l'application garde toute sa phase ennemie, sans délai entre les vagues ; Task 7 remplace ce câblage.
- [ ] **Step 7 : vérifier.** `dart analyze` → `No issues found!` ; `flutter test` → **1748** (1729 + 13 + 7 − 1).
- [ ] **Step 8 : commit.** `feat(p53): le Feu explose vague par vague, ordre du tour et fermetures`.

### Task 6: Le Gel au contrôleur et la symétrie

**Files :**
- Create : `test/unit/charge_symmetry_test.dart`
- Modify : `lib/models/enemy_instance.dart:3`, `:17-39` ; `lib/game/controllers/combat/turn_phase_manager.dart:95-129` ; `lib/game/systems/charge_rules.dart`
- Test : `test/unit/combat_controller_test.dart` ; `test/unit/effect_resolver_test.dart:254-283`

**Interfaces :**
- Consumes : `ChargeTrack`, `ChargeState`, `RuptureKind` ; `runEnemyPhaseStart` ; `RunController.updateHeroStats`.
- Produces : `EnemyInstance.skippingCharge` (`String?` : l'id de la piste `skipAction` `brokenPending`, sans catalogue, A5) ; `bool get skipsAction => skippingCharge != null` ; `ChargeRules.consumeSkip(EntityStats stats)` (la piste `skipAction` `brokenPending` → `none`).

- [ ] **Step 1 : les tests du contrôleur**, `combat_controller_test.dart`, groupe de Task 5 :
  1. `l ennemi gele ne resout rien et consomme son gel` — 3 Gel, intention `attack 10` : `resolveEnemyIntent` laisse les PV du héros, `skipsAction` faux ensuite ; après `endEnemyTurn()`, `currentIntent` est l'intention suivante du cycle (`data.intents`) ;
  2. `ses statuts se resolvent quand meme` — gelé, 3 Poison et 3 Feu : `runEnemyPhaseStart` lui ôte 15 PV, puis `resolveEnemyIntent` ne fait rien ;
  3. **(Review Focus 5)** `un ennemi gele sans intention consomme son gel` — `currentIntent: null`, gelé : `resolveEnemyIntent` → `skipsAction` faux ;
  4. `un combat de boss : chaque ennemi a 6 ; une elite a 3` — `initializeCombat(…, MapNodeType.boss, …, act: 6)` : pour chaque ennemi (`isBoss` vrai), 2 Gel posés → ligne `threshold == 6` ; un combat `MapNodeType.elite` : 3.
- [ ] **Step 2 : `charge_symmetry_test.dart`** — registre livré chargé en `setUpAll` (`loadGameDataRegistry(rootBundle)`), conteneur à `shippedChargeOverride()`, le Paladin, un ennemi à 100 PV ; chaque charge posée par `ChargeRules.pose` via `run.updateHeroStats` ou `combat.updateEnemyStats` :
  1. `Gel : l ennemi gele perd son action` ;
  2. `Gel : le heros gele inflige -50 % pendant son prochain tour, chaque coup compte, et joue cartes et signatures` — 5 Gel sur le héros pendant son tour ; `runEnemyPhaseStart`, `endEnemyTurn`, `run.startTurn()` : une *Frappe* de 6 fait **3** ; une carte de test `damage 4, hits 2` fait 2 + 2 ; `playSignature` rend `true` et sa signature fait la moitié ; au tour d'après, la *Frappe* refait 6 (D84) ;
  3. `Gel du heros : les degats de ses statuts ne sont pas reduits` — héros gelé actif, ennemi à 3 Feu : 12 au début de la phase ennemie ;
  4. `Feu du heros : sa part au debut de son tour, sans explosion` — 5 Feu, deux ennemis : `run.startTurn()` ôte 16 au héros, rien aux ennemis ;
  5. `Foudre du heros : les coups ennemis lui font +1 par point` — 2 Foudre, ennemi à `might == data.baseDamage == 10` (l'intention vaut alors 10, `enemy_instance.dart:21-28`), intention `attack 10` : le héros perd 12 ;
  6. `Feu : un ennemi entre deux voisins explose` — trois ennemis à 100 PV, 3 Feu sur celui du milieu : après le seul `startEnemyTurn()` (la vague 1), le porteur a perdu 12 (une tranche), chaque voisin 12, et chaque voisin porte 1 Feu ; puis `resolveNextFireWave()` jusqu'à `false` et `resolveEnemyStatuses()` : chaque voisin a perdu 14 en tout (2 à la vague 2, sous le seuil) et ne porte plus de Feu ;
  7. `Foudre : un ennemi a 2 points prend +1 par point a chaque coup` — 2 Foudre sur l'ennemi : une *Frappe* de 6 lui ôte 8.
- [ ] **Step 3 : l'intention et le Gel.** `effect_resolver_test.dart:254-283` : le test `le Gel reduit l intention de 25 % par point, 3 points au plus` disparaît ; à sa place `un ennemi qui porte du Gel sous le seuil montre son intention entiere` — 2 Gel, intention 10 : `effectiveIntent.value == 10` (A14).
- [ ] **Step 4 : faire rougir.** `flutter test test/unit/charge_symmetry_test.dart test/unit/combat_controller_test.dart test/unit/effect_resolver_test.dart` → échecs.
- [ ] **Step 5 : implémenter.** `resolveEnemyIntent` : si `enemy.skipsAction`, `updateEnemy(enemy.copyWith(stats: ChargeRules.consumeSkip(enemy.stats)))` et rien d'autre, **avant** `intent == null` (A13) ; le Gel lu à l'attaque disparaît (`turn_phase_manager.dart:106`, `:116-128`). `EnemyInstance.effectiveIntent` perd le Gel (`:29-32`) et son import de service (`:3`).
- [ ] **Step 6 : vérifier.** `dart analyze` → `No issues found!` ; `git grep -n -E "(s|status)\.id [!=]= '(burn|freeze|shock)'" -- lib` → rien ; `flutter test` → **1759** (1748 + 4 + 7).
- [ ] **Step 7 : commit.** `feat(p53): le Gel ote son action a l ennemi, reduit les coups du heros`.

### Task 7: Flame — le catalogue, les vagues une à une, l'ennemi gelé, les indicateurs

**Files :**
- Modify : `lib/game/heros_draft_game.dart:58-123`, `:369-401` ; `lib/game/game_constants.dart:60-74` ; `lib/game/components/entities/enemy_card.dart:36`, `:139-151`, `:217-246`, `:326-333` ; `lib/game/components/entities/status_indicator.dart` ; `lib/game/systems/state_sync_system.dart:92-149` ; `lib/ui/screens/game_screen.dart:307-310`, `:366-379`
- Test : `test/unit/flame_image_prefix_test.dart:11-30` ; `test/unit/heros_draft_game_targeting_test.dart:59-81`

**Interfaces :**
- Consumes : `ChargeCatalog`, `ChargeLine`, `ChargeRules.linesFor`, `EnemyInstance.skipsAction`, `CombatState.fireWaveReport`, `CombatController.startEnemyTurn/resolveNextFireWave/resolveEnemyStatuses`.
- Produces : `HerosDraftGame({…, required ChargeCatalog chargeCatalog, required bool Function() onStartEnemyTurn, required bool Function() onResolveFireWave, required void Function() onResolveEnemyStatuses, …})` et `final ChargeCatalog chargeCatalog` ; `GameConstants.combatDelayFireWaveMs = 600` (spec §4.10) ; `EnemyCard.skipsAction`, `EnemyCard.flameAnimation()` ; `StatusIndicator({required List<StatusEffect> statuses, required List<ChargeLine> chargeLines, required String Function(String chargeId) brokenNameOf, super.position})`, `void updateStatuses(List<StatusEffect> statuses, List<ChargeLine> chargeLines)`.

- [ ] **Step 1 : les bouchons des tests.** `flame_image_prefix_test.dart` et `heros_draft_game_targeting_test.dart` : `chargeCatalog: const ChargeCatalog.empty()`, `onStartEnemyTurn: () => false`, `onResolveFireWave: () => false`, `onResolveEnemyStatuses: () {}` ; leurs assertions ne changent pas. `flutter test` sur ces deux fichiers → échec de compilation tant que le constructeur n'a pas changé.
- [ ] **Step 2 : `HerosDraftGame`.** `_enemyRipostePhase` (spec §4.10) : `onPhaseChanged`, délai d'ouverture ; `var wave = onStartEnemyTurn();` tant que `wave` : délai `combatDelayFireWaveMs`, `wave = onResolveFireWave()` ; `onResolveEnemyStatuses()` ; délai `combatDelayAfterTicksMs` ; la liste copiée comme aujourd'hui (`:377`) ; pour chaque ennemi, **avant** le test `intent == null` : `if (enemy.skipsAction)` → ni bond ni animation de renforcement, `onResolveEnemyIntent(enemy.id)`, délai `combatDelayAfterIntentResolveMs`, suivant (A13 ; aucune animation neuve, spec §5.2) ; sinon le déroulé d'aujourd'hui ; `onEndEnemyTurn()`.
- [ ] **Step 3 : les indicateurs de l'ennemi.** `EnemyCard` : un seul calcul des listes des deux indicateurs, appelé par `onLoad`, `updateStats` et `resolvePendingVisualStats` (les deux chemins, `:217-246`) — buffs : les `buff`, `chargeLines: const []` ; altérations : les `debuff` dont l'id n'est pas dans `game.chargeCatalog`, `chargeLines: ChargeRules.linesFor(stats)` ; `brokenNameOf: (id) => game.chargeCatalog[id]?.brokenName(activeLocale) ?? ''`. `StatusIndicator` : égalité sur les statuts **et** sur les lignes (`ChargeLine ==`) ; une icône par ligne, clé `charge:<id>`, l'émoji de `_getEmoji` (`:141-166`), **sans durée** ; texte : `explode` → `"$points"` ; état `none` → `"$points/$threshold"` ; `amplifyHits` `brokenActive` → `"$points"` en `Colors.yellowAccent`, sous-titré `brokenNameOf(id)` ; `skipAction` `brokenPending` → aucun chiffre, sous-titré `brokenNameOf(id)` (spec §5.1). `flameAnimation()` pose `EffectIcon(iconType: 'burn', …)` au-dessus de la carte, comme `buffAnimation` (`:326-333`).
- [ ] **Step 4 : le compte rendu.** `StateSyncSystem._applyCombatState` : un `fireWaveReport` non nul et différent du dernier vu → `flameAnimation()` sur la carte de chaque porteur résolu (`resolved[].bearerId`) ; les PV, eux, passent par les réactions aux coups d'aujourd'hui (`updateStats`).
- [ ] **Step 5 : `game_screen.dart`.** `chargeCatalog: ref.read(chargeCatalogProvider)` à côté d'`imagesToPreload` (`:307-310`) ; `onStartEnemyTurn: () => …startEnemyTurn()` (rend le booléen ; l'enchaînement provisoire de Task 5 disparaît), `onResolveFireWave: () => …resolveNextFireWave()`, `onResolveEnemyStatuses: () => …resolveEnemyStatuses()`.
- [ ] **Step 6 : vérifier.** `dart analyze` → `No issues found!` ; `flutter test` → **1759**, tout vert, sans test neuf (D77).
- [ ] **Step 7 : commit.** `feat(p53): Flame joue les vagues une a une, l ennemi gele ne fonce pas`.

### Task 8: Les textes des cartes et des signatures

**Files :**
- Modify : `lib/l10n/app_fr.arb:155-160`, `:301` ; `lib/l10n/app_en.arb:406-443`, `:905-910` ; `lib/l10n/app_localizations*.dart` (générés) ; `lib/ui/widgets/ui_card/ui_card_helpers.dart:251-265`, `:408-427`, `:432` ; `lib/game/components/card_component.dart:432-452`, `:459` ; `lib/game/services/card_rule_texts.dart:31-69` ; `lib/game/services/effect_line_texts.dart:11-31` ; `lib/ui/widgets/hud/signature_bar.dart:64-82`, `:244-256`, `:401-410`, `:810-825` ; `lib/ui/screens/game_screen.dart` (l'appel de `SignatureBar`)
- Test : `test/unit/effect_line_texts_test.dart:28`, `:59-61`, `:69-70`, `:76-83`, `:89`, `:96-98` ; `test/unit/card_rule_texts_test.dart:45-51`, `:91-95` ; `test/unit/referential_integrity_test.dart:233`

**Interfaces :**
- Consumes : `ChargeCatalog`, `ChargeData.name`, `ChargeData.describe` ; `chargeCatalogProvider` ; `HerosDraftGame.chargeCatalog`.
- Produces : clés `cardDescStatusCharge(amount, name)` et `effectLineCharge(amount, name)` (textes de spec §6.2) ; `CardRuleTexts.scale(AppLocalizations l10n, ScaleWith scale, ChargeCatalog charges)` ; `EffectLineTexts.phrase(AppLocalizations l10n, EffectLine line, ChargeCatalog charges)` ; `SignatureBar({…, ChargeCatalog charges = const ChargeCatalog.empty()})` jusqu'à `_EffectList`.

- [ ] **Step 1 : les tests.**
  - `effect_line_texts_test.dart` : chaque appel reçoit `shippedChargeCatalog()` ; `status:burn` (`:59-61`) : `('Applique 3 Feu', 'Apply 3 Burn')` ; `:82-83` : `Applique 1 Feu` ; le test `hors des treize sortes, aucune phrase` (`:96-98`) ne garde que `status:poison` ; **test neuf** `status:freeze et status:shock ont leur phrase, sans duree` — `Applique 2 Gel`, `Applique 2 Foudre`, `Apply 2 Freeze`, `Apply 2 Shock` ;
  - `card_rule_texts_test.dart` : chaque appel reçoit le catalogue, valeurs inchangées (`:91-95` nomme Vulnérable) ; **test neuf** `targetStatus sur une charge dit son nom, jamais l id` — `statusId: 'freeze'` : contient `Gel`, ne contient pas `freeze` ;
  - `referential_integrity_test.dart:233` : `EffectLineTexts.phrase(l10n, line, registry.charges)`.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/effect_line_texts_test.dart test/unit/card_rule_texts_test.dart` → échec de compilation.
- [ ] **Step 3 : l'ARB.** Ajouter `cardDescStatusCharge` et `effectLineCharge` dans les deux fichiers (métadonnées des paramètres en anglais) ; retirer `cardDescStatus{Burn,Freeze,Shock}[Duration]` et `effectLineBurn` (et leurs `@…`) ; `statusFreezeHint` reste jusqu'à Task 10. `flutter gen-l10n`.
- [ ] **Step 4 : les textes.** `EffectLineTexts.phrase` : une sorte `status:<id>` dont l'id est une charge → `effectLineCharge(amount, charge.name(l10n.localeName))`, avant le `switch` ; le cas `status:burn` disparaît (§6.2). `CardRuleTexts._statusName` : `charges[id]?.name(l10n.localeName)`, puis `createStatus(id, 0, 0)?.name`, puis l'id ; ses deux appelants passent le catalogue. Infobulles (A16, §5.1) : un `statusId` du catalogue → `cardDescStatusCharge(scaledValue, charge.name(locale))`, puis `  (${charge.describe(locale)})` ; les cas `burn`, `freeze`, `shock` et leurs phrases en dur disparaissent — Flutter (`ui_card_helpers.dart:408-427`) lit `ProviderScope.containerOf(context, listen: false).read(chargeCatalogProvider)` ; Flame (`card_component.dart:432-452`) lit `game.chargeCatalog`. `game_screen.dart` passe `charges: ref.watch(chargeCatalogProvider)` à `SignatureBar`, qui le transmet à `_SignatureTile` puis à `_EffectList` (`:825`).
- [ ] **Step 5 : vérifier.** `flutter test test/widget/` → vert, et nommément les six tests d'écran qui rendent des cartes, donc l'infobulle à chaque `build` : `event_screen_test.dart`, `forge_fusion_screen_test.dart`, `rest_card_selection_screen_test.dart`, `rest_screen_test.dart` — tous quatre sous `UncontrolledProviderScope` et `gameDataLoaderProvider` surchargé : le catalogue y est celui du registre fourni — et `deck_screen_test.dart`, sous `UncontrolledProviderScope` sans surcharge de `gameDataLoaderProvider` (`deck_screen_test.dart:43-50`) : lire le catalogue y déclenche le vrai chargement du registre, et l'infobulle lit le catalogue vide tant qu'il n'a pas abouti ; aucune de ses cartes ne pose de charge, ses assertions ne changent pas — et `sharpen_rune_dialog_test.dart`, configuré de même (`ProviderContainer()` sans surcharge, `:39-46`, la carte rendue par `forge_card_preview.dart:28`) : sa carte, `strike_basic`, ne pose aucune charge, ses assertions ne changent pas ; `git grep -n "cardDescStatus\(Burn\|Freeze\|Shock\)\|effectLineBurn" -- lib` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1761** (1759 + 2).
- [ ] **Step 6 : commit** (ARB et les trois `app_localizations*.dart` compris). `feat(p53): les infobulles et les lignes disent la charge, sans duree`.

### Task 9: Le HUD — le panneau du héros, le panneau des intentions

**Files :**
- Modify : `lib/l10n/app_fr.arb`, `app_en.arb`, `app_localizations*.dart` ; `lib/ui/widgets/hud/status_effects_panel.dart:7-211` ; `lib/ui/widgets/hud/enemy_intents_panel.dart:6-168` ; `lib/ui/widgets/hud/combat_side_panels.dart:13-17`, `:19-96` ; `lib/ui/screens/game_screen.dart:640-646`

**Interfaces :**
- Consumes : `ChargeLine`, `ChargeRules.linesFor`, `ChargeCatalog`, `EnemyInstance.skippingCharge`.
- Produces : clés `statusChargePoints(name, points, threshold)`, `statusChargeOpen(name, points)`, `statusChargeWeakenNext(state, percent)`, `statusChargeWeakenNow(state, percent)`, `statusChargeCharged(state, bonus)`, `intentSkipped(state)` (textes de spec §6.2) ; `StatusEffectsPanel({required List<StatusEffect> statuses, List<ChargeLine> chargeLines = const [], ChargeCatalog charges = const ChargeCatalog.empty(), EffectIconTable effectIcons = …, double? maxHeight})`, désormais `StatefulWidget` (son `ScrollController`) ; `EnemyIntentsPanel({required List<EnemyInstance> enemies, ChargeCatalog charges = const ChargeCatalog.empty()})` ; `CombatSidePanels({…, required List<ChargeLine> heroChargeLines, ChargeCatalog charges = const ChargeCatalog.empty(), …})`.

- [ ] **Step 1 : l'ARB.** Les six clés, fr et en, `flutter gen-l10n`.
- [ ] **Step 2 : le panneau du héros** (spec §5.1). Les statuts dont l'id est une charge ne s'y dessinent plus (cas `burn`, `freeze`, `shock` et leurs libellés en dur retirés, `:131-151`) ; une rangée par ligne, icône et couleur d'`effect_icons.json` (`status:<id>`) : `explode` → `statusChargeOpen` (« Feu : 5 ») ; état `none` → `statusChargePoints` (« Gel : 2/5 », « Foudre : 2/3 ») ; `weakenDealt` `brokenPending` → `statusChargeWeakenNext(brokenName, value)` ; `brokenActive` → `statusChargeWeakenNow` ; `amplifyHits` `brokenActive` → `statusChargeCharged(brokenName, value)` (« Chargé : +8 par coup »). **Décision Q1** : ces rangées n'ont pas de colonne de durée, et leur `Text` se replie (`softWrap: true`, sans `maxLines`, sans `TextOverflow.ellipsis`) : « Gelé : −50 % de dégâts au prochain tour » se lit en entier sur deux lignes, texte inchangé. Le message `noStatusActive` s'affiche si statuts **et** lignes sont vides. **Au-delà de la réserve** (Décisions, Q1) : le parent, `Positioned(bottom:, left:)` (`combat_side_panels.dart:81-88`), ne borne pas la hauteur ; avec `maxHeight` non nul, c'est le `Container` du panneau (`status_effects_panel.dart:24-41`) qui la borne, par `constraints: BoxConstraints(maxHeight: maxHeight!)` — titre et séparateur fixes, la liste dans un `Flexible` qui défile (`SingleChildScrollView` sous `Scrollbar(thumbVisibility: true)`) ; sans `maxHeight` (la démonstration du tutoriel, en hauteur non bornée), la colonne d'aujourd'hui, sans `Flexible`, qui lèverait « non-zero flex but incoming height constraints are unbounded ». `StatusEffectsPanel` devient un `StatefulWidget` qui crée son `ScrollController` et le libère dans `dispose`, et le passe au `Scrollbar` **et** au `SingleChildScrollView` : sans lui, `Scrollbar(thumbVisibility: true)` lève une `FlutterError` en debug sous Windows, où le `SingleChildScrollView` ne s'attache pas au `PrimaryScrollController` (plateformes mobiles seulement) — erreur qu'aucun test ne voit (`flutter test` simule Android ; D77). Le `SingleChildScrollView` est enveloppé dans `ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false), …)` : sous linux, macOS et Windows, `MaterialScrollBehavior.buildScrollbar` (`material/app.dart:855-860`) ajouterait sinon une seconde barre sur le même contrôleur — le remède que la doc du SDK donne (`widgets/scrollbar.dart:916-950`). Le texte et l'affichage ne changent pas.
- [ ] **Step 3 : le panneau des intentions.** Un ennemi à `skippingCharge` non nul : son intention en gris (`Colors.white38`), barrée (`TextDecoration.lineThrough`), puis la ligne `intentSkipped(charges[id]?.brokenName(locale) ?? '')` (« Gelé : ne fait rien ce tour ») ; l'intention n'est plus réduite (Task 6).
- [ ] **Step 4 : le câblage.** `CombatSidePanels` transmet le catalogue aux deux panneaux, les lignes et `maxHeight: statusPanelReserve` (120, `:17`) au seul `StatusEffectsPanel` (`:84`) ; `statusPanelReserve` et `signature_bar.dart:45-46` ne changent pas. `game_screen.dart:640-646` : `heroChargeLines: ChargeRules.linesFor(runState.heroStats)`, `charges: ref.watch(chargeCatalogProvider)`. Le tutoriel (`tutorial_enemy_intents_widget.dart:152`) garde le catalogue vide par défaut : aucun de ses ennemis n'est gelé.
- [ ] **Step 5 : vérifier.** `git grep -n "Brûlure\|Électrocution" -- lib/ui` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1761**, sans test neuf (D77 : M1, M9, M10, M12 au manuel). **À recopier pour l'agent des tests manuels (M12 complété)** : héros gelé en attente, une Puissance et du Feu (entrée de debug, puis une Puissance par une carte) — le panneau ne monte pas à plus de 120 px au-dessus de sa base, une barre de défilement apparaît, le défilement montre chaque ligne en entier (« Gelé : −50 % de dégâts au prochain tour » sur deux lignes, sans ellipse), et la barre des signatures n'a ni bougé ni été recouverte ; sous Windows, aucune erreur rouge ni message dans la console de debug à l'apparition de la barre de défilement, et une seule barre de défilement.
- [ ] **Step 6 : commit** (ARB et générés compris). `feat(p53): les panneaux du heros et des intentions lisent les charges`.

### Task 10: Le tutoriel ; le Gel quitte le barème de P-1

**Files :**
- Modify : `lib/tutorial/tutorial_data.dart:220-243`, `:258`, `:270` ; `lib/tutorial/widgets/tutorial_elements_widget.dart:30-76`, `:129-149`, `:188-258`, `:486-505` ; `lib/game/services/proportional_status.dart:1-23` ; `lib/l10n/app_fr.arb:333`, `app_en.arb:1078-1083`, `app_localizations*.dart`
- Test : `test/unit/damage_pipeline_test.dart:59-70`

**Interfaces :**
- Consumes : `widget.engine.data.charges` (`ChargeCatalog`), `ChargeData.name/brokenName/describe`, `ChargeRules.pose`, `ChargeRules.linesFor`, `StatusEffectsPanel(chargeLines:, charges:)` (Task 9).
- Produces : `ProportionalStatus` ne garde que `vulnerable` et `weakness`.

- [ ] **Step 1 : le test du barème.** `damage_pipeline_test.dart:59-70` : titre `le bareme de P-1 : 25 % par point ; Vulnerable 4, Faiblesse 2 points au plus`, liste `[(25, 4, 100), (25, 2, 50)]` — écrit avant le retrait de la constante, il passe avant comme après.
- [ ] **Step 2 : la prose.** Étape « Les Effets Élémentaires » et étape « Les Intentions Ennemies » : FR et EN **mot pour mot** de spec §6.3 (lignes 1 et 2 de la table), sans chiffre.
- [ ] **Step 3 : la galerie et ses cycles.** Les entrées Gel, Feu, Foudre lisent nom et description dans `widget.engine.data.charges` (`name(locale)`, `describe(locale)`) au lieu des textes en dur (`:54`, `:59-66`, `:71`). Le cycle de deux secondes (spec §6.3, ligne 4), chiffres lus sur la donnée : Gel « ❄ 1/3 » → « ❄ 2/3 » → « ❄ <brokenName> » (`threshold`) ; Feu « 🔥 1 » → « 🔥 2 » → « 🔥 3 » → « 💥 <explosionDamage> » ; Foudre « ⚡ 1/3 : +<1 × belowValue> » → « ⚡ 2/3 : +<2 × belowValue> » → « ⚡ <brokenName> : +<threshold × bonusPerPoint> » ; le « 10 -> 5 » (`:227`) et la Brûlure qui perd 1 (`:140`) disparaissent, et les commentaires des cas (`:140`, `:146`, `:188`, `:237`) disent Feu et Foudre. Le panneau de démonstration (`:486-505`) : Poison 3 en statut, et 2 Feu posés par `ChargeRules.pose(…, ChargeBearer.hero)` sur un `EntityStats` de démonstration, passés en `chargeLines` avec `charges` — il lit « Feu : 2 ».
- [ ] **Step 4 : le barème.** `ProportionalStatus.freeze` (`proportional_status.dart:22-23`) disparaît, et la phrase d'en-tête (`:6-8`) passe de « Ces trois constantes » à « Ces deux constantes » et cesse de nommer « l'intention effective », qui ne valait que pour le Gel ; `statusFreezeHint` quitte les deux ARB ; `flutter gen-l10n`.
- [ ] **Step 5 : vérifier.** `git grep -n "ProportionalStatus.freeze\|statusFreezeHint" -- lib test` → rien (fichiers générés compris) ; `git diff main -- lib/game/services/proportional_status.dart` ne touche que les lignes du Gel et la phrase d'en-tête qui le nommait ; `flutter test test/tutorial/` → vert (`tutorial_fixtures_test.dart:106` : *Boule de Feu* pose toujours `burn`) ; `dart analyze` → `No issues found!` ; `flutter test` → **1761**.
- [ ] **Step 6 : commit** (ARB et générés compris). `feat(p53): le tutoriel apprend les charges, le Gel quitte le bareme`.

### Task 11: L'entrée de debug (P-e)

**Files :**
- Modify : `lib/game/services/debug_actions.dart:164-220` ; `lib/ui/widgets/debug/tabs/debug_combat_tab.dart:73-130`
- Test : `test/unit/debug_actions_test.dart:44-50`, groupe « combat » (`:169-278`)

**Interfaces :**
- Consumes : `chargeCatalogProvider`, `ChargeRules.pose`, `ChargeRules.bearerOf`, `ChargeBearer.hero`.
- Produces : `static void DebugActions.poseCharge(RefReader read, String chargeId, {String? enemyId})` — un point, par `ChargeRules.pose` (plafond, refus sur un porteur rompu, rupture), sans bonus de Puissance ; `enemyId` nul : le héros ; id hors catalogue : rien ; `static void DebugActions.clearCharges(RefReader read)` — chez le héros et chaque ennemi, les entrées des ids du catalogue et les pistes ; tous deux gardés par `_allowed`.

- [ ] **Step 1 : les tests**, `debug_actions_test.dart` ; `_startedRun` reçoit aussi `shippedChargeOverride()` :
  1. `poseCharge suit la regle : le Gel plafonne, la rupture au seuil` — trois `poseCharge('freeze', enemyId:)` : l'ennemi est gelé (`skipsAction`), une quatrième ne pose rien ; `poseCharge('shock')` trois fois sur le héros : piste `brokenActive` ;
  2. `hors d une run debug, poseCharge et clearCharges n ecrivent rien` ;
  3. `clearCharges vide les points et les pistes du heros et des ennemis` — Poison intact ;
  4. `skipEnemyPhase ne joue aucune fermeture de phase` — Foudre chargée sur un ennemi : après `skipEnemyPhase`, toujours `brokenActive`.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/debug_actions_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter.** Les deux actions ; le commentaire de `skipEnemyPhase` dit qu'elle ne joue ni la chaîne ni les fermetures (Décisions du plan). L'onglet Combat gagne une section « Charges » : pour le héros puis pour chaque ennemi, un bouton par charge du catalogue (`ref.watch(chargeCatalogProvider)`), « +1 <nom français> », et un bouton « Retirer les charges » (spec §7.2).
- [ ] **Step 4 : vérifier.** `dart analyze` → `No issues found!` ; `flutter test` → **1765** (1761 + 4).
- [ ] **Step 5 : commit.** `feat(p53): l entree de debug des charges`.

### Task 12: La vérification finale

**Files :** aucun, sauf correction d'un écart trouvé ici (dans la tâche fautive, recommitée).

- [ ] **Step 1 : l'analyse et les tests.** `dart analyze` → `No issues found!` ; `flutter test` → `+1765: All tests passed!`.
- [ ] **Step 2 : les contrôles de spec §11.**
  - la symétrie : `flutter test test/unit/charge_symmetry_test.dart` → vert, et son test 2 (le héros gelé à −50 % joue cartes et signatures) passe ;
  - l'exemple de l'étude et l'arrêt de la chaîne : `flutter test test/unit/charge_rules_test.dart --plain-name "l exemple de l etude"` et `--plain-name "la chaine s arrete"` → verts ;
  - Vulnérable, Faiblesse et Poison inchangés : `git diff main -- lib/game/services/proportional_status.dart` ne touche que les lignes du Gel et la phrase d'en-tête qui le nommait ; `git diff main -- test/unit/damage_pipeline_test.dart` ne change aucune valeur attendue des tests de Vulnérable et de Faiblesse ; les tests du Poison (`stat_gains_characterization_test.dart`, `mana_regen_test.dart`, `stat_rule_conversion_test.dart`) n'ont changé que leurs appels ;
  - `git grep -n -E "(s|status)\.id [!=]= '(burn|freeze|shock)'" -- lib` → rien ;
  - `git grep -n "ProportionalStatus.freeze" -- lib test` → rien ;
  - `git diff main -- test | grep -c '^+.*testWidgets('` → `0` ;
  - `dart run tool/sync_assets.dart --check` → code 0.
- [ ] **Step 3 : les restes.** `git grep -n "tickEnemyStatuses\|statusFreezeHint\|effectLineBurn" -- lib test` → rien ; `git grep -n "Brûlure\|Électrocution" -- lib assets ':!assets/data/patch_notes.json'` → rien ; `git status --short` ne montre aucun fichier de plateforme généré indexé, ni `patch_notes.json`, ni `site/`, ni la ligne `version:` de `pubspec.yaml`.
- [ ] **Step 4 : rendre** à l'orchestrateur le total de tests, la sortie de `dart analyze`, la liste des commits de la partie (`git log --oneline 42579386..HEAD`) et toute décision prise en cours d'exécution.
