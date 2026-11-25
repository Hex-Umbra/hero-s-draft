# P-05 vague 2 — les cadres de tier et les décors — Conception

Date : 2026-11-25
Statut : **Conception** — vague 2 du chantier du bestiaire (`0.6.2`), branche `feat/v0.6.2-cadres-et-decors`

Chantier ROADMAP : **P-05** « Bestiaire », et **P-08** « Cadre d'ennemi », que ce lot clôt. Les décisions font foi
dans le [cadrage du bestiaire](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1 ; la fiche
de la vague est [`docs/chantier_bestiaire/vague_2_visuel.md`](../../chantier_bestiaire/vague_2_visuel.md) ; la
méthode est celle du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§3 à §6, lu pour ce chantier ([README du chantier](../../chantier_bestiaire/README.md), en tête).

> **Ce que le lot livre, en une phrase.** Rien ne change à ce que les ennemis font ; chaque ennemi s'affiche dans
> le cadre de son tier, une gravure épineuse ajourée qui grossit de tier en tier autour d'une fenêtre de 64 × 96
> identique pour tous ; le plateau ne rétrécit plus en continu, il s'affiche à un palier pair choisi par l'écran,
> la créature à la moitié ; le combat se joue devant un décor de forêt neuf en 640 × 360, désigné par un lieu ;
> la barre de PV, les languettes, la fiche et le ciblage de la vague 1 se recalent sur la fenêtre. Les quatre
> ennemis d'aujourd'hui gardent leur sprite, recadré sur son illustration.

Toute référence `fichier:ligne` de ce document a été lue le 2026-11-25 sur la branche à `88dc42f6` (partie de
`main` à `e2a96432`, plus un commit de documentation). Les mesures en pixels sont données **en pixels de cadre**
quand l'élément suit l'échelle du cadre — un pixel de cadre vaut 2 pixels d'écran au palier ×2 —, en pixels
logiques quand il est un widget Flutter, en pixels physiques quand la mesure dépend de l'écran.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce que le lot en livre | Où |
|:---|:---|:---|
| **B66** | Le décor de combat et les fonds de fenêtre passent par un identifiant de lieu, à valeur unique ; les assets se rangent par lieu | §4.2, §5.8 |
| **B67** | Le fond de fenêtre est un asset séparé du cadre, trois par lieu, choisi par le jeu (la règle du tirage : P3, §1.3) | §5.5 |
| **B72** | Le cadre à un palier pair, la créature et son fond à la moitié ; plus de rétrécissement continu ; la fiche qui double la carte ; *amende B17* : aucun facteur 0,8, un écart par carte que le placement reçoit | §5.1, §5.6, §5.9 |
| **B73** | Les cinq géométries, une fenêtre de 64 × 96 ; un boss porte le cadre de son tier, au même palier | §4.1, §5.3 |
| **B74** | La forêt, lieu unique ; le décor de combat en 640 × 360, à 3, 4 ou 6 pixels d'écran par pixel | §4.2, §5.2 |
| **B75** | Un ancien sprite recadré sur son illustration, un seul rectangle pour les quatre, lissé ; le recadrage part avec le dernier | §5.4 |
| **B76** | Un décor par lieu et par écran ; un écran sans image garde son fond d'aujourd'hui ; seul le combat reçoit un décor | §4.2, §5.8 |
| **B77** | *Amende B12 et B14* : la barre et les languettes ancrées à un gabarit de 88 × 120 centré sur la fenêtre ; la rangée alignée sur les fenêtres | §5.6, §5.7 |
| **B78** | Le contour de ciblage autour de la fenêtre, cyan et ambre ; le liseré blanc du repos disparaît | §5.7 |
| **B79** | La fiche ouverte double la carte, sa barre et ses languettes ; le panneau garde sa taille | §5.9 |
| **B80** | Le décor garde ses couleurs peintes ; cadres et fonds restent en Apollo exact : l'export ne convertit rien | §10 |
| **B81, B82** | Les cinq cadres dessinés et corrigés, exportés tels quels | §10 |
| **B61, B52** | L'état transitoire : les anciens sprites dans les cadres jusqu'à la vague de leur tier | §2.1 |

Relues sur le nouveau placement, sans changement de texte : **B39** — une languette qui sortirait de l'écran se
déroule vers l'intérieur, par-dessus sa propre carte, c'est-à-dire désormais par-dessus le gabarit (§5.7) ;
**B40** — la carte ouverte garde sa barre à la hauteur des autres et grandit vers le bas (§5.9). Lues et tenues
sans être construites : **B3, B17, B21, B28, B30** — la demi-place du Rat, ses cartes de tier 1 entières et
plus serrées, la meute qui compte pour deux cartes, le plateau de six : le placement les reçoit (§5.6), les
vagues 4 et 5 les posent.

### 1.2. Les arbitrages

**A1 — Chaque élément vit dans sa couche ; aucun état Riverpod neuf** *(T, filtre 5)*. Les règles qui calculent
— le palier, le cadrage du décor, le recadrage d'une créature, le tirage du fond, la rangée, la zone d'un
ennemi — sont des fonctions pures sous `lib/game/systems/`, testées sans écran, sur le modèle de
`hand_geometry.dart` et `entity_hover.dart`. La table des cadres et le catalogue des lieux sont des modèles de
données sous `lib/models/data/`, chargés par `loadGameDataRegistry` et portés par `GameDataRegistry`. La couche
Flame les reçoit de `GameScreen` à sa construction, comme `chargeCatalog` (`game_screen.dart:313-317`) : elle ne
lit aucun provider. Un seul provider s'ajoute, dérivé du registre et sans état, `currentLocationProvider`, sur le
modèle de `chargeCatalogProvider` (`game_data_service.dart:238-242`), pour les écrans Flutter (A6). Le détail,
élément par élément : §3.

**A2 — La table des cadres est un document de configuration plat, `assets/data/tier_frames.json` ; ses images
se rangent par convention dans `assets/data/frames/tier_<n>.png`** *(T, filtres 4 puis 5)*. La fiche veut
l'offset de fenêtre « comme donnée » (point 1) : un tier de plus, ou le cadre des boss quand il aura sa
géométrie, est une ligne et une image, sans code. Le document ne porte que ce que le répertoire ne dit pas — la
taille du canevas et l'offset de la fenêtre ; le chemin de l'image se déduit du tier, comme l'id d'une entité se
déduit de son fichier. Il rejoint `audio.json`, `xp_curve.json` et `effect_icons.json` parmi les documents plats,
lu par `GameDataLoader.loadDocument` (`game_data_loader.dart:169-181`), dont les fautes s'accumulent avec les
autres. Schéma : §4.1. **Deux propositions de
l'[identité visuelle](../../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md) sont écartées** :
la table `const` Dart de cinq entrées (§4.1, l. 105), parce qu'un tier de plus demanderait du code là où le
document n'en demande pas (filtre 4) ; le dossier `assets/art/frames/` (§7.2), parce que la table est un document
de `assets/data/`, que ses images y suivent comme celles des entités suivent leur fichier, et que `assets/art/`
serait une troisième racine pour un seul vocabulaire (filtre 5). Ce document n'est pas une décision B.

**A3 — Un lieu est un dossier, `assets/data/locations/<id>/`, sans fichier JSON : ses images se lisent dans le
manifeste par leur nom** *(T, filtres 5 puis 7)*. Le répertoire porte l'appartenance : `forest/combat.png` *est*
le décor de combat de la forêt, `forest/window_2.png` son deuxième fond de fenêtre. Aucun champ n'aurait rien à
dire que le chemin ne dise déjà ; et le modèle d'un lieu — son nom, ses ennemis, son lien aux actes — appartient
au cadrage des biomes (P-12, B69), que ce lot ne préempte pas. Le chargeur gagne la lecture des assets par motif
(§4.3). Le dossier `assets/art/backgrounds/` de l'identité visuelle (§7.2, l. 228-229) est écarté pour la même
raison qu'en A2 : il rangerait les décors par écran, quand B66 les range par lieu, et hors du répertoire qui porte
l'appartenance (filtre 5). Le dossier `assets/data/frames/` et chaque dossier de lieu ont leur ligne au `pubspec.yaml` (§10.3).

**A4 — Le lieu courant est le seul lieu du catalogue ; le chargement refuse zéro lieu, ou plusieurs** *(T,
filtres 5 puis 8)*. L'identifiant de lieu est une donnée qui traverse le code — `GameScreen` passe au jeu le lieu
résolu, `ScreenScaffold` le lit par le provider —, et aucune chaîne `'forest'` n'est écrite dans `lib/` : la
valeur unique de B66 est un fait des données, le seul dossier présent. Un second dossier de lieu, exporté trop
tôt (le donjon et le cimetière ont leur décor validé dans `art_src/`), ferait échouer le chargement avec un
message clair, au lieu d'être ignoré en silence. Les biomes (P-12) remplaceront cette règle par la leur — un lieu
par acte ou par nœud — à un seul endroit, `LocationCatalog.current` (§4.2).

**A5 — Le décor de combat est obligatoire pour un lieu ; `bg_dungeon.png` et `assets/images/` disparaissent**
*(T, filtres 1 puis 8)*. B74 met le décor neuf « à la place de `bg_dungeon.png` », un JPEG de 1024 × 1024 sous une
extension `.png` (mesuré, §2.2). Un lieu sans `combat.png` est refusé au chargement : le repli de B76 (« un écran
sans image garde son fond d'aujourd'hui ») ne s'applique donc jamais au combat, et ne peut contredire B74. Le
dossier `assets/images/` ne contenait que ce fichier : sa ligne quitte le `pubspec.yaml`. La migration
« `assets/images/` → `assets/art/` » que l'identité visuelle range parmi ses migrations validées (§9, point 3,
l. 283) n'est pas faite : le dossier disparaît sans successeur, son seul fichier étant remplacé par une image de
lieu rangée sous `assets/data/locations/` (A3). La migration devient sans objet ; l'ADR de la vague le consigne
(§13).

**A6 — La couture sert les autres écrans dès cette vague, par `ScreenScaffold`** *(T, filtre 1 : B76)*. B76 :
« Le repos et les autres écrans reçoivent le leur quand il existe, **sans code neuf**. » Les écrans qu'ouvre un
nœud de la carte passent tous par `ScreenScaffold` (`lib/ui/widgets/screen_scaffold.dart`) : il gagne un
paramètre facultatif, l'écran de décor qu'il habille, et le repos (`rest_screen.dart:137`,
`rest_card_selection_screen.dart:91`), la boutique (`shop_screen.dart:336`), l'événement
(`event_screen.dart:446`), l'autel d'échange (`relic_exchange_screen.dart:112`) et la forge de fusion
(`forge_fusion_screen.dart:151`) le déclarent. Sans image pour cet écran dans le lieu courant — le cas de tous en
`0.6.2` —, `ScreenScaffold` dessine son fond d'aujourd'hui, inchangé. Avec une image, il la dessine derrière son
contenu, au cadrage du décor (§5.2), sans lissage. Déposer `rest.png` dans le dossier du lieu suffira : le dossier
est déjà déclaré, et le nom est connu du catalogue (§4.2). Rien ne se voit dans cette vague (§11.2, M19).

**A7 — Le refus d'un tier sans cadre vit dans `loadGameDataRegistry`, accumulé avec les autres fautes** *(T,
filtre 5)*. Après le chargement des ennemis, de la table et du manifeste, une fonction pure rend la liste des
fautes : un tier d'ennemi sans entrée dans la table, une entrée sans image au manifeste, une fenêtre qui sort du
canevas ou n'y est pas centrée (§4.1), un canevas plus petit que le gabarit. Elles s'ajoutent aux erreurs du chargeur, que `throwIfFailed`
remonte en une fois (`game_data_loader.dart:146-160`, `game_data_service.dart:182`). Les cinq tiers ont leur
cadre (B81) : le refus garde son sens pour un tier ajouté plus tard (point 9). Un boss porte le cadre de son tier
(B73) : la table n'a pas d'entrée pour les boss.

