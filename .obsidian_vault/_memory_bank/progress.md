# 📊 État du Projet & Progrès (Progress)

Ce document dresse l'inventaire technique exhaustif et rigoureux des fonctionnalités de **Hero's Draft** : opérationnelles, partiellement implémentées, non implémentées, et les chantiers de refactoring prioritaires issus des rapports de dette technique.

**Métriques du projet** :
- **~11 400 lignes** de code source dans `lib/` (70 fichiers).
- **8 fichiers JSON** de données d'assets.
- **107 tests automatisés** — 100% au vert.
- **0 erreur** via `flutter analyze`.
- **~118 phases d'implémentation** complétées (historique dans `docs/implementation_plans/done/`).
- **Version actuelle** : v0.2.01 — Décomposition de UiCard (Sprint Forge v2.00 inclus).

---

## 1. Fonctionnalités 100% Opérationnelles

### 🗺️ Génération et Progression Procédurale (World Map)

| Fonctionnalité | Fichiers Clés | Détails |
|:---|:---|:---|
| Graphe Acyclique Dirigé (DAG) | `MapGeneratorService`, `MapNode` | 10 étages (paramétrable), largeur 2-5 nœuds, chokepoint étage central dynamique, repos garanti étage `floors-2`, boss unique étage final |
| Distribution probabiliste des nœuds | `MapGeneratorService._randomNodeType()` | 60% combat, 15% event, 10% shop, 10% rest, 5% elite |
| Quotas équilibrés (Solver) | `MapGeneratorService._balanceQuotas` | Répartition des types de nœuds : Combat (12-22), Élite (3-6), Repos (3-6), Shop (2-5), Event (4-9) |
| Anti-répétition de chemins | `MapGeneratorService._optimizeMapTypes` | Algorithme interdisant 3 nœuds Élite ou Repos consécutifs sur un même chemin |
| Chokepoints structurels forcés | `MapGeneratorService` | Étage central dynamique (`floors ~/ 2`) Élite forcé (1 nœud), Étage `floors-2` Repos forcé (repos garanti avant boss) |
| Level Up différé sur la Carte | `RunController`, `MapScreen`, `GameScreen` | Les gains de niveau incrémentent `pendingDrafts` au lieu d'ouvrir le draft en combat. Un overlay bloquant « LEVEL UP ! » s'affiche sur la carte, forçant le joueur à effectuer ses choix de draft avant de naviguer. |
| Embranchement de Boss multiples | `MapGeneratorService` / `EncounterSystem` | Étage final (Boss) présente 3 nœuds de boss distincts avec récompenses de combat uniques déterminées par leur position |
| Récompenses de Boss uniques | `GameScreen`, `MapNode`, `RewardController`, `BossCardDraftScreen` | Boss 1 (x=0) : sélection forcée de 3 cartes via BossCardDraftScreen. Boss 2 (x=1) : XP/Or doublés. Boss 3 (x=2) : relic drop dynamique par Act dans RewardController. |
| Correction d'orphelins | `MapGeneratorService` (Phase 2 câblage) | Garantie que tout nœud a au moins 1 connexion entrante |
| Navigation réactive | `RunController.travelToNode()` | Validation d'accessibilité (connexion au nœud complété ou étage 0) |
| Caméra centrée | `MapScreen` | Repositionnement et centrage automatique fluide à chaque transition |
| Widgets dédiés par type | `MapScreen` | Icônes spécifiques (Combat/Élite/Shop/Event/Repos/Boss/Exchange) + tooltips |
| Barre d'XP HUD | `MapScreen`, `xp_scaling_test.dart` | Barre de progression d'expérience dorée permanente et badges de niveau sous le HUD |
| Rencontre d'Échange de Reliques | `MapGeneratorService`, `InventoryController`, `RunController`, `RelicExchangeScreen` | Autel d'échange de reliques (nœud relicExchange, emoji 🔄). Apparaît Acte 5+ (100% tous les 5 actes, 10% sinon, étage 2/3/4/6/7). Offre déterministe par seeded random. Échange 3 reliques de rareté R-1 contre 1 de rareté R proposée. |

### 🧠 Gestion d'État Métier (Riverpod Controllers)

