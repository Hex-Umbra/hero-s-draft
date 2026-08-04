# 📊 État du Projet & Progrès

> [!IMPORTANT]
> **Plafond : 300 lignes.** Ce fichier décrit **ce qui est construit**, jamais ce qui reste à faire — voir `docs/ROADMAP.md`.

## Métriques

**Vérifié le 2026-08-03**

| Métrique | Valeur | Commande |
|:---|:---|:---|
| Tests automatisés | 212 au vert | `flutter test` |
| Analyse statique | 0 erreur (`No issues found!`) | `dart analyze` |
| Fichiers Dart (`lib/`) | 169 | `find lib -name "*.dart" \| wc -l` |
| Lignes de code (`lib/`) | 36 343 | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | 10 | `ls assets/data/*.json \| wc -l` |

> [!NOTE]
> **La version ne vit pas ici.** La version de référence se lit dans `pubspec.yaml`
> (champ `version:`) et dans la 1ʳᵉ entrée de `assets/data/patch_notes.json` — les deux
> sont écrits ensemble par le skill `patch-notes-writer`, seul propriétaire du numéro.
> La recopier dans ce fichier lui donnerait un second domicile et la ferait diverger
> au prochain patch note.

## 1. Fonctionnalités opérationnelles

### 💾 Sauvegarde (Autosave)

| Fonctionnalité | Fichiers clés | Détails |
|:---|:---|:---|
| Autosave à checkpoint carte | `SaveService`, `checkpointProvider`, `autosaveOrchestratorProvider` | `shared_preferences`, slot unique, JSON versionné (`schemaVersion`), à chaque nœud résolu, jamais en cours de combat |
| Réhydratation des contrôleurs | `RunController.hydrate()`, `DeckNotifier`, `InventoryController`, `SkillController` | Remplacement intégral de l'état depuis les données chargées, navigation directe vers `MapScreen` |
| Reprise depuis l'accueil | `HomeScreen` | Bouton « Continuer » (si `SaveService.hasSave()`), confirmation avant écrasement ; réactivité après retour via `Navigator.popUntil` corrigée — [ADR-073](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md) |
| Dégradation gracieuse du contenu manquant | `MissingSaveItem`, `SaveLoadResult.missingItems` | Élément supprimé du catalogue depuis la sauvegarde : retiré silencieusement, signalé nommément au chargement |
| Sauvegarde corrompue = échec total | `SaveService.load()` | JSON illisible ou `schemaVersion` inconnue → échec propre, pas de récupération partielle |
| Fin de run | `GameOverScreen` | Sauvegarde effacée à la mort du héros |

Design complet — [ADR-069](../_adr/ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md).

### 🗺️ Carte du Monde (World Map)

| Fonctionnalité | Fichiers clés | Détails |
|:---|:---|:---|
| Graphe Acyclique Dirigé (DAG) | `MapGeneratorService`, `MapNode` | 10 étages, largeur 2-5 nœuds, chokepoint étage central dynamique, repos garanti étage `floors-2`, boss unique étage final |
| Distribution et quotas équilibrés | `MapGeneratorService._randomNodeType`, `._balanceQuotas` | Probabilités par type (60% combat, 15% event, 10% shop, 10% rest, 5% elite) puis rééquilibrage par quotas |
| Anti-répétition et chokepoints forcés | `MapGeneratorService._optimizeMapTypes` | Interdit 3 nœuds Élite/Repos consécutifs ; étage central Élite forcé ; étage `floors-2` Repos forcé |
| Level Up différé sur la carte | `RunController`, `MapScreen`, `GameScreen` | Gains de niveau → `pendingDrafts` ; overlay bloquant « LEVEL UP ! » sur la carte |
| Embranchement et récompenses de Boss uniques | `MapGeneratorService`/`EncounterSystem`, `RewardController`, `BossCardDraftScreen` | 3 branches de boss distinctes, récompenses différenciées par position (clonage, or/xp triplés, relique) |
| Rencontre d'Échange de Reliques | `MapGeneratorService`, `InventoryController`, `RelicExchangeScreen` | Nœud `relicExchange` (Acte 5+), offre déterministe par seeded random, échange 3 reliques R-1 → 1 rareté R |
| Nœud Forge de Fusion | `MapGeneratorService`, `MapContentPlacer`, `MapNodeWidget` | Nœud `forgeFusion`, 25% de probabilité sur les étages 3 à 7 — [ADR-074](../_adr/ADR-074-introduction-de-la-forge-de-fusion-procedurale-et.md) |
| Navigation et rendu | `RunController.travelToNode()`, `MapScreen` | Validation d'accessibilité, caméra centrée, widgets dédiés par type, barre d'XP HUD |

