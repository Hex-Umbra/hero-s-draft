# Rapport d'Analyse : Responsivité Dynamique du Moteur Flame

## 1. Diagnostic : Pourquoi le "Jeu" ne s'adapte pas ?

Le problème majeur vient de la dissonance entre le **Viewport Fixe** et les **Dimensions Hardcodées** des composants.

*   **Le Piège du Viewport Fixe (1920x1080) :**
    *   Sur une **Tablette en Portrait**, ce viewport force un format 16:9 dans un écran vertical. Résultat : d'énormes bandes noires en haut et en bas, et une zone de jeu "écrasée" au milieu où tout devient minuscule et illisible.
    *   Sur un **Écran 3K**, le jeu est simplement agrandi, mais il n'utilise pas l'espace supplémentaire pour espacer les cartes ou agrandir les textes de manière intelligente.
*   **Dimensions des Composants en Pixels :**
    *   Les cartes sont définies comme `140x196` pixels. Dans un monde virtuel de 1080p, c'est fixe. Si on veut que le jeu soit "Responsive", la taille d'une carte doit être un **pourcentage de la hauteur de l'écran** (ex: 20% de `game.size.y`).
*   **Ancrages Absolus :**
    *   Le héros est placé à `size.y / 2 + 50`. Les ennemis à `y = 220`. Ces valeurs ne tiennent pas compte de la place réelle disponible. Sur un téléphone étroit, les ennemis se chevauchent ou sortent du cadre car l'espacement `210.0` est fixe.

## 2. La Solution : Le passage au "Dynamic Layout Engine"

Pour que le jeu soit véritablement responsive (jouable au doigt sur mobile et confortable à la souris sur 3K), nous devons abandonner le viewport fixe et passer à un système de **Layout Relatif**.

### A. Calcul d'Échelle Dynamique (Component Scaling)
Chaque composant racine (`HeroCard`, `EnemyCard`, `CardComponent`) doit calculer sa taille en fonction de la résolution réelle :
*   `scale = (game.size.y / 1080)`.
*   Sur un écran 3K, les cartes seront physiquement plus grandes.
*   Sur un petit téléphone, elles resteront proportionnelles à la main du joueur.

### B. Positionnement par "Ancrages" (Anchoring)
Remplacer les coordonnées fixes par des ratios de `game.size` :
*   **Zone Ennemis :** `y = game.size.y * 0.25` (25% du haut).
*   **Zone Héros :** `y = game.size.y * 0.55` (Milieu-bas).
*   **Zone Main :** `y = game.size.y * 0.88` (Bas de l'écran).
*   **Espacement X :** Calculé dynamiquement : `espacement = game.size.x / (nombre_ennemis + 1)`.

### C. Adaptation à l'Orientation (Portrait vs Paysage)
*   **Mode Paysage :** Disposition classique.
*   **Mode Portrait :** Réduction automatique de l'échelle des cartes (`scale * 0.8`) et resserrement des espacements pour éviter que les éléments ne se superposent aux bords de l'écran.

---

## 3. Nouveau Plan d'Action (Le "Vrai" Jeu Responsive)

1.  **Suppression du Viewport Fixe :** Revenir à un viewport qui remplit 100% de l'écran (`MaxViewport`).
2.  **Refactoring de `HerosDraftGame` :** Implémenter une méthode `onGameResize` (ou utiliser `size` dans `update`) pour recalculer les positions de TOUS les composants dès que la fenêtre change.
3.  **Mise à l'échelle des Hitboxes :** S'assurer que les zones de drag & drop suivent l'échelle dynamique.

### Batterie de Tests pour validation future :
1.  **Changement d'orientation à chaud :** Basculer le téléphone de Paysage à Portrait pendant qu'une carte est sélectionnée (focus).
2.  **Redimensionnement extrême :** Réduire la fenêtre PC à un format "Carré" ; les ennemis doivent rester centrés et ne pas déborder.
3.  **Test 3K / 4K :** Vérifier que les textes dans les cartes ne deviennent pas illisibles ou trop fins.
