# 📊 État du Projet & Progrès

> [!IMPORTANT]
> **Plafond : 300 lignes.** Ce fichier décrit **ce qui est construit**, jamais ce qui reste à faire — voir `docs/ROADMAP.md`.

## Métriques

**Vérifié le 2026-08-23**

| Métrique | Valeur | Commande |
|:---|:---|:---|
| Tests automatisés (jeu) | 295 au vert | `flutter test` |
| Fichiers de test | 51 | `find test -name "*.dart" \| wc -l` |
| Analyse statique | 0 erreur (`No issues found!`) | `dart analyze` |
| Fichiers Dart (`lib/`) | 174 | `find lib -name "*.dart" \| wc -l` |
| Lignes de code (`lib/`) | 37 573 | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | 10 | `ls assets/data/*.json \| wc -l` |
| Tests de la logique du site | 20 au vert | `cd site && node --test` |
| Assertions du harnais CI | 57 au vert | `bash .github/scripts/test_scripts.sh` |
| Fichiers suivis sous `site/` | 16 | `git ls-files site/ \| wc -l` |

> [!NOTE]
> Relevé sur `3045971`, augmenté du correctif de lien Discord de cette même passe. Quatre
> lignes ont bougé depuis le 2026-08-20. Le chantier **P-45** a ajouté du code et des tests
> dans `lib/tutorial/` et `test/` ; sa vague de correctifs de fin de revue, puis les deux
> correctifs de jeu entrés dans le même tag par la PR #28, ont ajouté trois fichiers de test
> de plus — `tutorial_merge_transition_test.dart`, `enemy_intents_panel_overflow_test.dart`
> et `level_up_reward_values_test.dart`. Le harnais CI passe de 55 à 57 assertions : le
> titre cliquable de l'annonce Discord mène désormais au site vitrine et non au build
> jouable, et les deux moitiés du message sont verrouillées séparément. `site/_site/js/`
> n'a pas bougé, d'où les 20 tests de site inchangés.

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
| Piles de cartes | `DeckNotifier`/`deckProvider` | 5 piles logiques (Master, Draw, Hand, Discard, Exhaust), invariant de conservation asserté ; remélange à sec et arrêt net sur main pleine — [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md) |
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
| Moteur de pioche | `DeckNotifier._drawInto`, `.drawCards`, `.startCombat`, `deckRandomProvider` | Remélange à sec (défausse → pioche uniquement si pioche vide), arrêt net à `GameConstants.maxHandSize` (10), aléatoire injectable pour les tests de séquence, `DeckState.reshuffleCount` observable |
| Règle de tour joueur | `TurnPhaseManager.startPlayerCombat()`/`.startPlayerTurn()` | Moitié joueur du cycle, symétrique de `startEnemyTurn`/`endEnemyTurn` ; tour 1 et tour N+1 sur le même chemin ; nombre de cartes piochées piloté par `RunState.cardsPerTurn` (défaut 5) |
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
| Décomposition des écrans de combat/carte | `lib/ui/screens/map_screen.dart` (418 lignes), `lib/ui/screens/game_screen.dart` (524 lignes) — **vérifié le 2026-08-06** | Chantiers de refactoring Phase 2 achevés (god classes historiquement à 2471/1667 lignes) — historique dans `.obsidian_vault/_archive/2026-08-03-progress-historique.md`. `game_screen.dart` a encore perdu la règle de tour, le deck de secours et `_turnCount` avec [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md) |

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
| Moteur local, zéro provider d'état | `TutorialEngine`, `TutorialMockState` | `ChangeNotifier` gérant la progression ; tranche persistante (classe, deck) + tranche scratch réinitialisée par étape — [ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md) |
| 15 étapes interactives, choix de classe et draft de départ en amont | `TutorialScreen`, `lib/tutorial/widgets/` | Guidage pas-à-pas depuis le choix de classe jusqu'aux reliques ; étapes 02-03 verrouillées une fois franchies ; détail complet en [`_rules/08-00`](../_rules/08-00-systeme-de-tutoriel-autonome.md) |
| Fixtures résolues contre le registre de données | `tutorial_loader.dart`, `TutorialFixtures` | `gameDataLoaderProvider` lu en un point unique ; cartes/ennemis/reliques affichés sont ceux du jeu (`CardInstance`, `EnemyInstance`), plus de valeurs recopiées à la main |
| Ciblage double phase et info-bulles | `TutorialPlayCardWidget`, `TutorialCardsWidget` | Ciblage en deux temps, icônes vectorielles canvas et tooltips localisés |
| Persistance et badge « NEW » | `TutorialProgressService`, `HomeScreen` | Complétion sauvegardée en `shared_preferences` |
| Responsivité | `LayoutBuilder`, `FittedBox`, `Wrap` | Ajustements multi-résolutions (mobile, web, desktop) |

