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

## 💀 ADR-013 : Système de Mort et de Stats Synchronisé Z-Sync (Z-Sync Death & Stats System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la version initiale, lorsqu'un joueur jouait une carte infligeant des dégâts ou tuant un ennemi, l'état Riverpod du combat était immédiatement mis à jour (déclenchant instantanément `_cleanDeadEnemies()` et modifiant les points de vie / armure dans le `CombatState`).

Par conséquent, via le double-buffering dans Flame (`_applyCombatState`), l'entité visuelle `EnemyCard` correspondante voyait sa barre de vie (`HealthBar`) se vider et son badge d'armure s'actualiser, ou l'ennemi était purement supprimé du canvas pendant que l'animation physique de la carte (mouvement de mêlée ou projectile) était encore en cours de déplacement. L'impact de la carte frappait ainsi une cible déjà diminuée ou disparue, créant des désynchronisations visuelles majeures (race conditions visuelles de mort et de statistiques).

### Décision
- **Introduire un état de temporisation des morts et des statistiques (Z-Sync)** :
  - Ajouter un drapeau booléen central `isCardAnimating` dans `HerosDraftGame` pour indiquer qu'une animation de carte de combat est active.
  - Ajouter un drapeau booléen local `isPendingDeath` et un champ d'instance temporaire `EnemyInstance? _pendingVisualInstance` dans `EnemyCard`.
- **Différer la mise à jour des statistiques visuelles tout en gardant un feedback réactif** :
  - Lors de la réception de `updateStats(EnemyInstance newInstance)`, les effets d'impact physiques immédiats (secousses haute fréquence de la carte, flashs sprite de couleur, apparition de nombres flottants de dégâts `FloatingText` et jaillissement radial de particules `spawnDamageParticles`) sont **déclenchés instantanément** pour conserver une réactivité visuelle immédiate et extrêmement dynamique.
  - Cependant, si `game.isCardAnimating` est actif, la mise à jour réelle des indicateurs visuels du HUD de l'ennemi (la barre de vie `HealthBar`, le badge d'armure `StatBadge`, et la liste des icônes de buffs/debuffs) est **différée** : les données sont stockées temporairement dans `_pendingVisualInstance` et les badges ne sont pas rafraîchis. Si `isCardAnimating` est faux, la mise à jour est directe.
- **Différer le nettoyage des ennemis morts** :
  - Dans `_applyCombatState`, si un ennemi visuel Flame a été logiquement supprimé de l'état du combat Riverpod :
    - Si `game.isCardAnimating == true`, il n'est **PAS** supprimé immédiatement. Il est marqué `isPendingDeath = true` et reste pleinement dessiné sur le board.
    - Si faux, il disparaît immédiatement.
- **Résolution synchrone à l'impact** :
  - Lorsque l'animation de la carte (physique ou magique) arrive à son terme (impact sur la cible), son callback `onComplete` appelle `game.resolvePendingDeaths()`.
  - Cette méthode désactive le verrouillage en passant `isCardAnimating = false`, puis itère sur toutes les `EnemyCard` pour :
    1. Appeler `card.resolvePendingVisualStats()` : cela applique le `_pendingVisualInstance` mis en réserve, mettant à jour de façon synchrone les barres de vie, les badges d'armure et les indicateurs à la frame exacte de l'impact physique.
    2. Déclencher enfin l'animation de disparition (rétrécissement `ScaleEffect` et fondu d'opacité `OpacityEffect`) de toutes les `EnemyCard` marquées `isPendingDeath == true`.
- **Bypass pour le hors-combat** :
  - Si les statistiques ou la mort changent de façon passive hors de l'animation d'une carte (par exemple, les dégâts de poison ou brûlure au début du tour ennemi), le système Z-Sync contourne le délai pour mettre à jour les jauges et appliquer la mort visuelle instantanément.

