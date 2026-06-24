# 🧠 Contexte Actuel de Développement (Active Context)

Ce document décrit le focus actif du projet, les accomplissements récents, et la trajectoire de développement à court terme pour **Hero's Draft**.

## 1. Focus Actuel du Projet

Le projet a résolu un problème critique de crash de l'UI de combat (Version v0.2.8) lié à des clés dupliquées dans le système de notifications simultanées. 

Le focus se tourne désormais vers les étapes suivantes de la roadmap technique : la persistance I/O (Sauvegarde de partie via `shared_preferences`), l'implémentation audio complète, la décomposition des écrans complexes restants (`MapScreen` et `GameScreen`), et l'amélioration de la couverture des tests.

## 2. Accomplissements Récents

1. **Résolution du Bug de Clés Dupliquées dans l'Overlay de Notification (Complété - Version v0.2.8)** :
   - **Génération d'ID unique robuste** : Modification de `NotificationNotifier.show` dans `lib/ui/widgets/notification_overlay.dart` pour combiner le timestamp en microsecondes (`DateTime.now().microsecondsSinceEpoch`) et un suffixe aléatoire (`Random.nextInt(100000)`).
   - **Éradication des collisions** : Cette modification élimine les collisions d'identifiants (clés dupliquées dans l'arbre de widgets Flutter) lorsque plusieurs notifications sont déclenchées simultanément (par exemple, lors de l'application synchrone de multiples statuts ou effets de début de tour).
   - **Validation de l'analyse** : Zéro erreur et zéro avertissement avec `dart analyze`, garantissant la propreté du code.

2. **Révision du Scaling et du Spawn des Ennemis (Complété - Version v0.2.7)** :
   - **Formule de Combat Rating révisée** : Modification du calcul du coût de menace des ennemis pour atténuer le poids des PV bruts (divisés par 4.0) au profit des dégâts, permettant d'avoir plus d'ennemis pour un même budget.
   - **Couplage Deck & Puissance joueur** : Transmission du nombre de cartes du deck principal (`playerCardsCount`) depuis `game_screen.dart` via `CombatController` vers `EncounterSystem.generateEnemiesForLevel` pour ajuster plus finement le budget du combat.
   - **Difficulte accrue à partir de l'Acte 2** : Passage des ratios de croissance par acte à 35% pour les PV et 25% pour les dégâts.
   - **Validation unitaire** : Mise à jour des valeurs du test de calcul du Combat Rating dans `encounter_system_test.dart` et validation de la suite de tests (108/108 au vert).

2. **Double Confirmation de Fin de Tour avec Mana Restant (Complété - Version v0.2.6)** :
   - **Validation double clic** : Ajout d'une variable d'état local `_showRemainingManaWarning` dans `game_screen.dart` déclenchée si le mana du héros est supérieur à 0 lors du clic.
   - **Interactivité dynamique** : Réinitialisation immédiate du warning lors de l'exécution de `onPlayCard` ou du passage à un nouveau tour (`_startPlayerNewTurn()`).
   - **Localisation bilingue** : Ajout de la clé `remainingManaWarning` dans `app_en.arb` et `app_fr.arb`.
   - **Zéro Régression** : Analyse statique vierge et suite de tests validée avec 100% de réussite.

2. **Correction du Bouton de Fin de Tour (Complété - Version v0.2.5)** :
   - **Mise à jour synchrone de l'état Flame** : Résolution du problème d'inactivité transitoire du bouton de fin de tour en combat en synchronisant explicitement `_game.currentPhase = TurnPhase.player;` lors du démarrage du tour du joueur dans `game_screen.dart` (`_startPlayerNewTurn`).
   - **Protection Anti-Spam intacte** : Le clic initial désactive instantanément le bouton pour empêcher le spam, tandis que le retour au tour joueur réactive le bouton immédiatement.
   - **Zéro Régression** : Analyse statique vierge et tous les tests de la suite automatisée (108/108) au vert.

2. **Harmonisation Post-Refactoring de l'Architecture (Complété - Version v0.2.4)** :
   - **Harmonisation UI de ClassSelectionScreen** : Remplacement de l'ancien Scaffold/AppBar par les widgets standardisés de l'infrastructure (`ScreenScaffold` et `PageHeader`) pour harmoniser l'arrière-plan dégradé.
   - **Déduplication de code CombatEntity** : Centralisation de la logique de détection de modification de statistiques et de création d'animations d'impacts dans la classe de base commune Flame `CombatEntity`, éliminant la duplication logicielle résiduelle dans `HeroCard` et `EnemyCard`.
   - **Riverpodisation d'EffectRegistry** : Instanciation propre sans état statique mutable exposée par le provider `effectRegistryProvider` injecté à `EffectResolver.resolveCard`, et suppression de 3 callbacks orphelins de `HerosDraftGame`.
   - **Attribut floor de MapNode** : Ajout du champ `floor` avec désérialisation rétrocompatible, éradiquant les expressions `split('_')[1]` éparpillées.
   - **Zéro Régression** : L'analyse statique du projet est vierge de toute erreur ou avertissement et tous les 108 tests unitaires sont au vert.

2. **Refactoring Phase 4 — Architecture & Patterns (Complété - Version v0.2.3)** :
   - **Découpage Procedural de la Carte** : Algorithme monolithique divisé en 4 modules dédiés (`MapNodeGenerator`, `MapConnectionBuilder`, `MapValidator`, `MapContentPlacer`), facilitant la maintenance et l'évolution de la carte stratégique.
   - **Strategy Pattern pour les Effets de Cartes** : Création de l'interface `EffectStrategy` et du registre `EffectRegistry` gérant 6 stratégies concrètes (`Damage`, `Heal`, `Armor`, `GainMana`, `Draw`, `ApplyStatus`), rendant `EffectResolver` propre et extensible.
   - **Composant Commun Flame `CombatEntity`** : Centralisation des animations communes (secousses, flashs colorés, particules, dash) éliminant plus de 300 lignes de code dupliqué dans `HeroCard` et `EnemyCard`.
   - **Cycle de vie Unifié `BaseVisualEffect`** : Encapsulation du retrait automatique (`RemoveEffect`) et des callbacks optionnels de fin, appliqué à `SlashEffect` et `ShieldDome`.
   - **Thème Visual Design & Diagnostic Data** : Ajout de `GameThemeExtension` pour regrouper les couleurs gameplay (raretés, stats, lueurs néon) et sécurisation du chargement JSON dans `GameDataService` avec alertes explicites.

2. **Refactoring Phase 3 — Unification de l'UI (Complété - Version v0.2.2)** :
   - **Centralisation du Scaffold (`ScreenScaffold`)** : Unification des styles d'arrière-plan du jeu (dégradé sombre de combat/menus et texture parchemin de la carte/échanges) et gestion propre du cycle de vie des retours arrière via `PopScope`.
   - **En-têtes d'Écrans Homogènes (`PageHeader`)** : Remplacement des AppBar ad-hoc par une structure unifiée gérant le bouton retour standardisé, le titre stylisé et les actions transversales.
   - **Badge d'Or Uniforme (`GoldIndicator`)** : Intégration de l'affichage de l'or connecté à l'état de l'inventaire en haut des écrans Boutique, Forge et Carte.
   - **Modularisation de la Forge** : Scission du dialogue de forge monolithique en sous-composants unitaires sous `lib/ui/widgets/forge/` pour respecter le principe de responsabilité unique (SRP).
   - **Factorisation du Draft de Cartes** : Structure de mise en page commune (`CardDraftLayout`) avec grille responsive et indicateurs de sélection unifiés pour les drafts de boss et de starter.
   - **Nettoyage de 9 Écrans** : Migration des écrans clés vers la nouvelle architecture unifiée de l'UI sans régression visuelle ou logique.

2. **Refactoring Phase 2 — Décomposition des God Classes (Complété - Version v0.2.1)** :
   - **Contrôleur de Run Facade** : `RunController` réorganisé pour déléguer à `PlayerStatsManager` (stats, XP, HP, mana, buffs), `MapProgressionManager` (déplacements, complétions, actes), `RunPersistenceManager` (sauvegarde) et `GoldManager` (or, forge slots).
   - **Contrôleur de Combat Facade** : `CombatController` réorganisé pour déléguer à `StatusEffectProcessor` (résolution unifiée des statuts poison, brûlure, force, armure joueur/ennemis) et `TurnPhaseManager` (ripostes, transitions de tours).
   - **Systèmes Flame Spécialisés** : Division de `HerosDraftGame` en 4 composants Flame indépendants : `StateSyncSystem` (synchronisation des états Riverpod), `CardAnimationSystem` (inclinaison, zoom, focus, pioche), `CombatVisualSystem` (Bézier ciblage, explosions de particules, dômes), et `LayoutSystem` (layouts arc de main, repositionnement ennemis).
   - **Découplage de CardComponent** : Extraction du dessin Canvas 2D dans `CardRenderer` (runes de forge, halos de rareté, Sheen foil) et des gestes physiques dans `CardInteractionHandler` (hover, drag, cancel zone, ciblage).
   - **Maintien de l'intégrité de l'API** : Toutes les signatures de fonctions et méthodes publiques ont été préservées pour assurer une compatibilité immédiate avec les UI existantes et la suite de tests.

2. **Centralisation, Harmonisation et Refactoring (Version v0.1.9)** :
   - **Centralisation des Constantes de Jeu** : Déplacement de tous les délais temporels des phases de combat et des paramètres graphiques (police, échelle, drift, fondu) du texte flottant (`FloatingText`) dans `GameConstants` (`lib/game/game_constants.dart`), éliminant ainsi plus de 100 nombres magiques éparpillés.
   - **Immutabilité des Modèles d'État (Sécurisation)** : Application de l'annotation `@immutable` et de listes non modifiables (`List.unmodifiable` dans les constructeurs et `copyWith`) sur les modèles clés `EntityStats`, `CombatState` et `EnemyInstance`. Les constructeurs `const` incompatibles avec `unmodifiable` ont été convertis.
   - **Pipeline de Dégâts Unifié (`DamagePipeline`)** : Implémentation du service centralisé `DamagePipeline.calculate` (`lib/game/services/damage_pipeline.dart`) qui centralise toute la logique de combat physique et magique : affaiblissement de l'attaquant (-25%), jet de coup critique (avec propagation du flag de critique `lastActionWasCrit` pour Flame), cumul du choc de la cible et amplification de vulnérabilité (+50%). Simplification drastique de `CombatController` et `EffectResolver` qui lui délèguent leurs calculs.
   - **Assurance Qualité & Validation** : Analyse statique via `dart analyze` (0 erreur, 0 avertissement) et passage au vert de la totalité des 108 tests unitaires de la suite automatisée (`flutter test`).

3. **Transition Fluide de Tour & Reset d'Armure (Version v0.1.8)** :
   - **Reset Systématique de l'Armure** : Modification de la logique de transition de tour dans `RunController.startTurn()` pour mettre à jour l'état du run en remettant à `0` la statistique `armure` avant d'appliquer les reliques et effets de statut liés au début du tour (tels que `armor_regen`). Cela empêche l'immortalité involontaire par cumul continu d'armure.
   - **Contournement des Animations en Début de Tour** : Intégration d'un booléen `suppressArmorChangeAnimation` dans `HeroCard` pour empêcher les effets d'impact graphique (secousse de bouclier `shieldHitAnimation` et popups de perte d'armure) d'apparaître indûment lors du reset automatique de début de tour. Le flag est lu puis réinitialisé à `false` à la fin de la mise à jour des statistiques graphiques.
   - **Contrôle d'État Visuel** : Câblage du flag dans `game_screen.dart` lors de l'appel à `_startPlayerNewTurn()`, garantissant une synchronisation propre entre la transition d'état et le rendu.
   - **Validation de la Suite d'Assurance Qualité** : Passage réussi des 108 tests unitaires de la suite automatisée et validation de la propreté du code via `dart analyze` (linter 100% vert).

4. **L'Éclat des Combats (Version v0.1.7)** :
   - **Textes Flottants Premium & Néon** : Implémentation d'ombres portées et de contours thématiques fluorescents (rouge/orange pour critique, vert pour poison, bleu/cyan pour bouclier). Insertion des préfixes `"💥 CRIT "`, `"🧪 "` et `"🛡️ "` et calibrage de la taille (36, 22, 26).
   - **Cinématique de Pop & Pulsation** : Rotation aléatoire de départ (entre -0.15 et +0.15 rad) sur 150ms. Séquence d'échelle élastique sur critique (1.5x via `Curves.elasticOut` puis 1.15x puis pulsation infinie oscillante 1.15x - 1.3x). Oscillation sinusoïdale horizontale sur le poison.
   - **Déclenchement Critique Déterministe** : Câblage de l'animation de critique sur le flag `lastActionWasCrit` des modèles `EntityStats` calculé côté métier (Riverpod) et non plus sur des seuils de dégâts arbitraires.
   - **Intensification du Rendu Critique** : Intensification des secousses de cartes (`shakeAndFlashAnimation` à 28.0 de magnitude et 8 vibrations), flash doré vif (`0xFFF59E0B`, opacité 0.85, durée 350ms), et émission de 35 particules (contre 12 ou 15).
   - **Décélération de la Barre de Vie** : Modification de la double jauge de `PlayerHealthBar`. Lors de dégâts, the catch-up rouge prend désormais 1200ms avec une courbe `Curves.easeOut` pour donner de la lourdeur aux coups. Le soin reste rapide (vert monte en 500ms, rouge immédiat).
   - **Correction Métier du Croc Kunaï** : Remplacement de l'altération erronée des statistiques permanentes du héros par l'application d'un effet de statut temporaire de combat `'armor_mastery'` (durée 99). Calcul dynamique de l'armure via le getter `effectiveArmorMastery` sur `EntityStats` (sommant `armorMastery` et la somme des statuts `'armor_mastery'`).
   - **Animation Interactive du Carrousel de Reliques** : Intégration d'un `AnimationController` de 1800ms dans `RelicCarouselScreen` gérant la cinématique des particules Canvas à l'arrêt du spin (onLand). Application de formules physiques (vitesse avec traînée, gravité de `250.0 * progress * progress`, et atténuation d'opacité linéaire) à chaque tick pour éviter l'effet statique.
   - **Exclusion de Cartes Uniques post-Boss** : Ajout d'une clause d'exclusion `c.rarity != CardRarity.unique` dans `RewardController.initializeReward()` pour la récompense de cartes du boss de gauche (x=0), préservant la répartition sémantique et prévenant le drop non-contrôlé de cartes de classe.
   - **Visualisation Premium du Magic Mirror** : Remplacement des widgets simplifiés de sélection de carte dans le modal de clonage ("Mirror Magic") par l'utilisation de l'interface `UiCard` complète. Chaque carte proposée affiche désormais sa rareté, ses upgrades actifs sous forme de runes, son coût en mana standardisé, son ciblage et ses effets. Ajout d'un contrôle de survol réactif (`_isHovered`) animant l'échelle (de 1.0x à 1.05x via `AnimatedScale`) et la lueur de la bordure (`isSelected == _isHovered` transmettant le radial glow thématique).
   - **Mise en Page Responsive du Dialogue de Clonage** : Remplacement de l'ancien conteneur de disposition par un défilement horizontal fluide (`SingleChildScrollView` avec direction `Axis.horizontal` et un enfant `Row`) pour empêcher tout débordement d'interface (RenderFlex overflow) sur les écrans étroits. Élargissement de la largeur maximale du dialogue en dur à `maxWidth: 550` dans l'instance de `GameDialog` pour aérer la présentation des 3 choix de cartes clonables.
   - **Caching Persistant Anti-Exploit du Magic Mirror** : Pour empêcher le joueur d'annuler et de réouvrir le modal de clonage pour forcer un nouveau tirage de cartes (reroll exploit gratuit), les 3 cartes candidates sélectionnées du deck sont stockées de façon persistante dans la liste `cloneOptions` de `ShopState`. Si la liste est déjà peuplée, le modal réutilise la sélection existante sans ré-échantillonner. La liste n'est vidée et réinitialisée que lors d'un nouvel appel à `ShopController.initializeShop` lors du chargement d'un nouveau nœud boutique.
   - **Verrouillage Financier Automatique des Services de Boutique** : Intégration d'un système de gating strict des services (Reroll, Soin, Purge, Expansion, Clonage) dans l'interface de la boutique. Les boutons d'action correspondants sont désactivés (en assignant `onPressed: null`) et l'affichage visuel est mis à jour (`canAfford: false`) dès que le solde du joueur (`inventoryState.gold`) est inférieur au coût fixé pour chaque service, éliminant tout risque de transaction invalide ou de spam.

2. **Ajustements du Gel et de la Forge (Version v0.1.6)** :
   - **Correction Forge Hardened** : Modification d' `EffectResolver.resolveCard` pour appliquer directement l'armure de forge (`extraArmor`) au héros via `runController.setHeroStats()` si la carte d'attaque jouée ne dispose pas d'effet natif d'armure.
   - **Persistance du Gel (`freeze`)** : Modification de la méthode `tickStatuses()` d' `EntityStats` pour ignorer le statut de gel, empêchant sa dissipation prématurée au début du tour ennemi.
   - **Intention Visuelle Adaptée** : Mise à jour du getter `effectiveIntent` dans `EnemyInstance` pour diviser par deux (arrondi au plus proche) la valeur des dégâts d'intention affichée à l'écran lorsque l'ennemi subit l'altération de gel.
   - **Consommation de l'Effet** : Ajustement de `resolveEnemyIntent` dans `CombatController` pour décrémenter le compteur de tours de gel de 1 après la résolution de l'attaque sans appliquer de réduction supplémentaire.
   - **Tests unitaires et Statiques** : Passage réussi des tests unitaires simulés et linter Flutter validé à 100% vert.

2. **Effet de Bordure Foil Progressif pour les Cartes Uniques (Version v0.2.02)** :
   - **Calcul Dynamique** : Intégration de `upgradeCount: forgeUpgrades.length` passé du widget `UiCard` au composant `PolychromaticBorder`.
   - **Échelle Chromatique** : Utilisation d'un pool ordonné de 10 couleurs (Unique/Gold, Common, Uncommon, Rare, Epic, Legendary, Red, Yellow, Cyan, Pink) dont le sous-ensemble sélectionné augmente dynamiquement selon `upgradeCount`.
   - **Garantie de Fluidité** : Duplication automatique de la couleur de départ à la fin pour un bouclage sans couture du gradient tournant.
   - **Tests & Analyse** : Zéro problème d'analyse statique et passage des 107 tests.

2. **Décomposition de la God Class UiCard (Version v0.2.01)** :
   - **Découplage SRP** : Refactoring de `UiCard` (1136 lignes) pour isoler les responsabilités et respecter les patterns Flutter.
   - **Création du sous-dossier `ui_card/`** contenant les sous-composants isolés : `CardManaMedallion`, `CardRuneSockets`, `CardCompactDescription`, `PolychromaticBorder`, et `ui_card_helpers.dart`.
   - **Simplification de UiCard** : Réduction du fichier d'assemblage principal à ~175 lignes de composition pure.
   - **Intégrité de l'API** : Conservation stricte du constructeur pour éviter toute modification des imports externes.
   - **Vérification** : Validation réussie de l'intégralité des 107 tests automatisés du projet.

2. **Refonte Esthétique des Cartes (Version v0.1.5)** :
   - **Style Premium Glassmorphic** : Refonte visuelle complète utilisant un effet de verre dépoli semi-transparent (`BackdropFilter` avec un flou de 10px) combinant des dégradés subtils (`0.6` d'opacité en haut, `0.2` en bas) et des bordures affinées (épaisseur de `1.5` en temps normal et `2.5` en cas de sélection) avec un liseré semi-transparent (`0.5` d'opacité).
   - **Effet Polychromatique au Survol (Hover Foil)** : Ajout d'un effet arc-en-ciel tournant / balayant animé en temps réel sur la bordure de la carte lors du survol de la souris. L'épaisseur de la bordure augmente à `3.0` (sur `UiCard` Flutter) ou `3.5` (sur `CardComponent` Flame) lors du survol pour sublimer l'effet. Cet effet a été implémenté en double : via un `CustomPainter` et `AnimationController` pour les cartes Flutter, et via un shader de gradient linéaire orienté dynamiquement en fonction d'un accumulateur temporel pour les cartes Flame en combat.
   - **Médaillon de Coût Standardisé** : Remplacement des cristaux de mana inférieurs ou des affichages dispersés par un médaillon circulaire flottant en haut à gauche (rayon de 12px, centré à `[6, 6]`), de couleur sombre (`0xFF0D1B2A`), orné d'une bordure et d'un ombrage cyan brillant. Ce médaillon est identique entre la couche Flame en combat et les widgets Flutter.
   - **Fentes de Runes (Rune Sockets) avec Multi-Row Wrapping** : Remplacement des anciennes étoiles d'amélioration par des emplacements circulaires représentant le potentiel de forge de la carte (`baseMaxForgeUpgrades + rarityIndex`). Les upgrades actifs y sont représentés par des runes/émojis spécifiques (⚔️, 🛡️, 🔥, etc.), tandis que les emplacements vides apparaissent sous forme de cercles grisés translucides. Pour les cartes hautement améliorées, les fentes sont réparties sur plusieurs lignes (max 5 par rangée) via un widget `Wrap` contraint à `45.0` pixels dans `UiCard`, et calculées manuellement en grille sur le Canvas de `CardTextRenderer` (décalage vertical de 16 pixels pour centrer et empiler chaque rangée).
   - **Réduction d'Échelle de 25%** : Ajustement des dimensions de base de la carte à `140 × 196` (ratio d'aspect `70/110`) permettant un affichage plus fluide, compact et ergonomique, évitant tout encombrement de l'écran ou problème de responsivité.
   - **Nettoyage Visuel & Remplacement des Badges de Ciblage** : Suppression complète du filigrane décoratif en arrière-plan et des badges textuels de ciblage (Cible unique / Single Target, Tous les ennemis / All Enemies, Soi-même / Self) dans les descriptions pour réduire le bruit visuel et simplifier l'assimilation des informations de la carte.
   - **Doublement d'Icônes Multicibles (Raffinement)** : Pour conserver l'information de portée sans badges textuels, les cartes ciblant tous les ennemis doublent uniquement les icônes des effets offensifs ou dirigés vers l'ennemi (ex: double icône d'épée ⚔️⚔️ pour les dégâts multicibles, ou double icône de débuff). Les effets bénéfiques appliqués au joueur (gain d'armure, de soin, de mana, pioche, ou buffs de force/régénération) conservent une icône unique car ils n'affectent pas les ennemis individuellement.
   - **Suppression du label de rareté & Identification par Couleur/Halo** : Élimination complète de l'affichage textuel de la rareté ("Commune", "Rare", etc.) sur la carte. Le rendu repose exclusivement sur les bordures visuelles teintées (`rarityColor.withValues(alpha: 0.5)`) et les halos de surbrillance lumineux (glowing shadows/radial glow `rarityColor.withValues(alpha: 0.4)` de rayon 15px et diffusion 4px en cas de sélection `isSelected == true`) pour communiquer la rareté de la carte. Les infobulles de combat reprennent également cette couleur de contour (`Border.all(color: rarityColor, width: 1.5)`).
   - **Couleurs d'Arrière-Plan Typées pour le Rendu Combat (Flame)** : Les cartes de combat dans l'arène de jeu (Flame `CardComponent`) ont été mises à jour pour utiliser des couleurs d'arrière-plan thématiques spécifiques à leur type, identiques à celles définies pour les cartes de menu (`UiCard`) : rouge sombre (`0xFF4A1D1D`) pour les attaques, bleu marine profond (`0xFF152A4A`) pour les compétences, bronze sombre (`0xFF453215`) pour les pouvoirs et gris sombre (`0xFF2D2D2D`) pour les statuts.
   - **Mise à Jour des Tests** : Récriture et validation des tests d'interface s'assurant que les badges de ciblage n'apparaissent plus et que le doublement des icônes d'effet multicible fonctionne de manière rigoureuse (107 tests au total).

2. **Boutique & Économie (Version v0.1.3)** :
   - **Exclusion de cartes uniques** : Les cartes de classe exclusives (`unique`) sont explicitement exclues du pool des cartes éligibles à la vente dans `ShopController` (initialisation, reroll et expansion), préservant leur rôle de récompenses contrôlées.
   - **Arrière-plans typés dans UiCard** : Implémentation d'une distinction visuelle sémantique de l'arrière-plan et des bordures de `UiCard` selon la nature de la carte (rouge pour attaque, vert pour compétence, violet pour pouvoir, gris pour statut) facilitant la lisibilité immédiate.
   - **Grille de cartes en Wrap** : Utilisation d'un widget `Wrap` et de `SizedBox` d'une largeur de 150 pour contraindre l'affichage des cartes en boutique sous forme d'une grille uniforme sans débordement ni RenderFlex overflow.

3. **Map, Draft & Progression (Version v0.1.4)** :
   - **Level Up différé sur la Carte** : Découplage de l'écran de draft de montée de niveau vis-à-vis du combat. L'XP accumulée incrémente `pendingDrafts` dans `RunState`. À la fermeture du combat, le joueur revient sur la carte du monde (`MapScreen`) où un overlay d'animation bloquant « LEVEL UP ! » s'affiche si le compteur est positif. Un clic ouvre le `DraftScreen` via une route classique et décrémente `pendingDrafts`. Les clics sur les nœuds de la carte sont désactivés tant que le draft n'est pas complété.
   - **Protection Anti-Spoil du Carrousel de Reliques** : Durant la rotation de la roulette (`isWon == false`), les cartes de reliques sont masquées avec une apparence grise neutre et des badges techniques affichant « ??? » pour entretenir le suspense. Le titre de rareté en en-tête est dissimulé. À l'ar    - **Génération Dynamique de Chokepoints** : Remplacement de la constante d'étage d'élite central `y == 5` par `middleFloor = floors ~/ 2` dans `MapGeneratorService`, assurant une flexibilité totale de taille de carte (utilisé pour la génération, l'optimisation anti-répétition et le solver de quotas).

4. **Système de Forge v2 (Section 2 — Version v0.2.00)** :
   - **Anti-exploit de session** : Intégration de `forgeSlots` (liste d'upgrades sous format `id:tier`) et `forgeTargetCardId` dans `RunState` pour sauvegarder et restaurer les options de forge si la boîte de dialogue est fermée sans sélection. Nettoyage de la session uniquement lors d'un achat d'upgrade réussi ou du départ du camp de repos (`RestScreen._leave`).
   - **Filtrage intelligent par type de carte** : Restriction du pool d'améliorations selon la catégorie de carte (`skill` n'autorise pas les upgrades physiques ou élémentaires ; `power` n'autorise que les upgrades utilitaires : `eco`, `quick`, `enduring` ; `attack` accède au pool complet).
   - **Achat de fentes progressif (Buy Slots)** : Possibilité d'acheter jusqu'à 4 slots supplémentaires (5 slots max) avec un prix évolutif ($50 \rightarrow 80 \rightarrow 120 \rightarrow 175$ Or) directement dans la forge.
   - **Design responsive plein écran** : Passage à une disposition plein écran responsive (`Dialog.fullscreen`). Rendu en deux colonnes (`Row`) sur desktop et empilement vertical (`Column`) sur mobile avec une liste scrollable.
   - **Fiabilité et Assurance Qualité** : Ajout de tests unitaires dans `run_controller_test.dart` validant les coûts progressifs, le plafonnement des slots et la persistance de session, portant le total à **106 tests automatisés** 100% au vert et une analyse statique sans erreur.

5. **Génération et Progression de la Carte (Section 5)** :
   - **Algorithme anti-répétition de chemin** : Garantit de manière stricte qu'aucun chemin dans le graphe ne contient 3 nœuds consécutifs du même type (Élite ou Repos).
   - **Quotas de types de nœuds (Solver)** : Maintient un équilibre statistique optimal sur l'ensemble de la carte : Combat (12-22), Élite (3-6), Repos (3-6), Shop (2-5), Event (4-9).
   - **Chokepoints structurels forcés** : Étage central dynamique (`floors ~/ 2`, soit chokepoint à 1 nœud de type Élite) et Étage `floors-2` (tous les nœuds sont obligatoirement de type Repos, garantissant une pause avant les boss).
   - **Branchements de Boss multiples** : L'étage final présente 3 nœuds de boss distincts différenciés par leur position horizontale pour offrir des récompenses de combat uniques.
   - **Récompenses de Boss thématiques basées sur la position** :
     - **Position gauche (x = 0)** : Permet de sélectionner 5 cartes de son deck et d'en cloner 2 (icône Cartes).
     - **Position centrale (x = 1)** : Triple (x3) l'or et l'expérience de combat accumulés, et offre une carte aléatoire du jeu hors uniques et statuts (icône Magie/XP).
     - **Position droite (x = 2)** : Garantie de butin de relique premium améliorée (minimum Uncommon, chances de tirage Legendary et Epic accrues proportionnellement par Acte).

6. **Polissage et Responsivité en Combat (Section 6)** :
   - **HUD Responsive** : Adaptabilité complète de la hauteur et de la largeur du panneau de combat avec clamps de sécurité pour toutes les tailles d'écran (mobiles, desktop, web).
   - **Badges de Ciblage Remplacés** : Les anciens badges textuels (Single Target, All Enemies, Self) ont été supprimés (v0.1.5) pour réduire la pollution visuelle. Le ciblage multicible est représenté graphiquement en doublant les icônes d'effet ciblant l'ennemi (ex: ⚔️⚔️ pour les attaques de zone), tandis que les effets ciblant le joueur restent simples. Les tests unitaires et widget-tests correspondants ont été mis à jour pour valider cette distinction sémantique.
   - **Indicateurs de Carte du Monde** : Badge numérique dynamique pour les reliques possédées et badge numérique sur le bouton du deck affichant la taille actuelle du master deck.
   - **Scaling Échelle des Ennemis** : Ajustement proportionnel de la taille des cartes d'ennemis sur le plateau Flame pour refléter visuellement leur importance et leur niveau.

7. **Refactoring des Cartes de Classe "Unique" & Schémas JSON** :
   - Déplacement de toutes les cartes spécifiques de classe (`holy_shield`, `smite`, `reckless_strike`, `rage_form`, `magic_missile`, `mana_surge`) de `cards.json` vers `assets/data/hero_cards.json`.
   - Ajout de la rareté `unique` (enum `CardRarity`) mappée à un multiplicateur de 1.0 dans `card_instance.dart` et d'une limite de forge `baseMaxForgeUpgrades` fixée à 5.
   - Verrouillage de la fusion : les cartes de rareté `unique` ne peuvent pas être fusionnées (désactivé dans l'UI et interdit dans `deck_controller.dart`), et elles sont exclues des tables de draft de récompense ou de boutique en cours de run.
   - Restructuration de `heroes.json` avec l'intégration du champ `"skills"` contenant les identifiants de cartes de départ.
   - Création de la méthode d'extension `getHeroCards(gameData)` sur `HeroSkillsLink` pour charger dynamiquement les cartes de classe uniques à partir des compétences du héros sélectionné.

8. **Standardisation Globale et Rééquilibrage VPM** :
   - Uniformisation de la rareté de toutes les cartes globales restantes dans `cards.json` à `common`.
   - Rééquilibrage complet de leurs statistiques (coût, dégâts, blocage, statuts) autour d'un ratio de Valeur Par Mana (VPM) standardisé :
     - `heal_potion` : Coût 1 mana, Soin 4, Épuisement (`isExhaust: true`).
     - `iron_wall` : Coût 2 mana, Blocage 10.
     - `heavy_strike` : Coût 2 mana, Dégâts 12.

9. **Overhaul de l'Écran de Draft Initial (`StarterDeckDraftScreen`) & Corrections** :
   - Chargement direct de l'intégralité du catalogue des 15 cartes globales pour le choix initial (suppression totale de la logique de pool intermédiaire de 10 cartes tirées au hasard).
   - Retrait des importations et méthodes inutilisées (`dart:math` et `_rollRarity`).
   - Mise à jour des chaînes de localisation `draftDeckSubtitle` dans `app_en.arb` et `app_fr.arb` pour refléter la sélection libre des 5 cartes de départ (suppression de la mention "parmi les 10 proposées").
   - Les cartes uniques de classe du héros choisi sont automatiquement résolues via l'extension `getHeroCards(gameData)` et ajoutées pour constituer le deck de départ final.

10. **Intégration et Résolution des Effets Élémentaires & Vulnérabilité (Axe 1 - Précédent)** :
    - **Brûlure (`burn`)** : Dégâts de feu infligés au début du tour de la cible. Le tick applique des dégâts égaux à la valeur accumulée puis décrémente la valeur et la durée de 1.
    - **Gel (`freeze`)** : Divise par deux (arrondi) les dégâts de la prochaine attaque ennemie et décrémente immédiatement la durée du gel de 1.
    - **Électrocution (`shock`)** : Ajoute la valeur cumulée du statut à chaque dégât d'attaque direct subi par la cible.
    - **Vulnérabilité (`vulnerable`)** : Amplifie de 50% tous les dégâts reçus de manière universelle (s'applique aussi bien au Héros qu'aux Ennemis).
    - Résolutions métier câblées proprement dans `CombatController` et `EffectResolver` sans couplage Flame.

11. **Rareté Dynamique & Fusion Interactive (Axe 2 & 4 - Précédent)** :
    - Remplacement des niveaux numériques de cartes par une progression de rareté dynamique (`common` → `uncommon` → `rare` → `epic` → `legendary`). Les multiplicateurs de rareté adaptent les statistiques de base de la carte.
    - **Fusion interactive (3→1)** : Le joueur sélectionne exactement 3 exemplaires identiques. Le système fusionne automatiquement les upgrades de même ID en additionnant leurs Tiers, tout en limitant la quantité finale selon la capacité de la rareté supérieure. Un choix d'héritage d'améliorations est proposé de manière interactive.

12. **Système de Forge Découplé (Axe 3 - Précédent)** :
    - **Capacité de Forge** : Limite d'améliorations fixée à `baseMaxForgeUpgrades + rarityIndex`.
    - **Slots Probabilistes** : De 1 à 5 slots générés indépendamment avec des probabilités de `100%`, `50%`, `25%`, `10%`, et `2%`.
    - **Pools d'Améliorations** : Tirages clamps par rareté (Common: stats/debuffs; Uncommon: pioche/mana; Rare: enduring).
    - **Relance individuelle (Reroll)** : Coût par slot indexé sur $20 \times 1.25^n$ (arrondi), consommant l'or de l'inventaire.
    - **Intégration premium** : Nouveau widget `ForgeUpgradeDialog` accessible depuis l'option Forge de l'écran `RestScreen` (anciennement Campfire).

13. **Système de Tutoriel Autonome & Refactoring Responsive (Ancien)** :
    - Module isolé sous `lib/tutorial/` avec son propre `TutorialEngine` et un état simulé `TutorialMockState`.
    - 13 étapes interactives adaptées aux smartphones portrait/paysage, web, et desktop via des structures responsives unifiées (`LayoutBuilder`, `FittedBox`, `SingleChildScrollView`, `Wrap`).
    - Ciblage double phase interactif et infobulles explicatives localisées.

14. **Équilibrage de la Courbe de Difficulté et Vagues de Combat** :
    - Mise en œuvre d'un algorithme d'équilibrage hybride (DDA amorti à 0.5) comparant `PlayerPower` et `ExpectedPower` pour ajuster le `FinalBudget` de menace.
    - Intégration du système de `CombatRating` dynamique des ennemis (prenant en compte le scaling HP, dégâts, tier et chance critique).
    - Développement du système de réserve `pendingEnemies` (limité à 5 slots actifs) avec réapprovisionnement automatique lors des éliminations et condition de victoire étendue.
    - Correction de la logique de détermination de Boss (`isBoss`) : Restriction de la vérification par floor (divisible par 10) aux cas où le type de nœud n'est pas spécifié, évitant ainsi le scaling erroné de boss lors des combats classiques du floor 10.
    - Validation complète du comportement des vagues et de la répartition budgétaire via des tests unitaires automatisés.

15. **Assurance Qualité et Robustesse** :
    - **Tests automatisés** unitaires et d'intégration validés avec succès, maintenant les tests du générateur, du système de vagues, de la correction `isBoss` et du nouveau logger, portant le total à **106 tests** (100% verts).
    - Analyse de code statique : **0 erreur** sous `flutter analyze`.

16. **Isolation de la Journalisation du Combat (`CombatDebugLogger`)** :
    - Découplage complet de la journalisation mathématique d'initialisation de combat en extrayant ces fonctions de `CombatController` vers `CombatDebugLogger`.
    - Stylisation de la console de débogage à l'aide de bordures en boîte ANSI et de codes de couleurs ANSI.
    - Encapsulation des instructions de log dans des vérifications de mode débogage (`kDebugMode`) pour éviter toute surcharge d'allocation de mémoire en production.

17. **Refactoring et Finalisation des Récompenses de Boss (Version 0.0.94)** :
    - **Séparation et Centralisation Métier** : Centralisation complète du pipeline de récompenses post-combat dans un nouveau contrôleur Riverpod dédié `RewardController` (`rewardProvider`), isolant la logique métier des vues.
    - **Butin d'Or des Ennemis** : Ajout du champ `gold` à `EnemyData` et `EnemyInstance`. Les montants d'or initiaux sont configurés dans `enemies.json` et mis à l'échelle : `(enemy.data.gold * levelMultiplier).round()`.
    - **Boss 1 (Card Draft / Clonage)** : Refonte pour proposer 5 cartes aléatoires du deck du joueur afin d'en cloner 2.
    - **Boss 2 (Triple XP & Gold + Carte Aléatoire)** : Triplement (x3) de l'Or et de l'XP de combat à la défaite du boss central (x=1), avec ajout d'une carte aléatoire du jeu (hors uniques de classe et statuts).
    - **Boss 3 (Reliques Dynamiques)** : Pour le boss de droite (x=2), distribution évolutive des reliques (minimum Uncommon, chances de tirage Legendary et Epic accrues proportionnellement par Acte).
    - **Correction du Tirage de Relique des Boss** : Correction d'une régression dans `RewardController` pour restreindre le tirage d'une relique aux nœuds Élite ou aux nœuds Boss de type `improvedRelic` (x=2), évitant des reliques indues sur les boss x=0 et x=1.
    - **Génération Procédurale** : `MapGeneratorService` attribue explicitement le type de récompense de Boss selon la position horizontale `x` à l'étage final sous forme d'enum `BossRewardType`.
    - **Découplage UI** : `MapNodeWidget` lit le `bossRewardType` fortement typé plutôt que de parser des coordonnées de chaînes. `GameScreen` délègue les écrans de reliques et de dialogues de draft via le `rewardProvider`.

18. **Rééquilibrage des Reliques, Déclencheurs de Type de Carte et Système de Charges (Version 0.0.95)** :
    - **Intégration de 10 Nouvelles Reliques** : Ajout de 4 communes (Whetstone, Leather Boots, Lucky Coin, Travel Bandage), 4 rares (Kunai, Shuriken, Incense Burner), 1 atypique (Pen Nib) et 1 légendaire (Crown of Kings) dans `relics.json`, portant le total à 24 reliques et équilibrant les choix.
    - **Mana Permanent et de Combat** : Implémentation du gain de Mana permanent via la relique légendaire *Couronne des Rois* (+1 Max Mana permanent à l'échelle de la run) et de Mana de départ via la relique épique *Plume de Phénix* (+2 Mana au début du combat).
    - **Déclencheurs par Type de Carte** : Implémentation de triggers ciblés `onAttackPlayed`, `onSkillPlayed` et `onPowerPlayed` dans `RelicTrigger`, dispatchés dans `CombatController.applyPlayerCardPlay` en fonction du type de carte joué.
    - **Reliques à Charges / Compteurs** : Logique de compteurs de combat codée dans `RunController.applyRelicEffect` à l'aide de buffs temporaires ou durables empilables :
      - *Croc Kunaï* (Kunaï) : Accumule des charges de tour (`kunai_charge`). À 3 attaques jouées dans le même tour, reset les charges et octroie +1 Maîtrise d'Armure permanente pour le combat.
      - *Shuriken* : Accumule des charges de tour (`shuriken_charge`). À 3 attaques jouées dans le tour, reset les charges et confère +1 Force permanente pour le combat.
      - *Plume de Scribe* (Pen Nib) : Accumule des charges persistantes (`pen_nib_charge`). Au bout de 5 cartes jouées, reset et donne +3 Force temporaire pour le tour actuel.
      - *Encensoir* : Accumule des charges persistantes (`incense_charge`) à chaque tour. Tous les 4 tours, reset les charges et donne +8 points d'Armure.
    - **Dictionnaire des Reliques Bilingue** : Mise à jour de `DictionaryScreen` (`card_dictionary_screen.dart`) pour supporter et localiser correctement les badges textuels de ces nouveaux triggers en français et en anglais.
    - **Validation Technique** : Analyse statique passée sans erreur (`dart analyze`) et suite complète de 104 tests validée à 100% verte.

19. **Rencontre d'Échange de Reliques (Version 0.0.96)** :
    - **Nouveau nœud d'échange** : Implémentation du type de nœud `MapNodeType.relicExchange` (emoji `🔄`).
    - **Règles de génération procédurales** : Apparaît à partir de l'Acte 5. Garanti à 100% tous les 5 actes (Acte 5, 10, etc.), avec 10% de chances d'apparaître pour les autres actes. Positionné aléatoirement sur un étage intermédiaire (étages 2, 3, 4, 6 ou 7) afin d'éviter les chokepoints et haltes obligatoires.
    - **Offre déterministe par Seeded Random** : Tirage de la relique offerte basé sur une graine calculée via `(node.id.hashCode ^ act).abs()`. La relique offerte exclut la rareté `Common` (car sans rareté inférieure à sacrifier) et répartit les chances entre `Uncommon` (40%), `Rare` (35%), `Epic` (20%) et `Legendary` (5%).
    - **Transaction 3-pour-1 et inversion des statistiques** : Permet au joueur de sacrifier 3 reliques de rareté $R-1$ pour obtenir la relique gagnée de rareté $R$. Inversion et soustraction correcte des statistiques de run acquises (comme Force, Chance, Mana, PV max) lors du sacrifice des reliques concernées.
    - **Interface utilisateur immersive (`RelicExchangeScreen`)** : Thème d'autel magique en parchemin proposant une grille de sélection interactive (lueur dorée de sélection) des reliques requises, avec validation par transaction sécurisée ou possibilité de refuser et quitter sans échange.
    - **Fiabilité** : Ajout de tests unitaires complets dans `relic_exchange_test.dart` (validation topologique de génération de carte par Act et logique de transaction/inversion d'effets permanents), portant le total à **104 tests** (100% verts).

20. **Modernisation Architecturale & Découplage (Version 0.0.97)** :
    - **Migration vers Notifier** : Remplacement global du pattern legacy `StateNotifier` et `StateNotifierProvider` par les classes modernes `Notifier` et `NotifierProvider` de Riverpod 2.x.
    - **Découplage des contrôleurs** : Élimination complète des paramètres de constructeur injectant des `Ref` ou d'autres contrôleurs. Utilisation directe de `ref.read` de manière interne pour la communication inter-contrôleurs, éliminant les couplages rigides et les dépendances circulaires au démarrage.
    - **Immuabilité stricte de `CardInstance`** : Conversion systématique des listes d'améliorations de la forge (`forgeUpgrades`) en listes non modifiables via `List.unmodifiable(...)` à l'instanciation de `CardInstance`, garantissant qu'aucune carte en main ou dans le deck ne soit altérée silencieusement.
    - **Externalisation de la logique Flame** : Extraction complète de la logique métier de calcul des compétences (`executeSkill`) du moteur de jeu Flame (`heros_draft_game.dart`) vers `CombatController` (Riverpod), garantissant que le moteur de rendu Flame reste purement passif et découplé des calculs de dégâts ou de vol d'armure.

21. **Optimisations Graphiques, Performances & Animations Fluides (Version 0.0.98)** :
    - **Performances de Rendu Flame** : Élimination des appels GPU lents/redondants `saveLayer()` dans `FloatingText` et `EffectIcon` pour peindre directement sur le canvas principal.
    - **Mise en Cache CPU des Layouts** : Caching des `TextPainter` dans `CardComponent` pour éviter les calculs coûteux de layout textuel à chaque frame lors des transitions d'opacité. Utilisation de `saveLayer` uniquement sous condition stricte (`opacity < 1.0`).
    - **Synchronisation Synchrone à l'Impact** : Report des secousses, flashs, animations de particules, et modifications de points de vie dans `EnemyCard` au moment de la collision réelle de la carte de combat (en appelant `resolvePendingVisualStats` à l'impact).
    - **Prévention des Doubles Déclenchements** : Retrait des réactions redondantes dans `CardAnimator` pour éliminer les bugs d'animation d'impact double.
    - **Transition Organique de Pioche** : Les cartes tirées apparaissent à la coordonnée de la pioche `Vector2(40, size.y - 40)` et glissent, pivotent et s'adaptent à l'échelle via des Flame Effects jusqu'à leur position finale dans l'arc circulaire de la main.

22. **Système de Design & Uniformisation UI (Version 0.0.99)** :
    - **Tokens de Design Centralisés** : Création du module `lib/ui/theme/` regroupant `AppColors` (palettes Neon Dark + Parchemin + couleurs sémantiques de stats, de raretés de cartes et de reliques), `AppSpacing` (helpers `EdgeInsets` standardisés), et `AppTheme` (génération d'un `ThemeData` complet dark/light avec polices, couleurs primaires et styles de texte cohérents).
    - **Extensions Dart sur les Enums de Rareté** : Ajout d'un getter `.color` centralisé sur `CardRarity` et `RelicRarity` via des extensions Dart, remplaçant les switch-case dispersés par un accès direct (`card.rarity.color`, `relic.rarity.color`).
    - **Correction `GameButton` (RenderFlex overflow)** : Résolution d'un bug d'overflow sur les boutons contenant uniquement une icône dorée sans libellé textuel, rendu stable sur tous les rapports d'aspect.
    - **Refactoring `RelicsDialog`** : Remplacement d'un bloc `switch` de 19 lignes par un appel unique `.color` via l'extension `RelicRarity`, rendant le composant concis, lisible et auto-documenté.
    - **Validation** : 104/104 tests passés, 0 erreurs d'analyse.

23. **Interface & Cartes à Jouer (UX Combat - Section 1 - Version 0.1.00)** :
    - **Blocage de la Pioche** : Les cartes en cours de distribution depuis la pioche vers la main sont temporairement non-interactables (`isEnteringHand = true` bloquant le survol, glissement et clic) et bénéficient d'une animation ralentie à `0.7s` (au lieu de `0.35s`) pour un rendu fluide et serein.
    - **Contrôle et Contenu des Tooltips** : Les tooltips d'explication de combat ne s'affichent désormais que lorsqu'une carte est activement sélectionnée (focalisée) en combat et se masquent automatiquement lors du désélectionnement ou du jeu. Les descriptions détaillent de manière formatée l'intégralité des améliorations de forge appliquées.
    - **Polissage des Cartes (Flame & Flutter)** : Retrait des icônes vectorielles translucides en arrière-plan pour réduire le bruit visuel. Diminution des tailles de police de 10% à 20% pour une meilleure lisibilité. Intégration d'un indicateur sous forme d'étoiles dorées (remplies/vides) représentant les upgrades appliqués par rapport à la capacité maximale sous le label de rareté.
    - **Barre de Vie Premium (HUD Joueur)** : Refactorisation de `PlayerHealthBar` en `StatefulWidget` avec transition `TweenAnimationBuilder` (500ms, `Curves.easeOutCubic`). Sous l'effet des dégâts, la barre verte principale diminue instantanément alors qu'une barre de fond rouge/orange descend lentement. En cas de soin, la barre verte remonte de manière fluide tandis que la barre rouge la suit instantanément.
    - **Validation** : Tous les tests de la suite automatisée (104/104 verts) passent avec succès, et le linter est vierge sous `dart analyze`.

24. **Refactoring de UiCard (SRP - Version 0.2.01)** :
    - **Décomposition SRP** : Refactorisation de la god class `UiCard` (1136 lignes) en extrayant ses composants métiers et graphiques dans `lib/ui/widgets/ui_card/` (`CardManaMedallion`, `CardRuneSockets`, `CardCompactDescription`) et ses helpers d'affichage dans `ui_card_helpers.dart`.
    - **Interface unifiée** : Simplification de `UiCard` en un conteneur d'assemblage propre d'environ 175 lignes.

25. **Bordure Foil Progressif Unique (Version 0.2.02)** :
    - **Sheen Foil Dynamique** : Implémentation dans `PolychromaticBorder` d'une bordure brillante et animée exclusive aux cartes de rareté `Unique` (cartes de classe).
    - **Échelle d'upgrades** : Nombre de couleurs de gradient déterminé dynamiquement par `upgradeCount + 1` (de 1 à 10 couleurs, en bouclant le gradient).

26. **Polissage des Dimensions en Menu (Version 0.2.03)** :
    - **Forge Rune Sockets** : Diamètre des fentes de runes augmenté de 7px à 10px et élargissement de la contrainte pour assurer une lisibilité nette sans overflow.
    - **Mana Medallion** : Taille du médaillon de mana à 30px (font size 13) avec offset à [-9, -9] pour conserver le centrage précis à [6, 6] dans l'angle de la carte.
    - **Ciblage de l'Interface** : Modifié uniquement pour les menus Flutter (UiCard), laissant intact le rendu de combat (Flame).

27. **Enrichissement des Tooltips & Foil de Combat (Version 0.2.04)** :
    - **Détails de Cartes Complets** : Ajout systématique du type de cible (Target), de la rareté (Rarity), du type de carte (Type) et du coût en mana (Cost) sur les tooltips.
    - **Cible Écrite Explicite** : Permet au joueur d'avoir le type de cible écrit en toutes lettres (ex : "Slime (Cible unique)") pour lever toute ambiguïté visuelle.
    - **Support Bilingue & Combat** : Implémenté sur les infobulles de combat (Flame `CardComponent`) et de menu (Flutter `UiCard`).
    - **Foil en Combat** : Application du même effet brillant polychromatique (foil) progressif en combat basé sur `card.forgeUpgrades.length` pour les cartes de rareté `Unique`.

---

## 3. Prochaines Étapes de Développement (Roadmap Technique)

Pour élever le projet à un niveau commercialisable de qualité premium, les chantiers suivants doivent être priorisés (Phase 7) :

1. **Parallélisation des I/O dans `GameDataService`** :
   - Remplacer les 7 appels consécutifs `await rootBundle.loadString(...)` par un unique chargement parallèle via `Future.wait([...])` pour éliminer le décalage de démarrage à froid.
2. **Système de Sauvegarde et Persistance (Autosave)** :
   - Concevoir un `SaveService` s'appuyant sur `shared_preferences`.
   - Sauvegarder automatiquement l'état logique (`RunState`, `DeckState`, `CombatState`, `InventoryState`) après chaque modification significative (fin de tour, gain d'or, obtention de carte).
   - Intégrer un bouton "Reprendre la partie" sur l'écran d'accueil.
3. **Infrastructure Audio Sensorielle** :
   - Ajouter la dépendance `flame_audio` dans `pubspec.yaml`.
   - Mettre en place un service central `AudioService` pilotant les musiques de fond dynamiques et les effets sonores contextuels (impacts, pop de texte flottant).
   - Résoudre l'ensemble des commentaires `// TODO: Audio Hook`.
4. **Découplage des Écrans UI Monolithiques** :
   - Découper la classe géante `map_screen.dart` (**2471 lignes**) en composants unitaires réutilisables.
   - Externaliser la logique métier et de traversée de graphe dans un contrôleur focalisé `map_controller.dart`.
   - Décomposer `game_screen.dart` (**1667 lignes**) en extrayant ses overlays privés.
5. **Découplage du Routage de Navigation** :
   - Éradiquer les transitions codées en dur via `Navigator.push`.
   - Implémenter un contrôleur logique de navigation (`GoRouter` ou contrôleur d'état Riverpod réactif).
