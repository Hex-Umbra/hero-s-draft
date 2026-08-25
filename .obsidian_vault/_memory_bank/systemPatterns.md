# 🏗️ Architecture & Conception — Index

> [!IMPORTANT]
> **Plafond : 120 lignes.** Ce fichier est un index, jamais un contenu. Chaque pattern d'architecture vit dans sa fiche sous `../_patterns/`. Les arbitrages qui les ont produits vivent dans `../_adr/`.

**Vérifié le 2026-08-20** — 40 fiches. Découpage initial depuis un `systemPatterns.md` de 1320 lignes (après archivage des §13-14) ; §15 ajoutée le 2026-08-20.

### 1. Architecture Globale — Séparation Triangulaire

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 1. Architecture Globale — Séparation Triangulaire | [01-00-architecture-globale-separation-triangulaire.md](../_patterns/01-00-architecture-globale-separation-triangulaire.md) | 57 |

### 2. Rôle des Contrôleurs et Architecture Modulaire (`lib/game/controllers/`)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 2. Rôle des Contrôleurs et Architecture Modulaire (`lib/game/controllers/`) | [02-00-role-des-controleurs-et-architecture-modulair.md](../_patterns/02-00-role-des-controleurs-et-architecture-modulair.md) | 5 |
| 2.1. `RunController` (`runProvider`) — Superviseur Global (Façade) | [02-1-runcontroller-superviseur-global.md](../_patterns/02-1-runcontroller-superviseur-global.md) | 26 |
| 2.1.bis Persistance de Run — `SaveService`, Checkpoints et Réhydratation (v3.2.0) | [02-1-bis-bis-persistance-de-run-saveservice-checkpoint.md](../_patterns/02-1-bis-bis-persistance-de-run-saveservice-checkpoint.md) | 13 |
| 2.2. `CombatController` (`combatProvider`) — Pilote de Combat (Façade) | [02-2-combatcontroller-pilote-de-combat.md](../_patterns/02-2-combatcontroller-pilote-de-combat.md) | 31 |
| 2.3. `DeckNotifier` (`deckProvider`) — Maître du Deck | [02-3-decknotifier-maitre-du-deck.md](../_patterns/02-3-decknotifier-maitre-du-deck.md) | 14 |
| 2.4. `EventController` (`eventProvider`) | [02-4-eventcontroller.md](../_patterns/02-4-eventcontroller.md) | 49 |
| 2.5. `ShopController` (`shopProvider`) | [02-5-shopcontroller.md](../_patterns/02-5-shopcontroller.md) | 30 |
| 2.5. Immutabilité Stricte des Modèles d'État | [02-5-immutabilite-stricte-des-modeles-d-etat.md](../_patterns/02-5-immutabilite-stricte-des-modeles-d-etat.md) | 4 |
| 2.6. `InventoryController` (`inventoryProvider`) | [02-6-inventorycontroller.md](../_patterns/02-6-inventorycontroller.md) | 7 |
| 2.7. `SkillController` (`skillProvider`) | [02-7-skillcontroller.md](../_patterns/02-7-skillcontroller.md) | 7 |
| 2.8. `RewardController` (`rewardProvider`) — Pilote des Récompenses de Combat | [02-8-rewardcontroller-pilote-des-recompenses-de-co.md](../_patterns/02-8-rewardcontroller-pilote-des-recompenses-de-co.md) | 32 |

### 3. Systèmes Transversaux (`lib/game/systems/`)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 3.1. `EncounterSystem` — Générateur de Combats & Courbes d'Équilibrage | [03-1-encountersystem-generateur-de-combats-courbes.md](../_patterns/03-1-encountersystem-generateur-de-combats-courbes.md) | 79 |
| 3.2. `MapGeneratorService` — Générateur de Graphe de Carte du Monde (DAG World Map) | [03-2-mapgeneratorservice-generateur-de-graphe-de-c.md](../_patterns/03-2-mapgeneratorservice-generateur-de-graphe-de-c.md) | 21 |
| 3.3. `TraitSystem` — Passifs de Héros | [03-3-traitsystem-passifs-de-heros.md](../_patterns/03-3-traitsystem-passifs-de-heros.md) | 12 |
| 3.4. `EffectResolver` — Résolution d'Effets de Cartes | [03-4-effectresolver-resolution-d-effets-de-cartes.md](../_patterns/03-4-effectresolver-resolution-d-effets-de-cartes.md) | 36 |
| 3.5. `CombatDebugLogger` — Service de Journalisation Mathématique du Combat | [03-5-combatdebuglogger-service-de-journalisation-m.md](../_patterns/03-5-combatdebuglogger-service-de-journalisation-m.md) | 14 |
| 3.6. Systèmes de Jeu et Rendu Flame (`lib/game/systems/`) | [03-6-systemes-de-jeu-et-rendu-flame.md](../_patterns/03-6-systemes-de-jeu-et-rendu-flame.md) | 16 |
| 3.7. Logique de Forge Data-Driven & Forge de Fusion | [03-7-logique-de-forge-data-driven-forge-de-fusion.md](../_patterns/03-7-logique-de-forge-data-driven-forge-de-fusion.md) | 21 |

### 4. Synchronisation Bidirectionnelle Flame ⇄ Riverpod

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 4. Synchronisation Bidirectionnelle Flame ⇄ Riverpod | [04-00-synchronisation-bidirectionnelle-flame-riverp.md](../_patterns/04-00-synchronisation-bidirectionnelle-flame-riverp.md) | 79 |

