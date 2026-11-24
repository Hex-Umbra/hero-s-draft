# Exemple — la Faucheuse (créature de tier 3)

Le parcours complet de la première créature produite par [le workflow des créatures](../workflow_creature.md), les 09 et 10/11/2026 : les tours de génération, les prompts exacts, les graines, les corrections et ce que chaque échec a appris. Les fichiers sont dans `art_src/sprites/squelette/tier_3/` : la Faucheuse est le Squelette de tier 3.

## Le point de départ

On voulait un squelette plus détaillé que le Squelette de tier 2, dans l'esprit dark fantasy, avec un décor qui lui soit propre. Le propriétaire a demandé de rester général au départ, puis de préciser tour après tour, en choisissant à chaque fois parmi trois images.

## L'exploration du design, sans guide

Tout se fait en génération libre, en 1024 × 1536, avec le LoRA à 0.8.

| Tour | Ce qui change | Ce qui en sort |
|:---|:---|:---|
| 1 | Prompt général : *undead skeleton, full body, in its own detailed dark fantasy environment*, avec la phrase de palette | Des squelettes d'Halloween, dont un avec des citrouilles. Le meilleur décor est la graine 391766 : forêt et pleine lune. |
| 2 | + « grim, menacing undead » ; exclus : halloween, cartoon, cute, plain background | Des morts-vivants en lambeaux. Graine 683914 : une faucheuse encapuchonnée avec un bâton. Graine 86376 : une forêt profonde très détaillée. |
| 3 | + « hooded in a tattered dark robe », « a dense dark forest… » ; exclus : fog, mist, haze | Les deux idées réunies, et la brume en moins, ce qui rend le détail net. |

