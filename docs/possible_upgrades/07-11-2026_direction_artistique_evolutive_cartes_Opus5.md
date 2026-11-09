# Direction artistique évolutive — les cartes à jouer d'abord

**Date** : 07/11/2026 · **Mise à jour** : 08/11/2026 (échelle A retenue, série pilote de six cartes, §14)
**Contexte** : idée du propriétaire : le merging fait déjà progresser les valeurs d'une carte, il doit aussi faire progresser son dessin. Une *Frappe* commune est griffonnée, une *Frappe* légendaire est une illustration achevée. Les cartes à jouer ouvrent la marche parce que c'est le terrain le plus simple ; le concept pourra ensuite s'étendre au reste du jeu.
**Statut** : Exploration — **rien n'est implémenté, aucun asset n'est produit**. Seules les décisions de §2 sont acquises ; tout le reste est une proposition.
**Maquettes** : [`docs/presentations/2026-11-07_da_evolutive_cartes_maquettes.pptx`](../presentations/2026-11-07_da_evolutive_cartes_maquettes.pptx) — 19 diapositives, citées ci-dessous sous la forme *(diapo 2)*. Elles sont générées par code : les diapos 1 à 13 à partir d'un seul motif d'épée, les diapos 14 à 19 à partir de six autres cartes (§14). Elles servent à juger l'écart entre les styles, pas la qualité que chaque style peut atteindre.
**Croise** : [Identité visuelle pixel art](18-09-2026_identite_visuelle_pixel_art_Opus5.md) (voir §12, Q5) · [Rareté et fusion](../../.obsidian_vault/_rules/02-4-progression-de-rarete-dynamique-et-fusion-int.md)

---

## 1. L'idée en bref

**Le style de dessin d'une carte raconte son niveau.** Le modèle est *Evoland*, qui parcourt l'évolution des graphismes du jeu vidéo au fil de la partie. Ici, le même mouvement passe uniquement par le dessin, et il est porté par chaque carte.

| | Evoland | Hero's Draft |
|:---|:---|:---|
| Ce qui évolue | Tout le jeu d'un seul coup | Chaque carte, indépendamment |
| Ce qui déclenche | L'avancée dans l'aventure | La rareté de la carte |
| Ce qu'on voit à un instant donné | Une seule époque à l'écran | **Plusieurs époques dans la même main** |
| Ce qui se passe à la run suivante | — | Tout repart du griffonnage |

La troisième ligne est la différence qui compte, et c'est aussi le principal risque : voir §11. La main devient en revanche un résumé de la run : pleine de griffonnages au départ, de plus en plus aboutie ensuite *(diapos 11 et 12)*.

## 2. Ce qui est acquis

Décisions du propriétaire (échange du 07/11/2026, et du 08/11/2026 pour la sixième) :

1. **Le style suit la rareté de la carte**, pas le nombre de fusions. Une carte pré-forgée de la boutique arrive directement avec le style de sa rareté.
2. **Le changement est purement visuel** : aucun effet sur l'équilibrage ni sur les règles.
3. **Le premier palier est forcément le griffonnage** (*doodle*), volontairement brouillon. Le pixel art 16×16 cité pour le deuxième palier n'est qu'un exemple.
4. **Le critère de réussite** : on connaît le niveau d'une carte **sans regarder ni son niveau ni sa rareté**.
5. **On commence par les cartes à jouer.**
6. **L'échelle A est retenue** : griffonnage → pixel 16×16 → pixel 64×64 → dessin animé → peinture numérique (§8). Le test du tri sur de vrais dessins reste à faire, mais il n'est plus là pour choisir l'échelle : il sert à la valider.

## 3. Le point de départ, mesuré

Mesures du 07/11/2026 sur le code et les données.

