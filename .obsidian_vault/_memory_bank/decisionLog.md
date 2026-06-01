# 📋 Registre des Décisions Architecturales (Decision Log)

Ce document répertorie sous forme d'**ADR (Architecture Decision Records)** les choix de conception structurants qui pilotent le développement et l'évolution technique de **Hero's Draft**. Chaque ADR est tracé à partir de preuves factuelles dans le code source, les rapports de dette technique et la documentation du projet.

---

## 🏛️ ADR-001 : Séparation Triangulaire État/Rendu/UI (Riverpod ⇄ Flame ⇄ Flutter)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans les jeux intégrant des moteurs de rendu interactifs comme Flame, il est courant que la logique métier (calcul de dégâts, cycle de vie du deck, debuffs, cooldowns) se retrouve couplée au code de dessin ou de gestion des animations (`PositionComponent`). Cela rend les tests impossibles sans instancier le moteur graphique et provoque des désynchronisations état/affichage.

### Décision
- **Exclure toute logique métier du moteur Flame** : les contrôleurs Riverpod (`RunController`, `DeckNotifier`, `CombatController`, `InventoryController`, `SkillController`, `EventController`, `ShopController`) sont la source unique de vérité.
- **Rendre Flame réactif et passif** : il observe l'état Riverpod via un pattern de **double-buffering** (`_nextState`, `_nextDeckState`, `_nextCombatState`) appliqué dans `HerosDraftGame.update(dt)` par diffing visuel.
- **Limiter les interactions Flame à des callbacks** : 18 callbacks fortement typés (ex: `onPlayCard`, `onSelectEnemy`, `onResolveEnemyIntent`) injectés via le constructeur de `HerosDraftGame`.

### Preuves dans le code
- `HerosDraftGame` (775 lignes) contient uniquement de la logique de rendu, layout, et animation — pas de calcul de dégâts ni de gestion d'état.
- Tous les `StateNotifier` dans `lib/game/controllers/` fonctionnent indépendamment de Flame.
- `EffectResolver` est une classe statique pure sans dépendance Flame.

### Conséquences
- ✅ **Tests unitaires purs** : 58 tests au vert sans instancier le moteur graphique.
- ✅ **Éradication des bugs de désynchronisation** entre affichage et valeurs logiques.
- ⚠️ **Rigueur nécessaire** : Le pattern de buffering peut manquer des changements d'état si plusieurs mutations surviennent dans une même frame (identifié dans `docs/lessons/flame_riverpod_sync.md`).
- ⚠️ **Violation partielle** : `HerosDraftGame.executeSkill()` contient encore de la logique de calcul de dégâts (damage_aoe, damage_targeted, armor_buff) — identifiée comme dette technique dans le rapport Opus 4.6.

---

## 📐 ADR-002 : Responsivité Dynamique par ScaleFactor

### Statut
✅ Accepté & Implémenté

### Contexte
Le jeu cible des supports variés : smartphones étroits, tablettes et moniteurs PC 4K. Flame utilise un canvas absolu par défaut, ce qui peut tronquer ou déformer l'affichage sur des résolutions non-standard.

### Décision
Implémenter une formule de mise à l'échelle dynamique basée sur la **hauteur réelle du viewport** :
```dart
double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);
```
- **Hauteur de référence** : 800px (résolution mobile standard portrait).
- **Clamp** : 0.85 (plancher pour très petits écrans) à 2.5 (plafond pour écrans 4K).
- Tous les composants graphiques (cartes 140×196, espacements, arcs de main, positions ennemis) sont multipliés par ce coefficient.

### Preuves dans le code
- `HerosDraftGame.scaleFactor` utilisé dans `_applyState()`, `_applyDeckState()`, `_applyCombatState()`, `onGameResize()`.
- `_layoutHand()` : `radius = size.y * 1.5`, angles et positions calculés proportionnellement.
- `GameConstants` : `cardWidth = 140.0`, `cardHeight = 196.0` — valeurs de base avant application du scale.

### Conséquences
- ✅ Adaptabilité visuelle du mobile au PC 4K sans rupture de layout.
- ✅ Préservation du "Game Feel" organique et de l'alignement des éléments.
- ⚠️ Contrainte d'incorporer `scaleFactor` sur toutes les dimensions, augmentant le risque d'oublis pour les nouveaux composants.

