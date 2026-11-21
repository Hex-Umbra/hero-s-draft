# P-05 vague 1 — l'interface des ennemis en combat — Conception

Date : 2026-11-21
Statut : **Conception** — vague 1 du chantier du bestiaire (`0.6.1`), branche `feat/v0.6.1-interface-des-ennemis`

Chantier ROADMAP : **P-05** « Bestiaire ». Les décisions font foi dans le
[cadrage du 21/11](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1 (B1 à B41) ; la fiche de
cette vague est son §4.2. La méthode est celle du
[fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§3 à §6, lu pour ce chantier.

> **Ce que le lot livre, en une phrase.** Rien ne change à ce que les ennemis font ; seul change ce que le joueur
> voit d'eux : le panneau des intentions passe à trois colonnes (niveau, nom, pastilles) avec une infobulle par
> intention ; au-dessus de la carte ne reste que la barre de PV, à la largeur de la carte, avec un voile d'armure qui
> est la jauge de l'armure seule ; toucher un ennemi sans carte ni signature en attente ouvre sa fiche ; les bonus et
> les altérations passent dans deux languettes de part et d'autre de la carte, qui se déroulent au survol — sur les
> ennemis comme sur le héros.

Toute référence `fichier:ligne` de ce document a été lue le 2026-11-21 sur la branche à `c2e2dacb`. Les
mesures en pixels des maquettes sont des approximations (polices de remplacement, troncatures estimées) : la spec
les porte en **unités de la carte** quand le composant suit l'échelle du jeu, en pixels logiques quand il est un
widget Flutter de largeur fixe.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce que le lot en livre | Où |
|:---|:---|:---|
| **B6** (part sans B1) | Une pastille par intention d'aujourd'hui — attaque, Armure, Puissance —, à la couleur de son statut, sauf la Puissance (B31). Une intention n'a qu'un effet (`enemy_intent.dart:3-7`) : la règle du « +1 » n'a rien à compter en `0.6.1` et se fixe avec B1 (§2) | §4.2, §5.1 |
| **B9** | Trois colonnes fixes : « Niv. N », le nom, les pastilles ; plus de PV ; seul le nom se tronque | §5.1 |
| **B10** | Une seule infobulle par intention, quelle que soit la pastille visée, au survol et à l'appui long ; l'ennemi gelé garde ses pastilles, grisées et barrées | §5.1 |
| **B11** | La Puissance quitte le dessus de la carte ; la fiche l'affiche | §5.2, §5.4 |
| **B12** | Au-dessus de la carte, la seule barre de PV, à la largeur de la carte : les PV en blanc, l'armure en bleu à côté, le voile bleu posé sur la barre | §5.2 |
| **B13** | La fiche : ouverture, contenu, fermeture ; elle remplace l'appui long sur la jauge | §4.7, §5.4 |
| **B14** | Les languettes, repos et survol, ennemis et héros ; au doigt, pas de survol | §4.3, §4.5, §5.3 |
| **B15** | Le voile est la jauge de l'armure seule : plein au plus haut, il recule à chaque coup, disparaît à zéro | §4.1, §5.2 |
| **B16** | De l'armure regagnée remplit le voile, le nouveau montant devient son plein | §4.1 |

Lues et tenues sans être livrées : **B1** (le format des intentions ne change pas : `EnemyIntent` garde `type` et
`value`, aucun fichier d'ennemi ne migre) ; **B8** (l'esquive et son affichage attendent la vague du Kobold : la
maquette en dessine un exemple, que la spec ne construit pas) ; **B3, B7, B17 à B30** (la demi-place, le Rat, la
meute, le plafond de six cartes) ; **B2, B4, B5** (familles, esquive, premier lot d'ennemis).

### 1.2. Les réponses du propriétaire, reprises telles quelles

Les maquettes sur lesquelles le propriétaire a tranché (deck privé du cadrage, diapositives 31 et 37 à 41). Ce
qu'elles fixent est porté en texte en §5 ; ce tableau dit seulement laquelle tranche quoi.

| Maquette | Réponse |
|:---|:---|
| **Le panneau des intentions** (retenue, 1 sur 5) | Trois colonnes fixes ; la pastille d'un effet porte l'icône et la valeur, sur un fond et un liseré de sa couleur ; l'infobulle donne toute l'attaque en une phrase ; la pastille survolée est cerclée de la couleur de l'infobulle |
| **Le survol** (option **B** retenue) | Une infobulle pour toute l'intention, quelle que soit la pastille survolée ; son titre est le libellé de l'intention (« Attaque Rapide : 2 »), sa phrase celle du jeu |
| **La barre de PV et la jauge d'armure** (retenue, 2 sur 5) et **l'armure** (lecture **B** retenue) | La barre à la largeur de la carte ; « 9/14 » en blanc, puis le bouclier bleu et le montant d'armure en cyan ; le voile plein au plus haut de l'armure, qui recule, puis disparaît : 6 couvrent la barre d'un Kobold comme 40 celle d'un boss. La lecture A (un voile plein tant qu'il reste de l'armure) est écartée par le propriétaire |
| **La carte et ses deux languettes** (retenue, 3 sur 5) | À gauche les bonus en vert, à droite les altérations et les charges en rouge ; au repos l'icône et la valeur dessous ; au survol de la carte, les deux se déroulent : le nom, la valeur, la durée quand il y en a une ; une charge sous son seuil garde son compte (« Gel 2/3 ») |
| **La languette** (la « variante » de droite retenue) | Déroulée, la languette ajoute ce que le repos ne montre pas — le nom et la durée —, au lieu de seulement mettre l'icône et la valeur côte à côte |
| **La fiche de l'ennemi** (retenue, 4 sur 5) | La carte agrandie, bordée d'or, le reste du plateau estompé ; à côté, un cadre : le nom en capitales et le niveau ; PV, Armure, Puissance ; « INTENTION » : la pastille, le nom de l'intention, sa phrase ; « BONUS » ; « ALTÉRATIONS » |
| **Le plateau à cinq ennemis** (retenue, 5 sur 5) | À cinq ennemis, deux languettes au repos qui se font face tiennent entre deux cartes ; déroulée, une languette passe par-dessus la carte voisine |

Les réponses du propriétaire du 21/11 aux questions que la spec avait laissées ouvertes, sous les numéros que le
cadrage leur donne :

| N° | Réponse | Où |
|:---|:---|:---|
| **B31** | La pastille de Puissance d'un ennemi garde **la flèche montante violette d'aujourd'hui** (`Icons.trending_up`, `#E040FB`) : l'éclair orange de la table se confondrait avec l'éclair d'une petite attaque | A5, §4.2 |
| **B32** *(amende B14)* | La Foudre chargée s'affiche **en jaune** (`yellowAccent`) dans la languette de droite, comme depuis la vague des charges ; tout le reste de la languette de droite reste rouge | §4.3, §5.3 |
| **B33** | Une charge rompue sans chiffre montre au repos le nom de son état (« Gelé ») | §4.3 |
| **B34** | Une section vide de la fiche ne s'affiche pas ; un statut de 99 tours n'affiche pas de durée ; une ligne de description seulement pour la Faiblesse et le Vulnérable | §4.3, §4.4 |
| **B35** | La fiche ne s'ouvre qu'au tour du joueur et se ferme quand il finit | A10, A12 |
| **B36** | L'estompage couvre le plateau seul (décor, héros, main, autres ennemis) ; les panneaux et les boutons restent nets | A11 |
| **B37** | Le tutoriel gagne une phrase à l'étape des intentions ennemies (§6.3) | §6.3, §7 |
| **B38** | Le panneau des effets du héros reste, à côté de ses languettes : au doigt, c'est le seul détail du héros | §2 |
| **B39** | Une languette qui sortirait de l'écran se déroule vers l'intérieur, par-dessus sa propre carte | §5.3 |
| **B40** | La carte dont la fiche s'ouvre garde sa barre à la hauteur des autres et grandit vers le bas | A11 |
| **B41** | 💎 pour la régénération de Mana, 💖 pour celle des PV, sur la languette du héros | A8, §4.3 |

### 1.3. Les arbitrages

**A1 — Chaque élément vit dans une couche, et aucune donnée neuve n'entre dans l'état Riverpod** *(T, filtre 5)*.
Le panneau des intentions et le cadre de la fiche sont des widgets Flutter du HUD ; la barre, le voile, les
languettes, l'agrandissement de la carte et l'estompage sont des composants Flame, attachés à la carte qu'ils
habillent et qui bougent avec elle (élan, secousse, mort). Ce que tous affichent se calcule par des fonctions pures
(§4), testables sans écran. La fiche ouverte est un état d'affichage, pas une règle : `HerosDraftGame` la tient, sur
le modèle de `awaitingEnemyTarget` (`heros_draft_game.dart:103-112`), et `GameScreen` le reflète par un rappel,
comme `_armedSignature` (`game_screen.dart:75-76`). Le détail, élément par élément, est en §3.

**A2 — Le plus haut montant d'armure vit sur `EnemyCard`, calculé par une règle pure, `ArmorVeil`** *(T, filtres 5
puis 8)*. Aucune règle de jeu ne le lit : il ne sert qu'au voile. Il se calcule à chaque état appliqué à la carte,
de l'ancien au nouveau, là où `refreshChargeVisuals` pose déjà halo et gangue d'après la même transition
(`enemy_card.dart:288-294`, `combat_entity.dart:243-279`). Le mettre dans `EntityStats` le ferait entrer dans la
sauvegarde du héros, qui partage le modèle ; le mettre sur `EnemyInstance` demanderait de le tenir à jour à chacune
des écritures de l'état de combat (`combat_controller.dart`, neuf affectations de `state`). Une transition que
l'animation d'une carte diffère (`enemy_card.dart:257-264`) ne peut pas contenir un gain suivi d'une perte : un
ennemi ne gagne d'armure que pendant sa phase (intention Défense, `turn_phase_manager.dart:211-220` ; Métallisation,
`status_effect_processor.dart:141-149`), après la chaîne du Feu qui seule l'entame alors. Règle en §4.1.

**A3 — La barre remplace `StatBadge`, qui disparaît avec ce qu'il était seul à utiliser** *(T, filtres 5 puis 7)*.
`StatBadge` n'a qu'un appelant, la barre de l'ennemi (`enemy_card.dart:130-143`) ; ses branches cercle, armure,
attaque et mana ne servent pas. Un composant neuf, `EnemyHealthBar` (`lib/game/components/entities/`), porte la
`LinearProgressBarComponent` existante — dont le paramètre `armorPercentage` dessine déjà le voile
(`linear_progress_bar.dart:58-100`) et reçoit désormais la part d'`ArmorVeil` — et les deux textes. Partent :
`stat_badge.dart`, `circle_progress.dart` (son seul lecteur était `StatBadge`), l'appui long et son infobulle
(`stat_badge.dart:472-486`, B13), les clés que rien d'autre ne lit (§6.2), les trois tailles de badge de
`GameConstants` (`badgeHpSize`, `badgeStandardSize`, `badgeCircleSize`, `game_constants.dart:35-37`, lues par le seul
`stat_badge.dart`) et `EnemyCard.getTranslation` (`enemy_card.dart:188-200`, lu par le seul `_refreshBadges`,
`:203-224` ; `activeLocale` reste, `_brokenNameOf` le lit, `:247`, et passe à `CombatEntity`, d'où les languettes
lisent leurs textes, §4.3). `onShowTooltip` ne sert plus qu'aux cartes : son
`CardType?` devient `CardType`, et la branche `null` de `_getTooltipBorderColor` (`game_screen.dart:59`) tombe ; le
champ `_tooltipCardType` (`:55`), lu à chaque construction (`:702`) avant toute infobulle, devient un `CardType`
initialisé à `CardType.skill` — le `blueAccent` qu'il donne aujourd'hui à `null` —, et le `!` du `switch` (`:60`)
tombe avec lui. `FlameShieldIcon` reste, la barre neuve le dessine.

**La barre reçoit les touchers de sa carte** : elle est hors du rectangle 100 × 140 de la carte (A4), où
`StatBadge`, composant à `TapCallbacks` (`stat_badge.dart:13-14`), avalait aujourd'hui ces touchers, que le décor
recevrait sinon (`heros_draft_game.dart:255-260`). `EnemyHealthBar` porte `TapCallbacks` et renvoie son `onTapDown`
à l'`onTapEnemy` de sa carte (`enemy_card.dart:413-416`) : pour ouvrir la fiche, la garder ouverte et cibler, la barre
est l'ennemi. **Sa zone d'appui descend jusqu'à y 0**, le haut de la carte : la bande de 4 unités qui sépare la barre
dessinée (y −17 à −4, A4) de la carte n'est pas un trou. **La zone de l'ennemi** est donc le rectangle continu qui va
du haut de la barre (y −17) au bas de la carte (y 140), plus ses languettes ; c'est elle, et elle seule, que lisent
`_livingEnemyAt` (`heros_draft_game.dart:244-249`), l'arbitre du survol (A9, §4.5) et `findHoveredEnemy`, qui cherche
la cible d'une carte qu'on glisse et ne lit aujourd'hui que `enemy.containsPoint`, la carte seule
(`card_interaction_handler.dart:86-90`, `:160-165`) : toucher la barre ou une languette joue la carte (A10), la lâcher
dessus la cible aussi.

**A4 — La géométrie de la barre, en unités de la carte** *(T, filtre 6)*. La carte mesure 100 × 140 unités, mises à
l'échelle par `baseScale` = `scaleFactor` × 1,45 (× 1,25 pour un boss) × `scaleMultiplier`
(`enemy_card.dart:59`, `:69-70`) ; à 1280 × 800 et cinq ennemis, une unité vaut 1,43 px. La barre occupe x 0 à
100, y −17 à −4 : 13 unités de haut (19 px), 4 sous elle (6 px), la mesure de la maquette (270 × 37 à l'échelle
1,9). Rayon 4 ; fond, bordure et dégradé des PV de `LinearProgressBarComponent` inchangés. Les textes sont centrés
sur la barre : « PV/PV max » blanc gras 9, ombré de noir ; si l'armure est positive, 3 unités plus loin, le
bouclier bleu `#2196F3` de 8 unités et, 2 plus loin, le montant en `#00E5FF` gras 9 — les couleurs du badge
d'aujourd'hui (`stat_badge.dart:117-128`). Sans armure, le seul « PV/PV max ». Ces mesures sont des constantes de
`GameConstants` (`lib/game/game_constants.dart`), posées une seule fois en tâche 1 (§10) et lues par la barre (tâche
3) comme par la zone de l'ennemi (tâche 4).

**A5 — Les pastilles d'une intention sont un calcul pur, `IntentPips`, qui reprend les icônes et les couleurs
d'aujourd'hui** *(T, filtres 1, 6 puis 8 ; l'apparence de la Puissance est B31)*. `IntentPips` reçoit le calcul
`_visuals` du panneau (`enemy_intents_panel.dart:68-84`), tel quel. L'attaque garde ses quatre paliers d'icône et de
couleur (`:69-78`) : la maquette dessine celui des petites attaques, l'éclair ambre `#F39C12`, et le tutoriel les
enseigne (§7). La Puissance garde la flèche montante violette (`Icons.trending_up`, `#E040FB`, `:81-82`) : c'est la
réponse du propriétaire, B31. La Défense garde le bouclier `Icons.shield` `#448AFF` (`:79-80`) : c'est le plus simple,
et sans changement visible — l'entrée `armor` de la table (`effect_icons.json:3`) dessinerait `shield_rounded`, une
autre forme. `IntentPips` ne lit donc pas la table d'icônes : la vague de B1 dira comment chaque effet d'une
intention prend sa pastille. La valeur reste celle de `compactValue` (`enemy_intents_panel.dart:27-30`).
`IntentPips` ne calcule aucun débordement : aucune intention de `0.6.1` n'a deux effets, et un compteur sans lecteur
serait du code mort (filtre 7). Règle en §4.2.

**A6 — Le panneau : les largeurs des colonnes et la clé du niveau** *(T, filtres 5 puis 6)*. Le panneau garde sa
largeur de 250, sa marge de 16, sa bordure de 1,5 et la réserve de 8 à droite de sa liste défilante
(`enemy_intents_panel.dart:273-281`, `:338`) ; un `Container` ajoute la bordure de sa décoration à sa marge : 250 −
2 × (16 + 1,5) = 215 utiles, 207 quand il défile. Colonne du niveau : 40, le texte réduit s'il déborde (`FittedBox`,
jamais tronqué) ; colonne des pastilles : 96, la place de deux pastilles que dessine la maquette, alignées à gauche ;
entre deux colonnes, 6 ; le nom prend le reste, 59 à 67 — les 74 de la maquette — et seul il se tronque, par points de
suspension. « Niv. N » / « Lvl. N », écrit aujourd'hui en dur selon la locale
(`enemy_intents_panel.dart:232-236`), lit la clé ARB existante `levelLabel` (`app_fr.arb:178`, `app_en.arb:453`,
déjà lue par `signature_bar.dart:536`), que la fiche lit aussi *(amendé par la vérification du plan : une clé
`enemyLevel` l'aurait doublée)*.

**A7 — L'infobulle unique enveloppe la rangée des pastilles ; son contenu ne change pas** *(T, filtres 1 puis 8)*.
Le `Tooltip` d'aujourd'hui (`enemy_intents_panel.dart:113-161`) passe de la pastille à la rangée : il garde son
déclenchement (survol à la souris, appui long au doigt), son titre (`getLabel`, « Attaque Rapide : 2 »), sa phrase
(`explanation`), son style, sa bordure de la couleur de la première pastille, et le cas gelé (bordure
`lightBlueAccent`, « Gelé : ne fait rien ce tour »). Sous la souris, la pastille survolée prend un liseré de 1,5 de
la couleur de l'infobulle (maquette 1 sur 5) ; au doigt, rien. Ce qui reste de la phrase complète d'une intention
à plusieurs effets (« … et lui infligera 2 Poison pendant 3 tours ») est l'affaire de B1.

**A8 — Les languettes : un seul composant Flame, `StatusTabs`, pour l'ennemi et pour le héros, lu sur une vue pure,
`StatusReadout`** *(T, filtres 5, 6 puis 7)*. `StatusTabs` remplace `StatusIndicator` sur `EnemyCard`
(`enemy_card.dart:145-161`) et s'ajoute à `HeroCard`, qui n'en a aucun (B14 : « Le même mécanisme sert la carte du
héros »). Le partage gauche / droite est celui d'aujourd'hui (`enemy_card.dart:230-244`), sorti dans `StatusReadout`
pour servir les deux cartes et la fiche. **Une entrée par statut porté, clé `id` + source** : le héros peut porter
deux Puissances de sources différentes ([ADR-104](../../../.obsidian_vault/_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md),
« le panneau des effets montre une ligne par entrée ») ; l'indicateur d'aujourd'hui supposait une entrée par `id`
(`status_indicator.dart:69-73`, l'avertissement de [`_rules/04-00`](../../../.obsidian_vault/_rules/04-00-alterations-d-etat-statuts.md)).
**Les icônes restent les émojis de `statusEmoji`** (`status_indicator.dart:227-252`), que la maquette dessine :
passer les statuts ennemis sur la table d'icônes est une ligne de la ROADMAP
([`_patterns/05-13`](../../../.obsidian_vault/_patterns/05-13-table-d-icones-d-effet.md), note), hors de ce lot. Le
héros porte deux statuts que la fonction ne connaît pas : `mana_regen` prend 💎 et `hp_regen` 💖, les formes de leur
entrée de table (diamant, cœur), réponse du propriétaire, B41 ; les compteurs de reliques gardent ✨. `statusEmoji` passe
dans `status_readout.dart`, pur (tâche 1), que lisent les languettes, la fiche et son second lecteur, le « +N 🔥 » de
la vague du Feu (`combat_visual_system.dart:71`) : la fiche Flutter n'importe aucun composant Flame. La géométrie est
en §5.3.

**Les languettes déroulées reçoivent les touchers de leur carte.** Une languette déroulée passe sur la carte voisine
(maquette 5 sur 5) ; sans réception propre, un appui sur elle irait à la carte dessous — Flame confie l'appui au
premier composant à `TapCallbacks` qui contient le point, et la carte qui porte la languette ne le contient pas
(`component.dart:879-883`, flame 1.38) — : avec une carte focalisée, la carte se jouerait sur la voisine. `StatusTabs`
porte `TapCallbacks` et renvoie l'appui à sa carte (`onTapEnemy` pour un ennemi, le `onTapDown` de `HeroCard`,
`hero_card.dart:82-102`, pour le héros) ; `_livingEnemyAt` suit la même règle : la zone de l'ennemi (A3) comprend
ses languettes, et celle de la carte survolée passe avant les autres. Au repos, une languette ne passe sur aucune
carte et renvoie de même ses appuis.

**A9 — Le survol d'une carte de combat est un arbitre géométrique pur, `pickHoveredEntity`** *(T, filtres 6 puis
8)*. Il vit dans `onPointerMove` (`heros_draft_game.dart:166-175`), à côté de `refreshHover`. Un `PointerMoveEvent`
de Flame est un événement de survol (`PointerHoverEvent`, flame 1.38) : un doigt n'en produit jamais, ni une souris
bouton enfoncé — un glisser de carte ne déroule rien, et B14 (« au doigt, pas de survol ») tient par construction.
L'arbitre lit la zone de chaque carte vivante (A3) — pour un ennemi, le rectangle continu de sa barre au bas de sa
carte, plus ses languettes, au repos ou déroulées ; pour le héros, sa carte et ses languettes — : survoler une
languette au repos déroule sa carte, et le pointeur qui glisse de la carte sur sa languette ouverte la garde ouverte, comme la
carte survolée de la main est gardée (`pickHoveredCard`, [ADR-119](../../../.obsidian_vault/_adr/ADR-119-les-corrections-de-fin-de-vague-8.md)).
La carte survolée passe à la priorité `priorityEntityHovered` (5) : ses languettes déroulées passent sur la carte
voisine (maquette 5 sur 5), sous la main (10 et plus). Le pointeur qui quitte le jeu (`pointerLeft`), une carte
morte ou mourante, la fiche ouverte : plus rien n'est survolé. Règle en §4.5.

**A10 — Le toucher qui ouvre la fiche passe après la carte focalisée et la signature armée** *(T, filtres 1 puis
5)*. Dans `_handlePlayerTargeting` (`heros_draft_game.dart:407-438`), l'ordre devient : une carte focalisée, quelle
que soit sa cible, garde le toucher, comme aujourd'hui (`:414-430`) ; une signature en attente reçoit l'ennemi vivant
(`:434-437`) ; sinon, un ennemi vivant touché ouvre sa fiche — ou la garde ouverte si c'est la sienne, ou remplace
celle d'un autre. La garde d'entrée reste (`:408-412`) : run vivante, tour du joueur (B35). Un
ennemi mort ou mourant n'ouvre rien. `onSelectEnemy` et `selectedEnemyId` ne servent pas : la fiche n'est pas une
cible et ne touche pas à la résolution des cartes (`combat_controller.dart:191-195`).

**A11 — La mise au premier plan et l'estompage sont des composants Flame** *(T, filtres 6 puis 8 ; tâche à
risque)*. La carte ouverte grandit de **1,25**, le facteur de la carte focalisée de la main
(`card_animation_system.dart:91-96`) — la maquette mesure 1,27 —, porté par `baseScale`, si bien que les effets qui
ramènent la carte à son échelle de base (`combat_entity.dart:33-57`, `:59-77`, `:291-306`) la ramènent à son échelle
agrandie ; elle descend de 0,25 × 87 unités, pour que le haut de sa barre reste où il était et ne passe pas sous la
barre du haut du HUD (`combat_top_bar.dart:36-92`, `top: 10`) ; `LayoutSystem.repositionEnemies` garde ce décalage
pour elle (`layout_system.dart:133-135`). **Écart à la maquette, tranché par le propriétaire (B40)** : la maquette 4
sur 5 hausse la barre agrandie au-dessus de celle des voisines (`h-fiche.html`, `mv-bar` à `top: 16px` contre
`mv-ghost-bar` à `top: 68px`, à l'échelle 2) ; la carte garde sa barre à la hauteur des autres et grandit vers le bas,
parce qu'un boss, déjà à × 1,25 (`enemy_card.dart:59`), dont le haut de barre est vers 10 px à 1280 × 800, la verrait
sortir de l'écran (vers −29 px : 168 − 87 × 1,8125 × 1,25) en grandissant autour de son centre.

**Sa bordure vient d'un état propre, `isInspected`**, que `_refreshBorderVisuals` (`enemy_card.dart:296-307`) lit en
premier — ambre de 4, la bordure dorée de la maquette —, puis `isSelected` (ambre de 4), puis la surbrillance
(cyan de 3) *(ordre fixé par le plan, D14 : la sélection garde son ambre sous une carte focalisée, comme aujourd'hui)*.
Seul changement visible : une carte focalisée visant les ennemis, les ennemis non sélectionnés gardent une bordure cyan
(3) sous leur halo, au lieu du blanc (2). Ni la synchronisation
de la sélection (`state_sync_system.dart:185-192`, à chaque état), ni `highlightEnemy`
(`heros_draft_game.dart:309-315`), ni `setSelection` et `setHighlight` (`enemy_card.dart:309-342`) ne l'écrivent :
`selectedEnemyId` — la dernière cible jouée (`combat_controller.dart:268`), que la mort de l'ennemi efface
(`:408-412`) — garde son ambre propre, que la fermeture de la fiche ne touche pas. `setSelection` et `setHighlight`
passent par `_refreshBorderVisuals` au lieu d'écrire la bordure eux-mêmes.

**Le voile d'estompage** — noir à 55 % sur toute la scène Flame : décor, héros, main, autres ennemis ; le HUD Flutter,
panneaux et boutons, reste net (B36) — est à la
priorité `priorityInspectionVeil` (**180**), au-dessus de la carte survolée (100) et de la carte focalisée (150) de la
main ; la carte ouverte passe à `priorityInspectedEnemy` (**190**), et ses particules de coup à 200
(`combat_entity.dart:144`, priorité de la carte + 10). **Passent au-dessus du voile** : les textes flottants et les
icônes d'effet, ajoutés au jeu à 200 (`combat_entity.dart:214`, `enemy_card.dart:379`, `hero_card.dart:238`) — ceux de
la carte ouverte se lisent, ceux des autres cartes aussi, brefs ; la carte jouée en vol, à 500
(`card_animator.dart:149`, `lib/game/components/visual_effects/`) et sa traînée (`:63`, sa priorité − 1), qui frappe
peut-être la carte ouverte (A10 ne teste pas `isCardAnimating`). La ligne de ciblage n'y passe pas : elle est enfant
de `CombatVisualSystem` (`combat_visual_system.dart:10-17`), ajouté au jeu à la priorité 0
(`heros_draft_game.dart:275-278`), donc sous le voile — et cachée pendant la fiche, aucune carte n'étant focalisée.
Agrandissement, descente et fondu du voile : 0,15 s, à l'aller comme au retour. Ses languettes restent au repos,
agrandies avec elle (maquette 4 sur 5). Une carte morte ou mourante que la fiche quitte ne rejoue ni agrandissement ni
descente, pour garder son effet de mort — une garde défensive, qu'un geste ordinaire n'atteint pas (plan, D8).

**A12 — Tout toucher qui n'est pas sur la carte ouverte ferme la fiche ; Flame en est le seul propriétaire** *(T,
filtres 1 puis 5)*. B13 : « Un toucher ailleurs la referme. » `GameScreen` enveloppe son `Stack` d'un `Listener`
(`HitTestBehavior.translucent`, ancêtre de tout ce qui se touche) qui, à chaque appui du **bouton principal**
(`event.buttons == kPrimaryButton`, le seul que Flame accepte, `multi_tap_dispatcher.dart:161-163`), appelle
`_game.closeInspectionUnlessOn(event.pointer)` — HUD compris, cadre de la fiche compris. `kPrimaryButton` s'importe
de `package:flutter/gestures.dart` : `material.dart` ne l'exporte pas.

**La décision de fermer est dans Flame, et elle ne lit que le pointeur.** **L'ordre est fixe : Flame d'abord.** La `RawGestureDetector` du jeu est plus profonde
que le `Listener` de l'écran, et la distribution d'un appui va du plus profond au plus haut (`box.dart:2953-2954`,
`binding.dart:496`) ; le `MultiTapGestureRecognizer` de Flame rend son `onTapDown` dès l'appui (`multitap.dart:515-534`
; flame `gesture_detector_builder.dart:40`, `multi_tap_dispatcher.dart:37-45`, `:133-135`). **Flame retient le
pointeur de l'appui qui a ouvert ou gardé une fiche** : le `pointerId` de son `TapDownEvent` est le `pointer` du
`PointerDownEvent` que reçoit le `Listener` (`multitap.dart:524-526`). `closeInspectionUnlessOn(pointer)` garde la
fiche **si et seulement si** ce pointeur est celui que Flame vient de retenir, puis l'oublie ; elle la ferme sinon ;
elle ne lit ni un point ni le reflet que `GameScreen` tient. Tout appui que Flame reçoit sur la carte ouverte, sa
barre ou sa languette passe par `_handlePlayerTargeting`, qui garde la fiche et retient le pointeur (ce n'est pas
« ailleurs ») ; un appui sur un autre ennemi vivant, sa barre ou sa languette : Flame ouvre sa fiche et retient le
pointeur, le `Listener` la garde. La géométrie que `inspectEnemy` change pendant l'appel n'entre donc pas dans la
décision. Un appui sur le HUD — fût-ce un bouton peint au-dessus de la barre de la carte ouverte, Son ou Deck devant
l'ennemi de droite à cinq ennemis (`combat_top_bar.dart:36-75`, peint au-dessus du `GameWidget`,
`game_screen.dart:573-581`) — ou sur le cadre de la fiche : Flame ne le reçoit pas, le `Listener` ferme. **Effet de
bord, accepté** : un appui sur une carte jouée en vol au-dessus de la carte ouverte ferme la fiche — la carte en vol
consomme l'appui sans rien faire (`isPlayed`, `card_interaction_handler.dart:17`), et rien ne retient le pointeur.
Flame ferme aussi de
lui-même, par garde : une carte focalisée (`setFocusedCard`, `heros_draft_game.dart:153-158`), une signature armée
(le mutateur de `awaitingEnemyTarget`), le décor (`:255-260`), la fin du tour du joueur (`executeTurn`, `:440-457`, B35),
et, à chaque état de combat appliqué (`state_sync_system.dart:97-195`), l'ennemi parti, la phase quittée ou le combat
fini. Chaque ouverture et chaque fermeture passent par un seul rappel, `onInspectionChanged(EnemyInspection?)` —
l'id de l'ennemi et le rectangle de sa carte agrandie, barre et languettes au repos comprises, à l'échelle
d'arrivée —, que `GameScreen` reflète ; **ce rectangle ne sert qu'à placer le cadre** (`SheetPlacement`, §4.6) :
l'écart de 24 se mesure depuis les languettes, et le cadre ne recouvre pas la languette au repos du côté où il se pose,
qui reste touchable — sauf quand aucun côté ne tient (§4.6). **Quand les ennemis se replacent
fiche ouverte**, il change : redimensionnement de la fenêtre (`onGameResize`, `heros_draft_game.dart:294-301`), mort
ou entrée d'un ennemi pendant qu'une carte vole (`resolvePendingDeaths`, `:355-378` ; l'apparition d'un ennemi de la
réserve, `state_sync_system.dart:171-175`). Ce n'est pas tout : **chaque reconstruction de `GameScreen`** rappelle
`onGameResize`, à taille inchangée (`GameWidget` neuf à chaque `build`, son `LayoutBuilder` relancé, plan D10).
`repositionEnemies` réémet `onInspectionChanged` avec le nouveau rectangle, si une fiche est ouverte, que son ennemi
reste **et que le rectangle a changé** (plan D16) : le cadre suit la carte, et le reflet ne se rappelle pas lui-même ;
une place et une échelle inchangées ne coupent pas l'animation de la fiche (plan D10, D15). **Tout reflet dans `GameScreen`
est différé**, réémission comprise, comme `onEnemiesSpawned` (`game_screen.dart:394-401`, `addPostFrameCallback`) :
le rappel peut venir pendant le `build` du `LayoutBuilder` de `GameWidget`, qui appelle `onGameResize`
(`game_widget.dart:410`, flame 1.38.2) puis `update(0)`, où `setState` est interdit.

