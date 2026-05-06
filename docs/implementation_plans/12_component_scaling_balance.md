# Plan d'Implémentation 12 : Équilibrage des Tailles de Composants

## Objectif
Affiner les dimensions des éléments de jeu en appliquant des échelles différenciées :
1. Réduire la taille des cartes en main (jouabilité et encombrement).
2. Augmenter la taille des entités sur le terrain (Héros et Ennemis) pour une meilleure présence visuelle.

## 1. Réduction des cartes à jouer (`CardComponent`)
*   **Action :** Appliquer un multiplicateur de réduction au `scaleFactor` global uniquement pour les cartes en main.
*   **Fichier :** `lib/game/components/card_component.dart`
*   **Modification :** Dans `onLoad` et `onGameResize`, multiplier le `game.scaleFactor` par un ratio (ex: `0.8` ou `0.75`).

## 2. Augmentation des entités de terrain (`HeroCard`, `EnemyCard`)
*   **Action :** Appliquer un multiplicateur d'agrandissement au `scaleFactor` global pour les entités actives.
*   **Fichiers :** 
    *   `lib/game/components/entities/hero_card.dart`
    *   `lib/game/components/entities/enemy_card.dart`
*   **Modification :** Dans `onLoad` et `onGameResize`, multiplier le `game.scaleFactor` par un ratio (ex: `1.2` ou `1.3`).

## 3. Ajustement des espacements ennemis
*   **Action :** Suite à l'agrandissement des ennemis, vérifier que la logique de `_repositionEnemies` dans `lib/game/heros_draft_game.dart` ne provoque pas de chevauchements excessifs.
*   **Ajustement :** Si besoin, augmenter les bornes du `clamp(120, 250)` pour l'espacement.
