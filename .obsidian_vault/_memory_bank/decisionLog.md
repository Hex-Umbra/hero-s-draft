# 📋 Index des Décisions Architecturales (Decision Log)

Index des **ADR** (Architecture Decision Records) de **Hero's Draft**. Le corps de chaque décision vit dans son propre fichier sous `.obsidian_vault/_adr/`.

> [!IMPORTANT]
> **Plafond : 250 lignes.** Ce fichier est un index, jamais un contenu. Un nouvel ADR prend le numéro `max(index) + 1` lu ici, jamais un numéro deviné.

**Vérifié le 2026-08-23** — 81 décisions, numéros `ADR-001` à `ADR-081`, sans doublon ni trou.

| N° | Décision | Statut | Version | Fichier |
|:---|:---|:---:|:---:|:---|
| `ADR-081` | Amendement de la Règle d'Autonomie du Tutoriel — Zéro Provider d'État (chantier P-45) | ✅ | 0.4.9 | [ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md) |
| `ADR-080` | Site Vitrine Piloté par la Donnée et Jointure Déclarée Version → Patch Note (chantier P-04, lot 2) | ✅ | 0.4.8 | [ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md) |
| `ADR-079` | Chaîne de Release Déclenchée par Tag et Garde-fou de Version à Trois Fichiers (chantier P-04, lot 1) | ✅ | — | [ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md) |
| `ADR-078` | Assainissement du Système de Pioche — Remélange à Sec, Arrêt Net et Règle de Tour hors du Widget (chantier P-02) | ✅ | 0.4.7 | [ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md) |
| `ADR-077` | Clarté Visuelle du Mana des Reliques en Combat (v3.0.1) | ✅ | v3.0.1 | [ADR-077-clarte-visuelle-du-mana-des-reliques-en-combat.md](../_adr/ADR-077-clarte-visuelle-du-mana-des-reliques-en-combat.md) |
| `ADR-076` | Synchronisation Synchrone du Bouton Fin de Tour | ✅ | v0.2.5 | [ADR-076-synchronisation-synchrone-du-bouton-fin-de-tour.md](../_adr/ADR-076-synchronisation-synchrone-du-bouton-fin-de-tour.md) |
| `ADR-075` | Résolution Robuste des Clés Dupliquées dans l'Overlay de Notification (v0.2.8) | ✅ | v0.2.8 | [ADR-075-resolution-robuste-des-cles-dupliquees-dans-l-over.md](../_adr/ADR-075-resolution-robuste-des-cles-dupliquees-dans-l-over.md) |
| `ADR-074` | Introduction de la Forge de Fusion Procédurale et Forge Pilotée par les Données (v3.1.0) | ✅ | v3.1.0 | [ADR-074-introduction-de-la-forge-de-fusion-procedurale-et.md](../_adr/ADR-074-introduction-de-la-forge-de-fusion-procedurale-et.md) |
| `ADR-073` | Réactivité du Bouton « Continuer » de `HomeScreen` après Retour via `popUntil` (branche `fix/combat_scaling`) | ✅ | — | [ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md](../_adr/ADR-073-reactivite-du-bouton-continuer-de-homescreen-apres.md) |
| `ADR-072` | Resserrement de la Cadence du Scaling de Difficulté — Palier tous les 2 Actes & Tier tous les 5 Actes (branche `fix/combat_scaling`, suite d'ADR-070/ADR-071) | ✅ | v0.4.6 | [ADR-072-resserrement-de-la-cadence-du-scaling-de-difficult.md](../_adr/ADR-072-resserrement-de-la-cadence-du-scaling-de-difficult.md) |
| `ADR-071` | Plafonnement du Nombre d'Ennemis par Acte & Résolution de la Dérive Log/Calcul (branche `feature/combat_scaling`, suite d'ADR-070) | ✅ | — | [ADR-071-plafonnement-du-nombre-d-ennemis-par-acte-resoluti.md](../_adr/ADR-071-plafonnement-du-nombre-d-ennemis-par-acte-resoluti.md) |
| `ADR-070` | Scaling de Difficulté en Escalier Géométrique & Déblocage de Tier d'Ennemi (branche `feature/combat_scaling`) | ✅ | v0.4.5 | [ADR-070-scaling-de-difficulte-en-escalier-geometrique-debl.md](../_adr/ADR-070-scaling-de-difficulte-en-escalier-geometrique-debl.md) |
| `ADR-069` | Système de Sauvegarde de Run — Checkpoint Carte, `RefReader`, et Dégradation Gracieuse du Contenu Manquant (v3.2.0) | ✅ | v3.2.0 | [ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md](../_adr/ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md) |
| `ADR-068` | Refonte Équilibrée, Rendu Visuel et Validation d'Éligibilité du Système d'Événements (v0.3.0) | ✅ | v0.3.0 | [ADR-068-refonte-equilibree-rendu-visuel-et-validation-d-el.md](../_adr/ADR-068-refonte-equilibree-rendu-visuel-et-validation-d-el.md) |
| `ADR-067` | Équilibrage de l'Économie, Scaling par Acte des Cartes en Boutique et Réinitialisation du Miroir Magique (v0.2.9) | ✅ | v0.2.9 | [ADR-067-equilibrage-de-l-economie-scaling-par-acte-des-car.md](../_adr/ADR-067-equilibrage-de-l-economie-scaling-par-acte-des-car.md) |
| `ADR-066` | Révision du Scaling de Difficulté et du Spawn des Ennemis (v0.2.7) | ✅ | v0.2.7 | [ADR-066-revision-du-scaling-de-difficulte-et-du-spawn-des.md](../_adr/ADR-066-revision-du-scaling-de-difficulte-et-du-spawn-des.md) |
| `ADR-065` | Double Confirmation de Fin de Tour avec Mana Restant (v0.2.6) | ✅ | v0.2.6 | [ADR-065-double-confirmation-de-fin-de-tour-avec-mana-resta.md](../_adr/ADR-065-double-confirmation-de-fin-de-tour-avec-mana-resta.md) |
| `ADR-064` | Harmonisation de l'Architecture — Abstractions Flame, Riverpodisation du Registry et Simplification du Modèle de Carte (v0.2.4) | ✅ | v0.2.4 | [ADR-064-harmonisation-de-l-architecture-abstractions-flame.md](../_adr/ADR-064-harmonisation-de-l-architecture-abstractions-flame.md) |
| `ADR-063` | Extension de Thème pour Jetons Gameplay & Diagnostic de Diagnostic Data (v0.2.3) | ✅ | v0.2.3 | [ADR-063-extension-de-theme-pour-jetons-gameplay-diagnostic.md](../_adr/ADR-063-extension-de-theme-pour-jetons-gameplay-diagnostic.md) |
| `ADR-062` | Abstractions Graphiques Communes dans Flame (CombatEntity & BaseVisualEffect) (v0.2.3) | ✅ | v0.2.3 | [ADR-062-abstractions-graphiques-communes-dans-flame.md](../_adr/ADR-062-abstractions-graphiques-communes-dans-flame.md) |
| `ADR-061` | Strategy Pattern pour la résolution des effets de cartes (v0.2.3) | ✅ | v0.2.3 | [ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md](../_adr/ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md) |
| `ADR-060` | Décomposition modulaire de la génération procédurale de la carte (v0.2.3) | ✅ | v0.2.3 | [ADR-060-decomposition-modulaire-de-la-generation-procedura.md](../_adr/ADR-060-decomposition-modulaire-de-la-generation-procedura.md) |
| `ADR-059` | Unification de l'UI et Composants d'Infrastructure Communs (v0.2.2) | ✅ | v0.2.2 | [ADR-059-unification-de-l-ui-et-composants-d-infrastructure.md](../_adr/ADR-059-unification-de-l-ui-et-composants-d-infrastructure.md) |
| `ADR-058` | Modularité Rendu Flame / Composants de Rendu (v0.2.10) | ✅ | v0.2.10 | [ADR-058-modularite-rendu-flame-composants-de-rendu.md](../_adr/ADR-058-modularite-rendu-flame-composants-de-rendu.md) |
| `ADR-057` | Décomposition des Contrôleurs Globaux en Managers Spécialisés (v0.2.10) | ✅ | v0.2.10 | [ADR-057-decomposition-des-controleurs-globaux-en-managers.md](../_adr/ADR-057-decomposition-des-controleurs-globaux-en-managers.md) |
| `ADR-056` | Centralisation du Calcul des Dégâts via un Pipeline Unique (v0.1.9) | ✅ | v0.1.9 | [ADR-056-centralisation-du-calcul-des-degats-via-un-pipelin.md](../_adr/ADR-056-centralisation-du-calcul-des-degats-via-un-pipelin.md) |
| `ADR-055` | Immutabilité Stricte des Modèles d'État (v0.1.9) | ✅ | v0.1.9 | [ADR-055-immutabilite-stricte-des-modeles-d-etat.md](../_adr/ADR-055-immutabilite-stricte-des-modeles-d-etat.md) |
| `ADR-054` | Centralisation et Harmonisation des Constantes (v0.1.9) | ✅ | v0.1.9 | [ADR-054-centralisation-et-harmonisation-des-constantes.md](../_adr/ADR-054-centralisation-et-harmonisation-des-constantes.md) |
| `ADR-053` | Réinitialisation de l'Armure du Joueur en Début de Tour & Suppression de l'Animation (v0.1.8) | ✅ | v0.1.8 | [ADR-053-reinitialisation-de-l-armure-du-joueur-en-debut-de.md](../_adr/ADR-053-reinitialisation-de-l-armure-du-joueur-en-debut-de.md) |
| `ADR-052` | Amélioration Visuelle, Caching Anti-Exploit du Magic Mirror et Gating de Solde de la Boutique (v0.1.7) | ✅ | v0.1.7 | [ADR-052-amelioration-visuelle-caching-anti-exploit-du-magi.md](../_adr/ADR-052-amelioration-visuelle-caching-anti-exploit-du-magi.md) |
| `ADR-051` | Filtrage des Cartes de Rareté Unique dans les Récompenses de Boss (v0.1.7) | ✅ | v0.1.7 | [ADR-051-filtrage-des-cartes-de-rarete-unique-dans-les-reco.md](../_adr/ADR-051-filtrage-des-cartes-de-rarete-unique-dans-les-reco.md) |
| `ADR-050` | Animation Dynamique des Particules du Carrousel de Reliques (v0.1.7) | ✅ | v0.1.7 | [ADR-050-animation-dynamique-des-particules-du-carrousel-de.md](../_adr/ADR-050-animation-dynamique-des-particules-du-carrousel-de.md) |
| `ADR-049` | Correction de la Relique Croc Kunaï (v0.1.7) | ✅ | v0.1.7 | [ADR-049-correction-de-la-relique-croc-kunai.md](../_adr/ADR-049-correction-de-la-relique-croc-kunai.md) |
| `ADR-048` | État Critique Déterministe, Nombres Flottants Néon et Décélération de Jauge HP (v0.1.7) | ✅ | v0.1.7 | [ADR-048-etat-critique-deterministe-nombres-flottants-neon.md](../_adr/ADR-048-etat-critique-deterministe-nombres-flottants-neon.md) |
| `ADR-047` | Résolution des Armures de Forge sur Attaque et Persistance/Visualisation du Gel (v0.1.6) | ✅ | v0.1.6 | [ADR-047-resolution-des-armures-de-forge-sur-attaque-et-per.md](../_adr/ADR-047-resolution-des-armures-de-forge-sur-attaque-et-per.md) |
| `ADR-046` | Effet de Bordure Foil Progressif pour les Cartes Uniques (Progressive Unique Card Border Foil Effect) | ✅ | v0.2.02 | [ADR-046-effet-de-bordure-foil-progressif-pour-les-cartes-u.md](../_adr/ADR-046-effet-de-bordure-foil-progressif-pour-les-cartes-u.md) |
| `ADR-045` | Décomposition et Découplage de la God Class `UiCard` (UiCard Decomposition & Decoupling) | ✅ | v0.2.01 | [ADR-045-decomposition-et-decouplage-de-la-god-class-uicard.md](../_adr/ADR-045-decomposition-et-decouplage-de-la-god-class-uicard.md) |
| `ADR-044` | Refonte Visuelle et Structurelle des Cartes (Unified Glassmorphic Card UI) | ✅ | v0.1.5 | [ADR-044-refonte-visuelle-et-structurelle-des-cartes.md](../_adr/ADR-044-refonte-visuelle-et-structurelle-des-cartes.md) |
| `ADR-043` | Génération Dynamique du Goulot d'Étranglement Central (Dynamic Central Chokepoint Generation) | ✅ | v0.1.4 | [ADR-043-generation-dynamique-du-goulot-d-etranglement-cent.md](../_adr/ADR-043-generation-dynamique-du-goulot-d-etranglement-cent.md) |
| `ADR-042` | Protection Anti-Spoil dans le Carrousel de Reliques & Décoration Dynamique (Relic Carousel Rarity Masking & Polish) | ✅ | v0.1.4 | [ADR-042-protection-anti-spoil-dans-le-carrousel-de-relique.md](../_adr/ADR-042-protection-anti-spoil-dans-le-carrousel-de-relique.md) |
| `ADR-041` | Système de Level Up Différé sur la Carte & Bloquant (Deferred Level Up & Interaction Blocking on Map) | ✅ | v0.1.4 | [ADR-041-systeme-de-level-up-differe-sur-la-carte-bloquant.md](../_adr/ADR-041-systeme-de-level-up-differe-sur-la-carte-bloquant.md) |
| `ADR-040` | Harmonie Visuelle & Améliorations de Boutique (Visual Harmony & Shop Improvements) | ✅ | v0.1.3 | [ADR-040-harmonie-visuelle-ameliorations-de-boutique.md](../_adr/ADR-040-harmonie-visuelle-ameliorations-de-boutique.md) |
| `ADR-039` | Système de Forge v2 — Anti-Exploit, Filtrage Typé, Achat Progressif et Layout Plein Écran | ✅ | v0.2.00 | [ADR-039-systeme-de-forge-v2-anti-exploit-filtrage-type-ach.md](../_adr/ADR-039-systeme-de-forge-v2-anti-exploit-filtrage-type-ach.md) |
| `ADR-038` | Interface UX Combat — Blocage de Pioche, Tooltips Ciblés, Étoiles de Forge et Double Jauge HP (v0.1.00) | ✅ | v0.1.00 | [ADR-038-interface-ux-combat-blocage-de-pioche-tooltips-cib.md](../_adr/ADR-038-interface-ux-combat-blocage-de-pioche-tooltips-cib.md) |
| `ADR-037` | Système de Design Centralisé & Uniformisation UI (Design System & UI Uniformization) | ✅ | — | [ADR-037-systeme-de-design-centralise-uniformisation-ui.md](../_adr/ADR-037-systeme-de-design-centralise-uniformisation-ui.md) |
| `ADR-036` | Optimisations Graphiques, Performances de Rendu Flame & Synchronisation des Animations (Graphics, Performance & Animation Optimizations) | ✅ | — | [ADR-036-optimisations-graphiques-performances-de-rendu-fla.md](../_adr/ADR-036-optimisations-graphiques-performances-de-rendu-fla.md) |
| `ADR-035` | Modernisation Architecturale Riverpod & Découplage (Riverpod Notifier & Architectural Cleanups) | ✅ | — | [ADR-035-modernisation-architecturale-riverpod-decouplage.md](../_adr/ADR-035-modernisation-architecturale-riverpod-decouplage.md) |
| `ADR-034` | Rencontre d'Échange de Reliques (Relic Exchange Shrine Node) | ✅ | — | [ADR-034-rencontre-d-echange-de-reliques.md](../_adr/ADR-034-rencontre-d-echange-de-reliques.md) |
| `ADR-033` | Refonte des Reliques, Déclencheurs de Type de Carte et Système de Charges (Relic Overhaul, Card-Type Triggers & Charge Systems) | ✅ | — | [ADR-033-refonte-des-reliques-declencheurs-de-type-de-carte.md](../_adr/ADR-033-refonte-des-reliques-declencheurs-de-type-de-carte.md) |
| `ADR-032` | Finalisation du Refactoring des Récompenses de Boss (Boss Rewards Finalization) | ✅ | — | [ADR-032-finalisation-du-refactoring-des-recompenses-de-bos.md](../_adr/ADR-032-finalisation-du-refactoring-des-recompenses-de-bos.md) |
| `ADR-031` | Centralisation des Récompenses de Combat et Refactoring du Gain d'Or (Combat Reward Centralization & Gold Drops) | ✅ | — | [ADR-031-centralisation-des-recompenses-de-combat-et-refact.md](../_adr/ADR-031-centralisation-des-recompenses-de-combat-et-refact.md) |
| `ADR-030` | Polissage de l'UI de Combat Responsive et Signalétique de Ciblage Localisée (Combat UI Polish & Sizing) | ✅ | — | [ADR-030-polissage-de-l-ui-de-combat-responsive-et-signalet.md](../_adr/ADR-030-polissage-de-l-ui-de-combat-responsive-et-signalet.md) |
| `ADR-029` | Génération Procédurale Avancée avec Quotas et Anti-Répétition (Advanced Map Generation Constraints) | ✅ | — | [ADR-029-generation-procedurale-avancee-avec-quotas-et-anti.md](../_adr/ADR-029-generation-procedurale-avancee-avec-quotas-et-anti.md) |
| `ADR-028` | Équilibrage Hybride de la Difficulté et Système de Réserve de Vagues (Hybrid Difficulty Balancing & Wave Reserve System) | ✅ | — | [ADR-028-equilibrage-hybride-de-la-difficulte-et-systeme-de.md](../_adr/ADR-028-equilibrage-hybride-de-la-difficulte-et-systeme-de.md) |
| `ADR-027` | Système de Coup Critique et Rééquilibrage du Scaling Ennemi (Critical Hit System & Enemy Scaling Tuning) | ✅ | — | [ADR-027-systeme-de-coup-critique-et-reequilibrage-du-scali.md](../_adr/ADR-027-systeme-de-coup-critique-et-reequilibrage-du-scali.md) |
| `ADR-026` | Isolation des Cartes de Classe "Unique" et Standardisation du Draft Initial (Class Card Isolation & Starter Draft Overhaul) | ✅ | — | [ADR-026-isolation-des-cartes-de-classe-unique-et-standardi.md](../_adr/ADR-026-isolation-des-cartes-de-classe-unique-et-standardi.md) |
| `ADR-025` | Système de Forge Découplé et Probabiliste | ✅ | — | [ADR-025-systeme-de-forge-decouple-et-probabiliste.md](../_adr/ADR-025-systeme-de-forge-decouple-et-probabiliste.md) |
| `ADR-024` | Progression par Rareté Dynamique et Fusion Interactive (3→1) | ✅ | — | [ADR-024-progression-par-rarete-dynamique-et-fusion-interac.md](../_adr/ADR-024-progression-par-rarete-dynamique-et-fusion-interac.md) |
| `ADR-023` | Système de Statuts Élémentaires Riches & Vulnérabilité Universelle | ✅ | — | [ADR-023-systeme-de-statuts-elementaires-riches-vulnerabili.md](../_adr/ADR-023-systeme-de-statuts-elementaires-riches-vulnerabili.md) |
| `ADR-022` | Ciblage Interactif en Deux Phases et Clarté des Info-bulles (Two-Phase Targeting & Canvas Cards Tooltips) | ✅ | — | [ADR-022-ciblage-interactif-en-deux-phases-et-clarte-des-in.md](../_adr/ADR-022-ciblage-interactif-en-deux-phases-et-clarte-des-in.md) |
| `ADR-021` | Stratégie de Responsivité Unifiée du Système de Tutoriel (Unified Tutorial Responsiveness Strategy) | ✅ | — | [ADR-021-strategie-de-responsivite-unifiee-du-systeme-de-tu.md](../_adr/ADR-021-strategie-de-responsivite-unifiee-du-systeme-de-tu.md) |
| `ADR-020` | Feedback de Focus de Récompenses (Hover & Selection Glow Visual Feedback in Draft Screen) | ✅ | — | [ADR-020-feedback-de-focus-de-recompenses.md](../_adr/ADR-020-feedback-de-focus-de-recompenses.md) |
| `ADR-019` | Système de Tutoriel Autonome Isolant la Boucle Principale (Standalone Tutorial System with State Isolation) | ✅ | — | [ADR-019-systeme-de-tutoriel-autonome-isolant-la-boucle-pri.md](../_adr/ADR-019-systeme-de-tutoriel-autonome-isolant-la-boucle-pri.md) |
| `ADR-018` | Rareté Mythique & Transition d'Alerte Séquentielle en Draft (Mythic Rarity & Two-Step Draft Transition) | ✅ | — | [ADR-018-rarete-mythique-transition-d-alerte-sequentielle-e.md](../_adr/ADR-018-rarete-mythique-transition-d-alerte-sequentielle-e.md) |
| `ADR-017` | Système Interactif de Révélation de Cartes par Rouleaux 3D (Staggered Draft Slots & Reels) | ✅ | — | [ADR-017-systeme-interactif-de-revelation-de-cartes-par-rou.md](../_adr/ADR-017-systeme-interactif-de-revelation-de-cartes-par-rou.md) |
| `ADR-016` | Système de Progression XP & Échelonnement Dynamique des Ennemis (XP Progression & Enemy Scaling) | ✅ | — | [ADR-016-systeme-de-progression-xp-echelonnement-dynamique.md](../_adr/ADR-016-systeme-de-progression-xp-echelonnement-dynamique.md) |
| `ADR-015` | Système de Carrousel de Récompense de Reliques (Interactive Relic Carousel Reward System) | ✅ | — | [ADR-015-systeme-de-carrousel-de-recompense-de-reliques.md](../_adr/ADR-015-systeme-de-carrousel-de-recompense-de-reliques.md) |
| `ADR-014` | Système de Résolution des Altérations Élémentaires (Burn, Freeze, Shock) | ✅ | — | [ADR-014-systeme-de-resolution-des-alterations-elementaires.md](../_adr/ADR-014-systeme-de-resolution-des-alterations-elementaires.md) |
| `ADR-013` | Système de Mort et de Stats Synchronisé Z-Sync (Z-Sync Death & Stats System) | ✅ | — | [ADR-013-systeme-de-mort-et-de-stats-synchronise-z-sync.md](../_adr/ADR-013-systeme-de-mort-et-de-stats-synchronise-z-sync.md) |
| `ADR-012` | Absence de Système Audio | ⚠️ | — | [ADR-012-absence-de-systeme-audio.md](../_adr/ADR-012-absence-de-systeme-audio.md) |
| `ADR-011` | Absence de Système de Persistance | ✅ | v3.2.0 | [ADR-011-absence-de-systeme-de-persistance.md](../_adr/ADR-011-absence-de-systeme-de-persistance.md) |
| `ADR-010` | Absence Délibérée de Routeur Centralisé | ⚠️ | — | [ADR-010-absence-deliberee-de-routeur-centralise.md](../_adr/ADR-010-absence-deliberee-de-routeur-centralise.md) |
| `ADR-009` | Graphe Acyclique Dirigé pour la Carte du Monde | ✅ | — | [ADR-009-graphe-acyclique-dirige-pour-la-carte-du-monde.md](../_adr/ADR-009-graphe-acyclique-dirige-pour-la-carte-du-monde.md) |
| `ADR-008` | Double-Buffering pour la Synchronisation Flame ⇄ Riverpod | ✅ | — | [ADR-008-double-buffering-pour-la-synchronisation-flame-riv.md](../_adr/ADR-008-double-buffering-pour-la-synchronisation-flame-riv.md) |
| `ADR-007` | Système de Merge Automatique (3→1) | ✅ | — | [ADR-007-systeme-de-merge-automatique.md](../_adr/ADR-007-systeme-de-merge-automatique.md) |
| `ADR-006` | Localisation Data-Driven (i18n) | ✅ | — | [ADR-006-localisation-data-driven.md](../_adr/ADR-006-localisation-data-driven.md) |
| `ADR-005` | Immuabilité d'État et Pattern `copyWith` | ✅ | — | [ADR-005-immuabilite-d-etat-et-pattern-copywith.md](../_adr/ADR-005-immuabilite-d-etat-et-pattern-copywith.md) |
| `ADR-004` | Unification du Rendu de Cartes (Widget `UiCard`) | ✅ | — | [ADR-004-unification-du-rendu-de-cartes.md](../_adr/ADR-004-unification-du-rendu-de-cartes.md) |
| `ADR-003` | Architecture 100% Data-Driven (JSON Assets) | ✅ | — | [ADR-003-architecture-100-data-driven.md](../_adr/ADR-003-architecture-100-data-driven.md) |
| `ADR-002` | Responsivité Dynamique par ScaleFactor | ✅ | — | [ADR-002-responsivite-dynamique-par-scalefactor.md](../_adr/ADR-002-responsivite-dynamique-par-scalefactor.md) |
| `ADR-001` | Séparation Triangulaire État/Rendu/UI (Riverpod ⇄ Flame ⇄ Flutter) | ✅ | — | [ADR-001-separation-triangulaire-etat-rendu-ui.md](../_adr/ADR-001-separation-triangulaire-etat-rendu-ui.md) |

---

## Renumérotations du 2026-08-03

Quatre numéros portaient chacun deux décisions distinctes. Arbitrage : les références entrantes l'emportent, puis l'ancienneté. Détail en `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.

| Ancien | Nouveau | Décision déplacée |
|:---:|:---:|:---|
| `ADR-068` | `ADR-074` | Forge de Fusion (v3.1.0) |
| `ADR-067` | `ADR-075` | Clés Dupliquées de Notification (v0.2.8) |
| `ADR-028` | `ADR-076` | Synchronisation du Bouton Fin de Tour |
| `ADR-069` | `ADR-077` | Clarté du Mana des Reliques (v3.0.1) |
