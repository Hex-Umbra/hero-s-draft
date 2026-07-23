# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"Hero's Draft" is a roguelike deckbuilder built with **Flutter**, using the **Flame** engine for game rendering and **Riverpod** for state management. It features turn-based combat, hero classes with unique passives, a procedural world map, relics, a shop, narrative events, and a full deckbuilding/forge loop. The game is **100% data-driven**: cards, enemies, heroes, skills, relics, events, and patch notes are all defined in JSON under `assets/data/` rather than hardcoded.

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
  - `RunController` — run-wide state (health, mana, armor, buffs, map position, relics); split into focused managers under `run/`: `player_stats_manager.dart`, `map_progression_manager.dart`, `gold_manager.dart`, `run_persistence_manager.dart`.
  - `DeckController` — hand/draw/discard/exhaust pile management.
  - `CombatController` — turn flow, enemy intents, damage resolution; split into `combat/status_effect_processor.dart` and `combat/turn_phase_manager.dart`.
  - `RewardController` — post-combat rewards and relic choices.
  - `ShopController` — shop inventory/purchases.
  - `EventController` — random narrative event resolution.
  - `InventoryController` — relic inventory.
  - `SkillController` — hero skill management.
  - All shared/business state lives in `StateNotifier`s here — never in UI widgets or Flame components, and never as global variables/singletons.

- **Data layer** — `lib/models/data/` holds models mapping 1:1 to the JSON assets (`card_data.dart`, `enemy_data.dart`, `hero_data.dart`, `relic_data.dart`, `skill_data.dart`, `event_data.dart`, `forge_upgrade_data.dart`, etc.), aggregated via `game_data_registry.dart`. `lib/models/` (top level) holds runtime instances/state (`card_instance.dart`, `enemy_instance.dart`, `combat_state.dart`, `status_effect.dart`, etc.).

- **Services** — `lib/services/`
  - `GameDataService` — async loads and caches all JSON asset data at startup.
  - `MapGeneratorService` plus `lib/services/map/` (`map_node_generator.dart`, `map_connection_builder.dart`, `map_content_placer.dart`, `map_validator.dart`) — procedural world-map generation, decomposed into generate → connect → place-content → validate stages.

- **UI (Flutter)** — `lib/ui/`
  - `lib/ui/screens/` — Home, Splash, ClassSelection, Map, Game, Draft, StarterDeckDraft, BossCardDraft, DeckView, Shop, Event, Rest/RestCardSelection, RelicExchange, PatchNotes, CardDictionary.
  - `lib/ui/widgets/` — reusable widgets, grouped by feature (`draft/`, `forge/`, `hud/` incl. `hud/dialogs/`, `map/` incl. `map/dialogs/`, `relic_carousel/`, `ui_card/`).
  - `lib/ui/theme/` — app-wide theme/design tokens (`app_theme.dart`).
  - UI widgets and Flame components must stay decoupled: no Flame references inside UI code, no Flutter widget trees inside Flame components.

- **Tutorial system** — `lib/tutorial/` (with `widgets/`) — onboarding/tutorial engine, separate from the main game loop.

- **Localization** — dual system:
  - `lib/l10n/` (ARB files) drives Flutter-widget-level UI strings via `flutter_localizations`/`intl`.
  - All game *content* (card/enemy/relic/event/skill text) is localized inline in the JSON data as bilingual key pairs, not via ARB. **Every JSON entry with user-facing text must include both `_fr` and `_en` variants**, and the corresponding Dart model in `lib/models/data/` must be updated whenever a JSON schema changes.
  - Supported locales: French and English.

- **Persistence** — `shared_preferences` for run state and settings (see `run_persistence_manager.dart`).

## Data-Driven Content Workflow

To add or modify cards, enemies, heroes, relics, skills, or events: edit the relevant JSON file in `assets/data/`, following the shape of an existing entry. No business-logic code needs to change for pure content additions. `patch_notes.json` is the one exception — see below.

## Repo-Specific Conventions

- **`patch_notes.json` is agent-managed**: it should not be hand-edited directly. It's maintained by the `patch_notes_writer` sub-agent skill (`.agents/skills/patch_notes_writer.md`), which by default prepends a new semver entry, only writes player-facing French text, and touches no other file.
- **Memory bank**: `.obsidian_vault/_memory_bank/` contains living product documentation (`productContext.md`, `systemPatterns.md`, `activeContext.md`, `progress.md`, `decisionLog.md`) maintained by the `business_analyst_product_manager` skill (`.agents/skills/business_analyst_product_manager.md`). Treat it as a source of product/design context, not code.
- **`.agents/`** also defines a `game_designer` skill; other subfolders there (`orchestrator`, `worker_m1`, `auditor_m1`, etc.) are empty run-artifact directories from a past multi-agent workflow, not templates to follow.
- Favor non-blocking animations in Flame code (`Effect`, `Future.delayed` inside `async` methods) — never block the game loop.
- Use `priority` on Flame components to manage z-ordering (e.g. background at `-100`, floating text high).
- Use `FutureProvider` for async resource loading through Riverpod.
- No dead code, unused imports, or commented-out blocks in committed code.
