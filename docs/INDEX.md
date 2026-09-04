# 📇 Sommaire thématique de `docs/`

**Rôle** : retrouver, pour un sujet donné, **tous** les documents qui le concernent et dans quel
ordre ils ont été écrits. C'est un index de navigation — il ne contient **aucun fait**, uniquement
des liens. Si tu cherches une réponse plutôt qu'un document, la table de `CLAUDE.md` (§Documentation
Map) t'oriente plus vite.

**Dernière mise à jour** : 2026-08-25

---

## Comment lire ce document

Chaque sujet suit la même chaîne. Tous les documents n'en parcourent pas tous les maillons.

| Maillon | Où il vit | Ce que ça veut dire |
|:---|:---|:---|
| 🔍 **Exploration** | `possible_upgrades/` | Exploré, **pas tranché**. Aucune valeur d'engagement. |
| 📊 **Analyse** | `analysis_reports/` | Diagnostic vérifié contre le code, sans proposition. |
| 📐 **Conception** | `superpowers/specs/` | Design validé, **non implémenté**. |
| 🔨 **Plan** | `superpowers/plans/` · `implementation_plans/` | Découpage TDD prêt à exécuter. |
| ✅ **Livré** | `.obsidian_vault/_adr/` | La décision et ses preuves dans le code. |
| 🗄️ **Archive** | `archives/` · `*/_archives/` · `implementation_plans/done/` | **Lecture seule.** Valeur historique uniquement. |

> [!WARNING]
> Un document archivé ou ancien **n'est pas une source fiable sur l'état actuel du code**. La
> ROADMAP impose de re-vérifier toute fiche non re-mesurée depuis plus d'une semaine avant de
> l'ouvrir (`ROADMAP.md` §10.4). Les documents signalés ⚠️ ci-dessous ont des erreurs **connues et
> documentées** — ne pas s'y fier sans re-mesure.

---

## 1. Héros, classes & cartes

*Sujet actif. Programme **P-40 → P-44** de [`ROADMAP.md`](ROADMAP.md) §4.*

