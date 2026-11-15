# P-53, les charges élémentaires, partie 1 — vérifications du plan

**Plan** : [`2026-11-15-p53-charges-elementaires-partie-1.md`](2026-11-15-p53-charges-elementaires-partie-1.md), depuis la [spec](../specs/2026-11-15-p53-charges-elementaires-design.md) §10, partie 1. **Vague 7**, `0.5.9`, branche `feat/v0.5.9-p53-charges-elementaires`. Base de tests : **1682** ; total attendu par le rédacteur : **1763** (+82, −1). Tâches à risque : aucune. Autonomie : `continu` (levée du 15/11). Tenu par l'orchestrateur (§3.4 du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)) : les options écartées, puis le journal des tours.

## 1. Les options écartées

### Arbitrages T (rédacteur, confirmés par l'orchestrateur le 16/11)

| Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---:|
| Q1 — la ligne du gel en attente déborde du panneau du héros (spec §5.1) | police réduite (`scaleDown`) ; panneau élargi de 250 à 300 ; texte raccourci (classe P, non retenu) | les lignes de charge sans colonne de durée, le libellé replié sur deux lignes, le texte inchangé | 6, 7 |
| Q2 — transmettre les coups un à un à Flame (spec §5.2, §10) | un journal des coups dans `CombatState` dès la partie 1 ; le journal et des chiffres par coup (classe P, et la partie 2 avalée) ; un flux d'événements du contrôleur vers Flame | pas dans ce plan : sans lecteur en partie 1 ; décidé au plan de la partie 2, avec son test | 5, 7 |
| Le type du catalogue | `List<ChargeData>` ; une `Map` brute | `ChargeCatalog`, vide par défaut, sur le modèle d'`EffectIconTable` | 5 |
| La source des charges | écrite en ligne, testée par un `loadGameDataRegistry` complet | constante publique `chargeSource` | 8 |
| Comment Flame sait qu'il y a une vague 1 | lire le compte rendu après une frame ; un rappel de plus | `startEnemyTurn()` rend `bool` | 5, 8 |
| Les porteurs de la vague suivante | un champ de `TurnPhaseManager` | `FireWaveReport.nextBearerIds`, dans l'état | 5 |
| Ce que Flame affiche d'une vague | le rappel rend le compte rendu | `StateSyncSystem` lit le compte rendu, pose la flamme existante | 5 |
| Une résolution du Feu compte-t-elle une rupture | jamais | oui, si au moins une tranche ; invisible aux valeurs livrées | 4 |
| Les jetons de `heroDescription` | paramètres des deux ruptures mélangés | `description` ← `rupture`, `heroDescription` ← `heroRupture` | 5 |
| `ChargeLine.value` | le bonus courant sous le seuil | pourcentage (`weakenDealt`), `points × bonusPerPoint` (`amplifyHits`), 0 sinon | 8 |
| Le helper « début de phase ennemie complet » | une méthode dans `lib/` ; `shipped_data.dart` | `test/unit/enemy_phase_helper.dart` | 5, 8 |
| L'écriture des stats du héros | `poseCharge` et `closePhase` sur `RunController` | `RunController.updateHeroStats(fn)` | 8 |
| « Retirer les charges » au debug | un bouton par porteur | un seul bouton | 8 |
| `skipEnemyPhase` et les fermetures | lui faire jouer les fermetures | aucune, documenté et testé | 8 |
| Le nom de l'état rompu dans l'indicateur Flame | l'indicateur lit `game` | `EnemyCard` passe un rappel `brokenNameOf` | 5, 8 |
| L'ordre des tâches | les contenus après le moteur | les contenus avant la pose | 8 |
| Entre Task 5 et Task 7 | le câblage Flame fondu dans Task 5 | `game_screen` enchaîne toute la phase ennemie jusqu'à Task 7 | 8 |
| Quand retirer `ProportionalStatus.freeze` et `statusFreezeHint` | tôt, avec des remplacements temporaires | avec leur dernier lecteur, le tutoriel (Task 10) | 8 |
| Le chiffre « 💥 » du cycle du tutoriel | `threshold × damagePerPoint` | `explosionDamage` (12 dans les deux cas aux valeurs livrées) | 8 |

