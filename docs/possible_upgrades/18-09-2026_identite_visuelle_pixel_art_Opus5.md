# Identité Visuelle Pixel Art — Canvas, Cadres d'Ennemi et Palette

**Date** : 18/09/2026
**Contexte** : Reprise à jour des deux brainstorms concurrents du 28/07/2026 (`cadre_ennemi_modulaire_par_tier`, `cadre_ennemi_procedural`), dont l'arbitrage était resté ouvert dans `ROADMAP.md` (P-08). Le fait nouveau qui les périme partiellement : **toutes les illustrations seront redessinées à la main sous Aseprite**, là où les deux documents raisonnaient sur des créatures générées. Ce document tranche, et couvre en plus les héros, la palette, le format de fichier et l'arborescence — trois angles morts des documents précédents.
**Statut** : Brainstorm — conception fonctionnelle validée par échange, **rien encore implémenté**, aucun asset produit.
**Remplace** : les sections de rendu de `28-07-2026_cadre_ennemi_modulaire_par_tier_Sonnet5.md` et `28-07-2026_cadre_ennemi_procedural_Sonnet5.md`. Les deux restent lisibles comme historique de l'exploration ; les décisions de §3 et §4 ci-dessous priment.

---

## 1. Constat de départ, mesuré

Les 7 illustrations d'entités du dépôt ne sont pas des sprites. Chacune est le rendu d'une **carte entière posée sur une table en bois** : cadre à entrelacs cuit dans l'image, bandeau de texte vide (≈20 % de la hauteur pour les ennemis), tranche des cartes voisines sur le bord droit, filigrane de générateur en bas à droite.

| Mesure | Valeur |
|:---|---:|
| Illustrations d'entités | 7 (3 classes, 4 ennemis) |
| Dimensions | 1696 × 2528 (squelette : 1694 × 2528) |
| Poids unitaire | 6,4 à 7,0 Mo |
| Poids de `assets/` | 47 Mo, dont ~46 Mo pour ces 7 fichiers |
| **Mémoire texture une fois décodées** | **~115 Mio** (16,4 Mio × 7, toutes préchargées par `images.loadAll` dans `HerosDraftGame.onLoad`) |
| Canal alpha | Entièrement opaque — un quart du poids pour rien |
| `assets/images/bg_dungeon.png` | **Un JPEG** (JFIF, 1024×1024, 300 DPI) sous une extension `.png` |

Deux défauts de rendu s'y ajoutent :

- `HeroCard` étire le sprite à la taille de la boîte sans préserver le ratio (`hero_card.dart:113-116`) : le héros est élargi d'environ 12 % en combat. `EnemyCard` le préserve correctement (`enemy_card.dart:79-105`) — les deux chemins divergent.
- **Aucun `FilterQuality` n'est fixé nulle part** dans `lib/`. Le filtrage dépend donc du défaut de Flutter, ce qui est précisément ce qu'il ne faut pas laisser au hasard quand on passe à du pixel art dessiné à la main.

> [!NOTE]
> Le diagnostic du doc modulaire de juillet (« le cadre est cuit dans chaque asset ») était juste mais sous-estimé : il y a aussi la table, les cartes voisines, le bandeau mort et le filigrane. « Détourer la créature » n'est donc pas un recadrage — c'est un redessin complet.

## 2. Ce que le code exige comme taille de rendu

`scaleFactor = clamp(size.y / 800, 0.85, 2.5)` (`heros_draft_game.dart:48`), puis `baseScale = scaleFactor × 1.45 × (boss ? 1.25 : 1) × scaleMultiplier` (`enemy_card.dart:52`), le multiplicateur ∈ [0.4, 1.0] servant à faire tenir N ennemis en largeur (`layout_system.dart:91-108`).

