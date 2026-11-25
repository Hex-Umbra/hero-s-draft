# Cadrage — le bestiaire (P-05) : les décisions du chantier

> **Statut** : cadrage ouvert les 20 et 21/11/2026 avec le propriétaire, et complété depuis. B1 à B30 en deux séances, les 20 et 21 novembre ; B31 à B41 le 21/11, sur la spec de la première vague ; B42 à B61 le 22/11, pour le programme jusqu'à `0.7.0` et le tier 1 ; B62 à B74 le 23/11, après l'audit du chantier ; B75 à B79 le même jour, sur les maquettes des dernières questions du visuel ; B80 et B81 le 24/11, sur les maquettes du décor et des cadres ; B82 le 25/11, sur l'analyse visuelle des cadres produits ; B83 à B89 le même jour, sur les questions nées de la spec de la vague du visuel (§1.9) ; B90 le même jour, après le test du propriétaire. Toutes sont tranchées ; ce qui reste ouvert est en §2. **Ce document est la source de vérité des décisions du bestiaire** : il remplace, là où ils divergent, les brainstormings du [27/07](27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md) et du [28/07](28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md), écrits pour un jeu qui n'avait ni charges à seuil ni grammaire d'effets en donnée. La ligne P-05 de [`ROADMAP.md`](../ROADMAP.md) (« cinq ennemis, `onHitEffect`, 2 à 3 jours, prêt à passer en spec ») est périmée par ce cadrage.
>
> **Les maquettes** sur lesquelles le propriétaire a tranché sont dans un deck privé, <https://claude.ai/artifact/9LxzmnszyErbptiiJh8LDZ> (59 diapositives). Font foi : 31 (panneau des intentions), 37 à 40 (barre, carte, fiche, plateau), 41 (armure), 54 (rat libre et meute), 58 (la famille du Rat). Ce sont des approximations — polices de remplacement, troncatures estimées : ce document et les specs portent en texte ce qu'elles fixent.
>
> **Livraison** : par vagues, un tier par vague (B45). La première, `0.6.1`, a livré l'interface des ennemis. **Depuis le 22/11, le déroulé vit dans [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)** — les vagues, le journal, les fiches, le catalogue des mécanismes et celui des ennemis ; ce document garde les décisions. **Les décisions nomment les tiers ; seul le README du chantier leur donne un numéro de vague et une version.**
>
> **L'audit du 23/11** sur lequel B62 à B79 ont été tranchées : <https://claude.ai/artifact/GqvVVedFnU9ZBSYQL1ME2P> (49 diapositives, privé). Ses diapositives 24 à 31 portent, en maquettes, les trois questions de la vague du visuel que B72 à B74 tranchent ; ses diapositives 34 à 48, celles que B75 à B79 tranchent.

---

## 1. Les décisions acquises

Numérotées dans l'ordre où les questions ont été posées : B1 à B30 au cadrage, B31 à B41 le même jour, nées de la spec de la première vague, B42 à B61 le 22/11, à la préparation de la suite, B62 à B74 le 23/11, après l'audit. **Une décision corrigée par une suivante est écrite sous sa forme en vigueur**, sauf B14, que B32 amende par une exception. L'ordre des vagues a été réécrit cinq fois : ses décisions (B42, B45, B59, B61) sont écrites telles qu'elles valent aujourd'hui, et leur histoire est en §1.8.

### 1.1. Le langage et le contenu

| N° | Décision | Date |
|:---|:---|:---|
| **B1** | Une intention ennemie s'écrit avec la liste `effects` des cartes, et non avec un champ `onHitEffect` : un seul langage, des deux côtés. Les intentions d'aujourd'hui (attaque, Armure, Puissance) deviennent des écritures de cette liste ; les quatre ennemis existants migrent. | 20/11 |
| **B2** | Le bestiaire s'organise en familles, une signature par famille — Rat : la meute ; Slime : les charges ; Araignée : le Poison ; Gobelin : le larcin ; Squelette : la Faiblesse ; Orc : la Puissance. L'évolution d'une forme à l'autre attend. | 20/11 |
| **B4** | Le Kobold esquive au hasard, 20 % par attaque : un jet avant le calcul des dégâts, dans le calcul que le héros et les ennemis partagent, comme le coup critique. Restent à fixer à sa spec : un jet par coup et non par carte ; un coup esquivé ne pose ni charge ni statut ; le Poison et le Feu déjà posés ne s'esquivent pas. | 20/11 |
| **B5** | Le premier lot d'ennemis neufs est le tier 1 : le Rat, les trois slimes élémentaires (de givre, de braise, d'orage), l'Araignée venimeuse, le Corbeau charognard et le Kobold éclaireur — leurs valeurs en B53. Le Bandit de grand chemin n'y entre pas (B49), et aucun n'entre sans son sprite (B51). | 20/11, complétée le 22/11 |