### Question P ouverte, appliquée « (provisoire) »

| # | Question | Options | Recommandation |
|:---|:---|:---|:---|
| Q-P1 | Où le joueur lit-il `heroDescription` ? | (a) l'infobulle des contenus qui posent du Gel ; (b) l'entrée Gel de la galerie du tutoriel ; (c) la ligne du héros gelé, dans son panneau ; (d) nulle part en `0.5.9` | (d) |

## 2. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté et tranché |
|:---:|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet | 0 | 3 | 4 | 1 | à corriger — base 1682 et total 1763 confirmés, quatre-vingt-dix références contrôlées, aucun interdit. Constats confiés au rédacteur repris avec son contexte : (1) **moyen**, `EntityCategory.charge` casse `_registryIdsOf` (`entity_validator.dart:687-712`), `kCategoryIcons` (`editor_style.dart:107-118`, lu par `editor_toolbar.dart:42`) et `entity_descriptor_test.dart:302-405` ; (2) **moyen**, le test « Gel plafonné au restant » ne peut pas passer, la rupture remettant le Gel à 0 ; (3) la preuve « aucun test ne rend `UiCard` » est fausse (cinq tests d'écran) ; (4) `charge_symmetry_test` sans Feu ni Foudre sur un ennemi ; (5) trois données de test manquantes (PV, `might`, égalité d'`EntityStats`) ; (6) Q2 et la spec §10 ; (7) l'en-tête de `proportional_status.dart`. **Ajouté par l'orchestrateur**, relevé par les [maquettes de Q-P1](../../presentations/2026-11-16_charges_elementaires_q-p1_maquettes.pptx), p. 5 : (8) **moyen**, la ligne du gel repliée (Q1) porte le panneau du héros à 131 px, 11 px au-dessus de sa réserve de 120 | Q2 (constat 6) tranché par l'orchestrateur, T, filtres 7 puis 8 : le plan de la partie 1 ne porte pas le moyen ; si la partie 2 retient l'état, ce moyen et son test s'implémentent en complément de la partie 1, en tête de son plan, avant toute animation (spec §10) |
| 2 | différentiel | 0 | 2 | 5 | 2 | à corriger — les huit corrections du tour 1 confirmées (deux seuls lecteurs exhaustifs d'`EntityCategory` ; gabarit de sept clés ; le test du plafond vert sous §4.2 ; total 1765 recompté tâche par tâche ; M12 jouable). Constats confiés au rédacteur repris avec son contexte : (1) **moyen**, le test 6 de symétrie rouge — après la phase complète, chaque voisin perd 14 et n'a plus de Feu (vague 2 sous le seuil) ; (2) même calcul au test 4 de Task 5 ; (3) **moyen**, `Scrollbar(thumbVisibility: true)` sans `ScrollController` lève une `FlutterError` sous Windows, que `flutter test` (Android) ne voit pas ; (4) la borne de hauteur du panneau à nommer, le parent `Positioned` ne bornant pas ; (5) un sixième test d'écran rend `UiCard` (`sharpen_rune_dialog_test`) ; (6) « trois constantes » → « deux » ; (7) les clés de la charge construite du test du plafond ; (8), (9) rédaction | Aucun constat contesté |
| 3 | différentiel | 0 | 0 | 2 | 0 | **prêt** — les neuf corrections du tour 2 confirmées (vagues 1 et 2 recalculées, 12 puis 14 ; l'API des Tasks 5 et 7 concorde ; la borne de hauteur et la `Column` `min` ; six tests d'écran ; la charge construite passe A3 clé par clé) ; total 1765 recompté. Corrigés au passage par l'orchestrateur : (1) sous Windows, `MaterialScrollBehavior` ajouterait une seconde barre — `ScrollConfiguration(… scrollbars: false)` autour du `SingleChildScrollView`, et « une seule barre » au M12 recopié ; (2) A et C à 200 PV au test 4 de Task 5 | Aucun constat contesté |
