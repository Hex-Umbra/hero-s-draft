# Plan d'Implémentation : Système de Deckbuilding (Core Loop)

Ce document décrit le plan d'action exhaustif pour implémenter la véritable mécanique de Deckbuilding. Ce système remplacera les compétences fixes actuelles par une gestion dynamique de cartes (Pioche, Main, Défausse) typique des Roguelike Deckbuilders (ex: *Slay the Spire*).

Ce plan suppose que le système **Data-Driven (Phase 1)** est en place, permettant de charger la définition des cartes depuis des fichiers JSON.

---

## Phase 1 : Modèles et Architecture des Cartes (Data)

**Objectifs :** Définir la structure de données d'une carte et ses différentes caractéristiques.

1.  **Énumérations fondamentales :**
    *   `CardType` : `attack` (Dégâts), `skill` (Armure/Utilité), `power` (Buff permanent), `status/curse` (Cartes négatives).
    *   `CardCategory` : `global` (Accessible par tous), `character_specific` (Restreinte à une classe, ex: Paladin, Mage).
    *   `CardRarity` : `common`, `uncommon`, `rare`, `epic`.
    *   `CardTarget` : `singleEnemy` (Nécessite de viser), `allEnemies` (AoE), `self` (Joueur), `none` (Effet global).
2.  **Modèle `CardData` (issu du JSON) :**
    *   Attributs : `id`, `name`, `description`, `cost` (Mana), `type`, `category`, `heroClass` (si spécifique), `rarity`, `target`, `spritePath`.
    *   Liste d'effets : `List<CardEffect>` définissant précisément ce que fait la carte (ex: type "damage", valeur 10).
3.  **Classe `CardInstance` (en jeu) :**
    *   Représente une carte physique dans le deck.
    *   Contient le niveau actuel (`level`) de la carte (par défaut 1, augmente via fusion).
    *   Contient une référence au `CardData` de base, mais peut avoir un `id` unique (UUID) pour la différencier des doublons et stocker des modifications temporaires (ex: son coût a été réduit pour ce tour).

## Phase 2 : Gestionnaire d'État du Deck (Riverpod)

**Objectifs :** Gérer la logique mathématique des piles de cartes.

1.  **Deck de Départ (Starter Deck) :**
    *   **Note de Design :** Au début d'une nouvelle partie (Run), le joueur commence avec un deck de **5 cartes au total**, structuré de la manière suivante :
        *   **2 cartes** spécifiques à sa classe (`character_specific`).
        *   **3 cartes** générées aléatoirement depuis la catégorie `global` (parmi les types Attaque, Défense ou Buff).
    *   *Note sur la Fusion :* Limiter ainsi les doublons de départ empêche le déclenchement non désiré du système de fusion immédiate qui surviendrait si on donnait au joueur 5 copies identiques de la même attaque de base.
2.  **Création du `DeckState` :**
    *   `masterDeck` : Liste de `CardInstance` possédées par le joueur. Ce deck commence par n'être que le **Deck de Départ**, puis il va s'enrichir au fil des combats via les Drafts.
    *   `drawPile` : Cartes disponibles à piocher ce combat.
    *   `hand` : Cartes actuellement en main.
    *   `discardPile` : Cartes jouées ou défaussées.
    *   `exhaustPile` : Cartes retirées du combat (si la mécanique "Exhaust/Épuisement" est implémentée).
3.  **Création du `DeckNotifier` (StateNotifier) :**
    *   `initializeCombat(List<CardInstance> deck)` : Vide la main/défausse, copie le `masterDeck` dans la `drawPile` et la mélange.
    *   `drawCards(int amount)` : 
        *   Prend `amount` cartes de la `drawPile` vers la `hand`.
        *   **Logique critique :** Si la `drawPile` est vide avant d'avoir pioché toutes les cartes, appeler `shuffleDiscardIntoDraw()` puis continuer à piocher.
    *   `shuffleDiscardIntoDraw()` : Vide la `discardPile`, transfère tout dans la `drawPile` et mélange.
    *   `discardHand()` : Déplace toutes les cartes de la `hand` vers la `discardPile`.
    *   `playCard(CardInstance card)` : Retire la carte de la main et l'envoie dans la défausse (ou l'épuisement si c'est un Pouvoir).

## Phase 3 : Moteur d'Exécution et Vérifications

**Objectifs :** Lier les cartes jouées aux conséquences sur les entités (Dégâts, Soins, Mana).

1.  **Vérification de jouabilité :**
    *   Avant de jouer, vérifier si `playerMana >= card.cost`.
    *   Vérifier si une cible valide est sélectionnée (si `target == singleEnemy`).