**A8 — Le palier se calcule sur les pixels physiques, par une fonction pure, sur une rangée de référence de six
places** *(T, filtre 1 : B72)*. B72 nomme des écrans — 1080p, 1440p, 4K — et veut des pixels entiers : ce sont des
pixels physiques, quand Flame travaille en pixels logiques. Sur un écran Windows réglé à 125 %, un 1080p plein
écran mesure 1536 × 864 pixels logiques ; le palier ×2 y vaut 1,6 pixel logique par pixel de cadre, 2 pixels
physiques. La règle reçoit donc la taille logique et le rapport de pixels, et rend le palier en pixels logiques,
les positions — abscisses et ordonnée des centres des fenêtres — calées sur le pixel physique. Elle est écrite pour la rangée la plus large que B72 annonce — six
cartes, « à ×2, six cartes tiennent en 1080p » — et non pour la rangée du combat en cours : le palier est choisi par
l'écran, le plateau ne rétrécit plus avec le nombre d'ennemis. **Ses résultats en 1440p et en 4K attendent D1**
(§1.3). Règle : §5.1.

**A9 — La place d'une carte vaut 146 pixels de cadre à tout tier ; l'écart minimal, 7 ; l'étalement d'aujourd'hui
est relu en largeurs réelles** *(T, mesure qui suit l'échelle existante)*. La place se compte sur le plus large du
cadre et du gabarit avec ses deux languettes au repos (fiche, point 3) : 88 + 2 × (30 − 1) = 146, plus large que
le plus grand cadre (120) — toutes les places sont égales en `0.6.2`, mais la fonction reçoit une largeur et un
écart par place. L'écart minimal reprend celui d'aujourd'hui : 165 unités d'un centre à l'autre pour une carte de
100 et deux languettes de 29 (`layout_system.dart:129`), soit 7 ; l'écart maximal, 280 − 158 = 122
(`layout_system.dart:130`). L'étalement garde la forme de `layout_system.dart:132-133` : peu d'ennemis
s'espacent, beaucoup se serrent jusqu'à l'écart minimal. **La largeur que l'écran laisse reste 0,95 de la sienne**
(`layout_system.dart:119`) : à ×2 en 1920 pixels, la rangée de référence en prend 1822 sur 1824. Ces trois
constantes portent B72 ; un test les verrouille (§11). Règle : §5.6.

**A10 — Les fenêtres se centrent à 0,21 de la hauteur de l'écran** *(T, mesure qui suit l'échelle existante)*.
C'est la hauteur des cartes d'aujourd'hui (`layout_system.dart:136`), que le décor de forêt a prise pour sa carte
des zones (« Centrée sur y = 76 » sur la grille de 640 × 360, [workflow des décors](../../../art_src/docs/workflow_decor.md),
étape 1, bloc 2) et que la maquette de contrôle pose à 227 en 1080p (`art_src/tools/decor_controle.py:37`). B77
aligne la rangée sur les fenêtres : toutes les créatures ont le même sol, toutes les barres la même hauteur,
quel que soit le tier.

**A11 — Une carte d'ennemi mesure son canevas, en pixels de cadre ; son échelle est le palier ; son contenu est
composé de cinq calques dans un ordre fixe** *(T, filtre 5)*. La taille figée de 100 × 140 (`enemy_card.dart:213`)
devient celle du canevas du tier, l'échelle continue (`enemy_card.dart:60-61`) devient le palier, et l'ancre
reste au centre — le centre du canevas *est* le centre de la fenêtre, les cinq cadres étant symétriques (B73).
L'ordre des enfants : §5.3.

**A12 — Un ancien sprite se reconnaît à sa taille d'image, pas à un champ de donnée ; son rectangle est celui de
la maquette** *(T, filtres 5 puis 7)*. Un sprite neuf mesure 128 × 192, deux fois la fenêtre
([DA évolutive](../../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.1 ;
[workflow des créatures](../../../art_src/docs/workflow_creature.md), « Le cadrage est commun ») ; une peinture de
1696 × 2528 contient le rectangle de B75. La règle se lit sur l'image : aucun champ n'entre dans `enemy.json`,
l'éditeur et les quatre fichiers n'ont rien à porter puis à retirer, et la vague de chaque tier efface l'état
transitoire en remplaçant le seul `sprite.png`. Le rectangle est celui sur lequel le décor de forêt a été validé le
24/11 (`decor_controle.py:40`), re-mesuré sur les quatre peintures (§5.4). Un test de données garde la règle :
tout sprite livré est un sprite neuf ou une peinture qui contient le rectangle (§11).

**A13 — Le fond de fenêtre se tire quand la carte naît, la carte le tient, rien ne le sauvegarde** *(T, filtre
5)*. C'est un état d'affichage, comme le plein du voile de la vague 1 (ADR-121, point 2) : il se tire à la
création de la carte (`state_sync_system.dart:164-169`), par une fonction pure qui reçoit son aléa, et ne change
plus jusqu'à la mort de l'ennemi. **La règle du tirage est P3** (§1.3).

**A14 — Le contour de ciblage est un composant autour de la fenêtre, à l'extérieur d'elle, qui porte aussi la
lueur** *(T, filtre 1 : B78)*. Le rectangle de bordure couvre aujourd'hui toute la carte, blanc de 2 au repos
(`enemy_card.dart:264-271`, `:353-364`), et la lueur de surbrillance se dessine autour de la carte, sous ses
enfants (`enemy_card.dart:410-423`). Autour de la fenêtre, sous le cadre, la lueur serait couverte par la
gravure : elle passe donc dans le composant du contour, au-dessus du cadre. Le trait se pose à l'extérieur de la
fenêtre, sur le filet du cadre, pour ne rien retirer à la créature. Mesures : §5.7.

**A15 — La gangue de givre et le halo de Foudre couvrent la fenêtre, et non le canevas** *(T, filtres 1 puis 6)*.
Posés aujourd'hui à la taille de la carte (`combat_entity.dart:357`, `:367-373`), ils rempliraient de glace ou de
lueur les jours que B81 ouvre entre les vrilles (« seul le dessin est opaque, le décor se voit entre les
vrilles ») ; c'est la créature qui gèle ou qui porte la charge. Le changement se voit — la gangue et le halo
passent de toute la carte à la fenêtre —, mais une règle le décide déjà : l'ancrage « sur le bord de la fenêtre,
jamais sur le bord du canvas » ([identité visuelle](../../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md),
§4.2.3, l. 114), sur laquelle B77 construit le gabarit.

**A16 — Ce qui se pose « au-dessus » ou « au bas » d'un ennemi s'ancre au gabarit** *(T, filtre 1 : B77)*. Les
textes flottants (`combat_entity.dart:340`, `:467`, `:477`, `:498-503` ; `enemy_card.dart:462`), l'icône d'effet
(`enemy_card.dart:433`), l'entaille d'une carte jouée (`card_animator.dart:304-317`) et la boule de feu
(`combat_visual_system.dart:54`, `:74`) se calculent aujourd'hui sur la taille de la carte. Sur le canevas, ils
tomberaient à cinq places différentes selon le tier ; sur le gabarit, à la même, comme la barre et les
languettes ([identité visuelle](../../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md), §4.2.3 :
« sur le bord de la fenêtre, jamais sur le bord du canvas »). `CombatEntity` gagne le rectangle d'ancrage, la
carte du héros rendant la sienne entière : le héros ne change pas.

**A17 — La zone d'un ennemi est le canevas, prolongé jusqu'au haut de sa barre, plus ses languettes** *(T,
filtre 6)*. Le joueur voit le cadre comme la carte : un appui sur une épine, ou sur le décor vu entre deux vrilles,
reste sur l'ennemi, sans trou qui renverrait l'appui au décor — lequel fermerait la fiche et lâcherait la cible
(`heros_draft_game.dart:360-365`). La règle de la vague 1 ne change pas : une seule zone sert le survol, l'appui et
le lâcher (ADR-121, point 3). **La zone devient le test d'appui de la carte elle-même** : `containsLocalPoint` de
`CombatEntity` rend vrai sur toute sa zone, en coordonnées de la carte. Aux tiers 2 à 5, la barre ne couvre plus
la largeur du canevas : les coins au-dessus du canevas, de part et d'autre d'elle (4 × 13 pixels de cadre au
tier 2, 8 × 9 au tier 3), n'auraient sinon aucune cible d'appui, et l'appui tomberait au décor, alors que le survol
et le lâcher y désignent l'ennemi. La carte reçoit donc tout appui de sa zone ; **la barre et les languettes
perdent `TapCallbacks` et leur renvoi d'appui** (A3 et A8 de la vague 1), devenus sans objet : la zone d'appui
d'aujourd'hui de la barre — y −17 à 0 sur la largeur de la carte (`enemy_health_bar.dart:22-26`) — n'a plus de
composant propre, elle est une part de la zone de la carte. Une languette déroulée sur la voisine reste à sa carte :
la carte survolée est à la priorité 5, la voisine à 0, et Flame interroge d'abord la plus haute. La carte du héros
suit la même règle, sans rien changer à ce qu'elle reçoit. Les tests qui verrouillaient l'ancienne répartition
sont réécrits sur la zone (§11). Géométrie : §5.7.

**A18 — La fiche double la carte, sa barre et ses languettes ; la carte descend de 77 pixels de cadre par palier**
*(T, B79 ; au palier ×2, B72 et B79 disent la même chose)*. `GameConstants.inspectionScale` passe de 1,25 à 2. Le
haut de la barre est à 77 pixels de cadre au-dessus du centre de la fenêtre sur les cinq cadres (48 + 12 + 17) :
la descente qui le garde en place (B40) vaut 77 × (2 − 1) × le palier, la même pour tous les tiers. **À un palier
de 4 ou plus, les deux décisions divergent : D2** (§1.3). Le panneau de la fiche, widget Flutter, garde ses 310 de
large (B79).

**A19 — L'export passe par un outil de `art_src/tools/`, qui aplatit les calques visibles par Aseprite** *(T,
filtre 8)*. Aucun outil ne fait aujourd'hui le chemin d'un `.aseprite` vers un PNG du jeu : `aseprite_export.lua`
exporte calque par calque, pour reprendre un fichier (§2.2). `aseprite --batch <source> --save-as <cible>`
aplatit les calques visibles : essayé le 25/11 sur `art_src/cadres/tier_3.aseprite`, le PNG rendu est identique,
pixel pour pixel, à la superposition de ses six calques. L'outil l'enveloppe, contrôle la taille et dit ce qu'il a
exporté (§10).

**A20 — L'éditeur de contenu ne change pas** *(T, filtre 7)*. §8.

**A21 — Un seul plan, sept tâches et une vérification** *(T, filtre 7)*. §12.

### 1.3. Les questions ouvertes

**Trois questions de classe D**, à trancher par le propriétaire avant le plan — elles ne se règlent qu'en
amendant B72 ou B79 :

- **D1 — Les paliers de 1440p et de 4K.** B72 pose une règle, « le plus grand [palier pair] qui laisse tenir la
  rangée », et ses exemples, « ×2 en 1080p, ×4 en 1440p, ×6 en 4K ». **La règle ne donne pas les exemples.** Avec ses
  languettes, une carte prend 146 pixels de cadre (A9) : six cartes au palier ×4 en prennent 3504 pixels d'écran,
  plus que les 2560 du 1440p — cinq, 2920, n'y tiennent pas non plus ; au palier ×6, 5256 pour les 3840 de la 4K.
  En hauteur, la fenêtre centrée à 0,21 de l'écran (A10), le haut de la barre sortirait de l'écran en 1440p à ×4
  (302 − 77 × 4 = −6) et en 4K à ×6 (454 − 77 × 6 = −8) ; et en 1440p à ×4, même à quatre cartes, qui tiennent en
  largeur, **seul un cadre de tier 1 reste au-dessus de la carte du héros** : le bas d'un tier 2 descend à 558, celui
  d'un tier 5 à 606, contre 547 pour le haut du héros. Les exemples se retrouvent en comptant six gabarits de 88 sans
  languettes ni écart (6 × 88 × 4 = 2112 ≤ 2560 ; 6 × 88 × 6 = 3168 ≤ 3840). Sous la règle, les paliers sont
  **×2 en 1080p, ×2 en 1440p, ×4 en 4K** ; la créature tombe sur des pixels entiers dans les trois cas (1, 1, 2), le
  décor aussi (3, 4, 6). Deux faits de la règle à peser : **en 4K, ×4 ne tient qu'à 4 pixels près** (3644 sur 3648) —
  un pixel de cadre de plus à une place ou à un écart la ferait tomber à ×2 ; et **en 1440p, les ennemis gardent
  leur taille du 1080p quand le héros et la main grandissent de 4/3** (`scaleFactor` 1,8 contre 1,35,
  `heros_draft_game.dart:72`). **Recommandation : la règle** — elle tient les six cartes que B72 et B30 annoncent, et
  le plateau de la 4K est celui du 1080p doublé ; les exemples demanderaient de déplacer le héros, hors du lot. La spec
  est écrite autour : §5.1 calcule la règle, et seuls ses cas de test de 1440p et de 4K dépendent de la réponse.
