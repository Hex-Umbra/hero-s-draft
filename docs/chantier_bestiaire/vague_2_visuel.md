# Vague 2 — `0.6.2` — le visuel : cadres de tier et décors

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, et placée en tête du programme le même jour (B61) : le visuel passe avant le tier 1, pour que chaque sprite neuf se valide sur son vrai fond et que les vagues d'ennemis se construisent sur le placement définitif. Les chemins et les lignes de code sont **à revérifier, pas à croire**.

**Poids** : moyen — une spec, un plan. Aucun mécanisme de combat, aucun ennemi neuf.

## Ce qu'elle livre

- **Le cadre de tier** de chaque ennemi : la fenêtre de 64 × 96 est la même pour tous, le cadre grossit avec le tier, et la menace se lit avant l'illustration ([identité visuelle](../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md), §4). **Le code reçoit les cinq tiers** : leurs géométries sont fixées (§4.1, de 88 × 120 au tier 1 à 112 × 144 au tier 5). **Les cadres dessinés sont ceux des tiers 1 à 3**, les tiers des ennemis d'aujourd'hui ; ceux des tiers 4 et 5 arrivent comme des assets avec leurs vagues (6 et 7), celui des boss avec la vague 8.
- **Le fond de fenêtre** derrière la créature : un asset séparé du cadre, trois variations, choisi par le jeu ([DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.3 ; [workflow des fonds](../../art_src/docs/workflow_fond.md), §2). Cela amende l'identité visuelle §4.3, qui dessinait le fond dans le cadre.
- **Le décor de combat** redessiné, à la place de `assets/images/bg_dungeon.png` — un JPEG sous une extension `.png` (identité visuelle, §3.3) ([workflow des fonds](../../art_src/docs/workflow_fond.md), §1).
- **La clôture de P-08** dans la ROADMAP : le cadre en PNG par tier, tranché par l'identité visuelle du 18/09, est construit.

Les quatre ennemis d'aujourd'hui gardent leur sprite : des images peintes de 1696 × 2528, au rapport 2:3 de la fenêtre. Ils entrent dans les cadres tels quels, jusqu'à leur refonte dans la vague de leur tier (B52) : le Slime et le Gobelin en vague 3, le Squelette en vague 4, l'Orc en vague 5.

## Prérequis — avant l'ouverture

1. **Les assets, tous validés** :
   - les cadres des tiers 1, 2 et 3, par `art_src/tools/frame_tier.py` — le tier 2 existe (`art_src/frames/tier_2.aseprite`) ;
   - les fonds de fenêtre — trois de forêt existent (`art_src/backgrounds/windows/forest/`) ;
   - le décor de combat — `art_src/backgrounds/` en a trois en cours (`dungeon/`, `camp/`, `steampunk/`).
2. **Les réponses du propriétaire** (classe P), sur maquettes aux vraies tailles :
   - un combat complet, cadres et décor posés, aux tiers 1 à 3 : avec les sprites d'aujourd'hui, et avec un sprite neuf déjà produit (le Rat alpha, le Squelette de tier 2 ou la Faucheuse, sous `art_src/creatures/`) ;
   - quel décor pour le combat, et si le repos ou d'autres écrans en reçoivent un ;
   - le fond de fenêtre : un seul thème (la forêt) tant que les biomes (P-12) n'existent pas, tiré parmi trois variations ;
   - ce que deviennent les éléments de la vague 1 sur un cadre plus large : la barre de PV à la largeur de la carte (B12), les languettes (B14, B39), la fiche (B40).

## Porte d'entrée

La vague 1 fusionnée dans `main` par la PR #57 (commit de fusion `32e2ad46`) et taguée `v0.6.1` le 22/11 ; la porte de l'orchestration §3.1 vérifie par `gh` que la CI de `main` et le run `release.yml` du tag sont verts, puis passe la vague 1 à « close » au journal ([README](README.md) §4) et dans la mémoire. La branche part de `main`. Les trois écarts de la vague 1 (cadrage §4) ne s'appliquent plus.

## Fichiers

`p05-cadres-et-decors` pour la spec et le plan ; `bestiaire-vague-2` pour le compte rendu et les tests manuels.

## À lire

L'identité visuelle §3 à §5 et §7 à §8 ; la DA évolutive §16 ; `art_src/docs/workflow_creature.md` et `workflow_fond.md` ; `art_src/tools/README.md` (`frame_tier.py`, `creature_controle.py`) ; `lib/game/components/entities/enemy_card.dart`, `combat_entity.dart`, `health_bar.dart` ; `lib/game/systems/layout_system.dart` (`repositionEnemies` : la largeur d'un ennemi y est une constante, `visualWidthPerEnemy`) ; `lib/game/heros_draft_game.dart` (le décor, sa priorité) ; ADR-121 (l'interface des ennemis) ; le cadrage §1.3 (B17, B21, B30 : la demi-place, la meute, les six cartes, que les vagues 3 et 4 poseront sur ce placement).

## La spec doit fixer

1. **Le compositing** : le décor, puis le fond de fenêtre, la créature et le cadre ; l'offset de fenêtre de chaque cadre comme donnée, pour les cinq tiers (identité visuelle §4.1) ; l'échelle entière (la créature de 128 × 192 à deux pixels par pixel de fenêtre, DA §16.2).
2. **Le placement** : des largeurs de carte qui varient avec le tier, la somme des largeurs réelles à la place de la constante. **Il s'écrit en connaissant ses suites** : la demi-place du Rat et les six cartes du plateau (vague 3, B17, B30), la meute qui compte pour deux cartes (vague 4, B21) devront s'y poser sans reprise.
3. **Les anciens sprites dans la fenêtre** : une image peinte de 1696 × 2528 réduite à 64 × 96, son filtrage, et ce qui la distingue d'un sprite neuf ; un état transitoire, que chaque vague de tier efface.
4. **La vague 1 sur les cadres** : la barre, le voile, les languettes, la fiche et le survol, ancrés à la fenêtre et non au canvas (identité visuelle §4.2).
5. **Le fond de fenêtre** : qui le choisit, et quand (par combat, par ennemi).
6. **Le décor** : le remplacement de `bg_dungeon.png`, son format (PNG seulement, identité visuelle §3.3).
7. **Un cadre absent** : ce que le jeu affiche pour un tier dont le cadre n'est pas encore dessiné (les tiers 4 et 5 jusqu'à leurs vagues), et le test qui le refuse au chargement une fois le tier ouvert.
8. **Les tests** (ADR-113) : le calcul du placement ; tout ce qui se voit va au fichier de tests manuels.

## À arbitrer

Les questions P ont leur réponse dans les prérequis ; une mesure que les maquettes ne donnent pas et qui suit l'échelle existante est de classe T.

## Ne pas absorber

La demi-place et les six cartes (vague 3), la meute (vague 4) : le placement les prévoit, il ne les construit pas ; les cadres des tiers 4, 5 et boss (vagues 6, 7 et 8) ; aucun sprite refait ; les biomes (P-12) ; le médaillon d'élite (identité visuelle §5.1, P-14) ; la carte du héros ; le juice et les animations (P-06, P-07) ; aucun mécanisme de combat, aucun ennemi neuf.

## Tâche à risque

**Le placement et la vague 1** : des cartes de tailles différentes changent tout ce qui s'ancre à une carte d'ennemi — la barre, les languettes, la fiche, le ciblage, le survol.

## Pour `memory-bank-sync`

Un ADR pour le cadre de tier et le compositing ; les fiches `_patterns` du rendu des entités et du HUD que le diff périme ; la ligne P-08 de `docs/ROADMAP.md`, qui se clôt, et la ligne P-05.

## Ce que le joueur voit

Les ennemis d'aujourd'hui, chacun dans un cadre qui dit son tier, sa créature sur un fond, dans une salle de combat redessinée.
