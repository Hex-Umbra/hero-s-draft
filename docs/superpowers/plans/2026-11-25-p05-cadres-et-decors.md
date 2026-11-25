# P-05 vague 2 — les cadres de tier et les décors — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (méthode fixée par l'orchestrateur). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** rien ne change à ce que les ennemis font ; chaque ennemi s'affiche dans le cadre de son tier autour d'une fenêtre de 64 × 96, le plateau s'affiche à un palier pair choisi par l'écran, le combat se joue devant le décor de forêt en 640 × 360 désigné par le lieu, et la barre, les languettes, la zone, le contour et la fiche de la vague 1 se recalent sur la fenêtre.

**Architecture :** les règles qui calculent — le palier, le cadrage du décor, le recadrage d'une créature, le tirage du fond, la rangée, la zone, le décalage de la carte ouverte — sont des fonctions pures sous `lib/game/systems/`, testées sans écran ; la table des cadres (un document plat) et le catalogue des lieux (lu dans le manifeste, sans JSON) sont des modèles de `lib/models/data/`, chargés par `loadGameDataRegistry` avec leurs refus ; la couche Flame les reçoit de `GameScreen` à sa construction et ne lit aucun provider ; un seul provider s'ajoute, `currentLocationProvider`, dérivé du registre et sans état, pour `ScreenScaffold`. Aucun état Riverpod neuf, aucun modèle d'état ne change, rien n'est sauvegardé.

**Tech Stack :** Flutter 3.41.6, Flame 1.38.2, Riverpod 2.x, `flutter_test` ; Python 3 et Aseprite 1.3.18 pour l'export (`art_src/tools/`) ; le runner natif Windows (C++).

**Spec :** `docs/superpowers/specs/2026-11-25-p05-cadres-et-decors-design.md`, en entier — décisions B66 à B89 (§1.1, §1.3), arbitrages A1 à A22 (§1.2), mesures §2.2, découpage §12, contrôles §13, « Pour le Review Focus du plan ». **Ne rouvrir aucun de ces arbitrages.**

Branche : `feat/v0.6.2-cadres-et-decors`, sans en créer, un commit par tâche. Base de tests : **1939** (re-mesurée le 25/11 sur `ea3b8225` : `flutter test` → `+1939: All tests passed!`). Total attendu à la fin : **2020**. Toute référence `fichier:ligne` est lue le 25/11 sur `ea3b8225` ; les Tasks 4 à 6 désignent les endroits par symbole, leurs fichiers ayant bougé dans les tâches précédentes.

**Ordre d'exécution : 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8.** Task 3 dépend de 1 et 2 ; Task 4 de 1 et 2 ; Task 5 de 2 et 4 ; Task 6 de 4 et 5 ; Task 7 de 1.

| Après la tâche | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `flutter test` | 1966 | 2004 | 2005 | 2006 | 2007 | 2020 | 2020 | 2020 |

---

## Contraintes globales

Recopiées du fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §3.5) ; elles valent pour chaque tâche :

