# Produire une créature ou un personnage en pixel art

**État au 10/11/2026.** La méthode est encore en itération. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images. Un cas complet, de la première idée au sprite, est raconté dans [les exemples](exemples/).

## Le principe

**La créature est un sprite à part, sur fond transparent.** Le jeu la greffe sur un fond de fenêtre, choisi selon le biome (voir [le workflow des fonds](workflow_fond.md), § 2). Une créature ne se dessine donc qu'une fois, puis apparaît dans tous les décors.

**On commence par relever le tier de la créature.** La créature suit la DA évolutive par tier, décrite dans le [document de direction artistique](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16. **Le tier fixe la richesse, jamais la taille :** la qualité et surtout le détail. Le prompt suit le tier :
- une silhouette simple et peu d'accessoires pour un tier bas ;
- la matière, une pose qui menace et de petits accessoires au tier 3, le palier du milieu ;
- une tenue riche, une pose spectaculaire et une aura pour un tier haut.

La taille de la créature dans l'image se choisit pour sa lisibilité, créature par créature.

**Le cadrage est commun à toutes les créatures :**
- **La résolution :** toujours 128 × 192, générée à 1024 × 1536 (8 fois plus grande, pour la grille du LoRA). Le tier ne change pas la résolution.
- **La ligne de sol :** les pieds, ou le bas de la tenue, tombent sur la ligne y = 183. Ainsi, n'importe quelle créature tient sur n'importe quel fond.
- **Le liseré :** toutes les créatures portent un liseré de lumière d'un pixel, dans son propre calque. Il se pose en dernier, une fois le design validé, jamais dès le départ (étape 7).

## Les étapes

### 1. Explorer le design, sans guide

On génère librement, en trois graines par tour. On commence général (le type de créature, le ton dark fantasy, un décor libre), puis on précise à chaque tour ce qu'on a aimé, une chose à la fois. On garde la graine d'une image qu'on aime : relancée avec le prompt modifié, elle garde souvent sa composition.

**Le gabarit du prompt**, à compléter dans cet ordre :

> dark fantasy pixel art of a grim, menacing **[créature]**, full body, **[tenue, matière, état]**, **[arme ou attribut]**, isolated on a solid flat uniform pale ochre background, no texture, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust and old ivory bone, 16-bit, crisp pixels, highly detailed

**Les exclusions de base** (`--exclure`), à compléter selon la créature :

> halloween, cartoon, cute, scenery, landscape, ground details, flat shading, simple shapes, parchment, paper texture, grunge, textured background, vignette, gradient background, stains

- « grim, menacing » éloigne le résultat du monstre de fête foraine.
- Les exclusions « halloween, cartoon, cute » retirent le ton enfantin.
- Les exclusions de texture gardent le fond uni, dont dépend le détourage.

**La façon de tenir une arme ou de se tenir ne s'obtient pas par le texte.** Le prompt place les objets, pas le geste : c'est le rôle de l'étape 2. On ajoute aux exclusions les objets que le générateur substitue volontiers à l'arme voulue (un bâton à la place d'une arme à long manche, par exemple), et « multiple weapons, extra blades » s'il en ajoute.

### 2. Imposer la pose par un guide OpenPose

Une silhouette pleine en guide ne marche pas : le générateur copie les aplats, perd le détail et prend une forme simple pour autre chose. **Le geste se donne en OpenPose**, le bonhomme en bâtons que ControlNet Union sait lire.

1. **Écrire `creature_<id>_pose.py`** en copiant un script de pose existant. On y place :
   - les 18 points du corps, en fractions de l'image, avec leurs couleurs standard par membre ;
   - l'arme ou l'attribut, s'il y en a un, tracé à part en contours ;
   - une image de départ unie.
2. **Choisir un geste qui menace.** Une créature debout et droite reste figée. Il faut un appui large, un buste penché vers le spectateur et l'arme armée.
3. **Garder la tête dégagée :** aucun bras ni objet ne passe devant le visage.
4. **Placer les pieds sur la ligne de sol** et garder toute la silhouette, arme comprise, dans l'image.
5. **Générer** en mode guidé, avec trois graines :

   | Réglage | Valeur |
   |:---|:---|
   | Pose | 0.85 |
   | Contours de l'arme | 0.4 |
   | Profondeur | 0 |
   | Denoise | 1.0 |
   | Taille | 1024 × 1536 |

   Ajouter au prompt le geste en mots, par exemple « wide stance, leaning forward toward the viewer, three-quarter view ». Ajouter aux exclusions « standing still, symmetrical, front view ».

**Si le fond n'est pas uni,** on relance la même graine avec le même guide, en insistant sur le fond dans le prompt et les exclusions. La pose est tenue par le guide, elle ne bouge pas.

### 3. Vérifier l'anatomie, et corriger

**Compter les membres, les mains et les armes.** Le générateur en ajoute volontiers un. Il laisse aussi une trace de ce qu'on retire : une manche vide, une moitié de main.

On corrige sur l'image source, en gardant toujours l'originale à côté (`<id>_figure_brute.png`) :
- **Pour une petite forme posée sur un fond propre,** recopier la bande propre juste à côté. Si cette bande est penchée, compenser son décalage.
- **Pour retirer un pan entier :**
  1. Retailler la forme **par le code** : tracer le nouveau bord, et remettre du fond au-delà.
  2. Laisser ComfyUI ne retoucher **qu'une bande étroite le long de ce bord**, en mode retouche, avec un denoise d'environ 0.55. Faire trois graines et choisir.
- **À ne pas faire : donner à ComfyUI toute la zone à repeindre.** Il reconstruit la forme d'origine, en suivant ce qu'il voit autour.

Après chaque correction, on revérifie l'anatomie sur l'image entière.

### 4. Détourer et poser sur un fond

Avec `creature_compose.py`, sur un fond de fenêtre du biome visé.
- **Le détourage se fait case par case**, sur les cases de 8 pixels du LoRA. Chaque case est comparée au fond local, mesuré autour d'elle.
- **Les petits trous fermés sont bouchés.** Un grand espace fermé par la créature reste du fond, comme l'intérieur d'une anse ou l'espace entre un bras et le corps.
- **`--dy` aligne la créature sur la ligne de sol**, en multiple de 8 pixels.
- **`--ombre-peinte`** sert quand le générateur a peint l'ombre au sol avec la créature. Sinon, le code en pose une.

**À contrôler :** la silhouette détourée, sur un fond de couleur vive. Il ne doit rester aucune tache du fond uni, et aucune partie fine ne doit manquer (doigts, arme, lambeaux).

### 5. Ramener sur la grille et séparer en calques

Avec `creature_layers.py ... --sol 183 --sprite <id>.aseprite`. On obtient deux fichiers :
- **le sprite seul**, sur fond transparent : c'est le livrable ;
- **un aperçu**, la créature posée sur le fond.

Les calques suivent la règle commune : chaque calque est un objet complet, complété sous ceux qui le couvrent.

**La séparation en calques dépend de la forme de la créature.** La fonction `classify` de `creature_layers.py` ne connaît pour l'instant qu'une forme : une créature en robe, avec des os et une arme à manche. Elle range les cases en Ombre, Robe, Os et Arme. Pour une créature d'une autre forme (une bête, un golem, un personnage en armure), il faut lui écrire ses propres règles avant cette étape. Deux principes, appris en route :
- **Une couleur ne suffit pas.** Sur la grille Apollo, des matières différentes tombent sur les mêmes gris. On combine la couleur avec la forme : une droite pour un manche, une tache reliée à l'arme pour une lame.
- **En cas de doute, regarder l'image source.** Elle garde des nuances que la grille a fondues ensemble.

**À contrôler :** chaque calque seul, sur un fond de couleur vive. Il ne doit y avoir aucun morceau d'un objet rangé dans le calque d'un autre, et aucun objet coupé en deux.

### 6. Contrôler en situation, puis faire valider le design

Greffer le sprite sur les trois fonds de son biome, puis le poser dans le cadre de son tier, sur l'écran de combat, à côté des créatures des autres tiers. Trois questions :
- La silhouette se détache-t-elle de chaque fond ?
- Les pieds tombent-ils sur le sol ?
- Le tier se lit-il, par le détail ?

Ce contrôle se fait **sans liseré** : il juge le design seul. Tant que le propriétaire ne l'a pas validé, on revient aux étapes précédentes.

### 7. Ajouter le liseré, une fois le design validé

Toutes les créatures reçoivent un liseré de lumière d'un pixel sur le bord extérieur de leur tenue. **Il vient à la fin des générations initiales, quand le design est validé**, jamais dès le départ.

`python creature_lisere.py <sprite.aseprite>`, puis la même commande sur l'aperçu :
- **Il vit dans son propre calque, « Liseré »,** tout en haut, et se masque d'un clic. C'est un effet stylisé, voulu : la seule lumière de la chaîne qui ne soit pas cuite dans son objet.
- **Il est gris clair** (`#819796`, un gris d'Apollo) et borde le haut et les côtés de la tenue. Le bas, qui touche le sol, n'en reçoit pas.
- **Le calque de la tenue est `Robe` par défaut.** Pour une créature d'une autre forme, `--calque` nomme le sien.

Le liseré détache aussi la tenue des fonds sombres du biome. L'autre piste, recolorer la tenue dans une teinte que les fonds n'ont pas, a été écartée le 10/11/2026 : elle change le personnage (voir [l'exemple de la Faucheuse](exemples/creature_faucheuse.md)).

### 8. Retoucher dans Aseprite

On reprend à la main les fragments mal rangés, les bords et les détails que la grille a perdus.

**Si la retouche change le bord de la tenue,** on relance `creature_lisere.py`. Il relit le fichier dans Aseprite, garde les retouches et recalcule le liseré.

## Le dossier d'une créature

Dans `art_src/creatures/<id>/` :

| Fichier | Rôle |
|:---|:---|
| `<id>.aseprite` | Le sprite, sur fond transparent : le livrable. Ses calques : Ombre, Robe, Os, Arme, puis Liseré une fois le design validé |
| `<id>_<biome>.aseprite` | Un aperçu de la créature posée sur un fond de son biome |
| `<id>_figure_brute.png` | L'image générée, intacte |
| `<id>_figure.png` | L'image corrigée, d'où le sprite est tiré |
| `<id>_pose.png`, `<id>_pose_<objet>.png` | Les guides de génération |

Le script de pose va dans `art_src/tools/creature_<id>_pose.py`. Les fichiers de travail restent dans `art_src/tools/.work/`, que git ignore.

**On ne supprime rien :** une version remplacée ou un essai abandonné va dans les archives (voir les règles communes du [README des outils](../tools/README.md)).
