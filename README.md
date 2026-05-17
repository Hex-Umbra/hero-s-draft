# ⚔️ Hero's Draft - Roguelike Deckbuilder

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Flame](https://img.shields.io/badge/Flame-%23E040FB.svg?style=for-the-badge&logo=flame&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=for-the-badge&logo=dart&logoColor=white)

**Hero's Draft** est un Roguelike Deckbuilder dynamique, pensé pour offrir un "game feel" percutant et une architecture technique irréprochable. Développé avec **Flutter** et le moteur **Flame**, le jeu propose des combats tactiques, une progression procédurale sur carte, et une architecture 100% *Data-Driven*.

Site officiel: https://heros-draft.vilarserver.com/

---

## ✨ Key Features (Gameplay & Game Feel)

Le jeu a été conçu pour offrir une expérience fluide, réactive et stratégique, s'inspirant des références du genre tout en y ajoutant une forte dose de dynamisme (Visual Juice).

*   **🃏 Dynamic Combat & Visual Juice** : Le maniement des cartes est organique (tilt, inertie lors du glisser-déposer). Jouer une carte déclenche une séquence d'attaque percutante avec recul d'anticipation, impact visuel, tremblements d'écran (shake) et explosions de particules.
*   **🗺️ Strategic World Map** : L'exploration n'est plus linéaire. Les joueurs naviguent sur un graphe procédural généré dynamiquement. La carte inclut des chemins animés, des culs-de-sac stratégiques (chokepoints) et différents types de nœuds : Combats, Élites, Boss, Boutiques, Feux de camp et Événements narratifs.
*   **⚙️ Deep Mechanics & Traits** : 
    *   **Classes Uniques** : Paladin, Berserker, Mage, chacun possédant des traits passifs exclusifs (ex: régénération d'armure, gain de puissance selon les PV manquants).
    *   **Altérations d'État** : Gestion complète des buffs/debuffs (Poison, Force, Faiblesse, Régénération).
    *   **Système de Reliques** : Objets passifs modifiant l'économie de la partie.
*   **💰 Deckbuilding & Economy** : Gestion stricte du Mana (réinitialisé chaque tour), système de Draft post-combat avec **Auto-Merge** (fusionner 3 cartes identiques pour les améliorer), et une Boutique interactive pour affiner son deck ou retirer des cartes.

---

## 🏗️ Under the Hood (Architecture Technique)

Hero's Draft n'est pas qu'un jeu, c'est un moteur de deckbuilder robuste et extensible.

### The Power Couple : Flame 🤝 Riverpod
Le projet sépare strictement le rendu de la logique métier :
*   **Riverpod (Cerveau)** : Gère l'état global. Le `RunController` supervise les statistiques du joueur, les reliques et la progression sur la carte. Le `DeckController` gère la logique des piles (Main, Pioche, Défausse, Épuisement) de manière purement logique.
*   **Flame (Muscles)** : Gère la boucle de jeu, les entités (`PositionComponent`) et les animations. Les composants Flame écoutent les changements de Riverpod pour se mettre à jour, garantissant qu'aucun bug visuel ne puisse corrompre l'état de la partie.
*   **Flutter (Interface)** : Gère le HUD, les barres de vie, les modales fluides (Boutique, Repos) et les tooltips interactifs par-dessus le canvas Flame.

### 100% Data-Driven Heart
Pas de cartes ou d'ennemis codés en dur. Tout le contenu du jeu est externalisé dans des fichiers JSON (`assets/data/`). Le moteur lit ces fichiers au démarrage. 
Pour équilibrer le jeu, nerfer un ennemi ou modifier le coût en mana d'une carte, il suffit de changer une ligne dans un JSON, sans jamais recompiler le code métier.

### Responsivité Dynamique
Le jeu intègre un système de scaling sur mesure. Le moteur Flame s'adapte à la hauteur de l'écran, recalculant instantanément la taille et la position relative des cartes, des ennemis et de l'arène, garantissant une expérience parfaite du mobile au moniteur 4K.

---

## 🛠️ Developer Guide

### Lancer le projet
Hero's Draft est un projet Flutter standard. Assurez-vous d'avoir Flutter SDK (>= 3.11.4) installé.

```bash
# Récupérer les dépendances
flutter pub get

# Lancer sur l'appareil par défaut
flutter run

# Lancer les tests (génération de carte, résolution d'effets, etc.)
flutter test
```

### Modding (Ajouter du contenu)
Grâce à l'architecture Data-Driven, étendre le jeu est trivial :
1. Ouvrez `assets/data/cards.json` ou `enemies.json`.
2. Dupliquez une entrée existante et modifiez ses valeurs (nom, coût, effets, pv).
3. Relancez l'application. La nouvelle carte ou le nouvel ennemi est déjà dans le jeu, pris en compte par la Boutique, les récompenses et le système de combat !

*Note: Pensez à toujours lancer `dart analyze` après une modification du code.*

---

## 🚀 Roadmap & Status

Le moteur de base et l'architecture complète sont **terminés et fonctionnels** (Phases 1 à 12 validées).

**À venir :**
*   **Expérience Audio** : Intégration de `flame_audio` pour la musique dynamique et les effets sonores (SFX de cartes, impacts).
*   **Plus de Profondeur** : Nouvelles reliques, nouveaux archétypes de cartes (Malédictions à jouer) et de nouveaux événements narratifs.
*   **Polissage Final** : Équilibrage des derniers pourcentages, animations spécifiques aux boss, et préparation pour les plateformes de distribution.