| Configuration | Échelle finale | Boîte rendue | DPR | px physiques |
|:---|---:|---:|---:|---:|
| Pixel 7 portrait, 3 ennemis | 0,76 | 76×106 | 2,6 | 198 × 276 |
| iPad portrait, 3 ennemis | 1,52 | 152×213 | 2 | 304 × 426 |
| Desktop 1080p | 1,72 | 172×241 | 1 | 172 × 241 |
| Desktop 1440p, boss | 2,95 | 295×413 | 1 | 295 × 413 |
| **4K plein écran, boss** | **4,53** | 453×634 | 1 | **453 × 634** |

**Le maximum à couvrir est donc ~455 × 635 px physiques.** Le héros plafonne à 390 × 520 (`hero_card.dart:26,109`).

## 3. Décisions de format

### 3.1 Échelle entière, pas fractionnaire

Le jeu scale aujourd'hui par 0,76 · 1,52 · 2,95 · 4,53. **Le pixel art ne survit pas à ça** : en filtrage linéaire il devient mou, en nearest-neighbour les pixels deviennent inégaux (certains 3 px, d'autres 4).

**Décision : échelle discrète `{½, 1, 2, 3, 4, 5}` + `FilterQuality.none` épinglé explicitement.**

Les entiers pour agrandir — chaque pixel d'art devient N×N pixels écran, parfaitement uniforme. Le palier ½ est la seule exception vers le bas : il jette un pixel sur deux, net, juste moins détaillé. **Il est retenu pour le portrait mobile**, où il donne des sprites nettement plus grands qu'aujourd'hui (l'audit responsive mesurait des ennemis écrasés à 46 % de leur taille).

Règle de sélection : prendre le plus grand palier tel que la rangée d'ennemis tienne dans la largeur disponible et la carte dans la hauteur allouée. Cela remplace à la fois le `scaleFactor` continu et le `scaleMultiplier` continu pour les entités.

Deux réserves assumées :

- **Le DPR reste fractionnaire sur mobile** (2,625 sur un Pixel 7) : l'échelle physique ne sera pas entière là-bas. Sans importance — à DPR ≥ 2 chaque pixel d'art fait déjà ≥ 2 pixels écran et l'irrégularité est invisible. Le cas où le scaling fractionnaire crève les yeux est le **desktop à DPR 1**, et c'est celui que cette décision règle.
- **Les animations procédurales décrochent volontairement de la grille.** Squash/stretch, dash et secousses cassent l'échelle entière le temps de l'impact. C'est un choix, pas un compromis : c'est ce qui donne la sensation de « vivant ». **L'échelle entière régit l'état de repos, les animations s'en affranchissent délibérément.**

### 3.2 Canvas

| Asset | Canvas natif | Note |
|:---|:---|:---|
| **Créature** (ennemi *et* héros) | **64 × 96** | Détourée, fond transparent |
| **Cadre de tier** | variable, voir §4 | Fenêtre invariante de 64 × 96 |
| Icône de coin (élément) | 12 × 12 | Loge dans la bordure du cadre |
| Icône de statut | 16 × 16 | Popups de combat |
| Icône de relique | 32 × 32 | |
| Icône de classe | 32 × 32 | Menu de sélection |
| Fond de carte à jouer | 64 × 88 | 4 types (`CardType` : attack, skill, power, status) |

64 × 96 est généreux pour du pixel art dessiné main — un humanoïde y occupe ~50×85 px, l'ordre de grandeur d'un sprite de boss SNES. Tous les canvas sont multiples de 16.

**Conventions de dessin à figer en même temps**, sans quoi la cohérence part dès la cinquième créature :

- **Ligne de sol commune** : pieds à `y = 92` (4 px de marge basse). Toutes les créatures partagent le même plancher.
- **Budget de hauteur par classe de taille** : petit 40-50 px · moyen 55-70 · grand 72-85 · boss remplit les 96. C'est ce qui empêche un rat d'avoir la taille d'un ogre.

### 3.3 PNG exclusivement

