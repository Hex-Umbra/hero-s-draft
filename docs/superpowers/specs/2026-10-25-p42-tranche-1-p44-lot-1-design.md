# P-42 tranche 1 et P-44 lot 1 — Le catalogue par lots, la profondeur et les évolutions de signature — Conception

Date : 2026-10-25
Statut : **Conception** — vague 5 (`0.5.7`), branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`

Chantiers ROADMAP : **P-42** « Catalogue par lots de passif », tranche 1, et **P-44** « Profondeur », lot 1 — une
seule livraison (brainstorm §11, ligne P-44). Le déroulé fait foi dans le
[fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§8.5 ; les décisions, dans le [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md),
§1, §4.4, §6, §7, §8 et §9.

> **Ce que le lot livre, en une phrase.** Les cartes apprennent à coûter des PV ou de l'Armure, à frapper
> plusieurs fois, à grandir avec une ressource et à poser des statuts qui comptent leurs points ; cinq runes de
> mécanisme s'ajoutent à la fusion ; chaque passif reçoit son dossier de cartes, `cards/<passif>/`, et trois
> lots arrivent — Rempart, Sang, Arcaniste — pendant que les six passifs sans lot quittent la sélection ; enfin
> les signatures évoluent tous les cinq niveaux du héros, sur un écran à trois rouleaux.

Toute référence `fichier:ligne` de ce document a été lue le 2026-10-25 sur `da233ba`. **Les cartes et les
évolutions — noms, valeurs, textes — sont des ordres de grandeur** (fiche 8.5) : la spec les fixe, le plan les
écrit, le test du propriétaire les corrige.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce que le lot en livre | Où |
|:---|:---|:---|
| **D4**, **D18** | Cinq runes de mécanisme, une par mécanisme de P-44 lot 1 | §3.6, §4.6 |
| **D7** (évolutions) | Les signatures évoluent avec le niveau du héros, par des améliorations propres à chacune | §3.7, §4.10, §5.1 |
| **D8** | Le catalogue repart de zéro en gardant les ids : `focus` disparaît, `demon_form` change de dossier, les autres neutres restent | §3.5 |
| **D9** | Trois passifs par classe, exclusifs : `PassiveData.classes` vaut exactement une classe | §3.3 |
| **D10**, **D15** | Un lot par passif, la forme C : `cards/<passif>/<id>.json`, le passif injecté par le répertoire | §3.2 |
| **D12** | Les mécanismes de P-44 lot 1, plusieurs cartes par mécanisme, et les coûts combinés | §3.4, §4 |
| **D16** | 5 à 6 cartes par lot : six pour chacun des trois lots | §3.4 |
| **D17** | Aucune neutre bloquée ; aucune neutre ne coûte autre chose que du mana | §3.1, A8 |
| **D19**, **D21** | Tous les 5 niveaux, chaque signature gagne un niveau ; 3 améliorations tirées, une choisie ; mineure aux niveaux impairs de signature, majeure aux pairs, sans plafond | §4.10, §5.1 |
| **D28** | `focus` supprimée | §3.5 |
| **D33**, **D35** | `piercing` et `lifesteal` en pourcentage ; `lifesteal` est un soin propre à la carte, par carte et non par coup | §4.6 |
| **D34** | L'ordre des tranches : Rempart, Sang, Arcaniste. Le déclencheur `onDamagingCardPlayed` **n'est pas** de ce lot | §2 |
| **D38** | `mightRatio` par effet de dégâts ; le test Σ `hits` × `mightRatio` ≤ coût en mana + 1 | §4.3, §9 |
| **D40** | Les trois règles des coûts combinés ; le validateur `costs.armor` dans un lot dont la classe convertit l'armure | §4.1, A7 |
| **D44** | `requiresCost: "hp"` sur `transfusion` | §3.6 |
| **D45** | `feeds` sur chaque passif, et le test qui l'impose aux cartes de lot | §3.3, §9 |
| **D50** | Le test des cartes gratuites : coût total nul, deux au plus par classe et passif, toutes à épuisement | §9 |
| **D54** | *Célérité*, majeure | §3.7 |
| **D63** (Q9) | Le draft de départ : 2 cartes du lot et 3 neutres ; les runes neuves au poids 50, `minFusionRank` 1 | §4.9, §3.6 |
| **D65** | `piercing`, `lifesteal`, `splash`, `echo`, `transfusion` | §3.6, §4.6 |
| **D66** | D38, D40 dans P-44 lot 1 ; D45, D50 dans la tranche 1 | §9 |

### 1.2. Les réponses du propriétaire (classe P), reprises telles quelles

| Question | Réponse |
|:---|:---|
| **Q6** | 3 mineures et 4 majeures par signature (le bas de la fourchette du brainstorm §4.4) ; le repli « un palier majeur tire des mineures quand les majeures sont épuisées » est confirmé |
| **Q7** | Deux majeures contradictoires s'excluent par un champ en donnée sur l'évolution : une liste `excludes` d'ids, sur le modèle d'`excludesRunes` (D44) — prise l'une, l'autre sort du tirage |
| **Q8** | Pas de carte-pont dans cette vague : chaque lot atteint ses 5 à 6 cartes seul ; les ponts restent sous la main pour plus tard (brainstorm §7.4) |
| **Q9** | Le draft de départ propose 2 cartes du lot du passif choisi et 3 neutres (la valeur de D63) |
| **Q11** | Un seul bonus de Puissance par carte : une carte qui pose `burn` et porte la rune `burning` ne compte la Puissance qu'une fois |
| **O5** | Le masquage : un passif dont le dossier `cards/<passif>/` est vide n'est pas proposé à la sélection — une règle dans `availablePassivesFor`, sans liste en dur ; la note de version dira que six passifs quittent la sélection jusqu'à ce que leur lot arrive |
| **P-1** *(répondue le 03/11, née à l'écriture)* | Option (a) — 25 % par point, plafonnés : Vulnérable +25 % de dégâts subis par point, 4 points au plus (+100 %) ; Faiblesse −25 % de dégâts infligés par point, 2 au plus (−50 %) ; Gel −25 % à l'attaque par point, 3 au plus (−75 %) ; *Trait de Glace* Gel 1 → 2, `freezing` 2 points par niveau, *Marque du Mage* Vulnérable 1 → 2 (§4.4). Le propriétaire ajoute que les charges élémentaires (P-53 de la ROADMAP, [étude](../../possible_upgrades/03-11-2026_charges_elementaires_Opus5.md)) relèveront le Gel, le Feu et la Foudre en `0.6.0` : ce barème est celui de `0.5.7` |
| **P-2** *(répondue le 03/11, née à l'écriture)* | Option (c) — **un badge de niveau et une icône par évolution prise, sur la tuile de la signature**. Motif du propriétaire : « c'est celle qui donne le plus d'informations au joueur, rien n'est caché ». Forme : A35 à A38, §3.7, §5.2 |
| **P-3** *(répondue le 03/11, née à l'écriture)* | Option (a) — **l'écho ne déclenche aucun événement « carte jouée »** : il rejoue la résolution, pas le geste ; ni passif (*Flux de Mana*, *Soif de Sang*), ni relique, ni compteur de cartes jouées (A12) ne le voient (A19). Écartées : (b) tous les événements — une Compétence à écho compterait deux fois pour *Flux de Mana*, du mana hors de la courbe que D11 et les exclusions d'`echo` ferment ; (c) les passifs seulement, la même faille et une seconde règle |
| **P-4** *(répondue le 03/11, née de P-2)* | Option (a) — **l'icône de l'évolution sur chaque rouleau de l'écran d'évolution** (§5.1). Motif du propriétaire : la philosophie de P-2, afficher toutes les informations au joueur ; sans elle, rien ne relie une icône de tuile à son évolution |
| **PN12** *(répondue le 03/11, née à l'écriture du plan de la partie 3 ; [maquettes](../../presentations/2026-11-03_vague_5_pn12_pn13_maquettes.pptx), diapositives 5 à 8)* | Une option (d), du propriétaire, à la place des trois proposées — **sur la tuile de combat, ce que fait la signature s'écrit en icônes au lieu du texte**, sans réutiliser le système actuel d'infobulles des cartes, « qui doit être revisité » (hors de cette vague). **Au repos** : une icône par effet de la signature évoluée — ses effets propres et ceux qu'ajoutent ses évolutions, critique et « tous les ennemis » compris —, plus grandes que les icônes d'évolution (28 px contre 18 dans la maquette), trois par ligne, centrées dans la tuile, puis retour à la ligne ; **chaque icône porte sa valeur** évoluée (10, 4, 1, +5 %) ; la durée d'un statut ne s'y écrit pas. **Appui long** : tant que le joueur reste appuyé sur la tuile, elle déroule sa description complète en liste, à la manière de l'option (b) — **une ligne par icône**, l'icône suivie de sa phrase (« Inflige 10 dégâts », « Donne 4 d'Armure », « Applique 1 Faiblesse pendant 2 tours ») ; **relâcher la replie**, comme l'infobulle d'un nœud de la carte du monde (`map_node_widget.dart:140-142`) ; la liste passe par-dessus les tuiles voisines sans déplacer la colonne de la barre. Un appui court garde son rôle — jouer, ou armer une signature à cible. Le badge de niveau et la rangée des icônes d'évolution (A36, A37) restent. **Hors combat** (sélection de classe, deck), la tuile garde son texte complet. Motif du propriétaire, devant les maquettes : « c'est exactement la vision que j'avais » ; les quatre précisions sont les recommandations de l'orchestrateur, acceptées telles quelles |
| **PN13** *(répondue le 03/11, née à l'écriture du plan de la partie 3)* | Option (c) — **le badge « Niv. n » en `Colors.amberAccent`** quand la tuile est disponible ou armée, l'ambre d'accent du HUD (panneau des intentions ennemies, bouton de tour) ; en recharge et sans le mana, `Colors.white38`, comme le reste de la tuile (A36). Écartées : (a) le blanc du nom, (b) la couleur de la classe — le rouge du Berserker se fond dans le type « Attaque », le violet du Mage se lit mal sur le fond sombre |
| **L'écran d'évolution** | Le carrousel de la montée de niveau (`DraftScreen`, `DraftCardReel`), trois rouleaux, une fois par signature, déclenché par `pendingDrafts`. Chaque rouleau montre : le nom de l'évolution, sa description, son palier (« Mineure » / « Majeure ») et, pour une mineure déjà prise, son niveau « 1 → 2 » ; l'en-tête de l'écran nomme la signature concernée. Les détails de mise en page que ce contenu ne fixe pas (tailles, polices, couleurs) suivent le carrousel existant et sont de classe T |

### 1.3. Les arbitrages

**A1 — Q10 est sans objet : une carte de lot se dit par `CardData.passive`, rien d'autre** *(T, filtre 5)*.
Re-mesuré : `CardCategory` n'existe plus, E4 l'a retirée (spec E4, A2) et `CardData.fromJson` refuse la clé
`category` (`card_data.dart:150-157`). Réintroduire une énumération `lot` doublerait `passive != null` — deux
champs qui disent la même chose, ce qu'ADR-101 D2 écarte. `CardData` gagne `passive` (`String?`), injecté ;
`null` veut dire neutre.

**A2 — La forme C au chargeur : une seconde source de cartes, et la source neutre injecte `passive: null`**
*(T, filtre 5)*. La liste des sources de cartes (`game_data_service.dart:77-83`) gagne
`EntitySource('assets/data/cards/*/*.json', CardData.fromJson, inject: (c) => {'id': c[1], 'passive': c[0]})` ;
le nombre de segments sépare les deux (`game_data_loader.dart:251-257`). La source neutre injecte désormais
`{'id': c[0], 'passive': null}` : une neutre qui déclarerait `passive` tombe sous la règle unique de
`_applyInjection` (`game_data_loader.dart:226-238`) — champ imposé par le répertoire, refusé — au lieu de
devenir une carte de lot en silence, ce qu'A10 d'E4 craignait pour `heroClass`. Un même id sous deux dossiers
échoue déjà : la déduplication est commune aux sources (`game_data_loader.dart:123-131`).

**A3 — Le prédicat d'offre devient `CardData.isOfferable(String? activePassiveId)`** *(T, filtre 5)*.
Aujourd'hui un accesseur sans paramètre, `type != CardType.status` (`card_data.dart:146`). Il reste unique
(ADR-101 D1) et gagne la ligne que le brainstorm §6 prévoit : `passive == null || passive == activePassiveId`.
Ses quatre lecteurs passent le passif actif : boutique (`shop_controller.dart:51-53`), trouvaille
(`reward_controller.dart:220`), draft de départ (`starter_deck_draft_screen.dart:55-56`), `starterPool` du
tutoriel (`tutorial_fixtures.dart:67-70`). Une run sans passif ne se voit offrir que des neutres. Le nom
`isOfferableTo`, retiré par E4, n'est pas repris.

**A4 — Le masquage (O5) se lit sur le registre** *(T, filtre 5)*. Un dossier vide n'a pas d'existence dans le
manifeste d'assets — `sync_assets` ne déclare que les dossiers qui portent un fichier, et le chargeur ne lit
que des fichiers (`game_data_loader.dart:251-285`) — : « le dossier `cards/<passif>/` est vide » se mesure donc
comme « aucune carte du registre ne porte ce passif ». Forme complète, cas limites et tests : §4.8.

**A5 — `PassiveData.classes` vaut exactement une classe, au chargement** *(T, filtre 5)*. `PassiveData.fromJson`
refuse aujourd'hui la seule liste vide (`passive_data.dart:222-228`) ; il refuse désormais l'absence et toute
liste d'une longueur autre que 1. Le champ reste une liste (brainstorm §6), le modèle reste nullable pour les
passifs construits en code par les tests, et `availablePassivesFor` garde sa lecture. **Amende ADR-096 D1**
(« absent = toutes les classes »).

**A6 — `feeds` : un vocabulaire à préfixes, obligatoire sur les neuf passifs** *(T, filtres 1 et 4)*. D45 dit
« chaque passif déclare `feeds` » et donne Ferveur, `["armor", "attack"]` — un type d'effet et un type de carte.
Le Sang se nourrit de PV manquants, que ni un type d'effet ni un type de carte ne disent ; la liste admet donc
cinq formes, lues au chargement : un type de carte (`attack`, `skill`, `power`), un type d'effet (`damage`,
`armor`, `heal`, `draw`, `gain_mana`, `apply_status`), `status:<id>` (un `apply_status` de ce statut),
`cost:<hp|armor>`, `scale:<source>`. Une carte « touche » la liste si son type, l'un de ses effets, l'un de ses
statuts posés, l'un de ses coûts ou l'une de ses sources de `scaleWith` y figure. La règle vit dans une fonction
pure que lisent le test de données et l'éditeur (A31). Les neuf valeurs : §3.3.

Compter un coût combiné comme une touche est une **lecture** de D45, non un amendement *(tranché par
l'orchestrateur, C1.3, T, filtre 1)* : le coût est une part de la résolution de la carte — débité par `resolveCard`
(§4.1), hors du pipeline (brainstorm §9.1) —, donc un de ses effets au sens de D45. Sans cette lecture, *Percée*, que le
brainstorm range dans Rempart (§7.1), et *Sang versé*, *Pacte de sang*, *Éclat de bouclier*, qui ne touchent leur
passif que par leur coût, échoueraient au test de D45.

**A7 — Le validateur `costs.armor` se lit sur la règle de classe, pas sur l'id `berserker`** *(T, filtre 4)*.
Une carte de lot qui coûte de l'Armure est une faute de donnée quand la classe de son passif porte une règle
`statRules` qui convertit l'armure (`classes/berserker/class.json`, `"stat": "armor", "mode": "convert"`) : cette
classe n'a jamais d'Armure à dépenser. La règle est dans la même fonction pure que `feeds` (A6), lue par le test
et par l'éditeur ; elle ne s'étend pas à `costs.hp` dans un lot qui soigne (D40).

**A8 — D17 se garde au chargement** *(T, filtre 5)*. `CardData.fromJson` refuse un coût en PV ou en Armure sur
une carte sans `passive` — une neutre, le passif étant injecté à `null` (A2). Le test de données le redit sur le
registre réel (§9).

**A9 — La forme de `costs`** *(T, filtres 5 et 7)*. Une carte déclare **soit** `cost` (mana seul, la forme
d'aujourd'hui) **soit** `costs` ; les deux ensemble sont refusés. `costs` exige `mana` (entier ≥ 0) et au moins
un de `hp`, `armor` (entier ≥ 1) — sans eux, la carte s'écrit avec `cost`. Toute autre clé est refusée, nommée :
`discard` est P-44 lot 4 (brainstorm §9.1). Le modèle garde `cost` pour le mana et gagne `hpCost`, `armorCost`
(défaut 0) ; `toJson` écrit `costs` si l'un des deux est non nul, `cost` sinon — la sauvegarde relit la carte
par `CardData.fromJson` avant de la remplacer par celle du registre (`card_instance.dart:56-63`,
`deck_controller.dart:72-99`), un aller-retour faux effacerait la partie.

**A10 — Une seule règle d'accessibilité, `EffectResolver.canAfford`** *(T, filtre 5)*. Le jeu teste le mana à
trois endroits qui divergeraient : `canPlayCard` (`effect_resolver.dart:109-111`), `CardComponent.canAfford`
(`card_component.dart:53-57`) et le jeu simulé du tutoriel. Une fonction pure, `canAfford(card, heroStats)`,
porte les trois ressources ; `canPlayCard` et `CardComponent.canAfford` l'appellent.

**A11 — `scaleWith` : un objet, six sources, arrondi vers le bas** *(T, filtres 4, 5 et 8)*. Forme :
`"scaleWith": { "source": "<source>", "ratio": <nombre > 0>, "statusId": "<id>" }`, `statusId` exigé pour
`targetStatus` seulement. Le terme vaut `floor(quantité × ratio)` (tolérance 10⁻⁹, comme
`StatRule.convertedAmount`), calculé par le résolveur avant la stratégie (ADR-061) et ajouté à la valeur
**après** la rareté et les runes — la rareté ne le multiplie jamais. Un `ratio` inférieur à 1 dont l'inverse
n'est pas entier, à 10⁻⁹ près, est refusé au chargement : le texte l'écrit en tranches de `1 / ratio` (§6.1), qui
doivent être entières — 0,2 et 0,1 donnent 5 et 10 ; 0,3 est refusé. Les sources et leurs bornes : §4.2.

**A12 — Les cartes jouées ce tour se dérivent, elles ne se décomptent pas** *(T, filtre 8)*. `CombatState`
gagne deux entiers, le tour du dernier jeu et le nombre de jeux de ce tour ; `cardsPlayedThisTurn` rend le
second si le premier est le tour courant, 0 sinon. La suite commune `_afterCardPlayed`
(`combat_controller.dart:296-321`) l'incrémente — une signature compte, résolue comme une carte. Aucune remise à
zéro n'est écrite dans l'ouverture du tour : le précédent d'A7 d'E4.

**A13 — `mightRatio` arrondit vers le bas, et un multi-coups le déclare sous 1** *(T, filtre 1)*. La Puissance
d'un coup vaut `floor(bonus × mightRatio)` : le budget de D38 est une borne, un arrondi au plus proche la
franchirait à faible Puissance. Le test de données impose, en plus de la somme de D38, la lettre de D38 : un
effet à `hits ≥ 2` déclare `mightRatio < 1`.

**A14 — Une rune en pourcentage sur un multi-coups se calcule sur le total** *(T, filtre 1)*. La formule d'E1,
`max(round(p × L × B), L)` par effet (`card_delta.dart:85-86`), appliquée coup par coup ferait du plancher « au
moins +L » un « +L par coup » : *Tranchant* 5 donnerait +15 à une *Rafale d'étincelles* 3 × 3, quand D33 veut
une rune « qui ne multiplie plus par le nombre de coups ». Sur un effet à `hits` coups, le bonus se calcule sur
la valeur totale `B × hits`, avec le même plancher, puis se répartit : `ceil(bonus / hits)` par coup. Un effet
d'un coup garde la formule d'E1 à l'identique.

**A15 — Q11 : un seul bonus de Puissance de statut par résolution, compté dans le résolveur** *(la réponse P de
Q11, appliquée à la lettre ; l'écho tranché par l'orchestrateur, C1.1, T, filtre 6 ; le lieu du calcul, T,
filtre 5)*. Le bonus de statut quitte `ApplyStatusEffectStrategy` (`strategies.dart:174-176`) pour le résolveur,
qui le calcule déjà pour `scaleWith` : à chaque résolution d'une carte, **seul le premier `apply_status` — tous
statuts confondus, ceux qu'une rune pose compris — reçoit `statusBonusFor(target)`** ; tous les suivants, de
quelque statut qu'ils soient, n'en reçoivent aucun. Les effets des runes passent d'abord
(`effect_resolver.dart:141-152`) : sur *Boule de Feu* + *Brûlant*, la Brûlure de la rune porte la Puissance, celle
de la carte non ; sur *Coup de Tonnerre* + *Brûlant*, *Boule de Feu* + *Surchargé* ou *Trait de Glace* +
*Brûlant*, le statut de la rune la porte et celui de la carte non. Un premier `apply_status` posé sur soi consomme
le bonus, qui y vaut 0 (`power_rules.dart:27-32`) — aucune carte livrée ne mêle un statut sur soi et un statut sur
l'ennemi. **L'écho est une seconde résolution de la carte** (« la carte se rejoue une fois », brainstorm §8) : il
reçoit son propre bonus unique, comme ses dégâts reçoivent de nouveau la Puissance. Les dégâts gardent leur
Puissance par coup (D38).

**A16 — `piercing` vit dans l'absorption, pas dans `DamagePipeline`** *(T, filtre 5)*. Re-mesuré : l'armure
n'est pas lue par le pipeline (`damage_pipeline.dart:9-62`) mais par `EntityStats.takeDamage`
(`entity_stats.dart:194-214`). `takeDamage` gagne un paramètre nommé, le pourcentage d'Armure ignoré (défaut 0) ;
la part ignorée de l'Armure ne protège pas et n'est pas consommée.

**A17 — `splash` : un pourcentage de chaque coup, par le pipeline de chaque cible** *(T, filtre 6)*. Chaque coup
d'une carte `singleEnemy` portant la rune frappe aussi chaque autre ennemi vivant pour `p %` de ses dégâts
avant pipeline (valeur, terme et Puissance), au moins 1 — la demie vers le haut, comme D33 — puis passe le
pipeline de cette cible (son critique, son Électrocution, sa Vulnérabilité) et son absorption, `piercing`
compris. L'éligibilité exige une cible unique, par un champ neuf de rune, `eligibleTargets` (A21).

**A18 — La rune `lifesteal` soigne en plus du statut de *Soif de Sang*** *(T, filtre 1)*. D35 : un soin propre à
la carte, « jamais le statut du passif ». La revue (§7 idée 2.8) avait montré qu'en statut non cumulable la
rune serait morte pour un Vampire ; elle se paie donc à part : une fois par effet de dégâts — par carte, aucune
carte du catalogue ne portant deux effets de dégâts —, `round(p % × dégâts infligés)` sur tous les coups et
toutes les cibles, éclaboussures comprises, demie vers le haut, **au moins L** et jamais plus que les dégâts
infligés, par `RunController.heal` sans critique. Le plancher « au moins +1 par niveau » de D33 s'applique, borné
par ce qu'il y a à prendre : D33 range `lifesteal` et `piercing` parmi ses runes en pourcentage, et la borne reprend
celle du statut, `min(valeur, dégâts)` (`strategies.dart:78`) *(T, filtre 1)*. Le statut garde son paiement
d'aujourd'hui (`strategies.dart:65`, `:73-79`). « Non cumulable » se lit : une rune par carte (D3), et pas de
statut qui s'additionne.

**A19 — `echo` : une seconde résolution, une seule** *(T, filtre 4 ; les événements : P-3, §1.2)*. Après les effets,
un jet ; réussi, les effets — ceux des runes et ceux de la carte — se résolvent une seconde fois, sur la même
cible si elle vit, sans coût, sans mouvement de pile, sans second jet ni remboursement, avec son propre bonus de
statut (A15). Il ne déclenche aucun événement « carte jouée » (P-3, §1.2). Un écho sur une carte qui rend du mana ou pioche serait un moteur :
la rune porte `excludesEffects: ["draw", "gain_mana"]` et `excludesRunes: ["eco", "quick"]`, des règles
d'éligibilité en donnée, dans la forme que D44 impose à toute règle d'éligibilité.

**A20 — `transfusion` : la moitié du coût en PV, rendue après la résolution** *(T, filtre 5)*.
`round(50 % × hpCost)`, demie vers le haut, ajoutée aux PV hors du pipeline et hors de `heal` — ni critique, ni
soin —, bornée par les PV max, après l'écho. `requiresCost` est un champ de rune neuf (D44) qui n'admet que
`"hp"` — aucune rune ne rembourse l'Armure (D40), une valeur `"armor"` n'aurait pas de lecteur — ; seule
`transfusion` le porte.

**A21 — `eligibleTargets`, la condition de cible en donnée** *(T, filtre 4)*. ADR-105 l'annonçait pour `splash`.
Liste facultative de noms de `CardTarget` ; absente, toute cible ; vide, refusée. `ForgeRuneRules.isEligible`
(`forge_rune_rules.dart:67-111`) la lit comme `eligibleCardTypes`.

**A22 — *Transcendance* garde sa règle sur les runes neuves, sauf un relèvement sans effet** *(tranché par
l'orchestrateur, C1.2, T, filtres 1 et 6)*. D42(c) monte « le `maxLevel` d'une rune », sans exception : la règle
d'E3 vaut telle quelle pour les runes neuves — `splash` 4 et `echo` 5 deviennent possibles, rares, comme `eco` 2.
Mais une rune dont le relèvement n'aurait aucun effet n'est pas proposée : `piercing` à 4 ignore déjà 100 % de
l'Armure. Le tirage — `ForgeRuneRules.raisableCaps` (`forge_rune_rules.dart:155-175`), lu par le draft de niveau
(`draft_screen.dart:116-120`) et par la modale de *Transcendance* (`:678`) — écarte, en plus des runes `binary`
(`:170`), une rune dont **chaque delta est saturé** à son plafond effectif. La saturation est une propriété de la
sorte de delta, non un cas par id. Trois sortes en ont une, toutes trois des pourcentages qui valent 100 au plus :
`armorPierce`, `lifestealPercent` et `echoChance` sont saturées au plafond `c` quand
`valuePercentPerLevel × c ≥ 100` — `piercing` à 4, `lifesteal` à 5 (le soin vaut alors les dégâts, A18), `echo` à
7. Le bonus de *Transcendance* s'additionnant à chaque tirage (`run_controller.dart:485-489`), `lifesteal` 5 et
`echo` 7 sont atteignables ; ils ne se proposent plus (§4.6).

**A23 — `freezing` perd son plafond, et gagne deux points par niveau** *(T, sous P-1, répondue)*. `maxLevel: null` (fiche
8.5, brainstorm §8) ; `valuePerLevel` passe à 2 pour que le niveau 1 garde l'effet d'aujourd'hui sous le barème
de P-1 (§1.2, §4.4).

**A24 — Une évolution est un delta, appliqué par l'applicateur des runes à la vue de carte** *(T, filtre 5)*.
`SignatureEvolutionData` déclare des `deltas` dans le vocabulaire de `CardDelta`, plus deux champs que n'a pas une
carte : `target` (une majeure qui change la cible) et `cooldown` (un entier ajouté à la recharge). `CardInstance`
gagne `extraDeltas`, des paires (delta, niveau) lues par `effective` après les runes, jamais sérialisées, que seule
`SignatureInstance.asCard` remplit (`signature_instance.dart:20-36`) : la couture qu'ADR-105 D1 prévoyait, sans
que runes et évolutions partagent données, stockage ni affichage. Une sorte de delta neuve, `flatBonus` (+N par
niveau à un effet propre), sert les mineures.

**A25 — La description d'une signature se lit sur ses valeurs évoluées, par un gabarit** *(T, filtre 6)*. Les
six descriptions deviennent des gabarits — `{damage}`, `{armor}`, `{heal}`, `{draw}`, `{gain_mana}`, `{<statusId>}`
— remplis par la valeur évoluée du premier effet propre de ce type. Une évolution est **chiffrée** (`flatBonus`,
`reduceCost`, `cooldown` : elle ne change que des chiffres que la tuile montre déjà — gabarit, médaillon de coût,
recharge) ou **verbale** (`addEffect`, `critBonus`, `target`) ; jamais les deux. Une verbale ajoute sa phrase à la
description ; une chiffrée, rien. S'y ajoutent, par la réponse du propriétaire à P-2 (§1.2), le badge de niveau
et une icône par évolution prise sur la tuile de combat : A35 à A38.

**A26 — Un tirage montre toujours trois évolutions tant qu'il en existe trois** *(T, filtre 1)*. D19 dit « 3
améliorations tirées ». Au palier mineur, trois mineures. Au palier majeur, les majeures éligibles — ni prises,
ni exclues par une prise —, jusqu'à trois ; s'il en reste moins de trois, des mineures complètent. Q6 confirme
le repli quand les majeures sont épuisées ; « moins de trois » en est le cas général.

**A27 — L'attente d'une évolution se dérive du niveau, et passe par le même rideau que `pendingDrafts`**
*(T, filtres 5 et 8)*. Une signature attend `max(0, ⌊niveau du héros / 5⌋ − somme des niveaux de ses
évolutions)` choix : rien de neuf à sauvegarder, et un abandon au milieu d'une série ne rejoue ni ne perd rien.
Le déclenchement est celui de la montée de niveau différée (`_rules/03-10`) : le rideau de la carte
(`map_screen.dart:302-316`) s'affiche, et les nœuds se ferment (`:380`, `:403`), tant qu'un draft de niveau ou
une évolution attend. Ordre et enchaînement : §5.1.

**A28 — La sauvegarde des évolutions** *(T, filtre 5)* : §8.

**A29 — Le draft de départ : deux groupes, deux quotas** *(T, conséquence de Q9, filtre 6)*. La grille montre le
lot du passif choisi puis les neutres, chacun sous son titre ; le joueur en prend exactement 2 et 3. Forme : §4.9.

**A30 — Le tutoriel suit le draft, et sa démonstration de jeu écarte les cartes à mécanisme** *(T, filtres 5 et
7)*. ADR-081 veut un tutoriel fidèle au jeu : son draft de départ prend 2 + 3 comme le jeu. Son jeu simulé
(`tutorial_engine.dart:366-399`) ne connaît ni coûts combinés, ni coups multiples, ni `scaleWith` ; plutôt que de
les y recopier, le choix des cartes de la leçon (`tutorial_engine.dart:247-258`) écarte une carte qui en porte —
le repli sur les fixtures existe déjà.

**A31 — L'éditeur de contenu gagne une dixième catégorie, la carte de lot** *(T, filtre 5)*. Le fil de détente
`entity_descriptor_test.dart:21-36` compte neuf `EntitySource` pour neuf catégories et dit, rouge, d'ajouter la
catégorie. La carte de lot reprend la mécanique de propriété de la signature (A4 d'E4), le passif à la place de la
classe. Forme : §7.

**A32 — Une carte dit ses coûts, ses coups et sa croissance sur sa face** *(T, filtre 6)* : §5.2.

**A33 — Le budget de Puissance couvre aussi les signatures** *(T, filtre 8)*. Elles reçoivent la Puissance de leur
type ; le test de D38 les parcourt avec les cartes. Aucune évolution n'ajoute de coup : le test reste vrai sur
chaque signature évoluée.

**A34 — Le découpage en trois parties** *(T, filtre 7)* : §10.

**A35 — L'icône d'une évolution : un champ en donnée qui nomme une entrée d'un registre Dart fermé** *(T, filtres
4 et 5)*. Re-mesuré : les runes font déjà ainsi — le fichier porte `"icon"` et `"color"` (`forge_upgrades/
freezing.json`, `"icon": "ac_unit_rounded"`, `"color": "lightBlueAccent"`), et `rune_style.dart` les traduit par
deux tables `const` de noms vers `Icons.…` et `Colors.…`, que garde le test d'intégrité
(`referential_integrity_test.dart:85-96`). Ces références `const` survivent à l'élagage des icônes du build
release, ce qu'une `IconData` construite à l'exécution depuis une chaîne ne ferait pas. Chaque évolution porte
donc `icon` et `color`, deux noms ; deux tables `const` à elles, `evolutionIcons` et `evolutionColors`
(`lib/ui/widgets/signature_evolution_style.dart`), les traduisent — un nom inconnu retombe, comme pour une rune,
sur `Icons.help_outline` et du gris. Des tables propres plutôt que celles des runes : runes et évolutions ne
partagent ni donnée ni affichage (brainstorm §8, A24). Une table par id d'évolution est écartée : *Célérité*
partage son id sur cinq pools, mais une évolution neuve à l'icône existante demanderait du Dart, quand un nom en
donnée n'en demande pas (filtre 4).

**A36 — Le badge de niveau : le nombre de choix faits, au bout de la ligne du type** *(T, filtre 6)*. Le niveau
d'une signature est `SignatureInstance.level` (§4.10), la somme des niveaux de ses évolutions — le nombre de
paliers atteints et choisis, un par tranche de 5 niveaux du héros (D19). En combat il ne diffère jamais des paliers
atteints, hors du menu de debug (§8) : le rideau ferme la carte tant qu'une évolution attend (A27). Le badge lit la
clé existante `levelLabel` (§6.1), réécrite sur l'abréviation du jeu (`enemy_intents_panel.dart:181-182`,
`hero_mini_stats_panel.dart:210`) ; elle n'avait aucun lecteur et en gagne un. Il se pose au bout de la ligne du **type** (`signature_bar.dart:257-266`), plus courte que le nom : la ligne du
nom (`:246-255`), à une ligne et à points de suspension (S9 de la vague 4), garde toute sa largeur — sur la tuile
étroite, « Surtension de Mana » ou « Projectile Magique » y tiennent à peine et passeraient en « … » si le badge la
partageait. Aucune hauteur de plus. Absent au niveau 0. Les largeurs se vérifient à l'écran, au test manuel : les
tests widget rendent une police carrée qui ne les mesure pas.

**A37 — Les icônes : une rangée sous la description, une puce par évolution distincte** *(T, filtres 6 et 8)*.
Dans l'ordre de la première prise, lue sur `SignatureInstance.taken` (§4.10) ; une majeure dans un anneau de sa
couleur, une mineure nue, avec son niveau en petit chiffre en bas à droite dès 2 — l'anneau distingue deux
évolutions de même icône sur une tuile (*Harmonie* et *Exaltation* sur *Surtension de Mana*) — dans les six pools,
deux évolutions d'une même signature qui partagent une icône sont toujours une mineure et une majeure (§3.7). Une
signature porte au plus sept évolutions distinctes (son pool) : à 16 px la puce et 2 d'écart, sept puces font
124 px, qui tiennent dans la colonne de texte de la tuile étroite — 170 px, moins la marge et la bordure (2 × 8,
`signature_bar.dart:374-384` : la bordure armée prend sur la marge), le médaillon (20) et son écart (6), soit
128 px ; à 18 px, 138 px dans les 178 de la large. La rangée ne déborde donc jamais : ni coupure, ni « +k ». Elle
ajoute une ligne de 16 ou 18 px, selon la tuile, dès la première évolution.

**A38 — La barre reste centrée à mi-hauteur, et ne se décale ou ne se réduit que si elle sort de sa bande** *(T,
filtres 1 et 6)*. A6 d'E4 pose la barre à mi-hauteur, en miroir du bouton de fin de tour
(`docs/superpowers/specs/2026-10-15-p43-e4-signatures-design.md:78`, `:341` ; `turn_control_panel.dart:101-104`,
`top: screenHeight / 2 - 25`) : cette place ne change pas. Mais la tuile grandit avec ses phrases verbales (A25) et
sa rangée d'icônes ; au niveau 30 du héros, l'horizon de D67, deux tuiles mesurent environ 300 px, et la colonne
centrée (`signature_bar.dart:60-66`) passerait sous le panneau des statuts du héros (`combat_side_panels.dart:71-75`)
sur un écran de moins de 700 px de haut. La colonne a donc une **bande** : de `bandTop` sous le haut à `bandBottom =
statusPanelBottom + statusPanelReserve` au-dessus du bas. `statusPanelBottom` (80) et `statusPanelReserve` (120, la
place de deux rangées de statuts) deviennent deux constantes nommées de `CombatSidePanels`, qui pose le panneau
(`combat_side_panels.dart:72` lit aujourd'hui `bottom: 80` en dur) ; la barre les lit. `bandTop` (80, sous la barre
du haut posée à `top: 10`, `combat_top_bar.dart:33-86`) est de même une constante nommée de `CombatTopBar`.

**`H`** est la hauteur que reçoit la barre — celle de son `Positioned.fill`, dans le `Stack` du `SafeArea`
(`game_screen.dart:559-560`), celle que lit l'`Align` d'aujourd'hui —, jamais `MediaQuery` (que lit
`turn_control_panel.dart:25`, pas la barre) ; le panneau étant posé dans le même `Stack`, `bandBottom` se compte
dans le même repère. Avec `h` la hauteur naturelle de la colonne et `bande = H − bandTop − bandBottom` :

1. l'échelle : `s = clamp(bande / h, 0.75, 1)` — 1 tant que la colonne tient dans la bande ;
2. la hauteur posée : `h' = s × h` ;
3. la position : `top = max(bandTop, min(H/2 − h'/2, H − bandBottom − h'))` — à mi-hauteur quand elle tient, décalée
   vers le haut seulement si elle sortirait de la bande par le bas, jamais au-dessus de `bandTop`.

