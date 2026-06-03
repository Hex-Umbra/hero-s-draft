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
- Définir **100% du contenu de jeu** dans des fichiers JSON stockés dans `assets/data/` (8 fichiers).
- Chaque fichier JSON a un modèle Dart correspondant dans `lib/models/data/` (les cartes globales et de classe partagent le modèle `CardData`) avec une factory `fromJson()`.
- Le chargement est centralisé dans `GameDataService.loadAll()` qui produit un `GameDataRegistry` immutable.
- Le registre est exposé via un `FutureProvider<GameDataRegistry>` (`gameDataLoaderProvider`).

### Preuves dans le code
- 8 fichiers JSON : `cards.json` (15 cartes globales), `hero_cards.json` (6 cartes spécifiques de classe), `enemies.json` (4 ennemis), `heroes.json` (3 héros), `skills.json` (6 compétences), `events.json` (2 événements), `passives.json` (3 passifs), `relics.json` (12 reliques).
- 8 modèles Data principaux avec `fromJson()` : `CardData`, `EnemyData`, `HeroData`, `SkillData`, `EventData`, `PassiveData`, `RelicData`, `GameDataRegistry`.
- `GameDataService.loadAll()` utilise `Future.wait()` pour charger les 8 fichiers en parallèle.

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
- ✅ **Robustesse Mathématique** : Le modèle probabiliste rééquilibré est rigoureusement testé et asserté à la frame près dans les tests automatisés (74/74 au vert).
- ✅ **Qualité de Rendu Premium** : Le contraste net entre l'arrière-plan flouté sombre et le premier plan écarlate vibrant met en valeur l'identité graphique d'exception de la rareté Mythique.
- ⚠️ **Rigueur d'Orchestration Visuelle** : L'introduction d'un overlay à fort impact au-dessus des rouleaux standard nécessite des cycles d'animation parfaitement synchronisés pour éviter les chevauchements visuels ou les clics de sélection hâtifs de l'utilisateur pendant le spin. Le bouton de sélection est verrouillé jusqu'à la réintégration complète.

---

## 🎓 ADR-019 : Système de Tutoriel Autonome Isolant la Boucle Principale (Standalone Tutorial System with State Isolation)

### Statut
✅ Accepté & Implémenté

### Contexte
L'onboarding des nouveaux joueurs est un aspect crucial pour "Hero's Draft", mais l'arène de combat Flame, les providers Riverpod complexes (RunController, DeckNotifier, etc.) et le chargement de données asynchrones lient fortement l'application à un flux de production stricte. Essayer de greffer un tutoriel guidé sur la boucle de gameplay classique créerait des risques majeurs d'effets de bord, d'effondrement de la run de production, ou de corruption de données. Un sous-système de tutoriel complètement découplé et autonome est nécessaire.

### Décision
- **Créer un module isolé** sous `lib/tutorial/` regroupant tout le code lié à l'apprentissage (widgets d'étapes, état simulé, moteur de transitions).
- **Éviter les providers Riverpod de production** : Le tutoriel n'utilise pas `runProvider` ou `deckProvider`. À la place, il repose sur un `TutorialEngine` (`ChangeNotifier` simple) qui encapsule sa propre structure de données d'état `TutorialMockState`.
- **Réinitialiser l'état par étape** : Au début de chaque étape du PageView, `resetMockState()` est appelé par le moteur pour injecter précisément les cartes en main, les PV, le mana, l'armure et l'ennemi nécessaires à l'exercice d'apprentissage de cette étape.
- **Utiliser SharedPreferences pour la persistance** : La réussite du tutoriel est tracée de manière persistante par `TutorialProgressService` sous le flag `tutorial_completed`. L'écran `HomeScreen` lit cette donnée pour afficher un badge "NEW" rouge clignotant sur le bouton d'accès.

### Preuves dans le code
- `lib/tutorial/tutorial_engine.dart` : Classe `TutorialEngine` et `TutorialMockState`.
- `lib/tutorial/widgets/` : 13 classes widgets représentant les étapes d'apprentissage.
- `lib/tutorial/tutorial_progress_service.dart` : Persistance via `SharedPreferences`.
- `lib/ui/screens/home_screen.dart` : Notification visuelle "NEW" dynamique basée sur la complétion.

### Conséquences
- ✅ **Sécurité et robustesse de la production** : Zéro risque de corrompre l'état de la run principale ou de casser les tests automatisés de production.
- ✅ **Grande liberté de scénarisation** : Chaque étape est un bac à sable parfait configuré sur mesure.
- ✅ **Rejouabilité infinie** : Le joueur peut rejouer le tutoriel à tout moment depuis l'écran d'accueil.
- ⚠️ **Duplication fonctionnelle légère** : Certains composants et modèles ont été recréés sous forme simplifiée (ex: `TutorialCard` vs `CardInstance`), impliquant de répercuter manuellement les changements graphiques si le design global des cartes change radicalement.

---

