# Plan d'Implémentation Exhaustif : Feedbacks, UI & UX (Phase 3)

Ce document détaille les étapes nécessaires pour transformer le prototype technique en une expérience de jeu fluide, gratifiante et stratégiquement claire.

## Objectif Global
Remplacer les indicateurs de debug par des retours visuels "Game Feel" (Juice) et améliorer la lisibilité des mécaniques de combat.

---

## Étape 1 : Lisibilité et Clarté du Combat

### 1.1 Barres de Vie Dynamiques (`HealthBarComponent`)
*   **Composant :** Créer une classe `HealthBarComponent` héritant de `PositionComponent`.
*   **Visuel :**
    *   Un fond (`background`) gris/noir.
    *   Une barre de progression (`foreground`) rouge pour les ennemis, verte pour le joueur.
    *   Un contour blanc fin.
*   **Logique :** La barre doit se mettre à jour via un pourcentage `current / max`.
*   **Intégration :** Remplacer le `StatBadge` HP dans `HeroCard` et `EnemyCard` par cette barre placée au-dessus ou en dessous de l'entité.

### 1.2 Système d'Intentions Ennemies (Telegraphing)
*   **Modèle :** Créer un modèle d'intention (Type : Attaque, Défense, Buff / Valeur).
*   **Logique :** Dans `EnemyCard`, générer une intention aléatoire au début du tour du joueur (via le `EncounterSystem` ou directement dans le composant).
*   **Visuel :** Afficher une petite icône flottante (épée, bouclier, éclair) avec la valeur prévue au-dessus de l'ennemi.
*   **Synchronisation :** Lors de la phase de riposte, l'ennemi doit exécuter l'action annoncée par son intention.

---

## Étape 2 : Le "Juice" (Animations et Feedbacks)

### 2.1 Screen Shake (Tremblement de caméra)
*   **Implémentation :** Ajouter une méthode `shake()` dans `HerosDraftGame` qui manipule la position du `viewfinder`.
*   **Intensité :** Prévoir deux niveaux (Faible pour les attaques réussies, Fort pour les dégâts subis par le joueur).

### 2.2 Animations de "Dash" directionnelles
*   **Refactorisation :** Transformer `bumpAnimation()` pour utiliser des `SequenceEffect`.
*   **Mouvement :** L'entité doit se déplacer vers le centre de l'écran (ou vers sa cible) avant de revenir.

### 2.3 Floating Text amélioré
*   **Visuel :** Améliorer `FloatingText` avec des variations de taille (plus gros pour les critiques) et des trajectoires légèrement aléatoires (arc de cercle).

---

## Étape 3 : Interface Avancée (Flutter Overlays)

### 3.1 Bannières de Phase (Tour Joueur / Tour Ennemi)
*   **UI :** Créer un widget Flutter affichant une bannière centrale lors du changement de `TurnPhase`.
*   **Animation :** Entrée latérale, pause de 1s, sortie latérale.

### 3.2 Système de Tooltips
*   **Interaction :** Déclencher l'affichage d'un Overlay Flutter lors d'un appui long sur une `CardComponent` ou une icône d'état.
*   **Contenu :** Nom, description complète et explication des effets (ex: "Armure : Réduit les prochains dégâts reçus").

---

## Consignes d'Exécution
*   **Validation :** Chaque sous-étape doit être testée manuellement en lançant le jeu.
*   **Suivi :** Entre chaque étape, une phrase récapitulative de type "git commit" doit être rédigée pour documenter l'avancement dans `avancé_implementation.md`.

---

## Checklist de Validation Finale
- [ ] Les barres de vie sont fluides et lisibles.
- [ ] Le joueur peut prédire les dégâts ennemis grâce aux intentions.
- [ ] Les impacts de combat sont ressentis physiquement via le Screen Shake.
- [ ] Les phases de jeu sont clairement identifiées.
