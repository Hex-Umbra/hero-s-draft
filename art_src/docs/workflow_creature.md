# Produire une créature ou un personnage en pixel art

**État au 12/11/2026.** La méthode est encore en itération. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images. Un cas complet, de la première idée au sprite, est raconté dans [les exemples](exemples/).

**Ce workflow se lance par la commande `/workflow-creature`.** Le [skill](../../.claude/skills/workflow-creature/SKILL.md) le conduit étape par étape : il dit où s'arrêter, ce qu'on montre au propriétaire, et qui décide. Ce document, lui, dit comment faire.

## Le principe

**La créature est un sprite à part, sur fond transparent.** Le jeu la greffe sur un fond de fenêtre, choisi selon le biome (voir [le workflow des fonds de fenêtre](workflow_fond.md)). Une créature ne se dessine donc qu'une fois, puis apparaît dans tous les décors.

**Tout part d'un brief, établi avec le propriétaire avant toute génération** (étape 1). On sait dès le premier tour quelle créature le générateur doit dessiner, dans quelle pose et avec quel équipement : c'est ce qui réduit le nombre de tours et de générations.

**Le brief relève d'abord le tier de la créature.** La créature suit la DA évolutive par tier, décrite dans le [document de direction artistique](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16. **Le tier fixe la richesse, jamais la taille :** la qualité et surtout le détail. Le prompt suit le tier (son vocabulaire est à l'étape 3) :
- une silhouette simple et peu d'accessoires pour un tier bas ;
- la matière, une pose qui menace et de petits accessoires au tier 3, le palier du milieu ;
- une tenue riche, une pose spectaculaire et une aura pour un tier haut.

La taille de la créature dans l'image se choisit pour sa lisibilité, créature par créature.

**Le cadrage est commun à toutes les créatures :**
- **La résolution :** toujours 128 × 192, générée à 1024 × 1536 (8 fois plus grande, pour la grille du LoRA). Le tier ne change pas la résolution.
- **La ligne de sol :** les pieds, ou le bas de la tenue, tombent sur la ligne y = 183. Ainsi, n'importe quelle créature tient sur n'importe quel fond.
- **L'ombre :** toute créature a son ombre au sol, dans son propre calque, Ombre, tout en bas (décision du propriétaire du 13/11/2026). C'est celle que le générateur a peinte, ou, s'il n'en a pas peint, une bande sombre posée par le code (étape 6). Le calque se masque d'un clic : le jeu peut charger le sprite avec ou sans son ombre, selon le fond.
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
| Dans quel biome apparaît-elle ? | Les fonds de l'aperçu et du contrôle (étapes 6 et 7) |

**Par défaut, la créature est nouvelle.** On ne repart d'une créature existante que sur instruction du propriétaire. On lui demande alors ce qu'on en garde : le design, l'équipement, les couleurs.

**Bloc 2 — Corps et pose**

| Question | Ce que la réponse décide |
|:---|:---|
| Est-elle humanoïde ? | Si oui, la pose se trace en OpenPose. Sinon, on explore d'abord sans guide (étape 3) |
| Une autre orientation que de face ? | Le guide et les mots du prompt. La vue de face est la préférence par défaut : la plus pratique et la plus logique pour le jeu |
| Quel geste ? Que fait chaque main ? | La place des poignets et de l'équipement dans le guide |
| Quelle taille dans le cadre, en part de la hauteur ? | La taille du guide. Elle oriente celle de la créature sans la tenir : le générateur déborde souvent de son guide |