**La décision qui en est sortie :** la créature et le décor deviennent deux assets séparés, générés chacun de leur côté. Le jeu greffera l'une sur l'autre. Le décor est raconté dans [l'exemple des fonds forêt](fonds_fenetre_foret.md).

## La créature seule

| Tour | Méthode | Résultat |
|:---|:---|:---|
| 1 | Libre, sur fond uni gris-bleu, « holding a large curved scythe with both hands » | Les faucheuses ne tiennent la faux que d'une main, et le fond est trop proche du bleu de la robe pour un détourage net. |
| 2 | Guidé par une silhouette pleine (robe, capuche, crâne, ovale des côtes, faux en diagonale, deux mains), denoise 0.85, contours 0.5, profondeur 0.45 | **Échec.** Les aplats donnent des aplats : le détail disparaît, et l'ovale des côtes devient un second crâne. |
| 3 | Le guide réduit au geste (plus d'ovale), denoise 1.0, contours 0.35, profondeur 0.3 | Les deux mains tiennent la faux et le détail revient. Graine 696174 retenue… |
| — | Le propriétaire n'est pas satisfait | Elle est trop grande dans le cadre, la pose est figée et la robe est plate. |
| 4 | La silhouette plus petite (70 % de la hauteur), de trois quarts, la faux levée, plus « deep folds, frayed torn edges » | La taille et la robe sont réglées. **La pose reste raide**, parce qu'elle copie la raideur du guide. |
| 5 | **Guide OpenPose** (pose 0.85), la faux en contours (0.4), sans profondeur, prompt « attacking, mid-swing… » | La pose est enfin vivante. **Graine 53724 retenue** par le propriétaire « sans hésitation ». Mais sans guide de profondeur, le fond est devenu un parchemin tacheté. |
| 6 | Même graine, même guide, + « solid flat uniform background, no texture » ; exclus : parchment, grunge, textured background, vignette, gradient background, stains | Le fond est uni, gris-vert, légèrement dégradé, et la pose est identique. |

### Le prompt final (tour 6, graine 53724)

> dark fantasy pixel art of a grim, menacing undead skeleton reaper attacking, full body, small in frame, mid-swing, winding up a large curved scythe held back with both bony hands, wide stance, leaning forward toward the viewer, three-quarter view, hooded in a tattered dark navy robe with deep folds, frayed torn edges flaring with the motion, worn cloth texture, highly detailed bones, visible skull and ribcage, isolated on a solid flat uniform pale ochre background, no texture, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust and old ivory bone, 16-bit, crisp pixels, highly detailed

**Exclusions :**

> halloween, cartoon, cute, staff, walking stick, multiple weapons, sword, extra blades, scenery, landscape, trees, forest, ground details, flat shading, simple shapes, standing still, symmetrical, front view, flat robe, parchment, paper texture, grunge, textured background, vignette, gradient background, stains

**Commande :** `python creature_faucheuse_pose.py .work/faucheuse_pose5`, puis :

`python comfy_gen.py .work/faucheuse_pose5 "<prompt>" --sujet --exclure "<exclusions>" --guide guide --size 1024x1536 --seed 53724 --denoise 1.0 --pose 0.85 --edges 0.4 --depth 0 --lora 0.8`

## Le détourage et les calques

- **Le fond « uni » ne l'était pas :** une zone plus claire, en haut à gauche, restait collée à la silhouette. C'est ce qui a conduit au détourage par fond local, où chaque case est comparée au fond mesuré autour d'elle.
- **La flaque d'ombre peinte touchait le bord bas.** On a remonté la créature de deux cases (`--dy -16`) et gardé cette ombre peinte (`--ombre-peinte`).
- **Le manche, dans l'ombre, devenait gris** sur la grille Apollo, et se retrouvait rangé dans la robe. On le suit maintenant le long de sa droite jusqu'au sol, quelle que soit sa couleur.
- **L'acier de la lame et la capuche tombent sur le même gris** une fois sur la grille. La lame se repère donc dans l'image source.

`python creature_compose.py <figure> <fond forêt 1> .work/faucheuse6 --dy -16 --ombre-peinte`

`python creature_layers.py .work/faucheuse6 .work/faucheuse6_assemblage.png <fond forêt 1> squelette_faucheuse_foret.aseprite --sol 183 --sprite squelette_faucheuse.aseprite`

**Ces deux commandes sont celles de l'époque.** La créature était alors posée sur un fond avant d'être mise sur la grille, et sa grille était lue sur ce fond. Depuis le 12/11/2026, elle est détourée seule et sa grille se lit sur elle-même :

`python creature_detour.py <figure> .work/faucheuse --ombre-peinte --pieds 185`

`python creature_squelette_layers.py .work/faucheuse squelette_faucheuse.aseprite --apercu <fond forêt 1, en .aseprite> squelette_faucheuse_foret.aseprite`

Refaite ainsi, la Faucheuse garde sa silhouette et ses calques, mais 7 % de ses cases changent de nuance : la grille n'est plus lue au même pixel près. Le sprite commité reste celui de l'époque.

## Les corrections d'anatomie

**Un troisième bras.** Sous le bras qui tient la faux, un avant-bras sortait du milieu de la robe pour serrer le manche une seconde fois. Le propriétaire l'a repéré sur le sprite fini.
- **Ce qui a été fait :** la zone (un polygone autour de l'avant-bras et de la main, vers x 600-770 et y 740-800) a été remplacée par la bande propre 65 pixels plus bas.
- **Le décalage du manche :** il penche, donc sa partie de la zone a été recopiée avec 6 pixels de décalage, pour qu'il reste continu.

**Puis la manche de ce bras.** Vide, la manche tombante se lisait encore comme un bras.
- **Premier essai, raté :** faire repeindre toute la zone par ComfyUI (denoise 0.8, trois graines). À chaque fois, il reconstruisait une manche, et ajoutait des bandes vertes lumineuses ou un panneau plat avec une ceinture.
- **Ce qui a marché :**
  1. Un nouveau bord de robe tracé par le code, en biais de l'aisselle (556, 752) jusqu'au bas de la robe (600, 960), avec le fond recopié au-delà.
  2. Une retouche de ComfyUI limitée à une bande de ±20 pixels le long de ce bord, en mode `--retouche`, denoise 0.55, graine 22 retenue sur trois.

La figure générée intacte est gardée sous le nom `squelette_faucheuse_figure_brute.png`. Le sprite est tiré de `squelette_faucheuse_figure.png`, l'image corrigée.

## La suite, le 10/11/2026

### Une régénération à la taille du tier 3, abandonnée

La DA évolutive fixait alors une limite de taille par tier : 70 % de la hauteur au tier 3. La Faucheuse en occupait 95 %, faux levée comprise. On l'a régénérée avec le même prompt, les mêmes exclusions et le même guide de pose.

| Tour | Méthode | Résultat |
|:---|:---|:---|
| 1 | Le guide réduit à 0,73 dans le cadre de 1024 × 1536, mêmes réglages qu'au tour 6. Graines 53724, 784142 et 189881 | Le corps suit le guide, mais **le générateur remplit l'espace libéré** : un second squelette au-dessus, un crâne géant, une faux qui couvre tout. Les trois dépassent 95 % |
| 2 | Le guide d'origine, sur une toile de 768 × 1152, posée sans redimensionnement dans le cadre (décalage multiple de 8) | La taille tombe entre 48 et 60 %. **Graine 389679 :** fond uni, le design de la Faucheuse, mais une seconde lame, fantôme, au-dessus de la vraie. Les deux autres ont un fond rayé ou en halo |
| 3 | Des variations de 389679 en img2img : l'image en guide, denoise 0.6, trois graines | La composition reste. **Graine 339193 retenue**, la plus proche et avec le moins de défauts. La lame fantôme reste sur les trois |

La lame fantôme, isolée sur un fond propre, a été recouverte par la bande de fond prise 48 pixels plus bas. Le sprite tiré de là fait 58 % de la hauteur.

**Pourquoi c'est abandonné :** posée à côté de l'originale, cette Faucheuse a été jugée bien moins cohérente. Le propriétaire a renoncé aux limites de taille par tier : seuls la qualité et le détail marquent le tier ([direction artistique](../../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.1). L'originale reste en place. L'essai est rangé dans `art_src/archives/sprites/squelette/tier_3/2026-11-10_essai_tier3/`.

**Ce que l'essai a appris :**
- **Le générateur déborde de son guide.** La Faucheuse d'origine occupe 95 % de la hauteur pour un guide qui n'en couvre que 62 %. Sa faux ne suit pas le tracé en contours : il l'a dressée au-dessus de la tête.
- **Un guide réduit laisse un vide, que le générateur remplit** avec ce qu'il veut.
- **Une toile plus petite réduit la créature sans brouiller le pixel art.** Le LoRA garde des cases de 8 pixels à 768 × 1152, et l'image se pose telle quelle dans le cadre.

### La robe se détache par un liseré

**Pourquoi elle se perdait :** sur la grille Apollo, la robe est peinte dans la rampe gris-sarcelle (indices 37 à 41), celle des forêts. Ses deux tons principaux couvrent à eux seuls 44 % des trois fonds.

Les deux pistes du workflow ont été montrées sur les trois fonds :
- **Recolorer la robe** dans une rampe absente des forêts : le bleu marine (indices 0 à 3) ou le violet (30 à 33). La robe ressort, mais le personnage change.
- **Un liseré de lumière** d'un pixel, gris clair (indice 42), sur le haut et les côtés de la robe.

**Le liseré est retenu**, dans son propre calque, pour son côté stylisé : 425 pixels, le même sur le sprite et sur l'aperçu. Le propriétaire l'a ensuite étendu à toutes les créatures, posé en dernier, une fois le design validé ([workflow](../workflow_creature.md), étape 8). Les versions sans liseré sont dans `art_src/archives/sprites/squelette/tier_3/2026-11-10_sans_lisere/`.

`python creature_lisere.py ../sprites/squelette/tier_3/squelette_faucheuse.aseprite`, puis la même commande sur `squelette_faucheuse_foret.aseprite`.

## Les fichiers

| Fichier | Contenu |
|:---|:---|
| `squelette_faucheuse.aseprite` | Le sprite, 128 × 192 : Ombre, Robe, Os, Arme, Liseré |
| `squelette_faucheuse_foret.aseprite` | L'aperçu sur le fond forêt 1, avec Décor dessous et Liseré dessus |
| `squelette_faucheuse_figure_brute.png` | La génération du tour 6, intacte |
| `squelette_faucheuse_figure.png` | La même, sans le troisième bras ni sa manche |
| `squelette_faucheuse_pose.png`, `squelette_faucheuse_edges.png` | Le guide OpenPose et la faux en contours |
| `art_src/tools/creature_faucheuse_pose.py` | Le script qui trace ces guides |