- `dart analyze` rend `No issues found!` et `flutter test` est entièrement vert **à la fin de chaque tâche**.
- Ne rien pousser, n'ouvrir aucune PR, ne rien commiter sur `main`, n'invoquer aucun skill de livraison — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync`.
- **Jamais `dart format`** ; Write / Edit plutôt que heredoc.
- Les fichiers que `flutter` régénère sont suivis par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (**`git add` par chemin, jamais `git add -A`**), les restaurer par `git restore` s'ils apparaissent modifiés.
- Après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit (aucune n'est prévue : spec §6).
- Après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge.
- Tout texte joueur d'un JSON porte `_fr` et `_en` (aucun n'est prévu) ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart`.
- Les trois couches de `CLAUDE.md` ne se mélangent pas : Flame lit ce qu'il reçoit et ne lit aucun provider ; aucun widget dans Flame, aucun composant Flame dans `lib/ui/` (qui n'importe que des fichiers purs de `lib/game/systems/`). Pas de code sans lecteur, pas de code mort, pas de bloc commenté.
- Commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/`.
- **Un commit par tâche**, sur la branche courante.
- **L'outil d'export se lance comme la spec le donne (§10.1)** : `python export_jeu.py <source.aseprite> <cible.png> [--taille LxH]`, depuis `art_src/tools/`, comme les autres outils du dossier. **Aseprite est trouvé par `aseprite_io.aseprite_exe()`** (`art_src/tools/aseprite_io.py:27-31`) ; Pillow, que `aseprite_io` importe (`:10`), est celui des prérequis du README (`art_src/tools/README.md:25`).
- **Aucun test d'écran neuf** (ADR-113) : aucun `testWidgets(` ajouté ; ce que verrait un écran est aux tests manuels de la spec, §11.2 (M1 à M22).

## Review Focus

Les cinq modes d'échec les plus graves de « Pour le Review Focus du plan » ; chacun a son test dans la tâche nommée. Les seize autres points de cette section (elle en compte vingt et un) sont confiés, un par un, à la tâche qui les sert (ligne « Trous de la spec » de chaque tâche) ; aucun ne reste orphelin.

1. **Une carte montée mal ancrée** — barre, languettes, zone, contour, carte ouverte et sa descente faux sur une carte réellement chargée, alors que les tests du dépôt ne touchent que des cartes jamais montées (`heros_draft_game_targeting_test.dart:45-50`). → **Task 6**, Step 8 : le rejeu sur cartes montées (tiers 1 à 5, et 1, 1, 2, 3, 3 comme la spec le prescrit, en 1920 × 1080, 1920 × 1009, 1280 × 720 et 1264 × 681), test jetable écrit en entier, que le vérificateur rejoue.
2. **Un appui qui tombe au décor** sur un coin au-dessus du canevas, une épine, un jour du cadre ou la bande entre la barre et le gabarit — il fermerait la fiche et lâcherait la cible (`heros_draft_game.dart:360-365`) ; ou un survol et un lâcher (`_livingEnemyAt`, `findHoveredEnemy`) qui ne liraient pas la même zone. → **Task 2** (`les coins au-dessus du canevas, de part et d autre de la barre, sont dans la zone`), **Task 6** (`la zone de la carte recoit l appui jusqu au haut de sa barre, coins compris` ; au rejeu monté, `componentsAtPoint` rend la carte comme premier `TapCallbacks` sur quatre points).
3. **Le flash cyan d'un coup sur l'armure perdu, ou un liseré qui reste au repos**, quand `borderInfo` disparaît de l'ennemi (`combat_entity.dart:32`, `:164-166`). → **Task 6**, `target_outline_test.dart` (`au repos, rien`, `le trait se pose a l exterieur de la fenetre`) et au rejeu monté (`flashArmorHit` met le contour au cyan de 4).
4. **Le filtrage qui ne bascule pas** quand le palier passe de net à lissé (fenêtre maximisée ↔ restaurée) : le cadre, le fond et la créature gardent la peinture de leur `onLoad`. → **Task 5** l'implémente (`_refreshFiltering` à chaque `onGameResize`) ; **Task 6**, au rejeu monté, mesure `FilterQuality` à 1920 × 1080 puis 1280 × 720 puis de nouveau 1920 × 1080.
5. **Le rapport de pixels lu au mauvais endroit** — un palier, un décor ou une rangée calculés en pixels logiques donneraient à 125 % un cadre flou et un palier faux. → **Task 2** (`1,6 logique en 1536 x 864 a 1,25`, `le rapport de pixels` du décor, `deux places voisines ne sont jamais plus proches que leur distance minimale` à 1,25), **Task 3** (`sans contexte, le rapport de pixels vaut 1`).

## Décisions du plan

Classe T, tranchées par les filtres de §5 du fichier d'orchestration. Les écarts avec la spec, ou ce que le plan ajoute à ce qu'elle laisse ouvert, sont D1, D2, D3, D5, D6, D7 et D8 ; chacun porte sa preuve.

- **D1 — Le rejeu sur cartes montées est un test jetable, pas un test du dépôt** (*filtre 8*). Monter un `HerosDraftGame` sans `GameWidget` demande `game.load()` et `game.mount()`, tous deux `@internal` (`flame-1.38.2/lib/src/game/flame_game.dart:124-132`) : leur appel depuis un test lève `invalid_use_of_internal_member` à `dart analyze`. Et le précédent invoqué n'en est pas un : `heros_draft_game_targeting_test.dart` ne monte rien (« Une carte jamais montée », `:45-50`). Le test est écrit en entier à la Task 6, joué, ses chiffres consignés dans le message de commit, puis supprimé avant le commit.
- **D2 — `boardScaleFor` reçoit un cinquième paramètre, facultatif : `referenceRowWidth`** (*filtre 8*), défaut `referenceRowFrameWidth` (911). Les tests de §11 veulent que la rangée « ne tienne plus si une place ou un écart grandit d'un pixel de cadre » : sans ce paramètre, rien ne le ferait grandir. Les quatre paramètres de la spec ne changent pas.
- **D3 — Les centres de `placeRow` se calent sur le pixel physique par pas arrondis, jamais sous la distance minimale** (*filtre 6*) : chaque pas physique vaut `max(round((minimale + étalement) × k), ceil(minimale × k))`, `k` = pixels physiques par pixel de cadre. Arrondir chaque centre isolément pouvait rapprocher deux places d'un pixel sous leur minimum (§11 : « jamais plus proches que leur distance minimale »). **Écart d'un pixel avec le tableau de §5.6** : pour quatre places, la distance arrondie vaut 326 (326,4), les centres 471, 797, 1123 et 1449, la rangée **1270** et non 1271 — le 1271 de la spec est la valeur non arrondie, 3 × 326,4 + 292 ; les trois autres lignes tombent juste.
- **D4 — Une carte d'ennemi lit ses images par `game.images.load`, qui rend le cache s'il est rempli et charge sinon** (*filtre 1*, Review Focus de la spec, « Le préchargement »). Le jeu précharge tout dans `onLoad` (`heros_draft_game.dart:385-389`), avant que `StateSyncSystem` ne crée une carte ; une carte créée avant la fin du chargement — un registre de test sans préchargement — charge son image au lieu de lever sur un cache vide. Le décor du combat suit la même règle.
- **D5 — `currentLocationProvider` naît à la Task 3, et non à la Task 1** que la spec lui donne (§12) : ses deux lecteurs, `GameScreen` et `LocationBackdrop`, naissent à la Task 3 (*pas de code sans lecteur*). La Task 1 livre le catalogue et le registre ; leur lecteur y est `imagesToPreload`.
- **D6 — `HerosDraftGame` reçoit `tierFrames` (défaut `TierFrameTable.empty()`) et `location` (nullable), tous deux facultatifs** : les jeux des tests (`flame_image_prefix_test.dart:12-35`, `heros_draft_game_targeting_test.dart:68-94`) ne changent pas de constructeur. `StateSyncSystem` lève une `StateError` qui nomme l'ennemi et le tier quand la table n'a pas son cadre : le chargement le refuse déjà (A7), seul un registre fait à la main y arrive.
- **D7 — Ce que `export_jeu.py` lit, et comment** (*filtre 8* ; la spec, §10.1, dit ce qu'il affiche et refuse, pas comment il le sait). Il lit la taille dans l'en-tête IHDR du PNG (octets 16 à 24, `struct`), sans décoder l'image ; les calques par Aseprite : `--list-layers` rend les calques visibles, `--all-layers --list-layers` tous, et les masqués sont la différence — mesuré le 25/11 sur une copie de `tier_3.aseprite` dont « Ronce » était masqué : la première liste l'omet, la seconde le donne. Il trouve Aseprite par `aseprite_io.aseprite_exe()`, importé depuis son propre dossier. `aseprite_io.py` ne change pas.
- **D8 — `LocationCatalog` porte ses fautes de lecture** (`List<String> faults`), que `loadGameDataRegistry` passe à `GameDataLoader.fault` : la spec veut que `fromAssetKeys` refuse et que ses fautes s'accumulent avec les autres (§4.2, §4.3), sans dire par où elles sortent.
- **D9 — `tierFrameFaults` vit dans `game_data_service.dart`**, à côté de `loadGameDataRegistry` (« vit dans `loadGameDataRegistry` », A7) : elle lit les tailles de la fenêtre et du gabarit dans `GameConstants`, qu'un modèle de `lib/models/data/` n'importe pas, et que `lib/services/` lit déjà (`lib/services/map/map_validator.dart`).
- **D10 — La géométrie d'un cadre est trois fonctions de `entity_hover.dart` sur un `TierFrame`** : `enemyWindowRect`, `enemyTemplateRect` (la fenêtre agrandie de 12), `enemyZoneRect`. `enemyBodyRect` ne part qu'à la Task 6, quand la zone la remplace : la retirer plus tôt casserait `EnemyCard.bodyLocalRect`.
- **D11 — `CombatEntity` gagne trois rectangles locaux à défaut commun**, la carte entière : `windowLocalRect` (Task 4, la gangue et le halo), `anchorLocalRect` (Task 6, la barre, les languettes, les ancres) ; `bodyLocalRect` reste le corps de la zone. `EnemyCard` les rend sur son cadre ; `HeroCard` garde le défaut — le héros ne change pas.
- **D12 — `borderInfo` quitte `CombatEntity` au profit de `void flashArmorHit()`** : `shieldHitAnimation` l'appelle (`combat_entity.dart:164-166`) ; `HeroCard` y écrit son rectangle, cyan de 4, comme aujourd'hui ; `EnemyCard` y écrit son contour.
- **D13 — Le palier se calcule avant que `onGameResize` ne descende aux cartes** : `HerosDraftGame.onGameResize` pose `_boardScale` depuis la taille qu'il reçoit, puis appelle `super.onGameResize`, qui la transmet aux enfants. `rowFloorY` se lit sur la pose du héros (`heros_draft_game.dart:403`, `hero_card.dart:30-33`) par trois constantes qui y entrent : `HerosDraftGame.heroRowY` (0,51), `HeroCard.cardHeight` (160) et `HeroCard.boardScaleRatio` (1,3), et `HerosDraftGame.scaleFactorFor(double height)` (la règle de `:72`).
- **D14 — Le rapport de pixels se lit sur `View.maybeOf(buildContext)`** (`HerosDraftGame.devicePixelRatio`), repli 1 quand le jeu n'est pas attaché : c'est le cas des tests sur cartes non montées (§13 de la spec, Review Focus).
- **D15 — Les tests partagent deux aides sans `_test`** : `test/unit/tier_frame_fixture.dart` (les cinq `TierFrame` de §4.1) et `test/unit/fake_bundle.dart` (le `FakeBundle` de `game_data_loader_test.dart:16-32`, que ce fichier et `game_data_loader_injection_test.dart:14` importent au lieu de leur copie).

## Carte des fichiers

| Fichier | Tâche | Rôle |
|:---|:---:|:---|
| `art_src/tools/export_jeu.py` *(neuf)* | 1 | L'export `.aseprite` → PNG du jeu (A19, §10.1) |
| `assets/data/tier_frames.json`, `assets/data/frames/tier_1.png` à `tier_5.png` *(neufs)* | 1 | La table des cadres et ses images (§4.1, §10.2) |
| `assets/data/locations/forest/{combat,window_1,window_2,window_3}.png` *(neufs)* | 1 | Le lieu (§4.2, §10.2) |
| `lib/models/data/tier_frame_data.dart` *(neuf)* | 1 | `TierFrame`, `TierFrameTable` |
| `lib/models/data/location_data.dart` *(neuf)* | 1 | `DecorScreen`, `LocationAssets`, `LocationCatalog` |
| `lib/services/game_data_loader.dart` | 1 | `assetsMatching`, `fault` |
| `lib/services/game_data_service.dart` | 1, 3 | Le chargement, `tierFrameFaults` ; `currentLocationProvider` (3) |
| `lib/models/data/game_data_registry.dart` | 1 | `tierFrames`, `locations`, `imagesToPreload` |
| `pubspec.yaml` (section `assets:` seulement) | 1, 3 | Par `sync_assets` |
| `CLAUDE.md` | 1 | L'arbre des données, la couche de données, `GameDataLoader` (§13) |
| `lib/game/game_constants.dart` | 1, 2, 6 | Fenêtre et gabarit (1), languette et rangée (2) ; `inspectionScale` = 2 (6) |
| `lib/game/systems/board_scale.dart`, `decor_fit.dart`, `creature_fit.dart`, `window_background.dart` *(neufs)* | 2 | Les fonctions pures |
| `lib/game/systems/enemy_row.dart` *(neuf)* | 2, 6 | `RowSlot`, `slotOf`, `placeRow`, `rowCenterYFor` ; `inspectionShift` (6) |
| `lib/game/systems/entity_hover.dart` | 2, 6 | Fenêtre, gabarit, zone ; `enemyBodyRect` part (6) |
| `lib/game/components/entities/status_tabs.dart` | 2, 6 | Ses deux constantes passent à `GameConstants` ; ancrée au gabarit, sans appui (6) |
| `lib/game/heros_draft_game.dart` | 3, 4, 5 | Le décor, le rapport de pixels ; `tierFrames` ; le palier |
| `lib/ui/screens/game_screen.dart` | 3, 4 | Passe le lieu, puis la table |
| `lib/ui/widgets/location_backdrop.dart` *(neuf)*, `lib/ui/widgets/screen_scaffold.dart` | 3 | La couture des autres écrans (A6) |
| `rest_screen.dart`, `rest_card_selection_screen.dart`, `shop_screen.dart`, `event_screen.dart`, `relic_exchange_screen.dart`, `forge_fusion_screen.dart` (sous `lib/ui/screens/`) | 3 | Déclarent leur écran de décor |
| `assets/images/bg_dungeon.png` *(supprimé)* | 3 | A5 |
| `lib/game/systems/state_sync_system.dart` | 4 | Le cadre et le fond à la naissance de la carte |
| `lib/game/components/entities/enemy_card.dart` | 4, 5, 6 | La carte composée ; le palier ; la vague 1 recalée |
| `lib/game/components/entities/combat_entity.dart` | 4, 6 | `windowLocalRect` ; zone, ancres, `flashArmorHit` |
| `lib/game/components/visual_effects/frost_shell.dart`, `charge_halo.dart` | 4 | Reçoivent une position |
| `lib/game/components/entities/hero_card.dart` | 5, 6 | Ses constantes ; `flashArmorHit`, languettes sans appui |
| `lib/game/systems/layout_system.dart` | 5 | `repositionEnemies` sur `placeRow` |
| `windows/runner/win32_window.cpp` | 5 | `SW_SHOWMAXIMIZED` (B86) |
| `lib/game/components/entities/target_outline.dart` *(neuf)* | 6 | Le contour de ciblage et sa lueur (A14) |
| `lib/game/components/entities/enemy_health_bar.dart` | 6 | Ancrée au gabarit, sans appui |
| `lib/game/components/visual_effects/card_animator.dart`, `lib/game/systems/combat_visual_system.dart` | 6 | Les ancres (A16) |
| `art_src/tools/README.md`, `art_src/docs/workflow_decor.md`, `workflow_fond.md`, `workflow_creature.md` | 7 | Le chemin vers le jeu |
| Tests neufs : `tier_frames_test`, `location_catalog_test`, `tier_frame_fixture`, `fake_bundle` (1) ; `board_scale_test`, `decor_fit_test`, `creature_fit_test`, `window_background_test`, `enemy_row_test` (2) ; `target_outline_test` (6) | | Sous `test/unit/` |
| Tests retouchés : `game_data_loader_test`, `game_data_loader_injection_test`, `game_data_registry_preload_test`, `flame_image_prefix_test`, `real_bundle_load_test`, `entity_id_convention_test` (1) ; `entity_hover_test`, `referential_integrity_test` (2) ; `flame_image_prefix_test`, `real_bundle_load_test`, `heros_draft_game_targeting_test` (3) ; `heros_draft_game_targeting_test` (4, 5, 6) ; `combat_tap_forwarding_test`, `entity_hover_test`, `enemy_row_test` (6) | | |

---

### Task 1: Les assets et le chargement

**Files :**
- Create : `art_src/tools/export_jeu.py` ; `assets/data/tier_frames.json` ; les cinq `assets/data/frames/tier_<n>.png` et les quatre `assets/data/locations/forest/*.png` (exportés) ; `lib/models/data/tier_frame_data.dart`, `lib/models/data/location_data.dart` ; `test/unit/tier_frames_test.dart`, `test/unit/location_catalog_test.dart`, `test/unit/tier_frame_fixture.dart`, `test/unit/fake_bundle.dart`
- Modify : `lib/game/game_constants.dart:55` ; `lib/services/game_data_loader.dart` ; `lib/services/game_data_service.dart:101-203` ; `lib/models/data/game_data_registry.dart:46-85` ; `pubspec.yaml` (section `assets:`) ; `CLAUDE.md:43`, `:47`, `:75-82` ; `test/unit/game_data_loader_test.dart:16-32`, `:338-348` ; `test/unit/game_data_loader_injection_test.dart:14` ; `test/unit/game_data_registry_preload_test.dart` ; `test/unit/flame_image_prefix_test.dart:56-67` ; `test/unit/real_bundle_load_test.dart:74-78`, `:82-93` ; `test/unit/entity_id_convention_test.dart:16-22`

**Interfaces :**
- Produces — `lib/models/data/tier_frame_data.dart` :
  - `class TierFrame` : `const TierFrame({required int tier, required int width, required int height, required int windowX, required int windowY})` ; `String get imagePath` → `'assets/data/frames/tier_$tier.png'` ; `factory TierFrame.fromJson(Map<String, dynamic> json)`, qui lève une `FormatException` nommant le tier si `tier` n'est pas un entier ≥ 1, si `size` n'est pas deux entiers **pairs**, si `window` n'est pas deux entiers.
  - `class TierFrameTable` : `const TierFrameTable(List<TierFrame> frames)`, `const TierFrameTable.empty()`, `List<TierFrame> get frames`, `TierFrame? of(int tier)`, `factory TierFrameTable.fromJson(Map<String, dynamic> json)` (clé `frames` ; deux entrées du même tier : `FormatException`).
- Produces — `lib/models/data/location_data.dart` :
  - `enum DecorScreen { combat, rest, shop, event, relicExchange, forgeFusion }`, chacun avec `final String fileName` : `combat.png`, `rest.png`, `shop.png`, `event.png`, `relic_exchange.png`, `forge_fusion.png` (§4.2).
  - `class LocationAssets` : `final String id`, `String? decorFor(DecorScreen screen)` (le chemin complet, ou `null` : le repli de B76), `final List<String> windowBackgrounds` (les trois chemins, dans l'ordre de leur numéro), `Iterable<String> get images` (décors et fonds).
  - `class LocationCatalog` : `const LocationCatalog.empty()` ; `factory LocationCatalog.fromAssetKeys(Iterable<String> keys)`, qui lit toute clé `assets/data/locations/<id>/<fichier>` ; `List<LocationAssets> get locations` ; `List<String> get faults` (D8) ; `LocationAssets? get current` — `null` pour un catalogue sans lieu, sinon `locations.single`. Fautes, chacune nommant le dossier ou le fichier : aucun lieu ; plus d'un (le message nomme chaque dossier) ; un lieu sans `combat.png` ; des fonds autres que `window_1.png` à `window_3.png` exactement ; un nom que ni `DecorScreen` ni la règle des fonds ne connaissent ; un fichier qui n'est pas un `.png` en minuscules ; un id de dossier hors de `^[a-z0-9_]+$`.
- Produces — `GameDataLoader` : `Future<List<({String key, List<String> captures})>> assetsMatching(String pattern)` (la règle de `_match`, `game_data_loader.dart:251-285`, sans lire de fichier) ; `void fault(String message)` (ajoute à `_errors`).
- Produces — `game_data_service.dart` : `List<String> tierFrameFaults({required List<EnemyData> enemies, required TierFrameTable frames, required Set<String> assetKeys})` (D9) : un tier d'ennemi sans entrée (« `assets/data/enemies/<id>/enemy.json : tier <n> sans cadre dans assets/data/tier_frames.json` ») ; une entrée dont `imagePath` manque à `assetKeys` ; une fenêtre qui sort du canevas ; une fenêtre qui n'est pas en `((largeur − 64) / 2, (hauteur − 96) / 2)` ; un canevas plus petit que 88 × 120. Les tailles se lisent dans `GameConstants`, qui gagne dès cette tâche, sous un bloc « CADRE D'UN ENNEMI (pixels de cadre) » après `:55` : `enemyWindowWidth` = 64, `enemyWindowHeight` = 96, `enemyTemplateWidth` = 88, `enemyTemplateHeight` = 120, `enemyTemplateMargin` = 12 (`static const double`).
- Produces — `GameDataRegistry` : `final TierFrameTable tierFrames` (défaut `const TierFrameTable.empty()`), `final LocationCatalog locations` (défaut `const LocationCatalog.empty()`) ; `imagesToPreload` ajoute `tierFrames.frames.map((f) => f.imagePath)` et `locations.current?.images`.
- `loadGameDataRegistry`, après les ennemis et avant `throwIfFailed` (`:182`) : `loadDocument('assets/data/tier_frames.json', TierFrameTable.fromJson)` ; `LocationCatalog.fromAssetKeys` sur les clés de `assetsMatching('assets/data/locations/*/*')` (tout fichier, pour que ce qui n'est pas un PNG soit refusé) et ses `faults` passées à `loader.fault` ; si la table s'est chargée, `tierFrameFaults` sur les clés de `assetsMatching('assets/data/frames/*')`, passées à `loader.fault`. Le registre reçoit `tierFrames` (la table, ou vide si son document a échoué — `throwIfFailed` lève alors) et `locations`.

**Trous de la spec confiés à cette tâche :** le test de la fenêtre transparente décode par Flutter, sans dépendance neuve ; un second lieu refusé avec un message qui nomme les dossiers ; `entity_id_convention_test.dart` et son compte de 143 ; le commentaire de `game_data_loader_test.dart:338-347` ; le canari de `flame_image_prefix_test.dart:66-67` et le manifeste de `real_bundle_load_test.dart` (part de « les tests existants que le lot casse »).

- [ ] **Step 1 : l'outil d'export.** `art_src/tools/export_jeu.py`, usage `python export_jeu.py <source.aseprite> <cible.png> [--taille LxH]` depuis `art_src/tools/` (§10.1, D7) : importe `aseprite_exe` d'`aseprite_io` ; affiche « exportés : » puis les calques de `--list-layers`, « laissés, masqués : » puis ceux de `--all-layers --list-layers` absents de la première liste (« aucun » sinon) ; exporte par `--batch <source> --save-as` dans `aseprite_io.work('export_jeu', <nom de la cible>)` ; lit la taille dans l'en-tête IHDR ; avec `--taille`, une autre taille sort en code 1 avec les deux tailles, sans rien écrire sous la cible ; sinon `os.replace` vers la cible et affiche son chemin et sa taille. Ne convertit aucune couleur (B80).
- [ ] **Step 2 : exporter les neuf images** depuis `art_src/tools/`, par les neuf commandes du tableau de §10.2, chacune `python export_jeu.py ../<source> ../../<cible> --taille <taille>` (les sources de §10.2 sont relatives à `art_src/`). Chacune doit afficher ses calques, « laissés, masqués : aucun » pour les cadres (six calques au tier 3 : Filet, Ronce, Pousses, Baies, Écusson, Gemmes) et un calque « Décor » pour les fonds et le décor, et sortir en code 0. Puis écrire `assets/data/tier_frames.json`, le JSON de §4.1 de la spec tel quel, et lancer `dart run tool/sync_assets.dart` : la section `assets:` gagne `assets/data/frames/` et `assets/data/locations/forest/` (`assets/images/` reste jusqu'à la Task 3).
- [ ] **Step 3 : les aides de test.** `test/unit/fake_bundle.dart` : la classe de `game_data_loader_test.dart:16-32`, telle quelle ; les deux fichiers qui en portaient une copie l'importent. `test/unit/tier_frame_fixture.dart` : `const List<TierFrame> testTierFrames`, les cinq entrées de §4.1, et `TierFrame testFrameOf(int tier)`.
- [ ] **Step 4 : écrire les tests rouges.**
  - `tier_frames_test.dart` (9) : 1. `un ennemi d un tier sans cadre fait echouer le chargement, le message nomme l ennemi et le tier` — `loadGameDataRegistry(FakeBundle({...}))` avec `xp_curve.json` (`{"xpPerLevelByAct":[100]}`), `effect_icons.json` (`{}`), une table d'un seul tier 1 et sa clé d'image, les quatre clés de la forêt, et `assets/data/enemies/rat/enemy.json` de tier 2 → lève, le message contient `rat` et `tier 2` ; 2. `une entree sans image au manifeste est une faute` (`tierFrameFaults`, `assetKeys` vide → une faute contenant `tier_1.png`) ; 3. `une fenetre hors du canevas est une faute` (88 × 120, fenêtre en (30, 12)) ; 4. `une fenetre decentree est une faute` (96 × 128, fenêtre en (12, 16)) ; 5. `un canevas plus petit que le gabarit est une faute` (80 × 110, fenêtre centrée en (8, 7)) ; 6. `un tier en double est refuse` (`TierFrameTable.fromJson` → `FormatException`) ; 7. `une taille impaire est refusee` ([89, 120] → `FormatException`) ; 8. `la table livree porte les cinq cadres de B73` — `loadGameDataRegistry(rootBundle).tierFrames.frames` vaut `testTierFrames`, et la plus grande demi-hauteur vaut 76 (la valeur que `boardScaleFor` prendra pour le bas du plus grand cadre, `frameBelowWindowCenter`, à la Task 2) ; 9. `chaque cadre livre a sa taille et une fenetre transparente` — chaque PNG décodé par `ui.instantiateImageCodec` (`rootBundle.load(imagePath)`) a la taille de son entrée, et chaque pixel de sa fenêtre un alpha de 0 (`toByteData(format: ImageByteFormat.rawRgba)`).
  - `location_catalog_test.dart` (14) : 1. `la foret : son decor de combat et ses trois fonds dans l ordre` (clés dans le désordre → `current!.id == 'forest'`, `decorFor(DecorScreen.combat) == 'assets/data/locations/forest/combat.png'`, `windowBackgrounds` dans l'ordre 1, 2, 3, `faults` vide, `decorFor(DecorScreen.rest)` nul) ; 2. `aucun lieu est refuse` ; 3. `deux lieux sont refuses, le message nomme les deux dossiers` (`forest`, `dungeon`) ; 4. `un lieu sans combat.png est refuse` ; 5. `deux fonds sont refuses` ; 6. `quatre fonds sont refuses` ; 7. `un nom de fichier inconnu est refuse` (`sky.png`) ; 8. `un combat.jpg est refuse` ; 9. `un combat.PNG est refuse` ; 10. `un dossier de lieu hors snake_case est refuse` (`Forest`) ; 11. `un catalogue vide rend current nul` (`LocationCatalog.empty()` et `fromAssetKeys(const [])`) ; 12. `rest.png depose habille le repos` (`decorFor(DecorScreen.rest)` rend son chemin, B76) ; 13. `le chargement refuse un second lieu et nomme son dossier` (`loadGameDataRegistry(FakeBundle)` avec deux dossiers → le message contient `dungeon`) ; 14. `le lieu courant livre est la foret, ses images aux tailles de B74 et B67` (vrai registre ; `combat.png` décodé en 640 × 360, chaque fond en 128 × 192).
  - `game_data_loader_test.dart` (+3) : `assetsMatching rend les cles et leurs segments sans lire les fichiers` (une clé `.png` au contenu non JSON → ses segments, et `throwIfFailed` ne lève pas) ; `fault ajoute une faute que throwIfFailed remonte` ; `le demarrage du jeu refuse un registre sans tier_frames.json` (la courbe et les icônes servies → le message contient `tier_frames.json`). Le commentaire de `:340-341` devient : les autres documents manquent aussi, le test vérifie que la faute des icônes d'effet est parmi celles qui remontent.
  - `game_data_registry_preload_test.dart` (+1) : `imagesToPreload ajoute les cinq cadres et les images du lieu courant` (un registre fait à la main avec `testTierFrames` et un catalogue de la forêt → contient les cinq `tier_<n>.png` et les quatre images du lieu).
- [ ] **Step 5 : faire rougir.** `flutter test test/unit/tier_frames_test.dart test/unit/location_catalog_test.dart test/unit/game_data_loader_test.dart test/unit/game_data_registry_preload_test.dart` → échec de compilation.
- [ ] **Step 6 : implémenter** les modèles, `assetsMatching`, `fault`, `tierFrameFaults`, le chargement et le registre. Retoucher les tests existants que la tâche casse : `flame_image_prefix_test.dart`, le canari `hasLength(8)` (`:67`) devient `hasLength(17)` (les seize images du registre, plus `bg_dungeon.png` que le test pose encore) et le titre « les 17 images » ; `real_bundle_load_test.dart`, `:74-78` gagne `tier_frames.json` (« Les cinq documents »), le test de `:82` attend les cinq `assets/data/frames/tier_<n>.png` et les quatre images de la forêt ; `entity_id_convention_test.dart:17-22`, `_configDocuments` gagne `'tier_frames.json'` (« Les cinq documents ») — le compte reste 143.
- [ ] **Step 7 : `CLAUDE.md`** (§13 de la spec) : l'arbre de « Data-Driven Content Workflow » (`:75-82`) gagne `tier_frames.json` parmi les documents plats, `frames/tier_<n>.png` et `locations/<id>/{combat.png, window_<1-3>.png, …}` ; la couche de données (`:43`) gagne `tier_frame_data.dart` et `location_data.dart`, « read from the asset manifest, without JSON » ; `GameDataLoader` (`:47`) gagne `assetsMatching(pattern)` et `fault(message)`, publiques.
- [ ] **Step 8 : vérifier.** Les quatre fichiers → verts ; `dart run tool/sync_assets.dart --check` → code 0 ; `dart analyze` → `No issues found!` ; `flutter test` → **1966** (1939 + 27). `git status --short` ne montre ni `bg_dungeon.png` touché ni un fichier généré de `windows/flutter/`.
- [ ] **Step 9 : commit.** `feat(bestiaire): la table des cadres, le lieu de la foret et leur chargement`.

### Task 2: Les fonctions pures

**Files :**
- Create : `lib/game/systems/board_scale.dart`, `decor_fit.dart`, `creature_fit.dart`, `window_background.dart`, `enemy_row.dart` ; `test/unit/board_scale_test.dart`, `decor_fit_test.dart`, `creature_fit_test.dart`, `window_background_test.dart`, `enemy_row_test.dart`
- Modify : `lib/game/game_constants.dart` (le bloc de la Task 1) ; `lib/game/components/entities/status_tabs.dart:33-34`, `:52`, `:123-124`, `:131`, `:138-140`, `:228`, `:233` ; `lib/game/systems/entity_hover.dart` ; `test/unit/entity_hover_test.dart` ; `test/unit/referential_integrity_test.dart`

**Interfaces :**
- Consumes : `TierFrame` (Task 1).
- Produces — `GameConstants`, au bloc de la Task 1, renommé « CADRE ET RANGÉE D'UN ENNEMI (pixels de cadre) » : `statusTabRestWidth` = 30, `statusTabOverlap` = 1, `enemyRowMinGap` = 7, `enemyRowMaxGap` = 122, `enemyRowUsableWidth` = 0.95, `enemyRowCenterY` = 0.21 (tous `static const double`). `StatusTabs` perd `_restWidth` et `_overlap` et lit les deux de `GameConstants` partout où il les lisait — aucun changement de comportement.
- Produces — `entity_hover.dart` : `Rect enemyWindowRect(TierFrame frame)` (64 × 96 en `(windowX, windowY)`) ; `Rect enemyTemplateRect(TierFrame frame)` (la fenêtre agrandie de `enemyTemplateMargin`) ; `Rect enemyZoneRect(TierFrame frame)` (`(0, gabarit.top + enemyHealthBarTop)` à `(width, height)`). `enemyBodyRect` reste (D10).
- Produces — `board_scale.dart` : `class BoardScale { const BoardScale({required double frame, required bool crisp}); final double frame; final bool crisp; double get creature => frame / 2; }` ; `const double barTopAboveWindowCenter` = 48 + 12 + 17 = 77 (des constantes) ; `const double frameBelowWindowCenter` = 76 (le cadre du tier 5, 48 + 28, gardé par le test 8 de `tier_frames_test`) ; `const double referenceRowFrameWidth` = `6 * enemySlotWidth + 5 * GameConstants.enemyRowMinGap` (911) ; `BoardScale boardScaleFor({required Size screen, required double devicePixelRatio, required double rowCenterY, required double rowFloorY, double referenceRowWidth = referenceRowFrameWidth})` (D2).
- Produces — `decor_fit.dart` : `class DecorFit { const DecorFit({required double scale, required double left, required double top}); }` (logiques : pixels par pixel de décor, coin haut-gauche) ; `const double decorWidth = 640, decorHeight = 360` ; `DecorFit decorFitFor({required Size screen, required double devicePixelRatio})`.
- Produces — `creature_fit.dart` : `class CreatureFit { const CreatureFit({required Rect source, required bool smooth}); }` ; `const Rect oldSpriteRect = Rect.fromLTRB(308, 329, 1388, 1949)` (B75, §5.4) ; `CreatureFit creatureFitOf(int imageWidth, int imageHeight)` — 128 × 192 : l'image entière, `smooth` faux ; une image d'au moins 1388 × 1949 (qui contient `oldSpriteRect`) : `oldSpriteRect`, vrai ; toute autre : l'image entière, faux.
- Produces — `window_background.dart` : `int pickWindowBackground({required int count, required Random random})` — `random.nextInt(count)`, `count` > 0 (B87).
- Produces — `enemy_row.dart` : `class RowSlot { const RowSlot({required double width, required double gap}); }` ; `const double enemySlotWidth = GameConstants.enemyTemplateWidth + 2 * (GameConstants.statusTabRestWidth - GameConstants.statusTabOverlap)` (146) ; `RowSlot slotOf(TierFrame frame, {double gap = GameConstants.enemyRowMinGap})` — largeur `max(frame.width, enemySlotWidth)` ; `List<double> placeRow({required List<RowSlot> slots, required double unit, required double screenWidth, double devicePixelRatio = 1})` ; `double rowCenterYFor(double screenHeight, {double devicePixelRatio = 1})` — `0,21 × hauteur`, calée sur le pixel physique (227 en 1080p).

Les trois algorithmes que la spec fixe ligne à ligne (§5.1, §5.2, §5.6) :

```dart
BoardScale boardScaleFor({
  required Size screen,
  required double devicePixelRatio,
  required double rowCenterY,
  required double rowFloorY,
  double referenceRowWidth = referenceRowFrameWidth,
}) {
  final center = rowCenterY * devicePixelRatio;
  final limit = [
    GameConstants.enemyRowUsableWidth *
        screen.width *
        devicePixelRatio /
        referenceRowWidth,
    center / barTopAboveWindowCenter,
    (rowFloorY * devicePixelRatio - center) / frameBelowWindowCenter,
  ].reduce(min);
  final even = 2 * (limit / 2).floorToDouble();
  if (even >= 2) return BoardScale(frame: even / devicePixelRatio, crisp: true);
  return BoardScale(frame: limit / devicePixelRatio, crisp: false);
}
```

```dart
DecorFit decorFitFor({required Size screen, required double devicePixelRatio}) {
  final width = screen.width * devicePixelRatio;
  final height = screen.height * devicePixelRatio;
  final factor = max(width / decorWidth, height / decorHeight);
  return DecorFit(
    scale: factor / devicePixelRatio,
    left: ((width - decorWidth * factor) / 2).roundToDouble() / devicePixelRatio,
    top: ((height - decorHeight * factor) / 2).roundToDouble() / devicePixelRatio,
  );
}
```

```dart
List<double> placeRow({
  required List<RowSlot> slots,
  required double unit,
  required double screenWidth,
  double devicePixelRatio = 1,
}) {
  if (slots.isEmpty) return const [];
  final k = unit * devicePixelRatio;
  final minimal = [
    for (var i = 1; i < slots.length; i++)
      (slots[i - 1].width + slots[i].width) / 2 +
          max(slots[i - 1].gap, slots[i].gap),
  ];
  final spread = minimal.isEmpty
      ? 0.0
      : (0.85 * screenWidth / (slots.length + 1) / unit -
              minimal.reduce((a, b) => a + b) / minimal.length)
          .clamp(0.0, GameConstants.enemyRowMaxGap - GameConstants.enemyRowMinGap);
  final steps = [
    for (final m in minimal)
      max(((m + spread) * k).roundToDouble(), (m * k).ceilToDouble()),
  ];
  final extent = steps.fold(0.0, (a, b) => a + b) +
      (slots.first.width + slots.last.width) / 2 * k;
  var x = ((screenWidth * devicePixelRatio - extent) / 2 +
          slots.first.width / 2 * k)
      .roundToDouble();
  final centers = [x / devicePixelRatio];
  for (final step in steps) {
    x += step;
    centers.add(x / devicePixelRatio);
  }
  return centers;
}
```

**Trous de la spec confiés à cette tâche :** la zone sur les cinq tiers, coins compris ; la marge de la 4K ; l'image de remplacement de 64 × 64 tolérée au rendu et refusée par le test des sprites livrés, qui le dit dans son message.

- [ ] **Step 1 : écrire les tests rouges.** Le rapport vaut 1 sauf mention ; `floor(s)` désigne la hauteur `rowFloorY` du héros que `HerosDraftGame` passera (`s.y × 0,51 − 80 × clamp(s.y / 800, 0,85 ; 2,5) × 1,3`), `rowCenterY` vaut `rowCenterYFor(s.y)`.
  - `board_scale_test.dart` (10) : `x2 en 1920 x 1080, net, la creature a la moitie` (`frame` 2, `crisp`, `creature` 1) ; `x2 en 1920 x 1009` ; `1,6 logique en 1536 x 864 a 1,25` (`frame` 1,6, `crisp`) ; `la rangee de six tient a x2 en 1920, plus si une place ou un ecart grandit d un pixel` (`referenceRowWidth` 917 puis 916 → `crisp` faux) ; `un ecran trop bas pour la barre fait tomber le palier` (`rowCenterY` 150 en 1920 → `frame` < 2) ; `un heros trop haut pour le cadre fait tomber le palier` (`rowFloorY` = 227 + 151 en 1920 × 1080 → `crisp` faux) ; `x2 en 2560 x 1440 (B83)` ; `x4 en 3840 x 2160 a 4 pixels pres, x2 si une place ou un ecart grandit` (`frame` 4 ; 917 et 916 → 2) ; `1,335 lisse en 1280 x 720 (B85)` (`closeTo(1.3348, 1e-4)`, `crisp` faux) ; `1,318 lisse en 1264 x 681` (`closeTo(1.3181, 1e-4)`).
  - `decor_fit_test.dart` (6) : `3, 4 et 6 en 1080p, 1440p et 4K, sans decalage` ; `3 en 1920 x 1009, centre` (`top` −36, rogné de 36 en haut, 35 en bas) ; `2 en 1280 x 720` ; `1,975 dans la fenetre restauree, 1264 x 681` ; `2,22 en 1280 x 800, centre, 71 pixels rognes de chaque cote (B88)` (`left` −71) ; `le rapport de pixels` (1536 × 864 à 1,25 → `scale` 2,4, `left` et `top` 0).
  - `creature_fit_test.dart` (3) : `un sprite neuf de 128 x 192 se dessine entier et net` ; `une peinture de 1696 ou 1694 x 2528 se recadre sur B75 et se lisse` (`source == oldSpriteRect`, rapport 2:3 exact, contenu dans l'image, `smooth`) ; `l image de remplacement de 64 x 64 se dessine entiere`.
  - `window_background_test.dart` (3) : `un indice dans [0, count)` ; `un alea a graine rejoue le meme` (`Random(7)` deux fois) ; `sur 300 tirages, chacun des trois sort`.
  - `enemy_row_test.dart` (12) : `slotOf rend 146 aux cinq tiers, a l ecart minimal 7` ; `six places en 1080p a x2 : 306 et 1822`, `cinq places : 306 et 1516`, `quatre places : 326 et 1270` (centres 471, 797, 1123, 1449 ; D3), `deux places : 536 et 828` (distances des centres, et largeur de la rangée = dernier − premier + 292 ; `unit` 2, `screenWidth` 1920) ; `une place seule au centre` (960) ; `la rangee est centree` (places de 146 et 200 : bords extérieurs à égale distance des bords de l'écran, à un pixel près) ; `deux places voisines ne sont jamais plus proches que leur distance minimale` (six places, `unit` 1,3348, rapport 1,25) ; `deux places a ecart serre sont plus proches que deux ordinaires` (`gap` 2) ; `une place serree a cote d une ordinaire garde l ecart ordinaire` ; `une meute de trois places serrees entre deux ordinaires` (pas de 306, 296, 296, 306 en 1080p ×2, rangée centrée) ; `les centres et l ordonnee sont cales sur le pixel physique` (rapport 1,25 : `x × 1,25` entier pour chaque centre ; `rowCenterYFor(1080) == 227`, `rowCenterYFor(864, devicePixelRatio: 1.25) * 1.25 == 227`).
  - `entity_hover_test.dart` (+3) : `la zone d un ennemi sur les cinq tiers : du haut de la barre au bas du canevas` (hauts −17, −13, −9, −5, −1 ; largeur et bas du canevas) ; `les coins au-dessus du canevas, de part et d autre de la barre, sont dans la zone` (tier 2 : (2, −10) et (94, −10) ; tier 3 : (4, −5) et (100, −5) ; tier 4 : (6, −3) ; tier 5 : (8, −0,5)) ; `le gabarit est le meme autour de la fenetre sur les cinq cadres` (88 × 120, à 12 de la fenêtre de 64 × 96).
  - `referential_integrity_test.dart` (+1) : `chaque sprite livre est un sprite neuf ou une peinture qui contient le rectangle de B75` — la taille lue dans l'en-tête IHDR de chaque `assets/data/enemies/<id>/sprite.png` (`dart:io`) vaut 128 × 192 ou contient `oldSpriteRect` ; le message d'échec dit : « un ennemi cree par l editeur doit recevoir son vrai sprite (128 x 192) avant d etre livre ».
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/board_scale_test.dart test/unit/decor_fit_test.dart test/unit/creature_fit_test.dart test/unit/window_background_test.dart test/unit/enemy_row_test.dart test/unit/entity_hover_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter** les cinq fichiers, les constantes, les trois rectangles ; `StatusTabs` lit les deux constantes déplacées.
- [ ] **Step 4 : vérifier.** Les fichiers → verts ; `git grep -n "_restWidth\|_overlap" -- lib` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **2004** (1966 + 38).
- [ ] **Step 5 : commit.** `feat(bestiaire): le palier, le cadrage du decor, la rangee et la zone en fonctions pures`.

### Task 3: Le décor

**Files :**
- Create : `lib/ui/widgets/location_backdrop.dart`
- Delete : `assets/images/bg_dungeon.png`
- Modify : `lib/services/game_data_service.dart` (fin de fichier) ; `lib/game/heros_draft_game.dart:85-93`, `:155-176`, `:385-397`, `:399-414` ; `lib/ui/screens/game_screen.dart:313-317` ; `lib/ui/widgets/screen_scaffold.dart` ; `rest_screen.dart:137`, `rest_card_selection_screen.dart:91`, `shop_screen.dart:336`, `event_screen.dart:446`, `relic_exchange_screen.dart:112`, `forge_fusion_screen.dart:151` ; `pubspec.yaml` (section `assets:`) ; `test/unit/flame_image_prefix_test.dart:56-67` ; `test/unit/real_bundle_load_test.dart:92` ; `test/unit/heros_draft_game_targeting_test.dart`

**Interfaces :**
- Consumes : `LocationAssets`, `DecorScreen` (Task 1) ; `decorFitFor`, `decorWidth`, `decorHeight` (Task 2).
- Produces — `final currentLocationProvider = Provider<LocationAssets?>(…)` : `ref.watch(gameDataLoaderProvider).valueOrNull?.locations.current` (D5, sur le modèle de `chargeCatalogProvider`, `:238-242`).
- Produces — `HerosDraftGame` : `final LocationAssets? location` (paramètre nommé facultatif, D6) ; `double get devicePixelRatio` (D14 : `View.maybeOf(buildContext)?.devicePixelRatio ?? 1`, `buildContext` nul → 1). `onLoad` ne charge plus que `imagesToPreload` ; le décor est un `SpriteComponent` de `priorityBackground`, ajouté seulement si `location?.decorFor(DecorScreen.combat)` n'est pas nul, son image lue par `images.load` (D4) ; un `void _placeDecor()` lui donne `position` (`left`, `top`) et `size` (640 × 360 × `scale`) de `decorFitFor(screen: Size(size.x, size.y), devicePixelRatio: devicePixelRatio)`, appelé après son ajout et à chaque `onGameResize` à la place de `:411-413`. Le filtrage reste celui par défaut, `FilterQuality.none` (B88 : jamais lissé). Sans lieu, rien n'est ajouté : `backgroundColor()` (`:488`) reste.
- Produces — `class LocationBackdrop extends ConsumerWidget` : `const LocationBackdrop({super.key, required DecorScreen screen, required Widget fallback, required Widget child})` — sans image pour `screen` dans `currentLocationProvider`, rend `fallback` ; sinon un `Stack` rogné, l'image (`Image.asset`, `FilterQuality.none`, `BoxFit.fill`) posée par `decorFitFor` sur la taille du `LayoutBuilder` et `MediaQuery.devicePixelRatioOf(context)`, puis `child`.
- Produces — `ScreenScaffold` : `final DecorScreen? decor` (paramètre facultatif) ; non nul, le corps devient `LocationBackdrop(screen: decor, fallback: <le corps décoré d'aujourd'hui>, child: <le contenu>)` ; nul, rien ne change (les huit autres écrans). Les six écrans déclarent : `DecorScreen.rest` (repos et son choix de carte), `.shop`, `.event`, `.relicExchange`, `.forgeFusion`.
- `GameScreen` : `location: ref.read(currentLocationProvider)`.

**Trous de la spec confiés à cette tâche :** la source du rapport de pixels et son repli à 1 ; `build/unit_test_assets` qui garde `bg_dungeon.png` ; les tests d'écran à registre manuel (`test/widget/event_screen_test.dart:62-72` et semblables), qui doivent garder leur fond ; `flame_image_prefix_test.dart:59` et `real_bundle_load_test.dart:92` (part de « les tests existants que le lot casse »).

- [ ] **Step 1 : écrire le test rouge.** `heros_draft_game_targeting_test.dart` (+1) : `sans contexte, le rapport de pixels vaut 1` — `expect(game.devicePixelRatio, 1)`.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/heros_draft_game_targeting_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter** ; supprimer `assets/images/bg_dungeon.png` (`git rm`), puis `dart run tool/sync_assets.dart` (la ligne `assets/images/` part) ; `Remove-Item -Recurse -Force build/unit_test_assets`. Retoucher : `flame_image_prefix_test.dart:59`, l'ensemble devient `{...registry.imagesToPreload}`, le canari `hasLength(16)` — trois classes, quatre ennemis, cinq cadres, quatre images du lieu — et le titre « les 16 images » ; `real_bundle_load_test.dart:92` part.
- [ ] **Step 4 : vérifier.** `git grep -n "bg_dungeon\|assets/images/bg" -- lib test` → rien ; `flutter test test/widget` → vert sans retouche ; `dart run tool/sync_assets.dart --check` → code 0 ; `dart analyze` → `No issues found!` ; `flutter test` → **2005** (2004 + 1).
- [ ] **Step 5 : commit.** `feat(bestiaire): le decor de foret derriere le combat, la couture des autres ecrans`.

### Task 4: La carte composée

**Files :**
- Modify : `lib/game/components/entities/enemy_card.dart:30-33`, `:211-213`, `:216-287` ; `lib/game/components/entities/combat_entity.dart:357`, `:367-373` ; `lib/game/components/visual_effects/frost_shell.dart:9-10` ; `charge_halo.dart:9-10` ; `lib/game/systems/state_sync_system.dart:164-167` ; `lib/game/heros_draft_game.dart` (constructeur) ; `lib/ui/screens/game_screen.dart:313-317` ; `test/unit/heros_draft_game_targeting_test.dart:45-50`

**Interfaces :**
- Consumes : `TierFrame`, `TierFrameTable` (Task 1) ; `creatureFitOf`, `pickWindowBackground`, `enemyWindowRect` (Task 2) ; `location` (Task 3).
- Produces — `HerosDraftGame` : `final TierFrameTable tierFrames` (facultatif, défaut `const TierFrameTable.empty()`, D6). `GameScreen` passe `tierFrames: ref.read(gameDataLoaderProvider).requireValue.tierFrames`.
- Produces — `EnemyCard({required EnemyInstance instance, required TierFrame frame, required String? windowBackground, required void Function(EnemyCard, int) onTapEnemy})`, `super(size: Vector2(frame.width, frame.height))` ; `final TierFrame frame` ; `final String? windowBackground` ; `@override Rect get windowLocalRect => enemyWindowRect(frame)`. `onLoad` ne calcule plus d'ajustement « contain » (`:227-255` partent) : dans l'ordre de §5.3, le fond (priorité 0, la fenêtre, s'il y en a un), la créature `sprite` (priorité 1, la fenêtre, `Sprite(image, srcPosition, srcSize)` de `creatureFitOf`), le cadre `_frameSprite` (priorité 2, le canevas, `frame.imagePath`), chacun lu par `game.images.load` (D4) ; `late final bool _smoothCreature` retient `CreatureFit.smooth`, la créature lissée en `FilterQuality.medium` quand il est vrai. `borderInfo` reste, priorité 3 ; la barre et les languettes restent ancrées au canevas (`width: size.x`, `cardWidth: size.x`) jusqu'à la Task 6.
- Produces — `CombatEntity` : `Rect get windowLocalRect => Rect.fromLTWH(0, 0, size.x, size.y)` (D11) ; `ChargeHalo` et `FrostShell` gagnent `Vector2? position`, et `refreshChargeVisuals` les pose sur `windowLocalRect` (A15) — position en son coin, taille la sienne ; priorités 4 et 5 inchangées.
- Produces — `StateSyncSystem` : `final Random _backgroundRandom = Random()` ; à la création d'une carte (`:164-167`), `frame: game.tierFrames.of(tier)` (sans entrée : `StateError` nommant l'ennemi et le tier, D6) et `windowBackground` : `null` sans lieu ou sans fond, sinon `windowBackgrounds[pickWindowBackground(count: …, random: _backgroundRandom)]` (A13, B87).

**Trous de la spec confiés à cette tâche :** le préchargement (D4) ; la gangue et le halo, ajoutés en cours de combat, gardent leur priorité et prennent la fenêtre (part de « l'ordre des enfants ») ; les `EnemyCard(...)` des tests reçoivent un cadre (part de « les tests existants que le lot casse »).

- [ ] **Step 1 : écrire le test rouge.** `heros_draft_game_targeting_test.dart` : `_enemy(game, id, {int tier = 1})` passe `frame: testFrameOf(tier)`, `windowBackground: null` ; (+1) `la carte d un ennemi mesure le canevas de son tier, sa fenetre a l offset de la table` — tier 3 : `size == Vector2(104, 136)`, `windowLocalRect == Rect.fromLTWH(20, 20, 64, 96)`.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/heros_draft_game_targeting_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter.**
- [ ] **Step 4 : vérifier.** Le fichier → vert ; `git grep -n "imgRatio\|cardRatio" -- lib` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **2006** (2005 + 1). Lancer `flutter run -d windows` et ouvrir un combat de l'acte 1 : les ennemis dans le cadre du tier 1, la créature recadrée (rien n'est mesuré ici : la Task 6 le rejoue monté).
- [ ] **Step 5 : commit.** `feat(bestiaire): la carte d ennemi composee, fond, creature et cadre`.

### Task 5: Le palier et la rangée

**Files :**
- Modify : `lib/game/heros_draft_game.dart:72`, `:399-414` ; `lib/game/components/entities/hero_card.dart:29-33`, `:120`, `:150` ; `lib/game/components/entities/enemy_card.dart:42`, `:51-66`, `:289-293` ; `lib/game/systems/layout_system.dart:104-145` ; `windows/runner/win32_window.cpp:153` ; `test/unit/heros_draft_game_targeting_test.dart`

**Interfaces :**
- Consumes : `boardScaleFor`, `BoardScale`, `placeRow`, `slotOf`, `rowCenterYFor` (Task 2) ; `devicePixelRatio` (Task 3) ; `EnemyCard.frame` (Task 4).
- Produces — `HerosDraftGame` : `static const double heroRowY = 0.51` (lu par `:403`) ; `static double scaleFactorFor(double height)` (`(height / 800).clamp(0.85, 2.5)`), `scaleFactor` le lit ; `BoardScale get boardScale` sur `late BoardScale _boardScale`, posé au début de `onGameResize` depuis sa taille, avant `super.onGameResize` (D13) : `screen` la taille, `rowCenterY` `rowCenterYFor(size.y, …)`, `rowFloorY` `size.y × heroRowY − HeroCard.cardHeight / 2 × scaleFactorFor(size.y) × HeroCard.boardScaleRatio`.
- Produces — `HeroCard` : `static const double cardWidth = 120, cardHeight = 160, boardScaleRatio = 1.3`, lus par son constructeur, `entityBaseScale`, `onLoad` et `onGameResize` — le héros ne change pas.
- Produces — `EnemyCard` : `restScale => game.boardScale.frame` (le boss à la taille des autres, B73) ; `_scaleMultiplier`, son accesseur et son mutateur partent ; le getter `isBoss` (`:42`) part aussi, `restScale` (`:61`) étant son seul lecteur — `ChargeRules.bearerOf` (`charge_rules.dart:61-62`) et le HUD lisent `EnemyInstance.isBoss` ; `void _refreshFiltering()` : à `crisp` faux, le fond et le cadre en `FilterQuality.medium`, sinon `none` ; la créature en `medium` si `_smoothCreature` ou si `crisp` est faux (B85) ; appelé à la fin de `onLoad` et dans `onGameResize` après `_snapScale()`, sous `if (isLoaded)`.
- Produces — `LayoutSystem.repositionEnemies` : les centres de `placeRow(slots: [slotOf(card.frame) …], unit: boardScale.frame, screenWidth: size.x, devicePixelRatio: …)`, l'ordonnée `rowCenterYFor(size.y, …)`, posés par `EnemyCard.place` ; `scaleMultiplier`, `visualWidthPerEnemy`, les facteurs 1,45 et le rétrécissement (`:113-136`) partent.
- `win32_window.cpp:153` : `SW_SHOWNORMAL` → `SW_SHOWMAXIMIZED` (B86, A22) ; `Show()` n'est appelé qu'à la première image (`flutter_window.cpp:30-31`).

**Trous de la spec confiés à cette tâche :** M22 regarde le premier affichage, sans éclair de la taille de création ; le filtrage qui bascule est implémenté ici (Review Focus 4, mesuré à la Task 6).

- [ ] **Step 1 : écrire le test rouge.** `heros_draft_game_targeting_test.dart` (+1) : `la carte au repos est a l echelle du palier, un boss aussi` — après `onGameResize(Vector2(1280, 800))`, `e1.restScale == game.boardScale.frame` (`closeTo(1.3348, 1e-4)`), et une carte d'`EnemyInstance(isBoss: true)` a le même. Le commentaire de `setUp` (`:108-109`) dit aussi le palier.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/heros_draft_game_targeting_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter.**
- [ ] **Step 4 : vérifier.** Le fichier → vert ; `git grep -n -e scaleMultiplier -e visualWidthPerEnemy -- lib test` → rien ; `git diff --stat -- windows macos linux` ne nomme que `windows/runner/win32_window.cpp` ; `flutter build windows --debug` → construit ; `dart analyze` → `No issues found!` ; `flutter test` → **2007** (2006 + 1). Lancer le jeu sous Windows : il s'ouvre maximisé ; « Restaurer » le ramène à 1280 × 720.
- [ ] **Step 5 : commit.** `feat(bestiaire): le plateau au palier pair, la rangee placee, la fenetre maximisee`.

### Task 6: La vague 1 sur les cadres — *tâche à risque*

**Files :**
- Create : `lib/game/components/entities/target_outline.dart` ; `test/unit/target_outline_test.dart`
- Modify : `lib/game/game_constants.dart:30` ; `lib/game/systems/entity_hover.dart:6-9` ; `lib/game/systems/enemy_row.dart` ; `lib/game/components/entities/enemy_card.dart` ; `combat_entity.dart` ; `hero_card.dart` ; `enemy_health_bar.dart` ; `status_tabs.dart` ; `lib/game/components/visual_effects/card_animator.dart:303-318` ; `lib/game/systems/combat_visual_system.dart:51-75` ; `test/unit/combat_tap_forwarding_test.dart` (réécrit) ; `test/unit/entity_hover_test.dart:80-86` ; `test/unit/enemy_row_test.dart` ; `test/unit/heros_draft_game_targeting_test.dart`
- Jetable, jamais commité : `test/unit/jetable_cartes_montees_test.dart`

**Interfaces :**
- Consumes : `enemyWindowRect`, `enemyTemplateRect`, `enemyZoneRect` (Task 2) ; `EnemyCard.frame`, `windowLocalRect`, `_frameSprite`, `_smoothCreature`, `_background` (Task 4) ; `boardScale`, `devicePixelRatio`, `_refreshFiltering` (Tasks 3, 5).
- Produces : `inspectionShift` ; `TargetOutline` ; `CombatEntity.anchorLocalRect`, `flashArmorHit()`, `containsLocalPoint` ; `StatusTabs({required StatusSide side, required Rect anchorRect})` ; `EnemyHealthBar({required Rect anchorRect})` ; `GameConstants.inspectionScale` = 2.

**Trous de la spec confiés à cette tâche :** la descente de 77 × le palier, un test par tier ; le rejeu monté (Review Focus 1), dont la 1264 × 681 ; l'ordre des enfants (la barre au-dessus du cadre, mesuré au rejeu) ; `combat_tap_forwarding_test.dart:10-38` et ses constructeurs `:31`, `:44` (part de « les tests existants que le lot casse ») ; la zone (Review Focus 2) ; le contour (Review Focus 3) ; le filtrage mesuré (Review Focus 4).

**Ordre des pas :** écrire d'abord les tests du Step 6 et les faire rougir (Step 7), puis les Steps 1 à 5, puis le Step 7 de nouveau (vert), enfin le rejeu monté (Step 8).

**Pourquoi le décalage de B89 se lit avant lui-même.** `_targetPosition` est la seule place d'arrivée que lisent `place`, `animateInspection` et `inspectionRect` (`enemy_card.dart:119`, `:127`, `:160`, `:187`). Il devient la place descendue (`restPosition` + la descente) plus le décalage, et le décalage se calcule sur le rectangle de la carte ouverte **posé sur la place descendue** : sans cela, le décalage se lirait sur un rectangle déjà décalé, qui tient toujours, et vaudrait 0 au second appel. `inspectionRect` rend ensuite le rectangle sur la place décalée : c'est lui que `_emitInspection` passe à `onInspectionChanged`, donc à `SheetPlacement`. Les écarts relatifs d'ADR-121 (point 6) suivent sans changement : `place` et `animateInspection` ajoutent l'écart entre la nouvelle arrivée et `_headingTo`.

- [ ] **Step 1 : `GameConstants` et `entity_hover.dart`.** `GameConstants.inspectionScale` (`:30`) passe à `2.0`, son commentaire : « L'agrandissement de la carte ouverte : le double, à tout palier (B79, B84). » `enemyBodyRect` et son commentaire (`entity_hover.dart:6-9`) partent.

- [ ] **Step 2 : le décalage de la carte ouverte**, à la fin de `lib/game/systems/enemy_row.dart` :

```dart
/// Le décalage horizontal, logique, qui garde la carte ouverte dans l'écran
/// (B89), arrondi vers l'intérieur. [left] et [right] bornent la carte ouverte
/// à son arrivée, AVANT décalage : sa zone au repos — canevas, barre,
/// languettes au repos —, à l'échelle de la fiche, posée sur `restPosition`
/// plus la descente. Une carte plus large que l'écran se centre.
double inspectionShift({
  required double left,
  required double right,
  required double screenWidth,
  double devicePixelRatio = 1,
}) {
  if (right - left > screenWidth) return (screenWidth - right - left) / 2;
  // La grandeur s'arrondit au pixel physique supérieur : sous B85, le bord de
  // la carte ne tombe pas sur un pixel physique, et la carte ne doit jamais
  // dépasser l'écran. Le millionième absorbe l'erreur d'arrondi d'un produit.
  double inward(double overflow) =>
      ((overflow * devicePixelRatio) - 1e-6).ceilToDouble() / devicePixelRatio;
  if (left < 0) return inward(-left);
  if (right > screenWidth) return -inward(right - screenWidth);
  return 0;
}
```

- [ ] **Step 3 : le contour de ciblage**, `lib/game/components/entities/target_outline.dart` :

```dart
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Le contour de ciblage d'un ennemi (B78, spec P-05 vague 2, A14) : un trait
/// posé à l'extérieur de sa fenêtre, sur le filet du cadre, et la lueur cyan
/// pulsante de la surbrillance. Au repos, rien. Il ne décide rien : sa carte
/// lui dit quoi montrer.
class TargetOutline extends PositionComponent {
  TargetOutline({required this.window}) : super(priority: _priority);

  /// La fenêtre de la carte, dans les coordonnées de la carte.
  final Rect window;

  /// Au-dessus du cadre (2), sous la gangue (4) et le halo (5).
  static const int _priority = 3;

  Color? _color;
  double _strokeWidth = 0;
  bool _glowing = false;
  double _time = 0;

  /// La couleur du trait, nulle au repos.
  Color? get color => _color;

  /// Le rectangle du trait : la fenêtre agrandie de la moitié du trait, qui se
  /// pose ainsi tout entier hors d'elle ; nul au repos.
  Rect? get strokeRect =>
      _color == null ? null : window.inflate(_strokeWidth / 2);

  /// [color] nulle : plus de trait.
  void setStroke(Color? color, double width) {
    _color = color;
    _strokeWidth = width;
  }

  /// La lueur de la surbrillance, qui pulse tant qu'elle dure.
  set glowing(bool value) {
    if (value && !_glowing) _time = 0;
    _glowing = value;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_glowing) _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_glowing) {
      final opacity = 0.5 + 0.3 * sin(_time * 4);
      final width = 6 + 2 * opacity;
      canvas.drawRect(
        window.inflate(width / 2),
        Paint()
          ..color = Colors.cyanAccent.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8 + 4 * opacity),
      );
    }
    final rect = strokeRect;
    final stroke = color;
    if (rect != null && stroke != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = _strokeWidth,
      );
    }
  }
}
```

- [ ] **Step 4 : la barre et les languettes au gabarit, sans appui.**

  `enemy_health_bar.dart` : `import 'package:flame/events.dart';` part ; la classe perd `with TapCallbacks`, `onTap` et `onTapDown` (`:13`, `:109-110`) ; son commentaire de tête devient « posée au-dessus du gabarit de sa carte et large comme lui (B77) … Elle ne reçoit aucun appui : la zone de sa carte le prend (A17). » Le constructeur :

```dart
  EnemyHealthBar({required Rect anchorRect})
    : super(
        position: Vector2(
          anchorRect.left,
          anchorRect.top + GameConstants.enemyHealthBarTop,
        ),
        size: Vector2(anchorRect.width, GameConstants.enemyHealthBarHeight),
        priority: _priority,
      ) {
    final centerY = GameConstants.enemyHealthBarHeight / 2;
    _bar = LinearProgressBarComponent(
      size: Vector2(anchorRect.width, GameConstants.enemyHealthBarHeight),
      percentage: 1.0,
      borderRadius: GameConstants.enemyHealthBarRadius,
    );
```

  le reste du corps (`:33-57`) inchangé ; et, après la déclaration des champs : `/// Au-dessus du cadre (2) et des languettes (6) (spec §5.3). static const int _priority = 7;`

  `status_tabs.dart` : `import 'package:flame/events.dart';` part ; la classe perd `with TapCallbacks`, `onTap`, `containsLocalPoint` et `onTapDown` (`:198-208`) ; `cardWidth` devient `anchorRect` :

```dart
  StatusTabs({
    required this.side,
    required this.anchorRect,
  }) : super(priority: _priority) {
    _target = _emptyRect;
    position.setValues(_target.left, _target.top);
  }

  final StatusSide side;

  /// Le rectangle auquel la languette s'attache, dans la carte : le gabarit
  /// d'un ennemi (B77), la carte entière du héros.
  final Rect anchorRect;
```

```dart
  double get _restX => side == StatusSide.left
      ? anchorRect.left + GameConstants.statusTabOverlap - GameConstants.statusTabRestWidth
      : anchorRect.right - GameConstants.statusTabOverlap;

  double get _topY => anchorRect.top + _top;

  Rect get _emptyRect => Rect.fromLTWH(_restX, _topY, 0, 0);

  Rect get _restRect => Rect.fromLTWH(
        _restX,
        _topY,
        GameConstants.statusTabRestWidth,
        2 * _restPadding + _rows.length * _restPitch,
      );

  Rect get _unfoldedRect {
    final width = unfoldedWidth;
    final x = switch ((side, _inward)) {
      (StatusSide.left, false) => anchorRect.left + GameConstants.statusTabOverlap - width,
      (StatusSide.left, true) => anchorRect.left,
      (StatusSide.right, false) => anchorRect.right - GameConstants.statusTabOverlap,
      (StatusSide.right, true) => anchorRect.right - width,
    };
    final height = _rows.fold(2 * _padY, (sum, row) => sum + row.pitch);
    return Rect.fromLTWH(x, _topY, width, height);
  }
```

  Le commentaire de tête (`:10-15`) : « … elle montre les entrées que sa carte lui donne. Son [position] et sa [size] sont le rectangle dessiné, en unités de la carte ; elle ne reçoit aucun appui, sa carte le prend sur [zoneLocalRects] (A17). » ; celui de `setUnfolded` : « par-dessus le gabarit de sa carte (B39) ».

- [ ] **Step 5 : la carte, la zone, la fiche, le contour et les ancres.**

  `combat_entity.dart` — `import 'package:flame/events.dart';` part. `RectangleComponent get borderInfo;` (`:32`) devient :

```dart
  /// Le flash d'un coup encaissé sur l'armure : cyan de 4, jusqu'à ce que la
  /// réaction rende la bordure (D12).
  void flashArmorHit();
```

  Après `bodyLocalRect` (`:37-39`), dont le commentaire devient « Le corps de la zone de la carte, en unités de la carte : sans ses languettes » :

```dart
  /// Le rectangle auquel s'ancrent la barre, les languettes, les textes et les
  /// effets (A16) : le gabarit d'un ennemi, la carte entière du héros.
  Rect get anchorLocalRect => Rect.fromLTWH(0, 0, size.x, size.y);
```

  `addStatusTabs` (`:60-74`) :

```dart
  /// Pose les deux languettes contre [anchorLocalRect].
  void addStatusTabs() {
    leftTabs = StatusTabs(side: StatusSide.left, anchorRect: anchorLocalRect);
    rightTabs = StatusTabs(side: StatusSide.right, anchorRect: anchorLocalRect);
    addAll([leftTabs, rightTabs]);
  }
```

  La zone (`:92-108`) :

```dart
  /// La zone de la carte en unités de la carte (spec P-05, §4.5 ; vague 2,
  /// A17) : son corps et ses languettes, au repos comme déroulées. Le
  /// rectangle au repos reste dans la zone quand une languette se déroule vers
  /// l'intérieur : le pointeur qui l'a déroulée y est encore.
  List<Rect> get _localZone => [
        bodyLocalRect,
        if (isLoaded)
          for (final tabs in [leftTabs, rightTabs]) ...tabs.zoneLocalRects,
      ];

  /// La même zone, sur le canevas : le survol et le lâcher la lisent.
  List<Rect> get zone => [for (final local in _localZone) _absoluteRect(local)];

  bool zoneContains(Vector2 point) {
    final offset = point.toOffset();
    return zone.any((rect) => rect.contains(offset));
  }

  /// L'appui suit la même zone : la carte reçoit tout appui de sa zone, coins
  /// au-dessus du canevas et languettes comprises (A17).
  @override
  bool containsLocalPoint(Vector2 point) {
    final offset = point.toOffset();
    return _localZone.any((rect) => rect.contains(offset));
  }
```

  Dans `setHovered` (`:128-130`), le bord d'attache devient celui du gabarit :

```dart
              attachEdge: absolutePositionOf(
                Vector2(
                  tabs.side == StatusSide.left
                      ? anchorLocalRect.left
                      : anchorLocalRect.right,
                  0,
                ),
              ).x,
```

  Dans `shieldHitAnimation`, `:164-166` deviennent `flashArmorHit();` sous le commentaire « Le flash cyan d'un coup sur l'armure (D12). » Les ancres (A16), dans `_spawnChargeHitBonuses` et `triggerHitReactions` :

```dart
          position + Vector2(offsetX, -anchorLocalRect.height * scale.y / 2),
```

```dart
          position + Vector2(0, (anchorLocalRect.height / 2 - 20) * scale.y),
```

```dart
          position + Vector2(0, -anchorLocalRect.height * scale.y / 2),
```

```dart
      final double verticalOffset = isPlayer
          ? -anchorLocalRect.height / 4
          : anchorLocalRect.height / 2;
```

  `hero_card.dart` — `borderInfo` (`:24-25`) perd `@override` ; `addStatusTabs(onTapDown)` (`:142`) devient `addStatusTabs()` ; après `refreshBorderVisuals` :

```dart
  @override
  void flashArmorHit() {
    borderInfo.paint.color = Colors.cyanAccent;
    borderInfo.paint.strokeWidth = 4;
  }
```

  `enemy_card.dart` — les imports gagnent `../../systems/enemy_row.dart` et `target_outline.dart`, perdent `dart:math` ; le commentaire de `onTapEnemy` : « Le toucher de la carte, n'importe où dans sa zone (A17), avec le pointeur de l'appui… » ; `@override late final RectangleComponent borderInfo;` devient `late final TargetOutline outline;`. La descente, la place d'arrivée et les deux rectangles remplacent `:114-119` et `:175-194` :

```dart
  /// La descente de la carte ouverte : le haut de sa barre, en haut de sa
  /// zone, reste où il était quand elle grandit (B40) — 77 pixels de cadre
  /// par palier sur les cinq cadres (A18).
  double get _inspectionDrop =>
      (size.y / 2 - bodyLocalRect.top) * (baseScale - restScale);

  /// La place de la carte, la descente comprise, avant le décalage de B89.
  Vector2 get _droppedPosition => restPosition + Vector2(0, _inspectionDrop);

  /// La place vers laquelle la carte va. Ouverte, elle se décale vers
  /// l'intérieur juste assez pour tenir dans l'écran (B89) ; le décalage se
  /// lit sur le rectangle de la carte ouverte AVANT décalage (spec §5.9).
  Vector2 get _targetPosition {
    final dropped = _droppedPosition;
    if (!_isInspected) return dropped;
    final open = _openRect(dropped);
    return dropped +
        Vector2(
          inspectionShift(
            left: open.left,
            right: open.right,
            screenWidth: game.size.x,
            devicePixelRatio: game.devicePixelRatio,
          ),
          0,
        );
  }
```

```dart
  /// Le rectangle de la carte ouverte à l'arrivée, décalée, barre et
  /// languettes au repos comprises, sur le canevas : ce que `GameScreen` lit
  /// pour placer le cadre de la fiche.
  Rect inspectionRect() => _openRect(_targetPosition);

  /// La zone au repos de la carte — canevas, barre, languettes au repos —, à
  /// l'échelle de base, centrée sur [center].
  Rect _openRect(Vector2 center) {
    var local = bodyLocalRect;
    if (isLoaded) {
      for (final tabs in [leftTabs, rightTabs]) {
        final rest = tabs.restLocalRect;
        if (rest != null) local = local.expandToInclude(rest);
      }
    }
    final s = baseScale;
    return Rect.fromLTRB(
      center.x + (local.left - size.x / 2) * s,
      center.y + (local.top - size.y / 2) * s,
      center.x + (local.right - size.x / 2) * s,
      center.y + (local.bottom - size.y / 2) * s,
    );
  }
```

  `bodyLocalRect` (`:204-205`) et ses deux voisins :

```dart
  @override
  Rect get bodyLocalRect => enemyZoneRect(frame);

  @override
  Rect get anchorLocalRect => enemyTemplateRect(frame);
```

  `onLoad`, en entier, tel qu'il est après les Tasks 4 à 6 :

```dart
  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    scale = Vector2.all(baseScale);

    final window = windowLocalRect;
    final windowPosition = Vector2(window.left, window.top);
    final windowSize = Vector2(window.width, window.height);

    final background = windowBackground;
    if (background != null) {
      add(
        _background = SpriteComponent(
          sprite: Sprite(await game.images.load(background)),
          position: windowPosition,
          size: windowSize,
          priority: 0,
        ),
      );
    }

    final creature = await game.images.load(data.spritePath);
    final fit = creatureFitOf(creature.width, creature.height);
    _smoothCreature = fit.smooth;
    sprite = SpriteComponent(
      sprite: Sprite(
        creature,
        srcPosition: Vector2(fit.source.left, fit.source.top),
        srcSize: Vector2(fit.source.width, fit.source.height),
      ),
      position: windowPosition.clone(),
      size: windowSize.clone(),
      priority: 1,
    );
    add(sprite);

    _frameSprite = SpriteComponent(
      sprite: Sprite(await game.images.load(frame.imagePath)),
      size: size.clone(),
      priority: 2,
    );
    add(_frameSprite);
    _refreshFiltering();

    outline = TargetOutline(window: window);
    add(outline);

    healthBar = EnemyHealthBar(anchorRect: anchorLocalRect);
    add(healthBar);

    addStatusTabs();
    refreshStatusTabs();

    _refreshHealthBar();

    // Les états visuels, maintenant que le contour existe.
    setSelection(isSelected);
    if (_isHighlighted) {
      _isHighlighted = false;
      setHighlight(true);
    }
  }
```

  Le contour, la surbrillance et la mise à jour remplacent `_refreshBorderVisuals` (`:353-364`), `setHighlight` et ses champs (`:372-386`), `update` (`:388-408`) et `render` (`:410-423`, supprimé) :

```dart
  void _refreshBorderVisuals() {
    if (_isInspected || isSelected) {
      outline.setStroke(Colors.amber, 4);
    } else if (_isHighlighted) {
      outline.setStroke(Colors.cyanAccent, 3);
    } else {
      // Au repos, rien : le liseré blanc a disparu (B78).
      outline.setStroke(null, 0);
    }
  }

  @override
  void flashArmorHit() => outline.setStroke(Colors.cyanAccent, 4);
```

```dart
  bool _isHighlighted = false;

  void setHighlight(bool highlight) {
    if (_isHighlighted == highlight) return;
    _isHighlighted = highlight;
    if (!isLoaded) return;
    outline.glowing = highlight;
    _refreshBorderVisuals();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Lu avant les effets de la carte, que Flame met à jour après elle : la
    // fin se constate à l'image qui suit celle où le retour s'est achevé.
    final returned = _returnAboveVeil;
    if (returned != null) {
      if (returned >= GameConstants.inspectionSeconds) {
        _returnAboveVeil = null;
        // La priorité du survol, et le sens du déroulé relu à la taille de repos.
        setHovered(isHovered);
      } else {
        _returnAboveVeil = returned + dt;
      }
    }
  }
```

  Les ancres de `buffAnimation` (`:433`) et de `frozenTurnAnimation` (`:462`) : `position + Vector2(0, -anchorLocalRect.height * scale.y / 2)`.

  `card_animator.dart:306` et `:315` : `size: Vector2(target.anchorLocalRect.width, target.anchorLocalRect.height) * 1.5` (et `enemy.` pour la seconde) — 132 × 180 au lieu de 150 × 210. `combat_visual_system.dart:54` : `radius: 1.5 * bearer.anchorLocalRect.width * bearer.scale.x` ; `:73-74` : `neighbour.position + Vector2(0, -neighbour.anchorLocalRect.height * neighbour.scale.y / 2)`.

- [ ] **Step 6 : les tests** (+14, −1).

  `test/unit/combat_tap_forwarding_test.dart`, réécrit en entier (4 tests → 3) :

```dart
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_health_bar.dart';
import 'package:roguelike_card_game/game/components/entities/status_tabs.dart';
import 'package:roguelike_card_game/game/systems/status_readout.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';

import 'tier_frame_fixture.dart';

/// La zone de la carte est son test d'appui (spec P-05 vague 2, A17) : ni la
/// barre ni les languettes ne prennent plus d'appui.
void main() {
  const gabarit = Rect.fromLTWH(16, 16, 88, 120); // le tier 5

  EnemyCard card(int tier) => EnemyCard(
        instance: EnemyInstance(
          id: 'e',
          data: const EnemyData(
            id: 'slime',
            maxHp: 18,
            baseDamage: 4,
            spritePath: 'slime.png',
          ),
          stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
        ),
        frame: testFrameOf(tier),
        windowBackground: null,
        onTapEnemy: (_, _) {},
      );

  test('ni la barre ni les languettes ne prennent d appui', () {
    expect(EnemyHealthBar(anchorRect: gabarit), isNot(isA<TapCallbacks>()));
    expect(
      StatusTabs(side: StatusSide.right, anchorRect: gabarit),
      isNot(isA<TapCallbacks>()),
    );
  });

  test('la zone de la carte recoit l appui jusqu au haut de sa barre, coins '
      'compris', () {
    final tier1 = card(1);
    expect(tier1.containsLocalPoint(Vector2(50, -2)), isTrue);
    expect(tier1.containsLocalPoint(Vector2(50, -18)), isFalse);

    // Au tier 2, la barre couvre x 4 à 92 ; les coins de part et d'autre,
    // au-dessus du canevas, sont à la carte.
    final tier2 = card(2);
    expect(tier2.containsLocalPoint(Vector2(2, -10)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(94, -10)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(2, -14)), isFalse);
    // Une épine du bord, un jour du cadre sous la fenêtre.
    expect(tier2.containsLocalPoint(Vector2(1, 60)), isTrue);
    expect(tier2.containsLocalPoint(Vector2(48, 125)), isTrue);
  });

  test('une languette deroulee vers l interieur garde son rectangle de repos '
      'dans la zone', () {
    final tabs = StatusTabs(side: StatusSide.right, anchorRect: gabarit);
    tabs.setEntries(const [
      StatusReadout(
        key: 'poison:',
        emoji: '🧪',
        restValue: '3',
        tone: ReadoutTone.debuff,
        title: 'Poison 3',
      ),
    ]);
    tabs.setUnfolded(true, inward: true);

    // Dans la carte : 120 est dans le rectangle de repos (103 à 133), hors du
    // rectangle dessiné, qui finit au bord droit du gabarit (104).
    const inRest = Offset(120, 30);
    expect(tabs.localRect!.contains(inRest), isFalse);
    expect(tabs.restLocalRect!.contains(inRest), isTrue);
    expect(tabs.zoneLocalRects.any((r) => r.contains(inRest)), isTrue);
    expect(
      tabs.zoneLocalRects.any((r) => r.contains(const Offset(150, 30))),
      isFalse,
    );
  });
}
```

  `test/unit/entity_hover_test.dart:80-86`, réécrit sur la zone du tier 1 (le compte ne change pas) :

```dart
  test('la bande entre la barre et la carte appartient a l ennemi', () {
    final zone = enemyZoneRect(testFrameOf(1));

    expect(zone.contains(const Offset(50, -2)), isTrue);
    expect(zone.contains(const Offset(50, 119)), isTrue);
    expect(zone.contains(const Offset(50, -18)), isFalse);
  });
```

  `test/unit/target_outline_test.dart` (2) :

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/target_outline.dart';

void main() {
  const window = Rect.fromLTWH(20, 20, 64, 96);

  test('au repos, rien', () {
    final outline = TargetOutline(window: window);
    expect(outline.strokeRect, isNull);
    outline.setStroke(Colors.amber, 4);
    outline.setStroke(null, 0);
    expect(outline.strokeRect, isNull);
  });

  test('le trait se pose a l exterieur de la fenetre', () {
    final outline = TargetOutline(window: window)
      ..setStroke(Colors.amber, 4);
    expect(outline.strokeRect, window.inflate(2));
    // Le bord intérieur du trait tombe sur le bord de la fenêtre.
    expect(outline.strokeRect!.deflate(2), window);

    outline.setStroke(Colors.cyanAccent, 3);
    expect(outline.strokeRect, window.inflate(1.5));
    expect(outline.color, Colors.cyanAccent);
  });
}
```

  `test/unit/enemy_row_test.dart` (+6) :

```dart
  group('inspectionShift (B89)', () {
    test('nul quand la carte tient, aux deux bords exacts compris', () {
      expect(inspectionShift(left: 100, right: 400, screenWidth: 1920), 0);
      expect(inspectionShift(left: 0, right: 400, screenWidth: 1920), 0);
      expect(inspectionShift(left: 1500, right: 1920, screenWidth: 1920), 0);
    });

    test('cinq places en 1080p : la carte ouverte du bord tient, bord droit a '
        '1864', () {
      final xs = placeRow(
        slots: List.filled(5, slotOf(testFrameOf(1))),
        unit: 2,
        screenWidth: 1920,
      );
      final right = xs.last + 73 * 4;
      expect(right, 1864);
      expect(inspectionShift(left: right - 584, right: right, screenWidth: 1920), 0);
    });

    test('la carte du bord droit d une rangee de six en 1080p se decale de 97 '
        'vers la gauche', () {
      final xs = placeRow(
        slots: List.filled(6, slotOf(testFrameOf(1))),
        unit: 2,
        screenWidth: 1920,
      );
      final right = xs.last + 73 * 4;
      expect(right, 2017);
      final shift =
          inspectionShift(left: right - 584, right: right, screenWidth: 1920);
      expect(shift, -97);
      expect(right + shift, 1920);
    });

    test('la carte du bord gauche, symetrique : +97', () {
      expect(inspectionShift(left: -97, right: 487, screenWidth: 1920), 97);
    });

    test('une carte plus large que l ecran se centre', () {
      final shift = inspectionShift(left: 100, right: 2100, screenWidth: 1920);
      expect(100 + shift, -40);
      expect(2100 + shift, 1960);
    });

    test('a 1,25, la grandeur s arrondit au pixel physique superieur', () {
      final right = inspectionShift(
        left: 1300,
        right: 1536.3,
        screenWidth: 1536,
        devicePixelRatio: 1.25,
      );
      expect(right, -0.8);
      expect(1536.3 + right, lessThanOrEqualTo(1536));
      final left = inspectionShift(
        left: -0.3,
        right: 200,
        screenWidth: 1536,
        devicePixelRatio: 1.25,
      );
      expect(left, 0.8);
      expect(-0.3 + left, greaterThanOrEqualTo(0));
    });
  });
```

  `test/unit/heros_draft_game_targeting_test.dart` (+6), à la fin de `main` (le jeu de `setUp` en 1280 × 800, palier 1,3348 lissé ; cartes jamais montées : leur zone au repos est le canevas et la barre) :

```dart
  test('la carte ouverte qui sortirait se decale : le decalage se lit sur le '
      'rectangle avant decalage, inspectionRect rend le rectangle decale', () {
    game.enemyCards.add(e1);
    e1.place(Vector2(1250, 168));

    game.handlePlayerTargeting(e1, 1);

    // Ouverte à 2 × 1,3348, la carte de 88 de large déborde de 87,46 à
    // droite : décalée de 88 vers la gauche, son bord droit à 1279,46.
    final rect = inspections.single!.rect;
    expect(rect.right, lessThanOrEqualTo(1280));
    expect(rect.right, greaterThan(1279));
    expect(rect.center.dx, closeTo(1250 - 88, 1e-6));
    expect(e1.inspectionRect(), rect);
  });

  for (var tier = 1; tier <= 5; tier++) {
    test('tier $tier : la carte ouverte est au double, sa descente garde le '
        'haut de sa barre', () {
      final enemy = _enemy(game, 'e$tier', tier: tier);
      game.enemyCards.add(enemy);
      enemy.place(Vector2(640, 300));
      final f = game.boardScale.frame;

      game.handlePlayerTargeting(enemy, 1);

      expect(enemy.baseScale, closeTo(2 * enemy.restScale, 1e-12));
      // 1e-3 : la place passe par `Vector2`, en Float32
      // (`vector_math-2.2.0/lib/src/vector_math/vector2.dart:9`).
      expect(inspections.single!.rect.top, closeTo(300 - 77 * f, 1e-3));
    });
  }
```

- [ ] **Step 7 : faire rougir, puis vert.** Avant les Steps 1 à 5, les tests du Step 6 échouent à la compilation (`flutter test test/unit/combat_tap_forwarding_test.dart test/unit/target_outline_test.dart test/unit/enemy_row_test.dart test/unit/heros_draft_game_targeting_test.dart test/unit/entity_hover_test.dart`) ; après, verts.

- [ ] **Step 8 : le rejeu sur cartes montées** (Review Focus 1 à 4, D1). Écrire `test/unit/jetable_cartes_montees_test.dart`, le jouer seul, recopier ses lignes `print` dans le message de commit, **puis le supprimer** :

```dart
// JETABLE (plan P-05 vague 2, Task 6, D1) : jamais commite.
// ignore_for_file: invalid_use_of_internal_member, avoid_print
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/game/systems/entity_hover.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/data/game_data_registry.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/models/status_effect.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';
import 'package:roguelike_card_game/services/game_data_service.dart';

late GameDataRegistry registry;
final inspections = <EnemyInspection?>[];

Future<HerosDraftGame> mountGame(Vector2 screen) async {
  inspections.clear();
  final game = HerosDraftGame(
    audio: AudioDirector(
      backend: const SilentAudioBackend(),
      data: const AudioData.disabled(),
      settings: () => const AudioSettings(),
    ),
    imagesToPreload: registry.imagesToPreload,
    chargeCatalog: registry.charges,
    tierFrames: registry.tierFrames,
    location: registry.locations.current,
    onEnemiesDead: () {},
    onPhaseChanged: (_) {},
    onShowTooltip: (_, _, _) {},
    onHideTooltip: () {},
    onPlayCard: (_, _) => false,
    onEnemyKilled: () {},
    onResolveEnemyIntent: (_) {},
    onStartEnemyTurn: () => false,
    onResolveFireWave: () => false,
    onResolveEnemyStatuses: () {},
    onEndEnemyTurn: () {},
    onSelectEnemy: (_) {},
    onUpdateEnemyStats: (_, _) {},
    onInspectionChanged: inspections.add,
  );
  game.onGameResize(screen);
  await game.load();
  game.mount();
  game.update(0);
  await game.ready();
  return game;
}

/// Les deux plateaux de cinq cartes : les tiers 1 à 5 — le Slime, le
/// Squelette, l'Orc, et deux ennemis fictifs de tiers 4 et 5 sur le sprite du
/// Slime — et les tiers 1, 1, 2, 3, 3 de la spec (Review Focus, l. 931-932) —
/// le Slime, le Gobelin, le Squelette et deux Orcs. Le dernier porte un
/// Poison, sa languette droite au repos.
const configs = {
  'tiers 1 a 5': ['slime', 'squelette', 'orc', 't4', 't5'],
  'tiers 1, 1, 2, 3, 3': ['slime', 'gobelin', 'squelette', 'orc', 'orc'],
};

Future<List<EnemyCard>> addFive(HerosDraftGame game, List<String> ids) async {
  EnemyData real(String id) => registry.enemies.firstWhere((e) => e.id == id);
  final slime = real('slime');
  EnemyData dataOf(String id) => switch (id) {
        't4' => EnemyData(id: 't4', maxHp: 10, baseDamage: 1, spritePath: slime.spritePath, tier: 4),
        't5' => EnemyData(id: 't5', maxHp: 10, baseDamage: 1, spritePath: slime.spritePath, tier: 5),
        _ => real(id),
      };
  final datas = [for (final id in ids) dataOf(id)];
  final cards = [
    for (var i = 0; i < datas.length; i++)
      EnemyCard(
        instance: EnemyInstance(
          id: 'e$i',
          data: datas[i],
          stats: EntityStats(
            maxPv: 10,
            currentPv: 10,
            armure: 0,
            might: 0,
            statuses: i == 4
                ? const [
                    StatusEffect(
                      id: 'poison',
                      name: 'Poison',
                      type: StatusType.debuff,
                      value: 3,
                      duration: 3,
                    ),
                  ]
                : const [],
          ),
        ),
        frame: registry.tierFrames.of(datas[i].tier)!,
        windowBackground: registry.locations.current!.windowBackgrounds.first,
        onTapEnemy: (_, _) {},
      ),
  ];
  game.enemyCards.addAll(cards);
  await game.addAll(cards);
  await game.ready();
  game.repositionEnemies();
  game.update(0);
  return cards;
}

void settle(HerosDraftGame game) {
  for (var i = 0; i < 30; i++) {
    game.update(0.05);
  }
}

SpriteComponent layer(EnemyCard card, int priority) => card.children
    .whereType<SpriteComponent>()
    .firstWhere((s) => s.priority == priority);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => registry = await loadGameDataRegistry(rootBundle));

  // Les tolérances, 1e-4 sur une échelle et 1e-3 sur une position, sont
  // celles du Float32 : `Vector2` y range ses composantes
  // (`vector_math-2.2.0/lib/src/vector_math/vector2.dart:9`), si bien que
  // 1,3347969264 est rangé en 1,3347969055, et que 381 revient en 381,0000305
  // après des déplacements additionnés en Float32. Un écart sous ces
  // tolérances n'est pas un bogue.
  for (final MapEntry(key: config, value: ids) in configs.entries) {
  for (final screen in [
    Vector2(1920, 1080),
    Vector2(1920, 1009),
    Vector2(1280, 720),
    Vector2(1264, 681),
  ]) {
    test('cartes montees, $config, en ${screen.x} x ${screen.y}', () async {
      final game = await mountGame(screen);
      final cards = await addFive(game, ids);
      final f = game.boardScale.frame;
      final y = cards.first.position.y;

      for (final c in cards) {
        // Le même sol, le palier, le même haut de barre (B72, B77).
        expect(c.position.y, y);
        expect(c.scale.x, closeTo(f, 1e-4));
        expect(c.healthBar.absolutePosition.y, closeTo(y - 77 * f, 1e-3));
        // L'ordre des enfants (§5.3).
        expect(c.outline.priority, 3);
        expect(c.healthBar.priority, 7);
        expect(c.leftTabs.priority, 6);
        expect(layer(c, 1), same(c.sprite));
        expect(layer(c, 2).size, c.size);
        // Au repos, aucun trait.
        expect(c.outline.strokeRect, isNull);
      }
      // Des places disjointes, dans l'écran, languettes au repos comprises.
      for (var i = 1; i < cards.length; i++) {
        expect(
          cards[i].position.x - cards[i - 1].position.x,
          greaterThanOrEqualTo(153 * f - 1),
        );
      }
      expect(cards.first.position.x - 73 * f, greaterThanOrEqualTo(0));
      expect(cards.last.position.x + 73 * f, lessThanOrEqualTo(screen.x));

      // La zone reçoit l'appui : coins au-dessus du canevas, épine, jour du
      // cadre, bande entre la barre et le gabarit (la carte de tier 2).
      final t2 = cards.firstWhere((c) => c.frame.tier == 2);
      for (final local in [
        Vector2(2, -10),
        Vector2(94, -10),
        Vector2(1, 60),
        Vector2(48, 2),
      ]) {
        final hit = game
            .componentsAtPoint(t2.absolutePositionOf(local))
            .whereType<TapCallbacks>()
            .first;
        expect(hit, same(t2), reason: 'point $local');
      }

      // Le contour : ambre à la sélection, cyan au coup sur l'armure.
      t2.setSelection(true);
      expect(t2.outline.strokeRect, enemyWindowRect(t2.frame).inflate(2));
      t2.flashArmorHit();
      expect(t2.outline.color, Colors.cyanAccent);
      t2.setSelection(false);

      // La carte ouverte : la dernière, sa languette au repos.
      final last = cards.last;
      final barTop = last.healthBar.absolutePosition.y;
      game.inspectEnemy(last);
      settle(game);
      expect(last.scale.x, closeTo(2 * f, 1e-4));
      expect(last.healthBar.absolutePosition.y, closeTo(barTop, 0.01));
      final rect = inspections.last!.rect;
      expect(rect, last.inspectionRect());
      expect(rect.right, lessThanOrEqualTo(screen.x));
      print('$config, ${screen.x}x${screen.y} : palier $f net '
          '${game.boardScale.crisp}, '
          'centres ${[for (final c in cards) c.position.x]}, y $y, '
          'carte ouverte $rect');

      // Un coup sur la carte ouverte la ramène au double, pas au palier.
      last.shakeAndFlashAnimation();
      settle(game);
      expect(last.scale.x, closeTo(2 * f, 1e-4));

      // Une reconstruction à taille égale ne coupe ni l'agrandissement ni la
      // descente.
      game.closeInspection();
      settle(game);
      game.inspectEnemy(last);
      game.update(0.05);
      game.onGameResize(screen);
      settle(game);
      expect(last.scale.x, closeTo(2 * f, 1e-4));
      expect(last.position.y, closeTo(last.restPosition.y + 77 * f, 1e-3));
    });
  }
  }

  test('le filtrage bascule avec le palier', () async {
    final game = await mountGame(Vector2(1920, 1080));
    final cards = await addFive(game, configs.values.first);
    final c = cards.first;
    expect(layer(c, 2).paint.filterQuality, FilterQuality.none);
    expect(layer(c, 0).paint.filterQuality, FilterQuality.none);
    expect(c.sprite.paint.filterQuality, FilterQuality.medium);
    game.onGameResize(Vector2(1280, 720));
    expect(layer(c, 2).paint.filterQuality, FilterQuality.medium);
    expect(layer(c, 0).paint.filterQuality, FilterQuality.medium);
    game.onGameResize(Vector2(1920, 1080));
    expect(layer(c, 2).paint.filterQuality, FilterQuality.none);
  });
}
```

  Commande : `flutter test test/unit/jetable_cartes_montees_test.dart` → `+9: All tests passed!` (deux plateaux sur quatre écrans, et le filtrage), et huit lignes `print`. Ses tolérances sont celles du Float32 de `Vector2` (le commentaire de `main`) : un écart plus fin n'est pas à chercher. Attendu, pour les deux plateaux, toutes les places valant 146 : en 1920 × 1080, palier 2 net, centres 348 à 1572 au pas de 306, y 227, carte ouverte bornée à droite par 1864 ; en 1920 × 1009, palier 2, y 212 ; en 1280 × 720, palier ≈ 1,3348 lissé ; en 1264 × 681, palier ≈ 1,3181 lissé, centres 228 à 1036 au pas de 202, carte ouverte bornée à droite vers 1228, décalage nul. Un écart se corrige dans le code de la tâche, et le rejeu reprend. Puis `Remove-Item test/unit/jetable_cartes_montees_test.dart`.

- [ ] **Step 9 : vérifier.** `git status --short test` ne montre pas le fichier jetable ; `git grep -n -e enemyBodyRect -e "borderInfo" -- lib/game/components/entities/enemy_card.dart lib/game/components/entities/combat_entity.dart lib/game/systems test` → rien ; `git grep -n "TapCallbacks" -- lib/game/components/entities/enemy_health_bar.dart lib/game/components/entities/status_tabs.dart` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **2020** (2007 + 14 − 1).
- [ ] **Step 10 : commit.** `feat(bestiaire): la barre, les languettes, la zone, le contour et la fiche sur la fenetre`, le corps du message portant les huit lignes du rejeu monté.

### Task 7: La documentation de `art_src/`

**Files :**
- Modify : `art_src/tools/README.md:38-78` (le tableau des commandes), `:80-120` (le tableau des fichiers) ; `art_src/docs/workflow_decor.md:204` ; `art_src/docs/workflow_fond.md` (le livrable et son chemin) ; `art_src/docs/workflow_creature.md:242`, `:347`
- `art_src/tools/decor_controle.py` n'est pas retouché (§12).

**Interfaces :**
- Consumes : `export_jeu.py` et les neuf chemins de §10.2 (Task 1).

- [ ] **Step 1 : le README des outils.** Une ligne au tableau des commandes, `python export_jeu.py <source.aseprite> <cible.png> [--taille LxH]`, qui dit ce qu'il fait (§10.1 : les calques visibles aplatis, la liste des exportés et des masqués, le refus d'une autre taille, aucune couleur convertie) ; une ligne au tableau des fichiers.
- [ ] **Step 2 : les trois workflows.** `workflow_decor.md`, étape 7 (`:204`) : la phrase « Le chemin … est fixé par la vague qui pose le décor dans le jeu » devient la commande d'export vers `assets/data/locations/<lieu>/combat.png`, 640 × 360, couleurs peintes gardées (B80), et la note qu'un autre écran reçoit son décor en déposant `<écran>.png` dans le même dossier (A6, les noms de `DecorScreen`). `workflow_fond.md` : le livrable va à `assets/data/locations/<lieu>/window_<1-3>.png`, 128 × 192, trois par lieu (B67), par la même commande. `workflow_creature.md`, à `:242` et à la ligne « le livrable » de `:347` : `sprites/<famille>/tier_<n>/<nom>.aseprite` → `assets/data/enemies/<id>/sprite.png`, 128 × 192, Ombre et Liseré visibles (§10.2), par la même commande avec `--taille 128x192`.
- [ ] **Step 3 : vérifier.** `git diff --stat` ne nomme que les quatre fichiers de la tâche ; `git grep -n -F "par la vague qui pose le décor dans le jeu" -- art_src` → rien (avant la tâche, il trouve `art_src/docs/workflow_decor.md:204`) ; `dart analyze` → `No issues found!` ; `flutter test` → **2020**.
- [ ] **Step 4 : commit.** `docs(art): le chemin des cadres, des fonds et du decor vers le jeu`.

### Task 8: La vérification finale

**Files :** aucun, sauf correction d'un écart trouvé ici, par un commit de correction au nom de la tâche fautive.

- [ ] **Step 1 : les commandes.** `dart analyze` → `No issues found!` ; `flutter test` → **2020**, `All tests passed!` ; `dart run tool/sync_assets.dart --check` → code 0.
- [ ] **Step 2 : les contrôles de la spec, §13.**
  - `git diff e2a96432 -- lib/game/controllers lib/game/services` → rien ;
  - `git diff e2a96432 --stat -- assets/data` → seuls `tier_frames.json`, `frames/` et `locations/` (la note de version n'est pas de ce plan) ;
  - `git diff e2a96432 --stat -- lib/models` → seuls `tier_frame_data.dart`, `location_data.dart`, `game_data_registry.dart` ;
  - `git grep -n -e bg_dungeon -e scaleMultiplier -e visualWidthPerEnemy -e enemyBodyRect -- lib test` → rien ;
  - `git diff e2a96432 -- test | grep -c '^+.*testWidgets(' || true` → `0` ;
  - `git diff e2a96432 --stat -- windows macos linux` → seulement `windows/runner/win32_window.cpp` ;
  - `git status --short` → propre, aucun `generated_plugin*` ni `GeneratedPluginRegistrant.swift` modifié, pas de `jetable_cartes_montees_test.dart`.
- [ ] **Step 3 : rendre** le total de tests, les huit lignes du rejeu monté (Task 6), et les tests manuels M1 à M22 de la spec (§11.2) à reprendre dans le fichier de tests manuels de la vague.
