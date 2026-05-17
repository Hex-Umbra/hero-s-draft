# Rapport d'Analyse du Parcours Utilisateur : Hero's Draft (MVP)

Actuellement, le jeu se présente comme un prototype fonctionnel (MVP) d'un jeu de type "Roguelike Deckbuilder" (bien que l'aspect deckbuilding semble pour l'instant se concentrer sur des choix de statistiques/compétences plutôt que sur des cartes à piocher). La boucle de gameplay principale est complète, allant du lancement du jeu jusqu'à la mort du personnage.

Voici le parcours exact qu'expérimente un joueur :

## 1. L'Écran d'Accueil (Lancement)
*   **Visuel** : Le joueur arrive sur un menu très sobre et sombre, typique de l'ambiance roguelike, avec le titre "HERO'S DRAFT" écrit en lettres dorées.
*   **Action** : L'unique interaction possible est un grand bouton "JOUER".
*   **Rôle** : Introduire le joueur et démarrer l'expérience.

## 2. La Sélection de Classe (Préparation de la "Run")
*   **Visuel** : Le joueur fait face à un carrousel horizontal présentant plusieurs cartes de héros (Paladin, Mage, Berserker).
*   **Informations** : Chaque carte détaille l'identité de la classe (couleur distinctive, icône, nom), une brève description de son style de jeu (Lore), et surtout ses statistiques de départ (Points de Vie Max, Attaque, Armure).
*   **Action** : Le joueur analyse et choisit son archétype préféré via le bouton "Sélectionner", ce qui lance officiellement sa partie (Run) au Niveau 1.

## 3. L'Écran de Jeu (La Boucle de Combat)
C'est le cœur de l'expérience. Le joueur est plongé sur le champ de bataille (géré par le moteur de jeu interne). L'interface utilisateur vient se superposer à l'action avec plusieurs éléments clés :
*   **HUD (Affichage Tête Haute)** : En haut à gauche, le joueur voit en permanence le niveau actuel dans lequel il se trouve, ainsi que les éventuels "Buffs" actifs (par exemple, un bonus de Rage).
*   **Menu Pause** : En haut à droite, le joueur peut à tout moment mettre le combat en pause. Une fenêtre modale lui permet soit de reprendre l'action, soit d'abandonner et de retourner au menu principal.
*   **Les Actions et Compétences** : En bas à droite de l'écran, le joueur dispose de deux boutons de "Compétences Spéciales", uniques à la classe qu'il a choisie. Ces compétences coûtent des ressources (Mana ou Points de Vie) et ont des temps de recharge (Cooldowns).
    *   *Exemple (Paladin)* : Le joueur peut générer un gros bouclier (+15 armure) ou s'enrager pour augmenter ses dégâts en fonction de ses PV max.
    *   *Exemple (Mage)* : Le joueur peut déclencher une explosion de zone (Nova) ou cibler un ennemi avec la Foudre.
    *   *Exemple (Berserker)* : Le joueur sacrifie ses propres PV pour du vol de vie, ou brise l'armure d'une cible précise.
*   **La Gestion du Temps** : L'expérience se déroule au tour par tour. À droite de l'écran, un grand bouton "Fin de Tour" permet au joueur de passer la main aux ennemis une fois ses actions terminées. Passer son tour diminue les temps de recharge de ses compétences.

## 4. L'Écran de Récompense (Le Draft - Évolution du Héros)
*   **Déclencheur** : Lorsque le joueur réussit à tuer tous les ennemis présents à l'écran, le combat s'arrête instantanément.
*   **Visuel** : Un écran de récompense se superpose, félicitant le joueur.
*   **Action** : Le joueur se voit proposer **3 choix aléatoires** d'améliorations parmi 4 possibles (Vitalité pour les PV, Aiguisage pour l'Attaque, Plaque de Fer pour l'Armure, ou Sagesse pour le Mana).
*   **Conséquence** : Une fois la récompense sélectionnée par le joueur, le héros est amélioré de façon permanente, il récupère 50% de son mana max, ses temps de recharge sont remis à zéro, et le jeu passe au niveau suivant.

## 5. La Défaite (Le Game Over)
*   **Déclencheur** : Si, lors d'un combat, les Points de Vie (PV) du héros du joueur tombent à 0 ou moins.
*   **Visuel** : L'écran se teinte d'un voile rouge inquiétant avec le texte brutal "VOUS ÊTES MORT". L'action est figée.
*   **Action** : Le joueur est invité à recommencer avec deux choix clairs :
    1.  Retourner au "Menu Principal".
    2.  "Changer de Classe", ce qui le ramène directement à l'étape 2 (Sélection de Classe) pour retenter sa chance immédiatement avec une nouvelle stratégie.

---

## Synthèse des fonctionnalités acquises du point de vue Joueur

À ce stade de développement, votre jeu permet de :
1.  **Rejouabilité initiale** : Choisir parmi 3 classes distinctes avec des mécaniques uniques (Gestion du Mana vs Gestion des PV sacrifiés).
2.  **Système de combat complet** : Utiliser des compétences ciblées ou de zone, gérer des cooldowns, payer des coûts en ressources, obtenir des buffs temporaires, et interagir avec un système de tours.
3.  **Progression Roguelike (Snowball)** : Monter de niveau à l'infini en accumulant des bonus de statistiques de façon aléatoire (le Draft) à la fin de chaque salle/combat. Les boss (tous les 10 niveaux) sont pris en compte dans l'architecture de la progression.
4.  **Ergonomie de base** : Mettre le jeu en pause, comprendre l'état de ses cooldowns via l'interface, et redémarrer rapidement une session après un échec.