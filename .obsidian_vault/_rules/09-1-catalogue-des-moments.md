## 9.1. Catalogue des moments et de leurs déclencheurs

Détachée de [`09-00`](09-00-systeme-audio.md) le 2026-09-01, quand le catalogue est passé
de 14 à **22 moments** : la fiche mère atteignait son plafond, et ce tableau est la partie
qui grossit à chaque livraison de contenu.

Un moment est un **événement de jeu**, jamais un fichier. La résolution moment → son vit
dans la donnée (`assets/data/audio.json`) et la chaîne de repli est décrite en
[`09-00`](09-00-systeme-audio.md) §9.2.

### Combat

| Moment (`GameMoment`) | Déclencheur |
|:---|:---|
| `cardPlay` | `CardAnimator.playAnimation()`, au tout début de l'animation — résolu via `CardData` comme `AudioSource` (`sfx` propre, puis `animation`, puis défaut) — `lib/game/components/visual_effects/card_animator.dart:154` |
| `impact` / `impactCrit` | `CombatEntity.triggerHitReactions()`, perte de PV actuels — `lib/game/components/entities/combat_entity.dart:215` |
| `armorHit` | Même méthode, **perte** d'armure — `combat_entity.dart:196` |
| `armorGain` | Même méthode, **gain** d'armure — `combat_entity.dart:208`. Séparé d'`armorHit` le 2026-08-29 : les deux branches opposées partageaient le son du coup encaissé, si bien qu'une carte défensive sonnait comme une carte subie |
| `heal` | Même méthode, gain de PV actuels — `combat_entity.dart:249`. **Voir l'avertissement [`09-00`](09-00-systeme-audio.md) §9.5** |
| `enemyAttack` | `HerosDraftGame._enemyRipostePhase()`, avant `dashAnimation()` — `heros_draft_game.dart:401` |
| `enemyDeath` | **Deux sites** : `HerosDraftGame.resolvePendingDeaths()` (mort différée pendant une animation de carte, `heros_draft_game.dart:251`) et `StateSyncSystem._applyCombatState()` (suppression immédiate hors animation — poison, effets passifs — `lib/game/systems/state_sync_system.dart:113`) |
| `turnStart` | `TurnPhaseManager.startPlayerTurn()`, avant le tick des reliques et statuts — `lib/game/controllers/combat/turn_phase_manager.dart:49` |
| `turnEnd` | `HerosDraftGame.executeTurn()`, juste après la garde de validité du tour — `heros_draft_game.dart:327` |

> [!IMPORTANT]
> `triggerHitReactions()` est un **entonnoir unique**, appelé aussi bien par `hero_card.dart`
> que par `enemy_card.dart` : cinq moments — les plus fréquents en combat — se branchent en un
> seul endroit, héros et ennemis couverts d'un coup.
>
> Depuis le 2026-08-29, ces cinq-là ne sonnent plus au moment où l'état change, mais à la
> **frappe d'impact** de l'animation en cours. Le mécanisme est décrit en
> [`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md) §16.7.

### Main et cartes

| Moment (`GameMoment`) | Déclencheur |
|:---|:---|
| `cardHover` | `HerosDraftGame.setHoveredCard()` — `lib/game/heros_draft_game.dart:97` |
| `cardPickup` | **Deux sites mutuellement exclusifs, un par geste de prise en main** : `CardInteractionHandler.onTapDown()`, quand la carte devient la carte focalisée par un clic (`lib/game/components/widgets/card_interaction_handler.dart:39`), et `onDragStart()`, dans la branche où la carte n'était pas déjà focalisée (`card_interaction_handler.dart:70`). `onTapDown` s'exécute toujours en premier sur un même geste (arène de gestes Flutter) et détermine donc lequel des deux émet : jamais les deux, jamais aucun |
| `cardDraw` | `DeckNotifier.drawCards()` — `lib/game/controllers/deck_controller.dart:226` |
| `manaGain` | `GainManaEffectStrategy` — `lib/game/services/effects/strategies.dart:109` |
| `insufficientMana` | **Quatre sites** : `HerosDraftGame._handlePlayerTargeting()` (`heros_draft_game.dart:308`), `PlayerStatsManager` — refus de compétence héroïque (`player_stats_manager.dart:441`), `HeroCard` (`hero_card.dart:89`) et `CardInteractionHandler` (`card_interaction_handler.dart:135`) |

### Interface et rouleaux *(ajoutés le 2026-08-29)*

| Moment (`GameMoment`) | Déclencheur |
|:---|:---|
| `uiTap` | `GameButton` — `lib/ui/widgets/game_button.dart:44`. **Point unique** : tout menu passe par ce bouton, donc aucun écran n'a de câblage propre |
| `mapNodeSelect` | `MapScreen._onNodeTap()` — `lib/ui/screens/map_screen.dart:394`. Émis **après** la garde `pendingDrafts` : un clic refusé ne sonne pas comme un départ |
| `draftCardPick` | `StarterDeckDraftScreen._toggleCardSelection()` — `lib/ui/screens/starter_deck_draft_screen.dart:67`. Sonne aussi à la désélection |
| `carouselTick` | Un cran par relique qui défile — `lib/ui/screens/game_screen.dart:164` |
| `carouselLand` | Le carrousel s'immobilise — `game_screen.dart:166` |
| `reelTick` | Une carte défile dans un rouleau de draft — `lib/ui/screens/draft_screen.dart:54` |
| `reelLand` | La révélation, **résolue par rareté** — `draft_screen.dart:63` |

> [!NOTE]
> **Le ralentissement « machine à sous » n'est pas calculé.** Le carrousel anime sur 4 s en
> `easeOutCubic` et émet un cran par relique : la décélération vient de sa propre courbe.
> Aucun code de cadence n'existe, et il ne faut pas en ajouter.

> [!IMPORTANT]
> **`reelLand` porte la rareté comme clé de variante**, via le `byAnimation` de
> [`09-00`](09-00-systeme-audio.md) §9.3 — le même sélecteur qui sert aux types d'animation
> des cartes. Aucun schéma ni code de résolution en plus, et plusieurs raretés peuvent
> pointer le même son tant qu'un bruitage distinct n'est pas sourcé.
>
> La rareté transmise est l'**enum brut** (`RewardRarity.name`), jamais le champ
> `DraftCardReel.rarity`, qui est un libellé *localisé* : s'en servir rendrait le son
> dépendant de la langue. Le vocabulaire est celui de `RewardRarity`, dont la valeur haute
> est `mythic` — et non `unique` comme dans `CardRarity`.

Les moments systémiques (tour, pioche, mana, survol, interface) n'ont pas de `source` et se
résolvent directement au niveau 3 de la chaîne de repli.
