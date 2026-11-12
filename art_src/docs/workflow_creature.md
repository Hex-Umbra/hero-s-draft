# Produire une créature ou un personnage en pixel art

**État au 12/11/2026.** La méthode est encore en itération. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images. Un cas complet, de la première idée au sprite, est raconté dans [les exemples](exemples/).

## Le principe

**La créature est un sprite à part, sur fond transparent.** Le jeu la greffe sur un fond de fenêtre, choisi selon le biome (voir [le workflow des fonds](workflow_fond.md), § 2). Une créature ne se dessine donc qu'une fois, puis apparaît dans tous les décors.

**Tout part d'un brief, établi avec le propriétaire avant toute génération** (étape 1). On sait dès le premier tour quelle créature le générateur doit dessiner, dans quelle pose et avec quel équipement : c'est ce qui réduit le nombre de tours et de générations.

**Le brief relève d'abord le tier de la créature.** La créature suit la DA évolutive par tier, décrite dans le [document de direction artistique](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16. **Le tier fixe la richesse, jamais la taille :** la qualité et surtout le détail. Le prompt suit le tier (son vocabulaire est à l'étape 3) :
- une silhouette simple et peu d'accessoires pour un tier bas ;
- la matière, une pose qui menace et de petits accessoires au tier 3, le palier du milieu ;
- une tenue riche, une pose spectaculaire et une aura pour un tier haut.

La taille de la créature dans l'image se choisit pour sa lisibilité, créature par créature.

**Le cadrage est commun à toutes les créatures :**
- **La résolution :** toujours 128 × 192, générée à 1024 × 1536 (8 fois plus grande, pour la grille du LoRA). Le tier ne change pas la résolution.
- **La ligne de sol :** les pieds, ou le bas de la tenue, tombent sur la ligne y = 183. Ainsi, n'importe quelle créature tient sur n'importe quel fond.
- **Le liseré :** toutes les créatures portent un liseré de lumière d'un pixel, dans son propre calque. Il se pose en dernier, une fois le design validé, jamais dès le départ (étape 8).

## Les étapes

### 1. Établir le brief avec le propriétaire

Avant tout guide et toute génération, l'agent et le propriétaire fixent la créature par une session de questions.

**La session est une conversation, menée bloc par bloc :**
1. L'agent pose les questions d'un bloc, en un seul message.
2. Il écrit les réponses dans le brief, puis résume en quelques lignes la créature telle qu'il la comprend à ce stade.
3. On en discute jusqu'à être d'accord, et le brief suit chaque correction. Ensuite seulement, on passe au bloc suivant.
4. Après le dernier bloc, le propriétaire valide le brief complet. Le guide vient après.

**Bloc 1 — Identité**

| Question | Ce que la réponse décide |
|:---|:---|
| Quelle famille, et quel nom ? | Le dossier `<famille>/tier_<n>/` et le nom des fichiers |
| Quel tier ? | Le niveau de détail du prompt (voir le principe, plus haut) |
| Doit-elle rappeler une autre forme de sa famille ? | La cohérence de la lignée, comme les os ivoire du Squelette à la Faucheuse |
| Dans quel biome apparaît-elle ? | Les fonds du détourage et du contrôle (étapes 5 et 7) |

**Par défaut, la créature est nouvelle.** On ne repart d'une créature existante que sur instruction du propriétaire. On lui demande alors ce qu'on en garde : le design, l'équipement, les couleurs.

**Bloc 2 — Corps et pose**

| Question | Ce que la réponse décide |
|:---|:---|
| Est-elle humanoïde ? | Si oui, la pose se trace en OpenPose. Sinon, on explore d'abord sans guide (étape 3) |
| Une autre orientation que de face ? | Le guide et les mots du prompt. La vue de face est la préférence par défaut : la plus pratique et la plus logique pour le jeu |
| Quel geste ? Que fait chaque main ? | La place des poignets et de l'équipement dans le guide |
| Quelle taille dans le cadre, en part de la hauteur ? | La taille du guide. Elle oriente celle de la créature sans la tenir : le générateur déborde souvent de son guide |

