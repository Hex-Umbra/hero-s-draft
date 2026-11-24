# Brief — Forêt, combat

**État :** décor validé le 24/11/2026.

Le décor de combat du lieu « forêt », en 640 × 360 (B74), en couleurs peintes (B80). C'est le premier décor produit par le [workflow des décors](../../../docs/workflow_decor.md) : il n'a pas eu de session de brief, il est né des essais 5 et 6, que ce document résume. Il ne porte **ni structure ni calques** : c'est une image à plat.

## 1. Identité

- **Le lieu et l'écran :** la forêt, le combat.
- **Ce qu'on comprend au premier regard :** un sous-bois sombre de grands pins, un sentier qui s'enfonce vers une lumière pâle.
- **Les fonds de fenêtre du lieu :** les trois de `backgrounds/windows/forest/`. Le décor reprend leur prompt, leurs exclusions et l'une de leurs graines.

## 2. L'écran et son interface

Sur la grille de 640 × 360 : la rangée des ennemis de y = 14 à 126, le héros centré en (320, 184), la main à partir de y = 238 entre x = 95 et 545. Ces places sont lues dans le code, pas mesurées sur une capture.

- **Le haut reste calme :** un fond lointain et pâle derrière la rangée des ennemis.
- **Les deux gros troncs cadrent les bords de l'écran,** hors des cartes.
- **Le sentier passe sous le héros et sous la main.**

## 3. Les plans et les objets

Du plus lointain au plus proche : la lumière pâle du fond, les pins lointains, les sapins sombres et deux troncs de second plan, le sol moussu et le sentier, les deux gros troncs du premier plan avec leurs racines. Aucun personnage, aucun animal.

## 4. Couleurs et style

Les tons froids d'Apollo — bleu nuit, bleu ardoise, gris sarcelle — avec la rouille des troncs et du sentier pour seul accent chaud. Pas de brume. Le décor garde ses couleurs peintes : il n'est pas ramené sur la palette.

## Le prompt

> dark fantasy pixel art illustration of a dense dark forest, empty scene, a clear path in the foreground, two massive pine trunks framing the left and right edges, highly detailed background with gnarled tree bark, mossy rocks, roots and a rust-colored forest floor, distant thin trunks fading into pale light in the center, moody lighting, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust, ember orange and old ivory, 16-bit, crisp pixels, highly detailed

**Exclusions :**

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, skeleton, animal, giant central tree, autumn

Le même prompt et les mêmes exclusions aux trois générations, sur la graine 832745, LoRA à 0.8. Chaque image source embarque ses réglages : `python comfy_meta.py lire <image>` les relit.

## Le journal des tours

| Tour | Passe | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|
| 1 | Ensemble, 1280 × 720 | Le plan en aplats comme image de départ, sans carte de guidage ; débruitage 0.8 puis 0.9, trois graines chacun | 832745, à 0.9 | Retenue par le propriétaire sur sa repeinte en 2560 × 1440 : la plus riche en matière |
| 2 | Détail, premier pas, 2560 × 1440 | L'image entière repeinte d'un coup, à 0.8 | 832745 | La matière revient — écorce, racines, mousse — et la composition tient |
| 3 | Détail, dernier pas, 5120 × 2880 | L'image entière repeinte d'un coup, à 0.6 | 832745 | Grille de 640 × 360 nette à 54,1 × 119,3 ; validé sous la maquette du combat |

## Après la génération

- **L'import :** `python window_import.py <image de 5120 × 2880> forest_combat_detail.aseprite --taille 640x360 --couleurs-peintes --source forest_combat_detail_source.png`. La grille est lue telle quelle, chaque case garde sa couleur peinte ; le `.aseprite` est en couleurs libres, la palette Apollo en nuancier.
- **Le contrôle en situation :** fait sur une maquette — quatre ennemis des tiers 1 à 3 dans leurs cadres provisoires, le héros, une main de cinq cartes. Les troncs de second plan passent derrière la première et la dernière carte ; sourds et lointains, ils ne les disputent pas.
- **La retouche :** pas encore faite.
- **Ce qui reste des essais :** les deux repeintes ont été lancées par un script d'essai, resté dans le dossier de travail ; il deviendra un outil.

## Les fichiers

| Fichier | Rôle |
|:---|:---|
| `forest_combat_plan.png` | Le plan en aplats, 1280 × 720, écrit par `art_src/tools/decor_forest_combat.py` |
| `forest_combat_ensemble_source.png` | L'image d'ensemble retenue, 1280 × 720 |
| `forest_combat_pas1_source.png` | La repeinte en 2560 × 1440 |
| `forest_combat_detail_source.png` | La repeinte en 5120 × 2880, intacte |
| `forest_combat_detail.aseprite` | Le décor, 640 × 360 : le livrable, à retoucher |