La colonne se mesure **avant** d'être posée : une mise en page qui connaît `h`, `Flow` ou un `RenderBox` propre à
la barre — le plan tranche entre les deux ; un `FittedBox` ne connaît pas `h` et ne tiendrait pas le plancher.
**0,75 est un plancher de lisibilité**, sous lequel le coût du médaillon (12 px, `signature_bar.dart:433`) tomberait
sous 9 px. Au plancher, la colonne dépasse la bande par le bas, toujours peinte au-dessus du panneau (S11 de la
vague 4). C'est le cas d'un écran bas — un téléphone en paysage, que l'iOS autorise (`ios/Runner/Info.plist:56-60`)
et qu'Android ne restreint pas (aucune `screenOrientation`), ou une fenêtre réduite : à `H ≈ 400`, la bande fait
≈ 120 px contre ≈ 176 pour deux tuiles au niveau 0. **Une limite acceptée** : sur un écran d'environ 400 px de haut,
en fin de run, avec ≈ 300 px de tuiles, la colonne au plancher descend à ≈ 95 px du bord et peut couvrir le haut du
HUD du bas — cristaux de mana et PV (`game_screen.dart:541-542`, `hudHeight` 100 en mobile, borné de 88 à 140 ;
`combat_bottom_hud.dart:30-35`) ; elle reste peinte au-dessus et jouable.

