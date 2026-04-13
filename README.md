# Hero's Draft - Documentation du Prototype (MVP)

Ce document détaille toutes les mécaniques, l'architecture technique et les fonctionnalités implémentées dans le prototype actuel de "Hero's Draft".

## 1. Architecture Technique

Le jeu est un projet hybride utilisant les forces conjointes de Flutter et de solutions tierces pour créer une interface fluide :
- **Moteur de jeu :** `Flame` (gestion de la boucle de jeu `update/render`, affichage des entités via `PositionComponent`, effets visuels via les `Effects`).
- **Interface Utilisateur (HUD) :** `Flutter` natif (gestion des boutons de bas d'écran, écrans de fin de partie, et Draft de cartes).
- **Gestion d'État :** `Riverpod` (Partage d'état réactif entre Flame et Flutter de manière dédoublée via `RunController` et le pattern `StateNotifier`).

## 2. Système de Classes de Personnage

Le jeu propose actuellement trois classes que le joueur peut incarner. Le choix d'une classe définit les statistiques de départ du Héros. 
Ces classes sont configurées dans `lib/data/models/player_class.dart` :
- **Le Paladin** (Défaut) : Stats équilibrées, orientées survie avec beaucoup de PV, d'armure de base et 10% de Défense.
- **Le Berserker** : Orienté Dégâts, aucune armure ni défense, mais une très forte attaque.
- **Le Mage** : Orienté Altération avec des capacités intermédiaires.

## 3. Le Système de Statistiques et de Dégâts (`EntityStats`)

Chaque entité (Héros et Ennemi) possède ses propres statistiques :
- **PV (Points de Vie)** : La santé de l'entité. Si elle tombe à 0, l'entité meurt.
- **Armure** : Un bouclier temporaire. Tout dégât absorbé par l'armure réduit celle-ci. Ce n'est qu'une fois l'armure détruite que les PV sont touchés.
- **Attaque** : Les dégâts de base infligés par l'entité.
- **Défense** : Un pourcentage de réduction de dégâts (ex: `0.1` pour 10%).

#### Résolution des Dégâts
Lorsqu'une attaque a lieu (fonction `takeDamage`), l'algorithme suivant s'applique :
1. **Réduction par la défense** : Dégâts finaux = `Attaque adversaire * (1 - Défense de la cible)`.
2. **Absorption de l'armure** : L'armure encaisse en priorité ces dégâts finaux.
3. **Réduction des PV** : Le reliquat des dégâts si l'armure est brisée attaque les Points de Vie.

## 4. Le Système de Combat au Tour par Tour

Le mode de combat a été structuré avec les caractéristiques suivantes (`HerosDraftGame`) :
- **Sélection de Cible :** Avant d'agir, le joueur a l'obligation de cliquer sur l'un des monstres adverses (qui s'entoure d'une bordure colorée). Cette cible reste sélectionnée au fil des tours jusqu'à sa mort ou le changement manuel de cible.
- **Exécution du Tour :** Tant que le joueur n'appuie pas sur le bouton "Fin de Tour", le jeu est en pause. Lors du clic, on rentre dans une boucle asynchrone animée :
  1. Le joueur lance son attaque de mêlée sur l'ennemi (**Animation visuelle `bump` du joueur** vers le haut).
  2. Si l'ennemi ciblé meurt, il est supprimé du plateau. 
  3. Si des ennemis ont survécu, ils ripostent et attaquent le joueur **un par un** (Animation visuelle **Séquentielle** de `bump` vers le bas).

### Effets Formatifs (Floating Text)
Lorsqu'une stat est modifiée, un indicateur d'aide s'envole de la carte en question pendant une seconde :
- **Texte Rouge (`-X`)** : Affiché lors d'une perte de PV.
- **Texte Bleu foncé (`-X`)** : Affiché lors d'une perte d'Armure.
- **Texte Bleu clair (`+X`)** : Affiché lors d'un gain d'Armure (soin ou buff).

## 5. Compétences Spéciales du Joueur

Au lieu de n'avoir qu'une seule attaque de base, le joueur dispose de **deux Boutons d'interaction spéciale** qui partagent un Unique indicateur de `Cooldown` (réinitialisé à 3 tours d'attente à chaque utilisation). L'utilisation d'une compétence compte comme une action gratuite et requiert par la suite d'utiliser la Fin de Tour.

1. **Bouclier (+15 Armure) :** Restaure de façon brutale et instantanément 15 points d'armure au joueur. Lance l'animation de floating text bleue.
2. **Rage (+25% Attaque) :** Octroie un bonus multiplicateur à l'attaque du héros sur les 2 prochains tours (`attackBuffDuration`). Ajoute un indicateur visuel en haut à gauche de l'écran pour garder l'oeil sur les tours restants de la RAGE.

## 6. Génération Procédurale des Monstres

Le jeu scale la difficulté en fonction du niveau actuel via l'`EncounterSystem`. 
- Tous les 10 niveaux (Niveaux se terminant par 0) : Apparition d'un **Boss**. Un ennemi unique très résistant (Couleur d'entité Magenata/Violette) aux statistiques élevées.
- Aux autres niveaux : Apparition dynamique d'ennemis classiques (1 à 3 adversaires, Couleur rouge), la difficulté de ces ennemis augmente progressivement en réduisant le partage initial de vie.
- L'algorithme des statistiques des monstres croît via un mécanisme incluant des fonctions mathématiques exponentielles garantissant qu'ils deviennent de plus en plus difficiles au fil du temps.

## 7. Boucle de Jeu Complète

La boucle "Run" complète s'orchestre comme ceci :
1. Lancement de la partie et configuration initiale au niveau 1 (Création du Paladin par défaut).
2. Phase de **Combat** : Combat asynchrone au tour par tour décrit plus haut.
3. Phase de **Draft (Draft Screen)** : L'ensemble des monstres du mur étant occis, le module Flutter met en pause le moteur Flame (`_showDraft = true`) et affiche un écran par-dessus. Le joueur y obtient des récompenses permettant d'augmenter son PV Max, son armure ou ses dégâts.
4. Validation de la récompense => Avancée au **Niveau Suivant** => Nouvel appel à la génération paramétrique des monstres.
5. S'il meurt, la Run est stoppée et le joueur est redirigé vers l'écran **"Vous êtes Mort"** avec un bouton permettant de relancer une nouvelle boucle tout en recommençant au niveau 0.