**Bloc 3 — Équipement**

| Question | Ce que la réponse décide |
|:---|:---|
| Quelle arme, dans quelle main, tenue comment : plantée, levée, en travers ? | Son tracé en contours dans le guide, et `--manche` à l'étape 6 |
| Un bouclier ? De quelle forme, de quelle taille, à quel bras ? | Son tracé en contours, et `--bouclier` à l'étape 6 |
| D'autres accessoires, comme un casque, ou explicitement aucun ? | Le prompt et les exclusions : le générateur ajoute volontiers une armure |
| Dans quel état, et de quelle facture : brut, rouillé, ouvragé ? | Les variantes de prompt à essayer sur une graine retenue |

**Bloc 4 — Tenue, couleurs, style**

| Question | Ce que la réponse décide |
|:---|:---|
| Quelle tenue, en quelle matière, dans quel état ? Y a-t-il des mots à éviter ? | Les mots du prompt. Un seul mot peut changer le personnage : pour le Squelette, « tunic » donnait un moine, et « leather » un soldat |
| Quelles couleurs dominantes, pour le corps, la tenue et les accents ? | La phrase de palette, propre à la créature |
| Qu'est-ce qu'elle ne doit surtout pas être : Halloween, chibi, trop détaillée ? | Les exclusions propres à la créature |

**Le brief s'écrit dans `<nom>_brief.md`**, dans le dossier de la créature. N'importe qui, artiste ou session d'agent, peut reprendre la créature à partir de lui, sans refaire les tours déjà faits. Il continue de vivre après la session : chaque tour de génération s'ajoute au journal, et chaque décision de design corrige le bloc qu'elle touche.

```markdown
# Brief — <Nom> (<famille>, tier <n>)

**État :** en cours | design validé le <date>

## 1. Identité
## 2. Corps et pose
## 3. Équipement
## 4. Tenue, couleurs, style
(dans chaque bloc : les réponses, puis le résumé validé)

## Le prompt en cours
Le prompt, les exclusions, le script de guide et ses réglages.

## Le journal des tours
| Tour | Variantes | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|
```

### 2. Tracer le guide

Une silhouette pleine en guide ne marche pas : le générateur copie les aplats, perd le détail et prend une forme simple pour autre chose. **Le geste se donne en OpenPose**, le bonhomme en bâtons que ControlNet Union sait lire. **L'équipement se donne en contours**, tracé à part.

1. **Écrire un script neuf, `creature_<nom>_pose.py`,** d'après les blocs 2 et 3 du brief : un script par créature, comme son brief. Il ne reprend la pose d'aucune autre créature, et ne contient que ce qui lui est propre :
   - les 18 points du corps, en fractions de l'image. **La droite et la gauche sont celles du personnage :** quand il fait face au spectateur, sa droite est à gauche de l'image ;
   - l'arme, le bouclier ou l'attribut, tracés à part en contours, à leur forme et à leur taille voulues.

   Le reste vient de `pose.py`, commun à toutes les créatures : le dessin du bonhomme, avec les couleurs standard par membre, et l'écriture des trois guides, dont l'image de départ unie.
2. **Reprendre le geste du brief.** Une créature debout et droite reste figée : pour qu'elle menace, il faut un appui large, un buste penché vers le spectateur et l'arme armée.
3. **Garder la tête dégagée :** aucun bras ni objet ne passe devant le visage.
4. **Placer les pieds sur la ligne de sol** et garder toute la silhouette, équipement compris, dans l'image, à la taille fixée par le brief.
5. **Montrer le guide au propriétaire avant toute génération,** pose et équipement superposés, et le corriger jusqu'à son accord.

**Pour une créature non humanoïde,** il n'existe pas encore de guide : on passe à l'exploration sans guide de l'étape 3.

### 3. Chercher le design sous le guide

