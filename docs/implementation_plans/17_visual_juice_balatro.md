# Plan d'Implémentation 17 : Visual Juice & Game Feel (Style Balatro)

Ce document détaille le plan pour insuffler du "dynamisme" et de la "satisfaction visuelle" aux mécaniques de combat, en s'inspirant du ressenti (game feel) de jeux comme Balatro. L'objectif est de rendre chaque manipulation de carte et chaque impact gratifiant.

## Phase 1 : Dynamisme de la Carte en Main (Inertie & Tilt)
L'objectif est de supprimer l'aspect rigide des cartes pour leur donner une sensation de "poids" et de mouvement organique.

### 1.1 Tilt Dynamique (Inclinaison selon la vitesse)
- Modifier `CardComponent` pour calculer la vitesse de déplacement lors du drag.
- Appliquer une rotation (`angle`) proportionnelle à la vitesse horizontale (`delta.x`).
- Ajouter un effet de lissage (Lerp) pour que l'inclinaison revienne doucement à zéro quand le mouvement s'arrête.

### 1.2 Feedback d'Élasticité (Curves)
- Améliorer le retour en main (`_returnToHand`) en utilisant `Curves.elasticOut` pour simuler un effet de ressort.
- Ajuster le `ScaleEffect` lors du survol/focus pour qu'il soit plus percutant.

---

## Phase 2 : Séquence de Jeu et Impact (Attack Sequence)
Rendre l'action de jouer une carte plus agressive et spectaculaire.

### 2.1 Animation de Lancer (Anticipation & Dash)
- Créer une séquence d'effets lorsqu'une carte est jouée sur un ennemi :
  1. **Anticipation** : La carte recule légèrement et s'incline en arrière.
  2. **Dash** : Elle fonce vers l'ennemi en rétrécissant (effet de perspective).
  3. **Flash d'impact** : La carte devient blanche (`ColorFilter`) juste avant de disparaître.

### 2.2 Particules d'Impact
- Déclencher un `ParticleSystemComponent` au point d'impact.
- Les particules doivent adopter la couleur thématique de la carte jouée.

---

## Phase 3 : Réaction de l'Ennemi (Feedback de Dégâts)
S'assurer que le joueur "ressente" les dégâts infligés aux ennemis.

### 3.1 Shake & Flash
- Implémenter un `ShakeEffect` court (0.1s) sur la carte de l'ennemi touché.
- Ajouter un flash de couleur (blanc/rouge) via un `ColorEffect` ou un changement temporaire de `Paint`.

### 3.2 Amélioration du Floating Text
- Transformer le `FloatingText` pour qu'il "jaillisse" de l'impact avec un `ScaleEffect` (Pop) avant de s'élever.

---

## Phase 4 : Peaufinage et Audio Hooks

### 4.1 Préparation de l'Audio (Squelette)
- Identifier les points d'insertion (`Audio Hooks`) pour les futurs sons :
  - `sfx_card_slide` (pendant le drag rapide).
  - `sfx_card_play` (au déclenchement de l'attaque).
  - `sfx_impact_heavy` (lorsque l'ennemi reçoit les dégâts).

### 4.2 Validation Visuelle
- Vérifier que les animations ne ralentissent pas le rythme du combat (les effets doivent être rapides, entre 0.1s et 0.3s).