| Fonctionnalité | Controller/Provider | Détails |
|:---|:---|:---|
| Modernisation Riverpod | `Tous les Providers` | Migration vers `Notifier` et `NotifierProvider` de Riverpod 2.x, communication inter-contrôleurs interne via `ref.read` sans injection par constructeur, et immuabilité stricte de `CardInstance` (v0.0.97) |
| Logique de Run | `RunController` / `runProvider` | Suivi PV, mana, armorMastery, luck, acte, level, XP, carte, passifs, reliques |
| Persistance Forge v2 | `RunController` / `runProvider` | Sauvegarde anti-exploit de la session de forge active (`forgeSlots`, `forgeTargetCardId`) et gestion des slots bonus achetés avec coût progressif (v0.2.00) |
| Système de Progression XP | `RunController.gainXp()` | Progression XP exponentielle ($100 \times 1.5^{lvl-1}$), gains multiples et carry-over |
| Échelonnement Ennemis | `CombatController.initializeCombat()` | Multiplicateurs dynamiques (+12% HP/lvl, +8% ATK/lvl) et calcul de combat level |
| Logique de Combat | `CombatController` / `combatProvider` | Phases (Player ⇄ Enemy), sélection cible, intentions ennemies (cycliques ou aléatoires), détection mort, victoire/défaite |
| Piles de Cartes | `DeckNotifier` / `deckProvider` | 5 piles logiques (Master, Draw, Hand, Discard, Exhaust) avec shuffle et gestion complète |
| Économie et Reliques | `InventoryController` / `inventoryProvider` | Or (initial 50), 24 reliques (communes rééquilibrées) avec 9 triggers différents, système de charges, bonus boutique |
| Compétences | `SkillController` / `skillProvider` | 2 compétences par héros, cooldowns, consommation de ressources |
| Événements | `EventController` / `eventProvider` | 2 événements narratifs à choix multiples, résolution d'actions, roll de rareté relique |
| Boutique | `ShopController` / `shopProvider` | Achat/purge/clone cartes, soin, expansion, reroll, exclusion logique des cartes de rareté unique (v0.1.3) |
| Récompenses de Victoire | `RewardController` / `rewardProvider` | Or, XP (doublés pour doubleXp), tirage de relique (improvedRelic avec chances dynamiques par Act excluant les communes), et draft de cartes (standard ou boss) |

### 🃏 Système de Cartes et Deck

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Auto-Merge (3→1) | `DeckNotifier.mergeCards()` | 3 copies même ID + rareté → 1 copie rareté supérieure (cumul des Tiers, clamp à la capacité). Les cartes de rareté `unique` (classe) ne peuvent pas être fusionnées (désactivé). |
| Rareté Dynamique | `EffectResolver.resolveCard()` | Progression par rareté (common → legendary) avec coefficients. La rareté `unique` (cartes de classe) est fixée à un multiplicateur de 1.0. |
| Catalogue complet | `cards.json` & `hero_cards.json` | 21 cartes équilibrées : 15 globales (communes) dans cards.json + 6 de classe (unique) dans hero_cards.json |
| Types d'effets | `EffectResolver`, `CardEffect` | damage, heal, armor, draw, gain_mana, apply_status |
| Exhaust mécanique | `DeckNotifier.playCard()` | Cartes Power et `isExhaust` → pile d'épuisement (sauf si upgrade `enduring`) |
| Upgrade de Forge | `DeckNotifier.addForgeUpgrade()` | Ajout d'améliorations (stats, statuts, pioche, enduring). Les cartes uniques ont un maximum d'upgrades fixé à 5. |
| Forge v2 (Refonte) | `ForgeUpgradeDialog` | Dialog.fullscreen responsive, filtrage intelligent selon le type (`skill` sans offensif, `power` utilitaire uniquement), achat de slots additionnels progressifs (v0.2.00) |
| Suppression de carte | `DeckNotifier.removeCardById()` | Oubli au feu de camp (`RestScreen`) : suppression définitive |
| Draft post-combat | `DraftScreen` | 3 choix de cartes aléatoires après victoire (les cartes uniques de classe sont exclues) |
| Draft de départ | `StarterDeckDraftScreen` | Sélection de 5 cartes globales directly depuis la grille complète des 15 cartes globales (suppression du pool de 10 cartes aléatoires) + cartes de classe uniques résolues via compétences |
| Équilibrage Probabilités | `probabilities_test.dart` | Rééquilibrage exact (Commune 52%/51.5%, Atypique 24%, Rare 16%, Épique 6%, Légendaire 2.0%, Mythique 0.5% au Level Up) |

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
| Difficulté Hybride & Budget | `EncounterSystem`, `CombatController` | Formule DDA amortie (damping 0.5) comparant la puissance du joueur à la puissance attendue, et calcul du budget final avec multiplicateurs de nœud |
| Réserve de vagues d'ennemis | `CombatController`, `CombatState` | Limite de 5 ennemis actifs, débordement dans `pendingEnemies`, alimentation automatique au fil des éliminations |

