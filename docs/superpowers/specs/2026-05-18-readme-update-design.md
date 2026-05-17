# README Design Spec: Hero's Draft (Modern Showcase)

## 1. Overview
This spec outlines the structure and content for the updated README of "Hero's Draft," a roguelike deckbuilder built with Flutter and Flame. The goal is to present a "Modern Showcase" that highlights both the rich gameplay features (visual juice, world map) and the robust technical architecture (Riverpod integration, data-driven design).

## 2. Structure
The README will follow this structure:

### 2.1 Header & Vision
*   **Title:** Hero's Draft - Roguelike Deckbuilder
*   **Badges:** Flutter, Flame, Riverpod, Status (Beta/Active).
*   **Description:** A dynamic, data-driven roguelike card game where strategy meets fluid "game feel."

### 2.2 Key Features
*   **Dynamic Combat:** Focus on the "Balatro-style" game feel (card tilt, inertia, attack sequences, particle explosions).
*   **Strategic Progression:** The fully functional World Map with animated paths, chokepoints, Boss nodes, and distinct encounters (Combat, Elite, Shop, Rest, Events).
*   **Deckbuilding & Economy:** Draft system with Auto-Merge (combining 3 identical cards), Shop for purchasing/removing cards, and Rest nodes for upgrades.
*   **Deep Mechanics:** Passive class traits, Relics, Status Effects (Poison, Strength, Weakness), and a strict Mana economy.

### 2.3 Under the Hood (Architecture)
*   **The Power Couple:** Explanation of Flame (handling the game loop, positioning, and visual effects) working in tandem with Riverpod (handling global state, deck logic, and combat resolution).
*   **Data-Driven Engine:** Highlighting the JSON-driven architecture. Cards, enemies, heroes, and skills are completely decoupled from the codebase, allowing for rapid balancing and modding.
*   **Responsive UI:** A dynamic scaling system ensuring the Flame engine and Flutter HUD adapt flawlessly to any screen resolution.

### 2.4 Developer Guide
*   **Running the project:** Standard Flutter commands.
*   **Modding/Extending:** A brief guide on how to add a new card or enemy simply by editing the JSON files in `assets/data/`.

### 2.5 Roadmap & Status
*   **Current Status:** Mentioning the completion of the core engine, UI responsiveness, and major content implementation (Phases 1-12).
*   **Next Steps:** Audio/Music integration, new Relics, and final polish.

## 3. Style & Tone
*   **Language:** French, with English headers/titles for a professional "showcase" feel.
*   **Tone:** Proud, technical, yet accessible to players. Uses markdown formatting (bolding, lists, code blocks) to make reading easy.