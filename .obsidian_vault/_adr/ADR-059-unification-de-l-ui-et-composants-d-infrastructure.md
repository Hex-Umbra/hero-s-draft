## 🎨 ADR-059 : Unification de l'UI et Composants d'Infrastructure Communs (v0.2.2)

### Statut
✅ Accepté & Implémenté (v0.2.2)

### Contexte
1. L'application comportait une duplication visuelle massive : chaque écran majeur (Shop, Deck, Map, Dictionary, Rest, etc.) redéfinissait ses propres Scaffold, décors d'arrière-plans (dégradés sombres ou textures parchemin), zones de sécurité (`SafeArea`) et interdictions de retour arrière (`PopScope`), nuisant à la cohérence et à la maintenabilité.
2. L'instanciation du composant `UiCard` Flutter dans les écrans de menu était extrêmement verbeuse (nécessitant de mapper manuellement ~15 attributs d'état à chaque fois).
3. Le dialogue de forge (`forge_upgrade_dialog.dart`) était une classe monolithique complexe d'environ 870 lignes gérant à la fois la logique de forge, l'affichage de l'aperçu de carte, les lignes de slots et le bouton d'achat de slots.
4. Les écrans de draft de cartes (`boss_card_draft_screen.dart` et `starter_deck_draft_screen.dart`) dupliquaient les structures de grille, d'en-tête et les indicateurs de sélection.

### Décision
1. **Composants Génériques Unifiés** :
   - Créer `ScreenScaffold` pour centraliser le rendu du Scaffold, le background thématique (`dark`, `parchment`, `none`), la `SafeArea` et la gestion de `PopScope`.
   - Créer `PageHeader` comme en-tête d'écran standardisé gérant le bouton de retour arrière, le titre et les actions (telles que le badge d'or).
   - Créer `GoldIndicator` pour l'affichage unifié de l'or connecté à `inventoryProvider`.
2. **Factories `UiCard`** :
   - Ajouter des constructeurs nommés `UiCard.fromInstance` (pour `CardInstance` de run) et `UiCard.fromData` (pour `CardData` de configuration) pour centraliser la conversion d'état.
3. **Décomposition de la Forge** :
   - Diviser le dialogue monolithique en extrayant ses composants visuels dans un nouveau sous-dossier `lib/ui/widgets/forge/` :
     - `ForgeCardPreview` : Rendu de la carte et de sa jauge d'upgrades.
     - `ForgeSlotRow` : Rendu d'une option d'amélioration, son coût de reroll et ses boutons d'actions.
     - `ForgeBuySlotButton` : Bouton d'achat de fente progressive.
4. **Layout de Draft Centralisé** :
   - Créer `CardDraftLayout` pour factoriser la mise en page commune des écrans de draft de cartes.
5. **Refactoring des Écrans** :
   - Harmoniser 9 écrans majeurs (Dictionary, Deck, Shop, RestCardSelection, PatchNotes, Rest, Event, RelicExchange, Map) pour s'appuyer sur ces widgets communs.

### Preuves dans le code
- [screen_scaffold.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/screen_scaffold.dart) : Classe centralisant le décor et le cycle de vie du Scaffold.
- [page_header.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/page_header.dart) : En-tête standardisé.
- [gold_indicator.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/gold_indicator.dart) : Badge d'or connecté à l'état.
- [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart) : Intégration de `UiCard.fromInstance` et `UiCard.fromData`.
- [card_draft_layout.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/draft/card_draft_layout.dart) : Layout de draft partagé.
- Sous-dossier [forge/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/forge/) : Composants visuels extraits de la forge.

### Conséquences
- ✅ **Élimination de la Duplication Visuelle (DRY)** : Les arrière-plans, les en-têtes et les structures de pages sont partagés, éliminant des centaines de lignes répétitives.
- ✅ **Séparation des Responsabilités (SRP)** : Le dialogue de la forge a été allégé de plus de 250 lignes et ne gère plus que l'orchestration logique et Riverpod.
- ✅ **Élimination de la Duplication Visuelle (DRY)** : Les arrière-plans, les en-têtes et les structures de pages sont partagés, éliminant des centaines de lignes répétitives.
- ✅ **Séparation des Responsabilités (SRP)** : Le dialogue de la forge a été allégé de plus de 250 lignes et ne gère plus que l'orchestration logique et Riverpod.
- ✅ **Simplicité d'Usage** : L'instanciation de `UiCard` est immédiate grâce aux factories, sécurisant les mappings.
- ✅ **Cooptation des Écrans de Draft** : Une seule grille responsive gère les différents drafts, rendant les corrections ou ajustements futurs instantanés.
- ✅ **Zéro Régression** : Les 108 tests unitaires du projet s'exécutent avec succès et l'analyse statique de compilation est vierge.
