# Brief — Donjon, combat

**État :** décor validé le 24/11/2026.

Le décor de combat du lieu « donjon » (`dungeon`), en 640 × 360 (B74), en couleurs peintes (B80) : une cave voûtée, très sombre. C'est le troisième décor produit par le [workflow des décors](../../../docs/workflow_decor.md), et le premier intérieur : il sert d'essai 8. Il n'a pas eu de session de brief en quatre blocs : le propriétaire a choisi le sujet sur des esquisses libres, puis l'a réorienté deux fois, ce que ce document résume. Il ne porte **ni structure ni calques** : c'est une image à plat.

L'ancien décor du donjon, `backgrounds/dungeon/dungeon_hall*` en 320 × 180, reste où il est. Le jeu affiche encore `assets/images/bg_dungeon.png` : poser ce décor dans le jeu est le travail d'une vague, pas de ce brief.

## 1. Identité

- **Le lieu et l'écran :** le donjon, le combat.
- **Ce qu'on comprend au premier regard :** une cave de pierre voûtée, tenue par des cadres de bois, presque noire, éclairée par quatre torches ; au fond, une arche ouverte sur le noir.
- **Les fonds de fenêtre du lieu :** aucun pour l'instant. Le décor a été contrôlé sous les fonds de fenêtre de la forêt.
- **La référence :** `assets/images/bg_dungeon.png`, le décor de combat actuel du jeu. Le propriétaire a demandé de s'en servir pour le prompt : une cave voûtée, des poutres et des arcs de bois, de la pierre humide, des torches, du noir partout où la lumière ne porte pas.
- **D'où vient le sujet,** en trois temps :
  1. « Le couloir des geôles », retenu sur douze esquisses de donjon, mené jusqu'au décor entier puis **écarté par le propriétaire** : « ça fait prison plutôt que donjon ».
  2. La cave : « un donjon de cave », « des caves creusées », en plus sombre. Quinze esquisses en deux tours ; le propriétaire retient « la cave voûtée », graine 832745.
  3. Sa demande sur la composition : centrer le fond, pour que la perspective mène l'œil vers lui et vers un chemin placé juste derrière la scène de combat, et ouvrir le mur du fond.

## 2. L'écran et son interface

Sur la grille de 640 × 360 : la rangée des ennemis de y = 14 à 126, le héros centré en (320, 184), la main à partir de y = 238 entre x = 95 et 545. Ces places sont lues dans le code, pas mesurées sur une capture.

- **Le point de fuite tombe derrière le héros,** en (320, 170) : les cadres de bois se resserrent vers lui.
- **L'arche du fond est plus large que le héros :** elle dépasse de ses deux côtés. Le héros cache le centre du passage ; c'est voulu.
- **Les deux torches sur pied encadrent l'arche,** dans la bande restée visible, de y = 126 à 238.
- **Le haut reste noir,** derrière la rangée des ennemis ; les tonneaux vont dans les coins que la main laisse voir.

## 3. Les plans et les objets

Du plus lointain au plus proche : le noir du passage, l'arche et le mur du fond, les deux torches sur pied, trois cadres de bois (poteaux et linteaux), les murs de pierre et leurs deux torches, le sol dallé, quatre tonneaux. Aucun personnage, aucun animal.

## 4. Couleurs et style

Presque noir : une luminosité moyenne de 30 sur 255, pour 34 dans le décor actuel du jeu. Des bleus et des gris très sombres, le brun sourd du bois, et l'orange des quatre flammes pour seul accent. **Le noir vient du plan, pas du prompt :** les esquisses libres, même poussées vers le noir, restaient entre 41 et 49. Le décor garde ses couleurs peintes : il n'est pas ramené sur la palette.

## Le prompt

> dark fantasy pixel art illustration of a very dark old underground cellar, wide view, a long vaulted stone corridor seen straight on in one-point perspective, heavy dark wooden beams and arched timber supports repeating into the distance, a wide open stone archway in the center of the back wall leading into a long torchlit passage that continues far away, empty scene, highly detailed background with rough damp dark stone blocks, hanging iron chains, cobwebs, an old wooden crate and a barrel, mossy stains, cracked dark flagstones and two wall torches beside the archway, almost pitch black, chiaroscuro, heavy darkness swallowing the walls and the ceiling, cold desaturated palette of near-black navy, dark slate blue and dark teal grey, with tiny warm accents of ember orange around the torches, 16-bit, crisp pixels, highly detailed

**Exclusions :**

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, animal, skeleton, prison, jail, cell bars, iron bars, cage, temple, palace, cathedral, marble, sandstone, beige, bright, daylight, clean, light grey stone, well lit, evenly lit, orange wood, brown walls, warm colors, tavern, wine bottles, closed door, wall blocking the passage, small doorway

Le même prompt et les mêmes exclusions à toutes les générations, sur la graine 293903, LoRA à 0.8. Chaque image source embarque ses réglages : `python comfy_meta.py lire <image>` les relit.

