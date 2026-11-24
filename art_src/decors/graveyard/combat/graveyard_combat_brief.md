# Brief — Cimetière, combat

**État :** décor validé le 24/11/2026, dans sa seconde version : le dernier pas refait à 0.5, après l'analyse de la première.

Le décor de combat du lieu « cimetière » (`graveyard`), en 640 × 360 (B74), en couleurs peintes (B80). C'est le second décor produit par le [workflow des décors](../../../docs/workflow_decor.md), et le premier mené d'un bout à l'autre par ses outils : il sert d'essai 7, celui qui dit si la méthode tient sur un autre sujet que la forêt. Il n'a pas eu de session de brief en quatre blocs : le propriétaire a choisi le sujet sur des esquisses libres, que ce document résume. Il ne porte **ni structure ni calques** : c'est une image à plat.

## 1. Identité

- **Le lieu et l'écran :** le cimetière, le combat.
- **Ce qu'on comprend au premier regard :** un vieux cimetière, la nuit, sous une grande lune ; des croix de pierre, deux arbres morts.
- **Les fonds de fenêtre du lieu :** aucun pour l'instant. Le décor a été contrôlé sous les fonds de fenêtre de la forêt.
- **D'où vient le sujet :** quatre idées de cimetière, trois graines chacune, en génération libre. Le propriétaire a retenu l'idée « sous les arbres morts », graine 121064 : un grand arbre mort à gauche, une grande lune pâle à droite, des croix, un sentier clair.

## 2. L'écran et son interface

Sur la grille de 640 × 360 : la rangée des ennemis de y = 14 à 126, le héros centré en (320, 184), la main à partir de y = 238 entre x = 95 et 545. Ces places sont lues dans le code, pas mesurées sur une capture.

Posée telle quelle sous le combat, l'esquisse retenue perdait l'essentiel : sa lune coupée par la dernière carte d'ennemi, ses tombes et son sentier sous la main. Le plan garde ses éléments et les replace :

- **L'horizon et ses tombes remontent** dans la bande restée visible, de y = 126 à 238.
- **La lune descend dans cette bande,** à droite du héros.
- **Le tronc de l'arbre mort se range à gauche de la première carte ;** une masse sombre lui répond au bord droit.
- **Le sentier passe sous le héros et sous la main.**

## 3. Les plans et les objets

Du plus lointain au plus proche : le ciel de nuit et ses étoiles, la lune, les tombes lointaines sur l'horizon, les croix de pierre sur leurs socles, le sol et son sentier, les deux arbres morts aux bords avec leurs racines. Aucun personnage, aucun animal.

## 4. Couleurs et style

Les tons froids d'Apollo — bleu nuit, bleu ardoise, gris de pierre — avec l'ivoire de la lune et la rouille des arbres pour accents. Pas de brume. Le décor garde ses couleurs peintes : il n'est pas ramené sur la palette.

## Le prompt

> dark fantasy pixel art illustration of an old graveyard at night, wide view, a large gnarled leafless dead tree on the left edge, a large pale full moon low above the horizon on the right, empty scene, highly detailed background with rows of weathered tombstones, stone crosses, twisted roots, a pale dirt path in the center and a deep blue starry night sky, moody lighting, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust, ember orange and old ivory, 16-bit, crisp pixels, highly detailed

**Exclusions :**

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, animal, skeleton, autumn, orange foliage, leaves

Le même prompt et les mêmes exclusions aux trois générations, sur la graine 121064, LoRA à 0.8. La phrase de palette est celle des fonds de fenêtre de la forêt. Chaque image source embarque ses réglages : `python comfy_meta.py lire <image>` les relit.

## Le journal des tours

| Tour | Passe | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|
| 0 | Esquisses libres, 1280 × 720 | Quatre idées, trois graines chacune, sans plan | 121064, idée « sous les arbres morts » | Choisie par le propriétaire pour son sujet et son ambiance |
| 1 | Ensemble, 1280 × 720 | Le plan en aplats comme image de départ ; débruitage 0.8 puis 0.9, trois graines chacun | 121064, à 0.8 | À 0.8 le plan tient sur les trois graines ; à 0.9 la lune se dédouble ou s'enterre |
| 2 | Détail, premier pas, 2560 × 1440 | Les trois images à 0.8 repeintes entières, à 0.8 | 121064 | La plus proche de l'esquisse ; ses croix se lisent des deux côtés du héros, sa lune est dégagée |
| 3 | Détail, dernier pas, 5120 × 2880 | L'image entière repeinte d'un coup, à 0.6 | 121064 | Grille nette à 91,1 × 99,1 ; validé sous la maquette du combat, puis **écarté** : regardé seul, le décor portait sept objets inventés par ce pas — une croix sans pied, des tombes dans un arbre, une seconde lune |
| 4 | Détail, dernier pas refait | Le même pas à 0.4, à 0.5, et à 0.6 avec un prompt sans objet | 121064, à 0.5 | 0.4 garde les gros pixels du premier pas ; le prompt sans objet change les croix en tours ; 0.5 affine sans refaire la scène, grille nette à 81,5 × 96,3 |

## Après la génération

- **L'import :** `python window_import.py <image de 5120 × 2880> graveyard_combat_detail.aseprite --taille 640x360 --couleurs-peintes --source graveyard_combat_detail_source.png`. La grille est lue telle quelle, chaque case garde sa couleur peinte ; le `.aseprite` est en couleurs libres, la palette Apollo en nuancier.
- **Le contrôle en situation :** `python decor_controle.py graveyard_combat_detail.aseprite <sortie.png>`, une maquette — quatre ennemis des tiers 1 à 3 dans leurs cadres provisoires, le héros, une main de cinq cartes.
- **La retouche :** pas encore faite. Cinq points relevés sur le décor seul, agrandi :
  - une stèle et deux petites croix dans les branches de l'arbre de gauche : à effacer ;
  - des brindilles rouges sur deux croix, à gauche du héros : à effacer ;
  - une branche qui pousse sur la croix du centre, présente dès le premier pas : à effacer ;
  - une étoile trop grosse dans le ciel, entre la deuxième et la troisième carte d'ennemi : à réduire ;
  - deux coins sombres sans forme, en bas de l'image, venus des masses de premier plan du plan : l'interface en cache une part.
- **Pour rejouer les deux repeintes :** `python decor_repeindre.py graveyard_combat_ensemble_source.png 2560x1440`, puis `python decor_repeindre.py graveyard_combat_pas1_source.png 5120x2880 --denoise 0.5`.

## Les fichiers

| Fichier | Rôle |
|:---|:---|
| `graveyard_combat_plan.png` | Le plan en aplats, 1280 × 720, écrit par `art_src/tools/decor_graveyard_combat.py` |
| `graveyard_combat_ensemble_source.png` | L'image d'ensemble retenue, 1280 × 720 |
| `graveyard_combat_pas1_source.png` | La repeinte en 2560 × 1440 |
| `graveyard_combat_detail_source.png` | La repeinte en 5120 × 2880, intacte |
| `graveyard_combat_detail.aseprite` | Le décor, 640 × 360 : le livrable, à retoucher |
