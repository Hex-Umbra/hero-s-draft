# Rapport de Concepts : Maîtrise du Game Design et Développement (Hero's Draft)

Ce document sert de guide pédagogique pour comprendre et reproduire l'architecture et les concepts de game design utilisés dans le projet **Hero's Draft**. Il est conçu pour qu'un apprenti développeur puisse assimiler les fondations du jeu sans avoir à décortiquer l'intégralité du code source à chaque fois.

---

## 1. L'Architecture Triangulaire : Flutter + Flame + Riverpod

L'une des plus grandes forces de ce projet est la séparation claire des responsabilités entre trois frameworks majeurs :

- **Riverpod (La Logique)** : C'est le "cerveau" du jeu. Il gère l'état global (PV, Mana, Cartes dans la main, Niveau actuel). Il ne sait rien du rendu visuel.
- **Flame (Le Rendu)** : C'est le "moteur de jeu". Il s'occupe d'afficher les entités (Héros, Ennemis), de gérer les animations, les drag-and-drop et les effets visuels.
- **Flutter (L'Interface)** : Il gère les menus, les boutons de l'interface (HUD), les dialogues de draft et les transitions d'écrans.

### Concept à retenir : "Le Pont" (SyncState)
Pour que Flame sache ce que Riverpod a décidé (ex: "Le joueur a perdu 10 PV"), on utilise une méthode de synchronisation.
*   **Implémentation** : Flame écoute le `runProvider`. Dès que l'état change, Flame reçoit une copie du `RunState` et met à jour ses composants visuels.

---

## 2. Le Design Piloté par les Données (Data-Driven Design)

Dans Hero's Draft, les cartes, les ennemis et les héros ne sont pas codés "en dur". Ils existent sous forme de fichiers **JSON** dans `assets/data/`.

### Pourquoi faire cela ?
1.  **Flexibilité** : On peut ajouter un nouvel ennemi simplement en modifiant un texte, sans toucher au code Dart.
2.  **Équilibrage** : Modifier les points de vie ou les dégâts d'une carte se fait en une seconde dans le JSON.

### Concept à retenir : "Modelisation & Service"
- **Modèles** : Des classes Dart (ex: `CardData`) qui mappent exactement la structure du JSON.
- **Service** : Le `GameDataService` qui charge ces fichiers au démarrage et les transforme en objets utilisables par le jeu.

---

## 3. Gestion de l'État (State Management) avec Riverpod

Le projet utilise des `StateNotifier` pour centraliser la logique.

- **RunController** : Gère la progression (Niveaux, Or, PV).
- **DeckController** : Gère la manipulation des cartes (Piocher, Défausser, Mélanger).

### Concept à retenir : "L'Immuabilité"
On ne modifie jamais directement les variables d'un état. On crée une **copie** de l'état avec les nouvelles valeurs via la méthode `copyWith`. Cela garantit que le jeu est toujours dans un état prévisible et facilite le debugging.

---

## 4. Moteur Flame : Entités et Effets

Chaque élément visuel dans le combat est un `Component`.

- **HeroCard & EnemyCard** : Représentent les entités de combat.
- **CardComponent** : Gère la logique complexe d'interaction.

### Concepts clés du moteur :
- **Priority (Z-Index)** : Détermine quel élément s'affiche par-dessus les autres (ex: une carte survolée passe en priorité 100, une carte tenue en priorité 200).
- **Effects (Tweening)** : Utilisation de `MoveEffect`, `ScaleEffect` et `OpacityEffect` pour rendre le jeu "vivant".
- **Layout Dynamique** : Les cartes dans la main sont positionnées sur un **arc de cercle mathématique** (calculé avec Sinus/Cosinus), s'adaptant automatiquement à la taille de l'écran.

### Focus : Le Drag-and-Drop (CardComponent)
C'est souvent l'aspect le plus complexe pour un débutant. Voici comment il est géré :
1.  **onDragStart** : On mémorise la position d'origine, on augmente la priorité, et on retire les animations automatiques pour donner le contrôle total au joueur.
2.  **onDragUpdate** : La carte suit le curseur (`canvasDelta`). On vérifie si elle survole une **"Cancel Zone"** (bas de l'écran) pour annuler le coup, ou un ennemi pour cibler.
3.  **onDragEnd** : Si la carte est au-dessus d'une cible valide, on appelle `game.tryPlayCard()`. Sinon, on utilise un `MoveEffect` pour la faire revenir "élastiquement" à sa place.

---

## 5. Logique de Jeu Avancée

### Gestion du Deck (DeckController)
Le jeu suit le cycle classique des jeux de cartes : **Pioche -> Main -> Défausse**.
- **Mélange (Shuffle)** : Quand la pioche est vide, la défausse est copiée, mélangée aléatoirement (`shuffle()`), puis devient la nouvelle pioche.
- **Cycle de Vie d'une Carte** : Une carte est retirée de la main et envoyée soit dans la défausse, soit dans la pile d'épuisement (`exhaustPile`) si c'est un pouvoir permanent.

### L'Intention de l'Ennemi (Intent System)
Inspiré de *Slay the Spire*, les ennemis affichent leur prochaine action.
- **Logique** : À la fin de chaque tour, l'ennemi "lance un dé" (`rollIntent()`) pour choisir sa prochaine action parmi une liste définie dans ses données, permettant au joueur de planifier sa défense.

### Génération Procédurale (Map System)
Le `MapGeneratorService` crée une structure de nœuds de manière aléatoire mais structurée.
- **Concept** : Utilisation de probabilités pour définir le type de nœud (Combat, Elite, Repos, Marchand) et assurer une progression équilibrée.

---

## 6. UX et Feedback (Le "Juice")

Un jeu se sent "bon" grâce aux feedbacks visuels :
- **Damage Numbers** : Chaque coup affiche un chiffre qui monte et disparaît (`FloatingText`).
- **Screen Shake / Bump** : Les composants "sautent" légèrement vers leur cible lors d'une attaque.
- **Tooltips** : Survoler une icône affiche instantanément une explication claire.

---

## Conclusion pour l'Apprenti

Pour reproduire ces concepts dans un nouveau projet :
1.  **Commence par les données** : Définis tes modèles et tes JSON.
2.  **Code la logique pure** : Crée tes controllers Riverpod sans penser aux graphismes.
3.  **Ajoute la couche visuelle** : Utilise Flame pour "dessiner" l'état de tes controllers.
4.  **Peaufine le feedback** : Ajoute des `Effects` Flame pour chaque interaction utilisateur.

*Ce rapport est une base solide. Pour approfondir, consulte les fichiers dans `lib/game/controllers/` pour la logique et `lib/game/components/` pour le visuel.*
