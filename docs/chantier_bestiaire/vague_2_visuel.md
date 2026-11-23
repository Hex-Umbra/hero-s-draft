# Vague 2 — `0.6.2` — le visuel : cadres de tier et décors

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, et placée en tête du programme le même jour (B61) : le visuel passe avant le tier 1, pour que chaque sprite neuf se valide sur son vrai fond et que les vagues d'ennemis se construisent sur le placement définitif. Les chemins et les lignes de code sont **à revérifier, pas à croire**. Complétée le 23/11, après l'audit du chantier : la couture de lieu (B66), le fond de fenêtre séparé (B67), puis la règle d'échelle, les géométries des cadres et le lieu (B72 à B74), tranchés sur les maquettes de l'[audit](https://claude.ai/artifact/GqvVVedFnU9ZBSYQL1ME2P), diapositives 24 à 31.

**Poids** : lourd — une spec, un plan. Aucun mécanisme de combat, aucun ennemi neuf ; mais l'échelle du plateau et le placement changent tout ce qui s'ancre à une carte d'ennemi.

## Ce qu'elle livre

- **Le cadre de tier** de chaque ennemi : la fenêtre de 64 × 96 est la même pour tous, le cadre grossit avec le tier, et la menace se lit avant l'illustration. **Le code reçoit les cinq tiers**, aux géométries de B73 : 88 × 120, 96 × 128, 104 × 136, 112 × 144 et 120 × 152, soit 12, 16, 20, 24 et 28 pixels de bordure. **Les cadres dessinés sont ceux des tiers 1 à 3**, les tiers des ennemis d'aujourd'hui ; ceux des tiers 4 et 5 arrivent comme des assets avec leurs tiers, celui des boss avec les boss. **Les cadres d'aujourd'hui sont provisoires** (B73) : ils seront redessinés, moins pleins, avec des parties transparentes, comme des racines autour de la carte.
- **La règle d'échelle** (B72) : le cadre à un palier pair choisi par l'écran, la créature et son fond à la moitié ; un plateau qui ne rétrécit plus en continu ; la fiche ouverte qui double la carte.
- **Le fond de fenêtre** derrière la créature : un asset séparé du cadre, trois variations par lieu, choisi par le jeu (B67 ; [DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.3 ; [workflow des fonds](../../art_src/docs/workflow_fond.md), §2). B67 amende l'identité visuelle §4.3, qui dessinait le fond dans le cadre.
- **Le décor de combat** : un décor de forêt neuf, en 640 × 360 (B74), à la place de `assets/images/bg_dungeon.png` — un JPEG sous une extension `.png` (identité visuelle, §3.3).
- **La couture de lieu** (B66) : le décor de combat et le thème du fond de fenêtre ne sont pas des constantes, ils passent par **un identifiant de lieu**, à valeur unique tant que les biomes (P-12) n'existent pas — la forêt (B74) ; les assets se rangent par lieu. Elle prépare les biomes, elle ne les construit pas.
- **La clôture de P-08** dans la ROADMAP : le cadre en PNG par tier, tranché par l'identité visuelle du 18/09, est construit.

Les quatre ennemis d'aujourd'hui gardent leur sprite : des peintures de 1696 × 2528, au rapport 2:3 de la fenêtre — **des cartes entières, avec leur cadre peint**, et non des créatures détourées. Ils entrent dans les cadres jusqu'à leur refonte dans la vague de leur tier (B52) : le Slime et le Gobelin en vague 4, le Squelette en vague 5, l'Orc en vague 6.

## Prérequis — avant l'ouverture

1. **Les assets, tous validés** :
   - **les cadres des tiers 1, 2 et 3, redessinés** (B73) : aux canevas de 88 × 120, 96 × 128 et 104 × 136, avec leurs transparences. Le cadre du tier 2 qui existe (`art_src/frames/tier_2.aseprite`) et l'outil `art_src/tools/frame_tier.py`, qui porte encore les anciennes tailles, sont provisoires ;
   - les fonds de fenêtre — trois de forêt existent (`art_src/backgrounds/windows/forest/`) ;
   - **le décor de combat de forêt, en 640 × 360** (B74) : à produire avant l'ouverture. La méthode des décors est écrite pour 320 × 180 ([workflow des fonds](../../art_src/docs/workflow_fond.md), §1) : ses scripts de scène, son image guide et sa taille de génération sont à recaler, et son problème ouvert — une grille générée plus grossière que la grille visée — pèse deux fois plus à cette taille.
2. **Les réponses du propriétaire** (classe P) :
   - ✅ **la règle d'échelle** : B72 ;
   - ✅ **les géométries des cadres** : B73, celle des boss attendant leur cadrage ;
   - ✅ **le lieu unique** : la forêt, B74 ;
   - un combat complet sur maquette, avec les cadres redessinés et le décor neuf, aux tiers 1 à 3 : avec les sprites d'aujourd'hui — recadrés sur leur illustration, ou gardés avec leur cadre peint dans le cadre neuf —, et avec un sprite neuf déjà produit (le Rat alpha, le Squelette de tier 2 ou la Faucheuse, sous `art_src/creatures/`) ;
   - si le repos ou d'autres écrans reçoivent un décor ;
   - ce que deviennent les éléments de la vague 1 sur un cadre plus large et moins plein : la barre de PV à la largeur de la carte (B12), les languettes (B14, B39), la fiche (B40).

## Porte d'entrée

La vague 1 fusionnée dans `main` par la PR #57 (commit de fusion `32e2ad46`) et taguée `v0.6.1` le 22/11 ; la porte de l'orchestration §3.1 vérifie par `gh` que la CI de `main` et le run `release.yml` du tag sont verts, puis passe la vague 1 à « close » au journal ([README](README.md) §4) et dans la mémoire. La branche part de `main`. Les trois écarts de la vague 1 (cadrage §4) ne s'appliquent plus.

## Fichiers

`p05-cadres-et-decors` pour la spec et le plan ; `bestiaire-vague-2` pour le compte rendu et les tests manuels.

## À lire

L'identité visuelle §3 à §5 et §7 à §8 ; la DA évolutive §16 ; `art_src/docs/workflow_creature.md` et `workflow_fond.md` ; `art_src/tools/README.md` (`frame_tier.py`, `creature_controle.py`) ; `lib/game/components/entities/enemy_card.dart`, `combat_entity.dart`, `health_bar.dart` ; `lib/game/systems/layout_system.dart` (`repositionEnemies` : la largeur d'un ennemi y est une constante, `visualWidthPerEnemy`) ; `lib/game/heros_draft_game.dart` (le décor, sa priorité) ; ADR-121 (l'interface des ennemis) ; le cadrage §1.3 (B17, B21, B30 : la demi-place, la meute, les six cartes, que les vagues 4 et 5 poseront sur ce placement).

## La spec doit fixer

1. **Le compositing** : le décor, puis le fond de fenêtre, la créature et le cadre ; l'offset de fenêtre de chaque cadre comme donnée, pour les cinq tiers (B73) ; un cadre qui n'est plus un rectangle plein — ses transparences laissent voir le décor, et rien ne suppose une bordure opaque.
2. **L'échelle** (B72) : le choix du palier pair selon l'écran, la créature et son fond à la moitié, le filtrage sans lissage ; ce qui remplace le facteur d'échelle continu de l'écran, le rétrécissement du plateau, le boss à 1,25 et la fiche à 1,25 ; ce que devient un écran plus petit que 1080p ; la fiche ouverte au palier pair suivant, sa barre à la même hauteur (B40) ; le décor de 640 × 360 à 3, 4 ou 6 pixels d'écran par pixel, et son cadrage quand l'écran n'est pas en 16:9.
3. **Le placement** : des largeurs de carte qui varient avec le tier, la somme des largeurs réelles à la place de la constante. **Il s'écrit comme une fonction pure**, hors du composant de rendu, qui reçoit une largeur et un écart par carte : c'est ce qui le rend testable, et ce qui laisse la demi-place du Rat et les six cartes du plateau (vague 4, B30), puis la meute qui compte pour deux cartes (vague 5, B21), s'y poser sans le reprendre. Le Rat y garde une carte de tier 1 entière, avec un écart plus serré (B72).
4. **Les anciens sprites dans la fenêtre** : une carte peinte de 1696 × 2528 réduite à 64 × 96 — recadrée ou non, selon le prérequis 2 —, son filtrage, et ce qui la distingue d'un sprite neuf ; un état transitoire, que chaque vague de tier efface.
5. **La vague 1 sur les cadres** : la barre, le voile, les languettes, la fiche et le survol, ancrés à la fenêtre et non au canvas (identité visuelle §4.2).
6. **Le lieu** (B66, B74) : l'identifiant de lieu comme donnée, ce qu'il désigne (un décor, un thème de fond de fenêtre), où il se lit, et sa valeur unique, la forêt ; les assets rangés par lieu.
7. **Le fond de fenêtre** (B67) : parmi les trois variations du lieu, qui le choisit, et quand (par combat, par ennemi).
8. **Le décor** : le remplacement de `bg_dungeon.png`, son format (PNG seulement, identité visuelle §3.3) — aujourd'hui l'image est étirée à la taille de l'écran.
9. **Un cadre absent** : ce que le jeu affiche pour un tier dont le cadre n'est pas encore dessiné (les tiers 4 et 5 jusqu'à leurs vagues), et le test qui le refuse au chargement une fois le tier ouvert. **Un boss porte le cadre de son tier**, au même palier que les autres (B73).
10. **L'export** : le chemin d'un `.aseprite` de `art_src/` vers l'asset du jeu, pour un sprite, un cadre et un fond.
11. **Les tests** (ADR-113) : le calcul du palier et du placement ; tout ce qui se voit va au fichier de tests manuels.

## Pièges relevés à l'audit du 23/11

Lus dans le code et dans `art_src/`, sans exécution : à revérifier.

- **Tout ce qui se lit sur un ennemi s'ancre à une carte de taille fixe** : la barre, les languettes, la zone de survol, le rectangle de la fiche et les halos se déduisent de la taille de la carte, figée à 100 × 140. Passer à une taille par tier est du paramétrage, à condition que le placement soit la fonction pure du point 2.
- **Deux largeurs concurrentes** dans `repositionEnemies` : l'une pour le test de rétrécissement, l'autre pour l'espacement.
- **Tout le placement est en échelle continue** aujourd'hui — le facteur d'échelle de l'écran, le rétrécissement du plateau, le boss à 1,25, la fiche à 1,25 : c'est ce que B72 remplace, et le plus gros du travail de cette vague.
- **Aucun filtrage n'est fixé** pour les sprites dans le rendu.
- **Le cadre provisoire du tier 2 embarque un calque de fond de fenêtre** opaque, alors que le fond est un asset séparé (B67) : les cadres redessinés n'en ont pas.
- **Trois grilles sur un écran** : en 1080p, un pixel de décor fait 3 pixels d'écran, un pixel de cadre 2, un pixel de créature 1. C'est voulu (B72, B74) ; les maquettes du prérequis 2 le montrent sur les vrais assets.

## À arbitrer

Les questions P ont leur réponse dans les prérequis ; une mesure que les maquettes ne donnent pas et qui suit l'échelle existante est de classe T.

## Ne pas absorber

La demi-place et les six cartes (vague 4), la meute (vague 5) : le placement les prévoit, il ne les construit pas ; les cadres des tiers 4, 5 et boss ; aucun sprite refait ; le système de biomes (P-12) — ni pool d'ennemis par lieu, ni second lieu : la couture de lieu le prépare, elle ne le construit pas ; le médaillon d'élite (identité visuelle §5.1, P-14) ; la carte du héros ; le juice et les animations (P-06, P-07) ; aucun mécanisme de combat, aucun ennemi neuf.

## Tâche à risque

**Le placement et la vague 1** : des cartes de tailles différentes changent tout ce qui s'ancre à une carte d'ennemi — la barre, les languettes, la fiche, le ciblage, le survol.

## Pour `memory-bank-sync`

Un ADR pour le cadre de tier et le compositing ; les fiches `_patterns` du rendu des entités et du HUD que le diff périme ; la ligne P-08 de `docs/ROADMAP.md`, qui se clôt, et la ligne P-05.

## Ce que le joueur voit

Les ennemis d'aujourd'hui, chacun dans un cadre qui dit son tier, sa créature sur un fond, dans une salle de combat redessinée.
