# P-42 tranche 3 — Sanctifié, Carnage, Marque : les neuf passifs jouables — Conception

Date : 2026-11-18
Statut : **Conception** — vague 8 (`0.6.0`), branche `feat/v0.6.0-p42-tranche-3`

Chantier ROADMAP : **P-42** « Catalogue par lots de passif », tranche 3 — la dernière. Le déroulé fait foi dans le
[fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§8.8 ; les décisions, dans le [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md),
§1 (D34, D43, D55, D60, D83 à D86), §3, §5, §6, §7. Le moteur que la tranche réutilise est celui de la
[spec de la vague 5](2026-10-25-p42-tranche-1-p44-lot-1-design.md) (`scaleWith`, `hits`, `mightRatio`, forme C,
`feeds`, masquage O5, draft 2 + 3) et celui de la [spec de la vague 7](2026-11-15-p53-charges-elementaires-design.md)
(les charges) : ni l'un ni l'autre ne se rouvre ici.

> **Ce que le lot livre, en une phrase.** Les trois derniers lots arrivent — **Sanctifié** pour *Bénédiction*,
> **Carnage** pour *Frénésie*, **Marque** pour *Marque du Mage* — et démasquent leur passif : les neuf passifs
> sont jouables ; *Marque du Mage* se déclenche désormais sur la première **carte de dégâts** du tour, Attaque ou
> Compétence, ce qui lui rend *Projectile Magique* ; la Faiblesse trouve ses cartes ; *Prière* pose un soin dans
> le temps, le statut neuf `hp_regen` ; six neutres rejoignent leur lot, `fireball` sans changer d'id.

Toute référence `fichier:ligne` de ce document a été lue le 2026-11-18 sur la branche à `eb7945fb`. **Les cartes —
noms, valeurs, textes — sont des ordres de grandeur** (brainstorm, en-tête ; fiche 8.8) : la spec les fixe, le
plan les écrit, le test du propriétaire les corrige.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce que le lot en livre | Où |
|:---|:---|:---|
| **D34** | *Marque du Mage* se déclenche sur la première carte de dégâts du tour, Attaque ou Compétence, signature comprise : le déclencheur neuf `onDamagingCardPlayed`, un prédicat unique « carte de dégâts » ; *Projectile Magique*, Compétence depuis `0.5.6`, marque de nouveau — hors son évolution *Nova*, qui en fait une carte de groupe (A3, **provisoire**) | §3.1, §4.1, §4.2 |
| **D55** | *Prière* : un soin **dans le temps**, différencié de `heal_potion` (qui reste neutre, inchangée) — le statut `hp_regen` | §3.2, §4.3 |
| **D43** | Pour ce lot, la seule variante « armure conservée » — **non retenue** par le propriétaire (§1.2) : aucune carte, aucun mécanisme d'armure conservée | §1.2 |
| **D16** | Cinq à six cartes par lot : Sanctifié 5, Carnage 5, Marque 6 | §3.2 |
| **D17** | Aucune neutre bloquée ; les neuf neutres qui restent ne portent que du mana — le test de la vague 5 le garde (`card_catalog_test.dart:203`) | §3.4 |
| **D45** | Chaque carte de lot touche une entrée des `feeds` de son passif ; `feeds` de *Frénésie* et de *Bénédiction* ajustés avec leur lot (A11) | §3.1, §9 |
| **D50** | Aucune des trois nouvelles tranches ne porte de carte à coût total nul : sous chacun des trois passifs, la seule carte gratuite offerte reste `concentration`, épuisable | §3.2, §9 |

Lues et tenues sans être livrées : **D10** (un passif, un lot) ; **D11** et brainstorm §5 (`maxMana` reste 3 ; pas
de carte à 0 dans les lots du Mage) ; **D38** (Σ `hits` × `mightRatio` ≤ coût en mana + 1 — *Salve* : 1,5 ≤ 2) ;
**D49** (les signatures hors du compte des cartes gratuites ; « carte » couvre la signature jouée, comme le
compteur de la vague 5) ; **D60** (*Bénédiction* garde sa tranche de 5 et sa Maîtrise sur la valeur :
`passives/blessing.json` ne change que de `feeds`) ; **D77** (aucun test d'écran : ce qu'il aurait vérifié est en
§9.1) ; **D83 à D86** (les quatre élémentaires du lot Marque posent les charges telles que la vague 7 les a
livrées, valeurs de P-b comprises ; la Faiblesse garde son barème et son tic — A19) ; **Q8** (spec de la
vague 5, §1.2) : aucune carte-pont.

### 1.2. Les réponses du propriétaire, reprises telles quelles

| Question | Réponse |
|:---|:---|
| **Q12** *(P)* | **Oui : les quatre élémentaires restent des Attaques.** `fireball`, `ice_bolt`, `thunder_clap`, `poison_stab` changent de dossier, pas de type |
| **D43, la variante « armure conservée »** *(P)* | **Non : on ne la prend pas.** Aucune carte, aucun mécanisme d'armure conservée dans ce lot ; l'armure de *Bénédiction* survit par la Faiblesse posée sur l'ennemi |
| **Q11** *(vérifiée, close)* | Tranchée en vague 5 : « Un seul bonus de Puissance par carte : une carte qui pose `burn` et porte la rune `burning` ne compte la Puissance qu'une fois » (spec de la vague 5, §1.2 ligne Q11 ; appliquée par A15 et §4.5 : seul le premier `apply_status` d'une résolution, ceux des runes compris, reçoit la Puissance de statut) ; reprise par D83 (« une fois par carte (Q11 de la vague 5) »). Rien à trancher : *Boule de Feu* + *Brûlant* dans le lot Marque suit cette règle |

### 1.3. Les arbitrages

**A1 — Le déclencheur est une valeur neuve, `onDamagingCardPlayed`, que `_afterCardPlayed` envoie après celui du
type** *(T, filtres 1, 4 puis 7)*. Les passifs lisent leur déclencheur dans `RelicTrigger` (`relic_data.dart:5-21`,
`passive_data.dart:262`) et `TraitSystem.dispatch` compare le déclencheur de l'événement à celui du passif
(`trait_system.dart:14-22`). L'énumération gagne `onDamagingCardPlayed`, que nomment le brainstorm (§7.3, colonne
« Passif ») et la fiche 8.8 ; `mage_mark.json` le déclare. La suite commune de la carte comme de la signature,
`_afterCardPlayed` (`combat_controller.dart:296-325`), envoie aujourd'hui `onCardPlayed` (`:303-306`) puis le
déclencheur du type (`:307-319`) ; elle envoie ensuite `PassiveEvent(RelicTrigger.onDamagingCardPlayed, card:,
enemyId:)` si la carte jouée est une carte de dégâts (A2), avant les reliques (`:321-322`) et le nettoyage des
morts (`:324`). Un filtre écrit dans `MageMarkPassive` sur `onCardPlayed` cacherait la règle dans la stratégie, là
où le fichier du passif doit dire ce qu'il écoute ; un filtre de déclencheur en donnée sur `PassiveData` serait un
mécanisme de plus pour un seul passif.

**A2 — « Carte de dégâts » : un seul prédicat, calculé sur la vue effective de la carte** *(T, filtres 4 et 5)*.
Une carte de dégâts est une carte dont la résolution porte au moins un effet `damage`, propre ou ajouté — par une
rune ou par une évolution de signature, `EffectiveCard.addedEffects` (`effective_card.dart:29`). Le prédicat vit
sur `EffectiveCard` (`dealsDamage`), et `_afterCardPlayed` le lit sur `card.effective` — pour une signature, sa vue
de carte évoluée (`combat_controller.dart:250`, `signature.asCard`). Il ne lit ni la cible, ni les dégâts
réellement infligés : une carte de dégâts entièrement absorbée par l'Armure en reste une. Aucun champ en donnée :
un drapeau `dealsDamage` sur la carte serait une donnée qui peut mentir sur ses effets, la forme que le brainstorm
écarte déjà pour une liste d'exclusion par carte (§7.4), et qu'ADR-086 refuse en faisant porter au répertoire, non
à un champ, ce qu'une carte est (filtre 5). Aujourd'hui aucune
rune n'ajoute d'effet `damage` (les fichiers de `forge_upgrades/` ne nomment `damage` que comme effet éligible ou
renforcé) : le prédicat est écrit pour la vue effective parce que c'est elle que la résolution joue.

*A3, la carte de dégâts de groupe jouée la première, est une question ouverte : §1.4.* La marque est posée après la
résolution de la carte qui la déclenche, comme aujourd'hui : cette carte-là ne profite pas de son propre
Vulnérable.

*A4, la carte à cible unique qui tue sa cible, est une question ouverte : §1.4.*