L'invite « Choisissez une cible » pend toujours sous la colonne sans la déplacer (S10 de la vague 4).

Les cartes, les pools d'évolutions et leurs textes sont des choix du rôle `game_designer` (fiche 8.5) ; deux
choix de conception y portent une raison qu'il faut lire : *Surtension de Mana* n'a pas *Célérité* — à recharge
1, elle rendrait +1 Mana à chaque tour, la *Sagesse* que D11 relègue en mythique — ; et chaque carte à
`scaleWith` garde une valeur de base d'au moins 1, sans quoi la fusion (G1) ne changerait aucun chiffre.

### 1.4. Les questions ouvertes

Aucune : P-1 à P-4, PN12 et PN13 sont répondues par le propriétaire (§1.2).

**Aucune question de classe D** : rien n'exige d'amender une décision acquise.

---

## 2. Périmètre

**Dans le lot** : le moteur de P-44 lot 1 — coûts combinés, `scaleWith`, multi-coups et `mightRatio`, statuts
proportionnels, un seul bonus de Puissance de statut par résolution — et les cinq runes ; la forme C, le passif injecté,
l'offre étendue, le masquage, `classes` à une classe, `feeds` ; les trois lots, `focus` supprimée, `demon_form`
déplacée, *Trait de Glace* et *Marque du Mage* recalibrés ; le draft de départ à 2 + 3 et le tutoriel ; les
évolutions de signature, leurs pools, leur écran, leur sauvegarde ; le rendu des cartes ; l'éditeur ; les textes.

| Hors du lot | Où |
|:---|:---|
| Les six autres lots ; leurs cartes, y compris les quatre élémentaires, `metallicize` et `warcry`, qui restent neutres | Vagues 6 et 7 |
| D30 (banque de mana), D55 (*Prière*, `hp_regen`), le déclencheur de D34 (`onDamagingCardPlayed`) | Vagues 6 et 7 |
| Épines, `retain`, production de cartes, malédictions, effets interactifs, `costs.discard`, `CardTarget.none` | P-44 lots 2 à 4 |
| Les cartes-pont (Q8) | Plus tard |
| `maxMana` | Reste 3 (D11) |
| Tout rééquilibrage des neutres, sauf *Trait de Glace* (P-1, l'effet gardé) et la suppression de `focus` | — |
| `tool/simulations/` : ni relancé, ni réaligné ; il ne lit pas `cards/*/*.json` et ne tourne plus depuis E4 — accepté (ADR-108 D5) | — |

### 2.1. Les transitions

| Frontière | État en `0.5.7` | Réglé par |
|:---|:---|:---|
| E4 → tranche 1 | Les signatures étaient des compétences sans évolution, le deck ne connaissait que les 17 neutres | Ce lot : `evolutions`, l'écran, trois lots |
| E4 → tranche 3 | *Marque du Mage* ne se déclenche plus sur *Projectile Magique* depuis `0.5.6` ; en `0.5.7` le passif est masqué, et son recalibrage (Vulnérable 2) est invisible jusqu'à `0.6.0` | Voulu (orchestration §7.2) ; le fichier garde `trigger: onAttackPlayed` |
| Tranche 1 → 2 → 3 | Six passifs masqués, puis trois ; le pool d'une run compte **15 neutres** + 6 cartes de lot, pas les 9 + 6 que la simulation a jouées — les six survivantes attendent leurs lots ; `fireball` reste neutre, son id de tutoriel ne change pas | Tranches 2 et 3 |
| Tranches → P-44 lots 2 à 4 | Rempart sans épines atteint ses 6 cartes sans elles | — |
| Sauvegardes de `0.5.6` | Une run sous un passif masqué reprend avec lui, et ne trouve que des neutres ; `focus` y est retirée comme élément manquant | Avant la `1.0.0`, rien |

---

## 3. Données

### 3.1. La carte : `costs`, `hits`, `mightRatio`, `scaleWith`

```json
{
  "name_en": "Breach", "name_fr": "Percée",
  "description_en": "Costs 4 Block. Deal 10 damage.",
  "description_fr": "Coûte 4 Armure. Inflige 10 dégâts.",
  "costs": { "mana": 0, "armor": 4 },
  "type": "attack", "rarity": "common", "target": "singleEnemy", "animation": "melee",
  "effects": [ { "type": "damage", "value": 10 } ]
}
```

| Clé | Règle au chargement (`CardData.fromJson`, `CardEffect.fromJson`) |
|:---|:---|
| `cost` / `costs` | A9 : l'un ou l'autre ; `costs.mana` ≥ 0 exigé, `hp`/`armor` ≥ 1, au moins l'un des deux ; toute autre clé refusée, nommée |
| `hpCost`, `armorCost` sur une carte sans `passive` | Refusés (A8, D17) |
| `effects[].hits` | Entier ≥ 1, défaut 1 ; sur `damage` seulement |
| `effects[].mightRatio` | Nombre dans ]0, 1], défaut 1 ; sur `damage` seulement |
| `effects[].scaleWith` | A11, la règle du `ratio` comprise ; refusé sur `draw` et `gain_mana` (ce que G2 gèle ne grandit pas), sur un effet à `hits ≥ 2`, et — pour `targetStatus`, `targetMissingHp` — sur une carte dont la cible n'est pas `singleEnemy` |
| `passive` | Injecté (A2) ; jamais écrit dans un fichier |

`toJson` écrit `passive` s'il n'est pas nul, `costs` ou `cost` (A9), et chaque champ d'effet hors de son défaut.
`SignatureData` lit ses effets par le même `CardEffect.fromJson` : mêmes champs, mêmes règles, la cible étant la
sienne.

### 3.2. La forme C

```
assets/data/cards/
├── <id>.json               # neutre : passive injecté à null
├── regen_armor/<id>.json   # Rempart : passive = "regen_armor"
├── rage/<id>.json          # Sang
└── mana_flux/<id>.json     # Arcaniste
```

Le nom du dossier **est** l'id du passif. Trois dossiers neufs : `dart run tool/sync_assets.dart` les déclare dans
`pubspec.yaml` ; vider `build/unit_test_assets` avant de croire `real_bundle_load_test`.

