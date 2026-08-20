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
  - `RunController` — run-wide state (health, mana, armor, buffs, map position, relics); split into focused managers under `run/`: `player_stats_manager.dart`, `map_progression_manager.dart`, `gold_manager.dart`.
  - `DeckNotifier` (`deck_controller.dart`) — hand/draw/discard/exhaust pile management.
  - `CombatController` — turn flow, enemy intents, damage resolution; split into `combat/status_effect_processor.dart` and `combat/turn_phase_manager.dart`.
  - `RewardController` — post-combat rewards and relic choices.
  - `ShopController` — shop inventory/purchases.
  - `EventController` — random narrative event resolution.
  - `InventoryController` — relic inventory.
  - `SkillController` — hero skill management.
  - `CheckpointNotifier` (`checkpoint_controller.dart`) — `checkpointProvider` / `autosaveOrchestratorProvider`: triggers the autosave when a map node is resolved.
  - All shared/business state lives in Riverpod 2.x `Notifier`s here (`extends Notifier<T>`, exposed via `NotifierProvider`) — never in UI widgets or Flame components, and never as global variables/singletons. The migration off `StateNotifier` is complete for the controllers; the only remaining `StateNotifier` is the UI-local toast queue in `lib/ui/widgets/notification_overlay.dart`, which holds no business state. Do not add new ones.

- **Data layer** — `lib/models/data/` holds models mapping 1:1 to the JSON assets (`card_data.dart`, `enemy_data.dart`, `hero_data.dart`, `relic_data.dart`, `skill_data.dart`, `event_data.dart`, `forge_upgrade_data.dart`, etc.), aggregated via `game_data_registry.dart`. `lib/models/` (top level) holds runtime instances/state (`card_instance.dart`, `enemy_instance.dart`, `combat_state.dart`, `status_effect.dart`, etc.).

- **Services** — `lib/services/`
  - `gameDataLoaderProvider` (`game_data_service.dart`) — a `FutureProvider<GameDataRegistry>` that async-loads and caches all JSON asset data at startup. There is no `GameDataService` class; the provider *is* the entry point.
  - `MapGeneratorService` plus `lib/services/map/` (`map_node_generator.dart`, `map_connection_builder.dart`, `map_content_placer.dart`, `map_validator.dart`) — procedural world-map generation, decomposed into generate → connect → place-content → validate stages.
  - `SaveService` (`lib/services/save_service.dart`) — serialises `RunState`/`DeckState`/`InventoryState`/`SkillState` into a single versioned JSON blob under one `shared_preferences` key. Never called mid-combat.

- **UI (Flutter)** — `lib/ui/`
  - `lib/ui/screens/` — Home, Splash, ClassSelection, Map, Game, Draft, StarterDeckDraft, BossCardDraft, Deck (`deck_screen.dart`), Shop, Event, Rest/RestCardSelection, RelicExchange, PatchNotes, CardDictionary, ForgeFusion.
  - `lib/ui/widgets/` — reusable widgets, grouped by feature (`draft/`, `forge/`, `hud/` incl. `hud/dialogs/`, `map/` incl. `map/dialogs/`, `relic_carousel/`, `ui_card/`).
  - `lib/ui/theme/` — app-wide theme/design tokens (`app_theme.dart`).
  - UI widgets and Flame components must stay decoupled: no Flame references inside UI code, no Flutter widget trees inside Flame components.

- **Site vitrine** — `site/` — site statique servi à la racine du VPS, sans build ni dépendance npm. `site/_site/versions.json` est sa source de vérité ; `site/_site/js/model.js` porte la logique pure et est testé par `node --test` lancé depuis `site/`. Déployé par `.github/workflows/site.yml`, jamais à la main. Aucun lien avec le code du jeu.

- **Tutorial system** — `lib/tutorial/` (with `widgets/`) — onboarding/tutorial engine, separate from the main game loop.

- **Localization** — dual system:
  - `lib/l10n/` (ARB files) drives Flutter-widget-level UI strings via `flutter_localizations`/`intl`.
  - All game *content* (card/enemy/relic/event/skill text) is localized inline in the JSON data as bilingual key pairs, not via ARB. **Every JSON entry with user-facing text must include both `_fr` and `_en` variants**, and the corresponding Dart model in `lib/models/data/` must be updated whenever a JSON schema changes.
  - Supported locales: French and English.

- **Persistence** — `shared_preferences` for run state and settings (see `SaveService`, `lib/services/save_service.dart`).

## Data-Driven Content Workflow

To add or modify cards, enemies, heroes, relics, skills, or events: edit the relevant JSON file in `assets/data/`, following the shape of an existing entry. No business-logic code needs to change for pure content additions. `patch_notes.json` is the one exception — see below.

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

- **`patch_notes.json` is agent-managed**: never hand-edit it. It is maintained by the `patch-notes-writer` skill (`.claude/skills/patch-notes-writer/SKILL.md`), which prepends a new semver entry, writes player-facing French only, keeps `pubspec.yaml`'s `version:` field in sync with it, and adds the matching `current` entry to `site/_site/versions.json` while demoting the previous one to `stable`. Those three files are its entire scope, and they must always move together in a single commit: `verify_version.sh` fails the release if any of them disagrees.
- **The memory bank is agent-managed**: `.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/` and `_patterns/` are maintained by the `memory-bank-sync` skill (`.claude/skills/memory-bank-sync/SKILL.md`). It re-measures every metric with a command before writing it, enforces per-file line caps, and archives rather than appends. `.obsidian_vault/_archive/` is read-only.
- **`.agents/`** also defines a `game_designer` skill; other subfolders there (`orchestrator`, `worker_m1`, `auditor_m1`, etc.) are empty run-artifact directories from a past multi-agent workflow, not templates to follow.
- Favor non-blocking animations in Flame code (`Effect`, `Future.delayed` inside `async` methods) — never block the game loop.
- Use `priority` on Flame components to manage z-ordering (e.g. background at `-100`, floating text high).
- Use `FutureProvider` for async resource loading through Riverpod.
- No dead code, unused imports, or commented-out blocks in committed code.
