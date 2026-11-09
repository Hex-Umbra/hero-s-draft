# Outils de la chaîne pixel art

Les scripts qui produisent les sources `.aseprite` du projet. Ils sont rangés hors de `assets/` et ne sont jamais livrés avec le jeu. Pourquoi cette méthode a été choisie : voir le document de direction artistique, [§15](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md).

## La méthode, en quatre étapes

1. **La structure, par le code.** La géométrie (pour les fonds, une vraie perspective calculée pixel par pixel), la palette [Apollo](https://lospec.com/palette-list/apollo) et des calques nommés.
2. **Le détail, par ComfyUI**, en local. L'image guide, la carte de profondeur et la carte des contours tiennent la composition (ControlNet).
3. **Le retour sur la grille.** L'image générée est alignée, ramenée sur la grille (chaque case prend la couleur du groupe dominant de son bloc, puis la couleur Apollo la plus proche à l'œil, tramée avec sa voisine quand la palette n'a pas le ton), puis découpée en calques selon la géométrie de l'étape 1.
4. **La retouche à la main**, dans Aseprite.

**Règle des calques :** un calque est un objet complet. Le masquer le fait disparaître en entier et laisse voir une surface complète dessous. Seules les surfaces (murs, sol, voûte, fond) n'ont rien derrière elles. `aseprite_io.check_independent` vérifie cette règle à chaque export, et `aseprite_io.build` vérifie que chaque `.aseprite`, rouvert dans Aseprite, redonne exactement son rendu.

## Prérequis

- **Python 3 et Pillow** (`pip install pillow`).
- **Aseprite 1.3 ou plus récent.** Il est trouvé tout seul dans l'installation Steam ou dans `Program Files`. Sinon, définir `ASEPRITE_PATH` vers `Aseprite.exe`.
- **Pour les aperçus sur la carte (`pilot_cards.py`) :** la police d'icônes Material du SDK Flutter, au chemin écrit en tête du script.
- **Pour l'étape 2, ComfyUI lancé en local** (`http://127.0.0.1:8188`, ou la variable `COMFY_HOST`), avec trois modèles :
  - `sd_xl_base_1.0.safetensors` dans `checkpoints/` ;
  - `controlnet-union-sdxl-1.0-promax.safetensors` dans `controlnet/` : ControlNet Union de xinsir, licence Apache 2.0 ;
  - `pixel-art-xl.safetensors` dans `loras/` : le LoRA de nerijs, licence OpenRAIL-M.

Les fichiers intermédiaires vont dans `.work/`, que git ignore. Pour les envoyer ailleurs, définir `ART_WORK`.

## Les commandes

Toutes se lancent depuis ce dossier.

| Commande | Ce qu'elle produit |
|:---|:---|
| `python bg_hall.py ../backgrounds/dungeon/dungeon_hall.aseprite` | La salle de la herse, 320 × 180, 12 calques. À côté : `_guide_x4.png`, l'image guide pour le générateur ; `_depth.png` et `_edges.png`, les cartes de guidage pour ControlNet. |
| `python bg_plaza.py ../backgrounds/steampunk/clockwork_plaza.aseprite` | La place de l'horloge, 320 × 180, 14 calques, avec les mêmes trois fichiers à côté. |
| `python bg_camp.py ../backgrounds/camp/forest_camp.aseprite` | Le campement de l'aire de repos, 320 × 180, 15 calques. Le centre reste calme sous la colonne du menu de repos, et le feu est juste dessous. |
| `python comfy_gen.py ../backgrounds/steampunk/clockwork_plaza "<prompt>" [--seed N] [--denoise D]` | L'étape 2 : ComfyUI peint le détail, guidé par l'image guide, la profondeur et les contours. L'image arrive dans `.work/comfy/`. `--depth`, `--edges` et `--lora` règlent la force de chaque guide. Pour le Squelette pleine fenêtre : `--size 768x1152 --guide guide_x6`, depuis `squelette_128`. Pour un sprite détouré de 64 × 96 : `--size 832x1248 --guide guide_x13`. |
| `python frame_tier.py 2 ../frames/tier_2.aseprite` | Un cadre de tier d'ennemi, d'après la table du document d'identité visuelle (§4) : canevas et bordure selon le tier, fenêtre fixe de 64 × 96 et son fond. Entièrement par le code : il ne passe pas par ComfyUI. |
| `python creature_squelette.py 128 ../creatures/squelette_128.aseprite [--sans-guide]` | Le Squelette en illustration pleine fenêtre, avec sa crypte, à la largeur donnée (64, 96 ou 128 ; la hauteur en découle, en 2:3). Une partie du corps ou du décor par calque. Sans `--sans-guide`, il écrit aussi l'image guide à 768 × 1152 et les cartes de guidage. |
| `python bg_import.py squelette_96 <image générée> ../creatures/squelette_96_detail.aseprite` | L'étape 3 d'une illustration pleine fenêtre : la même que pour un fond. Une génération à 768 × 1152 se ramène sur les trois largeurs. |
| `python sprite_import.py <scène> <image générée> <sortie.aseprite> [<copie PNG>]` | L'étape 3 d'un sprite détouré, sur fond transparent : la mise sur la grille, le retrait du fond uni, le découpage par partie du corps. |
| `python bg_import.py <scène> <image générée> <sortie.aseprite> [<copie PNG de la source>]` | L'étape 3, pour n'importe quelle scène (`hall`, `plaza`…) : l'image générée est alignée, ramenée sur la grille Apollo, puis découpée. Chaque pixel va au calque de l'objet visible à cet endroit, et les autres calques gardent le rendu de la scène. Le script de la scène doit avoir tourné avant. |
| `python aseprite_layers.py ../../docs/presentations/2026-11-09_sources_aseprite_serie_pilote` | Les paliers pixel 16 et pixel 64 des sept cartes de la série pilote. |
| `python pilot_cards.py` | Une planche de contrôle des cartes de la série pilote aux cinq paliers, sur la vraie carte. |

## Les fichiers

| Fichier | Rôle |
|:---|:---|
| `motifs.py` | Les motifs des cartes : des formes nommées par rôle (clair, sombre, accent, effet…), un sprite pixel 16 posé à la main et sa palette. |
| `ladder.py` | Les cinq paliers de l'échelle A (griffonnage, pixel 16, pixel 64, dessin animé, peinture numérique), applicables à tout motif. |
| `styles.py` | Frappe aux cinq paliers, et les outils de dessin partagés (bruit, dilatation, trame de Bayer…). |
| `cards.py`, `pilot_cards.py` | Le cadre de la carte de combat, et la carte complète avec titre, coût et valeurs par palier. |
| `aseprite_layers.py` | Le découpage en calques des paliers pixel des cartes. |
| `bg_hall.py` | Le fond « salle de la herse » : géométrie, matériaux, lumières, calques et cartes de guidage. |
| `scene.py` | Ce que partagent les fonds peints par calques : la scène et ses calques complets, les cartes de guidage, l'export en `.aseprite` avec ses contrôles. |
| `bg_plaza.py` | Le fond « place de l'horloge » : chaque objet est rendu dans son propre calque complet, du plus lointain au plus proche. |
| `bg_camp.py` | Le fond « campement » de l'aire de repos, sur le même modèle. |
| `frame_tier.py` | Les cadres de tier des ennemis : fond de fenêtre, plaque, liseré, rivets, coins, insigne du tier. |
| `creature_squelette.py` | Le Squelette et sa crypte, partie par partie, en coordonnées relatives à la fenêtre ; le modèle des futures créatures. |
| `sprite_import.py` | L'étape 3 des sprites détourés : fond uni retiré, transparence rendue autour de la silhouette. |
| `comfy_gen.py` | L'étape 2 : le pilote de ComfyUI, en bibliothèque standard seulement. |
| `bg_import.py` | L'étape 3, commune à toutes les scènes : alignement, mise sur la grille, découpage. |
| `aseprite_io.py`, `aseprite_build.lua`, `aseprite_verify.lua` | Le pont vers Aseprite : assemblage en mode indexé, aller-retour vérifié, contrôle des calques. |

**À savoir :**
- **Les fonds sont rangés par thème** dans `../backgrounds/<thème>/` (`dungeon/`, `steampunk/`, `camp/`…), chacun avec ses fichiers annexes : image guide, cartes de guidage, source générée.
- **Chaque fond a son propre script de géométrie**, construit sur `scene.py`, avec `bg_plaza.py` et `bg_camp.py` pour modèles : un calque complet par objet, posé à sa profondeur. Le script de la scène ne décrit que ce qui lui est propre ; l'export, les contrôles et les cartes de guidage sont communs.
- **Le manifeste de la scène guide l'étape 3.** Il dit quels calques sont des surfaces (autorisés à laisser un vide quand on les masque), lesquels l'import doit ignorer, comme l'ombre tramée des bords de la salle, et quelles couleurs il ne doit pas utiliser. Pour le Squelette, ce sont les deux verts pâles d'Apollo : sans cette exclusion, l'ivoire des os vire au vert maladif.
- **Le fichier `dungeon_hall_detail.aseprite` a été découpé par une version plus ancienne de `bg_import.py`**, qui triait aussi les pixels par couleur. Relancer l'import le découperait selon la règle actuelle.
- **Les fichiers `_detail` de la salle, de la place et du campement ont été mis sur la grille avant la conversion perceptive** (en Lab, avec trame) utilisée pour le Squelette. Les réimporter changerait leurs couleurs.
