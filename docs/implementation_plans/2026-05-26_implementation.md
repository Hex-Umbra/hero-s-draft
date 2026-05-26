## Phase 95 - Modèles de Données purs pour le Combat (Refactoring - Étape 1)

- feat: Création des modèles de données purs EnemyInstance et CombatState pour détacher l'état logique de Flame
    - Conception et implémentation de structures de données pures et sérialisables pour représenter le combat, découplant définitivement la logique métier des composants graphiques Flame.
        - **Création du Modèle `EnemyInstance` (`lib/models/enemy_instance.dart`)** :
            - Représentation immuable d'un ennemi au sein d'une arène de combat.
            - Attributs intégrés : `id` (généré via un UUID v4 unique grâce au package `uuid`), `data` (référence immuable vers `EnemyData`), `stats` (instance de `EntityStats`), `currentIntent` (intention active du tour de type `EnemyIntent?`), `intentStep` (index cyclique des intentions), et `isBoss`.
            - Ajout d'une méthode `copyWith(...)` robuste incluant un drapeau utilitaire `clearIntent` pour réinitialiser l'intention active lors des fins de tour.
            - Implémentation des méthodes `toJson()` et `fromJson(...)` pour supporter la persistance future du combat à mi-parcours.
        - **Création du Modèle `CombatState` (`lib/models/combat_state.dart`)** :
            - Représentation complète de l'état logique d'un affrontement en cours.
            - Attributs intégrés : `enemies` (liste ordonnée des ennemis actifs `List<EnemyInstance>`), `turnPhase` (phase active de type `TurnPhase` : `player` ou `enemy`), `turnCount` (numéro du tour de combat), `selectedEnemyId` (ID de la cible actuelle choisie par le joueur), `isCombatEnded`, et `isVictory`.
            - Fourniture d'une énumération `TurnPhase` claire pour piloter la chronologie des phases de jeu.
            - Méthode `copyWith(...)` standard dotée d'une option `clearSelectedEnemy` pour nettoyer le ciblage du joueur lorsqu'un ennemi succombe.
            - Intégration de `toJson()` et `fromJson(...)` pour assurer une sérialisation en cascade et propre de la liste des ennemis.
        - **Enrichissement de `StatusEffect` et `EntityStats` pour la Sérialisation** :
            - Ajout des méthodes `toJson()` et `fromJson(...)` à la classe `StatusEffect` (`lib/models/status_effect.dart`) pour supporter l'encodage et décodage dynamique de la liste des statuts actifs.
            - Ajout des méthodes `toJson()` et `fromJson(...)` à la classe `EntityStats` (`lib/data/models/entity_stats.dart`), sérialisant les statistiques clés et mappant récursivement la collection des `StatusEffect` actifs.
        - **Robustesse et Compilation** :
            - Le typage est rigoureusement respecté et aucune modification n'impacte le bon fonctionnement du jeu à ce stade.

## Phase 96 - Contrôleur de Combat Riverpod (Refactoring - Étape 2)