---

## 🌐 ADR-003 : Architecture 100% Data-Driven (JSON Assets)

### Statut
✅ Accepté & Implémenté

### Contexte
Les données de jeu (cartes, ennemis, héros, reliques, événements, passifs, compétences) pourraient être définies directement dans le code Dart ou dans des fichiers de données externes.

### Décision
- Définir **100% du contenu de jeu** dans des fichiers JSON stockés dans `assets/data/` (7 fichiers).
- Chaque fichier JSON a un modèle Dart correspondant dans `lib/models/data/` avec une factory `fromJson()`.
- Le chargement est centralisé dans `GameDataService.loadAll()` qui produit un `GameDataRegistry` immutable.
- Le registre est exposé via un `FutureProvider<GameDataRegistry>` (`gameDataLoaderProvider`).

### Preuves dans le code
- 7 fichiers JSON : `cards.json` (23 cartes), `enemies.json` (4 ennemis), `heroes.json` (3 héros), `skills.json` (6 compétences), `events.json` (2 événements), `passives.json` (3 passifs), `relics.json` (12 reliques).
- 8 modèles Data avec `fromJson()` : `CardData`, `EnemyData`, `HeroData`, `SkillData`, `EventData`, `PassiveData`, `RelicData`, `GameDataRegistry`.
- `GameDataService.loadAll()` utilise `Future.wait()` pour charger les 7 fichiers en parallèle.

### Conséquences
- ✅ **Modding** : Modification des valeurs ou équilibrage instantané sans toucher au code.
- ✅ **Séparation des compétences** : Un game designer peut modifier les JSON sans connaître Dart.
- ✅ **Extension facile** : Ajouter un nouvel ennemi = ajouter un objet dans `enemies.json`.
- ⚠️ **Pas de validation au chargement** : Aucun `try-catch` dans `GameDataService` — une erreur JSON crash l'app.
- ⚠️ **Lookup O(n)** : `GameDataRegistry` utilise des `List<T>` avec recherche linéaire — devrait être `Map<String, T>` pour O(1).

---

## 🃏 ADR-004 : Unification du Rendu de Cartes (Widget `UiCard`)

### Statut
✅ Accepté & Implémenté

### Contexte
La représentation graphique des cartes était dupliquée dans 6 fichiers d'écrans (ShopScreen, DraftScreen, StarterDeckDraftScreen, etc.). Toute modification du design nécessitait 6 modifications parallèles.

### Décision
- Concevoir un widget Flutter unique `UiCard` dans `lib/ui/widgets/ui_card.dart`.
- Ce widget encapsule : gradient rareté, cristal mana, icône type, barre nom, badge level, description dynamique.
- `_buildDescription()` calcule automatiquement les valeurs mises à l'échelle du niveau et remplace les placeholders.
- Remplacer toutes les implémentations inline dans les 5+ écrans UI.

### Preuves dans le code
- `UiCard` utilisé dans `StarterDeckDraftScreen`, `DraftScreen`, `ShopScreen`, `CampfireScreen`, `DictionaryScreen`.
- Ratio d'aspect constant `70 / 110`.
- Gradients par rareté : grey (common), green (uncommon), blue (rare), purple (epic), gold (legendary).

### Conséquences
- ✅ Cohérence graphique absolue sur l'ensemble de l'UI.
- ✅ Réduction de plusieurs centaines de lignes de code redondant.
- ✅ Maintenance centralisée en un seul fichier.
- ⚠️ **Dualité non résolue** : `CardComponent` (Flame) a son propre rendu de carte indépendant — deux systèmes de rendu coexistent.

---

## 🔒 ADR-005 : Immuabilité d'État et Pattern `copyWith`

### Statut
✅ Accepté & Implémenté

### Contexte
La gestion d'état mutable dans des contextes asynchrones (Flame loop + UI rebuilds) provoque des race conditions et des mutations silencieuses non détectées par Riverpod.

### Décision
- Tous les `StateNotifier` émettent de nouveaux objets d'état via `state = state.copyWith(...)`.
- Les listes sont recréées (pas de `.add()` in-place) : `state = state.copyWith(enemies: [...state.enemies, newEnemy])`.
- Les modèles d'état (`RunState`, `DeckState`, `CombatState`, etc.) implémentent `copyWith()`.