### 🏆 Système de Passifs et Traits de Héros

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Passifs data-driven | `passives.json` → `TraitSystem` | 3 passifs liés aux héros par `HeroData.passiveTrait` |
| Triggers multiples | `TraitSystem.onTurnStart/onTurnEnd/onCardPlayed` | Logique spécifique par effectType (`gain_armor`, `berserker_armor`, `spell_armor`) |
| Reliques à triggers | `RunController.applyRelics(trigger)` | 9 types de triggers : startOfRun, startOfCombat, startOfTurn, endOfTurn, onCardPlayed, onAttackPlayed, onSkillPlayed, onPowerPlayed, onEnemyKilled |
| Reliques à charges | `RunController.applyRelicEffect()` | Croc Kunaï, Shuriken, Plume de Scribe, Encensoir avec compteurs/charges visuels (StatusEffects) |

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
| `UiCard` unifié | `lib/ui/widgets/ui_card.dart` | Remplace 6 rendus dupliqués, style glassmorphic (BackdropFilter 10px), coût en médaillon standardisé, fentes de runes, retrait filigrane & badges de ciblage, doublement d'icônes multicibles |
| Système de Design Centralisé | `lib/ui/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart` | `AppColors` (Neon Dark + Parchemin + stats + raretés + sémantiques), `AppSpacing` (EdgeInsets helpers), `AppTheme` (ThemeData complet dark/light) — v0.0.99 |
| Extensions Enum Rareté | `CardRarity.color`, `RelicRarity.color` (extensions Dart) | Getter `.color` centralisé sur les enums de rareté de cartes et reliques, remplace les switch-case dispersés — v0.0.99 |
| Correction `GameButton` overflow | `lib/ui/widgets/game_button.dart` | Résolution du bug `RenderFlex` overflow sur les boutons or-seulement (icône sans libellé) — v0.0.99 |
| Refactoring `RelicsDialog` | `lib/ui/widgets/relics_dialog.dart` | Remplacement d'un `switch` de 19 lignes par `.color` via extension `RelicRarity` — v0.0.99 |
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
| Rareté Mythique & Alertes | `DraftScreen`, `DraftCardReel` | Rareté rouge sang, alerte cinématique warning 1400ms (laser horizontal, exclamation points `!!!` élastiques), flou d'arrière-plan `BackdropFilter` `8.0px`, spin prolongé `+800ms`, tremblement doublé `12.0` |
| Poli Visuel du Draft | `DraftScreen`, `TutorialDraftWidget` | Survol de carte à 1.05x (AnimatedScale + MouseRegion) et sélection à 1.12x avec lueur dorée (BoxShadow ambre) |
| HUD de Combat Responsive | `GameScreen` | Redimensionnement et mise à l'échelle automatique de la hauteur/largeur du HUD avec clamps de sécurité pour prévenir le clipping |
| Badges de Ciblage Remplacés | `UiCard` / `GameScreen` / `CardTextRenderer` | Suppression complète des badges textuels de ciblage (Single target, All enemies, Self), remplacés par des doublements d'icônes d'action multicibles (double-icon indicators) pour les seuls effets ciblant les ennemis (les effets joueur restent avec une icône simple) (v0.1.5) |
| Badges d'inventaire sur la Carte | `MapScreen` | Compteur numérique sur le bouton des Reliques et badge numérique sur le bouton du Deck affichant la taille du master deck |
| Scaling Échelle Ennemis | `EnemyCard` | Facteurs d'échelle visuelle progressifs sur les sprites des ennemis pour refléter leur puissance relative |
| Optimisations de Rendu GPU | `FloatingText`, `EffectIcon` | Élimination des appels GPU lents/redondants `saveLayer` au profit d'un dessin direct sur canvas (v0.0.98) |
| Caching CPU & Opacité Textes | `CardComponent`, `TextPainter` | Caching des layouts de texte complexes et utilisation conditionnelle de `saveLayer` uniquement si `opacity < 1.0` (v0.0.98) |
| Transition Organique de Pioche | `HerosDraftGame`, `CardComponent` | Spawning des cartes à la pioche `Vector2(40, size.y - 40)` avec glissement, scale et rotation asynchrones vers la main (v0.0.98) |
| Synchro d'Impact & Anti-Double | `EnemyCard`, `CardAnimator` | Dégâts et effets d'impact (flashs, tremblements, particules) différés jusqu'à la collision physique réelle; suppression des doublons (v0.0.98) |
| Blocage de Pioche (Input Blocking) | `CardComponent`, `HerosDraftGame` | Protection contre les clics ou glissements prématurés durant la pioche via le drapeau `isEnteringHand` (v0.1.00) |
| Tooltips de Combat Ciblés | `ui_card.dart`, `card_component.dart` | Affichage sélectif sur focus de carte, auto-masquage au jeu ou changement de phase, et injection formatée des upgrades de forge (v0.1.00) |
| Fentes de Runes (Rune Sockets) | `card_text_renderer.dart`, `ui_card.dart` | Remplacement des étoiles d'upgrades par des sockets de runes (⚔️, 🛡️, 🔥) avec retour à la ligne automatique (wrapping) par rangées de 5 (rows of 5) sur le layout de carte pour éviter tout overflow visuel (v0.1.5) |
| Rareté Visuelle sans Texte | `ui_card.dart`, `card_component.dart` | Retrait des labels textuels de rareté de la face avant des cartes; identification pure par la couleur des bordures et par halo lumineux (glowing shadows/radial glow) lors des sélections (v0.1.5) |
| Jauge HP Double-Transition | `PlayerHealthBar` | Refactorisation en StatefulWidget animée par TweenAnimationBuilder (500ms, easeOutCubic) avec jauge secondaire rouge/orange lagging sous les dégâts et snap direct au soin (v0.1.00) |
| Grille de Boutique | `ShopScreen` / `shop_screen.dart` | Disposition en Wrap avec contrainte de taille SizedBox de 150 par carte pour une grille stable (v0.1.3) |
| Couleur par type de carte | `UiCard` / `CardComponent` | Code couleur d'arrière-plan distinct sémantique (rouge=attack, vert=skill, violet=power, gris=status) et bordure d'accent appliqué aux cartes de menu (`UiCard` - v0.1.3) et étendu aux cartes de combat Flame (`CardComponent` - v0.1.5) |
| Masquage Anti-Spoil de Relique | `RelicRewardCarouselOverlay`, `RelicCarouselCard` | Affichage en gris neutre et anonyme des cartes avec badges « ??? » pendant le spin. Révélation complète des couleurs et déclencheurs à l'arrêt (v0.1.4) |


