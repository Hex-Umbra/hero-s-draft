# Cadrage — le bestiaire (P-05) : trente décisions, et la première vague

> **Statut** : cadrage clos le 21/11/2026 avec le propriétaire, en deux séances (20 et 21 novembre). Trente questions posées, vingt-neuf tranchées, une en attente (B8) ; onze de plus, B31 à B41, tranchées le même jour sur la spec de la première vague ; dix-huit de plus, B42 à B59, le 22/11, pour le programme jusqu'à `0.7.0` et le tier 1. **Ce document est la source de vérité des décisions du bestiaire** : il remplace, là où ils divergent, les brainstormings du [27/07](27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md) et du [28/07](28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md), écrits pour un jeu qui n'avait ni charges à seuil ni grammaire d'effets en donnée. La ligne P-05 de [`ROADMAP.md`](../ROADMAP.md) (« cinq ennemis, `onHitEffect`, 2 à 3 jours, prêt à passer en spec ») est périmée par ce cadrage.
>
> **Les maquettes** sur lesquelles le propriétaire a tranché sont dans un deck privé, <https://claude.ai/artifact/9LxzmnszyErbptiiJh8LDZ> (59 diapositives). Font foi : 31 (panneau des intentions), 37 à 40 (barre, carte, fiche, plateau), 41 (armure), 54 (rat libre et meute), 58 (la famille du Rat). Ce sont des approximations — polices de remplacement, troncatures estimées : ce document et les specs portent en texte ce qu'elles fixent.
>
> **Livraison** : par vagues, un tier par vague jusqu'à `0.7.0` (B45, B59). La première, `0.6.1`, a livré l'interface des ennemis. **Depuis le 22/11, le déroulé vit dans [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)** — les vagues, le journal, les fiches et le catalogue des mécanismes ; ce document garde les décisions.

---

## 1. Les décisions acquises

Numérotées dans l'ordre où les questions ont été posées : B1 à B30 au cadrage, B31 à B41 le même jour, nées de la spec de la première vague, B42 à B59 le 22/11, à la préparation de la suite. Une décision corrigée par une suivante est écrite sous sa forme finale, sauf B14, que B32 amende par une exception, B42, que B45 et B50 amendent, et B45, que B59 amende.

### 1.1. Le langage et le contenu

| N° | Décision | Date |
|:---|:---|:---|
| **B1** | Une intention ennemie s'écrit avec la liste `effects` des cartes, et non avec un champ `onHitEffect` : un seul langage, des deux côtés. Les intentions d'aujourd'hui (attaque, Armure, Puissance) deviennent des écritures de cette liste ; les quatre ennemis existants migrent. | 20/11 |
| **B2** | Le bestiaire s'organise en familles, une signature par famille — Rat : la meute ; Slime : les charges ; Araignée : le Poison ; Gobelin : le larcin ; Squelette : la Faiblesse ; Orc : la Puissance. L'évolution d'une forme à l'autre attend. | 20/11 |
| **B4** | Le Kobold esquive au hasard, 20 % par attaque : un jet avant le calcul des dégâts, dans le calcul que le héros et les ennemis partagent, comme le coup critique. Restent à fixer à sa spec : un jet par coup et non par carte ; un coup esquivé ne pose ni charge ni statut ; le Poison et le Feu déjà posés ne s'esquivent pas. | 20/11 |
| **B5** | Le premier lot d'ennemis : la famille du Rat et les slimes élémentaires (de givre, de braise, d'orage — 1 Gel, 1 Feu ou 1 Foudre par coup, valeurs proposées). L'Araignée venimeuse, le Corbeau charognard, le Bandit de grand chemin et le Kobold éclaireur viennent au rythme des sprites. | 20/11 |

