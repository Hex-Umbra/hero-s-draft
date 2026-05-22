## Phase 29 - Ajustements de combat et simplification de l'affichage

- feat: suppression des MP des ennemis
    - retrait de l'indicateur visuel manaBadge et des mises à jour correspondantes dans le combat
        - J'ai terminé la suppression des MP des ennemis. Le composant `manaBadge` a été retiré de `EnemyCard` (déclaration, initialisation et rafraîchissement), ce qui épure l'interface de combat en masquant une statistique non utilisée par les monstres.

- fix: affichage de l'armure totale du héros
    - correction du format d'affichage (suppression de l'ancien format split base + bonus de style 0+11)
        - J'ai terminé la correction de l'affichage de l'armure du héros. En retirant les paramètres `baseValue` et `bonusValue` lors de l'appel à `updateValue` de l'armure dans `HeroCard`, le badge affiche désormais directement la valeur d'armure totale sous une forme simple et lisible (ex: 11 au lieu de 0+11).

- feat: refonte visuelle et animations sur l'écran de sélection des classes
    - implémentation de micro-animations (tilt 3D, icône flottante, halos pulsants et bouton premium) sur `ClassSelectionScreen`
        - J'ai terminé l'intégration de micro-animations sur l'écran de sélection de classe. Le widget `_InteractiveClassCard` offre un effet de rotation 3D dynamique en suivant le pointeur/doigt (via Matrix4), les icônes de héros oscillent doucement pour respirer, les bordures s'illuminent en surbrillance d'une aura colorée propre à la classe, et le bouton `_PremiumSelectionButton` gère des dégradés animés et des retours tactiles fluides d'échelle.

- feat: refonte des icônes d'attaque et de mana dans l'interface utilisateur
    - intégration d'un widget personnalisé `SwordIcon` (dessin vectoriel d'une épée) et de l'icône de cristal `diamond_rounded` pour le mana
        - J'ai terminé la refonte des icônes de statistiques de l'écran de sélection de classe et des cartes à jouer. Le mana utilise désormais l'icône de cristal `Icons.diamond_rounded` de couleur cyan (`Colors.cyanAccent`) identique à celle des cartes en combat. Pour l'attaque, en raison de l'absence d'une icône d'épée native dans le SDK Flutter utilisé, j'ai créé un widget `SwordIcon` sur mesure utilisant un `CustomPainter` pour tracer une épée vectorielle avec reliefs 3D et dégradés. Ce widget est utilisé dans les badges de l'écran de sélection de classe et comme motif de fond sur les cartes d'attaque.

- feat: affichage détaillé des traits passifs d'armure
    - intégration d'un panneau d'information permanent sur les cartes de classe décrivant le fonctionnement et l'activation des passifs
        - J'ai terminé l'ajout des descriptions détaillées des passifs d'armure sur l'écran de sélection de classe. Le widget `Tooltip` masquant les descriptions a été remplacé par un conteneur permanent affichant en clair les conditions d'activation et les effets des passifs (Régénération d'Armure, Armure du Berserker, Armure Magique), y compris la prise en compte du bonus de statistique "Maîtrise".

- feat: réduction de la taille des cartes de classe sur mobile et agrandissement des contenus internes
    - ajustement de l'affichage mobile via la grille à 2 colonnes tout en agrandissant les polices, icônes et boutons internes, et augmentation de la hauteur des cartes
        - J'ai terminé l'ajustement des cartes de classe sur mobile. Tout en conservant la disposition sur deux colonnes (largeur globale de carte réduite de moitié via `maxCrossAxisExtent: isMobile ? 200 : 400`), j'ai augmenté de façon significative la taille de l'ensemble des textes et des icônes à l'intérieur des cartes sur mobile (icône de héros de 32 à 48, nom de classe de 16 à 20, icônes de statistiques de 11 à 14, bouton de sélection de 34 à 38 de haut et police de 12 à 14). De légers ajustements d'espacement vertical (padding interne et SizedBox réduits) ont été appliqués pour loger ces éléments plus grands. Pour offrir un confort de lecture optimal et éviter tout dépassement de gabarit (overflow), j'ai augmenté la hauteur des cartes de classe sur mobile en ajustant le `childAspectRatio` à `0.68` (au lieu de `0.75`), apportant de précieux pixels de hauteur supplémentaires et une aération visuelle d'exception.
