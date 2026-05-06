# Plan d'Implémentation 11 : Ajustements Visuels (Tailles et Espacements)

## Objectif
Corriger les problèmes visuels identifiés suite à l'implémentation de la responsivité dynamique :
1. Le chevauchement de la barre de vie (interface Flutter) avec les cartes en main (moteur Flame).
2. La taille globale des cartes (Héros, Ennemis, Cartes à jouer) jugée trop petite sur l'ensemble des résolutions testées.

## 1. Déplacement de la main de cartes vers le haut
*   **Problème :** Les cartes en main sont positionnées trop bas et se superposent avec le HUD.
*   **Solution :** Dans `lib/game/heros_draft_game.dart`, modifier la méthode `_layoutHand()`.
    *   Le centre de l'arc de cercle actuel est calculé ainsi : `Vector2(size.x / 2, size.y + radius - (size.y * 0.1))`
    *   *Correction :* Augmenter ce décalage relatif, par exemple à `(size.y * 0.25)`, pour remonter significativement la position de base des cartes en main et dégager l'espace inférieur pour la barre de vie.

## 2. Augmentation de la taille globale des cartes (Scaling)
*   **Problème :** Les cartes paraissent trop petites, même sur de grands écrans (3K, Tablettes).
*   **Solution :** Ajuster le `scaleFactor` global dans `lib/game/heros_draft_game.dart`.
    *   Actuellement, l'échelle est calculée via une hauteur de référence très grande : `(size.y / 1080).clamp(0.5, 2.0)`.
    *   *Correction :* Abaisser la hauteur de référence virtuelle (ce qui augmentera la taille des objets) et remonter le seuil minimum, par exemple : `(size.y / 800).clamp(0.85, 2.5)`. Cela aura pour effet d'agrandir de manière homogène toutes les entités du moteur Flame.
    *   Nous vérifierons également si un ajustement de l'espacement des ennemis est nécessaire suite à cet agrandissement.