**Pour une créature non humanoïde,** le bloc 2 n'a pas encore de règle générale. Voici ce que le Rat géant a fixé (décisions du propriétaire du 13/11/2026), à reprendre comme précédent :
- **L'orientation.** Un quadrupède vu de profil remplit mal un cadre en hauteur. Le Rat est vu en plongée et avance presque de face vers le joueur. Le corps se raccourcit derrière la tête, et la silhouette tient dans le cadre. Le propriétaire avait dit « trois quarts » : on lui fait confirmer ce qu'il veut sur sa référence, parce que « three-quarter view » tourne nettement le corps.
- **La taille.** Elle se donne en part de la largeur et de la hauteur, pas de la hauteur seule : pour le Rat, environ 85 % de la largeur et 60 % de la hauteur, queue comprise.
- **Une image de référence** montrée par le propriétaire se décrit en mots dans le brief : la pose, le geste, ce qu'on garde et ce qu'on ne garde pas. Elle n'est pas versée au dépôt quand c'est l'œuvre de quelqu'un d'autre.

**Bloc 3 — Équipement**

| Question | Ce que la réponse décide |
|:---|:---|
| Quelle arme, dans quelle main, tenue comment : plantée, levée, en travers ? | Son tracé en contours dans le guide, et son mot dans la recette de calques (étape 6) |
| Un bouclier ? De quelle forme, de quelle taille, à quel bras ? | Son tracé en contours, et son mot dans la recette de calques (étape 6) |
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