**A5 — Les reliques n'écoutent pas `onDamagingCardPlayed` ; son libellé d'affichage est une clé ARB**
*(T, filtres 7 puis 5)*. Aucune relique ne l'emploie : la suite commune n'appelle pas `applyRelics` pour lui, sur le
précédent d'`onDamageTaken`, posé pour *Ferveur* seule (`relic_data.dart:16-20`). Les trois `switch` exhaustifs
d'affichage du déclencheur d'une relique (`card_dictionary_screen.dart:344`, `relics_dialog.dart:201`,
`relic_carousel_card.dart:61`) reçoivent un cas, que le compilateur exige ; son texte est une clé ARB,
`relicTriggerDamagingCardPlayed` (§6.2), règle de `CLAUDE.md` pour les textes d'interface — les ternaires voisins
restent tels quels. Aucun joueur ne le voit tant qu'aucune relique ne le porte.

**A6 — `hp_regen`, sur le modèle de `mana_regen` ; symétrique, borné aux PV max, jamais sur un porteur à 0 PV**
*(T, filtres 4, puis 6 et 8)*. `EffectResolver.createStatus` (`effect_resolver.dart:24-91`) fabrique `hp_regen` —
buff, nom « Source de Vie » (A20). `StatusEffectProcessor.processPlayerStatuses`
(`status_effect_processor.dart:18-89`) additionne ses valeurs avec les autres avant le tic (`:29-39`) et rend ces PV
après lui (`:69`), à côté de l'Armure et du Mana (`:71-84`) : posé pour 3 tours, il rend sa valeur au début des
trois tours suivants, comme *Méditation* rend son Mana. Le soin ne passe pas par `StatGains` — `GainResource` ne
connaît que `armor`, `mana`, `might` (`stat_gains.dart:6`), et aucune règle de classe ne porte sur les PV — ni par
le critique ni par le vol de vie : il écrit `currentPv`, borné à `maxPv`. **Il ne relève jamais un porteur que le
Feu ou le Poison du même début de tour viennent de tuer** : à `currentPv <= 0`, rien n'est rendu. **Symétrique** :
`processEnemyStatuses` (`:94-141`) le traite de même, bien qu'aucun ennemi ne le pose — le cadre des charges
(D83) a posé ce précédent d'un moteur symétrique sans contenu ennemi. Sa vie est celle d'un statut de combat : vidé
à la fin du combat, jamais sauvegardé.

**A7 — L'icône et la couleur d'`hp_regen` sont celles du soin** *(T, filtre 6)*. `effect_icons.json` gagne
`"status:hp_regen": { "icon": "favorite_rounded", "color": "pinkAccent" }`, celles du `heal` (`:4`), comme
`status:mana_regen` reprend celles du gain de mana (`:9`) ; 18 sortes. Le panneau des statuts du héros lit la table
quand elle a l'entrée (`status_effects_panel.dart:107-172`) : la Source de Vie y prend le cœur rose, le Vol de vie
garde son cœur rouge. Partout où une face, une infobulle ou le panneau nomment `mana_regen`
(`card_component.dart:445`, `card_text_renderer.dart:124`, `:324`, `card_compact_description.dart:68`,
`ui_card_helpers.dart:113`, `:413`, `status_effects_panel.dart:144`), `hp_regen` prend sa ligne.
`effect_line_texts.dart` (signatures seules) et l'indicateur Flame des ennemis (`status_indicator.dart`) ne changent
pas : ni une signature ni un ennemi ne posent le statut.

**A8 — *Exécution* s'écrit avec la source livrée, `targetMissingHp`** *(T pour le mécanisme — aucune source neuve —,
filtres 4 puis 7 ; délégué pour la règle de la carte)*. La règle du
brainstorm, « ×2 si la cible a moins de 30 % PV », n'est pas un `scaleWith` : elle demanderait un second mécanisme,
un multiplicateur conditionnel en donnée, quand le lot a déjà la croissance (§7.2, colonne « P-44 » :
`scaleWith: targetMissingHp`). La source livrée en vague 5 (spec de la vague 5, §4.2 ; `effect_resolver.dart:253-254`)
lit `maxPv − currentPv` de la cible vivante (`:240`) ; un terme de `ratio` × PV manquants exécute à seuil
proportionnel : avec 4 et `ratio` 0,2, la carte tue une cible à moins d'environ un sixième de ses PV plus 3, quel
que soit son maximum — 8 PV restants sur un Gobelin de 28, 11 sur un Orc de 50. Une source neuve en pourcentage
serait plus juste contre les boss, où le terme absolu grandit, mais élargirait le moteur pour une carte ; le test du
propriétaire dira si les boss l'exigent (§9.1, M10).

**A9 — *Exploitation* s'écrit avec la source livrée, `targetStatus`, qui lit la somme brute des entrées**
*(T pour le mécanisme — aucune source neuve —, filtres 4, 6 puis 7 ; délégué pour la règle de la carte)*. « ×2 si la cible est vulnérable » devient « +1 par point de Vulnérable de la cible » :
`targetStatus` additionne les valeurs des entrées `vulnerable` de la cible (`effect_resolver.dart:249-252`). Sous
*Marque du Mage*, qui pose 2 points chaque tour sur la même cible, les entrées s'additionnent (`EntityStats.addStatus`,
fusion de même id et même source) : 2 au premier tour, 4 au deuxième — où le terme vaut le ×2 du brainstorm —, puis
au-delà, quand le pipeline plafonne Vulnérable à 4 points (`proportional_status.dart:15-16`, `:25-30`). La source
lit la somme brute parce que c'est elle que l'ennemi affiche (`status_indicator.dart:121-128`, `status.value`) : la
carte compte ce que le joueur voit. Le terme qui grandit au fil d'un long combat est laissé au test du propriétaire
(M7).

**A10 — Le nom du statut que lit `targetStatus` est traduit** *(T, filtre 6)*. `CardRuleTexts._statusName`
(`card_rule_texts.dart:72-81`) prend le nom de la charge, sinon celui que la fabrique donne, en français
(`:79`) : la ligne de croissance anglaise d'*Exploitation* dirait « +1 per point of Vulnérable on the target » — le
défaut que le compte rendu de la vague 5 avait mis à la file (§4), sans carte pour le montrer jusqu'ici. Une clé ARB
`statusName` à sélection (§6.2) donne le nom de chaque statut que `createStatus` fabrique, `hp_regen` compris ; la
charge garde le nom de son fichier.

**A11 — `feeds` : *Frénésie* gagne `damage`, *Bénédiction* gagne `status:hp_regen` ; *Marque du Mage* ne change
pas** *(T, filtres 1 puis 7)*. Les `feeds` des trois passifs sont des valeurs de départ, que la tranche ajuste avec
son lot (spec de la vague 5, §3.3). Re-mesuré : `["scale:targetMissingHp", "scale:enemiesAlive"]` refuserait quatre
des cinq cartes de Carnage — `warcry` et les trois Attaques de groupe ne lisent aucune source — ; et
`["armor", "status:armor_regen", "status:weakness", "heal"]` refuserait *Prière*, qui pose `hp_regen` sans effet
`heal`. *Frénésie* se nourrit de morts, donc de dégâts, de quelque type de carte qu'ils viennent : `damage`, plutôt
qu'`attack` qui dirait le type et non le verbe ; une forme `target:allEnemies` élargirait le vocabulaire d'A6 de la
vague 5 pour un lot. `scale:enemiesAlive` reste : aucune carte ne le lit, l'entrée n'en refuse aucune. Le test
d'intégrité exige que `status:hp_regen` soit fabriqué par `createStatus` : A6 le fait.

**A12 — Six fichiers changent de dossier, contenu et id inchangés ; le tutoriel ne change pas** *(T, filtres 1, 5
puis 7)*. `fireball`, `ice_bolt`, `thunder_clap`, `poison_stab` passent sous `cards/mage_mark/`, `metallicize` sous
`cards/blessing/`, `warcry` sous `cards/frenzy/` (brainstorm §7.1, §7.2, §7.3 ; revue, annexe B.4). Le répertoire
porte le passif (forme C) ; aucun fichier n'écrit `passive`. Les sources `card:<id>` (ADR-104) ne changent pas. Le
tutoriel lit `fireball` par son id dans le registre (`tutorial_fixtures.dart:21`, `:39`), quel que soit le dossier,
et le montre à l'étape « cartes » à toute classe (`tutorial_engine.dart:195-201`) — une carte du lot Marque montrée
au Paladin comme exemple de face : c'est une démonstration, pas une offre. Le tutoriel ne simule aucun passif (A12
de la vague 6) : *Marque du Mage* n'y fait rien.

**A13 — Le démasquage est la donnée ; l'ordre des passifs ne change pas** *(T, filtres 1 puis 7)*.
`availablePassivesFor` (`passive_availability.dart:24-38`) ouvre un passif dès qu'une carte du registre le porte
(O5) : les seize fichiers des trois dossiers ouvrent *Bénédiction*, *Frénésie* et *Marque du Mage*, sans code. Triés
par `displayOrder` : Paladin *Régénération d'Armure* (1), *Ferveur* (2), *Bénédiction* (3) ; Berserker *Rage* (1),
*Soif de Sang* (2), *Frénésie* (3) ; Mage *Canalisation* (1), *Marque du Mage* (2), *Flux de Mana* (3). Le passif
choisi par défaut à la sélection et au tutoriel reste le premier de chaque classe.