### 🧠 Contrôleurs (Riverpod)

| Fonctionnalité | Controller/Provider | Détails |
|:---|:---|:---|
| Modernisation Riverpod | Tous les providers | `Notifier`/`NotifierProvider` Riverpod 2.x, communication inter-contrôleurs via `ref.read`, immuabilité stricte de `CardInstance` |
| Logique de Run (façade) | `RunController`/`runProvider` | Délègue à `PlayerStatsManager`, `MapProgressionManager`, `GoldManager` (`lib/game/controllers/run/`) ; persistance via `SaveService` et `lib/game/controllers/checkpoint_controller.dart`, `hydrate()` porté par `RunController` lui-même |
| Logique de Combat (façade) | `CombatController`/`combatProvider` | Délègue à `StatusEffectProcessor` et `TurnPhaseManager` (`lib/game/controllers/combat/`) |
| Persistance Forge v2 | `RunController`/`runProvider` | Session de forge anti-exploit (`forgeSlots`, `forgeTargetCardId`), slots bonus à coût progressif |
| Progression XP | `RunController.gainXp()`, `PlayerStatsManager` | Progression exponentielle, gains multiples, carry-over |
| Échelonnement des ennemis | `CombatController.initializeCombat()` | Multiplicateurs dynamiques par acte — détail en §Combat |
| Piles de cartes | `DeckNotifier`/`deckProvider` | 5 piles logiques (Master, Draw, Hand, Discard, Exhaust) |
| Économie, compétences, événements, boutique, récompenses | `InventoryController`, `SkillController`, `EventController`, `ShopController`, `RewardController` | Or/reliques à charges, cooldowns de compétences, résolution d'événements, achat/clone/reroll boutique, tirage post-victoire |
| Logique de Fusion | `DeckNotifier`, `InventoryController` | Fusion d'améliorations identiques, déduction d'or, mise à jour de la carte via `setForgeUpgrades` |

### 🃏 Cartes et Deck

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Auto-Merge (3→1) | `DeckNotifier.mergeCards()` | 3 copies même ID + rareté → 1 copie rareté supérieure ; cartes `unique` non fusionnables |
| Foil Unique Progressif | `PolychromaticBorder`, `UiCard` | Bordure polychromatique au survol, nombre de couleurs croissant avec les upgrades |
| Rareté Dynamique | `EffectResolver.resolveCard()` | Progression par rareté (common → legendary), rareté `unique` fixée à ×1.0 |
| Catalogue de cartes | `assets/data/cards.json`, `assets/data/hero_cards.json` | 23 cartes : 17 globales (communes) + 6 de classe (unique) |
| Effets et exhaust | `EffectResolver`, `CardEffect`, `DeckNotifier.playCard()` | damage/heal/armor/draw/gain_mana/apply_status ; Power et `isExhaust` → pile d'épuisement |
| Forge et Fusion | `DeckNotifier.addForgeUpgrade()`, `ForgeUpgradeDialog`, `ForgeFusionScreen` | Upgrades pilotées par `assets/data/forge_upgrades.json`, cumulables sans limite |
| Draft (départ, post-combat) et suppression | `DraftScreen`, `StarterDeckDraftScreen`, `DeckNotifier.removeCardById()` | 3 choix post-victoire, 5 cartes globales au départ, oubli au feu de camp |