P-05 prépare, sans les construire, P-09 (une liste d'intentions par phase de boss), P-14 (un affixe d'élite est une liste d'effets ajoutée aux intentions) et P-44 lot 2 (épines, étourdissement, malédictions, symétriques) : le format des intentions se choisit en connaissant ces trois suites.

### 1.2. L'affichage

| N° | Décision | Date |
|:---|:---|:---|
| **B6** | Dans le panneau des intentions, une pastille par effet de l'intention, à la couleur de son statut. Au-delà de deux pastilles, la dernière devient « +1 ». | 21/11 |
| **B9** | Le panneau a trois colonnes fixes : le niveau, écrit (« Niv. 1 »), le nom, les pastilles. Les PV n'y figurent plus. Seul le nom se tronque. | 21/11 |
| **B10** | Une seule infobulle par intention, quelle que soit la pastille visée : elle dit toute l'attaque en une phrase. Au survol à la souris, à l'appui long au doigt. Un ennemi gelé qui perd son action garde ses pastilles, grisées et barrées. | 21/11 |
| **B11** | La Puissance quitte le dessus de la carte de l'ennemi : l'intention la compte déjà, et la fiche (B13) l'affiche. | 21/11 |
| **B12** | Au-dessus de la carte ne reste que la barre de PV, à la largeur de la carte : les PV en blanc, l'armure en bleu à côté. L'armure se montre aussi par un voile bleu posé sur la barre. *Amendée par B77* : sur les cadres de tier, la barre a la largeur et la place du gabarit, non celles de la carte. | 21/11 |
| **B13** | La fiche de l'ennemi : toucher un ennemi quand aucune carte ni signature n'attend de cible agrandit sa carte, estompe le reste du plateau et affiche à côté son nom, son niveau, ses PV, son armure, sa Puissance, son intention en une phrase, ses bonus et ses altérations. Un toucher ailleurs la referme. Avec une carte sélectionnée, toucher l'ennemi joue la carte, comme aujourd'hui. La fiche remplace l'appui long sur la jauge. | 21/11 |
| **B14** | Les languettes : à gauche de la carte les bonus (vert), à droite les altérations et les charges (rouge). Au repos, l'icône et sa valeur dessous. Au survol de la carte, elles se déroulent : le nom, la valeur, et la durée quand il y en a une ; une charge sous son seuil garde son compte (« 2/3 »). Le même mécanisme sert la carte du héros. Au doigt, pas de survol : la fiche donne le détail. *Amendée par B77* : sur les cadres de tier, les languettes se posent contre le gabarit, non contre le bord de la carte. | 21/11 |
| **B15** | Le voile d'armure ne se mesure pas aux PV : c'est la jauge de l'armure seule. Plein quand l'armure est à son plus haut, il recule à chaque coup qui l'entame et disparaît à zéro. 6 d'armure couvrent la barre d'un Kobold comme 40 celle d'un boss. | 21/11 |
| **B16** | Si l'ennemi regagne de l'armure, le voile se remplit à nouveau et le nouveau montant devient son plein. | 21/11 |
| **B31** | La pastille d'un ennemi qui gagne de la Puissance garde la flèche montante violette : l'éclair orange de la Puissance se confond, dans le panneau, avec l'éclair d'une petite attaque. Exception à « la couleur de son statut » de B6. | 21/11 |
| **B32** | *Amende B14.* La Foudre chargée s'affiche en jaune dans la languette de droite, comme depuis la vague des charges élémentaires ; tout le reste de cette languette reste rouge. | 21/11 |
| **B33** | Une charge qui a pris et n'a plus de chiffre à montrer — l'ennemi gelé — écrit au repos le nom de son état (« Gelé ») sous son icône. | 21/11 |
| **B34** | Dans la fiche : une section vide ne s'affiche pas ; un effet qui dure tout le combat n'affiche pas de durée ; seules la Faiblesse et le Vulnérable ont une ligne de description. | 21/11 |
| **B35** | La fiche ne s'ouvre qu'au tour du joueur, et se ferme quand il finit. | 21/11 |
| **B36** | La fiche estompe le plateau seul — le décor, le héros, la main, les autres ennemis. Les panneaux et les boutons restent nets. | 21/11 |
| **B37** | Le tutoriel dit la fiche en une phrase, à l'étape des intentions ennemies. | 21/11 |
| **B38** | Le panneau des effets du héros reste, à côté de ses languettes : au doigt, c'est le seul détail du héros. | 21/11 |
| **B39** | Une languette qui sortirait de l'écran se déroule vers l'intérieur, par-dessus sa propre carte. | 21/11 |
| **B40** | La carte dont la fiche s'ouvre garde sa barre à la hauteur des autres et grandit vers le bas : autour de son centre, la barre d'un boss sortirait de l'écran. | 21/11 |
| **B41** | Sur la languette du héros : 💎 pour la régénération de Mana, 💖 pour celle des PV. | 21/11 |
| **B8** | *Tranchée par B55.* Où se lit l'esquive du Kobold. | 22/11 |

### 1.3. La famille du Rat

| N° | Décision | Date |
|:---|:---|:---|
| **B3, B28** | Un ennemi peut prendre moins d'une place à la composition d'un combat : la place est une donnée de l'ennemi. Le Rat en prend une demie — deux rats pour une place, dès l'acte 1 — et lui seul s'en sert au départ. | 20 et 21/11 |
| **B7, B17, B18** | Chaque rat a sa carte et se cible seul. Le Rat se lit plus petit qu'un autre ennemi, libre ou en meute : son sprite est dessiné réduit à 80 % dans son image, et sa carte garde un cadre de tier 1 entier, sans mise à l'échelle (B72) ; les rats invoqués se placent de part et d'autre de leur alpha, plus serrés que deux ennemis ordinaires. | 21/11 |
| **B20, B26, B27** | Deux ennemis : le Rat, tier 1 (dès l'acte 1), et le Rat alpha, tier 2 (dès l'acte 6). Le Rat existe seul : un ennemi invoqué reste un ennemi du bestiaire, qui peut aussi être tiré à la composition. La règle vaut pour toute famille — un nécromancien invoquera le Squelette existant. | 21/11 |
| **Consigne** | Le Rat alpha entre seul et invoque ses rats un par un, deux au plus. | 21/11 |
| **B23** | Invoquer prend l'action de l'alpha pour le tour. Un rat tué se réinvoque, au même prix. | 21/11 |
| **B22, B29** | Le lien de meute porte sur la Puissance seule : l'alpha gagne un pourcentage par rat invoqué vivant, un rat invoqué en gagne un tant que son alpha vit. Un rat libre n'entre pas dans le lien. Les valeurs montrées (+20 % par rat, +25 % pour le rat) sont des exemples. | 21/11 |
| **B24** | À la mort de l'alpha, ses rats restent, sans leur bonus. | 21/11 |
| **B25** | Un rat invoqué ne rapporte rien, ni or ni autre récompense. Un rat libre et un alpha rapportent comme tout ennemi. | 21/11 |
| **B21, B30** | À l'écran, une meute compte pour 2 cartes sur les cinq, quel que soit le nombre de ses rats, et un seul chef de meute est à l'écran : un second alpha attend en réserve. Le plateau porte six cartes au plus. | 21/11 |
| **B19** | Au-delà du plafond, la réserve existante s'applique sans changement ([règle 02-6](../../.obsidian_vault/_rules/)). | 21/11 |
| **B43** | Le sprite déjà produit, `art_src/sprites/rat/tier_1/rat_geant.aseprite`, est celui du **Rat alpha**. Le sprite du Rat reste à produire, par `/workflow-creature`, avec ceux du tier 1. | 22/11 |

### 1.4. L'ordre des vagues

| N° | Décision | Date |
|:---|:---|:---|
| **B42** | **Le langage des intentions (B1) se livre seul**, dans sa propre vague, avant tout ennemi neuf : les ennemis suivants s'écrivent directement dans le nouveau format, rien ne migre deux fois, et cette vague n'ajoute aucun ennemi. B62 dit sa place. | 22/11, rétablie le 23/11 |
| **B44** | Les slimes élémentaires (B5) sont **trois créatures neuves**, produites de zéro par `/workflow-creature`, et non des variantes du Slime. Ils n'entrent dans aucune vague avant leurs sprites. | 22/11 |

### 1.5. Le programme jusqu'à `0.7.0`

| N° | Décision | Date |
|:---|:---|:---|
| **B45** | Le bestiaire se livre **un tier par vague** : chaque vague de tier livre ses mécanismes et ses ennemis ; le visuel — le cadre de tier, les fonds de fenêtre, le décor — a sa propre vague, le langage des intentions la sienne (B42), les boss la leur. Le déroulé, les numéros de vague et les versions : [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md). | 22/11 |
| **B46** | Une vague ne construit que les mécanismes dont ses ennemis se servent, et les branche dans la même vague ; un mécanisme se teste en jeu avec le premier ennemi qui s'en sert. Tous les mécanismes sont tenus dans un [catalogue](../chantier_bestiaire/catalogue_mecanismes.md), qui dit pour chacun sa vague. | 22/11 |
| **B47** | Les boss forment **un tier à part**, hors de l'échelle 1 à 5 des ennemis de base. | 22/11 |
| **B48** | Les quatre ennemis d'aujourd'hui n'ont pas de vague propre : chacun évolue avec sa famille, dans la vague de son tier — le Gobelin au tier 1, le Squelette au tier 2, l'Orc au tier 3. | 22/11 |
| **B49** | Le larcin du tier 1 est porté par **le Gobelin**, signature de sa famille (B2). Le Bandit de grand chemin n'entre pas au tier 1. | 22/11 |
| **B50** | Le Rat alpha étant de tier 2 (B20), **la meute — l'alpha, l'invocation, le lien — vient avec le tier 2**. Le Rat arrive seul, avec le tier 1 et sa demi-place. | 22/11 |
| **B51** | Une vague d'ennemis ne s'ouvre **qu'une fois tous ses sprites validés** ; la liste de ses ennemis est fixée dans sa fiche. | 22/11 |
| **B52** | **Tout le bestiaire est redessiné** dans le style des sprites neufs : chacun des quatre ennemis d'aujourd'hui reçoit un sprite neuf dans la vague de son tier — le Slime et le Gobelin avec le tier 1, le Squelette avec le tier 2, l'Orc avec le tier 3. | 22/11 |
| **B59** | **Les tiers 4 et 5 font partie du programme du bestiaire**, toujours un tier par vague, après le tier 3. Leur place par rapport aux boss : B63. | 22/11 |
| **B60** | **La cadence de déblocage des tiers ne change pas** : un tier de plus tous les cinq actes (`EncounterSystem.getUnlockedTier`) — le tier 4 à l'acte 16, le tier 5 à l'acte 21. Elle se réexamine avec la difficulté (B64). | 22/11 |
| **B61** | **Le visuel passe en tête**, juste après l'interface : le cadre de tier, les fonds de fenêtre et le décor de combat arrivent avant le langage des intentions et avant le tier 1. Chaque sprite neuf se valide sur son vrai fond, et la demi-place puis la meute se posent une seule fois sur le placement définitif. Le code du visuel reçoit les cinq tiers, mais seuls les cadres des tiers 1 à 3 sont dessinés pour lui ; les cadres 4 et 5 viennent avec leurs tiers. Les anciens sprites passent dans les cadres jusqu'à leur refonte (B52). Le tier boss reste le jalon `0.7.0`. | 22/11 |

### 1.6. Le tier 1

Tranchées le 22/11 sur les recommandations du [deck du tier 1](https://claude.ai/artifact/88qAGkoUHeX1Yi1YqzFSZK), qui en donne les chiffres et les options écartées. Ce sont des valeurs de départ : l'équilibrage les ajustera.

| N° | Décision | Date |
|:---|:---|:---|
| **B53** | *Fixe les valeurs que B5 proposait.* Les ennemis du tier 1 : **Rat** 8 PV, 3 dégâts, un coup ; **Slime de givre** 18 PV, 3 dégâts, 2 Gel par coup ; **Slime de braise** 18 PV, 3 dégâts, 1 Feu par coup ; **Slime d'orage** 18 PV, 4 dégâts, 1 Foudre par coup ; **Araignée venimeuse** 16 PV, 2 dégâts, Poison 1 par morsure ; **Corbeau charognard** 16 PV, 4 dégâts, vol de vie de 50 % des dégâts portés aux PV ; **Kobold éclaireur** 14 PV, 4 dégâts, esquive de 20 % par coup (B4). | 22/11 |
| **B54** | Le Rat ne frappe qu'une fois : **« plusieurs coups » part avec le tier 2**, avec le Loup des ombres. Une paire de rats vaut à peu près un ennemi, et son prix compte sa demi-place. | 22/11 |
| **B55** | *Tranche B8.* L'esquive se lit dans **une languette de bonus**, à gauche de la carte, le pourcentage à la place de la durée ; un texte flottant « Esquive ! » à chaque coup esquivé. | 22/11 |
| **B56** | Le « +1 » de B6 est **reporté** à la première intention à trois effets ; au tier 1, une intention en a deux au plus. | 22/11 |
| **B57** | Le larcin du Gobelin : **5 or par coup**, plafonné à l'or du héros ; **l'or volé est perdu** ; il se voit par un texte flottant « −5 or » au-dessus du héros et **une languette de butin** à gauche du Gobelin, qui dit ce qu'il a pris. La fuite du voleur reste au catalogue. | 22/11 |
| **B58** | Le prix d'un effet : **+6** au prix d'un ennemi qui en porte un (proposition du 28/07). Le Gobelin voleur, à 39, ne sort plus à l'acte 1 pour le Mage et le Berserker : accepté. Ce prix se réexamine avec la difficulté (B64). | 22/11 |

### 1.7. La révision du 23/11

Tranchées le 23/11 avec le propriétaire, sur l'audit du chantier (lien en tête du document) ; B75 à B79 le même jour, sur les maquettes ajoutées à ce deck.

| N° | Décision | Date |
|:---|:---|:---|
| **B62** | *Rétablit B42.* **Le langage des intentions (B1) a sa propre vague**, entre le visuel et le tier 1 : le jeu y reste identique, elle n'ajoute aucun ennemi et ne demande aucun sprite. Le tier 1, le tier 2 et le tier 3 suivent, un par vague. | 23/11 |
| **B63** | *Amende B59.* **Les tiers 4 et 5 se font après la refonte de la difficulté** (B64), et avant les boss : leurs valeurs se fixent sur la formule revue. B69 dit l'ordre. | 23/11 |
| **B64** | **La difficulté sera retravaillée dans son ensemble** — sa formule et sa mise à l'échelle —, par un cadrage propre, un brainstorm tenu après le tier 3 (B69). Le prix d'un effet (B58) et la cadence des tiers (B60) s'y réexaminent ; ils valent jusque-là. Un fait donné par le propriétaire : ses runs atteignent l'acte 20 et au-delà, mais très difficilement. | 23/11 |
| **B65** | *Complète B51.* Tous les ennemis du programme sont tenus dans un [catalogue des ennemis](../chantier_bestiaire/catalogue_ennemis.md), tier par tier : dictionnaire initial du bestiaire, il dit pour chacun sa famille, ses valeurs, ses intentions, ses mécanismes, et **si son sprite est livré**. La porte de B51 se lit dans ce tableau. | 23/11 |
| **B66** | **La couture de lieu** : dans la vague du visuel, le décor de combat et le thème du fond de fenêtre passent par un identifiant de lieu, à valeur unique tant que les biomes (P-12) n'existent pas ; les assets se rangent par lieu. Les biomes eux-mêmes ont leur cadrage, hors vague, et n'entrent pas dans cette vague. | 23/11 |
| **B67** | **Le fond de fenêtre est un asset séparé du cadre**, trois variations par lieu, choisi par le jeu. Amende l'[identité visuelle](18-09-2026_identite_visuelle_pixel_art_Opus5.md) §4.3, qui le dessinait dans le cadre ; la fiche du visuel le posait depuis le 22/11 sans numéro. | 23/11 |
| **B68** | *Applique B46.* Trois mécanismes n'avaient aucun ennemi dans la vague qui devait les construire ; chacun se construit désormais avec son premier ennemi : **viser un allié** avec le Chaman orc (tier 4) ; **le soin de soi** avec la Liche (tier 5) ; **le choix d'intention** avec un ennemi du tier 2 (B70). | 23/11 |
| **B69** | *Tranche la suite du programme.* Après le tier 3 : **la refonte de la difficulté**, puis **le tier 4**, puis **le tier 5**, puis **les boss**, qui restent le jalon `0.7.0`. La difficulté se retravaille donc après les tests des tiers 1 à 3 et de leurs intentions, et avant les tiers 4 et 5. **Les lieux** (biomes, P-12) se placent après `0.7.0`. | 23/11 |
| **B70** | *Complète B68.* **Le choix d'intention entre dès le tier 2**, pour y préparer le joueur : un ennemi de ce tier le porte, à désigner à la confirmation de sa liste. Un ennemi du tier 3 peut le reprendre. | 23/11 |
| **B71** | **La riposte**, un mécanisme neuf, qui fonctionne comme l'esquive (B4) : quand le héros attaque un ennemi qui la porte, cet ennemi a une chance de contre-attaquer, ou de lui poser un statut ou une charge. Premier usage : **le héros a 50 % de chance de prendre 1 Gel en attaquant un Slime de givre** ; de même 1 Feu pour le Slime de braise, 1 Foudre pour le Slime d'orage. C'est la première réponse à la faiblesse des doses posées par coup — au tier 1, une charge par coup ne gèle presque jamais le héros ; l'échelle des doses selon l'acte reste au cadrage de la difficulté (B64). | 23/11 |
| **B72** | **La règle d'échelle.** Un cadre s'affiche à un palier **pair**, le plus grand qui laisse tenir la rangée : ×2 en 1080p, ×4 en 1440p, ×6 en 4K. La créature et son fond de fenêtre sont à la moitié, donc sur des pixels entiers. **Le plateau ne rétrécit plus en continu** : à ×2, six cartes tiennent en 1080p, et la réserve joue au-delà du plafond. *Amende B17* : le Rat n'est pas mis à l'échelle 0,8 — son sprite est déjà réduit dans son image —, il garde un cadre de tier 1 entier, et sa demi-place se lit par un écart plus serré. **La fiche ouverte double la carte**, au palier pair suivant, au lieu de l'agrandir de 1,25 ; sa barre garde sa hauteur (B40). Le décor a sa propre grille (B74). | 23/11 |
| **B73** | **Les géométries des cadres** : une fenêtre de 64 × 96 pour tous, et 4 pixels de bordure de plus à chaque tier — tier 1 : 88 × 120 (bordure 12) ; tier 2 : 96 × 128 (16) ; tier 3 : 104 × 136 (20) ; tier 4 : 112 × 144 (24) ; tier 5 : 120 × 152 (28). Amende l'[identité visuelle](18-09-2026_identite_visuelle_pixel_art_Opus5.md) §4.1, où les tiers 2 et 3 avaient la même taille. **Les cadres d'aujourd'hui sont provisoires** : ils seront redessinés, moins pleins, avec des parties transparentes — comme des racines autour de la carte ; ces tailles sont celles de leur canevas. **Le cadre des boss** n'a pas de géométrie avant leur cadrage : d'ici là, un boss porte le cadre de son tier. | 23/11 |
| **B74** | **Le lieu unique du visuel est la forêt** (B66) : les trois fonds de fenêtre de forêt restent, et **un décor de combat neuf se produit avant la vague**. **Un décor d'écran se dessine désormais en 640 × 360**, le double de 320 × 180 : 3 pixels d'écran par pixel en 1080p, 4 en 1440p, 6 en 4K. | 23/11 |
| **B75** | **Les anciens sprites se recadrent.** Dans la fenêtre du cadre, un ancien sprite — une carte peinte entière — est recadré sur son illustration. Les quatre peintures ont la même composition : un seul rectangle les recadre toutes, au rapport 2:3 de la fenêtre. La créature garde son fond peint et son rendu lissé jusqu'à sa refonte (B52) ; le recadrage disparaît avec le dernier ancien sprite. | 23/11 |
| **B76** | *Étend B66.* **La couture de lieu désigne un décor par lieu et par écran** ; un écran sans image garde son fond d'aujourd'hui. Dans la vague du visuel, seul le combat reçoit un décor. Le repos et les autres écrans reçoivent le leur quand il existe, sans code neuf. Le décor du campement, en 320 × 180, n'est pas repris tel quel : il se refera en 640 × 360 (B74), recomposé autour du vrai menu du repos, dont les options recevront un fond plein — hors de la vague du visuel. | 23/11 |
| **B77** | *Amende B12 et B14.* **L'ancrage à la fenêtre.** La barre de PV et les languettes ne s'ancrent pas au bord du cadre, mais à **un gabarit de 88 × 120** — le canevas du tier 1 —, centré sur la fenêtre, le même sur les cinq cadres. La barre se pose au-dessus du gabarit, à sa largeur ; les languettes, contre ses côtés. **La rangée s'aligne sur les fenêtres** : les créatures ont le même sol, les barres la même hauteur. Au-delà du tier 1, la barre et les languettes passent sur le bord extérieur du cadre. **Contrainte pour le dessin des cadres** (B73) : la marque du tier tient dans les 12 pixels au-dessus de la fenêtre ; au-delà du gabarit, le dessin peut passer sous la barre et les languettes. | 23/11 |
| **B78** | **Le contour de ciblage entoure la fenêtre**, à la même taille sur les cinq cadres : cyan pour une cible possible, ambre pour une carte choisie ou dont la fiche est ouverte. Le liseré blanc du repos disparaît : le cadre le remplace. | 23/11 |
| **B79** | *Complète B72.* **La fiche ouverte double tout** : la carte, sa barre et ses languettes. Le panneau de la fiche, élément d'interface, garde sa taille. | 23/11 |
| **B80** | *Confirme B74, et amende l'[identité visuelle](18-09-2026_identite_visuelle_pixel_art_Opus5.md) §6 pour les décors.* **Un décor d'écran garde ses couleurs peintes** : seule sa grille de 640 × 360 est lue, il n'est pas ramené sur la palette Apollo. La palette lui retirait sa mousse, le modelé de ses rochers et la profondeur de son fond ; en couleurs peintes, il garde son caractère de décor et se détache des dessins des cartes. Les créatures, les cadres et les fonds de fenêtre restent en Apollo exact. **La taille de 640 × 360 est confirmée** sous un combat, face à 320 × 180. Tranché le 24/11 sur les maquettes de l'essai 5 du [workflow des décors](../../art_src/docs/workflow_decor.md), hors de l'audit. | 24/11 |
| **B81** | *Précise B73, et avance les cadres des tiers 4 et 5.* **Les cadres de tier sont une gravure épineuse, et les cinq se dessinent maintenant**, sans attendre la vague de leur tier. Une ronce d'encre ajourée, en palette Apollo, au trait de 2 pixels ombré et cerné : seul le dessin est opaque, le décor se voit entre les vrilles. **Elle part de deux coins opposés et envahit le cadre** : au tier 1, la ronce aux coins bas-gauche et haut-droit ; au tier 2, ces coins s'allongent et des pousses naissent aux deux autres ; au tier 3, la diagonale court jusqu'au milieu des bords, avec des baies ; au tier 4, la ronce fait tout le tour et se tresse, des fleurons au milieu des flancs ; au tier 5, des crochets aux coins, une couronne d'épines et un fleuron en bas. **La marque du tier** est un écusson au haut-centre et 1 à 5 gemmes : vertes, violettes, rouges, orange, blanches. Le tier 2 n'est pas or, qui se perdait dans un cadre doré et voisinait l'ambre du ciblage (B78) ; ces couleurs sont une proposition de l'agent, acceptée avec l'échelle. Tranché le 24/11 sur trois séries de maquettes en combat, d'après des inspirations du propriétaire — deck privé <https://claude.ai/artifact/Ra9ZjKALRHgqxgZELcocR8>, la version retenue aux diapositives 33 à 37 ; produits par `art_src/tools/frame_tier.py` dans `art_src/cadres/`. | 24/11 |
| **B82** | *Corrige B81 après une analyse visuelle des tiers 1 à 3.* **Les cadres gardent leur dessin et reçoivent quatre corrections et deux choix.** Les corrections : les baies sont au centre de leur boucle (elles étaient décalées d'un pixel, hors de la symétrie, aux tiers 3 à 5) ; au tier 3, la diagonale s'enroule juste avant le milieu des bords au lieu d'y être coupée net ; la rampe d'encre détache l'ombre du cerne (ombre `241527`, moyen `341c27`) ; le violet du tier 2, la marque la plus terne, monte d'un cran (`402751` à `df84a5`). Les choix du propriétaire, recommandés par l'agent : **au tier 2, sur les bords haut et bas, ronce et pousse s'arrêtent à égale distance du centre**, pour que l'écusson ne soit plus penché d'un côté ; **l'éclat de l'encre est cuivré** (`ad7757` au lieu de `7a4841`) : 5 % des pixels, qui dessinent le cadre sur un tronc où l'encre seule se perdait. Tranché le 25/11 sur les diapositives 38 à 45 du deck des cadres ; les cinq cadres sont régénérés. **Aux tiers 4 et 5**, analysés le même jour (diapositives 46 à 50), une seule correction : les crochets de coin du tier 5 se recourbent plus bas et ne sont plus coupés par le bord du canevas. La barre de PV qui couvre la pointe des épines du tier 5, et les languettes qui couvrent le bout des fleurons de flanc, restent telles quelles : c'est l'ancrage de B77. | 25/11 |

### 1.9. Les réponses du 25/11, sur la spec de la vague du visuel

Tranchées le 25/11 par le propriétaire, sur les maquettes à la taille réelle de l'écran de la page <https://claude.ai/artifact/5fcccZZGtE1xJVW9eLtAAq> (privée), nées en écrivant puis en vérifiant la [spec de la vague 2](../superpowers/specs/2026-11-25-p05-cadres-et-decors-design.md), §1.3 : trois questions de classe D (D1 à D3), trois de classe P (P2 à P4). Toutes suivent la recommandation de la spec.

| N° | Décision | Date |
|:---|:---|:---|
| **B83** | *Amende B72, tranche D1.* **Le palier suit la règle, non les exemples.** « Le plus grand palier pair qui laisse tenir la rangée » donne ×2 en 1080p, **×2 en 1440p** et **×4 en 4K** : les exemples de B72 (×4 en 1440p, ×6 en 4K) ne tiennent ni la rangée de six cartes en largeur, ni la barre en haut de l'écran, ni le héros sous les cadres. En 1440p, les ennemis gardent leur taille du 1080p, et le héros et la main, qui grandissent en continu, paraissent plus grands face à eux : accepté. | 25/11 |
| **B84** | *Précise B72 par B79, tranche D2.* **La fiche ouverte double la carte à tout palier** — ×4 à ×2, ×8 à ×4 —, et non « au palier pair suivant » : la fiche de la 4K est celle du 1080p doublée. | 25/11 |
| **B85** | *Exception à B72, tranche D3.* **Sous le plus petit écran qui tient le palier ×2**, le plateau garde la mise en page du palier ×2, **réduit en continu jusqu'à tenir et lissé** : la netteté n'y est pas recherchée (DA évolutive §16.2, 10/11). Le décor suit sa propre règle (B88). | 25/11 |
| **B86** | *Complète B85.* **La fenêtre Windows du jeu s'ouvre maximisée**, pour qu'un écran 1080p voie le plateau au palier ×2, net, dès l'ouverture. Elle entre dans la vague du visuel. | 25/11 |
| **B87** | *Tranche P3.* **Le fond de fenêtre se tire au hasard, pour chaque ennemi, à son entrée sur le plateau**, parmi les trois du lieu. À revoir au test de la vague 4, quand le fond se verra derrière les sprites neufs. | 25/11 |
| **B88** | *Complète B74, tranche P2.* **Hors 16:9, le décor couvre l'écran au plus petit facteur qui le couvre**, centré, rogné, jamais lissé : un facteur entier en 16:9 et sur une fenêtre maximisée, fractionnaire en 16:10. | 25/11 |
| **B90** | *Amende B72 et B83, précise B85 ; tranchée après le test du propriétaire, sur un écran de 2880 × 1800 à 200 % où un ennemi de tier 1 faisait 0,57 fois la hauteur du héros (0,85 en 1080p).* **La taille des ennemis suit celle du héros, nette quand elle est presque entière.** Le cadre vaut 2 pixels d'écran par pixel de cadre pour 1080 pixels physiques de hauteur de jeu, en continu — la proportion du 1080p face au héros, sur tous les écrans —, plafonné par la rangée de six cartes, la barre en haut et le héros en bas (B72). Quand cette valeur est à 10 % au plus d'un entier égal ou supérieur à 2, et que cet entier tient, elle s'y arrondit et tout reste net : ×2 en 1080p et sur une fenêtre maximisée de 1080p, ×3 sur un écran de 2880 × 1800, ×4 en 4K. Sinon elle reste continue, et le cadre, le fond et la créature se lissent (B85) : 1440p à ×2,67. Le décor garde sa règle (B88), le héros la sienne. Maquettes : section D4 de la page des questions. | 25/11 |
| **B89** | *Tranche P4.* **Une carte ouverte qui sortirait de l'écran se décale vers l'intérieur**, juste assez pour tenir, sa barre gardant sa hauteur (B40). Le cas naît avec la sixième carte (vague 4) ; la vague du visuel le construit dans sa fiche. | 25/11 |

### 1.8. L'histoire de l'ordre des vagues

Pour mémoire : seule la dernière ligne vaut, et le [README du chantier](../chantier_bestiaire/README.md) en tient les numéros.

| Date | Décision | L'ordre qu'elle posait |
|:---|:---|:---|
| 22/11 | B42 | Le langage des intentions seul en vague 2 ; la famille du Rat et la meute en vague 3. |
| 22/11 | B45 | Un tier par vague : le langage et le tier 1 en vague 2 (`0.6.2`), le tier 2 en 3, le tier 3 en 4, le visuel en 5, les boss en 6 (`0.7.0`) ; les tiers 4 et 5 après `0.7.0`. |
| 22/11 | B59 | Les tiers 4 et 5 entrent, en vagues 5 et 6 ; le visuel en vague 7 (`0.6.7`) ; les boss en vague 8. |
| 22/11 | B61 | Le visuel en tête, en vague 2 ; les tiers 1 à 5 en vagues 3 à 7 ; les boss en vague 8 (`0.7.0`). |
| 23/11 | B62, B63 | Le visuel en vague 2, le langage seul en vague 3, les tiers 1 à 3 en vagues 4 à 6 (`0.6.4` à `0.6.6`) ; la difficulté, les tiers 4 et 5, les lieux et les boss à placer ensuite. |
| 23/11 | B69 | La difficulté en vague 7 (`0.6.7`), le tier 4 en vague 8, le tier 5 en vague 9, les boss en vague 10 (`0.7.0`) ; les lieux après `0.7.0`. |

---

## 2. Ce qui reste à trancher

Chaque point est repris, sous « Prérequis », par la fiche de la vague qui en a besoin ([`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)) — sauf les lieux et les boss, qui n'ont pas encore de fiche.

- **La difficulté** (B64, B69) : ce qu'elle doit viser ; ce que deviennent la formule du budget et sa mise à l'échelle, le prix d'un effet, la cadence des tiers, l'échelle des doses d'un statut posé par un ennemi, la table d'XP au-delà de l'acte 15. Rien n'est écrit : c'est l'objet d'un brainstorm, tenu après le tier 3. **Un instrument de mesure** — un tableau de ce que le tirage des combats produit, acte par acte — a été proposé à l'audit, à poser dès la vague du langage des intentions : non décidé.
- **La vague du visuel** : toutes ses questions sont tranchées (B72 à B82, puis B83 à B89 sur sa spec, le 25/11). Le décor de forêt est validé depuis le 24/11 (`art_src/decors/forest/combat/`, [workflow des décors](../../art_src/docs/workflow_decor.md)) ; les cinq cadres, produits le même jour (B81) et corrigés le 25/11 (B82, `art_src/cadres/`), sont validés par le propriétaire le 25/11, avec les trois fonds de fenêtre de forêt (`art_src/fonds/forest/`). Rien ne reste ouvert pour cette vague ; hors d'elle, le décor du repos (B76).
- **La riposte** (B71) : un jet par coup ou par carte ; ce qui compte comme une attaque du héros ; si elle s'ajoute à ce que le slime pose en attaquant (B53) ou le remplace ; ce que le joueur en lit ; quel ennemi contre-attaquera en dégâts.
- **Le choix d'intention** (B70) : l'ennemi du tier 2 qui le porte.
- **Les lieux** (biomes, P-12), après `0.7.0` (B69) : leur modèle — un lieu par acte, ou par créature —, leur nombre, leur lien avec les familles et les boss. Un cadrage propre.
- **Les boss** : aucun concept. Un cadrage, avant la fiche de leur vague.

- La lecture du « +1 » de B6, quand une intention aura plus de deux effets : deux pastilles puis un compteur, ou une pastille puis un compteur. **Reportée** à la première intention à trois effets (B56) ; aucune n'existe au tier 1.
- Trois propositions du cadrage, sans numéro : l'invocation s'annonce comme une intention, un tour avant ; un rat invoqué n'agit qu'au tour suivant ; l'invocation et le lien s'écrivent en données, pour toute famille, de façon symétrique (le héros pourrait un jour invoquer).
- La meute compte-t-elle pour 2 dès l'entrée de l'alpha, avant toute invocation ? C'est la lecture du cadrage, pas une décision.
- Le prix de l'alpha dans le budget de combat, qui doit couvrir des rats entrant sans rien coûter.
- Les PV, les dégâts et les pourcentages : à l'équilibrage.

---

## 3. Ce que le cadrage a lu dans le code

Lu le 21/11 sur `8d544a3d`. À revérifier par commande avant de s'y appuyer.

- `EnemyInstance.effectiveIntent` : la valeur d'une attaque inclut déjà la Puissance.
- `lib/ui/widgets/hud/enemy_intents_panel.dart` : l'infobulle du panneau s'ouvre déjà au survol et à l'appui long.
- `lib/game/components/entities/stat_badge.dart`, `lib/game/components/widgets/linear_progress_bar.dart` : le badge au-dessus de la carte montre la Puissance et l'armure ; le voile d'armure a pour largeur `armure / PV max`. Le jeu ne retient pas le plus haut montant d'armure d'un ennemi.
- `lib/game/heros_draft_game.dart`, `_handlePlayerTargeting` : toucher un ennemi sans carte sélectionnée ne fait rien aujourd'hui. Le survol n'existe que pour les cartes de la main.
- `lib/game/components/entities/status_indicator.dart` : les bonus sont déjà à gauche de la carte, les altérations et les charges à droite.
- `lib/game/systems/encounter_system.dart` : le nombre d'ennemis d'un combat est un entier ; un tier s'ouvre tous les cinq actes, plafonné à 3 ; le prix d'un ennemi vaut `tier × 15 + PV / 4 + dégâts × 2 × (1 + critique)`.
- `lib/game/systems/layout_system.dart`, `repositionEnemies` : le plateau rétrécit déjà les cartes trop nombreuses. À 1280 × 800, cinq cartes tiennent à pleine taille ; six, dont deux rats à 80 %, à 97 %.
- Les règles des charges sur le héros sont écrites et testées ; seule l'entrée de debug en pose une aujourd'hui.
- La résolution des effets de carte est écrite pour le héros : la rendre symétrique est le principal coût de B1.

---

## 4. La livraison par vagues

**La méthode** est celle du chantier précédent — [ADR-102](../../.obsidian_vault/_adr/), ADR-103, [ADR-108](../../.obsidian_vault/_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md), ADR-113 et les cinq amendements d'[ADR-120](../../.obsidian_vault/_adr/ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md) D1 —, avec le cycle et les gabarits du [fichier d'orchestration](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6, lus pour ce chantier. Les propositions non adoptées d'ADR-120 (D3, D4) ne s'appliquent pas ; R31 non plus : la vague garde sa spec. Autonomie : `strict`.

**Depuis le 22/11, le déroulé vit dans [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)** (B45) : le journal, les fiches des vagues et des tiers, le catalogue des mécanismes, celui des ennemis, et la méthode lue pour ce chantier. Ce §4 garde, pour mémoire, les arrêts et la fiche de la vague 1.

**Trois écarts, décidés par le propriétaire le 21/11** : la session de cadrage orchestre elle-même la première vague ; la branche part de `fix/s9-phase-ennemie-apres-victoire` (`8d544a3d`) et non de `main`, si bien que la correction S9 sort avec `0.6.1` ; la porte d'entrée ne contrôle donc ni la fusion d'une vague précédente ni la CI.

### 4.1. Le journal

Il a déménagé dans le [README du chantier](../chantier_bestiaire/README.md), §4.

**Arrêts** : le 21/11, à la spec, après le troisième tour de vérification — il reste un constat moyen de classe T, et l'autonomie est `strict` ; onze questions visibles du joueur (31 à 41 du deck, [fichier de vérifications](../superpowers/specs/2026-11-21-p05-interface-des-ennemis-design-verifications.md) §2) attendaient aussi le propriétaire. **Levé le même jour** : le propriétaire répond aux onze questions (B31 à B41), accepte les corrections recommandées du troisième tour et accorde un quatrième tour, différentiel. **Second arrêt le même jour** : le quatrième tour rend « à corriger » pour un constat moyen de classe T, né de la correction précédente ; la correction recommandée est appliquée, non revérifiée ; le propriétaire dit si la vague passe au plan ou refait un tour. **Levé** : il choisit le plan ; la fiche, tâche à risque, y est écrite en entier et rejouée par son vérificateur.

### 4.2. Vague 1 — `0.6.1` — l'interface des ennemis

**Ce qu'elle livre** : B9, B10, B11, B12, B13, B14, B15, B16, B31 à B41, et de B6 la part qui ne dépend pas de B1 — une pastille par intention d'aujourd'hui (attaque, Armure, Puissance) ; les pastilles de statut viendront avec le langage des intentions. Elle emporte la correction S9, déjà sur la branche de départ.

**Fichiers** : `p05-interface-des-ennemis` pour la spec et le plan ; `bestiaire-vague-1` pour le compte rendu et les tests manuels.

**À lire** : les fichiers de §3 qui touchent l'affichage ; `lib/game/components/entities/` (`combat_entity.dart`, `enemy_card.dart`, `hero_card.dart`, `stat_badge.dart`, `status_indicator.dart`) ; `lib/ui/widgets/hud/enemy_intents_panel.dart`, `combat_tooltip_overlay.dart` ; `lib/models/enemy_instance.dart` ; `lib/tutorial/widgets/` (`tutorial_enemy_intents_widget.dart`, `tutorial_armor_widget.dart`, `tutorial_combat_overview_widget.dart`) ; les fiches `_rules` et `_patterns` du combat et du HUD.

**La spec doit fixer** :

1. le panneau : les trois colonnes et leurs largeurs, la troncature du nom, les pastilles des intentions d'aujourd'hui, la règle du « +1 », l'infobulle unique et son texte, l'ennemi gelé ;
2. la barre : sa géométrie, ses deux chiffres, le voile, et l'état « plus haut montant d'armure » — où il vit, quand il monte, quand il s'efface ; ce que devient le badge du dessus de la carte ;
3. la fiche : les conditions exactes du toucher qui l'ouvre, son contenu et sa mise en page, ce qui la ferme, ce qu'elle devient si l'ennemi meurt ou si le tour change pendant qu'elle est ouverte, et le retrait de l'appui long sur la jauge ;
4. les languettes : le repos et le survol, pour les ennemis et pour le héros, la détection du survol d'une carte d'ennemi, le comportement au doigt ;
5. les textes joueur, en français et en anglais ;
6. ce que le tutoriel montre et qui change ;
7. les tests — les calculs, les données et les contrôleurs seulement (ADR-113) ; tout ce qui se voit va au fichier de tests manuels.

**À arbitrer** : les questions visibles du joueur (classe P) ont leur réponse dans B6 à B16 et dans les maquettes ; une mesure que la maquette ne donne pas et qui suit l'échelle des composants existants est de classe T. Une question P neuve s'écrit et se signale, sans se trancher.

**Ne pas absorber** : B1 (le format des intentions ne change pas, aucun fichier d'ennemi ne migre), aucun nouvel ennemi, ni demi-place, ni meute, ni esquive, ni tier ; la jauge du héros, qui garde sa forme — le héros ne reçoit que ses languettes ; aucun équilibrage.

**Tâche à risque** : la fiche — le geste de toucher, la mise au premier plan de la carte et l'estompage du plateau.

**Pour `memory-bank-sync`** : un ADR pour l'interface des ennemis ; les fiches `_rules` et `_patterns` du combat et du HUD que le diff périme ; `ROADMAP.md`, où la ligne P-05 renvoie désormais à ce cadrage au lieu de dire le lot prêt à passer en spec.

**Ce que le joueur voit** : le panneau des intentions refait, la barre de PV et son voile d'armure, la fiche de l'ennemi, les languettes ; et un combat gagné pendant la phase ennemie qui ne rouvre plus de tour.
