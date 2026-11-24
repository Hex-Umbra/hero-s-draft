# Produire un décor d'écran en pixel art

**État au 24/11/2026 : méthode écrite, pas encore éprouvée.** Les étapes 1 à 3 reprennent ce que les trois décors existants ont appris. **L'étape 4, la passe de détail par tuiles, a son outil, et ses quatre essais sont menés** : un décor entier de 640 × 360 se peint et s'importe de bout en bout, sa grille est nette, mais **ses tuiles réinventent la scène et leurs raccords se voient** (essai 4). **L'essai 5 ouvre une autre voie : repeindre l'image entière d'un coup, sans tuiles**, ce qui donne un décor de 640 × 360 sans raccord ; les étapes 3 et 4 de ce document ne sont pas encore réécrites d'après lui. L'outil du contrôle en situation reste à écrire. Le tableau [« Ce qui est éprouvé »](#ce-qui-est-éprouvé-et-ce-qui-ne-lest-pas) dit où en est chaque étape ; [« Les essais à mener »](#les-essais-à-mener) dit ce qu'il faut mesurer avant de produire un vrai décor. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images.

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
- **Le décor garde ses couleurs peintes** (tranché par le propriétaire le 24/11, essai 5) : l'import lit la grille, il ne ramène pas le décor sur la palette Apollo, qui lui retire sa mousse, le modelé de ses rochers et la profondeur de son fond. Sous un combat, c'est aussi ce qui détache le décor des cartes, restées en Apollo exact. La phrase de palette du prompt continue de tenir le décor dans les tons d'Apollo.
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

**À éprouver.** L'outil existe, `decor_tuiles.py`, et ses quatre essais sont menés (voir [les essais](#les-essais-à-mener)) : le dernier échoue sur la fidélité. Les réglages qui suivent sont des points de départ, pas des valeurs trouvées.

`python decor_tuiles.py peindre <scène> <préfixe> <image d'ensemble> "<prompt>" --exclure "<exclusions>"`, puis `python decor_tuiles.py assembler <nom> <image assemblée.png>`.

L'outil fait, dans l'ordre :

1. **Agrandir l'image de départ** à 8 fois la taille visée. **Par pas de deux** (essai du 23/11) : l'image d'ensemble, en grille de 160 × 90, se repeint d'abord en 320 × 180, par quatre tuiles ; l'image assemblée se repeint ensuite en 640 × 360, par seize tuiles. D'un seul pas de quatre, la tuile réinvente la scène. Chaque pas se lance par `--taille`, sur l'image assemblée du pas d'avant : `--taille 320x180`, puis `--taille 640x360`.
2. **Découper en tuiles de 1280 × 720**, soit 160 × 90 cases chacune. Seize tuiles couvrent le décor sans recouvrement ; avec recouvrement, il en faut davantage. **Chaque tuile se pose sur un multiple de 8 pixels**, pour que les grilles de deux tuiles voisines restent en phase.
3. **Faire repeindre chaque tuile** par ComfyUI, en partant de son morceau de l'image agrandie, guidée par son morceau des cartes de profondeur et de contours. La même graine, le même style ; le prompt de chaque tuile est décrit plus bas.
4. **Assembler les tuiles.** Dans un recouvrement, le raccord se coupe sur une ligne de cases, jamais au milieu d'une case. **Avec `--continuer`, une tuile reprend tel quel ce que ses voisines déjà peintes couvrent, et ne peint que le reste :** un objet n'est plus coupé d'une tuile à l'autre (essai 2). Cela ne suffit pas : sur une surface unie, la texture et le ton changent encore là où une tuile commence à peindre (essai 4).
5. **Mesurer la netteté de la grille**, en largeur et en hauteur : celle de chaque tuile dès qu'elle est peinte, puis celle de l'image assemblée. Le minimum est 3 ; une génération directe atteint 30.

**Pour essayer sans tout peindre :** `--tuiles 0,1 2,1` ne repeint que les tuiles nommées, par colonne et rangée ; `--nom` range un essai dans son propre dossier ; `--a-blanc` affiche le plan des tuiles et leurs prompts sans rien générer. Une tuile se relance seule : son image remplace l'ancienne, et l'assemblage se refait.

**Les réglages, et ce que les essais en disent :**

