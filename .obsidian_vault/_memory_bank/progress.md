# 📊 État du Projet & Progrès (Progress)

Ce document dresse l'inventaire technique exhaustif et rigoureux des fonctionnalités de **Hero's Draft** : opérationnelles, partiellement implémentées, non implémentées, et les chantiers de refactoring prioritaires issus des rapports de dette technique.

**Métriques du projet** :
- **~8 200 lignes** de code source dans `lib/` (45 fichiers).
- **7 fichiers JSON** de données d'assets.
- **65 tests automatisés** — 100% au vert.
- **0 erreur, 0 avertissement** via `flutter analyze`.
- **~108 phases d'implémentation** complétées (historique dans `docs/implementation_plans/done/`).

---

## 1. Fonctionnalités 100% Opérationnelles

### 🗺️ Génération et Progression Procédurale (World Map)

| Fonctionnalité | Fichiers Clés | Détails |
|:---|:---|:---|
| Graphe Acyclique Dirigé (DAG) | `MapGeneratorService`, `MapNode` | 10 étages, largeur 2-5 nœuds, chokepoint étage 5, repos garanti étage 8, boss unique étage 9 |
| Distribution probabiliste des nœuds | `MapGeneratorService._randomNodeType()` | 60% combat, 15% event, 10% shop, 10% rest, 5% elite |
| Correction d'orphelins | `MapGeneratorService` (Phase 2 câblage) | Garantie que tout nœud a au moins 1 connexion entrante |
| Navigation réactive | `RunController.travelToNode()` | Validation d'accessibilité (connexion au nœud complété ou étage 0) |
| Caméra centrée | `MapScreen` | Repositionnement et centrage automatique fluide à chaque transition |
| Widgets dédiés par type | `MapScreen` | Icônes spécifiques (Combat/Élite/Shop/Event/Repos/Boss) + tooltips |
| Barre d'XP HUD | `MapScreen`, `xp_scaling_test.dart` | Barre de progression d'expérience dorée permanente et badges de niveau sous le HUD |

### 🧠 Gestion d'État Métier (Riverpod Controllers)

| Fonctionnalité | Controller/Provider | Détails |
|:---|:---|:---|
| Logique de Run | `RunController` / `runProvider` | Suivi PV, mana, armorMastery, luck, acte, level, XP, carte, passifs, reliques |
| Système de Progression XP | `RunController.gainXp()` | Progression XP exponentielle ($100 \times 1.5^{lvl-1}$), gains multiples et carry-over |
| Échelonnement Ennemis | `CombatController.initializeCombat()` | Multiplicateurs dynamiques (+12% HP/lvl, +8% ATK/lvl) et calcul de combat level |
| Logique de Combat | `CombatController` / `combatProvider` | Phases (Player ⇄ Enemy), sélection cible, intentions ennemies (cycliques ou aléatoires), détection mort, victoire/défaite |
| Piles de Cartes | `DeckNotifier` / `deckProvider` | 5 piles logiques (Master, Draw, Hand, Discard, Exhaust) avec shuffle et gestion complète |
| Économie et Reliques | `InventoryController` / `inventoryProvider` | Or (initial 50), 12 reliques avec 6 triggers différents, bonus boutique |
| Compétences | `SkillController` / `skillProvider` | 2 compétences par héros, cooldowns, consommation de ressources |
| Événements | `EventController` / `eventProvider` | 2 événements narratifs à choix multiples, résolution d'actions, roll de rareté relique |
| Boutique | `ShopController` / `shopProvider` | Achat/purge/clone cartes, soin, expansion, reroll |

### 🃏 Système de Cartes et Deck

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Auto-Merge (3→1) | `DeckNotifier.mergeCards()` | 3 copies même ID + level → 1 copie level+1 |
| Échelonnement par Level | `EffectResolver.resolveCard()` | `scaledValue = baseValue * (1 + (level-1) * 0.5)` |
| Catalogue complet | `cards.json` | 23 cartes : 15 globales + 2 Paladin + 2 Berserker + 2 Mage |
| Types d'effets | `EffectResolver`, `CardEffect` | damage, heal, armor, draw, gain_mana, apply_status |
| Exhaust mécanique | `DeckNotifier.playCard()` | Cartes Power et `isExhaust` → pile d'épuisement |
| Upgrade mécanique | `DeckNotifier.upgradeCard()` | Forge au feu de camp : level+1 permanent |
| Suppression de carte | `DeckNotifier.removeCardById()` | Oubli au feu de camp : suppression définitive |
| Draft post-combat | `DraftScreen` | 3 choix de cartes aléatoires après victoire |
| Draft de départ | `StarterDeckDraftScreen` | Vagues de 3 cartes pour constituer le deck initial |

