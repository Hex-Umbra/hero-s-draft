# Plan d'Implémentation 14 : Polissage UI et Positions

## Objectif
Répondre aux derniers retours visuels pour optimiser l'affichage :
1. Baisser la position de la barre de vie du joueur.
2. Transformer la barre de vie des ennemis en badge circulaire et le placer sur le côté droit.
3. Rapprocher l'indicateur d'attaque des ennemis de la bordure supérieure de leur carte.

## 1. Ajustement de la barre de vie joueur
*   **Fichier :** `lib/ui/screens/game_screen.dart`
*   **Modification :** La barre de vie est encadrée par un `Padding(padding: EdgeInsets.only(bottom: 20))`. Réduire ce padding à `5` ou `10` pour la coller davantage au bas de l'écran.

## 2. Refactoring des PV Ennemis (Badge Circulaire)
*   **Fichier :** `lib/game/components/entities/enemy_card.dart`
*   **Modifications :**
    *   Retirer l'import et l'instanciation de `HealthBarComponent`.
    *   Créer un nouveau `StatBadge` de type `StatType.hp` pour représenter les points de vie de l'ennemi.
    *   Le positionner à droite de la carte, par exemple : `Vector2(size.x + 15, 20)`.
    *   Mettre à jour ce badge dans `_refreshBadges` et `updateStats`.

## 3. Descente de l'indicateur d'intention (Ennemis)
*   **Fichier :** `lib/game/components/entities/enemy_card.dart`
*   **Modification :** L'espace libéré par l'ancienne barre de vie au-dessus de la carte permet de descendre le `IntentionIndicator`. Passer sa position de `Vector2(size.x / 2, -65)` à `Vector2(size.x / 2, -25)` (juste au-dessus du cadre de la carte).