### 🚀 Chaîne de Release et Site Vitrine

| Fonctionnalité | Fichiers clés | Détails |
|:---|:---|:---|
| Intégration continue | `.github/workflows/ci.yml` | `dart analyze`, `flutter test`, tests JS du site et harnais des scripts sur chaque push et PR |
| Release déclenchée par tag | `.github/workflows/release.yml` | Neuf jobs sur tag `v*.*.*` : builds web et Windows, déploiements, smoke test, pré-release GitHub, annonce Discord |
| Garde-fou de version | `.github/scripts/verify_version.sh` | Compare le tag à `pubspec.yaml`, `assets/data/patch_notes.json` et `site/_site/versions.json` **avant tout build** — [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md) |
| Site vitrine piloté par la donnée | `site/`, `site/_site/versions.json` | Trois pages sans étape de build ni dépendance npm ; jointure version → patch note **déclarée** par le champ `notes`, jamais dérivée de l'`id` — [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md) |
| Déploiement du site | `.github/workflows/site.yml` | rsync vers la racine confinée du VPS ; lançable seul pour une modification de contenu, sans release |

Structure détaillée — [fiche §15](../_patterns/15-00-chaine-de-release-et-site-vitrine.md).

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

**Re-vérifié fichier par fichier le 2026-08-04** — `grep -c "operator ==" <fichier>` et
`grep -n "fromJson\|toJson" <fichier>` sur chacun des 13 modèles. Les colonnes
`CardInstance` et `ShopState` étaient fausses avant cette date (leurs `fromJson`/`toJson`
existent depuis le commit `3b2365c` du 2026-06-24). Seul `EventState` est réellement
dépourvu de sérialisation.

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
| `CardInstance` | ✅ | ✅ | ✅ | ❌ |
| `EventState` | ❌ | ❌ | ✅ | ❌ |
| `InventoryState` | ✅ (`fromJsonWithReport`) | ✅ | ✅ | ❌ |
| `ShopState` | ✅ | ✅ | ✅ | ❌ |
| `SkillState` | ✅ | ✅ | ✅ | ❌ |

## 3. Références documentaires

