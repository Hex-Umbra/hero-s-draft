# Produire un décor d'écran en pixel art

**État au 24/11/2026 : méthode éprouvée sur trois décors.** Le décor de combat de la forêt est le premier sorti de cette chaîne, validé par le propriétaire ([son brief](../decors/forest/combat/forest_combat_brief.md)) ; celui du cimetière est le second, mené d'un bout à l'autre par les outils ([son brief](../decors/graveyard/combat/graveyard_combat_brief.md)) ; celui du donjon, une cave voûtée, est le troisième et le premier intérieur ([son brief](../decors/dungeon/combat/dungeon_combat_brief.md)). La méthode écrite le 23/11 passait par des tuiles ; ses essais l'ont écartée — les tuiles réinventent la scène, et leurs raccords se voient — et ont trouvé celle-ci : **un plan en aplats pour la composition, puis l'image entière repeinte d'un coup, sans tuiles.** Elle tient sur trois sujets, une graine chacun, avec un dernier pas ramené de 0.6 à 0.5 après l'analyse du second, et un premier pas tenu par une carte de contours pour l'intérieur ; elle donne une **image à plat** : le calque par objet reste à concevoir. Le tableau [« Ce qui est éprouvé »](#ce-qui-est-éprouvé-et-ce-qui-ne-lest-pas) dit où en est chaque étape ; [« Les essais »](#les-essais) racontent comment on y est arrivé, mesures à l'appui. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images.

Ce document remplace la section « Fond d'écran » du [workflow des fonds](workflow_fond.md), qui ne garde que les fonds de fenêtre.

## Le principe

**Un décor est l'image posée derrière tout un écran** : le combat, l'aire de repos, une boutique. Il se désigne par un lieu et par un écran ([cadrage du bestiaire](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), B66 et B76) : la forêt a son décor de combat, elle aura un jour son décor de repos.

**Il se dessine en 640 × 360** (B74, confirmé sous un combat par B80). Le jeu l'agrandit par pixels entiers : 3 pixels d'écran par pixel en 1080p, 4 en 1440p, 6 en 4K. Ce sont ces trois écrans qui fixent la taille : seuls 640 de large et ses diviseurs tombent juste sur les trois.

**Une génération ne peut pas le composer d'un coup, mais elle peut le repeindre.** C'est ce qui sépare ce workflow de celui des créatures :
- le LoRA pixel art peint des cases de 8 pixels : une image générée porte une grille huit fois plus petite qu'elle, et un décor de 640 × 360 se peint donc en 5120 × 2880 ;
- le générateur ne compose proprement qu'autour d'un mégapixel, soit environ 1280 × 720 : une grille de 160 × 90, seize fois trop grosse ;
- **cette limite vaut pour composer une image, pas pour la repeindre** : une image déjà composée se repeint entière, bien plus grande, sur une carte de 8 Go (essai 5).

**Le décor se peint donc en deux passes :**
1. **une passe d'ensemble**, en une génération de 1280 × 720 : elle fixe la composition, la lumière et les couleurs, sur une grille quatre fois trop grosse ;
2. **une passe de détail** : l'image entière est agrandie et repeinte d'un coup, en deux pas, jusqu'à 5120 × 2880. Sans tuiles, il n'y a aucun raccord.

**La composition vient du code, avant toute génération.** L'interface recouvre une grande part de l'écran : la composition ne se laisse pas au hasard. Un plan en aplats, dessiné par le code d'après la place de l'interface, sert d'image de départ à la passe d'ensemble ; le générateur y met la matière.

