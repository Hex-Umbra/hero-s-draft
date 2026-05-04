# Plan d'Implémentation : Refactoring du Layout UI (Phase 4)

## Objectif
Repenser la disposition spatiale des éléments de jeu sur l'écran de combat pour offrir une interface plus claire, plus centralisée et mieux structurée, en préparant le terrain pour de futures améliorations graphiques.

---

## Étape 1 : Repositionnement et Nettoyage de la Carte Joueur
### 1.1 Centrage du Héros
*   **Composant :** `HerosDraftGame` / `HeroCard`
*   **Action :** Modifier la logique de positionnement pour que la carte du héros s'affiche parfaitement au centre horizontal de la zone de jeu en bas, abandonnant ainsi son placement asymétrique.
### 1.2 Suppression du texte de Classe
*   **Composant :** `HeroCard`
*   **Action :** Retirer le `TextComponent` qui affiche actuellement le nom de la classe choisie (ex: "PALADIN") en haut de la carte du joueur pour épurer le visuel.

---

## Étape 2 : Redimensionnement des Cartes
### 2.1 Réduction de la taille de base
*   **Composants :** `HeroCard` et `EnemyCard`
*   **Action :** Réduire la taille définie dans le `super(size: Vector2(...))` de ces deux composants.
*   **Contrainte Critique :** Les dimensions des éléments associés (Badges de statistiques, Icônes de buff, Textes flottants) **ne doivent pas** être réduites. Seule la taille de la "carte" physique (le fond et le sprite du personnage) doit diminuer.

---

## Étape 3 : Réalignement des Badges de Statistiques
### 3.1 Alignement Vertical à Gauche
*   **Composants :** `HeroCard` et `EnemyCard`
*   **Action :** Modifier le placement actuel (points cardinaux) des `StatBadge` (Armure, Attaque/Force, Mana).
*   **Nouveau Layout :** Aligner tous ces badges verticalement le long du bord gauche (ou juste à l'extérieur du bord gauche) de chaque carte de manière uniforme pour les ennemis et le joueur.

---

## Étape 4 : Externalisation de la Barre de Vie du Joueur (HUD)
### 4.1 Suppression de la barre locale
*   **Composant :** `HeroCard`
*   **Action :** Retirer complètement le `HealthBarComponent` qui est actuellement un enfant de la carte du héros.
### 4.2 Intégration globale dans l'Interface Flutter
*   **Composant :** `GameScreen`
*   **Action :** Créer un nouveau widget Flutter pour la barre de vie du joueur.
*   **Positionnement :** L'intégrer dans le HUD principal (avec les widgets Flutter), le bouton "Fin de Tour" étant désormais placé au milieu à droite de l'écran.
*   **Dimensions :** Cette nouvelle barre devra être plus imposante et s'adapter dynamiquement à la largeur de l'écran ou de sa zone allouée pour une lecture immédiate de l'état de santé.