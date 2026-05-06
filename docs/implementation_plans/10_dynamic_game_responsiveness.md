# Plan d'Implémentation 10 : Responsivité Dynamique du Moteur Flame

## Objectif
Rendre le moteur de jeu Flame véritablement responsive en abandonnant le viewport fixe au profit d'un layout dynamique. Les composants doivent s'adapter en taille (scaling) et en position (ancrage relatif) selon la résolution et le ratio de l'écran.

## 1. Refactoring de la Caméra et de la Game Loop (`HerosDraftGame`)
*   **Suppression du Viewport Fixe** : Retirer `FixedResolutionViewport` dans `onLoad` pour laisser Flame utiliser tout l'écran (comportement par défaut avec `MaxViewport`).
*   **Surcharge de `onGameResize`** : Implémenter cette méthode (ou utiliser la boucle `update` via `hasLayout`) pour recalculer dynamiquement un `scaleFactor` et rafraîchir les positions lorsque la taille de la fenêtre change.
*   **Repositionnement Relatif des Entités** :
    *   Héros : Placé à `size.y * 0.55` (milieu-bas).
    *   Ennemis : Placés à `size.y * 0.25` avec un espacement horizontal dynamique (`size.x / (nombre_ennemis + 1)`).
    *   Main de cartes : Le centre de l'arc de cercle doit être calculé en fonction de `size.y` et `size.x`.

## 2. Refactoring des Composants d'Entité (`HeroCard`, `EnemyCard`)
*   **Mise à l'échelle (Scaling)** : Appliquer un `scaleFactor` (ex: `game.size.y / 1080`) au `scale` du composant racine.
*   **Ajustement de l'Orientation** : Si l'écran est en mode portrait (`size.y > size.x`), ajuster l'échelle globale pour que les cartes ne soient pas hors-cadre et resserrer les espacements.

## 3. Refactoring des Cartes en Main (`CardComponent`)
*   **Zone d'Annulation Dynamique** : Modifier `onDragUpdate` et `_isHoveringCancelZone` pour utiliser `game.size.y * 0.8` (les 20% du bas de l'écran) au lieu d'une valeur fixe en pixels (`game.size.y - 220`).
*   **Mise à jour Dynamique des Positions Originales** : S'assurer que le glisser-déposer retourne bien à la nouvelle position relative de la carte (après un `onGameResize`).

## 4. Tests de Redimensionnement (Resizing)
*   S'assurer que lors d'un changement de taille de la fenêtre "à chaud", la disposition de la main (`_layoutHand`) et la position des ennemis (`_spawnEnemies` ou équivalent) sont instantanément mises à jour sans "casser" l'interface visuelle.