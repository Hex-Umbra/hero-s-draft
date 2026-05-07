# Phase 15 - Polissage du Contenu, de la Map et de la Progression

Ce plan détaille les correctifs et les nouvelles fonctionnalités demandées pour parfaire les ajouts récents (Statuts, Shop, Map, Draft).

## Étape 1 : Amélioration des Cartes Statuts et de l'IA Ennemie

**Objectif :** Rendre le système de cartes statuts pleinement fonctionnel et intégré aux comportements ennemis, tout en nettoyant les "hacks" actuels.

*   **Blocage explicite :** Modifier `EffectResolver.canPlayCard()` (dans `lib/game/services/effect_resolver.dart`) pour interdire formellement de jouer une carte si `card.data.type == CardType.status`.
*   **Nettoyage du deck de départ :** Retirer la carte "Blessure" de l'initialisation du starter deck dans le `GameScreen`.
*   **Nouvelle intention ennemie :** 
    *   Ajouter `debuffDeck` (ou `addStatus`) à `IntentType` dans `lib/models/enemy_intent.dart`.
    *   Mettre à jour `IntentionIndicator` (`intention_indicator.dart`) pour afficher une icône spécifique (par exemple, une icône toxique ou un deck barré) pour cette intention.
*   **Comportement Ennemi :** 
    *   Dans `EnemyCard.rollIntent()`, ajouter une probabilité de choisir l'intention `debuffDeck` (ex: 15% de chance).
    *   Lors de l'exécution du tour ennemi (`GameScreen` ou système dédié), si l'intention est `debuffDeck`, ajouter dynamiquement une instance de la carte "Blessure" (ou autre statut) dans la `discardPile` du joueur via une nouvelle méthode dans `DeckController`.

## Étape 2 : Refonte des Récompenses de Draft (Combat)

**Objectif :** Introduire la mécanique de "Clonage" de carte tout en conservant les récompenses de statistiques.

*   **Conservation des récompenses :** Garder les choix d'augmentation de PV, Attaque, Armure et Mana.
*   **Mécanique de Clonage (4ème Option) :**
    *   Dans `DraftScreen`, ajouter une probabilité de chance de voir apparaître une 4ème option de récompense ("Clonage").
    *   Au clic sur l'option "Clonage", au lieu de donner directement une copie, ouvrir une modale présentant **3 cartes aléatoires** tirées du `masterDeck` du joueur.
    *   Le joueur choisit l'une des 3 cartes. Une fois sélectionnée, cette carte est clonée via `deckNotifier.addCardToMasterDeck()` (déclenchant l'Auto-Merge).

## Étape 3 : Améliorations de la Boutique (ShopScreen)

**Objectif :** Rendre l'expérience de la boutique plus complète et satisfaisante visuellement.

*   **Service de Retrait de Carte :**
    *   Ajouter un nouveau service dans l'UI du `ShopScreen` : **"Oubli"** (Coût : ~50-75 Or).
    *   Au clic, ouvrir une fenêtre modale (`showModalBottomSheet` ou `showDialog`) affichant sous forme de grille le contenu du `masterDeck` du joueur.
    *   Permettre au joueur de sélectionner une carte. Une fois confirmée, la carte est retirée du `masterDeck` (nécessite une méthode `removeCardFromMasterDeck` dans `DeckController`) et l'or est déduit.
*   **Service de Clonage (Achat) :**
    *   Ajouter un service **"Miroir Magique"** (Clonage) disponible en permanence dans la boutique mais à un coût élevé (ex: 100-150 Or) pour limiter son accessibilité.
    *   Même fonctionnement que la récompense de fin de combat : ouvre un menu proposant 3 cartes aléatoires du deck du joueur, et permet d'en choisir une à cloner.
*   **Nettoyage Visuel :** 
    *   Lorsqu'une carte est achetée dans la section "Cartes à vendre", la retirer purement et simplement de la liste affichée (via `setState(() => _cardsForSale.remove(card));`), ou la remplacer par un encart "Vendu" clair pour éviter toute confusion visuelle.

## Étape 4 : Corrections et Améliorations de la World Map

**Objectif :** Rendre la carte du monde fluide, sans bug d'affichage, et permettre une boucle de gameplay infinie (ou par actes).

*   **Centrage Automatique de la Caméra :**
    *   Dans `MapScreen`, utiliser `WidgetsBinding.instance.addPostFrameCallback` pour centrer automatiquement l'`InteractiveViewer` dès l'ouverture de l'écran.
    *   Récupérer les coordonnées du `currentNodeId` (ou le premier nœud disponible si `currentNodeId` est null).
    *   Calculer le décalage (offset) pour que ce nœud se trouve au centre de l'écran et appliquer cette matrice de transformation au `_transformationController`.
*   **Correction du Nœud Coupé :**
    *   Le dernier nœud (Boss) est parfois coupé car il se trouve à la limite supérieure du `Container`.
    *   Ajouter du padding vertical supplémentaire dans le `Container` de la map (ex: augmenter la hauteur totale de 2500 à 2800 et ajouter un `padding: EdgeInsets.only(top: 300)` pour s'assurer que l'icône et les effets du Boss soient pleinement visibles).
*   **Regénération de la Carte (Boucle de Gameplay) :**
    *   Dans `RunController.completeCurrentNode()`, ajouter une vérification :
        `if (node.type == MapNodeType.boss) { ... }`
    *   Lorsque le boss est vaincu, implémenter une méthode `advanceToNextWorld()` dans le `RunController` qui va :
        1. Garder les statistiques, l'or, les reliques et le deck intacts.
        2. Générer une nouvelle carte via `MapGeneratorService.generateMap()`.
        3. Réinitialiser `currentNodeId` à `null`.
        4. (Optionnel) Augmenter la difficulté des ennemis à l'avenir.
    *   Ceci empêchera le jeu de bloquer une fois la carte terminée.
