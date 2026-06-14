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
- Passage réussi de tous les 100 tests unitaires et widget-tests de la suite automatisée.

### Conséquences
- ✅ **Builds Variés et Synergies** : Ouvre la voie à des builds basés sur la Chance (Luck) et les Critiques en sélectionnant des reliques critiques et en choisissant Précision/Férocité lors des montées de niveau.
- ✅ **Rythme de Difficulté Lissé** : Évite le pic de dégâts et de PV insurmontables pour les héros à l'Acte 2 ou Acte 3, rendant la progression plus agréable.
- ✅ **HUD Mieux Organisé** : Le dialogue de statistiques affiche clairement les attributs offensifs de critique sans encombrer l'écran principal.
- ⚠️ **Part de Hasard Accrue** : Les combats peuvent basculer sur un coup critique chanceux du joueur (ou malchanceux de l'ennemi), ce qui augmente la tension mais peut légèrement frustrer en cas de coup critique subi inattendu.
- ✅ **Vérification Intègre & Cohérence** : Tous les 100 tests automatisés passent avec succès, et le linter est vierge sous `dart analyze`. Les descriptions de l'interface et les comportements du code sont en parfaite adéquation.

---

## ⚔️ ADR-028 : Équilibrage Hybride de la Difficulté et Système de Réserve de Vagues (Hybrid Difficulty Balancing & Wave Reserve System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans les versions précédentes, la composition des rencontres de combat et le nombre d'ennemis sur le plateau étaient statiques ou faiblement liés à la progression réelle du joueur. Cela entraînait trois problèmes majeurs de game design et de performance :
1. **Écarts de difficulty** : Les joueurs optimisant fortement leur deck (fusions de raretés élevées, forges optimisées) trivialisaient rapidement le jeu. À l'inverse, les joueurs moins chanceux ou moins expérimentés faisaient face à des pics de difficulté brutaux.
2. **Surcharge visuelle du board (Flame)** : La génération d'un nombre important d'ennemis (plus de 3 ou 4) saturait le plateau de rendu mobile, provoquait des chevauchements visuels inacceptables pour les `PositionComponent` de Flame, et compliquait le ciblage tactile.
3. **Classification erronée de Boss (`isBoss`)** : Le test pour déterminer si le combat en cours était un combat de Boss s'appuyait uniquement sur le fait que le floor/niveau était un multiple de 10 (`level % 10 == 0`) sans valider que le nœud n'avait pas de type explicitement défini (nœud de combat classique). Ainsi, les combats classiques au floor 10 subissaient un surclassement de Boss injuste avec multiplicateurs de statistiques (x3 HP, x2 dégâts).

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
5. **Isolation de la Journalisation Mathématique (`CombatDebugLogger`)** :
   - Isoler toute la logique de construction textuelle des formules et du scaling des ennemis dans une classe de service dédiée, `CombatDebugLogger`.
   - **Responsabilité Unique (SRP)** : Le contrôleur `CombatController` doit se concentrer exclusivement sur les transitions d'état logique de combat et la coordination des vagues. Il ne doit pas être encombré par le formatage de chaînes, les codes ANSI ou les buffers d'affichage.
   - **Toggling & Performance en Production** : En mode production (release), les logs détaillés de la DDA sont désactivés par une garde `if (!kDebugMode) return;` dans le service, éliminant tout coût CPU ou allocations inutiles associés au formatage de chaînes complexes.
6. **Correction de la règle d'identification `isBoss`** :
   - Modifier la garde conditionnelle pour ne déclencher la détection par niveau modulo 10 que si le nœud n'est pas spécifié (`nodeType == null`) :
     ```dart
     final bool isBoss = nodeType == MapNodeType.boss || (nodeType == null && level > 0 && level % 10 == 0);
     ```
   - Appliquer cette formule unifiée dans `CombatController.initializeCombat` et `EncounterSystem.generateEnemiesForLevel`, évitant ainsi le scaling anormal de Boss pour les nœuds de combat classiques au niveau 10.

### Preuves dans le code
- `lib/game/systems/encounter_system.dart` : Méthode `generateEnemiesForLevel` calculant les formules de `PlayerPower`, `ExpectedPower`, `PowerModifier`, `FinalBudget` et calculant la `CombatRating` ajustée de chaque ennemi avec la garde `isBoss` corrigée.
- `lib/game/controllers/combat_controller.dart` :
  - `initializeCombat()` : répartition initiale des ennemis scalés entre le board actif `enemies` (limité à 5) et la file de réserve `pendingEnemies`, avec calcul de `isBoss` corrigé.
  - `_cleanDeadEnemies()` : transition synchrone des ennemis de `pendingEnemies` vers `enemies`, rolling d'intention et vérification combinée des deux listes pour lever le flag `isVictory`.
  - Appelle `CombatDebugLogger.logCombatInitialization(...)` à la fin de l'initialisation.
- `lib/game/services/combat_debug_logger.dart` : Classe de service formatant les logs avec codes couleurs ANSI et bordures de boîtes, encapsulée sous `kDebugMode`.
- `lib/models/data/combat_state.dart` : Ajout et sérialisation/désérialisation du champ `pendingEnemies`.
- `test/unit/combat_difficulty_test.dart` (ou tests similaires dans `test/unit/combat_controller_test.dart`) : Suite de tests automatisés validant le respect du budget de menace, le plafonnement à 5 slots actifs, le transfert automatique de la réserve lors de la mort d'un ennemi, et l'ajustement dynamique du modificateur de puissance.
- `test/encounter_system_test.dart` : Ajout de tests vérifiant la logique `isBoss` sous trois configurations : nœud Combat au niveau 10 (non Boss), nœud Null au niveau 10 (Boss), et nœud Boss au niveau 9 (Boss).
- `test/unit/combat_debug_logger_test.dart` : Test unitaire du service de journalisation pour s'assurer que l'appel ne lève aucune exception dans divers scénarios de données.

### Conséquences
- ✅ **Rythme de jeu adapté et stimulant** : Le jeu adapte intelligemment le nombre et la puissance des menaces à la composition du deck du joueur. Un deck sur-optimisé fera face à des vagues de monstres plus nombreuses ou plus puissantes, tandis qu'un joueur en difficulté verra la menace stabilisée.
- ✅ **Respect de l'espace de rendu Flame** : La limite stricte de 5 ennemis actifs garantit une présentation claire, évite tout bug visuel d'empilement sur smartphone portrait/paysage, et assure des performances constantes à 60 FPS sur l'arène graphique.
- ✅ **Pérennité du Game Progression** : L'amortissement de $0.5$ de la DDA préserve le sentiment de satisfaction de la progression (les builds puissants roulent toujours plus facilement sur le jeu que les builds faibles, mais le défi reste présent).
- ✅ **Séparation propre et maintenabilité** : La logique de log est isolée. Si l'on souhaite changer le format de log ou la couleur ANSI, on modifie uniquement `CombatDebugLogger`.
- ✅ **Cohérence de la Difficulté sur les Combats Multiples de 10** : Grâce à la correction `isBoss`, le joueur ne fait plus face à des pics de difficulté monstrueux injustifiés sur les nœuds de combat ordinaires situés au niveau 10.
- ✅ **Validation par tests automatisés** : 100/100 tests au vert, confirmant que le flow logique de la file de réserve, les transitions d'intentions, l'algorithme de génération de budget, la condition `isBoss` et le nouveau logger respectent rigoureusement les invariants métier.

---

## 🗺️ ADR-029 : Génération Procédurale Avancée avec Quotas et Anti-Répétition (Advanced Map Generation Constraints)

### Statut
✅ Accepté & Implémenté

### Contexte
La génération de la carte du monde procédurale sous forme de DAG pouvait dans certains cas générer des parcours trop faciles, répétitifs ou déséquilibrés. Par exemple, un joueur pouvait traverser un chemin contenant 4 combats d'élites d'affilée ou aucun feu de camp (Rest) pour se soigner avant un combat majeur. Il était indispensable de rajouter des contraintes algorithmiques strictes pour équilibrer la répartition des types de salles et de forcer des chokepoints structurels, tout en gérant 3 boss uniques à la fin de l'Acte avec des récompenses spécifiques.

### Décision
1. **Solver par Quotas de Nœuds** :
   - Définir des quotas stricts pour chaque type de nœud dans `GameConstants.nodeQuotas` :
     - Combat : 12-22
     - Élite : 3-6
     - Repos : 3-6
     - Boutique (Shop) : 2-5
     - Événement (Event) : 4-9
   - Exécuter une passe d'optimisation `_balanceQuotas` après la génération du graphe pour réallouer les types de nœuds excédentaires vers les types déficitaires.
2. **Contrainte Anti-Répétition de Chemin** :
   - Parcourir récursivement les chemins possibles du graphe (`_hasThreeConsecutive` et `_getChainOfThree`) pour détecter si un type de nœud Élite ou Repos apparaît 3 fois consécutivement.
   - Si une violation est détectée, remplacer l'un des nœuds de la chaîne par un type alternatif (Combat, Shop ou Event) afin de garantir qu'aucun chemin ne contienne 3 Élites ou 3 Repos consécutifs.
3. **Chokepoints Structurels Forcés** :
   - **Étage 5** : Forcer la largeur de l'étage à 1 seul nœud et forcer son type à Élite pour créer un combat de mi-parcours obligatoire pour tous les chemins.
   - **Étage 8** : Forcer tous les nœuds générés pour cet étage à être de type Repos (Rest), assurant ainsi une halte obligatoire et salutaire juste avant le combat de Boss.
4. **Trilogie de Boss Distincts (Étage 9)** :
   - Configurer 3 nœuds de Boss distincts à l'étage 9, différenciés uniquement par leur position horizontale (`x` index) pour offrir des récompenses de combat uniques. Les boss sont générés de manière procédurale et mis à l'échelle via l'algorithme d'équilibrage du CombatRating de façon standardisée sans utiliser d'identifiants ou d'entités boss hardcodés.
5. **Mécanique de Récompenses de Boss Thématiques basées sur la Position** :
   - À la défaite d'un Boss, déclencher des récompenses spécifiques selon la position horizontale (`x` index) du nœud du boss :
     - **Position gauche (x = 0)** : Dialogue interactif affichant 3 cartes globales aléatoires, permettant au joueur d'en sélectionner entre 1 et 3 pour les ajouter gratuitement à son deck (icône Cartes).
     - **Position centrale (x = 1)** : Multiplie par 2 toute l'expérience (XP) cumulée par le joueur lors du combat (icône Magie/XP).
     - **Position droite (x = 2)** : Garantit l'obtention d'une relique de rareté supérieure (minimum Uncommon, excluant totalement les communes, icône Diamant). Les chances de rareté sont : Legendary 15%, Epic 30%, Rare 35%, Uncommon 20%.

### Preuves dans le code
- `MapGeneratorService.generateMap` : Implémentation des règles d'étages (y == 5, y == floors-2, y == floors-1).
- `MapGeneratorService._optimizeMapTypes` et `_balanceQuotas` : Application itérative du solver de quotas et de l'anti-répétition.
- `MapNodeWidget` : Attribution dynamique de l'icône, de la couleur et de l'info-bulle en fonction de la position horizontale `xIndex` de l'ID du nœud de boss.
- `GameScreen._handleCombatVictory` et `_resolveCombatProgression` : Analyse de l'identifiant du nœud pour en extraire l'index de position horizontale `nodeX` afin de déterminer la récompense (choix de cartes pour x = 0, double XP pour x = 1, relique améliorée pour x = 2).
- Tests unitaires et widget-tests validés à 100%.

### Conséquences
- ✅ **Rythme de jeu équilibré et tactique** : L'interdiction des suites infinies d'Élites ou l'absence de Repos évite les situations de défaite inévitable ("soft lock").
- ✅ **Variété tactique de fin de partie** : La présence de 3 boss distincts à l'étage 9 et leurs récompenses variées encouragent les joueurs à adapter leur itinéraire en fonction de leurs besoins (XP vs Cartes vs Reliques).
- ✅ **Robustesse algorithmique** : L'optimisation par solver garantit le respect des quotas sur toutes les cartes générées.

---

## 🎨 ADR-030 : Polissage de l'UI de Combat Responsive et Signalétique de Ciblage Localisée (Combat UI Polish & Sizing)

### Statut
✅ Accepté & Implémenté

### Contexte
L'arène de combat Flame et l'interface utilisateur Flutter (HUD) présentaient des problèmes d'affichage sur des terminaux aux rapports d'aspect variés. Le HUD joueur de combat (Mana, PV, Armure) subissait parfois des chevauchements ou des troncatures. De plus, la signalétique de ciblage des cartes (Single Target, AoE, Self) n'était pas bilingue et risquait de déborder sur les petits écrans. Enfin, les cartes d'ennemis sur le plateau Flame possédaient une taille uniforme ne reflétant pas leur dangerosité relative, et l'accès au deck ou aux reliques depuis la carte du monde manquait de repères visuels clairs.

### Décision
1. **HUD de Combat Responsive Clamped** :
   - Rendre le panneau de statistiques du joueur et des compétences réactif à la hauteur et à la largeur de l'écran en utilisant `MediaQuery` et des facteurs de mise à l'échelle.
   - Appliquer des contraintes de clamping sur les hauteurs et largeurs des conteneurs pour préserver la lisibilité sans clipping sur les tablettes et les mobiles étroits.
2. **Badges de Ciblage de Cartes FittedBox Wrapped** :
   - Ajouter un badge visuel sur la face avant de chaque carte unifiée `UiCard` indiquant son mode de ciblage (`_resolveTarget`).
   - Mapper les types d'effets pour obtenir un label textuel bilingue ('Cible unique', 'Tous les ennemis', 'Soi-même' en français / 'Single Target', 'All Enemies', 'Self' en anglais).
   - Envelopper le texte du badge dans un composant `FittedBox` pour forcer la mise à l'échelle automatique du texte et interdire tout débordement en dehors du badge physique.
3. **Badges et Indicateurs de Navigation sur la Carte** :
   - Ajouter un badge d'inventaire dynamique sur le bouton Reliques de la `MapScreen` montrant en temps réel le nombre de reliques collectées.
   - Intégrer un badge numérique sur le bouton Deck de la carte, affichant à tout moment le nombre actuel de cartes dans le master deck du joueur.
4. **Scaling Échelle des Ennemis** :
   - Modifier l'échelle visuelle (`scale`) des cartes d'ennemis (`EnemyCard`) en fonction de leur niveau de menace et de leur type (Elite ou Boss) pour donner une impression de grandeur et de puissance relative sur le plateau Flame.

### Preuves dans le code
- `GameScreen` : Layouts flexibles du HUD utilisant des contraintes proportionnelles aux dimensions de l'écran.
- `UiCard._resolveTarget` et `_buildTargetIcon` : Construction dynamique des icônes et textes bilingues de ciblage enveloppés de `FittedBox`.
- `MapScreen` : Badge numérique sur le bouton reliques (`relics.length`) et badge numérique sur le bouton de deck (`deck.length`).
- `EnemyCard` : Application de facteurs de scale personnalisés lors de l'initialisation du composant graphique.
- Validation complète et absence totale d'erreurs statiques sous `dart analyze`.

### Conséquences
- ✅ **Lisibilité universelle** : L'adaptation responsive assure un rendu professionnel et sans clipping sur l'ensemble de la gamme d'appareils testés.
- ✅ **Guidage utilisateur amélioré** : Les badges bilingues de ciblage et les indicateurs d'inventaire guident immédiatement le joueur sur les actions possibles.
- ✅ **Game Feel Premium** : Le scaling des sprites d'ennemis renforce visuellement la structure dramatique des rencontres de combat.

---

## 🪙 ADR-031 : Centralisation des Récompenses de Combat et Refactoring du Gain d'Or (Combat Reward Centralization & Gold Drops)

### Statut
✅ Accepté & Implémenté

### Contexte
Auparavant, le calcul et l'attribution des récompenses post-combat (XP, or, reliques et tirages de cartes) étaient intégrés directement au sein des classes de l'interface utilisateur (`GameScreen` et `DraftScreen`). Cette structure violait le principe de séparation des responsabilités, rendant l'interface lourde, difficile à tester et sujette aux régressions. De plus, les drops d'or des ennemis étaient calculés de manière aléatoire et codés en dur lors du draft de fin de combat, et le type de récompense de Boss à l'étage 9 était résolu par une analyse textuelle de l'identifiant du nœud (`id.endsWith('_0')`), ce qui était fragile et limitait l'évolutivité.

### Décision
1. **Ajout et Scaling du Butin d'Or des Ennemis** :
   - Ajouter la propriété `gold` au modèle `EnemyData` (avec une valeur par défaut de 10) et au modèle runtime `EnemyInstance`.
   - Définir l'or de base spécifique à chaque monstre dans `enemies.json` (slime: 10, gobelin: 12, squelette: 15, orc furieux: 25).
   - Mettre à l'échelle l'or gagné lors de la victoire en utilisant la même formule progressive que pour l'XP : `(baseGold * levelMultiplier).round()` où `levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1)`.
2. **Typage Fort des Récompenses de Boss** :
   - Introduire l'énumération `BossRewardType { cards, doubleXp, improvedRelic }` pour modéliser proprement les récompenses uniques de fin d'acte.
   - Ajouter le champ optionnel `bossRewardType` au modèle de données `MapNode` avec support complet de sa sérialisation/désérialisation JSON.
   - Lors de la génération procédurale dans `MapGeneratorService`, assigner explicitement `bossRewardType` aux nœuds de l'étage final (étage 9) en se basant sur leur position horizontale `x` (0: `cards`, 1: `doubleXp`, 2: `improvedRelic`).
3. **Création du Contrôleur de Récompenses (`RewardController`)** :
   - Introduire `RewardController` (`rewardProvider`), un `StateNotifier` centralisant l'état d'attribution post-combat (`RewardState`).
   - Gérer de manière isolée le calcul unifié des gains (XP doublée pour `doubleXp`, or scalé, et jets de relique de rareté supérieure pour `improvedRelic` excluant les reliques communes).
   - Encapsuler les méthodes de validation de collecte et d'omission : `collectGoldAndXp()`, `collectRelic()`, `skipRelic()`, `chooseCards()`, `skipCards()`.
   - Maintenir le drapeau d'état global `isResolved` pour coordonner la fin de la séquence de victoire.
4. **Découplage et Nettoyage de l'UI** :
   - Modifier `MapNodeWidget` pour lire directement le type fortement typé `node.bossRewardType` à la place du parsing de chaîne de coordonnées.
   - Refactoriser `GameScreen` pour déléguer les calculs et le séquençage visuel des récompenses (relique, draft de cartes, montées de niveau et transition de retour) au `rewardProvider`.
   - Supprimer le gain d'or aléatoire codé en dur qui persistait dans `DraftScreen._finishDraft`.

### Preuves dans le code
- `lib/models/data/enemy_data.dart` et `lib/models/map_node.dart` : ajout des attributs et mise à jour de `fromJson`/`toJson`.
- `assets/data/enemies.json` : définition de la propriété `"gold"` pour chaque ennemi.
- `lib/services/map_generator_service.dart` : attribution de `bossRewardType` lors de la construction de la carte.
- `lib/game/controllers/reward_controller.dart` : implémentation complète du contrôleur et de son état immuable.
- `lib/ui/widgets/map/map_node_widget.dart`, `lib/ui/screens/game_screen.dart` et `lib/ui/screens/draft_screen.dart` : intégration des flux de récompenses par delegation au provider.
- Validation statique vierge sous `dart analyze` et passage des 100 tests unitaires et widget-tests de la suite de tests.

### Conséquences
- ✅ **Séparation Métier / Rendu nette** : La logique de récompenses n'encombre plus les vues UI, ce qui facilite grandement la maintenance.
- ✅ **Robustesse et Évolutivité** : Remplacement des parsing fragiles par des types et propriétés forts. L'ajout de nouvelles récompenses de carte ou d'événements s'en trouve simplifié.
- ✅ **Testabilité Accrue** : Possibilité de tester la validité des calculs de butins, de drops d'or et de tirages de reliques par de simples tests unitaires Riverpod sans monter d'arbre de widgets.
- ✅ **Économie de Combat Cohérente** : Les gains d'or sont désormais directement proportionnels au niveau et à la difficulté des ennemis vaincus, évitant les anomalies de progression.

---

## 🏆 ADR-032 : Finalisation du Refactoring des Récompenses de Boss (Boss Rewards Finalization)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour finaliser le refactoring des récompenses post-combat initié dans la version 0.0.94, il était nécessaire d'intégrer pleinement les comportements et mécaniques propres aux 3 boss thématiques situés à l'étage 9 de la carte. Précédemment, les récompenses n'offraient pas le niveau d'interactivité requis (les tirages de cartes de boss n'avaient pas d'écran dédié et les probabilités de reliques étaient fixes). Le but était de concevoir un écran de sélection de cartes complet et obligatoire pour le Boss 1, de doubler les récompenses d'or et d'XP pour le Boss 2, et de concevoir une progression probabiliste de drop de relique dynamique selon l'acte en cours pour le Boss 3.

### Décision
1. **Écran de Draft Dédié pour Boss 1 (`BossCardDraftScreen`)** :
   - Créer `BossCardDraftScreen` dans `lib/ui/screens/boss_card_draft_screen.dart` s'appuyant sur le widget unifié `UiCard` contraint dans des dimensions fixes de `140x220`.
   - Charger toutes les cartes globales à l'exception des cartes status (`CardType.status`) pour composer le pool.
   - Forcer le joueur à sélectionner **exactement 3 cartes** avant d'activer le bouton de validation (« Confirmer la sélection »).
   - Intégrer cet écran via des redirections de navigation appropriées depuis `GameScreen`.
2. **Doublement Récompenses Boss 2** :
   - Doubler à la fois l'Or et l'XP de combat calculés lors de la victoire contre le boss du nœud central (x=1) dans `RewardController`.
   - Mettre à jour les tooltips dans `MapNodeWidget` et les étiquettes de légende de `MapLegend` en français ("Boss (XP & Or x2)") et en anglais ("Boss (2x XP & Gold)").
3. **Chances de Reliques Évolutives Boss 3** :
   - Fixer la chance de base Légendaire à **10.0%** (uniquement scalable par la statistique de Chance/Luck du joueur).
   - Diminuer la chance Commune de base démarrant à **40.0%** de **10% par acte** : `commonChance = max(0.0, 40.0 - (act - 1) * 10.0)`.
   - Distribuer proportionnellement la baisse de chance Commune (soit `90.0 - commonChance`) entre Uncommon, Rare, et Epic selon leurs parts relatives (respectivement 20/85, 35/85, 30/85), plus le bonus de luck.
   - Si la chance Commune atteint 0.0% (à l'Acte 5), commencer à diminuer la chance d'Atypique (Uncommon) de **10% par acte** à partir de sa base maximale de `(20.0 / 85.0) * 90.0` : `baseUncommonChance = max(0.0, maxUncommonBase - (act - 5) * 10.0)`.
   - Distribuer proportionnellement cette réduction de Uncommon (soit `90.0 - baseUncommonChance`) vers Rare et Epic selon leurs parts relatives de base (35/65, 30/65).
   - Logique de tirage cumulée intégrée au sein de `RewardController`.
4. **Correction du Tirage de Relique pour Boss 1 et Boss 2** :
   - Restreindre le tirage de relique dans le pipeline de récompenses aux seuls nœuds Élite ou Boss de type `BossRewardType.improvedRelic` (Boss 3).
   - Précédemment, la condition vérifiait simplement si le nœud était de type `MapNodeType.boss` sans valider son `bossRewardType`, ce qui faisait que Boss 1 (choix de cartes) et Boss 2 (Double XP & Or) tiraient et attribuaient par erreur une relique au joueur.
   - Corriger cette logique à la ligne 100 (lignes 100-101) de `lib/game/controllers/reward_controller.dart` :
     ```dart
     if (currentNode.type == MapNodeType.elite || (currentNode.type == MapNodeType.boss && isImprovedRelic)) {
     ```

### Preuves dans le code
- `lib/ui/screens/boss_card_draft_screen.dart` : Création de la vue GridView responsive, de la gestion de sélection multiple avec validation (compteur fixe à 3) et du bouton de confirmation.
- `lib/game/controllers/reward_controller.dart` : Calcul conditionnel des chances de reliques Boss 3 (`isImprovedRelic`) indexé sur l'Act, restriction du tirage de relique aux seuls nœuds Élite ou Boss 3 (ligne 100), et application de `totalXp *= 2` et `totalGold *= 2` pour Boss 2.
- `lib/ui/widgets/map/map_legend.dart` & `lib/ui/widgets/map/map_node_widget.dart` : Affichage localisé des tooltips et légende ("Boss (XP & Or x2)" / "Boss (2x XP & Gold)").

### Conséquences
- ✅ **Game Feel Premium** : Le joueur fait face à des opportunités de choix marquantes pour le Boss 1, à une économie relancée pour le Boss 2, et à des drops haut de gamme cohérents avec l'Acte pour le Boss 3.
- ✅ **Correction de la Distribution de Butin** : Éradication du bug de distribution indue de reliques sur les Boss 1 et 2, garantissant l'intégrité de l'économie des récompenses de fin d'acte et l'alignement sur les spécifications de design initiales.
- ✅ **Absence de Régression Technique** : Intégration transparente au sein du `RewardController` existant.
- ✅ **Respect de la Règle i18n** : Traduction intégrale des dialogues et tooltips.

---

## 🎒 ADR-033 : Refonte des Reliques, Déclencheurs de Type de Carte et Système de Charges (Relic Overhaul, Card-Type Triggers & Charge Systems)

### Statut
✅ Accepté & Implémenté

### Contexte
La version 0.0.94 de Hero's Draft comportait un ensemble de 14 reliques, ce qui déséquilibrait le pool en sous-représentant les reliques communes (seulement 1 relique commune, le Talisman de Fer, par rapport aux nombreuses reliques atypiques, rares ou épiques). De plus, les déclencheurs de reliques étaient limités à des phases globales de combat ou au fait de jouer n'importe quelle carte (`onCardPlayed`), ne permettant pas de concevoir des reliques favorisant des archétypes de deck spécifiques (tels que des decks centrés sur les attaques ou les compétences). Enfin, le jeu manquait de reliques actives ou à compteurs de charges (inspirées des classiques de type *Slay the Spire* comme Kunaï, Shuriken, Pen Nib ou Encensoir), qui récompensent l'accumulation d'actions au fil des tours ou du combat.

### Décision
1. **Équilibrage et Extension du Pool de Reliques** :
   - Ajouter 10 nouvelles reliques dans `relics.json`, portant le total à 24 reliques.
   - Introduire 4 nouvelles reliques Communes pour rééquilibrer le tirage en début de partie : *Pierre à aiguiser* (Whetstone, +1 Force), *Bottes en cuir* (Leather Boots, +3 Armure au combat), *Pièce de chance* (Lucky Coin, +5% Critique permanent), et *Bandage de voyage* (Travel Bandage, Soin 1 PV à la fin du tour).
   - Introduire *Plume de scribe* (Pen Nib, atypique) et *Couronne des Rois* (Crown of Kings, légendaire).
   - Introduire 4 nouvelles reliques Rares basées sur des compteurs de charges : *Croc Kunaï* (Kunai), *Shuriken*, et *Encensoir* (Incense Burner).
2. **Gestion du Mana Permanent et de Combat** :
   - Implémenter le gain de Mana max permanent pour toute la run via l'effet `gain_mana` associé au trigger `startOfRun` de la *Couronne des Rois* dans `RunController.applyRelics` (incrémente `state.maxMana` de manière durable).
   - Implémenter le gain de Mana de combat via la *Plume de Phénix* (trigger `startOfCombat` avec l'effet `gain_mana`) en ajoutant la valeur de la relique à la réserve de mana de départ du joueur.
3. **Déclencheurs par Type de Carte Spécifique** :
   - Ajouter les valeurs `onAttackPlayed`, `onSkillPlayed` et `onPowerPlayed` à l'énumération `RelicTrigger`.
   - Dans `CombatController.applyPlayerCardPlay`, après avoir déclenché `onCardPlayed`, évaluer le type de la carte jouée (`card.type`) :
     - Si `CardType.attack` : propager `RelicTrigger.onAttackPlayed`.
     - Si `CardType.skill` : propager `RelicTrigger.onSkillPlayed`.
     - Si `CardType.power` : propager `RelicTrigger.onPowerPlayed`.
4. **Système de Charges et Compteurs via Statuts Empilables** :
   - Utiliser la liste existante des statuts (`EntityStats.statuses`) pour stocker et incrémenter visuellement les compteurs sous forme de `StatusEffect` spécifiques attachés au Héros.
   - Les charges possèdent un indicateur textuel et une icône correspondante dans le panneau des effets de statut du HUD de combat, garantissant un retour visuel direct.
   - Dans `RunController.applyRelicEffect`, gérer la logique de charge :
     - **Kunaï** (`kunai`) & **Shuriken** (`shuriken`) : Utilise des charges à durée de 1 tour (`kunai_charge`, `shuriken_charge`). À chaque attaque jouée, la charge s'incrémente. Si elle atteint 3, les charges sont supprimées et le bonus permanent (+1 Maîtrise d'Armure pour Kunaï, +1 Force de combat pour Shuriken) est appliqué. Si le tour se termine avant d'atteindre 3 charges, le tick de début de tour décrémente et détruit automatiquement les charges non-résolues.
     - **Plume de scribe** (`pen_nib`) : Utilise des charges persistantes d'un tour à l'autre (`pen_nib_charge` avec une durée de 99). À chaque carte jouée, la charge s'incrémente. À 5 charges, reset et confère +3 Force temporaire (durée de 1 tour).
     - **Encensoir** (`incense_burner`) : Utilise des charges persistantes (`incense_charge` de durée 99) incrémentées au début de chaque tour. À 4 charges, reset et confère +8 Armure.
5. **Persistance de l'Armure et Synergies** :
   - Le jeu conservant l'Armure d'un tour à l'autre (l'Armure ne decay pas en fin de tour dans Hero's Draft), la Maîtrise d'Armure conférée par le Kunaï et l'armure brute de l'Encensoir s'avèrent particulièrement puissantes pour les builds défensifs.
6. **Statistiques Permanentes de Run vs Buffs de Combat** :
   - Afin de rationaliser les effets agissant sur les statistiques du joueur (Force/Attaque, Chances de Critique), les reliques d'ajustement de statistiques fixes de début de combat (comme *Pierre à aiguiser*, *Lame Maudite*, *Lentille de Focalisation*) ont été converties pour agir à l'échelle de toute la run (déclencheur `startOfRun`). Cela permet à ces bonus de modifier directement et de manière permanente la fiche de personnage globale plutôt que de polluer le panneau des statuts de combat sous forme de buffs de 99 tours. Les gains d'Armure et de Mana au combat (ressources éphémères) conservent leur déclencheur `startOfCombat`.
7. **Mise à jour du Dictionnaire de Reliques (bilingue)** :
   - Adapter `DictionaryScreen` (`card_dictionary_screen.dart`) pour mapper et traduire les nouveaux types de déclencheurs (`onAttackPlayed` → "At Play (Attack)" / "Jouer (Attaque)", etc.) sous forme de badges de couleurs spécifiques.

### Preuves dans le code
- `assets/data/relics.json` : Modifié pour intégrer les 10 nouvelles reliques et corriger les identifiants techniques et triggers.
- `lib/models/data/relic_data.dart` : Ajout des enums et valeurs de triggers `onAttackPlayed`, `onSkillPlayed`, `onPowerPlayed` dans `RelicTrigger`.
- `lib/game/controllers/combat_controller.dart` : Propagation des événements de type de carte dans `applyPlayerCardPlay` (lignes 215-221).
- `lib/game/controllers/run_controller.dart` : Implémentation du switch de charges dans `applyRelicEffect` (lignes ~369-482), gestion de la suppression des statuts de charge lors de l'application de l'effet, et prise en charge du gain de Mana max permanent dans `addRelic`.
- `lib/ui/screens/card_dictionary_screen.dart` : Ajout des libellés bilingues et styles de badges de trigger.
- Validation statique vierge sous `dart analyze` et passage des 100 tests unitaires et widget-tests de la suite de tests.

### Conséquences
- ✅ **Profondeur Stratégique Accrue** : Les joueurs peuvent désormais bâtir des synergies spécialisées autour de decks fortement agressifs (Shuriken/Kunaï) ou de la tempo (Encensoir, Plume de Scribe).
- ✅ **Clarté Visuelle Maximale** : L'utilisation de `StatusEffect` pour afficher les compteurs de charges réutilise l'infrastructure existante du HUD tout en offrant une rétroaction instantanée sans surcharge visuelle.
- ✅ **Équilibrage de Rareté Réussi** : Le pool de reliques communes passe de 1 à 5, diminuant la frustration liée aux tirages de reliques d'entrée de jeu.
- ✅ **Architecture Découplée et Propre** : Les calculs de charges et d'effets se font intégralement côté contrôleurs Riverpod, préservant l'isolation de la couche Flame et de l'interface graphique.

---

## 🔄 ADR-034 : Rencontre d'Échange de Reliques (Relic Exchange Shrine Node)

### Statut
✅ Accepté & Implémenté

### Contexte
Pour diversifier les nœuds d'intérêt sur la carte stratégique en fin de partie et offrir au joueur une opportunité de raffiner ses synergies de reliques, il manquait un mécanisme d'échange ou de sur-classement ("upcycling"). L'objectif était d'implémenter un nœud de type autel mystique à partir de l'Acte 5, permettant de sacrifier 3 reliques d'une rareté donnée pour acquérir 1 relique de rareté supérieure proposée de façon déterministe. De plus, il fallait s'assurer que si des reliques de type permanent (comme celles augmentant la Force, la Chance ou les PV max) étaient sacrifiées, leurs effets permanents sur la fiche de personnage du héros soient correctement annulés et retirés avant d'attribuer la nouvelle relique.

### Décision
1. **Topologie et Règles de Génération** :
   - Définir le type de nœud `MapNodeType.relicExchange` (emoji `🔄`).
   - Restreindre son apparition à partir de l'**Acte 5**.
   - Garantir sa présence à **100%** pour tout acte divisible par 5 (Acte 5, 10, etc.). Pour les autres actes ($\ge 5$), appliquer une probabilité d'apparition de **10%**.
   - Limiter à un seul nœud d'échange par acte, positionné sur un étage intermédiaire aléatoire (étages 2, 3, 4, 6 ou 7) pour ne pas perturber les haltes obligatoires (repos, élites, boss, nœud de départ).
2. **Offre Déterministe via Seeded Random** :
   - Éviter d'enregistrer l'offre du nœud en base de données de session en instanciant un générateur de nombres aléatoires déterministe basé sur l'identifiant du nœud et l'acte : `final seed = (node.id.hashCode ^ act).abs(); final random = Random(seed);`.
   - Exclure la rareté `Common` du choix de relique offerte et pondérer les chances : Uncommon (40%), Rare (35%), Epic (20%), et Legendary (5%).
3. **Transaction 3-pour-1 et Nettoyage de RunState** :
   - Implémenter la transaction dans `RunController.exchangeRelics` :
     - Retirer les 3 reliques sélectionnées de l'inventaire via `InventoryController.removeRelics`.
     - Inverser et déduire les bonus statistiques permanents accumulés (modificateurs permanents de run via trigger `startOfRun` : Attaque/Force, Chance, Mana maximum, PV maximum) pour chacune des reliques sacrifiées.
     - Ajouter la nouvelle relique via `InventoryController.addRelic` et appliquer immédiatement ses effets permanents si son trigger est `startOfRun`.
4. **Interface Utilisateur Dédiée (`RelicExchangeScreen`)** :
   - Créer un écran thématique d'autel en parchemin affichant la relique offerte, les pré-requis de sacrifice ($R-1$), et les reliques possédées éligibles.
   - Permettre la sélection tactile de 3 reliques (glow doré) avec bouton d'échange sécurisé et possibilité de quitter librement.

### Preuves dans le code
- `lib/services/map_generator_service.dart` : Intégration du nœud `relicExchange` (emoji `🔄`) sous des contraintes d'étage et d'Acte strictes.
- `lib/game/controllers/run_controller.dart` : Méthode `exchangeRelics(sacrificed, gained)` et méthode interne d'inversion des modificateurs de statistiques `removeRelicEffect(relic)`.
- `lib/game/controllers/inventory_controller.dart` : Méthode `removeRelics(List<String> ids)` filtrant et retirant les instances d'inventaire.
- `lib/ui/screens/relic_exchange_screen.dart` : Écran utilisateur avec PageView, grid interactive, sélections glow et confirmation sécurisée.
- `test/unit/relic_exchange_test.dart` : Tests de couverture de la topologie de la carte selon l'acte et de la logique de transaction/inversion.

### Conséquences
- ✅ **Gestion Saine de la Rareté** : Le joueur peut liquider ses reliques de moindre importance pour viser des pièces maîtresses (Épiques ou Légendaires).
- ✅ **Intégrité Mathématique de la Fiche de Personnage** : Pas d'accumulation infinie d'effets statistiques via des boucles infinies d'échange de reliques de run (Force/Mana/PV max bien déduits).
- ✅ **Architecture Déterminée et Légère** : Pas besoin de sauvegarder l'état de l'offre du nœud d'échange grâce à la seed déterministe par nœud/acte.
- ✅ Couverture de Tests : 3 nouveaux tests unitaires rédigés et validés à 100% verts, portant la suite à **103 tests** (100% verts).

## 🔄 ADR-035 : Modernisation Architecturale Riverpod & Découplage (Riverpod Notifier & Architectural Cleanups)

### Statut
✅ Accepté & Implémenté

### Contexte
L'architecture originale du projet reposait sur l'ancienne version de Riverpod (v1.x) utilisant `StateNotifier` et `StateNotifierProvider`. Cette approche imposait des contraintes rigides : pour que les contrôleurs communiquent entre eux, ils devaient s'injecter mutuellement dans leurs constructeurs respectifs ou stocker des instances de `Ref` globales. Cela menait à des signatures de constructeurs complexes et volumineuses, et augmentait considérablement le risque de dépendances circulaires au démarrage de l'application.
De plus, certains modèles comme `CardInstance` contenaient des listes modifiables (comme `forgeUpgrades`), ce qui pouvait corrompre l'état de manière silencieuse lors de manipulations directes. Enfin, une partie de la logique métier de combat (le calcul et l'application des compétences héroïques, `executeSkill`) était historiquement couplée et codée en dur dans le moteur de rendu graphique Flame (`HerosDraftGame`), violant le principe de séparation des responsabilités.

### Décision
1. **Migration vers Notifier et NotifierProvider** :
   - Abandonner complètement le pattern obsolète `StateNotifier` au profit de la classe moderne `Notifier` de Riverpod 2.x pour tous les contrôleurs métier (`RunController`, `CombatController`, `DeckNotifier`, `InventoryController`, `SkillController`, `EventController`, `ShopController`, `RewardController`).
   - Mettre à jour tous les providers associés vers `NotifierProvider`.
2. **Découplage Interne via `ref` et `ref.read`** :
   - Supprimer tous les paramètres de constructeur ou les injections directes de dépendances dans les constructeurs des contrôleurs.
   - Les contrôleurs héritent de `Notifier`, ce qui leur donne accès de manière native et sécurisée à la propriété `ref`.
   - Utiliser exclusivement `ref.read` en interne pour récupérer les instances des autres contrôleurs au moment de l'exécution (par exemple, `ref.read(runProvider.notifier)`).
3. **Immuabilité Stricte de `CardInstance`** :
   - Rendre tous les attributs de `CardInstance` finaux.
   - Forcer le gel de la liste des améliorations de la forge `forgeUpgrades` en la convertissant systématiquement en une liste non modifiable (`List<String>.unmodifiable`) lors de l'instanciation.
   - Remplacer toute altération par des appels à `copyWith` retournant de nouvelles instances.
4. **Découplage de la Logique de Compétence Flame** :
   - Extraire la logique métier de calcul des compétences (`executeSkill` qui calcule les dégâts, le vol d'armure, etc.) de la classe Flame `HerosDraftGame`.
   - L'intégrer proprement dans `CombatController` sous forme de méthode `executeSkill(SkillData skill, double healthPercent, RunController runCtrl)`.
   - Maintenir Flame comme un simple moteur de rendu réactif observant les changements d'état sans héberger de calculs de règles de combat.

### Preuves dans le code
- `lib/game/controllers/combat_controller.dart` : Héritage de `Notifier<CombatState>`, accès direct à `runProvider` et `deckProvider` via `ref.read`, et implémentation de la méthode métier `executeSkill`.
- `lib/game/controllers/run_controller.dart` : Héritage de `Notifier<RunState>` sans constructeur surchargé.
- `lib/game/controllers/deck_controller.dart` : Héritage de `Notifier<DeckState>` et manipulation de `CardInstance` en mode immuable.
- `lib/models/card_instance.dart` : Initialisation de `forgeUpgrades` avec `List<String>.unmodifiable`.
- `lib/game/heros_draft_game.dart` : Nettoyage des calculs métiers de compétences, Flame délègue l'exécution à `ref.read(combatProvider.notifier).executeSkill(...)`.

### Conséquences
- ✅ **Éradication des Dépendances Circulaires** : Les contrôleurs ne s'injectent plus dans les constructeurs, résolvant définitivement les bugs de cycles de dépendances.
- ✅ **Clean Code & SRP** : Flame ne contient plus de logique métier de combat, respectant une séparation stricte entre rendu visuel et logique applicative.
- ✅ **Prévisibilité de l'État** : L'immuabilité stricte de `CardInstance` élimine les risques d'effets de bord où une carte partagée est modifiée par mégarde en cours de combat.
- ✅ **Robustesse et Fiabilité** : Les 104 tests automatisés passent toujours avec succès, prouvant qu'aucune régression fonctionnelle n'a été introduite par ce refactoring majeur.

---

## 🔄 ADR-036 : Optimisations Graphiques, Performances de Rendu Flame & Synchronisation des Animations (Graphics, Performance & Animation Optimizations)

### Statut
✅ Accepté & Implémenté

### Contexte
La version 0.0.98 de Hero's Draft présentait plusieurs inefficacités visuelles et goulots d'étranglement de performance dans son moteur de rendu Flame :
1. **Redondance GPU via `saveLayer`** : L'affichage des textes flottants de dégâts/soins (`FloatingText`) et des petites icônes vectorielles (`EffectIcon`) déclenchait des appels répétitifs à `canvas.saveLayer()`. Ces appels forcent le GPU à allouer des tampons off-screen coûteux en mémoire et en temps de calcul, dégradant le framerate sur mobile.
2. **Re-layout CPU à chaque frame** : Pendant les transitions d'opacité (fondus), la disposition textuelle (`TextPainter`) de `CardComponent` était recalculée et re-layoutée à chaque frame, gaspillant du temps CPU.
3. **Condition de concurrence des effets de combat** : Les secousses d'écran, les flashs de sprite et les projectiles visuels étaient initiés dès le clic sur une carte, créant un décalage visuel où l'ennemi affichait ses dégâts (chiffres flottants, flash de douleur) avant même que le projectile ou la carte ne l'ait physiquement percuté. De plus, des double-réactions redondantes dans `CardAnimator` généraient parfois des duplications d'animations.
4. **Manque de poli visuel lors de la pioche** : Les cartes piochées apparaissaient instantanément dans la main, manquant de fluidité et de réalisme physique.

### Décision
1. **Éradication des saveLayer superflus** :
   - Éliminer complètement les appels à `canvas.saveLayer` dans `FloatingText` et `EffectIcon`. Peindre directement sur le canvas principal en adaptant les styles et pinceaux de dessin vectoriels.
2. **Optimisation du Layout CPU de Texte et Opacité Conditionnelle** :
   - Mettre en cache l'instance de `TextPainter` pour le titre et la description dans `CardComponent`.
   - Pendant les transitions d'opacité, éviter de ré-agencer le texte. Dessiner avec `canvas.saveLayer` uniquement et exclusivement si la carte a une opacité strictement inférieure à 1.0 (`opacity < 1.0`). Si la carte est opaque (cas standard), contourner l'allocation off-screen pour peindre le texte en direct.
3. **Synchronisation à l'Impact Synchrone & Anti-Double Trigger** :
   - Différer l'apparition des effets visuels d'impact (tremblement de carte, flash de sprite, FloatingText de dégâts, particules) sur `EnemyCard` lorsque `game.isCardAnimating == true`.
   - Stocker ces effets dans le tampon `_pendingVisualInstance`.
   - Déclencher l'impact physique, le flash, les chiffres de dégâts et l'actualisation des HP/armure uniquement lors de la collision de la carte avec l'ennemi en appelant explicitement `resolvePendingVisualStats()` au moment de l'impact réel.
   - Retirer les écouteurs et callbacks redondants dans `CardAnimator` pour éliminer définitivement les doubles déclenchements.
4. **Effet Physique Organique de Pioche** :
   - Instancier les cartes piochées aux coordonnées de la pile de pioche `Vector2(40, size.y - 40)`.
   - Utiliser des Flame Effects asynchrones (`MoveEffect`, `ScaleEffect`, `RotateEffect`) chaînés pour faire glisser, redimensionner et orienter la carte dynamiquement vers son slot final dans la main.

### Preuves dans le code
- `lib/game/components/floating_text.dart` & `lib/game/components/effect_icon.dart` : Nettoyage des appels à `saveLayer`, dessin direct.
- `lib/game/components/card_component.dart` : Implémentation du cache de layout textuel et de l'opacité conditionnelle.
- `lib/game/components/enemy_card.dart` : Modification de `updateStats` pour différer l'intégralité des effets d'impact physiques (flashes, shakes, particules) et du calcul visuel sous conditions de carte active, résolus dans `resolvePendingVisualStats`.
- `lib/game/animators/card_animator.dart` : Suppression des branchements redondants d'animation d'impact.
- `lib/game/heros_draft_game.dart` : Logique de spawn de cartes à `Vector2(40, size.y - 40)` avec application d'effets visuels combinés.

### Conséquences
- ✅ **Fluidité Graphique Optimisée (60 FPS)** : Le retrait de `saveLayer` élimine les goulots d'étranglement GPU et stabilise le framerate sur mobile. Le caching CPU évite le coût de `layout()` sur le fil de rendu.
- ✅ **Immersion et Confort Visuel** : Les retours d'impact se déclenchent à la frame exacte de collision physique de la carte. Plus de flash de dégâts ou de chiffres flottants prématurés.
- ✅ **Tactilité Améliorée ("Game Feel")** : L'animation de pioche avec trajectoire et orientation fluide renforce l'aspect physique du deckbuilder.

---

## 🎨 ADR-037 : Système de Design Centralisé & Uniformisation UI (Design System & UI Uniformization)

### Statut
✅ Accepté & Implémenté

### Contexte
L'interface utilisateur de Hero's Draft souffrait d'une fragmentation des définitions visuelles : des couleurs codées en dur (`Color(0xFF...)`) et des valeurs d'espacement magiques (`EdgeInsets.all(8.0)`) étaient dispersées dans 15+ fichiers de widgets sans source de vérité unique. Cette situation générait plusieurs problèmes :
1. **Inconsistance visuelle** : Des couleurs légèrement différentes pour le même concept pouvaient diverger au fil des nouvelles features.
2. **Coût de maintenance élevé** : Changer la palette de couleurs impliquait de modifier des dizaines de fichiers.
3. **Redondance** : Des `switch` sur `CardRarity` ou `RelicRarity` pour retourner une `Color` étaient dupliqués dans au moins 4 composants (`UiCard`, `RelicsDialog`, `DictionaryScreen`, `BossCardDraftScreen`).
4. **Bug silencieux de layout** : Un `RenderFlex` overflow sur `GameButton` se manifestait sur les boutons contenant uniquement une icône dorée (sans libellé textuel).

### Décision
1. **Création du module `lib/ui/theme/`** :
   - **`app_colors.dart` (`AppColors`)** : Classe statique regroupant toutes les palettes du jeu en domaines sémantiques : `neonDark`, `parchment`, `stats`, `cardRarityColors` (`Map<CardRarity, Color>`) et `relicRarityColors` (`Map<RelicRarity, Color>`).
   - **`app_spacing.dart` (`AppSpacing`)** : Helpers `EdgeInsets` nommés (`xs`, `sm`, `md`, `lg`, `xl`) pour des paddings cohérents.
   - **`app_theme.dart` (`AppTheme`)** : Factory statique générant un `ThemeData` Flutter complet (dark/light) via `ColorScheme.fromSeed`, intégrant `TextTheme` et `ColorScheme` Material 3.

2. **Extensions Dart sur les Enums de Rareté** :
   - Getter `.color` sur `CardRarity` (extension `CardRarityColor`) et sur `RelicRarity` (extension `RelicRarityColor`), définis en regard des maps dans `AppColors`.
   - Usage : `card.rarity.color` ou `relic.rarity.color` directement dans n'importe quel widget.

3. **Correction du Bug `GameButton` (`RenderFlex` overflow)** :
   - Diagnostic : Le layout `Row([Icon, Text])` débordait quand `text == null` dans des contextes de layout contraints.
   - Solution : `Flexible` wrappant le `Text`, `CrossAxisAlignment.center` sur le `Row`, et omission du `Text` du widget tree si absent.

4. **Refactoring `RelicsDialog` via l'Extension** :
   - Remplacement d'un `switch (rarity)` de 19 lignes par `relic.rarity.color`.

### Preuves dans le code
- `lib/ui/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart` : Module de design centralisé.
- `lib/models/data/card_data.dart` : Extension `CardRarityColor on CardRarity`.
- `lib/models/data/relic_data.dart` : Extension `RelicRarityColor on RelicRarity`.
- `lib/ui/widgets/game_button.dart` : Correction du layout `Row`.
- `lib/ui/widgets/relics_dialog.dart` : Remplacement du `switch` par `.color`.
- 104/104 tests passés, 0 erreur `dart analyze`.

### Conséquences
- ✅ **Source de Vérité Unique** : Toute la palette visuelle est définie en un seul endroit.
- ✅ **Cohérence Visuelle Garantie** : Impossible d'avoir deux couleurs différentes pour la même rareté dans deux composants distincts.
- ✅ **DRY** : Les `switch` de couleur dupliqués dans 4+ fichiers sont remplacés par un getter idiomatique Dart.
- ✅ **Bug corrigé** : Le `RenderFlex` overflow sur `GameButton` est résolu pour tous les formats d'écran.
- ⚠️ **Migration progressive** : Les widgets non encore migrés utilisent toujours des magic constants. La migration complète s'effectuera au fil des prochains sprints.

---

## 🃏 ADR-038 : Interface UX Combat — Blocage de Pioche, Tooltips Ciblés, Étoiles de Forge et Double Jauge HP (v0.1.00)

### Statut
✅ Accepté & Implémenté

### Contexte
Quatre problèmes d'expérience utilisateur distincts avaient été identifiés dans le combat de Hero's Draft lors de l'analyse UX Section 1 :

1. **Interactions prématurées lors de la pioche** : Les cartes distribuées depuis la pioche vers la main étaient immédiatement interactables dès leur instanciation, avant même de rejoindre leur emplacement final dans l'arc. Cela causait des sauts de position et des désalignements lors d'un survol ou d'un glissement prématuré.
2. **Tooltips intempestifs et peu informatifs** : Les infobulles de cartes s'affichaient au simple passage de la souris, encombrant l'écran pendant les phases de lecture ou de planification. De plus, leur contenu n'incluait pas les améliorations de forge appliquées, forçant le joueur à quitter l'arène pour consulter ses cartes.
3. **Surcharge visuelle et polices surdimensionnées** : Les icônes vectorielles translucides en arrière-plan des cartes (épées, boucliers) généraient un bruit visuel gênant. Les tailles de polices étaient jugées trop imposantes pour le ratio d'aspect de la carte, rendant les textes difficiles à lire sur mobile.
4. **Barre de vie statique peu expressives** : La `PlayerHealthBar` était un `StatelessWidget` avec une simple mise à jour de largeur, sans animation. Les dégâts et les soins n'avaient aucun effet cinétique distinct, nuisant au feedback sensoriel et à l'immersion du combat.

### Décision

#### 1. Verrouillage Tactile de Pioche (`isEnteringHand`)
- Ajouter un drapeau public `bool isEnteringHand = false` dans `CardComponent`.
- Tous les handlers d'entrée (`onTapDown`, `onDragStart`, `onHoverEnter`, `onHoverExit`, `onDragUpdate`) effectuent une garde `if (isEnteringHand) return;` immédiate.
- Dans `HerosDraftGame._applyDeckState()`, les nouvelles cartes sont instanciées avec `isEnteringHand = true`.
- Dans `_layoutHand()`, si `card.isEnteringHand`, la durée du `MoveEffect` est portée à `0.7s` (au lieu de `0.35s`). Un callback `onComplete` réinitialise le drapeau à `false`.

#### 2. Cycle de Vie des Tooltips de Combat (Focus-Only)
- Remplacer le déclenchement au survol par un déclenchement uniquement sur sélection active de la carte.
- Câbler `game.onShowTooltip()` dans `HerosDraftGame.setFocusedCard()` lorsqu'une carte est focalisée.
- Câbler `game.onHideTooltip()` lors de la défocalisation, du jeu d'une carte, ou du changement de phase de combat.
- Dans `card_component.dart`, enrichir `_buildDetailedDescription()` pour itérer sur `card.card.forgeUpgrades` et les concaténer sous forme de liste à puces formatée.

#### 3. Rénovation Esthétique des Cartes (Flame & Flutter)
- **Réduction du bruit de fond** : Supprimer l'instanciation et l'appel à `bgIconPainter` dans `card_text_renderer.dart` (Flame). Supprimer les icônes transparentes `Center` dans `ui_card.dart` (Flutter).
- **Diminution des polices** : Réduire toutes les tailles de polices de 10% à 20% de manière proportionnelle pour assurer la lisibilité sur petits écrans :
  - Flame : Titre `12→10.5`, Rareté `8→7.0`, Badges `8→7.0`, Description `9→8.0`, Valeurs `18→15.0`, Icônes `27→22.0`.
  - Flutter : Titre `12→10.5`, Rareté `9→8.0`, Badge `8→7.0`, Description `9→8.0`, Valeurs `18→15.0`, Icônes `25→20.0`.
- **Étoiles de forge** : Dessiner une rangée d'étoiles proportionnelles à la capacité maximale de forge de la carte sous le label de rareté. Les étoiles pleines dorées (`★`) représentent les upgrades actifs, les étoiles vides (`☆`) représentent les slots disponibles restants.

#### 4. Double Jauge de Vie Animée (`PlayerHealthBar` Dual-Bar)
- Convertir `PlayerHealthBar` de `StatelessWidget` en `StatefulWidget`.
- Maintenir localement `_targetRatio` (ratio courant) et `_oldRatio` (ratio précédent avant mise à jour).
- Lors de la réception d'un nouveau ratio :
  - Si le ratio **diminue** (dégâts) : la jauge verte d'avant-plan chute instantanément, la jauge rouge d'arrière-plan anime via `TweenAnimationBuilder` (500ms, `Curves.easeOutCubic`).
  - Si le ratio **augmente** (soin) : la jauge verte d'avant-plan anime fluide vers le haut, la jauge rouge s'aligne immédiatement pour éviter tout artefact de traînée inversée.

### Preuves dans le code
- `lib/game/components/card_component.dart` : Champ `isEnteringHand`, gardes d'input, appel `_buildDetailedDescription()` avec inject des forge upgrades.
- `lib/game/components/widgets/card_text_renderer.dart` : Suppression de `bgIconPainter`, réduction des tailles de police, boucle de dessin Canvas des étoiles.
- `lib/game/heros_draft_game.dart` : Set `isEnteringHand = true` dans `_applyDeckState`, durée `0.7s` dans `_layoutHand`, appel `onShowTooltip`/`onHideTooltip` dans `setFocusedCard`.
- `lib/ui/widgets/ui_card.dart` : Suppression des icônes de fond, réduction des polices, rangée d'icônes Flutter `Icons.star`/`Icons.star_border` sous le label de rareté.
- `lib/ui/widgets/hud/player_health_bar.dart` : Conversion `StatefulWidget`, champs `_targetRatio`/`_oldRatio`, `TweenAnimationBuilder` 500ms `Curves.easeOutCubic`, rendu dual-stack.
- **Vérification** : `dart analyze` 0 erreur. Suite complète de 104 tests — 100% au vert.

### Conséquences
- ✅ **Game Feel Immersif et Réactif** : Les cartes distribuées ne génèrent plus de sauts ni de désalignements. La double jauge donne une sensation d'impact physique convaincante aux dégâts reçus.
- ✅ **Lisibilité et Clarté Tactique** : Les tooltips apparaissent uniquement quand le joueur a une intention de lecture, et incluent désormais les upgrades de forge pour des décisions informées. Les polices réduites améliorent la densité d'information sans surcharge.
- ✅ **Transparence Systémique** : La jauge d'étoiles de forge matérialise visuellement le potentiel restant de chaque carte, guidant les stratégies de forge et de fusion sans quitter l'arène.
- ✅ **Architecture Préservée (ADR-001)** : Toute la logique de ratio HP reste dans les providers Riverpod (`runProvider`). `PlayerHealthBar` ne fait qu'observer et animer. `CardComponent` n'héberge aucune logique de calcul.
- ⚠️ **Cohérence Duale Flame/Flutter** : La réduction de polices et le rendu d'étoiles étant implémentés en parallèle dans `card_text_renderer.dart` (canvas Flame) et `ui_card.dart` (widgets Flutter), toute modification future des tailles ou du style des étoiles devra être propagée dans les deux systèmes de rendu simultanément.

---

## 🛠️ ADR-039 : Système de Forge v2 — Anti-Exploit, Filtrage Typé, Achat Progressif et Layout Plein Écran

### Statut
✅ Accepté & Implémenté (v0.2.00)

### Contexte
La version initiale du système de forge souffrait de plusieurs limitations ergonomiques et de failles d'exploitation logique :
1. **Faille d'exploitation (Save Scumming)** : Les options d'améliorations de forge étaient générées aléatoirement à chaque ouverture de la boîte de dialogue. Un joueur pouvait donc fermer le dialogue sans effectuer d'amélioration, puis le rouvrir à l'infini pour réinitialiser le tirage jusqu'à obtenir les options optimales.
2. **Pollution du pool d'améliorations** : Toutes les cartes accédaient au même pool d'upgrades global. Les cartes de type *Skill* (comme la *Potion de soin*) ou *Power* (comme la *Forme de rage*) se voyaient proposer des bonus offensifs physiques ou élémentaires (`sharp`, `burning`, etc.) inadaptés à leur rôle.
3. **Absence de progression et de débouché économique** : Les joueurs ne pouvaient pas étendre leur capacité de choix lors d'une session de forge, limitant les choix tactiques alors même qu'ils accumulaient d'importantes quantités d'or.
4. **Ergonomie dégradée sur petits écrans** : L'ancien popup de forge s'affichait mal sur mobile portrait/paysage, tronquant les listes d'options et créant des débordements visuels (`RenderFlex` overflow).

### Décision
1. **Anti-Exploit par Session Persistée** :
   - Sauvegarder la session active en persistant `forgeSlots` (liste d'upgrades sous format `id:tier`) et `forgeTargetCardId` (identifiant unique de la carte forgée) dans le `RunState` (Riverpod).
   - Lors de l'ouverture du dialogue, si `forgeTargetCardId == card.uniqueId`, le système restaure les slots stockés. Sinon, il effectue un nouveau tirage et appelle `setForgeSession()` pour le figer.
   - Effacer la session via `clearForgeSession()` uniquement sur réussite d'amélioration ou à la sortie définitive du camp de repos (`RestScreen._leave()`).
2. **Filtrage Intelligent Typé (Type-Safe Pools)** :
   - Restreindre le pool d'upgrades éligibles selon la catégorie de carte dans `ForgeUpgradeDialog` :
     - Les cartes `skill` excluent les améliorations offensives (`sharp`, `burning`, `freezing`, `shocking`).
     - Les cartes `power` n'autorisent que les améliorations utilitaires (`eco`, `quick`, `enduring`).
     - Les cartes `attack` conservent l'accès au pool complet d'upgrades.
3. **Achat de Fentes Progressif (Buy Slots)** :
   - Ajouter un attribut `bonusForgeSlots` dans `RunState` représentant le nombre de fentes achetées.
   - Permettre l'achat dynamique de slots supplémentaires (capé à 4 achats bonus, soit 5 slots de forge au total) avec une tarification progressive : 50 → 80 → 120 → 175 Or.
   - Mettre en place un bouton d'achat dynamique grisé ou désactivé si l'or du joueur est insuffisant ou si la capacité maximale de 5 slots est atteinte.
4. **Refonte Responsive Plein Écran** :
   - Remplacer l'overlay hérité par un dialogue plein écran (`Dialog.fullscreen`).
   - Adopter une structure responsive : disposition en deux colonnes (`Row`) sur desktop avec visuel de carte à gauche et upgrades scrollables à droite, et disposition verticale empilée (`Column`) sur mobile avec une liste scrollable (`ListView`).

### Preuves dans le code
- `lib/game/controllers/run_controller.dart` : Ajout de `forgeSlots`, `forgeTargetCardId` et `bonusForgeSlots` à `RunState`. Implémentation des méthodes `setForgeSession`, `clearForgeSession` et `buyBonusForgeSlot`.
- `lib/ui/widgets/forge_upgrade_dialog.dart` : Logique de vérification anti-exploit au `initState`, implémentation de `_getEligibleUpgradesForPool`, intégration de `Dialog.fullscreen`, structure adaptative `Row`/`Column` responsive, et bouton `_BuySlotButton` réactif.
- `lib/ui/screens/rest_screen.dart` : Appel à `clearForgeSession` lors du départ du camp de repos dans `_leave()`.
- `test/unit/run_controller_test.dart` : Ajout de tests unitaires couvrant la persistance, le nettoyage, et la validation de l'achat de slots bonus.

### Conséquences
- ✅ **Élimination de la Triche** : Le comportement de "save scumming" local est éradiqué ; le tirage est persistant et conservé au travers des ouvertures/fermetures de dialogues.
- ✅ **Cohérence Thématique de Deck-Building** : Les cartes de type *Skill* et *Power* conservent des pools d'upgrades cohérents avec leur rôle logique, améliorant la satisfaction et l'intérêt stratégique des choix de forge.
- ✅ **Nouveau Débouché Économique** : L'achat de fentes progressives offre un excellent évier à or ("gold sink") pour le milieu/fin de run, valorisant l'accumulation d'or et augmentant la liberté de personnalisation des cartes clés.
- ✅ **Ergonomie et Poli Visuel Premium** : La mise en œuvre de `Dialog.fullscreen` combinée au layout responsive supprime tout risque de clipping ou d'overflow sur mobile comme sur desktop, tout en mettant la carte modifiée au premier plan.
- ✅ **Garantie Fonctionnelle Continue** : L'ajout de tests unitaires dédiés porte la suite automatisée à **106 tests** au vert à 100%, garantissant l'intégrité de la logique métier.
- ⚠️ **Rigueur de Nettoyage de Session** : Il est impératif de s'assurer que `clearForgeSession()` soit appelé à chaque transition de nœud pour éviter de transporter des résidus de tirage ou de carte cible vers les nœuds de feu de camp suivants. (Garantie actuelle par RestScreen).

---

## 🎨 ADR-040 : Harmonie Visuelle & Améliorations de Boutique (Visual Harmony & Shop Improvements)

### Statut
✅ Accepté & Implémenté (v0.1.3)

### Contexte
La version 0.1.3 a introduit des améliorations axées sur l'ergonomie, la clarté visuelle et l'équilibrage de la boutique ("Shop & Economy") :
1. **Exclusion des cartes de rareté unique de la boutique** : Les cartes de rareté `unique` (les cartes de classe des héros) sont conçues pour être acquises via le draft de départ ou la forge, afin de préserver l'équilibre et de forcer des choix d'amélioration stratégiques. Elles risquaient cependant d'apparaître dans les pools de cartes proposés à la vente dans la boutique, créant des déséquilibres d'acquisition (Item #103).
2. **Identification visuelle lente en main/boutique** : Auparavant, les cartes de tous types (Attaque, Compétence, Pouvoir, Statut) partageaient le même arrière-plan générique sombre, ce qui ralentissait l'identification à la volée. L'UX en combat et dans la boutique exigeait une différenciation sémantique plus claire (Item #115).
3. **Erreurs de mise en page en boutique** : L'affichage des cartes en vente dans la boutique souffrait de défauts d'alignement ou d'overflow sur différents facteurs de forme, nécessitant un réalignement propre sous forme de grille uniforme et fluide (Item #99).

### Décision
1. **Exclusion des cartes uniques de la boutique** :
   - Mettre à jour la méthode helper `_getEligibleCards` dans `ShopController` pour filtrer à la fois les cartes de type `status` et celles de rareté `CardRarity.unique`.
   - Garantir que lors de l'initialisation initiale (`initializeShop`), du renouvellement (`rerollCards`), ou de l'expansion de boutique (`expandShop`), aucune carte de classe unique ne soit tirée au sort.
2. **Coloration d'arrière-plan par type dans `UiCard`** :
   - Ajouter la méthode helper `_getTypeColor()` renvoyant les couleurs d'accent de type : `Colors.redAccent` (Attaque), `Colors.blueAccent` (Compétence), `Colors.amber` (Pouvoir), `Colors.blueGrey` (Statut).
   - Ajouter la méthode helper `_getBackgroundColor()` renvoyant les couleurs de fond associées : `Color(0xFF4A1D1D)` (Attaque), `Color(0xFF152A4A)` (Compétence), `Color(0xFF453215)` (Pouvoir), `Color(0xFF2D2D2D)` (Statut), et `Color(0xFF2A2A3D)` par défaut.
   - Rendre le fond du widget de carte dynamique en passant un dégradé `LinearGradient` basé sur le `bgColor` et `bgColor.withAlpha(200)` au conteneur principal. Le contour (`border`) prend la couleur d'accent du type.
3. **Mise en page stable de la boutique (Wrap Grid)** :
   - Remplacer les dispositions rigides ou floues par un conteneur `Wrap` avec un espacement défini (`spacing: 12`, `runSpacing: 20`) dans `ShopScreen` pour présenter le catalogue des cartes en vente.
   - Envelopper chaque composant de carte (`_ShopCardItem`) dans un `SizedBox` de largeur fixe `150` pour imposer des dimensions de grille rigoureuses et une répartition adaptative sans overflow.

### Preuves dans le code
- `lib/game/controllers/shop_controller.dart` : Filtre `c.rarity != CardRarity.unique` appliqué au pool global de cartes de la boutique.
- `lib/ui/widgets/ui_card.dart` : Méthodes `_getTypeColor` et `_getBackgroundColor` câblées au build de `UiCard`.
- `lib/ui/screens/shop_screen.dart` : Utilisation de `Wrap` et `SizedBox(width: 150)` pour le positionnement harmonieux en grille.
- **Vérification** : `dart analyze` exempt d'erreurs, suite de 106 tests automatisés validée verte.

### Conséquences
- ✅ **Respect du Gameplay System** : Les cartes spécifiques à un héros ne polluent plus le pool de la boutique, renforçant la spécificité des mécaniques de forge et de fusion de départ.
- ✅ **Confort de Lecture Amélioré (Cognitive Load Reduction)** : Les couleurs de fond thématiques permettent une identification immédiate du type de carte, rendant le combat et le choix d'achat plus fluides et rapides.
- ✅ **Grid Layout Impeccable** : Le comportement adaptatif du Wrap élimine tout risque d'overflow horizontal ou vertical sur mobile ou desktop, avec des cartes parfaitement alignées dans leur contrainte SizedBox.

---

## 🗺️ ADR-041 : Système de Level Up Différé sur la Carte & Bloquant (Deferred Level Up & Interaction Blocking on Map)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
Dans l'implémentation précédente, lorsqu'un joueur passait un niveau (gain d'XP post-combat), l'écran de draft (`DraftScreen`) s'affichait instantanément sous forme d'un overlay par-dessus le combat. Ce flux créait des conflits visuels avec les transitions de fin de combat, forçait le joueur à faire un choix de carte avant même de voir le récapitulatif global des gains (or, reliques, etc.), et encombrait le cycle de vie du `GameScreen`.

### Décision
Déporter le déclenchement du Draft de montée de niveau sur la carte du monde (`MapScreen`) de manière différée et bloquante :
1. **Suivi d'État Métier (`pendingDrafts`)** :
   - Ajouter un entier `pendingDrafts` dans `RunState`.
   - Lors d'une montée de niveau dans `RunController.gainXp(int xp)`, au lieu d'ouvrir directement un écran, incrémenter `pendingDrafts`.
   - Fournir les méthodes `decrementPendingDrafts()` et `resetPendingDrafts()` dans le contrôleur.
2. **Découplage de fin de combat** :
   - Modifier `GameScreen` pour que la fin de combat (`_presentNextReward` / `_completeAndExitCombat`) ignore l'affichage immédiat du draft et renvoie le joueur directement à la carte.
   - Retirer le composant `DraftScreen` des overlays du jeu de combat.
3. **Overlay d'Alerte Bloquant sur la Carte (`MapScreen`)** :
   - Si `runState.pendingDrafts > 0`, afficher un overlay d'animation "LEVEL UP !" recouvrant tout l'écran de la carte.
   - Bloquer la navigation et les clics sur tous les nœuds de la carte tant que `pendingDrafts` n'est pas résolu.
   - Un clic sur l'overlay "LEVEL UP !" pousse l'écran de draft standard (`DraftScreen`) via le routeur. Lorsque le draft se termine (choix d'une carte ou passe), `decrementPendingDrafts()` est appelée, et si le compteur descend à 0, l'overlay est masqué, rendant les nœuds de la carte à nouveau interactifs.

### Preuves dans le code
- `lib/game/controllers/run_controller.dart` : Ajout et gestion du champ `pendingDrafts` dans `RunState` et `RunController`.
- `lib/ui/screens/map_screen.dart` : Affichage conditionnel de l'overlay `LevelUpOverlay`, interdiction de clic sur les nœuds, et transition vers `DraftScreen`.
- `lib/ui/screens/game_screen.dart` : Retrait de l'overlay de draft et routage de sortie directe sur montée de niveau.
- `lib/ui/screens/draft_screen.dart` : Retrait de l'appel direct à `nextLevel` (désormais géré lors de la sortie du nœud de combat).

### Conséquences
- ✅ **Rythme de Jeu Naturel** : La transition de fin de combat est plus fluide. Le joueur retourne d'abord à la carte, visualise sa position, puis est célébré avec sa montée de niveau.
- ✅ **Gestion des Niveaux Multiples** : Si le joueur gagne plusieurs niveaux d'un coup (combat de boss), `pendingDrafts` s'incrémente plusieurs fois, et l'overlay réapparaîtra séquentiellement sur la carte pour proposer autant de tirages de draft que nécessaire.
- ✅ **Stabilité des États** : L'état du combat est entièrement purgé avant le draft, réduisant les risques d'incohérence mémoire.

---

## 🎡 ADR-042 : Protection Anti-Spoil dans le Carrousel de Reliques & Décoration Dynamique (Relic Carousel Rarity Masking & Polish)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
Le système de carrousel de récompense de reliques (`RelicRewardCarouselOverlay`) simule une machine à sous pour introduire du suspense. Cependant, dans la version précédente, les cartes du carrousel affichaient dès le départ la couleur de leur rareté, le nom réel de la relique et ses badges d'effets/déclencheurs. Cela gâchait l'effet de surprise ("spoil"), car le joueur devinait instantanément la relique cible et sa rareté pendant le spin.

### Décision
Mettre en place un masquage d'informations tant que le carrousel tourne :
1. **État local de Masquage (`isWon`)** :
   - Passer un paramètre booléen `isWon` à `RelicCarouselCard`.
   - Tant que `isWon` est faux (le carrousel est en cours de spin) :
     - La bordure et l'arrière-plan de la carte de relique sont grisés/neutres (`AppColors.neutralGrey`).
     - Les badges de rareté et de déclencheur affichent textuellement « ??? » sur fond gris neutre.
     - Le titre de rareté de l'en-tête supérieur du dialogue est masqué.
2. **Animation de Révélation au Point d'Arrêt** :
   - Lorsque le carrousel ralentit et s'immobilise sur le gagnant, le drapeau `isWon` passe à vrai.
   - Les vraies couleurs de rareté de la carte s'allument avec un effet de lueur.
   - Le texte de description, le nom réel (coloré selon la rareté) et les badges techniques de déclencheurs sont révélés de manière dynamique.
   - L'en-tête supérieur de la page s'anime pour afficher fièrement la rareté correspondante.

### Preuves dans le code
- `lib/ui/widgets/relic_carousel/relic_carousel_card.dart` : Rendu conditionnel basé sur `isWon`, utilisation d'une bordure grise neutre si faux, affichage de "???" pour les badges, et coloration textuelle du nom selon la rareté si vrai.
- `lib/ui/widgets/relic_carousel/relic_carousel_screen.dart` : Masquage du sous-titre de rareté en cours de rotation, activation progressive à la complétion.

### Conséquences
- ✅ **Suspense Décuplé** : Le joueur assiste à un défilement de silhouettes grises anonymes et ne découvre la relique exacte et sa valeur qu'à la frame précise de l'arrêt, maximisant le plaisir de la récompense.
- ✅ **Clarté UX** : L'accentuation par couleur de rareté uniquement sur l'objet gagné clarifie visuellement la transaction.

---

## 🗺️ ADR-043 : Génération Dynamique du Goulot d'Étranglement Central (Dynamic Central Chokepoint Generation)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
L'algorithme de génération de carte procedural (`MapGeneratorService`) forçait un nœud unique de type Combat Élite au niveau 5 (chokepoint obligatoire). Cette valeur était codée en dur (`y == 5`), ce qui empêchait de modifier la hauteur globale de la carte (`floors`) pour des besoins de gameplay (ex: tutoriel court de 4 étages ou runs étendues de 15 étages).

### Décision
Calculer le goulot d'étranglement central de manière dynamique :
- Déterminer l'étage du milieu par la division entière de la hauteur totale : `middleFloor = floors ~/ 2`.
- Appliquer ce `middleFloor` dynamique dans `generateMap` pour forcer le chokepoint Élite unique.
- Adapter les fonctions de validation de quotas (`_balanceQuotas`) et d'anti-répétition (`_optimizeMapTypes` / `_hasThreeConsecutive`) pour exclure et protéger cet étage dynamique.

### Preuves dans le code
- `lib/services/map_generator_service.dart` : Remplacement de la constante `5` par `middleFloor` calculé via `floors ~/ 2` dans toutes les passes de traitement (génération, quotas, optimisation).

### Conséquences
- ✅ **Flexibilité Dimensionnelle** : Le moteur supporte désormais n'importe quelle taille de carte sans planter ni générer des topologies orphelines, tout en garantissant un affrontement Élite à mi-chemin.

---

## 🃏 ADR-044 : Refonte Visuelle et Structurelle des Cartes (Unified Glassmorphic Card UI)

### Statut
✅ Accepté & Implémenté (v0.1.5)

### Contexte
L'interface visuelle d'un jeu de cartes comme Hero's Draft est cruciale pour le game feel et la clarté tactique. La version précédente souffrait de plusieurs limitations :
1. Les cartes possédaient un motif en filigrane (watermark) en arrière-plan et des badges de ciblage textuels encombrants (Single target, All enemies, Self), ce qui surchargeait visuellement l'interface et limitait la lisibilité des descriptions.
2. Les améliorations de forge étaient représentées par des étoiles dorées basiques, ne donnant aucune indication sur la nature de l'upgrade appliqué.
3. Le coût en mana était affiché sous forme de cristaux ou de gemmes positionnés de manière incohérente entre le moteur Flame et les widgets de l'interface Flutter (UiCard).
4. La taille des cartes était trop grande, provoquant des encombrements d'écran sur les petites résolutions.
5. Les labels textuels indiquant explicitement la rareté de la carte (ex: "COMMUNE", "LÉGENDAIRE") encombraient la face avant de la carte, alors que la couleur de la carte devrait suffire à communiquer cette information de manière immédiate et intuitive.

### Décision
Mettre en œuvre une refonte visuelle majeure et unifiée pour le rendu des cartes dans les couches Flutter (`UiCard`) et Flame (`CardComponent` et `CardTextRenderer`) :
1. **Style Glassmorphic Unifié** :
   - Application d'un arrière-plan semi-transparent avec dégradé vertical (opacité `0.6` en haut à `0.2` en bas) et floutage d'arrière-plan de 10px (`BackdropFilter` et `ImageFilter.blur`).
   - Lissage des bordures avec une épaisseur fine (de `1.5` à `2.5` si sélectionné) et une opacité réduite (`0.5` de la couleur du type de carte) pour un style moderne.
   - Suppression totale du filigrane (watermark) arrière-plan.
2. **Médaillon de Coût Mana Standardisé** :
   - Affichage du coût dans un cercle de rayon 12px positionné dans le coin supérieur gauche, de couleur sombre (`0xFF0D1B2A`), orné d'un liseré et d'un halo de lueur cyan. Standardisé à l'identique entre le moteur Flame et les widgets Flutter.
3. **Fentes de Runes (Rune Sockets) avec Retour à la Ligne** :
   - Remplacement des étoiles dorées par des emplacements circulaires représentant la capacité de forge (`baseMaxForgeUpgrades + rarityIndex`).
   - Chaque emplacement vide est un cercle blanc translucide (`0.05` d'opacité).
   - Les upgrades appliqués affichent l'émoji/rune correspondant à l'amélioration (⚔️ pour `sharp`, 🛡️ pour `hardened`, 🔥 pour `burning`, etc.), rendant les cartes auto-documentées visuellement.
   - **Retour à la ligne automatique (Multi-row Wrapping)** : Pour éviter que les fentes ne dépassent de la largeur de la carte (notamment pour les cartes de haute rareté et les cartes uniques qui peuvent avoir jusqu'à 5+ upgrades), les sockets sont disposés sur plusieurs lignes avec un maximum de 5 fentes par rangée.
     - **Couche UI (Flutter `UiCard`)** : Utilisation d'un widget `Wrap` à espacement défini (`spacing: 2.0`, `runSpacing: 2.0`) contraint à l'intérieur d'une `SizedBox` de largeur fixe `45.0` pixels, forçant un wrap automatique au-delà de 5 fentes (`5 * 7px + 4 * 2px = 43px`).
     - **Couche Rendu (Flame `CardTextRenderer`)** : Calcul manuel de positionnement sur Canvas à l'aide d'une boucle imbriquée (`numRows = (totalSlots + 4) ~/ 5` et `maxSlotsPerRow = 5`) pour centrer chaque ligne horizontalement et les empiler verticalement en décalant l'ordonnée Y de `16` pixels (`socketDiameter 14.0 + spacing 2.0`) par rangée.
4. **Réduction d'Échelle de 25%** :
   - Dimensions réduites à `140 × 196` (ratio `70/110`) dans `GameConstants` pour offrir une disposition plus compacte.
5. **Suppression des Badges de Ciblage & Doublement d'Icônes** :
   - Retrait des badges textuels de ciblage (Single target, All enemies, Self) pour alléger l'UI.
   - **Remplacés par des indicateurs double-icône (double-icon indicators)** : Pour les cartes ciblant tous les ennemis, le doublement d'icône d'effet s'applique uniquement aux effets offensifs ou destinés à l'ennemi (ex: double icône d'épée ⚔️⚔️ pour les dégâts AoE, ou doublement d'icônes de débuffs). En revanche, les effets ciblant le joueur/héros (tels que le gain d'armure, de soin, de mana, la pioche, ou les buffs de statut comme `strength`, `strength_regen` et `armor_regen`) restent représentés par une icône simple, puisqu'ils ne ciblent pas individuellement chaque ennemi.
6. **Suppression du Label de Rareté & Identification par Code Couleur et Halo (Color-Coded Rarity & Glow)** :
   - Retrait complet de l'affichage textuel de la rareté (ex: "Commune", "Rare", "Légendaire") sur la face avant de la carte.
   - La rareté est communiquée de façon purement visuelle via la couleur de sa bordure fine (`rarityColor.withValues(alpha: 0.5)`) et par un halo de surbrillance/glow radial coloré (`rarityColor.withValues(alpha: 0.4)` avec un rayon de flou de 15px et de diffusion de 4px) lorsque la carte est activement sélectionnée (`isSelected == true`).
   - Encadrement de l'infobulle (tooltip) de combat par une bordure reprenant la couleur de la rareté de la carte avec une épaisseur de `1.5` pour lier sémantiquement l'infobulle à la carte.
7. **Couleurs d'Arrière-Plan Typées pour le Rendu Combat (Flame)** :
   - Les cartes de combat dans l'arène de jeu (Flame `CardComponent`) ont été mises à jour pour utiliser des couleurs d'arrière-plan thématiques spécifiques à leur type (type-specific background colors), calquant le style des cartes de menu (`UiCard`) : rouge sombre (`0xFF4A1D1D`) pour les attaques, bleu marine profond (`0xFF152A4A`) pour les compétences, bronze sombre (`0xFF453215`) pour les pouvoirs et gris sombre (`0xFF2D2D2D`) pour les statuts.
8. **Mise à Jour des Tests** :
   - Réécriture des tests d'interface dans `hud_and_targeting_badge_test.dart` pour s'assurer que les anciens badges textuels n'apparaissent plus, valider le doublement des icônes d'action pour la portée multicible sur les effets offensifs, et confirmer le maintien d'une icône simple pour les effets bénéfiques au joueur.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Rendu du gradient glassmorphic, médaillon flottant en haut à gauche, `runeSocketsRow` remplaçant les étoiles, suppression de `_buildTargetIcon` et implémentation du doublement filtré de `visuals.icon` si `isAllEnemies == true` et que `!isPlayerEffect` est vrai. Utilisation de `rarityColor` pour les bordures, le glow de sélection, et la bordure du tooltip, sans rendu textuel du paramètre `rarity`.
- `lib/game/components/card_component.dart` : Rendu sur canvas Flame de la bordure fine (`rarityColor.withValues(alpha: 0.5)`) et du halo de sélection (`glowPaint..color = rarityColor.withValues(alpha: 0.4)..maskFilter = MaskFilter.blur(BlurStyle.outer, 8)`), sans appel de texte de rareté dans `CardTextRenderer`, et implémentation de `getBackgroundColor()` associant chaque type de carte à son code couleur sombre.
- `lib/game/components/widgets/card_text_renderer.dart` : Rendu vectoriel sur canvas Flame reproduisant fidèlement le médaillon mana (cercle 12px, cyan border), la ligne de rune sockets sur plusieurs rangées avec retour à la ligne (wrapping) par rangées de 5 (décalage vertical de 16 pixels), et le doublement sélectif des icônes de statut/dégâts (filtré par `!isPlayerEffect`).
- `test/widget/hud_and_targeting_badge_test.dart` : Assertions sur `findsNothing` pour les badges textuels, `findsNWidgets(2)` pour les effets offensifs AoE et `findsOneWidget` pour les effets appliqués au joueur sur la même carte.

### Conséquences
- ✅ **Expérience Esthétique Premium** : Le design glassmorphic et le médaillon cyan procurent un game feel plus propre et professionnel.
- ✅ **Lisibilité Accrue & Précision Tactique** : La suppression du filigrane, des badges textuels de ciblage et des labels de rareté textuels réduit considérablement le bruit visuel et simplifie l'assimilation des informations de la carte.
- ✅ **Identification Sémantique Instantanée** : L'utilisation de codes couleur de rareté pour la bordure, le halo de sélection et l'infobulle permet d'identifier immédiatement la valeur d'une carte sans avoir recours à du texte.
- ✅ **Auto-Documentation Graphique & Zéro Débordement (Wrapping)** : L'affichage des runes d'améliorations (émojis) avec wrapping automatique par rangées de 5 (rows of 5) permet d'identifier les upgrades appliqués de manière ordonnée sans déborder des contours de la carte, même pour les cartes uniques hautement améliorées.
- ✅ **Grid Layout Stable & Uniformité Totale** : La réduction d'échelle élimine le risque d'overflow ou d'encombrement graphique sur petit écran, tandis que l'application des couleurs de fond typées sur les cartes Flame en combat garantit l'alignement graphique avec les menus Flutter.

---

## 🛠️ ADR-045 : Décomposition et Découplage de la God Class `UiCard` (UiCard Decomposition & Decoupling)

### Statut
✅ Accepté & Implémenté (v0.2.01)

### Contexte
Le widget `UiCard` (`lib/ui/widgets/ui_card.dart`) est central pour l'affichage de toutes les cartes à jouer dans l'interface Flutter (menus, boutique, draft, dictionnaire). En raison des refontes esthétiques successives (v0.1.5), ce widget a accumulé de nombreuses responsabilités :
1. Analyse et parsing de la cible de la carte (`_resolveTarget`).
2. Résolution dynamique du type d'élément et des dégâts (`_determineDamageType`).
3. Mappage des icônes et couleurs d'effets (`_getEffectVisuals`).
4. Formatage et mise en page complexe de la description abrégée sous forme de badges (`_buildCompactDescription`).
5. Construction verbeuse de la description textuelle multilingue pour les infobulles / tooltips (`_buildDetailedDescription`).
6. Rendu visuel direct des fentes de runes, du médaillon de mana, et du type de carte.
7. Rendu et gestion d'animation personnalisée de la bordure polychromatique brillante au survol (`PolychromaticBorder` et son painter).

Cette concentration de logique et d'affichage au sein d'un seul fichier de plus de 1130 lignes violait le principe de responsabilité unique (SRP), créait une forte dette technique ("god component"), et rendait le composant difficile à maintenir et à faire évoluer.

### Décision
Décomposer et découpler `UiCard` en extrayant ses sous-composants visuels et ses fonctions logiques pures dans un sous-dossier dédié `lib/ui/widgets/ui_card/` :
1. **Création de `ui_card_helpers.dart`** : Centralisation de l'ensemble des fonctions pures et des mappages de données (résolution de cible, détection d'élément, couleur des types, couleurs de rareté, emojis de runes, et construction du texte détaillé pour le tooltip) afin d'isoler la logique du cycle de vie des widgets.
2. **Création de `polychromatic_border.dart`** : Encapsulation de la bordure animée (`PolychromaticBorder` et `_PolychromaticBorderPainter`), retirant la gestion du ticker de la classe principale.
3. **Création de `card_mana_medallion.dart`** : Extraction de l'indicateur circulaire de coût sous forme de widget autonome layout-agnostique.
4. **Création de `card_rune_sockets.dart`** : Extraction du widget de gestion et d'agencement multi-lignes des emplacements d'upgrades.
5. **Création de `card_compact_description.dart`** : Extraction du layout d'affichage abrégé des effets et des modificateurs de forge sous forme de widget dédié.
6. **Simplification de `ui_card.dart`** : Le widget principal sert de couche d'assemblage et de composition ("facade") pour ces sous-widgets. Son code est réduit de plus de 80% (de 1136 à ~175 lignes).
7. **Préservation de l'Interface Publique** : Conservation de l'exactitude du constructeur de `UiCard` et de ses paramètres originaux pour éviter toute modification des fichiers externes (boutique, draft, dictionnaire) qui l'instancient.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Importe et compose `PolychromaticBorder`, `CardManaMedallion`, `CardRuneSockets` et `CardCompactDescription`. Le fichier ne contient plus aucune méthode de rendu privée ni calcul d'icône.
- `lib/ui/widgets/ui_card/` : Dossier contenant les 5 nouveaux fichiers extraits et découplés de manière modulaire.
- `test/widget/hud_and_targeting_badge_test.dart` et `test/widget/shop_screen_test.dart` : Passent sans modification des tests unitaires ni des widgets, prouvant le respect total de l'interface d'instanciation de `UiCard`.

### Conséquences
- ✅ **Respect du Single Responsibility Principle (SRP)** : Chaque sous-composant gère sa propre structure et logique, réduisant la complexité cognitive.
- ✅ **Facilité de Maintenance** : Le code de `UiCard` est réduit à ~175 lignes claires et lisibles. Toute modification future de l'affichage du coût, des sockets ou de la description se fera dans un fichier dédié.
- ✅ **Testabilité Accrue** : Les fonctions d'aide de `ui_card_helpers.dart` sont pures et isolées, facilitant leur test unitaire direct.
- ✅ **Zéro Régression** : La compatibilité de la signature du constructeur a garanti une intégration sans impact sur les 107 tests existants de l'application.

---

## 🛠️ ADR-046 : Effet de Bordure Foil Progressif pour les Cartes Uniques (Progressive Unique Card Border Foil Effect)

### Statut
✅ Accepté & Implémenté (v0.2.02)

### Contexte
Les cartes de classe uniques dans *Hero's Draft* représentent des éléments précieux du deck du joueur. Pour valoriser visuellement l'accumulation d'améliorations de forge appliquées à ces cartes de classe uniques, nous souhaitions introduire un effet visuel dynamique (foil / polychromatique) qui s'enrichit et progresse au fur et à mesure que la carte reçoit des runes de forge.

### Décision
Modifier le composant de bordure polychromatique (`PolychromaticBorder`) et le widget `UiCard` pour injecter dynamiquement le nombre d'améliorations appliquées à la carte (`forgeUpgrades.length`) et adapter la palette de couleurs de l'effet de balayage arc-en-ciel :
1. **Passage de `upgradeCount`** : Modifier le widget `UiCard` pour qu'il calcule `upgradeCount = forgeUpgrades.length` et le passe au composant `PolychromaticBorder`.
2. **Acceptation de `upgradeCount`** : Ajouter la propriété `upgradeCount` (valeur par défaut `0`) dans `PolychromaticBorder` et son painter associé `_PolychromaticBorderPainter` pour assurer une rétrocompatibilité complète avec les composants existants.
3. **Calcul Dynamique des Couleurs** : Dans `_PolychromaticBorderPainter._getRarityShineColors`, lorsque la carte est `unique`, définir un pool de 10 couleurs distinctes ordonnées :
   - Couleur de base Unique (Gold / `#FFD700`)
   - Couleur Commune (`Colors.white70`)
   - Couleur Atypique (`Colors.greenAccent`)
   - Couleur Rare (`Colors.blueAccent`)
   - Couleur Épique (`Colors.purpleAccent`)
   - Couleur Légendaire (`Colors.orangeAccent`)
   - Rouge (`Colors.red`)
   - Jaune (`Colors.yellow`)
   - Cyan (`Colors.cyan`)
   - Rose (`Colors.pink`)
4. **Calcul de la Sélection** : Sélectionner dynamiquement un sous-ensemble de taille `(upgradeCount + 1).clamp(1, 10)` à partir de ce pool.
5. **Bouclage Seamless** : S'assurer que le premier élément sélectionné est répété à la fin du tableau pour garantir un fondu de gradient linéaire tournant parfaitement fluide.
6. **Mise à jour de `shouldRepaint`** : Ajouter la vérification `oldDelegate.upgradeCount != upgradeCount` pour forcer le repeint du CustomPainter lorsque le nombre d'améliorations change.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Instancie `PolychromaticBorder` avec `upgradeCount: forgeUpgrades.length`.
- `lib/ui/widgets/ui_card/polychromatic_border.dart` : Intègre la logique de pool progressif de 10 couleurs, de clamp de sélection et de duplication de fin.
- `dart analyze` : Renvoie `No issues found!`.
- `flutter test` : Valide l'intégralité des 107 tests existants au vert.

### Conséquences
- ✅ **Feedback Visuel de Puissance** : Le joueur constate l'impact immédiat et la rareté de ses runes de forge à travers l'apparition progressive de nouvelles teintes chromatiques au survol de la carte (d'un simple halo doré à 0 upgrade vers un arc-en-ciel complet et vibrant à 5+ upgrades).
- ✅ **Modularité Intacte** : La logique esthétique reste isolée au sein de `PolychromaticBorder` sans alourdir le widget parent `UiCard`.
- ✅ **Rétrocompatibilité Totale** : La valeur par défaut de `upgradeCount = 0` permet l'utilisation du composant sur des cartes n'ayant pas d'améliorations ou n'exposant pas cette propriété sans provoquer d'erreurs d'initialisation.

---

## 🛠️ ADR-047 : Résolution des Armures de Forge sur Attaque et Persistance/Visualisation du Gel (v0.1.6)

### Statut
✅ Accepté & Implémenté (v0.1.6)

### Contexte
1. L'amélioration d'armure de la forge (`hardened`), lorsqu'elle est appliquée à des cartes d'attaque (qui ne possèdent pas d'effet d'armure natif dans leurs `CardEffect`), ne produisait aucun bouclier en combat car la logique de résolution n'augmentait l'armure du héros que si la carte contenait déjà un effet d'armure natif.
2. Le statut de gel (`freeze`), destiné à diviser par deux les dégâts de la prochaine attaque de l'ennemi, expirait prématurément au début du tour de l'ennemi lors du déclenchement de `tickStatuses()`, avant que celui-ci ne puisse exécuter son action d'attaque.
3. L'affichage des intentions d'attaque de l'ennemi ne reflétait pas visuellement la réduction de 50% des dégâts lorsque celui-ci était gelé, créant une incohérence entre les dégâts affichés dans le HUD et les dégâts réellement subis par le héros à l'impact.

### Décision
1. **Application Directe d'Armure** : Modifier `EffectResolver.resolveCard` pour vérifier si la carte jouée possède de l'armure additionnelle issue de la forge (`extraArmor > 0`) et ne contient aucun effet d'armure natif. Si c'est le cas, appliquer directement cette `extraArmor` aux statistiques d'armure du héros via `runController.setHeroStats()`.
2. **Exemption du Gel au Début du Tour** : Modifier `tickStatuses()` dans `EntityStats` pour ignorer le statut `freeze`, lui évitant ainsi d'être décrémenté et dissipé au début du tour ennemi.
3. **Calcul Visuel de l'Intention Gelée** : Mettre à jour le getter `effectiveIntent` dans `EnemyInstance` pour diviser par deux (avec arrondi au plus proche) la valeur des dégâts de l'intention offensive lorsque l'ennemi possède le statut `freeze`.
4. **Consommation de l'Effet post-attaque** : Ajuster `resolveEnemyIntent` dans `CombatController` pour décrémenter de 1 la durée du statut de gel après la résolution de l'attaque de l'ennemi (puisqu'il a consommé son action offensive sous gel) tout en veillant à ne pas appliquer à nouveau la réduction de 50% (l'intention ayant déjà été pré-réduite par `effectiveIntent`).

### Preuves dans le code
- `lib/game/services/effect_resolver.dart` : Résolution directe d'armure si `extraArmor > 0` et absence d'effet d'armure.
- `lib/models/entity_stats.dart` : Ignorance du statut `freeze` dans la méthode `tickStatuses()`.
- `lib/models/enemy_instance.dart` : Division par deux de l'intention de dégâts d'attaque dans `effectiveIntent` si l'ennemi est gelé.
- `lib/game/controllers/combat_controller.dart` : Retrait de la double réduction dans `resolveEnemyIntent` et décrémentation de la durée du gel après l'action de l'ennemi.

### Conséquences
- ✅ **Comportement Fiable de la Forge** : Les joueurs peuvent désormais forger des cartes d'attaque avec de l'armure et bénéficier correctement de cette protection en combat.
- ✅ **Tactique du Gel Préservée** : Le gel réduit de manière effective la prochaine action offensive de l'ennemi au lieu d'expirer dans le vide au début de son tour.
- ✅ **Lisibilité de l'Intention** : La signalétique des intentions affiche en temps réel les dégâts exacts que le joueur subira (tenant compte du gel), améliorant la prise de décision stratégique.
- ✅ **Tests & Qualité** : Les 107 tests du projet s'exécutent avec succès et l'analyse statique de compilation est vierge.

---

## 🎨 ADR-048 : État Critique Déterministe, Nombres Flottants Néon et Décélération de Jauge HP (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. L'ancien déclenchement des effets visuels de coup critique en combat reposait sur un calcul imprécis ou des seuils de dégâts arbitraires dans la couche de rendu. Il n'y avait pas de propagation déterministe de l'état "critique" depuis la logique de calcul de combat vers la couche Flame.
2. Les textes flottants d'effets et de dégâts (`FloatingText`) manquaient d'identité graphique et de dynamisme. Les critiques, le poison et le bouclier n'avaient pas de style distinctif en dehors de la valeur textuelle brute.
3. L'animation de dégâts de la jauge de vie du joueur (`PlayerHealthBar`) descendait trop rapidement (500ms), ce qui masquait l'intensité et le choc visuel des attaques subies lors des affrontements tendus.

### Décision
1. **Propagation de l'État Critique Déterministe** : Intégrer un champ booléen `lastActionWasCrit` dans le modèle d'état `EntityStats`. Ce flag est résolu à chaque calcul offensif ou curatif dans `EffectResolver` ou `CombatController` (grâce à des jets de chance critique) et stocké dans l'état Riverpod. Les composants Flame s'y synchronisent via `newStats.lastActionWasCrit` pour déclencher les tremblements prononcés (magnitude 28.0), les flashs dorés (`0xFFF59E0B`) et les 35 particules.
2. **Textes Flottants Premium & Néon** : Refondre `FloatingText` pour supporter :
   - *Ombres Néon Thématiques* : Orange/Rouge brillant pour critique, Vert pour poison, Cyan/Bleu pour bouclier.
   - *Rotation & Trajectoire* : Une rotation aléatoire de départ ($\pm 0.15$ rad) et une dérive en arc. Le poison bénéficie en plus d'une oscillation sinusoïdale horizontale dans sa méthode `update` pour simuler un gaz.
   - *Séquence d'Échelle de Critique* : Un effet séquentiel (`SequenceEffect`) composé d'un pop élastique initial à 1.5x (`Curves.elasticOut` en 350ms), d'une redescente à 1.15x, puis d'une pulsation de zoom/dézoom infinie (1.15x ⇄ 1.3x en 300ms) pour attirer l'attention du joueur.
   - *Préfixes Textuels* : Ajout automatique de `"💥 CRIT "`, `"🧪 "` ou `"🛡️ "` et calibrage de la taille de police (36 critique, 22 poison, 26 armure).
3. **Décélération de Jauge HP sous Dégâts** : Paramétrer dynamiquement la durée et la courbe d'animation de `PlayerHealthBar` dans `didUpdateWidget()`. Sous dégâts, la jauge verte descend instantanément tandis que la jauge rouge de catch-up met désormais **1200ms** à se vider avec une courbe de décélération `Curves.easeOut` pour matérialiser la gravité du coup. Pour le soin, la jauge rouge s'aligne immédiatement et la jauge verte remonte de manière fluide en **500ms**.

### Preuves dans le code
- `lib/models/entity_stats.dart` : Intégration de `lastActionWasCrit` dans les schémas JSON et la méthode `copyWith`.
- `lib/game/components/entities/hero_card.dart` & `enemy_card.dart` : Synchronisation et déclenchement d'animations enrichies si `newStats.lastActionWasCrit` est vrai.
- `lib/game/components/floating_text.dart` : Ombres thématiques complexes, préfixes, rotation, cinématique d'échelle séquentielle pour critique, et oscillation sinusoïdale pour poison.
- `lib/ui/widgets/hud/player_health_bar.dart` : Alternance de durée (1200ms dégâts vs 500ms soin) et gestion de courbe `Curves.easeOut`.

### Conséquences
- ✅ **Respect de l'Architecture Découplée (ADR-001)** : La logique de calcul des critiques reste à 100% dans la couche métier (Riverpod). La vue (Flame) est passive et se contente de réagir au flag d'état propagé.
- ✅ **Ressenti Tactile Décuplé (Visual Juice)** : L'élasticité et les ombres néon des critiques ainsi que la traînée de dégâts ralentie de la jauge HP confèrent un impact dramatique et gratifiant aux combats.
- ✅ **Maintenance & Robustesse** : Les 107 tests du projet continuent de s'exécuter sans aucune régression.

---

## 🛡️ ADR-049 : Correction de la Relique Croc Kunaï (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. La relique Croc Kunaï (qui octroie +1 Maîtrise d'Armure toutes les 3 attaques jouées dans un tour) présentait un bug critique : son application altérait directement et définitivement la statistique `armorMastery` permanente du héros dans `RunState`. Cela entraînait une persistance anormale du bonus à l'issue du combat, faussant la courbe de puissance de l'armure pour le reste de la run.
2. Il manquait un mécanisme propre pour appliquer et agréger des bonus temporaires ou combat-longs de Maîtrise d'Armure sans modifier les attributs fondamentaux de la run.

### Décision
1. **Altération sous forme de StatusEffect** : Modifier le déclenchement de l'effet dans `RunController.applyRelicEffect` pour la clé `'charge_armor_mastery_combat'`. Au lieu de modifier la statistique permanente, le reset de la charge Kunaï applique désormais un `StatusEffect` avec l'identifiant `'armor_mastery'`, un type `StatusType.buff`, une valeur correspondant à `relic.value` (généralement 1) et une durée de 99 tours (couvrant l'intégralité du combat).
2. **Getter dynamique d'Armor Mastery** : Introduire une propriété calculée (getter) `effectiveArmorMastery` dans le modèle `EntityStats`. Ce getter parcourt la liste des statuts actifs, somme les valeurs des statuts ayant l'ID `'armor_mastery'`, et ajoute ce cumul à la valeur de base `armorMastery`.
3. **Substitution des calculs d'Armure** : Remplacer l'accès direct à la statistique brute `armorMastery` par le nouveau getter `effectiveArmorMastery` dans `RunController.addArmor()` et dans le système de passifs `TraitSystem` lors de la résolution de l'armure.

### Preuves dans le code
- `lib/models/entity_stats.dart` : Ajout du getter dynamique `effectiveArmorMastery` parcourant la liste `statuses`.
- `lib/game/controllers/run_controller.dart` : Remplacement de l'altération de stat brute par l'appel à `addStatus` d'un effet `'armor_mastery'` de 99 tours, et utilisation de `effectiveArmorMastery` pour le calcul de gain d'armure.
- `lib/game/systems/trait_system.dart` : Utilisation de `effectiveArmorMastery` dans les calculs de gains d'armure basés sur les passifs de classe (Berserker, Mage, Paladin).

### Conséquences
- ✅ **Intégrité de la Progression** : Le bonus de Maîtrise d'Armure octroyé par le Croc Kunaï est correctement confiné à la durée du combat actuel. Les statistiques du héros redeviennent nominales dès le combat résolu.
- ✅ **Structure Générique de Buffs** : Le pattern de statut d'armure temporaire est réutilisable pour d'autres reliques ou compétences futures.
- ✅ **Robustesse** : La validation des 107 tests du projet passe sans régression.

---

## 🎨 ADR-050 : Animation Dynamique des Particules du Carrousel de Reliques (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. L'overlay de carrousel de reliques (`RelicRewardCarouselOverlay` / `RelicCarouselScreen`) comportait une célébration visuelle de victoire générant des particules dessinées sur Canvas. Cependant, à la fin de la rotation (onLand), ces particules étaient figées/immobiles à l'écran car aucun mécanisme d'animation temporelle n'actualisait leur position et leur opacité à chaque frame.
2. L'absence de mouvement brisait le ressenti de jus visuel ("visual juice") recherché pour cette transition critique.

### Décision
1. **Contrôle via AnimationController** : Intégrer un `AnimationController` dédié nommé `_particleAnimationController` avec une durée de 1800ms dans `RelicCarouselScreenState`. Un écouteur (`addListener`) y est rattaché pour déclencher un `setState` à chaque rafraîchissement d'écran.
2. **Initialisation des Particules** : À l'instant exact où le carrousel s'immobilise sur la relique gagnante (`onLand`), peupler la liste de 55 particules avec des angles aléatoires ($0 \rightarrow 2\pi$), des vitesses initiales radiales ($150 \rightarrow 500$), des tailles ($3 \rightarrow 8$px) et des opacités de départ ($0.6 \rightarrow 1.0$). Lancer immédiatement le contrôleur via `_particleAnimationController.forward(from: 0.0)`.
3. **Formules de Physique Canvas** : Dans la méthode `draw` de la classe `_Particle`, appliquer les paramètres physiques suivants interpolés par la progression du contrôleur (allant de 0.0 à 1.0) :
   - *Friction/Traînée* : `final double distance = speed * progress * (1.0 - 0.5 * progress)` limitant la distance radiale finale.
   - *Gravité* : `final double gravityY = 250.0 * progress * progress` tirant les particules vers le bas.
   - *Fondu d'Opacité* : `final double currentOpacity = (initialOpacity * (1.0 - progress)).clamp(0.0, 1.0)`.
4. **IgnorePointer & CustomPaint** : Dessiner l'overlay de particules à l'aide d'un widget `CustomPaint` enveloppé dans un `IgnorePointer` pour ne pas intercepter les interactions utilisateur sur l'écran.

### Preuves dans le code
- `lib/ui/widgets/relic_carousel/relic_carousel_screen.dart` : Définition de `_particleAnimationController`, instanciation de la liste de particules dans `_startSpin().then()`, et implémentation de la physique dans `_Particle.draw()`.

### Conséquences
- ✅ **Sensation Premium Renforcée** : L'explosion de confettis/particules de couleur de rareté est fluide, dynamique, et retombe élégamment vers le bas de l'écran tout en s'estompant.
- ✅ **Respect du Cycle de Vie** : Le contrôleur est correctement libéré via `dispose()` pour éviter toute fuite de mémoire.

---

## 🃏 ADR-051 : Filtrage des Cartes de Rareté Unique dans les Récompenses de Boss (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. Lors de l'implémentation de la récompense de cartes du Boss 1 (position x=0) via `BossCardDraftScreen`, les cartes étaient générées par `RewardController` en tirant depuis `allCards` sans filtrage de rareté spécifique.
2. Les cartes spécifiques de classe (ex: *Bouclier Saint*, *Fureur*) ayant été déplacées de `cards.json` à `hero_cards.json` avec la rareté `unique`, ces cartes étaient tirées à tort dans le draft de cartes globales, permettant à un joueur de collecter des cartes d'autres classes ou de briser la restriction de gating de classe.

### Décision
1. **Filtrage des Unique dans le RewardController** : Modifier la méthode d'initialisation de récompense `RewardController.initializeReward()`. Pour le cas de récompense `BossRewardType.cards` (Boss x=0), ajouter un filtre restrictif lors de l'extraction des cartes disponibles :
   ```dart
   rolledCards = allCards
       .where((c) => c.type != CardType.status && c.rarity != CardRarity.unique)
       .toList();
   ```
2. **Alignement des Pools** : Garantir que les cartes de rareté `unique` restent réservées à l'attribution initiale (starter decks via compétences) ou à des systèmes explicitement liés à la classe choisie, les excluant du pool de cartes globales proposées post-combat de boss.

### Preuves dans le code
- `lib/game/controllers/reward_controller.dart` : Ajout de la clause `c.rarity != CardRarity.unique` dans la méthode de roll des récompenses du boss de cartes.

### Conséquences
- ✅ **Cohérence Métier Restaurée** : Les cartes de classe conservent leur exclusivité. Un joueur Paladin n'aura aucun risque de se voir proposer des cartes de Mage ou de Berserker après avoir vaincu le premier boss.
- ✅ **Contrôle de l'Équilibrage** : Le pool de drafts de boss reste sain et équilibré avec les 15 cartes globales neutres uniquement.

---

## 🪞 ADR-052 : Amélioration Visuelle, Caching Anti-Exploit du Magic Mirror et Gating de Solde de la Boutique (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. L'option de service Magic Mirror (permettant de cloner une carte parmi 3 tirées aléatoirement du deck) utilisait précédemment une disposition visuelle simplifiée pour présenter les choix de cartes. Cette présentation sommaire omettait des informations fondamentales de la carte, telles que sa rareté, ses upgrades de forge actifs, son coût en mana standardisé, son type de ciblage ou sa description complète d'effets, nuisant à l'ergonomie générale.
2. L'interface n'offrait pas de feedback visuel réactif (comme un zoom ou un halo lumineux de rareté/surbrillance) lors du survol de la souris sur les cartes clonables.
3. Les dialogues standard (`GameDialog`) présentaient une largeur maximale par défaut trop étroite pour afficher confortablement 3 choix de cartes côte à côte. Sans un mécanisme de défilement ou une contrainte de largeur assouplie, l'affichage risquait de provoquer des débordements (RenderFlex overflow) sur les écrans étroits (mobiles portrait) ou d'être trop resserré.
4. L'option de clonage Magic Mirror présentait une faille d'exploitation (reroll exploit) : les 3 cartes candidates à la duplication étaient tirées aléatoirement à chaque ouverture du dialogue de clonage. Un joueur pouvait donc fermer et rouvrir le dialogue indéfiniment sans frais d'or pour relancer le tirage jusqu'à obtenir la carte idéale.
5. L'achat de services de boutique (Reroll, Heal, Purge, Expand, Clone) permettait théoriquement d'ouvrir les fenêtres de transaction ou de cliquer sur les boutons même si le solde en or du joueur était inférieur au coût du service, provoquant des anomalies fonctionnelles ou des toasts d'erreur redondants.

### Décision
1. **Intégration Unifiée de `UiCard`** : Remplacer l'affichage simplifié de la carte à cloner par l'utilisation directe du widget standardisé `UiCard` au sein d'un composant interne `_CloneCardItem`. Ce widget est alimenté par l'ensemble des données réelles de la carte (`title`, `description`, `cost` de combat, `effects`, `rarity` localisée, `target`, `type`, `isExhaust`, `forgeUpgrades` et `rarityMultiplier`).
2. **Gestion Dynamique du Survol** : Envelopper chaque `_CloneCardItem` dans un widget `MouseRegion` et un `AnimatedScale`. Lors du survol (`onEnter`), l'échelle de la carte augmente de manière fluide à `1.05` sur 200ms et le flag `isSelected` du widget `UiCard` est passé à `true`, ce qui active automatiquement les ombres lumineuses (radial glow shadow) et l'effet foil tournant sur la bordure de la carte selon sa rareté.
3. **Conteneur Horizontal Adaptatif** : Envelopper la ligne (`Row`) de choix de cartes dans un widget `SingleChildScrollView` avec `scrollDirection: Axis.horizontal` pour permettre un défilement propre si la largeur de l'écran est insuffisante pour afficher les 3 options simultanément.
4. **Élargissement Responsive du Dialogue** : Introduire la propriété optionnelle `maxWidth` dans `GameDialog` et la fixer à `550` pour le dialogue de clonage afin de donner l'espace nécessaire à l'affichage des 3 choix de cartes de largeur unitaire `140`.
5. **Caching de Session Anti-Exploit (`cloneOptions`)** : Intégrer une liste de cartes candidates `cloneOptions` dans le `ShopState` d'un run. Lors du premier appel à `_showCloneModal()`, si `shopState.cloneOptions` est vide, le système tire 3 cartes au hasard dans le master deck du joueur et appelle `ref.read(shopProvider.notifier).setCloneOptions(options)` pour les sauvegarder de manière persistante dans le state de la boutique. Les ouvertures ultérieures du modal de clonage réutilisent directement ces options persistantes, rendant l'annulation/réouverture inoffensive. Cette liste d'options n'est vidée et réinitialisée que lors de l'appel à `initializeShop` (lors de l'entrée dans une nouvelle boutique sur la carte).
6. **Gating de Solde Systématique pour les Services** : Mettre en œuvre une désactivation logicielle et visuelle directe pour tous les services de la boutique (Reroll, Soin, Purge, Expansion, Clonage) dans le widget principal. Si le solde d'or du joueur (`inventoryState.gold`) est inférieur au coût du service :
   - Le paramètre `onPressed` du widget `_ShopServiceWidget` est défini sur `null`, désactivant nativement l'interaction du bouton en Flutter.
   - La propriété `canAfford` est passée à `false`, modifiant l'affichage visuel (comme la coloration du prix ou de l'icône) pour signaler graphiquement le manque de fonds.

### Preuves dans le code
- `lib/models/shop_state.dart` : Ajout du champ `cloneOptions` (de type `List<CardInstance>`) dans l'état de la boutique avec initialisation par défaut à `const []` et propagation via `copyWith()`.
- `lib/game/controllers/shop_controller.dart` :
  - Implémentation du setter `setCloneOptions(List<CardInstance> options)`.
  - La méthode `initializeShop()` réinitialise l'état en instanciant un nouveau `ShopState`, ce qui remet `cloneOptions` à sa valeur par défaut vide.
- `lib/ui/screens/shop_screen.dart` :
  - Dans `_showCloneModal()`, vérification de `shopState.cloneOptions` avant tout tirage aléatoire.
  - Dans la construction de la sidebar de services, injection des conditions `inventoryState.gold >= servicePrice` pour désactiver `onPressed` (valorisé à `null` si faux) et affecter `canAfford`.
- `lib/ui/widgets/game_dialog.dart` : Ajout de la propriété `maxWidth` (valeur par défaut `500`) pour permettre aux modals spécifiques de demander un élargissement contrôlé de leur conteneur.

### Conséquences
- ✅ **Expérience Utilisateur Premium (Juice & Feedback)** : La sélection d'une carte à cloner bénéficie désormais de la même qualité visuelle premium glassmorphic, avec ses runes et son halo de rareté foil, que le reste du jeu. Le survol réactif à la souris renforce le plaisir d'interaction.
- ✅ **Responsivité et Robustesse UI** : Le défilement horizontal et l'élargissement ciblé préviennent tout overflow graphique tout en conservant une mise en page aérée sur desktop et web.
- ✅ **Cohérence de Design (DRY)** : Réutilisation du composant `UiCard` découpé au lieu d'une duplication partielle de code visuel.
- ✅ **Protection et Intégrité du Gameplay** : Élimination absolue de la faille de duplication infinie / reroll gratuit de Magic Mirror. Le tirage de clonage est fixé pour toute la visite de la boutique.
- ✅ **Interface Économique Intuitive** : Les verrous de solde empêchent de soumettre des transactions invalides, guidant visuellement le joueur sur ce qu'il peut s'offrir avec son solde actuel d'or.

---

## 🛡️ ADR-053 : Réinitialisation de l'Armure du Joueur en Début de Tour & Suppression de l'Animation (v0.1.8)

### Statut
✅ Accepté & Implémenté (v0.1.8)

### Contexte
1. Auparavant, l'armure (`armure`) du joueur persistait indéfiniment d'un tour sur l'autre s'il ne subissait pas d'attaque ennemie. Cela posait un problème d'équilibrage majeur : des reliques (comme le Talisman de Fer `iron_talisman`) ou des passifs de classe (tels que la régénération d'armure du Paladin `regenArmor` ou l'armure de début de tour du Berserker `berserkerArmor`) généraient de l'armure cumulative à chaque début de tour, permettant au joueur d'accumuler une armure infinie et de devenir virtuellemment invincible.
2. Pour corriger cela, l'armure du joueur devait être remise à 0 au début de chaque tour.
3. Néanmoins, en effectuant cette réinitialisation (par exemple, passage de 15 d'armure à 0 d'armure au démarrage du tour), la mise à jour des statistiques de l'entité (`HeroCard.updateStats()`) dans la couche graphique de Flame interprétait ce changement d'armure comme une perte standard (similaire à des dégâts). Cela déclenchait à tort une animation de tremblement de bouclier (`shieldHitAnimation`) et l'apparition de textes flottants négatifs d'armure (ex: "-15 🛡️"), induisant faussement le joueur en erreur en lui faisant croire qu'il venait d'être touché. Cette pollution visuelle transitoire devait impérativement être supprimée lors de la phase de reset.

### Décision
1. **Reset d'Armure Métier** : Modifier `RunController.startTurn()` pour fixer `armure: 0` dès le premier bloc de mise à jour de l'état `state.copyWith(...)`. Ce reset est effectué en amont afin que les reliques de début de tour (`RelicTrigger.startOfTurn`) et les effets de statut (comme `armor_regen`) s'exécutent immédiatement après, garantissant que le joueur commence son tour uniquement avec l'armure valide octroyée par ses bonus.
2. **Drapeau de Suppression d'Animation** : Ajouter une variable booléenne transitoire `suppressArmorChangeAnimation` (valeur par défaut `false`) au sein du composant de rendu `HeroCard`.
3. **Suppression Conditionnelle des Popups** : Dans la méthode de rafraîchissement visuel `HeroCard.updateStats()`, soumettre le déclenchement visuel de la perte d'armure (secousses `shieldHitAnimation` et instantation de `FloatingText` négatifs) à la condition `if (!suppressArmorChangeAnimation)`. En fin d'exécution de `updateStats()`, réinitialiser systématiquement `suppressArmorChangeAnimation` à `false`.
4. **Activation de la Suppression** : Dans `game_screen.dart` lors de l'appel à `_startPlayerNewTurn()`, forcer `_game.heroCard?.suppressArmorChangeAnimation = true;` juste avant de notifier le `runProvider` de démarrer le nouveau tour (`startTurn()`). Cela garantit que la mise à jour graphique consécutive au reset à 0 ignore les effets visuels de hit.

### Preuves dans le code
- `lib/game/controllers/run_controller.dart` : Réinitialisation à 0 de l'armure dans `startTurn()` avant l'itération des reliques et buffs.
- `lib/game/components/entities/hero_card.dart` : Variable `suppressArmorChangeAnimation` et embranchement conditionnel pour le rendu de perte de bouclier dans `updateStats()`.
- `lib/ui/screens/game_screen.dart` : Assignation à `true` de `suppressArmorChangeAnimation` dans `_startPlayerNewTurn()`.

### Conséquences
- ✅ **Intégrité de l'Équilibrage de Combat** : L'armure est correctement restreinte au tour en cours. La synergie avec les reliques et statuts de début de tour fonctionne de manière prévisible sans accumulation infinie exploitée.
- ✅ **Clarté Visuelle & Propreté des Transitions** : Les tours commencent sereinement sans faux popups négatifs ni animations d'impact parasites. La transition de tour est esthétique et fluide.
- ✅ **Robustesse et Qualité du Code** : La modification respecte le découplage MVC/Flux. Les tests automatisés continuent de passer avec succès (108/108 tests valides) et le linter est impeccable.

---

## 🛠️ ADR-054 : Centralisation et Harmonisation des Constantes (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. De nombreux délais temporels liés au déroulement des phases de combat (timing après dash, riposte, résolution des intentions, ticks de statut) étaient codés en dur avec des `Duration(milliseconds: ...)` au sein du orchestrateur de jeu `HerosDraftGame`.
2. Les configurations visuelles et physiques de l'affichage des textes flottants (`FloatingText`), comme les tailles de police pour les différents types de texte (dégâts, critique, poison, bouclier), les durées d'animations (fondu, échelle, dérive, suppression) et les calculs physiques de drift (angle de rotation de naissance, vitesse de dérive X, drift Y d'oscillation), étaient également codés en dur avec des magic numbers.
3. Ces valeurs disséminées nuisaient à la maintenance à long terme, rendant difficile l'ajustement global de la vitesse de jeu ou de la physique des textes flottants de dégâts.

### Décision
1. **Centralisation dans `GameConstants`** : Regrouper toutes les constantes concernées au sein de `lib/game/game_constants.dart` sous la forme de champs statiques typés et documentés (ex: `combatDelayHeroDashMs`, `floatingTextFontSizeCrit`, etc.).
2. **Refactoring de `HerosDraftGame`** : Remplacer toutes les instanciations de `Duration` utilisant des valeurs entières littérales dans le code de combat par des références aux constantes de délais de `GameConstants`.
3. **Refactoring de `FloatingText`** : Remplacer l'intégralité des nombres magiques de taille, durée, et drift par les nouvelles constantes de `GameConstants`, standardisant ainsi les trajectoires et l'affichage visuel des nombres flottants.

### Preuves dans le code
- [game_constants.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/game_constants.dart) : Déclaration et documentation détaillée des constantes sous `GameConstants`.
- [floating_text.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/floating_text.dart) : Utilisation des constantes `GameConstants.floatingText*`.
- [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) : Utilisation des constantes `GameConstants.combatDelay*Ms`.

### Conséquences
- ✅ **Éradication de la Dette Technique (Nombres Magiques)** : Disparition complète des valeurs littérales en dur liées aux timings de combat et à l'affichage des textes flottants, améliorant drastiquement la maintenabilité et la lisibilité du code.
- ✅ **Facilité d'Ajustement du Gameplay** : La modification globale du rythme du jeu (vitesse des tours, durée des ripostes) ou du rendu visuel des dégâts se fait désormais en un point unique (`GameConstants`).
- ✅ **Homogénéité Visuelle** : Uniformisation parfaite des trajectoires et des tailles des textes de dégâts.
- ✅ **Zéro Régression** : Les tests unitaires (108/108) passent sans modification de comportement fonctionnel et `dart analyze` ne signale aucune erreur.

---

## 🔒 ADR-055 : Immutabilité Stricte des Modèles d'État (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. L'utilisation de Riverpod pour la gestion globale de l'état repose sur des données immuables. Si des listes ou des objets imbriqués dans l'état sont mutables, des modifications directes de données peuvent se produire de manière indésirable sans déclencher la mise à jour des widgets à l'écran, rompant le cycle de rendu Flutter/Riverpod.
2. Les modèles d'état `EntityStats`, `CombatState` et `EnemyInstance` contenaient des listes (comme `statuses` et `enemies`) qui pouvaient être altérées par référence directe.
3. Il était nécessaire de sécuriser ces modèles pour interdire les mutations directes et renforcer la conformité du code avec le paradigme immuable.

### Décision
1. **Annotation @immutable** : Ajouter l'import `package:meta/meta.dart` et annoter les classes `EntityStats`, `CombatState` et `EnemyInstance` avec `@immutable`.
2. **Encapsulation des listes** : Remplacer l'instanciation simple des listes internes par `List.unmodifiable(...)` dans le constructeur et lors de l'appel à la méthode `copyWith`. Toute altération directe lève désormais une exception.
3. **Mise à jour des constructeurs** : Convertir les constructeurs de `EntityStats` et `CombatState` pour qu'ils ne soient plus `const` puisque `List.unmodifiable` est exécuté à l'exécution.

### Preuves dans le code
- [entity_stats.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart) : Ajout de `@immutable` et `List.unmodifiable(statuses)`.
- [combat_state.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/combat_state.dart) : Ajout de `@immutable` et `List.unmodifiable` pour `enemies`, `pendingEnemies`, et `defeatedEnemies`.
- [enemy_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/enemy_instance.dart) : Ajout de `@immutable`.

### Conséquences
- ✅ **Sécurisation du State Riverpod** : Plus aucune altération d'état non détectée ne peut se produire sur les entités de combat.
- ✅ **Respect Strict du Flux Unidirectionnel** : Les modifications se font uniquement via `copyWith` et les Notifiers associés.
- ✅ **Code Léger** : Aucune dépendance sur du code généré complexe (pas de `freezed` ni de build_runner requis pour le moment).
- ✅ **Zéro Régression** : Les 108 tests unitaires de non-régression s'exécutent avec succès.

---

## ⚔️ ADR-056 : Centralisation du Calcul des Dégâts via un Pipeline Unique (v0.1.9)

### Statut
✅ Accepté & Implémenté (v0.1.9)

### Contexte
1. Les calculs de dégâts (physiques, magiques, compétences, intentions de monstres) étaient dispersés dans le code entre `EffectResolver` (pour les cartes de combat) et `CombatController` (pour les intentions des ennemis et les compétences du héros).
2. Cette duplication présentait un risque élevé de désynchronisation des modificateurs d'état lors des calculs (par exemple, des différences dans l'application de la faiblesse, de la vulnérabilité, du choc, ou des calculs de coup critique).
3. Il était indispensable d'unifier ce calcul sous un service unique afin de garantir que les règles de calcul de combat restent prévisibles, centralisées et faciles à équilibrer ou modifier à l'avenir.

### Décision
1. **Création de DamagePipeline** : Définir un service centralisé `DamagePipeline.calculate` (`lib/game/services/damage_pipeline.dart`) qui prend en charge toutes les étapes logiques de calcul de combat :
   - Étape 1 : Application de la réduction de 25% de dégâts si l'attaquant possède le statut `weakness`.
   - Étape 2 : Jet de coup critique basé sur `effectiveCritChance` de l'attaquant. Si réussi, application du multiplicateur `critMultiplier` et enregistrement du flag `lastActionWasCrit` sur l'attaquant (nécessaire pour les animations Flame).
   - Étape 3 : Ajout de la valeur de débuff `shock` accumulée par le défenseur.
   - Étape 4 : Application du bonus de dégâts de 50% si le défenseur possède le statut `vulnerable`.
2. **Refactoring des Appelants** : Remplacer les calculs dispersés dans `CombatController.executeSkill`, `CombatController.resolveEnemyIntent` et `EffectResolver._calculateDamage` par un appel unique à `DamagePipeline.calculate`.
3. **Garantie DRY** : Suppression complète des switches et logiques de statuts dupliquées pour le calcul de dégâts.

### Preuves dans le code
- [damage_pipeline.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/damage_pipeline.dart) : Création de la classe avec sa logique métier en 4 étapes.
- [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) : Utilisation du pipeline pour calculer les dégâts reçus ou infligés.
- [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart) : Suppression du calcul local au profit de l'appel au pipeline centralisé.

### Conséquences
- ✅ **Calculs de Combat Garantis Homogènes** : Le héros et les monstres sont soumis aux mêmes règles et mécaniques, sans dérive de calcul possible.
- ✅ **Facilité d'Équilibrage** : La modification d'un coefficient ou l'ajout d'une nouvelle règle de calcul de dégâts globale s'effectue en une seule ligne de code.
- ✅ **Lisibilité Accrue** : Réduction sensible de la taille de `EffectResolver` et de `CombatController` grâce à l'externalisation de la formule mathématique.
- ✅ **Zéro Régression** : Tous les tests unitaires et d'intégration existants (108) passent sans anomalie.

---

## 🎛️ ADR-057 : Décomposition des Contrôleurs Globaux en Managers Spécialisés (v0.2.10)

### Statut
✅ Accepté & Implémenté (v0.2.10)

### Contexte
Les contrôleurs `RunController` et `CombatController` constituaient des classes monolithiques (God Classes) centralisant des responsabilités excessivement diverses : cycle de vie du run, progression sur la carte, gains de ressources (or, XP, niveaux), sauvegarde persistance, altérations d'état, riposte ennemie et flux de tour de combat. Cette concentration nuisait à la lisibilité, augmentait le couplage et rendait difficile l'isolation des règles de calcul pour les tests.

### Décision
- **Pattern Façade** : Transformer `RunController` et `CombatController` en façades légères préservant l'intégralité de leur API publique pour éviter de casser le code de l'interface UI (widgets Flutter) et la suite de tests.
- **Extraction des Managers de Run** : Déléguer les traitements du run à 4 classes spécialisées situées dans le sous-dossier `lib/game/controllers/run/` :
  1. `PlayerStatsManager` : Gère les points de vie, le mana, l'armure, les statistiques permanentes et le traitement du système d'expérience (XP et gains de niveau).
  2. `MapProgressionManager` : Gère le parcours et la complétion des nœuds de la carte stratégique ainsi que la transition entre les actes.
  3. `RunPersistenceManager` : Reçoit l'état et prépare l'écriture ou le chargement.
  4. `GoldManager` : Encapsule les transactions d'or et l'achat progressif de slots de forge.
- **Extraction des Managers de Combat** : Déléguer les traitements du combat à 2 classes spécialisées situées dans le sous-dossier `lib/game/controllers/combat/` :
  1. `StatusEffectProcessor` : Centralise le calcul des altérations d'état (Poison, Brûlure, Régénération de Force, Maîtrise d'Armure) de façon unifiée pour le joueur et les ennemis.
  2. `TurnPhaseManager` : Orchestre la transition des phases de tour (Joueur / Ennemi) et le déroulement séquentiel de la riposte ennemie.

### Preuves dans le code
- [run_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart) : Instancie les 4 managers et leur délègue ses appels de fonctions.
- [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) : Délègue le traitement des statuts à `StatusEffectProcessor` et les phases de tours à `TurnPhaseManager`.
- Sous-dossier [run/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run/) : Contient les classes métiers isolées de gestion du run.
- Sous-dossier [combat/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat/) : Contient les classes métiers de gestion du combat.

### Conséquences
- ✅ **Respect Strict du Principe de Responsabilité Unique (SRP)** : Chaque fichier possède un domaine logique restreint (stats, progression, or, statuts, phases), simplifiant la lecture.
- ✅ **Sécurité de Refactoring (Zéro Régression)** : L'utilisation du pattern Façade a garanti une non-régression absolue de la suite de tests automatisés (108/108 passés avec succès).
- ✅ **Maintenance Facilitée** : Les corrections ou équilibrages (par exemple, la formule d'XP ou le comportement d'un statut) se font dans des gestionnaires isolés et documentés.

---

## 🎮 ADR-058 : Modularité Rendu Flame / Composants de Rendu (v0.2.10)

### Statut
✅ Accepté & Implémenté (v0.2.10)

### Contexte
La classe racine du moteur Flame `HerosDraftGame` gérait de façon centralisée des responsabilités complexes comme la synchronisation d'état Riverpod, le calcul de la disposition des cartes en main, le repositionnement des ennemis, et l'affichage des effets visuels (particules, ciblage). De même, `CardComponent` combinait à la fois le dessin Canvas 2D (coût mana, bordures rareté, sheen foil, rune sockets) et la gestion des gestes du pointeur (drag, hover, tap). Ce couplage alourdissait les fichiers et créait de la dette technique de rendu.

### Décision
- **Extraction de Systèmes Graphiques** : Décomposer `HerosDraftGame` en extrayant ses sous-tâches dans 4 sous-systèmes autonomes enregistrés en tant que composants de jeu Flame sous `lib/game/systems/` :
  1. `StateSyncSystem` : Synchronise de manière séquentielle et synchrone les états Riverpod (`RunState`, `DeckState`, `CombatState`) avec la boucle `update` de Flame.
  2. `CardAnimationSystem` : Gère le focus, le zoom, le survol, la pioche et le tilt des cartes en main.
  3. `CombatVisualSystem` : Gère le rendu de la courbe de ciblage Bézier et les effets visuels de combat.
  4. `LayoutSystem` : Calcule l'arc circulaire de la main du joueur et le repositionnement automatique des ennemis actifs sur le plateau.
- **Découplage de CardComponent** : Diviser le composant carte en extrayant ses responsabilités logiques et visuelles dans deux classes spécialisées sous `lib/game/components/widgets/` :
  1. `CardRenderer` : Prend en charge exclusivement le dessin 2D de la carte (fond, halos, bordures, rune sockets, dégradés typés).
  2. `CardInteractionHandler` : Centralise la gestion des événements Pointer (drag, hover, tap) et met à jour les flags d'état du composant.
- **Conservation de la Façade** : `CardComponent` et `HerosDraftGame` agissent comme des façades de coordination légères associant et délégant aux sous-systèmes et helpers.

### Preuves dans le code
- [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) : Nettoyé de ses algorithmes de layout et d'animations, délègue aux 4 sous-systèmes.
- [card_component.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/card_component.dart) : Délègue son rendu à `CardRenderer` et ses interactions gestuelles à `CardInteractionHandler`.
- Sous-dossier [systems/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/systems/) : Contient les 4 sous-systèmes Flame autonomes.
- [card_renderer.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/widgets/card_renderer.dart) et [card_interaction_handler.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/components/widgets/card_interaction_handler.dart) : Gèrent respectivement le dessin et les gestes.

### Conséquences
- ✅ **Rendu et Calculs Découplés** : La structure des classes de rendu Flame est aérée, aisée à comprendre et à faire évoluer sans risquer de perturber la gestion des gestes ou le calcul de géométrie.
- ✅ **GPU/CPU Performance** : Permet de mieux cibler les mises en cache (comme le caching des structures textes dans `CardRenderer`).
- ✅ **Facilité d'Évolution** : L'ajout d'effets visuels, de nouveaux types de gestes ou de nouvelles dispositions de main se fait dans des fichiers isolés sans impacter la classe racine.

---

## 🎨 ADR-059 : Unification de l'UI et Composants d'Infrastructure Communs (v0.2.2)

### Statut
✅ Accepté & Implémenté (v0.2.2)

### Contexte
1. L'application comportait une duplication visuelle massive : chaque écran majeur (Shop, Deck, Map, Dictionary, Rest, etc.) redéfinissait ses propres Scaffold, décors d'arrière-plans (dégradés sombres ou textures parchemin), zones de sécurité (`SafeArea`) et interdictions de retour arrière (`PopScope`), nuisant à la cohérence et à la maintenabilité.
2. L'instanciation du composant `UiCard` Flutter dans les écrans de menu était extrêmement verbeuse (nécessitant de mapper manuellement ~15 attributs d'état à chaque fois).
3. Le dialogue de forge (`forge_upgrade_dialog.dart`) était une classe monolithique complexe d'environ 870 lignes gérant à la fois la logique de forge, l'affichage de l'aperçu de carte, les lignes de slots et le bouton d'achat de slots.
4. Les écrans de draft de cartes (`boss_card_draft_screen.dart` et `starter_deck_draft_screen.dart`) dupliquaient les structures de grille, d'en-tête et les indicateurs de sélection.

### Décision
1. **Composants Génériques Unifiés** :
   - Créer `ScreenScaffold` pour centraliser le rendu du Scaffold, le background thématique (`dark`, `parchment`, `none`), la `SafeArea` et la gestion de `PopScope`.
   - Créer `PageHeader` comme en-tête d'écran standardisé gérant le bouton de retour arrière, le titre et les actions (telles que le badge d'or).
   - Créer `GoldIndicator` pour l'affichage unifié de l'or connecté à `inventoryProvider`.
2. **Factories `UiCard`** :
   - Ajouter des constructeurs nommés `UiCard.fromInstance` (pour `CardInstance` de run) et `UiCard.fromData` (pour `CardData` de configuration) pour centraliser la conversion d'état.
3. **Décomposition de la Forge** :
   - Diviser le dialogue monolithique en extrayant ses composants visuels dans un nouveau sous-dossier `lib/ui/widgets/forge/` :
     - `ForgeCardPreview` : Rendu de la carte et de sa jauge d'upgrades.
     - `ForgeSlotRow` : Rendu d'une option d'amélioration, son coût de reroll et ses boutons d'actions.
     - `ForgeBuySlotButton` : Bouton d'achat de fente progressive.
4. **Layout de Draft Centralisé** :
   - Créer `CardDraftLayout` pour factoriser la mise en page commune des écrans de draft de cartes.
5. **Refactoring des Écrans** :
   - Harmoniser 9 écrans majeurs (Dictionary, Deck, Shop, RestCardSelection, PatchNotes, Rest, Event, RelicExchange, Map) pour s'appuyer sur ces widgets communs.

### Preuves dans le code
- [screen_scaffold.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/screen_scaffold.dart) : Classe centralisant le décor et le cycle de vie du Scaffold.
- [page_header.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/page_header.dart) : En-tête standardisé.
- [gold_indicator.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/gold_indicator.dart) : Badge d'or connecté à l'état.
- [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart) : Intégration de `UiCard.fromInstance` et `UiCard.fromData`.
- [card_draft_layout.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/draft/card_draft_layout.dart) : Layout de draft partagé.
- Sous-dossier [forge/](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/forge/) : Composants visuels extraits de la forge.

### Conséquences
- ✅ **Élimination de la Duplication Visuelle (DRY)** : Les arrière-plans, les en-têtes et les structures de pages sont partagés, éliminant des centaines de lignes répétitives.
- ✅ **Séparation des Responsabilités (SRP)** : Le dialogue de la forge a été allégé de plus de 250 lignes et ne gère plus que l'orchestration logique et Riverpod.
- ✅ **Simplicité d'Usage** : L'instanciation de `UiCard` est immédiate grâce aux factories, sécurisant les mappings.
- ✅ **Cooptation des Écrans de Draft** : Une seule grille responsive gère les différents drafts, rendant les corrections ou ajustements futurs instantanés.
- ✅ **Zéro Régression** : Les 108 tests unitaires du projet s'exécutent avec succès et l'analyse statique de compilation est vierge.








