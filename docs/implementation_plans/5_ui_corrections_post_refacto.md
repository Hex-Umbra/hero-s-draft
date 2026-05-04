# Plan d'Implémentation : Corrections et Polissage UI (Phase 5)

## Objectif
Ajuster l'interface utilisateur suite aux retours de la Phase 4 pour garantir une visibilité optimale des cartes et des indicateurs vitaux.

---

## Étape 1 : Rapprochement du Joueur et Redimensionnement des Cartes Jouables
### 1.1 Rapprochement du Héros vers le centre
*   **Composants :** `HeroCard` et `HerosDraftGame`
*   **Action :** Modifier la position `y` de l'instanciation de la `HeroCard`. Actuellement ancrée en bas de l'écran (`size.y - 150`), elle sera remontée plus proche du centre (ex: `size.y / 2 + 120`) pour éviter que les cartes en main ne la masquent.
### 1.2 Réduction de la taille des cartes en main
*   **Composant :** `CardComponent`
*   **Action :** Réduire les dimensions statiques `cardWidth` et `cardHeight` (actuellement à 140x200) pour qu'elles soient plus compactes (ex: 100x140 ou 110x160), libérant ainsi l'espace visuel sur la zone de jeu.

---

## Étape 2 : Relocalisation et Redimensionnement de la Barre de Vie
### 2.1 Intégration de la barre de vie dans le bandeau inférieur
*   **Composant :** `GameScreen`
*   **Action :** Déplacer le widget Flutter de la barre de vie du joueur. Actuellement flottant et très large au-dessus du bouton "Fin de Tour", il sera inséré horizontalement au même niveau que les autres éléments du HUD inférieur (Pioche, Fin de Tour, Défausse).
*   **Positionnement :** Placer la barre entre l'indicateur de "Pioche" (à gauche) et le bouton central "Fin de Tour". La largeur de la barre de vie sera fixée (ex: 150 pixels) pour s'adapter à cet espace sans déborder.

---

## Étape 3 : Nettoyage de la Carte Ennemie
### 3.1 Suppression du texte interne
*   **Composant :** `EnemyCard`
*   **Action :** Supprimer le `TextComponent` (`titleText`) affichant le nom de l'ennemi ou la mention "BOSS"/"ENNEMI" à l'intérieur de la carte, afin d'harmoniser son apparence épurée avec celle de la carte du joueur (modifiée en Phase 4).