| Réglage | Le point de départ | Ce qui le borne |
|:---|:---|:---|
| Le débruitage (`--denoise`) | 0.5 au premier pas, 0.6 au second | Trop bas, le LoRA ne repeint pas sa grille de 8 pixels : une repeinte à 0.35 rend une grille affaiblie (7,4 et 3,8 sur le Squelette réduit). Trop haut, la tuile réinvente une scène à elle seule |
| Le recouvrement (`--recouvrement`, en cases) | Avec `--continuer`. Essayé à 40 cases, puis à 20 demandées (essai 4) | Sans recouvrement, les raccords se voient ; avec, le nombre de tuiles monte. L'outil répartit les tuiles d'un bord à l'autre : pour 20 cases demandées sur un décor de 640 × 360, le recouvrement réel est de 40 cases en largeur et de 22 en hauteur. Le rétrécir n'a pas retenu les inventions |
| Un guide de couleur (`--couleur`) | Sans, puis le guide « tile » de ControlNet Union, nourri de l'image d'ensemble | Il tient les couleurs d'une tuile à l'autre ; trop fort, il garde aussi les grosses cases de la passe d'ensemble. **Écarté à 0.5 :** la grille fine ne se forme pas. Une force plus basse n'a pas été essayée |
| L'agrandissement de l'image de départ (`--agrandir`) | Bicubique | Au plus proche, la grille revient plus nette en largeur à 0.5 (76 contre 26), sans autre différence visible : à confirmer |

**Le prompt d'une tuile ne décrit pas la scène entière.** Une tuile ne voit qu'un seizième du décor : lui donner le prompt de l'ensemble, c'est lui demander une clairière dans un coin de ciel. **La proposition, à éprouver :** chaque calque de la scène déclare ses mots, comme la recette de calques d'une créature, et le prompt d'une tuile réunit le style commun et les mots des calques qu'elle montre — la structure sait quel objet occupe chaque pixel. `--mots <fichier.json>` le fait : un calque compte dès qu'il occupe 8 % de la tuile (`--seuil`). Sans ce fichier, toutes les tuiles reçoivent le prompt donné.

```json
{
  "style": "dark fantasy pixel art, moody lighting, <phrase de palette>, 16-bit, crisp pixels, highly detailed",
  "mots": {"Ciel": "night sky, thin clouds", "Troncs": "gnarled tree bark, roots", "Sol": "forest floor, moss, dead leaves"}
}
```

**Le coût.** Une tuile de 1280 × 720 prend de 30 à 55 secondes, selon le débruitage. Avec recouvrement, le premier pas compte 9 tuiles et le second 25 : mesuré à l'essai 4, le second pas prend 16 minutes à lui seul, à 38 secondes la tuile. Les deux pas d'un décor prennent donc un peu plus de vingt minutes, sur une seule image d'ensemble : on ne la lance qu'après le choix de l'étape 3, et on relance une tuile, pas le décor, pour corriger un endroit.

### 5. Ramener sur la grille et découper en calques

`python bg_import.py <scène> <image assemblée> <sortie.aseprite> <copie PNG de la source>`

- **La grille se lit sur l'image elle-même.** Générée à 8 fois la taille de la scène, l'image porte une grille qui tombe juste : l'import lit le cœur de chaque case, au lieu d'aligner sur les contours et de moyenner des blocs. C'est ce repli, pris par les trois décors existants, qui leur donne leur trame en damier.
- **Chaque pixel va au calque de l'objet visible à cet endroit** dans la structure ; les autres calques gardent le rendu de l'étape 2.
- **Le manifeste de la scène guide l'import :** les calques qui sont des surfaces, ceux qu'il ignore, les couleurs qu'il n'utilise pas.

