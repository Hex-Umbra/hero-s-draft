# Hero's Draft - Roguelike Deckbuilder

"Hero's Draft" est un roguelike card game développé avec **Flutter** et **Flame**, utilisant **Riverpod** pour la gestion d'état. Le jeu propose des combats au tour par tour, des classes de personnages uniques, et un système de progression procédural.

## 1. Architecture Technique

Le jeu repose sur une architecture hybride séparant le rendu, l'interface et la logique métier :
- **Moteur de Jeu (Flame)** : Gère la boucle de jeu principale, le rendu des cartes (Héros et Ennemis) sur le plateau, les animations de combat (dash, buffs, tremblements) et les effets de particules.
- **Interface Utilisateur (Flutter)** : Gère le HUD (barres de vie, mana, boutons de fin de tour), les menus interactifs (écran de sélection, draft de cartes en fin de combat), et les tooltips descriptifs.
- **Gestion d'État (Riverpod)** : Centralise la logique métier via le `RunController` (statistiques du héros, niveau en cours) et le `DeckController` (gestion de la pioche, de la main, et de la défausse).
- **Data-Driven Design** : Les données du jeu (cartes, ennemis, héros, compétences) sont définies dans des fichiers JSON (`assets/data/`), chargés dynamiquement au démarrage via le `GameDataService`. Cela permet d'équilibrer le jeu sans recompiler.

## 2. Mécaniques Principales

### Système de Deckbuilding
Le joueur gère un deck de cartes. À chaque tour, il pioche des cartes (Attaques, Défenses, Soins) coûtant du Mana. Les cartes non jouées sont défaussées à la fin du tour. Le système inclut des mécanismes de ciblage (ciblage unique ou effets de zone).

### Intentions Ennemies (Telegraphing)
Les ennemis affichent leurs intentions (Attaquer, Se défendre, Se buffer) au-dessus de leur carte avant d'agir. Le joueur peut ainsi planifier sa défense et sa stratégie en conséquence.

### Résolution des Combats et Statistiques
Chaque entité possède des **PV (Points de Vie)**, de l'**Armure** (qui absorbe les dégâts avant les PV), une **Attaque** de base, et du **Mana** (pour le joueur). Les effets des cartes sont résolus dynamiquement via l'`EffectResolver`.

### Système de Draft (Loot)
À la fin de chaque combat, le jeu se met en pause et affiche un écran de Draft (Flutter). Le joueur peut y choisir des améliorations permanentes (bonus de PV max, d'attaque, d'armure ou de mana max) avant de passer au niveau suivant.

## 3. Feuille de Route et État d'Avancement

Le développement est structuré en plusieurs phases d'implémentation. 

### ✅ Phases Terminées (Disponibles dans `docs/implementation_plans/done/`)
1. **Architecture Data-Driven** : Migration des entités hardcodées vers des fichiers JSON.
2. **Système de Deckbuilding** : Implémentation de la pioche, défausse, coût en mana et gestion des cartes.
3. **Feedbacks UI/UX** : Ajout des intentions ennemies, tooltips, et amélioration des textes de dégâts flottants.
4. **Refactoring UI/Layout** : Restructuration du HUD, des barres de vie, et de l'intégration entre Flutter et Flame.
5. **Corrections Post-Refacto** : Stabilisation des bugs visuels et logiques suite à la refonte de l'interface.

### 🚧 Phases À Venir (En cours de planification)
6. **Interface Responsiveness** : Adaptation complète de l'interface Flutter et de la caméra Flame pour tous les formats d'écrans (Mobile, Tablette, Desktop).
7. **Profondeur de Gameplay** : Ajout d'altérations d'état (Buffs/Debuffs : Poison, Vulnérabilité, Régénération), de types de cartes spéciaux (Pouvoirs) et d'un système de Reliques passives.
8. **Expérience Audio & Juice** : Intégration de `flame_audio` pour la musique et les bruitages, ajout de systèmes de particules avancés et de "Screen Shake".
9. **World Map et Progression** : Remplacement de la progression linéaire par une carte du monde procédurale (nœuds de combat, marchands, feux de camp) et un système d'économie (Or).