- feat: Implémentation du CombatController Riverpod pour centraliser la logique métier du combat
    - Développement d'un contrôleur d'état pur étendant `StateNotifier<CombatState>` pour piloter les tours, le ciblage, les statuts et la résolution d'intentions ennemies hors de Flame.
        - **Création du `CombatController` (`lib/game/controllers/combat_controller.dart`)** :
            - Intégration de la méthode `initializeCombat` : prend en charge le spawn des ennemis via `EncounterSystem.generateEnemiesForLevel`, applique le coefficient multiplicateur de PV/dégâts selon la difficulté et le type de nœud (Boss = x3.0, Élite = x1.5), et détermine la première intention de chaque ennemi.
            - Intégration de la méthode `selectEnemy` : permet de cibler dynamiquement un ennemi via son ID.
            - Intégration de la méthode `applyPlayerCardPlay` : pré-structure l'application d'une carte par le joueur en coordonnant la résolution d'effets, le signalement de mort des ennemis, les passifs et les reliques. (Temporairement stubbé à cette étape pour préserver la compilabilité du projet avant le refactoring de `EffectResolver` à l'Étape 3).
            - Intégration de la méthode `resolveEnemyIntent` : applique synchroniquement l'intention d'un ennemi (Attaque, Défense, Buff de Force via statut).
            - Intégration de la méthode `startEnemyTurn` : boucle de début de tour ennemi qui résout les statuts récurrents (Poison, Métallisation/Régénération d'Armure), décrémente la durée des statuts et nettoie les morts éventuels.
            - Intégration de la méthode `endEnemyTurn` : calcule les intentions du tour suivant pour tous les monstres restants, incrémente le nombre de tours de combat et redonne la main au joueur.
            - Expositions de méthodes utilitaires d'écriture : `updateEnemyStats` (pour ajuster les PV/Armure des ennemis depuis les services) et `rollIntentForEnemy` / `tickEnemyStatuses`.
        - **Ajout du getter `effectiveIntent` sur `EnemyInstance` (`lib/models/enemy_instance.dart`)** :
            - Déplacement de la logique géométrique d'ajustement dynamique de l'attaque ennemie (en fonction du multiplicateur de spawn et des buffs de force accumulés en combat) vers le modèle purement logique `EnemyInstance`.
        - **Fourniture globale** :
            - Enregistrement du fournisseur Riverpod global `combatProvider`.

## Phase 97 - Découplage Complet des Services Métier (Refactoring - Étape 3)

- feat: Rénovation de l'EffectResolver pour le libérer de toute dépendance vis-à-vis de Flame
    - Refactoring complet du résolveur d'effets de cartes afin qu'il opère uniquement sur des états logiques Riverpod purs (`CombatController` et `String? selectedEnemyId`), éliminant tout import ou manipulation de composants de rendu graphiques Flame (`EnemyCard`).
        - **Épuration de `EffectResolver` (`lib/game/services/effect_resolver.dart`)** :
            - Suppression définitive de l'import de `lib/game/components/entities/enemy_card.dart`.
            - Adaptation de `canPlayCard` : remplace le paramètre `EnemyCard? selectedEnemy` par `String? selectedEnemyId` pour vérifier purement s'il y a une cible légitime pour les cartes de type `singleEnemy`.
            - Refonte de `resolveCard` : remplace `List<EnemyCard> enemyCards` par `CombatController combatController` et `EnemyCard? selectedEnemy` par `String? selectedEnemyId`.
            - Réécriture de la boucle d'application d'effets :
                - Pour les effets `damage` et `apply_status` ciblant `singleEnemy` : recherche de l'instance `EnemyInstance` dans `combatController.state.enemies` par son ID, calcul des dégâts/effets purs et mise à jour de ses statistiques logiques en invoquant `combatController.updateEnemyStats(...)`.
                - Pour les effets ciblant `allEnemies` : itération sur toutes les instances d'ennemis logiques du combat et mise à jour via `updateEnemyStats` dans le contrôleur Riverpod.
            - Avantage immédiat : La classe `EffectResolver` est maintenant **100% découplée** et devient immédiatement testable de manière unitaire et instantanée, sans instanciation lourde du moteur Flame.
        - **Déstubbage de `CombatController` (`lib/game/controllers/combat_controller.dart`)** :
            - Ré-activation complète de l'import `import '../services/effect_resolver.dart';` au sommet du fichier.
            - Rétablissement de la connexion nominale de `EffectResolver.resolveCard` dans la méthode `applyPlayerCardPlay` en lui transmettant `this` (le contrôleur lui-même) et `state.selectedEnemyId` (l'ID ciblé par le joueur).

## Phase 98 - Intégration de l'Interface Utilisateur (HUD Flutter & Flame) (Refactoring - Étape 4)

- feat: Synchronisation réactive entre l'état Riverpod du combat et le rendu visuel Flame
    - Restructuration complète des écrans de jeu et des arènes de combat pour connecter dynamiquement l'état Riverpod `CombatState` au moteur Flame et au HUD Flutter, établissant un flux de données unidirectionnel propre.
        - **Refactorisation de `EnemyCard` (`lib/game/components/entities/enemy_card.dart`)** :
            - Remplacement de l'état interne mutable et de la logique autonome de calcul d'intentions par un couplage à un objet immuable `EnemyInstance instance` fourni par le State.
            - Suppression définitive des méthodes de décision (`_determineNextIntent`, `rollIntent`, `startTurn`) et de la mutation directe des PV/Armure, rendant le composant 100% passif.
            - Intégration de `updateStats(EnemyInstance newInstance)` : compare réactivement l'ancien état PV/Armure avec le nouveau pour déclencher automatiquement des animations visuelles ad-hoc (secousse d'impact, flash blanc de dégâts, et popups de textes flottants colorés).
            - Sécurisation asynchrone contre les `LateInitializationError` : ajout de gardes `isLoaded` au sein de `setSelection(...)` et `setHighlight(...)` pour interdire l'accès à `borderInfo` avant la complétion de la méthode `onLoad()`, et synchronisation tardive des états visuels en fin de chargement.
        - **Refactorisation de `HerosDraftGame` (`lib/game/heros_draft_game.dart`)** :
            - Implémentation de la synchronisation réactive de combat `syncCombat(CombatState combatState)`.
            - Gestion du cycle de vie des composants : instanciation dynamique des cartes d'ennemis `EnemyCard` lorsqu'un ID apparaît dans le State, et déclenchement ordonné des animations de mort/retrait visuel lorsqu'un ennemi disparaît de l'état logique.
            - Restructuration asynchrone cadencée de la phase de riposte `_enemyRipostePhase` : orchestre temporellement les animations graphiques séquentielles (effet de dash) tout en déléguant l'évaluation logique des intentions et l'application des dégâts à Riverpod via `resolveEnemyIntent(...)`.
        - **Refactorisation de `GameScreen` (`lib/ui/screens/game_screen.dart`)** :
            - Surveillance réactive du `combatProvider` via `ref.watch(combatProvider)` pour piloter l'arène graphique et alimenter dynamiquement le panneau HUD Flutter d'intentions ennemies.
            - Connexion nominale de la fin de tour et des interactions de ciblage d'ennemis au contrôleur global Riverpod.
            - Gestion automatisée de la victoire/défaite en écoutant les drapeaux réactifs `isCombatEnded` et `isVictory` pour rediriger proprement le joueur vers les écrans correspondants.
        - **Mise à Jour de la Suite de Tests Unitaires (`test/unit/effect_resolver_test.dart`)** :
            - Migration complète des tests de scaling d'intentions et d'effets de statuts pour utiliser directement le modèle logique pur `EnemyInstance` au lieu du composant visuel Flame `EnemyCard`, augmentant la robustesse de validation hors-moteur.

## Phase 99 - Finalisation, Nettoyage & Suite de Tests du CombatController (Refactoring - Étape 5)

- feat: Déploiement de tests unitaires purs pour valider le CombatController en isolation et nettoyage complet
    - Finalisation de la phase 1 du refactoring par l'écriture d'une suite de tests rigoureuse et le nettoyage de toutes les fonctions transitoires de compatibilité.
        - **Élimination définitive des fonctions héritées dans `EffectResolver` (`lib/game/services/effect_resolver.dart`)** :
            - Suppression définitive des versions obsolètes dépendantes de Flame de `canPlayCard(...)` et `resolveCard(...)`.
            - Renommage de `canPlayCardState` et `resolveCardState` en `canPlayCard` et `resolveCard` nominaux.
            - Adaptation correspondante des appels dans `lib/game/controllers/combat_controller.dart` et `lib/ui/screens/game_screen.dart`.
        - **Création du Fichier de Tests Unitaires Dédié `test/unit/combat_controller_test.dart`** :
            - Conception de tests unitaires purement logiques, 100% déterministes, en court-circuitant le générateur aléatoire `EncounterSystem` via l'injection directe d'états `CombatState` mockés.
            - Scénarios de tests implémentés et validés :
                - `initializeCombat` : Validation du comportement nominal d'initialisation, des calculs de multiplicateurs de PV et d'attaque pour les nœuds Standards, Élites (x1.5) et Boss (x3.0), ainsi que le tirage de la première intention de chaque ennemi.
                - `selectEnemy` : Validation du ciblage actif et du nettoyage lors du ciblage d'un ennemi inexistant/nul.
                - `resolveEnemyIntent` : Validation de l'application correcte des intentions des ennemis (dégâts infligés au PV du héros dans `RunController`, gain d'armure propre).
                - `startEnemyTurn` : Validation de l'évaluation globale et simultanée des effets récurrents de début de tour de tous les ennemis (ex: dégâts autonomes de Poison sur les PV de l'ennemi, réduction de durée des statuts actifs) et du nettoyage immédiat des monstres succombant au Poison.
                - `applyPlayerCardPlay` : Simulation complète de l'application d'une carte d'attaque simple (ex: Strike) par le joueur, validation de la consommation de Mana, de la prise en compte du bonus de Force du héros (`strength`), de la mise à jour des statistiques de vie de l'ennemi ciblé, et du déclenchement automatique des drapeaux de fin de combat (`isCombatEnded`, `isVictory`) lorsque tous les ennemis ont trépassé.
        - **Robustesse et Stabilité** :
            - Validation unitaire totale hors-moteur, garantissant la fiabilité des calculs de combat.
            - Tous les tests de l'application (unitaires et widgets) compilent et passent avec succès.