### ⚔️ Combat

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Pipeline de dégâts et armure | `EffectResolver._calculateDamage()`, `EntityStats.takeDamage()`, `RunController.addArmor()` | Armure absorbe en priorité, `armorMastery` sur tout gain d'armure, reset à 0 en début de tour joueur |
| Fin de tour : synchronisation et double confirmation | `lib/ui/screens/game_screen.dart` | Phase synchronisée à l'entrée du tour joueur ; confirmation supplémentaire si mana restant — [ADR-076](../_adr/ADR-076-synchronisation-synchrone-du-bouton-fin-de-tour.md), [ADR-065](../_adr/ADR-065-double-confirmation-de-fin-de-tour-avec-mana-resta.md) |
| Intentions ennemies et phase séquentielle | `CombatController._rollIntent()`, `HerosDraftGame._enemyRipostePhase()` | Cycle prédéfini ou aléatoire (60% atk/25% def/15% buff), résolution intent par intent animée |
| Statuts et nettoyage des morts | `EntityStats.addStatus()`/`.tickStatuses()`, `CombatController._cleanDeadEnemies()` | Stacking, tick de durée, auto-sélection du prochain ennemi, trigger `onEnemyKilled` |
| Difficulté hybride et réserve d'ennemis | `EncounterSystem`, `CombatController`, `CombatState` | Formule DDA amortie, limite de 5 ennemis actifs avec `pendingEnemies` |
| Scaling géométrique et déblocage de tier | `EncounterSystem.getHpActFactor`/`.getDamageActFactor`/`.getUnlockedTier` | Palier géométrique HP/Dégâts tous les 2 actes, tier d'ennemi débloqué tous les 5 actes — [ADR-070](../_adr/ADR-070-scaling-de-difficulte-en-escalier-geometrique-debl.md), [ADR-072](../_adr/ADR-072-resserrement-de-la-cadence-du-scaling-de-difficult.md) |
| Plafond du nombre d'ennemis par acte | `EncounterSystem.getMaxEnemiesForNormalCombat`/`.Elite`/`.Boss` | Croissant avec l'acte, différencié combat/élite/boss — [ADR-071](../_adr/ADR-071-plafonnement-du-nombre-d-ennemis-par-acte-resoluti.md) |
| Décomposition des écrans de combat/carte | `lib/ui/screens/map_screen.dart` (418 lignes), `lib/ui/screens/game_screen.dart` (555 lignes) | Chantiers de refactoring Phase 2 achevés (god classes historiquement à 2471/1667 lignes) — historique dans `.obsidian_vault/_archive/2026-08-03-progress-historique.md` |

### 🏆 Passifs et Traits de Héros

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Passifs data-driven | `assets/data/passives.json` → `TraitSystem` | 3 passifs liés aux héros par `HeroData.passiveTrait` |
| Triggers multiples | `TraitSystem.onTurnStart`/`.onTurnEnd`/`.onCardPlayed` | Logique spécifique par `effectType` (`gain_armor`, `berserker_armor`, `spell_armor`) |
| Reliques à triggers | `RunController.applyRelics(trigger)` | 9 types de triggers (startOfRun → onEnemyKilled) |
| Reliques à charges | `RunController.applyRelicEffect()` | Croc Kunaï, Shuriken, Plume de Scribe, Encensoir — compteurs visuels via `StatusEffect` |

### 🈳 Internationalisation (i18n)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| UI 100% localisée | `AppLocalizations` (ARB) | Zéro chaîne codée en dur |
| Modèles bilingues | `nameEn`/`nameFr` | Sauf `SkillData` (champ `name` unique — dette connue) |
| Statuts localisés | `StatusEffectsPanel` | Traduction dynamique depuis identifiants techniques |
| Langues supportées | `app_en.arb`, `app_fr.arb` | Français + Anglais |

