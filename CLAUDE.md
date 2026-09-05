# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Hero's Draft" is a roguelike deckbuilder built with **Flutter**, using the **Flame** engine for game rendering and **Riverpod** for state management. It features turn-based combat, hero classes with unique passives, a procedural world map, relics, a shop, narrative events, and a full deckbuilding/forge loop. The game is **100% data-driven**: cards, enemies, heroes, relics, passives, events, forge upgrades, and patch notes are all defined in JSON under `assets/data/` rather than hardcoded.

## Commands

- Install dependencies: `flutter pub get`
- Run the app: `flutter run`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/unit/combat_controller_test.dart`
- Run a single test by name: `flutter test --plain-name "test description"`
- Lint/analyze: `dart analyze` — **must be run and be clean (zero issues) after any code change**, before considering work done
- Build: `flutter build <apk|ios|web|windows|macos|linux>`

Lint rules come from `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`).

## Architecture

The codebase strictly separates three layers — never mix them:

- **Rendering (Flame)** — `lib/game/`
  - `HerosDraftGame` is the root game class orchestrating all Flame components.
  - `lib/game/components/` — `CardComponent`, `FloatingText`, `EffectIcon`, entity components (`entities/`), particle/shake/juice effects (`visual_effects/`), Flame-hosted widgets (`widgets/`).
  - `lib/game/systems/` — standalone game systems.
  - `lib/game/services/` (incl. `effects/`) — game-level services.
  - Flame components are visual/reactive only: they read Riverpod state and render it, they never own game logic.

- **State & business logic (Riverpod)** — `lib/game/controllers/`
  - `RunController` — run-wide state (health, mana, armor, buffs, map position, relics); split into focused managers under `run/`: `player_stats_manager.dart`, `map_progression_manager.dart`, `gold_manager.dart`.
  - `DeckNotifier` (`deck_controller.dart`) — hand/draw/discard/exhaust pile management.
  - `CombatController` — turn flow, enemy intents, damage resolution; split into `combat/status_effect_processor.dart` and `combat/turn_phase_manager.dart`.
  - `RewardController` — post-combat rewards and relic choices.
  - `ShopController` — shop inventory/purchases.
  - `EventController` — random narrative event resolution.
  - `InventoryController` — relic inventory.
  - `CheckpointNotifier` (`checkpoint_controller.dart`) — `checkpointProvider` / `autosaveOrchestratorProvider`: triggers the autosave when a map node is resolved.
  - All shared/business state lives in Riverpod 2.x `Notifier`s here (`extends Notifier<T>`, exposed via `NotifierProvider`) — never in UI widgets or Flame components, and never as global variables/singletons. The migration off `StateNotifier` is complete for the controllers; the only remaining `StateNotifier` is the UI-local toast queue in `lib/ui/widgets/notification_overlay.dart`, which holds no business state. Do not add new ones.

- **Data layer** — `lib/models/data/` holds models mapping 1:1 to the JSON assets (`card_data.dart`, `enemy_data.dart`, `hero_data.dart`, `relic_data.dart`, `passive_data.dart`, `event_data.dart`, `forge_upgrade_data.dart`, `audio_data.dart`), aggregated via `game_data_registry.dart`. `lib/models/` (top level) holds runtime instances/state (`card_instance.dart`, `enemy_instance.dart`, `combat_state.dart`, `status_effect.dart`, etc.).

- **Services** — `lib/services/`
  - `gameDataLoaderProvider` (`game_data_service.dart`) — a `FutureProvider<GameDataRegistry>` that async-loads and caches all JSON asset data at startup. There is no `GameDataService` class; the provider *is* the entry point. `loadGameDataRegistry(bundle)` is the **single declaration of the game's entity sources**; production and the tutorial test registry both go through it.
  - `GameDataLoader` / `EntitySource` (`game_data_loader.dart`) — the generic loader. An `EntitySource` is an asset **path pattern** plus a `fromJson`: the pattern both selects the files and injects the fields the directory imposes, from the segments it captures (`*` matches exactly one segment, so segment count alone separates `classes/*/class.json` from `classes/*/cards/*.json`). Errors are accumulated across every category and raised once by `throwIfFailed()`. The `bundle` is a parameter rather than a hardcoded `rootBundle` — that is the seam that makes the loader testable on a chosen asset tree.
  - `MapGeneratorService` plus `lib/services/map/` (`map_node_generator.dart`, `map_connection_builder.dart`, `map_content_placer.dart`, `map_validator.dart`) — procedural world-map generation, decomposed into generate → connect → place-content → validate stages.
  - `SaveService` (`lib/services/save_service.dart`) — serialises `RunState`/`DeckState`/`InventoryState`, three keys, into a single versioned JSON blob under one `shared_preferences` key. Never called mid-combat.

- **UI (Flutter)** — `lib/ui/`
  - `lib/ui/screens/` — Home, Splash, ClassSelection, Map, Game, Draft, StarterDeckDraft, BossCardDraft, Deck (`deck_screen.dart`), Shop, Event, Rest/RestCardSelection, RelicExchange, PatchNotes, CardDictionary, ForgeFusion.
  - `lib/ui/widgets/` — reusable widgets, grouped by feature (`draft/`, `forge/`, `hud/` incl. `hud/dialogs/`, `map/` incl. `map/dialogs/`, `relic_carousel/`, `ui_card/`).
  - `lib/ui/theme/` — app-wide theme/design tokens (`app_theme.dart`).
  - UI widgets and Flame components must stay decoupled: no Flame references inside UI code, no Flutter widget trees inside Flame components.

- **Showcase site** — `site/` — a static site served from the VPS root, with no build step and no npm dependency. `site/_site/versions.json` is its source of truth; `site/_site/js/model.js` holds the pure logic and is tested with `node --test` run from `site/`. Deployed by `.github/workflows/site.yml`, never by hand. No link to the game code.

- **Tooling** — `tool/` — a single script, `sync_assets.dart`, which regenerates `pubspec.yaml`'s `assets:` section from the real contents of `assets/`. Flutter's asset declarations are not recursive at any level, so every class and enemy folder needs its own line; an undeclared folder loads in development and silently vanishes from a build. `--check` exits 1 if the section has drifted. Covered by `test/unit/sync_assets_test.dart`.

- **Tutorial system** — `lib/tutorial/` (with `widgets/`) — onboarding/tutorial engine, separate from the main game loop.

- **Localization** — dual system:
  - `lib/l10n/` (ARB files) drives Flutter-widget-level UI strings via `flutter_localizations`/`intl`.
  - All game *content* (card/enemy/relic/event/passive text) is localized inline in the JSON data as bilingual key pairs, not via ARB. **Every JSON entry with user-facing text must include both `_fr` and `_en` variants**, and the corresponding Dart model in `lib/models/data/` must be updated whenever a JSON schema changes.
  - Supported locales: French and English.

- **Persistence** — `shared_preferences` for run state and settings (see `SaveService`, `lib/services/save_service.dart`).

## Data-Driven Content Workflow

**One entity, one file, and the directory carries the ownership.** A card filed under `assets/data/classes/paladin/cards/` *is* a paladin card — the loader injects that from the path, and a JSON claiming otherwise fails to load.

```
assets/data/
├── audio.json, patch_notes.json    # flat: single configuration documents, not catalogues
├── cards/<id>.json                 # neutral cards; likewise relics/, events/,
│                                   #   forge_upgrades/, passives/
├── classes/<id>/{class.json, icon.png, cards/<id>.json}
└── enemies/<id>/{enemy.json, sprite.png}
```

To add or modify a card, enemy, hero, relic, passive, event or forge upgrade:

1. **Create a file** in the right directory, shaped like a neighbouring entry. The filename **is** the `id` (`relics/iron_talisman.json` → `"id": "iron_talisman"`), in lowercase ASCII `snake_case` — enforced by `test/unit/entity_id_convention_test.dart`. For a class or an enemy it is a **folder** you create, image included, and the `id` comes from the folder name.
2. **Run `dart run tool/sync_assets.dart`** to regenerate `pubspec.yaml`'s `assets:` section — a new class or enemy folder needs its own line, and an undeclared one fails silently at build time.

No business-logic code needs to change for pure content additions. Never write a field the directory imposes: `heroClass` and `category` in a card file fail the load. Only `id` may be restated, and only identically — it makes the file readable out of context.

`patch_notes.json` is the one exception to all of the above — it stays flat (array order *is* the semantics: index 0 is the current version) and is agent-managed; see below.

## Documentation Map

One question, one place. Never duplicate a fact across two of these — link instead.

| Question | Location |
|:---|:---|
| Where to start | `.obsidian_vault/_memory_bank/` — five short files, three of them indexes |
| Every document written on one subject | `docs/INDEX.md` — thematic index of `docs/`, links only, never facts |
| Why a decision was taken | `.obsidian_vault/_adr/` — one file per ADR, indexed by `_memory_bank/decisionLog.md` |
| A game rule | `.obsidian_vault/_rules/` — one sheet per system, indexed by `_memory_bank/productContext.md` |
| An architecture pattern | `.obsidian_vault/_patterns/` — one sheet per area, indexed by `_memory_bank/systemPatterns.md` |
| What is built, and the project metrics | `_memory_bank/progress.md` — every figure carries the date it was measured |
| What is being worked on right now | `_memory_bank/activeContext.md` — current focus plus the last three deliveries, nothing older |
| What is left to do | `docs/ROADMAP.md` — **the single planning source** |
| What is designed but not built | `docs/superpowers/specs/` and `docs/superpowers/plans/` |
| What is explored but not decided | `docs/possible_upgrades/` |
| What the player sees | `assets/data/patch_notes.json` |
| Frozen history | `.obsidian_vault/_archive/` and `docs/archives/` — read-only |

The three index files are capped and deliberately short: they exist to be read whole, then to point you at the one sheet you actually need. Never inline a sheet's content back into its index.

`CLAUDE.md` is the authoritative agent instruction file for this repository.

## Repo-Specific Conventions

- **`patch_notes.json` is agent-managed**: never hand-edit it. It is maintained by the `patch-notes-writer` skill (`.claude/skills/patch-notes-writer/SKILL.md`), which prepends a new semver entry, writes player-facing French only, keeps `pubspec.yaml`'s `version:` field in sync with it, and adds the matching `current` entry to `site/_site/versions.json` while demoting the previous one to `stable`. Those three files carry the version number and must always move together in a single commit: `verify_version.sh` fails the release if any of them disagrees. The skill also refreshes three hardcoded fallback links, in `site/index.html` and `site/versions.html`, to match.
- **The memory bank is agent-managed**: `.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/` and `_patterns/` are maintained by the `memory-bank-sync` skill (`.claude/skills/memory-bank-sync/SKILL.md`). It re-measures every metric with a command before writing it, enforces per-file line caps, and archives rather than appends. `.obsidian_vault/_archive/` is read-only.
- **`.agents/`** holds exactly one file, `.agents/skills/game_designer.md`, defining a `game_designer` skill. The empty run-artifact directories of a past multi-agent workflow that this entry used to warn about are gone.
- Favor non-blocking animations in Flame code (`Effect`, `Future.delayed` inside `async` methods) — never block the game loop.
- Use `priority` on Flame components to manage z-ordering (e.g. background at `-100`, floating text high).
- Use `FutureProvider` for async resource loading through Riverpod.
- No dead code, unused imports, or commented-out blocks in committed code.