### 3.3. Les passifs

| Passif | Classe | Lot en `0.5.7` | `feeds` |
|:---|:---|:---|:---|
| `regen_armor` — Régénération d'Armure | paladin | **Rempart** | `["armor", "status:armor_regen", "scale:armor", "cost:armor"]` |
| `fervor` — Ferveur | paladin | — | `["armor", "attack"]` (D45) |
| `blessing` — Bénédiction | paladin | — | `["armor", "status:armor_regen", "status:weakness", "heal"]` |
| `rage` — Rage | berserker | **Sang** | `["cost:hp", "scale:missingHp", "armor", "status:might", "status:might_regen"]` |
| `bloodthirst` — Soif de Sang | berserker | — | `["attack"]` |
| `frenzy` — Frénésie | berserker | — | `["scale:targetMissingHp", "scale:enemiesAlive"]` |
| `mana_flux` — Flux de Mana | mage | **Arcaniste** | `["skill"]` |
| `channeling` — Canalisation | mage | — | `["power"]` |
| `mage_mark` — Marque du Mage | mage | — | `["damage", "status:vulnerable", "scale:targetStatus"]` |

Les six `feeds` sans lot sont des valeurs de départ : la tranche qui écrit le lot les ajuste avec lui. `feeds`
est exigé, non vide, chaque entrée dans l'une des cinq formes d'A6 ; le test d'intégrité vérifie qu'un
`status:<id>` est fabriqué par `EffectResolver.createStatus`.

***Marque du Mage*** (`passives/mage_mark.json`) : `value` 1 → 2 (P-1) ; descriptions « La première Attaque de
chaque tour applique 2 Vulnérable à sa cible pendant 2 tours. » / « The first Attack each turn applies 2
Vulnerable to its target for 2 turns. ». Le déclencheur ne change pas.

### 3.4. Les trois lots

Valeurs calées sur 6 dégâts ou 5 Armure par mana, la prime d'un lot à 6 Armure (revue, annexe B.4). Toutes
communes, aucune à épuisement hors les Pouvoirs, aucune à coût total nul. Les descriptions de fichier
(`description_fr` / `description_en`) sont celles de la dernière colonne.

**Rempart** — `cards/regen_armor/`, Paladin (Puissance sur tout). De l'Armure en quantité, des cartes qui la
lisent, des cartes qui la dépensent.

| id | Nom FR / EN | Coût | Type, cible | Effets | Mécanisme | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|:---|
| `bulwark` | Muraille / Bulwark | 2 | Compétence, soi | `armor` 12 | gros bloc | « Gagne 12 d'Armure. » / « Gain 12 Block. » |
| `bastion` | Bastion / Bastion | 3 | Pouvoir, soi | `armor_regen` 3, 4 tours | Armure dans le temps | « Pendant 4 tours, gagne 3 Armure au début du tour. » / « For 4 turns, gain 3 Block at the start of your turn. » |
| `rampart_slam` | Rempart brisé / Rampart Slam | 1 | Attaque, ennemi | `damage` 2, `scaleWith` `armor` × 1 | `scaleWith: armor` | « Inflige 2 dégâts, +1 par point d'Armure. » / « Deal 2 damage, +1 per point of Block. » |
| `fortify` | Fortification / Fortify | 1 | Compétence, soi | `armor` 6, `scaleWith` `armor` × 0,2 | `scaleWith: armor` | « Gagne 6 d'Armure, +1 par tranche de 5 d'Armure. » / « Gain 6 Block, +1 per 5 Block you have. » |
| `breach` | Percée / Breach | 0 mana + 4 Armure | Attaque, ennemi | `damage` 10 | `costs.armor` | « Coûte 4 Armure. Inflige 10 dégâts. » / « Costs 4 Block. Deal 10 damage. » |
| `shield_burst` | Éclat de bouclier / Shield Burst | 1 mana + 6 Armure | Attaque, tous | `damage` 8 | `costs.armor` | « Coûte 6 Armure. Inflige 8 dégâts à tous les ennemis. » / « Costs 6 Block. Deal 8 damage to all enemies. » |

**Sang** — `cards/rage/`, Berserker (Puissance sur les Attaques ; son Armure devient Puissance à 0,5:1, D37). Des
PV comme ressource, des dégâts qui grandissent avec les PV perdus, de la Puissance qui dure. Les batteries —
`awakening`, `iron_wall`, `defend_basic` — restent neutres (D17).

| id | Nom FR / EN | Coût | Type, cible | Effets | Mécanisme | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|:---|
| `bloodletting` | Sang versé / Bloodletting | 0 mana + 4 PV | Attaque, ennemi | `damage` 8 | `costs.hp` | « Coûte 4 PV. Inflige 8 dégâts. » / « Costs 4 HP. Deal 8 damage. » |
| `blood_pact` | Pacte de sang / Blood Pact | 1 mana + 3 PV | Compétence, soi | `draw` 2 | `costs.hp` | « Coûte 3 PV. Pioche 2 cartes. » / « Costs 3 HP. Draw 2 cards. » |
| `last_breath` | Dernier souffle / Last Breath | 2 | Attaque, ennemi | `damage` 4, `scaleWith` `missingHp` × 0,2 | `scaleWith: missingHp` | « Inflige 4 dégâts, +1 par tranche de 5 PV manquants. » / « Deal 4 damage, +1 per 5 missing HP. » |
| `blood_fury` | Fureur sanguine / Blood Fury | 1 | Compétence, soi | `might` 1, 1 tour, `scaleWith` `missingHp` × 0,1 | `scaleWith: missingHp` | « Gagne 1 Puissance ce tour, +1 par tranche de 10 PV manquants. » / « Gain 1 Might this turn, +1 per 10 missing HP. » |
| `trance` | Transe / Trance | 2 | Pouvoir, soi | `might_regen` 1, 3 tours | `might_regen`, l'orphelin d'août | « Pendant 3 tours, gagne 1 Puissance au début du tour. » / « For 3 turns, gain 1 Might at the start of your turn. » |
| `demon_form` | Forme Démoniaque | 2 | Pouvoir, soi | `might` 2, 4 tours | déplacée de `cards/` (§3.5) | inchangé |

**Arcaniste** — `cards/mana_flux/`, Mage (Puissance sur les Compétences et les altérations ; *Flux* compte les
Compétences). Rien que des Compétences : des dégâts à 1, de l'altération pure, un multi-coups, une Compétence à 3.

| id | Nom FR / EN | Coût | Type, cible | Effets | Mécanisme | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|:---|
| `arcane_shard` | Éclat / Arcane Shard | 1 | Compétence, ennemi | `damage` 5 | Compétence de dégâts | « Inflige 5 dégâts. » / « Deal 5 damage. » |
| `arcane_wave` | Onde / Arcane Wave | 2 | Compétence, tous | `damage` 4 | Compétence de dégâts | « Inflige 4 dégâts à tous les ennemis. » / « Deal 4 damage to all enemies. » |
| `kindle` | Embrasement / Kindle | 1 | Compétence, ennemi | `burn` 4, 3 tours | altération pure | « Applique 4 Brûlure. » / « Apply 4 Burn. » |
| `spark_barrage` | Rafale d'étincelles / Spark Barrage | 2 | Compétence, ennemi | `shock` 1, 1 tour ; puis `damage` 3, `hits` 3, `mightRatio` 0,5 | multi-coups × `shock` (O4) | « Applique 1 Électrocution, puis inflige 3 dégâts 3 fois. » / « Apply 1 Shock, then deal 3 damage 3 times. » |
| `frost_nova` | Nova de givre / Frost Nova | 2 | Compétence, tous | `freeze` 2, 1 tour | statut proportionnel | « Applique 2 Gel à tous les ennemis. » / « Apply 2 Freeze to all enemies. » |
| `discharge` | Décharge / Discharge | 3 | Compétence, ennemi | `damage` 12 ; `vulnerable` 2, 2 tours | statut proportionnel, Compétence à 3 | « Inflige 12 dégâts. Applique 2 Vulnérable pendant 2 tours. » / « Deal 12 damage. Apply 2 Vulnerable for 2 turns. » |

Contrôles : chaque mécanisme assigné (brainstorm §7, colonne P-44) a au moins une carte, et deux pour les coûts
et `scaleWith` (D12) ; chaque carte touche son `feeds` ; Σ `hits` × `mightRatio` vaut 1 partout, 1,5 ≤ 3 sur
*Rafale d'étincelles* ; aucun lot ne porte de carte à coût total nul.

### 3.5. Les neutres

