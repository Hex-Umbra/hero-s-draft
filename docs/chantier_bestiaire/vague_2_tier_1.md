# Vague 2 — `0.6.2` — le tier 1

> Fiche de vague du [chantier du bestiaire](README.md). Elle donne à l'orchestrateur la matière des gabarits de l'orchestration §4. Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Les chemins et les lignes de code sont **à revérifier, pas à croire** : ils datent du 22/11, sur `main` à `59bfb150`.

**Poids** : le plus lourd du chantier — une spec, trois parties, un plan par partie.

## Ce qu'elle livre

- **Le socle** : B1. Une intention ennemie s'écrit avec la liste `effects` des cartes ; les trois intentions d'aujourd'hui (attaque, Armure, Puissance) deviennent des écritures de cette liste, et les quatre ennemis (Slime, Gobelin, Squelette, Orc) migrent, **valeurs identiques**. La résolution d'un effet devient symétrique : elle part d'un lanceur, héros ou ennemi, vers sa cible. De B6, la part qui dépend de B1 : une pastille par effet de l'intention.
- **Les mécanismes du tier 1** ([catalogue](catalogue_mecanismes.md), #2 à #9) : le prix d'un effet, la demi-place, plusieurs coups, poser un statut ou une charge, le vol de vie, le larcin, l'esquive et les traits.
- **Sept ennemis neufs de tier 1**, branchés sur ces mécanismes :

| Ennemi | Mécanisme | Valeurs proposées *(à confirmer, prérequis 2)* |
|:---|:---|:---|
| Rat | demi-place (B28), plusieurs coups | 14 PV, 5 dégâts (28/07) ; le nombre de coups est à fixer |
| Slime de givre | pose du Gel | une charge par coup (B5) ; PV et dégâts à fixer |
| Slime de braise | pose du Feu | une charge par coup (B5) ; PV et dégâts à fixer |
| Slime d'orage | pose de la Foudre | une charge par coup (B5) ; PV et dégâts à fixer |
| Araignée venimeuse | pose du Poison | 16 PV, 2 dégâts, Poison 2 (28/07) |
| Corbeau charognard | vol de vie | 16 PV, 4 dégâts, 50 % des dégâts infligés (28/07) |
| Kobold éclaireur | esquive, en trait | 14 PV, 4 dégâts, 20 % par coup (B4) |

- **Le Gobelin vole** (B49) : il garde ses valeurs et gagne le larcin (5 % de l'or, proposé par le 28/07 pour le Bandit).

## Prérequis — avant l'ouverture

1. **Les sprites, tous validés** (B51) : Rat, Slime de givre, Slime de braise, Slime d'orage, Araignée venimeuse, Corbeau charognard, Kobold éclaireur, **et le Slime et le Gobelin redessinés** (B52) — neuf, par `/workflow-creature` (`art_src/creatures/<famille>/tier_1/`).
2. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient — elles sont développées, chiffres du jeu à l'appui et une recommandation par question, dans le [deck de la vague 2](https://claude.ai/artifact/88qAGkoUHeX1Yi1YqzFSZK) (22/11) :
   - les valeurs des sept ennemis et du larcin du Gobelin (table ci-dessus) ;
   - **B8** : où se lit l'esquive — recommandation du cadrage : un indicateur dans la languette de gauche, le pourcentage à la place de la durée, et un texte flottant « Esquive » ;
   - **le « +1 » de B6** : une attaque qui empoisonne porte déjà deux pastilles ; deux pastilles puis un compteur, ou une pastille puis un compteur ;
   - **le larcin** : combien, comment il se voit, et si l'or volé est rendu quand on tue le voleur ;
   - **le prix d'un effet** : il change le nombre d'ennemis d'un combat ; proposition du 28/07 : +6 par ennemi qui porte un effet, l'esquive × 0,3.

## Porte d'entrée

La vague 1 fusionnée dans `main` par la PR #57 (commit de fusion `32e2ad46`) et taguée `v0.6.1` le 22/11 ; la porte vérifie par `gh` que la CI de `main` et le run `release.yml` du tag sont verts, puis passe la vague 1 à « close » au journal ([README](README.md) §4) et dans la mémoire. La branche part de `main`. Les trois écarts de la vague 1 (cadrage §4) ne s'appliquent plus.

## Fichiers

`p05-bestiaire-tier-1` pour la spec et le plan ; `bestiaire-vague-2` pour le compte rendu et les tests manuels.

## À lire

- **Les intentions** : `lib/models/enemy_intent.dart`, `lib/models/enemy_instance.dart` (`effectiveIntent`, l'échelle d'apparition par `baseDamage`), `lib/models/data/enemy_data.dart`, les quatre `assets/data/enemies/*/enemy.json`.
- **Les effets** : `lib/models/data/card_data.dart` (le modèle d'un effet, sa cible, `hits`) ; `lib/game/services/effect_resolver.dart` et `lib/game/services/effects/` (les stratégies, écrites pour le héros : elles lisent `RunController` et la cible d'une carte ; le vol de vie y est déjà, statut et rune) ; `lib/game/services/damage_pipeline.dart`, où l'esquive prend sa place avant le calcul.
- **Le tour ennemi** : `TurnPhaseManager.resolveEnemyIntent` (`lib/game/controllers/combat/turn_phase_manager.dart`), `status_effect_processor.dart`, `lib/game/systems/charge_rules.dart`, `combat_controller.dart` (les `EntityStats` d'un ennemi, semées depuis sa donnée).
- **La composition** : `lib/game/systems/encounter_system.dart` (le budget, `calculateCombatRating`, `generateEnemiesForLevel` — le nombre d'ennemis y est un entier), `lib/game/systems/layout_system.dart` (`repositionEnemies`).
- **L'or** : `lib/game/controllers/run/gold_manager.dart`.
- **Les lecteurs d'une intention** : `intent_pips.dart`, `enemy_sheet_view.dart`, `enemy_intents_panel.dart`, `lib/models/data/model_extensions.dart`, `lib/game/systems/status_readout.dart`, le tutoriel des intentions (`lib/tutorial/widgets/tutorial_enemy_intents_widget.dart`).
- **Les outils** : l'onglet Ennemi de l'éditeur de contenu (`lib/services/content_editor/entity_descriptor.dart`), l'onglet Combat du menu de debug (`lib/ui/widgets/debug/tabs/debug_combat_tab.dart`).
- **Le sprite** : `art_src/docs/workflow_creature.md` (le format, 128 × 192 sur fond transparent).
- **La doc** : le cadrage §1 à §3, le [catalogue](catalogue_mecanismes.md) ; ADR-061 (les stratégies d'effet), ADR-121 ; les fiches [`_rules/02-5`](../../.obsidian_vault/_rules/02-5-bestiaire.md), [`_rules/03-3`](../../.obsidian_vault/_rules/03-3-pipeline-de-degats-centralise.md), [`_patterns/03-4`](../../.obsidian_vault/_patterns/03-4-effectresolver-resolution-d-effets-de-cartes.md).

## La spec doit fixer

1. **Le format d'une intention** : sa liste d'effets, ce qu'elle garde à côté (le nom affiché, aujourd'hui tiré de la valeur par les paliers 6, 12 et 20, écrits trois fois — à réunir ici), l'ordre du cycle, inchangé. **Le format se choisit en connaissant ses suites** : les mécanismes des vagues 3 et 4 (catalogue #11 à #16 — invocation, aura, viser un allié, perce-armure, phases, choix d'intention) et P-09, P-14, P-44 lot 2 devront s'y écrire sans reprise.
2. **L'échelle d'apparition** : ce que deviennent `baseDamage` et le multiplicateur de `effectiveIntent`, et sur quels effets ils portent.
3. **La résolution symétrique** : le lanceur, la cible d'un effet d'ennemi (le héros, soi), les effets qu'un ennemi ne peut pas porter (piocher, gagner du Mana) et leur refus au chargement ; ce que le chemin du héros garde à l'identique.
4. **La migration** des quatre ennemis, et la preuve par test que les dégâts, l'Armure et la Puissance d'une phase ennemie ne changent pas.
5. **Les mécanismes du tier 1**, un par un :
   - **la demi-place** : la place comme donnée de l'ennemi, la composition qui n'est plus un entier, le plateau à six cartes au plus (B30), le Rat à 80 % (B17), la réserve au-delà du plafond (B19) ;
   - **plusieurs coups** : chaque coup résolu à part, avec ce qu'il déclenche ;
   - **poser un statut ou une charge** sur le héros, par les règles existantes ;
   - **le vol de vie** d'un ennemi ;
   - **le larcin** : où l'or part, ce qui le rend, ce qui le montre ;
   - **l'esquive et les traits** : l'esquive dans le calcul partagé (B4), le trait comme effet permanent porté dès l'entrée en combat. **Le nom est à choisir** : `TraitSystem` désigne déjà le répartiteur des passifs du héros (`lib/game/systems/trait_system.dart`).
6. **Le prix d'un effet** dans le budget d'un combat, selon la réponse du propriétaire.
7. **Les sept ennemis et le Gobelin** : leurs fichiers, leurs dossiers (`dart run tool/sync_assets.dart`), leur tier, leurs valeurs, leurs textes en français et en anglais.
8. **Ce que le joueur lit** : les pastilles (une par effet, à la couleur de son statut, la flèche violette de la Puissance, B31, et le « +1 »), la phrase d'une intention à plusieurs effets dans l'infobulle et dans la fiche, en français et en anglais ; l'esquive (B8) et le larcin à l'écran.
9. **Les outils** : l'éditeur de contenu, qui écrit le nouveau format ; ce que le menu de debug doit permettre pour tester chaque mécanisme en jeu.
10. **Les tests** — les calculs, les données et les contrôleurs seulement (ADR-113) ; tout ce qui se voit va au fichier de tests manuels.

## Découpage proposé

1. **Le socle** — format, résolution symétrique, migration, pastilles, éditeur. **Invariant** : à la fin de la partie 1, aucun ennemi ne fait rien de neuf ; le jeu est identique, et les tests le prouvent.
2. **Les mécanismes du tier 1 et le prix d'un effet**, gardés par des tests sur des ennemis de test.
3. **Les ennemis** — les sept fichiers, les sprites, le larcin du Gobelin, les textes.

Chaque plan s'écrit sur le code que la partie précédente a laissé (orchestration §3.4).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste — le format, la symétrie, la migration, la demi-place dans la composition — est de classe T. Une question P neuve s'écrit et se signale, sans se trancher.

## Ne pas absorber

Aucun mécanisme des vagues 3 et suivantes (catalogue #11 à #17) : ni Rat alpha, ni invocation, ni aura, ni meute, ni perce-armure, ni phases ; ni cadre de tier, ni fond (vague 5) ; ni épines, étourdissement ou malédictions (P-44 lot 2), ni affixes d'élite (P-14), ni intentions cachées (P-19) ; aucun ennemi hors de la table ; **aucun équilibrage des ennemis existants**, hors du larcin du Gobelin.

## Tâches à risque

- **La résolution symétrique.** Le chemin des cartes du héros — runes, reliques, passifs, Puissance, critique, charges, vol de vie — ne doit pas changer d'un point.
- **La demi-place.** Elle change la composition d'un combat et le plateau : la sélection par budget, le placement, la réserve.

## Pour `memory-bank-sync`

Un ADR pour le langage des intentions, qui complète ADR-061, et un pour les mécanismes du tier 1 ; les fiches `_rules/02-5`, `_rules/03-3` et `_patterns/03-4` que le diff périme ; dans `docs/ROADMAP.md`, la ligne P-05 et les mentions d'`onHitEffect` (schéma, Gantt, P-14, P-15) que B1 remplace.

## Ce que le joueur voit

Sept ennemis neufs dès le premier acte : des rats qui viennent par deux et mordent plusieurs fois, trois slimes qui gèlent, brûlent ou électrisent, une araignée qui empoisonne, un corbeau qui se soigne en frappant, un kobold qui esquive ; un gobelin qui vole de l'or. Les ennemis d'aujourd'hui frappent comme avant. Les sprites neufs, Slime et Gobelin compris, s'affichent dans la carte actuelle, sans cadre de tier (vague 5).