### 🎨 Rendu, Design System et Jus Visuel

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Modularité Flame et cartes | `lib/game/systems/` (StateSync, CardAnimation, CombatVisual, Layout), `lib/game/components/widgets/` (`CardRenderer`, `CardInteractionHandler`) | `HerosDraftGame` et `CardComponent` en façades déléguant à des sous-systèmes |
| Système de design centralisé | `AppColors`, `AppSpacing`, `AppTheme` (`lib/ui/theme/`) | Thème dark/light complet, extensions `.color` sur les enums de rareté |
| Composants UI communs | `ScreenScaffold`, `PageHeader`, `GoldIndicator`, `UiCard` (`lib/ui/widgets/ui_card/`) | Arrière-plans/SafeArea/PopScope centralisés, factories `fromInstance`/`fromData` |
| Décomposition des god classes UI | `UiCard`, `CardComponent`, `MapScreen`, `GameScreen` | Refactoring Phases 2-3 achevé — historique dans `.obsidian_vault/_archive/2026-08-03-progress-historique.md` |
| Jus visuel de dégâts et impacts | `CardComponent`, `EnemyCard` | Secousses, rebond élastique, flashes de sprite, particules radiales |
| Système de mort et de stats synchronisé (Z-Sync) | `isPendingDeath`, `resolvePendingDeaths()` | Diffère morts/stats HUD jusqu'à l'impact réel de la carte animée — [ADR-013](../_adr/ADR-013-systeme-de-mort-et-de-stats-synchronise-z-sync.md) |
| Texte flottant et HUD | `FloatingText`, `HealthBar`, `StatBadge`, `ManaIndicator` | Textes néon thématiques, jauge HP dual-bar, badges vectoriels |
| Carrousel de reliques et Draft Reels | `RelicRewardCarouselOverlay`, `DraftCardReel` | Machine à sous PageView, célébration légendaire, masquage anti-spoil |
| Optimisations de rendu | `FloatingText`, `EffectIcon`, `CardComponent` | Suppression des `saveLayer` redondants, caching des layouts de texte |
| Tooltips et clarté de ciblage | `UiCard`, `CardComponent` | Doublement d'icônes pour cibles multiples, tooltips localisés focus-only |
| Layout de main et caméra carte | `HerosDraftGame._layoutHand()`, `MapScreen` | Arc circulaire adaptatif, caméra recentrée à chaque transition |
| HUD de combat responsive | `GameScreen` | Redimensionnement automatique avec clamps anti-clipping |

### ✨ Statuts Élémentaires et Vulnérabilité

| Statut | Implémentation | Effet Mécanique | Résolution |
|:---|:---|:---|:---|
| Brûlure (`burn`) | `CombatController.startEnemyTurn()` | Dégâts directs = valeur du statut (décrémente de 1) | Début du tour de la cible |
| Gel (`freeze`) | `CombatController.resolveEnemyIntent()` | Division par deux de l'attaque, décrémente immédiatement | Attaque de l'entité gelée |
| Électrocution (`shock`) | `EffectResolver.resolveCard()` | Ajoute la valeur cumulée aux dégâts directs subis | Résolution d'une attaque directe |
| Vulnérabilité (`vulnerable`) | `EffectResolver.resolveCard()` | +50% sur tous les dégâts d'attaque reçus | Universel (joueur et ennemis) |

### 🎓 Tutoriel Autonome

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Moteur local | `TutorialEngine`, `TutorialMockState` | `ChangeNotifier` gérant la progression, état simulé réinitialisé par étape |
| 13 étapes interactives | `TutorialScreen`, `lib/tutorial/widgets/` | Guidage pas-à-pas couvrant le gameplay de base |
| Ciblage double phase et info-bulles | `TutorialPlayCardWidget`, `TutorialCardsWidget` | Ciblage en deux temps, icônes vectorielles canvas et tooltips localisés |
| Persistance et badge « NEW » | `TutorialProgressService`, `HomeScreen` | Complétion sauvegardée en `shared_preferences` |
| Responsivité | `LayoutBuilder`, `FittedBox`, `Wrap` | Ajustements multi-résolutions (mobile, web, desktop) |