**La main et les languettes ne réagissent pas au survol pendant la fiche** *(T, filtre 6)* : c'est la conséquence de
B13 — le reste du plateau est estompé, et tout toucher ailleurs ferme la fiche ; une carte de la main qui grandirait
sous le voile annoncerait un geste qu'un appui ne ferait pas (il fermerait la fiche d'abord). `refreshHover` et
l'arbitre de §4.5 ne désignent rien tant que `inspectedEnemy` n'est pas nul.

**A13 — Le cadre de la fiche est un widget Flutter, nourri d'une vue pure, `EnemySheetView`, et placé par une
fonction pure, `SheetPlacement`** *(T, filtres 5 puis 6)*. Le texte, la mise en page et la traduction sont l'affaire
du HUD ; les coordonnées du canevas Flame sont celles du `Stack` de `GameScreen`, où le `GameWidget` est en
`Positioned.fill` (`game_screen.dart:573-578`) : le cadre se pose dans ce `Stack`, **hors** de la `SafeArea` du HUD
(`:581`), après elle, pour ne jamais passer dessous. Il lit l'ennemi dans `combatProvider` à chaque construction :
il suit l'état sans copie. Un id reflété absent de `combatState.enemies` — une ou deux images, le reflet étant
différé (A12) — : le cadre ne se dessine pas. Il absorbe ses touchers, pour qu'un appui sur lui n'atteigne pas un ennemi estompé
dessous. Règles en §4.4 et §4.6.