- **D2 — La fiche à un palier de 4 ou plus.** B72 écrit « au palier pair suivant », B79 « double tout ». Au palier
  ×2, l'un et l'autre donnent ×4 ; au palier ×4 (la 4K sous D1 recommandée), le palier pair suivant est ×6, le
  double ×8 ; au palier ×6 (la 4K sous les exemples de B72), ×8 contre ×12 — à ×12, un cadre de tier 5 de 1824
  pixels de haut, 84 % de la hauteur de l'écran. **Recommandation : doubler** (B79, la décision la plus récente, qui complète B72) ; sous
  D1 recommandée, la carte ouverte de la 4K est exactement celle du 1080p doublée. A18 l'écrit ainsi ; seule la
  constante change si la réponse est l'autre.
- **D3 — Sous le plus petit écran qui tient le palier ×2.** La fenêtre du jeu s'ouvre en 1280 × 720 sous Windows
  (`windows/runner/main.cpp:28-29`, affichée par `ShowWindow(…, SW_SHOWNORMAL)`, `win32_window.cpp:152-153`) : la
  rangée de référence n'y tient pas à ×2 (911 × 2 = 1822 > 0,95 × 1280). **Toutes les options dérogent à la lettre de
  B72** (« un palier pair, le plus grand qui laisse tenir la rangée ») : d'où la classe D. Le propriétaire a décidé le
  10/11 que le jeu vise le 1080p au minimum et qu'on ne cherche pas la netteté en dessous
  ([DA évolutive](../../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.2) ; il
  n'a pas dit ce que devient le plateau. Options : **(a)** le palier ×2 réduit en continu jusqu'à tenir, lissé — hors
  palier ; (b) le même, sans lissage, aux pixels inégaux — hors palier ; (c) le palier ×1, impair, net mais moitié
  plus petit, la créature à un demi-pixel par pixel ; (d) le palier ×2 qui déborde — la rangée ne tient pas.
  L'[identité visuelle](../../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md), §3.1, plaide pour
  (c) : « en filtrage linéaire il devient mou », et son palier ½, qui « jette un pixel sur deux, net », est retenu
  pour le portrait mobile. **(e)**, à combiner avec l'une des quatre pour les écrans réellement plus petits : ouvrir la
  fenêtre maximisée au lancement, pour que la première vue soit nette sur un écran 1080p (environ 1920 × 1009, au
  palier ×2, §5.1). Elle toucherait le runner Windows — `SW_SHOWNORMAL` en `SW_SHOWMAXIMIZED`
  (`win32_window.cpp:153`), ou la taille de `main.cpp:28` — : du code natif de plateforme, ni dans « Ce qu'elle
  livre » ni dans les onze points de la fiche, donc **hors du périmètre**, où seule la réponse du propriétaire la
  ferait entrer. **Recommandation : (a), avec (e)** si le propriétaire accepte cette ligne native — en 1280 × 720, un
  pixel de cadre vaut 1,34 pixel, la rangée de six tient et l'écran garde sa mise en page ; (e) rend net le cas le
  plus fréquent. §5.1 écrit (a), sous réserve.

**Trois questions de classe P**, sans réponse dans le cadrage, posées en une fois :

- **P2 — Le cadrage du décor hors 16:9.** B74 fixe 3, 4 et 6 pixels d'écran par pixel de décor sur les trois
  écrans 16:9. Ailleurs — 16:10, ultra-large, et une fenêtre maximisée, dont la hauteur utile perd la barre de titre
  et la barre des tâches (environ 1920 × 1009 sur un écran 1080p) — options : **(a)** couvrir l'écran au plus petit
  facteur qui le couvre, centré, rogné, non lissé — entier sur les trois écrans de B74 et sur une fenêtre maximisée
  ou de 1280 × 720, fractionnaire en 16:10 ; (b) couvrir au plus petit facteur *entier* qui couvre — un 1280 × 800
  passe à ×3 et perd de chaque côté un quart de la largeur de l'écran (320 pixels, un sixième du décor), les deux
  troncs qui cadrent le décor compris ; (c) le plus grand
  facteur entier qui tient dans l'écran, avec des bandes de la couleur de fond. **Recommandation : (a)**. §5.2
  l'écrit ainsi, sous réserve.
- **P3 — Le tirage du fond de fenêtre parmi trois** (fiche, point 7). Options : **(a)** au hasard, par ennemi, à son
  entrée sur le plateau ; (b) le même tirage, sans reprendre le fond de la carte voisine quand c'est possible ;
  (c) un tirage par combat, le même fond pour tous ; (d) un fond fixe par ennemi, qui contredirait le motif des
  trois variations (« pour que le même ennemi ne se présente pas toujours dans le même décor »,
  [workflow des fonds](../../../art_src/docs/workflow_fond.md)). **Recommandation : (a)**, la plus simple, à revoir
  au test de la vague 4 : **le fond ne se voit pas en `0.6.2`** (§2.1). §5.5 l'écrit ainsi, sous réserve.
- **P4 — La carte ouverte au bord du plateau, avec six cartes.** Doublée, la carte du bord d'une rangée de six
  sort de l'écran d'une centaine de pixels (en 1080p, son bord droit, languette comprise, à 2017). Avec cinq
  cartes au plus, le cas de `0.6.2`, elle tient sur tous les écrans (§5.9). Options : (a) elle déborde ; **(b)**
  elle se décale vers l'intérieur juste assez pour tenir, sa barre gardant sa hauteur (B40) ; (c) la fiche ne double
  pas la carte du bord. **Recommandation : (b)**. **Non bloquante pour `0.6.2`** : à trancher avant la vague 4, qui
  ouvre le sixième emplacement ; ce lot ne la construit pas.

---

## 2. Périmètre

**Dans le lot** : la table des cadres et ses cinq images ; le dossier de la forêt, son décor de combat et ses trois
fonds ; le chargement et ses refus ; le palier, le cadrage du décor, le recadrage, le tirage du fond et la rangée,
en fonctions pures ; la carte d'ennemi composée, à l'échelle du palier ; le décor du combat ; la couture des autres
écrans par `ScreenScaffold` ; la barre, les languettes, le contour, la zone et la fiche de la vague 1, recalés sur
la fenêtre ; l'outil d'export ; la retouche de la documentation de `art_src/` qui annonçait ce chemin.

| Hors du lot | Où |
|:---|:---|
| La demi-place du Rat, ses cartes plus serrées, le sixième emplacement du plateau (B3, B17, B28, B30) — le plafond reste de cinq (`combat_controller.dart:170`) | Vague 4 |
| La meute, qui compte pour deux cartes (B21) | Vague 5 |
| Le cadre des boss (B73) ; le médaillon d'élite ([identité visuelle](../../possible_upgrades/18-09-2026_identite_visuelle_pixel_art_Opus5.md), §5.1, P-14) | Les boss ; P-14 |
| Tout sprite refait, tout ennemi neuf, tout mécanisme | Vagues 3 à 10 |
| Les biomes : un second lieu, un lieu par acte, un pool d'ennemis par lieu (B66, B69) | P-12, après `0.7.0` |
| Le décor du repos et des autres écrans, le fond plein des options du repos (B76) | Hors vague |
| La carte du héros et la main, qui gardent leur échelle continue (`hero_card.dart:33`, `:120` ; `layout_system.dart:20`) ; le héros garde aussi son liseré blanc | — |
| Le juice, les animations, les secousses (P-06, P-07) : seules leurs ancres changent (A16) | P-06, P-07 |
| `health_bar.dart`, que rien n'utilise (ADR-121, « Conséquences ») | À la file |

### 2.1. Les transitions

| Frontière | État | Réglé par |
|:---|:---|:---|
| `0.6.1` → `0.6.2` | La carte peinte entière, 100 × 140 unités, à l'échelle continue, le boss à × 1,25, la fiche à × 1,25 ; le décor `bg_dungeon.png` étiré | Ce lot |
| `0.6.2` → `0.6.4` à `0.6.6` | **Les anciens sprites dans les cadres** (B61, B52), recadrés et lissés : le Slime et le Gobelin jusqu'en `0.6.3`, le Squelette jusqu'en `0.6.4`, l'Orc jusqu'en `0.6.5` ([README du chantier](../../chantier_bestiaire/README.md), §3) | La vague de chaque tier, qui remplace le `sprite.png` ; le recadrage part avec le dernier (§5.4) |
| `0.6.2` → `0.6.4` | **Le fond de fenêtre est dormant** : la peinture recadrée d'un ancien sprite est opaque et le couvre en entier. Il se dessine, il ne se voit pas. Le premier sprite neuf, en vague 4, le montre | Vague 4 |
| `0.6.2` → `0.6.4` | La rangée est écrite pour six places ; le combat n'en remplit que cinq | Vague 4 |
| `0.6.2` → après `0.7.0` | Un seul lieu ; la couture des autres écrans sans image (A6) | P-12 ; le décor de chaque écran, hors vague |
| Sauvegardes de `0.6.1` | Rien de neuf n'est écrit | §9 |

### 2.2. L'état mesuré

Les pièges de la fiche, relevés le 23/11 sans exécution, re-mesurés le 25/11 :

| Prémisse | Mesure | Où |
|:---|:---|:---|
| Tout s'ancre à une carte de 100 × 140 | Vrai : la taille de la carte, la barre à sa largeur, les languettes à ses bords, la zone de la barre au bas de la carte, la descente de la fiche, son rectangle, la gangue et le halo | `enemy_card.dart:213`, `:273`, `:116-117`, `:178-194` ; `combat_entity.dart:62-74`, `:357`, `:367-373` ; `entity_hover.dart:8-9` |
| Deux largeurs concurrentes dans `repositionEnemies` | Vrai : `visualWidthPerEnemy` (170 unités) pour le rétrécissement, l'espacement borné à [165, 280] unités pour la place | `layout_system.dart:116-127`, `:129-133` |
| Tout le placement est en échelle continue | Vrai : `scaleFactor` = hauteur / 800 borné à [0,85 ; 2,5] ; × 1,45 ; × 1,25 pour un boss ; × `scaleMultiplier` ∈ [0,4 ; 1] ; la fiche × 1,25 | `heros_draft_game.dart:72` ; `enemy_card.dart:60-61`, `:65-66` ; `layout_system.dart:118-127` ; `game_constants.dart:30` |
| Aucun filtrage n'est fixé pour les sprites | Vrai : aucun `filterQuality` dans `lib/`. `SpriteComponent` dessine avec la peinture de `HasPaint`, une `Paint()` dont le filtrage par défaut est `FilterQuality.none` : **les peintures de 1696 × 2528 sont réduites aujourd'hui au plus proche voisin**, à environ 196 pixels de large en 1080p | `grep -rn filterQuality lib` (vide) ; flame 1.38.2, `sprite.dart:162-164`, `sprite_component.dart:13`, `:129` |
| Les cadres redessinés n'ont pas de fond de fenêtre | Vrai : exportés calque par calque et superposés, aucun pixel opaque dans la fenêtre de 64 × 96, sur les cinq ; alpha 0 ou 255 seulement ; 31 % (tier 1) à 45 % (tier 5) de la bordure est opaque | `art_src/cadres/tier_1.aseprite` à `tier_5.aseprite`, par `aseprite_export.lua` |
| Ancrée au gabarit, une carte prend 292 pixels en 1080p à tout tier | Vrai au palier ×2 : 146 pixels de cadre (A9) ; six places et cinq écarts minimaux, 1822 pixels | A9 |
| Trois grilles sur un écran | Vrai, voulu : en 1080p, 3, 2 et 1 pixels d'écran par pixel de décor, de cadre et de créature | B72, B74 |

Et les mesures que la fiche demande en plus :

| Sujet | Mesure | Comment |
|:---|:---|:---|
| `assets/images/bg_dungeon.png` | **Un JPEG** (JFIF 1.01) de **1024 × 1024**, carré, étiré à la taille de l'écran ; seul fichier du dossier ; un seul lecteur | `file`, signature `ffd8ffe0` ; `heros_draft_game.dart:385-395`, `:411-413` |
| Les quatre sprites d'ennemis | PNG RGBA : Gobelin, Orc et Slime en **1696 × 2528**, **le Squelette en 1694 × 2528** | en-tête IHDR |
| Les images déclarées | `assets/images/` et les quatre dossiers d'ennemis ; `version: 0.6.1+1` | `pubspec.yaml:4` et section `assets:` |
| Un outil d'export `.aseprite` → PNG du jeu | **Aucun** : `aseprite_export.lua` exporte un PNG par calque et la liste des calques (pour reprendre un fichier) ; `aseprite_build.lua` et `aseprite_verify.lua` assemblent et vérifient ; `art_src/docs/workflow_decor.md`, étape 7, laisse ce chemin « à la vague qui pose le décor dans le jeu » | `art_src/tools/` |
| L'exécutable Aseprite | **Présent** : Aseprite 1.3.18.6, à `C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe`, trouvé par `aseprite_io.aseprite_exe()` (`ASEPRITE_PATH` non défini) ; `--version` répond, et les neuf sources de la vague ont été exportées avec lui dans un dossier de travail le 25/11 | `aseprite_io.py:14-31` |
| Les fonds de forêt | 128 × 192, un calque « Décor », opaques | export du 25/11 |
| Le décor validé | **`art_src/decors/forest/combat/forest_combat_detail.aseprite`** : 640 × 360, un calque « Décor », couleurs libres. Les autres fichiers du dossier sont ses sources : le plan (1280 × 720), l'image d'ensemble (1280 × 720), les deux repeintes (2560 × 1440 et 5120 × 2880), le brief | `forest_combat_brief.md` ; `art_src/INDEX.md` |
| Le placement de la maquette | Fenêtres centrées à 227, barre à 29 pixels de cadre au-dessus de la fenêtre, languettes à son haut − 1 : ce que A10 et §5.7 retrouvent. Son pas de 310 pixels, le même quel que soit le nombre d'ennemis, est arbitraire : A9 le remplace (306, 326, 536 en 1080p selon le nombre) | `decor_controle.py:34-40`, `:141-183` |
| La fenêtre du jeu au lancement, sous Windows | **1280 × 720**, sous le 1080p | `windows/runner/main.cpp:28-29` |
| Le plafond du plateau | Cinq ennemis à l'écran, la réserve au-delà ; dans un combat de boss, tous les ennemis portent `isBoss` | `combat_controller.dart:161`, `:170` |
| Les tiers atteignables | 1 à 3 : `maxTierAuthored` = 3 ; un tier s'ouvre tous les cinq actes | `encounter_system.dart:25`, `:55-58`, `:264` |

**Trois prémisses de documents sont fausses**, relevées pour `memory-bank-sync` et l'orchestrateur : la
[DA évolutive](../../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.2, donne à
une créature « 3 pixels d'écran en 1080p (×6) », que B72 remplace par un pixel ; le
[README du chantier](../../chantier_bestiaire/README.md), §1, fait voir au joueur de `0.6.2` chaque ennemi « sur un
fond de forêt », et la fiche de la vague elle-même, « sa créature sur un fond »
([`vague_2_visuel.md:91`](../../chantier_bestiaire/vague_2_visuel.md)) : ce fond est dormant en `0.6.2`, les anciens
sprites le couvrent (§2.1).

---

## 3. Où vit chaque chose

| Élément | Couche | Fichier | Pourquoi |
|:---|:---|:---|:---|
| La table des cadres | Donnée | `assets/data/tier_frames.json`, `assets/data/frames/tier_<n>.png` *(nouveaux)* | A2 |
| Son modèle | Données | `lib/models/data/tier_frame_data.dart` *(nouveau)* : `TierFrame`, `TierFrameTable` | 1:1 avec le document |
| Le dossier d'un lieu | Donnée | `assets/data/locations/<id>/` *(nouveau)* | A3 |
| Le catalogue des lieux, les écrans de décor | Données | `lib/models/data/location_data.dart` *(nouveau)* : `DecorScreen`, `LocationAssets`, `LocationCatalog` | Lu dans le manifeste, sans JSON |
| La lecture des assets par motif, la faute d'une règle croisée | Service | `lib/services/game_data_loader.dart` | §4.3 |
| Le chargement et ses refus | Service | `lib/services/game_data_service.dart` (`loadGameDataRegistry`, `currentLocationProvider`) | A4, A5, A7 |
| Le registre | Données | `lib/models/data/game_data_registry.dart` (`tierFrames`, `locations`, `imagesToPreload`) | Le seul porteur des données chargées |
| Le palier | Calcul pur | `lib/game/systems/board_scale.dart` *(nouveau)* | A8, §5.1 |
| Le cadrage d'un décor | Calcul pur | `lib/game/systems/decor_fit.dart` *(nouveau)* | Lu par Flame et par `ScreenScaffold` |
| Le recadrage d'une créature | Calcul pur | `lib/game/systems/creature_fit.dart` *(nouveau)* | A12, §5.4 |
| Le tirage du fond | Calcul pur | `lib/game/systems/window_background.dart` *(nouveau)* | A13, P3 |
| La rangée, la place d'une carte | Calcul pur | `lib/game/systems/enemy_row.dart` *(nouveau)* | A9, §5.6 |
| Le gabarit, la fenêtre et la zone d'un ennemi | Calcul pur | `lib/game/systems/entity_hover.dart` (`enemyZoneRect` remplace `enemyBodyRect`, `:8-9`) | À côté de `unfoldsInward` |
| La carte composée, son échelle, sa fiche | Flame | `lib/game/components/entities/enemy_card.dart` | A11, A18 |
| Le contour de ciblage et sa lueur | Flame | `lib/game/components/entities/target_outline.dart` *(nouveau)* | A14 |
| La barre, les languettes | Flame | `enemy_health_bar.dart`, `status_tabs.dart` | Ancrées au gabarit |
| Le rectangle d'ancrage commun | Flame | `combat_entity.dart` | A16 |
| Le décor du combat | Flame | `lib/game/heros_draft_game.dart` | Sous le voile de la fiche (B36) |
| Le palier courant | Flame | `heros_draft_game.dart` (`boardScale`, relu à `onGameResize`) | Lu par la rangée et les cartes |
| La rangée posée | Flame | `lib/game/systems/layout_system.dart` (`repositionEnemies`) | Le seul écrivain de la place d'un ennemi (ADR-121) |
| Le décor d'un autre écran | Flutter | `lib/ui/widgets/screen_scaffold.dart`, `lib/ui/widgets/location_backdrop.dart` *(nouveau)* | A6 |
| L'export | Outil | `art_src/tools/export_jeu.py` *(nouveau)* | A19 |

**Aucun champ neuf** sur `EnemyData`, `EnemyInstance`, `EntityStats`, `CombatState` ni `RunState`. `GameConstants`
gagne la fenêtre (64 × 96), le gabarit (88 × 120) et sa marge autour de la fenêtre (12), la largeur d'une
languette au repos (30) et son recouvrement de la carte (1) — **qui quittent `StatusTabs`** (`_restWidth` et
`_overlap`, `status_tabs.dart:33-34`, lus par `_restX`, `:123-124`) pour n'avoir qu'une source, lue par
`StatusTabs` et par `slotOf` —, les deux écarts de la rangée (7 et 122), la largeur utile (0,95) et la hauteur des fenêtres (0,21) ;
`inspectionScale` passe à 2 ; les constantes de la barre gardent leurs valeurs, lues désormais en pixels de cadre
depuis le haut du gabarit. Il perd ce que seul l'ancien placement lisait.

---

## 4. Données

### 4.1. La table des cadres

`assets/data/tier_frames.json` :

```json
{
  "frames": [
    { "tier": 1, "size": [88, 120], "window": [12, 12] },
    { "tier": 2, "size": [96, 128], "window": [16, 16] },
    { "tier": 3, "size": [104, 136], "window": [20, 20] },
    { "tier": 4, "size": [112, 144], "window": [24, 24] },
    { "tier": 5, "size": [120, 152], "window": [28, 28] }
  ]
}
```

| Clé | Contrainte, refusée au chargement sinon |
|:---|:---|
| `tier` | Entier ≥ 1 ; deux entrées du même tier sont refusées |
| `size` | Deux entiers pairs : la carte est ancrée en son centre, qui tombe ainsi sur un pixel entier à tout palier |
| `window` | L'offset du coin haut-gauche de la fenêtre de 64 × 96 ; la fenêtre tient dans le canevas, et le gabarit de 88 × 120 aussi ; **la fenêtre est centrée dans le canevas** — `window` vaut `((largeur − 64) / 2, (hauteur − 96) / 2)` —, puisque la carte s'ancre au centre de son canevas, qui doit être celui de sa fenêtre (A11, §5.7). Une fenêtre décentrée est une faute du chargement, remontée par `throwIfFailed` |

L'image d'une entrée est `assets/data/frames/tier_<tier>.png`, dont la présence au manifeste est contrôlée (A7). Le
document rejoint les documents de configuration plats : `test/unit/entity_id_convention_test.dart` le compte parmi
eux (`_configDocuments`, `:17-22`). `TierFrameTable.of(tier)` rend l'entrée, ou `null`.

### 4.2. Le dossier d'un lieu

```
assets/data/locations/forest/
├── combat.png        # 640 × 360, le décor de combat — obligatoire (A5)
├── window_1.png      # 128 × 192, les trois fonds de fenêtre (B67)
├── window_2.png
└── window_3.png
```

`DecorScreen` nomme les écrans qu'un décor peut habiller, et le fichier de chacun : `combat` (`combat.png` — le
combat, l'élite et le boss partagent l'écran de combat), `rest` (le repos et son choix de carte), `shop`,
`event`, `relicExchange` (`relic_exchange.png`), `forgeFusion` (`forge_fusion.png`). `LocationCatalog.fromAssetKeys(keys)` lit **toutes**
les clés `assets/data/locations/<id>/<fichier>` et rend, par lieu, `LocationAssets` : son `id`, ses décors par
écran, ses fonds de fenêtre dans l'ordre de leur numéro. **Refusés au chargement** : aucun lieu, ou plus d'un (A4) ;
un lieu sans `combat.png` (A5) ; des fonds autres que `window_1.png` à `window_3.png` exactement (B67, trois par
lieu) ; un nom de fichier que ni `DecorScreen` ni la règle des fonds ne connaissent ; **un fichier qui n'est pas un
`.png` en minuscules** — un `combat.jpg` ou un `combat.PNG` serait sinon ignoré en silence ; **un dossier dont l'id
n'est pas en `snake_case` ASCII minuscule**, la règle des ids d'entités, que `entity_id_convention_test.dart:25-33`
ne contrôle pas ici, puisqu'il ne parcourt que les `.json`. Une faute de frappe ne se perd pas en silence.
`LocationCatalog.current` rend le seul lieu, et **`null` pour un catalogue vide** : c'est le cas des registres
construits à la main que les tests d'écran injectent (`test/widget/event_screen_test.dart:62-72`), qui passeront par
`ScreenScaffold` puis `LocationBackdrop` — le refus de zéro lieu reste au chargement (A4), il ne vit pas dans
`current`. `LocationAssets.decorFor(screen)` rend le chemin, ou `null` : `null` est le repli de B76. Le jeu,
construit sans lieu (`location` nul, possible seulement avec un registre fait à la main), ne dessine pas de décor :
le fond de `backgroundColor` (`heros_draft_game.dart:488`) reste.

### 4.3. Le chargement

`GameDataLoader` gagne deux méthodes publiques : `assetsMatching(pattern)`, qui rend les clés du manifeste et
leurs segments capturés pour un motif — la règle de `_match` (`game_data_loader.dart:251-285`), sans lecture de
fichier — ; et `fault(message)`, qui ajoute une faute à celles que `throwIfFailed` remonte. `loadGameDataRegistry`
charge la table par `loadDocument`, lit les lieux par `assetsMatching('assets/data/locations/*/*')` — tout fichier, pour que ce qui n'est pas un PNG
soit refusé et non ignoré —, puis
ajoute les fautes de deux fonctions pures : `tierFrameFaults(enemies, frames, assetKeys)` (A7) et celles de
`LocationCatalog.fromAssetKeys`. Tout se remonte en une fois, avec les fautes des entités.

`GameDataRegistry` gagne `tierFrames` et `locations`, facultatifs au constructeur, comme `charges`
(`game_data_registry.dart:69`), pour ne pas casser les registres des tests ; `imagesToPreload`
(`:82-85`) y ajoute les cinq cadres et les images du lieu courant. `currentLocationProvider` rend le lieu courant,
ou `null` sans registre chargé (`valueOrNull`, comme `chargeCatalogProvider`) ou sur un registre sans lieu ;
`LocationBackdrop` ne dessine alors rien, et `ScreenScaffold` garde son fond d'aujourd'hui.

### 4.4. Ce qui disparaît

`assets/images/bg_dungeon.png`, et la ligne `assets/images/` du `pubspec.yaml` ; le chemin écrit en dur dans
`heros_draft_game.dart:386` et `:391`.

---

## 5. Le moteur : rendu et placement

### 5.1. Le palier — `boardScaleFor`

```dart
/// Le palier du plateau pour un écran (B72), en pixels logiques par pixel de cadre.
BoardScale boardScaleFor({
  required Size screen,              // taille logique du jeu
  required double devicePixelRatio,
  required double rowCenterY,        // le centre des fenêtres, logique (A10)
  required double rowFloorY,         // le haut de la carte du héros, logique
});

class BoardScale {
  final double frame;      // pixels logiques par pixel de cadre
  final bool crisp;        // vrai sur un palier pair entier en pixels physiques
  double get creature => frame / 2;
}
```

En pixels physiques, un palier `p` **tient** quand : la rangée de référence — six places de 146 et cinq écarts de
7, soit 911 pixels de cadre — tient dans 0,95 de la largeur ; le haut de la barre reste dans l'écran
(`rowCenterY − 77 p ≥ 0`) ; le bas du plus grand cadre reste au-dessus du héros (`rowCenterY + 76 p ≤ rowFloorY`,
76 = 48 + 28). **Le palier est le plus grand pair qui tient** ; `frame` = `p / devicePixelRatio`, `crisp` vrai.
`rowFloorY` est le haut de la carte du héros, telle qu'elle est posée aujourd'hui (`heros_draft_game.dart:403`,
`hero_card.dart:33`) : la fonction ne la déplace pas, elle la reçoit.

| Écran (logique, rapport) | Palier | Commentaire |
|:---|:---|:---|
| 1920 × 1080, 1 | ×2 | La rangée de six : 1822 pixels sur 1824 |
| 1920 × 1009, 1 (fenêtre maximisée) | ×2 | La hauteur tient : barre à 58, cadre jusqu'à 364, héros à 383 |
| 1536 × 864, 1,25 | ×2 physique, 1,6 logique | Un 1080p à 125 % |
| 2560 × 1440, 1 | ×2 sous la règle — **D1** | B72 écrit ×4 |
| 3840 × 2160, 1 | ×4 sous la règle — **D1** | B72 écrit ×6 |
| 1280 × 720, 1 | 1,335, non net — **D3** | La fenêtre du lancement |

**Quand aucun palier pair ne tient** (D3, recommandation (a)) : `frame` est le plus grand réel inférieur à 2 qui
tient — le plus petit des trois rapports —, divisé par le rapport de pixels, et `crisp` faux. Aucune autre règle ne
change : la rangée, la fiche et la barre suivent `frame`.

**Ce qu'elle remplace** : pour les ennemis, `scaleFactor` (`heros_draft_game.dart:72`, qui reste pour le héros et
la main), le facteur 1,45, le boss à 1,25 (B73), et `scaleMultiplier` avec son rétrécissement
(`layout_system.dart:113-127`). `HerosDraftGame` relit le palier à chaque `onGameResize` ; un palier inchangé ne
touche à aucune carte (chaque reconstruction de `GameScreen` rappelle `onGameResize` à taille inchangée — ADR-121,
point 6). Le rapport de pixels est lu sur la vue qui porte le jeu ; un test le passe en paramètre.