### Preuves dans le code
- `HerosDraftGame.isCardAnimating` (verrouillage central).
- `EnemyCard.isPendingDeath` et `EnemyCard._pendingVisualInstance` (conservation d'état local différé).
- `EnemyCard.resolvePendingVisualStats()` : applique `_pendingVisualInstance`, appelle `_refreshBadges()` et met à jour les icônes de statuts.
- `HerosDraftGame.resolvePendingDeaths()` qui coordonne l'appel séquentiel de `resolvePendingVisualStats()` sur toutes les cartes ennemies avant de déclencher l'effet de mort sur les ennemis en attente de destruction.

### Conséquences
- ✅ **Game Feel Premium Exceptionnel** : Les cartes frappent toujours une cible solide dont la barre de vie se vide et dont l'armure se brise à la microseconde exacte de l'impact, maximisant la satisfaction sensorielle du joueur.
- ✅ **Éradication complète des race conditions visuelles** : Zéro modification de jauge prématurée ou disparition d'ennemi avant la rencontre physique réelle du projectile ou du coup de mêlée.
- ✅ **Respect de l'architecture découplée** : La couche Riverpod conserve la maîtrise absolue de l'état logique exact du combat, la couche Flame n'agissant que comme un cache graphique différé réaligné à l'impact.
- ⚠️ **Rigueur d'orchestration** : Toute action de carte de combat doit impérativement basculer `game.isCardAnimating = true` au lancement de l'effet et appeler `resolvePendingDeaths()` à sa complétion pour déverrouiller la synchronisation visuelle.

---

## 🧪 ADR-014 : Système de Résolution des Altérations Élémentaires (Burn, Freeze, Shock)

### Statut
✅ Accepté & Implémenté

### Contexte
La version initiale déclarait dans ses modèles de données et ses templates d'interface (les descriptions de cartes dans `UiCard`) trois altérations d'état élémentaires majeures : la Brûlure (`burn`), le Gel (`freeze`) et l'Électrocution (`shock`). 
Cependant, la logique de résolution de ces statuts était totalement absente du pipeline de combat (`EffectResolver` et `CombatController`), rendant les cartes appliquant ces statuts purement décoratives au niveau du gameplay. Il était nécessaire d'implémenter une résolution logique rigoureuse de ces statuts tout en respectant l'architecture découplée sans introduire de couplage avec Flame.

### Décision
1. **Création Centralisée et Typage Métier** :
   - Câbler la création des instances de statuts dans le switch helper de `EffectResolver._createStatus()`.
   - Associer les identifiants textuels `burn`, `freeze`, `shock` à des objets `StatusEffect` fortement typés en tant que `StatusType.debuff`.

2. **Mécanique de Résolution de la Brûlure (`burn`)** :
   - Résoudre la brûlure de manière autonome au début de chaque tour ennemi.
   - Accumuler les valeurs de brûlure pour chaque ennemi et appliquer des dégâts directs sur ses PV logiques : `updatedStats = updatedStats.takeDamage(burnDamage)`.
   - La brûlure se résout dans `CombatController.startEnemyTurn()` en parallèle du poison, garantissant une cohérence d'exécution temporelle.

3. **Mécanique de Résolution du Gel (`freeze`)** :
   - Réduire la dangerosité offensive d'un ennemi sous l'effet du gel.
   - Lors de la résolution séquentielle de son intention dans `CombatController.resolveEnemyIntent()`, si l'attaquant a le statut `freeze`, les dégâts infligés au héros sont divisés par deux (arrondi au plus proche) :
     ```dart
     int dmg = intent.value;
     if (enemy.stats.statuses.any((s) => s.id == 'freeze')) {
       dmg = (intent.value * 0.5).round();
     }
     ```

4. **Mécanique de Résolution de l'Électrocution (`shock`)** :
   - Créer un effet multiplicateur ou additif de dégâts subis sur l'ennemi.
   - Dans `EffectResolver.resolveCard()` lors de la résolution de l'effet `damage` (qu'il soit ciblé ou de zone), vérifier si l'ennemi ciblé possède le statut `shock`.
   - Si oui, additionner directement la valeur cumulée du statut `shock` aux dégâts de base calculés de la carte d'attaque :
     ```dart
     final shockStatus = enemy.stats.statuses.firstWhere(
       (s) => s.id == 'shock',
       orElse: () => StatusEffect(
         id: '',
         name: '',
         type: StatusType.debuff,
         value: 0,
         duration: 0,
       ),
     );
     if (shockStatus.id.isNotEmpty) {
       dmg += shockStatus.value;
     }
     ```