**A14 — Sanctifié : la Faiblesse fait survivre l'Armure, la Métallisation en pose au début du tour, *Prière* soigne
dans le temps** *(rôle `game_designer`, délégué)*. *Bénédiction* convertit l'Armure qui a survécu (5 points → 1 PV,
2 sous la Maîtrise 1 du Paladin) : le lot pose de la Faiblesse pour que l'ennemi frappe moins fort que le bloc —
le seul sous-thème que D43 lui laisse, la variante « armure conservée » écartée (§1.2). *Sommation* (1 : 1
Faiblesse, longue, un ennemi) et *Édit* (2 : 2 Faiblesse à tous, courte) sont celles du brainstorm (§7.1), leurs
durées écrites par A19 ; *Réprimande* (1 : 4 Armure + 1 Faiblesse courte) met le bloc et la Faiblesse dans
une même carte, le geste exact que *Bénédiction* récompense ; `metallicize` survit telle quelle (§7.1, la note) ;
*Prière* (2, Pouvoir : `hp_regen` 2 pendant 3 tours, 6 PV en tout, une fois par combat — un Pouvoir s'épuise,
`card_instance.dart:43-48`) se distingue de `heal_potion` (1, 3 PV d'un coup, épuise) par le temps (D55), à 3 PV par
mana comme elle. La Puissance du Paladin, qui va aussi aux altérations (`power_rules.dart:27-32`), ajoute des points à
la première Faiblesse de chaque carte (Q11), plafonnés à 2 par le barème. Courbe 1, 1, 1, 2, 2 ; ni carte à 0, ni
coût en PV ou en Armure. *Vigile* reste retirée (revue §12, T6).

**A15 — Carnage : des Attaques de groupe et une exécution, pour enchaîner les morts** *(rôle `game_designer`,
délégué)*. *Frénésie* donne 2 Puissance pour le tour et une pioche par ennemi abattu, une fois par mort
(`passive_strategies.dart:200-217`, `combat_controller.dart:371-381`) : la Puissance du Berserker allant aux Attaques
et s'ajoutant par ennemi touché, chaque mort renforce l'Attaque de groupe suivante. *Moulinet* (2 : 7 à tous, la
prime d'un lot sur deux *Balayage*), *Tourbillon* (1 : 2 à tous + pioche 1) et *Coup de grâce* (3 : 10 à tous) sont
celles du brainstorm (§7.2), relevées de 1 pour les deux grandes ; *Exécution* (1 : 4, +1 par tranche de 5 PV
manquants de la cible, A8) achève ; `warcry` survit (§7.2, la note : son Armure devient +2 Puissance ce tour chez le
Berserker). Courbe 1, 1, 2, 2, 3 ; aucune carte à 0. *Forge de guerre* n'est pas de ce lot (§2) : Carnage atteint
ses cinq cartes sans elle. **À l'acte 1, chaque combat ne compte qu'un ennemi** (`encounter_system.dart:60-71`) : les
Attaques de groupe y frappent une seule cible et la mort de l'ennemi finit le combat — Carnage est un lot des actes
suivants, ce que le test du propriétaire jugera (M9).

**A16 — Marque : les quatre élémentaires, et deux Compétences qui exploitent la marque** *(rôle `game_designer`,
délégué)*. Les quatre élémentaires restent des Attaques (Q12) et gardent les valeurs que le propriétaire a fixées
en vague 7 (P-b) ; leur part de statut reçoit la Puissance « altération » du Mage, leur part de dégâts non
(`power_rules.dart:17-21`). ***Exploitation* et *Salve* sont des Compétences**, quand le brainstorm les esquissait
en Attaques : sous D34, le passif partage le verbe de la classe — les Compétences de dégâts, où tombe la Puissance
du Mage (`mightTargets: ["skill", "alteration"]`) —, et deux Attaques de plus feraient de Marque le lot où la
Puissance du Mage ne touche aucun dégât (revue §8.1, R6). *Exploitation* (2 : 4, +1 par point de Vulnérable de la
cible, A9) frappe la cible marquée ; *Salve* (1 : 2 × 3, `mightRatio` 0,5, comme *Rafale d'étincelles*) multiplie
les coups que Vulnérable et la Foudre amplifient chacun (D35 : les multi-coups vont à Marque). Courbe 1, 1, 1, 1, 2,
2. Ce qui sépare Marque d'Arcaniste (« Une tension levée », §7.3) : le payoff — une rafale sur une cible
vulnérable, contre un volume de Compétences.

**A17 — Les textes** *(délégués)* : §6. *Marque du Mage* dit « carte » pour une carte comme pour une signature
jouée, la convention des textes `scaleWith` de la vague 6 (« +2 par carte jouée ce tour », S4).

**A18 — Un seul plan** *(T, filtre 7)* : §10.

**A19 — La Faiblesse garde son moteur ; les durées des cartes de Sanctifié sont écrites pour les attaques qu'elles
doivent réduire** *(T, filtres 1 puis 3 ; arbitré par l'orchestrateur)*. Un ennemi vieillit ses statuts au début de
sa phase, **avant** d'agir — la phase ennemie joue le Feu (`heros_draft_game.dart:393`), puis
`resolveEnemyStatuses` (`:399` ; `turn_phase_manager.dart:132-151`), dont `processEnemyStatuses` décompte les durées
(`status_effect_processor.dart:141`), puis seulement les intentions (`heros_draft_game.dart:412`, `:429`) : une
Faiblesse de durée N posée par une carte réduit N − 1 attaques. Faire vieillir la Faiblesse après l'action de son
porteur changerait son tic, que D83 garde (« Vulnérable, Faiblesse et Poison ne changent pas ») et ADR-117 avec lui
(« même barème, même tic, mêmes valeurs », ligne 158) : écarté par le filtre 1. Garder les durées du brainstorm
laisserait *Édit* (1 tour) sans aucun effet, une carte qui ne porte rien : écarté par P1 (filtre 3). Reste
d'écrire les durées des cartes plus longues d'un tour — *Sommation* 3, *Édit* et *Réprimande* 2 (§3.2) —, des
valeurs de cartes, déléguées : aucune option n'amendant une décision, la question n'est pas de classe D. Le
décalage lui-même, antérieur à la vague (*Sentence*, `0.5.7`), est porté à la file (§2).

**A20 — `hp_regen` s'appelle « Source de Vie » / « Life Spring »** *(T, filtre 6 ; précédent de la vague 6, A5 du
[plan de la tranche 2](../plans/2026-11-15-p42-tranche-2.md), où « Source de Mana » a été nommé dans un arbitrage T,
textes délégués)*. Le nom se lit au panneau des effets du héros et dans les infobulles ; il suit « Source de Mana »
/ « Mana Spring » (`mana_regen`), et « Régénération » se confondrait avec le passif *Régénération d'Armure*.

### 1.4. Les questions ouvertes

**A3 — Une carte de dégâts de groupe jouée la première du tour** *(classe P, ouverte, par la règle du doute : une
règle que le joueur lit dans la description du passif, que D34 — « la première carte de dégâts du tour » — ne
tranche pas)*. Aujourd'hui, `MageMarkPassive` (`passive_strategies.dart:62-95`) rend la main sans rien compter quand
l'événement ne porte pas d'ennemi (`:67-68`), et `applyPlayerCardPlay` ne renseigne `enemyId` que pour une carte
`singleEnemy` (`combat_controller.dart:231-236`) : une Attaque de groupe jouée la première laisse la marque à
l'Attaque suivante (`passives_mage_test.dart:384`). La question touche aussi *Projectile Magique* : son évolution
majeure *Nova* (`classes/mage/skills/magic_missile.json:111-119`, `"target": "allEnemies"`) fait de la signature une
carte de groupe — la vue évoluée prend la cible de la dernière évolution qui en déclare une
(`signature_instance.dart:141-145`), et `playSignature` ne transmet `enemyId` qu'à une signature à cible unique
(`combat_controller.dart:251`, `:287`). **Options**, et ce que chacune changerait :

- (a) **la carte de groupe marque chaque ennemi qu'elle vise** — les ennemis vivants que vise sa cible
  `allEnemies`, **éclaboussure non comprise** : `splash` est une rune d'une carte à cible unique, un pourcentage de
  ses dégâts versé aux voisins (`strategies.dart:68-71`), et la marque suit la cible que le joueur a choisie, ce qu'il
  lit sur la carte (filtre 6). Texte du passif : « À chaque tour, la première carte de dégâts, Attaque ou Compétence,
  applique 2 Vulnérable à chaque ennemi qu'elle vise pendant 2 tours. » / « Each turn, the first damage card, Attack
  or Skill, applies 2 Vulnerable to each enemy it targets for 2 turns. » ; *Nova* marque tous les ennemis ; le test
  `:384` se renverse (les deux ennemis marqués, le tour consommé), un test *Nova* le dit ;
- (b) **elle consomme le tour sans marquer** — texte : « À chaque tour, la première carte de dégâts, Attaque ou
  Compétence, applique 2 Vulnérable à sa cible pendant 2 tours ; une carte qui vise tous les ennemis n'en applique
  pas. » / « Each turn, the first damage card, Attack or Skill, applies 2 Vulnerable to its target for 2 turns; a
  card that targets all enemies applies none. » ; le compteur avance avant le test d'`enemyId` ; *Nova* consomme le
  tour sans marquer ; le test `:384` gagne « la carte suivante ne marque pas », un test *Nova* le dit ;
- (c) **le comportement actuel : elle ne marque ni ne consomme ; la première carte de dégâts à cible unique
  marque**, et la description le dit — texte de §3.1 ; stratégie inchangée sur ce point ; *Nova* ne marque plus et
  ne consomme pas ; le test `:384` reste, et gagne « la carte à cible unique suivante marque », un test *Nova* le dit.

**Recommandation : (c)**, appliquée à titre provisoire et marquée « (provisoire) » là où elle se lit (§1.1, §2.1,
§3.1, §4.2, §9, §9.1, §11) : elle ne change pas ce que le passif faisait, D34 n'en change que la famille des cartes
qui déclenchent, et elle garde le payoff de Marque, une rafale sur une cible unique vulnérable. Sous (b) et (c),
« la signature marque de nouveau » vaut pour *Projectile Magique* hors *Nova*.

**A4 — La carte à cible unique qui tue sa cible compte-t-elle comme la première carte de dégâts du tour** *(classe
P, ouverte : la même phrase du passif ; reclassée par l'orchestrateur)*. Le commentaire de `MageMarkPassive`
(`passive_strategies.dart:73-77`) veut qu'une cible morte de la carte qui vient d'être jouée ne consomme pas le
compteur ; or la stratégie ne cherche que l'absence (`index == -1`, `:77`), et l'ennemi tué est encore dans
`enemies`, à 0 PV, quand le passif se résout — `cleanDeadEnemies` vient après (`combat_controller.dart:324`,
`:371-381`). Re-mesuré : la carte qui tue sa cible consomme aujourd'hui la marque du tour sur un mort ; sous D34, où
*Projectile Magique* ouvre souvent le tour, le cas est courant. **Options**, et ce que chacune changerait :

- (i) **elle compte : le tour est consommé sur un mort** (comportement actuel) — texte de §3.1 sans « sans le tuer »
  : « À chaque tour, la première carte de dégâts, Attaque ou Compétence, qui vise un seul ennemi lui applique 2
  Vulnérable pendant 2 tours. » / « Each turn, the first damage card, Attack or Skill, aimed at a single enemy
  applies 2 Vulnerable to it for 2 turns. » ; stratégie inchangée ; un test « une cible tuée consomme le tour : la
  carte suivante ne marque pas » ;
- (ii) **elle ne compte pas : la carte de dégâts suivante marque** — la stratégie tient pour absente une cible à
  `currentPv <= 0`, ce que son commentaire voulait ; texte de §3.1 (« sans le tuer ») ; le test « une cible tuée
  par la carte ne consomme pas, la carte suivante marque ».

**Recommandation : (ii)**, appliquée à titre provisoire et marquée « (provisoire) » là où elle se lit (§3.1, §4.2,
§9, §9.1, §11) : le joueur ne perd pas la marque du tour pour avoir tué, et la phrase dit la règle. **Texte exact
proposé**, sous A3 (c) et A4 (ii) : « À chaque tour, la première carte de dégâts, Attaque ou Compétence, qui vise un
seul ennemi sans le tuer lui applique 2 Vulnérable pendant 2 tours. » / « Each turn, the first damage card, Attack
or Skill, that hits a single enemy without killing it applies 2 Vulnerable to it for 2 turns. »

---

## 2. Périmètre

**Dans le lot** : le déclencheur `onDamagingCardPlayed` et son prédicat ; *Marque du Mage* — son fichier, sa
stratégie (A3 et A4, provisoires), sa description ; le statut `hp_regen` (A6, A7) ; les seize fichiers des trois lots, dont six
déplacés ; les `feeds` de *Frénésie* et de *Bénédiction* ; le nom traduit du statut de `targetStatus` (A10) ; trois
lignes de `pubspec.yaml` ; les textes ; les tests de données, de calcul et de contrôleur.

| Hors du lot | Où |
|:---|:---|
| *Forge de guerre* de Carnage (production de cartes) | P-44 lot 3, après `0.6.0` |
| Les épines de Rempart, la carte `retain` de Voile | P-44 lots 2 et 3, après `0.6.0` |
| La calibration, dont les boss face à *Exécution* et le Vulnérable qui s'accumule (M7, M10) | P-16 |
| Toute règle des charges élémentaires (D83 à D86) ; le tic de la Faiblesse (A19) | Vague 7 ; D83 |
| Le décalage « une Faiblesse de N tours réduit N − 1 attaques ennemies », antérieur à la vague (*Sentence*, `0.5.7`, `classes/paladin/skills/smite.json:84-102`) | À la file |
| Tout rééquilibrage des six lots livrés et des neuf neutres qui restent ; la valeur de *Marque du Mage* (2) | — |
| `maxMana` (reste 3) ; un ennemi neuf ; un ennemi qui pose `hp_regen` ou la Faiblesse | — |
| Les reliques qui écouteraient `onDamagingCardPlayed` (A5) | Plus tard |
| La face qui montrerait, avant le jeu, le terme d'une source de cible (`card_component.dart:255-268` : 0 sans cible) | Plus tard |
| La valeur affichée sur l'ennemi au-delà du plafond du barème (`status_indicator.dart:121-128`) : Vulnérable au-delà de 4 points ; la Faiblesse au-delà de 2 — *Édit*, ou *Sommation* plus la Puissance du Paladin, qui en ajoute à la première Faiblesse de la carte (`power_rules.dart:27-32`), affichent « Faiblesse 3 » ou plus quand le pipeline en compte 2 (`proportional_status.dart:18-19`, `:25-30`) | À la file, pas traité ici |
| La fin de la phase ennemie jouée après une victoire par les statuts (compte rendu de la vague 7, S9) : *Prière*, comme *Bénédiction*, y soigne d'un tour de trop | À la file — non bloquant : aucune carte du lot ne pose de Feu ni de Poison sur le héros |
| `tool/simulations/d26_economy_sim.dart`, qui nomme les cartes déplacées : gelé depuis ADR-108 | — |

### 2.1. Les transitions

| Frontière | État | Réglé par |
|:---|:---|:---|
| E4 → tranche 3 | Depuis `0.5.6`, *Projectile Magique* est une Compétence et *Marque du Mage*, sur `onAttackPlayed`, ne se déclenche plus sur elle (`combat_signature_test.dart:290-299` le garde) ; le passif est masqué de `0.5.7` à `0.5.9` | D34 (A1, A2) : la signature marque de nouveau, hors *Nova* (A3, **provisoire**) ; le test se renverse |
| Tranches 1 → 2 → 3 | Trois passifs masqués depuis `0.5.7` ; `fireball` neutre jusqu'au lot Marque | A13 : démasqués par la donnée ; A12 : `fireball` garde son id |
| Charges élémentaires → tranche 3 | Les quatre élémentaires et la Faiblesse de Sanctifié s'écrivent sur les règles livrées en vague 7 | Aucun moteur neuf : une carte qui pose une charge pose un `statusId` du catalogue ; `targetStatus` lit la somme des entrées de même id ; la Faiblesse garde son barème et son tic (A19) |
| Tranches → P-44 lots 2 à 4 | *Forge de guerre* ne s'écrit pas avant `0.6.0` | Carnage atteint cinq cartes sans elle (A15) ; la session de clôture la porte en ROADMAP (orchestration §8.9) |
| Le pool des autres passifs | Sous les six autres passifs, la trouvaille, la boutique et le draft de départ n'offrent plus les quatre élémentaires, *Métallisation* ni *Cri de Guerre* : ils quittent le noyau neutre | Voulu (brainstorm §7, revue annexe B.4) ; à dire dans la note de version |
| Sauvegardes de `0.5.9` | Elles ne se relisent pas forcément | Avant la `1.0.0`, rien (§8) |

---

## 3. Données

### 3.1. Les passifs

`assets/data/passives/mage_mark.json` — le déclencheur, la description ; `value`, `duration`, `feeds`,
`displayOrder` et `mastery` ne changent pas :

```json
{
  "id": "mage_mark",
  "name_en": "Mage's Mark",
  "name_fr": "Marque du Mage",
  "description_en": "Each turn, the first damage card, Attack or Skill, that hits a single enemy without killing it applies 2 Vulnerable to it for 2 turns.",
  "description_fr": "À chaque tour, la première carte de dégâts, Attaque ou Compétence, qui vise un seul ennemi sans le tuer lui applique 2 Vulnérable pendant 2 tours.",
  "classes": ["mage"],
  "feeds": ["damage", "status:vulnerable", "scale:targetStatus"],
  "trigger": "onDamagingCardPlayed",
  "effectType": "mage_mark",
  "value": 2,
  "duration": 2,
  "displayOrder": 2,
  "mastery": {
    "field": "duration",
    "perPoint": 1,
    "description_en": "+{amount} turn of Vulnerable",
    "description_fr": "+{amount} tour de Vulnérable"
  }
}
```

`assets/data/passives/frenzy.json` : `"feeds": ["damage", "scale:targetMissingHp", "scale:enemiesAlive"]`, le reste
inchangé. `assets/data/passives/blessing.json` : `"feeds": ["armor", "status:armor_regen", "status:weakness",
"status:hp_regen", "heal"]`, le reste inchangé (D60).

Dans la description de *Marque du Mage*, « qui vise un seul ennemi » / « a single enemy » est **(provisoire)** : il
dit l'option (c) d'A3 (§1.4), et changerait sous (a) ou (b) ; « sans le tuer » / « without killing it » est
**(provisoire)** : il dit l'option (ii) d'A4, et disparaîtrait sous (i).

### 3.2. Les trois lots

Toutes communes ; aucune à épuisement (les Pouvoirs s'épuisent par leur type) ; descriptions de fichier
identiques au texte que lit le joueur. **Chaque fichier s'écrit dans la mise en forme de ses voisins** (deux
espaces, une clé par ligne, un objet par effet, `"id"` égal au nom du fichier) ; le répertoire porte le passif.
Les six cartes déplacées gardent leur fichier à l'octet près.

**Sanctifié** — `assets/data/cards/blessing/`, Paladin (Puissance sur les Attaques, les Compétences et les
altérations). Durées de Faiblesse : A19.

| Fichier | Nom FR / EN | Coût | Type, cible | Effets | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|
| `summons` | Sommation / Summons | 1 | Compétence, ennemi, `magic` | `weakness` 1, 3 tours | « Applique 1 Faiblesse pendant 3 tours. » / « Apply 1 Weakness for 3 turns. » |
| `edict` | Édit / Edict | 2 | Compétence, tous, `magic` | `weakness` 2, 2 tours | « Applique 2 Faiblesse à tous les ennemis pendant 2 tours. » / « Apply 2 Weakness to all enemies for 2 turns. » |
| `rebuke` | Réprimande / Rebuke | 1 | Compétence, ennemi, `magic` | `armor` 4 ; `weakness` 1, 2 tours | « Gagne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. » / « Gain 4 Block. Apply 1 Weakness for 2 turns. » |
| `prayer` | Prière / Prayer | 2 | Pouvoir, soi, `buff` | `hp_regen` 2, 3 tours | « Pendant 3 tours, récupère 2 PV au début du tour. » / « For 3 turns, heal 2 HP at the start of your turn. » |
| `metallicize` | Métallisation / Metallicize | 1 | Pouvoir, soi | `armor_regen` 2, 2 tours | déplacée de `cards/`, inchangée |

**Carnage** — `assets/data/cards/frenzy/`, Berserker (Puissance sur les Attaques ; Armure → Puissance 1 tour, à
0,5:1, D37).

| Fichier | Nom FR / EN | Coût | Type, cible | Effets | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|
| `windmill` | Moulinet / Windmill | 2 | Attaque, tous, `magic` | `damage` 7 | « Inflige 7 dégâts à tous les ennemis. » / « Deal 7 damage to all enemies. » |
| `whirlwind` | Tourbillon / Whirlwind | 1 | Attaque, tous, `magic` | `damage` 2 ; `draw` 1 | « Inflige 2 dégâts à tous les ennemis et pioche 1 carte. » / « Deal 2 damage to all enemies and draw 1 card. » |
| `coup_de_grace` | Coup de grâce / Coup de Grâce | 3 | Attaque, tous, `magic` | `damage` 10 | « Inflige 10 dégâts à tous les ennemis. » / « Deal 10 damage to all enemies. » |
| `execution` | Exécution / Execution | 1 | Attaque, ennemi, `melee` | `damage` 4, `scaleWith` `targetMissingHp` × 0,2 | « Inflige 4 dégâts, +1 par tranche de 5 PV manquants de la cible. » / « Deal 4 damage, +1 per 5 missing HP on the target. » |
| `warcry` | Cri de Guerre / Warcry | 2 | Attaque, tous | `damage` 4 ; `armor` 4 | déplacée de `cards/`, inchangée |

**Marque** — `assets/data/cards/mage_mark/`, Mage (Puissance sur les Compétences et les altérations).

| Fichier | Nom FR / EN | Coût | Type, cible | Effets | Texte FR / EN |
|:---|:---|:---|:---|:---|:---|
| `fireball` | Boule de Feu / Fireball | 2 | Attaque, ennemi | `damage` 6 ; `burn` 2 | déplacée de `cards/`, inchangée ; **id du tutoriel** |
| `ice_bolt` | Trait de Glace / Ice Bolt | 1 | Attaque, ennemi | `damage` 4 ; `freeze` 2 | déplacée, inchangée |
| `thunder_clap` | Coup de Tonnerre / Thunderclap | 1 | Attaque, ennemi | `damage` 4 ; `shock` 1 | déplacée, inchangée |
| `poison_stab` | Coup Empoisonné / Poison Stab | 1 | Attaque, ennemi | `damage` 3 ; `poison` 1, 2 tours | déplacée, inchangée |
| `exploit` | Exploitation / Exploit | 2 | Compétence, ennemi, `magic` | `damage` 4, `scaleWith` `targetStatus` (`vulnerable`) × 1 | « Inflige 4 dégâts, +1 par point de Vulnérable de la cible. » / « Deal 4 damage, +1 per point of Vulnerable on the target. » |
| `volley` | Salve / Volley | 1 | Compétence, ennemi, `magic` | `damage` 2, `hits` 3, `mightRatio` 0,5 | « Inflige 2 dégâts 3 fois. » / « Deal 2 damage 3 times. » |

Les quatre effets neufs qui sortent de la forme courante :

```json
{ "type": "apply_status", "statusId": "hp_regen", "value": 2, "duration": 3 }
{ "type": "damage", "value": 4, "scaleWith": { "source": "targetMissingHp", "ratio": 0.2 } }
{ "type": "damage", "value": 4, "scaleWith": { "source": "targetStatus", "ratio": 1, "statusId": "vulnerable" } }
{ "type": "damage", "value": 2, "hits": 3, "mightRatio": 0.5 }
```

Dans *Réprimande*, l'Armure précède la Faiblesse dans `effects` ; la Faiblesse est le premier `apply_status` de la
carte et reçoit seule la Puissance de statut (Q11).

**Écarts au brainstorm** (§7.2, §7.3) : *Exécution* dit « +1 par tranche de 5 PV manquants de la cible » au lieu de
« ×2 si la cible a moins de 30 % PV », et *Exploitation* « +1 par point de Vulnérable de la cible » au lieu de « ×2
si la cible est vulnérable », parce que la croissance livrée (`scaleWith`) les écrit sans mécanisme neuf (A8, A9) ;
*Salve* frappe 2 × 3 au lieu de 2 × 2, parce qu'à 4 dégâts pour 1 mana elle serait dominée par *Frappe* (6), et que
chaque coup de plus est un coup que Vulnérable et la Foudre amplifient (A16).

**Contrôles** : chaque carte touche son `feeds` — Sanctifié par `status:armor_regen`, `status:weakness`,
`status:hp_regen` ou `armor` ; Carnage par `damage` (et *Exécution* par `scale:targetMissingHp`) ; Marque par `damage`
(et *Exploitation* par `scale:targetStatus`) ; Σ `hits` × `mightRatio` : 1,5 ≤ 2 (*Salve*), 1 ailleurs ≤ coût + 1 ;
`mightRatio` < 1 sur le seul multi-coups ; `scaleWith` sur une base de 4 ≥ 1 ; `targetStatus` et `targetMissingHp`
sur des cartes `singleEnemy` (`card_data.dart:237-256`) ; aucune carte à coût total nul, aucun coût en PV ou en
Armure ; aucun id ni nom déjà pris (vérifié le 18/11 sur `assets/data/` : *Cleave* est le nom anglais de l'évolution
*Fauchage* de *Frappe Téméraire*, `classes/berserker/skills/reckless_strike.json:107-110` — d'où `windmill`).

### 3.3. Les déplacements

Six `git mv`, sans retouche : `cards/{fireball,ice_bolt,thunder_clap,poison_stab}.json` → `cards/mage_mark/`,
`cards/metallicize.json` → `cards/blessing/`, `cards/warcry.json` → `cards/frenzy/`. Aucun test ne lit ces
fichiers par leur chemin : ceux qui les jouent passent par le registre (`effect_resolver_test.dart:376-377`,
`multi_hit_test.dart:251-252`, la matrice des runes de `forge_upgrades_catalog_test.dart:258`). L'aide
`shippedCard` (`test/unit/shipped_data.dart:25-26`) ne lit que `cards/<id>.json` à plat : aucun de ses appels ne vise
une carte déplacée.

### 3.4. Les neutres

Le noyau neutre passe de 15 à **9 cartes**, celles que le brainstorm garde (§7.4) : `strike_basic`, `defend_basic`,
`quick_attack`, `heavy_strike`, `sweep`, `iron_wall`, `awakening`, `concentration`, `heal_potion`. Aucune ne change.
`heal_potion` reste neutre (§7.1, la note) ; `concentration` reste la carte gratuite du noyau.

| Lecteur | Ce qui change |
|:---|:---|
| Draft de départ (`starter_draft.dart:22-36`) | Le groupe du lot montre 5 ou 6 cartes, quota 2 ; le groupe neutre en montre 9 au lieu de 15, quota 3 — pour toutes les classes et tous les passifs |
| Trouvaille, boutique, `starterPool` du tutoriel | `isOfferable(passif actif)` : les neuf neutres et le seul lot du passif actif |
| Dictionnaire des cartes (`card_dictionary_screen.dart:85-104`) | Toutes les cartes du registre, 58, groupées par type comme aujourd'hui : rien ne change de forme |

### 3.5. Les autres données et les comptes

- `assets/data/effect_icons.json` gagne `status:hp_regen` (A7), après `status:mana_regen` : 18 sortes.
- `pubspec.yaml` : trois lignes `assets/data/cards/blessing/`, `…/frenzy/`, `…/mage_mark/`, écrites par
  `dart run tool/sync_assets.dart`.
- Comptes : `registry.cards` **58** (9 neutres + 49 de lot, dont 16 dans les trois dossiers neufs) ; fichiers
  d'entité 133 → **143** (dix fichiers neufs ; les déplacements ne comptent pas) ; neuf passifs, tous disponibles,
  trois par classe.

---

## 4. Le moteur

### 4.1. `onDamagingCardPlayed`

| Élément | Changement |
|:---|:---|
| `RelicTrigger` (`relic_data.dart:5-21`) | `onDamagingCardPlayed`, après `onDamageTaken`, son commentaire nommant son seul lecteur, *Marque du Mage* |
| `EffectiveCard` | `bool get dealsDamage` : un effet `damage` parmi `addedEffects` ou `effects` (A2) |
| `CombatController._afterCardPlayed` (`combat_controller.dart:296-325`) | Après le déclencheur du type : `if (card.effective.dealsDamage) TraitSystem.dispatch(runController, PassiveEvent(RelicTrigger.onDamagingCardPlayed, card: card, enemyId: enemyId))` ; pas d'`applyRelics` (A5) |
| `PassiveEvent.card` (`passive_strategy.dart:15-17`) | Son commentaire compte `onDamagingCardPlayed` parmi les déclencheurs qui la renseignent |
| Les trois `switch` d'affichage (A5) | Un cas, `l10n.relicTriggerDamagingCardPlayed` |

L'écho ne déclenche aucun événement « carte jouée » (P-3 de la vague 5) : une carte de dégâts rejouée par *Résonant*
ne marque pas une seconde fois. Un seul passif étant actif, l'ordre des trois envois ne départage rien.

### 4.2. *Marque du Mage*

`MageMarkPassive` (`passive_strategies.dart:62-95`) : sans `enemyId`, rien — la carte de groupe ne marque ni ne
consomme (A3, **provisoire**) ; une cible absente **ou à
`currentPv <= 0`** ne consomme pas le compteur (A4, **provisoire**) ; sinon le compteur de tour (`:79`) et la pose, inchangés. Son
commentaire dit « la première carte de dégâts du tour » au lieu de « la première Attaque ». Les points
s'additionnent d'un tour à l'autre sur la même cible (A9) ; le pipeline les plafonne à 4.

### 4.3. `hp_regen`

| Où | Quoi |
|:---|:---|
| `EffectResolver.createStatus` | `'hp_regen'` → `StatusEffect(id: 'hp_regen', name: 'Source de Vie', type: StatusType.buff, value:, duration:)` |
| `processPlayerStatuses` (`status_effect_processor.dart:18-89`) | Somme avant le tic ; après le tic, `currentPv = min(maxPv, currentPv + somme)` si `currentPv > 0` |
| `processEnemyStatuses` (`:94-141`) | La même règle, pour un ennemi (A6) |

L'ordre du début de tour reste celui de la vague 7 (Feu, Poison, Éveil, tic, Métallisation, Source de Mana, déclins)
; la Source de Vie se joue avec la Métallisation et la Source de Mana, après le Poison : un porteur que son Poison
tue n'est pas relevé. *Bénédiction* soigne au même début de tour par sa stratégie (`passive_strategies.dart:140-152`)
; les deux soins s'additionnent sous les PV max.

### 4.4. La Faiblesse

Moteur inchangé (A19) : le barème de la vague 5 (`proportional_status.dart:18-19`, −25 % par point, 2
points au plus), lu par le pipeline sur l'attaquant (`damage_pipeline.dart:21-26`), et le tic de début de tour du
porteur. Les cartes de Sanctifié sont les premières à poser la Faiblesse depuis une carte ; seule *Sentence* la
posait jusqu'ici, depuis une évolution.

### 4.5. Ce qui ne change pas

`scaleWith` et ses six sources (`card_data.dart:76-83`, `effect_resolver.dart:230-257`) : aucune source neuve,
*Exécution* et *Exploitation* sont les premières cartes à lire `targetMissingHp` et `targetStatus` ; les règles de
chargement (`scaleWith` refusé sur un multi-coups, `card_data.dart:200` ; source de cible exigeant `singleEnemy`,
`:237-256`) ; `availablePassivesFor` et le draft de départ (A13, §3.4) ; *Frénésie* et *Bénédiction*, hors leurs
`feeds` ; les charges ; `maxMana`.

---

## 5. Les écrans

Aucun écran ne change de forme. Ce que le joueur voit de neuf passe par les listes existantes :

| Écran | Ce qui s'y ajoute |
|:---|:---|
| Sélection de classe, fiche du héros, tutoriel | Trois passifs par classe ; la description neuve de *Marque du Mage* |
| Draft de départ | Les trois lots neufs ; un groupe neutre de 9 cartes |
| Faces et infobulles (Flutter, Flame) | L'icône et la ligne d'`hp_regen` ; la ligne de croissance de `targetMissingHp` et de `targetStatus`, celle-ci nommant le statut dans la langue du joueur (A10) |
| Panneau des effets du héros | « Source de Vie : +2 », cœur rose (A7, A20) |
| Panneau de l'ennemi | Vulnérable posé par une carte de dégâts ; Faiblesse posée par les cartes de Sanctifié — l'indicateur existe déjà (`status_indicator.dart`) |

---

## 6. Textes joueur

### 6.1. La donnée

Les textes des seize cartes sont ceux de §3.2 ; celui de *Marque du Mage*, de §3.1. *Bénédiction* et *Frénésie*
gardent leurs descriptions : « Au début du tour, chaque tranche de 5 points d'Armure survivante devient 1 PV. » et
« Chaque ennemi abattu donne 2 Puissance pour le tour et fait piocher 1 carte. » restent vraies.

### 6.2. Clés ARB (`app_fr.arb`, `app_en.arb`)

Métadonnées `@` dans `app_en.arb`, le gabarit ; `amount`, `duration`, `value` de type `int`. `@cardDescStatusHpRegen`
déclare `amount` **puis** `duration`, comme `@cardDescStatusManaRegen`. Après la retouche : `flutter gen-l10n`.

| Clé | FR | EN |
|:---|:---|:---|
| `statusHpRegen` | `Source de Vie : +{value}` | `Life Spring: +{value}` |
| `cardDescStatusHpRegen` | `Pendant {duration} tours, récupère {amount} PV au début du tour.` | `For {duration} turns, heals {amount} HP at turn start.` |
| `relicTriggerDamagingCardPlayed` | `Carte de dégâts jouée` | `Damage Card Played` |
| `statusName` *(sélection sur `id`)* | `poison` Poison · `might` Puissance · `weakness` Faiblesse · `vulnerable` Vulnérable · `might_regen` Éveil de Puissance · `mana_regen` Source de Mana · `armor_regen` Métallisation · `hp_regen` Source de Vie · autre : l'id | Poison · Might · Weakness · Vulnerable · Might Awakening · Mana Spring · Plated Armor · Life Spring · autre : l'id |

Les noms anglais de `statusName` reprennent ceux des clés `status*` existantes (`app_en.arb:607-648`). Le placeholder `id` de `statusName` est
déclaré de type `String`. Ces noms existent désormais en trois exemplaires — `createStatus`
(`effect_resolver.dart:31-87`), les clés `status*`, `statusName` — : un test de données garde l'accord du premier et
du troisième (§9).

### 6.3. Le tutoriel

Aucune clé, aucune étape ne change. Le tutoriel montre *Boule de Feu* à l'étape des cartes (A12), propose trois
passifs à chaque classe, préselectionne le premier (A13), et lit la description de *Marque du Mage* dans la donnée.
Sa galerie des statuts ne gagne pas `hp_regen`, comme elle n'a pas gagné `mana_regen`.

---

## 7. L'éditeur de contenu

**Rien à coder.** Le vocabulaire neuf y paraît de lui-même :

| Vocabulaire | Lu où |
|:---|:---|
| Le déclencheur `onDamagingCardPlayed` | L'énumération `trigger` du passif et de la relique, `_names(RelicTrigger.values)` (`entity_descriptor.dart:369`, `:391`) |
| Le statut `hp_regen` ; `weakness` sur une carte | `effects[].statusId`, vocabulaire dérivé des fichiers (`known_values.dart:7-13`) dès que *Prière* et les cartes de Sanctifié existent |
| Les sources `targetMissingHp`, `targetStatus` | Déjà dans `effects[].scaleWith.source` (`entity_descriptor.dart:240`) |
| La touche de `feeds` et le validateur des lots | `PassiveFeeds`, `LotRules`, que lit déjà l'éditeur |

L'aller-retour des entités livrées (`test/unit/content_editor/shipped_entities_round_trip_test.dart`) couvre les dix fichiers neufs et les
trois passifs retouchés.

---

## 8. La sauvegarde

**Rien de neuf n'est sauvegardé ; aucun `schemaVersion` ne change.** `hp_regen` est un statut de combat, et la
sauvegarde n'est jamais écrite en combat (`CLAUDE.md`, `SaveService`) ; le passif actif se relit par son id, la carte
par le sien — un déplacement de dossier ne change aucun des deux. Avant la `1.0.0`, les sauvegardes ne se
transfèrent pas d'une version à l'autre : rien d'autre à prévoir.

---

## 9. Tests

**Sous D77** : calculs, données, contrôleurs, sauvegarde ; aucun test d'écran. La base se re-mesure au début du
plan (1772 à la fin de la vague 7, compte rendu §1, avant le correctif `ab1e0e32`). Le Berserker a 10 % de critique :
tout test de dégâts qui le joue met `critChance` à 0.

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| **Le déclencheur** | `test/unit/passive_triggers_test.dart` | `onDamagingCardPlayed` atteint le passif pour une Attaque et une Compétence de dégâts, une signature de dégâts, une carte de groupe de dégâts ; pas pour une carte sans effet `damage` (*Embrasement*, `concentration`) ; une rune ou une évolution qui ajouterait un effet `damage` rend la carte « de dégâts » (`dealsDamage` sur une vue effective construite par le test) |
| ***Marque du Mage*** | `test/unit/passives_mage_test.dart`, groupe « Marque du Mage » (`:301-437`) | Réécrit sur D34 : la première carte de dégâts, Attaque ou Compétence, marque ; la deuxième non ; au tour suivant, la marque revient ; **« une Compétence ne marque jamais » (`:338`) se renverse** ; une carte sans dégâts ne marque ni ne consomme ; une carte de groupe ne marque ni ne consomme, et la carte à cible unique suivante marque (`:384`, complété —
A3, **provisoire**) ; une cible absente ne consomme pas (`:418`, inchangé) ; **une cible tuée par la carte ne consomme pas, la carte suivante marque** (A4, **provisoire**) ; deux marques sur la même cible s'additionnent |
| La signature | `test/unit/combat_signature_test.dart:290-299` | Renversé : *Projectile Magique* pose 2 Vulnérable sous *Marque du Mage* ; **un test neuf, « *Projectile Magique* évolué en *Nova* ne marque personne et ne consomme pas le tour »** (A3 (c), **provisoire**) |
| **`hp_regen`** | `test/unit/hp_regen_test.dart` *(nouveau, sur le modèle de `mana_regen_test.dart`)* | Posé pour 3 tours, +valeur au début des trois tours suivants, rien au quatrième ; borné aux PV max ; **aucun soin à 0 PV** (le Poison du même début de tour tue, la Source ne relève pas) ; le même calcul sur un ennemi ; `createStatus('hp_regen')` buff |
| **Les cartes** | `test/unit/tranche_3_cards_test.dart` *(nouveau)* | Par le contrôleur, `critChance` à 0 : *Exécution* sur une cible à 20 PV manquants fait 8, sur une cible saine 4 ; *Exploitation* sur une cible à 0, 2 et 6 points de Vulnérable fait 4, puis (4 + 2) × 1,5, puis (4 + 6) × 2 ; *Salve* : trois coups, la Puissance du Mage ×0,5 arrondie par coup ; *Moulinet* et *Coup de grâce* touchent chaque ennemi vivant, la Puissance du Berserker par ennemi ; *Tourbillon* pioche ; *Édit* pose la Faiblesse sur tous ; *Réprimande* : l'Armure au héros, la Faiblesse à la cible, la Puissance du Paladin sur la Faiblesse ; *Prière* pose `hp_regen` ; **la Faiblesse de *Sommation* réduit les deux attaques suivantes de la cible et pas la troisième** (A19) |
| Frénésie | `test/unit/passives_berserker_test.dart` | Une Attaque de groupe qui tue deux ennemis donne 4 Puissance et deux pioches |
| Les textes | `test/unit/card_rule_texts_test.dart` | La croissance `targetStatus` sur `vulnerable` dit « Vulnerable » en anglais, « Vulnérable » en français (A10) ; celle de `targetMissingHp` à 0,2, « +1 per 5 missing HP on the target » ; **pour chaque id couvert par `statusName`, le nom français égale `createStatus(id).name`** |
| **Le catalogue** | `test/unit/card_catalog_test.dart` | La table `_lots` gagne les 16 cartes, le test des lots (`:211-239`) dit « les 49 cartes de lot » ; les neuf lots comptent 6, 6, 6, 5, 5, 5, 5, 5, 6 (`:241-275`), toutes communes, seules `laceration` et `meditation` s'épuisent ; D12 (`:336-350`) exige au moins une carte `targetStatus` et une `targetMissingHp` ; **D45 (`:277-284`) et D50 (`:302-334`) bouclent sur les neuf lots sans changer** |
| **Aucun passif masqué** | `test/unit/referential_integrity_test.dart` | Neuf `feeds` (`:395-411`) ; `status:hp_regen` créé par `createStatus` ; **chaque passif livré est disponible pour sa classe** (test neuf, à côté de `:432`) |
| La disponibilité | `passives_paladin_test.dart`, `passives_berserker_test.dart`, `passives_mage_test.dart:507-516` | Trois passifs par classe, dans l'ordre d'A13 |
| Données livrées | `test/unit/real_bundle_load_test.dart` | 9 neutres, 49 de lot (`:37-38`), 58 cartes (`:101`), 18 sortes d'icônes (`:203`) ; `mage_mark` sur `onDamagingCardPlayed` |
| Comptes | `entity_id_convention_test.dart:72-81`, `audio/audio_catalogue_test.dart:53` | 143 fichiers d'entité ; 96 fichiers de contenu audio (58 cartes + 28 reliques + 6 signatures + 4 ennemis) |
| Les runes | `test/unit/forge_upgrades_catalog_test.dart:255-258`, `:482` | La matrice de l'offre aux 58 cartes : les dix neuves y prennent leur ligne |
| **Le tutoriel** | `test/tutorial/tutorial_fixtures_test.dart:59-63`, `:102-109` | `fireball` se résout toujours par son id, reste une Attaque qui pose `burn`, et porte désormais `passive == 'mage_mark'` ; le premier passif de chaque classe est inchangé ; `tutorial_engine_test.dart:94` sème toujours *Boule de Feu* |
| Le passif en donnée | `test/unit/passive_data_test.dart` | `trigger: onDamagingCardPlayed` se lit |
| `sync_assets` | `test/unit/sync_assets_test.dart` | `dart run tool/sync_assets.dart --check` passe avec les trois dossiers |

### 9.1. Les tests manuels

Le fichier de tests manuels de la vague les reprend. Plusieurs ennemis demandent l'acte 2 ou plus (A15) : l'onglet
Run du menu de debug passe d'acte ; l'onglet Deck ajoute une carte au deck maître ; l'onglet Combat règle les PV d'un
ennemi.

| # | Écran | Ce que fait le propriétaire | Ce qu'il doit voir |
|:---:|:---|:---|:---|
| M1 | Sélection de classe | Ouvre les trois classes, en français puis en anglais | Trois passifs chacune, le premier préselectionné comme avant ; la description neuve de *Marque du Mage* |
| M2 | Draft de départ | Démarre sous *Bénédiction*, *Frénésie*, *Marque du Mage* | 2 cartes du lot et 3 neutres ; le groupe neutre montre 9 cartes ; sous *Flux de Mana*, plus d'élémentaire |
| M3 | Combat : la Marque | Mage sous *Marque du Mage* : joue *Projectile Magique*, puis *Exploitation* sur la même cible | Vulnérable 2 sur la cible après la signature ; *Exploitation* frappe plus fort ; une seconde carte de dégâts ne remarque pas ; au tour suivant, la marque revient |
| M4 | Combat : ce qui ne marque pas | Ouvre le tour par `concentration`, puis par *Balayage*, puis joue *Salve* | Ni l'une ni l'autre ne marque (*Balayage* : A3, **provisoire**) ; *Salve*, Compétence, marque |
| M5 | Combat : la cible tuée | Ouvre le tour par une carte de dégâts qui tue sa cible, puis frappe un autre ennemi | Le second ennemi est marqué (A4, **provisoire**) |
| M6 | Les faces | *Exécution*, *Exploitation*, *Salve*, *Prière* au dictionnaire, en main et en combat, FR puis EN | « +1 par tranche de 5 PV manquants de la cible », « +1 per point of Vulnerable on the target », « 2×3 » ; en main, la face affiche la base (4) tant qu'aucune cible n'est visée — à juger |
| M7 | Combat : Vulnérable qui s'accumule | Marque la même cible quatre tours de suite, puis joue *Exploitation* | L'ennemi affiche Vulnérable 8 ; *Exploitation* compte 8, le pipeline plafonne à +100 % — à juger (A9) |
| M8 | Combat : *Salve* et la Foudre | *Coup de Tonnerre* puis *Salve* sur la même cible | Chaque coup de *Salve* reçoit le bonus de Foudre |
| M9 | Combat : Carnage | À l'acte 3, sous *Frénésie* : *Moulinet* ou *Coup de grâce* qui tue deux ennemis, puis une autre Attaque de groupe | +4 Puissance et deux pioches ; l'Attaque suivante frappe chaque ennemi de +4 ; à l'acte 1, juger le lot face à un seul ennemi |
| M10 | Combat : *Exécution* | Sur un ennemi à moins d'un cinquième de ses PV, puis sur un boss à mi-vie | L'ennemi meurt ; contre le boss, juger le terme (A8) |
| M11 | Combat : Sanctifié | Paladin sous *Bénédiction* : *Sommation* sur un ennemi, *Défense* ou *Réprimande*, fin de tour, sur trois tours | La Faiblesse réduit les deux attaques suivantes, pas la troisième (A19) ; l'Armure qui survit devient des PV au début du tour |
| M12 | Combat : *Édit* | Devant trois ennemis | Faiblesse 2 sur chacun ; leur prochaine attaque est réduite de moitié |
| M13 | Combat : *Prière* | Joue *Prière* blessé | « Source de Vie : +2 », cœur rose, 3 tours au panneau ; +2 PV au début des trois tours suivants, jamais au-delà du maximum |
| M14 | Le tutoriel | Paladin, puis Mage | L'étape des cartes montre *Boule de Feu* ; le Mage voit trois passifs ; rien ne casse |
| M15 | Le pool des autres passifs | Run sous *Rage*, sous *Canalisation* : boutique, trouvaille | Ni élémentaire, ni *Métallisation*, ni *Cri de Guerre* |
| M16 | *Sentence* | Paladin, évolution *Sentence* de *Châtiment* (entrée de debug des évolutions), sur deux tours | Le nombre d'attaques réduites — point d'observation du décalage porté à la file (§2) |

---

## 10. Le découpage

**Un seul plan.** Le lot est moyen : un déclencheur et son prédicat, une stratégie retouchée, un statut, une clé de
nom, seize fichiers de données et trois passifs, sans écran neuf ni animation. Rien n'impose d'ordre entre deux
livraisons ; à l'intérieur du plan, le moteur (déclencheur, `hp_regen`, nom du statut) précède les données, dont les
tests lisent le moteur. Si le propriétaire tranche A3 ou A4 autrement que la recommandation, le changement reste
dans le même plan : sous A3 (b), la stratégie de *Marque du Mage*, sa description (§3.1, §11), le test
`passives_mage_test.dart:384`, le test *Nova* et M4 ; sous A3 (a), de plus, le calcul des ennemis visés — sans
champ neuf sur `PassiveEvent`, qui ne porte qu'`enemyId` (`passive_strategy.dart:19-21`) : la stratégie lit la cible
de `event.card` et marque les ennemis vivants qu'elle vise — ; sous A4 (i), la condition `currentPv <= 0` de la
stratégie, « sans le tuer » dans la description (§3.1, §11), le test de la cible tuée et M5.

---

## 11. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| ADR « la tranche 3 » — le déclencheur `onDamagingCardPlayed` et le prédicat de carte de dégâts (D34), la Marque sur une cible vivante et à cible unique (A4 et A3, telles que le propriétaire les aura tranchées), `hp_regen` symétrique (D55), le nom traduit du statut de `targetStatus` ; **complète ADR-112** (forme C : neuf lots, aucun passif masqué — la règle d'O5 reste, sans plus rien masquer), **ADR-111** (premières cartes à `targetMissingHp` et `targetStatus` ; la Faiblesse posée par des cartes) et **ADR-116** (`hp_regen` sur le modèle de `mana_regen`) ; **clôt** ce que **ADR-109** disait de la Marque perdue par *Projectile Magique* | `memory-bank-sync` |
| Fiches `_rules/02-2` (les passifs : `mage_mark` sur `onDamagingCardPlayed`, neuf jouables), `02-3` (catalogue : 9 neutres, 49 de lot, 58), `04-00` (`hp_regen` ; la Faiblesse posée par Sanctifié ; Vulnérable par toute carte de dégâts), `03-14` (les deux sources de cible ont leurs cartes), `08-00` (le tutoriel : *Boule de Feu* au lot Marque, trois passifs par classe), `07-00` (trois dossiers de lot de plus) ; `_patterns/02-2` (`_afterCardPlayed` envoie `onDamagingCardPlayed`), `03-4` (`createStatus('hp_regen')`), `07-00` (le flux du tour : la Source de Vie), `05-13` (18 sortes d'icônes) — un minimum, que le diff complétera | `memory-bank-sync` |
| **P-42 se clôt** dans `docs/ROADMAP.md`, comme P-43 en vague 4 et P-53 en vague 7 | `memory-bank-sync`, à la fin de la vague |
| La note de version | Celle de la vague, écrite à la fin par `patch-notes-writer` ; ce lot n'en prévoit pas d'autre, ni de lien dans `docs/ROADMAP.md` |

**Ce que le joueur voit en `0.6.0`** : les neuf passifs sont jouables, chacun avec son lot — *Bénédiction* avec
Sanctifié (la Faiblesse, la Métallisation, *Prière*), *Frénésie* avec Carnage (les Attaques de groupe et
*Exécution*), *Marque du Mage* avec Marque (les quatre élémentaires, *Exploitation*, *Salve*) ; *Marque du Mage* se
déclenche sur la première carte de dégâts du tour qui vise un seul ennemi sans le tuer (A3 et A4, **provisoires**),
Attaque ou Compétence, et donc de nouveau sur *Projectile Magique*, hors *Nova*. **À dire dans la note** : les quatre élémentaires, *Métallisation* et *Cri
de Guerre* quittent les cartes neutres pour leur lot — sous les autres passifs, ils ne sont plus offerts. **À ne pas
dire** : une règle de la Faiblesse — son décompte ne change pas (A19).

**Ce que le vérificateur contrôle** :

- **le tutoriel tourne avec `fireball`** : `flutter test test/tutorial/` vert, `tutorial_fixtures_test.dart` résout
  `fireball` dans le registre et le trouve sous `mage_mark` ; `git grep -n "'fireball'" -- lib` ne rend que
  `lib/tutorial/tutorial_fixtures.dart:21` ;
- **les neuf lots passent D45 et D50** : les deux tests de `card_catalog_test.dart` bouclent sur les neuf lots,
  inchangés, et sont verts ;
- **aucun passif n'est resté masqué** : le test neuf de `referential_integrity_test.dart` ; `availablePassivesFor`
  rend trois passifs pour chaque classe du registre livré ;
- `git grep -n "onAttackPlayed" -- assets/data/passives` ne rend que `bloodthirst.json` ;
  `ls assets/data/cards/*.json` ne liste aucune des six cartes déplacées ;
- la Faiblesse n'a pas changé (A19) : `git diff main -- lib/game/services/proportional_status.dart
  lib/game/services/damage_pipeline.dart` ne rend rien ;
- aucune règle des charges ne change : `git diff main -- assets/data/charges lib/game/systems/charge_rules.dart` ne
  rend rien ;
- aucun test d'écran neuf (D77) : `git diff main -- test | grep -c '^+.*testWidgets('` rend `0` ;
- `dart run tool/sync_assets.dart --check` passe ; `dart analyze` propre ; `flutter test` vert.
