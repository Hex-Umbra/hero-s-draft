# Outils de la chaîne pixel art

Les scripts qui produisent les sources `.aseprite` du projet. Ils sont rangés hors de `assets/` et ne sont jamais livrés avec le jeu. Pourquoi cette méthode a été choisie : voir le document de direction artistique, [§15](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md).

## La méthode

Deux documents décrivent le travail pas à pas :
- [**Produire un fond**](../docs/workflow_fond.md) : le fond d'écran de 320 × 180, avec la structure par le code et le détail par ComfyUI ; et le fond de fenêtre de 128 × 192, généré librement, en trois variations par biome.
- [**Produire une créature ou un personnage**](../docs/workflow_creature.md) : la créature décrite d'abord dans un brief établi avec le propriétaire, puis générée seule, avec la pose imposée en OpenPose, puis détourée et séparée en calques, et livrée comme un sprite que le jeu greffe sur un fond de fenêtre. Une fois son design validé, elle reçoit un liseré de lumière dans son propre calque.

Les deux finissent de la même façon : un `.aseprite` en palette Apollo, à retoucher à la main. Des cas réels, racontés en détail avec leurs prompts et leurs graines, sont dans [`../docs/exemples/`](../docs/exemples/).

## Règles communes

- **La palette [Apollo](https://lospec.com/palette-list/apollo), exacte.** ComfyUI ne la connaît pas : le prompt la décrit en mots (« muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust, ember orange and old ivory »), puis la mise sur la grille la rend exacte. Chaque case prend la couleur du groupe dominant de son bloc, puis la couleur Apollo la plus proche à l'œil, tramée avec sa voisine quand la palette n'a pas le ton.
- **Générer à 8 fois la taille voulue.** Le LoRA pixel art peint des cases de 8 pixels. À 1024 × 1536, elles tombent pile sur une grille de 128 × 192, et l'import lit le cœur de chaque case au lieu de mélanger ses bords.
- **Plusieurs graines par tour, une chose changée à la fois.** Trois pour un fond. Pour une créature, six au premier tour, puis moins à mesure que le design se fixe ([workflow des créatures](../docs/workflow_creature.md), étape 3). Une image qu'on aime se relance avec sa graine quand on retouche le prompt : la composition reste souvent proche. Pour une créature, on ne garde une graine qu'une fois son design validé.
- **Garder la source.** L'image générée se range en PNG à côté de son `.aseprite`, jamais en JPEG. Une image corrigée garde l'originale à côté (`_brute`).
- **Ne rien supprimer.** Une version remplacée, ou un essai abandonné, va dans [`../archives/`](../archives/README.md), au même chemin que l'original (`<famille>/tier_<n>/` pour une créature), puis dans `<date>_<ce que c'est>/`, avec ses noms de fichiers d'origine. Les archives sont en lecture seule, et aucun outil n'y lit : c'est l'historique de ce qui a été fait.
- **Un calque est un objet complet.** Le masquer le fait disparaître en entier et laisse voir une surface complète dessous. Seules les surfaces (murs, sol, voûte, fond) n'ont rien derrière elles. `aseprite_io.check_independent` vérifie cette règle à chaque export, et `aseprite_io.build` vérifie que chaque `.aseprite`, rouvert dans Aseprite, redonne exactement son rendu.

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
| `python comfy_gen.py ../backgrounds/steampunk/clockwork_plaza "<prompt>" [--seed N] [--denoise D]` | L'étape 2 : ComfyUI peint le détail, guidé par l'image guide, la profondeur et les contours. L'image arrive dans `.work/comfy/`. `--depth`, `--edges` et `--lora` règlent la force de chaque guide. Pour le Squelette pleine fenêtre (ancienne méthode) : `--size 768x1152 --guide guide_x6`, depuis la sortie de `creature_squelette.py`. Pour un sprite détouré de 64 × 96 : `--size 832x1248 --guide guide_x13`. |
| `python frame_tier.py 2 ../frames/tier_2.aseprite` | Un cadre de tier d'ennemi, d'après la table du document d'identité visuelle (§4) : canevas et bordure selon le tier, fenêtre fixe de 64 × 96 et son fond. Entièrement par le code : il ne passe pas par ComfyUI. |
| `python creature_squelette.py 128 .work/squelette_128.aseprite [--sans-guide]` | **L'ancienne méthode, archivée** dans `../archives/squelette/tier_2/` : le Squelette en illustration pleine fenêtre, avec sa crypte, à la largeur donnée (64, 96 ou 128 ; la hauteur en découle, en 2:3). Une partie du corps ou du décor par calque. Sans `--sans-guide`, il écrit aussi l'image guide à 768 × 1152 et les cartes de guidage. |
| `python bg_import.py squelette_96 <image générée> .work/squelette_96_detail.aseprite` | L'étape 3 d'une illustration pleine fenêtre (ancienne méthode) : la même que pour un fond. Une génération à 768 × 1152 se ramène sur les trois largeurs. |
| `python sprite_import.py <scène> <image générée> <sortie.aseprite> [<copie PNG>]` | L'étape 3 d'un sprite détouré, sur fond transparent : la mise sur la grille, le retrait du fond uni, le découpage par partie du corps. |
| `python bg_import.py <scène> <image générée> <sortie.aseprite> [<copie PNG de la source>]` | L'étape 3, pour n'importe quelle scène (`hall`, `plaza`…) : l'image générée est alignée, ramenée sur la grille Apollo, puis découpée. Chaque pixel va au calque de l'objet visible à cet endroit, et les autres calques gardent le rendu de la scène. Le script de la scène doit avoir tourné avant. |
| `python comfy_gen.py <nom> "<prompt>" --libre --exclure "<exclusions>" --size 1024x1536 --seed N --lora 0.8` | Une génération libre, sans guide : pour explorer un design, pour un fond de fenêtre ou pour une créature seule. L'image arrive dans `.work/comfy/<nom>_libre_s<graine>.png`. |
| `python comfy_gen.py <préfixe> "<prompt>" --sujet --guide guide --pose 0.85 --edges 0.55 --depth 0 --denoise 1.0 --size 1024x1536 --lora 0.8 [--nom <nom>]` | Une créature guidée par sa pose : `<préfixe>_pose.png` (OpenPose), `<préfixe>_edges.png` (l'équipement) et `<préfixe>_guide.png`. `--sujet` laisse le prompt négatif accepter une figure. Un guide de force nulle n'est pas utilisé. `--nom` donne un autre nom à l'image de sortie : plusieurs prompts sur une même graine ne s'écrasent plus. |
| `python comfy_gen.py <préfixe> "<prompt>" --retouche --denoise 0.55` | Ne repeint que la zone blanche de `<préfixe>_bande.png` dans `<préfixe>_assemblage.png`, et rend le reste à l'identique. |
| `python window_import.py <image générée> <sortie.aseprite> [--taille 128x192] [--source <copie PNG>]` | Un fond de fenêtre : l'image générée à 8 fois la taille, ramenée sur la grille Apollo, en un calque. |
| `python creature_<nom>_pose.py <préfixe>` | Les guides d'une créature : la carte OpenPose, l'équipement en contours et l'image de départ unie. Un script neuf par créature, écrit d'après son brief ; il ne contient que ses points et son équipement, et importe le dessin de `pose.py`. Existent : `creature_faucheuse_pose.py` (la Faucheuse, la faux) et `creature_squelette_pose.py` (le Squelette de tier 2, de face, le bâton et l'écu rond). |
| `python fond_uni.py <image.png> <sortie.png> [--ecart 30] [--poche 6]` | Aplatit le fond d'une créature générée sur le ton du haut, quand le générateur y a ajouté un sol d'un autre ton. La créature n'est pas touchée. Essayé sur un fond en deux tons, pas sur un fond rayé ou en halo. |
| `python creature_controle.py <sprite.aseprite> <tier> <planche.png> [--fonds <fond.aseprite> ...] [--voisins <sprite.aseprite> ...] [--avec-lisere]` | La planche du contrôle en situation : le sprite sur les fonds de son biome (la forêt par défaut), dans le cadre de son tier agrandi deux fois, et à côté de ses voisins. Le calque Liseré est masqué, sauf avec `--avec-lisere`. |
| `python creature_reduire.py reduire <figure.png> <préfixe des guides> <préfixe de sortie> <facteur> --ancre X,Y` | Réduit une créature validée et ses guides autour du milieu des pieds. Écrit `<sortie>_base.png`, `_pose.png` et `_edges.png`, à faire repeindre par `comfy_gen.py --guide base --denoise 0.35`. |
| `python creature_reduire.py grille <image repeinte.png>` | Dit si la grille de 8 pixels est retombée après la repeinte, et la hauteur de la silhouette. |
| `python creature_compose.py <figure.png> <fond.png> <préfixe> [--dx N] [--dy N] [--ombre-peinte]` | Détoure une créature générée sur fond uni et la pose sur un fond de la même taille. Écrit `<préfixe>_assemblage.png`, la silhouette (une case par case de 8 pixels) et la bande de retouche. |
| `python creature_layers.py <préfixe> <assemblage.png> <fond.png> <aperçu.aseprite> [--sol 183] [--sprite <sprite.aseprite>] [--manche 1.3] [--bouclier]` | Met l'assemblage sur la grille Apollo et le sépare en calques : Décor, Ombre et raccord, puis la créature en Ombre, Robe, Os et Arme. `--sprite` écrit aussi la créature seule, sur fond transparent. `--bouclier` range un bouclier dans son propre calque, entre les Os et l'Arme. `--manche` sert à un manche épais : sa demi-largeur, en cases (2 pour le bâton du Squelette), et une lecture de ses reflets dans l'image source, que la grille arrondit au clair des os. La main qui le serre reste alors aux Os. Sans ces deux options, l'outil range comme pour la Faucheuse. |
| `python creature_lisere.py <créature.aseprite> [--calque Robe] [--couleur 819796] [--sol 183]` | Ajoute, ou recalcule, le calque « Liseré » tout en haut : un pixel de lumière sur le bord extérieur de la tenue, sauf en bas, près du sol. Le fichier est relu dans Aseprite, ses autres calques sont recopiés à l'identique (le script le vérifie), puis il est réécrit sur place. Pour toute créature, une fois son design validé : sur le sprite, puis sur l'aperçu. |
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
| `comfy_gen.py` | Le pilote de ComfyUI, en bibliothèque standard seulement : génération guidée (profondeur, contours, pose), libre, ou retouche d'une zone. |
| `bg_import.py` | L'étape 3 des fonds d'écran : alignement, mise sur la grille, découpage. Elle contient aussi la mise sur la grille commune à toute la chaîne, la lecture de la grille du LoRA et le nettoyage des pixels isolés. |
| `window_import.py` | Les fonds de fenêtre : mise sur la grille, un calque. |
| `pose.py` | Le dessin commun des guides de pose : le bonhomme OpenPose, avec ses couleurs par membre et la convention gauche-droite, et l'écriture des trois guides. |
| `creature_faucheuse_pose.py`, `creature_squelette_pose.py` | Les guides de pose de la Faucheuse et du Squelette : leurs points et leur équipement. |
| `fond_uni.py` | L'aplatissement d'un fond généré en un ou deux tons. |
| `creature_controle.py` | La planche du contrôle en situation d'une créature. |
| `creature_reduire.py` | La réduction d'une créature validée, et le contrôle de sa grille. |
| `creature_compose.py` | Le détourage d'une créature générée seule, et sa pose sur un fond. |
| `creature_layers.py` | La séparation d'une créature en calques complets, et son sprite sur fond transparent. Sa fonction `classify` connaît une créature en robe, avec des os et une arme à manche, et, avec `--bouclier`, un bouclier. |
| `creature_lisere.py` | Le calque de liseré de lumière d'une créature, posé sur un `.aseprite` déjà fait. |
| `aseprite_io.py`, `aseprite_build.lua`, `aseprite_verify.lua`, `aseprite_export.lua` | Le pont vers Aseprite : assemblage en mode indexé, aller-retour vérifié, contrôle des calques, relecture d'un fichier existant calque par calque. |

**À savoir :**
- **Les fonds sont rangés par thème** dans `../backgrounds/<thème>/` (`dungeon/`, `steampunk/`, `camp/`…), chacun avec ses fichiers annexes : image guide, cartes de guidage, source générée. Les fonds de fenêtre sont dans `../backgrounds/windows/<biome>/`, trois par biome.
- **Les créatures sont rangées par famille, puis par tier,** dans `../creatures/<famille>/tier_<n>/` : la Faucheuse est le Squelette de tier 3, dans `squelette/tier_3/`. Chaque dossier contient le sprite, un aperçu sur un fond, la figure générée brute, la figure corrigée et les guides de pose.
- **Chaque fond a son propre script de géométrie**, construit sur `scene.py`, avec `bg_plaza.py` et `bg_camp.py` pour modèles : un calque complet par objet, posé à sa profondeur. Le script de la scène ne décrit que ce qui lui est propre ; l'export, les contrôles et les cartes de guidage sont communs.
- **Le manifeste de la scène guide l'étape 3.** Il dit quels calques sont des surfaces (autorisés à laisser un vide quand on les masque), lesquels l'import doit ignorer, comme l'ombre tramée des bords de la salle, et quelles couleurs il ne doit pas utiliser. Pour le Squelette, ce sont les deux verts pâles d'Apollo : sans cette exclusion, l'ivoire des os vire au vert maladif.
- **Le fichier `dungeon_hall_detail.aseprite` a été découpé par une version plus ancienne de `bg_import.py`**, qui triait aussi les pixels par couleur. Relancer l'import le découperait selon la règle actuelle.
- **Les fichiers `_detail` de la salle, de la place et du campement ont été mis sur la grille avant la conversion perceptive** (en Lab, avec trame) utilisée pour le Squelette. Les réimporter changerait leurs couleurs.