### 5.2. Le décor — `decorFitFor`

```dart
/// Le décor de 640 × 360 posé derrière un écran (B74) : son échelle et son coin haut-gauche, logiques.
DecorFit decorFitFor({required Size screen, required double devicePixelRatio});
```

**Sous P2, recommandation (a)** : le facteur physique est le plus petit qui couvre l'écran,
`max(largeur / 640, hauteur / 360)` en pixels physiques ; le décor est centré, ce qui dépasse est rogné. Il vaut 3,
4 et 6 en 1080p, 1440p et 4K (B74), 3 sur une fenêtre maximisée de 1920 × 1009 (71 pixels rognés, la moitié en haut,
la moitié en bas) et 2 en 1280 × 720. Le décor ne se lisse jamais.

Dans le combat, le décor est le `SpriteComponent` de `priorityBackground` (−100) qui remplace celui de
`bg_dungeon.png` (`heros_draft_game.dart:391-395`), lu sur `location.decorFor(DecorScreen.combat)` ; à chaque
`onGameResize`, il prend la taille et la place de `decorFitFor` au lieu d'être étiré à l'écran (`:411-413`). Il reste
sous le voile de la fiche (B36). Hors du combat, `LocationBackdrop` dessine le même cadrage (A6).

### 5.3. La carte composée