P-05 prépare, sans les construire, P-09 (une liste d'intentions par phase de boss), P-14 (un affixe d'élite est une liste d'effets ajoutée aux intentions) et P-44 lot 2 (épines, étourdissement, malédictions, symétriques) : le format des intentions se choisit en connaissant ces trois suites.

### 1.2. L'affichage

| N° | Décision | Date |
|:---|:---|:---|
| **B6** | Dans le panneau des intentions, une pastille par effet de l'intention, à la couleur de son statut. Au-delà de deux pastilles, la dernière devient « +1 ». | 21/11 |
| **B9** | Le panneau a trois colonnes fixes : le niveau, écrit (« Niv. 1 »), le nom, les pastilles. Les PV n'y figurent plus. Seul le nom se tronque. | 21/11 |
| **B10** | Une seule infobulle par intention, quelle que soit la pastille visée : elle dit toute l'attaque en une phrase. Au survol à la souris, à l'appui long au doigt. Un ennemi gelé qui perd son action garde ses pastilles, grisées et barrées. | 21/11 |
| **B11** | La Puissance quitte le dessus de la carte de l'ennemi : l'intention la compte déjà, et la fiche (B13) l'affiche. | 21/11 |
| **B12** | Au-dessus de la carte ne reste que la barre de PV, à la largeur de la carte : les PV en blanc, l'armure en bleu à côté. L'armure se montre aussi par un voile bleu posé sur la barre. | 21/11 |
| **B13** | La fiche de l'ennemi : toucher un ennemi quand aucune carte ni signature n'attend de cible agrandit sa carte, estompe le reste du plateau et affiche à côté son nom, son niveau, ses PV, son armure, sa Puissance, son intention en une phrase, ses bonus et ses altérations. Un toucher ailleurs la referme. Avec une carte sélectionnée, toucher l'ennemi joue la carte, comme aujourd'hui. La fiche remplace l'appui long sur la jauge. | 21/11 |
| **B14** | Les languettes : à gauche de la carte les bonus (vert), à droite les altérations et les charges (rouge). Au repos, l'icône et sa valeur dessous. Au survol de la carte, elles se déroulent : le nom, la valeur, et la durée quand il y en a une ; une charge sous son seuil garde son compte (« 2/3 »). Le même mécanisme sert la carte du héros. Au doigt, pas de survol : la fiche donne le détail. | 21/11 |
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
| **B7, B17, B18** | Chaque rat a sa carte et se cible seul. Le Rat est dessiné à 80 % de la taille d'une carte, libre ou en meute ; les rats invoqués se placent de part et d'autre de leur alpha, plus serrés que deux ennemis ordinaires. | 21/11 |
| **B20, B26, B27** | Deux ennemis : le Rat, tier 1 (dès l'acte 1), et le Rat alpha, tier 2 (dès l'acte 6). Le Rat existe seul : un ennemi invoqué reste un ennemi du bestiaire, qui peut aussi être tiré à la composition. La règle vaut pour toute famille — un nécromancien invoquera le Squelette existant. | 21/11 |
| **Consigne** | Le Rat alpha entre seul et invoque ses rats un par un, deux au plus. | 21/11 |
| **B23** | Invoquer prend l'action de l'alpha pour le tour. Un rat tué se réinvoque, au même prix. | 21/11 |
| **B22, B29** | Le lien de meute porte sur la Puissance seule : l'alpha gagne un pourcentage par rat invoqué vivant, un rat invoqué en gagne un tant que son alpha vit. Un rat libre n'entre pas dans le lien. Les valeurs montrées (+20 % par rat, +25 % pour le rat) sont des exemples. | 21/11 |
| **B24** | À la mort de l'alpha, ses rats restent, sans leur bonus. | 21/11 |
| **B25** | Un rat invoqué ne rapporte rien, ni or ni autre récompense. Un rat libre et un alpha rapportent comme tout ennemi. | 21/11 |
| **B21, B30** | À l'écran, une meute compte pour 2 cartes sur les cinq, quel que soit le nombre de ses rats, et un seul chef de meute est à l'écran : un second alpha attend en réserve. Le plateau porte six cartes au plus. | 21/11 |
| **B19** | Au-delà du plafond, la réserve existante s'applique sans changement ([règle 02-6](../../.obsidian_vault/_rules/)). | 21/11 |
| **B43** | Le sprite déjà produit, `art_src/creatures/rat/tier_1/rat_geant.aseprite`, est celui du **Rat alpha**. Le sprite du Rat reste à produire, par `/workflow-creature`, avant la vague de la meute. | 22/11 |

### 1.4. L'ordre des vagues

| N° | Décision | Date |
|:---|:---|:---|
| **B42** | *Amendée par B45 et B50.* Après l'interface (vague 1), **le langage des intentions d'abord (B1), seul**, en vague 2 ; la famille du Rat et la meute ensuite, en vague 3, écrites directement dans le nouveau format. Rien ne migre deux fois. La vague 2 n'ajoute aucun ennemi. | 22/11 |
| **B44** | Les slimes élémentaires (B5) sont **trois créatures neuves**, produites de zéro par `/workflow-creature`, et non des variantes du Slime. Ils n'entrent dans aucune vague avant leurs sprites. | 22/11 |

### 1.5. Le programme jusqu'à `0.7.0`

| N° | Décision | Date |
|:---|:---|:---|
| **B45** | *Amende B42 ; amendée par B59.* Le bestiaire se livre **un tier par vague**, jusqu'à `0.7.0` : la vague 2 (`0.6.2`) livre le langage des intentions (B1), les mécanismes du tier 1 et ses ennemis ; la vague 3 (`0.6.3`) le tier 2 ; la vague 4 (`0.6.4`) le tier 3 ; la vague 5 (`0.6.5`) le visuel — le cadre de tier, les fonds de fenêtre, le décor ; la vague 6 (`0.7.0`) le tier boss. Les tiers 4 et 5 viennent après `0.7.0`. Le déroulé : [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md). | 22/11 |
| **B46** | Une vague ne construit que les mécanismes dont ses ennemis se servent, et les branche dans la même vague ; un mécanisme se teste en jeu avec le premier ennemi qui s'en sert. Tous les mécanismes sont tenus dans un [catalogue](../chantier_bestiaire/catalogue_mecanismes.md), qui dit pour chacun sa vague. | 22/11 |
| **B47** | Les boss forment **un tier à part**, hors de l'échelle 1 à 5 des ennemis de base. | 22/11 |
| **B48** | Les quatre ennemis d'aujourd'hui n'ont pas de vague propre : chacun évolue avec sa famille, dans la vague de son tier — le Gobelin au tier 1, le Squelette au tier 2, l'Orc au tier 3. | 22/11 |
| **B49** | Le larcin du tier 1 est porté par **le Gobelin**, signature de sa famille (B2). Le Bandit de grand chemin n'entre pas au tier 1. | 22/11 |
| **B50** | *Amende B42.* Le Rat alpha étant de tier 2 (B20), **la meute — l'alpha, l'invocation, le lien — vient avec le tier 2**, en vague 3. Le Rat arrive seul en vague 2, avec sa demi-place. | 22/11 |
| **B51** | Une vague d'ennemis ne s'ouvre **qu'une fois tous ses sprites validés** ; la liste de ses ennemis est fixée dans sa fiche. | 22/11 |
| **B52** | **Tout le bestiaire est redessiné** dans le style des sprites neufs : chacun des quatre ennemis d'aujourd'hui reçoit un sprite neuf dans la vague de son tier — le Slime et le Gobelin en vague 2, le Squelette en vague 3, l'Orc en vague 4. | 22/11 |
| **B59** | *Amende B45.* **Les tiers 4 et 5 entrent au programme**, toujours un tier par vague : la vague 5 (`0.6.5`) livre le tier 4, la vague 6 (`0.6.6`) le tier 5. Le visuel passe en vague 7 (`0.6.7`), juste avant les boss, pour que le cadre de tier se pose une fois sur les cinq tiers. Le tier boss reste `0.7.0`, en vague 8. | 22/11 |

### 1.6. Le tier 1

Tranchées le 22/11 sur les recommandations du [deck de la vague 2](https://claude.ai/artifact/88qAGkoUHeX1Yi1YqzFSZK), qui en donne les chiffres et les options écartées. Ce sont des valeurs de départ : l'équilibrage les ajustera.

| N° | Décision | Date |
|:---|:---|:---|
| **B53** | *Fixe les valeurs que B5 proposait.* Les ennemis du tier 1 : **Rat** 8 PV, 3 dégâts, un coup ; **Slime de givre** 18 PV, 3 dégâts, 2 Gel par coup ; **Slime de braise** 18 PV, 3 dégâts, 1 Feu par coup ; **Slime d'orage** 18 PV, 4 dégâts, 1 Foudre par coup ; **Araignée venimeuse** 16 PV, 2 dégâts, Poison 1 par morsure ; **Corbeau charognard** 16 PV, 4 dégâts, vol de vie de 50 % des dégâts portés aux PV ; **Kobold éclaireur** 14 PV, 4 dégâts, esquive de 20 % par coup (B4). | 22/11 |
| **B54** | Le Rat ne frappe qu'une fois : **« plusieurs coups » part en vague 3**, avec le Loup des ombres. Une paire de rats vaut à peu près un ennemi, et son prix compte sa demi-place. | 22/11 |
| **B55** | *Tranche B8.* L'esquive se lit dans **une languette de bonus**, à gauche de la carte, le pourcentage à la place de la durée ; un texte flottant « Esquive ! » à chaque coup esquivé. | 22/11 |
| **B56** | Le « +1 » de B6 est **reporté** à la première intention à trois effets ; au tier 1, une intention en a deux au plus. | 22/11 |
| **B57** | Le larcin du Gobelin : **5 or par coup**, plafonné à l'or du héros ; **l'or volé est perdu** ; il se voit par un texte flottant « −5 or » au-dessus du héros et **une languette de butin** à gauche du Gobelin, qui dit ce qu'il a pris. La fuite du voleur reste au catalogue. | 22/11 |
| **B58** | Le prix d'un effet : **+6** au prix d'un ennemi qui en porte un (proposition du 28/07). Le Gobelin voleur, à 39, ne sort plus à l'acte 1 pour le Mage et le Berserker : accepté. | 22/11 |

---

## 2. Ce qui reste à trancher

Chaque point est repris, sous « Prérequis », par la fiche de la vague qui en a besoin ([`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)).

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

**Depuis le 22/11, le déroulé vit dans [`docs/chantier_bestiaire/`](../chantier_bestiaire/README.md)** (B45) : le journal, les fiches des vagues 2 à 7, le catalogue des mécanismes, et la méthode lue pour ce chantier. Ce §4 garde, pour mémoire, les arrêts et la fiche de la vague 1.

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