**Sur une scène de 640 × 360, l'import prend 21 secondes** (essai 4) : il lit une grille de 8,00 × 8,00 pixels, sans décalage, et l'aller-retour dans Aseprite rend le même fichier. Il lit la taille de la grille sur le rendu de la scène : une scène écrite en 320 × 180 s'importe en 320 × 180, quelle que soit l'image qu'on lui donne.

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
| 4. La passe de détail | **Essais 1 à 4 menés, les 23 et 24/11** : elle tient par pas de deux, à 0.5 puis 0.6, et un décor entier de 640 × 360 porte une grille nette. **Elle échoue sur deux points** : avec le prompt de l'ensemble, les tuiles réinventent la scène ; et leurs raccords se voient sur les surfaces unies, malgré `--continuer` | `decor_tuiles.py` : existe. Le découpage, les mots par calque et l'assemblage sont vérifiés hors génération |
| 5. L'import | **Éprouvé en 640 × 360 le 24/11** : 21 secondes, la grille lue telle quelle | `bg_import.py` : existe |
| 6. Le contrôle en situation | Fait à la main, pour les maquettes du 23/11 | **À écrire** |
| 7. La retouche | — | Aseprite |

## Les essais à mener

Avant de produire un vrai décor, sur une scène existante — le campement, dont la structure et une image d'ensemble existent. On change une chose à la fois, et chaque essai s'écrit ici, avec ses mesures.

| Essai | Ce qu'on fait | Ce qu'on mesure | Il réussit si |
|:---|:---|:---|:---|
| 1. La grille — **mené le 23/11**, résultats plus bas | Une seule tuile, repeinte à quatre débruitages, de 0.4 à 0.7 | La netteté de la grille ; ce que la tuile a gardé de l'ensemble | La netteté dépasse nettement 3 à un débruitage où la tuile ne réinvente rien |
| 2. Les raccords — **mené le 23/11** | Quatre tuiles voisines, sans recouvrement puis avec | Ce qui se voit aux raccords, une fois sur la grille Apollo | Aucun raccord ne se lit à la taille du jeu |
| 3. Le prompt — **une tuile, le 23/11** | Les mêmes tuiles, avec le prompt de l'ensemble puis avec les mots des calques | Les objets inventés dans une tuile | Les mots des calques retirent les inventions |
| 4. Le décor entier — **mené le 24/11**, sans le contrôle en situation | Les seize tuiles, l'import, le contrôle en situation | La durée de chaque étape ; le jugement du propriétaire | Le décor passe les quatre questions de l'étape 6 |

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
- **Restait à essayer sur le second pas :** un débruitage de 0.55 à 0.6, le guide de couleur, l'agrandissement au plus proche, les mots par calque ; et le recouvrement, pour les raccords. C'est fait : voir les deux blocs suivants.

**L'essai 2, les raccords, mené le 23/11/2026.** Le campement entier, en grille de 320 × 180, à 0.5 :

| Assemblage | Tuiles | Netteté de la grille | Ce qu'on voit |
|:---|:---|:---|:---|
| Sans recouvrement | 4 | 44,4 × 42,5 | Les deux raccords se voient : le ciel change de ton, le feu est coupé en deux |
| Recouvrement de 40 cases, coupe franche | 9 | 35,8 × 75,0 | Le feu et le ciel sont entiers ; à la taille réelle, la haie change encore de dessin et de ton d'une tuile à l'autre |
| Recouvrement de 40 cases, `--continuer` | 9 | 34,6 × 54,4 | Plus aucun objet coupé. **Relu le 24/11 à la taille réelle : un raccord reste dans le ciel**, là où la tuile du milieu commence à peindre — tramé d'un côté, lisse de l'autre. En contrepartie, les tuiles qui ne peignent qu'un quart inventent davantage : des panneaux et un petit sapin apparaissent au second plan |
| Sans recouvrement, guide de couleur à 0.5 | 4 | 8,4 × 15,9 | Les couleurs tiennent, mais les grosses cases et la trame de l'image d'ensemble restent : la grille fine ne se forme pas |

**Ce qu'on en retient :** un recouvrement et `--continuer`, où chaque tuile reprend tel quel ce que ses voisines ont peint, retirent les objets coupés, pas les changements de texture sur une surface unie. Le recouvrement de 40 cases, la moitié d'une tuile à cette taille, est plus large qu'il ne faut : un recouvrement plus étroit laisserait chaque tuile peindre davantage, donc inventer moins — à essayer. **Le guide de couleur est écarté à cette force :** il empêche la grille fine.

**Le second pas, à l'échelle d'un décor de 640 × 360, mené le 23/11/2026.** La même tuile des caisses et de la lanterne, depuis l'image assemblée en 320 × 180 :