**A14 — Les textes** *(P, délégués à la spec par la fiche de la vague — cadrage §4.2, « La spec doit fixer », point
5 —, comme les textes des vagues précédentes, A17 de la vague 8)* : §6. Les clés neuves ; les clés que le retrait du badge laisse sans lecteur
partent, aucune n'a d'autre lecteur (`grep` du 21/11, §6.2).

**A15 — Le tutoriel réaligne sa maquette de combat ; son étape des intentions suit le panneau réel** *(T, filtre 6 ;
la phrase sur la fiche est B37)*. §7.

**A16 — Un seul plan, six tâches, plus la vérification finale** *(T, filtre 7)* : §10.

### 1.4. Les questions ouvertes

Aucune. Les questions que la spec avait laissées ouvertes ont reçu leur réponse du propriétaire le 21/11 : B31 à
B41 (§1.2). Aucune question de classe D : B32 amende B14, par le propriétaire lui-même ; B31 fait une exception à « la
couleur de son statut » de B6.

---

## 2. Périmètre

**Dans le lot** : le panneau des intentions refait (§5.1) ; la barre de PV et son voile d'armure (§5.2) ; les
languettes, sur les ennemis et sur le héros (§5.3) ; la fiche de l'ennemi (§5.4) ; les fonctions pures qui les
calculent (§4) ; les textes (§6) ; la maquette de combat et l'étape des intentions du tutoriel (§7) ; les tests de
calcul et de contrôleur (§9). La correction S9 (`8d544a3d`), déjà sur la branche de départ, sort avec `0.6.1` sans
travail de ce lot.