On génère en mode guidé, avec le prompt tiré du brief. **Le nombre d'images par tour baisse à mesure que le design se fixe :**
- six au premier tour, sur des graines neuves ;
- trois ou quatre quand on fait varier un design validé ;
- une ou deux pour une dernière correction.

L'agent annonce le nombre avant chaque tour, montre toutes les images, et le propriétaire choisit. On change une chose à la fois, et chaque tour s'inscrit au journal du brief.

| Réglage | Valeur |
|:---|:---|
| Pose | 0.85 |
| Contours de l'équipement | 0.55 |
| Profondeur | 0 |
| Denoise | 1.0 |
| Taille | 1024 × 1536 |

À 0.4, les contours gardent la place d'un objet mais pas sa forme : l'écu du Squelette n'était pas rond. **Ces réglages sont provisoires.** Une session dédiée doit les affiner, pour que la base de chaque génération reste la même et que seuls la créature et ses détails changent.

**Le gabarit du prompt**, à compléter dans cet ordre :

> dark fantasy pixel art of a grim, menacing **[créature]**, **[vocabulaire du tier]**, **[orientation et geste]**, **[tenue, matière, état]**, **[arme ou attribut]**, full body, isolated on a solid flat uniform pale ochre background, no texture, **[phrase de palette]**, 16-bit, crisp pixels

**Les exclusions de base** (`--exclure`), à compléter selon le tier et la créature :

> halloween, cute, scenery, landscape, ground details, parchment, paper texture, grunge, textured background, vignette, gradient background, stains

- « grim, menacing » éloigne le résultat du monstre de fête foraine.
- Les exclusions « halloween, cute » retirent le ton enfantin.
- Les exclusions de texture gardent le fond uni, dont dépend le détourage.

**Le vocabulaire du tier**, une liste provisoire, complétée à chaque créature :

| Tier | Ajouté au prompt | Ajouté aux exclusions | Trouvé sur |
|:---|:---|:---|:---|
| 1 | à trouver | | |
| 2 | (cartoonish stylized design:1.3), (low detail:1.2), chunky simple shapes, flat colors, simple shading | chibi, highly detailed, intricate, detailed anatomy, realistic proportions | Le Squelette, en cours |
| 3 | highly detailed, et la matière en mots : worn cloth texture, deep folds, frayed torn edges, highly detailed bones | cartoon, flat shading, simple shapes | La Faucheuse |
| 4 et 5 | à trouver | | |

**La phrase de palette ne colore que le corps et ses ombres, jamais la tenue.** Des couleurs citées sans dire sur quoi les poser habillent la créature : « teal greys » a donné au Squelette un haillon sarcelle pendant six tours, malgré l'exclusion des capes. Celle du Squelette : « muted cold colors, old ivory bones with cold slate blue shading and deep navy blue shadows, sparse warm rust accents ». La couleur de la tenue s'écrit avec la tenue, d'après le bloc 4 du brief.

**La pondération `(mots:1.3)`** donne plus de poids à un passage du prompt, dans la syntaxe de ComfyUI ; de 1.2 à 1.4 suffisent. Elle fait venir un élément que le générateur oublie, comme l'équipement du Squelette. **Le piège :** elle renforce aussi chaque adjectif du passage, et « large » a rendu les écus géants. La taille d'un objet se règle par le guide, jamais par un adjectif.

**Le geste et l'orientation du brief s'écrivent aussi en mots,** par exemple « front view, facing the viewer » ou « wide stance, leaning forward toward the viewer ». **On n'exclut jamais une orientation ni une pose :** une créature peut prendre n'importe quelle pose, et c'est le guide qui la tient.

**La façon de tenir une arme ou de se tenir ne s'obtient pas par le texte.** Le prompt place les objets, pas le geste : c'est le rôle du guide. On ajoute aux exclusions les objets que le générateur substitue volontiers à l'arme voulue (un bâton à la place d'une arme à long manche, par exemple), et « multiple weapons, extra blades » s'il en ajoute.

