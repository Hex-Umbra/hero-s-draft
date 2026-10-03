# P-43 E3 — Trouvaille et progression — Conception

Date : 2026-10-03
Statut : **Conception, non convergée au quatrième tour** — vague 3 (`0.5.5`), lot unique et lourd (deux parties),
branche `feat/v0.5.5-p43-e3-trouvaille`. **La vague est de nouveau arrêtée.** Le troisième tour avait rendu trois
constats moyens et arrêté la vague (orchestration §3.3 et §6) ; le propriétaire a levé l'arrêt, les treize constats
sont corrigés (arbitrages en §1.2), et le quatrième tour qu'il demandait rend encore deux constats moyens — ouverts en
§13, avec les dix autres et les recommandations de l'orchestrateur. Corrigée auparavant après le premier tour (22 constats, 6 moyens,
13 mineurs, 3 de rédaction ; A8 à A28 confirmés par l'orchestrateur, A1 et A7 reconsignés sur son arbitrage) et après
le deuxième (15 constats, 2 moyens, 10 mineurs, 3 de rédaction, plus une passe ciblée sur les liaisons non testées et
les pièges de test du dépôt).

Chantier ROADMAP : **P-43** « Économie unifiée », lot **E3**, le quatrième des cinq lots E0 à E4. Le déroulé fait foi
dans le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
(fiche §8.3) ; **E2**, fusionné dans `main` (`bca35c5`, PR #48), a laissé la fusion qui donne la rune, l'affûtage au
feu et le Puits sur lesquels E3 s'écrit.
Sources amont :
- [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 — **D1**, **D2**,
  **D11**, **D23**, **D24**, **D25**, **D31**, **D42**, **D43**, **D47**, **D57**, **D58**, **D59**, **D60**, **D62**,
  **D63** (Q15), **D67** : source de vérité, ni rediscutées ni amendées ici ; l'encadré de §2 sur la « pioche
  infinie », §4.1 en entier, §4.3, §5, §11 ligne E3 et nœud R, §13 Q5 et Q15 ;
- [revue du brainstorm](../../possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §3.1 E2,
  §3.2 E3, §8.1 R5 et R8, §8.2 idées 5, 7 et 12, §9, annexe A n° 5, 11, 12, 13, 20, 23 ;
- [rapport de simulation](../../possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md), §1.2, §2.1, §3.1,
  §3.3, §3.9 à §3.11, §3.16, §4, §5, §7.1 à §7.3 ; le script `tool/simulations/d26_economy_sim.dart` et sa sortie de
  référence `tool/simulations/d26_reference_output.md` ;
- [spec E2](2026-10-02-p43-e2-fusion-forge-design.md), §1.2 et §4.13 (ce qui est laissé « pour E3 »), et le
  [compte rendu de la vague 2](../reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md), §4 et §5 ;
  ADR-078, ADR-098, ADR-099, ADR-101, ADR-106, et ADR-096, ADR-097, ADR-105, ADR-081 pour ce qu'E3 complète.

> **Ce que E3 livre, en une phrase.** Chaque combat rapporte une carte commune tirée parmi celles que la classe peut
> recevoir — une seconde à 25 % en élite, deux reliques rares le modulent — ; la main maximale devient une stat de
> run ; le prix d'un niveau se lit dans une table par acte, en donnée ; la difficulté lit la qualité du deck,
> 2 × Σ `fusionRank`, et non plus sa taille ; l'affûtage sort du feu — le boss « XP » monte une rune au lieu de donner une
> carte, une relique légendaire en ajoute, un événement en monte une contre des PV, une mythique relève le plafond
> d'un type de rune — ; un événement échange une relique contre de l'or ou des soins ; *Sagesse* devient mythique ;
> *Bénédiction* et *Flux de Mana* lisent leurs seuils en donnée. **En `0.5.5`, les fusions cessent d'être rares.**

Toute référence `fichier:ligne` de ce document a été mesurée le 2026-10-03 sur `9282513`, tête de la branche, qui ne
diffère de `main` (`bca35c5`) que par le fichier d'orchestration : `git diff --stat main HEAD -- lib test assets tool`
est vide. Celles que la correction du troisième tour écrit ou touche ont été re-mesurées sur `0a4eaa0`, tête de la
branche à la levée de l'arrêt, dont `lib/`, `test/`, `assets/` et `tool/` égalent `9282513`
(`git diff --stat 9282513 HEAD -- lib test assets tool` vide). Base de tests de la vague : **1480** (journal de
l'orchestration, §2).

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce qu'E3 en livre | Où |
|:---|:---|:---|
| **D1** | Après chaque combat normal ou d'élite, des cartes tirées uniformément dans le pool que la classe peut recevoir (`CardData.isOfferableTo`, signatures exclues par `unique`), **toujours communes**, ajoutées au deck sans refus ; le boss garde sa récompense | §4.1 ; A10 |
| **D2** | Plus de plafond de deck — aucun n'existe dans le code (§1.3) ; la seule limite est la main, que toute pioche respecte, et qui devient une stat de run | §4.3 |
| **D11** | *Sagesse* (`maxMana`) passe en mythique | §3.5, §4.10 |
| **D23** | Un événement neuf échange une relique contre de l'or ou des PV | §3.4, §4.9 ; A2, A19, A20 |
| **D24** | La courbe d'XP, aplatie et **en donnée** | §3.2, §4.4 ; A1, A8 |
| **D25** | `maxHandSize` devient une stat de run ; ADR-078 D3 est amendé | §4.3 ; A6, A11 |
| **D31** (amendée par **D57**) | La table `cardDrops` par type de nœud : une carte garantie en combat normal ; en élite, une garantie et 25 % pour une seconde ; les reliques A et C, par `applyRunRuleModifier` | §3.1, §3.3, §4.1, §4.2 |
| **D42** | (a) Le boss « XP » ne donne plus de carte : une rune tirée dans tout le deck monte d'un niveau ; une relique légendaire porte ce nombre au-delà de 1 ; (b) un événement affûte ; (c) une récompense mythique monte de 1 le `maxLevel` d'une rune. **Ni pool `draft`, ni boutique, ni quatrième type de boss** | §4.6, §4.7, §4.8, §4.9 ; A3 à A5, A13 à A18, A21 |
| **D43** (amendée par **D60**) | `threshold` de *Bénédiction* en donnée ; le bloc `mastery` gagne `floor`, **2 sur *Flux de Mana* seulement**. La variante « armure conservée » attend le lot Sanctifié (vague 7) | §3.6, §4.11 ; A23, A24 |
| **D47**, **D59** | Le terme de deck de `PlayerPower` devient **2 × Σ `fusionRank`** à la place de `playerCardsCount × 2` ; les autres termes ne bougent pas | §4.5 ; A12 |
| **D57** | La relique B n'existe pas ; A (+25 % de seconde carte en élite) est **rare** ; C (+1 carte garantie en combat normal) est **rare** | §3.3 |
| **D58**, **D67** | L'XP par niveau est une table par acte : **115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015**, la dernière valeur répétée au-delà | §3.2, §4.4 |
| **D60** | *Bénédiction* : `threshold: 5`, la Maîtrise sur la valeur par tranche, sans plancher | §3.6 |
| **D62** | Chaque mythique a son propre jet de 0,5 % par niveau — déjà le cas (`level_up_reward_service.dart:127-145`) : *Sagesse* et la mythique neuve en héritent sans code | §4.8, §4.10 |
| **D63** (Q15) | L'échange de relique : la plus faible contre 40 or × (rareté + 1), ou 20 % des PV max sous 50 % des PV | A2 |

**Les réserves de la fiche, tenues.** Les valeurs de D57 à D60 et de D67 sont livrées telles que la simulation les a
mesurées (rapport §4, §7) ; aucune n'est rediscutée. Celles de D63 (Q15) et les deux défauts nommés par la fiche — la
relique légendaire de D42(a), l'événement de D42(b) — sont des valeurs de spec, confirmées ici (A2 à A4) : **aucune
relance de second temps ne vient d'elles**.

**Restent tenues, sans être relivrées** : **D72** — `maxLevel` borne chaque endroit qui écrit un niveau ; le bonus de
plafond de D42(c) en suit la liste (A17) ; **D14** — une rune, un niveau par visite au feu : les sources neuves ne sont
pas le feu ; **D20**, **D32** — le feu se paie en or, la fusion reste gratuite ; aucune source neuve ne se paie en or
(spec E2 §4.13) ; **D3**, **D13** — la fusion et l'héritage, que la trouvaille nourrit ; **D49**, **D53** — les
signatures restent des cartes jusqu'à E4 (§4.13) ; **ADR-101** — `isOfferableTo` reste le seul prédicat d'offre, la
trouvaille en devient le lecteur à la place de la carte bonus du boss « XP ».

### 1.2. Les arbitrages de la spec

Tranchés par l'arbre de décision du fichier d'orchestration (§5) : le premier filtre qui départage l'emporte. **Aucune
question ne s'est révélée ne se trancher qu'en amendant une décision acquise.** A1 à A7 sont posées par la fiche ;
les autres sont apparues à la rédaction.

**Sur le filtre 2**, la lecture de la spec E2 (§1.2) : une valeur que le script joue sans qu'une décision la fixe est
une valeur de spec — la garder ne demande aucune relance, la remplacer en demande une ; quand les filtres 3 à 6 ne
donnent aucun motif de la remplacer, **le filtre 7 la garde**. Un comportement que le script joue comme **politique**
du joueur simulé — un choix, pas une règle — n'est pas une valeur jouée : le jeu y laisse le choix au joueur, et
l'écart est consigné (§9), sans relance.

#### A1 — Où vivent les tables *(posée par la fiche — Q5)*

**`cardDrops`.**
- **(a) une constante nommée dans `GameConstants`**, à côté de `nodeQuotas` (`game_constants.dart:24-31`), en attendant
  le socle de la carte (P-50, proposé) ;
- (b) un document plat `assets/data/card_drops.json` ;
- (c) sur le nœud (`map_nodes/<variante>.json`), qui n'existe pas.

1. ne départage pas : D31 ne fixe pas le lieu. 2. à 4. neutres — les valeurs jouées sont les mêmes, et les trois formes
sont une table. **7** écarte (c) : elle suppose P-50, hors du chantier. Entre (a) et (b), d'abord la proposition de Q5
et de la fiche — `GameConstants` tant que le socle de la carte n'existe pas (brainstorm §4.1, §13 Q5 ; fiche §8.3) —,
qui n'est pas une décision acquise. **5** ne départage pas : le principe « 100 % data-driven » de `CLAUDE.md` tire vers
(b), mais `nodeQuotas`, la seule autre table indexée par `MapNodeType`, vit dans `GameConstants`. 6. et 7. neutres
entre les deux. **8** tranche : (a) est la plus simple à défaire — ni modèle, ni chargeur, ni ligne de `CLAUDE.md`, et
P-50 déplacera les deux tables ensemble. **Choix : (a)** *(consignation arrêtée par l'orchestrateur au tour 1, constat
19 ; le choix est inchangé)*.

**La table d'XP.**
- (a) une constante nommée en Dart ;
- **(b) un document plat, `assets/data/xp_curve.json`**, à côté d'`audio.json` et de `patch_notes.json`.

**1** retient (b) : D24 veut la courbe « **en donnée** », et dans ce dépôt « en donnée » veut dire un fichier sous
`assets/data/` (ADR-003 ; ADR-098, « les récompenses de niveau en donnée »). La fiche demande d'ailleurs que le script de
simulation, qui ne lit que `assets/data/` (`d26_economy_sim.dart:402-412`), lise la table du jeu (§9, second temps) :
une constante Dart lui serait illisible. **Choix : (b).** Sa forme est en §3.2.

#### A2 — Les valeurs de l'échange de relique *(posée par la fiche — D63, Q15)*

- **(a) D63 tel qu'écrit** : la relique de plus faible rareté (tirée au hasard parmi les ex æquo) contre
  40 or × (rang de rareté + 1), commune = 0 — soit 40 à 200 or ; **ou** 20 % des PV max, cette option n'étant offerte
  que sous 50 % des PV ; et une sortie sans rien ;
- (b) le joueur choisit la relique qu'il cède ;
- (c) l'or **et** les PV ensemble — « les deux » de D23 ;
- (d) l'option des PV offerte à toute santé.

1. ne départage pas : D23 admet « des PV, de l'or, ou les deux ». **2** : (a) est ce que joue le script
(`_eventRelicTrade`, `d26_economy_sim.dart:3072-3089`, défaut validé du rapport §1.2) ; (b), (c) et (d) remplacent
chacune une valeur jouée — une relance chacune. 3. à 5. neutres. 6. ne départage pas : la relique visée se lit avant
le choix (A20), la condition « sous la moitié de vos PV » se lit dans le texte du choix. **7** retient (a).
**Choix : (a). Aucune relance de second temps.** Deux gardes que le script ajoute — il ne cède rien sous trois
reliques portées, et jamais une relique du brainstorm (`:3077-3078`, « la politique ne sait pas les valoriser ») —
sont des politiques du joueur simulé, pas des valeurs : le jeu laisse ce choix au joueur (§9, écarts consignés).

#### A3 — La relique légendaire de D42(a) *(posée par la fiche — défaut joué)*

- **(a) +1 rune affûtée par exemplaire** (rapport §1.2 ; `relicD42`, `:697`, lu en `:2832`) ;
- (b) +2 par exemplaire ;
- (c) un effet non cumulable.

1. D42(a) : « porte ce nombre au-delà de 1 » — les trois le tiennent. **2** : (a) est jouée ; 3. à 6. ne donnent aucun
motif de la remplacer — une légendaire qui ne sort qu'aux tirages de reliques. **7** retient (a). **Choix : (a). Aucune
relance.**

#### A4 — L'événement d'affûtage de D42(b) *(posée par la fiche — défaut joué)*

- **(a) +1 niveau contre 10 % des PV max**, arrondis (`_eventSharpen`, `:3091-3100` : `(maxHp * 0.10).round()`) ;
- (b) contre de l'or ;
- (c) gratuit.

1. ne départage pas : D42(b) dit « une issue d'événement affûte ». **2** : (a) est jouée ; (b) et (c) la remplacent.
3. à 6. ne donnent aucun motif de la remplacer — (b) moins qu'aucune : l'or ne manque jamais (rapport §2.3, §7.2), un
prix en or ne coûterait rien. **7** retient (a). **Choix : (a). Aucune relance.** Qui choisit la rune : A21.

#### A5 — Le boss « XP » quand aucune rune n'est sous son plafond *(posée par la fiche)*

- **(a) rien ne monte, et le joueur le lit** ;
- (b) une carte à la place, comme aujourd'hui ;
- (c) de l'or ou de l'XP en plus ;
- (d) le boss « XP » n'est pas proposé tant que le deck n'a pas de rune affûtable.

**1** écarte (b) : D42(a), « ne donne plus de carte ». **2** : (a) est ce que joue le script (`sharpenRandom`,
`:2450-2463`, qui ne fait rien quand la liste est vide) ; (c) remplace la valeur jouée — le triple d'XP et d'or ;
(d) change la génération de la carte, que le script joue telle qu'elle est (trois boss par acte, `:956`).
**6** : le joueur lit le fait — la notification `restCampSharpenNone`, « Aucune rune de votre deck ne peut gagner de
niveau. », déjà écrite pour le feu. **Choix : (a).** C'est fréquent en début de run : le deck porte 2 runes (0–3) à
l'acte 1 (rapport §2.1).

#### A6 — D25 et la « pioche infinie » *(posée par la fiche)*

**Ce qui a été recensé**, par le code : tous les chemins qui ajoutent une carte à la main (§4.3). Un seul endroit
ajoute une carte à `DeckState.hand` : `_drawInto` (`deck_controller.dart:209`), qui s'arrête à `maxHandSize` avant de
consommer quoi que ce soit (`:200`). Ses deux appelants, `startCombat` (`:158-175`) et `drawCards` (`:218-242`), sont
appelés par cinq sites, qui portent six chemins — la carte `draw` et la rune `quick` partagent `DrawEffectStrategy` —,
tous avec `GameConstants.maxHandSize` ; les autres écritures de la main la vident ou la
réduisent (`discardHand`, `:253` ; `playCard`, `:275`) ; `hydrate` (`:146-148`) recharge une sauvegarde, jamais prise en
combat, et `startCombat` refait la main de zéro au combat suivant. Côté Flame, `StateSyncSystem._applyDeckState`
(`state_sync_system.dart:62-90`) ajoute exactement les identifiants absents et retire les autres : il ne peut afficher
plus de cartes que la main n'en a.

**Ce qui a été essayé** : un test exploratoire, `test/unit/zz_tmp_hand_bound_exploration_test.dart`, écrit, lancé
(`flutter test`, vert) puis **supprimé** — `git status` propre. Sur le registre réel : un Berserker *Frénésie*, trois
*Besaces de l'Érudit* et quatre cartes par tour de plus (12 cartes par tour, au-delà de la main), un deck de
9 *Concentration*, 9 *Éveil* et 6 *Attaque Rapide* rares portant `quick:1`, plus 4 *Frappe* ; cinq ennemis à 9999 PV
et vingt en file à 1 PV, abattus au hasard pour déclencher la pioche de *Frénésie* ; mana remis à 99 avant chaque carte ;
40 graines × 12 tours × jusqu'à 30 cartes jouées, chaque tour fini par `discardHand` puis `startPlayerTurn`. **15 920
contrôles** après la main d'ouverture, chaque carte jouée, chaque mort et chaque début de tour : **main maximale
observée 10**, aucune carte en double dans la main, et la conservation `pioche + main + défausse + épuisement = deck`
toujours vraie. Une carte qui pioche se résout **avant** de quitter la main (`combat_controller.dart:214-225`) : jouée
sur une main pleine, elle ne pioche rien, puis la main retombe à 9 — jamais 11.

**Non reproduit.** Deux lectures restent : le testeur a vu le **cyclage** — la pioche qui tourne le deck entier
plusieurs fois par tour, sans limite, ce que D3, D27 et D48 ont fermé — comme le pense l'encadré de §2 du
brainstorm ; ou il jouait une version antérieure à ADR-078 (06/08), où rien ne bornait la main (ADR-078, Contexte).

- **(a) `maxHandSize` migre quand même** (D2, D25) ; l'ADR de la vague amende ADR-078 D3 en disant que le bug n'est pas
  reproduit, que le testeur a vu le cyclage — ou une version antérieure à la borne —, et que la borne tient sur chaque
  chemin ; un test garde la borne sur chacun (§8) ;
- (b) ne rien migrer tant que le bug n'est pas reproduit.

**1** écarte (b) : D2 fait de la main une limite « augmentable par relique ou récompense », D25 une stat de run.
**Choix : (a).** Ce n'est pas un correctif : rien ne change à la pioche, seule la valeur lue change de place (§4.3).

#### A7 — Le découpage en parties *(posé par la fiche)*

- (a) une seule partie, un seul plan ;
- (b) les deux parties de la fiche, telles qu'elle les nomme — (1) `cardDrops`, reliques, main, XP, DDA ; (2) boss
  « XP », relique légendaire, événements, mythique `maxLevel`, *Sagesse*, seuils —, sans placer ce qu'elle ne nomme
  pas ;
- **(c) le partage de (b), complété** : `raiseRuneLevel` et le bonus de plafond en tête de la partie 2, avant les
  sources qui les lisent ; `GameConstants.bossXpRuneSharpens` avec le boss « XP », son seul lecteur ; la clause du boss
  « XP » du test de transition en partie 2 ; le réalignement du script, puis ses trois changements voulus, en dernier.

(a) est écartée avant les filtres, par le fichier d'orchestration, qui fait foi pour le déroulé : la vague 3 est un lot
lourd, « une spec, deux parties » (§1), et le plan de la partie 2 s'écrit sur le code de la partie 1 (§3.4). 1. à 4. ne
départagent pas (b) et (c), qui partagent le lot de la même façon. **5** retient (c) : sous (b), rien n'empêche un plan
de poser en partie 1 l'affûtage sans or, le bonus de plafond ou la constante du boss, que seule la partie 2 lit — du code
sans lecteur entre les deux parties (`CLAUDE.md`, « No dead code » ; l'invariant de §10). **Choix : (c)** ; le détail et
le motif de l'ordre sont en §10.

#### A8 — Le palier d'XP : stocké, ou dérivé de l'acte *(apparue à la rédaction)*

Aujourd'hui le palier est stocké sur le héros (`EntityStats.xpToNextLevel`, `entity_stats.dart:18`) et recalculé au
passage de niveau (`player_stats_manager.dart:126-127`). Le script, lui, relit la table de l'acte courant à chaque
comparaison (`xpNeed`, `d26_economy_sim.dart:2590-2605`).

- (a) stocké, recalculé au passage de niveau seulement ;
- (b) stocké, recalculé aussi au changement d'acte ;
- **(c) dérivé** : le palier est `courbe.thresholdFor(acte)`, calculé là où on le lit ; `EntityStats.xpToNextLevel`
  disparaît.

1. ne départage pas : D58 dit « une table par acte », pas quel acte compte pour un niveau commencé dans l'acte
précédent. **2** écarte (a) : un niveau commencé à l'acte 8 coûterait 1100 XP même fini à l'acte 9 (1040), quand la
mesure de D67 relit l'acte courant — une valeur mesurée changée sans relance. **5** retient (c) contre (b) : le palier
est une fonction de l'acte et de la courbe ; le stocker en ferait un cache à quatre écrivains — le départ de run, le
passage de niveau, le changement d'acte, et le champ « Acte » du menu de debug —, un fait à quatre endroits.
**Choix : (c).** Quand l'acte change et que le palier baisse sous l'XP accumulée (acte 8 → 9, acte 14 → 15), le niveau
se gagne au prochain gain d'XP, comme dans le script (`while`, `:2599`).

#### A9 — Comment la courbe arrive au contrôleur *(apparue à la rédaction)*

- (a) `GameDataRegistry.instance`, comme `GoldManager` et `ShopController` lisent le catalogue des runes
  (`gold_manager.dart:73`, `shop_controller.dart:66`) ;
- **(b) un `Provider<XpCurveData>`**, `xpCurveProvider`, lu sur `gameDataLoaderProvider`, surchargeable en test comme
  `deckRandomProvider` (`deck_controller.dart:374`) ;
- (c) la courbe en paramètre de `gainXp`.

**5** retient (b) : `CLAUDE.md` veut l'état partagé et les ressources dans des providers, jamais dans un singleton ; un
test surcharge la courbe sans dépendre d'un registre statique resté d'un autre test ; (c) ferait lire la courbe à
chaque appelant de `gainXp` (récompense, debug). Le tutoriel, qui n'a aucun provider (ADR-081), lit la courbe sur son
registre (§4.4). **Choix : (b).**

#### A10 — Ce que le joueur voit de la carte trouvée *(apparue à la rédaction)*

- **(a) une notification par carte**, qui la nomme — la place exacte de la notification de la carte bonus
  d'aujourd'hui (`game_screen.dart:129-135`), par une clé ARB ;
- (b) un écran de révélation, la carte montrée, un bouton « Ajouter au deck » ;
- (c) rien : la carte apparaît dans le deck.

**6** écarte (c) : une carte entrée sans que rien ne le dise est une règle cachée ; (a) et (b) se lisent tous deux, la
carte restant consultable dans l'écran de deck. **7** retient (a) : (b) est un écran neuf pour un geste sans choix
(D1 : la carte ne se refuse pas). **Choix : (a).**

#### A11 — `maxHandSize` : la stat, et rien d'autre *(apparue à la rédaction)*

- **(a) la stat seule** : `RunState.maxHandSize`, sérialisée, lue par les six chemins (§4.3), écrite par le départ de
  run et par le menu de debug ; sa valeur de départ, `GameConstants.startingMaxHandSize = 10` ;
- (b) la stat et un accumulateur `maxHandSizeAcc` dans `applyRunRuleModifier` ;
- (c) la stat, l'accumulateur et une relique « +2 en main ».

**3** écarte (c) : P1 — aucune décision ne fixe cette relique (le brainstorm §4.1 n'en fait qu'un exemple), et un
fichier de relique neuf changerait les tirages de reliques du script (§9) ; elle relève de P-16. **5** écarte (b) : un
accumulateur sans appelant est du code sans lecteur. **Choix : (a)** : « augmentable par relique ou récompense » (D2)
tient par construction — la relique future écrira l'accumulateur avec elle. La constante renommée garde un seul
endroit à la valeur de départ ; plus aucun chemin de pioche ne la lit.

#### A12 — La somme des rangs de fusion *(apparue à la rédaction)*

- **(a) un getter `DeckState.fusionRankSum`**, à côté de `copyableCards` (`deck_controller.dart:49-55`) ; le paramètre
  `playerCardsCount` de `EncounterSystem.calculateBudget` (`encounter_system.dart:93`) devient `deckFusionRanks` ;
- (b) la somme calculée en ligne par l'écran de combat (`game_screen.dart:262`) ;
- (c) `EncounterSystem` reçoit la liste des cartes.

**5** retient (a) : un fait sur le deck vit sur `DeckState`, et `EncounterSystem` reste une fonction pure sur des
entiers. **Choix : (a).**

#### A13 — L'affûtage sans or : une opération partagée *(apparue à la rédaction)*

Trois sources neuves montent une rune sans or — le boss « XP », sa relique, l'événement — à côté du feu, qui paie
(`GoldManager.sharpenRune`, `gold_manager.dart:21-51`).

- **(a) `DeckNotifier.raiseRuneLevel(cardId, runeId, levels, capBonus)`** : vérifie la carte, la rune et le plafond,
  réécrit `id:n` en `id:n+k` à sa place ; `GoldManager.sharpenRune` vérifie, paie, puis l'appelle ;
- (b) `GoldManager.sharpenRune(…, free: true)` ;
- (c) chaque source réécrit elle-même par `setForgeUpgrades` et `replaceRune`.

**5** écarte (b) — `GoldManager` vend des services contre de l'or (spec E2, A16) — et (c) — la troisième copie d'une
même écriture, que le compte rendu de la vague 2 demandait de factoriser à la troisième (§5, « Pour la file »).
`DeckNotifier` écrit déjà les runes d'une carte (`addForgeUpgrade`, `setForgeUpgrades`, `:334-356`). **Choix : (a).**
« Payer et écrire, ou rien » reste vrai : `GoldManager` refuse avant de dépenser si l'écriture serait refusée.

#### A14 — Le tirage du boss « XP » *(apparue à la rédaction)*

- **(a) uniforme parmi les paires (carte, rune)** du deck dont la rune est sous son plafond effectif, une paire par
  tirage, chaque tirage voyant le précédent ;
- (b) une carte au hasard, puis une rune de cette carte.

1. ne départage pas : D42(a), « une rune tirée dans tout le deck ». **2** : (a) est jouée (`:2451-2462`). **Choix :
(a)**, répété `GameConstants.bossXpRuneSharpens` + `RunState.extraBossRuneSharpens` fois (A3), jusqu'à épuisement des
paires.

#### A15 — La mythique de D42(c) : sa portée, ses candidates, sa condition *(apparue à la rédaction)*

**La portée.** (a) **un type de rune, pour toute la run** : le plafond de `eco` monte sur toutes les cartes ; (b) une
rune d'une carte. 1. ne départage pas : « monte de 1 le `maxLevel` d'une rune ». **2** : le script joue (a)
(`maxLevelBonus[id]`, `:2115`, lu par `maxLevel`, `:2163-2166`). **(a).**

**Les candidates.** (i) **les runes que le deck porte à leur plafond effectif, sauf les binaires** ; (ii) toute rune
plafonnée du catalogue. **2** : (i) est l'ensemble joué (`_chooseReward`, `:2675-2693`) ; le script y prend la plus
fréquente — une politique : **le joueur choisit**. **(i).** Ce qu'est une rune binaire : A16.

**La condition d'offre.** (x) **`"requires": "raisableRune"`** : la mythique n'est tirée que si une candidate existe ;
(y) tirée toujours, inactive sans candidate. **5** retient (x) : le mécanisme existe (ADR-099 D1, « le
conditionnement est un mécanisme, pas une propriété d'*Affinité* »). Le taux mesuré par D62 — 11 à 12 % des runs la
**prennent** — tient : le script ne la prend que quand une candidate existe, ce que (x) fait d'office.

**Choix : (a), (i), (x).**

#### A16 — Les runes dont le plafond ne monte jamais *(apparue à la rédaction)*

Le script exclut de D42(c) les runes « binaires », `enduring`, `retain`, `cheap`, `transfusion` (`:2677`). Le jeu n'a
pas cette notion : `cheap` porte `reduceCost` à `valuePerLevel: 1` (`assets/data/forge_upgrades/cheap.json`), et un
niveau 2 coûterait 2 de moins.

- **(a) un champ de rune, `binary`** (booléen, absent = faux), vrai sur `enduring` et `cheap` ; une rune binaire a
  `maxLevel: 1`, refusée au chargement sinon ;
- (b) la liste des ids exclus, dans le fichier de la mythique ;
- (c) binaire déduit des deltas — une rune sans `valuePerLevel`.

**1** écarte (c) : le brainstorm §8 tient `cheap` pour binaire (« un −2 serait une carte à 0 de plus », D11), ce que
ses deltas ne disent pas. **4** retient (a) contre (b) : la propriété appartient à la rune — une rune neuve la déclare
dans son fichier, la mythique n'a pas à en tenir la liste. **Choix : (a).** `retain` et `transfusion` le déclareront à
leur vague (§4.13).

#### A17 — Le bonus de plafond, partout où un niveau s'écrit *(apparue à la rédaction)*

D72 : `maxLevel` borne chaque endroit qui écrit un niveau de rune. Le plafond effectif est `maxLevel` + le bonus de la
run pour cet id ; il borne donc les mêmes endroits — le script le lit dans ses six (`:2351`, `:2419`, `:2455`, `:2681`,
`:2895`, `:3122`).

- **(a) un paramètre `capBonus`** sur `ForgeUpgradeData.boundLevel` et sur les fonctions de `ForgeRuneRules` qui le
  lisent — nommé, **optionnel, à défaut neutre** : `{int capBonus = 0}` sur `boundLevel`,
  `{Map<String, int> capBonus = const {}}` ailleurs (§3.8) ; chaque appelant de production passe
  `RunState.runeCapBonus` ;
- (b) `DeckNotifier`, `ShopController` et les autres lisent `runProvider` eux-mêmes, au fond des fonctions ;
- (c) un catalogue de runes « de la run », aux `maxLevel` relevés.

**1** écarte toute option qui oublierait un écrivain (D72). **5** retient (a) : les fonctions de `ForgeRuneRules`
restent pures par leurs entrées (spec E1, A3 ; spec E2, A15) — le tutoriel, qui n'a pas de run, n'appelle d'ailleurs
aucune de celles qui lisent le plafond, seulement `isEligible` et `drawRunes` (`tutorial_engine.dart:442`, `:470`) ;
(c) recopierait les runes par run. **Choix : (a)** ; la liste des lecteurs est en §4.8. Le paramètre est optionnel pour que les appels
d'aujourd'hui, tous sans bonus, compilent tels quels : `dart analyze` ne désigne donc pas un appelant de production
qui l'oublierait — ce sont les tests de §8 (« Le bonus de plafond, lu par ses lecteurs ») qui le gardent.

#### A18 — Le nom d'une rune montée au-delà de son plafond de base *(apparue à la rédaction)*

`ForgeUpgradeData.nameAt` (`forge_upgrade_data.dart:299-300`) n'écrit pas le niveau d'une rune de `maxLevel: 1` : un
`eco:2`, permis par D42(c), s'afficherait « Économe ». (a) **le niveau s'écrit dès qu'il dépasse 1**, ou que le
plafond n'est pas 1 ; (b) inchangé. **6** retient (a). **Choix : (a).**

#### A19 — La mécanique des deux événements *(apparue à la rédaction)*

Les actions d'événement sont une table de types (`event_controller.dart:59-129`), à valeur fixe : aucune ne cède une
relique, ne soigne en pourcentage, ni n'affûte.

- **(a) quatre actions composables et une condition de choix** : `trade_relic` (cède la relique visée — A20 — et
  rapporte `value` × (rang + 1) or, 0 = rien), `heal_percent` et `lose_hp_percent` (en pourcentage des PV max),
  `sharpen_rune` (monte de `value` niveaux une rune choisie, sans or) ; `requiresHpBelowPercent` sur un choix ;
- (b) une action dédiée par issue (`relic_trade_gold`, `relic_trade_heal`, `rune_event_sharpen`) ;
- (c) des écrans d'événement écrits en Dart.

**5** écarte (c) (`CLAUDE.md` : 100 % data-driven). **4** retient (a) : « les deux » de D23 s'écrit
`trade_relic` 40 suivi de `heal_percent` 20, sans code ; `heal_percent` et `lose_hp_percent` servent tout événement
futur. **Choix : (a)** ; les règles sont en §4.9.

#### A20 — La relique que vise l'échange *(apparue à la rédaction)*

(a) **tirée une fois, à l'ouverture de l'événement** — la rareté la plus basse, au hasard parmi les ex æquo —, gardée
dans `EventState`, nommée sur les badges ; (b) déterminée au moment du choix. **6** retient (a) : le joueur lit ce
qu'il cède avant de choisir. **Choix : (a).** Sans relique visée — un inventaire vide, le cas courant à l'acte 1 —,
les badges `trade_relic` disent « Aucune relique à céder » et les choix d'échange restent inactifs (arbitrage du
propriétaire, n° 5, ci-dessous ; §4.9).

#### A21 — Qui choisit la rune à l'événement d'affûtage *(apparue à la rédaction)*

(a) **le joueur choisit la carte, puis la rune** — la sélection et le dialogue du feu (spec E2, §4.7), sans or ;
(b) tirée au hasard, comme au boss. **2** : le script monte la rune qui rapporte le plus (`sharpenTarget`, `:2405-2434`)
— un choix, que le jeu laisse au joueur ; (b) remplacerait le choix joué par un tirage. **6** ensuite. **Choix : (a).**
Annuler la sélection n'engage rien : le choix d'événement n'est pas pris, les PV ne sont pas payés.

#### A22 — Le retour système après un choix d'événement *(apparue à la rédaction)*

**Le constat.** `EventScreen` autorise le retour dès qu'un choix est fait (`canPop: eventState.isResolved`,
`event_screen.dart:323`), sans passer par `_leave` (`:70-73`), qui seul résout le nœud ; la carte laisse rentrer dans
le nœud courant tant qu'il n'est pas résolu (`map_screen.dart:391-392`) ; et l'écran tire un **nouvel** événement à
chaque entrée (`:24-29`). Un second événement, donc un second choix, s'obtient ainsi dans un même nœud — un défaut
antérieur, qu'E3 rend exploitable : l'événement d'affûtage et l'échange se répéteraient.

- **(a) après un choix, le retour système résout le nœud**, par le mécanisme du feu et du Puits (spec E2, A4, A5) :
  `canPop: false` et un `onPopInvokedWithResult` qui, le choix fait, appelle `_leave` ; avant tout choix, le retour
  reste bloqué, comme aujourd'hui ;
- (b) un drapeau de visite dans `RunState` ;
- (c) laisser tel quel.

**3** écarte (c) : P3 — un affûtage gratuit répétable court-circuite la chaîne trouvaille → fusion → rune → affûtage,
dont le feu, une fois par visite (D14), est le rythme. **5** retient (a) contre (b) : un mécanisme déjà dans le dépôt, sur
un état métier qui existe (la résolution du nœud). **Choix : (a)** ; la note de version le dit comme une correction.

#### A23 — Le plancher de *Flux de Mana* *(apparue à la rédaction)*

**Où il s'applique.** (a) **dans `PassiveData.withMastery`**, depuis `mastery.floor` ; (b) dans la stratégie.
**1** retient (a) : D43 met le plancher dans le bloc `mastery`, « que la Maîtrise ne franchit pas ». Le plancher codé de
`ManaFluxPassive` (`passive_strategies.dart:110`) est **inerte** : le compteur vaut au moins 1 quand il est comparé
(`:111-113`), si bien qu'un seuil de 1, de 0 ou négatif déclenche à chaque Compétence — le test
`passives_mage_test.dart:336-342` le dit déjà en commentaire. Il disparaît (pas de code mort).

**Ce que lisent les textes.** Aujourd'hui `{amount}` vaut `|perPoint × points|` (`passive_data.dart:39-41`) : avec le
plancher, la fiche des stats dirait « −3 Compétences à réunir » pour un seuil passé de 3 à 2. (x) **`{amount}` dit le
changement effectif** — l'écart du paramètre entre deux nombres de points, plancher compris ; (y) inchangé. **6**
retient (x). Ses trois lecteurs (§4.11) : la fiche des stats (de 0 à la Maîtrise effective), l'écran de sélection (de 0 à
1 point), et la carte d'*Affinité* (de la Maîtrise effective à la même plus le gain tiré — un gain qui ne change plus
rien affiche le repli « sans effet sur votre passif » d'`affinity.json`).

**Choix : (a), (x).** `floor` est refusé au chargement si `perPoint` n'est pas négatif — un plancher ne mord que sur un
paramètre qui baisse — ou s'il dépasse la valeur de base du paramètre.

#### A24 — Le seuil de *Bénédiction* en donnée *(apparue à la rédaction)*

`BlessingPassive` divise l'armure survivante par une constante (`_armorPerTranche = 5`, `passive_strategies.dart:148`,
lue en `:152`). (a) **la stratégie lit `passive.threshold`** ; un seuil inférieur à 1 ne fait rien — pas d'exception en
combat, le précédent de P-49 §5.2 ; (b) refusé au chargement pour ce seul passif. **5** écarte (b) : `PassiveData` ne
connaît pas la stratégie d'un passif. **Choix : (a)** ; un test de catalogue garde `threshold: 5` (§8).

#### A25 — L'infobulle du boss « XP » *(apparue à la rédaction)*

Son titre, écrit en ligne, dit « Boss (XP & Or x2) » (`map_node_widget.dart:59-61`) quand la récompense triple
(`reward_controller.dart:89-91`, `:99-101`), et sa description est celle des trois boss. (a) **titre `legendBossXp`,
description neuve qui dit la rune**, sur le modèle des deux autres boss (`:57-58`, `:62-63`) ; (b) inchangé. **6**
retient (a). **Choix : (a)** ; la note le dit comme une correction.

#### A26 — La prose XP du tutoriel *(apparue à la rédaction)*

L'étape « L'Expérience » écrit « 100, puis 150, puis 225 » (`tutorial_data.dart:305-306`, `:316-317`). (a) **deux
placeholders, `{xpAct1}` et `{xpAct2}`, remplis depuis la courbe** par une fonction pure, sur le précédent de
`fillRewardPlaceholders` (`tutorial_prose.dart:54-70`, ADR-098 D7) ; (b) les chiffres en toutes lettres. **5** retient
(a) : un fait, à un seul endroit. **Choix : (a).**

#### A27 — La courbe dans le registre *(apparue à la rédaction)*

`GameDataRegistry(` apparaît 78 fois dans `lib/` et `test/` (somme de `git grep -c "GameDataRegistry(" -- lib test`),
pour l'essentiel dans des registres de test. (a) paramètre
requis ; (b) **paramètre optionnel, nullable** — le précédent de `levelUpRewards`, optionnel « pour ne pas casser les
dizaines de registres de test » (`game_data_registry.dart:20-24`). **5** retient (b) : la façon dont le registre grandit
est déjà fixée. **Choix : (b)**, avec **une seule sémantique** : `loadGameDataRegistry` renseigne toujours la courbe ;
un registre construit à la main peut ne pas la porter, et **tout lecteur du palier lève alors** —
`xpCurveProvider` une `StateError` explicite. Un registre de test sans courbe sert donc tant que rien n'y lit le palier ;
les tests qui en lisent un reçoivent une courbe (§8). Le tutoriel lit `data.xpCurve!` : son registre passe toujours
par `loadGameDataRegistry`, en jeu (`tutorial_loader.dart:23`) comme en test (`buildTutorialTestRegistry`,
`test/tutorial/tutorial_test_registry.dart:22-23`).

#### A28 — Le second temps de la simulation : combien de relances *(apparue à la rédaction)*

La fiche liste trois changements voulus : la relique B retirée, l'événement de D29 retiré, la table d'XP lue dans la
donnée. (a) **trois commits, trois relances**, dans cet ordre ; (b) B et D29 ensemble, puis la table. **1** retient (a) :
D73 — « chaque changement voulu [...] relancé à part, l'écart attribué ». **Choix : (a)** (§9).

#### Récapitulatif

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Où vivent les tables (Q5) | `cardDrops` : `GameConstants` · document plat · nœud ; XP : constante · document plat | `cardDrops` : 7 écarte le nœud, la proposition de Q5, 5 neutre, 8 tranche ; XP : 1 | `GameConstants.cardDrops` ; `assets/data/xp_curve.json` |
| A2 | Échange de relique (D63, Q15) | D63 · relique choisie · or et PV · PV à toute santé | 2 puis 7 | D63 tel qu'écrit — pas de second temps |
| A3 | Relique de D42(a) | +1 par exemplaire · +2 · non cumulable | 2 puis 7 | +1 par exemplaire — pas de second temps |
| A4 | Événement de D42(b) | +1 contre 10 % PV max · contre or · gratuit | 2 puis 7 | +1 niveau contre 10 % des PV max — pas de second temps |
| A5 | Boss « XP » sans rune affûtable | rien et un message · une carte · or ou XP · boss non proposé | 1 ; 2 ; 6 | Rien ne monte ; `restCampSharpenNone` |
| A6 | D25, la « pioche infinie » | migrer · attendre la reproduction | 1 | Non reproduit (15 920 contrôles) ; `maxHandSize` migre ; ADR-078 D3 amendé ; un test par chemin |
| A7 | Découpage | une partie · les deux parties de la fiche · les deux parties complétées | l'orchestration (§1, §3.4) écarte une partie ; 5 | Deux parties : la boucle, puis les sources ; ce que lit la seule partie 2 y vient (§10) |
| A8 | Palier d'XP | stocké au niveau · stocké et recalculé à l'acte · dérivé | 2 puis 5 | Dérivé de l'acte ; `EntityStats.xpToNextLevel` supprimé |
| A9 | Couture de la courbe | registre global · `Provider` · paramètre | 5 | `xpCurveProvider` |
| A10 | Carte trouvée, à l'écran | notification · écran de révélation · rien | 6 puis 7 | Une notification par carte, `rewardCardFound` |
| A11 | `maxHandSize` | la stat · + accumulateur · + relique | 3 ; 5 | La stat seule ; `GameConstants.startingMaxHandSize` ; un champ de debug |
| A12 | Σ `fusionRank` | `DeckState` · en ligne · liste passée | 5 | `DeckState.fusionRankSum` ; `deckFusionRanks` |
| A13 | Affûtage sans or | `DeckNotifier` · `GoldManager(free)` · trois copies | 5 | `DeckNotifier.raiseRuneLevel`, que `GoldManager` appelle |
| A14 | Tirage du boss « XP » | paires (carte, rune) · carte puis rune | 2 | Paires sous le plafond effectif, séquentiel |
| A15 | Mythique D42(c) | type · instance ; à leur plafond · toute plafonnée ; condition · inactive | 2 ; 2 ; 5 | Un type pour la run ; candidates à leur plafond, sauf binaires, le joueur choisit ; `requires: raisableRune` |
| A16 | Runes binaires | champ `binary` · liste dans la mythique · déduit des deltas | 1 puis 4 | `binary: true` sur `enduring` et `cheap` |
| A17 | Bonus de plafond | paramètre `capBonus` · lecture au fond · catalogue de run | 1 puis 5 | `capBonus` optionnel, à défaut neutre, sur `boundLevel`, `ForgeRuneRules` et `mergeCards` |
| A18 | `nameAt` | niveau écrit au-delà de 1 · inchangé | 6 | Le niveau s'écrit dès qu'il dépasse 1 |
| A19 | Mécanique des événements | actions composables · actions dédiées · écrans | 5 puis 4 | `trade_relic`, `heal_percent`, `lose_hp_percent`, `sharpen_rune`, `requiresHpBelowPercent` |
| A20 | Relique visée | tirée à l'ouverture · au choix | 6 | Tirée à l'ouverture, nommée sur les badges ; sans elle, « Aucune relique à céder », choix inactifs |
| A21 | Rune de l'événement d'affûtage | choisie · tirée | 2 puis 6 | Le joueur choisit, sans or ; annuler n'engage rien |
| A22 | Retour après un choix d'événement | résout le nœud · drapeau · tel quel | 3 puis 5 | Le retour résout le nœud, comme au feu et au Puits |
| A23 | Plancher de *Flux* | `withMastery` · stratégie ; textes effectifs · inchangés | 1 ; 6 | `withMastery` ; `{amount}` effectif ; plancher codé supprimé |
| A24 | Seuil de *Bénédiction* | lu en donnée, sans effet sous 1 · refusé au chargement | 5 | Lu en donnée ; test de catalogue |
| A25 | Infobulle du boss « XP » | titre et description justes · inchangée | 6 | `legendBossXp` et `tooltipBossXpDesc` |
| A26 | Prose XP du tutoriel | placeholders · chiffres | 5 | `{xpAct1}`, `{xpAct2}` |
| A27 | Courbe dans le registre | requise · optionnelle | 5 | Optionnelle, comme `levelUpRewards` ; sans elle, tout lecteur du palier lève ; le tutoriel lit `data.xpCurve!` |
| A28 | Relances du second temps | trois · deux | 1 (D73) | Trois : B, puis D29, puis la table d'XP |

#### Tranchés par l'orchestrateur — questions apparues à la correction du premier tour

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C1.1 | Le discriminant de `RewardState.sharpenedRunes` | liste nullable · booléen `isXpBossReward` à côté | 5 — un seul champ porte les deux faits | Nullable : `null` hors d'un boss « XP », vide pour un boss « XP » sans rune affûtable | §3.8, §4.6 |
| C1.2 | La Maîtrise effective dans les textes | requise dans `getChoiceDescription` seul · dans `getChoiceDescription` et `LevelUpRewardData.describe` | 5 — l'analyseur garde toute la chaîne | `currentMastery` requis dans les deux | §3.8, §4.11, §8 |
| C1.3 | `binary` dans `toJson` | toujours écrit · écrit seulement à vrai | 5 — le précédent de `requiresExhaust` | Toujours écrit | §3.8, §8 |
| C1.4 | Le filtre qui tranche A7 | 8 · 5 | — | 5 : sous l'autre découpage, un plan pourrait poser en partie 1 du code que seule la partie 2 lit | A7 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du deuxième tour

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C2.1 | La commande de contrôle du renommage | `playerCardsCount` seul · élargie | 5 — elle garde le renommage sans test | Élargie *(sa forme est le constat 4 du tour 3, §13)* | §8 |
| C2.2 | Le recalage des commentaires du script | tous les renvois · les six renvois mesurés | 7 | Les six renvois mesurés | §9 |
| C2.3 | La clause de transition E3 → E4 | par `handleVictory` · par une fonction extraite | 8 | Par `handleVictory`, sur le registre réel | §4.13, §8 |
| C2.4 | Le défaut de `hasRaisableRune` dans `isAvailableWith` | faux · requis | 8, et l'accord avec `generateChoices` | Faux par défaut ; les appels à un argument compilent | §3.8 |
| C2.5 | Les deux lecteurs de `GameScreen`, qu'aucun test ne monte | commandes de contrôle · fonction pure extraite · test de widget de `GameScreen` | 7 — le lot ne prend pas en charge les tests de `GameScreen` —, puis 8 | Des commandes de contrôle | §8 |
| C2.6 | `StatsDialog`, sans aucun test | un test de widget neuf · le seul cas unitaire de `describeMastery` | 6 — le joueur pourrait lire « -9 » au lieu de « -1 » | Un test de widget neuf | §8 |

#### Tranchés par le propriétaire — la levée de l'arrêt (03/10)

Ce sont les recommandations que l'orchestrateur avait consignées à l'arrêt du troisième tour, acceptées par le
propriétaire quand il a levé l'arrêt (§13).

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| n° 1 | La forme du test qui garde l'absence de signature dans la trouvaille | la rareté de l'instance trouvée · la donnée de la carte trouvée · la donnée de la carte, et en plus, pour la transition E3 → E4, aucun id de signature | — : l'instance est construite `common` (§4.1), une assertion sur `card.rarity` ne garderait rien | Les deux formes ensemble : `card.data.rarity` jamais `unique` et `card.data.heroClass` jamais une autre classe, dans les deux tests ; en plus, dans la transition, aucun `card.data.id` parmi les six signatures du registre (C3.1) ; « toutes communes », sur `card.rarity`, reste | §4.1, §8 |
| n° 5 | Le badge `trade_relic` sans relique visée | pas de badge · un badge qui dit qu'il n'y a rien à céder | 6 — le joueur lit pourquoi le choix est inactif | `eventNoRelicToGive`, « Aucune relique à céder » · "No relic to give up" ; les choix d'échange restent inactifs | A20, §4.9, §5.1, §8, §10 |
| n° 7 | La parenthèse « (Trèfle / Miroir) » de la fiche des probabilités | remplie depuis les mythiques en donnée · retirée · consignée hors d'E3 | 5 ne départage pas (la retirer supprime aussi le doublon) ; 6 retient la forme qui dit au joueur quelles options sont mythiques | Remplie depuis `LevelUpRewardData.inPool(rewards, RewardPool.mythic)`, par une clé ARB neuve à placeholder, `luckLevelRewardSubtitle` (`{mythicNames}`), en partie 2 (C3.2) | §3.8, §5.1, §8, §10 |
| n° 8 | L'infobulle d'élite, `tooltipEliteDesc`, qui ne dit que la relique | réécrite en partie 1 · laissée telle quelle, consignée en §5.4 | 6 — la carte du monde dit de l'élite ce qu'en dit le tutoriel | Réécrite en partie 1 : « Un combat bien plus rude : une relique garantie, et une carte — parfois deux. » · "A much tougher fight: a guaranteed relic, and a card — sometimes two." | §5.1, §10 |

#### Tranchés par l'orchestrateur — questions apparues à la correction du troisième tour

Tranchées par l'arbre de décision (orchestration §5) à la correction ; l'orchestrateur les relit et peut les renverser.

| # | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| C3.1 | D'où le test de la transition E3 → E4 lit les six signatures | les `skills` des classes du registre · les cartes `unique` du registre · une liste écrite dans le test | 4 écarte la liste écrite, un cas qui ne suit pas le registre ; 5 retient les `skills` : une signature est ce que la classe déclare et ce que son dossier porte (`referential_integrity_test.dart:211-229`) — les cartes `unique` relisent la rareté, l'entrée même du prédicat que la clause garde, et répéteraient sa première forme | `registry.heroes.expand((h) => h.skills)` (`HeroData.skills`, `hero_data.dart:44`), dont le test vérifie d'abord qu'il compte six ids | §8 |
| C3.2 | Qui compose les noms des mythiques de la fiche des probabilités | `build` lui-même : la lecture de `inPool`, les noms dans la locale, joints par « / » · une fonction pure de la couche UI, testée seule, que `build` appelle | 1 à 7 ne départagent pas — la lecture reste dans la couche UI pour les deux, et le joueur lit la même parenthèse ; 8 retient la première : aucune fonction neuve, et le test de widget, qu'exige de toute façon un lecteur qu'aucun test n'ouvre (le précédent de C2.6), garde la lecture et l'affichage ensemble | Dans `build` ; un test de widget neuf, `probabilities_dialog_test.dart` | §5.1, §8 |

### 1.3. Prémisses re-mesurées

| Prémisse | Où | Mesure |
|:---|:---|:---|
| « La cinquième ligne de la sortie, “Données lues”, **compte les fichiers** » ; au premier temps, « un écart admis » sur elle | Orchestration §3.6, §7.3 ; D73 | **Fausse**, déjà trouvée par la vague 2 (compte rendu §5) : elle écrit la longueur des listes que le script a chargées (`d26_economy_sim.dart:3873-3877`) — les runes jouées (`data.runes`), et pour les reliques, les récompenses et les événements les fichiers retenus, plus des littéraux « (+ 4 du brainstorm) », « (+ 3 du brainstorm) ». Un réalignement qui retire de ces listes les fichiers neufs pour les mettre à la place de leur entrée en dur **les laisse inchangées** : l'écart attendu est **nul**, le diff entièrement vide (§9) |
| « La table d'XP n'est pas lue : elle est recalée à chaque lancement — **elle égale celle de D67** aujourd'hui (référence, ligne 11) » | Orchestration §7.3 | **Fausse depuis `cba147c`** (vague 2, `spectral` aligné sur D33) : la référence cale 115 · 200 · 310 · **475** · 590 · **770** · 955 · **1080** · **1050** · **1190** · **1410** · **1345** · **1275** · **1380** · **1040** ; seule la version `37aa9d5` égalait D67. Le compte rendu de la vague 2 l'a noté (§4). Conséquence : la relance qui fait lire au script la table du jeu (§9, troisième relance) rend un écart non nul, attendu |
| « Les trois chemins de pioche — la carte `draw` (`strategies.dart:147`), la rune `quick` (`effect_resolver.dart:168`) et le tour (`turn_phase_manager.dart:40,56`) » | Brainstorm §2, encadré ; revue, annexe A n° 11 | Incomplète, et déplacée : `quick` est un delta `addEffect draw` depuis E1, résolu par `DrawEffectStrategy` (`strategies.dart:152`, via `effect_resolver.dart:142-152`) ; deux chemins manquent — *Frénésie* (`passive_strategies.dart:217-219`, lot B de P-41) et le menu de debug (`debug_actions.dart:88-93`). Cinq sites, six chemins en tout, tous bornés (§4.3) |
| « Le testeur a observé une main au-delà du maximum, à reproduire » | D2, D25 ; brainstorm §2 | Non reproduit (A6) |
| « Plus de plafond de deck » | D2 | Aucun plafond n'existe dans le code (`git grep -in "maxDeck\|deckLimit\|deckSize" -- lib` vide) : la « limite de 15 cartes » de P-18 n'a jamais été écrite. Rien à retirer |
| `run_controller.dart:41` (`cardsPerTurn`) | Fiche §8.3 | `:36` (doc `:33-35`) |
| `passive_strategies.dart:108,146` | Fiche §8.3 | `:110` (le plancher de *Flux*, inerte — A23) ; `:148` (`_armorPerTranche`), lu en `:152` |
| `reward_controller.dart:83-165` | Fiche §8.3 | L'XP `:83-91`, l'or `:93-101`, la relique `:103-166`. Exactes : `:75-82`, `:86`, `:168-195` (`:168-184` les clones du boss « cartes », `:186-194` la carte bonus) |
| `event_controller.dart:80-100` | Fiche §8.3 | Le tirage de rareté de `gain_relic` : `:79-128` ; la table des actions : `:59-129` |
| `level_up_reward_data.dart:283-285` ; `:7-11` | Fiche §8.3 | `:283-286` ; `:7-13`. Exactes : `:277`, `game_constants.dart:36`, `deck_controller.dart:200`, `player_stats_manager.dart:102-108`, `:127`, `encounter_system.dart:97-101`, `:136-148`, `level_up_reward_service.dart:38-148` |
| Les lignes du script que §7.3 de l'orchestration cite pour la vague 3 | Orchestration §7.3, ligne 3 | Déplacées par la vague 2 : la réserve de reliques `:2517-2522` → `:2506-2510` ; les événements `:2940-2947` → `:2976-2982` ; les mythiques `:2602-2626` → `:2645-2663` ; le pool forcé de *Sagesse* `:2594` → `:2629-2633` ; sa valeur `mythic` `:2619` → `:2655`, `:2660` ; les quatre reliques en dur `:693-696` → `:694-697` ; « Données lues » `:3837-3841` → `:3873-3877` ; la calibration `:3801-3806` → `:3810-3823`, `:3837-3842` |
| « `wisdom.json` : le script force déjà son pool, mais lira sa valeur `mythic` » | Orchestration §7.3 | Exact : `r?.values['mythic'] ?? 1` (`:2655`, `:2660`) ; avec `values.mythic: 1`, la valeur lue est celle d'aujourd'hui — sortie inchangée |
| Le seuil de *Bénédiction* et le plancher de *Flux* passés en donnée | Fiche §8.3 | Sans effet sur le script : il ne lit le `threshold` que pour *Flux* (`fluxThreshold`, `:2153`), joue déjà le plancher 2 (`max(2, …)`) et la tranche de 5 en dur (`blessingThreshold`, `:2157`) ; `PassiveDef` n'a pas de `floor` (`:348-358`) |
| D42(c), « monte de 1 le `maxLevel` d'une rune » | D42 | Le script relève le plafond **d'un type de rune pour la run** (`maxLevelBonus`, `:2115`, `:2163-2166`), lu par six écrivains de niveau (A17) ; il exclut les runes « binaires », dont `cheap` (`:2677`), notion que la donnée du jeu n'a pas (A16) |
| L'infobulle du boss « XP » | — | Dit « x2 » (`map_node_widget.dart:59-61`) ; la récompense triple (A25) |
| Le retour système à l'écran d'événement | — | Rejoue un événement dans le même nœud (A22) |

---

## 2. Périmètre

**Dans E3**

- la trouvaille : `GameConstants.cardDrops`, son tirage, ses cartes communes ajoutées au deck, leur notification ; les
  reliques A et C et leurs règles de run (§3.1, §3.3, §4.1, §4.2) ;
- `maxHandSize` en stat de run, ses six lecteurs, son champ de debug, le test de la borne (§4.3) ;
- la courbe d'XP : `assets/data/xp_curve.json`, son modèle, son chargement, `xpCurveProvider`, le palier dérivé, ses
  lecteurs — dont le tutoriel —, la suppression d'`EntityStats.xpToNextLevel` (§3.2, §4.4) ;
- la DDA sur 2 × Σ `fusionRank` (§4.5) ;
- le boss « XP » sans carte, son affûtage aléatoire, la relique légendaire, l'infobulle (§4.6) ; l'affûtage sans or
  partagé (§4.7) ;
- la mythique de D42(c) : `binary`, `RunState.runeCapBonus` et ses lecteurs, la condition `raisableRune`, la modale,
  `nameAt` (§4.8) ;
- les deux événements, leurs actions, la relique visée, la sélection d'affûtage sans or, le retour système (§4.9) ;
- *Sagesse* en mythique (§4.10) ; les seuils de *Bénédiction* et de *Flux* et leurs textes (§4.11) ;
- les textes joueur (§5), l'éditeur (§6), les tests (§8) ;
- le réalignement du script de simulation, premier temps, puis trois changements voulus, second temps (§9).

**Hors d'E3**

| Sujet | Où |
|:---|:---|
| Les reliques de mana, un puits d'or, la survie après l'acte 5, la boucle XP / niveau ennemi — le +10 % d'XP par niveau ennemi (`reward_controller.dart:86`) et le niveau ennemi égal à celui du héros (`encounter_system.dart:136-148`) restent tels quels | P-16 |
| L'échange 3 → 1 ; l'événement de fusion de D29 (D56) | P-16 |
| Une relique ou une récompense « +N en main » | P-16 (A11) |
| Les signatures en compétences de classe ; `unique`, `characterSpecific` | E4 (vague 4) |
| Le lien carte ↔ passif dans `isOfferableTo` (§6 du brainstorm) : le pool de la trouvaille grandit avec les lots | Vague 5 |
| `binary` sur `retain` et `transfusion` ; le bonus de plafond lu par toute rune ou tout écrivain de niveau neuf | Vagues 5 et suivantes (§4.13) |
| La variante « armure conservée » de *Bénédiction* (D43) | Vague 7 |
| Tout rééquilibrage de carte, de relique ou d'ennemi ; toute valeur de D56 à D62 ou de D67 | Aucun |
| Le tirage de l'événement à l'entrée de l'écran, que rien ne retient d'une entrée à l'autre (avant tout choix, le retour est bloqué, §4.9) | Inchangé |

---

## 3. Données

### 3.1. La table de la trouvaille

`lib/game/game_constants.dart`, à côté de `nodeQuotas` (`:24-31`) :

```dart
// Au niveau du fichier :
/// Une règle de trouvaille : [guaranteed] cartes garanties, puis des jets
/// successifs, en pourcentage — le premier raté arrête.
typedef CardDropRule = ({int guaranteed, List<int> extraChances});

// Dans `GameConstants` :
// --- TROUVAILLE (D1, D31, D57) ---
/// Les cartes trouvées après un combat, par type de nœud. Un type absent n'en
/// donne aucune : le boss garde sa récompense (D1).
static const Map<MapNodeType, CardDropRule> cardDrops = {
  MapNodeType.combat: (guaranteed: 1, extraChances: []),
  MapNodeType.elite: (guaranteed: 1, extraChances: [25]),
};

/// Les runes que la récompense du boss « XP » monte d'un niveau (D42(a)).
static const int bossXpRuneSharpens = 1;

/// La main maximale au début d'une run (D25) : la stat vit sur `RunState`.
static const int startingMaxHandSize = 10;
```

`maxHandSize` (`:33-36`) devient `startingMaxHandSize`, sa documentation dit la valeur de départ d'une stat de run ;
plus aucun chemin de pioche ne la lit (§4.3). `cardDrops` et `startingMaxHandSize` viennent en partie 1 ;
`bossXpRuneSharpens` en **partie 2**, avec son seul lecteur, l'affûtage du boss « XP » (§4.6, §10).

### 3.2. La courbe d'XP

`assets/data/xp_curve.json`, neuf, un document plat comme `audio.json` :

```json
{
  "xpPerLevelByAct": [115, 200, 310, 480, 590, 775, 955, 1100, 1040, 1185, 1370, 1370, 1300, 1375, 1015]
}
```

| Élément | Avec E3 |
|:---|:---|
| `XpCurveData` (`lib/models/data/xp_curve_data.dart`, neuf) | `fromJson` : `xpPerLevelByAct` liste **non vide** d'entiers **≥ 1**, refusée sinon (`FormatException`) ; `int thresholdFor(int act)` = `xpPerLevelByAct[min(max(act, 1), length) − 1]` — la dernière valeur répétée au-delà (D67), l'acte borné à 1 en dessous |
| `GameDataLoader` (`lib/services/game_data_loader.dart`) | Gagne `Future<T?> loadDocument<T>(String path, T Function(Map<String, dynamic>) fromJson)` : lit un document plat par le `bundle`, **avec `bundle.loadString(path, cache: false)`**, comme `_read` (`:161-183`) — le commentaire de `_read` (`:163-170`) dit pourquoi : sous `flutter test`, un `Future` mis en cache dans la zone d'un test terminé ne se résout jamais depuis le suivant, et les tests de widget du tutoriel reconstruisent le registre à chaque `testWidgets` (§8). La forme est au plan : une lecture neuve qui porte le drapeau et renvoie à ce commentaire, ou `_read` généralisé à un chemin et appelé par `loadDocument`. Il **accumule** son erreur — fichier absent, JSON illisible, `fromJson` qui lève — avec celles des entités (`:97-141`), que `throwIfFailed` (`:145-159`) remonte en une fois. À la différence d'`audio.json` (`game_data_service.dart:17-49`), la courbe fait échouer le démarrage |
| `loadGameDataRegistry` (`game_data_service.dart:67-154`) | Charge `assets/data/xp_curve.json` par `loadDocument`, avant `throwIfFailed` (`:137`) |
| `GameDataRegistry` (`game_data_registry.dart:11-43`) | Gagne `final XpCurveData? xpCurve`, optionnel (A27) |
| `xpCurveProvider` (`game_data_service.dart`, neuf) | `Provider<XpCurveData>` : `ref.watch(gameDataLoaderProvider).requireValue.xpCurve`, une `StateError` explicite s'il manque (A9) |

Le dossier `assets/data/` est déjà déclaré (`pubspec.yaml:35`) : `dart run tool/sync_assets.dart --check` reste propre.
`CLAUDE.md` change de deux lignes, dans la même tâche de la partie 1 : l'arbre de `assets/data/` nomme les documents
plats (« `audio.json, patch_notes.json` # flat ») et gagne `xp_curve.json` ; la rubrique « Data layer » énumère les
modèles de `lib/models/data/` qui correspondent aux assets JSON (`card_data.dart`, … `audio_data.dart`) et gagne
`xp_curve_data.dart`.

### 3.3. Les trois reliques

Toutes `trigger: "startOfRun"` : leur effet est une règle de run, posée à l'acquisition (`InventoryController.addRelic`,
`inventory_controller.dart:27-32`) et retirée, symétriquement, à l'échange (§4.2) — le modèle de
`scholars_satchel.json`.

**Les six fichiers neufs de §3.3 à §3.5** — les trois reliques, les deux événements, *Transcendance* — **déclarent leur
`"id"`**, égal au nom du fichier. `CLAUDE.md` permet de l'omettre, le chargeur du jeu l'injectant ; mais le chargeur du
script de simulation le lit en dur, avant toute exclusion (`d26_economy_sim.dart:756`, `:770`, `:887`), et planterait
sans lui (§9).

| Fichier | Nom fr · en | Rareté | `effectType` | `value` | Description fr · en | Emoji |
|:---|:---|:---|:---|---:|:---|:---|
| `relics/bounty_ledger.json` (A de D31) | Registre des primes · Bounty Ledger | `rare` (D57) | `increase_elite_card_chance` | 25 | « Après un combat d'élite, +25 % de chance de trouver une seconde carte. » · "After an elite fight, +25% chance to find a second card." | 📜 |
| `relics/gleaners_pouch.json` (C de D31) | Sacoche du glaneur · Gleaner's Pouch | `rare` (D57) | `increase_combat_card_drops` | 1 | « Après un combat normal, trouvez une carte de plus. » · "After a normal fight, find one more card." | 👝 |
| `relics/grindstone.json` (D42(a)) | Meule · Grindstone | `legendary` (D42) | `increase_boss_rune_sharpens` | 1 | « La récompense du Boss d'XP fait gagner un niveau à une rune de plus. » · "The XP Boss reward raises one more rune by a level." | ⚙️ |

### 3.4. Les deux événements

`events/relic_peddler.json` (D23) — titre « Le Colporteur » · "The Peddler" ; description : « Un colporteur au regard
vif soupèse vos reliques. « Je prends la moins précieuse — contre de l'or, ou contre mes remèdes si vous en avez
besoin. » » · "A sharp-eyed peddler weighs your relics. 'I'll take the least precious one — for gold, or for my
remedies if you need them.'"

| Choix (fr · en) | Résultat (fr · en) | `actions` | Condition |
|:---|:---|:---|:---|
| « Vendre votre relique la plus faible (+40 à +200 Or selon sa rareté) » · "Sell your weakest relic (+40 to +200 Gold depending on its rarity)" | « Le colporteur soupèse la relique, hoche la tête et vous compte ses pièces. » · "The peddler weighs the relic, nods, and counts out his coins." | `trade_relic` 40 | une relique portée |
| « L'échanger contre des remèdes (+20 % des PV max, si vos PV sont sous la moitié) » · "Trade it for remedies (+20% max HP, if your HP is below half)" | « Il emporte la relique et vous tend une fiole amère. Vos blessures se referment. » · "He takes the relic and hands you a bitter vial. Your wounds close." | `trade_relic` 0, `heal_percent` 20 | une relique portée ; `requiresHpBelowPercent: 50` |
| « Passer votre chemin (Rien) » · "Move on (Nothing)" | « Le colporteur hausse les épaules et reprend sa route. » · "The peddler shrugs and goes on his way." | — | — |

`events/wandering_grinder.json` (D42(b)) — titre « Le Rémouleur » · "The Knife-Grinder" ; description : « Un rémouleur
fait tourner sa meule au bord du chemin. Il affûte tout — mais se paie en sang. » · "A knife-grinder turns his wheel
by the roadside. He sharpens anything — but takes his fee in blood."

| Choix (fr · en) | Résultat (fr · en) | `actions` | Condition |
|:---|:---|:---|:---|
| « Lui confier une rune (-10 % des PV max, +1 niveau de rune) » · "Hand him a rune (-10% max HP, +1 rune level)" | « La meule chante, une goutte de votre sang perle sur la pierre — et la rune brille plus fort. » · "The wheel sings, a drop of your blood beads on the stone — and the rune glows brighter." | `lose_hp_percent` 10, `sharpen_rune` 1 | une rune affûtable ; PV > le coût |
| « Passer votre chemin (Rien) » · "Move on (Nothing)" | « Vous laissez le rémouleur à sa meule. » · "You leave the knife-grinder to his wheel." | — | — |

Chaque choix porte son résultat (`result_text_fr`, `result_text_en`), comme les événements livrés ; un choix sans
action existe déjà (*Prier et partir*, `mysterious_altar.json`).

### 3.5. Les récompenses de niveau

| Fichier | Avec E3 |
|:---|:---|
| `level_up_rewards/wisdom.json` | `"pool": "mythic"` ; `"values": {"mythic": 1}` à la place des cinq paliers — le chargeur refuse une mythique de stat sans valeur `mythic` (`level_up_reward_data.dart:283-286`), et 1 est la valeur jouée (`d26_economy_sim.dart:2655`) ; `displayOrder` 4 inchangé. Son plateau (1, 2, 2, 3, 4), qu'ADR-098 renvoyait à P-16, disparaît avec ses paliers |
| `level_up_rewards/transcendence.json` (neuf, D42(c)) | « Transcendance » · "Transcendence" ; description « Le niveau maximal d'un type de rune de votre deck monte de 1, sur toutes vos cartes, pour toute la run » · "One rune type in your deck can climb one level higher on every card, for the rest of the run" (A15 : un type de rune, pas une carte) ; `shortDescription` « Plafond de rune +1 » · "Rune cap +1" ; `"effect": "raiseRuneCap"`, `"pool": "mythic"`, `"requires": "raisableRune"`, `"displayOrder": 9`, `"values": {}` |

Le catalogue compte neuf récompenses : **cinq tirables** (*Vitalité*, *Aiguisage*, *Affinité*, *Précision*,
*Férocité*) et **quatre mythiques** (*Sagesse*, *Trèfle à 4 feuilles*, *Miroir*, *Transcendance*), rangées 1 à 9.

### 3.6. Les passifs

| Fichier | Avec E3 |
|:---|:---|
| `passives/blessing.json` | Gagne `"threshold": 5` (D60) ; son bloc `mastery` reste sur `value`, sans plancher |
| `passives/mana_flux.json` | Le bloc `mastery` gagne `"floor": 2` (D43, D60) ; la description gagne une phrase : « La Maîtrise abaisse ce seuil, jamais sous 2. » · "Mastery lowers this threshold, never below 2." |

### 3.7. Les runes

`forge_upgrades/enduring.json` et `forge_upgrades/cheap.json` gagnent `"binary": true` (A16). Aucune autre rune ne
change.

### 3.8. Le modèle

| Où | Avec E3 |
|:---|:---|
| `RunState` (`run_controller.dart:23-164`) | Gagne **`maxHandSize`** (défaut `GameConstants.startingMaxHandSize`), **`extraCombatCards`** (0), **`eliteCardChanceBonus`** (0, en points de pourcentage), **`extraBossRuneSharpens`** (0) et **`runeCapBonus`** (`Map<String, int>`, vide) ; constructeur (`:64-75`), `copyWith` (`:77-104`), `toJson` (`:106-118`) et `fromJsonWithReport` (`:141-160`, une clé absente prend le défaut) |
| `RunController` | `applyRunRuleModifier` (`:297-299`) gagne `extraCombatCardsAcc`, `eliteCardChanceAcc`, `extraBossRuneSharpensAcc` ; gagne `raiseRuneCap(String runeId)` (+1 dans `runeCapBonus`) et `loseRelic(RelicData)` (§4.9) |
| `PlayerStatsManager` (`run/player_stats_manager.dart`) | `applyRunRuleModifier` (`:99-108`) écrit les trois accumulateurs ; `gainXp` (`:113-144`) lit le palier dérivé (§4.4) ; `applyRelicEffect` (`:239-436`) et `removeRelicEffect` (`:438-458`) gagnent les trois `effectType` (§4.2) |
| `EntityStats` (`lib/models/entity_stats.dart`) | `xpToNextLevel` (`:18`, `:36`, `:55`, `:73`, `:103`, `:126`) **supprimé** (A8) |
| `DeckState` (`deck_controller.dart:11-129`) | Gagne `int get fusionRankSum` (A12) |
| `DeckNotifier` | Gagne `raiseRuneLevel` (A13, §4.7) ; `mergeCards` (`:294-324`) devient `mergeCards(List<String> selectedIds, {Map<String, int> capBonus = const {}})` et passe le bonus à `consolidate` (`:314`) |
| `RewardState` (`reward_controller.dart:12-67`) | Gagne `foundCards` (`List<CardInstance>`) ; `rolledBonusCard` (`:24`, `:37`, `:51`, `:64`, `:207`) **supprimé** en partie 2, avec la carte bonus ; gagne `sharpenedRunes`, de type `List<({String cardUniqueId, String runeId, int level})>?` : une entrée par rune montée par le boss « XP » — l'identifiant de l'exemplaire, l'id de la rune et le niveau **atteint** ; `null` hors d'un boss « XP », liste vide pour un boss « XP » sans paire affûtable — §4.6 |
| `EncounterSystem` | `calculateBudget` (`encounter_system.dart:86-131`) : `playerCardsCount` (`:93`, `:101`) devient `deckFusionRanks` ; de même `generateEnemiesForLevel` (`:220`, `:235`), `CombatController.initializeCombat` (`combat_controller.dart:49`, `:62`, `:103`, `:116`) et `CombatDebugLogger` (`combat_debug_logger.dart:17`, `:62`, `:69`, `:70` — `:69` écrit la formule en clair, « (cardsCount * 2) ») |
| `PassiveMastery` (`passive_data.dart:10-71`) | Gagne `floor` (`int?`) ; `fromJson` (`:43-70`) le refuse si `perPoint` n'est pas négatif ; `describe` (`:39-41`) cède la place à `PassiveData.describeMastery` (A23) |
| `PassiveData` | La documentation de `threshold` (`:90-92`) dit ses deux lectures — les Compétences à réunir de *Flux*, l'armure d'une tranche de *Bénédiction* ; `fromJson` (`:166-204`) refuse un `floor` supérieur à la valeur de base du paramètre ; `withMastery` (`:134-146`) applique le plancher ; gagne `describeMastery(locale, {from, to})` |
| `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) | Gagne `binary` (`bool`, défaut faux ; refusé avec un `maxLevel` autre que 1), lu et écrit par `toJson` ; `boundLevel` (`:326-330`) devient `boundLevel(int requested, {int carried = 0, int capBonus = 0})`, le bonus ajouté au plafond ; `nameAt` (`:299-300`) suit A18 |
| `ForgeRuneRules` (`lib/game/services/forge_rune_rules.dart`) | `consolidate` (`:21`), `canSharpen` (`:144`), `hasSharpenableRune` (`:150-153`) et `wellLevel` (`:185`) gagnent, après leurs paramètres d'aujourd'hui, `{Map<String, int> capBonus = const {}}`, lu par id de rune (§4.8). **Optionnel, à défaut neutre**, comme sur `boundLevel` et `mergeCards` (A17) : les appels de test d'aujourd'hui, tous sans bonus, compilent tels quels — ces quatre fonctions dans `forge_rune_rules_test.dart`, `boundLevel` dans `forge_upgrade_data_test.dart`, `DeckNotifier.mergeCards` dans `deck_controller_test.dart` et `decoupled_forge_test.dart` (17, 7, 7 et 3 lignes, comptées par `git grep -c`) ; seuls les appelants de production le passent (§4.8). Gagne `raisableCaps` et `sharpenablePairs` |
| `LevelUpRewardData` (`level_up_reward_data.dart`) | `RewardEffect` (`:7-13`) gagne `raiseRuneCap` ; `RewardRequirement` (`:36-40`) gagne `raisableRune` ; `isAvailableWith` (`:165-168`) devient `isAvailableWith(PassiveData? passive, {bool hasRaisableRune = false})` — défaut faux, comme `generateChoices` : ses appels d'aujourd'hui à un argument (`level_up_reward_requirement_test.dart:89-93`) compilent tels quels ; `describe` (`:138-150`) reçoit la Maîtrise effective, paramètre requis (A23, §4.11) ; `DraftChoiceLabels.getChoiceDescription` (`draft_choice_labels.dart:47-56`) de même. **En partie 2**, avec *Sagesse* mythique, la documentation d'`inPool` (`:170-181`) est réécrite : « exactement six tirables » (`:175-177`) devient cinq (D11), et ses « deux lecteurs » (`:179-181`), le tirage et la prose du tutoriel, en comptent un troisième, la fiche des probabilités (§5.1) |
| `LevelUpRewardService.generateChoices` (`level_up_reward_service.dart:89-148`) | Gagne `hasRaisableRune` (défaut faux), passé au filtre (`:99-100`) ; `DraftChoice` gagne `isRuneCapOption` à côté d'`isCloneOption` (`:29`) |
| `EventChoice`, `EventAction` (`lib/models/data/event_data.dart`) | `EventChoice` gagne `requiresHpBelowPercent` (`int?`, 1 à 100) ; `isSelectable` (`:66-92`) reçoit ce dont les conditions neuves ont besoin (§4.9) ; `EventAction.fromJson` (`:124-126`) refuse une valeur hors bornes pour les quatre types neufs |
| `EventState` (`lib/models/event_state.dart`) | Gagne `tradedRelic` (`RelicData?`) |

---

## 4. Le moteur

### 4.1. La trouvaille

**Le tirage** — une fonction pure, `CardDrops.roll(CardDropRule? rule, {extraGuaranteed, firstExtraBonus, Random rng})`
(`lib/game/systems/card_drops.dart`, neuf) : `null` → 0 ; sinon `guaranteed + extraGuaranteed`, puis pour chaque
chance de `extraChances`, la première augmentée de `firstExtraBonus`, une carte de plus si `rng.nextInt(100) < chance`,
et l'arrêt au premier raté.

| Nœud | Règle | Bonus de run | Cartes |
|:---|:---|:---|:---|
| Combat normal | 1 garantie | `extraCombatCards` (C : +1 par exemplaire) | 1 (+ C) |
| Élite | 1 garantie, un jet à 25 % | `eliteCardChanceBonus` (A : +25 points par exemplaire) sur ce jet | 1, ou 2 à 25 % (50 % avec un A, 100 % avec trois) |
| Boss, et tout autre type | — | — | 0 : le boss garde sa récompense (D1) |

**Dans `RewardController.handleVictory`** (`reward_controller.dart:75-209`), après les clones du boss
(`:168-184`) : le nombre tiré pour `currentNode.type`, puis autant de cartes tirées **uniformément**, avec remise,
parmi `allCards.where((c) => c.isOfferableTo(heroClassId))` — le prédicat de la carte bonus d'aujourd'hui
(`:186-194`, ADR-101) —, chacune `CardInstance(data: c, rarity: CardRarity.common)`, dans `foundCards`. Pool vide :
aucune carte (ADR-101 D4, pas de repli). Le `Random` est passé, pour les tests.

**Les deux bonus des reliques** : `handleVictory` lit `ref.read(runProvider)` — il n'y lit aujourd'hui que
`heroClassId` (`:188`) — et passe à `CardDrops.roll` **`extraGuaranteed: extraCombatCards` sur un combat normal
seulement**, et **`firstExtraBonus: eliteCardChanceBonus` sur une élite seulement** ; sur tout autre nœud, ni l'un ni
l'autre. C ne touche donc jamais l'élite, ni A le combat normal (D31, D57).

**Dans `collectGoldAndXp`** (`:211-225`) : les cartes trouvées rejoignent le deck par `addCardToMasterDeck`, comme la
carte bonus aujourd'hui (`:217-219`).

**À l'écran** — `_presentNextReward` (`game_screen.dart:93-149`), au pas « or et XP » : **en partie 1**, une
notification `rewardCardFound` par carte s'ajoute **à côté** de celle de la carte bonus (`:129-135`), qui dit encore la
carte que donne le boss « XP » ; celle-ci disparaît **en partie 2**, avec `rolledBonusCard` (§4.6) (A10). Aucun test
ne monte `GameScreen` : une commande de contrôle garde ce lecteur dès la partie 1 (§8).

Une carte trouvée est **commune**, donc **sans rune** : une commune n'en porte jamais (spec E2, §4.12). Les signatures,
`unique`, n'en sont jamais (`isOfferableTo`, `card_data.dart:170-173`) — le pool est les 17 neutres. **Ce que lit un
test de la trouvaille** : la rareté passée à l'instance remplace celle de la donnée (`card_instance.dart:14-17`), si
bien que `card.rarity` vaut `common` pour toute carte trouvée, signature comprise ; un test qui garde le filtre lit donc
la donnée de la carte — `card.data.rarity`, `card.data.heroClass`, `card.data.id` —, et l'assertion « toutes
communes » sur `card.rarity` garde, elle, la construction (§8).

### 4.2. Les règles de run des reliques

| `effectType` | `applyRelicEffect`, en `startOfRun` | `removeRelicEffect` |
|:---|:---|:---|
| `increase_combat_card_drops` | `applyRunRuleModifier(extraCombatCardsAcc: value)` | le même, en `-value` |
| `increase_elite_card_chance` | `applyRunRuleModifier(eliteCardChanceAcc: value)` | idem |
| `increase_boss_rune_sharpens` | `applyRunRuleModifier(extraBossRuneSharpensAcc: value)` | idem |

Sur le modèle exact d'`increase_cards_per_turn` (`player_stats_manager.dart:302-304`, `:453-455`) : la symétrie
garde l'Autel (`exchangeRelics`, `:460-467`) et l'échange de D23 (§4.9) de toute fuite. Le retrait au menu de debug
reste asymétrique, comme il l'est (`debug_actions.dart:100-113`).

### 4.3. La main

**La stat.** `RunState.maxHandSize`, posée à `GameConstants.startingMaxHandSize` par `startNewRun`
(`run_controller.dart:208-231`) et par le défaut du constructeur, sérialisée ; aucun accumulateur (A11) ; le menu de
debug l'écrit (`debug_run_tab.dart`, un champ « Main max » sur le modèle de « Cartes par tour », `:51-58`).

**Les six chemins** — tous passent par `_drawInto`, qui s'arrête à la borne (`deck_controller.dart:200`), et lisent
désormais la stat :

| Chemin | Site | Aujourd'hui | Avec E3 |
|:---|:---|:---|:---|
| Main d'ouverture | `TurnPhaseManager.startPlayerCombat` (`turn_phase_manager.dart:38-41`) → `startCombat` | `GameConstants.maxHandSize` | `runController.currentState.maxHandSize` |
| Pioche du tour | `startPlayerTurn` (`:54-57`) → `drawCards` | idem | idem |
| Effet `draw` d'une carte | `DrawEffectStrategy` (`strategies.dart:152`) | idem | `runController.currentState.maxHandSize` |
| Rune `quick` (`addEffect draw`) | le même `DrawEffectStrategy`, par `effective.addedEffects` (`effect_resolver.dart:142-152`) | idem | idem |
| *Frénésie* | `FrenzyPassive` (`passive_strategies.dart:217-219`) | idem | `run.currentState.maxHandSize` |
| Menu de debug | `DebugActions.drawCards` (`debug_actions.dart:88-93`) | idem | `read(runProvider).maxHandSize` |

`DeckNotifier.startCombat` et `drawCards` gardent leur paramètre `maxHandSize` : la couture reste, seule la valeur
passée change. `git grep -n "GameConstants.maxHandSize" -- lib test` ne rend plus rien.

### 4.4. L'XP

| Lecteur | Aujourd'hui | Avec E3 |
|:---|:---|:---|
| `PlayerStatsManager.gainXp` (`player_stats_manager.dart:113-144`) | `currentStats.xpToNextLevel`, puis `100 × 1,5^(n−1)` (`:119`, `:126-127`) | `ref.read(xpCurveProvider).thresholdFor(controller.currentState.act)`, relu à chaque tour de boucle ; écrit `level`, `xp`, `pendingDrafts`, plus de palier |
| La barre d'XP de la carte du monde (`hero_mini_stats_panel.dart:170-182`) | `stats.xpToNextLevel` | `xpCurveProvider` à l'acte courant |
| Le menu de debug : « Gagner un niveau » (`debug_actions.dart:71-76`), le libellé « XP (seuil N) » (`debug_hero_tab.dart:142`) | idem | idem |
| Le tutoriel (`tutorial_engine.dart:38`, `:87`, `:510-532` ; `tutorial_xp_widget.dart:60`, `:121`) | son propre `xpToNextLevel`, sa propre formule | le champ `mockState.xpToNextLevel` (`:38`, `:87`) disparaît ; un getter de l'engine, **`TutorialEngine.xpThreshold`** — un nom sans `xpToNextLevel`, que la commande de contrôle de §8 cherche —, rend `data.xpCurve!.thresholdFor(1)` : la même fonction pure, sur son registre (ADR-081), qui porte toujours la courbe (A27) ; le tutoriel est à l'acte 1. `gainXp` (`:510-532`) et `tutorial_xp_widget.dart:60`, `:121` le lisent |

La récompense du boss se compte **avant** le changement d'acte : `collectGoldAndXp` précède `completeCurrentNode`, qui
appelle `advanceToNextWorld` (`game_screen.dart:121`, `:208-211` ; `map_progression_manager.dart:41-43`) — l'XP du boss
de l'acte n se paie au prix de l'acte n, comme dans le script (`:2829`). `git grep -n "xpToNextLevel\|pow(1.5" -- lib test`
ne rend plus rien.

### 4.5. La DDA

```
PlayerPower = maxHP + might × 10 + maxMana × 15 + relics × 5 + 2 × Σ fusionRank      (encounter_system.dart:97-101)
```

`DeckState.fusionRankSum` = Σ `card.rarity.fusionRank` sur le deck — 0 pour une commune et pour une signature
`unique` (`card_data.dart:37-43`). L'écran de combat le passe (`game_screen.dart:262`). Le journal de debug écrit
« Σ rangs : N » à la place de « Cards » (`combat_debug_logger.dart:62`), et « 2 × Σ rangs » à la place de « cardsCount * 2 » dans la
formule écrite en clair (`:69`) et dans son calcul (`:70`). Les quatre autres
termes, l'`ExpectedPower` et le budget ne changent pas.

### 4.6. Le boss « XP »

| Étape | Avec E3 |
|:---|:---|
| `handleVictory` | Le triple d'XP et d'or (`:89-91`, `:99-101`) reste ; **la carte bonus (`:186-194`) disparaît** (D42(a)) ; `sharpenedRunes` vaut une liste vide sur un boss « XP », `null` sur tout autre nœud — le discriminant de l'écran |
| `collectGoldAndXp` | Après l'or et l'XP, sur un boss « XP » : `GameConstants.bossXpRuneSharpens + RunState.extraBossRuneSharpens` tirages ; chacun prend une paire au hasard parmi `ForgeRuneRules.sharpenablePairs(deck, catalogue, capBonus)` — les paires (carte, rune) dont la rune monte encore — et la monte d'un niveau par `DeckNotifier.raiseRuneLevel` (A13, A14) ; les paires montées remplissent `RewardState.sharpenedRunes` |
| L'écran | `_presentNextReward` lit l'état dans une copie prise **avant** `collectGoldAndXp` (`game_screen.dart:95`, `:121`) : pour les runes montées, il **relit** `ref.read(rewardProvider)` après l'appel. `sharpenedRunes` nul : rien ; une notification `restCampSnackbarSharpen` par entrée — `{cardName}` lu dans le deck par `cardUniqueId`, `{runeName}` dans le catalogue des runes par `runeId`, selon la locale, `{level}` le niveau atteint (§3.8) ; liste vide — un boss « XP » sans paire affûtable — : `restCampSharpenNone` (A5). Les cartes trouvées, tirées par `handleVictory`, se lisent sur la copie |
| L'infobulle (`map_node_widget.dart:59-61`) | Titre `legendBossXp`, description `tooltipBossXpDesc` (A25) — à la place de `tooltipBossDesc`, que lit aujourd'hui la branche du boss « XP » (`:61`) ; aucun test ne monte `MapNodeWidget`, une commande de contrôle garde la description (§8) |

Le boss « XP » reste l'un des trois boss de chaque acte (`map_node_generator.dart:57`) : ni pool `draft`, ni boutique,
ni quatrième type (D42).

### 4.7. L'affûtage sans or

```dart
// DeckNotifier
bool raiseRuneLevel(String cardId, String runeId,
    {int levels = 1, Map<String, int> capBonus = const {}})
```

Refuse — sans rien toucher — si la carte n'est pas dans le deck, ne porte pas la rune, si la rune est absente du
registre, ou si `boundLevel(levels, carried: n, capBonus: …)` vaut 0 ; sinon réécrit `id:n` en `id:n+k` **à sa place**
(`ForgeRuneRules.replaceRune`, `forge_rune_rules.dart:163-171`), `k` le niveau borné. Trois appelants : le boss « XP »
(§4.6), l'événement (§4.9), et `GoldManager.sharpenRune` (`gold_manager.dart:21-51`), qui garde son contrat — refuse
sans payer si l'écriture serait refusée, paie `sharpenCost(n)`, puis l'appelle. L'or du feu ne change pas (D20).

### 4.8. La mythique de D42(c)

**Le bonus.** `RunState.runeCapBonus[id]` : le plafond effectif d'une rune est `maxLevel + bonus` ; une rune sans
plafond reste sans plafond. `RunController.raiseRuneCap(id)` l'augmente de 1.

**Ses lecteurs** — tous les écrivains de niveau de D72, et ce qui en dépend :

| Lecteur | Site | Le bonus lu |
|:---|:---|:---|
| La borne | `ForgeUpgradeData.boundLevel` (`forge_upgrade_data.dart:326-330`) | `capBonus` ajouté au plafond |
| La fusion | `ForgeRuneRules.consolidate` (`:21-31`, par `_bounded`, `:41-42`), appelé par `DeckNotifier.mergeCards` (`deck_controller.dart:314`) | `RunState.runeCapBonus`, passé par l'écran de deck |
| Les pré-forgées | `ShopController._rollRandomUpgrade` (`shop_controller.dart:72`) | idem |
| L'affûtage au feu | `canSharpen` (`forge_rune_rules.dart:144-145`), `hasSharpenableRune` (`:150-157`) — lus par `GoldManager` (`gold_manager.dart:34`), l'option du feu (`rest_screen.dart:128-131`), la sélection (`rest_card_selection_screen.dart:118-124`) et le dialogue (`sharpen_rune_dialog.dart:34`), ces deux derniers dans leurs deux modes, le feu et le *Rémouleur* (§4.9) ; et par la condition du *Rémouleur*, `EventChoice.isSelectable`, que l'écran appelle (`event_screen.dart:528`) | idem |
| Le Puits | `wellLevel` (`:185-186`), lu par `GoldManager.exchangeRune` (`gold_manager.dart:86`) et l'écran (`forge_fusion_screen.dart:250`) | idem |
| Les sources neuves | `raiseRuneLevel`, `sharpenablePairs` (§4.6, §4.7, §4.9) | idem |

Le tutoriel n'en passe aucun : sa fusion n'a pas de run.

**Les candidates** — `ForgeRuneRules.raisableCaps(deck, catalogue, capBonus)` : les runes que le deck porte **à leur
plafond effectif**, `maxLevel` non nul, **non `binary`**, une fois chacune, dans l'ordre du catalogue. Dans les onze
runes livrées : `eco`, `quick`, `freezing` (plafond 1) et `precise` (plafond 10) ; jamais `enduring` ni `cheap`
(binaires), ni les cinq runes sans plafond.

**L'offre.** `transcendence.json` déclare `requires: raisableRune` : `generateChoices` ne la tire que si
`raisableCaps` est non vide — l'écran de draft le calcule (`draft_screen.dart:105-110`) ; le tutoriel ne le passe pas,
et ne la tire jamais. Son jet est le sien, 0,5 % plus 0,15 % par point de Chance (D62).

**Le choix** — `_onChoiceSelected` (`draft_screen.dart:651-672`) ouvre, pour `isRuneCapOption`, une modale sur le modèle
du clonage (`_showCloneModal`, `:591-649`) : une ligne par candidate — son nom, `runeCapLine` « Niveau maximal {from} → {to} » —, non
refermable ; le toucher appelle `raiseRuneCap`, notifie `runeCapRaised`, puis termine le draft. Liste vide — impossible
sous la condition — : le draft se termine, comme le clonage sans option (`:599-602`).

**Ce que cela ouvre** : `eco` 2 ou `quick` 2, par l'affûtage — feu, boss, événement — ou par l'héritage d'une fusion
(D13, bornée par le plafond effectif) ; c'est le moteur que D27 fermait, rendu rare (11 à 12 % des runs, D62) et
jamais avec `enduring` (D51). Le nom affiche le niveau dès qu'il dépasse 1 (A18).

### 4.9. Les événements

**Les actions neuves**, dans `EventController.selectChoice` (`event_controller.dart:47-133`), exécutées dans l'ordre du
choix :

| Type | `value` | Effet | Condition de choix |
|:---|:---|:---|:---|
| `trade_relic` | entier ≥ 0, l'or par rang | La relique visée (`EventState.tradedRelic`) quitte l'inventaire par `RunController.loseRelic` — `removeRelicEffect` puis `removeRelics` ; `value × (rareté.index + 1)` or si `value` > 0 | une relique visée |
| `heal_percent` | 1 à 100 | `heal(round(maxPv × value / 100))` | — |
| `lose_hp_percent` | 1 à 100 | `takeDamage(round(maxPv × value / 100))` | PV courants > ce montant, la règle de `take_damage` (`event_data.dart:68-74`) |
| `sharpen_rune` | entier ≥ 1, les niveaux | `DeckNotifier.raiseRuneLevel` sur la paire choisie, sans or (§4.7) | une rune affûtable dans le deck, plafond effectif compris |

`requiresHpBelowPercent: p` sur un choix : sélectionnable si `PV courants × 100 < PV max × p`. Les arrondis sont ceux du
script (`.round()`, `:3084`, `:3095`). Le texte du choix, écrit dans la donnée, dit les pourcentages ; les badges
(les `switch` de `_buildActionBadge`, `event_screen.dart:84-140`, et de `_buildCompactActionBadge`, `:218-274` — ce
dernier sur les boutons de choix, avant tout choix, `:534-536`) disent les montants calculés
et le nom de la relique (§5.1). **Sans relique visée**, le badge de chaque action `trade_relic` dit
`eventNoRelicToGive`, « Aucune relique à céder » — sur les deux choix d'échange du *Colporteur*, avant tout choix —, et
ces choix restent inactifs : leur condition, une relique visée, n'est pas remplie (arbitrage du propriétaire, n° 5,
§1.2).

**La relique visée** (A20) — `initializeEvent` et `setEvent` (`:16-42`) : si l'événement porte une action
`trade_relic` et que l'inventaire n'est pas vide, la relique de plus petite `RelicRarity.index`, tirée au hasard parmi
les ex æquo — les trois reliques neuves comprises, comme à l'Autel, qui n'en distingue aucune ; sinon nulle.

**Le choix de la rune** (A21) — `_handleChoice` (`event_screen.dart:32-68`) : un choix qui porte `sharpen_rune` pousse
d'abord la sélection du feu en mode affûtage (`RestCardSelectionScreen`, `isSharpen`), **sans or** : les cartes sans
rune affûtable — plafond effectif compris, le bonus de la run lu comme au feu (§4.8) — grisées comme au feu, puis
`SharpenRuneDialog`, dont le bouton dit `fusionRuneChoose` « Choisir », sans
coût ni condition d'or, et **n'écrit rien** — il rend la rune choisie, la sélection rend la paire. Paire rendue :
`selectChoice` résout le choix — la perte de PV, puis l'affûtage de cette paire. `null` (Annuler, retour) : rien n'est
résolu, le joueur revient aux choix. La forme du mode — un paramètre, une valeur d'énumération — est au plan ; l'écran
du feu garde son comportement.

**Le retour système** (A22) — `EventScreen` passe à `ScreenScaffold` `canPop: false` et un `onPopInvokedWithResult` qui
ne fait rien si `didPop` est vrai, appelle `_leave` si le choix est fait (`isResolved`), et ne fait rien sinon — le
mécanisme de `RestScreen` (`rest_screen.dart:139-142`), `screen_scaffold.dart` inchangé.

Les deux événements entrent dans le tirage uniforme des événements (`initializeEvent`, `:26-27`) : sept, chacun
une fois sur sept — ce que joue le script après le retrait de D29 (§9).

### 4.10. *Sagesse*

Mythique (§3.5) : son jet est le sien (`level_up_reward_service.dart:130-145`) ; elle quitte les trois emplacements,
qui tirent parmi cinq (`:101`, `:119`). `PlayerStatsManager.applyLevelUpReward` (`:73-97`) l'applique comme avant :
+1 `maxMana`. Le tutoriel l'écrit dans la liste des mythiques, par ses placeholders (§5.3).

### 4.11. Les seuils

| Passif | Avec E3 |
|:---|:---|
| *Bénédiction* (`BlessingPassive`, `passive_strategies.dart:136-157`) | `_armorPerTranche` (`:146-148`) disparaît ; `tranches = armure survivante ~/ passive.threshold`, rien si `threshold` < 1 (A24) ; la Maîtrise monte `value`, comme aujourd'hui (D60) |
| *Flux de Mana* (`ManaFluxPassive`, `:100-118`) | La ligne `threshold < 1 ? 1 : …` (`:107-110`) disparaît ; le seuil vient de `withMastery`, plancher 2 compris (A23) |
| `PassiveData.withMastery` (`passive_data.dart:134-146`) | Le paramètre visé vaut `base + perPoint × points`, puis, si `floor` est déclaré, `max(floor, …)` |

**Les textes de la Maîtrise** (A23) — `describeMastery(locale, from:, to:)` : `{amount}` = `|paramètre(to) − paramètre(from)|`,
plancher compris.

| Lecteur | Aujourd'hui | Avec E3 |
|:---|:---|:---|
| Fiche des stats (`stats_dialog.dart:57-60`) | `describe(effectiveMastery)` | de 0 à `effectiveMastery` ; la ligne n'apparaît que si `{amount}` > 0 |
| Écran de sélection (`class_passive_list.dart:250`) | `describe(1)` | de 0 à 1 |
| Carte d'*Affinité* (`level_up_reward_data.dart:138-150`, par `draft_choice_labels.dart:47-56`) | `describe(montant tiré)` | de la Maîtrise effective à la même plus le montant ; 0 : le repli d'`affinity.json`, « +{amount} Maîtrise, sans effet sur votre passif » |

**D'où vient la Maîtrise effective de la carte d'*Affinité*.** `DraftChoiceLabels.getChoiceDescription` et
`LevelUpRewardData.describe` gagnent un paramètre **requis**, `currentMastery` — requis pour que `dart analyze` désigne
tout appelant oublié : optionnel à 0, il ferait partir l'écart de 0, et *Affinité* sur *Flux* au plancher afficherait un
gain au lieu du repli. Ses quatre appelants de production (`git grep -n getChoiceDescription -- lib`) :

| Appelant | La Maîtrise effective lue |
|:---|:---|
| `draft_screen.dart:250`, `:343`, `:469` | `ref.read(runProvider).heroStats.effectiveMastery` |
| `tutorial_draft_widget.dart:89-93` | `widget.engine.mockState.heroStats.effectiveMastery` (ADR-081 : aucun provider) |

*Bénédiction* et les sept autres passifs, sans plancher, affichent ce qu'ils affichent aujourd'hui.

### 4.12. Ce que cela fait au jeu

Ordres de grandeur mesurés par le script (rapport §2.1, relance à k = 2 au §7.2) — sur son modèle, avec ses lots et
sans les signatures dans le deck :

| Mesure | Acte 1 | Acte 5 | Acte 15 |
|:---|---:|---:|---:|
| Cartes trouvées (cumul) | 6 | 28 | 86 |
| Taille du deck | 9 | 20 | 35 (30–41) |
| Fusions (cumul) | 2 | 11 | 45 |
| Niveau du héros | 2 | 10 (8–12) | 30 (25–35) |
| Niveaux de rune du boss « XP » (cumul) | 0 | 0 | 2 (0–4) |
| Niveaux de rune par l'événement (cumul) | 0 | 0 | 1 (0–3) |
| Reliques échangées (cumul) | 0 | 1 | 3 (1–5) |

Première fusion à l'acte 1, première rare à l'acte 4 dans toutes les runs, première épique à l'acte 10 dans 94 %. La
mythique de D42(c) est prise dans 12 % des runs avant l'acte 15. Le deck se régule : chaque fusion retire deux cartes
(D56). **La transition E2 → E3 se ferme** : les fusions, rares en `0.5.4` (spec E2, §4.12), deviennent le rythme normal.

Sur le jeu de `0.5.5` : le pool de la trouvaille est les 17 neutres (le script en joue 15, lots compris) ; les deux
signatures restent dans le deck, au rang 0 pour la DDA.

### 4.13. Les frontières

| Frontière | Ce que le lot voisin trouve |
|:---|:---|
| **E2 → E3** | `canSharpen`, `boundLevel` et la réécriture `id:n → id:n+1` réutilisés par les trois sources sans or, par `raiseRuneLevel` (§4.7) ; `fusionRank` lu par la DDA ; les fusions rares, que la trouvaille nourrit |
| **E3 → E4** | Les signatures sont encore des cartes : exclues de la trouvaille par `unique` (`isOfferableTo`), sans rune — la fusion ne leur en offre aucune (spec E2, §4.3), et le boss « XP » n'en trouve aucune à monter —, au rang 0 pour la DDA. **Un test le garde** (§8). E4 les sort du deck : la trouvaille et la DDA n'en voient pas la différence |
| **E3 → vague 5** | `isOfferableTo` gagne le lien au passif (§6 du brainstorm) : le pool de la trouvaille devient noyau + lot, sans toucher au tirage. `retain` et `transfusion` déclarent `binary: true` ; toute rune, et tout écrivain de niveau neuf, lit le bonus de plafond (A17). Le script lit la table d'XP du jeu (§9), comme la fiche 8.5 le veut |
| **E3 → P-16** | La table d'XP se recale à chaque changement de budget ennemi (D58) ; une relique « +N en main » écrira l'accumulateur qu'elle lit (A11) ; le puits d'or, la survie, la boucle XP / niveau ennemi |

### 4.14. Ce qui ne change pas

- `_drawInto` et ses deux conditions d'arrêt, dans cet ordre (ADR-078 D2) ; `cardsPerTurn` ; le remélange à sec.
- Le tirage de la relique d'élite et du boss « relique » ; les clones du boss « cartes » ; le triple d'XP et d'or.
- Le +10 % d'XP et d'or par niveau ennemi (`reward_controller.dart:86`, `:96`) ; le niveau ennemi (`encounter_system.dart:136-148`).
- L'affûtage au feu — une fois par visite, `50 × niveau` or (D14, D20) — ; le Puits ; la fusion ; la boutique.
- Les jets mythiques, un par récompense (D62) ; le Trèfle ; le Miroir.
- Les sept autres passifs ; la Maîtrise sur la valeur de *Bénédiction*.
- Les cinq événements livrés et leurs actions.

---

## 5. Textes joueur

### 5.1. Les chaînes ARB

Déclarées dans `app_en.arb` (gabarit) et `app_fr.arb` ; `flutter gen-l10n` régénère les trois
`app_localizations*.dart`. Tout texte que le lot écrit ou réécrit dans `lib/ui/` passe par elles.

| Clé | Français | English | Partie |
|:---|:---|:---|:---:|
| `rewardCardFound` (`{cardName}`) | `🃏 Carte trouvée : {cardName}` | `🃏 Card found: {cardName}` | 1 |
| `tooltipEliteDesc` *(réécrite ; `app_fr.arb:60`, `app_en.arb:105`, lue par `map_node_widget.dart:39`)* | `Un combat bien plus rude : une relique garantie, et une carte — parfois deux.` | `A much tougher fight: a guaranteed relic, and a card — sometimes two.` | 1 |
| `tooltipBossXpDesc` | `Le triple d'XP et d'or, et une rune de votre deck gagne un niveau.` | `Triple XP and gold, and one rune in your deck gains a level.` | 2 |
| `eventTradeRelic` (`{relic}`, `{amount}`) | `Cède {relic} : +{amount} Or` | `Give up {relic}: +{amount} Gold` | 2 |
| `eventGiveRelic` (`{relic}`) | `Cède {relic}` | `Give up {relic}` | 2 |
| `eventNoRelicToGive` | `Aucune relique à céder` | `No relic to give up` | 2 |
| `eventSharpenRune` (`{amount}`) | `+{amount} niveau de rune` | `+{amount} rune level` | 2 |
| `runeCapTitle` | `Choisissez la rune dont le plafond monte` | `Choose the rune whose cap rises` | 2 |
| `runeCapLine` (`{from}`, `{to}`) | `Niveau maximal {from} → {to}` | `Max level {from} → {to}` | 2 |
| `runeCapRaised` (`{runeName}`, `{level}`) | `{runeName} peut désormais monter jusqu'au niveau {level}.` | `{runeName} can now reach level {level}.` | 2 |
| `luckLevelRewardSubtitle` (`{mythicNames}`) | `Chances d'obtenir chaque rareté d'option lors de la montée de niveau ({mythicNames})` | `Chances of getting each option rarity when leveling up ({mythicNames})` | 2 |

**`eventNoRelicToGive`** est le badge d'une action `trade_relic` quand aucune relique n'est visée (§4.9) ;
`eventTradeRelic` et `eventGiveRelic` la nomment sinon.

**La fiche des probabilités** (`ProbabilitiesDialog`, carte du monde) nomme aujourd'hui les mythiques en dur, dans le
sous-titre de sa section « Récompense de niveau » : « … (Trèfle / Miroir) » · "… (Clover / Mirror)"
(`probabilities_dialog.dart:244-245`, en ligne). En partie 2, quand *Sagesse* et *Transcendance* deviennent mythiques,
ce sous-titre passe par `luckLevelRewardSubtitle` (arbitrage du propriétaire, n° 7, §1.2) : `build` lit les
récompenses sur le chargeur, `ref.watch(gameDataLoaderProvider).value`, comme la fiche des stats
(`stats_dialog.dart:36`) — jamais `GameDataRegistry.instance` (A9) —, prend
`LevelUpRewardData.inPool(rewards, RewardPool.mythic)`, dans l'ordre de `displayOrder`, et passe à `{mythicNames}`
leurs noms dans la locale, joints par « / » comme aujourd'hui (C3.2) ; aucune autre logique dans le widget. Sur le
catalogue de la fin de la vague : « (Sagesse / Trèfle à 4 feuilles / Miroir / Transcendance) » · "(Wisdom / 4-Leaf Clover / Mirror /
Transcendence)". Le titre de la section reste en ligne, comme le reste de la fiche.

**Reprises sans changement de texte** : `restCampSnackbarSharpen` et `restCampSharpenNone` (le boss « XP »),
`restCampSharpenTitle`, `restCampSharpenSubtitle`, `sharpenNothingOnCard` (la sélection de l'événement),
`fusionRuneChoose` (le bouton du dialogue sans or), `eventGainHp` et `eventLoseHp` (les deux actions en pourcentage,
avec le montant calculé), `legendBossXp` (le titre de l'infobulle). Leurs textes ne nomment pas le feu.

**Disparaissent**, tous deux **en partie 2**, avec le boss « XP » : la notification en ligne de la carte bonus
(`game_screen.dart:129-135`), avec `rolledBonusCard` ; le titre en ligne « Boss (XP & Or x2) »
(`map_node_widget.dart:59-61`).

Le menu de debug garde sa convention de libellés en ligne, en français (`debug_run_tab.dart`) : « Main max ».

### 5.2. Le contenu

Les textes des trois reliques (§3.3), des deux événements (§3.4), de *Transcendance* (§3.5) et la phrase ajoutée à
*Flux de Mana* (§3.6), en `_fr` et `_en`. *Sagesse* ne change pas de texte.

### 5.3. Le tutoriel

| Où | Avec E3 — français | Avec E3 — English | Partie |
|:---|:---|:---|:---:|
| Étape des nœuds, `tutorial_data.dart:90` (fr), `:74` (en) — Combat | « affrontement standard, pour l'or, l'XP et une carte. » | "a standard fight, for gold, XP and a card." | 1 |
| — `:91`, `:75`, Élite | « combat difficile qui récompense par une Relique et une carte — parfois deux. » | "a hard fight that rewards a Relic and a card — sometimes two." | 1 |
| — `:101-103`, `:85-87`, Boss | « … des cartes, le triple d'XP et d'or avec une rune montée d'un niveau, ou une relique améliorée. … » | "… cards, triple XP and gold with one rune raised a level, or an improved relic. …" | 2 |
| `tutorial_node_types_widget.dart:32-39` — Combat | « Combattez des monstres pour de l'or, de l'XP et une carte. » | "Fight base monsters for gold, XP and a card." | 1 |
| — `:40-47`, Élite | « Combat difficile. Offre une Relique et une carte. » | "Difficult fight. Rewards a Relic and a card." | 1 |
| — `:98-105`, Boss (XP & Or ×3) | « Offre le triple d'XP et d'or, et monte une rune. » | "Rewards triple XP and gold, and raises a rune." | 2 |
| Étape « L'Expérience », `tutorial_data.dart:316-317` (fr), `:305-306` (en) | « Vaincre des ennemis rapporte de l'XP. Le prix d'un niveau dépend de l'acte : {xpAct1} XP à l'acte 1, {xpAct2} à l'acte 2, et ainsi de suite — de quoi gagner deux niveaux par acte. » | "Defeating enemies grants XP. A level's price depends on the act: {xpAct1} XP in act 1, {xpAct2} in act 2, and so on — about two levels per act." | 1 |
| `tutorial_play_card_widget.dart:741-743` | « Main max : » suivi de `GameConstants.startingMaxHandSize` | "Max hand: " followed by the same | 1 |

`{xpAct1}` et `{xpAct2}` sont remplis par une fonction pure de `tutorial_prose.dart`, `fillXpPlaceholders(body,
XpCurveData curve)`, que `TutorialScreen` appelle à côté de `fillRewardPlaceholders` (`tutorial_screen.dart:150`), sur
son registre. L'étape « Le Draft de Récompenses » se réécrit d'elle-même par ses placeholders : « cinq types —
Vitalité, Aiguisage, Affinité, Précision, Férocité — et jusqu'à quatre options Mythiques : Sagesse, Trèfle à 4 feuilles,
Miroir et Transcendance ». Le tutoriel garde sa convention de textes en ligne.

### 5.4. Ce qui ne change pas

Les noms et descriptions des runes, des cartes, des cinq événements livrés, des vingt-cinq reliques livrées ; `legendBossXp`.

Les chiffres de la section « Récompense de niveau » de la fiche des probabilités : elle affiche
`calculateDraftProbabilities(luck, true)` (`probabilities_dialog.dart:105-106`), une répartition par rareté qui n'est
pas le jet mythique réel — 0,5 % plus 0,15 % par point de Chance, un jet par mythique
(`level_up_reward_service.dart:50-58`). L'écart est antérieur à E3 et hors du lot : E3 ne remplit que la parenthèse des
noms (§5.1).

---

## 6. L'éditeur de contenu

| Élément | Avec E3 |
|:---|:---|
| Relique (`entity_descriptor.dart:241-262`) | Rien : les trois `effectType` neufs sont admis par le vocabulaire lu sur le disque (`vocabularyKeys`, `:253`) |
| Événement (`:300-325`) | Rien dans le descripteur : les quatre types d'action neufs sont admis par `choices[].actions[].type` (`:310`) ; `requiresHpBelowPercent` et les bornes des valeurs sont refusés par `EventChoice.fromJson` et `EventAction.fromJson`, que la famille 7 appelle |
| Passif (`:263-299`) | `mastery.floor` s'édite comme un nombre ; refusé par `PassiveData.fromJson` (§3.8) ; le gabarit, à `perPoint` positif, ne le porte pas |
| Rune (`:326-392`) | Le gabarit (`:375-391`) gagne `"binary": false` ; `ForgeUpgradeData.fromJson` refuse `binary: true` avec un `maxLevel` autre que 1 |
| Récompense de niveau (`:393-439`) | `effect` et `requires` lisent leurs énumérations (`:402`, `:405`) : `raiseRuneCap` et `raisableRune` admis sans code |
| `xp_curve.json` | Hors de l'éditeur, comme `audio.json` : un document de configuration, pas une entité |

Les gabarits restent valides ; chaque fichier livré valide et se réécrit à l'identique
(`shipped_entities_round_trip_test.dart`).

---

## 7. La sauvegarde

**Rien à migrer ; `SaveMigrator.currentVersion` ne bouge pas.** `RunState` gagne cinq clés (§3.8), relues à leur défaut
si absentes ; `EntityStats` perd `xpToNextLevel`, qu'une sauvegarde plus ancienne porte et que la lecture ignore. Les
sauvegardes ne se transfèrent pas avant la `1.0.0` : rien de cela n'est testé ni annoncé. `RewardState` et
`EventState` ne se sauvegardent pas (`SaveService` n'écrit que la run, le deck et l'inventaire,
`save_service.dart:58-62`) : un nœud se sauvegarde résolu.

---

## 8. Tests

| Sujet | Fichier | Ce qu'il verrouille | Partie |
|:---|:---|:---|:---:|
| Le tirage de la trouvaille | `test/unit/card_drops_test.dart` *(nouveau)* | Combat : 1 ; avec `extraGuaranteed` 1 : 2 ; élite à jet gagnant : 2, perdant : 1, sur un `Random` dont le premier tirage est connu ; `firstExtraBonus` 75 : toujours 2 ; une règle absente (boss) : 0 ; l'arrêt au premier raté sur une règle à deux jets | 1 |
| La trouvaille dans la récompense | `test/unit/reward_controller_test.dart` | `foundCards` : une carte en combat, une ou deux en élite, aucune au boss ; toutes communes, sans rune ; `collectGoldAndXp` les ajoute au deck une fois ; les cas qui disent « aucune carte » d'un combat normal (`:127`) parlent des clones du boss (`rolledCards`) et gagnent l'attente de la carte trouvée. **Un cas neuf garde le filtre de la trouvaille**, sur une fixture de cartes de plusieurs classes et d'une `unique` **de la classe du joueur** : 200 tirages, aucune carte trouvée dont `card.data.heroClass` est une autre classe que celle de la run, ni dont `card.data.rarity` vaut `unique` — la donnée de la carte, jamais `card.rarity`, que l'instance porte `common` (§4.1) et sur laquelle l'assertion ne garderait rien —, les cartes de la classe du joueur admises. **Le cas `:284`**, qui garde le filtre de classe de la carte bonus — encore vivante en partie 1 —, **ne change pas**. **Les bonus des reliques, lus par `handleVictory`** (§4.1), sur un `Random` dont les tirages sont connus : (1) après `addRelic` de la *Sacoche du glaneur* (C), un combat normal donne **2** cartes, et une élite au jet perdant en donne **1** — C ne touche pas l'élite ; (2) après trois `addRelic` du *Registre des primes* (A, 75 points), une élite au jet qui perdait à 25 % donne **2** cartes, et un combat normal en donne **1** — A ne touche pas le combat normal ; (3) aucun des deux ne fait trouver une carte au boss | 1 |
| Les règles de run des reliques | `test/unit/relic_exchange_test.dart` | Chaque `effectType` neuf : `addRelic` monte la règle, `exchangeRelics` la rend ; deux exemplaires s'additionnent | 1 (A, C), 2 (D42(a)) |
| La borne de la main | `test/unit/hand_size_bound_test.dart` *(nouveau)* | `RunState.maxHandSize` à **7** (une valeur qui n'est pas la constante) : la main s'arrête à 7 par chacun des six chemins de §4.3 — la main d'ouverture à 9 cartes par tour, la pioche du tour, une carte `draw`, une carte portant `quick:1`, *Frénésie* sur une main pleine, `DebugActions.drawCards` ; la conservation des piles tient. **L'écrivain** : `startNewRun` pose `startingMaxHandSize` — après une run à 7, la suivante repart à 10 | 1 |
| La stat de la main | `test/unit/run_state_persistence_test.dart` | `maxHandSize`, `extraCombatCards`, `eliteCardChanceBonus`, `extraBossRuneSharpens`, `runeCapBonus` aller-retour ; absents : leurs défauts | 1, 2 (`extraBossRuneSharpens`, `runeCapBonus`) |
| La courbe | `test/unit/xp_curve_data_test.dart` *(nouveau)* | `fromJson` : liste vide, valeur 0 ou négative, valeur non entière refusées ; `thresholdFor(1)` = 115, `(15)` = 1015, `(16)` et `(40)` = 1015, `(0)` = 115 | 1 |
| Le chargement d'un document | `test/unit/game_data_loader_test.dart` ; les tests de widget du tutoriel | `loadDocument` : fichier absent, JSON illisible, `fromJson` qui lève — l'erreur accumulée avec celles des entités, levée une fois par `throwIfFailed`. **Le drapeau `cache: false`** (§3.2) n'est gardé par aucun test unitaire — dans une seule zone, le blocage ne se reproduit pas — mais par les tests de widget qui reconstruisent le registre à chaque `testWidgets`, par `buildTutorialTestRegistry` (`test/tutorial/tutorial_test_registry.dart:22-23`) : `tutorial_class_step_test.dart` (six `testWidgets`, `_pump`, `:16`), `tutorial_armor_step_test.dart`, `tutorial_starter_draft_test.dart`, `tutorial_merge_widget_test.dart`, `tutorial_play_card_step_test.dart`, `tutorial_merge_transition_test.dart`. Sans le drapeau, ils se bloquent dès le deuxième `testWidgets` d'un fichier : la partie 1 doit les laisser verts | 1 |
| Le palier dérivé | `test/unit/xp_scaling_test.dart:37-84` *(réécrit)* | Sur une courbe surchargée (`xpCurveProvider`) : 115 à l'acte 1 ; report de l'excédent ; plusieurs niveaux d'un coup ; le palier change avec l'acte ; un palier qui baisse sous l'XP accumulée donne le niveau au gain suivant ; au-delà de la table, la dernière valeur | 1 |
| Le palier, lu par ses écrans | `test/widget/map_screen_test.dart` ; `test/widget/debug_drawer_test.dart` | Sur une courbe de test `[115, 200]` : la barre d'XP de la carte du monde (`hero_mini_stats_panel.dart:170-182`) dit « XP: 0/115 » à l'acte 1 et « XP: 0/200 » à l'acte 2 — le panneau lit la courbe **à l'acte courant** ; l'onglet « Heros » du menu de debug dit « XP  (seuil 115) » (`debug_hero_tab.dart:142`) | 1 |
| La donnée livrée | `test/unit/real_bundle_load_test.dart` | `xp_curve.json` déclaré (`:71-72`, à côté des deux autres documents) ; ses quinze valeurs sont celles de D67, une à une ; les comptes de reliques (`:36`, `:95`), d'événements (`:37`, `:96`) et de récompenses (`:40-41`) suivent les fichiers neufs, partie par partie — 27 reliques en partie 1, puis 28 ; 7 événements et 9 récompenses en partie 2 | 1, 2 |
| La convention des ids | `test/unit/entity_id_convention_test.dart:22`, `:64-71` | `xp_curve.json` est un document de configuration, exclu comme les deux autres (`:22`) ; le compte des fichiers d'entité (`:64-71`, 88 aujourd'hui) passe à **90** en partie 1 (les reliques A et C), puis à **94** en partie 2 (la *Meule*, les deux événements, *Transcendance*), sa raison réécrite à chaque fois | 1, 2 |
| Le catalogue audio | `test/unit/audio/audio_catalogue_test.dart:51-52` | Il compte les fichiers de cartes, de reliques, de cartes de classe et d'ennemis (52 aujourd'hui) : **54** en partie 1, **55** en partie 2 (la *Meule*), sa raison réécrite | 1, 2 |
| La DDA | `test/encounter_system_test.dart` | `deckFusionRanks` remplace `playerCardsCount` (`:122`, `:139`, `:157`, `:175`, `:322`) ; `:536-575` : 10 rangs → +20 de `PlayerPower`, un deck de communes → 0 | 1 |
| La somme des rangs | `test/unit/deck_controller_test.dart` | `fusionRankSum` : 0 pour des communes et des `unique`, 1 · 2 · 3 · 4 de peu commune à légendaire, additionnés | 1 |
| Le journal de debug | `test/unit/combat_debug_logger_test.dart:28`, `:57` | Le paramètre renommé. Les deux cas n'affirment aujourd'hui que `returnsNormally` (`:44`, `:73`) : pour garder le texte, le cas `:28` capture la sortie en surchargeant `debugPrint` (rendu en `addTearDown`) — le journal écrit par `debugPrint` (`combat_debug_logger.dart:123`) — et y trouve « Σ rangs » et « 2 × Σ rangs », plus « Cards » ni « cardsCount » | 1 |
| La transition E3 → E4 | `test/unit/signature_cards_transition_test.dart` *(nouveau)* | Sur le registre réel, pour chaque classe : aucune signature dans la trouvaille — **par `handleVictory` lui-même**, sur un nœud de combat, `allCards` le registre réel, 200 victoires sur un `Random` connu : aucune carte trouvée dont `card.data.rarity` vaut `unique`, ni dont `card.data.heroClass` est une autre classe que celle de la run, **et** aucun `card.data.id` parmi les six signatures du registre — lues dans le registre réel, `registry.heroes.expand((h) => h.skills)` (`HeroData.skills`, `hero_data.dart:44`, que `referential_integrity_test.dart:211-229` égale au contenu de chaque dossier `classes/<id>/cards/`), un ensemble dont le test vérifie d'abord qu'il compte six ids, pour qu'un ensemble vide ne rende pas la clause vraie d'office (C3.1). Jamais `card.rarity`, que l'instance porte `common` (§4.1) : l'assertion ne garderait rien (`card_offer_filter_test.dart:24-57` garde déjà `isOfferableTo` seul ; la clause garde la trouvaille) ; une signature n'a aucune rune offerte (`drawRunes` vide) ; un deck des deux signatures et de communes vaut `fusionRankSum` 0 ; **en partie 2**, le boss « XP » ne monte jamais une rune de signature — aucune n'en porte | 1, 2 |
| Le tutoriel | `test/tutorial/tutorial_engine_test.dart:391-403`, `:407-414`, `:416-422`, `:697-699` ; `test/tutorial/tutorial_prose_test.dart` | Le palier est 115 à l'acte 1, à chaque niveau, lu par le getter `TutorialEngine.xpThreshold` (§4.4) : `:391-403` — trois gains de 35 (105 XP) ne font plus de niveau, quatre (140) donnent le niveau 2 et 25 XP ; son titre (`:391`, « … au-delà de xpToNextLevel ») devient « … au-delà du palier de l'acte » ; `:407-414` — 115 puis 115 ; `:416-422` — `gainXp(260)` donne le niveau 3, 30 XP, 2 drafts ; `:697-699` — `gainXp(115)` à la place de `gainXp(100)`. `{xpAct1}` → 115, `{xpAct2}` → 200 ; aucun placeholder ne survit dans l'étape XP ; **en partie 2**, cinq tirables et quatre mythiques nommées (`:13-27`, `:29-53`, `:63-74`) | 1, 2 |
| Le boss « XP » | `test/unit/reward_controller_test.dart:349-374`, `:399-415` *(réécrits)* ; `:284-347` *(supprimé)* ; `:146` | Plus de carte ; `1 + extraBossRuneSharpens` runes montées d'un niveau, tirées parmi les paires sous leur plafond effectif ; une rune au plafond jamais choisie ; aucune paire : `sharpenedRunes` vide ; hors d'un boss « XP », `sharpenedRunes` nul (§4.6). **La *Meule*, lue par la récompense** : après `addRelic` de la *Meule*, un boss « XP » monte **deux** runes (deux entrées, chacune au niveau atteint) ; sur un boss « cartes », un boss « relique » ou un combat, elle ne monte rien. **Le bonus de plafond, lu par le tirage** : un deck dont la seule rune est `eco:1` n'offre aucune paire (`sharpenedRunes` vide) ; après `raiseRuneCap('eco')`, il monte `eco:2` ; le triple d'XP et d'or (`:149-161`) inchangé. Avec `rolledBonusCard` disparaissent ses deux autres lecteurs : le cas `:284-347`, supprimé — le filtre de classe qu'il gardait est gardé depuis la partie 1 par le cas neuf de la trouvaille —, et l'assertion `:146`, remplacée par `sharpenedRunes` nul sur un combat normal (`git grep -n rolledBonusCard -- test` : `:146`, `:341`, `:359`, `:373`) | 2 |
| L'affûtage sans or | `test/unit/deck_controller_test.dart` ; `test/unit/run_controller_test.dart` | `raiseRuneLevel` : réécrit à sa place, borné par le plafond effectif, refuse sans rien toucher ; `sharpenRune` paie toujours `50 × n` et refuse au plafond **sans payer** | 2 |
| Le bonus de plafond, lu par ses lecteurs | `test/unit/run_controller_test.dart` ; `test/unit/shop_controller_test.dart` ; `test/widget/deck_screen_test.dart` ; `test/widget/rest_screen_test.dart` ; `test/widget/rest_card_selection_screen_test.dart` ; `test/widget/sharpen_rune_dialog_test.dart` ; `test/widget/forge_fusion_screen_test.dart` | Chaque écrivain de niveau de §4.8 lit **`RunState.runeCapBonus`**, et pas seulement le paramètre de sa fonction pure : un `eco:1` sans bonus, puis après `raiseRuneCap('eco')`. `sharpenRune` (par `GoldManager`) : refusé, puis `eco:2` contre 50 or. `exchangeRune` d'un `sharp:3` contre `eco` sur une rare : reçue à `eco:1`, puis `eco:2` (`wellLevel(3)` = 2). Les pré-forgées, sur le motif de `shop_controller_test.dart:344-389` — un catalogue réduit à une rune plafonnée à 1, 200 boutiques à l'acte 3, la boutique n'ayant pas de couture `Random` (`shop_controller.dart:156`) — : `{capped:1}` sans bonus, `{capped:1, capped:2}` avec, jamais `capped:3`. La fusion de trois rares portant `eco:1`, lancée depuis l'écran de deck : une épique à `eco:1`, puis `eco:2` — l'écran passe le bonus de la run à `mergeCards`. L'option « AFFÛTER » du feu, sur un deck dont la seule rune est `eco:1` : inactive, puis active ; le dialogue d'affûtage dit « Niveau maximal », puis « Niveau 1 → 2 ». **La sélection d'affûtage** (`rest_card_selection_screen.dart:118-124`, `:44-50`), sur le modèle du cas `rest_card_selection_screen_test.dart:86` et sur un deck dont la seule rune est `eco:1`, **dans ses deux modes**, avec or (le feu) et sans or (le *Rémouleur*) : la carte est grisée, et la toucher n'ouvre pas le dialogue et notifie `sharpenNothingOnCard` ; après `raiseRuneCap('eco')`, elle n'est plus grisée, et la toucher ouvre `SharpenRuneDialog` sur « Niveau 1 → 2 » — la sélection lit le bonus de la run, et non le seul plafond de la rune. L'écran du Puits (`forge_fusion_screen.dart:250`), pour un `sharp:3` donné contre `eco`, dit « Reçue au niveau 1 », puis « Reçue au niveau 2 » | 2 |
| Le bonus de plafond | `test/unit/forge_rune_rules_test.dart` ; `test/unit/forge_upgrade_data_test.dart` ; `test/unit/shop_controller_test.dart` | `boundLevel` avec `capBonus` ; `consolidate` : `eco:1` × 3 → `eco:2` sous un bonus de 1, `eco:1` sans ; `canSharpen`, `hasSharpenableRune`, `wellLevel` ; une pré-forgée bornée par le plafond effectif ; `raisableCaps` : à leur plafond, sans les binaires, sans les runes sans plafond ; `sharpenablePairs` ; `binary` lu, refusé avec `maxLevel` 2 ; `nameAt(2)` d'une rune de plafond 1 écrit le niveau ; l'ensemble exact des clés de `toJson` (`forge_upgrade_data_test.dart:312-329`) gagne `binary`, écrit toujours, comme `requiresExhaust` | 2 |
| Les runes livrées | `test/unit/forge_upgrades_catalog_test.dart` | `enduring` et `cheap` binaires, les neuf autres non ; l'ensemble `read` des clés lues par le modèle (`:239-258`) gagne `binary` | 2 |
| Le gabarit de rune de l'éditeur | `test/unit/content_editor/entity_descriptor_test.dart:260-273` | L'ensemble exact des clés du gabarit `forgeUpgrade` gagne `binary` (§6) | 2 |
| La mythique | `test/unit/level_up_reward_data_test.dart` ; `test/unit/level_up_reward_requirement_test.dart` ; `test/widget/draft_screen_test.dart` | `raiseRuneCap` et `raisableRune` lus ; `isAvailableWith` : *Transcendance* exclue sans candidate, *Affinité* inchangée ; **la condition, lue par le service** : `generateChoices` sous `forceLegendary` sort *Transcendance* avec `hasRaisableRune: true`, jamais sans. Les cas existants qui changent : `level_up_reward_requirement_test.dart:56-60` (« aucune autre récompense n'exige quoi que ce soit ») exclut aussi `transcendence`, qui exige `raisableRune` ; `:62-77` — `wisdom`, devenue mythique, sort des ensembles de tirables (`tirees` ne garde que le pool `draft`, `:45`) : cinq, puis quatre sans *Affinité*. `draft_screen_test.dart:207-220` : sous `forceLegendary`, chaque mythique sort (`level_up_reward_service.dart:44-47`, `:130-145`) — **six** rouleaux, *Sagesse*, *Trèfle* et *Miroir* en plus des trois, *Transcendance* exclue faute de rune à son plafond dans le deck du test. **La condition, lue par l'écran** (`draft_screen.dart:105-110`), un cas neuf sous `forceLegendary` : un deck portant une rare à `eco:1` donne **sept** rouleaux, *Transcendance* comprise ; la modale liste `eco`, « Niveau maximal 1 → 2 » ; le toucher fait `runeCapBonus['eco']` = 1, notifie `runeCapRaised` et termine le draft. Le même deck après `raiseRuneCap('eco')` — `eco:1` est alors sous son plafond effectif, 2 — redonne six rouleaux, sans *Transcendance* : l'écran lit le deck **et** le bonus de la run | 2 |
| Le catalogue des récompenses | `test/unit/level_up_rewards_catalog_test.dart:64-131` ; `test/unit/level_up_reward_values_test.dart` ; `test/unit/level_up_reward_apply_test.dart:86-95` | Neuf récompenses ; cinq tirables à leurs tables d'aujourd'hui, *Sagesse* hors de `attendu` (et de `_attendu` dans `level_up_reward_values_test`, avec son exception de plateau) ; quatre mythiques, `[wisdom, lucky_clover, mirror, transcendence]` par `displayOrder`, *Sagesse* à `mythic: 1` ; rangs 1 à 9 sans trou ; les cinq tirables atteignables (`level_up_reward_values_test.dart:173`). « Sagesse monte le mana max » (`level_up_reward_apply_test.dart:86-95`) l'applique à `RewardRarity.mythic` : +1, et non plus +4 en légendaire, palier que sa table ne déclare plus | 2 |
| La fiche des probabilités | `test/widget/probabilities_dialog_test.dart` *(nouveau — aucun test n'ouvre la fiche, `git grep -n ProbabilitiesDialog -- test` est vide)* | Le sous-titre de la section « Récompense de niveau » nomme les mythiques de la donnée (§5.1) : le conteneur surcharge le chargeur et le résout avant le premier `pump` (le motif de `draft_screen_test.dart:76-79`). Sur le registre réel, il dit en français « … (Sagesse / Trèfle à 4 feuilles / Miroir / Transcendance) », en anglais « … (Wisdom / 4-Leaf Clover / Mirror / Transcendence) » ; sur un registre dont la seule mythique est une fixture, la parenthèse ne nomme qu'elle — la fiche lit la donnée, et non une liste écrite | 2 |
| Les événements | `test/unit/event_controller_test.dart` | `tradedRelic` : la plus faible, au hasard parmi les ex æquo ; nul sans action `trade_relic`, nul sur un inventaire vide ; `trade_relic` 40 : la relique quitte l'inventaire, son effet `startOfRun` défait, 40 × (rang + 1) or — **céder la *Sacoche du glaneur*** remet `extraCombatCards` à 0, la règle de run défaite par `loseRelic` ; 0 : pas d'or ; `heal_percent`, `lose_hp_percent` : les arrondis ; `sharpen_rune` : la paire montée, aucun or dépensé ; **le bonus de plafond, lu par l'action et sa condition** : sur un deck dont la seule rune est `eco:1`, le choix n'est pas sélectionnable, puis, après `raiseRuneCap('eco')`, il l'est et monte `eco:2` ; `isSelectable` : sans relique, sans rune affûtable, PV ≤ coût — refusés ; **`requiresHpBelowPercent`, lu dans la donnée** : un choix construit à 30, et non aux 50 du fichier livré — sur 100 PV max, 29 PV sélectionnable, 30 refusé —, la même valeur lue par `fromJson`, 0 et 101 refusés ; bornes des valeurs refusées au chargement ; **les deux événements livrés**, sur le registre réel : leurs actions, et la condition `requiresHpBelowPercent: 50` du second choix du *Colporteur* (§3.4) | 2 |
| L'écran d'événement | `test/widget/event_screen_test.dart` *(nouveau — aucun test n'ouvre `EventScreen` aujourd'hui, `git grep -l EventScreen -- test` est vide)* | **Le retour système** (A22), sur le précédent de `rest_screen_test.dart:185-188` : après un choix, `maybePop()` ferme l'écran et le nœud courant est `isCompleted` ; avant tout choix, l'écran reste ouvert ; l'affûtage annulé ne résout rien, les PV ne baissent pas. **Le montage** : `initState` tire, dans une micro-tâche, un événement au hasard parmi `gameData.events`, par `requireValue` (`event_screen.dart:24-29`) — le test résout le chargeur avant le premier `pump` (le motif de `draft_screen_test.dart:76-79`) et lui donne un registre dont `events` ne porte **que** l'événement visé : un `setEvent` posé avant le `pump` serait écrasé, et le registre réel tirerait un événement sur sept. **Les conditions, lues par l'écran** (`event_screen.dart:528`, qui passe la run à `isSelectable`) : une relique portée, le choix des remèdes du *Colporteur* est inactif à PV pleins, actif à 40 % ; le choix du *Rémouleur* est inactif sur un deck sans rune affûtable ; **le bonus de plafond, lu par la condition** : sur un deck dont la seule rune est `eco:1`, le choix du *Rémouleur* est inactif, puis actif après `raiseRuneCap('eco')` — l'écran passe le bonus de la run à `isSelectable`. **Les badges du *Colporteur*** (§4.9, §5.1), en français : avec une seule relique portée, une commune, le badge du premier choix dit « Cède <nom> : +40 Or » et celui du second « Cède <nom> », `<nom>` le nom de la relique dans la locale ; sur un inventaire vide, l'écran s'ouvre sans exception (`tester.takeException()` nul), les deux choix d'échange sont inactifs, et chacun porte le badge « Aucune relique à céder » (deux occurrences). **L'affûtage de bout en bout** : le choix du *Rémouleur*, puis la sélection — les cartes sans rune affûtable grisées —, puis le dialogue, bouton « Choisir », sans coût : la rune monte d'un niveau, 10 % des PV max sont perdus, l'or ne bouge pas | 2 |
| La sélection sans or | `test/widget/rest_card_selection_screen_test.dart` ; `test/widget/sharpen_rune_dialog_test.dart` | En mode sans or : pas de coût, pas de condition d'or, le dialogue n'écrit rien et rend la rune ; le mode du feu inchangé ; le bonus de plafond, lu dans les deux modes, est gardé par « Le bonus de plafond, lu par ses lecteurs » | 2 |
| Les passifs | `test/unit/passive_data_test.dart:144-157`, `:160-220` ; `test/unit/passives_mage_test.dart:59-70`, `:327-356` ; `test/unit/passives_paladin_test.dart:45-56`, `:140-182` | `floor` : lu, refusé avec un `perPoint` positif ou au-dessus de la base ; `withMastery` le respecte. Le groupe `PassiveMastery.describe` (`passive_data_test.dart:144-157`), qui appelle la méthode retirée, passe sur `PassiveData.describeMastery`, qui dit l'écart effectif ; de même le cas `:202-215`, dont l'assertion `:214` (`passive.mastery!.describe('fr', 2)`) passe sur `passive.describeMastery('fr', from: 0, to: 2)` et vaut toujours « -2 Competence a reunir » — ce passif n'a pas de plancher —, et dont le commentaire `:200-201` (« Borner le résultat est l'affaire de la stratégie qui le lit ») est réécrit : le plancher vit dans `withMastery` (A23). *Flux* : le gabarit `manaFlux()` (`passives_mage_test.dart:59-70`) gagne `floor: 2` dans son bloc `mastery`, comme `mana_flux.json` — sans lui, 3 − 2 = 1 et une Compétence suffirait encore ; à Maîtrise 2, **deux** Compétences (le cas `:327-334` réécrit) ; « jamais sous une Compétence » (`:343-356`) devient « jamais sous son plancher » — à Maîtrise 9, une seule Compétence ne donne rien, deux en donnent —, et son commentaire `:336-342`, qui disait le plancher sans effet observable, est réécrit. *Bénédiction* : le gabarit `blessing()` (`passives_paladin_test.dart:45-56`), sans seuil — donc à 0, qui ne soigne plus rien sous A24 —, gagne `threshold: 5`, et les quatre cas `:140-182` gardent leurs attentes ; un cas neuf : une tranche de 4 sur un passif construit à `threshold: 4` ; `threshold: 0`, rien et aucune exception | 2 |
| Les passifs livrés | `test/unit/passives_paladin_test.dart` ou `passives_mage_test.dart`, groupe « le catalogue » | `blessing.json` : `threshold` 5, Maîtrise sur `value`, sans plancher ; `mana_flux.json` : `floor` 2 | 2 |
| Les textes de la Maîtrise | `test/unit/draft_choice_labels_test.dart:57-100` ; `test/unit/level_up_reward_data_test.dart:169-203` ; `test/unit/level_up_rewards_catalog_test.dart:115-116` ; `test/widget/class_selection_screen_test.dart` ; `test/widget/draft_screen_test.dart` ; `test/widget/stats_dialog_test.dart` *(nouveau)* | Les appels existants passent `currentMastery`, devenu requis ; *Affinité* sur *Flux* : l'écart effectif depuis la Maîtrise passée, puis le repli « sans effet » au plancher ; les autres passifs inchangés. **La Maîtrise de la run, lue par l'écran de draft** (`draft_screen.dart:250`, `:343`, `:469`) : un registre dont la seule récompense tirable est *Affinité* — les trois emplacements tirent avec remise parmi les tirables (`level_up_reward_service.dart:119`) —, une run de mage sous *Flux* : à Maîtrise effective 1, les rouleaux disent le repli « … sans effet sur votre passif » ; à 0, « Flux de Mana : -1 Compétence à réunir » — quel que soit le montant tiré, le plancher 2 étant atteint dès le premier point. **La fiche des stats** (`stats_dialog.dart:57-60`), qu'aucun test n'ouvre (`git grep -n StatsDialog -- test` est vide) : *Flux* à Maîtrise 9 dit « -1 Compétence à réunir », et non « -9 » ; à Maîtrise 0, aucune ligne | 2 |

**Les titres suivent les attentes.** Un test existant dont l'attente change prend un titre qui la dit, dans la partie
qui change l'attente ; un cas réécrit (`xp_scaling_test.dart:37-84`, `reward_controller_test.dart:349-374`, `:399-415`)
aussi. Outre ceux que le tableau nomme déjà (`tutorial_engine_test.dart:391`, `passives_mage_test.dart:343`), les
titres qui deviendraient faux sans cela :

| Titre | Aujourd'hui | Devient | Partie |
|:---|:---|:---|:---:|
| `tutorial_engine_test.dart:407` | « le palier suit 100 x 1,5^(niveau-1) » | « le palier est celui de l'acte, à chaque niveau » | 1 |
| `entity_id_convention_test.dart:64` | « il y a bien 88 fichiers d entite » | « … 90 … », puis « … 94 … » | 1, 2 |
| `real_bundle_load_test.dart:24` | « le manifeste declare les 85 fichiers d entite, par categorie » — faux dès aujourd'hui : ses attentes en comptent 88 | « … 90 … », puis « … 94 … » | 1, 2 |
| `encounter_system_test.dart:536` | « calculateBudget includes playerCardsCount in playerPower … » — que la première commande de contrôle désigne aussi | le terme de deck dit par `deckFusionRanks` | 1 |
| `encounter_system_test.dart:563` | « calculateBudget matches the zero-cards, act-1 baseline … » | la base à zéro rang de fusion | 1 |
| `reward_controller_test.dart:127` | « … no relic/cards on a normal combat node » | ni relique ni clone du boss, une carte trouvée | 1 |
| `level_up_rewards_catalog_test.dart:64` | « les huit récompenses se chargent depuis le vrai bundle » | « les neuf … » | 2 |
| `level_up_rewards_catalog_test.dart:74` | « les six récompenses tirables portent la table d aujourd hui » | « les cinq … » | 2 |
| `level_up_rewards_catalog_test.dart:92` | « les deux mythiques sont hors du tirage des trois emplacements » | « les quatre … » | 2 |
| `level_up_rewards_catalog_test.dart:104` | « les huit récompenses portent leurs deux langues » | « les neuf … » | 2 |
| `level_up_reward_values_test.dart:127` | « la table est respectée sur les 30 combinaisons » | « … 25 … » (cinq tirables × cinq paliers) | 2 |
| `level_up_reward_values_test.dart:173` | « les six récompenses tirables sont toutes atteignables » | « les cinq … » | 2 |
| `level_up_reward_requirement_test.dart:62` | « un passif avec Maitrise laisse les six types tirables » | « … les cinq … » | 2 |

**Et les commentaires**, de même : `real_bundle_load_test.dart:70` (« Les deux documents de configuration restent a
plat ») en compte trois avec `xp_curve.json`, en partie 1 ; `level_up_reward_requirement_test.dart:72` (« Les cinq
autres restent ») en compte quatre sans *Sagesse*, devenue mythique, en partie 2.

**Les tests qui suivent sans changer ce qu'ils vérifient**, tous en partie 1 :

- `combat_controller_test.dart:364`, `:511`, `:704` et `:726` passent `GameConstants.maxHandSize` à `startCombat` —
  ils prennent `startingMaxHandSize` ; `passives_berserker_test.dart:233` passe le littéral 10 et ne change pas ;
- **les tests qui lisent le palier sans courbe** (A27) — tous reçoivent une courbe de test, soit en surchargeant
  `xpCurveProvider`, soit en donnant une `xpCurve` au registre qu'ils injectent :
  - qui appellent `gainXp` par `collectGoldAndXp` : `reward_controller_test.dart:388`, `:394`, `:410`, `:427`, `:453`,
    `:478`, `:506` — `xp_scaling_test.dart`, dont « Le palier dérivé » réécrit les cas `:37-84`, n'est pas de ceux-ci ;
    seul son conteneur nu (`:28`) est cité, au piège du montage ;
  - qui montent la barre d'XP de la carte du monde (`HeroMiniStatsPanel`, `map_screen.dart:299`) :
    `test/widget/map_screen_test.dart`, ses cinq conteneurs nus (`:49`, `:115`, `:162`, `:209`, `:276`) ; et
    `test/widget/starter_deck_draft_screen_test.dart`, dont le registre `mockRegistry` (`:192-200`), sans courbe, sert
    à pousser `MapScreen` (`:268-273`, par `starter_deck_draft_screen.dart:118-121`) ;
  - qui ouvrent le menu de debug hors combat, où « Heros » est le premier onglet (`debug_drawer.dart:48`) et lit
    « XP (seuil N) » (`debug_hero_tab.dart:142`) : `test/widget/debug_drawer_test.dart`. La courbe est posée **dans
    `_debugRunContainer` lui-même** (`:126-131`), ce qui couvre tous ses appelants, dont ceux qui ouvrent le tiroir hors
    combat : `:231` (ses onglets, `:244-259`, avec `takeException()` nul), `:296`, `:314`, `:338` — et non cas par
    cas.

**Le piège du montage.** `xpCurveProvider` lit `gameDataLoaderProvider` par `requireValue` (§3.2) : dans un conteneur
où le chargeur n'est pas résolu, la première lecture du palier lève. Deux règles en suivent :

- un **conteneur nu** — `map_screen_test.dart`, `_debugRunContainer`, `reward_controller_test.dart:114`,
  `xp_scaling_test.dart:28` — reçoit la courbe par `xpCurveProvider.overrideWithValue(…)`, qui ne lit jamais le
  chargeur ; lire le provider d'origine lancerait le vrai, `loadGameDataRegistry(rootBundle)`
  (`game_data_service.dart:160-162`), encore en chargement au premier rendu — et `MapScreen`, qui ne lit pas le
  chargeur, monte le panneau dès la première image (`map_screen.dart:299`) ;
- un conteneur dont le **chargeur est surchargé** peut donner la courbe à son registre ; il résout alors le futur avant
  la première lecture du palier, `await container.read(gameDataLoaderProvider.future)` — le motif et le commentaire de
  `draft_screen_test.dart:76-79`. `starter_deck_draft_screen_test.dart` y satisfait déjà : `MapScreen` n'y est poussé
  qu'après le draft (`:268-273`), le chargeur résolu.

`DebugActions.gainLevel` n'a aucun test aujourd'hui (`git grep -n gainLevel -- test` vide) : `debug_actions_test.dart`
gagne le sien en partie 1 — exactement un niveau, au palier de l'acte courant, à l'acte 1 comme à l'acte 9.

**Les commandes de contrôle** — résultat vide attendu à la fin de la vague :

```
git grep -n -e "GameConstants.maxHandSize" -e playerCardsCount -e cardsCount -e rolledBonusCard -e "pow(1.5" -- lib test
git grep -n -e xpToNextLevel -e _armorPerTranche -e "XP & Or x2" -e "2x XP" -- lib test
```

`git grep` distingue la casse : `-e cardsCount` trouve la formule écrite en clair du journal
(`combat_debug_logger.dart:69`), `-e playerCardsCount` le nom du paramètre, que le renommage en `deckFusionRanks` retire
de `calculateBudget`, `generateEnemiesForLevel`, `CombatController.initializeCombat`, `CombatDebugLogger`, de l'appel
de `game_screen.dart:262` et des tests (§3.8) — 22 lignes aujourd'hui.

**Et cinq sur l'écran de combat et la carte du monde**, pour quatre lecteurs qu'aucun test ne monte
(`git grep -n "GameScreen(" -- test` et `git grep -n MapNodeWidget -- test` sont vides) et dont `dart analyze` ne
verrait pas la faute :

```
git grep -n fusionRankSum -- lib/ui/screens/game_screen.dart        # une ligne
git grep -n sharpenedRunes -- lib/ui/screens/game_screen.dart       # au moins une ligne
git grep -n "rewardState.sharpenedRunes" -- lib                     # vide
git grep -n rewardCardFound -- lib/ui/screens/game_screen.dart      # au moins une ligne, dès la partie 1
git grep -n tooltipBossXpDesc -- lib/ui/widgets/map/map_node_widget.dart   # une ligne, en partie 2
```

La première rend l'argument `deckFusionRanks:` de l'appel de la DDA (`game_screen.dart:262` aujourd'hui), qui lit
`ref.read(deckProvider).fusionRankSum` — le paramètre, optionnel à 0 comme `playerCardsCount`
(`combat_controller.dart:49`), laisserait passer un oubli. Les deux suivantes gardent la relecture de §4.6 : la copie
`rewardState` est prise avant `collectGoldAndXp` (`game_screen.dart:95`, `:121`), quand `sharpenedRunes` n'est encore
qu'une liste vide ; la lire là afficherait « aucune rune » à chaque boss « XP ». L'écran relit `ref.read(rewardProvider)`.
La quatrième garde la notification de la trouvaille (§4.1, A10) : oubliée, la carte entrerait au deck sans que rien ne
le dise, et une clé ARB que rien ne lit ne fait rougir ni l'analyseur ni la suite. La cinquième garde la description de
l'infobulle du boss « XP » (§4.6, A25), que la commande sur « XP & Or x2 » ne garde pas : celle-ci prouve que l'ancien
titre est parti, pas que la description a changé — la branche lit aujourd'hui `tooltipBossDesc`
(`map_node_widget.dart:61`).

`dart analyze` propre et suite verte à la fin de chaque tâche, comme chaque lot du programme.

---

## 9. La simulation

Le script lit `assets/data/` (`GameData.load`, `d26_economy_sim.dart:723-899`) ; ses listes se tirent par index
(D73). E3 y crée six fichiers qui doublonnent une entrée en dur : les reliques A, C et D42(a) (`relicD31A`,
`relicD31C`, `relicD42`, `:694-697`, versées en queue de la réserve, `:2506-2510`), les événements de D23 et de D42(b)
(`'d23_relic'`, `'d42b_sharpen'`, `:2976-2982`), et la mythique de D42(c) (le `null` en fin des mythiques,
`:2645-2651`).

**Premier temps — le réalignement seul, une tâche, la dernière de la partie 2 à toucher `assets/data/`.** Valeurs en
dur inchangées ; chaque fichier neuf prend **la place exacte** de son entrée en dur :

- **les reliques** : le chargeur (`:751-763`) écarte de `data.relics` les trois ids neufs ; la réserve garde sa queue
  **A, B, C, D42(a)**. Ce sont **les définitions elles-mêmes**, `relicD31A`, `relicD31C` et `relicD42` (`:694`,
  `:696`, `:697`), qui cèdent la place à des valeurs construites depuis leur fichier, **l'id du fichier compris** —
  `bounty_ledger`, `gleaners_pouch`, `grindstone` à la place de `d31_a_elite`, `d31_c_extra`, `d42_whetstone` —, pour
  que tous leurs lecteurs suivent : la variante `forced` (`:2101`), la réserve (`:2508-2509`), la trouvaille (`:2810`,
  `:2812`), le boss « XP » (`:2832`) et le compte `d31Copies` (`:3311`), par `copies()` (`:2160`). Construites avec
  **`trigger: 'special'`** — le jeu les déclare `startOfRun` : lues telles quelles, l'échange de relique du script les
  céderait (`:3077`) et l'Autel les sacrifierait (`:3149`, `:3161`) —, leur rareté lue et **vérifiée** égale à celle de
  l'entrée en dur (`StateError` sinon), leur effet et leur valeur ceux de l'entrée ; les listes `const` qui les
  rangent (`:2101`, `:2508`) perdent `const`. B reste en dur ;
- **les événements** : le chargeur (`:883-895`) écarte de `data.events` les deux ids neufs ; la liste tirée garde
  `[...data.events, 'd29_fusion', <D23>, <D42(b)>]`, les deux ids neufs aux places de `'d23_relic'` et
  `'d42b_sharpen'`, toujours résolus par `_eventRelicTrade` et `_eventSharpen` ;
- **la mythique** : le chargeur (`:765-778`) écarte de `data.rewards` l'id `transcendence` ; elle prend la place du
  `null`, **en dernier** (`:2647-2651`), et les tests qui reconnaissent le `null` (`:2664`, `:2675`) la reconnaissent
  par son id ;
- un fichier de relique, d'événement ou de récompense dont l'id joue une entrée du brainstorm sans y être rangé lève
  une erreur, comme la liste d'ordre des runes (`:847-850`) ;
- les commentaires qui citent du code qu'E3 change sont rafraîchis, sans toucher au calcul : `:41`
  (`const maxHandSize = 10; // game_constants.dart:36`, devenu `startingMaxHandSize` et `RunState.maxHandSize`),
  `:145` et `:2593` (`player_stats_manager.dart:127`, la formule géométrique qu'E3 supprime — ils la disent « la courbe
  d'avant E3 ») ; `:49` (`nodeQuotas`, `game_constants.dart:25-31`, que le `typedef CardDropRule` posé au niveau du
  fichier décale) et `:2571` (`player_stats_manager.dart:239-303 et :435-455`, les plages d'`applyRelicEffect` et de
  `removeRelicEffect`, qui gagnent trois `effectType` — la seconde, `:438` aujourd'hui, dérive déjà), recalés sur les
  plages d'après E3. Les autres renvois du script vers le code (une quarantaine) ne sont pas recalés : beaucoup dérivent
  déjà avant E3 (`passive_strategies.dart:146`, `:2155`, désigne une ligne aujourd'hui en `:148`), et les recaler tous
  sortirait du réalignement.

Le chargeur du script lit `j['id'] as String` dans chaque fichier, avant toute exclusion (`:756`, `:770`, `:887`) :
les six fichiers neufs **déclarent leur `"id"`** (§3.3 à §3.5), sans quoi la simulation plante.

Rien d'autre ne change ce que le script lit : `wisdom.json` (`values.mythic` 1 = le défaut `?? 1`, `:2655`, `:2660`),
`blessing.json` et `mana_flux.json` (§1.3), `binary` (non lu, `:844-875`) et `xp_curve.json` (non lu au premier temps)
laissent la sortie identique ; les reliques A et C, ajoutées en partie 1, ne doublonnent dans le script qu'entre les
deux parties, où aucune relance ne tourne.

**L'écart attendu : aucun.** La ligne « Données lues » (`:3873-3877`) écrit `data.relics.length` (25), « (+ 4 du
brainstorm) », `data.rewards.length` (8), `data.runes.length` (17), `data.events.length` (5) et « (+ 3 du
brainstorm) » : les fichiers neufs écartés de ces listes, elles gardent leurs longueurs. **Diff entièrement vide**
contre `tool/simulations/d26_reference_output.md`, ligne « Données lues » comprise (§1.3). La tâche se fume par
`--quick` : même empreinte que la fumée lancée sur l'état de la base de la vague, extrait par
`git archive 9282513 tool/simulations assets/data` — avant la tâche, les fichiers neufs doublonnent, et la fumée sur la
branche n'est plus un témoin.

**Second temps — trois tâches, une par changement voulu, après le réalignement (A28)** ; chacune un commit du script,
fumé par `--quick`. **L'orchestrateur** relance chaque commit à part, explique l'écart au compte rendu et recommite la
référence — aucune tâche du plan ne le fait :

1. **La relique B retirée** (D57) : `relicD31B` (`:695`) quitte la réserve (`:2508`) et la variante `forced`
   (`:2101`), `relicBPerCopy` et ses deux jets (`:2814`, `:2816`) disparaissent, ainsi que la variante « B +2 % par
   exemplaire » (`:3683`) ; B sort du compte `d31Copies` (`:3311`) ; la variante de référence « **A +25 %, B +1 %,
   dans la réserve** (réf.) » (`:3680`) devient « A +25 %, dans la réserve » ; « A, B, C tenues dès l'acte 1 »
   (`:3684`) devient « A et C » ; « (+ 4 du brainstorm) » devient « (+ 3 ») ;
2. **l'événement de D29 retiré** (D56) : `'d29_fusion'` quitte la liste (`:2978`), avec `_eventFusion`
   (`:3055-3070`) et sa ligne de sortie si elle ne compte plus rien ; « (+ 3 du brainstorm) » devient « (+ 2 ») ;
3. **la table d'XP lue dans la donnée** : la référence prend `xpTable` de `assets/data/xp_curve.json`
   (`xpPerLevelByAct`) au lieu de la table calée (`ref = t2`, `:3842`) ; **la calibration reste affichée** (`:3880-3887`),
   ses variantes « 3 niv./acte » et « palier constant » restent calées. La ligne « Table par acte (réf.) » (`:3883`), qui
   désigne `t2`, devient « Table par acte, calée », et une ligne « Table par acte (réf., `xp_curve.json`) » écrit la
   table lue : la sortie recommitée, que la vague suivante relira, dit laquelle sert de référence. Écart attendu non
   nul : la référence joue aujourd'hui la table recalée après la vague 2 (§1.3), à −25 à +40 XP de D67 selon l'acte.

**L'ordre et le lieu des relances** — ceux de la vague 2 (spec E2, §9, n° 9) : la relance du premier temps tourne sur
le commit de réalignement, extrait **hors du dépôt** par `git archive <commit> tool/simulations assets/data` dans le
dossier temporaire de la session ; chaque relance du second temps sur son commit, de même. Les tâches du second temps
sont **les dernières à toucher le script**, et aucune tâche qui touche `assets/data/` ne vient après le réalignement.
**Aucune tâche du plan ne lance la mesure complète** : le plan réaligne et fume par `--quick` ; l'orchestrateur relance.

**Les écarts du script, consignés et non relancés** — aucun n'est une valeur qu'un arbitrage d'E3 remplace :

| Écart | Où | Pourquoi pas de relance |
|:---|:---|:---|
| L'échange de relique ne cède rien sous trois reliques, ni une relique du brainstorm | `:3077-3078` | Politique du joueur simulé (A2) |
| L'Autel ne sacrifie jamais une relique du brainstorm | `:3149`, `:3161` | Politique : le joueur choisit ce qu'il sacrifie (§4.9) |
| L'événement d'affûtage refusé sous 30 % des PV, sauf au Berserker *Sang* ; une marge d'un PV | `:3096` | Politique ; le jeu applique la règle de `take_damage` (§4.9) |
| L'échange : PV sous 50 %, or sinon | `:3083-3087` | Politique : le jeu offre les deux sous la moitié des PV, l'or seul au-dessus (A2) |
| *Sagesse* prise d'office quand elle est offerte ; la mythique de D42(c) prise sur la rune la plus fréquente | `:2669-2693` | Politique : le joueur choisit (A15) |
| Le script sort les signatures du deck (D49) ; le jeu les y garde jusqu'en `0.5.6` | — | Rang 0 pour la DDA, hors de la trouvaille : sans effet sur ce que la mesure compte (§4.13) |
| Le script gagne la relique d'élite avant de tirer les cartes de la même élite — un *Registre des primes* compte dès sa propre élite —, et, au boss « XP », résout la montée de niveau, récompense prise sur-le-champ, *Transcendance* comprise, avant l'affûtage ; le jeu fait l'inverse : `handleVictory` tire les cartes à la victoire, avant le carrousel de la relique, et l'affûtage se fait dans `collectGoldAndXp`, quand le draft de niveau attend la carte du monde (`game_screen.dart:97-121` ; `pendingDrafts`, `player_stats_manager.dart:139`) | `:2808-2812` ; `:2829-2834` (`rewardFoes` → `gainXp`, `:2794`, → `levelUp`, `:2603`, puis `sharpenRandom`) | Ordre de modélisation, pas une politique du joueur, et sans effet mesurable : A est indiscernable de 15 à 50 % (D57), une mythique sort à 0,5 % par niveau (D62) ; le jeu garde son ordre |

**Ce qu'E3 confirme de ce que le script joue** : une carte garantie en combat, une garantie et 25 % en élite
(`:2809-2822`) ; A à +25 points par exemplaire, C à +1 par exemplaire ; le boss « XP » sans carte, `1 + exemplaires`
runes tirées parmi les paires sous leur plafond (`:2831-2834`, `:2450-2463`) ; la relique la plus faible contre
40 × (rang + 1) or, 20 % des PV max sous 50 % (`:3072-3089`) ; +1 niveau contre 10 % des PV max (`:3091-3100`) ; un jet
par mythique, *Sagesse* à +1 (`:2645-2663`) ; le bonus de plafond par type pour la run (`:2163-2166`) ; k = 2
(`deckTerm`, `:2171`) ; la table par acte, dernière valeur répétée (`:2592`).

---

## 10. Le découpage en parties

**L'invariant** : chaque partie laisse le jeu jouable, `dart analyze` propre et `flutter test` vert ; une partie ne
supprime un champ qu'avec son dernier lecteur, et n'écrit aucun code que la suivante jetterait ; un test qui garde un
comportement encore vivant n'est réécrit que dans la partie qui change ce comportement (spec E2, §10, tranché par
l'orchestrateur de la vague 2).

**Partie 1 — la boucle** : ce que la run gagne à chaque combat, et ce qu'elle en mesure.
- la trouvaille : `cardDrops`, `CardDrops.roll`, `foundCards`, sa notification `rewardCardFound`, **à côté** de celle
  de la carte bonus, qui reste jusqu'en partie 2 ; les reliques A et C, les deux champs
  de `RunState` qu'elles écrivent (`extraCombatCards`, `eliteCardChanceBonus`), leurs `effectType` symétriques — le
  troisième champ, `extraBossRuneSharpens`, vient en partie 2 avec la *Meule*, son seul écrivain ;
- `maxHandSize` : la stat, `startingMaxHandSize`, les six chemins, le champ de debug, `hand_size_bound_test` ;
- la courbe d'XP : `xp_curve.json`, `XpCurveData`, `loadDocument`, le registre, `xpCurveProvider`, `gainXp`, la
  suppression d'`EntityStats.xpToNextLevel` et de ses lecteurs, le tutoriel (moteur et prose XP), `CLAUDE.md` ;
- la DDA : `fusionRankSum`, `deckFusionRanks`, le journal de debug ;
- la prose du tutoriel pour le combat et l'élite (§5.3) ; l'infobulle d'élite, `tooltipEliteDesc`, réécrite (§5.1) ;
- `signature_cards_transition_test`, sans sa clause du boss « XP ».

*Entre les deux parties* : le boss « XP » donne encore sa carte bonus, et sa notification la nomme, en plus de l'XP et
de l'or triplés ; jouable, jamais livré ainsi — la vague sort en une version.

**Partie 2 — les sources** : ce qui monte une rune, échange une relique, ou relève un plafond.
- `DeckNotifier.raiseRuneLevel` et `GoldManager.sharpenRune` qui l'appelle (§4.7) ;
- `binary`, `RunState.runeCapBonus`, le `capBonus` de tous ses lecteurs, `raisableCaps`, `sharpenablePairs`,
  `nameAt` (§4.8) ;
- le boss « XP » : la carte bonus, `rolledBonusCard` et la notification de la carte bonus (`game_screen.dart:129-135`)
  supprimées, l'affûtage aléatoire,
  `GameConstants.bossXpRuneSharpens`, `extraBossRuneSharpens`, `sharpenedRunes`, la relique D42(a), l'infobulle, la
  prose du tutoriel (§4.6, §5.3) ;
- les deux événements, les actions neuves, `tradedRelic`, `loseRelic`, les badges — `eventNoRelicToGive` sans relique
  visée —, la sélection sans or, le retour système (§4.9, §5.1) ;
- *Sagesse* et *Transcendance* : les deux fichiers, `raiseRuneCap`, `raisableRune`, la modale (§4.8, §4.10) ; la
  documentation d'`inPool` réécrite (§3.8) ; la fiche des probabilités, qui nomme les mythiques depuis la donnée par
  `luckLevelRewardSubtitle` (§5.1) ;
- les seuils : `threshold` de *Bénédiction*, `floor` de *Flux*, `describeMastery` et ses trois lecteurs (§4.11) ;
- la simulation : le réalignement (premier temps), puis les trois tâches du second temps (§9) — les dernières de la
  vague.

**Pourquoi cet ordre.** La partie 1 change la boucle et ce qu'elle mesure — elle ne dépend de rien de la partie 2 —, et
la partie 2 s'écrit sur elle : le boss « XP » perd sa carte quand la trouvaille existe déjà, et ses tirages lisent les
paires d'une run qui fusionne. **Corrections à la proposition de la fiche** : aucune sur le partage ; la clause du boss
« XP » du test de transition suit le boss en partie 2 ; `raiseRuneLevel` et le bonus de plafond ouvrent la partie 2,
parce que ses trois sources et la mythique en ont besoin, et `GameConstants.bossXpRuneSharpens` y vient avec son seul
lecteur ; le réalignement du script vient en dernier, après le dernier fichier de donnée (spec E2, §10). C'est
l'option (c) d'A7, retenue par le filtre 5.

---

## 11. Documentation et livraison

**Pour `memory-bank-sync`**, à la fin de la vague :

| Quoi | Contenu |
|:---|:---|
| Un ADR neuf, « trouvaille et progression » (ADR-107, si le numéro est libre) | A1 à A28. Il **amende ADR-078 D3** : `maxHandSize` devient une stat de run (D25) ; la « pioche infinie » n'est pas reproduite — le testeur a vu le cyclage, ou joué une version antérieure à la borne — et la borne tient sur les six chemins, chacun gardé par un test. Il **complète** ADR-096 (`floor` dans le bloc `mastery`, appliqué par `withMastery`) ; ADR-097 D3 (la tranche de *Bénédiction* en donnée) ; ADR-098 (neuf récompenses, cinq tirables, *Sagesse* mythique sans son plateau, l'effet `raiseRuneCap`) ; ADR-099 D1 (une seconde exigence, `raisableRune`, et `isAvailableWith` qui reçoit `hasRaisableRune`, calculé par l'écran de draft sur le deck) ; ADR-101 (la trouvaille, lecteur d'`isOfferableTo` à la place de la carte bonus) ; ADR-105 D7 et ADR-106 (`boundLevel` et ses lecteurs gagnent le bonus de plafond ; `nameAt` ; `raiseRuneLevel` partagé par le feu et les trois sources) — chacun ne change que de Statut |
| `_rules/01-00` | Les récompenses de combat : une carte en combat, une ou deux en élite (`:32`) |
| `_rules/02-6` | La formule de `PlayerPower` (`:7-8`) : 2 × Σ `fusionRank` |
| `_rules/02-1` | Le boss « XP » n'octroie plus de carte ; une rune monte (`:47`) |
| `_rules/03-4` | La main : `RunState.maxHandSize`, plus `GameConstants.maxHandSize` (`:35-36`) |
| `_rules/08-00` | Le tutoriel : le palier d'XP, les nœuds |
| `_patterns/02-1` | Le palier d'XP dérivé de l'acte (`:13`), les règles de run, `runeCapBonus` |
| `_patterns/20-00` | Ce que le script lit : reliques, événements et mythique du brainstorm depuis leurs fichiers ; B et D29 retirés ; la table d'XP du jeu |
| À relire, que le diff peut périmer | `_rules/03-5` (reliques), `03-6` (événements), `03-8` (l'affûtage hors du feu, le bonus de plafond, `binary`), `03-10` (le draft : *Sagesse*, *Transcendance*), `03-13` (les champs de `RunState`), `06-00` (économie), `07-00` (`xp_curve.json`), `02-2` (*Bénédiction*, *Flux*) ; `_patterns/02-3`, `02-4`, `02-8`, `03-1`, `03-3`, `03-5`, `09-00`, `10-00`, `11-00`, `17-00` (`loadDocument`), `18-00` (debug) |

`CLAUDE.md` change de deux lignes — l'arbre de `assets/data/` nomme `xp_curve.json` parmi les documents plats, et la
rubrique « Data layer » nomme `xp_curve_data.dart` parmi les modèles —, dans une même tâche du plan de la partie 1
(§3.2). Pas de lien dans `docs/ROADMAP.md` ni de note de version propre au lot : la note est celle de
la vague, écrite à sa fin.

**Ce que le joueur voit en `0.5.5`** — la note la plus longue du chantier :
- **une carte après chaque combat** : tirée parmi les cartes que votre classe peut recevoir, commune, elle entre dans
  votre deck ; **en élite, une seconde à 25 %** ; deux reliques rares en ajoutent — le *Registre des primes* (+25 % de
  seconde carte en élite) et la *Sacoche du glaneur* (une carte de plus en combat normal) ; **les fusions deviennent
  fréquentes** ;
- **deux niveaux par acte** : le prix d'un niveau dépend de l'acte — 115 XP à l'acte 1, 200 à l'acte 2… ;
- **le boss d'XP ne donne plus de carte** : avec le triple d'XP et d'or, une rune de votre deck gagne un niveau — deux
  avec la *Meule*, relique légendaire ;
- **un événement, le Rémouleur**, monte une rune d'un niveau contre 10 % de vos PV max ;
- **une récompense mythique, *Transcendance***, relève de 1 le niveau maximal d'un type de rune, sur toutes vos
  cartes, pour toute la run — *Économe* ou *Véloce* au niveau 2 deviennent possibles ;
- **un événement, le Colporteur**, vous prend votre relique la plus faible contre de l'or — ou, sous la moitié de vos
  PV, contre des soins ;
- **la difficulté lit la force de votre deck, et non plus sa taille** : des cartes trouvées ne rendent plus les combats plus
  durs ;
- ***Sagesse* (+1 Mana max) devient une récompense mythique** ;
- *Flux de Mana* : la Maîtrise abaisse son seuil, jamais sous 2 Compétences ; l'effet affiché de la Maîtrise dit
  désormais ce qu'elle change vraiment ;
- **trois corrections** : l'infobulle du boss d'XP disait « x2 » — c'est le triple ; à un événement, quitter l'écran par
  le retour après avoir choisi termine la visite — on ne peut plus rejouer un événement dans le même nœud ; le nom d'une
  rune montée au-delà de son niveau maximal d'origine affiche son niveau.

---

## 12. Alternatives écartées

Les options écartées par chaque arbitrage sont en §1.2 avec leur motif ; ne restent ici que les idées qui ne sont pas
des options d'un arbitrage.

| Idée | Motif |
|:---|:---|
| **Un écran de choix de carte après le combat** (une parmi trois) | D1 : tirage uniforme, sans refus — « pas de contenu sans décision » vaut pour nous, pas pour le joueur |
| **La trouvaille tirée parmi les cartes du deck, comme les clones du boss** | D1 : « dans le pool accessible à la run » ; les doublons ciblés sont la boutique et les Miroirs |
| **Garder le palier géométrique comme repli quand la table manque** | Un second fait sur le même sujet ; le chargement échoue si `xp_curve.json` manque (§3.2) |
| **Recaler la table d'XP sur la mesure de la vague 2** | D67 est une valeur mesurée et acquise (filtre 2) ; le recalage est un sujet de P-16 (D58) |
| **Une relique « +2 en main » livrée avec la stat** | P1, et le script en tirerait une relique de plus (A11) |
| **Retirer `focus` du pool de la trouvaille** | Le catalogue ne change pas en E3 (D28 : supprimée en tranche 1) |
| **Ouvrir *Transcendance* aux runes sans plafond** | Rien à relever ; et le script ne le joue pas |
| **Un plancher sur *Bénédiction*** | D60 : le plancher ne vaut que pour *Flux* |
| **Une étape de migration de sauvegarde** | Rien à migrer ; les sauvegardes ne se transfèrent pas avant la `1.0.0` (§7) |

---

## 13. Vérification

Écrit par l'orchestrateur de la vague 3, complété à la correction du troisième tour, puis au quatrième. Quatre tours
de vérification, chacun par un panel neuf — trois vérificateurs indépendants, un par angle (le code ; les décisions et la fiche ; les
transitions, les tests, le découpage et la simulation), puis un consolidateur qui rend une seule table. Après le
premier tour et après le deuxième, deux corrections par le rédacteur, repris avec son contexte ; après le troisième,
l'arrêt, puis sa levée et une correction par un correcteur neuf. Les arbitrages sont tous en §1.2 : A1 à
A28, les deux tableaux « Tranchés par l'orchestrateur » des deux premières corrections, puis, pour la troisième, le
tableau « Tranchés par le propriétaire » et celui des questions qu'elle a fait apparaître (C3.1, C3.2).

| Tour | Constats | Suite |
|:---|:---|:---|
| 1 | 6 moyens, 13 mineurs, 3 de rédaction | Corrigés ; A8 à A28 confirmés, A1 et A7 reconsignés ; quatre arbitrages de la correction confirmés (`sharpenedRunes` nullable, `currentMastery` requis, `binary` toujours écrit, A7 par le filtre 5) |
| 2 | 2 moyens (aucun test ne reliait les reliques A et C à la trouvaille ; `loadDocument` sans `cache: false`), 10 mineurs, 3 de rédaction | Corrigés, avec une passe ciblée sur les liaisons non testées et les pièges de test ; six arbitrages de la correction confirmés |
| 3 | **3 moyens**, 8 mineurs, 2 de rédaction | **Non corrigés à l'arrêt : la troisième vérification qui rend un constat moyen arrête la vague** (orchestration §3.3, §6). L'arrêt levé par le propriétaire le 03/10, les treize corrigés (ci-dessous) |
| 4 | **2 moyens**, 9 mineurs, 1 de rédaction — les trois vérificateurs rendent « prête » ; le consolidateur, qui vérifie lui-même chaque constat qu'il garde moyen, en remonte deux de mineur à moyen | **Non corrigés : la levée n'autorisait la suite que sur un « prête »** — la vague s'arrête de nouveau (ci-dessous) |

**Les constats du tour 3**, tels que le consolidateur les a rendus — preuves relues sur `9282513` ; les lignes sont
désignées par section, celles du code et du script par `fichier:ligne`. Ces dernières sont celles du vérificateur ;
la correction les a re-mesurées là où elle les écrit. La colonne « Suite » dit où chacun est corrigé :

| # | Gravité | Où | Constat | Correction proposée par le vérificateur | Suite |
|:---|:---|:---|:---|:---|:---|
| 1 | **moyen** | §8, « La transition E3 → E4 » et « La trouvaille dans la récompense » ; §4.1 | Les deux tests qui gardent « pas de signature dans la trouvaille » lisent la rareté de l'**instance** trouvée ; or §4.1 la construit par `CardInstance(data: c, rarity: CardRarity.common)`, et la rareté passée remplace celle de la donnée (`card_instance.dart:14-17`) : l'assertion vaut toujours vrai, même sur un pool construit sans `rarity.isAcquirable` (`card_data.dart:170-173`). Le test exigé par la fiche ne garderait rien | La clause lit la donnée : aucune carte trouvée dont `card.data.rarity` vaut `unique`, ni dont `card.data.heroClass` est une autre classe — ou aucun `card.data.id` parmi les six signatures du registre ; l'assertion « toutes communes » sur `card.rarity` reste | Corrigé, les deux formes ensemble — §4.1 ; §8, « La trouvaille dans la récompense » et « La transition E3 → E4 » ; §1.2, propriétaire n° 1 et C3.1 |
| 2 | **moyen** | §8, « Le bonus de plafond, lu par ses lecteurs », « L'écran d'événement », « La sélection sans or » ; §4.8, §4.9 | La sélection d'affûtage (`rest_card_selection_screen.dart:118-119`, `:44-49`) lit le bonus de plafond — elle grise et refuse une carte sans rune affûtable —, et la condition du *Rémouleur* passe par `event_screen.dart:528` ; aucun cas ne prouve qu'elles lisent `RunState.runeCapBonus`, et `capBonus` n'est pas requis (A17) : un oubli laisserait la suite verte, et *Transcendance* sans effet au feu comme à l'événement | Sur le modèle de `rest_card_selection_screen_test.dart:86` : un deck dont la seule rune est `eco:1` — carte grisée et refusée, puis, après `raiseRuneCap('eco')`, dialogue ouvert sur « Niveau 1 → 2 », dans les deux modes (avec or, sans or) ; et le choix du *Rémouleur* inactif sur ce deck, puis actif après `raiseRuneCap('eco')` | Corrigé — §4.8 (« L'affûtage au feu ») ; §4.9 (« Le choix de la rune ») ; §8, « Le bonus de plafond, lu par ses lecteurs », « L'écran d'événement », « La sélection sans or » ; partie 2 |
| 3 | **moyen** | §8, commandes de contrôle « sur l'écran de combat » ; §4.1, A10 ; §4.6, A25 | Deux lecteurs neufs d'écrans qu'aucun test ne monte n'ont ni test ni commande : la notification `rewardCardFound` de `GameScreen` (partie 1) — oubliée, la carte entre sans que rien ne le dise, ce qu'A10 écarte — et la description `tooltipBossXpDesc` de `map_node_widget.dart:61` (partie 2), que la commande sur « XP & Or x2 » ne garde pas | Deux commandes de plus : `git grep -n rewardCardFound -- lib/ui/screens/game_screen.dart` (au moins une ligne, partie 1) et `git grep -n tooltipBossXpDesc -- lib/ui/widgets/map/map_node_widget.dart` (une ligne, partie 2) | Corrigé — §8, commandes de contrôle (cinq sur l'écran de combat et la carte du monde) ; §4.1 ; §4.6 |
| 4 | mineur | §8, première commande ; §3.8 `EncounterSystem` | La correction du tour 2 a remplacé `playerCardsCount` par `cardsCount` ; `git grep` distingue la casse : la commande ne garde plus le renommage de `combat_controller.dart:49`, `:62`, `:103`, `:116`, `encounter_system.dart:220`, `:235`, `game_screen.dart:262` | `-e playerCardsCount -e cardsCount` | Corrigé — §8, première commande |
| 5 | mineur | §4.9, §5.1, §8 « L'écran d'événement » ; A20 | Le badge `trade_relic` sans relique visée n'est pas fixé (`tradedRelic` est nul sur un inventaire vide, le cas courant à l'acte 1) ; le test d'écran ne vérifie ni le nom ni le montant affichés | Fixer le badge sans relique visée ; deux cas : une commune portée — « Cède <nom> : +40 Or » et « Cède <nom> » ; un inventaire vide — l'écran s'ouvre sans exception, les deux choix d'échange inactifs | Corrigé, le badge `eventNoRelicToGive` — A20 ; §4.9 ; §5.1 ; §8, « L'écran d'événement » ; §10 ; §1.2, propriétaire n° 5 |
| 6 | mineur | §9, table des écarts consignés | Le script gagne la relique d'élite avant de tirer les cartes de la même élite (`d26_economy_sim.dart:2808-2812`) et résout la montée de niveau du boss « XP » avant son affûtage (`:2829-2832`) ; le jeu fait l'inverse (`game_screen.dart:97-121`, `pendingDrafts`). Effet indiscernable (D57, D62), mais l'écart n'est pas une politique du joueur et n'est pas consigné | Une ligne de plus à la table des écarts, sans relance : ordre de modélisation, sans effet mesurable | Corrigé — §9, table des écarts consignés (le boss « XP » re-mesuré `:2829-2834`) |
| 7 | mineur | §5.1 | La fiche des probabilités nomme les mythiques en dur, « (Trèfle / Miroir) » (`probabilities_dialog.dart:244-245`) : faux dès que *Sagesse* et *Transcendance* sont mythiques | La remplir depuis `LevelUpRewardData.inPool(rewards, RewardPool.mythic)`, ou la retirer, ou la consigner hors d'E3 au §5.4 | Corrigé, remplie depuis la donnée par `luckLevelRewardSubtitle` — §3.8 ; §5.1 ; §8, « La fiche des probabilités » ; §10 ; §1.2, propriétaire n° 7 et C3.2 |
| 8 | mineur | §5.1, §5.4 ; §5.3 | L'infobulle d'élite (`tooltipEliteDesc`, `app_fr.arb:60`, `app_en.arb:105`) ne dit que la relique, quand le tutoriel dira « une Relique et une carte — parfois deux » | La réécrire en partie 1 : « Un combat bien plus rude : une relique garantie, et une carte — parfois deux. » / "A much tougher fight: a guaranteed relic, and a card — sometimes two." | Corrigé, en partie 1 — §5.1 ; §10 ; §1.2, propriétaire n° 8. §5.4 ne la nommait pas |
| 9 | mineur | §3.8 `LevelUpRewardData` | La documentation d'`inPool` (`level_up_reward_data.dart:175-177`) dit « exactement six tirables » ; il en reste cinq | La faire réécrire | Corrigé, en partie 2, avec ses « deux lecteurs » devenus trois — §3.8 ; §10 |
| 10 | mineur | §3.8 `DeckNotifier`, `ForgeUpgradeData`, `ForgeRuneRules` ; A17 | La spec ne dit pas que `capBonus` est **optionnel**, avec un défaut, sur `consolidate`, `canSharpen`, `hasSharpenableRune`, `wellLevel`, `boundLevel` et `mergeCards` ; requis, il casserait 36 appels de test qu'aucune ligne du §8 ne nomme | Écrire les signatures : `{Map<String, int> capBonus = const {}}`, `{int capBonus = 0}` sur `boundLevel` | Corrigé — A17 et son récapitulatif ; §3.8, `DeckNotifier`, `ForgeUpgradeData`, `ForgeRuneRules` |
| 11 | mineur | §8 ; §4.9 | Quatre références voisines de la bonne | `level_up_reward_requirement_test.dart:45`, `forge_upgrades_catalog_test.dart:239-258`, `rest_screen.dart:139-142`, `rest_screen_test.dart:185-188` | Corrigé — §8, « La mythique », « Les runes livrées », « L'écran d'événement » ; §4.9, « Le retour système » |
| 12 | rédaction | §8, « Les tests qui suivent sans changer » | `xp_scaling_test.dart:45`, `:59`, `:76` y sont rangés alors que « Le palier dérivé » réécrit `:37-84` | Les retirer de cette liste | Corrigé — §8, « Les tests qui suivent sans changer » |
| 13 | rédaction | §8 | Des titres de tests existants deviennent faux (`tutorial_engine_test.dart:407`, `entity_id_convention_test.dart:64`, `level_up_rewards_catalog_test.dart:64`, `:74`, `:92`, `:104`, `level_up_reward_values_test.dart:173`, `level_up_reward_requirement_test.dart:62`) | Dire que les titres suivent les attentes | Corrigé — §8, « Les titres suivent les attentes », avec cinq titres de plus trouvés à la re-mesure |

**Aucun constat n'exige d'amender une décision acquise, ni ne change une valeur mesurée** : les trois moyens sont des
trous de test.

**La levée de l'arrêt (03/10).** Le propriétaire a levé l'arrêt en acceptant les recommandations de l'orchestrateur :
pour les n° 1 à 4, 6 et 9 à 13, les corrections du vérificateur telles quelles — le n° 1 sous ses deux formes
ensemble ; pour les n° 5, 7 et 8, les options que l'orchestrateur retenait. Les treize constats sont corrigés par un
correcteur neuf, qui n'a pas écrit la spec ; la colonne « Suite » dit où. Les arbitrages du propriétaire sont en
§1.2, comme les deux questions que la correction a fait apparaître (C3.1, C3.2), tranchées par l'arbre de décision et
soumises à la relecture de l'orchestrateur. Le propriétaire demande ensuite un quatrième tour de vérification, par un
panel neuf.

### Le quatrième tour — état à l'arrêt (03/10/2026)

Un panel neuf, de même forme, qui a reçu tous les arbitrages de §1.2 (A1 à A28, C1, C2, la levée de l'arrêt, C3) et les
tables des trois tours. **Les trois vérificateurs rendent « prête »** (4, 5 et 5 constats, aucun moyen) ; le
consolidateur fusionne les doublons, vérifie par une commande chaque constat qu'il garde moyen, et **remonte deux
constats de mineur à moyen** — tous deux trouvés par le vérificateur des tests et du découpage, qui les classait
mineurs. Son verdict, « à corriger », est celui du tour, comme aux trois premiers ; l'orchestrateur a relu les deux
moyens sur le code et le texte, ils sont exacts. **La levée n'autorisait la suite du cycle que sur un « prête »** : la
vague s'arrête de nouveau, constats non corrigés. Les lignes « l. » sont celles de la spec à ce commit.

| # | Gravité | Où | Constat | Correction proposée par le consolidateur |
|:---|:---|:---|:---|:---|
| 1 | **moyen** | §8, « Le journal de debug » (l. 1161) contre la première commande de contrôle (l. 1240-1247) | L'assertion d'absence prévue dans `combat_debug_logger_test.dart:28` (« plus … cardsCount ») écrit le littéral `cardsCount` dans `test/` ; la première commande cherche `-e cardsCount` dans `lib test` et attend un résultat vide, et `git grep` distingue la casse : la barrière de fin de vague ne peut pas être vide | Sortir `-e cardsCount` dans une commande à part, limitée à `-- lib`, résultat vide ; garder `-e playerCardsCount` sur `lib test` — ou dire que la seule ligne attendue est l'assertion d'absence |
| 2 | **moyen** | §8, « Le catalogue des récompenses » (l. 1171), `level_up_rewards_catalog_test.dart:64-131`, partie 2 | La ligne donne l'ordre neuf des mythiques, `[wisdom, lucky_clover, mirror, transcendence]`, sans dire ce que deviennent `:101` (`mythiques.last.effect` attendu `cloneCard` — `last` devient *Transcendance*, `raiseRuneCap`) ni `:68-71` (l'ensemble `{...attendu.keys, 'lucky_clover', 'mirror'}` perd `wisdom` et n'a pas `transcendence` : sept ids pour neuf récompenses) : la suite resterait rouge | `:100-101` lisent les mythiques par id — *Sagesse* et *Trèfle* à `amountFor(mythic)` 1, *Miroir* à `cloneCard`, *Transcendance* à `raiseRuneCap` ; l'ensemble de `:68-71` gagne `wisdom` et `transcendence` |
| 3 | mineur | §8, « Et les commentaires » | La liste des commentaires qu'E3 rend faux se dit complète et n'en nomme que deux ; dix autres deviennent faux — partie 1 : `entity_id_convention_test.dart:21`, `tutorial_engine.dart:510-511`, `tutorial_engine_test.dart:417` ; partie 2 : `passive_data.dart:133`, `passive_strategies.dart:136`, `level_up_reward_service.dart:27-28`, `player_stats_manager.dart:74`, `level_up_reward_data.dart:45-49`, `level_up_rewards_catalog_test.dart:16-18`, `draft_screen_test.dart:35-38` et `:194-196` | Compléter la liste, chaque ligne dans sa partie ; ou une règle générale : tout commentaire ou documentation que le lot rend faux est réécrit dans la partie qui le rend faux |
| 4 | mineur | §9, premier temps, les commentaires rafraîchis ; second temps, relance 3 | Quatre commentaires du script relèvent du critère que la puce pose et n'y sont pas — `:156-157` et `:1189-1191` (la DDA « actuelle », cartes × 2), `:2646` (*Sagesse* « sans valeur `mythic` en donnée »), `:2155` (la tranche de 5, rangé à tort parmi les dérives) ; et trois libellés imprimés, `:2046`, `:3733`, `:3745`, appelleront « actuelle » dans la référence recommitée ce que le jeu n'a plus | Rafraîchir les quatre commentaires au premier temps ; garder les trois libellés au premier temps (diff vide) et les renommer « d'avant E3 » dans la relance 3, l'écart de libellé expliqué au compte rendu |
| 5 | mineur | §3.8, `LevelUpRewardData` (l. 747) | La documentation d'`inPool` réécrite garde « ce qui préserve le tirage d'origine », faux dès que D11 change ce tirage | Réécrire la parenthèse entière : « le tirage est uniforme parmi les tirables, cinq depuis que *Sagesse* est mythique (D11), compte verrouillé par un test » |
| 6 | mineur | §5.1, `tooltipBossXpDesc` (l. 1046) ; §5.3 (l. 1092, l. 1095) ; §11 (l. 1455-1456) ; A5 | Trois textes joueur promettent sans condition qu'une rune monte au boss « XP », quand A5 tranche que rien ne monte sans paire sous son plafond — fréquent en début de run | La réserve d'A5 dans les textes : « … et une rune de votre deck, si l'une peut encore monter, gagne un niveau » · "… and one rune in your deck gains a level, if any still can" ; de même en §5.3 et §11 |
| 7 | mineur | §5.1, `luckLevelRewardSubtitle` (l. 1054-1068) ; propriétaire n° 7 | Le libellé de la parenthèse ne porte pas le motif du n° 7 (dire au joueur quelles options sont mythiques) : sous le titre des raretés d'option, elle se lit comme la liste des options dont le tableau donne la rareté | `(options mythiques, tirées à part : {mythicNames})` · `(mythic options, rolled separately: {mythicNames})`, et les attentes de `probabilities_dialog_test.dart` alignées |
| 8 | mineur | §5.4 et §5.1, la fiche des probabilités | La section « Draft standard de récompenses » (`probabilities_dialog.dart:200-205`, `:102-103`) annonce une rareté de carte en fin de combat standard qu'aucun mécanisme ne lit ; avec E3, la carte trouvée y est toujours commune (D1) : la fiche contredira une règle que le lot rend visible, et la spec ne dit rien de cette section | La consigner en §5.4, hors du lot, comme la section « Récompense de niveau » ; ou réécrire son sous-titre en partie 1 |
| 9 | mineur | §3.8, `RunController` (l. 736) | Le wrapper `RunController.applyRunRuleModifier` gagnerait trois accumulateurs qu'aucun appelant de production ni aucun test du §8 ne passe (`run_controller.dart:297-299` ; production : `player_stats_manager.dart:303`, `:454`) : trois paramètres sans lecteur | Ne les donner qu'à `PlayerStatsManager.applyRunRuleModifier` et retirer la mention du wrapper — ou nommer un test qui passe par lui |
| 10 | mineur | §4.8 (l. 892) ; §3.8, `EventChoice` (l. 749) ; §8, « L'écran d'événement » | `EventChoice.isSelectable` (`lib/models/data/event_data.dart:66-92`) appellerait `ForgeRuneRules.hasSharpenableRune` (`lib/game/services/`) : le premier import de `lib/models` vers `lib/game`, à rebours des couches | `isSelectable` reçoit des faits calculés (`bool hasTradedRelic`, `bool hasSharpenableRune`) ; l'écran et le contrôleur les calculent avec le bonus de la run ; les tests du §8 restent valables |
| 11 | mineur | §4.6 (l. 861) ; §8, « Et cinq sur l'écran de combat et la carte du monde » | « Aucun test ne monte `MapNodeWidget` » est inexact : `map_screen_test.dart` le monte par `MapScreen` (`:73`, `map_screen.dart:261`) ; aucun ne lit son infobulle, la commande de contrôle reste justifiée | « aucun test ne lit l'infobulle de `MapNodeWidget` (`map_screen_test.dart` le monte par `MapScreen` sans la déclencher) » |
| 12 | rédaction | §11, « trois corrections » (l. 1467-1469) ; A18 | Le nom d'une rune montée au-delà de son plafond d'origine n'est pas une correction : avant E3, aucun écrivain de niveau ne dépassait le plafond — c'est un comportement neuf de *Transcendance* | Le retirer des corrections (il en reste deux) et le rattacher à la puce de *Transcendance* : « … et leur nom affiche leur niveau » |

**Aucun constat n'exige d'amender une décision acquise, ni ne change une valeur mesurée** ; les deux moyens sont deux
attentes de test que la spec ne pose pas — une barrière de contrôle qui se contredit, un test existant qu'aucune
ligne ne réécrit en entier. **Ce que l'orchestrateur recommande pour lever l'arrêt**, sans l'avoir appliqué — c'est au
propriétaire d'en décider :

- **n° 1, 2, 5, 6, 7, 11, 12** : les corrections du consolidateur, telles quelles — pour le n° 1, la première forme,
  la commande à part sur `lib` seul (filtre 8 : l'assertion du test reste celle que §8 prescrit) ;
- **n° 3** : les deux formes ensemble — la règle générale, puis les dix lignes comme un minimum, chacune dans sa
  partie (filtre 4 : la règle plutôt que le cas ; la liste guide le plan) ;
- **n° 4** : la correction du consolidateur, en deux temps (D73 : le premier temps garde le diff vide, le libellé
  imprimé change au second, dans la relance 3) ;
- **n° 8** : une troisième option, que le consolidateur ne propose pas — **retirer la section en partie 1**. Le filtre 6
  passe avant le filtre 7 : la consigner hors du lot laisse le joueur lire, à côté d'une carte toujours commune, cinq
  chances de rareté qu'aucun mécanisme ne tire (`probabilities_dialog.dart:102-103`, `:200-240`, seule lectrice de
  `calculateDraftProbabilities(luck, false)`) ; réécrire son seul sous-titre laisse ces cinq lignes sous une phrase qui
  les dément. Retirée, la fiche ne dit plus rien de faux sur la trouvaille, que l'infobulle d'élite et le tutoriel
  disent déjà ; `calculateDraftProbabilities` perd sa branche `isLevelReward: false`, et un test de widget garde
  l'absence de la section ;
- **n° 9** : la première forme, le wrapper sans accumulateur neuf (filtre 5 : pas de code sans lecteur) ;
- **n° 10** : la correction du consolidateur, des faits calculés passés à `isSelectable` (filtre 5 : les couches de
  `CLAUDE.md`) ;
- **puis un cinquième tour** : les quatre tours ont rendu 22, 15, 13 et 12 constats, dont 6, 2, 3 et 2 moyens — tous
  des trous de test ou des incohérences de texte, aucun ne touchant une décision ; le quatrième n'a trouvé ses deux
  moyens qu'au consolidateur. Un vérificateur neuf, centré sur les douze corrections et ce qu'elles touchent, suffit à
  dire si elles tiennent ; un panel entier reprend toute la spec et trouve chaque fois de nouveaux mineurs. Le
  propriétaire choisit la forme du tour ; la suite du cycle, s'il rend « prête », est inchangée (commit avec la ligne
  de `docs/INDEX.md`, puis le plan de la partie 1).