### ⚔️ Système de Combat

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Pipeline de dégâts | `EffectResolver._calculateDamage()` | baseDamage + effectiveAttaque, réduction weakness ×0.75 |
| Absorption armure | `EntityStats.takeDamage()` | Armure absorbe en priorité, reste → PV |
| Armure + Mastery | `RunController.addArmor()`, `TraitSystem` | Tous les gains d'armure incluent `armorMastery` |
| Intentions ennemies | `CombatController._rollIntent()` | Cycle séquentiel (prédéfinis) ou aléatoire (60% atk, 25% def, 15% buff) |
| Phase ennemie séquentielle | `HerosDraftGame._enemyRipostePhase()` | Résolution intent par intent avec animations (délais 400-600ms) |
| Statuts de combat | `EntityStats.addStatus()`, `tickStatuses()` | Stacking, tick durée, processing poison/regen |
| Nettoyage des morts | `CombatController._cleanDeadEnemies()` | Auto-sélection prochain ennemi, trigger reliques `onEnemyKilled` |

### 🏆 Système de Passifs et Traits de Héros

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Passifs data-driven | `passives.json` → `TraitSystem` | 3 passifs liés aux héros par `HeroData.passiveTrait` |
| Triggers multiples | `TraitSystem.onTurnStart/onTurnEnd/onCardPlayed` | Logique spécifique par effectType (`gain_armor`, `berserker_armor`, `spell_armor`) |
| Reliques à triggers | `RunController.applyRelics(trigger)` | 6 types de triggers : startOfRun, startOfCombat, startOfTurn, endOfTurn, onCardPlayed, onEnemyKilled |

### 🈳 Internationalisation (i18n)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| UI 100% localisée | `AppLocalizations` (ARB) | Zéro chaîne codée en dur, zéro variable `isFr` |
| Modèles bilingues | `nameEn`/`nameFr` sur tous les modèles Data | Sauf `SkillData` (champ `name` unique) |
| Statuts localisés | `StatusEffectsPanel` | Traduction dynamique depuis identifiants techniques |
| Langues supportées | `app_en.arb`, `app_fr.arb` | Anglais + Français |

### 🎨 Rendu Unifié, Rénovation Premium et Jus Visuel (Visual Juice)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| `UiCard` unifié | `lib/ui/widgets/ui_card.dart` | Remplace 6 rendus dupliqués, ratio 70/110, gradients par rareté |
| Tilt organique des cartes | `CardComponent` (DragCallbacks) | Rotation proportionnelle à la vélocité horizontale au glissement |
| Shake d'erreur mana | `CardComponent._shakeAnimation()` | `SequenceEffect` oscillations rapides en cas de manque de mana |
| Courbe de ciblage Bézier | `targeting_line.dart` | Courbe quadratique de Bézier fluide avec pointillés défilants et tête orientée via la tangente |
| Jus Visuel de Dégâts/Impacts | `CardComponent`, `EnemyCard` | Secousses haute fréquence, rebond élastique (`Curves.elasticOut`), et flashes de sprites (`ColorEffect`) rouges/oranges ou verts |
| Particules physiques | `spawnDamageParticles` | Éjection radiale de particules de dégâts (12 poison, 15 normal, 25 critiques) |
| Traînées élémentaires | `CardAnimator`, `RibbonTrail` | Traînées d'étincelles assorties et ruban de traînée tactile selon le type d'effet |
| Auras de Soin et Bouclier | `CrossParticle`, `ShieldDome` | 20 croix dorées/vertes montantes pour le heal; dôme cyan scanline pulsant pour le blocage |
| Icônes vectorielles canvas | `effect_icon.dart` | Dessin personnalisé (écu, épées croisées, goutte, étoile, flamme, flocon de neige, éclair) avec flou glow à la main sur canvas |
| Clarté des infobulles (Tooltips) | `ui_card.dart`, `card_component.dart` | Explications mécaniques parentthésées et localisées pour tous les statuts (poison, brûlure, gel, élec, faiblesse, vulnérable) |
| Cohérence visuelle HUD | `status_effects_panel.dart`, `status_indicator.dart` | Mappage complet d'émojis (🔥, ❄️, ⚡, ✊) et d'icônes Flutter harmonisés pour le joueur et les ennemis |
| Texte flottant de dégâts | `FloatingText` | `MoveEffect` ascendant + `OpacityEffect` fade, ~1.5s |
| Animations d'attaque ennemie | `EnemyCard.dashAnimation()` | `MoveEffect` avant/arrière |
| Barre de vie dynamique | `HealthBar` | Interpolation couleur green→yellow→red, transition animée |
| Badges de stats vectoriels | `StatBadge` | Dessin custom, pulse de scale au changement |
| Animations de cartes data-driven | `CardData.animation` | Types : melee, magic, buff, poison, fire, ice, lightning |
| Layout main en arc | `HerosDraftGame._layoutHand()` | Arc circulaire, radius = `size.y * 1.5`, angle adaptatif |
| Carrousel de reliques interactif | `RelicRewardCarouselOverlay` | Machine à sous PageView viewportFraction (0.85x scale/0.4 opacity sur les côtés, 1.0x/1.0 au centre), décélération cubique, célébration Canvas particles, bouton sécurisé, callbacks audio (`onTick`/`onLand`) |
| Draft Reels Séquentiels | `DraftCardReel`, `DraftScreen` | Révélation machine à sous vertical spinner (0.8s, 1.4s, 2.0s), 3D flip axe Y, célébration légendaire (screen shake, gold particles, flash) et sound hooks |