La carte d'un ennemi mesure le canevas de son tier, en pixels de cadre ; son échelle est `boardScale.frame` ; son
ancre, le centre du canevas, est le centre de sa fenêtre. Ses enfants, dans l'ordre où ils se dessinent :

| Priorité | Enfant | Rectangle, en pixels de cadre | Filtrage |
|:---:|:---|:---|:---|
| 0 | Le fond de fenêtre (A13, P3) | La fenêtre : 64 × 96 à l'offset de la table ; image de 128 × 192 | Aucun |
| 1 | La créature | La fenêtre ; la source selon `creatureFitOf` (§5.4) | Aucun, ou lissé pour un ancien sprite |
| 2 | Le cadre | Le canevas entier, à l'origine | Aucun |
| 3 | Le contour de ciblage et sa lueur (A14) | Autour de la fenêtre, à l'extérieur | — |
| 4 | La gangue de givre (`frost_shell.dart:19`) | La fenêtre (A15) | — |
| 5 | Le halo de Foudre (`charge_halo.dart`) | La fenêtre (A15) | — |
| 6 | Les languettes | Contre le gabarit (§5.7) | — |
| 7 | La barre de PV | Au-dessus du gabarit (§5.7) | — |

Le cadre n'est pas un rectangle plein : un tiers à près de la moitié de sa bordure est opaque, et rien ne suppose
une bordure opaque — ses jours laissent voir le décor, que la carte ne masque pas. Au-delà du tier 1, la barre et
les languettes passent sur le bord extérieur du cadre (B77). La teinte d'un coup (`_replaceSpriteTint`,
`combat_entity.dart:262-266`) joue sur la créature, que `CombatEntity.sprite` désigne désormais. **Un boss porte le
cadre de son tier, au même palier** : `isBoss` ne change plus la taille.

Le chargement de la carte (`enemy_card.dart:222-262`) ne calcule plus d'ajustement « contain » : les images —
cadre, fond, créature — sont préchargées par le jeu (§4.3), et la carte les lit dans le cache.

### 5.4. Les anciens sprites — `creatureFitOf`

```dart
/// La part de l'image d'une créature dessinée dans la fenêtre, et son filtrage (B75).
CreatureFit creatureFitOf(int imageWidth, int imageHeight);

class CreatureFit {
  final Rect source;   // en pixels de l'image
  final bool smooth;   // vrai : FilterQuality.medium ; faux : FilterQuality.none
}
```

| Image | `source` | `smooth` |
|:---|:---|:---|
| 128 × 192 : un sprite neuf | L'image entière | Faux |
| Une image qui contient le rectangle de B75 : un ancien sprite | **x 308 à 1388, y 329 à 1949 — 1080 × 1620**, au rapport 2:3 exact de la fenêtre | **Vrai** |
| Toute autre, dont l'image de remplacement de 64 × 64 de l'éditeur (§8) | L'image entière, étirée à la fenêtre | Faux |

**Le rectangle est mesuré**, et non deviné : c'est celui de la maquette de contrôle (`decor_controle.py:40`), sur
laquelle le décor de forêt a été validé le 24/11, re-mesuré le 25/11 sur les quatre peintures par des profils de
luminance moyenne — colonnes sur les rangées 700 à 1600, rangées sur les colonnes 500 à 1200. Sur les quatre, le
bord peint de l'illustration — un filet sombre, clair, sombre, d'environ 24 pixels — court de x 304 à 330 et de
1368 à 1392, de y 330 à 354 et de 1924 à 1948, à 4 pixels près à droite pour le Squelette, large de 1694. Le
rectangle part du bord extérieur de ce filet : réduit à 128 × 192, le filet laisse un trait d'environ 3 pixels de
créature à l'intérieur de la fenêtre, que le propriétaire voit au test (§11.2, M6). Le rectangle est une constante
de `creature_fit.dart`, écrite une fois ; elle part avec le dernier ancien sprite, l'Orc, en vague 6, avec la
branche qui la lit.

Le lissage sépare l'ancien sprite du neuf : une peinture de 1080 × 1620 se réduit d'un facteur 8,4 jusqu'à la
fenêtre de 128 × 192, que seul un filtrage à niveaux de détail rend propre ; un sprite neuf tombe sur des pixels
entiers et ne se lisse jamais.

### 5.5. Le fond de fenêtre — `pickWindowBackground`

```dart
/// L'indice du fond de fenêtre d'une carte qui naît, parmi les fonds du lieu (B67).
int pickWindowBackground({required int count, required Random random});
```

**Sous P3, recommandation (a)** : un tirage uniforme, par carte, à sa création (A13). La fonction reçoit son aléa :
un test la rejoue. Une réponse (b) lui ajouterait l'indice de la voisine.

### 5.6. La rangée — `placeRow`

```dart
/// Une place de la rangée, en pixels de cadre : sa largeur, et l'écart minimal qu'elle demande à ses voisines.
class RowSlot {
  final double width;
  final double gap;
}

/// Les abscisses des centres des places, logiques, calées sur le pixel physique (A9).
List<double> placeRow({
  required List<RowSlot> slots,
  required double unit,              // boardScale.frame
  required double screenWidth,
  double devicePixelRatio = 1,
});

/// La place d'une carte : le plus large de son cadre et du gabarit avec ses deux languettes au repos.
RowSlot slotOf(TierFrame frame, {double gap = GameConstants.enemyRowMinGap});
```

