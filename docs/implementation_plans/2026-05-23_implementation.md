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

## Phase 63 - Restriction du bonus de Maîtrise d'Armure au seul Passif de Classe

- feat: Restreindre l'application du bonus d'armure global (`armorMastery`) pour qu'il n'impacte que les passifs de classe
    - Modification du calcul des gains d'armure de cartes classiques pour exclure le bonus et réorientation des tooltips.
        - **Problématique** : L'attribut de statistiques permanent `armorMastery` (augmenté via les récompenses ou buffs de maîtrise) était appliqué sans distinction à TOUS les gains d'armure du jeu, y compris lors du jeu de cartes ordinaires (ex: "Défense") via l'effet `armor` du résolveur.
        - **Résolution dans `EffectResolver`** : Suppression de `+ currentStats.armorMastery` dans le traitement de l'effet `armor` de `lib/game/services/effect_resolver.dart`. Désormais, jouer une carte d'armure n'ajoute que sa valeur propre (éventuellement scalée par son niveau).
        - **Réservation aux Passifs (`TraitSystem`)** : Le bonus global de maîtrise (`stats.armorMastery`) reste pleinement appliqué dans `lib/game/systems/trait_system.dart` lors du déclenchement automatique des passifs de classe (tels que `berserkerArmor`, `regenArmor` ou `spellArmor`). Cela respecte précisément le souhait de valoriser et d'améliorer spécifiquement la signature passive du personnage choisi.
        - **Mise à jour graphique (UI / Tooltips)** :
            - **Dans `hero_card.dart`** : Mise à jour de l'infobulle du badge d'armure pour indiquer de façon explicite : `Maîtrise d'Armure : +$mastery aux gains d'armure du passif de classe`.
            - **Dans `map_screen.dart`** : Modification du sous-titre de la statistique Maîtrise du panneau d'affichage pour spécifier : `Sur l'Armure Passive`.

## Phase 64 - Ajustement Ergonomique de la Hauteur de la Zone d'Annulation (Drag and Drop)

- ux: Remonter le seuil de la zone d'annulation lors du glisser-déposer des cartes
    - Modification de la coordonnée Y de détection de la cancel zone pour s'aligner naturellement avec le sommet de la main de cartes.
        - **Problématique** : La limite de la zone d'annulation était fixée très bas, à 80% de la hauteur de l'écran (`game.size.y * 0.8`). Comme les cartes en main s'étalent sur un arc de cercle positionné entre 77% et 85% de la hauteur de l'écran, le joueur devait glisser sa carte extrêmement bas pour annuler, ou risquait de jouer involontairement sa carte s'il la relâchait à peine au-dessus des autres cartes.
        - **Résolution dans `CardComponent`** : Remontée du seuil de détection dans `onDragUpdate` à 68% de la hauteur de l'écran (`game.size.y * 0.68`). Désormais, tout relâchement en dessous de cette ligne (donc dans la zone de la main de cartes) annule proprement le jeu et renvoie la carte en main sans déclencher d'action accidentelle. Le joueur doit faire glisser la carte clairement dans la moitié supérieure de l'écran pour la valider, ce qui rend le gameplay tactile 100% robuste, intuitif et naturel.

## Phase 65 - Intégration d'un Aperçu Flottant des Statistiques de Base sur la Carte

- feat: Ajout d'un panneau flottant compact présentant l'état du joueur directement sur l'écran de la carte
    - Création d'un overlay de statistiques épuré et esthétique positionné en bas à droite de la carte, parfaitement symétrique à la légende.
        - **Problématique** : Bien qu'il existe un menu complet très détaillé accessible via le bouton "STATS" de l'AppBar, le joueur n'avait pas de vue immédiate sur ses ressources (PV, Mana, Or) ni ses modificateurs de combat (Attaque, Maîtrise d'Armure, Chance) lors de son exploration de la carte de l'acte sans devoir ouvrir un dialogue modal.
        - **Résolution visuelle (`map_screen.dart`)** : Conception d'un panneau flottant `STATS DU HÉROS` placé au coin inférieur droit de la vue (`Positioned` à `right: 20, bottom: 20`), conçu en parfaite harmonie stylistique avec la légende médiévale (fond brun foncé semi-translucide `0xFF4A3728`, bordure dorée beige `0xFFD2B48C`, et ombrage marqué).
        - **Contenu Compact** : Ce panneau affiche de manière sobre et qualitative les statistiques fondamentales actualisées en temps réel via l'état Riverpod :
            - **PV** : `${stats.currentPv}/${stats.maxPv}` avec une icône de cœur rouge.
            - **Mana** : `${stats.currentMana}/${stats.maxMana}` avec un cristal cyan.
            - **Or** : `${runState.gold}` avec une pièce d'or dorée.
            - **Attaque** : `${stats.attaque}` avec le widget `SwordIcon` orange.
            - **Maîtrise d'Armure** : `+${stats.armorMastery}` avec un bouclier bleu ciel.
            - **Chance** : `${stats.luck}` avec un dé doré.
        - **Sous-composants** : Intégration de deux méthodes privées d'aide (`_buildMiniStatRow` et `_buildMiniStatRowWidget`) pour normaliser l'espacement, l'alignement et la typographie des lignes de statistiques afin de conserver un rendu graphique ultra-premium et rigoureux.

## Phase 66 - Optimisation du Centrage de la Caméra et Résolution de l'Affichage du Boss sur la Carte

- bugfix: Centrage horizontal par défaut au chargement de la carte et correction du boss coupé à moitié en haut
    - Résolution des coordonnées de centrage X/Y et décalage visuel global de la carte pour assurer la visibilité totale du nœud boss.
        - **Problématique 1 (Boss coupé)** : Le nœud final du boss est généré logiquement à l'ordonnée `posY = 0.0`. Dans la Stack de taille $1000 \times 3000$ pixels, cela positionnait le centre du nœud boss pile au niveau de la bordure supérieure de la vue. Son icône de taille $70$ pixels était donc tronquée à 50% de sa surface.
        - **Problématique 2 (Caméra excentrée)** : Au premier chargement de l'acte (`currentNodeId == null`), le moteur centrait la caméra sur le premier nœud de la première ligne. Or, ce nœud étant situé à l'extrême gauche, la caméra apparaissait collée au bord gauche de la carte, occultant les autres nœuds disponibles du premier étage.
        - **Résolution du Boss coupé (`map_screen.dart`)** : Application d'un décalage visuel constant `yOffset = 80.0` pixels sur l'axe vertical lors du rendu des composants dans le fichier `map_screen.dart`. Ce décalage a été répercuté à 4 endroits stratégiques :
            1. **`MapConnectionPainter`** : Décalage des coordonnées Y de début et de fin de chaque ligne tracée (`node.position.y + 80.0`).
            2. **`_MapNodeWidgetState`** : Décalage du `top` du composant de nœud (`widget.node.position.y - 35 + 80.0`).
            3. **`_PlayerPawn`** : Décalage du `top` du pion représentant le joueur (`position.y - 65 + 80.0`).
            4. **`WidgetsBinding.instance.addPostFrameCallback`** : Décalage de la cible de focalisation de la caméra (`targetNode.position.y + 80.0`).
            *Grâce à cette approche purement graphique en bout de chaîne, le boss est désormais parfaitement visible et décalé vers le bas de 80px, tandis que les tests unitaires logiques (qui exigent que le boss soit à `y = 0.0`) continuent de valider à 100%.*
        - **Résolution du Centrage Horizontal (`map_screen.dart`)** : Modification du calcul horizontal `actualX` dans les routines de centrage post-frame de `map_screen.dart`. Si aucun nœud de départ n'est actif, `actualX` est positionné sur `500.0` (le centre géométrique de la largeur de la carte de $1000$px). La caméra apparaît maintenant divinement centrée au milieu du premier étage, offrant au joueur une vision globale et claire de toutes les options de départ possibles.

## Phase 67 - Intégration du Défilement Vertical de la Carte à la Molette de la Souris (Scroll)

- ux: Permettre de faire défiler la carte de haut en bas ou de bas en haut avec la molette de la souris
    - Enveloppement de la vue InteractiveViewer dans un écouteur de signaux de pointage pour intercepter et transcrire les évènements de scroll.
        - **Problématique** : Le parcours de la carte se faisait exclusivement en cliquant et glissant (click-and-drag/pan) avec le pointeur ou le doigt. Sur ordinateur de bureau ou avec une souris de jeu, cette méthode s'avère moins naturelle et plus fatigante que le défilement fluide classique à la molette.
        - **Résolution ergonomique (`map_screen.dart`)** : 
            1. **Importation** : Ajout de la bibliothèque standard `package:flutter/gestures.dart` pour la gestion avancée des signaux physiques de la souris.
            2. **Intégration du `Listener`** : Enveloppement d' `InteractiveViewer` dans un widget `Listener` configuré sur la propriété `onPointerSignal`. 
            3. **Traduction du Scroll** : Dès qu'un `PointerScrollEvent` est capturé, la routine extrait la matrice de transformation active de `_transformationController`, récupère sa translation actuelle et lui applique un décalage vertical opposé au déplacement de la molette (`scrollDelta.dy`). La nouvelle coordonnée Y est réassignée en préservant intactes la translation X et la mise à l'échelle.
        - **Bénéfice** : Le joueur peut désormais faire défiler la carte verticalement de manière ultra-fluide avec sa molette (scroller vers le bas révèle le bas de la carte, scroller vers le haut révèle le boss au sommet), en parfaite synergie avec le glisser-déplacer d'origine qui reste 100% fonctionnel et réactif.

## Phase 68 - Centrage Horizontal du Titre de l'Acte dans la Toolbar de la Carte

- style: Forcer le centrage parfait du numéro de l'acte au milieu de l'AppBar
    - Réassignation de la propriété `centerTitle` de l'AppBar à true dans la vue de la carte.
        - **Problématique** : Le titre de l'acte exploré (ex : "Acte 1") apparaissait aligné à gauche par défaut à côté de la rangée de boutons outils de gauche, créant un déséquilibre esthétique notable dans l'AppBar.
        - **Résolution (`map_screen.dart`)** : Modification de la propriété `centerTitle` de `false` à `true` dans le constructeur de l' `AppBar`. Le titre s'affiche désormais de façon parfaitement équilibrée et royale au centre exact de la largeur de la barre d'outils, assurant un rendu graphique irréprochable et symétrique.

## Phase 69 - Épuration du Panneau Flottant de Statistiques de la Carte

- ux: Retirer la quantité d'or du petit panneau flottant de statistiques en bas à droite
    - Raccourcissement de la liste des statistiques affichées dans l'overlay de la carte.
        - **Problématique** : L'affichage redondant de l'or (déjà présent de manière proéminente en haut à droite dans l'AppBar avec une icône de pièce d'or sienne) encombrait inutilement le nouveau panneau flottant de statistiques rapides.
        - **Résolution (`map_screen.dart`)** : Retrait complet de la ligne d'or (`_buildMiniStatRow` d'or) du composant `Column` du panneau de statistiques flottant. Cela permet d'épurer l'overlay de statistiques rapides, en concentrant l'information uniquement sur l'état physique du héros (PV, Mana) et ses capacités passives (Attaque, Maîtrise, Chance), tout en maintenant une hauteur compacte idéale.
        
## Phase 70 - Résolution du plantage BackdropFilter sur Flutter Web (DDC) et raccourci d'œil des stats

- bugfix: Contournement des crashs de BackdropFilter sur le Web (DDC) et intégration d'un raccourci visuel d'œil pour les stats
    - Création d'un helper cross-platform de floutage/couleur opaque et intégration d'une icône d'œil dans le panneau flottant de la carte.
        - **Problématique 1 (Crash Web BackdropFilter)** : Sur Flutter Web (notamment sous le compilateur DDC), l'application de transitions de disparition (fondu, échelle) sur un widget `BackdropFilter` placé en racine de modale entraînait un plantage complet de l'application (écran blanc) avec l'erreur `Assertion failed: rendering/object.dart:318:16` puis `Aborted()`.
        - **Résolution du flou Web (`map_screen.dart`)** : Import de `package:flutter/foundation.dart` pour exposer `kIsWeb`. Implémentation d'une méthode de wrapping `_wrapWithBlur` dans `_MapScreenState` :
            - **Sur le Web** : Le `BackdropFilter` est remplacent par une couleur sombre translucide premium (`Colors.black.withValues(alpha: 0.75)`). Cela évite le calcul de flou gaussien défectueux en DDC tout en offrant un contraste exceptionnel.
            - **En Natif** : Le `BackdropFilter` traditionnel est conservé à l'intérieur d'un `ClipRect` de sécurité pour empêcher les fuites graphiques du flou gaussien.
            - Cette méthode a été appliquée sur les 3 modales de la carte (`_showNodeOverlay`, `_showStatsDialog`, `_showInventoryDialog`).
        - **Raccourci visuel "œil" (`map_screen.dart`)** : Ajout d'une icône `Icons.visibility_outlined` (œil) rétroéclairée dans le panneau flottant d'aperçu des statistiques rapides en bas à droite de la carte, permettant d'ouvrir directement la modale de statistiques complètes. Pour éviter tout dépassement RenderFlex (overflow) en basse résolution ou dans les suites de tests automatisés (avec la police carrée Ahem), le titre a été enveloppé d'un `Expanded` et la largeur a été ajustée de `140` à `165` pixels.

## Phase 71 - Refonte UX & Style du Combat (HUD du Joueur et barre de vie Ennemis)

- feat: Modernisation graphique de l'affichage de l'armure et de l'attaque en combat et aération de la scène de jeu
    - Remplacement des badges Flame flottants encombrants par un HUD bas Flutter complet et une barre de PV enrichie au-dessus des ennemis.
        - **Épurage de la Scène de Combat (Flame)** : Retrait de tous les anciens badges flottants individuels (`armorBadge` d'armure, `attackBadge` d'attaque, `statusIndicator` de buff/debuff) sur les cartes du joueur (`HeroCard`) et des monstres (`EnemyCard`). Les cartes physiques respirent et affichent fièrement leur design artistique sans surcharge.
        - **Modernisation de la barre de vie Ennemis (Flame)** : La barre de PV au-dessus de chaque ennemi sur le terrain (`StatBadge` de type `hp`) est devenue un tableau de bord compact et unifié (`130x16`) :
            - Affiche à gauche sa valeur d'attaque effective (icône épée `⚔️` ambre) et d'armure (icône bouclier `🛡️` bleu clair, visible en permanence y compris à `0`) à gauche de sa barre de vie.
            - Superpose graphiquement une jauge d'armure progressive bleue translucide par-dessus son remplissage de PV rouge, s'étirant dynamiquement.
        - **HUD Joueur Intégré (Flutter bas-milieu)** : Remplacement de la simple barre de PV par une ligne horizontale (`Row`) regroupant :
            - **Attaque** à gauche : Conteneur orange équipé de `SwordIcon` et affichant l'attaque effective mise à jour en temps réel (base + force active + bonus de sélection).
            - **Armure** à gauche : Conteneur bleu équipé de `Icons.shield` et affichant sa valeur (toujours visible, affiche `0` si l'armure est nulle).
            - **Barre de PV & Armure** (dans un `Expanded`) : Barre verte progressive sur laquelle se superpose graphiquement une jauge d'armure bleue translucide progressive s'étirant harmonieusement.
        - **Nettoyage statique** : Les importations devenues inutiles après le refactoring (`status_indicator.dart`, `stat_badge.dart`) ont été nettoyées, maintenant un rapport `dart analyze` parfait à 0 warning.

## Phase 72 - Ajustements Esthétiques et Effet 3D Translucide de l'Armure (Combat)

- style: Sublimation graphique de la barre d'armure en combat et design épuré en dégradés pour le joueur
    - Ajout d'un padding intérieur aux jauges d'armure du joueur (Flutter) et de l'ennemi (Flame) pour un effet de superposition 3D, et application de ShaderMask pour des statistiques joueur sans conteneur de couleur.
        - **Barre d'armure du joueur (Flutter)** : L'overlay d'armure bleue translucide superposé à la jauge de points de vie dispose désormais d'un padding intérieur (`vertical: 3.0`, `horizontal: 1.5`) et d'un arrondi (`borderRadius: BorderRadius.circular(8)`), complété par une fine bordure brillante cyan (`Colors.cyanAccent.withValues(alpha: 0.7)`). Cela donne une magnifique sensation de bouclier d'énergie 3D flottant par-dessus la jauge verte principale.
        - **Barre d'armure de l'ennemi (Flame)** : La jauge d'armure au-dessus des ennemis a également vu son padding intérieur ajusté (`vertPad = 2.0`, `horizPad = 1.5`), créant une cohérence visuelle parfaite avec le joueur et renforçant l'aspect de capsule d'armure flottante.
        - **Statistiques d'Attaque et d'Armure du joueur (HUD Bas)** :
            - Retrait complet du fond de couleur des conteneurs, des bordures et des ombres portées pour laisser respirer les icônes et les valeurs numériques sur un fond transparent.
            - Augmentation de la taille des icônes à `20` et des valeurs numériques à `16` (en gras) pour une lisibilité maximale à l'écran.
            - **Attaque** : Colorisation de l'icône de l'épée et de sa valeur avec un dégradé de rouge ardent (`Color(0xFFFF2A2A)` vers `Color(0xFFFF7A7A)`) via un composant `ShaderMask` avec `BlendMode.srcIn`.
            - **Armure** : Colorisation de l'icône du bouclier et de sa valeur (toujours affichée, même à `0`) avec un dégradé bleu glacier arctique (`Color(0xFF2196F3)` vers `Color(0xFF00E5FF)`).
        - **Robustesse et Performance** : Aucun problème de performance ou de rendu n'est introduit. Le code respecte à 100% les critères de typage fort et de linting.