### 💀 Z-Sync Death & Stats System (Système de Mort et de Stats Synchronisé)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Retardement des morts en combat | `isCardAnimating` & `isPendingDeath` | Deferre le scale-down et fondu de disparition de l'ennemi mort si une carte s'anime |
| Synchronisation des statistiques HUD | `_pendingVisualInstance` & `resolvePendingVisualStats()` | Diffère la diminution visuelle des HP et de l'armure dans le HUD jusqu'à l'instant exact de l'impact de la carte |
| Libération à l'impact | `resolvePendingDeaths()` | Déclenche instantanément la mort de tous les ennemis différés et applique les stats différées à la complétion du coup |
| Morts/Stats hors combat instantanées | Bypass automatique | Les morts/stats hors combat (poison de début de tour) contournent Z-Sync et se résolvent de suite |

### ✨ Statuts Élémentaires (`burn`, `freeze`, `shock`)

| Statut | Implémentation | Effet Mécanique | Résolution |
|:---|:---|:---|:---|
| Brûlure (`burn`) | `CombatController.startEnemyTurn()` | Dégâts directs = valeur du statut | Début du tour de l'ennemi ciblé (similaire au poison) |
| Gel (`freeze`) | `CombatController.resolveEnemyIntent()` | Division par deux (`×0.5` arrondi) des dégâts d'intention d'attaque | Lors de l'attaque de l'ennemi gelé |
| Électrocution (`shock`) | `EffectResolver.resolveCard()` | Ajoute la valeur du statut aux dégâts subis par l'ennemi | Lors de la résolution d'une carte d'attaque |

### 🧪 Fiabilité et Assurance Qualité

| Métrique | Valeur | Détails |
|:---|:---|:---|
| Tests automatisés | **65** (100% VERT) | Tests unitaires et widget-tests |
| Couverture estimée | **~15-20%** | Principalement logique/controllers, pas d'UI |
| Analyse statique | **0 erreur, 0 warning, 0 info** | `flutter analyze` vierge |
| Linter | `flutter_lints` v6.0.0 | Configuration standard, pas de règles custom |

---

## 2. Fonctionnalités Partiellement Implémentées (Dette Métier)

### ⚠️ Statut `vulnerable`

| Aspect | État |
|:---|:---|
| Déclaré dans `StatusType` et `EffectResolver._createStatus()` | ✅ |
| Affichable dans l'UI (`StatusEffectsPanel`) | ✅ |
| Applicable via `apply_status` | ✅ |
| **Pris en compte dans `_calculateDamage()`** | ❌ **ABSENT** |
| **Impact** : Le statut existe visuellement mais n'augmente PAS les dégâts reçus | — |

### ⚠️ Système Audio

| Aspect | État |
|:---|:---|
| Commentaires `// TODO: Audio Hook` | Disséminés dans les fichiers d'effets et interactions |
| Dépendance `flame_audio` dans `pubspec.yaml` | ❌ ABSENTE |
| Service `AudioService` | ❌ ABSENT |
| Fichiers audio dans `assets/` | ❌ ABSENTS |

### ⚠️ Sérialisation Partielle des Modèles

| Modèle | `fromJson` | `toJson` | `copyWith` | `==`/`hashCode` |
|:---|:---:|:---:|:---:|:---:|
| `CombatState` | ✅ | ✅ | ✅ | ❌ |
| `EnemyInstance` | ✅ | ✅ | ✅ | ❌ |
| `EnemyIntent` | ✅ | ✅ | — | ❌ |
| `EntityStats` | ✅ | ✅ | ✅ | ❌ |
| `StatusEffect` | ✅ | ✅ | ✅ | ❌ |
| `MapNode` | ✅ | ✅ | — | ❌ |
| `CardInstance` | ❌ | ❌ | ✅ | ❌ |
| `EventState` | ❌ | ❌ | ✅ | ❌ |
| `InventoryState` | ❌ | ❌ | ✅ | ❌ |
| `ShopState` | ❌ | ❌ | ✅ | ❌ |
| `SkillState` | ❌ | ❌ | ✅ | ❌ |

