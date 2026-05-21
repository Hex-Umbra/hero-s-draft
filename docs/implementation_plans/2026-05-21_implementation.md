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