## Phase 2 : Étape 1 - Découpage de l'Écran de la Carte (map_screen.dart)

- refactor: Extraction des composants et dialogues de `map_screen.dart` pour réduire sa dette technique
    - Découpage complet du fichier monolithique `map_screen.dart` (qui est passé de plus de 2300 lignes à seulement 630 lignes), augmentant la modularité, la lisibilité et l'organisation de l'UI.
        - **Création du `BlurWrapper` (`lib/ui/widgets/blur_wrapper.dart`)** :
            - Extraction de l'effet de flou dynamique (`BackdropFilter`) avec prise en charge du repli intelligent (`kIsWeb`) sur fond sombre opaque afin d'éviter toute duplication de logique visuelle.
        - **Création du Widget `MapConnectionPainter` (`lib/ui/widgets/map/map_connection_painter.dart`)** :
            - Isolation complète du painter vectoriel personnalisé dessinant les connexions en pointillés animés entre les nœuds de la carte.
        - **Création du Widget `MapLegend` (`lib/ui/widgets/map/map_legend.dart`)** :
            - Encapsulation autonome de la légende cartographique flottante avec sa liste d'icônes et de libellés descriptifs.
        - **Création du Widget `MapNodeWidget` (`lib/ui/widgets/map/map_node_widget.dart`)** :
            - Déplacement de la logique de rendu individuel de nœud (gestion des clics, détection de survol, animations de dimensions, tooltips, et badges de complétion) dans sa propre classe.
        - **Création du Widget `PlayerPawn` (`lib/ui/widgets/map/player_pawn.dart`)** :
            - Extraction du pion animé du joueur avec son indicateur vectoriel pointé vers le bas et son amortissement cinématique.
        - **Création du Dialog `StatsDialog` (`lib/ui/widgets/map/dialogs/stats_dialog.dart`)** :
            - Isolation de la fiche de personnage complète avec affichage des jauges de PV progressives, cristaux de mana, statistiques secondaires (Attaque, Maîtrise, Chance) et passif de classe.
        - **Création du Dialog `RelicsDialog` (`lib/ui/widgets/map/dialogs/relics_dialog.dart`)** :
            - Extraction de la grille adaptative de reliques gérant le groupement intelligent des doublons magiques (stacking) et l'affichage des déclencheurs de combat.
        - **Création du Dialog `ProbabilitiesDialog` (`lib/ui/widgets/map/dialogs/probabilities_dialog.dart`)** :
            - Déplacement de la logique algorithmique et de l'interface des chances de butin de cartes/reliques bonifiées par la statistique Chance du héros.
        - **Création du Widget `HeroMiniStatsPanel` (`lib/ui/widgets/map/hero_mini_stats_panel.dart`)** :
            - Isolation du panneau résumé flottant des statistiques en bas à droite de la carte de navigation.
        - **Épuration Globale de `MapScreen` (`lib/ui/screens/map_screen.dart`)** :
            - Importation nominale des nouveaux widgets et suppression de 1700 lignes de code répétitif et monolithique.
        - **Validation Statique Complète** :
            - Lancement de `dart analyze` validant l'absence d'avertissements ou d'erreurs sur l'intégralité du projet.

