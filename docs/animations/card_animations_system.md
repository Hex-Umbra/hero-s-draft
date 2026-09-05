# Système d'Animations Dynamiques des Cartes

Ce document explique le fonctionnement du système d'animations piloté par les données (Data-Driven) pour les cartes dans Hero's Draft.

## 1. Vue d'ensemble

Le système permet de déclencher des séquences visuelles différentes selon le type de carte jouée. Le choix de l'animation est défini directement dans le fichier de la carte — `assets/data/cards/<id>.json` ou `assets/data/classes/<classe>/cards/<id>.json` — via la clé `"animation"`.

## 2. Configuration JSON

Chaque carte peut définir son type d'animation. Si la clé est absente, le système utilise `melee` par défaut.

```json
{
  "id": "strike_basic",
  "name": "Frappe",
  "type": "attack",
  "animation": "melee",
  ...
}
```

## 3. Types d'Animations Actuels

### `melee` (Mêlée)
*   **Usage** : Attaques physiques directes sur cible unique.
*   **Visuel** : 
    1.  La carte effectue une légère anticipation vers l'arrière.
    2.  Dash rapide vers la cible.
    3.  Impact : La carte disparaît et un **Slash rouge** (`SlashEffect`) traverse l'ennemi.
    4.  **Réaction** : L'ennemi subit un tremblement (`shake`) et un flash blanc.
*   **Méthode interne** : `_playMeleeAnimation`

### `magic` (Magique)
*   **Usage** : Sorts, attaques de zone ou effets d'état (ex: Poison).
*   **Visuel** : La carte prend une teinte violette, s'élève en vibrant (pulsation), puis explose en particules pourpres.
*   **Méthode interne** : `_playMagicAnimation`

### `buff` (Amélioration/Défense)
*   **Usage** : Cartes de défense, de pioche ou de bonus passifs.
*   **Visuel** : La carte devient dorée et s'élève doucement vers le haut de l'écran avant de disparaître en fondu (fade out).
*   **Méthode interne** : `_playBuffAnimation`

### Animations Élémentaires (`poison`, `fire`, `ice`, `lightning`)
*   **Usage** : Sorts d'attaque appliquant des effets de statut.
*   **Visuel** : 
    1.  **Chargement** : La carte prend la couleur de l'élément (ex: Vert pour Poison), s'élève et effectue une rotation oscillante.
    2.  **Dash** : La carte fonce vers l'ennemi.
    3.  **Impact** : Explosion de 30 particules denses de la couleur de l'élément.
    4.  **Réaction** : Tremblement et flash blanc de l'ennemi.
*   **Méthode interne** : `_playStatusAnimation` (mutualisée avec paramètre `Color`).

## 4. Fonctionnement Technique

La logique réside dans `lib/game/components/card_component.dart`.

1.  **Déclenchement** : Quand une carte est jouée avec succès, `game.tryPlayCard` appelle `cardComp.playAnimation(target)`.
2.  **Dispatch** : La méthode `playAnimation` lit `card.data.animation` et redirige vers la méthode de séquence appropriée via un `switch`.
3.  **Séquençage** : Les animations utilisent `SequenceEffect` et `CombinedEffect` (pour le parallélisme) de Flame.
4.  **Finalisation** : À la fin de chaque séquence, le callback `onComplete` est appelé pour retirer la carte du moteur de jeu et résoudre les effets logiques.

## 5. Comment ajouter une nouvelle animation ?

### Ajouter une variante élémentaire
Si vous voulez ajouter un élément (ex: `wind`), il suffit de :
1.  Ajouter `"animation": "wind"` dans le JSON.
2.  Ajouter le cas dans le `switch` de `playAnimation` :
    ```dart
    case 'wind':
      _playStatusAnimation(target, Colors.white70, onComplete);
      break;
    ```

### Ajouter un type d'animation unique
Pour ajouter un comportement totalement différent (ex: `archery`) :
1.  **Ajouter la clé dans le JSON** : Mettez `"animation": "archery"`.
2.  **Modifier `CardComponent`** :
    *   Créez une méthode privée `void _playArcheryAnimation(EnemyCard? target, VoidCallback onComplete)`.
    *   Implémentez la séquence d'effets Flame souhaitée.
    *   Ajoutez le cas dans le `switch` de la méthode `playAnimation`.

```dart
// Exemple d'ajout dans CardComponent
case 'archery':
  _playArcheryAnimation(target, onComplete);
  break;
```

## 6. Feedback de Traînée (Trail)

Indépendamment de l'animation finale, toutes les cartes en cours de drag possèdent :
*   Un **RibbonTrail** (ruban blanc/doré continu).
*   Des **AcceleratedParticles** (particules arc-en-ciel) soumises à la gravité.

Ces effets sont gérés dans la méthode `update` et le cycle de vie du drag (`onDragStart`, `onDragEnd`).