**La lecture du « +1 » de B6 se fixe avec B1**, quand une intention aura plus d'un effet : ce lot ne calcule ni ne
dessine aucun compteur.

| Hors du lot | Où |
|:---|:---|
| Les intentions écrites avec `effects` (B1), leurs pastilles de statut, la phrase complète d'une intention à plusieurs effets, le « +1 » de B6 | Vague du langage des intentions |
| L'esquive et son indicateur (B4, B8), tout nouvel ennemi, la demi-place, la meute, le plafond de six cartes, le tier (B3, B5, B7, B17 à B30) | Vagues suivantes |
| La jauge du héros (`PlayerHealthBar`) et son panneau des effets (`StatusEffectsPanel`), qui gardent leur forme : le héros ne reçoit que ses languettes ; le panneau reste à côté d'elles, seul détail du héros au doigt (B38) | — |
| Tout équilibrage ; ce que font les ennemis | — |
| Les émojis des statuts ennemis passés sur la table d'icônes | ROADMAP ([`_patterns/05-13`](../../../.obsidian_vault/_patterns/05-13-table-d-icones-d-effet.md)) |
| `health_bar.dart` (`HealthBarComponent`), que rien n'utilise aujourd'hui | À la file |

### 2.1. Les transitions

| Frontière | État | Réglé par |
|:---|:---|:---|
| `0.6.0` → `0.6.1` | Le badge au-dessus de la carte montre ⚡ Puissance, 🛡 armure, une barre de 66 et les PV (`stat_badge.dart:74-174`) ; un appui long l'explique | La barre seule (A3, A4) ; la fiche (B13) |
| L'indicateur d'aujourd'hui → les languettes | Valeur à droite de l'icône, durée ou état rompu dessous, pas de 36 unités (`status_indicator.dart:84-100`, `:177-202`) ; une entrée par `id` | `StatusTabs` (A8) ; une entrée par `id` + source |
| ADR-119 → B9 | Le panneau en lignes compactes : nom, niveau, PV, une pastille (`enemy_intents_panel.dart:203-251`) | Trois colonnes, plus de PV (A6) |
| Ce lot → la vague de B1 | Une pastille par intention ; aucun compteur | La vague de B1 donne la liste des effets, dit comment chaque effet prend sa pastille (A5) et fixe le « +1 » de B6 |
| Sauvegardes de `0.6.0` | Rien de neuf n'est écrit | §8 |

### 2.2. L'état mesuré

Le cadrage (§3) a lu le code le 21/11 sur `8d544a3d`. Re-mesuré sur `c2e2dacb`, qui n'ajoute que le cadrage :

| Prémisse du cadrage | Mesure | Où |
|:---|:---|:---|
| La valeur d'une attaque inclut déjà la Puissance | Vrai : `effectiveMight` entre dans `finalValue` | `enemy_instance.dart:33-51` |
| L'infobulle du panneau s'ouvre au survol et à l'appui long | Vrai : `Tooltip` en `longPress`, qui s'ouvre aussi au survol de la souris | `enemy_intents_panel.dart:113-114` |
| Le badge montre la Puissance et l'armure ; le voile vaut `armure / PV max` ; le plus haut montant d'armure n'est retenu nulle part | Vrai | `enemy_card.dart:130-138`, `:202-225` |
| Toucher un ennemi sans carte sélectionnée ne fait rien | Vrai hors d'une signature armée | `heros_draft_game.dart:432-437` |
| **Le survol n'existe que pour les cartes de la main** | **À nuancer** : `onPointerMove` illumine déjà l'ennemi vivant sous la souris pendant qu'une signature attend (`_livingEnemyAt`), et le glisser d'une carte cherche l'ennemi sous elle. Ce que le lot ajoute — un survol d'ennemi et de héros sans cible attendue — réutilise ce test de point | `heros_draft_game.dart:171-173`, `:244-249` ; `card_interaction_handler.dart:86-90`, `:160-165` |
| Les bonus à gauche, les altérations et les charges à droite | Vrai | `enemy_card.dart:145-161` |
| **À 1280 × 800, cinq cartes tiennent à pleine taille** | **À 98,7 %** : 5 × 170 × 1,45 = 1232,5 > 0,95 × 1280 = 1216, `scaleMultiplier` 0,987 ; une carte de 143 px, 93 px entre deux — la mesure de la maquette 5 sur 5 | `layout_system.dart:111-118`, `:124-128` |
| Le nombre d'ennemis est un entier ; un tier tous les cinq actes, plafonné à 3 ; le prix d'un ennemi | Vrai | `encounter_system.dart:209`, `:262-264` |

Deux fiches du vault sont en retard sur le code, sans lien avec ce lot mais lues pour lui : les priorités
`priorityHero` (10) et `priorityEnemy` (20) de [`_patterns/05-4`](../../../.obsidian_vault/_patterns/05-4-constantes-de-z-indexing.md)
n'existent pas (`game_constants.dart:10-18` ; `EnemyCard` et `HeroCard` sont à 0) ; la ligne `HeroCard` de
[`_patterns/05-3`](../../../.obsidian_vault/_patterns/05-3-composants-flame.md) lui prête une barre, des badges et des
icônes de statut qu'il n'a pas (`hero_card.dart:105-130`). §11 les porte à `memory-bank-sync`.

---

## 3. Où vit chaque chose

| Élément | Couche | Fichier | Pourquoi |
|:---|:---|:---|:---|
| Panneau des intentions, pastilles, infobulle | Flutter (HUD) | `lib/ui/widgets/hud/enemy_intents_panel.dart` | Il y est ; il lit `combatState.enemies` (`combat_side_panels.dart:128-139`) |
| Les pastilles d'une intention | Calcul pur | `lib/ui/widgets/hud/intent_pips.dart` *(nouveau)* | Lu par le panneau et la fiche ; `IconData` et `Color` sont des valeurs, testables sans écran — comme `compactValue` aujourd'hui |
| Barre, deux chiffres, voile | Flame | `lib/game/components/entities/enemy_health_bar.dart` *(nouveau)* | Attachée à la carte, à son échelle ; reçoit les touchers de sa carte (A3) |
| Le plus haut montant d'armure | Flame, état d'affichage de `EnemyCard` | `enemy_card.dart` | A2 |
| La règle du voile | Calcul pur | `lib/game/systems/armor_veil.dart` *(nouveau)* | À côté de `charge_rules.dart`, pur |
| Languettes, repos et déroulé | Flame | `lib/game/components/entities/status_tabs.dart` *(nouveau, remplace `status_indicator.dart`)* | Attachées à la carte ; ennemi et héros ; reçoivent les touchers de leur carte (A8) |
| Ce qu'une entrée de statut ou de charge écrit, et de quel côté ; `statusEmoji` | Calcul pur | `lib/game/systems/status_readout.dart` *(nouveau)* | Lu par les languettes (Flame), la fiche (Flutter) et la vague du Feu ; prend `AppLocalizations` et le catalogue des charges en paramètres |
| L'arbitre du survol des cartes de combat | Calcul pur, appelé par Flame | `lib/game/systems/entity_hover.dart` *(nouveau)* | Sur le modèle de `hand_geometry.dart` |
| La fiche ouverte (quel ennemi, son rectangle) | Flame, `HerosDraftGame` | `heros_draft_game.dart` | A1, A12 : un seul propriétaire, reflété par `GameScreen` |
| Agrandissement, descente, bordure | Flame | `enemy_card.dart`, `layout_system.dart` | A11 |
| Voile d'estompage | Flame | `lib/game/components/visual_effects/inspection_veil.dart` *(nouveau)* | A11 |
| Le `Listener` qui ferme | Flutter (écran) | `lib/ui/screens/game_screen.dart` | A12 |
| Le cadre de la fiche | Flutter (HUD) | `lib/ui/widgets/hud/enemy_sheet_panel.dart` *(nouveau)* | A13 |
| Le contenu de la fiche | Calcul pur | `lib/ui/widgets/hud/enemy_sheet_view.dart` *(nouveau)* | Testable sans écran |
| La place du cadre | Calcul pur | dans `enemy_sheet_view.dart` | A13 |

**Aucun état Riverpod neuf, aucun champ neuf** sur `EnemyInstance`, `EntityStats` ou `CombatState`. `GameConstants`
gagne `priorityEntityHovered` (5), `priorityInspectionVeil` (180), `priorityInspectedEnemy` (190), et le facteur
`inspectionScale` (1,25) ; il perd `badgeHpSize`, `badgeStandardSize` et `badgeCircleSize` (A3).

---

## 4. La logique qui se calcule

### 4.1. `ArmorVeil`

```dart
/// Le plein du voile après qu'un état est passé de [oldArmor] à [newArmor].
static int nextPeak({required int peak, required int oldArmor, required int newArmor});
/// La part de la barre que couvre le voile, entre 0 et 1.
static double fraction({required int armor, required int peak});
```

- `newArmor <= 0` → 0 : le voile disparaît, le plein s'efface (B15).
- `newArmor > oldArmor` → `newArmor` : tout gain remplit le voile, le nouveau montant est son plein (B16), même avant
  que l'armure soit tombée à 0.
- sinon → `max(peak, newArmor)` : un coup qui entame laisse le plein ; le `max` garde l'invariant `peak ≥ armor`
  contre un état d'entrée qui ne l'aurait pas.
- `fraction` = `armor / peak` borné à [0, 1] ; 0 si `peak <= 0`. **Les PV n'entrent pas dans le calcul** (B15).

