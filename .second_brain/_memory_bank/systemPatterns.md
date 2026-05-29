# 🏗️ Architecture & Conception (System Patterns)

Ce document décrit l'architecture globale, les patrons de conception, la stratégie de gestion d'état, les composants d'interface et les conventions de codage appliqués dans le projet **Hero's Draft**.

---

## 1. Architecture Globale

Le projet **Hero's Draft** est articulé autour d'une séparation stricte des responsabilités (SOC) via trois couches distinctes : la **Logique métier et d'état (Riverpod)**, le **Rendu de jeu interactif (Flame Engine)**, et l'**Interface utilisateur HUD (Flutter Widgets)**.

```mermaid
graph TD
    subgraph Couche UI (Flutter Overlay)
        UI[HUD Overlay / Screens] <-->|ref.watch / ref.read| RVP
        UiCard[UiCard Widget]
    end

    subgraph Couche Métier (Riverpod - Cerveau)
        RVP[RunController / DeckNotifier / CombatController]
        ER[EffectResolver]
        TS[TraitSystem]
        ES[EncounterSystem]
        GD[GameDataService / Registry]
    end

    subgraph Couche Rendu (Flame - Muscles)
        Game[HerosDraftGame] <-->|Callbacks & syncState| RVP
        CardComp[CardComponent]
        EnemyComp[EnemyCard]
        HeroComp[HeroCard]
        TargetLine[TargetingLine]
    end

    RVP -->|Orchestre| ER
    RVP -->|Évalue| TS
    CombatController -->|Génère via| ES
    GameDataService -->|Parse JSON vers| GD
    ER -->|Mutations d'état| RVP
```

### Rôle des Contrôleurs Globaux (`lib/game/controllers/`)
Les contrôleurs encapsulent la logique de transition d'état et le cycle de vie du jeu. Ils héritent de `StateNotifier` pour exposer des états immuables.
- **`RunController` (`runProvider`)** : Supervise la progression globale de la partie (niveaux, actes, graphe des nœuds de la carte `mapNodes`, position actuelle `currentNodeId`, et statistiques globales du joueur `EntityStats`). Il gère les événements hors combat (repos, draft, sélection de classe) ainsi que le cycle de vie général (début du tour globale, reliques passives).
- **`DeckNotifier` (`deckProvider`)** : Maître d'œuvre des piles de cartes (`masterDeck`, `drawPile`, `hand`, `discardPile`, `exhaustPile`). Il implémente la mécanique pure du deckbuilder (piocher, défausser, détruire/épuiser, et la fusion automatique de 3 cartes identiques en niveau supérieur).
- **`CombatController` (`combatProvider`)** : Gère l'état actif d'un affrontement (`CombatState`). Il génère les monstres adéquats via `EncounterSystem`, ordonne la file d'intentions ennemies (`EnemyIntent`), contrôle la phase de tour (`TurnPhase`), sélectionne la cible active, et détermine la mort des entités ainsi que les issues de combat (Victoire/Défaite).
- **`InventoryController` (`inventoryProvider`)** : Suivi des finances du joueur (or) et des objets passifs (`relics`).
- **`SkillController` (`skillProvider`)** : Contrôle l'état et le temps de recharge (`cooldown`) des compétences actives du héros.

### Système d'Affrontement et Résolution (`EncounterSystem` & `EffectResolver`)
- **`EncounterSystem` (`lib/game/systems/encounter_system.dart`)** : C'est le générateur de groupes de combat. À partir du niveau de la run (`currentLevel`) et du type de nœud (`MapNodeType.combat`, `elite`, `boss`), il extrait les structures d'ennemis du registre et leur applique des multiplicateurs de statistiques (ex : `x1.5` pour un combat Élite, `x3.0` pour un Boss).
- **`EffectResolver` (`lib/game/services/effect_resolver.dart`)** : Service pur qui traite les effets de cartes jouées. Il valide d'abord la faisabilité via `canPlayCard()` (mana suffisant, cible correcte). Ensuite, dans `resolveCard()`, il boucle sur les effets listés dans `CardData` (dégâts bruts, soins, armure cumulée à la maîtrise, pioche, application de statuts). Les dégâts physiques y sont calculés dynamiquement dans `_calculateDamage()` en incorporant la force brute (`effectiveAttaque`) et la réduction sous effet de faiblesse (`weakness` inflige -25% de dégâts).

---

## 2. Stratégie de State Management (Riverpod)

Le projet utilise **Riverpod (v2.5.1)** comme unique source de vérité pour les états mutables. La structure de l'état est maintenue 100% immuable pour assurer la réactivité et éviter les bugs de race-conditions ou de mutations silencieuses.

### Types de Providers identifiés dans le code
1. **`runProvider` (`StateNotifierProvider<RunController, RunState>`)** :
   - Gère l'état global de la run en cours (`RunState`).
   - Non-autoDisposed pour conserver la progression de la run entre les écrans.
2. **`deckProvider` (`StateNotifierProvider<DeckNotifier, DeckState>`)** :
   - Gère le deck logique (`DeckState`).
   - Réinitialisé à chaque nouvelle run (`clearDeck()`) et préparé au combat (`initializeCombat()`).
3. **`combatProvider` (`StateNotifierProvider<CombatController, CombatState>`)** :
   - Gère l'état temporaire du combat (`CombatState`).
   - Fait le pont avec les monstres générés et pilote le déroulement phase par phase (Player / Enemy).
