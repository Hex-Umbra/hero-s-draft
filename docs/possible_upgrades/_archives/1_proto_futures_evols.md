# Axes d'Amélioration et Évolutions Futures (Prototype Hero's Draft)

Suite à l'analyse approfondie du prototype actuel (MVP), voici une liste exhaustive d'axes d'amélioration et de nouvelles fonctionnalités à implémenter pour transformer ce prototype fonctionnel en un véritable jeu complet et engageant.

Ces recommandations sont divisées par catégories : Game Design, Interface & Expérience Utilisateur (UI/UX), et Architecture Technique.

---

## 1. Game Design & Mécaniques de Jeu (Core Loop)

Bien que le jeu s'intitule "Roguelike Deckbuilder", la mécanique de deckbuilding (piocher et jouer des cartes) est pour l'instant absente, remplacée par des compétences fixes et des choix de statistiques.

*   **Implémentation d'un Vrai Système de Cartes (Deckbuilding)** :
    *   Remplacer les compétences fixes (boutons en bas à droite) par une **main de cartes** tirée d'un deck personnel.
    *   Chaque tour, le joueur pioche X cartes (Attaques, Sorts, Compétences, Pouvoirs) qui coûtent du Mana.
    *   À la fin du combat (Draft), proposer de **nouvelles cartes** à ajouter au deck au lieu de simples augmentations de statistiques.
*   **Système d'Intentions Ennemies (Télégraphie)** :
    *   C'est la base des deckbuilders modernes (ex: *Slay the Spire*). Le joueur **doit savoir** ce que l'ennemi compte faire au prochain tour (Attaquer pour X dégâts, se buffer, se soigner) via une icône au-dessus de sa tête. Cela permet de planifier sa défense.
*   **États Altérés (Status Effects)** :
    *   Ajouter des buffs et debuffs temporels : *Poison* (dégâts par tour), *Faiblesse* (-25% dégâts infligés), *Vulnérabilité* (+50% dégâts reçus), *Étourdissement* (passe son tour).
*   **Diversité du Bestiaire & IA Ennemie** :
    *   Actuellement, les ennemis n'ont que des statistiques qui augmentent. Il faut créer des **archétypes d'ennemis** : Le "Tank" (beaucoup d'armure, protège les autres), le "Healer" (soigne ses alliés), le "Glass Cannon" (frappe très fort mais peu de PV).
    *   Dotation d'une vraie IA (patterns d'attaques au lieu d'une simple riposte automatique de dégâts).
*   **Carte de Progression (Pathing)** :
    *   Plutôt que d'enchaîner les combats linéairement, proposer une "Map" générée procéduralement avec des embranchements.
    *   Types de nœuds : Combat normal, Combat d'Élite, Feu de camp (soin ou amélioration de carte), Marchand, Événement aléatoire (choix narratif).
*   **Reliques / Artefacts** :
    *   Des objets passifs obtenus sur les Boss ou Élites qui modifient les règles de la partie de manière permanente (ex: "Le premier coup reçu chaque combat est ignoré").

## 2. Interface et Expérience Utilisateur (UI/UX)

Le rendu visuel actuel utilise les primitives de base de Flame (Rectangles colorés) et de Flutter. Une grande marge d'amélioration esthétique est possible.

*   **Refonte Visuelle (Assets Graphiques)** :
    *   Remplacer les rectangles de couleur par de vrais **Sprites** ou illustrations pour les Héros et les Ennemis.
    *   Ajouter des **fonds d'écran (Backgrounds)** animés ou changeants selon le biome/niveau pour l'arène de combat.
    *   Design de vraies cartes avec des bordures, des illustrations, des icônes de coût de mana, et une typographie claire.
*   **Amélioration du "Juice" (Animations et Feedbacks)** :
    *   *Particules* (Flame Particles) pour les explosions magiques, les coups d'épée, les saignements.
    *   *Screen Shake* (Tremblement d'écran) lors de gros coups critiques ou de la mort d'un boss.
    *   Animations d'attaque plus prononcées (dash vers l'avant, retour en position).
    *   Amélioration des *Floating Texts* (textes de dégâts) avec des polices stylisées, des tailles variables selon la violence du coup (critique), et des icônes à côté des chiffres.
*   **Amélioration des Retours Sonores (Sound Design)** :
    *   C'est souvent ce qui manque aux prototypes. Ajouter des sons d'impact, des sons pour l'UI (clics, survols), une musique d'ambiance dynamique (qui s'intensifie contre les boss).
*   **Accessibilité et Lisibilité** :
    *   Afficher des "Tooltips" (infobulles) lors d'un appui long sur un ennemi ou un buff pour expliquer exactement ce que fait une statistique ou un statut.
    *   Rendre la barre de vie plus visuelle (une vraie barre qui se vide, rouge/verte) plutôt que de simples compteurs textuels.

## 3. Architecture Technique et Scalabilité

Pour soutenir ces nouvelles fonctionnalités, la base de code devra évoluer.

*   **Séparation des Données et du Code (Data-Driven Design)** :
    *   Actuellement, les classes (Paladin, Mage) sont "hardcodées" dans les fichiers Dart.
    *   *Évolution* : Extraire les données des classes, des cartes, et des ennemis dans des fichiers de configuration (`JSON`, `YAML` ou une base de données locale/SQLite). Cela permettra un équilibrage (balancing) beaucoup plus rapide sans recompiler l'application.
*   **Système d'Événements Avancé (Event Bus)** :
    *   Avec l'ajout de Reliques et de Statuts complexes ("Quand vous jouez une carte Attaque, gagnez 1 armure"), un système d'Event Bus global (Publish/Subscribe) deviendra nécessaire pour que les reliques écoutent les actions du joueur et réagissent sans créer de dépendances croisées (Spaghetti Code).
*   **Amélioration de l'IA (Behavior Trees)** :
    *   Remplacer la méthode `_enemyRipostePhase` par un système d'Arbre de Comportement (Behavior Tree) ou une Machine à États Finis (FSM) pour chaque ennemi, permettant des patterns d'attaque complexes (Ex: Tour 1 Buff, Tour 2 Grosse attaque, Tour 3 Repos).
*   **Sauvegarde et Reprise de Partie (Persistence)** :
    *   Actuellement, quitter l'application perd la "Run". Utiliser `SharedPreferences` ou `Hive` pour sauvegarder l'état du `RunState` (Niveau, PV, Deck) à la fin de chaque combat, permettant au joueur de reprendre sa partie plus tard.