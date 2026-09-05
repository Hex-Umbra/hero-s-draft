# 📊 État du Projet & Progrès

> [!IMPORTANT]
> **Plafond : 300 lignes.** Ce fichier décrit **ce qui est construit**, jamais ce qui reste à faire — voir `docs/ROADMAP.md`.

## Métriques

**Vérifié le 2026-09-05**

| Métrique | Valeur | Commande |
|:---|:---|:---|
| Tests automatisés (jeu) | 427 au vert | `flutter test` |
| Fichiers de test | 81 | `find test -name "*.dart" \| wc -l` |
| Analyse statique | 0 erreur (`No issues found!`) | `dart analyze` |
| Fichiers Dart (`lib/`) | 185 | `find lib -name "*.dart" \| wc -l` |
| Lignes de code (`lib/`) | 39 280 | `find lib -name "*.dart" -exec cat {} + \| wc -l` |
| Fichiers de données | 73 | `find assets/data -name '*.json' \| wc -l` |
| Tests de la logique du site | 20 au vert | `cd site && node --test` |
| Assertions du harnais CI | 57 au vert | `bash .github/scripts/test_scripts.sh` |
| Fichiers suivis sous `site/` | 16 | `git ls-files site/ \| wc -l` |

> [!NOTE]
> Relevé sur `ac37596`. Deux chantiers expliquent tout le mouvement depuis le 2026-09-01.
>
> **P-48 (réorganisation des données)** : les 73 fichiers de données sont **71 entités**
> — `cards/` 17, `relics/` 25, `forge_upgrades/` 8, `events/` 5, `passives/` 3, 3 classes
> (`class.json` + 2 cartes chacune), 4 ennemis — plus `audio.json` et `patch_notes.json`, qui
> restent des documents de configuration. La comparaison au 11 précédent est directe : avant,
> `assets/data/` n'avait aucun sous-répertoire.
>
> **P-40 bloc 1** : −3 fichiers Dart avec la chaîne de compétences, +1 pour
> `game_data_loader.dart`, d'où 187 → **185** pour +24 lignes nettes.
>
> **+42 tests** (385 → 427) : −8 partis avec le système de compétences, +50 pour la
> réorganisation, dont les gardes permanentes de la structure. `site/`, `.github/` et
> le harnais CI n'ont pas bougé.

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
| Réhydratation des contrôleurs | `RunController.hydrate()`, `DeckNotifier`, `InventoryController` | Remplacement intégral de l'état depuis les données chargées, navigation directe vers `MapScreen` |
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
| Économie, événements, boutique, récompenses | `InventoryController`, `EventController`, `ShopController`, `RewardController` | Or/reliques à charges, résolution d'événements, achat/clone/reroll boutique, tirage post-victoire |
| Logique de Fusion | `DeckNotifier`, `InventoryController` | Fusion d'améliorations identiques, déduction d'or, mise à jour de la carte via `setForgeUpgrades` |

### 🃏 Cartes et Deck

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Auto-Merge (3→1) | `DeckNotifier.mergeCards()` | 3 copies même ID + rareté → 1 copie rareté supérieure ; cartes `unique` non fusionnables |
| Foil Unique Progressif | `PolychromaticBorder`, `UiCard` | Bordure polychromatique au survol, nombre de couleurs croissant avec les upgrades |
| Rareté Dynamique | `EffectResolver.resolveCard()` | Progression par rareté (common → legendary), rareté `unique` fixée à ×1.0 |
| Catalogue de cartes | `assets/data/cards/`, `assets/data/classes/<id>/cards/` | 23 cartes, un fichier par carte : 17 globales (communes) + 6 de classe (unique) |
| Effets et exhaust | `EffectResolver`, `CardEffect`, `DeckNotifier.playCard()` | damage/heal/armor/draw/gain_mana/apply_status ; Power et `isExhaust` → pile d'épuisement |
| Moteur de pioche | `DeckNotifier._drawInto`, `.drawCards`, `.startCombat`, `deckRandomProvider` | Remélange à sec (défausse → pioche uniquement si pioche vide), arrêt net à `GameConstants.maxHandSize` (10), aléatoire injectable pour les tests de séquence, `DeckState.reshuffleCount` observable |
| Règle de tour joueur | `TurnPhaseManager.startPlayerCombat()`/`.startPlayerTurn()` | Moitié joueur du cycle, symétrique de `startEnemyTurn`/`endEnemyTurn` ; tour 1 et tour N+1 sur le même chemin ; nombre de cartes piochées piloté par `RunState.cardsPerTurn` (défaut 5) |
| Forge et Fusion | `DeckNotifier.addForgeUpgrade()`, `ForgeUpgradeDialog`, `ForgeFusionScreen` | Upgrades pilotées par `assets/data/forge_upgrades/`, un fichier par amélioration, cumulables sans limite |
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
| Passifs data-driven | `assets/data/passives/` → `TraitSystem` | 3 passifs liés aux héros par `HeroData.passiveTrait` ; ids en `snake_case` |
| Triggers multiples | `TraitSystem.onTurnStart`/`.onTurnEnd`/`.onCardPlayed` | Logique spécifique par `effectType` (`gain_armor`, `berserker_armor`, `spell_armor`) |
| Reliques à triggers | `RunController.applyRelics(trigger)` | 9 types de triggers (startOfRun → onEnemyKilled) |
| Reliques à charges | `RunController.applyRelicEffect()` | Croc Kunaï, Shuriken, Plume de Scribe, Encensoir — compteurs visuels via `StatusEffect` |