4. **`inventoryProvider` (`StateNotifierProvider<InventoryController, InventoryState>`)** :
   - Centralise l'économie et la gestion des reliques.
5. **`skillProvider` (`StateNotifierProvider<SkillController, SkillState>`)** :
   - Gère le cooldown des compétences héroïques uniques.
6. **`gameDataLoaderProvider` (`FutureProvider<GameDataRegistry>`)** :
   - Chargeur asynchrone des assets JSON (`GameDataService`). Utilisé pour le démarrage à froid de l'application et l'injection des bases de données de jeu statiques dans l'UI et les contrôleurs.

### Synchronisation bidirectionnelle Flame ⇄ Riverpod
Le moteur de rendu Flame s'aligne de manière réactive sur l'état Riverpod sans polluer la logique métier :
- **Flame écoutant Riverpod (Descente d'état)** : Dans la boucle de mise à jour de `HerosDraftGame.update()`, les données Riverpod poussées depuis l'interface sont interceptées dans des tampons (`_nextState`, `_nextDeckState`, `_nextCombatState`). Si un changement survient, Flame invoque les méthodes de diffing (`_applyState`, `_applyDeckState`, `_applyCombatState`) pour instancier ou repositionner les composants visuels (`HeroCard`, `EnemyCard`, `CardComponent` dans la main) à la frame suivante.
- **Flame pilotant Riverpod (Remontée d'événements)** : Les interactions physiques sur le Canvas (glisser-déposer une carte, cibler un monstre, cliquer sur le bouton fin de tour) sont retransmises à Riverpod via des callbacks fortemente typés passés au constructeur de `HerosDraftGame` (ex : `onPlayCard`, `onSelectEnemy`, `onResolveEnemyIntent`).

---

## 3. UI et Composants Graphiques

Le design visuel repose sur deux technologies distinctes s'emboîtant harmonieusement.

### Rendu de Jeu Flame (`lib/game/components/`)
Gère l'arène de combat avec des animations fluides et du retour haptique ("Visual Juice") :
- **`CardComponent` (`card_component.dart`)** : Hérite de `PositionComponent` avec détection d'événements (`DragCallbacks`, `HoverCallbacks`). Représente la carte en main. Gère le tilt organique lors du déplacement, le tracé de ciblage réactif `TargetingLine`, et les animations d'anticipation ou de retour en main en cas de mana insuffisant (Shake animation).
- **`EnemyCard` et `HeroCard` (`lib/game/components/entities/`)** : Représentent les entités physiques de combat. Gèrent les animations dynamiques (attaque en avant via `dashAnimation`, pulsation lumineuse de ciblage, text flottant de dégâts `FloatingText` et barre de vie réactive `HealthBar` ou `StatBadge`).
- **`StatBadge` (`stat_badge.dart`)** : Un composant Flame sur mesure dessiné vectoriellement pour afficher les statistiques d'armure et de vie en temps réel avec des jauges progressives.
- **Priorités de Z-Indexing (`lib/game/game_constants.dart`)** :
  - Arrière-plan (`priorityBackground`) : `-100`
  - Personnages et ennemis (`priorityHero`/`priorityEnemy`) : `10` / `20`
  - Tracé de ciblage (`priorityTargetingLine`) : `500`
  - Cartes en main standard (`basePriority`) : `10 + index`
  - Carte survolée (`priorityCardHovered`) : `200`
  - Carte ciblée (`priorityCardFocused`) : `790`

### Widgets Flutter UI Overlay (`lib/ui/`)
Surplombent le canvas Flame pour afficher les écrans statiques et le HUD interactif :
- **`UiCard` (`lib/ui/widgets/ui_card.dart`)** : **Composant UI maître unifié**. Il fournit un gabarit de carte complet, typé, et responsive doté d'un ratio constant `70 / 110`. Il remplace toutes les duplications visuelles de cartes dans les boutiques, les dictionnaires et les écrans de draft.
- **Textes et Description Dynamique** : `UiCard` intègre une résolution textuelle robuste (`_buildDescription()`) qui calcule à la volée les valeurs d'effets mises à l'échelle du niveau de la carte (`scaledValue = baseValue * (1 + (level - 1) * 0.5)`) et les injecte dans les expressions internationalisées `AppLocalizations`.

---

## 4. Conventions de Code & Standards Techniques

Le codebase suit des consignes de qualité très strictes pour assurer la robustesse du projet :
- **Analyse Statique et Linter (`analysis_options.yaml`)** :
  - Configure les règles standard de Flutter via `include: package:flutter_lints/flutter.yaml`.
  - Exige le typage fort, l'utilisation systématique de constructeurs `const` pour optimiser le rebuild de l'arbre de widgets, et la proscription des variables non typées (`dynamic`) lorsque c'est évitable.
- **Sécurité Typographique et Gestion de Données** :
  - Utilisation exhaustive des types d'énumérations fortement typés (`CardType`, `CardCategory`, `CardRarity`, `CardTarget`, `MapNodeType`, `IntentType`, `StatusType`, `TurnPhase`) pour éliminer les typos et optimiser les performances des branchements `switch`.
  - Pas d'écriture directe (I/O) ou de modifications de logique métier au sein des vues UI (toutes déléguées aux contrôleurs Riverpod correspondants).
  - Validation obligatoire via l'outil `dart analyze` à chaque fin de phase technique (0 erreur et 0 avertissement tolérés).