**Les règles communes aux décors :**
- **Le décor garde ses couleurs peintes** (B80, tranché par le propriétaire le 24/11) : l'import lit la grille, il ne ramène pas le décor sur la palette Apollo, qui lui retire sa mousse, le modelé de ses rochers et la profondeur de son fond. Sous un combat, c'est aussi ce qui détache le décor des cartes, restées en Apollo exact. La phrase de palette du prompt continue de tenir le décor dans les tons d'Apollo.
- **Le décor reste derrière.** Sur un écran de combat se superposent trois grilles : en 1080p, un pixel de décor fait 3 pixels d'écran, un pixel de cadre 2, un pixel de créature 1. Le décor reste calme là où l'interface se pose.
- **Pas de brume**, comme pour les fonds de fenêtre : elle aplatit l'image et tue le détail.
- **Un calque par objet,** complet, posé à sa profondeur, avec sa lumière cuite dedans : c'est la règle de toutes les images du jeu, et **cette chaîne ne la tient pas encore.** Elle donne une image à plat. La structure par le code et l'import par calques de [la première méthode](#la-première-méthode--la-structure-les-tuiles-limport-par-calques) restent la piste pour y revenir.

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
Le prompt, les exclusions, les réglages des deux passes.

## Le journal des tours
| Tour | Passe | Ce qui change | Graine retenue | Pourquoi |
|:---|:---|:---|:---|:---|

## Après la génération
- La passe de détail : le débruitage de chaque pas, la netteté de la grille.
- L'import, et le contrôle en situation : ce qu'on y a vu.
- La retouche.
```

### 2. Écrire le plan par le code

**Un script par décor, `decor_<nom>.py`,** dessine un plan de 1280 × 720 en aplats : pas de perspective calculée, pas de détail, seulement la place des masses. [`decor_forest_combat.py`](../tools/decor_forest_combat.py) est le modèle ; [`decor_graveyard_combat.py`](../tools/decor_graveyard_combat.py) en est un second, parti d'une esquisse libre choisie par le propriétaire, dont il replace les objets hors de l'interface. [`decor_dungeon_combat.py`](../tools/decor_dungeon_combat.py) pose une perspective : un point de fuite derrière le héros, des cadres qui se resserrent vers lui.

`python decor_<nom>.py ../decors/<lieu>/<écran>/<nom>_plan.png <zones.png>`

- **Le plan se cale sur la carte des zones** du bloc 2 du brief : ce que l'interface recouvre reste calme, ce qui doit se voir tombe dans ce qui reste visible. Pour le combat de la forêt : un fond lointain et pâle derrière la rangée des ennemis, les deux gros troncs aux bords de l'écran, le sol, son sentier et ses rochers dans le bas.
- **Des aplats aux couleurs du lieu**, à peine floutés pour le lointain. Le générateur garde la place et la teinte des masses, et y met la matière.
- **Le plan fixe aussi la luminosité du décor.** Le prompt seul ne donne pas un décor très sombre : le générateur ramène l'image vers le gris. Pour la cave du donjon, les esquisses libres poussées vers le noir restaient à une luminosité moyenne de 41 à 49 sur 255 ; avec un plan dessiné à 34, l'image d'ensemble sort à 36 et le décor à 30 (essai 8).
- **Le second argument écrit le plan sous la carte des zones**, celle de `decor_controle.py`.

**À montrer au propriétaire avant toute génération :** le plan sous la carte des zones. Rien d'important ne passe sous l'interface ; ce que l'interface vient habiter est à sa place.

**Ce que le plan ne fait pas :** il ne donne ni calques, ni carte de profondeur. Une carte de profondeur tirée du plan a été essayée : elle raidit l'image, aux plans découpés comme un décor de théâtre (essai 6).

### 3. La passe d'ensemble

ComfyUI peint toute la scène en une génération, en partant du plan, sans carte de guidage :

`python comfy_gen.py ../decors/<lieu>/<écran>/<nom> "<prompt>" --guide plan --depth 0 --edges 0 --denoise 0.8 --size 1280x720 --lora 0.8 --seed <a>,<b>,<c> --exclure "<exclusions>"`

| Réglage | Valeur | Option |
|:---|:---|:---|
| Taille | 1280 × 720 : une grille de 160 × 90, le quart exact de celle du décor | `--size` |
| L'image de départ | Le plan, `<nom>_plan.png` | `--guide plan` |
| Débruitage | 0.8 : le plan est suivi. À 0.9, l'image a plus de matière, et une graine sur trois replace un objet derrière une carte ; un objet unique, comme une lune, s'y dédouble ou se déplace (essai 7) | `--denoise` |
| Profondeur, contours | 0 : aucune carte de guidage | `--depth 0 --edges 0` |
| LoRA | 0.8, comme les fonds de fenêtre | `--lora` |

**Le prompt est celui des fonds de fenêtre du lieu** ([workflow des fonds de fenêtre](workflow_fond.md), « Le gabarit du prompt »), avec leurs exclusions : c'est ce qui donne au décor la même forêt que celle des cartes. On y ajoute ce que le plan pose — pour la forêt, « two massive pine trunks framing the left and right edges » et « distant thin trunks fading into pale light in the center » — et on en retire « a small open clearing in the center », qui gardait la place d'une créature.

**Les exclusions de base** (`--exclure`), à compléter selon le lieu :

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, skeleton, animal

`comfy_gen.py` ajoute les siennes tout seul. Composer sans plan, en génération libre, donne la même forêt mais ignore l'interface : ses gros troncs passent derrière les cartes, et une bande sombre borde l'image (essai 5).

**Trois graines par tour, une chose changée à la fois.** Chaque image se pose sous le combat avant d'être jugée :

`python decor_controle.py .work/comfy/<image d'ensemble>.png <sortie.png>`

Le propriétaire choisit l'image d'ensemble sur trois questions seulement : la composition, la lumière, les couleurs. Son détail ne compte pas : il sera repeint.

### 4. La passe de détail : l'image entière, repeinte en deux pas

`python decor_repeindre.py <image d'ensemble> 2560x1440`, puis `python decor_repeindre.py <repeinte en 2560 × 1440> 5120x2880 --denoise 0.5`

L'outil agrandit l'image de départ et la fait repeindre entière par ComfyUI. Il relit dans l'image son prompt, ses exclusions, sa graine et la force du LoRA, et les reprend tels quels. Il affiche la netteté de la grille peinte, et ce qu'il reste de celle de l'image de départ.

| Pas | Taille | Débruitage | Durée | Ce qu'il fait |
|:---|:---|:---|:---|:---|
| 1 | 2560 × 1440, une grille de 320 × 180 | 0.8 | 2 minutes | Il redonne sa matière à l'image — l'écorce, les racines, la mousse — et efface la grosse grille. La scène est en partie recomposée, sans sortir du sujet |
| 2 | 5120 × 2880, la grille du décor | 0.5 | 14 minutes | Il affine les pixels sans refaire la scène |

- **Le premier pas se juge avant le second.** L'image se pose sous le combat (`decor_controle.py`) : la matière est-elle revenue, la composition a-t-elle tenu ? On ne paie le quart d'heure du second pas que sur une image retenue.
- **Une image née d'un plan passe par les deux pas.** Elle porte les aplats du plan : repeinte d'un seul pas jusqu'à 5120 × 2880, elle les garde, et le décor sort plat (essai 6). Une image composée librement, qui porte déjà sa matière, tient en un seul pas à 0.7 (essai 5).
- **Un intérieur se peint au premier pas avec une carte de contours.** À 0.8, le premier pas recompose la scène : sans dommage pour une forêt, mais un intérieur y perd ses objets comptés et ses lignes droites — une grille, des portes, une arche. À 0.6 la scène tient, mais l'image reste lisse et le dernier pas ne la rattrape pas. On peint donc deux fois en 2560 × 1440 : `python decor_repeindre.py <image d'ensemble> 2560x1440 --denoise 0.6`, puis `python decor_repeindre.py <image d'ensemble> 2560x1440 --contours <la repeinte à 0.6>`. L'outil lit les contours de la première sur sa grille et les donne en guide à la seconde, à 0.8 : la scène de l'une, la matière de l'autre, pour 25 secondes de plus (essai 8).
- **Un objet à retirer se retire avant le dernier pas,** sur l'image de 2560 × 1440. Le dernier pas, à 0.5, ne change presque rien d'autre : sur la cave du donjon, 0,3 % des pixels. Faire repeindre la zone par le générateur y remet un objet de la même forme ; quand l'objet se tient devant un fond uni, recopier ce fond par-dessus suffit (essai 8).
- **Le dernier pas se règle à 0.5.** Il faut du débruitage pour affiner les pixels, et c'est ce même débruitage qui invente. À 0.4, l'image garde les gros pixels du premier pas : la grille de 320 × 180 y reste plus nette que celle de 640 × 360. À 0.6, le générateur replace dans les matières ce que le prompt nomme : sur le cimetière, des tombes dans les branches d'un arbre, une croix privée de son pied (essai 7). Le décor de la forêt a été peint à 0.6 : une écorce ou une mousse réinventée reste une écorce.
- **Le prompt reste celui du décor.** Un prompt qui ne nomme plus aucun objet ne retient plus le sujet : à 0.6, les croix deviennent des tours en ruine (essai 7).
- **La netteté de la grille** se lit à la fin de chaque pas. Le minimum est 3 ; le décor de la forêt atteint 54 × 119. Il peut rester une trace de la grille du pas précédent — 10 × 7 sur ce décor — que l'œil ne lit pas.
- **Au-delà de 2560 × 1440, l'image est encodée et décodée par morceaux**, pour tenir sur une carte de 8 Go ; le débruitage, lui, porte toujours sur l'image entière. C'est ce qui garantit l'absence de raccord.

**Ce que les essais disent des réglages :** à 0.5, le premier pas rend une image molle, aux aplats lissés ; il lui faut 0.7 à 0.8. Par tuiles, ces mêmes débruitages faisaient réinventer la scène à chaque tuile : l'image entière voit toute la scène, et le prompt lui convient.

### 5. Ramener sur la grille

`python window_import.py <image de 5120 × 2880> ../decors/<lieu>/<écran>/<nom>_detail.aseprite --taille 640x360 --couleurs-peintes --source ../decors/<lieu>/<écran>/<nom>_detail_source.png`

- **La grille se lit sur l'image elle-même.** Générée à 8 fois la taille du décor, l'image porte une grille qui tombe juste : l'import lit le cœur de chaque case.
- **Chaque case garde sa couleur peinte** (B80) : `--couleurs-peintes`. Le `.aseprite` reste en couleurs libres, la palette Apollo en nuancier pour la retouche. Sans l'option, l'import ramène l'image sur Apollo, comme pour un fond de fenêtre : sur un décor, il trame le sol et lui retire sa mousse (essai 5).
- **Le décor tient en un seul calque.** `--source` garde l'image de 5120 × 2880 à côté, intacte.

L'import prend 12 secondes, et l'aller-retour dans Aseprite rend le même fichier.

### 6. Contrôler en situation, puis faire valider

Le décor se juge sous son interface, à la taille réelle du jeu, jamais seul :

`python decor_controle.py ../decors/<lieu>/<écran>/<nom>_detail.aseprite <sortie.png> [--zones]`

L'outil agrandit le décor à la taille d'un écran en 1080p et pose dessus un combat : une rangée d'ennemis dans les cadres de leurs tiers, sur les fonds de fenêtre du lieu, avec leurs barres et leurs languettes, le héros, et une main de cinq cartes. Il accepte aussi une image générée — l'image d'ensemble, une repeinte — qu'il lit à un pixel par case : c'est ainsi qu'on juge les étapes 3 et 4. `--zones` ajoute, en voile clair, ce que l'interface recouvre.

**C'est une maquette, pas le jeu.** Ses places viennent des maquettes du 23/11 (B72, B73, B77), ses cadres sont ceux, provisoires, de `frame_tier.py`, et les cartes de sa main sont factices. Elle se revérifie sur le jeu une fois la vague du visuel livrée.

**Le décor se regarde aussi seul, agrandi, zone par zone, avant d'être validé.** Sous le combat, l'interface cache une part des défauts, et l'œil suit les cartes. C'est seul qu'on voit un objet qui flotte, un objet posé où il ne peut pas être, deux objets soudés, une matière qui a changé de nature. Chaque défaut se cherche ensuite dans les images des étapes précédentes : celui qui est né au dernier pas se règle par son débruitage, celui qui vient du plan se règle dans le plan.

Quatre questions, sous le combat :
- Les cartes se détachent-elles du décor, et leurs barres se lisent-elles ?
- Le décor reste-t-il calme sous l'interface ?
- Le lieu se lit-il dans ce qui reste visible ?
- Le décor et les fonds de fenêtre du même lieu vont-ils ensemble ?

Tant que le propriétaire ne l'a pas validé, on revient aux étapes précédentes : au plan pour une composition, à la passe d'ensemble pour une lumière ou une couleur, au premier pas de la passe de détail pour la matière.

### 7. Retoucher dans Aseprite

On reprend à la main les bords d'objets et les détails à préciser, en couleurs libres, la palette Apollo en nuancier. Le chemin du `.aseprite` vers l'image du jeu est fixé par la vague qui pose le décor dans le jeu, pas par ce workflow.

## Ce qui est éprouvé, et ce qui ne l'est pas

| Étape | État | Outil |
|:---|:---|:---|
| 1. Le brief | Repris des créatures ; **jamais mené en session** : le décor de la forêt est né des essais, son brief les résume | — |
| 2. Le plan | Éprouvé sur trois décors, le 24/11 | Un script par décor ; `decor_forest_combat.py`, `decor_graveyard_combat.py` et `decor_dungeon_combat.py` pour modèles |
| 3. La passe d'ensemble | Éprouvée sur trois décors, trois graines chacun, de 0.7 à 0.9 | `comfy_gen.py` |
| 4. La passe de détail | Éprouvée sur trois décors, une graine chacun : aucun raccord, grille nette ; la carte de contours, sur un intérieur et deux scènes | `decor_repeindre.py` : il rejoue à l'identique le premier pas du décor de la forêt, a peint les deux pas de celui du cimetière, et rejoue à l'identique le pas tenu par les contours de celui du donjon |
| 5. L'import | Éprouvé en 640 × 360, en couleurs peintes, sur trois décors | `window_import.py --couleurs-peintes` |
| 6. Le contrôle en situation | Fait sur une maquette, pas sur le jeu ; le contrôle du décor seul, agrandi, se fait à l'œil, sans outil | `decor_controle.py` |
| 7. La retouche | Pas encore faite sur un décor | Aseprite |

**Ce qui reste ouvert :**
- **Les calques.** Le décor est une image à plat ; la règle du calque par objet n'est pas tenue.
- **Un intérieur sans perspective simple.** La cave du donjon est un couloir vu de face, à un seul point de fuite. Une salle vue de biais, un campement aux objets épars, restent à éprouver.
- **Le fond d'une ouverture.** Derrière l'arche de la cave, le passage est un noir uni : y montrer un couloir qui continue faisait rétrécir l'arche (essai 8).
- **La mesure de netteté sur un intérieur.** Des pierres et des barreaux droits s'alignent d'eux-mêmes sur la grosse grille : le « reste de la grille de départ » y est haut même sur un décor net. L'œil juge.
- **Les inventions du dernier pas.** À 0.5, il en reste quelques-unes sur un décor d'objets nets — une stèle dans un arbre, des brindilles sur une croix — laissées à la retouche (essai 7). Tenir les formes par une carte de contours au dernier pas n'a pas été essayé.
- **La carte des zones** est lue dans le code, pas mesurée sur une capture du jeu.

## Les essais

Six essais, les 23 et 24/11/2026, ont mené à cette méthode ; un septième la rejoue sur un second sujet, un huitième sur un intérieur. Les quatre premiers éprouvent la passe de détail par tuiles, sur une scène existante, le campement ; les deux suivants partent d'un décor neuf, à la demande du propriétaire. Chaque essai est écrit ici, avec ses mesures.

| Essai | Ce qu'on fait | Ce qu'il dit |
|:---|:---|:---|
| 1. La grille, par tuiles | Une tuile du campement, à plusieurs débruitages | La grille revient par pas de deux ; d'un seul pas de quatre, la tuile réinvente |
| 2. Les raccords | Le campement en quatre et en neuf tuiles | Un recouvrement et `--continuer` retirent les objets coupés, pas les changements de texture |
| 3. Le prompt | Une tuile, avec les mots des calques | La grille la plus nette ; un petit objet sans mots change de nature |
| 4. Le décor entier, par tuiles | Le campement en 640 × 360, 25 tuiles | **Échec** : chaque tuile repeint un campement, et les raccords se voient |
| 5. L'image entière, sans tuiles | La forêt, composée librement, repeinte d'un coup | **Aucun raccord.** Le décor garde ses couleurs peintes (B80), en 640 × 360 |
| 6. La composition | Un plan en aplats comme image de départ | Le plan tient la composition ; il faut deux pas pour retrouver la matière. **Premier décor validé** |
| 7. Un second sujet | Le cimetière, par toute la chaîne, puis son dernier pas à 0.4, 0.5 et 0.6 | La méthode tient ; à 0.6 le dernier pas invente des objets, à 0.5 il affine. **Second décor validé** |
| 8. Un intérieur | Le donjon : un couloir de geôles, puis une cave voûtée, à la demande du propriétaire | Le premier pas à 0.8 refait un intérieur ; tenu par une carte de contours, il garde la scène et la matière. **Troisième décor validé** |

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

**L'essai 6, la composition par un plan grossier, mené le 24/11/2026.** L'image d'ensemble de l'essai 5, composée librement, ignorait l'interface : ses gros troncs passaient derrière trois cartes sur quatre. Un plan de 1280 × 720, dessiné par le code en aplats d'après la carte des zones, guide maintenant la génération : un fond lointain et pâle derrière la rangée des ennemis, les deux gros troncs aux bords de l'écran, le sol, son sentier et ses rochers dans le bas. Ce plan sert d'image de départ, sans carte de profondeur ni de contours (`comfy_gen.py --guide guide --depth 0 --edges 0`), avec le prompt des fonds de fenêtre et deux mentions en plus : les troncs qui cadrent les bords, les troncs lointains dans la lumière du centre.

| Débruitage | Ce qu'on voit, sur trois graines |
|:---|:---|
| 0.8 | Le plan est suivi : les gros troncs aux bords, un fond calme derrière les cartes, le sentier au centre. La bande sombre du bord a disparu |
| 0.9 | Le plan tient encore, avec plus de liberté : une graine sur trois replace un tronc derrière une carte |

**La repeinte de l'image retenue** (0.8, graine 293903), sous trois formes :

| Repeinte | Durée | Ce qu'on voit |
|:---|:---|:---|
| D'un pas, à 5120 × 2880, à 0.7 | 14 min 24 s | La composition tient parfaitement sous le combat, grille nette à 62,0 × 105,4. **Mais l'image est plate** : le sol et les buissons restent des aplats, sans rochers ni mousse — ceux que l'image d'ensemble tenait du plan |
| D'un pas de deux, à 2560 × 1440, à 0.8 | 129 s | **La matière revient** — rochers, sentier, sous-bois — et la composition tient : troncs aux bords, fond pâle au centre |
| La graine 832745 du tour à 0.9, à 2560 × 1440, à 0.8 | 127 s | Plus riche encore, mais de gros troncs de second plan reviennent derrière les cartes |

**Le dernier pas, sur la graine 832745, retenue par le propriétaire :** la repeinte de 2560 × 1440 passe à 5120 × 2880 à 0.6, en 14 min 28 s, puis s'importe en couleurs peintes en 12 secondes. La grille de 640 × 360 est nette à 54,1 × 119,3 ; il reste une trace de celle de 320 × 180, à 10,7 × 7,0, que l'œil ne lit pas. Sous le combat, les troncs de second plan, sourds et lointains, ne disputent pas les cartes : la Faucheuse se détache. C'est le premier décor de la chaîne entière — un plan, une image d'ensemble, deux repeintes, l'import — en dix-sept minutes de génération. **Validé par le propriétaire le 24/11**, il est rangé dans `decors/forest/combat/`.

**L'essai 7, un second sujet, mené le 24/11/2026.** La méthode ne reposait que sur la forêt. Le propriétaire a demandé un autre décor : un cimetière, choisi sur douze esquisses libres (quatre idées, trois graines). Il a retenu « sous les arbres morts », graine 121064 : un grand arbre mort à gauche, une grande lune pâle à droite, des croix, un sentier clair.

**L'esquisse sous le combat.** Posée telle quelle sous la maquette, elle perd l'essentiel : la lune est coupée par la dernière carte d'ennemi et ses languettes, les tombes et le sentier passent sous la main, la ramure tombe derrière les deux premières cartes. Le plan (`decor_graveyard_combat.py`) garde ses éléments et les replace : l'horizon et ses tombes remontent dans la bande restée visible, entre la rangée des ennemis et la main ; la lune descend dans cette bande, à droite du héros ; le tronc se range à gauche de la première carte.

**La passe d'ensemble,** avec les réglages de la forêt, 28 à 30 secondes par image :

| Débruitage | Ce qu'on voit, sur trois graines |
|:---|:---|
| 0.8 | Le plan est suivi sur les trois : l'arbre à gauche, la lune visible à droite du héros, le haut calme. Une graine peint un arbre feuillu |
| 0.9 | Le plan lâche sur l'objet unique : une graine peint deux lunes, une autre enterre la lune à moitié derrière les tombes |

**Le premier pas de détail,** sur les trois images à 0.8, en 2560 × 1440 à 0.8, 127 à 128 secondes chacune : les grilles de 320 × 180 sont nettes, de 50 à 82. Sous le combat, la graine 121064 garde ses croix dans la bande visible, des deux côtés du héros ; la graine 832745 les redescend sous la main et laisse la bande presque vide ; la graine 293903 garde son arbre feuillu.

**Le dernier pas, sur la graine 121064, d'abord à 0.6 :** 5120 × 2880 en 14 min 29 s, puis l'import en couleurs peintes. La grille de 640 × 360 est nette à 91,1 × 99,1, et la composition du plan a tenu. Validé sous le combat, ce décor a été repris le jour même : le propriétaire y a vu des détails incohérents.

**L'analyse du décor seul, agrandi, zone par zone,** relève neuf incohérences, et l'origine de chacune se lit dans les images des étapes :

| Ce qui ne va pas | Né à quelle étape |
|:---|:---|
| Une croix flotte dans le ciel, sans pied | Dernier pas : c'était une croix sur une colonne et son socle |
| Des stèles sur les branches de l'arbre, et une corniche de pierre portant trois croix, en l'air | Dernier pas : il n'y avait là que des branches et un nuage |
| Un petit disque pâle dans le ciel, comme une seconde lune | Dernier pas : c'était une grosse étoile |
| Deux croix soudées sur un seul socle | Dernier pas |
| Les stèles du premier plan devenues des tas de pierres | Dernier pas |
| Un amas de tombes empilées derrière l'arbre de droite | Dernier pas |
| Une petite croix sur une branche de l'arbre de droite | Dernier pas |
| Une branche qui pousse sur une croix de pierre ; un sentier qui bifurque vers un tas de pierres | Premier pas |
| Deux coins sombres sans forme, en bas de l'image | Le plan : ses masses de premier plan, que le générateur n'a pas su lire |

**Le dernier pas, refait depuis la même repeinte de 2560 × 1440,** avec la même graine :

| Dernier pas | Durée | Grille de 640 × 360 | Reste de celle de 320 × 180 | Ce qu'on voit |
|:---|:---|:---|:---|:---|
| 0.4 | 14 min 24 s | 39,0 × 53,2 | 59,3 × 38,4 | Rien d'inventé, mais l'image garde les gros pixels du premier pas : ce n'est pas un décor de 640 × 360 |
| 0.5 | 13 min 55 s | 81,5 × 96,3 | 19,7 × 25,4 | La croix garde sa colonne, les stèles restent des stèles, le ciel reste plus près de l'esquisse. Restent une stèle et deux petites croix dans l'arbre, des brindilles sur deux croix |
| 0.6 | 14 min 29 s | 91,1 × 99,1 | 8,6 × 9,7 | Les sept inventions du tableau ci-dessus |
| 0.6, avec un prompt qui ne nomme aucun objet | 13 min 57 s | 205,9 × 167,3 | 12,7 × 11,1 | **Pire** : les croix et les stèles deviennent des tours en ruine aux fenêtres éclairées. Le prompt tenait le sujet |

**La version à 0.5, validée par le propriétaire le 24/11,** remplace la première dans `decors/graveyard/combat/`.

**Ce que dit l'essai 7 :**
- **La méthode tient sur un autre sujet,** en dix-sept minutes de génération pour l'image retenue ; un seul réglage change, le débruitage du dernier pas.
- **Le plan sert aussi à reprendre une esquisse libre** que le propriétaire a choisie : il en garde les objets et les replace hors de l'interface.
- **0.9 est à éviter à la passe d'ensemble** quand le décor porte un objet unique : il se dédouble ou se déplace.
- **Le dernier pas à 0.6 invente.** À 5120 × 2880, le générateur voit chaque objet en très gros et replace dans les matières ce que le prompt nomme. C'est le défaut des tuiles, en plus discret ; la forêt le cachait.
- **0.5 est le compromis :** assez pour affiner les pixels, pas assez pour refaire la scène. Retirer les objets du prompt n'est pas une issue.
- **Le contrôle sous le combat ne suffit pas.** Le premier décor du cimetière a été validé sous la maquette avec sept inventions que l'interface cachait en partie : le décor se regarde aussi seul, agrandi.
- **Ce que l'essai ne dit pas :** c'est encore un extérieur. Le cimetière n'a pas de fonds de fenêtre : il a été jugé sous ceux de la forêt.

**L'essai 8, un intérieur, mené le 24/11/2026.** Le donjon, dont le jeu affiche déjà un décor de combat (`bg_dungeon.png`). Deux scènes s'y sont succédé : un couloir de geôles, mené jusqu'au décor entier puis écarté par le propriétaire — « ça fait prison plutôt que donjon » — et une cave voûtée, plus sombre, calée sur le décor du jeu.

**Le prompt d'abord.** Les mots font le lieu : « stone dungeon hall » donne une salle de temple, claire et propre ; « dungeon prison corridor » donne des geôles et des barreaux ; « old underground cellar » donne la cave, mais une cave de taverne au bois orange, tant que « tavern », « orange wood » et « warm colors » ne sont pas exclus. Et le noir ne vient pas du prompt : « almost pitch black, chiaroscuro » ramène les esquisses libres d'une luminosité moyenne de 43 à 56 vers 41 à 49, quand le décor du jeu est à 34. C'est le plan, dessiné à 34, qui donne le noir : l'image d'ensemble sort à 36, le décor à 30.

**Le premier pas, sur le couloir des geôles** (graine 293903), depuis une image d'ensemble qui suit le plan — une grille au fond, une porte de geôle sur chaque mur, des lanternes, des tonneaux :

| Premier pas, 2560 × 1440 | Durée | Grille de 320 × 180 | Ce qu'on voit |
|:---|:---|:---|:---|
| 0.8, le réglage de la forêt et du cimetière | 132 s | 37,6 × 28,0 | La plus belle matière, la plus sombre. **Mais la scène est refaite** : plus de grille, plus de portes de geôle, le couloir devient une salle |
| 0.7 | 127 s | 33,0 × 19,2 | La grille du fond devient une porte noire ; une seule geôle reste |
| 0.6 | 125 s | 40,0 × 18,4 | La scène tient : la grille, les deux geôles, les lanternes, les tonneaux. La pierre est lisse |
| 0.8, guidé par les contours de l'image à 0.6 | 153 s | 59,3 × 31,3 | **La scène de l'une et la matière de l'autre** : la grille, les geôles, la perspective, dans le noir du 0.8 |

**Le dernier pas, à 0.5,** dit lequel des deux départs vaut : depuis l'image à 0.6, le décor sort mou — la pierre est lisse, sans matière de pixel art, et la grille de 320 × 180 y reste presque aussi nette (34,0 × 11,5) que celle de 640 × 360 (40,3 × 16,2). Depuis l'image tenue par les contours, la matière est là : la pierre est mouchetée, les lanternes dessinées au pixel près.

**La carte des contours** se lit sur la grille de l'image qui tient la scène : un contour là où deux cases voisines diffèrent de plus de 14 en luminosité, agrandi à la taille visée, aminci à 4 pixels. Elle guide la repeinte par ControlNet Union, à la force 0.5, pendant les six premiers dixièmes du débruitage. `decor_repeindre.py --contours` la bâtit et l'applique ; rejouée par l'outil, la repeinte de la cave revient à l'identique.

**La cave voûtée,** choisie par le propriétaire sur quinze esquisses, avec une demande : centrer le fond, pour que la perspective mène l'œil vers lui et vers un chemin placé juste derrière la scène de combat, et ouvrir le mur du fond. Le plan (`decor_dungeon_combat.py`) pose donc le point de fuite derrière le héros, des cadres de bois qui se resserrent vers lui, et une arche plus large que le héros.

| Image d'ensemble | Ce qu'on voit, sur trois graines |
|:---|:---|
| Le plan, à 0.8 | L'arche s'ouvre, mais sur un trou noir ; les cadres de bois deviennent des piliers de pierre |
| Le plan avec des arcs et des torches dans le passage, à 0.8 | Les arcs sont lus comme les moulures d'une porte : l'arche rétrécit, et tombe derrière le héros |
| Le plan simplifié, à 0.8 puis à 0.7 | À 0.7, la graine 293903 garde les cadres de bois et la large arche. C'est l'image retenue, pas la graine de l'esquisse |

**Les pas de détail de la cave :** 0.6 en 133 s (grille à 15,7 × 19,5, lisse), puis 0.8 par les contours en 153 s (38,7 × 41,4), puis le dernier pas à 0.5 en 14 min 26 s (114,4 × 37,7). Regardé seul, agrandi : rien d'inventé, rien qui flotte. Le propriétaire demande de retirer deux tonneaux en feu posés devant l'arche. Sur l'image de 2560 × 1440, le générateur chargé de repeindre les deux zones y remet un tas de pierres de la forme du tonneau ; recopier par-dessus le noir du passage, devant lequel ils se tenaient, donne une arche vide. Le dernier pas refait, en 14 min 27 s, ne change que 0,3 % des pixels ; la grille est nette à 143,3 × 31,2. **Validé par le propriétaire le 24/11**, le décor est rangé dans `decors/dungeon/combat/`.

**Ce que dit l'essai 8 :**
- **Le premier pas à 0.8 refait un intérieur.** Il garde « un donjon » et perd « les geôles ». La forêt et le cimetière supportaient cette recomposition ; un intérieur, non.
- **Une carte de contours règle le dilemme** entre la scène (0.6) et la matière (0.8), pour 25 secondes. Elle n'a servi qu'au premier pas : au dernier, à 0.5, rien ne bouge.
- **Le plan fixe la luminosité,** et le prompt le sujet : un mot de trop — « prison », « tavern » — change le lieu.
- **Un plan trop détaillé se retourne :** des arcs dessinés dans le passage ont été lus comme les moulures d'une porte.
- **La graine d'une esquisse libre ne vaut plus une fois le plan posé :** c'est une autre graine qui a tenu le plan de la cave.
- **Un objet se retire avant le dernier pas,** qui ne change alors presque rien d'autre.
- **Ce que l'essai ne dit pas :** c'est un couloir vu de face, à un seul point de fuite. Le donjon n'a pas de fonds de fenêtre : il a été jugé sous ceux de la forêt.

**Une carte de profondeur tirée du plan** (les troncs devant, le sol en pente, le fond loin), seule ou avec le plan, donne des images raides, aux plans découpés comme un décor de théâtre : écartée.

**Ce qu'on en retient :**
- **Un plan en aplats suffit à tenir la composition**, sans la structure complète de la première méthode ; 0.8 le suit mieux que 0.9. La bande sombre du bord ne revient pas.
- **Une image d'ensemble née d'un plan porte ses aplats** : la repeindre d'un seul pas les garde. Il lui faut le pas intermédiaire à 2560 × 1440, à 0.8, qui redonne la matière en deux minutes et se juge avant de payer les quatorze minutes du dernier pas. Le chemin en deux pas redevient donc la règle pour une image guidée.
- **Chaque image se juge sous le combat de la maquette** avant d'être repeinte. Les images sont dans `.work/composition/`.

**Deux replis avaient été écrits,** pour le cas où la passe de détail échouerait. L'image repeinte entière les rend inutiles pour la forêt ; ils restent, pour un sujet qui ne supporterait pas d'être recomposé :
- **le décor par éléments :** chaque objet, ou chaque plan, généré seul à sa taille, comme une créature, puis posé par le code — la lumière et la perspective sont alors à tenir à la main ;
- **une grille plus grosse :** la question revient au propriétaire, qui a fixé la taille de 640 × 360 (B74).

## La première méthode : la structure, les tuiles, l'import par calques

**Écrite le 23/11/2026, avant les essais.** Sa passe de détail par tuiles est écartée (essai 4) ; `decor_tuiles.py` reste dans les outils, avec ses mesures. Sa structure par le code et son import par calques ne sont pas écartés : ce sont eux qui donnaient un calque par objet, et la piste pour y revenir. Ni l'un ni l'autre n'a servi à 640 × 360 sur un vrai décor.

### La structure par le code

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

### La passe d'ensemble guidée par la structure

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

### La passe de détail par tuiles

**Écartée.** L'outil existe, `decor_tuiles.py`, et ses quatre essais sont menés (voir [les essais](#les-essais)) : le dernier échoue sur la fidélité et sur les raccords. Les réglages qui suivent sont ceux que ces essais ont mesurés.

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

### L'import par calques

`python bg_import.py <scène> <image assemblée> <sortie.aseprite> <copie PNG de la source>`

- **La grille se lit sur l'image elle-même.** Générée à 8 fois la taille de la scène, l'image porte une grille qui tombe juste : l'import lit le cœur de chaque case, au lieu d'aligner sur les contours et de moyenner des blocs. C'est ce repli, pris par les trois décors existants, qui leur donne leur trame en damier.
- **Chaque pixel va au calque de l'objet visible à cet endroit** dans la structure ; les autres calques gardent le rendu de la structure.
- **Le manifeste de la scène guide l'import :** les calques qui sont des surfaces, ceux qu'il ignore, les couleurs qu'il n'utilise pas.

**Sur une scène de 640 × 360, l'import prend 21 secondes** (essai 4) : il lit une grille de 8,00 × 8,00 pixels, sans décalage, et l'aller-retour dans Aseprite rend le même fichier. Il lit la taille de la grille sur le rendu de la scène : une scène écrite en 320 × 180 s'importe en 320 × 180, quelle que soit l'image qu'on lui donne.

**À contrôler :** l'aperçu agrandi. Aucun bloc de 2 × 2 ou de 4 × 4 ne doit rester ; aucun raccord de tuile ne doit se lire.

## Le dossier d'un décor

**Un décor se range par lieu, puis par écran :** `art_src/decors/<lieu>/<écran>/`, par exemple `decors/forest/combat/`. Les trois décors de la première méthode — `dungeon/`, `steampunk/`, `camp/` — sont en 320 × 180 : ils sont rangés à part, dans `decors/anciens_320x180/`, et aucun n'est repris tel quel (B74, B76). Les fonds de fenêtre ont leur dossier, `fonds/<lieu>/`. L'[index des images](../INDEX.md) montre tout ce qui existe.

| Fichier | Rôle |
|:---|:---|
| `<nom>_brief.md` | Le brief : les réponses du propriétaire, le prompt, le journal des tours |
| `<nom>_plan.png` | Le plan en aplats, que le script du décor réécrit |
| `<nom>_ensemble_source.png` | L'image d'ensemble retenue, intacte |
| `<nom>_contours.png` | Pour un intérieur : la carte des contours qui a tenu le premier pas |
| `<nom>_pas1_source.png` | La repeinte en 2560 × 1440 |
| `<nom>_detail_source.png` | La repeinte en 5120 × 2880, intacte, jamais en JPEG |
| `<nom>_detail.aseprite` | Le décor : le livrable, à retoucher |

**Avec la première méthode** s'y ajoutent `<nom>.aseprite`, la structure rendue par le code, un calque par objet ; `<nom>_guide_x<n>.png`, `<nom>_depth.png` et `<nom>_edges.png`, l'image guide et ses cartes de guidage ; et `<nom>_mots.json`, les mots de chaque calque pour le prompt des tuiles.

Le script du décor, un par décor, va dans `art_src/tools/decor_<nom>.py`. **Le premier décor rangé ainsi est `decors/forest/combat/`**, validé le 24/11 : son [brief](../decors/forest/combat/forest_combat_brief.md) dit comment il a été fait. Le second est `decors/graveyard/combat/`, validé le même jour ([brief](../decors/graveyard/combat/graveyard_combat_brief.md)), et le troisième `decors/dungeon/combat/` ([brief](../decors/dungeon/combat/dungeon_combat_brief.md)). Les fichiers de travail, dont les images générées et les maquettes du contrôle, restent dans `art_src/tools/.work/`, que git ignore.

**On ne supprime rien :** une version remplacée ou un essai abandonné va dans les archives (voir les règles communes du [README des outils](../tools/README.md)).
