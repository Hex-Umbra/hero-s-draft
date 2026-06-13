# Hero's Draft - Project Documentation

## Project Overview
"Hero's Draft" is a roguelike card game built with **Flutter**, using the **Flame** engine for game rendering and **Riverpod** for state management. The game features turn-based combat, character classes with unique stats, a procedural map system, relics, a shop, events, and a full deckbuilding loop.

### Core Technologies
- **Flutter**: UI, HUD, screens, and application lifecycle.
- **Flame**: Game loop, entity rendering, animations, and visual effects.
- **Riverpod**: Global state management and all business logic.
- **JSON Data**: Assets in `assets/data/` define cards, enemies, heroes, skills, relics, events, and patch notes.
- **flutter_localizations / intl**: Full bilingual support (French & English). All user-facing content must have both `_fr` and `_en` keys.
- **shared_preferences**: Persistence for run state and settings.

### Architecture
- **Rendering Layer (Flame)**: `lib/game/`
  - `HerosDraftGame` — root game class, orchestrates all Flame components.
  - `lib/game/components/` — `CardComponent`, `FloatingText`, `EffectIcon`, entity components, visual effects.
  - `lib/game/systems/` — standalone game systems.
  - `lib/game/services/` — game-level services.
  - `game_constants.dart` — shared constants.
- **State Management (Riverpod)**: `lib/game/controllers/`
  - `RunController` — current run state (health, mana, armor, buffs, map, level, relics).
  - `DeckController` — deck, hand, discard pile management.
  - `CombatController` — turn flow, enemy intents, damage calculation, status effects.
  - `RewardController` — post-combat reward and relic selection.
  - `ShopController` — shop inventory and purchase logic.
  - `EventController` — random event resolution.
  - `InventoryController` — relic inventory management.
  - `SkillController` — hero skill management.
- **Data Layer**: `lib/models/data/` — models mapping to JSON assets. `GameDataService` handles asynchronous loading.
- **Services**: `lib/services/`
  - `GameDataService` — loads and caches all JSON asset data.
  - `MapGeneratorService` — procedural map generation.
- **UI Layer**: `lib/ui/`
  - `lib/ui/screens/` — all Flutter screens (Home, Splash, ClassSelection, Map, Game, Draft, StarterDeckDraft, BossCardDraft, DeckView, Shop, Event, Rest, RestCardSelection, RelicExchange, PatchNotes, CardDictionary).
  - `lib/ui/widgets/` — reusable Flutter widgets.
  - `lib/ui/theme/` — app-wide theme and design tokens.
- **Localization**: `lib/l10n/` — ARB files for FR/EN strings.
- **Agent System**: `.agents/` — orchestrator, worker, reviewer, explorer, challenger, auditor sub-agents and skills.
- **Memory Bank**: `.obsidian_vault/_memory_bank/` — living project documentation maintained by the BA/PM agent.

---

## Language Rule

> **Mandatory** — All agent responses, plans, summaries, questions, and comments addressed to the user must **always be written in French**, without exception. This applies to the main agent and all sub-agents.

---

## Building and Running
As a standard Flutter project, the following commands apply:

- **Run the app**: `flutter run`
- **Run tests**: `flutter test`
- **Get dependencies**: `flutter pub get`
- **Analyze**: `dart analyze`
- **Build**: `flutter build <apk|ios|web|windows|macos|linux>`

---

## Agent Workflow & Delegation Rules

> These rules govern how every implementation task must be executed. They are **mandatory** and apply to all agents.

### Rule 1 — Task Delegation to Sub-Agents
Every implementation task given by the user **must be delegated to one or more sub-agents**. The main agent acts as an orchestrator and must not perform implementation work directly. Sub-agents are declared in `.agents/` (orchestrator, workers, explorers, challengers, reviewers, auditor).

### Rule 2 — Post-Implementation Sub-Agent Calls (Parallel)
Once sub-agents have completed their implementation work and `dart analyze` reports **zero errors**, two additional sub-agents declared in `.agents/skills/` must be launched **in parallel**:

#### 2a. Patch Notes Writer — `.agents/skills/patch_notes_writer.md`
- Reads the `implementation_plan.md`, `task.md`, and `walkthrough.md` from the conversation artifacts.
- **By default**: creates a **new version entry** (incremented semver) prepended to `assets/data/patch_notes.json`.
- **Exception**: if the user explicitly states in their prompt to *update the current version* rather than create a new one, the agent updates the latest existing entry instead.
- Writes only in French, player-facing language. No developer jargon.
- Must not touch any file other than `assets/data/patch_notes.json`.

#### 2b. Business Analyst / Product Manager — `.agents/skills/business_analyst_product_manager.md`
- Reads the implementation artifacts and the Obsidian Memory Bank at `.obsidian_vault/_memory_bank/`.
- Updates the 5 core vault files: `productContext.md`, `systemPatterns.md`, `activeContext.md`, `progress.md`, `decisionLog.md`.
- Ensures cross-file consistency and no contradictions.
- Translates technical changes into structured product knowledge.

> **Both sub-agents (2a and 2b) are always launched in parallel at the end of every implementation phase.**

---

## Development Conventions

### State Management
- **Always use Riverpod** for shared state. No global variables, no singletons outside of providers.
- Flame components synchronize with Riverpod state via `syncState` or similar bridge methods in `HerosDraftGame`.
- Business logic (cooldowns, damage calculation, resource consumption, armor reset, buff/debuff ticks) must reside in `StateNotifier` controllers, never in UI widgets or Flame components.

### Game Rendering (Flame)
- Game entities must inherit from `PositionComponent` or use Flame's component system.
- Use `priority` to manage z-indexing (e.g., background at `-100`, floating text at high priority).
- Favor **non-blocking animations** (`Effect`, `Future.delayed` inside `async` methods). Never block the game loop.
- Visual effects (damage numbers, critical hit indicators, bump animations) live in `lib/game/components/`.

### Data & Content
- Add new enemies, cards, heroes, relics, or events by modifying the JSON files in `assets/data/`.
- Every JSON entry with user-facing text **must** include both `_fr` and `_en` variants.
- Update corresponding Dart models in `lib/models/data/` whenever the JSON schema changes.
- `patch_notes.json` is managed exclusively by the `patch_notes_writer` skill agent — do not edit it manually.

### Localization
- All user-facing strings rendered in Flutter widgets must use the ARB localization system (`lib/l10n/`).
- Card names, enemy names, relic descriptions, event texts, and skill names are localized via JSON bilingual keys, not ARB.

### Coding Style
- Follow `package:flutter_lints` (default Flutter linting rules).
- Keep UI widgets (Flutter) and Game components (Flame) **strictly decoupled**. No direct Flame references in UI, no Flutter widget trees inside Flame components.
- Use `FutureProvider` for asynchronous resource loading.
- **Mandatory Validation**: Always run `dart analyze` at the end of each implementation phase and fix **all** identified issues before proceeding, finalizing, or triggering post-implementation agents.
- Prefer named parameters and explicit types for clarity.
- Do not leave dead code, unused imports, or commented-out blocks in committed code.
