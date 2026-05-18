# Plan d'Implémentation 24 : Refonte UI et Interaction des Cartes

Ce plan vise à uniformiser l'affichage des cartes entre les menus et le combat, tout en introduisant un nouveau mode d'interaction "Click-to-Play" pour améliorer l'accessibilité et le confort de jeu.

## 1. Objectifs
- **Uniformisation UI** : Utiliser un style visuel unique pour les cartes partout dans le jeu (Combat, Shop, Deck, Forge).
- **Distinction Visuelle** : Appliquer des thèmes de couleurs par type de carte (Attaque, Défense, Pouvoir).
- **Interaction Click-to-Play** : Permettre de jouer une carte en cliquant sur elle puis sur sa cible, en complément du drag-and-drop actuel.

## 2. Phase 1 : Modernisation du Widget `UiCard`
Le widget Flutter `UiCard` doit devenir le composant de référence pour toutes les cartes.

### Tâches :
- **Extension du modèle de données** : S'assurer que `UiCard` reçoit toutes les informations nécessaires (Type de carte, Cible, etc.).
- **Styles par Type** :
    - **Attaque** : Bordure rouge (`Colors.redAccent`), fond avec gradient subtil vers le rouge.
    - **Défense/Skill** : Bordure bleue (`Colors.blueAccent`), fond avec gradient subtil vers le bleu.
    - **Pouvoir** : Bordure dorée (`Colors.amber`), fond avec gradient subtil vers l'or/ambre.
- **Interactivité** : Ajouter un état `isSelected` pour afficher un halo de sélection (Glow effect).

## 3. Phase 2 : Unification dans le moteur Flame (`CardComponent`)
Refonte du `CardComponent` pour qu'il utilise le rendu de `UiCard`.

### Tâches :
- **Refactoring de `CardComponent`** : Supprimer le rendu manuel (`render` avec `TextPainter`).
- **Utilisation de `WidgetComponent`** : Intégrer `UiCard` dans Flame via `WidgetComponent` (ou synchroniser le rendu Canvas pour qu'il soit identique à 100% au widget Flutter).
- **Synchronisation des États** : S'assurer que les effets Flame (Shake, Flash, Glow) s'appliquent correctement au nouveau composant.

## 4. Phase 3 : Système "Click-to-Play"
Ajout de la logique de sélection et de ciblage par clic.

### Tâches :
- **Gestion de la Sélection** :
    - Lorsqu'une carte est cliquée (`onTapDown`), elle passe en mode `Focused`.
    - Si elle était déjà `Focused`, le mode est maintenu.
- **Logique de Ciblage** :
    - Modifier `HerosDraftGame._handlePlayerTargeting` :
        - Si une carte est `Focused` ET que la cible cliquée est valide pour cette carte :
            - Appeler `tryPlayCard(focusedCard, target)`.
            - Réinitialiser le focus.
- **Support du Ciblage Personnel** :
    - Ajouter `TapCallbacks` à `HeroCard`.
    - Permettre de cliquer sur le Héros pour jouer les cartes de type "Self" (Buffs, Soins, Armure).
- **Annulation** : Cliquer sur le fond de l'écran annule le focus actuel.

## 5. Phase 4 : Polissage et Feedbacks
- **Feedback Visuel** : Ajouter une flèche ou une ligne de ciblage (Targeting Line) entre la carte sélectionnée et le curseur/cible potentielle.
- **Validation des Cibles** : Mettre en surbrillance (Glow) les cibles valides (Ennemis ou Héros) lorsqu'une carte est sélectionnée.
- **Transition** : S'assurer que le passage du clic au drag est fluide (si le joueur maintient le clic après avoir sélectionné la carte).

## 6. Critères d'Acceptation
- Les cartes en combat ont exactement le même design que dans le dictionnaire ou le shop.
- Le type de carte (Attaque/Défense/Pouvoir) est immédiatement identifiable par la couleur.
- Une carte peut être jouée en cliquant dessus puis sur un ennemi (pour les attaques).
- Une carte peut être jouée en cliquant dessus puis sur le héros (pour les buffs).
- Le drag-and-drop reste fonctionnel et prioritaire si un mouvement est détecté.
- Aucun bug de superposition ou de priorité (Z-index) lors de la sélection.