5. **Couverture de Tests et Assurance Qualité** :
   - Intégrer une couverture de test unitaire exhaustive simulant l'application de chaque statut dans `test/unit/combat_controller_test.dart` (portant la suite de tests à 60 tests réussis à 100%).

### Preuves dans le code
- `EffectResolver._createStatus()` : Déclaration des switch cases `burn`, `freeze`, `shock` renvoyant le modèle `StatusEffect` avec les noms en français (« Brûlure », « Gel », « Électrocution »).
- `CombatController.startEnemyTurn()` : Récupération cumulée de `burnDamage += status.value` et application via `updatedStats = updatedStats.takeDamage(burnDamage)`.
- `CombatController.resolveEnemyIntent()` : Division des dégâts par 2 si le statut `freeze` est présent dans la liste des statuts actifs de l'ennemi.
- `EffectResolver.resolveCard()` : Lookup du statut `shock` sur l'instance d'ennemi en cours d'attaque et incrément de `dmg += shockStatus.value` avant l'appel à `updateEnemyStats`.
- `test/unit/combat_controller_test.dart` (Lignes 424-558) : Le test unitaire complet validant le bon fonctionnement combiné ou isolé des trois statuts en combat.

### Conséquences
- ✅ **Système de Combat Complet et Coordonné** : Les mécaniques élémentaires sont désormais 100% opérationnelles, donnant une vraie profondeur stratégique aux classes de personnages (notamment le Mage qui s'appuie fortement sur ces altérations).
- ✅ **Respect Strict de l'Architecture Découplée (ADR-001)** : Toute la logique de calcul de dégâts, de réduction, et de résolution autonome est pilotée de bout en bout par la couche métier Riverpod. Flame se contente de lire l'état double-bufferisé pour afficher les icônes de statut.
- ✅ **Extrême Robustesse Logicielle** : La suite de tests unitaires garantit qu'aucune régression logicielle ne peut affecter le calcul ou l'application de ces statuts.
- ⚠️ **Stacking Infini** : Par conception, les statuts élémentaires s'empilent et se cumulent à chaque tour. Une attention particulière à l'équilibrage des cartes appliquant ces statuts sera nécessaire pour éviter des combos infinis de surpuissance (ex: accumuler trop d'électrocution pour infliger des centaines de dégâts).

---

## 🎡 ADR-015 : Système de Carrousel de Récompense de Reliques (Interactive Relic Carousel Reward System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la boucle de gameplay originale, lorsqu'un joueur battait un ennemi élite ou un boss, une relique lui était octroyée de manière instantanée, affichée sous forme d'une alerte Toast standard à l'écran. Cette approche manquait grandement d'impact visuel et de feedback émotionnel ("satisfaction du butin") pour le joueur, un aspect pourtant capital dans les roguelikes premium.

### Décision
Concevoir un écran de célébration et de tirage interactif en plein écran appelé **Relic Carousel Reward System** :
1. **Option B (Présentation en Picker 3 cartes simultanées)** :
   - Plutôt que d'afficher une seule relique au centre, présenter 3 cartes simultanément dans un `PageView` doté d'un `viewportFraction` réduit (~0.7).
   - Les cartes latérales subissent un effet de recul/rétrécissement d'échelle (`0.85x`) et de flou/translucidité (`0.4` d'opacité), tandis que la carte centrale active est mise en avant (échelle `1.0x` et pleine opacité `1.0`) pour un guidage visuel optimal.
2. **Animation de décélération fluide** :
   - Un défilement automatique rapide de type machine à sous est lancé.
   - Il décélère de manière progressive en appliquant une courbe cubique de ralentissement (`Curves.easeOutCubic`) sur une durée de 4,0 secondes pour s'arrêter au pixel près sur la relique cible pré-sélectionnée par le contrôleur de jeu.
3. **Sound Hooks Integration** :
   - Lancer un callback de tick sonore (`onTick`) à chaque changement d'index visuel du carrousel pour simuler le bruit d'une roue de loterie.
   - Lancer un callback d'arrêt final (`onLand`) au moment exact de la stabilisation sur la relique gagnée pour déclencher un son de triomphe.
4. **Option A (Bouton de confirmation « Récupérer »)** :
   - La relique n'est **PAS** ajoutée à l'inventaire lors de la phase de rotation pour éviter toute triche ou incohérence visuelle/métier.
   - Un bouton de confirmation « Récupérer » n'apparaît qu'une fois le carrousel parfaitement arrêté et verrouillé sur sa cible, déclenchant simultanément l'écriture dans l'inventaire (`addRelic`) et la transition sécurisée vers l'écran suivant (Draft ou Carte).
5. **Célébration visuelle vectorielle** :
   - À l'arrêt, un `CustomPainter` de particules vectorielles projette des gerbes d'étoiles dorées et de confettis peints sur le Canvas en arrière-plan de la relique remportée.

### Preuves dans le code
- Classe `RelicRewardCarouselOverlay` (widget de carrousel interactif).
- Utilisation de `Curves.easeOutCubic` et d'une durée de 4,0 secondes dans l'orchestrateur de l'animation de défilement du `PageController`.
- Callbacks `onTick` et `onLand` câblés dans l'animation du carrousel.
- `RelicParticlePainter` pour l'effet de projection de particules de victoire.
- Bouton de confirmation conditionné par `isSpinning == false`.

### Conséquences
- ✅ **Game Feel Premium Exceptionnel** : L'effet de suspense de la machine à sous et l'explosion de confettis transforment l'obtention de reliques en un moment de célébration mémorable.
- ✅ **Respect de l'état logique (ADR-001)** : L'inventaire n'est mis à jour qu'au clic sur « Récupérer », maintenant une cohérence parfaite et empêchant toute perte de données en cas de crash/fermeture intempestive pendant la rotation.
- ✅ **Architecture Audio Orientée Événements** : Les hooks `onTick` et `onLand` sont prêts pour brancher le système audio de façon propre sans couplage visuel.

---

## 📈 ADR-016 : Système de Progression XP & Échelonnement Dynamique des Ennemis (XP Progression & Enemy Scaling)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la version initiale, le niveau du héros était figé et les ennemis possédaient des statistiques prédéfinies et fixes dans les fichiers JSON. Ce manque de progression à long terme aplatissait l'expérience au cours d'une run, ne proposant aucun sentiment d'évolution ou de montée en puissance. Pour introduire une dimension RPG gratifiante et conserver une tension compétitive croissante tout au long des actes, le jeu nécessitait l'intégration d'un système d'expérience avec des seuils exponentiels et une mise à l'échelle dynamique des caractéristiques des ennemis basée sur le niveau du joueur et la difficulté de la salle de combat.

### Décision
1. **Courbe d'Expérience Exponentielle** :
   - Implémenter une formule de progression basée sur des seuils d'expérience exponentiels :
     $$RequiredXP = 100 \times 1.5^{\text{level} - 1}$$
   - Concevoir la méthode de gain d'XP (`RunController.gainXp(int xp)`) de sorte qu'elle traite de manière récursive ou itérative les gains d'XP massifs. Si le montant d'XP dépasse plusieurs paliers consécutifs, le héros gagne plusieurs niveaux à la fois tout en conservant et reportant le reliquat d'expérience restant (`XP carry-over`) de façon mathématiquement intègre.

2. **Échelonnement Dynamique des Niveaux de Combat** :
   - Déterminer le niveau d'un ennemi de façon dynamique selon la formule :
     $$EnemyLevel = PlayerLevel + (Act - 1) \times 2 + NodeModifier$$
     - `NodeModifier` vaut `0` pour un combat standard, `+1` pour un combat élite, et `+2` pour un combat de boss de fin d'acte.

3. **Multiplicateurs de Caractéristiques de Combat** :
   - Mettre à l'échelle dynamiquement les points de vie maximaux et les dégâts de base des monstres lors de l'initialisation du combat dans `CombatController`.
   - Augmenter les PV max de **+12% par niveau** de monstre supplémentaire au-dessus du niveau 1.
   - Augmenter l'attaque de base de **+8% par niveau** de monstre supplémentaire au-dessus du niveau 1.
   - Les formules appliquées sont :
     - $$ScaledHP = BaseHP \times [1 + (Level - 1) \times 0.12]$$
     - $$ScaledDamage = BaseDamage \times [1 + (Level - 1) \times 0.08]$$

4. **Visuels et HUD de Progression** :
   - Intégrer une barre de progression XP dorée permanente sous les mini-statistiques du héros sur la carte du monde (`MapScreen`) pour une visualisation claire.
   - Suffixer dynamiquement le nom des ennemis par leur niveau calculé dans l'arène de combat Flame (ex : "Squelette (Niv. 3)") afin de signaler immédiatement la dangerosité relative aux joueurs.

### Preuves dans le code
- `RunController.gainXp(int xp)` : Boucle de consommation d'XP avec augmentation du niveau et report du reliquat.
- `CombatController.initializeCombat()` : Calcul dynamique du niveau et application des multiplicateurs `1 + (level - 1) * 0.12` pour les HP, et `1 + (level - 1) * 0.08` pour les dégâts.
- `test/unit/xp_scaling_test.dart` : Suite de tests unitaires validant l'XP cumulée, le carry-over en cascade (multi-levels), et le calcul correct des niveaux de monstres standards, élites et boss.

### Conséquences
- ✅ **Expérience RPG Profonde** : La boucle d'action devient gratifiante grâce à la montée de niveau et aux bonus de caractéristiques permanentes choisis par le joueur.
- ✅ **Courbe de Difficulté Équilibrée** : L'adaptation automatique élimine la trivialisation des combats en late-game tout en offrant un défi juste et progressif.
- ✅ **Absence de bugs de transition** : Les tests unitaires rigoureux sur l'XP prouvent qu'aucune expérience n'est perdue ou dupliquée lors des montées de niveau successives.
- ⚠️ **Danger de "Soft Lock"** : Si le joueur n'optimise pas son deck (fusions automatiques et forges), la mise à l'échelle des ennemis (+12% HP, +8% ATK) peut rapidement surpasser sa puissance offensive, créant des combats longs et punitifs.

---

## 🎰 ADR-017 : Système Interactif de Révélation de Cartes par Rouleaux 3D (Staggered Draft Slots & Reels)

### Statut
✅ Accepté & Implémenté

### Contexte
Lors de la sélection du deck de départ ou de l'obtention de cartes de draft après une victoire, l'affichage instantané et plat des choix de cartes manquait grandement de "game feel", de dynamisme et d'attrait visuel. Pour transformer l'acquisition de nouvelles cartes en un moment fort et tactile à forte récompense émotionnelle, nous souhaitions concevoir un système inspiré des machines à sous, où chaque slot de carte défile verticalement de manière asynchrone avant de se stabiliser par un effet spectaculaire de rotation 3D (Flip).

### Décision
1. **Composant de Rouleau Individuel (`DraftCardReel`)** :
   - Remplacer l'affichage brut de cartes par trois widgets `DraftCardReel` autonomes.
   - Chaque rouleau simule un défilement vertical ultra-rapide de textures de dos de cartes pour évoquer le suspense d'un tirage.

2. **Révélation Séquentielle Échelonnée (Staggered Stoppage)** :
   - Configurer des délais asynchrones pour l'arrêt de chaque rouleau de gauche à droite afin de rythmer la découverte :
     - **Rouleau 1** : Arrêt et flip à **0.8 seconde**.
     - **Rouleau 2** : Arrêt et flip à **1.4 seconde**.
     - **Rouleau 3** : Arrêt et flip à **2.0 secondes**.
   - Au moment exact de l'arrêt, la carte effectue une rotation 3D à 180° sur l'axe Y pour révéler son identité visuelle unifiée (`UiCard`).

3. **Célébration Temporelle et Visuelle des Raretés Rares/Légendaires** :
   - Si une carte sélectionnée par l'algorithme est de rareté **Épique** ou **Légendaire** :
     - Prolonger délibérément le temps de défilement du rouleau correspondant (+0.8s) pour faire monter le suspense.
     - À l'arrêt, déclencher un effet de secousse de l'écran (`screen-shake`), une explosion radiale de particules d'étoiles dorées et un halo de lumière éclatant sur canvas en arrière-plan.

4. **Architecture Découplée pour l'Audio (Sound Hooks)** :
   - Intégrer des rappels audio `onTick` (bruit sec à chaque changement d'index durant la rotation) et `onLand` (son d'impact lourd lors de l'arrêt) pour autoriser un couplage audio réactif sans lier directement le framework sonore à l'UI visuelle.

### Preuves dans le code
- Widget `DraftCardReel` exploitant un `AnimatedBuilder` pour le flip 3D avec perspective `transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(...)`.
- `DraftScreen` qui instancie les reels avec des décalages temporels de défilement configurés.
- Traitement conditionnel basé sur `CardRarity` pour étendre la durée et émettre des particules de célébration dorées.

### Conséquences
- ✅ **Visual Juice de Niveau Commercial** : La transition post-combat est transformée en une expérience visuelle mémorable et excitante qui valorise le butin.
- ✅ **Découplage Technique Sain** : La couche de présentation Flutter gère ses animations de transition de manière isolée, tout en émettant des hooks prêts pour l'audio et alignés avec les conventions architecturales.
- ⚠️ **Durée du Draft** : La révélation complète requiert un minimum de 2.0 secondes (et plus si célébration légendaire), ce qui peut s'avérer répétitif pour les joueurs aguerris lors de runs successives très rapides. Il est recommandé de conserver ce rythme mais d'analyser la demande des utilisateurs pour un éventuel bouton de raccourci d'affichage immédiat ("Fast Reveal").

---

## 🟥 ADR-018 : Rareté Mythique & Transition d'Alerte Séquentielle en Draft (Mythic Rarity & Two-Step Draft Transition)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour élever le sentiment d'accomplissement et de puissance lors de l'obtention de cartes ultra-spéciales (telles que le Trèfle à quatre feuilles ou le Miroir), le jeu intègre une rareté suprême appelée **'Mythique' (Mythic)**. Présenter ces cartes exceptionnelles de manière brute ou mélangée avec les autres cartes dans un tirage standard affaiblirait considérablement l'impact émotionnel et dramatique souhaité. Nous souhaitions concevoir un flow de transition cinématique séquentiel en deux étapes : d'abord la révélation du Draft standard, puis en cas de tirage Mythique, le déclenchement d'un écran d'alerte spectaculaire, suivi du spin et de la révélation isolés de la carte Mythique au premier plan sous un effet de flou gaussien de l'arrière-plan.

### Décision
1. **Algorithme de Tirage Indépendant Double Rolls** :
   - Plutôt que d'intégrer le tirage des cartes Mythiques dans le pool global de cartes ordinaires avec le même algorithme linéaire, le système applique un double roll de probabilité indépendant.
   - Si les conditions du tirage de Draft amélioré (Level Up) sont remplies, un roll de probabilité ultra-restreint de `0.5%` est exécuté. Si validé, la carte spéciale (Trèfle ou Miroir) est tirée et injectée dans le flux de présentation Mythique.
   - *Rationale* : Ce double tirage isolé garantit le maintien strict des pourcentages de distribution réguliers (Légendaire `2.0%`, Épique `6%`, Rare `16%`, Atypique `24%`, Commune `51.5%` au Level Up, ou Commune `52%` au Draft de base) sans perturber l'équilibre mathématique global du deckbuilder.

2. **Transition Séquentielle Cinématique en Deux Étapes** :
   - **Étape 1 : Révélation Standard** : Les 3 cartes ordinaires s'affichent et stabilisent séquentiellement via les rouleaux 3D (de 0.8s à 2.0s).
   - **Étape 2 : Alerte Alarme (Laser & Pop-Up)** : Si une carte Mythique est obtenue, le Draft normal se fige. Une animation d'alerte se lance pendant 1400ms : une ligne laser écarlate (`0xFFE53E3E`) balaie horizontalement l'écran de gauche à droite, divisant virtuellement les cartes standard. Simultanément, trois points d'exclamation géants `!!!` apparaissent en animation élastique au centre, accompagnés de doubles ombres rouge et blanc, et clignotent deux fois pour capter l'attention.
   - **Étape 3 : Flou Gaussien et Spin de Premier Plan** : L'arrière-plan subit un flou de `8.0px` via un `BackdropFilter` Flutter. Une bannière rouge clignotante annonce l'alerte. Le rouleau de la carte Mythique spin au premier plan avec une durée de rotation prolongée (`+800ms`) pour accentuer le suspense, une amplitude de secousse doublée (`12.0` vs `6.0` pixels), et des contours d'étincelles rouge-néon (`_SparkPainter` avec configurations `isMythic`).
   - **Étape 4 : Réintégration Synchrone** : Une fois la carte stabilisée sur sa face avant 3D, le système attend 1.5s avant de dissiper progressivement en fondu l'overlay flouté, insérant proprement la carte Mythique dans la rangée du Draft normal pour permettre son choix définitif par l'utilisateur.

### Trade-offs (Compromis Techniques)
- **Temps d'attente supplémentaire** : La transition cinématique allonge la phase de draft de près de 3 secondes lors d'une obtention Mythique. Ce compromis est hautement bénéfique car l'apparition d'une carte Mythique est un événement rarissime (probabilité de `0.5%`), transformant cette attente en une célébration gratifiante.
- **Ressources GPU de Floutage (`BackdropFilter`)** : Flouter dynamiquement l'intégralité du canvas de l'arène de combat consomme des cycles GPU supplémentaires. Cependant, puisque cette opération est isolée à l'écran de récompense et ne s'applique qu'au moment précis du tirage, l'impact sur l'expérience générale de fluidité du jeu (60 FPS) est totalement imperceptible.

### Preuves dans le code
- `probabilities_test.dart` : Tests rééquilibrés à 100% exact validant les probabilités de Draft (Common `52%` standard, et `51.5%` + Mythic `0.5%` au Level Up).
- `DraftScreen` orchestrant le `BackdropFilter` (flou `8.0px`), l'effet laser horizontal 1400ms, et le pop des points d'exclamation `!!!`.
- `DraftCardReel` configuré avec le paramètre `isMythic` (border `4.0`, couleur rouge sang `0xFFE53E3E`, shake amplitude `12.0`, `+800ms` delay).

### Conséquences
- ✅ **Game Feel et Suspension Inégalés** : La dramatisation visuelle de l'obtention d'une carte Mythique crée une forte charge d'adrénaline et de satisfaction pour le joueur.
- ✅ **Robustesse Mathématique** : Le modèle probabiliste rééquilibré est rigoureusement testé et asserté à la frame près dans les tests automatisés (66/66 au vert).
- ✅ **Qualité de Rendu Premium** : Le contraste net entre l'arrière-plan flouté sombre et le premier plan écarlate vibrant met en valeur l'identité graphique d'exception de la rareté Mythique.
- ⚠️ **Rigueur d'Orchestration Visuelle** : L'introduction d'un overlay à fort impact au-dessus des rouleaux standard nécessite des cycles d'animation parfaitement synchronisés pour éviter les chevauchements visuels ou les clics de sélection hâtifs de l'utilisateur pendant le spin. Le bouton de sélection est verrouillé jusqu'à la réintégration complète.
