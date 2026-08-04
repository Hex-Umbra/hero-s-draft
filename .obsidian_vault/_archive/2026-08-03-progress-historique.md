# Archive — progress.md, sections historiques (2026-08-03)

Sections retirées de `progress.md` lors de la refonte documentaire du 3 août 2026. Conservées verbatim pour la traçabilité. **Ne pas éditer.**

Le backlog et les chantiers priorisés vivent désormais dans `docs/ROADMAP.md`.

---

## Historique des Releases (entrées antérieures aux 10 conservées dans `progress.md`)

Extrait verbatim de l'ancien §7 « Historique des Releases » de `progress.md` — toutes les entrées sauf les 10 plus récentes (conservées dans le fichier actif).

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v0.2.6** | 2026-06-16 | Double Confirmation de Fin de Tour | Ajout d'une double confirmation sur le bouton de fin de tour en cas de mana restant. Affiche un avertissement localized et réclame un deuxième clic pour valider. Se réinitialise automatiquement au début de chaque tour ou dès qu'une carte est jouée. |
| **v0.2.5** | 2026-06-16 | Correction Bouton Fin De Tour | Résolution du problème d'inactivité du bouton de fin de tour après avoir joué une carte en synchronisant explicitement la phase du tour dans la méthode de démarrage du tour joueur. |
| **v0.2.4** | 2026-06-14 | Harmonisation de l'Architecture | Harmonisation Post-Refactoring de l'Architecture : Migration de `ClassSelectionScreen` sous `ScreenScaffold` et `PageHeader` ; remontée de la logique d'`updateStats` et des réactions d'impacts visuels dans `CombatEntity` (Flame), nettoyant `HeroCard` et `EnemyCard` ; riverpodisation d'`EffectRegistry` via le provider `effectRegistryProvider` (sans mutable statique global) et passage à `EffectResolver.resolveCard` ; nettoyage de callbacks obsolètes de `HerosDraftGame` ; et ajout du champ `floor` explicite dans `MapNode` pour supprimer le parsing d'ID de chaîne. |
| **v0.2.3** | 2026-06-14 | Architecture & Patterns | Refactoring Phase 4 : Découpage procédural de `MapGeneratorService` en 4 sous-services (`MapNodeGenerator`, `MapConnectionBuilder`, `MapValidator`, `MapContentPlacer`) ; refactorisation d'`EffectResolver` avec le Strategy Pattern (`EffectStrategy` et `EffectRegistry`) ; abstractions Flame `CombatEntity` (pour unifier `HeroCard`/`EnemyCard`) et `BaseVisualEffect` (pour unifier `SlashEffect`/`ShieldDome`) ; centralisation de la thématique via `GameThemeExtension` et try/catch détaillés de diagnostic dans `GameDataService`. Zéro erreur et 108 tests unitaires au vert. |
| **v0.2.2** | 2026-06-14 | Unification de l'UI & Composants Communs | Refactoring Phase 3 : Centralisation des arrière-plans, SafeArea et PopScope dans `ScreenScaffold` ; standardisation des en-têtes avec `PageHeader` et de l'affichage de l'or avec `GoldIndicator` ; factories `UiCard.fromInstance` et `UiCard.fromData` ; découpage modulaire de la forge (`ForgeCardPreview`, `ForgeSlotRow`, `ForgeBuySlotButton`) ; et structure de mise en page commune `CardDraftLayout`. Zéro régression et 108 tests unitaires au vert. |
| **v0.2.10** | 2026-06-13 | Décomposition des God Classes | Refactoring Phase 2 : Décomposition de `RunController` (en 4 managers spécialisés), `CombatController` (en 2 processeurs spécialisés), `HerosDraftGame` (en 4 sous-systèmes Flame : `StateSync`, `CardAnimation`, `CombatVisual`, `Layout`), et `CardComponent` (délégation à `CardRenderer` pour le dessin Canvas et `CardInteractionHandler` pour les gestes). Préservation des signatures d'API et 108 tests unitaires 100% au vert. |
| **v0.1.9** | 2026-06-13 | Refactoring & Centralisation | Centralisation de tous les délais de combat et des paramètres de FloatingText dans `GameConstants` pour supprimer les nombres magiques ; sécurisation du flux d'état via `@immutable` et `List.unmodifiable` sur les modèles clés (`EntityStats`, `CombatState`, `EnemyInstance`) ; et unification des calculs de dégâts via le service centralisé `DamagePipeline.calculate`. |
| **v0.1.8** | 2026-06-13 | Transition Fluide de Tour | Réinitialisation de l'armure du joueur à 0 au début de son tour (dans `RunController`) pour éviter le cumul infini inter-tours de l'armure. Ajout d'un drapeau transitoire `suppressArmorChangeAnimation` dans `HeroCard` activé lors de la transition de tour par `game_screen.dart` pour masquer les popups négatifs d'armure ("-X") et l'animation d'impact de bouclier, évitant un faux feedback visuel de dégâts reçus. |
| **v0.1.7** | 2026-06-13 | L'Éclat des Combats | Embellissement des textes flottants thématiques avec ombres néon et symboles descriptifs, rotation de naissance, et cinématique d'échelle élastique suivie d'une pulsation infinie sur critique. Déclenchement visuel des critiques basé sur la propagation de l'état `lastActionWasCrit` calculé en phase métier (déterministe). Renforcement des impacts (tremblement accru, flash doré, 35 particules). Décélération de la jauge HP de catch-up (1200ms easeOut sous dégâts) pour mieux ressentir la violence des coups. **Incorpore également** : le fix de la relique Croc Kunaï (combat-long `'armor_mastery'` StatusEffect avec getter dynamique `effectiveArmorMastery`), l'animation dynamique des particules Canvas du carrousel de reliques (via `AnimationController` Flutter avec gravité, friction et fade), l'exclusion des cartes de rareté unique dans les récompenses de cartes post-boss (x=0), l'amélioration visuelle du clonage Magic Mirror en boutique (affichage de l'interface `UiCard` complète avec runes de forge, rareté, effets de survol réactifs et boîte de dialogue responsive élargie à `maxWidth: 550` avec scroll horizontal), la protection anti-exploit de caching de `cloneOptions` pour le Magic Mirror, et le verrouillage dynamique (désactivation) des boutons de services de la boutique en cas de solde d'or insuffisant. |
| **v0.2.04** | 2026-06-12 | Enrichissement des Tooltips de Cartes | Ajout de tous les détails (type de cible écrit explicitement, rareté, type de carte, coût mana) dans les tooltips en combat (Flame CardComponent) et menus (Flutter UiCard) en français et anglais. |
| **v0.2.03** | 2026-06-12 | Polissage Dimensionnel des Cartes en Menu | Agrandissement des fentes de runes à 10px (visibilité des emojis d'upgrades) et agrandissement du médaillon de coût mana à 30px (ajustement offset [-9, -9]) uniquement sur les menus (Flutter). |
| **v0.2.02** | 2026-06-12 | Bordure Foil Progressif Unique | Rendu de la bordure polychromatique brillante au survol de la souris dont le nombre de couleurs (de 1 à 10) augmente avec le nombre d'upgrades (upgradeCount) de la carte Unique. |
| **v0.2.01** | 2026-06-12 | Décomposition de UiCard (SRP) | Refactoring de la god class `UiCard` (1136 lignes) en extrayant ses sous-widgets (`CardManaMedallion`, `CardRuneSockets`, `CardCompactDescription`) et ses helpers (`ui_card_helpers.dart`) dans un sous-dossier `ui_card/` dédié, garantissant la cohésion, respectant le principe de responsabilité unique (SRP) et la structure du framework Flutter. |
| **v0.1.6** | 2026-06-12 | Ajustements du Gel et de la Forge | Résolution du bug d'armure de forge (hardened) sur les cartes d'attaque (application directe au héros), persistance du statut de gel (freeze) en début de tour ennemi et affichage de la réduction de 50% de dégâts directement dans l'intention de combat. |
| **v0.1.5** | 2026-06-12 | Refonte Esthétique des Cartes | Layout glassmorphic unifié, médaillon standardisé de coût, fentes d'améliorations (rune sockets) avec retour à la ligne automatique par rangées de 5 (rows of 5) pour éviter tout débordement, réduction d'échelle de 25%, suppression du filigrane et des badges textuels de ciblage (remplacés par des doublements d'icônes d'effet pour la portée multicible ciblant les ennemis), retrait complet des labels textuels de rareté (remplacés par l'identification pure via la couleur des bordures et par halo de surbrillance lumineux/glowing shadows en cas de sélection), et mise à jour des cartes de combat (Flame) pour utiliser des couleurs d'arrière-plan spécifiques à leur type (type-specific background colors) identiques à celles des menus. |
| **v0.2.00** | 2026-06-11 | Forge v2 : Anti-Exploit, Filtrage Typé, Achat Progressif | Écran forge responsive plein écran, persistance session anti-exploit, fentes d'upgrades progressives, filtrage typé. |
| **v0.1.4** | 2026-06-11 | Map, Draft & Progression | Level Up différé sur la carte (MapScreen), protection anti-spoil du carrousel de reliques, chokepoint élite central calculé dynamiquement. |
| **v0.1.3** | 2026-06-11 | Harmonie Visuelle & Améliorations de Boutique | Exclusion des cartes uniques de la boutique, arrière-plans colorés par type de carte dans UiCard, grille Wrap/SizedBox pour la boutique. |
| **v0.1.00** | 2026-06-10 | Clarté Visuelle & Fluidité de Combat | Input blocking pendant la pioche, tooltips focus-only, étoiles d'upgrades, jauge HP dual-bar animée. |
| **v0.0.99** | 2026-06-07 | Fondations du Design | Uniformisation typographique, corrections d'overflows, palette de couleurs centralisée. |
| **v0.0.98** | 2026-06-07 | Fluidité & Impacts | Animations de pioche organiques, synchro précise des impacts en combat, corrections d'animation. |
| **v0.0.97** | 2026-06-07 | Modernisation Technique | Migration Notifier/NotifierProvider, découplage des contrôleurs, immuabilité de CardInstance. |
| **v0.0.95** | 2026-06-05 | L'Éveil des Reliques | 10 nouvelles reliques, triggers par type de carte, charges persistantes, autel d'échange de reliques. |
| **v0.0.94** | 2026-06-04 | Or et Butin des Boss | Or post-combat, récompenses de boss fixes selon position, écran de draft de boss. |
| **v0.0.93** | 2026-06-04 | La Grande Refonte | Chemins de run multiples divergés, quotas équilibrés, anti-répétition de chemins. |
| **v0.0.4** | 2026-05-15 | Système de Fusion & Équilibrage | Fusion de cartes v1, progression classes, reliques légendaires, événements. |
| **v0.0.3** | 2026-04-20 | Carte & Exploration | Carte procédurale simple, boutique v1, repos, dictionnaire. |
| **v0.0.2** | 2026-03-10 | Combat & Deck | MVP combat, pioche, main, défausse, altérations élémentaires de base. |
| **v0.0.1** | 2026-02-01 | MVP Initial | Lancement avec 3 classes de base, cartes de base attaque et défense. |

---

## 4. Chantiers de Refactoring Prioritaires (Roadmap Dette Technique)

Basé sur les rapports de dette technique (`technical_debt_report_Opus4.6.md`, 4 rapports Gemini 3.5) et les 4 plans d'implémentation de refactoring.

### 🔴 Phase 1 — Fondations (Semaines 1-2)

| Priorité | Chantier | Problème | Solution | Fichiers |
|:---|:---|:---|:---|:---|
| Critique | Typage des modèles | `==`/`hashCode` absents sur 12 modèles, `Map<String, dynamic>` non typés | Ajouter `freezed` ou implémenter manuellement | `lib/models/` (11 fichiers) |
| Critique | Immuabilité réelle des listes | Listes mutables dans états "immuables" | ✅ List.unmodifiable() et @immutable dans `EntityStats`, `CombatState` et `EnemyInstance` (v0.1.9) | `lib/models/` |
| Critique | Validation des entrées | `gainGold(-50)` fonctionne, HP peut dépasser maxHP | Ajouter validation dans chaque mutation | `run_controller.dart`, `inventory_controller.dart` |
| Important | Centralisation des dégâts | Calculs de dégâts physiques et magiques dispersés (`EffectResolver`, `CombatController`) | ✅ Unifié via le service `DamagePipeline` centralisé (v0.1.9) | `lib/game/services/damage_pipeline.dart` |
| Important | Error handling I/O | Aucun `try-catch` dans `GameDataService` | ✅ Sécurisé avec des try/catch détaillés de diagnostic (v0.2.3) | `lib/services/game_data_service.dart` |
| Important | Design System | ~~Pas de `AppColors`, `AppTextStyles` — 100+ magic constants~~ | ✅ `AppColors`, `AppSpacing`, `AppTheme` créés dans `lib/ui/theme/` + extensions enum rareté (v0.0.99) et `GameThemeExtension` (v0.2.3) | `lib/ui/theme/` |
| Moyen | Lookup O(1) | `GameDataRegistry` utilise `List` avec O(n) | Migrer vers `Map<String, T>` | `game_data_registry.dart` |

### 🟡 Phase 2 — Décomposition God Classes (Semaines 3-4)

| Priorité | Chantier | Problème | Solution | Impact |
|:---|:---|:---|:---|:---|
| Critique | `map_screen.dart` | **2 471 lignes**, 10+ responsabilités | Extraire `MapPainter`, `MapNodeWidget`, `MapLegend`, `MapTooltip`, `MapController` | 2471 → ~400 lignes |
| Critique | `game_screen.dart` | **1 667 lignes**, 5 overlays privés | Extraire `PauseOverlay`, `RewardOverlay`, `DeathOverlay`, `VictoryOverlay`, `HudPanel`, `CombatOrchestrator` | 1667 → ~500 lignes |
| Critique | `card_component.dart` | ~~**1 031 lignes**, render + drag + targeting + animation + tooltip~~ | ✅ Décomposé en `CardRenderer` (Canvas) et `CardInteractionHandler` (Gestes) | ~150 lignes |
| Important | `ui_card.dart` | **1 136 lignes**, god component UI/logic/painting | ✅ Refactorisé en extrayant les sous-widgets dans `ui_card/` (v0.2.01) | 1136 → ~175 lignes |
| Important | `heros_draft_game.dart` | ~~**775 lignes**, 18 callbacks constructeur~~ | ✅ Décomposé en 4 sous-systèmes : `StateSync`, `CardAnimation`, `CombatVisual`, `Layout` | ~400 lignes |
| Important | `stat_badge.dart` | **720 lignes**, 5 classes, recreate all children à chaque update | Extraire classes, optimiser update | Performance + lisibilité |

### 🟢 Phase 3 — Qualité (Semaines 5-6)

| Priorité | Chantier | Problème | Solution |
|:---|:---|:---|:---|
| Important | Couverture tests | ~15-20% estimée | Atteindre ≥50%, ajouter widget tests UI |
| Important | Magic constants | 100+ valeurs codées en dur | ✅ Délais de combat et configurations de floating text extraits dans `GameConstants` (v0.1.9) |
| Important | `EffectResolver` pattern | Classe statique avec switch géant | ✅ Refactoré avec le registre `EffectRegistry` et le Strategy Pattern (v0.2.3) |
| Important | Logique dans Flame | `executeSkill()` calcule des dégâts dans `HerosDraftGame` | ✅ Déplacé vers CombatController (v0.0.97) |
| Moyen | Logique dans UI | Shop/event/heal dans les écrans (Reward déplacé vers RewardController en v0.0.94) | Déplacer vers controllers |

### 🔵 Phase 4 — Long Terme (Semaines 7+)

| Priorité | Chantier | Problème | Solution |
|:---|:---|:---|:---|
| Critique | Persistance / Sauvegarde | ~~Aucune — RAM uniquement~~ | ✅ `SaveService` (`lib/services/save_service.dart`) via `shared_preferences`, autosave à chaque checkpoint carte, bouton "Continuer" sur `HomeScreen` (v3.2.0) — granularité checkpoint carte uniquement, pas de reprise mid-combat (voir ADR-069) |
| Important | Routage centralisé | 20+ `Navigator.push` hardcodés | `GoRouter` avec routes nommées |
| Important | Système Audio | Aucun — `// TODO: Audio Hook` | `flame_audio`, `AudioService` central, musiques dynamiques, effets contextuels |
| Important | Event Bus | 18 callbacks constructeur dans `HerosDraftGame` | Pattern Event Bus pour découpler |
| Moyen | `SkillData` i18n | Champ `name` unique (pas bilingue) | Migrer vers `nameEn`/`nameFr` |
| Moyen | `MapNode` découplage | Importe `Vector2` de Flame dans le modèle de données | Utiliser des types natifs Dart |

---

## 3. Fonctionnalités Non Implémentées (Backlog)

Issues du backlog `docs/possible_upgrades/upgrade_ideas.md` (~95 items, ~60% résolus) :

### Gameplay & Mécanique
- [ ] Restrictions de cartes par classe (ex: Berserker ne peut pas utiliser cartes d'armure)
- [ ] Coût de merge +1 mana par level de carte
- [ ] Limite de taille de deck (15 max, extensible via récompenses légendaires)
- [x] Système XP/level pour gating des récompenses (v0.0.95)
- [x] Statistique de coup critique (dégâts et soins) (v0.0.94 / ADR-027)
- [x] Level Up différé et bloquant sur la carte (v0.1.4)
- [ ] Intentions ennemies cachées en late game
- [x] Rééquilibrage des reliques communes (Whetstone, Leather Boots, Lucky Coin, Bandage) pour le pool de départ (v0.0.95)
- [x] Reliques à charge / compteur (Kunaï, Shuriken, Plume de Scribe, Encensoir) (v0.0.95)
- [x] Déclencheurs par type de carte joué (onAttackPlayed, onSkillPlayed, onPowerPlayed) (v0.0.95)
- [ ] Scaling progressif d'armure ennemi par acte
- [x] Exclusion des cartes uniques de classe du pool de la boutique (v0.1.3)

### Contenu
- [x] Tutoriel / système "How-to-play"
- [ ] Icônes de type de dégâts (feu, glace, poison) sur les descriptions
- [x] Rework des cartes élémentaires (certaines status-only, d'autres damage+status)
- [ ] Nœuds Trésor et Mystère sur la carte
- [x] Rencontre d'échange de reliques (3 reliques → 1 rareté supérieure) (v0.0.96)
- [ ] Onglet Reliques dans le dictionnaire
- [ ] **Nouveaux ennemis tier-1** pour compenser la réduction de variété des Actes 1-5 (roster actuel : Slime, Gobelin uniquement) causée par le gating strict de tier introduit par la refonte du scaling de difficulté (ADR-070) et aggravée par le resserrement de cadence d'ADR-072 (fenêtre tier-1-only réduite des Actes 1-10 aux Actes 1-5, branche `fix/combat_scaling`). Trade-off de design explicitement validé, pas un oversight — voir `decisionLog.md` (ADR-070, ADR-072) et `activeContext.md`.

### Méta-Progression
- [ ] Skins de héros débloquables
- [ ] Monnaie persistante entre les runs
- [ ] Système d'achievements/trophées
- [ ] Menu de patch notes sur l'écran d'accueil

### Carte & Navigation
- [x] Contraintes de génération (pas 3 nœuds identiques consécutifs)
- [x] Génération dynamique de l'étage d'élite central (chokepoint) (v0.1.4)
- [ ] Randomisation du deck de départ avec pools par classe
- [x] Divergence de chemins (routes multiples vers boss)

### UX & Visuel
- [ ] Redesign des snackbar/notifications
- [ ] Redesign descriptions de cartes (icônes-only, descriptions dans tooltips)
- [x] Rework forge du feu de camp (choix de forge limités)
- [x] Rendu de la boutique en grille Wrap/SizedBox pour éviter les overflows (v0.1.3)
- [x] Code couleur d'arrière-plan par type de carte (Attaque, Compétence, Pouvoir, Statut) dans UiCard (v0.1.3)
- [x] Masquage anti-spoil / protection de rareté dans le carrousel de reliques (v0.1.4)
- [ ] Synergies reliques avec cartes début/fin de tour

### Système
- [ ] PvP draft mode (théorique)
- [ ] Boss multi-phases

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