## Phase 2 : Étape 2 - Découpage de l'Écran de Combat (game_screen.dart)

- refactor: Extraction des composants HUD et dialogs de `game_screen.dart`
    - Découpage complet du fichier monolithique `game_screen.dart` (passant de plus de 1350 lignes à seulement 820 lignes), améliorant considérablement l'organisation visuelle du combat et la testabilité des widgets du HUD.
        - **Création du Widget `PlayerHealthBar` (`lib/ui/widgets/hud/player_health_bar.dart`)** :
            - Extraction de la barre de PV et d'armure superposée avec liseré cyan progressif, ainsi que des jauges de dégâts d'attaque de base sous forme d'icônes à gradients premiums.
        - **Création du Widget `ManaIndicator` (`lib/ui/widgets/hud/mana_indicator.dart`)** :
            - Encapsulation autonome de la ligne de cristaux de mana diamantés avec ombrages de lueurs néon cyan.
        - **Création du Widget `StatusEffectsPanel` (`lib/ui/widgets/hud/status_effects_panel.dart`)** :
            - Extraction du panneau d'affichage des modificateurs de statut actifs du héros (Poison, Force, Métallisation) avec leurs icônes représentatives et indicateurs de tours restants.
        - **Création du Widget `EnemyIntentsPanel` (`lib/ui/widgets/hud/enemy_intents_panel.dart`)** :
            - Déplacement de la liste d'intentions ennemies et de l'état des PV des monstres (attaques lourdes, blocages, buffs, malédictions) dans un sous-widget propre avec bordures adaptées au type d'intention.
        - **Création du Dialog `PauseDialog` (`lib/ui/widgets/hud/dialogs/pause_dialog.dart`)** :
            - Extraction du menu de pause interactif gérant de façon générique les actions de reprise et de retour au menu principal.
        - **Épuration de `GameScreen` (`lib/ui/screens/game_screen.dart`)** :
            - Intégration nominale des nouveaux widgets HUD Flutter réutilisables et nettoyage de plus de 500 lignes de code graphique complexe.
        - **Création des Tests de Widgets Dédiés** :
            - Écriture de tests dans `test/widget/player_health_bar_test.dart` et `test/widget/mana_indicator_test.dart` vérifiant la justesse des rendus visuels sous des états logiques spécifiques.
        - **Validation Statique & Exécution des Tests** :
            - Lancement de `dart analyze` (aucun problème détecté) et succès complet de l'ensemble de la suite de tests (`All tests passed!`).