**Vérifié le 2026-08-20** — chaque chemin testé avec `test -e`, et les trois comptes re-mesurés (5 rapports Gemini, 4 plans de refactoring, 26 phases livrées).

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
| **0.4.9** | 2026-08-23 | L'École du Héros (P-45) | Le tutoriel autonome (`lib/tutorial/`) avait dérivé du jeu réel : 50 écarts relevés, nés d'une règle « zéro Riverpod » qui interdisait aussi l'accès aux données immuables, forçant une recopie manuelle qui a dérivé avec le temps. La règle devient « zéro provider d'*état* » : `gameDataLoaderProvider` est autorisé en un point unique (`tutorial_loader.dart`), les neuf providers d'état restent interdits, critère vérifié par `test/tutorial/tutorial_isolation_test.dart`. Les POJOs du mock (`TutorialCard`, `TutorialEnemy`) sont remplacés par les vrais modèles du jeu (`CardInstance`, `EnemyInstance`, `EntityStats`, `DamagePipeline`). Le parcours passe de 13 à **15 étapes** : choix de classe et draft du deck de départ ajoutés en amont, verrouillés une fois franchis, dont dépendent les étapes suivantes (Armure démontre le passif choisi, Jouer pioche dans ce deck, Fusion y prend une carte réellement draftée). Correctif d'affichage hors tutoriel : la légende de la carte du monde annonçait « Boss (XP & Or x2) » alors que `reward_controller.dart` applique `×3` depuis longtemps — seul l'affichage change, le code de récompense est intact. **45 commits hors merges** depuis `v0.4.8`, **295 tests au vert** (+65), `dart analyze` propre. Voir [ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md). ⚠️ **Deux correctifs de jeu sont entrés dans ce même tag par la PR #28 et ne figurent pas dans la note joueur**, rédigée avant leur fusion. *(1)* `EnemyIntentsPanel` débordait de sa largeur fixe de 250 px dès que le libellé d'intention était long : la bande d'erreur jaune et noire s'affichait en plein HUD de combat, à chaque combat en français, depuis au moins `0.4.8`. Les deux `Row` se replient désormais au lieu de tronquer — la valeur chiffrée est en fin de libellé (« Attaque Dévastatrice : 25 »), une ellipse l'aurait fait disparaître. *(2)* La **Forge d'Acier légendaire** rendait +1 Maîtrise d'Armure, la valeur d'un commun, faute de palier légendaire dans sa cascade de `if` : elle rend désormais **+7**. Les 30 cases type × rareté sont verrouillées par `test/unit/level_up_reward_values_test.dart` et la table est écrite dans [`_rules/06-00`](../_rules/06-00-economie-de-jeu.md) — son absence était la raison pour laquelle rien n'avait signalé le trou. |
| **0.4.8** | 2026-08-20 | La Salle des Archives (P-04) | Chantier **P-04** livré en deux lots, sans que le jeu change : **aucun fichier de `lib/`, `test/` ou `assets/` n'est touché**, et le patch note joueur ne décrit donc que le site. **Lot 1 — chaîne CI/CD** : trois workflows (`ci.yml`, `release.yml` à neuf jobs, `site.yml`), publication réduite à la pose d'un tag `v*.*.*`, garde-fou `verify-version` comparant le tag à `pubspec.yaml`, `patch_notes.json` et `versions.json` **avant tout build**, smoke test HTTP post-déploiement, pré-release GitHub avec le zip Windows, annonce Discord en `continue-on-error`. Toute la logique vit dans cinq scripts shell testables — harnais à **55 assertions**, attentes dérivées à l'exécution par `jq` plutôt que figées. Actions tierces épinglées sur SHA, secrets par `env:` uniquement, accès VPS confiné en écriture seule par `rrsync -wo`. Voir [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md). **Lot 2 — site vitrine** : la page de sélection des versions, jusque-là hors du dépôt et maintenue à la main, devient `site/` — trois pages sans étape de build ni dépendance npm, pilotées par `site/_site/versions.json`, logique pure testée par `node --test` (**20 tests**). La jointure version → patch note passe par un champ `notes` déclaré et nullable, jamais dérivé du nom de dossier : les quatorze dossiers historiques rapportent tous `0.1.0`, et une dérivation aurait produit quatre associations fausses. Voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md). Enrichissement du 20/08 : les quatorze dates relevées sur l'archive locale des builds, et deux jointures déclarées (`v0.0.5` → note `0.0.4`, `v0.0.9` → note `0.0.93`). |
| **0.4.7** | 2026-08-06 | Assainissement du Système de Pioche (P-02) | Le remélange défausse → pioche devient **automatique et à sec** : il n'intervient plus qu'une fois la pioche réellement vide, y compris au milieu d'une pioche. L'ancien seuil `if (drawPile.length < 5)` porté par `game_screen.dart` déclenchait un remélange presque chaque tour et détruisait la capacité à compter son deck ; `shuffleDiscardIntoDraw()` est supprimée. La pioche s'arrête **net** à `GameConstants.maxHandSize` (10) sans consommer de carte ni remélanger. `RunState.cardsPerTurn` (défaut 5) remplace le `5` codé en dur, et `TurnPhaseManager` gagne `startPlayerCombat()`/`startPlayerTurn()` : le tour 1 et le tour N+1 empruntent enfin le même code, et `game_screen.dart` n'anime plus que (perte de `_turnCount` et du deck de secours, 555 → 524 lignes). Aléatoire injectable via `deckRandomProvider`, compteur `DeckState.reshuffleCount` observable et notification joueur. Première relique touchant au deck : `scholars_satchel` (Besace de l'Érudit, legendary, +1 carte/tour), avec `case` symétrique dans `removeRelicEffect`. 6 éléments de code mort supprimés (`temporaryCost`, `IntentType.debuffDeck`, `intentCurse`, `onEnemyDebuffDeck`, `onTurnEnded`, deck de secours). 8 commits TDD, **230/230 tests au vert** (+18 neufs, 2 réécrits), `dart analyze` propre, **playtest de validation passé le 2026-08-06**. Voir [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md). |
| **v3.5.1** | 2026-07-26 | Correction de la Réactivité du Bouton « Continuer » (HomeScreen) | `HomeScreen._continueGame()`/`_startNewGame()` naviguent via `Navigator.push`, mais le menu pause et `GameOverScreen` reviennent à l'accueil via `Navigator.popUntil((route) => route.isFirst)`, qui ne reconstruit pas `HomeScreen` ni ne réévalue `SaveService.hasSave()` : le bouton « Continuer » pouvait rester dans un état obsolète jusqu'au redémarrage de l'application. Correctif : les deux méthodes attendent désormais (`await`) leur `Navigator.push` et appellent `setState(() {})` à son retour. Nouveau test `test/widget/home_screen_save_test.dart` (95 lignes). Commit `17564b4`, mergé avec ADR-072 via PR #22. Voir ADR-073. |
| **v3.5.0** | 2026-07-26 | Accélération de la Cadence du Scaling de Difficulté | Resserrement de la cadence du système introduit par ADR-070/071 suite à un retour de playtest (le joueur montait en puissance plus vite que les ennemis) : le palier géométrique HP/Dégâts (`_actBracketSize`) passe de 5 à 2 actes (bases x1.35 HP / x1.25 Dégâts et rampe intra-palier inchangées) et le déblocage de tier (`_tierUnlockBracketSize`) de 10 à 5 actes (tier 2 dès l'Acte 6, tier 3 dès l'Acte 11). Aucune autre formule modifiée (budget, plafond d'ennemis ADR-071, puissance du joueur). Effet secondaire assumé : fenêtre de contenu tier-1-only resserrée des Actes 1-10 aux Actes 1-5. 2 commits TDD (`97c5fcb`, `8bc1920`), suite de tests complète 211/211 au vert, `dart analyze` propre. Voir ADR-072. *(Branche `fix/combat_scaling` mergée vers `main` via PR #22 ; patch note joueur v0.4.6 rédigé — voir `assets/data/patch_notes.json`.)* |
| **v3.4.0** | 2026-07-25 | Plafonnement du Nombre d'Ennemis par Acte & Résolution de la Dérive Log/Calcul | Suite directe d'ADR-070 sur la même branche `feature/combat_scaling` (mergée avec PR #21) : plafond du nombre d'ennemis générés par combat, croissant avec l'Acte et différencié combat normal/élite/boss (+1/acte, +1/2 actes, +1/5 actes respectivement, sans plafond ultime), remplaçant l'ancienne limite fixe de 10 — empêche l'empilement de plusieurs ennemis tier-1 faibles pour épuiser un budget élite/boss. Corrige aussi la dérive confirmée entre le log de debug (`math_combat.md`) et le calcul réel de budget (`playerCardsCount`, `+(act-1)*10` manquants dans le log) via un unique `EncounterSystem.calculateBudget()`. Voir ADR-071. *(Patch note joueur rédigé — v0.4.7 "L'Équilibre des Effectifs", voir `assets/data/patch_notes.json`.)* |
| **v3.3.0** | 2026-07-24 | Scaling de Difficulté en Escalier Géométrique & Déblocage de Tier | Correction d'un double comptage de l'Acte dans `EncounterSystem` (`enemyLevel` + terme linéaire direct dans `getHpMultiplier`/`getDamageMultiplier`) qui provoquait une explosion de difficulté incontrôlée en mode endless. `enemyLevel` devient strictement indépendant de l'Acte ; l'Acte agit désormais via un facteur géométrique par palier de 5 actes (`getHpActFactor`/`getDamageActFactor`, x1.35 HP / x1.25 Dégâts par palier + rampe intra-palier douce réinitialisée). Ajout d'un déblocage de tier d'ennemi tous les 10 actes (`getUnlockedTier`, plafond tier 3), gating strict assumé (Squelette/tier 2 non disponible avant l'Acte 11, contre l'Acte 2 auparavant) créant un backlog de contenu tier-1. 6 commits TDD, 201/201 tests au vert, `dart analyze` propre, revue de code de branche complète. Voir ADR-070. Mergé vers `main` (PR #20). |
| **v3.2.0** | 2026-07-24 | Système de Sauvegarde et Persistance de Run (Autosave) | Résolution du point bloquant de commercialisation ADR-011 : `SaveService` (`shared_preferences`, slot unique, JSON versionné) sauvegardant `RunState`/`DeckState`/`InventoryState`/`SkillState` à chaque checkpoint carte (`checkpointProvider`/`autosaveOrchestratorProvider`), jamais en cours de combat. Bouton "Continuer" et dialogue de confirmation sur `HomeScreen`. Dégradation gracieuse du contenu manquant (cartes/reliques/upgrades/passifs supprimés du catalogue) avec avertissement nommé au joueur. Sauvegarde corrompue traitée comme échec total sans récupération partielle. Sauvegarde effacée à la mort du héros. Suppression du stub mort `RunPersistenceManager`. Voir ADR-069. |
| **v3.1.0** | 2026-07-01 | Forge de Fusion et Forge Data-Driven | Introduction du nœud Forge de Fusion (`MapNodeType.forgeFusion` à 25% de chance) sur les étages 3 à 7. Écran `ForgeFusionScreen` pour fusionner les runes identiques pour un coût de 80 Or. Remplacement des upgrades codés en dur par une structure data-driven (`assets/data/forge_upgrades.json` + `ForgeUpgradeData`). Cumul de runes sans épuisement (alreadyHas retiré). Correction de la navigation au repos : annuler la forge ramène à la sélection de cartes au lieu de quitter au menu du repos. Écriture de tests unitaires (112 tests réussis, 0 erreur). |
| **v0.3.0** | 2026-06-25 | Refonte et Validation du Système d'Événements | Enrichissement visuel et narratif du système de rencontres avec 5 événements bilingues configurés dans `assets/data/events.json`. Conception d'un Safety Gate de validation d'éligibilité (`isSelectable`) bloquant les options en cas d'or insuffisant, de dégâts létaux (`currentHp <= damage`), ou de réduction de PV Max létale. Rendu visuel d'en-tête (PV et Or réactifs) et intégration de badges compacts directement dans les boutons de choix d'options avec transition d'échelle animée après résolution. |

Les releases sorties de ce tableau par débordement du plafond FIFO sont conservées
verbatim sous `.obsidian_vault/_archive/` (`2026-08-23-progress-releases.md` pour la
dernière rotation, `2026-08-20-progress-releases.md` pour la précédente).

> [!NOTE]
> **Le schéma `v3.x` est gelé.** L'historique ci-dessus emploie un schéma interne
> (`v3.x`) distinct de la version joueur de `assets/data/patch_notes.json` (`0.4.x`).
> Depuis le 2026-08-03, la version de référence est celle de `assets/data/patch_notes.json`,
> maintenue conjointement avec `pubspec.yaml` par le skill `patch-notes-writer`.
> **Aucune nouvelle entrée n'emploie le schéma `v3.x`** : les lignes existantes sont
> conservées telles quelles pour leur valeur historique, et toute ligne ajoutée à ce
> tableau est clé sur la version publiée dans `assets/data/patch_notes.json`.
