# Système d'Animations Dynamiques des Cartes

Ce document explique le fonctionnement du système d'animations piloté par les données (Data-Driven) pour les cartes dans Hero's Draft.

## 1. Vue d'ensemble

Le système permet de déclencher des séquences visuelles différentes selon le type de carte jouée. Le choix de l'animation est défini directement dans le fichier `assets/data/cards.json` via la clé `"animation"`.

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
*   **Visuel** : La carte effectue une légère anticipation vers l'arrière, puis un dash rapide vers la cible, finit par un flash blanc et des particules bleues.
*   **Méthode interne** : `_playMeleeAnimation`

### `magic` (Magique)
*   **Usage** : Sorts, attaques de zone ou effets d'état (ex: Poison).
*   **Visuel** : La carte prend une teinte violette, s'élève en vibrant (pulsation), puis explose en particules pourpres.
*   **Méthode interne** : `_playMagicAnimation`

### `buff` (Amélioration/Défense)
*   **Usage** : Cartes de défense, de pioche ou de bonus passifs.
*   **Visuel** : La carte devient dorée et s'élève doucement vers le haut de l'écran avant de disparaître en fondu (fade out).
*   **Méthode interne** : `_playBuffAnimation`

## 4. Fonctionnement Technique

La logique réside dans `lib/game/components/card_component.dart`.

1.  **Déclenchement** : Quand une carte est jouée avec succès, `game.tryPlayCard` appelle `cardComp.playAnimation(target)`.
2.  **Dispatch** : La méthode `playAnimation` lit `card.data.animation` et redirige vers la méthode de séquence appropriée via un `switch`.
3.  **Séquençage** : Les animations utilisent `SequenceEffect` de Flame pour enchaîner les `MoveEffect`, `ScaleEffect`, `RotateEffect` et `OpacityEffect`.
4.  **Finalisation** : À la fin de chaque séquence, le callback `onComplete` est appelé pour retirer la carte du moteur de jeu et résoudre les effets logiques.

## 5. Comment ajouter une nouvelle animation ?

Pour ajouter un nouveau type (par exemple, `archery`) :

1.  **Ajouter la clé dans le JSON** : Mettez `"animation": "archery"` dans les cartes concernées.
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