| Réglage | Netteté de la grille | Reste de la grosse grille | Écart de couleur | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| 0.5 | 26,1 × 6,4 | 12,0 × 3,0 | 8 | Les objets tiennent ; un rendu lisse |
| 0.55 | 33,2 × 8,2 | 3,3 × 1,6 | 10 | Les objets tiennent ; le rendu se durcit |
| 0.6 | 45,0 × 10,1 | 2,2 × 1,9 | 12 | Les objets tiennent ; un vrai rendu de pixel art |
| 0.6, guide de couleur à 0.5 | 54,5 × 5,5 | 33,3 × 7,1 | 3 | L'image de départ presque inchangée : les grosses cases restent |
| 0.5, agrandie au plus proche | 76,1 × 7,3 | 9,5 × 2,6 | 8 | Comme à 0.5, plus net en largeur |
| 0.6, mots des calques | 77,3 × 11,7 | 1,4 × 2,7 | 12 | Le plus net ; les caisses deviennent de vraies caisses de bois, comme le disent les mots, et le fond se change en buissons |
| 0.6, guide de couleur et mots | 77,1 × 5,8 | 34,0 × 6,6 | 3 | Comme avec le guide seul |
| 0.5, LoRA à 1.0 | 32,8 × 7,7 | 11,0 × 2,8 | 8 | Comme à 0.5 : la force du LoRA ne change rien |

**Ce qu'on en retient :**
- **Le second pas demande 0.6**, là où le premier se contente de 0.5 : la grille revient à 45 × 10, sans grosses cases, et la tuile garde ses objets — ce qu'un seul pas de quatre ne faisait pas.
- **Les mots des calques donnent la grille la plus nette**, et tirent la tuile vers ce qu'ils nomment. Un objet sous le seuil de 8 % n'a pas ses mots : la lanterne, absente du prompt de cette tuile, est devenue un four. Le seuil, ou des mots pour les petits objets, est à régler.
- **La netteté reste plus faible en hauteur qu'en largeur** sur cette tuile, à tous les réglages : cela tient peut-être à ses formes, larges et couchées. À vérifier sur d'autres tuiles.
- **Toujours une seule tuile et une seule graine** à cette échelle. Le décor entier, seize tuiles avec recouvrement, reste à faire : c'est l'essai 4.

**L'essai 4, le décor entier, mené le 24/11/2026.** Le campement en 640 × 360, depuis l'assemblage de l'essai 2 (`essai2_continuer`), à 0.6, avec le prompt de l'ensemble, un recouvrement demandé de 20 cases et `--continuer`, sur la même graine. Les images sont dans `.work/tuiles/essai4/` : `assemblage.png`, et `import_x3.png`, le décor importé à la taille d'un écran en 1080p.

| Étape | Durée | Ce qu'on mesure |
|:---|:---|:---|
| Les 25 tuiles | 16 min 23 s, à 38 s la tuile | La netteté de chaque tuile : de 12 à 123 en largeur (médiane 31), de 9 à 92 en hauteur (médiane 23) |
| L'assemblage | 8 s | Une grille de 640 × 360 nette à 91,4 × 73,2 |
| L'import | 21 s | Une grille lue de 8,00 × 8,00 pixels ; 41 couleurs Apollo, 15 calques, 6 421 pixels isolés fondus |

**Ce qui tient :**
- **La chaîne va de bout en bout** à 640 × 360, en un peu plus d'un quart d'heure pour le second pas.
- **La grille est nette partout**, en hauteur comme en largeur : la faiblesse en hauteur relevée au second pas tenait à sa tuile, pas à la méthode.
- **L'import lit la grille telle quelle** : le décor importé porte un détail par pixel, sans bloc de 2 × 2.

**Ce qui ne tient pas :**
- **Les tuiles réinventent la scène.** Chacune ne montre qu'un seizième du décor et reçoit le prompt du campement entier : elle peint un campement. Des montagnes, une table et un feu apparaissent dans le ciel ; la prairie se couvre de tentes et de sapins ; les caisses deviennent une forge de pierre et un four ; une souche reçoit un foyer, le feu de camp des bougies. Les inventions du premier pas — les panneaux, le sapin — sont reprises et grossies par le second.
- **Les raccords se voient.** Sur l'image assemblée, le ciel et le sol se lisent par rectangles : le ton et la texture changent là où une tuile commence à peindre. L'import sur la palette Apollo en fond une partie ; il en reste dans le ciel, à l'horizon et dans la prairie.
- **L'import trame de grandes plages** — le sol autour du feu, la bande de l'horizon — là où la couleur peinte tombe entre deux couleurs de la palette.