## Phase 3 : Étape 1 - Modularisation du Badge de Statistiques (stat_badge.dart)

- refactor: Extraction des composants internes de `stat_badge.dart` pour réduire sa dette technique
    - Découpage complet du fichier `stat_badge.dart` (passant de 720 lignes à seulement 430 lignes), isolant la logique de dessin vectoriel complexe et les barres de vie dans des fichiers séparés et réutilisables.
        - **Création du Widget `FlameSwordIcon` (`lib/game/components/widgets/flame_sword_icon.dart`)** :
            - Extraction du tracé vectoriel d'une épée 3D biseautée avec garde incurvée, poignée en cuir segmentée et pommeau circulaire orné d'un joyau.
        - **Création du Widget `FlameShieldIcon` (`lib/game/components/widgets/flame_shield_icon.dart`)** :
            - Extraction du tracé vectoriel d'un bouclier de guerrier biseauté aux couleurs cyan brillant translucides.
        - **Création du Widget `LinearProgressBarComponent` (`lib/game/components/widgets/linear_progress_bar.dart`)** :
            - Extraction de la barre de vie horizontale rouge dotée d'un dégradé et de sa jauge d'armure bleue brillante (avec liseré cyan accent) superposée.
        - **Création du Widget `CircleProgressComponent` (`lib/game/components/widgets/circle_progress.dart`)** :
            - Extraction de l'arc de progression circulaire utilisé pour le rendu des jauges de vie rondes du héros.
        - **Épuration de `StatBadge` (`lib/game/components/entities/stat_badge.dart`)** :
            - Remplacement de plus de 400 lignes de codes inline par l'importation propre de nos nouveaux widgets modularisés, transformant le badge en un simple coordinateur de mise en page réactif.
        - **Validation Statique Complète** :
            - Succès complet de `dart analyze` garantissant la stabilité et la propreté du code.

## Phase 3 : Étape 2 - Modularisation de la Carte de Jeu (card_component.dart)