**Ce que les mots ont fait :** « dungeon » et « prison corridor » donnent des geôles et des barreaux ; « stone dungeon hall » donne une salle de temple, claire et propre ; « old underground cellar » donne la cave, mais une cave de taverne, au bois orange, tant que « tavern », « orange wood » et « warm colors » ne sont pas exclus.

## Le journal des tours

| Tour | Passe | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|
| 0 | Esquisses libres, 1280 × 720 | Trois tours : le donjon (4 idées), la cave (3 idées), la cave poussée vers le noir (2 idées) ; trois graines chacun | 832745, « la cave voûtée » | Choisie par le propriétaire, qui demande ensuite de centrer le fond et d'ouvrir le mur |
| 1 | Ensemble, 1280 × 720 | Le plan sombre comme image de départ, en trois versions ; débruitage 0.8 puis 0.7, trois graines | 293903, à 0.7 | La seule qui garde à la fois les cadres de bois et la large arche. La 832745 décentre l'arche ou la rétrécit derrière le héros |
| 2 | Détail, premier pas, 2560 × 1440 | À 0.6, pour tenir la scène, puis à 0.8 guidé par les contours de cette image | 293903 | À 0.8 sans guide, un intérieur est refait ; à 0.6 il reste lisse. Avec les contours : la scène de l'un, la matière de l'autre. Grille nette à 38,7 × 41,4 |
| 3 | Détail, dernier pas, 5120 × 2880 | L'image entière repeinte d'un coup, à 0.5 | 293903 | Rien d'inventé ni de déplacé ; grille nette à 114,4 × 37,7. Le propriétaire demande de retirer les deux tonneaux en feu posés devant l'arche |
| 4 | Retouche du premier pas, puis dernier pas refait | Les deux tonneaux effacés sur l'image de 2560 × 1440, puis le dernier pas à 0.5 | 293903 | L'arche est vide ; 0,3 % des pixels changent. Grille nette à 143,3 × 31,2 ; validé sous la maquette du combat |

## Après la génération

- **La retouche des tonneaux en feu,** sur l'image du premier pas, avant le dernier pas. Le générateur, chargé de repeindre les deux zones, y remettait un tas de pierres de la forme du tonneau. Les tonneaux se tenaient devant le noir du passage : ce noir a donc été recopié par-dessus, par le code. Sur l'image de 2560 × 1440 : les rectangles x = 1052 à 1204 et x = 1432 à 1592, de y = 636 à 944, reçoivent le noir pris au milieu de l'arche, autour de x = 1310 ; le bord du piédroit gauche, x = 1030 à 1052, est repris au-dessus de lui. `dungeon_combat_pas1_source.png` est l'image retouchée.
- **L'import :** `python window_import.py <image de 5120 × 2880> dungeon_combat_detail.aseprite --taille 640x360 --couleurs-peintes --source dungeon_combat_detail_source.png`.
- **Le contrôle en situation :** `python decor_controle.py dungeon_combat_detail.aseprite <sortie.png>`.
- **Le contrôle du décor seul, agrandi, zone par zone :** aucun objet inventé, rien qui flotte, rien de soudé.
- **La retouche à la main :** pas encore faite. Deux points relevés :
  - les deux torches des bords ne tiennent à rien : une coupe, un bout de chaîne dessous. Un support à dessiner ;
  - les poutres portent des joints, comme des blocs : on hésite entre le bois et une pierre brune.
- **Ce qui n'a pas été obtenu :** derrière l'arche, le passage est un noir uni. Montrer le couloir qui continue (des arcs, des torches lointaines) faisait rétrécir l'arche derrière le héros : l'arche large a été gardée.
- **Pour rejouer les repeintes :**
  - `python decor_repeindre.py dungeon_combat_ensemble_source.png 2560x1440 --denoise 0.6`, l'image qui tient la scène ;
  - `python decor_repeindre.py dungeon_combat_ensemble_source.png 2560x1440 --contours <cette image>`, qui rend le premier pas à l'identique, avant sa retouche, et réécrit `dungeon_combat_contours.png` ;
  - `python decor_repeindre.py dungeon_combat_pas1_source.png 5120x2880 --denoise 0.5`.

## Les fichiers

| Fichier | Rôle |
|:---|:---|
| `dungeon_combat_plan.png` | Le plan en aplats, 1280 × 720, écrit par `art_src/tools/decor_dungeon_combat.py` |
| `dungeon_combat_ensemble_source.png` | L'image d'ensemble retenue, 1280 × 720 |
| `dungeon_combat_contours.png` | La carte des contours qui a tenu le premier pas, 2560 × 1440 |
| `dungeon_combat_pas1_source.png` | La repeinte en 2560 × 1440, les deux tonneaux en feu retirés |
| `dungeon_combat_detail_source.png` | La repeinte en 5120 × 2880, intacte |
| `dungeon_combat_detail.aseprite` | Le décor, 640 × 360 : le livrable, à retoucher |