---

## 3. Fonctionnalités Non Implémentées (Backlog)

Issues du backlog `docs/possible_upgrades/upgrade_ideas.md` (~95 items, ~60% résolus) :

### Gameplay & Mécanique
- [ ] Restrictions de cartes par classe (ex: Berserker ne peut pas utiliser cartes d'armure)
- [ ] Coût de merge +1 mana par level de carte
- [ ] Limite de taille de deck (15 max, extensible via récompenses légendaires)
- [x] Système XP/level pour gating des récompenses
- [ ] Statistique de coup critique (dégâts et soins)
- [ ] Intentions ennemies cachées en late game
- [ ] Scaling progressif d'armure ennemi par acte

### Contenu
- [ ] Tutoriel / système "How-to-play"
- [ ] Icônes de type de dégâts (feu, glace, poison) sur les descriptions
- [ ] Rework des cartes élémentaires (certaines status-only, d'autres damage+status)
- [ ] Nœuds Trésor et Mystère sur la carte
- [ ] Rencontre d'échange de reliques (3 reliques → 1 rareté supérieure)
- [ ] Onglet Reliques dans le dictionnaire

### Méta-Progression
- [ ] Skins de héros débloquables
- [ ] Monnaie persistante entre les runs
- [ ] Système d'achievements/trophées
- [ ] Menu de patch notes sur l'écran d'accueil

### Carte & Navigation
- [ ] Contraintes de génération (pas 3 nœuds identiques consécutifs)
- [ ] Randomisation du deck de départ avec pools par classe
- [ ] Divergence de chemins (routes multiples vers boss)

### UX & Visuel
- [ ] Redesign des snackbar/notifications
- [ ] Redesign descriptions de cartes (icônes-only, descriptions dans tooltips)
- [ ] Rework forge du feu de camp (choix de forge limités)
- [ ] Synergies reliques avec cartes début/fin de tour

### Système
- [ ] PvP draft mode (théorique)
- [ ] Boss multi-phases

---

## 4. Chantiers de Refactoring Prioritaires (Roadmap Dette Technique)

Basé sur les rapports de dette technique (`technical_debt_report_Opus4.6.md`, 4 rapports Gemini 3.5) et les 4 plans d'implémentation de refactoring.

### 🔴 Phase 1 — Fondations (Semaines 1-2)

| Priorité | Chantier | Problème | Solution | Fichiers |
|:---|:---|:---|:---|:---|
| Critique | Typage des modèles | `==`/`hashCode` absents sur 12 modèles, `Map<String, dynamic>` non typés | Ajouter `freezed` ou implémenter manuellement | `lib/models/` (11 fichiers) |
| Critique | Immuabilité réelle des listes | Listes mutables dans états "immuables" | `List.unmodifiable()` systématique | Tous les controllers |
| Critique | Validation des entrées | `gainGold(-50)` fonctionne, HP peut dépasser maxHP | Ajouter validation dans chaque mutation | `run_controller.dart`, `inventory_controller.dart` |
| Important | Error handling I/O | Aucun `try-catch` dans `GameDataService` | Wrapping avec fallbacks gracieux | `game_data_service.dart` |
| Important | Design System | Pas de `AppColors`, `AppTextStyles` — 100+ magic constants | Créer `lib/ui/theme/` | Nouveau fichier |
| Moyen | Lookup O(1) | `GameDataRegistry` utilise `List` avec O(n) | Migrer vers `Map<String, T>` | `game_data_registry.dart` |

### 🟡 Phase 2 — Décomposition God Classes (Semaines 3-4)

| Priorité | Chantier | Problème | Solution | Impact |
|:---|:---|:---|:---|:---|
| Critique | `map_screen.dart` | **2 471 lignes**, 10+ responsabilités | Extraire `MapPainter`, `MapNodeWidget`, `MapLegend`, `MapTooltip`, `MapController` | 2471 → ~400 lignes |
| Critique | `game_screen.dart` | **1 667 lignes**, 5 overlays privés | Extraire `PauseOverlay`, `RewardOverlay`, `DeathOverlay`, `VictoryOverlay`, `HudPanel`, `CombatOrchestrator` | 1667 → ~500 lignes |
| Critique | `card_component.dart` | **1 031 lignes**, render + drag + targeting + animation + tooltip | Extraire `CardRenderer`, `CardAnimationController`, `CardInteractionHandler` | 1031 → ~300 lignes |
| Important | `heros_draft_game.dart` | **775 lignes**, 18 callbacks constructeur | Extraire layout, sync, factories | 775 → ~400 lignes |
| Important | `stat_badge.dart` | **720 lignes**, 5 classes, recreate all children à chaque update | Extraire classes, optimiser update | Performance + lisibilité |

### 🟢 Phase 3 — Qualité (Semaines 5-6)

| Priorité | Chantier | Problème | Solution |
|:---|:---|:---|:---|
| Important | Couverture tests | ~15-20% estimée | Atteindre ≥50%, ajouter widget tests UI |
| Important | Magic constants | 100+ valeurs codées en dur | Extraire dans `GameConstants` étendu |
| Important | `EffectResolver` pattern | Classe statique avec switch géant | Migrer vers Strategy/Command pattern |
| Important | Logique dans Flame | `executeSkill()` calcule des dégâts dans `HerosDraftGame` | Déplacer vers un controller dédié |
| Moyen | Logique dans UI | Shop/event/heal/reward dans les écrans | Déplacer vers controllers |

### 🔵 Phase 4 — Long Terme (Semaines 7+)

| Priorité | Chantier | Problème | Solution |
|:---|:---|:---|:---|
| Critique | Persistance / Sauvegarde | Aucune — RAM uniquement | `SaveService` via `shared_preferences` ou SQLite, auto-save, "Reprendre la partie" |
| Important | Routage centralisé | 20+ `Navigator.push` hardcodés | `GoRouter` avec routes nommées |
| Important | Système Audio | Aucun — `// TODO: Audio Hook` | `flame_audio`, `AudioService` central, musiques dynamiques, effets contextuels |
| Important | Event Bus | 18 callbacks constructeur dans `HerosDraftGame` | Pattern Event Bus pour découpler |
| Moyen | `SkillData` i18n | Champ `name` unique (pas bilingue) | Migrer vers `nameEn`/`nameFr` |
| Moyen | `MapNode` découplage | Importe `Vector2` de Flame dans le modèle de données | Utiliser des types natifs Dart |

---

## 5. Problèmes d'Équilibrage Identifiés

Issus de `docs/analysis_reports/6_analyse_game_balance.md` (documentés, non corrigés) :

| Problème | Impact | Correction Recommandée |
|:---|:---|:---|
| Économie de mana brisée | Héros 5-15 mana, cartes 0-3 → mana rarement limitant | Standardiser 3-4 mana/tour OU multiplier HP ennemis ×3-4 |
| Paladin invulnérable | 20 armure de base rend les ennemis early inoffensifs | Remplacer par passif scalé (+2 armure/tour) |
| HP ennemis trop bas | Squelette (22 HP) meurt en 1-2 tours | Multiplier HP par 2-3× |
| `Attaque Rapide` OP | 0 mana, 3 dégâts + 1 pioche = avantage carte gratuit | Supprimer pioche OU ajouter 1 mana de coût |
| Heal répétable | `Potion de Soin` (2 mana, 8 HP) mine la tension | Rendre les cartes de soin exhaustibles |

---

## 6. Références aux Fichiers de Documentation

| Document | Chemin | Contenu |
|:---|:---|:---|
| Rapport dette technique principal | `docs/analysis_reports/technical_debt_report_Opus4.6.md` | 833 lignes, analyse la plus complète |
| Rapports Gemini 3.5 (×4) | `docs/analysis_reports/dette_technique_rapport_Gemini3.5*.md` | Analyses spécialisées par domaine |
| Plans de refactoring (×4) | `docs/analysis_reports/26-05-2026_Refactoring_Phase*_implementation_plan.md` | Plans détaillés par phase |
| Système de récompenses | `docs/reward_and_luck_system.md` | Spécification luck + rareté |
| Système de passifs | `docs/système_de_passifs.md` | Design document passifs héros |
| Carte du monde | `docs/world_map_system.md` | Spécification DAG procédural |
| Stratégie de migration | `docs/stratégies_migrations.md` | Flutter/Flame vs alternatives (Godot recommandé si migration) |
| Backlog d'upgrades | `docs/possible_upgrades/upgrade_ideas.md` | 95 items, ~60% réalisés |
| Phases implémentées | `docs/implementation_plans/done/` | 22 fichiers de phases complétées |
| Leçons apprises | `docs/lessons/` | `flame_riverpod_sync.md`, `state_immutability.md` |