- **PNG** : sans perte, gère l'alpha. Obligatoire pour tout ce qui a de la transparence — créatures, cadres, icônes. Sans exception.
- **JPEG** : avec perte, pas d'alpha. Sa compression produit du *ringing* sur les arêtes dures, c'est-à-dire exactement sur ce qui définit le pixel art.

**Décision : aucun JPEG dans le projet.** `bg_dungeon.png` est un JPEG **et** est du pixel art — il porte donc déjà ces artefacts, que la reconversion ne récupérera pas. À défaut de le redessiner, renommer l'extension pour qu'elle dise la vérité (et mettre à jour `heros_draft_game.dart:151,156`) : un fichier qui ment sur son format est un piège.

## 4. Géométrie des cadres

### 4.1 Le principe : la fenêtre est l'invariant, pas le canvas

Les cadres partent d'une base commune, mais **l'épaisseur des bordures reste libre par tier** (en restant cohérente et lisible). Ce qui est strictement invariant, c'est l'intérieur :

> **Fenêtre = 64 × 96, identique sur les 5 cadres. Le canvas du cadre varie.**

| Tier | Canvas suggéré | Bordure |
|:---|:---|---:|
| 1 | 88 × 120 | 12 px |
| 2 | 96 × 128 | 16 px |
| 3 | 96 × 128 | 16 px |
| 4 | 104 × 136 | 20 px |
| 5 | 112 × 144 | 24 px |

Chaque cadre déclare son **offset de fenêtre** dans une table `const` Dart de 5 entrées — deux entiers par cadre, ce qui autorise des bordures asymétriques (base plus lourde) sans rien coûter.

> [!NOTE]
> Cela supprime le champ `windowRect` et la majeure partie du `enemy_frames.json` que proposait le doc modulaire de juillet : la **taille** de fenêtre est une constante du projet, seul l'**offset** est une donnée.

### 4.2 Trois conséquences