### 💀 Z-Sync Death & Stats System (Système de Mort et de Stats Synchronisé)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Retardement des morts en combat | `isCardAnimating` & `isPendingDeath` | Deferre le scale-down et fondu de disparition de l'ennemi mort si une carte s'anime |
| Synchronisation des statistiques HUD | `_pendingVisualInstance` & `resolvePendingVisualStats()` | Diffère la diminution visuelle des HP et de l'armure dans le HUD jusqu'à l'instant exact de l'impact de la carte |
| Libération à l'impact | `resolvePendingDeaths()` | Déclenche instantanément la mort de tous les ennemis différés et applique les stats différées à la complétion du coup |
| Morts/Stats hors combat instantanées | Bypass automatique | Les morts/stats hors combat (poison de début de tour) contournent Z-Sync et se résolvent de suite |
| Deferral Visuel Complet d'Impact | `EnemyCard.updateStats()` | Retarde l'apparition des tremblements, flashs de sprite, particules et FloatingText jusqu'à l'impact de la carte de combat (v0.0.98) |
| Nettoyage de Double Réaction | `CardAnimator` | Suppression des doubles déclenchements pour éviter de lancer plusieurs fois les animations d'impact (v0.0.98) |

### ✨ Statuts Élémentaires & Vulnérabilité (`burn`, `freeze`, `shock`, `vulnerable`)