### 5. UI et Composants Graphiques

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 5.1. Écrans Flutter (`lib/ui/screens/`) | [05-1-ecrans-flutter.md](../_patterns/05-1-ecrans-flutter.md) | 17 |
| 5.2. Widget `UiCard` (`lib/ui/widgets/ui_card.dart`) | [05-2-widget-uicard.md](../_patterns/05-2-widget-uicard.md) | 33 |
| 5.3. Composants Flame (`lib/game/components/`) | [05-3-composants-flame.md](../_patterns/05-3-composants-flame.md) | 22 |
| 5.3.1. Abstractions Graphiques Communes (CombatEntity & BaseVisualEffect) | [05-3-1-abstractions-graphiques-communes.md](../_patterns/05-3-1-abstractions-graphiques-communes.md) | 12 |
| 5.4. Constantes de Z-Indexing (`GameConstants`) | [05-4-constantes-de-z-indexing.md](../_patterns/05-4-constantes-de-z-indexing.md) | 13 |
| 5.5. Dimensions de Carte | [05-5-dimensions-de-carte.md](../_patterns/05-5-dimensions-de-carte.md) | 6 |
| 5.6. Layout de Main en Arc | [05-6-layout-de-main-en-arc.md](../_patterns/05-6-layout-de-main-en-arc.md) | 8 |
| 5.7. Courbes de Ciblage Réactives en Bézier Quadratique | [05-7-courbes-de-ciblage-reactives-en-bezier-quadra.md](../_patterns/05-7-courbes-de-ciblage-reactives-en-bezier-quadra.md) | 26 |
| 5.8. Rendu Vectoriel direct sur Canvas & Auras Sensoriels | [05-8-rendu-vectoriel-direct-sur-canvas-auras-senso.md](../_patterns/05-8-rendu-vectoriel-direct-sur-canvas-auras-senso.md) | 26 |
| 5.9. Pattern de Draft Card Reels Staggered et 3D Flip (Interactive Reels Reveal) | [05-9-pattern-de-draft-card-reels-staggered-et-3d-f.md](../_patterns/05-9-pattern-de-draft-card-reels-staggered-et-3d-f.md) | 27 |
| 5.10. Optimisations de Rendu GPU/CPU & Effet Physique de Pioche | [05-10-optimisations-de-rendu-gpu-cpu-effet-physique.md](../_patterns/05-10-optimisations-de-rendu-gpu-cpu-effet-physique.md) | 16 |
| 5.11. Unification UI et Composants Communs (v0.2.2) | [05-11-unification-ui-et-composants-communs.md](../_patterns/05-11-unification-ui-et-composants-communs.md) | 27 |

### 6. Stratégie de State Management (Riverpod v2.5.1)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 6. Stratégie de State Management (Riverpod v2.5.1) | [06-00-strategie-de-state-management.md](../_patterns/06-00-strategie-de-state-management.md) | 34 |

### 7. Flux Complet d'un Tour de Combat

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 7. Flux Complet d'un Tour de Combat | [07-00-flux-complet-d-un-tour-de-combat.md](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md) | 54 |

### 8. Conventions de Code & Standards Techniques

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 8. Conventions de Code & Standards Techniques | [08-00-conventions-de-code-standards-techniques.md](../_patterns/08-00-conventions-de-code-standards-techniques.md) | 94 |

### 9. Architecture du Système de Tutoriel Autonome (Tutorial System Technical Design)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 9. Architecture du Système de Tutoriel Autonome (Tutorial System Technical Design) | [09-00-architecture-du-systeme-de-tutoriel-autonome.md](../_patterns/09-00-architecture-du-systeme-de-tutoriel-autonome.md) | 134 |

### 10. Architecture du Système de Forge et de Fusion de Cartes (Forge & Card Merge Technical Design)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 10. Architecture du Système de Forge et de Fusion de Cartes (Forge & Card Merge Technical Design) | [10-00-architecture-du-systeme-de-forge-et-de-fusion.md](../_patterns/10-00-architecture-du-systeme-de-forge-et-de-fusion.md) | 109 |

### 11. Système de Reliques Avancé : Déclencheurs de Cartes Spécifiques et Charges

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 11. Système de Reliques Avancé : Déclencheurs de Cartes Spécifiques et Charges | [11-00-systeme-de-reliques-avance-declencheurs-de-ca.md](../_patterns/11-00-systeme-de-reliques-avance-declencheurs-de-ca.md) | 58 |

### 12. Autel d'Échange de Reliques (`RelicExchangeScreen`)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 12. Autel d'Échange de Reliques (`RelicExchangeScreen`) | [12-00-autel-d-echange-de-reliques.md](../_patterns/12-00-autel-d-echange-de-reliques.md) | 47 |

### 15. Chaîne de Release et Site Vitrine (`.github/` et `site/`)

| Domaine | Fiche | Lignes |
|:---|:---|---:|
| 15. Chaîne de Release et Site Vitrine (`.github/` et `site/`) | [15-00-chaine-de-release-et-site-vitrine.md](../_patterns/15-00-chaine-de-release-et-site-vitrine.md) | 83 |

---

## Historique

Les sections §13 (Design System, v0.0.99) et §14 (UX Combat, v0.1.00) sont dans `../_archive/2026-08-03-systemPatterns-historique.md` — leurs numéros restent pris, d'où le saut de §12 à §15.