| Carte | Changement |
|:---|:---|
| `focus` | **Supprimée** (D28) : `cards/focus.json` disparaît |
| `demon_form` | `cards/demon_form.json` → `cards/rage/demon_form.json`, contenu inchangé ; ses sources `card:demon_form` (ADR-104) ne changent pas |
| `ice_bolt` — Trait de Glace | Gel 1 → 2 (P-1 : l'effet d'aujourd'hui, −50 % à la prochaine attaque) ; descriptions « Inflige 4 dégâts. Applique 2 Gel. » / « Deal 4 damage. Apply 2 Freeze. » |
| Les 14 autres | Inchangées. Le noyau neutre de `0.5.7` compte **15 cartes** |

### 3.6. Les runes

Cinq fichiers sous `forge_upgrades/`, au poids 50 et au `minFusionRank` 1 (D63), avec les valeurs de §8 du
brainstorm. Chaque type de delta neuf est une sorte de `CardDelta`, écrite une fois par mécanisme (ADR-105 D1).

| id | Nom FR / EN | Delta | Par niveau | `maxLevel` | Éligibilité | Texte FR / EN |
|:---|:---|:---|:---|:---:|:---|:---|
| `piercing` | Perforant / Piercing | `armorPierce` | 25 % d'Armure ignorée, borné à 100 | 4 | `eligibleEffects: ["damage"]` | « Ignore {val} % de l'Armure de la cible » / « Ignores {val}% of the target's Block » |
| `lifesteal` | Vampirique / Vampiric | `lifestealPercent` | 20 % des dégâts infligés | 3 | `["damage"]` | « Soigne {val} % des dégâts infligés » / « Heals {val}% of the damage dealt » |
| `splash` | Ricochant / Ricocheting | `splashPercent` | 25 % de chaque coup | 3 | `["damage"]`, `eligibleTargets: ["singleEnemy"]` | « Touche aussi les autres ennemis pour {val} % des dégâts » / « Also hits the other enemies for {val}% of the damage » |
| `echo` | Résonant / Echoing | `echoChance` | 15 % de chance | 4 | `excludesEffects: ["draw", "gain_mana"]`, `excludesRunes: ["eco", "quick"]` | « {val} % de chances de se rejouer » / « {val}% chance to play again » |
| `transfusion` | Transfusion / Transfusion | `refundHpCost` | 50 % du coût en PV | 1, `binary` | `requiresCost: "hp"` | « Rend {val} % du coût en PV » / « Refunds {val}% of the HP cost » |

`{val}` rend le pourcentage du niveau (`_valueAdded`, `forge_upgrade_data.dart:275-289`, gagne les cinq sortes).
Icônes, couleurs et emojis — `navigation_rounded`/`indigoAccent`/🗡️, `water_drop_rounded`/`deepOrangeAccent`/🩸,
`scatter_plot_rounded`/`limeAccent`/💥, `replay_rounded`/`deepPurpleAccent`/🔁, `bloodtype_rounded`/`red`/💉 —
entrent dans `runeIcons` et `runeColors` (`rune_style.dart`), que garde le test d'intégrité.

**`freezing`** : `maxLevel` 1 → `null`, `valuePerLevel` 1 → 2 (A23).

`ForgeUpgradeData` gagne `eligibleTargets` (A21) et `requiresCost` (`"hp"` seulement, A20), lus par
`isEligible` ; `requiresMinCost` continue de lire le coût en mana courant (D61).

### 3.7. Les signatures : gabarits et évolutions

Chaque `classes/<classe>/skills/<id>.json` gagne `evolutions`, et ses deux descriptions deviennent des gabarits
(A25) ; remplis des valeurs de base, ils se lisent comme aujourd'hui, au « (s) » près des trois qui piochent — une donnée ne sait pas accorder :

| Signature | Gabarit FR | Gabarit EN |
|:---|:---|:---|
| `smite` | Inflige {damage} dégâts et donne {armor} d'Armure. | Deal {damage} damage and gain {armor} Block. |
| `holy_shield` | Donne {armor} d'Armure et soigne {heal} PV. | Gain {armor} Block and heal {heal} HP. |
| `reckless_strike` | Inflige {damage} dégâts. | Deal {damage} damage. |
| `rage_form` | Applique {might} Puissance ce tour-ci. Pioche {draw} carte(s). | Apply {might} Might this turn. Draw {draw} card(s). |
| `magic_missile` | Inflige {damage} dégâts et pioche {draw} carte(s). | Deal {damage} damage and draw {draw} card(s). |
| `mana_surge` | Gagne {gain_mana} Mana et pioche {draw} carte(s). | Gain {gain_mana} Mana and draw {draw} card(s). |

Une évolution :

```json
{ "id": "devastation", "tier": "major",
  "name_fr": "Dévastation", "name_en": "Devastation",
  "description_fr": "+10 dégâts, recharge allongée d'un tour",
  "description_en": "+10 damage, cooldown one turn longer",
  "deltas": [ { "type": "flatBonus", "effect": "damage", "valuePerLevel": 10 } ],
  "cooldown": 1, "excludes": ["haste"] }
```

| Clé | Règle au chargement (`SignatureEvolutionData.fromJson`, puis `SignatureData.fromJson` sur le pool) |
|:---|:---|
| `evolutions` | Exigée ; ids uniques, en `snake_case` ; au moins une mineure |
| `tier` | `minor` ou `major` |
| `name_*`, `description_*` | Les quatre, bilingues ; `{val}` vaut ce que le premier delta porteur d'un nombre ajoute au niveau de l'évolution, selon la règle de `_valueAdded` des runes (`forge_upgrade_data.dart:275-289`) — `valuePerLevel × L` pour `flatBonus`, `addEffect`, `critBonus` ; pour `reduceCost`, la baisse réelle du coût, bornée à 0, comme `_costCut` (`:282`, `:308-318`) —, que l'évolution soit chiffrée ou verbale au sens d'A25 |
| `deltas` | Sortes admises : `flatBonus`, `addEffect`, `reduceCost`, `critBonus` — celles qu'emploient les six pools ; toute autre refusée, nommée, `percentBonus` compris tant qu'aucune évolution ne l'emploie. `flatBonus` : `effect`, `valuePerLevel` > 0, `statusId` facultatif pour viser un `apply_status` |
| `target` | Majeure seulement ; `allEnemies` seulement, sur une signature `singleEnemy` (une signature sur soi enverrait ses statuts aux ennemis) |
| `cooldown` | Majeure seulement ; entier non nul ; la recharge évoluée ne descend jamais sous 1 (D54) |
| `excludes` | Majeure seulement ; ids de majeures du même pool, pas elle-même ; lu dans les deux sens |
| Au moins un changement | `deltas` non vide, `target` ou `cooldown` |
| `icon`, `color` | Exigés, deux textes non vides (A35) ; que le nom figure dans `evolutionIcons` / `evolutionColors`, le modèle ne le voit pas — les tables vivent dans `lib/ui/` — : le test d'intégrité le garde (§9), comme pour les runes |
| Chiffrée ou verbale | A25 : une évolution qui porte `addEffect`, `critBonus` ou `target` ne porte ni `flatBonus`, ni `reduceCost`, ni `cooldown` |
| Gabarits | Chaque `{…}` des deux descriptions désigne un effet propre ; chaque effet que vise un `flatBonus` du pool a son `{…}` dans les deux |

**Les six pools** — trois mineures, quatre majeures (Q6). Chiffrée : ch. ; verbale : v.

| Signature | Mineures | Majeures |
|:---|:---|:---|
| **Châtiment** (`smite`, 1, Attaque : 6 + 4 Armure) | `zeal` Zèle / Zeal — ch., `flatBonus damage 2`, « +{val} dégâts » / « +{val} damage » · `aegis` Égide / Aegis — ch., `flatBonus armor 2`, « +{val} Armure » / « +{val} Block » · `ardor` Ardeur / Ardor — v., `critBonus 5`, « +{val} % de critique » / « +{val}% critical chance » | `haste` Célérité / Haste — ch., `cooldown −1`, « Recharge réduite d'un tour » / « Cooldown one turn shorter » · `sentence` Sentence / Sentence — v., `addEffect weakness 1`, 2 tours, « Applique 1 Faiblesse pendant 2 tours » / « Apply 1 Weakness for 2 turns » · `radiance` Rayonnement / Radiance — v., `target allEnemies`, « Touche tous les ennemis » / « Hits all enemies » · `devotion` Dévotion / Devotion — ch., `reduceCost 1`, « Coûte 1 Mana de moins » / « Costs 1 less Mana » |
| **Bouclier Sacré** (`holy_shield`, 1, Compétence : 8 Armure + soin 2) | `ward` Garde / Ward — ch., `flatBonus armor 2`, « +{val} Armure » / « +{val} Block » · `mercy` Miséricorde / Mercy — ch., `flatBonus heal 1`, « +{val} PV soignés » / « +{val} HP healed » · `resolve` Résolution / Resolve — v., `addEffect might 1`, 1 tour par niveau, « Gagne {val} Puissance » / « Gain {val} Might » | `haste` · `consecration` Consécration / Consecration — v., `addEffect might 2`, 2 tours, « Gagne 2 Puissance pendant 2 tours » / « Gain 2 Might for 2 turns » · `inspiration` Inspiration / Inspiration — v., `addEffect draw 1`, « Pioche 1 carte » / « Draw 1 card » · `lasting_aegis` Égide durable / Lasting Aegis — v., `addEffect armor_regen 3`, 2 tours, « Pendant 2 tours, gagne 3 Armure au début du tour » / « For 2 turns, gain 3 Block at the start of your turn » |
| **Frappe Téméraire** (`reckless_strike`, 2, Attaque : 15) | `brutality` Brutalité / Brutality — ch., `flatBonus damage 3`, « +{val} dégâts » / « +{val} damage » · `instinct` Instinct / Instinct — v., `critBonus 5`, « +{val} % de critique » / « +{val}% critical chance » · `shatter` Fracas / Shatter — v., `addEffect vulnerable 1`, 1 tour par niveau, « Applique {val} Vulnérable » / « Apply {val} Vulnerable » | `haste` (`excludes: ["devastation"]`) · `devastation` Dévastation — ch., `flatBonus damage 10` et `cooldown +1` (`excludes: ["haste"]`) · `cleave` Fauchage / Cleave — v., `target allEnemies`, « Touche tous les ennemis » / « Hits all enemies » · `composure` Sang-froid / Composure — ch., `reduceCost 1`, « Coûte 1 Mana de moins » / « Costs 1 less Mana » |
| **Posture de Rage** (`rage_form`, 1, Compétence : Puissance 2 ce tour + pioche 1) | `anger` Colère / Anger — ch., `flatBonus apply_status might 1`, « +{val} Puissance » / « +{val} Might » · `hide` Carapace / Thick Hide — v., `addEffect armor 2`, « Gagne {val} Armure » / « Gain {val} Block » (chez lui, de la Puissance ; son icône reste le bouclier, celle de ce qu'écrit l'évolution — table des icônes, ci-dessous) · `second_wind` Second souffle / Second Wind — v., `addEffect heal 2`, « Soigne {val} PV » / « Heal {val} HP » | `haste` · `berserk` Démence / Berserk — v., `addEffect might_regen 1`, 3 tours, « Pendant 3 tours, gagne 1 Puissance au début du tour » / « For 3 turns, gain 1 Might at the start of your turn » · `rally` Ralliement / Rally — ch., `flatBonus draw 1`, « Pioche 1 carte de plus » / « Draw 1 more card » · `fury` Furie / Fury — ch., `reduceCost 1`, « Coûte 1 Mana de moins » / « Costs 1 less Mana » |
| **Projectile Magique** (`magic_missile`, 1, Compétence : 5 + pioche 1) | `acuity` Acuité / Acuity — ch., `flatBonus damage 2`, « +{val} dégâts » / « +{val} damage » · `precision` Précision / Precision — v., `critBonus 5`, « +{val} % de critique » / « +{val}% critical chance » · `ember` Braise / Ember — v., `addEffect burn 1`, 2 tours par niveau, « Applique {val} Brûlure » / « Apply {val} Burn » | `haste` (`excludes: ["overload"]`) · `overload` Surcharge / Overload — ch., `flatBonus damage 8` et `cooldown +1` (`excludes: ["haste"]`), « +8 dégâts, recharge allongée d'un tour » / « +8 damage, cooldown one turn longer » · `nova` Nova / Nova — v., `target allEnemies`, « Touche tous les ennemis » / « Hits all enemies » · `exposure` Mise à nu / Exposure — v., `addEffect vulnerable 2`, 2 tours, « Applique 2 Vulnérable pendant 2 tours » / « Apply 2 Vulnerable for 2 turns » |
| **Surtension de Mana** (`mana_surge`, 0, Compétence : +1 Mana + pioche 1) | `mana_shield` Bouclier de mana / Mana Shield — v., `addEffect armor 2`, « Gagne {val} Armure » / « Gain {val} Block » · `attunement` Harmonie / Attunement — v., `addEffect might 1`, 1 tour par niveau, « Gagne {val} Puissance » / « Gain {val} Might » · `clarity` Clarté / Clarity — v., `addEffect heal 1`, « Soigne {val} PV » / « Heal {val} HP » | **pas de *Célérité*** (§1.3) · `foresight` Prescience / Foresight — ch., `flatBonus draw 1`, « Pioche 1 carte de plus » / « Draw 1 more card » · `glyph` Glyphe de garde / Ward Glyph — v., `addEffect armor_regen 3`, 2 tours, « Pendant 2 tours, gagne 3 Armure au début du tour » / « For 2 turns, gain 3 Block at the start of your turn » · `empower` Exaltation / Exaltation — v., `addEffect might 2`, 2 tours, « Gagne 2 Puissance pendant 2 tours » / « Gain 2 Might for 2 turns » · `serenity` Sérénité / Serenity — v., `addEffect heal 4`, « Soigne 4 PV » / « Heal 4 HP » |

`haste` porte dans chaque pool le même id et le même texte : il reste propre à chaque signature (D7), déclaré
dans son fichier.

**Les icônes** (A35) — une par sorte d'effet, la même d'un pool à l'autre : quinze icônes, quatorze couleurs, pour
les 42 évolutions.

| Ce que fait l'évolution | `icon` | `color` | Évolutions |
|:---|:---|:---|:---|
| + dégâts | `gavel_rounded` | `redAccent` | `zeal`, `brutality`, `acuity` |
| + Armure, ou Armure ajoutée | `shield_rounded` | `blueAccent` | `aegis`, `ward`, `hide`, `mana_shield` |
| + soin, ou soin ajouté | `favorite_rounded` | `greenAccent` | `mercy`, `second_wind`, `clarity`, `serenity` |
| + critique | `gps_fixed_rounded` | `amber` | `ardor`, `instinct`, `precision` |
| + Puissance, ou Puissance ajoutée | `fitness_center_rounded` | `orangeAccent` | `resolve`, `anger`, `attunement`, `consecration`, `empower` |
| Éveil de Puissance (`might_regen`) | `trending_up_rounded` | `orangeAccent` | `berserk` |
| Armure au début du tour (`armor_regen`) | `autorenew_rounded` | `lightBlueAccent` | `lasting_aegis`, `glyph` |
| Faiblesse | `arrow_downward_rounded` | `purpleAccent` | `sentence` |
| Vulnérable | `heart_broken_rounded` | `pinkAccent` | `shatter`, `exposure` |
| Brûlure | `local_fire_department_rounded` | `deepOrangeAccent` | `ember` |
| Pioche | `style_rounded` | `amberAccent` | `inspiration`, `rally`, `foresight` |
| Recharge réduite (*Célérité*) | `fast_forward_rounded` | `tealAccent` | `haste` (cinq pools) |
| Dégâts accrus, recharge allongée | `bolt_rounded` | `yellowAccent` | `devastation`, `overload` |
| Touche tous les ennemis | `all_out_rounded` | `deepPurpleAccent` | `radiance`, `cleave`, `nova` |
| Coûte moins | `savings_rounded` | `cyanAccent` | `devotion`, `composure`, `fury` |

### 3.8. Les comptes

| Quoi | Avant (`0.5.6`) | Après |
|:---|:---:|:---:|
| `registry.cards` — neutres / de lot | 17 / 0 | 15 / 18 |
| `registry.forgeUpgrades` | 11 | 16 |
| `registry.passives`, `registry.signatures` | 9, 6 | 9, 6 |
| Fichiers d'entité (`entity_id_convention_test.dart:65-73`) | 94 | **115** |
| Sources de chargement (`entity_descriptor_test.dart:34-35`) | 9 | 10 |

---

## 4. Le moteur

### 4.1. Les coûts combinés — tâche à risque

**`canAfford(card, heroStats)`** (A10), vraie si et seulement si :

1. `heroStats.currentMana ≥ card.currentCost` — le mana courant, runes appliquées (`card_instance.dart:24`) ;
2. `card.data.hpCost == 0` **ou** `heroStats.currentPv > card.data.hpCost` — strictement : une carte ne tue jamais
   son porteur (D40), comme le faisait le chemin en pourcentage (`player_stats_manager.dart:503-506`) ;
3. `heroStats.armure ≥ card.data.armorCost`.

`canPlayCard` (`effect_resolver.dart:104-119`) = `canAfford` et les deux règles d'aujourd'hui (statut, cible).
La rareté ne lit jamais `hpCost` ni `armorCost` (D40) ; aucune rune ne les touche : `cheap` réduit le mana
(`ReduceCostDelta`), `transfusion` rembourse après coup.

**Le paiement**, dans `resolveCard`, à la place de `consumeResource(mana:)` (`effect_resolver.dart:134`) :
`consumeResource({int mana = 0, int hp = 0, int armor = 0})` débite les trois en **une seule** écriture d'état —
mana, `currentPv`, `armure`. Ni `takeDamage`, ni absorption, ni critique, ni vol de vie, ni événement
`onDamageTaken` (*Ferveur* ne voit pas l'Armure dépensée), ni soin négatif (brainstorm §12 : le soin passe par le
critique, `strategies.dart:97-100`). Le paramètre `hpPercent` (`player_stats_manager.dart:501`) n'a aucun appelant
dans `lib/` ni dans `test/` : il disparaît.

**L'ordre d'un jeu de carte** : (1) `canPlayCard`, faux → `false`, rien n'est écrit ; (2) le paiement ; (3) les
effets (§4.7) ; (4) l'écho ; (5) le remboursement de `transfusion`. Une carte refusée ne paie rien ; une carte
payée se résout jusqu'au bout.

| Cas limite | Résultat |
|:---|:---|
| PV = coût en PV | Refusée |
| PV = coût + 1 | Jouée ; le héros finit à 1 PV |
| Armure = coût en Armure | Jouée ; Armure 0 |
| Berserker et `costs.armor` | Impossible en donnée (A7) ; une telle carte serait toujours refusée |
| Coût en PV sous *Rage* | Les PV perdus comptent dans la Puissance du tour suivant |
| `cheap` sur une carte à `costs` | Réduit le seul mana ; `requiresMinCost` lit le mana (D61) — *Percée*, à 0, ne reçoit ni `cheap` ni `eco` |
| `transfusion`, coût 3 | Rend 2 (demie vers le haut), jamais au-delà des PV max |

Le refus à l'écran reste le geste d'aujourd'hui — secousse et son (`card_interaction_handler.dart:134-139`,
`heros_draft_game.dart:328-331`) — ; la ressource qui manque se lit sur son médaillon, en rouge (§5.2).

### 4.2. `scaleWith`

| Source | Quantité, lue au moment de l'effet | Portée |
|:---|:---|:---|
| `armor` | `armure` du héros | Calculée une fois par effet |
| `missingHp` | `maxPv − currentPv` du héros | Une fois par effet |
| `cardsPlayedThisTurn` | Cartes et signatures jouées avant celle-ci ce tour (A12) | Une fois par effet |
| `enemiesAlive` | Ennemis actifs à `currentPv > 0` | Une fois par effet |
| `targetStatus` | Somme des valeurs du statut `statusId` sur la cible | Carte `singleEnemy` seulement |
| `targetMissingHp` | `maxPv − currentPv` de la cible | Carte `singleEnemy` seulement |

Les effets se résolvent dans l'ordre : l'Armure d'un effet précédent de la même carte compte pour le suivant.
*Fortification* lit l'Armure avant de donner la sienne. Seules `armor` et `missingHp` ont une carte en `0.5.7` ;
les quatre autres sont prouvées par les tests unitaires, pour les lots qui les attendent (brainstorm §7). Une
source par type de carte (*Frénésie sanglante*, « par Attaque jouée ») s'ajoutera, si son lot la veut, comme un
filtre de la source.

### 4.3. Multi-coups et `mightRatio`

`DamageEffectStrategy` (`strategies.dart:16-80`) boucle sur `hits`. Pour chaque coup, et pour chaque cible —
l'ennemi choisi s'il vit, ou chaque ennemi vivant pour `allEnemies` — : dégâts initiaux = valeur jouée (rareté,
runes, terme `scaleWith`) + `floor(damageBonusFor(type) × mightRatio)` (A13) ; puis le pipeline, dont le critique
et l'Électrocution par coup ; puis l'absorption, `piercing` compris ; puis l'éclaboussure (A17). Un coup ne
tombe que sur une cible vivante : sur une cible unique morte, les coups restants sont perdus. Le vol de vie
(statut et rune) se paie une fois, après tous les coups.

Une rune en pourcentage sur un effet à plusieurs coups suit A14.

### 4.4. Les statuts proportionnels (barème de P-1, §1.2)