| Statut | Implémentation | Effet Mécanique | Résolution |
|:---|:---|:---|:---|
| Brûlure (`burn`) | `CombatController.startEnemyTurn()` | Dégâts directs = valeur du statut (décrémente intensité/durée de 1) | Début du tour de la cible (joueur ou ennemi) |
| Gel (`freeze`) | `CombatController.resolveEnemyIntent()` | Division par deux (`×0.5` arrondi) de l'attaque, décrémente immédiatement la durée | Lors de l'attaque de l'entité gelée |
| Électrocution (`shock`) | `EffectResolver.resolveCard()` | Ajoute la valeur cumulée du statut aux dégâts directs subis | Lors de la résolution d'une attaque directe subie |
| Vulnérabilité (`vulnerable`) | `EffectResolver.resolveCard()` | Augmente de 50% tous les dégâts d'attaque reçus | Universel (affecte aussi bien le héros que les ennemis) |

### 🎓 Système de Tutoriel Autonome (Standalone Tutorial)

| Fonctionnalité | Implémentation | Détails |
|:---|:---|:---|
| Moteur local | `TutorialEngine`, `TutorialMockState` | ChangeNotifier gérant la progression et un état simulé réinitialisé par étape |
| 13 Étapes Interactives | `TutorialScreen` & widgets `lib/tutorial/widgets/` | Guidage pas-à-pas interactif couvrant l'ensemble du gameplay de base |
| i18n Découplée | `TutorialData` | Textes bilingues FR/EN intégrés directement dans les modèles de données locaux |
| Persistance & Badge "NEW" | `TutorialProgressService`, `HomeScreen` | Sauvegarde de la complétion dans SharedPreferences et affichage d'un badge d'alerte |
| Refactoring de Responsivité | `LayoutBuilder`, `FittedBox`, `SingleChildScrollView`, `Wrap` | Ajustements automatiques multi-résolutions (mobiles portrait/paysage, web, desktop), orientation split et canevas FittedBox |
| Ciblage double phase (Étape 6) | `TutorialPlayCardWidget` | Ciblage interactif en deux temps : d'abord l'attaque (slime), puis la défense (self/hero) |
| Info-bulles & Icônes Canvas (Étape 5) | `TutorialCardsWidget` | Cartes améliorées avec icônes vectorielles réelles dessinées sur Canvas et tooltips descriptifs localisés |


### 🧪 Fiabilité et Assurance Qualité

| Métrique | Valeur | Détails |
|:---|:---|:---|
| Tests automatisés | **106** (100% VERT) | Tests unitaires, widget-tests et tests d'intégration (dont persistance et coûts progressifs de forge, génération de carte avec anti-répétition, responsivité du HUD de combat, et scaling dynamique des ennemis) |
| Couverture estimée | **23%** | Logique/controllers, moteur tutoriel, forge, pas d'UI de production |
| Analyse statique | **0 erreur** | `flutter analyze` sans erreur de compilation |
| Linter | `flutter_lints` v6.0.0 | Configuration standard, pas de règles custom |

---

## 2. Fonctionnalités Partiellement Implémentées (Dette Métier)

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

## 4. Chantiers de Refactoring Prioritaires (Roadmap Dette Technique)

Basé sur les rapports de dette technique (`technical_debt_report_Opus4.6.md`, 4 rapports Gemini 3.5) et les 4 plans d'implémentation de refactoring.

### 🔴 Phase 1 — Fondations (Semaines 1-2)