| | Document | Date |
|:---:|:---|:---|
| 📊 | [État des lieux — roster de héros & catalogue de cartes](analysis_reports/05082026_etat_des_lieux_heros_et_cartes_Opus5.md) | 05/08/2026 |
| 🔍 | [Brainstorm — évolution du roster & du catalogue](analysis_reports/05082026_brainstorm_heros_et_cartes_Opus5.md) | 05/08/2026 |
| 🔍 | [Idées améliorations classe et cartes](Idées%20améliorations%20classe%20et%20cartes.md) *(notes du propriétaire)* | 05/08/2026 |
| 📐 | [S2 — Identité de classe *(P-41)*](superpowers/specs/2026-08-07-s2-identite-de-classe-design.md) | 07/08/2026 |
| 📐 | [Réorganisation des données — un fichier par entité *(P-48)*](superpowers/specs/2026-09-04-reorganisation-donnees-un-fichier-par-entite-design.md) | 04/09/2026 |
| 🔨 | [P-48 — Plan des lots 1 et 2](superpowers/plans/2026-09-04-reorganisation-donnees-lots-1-2.md) *(livrés)* | 04/09/2026 |
| 🔨 | [P-48 — Plan du lot 3](superpowers/plans/2026-09-04-reorganisation-donnees-lot-3.md) *(la migration ; à exécuter)* | 04/09/2026 |
| 🗄️ | [Documentation des classes](archives/classes_documentation.md) · [Système de passifs](archives/système_de_passifs.md) · [Bilan changement compétences](archives/bilan_changement_competences.md) | — |
| 🗄️ | [Analyse d'équilibrage des cartes](archives/card_balancing_analysis_01-06-2026.md) | 01/06/2026 |
| 🗄️ | [Refactoring & équilibrage unifié des cartes](implementation_plans/done/unified_cards_refactoring_and_balancing.md) · [Refonte des raretés](implementation_plans/done/implementation_plan_cards_rarity_refactoring.md) · [Ajustements d'équilibrage](implementation_plans/done/22_card_balance_adjustments.md) | — |
| 🗄️ | [Profondeur des mécaniques de gameplay](implementation_plans/done/7_gameplay_mechanics_depth.md) · [Forge de fusion](archives/2026-07-01-task-forge-fusion.md) | — |

## 2. Pioche & deckbuilding

| | Document | Date |
|:---:|:---|:---|
| 🔍 | [Assainissement du système de pioche](possible_upgrades/_archives/31-07-2026_systeme_pioche_assainissement_Opus5.md) | 31/07/2026 |
| 📐 | [P-02 — Assainissement de la pioche](superpowers/specs/2026-08-04-p02-assainissement-pioche-design.md) | 04/08/2026 |
| 🔨 | [P-02 — Plan d'implémentation](superpowers/plans/2026-08-05-p02-assainissement-pioche.md) | 05/08/2026 |
| ✅ | [ADR-078](../.obsidian_vault/_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md) → [`ROADMAP.md` P-02](ROADMAP.md) | 06/08/2026 |
| 🗄️ | [Système de deckbuilding](implementation_plans/done/2_deckbuilding_system.md) | — |

## 3. Ennemis & combat

| | Document | Date |
|:---:|:---|:---|
| 🔍 | [Nouveaux ennemis par tier](possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md) | 27/07/2026 |
| 🔍 | [Roster tier-1 & mécaniques `onHitEffect`](possible_upgrades/28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md) *(→ P-05)* | 28/07/2026 |
| 🔍 | [Cadre d'ennemi — modulaire par tier](possible_upgrades/28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md) · [procédural](possible_upgrades/28-07-2026_cadre_ennemi_procedural_Sonnet5.md) *(→ P-08, deux options concurrentes)* | 28/07/2026 |
| 🗄️ | [Logs de maths de combat](archives/combat_maths_logs_03_06_2026.md) · [suite](archives/combat_maths_logs_05_06_2026-1.md) | 06/2026 |

## 4. Difficulté & scaling

| | Document | Date |
|:---:|:---|:---|
| 📐🔨 | [Scaling de difficulté en combat](superpowers/specs/2026-07-24-combat-difficulty-scaling-design.md) · [plan](superpowers/plans/2026-07-24-combat-difficulty-scaling.md) | 24/07/2026 |
| 📐🔨 | [Scaling du nombre d'ennemis](superpowers/specs/2026-07-25-enemy-count-scaling-design.md) · [plan](superpowers/plans/2026-07-25-enemy-count-scaling.md) | 25/07/2026 |
| 📐🔨 | [Accélération du scaling](superpowers/specs/2026-07-26-difficulty-scaling-acceleration-design.md) · [plan](superpowers/plans/2026-07-26-difficulty-scaling-acceleration.md) | 26/07/2026 |
| 🔨 | [Courbe de difficulté](implementation_plans/implementation_plan_difficulty_curve.md) | — |
| 🗄️ | [Ajustement de la courbe d'ennemis](implementation_plans/done/21_enemy_curve_adjustment.md) · [XP & scaling](implementation_plans/done/implementation_plan_xp_progressions_and_enemy_scaling.md) | — |

## 5. Équilibrage & économie

| | Document | Date |
|:---:|:---|:---|
| ⚠️🗄️ | [Analyse d'équilibrage du jeu](possible_upgrades/_archives/6_analyse_game_balance.md) — **source des deux constats faux de P-17** (`Attaque Rapide` gratuite, Paladin à 20 armure) | — |
| 🗄️ | [Système de récompenses & de luck](archives/reward_and_luck_system.md) · [plan](implementation_plans/done/23_reward_rarity_and_luck_system.md) | — |
| 🗄️ | [Refonte du système de mana](implementation_plans/done/19_mana_system_rework.md) · [Rééquilibrage de l'armure de base](implementation_plans/done/20_base_armor_rebalance.md) | — |

## 6. Carte du monde & progression de run

| | Document | Date |
|:---:|:---|:---|
| 🔍 | [Structure des nœuds & identité visuelle de la carte](possible_upgrades/11-08-2026_systeme_carte_visuel_et_noeuds_Opus5.md) *(→ P-31, croise P-12 et P-26)* | 11/08/2026 |
| 🔍 | [Biomes, finale de séquence & historique des runs](possible_upgrades/27-07-2026_biomes_finale_sequence_historique_runs_Sonnet5.md) *(→ P-10, P-11, P-12)* | 27/07/2026 |
| 📐🔨 | [Menu pause de l'écran carte](superpowers/specs/2026-07-24-map-screen-pause-menu-design.md) · [plan](superpowers/plans/2026-07-24-map-screen-pause-menu.md) | 24/07/2026 |
| 🗄️ | [Analyse des améliorations de la carte](possible_upgrades/_archives/5_analyse_world_map_improvements.md) · [Système de carte du monde](archives/world_map_system.md) | — |
| 🗄️ | [World map v2](implementation_plans/done/18_world_map_v2.md) · [Solidification](implementation_plans/done/9_world_map_solidification.md) · [Contenu & polish](implementation_plans/done/15_content_and_map_polish.md) | — |

## 7. Sauvegarde & persistance

| | Document | Date |
|:---:|:---|:---|
| 📐 | [Système de sauvegarde](superpowers/specs/2026-07-23-save-system-design.md) | 23/07/2026 |
| 🔨 | [Plan d'implémentation](superpowers/plans/2026-07-24-save-system.md) | 24/07/2026 |
| 🗄️ | [Stratégies de migration](archives/stratégies_migrations.md) | — |

## 8. Animations, juice & interface

| | Document | Date |
|:---:|:---|:---|
| 🔍 | [Audit animations & juice](possible_upgrades/25-07-2026_animations_juice_analysis_Opus5.md) *(→ P-06, P-07, P-29)* | 25/07/2026 |
| 🔍⚠️ | [Audit responsive — téléphone & tablette](possible_upgrades/05-08-2026_audit_responsive_mobile_tablette_Opus5.md) — **aucun chantier `P-xx` ne le porte à ce jour** : son verdict (portrait téléphone injouable) n'a pas de destination dans `ROADMAP.md`, à trancher | 05/08/2026 |
| ⚠️ | [Système d'animation des cartes](animations/card_animations_system.md) — **faux sur 4 points**, mise en conformité listée en `ROADMAP.md` §7 | — |
| 🔨 | [UI, UX, audio & juice](implementation_plans/8_ui_ux_audio_juice.md) | — |
| 🗄️ | [Analyse de responsivité UI](possible_upgrades/_archives/3_ui_responsiveness_analysis.md) · [Responsivité dynamique](possible_upgrades/_archives/4_dynamic_game_responsiveness_analysis.md) · [Parcours utilisateur](archives/user_flow_report.md) | — |
| 🗄️ | Lots UI livrés : [feedback](implementation_plans/done/3_feedback_ui_ux_system.md) · [refonte layout](implementation_plans/done/4_ui_refactoring_layout.md) · [corrections](implementation_plans/done/5_ui_corrections_post_refacto.md) · [responsivité](implementation_plans/done/6_ui_responsiveness.md) · [dynamique](implementation_plans/done/10_dynamic_game_responsiveness.md) · [ajustements](implementation_plans/done/11_ui_adjustments.md) · [scaling](implementation_plans/done/12_component_scaling_balance.md) · [polissage](implementation_plans/done/14_ui_polishing.md) · [corrections](implementation_plans/done/16_polishing_and_fixes.md) · [juice Balatro](implementation_plans/done/17_visual_juice_balatro.md) · [interaction cartes](implementation_plans/done/24_card_ui_interaction_overhaul.md) | — |

## 9. Tutoriel

| | Document | Date |
|:---:|:---|:---|
| 🗄️ | [Plan d'implémentation du tutoriel](implementation_plans/done/implementation_plan_tutorial_02-06-2026.md) | 02/06/2026 |
| 🗄️ | [Revue de responsivité du tutoriel](archives/tutorial_responsiveness_review.md) | — |
| 📐🔨 | [P-45 — Fidélité du tutoriel](superpowers/specs/2026-08-22-p45-fidelite-du-tutoriel-design.md) · [plan](superpowers/plans/2026-08-23-p45-fidelite-du-tutoriel.md) — **livré en `0.4.9`** : 50 écarts relevés entre `lib/tutorial/` et le jeu réel, parcours étendu de 13 à 15 étapes, règle d'autonomie amendée en « zéro provider d'*état* » | 22/08/2026 |

## 10. Infrastructure & CI/CD

| | Document | Date |
|:---:|:---|:---|
| 🔍⚠️ | [Pipeline CI/CD GitHub Actions](possible_upgrades/_archives/30-07-2026_ci_cd_pipeline_github_actions_Sonnet5.md) *(→ P-04)* — **périmé, ne pas implémenter depuis ce document** : la modification nginx qu'il prescrit casserait le site en production, et son job `build-web` produit une page blanche. Corrigé par la spec ci-dessous (§9). Reste valable pour le *raisonnement*. | 30/07/2026 |
| 📐🔨 | [P-04 — CI/CD GitHub Actions](superpowers/specs/2026-08-17-p04-ci-cd-github-actions-design.md) · [plan](superpowers/plans/2026-08-17-p04-ci-cd-github-actions.md) — **livré, en production depuis le 18/08** | 17/08/2026 |
| 📐🔨 | [P-04 lot 2 — Site vitrine & finalisation du CI/CD](superpowers/specs/2026-08-19-site-vitrine-et-finalisation-ci-cd-design.md) · [plan](superpowers/plans/2026-08-19-site-vitrine-et-finalisation-ci-cd.md) — smoke test, notification Discord, répertoire `site/` piloté par `versions.json` | 19/08/2026 |
| 🗄️ | [Tests manuels — phase 3](tests/phase_3_manual_tests.md) | — |

## 11. Dette technique & refactoring

| | Document | Date |
|:---:|:---|:---|
| ⚠️📊 | [Rapport de dette technique](analysis_reports/technical_debt_report_Opus4.6_13-06-2026.md) · [antérieur](analysis_reports/technical_debt_report_Opus4.6.md) — **six des huit fiches du Tier D qui en dérivent énonçaient des faits périmés** (re-vérification du 04/08) | 13/06/2026 |
| 📊 | Rapports Gemini 3.5 : [1](analysis_reports/dette_technique_rapport_Gemini3.5.md) · [2](analysis_reports/dette_technique_rapport_Gemini3.5_2.md) · [3](analysis_reports/dette_technique_rapport_Gemini3.5_3.md) · [4](analysis_reports/dette_technique_rapport_Gemini3.5_4.md) · [5](analysis_reports/dette_technique_rapport_Gemini3.5_5_07-06-2026.md) | 06/2026 |
| 🔨 | Refactoring par phases : [1](analysis_reports/26-05-2026_Refactoring_Phase1_implementation_plan.md) · [2](analysis_reports/26-05-2026_Refactoring_Phase2_implementation_plan.md) · [3](analysis_reports/26-05-2026_Refactoring_Phase3_implementation_plan.md) · [4](analysis_reports/26-05-2026_Refactoring_Phase4_implementation_plan.md) | 26/05/2026 |
| 🗄️ | [Dette non documentée](possible_upgrades/_archives/dette_technique_non_documentee_24-07-2026.md) · [Rapport technique](archives/technical_report.md) · [Système data-driven](implementation_plans/done/1_data_driven_system.md) | — |

## 12. Documentation & méthode

| | Document | Date |
|:---:|:---|:---|
| 📐🔨 | [Refonte de la documentation](superpowers/specs/2026-08-03-documentation-overhaul-design.md) · [plan](superpowers/plans/2026-08-03-documentation-overhaul.md) | 03/08/2026 |
| 📐 | [Mise à jour du README](superpowers/specs/2026-05-18-readme-update-design.md) | 18/05/2026 |
| ⚠️🗄️ | [Backlog & roadmap du 22/07](archives/backlog_and_roadmap_report_22072026.md) — **remplacé par [`ROADMAP.md`](ROADMAP.md)** | 22/07/2026 |
| 🗄️ | [README v1](old_Readmes/README_1.md) · [v2](old_Readmes/README_2.md) | — |

## 13. Transverse — leçons techniques

Notes de maîtrise, indépendantes de tout chantier.

- [Concepts](lessons/concept_mastery.md) · [Flame](lessons/flame_mastery.md) · [Riverpod](lessons/riverpod_mastery.md)

## 14. Audio

*Chantier **P-03** de [`ROADMAP.md`](ROADMAP.md) — clos.*

| | Document | Date |
|:---:|:---|:---|
| 🔍 | [Audit animations & juice](possible_upgrades/25-07-2026_animations_juice_analysis_Opus5.md) — recommandation n°1, à l'origine du chantier *(→ P-03)* | 25/07/2026 |
| 📐 | [P-03 — Système audio](superpowers/specs/2026-08-24-p03-systeme-audio-design.md) | 24/08/2026 |
| 🔨 | [P-03 — Plan d'implémentation](superpowers/plans/2026-08-24-p03-systeme-audio.md) | 24/08/2026 |
| ✅ | [ADR-082](../.obsidian_vault/_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md) → [`ROADMAP.md` P-03](ROADMAP.md) | 25/08/2026 |

## 15. Idées non encore rattachées à un sujet

| | Document |
|:---:|:---|
| 🔍 | [Idées d'améliorations](possible_upgrades/upgrade_ideas.md) — vivier courant |
| 🗄️ | [Idées regroupées](possible_upgrades/_archives/idees_regroupees.md) · [10/06](possible_upgrades/_archives/analysis_reports_idee_regroupee_ideas_10-06-2026.md) · [post-implémentations](possible_upgrades/_archives/analysis_reports_idee_regroupee_ideas_after_implementations.md) |
| 🗄️ | Prototypes d'évolutions : [analyse 1](possible_upgrades/_archives/1_analyse_techniques_evols.md) · [proto 1](possible_upgrades/_archives/1_proto_futures_evols.md) · [analyse 2](possible_upgrades/_archives/2_analyse_techniques_evols.md) · [proto 2](possible_upgrades/_archives/2_proto_futures_evols.md) |

---

## Ce qui n'est pas ici

Ce sommaire ne couvre que `docs/`. Trois autres emplacements portent des réponses, pas des documents :

| Question | Emplacement |
|:---|:---|
| Ce qui existe et ses métriques | `.obsidian_vault/_memory_bank/` |
| Pourquoi une décision a été prise | `.obsidian_vault/_adr/` |
| Une règle de jeu · un pattern d'architecture | `.obsidian_vault/_rules/` · `.obsidian_vault/_patterns/` |

`.obsidian_vault/_archive/` est en **lecture seule définitive**.

---

*Index de navigation. Il ne porte aucun fait et n'a donc jamais à être re-mesuré — seulement
complété quand un document est ajouté à `docs/`.*
