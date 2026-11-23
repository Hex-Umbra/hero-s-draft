# Vague 3 — `0.6.3` — le socle : le langage des intentions

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Née le 23/11 de la coupe de la fiche du tier 1 (B62) : le langage des intentions se livre seul, avant tout ennemi neuf. Les chemins et les lignes de code sont **à revérifier, pas à croire** : ils datent du 22/11, sur `main` à `59bfb150`.

**Poids** : lourd — une spec, un plan. Aucun ennemi neuf, aucun mécanisme neuf, aucun sprite.

## Ce qu'elle livre

- **Le langage des intentions** (B1, [catalogue](catalogue_mecanismes.md) #1) : une intention ennemie s'écrit avec la liste `effects` des cartes. Les trois intentions d'aujourd'hui (attaque, Armure, Puissance) deviennent des écritures de cette liste, et les quatre ennemis (Slime, Gobelin, Squelette, Orc) migrent, **valeurs identiques**.
- **La résolution symétrique** : un effet part d'un lanceur, héros ou ennemi, vers sa cible.
- **De B6, la part qui dépend de B1** : une pastille par effet de l'intention.
- **L'invariant** : à la fin de la vague, aucun ennemi ne fait rien de neuf. Le jeu est identique, et les tests le prouvent.

## Prérequis — avant l'ouverture

**Aucun sprite, aucune question du propriétaire** : c'est ce qui permet à cette vague de se coder pendant que les sprites du tier 1 se produisent ([catalogue des ennemis](catalogue_ennemis.md)).

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 2 : fusionnée, `v0.6.2` posé sur un commit de `main`, CI et release vertes ; la vague 2 passe à « close ».

## Fichiers

`p05-langage-des-intentions` pour la spec et le plan ; `bestiaire-vague-3` pour le compte rendu et les tests manuels.

## À lire

- **Les intentions** : `lib/models/enemy_intent.dart`, `lib/models/enemy_instance.dart` (`effectiveIntent`, l'échelle d'apparition par `baseDamage`), `lib/models/data/enemy_data.dart`, les quatre `assets/data/enemies/*/enemy.json`.
- **Les effets** : `lib/models/data/card_data.dart` (le modèle d'un effet, sa cible, `hits`) ; `lib/game/services/effect_resolver.dart` et `lib/game/services/effects/` (les stratégies, écrites pour le héros : elles lisent `RunController` et la cible d'une carte) ; `lib/game/services/damage_pipeline.dart`.
- **Le tour ennemi** : `TurnPhaseManager.resolveEnemyIntent` (`lib/game/controllers/combat/turn_phase_manager.dart`), `status_effect_processor.dart`, `lib/game/systems/charge_rules.dart`, `combat_controller.dart` (les `EntityStats` d'un ennemi, semées depuis sa donnée), et la phase ennemie de `lib/game/heros_draft_game.dart`.
- **Les lecteurs d'une intention** : `intent_pips.dart`, `enemy_sheet_view.dart`, `enemy_intents_panel.dart`, `lib/models/data/model_extensions.dart`, `lib/game/systems/status_readout.dart`, le tutoriel des intentions (`lib/tutorial/widgets/tutorial_enemy_intents_widget.dart`).
- **Les outils** : l'onglet Ennemi de l'éditeur de contenu (`lib/services/content_editor/entity_descriptor.dart`).
- **La doc** : le cadrage §1 à §3, le [catalogue des mécanismes](catalogue_mecanismes.md) ; ADR-061 (les stratégies d'effet), ADR-121 ; les fiches [`_rules/02-5`](../../.obsidian_vault/_rules/02-5-bestiaire.md), [`_rules/03-3`](../../.obsidian_vault/_rules/03-3-pipeline-de-degats-centralise.md), [`_patterns/03-4`](../../.obsidian_vault/_patterns/03-4-effectresolver-resolution-d-effets-de-cartes.md).

## La spec doit fixer

1. **Le format d'une intention** : sa liste d'effets, ce qu'elle garde à côté (le nom affiché, aujourd'hui tiré de la valeur par les paliers 6, 12 et 20, écrits trois fois — à réunir ici), l'ordre du cycle, inchangé. **Le format se choisit en connaissant ses suites** : les mécanismes du [catalogue](catalogue_mecanismes.md) #2 à #20 et P-09, P-14, P-44 lot 2 devront s'y écrire — dont la riposte (B71), une liste d'effets qu'un ennemi résout pendant le tour du héros. Plusieurs de ces suites attendent encore une réponse du propriétaire — l'invocation annoncée un tour avant, ce qu'une phase et une intention tirée au hasard annoncent, la forme de la marque : **la spec écrit ce qu'elle en suppose**, pour que la vague qui les construit sache ce qui tiendra et ce qui se reprendra.
2. **L'échelle d'apparition** : ce que deviennent `baseDamage` et le multiplicateur de `effectiveIntent`, et sur quels effets ils portent. Pour les trois intentions d'aujourd'hui, c'est de classe T : le jeu reste identique. **L'échelle des doses d'un statut ou d'une charge posés par un ennemi est au propriétaire** : sa première réponse est la riposte (B71, vague 4), le reste se traite au cadrage de la difficulté (B64). La spec ne la tranche pas.
3. **La résolution symétrique** : le lanceur, la cible d'un effet d'ennemi (le héros, soi), les effets qu'un ennemi ne peut pas porter (piocher, gagner du Mana) et leur refus au chargement ; ce que le chemin du héros garde à l'identique.
4. **La séquence du tour ennemi** : sortie du rendu vers le contrôleur, pour que l'ordre des actions ennemies se teste (voir « Pièges »).
5. **La migration** des quatre ennemis, et la preuve par test que les dégâts, l'Armure et la Puissance d'une phase ennemie ne changent pas.
6. **Ce que le joueur lit** : les pastilles, une par effet ; la phrase d'une intention dans l'infobulle et dans la fiche, en français et en anglais — pour les intentions d'aujourd'hui, à l'identique.
7. **Les outils** : l'éditeur de contenu, qui écrit le nouveau format.
8. **Les tests** — les calculs, les données et les contrôleurs seulement (ADR-113) ; tout ce qui se voit va au fichier de tests manuels.

## Pièges relevés à l'audit du 23/11

Lus dans le code, sans exécution : à revérifier.

- **Le tour ennemi est orchestré dans le rendu**, hors des tests : la phase ennemie de `lib/game/heros_draft_game.dart` enchaîne les actions et choisit l'animation sur le type de l'intention. Un langage neuf posé là-dessus ne serait gardé par aucun test.
- **La cible se lit sur la carte, pas sur l'effet** : un effet n'a pas de champ de cible. Une intention « dégâts au héros, soin sur soi » ne s'écrit pas aujourd'hui.
- **Les couches pures sont déjà symétriques** : le calcul des dégâts prend un attaquant et un défenseur et sert déjà au tour ennemi ; les charges et les gains de stats prennent un porteur. B1 se lit donc de deux façons — un interprète côté ennemi posé sur ces couches, ou un résolveur unique à lanceur, qui réécrit les stratégies du héros. La spec choisit et dit pourquoi ; la seconde lecture touche le chemin le plus sensible du jeu.
- **La surface de la migration** : l'API d'intention se lit dans une quinzaine de fichiers de `lib/` et autant de fichiers de test.

## À arbitrer

Tout est de classe T, sauf ce que le point 2 réserve au propriétaire. Une question P neuve s'écrit et se signale, sans se trancher.

## Ne pas absorber

Aucun mécanisme du catalogue hors le #1 : ni le prix d'un effet, ni la demi-place, ni la pose d'un statut par un ennemi, ni le vol de vie, le larcin, l'esquive, les traits ou la riposte (vague 4) ; aucun ennemi neuf ; aucune reprise des cadres, des fonds ni du placement de la vague 2 ; **aucun équilibrage**.

## Tâche à risque

**La résolution symétrique.** Le chemin des cartes du héros — runes, reliques, passifs, Puissance, critique, charges, vol de vie — ne doit pas changer d'un point.

## Pour `memory-bank-sync`

Un ADR pour le langage des intentions, qui complète ADR-061 ; les fiches `_rules/02-5`, `_rules/03-3` et `_patterns/03-4` que le diff périme ; dans `docs/ROADMAP.md`, la ligne P-05 et les mentions d'`onHitEffect` (schéma, Gantt, P-14, P-15) que B1 remplace.

## Ce que le joueur voit

Rien de neuf : les ennemis d'aujourd'hui frappent comme avant. La vague prépare le terrain du tier 1.
