# Hero's Draft - Project Documentation

## Project Overview
"Hero's Draft" is a roguelike card game built with **Flutter**, using the **Flame** engine for game rendering and **Riverpod** for state management. The game features turn-based combat, character classes with unique stats, and a procedural encounter system.

### Core Technologies
- **Flutter**: UI, HUD, and application lifecycle.
- **Flame**: Game loop, entity rendering, and animations.
- **Riverpod**: Global state management and business logic.
- **JSON Data**: Assets located in `assets/data/` define cards, enemies, heroes, and skills.

### Architecture
- **Rendering Layer (Flame)**: Located in `lib/game/`. Uses `PositionComponent` for game entities and handles visual effects like damage numbers and "bump" animations.
- **State Management (Riverpod)**: Located in `lib/game/controllers/` and `lib/services/`.
    - `RunController`: Manages the current run state (level, health, mana, buffs).
    - `DeckController`: Manages the player's deck, hand, and discard pile.
- **Data Layer**: Models in `lib/models/data/` map to JSON assets. `GameDataService` handles asynchronous loading of game data.
- **UI Layer**: Flutter widgets in `lib/ui/` for screens (Home, Game, Draft, Selection).

## Building and Running
As a standard Flutter project, the following commands apply:

- **Run the app**: `flutter run`
- **Run tests**: `flutter test`
- **Get dependencies**: `flutter pub get`
- **Build**: `flutter build <apk|ios|web|windows|macos|linux>`

## Development Conventions

### State Management
- **Always use Riverpod** for shared state.
- Flame components should synchronize with Riverpod state via `syncState` or similar methods in `HerosDraftGame`.
- Business logic (cooldowns, damage calculation, resource consumption) should reside in `StateNotifier` controllers.

### Game Rendering (Flame)
- Game entities should inherit from `PositionComponent` or use Flame's component system.
- Use `priority` to manage z-indexing (e.g., background at `-100`).
- Favor non-blocking animations (using `Effect` or `Future.delayed` within `async` methods).

### Data & Content
- Add new enemies, cards, or heroes by modifying the JSON files in `assets/data/`.
- Ensure corresponding models in `lib/models/data/` are updated if the JSON schema changes.

### Coding Style
- Follow `package:flutter_lints` (default Flutter linting rules).
- Keep UI widgets (Flutter) and Game components (Flame) decoupled.
- Use `FutureProvider` for asynchronous resource loading.
- **Mandatory Validation**: Always run `dart analyze` at the end of each implementation phase and fix any identified issues before proceeding or finalizing the task.
