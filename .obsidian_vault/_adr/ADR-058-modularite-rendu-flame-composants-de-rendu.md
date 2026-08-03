## 🎮 ADR-058 : Modularité Rendu Flame / Composants de Rendu (v0.2.10)

### Statut
✅ Accepté & Implémenté (v0.2.10)

### Contexte
La classe racine du moteur Flame `HerosDraftGame` gérait de façon centralisée des responsabilités complexes comme la synchronisation d'état Riverpod, le calcul de la disposition des cartes en main, le repositionnement des ennemis, et l'affichage des effets visuels (particules, ciblage). De même, `CardComponent` combinait à la fois le dessin Canvas 2D (coût mana, bordures rareté, sheen foil, rune sockets) et la gestion des gestes du pointeur (drag, hover, tap). Ce couplage alourdissait les fichiers et créait de la dette technique de rendu.

### Décision
- **Extraction de Systèmes Graphiques** : Décomposer `HerosDraftGame` en extrayant ses sous-tâches dans 4 sous-systèmes autonomes enregistrés en tant que composants de jeu Flame sous `lib/game/systems/` :
  1. `StateSyncSystem` : Synchronise de manière séquentielle et synchrone les états Riverpod (`RunState`, `DeckState`, `CombatState`) avec la boucle `update` de Flame.
  2. `CardAnimationSystem` : Gère le focus, le zoom, le survol, la pioche et le tilt des cartes en main.
  3. `CombatVisualSystem` : Gère le rendu de la courbe de ciblage Bézier et les effets visuels de combat.
  4. `LayoutSystem` : Calcule l'arc circulaire de la main du joueur et le repositionnement automatique des ennemis actifs sur le plateau.
- **Découplage de CardComponent** : Diviser le composant carte en extrayant ses responsabilités logiques et visuelles dans deux classes spécialisées sous `lib/game/components/widgets/` :
  1. `CardRenderer` : Prend en charge exclusivement le dessin 2D de la carte (fond, halos, bordures, rune sockets, dégradés typés).
  2. `CardInteractionHandler` : Centralise la gestion des événements Pointer (drag, hover, tap) et met à jour les flags d'état du composant.
- **Conservation de la Façade** : `CardComponent` et `HerosDraftGame` agissent comme des façades de coordination légères associant et délégant aux sous-systèmes et helpers.

### Preuves dans le code
- [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) : Nettoyé de ses algorithmes de layout et d'animations, délègue aux 4 sous-systèmes.
- [card_component.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/card_component.dart) : Délègue son rendu à `CardRenderer` et ses interactions gestuelles à `CardInteractionHandler`.
- Sous-dossier [systems/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/systems/) : Contient les 4 sous-systèmes Flame autonomes.
- [card_renderer.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/widgets/card_renderer.dart) et [card_interaction_handler.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/widgets/card_interaction_handler.dart) : Gèrent respectivement le dessin et les gestes.

### Conséquences
- ✅ **Rendu et Calculs Découplés** : La structure des classes de rendu Flame est aérée, aisée à comprendre et à faire évoluer sans risquer de perturber la gestion des gestes ou le calcul de géométrie.
- ✅ **GPU/CPU Performance** : Permet de mieux cibler les mises en cache (comme le caching des structures textes dans `CardRenderer`).
- ✅ **Facilité d'Évolution** : L'ajout d'effets visuels, de nouveaux types de gestes ou de nouvelles dispositions de main se fait dans des fichiers isolés sans impacter la classe racine.