**Si le fond n'est pas uni, le code l'aplatit,** avec `fond_uni.py`. Le générateur peine à tenir un fond uni, et insister dans le prompt déforme le reste : l'écu du Squelette s'est allongé. L'outil traite un fond d'un ou deux tons, comme un fond ocre posé sur un sol bleu. Il n'a pas été essayé sur un fond rayé ou en halo.

**Une graine ne se garde qu'une fois un design validé,** pour en voir d'autres possibilités par petites modifications. Ce choix n'est pas encore la validation finale de l'étape 7. Jusque-là, chaque tour repart de graines neuves : le guide porte la composition, et le prompt s'affine avec le brief. Une graine gardée trop tôt fige sa composition avec ses défauts : relancée avec un prompt modifié, elle la garde au point d'ignorer « facing the viewer ». Avec une autre taille de toile, elle ne garde rien.

**Deux façons de faire varier un design validé :**
- **Plusieurs prompts sur sa graine,** chacun changeant une chose : six bâtons et écus de styles différents, pour le Squelette. `comfy_gen.py` nomme ses images par préfixe, graine et denoise : on renomme chaque image avant de lancer la suivante, sinon elle est écrasée.
- **L'img2img :** l'image retenue devient l'image de départ. On la copie en `<préfixe>_base.png`, à côté des guides de pose et de contours, puis on génère avec `--guide base`, un denoise de 0.6 à 0.7 et des graines neuves. La composition reste, les détails changent.

**Sans guide, pour un brief ouvert ou une créature non humanoïde.** On commence par explorer en génération libre (`--libre`, à 1024 × 1536, avec le LoRA à 0.8), avec le même gabarit et le même nombre d'images par tour. On part général, le type de créature et le ton, puis on précise à chaque tour ce qu'on a aimé. Pour une créature humanoïde, on trace le guide dès que le design est trouvé (étape 2), puis on continue sous le guide.

### 4. Vérifier l'anatomie, et corriger

**Compter les membres, les mains et les armes.** Le générateur en ajoute volontiers un. Il laisse aussi une trace de ce qu'on retire : une manche vide, une moitié de main.

On corrige sur l'image source, en gardant toujours l'originale à côté (`<nom>_figure_brute.png`) :
- **Pour une petite forme posée sur un fond propre,** recopier la bande propre juste à côté. Si cette bande est penchée, compenser son décalage.
- **Pour retirer un pan entier :**
  1. Retailler la forme **par le code** : tracer le nouveau bord, et remettre du fond au-delà.
  2. Laisser ComfyUI ne retoucher **qu'une bande étroite le long de ce bord**, en mode retouche, avec un denoise d'environ 0.55. Faire trois graines et choisir.
- **À ne pas faire : donner à ComfyUI toute la zone à repeindre.** Il reconstruit la forme d'origine, en suivant ce qu'il voit autour.

Après chaque correction, on revérifie l'anatomie sur l'image entière.

### 5. Détourer et poser sur un fond

Avec `creature_compose.py`, sur un fond de fenêtre du biome visé. On lui donne la source du fond, en 1024 × 1536 (`<biome>_window_<n>_comfy_source.png`), pas son `.aseprite`. Tant qu'un biome n'a pas ses fonds, on prend ceux de la forêt.
- **Le détourage se fait case par case**, sur les cases de 8 pixels du LoRA. Chaque case est comparée au fond local, mesuré autour d'elle.
- **Les petits trous fermés sont bouchés.** Un grand espace fermé par la créature reste du fond, comme l'intérieur d'une anse ou l'espace entre un bras et le corps.
- **`--dy` aligne la créature sur la ligne de sol**, en multiple de 8 pixels. Une première passe sans `--dy` écrit la silhouette (`<préfixe>_silhouette.png`, une case par pixel du sprite). On y lit r, la dernière rangée des pieds, et `--dy` vaut (183 − r) × 8. Une ombre peinte descend sous les pieds : r se lit sur les pieds, pas sur l'ombre.
- **`--ombre-peinte`** sert quand le générateur a peint l'ombre au sol avec la créature. Sinon, le code en pose une. **Sans ombre peinte, le sprite livré n'a pas d'ombre :** celle du code ne va que dans l'aperçu.