## Après la génération
- Les corrections d'anatomie (étape 4) : ce qui a été retiré, et comment.
- La réduction, s'il y en a eu une : le facteur et l'ancre.
- Le détourage (étape 5) : `--pieds` ou `--dy`, et `--ombre-peinte`.
- Les calques (étape 6) : la recette, `<nom>_calques.json`, avec les mots retenus et ceux qui n'ont rien donné.
- Le liseré (étape 8) : le calque de la tenue.
```

**La dernière section sert à refaire le sprite sans rien deviner.** Sans elle, les réglages choisis après la génération ne sont écrits nulle part : le Squelette a été réduit à 70 % autour d'une ancre que seul un fichier de travail retenait.

**Le journal se remplit depuis les images.** Chaque image générée embarque son prompt, ses exclusions, sa graine et ses forces : `python comfy_meta.py lire <image.png>` les affiche.

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

**Pour une créature non humanoïde,** il n'y a pas de bonhomme OpenPose, mais **un guide en contours seuls tient la pose** (le Rat géant, 13/11/2026). Trois tours sans guide, soit 18 images, n'avaient donné ni la plongée ni le rat à quatre pattes : sur une toile en hauteur, le générateur dressait la bête pour la remplir. Le premier tour sous un guide en contours a tenu la pose sur six images sur six.
- **Le script trace la silhouette de la référence en formes simples** (ellipses et polygones, de l'arrière vers l'avant, chaque forme effaçant les contours qu'elle cache), puis écrit `_edges.png` et l'image de départ unie, sans `_pose.png` : voir `creature_rat_geant_pose.py`.
- **Le tour se lance avec `--creature --pose 0`** : un guide de force nulle n'est pas chargé, et les contours gardent leur force de 0.55.
- **Une forme tracée par ses deux bords peut se lire en double :** la queue du Rat, une bande fine, est sortie en deux queues sur deux images sur six. Le propriétaire a gardé l'idée ; ailleurs, une forme fine se trace d'un seul trait.
- **Les petits détails du guide ne pèsent pas :** la gueule ouverte et les incisives tracées sur le museau ne sont sorties sur aucune image.
### 3. Chercher le design sous le guide

On génère en mode guidé, avec le prompt tiré du brief. **Le nombre d'images par tour baisse à mesure que le design se fixe :**
- six au premier tour, sur des graines neuves ;
- trois ou quatre quand on fait varier un design validé ;
- une ou deux pour une dernière correction.

L'agent annonce le nombre avant chaque tour, montre toutes les images, et le propriétaire choisit. On change une chose à la fois, et chaque tour s'inscrit au journal du brief.

**Un tour se lance en une commande :**

`python comfy_gen.py <préfixe des guides> "<prompt>" --creature --graines 6 --exclure "<exclusions>"`

- **`--creature` pose tous les réglages du tableau.** Sans lui, `comfy_gen.py` prend ceux des fonds d'écran. Une option donnée à la main garde le dessus : `--edges 0.4`, par exemple.
- **`--graines N` tire N graines neuves.** `--seed` en accepte plusieurs, séparées par des virgules, pour rejouer des graines choisies.
- **Les images du tour sont réunies sur une planche,** chacune sous sa graine : c'est elle qu'on montre au propriétaire.

| Réglage | Valeur | Option |
|:---|:---|:---|
| Pose | 0.85, jusqu'à 80 % du débruitage | `--pose` |
| Contours de l'équipement | 0.55, jusqu'à 60 % du débruitage | `--edges` pour la force, `--edges-fin` pour la fin d'effet |
| Profondeur | 0 : pas utilisée | `--depth` |
| Denoise | 1.0 | `--denoise` |
| LoRA | 0.8 | `--lora` |
| Taille | 1024 × 1536 | `--size` |
| Échantillonnage | 30 pas, CFG 6.5, `dpmpp_2m` karras | fixé dans `comfy_gen.py` |

La fin d'effet de la pose est fixée dans `comfy_gen.py`, elle aussi ; celle des contours se règle par `--edges-fin`. À une force de 0.4, les contours gardent la place d'un objet mais pas sa forme : l'écu du Squelette n'était pas rond. **Ces réglages sont provisoires.** Une session dédiée doit les affiner, pour que la base de chaque génération reste la même et que seuls la créature et ses détails changent.

**Un premier essai, le 12/11/2026 : la taille de la toile.** Six graines du Squelette, à 1024 × 1536 puis à 832 × 1248, avec le même prompt et le même guide. Aucune des douze images n'a de membre en trop. Le bâton et l'écu au bras sortent sur trois images à la grande taille, et sur deux à la petite ; le fond est uni sur trois, puis sur quatre. La petite taille prend 48 secondes au lieu de 72. Sur cet échantillon, rien ne justifie de changer de taille.

**Le gabarit du prompt**, à compléter dans cet ordre :

> dark fantasy pixel art of a grim, menacing **[créature]**, **[vocabulaire du tier]**, **[orientation et geste]**, **[tenue, matière, état]**, **[arme ou attribut]**, full body, isolated on a solid flat uniform pale ochre background, no texture, **[phrase de palette]**, 16-bit, crisp pixels

**Les exclusions de base** (`--exclure`), à compléter selon le tier et la créature :

> halloween, cute, scenery, landscape, ground details, parchment, paper texture, grunge, textured background, vignette, gradient background, stains

- « grim, menacing » éloigne le résultat du monstre de fête foraine.
- Les exclusions « halloween, cute » retirent le ton enfantin.
- Les exclusions de texture gardent le fond uni, dont dépend le détourage.
- **`comfy_gen.py` ajoute les siennes tout seul,** devant celles-ci : le flou, le rendu 3D, la photo, le texte, les cadres, et « duplicate, multiple figures, cropped, cut off » pour une créature. On ne les répète pas dans `--exclure`.

**Le vocabulaire du tier**, une liste provisoire, complétée à chaque créature :

| Tier | Ajouté au prompt | Ajouté aux exclusions | Trouvé sur |
|:---|:---|:---|:---|
| 1 | (simple readable silhouette:1.3), (low detail:1.3), chunky simple shapes, flat colors, simple shading. Pas de « cartoonish » : sur une bête, il tire vers le dessin animé mignon | highly detailed, intricate, detailed anatomy, chibi | Le Rat géant, en cours (validé comme point de départ le 13/11/2026) |
| 2 | (cartoonish stylized design:1.3), (low detail:1.2), chunky simple shapes, flat colors, simple shading | chibi, highly detailed, intricate, detailed anatomy, realistic proportions | Le Squelette, en cours |
| 3 | highly detailed, et la matière en mots : worn cloth texture, deep folds, frayed torn edges, highly detailed bones | cartoon, flat shading, simple shapes | La Faucheuse |
| 4 et 5 | à trouver | | |

**La phrase de palette ne colore que le corps et ses ombres, jamais la tenue.** Des couleurs citées sans dire sur quoi les poser habillent la créature : « teal greys » a donné au Squelette un haillon sarcelle pendant six tours, malgré l'exclusion des capes. Celle du Squelette : « muted cold colors, old ivory bones with cold slate blue shading and deep navy blue shadows, sparse warm rust accents ». La couleur de la tenue s'écrit avec la tenue, d'après le bloc 4 du brief.

**La pondération `(mots:1.3)`** donne plus de poids à un passage du prompt, dans la syntaxe de ComfyUI ; de 1.2 à 1.4 suffisent. Elle fait venir un élément que le générateur oublie, comme l'équipement du Squelette. **Le piège :** elle renforce aussi chaque adjectif du passage, et « large » a rendu les écus géants. La taille d'un objet se règle par le guide, jamais par un adjectif.

**Le geste et l'orientation du brief s'écrivent aussi en mots,** par exemple « front view, facing the viewer » ou « wide stance, leaning forward toward the viewer ». **On n'exclut jamais une orientation ni une pose :** une créature peut prendre n'importe quelle pose, et c'est le guide qui la tient. **L'exception, sans guide** (décision du propriétaire du 13/11/2026) : pour une créature non humanoïde, rien ne tient la pose. On peut alors exclure les poses que le générateur met à la place de celle du brief. Le Rat géant sortait dressé sur ses pattes arrière, comme un ours-garou, sur cinq images sur six : « standing, upright, bipedal ». On commence par pondérer la pose voulue dans le prompt, et l'exclusion ne vient qu'ensuite. Les prompts du Squelette et de la Faucheuse datent d'avant cette règle : ils excluent encore « profile, side view » ou « front view, standing still ». On ne les recopie pas tels quels.

**La façon de tenir une arme ou de se tenir ne s'obtient pas par le texte.** Le prompt place les objets, pas le geste : c'est le rôle du guide. On ajoute aux exclusions les objets que le générateur substitue volontiers à l'arme voulue (un bâton à la place d'une arme à long manche, par exemple), et « multiple weapons, extra blades » s'il en ajoute.

**Si le fond n'est pas uni, le code l'aplatit,** avec `fond_uni.py`. Le générateur peine à tenir un fond uni, et insister dans le prompt déforme le reste : l'écu du Squelette s'est allongé. L'outil traite un fond d'un ou deux tons, comme un fond ocre posé sur un sol bleu.

**Si le fond est taché, le modèle de détourage prend le relais.** `python comfy_masque.py <figure.png> <masque.png>` demande à ComfyUI le masque de la créature (BiRefNet), et `creature_detour.py --masque` le prend à la place du détourage par le code. Essayé le 13/11/2026 sur quatre fonds que le générateur n'avait pas tenus :
- **des taches en nuage :** le code laisse des éclats de fond autour de la créature, même après `fond_uni.py` ; le modèle la détoure proprement ;
- **un sol d'un autre ton :** `fond_uni.py` et le modèle réussissent tous les deux ;
- **un halo,** un grand disque clair derrière la créature : ni l'un ni l'autre ne le retire. On change de graine.

Le modèle retire le plus souvent l'ombre peinte au sol, que le code garde.

**Une graine ne se garde qu'une fois un design validé,** pour en voir d'autres possibilités par petites modifications. Ce choix n'est pas encore la validation finale de l'étape 7. Jusque-là, chaque tour repart de graines neuves : le guide porte la composition, et le prompt s'affine avec le brief. Une graine gardée trop tôt fige sa composition avec ses défauts : relancée avec un prompt modifié, elle la garde au point d'ignorer « facing the viewer ». Avec une autre taille de toile, elle ne garde rien.

**Deux façons de faire varier un design validé :**
- **Plusieurs prompts sur sa graine,** chacun changeant une chose : six bâtons et écus de styles différents, pour le Squelette. `comfy_gen.py` nomme ses images par préfixe, graine et denoise : `--nom` donne à chaque prompt son propre nom d'image, sinon elles s'écrasent.
- **L'img2img :** l'image retenue devient l'image de départ. On la copie en `<préfixe>_base.png`, à côté des guides de pose et de contours, puis on génère avec `--creature --guide base`, un denoise de 0.6 à 0.7 et des graines neuves. La composition reste, les détails changent.

**Sans guide, pour un brief ouvert ou une créature non humanoïde.** On commence par explorer en génération libre (`--libre --creature` : 1024 × 1536, avec le LoRA à 0.8), avec le même gabarit et le même nombre d'images par tour. On part général, le type de créature et le ton, puis on précise à chaque tour ce qu'on a aimé. Pour une créature humanoïde, on trace le guide dès que le design est trouvé (étape 2), puis on continue sous le guide. Pour une créature non humanoïde, on trace son guide en contours dès que la pose voulue ne sort pas, ou dès qu'une référence la fixe (étape 2) : la génération libre trouve l'espèce et les couleurs, rarement la posture.

### 4. Vérifier l'anatomie, et corriger

**Compter les membres, les mains et les armes.** Le générateur en ajoute volontiers un. Il laisse aussi une trace de ce qu'on retire : une manche vide, une moitié de main.

On corrige sur l'image source, en gardant toujours l'originale à côté (`<nom>_figure_brute.png`) :
- **Pour une petite forme posée sur un fond propre,** recopier la bande propre juste à côté. Si cette bande est penchée, compenser son décalage.
- **Pour retirer un pan entier :**
  1. Retailler la forme **par le code** : tracer le nouveau bord, et remettre du fond au-delà.
  2. Laisser ComfyUI ne retoucher **qu'une bande étroite le long de ce bord**, en mode retouche (`comfy_gen.py --retouche`), avec un denoise d'environ 0.55. On lui donne l'image sous le nom `<préfixe>_assemblage.png`, et le masque, blanc sur la bande, sous `<préfixe>_bande.png`. Faire trois graines et choisir.
- **À ne pas faire : donner à ComfyUI toute la zone à repeindre, sans guide de repeinte.** Il reconstruit la forme d'origine, en suivant ce qu'il voit autour.
- **Une piste plus courte, à confirmer : la repeinte guidée.** `comfy_gen.py <préfixe> "<prompt>" --creature --retouche --repaint 1.0 --zone X0,Y0,X1,Y1` repeint un rectangle entier, à débruitage complet. Le ControlNet reçoit l'image, noire dans la zone, et accorde la zone à ce qui l'entoure. Le prompt décrit ce qui doit s'y trouver, et les exclusions ce qu'on retire. Essayé le 13/11/2026 sur le troisième bras de la Faucheuse, bras et manche d'un seul coup, sur la figure brute : deux graines sur trois les retirent en gardant le manche de la faux, la troisième casse le manche. Sans le guide, sur les mêmes graines, la manche revenait à chaque fois. Le propriétaire n'a pas encore jugé ces images.

Après chaque correction, on revérifie l'anatomie sur l'image entière.

### 5. Détourer et poser dans le cadre

`python creature_detour.py <figure.png> <préfixe>`. La créature est détourée seule : aucun fond n'entre dans son sprite.
- **Le détourage se fait case par case**, sur les cases de 8 pixels du LoRA. Chaque case est comparée au fond local, mesuré autour d'elle.
- **Les petits trous fermés sont bouchés.** Un grand espace fermé par la créature reste du fond, comme l'intérieur d'une anse ou l'espace entre un bras et le corps.
- **Les pieds vont sur la ligne de sol**, par cases entières. Sans ombre peinte, l'outil prend le bas de la silhouette pour les pieds et la place tout seul.
- **`--ombre-peinte`** sert quand le générateur a peint l'ombre au sol avec la créature : le bas de la silhouette est alors l'ombre, pas les pieds. L'outil affiche la largeur des dernières rangées. On y lit la rangée des pieds, là où la silhouette s'élargit en ombre, et on relance avec `--pieds R`. La Faucheuse : `--ombre-peinte --pieds 185`.
- **`--masque <masque.png>`** remplace le détourage par le code par le masque de `comfy_masque.py`, pour un fond taché (étape 3). Ce masque retire l'ombre peinte, mais en laisse des restes collés à la créature : **`--miettes`** les retire, en reconnaissant le ton du fond, assombri (27 cases sur le Rat géant).
- **Une figure générée sur une toile plus petite que le cadre** est posée telle quelle, sans redimensionnement, centrée et les pieds au sol.

Trois fichiers sortent : la figure cadrée (`<préfixe>_cadree.png`), sa silhouette (`<préfixe>_silhouette.png`, une case par pixel du sprite) et la créature sur un fond vif (`<préfixe>_detouree.png`).

**Une question ouverte, le raccord au sol.** Le bas d'une créature doit paraître posé sur le sol de n'importe quel biome, et chaque fond doit pouvoir accueillir n'importe quelle créature. Ce raccord touche les deux à la fois, comme la position où poser la créature sur chaque fond. Il sera travaillé avec le workflow des fonds et des biomes.

**À contrôler :** `<préfixe>_detouree.png`. Il ne doit rester aucune tache du fond uni, et aucune partie fine ne doit manquer (doigts, arme, lambeaux).

### 6. Ramener sur la grille et séparer en calques

`python creature_mots_layers.py <préfixe> <nom>.aseprite --recette <nom>_calques.json --apercu <fond.aseprite> <nom>_<biome>.aseprite`. On obtient :
- **le sprite seul**, sur fond transparent : c'est le livrable. Il entre dans le jeu par `python export_jeu.py ../sprites/<famille>/tier_<n>/<nom>.aseprite ../../assets/data/enemies/<id>/sprite.png --taille 128x192`, calques Ombre et Liseré visibles ;
- **un aperçu**, la créature posée sur un fond de fenêtre de son biome, pour la retoucher en situation. Tant qu'un biome n'a pas ses fonds, on prend ceux de la forêt ;
- **la planche des calques** (`<préfixe>_calques.png`), chaque calque seul sur un fond vif.

**La grille se lit sur la créature elle-même.** L'outil affiche sa netteté, et s'arrête sous 3. Les calques suivent la règle commune : chaque calque est un objet complet, complété sous ceux qui le couvrent.

**Le premier calque est toujours l'ombre.** Le propriétaire l'a décidé le 13/11/2026, sur [maquettes](../../docs/presentations/2026-11-13_ombre_au_sol_creatures_maquettes.pptx) :
- **peinte par le générateur,** sous la ligne de sol, elle est gardée telle quelle. Celle de la Faucheuse porte le bas de sa robe : la retirer couperait la robe sur une ligne droite ;
- **sinon, le code en pose une :** une bande pleine, de la couleur la plus sombre d'Apollo, en ellipse aplatie sous ce qui repose au sol. L'arme ne compte pas : elle peut descendre plus bas que les pieds.

L'outil refuse une recette qui ne livre pas ce calque.

**Les calques se découpent par des mots.** Le modèle SAM3 isole dans l'image ce qu'un mot anglais désigne : « scythe », « robe », « shield ». La créature ne déclare donc que ses calques et leurs mots, dans `<nom>_calques.json`, rangé avec elle. Il n'y a aucun seuil de couleur à régler, et la même recette sert à toute forme de créature. Celle du Squelette :

```json
{
  "calques": ["Ombre", "Robe", "Bouclier", "Arme", "Os"],
  "mots": {"Arme": ["staff"], "Bouclier": ["shield"], "Robe": ["clothes"], "Os": ["skeleton"]},
  "sous_le_sol": ["Arme"]
}
```

- **`calques` :** du bas vers le haut. Le premier est toujours l'ombre. Ce qui passe devant va au-dessus : les os après l'arme, parce que la main serre le manche.
- **`mots` :** pour chaque calque, les mots qui le désignent. **L'ordre compte :** chaque calque réclame ses cases à son tour, et une case déjà prise ne change plus de main. On va du plus sûr au plus large. « skeleton » désigne aussi la tenue : il passe après « clothes », et ne garde que les os.
- **`sous_le_sol` :** les calques qui ont le droit de descendre sous la ligne de sol, comme une arme plantée. Tout le reste, sous la ligne de sol, est l'ombre peinte. Ces calques ne comptent pas non plus pour placer l'ombre du code.
- **`passe_sous`,** facultatif : `{"Corps": ["Tête"]}`, pour un objet qui passe en entier sous un autre. Un calque n'est complété, par défaut, que sous ce qu'il encadre de près, à moins de 8 cases : assez pour une main sur un manche, pas pour le corps d'une bête sous sa tête.
- **`ombre_sous`,** facultatif : `["Corps"]`, pour une créature vue de dessus, dont tout le corps touche le sol. Sans ombre peinte, le code pose alors l'ombre sous l'empreinte entière de ces calques, décalée de trois cases vers le bas, et non en bande sous les pieds.
- **`miettes`,** facultatif : `{"Corps": "Tête"}`. Les morceaux détachés du premier calque vont au second : les moustaches du Rat géant, que « rat » désigne et pas « head ».

**Les mots se cherchent sur une planche, avant d'écrire la recette :**

`python comfy_masque.py <préfixe>_cadree.png <planche.png> --mots scythe robe skeleton hand`

La planche montre ce que chaque mot isole, en quatre secondes par mot. Un mot ne rend pas toujours ce qu'on attend :
- **« bones » ne rend que le crâne.** Les os s'obtiennent par « skeleton », réclamé après la tenue.
- **« shadow » n'est pas fiable :** sur la Faucheuse, il désigne la lame de la faux. L'ombre se prend donc sous la ligne de sol, jamais par un mot.
- **Un pluriel n'est pas un singulier :** sur la Faucheuse, « hand » rend une main et « hands » l'autre. On donne les deux.
- **Un détail peut n'avoir aucun mot :** les chiffons des genoux du Squelette restent avec les os. C'est une retouche de l'étape 9.

**Ce que fait l'outil des mots qu'on lui donne :**
- **Une case qu'aucun mot ne réclame suit ses voisines.** L'outil affiche combien de cases les mots ont réclamées : 93 % pour le Squelette, 98 % pour la Faucheuse.
- **Chaque calque est complété sous ceux qui le couvrent,** là où il les encadre : masquer la main laisse voir le manche, masquer les os la tenue.
- **Un mot qui ne désigne rien arrête l'outil,** qui le nomme.

**Pourquoi les mots,** depuis le 13/11/2026. La recette d'avant triait les cases par leur couleur et leur forme, avec des seuils réglés pour chaque créature. Sur les deux créatures existantes, les mots rendent des objets entiers là où elle rendait des pointillés : les os du Squelette passent de 482 cases éparses à 933 d'un seul tenant. Le propriétaire a jugé ce découpage bien meilleur.

**Sans ComfyUI, une recette par le code reste possible.** `creature_squelette_layers.py` trie le Squelette et la Faucheuse par la couleur et la forme, avec `--manche` et `--bouclier`. Elle ne sert qu'à une créature en tenue, avec des os et une arme à manche. Écrire une telle recette pour une autre forme demande du code. Deux principes s'y appliquent :
- **Une couleur ne suffit pas.** Sur la grille Apollo, des matières différentes tombent sur les mêmes gris. On combine la couleur avec la forme : une droite pour un manche, une tache reliée à l'arme pour une lame.
- **En cas de doute, regarder l'image source.** Elle garde des nuances que la grille a fondues ensemble.

**À contrôler :** la planche des calques. Il ne doit y avoir aucun morceau d'un objet rangé dans le calque d'un autre, et aucun objet coupé en deux.

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
2. **La faire repeindre** par `comfy_gen.py`, sur sa graine et avec son prompt, en `--creature --guide base` et à un denoise de 0.35. La repeinte rend au pixel art sa grille.
3. **Vérifier que la grille est retombée** sur 8 pixels : `python creature_reduire.py grille <image repeinte>`. L'outil affiche la netteté de la grille, en largeur et en hauteur. **Elle revient affaiblie :** pour le Squelette, à 70 % et 0.35, elle vaut 7,4 et 3,8, pour un minimum de 3, quand la Faucheuse, générée directement, atteint 30. À 80 % et 0.35, elle n'était pas retombée. Entre deux facteurs qui plaisent autant, on garde le plus net.

On essaie plusieurs facteurs, et le propriétaire choisit. L'image retenue devient la figure brute, et la version pleine taille va aux archives. La suite reprend à l'étape 4.

## Le dossier d'une créature

**Les créatures sont rangées par famille, puis par tier :** `art_src/sprites/<famille>/tier_<n>/`. Une famille regroupe les formes d'une même créature d'un tier à l'autre : la Faucheuse est le Squelette de tier 3, dans `squelette/tier_3/`. **La famille est la créature elle-même, jamais un groupe de créatures** comme « vermine » ou « bêtes » : le Rat géant est dans `rat/tier_1/` (décision du propriétaire du 13/11/2026). Les fichiers portent le nom de la forme, `<nom>` (`squelette`, `squelette_faucheuse`) :

| Fichier | Rôle |
|:---|:---|
| `<nom>_brief.md` | Le brief : les réponses du propriétaire, le prompt en cours et le journal des tours |
| `<nom>.aseprite` | Le sprite, sur fond transparent : le livrable, exporté en `assets/data/enemies/<id>/sprite.png`, 128 × 192, Ombre et Liseré visibles. Ses calques : Ombre, puis ceux de sa recette, puis Liseré une fois le design validé |
| `<nom>_calques.json` | La recette de calques : l'ordre des calques, et les mots qui désignent chacun (étape 6) |
| `<nom>_<biome>.aseprite` | Un aperçu de la créature posée sur un fond de son biome : le calque Décor, puis ceux du sprite |
| `<nom>_figure_brute.png` | La dernière génération, intacte : celle d'où la figure est tirée. Quand la figure vient d'une réduction ou d'une variation, c'est l'image repeinte ; les générations d'avant vont aux archives. Elle embarque ses réglages (`comfy_meta.py lire`) |
| `<nom>_figure.png` | L'image corrigée, d'où le sprite est tiré |
| `<nom>_pose.png`, `<nom>_edges.png` | Les guides de génération, la pose et l'équipement en contours, sous les noms que les outils leur donnent : `<dossier>/<nom>` sert tel quel de préfixe à `creature_reduire.py`. L'image de départ unie (`_guide.png`) n'est pas gardée : le script de pose la réécrit |

Le script de pose, un par créature, va dans `art_src/tools/creature_<nom>_pose.py`, à côté de `pose.py` qu'il importe. La recette de calques est un fichier de la créature, pas un script : `creature_mots_layers.py` la lit. Les fichiers de travail restent dans `art_src/tools/.work/`, que git ignore.

**On ne supprime rien :** une version remplacée ou un essai abandonné va dans les archives (voir les règles communes du [README des outils](../tools/README.md)).