`EnemyCard` part de `peak = stats.armure` au chargement (0 à l'apparition, `combat_controller.dart:155`), applique
`nextPeak` dans `_applyInstance`, avant `instance = next` (`enemy_card.dart:288-294`), et passe `fraction` à la barre.
L'armure d'un ennemi n'est remise à 0 par aucun tour : seuls les coups l'entament.

Exemples, ceux des maquettes : 6 gagnés → plein, 1 ; un coup en laisse 2 → 1/3 ; 0 → plus de voile ; un boss à 40
→ 1, entamé à 25 → 0,625, à 8 → 0,2 ; 2 restants puis 5 gagnés → 7, plein.

### 4.2. `IntentPips`

```dart
class IntentPip { IconData icon; Color color; String value; bool struck; bool waiting; }
static List<IntentPip> of(EnemyIntent? intent, {required bool skipped, required AppLocalizations l10n});
```

`IntentPips` écrit aussi la pastille d'attente : le panneau et la fiche la dessinent sans rien savoir de plus, et le
test la lit en FR et en EN.

- **Attaque** : l'icône et la couleur du palier (`enemy_intents_panel.dart:68-78`, seuils 6, 12, 20), valeur
  `compactValue`. **Défense** : `Icons.shield`, `#448AFF` (`:79-80`) ; **Buff** : `Icons.trending_up`, `#E040FB`
  (`:81-82`, B31). Les icônes et les couleurs d'aujourd'hui, sans la table d'icônes (A5).
- **Sans intention** : une seule pastille, le sablier `white30` et pour valeur `l10n.waitingIntents` (« En
  attente... »), `waiting` vrai — le panneau l'écrit en italique —, comme aujourd'hui (`enemy_intents_panel.dart:99-102`,
  `:175-184`).
- **Ennemi qui ne fait rien ce tour** (`skippingCharge`, `enemy_instance.dart:21-31`) : chaque pastille garde son
  icône et sa valeur, en `white38`, la valeur barrée (`struck`) — `enemy_intents_panel.dart:108-111` étendu à toutes.
- `of` rend une liste, la forme que B1 remplira ; en `0.6.1`, elle a toujours une pastille, et aucun débordement ne
  se calcule (A5, §2).

### 4.3. `StatusReadout`

Une entrée par statut porté (clé `id` + `sourceId`) et une par ligne de charge (`ChargeRules.linesFor`), rangées
comme aujourd'hui : **à gauche**, les statuts `buff` ; **à droite**, les statuts `debuff` qui ne sont pas des charges,
puis les charges (`enemy_card.dart:230-244`).

```dart
class StatusReadout {
  String key; String emoji;                    // le côté : la liste qui porte l'entrée
  String restValue; ReadoutTone tone;          // buff, debuff, charged
  String title; String? subtitle;              // le déroulé
  int? turnsLeft; String? hint;                // la fiche
}
static ({List<StatusReadout> left, List<StatusReadout> right}) of(
    EntityStats stats, ChargeCatalog charges, AppLocalizations l10n, String locale, {String? counterId});
```

**La source des textes.** La fiche, widget Flutter, passe `AppLocalizations.of(context)` et la locale de son
contexte. Les languettes, en Flame, n'ont plus d'accès aux textes une fois `getTranslation` retiré (A3), et
`HeroCard` n'en a jamais eu : `CombatEntity` lit `lookupAppLocalizations(Locale(activeLocale))`
(`app_localizations.dart:2201`), `activeLocale` passant de `EnemyCard` (`enemy_card.dart:180-186`) à `CombatEntity`
pour servir aussi le héros. **`counterId`** : l'id du compteur du passif actif, `PassiveCounters.idOf(passive)`
(`passive_counters.dart:27`), que le héros passe depuis `RunState.activePassive` (`run_controller.dart:38`) ; nul pour
un ennemi.

| Entrée | `restValue` | `title` | `subtitle` | `turnsLeft` |
|:---|:---|:---|:---|:---|
| Statut bonus | sa valeur | « {nom} +{valeur} » | « {n} tours » si 0 < durée < 99 | durée si < 99 (B34) |
| Statut altération | sa valeur | « {nom} {valeur} » | idem | idem |
| Charge sous le seuil | « {points}/{seuil} » | « {nom} {points}/{seuil} » | — | — |
| Charge `explode` (Feu) | ses points | « {nom} {points} » | — | — |
| Charge `skipAction` en attente (ennemi Gelé) | le nom de l'état (B33) | « {état} » | — | — |
| Charge `weakenDealt` en attente / active (héros gelé) | le nom de l'état (B33) | « {état} » | « −{%} % de dégâts au prochain tour » / « … ce tour » | — |
| Charge `amplifyHits` chargée (Foudre) | ses points, ton `charged` (B32) | « {état} {points} » | « +{bonus} par coup » | — |

- **Le nom d'un statut** : `l10n.statusName(id)` pour les ids qu'il couvre — `lifesteal` et les six statuts de
  reliques y entrent (§6.2) — ; **l'id `counterId`** — le compteur d'un passif, `<passif>_count`, posé sous le nom
  français seul « Compteur » (`passive_counters.dart:45-52`, par `passive_strategies.dart:75`, `:104`), que le
  panneau du héros ne filtre pas (`status_effects_panel.dart:221`, `:166`) — prend la clé neuve `statusPassiveCounter`
  (§6.2) ; sinon le `name` de l'entrée, comme le panneau du héros aujourd'hui (`status_effects_panel.dart:159-167`). Le nom d'une charge et de son état : le catalogue (`charge_data.dart:192`,
  `brokenName`).
- **Le ton** : `buff` vert `#69F0AE`, `debuff` rouge `#FF5252` — charges comprises (B14) —, `charged` jaune
  `yellowAccent` pour la seule Foudre chargée, comme depuis la vague des charges (`status_indicator.dart:151`) : B32
  amende B14 de cette exception.
- **`hint`** : `statusWeaknessHint` et `statusVulnerableHint`, avec les valeurs de `ProportionalStatus`, comme les
  faces de cartes (`card_component.dart:410-420`) ; `null` ailleurs (B34).
- **L'émoji** : `statusEmoji`, qui vit dans ce fichier, gagné de `mana_regen` 💎 et `hp_regen` 💖 (A8, B41).

### 4.4. `EnemySheetView`

```dart
static EnemySheetView of(EnemyInstance enemy, {required ChargeCatalog charges,
    required AppLocalizations l10n, required String locale});
```

Rend, dans l'ordre de la maquette 4 sur 5 : `title` (le nom, en capitales), `level` (`levelLabel`) ; `hp`
(« PV 9/14 »), `armor` (« Armure 4 »), `might` (« Puissance 4 », `effectiveMight`, la valeur du badge d'aujourd'hui,
`enemy_card.dart:207`) ; l'intention : `pips` (`IntentPips.of`), `intentName` (« Attaque Rapide », sans valeur),
`intentSentence` (« Attaquera le héros pour 4 dégâts. », sans le nom de l'ennemi ; gelé : « Gelé : ne fait rien ce
tour » ; sans intention : « Intention pas encore connue. ») ; `bonuses` et `alterations` : les deux côtés de
`StatusReadout`, chaque entrée écrite « {émoji} {title} » et, si `turnsLeft`, « · encore {n} tours », sa `hint`
dessous. Une section vide est absente (B34). L'armure se montre même à 0 (« Armure 0 »), comme la Puissance : la
ligne des chiffres ne change pas de forme.

### 4.5. `pickHoveredEntity`

```dart
static int? pickHoveredEntity({required List<List<Rect>> zones, required int? current,
    required Offset pointer});
```

Chaque entrée de `zones` est la zone d'une carte vivante, en rectangles : pour un ennemi, le rectangle continu de sa
barre au bas de sa carte (y −17 à 140, A3) et ses languettes, au repos ou déroulées ; pour le héros, sa carte et ses
languettes. Le pointeur dans la zone de la courante → la courante ; sinon, la première zone qui contient le pointeur
; sinon `null`. Survoler une languette au repos déroule donc sa carte. `HerosDraftGame` passe les ennemis vivants
puis le héros ; il n'appelle pas l'arbitre tant que la fiche est ouverte (A12). **La zone d'un ennemi est une seule
fonction de `EnemyCard`**, que lisent l'arbitre, `_livingEnemyAt` et `findHoveredEnemy` (A3) ; la fermeture ne la lit
pas (A12).

### 4.6. `SheetPlacement`

```dart
static Offset topLeftFor({required Rect card, required Size screen, double width = 310,
    double gap = 24, double margin = 16});
```

`card` est le rectangle d'A12 : la carte agrandie, sa barre et ses languettes au repos ; l'écart se mesure donc
depuis la languette du côté où le cadre se pose, qu'il ne recouvre pas. À droite si `card.right + gap + width <=
screen.width − margin` ; sinon à gauche si `card.left − gap − width >= margin` ; sinon du côté le plus large, borné à
`[margin, screen.width − margin − width]`. Le haut : le haut de la barre de la carte agrandie (`card.top`), borné à
`margin`.

### 4.7. L'ouverture et la fermeture, dans `HerosDraftGame`

```dart
EnemyCard? inspectedEnemy;
void inspectEnemy(EnemyCard enemy);     // ouvre ou remplace
void closeInspection();                 // sans effet si rien n'est ouvert
void closeInspectionIfStale(CombatState state);
void closeInspectionUnlessOn(int pointer);   // le Listener de GameScreen, après Flame (A12)
```

`_handlePlayerTargeting` suit A10 ; il reçoit aussi le `pointerId` du `TapDownEvent` — la carte, sa barre et ses
languettes le passent avec elles-mêmes à `onTapEnemy` — et le retient quand il ouvre ou garde une fiche ;
`closeInspectionUnlessOn` le lit (A12), puis l'oublie. `closeInspection` est appelé par `setFocusedCard(card non nul)`, le mutateur de
`awaitingEnemyTarget` à `true`, `onTapDown` du décor et `executeTurn` ; `closeInspectionIfStale`, appelé par
`StateSyncSystem._applyCombatState` après l'application, ferme quand l'ennemi ouvert n'est plus dans `state.enemies`,
quand `state.turnPhase` n'est plus `player` ou quand `state.isCombatEnded`. Chaque changement appelle
`onInspectionChanged`, un rappel de plus au constructeur ; `repositionEnemies` le rappelle avec le nouveau rectangle
quand une fiche reste ouverte sur une carte replacée (A12). `GameScreen` diffère tout reflet de ce rappel à la frame
suivante ; aucune décision de Flame ne lit ce reflet.

---

## 5. L'interface

### 5.1. Le panneau des intentions (Flutter)

Le cadre ne change pas : 250 de large, marge 16, fond `#1E1E2C` à 240, liseré `amberAccent` à 100, titre « 👁
INTENTIONS ENNEMIES » ambre (`enemy_intents_panel.dart:272-321`). Chaque ligne, séparée de la suivante par le trait
`white10` d'aujourd'hui :

| Colonne | Largeur | Contenu |
|:---|:---|:---|
| Niveau | 40 | `levelLabel` (« Niv. 1 »), 11, `white38` ; réduit, jamais tronqué |
| Nom | le reste (59 à 67, A6) | le nom, 12 gras, blanc — `amberAccent` pour un boss, comme aujourd'hui — ; une ligne, points de suspension |
| Pastilles | 96 | les pastilles d'`IntentPips`, alignées à gauche, 4 entre deux ; une pastille plus large que la colonne — « En attente... », 104 à 110 en français — est réduite (`FittedBox`), jamais tronquée, comme la colonne du niveau (B9 : seul le nom se tronque) |

Une pastille : marge 6 × 2, rayon 6, fond de sa couleur à 20, liseré de sa couleur à 60 d'épaisseur 1, icône 14, 4,
valeur 12 gras de sa couleur — le style d'aujourd'hui (`enemy_intents_panel.dart:162-198`) ; les couleurs aussi :
paliers de l'attaque, bouclier bleu de la Défense, flèche montante violette de la Puissance (A5, B31). L'infobulle enveloppe la
rangée (A7). L'ennemi qui ne fait rien ce tour : pastilles `white38`, valeurs barrées, infobulle bordée
`lightBlueAccent`, sa phrase « Gelé : ne fait rien ce tour » en `lightBlueAccent` gras.

### 5.2. La barre de PV et le voile (Flame)

A4 pour la géométrie, §4.1 pour le voile. Le voile garde le dessin d'aujourd'hui — dégradé `blueAccent` 45 % →
`lightBlueAccent` 65 %, liseré `cyanAccent` (`linear_progress_bar.dart:58-100`) —, posé sur toute la largeur de la
barre et non plus sur la seule part des PV. Sous lui, les PV gardent leur dégradé rouge. Rien d'autre au-dessus de la
carte : ni Puissance, ni second badge. Un boss : la même barre, à l'échelle de sa carte. Pas d'appui long.