Entre deux places voisines, la distance minimale des centres est la demi-somme de leurs largeurs, plus le plus
grand de leurs deux écarts. **L'étalement** ajoute à chaque distance la même part, `0,85 × largeur / (n + 1)` moins
la moyenne des distances minimales, bornée à [0 ; 115] pixels de cadre — pour des places égales, c'est la règle
d'aujourd'hui (`layout_system.dart:132-133`) entre 153 et 268 pixels de cadre. La rangée est centrée sur l'écran ;
une place seule, au centre. Les abscisses des centres se calent sur le pixel physique, et l'ordonnée commune des
fenêtres aussi (ci-dessous).

| 1080p, ×2 | Distance des centres | Largeur de la rangée |
|:---|:---|:---|
| 6 places | 306 | 1822 |
| 5 places | 306 | 1516 |
| 4 places | 326 | 1271 |
| 2 places | 536 | 828 |

**Ce que les vagues suivantes y posent sans la reprendre** : le Rat, une carte de tier 1 entière (B72), dont la
place demande un écart plus serré que les autres (`RowSlot.gap`) ; **la meute**, trois cartes physiques — l'alpha
et ses deux rats, chacun sa carte de tier 1 entière, de part et d'autre de l'alpha et plus serrés (B7, B17, B18,
cadrage l. 59) —, que `placeRow` reçoit telles quelles, **trois places** dont les trois écarts sont serrés : la règle
du plus grand des deux écarts rend alors serrées les deux jointures rat–alpha, et ordinaire celle d'un rat avec un
ennemi hors de la meute. « Compte pour deux cartes » (B21, B30, cadrage l. 66) est le décompte du plafond du
plateau, que la composition du combat tient, pas une largeur de la rangée. `LayoutSystem.repositionEnemies` fait la
correspondance des cartes et des places ; `placeRow` ne connaît que des places. Les fenêtres se centrent toutes à
`0,21 × hauteur` (A10), **ordonnée calée elle aussi sur le pixel physique** — 0,21 × 1080 vaut 226,8 —, comme les
abscisses : `EnemyCard.place` reçoit ce centre, comme aujourd'hui sa place (`enemy_card.dart:125-130`), et les
écarts relatifs d'ADR-121 (point 6) restent.

### 5.7. La vague 1 sur les cadres

En pixels de cadre, dans les coordonnées de la carte, pour un cadre dont la fenêtre est à l'offset `(b, b)` :

| Élément | Géométrie | Mesures reprises de la vague 1 |
|:---|:---|:---|
| **La fenêtre** | `(b, b)` à `(b + 64, b + 96)` | — |
| **Le gabarit** (B77) | `(b − 12, b − 12)` à `(b + 76, b + 108)`, le même sur les cinq cadres ; le canevas même au tier 1 | — |
| **La barre et son voile** | x : le gabarit, 88 de large ; y : de 17 à 4 au-dessus du gabarit — son haut à 77 au-dessus du centre de la fenêtre, sur les cinq cadres | `enemyHealthBarTop` (−17), hauteur 13, rayon 4, texte 9, bouclier 8 à 3, montant à 2 (`game_constants.dart:48-55`) — leurs valeurs ne changent pas, elles se lisent depuis le haut du gabarit. À ×2 : 176 × 26 pixels, contre 196 × 25 aujourd'hui en 1080p |
| **Les languettes** | Au repos, collées aux côtés du gabarit, 1 dessus ; leur haut à 11 sous le haut du gabarit ; déroulées vers l'extérieur ; **vers l'intérieur (B39) par-dessus le gabarit**, leur bord extérieur au bord du gabarit | Repos 30 de large, déroulé de 30 à 120, pas de 31 et de 22 ou 30 (`status_tabs.dart:33-48`) : `StatusTabs` reçoit le rectangle d'ancrage au lieu de `cardWidth` (`combat_entity.dart:62-74`). Le héros passe le sien, sa carte entière : rien ne change pour lui |
| **Le contour de ciblage** (B78) | Autour de la fenêtre, à l'extérieur : le rectangle de la fenêtre agrandi de la moitié du trait | Ambre de 4 pour une carte choisie ou une fiche ouverte, cyan de 3 pour une cible possible, la lueur cyan pulsante de la surbrillance (`enemy_card.dart:353-364`, `:404-423`) ; **au repos, rien** : le liseré blanc disparaît. Le flash cyan d'un coup sur l'armure (`combat_entity.dart:143-167`) passe sur le contour |
| **La zone** (A17) | Le rectangle `(0, b − 29)` à `(largeur, hauteur)` du canevas — du haut de la barre au bas du cadre, coins de part et d'autre de la barre compris —, plus chaque languette par son rectangle dessiné et son rectangle au repos | La règle d'ADR-121, point 3 : la même zone pour le survol, l'appui et le lâcher, désormais lue aussi par `containsLocalPoint` de la carte. Au tier 1, `b − 29` = −17, la zone d'aujourd'hui ; au tier 5, −1 |
| **Les ancres** (A16) | Le haut et le bas du gabarit, à 60 du centre | Les textes flottants, l'icône d'effet, l'entaille (le gabarit × 1,5 : 132 × 180 au lieu de 150 × 210 pixels logiques, dessinés sans le palier comme aujourd'hui), la boule de feu (1,5 × 88 × l'échelle) |

Le sens du déroulé (B39) se lit comme aujourd'hui, sur le bord de la carte du côté de la languette
(`combat_entity.dart:119-136`) — c'est désormais le bord du gabarit. Une languette intérieure plus large que le
gabarit déborde de l'autre côté, comme elle débordait de la carte (ADR-121, « Ce qui reste ouvert »).

### 5.8. Le lieu

`GameScreen` passe au jeu, à sa construction, la table des cadres et le lieu courant (`currentLocationProvider`) ;
le jeu ne lit que ce qu'il reçoit. Le décor du combat est `decorFor(combat)` (§5.2) ; les fonds de fenêtre, la
liste du lieu (§5.5). Les autres écrans lisent le même lieu par `ScreenScaffold` (A6) : `LocationBackdrop` lit
`currentLocationProvider` et `decorFor(screen)` ; à `null`, `ScreenScaffold` garde son dégradé ou son parchemin
d'aujourd'hui (`screen_scaffold.dart:33-65`).

### 5.9. La fiche ouverte

La carte ouverte passe à `inspectionScale` = 2 (A18), barre et languettes comprises, puisqu'elles sont ses
enfants ; sa descente, 77 × le palier, garde le haut de sa barre où il était (B40) ; son contour passe à l'ambre.
Rien d'autre ne change de la vague 1 : les écarts relatifs, la retenue de l'échelle à `onGameResize`, la priorité
au-dessus du voile, `inspectionRect` (`enemy_card.dart:178-194`) qui lit la zone au repos à l'échelle d'arrivée et
nourrit `SheetPlacement`.

En 1080p, à ×4, une carte de tier 5 ouverte mesure 480 × 608 pixels, son haut de barre à 73, son bas à 685 ; avec
cinq cartes au plus, la carte ouverte du bord tient dans l'écran (son bord droit, languette au repos comprise, à
1864 sur 1920), et ce rapport tient à tout palier que la largeur fixe — la rangée de référence garde une place
libre. Le cas de six cartes est P4.

---

## 6. Textes joueur

Aucun. Aucune clé ARB, aucun texte de donnée ne change.

---

## 7. Le tutoriel

Rien. La maquette de combat de l'étape 6 (`tutorial_combat_overview_widget.dart:381-446`) dessine un ennemi
schématique — une icône et un nom —, sa barre au-dessus de la carte et à sa largeur : c'est encore vrai du
Gobelin, de tier 1, dont le cadre est le gabarit. Le tutoriel n'a pas de combat Flame.

---

## 8. L'éditeur de contenu

Rien ne change (A20). Un ennemi garde `tier` comme entier libre au gabarit (`entity_descriptor.dart:668-692`) : un
tier sans cadre est refusé au chargement suivant du jeu (A7), comme tout fichier fautif. L'image de remplacement
qu'il copie pour un ennemi neuf, de 64 × 64 (`entity_writer.dart:13`), entre entière dans la fenêtre (§5.4). Ni les
lieux ni la table des cadres ne sont des catégories de l'éditeur.

---

## 9. La sauvegarde

**Rien de neuf n'est sauvegardé ; aucun `schemaVersion` ne change.** Le palier se recalcule à chaque taille
d'écran, le fond de fenêtre est un état de la carte, le lieu est unique. La sauvegarde n'est jamais écrite en
combat ; avant la `1.0.0`, elle ne se transfère pas d'une version à l'autre.

---

## 10. L'export

### 10.1. L'outil

`python export_jeu.py <source.aseprite> <cible.png> [--taille LxH]`, depuis `art_src/tools/` : Aseprite, trouvé par
`aseprite_io.aseprite_exe()`, aplatit les calques **visibles** du fichier et l'écrit en PNG (`--batch … --save-as`,
A19) ; l'outil affiche les calques exportés et ceux qu'il a laissés, masqués, puis refuse une image dont la taille
n'est pas `--taille`. Il ne convertit aucune couleur : les cadres et les fonds restent en Apollo exact, le décor en
couleurs peintes (B80). Un PNG indexé, comme celui qu'Aseprite écrit d'un fichier en mode indexé, se charge dans le
jeu comme un autre. Une source retouchée se réexporte par la même commande.

### 10.2. Ce qui entre sous `assets/`

| Source (`art_src/`) | Cible | Taille |
|:---|:---|:---|
| `cadres/tier_1.aseprite` | `assets/data/frames/tier_1.png` | 88 × 120 |
| `cadres/tier_2.aseprite` | `assets/data/frames/tier_2.png` | 96 × 128 |
| `cadres/tier_3.aseprite` | `assets/data/frames/tier_3.png` | 104 × 136 |
| `cadres/tier_4.aseprite` | `assets/data/frames/tier_4.png` | 112 × 144 |
| `cadres/tier_5.aseprite` | `assets/data/frames/tier_5.png` | 120 × 152 |
| `fonds/forest/forest_window_1.aseprite` | `assets/data/locations/forest/window_1.png` | 128 × 192 |
| `fonds/forest/forest_window_2.aseprite` | `assets/data/locations/forest/window_2.png` | 128 × 192 |
| `fonds/forest/forest_window_3.aseprite` | `assets/data/locations/forest/window_3.png` | 128 × 192 |
| `decors/forest/combat/forest_combat_detail.aseprite` | `assets/data/locations/forest/combat.png` | 640 × 360 |

Pour un sprite, le chemin que la vague de chaque tier suivra : `sprites/<famille>/tier_<n>/<nom>.aseprite` →
`assets/data/enemies/<id>/sprite.png`, 128 × 192, ses calques tels que le sprite est livré (Ombre et Liseré
visibles). Aucun sprite n'est exporté dans ce lot.

### 10.3. Ce que `sync_assets` déclare

`dart run tool/sync_assets.dart` **ajoute** `assets/data/frames/` et `assets/data/locations/forest/`, et **retire**
`assets/images/`. `assets/data/`, déjà déclaré, couvre `tier_frames.json`. Après quoi
`dart run tool/sync_assets.dart --check` passe.

---

## 11. Tests

