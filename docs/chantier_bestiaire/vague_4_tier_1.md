# Vague 4 — `0.6.4` — le tier 1

> Fiche de vague du [chantier du bestiaire](README.md). Elle donne à l'orchestrateur la matière des gabarits de l'orchestration §4. Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Les chemins et les lignes de code sont **à revérifier, pas à croire** : ils datent du 22/11, sur `main` à `59bfb150`. Écrite le 22/11 avec le langage des intentions ; le 23/11, celui-ci est parti dans sa propre vague, la [vague 3](vague_3_socle.md) (B62) : **la spec de la vague 3 aura fixé le format des intentions** sur lequel celle-ci s'écrit — relis-la avant tout.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **Les mécanismes du tier 1** ([catalogue](catalogue_mecanismes.md), #2, #3, #5 à #9 et #20) : le prix d'un effet, la demi-place, poser un statut ou une charge, le vol de vie, le larcin, l'esquive, les traits et **la riposte** (B71, ajoutée le 23/11). « Plusieurs coups » est parti avec le tier 2 (B54).
- **Sept ennemis neufs de tier 1**, branchés sur ces mécanismes — leurs lignes complètes sont au [catalogue des ennemis](catalogue_ennemis.md), §2 :

| Ennemi | Mécanisme | Valeurs (B53) |
|:---|:---|:---|
| Rat | demi-place (B28) | 8 PV, 3 dégâts, un coup (B54) |
| Slime de givre | pose du Gel | 18 PV, 3 dégâts, 2 Gel par coup |
| Slime de braise | pose du Feu | 18 PV, 3 dégâts, 1 Feu par coup |
| Slime d'orage | pose de la Foudre | 18 PV, 4 dégâts, 1 Foudre par coup |
| Araignée venimeuse | pose du Poison | 16 PV, 2 dégâts, Poison 1 par morsure |
| Corbeau charognard | vol de vie | 16 PV, 4 dégâts, 50 % des dégâts portés aux PV |
| Kobold éclaireur | esquive, en trait | 14 PV, 4 dégâts, 20 % par coup (B4) |

- **La riposte des slimes élémentaires** (B71) : quand le héros attaque un Slime de givre, il a 50 % de chance de prendre 1 Gel ; de même 1 Feu en attaquant un Slime de braise, 1 Foudre en attaquant un Slime d'orage. Elle fonctionne comme l'esquive : un trait de l'ennemi, et un jet.
- **Le Gobelin vole** (B49) : il garde ses valeurs et gagne le larcin — 5 or par coup, perdu, montré par un texte flottant et une languette de butin (B57).

## Prérequis — avant l'ouverture