### 5.3. Les languettes (Flame)

En unités de la carte — 100 × 140 pour un ennemi, 120 × 160 pour le héros, à `scaleFactor` × 1,3
(`hero_card.dart:27-31`) : ses languettes sont un peu plus petites à l'écran que celles d'un ennemi.

| | Repos | Déroulée (au survol de la carte) |
|:---|:---|:---|
| Place | Collée au bord de la carte, 1 unité dessus ; son haut à 11 sous le haut de la carte | Le même bord reste collé à la carte ; elle s'étend vers l'extérieur (la gauche à gauche, la droite à droite) et passe sur la carte voisine. **Si elle sortait de l'écran**, elle se déroule vers l'intérieur, par-dessus sa propre carte, son bord extérieur collé au bord extérieur de la carte (B39) — à cinq ennemis en 1280 × 800, le bord droit de l'ennemi le plus à droite est vers 1184 px (`layout_system.dart:111-135`), et sa languette droite déroulée irait jusqu'à 172 px plus loin |
| Cadre | 30 de large, fond `#14141E`, liseré `#766734` de 1, rayon 4, marge 3 | Largeur de son contenu, entre 30 et 120 (au-delà, le texte se coupe par points de suspension) ; marges 8 × 4 |
| Une entrée | L'émoji (14) et, dessous, `restValue` gras 10, de son ton, réduit s'il dépasse la largeur (« Frozen ») ; une entrée toutes les 31, empilées de haut en bas | L'émoji (14) ; 6 plus loin, `title` gras 9 `#F7F7FA` et, dessous, `subtitle` gras 9 `#FFD740` s'il y en a un ; une entrée toutes les 22, 30 avec un `subtitle` |
| Vide | Pas de languette | — |
| Ordre dans la carte | Enfant de la carte à la priorité 6, au-dessus de la gangue (4, `frost_shell.dart:19`) et du halo (5, `charge_halo.dart:14`) que `refreshChargeVisuals` ajoute à la carte (`combat_entity.dart:247`, `:263`) | Idem : déroulée vers l'intérieur (B39), elle passe sur la gangue et le halo de sa propre carte |

À cinq ennemis à 1280 × 800, une languette au repos mesure 43 px ; deux qui se font face en prennent 86 des 93 qui
séparent deux cartes (maquette 5 sur 5). Les deux languettes de la carte survolée se déroulent ensemble, en 0,1 s.
La réconciliation par clé d'aujourd'hui (`status_indicator.dart:63-101`) reste : une entrée qui ne change que de
valeur se met à jour en place.

### 5.4. La fiche de l'ennemi (Flame et Flutter)

**Ouverture** (A10) : au tour du joueur, sans carte focalisée ni signature en attente, toucher un ennemi vivant.
**Fermeture** (A12) : tout appui que Flame ne reçoit pas sur elle — sa carte, sa barre, ses languettes —, HUD compris ; une carte focalisée ou saisie ; une signature armée ; la fin du
tour ; l'ennemi qui quitte le combat ; le combat fini. Toucher un autre ennemi ouvre la sienne. Toucher la carte
ouverte ne fait rien.

**La scène** (Flame, A11) : la carte grandit de 1,25 et descend pour garder le haut de sa barre ; bordure ambre de 4 ;
le reste de la scène sous un voile noir à 55 % ; 0,15 s.

**Le cadre** (Flutter, A13), 310 de large, à 24 de la languette au repos du côté où il se pose (§4.6), son haut au
haut de la barre agrandie :

| Élément | Style |
|:---|:---|
| Cadre | fond `#1E1E2C` à 245, liseré `amberAccent` à 100 de 1,5, rayon 12, marges 15 × 13, 5 entre deux lignes, ombre du panneau des intentions |
| Titre | le nom en capitales, 14 gras `#FFD740`, espacement 0,5 ; 8 plus loin, « Niv. 1 » 12 `#7C7C8A` |
| Trait | `white12` |
| Chiffres | « PV 9/14 » 12 gras blanc ; 18 plus loin, le bouclier `#2196F3` de 12 et « Armure 4 » 12 gras `#00E5FF` ; 18 plus loin, « ⚡ Puissance 4 » 12 gras `#FF5252` |
| Trait | `white12` |
| « INTENTION » | 12 gras `#8E8E9C`, espacement 1 |
| Intention | les pastilles du panneau — violette pour la Puissance (B31) — ; 8 plus loin, le nom de l'intention, 12 gras blanc ; dessous, sa phrase, 12 `#C9C9D6` |
| « BONUS » | comme « INTENTION » ; chaque entrée « {émoji} {title} · encore {n} tours » 12 gras `#69F0AE`, sa `hint` dessous 12 `#C9C9D6` |
| « ALTÉRATIONS » | idem, entrées en `#FF8A80` |

Le cadre se reconstruit avec l'état : un ennemi dont les chiffres changent pendant que la fiche est ouverte — une
carte jouée sur lui, qui frappe après l'ouverture — se relit tel quel.

### 5.5. Ce qui disparaît

Le badge au-dessus de la carte (⚡ Puissance, 🛡 armure, la barre de 66) et son appui long ; la colonne des PV du
panneau ; la valeur à droite de l'icône et la durée sous l'icône de l'indicateur des ennemis.

---

## 6. Textes joueur

### 6.1. La donnée

Aucune. Aucun fichier de `assets/data/` ne change ; `effect_icons.json` non plus (18 sortes).

### 6.2. Clés ARB (`app_fr.arb`, `app_en.arb`)

Métadonnées `@` dans `app_en.arb` ; `level`, `count`, `value`, `points`, `threshold`, `bonus`, `percent`, `current`,
`max` de type `int`, `name` et `state` de type `String`. Après la retouche : `flutter gen-l10n`. Le niveau lit la clé
existante `levelLabel` (A6).

| Clé | FR | EN |
|:---|:---|:---|
| `intentNameDevastatingAttack` | `Attaque Dévastatrice` | `Devastating Attack` |
| `intentNameHeavyAttack` | `Attaque Lourde` | `Heavy Attack` |
| `intentNameAttack` | `Attaque` | `Attack` |
| `intentNameQuickAttack` | `Attaque Rapide` | `Quick Attack` |
| `intentNameDefend` | `Défense` | `Defend` |
| `intentNameBuff` | `Buff Puissance` | `Buff Might` |
| `sheetIntentAttack` | `{value, plural, =1{Attaquera le héros pour 1 dégât.} other{Attaquera le héros pour {value} dégâts.}}` | `Will attack the hero for {value} damage.` |
| `sheetIntentDefend` | `Gagnera {value} d'Armure.` | `Will gain {value} Armor.` |
| `sheetIntentBuff` | `Gagnera {value} de Puissance.` | `Will gain {value} Might.` |
| `sheetIntentWaiting` | `Intention pas encore connue.` | `Intent not known yet.` |
| `sheetHp` | `PV {current}/{max}` | `HP {current}/{max}` |
| `sheetArmor` | `Armure {value}` | `Armor {value}` |
| `sheetMight` | `Puissance {value}` | `Might {value}` |
| `sheetSectionIntent` | `INTENTION` | `INTENT` |
| `sheetSectionBonuses` | `BONUS` | `BUFFS` |
| `sheetSectionAlterations` | `ALTÉRATIONS` | `DEBUFFS` |
| `sheetTurnsLeft` | `{count, plural, =1{encore 1 tour} other{encore {count} tours}}` | `{count, plural, =1{1 turn left} other{{count} turns left}}` |
| `tabBuff` | `{name} +{value}` | `{name} +{value}` |
| `tabDebuff` | `{name} {value}` | `{name} {value}` |
| `tabTurns` | `{count, plural, =1{1 tour} other{{count} tours}}` | `{count, plural, =1{1 turn} other{{count} turns}}` |
| `tabChargePoints` | `{name} {points}/{threshold}` | `{name} {points}/{threshold}` |
| `tabChargeOpen` | `{name} {points}` | `{name} {points}` |
| `tabChargeBonus` | `+{bonus} par coup` | `+{bonus} per hit` |
| `tabChargeWeakenNext` | `−{percent} % de dégâts au prochain tour` | `−{percent}% damage next turn` |
| `tabChargeWeakenNow` | `−{percent} % de dégâts ce tour` | `−{percent}% damage this turn` |
| `statusPassiveCounter` | `Compteur` | `Counter` |
| `statusName` *(étendue)* | `… lifesteal{Vol de Vie} crit_chance{Critique (Relique)} mastery{Maîtrise (Relique)} kunai_charge{Charge Kunaï} shuriken_charge{Charge Shuriken} pen_nib_charge{Charge Plume} incense_charge{Charge Encensoir} …` | `… lifesteal{Lifesteal} crit_chance{Critical (Relic)} mastery{Mastery (Relic)} kunai_charge{Kunai Charge} shuriken_charge{Shuriken Charge} pen_nib_charge{Pen Nib Charge} incense_charge{Incense Burner Charge} …` |

Les six statuts de reliques sont ceux que `player_stats_manager.dart` pose sur le héros avec un nom français seul
(`:299-300`, `:344-345`, `:354-355`, `:389-390`, `:424-425`, `:450-451`) : la languette du héros les nommerait en
français à un joueur anglophone. Les noms français reprennent ces `name` à l'identique ; les noms anglais, ceux des
reliques (`assets/data/relics/kunai.json`, `shuriken.json`, `pen_nib.json`, `incense_burner.json`).

L'infobulle du panneau garde ses clés (`intentQuickAttack` et ses sœurs, `intentAttackExplanation` et ses sœurs,
`intentSkipped`, `intentWaitingExplanation`, `app_fr.arb:132-137`, `:260-264`).

**Clés retirées**, sans autre lecteur que `stat_badge.dart` ou le badge d'`enemy_card.dart` (re-mesuré par `grep` le
21/11) : `hpAbbreviation`, `enemyStatsTitle`, `enemyStatsDesc`, `tooltipHpDesc`, `tooltipArmorTitle`,
`tooltipArmorDesc`, `tooltipAttackTitle`, `tooltipAttackDesc`, `tooltipManaDesc`. `tooltipHpTitle` et
`tooltipManaTitle` restent : `stats_dialog.dart` les lit.

### 6.3. Le tutoriel

Une phrase s'ajoute à la fin du texte de l'étape « Les Intentions Ennemies » (`tutorial_data.dart:249-277`)
(B37) :

- FR : « **Touchez un ennemi** pour ouvrir sa fiche : ses PV, son Armure, sa Puissance, son intention, ses bonus et
  ses altérations. À la souris, survoler sa carte déroule ses deux languettes. »
- EN : « **Tap an enemy** to open its sheet: its HP, Armor, Might, intent, buffs and debuffs. With a mouse, hovering
  its card unfolds its two side tabs. »

Le reste de la prose reste vrai : le panneau en bas à droite, les quatre paliers, le sablier, le Gelé qui ne fait
rien.

---

## 7. Le tutoriel