| Constat | Valeur | Conséquence |
|:---|:---|:---|
| Échelle de rareté | 5 raretés, `CardRarity.fusionRank` de 0 à 4 ([`_rules/02-4`](../../.obsidian_vault/_rules/02-4-progression-de-rarete-dynamique-et-fusion-int.md)) | **5 paliers de style**, et un point d'entrée unique déjà prêt dans le code |
| Cartes au catalogue | 33 (14 attaques, 15 compétences, 4 pouvoirs, aucune de statut), **toutes communes de base** | 165 dessins pour une couverture complète |
| Illustrations de cartes | **Aucune** | Le chantier introduit l'illustration elle-même, pas seulement son évolution |
| Zone d'illustration | **Aucune** : le titre en haut, les badges d'effet centrés, le type à `y = 175` ([`card_text_renderer.dart:363`](../../lib/game/components/widgets/card_text_renderer.dart#L363)) | La mise en page de la carte doit changer (§7.1) |
| Taille de la carte | 140 × 196, multipliée par `scaleFactor × 0,88`, soit de 0,75 à 2,2 selon la hauteur de la fenêtre ; 166 × 233 px sur un écran 1080p | Le style doit se lire à cette taille *(diapos 3, 11, 12)* |
| Repère du type | La couleur de fond ([`card_component.dart:80`](../../lib/game/components/card_component.dart#L80)) | Un fond de papier l'efface (§7.3) |
| Chemins de rendu | Deux : `CardComponent` en Flame (combat) et `UiCard` en Flutter (deck, boutique, dictionnaire), avec des proportions différentes (140:196 et 70:110) | Le dessin devra tenir dans les deux |
| Filtrage d'image | `FilterQuality` n'est fixé nulle part dans `lib/` | Le filtrage devra être choisi par palier (§10) |
| Obtenir une rareté haute | La fusion, ou la boutique, qui monte de 2 crans au plus ([`shop_controller.dart:75`](../../lib/game/controllers/shop_controller.dart#L75)) | Toutes les cartes étant communes de base, **épique et légendaire ne s'obtiennent que par fusion** |

Une fusion consommant 3 copies, le coût d'un palier croît vite : **1 · 3 · 9 · 27 · 81 communes** de la commune à la légendaire, ou 9 rares pour une légendaire à partir de la boutique. La fréquence réelle de chaque palier en partie n'est pas mesurée, mais les premiers seront à coup sûr les plus vus. Le griffonnage est donc **le dessin que le joueur verra le plus**, et il mérite plus de soin que son apparence ne le laisse croire.

## 4. Comment juger un style

Quatre critères, dans cet ordre.

1. **Le tri tout seul** — cinq cartes mélangées, sans chiffres ni couleur de rareté : l'ordre doit être évident pour quelqu'un qui ne connaît pas l'échelle *(diapo 3)*. C'est la traduction directe de la décision 4 de §2. Un style beau mais sans place évidente dans l'ordre est éliminé.
2. **Un changement de nature entre voisins** — deux paliers voisins doivent différer par leur technique (trait, grille de pixels, aplats, lumière), pas seulement par leur finition. Le trait doit se voir à 166 px de large.
3. **Une famille de couleurs propre à chaque palier** — appris en faisant les maquettes : avec une palette voisine, le pixel 64 et la peinture se confondaient en petit, malgré des techniques opposées.
4. **Un coût tenable, multiplié par 33** — et par chaque future carte du catalogue.

Une règle de dessin rend ces comparaisons possibles : **la composition reste la même d'un palier à l'autre.** La *Frappe* est toujours la même épée, au même angle. C'est ce qui fait voir une évolution plutôt que cinq images sans rapport.

## 5. Le catalogue complet

74 styles en 5 familles. Le numéro renvoie aux maquettes quand un échantillon existe *(diapos 6 et 7)*.

**Lecture des colonnes — ce sont mes estimations, rien n'est mesuré.** *Palier* : où le style tomberait naturellement. *Lisible* : sa reconnaissance à la taille de la main, de ★ à ★★★. *Coût* : l'effort par carte, de € à €€€. *Éch.* : ✓ si les maquettes en montrent un échantillon. « Hors concept » signale un style qui n'est plus vraiment du dessin : il est listé pour que la liste soit complète.

### 5.1 Le trait à main levée

| N° | Style | On le reconnaît à | Palier | Lisible | Coût | Éch. |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| TR1 | **Griffonnage au stylo bille sur feuille lignée** | Encre bleue, traits repassés, lignes du cahier | 1 | ★★★ | € | ✓ |
| TR2 | Griffonnage sur post-it | Carré jaune, feutre fin | 1 | ★★★ | € | |
| TR3 | Griffonnage de marge de cahier | Ratures, flèches, petites notes | 1 | ★★ | € | |
| TR4 | Bonhomme bâton, dessin schématique | Formes réduites à l'extrême | 1 | ★★★ | € | |
| TR5 | Dessin d'enfant aux crayons de couleur | Coloriage qui dépasse, grain de cire | 1-2 | ★★★ | € | ✓ |
| TR6 | Feutre épais sur carton | Gros trait noir, fond kraft | 1-2 | ★★★ | € | |
| TR7 | Craie sur ardoise | Trait clair poudreux, fond sombre | 1-2 | ★★★ | € | ✓ |
| TR8 | Craie grasse sur trottoir | Couleurs vives, sol granuleux | 1-2 | ★★ | € | |
| TR9 | Crayonné avec lignes de construction | Traits de mise en place visibles | 2 | ★★ | € | ✓ |
| TR10 | Crayonné propre et ombré | Graphite net, hachures d'ombre | 2-3 | ★ | €€ | ✓ |
| TR11 | Fusain | Noirs profonds, estompe | 2-3 | ★★ | €€ | ✓ |
| TR12 | Sanguine, étude d'atelier | Monochrome rouge, papier crème | 3 | ★★ | €€ | |
| TR13 | Plan technique | Blanc sur bleu, cotes, quadrillage | 2-3 | ★★★ | € | ✓ |
| TR14 | Planche de storyboard | Cases, flèches de mouvement | 2 | ★★ | € | |
| TR15 | Peinture rupestre | Ocre sur roche, silhouette | ? | ★★ | € | ✓ |
| TR16 | Carnet de voyage, plume et lavis léger | Encre fine, touches de couleur | 3 | ★★ | €€ | |

### 5.2 L'écran

| N° | Style | On le reconnaît à | Palier | Lisible | Coût | Éch. |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| EC1 | ASCII | Une image faite de caractères | 1-2 | ★★ | € | ✓ |
| EC2 | Caractères semi-graphiques (PETSCII, télétexte) | Blocs et couleurs primaires | 2 | ★★ | € | |
| EC3 | Vecteurs lumineux d'écran cathodique | Lignes néon sur noir | 2 | ★★ | € | ✓ |
| EC4 | Pixel 8×8 monochrome | Pictogramme minuscule | 2 | ★★ | € | |
| EC5 | Pixel 16×16, 2 à 4 tons de console portable | Palette verte ou grise | 2 | ★★★ | € | ✓ |
| EC6 | **Pixel 16×16 en couleur** | Très gros pixels, 4 à 8 couleurs | 2 | ★★★ | € | ✓ |
| EC7 | Pixel 24×24 | Gros pixels, un peu de détail | 2-3 | ★★ | € | |
| EC8 | Pixel 32×32, 16 couleurs et tramage | Dégradés en damier | 3 | ★★ | €€ | ✓ |
| EC9 | **Pixel 64×64 ombré** | Pixels fins, volumes, ambiance | 3 | ★★★ | €€ | ✓ |
| EC10 | Pixel 128×128 | Presque lisse, très détaillé | 3-4 | ★ | €€€ | ✓ |
| EC11 | Pixel art isométrique | Vue de trois quarts stricte | 3 | ★★ | €€€ | |
| EC12 | Pixel art avec balayage cathodique | Lignes horizontales sur l'image | 3 | ★★ | €€ | |
| EC13 | Vectoriel plat des années Flash | Formes lisses, contours épais | 3-4 | ★★ | €€ | |
| EC14 | Icône brillante des années 2000 | Reflets vitrés, dégradés | 3-4 | ★★ | €€ | |
| EC15 | Faux rendu 3D pré-calculé, dessiné | Volumes plastiques | 4 | ★★ | €€€ | |
| EC16 | Low poly | Facettes planes | 4 | ★★ | €€€ | Hors concept |

### 5.3 L'encre et l'imprimerie

| N° | Style | On le reconnaît à | Palier | Lisible | Coût | Éch. |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| EN1 | Encrage noir et blanc | Trait net, noirs francs | 2-3 | ★★★ | €€ | ✓ |
| EN2 | Encrage et aplats de couleur | Couleurs plates, sans ombre | 3-4 | ★★★ | €€ | ✓ |
| EN3 | Ligne claire (BD franco-belge) | Trait uniforme, décor net | 4 | ★★ | €€ | ✓ |
| EN4 | Comics tramé | Points d'imprimerie, contours épais | 4 | ★★★ | €€ | ✓ |
| EN5 | Manga encré | Trames grises, lignes de vitesse | 4 | ★★★ | €€ | |
| EN6 | **Dessin animé (*cel*)** | Aplats, ombre dure, couleurs franches | 4 | ★★★ | €€ | ✓ |
| EN7 | Gravure sur bois | Noir et blanc taillé, rayons | 3-4 | ★★★ | €€ | ✓ |
| EN8 | Taille-douce | Hachures très fines | 4 | ★ | €€€ | |
| EN9 | Linogravure | Formes massives, éclats | 3 | ★★ | €€ | |
| EN10 | Risographie | 2 encres décalées, grain | 3 | ★★ | €€ | ✓ |
| EN11 | Sérigraphie pop | Couleurs saturées et plates | 3-4 | ★★★ | €€ | |
| EN12 | Pochoir urbain | Silhouette, éclaboussures | 2-3 | ★★ | € | |
| EN13 | Lavis d'encre | Coup de pinceau, sceau rouge | 3-4 | ★★ | €€ | ✓ |
| EN14 | Estampe japonaise | Contours souples, dégradés doux | 4 | ★★ | €€€ | |
| EN15 | Affiche art déco | Géométrie, or et noir | 4 | ★★★ | €€ | ✓ |
| EN16 | Affiche constructiviste | Diagonales, rouge et noir | 3-4 | ★★ | €€ | |

### 5.4 La peinture

| N° | Style | On le reconnaît à | Palier | Lisible | Coût | Éch. |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| PE1 | Feutres à alcool | Dégradés doux, teintes vives | 3 | ★★ | €€ | |
| PE2 | Crayons de couleur soignés | Grain fin, ombres douces | 3 | ★★ | €€ | |
| PE3 | Pastel sec | Matière poudreuse et douce | 3-4 | ★★ | €€ | |
| PE4 | Aquarelle | Bords sombres, transparences | 3-4 | ★★ | €€ | ✓ |
| PE5 | Gouache | Matière mate, touches visibles | 4 | ★★ | €€€ | ✓ |
| PE6 | Acrylique | Couleurs denses, coups de brosse | 4 | ★★ | €€€ | |
| PE7 | Huile | Empâtements, lumière | 5 | ★★ | €€€ | ✓ |
| PE8 | **Peinture numérique d'apparat** | Lumière, éclat, particules | 5 | ★★★ | €€€ | ✓ |
| PE9 | Clair-obscur baroque | Sujet éclairé sur un fond noir | 5 | ★★★ | €€€ | |
| PE10 | Impressionnisme | Touches séparées, lumière | 4-5 | ★★ | €€€ | |
| PE11 | Pointillisme | Image faite de points | 4 | ★★ | €€€ | |
| PE12 | Couverture de roman de fantasy | Héroïque, très détaillé | 5 | ★★ | €€€ | |
| PE13 | Peinture animée sur quelques images | Le dessin bouge : flamme, éclat | 5 | ★★★ | €€€ + | |
| PE14 | Peinture en calques avec parallaxe | Profondeur au survol | 5 | ★★★ | €€€ + | |

### 5.5 L'apparat et l'artisanat

| N° | Style | On le reconnaît à | Palier | Lisible | Coût | Éch. |
|:---|:---|:---|:---:|:---:|:---:|:---:|
| AP1 | Enluminure médiévale | Fond bleu et or, parchemin | 4-5 | ★★★ | €€€ | ✓ |
| AP2 | Vitrail | Plombs noirs, couleurs franches | 4-5 | ★★★ | €€ | ✓ |
| AP3 | Mosaïque | Image en petites tesselles | 3-4 | ★★ | €€ | ✓ |
| AP4 | Tapisserie médiévale | Trame textile, couleurs passées | 4 | ★★ | €€€ | |
| AP5 | Point de croix | Pixels faits de fil | 2-3 | ★★ | €€ | |
| AP6 | Papier découpé | Couches, ombres portées | 3 | ★★★ | €€ | |
| AP7 | Papyrus, hiéroglyphes | Profils plats, ocres | ? | ★★ | €€ | |
| AP8 | Céramique à figures noires | Silhouette noire sur terre cuite | ? | ★★ | €€ | |
| AP9 | Art nouveau | Arabesques, cadre végétal | 4-5 | ★★ | €€€ | |
| AP10 | Feuille d'or, métal gravé | Reflets dorés, relief | 5 | ★★ | €€€ | |
| AP11 | Pâte à modeler | Volumes, empreintes | ? | ★★ | €€€ | Hors concept |
| AP12 | Reflet holographique | Un effet qui s'ajoute à un autre style | 5 | ★★★ | € | Combinable |

## 6. Les styles recommandés

| Palier | Recommandé | Alternatives à garder | Pourquoi ce choix |
|:---|:---|:---|:---|
| **1 · Commune** | **TR1** Griffonnage au stylo bille | TR2 Post-it · TR7 Craie, si le papier éclaire trop la main | Imposé par §2 ; le plus immédiat, et le support raconte le cahier |
| **2 · Peu commune** | **EC6** Pixel 16×16 en couleur | TR5 Crayons · EN1 Encrage, pour une échelle sans pixels | Ton exemple. Le saut du papier à l'écran est impossible à manquer, et c'est le palier le moins cher |
| **3 · Rare** | **EC9** Pixel 64×64 ombré | EC8 Pixel 32×32 · EN2 Aplats | Quatre fois plus fin : la progression se lit sans explication. EC8 est plus proche de 16×16 et moins franc |
| **4 · Épique** | **EN6** Dessin animé | EN4 Comics tramé · EN2 Aplats · EN3 Ligne claire | Le deuxième saut : les pixels disparaissent au profit d'un trait lisse et de couleurs fortes |
| **5 · Légendaire** | **PE8** Peinture numérique d'apparat | PE7 Huile · PE9 Clair-obscur · AP12, à ajouter | La lumière et la matière n'existent qu'ici. C'est le seul palier qui ait droit à l'éclat |

**À écarter pour l'échelle des cartes**, malgré leur intérêt :

- **TR15, AP7, AP8** — aucune place évidente dans l'ordre.
- **EC10, TR10, EN8** — leur détail disparaît à 166 px.
- **EC16, AP11** — ce n'est plus du dessin.

**À garder pour plus tard** : PE13 (peinture animée) et AP12 (reflet holographique) sont les deux moyens les plus sûrs de rendre le dernier palier impossible à confondre. L'un coûte cher, l'autre presque rien, puisque le reflet au survol existe déjà sur les bordures.

## 7. Le rendu sur la carte

### 7.1 Une fenêtre plutôt qu'un plein cadre

*(diapos 8 et 9)*

| | Fenêtre 126 × 96 | Plein cadre |
|:---|:---|:---|
| Impact en petit | Bon, grâce au support | Le meilleur |
| Chiffres et texte | Sur un fond calme | Voile et pastille nécessaires |
| Pire cas (7 runes, longue description) | Prises par-dessus le dessin, texte sous la fenêtre | Tout se superpose |
| Grille des pixels | 21 × 16 à ×6, 84 × 64 à ×1,5 : **tombe juste** | Dépend de la taille de la carte |

**Recommandation : la fenêtre.** Elle occupe `x` de 7 à 133 et `y` de 34 à 130 sur la carte de combat. Le contenu doit cesser de pousser le dessin : les prises de rune et le badge d'*Usage Unique* passent par-dessus, à des positions fixes.

### 7.2 Le style habille toute la carte

Le dessin n'est pas seul à évoluer : le **support** (fond, cadre, police du titre) évolue avec lui. C'est ce qui rend le tri évident, et c'est le levier le moins cher du chantier : 15 images pour toutes les cartes, contre 165 dessins *(diapo 10)*. Avec ce seul support, le jeu change déjà de visage.

**Ce qui ne bouge jamais**, pour que la lecture reste instantanée : la position des éléments, les chiffres dans une seule police, les médaillons de coût.

### 7.3 Le type de carte reste lisible

La couleur de fond indique aujourd'hui le type : rouge pour l'attaque, bleu pour la compétence, ambre pour le pouvoir. Le papier efface ce repère. **Chaque support existe donc en 3 versions**, une par type *(diapo 10)*. La couleur de rareté, elle, peut rester sur la bordure : elle devient redondante, mais elle ne coûte rien et reste utile à la lecture du deck.

La série pilote (§14) montre une limite à cette teinte : au palier 4, le fond magenta du dessin animé tire la compétence vers le violet *(diapo 15)*. La teinte du type devra y être plus forte, ou le fond du palier plus neutre.

Le fond clair du griffonnage impose aussi un texte sombre : la couleur du texte devient une donnée du palier, alors qu'elle est blanche partout aujourd'hui.

### 7.4 La révélation à la fusion

Le saut de style est **la récompense visuelle de la fusion**, et il doit se voir à cet instant. Aujourd'hui, le dialogue de fusion se referme sur le choix d'une rune ([`deck_screen.dart:230`](../../lib/ui/screens/deck_screen.dart#L230)). Une piste : montrer dans ce dialogue la carte qui passe d'un style au suivant, avant le choix de la rune. C'est sans doute le moment le plus mémorable du concept, et il reste entièrement visuel.

## 8. Les échelles complètes

*(diapos 4 et 5 ; la diapo 4 mélange les images pour permettre le test du tri)*

| | Échelle | 1 | 2 | 3 | 4 | 5 | Avis |
|:---:|:---|:---|:---|:---|:---|:---|:---|
| **A** | **Les âges du dessin de jeu** | TR1 | EC6 | EC9 | EN6 | PE8 | **Retenue le 08/11/2026 (§2, décision 6).** Ordre évident, deux seuils nets (papier → écran, pixels → trait lisse), la plus proche de l'idée d'Evoland et de ton exemple |
| B | L'atelier | TR1 | TR10 | EN1 | EN2 | PE7 | La moins chère : chaque palier repart du précédent, comme les étapes d'une vraie illustration. Mais les paliers 2 et 3 sont proches en petit, et le voyage est moins spectaculaire |
| C | Les matières | TR1 | TR5 | PE4 | PE5 | PE7 | La collection la plus belle. Mais l'ordre est moins évident : aquarelle ou gouache d'abord ? |
| D | L'histoire de l'art | TR1 | TR15 | AP1 | EN7 | PE7 | **Non recommandée.** Une belle idée, mais rien ne dit qu'une gravure vaut plus qu'une enluminure : elle échoue au premier critère |

Ce classement est mon jugement sur des échantillons générés. Il se refait sur de vrais dessins (§13).

## 9. La production

**Le volume, avec l'échelle A :**

| Lot | Images | Source native | Effort |
|:---|---:|:---|:---:|
| Supports (5 paliers × 3 types) | 15 | Selon le palier | € |
| Palier 1 · Griffonnage | 33 | Dessin ou scan | € |
| Palier 2 · Pixel 16×16 | 33 | 21 × 16 sous Aseprite | € |
| Palier 3 · Pixel 64×64 | 33 | 84 × 64 sous Aseprite | €€ |
| Palier 4 · Dessin animé | 33 | 504 × 384 | €€ |
| Palier 5 · Peinture | 33 | 504 × 384 | €€€ |
| **Total** | **180** | | |

**Chaque nouvelle carte coûtera désormais jusqu'à 5 dessins.** C'est le vrai coût de long terme, et la règle de repli ci-dessous est ce qui empêche ce coût de bloquer l'ajout de contenu.

**La règle de repli** : si un dessin manque à un palier, la carte garde **le dernier dessin disponible, sur le support de sa rareté**. Sans aucun dessin, elle garde la mise en page actuelle, sur le bon support. Chaque lot est ainsi livrable seul, et une carte reste jouable sans son art.

**L'ordre proposé :**

1. Les 15 supports.
2. *Frappe* aux 5 paliers, puis le test du tri sur de vrais dessins, avant toute production de masse.
3. Les 33 griffonnages et les 33 pixel 16 : les moins chers et les plus vus.
4. Le palier 3, puis le palier 4.
5. Le palier 5 en dernier : le plus cher et le plus rare. C'est aussi celui dont le joueur se souviendra, donc il ne se sacrifie pas pour autant : il attend seulement que l'échelle soit confirmée.

## 10. Le mécanisme

**Une échelle est une donnée, pas du code.** Elle associe une clé (la rareté pour les cartes) à une suite de paliers. Changer de style à un palier, ou comparer deux échelles, ne doit demander aucune modification de Dart.

```jsonc
// assets/data/art_ladders.json — document de configuration plat, comme audio.json
{
  "cards": {
    "key": "rarity",
    "stages": [
      { "style": "doodle", "filter": "smooth", "ink": "#1A286E", "support": "paper",      "titleFont": "..." },
      { "style": "pix16",  "filter": "pixel",  "ink": "#FFFFFF", "support": "pixel_low",  "titleFont": "..." },
      { "style": "pix64",  "filter": "pixel",  "ink": "#FFFFFF", "support": "pixel_high", "titleFont": "..." },
      { "style": "cel",    "filter": "smooth", "ink": "#FFFFFF", "support": "comic",      "titleFont": "..." },
      { "style": "paint",  "filter": "smooth", "ink": "#FFF4D6", "support": "gold",       "titleFont": "..." }
    ]
  }
}
```

- **Les images** : `assets/images/cards/<style>/<id_de_carte>.png`. Un dossier par style, donc 5 lignes de plus dans `pubspec.yaml`, générées par `tool/sync_assets.dart`, et le nom du fichier reste l'identifiant de l'entité.
- **Le point d'entrée** : une fonction pure `(id de carte, rareté) → (palier, chemin du dessin)`, qui applique le repli de §9. `CardRarity.fusionRank` donne déjà l'indice du palier. Lue par les deux chemins de rendu, elle garde Flame et Flutter découplés, et elle se teste comme un calcul, sans test de widget (D77).
- **La sauvegarde** : rien à ajouter. La rareté y est déjà, et le style s'en déduit.

**Trois points techniques à prouver sur la carte pilote :**

| Point | Détail |
|:---|:---|
| Des pixels nets à une échelle continue | La carte a une échelle fractionnaire (1,188 en 1080p), ce qui rend les pixels inégaux en filtrage `none`. Piste à essayer : agrandir l'image à l'avance en plus proche voisin, puis la filtrer normalement. La décision du 18/09 d'une échelle entière porte sur les entités, pas sur les cartes |
| Deux proportions de carte | Le combat est en 140:196 et `UiCard` en 70:110 : le dessin doit être recadré sans couper le sujet |
| La mémoire | Une image de 504 × 384 occupe 0,74 Mio une fois décodée, soit 24 Mio pour tout un palier. C'est acceptable à condition de charger à la demande les cartes du deck, et non tout le catalogue au démarrage |

**Reprendre le mécanisme ailleurs** : seule la clé change. Ce ne sont que des pistes pour plus tard.

| Domaine | Clé déjà présente dans le code | Remarque |
|:---|:---|:---|
| Reliques | `RelicRarity` (5 raretés) | Le plus simple : mêmes paliers, peu d'images |
| Ennemis | `EnemyData.tier` | Une brute griffonnée puis un boss peint : fort, mais en tension avec l'identité pixel du 18/09 (Q5) |
| Signatures | Le niveau d'évolution | Elles ne sont pas des cartes (ADR-109), mais elles évoluent déjà |
| Héros | Le niveau de run | Le héros mûrit avec la run |
| Carte du monde, décors | L'acte | C'est la version la plus proche d'Evoland, tout le monde change ensemble |

## 11. Les risques

| Risque | Pourquoi | Parade |
|:---|:---|:---|
| **Le patchwork** | Cinq époques dans la même main *(diapo 12)* | Une mise en page strictement commune ; à vérifier en jeu sur une vraie main |
| **Le griffonnage éclipse la peinture** | Sur le donjon sombre, le papier clair est la chose la plus visible de l'écran : le bas de l'échelle attire plus l'œil que le haut *(diapos 11 et 12)* | Un papier moins lumineux, un support sombre (TR7 Craie), ou un éclat réservé au palier 5 |
| **« Le jeu n'est pas fini »** | Un nouveau joueur ne voit que des griffonnages pendant ses premières minutes | Assumer le cahier : un support soigné, un griffonnage plein de charme, et une fusion montrée tôt au tutoriel |
| **Deux paliers se confondent** | Palette voisine ou finition trop proche | Une famille de couleurs par palier (§4) ; le test du tri avant la production de masse |
| **Le coût bloque le contenu** | Jusqu'à 5 dessins par nouvelle carte | La règle de repli (§9) |
| **Le type ne se lit plus** | Le fond ne porte plus seul la couleur | 3 versions de chaque support (§7.3) |

## 12. Les questions ouvertes

| | Question | Ma recommandation |
|:---:|:---|:---|
| **Q1** | Quelle échelle ? | **Tranchée le 08/11/2026 : A** (§2, décision 6) |
| **Q2** | Fenêtre ou plein cadre ? | Fenêtre |
| **Q3** | Le support évolue-t-il avec le dessin, police du titre comprise ? | Oui pour le fond et le cadre ; la police du titre reste à juger en jeu |
| **Q4** | **Qui dessine, et avec quel budget ?** Le document du 18/09 prévoit des illustrations à la main sous Aseprite, ce qui couvre bien les paliers 2 et 3. Les paliers 1, 4 et 5 demandent d'autres outils et d'autres compétences. Indication du propriétaire (08/11/2026) : le dessin final sera plus probablement fait à la main | À trancher avant le lot de masse : c'est la décision qui pèse le plus sur la faisabilité. En attendant, les images générées de §14 peuvent servir de remplaçants provisoires et de gabarits |
| **Q5** | **Comment concilier avec l'identité pixel du 18/09 ?** Celle-ci prévoit un fond de carte de 64 × 88 par type, que ce document remplacerait. Le reste du jeu pourrait rester en pixel art, les cartes le traversant : en dessous au palier 1, au même niveau aux paliers 2 et 3, au-delà aux paliers 4 et 5 | Garder le pixel art pour le monde, et ne pas étendre l'échelle aux ennemis tant que les cartes n'ont pas fait leurs preuves |
| **Q6** | Y a-t-il une révélation à la fusion, et sous quelle forme ? | Oui, à concevoir après la carte pilote |
| **Q7** | Le palier 5 a-t-il droit à un traitement à part (animation, reflet) ? | Le reflet d'abord, car il ne coûte presque rien |
| **Q8** | Garde-t-on le générateur d'images de §14 ? Il vit hors du dépôt, dans un dossier temporaire, et il est écrit en Python alors que `tool/` ne contient que du Dart | À décider avant d'aller au-delà des sept cartes : sans lui, les images générées ne se refont pas |

## 13. Les prochaines étapes possibles

1. **Le propriétaire regarde les maquettes** et tranche Q2 et Q4, au moins provisoirement. Q1 est tranchée (A).
2. **Une carte pilote** : *Frappe* aux 5 paliers, dessinée pour de vrai, avec les 15 supports. C'est le seul moyen de confirmer le test du tri et de chronométrer le coût réel de chaque palier ; le tableau de §9 n'est qu'une estimation. La série générée de §14 ne remplace pas cette étape : elle montre que l'échelle tient sur des sujets variés, pas ce qu'elle coûte à la main.
3. **Un essai jouable**, branché derrière le repli de §9, pour juger le patchwork et l'éclat du papier sur une vraie main.
4. **Si l'essai convainc** : une entrée dans `docs/ROADMAP.md`, une spec, puis la production par lots. Rien de tout cela n'est engagé par ce document.

## 14. La série pilote générée (08/11/2026)

*(diapos 14 à 19)*

Une fois l'échelle A retenue, six cartes de plus ont été générées aux cinq paliers, avec la même méthode que l'épée. Elles ont été choisies pour couvrir la difficulté, de l'objet simple au visage. Les deux dernières lignes du tableau étaient le vrai test : une idée sans objet, et une créature.

| Carte | Type | Difficulté | Ce qui est dessiné |
|:---|:---|:---|:---|
| *Défense* | Compétence | Objet simple | Un écu frappé d'une croix, sous un arc de protection |
| *Boule de feu* | Attaque | Effet en mouvement | Une boule de feu qui file, sa traînée en langues de flamme |
| *Potion de soin* | Compétence | Objet + symbole | Une fiole ronde, un cœur dans le liquide, des croix de soin autour |
| *Métallisation* | Pouvoir | Objet + effet abstrait | Une cuirasse entre deux flèches circulaires, l'armure qui revient chaque tour |
| *Concentration* | Compétence | Idée abstraite | Deux cartes qui s'envolent de la pioche |
| *Forme démoniaque* | Pouvoir | Visage, créature | Un masque cornu aux yeux jaunes, dans un halo de flammes |

Sept cartes sur 33 existent donc maintenant aux cinq paliers, *Frappe* comprise. Il en reste 26. Les 6 signatures ne fusionnent pas ([ADR-109](../../.obsidian_vault/_adr/ADR-109-signatures-hors-du-deck.md)) : elles sortent de cette échelle, et leur cas reste celui de §10.

### 14.1 Comment les images sont faites

- **Le motif :** chaque carte est une liste ordonnée de formes géométriques, et chaque forme porte un rôle : effet, partie claire, partie sombre, accent, point lumineux. Un motif tient en 34 à 51 lignes, sprite compris.
- **Les styles :** les cinq styles de l'échelle lisent ces rôles et les rendent à leur manière. Ils sont devenus génériques : après deux réglages communs à tous (la lueur et l'éclat du palier 5), chaque motif passe aux cinq paliers sans retouche propre.
- **Le pixel 16×16, une exception :** à cette taille, une forme réduite par le calcul devient une tache. Chaque sprite est donc posé pixel par pixel, à la main, dans le code. C'est le palier le moins automatisable.
- **Le rendu :** les 30 images de la série se rendent en 6 secondes.
- **Les cartes :** elles sont rendues avec la mise en page réelle du combat, les icônes d'effet du jeu et les valeurs de chaque palier, selon les règles G1 et G2 de [`_rules/02-4`](../../.obsidian_vault/_rules/02-4-progression-de-rarete-dynamique-et-fusion-int.md).

### 14.2 Ce que la série apprend

- **Les sujets se reconnaissent :** à mon œil, les six sujets se reconnaissent aux cinq paliers, y compris *Concentration* et *Forme démoniaque*.
- **Une règle de dessin :** dessiner ce que la carte **fait**, pas son nom. *Concentration* n'a pas d'objet évident ; la carte devient lisible quand on dessine son effet, piocher.
- **Le tri tient sur des sujets différents :** sur cinq cartes différentes, chacune à un palier, l'ordre reste lisible *(diapo 17)*. On lit la technique, pas le sujet. Ce n'est que mon jugement ; le test se refait avec des joueurs.
- **L'échelle sert le plus là où les chiffres ne bougent pas :** *Concentration* pioche 2 cartes à tous les paliers (règle G2). Sans l'échelle, rien ne distingue une *Concentration* légendaire d'une commune.
- **Les familles de couleurs :** chaque palier garde la sienne (bleu nuit, ciel vert, rayons orange, nuit pourpre). À mon œil, c'est elle qui tient la main ensemble, et le patchwork se voit moins avec six sujets qu'avec la même épée *(diapo 18)*. Le papier reste la chose la plus lumineuse de la main (§11).
- **Le type de carte :** il se lit au fond, sauf au palier 4, où la compétence tire vers le violet (§7.3).

### 14.3 Les limites

- **Le palier 5 est le plus faible :** c'est un filtre posé sur des formes. Les objets clairs (cuirasse, cartes) y pâlissent.
- **Ce ne sont pas des cibles de qualité :** ces images ne remplacent pas un dessinateur. Elles peuvent servir de remplaçants provisoires derrière la règle de repli de §9, et de gabarits pour le dessin à la main (cadrage, palette et taille par palier).
- **Le générateur est temporaire :** il n'est pas dans le dépôt (Q8).
