# Vague 7 — `0.6.7` — le visuel : cadres de tier et décors

> Fiche de vague du [chantier du bestiaire](README.md). Écrite le 22/11 pour `0.6.5`, déplacée en `0.6.7` le même jour, après les tiers 4 et 5 (B59) ; avant les vagues 2 à 6 : revérifie chaque chemin, et relis les comptes rendus des vagues précédentes, qui disent quels anciens sprites restent.

**Poids** : moyen — une spec, un plan. Aucun mécanisme de combat.

## Ce qu'elle livre

- **Le cadre de tier** de chaque ennemi, des tiers 1 à 5 : la fenêtre de 64 × 96 est la même pour tous, le cadre grossit avec le tier, et la menace se lit avant l'illustration ([identité visuelle](../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md), §4).
- **Le fond de fenêtre** derrière la créature : un asset séparé du cadre, trois variations, choisi par le jeu ([DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.3 ; [workflow des fonds](../../art_src/docs/workflow_fond.md), §2). Cela amende l'identité visuelle §4.3, qui dessinait le fond dans le cadre.
- **Le décor de combat** redessiné, à la place de `assets/images/bg_dungeon.png` — un JPEG sous une extension `.png` (identité visuelle, §3.3) ([workflow des fonds](../../art_src/docs/workflow_fond.md), §1).
- **La clôture de P-08** dans la ROADMAP : le cadre en PNG par tier, tranché par l'identité visuelle du 18/09, est construit.

## Prérequis — avant l'ouverture

1. **Les assets, tous validés** :
   - les cadres des tiers 1 à 5, par `art_src/tools/frame_tier.py` — le tier 2 existe (`art_src/frames/tier_2.aseprite`) ;
   - les fonds de fenêtre — trois de forêt existent (`art_src/backgrounds/windows/forest/`) ;
   - le décor de combat — `art_src/backgrounds/` en a trois en cours (`dungeon/`, `camp/`, `steampunk/`).
2. **Les réponses du propriétaire** (classe P), sur maquettes aux vraies tailles :
   - un combat complet, cadres et décor posés, aux cinq tiers ;
   - quel décor pour le combat, et si le repos ou d'autres écrans en reçoivent un ;
   - le fond de fenêtre : un seul thème (la forêt) tant que les biomes (P-12) n'existent pas, tiré parmi trois variations ;
   - ce que deviennent les éléments de la vague 1 sur un cadre plus large : la barre de PV à la largeur de la carte (B12), les languettes (B14, B39), la fiche (B40) ;
   - le Rat à 80 % (B17) : dans un cadre réduit, ou sa créature seule réduite.
3. **Aucun ennemi ne garde d'ancien sprite** à l'ouverture, ou la liste de ceux qui le gardent est acceptée par le propriétaire.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 6 : fusionnée, `v0.6.6` posé sur un commit de `main`, CI et release vertes ; la vague 6 passe à « close ».

## Fichiers

`p05-cadres-et-decors` pour la spec et le plan ; `bestiaire-vague-7` pour le compte rendu et les tests manuels.

## À lire

L'identité visuelle §3 à §5 et §7 à §8 ; la DA évolutive §16 ; `art_src/docs/workflow_creature.md` et `workflow_fond.md` ; `art_src/tools/README.md` (`frame_tier.py`, `creature_controle.py`) ; `lib/game/components/entities/enemy_card.dart`, `combat_entity.dart`, `health_bar.dart` ; `lib/game/systems/layout_system.dart` (`repositionEnemies` : la largeur d'un ennemi y est une constante, `visualWidthPerEnemy`) ; `lib/game/heros_draft_game.dart` (le décor, sa priorité) ; ADR-121 (l'interface des ennemis).

## La spec doit fixer

1. **Le compositing** : le décor, puis le fond de fenêtre, la créature et le cadre ; l'offset de fenêtre de chaque cadre comme donnée (identité visuelle §4.1) ; l'échelle entière (la créature de 128 × 192 à deux pixels par pixel de fenêtre, DA §16.2).
2. **Le placement** : des largeurs de carte qui varient avec le tier, la somme des largeurs réelles à la place de la constante, les six cartes du plateau (B30) et la meute (B21).
3. **La vague 1 sur les cadres** : la barre, le voile, les languettes, la fiche et le survol, ancrés à la fenêtre et non au canvas (identité visuelle §4.2).
4. **Le fond de fenêtre** : qui le choisit, et quand (par combat, par ennemi).
5. **Le décor** : le remplacement de `bg_dungeon.png`, son format (PNG seulement, identité visuelle §3.3).
6. **Les tests** (ADR-113) : le calcul du placement ; tout ce qui se voit va au fichier de tests manuels.

## À arbitrer

Les questions P ont leur réponse dans les prérequis ; une mesure que les maquettes ne donnent pas et qui suit l'échelle existante est de classe T.

## Ne pas absorber

Les biomes (P-12) ; le médaillon d'élite (identité visuelle §5.1, P-14) ; le cadre des boss (vague 8) ; la carte du héros ; le juice et les animations (P-06, P-07) ; aucun mécanisme de combat, aucun ennemi neuf.

## Tâche à risque

**Le placement et la vague 1** : des cartes de tailles différentes changent tout ce qui s'ancre à une carte d'ennemi — la barre, les languettes, la fiche, le ciblage, le survol.

## Pour `memory-bank-sync`

Un ADR pour le cadre de tier et le compositing ; les fiches `_patterns` du rendu des entités et du HUD que le diff périme ; la ligne P-08 de `docs/ROADMAP.md`, qui se clôt, et la ligne P-05.

## Ce que le joueur voit

Chaque ennemi dans un cadre qui dit son tier, sa créature sur un fond, dans une salle de combat redessinée.