| Statut | Lecture d'aujourd'hui | Avec le lot |
|:---|:---|:---|
| `vulnerable` | Tout ou rien, +50 % (`damage_pipeline.dart:50-54`) | +25 % de dégâts subis par point, 4 points au plus |
| `weakness` | Tout ou rien, −25 % (`damage_pipeline.dart:18-22`) | −25 % de dégâts infligés par point, 2 points au plus |
| `freeze` | Tout ou rien, intention × 0,5 (`enemy_instance.dart:28-30`) | −25 % à l'attaque par point, 3 points au plus |

Arrondi au plus proche, comme aujourd'hui. Les durées ne changent pas : le Gel s'use d'une attaque par attaque
(`turn_phase_manager.dart:116-128`) et ne vieillit pas au tic (`entity_stats.dart:145-147`). Le point se lit sur la
somme des entrées de même id. La Puissance « altération » (`power_rules.dart:27-32`) ajoute désormais des points à
ces trois statuts. Recalibrés pour garder leur effet au premier usage : *Trait de Glace* (§3.5), `freezing`
(§3.6), *Marque du Mage* (§3.3). Le barème vit en un seul endroit, à côté du pipeline — par statut, le
pourcentage par point et le plafond en points —, que lisent le pipeline, l'intention effective et les textes : les
parenthèses des deux infobulles (§5.2) et la galerie et le tableau des statuts du tutoriel (§6.2) passent ces deux
nombres, et le plafond en pourcentage qu'ils donnent, aux clés paramétrées de §6.1 ; aucun de ces textes n'écrit
plus un pourcentage en dur, et le corps des étapes du tutoriel qui décrivent le Gel ne le chiffre plus (§6.2).

### 4.5. Un seul bonus de Puissance de statut par résolution (Q11)

A15. Le bonus reste celui de `statusBonusFor` : il ne vise qu'un statut posé sur un ennemi, jamais une durée ; à
chaque résolution, seul le premier `apply_status`, tous statuts confondus, le reçoit. Un écho (§4.6) est une
seconde résolution : son premier `apply_status` reçoit son propre bonus (C1.1).

### 4.6. Les cinq runes

| Rune | Lecteur | Règle |
|:---|:---|:---|
| `piercing` | `takeDamage(…, armorPiercePercent:)` (A16) | Armure ignorée = `min(A, max((p × A + 50) ~/ 100, L))`, `A` l'Armure de la cible au coup, `p = min(100, 25 × L)` : la demie vers le haut, en arithmétique entière, et le plancher « au moins +L » de D33 borné par l'Armure présente — comme `lifesteal` (A18) *(T, filtre 1)* ; la part non ignorée absorbe comme aujourd'hui. `armorPierce` est saturée à `p = 100`, soit L ≥ 4 (A22) |
| `lifesteal` | `DamageEffectStrategy`, après les coups | A18 : `min(D, max((20 × L × D + 50) ~/ 100, L))`, `D` les dégâts infligés, si `D ≥ 1` ; `lifestealPercent` est saturée à L ≥ 5, le soin valant alors les dégâts (A22) |
| `splash` | `DamageEffectStrategy`, à chaque coup | A17 |
| `echo` | `resolveCard`, après les effets | A19 : jet de `15 × L` % sur un générateur injectable (`resolveCard` gagne un `Random` facultatif, pour les tests) ; `echoChance` est saturée à L ≥ 7, la chance valant alors 100 % (A22) |
| `transfusion` | `resolveCard`, en dernier | A20 |

`EffectiveCard` (`effective_card.dart:11-95`) expose les cinq lectures, sommées sur les deltas.

### 4.7. La résolution d'une carte, en entier

1. `canPlayCard` (§4.1) ; 2. le paiement ; 3. pour chaque effet, ceux des runes puis ceux de la carte : valeur
jouée + terme `scaleWith` (A11) ; pour un `apply_status`, + le bonus de statut s'il est le premier
`apply_status` de la résolution (A15) ; puis la stratégie du registre ; 4. l'écho ; 5. `transfusion` ; puis, côté contrôleur, la
pile (`deckController.playCard`) et la suite commune, qui compte la carte jouée (A12). Une signature suit 1 à 5
par sa vue de carte, sans pile (spec E4, §4.3).

### 4.8. L'offre et le masquage — tâche à risque

**`availablePassivesFor(hero, registry)`** (`passive_availability.dart:18-29`) rend les passifs qui vérifient
**les deux** conditions, triés comme aujourd'hui par `(displayOrder, id)` :

1. éligibles à la classe : `passive.classes?.contains(hero.id) ?? true` — inchangé ;
2. **pourvus d'un lot** : au moins une carte de `registry.cards` porte `passive == passive.id`, quel que soit son
   type.

Le commentaire de la fonction cesse de dire « débloqué vaut tous » : la disponibilité vaut « éligible et pourvu
d'un lot », et P-13 y ajoutera le déblocage. Aucune liste de passifs n'est écrite nulle part.

| Cas | Résultat |
|:---|:---|
| Registre livré, `0.5.7` | Une disponibilité par classe : `regen_armor`, `rage`, `mana_flux` |
| Classe dont aucun passif n'a de lot | Liste vide — le test d'intégrité « chaque classe a au moins un passif disponible » (`referential_integrity_test.dart:144`) l'interdit dans la donnée livrée |
| Carte de lot d'un autre passif | N'ouvre pas celui-ci |
| Écran de sélection, tutoriel | Lisent la même fonction (`class_selection_screen.dart:379`, `tutorial_fixtures.dart:63-64`) : un seul passif par classe ; le Mage démarre sur *Flux de Mana*, y compris au tutoriel (`tutorial_engine.dart:138-146`) |
| Sauvegarde dont le passif est masqué | Le passif se relit par `PassiveData.getById` (`run_controller.dart:188-200`), qui ne lit pas la disponibilité : la run reprend avec lui |
| Récompense *Affinité*, Maîtrise | Lisent le passif actif, inchangé |

**L'offre** : `isOfferable(activePassiveId)` (A3). Trouvaille, boutique, draft de départ et `starterPool`
proposent les neutres et le seul lot du passif actif ; le Miroir, la copie du deck et le boss « cartes » lisent
le deck, comme avant.

**Les registres de test** : un registre construit à la main qui attend un passif disponible lui donne au moins
une carte de lot. Le plan les mesure (`git grep` des lecteurs de `availablePassivesFor` sous `test/`) ; les tests
du registre réel qui attendent trois passifs par classe (`passives_paladin_test.dart:210`,
`passives_berserker_test.dart:252`, `passives_mage_test.dart:365`, tutoriel) sont réécrits sur la disponibilité
livrée.

### 4.9. Le draft de départ (Q9)

`StarterDeckDraftScreen` (`starter_deck_draft_screen.dart:51-113`) : le pool est `isOfferable(passive.id)`, trié
par `compareByDisplayOrder`, séparé en **lot** (`passive != null`) et **neutres**. Le joueur choisit exactement
`quotaLot = min(2, taille du lot)` cartes du premier groupe et `5 − quotaLot` du second ; choisir au-delà d'un
quota refuse et notifie, comme le plafond de 5 aujourd'hui (`:68-85`). « Valider » s'active quand les deux quotas
sont atteints. Le deck de départ : les cinq cartes choisies, rien d'autre (E4). Le tutoriel suit (A30).

### 4.10. Les évolutions

**`SignatureInstance(data, {evolutions})`** — `evolutions` : des références `id:niveau`, dans l'ordre de la
première prise, lues par l'analyseur unique `ForgeUpgradeData.parseRef` / `levelsOf`
(`forge_upgrade_data.dart:365-384`). Lectures :

