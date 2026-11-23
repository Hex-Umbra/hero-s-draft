# Produire un décor d'écran en pixel art

**État au 23/11/2026 : méthode écrite, pas encore éprouvée.** Les étapes 1 à 3 reprennent ce que les trois décors existants ont appris. **L'étape 4, la passe de détail par tuiles, a son outil, et son premier essai est mené** : elle tient par pas de deux, pas encore à l'échelle d'un décor de 640 × 360. L'outil du contrôle en situation reste à écrire. Le tableau [« Ce qui est éprouvé »](#ce-qui-est-éprouvé-et-ce-qui-ne-lest-pas) dit où en est chaque étape ; [« Les essais à mener »](#les-essais-à-mener) dit ce qu'il faut mesurer avant de produire un vrai décor. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images.

Ce document remplace la section « Fond d'écran » du [workflow des fonds](workflow_fond.md), qui ne garde que les fonds de fenêtre.

## Le principe

**Un décor est l'image posée derrière tout un écran** : le combat, l'aire de repos, une boutique. Il se désigne par un lieu et par un écran ([cadrage du bestiaire](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), B66 et B76) : la forêt a son décor de combat, elle aura un jour son décor de repos.

**Il se dessine en 640 × 360** (B74). Le jeu l'agrandit par pixels entiers : 3 pixels d'écran par pixel en 1080p, 4 en 1440p, 6 en 4K.

**Une génération ne peut pas le peindre d'un coup.** C'est ce qui sépare ce workflow de celui des créatures :
- le LoRA pixel art peint des cases de 8 pixels : une image générée porte une grille huit fois plus petite qu'elle ;
- le générateur compose proprement autour d'un mégapixel, soit environ 1280 × 720 ;
- une génération donne donc au mieux une grille de 160 × 90 cases. Un décor de 640 × 360 en demande seize fois plus : il faudrait générer en 5120 × 2880.

**Le décor se peint donc en deux passes :**
1. **une passe d'ensemble**, en une génération : elle fixe la composition, la lumière et les couleurs, sur une grille quatre fois trop grosse ;
2. **une passe de détail par tuiles** : l'image d'ensemble est agrandie, puis repeinte morceau par morceau, chaque morceau à la taille qu'une génération sait peindre. L'essai du 23/11 dit que cet agrandissement se fait par pas de deux (étape 4).

**La structure vient du code, avant toute génération.** L'interface recouvre une grande part de l'écran : la composition ne se laisse pas au hasard. Le code pose la perspective, les objets et leur profondeur ; le générateur n'ajoute que le détail. C'est aussi ce qui tient les tuiles ensemble : chacune reçoit le morceau de la même structure.

**Les règles communes aux décors :**
- **Un calque par objet,** complet, posé à sa profondeur, avec sa lumière cuite dedans. Seules les surfaces — le ciel, le sol — n'ont rien derrière elles.
- **La palette Apollo, exacte**, dès la structure.
- **Le décor reste derrière.** Sur un écran de combat se superposent trois grilles : en 1080p, un pixel de décor fait 3 pixels d'écran, un pixel de cadre 2, un pixel de créature 1. Le décor porte donc moins de détail que ce qu'il reçoit, et reste calme là où l'interface se pose.
- **Pas de brume**, comme pour les fonds de fenêtre : elle aplatit l'image et tue le détail.

## Les étapes

### 1. Établir le brief avec le propriétaire

Avant tout script et toute génération, l'agent et le propriétaire fixent le décor par une session de questions, menée bloc par bloc comme pour une créature ([workflow des créatures](workflow_creature.md), étape 1) : les questions d'un bloc en un message, les réponses écrites au brief, un résumé, puis le bloc suivant.

**Bloc 1 — Identité**

| Question | Ce que la réponse décide |
|:---|:---|
| Quel lieu, et quel écran ? | Le dossier `<lieu>/<écran>/` et le nom des fichiers |
| Que doit-on comprendre au premier regard ? | Le sujet de la scène, en une phrase |
| Existe-t-il déjà des fonds de fenêtre de ce lieu ? | Les matières et les couleurs à reprendre : la carte d'un ennemi montre le même lieu que le décor |
| Une image de référence ? | Elle se décrit en mots dans le brief ; elle n'est pas versée au dépôt quand c'est l'œuvre de quelqu'un d'autre |

**Bloc 2 — L'écran et son interface**

| Question | Ce que la réponse décide |
|:---|:---|
| Qu'est-ce que l'interface recouvre, et où ? | La carte des zones : ce qui reste visible du décor |
| Où le regard doit-il aller ? | La place du sujet, dans ce qui reste visible |
| Le décor porte-t-il un élément que l'interface vient habiter ? | Un sol sous le héros, une trouée derrière un menu : ce que la structure doit placer au pixel près |

**La carte des zones se mesure sur une capture réelle de l'écran**, à la taille du jeu, jamais sur un menu de substitution : le campement a été composé autour d'un menu plus court que le vrai, et sa troisième option recouvre le feu. Pour l'écran de combat, les places des éléments du plateau se lisent dans le code (`layout_system.dart`, `heros_draft_game.dart`, lus le 23/11/2026, à revérifier) :

| Élément | Sa place, sur la grille de 640 × 360 |
|:---|:---|
| La rangée des ennemis | Centrée sur y = 76 ; avec les barres et les cadres, de y = 14 à y = 126, sur presque toute la largeur |
| La carte du héros | Centrée en (320, 184) : environ 70 × 94 |
| La main | À partir de y = 238 environ, entre x = 95 et x = 545 |
| Les panneaux | Les quatre coins, et les bords gauche et droit sous la rangée des ennemis : à mesurer sur la capture |

Ce qui reste visible d'un décor de combat : les intervalles entre les cartes, la bande du milieu de part et d'autre du héros, et les bords.

**Bloc 3 — Les plans et les objets**

| Question | Ce que la réponse décide |
|:---|:---|
| Quels plans, du plus lointain au plus proche ? | L'ordre des calques |
| Quels objets, et lequel est le plus important ? | Un calque par objet ; ce que la structure dessine gros |
| D'où vient la lumière, et y a-t-il une source dans la scène ? | La lumière cuite dans chaque objet |
| Qu'est-ce qui ne doit pas s'y trouver ? | Les exclusions : des personnages, un bâtiment, une saison |

**Bloc 4 — Couleurs et style**

| Question | Ce que la réponse décide |
|:---|:---|
| Quelles couleurs dominantes, et quels accents ? | Les rampes de la scène, et la phrase de palette du prompt |
| Quelle heure, quel temps ? | Le ciel et l'ambiance |
| Qu'est-ce que le décor ne doit surtout pas être ? | Les exclusions de style |

**Le brief s'écrit dans `<nom>_brief.md`**, dans le dossier du décor. Il continue de vivre après la session : chaque tour de génération s'ajoute au journal.

```markdown
# Brief — <Nom> (<lieu>, <écran>)

**État :** en cours | décor validé le <date>

## 1. Identité
## 2. L'écran et son interface
## 3. Les plans et les objets
## 4. Couleurs et style
(dans chaque bloc : les réponses, puis le résumé validé)

## Le prompt en cours
Le prompt, les exclusions, les mots de chaque calque, les réglages des deux passes.

## Le journal des tours
| Tour | Passe | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|

## Après la génération
- La passe de détail : le découpage en tuiles, le recouvrement, le débruitage, la netteté de la grille.
- Les tuiles relancées, et pourquoi.
- L'import : les calques ignorés, les couleurs exclues.
```

### 2. Écrire la structure par le code

**Un script par décor, `decor_<nom>.py`,** construit sur `scene.py`, à partir d'un script de scène existant (`bg_camp.py` est le plus proche). Il ne contient que ce qui est propre au décor.

- **La scène fait 640 × 360.** `scene.py` accepte une taille, mais ses constantes et les trois scripts existants sont écrits pour 320 × 180 : un décor neuf déclare sa taille lui-même.
- **Une vraie perspective**, calculée pixel par pixel, et un calque complet par objet, posé à sa profondeur.
- **La palette Apollo** dès cette étape.
- **Le script écrit** le `.aseprite` de base, l'image guide et les deux cartes de guidage : la profondeur et les contours. Pour la passe de détail, `decor_tuiles.py` les agrandit à 8 fois la taille de la scène, 5120 × 2880, et chaque tuile y découpe son morceau ; il ramène les contours, épais d'une case, à 4 pixels (`--trait`).

**Ce que la structure a appris sur les trois premiers décors :**
- **Une carte des contours trop chargée** — chaque pavé, chaque brique — fige le générateur. On simplifie les formes avant de tracer les contours.
- **Les éléments fins se perdent.** Il faut les dessiner assez gros dans la géométrie.
- **Une forme ambiguë est réinterprétée** par le générateur, à sa façon. Chaque forme claire du guide doit être sans ambiguïté.
- **La lumière se cuit dans chaque objet**, jamais dans un calque de lumière posé par-dessus. Sinon, masquer un objet laisse sa lueur flotter.

**À montrer au propriétaire avant toute génération :** le rendu de la structure, agrandi, avec la carte des zones posée dessus. Rien d'important ne passe sous l'interface ; ce que l'interface vient habiter est à sa place.

### 3. La passe d'ensemble

ComfyUI peint toute la scène en une génération, guidé par l'image guide, la profondeur et les contours :

`python comfy_gen.py <préfixe> "<prompt>" --size 1280x720 --graines 3 --exclure "<exclusions>"`

| Réglage | Valeur | Option |
|:---|:---|:---|
| Taille | 1280 × 720 : une grille de 160 × 90, le quart exact de celle du décor | `--size` |
| Denoise | 0.7 | `--denoise` |
| Profondeur | 0.7 | `--depth` |
| Contours | 0.45 | `--edges` |
| LoRA | 0.9 | `--lora` |

Ces réglages sont ceux des trois décors existants, à une différence près : ils ont été générés en 1360 × 768, dont la grille de 170 × 96 ne tombe sur aucun multiple de la grille visée. La taille de 1280 × 720 est à confirmer au premier essai.

**Le gabarit du prompt** est celui des fonds de fenêtre ([workflow des fonds de fenêtre](workflow_fond.md), « Le gabarit du prompt »), sans les mots qui gardent la place d'une créature :

> dark fantasy pixel art illustration of **[le lieu et le sujet]**, empty scene, highly detailed background with **[les matières et les éléments du lieu]**, moody lighting, **[la phrase de palette]**, 16-bit, crisp pixels, highly detailed

**Les exclusions de base** (`--exclure`), à compléter selon le lieu :

> halloween, cartoon, cute, plain background, fog, mist, haze, animal

`comfy_gen.py` ajoute les siennes tout seul, dont les personnages et les créatures : un décor reste vide.

**Trois graines par tour, une chose changée à la fois.** Le propriétaire choisit l'image d'ensemble sur trois questions seulement : la composition, la lumière, les couleurs. Son détail ne compte pas : il sera repeint.

### 4. La passe de détail, par tuiles

**À éprouver.** L'outil existe, `decor_tuiles.py`, et son premier essai est mené (voir [les essais](#les-essais-à-mener)) ; les réglages qui suivent sont des points de départ, pas des valeurs trouvées.

`python decor_tuiles.py peindre <scène> <préfixe> <image d'ensemble> "<prompt>" --exclure "<exclusions>"`, puis `python decor_tuiles.py assembler <nom> <image assemblée.png>`.

L'outil fait, dans l'ordre :

1. **Agrandir l'image de départ** à 8 fois la taille visée. **Par pas de deux** (essai du 23/11) : l'image d'ensemble, en grille de 160 × 90, se repeint d'abord en 320 × 180, par quatre tuiles ; l'image assemblée se repeint ensuite en 640 × 360, par seize tuiles. D'un seul pas de quatre, la tuile réinvente la scène. Chaque pas se lance par `--taille`, sur l'image assemblée du pas d'avant : `--taille 320x180`, puis `--taille 640x360`.
2. **Découper en tuiles de 1280 × 720**, soit 160 × 90 cases chacune. Seize tuiles couvrent le décor sans recouvrement ; avec recouvrement, il en faut davantage. **Chaque tuile se pose sur un multiple de 8 pixels**, pour que les grilles de deux tuiles voisines restent en phase.
3. **Faire repeindre chaque tuile** par ComfyUI, en partant de son morceau de l'image agrandie, guidée par son morceau des cartes de profondeur et de contours. La même graine, le même style ; le prompt de chaque tuile est décrit plus bas.
4. **Assembler les tuiles.** Dans un recouvrement, le raccord se coupe sur une ligne de cases, jamais au milieu d'une case.
5. **Mesurer la netteté de la grille**, en largeur et en hauteur : celle de chaque tuile dès qu'elle est peinte, puis celle de l'image assemblée. Le minimum est 3 ; une génération directe atteint 30.

**Pour essayer sans tout peindre :** `--tuiles 0,1 2,1` ne repeint que les tuiles nommées, par colonne et rangée ; `--nom` range un essai dans son propre dossier ; `--a-blanc` affiche le plan des tuiles et leurs prompts sans rien générer. Une tuile se relance seule : son image remplace l'ancienne, et l'assemblage se refait.

**Quatre réglages sont à trouver par l'essai :**

| Réglage | Le point de départ | Ce qui le borne |
|:---|:---|:---|
| Le débruitage (`--denoise`) | 0.5 : celui qui tient le mieux un pas de deux à l'essai 1 | Trop bas, le LoRA ne repeint pas sa grille de 8 pixels : une repeinte à 0.35 rend une grille affaiblie (7,4 et 3,8 sur le Squelette réduit). Trop haut, la tuile réinvente une scène à elle seule |
| Le recouvrement (`--recouvrement`, en cases) | Aucun, puis un quart de tuile | Sans recouvrement, un raccord peut se voir ; avec, le nombre de tuiles monte |
| Un guide de couleur (`--couleur`) | Sans, puis le guide « tile » de ControlNet Union, nourri de l'image d'ensemble | Il tient les couleurs d'une tuile à l'autre ; trop fort, il garde aussi les grosses cases de la passe d'ensemble. ComfyUI 0.46.2 propose bien ce type de guide ; il n'a pas été essayé |
| L'agrandissement de l'image d'ensemble (`--agrandir`) | Bicubique | Au plus proche, l'image de départ garde ses grosses cases, que la repeinte peut conserver |

**Le prompt d'une tuile ne décrit pas la scène entière.** Une tuile ne voit qu'un seizième du décor : lui donner le prompt de l'ensemble, c'est lui demander une clairière dans un coin de ciel. **La proposition, à éprouver :** chaque calque de la scène déclare ses mots, comme la recette de calques d'une créature, et le prompt d'une tuile réunit le style commun et les mots des calques qu'elle montre — la structure sait quel objet occupe chaque pixel. `--mots <fichier.json>` le fait : un calque compte dès qu'il occupe 8 % de la tuile (`--seuil`). Sans ce fichier, toutes les tuiles reçoivent le prompt donné.

```json
{
  "style": "dark fantasy pixel art, moody lighting, <phrase de palette>, 16-bit, crisp pixels, highly detailed",
  "mots": {"Ciel": "night sky, thin clouds", "Troncs": "gnarled tree bark, roots", "Sol": "forest floor, moss, dead leaves"}
}
```

**Le coût.** Une tuile de 1280 × 720 prend de 30 à 55 secondes, selon le débruitage. Les deux pas d'un décor, quatre tuiles puis seize, prennent donc un quart d'heure environ, sur une seule image d'ensemble : on ne la lance qu'après le choix de l'étape 3, et on relance une tuile, pas le décor, pour corriger un endroit.

### 5. Ramener sur la grille et découper en calques

`python bg_import.py <scène> <image assemblée> <sortie.aseprite> <copie PNG de la source>`

- **La grille se lit sur l'image elle-même.** Générée à 8 fois la taille de la scène, l'image porte une grille qui tombe juste : l'import lit le cœur de chaque case, au lieu d'aligner sur les contours et de moyenner des blocs. C'est ce repli, pris par les trois décors existants, qui leur donne leur trame en damier.
- **Chaque pixel va au calque de l'objet visible à cet endroit** dans la structure ; les autres calques gardent le rendu de l'étape 2.
- **Le manifeste de la scène guide l'import :** les calques qui sont des surfaces, ceux qu'il ignore, les couleurs qu'il n'utilise pas.

`bg_import.py` n'a jamais tourné sur une scène de 640 × 360 : sa durée est à mesurer.

**À contrôler :** l'aperçu agrandi. Aucun bloc de 2 × 2 ou de 4 × 4 ne doit rester ; aucun raccord de tuile ne doit se lire.

### 6. Contrôler en situation, puis faire valider

Le décor se juge sous son interface, à la taille réelle du jeu, jamais seul. **L'outil reste à écrire** ; les maquettes du 23/11/2026 en donnent le principe : le décor agrandi trois fois, un combat complet posé dessus — des cartes d'ennemi des tiers 1 à 3 dans leurs cadres, sur les fonds de fenêtre du lieu, avec leurs barres et leurs languettes, le héros, la main — et la carte des zones pour ce que la maquette ne montre pas.

Quatre questions :
- Les cartes se détachent-elles du décor, et leurs barres se lisent-elles ?
- Le décor reste-t-il calme sous l'interface ?
- Le lieu se lit-il dans ce qui reste visible ?
- Le décor et les fonds de fenêtre du même lieu vont-ils ensemble ?

Tant que le propriétaire ne l'a pas validé, on revient aux étapes précédentes : à la structure pour une composition, à la passe d'ensemble pour une lumière ou une couleur, à une tuile pour un détail.

### 7. Retoucher dans Aseprite

On reprend à la main les raccords, les bords d'objets et les détails que la grille a perdus. Le chemin du `.aseprite` vers l'image du jeu est fixé par la vague qui pose le décor dans le jeu, pas par ce workflow.

## Ce qui est éprouvé, et ce qui ne l'est pas

| Étape | État | Outil |
|:---|:---|:---|
| 1. Le brief | Repris des créatures ; jamais mené pour un décor | — |
| 2. La structure | Éprouvée sur trois décors, en 320 × 180 ; jamais en 640 × 360 | `scene.py` et un script par décor : existent. `decor_tuiles.py` agrandit lui-même les cartes de guidage |
| 3. La passe d'ensemble | Éprouvée en 1360 × 768 ; 1280 × 720 à confirmer | `comfy_gen.py` : existe |
| 4. La passe de détail | **Essai 1 mené le 23/11** : elle tient par pas de deux, à 0.5 ; à l'échelle d'un décor de 640 × 360, la grille revient faible, et les raccords se voient sans recouvrement | `decor_tuiles.py` : existe. Le découpage, les mots par calque et l'assemblage sont vérifiés hors génération |
| 5. L'import | Éprouvé quand la grille tombe juste, sur les fonds de fenêtre ; jamais à cette taille | `bg_import.py` : existe |
| 6. Le contrôle en situation | Fait à la main, pour les maquettes du 23/11 | **À écrire** |
| 7. La retouche | — | Aseprite |

## Les essais à mener

Avant de produire un vrai décor, sur une scène existante — le campement, dont la structure et une image d'ensemble existent. On change une chose à la fois, et chaque essai s'écrit ici, avec ses mesures.

| Essai | Ce qu'on fait | Ce qu'on mesure | Il réussit si |
|:---|:---|:---|:---|
| 1. La grille — **mené le 23/11**, résultats plus bas | Une seule tuile, repeinte à quatre débruitages, de 0.4 à 0.7 | La netteté de la grille ; ce que la tuile a gardé de l'ensemble | La netteté dépasse nettement 3 à un débruitage où la tuile ne réinvente rien |
| 2. Les raccords | Quatre tuiles voisines, sans recouvrement puis avec | Ce qui se voit aux raccords, une fois sur la grille Apollo | Aucun raccord ne se lit à la taille du jeu |
| 3. Le prompt | Les mêmes tuiles, avec le prompt de l'ensemble puis avec les mots des calques | Les objets inventés dans une tuile | Les mots des calques retirent les inventions |
| 4. Le décor entier | Les seize tuiles, l'import, le contrôle en situation | La durée de chaque étape ; le jugement du propriétaire | Le décor passe les quatre questions de l'étape 6 |

**L'essai 1, mené le 23/11/2026.** Sur le campement, avec le prompt de l'ensemble, sans recouvrement ni guide de couleur, sur une seule graine. Les images et leurs planches sont dans `.work/tuiles/` (`essai1*`), hors du dépôt.

**Ce que porte l'image existante.** L'image d'ensemble du campement (1360 × 768) porte une grille nette de 170 × 96 cases : 31,7 et 23,6. Lue comme une grille de 320 × 180, sa netteté tombe à 1,3 et 2,6 : la grille visée n'y est pas.

**Un pas de deux : du campement en grille de 170 à une grille de 320.** La tuile du bas à gauche, un quart de la scène :

| Débruitage | Netteté de la grille | Reste de la grosse grille | Écart de couleur à l'ensemble | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| 0.4 | 27,4 × 20,9 | 8,1 × 8,1 | 7 | Les objets gardent leur nature ; il reste des traces des grosses cases |
| 0.5 | 51,9 × 23,2 | 2,4 × 4,7 | 10 | Les objets tiennent ; des sapins remplacent la trame, une bûche apparaît |
| 0.55 | 90,8 × 43,0 | 2,0 × 2,4 | 11 | La lanterne devient un brasero |
| 0.6 | 50,3 × 35,8 | 1,8 × 2,3 | 12 | Comme à 0.55 |
| 0.7 | 41,4 × 29,2 | 3,0 × 2,2 | 15 | La tuile réinvente : un ciel étoilé apparaît, la lanterne devient autre chose |

**À ce pas, l'essai réussit :** de 0.4 à 0.6, la grille est très au-dessus de 3 et la tuile garde la scène. Le point de départ retenu est 0.5. Les quatre tuiles peintes à 0.5 puis assemblées donnent une grille de 320 × 180 nette à 44,4 et 42,5. **Mais les deux raccords se voient** : le ciel change de ton d'une tuile à l'autre, et le feu est coupé en deux. Sans recouvrement, l'assemblage ne tient pas : c'est le premier résultat de l'essai 2.

**À l'échelle d'un décor de 640 × 360** (`--taille 640x360`) : une tuile d'un seizième de la scène, celle des caisses et de la lanterne.

| Image de départ | Débruitage | Netteté de la grille | Écart de couleur | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| L'image d'ensemble, agrandie 3,8 fois | 0.4 | 18,1 × 2,3 | 5 | Les grosses cases restent : pas de grille fine |
| | 0.5 | 22,8 × 5,2 | 8 | Une image molle ; des sapins inventés |
| | 0.6 | 75,1 × 10,2 | 11 | Une grille nette, une scène réinventée : un tronc à la place des caisses |
| L'image assemblée en 320 × 180, agrandie 2 fois | 0.4 | 29,5 × 5,2 | 6 | Les objets tiennent ; un rendu lisse, une grille faible en hauteur |
| | 0.5 | 26,1 × 6,4 | 8 | Les objets tiennent ; le même rendu |

**Ce qu'on en retient :**
- **D'un seul pas de quatre, aucun débruitage ne donne à la fois la grille et la fidélité.** L'agrandissement se fait par pas de deux.
- **Par pas de deux, la tuile garde la scène, mais sa grille reste faible en hauteur** — 5 à 6, pour un minimum de 3 — et son rendu est plus lisse que celui d'une génération directe. **La méthode n'est pas validée à 640 × 360.**
- **Les limites de l'essai :** une seule tuile et une seule graine à cette échelle ; et la structure du campement est écrite en 320 × 180, si bien que ses cartes de guidage sont floues à l'échelle d'un décor de 640 × 360. Une structure écrite à cette taille guidera mieux.
- **Reste à essayer sur le second pas :** un débruitage de 0.55 à 0.6, le guide de couleur, l'agrandissement au plus proche, les mots par calque ; et le recouvrement, pour les raccords.

**Si la passe de détail échoue,** deux replis, à ne considérer qu'après l'essai 1 :
- **le décor par éléments :** chaque objet, ou chaque plan, généré seul à sa taille, comme une créature, puis posé par le code — la lumière et la perspective sont alors à tenir à la main ;
- **une grille plus grosse :** la question revient au propriétaire, qui a fixé la taille de 640 × 360 (B74).

## Le dossier d'un décor

**Un décor se range par lieu, puis par écran :** `art_src/backgrounds/<lieu>/<écran>/`, par exemple `backgrounds/forest/combat/`. Les trois décors existants — `dungeon/`, `steampunk/`, `camp/` — sont en 320 × 180 et restent où ils sont : aucun n'est repris tel quel (B74, B76). Les fonds de fenêtre gardent leur dossier, `backgrounds/windows/<lieu>/`.

| Fichier | Rôle |
|:---|:---|
| `<nom>_brief.md` | Le brief : les réponses du propriétaire, le prompt en cours, le journal des tours |
| `<nom>.aseprite` | La structure : le rendu du code, un calque par objet |
| `<nom>_detail.aseprite` | Le décor : le livrable, à retoucher |
| `<nom>_guide_x<n>.png`, `<nom>_depth.png`, `<nom>_edges.png` | L'image guide et les cartes de guidage, que le script de la scène réécrit |
| `<nom>_ensemble_source.png` | L'image d'ensemble retenue, intacte |
| `<nom>_detail_source.png` | L'image assemblée des tuiles, intacte, jamais en JPEG |
| `<nom>_mots.json` | Le style commun et les mots de chaque calque, pour le prompt des tuiles |

Le script de la scène, un par décor, va dans `art_src/tools/decor_<nom>.py`. Les fichiers de travail, dont les tuiles, restent dans `art_src/tools/.work/`, que git ignore.

**On ne supprime rien :** une version remplacée ou un essai abandonné va dans les archives (voir les règles communes du [README des outils](../tools/README.md)).