### 🈳 Internationalisation (i18n)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| UI 100% localisée | `AppLocalizations` (ARB) | Zéro chaîne codée en dur |
| Modèles bilingues | `nameEn`/`nameFr` | **Sans exception** depuis la suppression de `SkillData` — [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md) |
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

### 🔊 Système Audio

| Fonctionnalité | Fichiers clés | Détails |
|:---|:---|:---|
| Directeur central | `AudioDirector.onMoment()`, `MusicConductor.onScene()` (`lib/services/audio/`) | Point d'entrée unique ; le code de jeu déclare un moment ou une scène, jamais un fichier |
| Mapping par données | `assets/data/audio.json`, `AudioData`/`SoundData`/`MomentSounds` | Chaîne de repli à 4 niveaux (son propre → type d'animation → défaut → silence) ; champ `sfx` optionnel sur `CardData`/`EnemyData`/`RelicData` |
| 22 moments de jeu | `GameMoment` | Branchés dans 13 fichiers ; `triggerHitReactions()` couvre à lui seul les 5 moments d'impact, héros et ennemis. Catalogue : [`_rules/09-1`](../_rules/09-1-catalogue-des-moments.md) |
| Lecture sans allocation | `SfxPool` / `AudioPool` (`flame_audio_backend.dart`) | Un réservoir de lecteurs pré-armés par fichier, monté au préchargement ; `playOnce` ne fait plus que réserver et relancer |
| Deux préchargements distincts | `AudioBackend.preload` / `.preloadMusic` | Réservoir pour les bruitages, octets seuls pour la musique — les deux chemins n'ont plus rien de commun |
| Rendu des coups sur la frappe | `CardAnimator.playAnimation(onImpact:)`, `HeroCard._pendingStats` | Nombres flottants et bruitages tombent quand la carte atteint sa cible, plus à la fin de l'animation |
| Backend silencieux par défaut | `SilentAudioBackend` (défaut), `FlameAudioBackend` (`main.dart` seul à le surcharger) | Les 295 tests antérieurs au chantier n'ont subi aucune modification |
| Musique par scène | `MusicConductor`, `MusicScene` (menu/map/combat/boss) | `onScene` idempotent, déverrouillage autoplay web au premier geste pointeur ; garde de disponibilité à cache négatif — une piste absente est silencieuse, pas bruyante |
| Réglages persistés | `AudioSettingsNotifier`, `SettingsService` | Clé `shared_preferences` dédiée, indépendante de `SaveService` ; écran `SettingsScreen` + coupure au HUD de combat |
| Bruitages complets, musique absente | `test/unit/audio/audio_sourcing_report_test.dart` | 31 bruitages WAV sur 31 ; les 4 musiques MP3 manquent — rapport non bloquant, ne rougit jamais la CI ; état courant : `docs/ROADMAP.md` (P-46) |

Design complet — [ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md),
remplace [ADR-012](../_adr/ADR-012-absence-de-systeme-audio.md). Latence, disponibilité et
synchronisation — [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md).
Chaîne de repli — [`_rules/09-00`](../_rules/09-00-systeme-audio.md), catalogue des moments —
[`_rules/09-1`](../_rules/09-1-catalogue-des-moments.md). Architecture —
[`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md).

### 🗂️ Architecture des Données (un fichier par entité)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Une entité, un fichier | `assets/data/` | 71 entités dans 7 catalogues répertoriés ; le nom du fichier **est** l'`id` ; `audio.json` et `patch_notes.json` restent des documents de configuration |
| Dossiers auto-suffisants | `classes/<id>/`, `enemies/<id>/` | JSON + image dans le même dossier ; ajouter un ennemi = créer un dossier |
| Chargeur générique par motifs de chemin | `GameDataLoader`, `EntitySource` (`lib/services/game_data_loader.dart`) | Le répertoire injecte l'appartenance ; les fautes s'accumulent et lèvent une fois ; `bundle` en paramètre comme seam de test |
| Section `assets:` générée depuis le disque | `tool/sync_assets.dart` | `--check` sort 1 sur dérive ; refuse de deviner sur un pubspec ambigu |
| Gardes permanentes de la structure | `real_bundle_load`, `referential_integrity`, `entity_id_convention`, `flame_image_prefix`, `sync_assets` (`test/unit/`) | Ligne de pubspec oubliée, dossier incomplet, id hors convention, collision de clés du cache d'images |

Règle de partage catalogue / configuration — [ADR-085](../_adr/ADR-085-regle-de-partage-catalogue-configuration.md).
Autorité du répertoire — [ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).
Structure — [`_rules/07-00`](../_rules/07-00-architecture-des-donnees.md), mécanique —
[`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).
**Coût de démarrage mesuré le 2026-09-05** : 72 lectures de bundle en **53 ms** en profile,
seuil d'alerte à 200 ms.

## 2. Dette métier assumée

### ⚠️ Sérialisation Partielle des Modèles

**Re-vérifié fichier par fichier le 2026-08-04** — `grep -c "operator ==" <fichier>` et
`grep -n "fromJson\|toJson" <fichier>` sur chacun des 13 modèles. Les colonnes
`CardInstance` et `ShopState` étaient fausses avant cette date (leurs `fromJson`/`toJson`
existent depuis le commit `3b2365c` du 2026-06-24). Seul `EventState` est réellement
dépourvu de sérialisation.

**2026-09-05** — le tableau ne compte plus que **12 modèles** : `SkillState` a été supprimé
avec son système ([ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md)).
Les 12 lignes restantes n'ont pas été re-vérifiées à cette date.

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
| **0.5.0** | 2026-09-01 | Le Jeu Sort du Silence (P-03, sourcing et chemin de lecture) | Première version **audible** : le moteur livré en `0.4.9` restait muet faute d'assets ; les **31 bruitages** sont désormais posés et chacun des 14 `GameMoment` a son son. Les fichiers sont arrivés en WAV alors qu'`audio.json` déclarait des `.mp3` — le rapport de sourcing restait à 0/23 sans rien signaler d'autre, ne vérifiant que la présence. **Arbitrage : WAV pour les bruitages, MP3 pour la musique**, amendement de [`_rules/09-00`](../_rules/09-00-systeme-audio.md) §9.3 ; [ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md) ne fixait pas le format mais le déléguait à la fiche, elle n'est donc pas touchée. Motif : un bruitage pèse ~13 Ko, rien à compresser, et l'encodage MP3 préfixe 13 à 26 ms de silence audibles sur un `card_hover` de 84 ms rejoué à chaque survol ; une musique dure des minutes, c'est là que la compression sert. **Zéro fichier `.dart` modifié** sur toute la bascule : aucune ligne de `lib/` ne nomme d'extension, `SoundData.expectedFiles` insérant le suffixe de variante avant l'extension quelle qu'elle soit. Piège documenté au passage : un jeu de variantes incomplet **rend muet au prorata au lieu de se replier**, `_pickFile` tirant au hasard avant le garde de présence d'`onMoment` — `impact_normal` en `variants: 3` avec le seul `_1` posé laissait deux impacts sur trois silencieux. Les 19 empreintes MD5 sont distinctes, contrôle que le rapport de sourcing ne fait pas. **Trois livraisons rejoignent ce numéro**, l'attente ayant été délibérée (ADR-082 D5) : P-03, la PR #31 (deux débordements de `RenderFlex` — `StatusEffectsPanel` et `tutorial_combat_overview_widget.dart`) et la PR #32 (documentation seule, sans effet joueur). **369 tests au vert**, `dart analyze` propre. Les 4 musiques sortent vers le chantier **P-46**. **Note rouverte le 2026-09-01** pour absorber les sept commits du chemin de lecture ([ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)) : la version n'avait jamais été taguée, donc aucun joueur n'avait vu la note initiale. |
| **0.4.9** | 2026-08-23 | L'École du Héros (P-45) | Le tutoriel autonome (`lib/tutorial/`) avait dérivé du jeu réel : 50 écarts relevés, nés d'une règle « zéro Riverpod » qui interdisait aussi l'accès aux données immuables, forçant une recopie manuelle qui a dérivé avec le temps. La règle devient « zéro provider d'*état* » : `gameDataLoaderProvider` est autorisé en un point unique (`tutorial_loader.dart`), les neuf providers d'état restent interdits, critère vérifié par `test/tutorial/tutorial_isolation_test.dart`. Les POJOs du mock (`TutorialCard`, `TutorialEnemy`) sont remplacés par les vrais modèles du jeu (`CardInstance`, `EnemyInstance`, `EntityStats`, `DamagePipeline`). Le parcours passe de 13 à **15 étapes** : choix de classe et draft du deck de départ ajoutés en amont, verrouillés une fois franchis, dont dépendent les étapes suivantes (Armure démontre le passif choisi, Jouer pioche dans ce deck, Fusion y prend une carte réellement draftée). Correctif d'affichage hors tutoriel : la légende de la carte du monde annonçait « Boss (XP & Or x2) » alors que `reward_controller.dart` applique `×3` depuis longtemps — seul l'affichage change, le code de récompense est intact. **45 commits hors merges** depuis `v0.4.8`, **295 tests au vert** (+65), `dart analyze` propre. Voir [ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md). ⚠️ **Deux correctifs de jeu sont entrés dans ce même tag par la PR #28 et ne figurent pas dans la note joueur**, rédigée avant leur fusion. *(1)* `EnemyIntentsPanel` débordait de sa largeur fixe de 250 px dès que le libellé d'intention était long : la bande d'erreur jaune et noire s'affichait en plein HUD de combat, à chaque combat en français, depuis au moins `0.4.8`. Les deux `Row` se replient désormais au lieu de tronquer — la valeur chiffrée est en fin de libellé (« Attaque Dévastatrice : 25 »), une ellipse l'aurait fait disparaître. *(2)* La **Forge d'Acier légendaire** rendait +1 Maîtrise d'Armure, la valeur d'un commun, faute de palier légendaire dans sa cascade de `if` : elle rend désormais **+7**. Les 30 cases type × rareté sont verrouillées par `test/unit/level_up_reward_values_test.dart` et la table est écrite dans [`_rules/06-00`](../_rules/06-00-economie-de-jeu.md) — son absence était la raison pour laquelle rien n'avait signalé le trou. |
| **0.4.8** | 2026-08-20 | La Salle des Archives (P-04) | Chantier **P-04** livré en deux lots, sans que le jeu change : **aucun fichier de `lib/`, `test/` ou `assets/` n'est touché**, et le patch note joueur ne décrit donc que le site. **Lot 1 — chaîne CI/CD** : trois workflows (`ci.yml`, `release.yml` à neuf jobs, `site.yml`), publication réduite à la pose d'un tag `v*.*.*`, garde-fou `verify-version` comparant le tag à `pubspec.yaml`, `patch_notes.json` et `versions.json` **avant tout build**, smoke test HTTP post-déploiement, pré-release GitHub avec le zip Windows, annonce Discord en `continue-on-error`. Toute la logique vit dans cinq scripts shell testables — harnais à **55 assertions**, attentes dérivées à l'exécution par `jq` plutôt que figées. Actions tierces épinglées sur SHA, secrets par `env:` uniquement, accès VPS confiné en écriture seule par `rrsync -wo`. Voir [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md). **Lot 2 — site vitrine** : la page de sélection des versions, jusque-là hors du dépôt et maintenue à la main, devient `site/` — trois pages sans étape de build ni dépendance npm, pilotées par `site/_site/versions.json`, logique pure testée par `node --test` (**20 tests**). La jointure version → patch note passe par un champ `notes` déclaré et nullable, jamais dérivé du nom de dossier : les quatorze dossiers historiques rapportent tous `0.1.0`, et une dérivation aurait produit quatre associations fausses. Voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md). Enrichissement du 20/08 : les quatorze dates relevées sur l'archive locale des builds, et deux jointures déclarées (`v0.0.5` → note `0.0.4`, `v0.0.9` → note `0.0.93`). |
| **0.4.7** | 2026-08-06 | Assainissement du Système de Pioche (P-02) | Le remélange défausse → pioche devient **automatique et à sec** : il n'intervient plus qu'une fois la pioche réellement vide, y compris au milieu d'une pioche. L'ancien seuil `if (drawPile.length < 5)` porté par `game_screen.dart` déclenchait un remélange presque chaque tour et détruisait la capacité à compter son deck ; `shuffleDiscardIntoDraw()` est supprimée. La pioche s'arrête **net** à `GameConstants.maxHandSize` (10) sans consommer de carte ni remélanger. `RunState.cardsPerTurn` (défaut 5) remplace le `5` codé en dur, et `TurnPhaseManager` gagne `startPlayerCombat()`/`startPlayerTurn()` : le tour 1 et le tour N+1 empruntent enfin le même code, et `game_screen.dart` n'anime plus que (perte de `_turnCount` et du deck de secours, 555 → 524 lignes). Aléatoire injectable via `deckRandomProvider`, compteur `DeckState.reshuffleCount` observable et notification joueur. Première relique touchant au deck : `scholars_satchel` (Besace de l'Érudit, legendary, +1 carte/tour), avec `case` symétrique dans `removeRelicEffect`. 6 éléments de code mort supprimés (`temporaryCost`, `IntentType.debuffDeck`, `intentCurse`, `onEnemyDebuffDeck`, `onTurnEnded`, deck de secours). 8 commits TDD, **230/230 tests au vert** (+18 neufs, 2 réécrits), `dart analyze` propre, **playtest de validation passé le 2026-08-06**. Voir [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md). |
| **v3.5.1** | 2026-07-26 | Correction de la Réactivité du Bouton « Continuer » (HomeScreen) | `HomeScreen._continueGame()`/`_startNewGame()` naviguent via `Navigator.push`, mais le menu pause et `GameOverScreen` reviennent à l'accueil via `Navigator.popUntil((route) => route.isFirst)`, qui ne reconstruit pas `HomeScreen` ni ne réévalue `SaveService.hasSave()` : le bouton « Continuer » pouvait rester dans un état obsolète jusqu'au redémarrage de l'application. Correctif : les deux méthodes attendent désormais (`await`) leur `Navigator.push` et appellent `setState(() {})` à son retour. Nouveau test `test/widget/home_screen_save_test.dart` (95 lignes). Commit `17564b4`, mergé avec ADR-072 via PR #22. Voir ADR-073. |
| **v3.5.0** | 2026-07-26 | Accélération de la Cadence du Scaling de Difficulté | Resserrement de la cadence du système introduit par ADR-070/071 suite à un retour de playtest (le joueur montait en puissance plus vite que les ennemis) : le palier géométrique HP/Dégâts (`_actBracketSize`) passe de 5 à 2 actes (bases x1.35 HP / x1.25 Dégâts et rampe intra-palier inchangées) et le déblocage de tier (`_tierUnlockBracketSize`) de 10 à 5 actes (tier 2 dès l'Acte 6, tier 3 dès l'Acte 11). Aucune autre formule modifiée (budget, plafond d'ennemis ADR-071, puissance du joueur). Effet secondaire assumé : fenêtre de contenu tier-1-only resserrée des Actes 1-10 aux Actes 1-5. 2 commits TDD (`97c5fcb`, `8bc1920`), suite de tests complète 211/211 au vert, `dart analyze` propre. Voir ADR-072. *(Branche `fix/combat_scaling` mergée vers `main` via PR #22 ; patch note joueur v0.4.6 rédigé — voir `assets/data/patch_notes.json`.)* |
| **v3.4.0** | 2026-07-25 | Plafonnement du Nombre d'Ennemis par Acte & Résolution de la Dérive Log/Calcul | Suite directe d'ADR-070 sur la même branche `feature/combat_scaling` (mergée avec PR #21) : plafond du nombre d'ennemis générés par combat, croissant avec l'Acte et différencié combat normal/élite/boss (+1/acte, +1/2 actes, +1/5 actes respectivement, sans plafond ultime), remplaçant l'ancienne limite fixe de 10 — empêche l'empilement de plusieurs ennemis tier-1 faibles pour épuiser un budget élite/boss. Corrige aussi la dérive confirmée entre le log de debug (`math_combat.md`) et le calcul réel de budget (`playerCardsCount`, `+(act-1)*10` manquants dans le log) via un unique `EncounterSystem.calculateBudget()`. Voir ADR-071. *(Patch note joueur rédigé — v0.4.7 "L'Équilibre des Effectifs", voir `assets/data/patch_notes.json`.)* |
| **v3.3.0** | 2026-07-24 | Scaling de Difficulté en Escalier Géométrique & Déblocage de Tier | Correction d'un double comptage de l'Acte dans `EncounterSystem` (`enemyLevel` + terme linéaire direct dans `getHpMultiplier`/`getDamageMultiplier`) qui provoquait une explosion de difficulté incontrôlée en mode endless. `enemyLevel` devient strictement indépendant de l'Acte ; l'Acte agit désormais via un facteur géométrique par palier de 5 actes (`getHpActFactor`/`getDamageActFactor`, x1.35 HP / x1.25 Dégâts par palier + rampe intra-palier douce réinitialisée). Ajout d'un déblocage de tier d'ennemi tous les 10 actes (`getUnlockedTier`, plafond tier 3), gating strict assumé (Squelette/tier 2 non disponible avant l'Acte 11, contre l'Acte 2 auparavant) créant un backlog de contenu tier-1. 6 commits TDD, 201/201 tests au vert, `dart analyze` propre, revue de code de branche complète. Voir ADR-070. Mergé vers `main` (PR #20). |
| **v3.2.0** | 2026-07-24 | Système de Sauvegarde et Persistance de Run (Autosave) | Résolution du point bloquant de commercialisation ADR-011 : `SaveService` (`shared_preferences`, slot unique, JSON versionné) sauvegardant `RunState`/`DeckState`/`InventoryState`/`SkillState` à chaque checkpoint carte (`checkpointProvider`/`autosaveOrchestratorProvider`), jamais en cours de combat. Bouton "Continuer" et dialogue de confirmation sur `HomeScreen`. Dégradation gracieuse du contenu manquant (cartes/reliques/upgrades/passifs supprimés du catalogue) avec avertissement nommé au joueur. Sauvegarde corrompue traitée comme échec total sans récupération partielle. Sauvegarde effacée à la mort du héros. Suppression du stub mort `RunPersistenceManager`. Voir ADR-069. |
| **v3.1.0** | 2026-07-01 | Forge de Fusion et Forge Data-Driven | Introduction du nœud Forge de Fusion (`MapNodeType.forgeFusion` à 25% de chance) sur les étages 3 à 7. Écran `ForgeFusionScreen` pour fusionner les runes identiques pour un coût de 80 Or. Remplacement des upgrades codés en dur par une structure data-driven (`assets/data/forge_upgrades.json` + `ForgeUpgradeData`). Cumul de runes sans épuisement (alreadyHas retiré). Correction de la navigation au repos : annuler la forge ramène à la sélection de cartes au lieu de quitter au menu du repos. Écriture de tests unitaires (112 tests réussis, 0 erreur). |

Les releases sorties de ce tableau par débordement du plafond FIFO sont conservées
verbatim sous `.obsidian_vault/_archive/` (`2026-08-28-progress-releases.md` pour la
dernière rotation, `2026-08-23-progress-releases.md` pour la précédente).

> [!NOTE]
> **Le schéma `v3.x` est gelé.** L'historique ci-dessus emploie un schéma interne
> (`v3.x`) distinct de la version joueur de `assets/data/patch_notes.json` (`0.4.x`).
> Depuis le 2026-08-03, la version de référence est celle de `assets/data/patch_notes.json`,
> maintenue conjointement avec `pubspec.yaml` par le skill `patch-notes-writer`.
> **Aucune nouvelle entrée n'emploie le schéma `v3.x`** : les lignes existantes sont
> conservées telles quelles pour leur valeur historique, et toute ligne ajoutée à ce
> tableau est clé sur la version publiée dans `assets/data/patch_notes.json`.