2.  **`EffectResolver` (Résolveur d'effets) :**
    *   Service qui lit les effets d'une carte et modifie le `PlayerState` ou l'`EnemyState`.
    *   *Exemple :* Si effet est "Dégâts = 15", appeler `enemy.takeDamage(15)`.
    *   Déduire le mana du joueur : `player.consumeMana(card.cost)`.

## Phase 4 : Interface Utilisateur en Combat (Flame)

**Objectifs :** Rendre les cartes manipulables à l'écran.

1.  **`CardComponent` (Visuel Flame) :**
    *   Composant dessinant le fond de carte, l'icône de mana, l'illustration (`Sprite`), le nom et la description dynamique (calculée depuis les stats du joueur, ex: Dégâts + Force).
2.  **Layout de la Main (Fan Layout) :**
    *   Calculer la position, la rotation et l'échelle (Scale) des cartes dans la main pour qu'elles s'affichent en éventail au bas de l'écran.
    *   Mettre à jour ce layout à chaque pioche ou carte jouée.
3.  **Interactions (Drag & Drop) :**
    *   Utiliser les mixins `DragCallbacks` de Flame sur le `CardComponent`.
    *   **Survol (Hover) :** La carte se soulève et s'agrandit pour être lisible.
    *   **Drag :** La carte suit la souris/le doigt.
    *   **Ciblage (Arrow) :** Si la carte nécessite une cible, dessiner une flèche/courbe de Bézier depuis le joueur jusqu'au curseur. Les ennemis survolés sont mis en surbrillance.
    *   **Drop (Relâchement) :** 
        *   Si relâchée sur une cible valide : Déclencher `playCard`.
        *   Si cible invalide ou annulée : Remettre la carte dans la main (retour à sa position initiale avec une animation `MoveEffect`).
4.  **UI des Piles (Overlay/HUD) :**
    *   Afficher des compteurs pour la `Pioche` (bas-gauche) et la `Défausse` (bas-droite) permettant de cliquer pour voir leur contenu.

## Phase 5 : Intégration à la Game Loop (Tour par tour)

**Objectifs :** Intégrer la logique de pioche et défausse dans le flux des tours de combat existant.

1.  **Début du tour du Joueur :**
    *   Réinitialiser le Mana du joueur à son maximum.
    *   Appeler `deckNotifier.drawCards(5)` (ou la valeur de pioche par défaut).
2.  **Phase d'Action du Joueur :**
    *   Le joueur joue ses cartes (Drag & Drop).
    *   Le joueur clique sur un nouveau bouton "Fin de Tour".
3.  **Fin du tour du Joueur :**
    *   Appeler `deckNotifier.discardHand()`.
    *   Passer au tour de l'ennemi.

## Phase 6 : Système de Draft (Loot) et Amélioration (Fusion)

**Objectifs :** Permettre la progression du deck et l'amélioration des cartes via un système de fusion (Merge).

1.  **Modification de l'écran de récompenses (Draft) :**
    *   À la mort de tous les ennemis, ouvrir l'écran de Draft.
    *   Piocher au hasard 3 `CardData` différentes dans le registre. 
    *   **Contraintes de Pool :** Le tirage doit inclure un mix de cartes `global` et de cartes `character_specific` correspondant à la classe actuelle du joueur.
    *   Tenir compte de la probabilité liée à la `CardRarity` (Commune, Non-Commune, Rare).
2.  **Ajout au Master Deck :**
    *   Présenter ces 3 cartes au joueur.
    *   Lors de la sélection, ajouter une nouvelle `CardInstance` (niveau 1) correspondante au `masterDeck` dans le `RunState`.
    *   Proposer un bouton "Passer" (Skip) si aucune carte n'est intéressante.
3.  **Système de Fusion et d'Amélioration (Auto-Merge) :**
    *   **Logique de vérification :** À chaque fois qu'une carte est ajoutée au deck, vérifier si le joueur possède **3 exemplaires exacts de cette carte au même niveau**.
    *   **Fusion :** Si 3 exemplaires sont trouvés (ex: trois "Coup d'épée" niveau 1), ils sont retirés du `masterDeck` et remplacés par **1 seule carte de niveau supérieur** (ex: un "Coup d'épée" niveau 2).
    *   **Progression infinie :** Ce processus fonctionne à tous les niveaux (3 cartes niv. 2 = 1 carte niv. 3, etc.). Les statistiques de la carte (dégâts, coût, effets) augmentent en fonction de ce niveau.