**Une question ouverte, le raccord au sol.** Le bas d'une créature doit paraître posé sur le sol de n'importe quel biome, et chaque fond doit pouvoir accueillir n'importe quelle créature. Ce raccord touche les deux à la fois, comme la position où poser la créature sur chaque fond. Il sera travaillé avec le workflow des fonds et des biomes.

**À contrôler :** la silhouette détourée, sur un fond de couleur vive. Il ne doit rester aucune tache du fond uni, et aucune partie fine ne doit manquer (doigts, arme, lambeaux).

### 6. Ramener sur la grille et séparer en calques

Avec `creature_layers.py ... --sol 183 --sprite <nom>.aseprite`. On obtient deux fichiers :
- **le sprite seul**, sur fond transparent : c'est le livrable ;
- **un aperçu**, la créature posée sur le fond.

Les calques suivent la règle commune : chaque calque est un objet complet, complété sous ceux qui le couvrent.

**La séparation en calques dépend de la forme de la créature.** La fonction `classify` de `creature_layers.py` ne connaît pour l'instant qu'une forme : une créature en robe ou en vêtements, avec des os, une arme à manche et, au besoin, un bouclier. Elle range les cases en Ombre, Robe, Os, Bouclier (avec `--bouclier`) et Arme. `--manche` règle l'épaisseur du manche, pour un bâton plus large qu'une faux. Pour une créature d'une autre forme (une bête, un golem, un personnage en armure), il faut lui écrire ses propres règles avant cette étape. Deux principes, appris en route :
- **Une couleur ne suffit pas.** Sur la grille Apollo, des matières différentes tombent sur les mêmes gris. On combine la couleur avec la forme : une droite pour un manche, une tache reliée à l'arme pour une lame.
- **En cas de doute, regarder l'image source.** Elle garde des nuances que la grille a fondues ensemble.

**À contrôler :** chaque calque seul, sur un fond de couleur vive. Il ne doit y avoir aucun morceau d'un objet rangé dans le calque d'un autre, et aucun objet coupé en deux.

### 7. Contrôler en situation, puis faire valider le design

Greffer le sprite sur les trois fonds de son biome, puis le poser dans le cadre de son tier, sur l'écran de combat, à côté des créatures des autres tiers. La planche se fait en une commande :

`python creature_controle.py <sprite.aseprite> <tier> <planche.png> --voisins <autres sprites>`

- **Les fonds sont ceux de la forêt** par défaut ; `--fonds` en nomme d'autres.
- **Le cadre est tracé par `frame_tier.py`.** Sa fenêtre fait 64 × 96, la moitié du sprite : il est agrandi deux fois pour l'accueillir.
- **Le calque Liseré est masqué**, sauf avec `--avec-lisere`.
- **La planche ne montre pas l'écran de combat entier :** le cadre y tient lieu de l'écran.

Trois questions :
- La silhouette se détache-t-elle de chaque fond ?
- Les pieds tombent-ils sur le sol ?
- Le tier se lit-il, par le détail ?

Ce contrôle se fait **sans liseré** : il juge le design seul. Tant que le propriétaire ne l'a pas validé, on revient aux étapes précédentes. **Si la créature paraît trop grande devant son fond,** on la réduit (voir [Réduire une créature validée](#réduire-une-créature-validée)).

### 8. Ajouter le liseré, une fois le design validé

Toutes les créatures reçoivent un liseré de lumière d'un pixel sur le bord extérieur de leur tenue. **Il vient à la fin des générations initiales, quand le design est validé**, jamais dès le départ.

