## Phase 58 - Affichage des Statistiques et de l'Inventaire des Reliques depuis la Carte

- feat: Ajout d'un panneau de statistiques et d'un inventaire des reliques accessibles depuis la carte
    - Intégration de boutons compacts dans l'AppBar de MapScreen à côté de "Mon Deck" et développement de deux dialogues overlays immersifs en glassmorphism.
        - J'ai conçu et intégré une barre d'outils étendue dans l'AppBar de `map_screen.dart` (en augmentant `leadingWidth` à `360` et en alignant les boutons horizontalement dans une `Row` compacte équipée de paddings réduits). En plus du bouton "MON DECK" pré-existant, le joueur dispose désormais de deux nouveaux boutons : "STATS" et "RELIQUES".
        - **Dialogue des Statistiques (STATS)** : Affiche de manière ultra-qualitative la classe active (icône et couleur associées issues de la sélection de classe), les PV actuels/max équipés d'une barre de vie animée aux dégradés verts, le mana actuel/max via des cristaux cyan rétroéclairés, et les statistiques de combat flat (Attaque vectorisée, Maîtrise d'Armure et Chance) ainsi qu'un encadré récapitulatif clair du passif de classe actif.
        - **Dialogue de l'Inventaire (RELIQUES)** : Présente les reliques possédées par le joueur sous forme de grille adaptative. Chaque relique est enveloppée dans une carte au liséré violet mystique, indiquant son nom, ses effets et son moment de déclenchement ("Début Combat", "Fin Tour", etc.) grâce à des tags colorés contextuels. Un état vide soigné incite le joueur à combattre des Élites pour remplir son inventaire.
        - Les deux overlays s'ouvrent via `showGeneralDialog` avec un filtre de flou gaussien d'arrière-plan (`BackdropFilter`) et une transition d'échelle élastique fluide (`ScaleTransition` avec `Curves.easeOutBack`) pour un effet 100% premium et dynamique conforme au reste du jeu.

## Phase 59 - Refactoring Data-Driven des Passifs d'Armure

- feat: Rendre le système de passifs d'armure de classe dynamique et piloté par les données
    - Création d'un asset JSON externe, implémentation d'un nouveau modèle PassiveData et refactoring du moteur de jeu et de l'interface graphique.
        - J'ai créé un fichier d'asset `assets/data/passives.json` qui externalise et standardise les propriétés (déclencheurs, types d'effet et valeurs) des passifs d'armure existants (`regenArmor`, `berserkerArmor`, `spellArmor`), le calquant directement sur l'architecture de données robuste des Reliques.
        - **Nouveau Modèle `PassiveData`** : Implémenté dans `lib/models/data/passive_data.dart`, il gère la dé-sérialisation JSON et propose une méthode de repli `PassiveData.fallback` garantissant une rétrocompatibilité complète et sécurisée avec l'ensemble des tests unitaires et de widgets existants du projet.
        - **Refactoring du Moteur (`TraitSystem`)** : Les vérifications en dur de chaînes textuelles dans `lib/game/systems/trait_system.dart` ont été entièrement réécrites. Les hooks de début de tour, de fin de tour et de carte jouée interprètent désormais de manière totalement dynamique le trigger, le type d'effet (ex: `berserker_armor`, `gain_armor`, `spell_armor`) et la valeur numérique déclarés dans le fichier JSON.
        - **Nettoyage de l'UI** : Les écrans `class_selection_screen.dart` et `map_screen.dart` ont été purgés de leurs longs switch-cases statiques. Le nom et la description du passif affichés à l'écran sont maintenant résolus de manière purement dynamique via l'objet passif actif de l'état global Riverpod (`RunState.activePassive`), créant un design 100% data-driven.

## Phase 60 - Ajustement du dégradé du bouton du Paladin

- style: Personnalisation du dégradé du bouton de sélection du Paladin
    - Remplacement du calcul de dégradé générique par des couleurs royal navy et bleu azur éclatant à haut contraste.
        - Afin de mieux marquer la couleur de classe et de rehausser le rendu premium du bouton du Paladin sur l'écran de sélection de classe, j'ai introduit une règle spécifique dans le constructeur de dégradé de `_PremiumSelectionButton`. Au lieu d'utiliser l'interpolation par défaut, le bouton du Paladin utilise désormais un dégradé de bleu marine royal profond (`0xFF0D47A1`) vers un bleu azur/cyan éclatant (`0xFF00B0FF`). Cela crée une transition de couleur riche, vibrante et à fort contraste parfaitement intégrée à la charte graphique.

## Phase 61 - Flexibilité de Sélection des Cartes unaffordables en Combat

- feat: Autoriser la sélection et le drag-and-drop des cartes même sans mana suffisant
    - Découplage de la phase de réflexion (sélection/drag) et de la phase d'exécution (jeu effectif de la carte).
        - **Dans `CardComponent`** : Le getter privé `_canAfford` a été renommé en `canAfford` (public) et la méthode `_shakeAnimation` a été renommée en `shakeAnimation` (publique). Les vérifications restrictives de mana ont été totalement retirées de `onTapDown` et de `onDragStart`. Cela permet au joueur de toucher/sélectionner librement n'importe quelle carte et de commencer son glisser-déplacer, favorisant ainsi la planification visuelle de ses tours.
        - **Dans `onDragEnd`** : Si le joueur relâche la carte sur une cible ou la zone de jeu mais qu'il ne dispose pas de mana suffisant (`!canAfford`), la carte déclenche désormais son animation de secousse (`shakeAnimation()`) et retourne en main de manière fluide (`_returnToHand()`), bloquant l'action uniquement lors de la tentative réelle d'exécution.
        - **Système Click-to-Play** : Les handlers de ciblage de `_handlePlayerTargeting` dans `heros_draft_game.dart` (pour le ciblage d'ennemis) et `onTapDown` dans `hero_card.dart` (pour le ciblage de soi-même) interceptent le clic si la carte ciblée n'est pas payable, déclenchent la secousse visuelle (`shakeAnimation()`) et bloquent l'action sans pour autant désélectionner la carte, réduisant significativement toute frustration liée à la prise de décision en combat.

## Phase 62 - Correction du buff permanent de l'événement Autel Mystérieux

- bugfix: Correction de l'application du buff de +1 Attaque de l'événement "Autel" pour qu'il soit persistant
    - Remplacement de l'application d'un effet temporaire de combat par une modification directe et permanente de la statistique d'attaque de base du héros.
        - **Problématique** : L'action `gain_strength` de l'événement "Autel Mystérieux" instanciat précédemment un `StatusEffect` temporaire de 3 tours appliqué hors combat via `addStatus`. Ce dernier était systématiquement écrasé et réinitialisé (`statuses: []`) lors du lancement du combat suivant par le `RunController`.
        - **Résolution** : Modification de la gestion de l'action `gain_strength` dans `event_screen.dart` pour qu'elle appelle désormais directement `runController.applyHeroStatModifier(attackAcc: action.value as int)`. Le buff de +1 Attaque s'ajoute ainsi de manière définitive à la statistique de base `attaque` du héros (comme le fait déjà l'action `gain_max_hp` pour les points de vie), persistant correctement à travers les combats et apparaissant proprement dans les panneaux de statistiques.
        - **Nettoyage** : Suppression de l'import inutilisé `status_effect.dart` dans `event_screen.dart` identifié par l'analyse statique de Dart.