## Phase 30 - Correction du bug d'affichage et superposition du poison

- fix: résolution du bug de superposition et de rafraîchissement des dégâts de poison
    - implémentation d'une comparaison de listes en profondeur et d'une mise à jour en place (reconciliation) des icônes de statut
        - J'ai terminé la correction du bug d'affichage des dégâts de poison. Le composant `StatusIndicator` a été optimisé pour effectuer une comparaison en profondeur (`_areStatusListsEqual`) des statuts de l'entité lors de chaque mise à jour, évitant ainsi les rafraîchissements redondants. De plus, le mécanisme asynchrone d'effacement complet (`removeAll`/`add`) a été remplacé par un système de réconciliation en place (`updateStatus`), permettant de mettre à jour la valeur textuelle directement sur le composant existant. Cela élimine définitivement les conflits de timing asynchrone et les superpositions de textes (valeurs illisibles) lorsque du poison est réappliqué sur un ennemi déjà empoisonné.

## Phase 31 - Amélioration de l'interaction et de la désélection des cartes en combat

- feat: possibilité de désélectionner une carte en recliquant dessus
    - modification de la gestion de focus dans `CardComponent.onTapDown` pour basculer (toggle) l'état de sélection
        - J'ai terminé l'amélioration de la sélection de carte en combat. Désormais, lorsqu'un joueur clique sur une carte déjà sélectionnée (qui a le focus), elle est automatiquement désélectionnée en appelant `game.setFocusedCard(null)`. Si la carte n'a pas le focus, elle est sélectionnée normalement. Cela offre une interaction plus intuitive et naturelle en plus du clic sur le fond de l'écran pour annuler la sélection.
## Phase 32 - Ajustements UI : Barre de vie, Intentions des ennemis et Bouton Mon Deck

- feat: Rendre la barre de vie du joueur plus épaisse et arrondie
    - Augmentation de l'épaisseur de la barre de progression des PV dans le HUD inférieur
        - J'ai terminé l'épaississement de la barre de vie du joueur. En ajustant le paramètre `minHeight` du `LinearProgressIndicator` dans `game_screen.dart` de `12` à `22` pixels et en lui ajoutant des coins arrondis avec un `BorderRadius.circular(12)` dans un widget `ClipRRect`, la barre de vie est désormais beaucoup plus visible, moderne et premium.

- feat: Repositionnement ergonomique du bouton "Mon Deck"
    - Déplacement du bouton "Mon Deck" du HUD inférieur vers le HUD supérieur à côté du bouton pause
        - J'ai terminé le repositionnement du bouton "Mon Deck". Auparavant superposé à la barre de vie dans la partie inférieure de l'écran, il est désormais placé tout en haut à droite à `Positioned(top: 10, right: 75)`. Il se trouve idéalement aligné à gauche du bouton Pause (qui est à `right: 20`), arborant une icône de couleur ambre de taille `40` pour une ergonomie optimale sans aucune superposition d'éléments.

- feat: Réduction de la taille de l'affichage de l'intention des ennemis
    - Optimisation de la taille et de la typographie du composant `IntentionIndicator`
        - J'ai terminé la réduction de taille de l'indicateur d'intention des ennemis. Les dimensions du composant dans `intention_indicator.dart` ont été réduites de `Vector2(90, 45)` à `Vector2(74, 34)` (soit environ 25% de réduction), rendant l'interface plus épurée. Les tailles de police ont été ajustées en conséquence : le label "Next action" passe de `10` à `8`, l'indicateur d'action de `12` à `10` et la valeur numérique de l'intention de `18` à `13`. La bordure a été affinée de `1.5` à `1.0` de largeur de ligne, et les coordonnées verticales des textes ont été adaptées à la nouvelle hauteur pour un rendu centré et impeccable.