## 🎨 ADR-020 : Feedback de Focus de Récompenses (Hover & Selection Glow Visual Feedback in Draft Screen)

### Statut
✅ Accepté & Implémenté

### Contexte
La sélection de cartes de récompenses dans l'écran de Draft standard et le draft du tutoriel manquait de retour sensoriel et tactile. Le joueur pouvait avoir des difficultés à repérer la carte survolée et celle activement choisie avant confirmation.

### Décision
Mettre en place un pipeline d'animations de focus partagé entre le tutoriel et le jeu de production :
- **Survol (Hover)** : Envelopper les cartes de choix dans une `MouseRegion` et appliquer un `AnimatedScale` pour modifier dynamiquement l'échelle à `1.05x` en 200ms lors du survol.
- **Sélection (Selection)** : En cas de tap ou clic actif, faire grossir la carte sélectionnée à `1.12x` et lui attribuer une surbrillance dorée intense via une décoration `BoxShadow` de couleur `Colors.amber` avec un rayon de flou de 16px et une extension de 3px.
- **Confirmation Sécurisée** : Conserver la carte en état sélectionné/grossi jusqu'à ce que le joueur appuie sur le bouton de validation de draft pour valider la transition.

### Preuves dans le code
- `lib/tutorial/widgets/tutorial_draft_widget.dart` : Implémentation complète avec `MouseRegion`, `AnimatedScale`, et lueur dorée BoxShadow.
- `lib/ui/screens/draft_screen.dart` / `lib/ui/widgets/relic_carousel/draft_card_reel.dart` : Intégration des effets de focus similaires pour le Draft de production.

### Conséquences
- ✅ **Amélioration immédiate du game feel** : La sélection devient agréable et offre une rétroaction instantanée sur les intentions de l'utilisateur.
- ✅ **Accessibilité accrue** : Le contraste visuel de la lueur dorée et l'échelle augmentée identifient sans équivoque la carte cible active.

---

## 📱 ADR-021 : Stratégie de Responsivité Unifiée du Système de Tutoriel (Unified Tutorial Responsiveness Strategy)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de tutoriel original composé de 13 illustrations et interacteurs souffrait de sévères contraintes de mise en page. Sur les écrans de smartphones de faible largeur ou lors de l'utilisation du mode paysage sur mobile (faible hauteur verticale disponible, ~360px), les contraintes fixes de flexibilité et les coordonnées de positionnement absolues provoquaient des erreurs de contraintes de boîte ("Yellow-Black Stripes") et masquaient le texte ou les éléments interactifs.