## 2. Dette métier assumée

### ⚠️ Système Audio

| Aspect | État |
|:---|:---|
| Commentaires `// TODO: Audio Hook` | 1 occurrence mesurée (`lib/game/components/floating_text.dart`) |
| Dépendance `flame_audio` dans `pubspec.yaml` | ❌ ABSENTE |
| Service `AudioService` | ❌ ABSENT |
| Fichiers audio dans `assets/` | ❌ ABSENTS |

Absence délibérée — [ADR-012](../_adr/ADR-012-absence-de-systeme-audio.md).

### ⚠️ Sérialisation Partielle des Modèles

| Modèle | `fromJson` | `toJson` | `copyWith` | `==`/`hashCode` |
|:---|:---:|:---:|:---:|:---:|
| `CombatState` | ✅ | ✅ | ✅ | ❌ |
| `EnemyInstance` | ✅ | ✅ | ✅ | ❌ |
| `EnemyIntent` | ✅ | ✅ | — | ❌ |
| `EntityStats` | ✅ | ✅ | ✅ | ❌ |
| `StatusEffect` | ✅ | ✅ | ✅ | ❌ |
| `MapNode` | ✅ | ✅ | — | ❌ |
| `RunState` | ✅ (`fromJsonWithReport`) | ✅ | ✅ | ❌ |
| `DeckState` | ✅ (`fromJsonWithReport`) | ✅ | ✅ | ❌ |
| `CardInstance` | ❌ | ❌ | ✅ | ❌ |
| `EventState` | ❌ | ❌ | ✅ | ❌ |
| `InventoryState` | ✅ (`fromJsonWithReport`) | ✅ | ✅ | ❌ |
| `ShopState` | ❌ | ❌ | ✅ | ❌ |
| `SkillState` | ✅ | ✅ | ✅ | ❌ |

## 3. Références documentaires

**Vérifié le 2026-08-03** — chaque chemin testé avec `test -e`.

| Document | Chemin | Contenu |
|:---|:---|:---|
| Rapport dette technique principal | `docs/analysis_reports/technical_debt_report_Opus4.6.md` | Analyse la plus complète |
| Rapports dette technique Gemini 3.5 | `docs/analysis_reports/` | 5 rapports dette_technique_rapport_Gemini3.5*.md |
| Plans de refactoring (historique, chantiers clos) | `docs/analysis_reports/` | 4 plans 26-05-2026_Refactoring_Phase*_implementation_plan.md |
| Système de récompenses | `docs/archives/reward_and_luck_system.md` | Spécification luck + rareté |
| Système de passifs | `docs/archives/système_de_passifs.md` | Design document passifs héros |
| Carte du monde | `docs/archives/world_map_system.md` | Spécification DAG procédural |
| Stratégie de migration | `docs/archives/stratégies_migrations.md` | Flutter/Flame vs alternatives |
| Backlog d'upgrades (historique) | `docs/possible_upgrades/upgrade_ideas.md` | Backlog actif désormais dans docs/ROADMAP.md |
| Phases implémentées | `docs/implementation_plans/done/` | 26 fichiers de phases complétées |
| Leçons apprises | `docs/lessons/concept_mastery.md`, `docs/lessons/flame_mastery.md`, `docs/lessons/riverpod_mastery.md` | Trois leçons capitalisées |

