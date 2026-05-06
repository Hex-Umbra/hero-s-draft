# Plan d'Implémentation 6 : Interface Utilisateur (UI/UX) Responsive

## Objectif
Transformer l'ensemble de l'interface (Flutter et Flame) de dimensions absolues (hardcodées) à des dimensions relatives et flexibles. L'objectif est d'assurer une expérience de jeu cohérente, sans superpositions ou débordements, sur tous les appareils (Mobiles en portrait/paysage, Tablettes, Desktop).

## 1. Refactoring de la Couche Flutter (HUD & Menus)

La couche Flutter est responsable de l'affichage du HUD (barre de vie, boutons, indicateurs) par-dessus le rendu Flame (`GameWidget`).

### A. Écran de Jeu (`lib/ui/screens/game_screen.dart`)
*   **Barre de Vie du Joueur (HUD) :**
    *   *Problème actuel :* La barre est positionnée à `left: 140` avec une largeur fixe `width: 300`. Sur les petits écrans, elle rentre en collision avec les compteurs de pioche ou sort de l'écran.
    *   *Solution :* 
        1.  Remplacer le `Positioned(bottom: 20, left: 140)` par un `Align(alignment: Alignment.bottomCenter)` avec un `Padding(padding: EdgeInsets.only(bottom: 20))`.
        2.  Contraindre la largeur dynamiquement : `width: MediaQuery.of(context).size.width * 0.4` (ou utiliser `FractionallySizedBox(widthFactor: 0.4)`).
*   **Indicateurs Pioche / Défausse :**
    *   *Problème actuel :* Fixés aux bords gauche/droit (`left: 20`, `right: 20`).
    *   *Solution :* Envelopper le rendu complet de l'écran dans un `SafeArea` pour garantir que les "encoches" de téléphone ne masquent pas les informations, et conserver des positionnements relatifs aux bords de la Safe Area.
*   **Textes dynamiques :**
    *   *Problème actuel :* Tailles fixes (`TextStyle(fontSize: 24)`).
    *   *Solution :* Utiliser une méthode utilitaire (ex: `ResponsiveLayout.textScale(context) * 24`) ou envisager d'utiliser le package `auto_size_text` pour les titres longs qui risquent de déborder.

### B. Écrans de Menus (`DraftScreen`, `ClassSelectionScreen`)
*   **Composant de Choix (`UiCard` dans `lib/ui/widgets/ui_card.dart`) :**
    *   *Problème actuel :* Dimensions absolues (`width: 150, height: 220`).
    *   *Solution :* 
        1. Enlever ces dimensions du `Container`.
        2. Envelopper le composant dans un `AspectRatio(aspectRatio: 150 / 220)`.
        3. Dans le parent (`DraftScreen`), placer ces cartes dans un parent flexible (ex: `Expanded` au sein d'un `Row` ou `Wrap`).
*   **Adaptation au format Portrait (Mobile) :**
    *   *Problème actuel :* Un simple `Row` de 3 éléments plantera (overflow horizontal) sur un téléphone en mode portrait.
    *   *Solution :* Utiliser un `LayoutBuilder` :
        *   Si `maxWidth > 600` (Tablette/Desktop/Paysage) : Utiliser un `Row`.
        *   Si `maxWidth <= 600` (Mobile Portrait) : Remplacer par un `Column` (ou un `Wrap` scrollable) et ajuster la taille des cartes.

---

## 2. Refactoring du Moteur Flame (`HerosDraftGame`)

Flame s'occupe de l'arène de combat, des cartes et des effets.

### A. Gestion de la Caméra (Le plus simple et robuste)
Plutôt que de recalculer chaque coordonnée (`Vector2`), la meilleure approche consiste à déléguer l'adaptation à la caméra de Flame.
*   *Solution :* Dans `HerosDraftGame.onLoad()`, configurer la caméra avec un **`FixedResolutionViewport`** (ex: résolution cible de `1920x1080` ou `1280x720`).
    ```dart
    camera.viewport = FixedResolutionViewport(resolution: Vector2(1920, 1080));
    ```
    *Avantage :* Flame va automatiquement "letterboxer" (ajouter des bandes noires) ou "pillarboxer" l'écran si le ratio de l'appareil ne correspond pas. Ainsi, les positions absolues des ennemis (ex: `y=220`) fonctionneront toujours parfaitement, peu importe l'écran.

### B. Positionnement Relatif (Alternative sans bandes noires)
Si l'utilisation du viewport avec des bandes noires n'est pas souhaitée (pour utiliser tout l'espace disponible de chaque écran), les positionnements doivent devenir relatifs :
*   **Ennemis (`_spawnEnemies`) :**
    *   *Ordonnée Y :* `size.y * 0.3` (30% du haut de l'écran) au lieu de `220`.
    *   *Abscisse X :* Calculer l'espacement dynamiquement selon `size.x / (ennemis.length + 1)`.
*   **Héros :**
    *   *Ordonnée Y :* `size.y * 0.65`.
*   **Main du Joueur (`_layoutHand`) :**
    *   *Ordonnée Y (centre de l'arc) :* `size.y + radius - (size.y * 0.1)` (dépendant de la hauteur disponible).
*   **Mécaniques de Drag & Drop (`CardComponent`) :**
    *   *Cancel Zone :* `position.y > game.size.y * 0.8` (les 20% du bas de l'écran) au lieu de `game.size.y - 220`.

---

## 3. Plan d'Action par Phases (Déploiement)

### Phase 1 : Configuration du Viewport Flame (Rapide)
1.  Modifier `HerosDraftGame.onLoad()` pour instancier un `FixedResolutionViewport`.
2.  Tester l'arène de combat (héros, ennemis, main) sur diverses résolutions. Si cela résout les soucis sans créer de désagrément visuel majeur, conserver cette approche. Sinon, basculer sur la Phase 1 Bis (Positionnements Relatifs).

### Phase 2 : Responsivité de l'UI Principale (GameScreen)
1.  Envelopper le `Scaffold` du jeu principal avec un `SafeArea`.
2.  Refactoriser le HUD (Barre de vie) en utilisant `Align` et `MediaQuery.of(context).size.width * 0.4`.
3.  Vérifier que les fenêtres modales (`PauseMenu`, Tooltips) utilisent des pourcentages de largeur (`width: MediaQuery.of(context).size.width * 0.8`) au lieu de tailles fixes.

### Phase 3 : Refonte des Écrans Intermédiaires (Menus)
1.  Refactoriser `UiCard` pour la rendre flexible (`AspectRatio`).
2.  Modifier `DraftScreen` avec un `LayoutBuilder` pour basculer entre un affichage `Row` (Paysage/Desktop) et `Column` (Portrait).
3.  Modifier `ClassSelectionScreen` (si applicable) pour que la liste des héros utilise un `GridView` avec `SliverGridDelegateWithMaxCrossAxisExtent` (qui s'adapte automatiquement au nombre de colonnes) au lieu d'un nombre fixe (`crossAxisCount`).

### Phase 4 : Tests Fonctionnels et Assurance Qualité
1.  Lancer le jeu sur un simulateur mobile (iOS/Android) et basculer l'orientation (Portrait <-> Paysage) en plein combat pour vérifier la robustesse du re-layout (`hasLayout` dans Flame).
2.  Lancer le jeu sur la cible Desktop (Windows/macOS) et redimensionner la fenêtre "à chaud".
3.  Vérifier spécifiquement la logique de "Hitbox" (Ciblage des ennemis avec les cartes) pour s'assurer que les zones interactives suivent bien les redimensionnements.