## Phase 33 - Inversion de l'effet d'inclinaison 3D (tilt) sur l'écran de sélection de classe

- feat: Inversion du sens de rotation 3D des cartes de classe au survol de la souris
    - Inversion des angles `rotateX` et `rotateY` du widget `Transform` dans `class_selection_screen.dart`
        - J'ai terminé l'inversion du sens du tilt 3D sur l'écran de sélection de classe. Au lieu de s'incliner vers le curseur (ce qui rapprochait la zone survolée de l'écran), les signes mathématiques des rotations de la transformation 3D ont été inversés (`..rotateX(currentTiltY)` et `..rotateY(-currentTiltX)`). Désormais, la zone située sous la souris recule vers l'arrière-plan (effet d'enfoncement tridimensionnel) tandis que la partie opposée pivote vers l'avant, créant une interaction plus vivante, moderne et digne d'un jeu de cartes premium.

## Phase 34 - Résolution du bug de scaling des dégâts d'intentions des ennemis

- fix: Correction du bug d'attaque de l'intention de l'ennemi inférieure à sa statistique d'attaque
    - Implémentation du getter réactif `effectiveIntent` dans `enemy_card.dart` et utilisation dans le combat de `heros_draft_game.dart`
        - J'ai terminé la correction du bug de scaling de dégâts d'attaques des intentions ennemies. Auparavant, les intentions d'attaques des ennemis utilisaient des valeurs numériques statiques chargées depuis le fichier JSON (`enemies.json`) sans tenir compte des augmentations de leur statistique d'attaque active (Force / buffs de combat). J'ai introduit un getter dynamique `effectiveIntent` on le composant `EnemyCard` qui calcule la valeur d'attaque effective en appliquant la formule `V_effective = max(stats.effectiveAttaque, V_statique + (stats.effectiveAttaque - baseDamage))`. Cela permet de prendre en compte dynamiquement les buffs de Force issus du statut `strength` (via `stats.effectiveAttaque`), tout en conservant l'esprit des attaques lourdes ou légères et en garantissant qu'un ennemi ne puisse jamais attaquer pour moins que son attaque de base ou active actuelle. De plus, le badge d'attaque de l'ennemi a été synchronisé pour afficher le format étendu `Total (Base + Force)` de manière réactive. L'indicateur visuel d'intentions est également forcé à se mettre à jour immédiatement dès que `updateStats` est appelé, et le moteur de jeu utilise désormais cette intention effective pour infliger les dégâts au joueur lors de la phase de riposte.

## Phase 35 - Intégration immersive des événements et affichage des statistiques vitales

- feat: Affichage des PV et des Pièces d'Or dans l'écran d'événement
    - Intégration d'un en-tête de statistiques réactif affichant les points de vie et l'or actuel du joueur
        - J'ai terminé l'ajout d'une barre de statistiques en haut de `EventScreen`. En écoutant le `runProvider`, nous récupérons dynamiquement les PV actuels/max et l'or. Ces informations sont présentées de manière élégante et premium via deux badges personnalisés avec des icônes colorées (`Icons.favorite` en rouge pour les PV et `Icons.monetization_on` en ambre pour l'or), permettant au joueur de faire des choix d'événements éclairés.

- feat: Ouverture des événements en tant qu'overlay flouté sur la carte
    - Modification de la transition de carte vers les événements pour utiliser `_showNodeOverlay`
        - J'ai harmonisé l'ouverture des nœuds d'événement avec celle des boutiques et zones de repos. Désormais, cliquer sur un événement n'effectue plus une transition de page classique, mais ouvre l'événement directement sous forme d'overlay modal sur la carte (`map_screen.dart`), floutant l'arrière-plan grâce à un filtre de flou gaussien (`BackdropFilter`).