**Sous [ADR-113](../../../.obsidian_vault/_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)** : les
calculs, les données, les contrôleurs ; aucun test d'écran. Base : 1939 (journal du chantier), re-mesurée au début
du plan.

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| **Le palier** | `test/unit/board_scale_test.dart` *(nouveau)* | Les lignes du tableau de §5.1 : ×2 en 1920 × 1080 ; ×2 en 1920 × 1009 ; 1,6 logique en 1536 × 864 à 1,25 ; `creature` = `frame / 2` ; `crisp` ; **la rangée de six tient à ×2 en 1920 et ne tient plus si une place ou un écart grandit d'un pixel de cadre** ; un écran trop bas pour la barre ou pour le cadre fait tomber le palier. Les cas de 1440p et de 4K selon D1 ; celui de 1280 × 720 selon D3 |
| **Le décor** | `test/unit/decor_fit_test.dart` *(nouveau)* | 3, 4, 6 en 1080p, 1440p, 4K, sans décalage ; 3 en 1920 × 1009, centré ; 2 en 1280 × 720 ; le rapport de pixels ; les cas hors 16:9 selon P2 |
| **Le recadrage** | `test/unit/creature_fit_test.dart` *(nouveau)* | 128 × 192 → l'image entière, net ; 1696 × 2528 et 1694 × 2528 → le rectangle de §5.4, lissé, au rapport 2:3 exact, contenu dans l'image ; 64 × 64 → l'image entière |
| **Le fond** | `test/unit/window_background_test.dart` *(nouveau)* | Un indice dans `[0, count)` ; un aléa à graine rejoue le même ; selon P3 |
| **La rangée** | `test/unit/enemy_row_test.dart` *(nouveau)* | `slotOf` rend 146 aux cinq tiers ; les lignes du tableau de §5.6 ; une place seule au centre ; la rangée centrée ; deux places voisines jamais plus proches que leur distance minimale ; deux places à écart serré plus proches que deux ordinaires ; une place serrée à côté d'une ordinaire à l'écart ordinaire ; **une meute de trois places serrées** (rat, alpha, rat) entre deux ordinaires : deux jointures serrées, deux ordinaires, la rangée centrée ; des centres calés sur le pixel physique, ordonnée comprise |
| **La zone et le gabarit** | `test/unit/entity_hover_test.dart` | `enemyZoneRect` **sur les cinq tiers** (son haut à −17, −13, −9, −5, −1, la largeur du canevas), **coins compris** : un point au-dessus du canevas, de part et d'autre de la barre (au tier 2, x 2, y −10 ; au tier 3, x 4, y −5), est dans la zone ; le gabarit identique autour de la fenêtre sur les cinq cadres ; `unfoldsInward` inchangé |
| **L'appui par la zone** | `test/unit/combat_tap_forwarding_test.dart` | Réécrit (A17) : le renvoi de la barre (`:10-17`) et des languettes (`:27-38`) part avec leur `TapCallbacks` ; la zone d'appui de la barre (`:19-25`) devient un test de la zone de la carte ; le rectangle de repos d'une languette déroulée vers l'intérieur (`:40` et suivantes) reste, lu sur `zoneLocalRects` ; les languettes se construisent sur le rectangle d'ancrage et non plus sur `cardWidth: 100` (`:31`, `:44`) |
| **La table des cadres** | `test/unit/tier_frames_test.dart` *(nouveau)* | Sur un bundle de test (le seam du chargeur) : **un ennemi d'un tier sans cadre fait échouer le chargement, et le message nomme l'ennemi et le tier** ; une entrée sans image ; une fenêtre hors du canevas ; **une fenêtre non centrée dans son canevas** ; un tier en double ; une taille impaire. Sur les vraies données : cinq entrées, celles de §4.1 ; chaque PNG a la taille déclarée, sa fenêtre entièrement transparente |
| **Les lieux** | `test/unit/location_catalog_test.dart` *(nouveau)* | `fromAssetKeys` : la forêt, son décor de combat, ses trois fonds dans l'ordre ; refusés : aucun lieu, deux lieux, un lieu sans `combat.png`, deux ou quatre fonds, un nom inconnu, **un fichier qui n'est pas un `.png`** (`combat.jpg`, `combat.PNG`), **un dossier de lieu dont l'id n'est pas en snake_case** ; `decorFor(rest)` nul ; **un catalogue vide rend `current` nul**. Sur les vraies données : le lieu courant est la forêt, `combat.png` mesure 640 × 360, chaque fond 128 × 192 |
| **Les sprites livrés** | `test/unit/referential_integrity_test.dart` | Chaque `sprite.png` d'ennemi mesure 128 × 192 ou contient le rectangle de B75 (A12) |
| Les chemins | `test/unit/entity_id_convention_test.dart`, `real_bundle_load_test.dart` | `tier_frames.json` parmi les documents de configuration ; le manifeste réel déclare les cinq cadres et les quatre images du lieu |
| **La fiche** | `test/unit/heros_draft_game_targeting_test.dart` | Les tests de la vague 1 restent ; la carte ouverte est à deux fois l'échelle de repos, sa descente garde le haut de sa barre |

### 11.1. Ce qui s'atteint en jeu, et comment

Sans changer le menu de debug ([`_patterns/18-00`](../../../.obsidian_vault/_patterns/18-00-menu-de-debug-run-declaree-et-tiroir-ancre.md)) :

| Élément | Comment l'atteindre |
|:---|:---|
| Le cadre du tier 1 | Tout combat de l'acte 1 (Slime, Gobelin) |
| Le cadre du tier 2 | Onglet Run : acte 6, puis un combat (Squelette) |
| Le cadre du tier 3 | Onglet Run : acte 11, puis un combat (Orc) |
| **Les cadres des tiers 4 et 5** | **Pas en jeu** : `maxTierAuthored` = 3. Gardés par le test de la table (§11) et par la validation des assets du 25/11 |
| Le cadre d'un boss | Le boss de l'acte : il porte le cadre de son tier, à la taille des autres |
| Cinq cartes | Onglet Run : acte 5 ou plus ; un combat normal en tire jusqu'à cinq |
| **Six cartes, l'écart du Rat, la meute** | **Pas en jeu** : le test de la rangée |
| **Le fond de fenêtre** | **Pas en jeu, dormant** (§2.1) : le test du fond et celui des images du lieu |
| Le décor de combat | Tout combat |
| **Le décor d'un autre écran** | **Dormant** ; vérifiable sans rien commiter : copier `combat.png` en `rest.png` dans le dossier du lieu, relancer, ouvrir un repos, puis retirer le fichier (M19) |
| Les anciens sprites recadrés et lissés | Tout combat, les quatre ennemis |
| Le palier ×2 net | Un écran 1080p, plein écran ou fenêtre maximisée |
| Le plateau sous le 1080p | La fenêtre du lancement, 1280 × 720 |
| La fiche doublée | Toucher un ennemi, sans carte ni signature en attente |
| Le contour cyan, puis ambre | Une signature armée, ou une carte focalisée qui vise un ennemi |
| Les languettes au gabarit | Onglet Combat, section Charges : « +1 Gel » sur un ennemi (à droite) ; la Puissance de l'Orc (à gauche), acte 11 |

### 11.2. Les tests manuels

Le fichier de tests manuels de la vague (`bestiaire-vague-2`) les reprend ; voici leur liste.

| # | Ce que fait le propriétaire | Ce qu'il doit voir |
|:---:|:---|:---|
| M1 | Un combat de l'acte 1, plein écran 1080p | Chaque ennemi dans le cadre du tier 1, ronce aux coins bas-gauche et haut-droit, une gemme verte ; le décor de forêt entre les vrilles |
| M2 | Actes 6 et 11 | Les cadres des tiers 2 (deux gemmes violettes, des pousses) et 3 (trois gemmes rouges, des baies), plus grands ; la même fenêtre |
| M3 | Un combat à plusieurs tiers mêlés | Les créatures sur le même sol, les barres à la même hauteur, quel que soit le cadre (B77) |
| M4 | Regarde le décor | La forêt neuve, nette, sans flou ni étirement ; plus le donjon d'avant |
| M5 | Regarde de près un cadre et une barre | Le cadre aux pixels carrés et égaux ; trois grilles — décor, cadre, créature — qui ne se brouillent pas |
| M6 | Regarde les quatre anciens sprites | Chacun recadré sur son illustration, sans le cadre de parchemin peint, lissé, sans scintillement ; un trait fin de la bordure peinte peut se voir sur le bord de la fenêtre (§5.4) |
| M7 | Acte 5, cinq ennemis | La rangée tient dans l'écran, centrée, sans chevauchement, languettes au repos comprises |
| M8 | Un, deux, trois ennemis | Ils s'écartent, comme aujourd'hui |
| M9 | Survole un ennemi à une altération et un bonus, puis l'ennemi du bord | Les languettes contre le gabarit, déroulées vers l'extérieur ; vers l'intérieur au bord de l'écran (B39) ; sur un tier 3, elles passent sur le bord du cadre |
| M10 | Touche un ennemi, puis un ennemi de tier 3, puis celui du bord droit | La carte doublée, barre et languettes comprises, sa barre à la hauteur des autres (B40) ; le panneau de la fiche à sa taille, à côté ; la carte du bord reste dans l'écran |
| M11 | Signature armée, puis carte focalisée qui vise un ennemi | Le contour cyan autour de la fenêtre, à la même taille sur tous les tiers ; plus de liseré blanc au repos ; l'ennemi choisi en ambre |
| M12 | Touche une épine du cadre, le décor vu entre deux vrilles, le haut de la barre | Chaque fois l'ennemi : la fiche s'ouvre, ou la carte se joue |
| M13 | Glisse une carte sur un ennemi de tier 3, lâche-la sur son cadre | La carte se joue sur lui |
| M14 | Un coup, un gel (Onglet Combat : trois « +1 Gel »), une Foudre chargée | Les textes flottants au-dessus de la barre, à la même place sur tous les tiers ; la gangue et le halo sur la fenêtre, pas sur le cadre ; la teinte du coup sur la créature |
| M15 | Le boss de l'acte | Le cadre de son tier, à la taille des autres ennemis : plus d'agrandissement |
| M16 | Redimensionne la fenêtre : 1280 × 720 au lancement, puis maximisée, puis plein écran | Le plateau suit, sans saut au-delà du palier ; sous 1080p, selon D3 ; maximisé et plein écran, net |
| M17 | Fiche ouverte, redimensionne la fenêtre | La fiche suit sa carte (ADR-121, point 6) |
| M18 | Sur un écran 1440p ou 4K, ou sous un réglage d'affichage Windows à 125 % ou 150 %, si le propriétaire en a un | Le palier de D1, net ; à 125 %, les cadres aussi nets qu'à 100 % |
| M19 | Copie `combat.png` en `rest.png` dans `assets/data/locations/forest/`, relance, ouvre un repos ; puis retire le fichier | Le décor de forêt derrière le menu du repos ; sans le fichier, le fond d'aujourd'hui |
| M20 | Le repos, la boutique, un événement, l'autel, la forge | Leurs fonds d'aujourd'hui, inchangés |
| M21 | Regarde la barre de l'ennemi le plus à droite, en 1280 × 720 | Elle ne passe pas sous les boutons Son et Deck — ou le noter |

---

## 12. Le découpage

**Un seul plan, sept tâches et une huitième, la vérification finale.** L'invariant : **chaque tâche laisse un jeu
qui se lance et une suite verte**, et chacune s'écrit sur la géométrie que la précédente a fixée. Les données et les
fonctions pures d'abord, parce que tout le reste les lit et qu'elles se testent seules ; le décor, qui ne touche à
aucune carte ; la carte composée, puis la rangée qui la pose ; la vague 1 recalée en dernier, sur la carte et la
rangée définitives — c'est la tâche à risque, et elle ne doit se jouer qu'une fois.