| Étape | Ce qui change |
|:---|:---|
| 6 — Vue d'ensemble (`tutorial_combat_overview_widget.dart`) | **La maquette de l'ennemi** (`:386-479`) perd sa rangée « ⚡ 5 · 🛡 0 · barre · 28/28 » (`:391-443`) : une barre à la largeur de la carte, « 28/28 » dedans, sans Puissance. **La maquette du panneau** (`:307-363`) perd « Gobelin (Niv. 1) » et « ⚡ Attaque Rapide : 5 » : une ligne « Niv. 1 · Gobelin · [⚡ 5] ». Une maquette du tutoriel suit l'écran réel ([`_rules/08-00`](../../../.obsidian_vault/_rules/08-00-systeme-de-tutoriel-autonome.md), étape 6). La prose ne change pas |
| 9 — Armure & Dégâts (`tutorial_armor_widget.dart`) | Rien : elle montre l'armure du héros, dont la jauge garde sa forme |
| 11 — Intentions (`tutorial_enemy_intents_widget.dart`) | Le panneau réel (`:152`) prend de lui-même ses trois colonnes ; ses quatre ennemis d'entraînement y lisent « Niv. 1 » et leur pastille ; la légende des paliers reste. Une phrase de prose (§6.3, B37) |
| 10 — Effets Élémentaires | Rien : sa galerie montre la règle des charges, pas l'indicateur |

Le tutoriel n'a pas de combat Flame : ni languette, ni barre, ni fiche à démontrer.

---

## 8. La sauvegarde

**Rien de neuf n'est sauvegardé ; aucun `schemaVersion` ne change.** Le plus haut montant d'armure est un état
d'affichage de `EnemyCard`, la fiche ouverte un état de `HerosDraftGame` ; ni l'un ni l'autre n'entre dans un modèle.
La sauvegarde n'est jamais écrite en combat (`CLAUDE.md`, `SaveService`) ; avant la `1.0.0`, elle ne se transfère pas
d'une version à l'autre : aucune compatibilité à prévoir.

---

## 9. Tests

**Sous ADR-113** : calculs, données, contrôleurs ; aucun test d'écran. Base : 1866 (porte d'entrée, journal du
cadrage §4.1), re-mesurée au début du plan.

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| **Le voile** | `test/unit/armor_veil_test.dart` *(nouveau)* | Les exemples de §4.1 : 6 gagnés → 1 ; 2 sur 6 → 1/3 ; 0 → 0 et plein effacé ; boss 40 → 25 → 0,625 → 8 → 0,2 ; 2 restants puis +5 → plein 7, 1 (B16) ; **la part ne dépend pas des PV** : 6 sur un ennemi de 14 PV et 40 sur un boss de 250 donnent 1 (B15) ; `peak` 0 → 0 |
| **Les pastilles** | `test/unit/intent_pips_test.dart` *(nouveau)* | Une attaque par palier : icône, couleur, valeur (5, 8, 15, 22, et les seuils 6, 12, 20) ; Défense → `Icons.shield` `#448AFF`, Buff → `Icons.trending_up` `#E040FB` (B31) ; sans intention → le sablier ; gelé → chaque pastille `struck`, `white38` ; **`of` ne rend jamais plus d'une pastille en `0.6.1`** |
| Le panneau | `test/unit/enemy_intents_panel_texts_test.dart` | Inchangé pour `compactValue`, `explanation` et `intentsPanelMaxHeight` ; le niveau (`levelLabel`, existante) est lu par le test de la fiche |
| **Les entrées de statut** | `test/unit/status_readout_test.dart` *(nouveau)* | Le partage gauche / droite sur un état mêlé (Puissance, Poison, Faiblesse, Gel 2/3, Feu 5) ; **deux Puissances de sources différentes font deux entrées** ; chaque ligne du tableau de §4.3, FR et EN (« Puissance +2 » / « Might +2 », « Poison 2 », « Gel 2/3 » / « Freeze 2/3 », « Gelé » / « Frozen », « Chargé 3 », « +6 par coup ») ; « 2 tours » / « 2 turns », « 1 tour » ; **une durée de 99 → ni `subtitle` ni `turnsLeft`** ; une charge n'a jamais de durée ; les `hint` de Faiblesse et Vulnérable, aucune ailleurs ; les tons — **une Foudre chargée en `charged`**, toute autre charge en `debuff` (B32) ; un statut d'id `counterId` (`mage_mark_count`) nommé « Compteur » / « Counter » ; `statusEmoji('mana_regen')` 💎, `('hp_regen')` 💖 |
| **La fiche** | `test/unit/enemy_sheet_view_test.dart` *(nouveau)* | Sur un ennemi fixture à 9/14 PV, 4 d'armure, Puissance 4, attaque de 4, Puissance +2 et Poison 2 pendant 3 tours : titre en capitales, « Niv. 1 », « PV 9/14 », « Armure 4 », « Puissance 4 » (`effectiveMight`), « Attaque Rapide », « Attaquera le héros pour 4 dégâts. », un bonus, une altération « … · encore 3 tours » — FR et EN ; gelé : « Gelé : ne fait rien ce tour » ; sans intention ; **sans bonus, pas de section bonus** ; « Armure 0 » ; 1 dégât au singulier |
| **La place du cadre** | même fichier | Droite si elle tient ; gauche sinon ; bornée quand aucune ne tient ; haut borné à la marge |
| **Le survol** | `test/unit/entity_hover_test.dart` *(nouveau)* | Le pointeur dans une carte → elle ; dans les languettes déroulées de la courante, hors de sa carte → la courante ; ailleurs → `null` ; deux cartes qui se recouvrent → la courante l'emporte |
| **L'ouverture et la fermeture** | `test/unit/heros_draft_game_targeting_test.dart` | « Sans cible attendue, toucher un ennemi ne rapporte rien » (`:112-116`) **et ouvre sa fiche** (`inspectedEnemy`, un rappel) ; un second ennemi la remplace ; la même la garde, sans second rappel ; une carte focalisée joue sa carte, n'ouvre rien ; une signature en attente reçoit l'ennemi, n'ouvre rien ; hors du tour du joueur, un ennemi mort ou mourant : rien ; **focaliser une carte, armer une signature, toucher le décor, `executeTurn` ferment** et le rappellent ; `closeInspection` sans fiche ne rappelle rien |
| La fermeture par l'état | `test/unit/heros_draft_game_targeting_test.dart` | `closeInspectionIfStale` sur un état sans l'ennemi ouvert, en phase ennemie, fini : la fiche se ferme et le rappelle ; sur un état où il est vivant, au tour du joueur : elle reste |
| Les textes | `test/unit/card_rule_texts_test.dart:77-91` | Inchangé ; `statusName('lifesteal')` FR « Vol de Vie », EN « Lifesteal » ; pour chacun des six statuts de reliques, le nom français égale le `name` que `player_stats_manager.dart` lui donne, l'anglais n'est pas l'id |

Les tests qui lisaient `StatBadge` ou `StatusIndicator` : aucun (`grep` du 21/11).

### 9.1. Les tests manuels

Le fichier de tests manuels de la vague (`bestiaire-vague-1`) les reprend. L'onglet Combat du menu de debug règle les
PV d'un ennemi et pose ses charges ; l'onglet Run change d'acte (plusieurs ennemis dès l'acte 2).