## 4. Historique des releases (10 dernières)

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v3.5.1** | 2026-07-26 | Correction de la Réactivité du Bouton « Continuer » (HomeScreen) | `HomeScreen._continueGame()`/`_startNewGame()` naviguent via `Navigator.push`, mais le menu pause et `GameOverScreen` reviennent à l'accueil via `Navigator.popUntil((route) => route.isFirst)`, qui ne reconstruit pas `HomeScreen` ni ne réévalue `SaveService.hasSave()` : le bouton « Continuer » pouvait rester dans un état obsolète jusqu'au redémarrage de l'application. Correctif : les deux méthodes attendent désormais (`await`) leur `Navigator.push` et appellent `setState(() {})` à son retour. Nouveau test `test/widget/home_screen_save_test.dart` (95 lignes). Commit `17564b4`, mergé avec ADR-072 via PR #22. Voir ADR-073. |
| **v3.5.0** | 2026-07-26 | Accélération de la Cadence du Scaling de Difficulté | Resserrement de la cadence du système introduit par ADR-070/071 suite à un retour de playtest (le joueur montait en puissance plus vite que les ennemis) : le palier géométrique HP/Dégâts (`_actBracketSize`) passe de 5 à 2 actes (bases x1.35 HP / x1.25 Dégâts et rampe intra-palier inchangées) et le déblocage de tier (`_tierUnlockBracketSize`) de 10 à 5 actes (tier 2 dès l'Acte 6, tier 3 dès l'Acte 11). Aucune autre formule modifiée (budget, plafond d'ennemis ADR-071, puissance du joueur). Effet secondaire assumé : fenêtre de contenu tier-1-only resserrée des Actes 1-10 aux Actes 1-5. 2 commits TDD (`97c5fcb`, `8bc1920`), suite de tests complète 211/211 au vert, `dart analyze` propre. Voir ADR-072. *(Branche `fix/combat_scaling` mergée vers `main` via PR #22 ; patch note joueur v0.4.6 rédigé — voir `assets/data/patch_notes.json`.)* |
| **v3.4.0** | 2026-07-25 | Plafonnement du Nombre d'Ennemis par Acte & Résolution de la Dérive Log/Calcul | Suite directe d'ADR-070 sur la même branche `feature/combat_scaling` (mergée avec PR #21) : plafond du nombre d'ennemis générés par combat, croissant avec l'Acte et différencié combat normal/élite/boss (+1/acte, +1/2 actes, +1/5 actes respectivement, sans plafond ultime), remplaçant l'ancienne limite fixe de 10 — empêche l'empilement de plusieurs ennemis tier-1 faibles pour épuiser un budget élite/boss. Corrige aussi la dérive confirmée entre le log de debug (`math_combat.md`) et le calcul réel de budget (`playerCardsCount`, `+(act-1)*10` manquants dans le log) via un unique `EncounterSystem.calculateBudget()`. Voir ADR-071. *(Patch note joueur rédigé — v0.4.7 "L'Équilibre des Effectifs", voir `assets/data/patch_notes.json`.)* |
| **v3.3.0** | 2026-07-24 | Scaling de Difficulté en Escalier Géométrique & Déblocage de Tier | Correction d'un double comptage de l'Acte dans `EncounterSystem` (`enemyLevel` + terme linéaire direct dans `getHpMultiplier`/`getDamageMultiplier`) qui provoquait une explosion de difficulté incontrôlée en mode endless. `enemyLevel` devient strictement indépendant de l'Acte ; l'Acte agit désormais via un facteur géométrique par palier de 5 actes (`getHpActFactor`/`getDamageActFactor`, x1.35 HP / x1.25 Dégâts par palier + rampe intra-palier douce réinitialisée). Ajout d'un déblocage de tier d'ennemi tous les 10 actes (`getUnlockedTier`, plafond tier 3), gating strict assumé (Squelette/tier 2 non disponible avant l'Acte 11, contre l'Acte 2 auparavant) créant un backlog de contenu tier-1. 6 commits TDD, 201/201 tests au vert, `dart analyze` propre, revue de code de branche complète. Voir ADR-070. Mergé vers `main` (PR #20). |
| **v3.2.0** | 2026-07-24 | Système de Sauvegarde et Persistance de Run (Autosave) | Résolution du point bloquant de commercialisation ADR-011 : `SaveService` (`shared_preferences`, slot unique, JSON versionné) sauvegardant `RunState`/`DeckState`/`InventoryState`/`SkillState` à chaque checkpoint carte (`checkpointProvider`/`autosaveOrchestratorProvider`), jamais en cours de combat. Bouton "Continuer" et dialogue de confirmation sur `HomeScreen`. Dégradation gracieuse du contenu manquant (cartes/reliques/upgrades/passifs supprimés du catalogue) avec avertissement nommé au joueur. Sauvegarde corrompue traitée comme échec total sans récupération partielle. Sauvegarde effacée à la mort du héros. Suppression du stub mort `RunPersistenceManager`. Voir ADR-069. |
| **v3.1.0** | 2026-07-01 | Forge de Fusion et Forge Data-Driven | Introduction du nœud Forge de Fusion (`MapNodeType.forgeFusion` à 25% de chance) sur les étages 3 à 7. Écran `ForgeFusionScreen` pour fusionner les runes identiques pour un coût de 80 Or. Remplacement des upgrades codés en dur par une structure data-driven (`assets/data/forge_upgrades.json` + `ForgeUpgradeData`). Cumul de runes sans épuisement (alreadyHas retiré). Correction de la navigation au repos : annuler la forge ramène à la sélection de cartes au lieu de quitter au menu du repos. Écriture de tests unitaires (112 tests réussis, 0 erreur). |
| **v0.3.0** | 2026-06-25 | Refonte et Validation du Système d'Événements | Enrichissement visuel et narratif du système de rencontres avec 5 événements bilingues configurés dans `assets/data/events.json`. Conception d'un Safety Gate de validation d'éligibilité (`isSelectable`) bloquant les options en cas d'or insuffisant, de dégâts létaux (`currentHp <= damage`), ou de réduction de PV Max létale. Rendu visuel d'en-tête (PV et Or réactifs) et intégration de badges compacts directement dans les boutons de choix d'options avec transition d'échelle animée après résolution. |
| **v0.2.9** | 2026-06-25 | Équilibrage Boutique et Miroir Magique | Vente de cartes modélisée par instances réelles (`CardInstance`) affichant leurs sockets de runes et raretés dynamiques via `UiCard.fromInstance`. Tarification dynamique (+20 Or par upgrade de forge). Scaling de raretés et d'upgrades par Acte. Nerf anti-exploit du Miroir Magique doublant son coût à chaque achat ($150 \rightarrow 300 \rightarrow 600 \dots$ Or) avec réinitialisation à 150 Or en sortie de session. |
| **v0.2.8** | 2026-06-24 | Résolution du Bug de Clés Dupliquées | Résolution de l'erreur "Duplicate keys found" dans l'overlay de notification en combinant le timestamp en microsecondes avec un suffixe pseudo-aléatoire généré par une instance statique unique de `Random`. Garantit des identifiants uniques stables pour toutes les notifications simultanées. |
| **v0.2.7** | 2026-06-16 | Révision du Scaling et du Spawn des Ennemis | Révision des formules de génération des combats et de scaling de difficulté. Prise en compte du nombre de cartes du deck (`playerCardsCount * 2.0`) dans la puissance estimée du joueur. Ajustement du calcul du Combat Rating des ennemis (division par 4 des PV de base, multiplication par 2 des dégâts) pour encourager le spawn de plus d'ennemis. Augmentation des coefficients de croissance par acte (HP passe de 20% à 35%, dégâts de 15% à 25%). |

> [!NOTE]
> **Le schéma `v3.x` est gelé.** L'historique ci-dessus emploie un schéma interne
> (`v3.x`) distinct de la version joueur de `assets/data/patch_notes.json` (`0.4.x`).
> Depuis le 2026-08-03, la version de référence est celle de `assets/data/patch_notes.json`,
> maintenue conjointement avec `pubspec.yaml` par le skill `patch-notes-writer`.
> **Aucune nouvelle entrée n'emploie le schéma `v3.x`** : les lignes existantes sont
> conservées telles quelles pour leur valeur historique, et toute ligne ajoutée à ce
> tableau est clé sur la version publiée dans `assets/data/patch_notes.json`.