`python creature_lisere.py <sprite.aseprite>`, puis la même commande sur l'aperçu :
- **Il vit dans son propre calque, « Liseré »,** tout en haut, et se masque d'un clic. C'est un effet stylisé, voulu : la seule lumière de la chaîne qui ne soit pas cuite dans son objet.
- **Il est gris clair** (`#819796`, un gris d'Apollo) et borde le haut et les côtés de la tenue. Le bas, qui touche le sol, n'en reçoit pas.
- **Le calque de la tenue est `Robe` par défaut.** Pour une créature d'une autre forme, `--calque` nomme le sien.

Le liseré détache aussi la tenue des fonds sombres du biome. L'autre piste, recolorer la tenue dans une teinte que les fonds n'ont pas, a été écartée le 10/11/2026 : elle change le personnage (voir [l'exemple de la Faucheuse](exemples/creature_faucheuse.md)).

### 9. Retoucher dans Aseprite

On reprend à la main les fragments mal rangés, les bords et les détails que la grille a perdus.

**Si la retouche change le bord de la tenue,** on relance `creature_lisere.py`. Il relit le fichier dans Aseprite, garde les retouches et recalcule le liseré.

## Réduire une créature validée

Une créature validée peut paraître trop grande devant son fond. **On ne la régénère pas avec un guide plus petit :** le générateur déborde de son guide (la Faucheuse occupe 95 % de la hauteur pour un guide de 62 %), et il remplit la place libérée avec ce qu'il veut, comme un second squelette. On réduit la figure retenue, puis on la fait repeindre légèrement :

1. **Réduire la figure et ses guides** autour du milieu des pieds, qui ne bouge pas :
   `python creature_reduire.py reduire <figure.png> <préfixe des guides> <préfixe de sortie> <facteur> --ancre X,Y`
2. **La faire repeindre** par `comfy_gen.py`, sur sa graine et avec son prompt, en `--guide base` et à un denoise de 0.35. La repeinte rend au pixel art sa grille.
3. **Vérifier que la grille est retombée** sur 8 pixels : `python creature_reduire.py grille <image repeinte>`. Pour le Squelette, à 70 % et 0.35, elle l'était ; à 80 % et 0.35, non.

On essaie plusieurs facteurs, et le propriétaire choisit. L'image retenue devient la figure brute, et la version pleine taille va aux archives. La suite reprend à l'étape 4.

## Le dossier d'une créature

**Les créatures sont rangées par famille, puis par tier :** `art_src/creatures/<famille>/tier_<n>/`. Une famille regroupe les formes d'une même créature d'un tier à l'autre : la Faucheuse est le Squelette de tier 3, dans `squelette/tier_3/`. Les fichiers portent le nom de la forme, `<nom>` (`squelette`, `squelette_faucheuse`) :

| Fichier | Rôle |
|:---|:---|
| `<nom>_brief.md` | Le brief : les réponses du propriétaire, le prompt en cours et le journal des tours |
| `<nom>.aseprite` | Le sprite, sur fond transparent : le livrable. Ses calques : Ombre, Robe, Os, Bouclier s'il en a un, Arme, puis Liseré une fois le design validé |
| `<nom>_<biome>.aseprite` | Un aperçu de la créature posée sur un fond de son biome |
| `<nom>_figure_brute.png` | La dernière génération, intacte : celle d'où la figure est tirée. Quand la figure vient d'une réduction ou d'une variation, c'est l'image repeinte ; les générations d'avant vont aux archives |
| `<nom>_figure.png` | L'image corrigée, d'où le sprite est tiré |
| `<nom>_pose.png`, `<nom>_pose_<objet>.png` | Les guides de génération |

Le script de pose, un par créature, va dans `art_src/tools/creature_<nom>_pose.py`, à côté de `pose.py` qu'il importe. Les fichiers de travail restent dans `art_src/tools/.work/`, que git ignore.

**On ne supprime rien :** une version remplacée ou un essai abandonné va dans les archives (voir les règles communes du [README des outils](../tools/README.md)).