| # | Écran | Ce que fait le propriétaire | Ce qu'il doit voir |
|:---:|:---|:---|:---|
| M1 | Panneau | Un combat à trois ennemis ou plus, FR puis EN | Trois colonnes alignées : « Niv. N » / « Lvl. N », le nom, la pastille ; plus de PV ; un nom long se tronque, rien d'autre |
| M2 | Panneau | Survole la pastille d'une attaque, d'une Défense, d'un Buff ; au doigt, appui long | Une infobulle par ligne, titre « Attaque Rapide : 4 » et sa phrase ; la pastille survolée cerclée ; l'Armure en bouclier bleu, la Puissance en flèche montante violette (B31) |
| M3 | Panneau | Un ennemi Gelé (debug : 3 Gel sur un ennemi qui n'est pas un boss, encore jamais gelé — `freeze.json` : seuil 3, boss 6, croissance 1) | Sa pastille grisée et barrée ; l'infobulle « Gelé : ne fait rien ce tour » |
| M4 | Barre | Regarde un ennemi neuf, puis blessé | La barre à la largeur de la carte, « 14/14 » puis « 9/14 » en blanc ; plus de ⚡ ni de 🛡 au-dessus de la carte |
| M5 | Voile | Un ennemi qui se défend (Orc ou debug), puis frappé deux fois, puis à 0 | Voile plein et « 🛡 6 » cyan ; il recule à chaque coup ; il disparaît à 0 |
| M6 | Voile | Un ennemi entamé qui regagne de l'armure | Le voile se remplit de nouveau, le nouveau montant pour plein (B16) |
| M7 | Voile | Un boss qui gagne 40 d'armure | Le voile couvre toute sa barre, comme 6 sur un petit ennemi |
| M8 | Languettes | Souris : survole un ennemi à deux bonus et deux altérations, dont une charge | Au repos l'icône et la valeur ; au survol, les deux languettes se déroulent : « Puissance +2 », « Poison 2 / 3 tours », « Gel 2/3 » ; la languette passe sur la carte voisine ; glisser sur la languette ouverte la garde ouverte |
| M9 | Languettes | Cinq ennemis à 1280 × 800, languettes qui se font face | Elles tiennent entre deux cartes sans se toucher |
| M10 | Languettes du héros | Joue *Méditation*, *Prière*, une carte de Puissance ; un ennemi qui pose une altération (debug) | Les languettes du héros, mêmes règles ; 💎, 💖 ; deux Puissances de sources différentes, deux entrées ; le panneau des effets du héros inchangé |
| M11 | Languettes | Au doigt, appuie et glisse une carte au-dessus des ennemis | Rien ne se déroule |
| M12 | Fiche | Sans carte ni signature : touche un ennemi | La carte grandit, bordée d'or, le reste estompé, le HUD net ; le cadre à côté : nom, niveau, PV, Armure, Puissance, intention, bonus, altérations, FR puis EN |
| M13 | Fiche | Fiche ouverte : touche le décor, la main, un bouton du HUD, le cadre lui-même, la carte ouverte, un autre ennemi | Tout la ferme sauf la carte ouverte ; un autre ennemi ouvre la sienne ; une carte de la main touchée se lève |
| M14 | Fiche | Carte focalisée, puis touche un ennemi ; signature armée, puis touche un ennemi | La carte se joue, la signature se joue : aucune fiche |
| M15 | Fiche | Le dernier ennemi à droite, puis le premier à gauche | Le cadre à gauche de la carte, puis à droite ; jamais hors de l'écran ; la barre agrandie garde le haut qu'elle a au repos (B40) — à cinq ennemis en 1280 × 800, celle de l'ennemi de droite passe déjà sous les boutons Son et Deck, fiche ouverte ou non (`combat_top_bar.dart:36-75`) : la fiche ne la couvre pas davantage |
| M16 | Fiche | Fiche ouverte, puis Fin de Tour | La fiche se ferme ; pendant la phase ennemie, toucher un ennemi ne fait rien (B35) |
| M17 | Fiche | Joue une attaque sur un ennemi, puis touche-le avant l'impact | La fiche s'ouvre ; à l'impact, la carte agrandie se secoue et revient agrandie, pas à sa taille d'avant ; le cadre suit les chiffres |
| M18 | Tutoriel | Étapes 6 et 11, FR et EN | La maquette de l'ennemi sans Puissance, la barre à la largeur de la carte ; le panneau en trois colonnes ; la phrase sur la fiche (B37) |
| M19 | S9 | Gagne un combat par le Poison ou le Feu, pendant la phase ennemie | Aucun tour ne se rouvre |
| M20 | Languettes | Cinq ennemis à 1280 × 800 : survole l'ennemi le plus à droite, puis le plus à gauche, porteurs d'une altération et d'un bonus | Leurs languettes extérieures se déroulent vers l'intérieur, sur leur propre carte, sans sortir de l'écran (B39) |

---

## 10. Le découpage

**Un seul plan, six tâches, plus une septième : la vérification finale.** Le panneau et la barre ne dépendent que de la
première ; les languettes dépendent aussi de la barre (même fichier de test, même `onLoad`) ; l'ordre est
1 → 2 → 3 → 4 → 5 → 6 → 7. La fiche vient après
elles, parce qu'elle agrandit la barre et suspend le survol qu'elles posent.

| # | Tâche | Dépend de | Contenu |
|:---:|:---|:---|:---|
| 1 | Les règles pures et les textes | — | Les constantes de la géométrie de la barre (A4), posées une seule fois et lues par les tâches 3 et 4 ; `ArmorVeil`, `IntentPips`, `StatusReadout` (et `statusEmoji`), `EnemySheetView` et `SheetPlacement`, `pickHoveredEntity` ; les clés ARB, neuves, étendue et retirées — ces dernières au moment où leur lecteur part, tâche 3 ; leurs tests |
| 2 | Le panneau | 1 | Trois colonnes, pastilles, infobulle sur la rangée, liseré au survol, gelé, `levelLabel` |
| 3 | La barre | 1 | `EnemyHealthBar`, qui renvoie ses touchers à sa carte ; le plein du voile sur `EnemyCard` ; retrait de `StatBadge`, `CircleProgressComponent`, des trois tailles de badge, d'`EnemyCard.getTranslation`, des clés sans lecteur ; `onShowTooltip` et `_tooltipCardType` en `CardType` |
| 4 | Les languettes | 1, 3 | `StatusTabs` sur `EnemyCard` (retrait de `StatusIndicator`) et `HeroCard`, qui renvoient leurs touchers à leur carte et se déroulent vers l'intérieur au bord de l'écran ; l'arbitre du survol dans `onPointerMove`, la priorité de la carte survolée ; la zone d'un ennemi (carte, barre à la géométrie d'A4, languettes), lue par `_livingEnemyAt`, l'arbitre du survol et `findHoveredEnemy` (`card_interaction_handler.dart:160-165`) — la géométrie de la barre vient des constantes de la tâche 1 ; la tâche 4 suit la 3, qui crée le fichier de test des renvois et retouche avant elle `EnemyCard.onLoad` |
| 5 | **La fiche** — *tâche à risque* | 1, 3, 4 | Le geste dans `_handlePlayerTargeting` ; `inspectEnemy` et `closeInspection` ; l'agrandissement par `baseScale` et la descente, gardée par `repositionEnemies`, qui réémet le rectangle ; la bordure `isInspected` ; le voile d'estompage et les priorités ; `onInspectionChanged`, reflété en différé ; le `Listener` de `GameScreen` et `closeInspectionUnlessOn` ; `EnemySheetPanel` ; les fermetures par garde et par l'état ; la suspension du survol ; leurs tests de contrôleur |
| 6 | Le tutoriel | 2, 3 | Les deux maquettes de l'étape 6 ; la phrase de l'étape 11 |

**La tâche à risque est la 5**, comme la fiche le dit : le geste de toucher (l'ordre des priorités entre carte
focalisée, signature, fiche ; le `Listener` et le tap Flame sur le même appui), la mise au premier plan (une échelle
que les secousses ne doivent pas défaire, une position que la remise en place ne doit pas écraser) et l'estompage
(une priorité qui passe sur la main sans passer sur la carte ouverte).

---

## 11. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| **ADR « l'interface des ennemis »** — B9 à B16 et la part de B6 livrée ; le plein du voile sur la carte (A2) ; la fiche, état de `HerosDraftGame` reflété par l'écran, fermée par tout appui que Flame ne reçoit pas sur elle — sa carte, sa barre, ses languettes — (A1, A12) ; un seul composant de languettes pour l'ennemi et le héros, une entrée par statut porté (A8) ; les réponses du propriétaire B31 à B41 (§1.2), dont B32, qui amende B14, et B31, exception à « la couleur de son statut » de B6. **Amende [ADR-119](../../../.obsidian_vault/_adr/ADR-119-les-corrections-de-fin-de-vague-8.md)** (point 3 : le panneau perd les PV et passe en trois colonnes ; l'infobulle passe de la pastille à la rangée) ; **complète [ADR-104](../../../.obsidian_vault/_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md)** (l'affichage des ennemis ne suppose plus une entrée par `id`) et **[ADR-117](../../../.obsidian_vault/_adr/ADR-117-les-charges-elementaires.md)** (les états des charges se lisent au repos et au déroulé des languettes) ; le texte d'**ADR-013** nomme `StatBadge` et `HealthBar` | `memory-bank-sync` |
| Fiches `_patterns/05-3` (les lignes `EnemyCard`, `HeroCard`, `StatBadge`, `HealthBar`), `05-3-1` (`CombatEntity` et l'échelle de base agrandie), `05-4` (les trois priorités neuves ; `priorityHero` et `priorityEnemy` qui n'existent pas), `04-00` (le rappel `onInspectionChanged`, l'ordre de `_handlePlayerTargeting`, §4.4 qui nomme `HealthBar` et `StatBadge`), `01-00` (le schéma nomme `StatBadge / HealthBar`), `05-13` (les émojis des languettes ; les pastilles des intentions ne lisent pas la table, B31), `09-00` (la maquette de l'étape 6) ; `_rules/04-00` (l'avertissement « une entrée par `id` » ; la ligne « États affichés » des charges), `03-2` (l'armure d'un ennemi et son voile), `08-00` (étapes 6 et 11) — un minimum, que le diff complétera | `memory-bank-sync` |
| `docs/ROADMAP.md`, la ligne P-05 | `memory-bank-sync`, à la fin de la vague — hors de cette spec |
| La note de version | Celle de la vague, écrite à la fin par `patch-notes-writer` — hors de cette spec |

**Ce que le joueur voit en `0.6.1`** : le panneau des intentions en trois colonnes — le niveau, le nom, la pastille —
sans les PV, avec une infobulle qui dit toute l'intention ; au-dessus de chaque ennemi, une seule barre de PV à la
largeur de sa carte, ses PV en blanc, son armure en bleu à côté, et un voile bleu qui est la jauge de son armure ; en
touchant un ennemi, sa fiche, sa carte agrandie et le plateau estompé ; de part et d'autre des cartes des ennemis et
du héros, les languettes des bonus et des altérations, qui se déroulent au survol de la souris ; et un combat gagné
pendant la phase ennemie qui ne rouvre plus de tour. **À ne pas dire** : un changement de règle — aucun ennemi ne
fait autre chose qu'en `0.6.0`.

**Ce que le vérificateur contrôle** :

- aucune règle de combat ne change : `git diff c2e2dacb -- lib/game/controllers lib/game/services assets/data
  ':!assets/data/patch_notes.json'` ne rend rien — la base de la branche, et non `main`, qui n'a pas la correction S9 ;
  la note de version de la vague est seule à toucher `assets/data` ;
- aucun modèle ne change : `git diff c2e2dacb -- lib/models` ne rend rien ;
- plus aucun lecteur des pièces retirées : `git grep -nw -e StatBadge -e StatusIndicator -e CircleProgressComponent -e enemyStatsDesc -e hpAbbreviation -e badgeHpSize -- lib test`
  ne rend rien — mots entiers : `_buildStatBadge` (`class_selection_screen.dart:615`, `:763`) n'est pas visé ;
- aucun test d'écran neuf (ADR-113) : `git diff c2e2dacb -- test | grep -c '^+.*testWidgets(' || true` affiche `0` (`grep -c` sort en code 1 quand
  il ne trouve rien) ;
- `dart analyze` propre ; `flutter test` vert ; `dart run tool/sync_assets.dart --check` passe (aucun dossier neuf).

---

## Pour le Review Focus du plan

Reporté des tours de vérification de la spec, à traiter par le plan :

- `heros_draft_game_targeting_test.dart` touche des `EnemyCard` jamais montées : `inspectEnemy` et `closeInspection`
  séparent le changement d'état des effets visuels (`baseScale` lit `game.scaleFactor`) ; le nouveau rappel
  obligatoire se bouchonne dans `flame_image_prefix_test.dart:23` et `heros_draft_game_targeting_test.dart:70` ;
- `closeInspectionIfStale`, appelé dans `_applyCombatState`, peut s'exécuter pendant le `currentGame.update(0)` du
  `LayoutBuilder` de `GameWidget` (`game_widget.dart:416`) : différer le `setState` comme `onEnemiesSpawned`
  (`game_screen.dart:394-401`) ;
- le survol des cartes de combat n'est relu qu'au mouvement : si le plateau change sous un pointeur immobile, il faut
  l'équivalent du `refreshHover` de `layoutHand` (`layout_system.dart:100-101`) ;
- tests manuels à ajouter : la fiche d'un ennemi gelé ; le survol de l'ennemi du bord à cinq ennemis ; un
  redimensionnement ou un replacement fiche ouverte ; un toucher de la barre avec une carte focalisée ; la souris sur
  la main fiche ouverte ; la fiche d'un boss ;
- un test de contrôleur pour la réémission : fiche ouverte, `repositionEnemies` rappelle `onInspectionChanged` avec le
  nouveau rectangle ; sans fiche, aucun rappel ; si l'ennemi ouvert est parti, aucun rappel ;
- un test pour `isInspected` : appliquer un état dont `selectedEnemyId` change, ou appeler `highlightEnemy`, fiche
  ouverte, laisse `isInspected` intact ; `closeInspection` le remet à faux sans toucher `isSelected` ;
- le renvoi des touchers : `EnemyHealthBar.onTapDown` et `StatusTabs.onTapDown` appellent `onTapEnemy`, ou
  `HeroCard.onTapDown` pour le héros ;
- le déroulé vers l'intérieur (B39), calculé comme une fonction pure de la carte, de la largeur déroulée et de la
  largeur de l'écran : bord droit, bord gauche, héros au centre jamais retourné ;
- `statusPassiveCounter` en FR et EN ;
- un test manuel : toucher la languette au repos d'un ennemi, sans fiche, puis avec sa propre fiche ouverte, puis avec
  la fiche d'un autre ennemi ;
- `entity_hover_test` : un pointeur sur une languette au repos désigne sa carte ; un pointeur dans l'ancienne bande
  entre la barre et la carte (y −4 à 0) désigne l'ennemi ;
- `heros_draft_game_targeting_test`, la retenue du pointeur : ouvrir avec le pointeur `p`, puis la fermeture appelée
  avec `p` garde la fiche ; appelée avec `p'` elle la ferme ; un second appel avec `p` la ferme aussi, le pointeur
  ayant été oublié ; garder la même fiche retient aussi le pointeur ; les chemins carte focalisée et signature ne
  retiennent rien ;
- `status_readout_test` : une Foudre en `brokenPending` et en `brokenActive` donne le ton `charged`, une Foudre en
  `none` donne `debuff` (la règle `broken` de `status_indicator.dart:138-140`) ;
- `_visuals` passe dans `IntentPips` sans rester en double dans le panneau ;
- test manuel : à cinq ennemis, fiche ouverte sur l'ennemi de droite, toucher Son puis Deck à hauteur de sa barre — la
  fiche doit se fermer ;
- `intent_pips_test` : sans intention, la valeur « En attente... » / « Waiting... » et `waiting` vrai ;
- tests manuels : toucher la barre, puis le haut de la carte, d'un ennemi sans fiche — la fiche s'ouvre et reste
  ouverte ; un clic droit sur un autre ennemi, fiche ouverte ; fiche ouverte sur un ennemi qui porte un bonus et une
  altération — le cadre ne couvre pas sa languette.
