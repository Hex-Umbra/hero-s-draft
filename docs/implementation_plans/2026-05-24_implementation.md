## Phase 73 - Refonte Visuelle des Statuts, Alignements et Effet 3D Englobant (Combat)

- style: Alignement horizontal du HUD, boucliers vectoriels Flame, et indicateurs verticaux de debuffs sur les cartes
    - Intégration de structures symétriques pour le HUD, dessins géométriques 3D de boucliers et d'épées en Flame, et empilement précis des debuffs (poison, etc.) sur le flanc droit des cartes de combat.
        - **Indicateur de Debuffs Verticaux sur les Cartes (Flame)** :
            - Ré-intégration complète de `StatusIndicator` sur le côté droit de `HeroCard` et `EnemyCard` (`position = Vector2(size.x + 4, 10)`), à l'extérieur de leur bordure de carte.
            - Empilement vertical des icônes de statut (`currentY += 36` à chaque rafraîchissement) au lieu d'une disposition horizontale pour éviter tout débordement ou gêne visuelle.
            - Restructuration visuelle de `_StatusIcon` (taille ajustée à `20x20` et taille d'émoticône à `14`) :
                - **Quantité de dégâts / valeur** : S'affiche à droite de l'icône à la coordonnée `position = Vector2(22, size.y / 2)` avec un ancrage `Anchor.centerLeft`, coloré en vert brillant (buff) ou rouge (debuff) avec un ombrage marqué.
                - **Tours restants** : S'affiche en bas de l'icône à la coordonnée `position = Vector2(size.x / 2, size.y + 1)` avec un ancrage `Anchor.topCenter`, coloré en jaune ambré brillant (`Colors.amberAccent`), rendant les statuts extrêmement faciles à lire en un coup d'œil.
        - **Superposition d'Armure Englobante (Effet 3D)** :
            - Inversion de la logique de rembourrage (*padding*) afin que la jauge bleue translucide d'armure enveloppe et « englobe » la jauge de points de vie au lieu d'être logée à l'intérieur.
            - **HUD Joueur (Flutter)** : Le remplissage vert de PV a été doté d'un padding de `3.0`px vertical et `1.5`px horizontal (agissant comme le noyau physique interne), tandis que l'overlay bleu translucide s'étend sur presque toute la hauteur du conteneur parent (padding minimal de `0.5`px) avec un `borderRadius` de `10` et une bordure cyan active, créant une enveloppe d'énergie externe protectrice très qualitative.
            - **Rendu Ennemis (Flame)** : Même modification appliquée dans `LinearProgressBarComponent` ; le remplissage rouge des PV reçoit un padding interne (`pvVertPad = 2.0`, `pvHorizPad = 1.5`), et la jauge bleue d'armure s'affiche presque à pleine hauteur (`vertPad = 0.5`, `horizPad = 0.5`, arrondi `3.5`) pour englober la barre de vie.
        - **Icônes Ennemis Homogénéisées (Flame)** :
            - Remplacement complet des anciens émojis textuels `⚔️` et `🛡️` par les exactes répliques des icônes du joueur pour une cohérence graphique absolue.
            - L'épée de l'ennemi est dessinée via un composant vectoriel custom `FlameSwordIcon` (reprenant le dessin en perspective de `CustomPainter`) de couleur rouge assortie (`Color(0xFFFF3B30)`), avec sa valeur textuelle en rouge vif.
            - Le bouclier est rendu à l'aide d'un composant vectoriel custom `FlameShieldIcon` de taille `10x10` dessiné en bleu-cyan (`Color(0xFF2196F3)`). Il utilise le même effet de biseau 3D que l'épée (moitié gauche sombre, moitié droite claire) et est orné d'une fine bordure brillante cyan intense (`Colors.cyanAccent`), offrant un rendu parfaitement stable et indépendant des polices de caractères du système, avec sa valeur textuelle en cyan vif.
        - **Centrage Mathématique du HUD Joueur (Flutter)** :
            - Résolution du décalage de la barre de vie provoqué par l'ajout des statistiques sur son côté gauche.
            - Élargissement de l'enveloppe du HUD bas à `screenWidth * 0.52` et réorganisation de la `Row` avec deux conteneurs `Expanded(flex: 1)` entourant une barre de vie de taille fixe `screenWidth * 0.26`.
            - Les statistiques sont alignées à droite du conteneur de gauche, créant un alignement parfait avec le bord gauche de la barre de vie, tandis que l'espaceur de droite garantit un **centrage horizontal absolu et pixel-perfect** de la barre de vie à l'écran.
        - **Correction de la Récompense d'Armure (Draft)** :
            - Alignement de la description du draft dans `lib/ui/screens/draft_screen.dart` avec les règles mécaniques de la Phase 63.
            - Remplacement de l'ancien descriptif de la récompense d'armure "Forge d'Acier" (`+$boost à tous vos gains d'Armure`) par `+$boost aux gains d'Armure de votre passif`.
        - **Robustesse et Performance** : Aucun problème de performance ou de rendu n'est introduit. Le code respecte à 100% les critères de typage fort et de linting.

## Phase 74 - Séparation Sémantique des Buffs/Debuffs Ennemis et Épuration du Héros (Combat)

- feat: Distinction visuelle des buffs/debuffs sur les cartes ennemies et suppression des indicateurs sur la carte du joueur
    - Séparation des effets en buffs (côté gauche de la carte de l'ennemi) et debuffs (côté droit), et suppression de l'affichage redondant sur la carte du héros.
        - **Distinction Buffs vs Debuffs Ennemis (Flame)** :
            - Division de l'ancien `statusIndicator` unique dans `EnemyCard` en deux instances spécialisées : `buffIndicator` et `debuffIndicator`.
            - Positionnement asymétrique soigné :
                - Les buffs (effets positifs de type `StatusType.buff` comme la force ou la régénération d'armure) sont empilés à gauche de la carte : `position = Vector2(-36, 10)`.
                - Les debuffs (effets négatifs de type `StatusType.debuff` comme le poison ou la vulnérabilité) sont empilés à droite : `position = Vector2(size.x + 4, 10)`.
            - Filtrage dynamique via `stats.statuses.where((s) => s.type == StatusType.buff).toList()` (pour les buffs) et `stats.statuses.where((s) => s.type == StatusType.debuff).toList()` (pour les debuffs) lors de l'initialisation dans `onLoad` et des mises à jour dans `updateStats`.
        - **Épuration de la Carte du Joueur (`HeroCard`)** :
            - Le joueur bénéficiant déjà d'un panneau HUD Flutter dédié et complet au bas de l'écran de combat pour afficher ses statuts actifs, l'affichage d'un second indicateur à droite de la carte `HeroCard` a été entièrement supprimé.
            - Cela allège visuellement la partie inférieure de l'arène de combat et évite toute surcharge d'informations en éliminant les redondances.

## Phase 75 - Modèle de Données des Reliques et Base de Données JSON

- feat: Ajout du fichier de données `relics.json` contenant 12 reliques et mise à jour du modèle `RelicData` avec rareté et emojis
    - Création d'une base de données équilibrée de 12 reliques et extension du modèle de données Dart pour inclure les attributs visuels et de classification requis.
        - **Création du Fichier `assets/data/relics.json`** :
            - Définition de 12 reliques distinctes couvrant 6 déclencheurs (`startOfRun`, `startOfCombat`, `startOfTurn`, `endOfTurn`, `onCardPlayed`, `onEnemyKilled`) et 5 types d'effets (`gain_armor`, `gain_mana`, `gain_strength`, `heal`, `gain_luck`).
            - Attribution d'une rareté (`common`, `uncommon`, `rare`, `epic`, `legendary`) et d'un emoji approprié pour chaque relique.
        - **Mise à Jour de `RelicData` (`lib/models/data/relic_data.dart`)** :
            - Ajout de l'énumération `RelicRarity` représentant les 5 niveaux de rareté.
            - Ajout des champs `rarity` (de type `RelicRarity`) et `emoji` (de type `String`) à la classe `RelicData`.
            - Adaptation du constructeur constant et mise à jour de la fabrique `RelicData.fromJson` pour analyser et injecter ces nouvelles propriétés depuis le JSON.

## Phase 76 - Intégration et Chargement Asynchrone des Reliques dans le Registre

- feat: Enregistrement et chargement de `relics.json` via `GameDataService` et association dans `GameDataRegistry`
    - Configuration de la chaîne de chargement des ressources de l'application pour inclure le nouveau catalogue de reliques.
        - **Mise à Jour de `GameDataRegistry` (`lib/models/data/game_data_registry.dart`)** :
            - Déclaration du champ final `List<RelicData> relics` pour stocker en mémoire les reliques disponibles.
            - Ajout de ce champ comme paramètre requis dans le constructeur constant de la classe.
        - **Mise à Jour du Service de Chargement (`lib/services/game_data_service.dart`)** :
            - Chargement asynchrone du fichier `assets/data/relics.json` via le `rootBundle`.
            - Décodage et conversion du JSON brut en une liste d'instances de `RelicData` typées.
            - Fourniture de cette liste au constructeur de `GameDataRegistry` retourné par le `gameDataLoaderProvider`.

## Phase 77 - Extension de la Logique de RunController (Effets de Reliques et Triggers)

- feat: Ajout du traitement de `gain_luck`, correction de `gain_strength`, et implémentation de `onEnemyKilled()` dans `RunController`
    - Implémentation des règles de résolution d'effets de reliques et enrichissement des points de déclenchement du moteur de jeu.
        - **Mécanique de Force Corrigée (`gain_strength`)** :
            - Distinction selon le trigger : pour un déclenchement de type `startOfRun`, le bonus de Force est appliqué de manière permanente aux caractéristiques fondamentales du héros via `applyHeroStatModifier(attackAcc: relic.value)`.
            - Pour les autres triggers (ex: début de combat), le bonus est appliqué via un `StatusEffect` d'une durée de 99 tours (couvrant tout le combat) au lieu de l'ancienne limite de 3 tours.
        - **Mécanique de Chance Implémentée (`gain_luck`)** :
            - Ajout du cas `gain_luck` dans `_applyRelicEffect`.
            - Augmentation permanente de la Chance du héros via `applyHeroStatModifier(luckAcc: relic.value)` pour le trigger `startOfRun`.
            - Pour les autres cas, incrémentation directe et dynamique de la statistique `luck` dans `heroStats`.
        - **Nouveau Déclencheur d'Élimination d'Ennemi (`onEnemyKilled()`)** :
            - Ajout de la méthode `onEnemyKilled()` qui appelle `applyRelics(RelicTrigger.onEnemyKilled)` pour appliquer les effets des reliques correspondantes (tels que "Essence Spirituelle" et "Croc Vampirique").

## Phase 78 - Signalement et Transmission de la Mort des Ennemis (Flame)

- feat: Ajout du callback `onEnemyKilled` dans `HerosDraftGame` et déclenchement lors du décès d'un adversaire
    - Propagation de l'événement de mort des ennemis depuis le moteur de rendu Flame vers le gestionnaire d'état Flutter.
        - **Ajout du Callback (`lib/game/heros_draft_game.dart`)** :
            - Intégration de la fonction de rappel `onEnemyKilled` de type `void Function()` dans la signature et le constructeur de `HerosDraftGame`.
        - **Déclenchement lors des Compétences de Dégâts** :
            - Appel de `onEnemyKilled()` dans la méthode `executeSkill` à la mort d'un ou plusieurs ennemis via des compétences de zone (`damage_aoe`), ciblées (`damage_targeted`) ou perforantes (`damage_pierce`).
        - **Déclenchement lors de la Phase de Riposte Ennemie** :
            - Appel de `onEnemyKilled()` lors du nettoyage des ennemis succombant aux effets récurrents de combat (tels que le poison) dans `_enemyRipostePhase()`.

## Phase 79 - Raccordement des Triggers et Attribution de Relique de Boss (UI & Game loop)

- feat: Intégration des triggers de reliques `onCardPlayed`, `endOfTurn`, `onEnemyKilled` et attribution de relique après combat de Boss dans `GameScreen`
    - Raccordement du moteur graphique et de l'interface utilisateur avec la logique des reliques et le système de récompenses du jeu.
        - **Intégration d'onEnemyKilled** :
            - Liaison du callback de mort de `HerosDraftGame` avec `runController.onEnemyKilled()` lors de l'initialisation du jeu.
            - Appel de `runController.onEnemyKilled()` dans `onPlayCard` lors du nettoyage local des ennemis tués par le joueur.
        - **Intégration d'onCardPlayed et endOfTurn** :
            - Ajout du déclencheur `applyRelics(RelicTrigger.onCardPlayed)` après la résolution réussie d'une carte dans `onPlayCard`.
            - Ajout du déclencheur `applyRelics(RelicTrigger.endOfTurn)` lors de l'activation du bouton « Fin de Tour ».
        - **Attribution des Reliques de Boss** :
            - Dans le callback de victoire de combat (`onEnemiesDead`), détection si le nœud actuel est de type `MapNodeType.boss`.
            - Tirage pondéré par rareté : 50% Commun, 30% Peu Commun, 13% Rare, 5% Épique, 2% Légendaire.
            - Attribution automatique de la relique tirée via `runController.addRelic` et affichage d'une notification visuelle via une `SnackBar` stylisée selon la rareté de la relique.

## Phase 80 - Résolution de l'Action d'Événement Relique (UI & Logic)

- feat: Implémentation complète de l'action `gain_relic` pour les événements aléatoires dans `EventScreen`
    - Ajout du traitement dynamique de la récompense de relique lors du choix d'une option d'événement.
        - **Import des Dépendances** :
            - Ajout de l'import de `relic_data.dart` dans `lib/ui/screens/event_screen.dart` pour permettre la manipulation des structures de relique.
        - **Résolution de l'Action `gain_relic` dans `_handleAction()`** :
            - Extraction de la liste complète des reliques du registre de données de jeu `gameDataLoaderProvider`.
            - Application de la même logique de probabilité de rareté pondérée que pour les récompenses de Boss (50% Commun, 30% Peu Commun, 13% Rare, 5% Épique, 2% Légendaire).
            - Ajout de la relique tirée à la collection permanente du joueur via `runController.addRelic()`.
            - Affichage d'une `SnackBar` colorée selon le niveau de rareté de la relique avec son emoji associé pour informer instantanément le joueur de son acquisition.

## Phase 81 - Regroupement Visuel et Stacking Premium de l'Inventaire des Reliques (UI)

- style: Refonte visuelle de l'inventaire dans `MapScreen` avec distinction des raretés, emojis custom et indicateurs de stacks (×N)
    - Amélioration de l'expérience utilisateur et de la clarté de l'inventaire en regroupant les doublons et en introduisant des codes couleur qualitatifs.
        - **Calcul et Regroupement des Doublons** :
            - Comptabilisation dynamique de la quantité de chaque relique possédée en associant l'ID à son nombre d'occurrences.
            - Remplacement de la grille d'affichage simple par une grille d'éléments uniques ordonnés, évitant de polluer l'inventaire de cartes identiques.
        - **Refonte Graphique de `_buildRelicCard()` (`lib/ui/screens/map_screen.dart`)** :
            - **Rareté Dynamique** : Application d'un liséré de couleur brillant et d'un ombrage adapté selon la rareté de la relique (Commun = Gris `Color(0xFF8E8E93)`, Peu Commun = Vert `Color(0xFF34C759)`, Rare = Bleu `Color(0xFF007AFF)`, Épique = Violet `Color(0xFFAF52DE)`, Légendaire = Doré `Color(0xFFFFCC00)`).
            - **Intégration d'Emojis** : Remplacement de l'icône d'étoile générique par l'emoji spécifique de la relique chargé depuis `relics.json`.
            - **Badge de Classification** : Ajout d'un badge textuel coloré (ex: « LÉGENDAIRE ») en bas à gauche de la carte.
            - **Compteur de Stacking** : Superposition d'un badge de stack premium (ex: « ×3 ») coloré en orange-ambré en bas à droite de la carte lorsque l'occurrence de la relique est supérieure à 1, reflétant fidèlement le stacking infini du système de jeu.

## Phase 82 - Tests Unitaires Dédiés au Système de Reliques et Validation

- feat: Ajout d'une suite de tests unitaires pour valider les mécaniques d'empilement (stacking), d'activation et de déclenchement des reliques
    - Couverture complète de la logique métier pour prévenir toute régression future.
        - **Écriture des Tests (`test/unit/run_controller_test.dart`)** :
            - Vérification que l'ajout d'une relique via `addRelic` fonctionne parfaitement.
            - Validation que le trigger `startOfRun` est résolu et appliqué immédiatement (ex: augmentation permanente de la Chance).
            - Validation de l'empilement (stacking) et de l'indépendance de traitement : obtenir 2× la même relique applique 2× son effet lors des triggers.
        - **Mise à Jour des Mocks de Tests Existants** :
            - Correction de `mockGameDataLoaderProvider` dans `test/widget/map_screen_test.dart` et `test/widget/shop_screen_test.dart` pour instancier `GameDataRegistry` avec la nouvelle liste de reliques requise.
        - **Vérification Intégrale** :
            - `dart analyze` exécuté avec 0 warning ni erreur.
            - `flutter test` exécuté avec succès : 17 tests sur 17 validés à 100%.

## Phase 83 - Optimisation Visuelle et Refonte Majeure de l'Inventaire (Map)

- style: Agrandissement du menu, cartes sur 2 colonnes occupant la moitié de la largeur, hauteur triplée à 220px et descriptions défilantes
    - Refonte complète de la grille de reliques et de la structure des cartes pour éliminer tout débordement (overflow) tout en maximisant la visibilité des descriptions.
        - **Refonte Structurale du Menu et de la Grille (`lib/ui/screens/map_screen.dart`)** :
            - Agrandissement substantiel du conteneur de dialogue de l'inventaire (`width` portée à 90% de l'écran ou max `850px` ; `height` à 85% de l'écran ou max `650px`) pour un rendu aéré et premium.
            - Restructuration du `LayoutBuilder` pour forcer chaque carte à occuper **exactement la moitié de la largeur disponible** (`cardWidth = (availableWidth - 16) / 2`), garantissant 2 colonnes symétriques et exploitant pleinement la surface.
            - Fixation de la hauteur de chaque carte à **220px** (hauteur triplée), résolvant définitivement les débordements de `RenderFlex` et les textes tronqués.
        - **Confort Visuel Premium dans `_buildRelicCard()`** :
            - Ré-introduction de marges de rembourrage spacieuses (`const EdgeInsets.all(16)`) et d'un espacement vertical généreux (`const SizedBox(height: 14)`).
            - Agrandissement qualitatif des polices et émojis : Émojis à `fontSize: 24`, titre principal à `fontSize: 14.5` (semi-bold) et badges à `fontSize: 9`.
            - **Intégration d'un Conteneur Défilant pour la Description** : Enveloppement du texte de description (`fontSize: 12`, `height: 1.45`) dans un `SingleChildScrollView` avec un défilement physique rebondissant (`BouncingScrollPhysics`). Cela garantit une lecture complète et fluide des descriptions quelle que soit leur longueur ou le niveau de zoom système.
        - **Robustesse et Tests** :
            - Validation par `dart analyze` : 0 avertissement ni erreur de type.
            - Non-régression prouvée par `flutter test` : 17 tests sur 17 passés avec succès.

## Phase 84 - Récompense d'Élite Relique, Suppression du Draft et Transition Fluide

- feat: Attribution de reliques lors des victoires d'Élites, suppression de l'écran de draft/choix, et correction du bug de réapparition visuelle
    - Transformation du système de récompense des Élites et sécurisation des transitions d'écrans pour une expérience fluide et sans artefact graphique.
        - **Évolution d'onEnemiesDead (`lib/ui/screens/game_screen.dart`)** :
            - Fusion de la logique d'attribution des reliques : le bloc de sélection pondérée (50% Commun, 30% Peu Commun, 13% Rare, 5% Épique, 2% Légendaire) et d'attribution automatique de relique s'exécute désormais tant pour les Boss (`MapNodeType.boss`) que pour les Élites (`MapNodeType.elite`).
            - Ajout d'un traitement asymétrique et sécurisé de fin de combat pour les combats Élites :
                - **Bypass de DraftScreen** : L'écran de choix de statistiques (draft de 3 bonus) est totalement ignoré et désactivé lors de la victoire contre un ennemi Élite, recentrant l'intérêt des Élites uniquement sur l'acquisition de reliques.
                - **Correction du Bug Visuel de Réapparition** : Auparavant, l'or et la progression de niveau (`nextLevel()`) étaient mis à jour immédiatement en début de méthode. Cette incrémentation de niveau déclenchait instantanément la reconstruction réactive du HUD de jeu et forçait le moteur Flame à engendrer (`_spawnEnemies()`) les monstres du niveau supérieur au beau milieu de l'arène vide durant les 1.5s d'affichage de la SnackBar.
                - **Résolution par Synchronisation Atomique** : Décalage de l'appel de `gainGold(...)` et `nextLevel(...)` à l'intérieur du bloc de temporisation `Future.delayed`. Les gains de ressources, l'avancement de niveau, la finalisation du nœud de carte et la fermeture de l'écran (`Navigator.pop`) s'exécutent désormais dans la même transaction synchrone de fin. L'arène de combat reste parfaitement vide et sereine, valorisant la relique obtenue avant un retour instantané à la carte de jeu.
        - **Préservation pour les Combats Communs et Boss** :
            - Les combats standards continuent de diriger le joueur vers `DraftScreen` pour choisir un bonus de statistiques et cloner des cartes, tandis que les combats de Boss préservent le double gain (Relique + DraftScreen), maintenant le boss comme l'arène de fin d'acte suprême.
        - **Robustesse et Tests** :
            - `dart analyze` validé avec 0 warning ni erreur de type.
            - Non-régression confirmée par `flutter test` avec 17 tests sur 17 passés avec succès.

## Phase 85 - Correction du Double Cumul de la Force dans l'Affichage du HUD

- fix: Résolution du bug de double addition des buffs d'attaque/force temporaires dans le HUD de combat
    - Rectification de la formule de calcul de l'attaque affichée au bas de l'écran pour refléter exactement les statistiques réelles du joueur.
        - **Analyse du Problème** :
            - Le joueur possédait une Force de base de `26` et 2 instances de la relique "Lame Maudite" (octroyant `+2` Force chacune au début du combat, soit un buff temporaire de `+4` Force).
            - En combat, la valeur d'attaque affichée dans le HUD était de `34` au lieu de `30` (`26 + 4`).
            - L'analyse du code a révélé que la variable `totalAttack` dans `GameScreen` était calculée via la formule erronée : `runState.heroStats.effectiveAttaque + bonusAttack`.
            - `effectiveAttaque` (provenant du modèle `EntityStats`) calcule déjà la somme de la Force de base et de l'ensemble des modificateurs de statut actifs (`attaque + strength_status_value`), retournant correctement `30`.
            - `bonusAttack` (provoyant du composant Flame `HeroCard`) lisait la différence `effectiveAttaque - attaque`, retournant également `4`.
            - La formule additionnait ainsi la Force temporaire **deux fois**, affichant à tort `34` (`30 + 4`).
        - **Résolution dans `lib/ui/screens/game_screen.dart`** :
            - Remplacement de la formule erronée par l'exacte source de vérité : `final totalAttack = runState.heroStats.effectiveAttaque`.
            - Nettoyage du code en éliminant les blocs `try-catch` obsolètes et redondants qui tentaient de lire `bonusAttack` depuis le composant Flame.
            - La valeur affichée correspond maintenant de manière pixel-perfect et rigoureuse à l'attaque effective du joueur (`30`), assurant une parfaite transparence mathématique pour le joueur.
        - **Robustesse et Validation** :
            - `dart analyze` exécuté avec succès : 0 erreur, 0 avertissement.
            - `flutter test` exécuté avec succès : 17 tests sur 17 passés.