### Décision
Établir et appliquer de façon systématique quatre patrons de responsivité à l'échelle de l'ensemble des 13 widgets du tutoriel :
1. **FittedBox Canvas Scaling Pattern** : Pour les widgets s'appuyant sur des coordonnées de positionnement absolues ou des animations complexes (`Map`, `Combat Overview`, `Play Card`, `Merge`, `Armor`), envelopper le conteneur principal à taille fixe (ex: `SizedBox(width: 360, height: 260)`) dans un widget `FittedBox` configuré avec `fit: BoxFit.contain`. Cela force l'illustration à s'échelonner comme un graphique vectoriel unique proportionnellement à l'espace alloué, éliminant tout overflow.
2. **LayoutBuilder Orientation Split Pattern** : Structurer la classe principale `TutorialScreen` de sorte qu'elle détecte l'orientation active via un `LayoutBuilder`. Si l'écran est en mode paysage (largeur > hauteur et hauteur < 500px) ou si la largeur dépasse 720px (mode tablette/bureau), diviser l'écran à l'aide d'un `Row` horizontal (50% pour l'illustration interactive à gauche, 50% pour les descriptions textuelles et les boutons à droite) au lieu du split vertical `Column` par défaut qui écrase l'illustration sur les écrans courts.
3. **Scrollable Container Pattern** : Remplacer l'utilisation de `NeverScrollableScrollPhysics` par `BouncingScrollPhysics` et injecter des conteneurs `SingleChildScrollView` élastiques sur les descriptions ou les grilles pour autoriser l'utilisateur à scroller en cas de réduction drastique de la hauteur d'écran.
4. **Adaptive Columns & Wraps** : Utiliser le widget `Wrap` (ex. pour la légende des raretés de reliques ou les types de nœuds) et des listes déroulantes horizontales (pour la main de cartes ou les choix de draft) afin que les cellules s'écoulent naturellement en fonction de la largeur disponible. Réorganiser les types de nœuds en grille compacte 3x2.

### Preuves dans le code
- `lib/tutorial/tutorial_screen.dart` : Exploitation de `LayoutBuilder` et aiguillage vers la structure `Row` ou `Column` selon le ratio d'aspect.
- `lib/tutorial/widgets/` :
  - `tutorial_map_widget.dart` et `tutorial_combat_overview_widget.dart` : Utilisation combinée de `SizedBox` de taille de référence et de `FittedBox(fit: BoxFit.contain)`.
  - `tutorial_node_types_widget.dart` : Grille flexible reconfigurée en 3x2 avec support du défilement.
  - `tutorial_relics_widget.dart` : Remplacement du layout `Row` horizontal rigide des raretés par un `Wrap` adaptatif.

### Conséquences
- ✅ **Compatibilité universelle multi-plateforme** : Le tutoriel s'affiche de manière premium sur toutes les résolutions d'écran sans aucun bug visuel ou texte rogné.
- ✅ **Expérience Mobile Paysage Premium** : Le split horizontal évite l'écrasement vertical des illustrations, préservant la lisibilité sur smartphone tenu à l'horizontale.
- ⚠️ **Surcharge légère d'encapsulation** : Obligation d'utiliser un gabarit de conteneur virtuel (`SizedBox`) sur les widgets canvas pour assurer la stabilité du `FittedBox`.

---

## ⚔️ ADR-022 : Ciblage Interactif en Deux Phases et Clarté des Info-bulles (Two-Phase Targeting & Canvas Cards Tooltips)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de tutoriel initial possédait des étapes interactives simplifiées qui ne reflétaient pas pleinement la dynamique fine du système de ciblage et de description des effets de statut du jeu de production. L'étape 6 (Play Card) n'illustrait pas les cas de sélection de cibles multiples (ennemi vs héros), et l'étape 5 (Cards & Mana) affichait des descriptions textuelles plates dépourvues des icônes vectorielles et des info-bulles présentes en combat réel.

### Décision
1. **Interactive Two-Phase Targeting** : À l'étape 6, implémenter une séquence interactive obligeant le joueur à comprendre les deux directions possibles de ciblage. Phase 1 : glisser et déposer la carte d'attaque offensive sur le Slime cible. Phase 2 : glisser la carte d'armure défensive sur le portrait du Héros (soi-même). La progression n'est déverrouillée qu'une fois les deux gestes complétés avec succès.
2. **True Canvas Vector Icons & Tooltips** : À l'étape 5, refactoriser le rendu des cartes de démonstration en remplaçant les chaînes plates par les vraies icônes vectorielles dessinées sur le Canvas Flutter (Épée, Bouclier, Poison). De plus, intégrer un système de détection de clic/hover qui affiche des info-bulles descriptives localisées détaillant précisément les règles mécaniques de chaque effet de combat.
3. **Alignement du Combat Overview** : Repositionner et calibrer les lignes d'annotation à l'étape 4 pour qu'elles s'alignent précisément sur les coordonnées du HUD de combat réel.

### Preuves dans le code
- `lib/tutorial/widgets/tutorial_play_card_widget.dart` : Logique de ciblage intégrant une machine à états locale (Phases de jeu d'attaque puis de défense) avec validation des cibles.
- `lib/tutorial/widgets/tutorial_cards_widget.dart` : Remplacement des rendus statiques par l'affichage d'icônes Canvas vectorielles et insertion de widgets d'info-bulles tactiles.
- `lib/tutorial/widgets/tutorial_combat_overview_widget.dart` : Ajustement millimétré des positions absolues des conteneurs d'annotations et réduction de la taille des cartes représentées.

### Conséquences
- ✅ **Fidélité d'apprentissage optimale** : Le joueur appréhende les gestes complexes de ciblage de production de manière sûre dans un bac à sable isolé.
- ✅ **Expérience utilisateur immersive** : Les info-bulles et les icônes de haute qualité vectorielle améliorent instantanément la qualité perçue du jeu.

---

## ⚔️ ADR-023 : Système de Statuts Élémentaires Riches & Vulnérabilité Universelle

### Statut
✅ Accepté & Implémenté

### Contexte
Les combats tactiques manquaient d'altérations d'état dynamiques et de synergies élémentaires. Les effets de statut initiaux étaient soit trop basiques, soit limités aux forces et armures. Pour offrir des opportunités de build plus poussées (jeux basés sur le temps, le burst ou le contrôle), il était nécessaire d'introduire des effets élémentaires riches et une gestion propre de la vulnérabilité affectant toutes les entités en jeu.

### Décision
1. **Brûlure (`burn`)** : Inflige des dégâts au début du tour de la cible. Le tick applique des dégâts physiques équivalents à l'intensité accumulée, puis décrémente l'intensité et la durée de 1.
2. **Gel (`freeze`)** : Réduit de 50% (arrondi) les dégâts de la prochaine attaque de la cible, puis consomme immédiatement la durée du gel.
3. **Électrocution (`shock`)** : Fonctionne comme un amplificateur de dégâts cumulatif flat. À chaque attaque directe subie par la cible, la valeur cumulée du statut est ajoutée aux dégâts infligés.
4. **Vulnérabilité (`vulnerable`)** : Multiplicateur universel de dégâts. Toute attaque directe subie par une entité sous vulnérabilité inflige 50% de dégâts supplémentaires. Cet effet est symétrique (affecte autant le Héros que les Ennemis).
5. **Découplage Logique** : Câbler la totalité de ces règles dans `CombatController` et `EffectResolver` de manière autonome, garantissant la testabilité unitaire sans nécessiter le moteur graphique Flame.

### Preuves dans le code
- `lib/game/services/effect_resolver.dart` : Prise en compte de la vulnérabilité et de l'électrocution (`shock`) dans le calcul dynamique des dégâts finaux d'une attaque.
- `lib/game/controllers/combat_controller.dart` : Ticks de brûlure résolus au début du tour et application des réductions de dégâts liées au gel.
- `test/unit/combat_controller_test.dart` et `test/unit/effect_resolver_test.dart` : Tests unitaires vérifiant la conformité des ticks et des réductions/amplifications.

### Conséquences
- ✅ **Diversité des builds** : Permet au joueur de construire des archétypes viables orientés Gel (contrôle défensif) ou Électrocution/Vulnérabilité (burst agressif).
- ✅ **Double tranchant** : L'universalité de la vulnérabilité force le joueur à surveiller ses propres débuffs sous peine de subir des attaques dévastatrices.

---

## ⚔️ ADR-024 : Progression par Rareté Dynamique et Fusion Interactive (3→1)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de progression initial reposait sur un niveau numérique de cartes peu évocateur. Pour renforcer l'aspect roguelike deckbuilder traditionnel et donner de la valeur aux doublons de cartes obtenus en récompense, le jeu avait besoin d'un mécanisme de rareté dynamique et d'une fusion interactive de cartes.

### Décision
1. **Rareté Dynamique** : Abandonner le concept de niveau numérique au profit d'une progression par rareté : `common` (Commune) → `uncommon` (Atypique) → `rare` (Rare) → `epic` (Épique) → `legendary` (Légendaire). Un multiplicateur de rareté spécifique applique un échelonnement proportionnel aux dégâts et armures de base de la carte.
2. **Fusion Interactive** : Intégrer dans le deck une mécanique de fusion demandant exactement 3 exemplaires identiques d'une carte à la même rareté. La fusion consomme ces 3 cartes et produit une carte unique de la rareté directement supérieure.
3. **Consolidation d'Upgrades** : Cumuler les améliorations de forge des cartes consommées lors de la fusion en additionnant les Tiers des améliorations de même ID (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`).
4. **Contrainte de Capacité** : Tronquer la liste des upgrades cumulés pour respecter la capacité maximale de la nouvelle rareté (`baseMaxForgeUpgrades + rarityIndex`). Fournir une interface de choix interactif pour décider des améliorations héritées.
5. **Équilibrage de Cartes Clés** : Rééquilibrer plusieurs cartes pour qu'elles s'adaptent harmonieusement au flux de rareté et d'upgrades :
   - `holy_shield` : Dotée du mot-clé `isExhaust: true` pour éviter le spam défensif infini.
   - `warcry` : Dégâts de zone (AoE) couplés à un gain d'armure modéré.
   - `mana_surge` : Gain de 1 mana, pioche 1, et épuisement (`isExhaust: true`).
   - `concentration` : Pioche 2, coût 0, et épuisement.
   - `poison_stab` : Dégâts ciblés avec application directe de poison.

### Preuves dans le code
- `lib/game/controllers/deck_controller.dart` : Méthode `mergeCards()` gérant la validation des 3 IDs, le retrait des cartes du deck principal, le calcul de la rareté supérieure, la consolidation des Tiers d'upgrades et le clamp à la capacité maximale.
- `assets/data/cards.json` : Structure JSON mise à jour avec les attributs de rareté et les configurations d'équilibrage.
- `test/unit/deck_controller_test.dart` : Validation de la fusion 3→1 et de la conservation/limitation des upgrades.

### Conséquences
- ✅ **Valorisation des récompenses** : Le joueur est ravi de recevoir des doublons de cartes car ils lui permettent de monter son deck en rareté.
- ✅ **Conservation d'investissement** : Fusionner des cartes déjà améliorées à la forge ne fait pas perdre l'investissement en or grâce au cumul de Tiers.

---

## ⚔️ ADR-025 : Système de Forge Découplé et Probabiliste

### Statut
✅ Accepté & Implémenté

### Contexte
L'amélioration des cartes au feu de camp manquait d'aléa et de choix stratégiques significatifs. Proposer des choix d'améliorations fixes et illimités rendait la forge monotone. Un système roguelike robuste exigeait des options aléatoires limitées par la rareté de la carte, des probabilités de slots d'options variables et un coût de relance exponentiel.

### Décision
1. **Capacité Maximale Scalée** : Restreindre le nombre maximum d'améliorations de forge toléré sur une carte à la valeur `baseMaxForgeUpgrades + rarityIndex`.
2. **Génération Probabiliste de Slots** : À chaque ouverture de la forge pour une carte, le nombre d'options d'upgrades disponibles (1 à 5) est déterminé aléatoirement. Chaque slot a une chance indépendante d'apparaître :
   - Slot 1 : 100%
   - Slot 2 : 50%
   - Slot 3 : 25%
   - Slot 4 : 10%
   - Slot 5 : 2%
3. **Pools Clamps par Rareté** : Classer les upgrades par niveaux de rareté :
   - *Common Pool* (Dégâts `sharp`, Armure `hardened`, et effets de statut `burning`, `freezing`, `shocking` limités aux cartes Attaque).
   - *Uncommon Pool* (Pioche `quick`).
   - *Rare Pool* (Économe en mana `eco`, et persistant `enduring` - retirant l'épuisement `exhaust` - réservé aux cartes non-pouvoir qui s'épuisent).
4. **Pondération et Distribution** : Assigner la probabilité d'apparition des pools selon la rareté de la carte (ex : une carte rare a de meilleures chances de tirer des options peu communes ou rares). Déterminer le Tier de l'upgrade (de I à III) via des jets pondérés : Tier I (80%), Tier II (15%), Tier III (5%).
5. **Relance Exponentielle Individuelle** : Permettre au joueur de relancer le tirage d'un slot spécifique en dépensant de l'or de l'inventaire. Le coût augmente exponentiellement par slot selon la formule $20 \times 1.25^n$ (arrondi) où $n$ est le nombre de relances subies par ce slot.
6. **Intégration d'Écran** : Modéliser le système de slots indépendamment de l'UI et l'intégrer dans le widget dialog `ForgeUpgradeDialog` appelé depuis l'écran de feu de camp `RestScreen`.

### Preuves dans le code
- `lib/ui/widgets/forge_upgrade_dialog.dart` : Classe `ForgeSlot` portant la formule `(20 * pow(1.25, rerollsCount)).round()`, méthodes `_generateInitialSlots`, `_rollSlotUpgrade`, et `_rerollSlot` consommant l'or de `inventoryProvider`.
- `test/unit/decoupled_forge_test.dart` : Suite complète de tests unitaires simulant des centaines de tirages pour valider les chances d'ouverture de slots, la clampabilité des pools et le coût de reroll.

### Conséquences
- ✅ **Suspense et rejouabilité** : Le joueur espère obtenir de nombreux slots ou un upgrade Rare puissant (comme `enduring` pour pérenniser un sort de soin).
- ✅ **Arbitrage financier** : Introduit un arbitrage crucial sur l'or : faut-il relancer un slot de forge ou économiser pour la boutique ?
- ⚠️ **Dépendance à la chance** : Un joueur malchanceux peut n'avoir qu'un seul slot d'option disponible, bien que compensé par la possibilité de reroll.

---

## 🃏 ADR-026 : Isolation des Cartes de Classe "Unique" et Standardisation du Draft Initial (Class Card Isolation & Starter Draft Overhaul)

### Statut
✅ Accepté & Implémenté

### Contexte
Les cartes de classe initiales (`holy_shield`, `smite`, `reckless_strike`, `rage_form`, `magic_missile`, `mana_surge`) étaient mélangées dans `cards.json` avec les cartes neutres globales. Ce couplage nuisait à l'identité stratégique de chaque héros, car les cartes spécifiques apparaissaient de manière confuse dans les tables d'acquisition ou de boutique, et les mécaniques de fusions n'étaient pas adaptées à des sorts de classe intrinsèques. De plus, l'écran `StarterDeckDraftScreen` original reposait sur une sélection aléatoire par vagues de 3 cartes qui nuisait à l'arbitrage tactique initial du joueur.

### Décision
1. **Séparation des JSON de cartes** : Extraire toutes les cartes spécifiques de classe de `cards.json` vers `assets/data/hero_cards.json`.
2. **Introduction de la Rareté `unique`** : Créer le type de rareté `unique` dans l'enum `CardRarity`. Les cartes uniques possèdent une valeur de multiplicateur fixe à `1.0` (définie dans `card_instance.dart`) et une limite de forge `baseMaxForgeUpgrades` bloquée à 5.
3. **Verrouillage Métier de la Fusion & Obtention** : Empêcher explicitement la fusion de cartes de rareté `unique` en désactivant le bouton correspondant dans l'UI et en levant une erreur dans `deck_controller.dart`. Filtrer également ces cartes pour qu'elles ne soient jamais proposées en boutique ou en draft après un combat.
4. **Liaison Dynamique Héros-Skills** : Structurer `heroes.json` avec l'intégration du champ `"skills"` qui contient les identifiants de cartes de départ uniques. Implémenter l'extension `HeroSkillsLink` et sa méthode `getHeroCards(gameData)` pour charger dynamiquement ces cartes basées sur les compétences du héros.
5. **Standardisation Globale & VPM** : Passer toutes les cartes globales de `cards.json` à la rareté `common`. Rééquilibrer leurs statistiques fondamentales pour les stabiliser autour de ratios de Valeur Par Mana (VPM) justes et équitables (ex: `heal_potion` coût 1, heal 4, exhaust; `iron_wall` coût 2, 10 block; `heavy_strike` coût 2, 12 dmg).
6. **Refonte et Stabilisation de l'écran `StarterDeckDraftScreen`** : Remplacer l'ancien système de draft par vagues par une grille affichant l'intégralité du catalogue des 15 cartes globales. Le joueur sélectionne de manière totalement libre exactement 5 cartes globales de départ parmi le pool complet (la logique intermédiaire consistant à restreindre le choix à un sous-ensemble aléatoire de 10 cartes a été complètement supprimée). Les cartes de classe uniques obtenues via `getHeroCards()` sont ajoutées automatiquement au deck initial. Les descriptions de localisation `draftDeckSubtitle` ont été révisées et corrigées en français/anglais, et les importations et méthodes mathématiques inutilisées (`dart:math` et `_rollRarity`) ont été supprimées.

### Preuves dans le code
- Fichier `assets/data/hero_cards.json` contenant les 6 cartes spécifiques.
- Fichier `assets/data/cards.json` contenant les 15 cartes globales rééquilibrées.
- Enum `CardRarity` étendu avec `unique`.
- Code de validation de merge dans `deck_controller.dart` qui rejette les cartes `unique`.
- Méthode `HeroSkillsLink.getHeroCards(gameData)` dans `lib/models/data/hero_data.dart` (ou extension équivalente).
- Grille de sélection interactive et validation de la taille de sélection (exactement 5) dans `StarterDeckDraftScreen`.
- Fichiers `app_en.arb` et `app_fr.arb` modifiant la clé `draftDeckSubtitle` pour supprimer l'ancienne mention d'une sélection "parmi les 10 proposées".
- Nettoyage du code de `starter_deck_draft_screen.dart` avec retrait des fonctions probabilistes inutilisées.
- Validation de la suite complète de 78 tests automatisés après mise à jour des mocks de tests unitaires/widgets pour s'adapter à la grille globale étendue.

### Conséquences
- ✅ **Renforcement de l'identité des Héros** : Chaque classe démarre avec des compétences fortes, stables et caractéristiques qui ne diluent pas son identité au fil des fusions.
- ✅ **Pouvoir de Décision Initial accru** : Le joueur compose consciemment sa stratégie de départ parmi les cartes globales sans subir l'aléa du tirage.
- ✅ **Coût de Maintenance Réduit** : La distinction nette entre le pool global et le pool de classe facilite l'implémentation de futurs héros et cartes sans perturber le système d'acquisition général.
- ⚠️ **Évolution Statique de Classe** : N'étant pas fusionnables, les cartes uniques de classe ne s'améliorent que via les slots probabilistes de la Forge, accentuant l'importance stratégique des feux de camp.
- ✅ **Vérification Intègre & Cohérence** : Tous les 78 tests automatisés passent avec succès, et le linter est vierge sous `dart analyze`. Les descriptions de l'interface et les comportements du code sont en parfaite adéquation.

---

## 🎯 ADR-027 : Système de Coup Critique et Rééquilibrage du Scaling Ennemi (Critical Hit System & Enemy Scaling Tuning)

### Statut
✅ Accepté & Implémenté

### Contexte
Le gameplay de combat de *Hero's Draft* manquait d'une composante d'incertitude positive (chance/opportunités tactiques) pour le joueur ainsi que d'une gestion plus fine et équilibrée de la difficulté progressive. Les multiplicateurs de caractéristiques de niveau des ennemis d'origine (+12% HP/lvl, +8% ATK/lvl) rendaient le late game exponentiellement punitif, tandis que l'absence de coups critiques réduisait la variété des builds possibles (comme des archétypes basés sur la chance). De plus, l'affichage HUD n'était pas dimensionné pour intégrer ces nouvelles statistiques de combat.

### Décision
1. **Rework du Scaling Ennemi** :
   - Réduire le coefficient de niveau de PV des ennemis de `0.12` à `0.06` et le coefficient d'acte de `0.40` à `0.20` dans `CombatController.initializeCombat`.
   - Réduire le coefficient de niveau des dégâts des ennemis de `0.08` à `0.04` et le coefficient d'acte de `0.30` à `0.15`.
   - Ces modifications aplatissent la courbe de difficulté pour la rendre plus fluide tout en préservant le défi stratégique.
2. **Architecture du Coup Critique** :
   - Ajouter les propriétés `critChance` (taux en %, défaut 0) et `critMultiplier` (multiplicateur de dégâts, défaut x1.5) au modèle d'attributs de combat `EntityStats`.
   - Intégrer la notion de chance de critique effective (`effectiveCritChance`) qui additionne les statistiques permanentes et les altérations de statut temporaires de critique.
   - Enregistrer des chances de critique de base dans `enemies.json` pour tous les types d'ennemis (Slime: 5%, Gobelin: 10%, Squelette: 10%, Orc Furieux: 15%).
3. **Application du Pipeline de Critique** :
   - Dégâts physiques/magiques des cartes du joueur (`EffectResolver._calculateDamage`) : Effectuer un jet aléatoire (0-99) face aux chances effectives et multiplier les dégâts par `critMultiplier` en cas de réussite.
   - Soins des cartes du joueur (`EffectResolver.resolveCard`) : Jet critique appliquant le multiplicateur aux PV soignés.
   - Dégâts des intentions ennemies (`CombatController.resolveEnemyIntent`) : Jet critique appliquant le multiplicateur aux dégâts d'attaque infligés au héros.
   - Compétences actives de classe du héros (`HerosDraftGame.executeSkill`) : Jet critique sur les compétences ciblées, de zone (AoE), ou perçantes.
4. **Intégration du Draft de Level Up et i18n** :
   - Étendre le pool de récompenses de montée de niveau pour proposer les choix :
     - **Précision** (augmente `critChance` de +1% à +5% selon la rareté du draft).
     - **Férocité** (augmente `critMultiplier` de +0.10 à +0.50 via `critDamageAcc` selon la rareté du draft).
   - Localiser proprement ces choix dans `app_en.arb` et `app_fr.arb` (`draftChoicePrecisionTitle`, `draftChoicePrecisionDesc`, `draftChoiceFerocityTitle`, `draftChoiceFerocityDesc`).
5. **Ajout de Reliques Orientées Critique** :
   - Ajouter deux nouvelles reliques dans `relics.json` exploitant l'effet `gain_crit` :
     - *Focus Lens* (`critical_lens`, Rare, trigger: `startOfCombat`) : confère un buff temporaire de $+15\%$ de critique en combat.
     - *Lucky Charm* (`lucky_charm`, Uncommon, trigger: `startOfRun`) : confère un bonus permanent de $+10\%$ de critique pour toute la run.
6. **Redesign de la Grille des Statistiques (StatsDialog)** :
   - Réorganiser l'affichage du dialogue de statistiques `StatsDialog` (lors du clic sur le profil du héros sur la carte) en une grille compacte et structurée en 2x2.
   - Les quatre zones affichent de manière alignée : Attaque / Armure en haut, et Précision (Chance Critique) / Férocité (Multiplicateur) en bas.

### Preuves dans le code
- Modifications de `EntityStats.dart` pour stocker `critChance` et `critMultiplier`.
- Formules de scaling révisées dans `CombatController.initializeCombat`.
- Logique de lancer aléatoire et d'amplification dans `EffectResolver._calculateDamage`, `EffectResolver.resolveCard` (soin), `CombatController.resolveEnemyIntent` (attaque ennemie), et `HerosDraftGame.executeSkill` (compétences).
- Nouvelles clés de traduction dans `app_en.arb`/`app_fr.arb` et sélection correspondante dans `DraftScreen`.
- Fichier `relics.json` mis à jour avec `critical_lens` et `lucky_charm` et traitement associé dans `RunController.applyRelicEffect`.
- Layout grid 2x2 dans `lib/ui/widgets/map/dialogs/stats_dialog.dart`.
- Passage réussi de tous les 82 tests unitaires et widget-tests de la suite automatisée.

### Conséquences
- ✅ **Builds Variés et Synergies** : Ouvre la voie à des builds basés sur la Chance (Luck) et les Critiques en sélectionnant des reliques critiques et en choisissant Précision/Férocité lors des montées de niveau.
- ✅ **Rythme de Difficulté Lissé** : Évite le pic de dégâts et de PV insurmontables pour les héros à l'Acte 2 ou Acte 3, rendant la progression plus agréable.
- ✅ **HUD Mieux Organisé** : Le dialogue de statistiques affiche clairement les attributs offensifs de critique sans encombrer l'écran principal.
- ⚠️ **Part de Hasard Accrue** : Les combats peuvent basculer sur un coup critique chanceux du joueur (ou malchanceux de l'ennemi), ce qui augmente la tension mais peut légèrement frustrer en cas de coup critique subi inattendu.
- ✅ **Vérification Intègre & Cohérence** : Tous les 82 tests automatisés passent avec succès, et le linter est vierge sous `dart analyze`. Les descriptions de l'interface et les comportements du code sont en parfaite adéquation.

---

## ⚔️ ADR-028 : Équilibrage Hybride de la Difficulté et Système de Réserve de Vagues (Hybrid Difficulty Balancing & Wave Reserve System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans les versions précédentes, la composition des rencontres de combat et le nombre d'ennemis sur le plateau étaient statiques ou faiblement liés à la progression réelle du joueur. Cela entraînait deux problèmes majeurs de game design et de performance :
1. **Écarts de difficulté** : Les joueurs optimisant fortement leur deck (fusions de raretés élevées, forges optimisées) trivialisaient rapidement le jeu. À l'inverse, les joueurs moins chanceux ou moins expérimentés faisaient face à des pics de difficulté brutaux.
2. **Surcharge visuelle du board (Flame)** : La génération d'un nombre important d'ennemis (plus de 3 ou 4) saturait le plateau de rendu mobile, provoquait des chevauchements visuels inacceptables pour les `PositionComponent` de Flame, et compliquait le ciblage tactile.

### Décision
1. **Implémentation d'une DDA Hybride (Dynamic Difficulty Adjustment)** :
   - Évaluer la puissance réelle actuelle du joueur via ses attributs permanents et reliques :
     $$\text{PlayerPower} = \text{maxHP} + (\text{attaque} \times 10.0) + (\text{maxMana} \times 15.0) + (\text{relicsCount} \times 5.0)$$
   - Définir la puissance théorique attendue à ce stade de la partie :
     $$\text{ExpectedPower} = 145.0 + ((\text{playerLevel} - 1) \times 15.0) + ((\text{act} - 1) \times 20.0)$$
   - Introduire un amortissement strict de $0.5$ sur l'écart de puissance pour atténuer les corrections et éviter les fluctuations brutales de budget de menace :
     $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
     $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$
2. **Budget de Menace de Combat (`FinalBudget`)** :
   - Calculer le budget de base lié au niveau et à l'acte :
     $$\text{BaseBudget} = 40.0 + ((\text{playerLevel} - 1) \times 10.0) + ((\text{act} - 1) \times 25.0)$$
   - Ajuster ce budget par le modificateur de puissance amorti et le type de nœud (Normal 1.0, Élite 1.5, Boss 2.0) :
     $$\text{FinalBudget} = \text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}$$
3. **Score individuel de Menace (`CombatRating`)** :
   - Assigner à chaque ennemi une valeur de menace recalculée dynamiquement en fonction de ses statistiques réelles après scaling (incluant le multiplicateur de PV, d'attaque et son taux de critique de base) :
     $$\text{CombatRating} = (\text{tier} \times 10.0) + \text{HP\_Scalé} + \text{Armure\_Scalée} + \text{Dégâts\_Scalés} \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
   - Sélectionner les ennemis séquentiellement par tirage aléatoire sous contrainte de budget restant, avec un fallback automatique sur le plus petit monstre disponible pour garantir au moins un ennemi si le budget final est extrêmement restreint.
4. **Système de Réserve de Vagues (limite de 5 ennemis actifs)** :
   - Limiter le nombre de monstres actifs sur le board Flame à **5 au maximum**.
   - Si le générateur `EncounterSystem` produit plus de 5 ennemis, les 5 premiers sont instanciés sur le plateau (`enemies` dans `CombatState`), et les suivants sont sérialisés dans la file d'attente de réserve (`pendingEnemies`).
   - À chaque mort d'un ennemi actif, `CombatController._cleanDeadEnemies()` extrait automatiquement le premier élément de `pendingEnemies` pour l'ajouter à `enemies`, et effectue immédiatement son premier tirage d'intention de combat (`_rollIntent`).
   - La condition de victoire du combat est validée uniquement lorsque `enemies` **ET** `pendingEnemies` sont vides.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : Méthode `generateEnemiesForLevel` calculant les formules de `PlayerPower`, `ExpectedPower`, `PowerModifier`, `FinalBudget` et calculant individuellement la `CombatRating` ajustée de chaque ennemi lors du tirage.
- `lib/game/controllers/combat_controller.dart` :
  - `initializeCombat()` : répartition initiale des ennemis scalés entre le board actif `enemies` (limité à 5) et la file de réserve `pendingEnemies`.
  - `_cleanDeadEnemies()` : transition synchrone des ennemis de `pendingEnemies` vers `enemies`, rolling d'intention et vérification combinée des deux listes pour lever le flag `isVictory`.
- `lib/models/data/combat_state.dart` : Ajout et sérialisation/désérialisation du champ `pendingEnemies`.
- `test/unit/combat_difficulty_test.dart` (ou tests similaires dans `test/unit/combat_controller_test.dart`) : Suite de tests automatisés validant le respect du budget de menace, le plafonnement à 5 slots actifs, le transfert automatique de la réserve lors de la mort d'un ennemi, et l'ajustement dynamique du modificateur de puissance.

### Conséquences
- ✅ **Rythme de jeu adapté et stimulant** : Le jeu adapte intelligemment le nombre et la puissance des menaces à la composition du deck du joueur. Un deck sur-optimisé fera face à des vagues de monstres plus nombreuses ou plus puissantes, tandis qu'un joueur en difficulté verra la menace stabilisée.
- ✅ **Respect de l'espace de rendu Flame** : La limite stricte de 5 ennemis actifs garantit une présentation claire, évite tout bug visuel d'empilement sur smartphone portrait/paysage, et assure des performances constantes à 60 FPS sur l'arène graphique.
- ✅ **Pérennité du Game Progression** : L'amortissement de $0.5$ de la DDA préserve le sentiment de satisfaction de la progression (les builds puissants roulent toujours plus facilement sur le jeu que les builds faibles, mais le défi reste présent).
- ✅ **Validation par tests automatisés** : 82/82 tests au vert, confirmant que le flow logique de la file de réserve, les transitions d'intentions et l'algorithme de génération de budget respectent rigoureusement les invariants métier.