| # | Tâche | Dépend de | Contenu |
|:---:|:---|:---|:---|
| 1 | Les assets et le chargement | — | `export_jeu.py` et les neuf PNG (§10) ; `tier_frames.json` ; les modèles `TierFrameTable` et `LocationCatalog` ; `assetsMatching` et `fault` ; les refus (A4, A5, A7) ; le registre, `imagesToPreload`, `currentLocationProvider` ; `sync_assets` ; leurs tests de données. `bg_dungeon.png` reste lu : il part en tâche 3 |
| 2 | Les fonctions pures | — | `boardScaleFor`, `decorFitFor`, `creatureFitOf`, `pickWindowBackground`, `placeRow` et `slotOf`, `enemyZoneRect` et le gabarit ; les constantes de `GameConstants` ; leurs tests |
| 3 | Le décor | 1, 2 | Le décor du combat au cadrage de `decorFitFor` ; `GameScreen` passe le lieu et la table au jeu ; `bg_dungeon.png` et `assets/images/` partent ; `ScreenScaffold` et `LocationBackdrop`, déclarés par les six écrans (A6) |
| 4 | La carte composée | 1, 2 | Le fond, la créature (`creatureFitOf`, le filtrage), le cadre ; la taille du canevas ; la gangue et le halo sur la fenêtre ; le fond tiré à la création. La barre et les languettes restent provisoirement ancrées au canevas |
| 5 | Le palier et la rangée | 2, 4 | `boardScale` relu à `onGameResize` ; l'échelle de la carte au palier, le boss à la taille des autres ; `repositionEnemies` sur `placeRow`, les fenêtres à 0,21 ; le retrait de `scaleMultiplier`, du facteur 1,45 et du rétrécissement |
| 6 | **La vague 1 sur les cadres** — *tâche à risque* | 4, 5 | La barre et les languettes au gabarit ; la zone, test d'appui de la carte, la barre et les languettes sans `TapCallbacks` (A17) ; le contour de ciblage et sa lueur (A14) ; la fiche doublée et sa descente ; `inspectionRect` ; les ancres des textes, de l'icône, de l'entaille et de la boule de feu (A16) ; leurs tests |
| 7 | La documentation de `art_src/` | 1 | `tools/README.md` (la commande d'export) ; `workflow_decor.md` étape 7, `workflow_fond.md`, `workflow_creature.md` (le livrable et son chemin vers le jeu) ; `decor_controle.py` n'est pas retouché |

**Pourquoi la tâche 6 est à risque** : des cartes de cinq tailles changent tout ce qui s'ancre à une carte
d'ennemi — la barre, les languettes, la zone que lisent le survol, l'appui et le lâcher, le contour, la fiche et sa
descente, le rectangle qui place son panneau. Le plan l'écrit en entier, et **son vérificateur la rejoue sur des
composants montés** (leçon 2 du [compte rendu de la vague 1](../reports/2026-11-22-bestiaire-vague-1-compte-rendu.md),
§5), par un test jetable : voir « Pour le Review Focus du plan ».

---

## 13. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| **ADR « le cadre de tier et le compositing »** — la carte composée en cinq calques, la fenêtre invariante et le gabarit (B73, B77) ; le palier pair sur les pixels physiques, la créature à la moitié (B72, A8) ; la rangée en fonction pure, des places de 146 (A9) ; le recadrage des anciens sprites par la taille de l'image (A12) ; la couture de lieu par le répertoire, le lieu unique et le décor par écran (B66, B76, A3 à A6) ; la table des cadres en donnée et le refus d'un tier sans cadre (A2, A7) ; l'export (A19) ; les réponses à D1 à D3 et P2 à P4 ; **les propositions de l'identité visuelle écartées** — la table `const` Dart (§4.1), `assets/art/frames/` et `assets/art/backgrounds/` (§7.2), et la migration validée `assets/images/` → `assets/art/` (§9, point 3), devenue sans objet (A2, A3, A5). **Amende [ADR-121](../../../.obsidian_vault/_adr/ADR-121-l-interface-des-ennemis-en-combat.md)** (la barre à la largeur du gabarit, les languettes contre lui, la zone du canevas devenue le test d'appui de la carte, la barre et les languettes qui ne renvoient plus d'appui, la fiche doublée au lieu de 1,25, le contour autour de la fenêtre et la fin du liseré blanc) et **[ADR-002](../../../.obsidian_vault/_adr/ADR-002-responsivite-dynamique-par-scalefactor.md)** (les ennemis quittent `scaleFactor`, que gardent le héros et la main). Le numéro suivant est ADR-123 | `memory-bank-sync` |
| Fiches `_patterns` : `05-3` (les lignes `EnemyCard`, `EnemyHealthBar`, `StatusTabs`, le contour neuf), `05-3-1` (`CombatEntity`, son rectangle d'ancrage, l'échelle de base doublée par la fiche), `05-4` (l'ordre des enfants d'une carte d'ennemi), `05-5` (la carte d'un ennemi : son canevas, sa fenêtre, son gabarit, le palier), `03-6` (`LayoutSystem` sur `placeRow`), `08-00` (`scaleFactor`, qui ne sert plus aux ennemis), `17-00` (`assetsMatching`, `fault`, `tier_frames.json`, les lieux), `05-11` (`ScreenScaffold` et son décor), `04-00` (ce que `GameScreen` passe au jeu) — un minimum, que le diff complétera | `memory-bank-sync` |
| `CLAUDE.md`, trois descriptions factuelles que le lot rend fausses : l'arbre de « Data-Driven Content Workflow » gagne `frames/`, `tier_frames.json` et `locations/<id>/` ; la couche de données (« models mapping 1:1 to the JSON assets », `CLAUDE.md:43`) gagne `tier_frame_data.dart` et `location_data.dart`, ce dernier lu dans le manifeste sans JSON ; `GameDataLoader` (`CLAUDE.md:47`) gagne `assetsMatching` et `fault`, publiques | Le plan les met à jour ; le compte rendu de la vague le signale au propriétaire |
| `docs/ROADMAP.md` : la ligne **P-08**, qui se clôt, et la ligne **P-05** | `memory-bank-sync`, à la fin de la vague — hors de cette spec |
| La note de version | Écrite à la fin par `patch-notes-writer` — hors de cette spec |

**Ce que le joueur voit en `0.6.2`** : les ennemis d'aujourd'hui, chacun dans un cadre qui dit son tier — une ronce
d'encre ajourée qui envahit le cadre de tier en tier, ses gemmes en haut —, sa créature recadrée sur son
illustration, dans une salle de combat redessinée, une forêt ; un plateau net, qui ne rétrécit plus ; un boss à la
taille des autres ennemis ; la barre, les languettes et le contour de ciblage autour de la fenêtre ; la fiche qui
double la carte. **À ne pas dire** : un fond de forêt derrière les créatures (dormant, §2.1), ni un changement de
règle — aucun ennemi ne fait autre chose qu'en `0.6.1`.

**Ce que le vérificateur contrôle** :

- aucune règle de combat ne change : `git diff e2a96432 -- lib/game/controllers lib/game/services` ne rend rien ;
  sous `assets/data`, seuls `tier_frames.json`, `frames/`, `locations/` et la note de version changent ;
- aucun modèle d'état ne change : `git diff e2a96432 -- lib/models` ne touche que `lib/models/data/`
  (`tier_frame_data.dart`, `location_data.dart`, `game_data_registry.dart`) ;
- plus aucun lecteur des pièces retirées : `git grep -n -e bg_dungeon -e scaleMultiplier -e visualWidthPerEnemy -e enemyBodyRect -- lib test`
  ne rend rien ;
- aucun test d'écran neuf (ADR-113) : `git diff e2a96432 -- test | grep -c '^+.*testWidgets(' || true` affiche `0` ;
- `dart analyze` propre ; `flutter test` vert ; `dart run tool/sync_assets.dart --check` passe.

---

## Pour le Review Focus du plan

- **Le rejeu sur composants montés** (tâche 6, par un test jetable du vérificateur) : `HerosDraftGame` monté en
  1920 × 1080, en 1920 × 1009 et en 1280 × 720, cinq ennemis de tiers 1, 1, 2, 3, 3 ; mesurer les centres des
  fenêtres (même ordonnée), les hauts de barre (même ordonnée), les places (disjointes, dans l'écran, languettes
  au repos comprises), l'échelle de chaque carte (le palier), puis, fiche ouverte, l'échelle (le double), le haut de
  sa barre (inchangé), le rectangle rappelé par `onInspectionChanged` ; un coup sur la carte ouverte la ramène au
  double et non au palier ; un `onGameResize` à taille inchangée ne coupe ni l'agrandissement ni la descente.
- **Le rapport de pixels** : où `HerosDraftGame` le lit, et comment `heros_draft_game_targeting_test.dart`, qui
  touche des `EnemyCard` jamais montées, l'obtient — la vague 1 y a déjà bouchonné `onInspectionChanged`.
- **La zone** : `findHoveredEnemy` (`card_interaction_handler.dart`) et `_livingEnemyAt`
  (`heros_draft_game.dart:342-353`) lisent la nouvelle zone sans changement de code ; un pointeur sur une épine, sur
  un jour du cadre, entre la barre et le gabarit, désigne l'ennemi.
- **L'ordre des enfants** : la barre, ajoutée aujourd'hui sans priorité (`enemy_card.dart:273-274`), passe au-dessus
  du cadre ; la gangue et le halo, enfants ajoutés en cours de combat par `refreshChargeVisuals`, gardent leur
  priorité et prennent la fenêtre.
- **Le préchargement** : `HerosDraftGame.onLoad` (`heros_draft_game.dart:385-389`) charge tout avant le premier
  rendu ; une carte créée avant la fin du chargement ne doit pas lire un cache vide.
- **`build/unit_test_assets`** ne se purge jamais : un cadre ou un lieu renommé pendant l'implémentation reste dans
  le manifeste des tests jusqu'à ce que le dossier soit vidé ; `bg_dungeon.png` y restera, sans lecteur.
- **Le test de la fenêtre transparente** décode les PNG dans `flutter test` : par le décodeur de Flutter, aucune
  dépendance neuve.
- **Un dossier de lieu vide ou un second lieu** dans `build/unit_test_assets` ferait échouer le chargement des tests
  réels : la règle A4 le dit clairement, le message doit nommer le dossier.
- **Les tests existants que le lot casse**, à réécrire dans la tâche qui les casse :
  `combat_tap_forwarding_test.dart:10-17`, `:19-25`, `:27-38` et les constructeurs de `:31`, `:44` (A17, §11) ;
  `flame_image_prefix_test.dart:59` (la clé `bg_dungeon` posée en dur) et `:66-67` (le canari `hasLength(8)`, qui
  devient 16 : trois classes, quatre ennemis, cinq cadres, quatre images du lieu, sans `bg_dungeon`) ;
  `real_bundle_load_test.dart:92` (`bg_dungeon` attendu au manifeste) ; les `HerosDraftGame(...)` construits par
  les tests (`flame_image_prefix_test.dart:12-35`, `heros_draft_game_targeting_test.dart:68-74`), qui reçoivent la
  table des cadres et un lieu, ou rien.
- **Les tests d'écran à registre manuel** (`test/widget/event_screen_test.dart:62-72` et leurs semblables) : un
  registre sans lieu donne `currentLocationProvider` nul, et `ScreenScaffold` son fond d'aujourd'hui (§4.2).
- **La zone sur les cinq tiers, coins compris** : le test de `enemyZoneRect` (§11) prend un point dans chaque coin
  au-dessus du canevas, de part et d'autre de la barre, aux tiers 2 à 5.
- **La marge de la 4K** : un test verrouille que ×4 tient en 3840 × 2160 à 4 pixels près (3644 sur 3648) et tombe à
  ×2 si une place ou un écart grandit d'un pixel de cadre (sous D1 recommandée).
- **La descente de la carte ouverte** vaut 77 × le palier sur les cinq tiers : un test par tier.
- **`entity_id_convention_test.dart`** : son compte de 143 fichiers d'entité (`:72-78`) ne tient que si
  `tier_frames.json` entre dans `_configDocuments` (`:17-22`).
- **La source du rapport de pixels** et son repli quand `buildContext` est nul (un jeu pas encore attaché, les
  tests sur cartes non montées) : le repli vaut 1.
- **Le commentaire de `game_data_loader_test.dart:338-347`** (« l erreur qui remonte ne peut venir que du document
  des icones d effet ») devient faux quand `tier_frames.json` est obligatoire : le test sert aussi ce document, ou
  le commentaire le dit.
- **Le contour qui remplace `RectangleComponent borderInfo`** : `CombatEntity` le déclare (`combat_entity.dart:32`)
  et `shieldHitAnimation` en écrit la couleur et le trait (`:165-166`) ; le héros garde son rectangle, l'ennemi passe
  au composant de contour (A14), sans que le flash cyan d'un coup sur l'armure ne se perde.
- **L'image de remplacement de 64 × 64 de l'éditeur** est tolérée au rendu (§5.4, troisième ligne) et refusée par
  le test des sprites livrés (§11) : c'est voulu — un ennemi créé par l'éditeur doit recevoir son vrai sprite avant
  d'être livré ; le test le dit dans son message.