- refactor: Découpage du fichier `card_component.dart` pour isoler son rendu textuel et ses effets visuels
    - Allègement massif de `card_component.dart` (passant de 1030 lignes à seulement 430 lignes), déléguant l'intégralité de sa peinture textuelle et de ses animations cinématiques de combat à des classes spécialisées et autonomes.
        - **Création du Rendu Textuel `CardTextRenderer` (`lib/game/components/widgets/card_text_renderer.dart`)** :
            - Centralisation et configuration des 6 instances de `TextPainter` (Titre, Coût en Mana sous forme de diamants vectoriels, Rareté, Description dynamique ajustée à la force active du joueur, Type et Bandeau rouge "Usage Unique").
            - Gestion de la mise en page géométrique et du tracé textuel sur Canvas.
        - **Création de l'Animateur de Combat `CardAnimator` (`lib/game/components/visual_effects/card_animator.dart`)** :
            - Isolation de toute la cinématique visuelle de combat : tremblements impossible-à-jouer (`shakeAnimation`), dashs corps-à-corps avec slash vectoriel, zoom de sorts magiques, fondus de buffs et trajectoires de statuts colorées (Poison, Brûlure, Gel, Électrocution).
            - Encapsulation des systèmes physiques de particules : traînées arc-en-ciel lors du drag (`spawnTrailParticles`), explosions d'impacts d'effets et désintégration par étincelles en cas d'épuisement.
            - Gestion du retour élastique de la carte en main en cas d'annulation du glissement (`returnToHand`).
        - **Épuration de `CardComponent` (`lib/game/components/card_component.dart`)** :
            - Remplacement de près de 600 lignes de code graphique par l'instanciation de nos deux délégués `textRenderer` et `animator`, recentrant le composant uniquement sur les événements d'interactions physiques (glissements, détection de survol, clics).
        - **Validation Statique & Exécution des Tests** :
            - Lancement de `dart analyze` (100% propre, aucune erreur ou avertissement).
            - Succès total de l'intégralité de la suite de tests Flutter (`All tests passed!`).

## Phase 4 : Étape 1 - Remplissage des Fichiers de Ressources Localisées (ARB)

- feat: Centralisation complète des chaînes de caractères de l'UI et du HUD dans les fichiers ARB
    - Ajout exhaustif de toutes les clés de traduction requises pour l'internationalisation complète dans `lib/l10n/app_en.arb` et `lib/l10n/app_fr.arb`.
        - **Ajouts pour la Carte du Monde (`MapScreen`)** :
            - Clés de navigation et d'interface : `myDeck`, `stats`, `relics`, `chances`, `goldCount`.
            - Clés des dialogues : `heroStatsTitle`, `classPassive`, `relicInventory`, `emptyInventory`, `luckPercentageTitle`, `currentLuck` (avec placeholder numérique).
            - Légendes complètes : `legendTitle`, `legendCombat`, `legendElite`, `legendShop`, `legendRest`, `legendEvent`, `legendBoss`.
            - Infobulles explicatives pour tous les nœuds de la carte : de `tooltipCombatTitle` / `Desc` jusqu'à `tooltipBossTitle` / `Desc`.
        - **Ajouts pour l'Écran de Combat (`GameScreen` et HUD)** :
            - Informations d'état : `actLevel` (avec placeholders pour l'acte et le niveau), `playerEffects`, `enemyIntents`, `noStatusActive`, `waitingIntents`, `manaWarning`, `turnCount` (avec placeholder).
            - Options de pause : `pauseTitle`, `backToMainMenu`.
        - **Ajouts pour les Éléments Graphiques Flame** :
            - Déclencheurs de reliques : de `relicTriggerRun` à `relicTriggerEnemyKilled`.
            - Raretés unifiées : de `rarityCommon` à `rarityLegendary`.
            - Descriptions et titres des tooltips d'attributs primaires : PV, Armure, Force/Attaque et Mana (`tooltipHpTitle`/`Desc`, etc.).
    - **Validation et Régénération** :
        - Exécution réussie de `flutter gen-l10n` pour régénérer la classe fortement typée `AppLocalizations`.
        - Validation de la conformité statique globale avec `flutter analyze` : résultat 100% propre, aucune erreur ou avertissement de lint.