### Preuves dans le code
- Pattern `copyWith` visible dans tous les contrôleurs (`RunController`, `CombatController`, `DeckNotifier`, etc.).
- Documentation dans `docs/lessons/state_immutability.md`.
- `CombatState`, `EntityStats`, `StatusEffect` possèdent des `copyWith` complets.

### Conséquences
- ✅ Réactivité fiable de Riverpod (détection de changements par référence).
- ✅ Traçabilité des mutations d'état.
- ⚠️ **Violation partielle identifiée** (rapport Opus 4.6) : Certaines listes mutables persistent dans les états "immuables" (enemies, relics, statusEffects) — risque de casser la détection de changements Riverpod.
- ⚠️ Absence de `==`/`hashCode` sur les modèles — comparaison par référence uniquement.

---

## 🌍 ADR-006 : Localisation Data-Driven (i18n)

### Statut
✅ Accepté & Implémenté

### Contexte
La version initiale comportait des chaînes codées en dur en français, des variables `isFr` locales pour commuter les traductions, et des données JSON monolingues.

### Décision
- Éradiquer toutes les variables `isFr` et conditions manuelles de langue.
- Migrer l'UI Flutter vers `AppLocalizations` (ARB : `app_en.arb`, `app_fr.arb`).
- Ajouter des double-champs bilingues dans tous les modèles Data (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
- Exposer des méthodes `getName(locale)` / `getDescription(locale)` sur chaque modèle.
- Les statuts de combat transitent via des identifiants techniques neutres (`poison`, `weakness`), traduits à la volée par `StatusEffectsPanel`.

### Preuves dans le code
- Zéro variable `isFr` dans tout le codebase.
- `CardData.fromJson` supporte un fallback `name` → `nameEn` pour rétrocompatibilité.
- `StatusEffectsPanel` traduit dynamiquement les identifiants techniques.

### Conséquences
- ✅ Conformité i18n à 100%, `flutter analyze` vierge.
- ✅ Extension facile vers d'autres langues (ajouter ARB + compléter JSON).
- ⚠️ **Exception** : `SkillData` n'a qu'un champ `name` unique — pas encore migré vers le bilingue.

---

## 🎲 ADR-007 : Système de Merge Automatique (3→1)

### Statut
✅ Accepté & Implémenté

### Contexte
L'accumulation de cartes dans un roguelike deckbuilder peut diluer la puissance du deck. Un mécanisme d'amélioration automatique est nécessaire.

### Décision
- Quand le `masterDeck` contient 3 exemplaires d'une carte avec le **même `baseCardId` ET le même `level`**, ils fusionnent automatiquement en 1 exemplaire de level+1.
- La fusion est déclenchée par `DeckNotifier.mergeCards(cardId, level)`.
- L'échelonnement des effets suit : `scaledValue = baseValue * (1 + (level - 1) * 0.5)`.

### Preuves dans le code
- `DeckNotifier.mergeCards()` : recherche 3 copies, suppression, ajout level+1.
- `EffectResolver.resolveCard()` : calcul du `scaledValue` par level.
- `UiCard._buildDescription()` : affichage des valeurs scalées.
- Documentation dans `docs/implementation_plans/deck_merge_system.md`.

### Conséquences
- ✅ Progression organique du deck sans interface d'amélioration explicite.
- ✅ Effet satisfaisant pour le joueur ("power spike" naturel).
- ⚠️ Complexité de l'algorithme : O(n²) pour grands decks (non problématique à <50 cartes actuellement).

---

## 🔄 ADR-008 : Double-Buffering pour la Synchronisation Flame ⇄ Riverpod

### Statut
✅ Accepté & Implémenté

### Contexte
La boucle de jeu Flame (`update`) tourne à 60fps, tandis que les mutations Riverpod surviennent de manière asynchrone depuis l'UI Flutter. Un mécanisme de synchronisation sûr est nécessaire pour éviter les accès concurrents.

### Décision
- Trois **tampons nullable** dans `HerosDraftGame` : `_nextState`, `_nextDeckState`, `_nextCombatState`.
- Des **setters publics** (`syncState`, `syncDeck`, `syncCombat`) écrivent dans ces tampons depuis le thread UI.
- Dans `update(dt)`, si un tampon est non-null et `hasLayout == true`, la méthode de diffing correspondante est appelée (`_applyState`, `_applyDeckState`, `_applyCombatState`), puis le tampon est remis à null.

### Preuves dans le code
- `HerosDraftGame` : 3 champs `_nextState`/`_nextDeckState`/`_nextCombatState`.
- `GameScreen` : appelle `game.syncState()` dans des `addPostFrameCallback`.
- Leçon documentée dans `docs/lessons/flame_riverpod_sync.md`.

### Conséquences
- ✅ Pas de race condition entre Flame et Riverpod.
- ✅ Rendu toujours cohérent à la frame suivante.
- ⚠️ **Risque** : Si deux mutations d'état surviennent dans la même frame, seule la dernière est appliquée (la première est écrasée dans le tampon).
- ⚠️ Le rapport Gemini 3.5 recommande un pattern event-driven plutôt que polling de tampons.

---

## 🗺️ ADR-009 : Graphe Acyclique Dirigé pour la Carte du Monde

### Statut
✅ Accepté & Implémenté

### Contexte
Les roguelikes deckbuilders utilisent typiquement une carte procédurale permettant des choix de parcours. Le design doit offrir de la variété tout en garantissant l'accessibilité de tous les nœuds.

### Décision
- Générer un **DAG** de 10 étages via `MapGeneratorService.generateMap()`.
- Largeur variable de 2 à 5 nœuds par étage, avec des règles spéciales (chokepoint à l'étage 5, repos garanti avant boss, boss unique au dernier étage).
- Connexions par offset (-1, 0, +1) depuis un index proportionnel, avec passe de correction d'orphelins.
- Le modèle `MapNode` utilise `Vector2` de Flame pour le positionnement.

### Preuves dans le code
- `MapGeneratorService` : ~120 lignes de logique de génération.
- `MapNode` : utilise `Vector2` (import Flame).
- `RunController.startNewRun()` : appelle `MapGeneratorService.generateMap()`.

### Conséquences
- ✅ Rejouabilité élevée (variété de parcours).
- ✅ Garantie d'accessibilité (passe orphelins).
- ⚠️ **Couplage modèle/rendu** : `MapNode` importe `Vector2` de Flame — le modèle de données dépend du moteur de rendu.

---

## 🚫 ADR-010 : Absence Délibérée de Routeur Centralisé

### Statut
⚠️ Accepté (dette technique reconnue)

### Contexte
Le projet utilise des appels directs `Navigator.of(context).push(MaterialPageRoute(...))` pour toutes les transitions d'écran (20+ occurrences).

### Décision Actuelle
Navigation hardcodée dans les callbacks graphiques des écrans. Pas de `GoRouter`, pas de `NavigationController`, pas de routes nommées.

### Raison Probable
Simplicité initiale et développement incrémental — chaque écran ajouté naviguait directement vers le suivant.

### Conséquences
- ✅ Simplicité de mise en œuvre initiale.
- ❌ **Fragile** : Pas de deep linking, pas de restauration d'état à la reprise.
- ❌ **Difficile à maintenir** : 20+ transitions dispersées dans le code.
- 📋 **Identifié comme refactoring Phase 4** dans les plans d'implémentation.

---

## 💾 ADR-011 : Absence de Système de Persistance

### Statut
⚠️ Accepté (dette technique reconnue)

### Contexte
L'état logique de la run (`RunState`, `DeckState`, `CombatState`, `InventoryState`) réside uniquement en mémoire vive. Aucune dépendance de persistance (`shared_preferences`, `sqlite`) n'est dans le `pubspec.yaml`.

### Décision Actuelle
Pas de sauvegarde. Fermer l'app ou crash = perte totale de progression.

### Sérialisation Existante
Certains modèles ont déjà `fromJson`/`toJson` (`CombatState`, `EnemyInstance`, `EntityStats`, `StatusEffect`, `MapNode`), mais d'autres non (`CardInstance`, `InventoryState`, `SkillState`).

### Conséquences
- ❌ **Bloquant pour la commercialisation** : inacceptable pour un jeu mobile.
- 📋 **Identifié comme refactoring Phase 4** : créer un `SaveService` avec auto-save après chaque action majeure.

---

## 🔇 ADR-012 : Absence de Système Audio

### Statut
⚠️ Accepté (dette technique reconnue)

### Contexte
`// TODO: Audio Hook` est disséminé dans les fichiers d'effets et d'interactions de cartes, mais aucune dépendance audio n'existe dans `pubspec.yaml`.

### Décision Actuelle
Pas d'audio. Pas de `flame_audio`, pas de `audioplayers`, pas de `AudioService`.

### Conséquences
- ❌ L'expérience de jeu manque de feedback sensoriel.
- 📋 **Identifié dans la roadmap** : ajouter `flame_audio`, créer un `AudioService` central.

---

## 💀 ADR-013 : Système de Mort Synchronisée Z-Sync (Z-Sync Death System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la version initiale, lorsqu'un joueur jouait une carte infligeant des dégâts létaux à un ennemi, l'état Riverpod du combat était immédiatement mis à jour, déclenchant instantanément `_cleanDeadEnemies()` et supprimant l'ennemi de la liste dans le `CombatState`. 

Par conséquent, via le double-buffering dans Flame (`_applyCombatState`), l'entité visuelle `EnemyCard` correspondante était instantanément retirée (ou lançait son effet de disparition) pendant que l'animation physique de la carte (déplacement de mêlée ou projectile) était encore en cours de déplacement. L'impact de la carte frappait ainsi de l'air vide, créant une désynchronisation visuelle majeure (race condition visuelle).

### Décision
- **Introduire un état de temporisation des morts (Z-Sync)** :
  - Ajouter un drapeau booléen central `isCardAnimating` dans `HerosDraftGame` pour indiquer qu'une animation de carte de combat est en cours de lecture.
  - Ajouter un drapeau booléen local `isPendingDeath` dans `EnemyCard`.
- **Différer le nettoyage visuel** :
  - Lors de l'application de `_applyCombatState`, si un ennemi présent dans le canvas Flame n'est plus présent dans la liste logique du combat Riverpod (ce qui signifie qu'il est mort), nous vérifions si `game.isCardAnimating` est actif.
  - Si oui, au lieu de supprimer immédiatement le composant ou de lancer sa disparition normale, l'ennemi est marqué avec `isPendingDeath = true` et reste visible, opaque et interactif sur le board.
- **Résolution synchrone à l'impact** :
  - Lorsque l'animation de la carte (physique ou magique) arrive à son terme et applique l'impact visuel (particules, shake, flash), sa méthode `onComplete` appelle `game.resolvePendingDeaths()`.
  - Cette méthode désactive `isCardAnimating` et déclenche enfin les animations de mort (rétrécissement d'échelle et fondu d'opacité) de toutes les `EnemyCard` marquées en `isPendingDeath`.
- **Bypass pour le hors-combat** :
  - Si un ennemi meurt de façon passive sans qu'une carte ne soit activement en train de s'animer (par exemple, les dégâts de poison au début du tour ennemi), le système Z-Sync contourne automatiquement le délai pour appliquer immédiatement la mort visuelle.

### Preuves dans le code
- `HerosDraftGame.isCardAnimating` (variable d'orchestration).
- `EnemyCard.isPendingDeath` (état de report de mort).
- Méthode `HerosDraftGame.resolvePendingDeaths()` qui itère sur les composants enfants de type `EnemyCard` pour lancer leur transition de mort si `isPendingDeath == true`.
- Callback `onComplete` des effets de mouvement et d'impact dans `CardComponent` ou les orchestrateurs d'animations graphiques de cartes.

### Conséquences
- ✅ **Game Feel Premium** : Les cartes frappent toujours une cible solide et existante, et l'impact visuel se synchronise parfaitement avec l'éjection de particules vectorielles et le flash du sprite.
- ✅ **Éradication complète de la race condition visuelle** : Zéro ennemi ne disparaît prématurément avant d'avoir reçu le coup physique.
- ✅ **Robustesse préservée** : La logique du jeu (Riverpod) reste le maître absolu des calculs de vie et de mort, le moteur Flame gérant uniquement le report temporel de l'affichage visuel de cette mort pour des raisons de synchronisation esthétique.
- ⚠️ **Rigueur d'implémentation** : Tout nouveau type de carte animée doit impérativement déclarer le début d'une animation en basculant `game.isCardAnimating = true` et appeler `resolvePendingDeaths()` à sa complétion pour libérer les ennemis en attente.