1. **Les sprites, tous livrés** (B51, B65) : les neuf lignes du tier 1 du [catalogue des ennemis](catalogue_ennemis.md) à ✅ — Rat, Slime de givre, Slime de braise, Slime d'orage, Araignée venimeuse, Corbeau charognard, Kobold éclaireur, **et le Slime et le Gobelin redessinés** (B52). Ils se produisent par `/workflow-creature` (`art_src/sprites/<famille>/tier_1/`) et **se valident sur le cadre du tier 1 et les fonds de la vague 2** (B61).
2. ✅ **Les réponses du propriétaire** — données le 22/11 sur le [deck du tier 1](https://claude.ai/artifact/88qAGkoUHeX1Yi1YqzFSZK) : les valeurs (B53, B54), l'esquive (B55), le « +1 » reporté (B56), le larcin (B57), le prix d'un effet (B58).
3. ✅ **Le Rat dans un cadre** — tranché le 23/11 (B72) : aucune mise à l'échelle. Le Rat garde un cadre de tier 1 entier, son sprite est dessiné réduit dans son image, et sa demi-place se lit par un écart plus serré.
4. **Ce que B53 ne fixe pas** : le critique, l'XP et l'or des sept ennemis neufs, et les familles du Corbeau et du Kobold ([catalogue des ennemis](catalogue_ennemis.md), §8).
5. **Les questions de la riposte** (B71, classe P) :
   - un jet par coup, comme l'esquive, ou un jet par carte jouée ;
   - ce qui compte comme une attaque du héros : toute carte qui inflige des dégâts à ce slime, ou aussi une carte qui ne lui pose qu'un statut ;
   - la riposte s'ajoute-t-elle à ce que le slime pose en attaquant (B53 : 2 Gel, 1 Feu, 1 Foudre par coup), ou le remplace-t-elle ;
   - un coup qui tue le slime, ou qu'un ennemi esquive, déclenche-t-il la riposte ;
   - ce que le joueur lit : une languette à gauche du slime, le pourcentage à la place de la durée, comme l'esquive (B55), et un texte flottant quand la riposte part ;
   - un héros gelé au seuil par une riposte, en plein tour : ce que devient la suite de son tour.

**L'échelle des doses selon l'acte n'est plus un prérequis** : la riposte est la première réponse à la faiblesse des doses posées par coup (B71), et le reste se traite au cadrage de la difficulté (B64). La spec applique B53 et B71 telles quelles.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 3 : fusionnée, `v0.6.3` posé sur un commit de `main`, CI et release vertes ; la vague 3 passe à « close ».

## Fichiers

`p05-bestiaire-tier-1` pour la spec et le plan ; `bestiaire-vague-4` pour le compte rendu et les tests manuels.

## À lire

- **Le socle** : le format des intentions et la résolution symétrique tels que la vague 3 les a livrés (sa spec, son ADR).
- **Les effets** : `lib/game/services/effect_resolver.dart` et `lib/game/services/effects/` (le vol de vie y est déjà, statut et rune) ; `lib/game/services/damage_pipeline.dart`, où l'esquive prend sa place avant le calcul.
- **Le tour ennemi** : `TurnPhaseManager` (`lib/game/controllers/combat/turn_phase_manager.dart`), `status_effect_processor.dart`, `lib/game/systems/charge_rules.dart`, `combat_controller.dart`.
- **La composition** : `lib/game/systems/encounter_system.dart` (le budget, `calculateCombatRating`, `generateEnemiesForLevel` — le nombre d'ennemis y est un entier), `lib/game/systems/layout_system.dart` (`repositionEnemies`, refait par la vague 2 sur des largeurs par tier : lis sa spec et son ADR).
- **L'or** : il vit dans `lib/game/controllers/inventory_controller.dart`, et non dans `run/gold_manager.dart`.
- **Les lecteurs d'une intention** : `intent_pips.dart`, `enemy_sheet_view.dart`, `enemy_intents_panel.dart`, `lib/game/systems/status_readout.dart`.
- **Les outils** : l'onglet Ennemi de l'éditeur de contenu (`lib/services/content_editor/entity_descriptor.dart`), l'onglet Combat du menu de debug (`lib/ui/widgets/debug/tabs/debug_combat_tab.dart`).
- **Le sprite** : `art_src/docs/workflow_creature.md` (le format, 128 × 192 sur fond transparent).
- **La doc** : le cadrage §1 à §3, le [catalogue des mécanismes](catalogue_mecanismes.md), le [catalogue des ennemis](catalogue_ennemis.md) ; les fiches [`_rules/02-5`](../../.obsidian_vault/_rules/02-5-bestiaire.md) et [`_rules/03-3`](../../.obsidian_vault/_rules/03-3-pipeline-de-degats-centralise.md).

## La spec doit fixer

1. **Les mécanismes du tier 1**, un par un :
   - **la demi-place** : la place comme donnée de l'ennemi, la composition qui n'est plus un entier, le plateau à six cartes au plus (B30), le Rat dans un cadre de tier 1 entier et l'écart serré entre deux rats, sur le placement de la vague 2 (B72), la réserve au-delà du plafond (B19) ;
   - **poser un statut ou une charge** sur le héros, par les règles existantes, aux doses de B53 ;
   - **la riposte** (B71) : un trait qui porte une chance et une liste d'effets, résolue sur le héros quand il attaque son porteur — une charge pour les slimes ; une contre-attaque en dégâts s'écrit dans la même liste, pour l'ennemi qui la portera. Les réponses du prérequis 5 en fixent le jet, le déclencheur et la lecture ;
   - **le vol de vie** d'un ennemi ;
   - **le larcin** (B57) : l'or retiré, plafonné à ce que le héros a et perdu ; la languette de butin et le texte flottant ;
   - **l'esquive et les traits** : l'esquive dans le calcul partagé (B4) et sa languette (B55), le trait comme effet permanent porté dès l'entrée en combat. **Le nom est à choisir** : `TraitSystem` désigne déjà le répartiteur des passifs du héros (`lib/game/systems/trait_system.dart`).
2. **Le prix d'un effet** dans le budget d'un combat : +6 par ennemi qui en porte un (B58, qui se réexaminera avec la difficulté, B64) ; et le prix d'un ennemi qui compte sa place, pour le Rat (B54).
3. **Les sept ennemis et le Gobelin** : leurs fichiers, leurs dossiers (`dart run tool/sync_assets.dart`), leur tier, leurs valeurs, leurs textes en français et en anglais.
4. **Ce que le joueur lit** : les pastilles de statut (à la couleur de leur statut, la flèche violette de la Puissance, B31 ; deux au plus au tier 1, le « +1 » étant reporté, B56), la phrase d'une intention à plusieurs effets dans l'infobulle et dans la fiche, en français et en anglais ; l'esquive (B55) et le larcin (B57) à l'écran ; l'icône du larcin et sa couleur.
5. **Les outils** : ce que le menu de debug doit permettre pour tester chaque mécanisme en jeu.
6. **Les tests** — les calculs, les données et les contrôleurs seulement (ADR-113) ; tout ce qui se voit va au fichier de tests manuels.

## Découpage proposé

1. **Les mécanismes du tier 1 et le prix d'un effet**, gardés par des tests sur des ennemis de test.
2. **Les ennemis** — les sept fichiers, les sprites, le larcin du Gobelin, les textes.

Le second plan s'écrit sur le code que la première partie a laissé (orchestration §3.4).

## Pièges relevés à l'audit du 23/11

Lus dans le code, sans exécution : à revérifier.

- **L'esquive et les effets d'un même coup** : les effets se résolvent aujourd'hui indépendamment les uns des autres. « Un coup esquivé ne pose ni charge ni statut » (B4) demande un lien entre l'effet de dégâts et ceux qui le suivent.
- **Le vol de vie** : celui du héros compte les dégâts avant l'armure ; B53 dit « portés aux PV » pour le Corbeau. Ce n'est pas la même règle.
- **Le larcin à l'écran** : le rendu du combat ne suit pas l'inventaire ; le « −5 or » demande un chemin neuf.
- **La demi-place** : le plafond d'ennemis est un entier, et le plateau à cinq cartes est écrit en dur dans le contrôleur du combat.
- **La riposte se résout pendant le tour du héros**, au milieu de la résolution de sa carte : c'est le premier effet d'ennemi qui part hors de la phase ennemie. Elle touche le chemin des cartes du héros, que la vague 3 doit avoir laissé identique.

## À arbitrer

Les questions P ont leur réponse dans le cadrage, B53 à B58 et B72, et aux prérequis 4 et 5. Le reste — la demi-place dans la composition, l'esquive dans le calcul — est de classe T. Une question P neuve s'écrit et se signale, sans se trancher.

## Ne pas absorber

Aucun mécanisme des vagues suivantes (catalogue #4 et #10 à #19) : ni plusieurs coups (B54), ni Rat alpha, ni invocation, ni aura, ni meute, ni perce-armure, ni phases ; aucune reprise du format des intentions (vague 3), des cadres, des fonds ni du placement (vague 2), hors de ce que la demi-place y pose ; ni épines, étourdissement ou malédictions (P-44 lot 2), ni affixes d'élite (P-14), ni intentions cachées (P-19), ni la fuite du voleur ; ni le « +1 » (B56) ; aucun ennemi hors de la table ; **aucun équilibrage des ennemis existants**, hors du larcin du Gobelin ; ni la refonte de la difficulté (B64).

## Tâches à risque

- **La demi-place.** Elle change la composition d'un combat et le plateau : la sélection par budget, le placement, la réserve.
- **La riposte.** Un effet d'ennemi résolu pendant le tour du héros : l'ordre avec les effets de la carte jouée, avec les runes, les reliques et les passifs, et avec la mort de l'ennemi.

## Pour `memory-bank-sync`

Un ADR pour les mécanismes du tier 1 ; les fiches `_rules/02-5` et `_rules/03-3` que le diff périme ; la ligne P-05 de `docs/ROADMAP.md` ; le [catalogue des ennemis](catalogue_ennemis.md), dont les lignes du tier 1 renvoient désormais à leurs données.

## Ce que le joueur voit

Sept ennemis neufs dès le premier acte : des rats qui viennent par deux, trois slimes qui gèlent, brûlent ou électrisent — y compris, une fois sur deux, celui qui les frappe —, une araignée qui empoisonne, un corbeau qui se soigne en frappant, un kobold qui esquive ; un gobelin qui vole de l'or. Chacun dans son cadre de tier 1, le Slime et le Gobelin redessinés.