**Ce qu'on en retient :**
- **L'essai échoue sur la fidélité, pas sur la grille.** Le décor n'a pas été posé sous un combat, l'outil du contrôle en situation n'existant pas ; le jugement du propriétaire se fait sur `import_x3.png`.
- **Le prompt est la première cause à écarter.** Ce document le prévoyait : le prompt de l'ensemble demande une clairière dans un coin de ciel. Les mots par calque (`--mots`), essayés sur une seule tuile, sont le prochain réglage à éprouver sur un décor entier, seuls.
- **Deux limites de l'essai demeurent :** les cartes de guidage du campement, écrites en 320 × 180, sont floues à cette échelle et tiennent mal les formes ; et l'image de départ portait déjà les inventions du premier pas.
- **Pour l'import, la scène a été agrandie deux fois** dans le dossier de travail (`camp640`), `bg_import.py` lisant la taille de la grille sur le rendu de la scène. Une scène écrite en 640 × 360 n'en aura pas besoin.

**L'essai 5, un décor neuf et un premier pas sans tuiles, mené le 24/11/2026.** Après l'essai 4, le propriétaire change la façon d'essayer : on ne part plus d'un décor existant mais d'un décor neuf, la forêt du combat, composé librement comme les fonds de fenêtre de forêt. Il n'a ni structure ni calques : c'est une image à plat, pour éprouver la génération seule. Les images sont dans `.work/comfy/` (`foret_combat_*`).