| Lecture | Règle |
|:---|:---|
| `level` | Somme des niveaux de ses évolutions |
| `taken` | La liste ordonnée, par première prise, des paires (`SignatureEvolutionData`, niveau) — les références relues dans le pool de la signature une fois pour toutes ; `asCard` en tire ses deltas, sa cible et ses phrases, la tuile ses puces (A37) — le badge lit `level` (A36) : aucun widget n'analyse une référence ni ne cherche dans le pool |
| `asCard` | La vue d'E4 ; sa cible est celle de la dernière majeure `target` prise, sinon la sienne ; ses `extraDeltas`, les deltas des évolutions à leur niveau, dans l'ordre (A24) ; sa description, le gabarit rempli suivi des phrases verbales (A25) |
| `cost` | `asCard.currentCost` — `asCard` construit sa `CardData` sur `data.cost`, le coût de la donnée, et le delta `reduceCost` des évolutions le réduit par `effective` ; il ne lit plus `cost` (`signature_instance.dart:27` le lit aujourd'hui, `:12` rendant `data.cost`), sans quoi les deux lectures s'appelleraient l'une l'autre |
| `cooldown` | `max(1, data.cooldown + Σ cooldown des majeures prises)` |
| `pendingFor(heroLevel)` | `max(0, heroLevel ~/ 5 − level)` (A27) |
| `nextTier` | Mineure si `level + 1` est impair (niveaux de héros 5, 15, 25…), majeure sinon (10, 20, 30…) — D21 |

**Le tirage**, `SignatureEvolutionRules.offer(signature, rng)`, fonction pure : A26, sans poids, sans remise. Une
majeure est éligible si elle n'est pas prise et qu'aucune majeure prise ne l'exclut ni n'est exclue par elle.

**Le choix**, `RunController.chooseSignatureEvolution(signatureId, evolutionId) → bool` : refuse sans rien
écrire si la signature n'est pas de la run, si elle n'attend rien, si l'évolution n'est pas de son pool, ou si elle
n'est pas admissible au palier — une mineure au palier mineur ; au palier majeur, une majeure éligible, ou une
mineure quand il reste moins de trois majeures éligibles. Sinon : une mineure déjà prise monte d'un niveau à sa
place, toute autre entre à `id:1` à la fin ; puis `checkpointProvider.bump()`, comme `decrementPendingDrafts`
(`player_stats_manager.dart:156-165`) — la sauvegarde suit chaque choix.

**L'ordre des attentes**, `RunState.nextPendingEvolution` : la signature dont le prochain niveau est le plus bas,
à égalité dans l'ordre de `HeroData.skills`. Au niveau 5 : Châtiment, puis Bouclier Sacré ; à un saut de 4 à 10 :
les deux mineures, puis les deux majeures.

---

## 5. Les écrans

### 5.1. L'écran d'évolution

`lib/ui/screens/signature_evolution_screen.dart` — un écran propre (D19), sur le patron de `DraftScreen`
(`draft_screen.dart:24-35`) et ses trois `DraftCardReel` (`relic_carousel/draft_card_reel.dart:11-37`), survol à
1,05 et sélection à 1,12 avec halo ambre (`_rules/03-10`). Il reçoit la signature qui attend.

| Élément | Contenu |
|:---|:---|
| En-tête | « Évolution de {signature} » / « {signature} evolves », puis « Choisissez une évolution » / « Choose an evolution » |
| Un rouleau par évolution tirée | `title` : son nom ; `description` : sa description à son prochain niveau, et, pour une mineure déjà prise, une dernière ligne « Niveau 1 → 2 » / « Level 1 → 2 » ; `rarity` : son palier, « MINEURE » / « MAJEURE » — un libellé que le rouleau ne reconnaît ni légendaire ni mythique, donc au style ordinaire |
| Icône du rouleau *(P-4, §1.2)* | Voir le paragraphe ci-dessous |
| Décor du rouleau (`spinPool`) | Les évolutions du pool de la signature, nom et description |
| Toucher un rouleau posé | `chooseSignatureEvolution`, puis retour à la carte |

Le tirage se fait à l'ouverture, comme celui du draft de niveau (`draft_screen.dart:105-118`) : rien n'est retenu
entre deux ouvertures. **Le rideau de la carte** (`map_screen.dart:302-316`) s'affiche tant que
`pendingDrafts > 0` ou qu'une évolution attend ; le toucher ouvre d'abord le draft de niveau s'il en reste un,
sinon l'évolution de `nextPendingEvolution`. Chaque écran fermé rend la carte ; le rideau, toujours là, ouvre le
suivant : deux écrans successifs au niveau 5. Les deux gardes de nœud (`:380`, `:403`) lisent la même condition,
un accesseur de `RunState`.

**L'icône sur le rouleau** (P-4, §1.2) : l'icône de l'évolution, à sa couleur,
au-dessus du nom — dans l'anneau pour une majeure, comme sur la tuile (A37) —, posée une fois le rouleau arrêté.
`DraftCardReel` (`relic_carousel/draft_card_reel.dart:11-37`) gagne un paramètre facultatif, l'icône et sa couleur,
qu'il passe à `DraftChoiceCard`, qui dessine le titre du rouleau arrêté (`:294-295`) et gagne le même paramètre
facultatif ; le draft de niveau ne le passe pas, ni le tutoriel, qui emploie aussi `DraftChoiceCard`
(`tutorial_draft_widget.dart:130`) : ni l'un ni l'autre ne change.

### 5.2. Les cartes

| Rendu | Changement | Partie |
|:---|:---|:---:|
| Parenthèses des statuts — infobulle Flutter (`ui_card_helpers.dart:374-404`) et infobulle Flame (`card_component.dart:371-401`) | Faiblesse, Vulnérable et Gel disent le barème par point, par les clés paramétrées de §6.1 remplies depuis le barème (§4.4) ; les deux infobulles perdent leurs pourcentages en dur | 1 |
| La galerie et le tableau des statuts du tutoriel | Lisent les mêmes clés et le même barème : §6.2 | 1 |
| Médaillon de coût — `CardManaMedallion` (Flutter), `CardComponent` (Flame) | Un médaillon de plus par coût non nul : PV (goutte rouge) et Armure (écu acier), à côté du mana ; en combat, le médaillon d'une ressource qui manque passe au rouge, comme le mana (`card_component.dart:53-60`) | 2 |
| Badge de dégâts — `CardCompactDescription` (Flutter) et `CardTextRenderer` (Flame, `card_text_renderer.dart:96-110`) | `valeur×coups` pour un multi-coups (`3×3`) ; la Puissance ajoutée par coup est `floor(bonus × mightRatio)` (A13), là où le badge Flame ajoute aujourd'hui `damageBonusFor` entier (`:96`) ; la valeur d'un effet à `scaleWith` d'une source du héros inclut le terme calculé sur l'état courant quand le héros est connu (combat), la valeur de base sinon | 2 |
| Infobulle Flutter (`ui_card_helpers.dart:338-412`) | La ligne de coût dit PV et Armure en plus du mana ; la ligne de dégâts dit les coups (`cardDescDamageHits`) et la Puissance par coup ; une ligne de croissance par `scaleWith` (§6.1) | 2 |
| Infobulle Flame (`card_component.dart:296-298`, `:326-336`) | Mêmes lignes : la ligne de coût, aujourd'hui `'$costHeader${card.currentCost} Mana'` (`:298`), ajoute `cardCostHp`, `cardCostArmor` ; les lignes de dégâts (`:329-336`), qui ajoutent aujourd'hui `damageBonus` entier, passent à `floor(bonus × mightRatio)` par coup et à `cardDescDamageHits` ; la ligne de croissance | 2 |
| Tuile de combat (`_SignatureTile`, `hud/signature_bar.dart:126-410`) | Lit `SignatureInstance` : coût, recharge, cible et description évolués ; la description n'est plus bornée à deux lignes (`:270`), la tuile suit son contenu. Par P-2 (c) : le badge de niveau au bout de la ligne du type (A36), la rangée d'icônes sous la description et au-dessus du compte de recharge (A37). États : **inactive**, toute la tuile à 0,45 comme aujourd'hui, icônes et badge compris ; **en recharge** et **sans le mana**, icônes, anneaux, chiffres de niveau des mineures et badge passent au gris pâle du texte (`Colors.white38`), comme le nom ; **disponible** et **armée**, à leurs couleurs. Ni toucher ni survol propres aux icônes : la tuile seule répond, et aucune infobulle ne revient (O4 de la vague 4). La barre : A38 | 3 |
| Tuile hors combat (`SignatureTile`, `signature_tile.dart`) | Carte de classe et dictionnaire : la signature de base, le gabarit rempli des valeurs du fichier, **sans badge ni icône** — hors d'une run, elle n'a pas d'évolution (`signature_tile.dart:7-8` lit la donnée, jamais une instance) | 3 |
| Dictionnaire | Inchangé : les cartes de lot y sont rangées avec les autres. Aucun regroupement par lot n'est ajouté (filtre 7) | — |

### 5.3. Le draft de départ

Deux sections dans la grille, titrées « Cartes de {passif} » et « Cartes neutres », chacune avec son compteur
(`2/2`, `3/3`) ; les sous-titres et la notification de quota au §6.

---

## 6. Textes joueur

### 6.1. Clés ARB (`app_fr.arb`, `app_en.arb`)

| Clé | Français | English |
|:---|:---|:---|
| `draftDeckSubtitle` *(réécrite ; « 5 cartes globales » était périmé depuis E4)* | Choisissez 2 cartes de votre passif et 3 cartes neutres pour constituer votre deck de départ. | Pick 2 cards from your passive and 3 neutral cards to build your starting deck. |
| `draftDeckLotSection` | Cartes de {passive} | {passive} cards |
| `draftDeckNeutralSection` | Cartes neutres | Neutral cards |
| `draftDeckQuota` | {picked}/{quota} | {picked}/{quota} |
| `draftDeckSnackbarMaxLot` | Vous avez déjà choisi vos {quota} cartes de passif. | You already picked your {quota} passive cards. |
| `draftDeckSnackbarMaxNeutral` | Vous avez déjà choisi vos {quota} cartes neutres. | You already picked your {quota} neutral cards. |
| `cardCostHp` | Coûte {amount} PV | Costs {amount} HP |
| `cardCostArmor` | Coûte {amount} Armure | Costs {amount} Block |
| `cardDescDamageHits` | Inflige {amount} dégâts {hits} fois. | Deal {amount} damage {hits} times. |
| `cardScaleArmor` | +{ratio} par point d'Armure | +{ratio} per point of Block |
| `cardScaleArmorPer` | +1 par tranche de {per} d'Armure | +1 per {per} Block |
| `cardScaleMissingHp` | +{ratio} par PV manquant | +{ratio} per missing HP |
| `cardScaleMissingHpPer` | +1 par tranche de {per} PV manquants | +1 per {per} missing HP |
| `cardScaleCardsPlayed` | +{ratio} par carte jouée ce tour | +{ratio} per card played this turn |
| `cardScaleCardsPlayedPer` | +1 par tranche de {per} cartes jouées ce tour | +1 per {per} cards played this turn |
| `cardScaleEnemiesAlive` | +{ratio} par ennemi | +{ratio} per enemy |
| `cardScaleEnemiesAlivePer` | +1 par tranche de {per} ennemis | +1 per {per} enemies |
| `cardScaleTargetStatus` | +{ratio} par point de {status} de la cible | +{ratio} per point of {status} on the target |
| `cardScaleTargetStatusPer` | +1 par tranche de {per} points de {status} de la cible | +1 per {per} points of {status} on the target |
| `cardScaleTargetMissingHp` | +{ratio} par PV manquant de la cible | +{ratio} per missing HP on the target |
| `cardScaleTargetMissingHpPer` | +1 par tranche de {per} PV manquants de la cible | +1 per {per} missing HP on the target |
| `statusWeaknessHint` | −{percent} % de dégâts infligés par point, jusqu'à −{max} % | −{percent}% damage dealt per point, down to −{max}% |
| `statusVulnerableHint` | +{percent} % de dégâts subis par point, jusqu'à +{max} % | +{percent}% damage taken per point, up to +{max}% |
| `statusFreezeHint` | −{percent} % à la prochaine attaque par point, jusqu'à −{max} % | −{percent}% to the next attack per point, down to −{max}% |
| `evolutionScreenTitle` | Évolution de {signature} | {signature} evolves |
| `evolutionScreenSubtitle` | Choisissez une évolution | Choose an evolution |
| `evolutionTierMinor`, `evolutionTierMajor` | MINEURE, MAJEURE | MINOR, MAJOR |
| `evolutionLevelUp` | Niveau {from} → {to} | Level {from} → {to} |
| `levelLabel` *(réécrite : « Niv {level} » / « Lvl {level} », `app_fr.arb:176`, `app_en.arb:446`, prend le point de l'abréviation du jeu ; aucune clé neuve, et elle gagne son premier lecteur, le badge, A36)* | Niv. {level} | Lvl. {level} |

Chaque source a ses deux formes : un ratio inférieur à 1 s'écrit en tranches, par la clé `…Per`
(`per = 1 / ratio`, entier par la règle de chargement d'A11 : 5 pour *Fortification* et *Dernier souffle*, 10
pour *Fureur sanguine*) ; un ratio d'au moins 1 s'écrit tel quel (*Rempart brisé* : « +1 par point d'Armure »).
Les trois clés `status…Hint` remplacent les textes en dur des deux infobulles (`ui_card_helpers.dart:374-404`,
`card_component.dart:371-401`), qui les mettent entre parenthèses, et ceux de la galerie et du tableau des statuts
du tutoriel (§6.2) ; `percent` et `max` viennent du barème (§4.4) — sous P-1 (a), §1.2 : 25 et 50, 25 et
100, 25 et 75.

**Le draft de départ** : `draftDeckSnackbarMax` (`app_fr.arb:227`, lu à `starter_deck_draft_screen.dart:79`)
disparaît — le total de 5 ne se dépasse plus sans dépasser un quota, et les deux notifications de quota le
remplacent ; `draftDeckSelectedCount` (`app_fr.arb:225`, lu à `:130`) reste le compteur total que
`CardDraftLayout` affiche sous la grille, à côté des deux compteurs de section.

### 6.2. Le tutoriel

| Où | Changement |
|:---|:---|
| Étape « Votre deck de départ » (`tutorial_data.dart:43`) | FR : « Choisissez 2 cartes du lot de votre passif et 3 cartes neutres : elles forment votre deck de départ, celui avec lequel vous jouerez le reste du tutoriel. » — EN : « Pick 2 cards from your passive's set and 3 neutral cards: they form your starting deck, the one you will play the rest of the tutorial with. » La suite du texte, sur les signatures, ne change pas |
| `tutorial_starter_deck_widget.dart:55` | « Choisissez 5 cartes » → les deux sections et leurs compteurs, comme le jeu |
| `TutorialFixtures.starterPool` | `isOfferable(activePassive?.id)` |
| Leçon de jeu (`tutorial_engine.dart:247-258`) | A30 |
| La galerie des statuts (`tutorial_elements_widget.dart:65-66`, Gel « 50% ») et le tableau des statuts qu'elle ne montre pas (`_missingStatuses`, `:78-80` ; `:86-87`, Vulnérable « +50 % », `:94-95`, Faiblesse « −25 % »), affichés par `tutorial_screen.dart:112` | Gel, Vulnérable et Faiblesse lisent `statusFreezeHint`, `statusVulnerableHint`, `statusWeaknessHint` sur le barème (§4.4), au lieu de leurs pourcentages en dur ; les entrées cessent d'être `const` ; partie 1, avec le barème. La simulation de la galerie (`tutorial_elements_widget.dart:221`, « 10 -> 5 ») reste juste : deux points de Gel sous (a), ce que pose *Trait de Glace* (§3.5) |
| Le corps des étapes « Les Effets Élémentaires » (`tutorial_data.dart:227-228`, `:236-237`) et « Les Intentions Ennemies » (`:255`, `:267-268`) | Le Gel ne se chiffre plus dans la prose, la galerie le chiffre. FR : « • ❄️ Gel : réduit leur prochaine attaque, d'autant plus qu'il compte de points, jusqu'à un plafond. La durée ne décrémente qu'une fois qu'ils ont attaqué. » — EN : « • ❄️ Freeze: reduces their next attack, more with each point, up to a cap. The duration only ticks down once they have attacked. » ; et FR « …et baisse tant qu'il est Gelé. » — EN « …and drops while they are Frozen. » ; partie 1, avec le barème |

---

## 7. L'éditeur de contenu

| Élément | Changement | Partie |
|:---|:---|:---:|
| Descripteur de rune (`entity_descriptor.dart`) | Connaît `eligibleTargets` (énumération `CardTarget`), `requiresCost` (`hp` seulement) et les cinq sortes de delta neuves, lues sur `CardDelta.typeNames` | 1 |
| Descripteur de carte (`:210-238`) | Neutre seulement ; `forbiddenKeys` gagne `passive` ; connaît `costs` (`mana`, `hp`, `armor`), `effects[].hits`, `effects[].mightRatio`, `effects[].scaleWith.source` (énumération lue sur le modèle) | 2 |
| **`EntityCategory.lotCard`**, « Carte de lot » (A31) | Chemin `cards/<passif>/<id>.json` ; la propriété de la signature, `supportsHeroClass`, devient une propriété à deux sortes — classe pour la signature, passif pour la carte de lot — : catalogue par propriétaire (`entity_catalog.dart:7-83`), choix du propriétaire à l'écran, propriétaire exigé et existant ; `construct` reçoit le document augmenté de `passive`, jamais écrit dans le fichier — le précédent de `heroClass` (spec E4, §8) ; mêmes clés que la carte | 2 |
| Validateur | Pour une carte de lot, la fonction pure d'A6 et A7 : `feeds` touché, `costs.armor` refusé sous une classe qui convertit l'armure | 2 |
| Descripteur de passif | `feeds`, liste exigée | 2 |
| Descripteur de signature | `evolutions` et leurs clés ; `evolutions[].tier`, `evolutions[].target`, `evolutions[].deltas[].type` en énumérations lues sur le modèle ; `evolutions[].icon` et `evolutions[].color` en clés de vocabulaire, admises si un fichier livré les emploie déjà — la forme d'`icon` et `color` des runes (`entity_descriptor.dart:376-390`), qui ne lit pas les tables de `lib/ui/` | 3 |
| `entity_descriptor_test.dart:17-36` | Dix catégories, dix sources | 2 |

---

## 8. La sauvegarde — tâche à risque

**Aucune migration, `schemaVersion` inchangé.** Un seul champ neuf, dans `RunState.toJson`
(`run_controller.dart:164-181`) :

```json
"signatureEvolutions": { "smite": ["zeal:2", "sentence:1"], "holy_shield": ["ward:1"] }
```

**L'écriture** : une clé par signature qui porte au moins une évolution, sa liste `evolutions` telle quelle ; une
signature sans évolution n'écrit rien.

**La lecture**, dans `fromJsonWithReport` (`run_controller.dart:183-238`), après que les signatures sont relues de
la classe (`_signaturesOf`, `:244-251`), dans cet ordre, pour chaque signature :

1. la liste de sa clé, absente → aucune évolution ;
2. chaque référence passe par `parseRef` ; mal formée ou de niveau ≤ 0 → ignorée, sans rapport ;
3. un id absent du pool de la signature → retiré, et un `MissingSaveItem(id, nameFr: id, nameEn: id, category:
   'signatureEvolution')` rejoint le rapport ;
4. les références de même id se réunissent, niveaux additionnés (`levelsOf`) ; une majeure est ramenée au niveau
   1 ;
5. une majeure exclue par une majeure gardée avant elle, dans un sens ou dans l'autre, est retirée — la première
   arrivée est gardée, comme `consolidate` (`forge_rune_rules.dart:32-45`) ;
6. la signature est reconstruite avec la liste qui reste, dans l'ordre lu.

Seule l'étape 3 écrit dans le rapport. Une majeure ramenée à 1 (étape 4) ou retirée pour exclusion (étape 5) n'y
entre pas *(T, filtre 6)* : le rapport s'affiche au joueur comme « des éléments ne sont plus disponibles suite à
une mise à jour » (`missingItemsMessage`, `app_fr.arb:162`), ce qui serait faux pour une évolution qui existe
toujours et qu'une sauvegarde incohérente portait mal ; ces deux cas ne naissent que d'une sauvegarde écrite à la
main ou par un build fautif.

| Cas | Résultat |
|:---|:---|
| Sauvegarde de `0.5.6`, sans la clé | Aucune évolution ; au niveau ≥ 5, le rideau propose les choix dus — ce qui est le jeu |
| Une clé pour une signature que la classe ne porte plus | Ignorée |
| Plus de niveaux d'évolution que le niveau n'en donne (menu de debug) | Gardés ; `pendingFor` vaut 0 |
| Abandon au milieu d'une série | Les choix faits sont sauvés un à un (§4.10) ; la reprise propose ceux qui restent |

La recharge reste hors de la sauvegarde (spec E4, §4.2). Une partie de `0.5.6` dont le deck porte `focus` reprend
sans elle, signalée manquante (`deck_controller.dart:72-99`) ; ni test ni protection pour le reste : avant la
`1.0.0`, les sauvegardes ne se transfèrent pas.

---

## 9. Tests

| Sujet | Fichier | Ce qu'il verrouille | Partie |
|:---|:---|:---|:---:|
| **Coûts — tâche à risque** | `test/unit/card_costs_test.dart` *(nouveau)* | `fromJson` : `cost` et `costs` ensemble refusés ; `costs` sans `mana`, sans `hp` ni `armor`, avec `discard`, ou à `hp: 0` refusé ; aller-retour `toJson`/`fromJson`. `canAfford` : PV = coût refusé, coût + 1 accepté ; Armure = coût acceptée ; mana d'abord. `resolveCard` : une carte refusée n'écrit rien ; payée, mana, PV et Armure débités en une écriture ; aucun `onDamageTaken` (*Ferveur* ne monte pas) ; *Rage* lit les PV perdus au tour suivant ; `cheap` ne touche que le mana ; `transfusion` rend 2 sur 3, borné aux PV max | 1 |
| `scaleWith` | `test/unit/scale_with_test.dart` *(nouveau)* | Les six sources ; arrondi vers le bas ; la rareté ne multiplie pas le terme (épique : valeur × rareté + terme) ; refus sur `draw`, `gain_mana`, multi-coups, cible non unique pour les sources de cible ; l'ordre des effets | 1 |
| Multi-coups | `test/unit/multi_hit_test.dart` *(nouveau)* | Critique, Électrocution et Puissance × `mightRatio` par coup ; arrondi vers le bas ; cible morte en cours ; AoE ; A14 (*Tranchant* 1 et 5 sur 3 × 3) | 1 |
| Statuts proportionnels | `test/unit/damage_pipeline_test.dart` ; l'intention effective (`EnemyInstance.effectiveIntent`), dans le test qui la couvre ou un neuf | Le barème et ses plafonds ; somme des entrées ; *Trait de Glace* et `freezing` 1 gardent −50 % ; les parenthèses de l'infobulle Flutter et la galerie des statuts du tutoriel lisent le barème (une valeur changée du barème change le texte) | 1 |
| Q11 | `test/unit/effect_resolver_test.dart` | Un seul `apply_status` par résolution reçoit le bonus, tous statuts confondus : *Boule de Feu* + *Brûlant* et *Coup de Tonnerre* + *Brûlant*, un bonus chacune, sur le statut de la rune ; un écho, un second bonus ; un premier statut posé sur soi consomme le bonus | 1 |
| Les cinq runes | `forge_upgrades_catalog_test.dart` (matrice de l'offre), `rune_resolution_test.dart`, `rune_eligibility_test.dart` | Chaque rune : son effet, son plafond, son éligibilité (`eligibleTargets`, `requiresCost`, exclusions d'`echo`) ; `piercing` borné à 100 %, demie vers le haut, plancher L borné par l'Armure ; `lifesteal` : plancher L borné par les dégâts ; `freezing` sans plafond ; `raisableCaps` écarte `piercing` à 4, `lifesteal` à 5 et `echo` à 7, et propose `splash` 3, `echo` 4 à leur plafond | 1 (17 cartes) · 2 (33) |
| Budget de Puissance (D38) | `test/unit/card_catalog_test.dart` *(nouveau)* | Σ `hits` × `mightRatio` ≤ coût en mana + 1 et `hits ≥ 2 ⇒ mightRatio < 1`, sur toutes les cartes et les signatures (A33) | 1 |
| Données de lot (D17, D45, D50, A7) | `card_catalog_test.dart` | Aucune neutre à coût non-mana ; chaque carte de lot touche son `feeds` ; par classe et passif disponible, au plus deux cartes à coût total nul, toutes `isExhaust` ; aucun lot n'en porte plus d'une ; aucune `costs.armor` sous une classe qui convertit l'armure | 2 |
| Chargeur | `test/unit/game_data_loader_injection_test.dart`, `game_data_loader_test.dart` | `cards/*/*.json` injecte `passive` ; `passive` déclaré dans une carte de lot ou une neutre refusé ; même id sous deux dossiers refusé | 2 |
| Passifs | `passive_data_test.dart` | `classes` absente ou de longueur ≠ 1 refusée ; `feeds` exigé, ses cinq formes, entrée inconnue refusée | 2 |
| **Masquage — tâche à risque** | `passive_availability_test.dart` | Un passif sans carte de lot est absent, avec une il est présent ; la carte d'un autre passif ne l'ouvre pas ; une carte de lot de type quelconque suffit ; l'ordre ; le registre n'est pas réordonné | 2 |
| Masquage, registre réel | `referential_integrity_test.dart` | Chaque passif disponible a un lot et chaque passif pourvu d'un lot est disponible pour sa classe — sans nommer de passif ; chaque `status:<id>` de `feeds` est fabriqué ; chaque dossier de `cards/` est l'id d'un passif | 2 |
| Offre | `card_offer_filter_test.dart`, `shop_controller_test.dart`, `reward_controller_test.dart` | `isOfferable(p)` : neutres et lot de `p`, jamais un autre lot ni un statut ; sans passif, neutres seules ; 200 tirages de boutique et de trouvaille sans carte d'un autre lot | 2 |
| Draft de départ | `starter_deck_draft_screen_test.dart`, `starter_deck_draft_order_test.dart` | Deux groupes ; quotas 2 et 3 ; refus au-delà ; « Valider » à 2 + 3 seulement ; lot de moins de deux cartes : quotas ajustés | 2 |
| Tutoriel | `tutorial_engine_test.dart` (dont `:568`, qui lit `focus`), `tutorial_fixtures_test.dart`, `tutorial_class_step_test.dart` | Le Mage démarre sur *Flux de Mana* ; `starterPool` du passif ; la leçon de jeu écarte une carte à coûts, à coups ou à `scaleWith` | 2 |
| Rendu | `test/widget/ui_card_values_test.dart` ; la face Flame au test manuel, faute de banc | Sur `UiCard` : médaillons PV et Armure, badge `3×3`, lignes de l'infobulle ; sur la face Flame, médaillons rouges et terme de `scaleWith`, au test manuel | 2 |
| Comptes | `entity_id_convention_test.dart:65-73`, `real_bundle_load_test.dart:36`, `:97` | 115 fichiers ; 15 neutres à la profondeur 4, 18 cartes de lot à la profondeur 5 ; `registry.cards` 33 ; forge 16 | 1 (forge) · 2 |
| Éditeur | `entity_descriptor_test.dart`, tests de `content_editor/` dont `shipped_entities_round_trip_test.dart` | Dix catégories, dix sources ; carte de lot sous `cards/<passif>/`, propriétaire exigé, `passive` jamais écrit ; chaque fichier livré — runes, cartes de lot, signatures à évolutions — repasse la validation et se réécrit à l'identique | 1 · 2 · 3 |
| Évolutions : donnée | `test/unit/signature_evolution_data_test.dart` *(nouveau)* | Chaque règle de §3.7, refus nommés ; trois mineures et quatre majeures par signature livrée (Q6) ; `cooldown` sur une mineure refusé (D54) ; `icon` ou `color` absents refusés | 3 |
| Icônes d'évolution | `test/unit/referential_integrity_test.dart`, à côté du test des icônes de rune (`:85-96`) | Chaque `icon` et chaque `color` d'évolution livrée est connue d'`evolutionIcons` et `evolutionColors` ; deux évolutions d'une même signature de même icône ne sont jamais deux mineures ni deux majeures (A37) | 3 |
| Tuile de combat | `test/widget/signature_bar_test.dart` | Badge absent au niveau 0, « Niv. 3 » (`levelLabel`) au niveau 3, sur la ligne du type ; une puce par évolution distincte, dans l'ordre ; anneau sur une majeure ; chiffre sur une mineure dès 2 ; sept puces sans débordement à 170 et à 220 px ; gris en recharge et sans le mana, chiffre de niveau compris ; la colonne centrée à mi-hauteur quand elle tient, décalée quand elle sortirait de la bande, réduite quand elle dépasse sa hauteur, à l'échelle 0,75 au plus bas et alors sortie par le bas — un cas à `H ≈ 400` (A38) | 3 |
| Évolutions : moteur | `test/unit/signature_instance_test.dart` | `asCard` évolué : dégâts, Armure, coût, cible, recharge (plancher 1) ; description remplie et phrases verbales ; `pendingFor` ; `nextTier` 5 → mineure, 10 → majeure | 3 |
| Évolutions : tirage et choix | `test/unit/signature_evolution_rules_test.dart` *(nouveau)* | Trois mineures ; majeures non prises ; exclusion dans les deux sens (`haste` ↔ `devastation`) ; complément par des mineures sous trois majeures ; repli quand elles sont épuisées ; `chooseSignatureEvolution` refuse sans rien écrire, monte une mineure prise, sauve | 3 |
| **Évolutions : sauvegarde — tâche à risque** | `test/unit/save_service_test.dart` | Aller-retour exact ; signature sans évolution : aucune clé ; sauvegarde sans la clé ; id inconnu retiré et signalé ; référence mal formée ignorée ; doublons additionnés ; majeure ramenée à 1 et paire exclue, la première gardée, sans entrée au rapport ; clé d'une signature absente ignorée | 3 |
| Écran et rideau | `test/widget/signature_evolution_screen_test.dart` *(nouveau)*, `test/widget/map_screen_test.dart` | En-tête au nom de la signature ; trois rouleaux, palier, icône (P-4) et « Niveau 1 → 2 » ; le toucher choisit et rend la carte ; rideau et nœuds fermés tant qu'une évolution attend ; draft de niveau d'abord | 3 |

---

## 10. Le découpage

**Partie 1 — le moteur de P-44 lot 1, sur les 17 neutres.** Le modèle (`costs`, `hits`, `mightRatio`,
`scaleWith`), `canAfford` et le paiement, la résolution de §4.7, A12, A14, A15, A16 ; les statuts proportionnels
et leurs recalibrages (*Trait de Glace*, `freezing`, *Marque du Mage*), avec les parenthèses de statut des deux
infobulles, la galerie et le tableau des statuts du tutoriel, le corps de ses deux étapes qui décrivent le Gel, et leurs clés `status…Hint` (§5.2, §6.1, §6.2) — le barème change ce que lit le joueur dès cette partie ; les
cinq runes, leurs sortes de delta, `eligibleTargets`, `requiresCost`, la saturation lue par `raisableCaps` (A22) ;
le descripteur de rune ; le test de D38 ; les tests marqués 1.

**Partie 2 — la forme C et les trois lots.** La source et l'injection, `passive`, A8, `isOfferable(p)`, le
masquage, `classes` à une classe, `feeds` ; les 18 cartes, `focus` supprimée, `demon_form` déplacée,
`sync_assets` ; le rendu des cartes marqué 2 au §5.2 — médaillons, badges et lignes d'infobulle, Flutter et
Flame — ; le draft de départ et le tutoriel ;
l'éditeur (`lotCard`) ; `CLAUDE.md` et `README.md` (§11) ; les tests marqués 2.

**Partie 3 — les évolutions.** `flatBonus`, `extraDeltas`, `SignatureEvolutionData`, les gabarits et les six
pools, avec leurs icônes et les tables `evolutionIcons` / `evolutionColors` ; `SignatureInstance`, le tirage, le
choix, l'attente ; la sauvegarde ; l'écran, son icône de rouleau (P-4), le rideau ; la tuile de combat, son badge, sa
rangée d'icônes et la bande de la barre (A35 à A38) ; le descripteur de signature ; les tests marqués 3.

**L'invariant** : à la fin de chaque partie, **toute donnée livrée a son moteur, son rendu et ses tests dans la
même partie**, et la suite est verte. Après la partie 1, le jeu est celui de `0.5.6` avec cinq runes de plus à la
fusion, des statuts qui comptent leurs points et la Puissance qui les nourrit — aucune carte ne porte encore de
coût, de coups ni de croissance, d'où l'absence de leur rendu. Après la partie 2, trois passifs se jouent avec leur
lot et les six autres quittent la sélection ; les signatures sont celles d'E4. La partie 3 ajoute son modèle, sa
donnée et son écran ensemble. L'ordre suit les dépendances : les cartes de la partie 2 exigent le moteur de la
partie 1 ; la partie 3 n'exige que l'applicateur, et se place en dernier pour que la partie la plus chargée en
donnée et celle qui touche la sauvegarde ne se mêlent pas.

---

## 11. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| ADR « forme C et lots par passif » — **amende ADR-101** D1 (le prédicat lit le passif actif) et **ADR-096** D1 (`classes` exactement une, absente refusée) et D2 (disponible = éligible et pourvu d'un lot) ; **complète ADR-086** (`cards/*/*.json` injecte `passive` ; la source neutre l'injecte à `null`) et ADR-109 (la carte de lot dans l'éditeur, dixième catégorie) | `memory-bank-sync` |
| ADR « évolutions de signature » — **complète ADR-109** (`SignatureInstance.evolutions`, sauvegardées ; l'écran ; le badge et les icônes de la tuile, P-2) et **ADR-105** D1 (la couture : `extraDeltas`, `flatBonus`) | `memory-bank-sync` |
| ADR « profondeur, lot 1 » — **complète ADR-061** (multi-coups dans la stratégie ; la Puissance de statut au résolveur), **ADR-105** D1 et D8 (cinq sortes de delta ; `eligibleTargets`, `requiresCost`), **ADR-097** (Puissance × `mightRatio` par coup ; un seul bonus de statut par résolution, Q11) | `memory-bank-sync` |
| Fiches `_rules/02-3` (catalogue de cartes), `04-00` (statuts), `03-3` (pipeline : `piercing`, barème), `03-1` (coûts), `02-2` (signatures), `03-13` (persistance), `01-00` et `03-10` (draft de départ, écran d'évolution), `07-00` (forme C) ; `_patterns/20-00` (le script ignore `cards/*/*.json`) — un minimum : le diff périme aussi `_rules/03-8`, `08-00` et `_patterns/02-1`, `03-3`, `03-4`, `05-9`, `17-00`, `19-00` | `memory-bank-sync` |
| **P-44 lot 1 se clôt** dans `docs/ROADMAP.md` | `memory-bank-sync` |
| `CLAUDE.md:78` et `README.md:69` : l'arbre gagne `cards/<passive>/<id>.json` ; la phrase « Never write a field the directory imposes » gagne « and `passive` in any card file » | Partie 2 |
| Note de version `0.5.7` | `patch-notes-writer`, à la fin de la vague |

**Ce que le joueur voit en `0.5.7`** : le deckbuilding existe — trois passifs jouables avec leur lot de six
cartes (*Régénération d'Armure* et le Rempart, *Rage* et le Sang, *Flux de Mana* et l'Arcaniste), un draft de
départ à 2 cartes du lot et 3 neutres ; des cartes qui coûtent des PV ou de l'Armure, qui frappent plusieurs fois,
qui grandissent avec l'Armure ou les PV perdus ; Vulnérable, Faiblesse et Gel qui comptent leurs points, et la
Puissance d'altération qui les renforce ; cinq runes de plus à la fusion ; les signatures qui évoluent tous les
cinq niveaux, sur un écran à trois rouleaux, et montrent en combat leur niveau et une icône par évolution prise. **À dire dans la note** : six passifs quittent la sélection jusqu'à
ce que leur lot de cartes arrive, dans les versions suivantes — trois en `0.5.8`, les trois derniers en `0.6.0` (D76) ; *Focalisation* disparaît ; *Forme
Démoniaque* devient une carte du Sang ; *Trait de Glace* applique 2 Gel pour le même effet.

**Ce que le vérificateur contrôle** :

- chaque carte de lot touche une entrée de `feeds`, aucune neutre ne porte de coût autre que du mana, aucun lot ne
  dépasse une carte à coût total nul : `card_catalog_test.dart`, sur le registre réel ;
- `git grep -n "onDamagingCardPlayed" -- lib test assets` ne rend rien, et `assets/data/passives/mage_mark.json`
  garde `"trigger": "onAttackPlayed"` : D34 n'est pas absorbé ;
- `assets/data/cards/focus.json` et `assets/data/cards/demon_form.json` n'existent plus,
  `assets/data/cards/rage/demon_form.json` existe ; `TutorialFixtureIds` (`tutorial_fixtures.dart:18-20`) nomme
  toujours `strike_basic`, `defend_basic`, `fireball`, qui restent sous `cards/` ;
- `git diff main -- tool/simulations` est vide ;
- `dart run tool/sync_assets.dart --check` passe.