| Priorité | Chantier | Problème | Solution | Fichiers |
|:---|:---|:---|:---|:---|
| Critique | Typage des modèles | `==`/`hashCode` absents sur 12 modèles, `Map<String, dynamic>` non typés | Ajouter `freezed` ou implémenter manuellement | `lib/models/` (11 fichiers) |
| Critique | Immuabilité réelle des listes | Listes mutables dans états "immuables" | ✅ List.unmodifiable() et final dans CardInstance (v0.0.97) | Tous les controllers |
| Critique | Validation des entrées | `gainGold(-50)` fonctionne, HP peut dépasser maxHP | Ajouter validation dans chaque mutation | `run_controller.dart`, `inventory_controller.dart` |
| Important | Error handling I/O | Aucun `try-catch` dans `GameDataService` | Wrapping avec fallbacks gracieux | `game_data_service.dart` |
| Important | Design System | ~~Pas de `AppColors`, `AppTextStyles` — 100+ magic constants~~ | ✅ `AppColors`, `AppSpacing`, `AppTheme` créés dans `lib/ui/theme/` + extensions enum rareté (v0.0.99) | `lib/ui/theme/` |
| Moyen | Lookup O(1) | `GameDataRegistry` utilise `List` avec O(n) | Migrer vers `Map<String, T>` | `game_data_registry.dart` |

### 🟡 Phase 2 — Décomposition God Classes (Semaines 3-4)

| Priorité | Chantier | Problème | Solution | Impact |
|:---|:---|:---|:---|:---|
| Critique | `map_screen.dart` | **2 471 lignes**, 10+ responsabilités | Extraire `MapPainter`, `MapNodeWidget`, `MapLegend`, `MapTooltip`, `MapController` | 2471 → ~400 lignes |
| Critique | `game_screen.dart` | **1 667 lignes**, 5 overlays privés | Extraire `PauseOverlay`, `RewardOverlay`, `DeathOverlay`, `VictoryOverlay`, `HudPanel`, `CombatOrchestrator` | 1667 → ~500 lignes |
| Critique | `card_component.dart` | **1 031 lignes**, render + drag + targeting + animation + tooltip | Extraire `CardRenderer`, `CardAnimationController`, `CardInteractionHandler` | 1031 → ~300 lignes |
| Important | `ui_card.dart` | **1 136 lignes**, god component UI/logic/painting | ✅ Refactorisé en extrayant les sous-widgets dans `ui_card/` (v0.2.01) | 1136 → ~175 lignes |
| Important | `heros_draft_game.dart` | **775 lignes**, 18 callbacks constructeur | Extraire layout, sync, factories | 775 → ~400 lignes |
| Important | `stat_badge.dart` | **720 lignes**, 5 classes, recreate all children à chaque update | Extraire classes, optimiser update | Performance + lisibilité |

### 🟢 Phase 3 — Qualité (Semaines 5-6)

| Priorité | Chantier | Problème | Solution |
|:---|:---|:---|:---|
| Important | Couverture tests | ~15-20% estimée | Atteindre ≥50%, ajouter widget tests UI |
| Important | Magic constants | 100+ valeurs codées en dur | Extraire dans `GameConstants` étendu |
| Important | `EffectResolver` pattern | Classe statique avec switch géant | Migrer vers Strategy/Command pattern |
| Important | Logique dans Flame | `executeSkill()` calcule des dégâts dans `HerosDraftGame` | ✅ Déplacé vers CombatController (v0.0.97) |
| Moyen | Logique dans UI | Shop/event/heal dans les écrans (Reward déplacé vers RewardController en v0.0.94) | Déplacer vers controllers |

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

---

## 7. Historique des Releases (Release History)

| Version | Date | Titre | Description des changements clés |
|:---|:---|:---|:---|
| **v0.2.01** | 2026-06-12 | Décomposition de UiCard (SRP) | Refactoring de la god class `UiCard` (1136 lignes) en extrayant ses sous-widgets (`CardManaMedallion`, `CardRuneSockets`, `CardCompactDescription`) et ses helpers (`ui_card_helpers.dart`) dans un sous-dossier `ui_card/` dédié, garantissant la cohésion, respectant le principe de responsabilité unique (SRP) et la structure du framework Flutter. |
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