**L'image d'ensemble.** Le prompt, les exclusions et les graines des trois fonds de fenêtre ([l'exemple des fonds de forêt](exemples/fonds_fenetre_foret.md)), en génération libre, LoRA à 0.8, en 1280 × 720 au lieu de 1024 × 1536 : la même forêt sort en format paysage, en 30 secondes l'image. Ajouter « wide panoramic view » n'apporte rien sur deux graines et fait sortir la troisième de la forêt. Une bande sombre borde la gauche et le bas des images. Retenue par le propriétaire : la graine 293903 du second tour.

**Le premier pas, l'image entière repeinte d'un coup en 2560 × 1440**, sans tuiles ni guide, avec le prompt de l'ensemble :

| Débruitage | Durée | Netteté de la grille de 320 × 180 | Reste de la grosse grille | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| 0.5 | 127 s | 19,7 × 99,2 | 12,4 × 17,5 | La composition à l'identique ; un rendu mou, des aplats lissés |
| 0.6 | 124 s | 27,1 × 70,2 | 5,8 × 4,4 | La composition tient ; le rendu se durcit, des rochers se dessinent |
| 0.7 | 125 s | 30,6 × 57,7 | 3,2 × 4,5 | Un vrai rendu de pixel art fin. La scène est en partie recomposée — le tronc couché devient un talus moussu, le sentier se prolonge — mais reste une forêt cohérente, sans objet parasite |
| 0.8 | 124 s | 34,2 × 81,3 | 1,7 × 2,1 | Le rendu le plus net, sans trace de la grosse grille. La scène s'éloigne davantage : les troncs gardent leur place, le sentier s'arrête dans une clairière |

**Le second pas, l'image entière repeinte d'un coup en 5120 × 2880**, depuis la repeinte à 0.7, à 0.6, sans tuiles ni guide. Seuls l'encodage et le décodage de l'image passent par morceaux (`VAEEncodeTiled`, `VAEDecodeTiled`), pour tenir dans 8 Go ; `HyperTile` n'a pas été nécessaire.

| Étape | Durée | Ce qu'on mesure |
|:---|:---|:---|
| La repeinte en 5120 × 2880 | 14 minutes environ | Une grille de 640 × 360 nette à 29,8 × 114,4 ; reste de la grille de 320 × 180 : 7,5 × 4,9 |
| L'import, par `window_import.py --taille 640x360` | 26 s | La grille lue telle quelle ; 19 couleurs Apollo, un seul calque |

**Un seul pas de quatre, de 1280 × 720 à 5120 × 2880**, l'image d'ensemble repeinte d'un coup à 0.7 :

| Chemin | Durée des repeintes | Netteté de la grille de 640 × 360 | Reste des grosses grilles | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| Deux pas, 0.7 puis 0.6 | 2 min, puis 14 min | 29,8 × 114,4 | 7,5 × 4,9 (320 × 180) | La composition de l'image d'ensemble, précisée ; de la mousse verte |
| Un pas, 0.7 | 14 min 23 s | 126,1 × 127,9 | 3,7 × 2,6 (320 × 180), 2,5 × 6,9 (160 × 90) | La grille la plus nette. Les trois troncs gardent leur place ; le sol est recomposé — une mare apparaît, les rochers remplacent la mousse |

**Sur l'image entière, le pas unique tient**, là où il échouait sur une tuile : la chaîne peut se réduire à une image d'ensemble et une seule repeinte. Les deux chemins recomposent la scène autant l'un que l'autre, chacun à son premier pas à 0.7.

**La maquette sous un combat** (`.work/maquette_foret/`, reprise des maquettes du 23/11) pose les mêmes cartes sur le décor en 320 × 180 puis en 640 × 360, à la taille d'un écran en 1080p. En 320 × 180, le décor se lit en gros blocs à côté des cadres et des créatures ; en 640 × 360, il s'accorde aux fonds de fenêtre. Sur les deux, les gros troncs passent derrière les cartes et un cadre rouille se détache mal d'un tronc rouille : la composition libre ignore la place de l'interface.

**L'import abîmait le décor de trois façons**, de causes différentes ; quatre conversions ont été rendues sur la même image, puis posées sous le combat (`.work/import_essais/`) :

| Conversion | Couleurs dans le décor | Ce qu'on voit |
|:---|:---|:---|
| L'import d'origine : Apollo exact, tramé | 19 | Une trame en pointillés sur le sentier, qui vire à l'ivoire ; la mousse et le modelé des rochers perdus |
| A. Apollo exact, sans trame, à la couleur la plus proche à l'œil | 17 | Plus de trame, un sentier brun uni ; des aplats, la mousse toujours perdue |
| B. Apollo et le ton intermédiaire de deux voisines de chaque rampe, 81 couleurs | 32 | Le modelé des rochers revient ; jugé trop contrasté, aux ombres mal tenues |
| **C. Les couleurs peintes, la grille seule — retenue** | environ 24 400 | La mousse, les gris chauds, la profondeur du fond |

- **La trame** vient du mélange en damier de deux couleurs voisines de la palette ; **le sentier ivoire**, de la règle qui compte peu la clarté d'une couleur vive, écrite pour les créatures. Les deux se corrigent en restant en Apollo exact (A).
- **La mousse et le modelé** se perdent dans la palette elle-même : ses verts sont trop vifs pour une mousse terne, et ses gris tirent tous sur le bleu.
- **Le propriétaire retient C** : le décor garde son caractère de décor et se détache des dessins des cartes. `window_import.py --taille 640x360 --couleurs-peintes` le fait en 10 secondes ; le `.aseprite` reste en couleurs libres, la palette Apollo en nuancier. Le fond de fenêtre et les créatures gardent l'import d'origine, à l'identique.

**Ce qu'on en retient :**
- **Le décor entier de 640 × 360 se peint sans tuiles, donc sans raccord** : deux repeintes de l'image entière, de deux puis de quatorze minutes, sur une carte de 8 Go. La limite d'un mégapixel vaut pour composer une image, pas pour la repeindre.
- **L'image entière supporte un débruitage plus haut qu'une tuile** : elle voit toute la scène, et le prompt lui convient. À 0.7, là où une tuile réinventait, elle recompose sans sortir du sujet. Au second pas, à 0.6, la composition tient et les formes se précisent.
- **Deux défauts restent à régler :** la bande sombre du bord gauche et du bas, que les repeintes gardent ; et la composition, qui ignore la place de l'interface. Ceux de l'import sont réglés par les couleurs peintes.
- **Ce que l'essai ne dit pas :** il porte sur une seule image, sans structure ni calques, et n'a pas été posé sous un combat. Une scène écrite par le code se repeindrait de la même façon, avec ses guides agrandis à la taille de l'image entière : à éprouver.

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
