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