1. **C'est une fonctionnalité.** La créature garde exactement la même taille à l'écran quel que soit le tier (fenêtre invariante × même palier d'échelle), mais le cadre grossit. La menace se lit **avant** l'illustration — c'est la « taille hiérarchique » que réclamait `11-08-2026_systeme_carte_visuel_et_noeuds_Opus5.md` §6.3.
2. **Le layout doit s'adapter.** `layout_system.dart:98` calcule l'espacement depuis une constante unique `visualWidthPerEnemy = (100.0 + 70.0)`. Avec des largeurs variables, il faut sommer les largeurs réelles des cartes.
3. **Ancrage : sur le bord de la fenêtre, jamais sur le bord du canvas.** C'est ce qui rend la montée en gamme de §5.1 possible — un élément ancré à la fenêtre tombe au même endroit sur les 5 cadres quelle que soit la bordure. Ancré au canvas, il faudrait 5 variantes de chaque.

### 4.3 Fond de fenêtre : opaque en V1

Le cadre a un trou de 64×96 ; la question est ce qu'on voit derrière la créature détourée.

```
   Fenêtre opaque (retenue)              Fenêtre transparente
 ┌──────────────────────────┐          ┌──────────────────────────┐
 │ 4 · cadre + ornements    │          │ 4 · cadre + ornements    │
 │ 3 · créature détourée    │          │ 3 · créature détourée    │
 │ 2 · FOND rempli  ← opaque│          │ 2 ·   (trou)             │
 │ 1 · décor de combat      │  masqué  │ 1 · décor de combat ← vu │
 └──────────────────────────┘          └──────────────────────────┘
```

**Retenu : opaque**, avec le fond dessiné dans le cadre lui-même (donc variable par tier — un tier 5 peut avoir un fond plus noir). L'ennemi se lit comme *une carte posée dans la salle*, et le contraste des badges PV/attaque que le jeu dessine par-dessus est garanti par construction, quel que soit le décor ou le futur biome (P-12).

**Porte laissée ouverte, à coût nul** : le jour où chaque entité porte son propre décor, la créature cesse d'être détourée — c'est un sprite 64×96 **plein** qui remplit la fenêtre, et le fond du cadre devient inutile puisqu'il est couvert. Même canvas, même compositing, migration entité par entité, aucun code à changer.

## 5. Signalétique

### 5.1 Variantes d'Élite : médaillon dessiné (V1)

Le piège à éviter : 5 tiers × 5 affixes = 25 cadres si l'affixe est une variante. **L'affixe doit être une couche, pas une variante.**

Trois options ont été comparées :

| Option | Coût art | Expressivité |
|:---|:---|:---|
| **A — Calque superposé** (5 overlays alpha pleine taille) | 5 dessins | Forte : flammes qui lèchent les montants, givre qui envahit les coins, gravures qui saignent |
| **B — Médaillon ancré** (5 emblèmes ~24×24) | 5 petits dessins | Moyenne, très lisible |
| **C — Palette swap** (rampe d'accent échangée par le code) | 0 dessin | Couleur seule |

**Retenu pour la V1 : B.** Tout est dessiné à la main, donc long ; B livre les 5 affixes lisibles immédiatement et laisse le temps de peaufiner A et C. Le médaillon est **ancré sur le bord de la fenêtre** (§4.2.3), ce qui le fait tomber identiquement sur les 5 cadres.

**Trajectoire prévue** : A et C viennent se poser par-dessus sans rien casser. C (palette swap) porte alors la lecture couleur à distance, A la signature dessinée, B devient le blason central. Les trois sont additifs, pas concurrents.

> [!NOTE]
> Cela règle au passage un suivi resté en plan : la section « Rendu visuel » des Variantes d'Élite de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md` décrit encore un « halo lumineux autour de l'EnemyCard », option abandonnée dès juillet. Le signal passe par le cadre, jamais par un halo.

### 5.2 Affinités élémentaires et icônes dessinées

Les 4 icônes de coin (physique / feu / givre / foudre / poison) passent en 12 × 12 dessinés, dans un spritesheet.

**Le remplacement dans Flame est contenu** : `EffectIcon` (314 lignes, 6 familles de formes — defend/shield, poison/debuff, burn/fire, freeze/cold/ice, shock/lightning, buff/attack_buff) n'a que **deux sites d'appel** (`hero_card.dart:198`, `enemy_card.dart:327`).

**La vraie surface est l'UI Flutter**, qui aligne des icônes Material pour les mêmes concepts (`ui_card_helpers.dart` : `Icons.bolt_rounded`, `Icons.science_rounded`, `Icons.shield_rounded`…). Ne basculer que le combat laisserait le même statut avec une icône dessinée en combat et une icône Material dans le tooltip de carte. **Un inventaire complet des `Icons.*` est un prérequis** de ce sous-chantier, avant de dessiner quoi que ce soit.

## 6. Palette

**Retenue : [Apollo](https://lospec.com/palette-list/apollo), 46 couleurs.** Ses rampes désaturées correspondent au dark fantasy visé ; elle porte 3 rampes de verts (le bestiaire est vert : slime, gobelin, orc) et pierre/bois/parchemin pour le décor ; et sa désaturation fait que les accents saturés (feu, givre, foudre) ressortent sans forcer — exactement l'effet recherché pour les Variantes d'Élite.

Alternatives écartées : DawnBringer 32 (éprouvée mais look « indie générique », et 32 est serré pour un bestiaire + une signalétique), Resurrect 64 et AAP-64 (trop permissives pour un projet solo — la dérive revient), Endesga 36 (plus punchy, moins brumeux, second choix).

### 6.1 La règle qui compte plus que le choix de palette

Un sous-ensemble de la palette est **réservé au signalétique** et **interdit dans l'art des créatures** :

- 6 teintes de rareté (`CardRarity` : common → unique)
- 5 teintes d'affixe (Ardent, Foudroyant, Glacial, Vampirique, Parfait)
- 5 teintes élémentaires
- 3+ teintes de classe (nouveau champ `color` dans `class.json`)

> [!WARNING]
> **Le poison est vert et le bestiaire est vert.** Le vert « poison » doit être un vert acide/jaune employé sur aucune créature, sinon un gobelin empoisonné devient illisible. Même vigilance pour le rouge de dégâts contre les créatures rouges à venir.

### 6.2 Dette de couleur à solder dans la même passe

Aujourd'hui les couleurs de signalétique sont des constantes Material éparpillées (`Colors.orangeAccent`, `Colors.purpleAccent`…) entre `ui_card_helpers.dart` et `polychromatic_border.dart`. Plus grave : `getCardRarityColor()` résout la rareté **en comparant des chaînes localisées** (`ui_card_helpers.dart:182-213`). Et `25-07-2026_animations_juice_analysis_Opus5.md` signalait déjà « une palette élémentaire en 3 versions divergentes ».

Poser la palette impose de sortir ces couleurs dans **un fichier de tokens unique, indexé sur les `enum`** et non sur du texte traduit. C'est la condition pour que la palette soit réellement respectée.

## 7. Arborescence

### 7.1 La règle

> **Le répertoire est l'unité de déclaration.** Les déclarations d'assets Flutter ne sont récursives à aucun niveau : une ligne par répertoire, et *tous* les fichiers de ce répertoire sont embarqués.
>
> Un **dossier par entité** seulement quand l'entité a besoin d'un espace de noms à elle (classes et ennemis : plusieurs fichiers, plus un sous-dossier `cards/`). Sinon, **fichiers frères à plat**.
>
> Un **spritesheet** seulement pour un **vocabulaire fermé** que le jeu définit dans un `enum` et que le contenu n'étend pas.

Cette règle rejette le spritesheet pour les créatures **et** pour les reliques : ce sont des entités, et un sheet ferait de « ajouter une relique » l'édition d'un fichier partagé plus d'un index — l'inverse exact de ce que protège ADR-086.

### 7.2 Structure cible

```
assets/                                    # LE BUNDLE EXPÉDIÉ
├── data/                                  # entités — le contenu les étend
│   ├── classes/<id>/
│   │   ├── class.json                     # + iconPath, + spritePath, + color
│   │   ├── sprite.png                     # 64×96 — l'entité en combat
│   │   ├── icon.png                       # 32×32 — menu de sélection
│   │   └── cards/<id>.json
│   ├── enemies/<id>/
│   │   ├── enemy.json
│   │   └── sprite.png                     # 64×96 détouré
│   ├── relics/
│   │   ├── <id>.json
│   │   └── <id>.png                       # 32×32, fichier frère à plat
│   ├── cards/<id>.json
│   ├── events/, forge_upgrades/, passives/
│   └── audio.json, patch_notes.json
│
└── art/                                   # vocabulaires fermés — le jeu les définit
    ├── frames/
    │   ├── tiers.png                      # 5 cadres, canvas variable
    │   └── affixes.png                    # 5 médaillons ~24×24
    ├── icons/
    │   ├── elements.png                   # 5 × 12×12
    │   ├── statuses.png                   # 9 × 16×16
    │   ├── card_types.png                 # 4 × 64×88 (fonds de carte)
    │   └── nodes.png                      # types de nœuds (prépare P-31)
    └── backgrounds/
        └── dungeon.png

art_src/                                   # LES MASTERS — jamais expédiés
├── creatures/*.aseprite
├── frames/*.aseprite
├── icons/*.aseprite
├── palette.gpl                            # Apollo + réservation signalétique
└── branding/app_icon.png                  # 1024×1024, consommé au build
```

Quatre justifications :

1. **`assets/images/` disparaît au profit de `assets/art/`** — un nom qui dit ce qu'il contient plutôt que le format des fichiers.
2. **`art_src/` est hors de `assets/` par nécessité, pas par goût.** `assets/` est le bundle expédié : un `.aseprite` de 2 Mo ou une source d'icône 1024×1024 y gonfleraient le build pour rien, et `sync_assets.dart` les déclarerait automatiquement.
3. **Les index de spritesheet vivent en Dart, pas en JSON.** Une `const Map<CardType, Rect>` est vérifiée à la compilation — c'est le raisonnement déjà tenu par `11-08-2026_systeme_carte_visuel_et_noeuds_Opus5.md` §6.2 (Flutter élague les polices d'icônes au build, donc table `const`). Légitime **uniquement parce que** ces vocabulaires sont fermés.
4. **Padding de 1-2 px** entre les sprites d'un sheet, pour éviter que les pixels voisins bavent sur les bords.

### 7.3 Icône et titre de l'application

Tout dit encore `roguelike_card_game` :

| Fichier | À corriger |
|:---|:---|
| `android/app/src/main/AndroidManifest.xml:3` | `android:label` |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` |
| `web/index.html:32` | `<title>` |
| `web/manifest.json:2-3` | `name` / `short_name` |
| `macos/Runner/Configs/AppInfo.xcconfig:8` | `PRODUCT_NAME` |
| `pubspec.yaml:2` | `description: "A new Flutter project."` |

> [!WARNING]
> **Ne pas toucher `pubspec.yaml:1` (`name:`)** — c'est le nom du package Dart, chaque import du projet est un `package:roguelike_card_game/…`. Le renommer, c'est réécrire tous les imports pour zéro bénéfice joueur.

Les 30+ déclinaisons d'icône des 5 plateformes se génèrent depuis `art_src/branding/app_icon.png` via `flutter_launcher_icons`. Une source, une commande.

## 8. Impacts sur le code

| Zone | Changement |
|:---|:---|
| `hero_card.dart:113-116` | Fin de l'étirement : boîte = canvas créature × palier, sprite 1:1 |
| `hero_card.dart:26,109` | Boîte 120×160 → 64×96 × palier ; le héros n'a **pas** de cadre |
| `enemy_card.dart:52,63` | Boîte = canvas du cadre du tier × palier ; échelle discrète |
| `enemy_card.dart:65-112` | Compositing 3 couches : fond de fenêtre → créature → cadre (+ médaillon) |
| `layout_system.dart:91-108` | Espacement depuis les largeurs réelles, plus depuis une constante |
| `heros_draft_game.dart:48` | `scaleFactor` continu → sélection de palier dans `{½,1,2,3,4,5}` |
| `game_constants.dart:15-17` | `cardWidth/Height` 140×196 → 128×176 (palier entier) |
| `effect_icon.dart` | Formes vectorielles → sprites du sheet `elements`/`statuses` |
| `ui_card_helpers.dart:182-213` | Couleurs de rareté : sortir des chaînes localisées vers des tokens sur `enum` |
| partout | `FilterQuality.none` épinglé explicitement sur les peintures de sprite |

## 9. Migrations validées

1. **`classes/<id>/icon.png` → `sprite.png`.** Aujourd'hui `icon.png` contient le portrait de combat. Avec l'arrivée d'une vraie icône de classe (menu de sélection) dans le même dossier, le nom deviendrait activement faux. `HeroData` porte alors les deux champs : `spritePath` (aligné sur `EnemyData`) et `iconPath` (le vrai sens du mot). Impacte `class.json`, `hero_data.dart`, `game_data_registry.dart:44`.
2. **Icônes de relique en fichiers frères** dans `assets/data/relics/`. **Aucune modification du chargeur** : le motif est `assets/data/relics/*.json` (`game_data_service.dart:92`), un `.png` frère ne le matche pas, et le répertoire est déjà déclaré — donc zéro ligne de `pubspec.yaml` supplémentaire.
3. **`assets/images/` → `assets/art/`**, et création de `art_src/` hors bundle.

Toute création de répertoire impose `dart run tool/sync_assets.dart`.

## 10. Effort & risque

| Bloc | Effort | Risque |
|:---|:---:|:---|
| Échelle entière + `FilterQuality` + fin de l'étirement héros | 0,5-1 j | Faible — mais touche le layout de combat, à valider en playtest |
| Compositing 3 couches dans `EnemyCard` + table des cadres | 1 j | Faible — la fenêtre invariante supprime l'alignement |
| Arborescence + 2 migrations + `sync_assets` | 0,5 j | Faible — mécanique, mais touche `entity_id_convention_test.dart` |
| Tokens de couleur (raretés, éléments, affixes, classes) | 0,5 j | Faible — supprime une fragilité existante au passage |
| Sheets d'icônes + remplacement `EffectIcon` | 0,5 j | Faible côté Flame ; l'inventaire des `Icons.*` UI est le vrai travail |
| Titre + icône d'application (5 plateformes) | 0,25 j | Nul |
| **Production artistique** | **le chemin critique réel** | 7 créatures + 3 icônes de classe + 5 cadres + 5 médaillons + ~19 icônes, à la main |

**Gains mesurés attendus** : disque 46 Mo → ~300 Ko (×150) ; mémoire texture ~115 Mio → ~0,7 Mio (×150) ; entrée en combat instantanée au lieu du décodage bloquant de 46 Mo. **Aucun gain de FPS attendu** — le nombre de sprites dessinés ne change pas, et avec ≤ 6 entités à l'écran la réduction des changements de texture est du bruit.

## 11. Points ouverts

- **Le portrait mobile reste le cas faible.** Le palier ½ donne des sprites plus grands qu'aujourd'hui, mais `05-08-2026_audit_responsive_mobile_tablette_Opus5.md` classait déjà cette orientation « injouable » pour d'autres raisons (2 cartes sur 5 hors écran, panneaux HUD superposés). Ce chantier améliore la lisibilité des ennemis sans régler le fond.
- **Le fond de combat.** `bg_dungeon.png` est un JPEG non redessiné : il jurera avec de l'art pixel dessiné main. Le redessiner est hors périmètre ici, et se pose de toute façon avec **P-12 Biomes** (15 illustrations de fond).
- **Illustrations de carte.** `CardData.spritePath` (`card_data.dart:55`) existe et n'est renseigné par aucun fichier. Ce document ne couvre que les **fonds par type** (4), pas une illustration par carte (23 cartes).
- **Les 4 cadres restants.** Le doc modulaire de juillet prévoyait de laisser les ennemis existants en full-art avec un chemin de rendu *legacy*. Tout étant redessiné, **ce compromis disparaît : un seul chemin de rendu, pas de dette**. À acter explicitement dans l'ADR pour que personne ne réintroduise la branche.
- **Ordre de dessin.** Commencer par un cadre de tier 2 (bordure médiane) et une créature, pour valider la lisibilité à l'échelle 1 et 2 avant d'en produire 25.

## 12. Prochaines étapes possibles

1. **Dessiner une paire de validation** — un cadre tier 2 + une créature — et la regarder en jeu aux paliers ½, 1, 2 et 4 avant d'investir plus loin. C'est le prototype de 0,5 jour que `ROADMAP.md` P-08 réclamait, avec une décision de pipeline désormais prise.
2. **Charger Apollo dans Aseprite** et marquer la réservation signalétique dans `art_src/palette.gpl` — c'est le document qui empêche la dérive.
3. **Passer ce brainstorm en ADR** (`.obsidian_vault/_adr/`, via la skill `memory-bank-sync` pour la numérotation), puis en spec d'implémentation dans `docs/superpowers/specs/`.
4. **Mettre à jour `ROADMAP.md`** : P-08 est tranché, et il conditionnait la production des 5 sprites de P-05.
5. **Corriger la dérive documentaire** des brainstorms de juillet-août, qui citent encore `enemy_goblin.png`, `enemies.json`, `hero_berserker.png` et « 8 PNG dans `assets/images/` » — tous périmés depuis P-48 (05/09/2026).