# P-43 E2 — Fusion = forge — Conception

Date : 2026-10-02
Statut : **Conception, non convergée** — vague 2 (`0.5.4`), lot unique et lourd (deux parties), branche
`feat/v0.5.4-p43-e2-fusion-forge`. **La vague est arrêtée à la vérification de cette spec** : le troisième tour a
rendu deux constats moyens (orchestration §3.3 et §6) ; ils sont consignés, non corrigés, en §13

Chantier ROADMAP : **P-43** « Économie unifiée », lot **E2**, le troisième des cinq lots E0 à E4. Le déroulé fait foi
dans le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
(fiche §8.2) ; **E1**, fusionné dans `main` (`559df08`), a laissé le moteur de runes sur lequel E2 s'écrit.
Sources amont :
- [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 — **D3**, **D4** (le
  niveau monté contre de l'or), **D5**, **D6**, **D13**, **D14**, **D20**, **D22**, **D28** (capacité, pré-forgées),
  **D32**, **D33** (`spectral`), **D39**, **D44** et **D51** (la donnée de `cheap`), **D46**, **D48**, **D63**,
  **D65**, **D68** : source de vérité, ni rediscutées ni amendées ici ; §4.2, §4.3, §8 (lignes `cheap`, `precise`,
  `spectral`, table des `maxLevel`, paragraphe D65), §11 ligne E2, §12 lignes 1 et 2 ;
- [revue du brainstorm](../../possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §2.1 (les
  sept lecteurs de la capacité), §11 S4 et S6, §13 IV3, IV5, IV8, annexe A n° 29 ;
- [rapport de simulation](../../possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md), §1.2, §2.3, §3.6,
  §3.8, §3.13, §3.15, §7.2, §7.3 ; le script `tool/simulations/d26_economy_sim.dart` et sa sortie de référence ;
- [spec E1](2026-10-02-p43-e1-moteur-de-runes-design.md) et le
  [compte rendu de la vague 1](../reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md), §2.4 à §2.6 et §5
  (ce qui est laissé « pour E2 ») ; ADR-105, ADR-104, ADR-094, ADR-101, ADR-074, et pour l'histoire ADR-024, ADR-025,
  ADR-039.

> **Ce que E2 livre, en une phrase.** La rune ne s'obtient plus au feu de camp : chaque fusion 3 → 1 garde toutes les
> runes de ses trois exemplaires et en propose **une parmi trois**, tirées par le prédicat d'E1 au rang que la fusion
> atteint ; le feu **affûte** une rune d'un niveau contre `50 × niveau` or ; le **Puits d'échange** remplace la Forge
> de Fusion, tous les trois actes ; la boutique vend **la copie d'une carte du deck** ; `cheap`, `precise` et
> `spectral` rejoignent les huit runes ; `pools`, `stackable` et la capacité disparaissent avec les deux écrans qui
> les lisaient. **En `0.5.4`, les fusions restent rares** : la trouvaille n'arrive qu'en `0.5.5`.

Toute référence `fichier:ligne` de ce document a été mesurée le 2026-10-02 sur `a9e2db6`, tête de la branche — qui ne
diffère de `main` (`559df08`) que par le fichier d'orchestration.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce qu'E2 en livre | Où |
|:---|:---|:---|
| **D3** | À chaque fusion 3 → 1, la carte monte de rareté **et** le joueur choisit une rune parmi trois, qui entre au niveau 1 ; **une seule rune de chaque type par carte** | §4.4, §4.5 ; A1, A2 |
| **D4** (le niveau monté contre de l'or) | L'affûtage au feu de camp | §4.7 |
| **D5** | Le feu garde repos et oubli ; la forge devient « affûter une rune » | §4.7 ; A4 |
| **D6** | Le Puits d'échange remplace le nœud Forge de Fusion : une rune contre une autre, toutes les options proposées, un coût croissant avec le niveau | §4.8 ; A5 |
| **D13** | L'héritage : les runes des trois exemplaires sont gardées, deux runes de même id fusionnent en une, niveaux additionnés, puis la rune neuve hors des runes portées ; **aucun plafond de runes par carte** | §4.6 |
| **D14** | Au feu, une seule rune monte d'un seul niveau par visite | §4.7 ; A4 |
| **D20** | Le coût de l'affûtage croît avec le niveau de la rune, pas avec le rang de la carte : `b × niveau` | §4.7 |
| **D22** | Un Puits garanti tous les trois actes (actes 3, 6, 9…), sur un nœud des étages 3 à 7 | §4.8 |
| **D28** (capacité, pré-forgées) | `forgeCapacityAt`, `CardInstance.forgeCapacity` et `baseMaxForgeUpgrades` supprimés ; une carte pré-forgée de la boutique porte au plus `fusionRank` runes | §4.9, §4.10 |
| **D32** | Pas de taxe de fusion : la fusion reste gratuite | §4.5 |
| **D33** (`spectral`) | `spectral` : +40 % de la valeur de base par niveau, au moins +1 par niveau, et la carte s'épuise | §3.2, §4.1 ; A10 |
| **D39** | La rune reçue au Puits entre aux deux tiers du niveau de la rune donnée, arrondi au plus proche, au moins 1, puis bornée par son `maxLevel` ; le coût est `base × niveau` de la rune donnée | §4.8 |
| **D44**, **D51** (la donnée de `cheap`) | `requiresMinCost: 1`, `excludesRunes: ["eco"]`, dans les champs d'E1, sans code | §3.2 |
| **D46** | La boutique montre une carte de plus, à part : la copie d'une carte tirée dans tout le deck, même rang, sans ses runes, à un prix par rareté | §4.9 ; A11 |
| **D48** | `eco` et `quick` à `minFusionRank: 2` | §3.2 |
| **D63** | `b` = 50 ; les trois runes neuves au poids 50 et au `minFusionRank` 1 | §3.2, §4.7 ; A6 |
| **D65** | `cheap`, `precise`, `spectral` entrent en E2 ; la fusion propose moins de trois runes si moins sont éligibles, **jamais aucune tant qu'une existe** | §3.2, §4.4 |
| **D68** (E2 obtient) | `minFusionRank` ; une rune par type par carte ; la capacité supprimée, les pré-forgées bornées ; `pools` et `stackable` supprimés | §4.10, §4.11 |

Restent tenues, sans être relivrées : **D72** — `boundLevel` borne toujours chaque endroit qui écrit un niveau, dont la
liste change (§4.3) ; **D75** — une rune déjà portée ne se repropose jamais, ce que « une rune par type » rend général ;
**D7** — en conséquence de la disparition de la forge du feu, seule source qui leur en donnait, les cartes de classe ne
reçoivent plus de rune (§4.12).

**D13 et les exclusions.** D13 garde les runes des trois exemplaires ; D44, D51 et D61 ferment certaines paires sur une
carte. La vague 1 a tranché leur rencontre par le filtre 1 (compte rendu §2.6, E-S3 ; ADR-105 D10, correctif
`ee814e9`) : `consolidate` écarte une rune exclue par une rune gardée avant elle, la première arrivée gardée. E2
**suit** cette règle, comme la fiche le demande ; il ne la rouvre pas.

### 1.2. Les arbitrages de la spec

Tranchés par l'arbre de décision du fichier d'orchestration (§5) : le premier filtre qui départage l'emporte. **Aucune
question ne s'est révélée ne se trancher qu'en amendant une décision acquise.** A3 à A7, A9, A11 et A20 sont posées
par la fiche ; A1 et A18 sont nées de « la spec doit fixer » ; les autres sont apparues à la rédaction.
L'orchestrateur a tranché six points au tour 1 de vérification, dont un apparu à la correction — le retour sur l'écran
du feu ou du Puits après une action (A4, A5) —, et trois au tour 2 : qui tire l'offre, l'offre vide (A1), les textes
qui nomment encore la forge (§5.7). Les deux tableaux sont en fin de section.

**Sur le filtre 2.** Les valeurs que le script joue sans qu'une décision les fixe sont des valeurs de spec : les
garder ne demande aucune relance, les remplacer en demande une (second temps, orchestration §3.6). Le filtre 2 ne les
écarte donc pas à lui seul ; quand les filtres 3 à 6 ne donnent aucun motif de remplacer une valeur jouée, **le
filtre 7 la garde** — la remplacer ajouterait à la vague une relance que rien n'appelle. C'est une lecture différente
d'A5 de la spec E1, qui retenait la valeur jouée par le filtre 2 lui-même (spec E1, `:149`).

#### A1 — Le geste de fusion *(née de « la spec doit fixer »)*

- **(a) la fusion, puis le choix** : `mergeCards` crée la carte, avec ses runes héritées ; le dialogue s'ouvre sur
  elle et **ne se ferme que par un choix** — ni bouton d'annulation, ni retour ;
- (b) la fusion, puis un choix différable : le dialogue se ferme, la carte garde son offre en attente, l'écran de deck
  la rouvre ;
- (c) le choix d'abord, sur un aperçu de la carte fusionnée ; la fusion n'a lieu qu'au choix, annuler n'en fait aucune.

1. *Décision acquise* — ne départage pas : D3 lie la fusion et le choix ; les trois les gardent, (b) en les écartant
   dans le temps.
2. *Valeur jouée* — le script tire l'offre une fois, dans la fusion même (`d26_economy_sim.dart:2308-2326`, qui
   appelle `offerRune`, `:2281-2303`). (c) sans garde-fou retire une offre neuve à chaque annulation : une relance
   gratuite, qui remplace le tirage joué.
3. et 4. — neutres.
5. *Architecture* — **retient (a)**. (c) ne tient le tirage joué qu'avec une garde anti-relance indexée sur les trois
   exemplaires, un état sans autre lecteur ; (b) demande un état « offre en attente », sérialisé, et un chemin de
   réouverture. (a) n'a besoin d'aucun état : rien ne se sauvegarde avant la résolution d'un nœud
   (`map_progression_manager.dart:45`, `player_stats_manager.dart:153`), et le dialogue ne se ferme pas sans choix.

**Choix : (a).** Une fusion sans aucune rune éligible — la première d'une *Concentration* ou d'une *Focalisation*
(§4.12) — se fait sans dialogue de choix (D65 : jamais aucune tant qu'une existe ; ici aucune n'existe).

**Qui tire l'offre** *(tranché par l'orchestrateur au tour 2)*. (i) `DeckNotifier.mergeCards` tire les trois runes et
les rend avec la carte — la prose du brainstorm §4.2 (`:200`, « `DeckNotifier.mergeCards` tire 3 runes éligibles ») et
§11 (`:491`, « `mergeCards` propose 3 runes ») ; (ii) la fonction pure `ForgeRuneRules.drawRunes` (§4.4), appelée par
l'écran de deck sur la carte que `mergeCards` rend, le choix écrit par le Notifier (`addForgeUpgrade`). Ces deux phrases
sont une prose de proposition, pas une décision acquise : D3 dit que le joueur choisit une rune parmi trois, pas qui
les tire. **5** retient (ii) : la même fonction pure sert le jeu et le tutoriel (A18), sur le précédent du dialogue
d'E1, qui tirait ses fentes lui-même ; l'offre n'est pas un état persisté — A3 supprime la session ; tout changement
d'état passe par `DeckNotifier`. **Choix : (ii)** — la phrase du brainstorm n'est pas suivie à la lettre, pour ces
raisons ; son intention, une offre de trois runes à chaque fusion, l'est.

**L'offre vide** *(tranché par l'orchestrateur au tour 2)*. **6** : le joueur lit les deux faits — la fusion se fait,
la notification de fusion réussie (`deckMergeSuccess`) s'affiche, **puis** le message `forgeNoEligibleRune`. Le chemin
exact est en §4.5.

#### A2 — Ce que propose le dialogue de fusion *(apparue à la rédaction)*

`ForgeUpgradeDialog` porte aujourd'hui un nombre de fentes tiré (100 · 50 · 25 · 10 · 2 %,
`forge_upgrade_dialog.dart:207-211`), un ciblage par `pools` selon la rareté de la carte (`:96-134`), un tirage de
niveau 80 · 15 · 5 % (`:171-181`), des relances payantes (`:223-246`, `ForgeSlot.rerollCost`, `:29`) et des fentes
achetées (`:248-264`, `bonusForgeSlots`).

**Le nombre et le niveau.** (i) Trois runes, ou toutes si moins sont éligibles, au niveau 1 ; (ii) le niveau selon le
rang atteint ; (iii) des fentes tirées comme aujourd'hui. **1** écarte (iii) — D3 : « 1 rune parmi 3 » — et ne
départage pas (i) et (ii) : le « palier [qui] dépend du rang de fusion » de D3 est tenu par `minFusionRank` dans les
deux (D48 ; brainstorm §4.2). **2** : (i) est ce que joue le script (`:2302`) et ce que lit le brainstorm §4.2
(« elle entre au niveau 1 ») ; les filtres 3 à 6 ne donnent aucun motif de le remplacer — les niveaux viennent de
l'héritage et de l'affûtage (D13, D4) ; **7** retient (i).

**Le tirage.** (x) Pondéré par `weight`, sans remise, parmi toutes les runes éligibles ; (y) le ciblage par `pools`
d'aujourd'hui. **1** écarte (y) : D68 supprime `pools`. (x) est ce que joue le script (`:2282-2288`).

**Relances et fentes achetées.** (p) Supprimées ; (q) gardées. **1** écarte les fentes achetées : elles portent l'offre
au-delà de trois. Pour les relances, **2** : le script n'en joue aucune — une relance payante, l'or débordant (rapport
§2.3), changerait la rune choisie que la mesure suppose ; les filtres 3 à 6 n'en donnent aucun motif ; **7** retient
(p). Le constat E-S4 de la vague 1 — une relance sans effet sur une carte à une seule rune éligible — disparaît avec
elles.

**Choix : (i), (x), (p).**

#### A3 — Ce que `forgeTargetCardId` désigne désormais *(posée par la fiche)*

**Constat de mesure.** `forgeSlots` et `forgeTargetCardId` (`lib/game/controllers/run_controller.dart:32-33`) sont
écrits par `setForgeSession` (`:503-511`), remis à zéro par `clearForgeSession` (`:513-519`), sérialisés
(`:139-140`, `:152-154`, `:192-193`) — et **lus par aucun code du jeu** : le dialogue restaure sa session depuis
`forgeTargetSessions`, une table par carte (`forge_upgrade_dialog.dart:54-56`). Leurs seuls lecteurs sont deux tests
(`test/unit/run_controller_test.dart:189-203`, `test/unit/run_state_persistence_test.dart:59-84`, `:120-126`).
`bonusForgeSlots` (`:35`) n'est jamais remis à zéro : une fente achetée vaut pour toute la run.

- **(a) rien** : `forgeSlots`, `forgeTargetCardId`, `forgeTargetSessions`, `bonusForgeSlots`, `setForgeSession`,
  `clearForgeSession` et `buyBonusForgeSlot` sont supprimés ;
- (b) la carte fusionnée qui attend sa rune, `forgeSlots` son offre ;
- (c) la carte affûtée pendant la visite, pour tenir « une fois par visite ».

1 à 4 ne départagent pas. **5** : (b) suppose A1 (b), écartée ; (c) écrirait dans `RunState` une règle que l'écran du
feu tient déjà pour ses deux autres options (A4) — un fait à deux endroits. **Choix : (a).** Le dialogue de fusion ne
se ferme pas sans choix (A1) et n'a plus de relance (A2) : il n'y a plus de session à garder. La ligne « Slots de forge
bonus » du menu de debug (`lib/ui/widgets/debug/tabs/debug_run_tab.dart:59-66`) part avec `bonusForgeSlots`.

#### A4 — L'écran d'affûtage et « une fois par visite » *(posée par la fiche)*

**Constat de mesure.** Le feu tient déjà « une action par visite » : `_actionTaken`
(`lib/ui/screens/rest_screen.dart:23`) passe à vrai après le repos, la forge ou l'oubli (`:34`, `:60`, `:92`), et les
trois options disparaissent (`:151`) ; seul « Continuer » reste.

**La règle « une fois par visite ».** (α) L'exclusivité d'aujourd'hui : l'affûtage prend la place de la forge parmi
trois options exclusives ; (β) un compteur dans `RunState` ; (γ) l'affûtage en plus du repos ou de l'oubli, une fois.
**1** retient (α) contre (γ) : D5 — « garde repos et oubli ; la forge devient améliorer une rune » — met l'affûtage à
la place de la forge. Le script joue de même un feu à une action (rapport §2.3 : 14 repos, 5 affûtages, 1 oubli sur 20
visites). **5** écarte (β) : la règle vivrait à deux endroits.

**L'écran.** (i) L'écran de sélection du feu en mode affûtage, puis un dialogue qui liste les runes de la carte ;
(ii) `ForgeUpgradeDialog` en mode affûtage ; (iii) un écran de toutes les paires (carte, rune). **5** écarte (ii) : un
dialogue pour deux gestes, ajouter une rune et monter un niveau. **6** retient (i) sur (iii) : chaque ligne dit ce que
le niveau ajoute à **cette** carte (`{val}` marginal, spec E1 §5.1) et son coût, sur la carte en regard.

**Choix : (α), (i)**, et deux règles de lecture (6) : l'option du feu se montre **inactive, avec son motif**, quand
aucune rune du deck ne peut monter ; à la sélection, une carte sans rune affûtable est grisée et refusée au toucher,
avec son message, comme E1 refusait une carte sans rune éligible (A11).

**Où vit l'état de visite** *(tranché par l'orchestrateur au tour 1)*. (α′) Un état local de l'écran, sur le précédent
`_actionTaken` (`rest_screen.dart:23`) ; (δ) la règle entière dans un Notifier, `_actionTaken` supprimé. **5** retient
(α′) : c'est un état de déroulé d'écran, qui ne survit pas à l'écran et n'est partagé avec personne ; les opérations de
jeu — payer l'or, monter le niveau — vivent dans les Notifiers et les fonctions pures (A16). **7** : l'écran du feu
n'est pas refondu au-delà de son option. **Choix : (α′).**

**Le retour à l'écran après une action** *(apparue à la correction du tour 1 ; tranché par l'orchestrateur au
tour 1)*. **Le constat.** Le nœud n'est résolu que par le bouton « Continuer » : `_leave` (`rest_screen.dart:105-109`)
appelle `completeCurrentNode`. Mais l'écran autorise le retour système dès qu'une action est faite
(`canPop: _actionTaken`, `:121`, posé par `ScreenScaffold` en `PopScope`, `lib/ui/widgets/screen_scaffold.dart:83-89`) :
ce retour quitte l'écran **sans** `_leave`, le nœud reste non résolu, et la carte du monde laisse rentrer dans le nœud
courant tant qu'il ne l'est pas (`map_screen.dart:389-392`). Le nouvel écran repart de `_actionTaken = false` : un
second affûtage serait possible — comme le sont aujourd'hui un second repos, une seconde forge ou un second oubli.

- **(a) toute sortie de l'écran après une action résout le nœud** : le retour système, une fois l'action faite, fait
  ce que fait « Continuer » ; avant toute action, rien ne change ;
- (b) un drapeau de visite neuf dans `RunState`, lu à l'entrée de l'écran ;
- (c) laisser tel quel.

**1** écarte (c) : D14 — une seule rune, un seul niveau par visite — ne tiendrait pas ; on affûterait autant qu'on a
d'or. **5** retient (a) contre (b) : (a) s'appuie sur un état métier qui existe déjà, la résolution du nœud dans son
Notifier (`completeCurrentNode`), au lieu d'en créer un ; **8** ensuite. **Choix : (a).** L'état de visite reste local
à l'écran (ci-dessus).

**Le mécanisme**, re-mesuré. `RestScreen` passe à `ScreenScaffold` `canPop: false` — au lieu de `canPop: _actionTaken`
(`:121`) — et un `onPopInvokedWithResult` (le paramètre existe déjà, `screen_scaffold.dart:11`, `:20`, transmis au
`PopScope` en `:84-87` : **`screen_scaffold.dart` ne change pas**) qui :

1. ne fait rien si `didPop` est vrai — c'est le `Navigator.pop` de `_leave` lui-même, qui repasse par le rappel : pas
   de double navigation ;
2. sinon, si `_actionTaken`, appelle `_leave` (`:105-109`) : le nœud est résolu, puis l'écran se ferme, par le même
   chemin que « Continuer » ;
3. sinon — aucune action faite —, ne fait rien : le retour reste bloqué, comme aujourd'hui (`canPop` valait alors
   `false`).

**Conséquence assumée** : le même mécanisme ferme au feu le second repos et le second oubli, possibles aujourd'hui par
la même voie. C'est la **correction d'un défaut antérieur**, dans l'écran et la règle qu'E2 réécrit, et la note de
version la dit comme telle (§11).

#### A5 — L'écran du Puits *(posée par la fiche ; deux points apparus à la rédaction)*

**L'écran.** (i) `ForgeFusionScreen` réécrit en place : les cartes qui portent une rune, puis la rune à donner, puis
**toutes** les runes qui peuvent la remplacer, chacune avec son niveau d'arrivée, sa description sur la carte et le
coût ; (ii) un dialogue sur la carte du monde ; (iii) l'écran de sélection du feu et un dialogue. **5** retient (i) :
le nœud a déjà son écran, sa sortie (`_leave`, `forge_fusion_screen.dart:84-87`, qui résout le nœud) et son entrée
(`map_screen.dart:427-428`).

**Ce qui s'offre** *(apparue)*. (x) Le prédicat évalué sur la carte **sans la rune donnée**, au rang de la carte, la
rune donnée exclue ; (y) sur la carte telle qu'elle est. **1** : IV5 et le brainstorm §4.3 lisent « toutes les runes
éligibles au sens de §4.2, au rang de la carte » — les deux le tiennent. **2** : (x) est ce que joue le script, qui
retire la rune donnée avant de juger (`d26_economy_sim.dart:3082-3085`). 3 à 5 neutres. **6** retient (x) : sous (y),
donner *Persistant* pour *Économe* serait refusé par l'exclusion même que l'échange défait — une règle que le joueur ne
peut pas lire.

**Combien d'échanges par visite** *(apparue)*. (p) Un ; (q) autant que l'or le permet, comme la Forge de Fusion
d'aujourd'hui. **1** ne départage pas. **2** : le script en joue un par visite (`visitWell`, `:3068-3108` — rapport §3.6 :
5 échanges pour 5 visites) ; (q) laisserait la réserve d'or (5 596 à l'acte 15, rapport §7.2) acheter des échanges que
la mesure ne compte pas ; 3 à 6 ne donnent aucun motif ; **7** retient (p).

**Choix : (i), (x), (p).** Une rune donnée qui n'a aucune remplaçante se montre inactive, avec son motif ; un deck sans
rune montre l'écran vide et la sortie.

**Où vit l'état de visite** *(tranché par l'orchestrateur au tour 1)*. (p′) Un état local de l'écran, comme
`_actionTaken` au feu ; (δ) la règle entière dans un Notifier. **5** retient (p′) — un état de déroulé d'écran, non
partagé ; l'échange lui-même vit dans `GoldManager` et `ForgeRuneRules` (A16) ; **7** : l'écran n'en porte pas plus.
**Choix : (p′).**

**Le retour à l'écran après un échange** *(apparue à la correction du tour 1 ; tranché par l'orchestrateur au tour 1,
avec A4)*. **Le constat.** `ForgeFusionScreen` ne pose aucun `PopScope` (`ScreenScaffold` sans `canPop`,
`forge_fusion_screen.dart:127`) : le retour système le quitte à tout moment sans `_leave` (`:84-87`), le nœud reste
non résolu, la carte du monde laisse y rentrer (`map_screen.dart:389-392`), et le nouvel écran repart d'un état vierge
— un second échange serait possible. Options : celles d'A4 — (a) toute sortie après un échange résout le nœud ; (b) un
drapeau de visite dans `RunState` ; (c) tel quel. Le filtre 1 ne s'applique pas ici : aucune décision acquise ne fixe
un échange par visite au Puits, D14 ne vaut qu'au feu ; **(c) déferait A5 (p)**, l'échange unique que cette spec retient
plus haut (filtre 7). **5** retient (a) contre (b) ; **8** ensuite. **Choix : (a).**

**Le mécanisme.** L'écran réécrit passe à `ScreenScaffold` `canPop: !échangé` — son état local d'échange — et un
`onPopInvokedWithResult` qui ne fait rien si `didPop` est vrai (le pop de `_leave`, ou un retour avant tout échange),
et appelle sinon `_leave` (`:84-87`) : après un échange, le retour système résout le nœud par le chemin du bouton de
sortie. **Avant tout échange, rien ne change** : le retour ferme l'écran sans résoudre le nœud, et le joueur peut
revenir au Puits, comme aujourd'hui.

#### A6 — La `base` du Puits *(posée par la fiche — valeur jouée sans décision)*

- **(a) 50 or, une constante à part** ;
- (b) la même constante que `b`, 50 ;
- (c) une autre valeur — 80, l'ancien prix de la Forge de Fusion, ou 100.

1. *Décision acquise* — ne départage pas : D6 veut un coût croissant avec le niveau, D39 `base × niveau` de la rune
   donnée ; aucune ne fixe la base.
2. *Valeur jouée* — ne départage pas (a) et (b), qui gardent toutes deux 50 ; (c) remplacerait la valeur jouée.
3. et 4. — neutres.
5. *Architecture* — **écarte (b)** : le script joue `wellBase = 50` comme un paramètre **distinct** de `sharpenB`
   (`:82-85`, `:133-138`), et le levier de `b` (rapport §3.8, §7.3) a varié l'affûtage seul, la base du Puits fixée
   (`:3686-3689`) — deux prix que la mesure fait varier séparément sont deux faits, chacun à son endroit.
6. — aucun motif de remplacer la valeur : le Puits ne consomme presque pas d'or (≈ 3 300 quel que soit son rythme,
   rapport §3.6).
7. *Périmètre* — **écarte (c)**, qui ajouterait une relance sans motif ; **retient (a)**.

**Choix : (a)** — `ForgeRuneRules.wellBaseCost = 50`, à côté de `sharpenBaseCost = 50` (D63), chacun lu par une seule
fonction (§4.7, §4.8). **Aucune relance de second temps.**

#### A7 — Le `minFusionRank` 1 des six runes existantes autres qu'`eco` et `quick` *(posée par la fiche — valeur jouée)*

Le script joue 1 pour toute rune hors `eco` et `quick` (`minRankOf`, `:1267-1269`) ; `enduring` n'est aujourd'hui que
dans le pool `rare` (`assets/data/forge_upgrades/enduring.json:9-11`).

- **(a) 1 pour les six** ;
- (b) `enduring` à 2, comme son pool d'aujourd'hui ;
- (c) chaque rune à un rang déduit de son pool le plus bas.

1. ne départage pas : D48 ne nomme qu'`eco` et `quick`, et tient seule le « palier » de D3. 2. (a) est la valeur jouée.
3 à 6 ne donnent aucun motif de la remplacer : sur les cartes livrées, `enduring` à 1 ne s'offre qu'à la première
fusion d'une *Potion de Soin* (§4.12) — la seule carte fusionnable qui s'épuise sans piocher ni rendre de mana — et la
forge du feu de `0.5.3` la proposait déjà à une *Potion de Soin* commune, par le repli des pools (compte rendu de la
vague 1, §5). **7** retient (a). **Aucune relance de second temps.**

#### A8 — La forme de `minFusionRank` *(apparue à la rédaction)*

- **(a) clé obligatoire, entier ≥ 1**, refusée par `ForgeUpgradeData.fromJson` sinon ;
- (b) clé facultative, 1 par défaut ;
- (c) obligatoire, 0 admis.

1 à 4 ne départagent pas. **5** écarte (b) : la clé remplace `pools`, la seule clé que l'éditeur exige d'une rune
aujourd'hui (`entity_descriptor.dart:335`) ; une rune neuve ne doit pas s'offrir dès la première fusion faute de l'avoir
dite — le précédent est `maxLevel` (A8 de la spec E1). **6** écarte (c) : 0 se lirait « dès la commune », ce qu'aucune
source ne tient — une commune ne porte jamais de rune (§4.12). **Choix : (a)**, avec le précédent de `maxLevel`
(`forge_upgrade_data.dart:43-47`) : `fromJson` exige la clé, le constructeur prend `minFusionRank = 1` par défaut, pour
les tests qui construisent une rune en Dart.

#### A9 — L'éligibilité de `precise` et de `spectral` *(posée par la fiche — valeur jouée)*

Le script les joue sur les seules cartes de dégâts (`needs: 'damage'`, `:854`, `:858`), sans type ni exclusion.

- **(a) `eligibleEffects: ["damage"]` pour les deux**, sans `eligibleCardTypes` ni `excludesRunes` ;
- (b) `precise` aussi sur le soin, qui peut critiquer (`lib/game/services/effects/strategies.dart:94-97`) ;
- (c) `spectral` refusée à une carte qui s'épuise déjà, et exclue d'`enduring`.

1. ne départage pas : D33 veut `spectral` en pourcentage de la valeur de base — une carte de dégâts, ce que les trois
   tiennent. 2. (a) est la valeur jouée. 3 à 5 neutres. 6. (c) fermerait deux cas qu'aucune carte de `0.5.4` ne
   produit — aucune carte fusionnable ne porte à la fois des dégâts et l'épuisement (§4.12) ; (b) dirait une rune de
   critique sur une carte de soin, que le brainstorm §8 attache à `DamagePipeline`. **7** retient (a).

**Choix : (a). Aucune relance de second temps.** Les deux cas de (c) — `spectral` sans contrepartie sur une carte qui
s'épuise, et la paire `spectral` / `enduring` — deviennent possibles avec les cartes de lot de la vague 5
(*Lacération* du script, `:584-585`, 0 mana, dégâts, épuisement) : ils sont portés à sa frontière (§4.13), où la
relance mesure de toute façon les lots réels (orchestration §7.3, ligne 5).

#### A10 — L'effet des trois runes neuves *(apparue à la rédaction)*

**Les sortes.** `cheap` et `precise` demandent chacune une sorte neuve, `spectral` une — une fois par mécanisme
(D18, A1 de la spec E1) : `reduceCost` (le coût, que `currentCost` lit), `critBonus` (le critique de la carte, que
`DamagePipeline.calculate` lit), `addExhaust` (la carte s'épuise). `spectral` compose `percentBonus` (sorte d'E1) et
`addExhaust`.

**`spectral` face au script.** (x) D33 : +40 % de la valeur de l'effet **à la rareté**, au moins +1 par niveau,
additionné aux autres pourcentages, sans la Puissance ; (y) le modèle du script : ×(1 + 0,4 × niveau) sur les dégâts
par coup **Puissance et `sharp` compris** (`:1700-1702`, `:1894-1902`, `:2202`). **1** écarte (y) : D33 dit
« pourcentage de la valeur de base de la carte, au moins +1 par niveau ». Le 40 % est gardé, la base est celle de la
décision.

**Ce que la simulation en fait** *(tranché par l'orchestrateur au tour 1)*. (s1) Une relance de second temps : le
script est aligné sur la forme du jeu dans une tâche à part, après le réalignement, et l'orchestrateur relance,
explique l'écart et recommite la référence ; (s2) une exception consignée, sans relance. **2** retient (s1) : une
valeur que le script joue et que la vague remplace se relance à part (orchestration §3.6, second temps ; §5, filtre 2) ;
(s2) laisserait la référence mesurer un `spectral` que le jeu ne joue pas. **Choix : (s1)** — ce que le script doit
calculer est en §9.

**La préséance de l'épuisement.** Une carte qui porterait `spectral` et `enduring` : (p) `addExhaust` l'emporte, la
carte s'épuise ; (q) `removeExhaust` l'emporte ; (r) la paire exclue en donnée. **1** écarte (q) : D33, « la carte
s'épuise ». **2** : le script joue (p) (`:1849-1852`) et n'exclut pas la paire. 3 à 6 neutres en `0.5.4` (A9 : aucune
carte n'y mène). **7** retient (p). La préséance s'écrit de toute façon : `exhaustsOnPlay` combine deux drapeaux.

**Choix : trois sortes neuves, (x), (p) ; pour la simulation, (s1).**

#### A11 — La copie du deck : son prix, sa source, la relance *(prix posé par la fiche ; le reste apparu)*

**Le prix.** (a) Le prix de boutique d'une carte sans rune de sa rareté — 25 · 50 · 100 · 150 · 200
(`ShopController.getCardPrice`, `shop_controller.dart:19-43`) ; (b) une prime pour une source ciblée ; (c) le prix du
Miroir magique (`150 << achats`, `lib/models/shop_state.dart:16`). **1** écarte (c) : D46 veut « un prix par rareté ».
**2** : (a) est ce que joue le script (`cardPriceByRank[src.rank]`, `:2876`, `:32`). 3 à 6 sans motif ; **7** retient (a).

**La source.** `DeckState.copyableCards` (`deck_controller.dart:54-55`), tirage uniforme : D46 « tirée dans tout le
deck », ADR-094 D2 fait de cette liste celle de toute source de copie — la copie en est la quatrième. Liste vide : pas
de copie (ADR-101 D4, pas de repli codé).

**La relance de l'étal** (`rerollCards`, `:309-331`). (a) Elle ne touche pas la copie ; (b) elle la retire aussi.
**1** retient (a) : D46, « tirée et non choisie » — 15 or par nouveau tirage la rendraient choisie.

**Choix : (a), `copyableCards`, (a).**

#### A12 — Les cartes pré-forgées *(apparue à la rédaction)*

- **(a)** au plus `fusionRank` runes (D28), chacune tirée par le prédicat **au rang de la carte**, pondérée, sur la
  carte avec les runes déjà tirées (A12 de la spec E1), puis un niveau tiré 80 · 15 · 5 % et borné par `boundLevel` ;
- (b) la même, au niveau 1, comme une fusion ;
- (c) le ciblage par `pools` d'aujourd'hui.

**1** écarte (c) (D68). **2** : (a) est `shopCard` du script (`:2842-2862`, niveau `:2858-2861`) ; (b) remplacerait le
niveau joué, et 3 à 6 n'en donnent aucun motif ; **7** retient (a). **Choix : (a).** Le tirage 80 · 15 · 5 ne vit plus qu'à un endroit : le « bloc dupliqué entre le feu et la boutique » que la
vague 1 laissait (compte rendu §2.6) se résout par la disparition du feu.

#### A13 — Le badge « Usage unique » *(apparue à la rédaction)*

Quatre lecteurs disent qu'une carte s'épuise en lisant la donnée seule : le badge Flame
(`card_text_renderer.dart:434`), la description Flame (`card_component.dart:340`), les particules
(`card_animator.dart:157`), le badge Flutter (`ui_card.dart:79`, lu en `:124`). Avec `spectral`, une carte s'épuiserait
sans badge ; avec *Persistant*, le badge ment depuis ADR-094 (Conséquences).

- **(a) les quatre lisent `CardInstance.exhaustsOnPlay`** (les particules continuent d'ignorer les Pouvoirs, comme
  aujourd'hui) ;
- (b) ils restent sur la donnée, la ligne de rune dit l'épuisement.

1 à 4 ne départagent pas. **5** retient (a) : un seul prédicat par question — « la carte s'épuise-t-elle ? » en a un,
`exhaustsOnPlay` (`card_instance.dart:36-38`), que le moteur lit (`deck_controller.dart:268`) — et `spectral` ajoute
l'épuisement. **Choix : (a)**, annoncé dans la note, **maintenu par l'orchestrateur au tour 1**. Il ferme au passage la
conséquence « non planifiée » d'ADR-094 pour *Persistant* : le badge et les particules ignoraient la rune.

#### A14 — `{val}` pour toute sorte qui porte un chiffre *(apparue à la rédaction — E-S5 de la vague 1)*

Aujourd'hui `{val}` ne vaut que pour `percentBonus` ; `{val}` et `{percent}` valent 0 ailleurs
(`forge_upgrade_data.dart:231-235`, `:245`), et les cinq runes à effet ajouté écrivent `{tier}`, leur niveau, à la place
de leur valeur.

- **(a) `{val}` dit ce que la rune ajoute à cette carte, pour toute sorte chiffrée**, calculé par l'applicateur sur le
  premier delta chiffré de la rune, au-delà de ce que la carte en porte déjà ; les cinq descriptions passent de `{tier}`
  à `{val}` ;
- (b) un placeholder par sorte (`{cost}`, `{crit}`) ;
- (c) un texte littéral pour les runes binaires.

**4** retient (a) : un mécanisme, là où (b) écrit un vocabulaire par sorte et (c) recopie dans le texte un chiffre que
la donnée porte déjà. **Choix : (a).** Pour les huit runes livrées, l'affichage ne change pas (une unité par niveau).

#### A15 — Le coût courant que lit le prédicat *(apparue à la rédaction)*

Avec `cheap`, `CardInstance.currentCost` (`card_instance.dart:22`) devient le coût de l'applicateur, sur le registre
global. Le prédicat, lui, reçoit son `catalog` (`forge_rune_rules.dart:103-107`) et le lit en `:118`.

- **(a)** le prédicat calcule le coût courant par l'applicateur **sur le `catalog` reçu** ;
- (b) il garde `card.currentCost`.

**5** retient (a) : le prédicat est pur par ses entrées (A3 de la spec E1) ; le tutoriel l'appelle sur son propre
registre (ADR-081), jamais sur `GameDataRegistry.instance`. **Choix : (a).** Même valeur en jeu.

**Sa partie** *(tranché par l'orchestrateur au tour 1)* : **la partie 2**, avec `reduceCost`. En partie 1, aucune
sorte ne change le coût : le coût courant égale le coût de la donnée, et rien n'est perdu à attendre.

#### A16 — Où vivent l'affûtage et l'échange payants *(apparue à la rédaction)*

- **(a) `GoldManager`** (`lib/game/controllers/run/gold_manager.dart`), exposé par `RunController`, qui y perd
  `buyBonusForgeSlot` (`:12-24`) ;
- (b) `DeckNotifier` ;
- (c) les écrans, comme la Forge de Fusion d'aujourd'hui (`spendGold` puis `setForgeUpgrades`,
  `forge_fusion_screen.dart:45`, `:63`).

**5** écarte (c) — la règle « payer et écrire, ou rien » est de la logique métier, que l'interface ne porte pas
(`CLAUDE.md`, Architecture) — et (b) : `DeckNotifier` gère les piles et n'a jamais touché à l'or. `GoldManager` existe
pour vendre un service de forge contre de l'or ; il garde ce rôle. **Choix : (a).** Les formules restent des
fonctions pures de `ForgeRuneRules` (§4.7, §4.8) ; `CLAUDE.md`, qui cite `gold_manager.dart`, reste exact.

#### A17 — Les noms *(apparue à la rédaction)*

(a) `MapNodeType.forgeFusion`, `ForgeFusionScreen`, `ForgeUpgradeDialog` gardent leur nom ; (b) ils sont renommés
(`runeWell`…). 1 à 6 ne départagent pas — le joueur ne lit jamais ces noms, et le brainstorm §4.3 garde l'id du nœud.
**7** retient (a) : un renommage s'étendrait à `CLAUDE.md` (liste des écrans), aux tests et au format de la carte
sauvegardée. **Choix : (a)** ; ce qui est lu par le joueur change (§5).

#### A18 — Le tutoriel *(née de « la spec doit fixer » — revue IV8, annexe A n° 29)*

`TutorialEngine.mergeCards` (`lib/tutorial/tutorial_engine.dart:451-458`) fait monter la rareté, rien d'autre.

- **(a)** l'étape tire l'offre par **la même fonction** que le jeu (`ForgeRuneRules.drawRunes`, §4.4) sur le registre
  du tutoriel, le joueur touche une rune, la carte la porte ;
- (b) la première rune de l'offre est posée d'office, la prose explique ;
- (c) la prose seule.

**5** écarte (c) : ADR-081 — le tutoriel appelle les fonctions pures du jeu (fidélité, P-45). **6** retient (a) :
l'étape enseigne un choix. **Choix : (a)**, et `_seedMergeHand` (`:421-447`) préfère la première carte du deck dont la
fusion offre au moins une rune — repli sur la première carte fusionnable, puis sur les fixtures, comme aujourd'hui ;
sans offre, l'étape le dit.

#### A19 — L'icône et la couleur des runes neuves *(apparue à la rédaction)*

`forge_slot_row.dart` traduit `icon` et `color` par deux tables (`:35-80`) ; un nom inconnu retombe **en silence** sur
du gris et `Icons.help_outline` (commentaire `entity_descriptor.dart:342-345`).

- **(a)** les deux tables gagnent les trois icônes et les trois couleurs, et un test d'intégrité vérifie que chaque rune
  livrée a les siennes. **La couture** : les deux méthodes privées du widget (`_getUpgradeColorFromString`,
  `_getUpgradeIconFromString`) deviennent deux tables `const` publiques, `runeIcons` (`Map<String, IconData>`) et
  `runeColors` (`Map<String, Color>`), dans `lib/ui/widgets/forge/rune_style.dart` (neuf) ; la ligne de rune les lit,
  repli gris et `Icons.help_outline` compris, et le test les lit sans monter de widget ;
- (b) les runes neuves reprennent des noms existants ;
- (c) l'emoji seul.

**6** retient (a) : (b) donne à deux runes la même apparence, (c) change toutes les lignes. **Choix : (a).**

#### A20 — Le découpage en parties *(posé par la fiche)* — voir §10

La proposition de la fiche, corrigée : `minFusionRank` et « une rune par type » passent en **partie 1**, que l'offre de
fusion ne peut pas livrer sans eux (D48) ; la borne des pré-forgées par `fusionRank` (D28) y entre avec la suppression
de la capacité, qui touche la même ligne (`shop_controller.dart:198`). **8** à égalité sur le reste.

#### Tranchés par l'orchestrateur au tour 1

Sur les constats du premier tour de vérification, l'orchestrateur a tranché — chaque choix est écrit à sa place :

| N° | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| 1 | `spectral` dans la simulation | relance de second temps · exception consignée | 2 | Second temps : le script aligné sur la forme de D33 dans une tâche à part, après le réalignement ; l'orchestrateur relance, explique l'écart, recommite la référence | A10, §9, §10 |
| 2 | Le motif d'A6 | filtre 2 · filtre 5 | 5 puis 7 | A6 tranchée par le filtre 5 (deux prix que la mesure fait varier séparément sont deux faits), puis 7 ; choix inchangé : 50, constante distincte de `b` | A6 |
| 3 | La partie d'A15 | partie 1 · partie 2 | — | Partie 2, avec `reduceCost` | A15, §10 |
| 4 | L'état « une fois par visite » | état local de l'écran · la règle entière dans un Notifier | 5 puis 7 | État local de l'écran, au feu comme au Puits | A4, A5 |
| 4 bis *(apparue à la correction)* | Le retour système après une action, qui laisse le nœud non résolu | toute sortie après une action résout le nœud · drapeau de visite dans `RunState` · tel quel | Feu : 1 (D14) puis 5, puis 8. Puits : (c) déferait A5 (p) — aucune décision acquise n'y fixe l'échange unique, D14 ne vaut qu'au feu —, puis 5, puis 8 | Toute sortie après une action — au feu un repos, un affûtage ou un oubli ; au Puits un échange — résout le nœud, par le chemin de « Continuer » ; avant toute action, inchangé ; ferme au passage le second repos et le second oubli d'aujourd'hui | A4, A5, §4.7, §4.8, §8, §10, §11 |
| 5 | Les arbitrages apparus à la rédaction | — | — | Consignés par l'orchestrateur ; A13 maintenu (filtre 5 : `spectral` ajoute l'épuisement) | A13 |

#### Tranchés par l'orchestrateur au tour 2

Sur les constats du deuxième tour de vérification — chaque choix est écrit à sa place :

| N° | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| 5 | Qui tire les trois runes de la fusion | `DeckNotifier.mergeCards` tire et rend l'offre (prose du brainstorm §4.2 `:200`, §11 `:491`) · la fonction pure `drawRunes`, appelée par l'écran de deck, l'écriture par `addForgeUpgrade` | 5 | La fonction pure, appelée par l'écran ; la prose du brainstorm n'est pas suivie à la lettre — une proposition, pas une décision acquise | A1, §4.5 |
| 8 | Les textes joueur qui nomment encore la forge | renommés · laissés | 6 | Un texte que le joueur lit et qui nomme une forge disparue est renommé (« Runes » ou l'équivalent juste), en `_fr` et `_en` ; un texte jamais affiché au joueur ne change pas ; les noms de code restent (A17) | §5.7 |
| 4 | L'offre vide | — | 6 | La fusion se fait ; `deckMergeSuccess`, puis `forgeNoEligibleRune` ; `_MergeDialog` se ferme sur la `CardInstance` rendue | A1, §4.5, §8 |

#### Récapitulatif

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Le geste de fusion | fusion puis choix obligatoire · choix différable · aperçu puis fusion ; offre tirée par `mergeCards` · par `drawRunes` depuis l'écran ; offre vide | 5 ; 5 (orchestrateur, tour 2) ; 6 (orchestrateur, tour 2) | Fusion, puis un dialogue qui ne se ferme que par un choix ; l'offre tirée par la fonction pure `drawRunes`, appelée par l'écran de deck ; sans rune éligible, la fusion, `deckMergeSuccess`, puis `forgeNoEligibleRune` |
| A2 | Ce que propose le dialogue | 3 au niveau 1 · niveau au rang · fentes tirées ; tirage pondéré · `pools` ; relances et fentes gardées ou non | 1 puis 7 ; 1 ; 1 puis 7 | Trois runes (moins si moins), niveau 1, tirage pondéré sans remise, ni relance ni fente achetée |
| A3 | `forgeTargetCardId` | rien · carte en attente · carte affûtée | 5 | Supprimé, avec `forgeSlots`, `forgeTargetSessions`, `bonusForgeSlots` et leur API |
| A4 | Écran d'affûtage, une fois par visite | exclusivité du feu · compteur · en plus ; sélection + dialogue · dialogue de forge · écran des paires ; état local · Notifier | 1 puis 5 ; 5 puis 6 ; 5 puis 7 (orchestrateur) | L'affûtage remplace la forge parmi trois options exclusives ; sélection puis dialogue des runes de la carte ; état de visite local à l'écran ; après une action, le retour système résout le nœud comme « Continuer » (orchestrateur) |
| A5 | Écran du Puits | réécrit en place · dialogue de carte · sélection du feu ; carte sans la rune donnée · telle quelle ; un échange · plusieurs ; état local · Notifier | 5 ; 6 ; 7 ; 5 puis 7 (orchestrateur) | `ForgeFusionScreen` réécrit ; offre jugée sans la rune donnée ; un échange par visite, état local à l'écran ; après un échange, le retour système résout le nœud, sans échange il ne le résout pas (orchestrateur) |
| A6 | Base du Puits | 50 à part · 50 partagé avec `b` · autre | 5 puis 7 | 50, constante distincte de `b` — pas de second temps |
| A7 | `minFusionRank` des six | 1 · `enduring` à 2 · déduit des pools | 7 | 1 — pas de second temps |
| A8 | Forme de `minFusionRank` | obligatoire ≥ 1 · facultatif · 0 admis | 5 puis 6 | Obligatoire, entier ≥ 1 |
| A9 | Éligibilité de `precise`, `spectral` | dégâts seuls · `precise` sur le soin · `spectral` hors épuisement | 7 | `eligibleEffects: ["damage"]` — pas de second temps ; deux cas latents à la vague 5 |
| A10 | Effet des runes neuves | sortes neuves ; D33 · modèle du script ; préséances ; second temps · exception | 1 ; 1 ; 1 puis 7 ; 2 (orchestrateur) | `reduceCost`, `critBonus`, `addExhaust` ; `spectral` sur la base à la rareté ; l'épuisement l'emporte ; le `spectral` du script aligné, second temps |
| A11 | Copie du deck | prix de boutique · prime · prix du Miroir ; relance | 1 puis 7 ; 1 | 25 · 50 · 100 · 150 · 200, tirée dans `copyableCards`, intouchée par la relance |
| A12 | Pré-forgées | prédicat au rang + niveau tiré · niveau 1 · `pools` | 1 puis 7 | ≤ `fusionRank` runes, prédicat au rang, niveau 80 · 15 · 5 borné |
| A13 | Badge « Usage unique » | `exhaustsOnPlay` · donnée | 5 | Les quatre lecteurs lisent `exhaustsOnPlay` — maintenu par l'orchestrateur ; ferme la conséquence d'ADR-094 pour *Persistant* |
| A14 | `{val}` | toute sorte chiffrée · placeholder par sorte · littéral | 4 | `{val}` général ; cinq descriptions passent à `{val}` |
| A15 | Coût courant du prédicat | applicateur sur le catalogue reçu · `currentCost` | 5 | Sur le catalogue reçu ; en partie 2 (orchestrateur) |
| A16 | Affûtage et échange payants | `GoldManager` · `DeckNotifier` · écrans | 5 | `GoldManager`, formules dans `ForgeRuneRules` |
| A17 | Noms | gardés · renommés | 7 | Gardés |
| A18 | Tutoriel | offre jouée · rune d'office · prose | 5 puis 6 | Offre tirée par la fonction du jeu, choix par le joueur |
| A19 | Icône, couleur | tables étendues · noms repris · emoji seul | 6 | Deux tables `const` publiques, `runeIcons` et `runeColors` (`rune_style.dart`), lues par la ligne de rune et par le test d'intégrité |
| A20 | Découpage | voir §10 | 8 | Deux parties ; `minFusionRank` et « une rune par type » en partie 1 |

### 1.3. Les reliquats de la vague 1

| Reliquat (compte rendu §2.6, §5) | Sort en E2 |
|:---|:---|
| E-S3 — l'héritage doit suivre la règle d'exclusion de `consolidate` | Tenu : `mergeCards` consolide déjà (`deck_controller.dart:315`) ; E2 retire seulement la troncature qui suit (`:317-321`) (§4.6) |
| E-S4 — la relance payante sans effet sur une carte à une seule rune éligible | Disparaît avec les relances (A2) |
| E-S5 — `{val}` nul hors pourcentage ; `cheap` a besoin de son substitut | A14 |
| E-S6 — l'emoji d'une rune et la fente lisent `id:niveau` à la main | Les lecteurs que le lot réécrit ou touche passent par `ForgeUpgradeData.parseRef` : `getRuneEmoji` (`ui_card/ui_card_helpers.dart:220-221`), `_getRuneEmoji` (`card_text_renderer.dart:551-555`), la ligne de rune (`forge_slot_row.dart:83-86`), le dialogue de fusion (`deck_screen.dart:278-281`) ; ceux de `forge_upgrade_dialog.dart` et `forge_fusion_screen.dart:52` disparaissent |
| La première fusion d'une *Concentration* sans rune éligible | Confirmé (§4.12) ; A1 : la fusion se fait, avec le message |
| Le tirage 80 · 15 · 5 et un bloc de six lignes dupliqués entre le feu et la boutique | Le feu disparaît ; le tirage ne vit plus qu'en boutique (A12) |

### 1.4. Prémisses re-mesurées

| Prémisse | Où | Mesure |
|:---|:---|:---|
| « La persistance anti-reroll (`forgeSlots`, `forgeTargetCardId`) sert telle quelle » | Brainstorm §4.2 ; `_rules/03-8:29` ; ADR-039 D1 | Fausse : ces deux champs ne sont lus par aucun code du jeu ; la session vit dans `forgeTargetSessions` (A3) |
| Les références de l'« État mesuré » de la fiche | Fiche §8.2 | Déplacées par la vague 1 : `card_data.dart:142-143` → `:176-178` ; `card_instance.dart:24` → `:24-25` ; `ui_card.dart:69,101,241` → `:76`, `:107`, `:246` ; `card_text_renderer.dart:519` (aujourd'hui le coût) → `:365` ; `rest_card_selection_screen.dart:30` → `:32` ; `shop_controller.dart:188-205` → `:189-228`, `:341-355` → `:344-363` ; `deck_screen.dart:200-231` → `:196-245` ; `map_content_placer.dart:24-36` → `:23-37` ; `rest_screen.dart:29` est le soin de 30 %, la forge est `:43-73` et `:162-168`. Exactes : `deck_controller.dart:288`, `:314-321`, `forge_upgrade_dialog.dart:32`, `:51`, `run_controller.dart:32-33`, `forge_fusion_screen.dart:102`, `:112`, `shop_state.dart:16`, `tutorial_engine.dart:451`, script `:1267-1269`, `:854`, `:858` |
| `fusionOptionsFor` en `forge_rune_rules.dart:60-78` | Fiche §8.2 | `:65-94` |
| Le découpage « `minFusionRank` en partie 2 » | Fiche §8.2 | Ne tient pas : l'offre de fusion, en partie 1, en a besoin (A20, §10) |
| Le script réaligné « prend le fichier » des trois runes | Orchestration §7.3, ligne 2 | Incomplet : son `switch` ne lit d'un fichier que `id`, `weight` et `eligibleCardTypes` (`:826-829`) ; la branche par défaut (`:845`) donnerait aux trois runes **aucune** condition (`needs`) — le `switch` doit gagner leurs trois cas, et leurs fichiers ne doivent pas déclarer `eligibleCardTypes` (§9) |
| `spectral` « en pourcentage de la valeur de base » | D33 ; script `:1700-1702`, `:1894-1902` | Le script joue un multiplicateur sur les dégâts Puissance et `sharp` compris ; le jeu suit D33 (A10), et le script est aligné sur lui en second temps (§9) |
| L'héritage du script | Script `fuseInto`, `:2308-2317` | Additionne tout, sans la règle d'exclusion d'E-S3 que le jeu applique depuis `0.5.3` |
| Le feu « une fois par visite » | Fiche §8.2, à arbitrer | Tenu par `_actionTaken` (A4) — mais seulement quand le joueur sort par « Continuer » : le retour système laisse revenir dans le nœud non résolu. Tranché par l'orchestrateur au tour 1 : après une action, le retour résout le nœud (A4, A5) |
| La revue §2.1 : « `shop_controller.dart:195` … 15 % à l'acte 2, 10 % de deux runes dès l'acte 3 » | Revue §2.1 | `:198` ; et 30 % d'une rune dès l'acte 3 (`:200-212`) |

---

## 2. Périmètre

**Dans E2**

- le geste de fusion : `mergeCards` sans troncature, l'offre de trois runes, `ForgeUpgradeDialog` rappelé depuis
  l'écran de deck et réduit au choix (A1, A2) ;
- `minFusionRank` (champ, huit fichiers, prédicat) et « une rune par type » (prédicat) ;
- l'affûtage au feu (A4), le Puits (A5), la copie du deck et les pré-forgées bornées (A11, A12) ;
- la capacité supprimée — ses sept lecteurs, `baseMaxForgeUpgrades` du modèle, de l'éditeur et des six fichiers de
  signature ; `pools` et `stackable` supprimés — tous leurs lecteurs (§4.10, §4.11) ;
- la session de forge, les fentes achetées et leur API supprimées (A3) ; `fusionOptionsFor`, `FusionOption`,
  `isStackable` supprimés ;
- `cheap`, `precise`, `spectral` : trois fichiers, trois sortes de delta, leurs lecteurs (A10) ; le badge (A13) ;
  `{val}` (A14) ; les tables d'icônes et de couleurs (A19) ;
- les textes joueur : ARB, cinq descriptions de rune, la carte du monde, le tutoriel (§5) ; l'éditeur (§6) ;
- le réalignement du script de simulation, premier temps, puis l'alignement de son `spectral` sur D33, second temps
  (§9) ; les tests (§8).

**Hors d'E2**

| Sujet | Où |
|:---|:---|
| La trouvaille, `maxHandSize`, l'XP, la DDA sur Σ `fusionRank`, *Sagesse* en mythique, l'événement de relique | E3 |
| Les sources d'affûtage hors feu — boss « XP », événement, mythique `maxLevel` (D42) | E3 ; elles réutiliseront `ForgeRuneRules.canSharpen` et `boundLevel` |
| Les signatures en compétences de classe ; `unique`, `characterSpecific` | E4 |
| `piercing`, `lifesteal`, `splash`, `echo`, `transfusion` ; `requiresCost` | Vague 5 (P-44 lot 1) |
| `retain` | P-44 lot 3 |
| La paire `spectral` / `enduring` et `spectral` sur une carte qui s'épuise déjà (A9) | Vague 5, avec les cartes de lot |
| Une condition de cible pour les runes élémentaires (ADR-105, Conséquences) | Non planifié |
| Le puits d'or, l'échange 3 → 1, l'événement de fusion | P-16 |
| Tout rééquilibrage de carte ; toute valeur de D56 à D62 ou D67 | Aucun |
| `ShopState.toJson` / `fromJson`, sans lecteur (`shop_state.dart:32-53`) ; les clés ARB `deckMergeConfirm` et `merge`, sans lecteur | Collatéraux, pour la file |

---

## 3. Données

### 3.1. Le fichier d'une rune

`assets/data/forge_upgrades/cheap.json`, neuf :

```json
{
  "id": "cheap",
  "name_en": "Light",
  "name_fr": "Allégé",
  "description_en": "Costs {val} less Mana (never below 0)",
  "description_fr": "Coûte {val} Mana de moins (jamais sous 0)",
  "icon": "savings_rounded",
  "color": "tealAccent",
  "minFusionRank": 1,
  "requiresMinCost": 1,
  "excludesRunes": ["eco"],
  "maxLevel": 1,
  "deltas": [
    { "type": "reduceCost", "valuePerLevel": 1 }
  ],
  "weight": 50,
  "emoji": "🪙"
}
```

| Clé | Avec E2 | Contrainte, refusée par `ForgeUpgradeData.fromJson` sinon | Lue par |
|:---|:---|:---|:---|
| `pools` | **Supprimée** | — | — (§4.11) |
| `stackable` | **Supprimée** | — | — (§4.11) |
| `minFusionRank` | Neuve, **obligatoire** (A8) | Entier ≥ 1 ; absente, nulle, négative ou non entière refusée | Le prédicat (§4.3) |
| `eligibleCardTypes`, `eligibleEffects`, `excludesEffects`, `requiresExhaust`, `requiresMinCost`, `excludesRunes`, `maxLevel` | Restent | Inchangées (spec E1 §3.1) | Le prédicat ; `maxLevel` par `boundLevel` |
| `deltas` | Reste | Six sortes (§4.1) | L'applicateur |
| `weight`, `emoji`, `icon`, `color`, noms, descriptions | Restent | Inchangées | Le tirage ; les rendus |

Une clé `pools` ou `stackable` restée dans un fichier n'est pas lue, comme toute clé inconnue.

### 3.2. Les onze fichiers

| Rune | `minFusionRank` | `maxLevel` | Éligibilité | `deltas` | `weight` | Avec E2 |
|:---|:---:|:---:|:---|:---|---:|:---|
| `sharp` | 1 | `null` | `eligibleEffects: ["damage"]` | `percentBonus damage 15` | 100 | perd `pools` |
| `hardened` | 1 | `null` | `eligibleEffects: ["armor"]` | `percentBonus armor 15` | 100 | perd `pools` |
| `burning` | 1 | `null` | `eligibleCardTypes: ["attack"]` | `addEffect apply_status burn` | 80 | perd `pools` ; description `{tier}` → `{val}` |
| `freezing` | 1 | 1 | `eligibleCardTypes: ["attack"]` | `addEffect apply_status freeze` | 80 | idem |
| `shocking` | 1 | `null` | `eligibleCardTypes: ["attack"]` | `addEffect apply_status shock` | 80 | idem |
| `quick` | **2** (D48) | 1 | trois types | `addEffect draw` | 60 | perd `pools` ; `{tier}` → `{val}` |
| `eco` | **2** (D48) | 1 | trois types, `requiresMinCost: 1` | `addEffect gain_mana` | 40 | idem |
| `enduring` | 1 (A7) | 1 | trois types, `requiresExhaust`, `excludesEffects`, `excludesRunes: ["eco", "quick"]` | `removeExhaust` | 30 | perd `pools` et `stackable` |
| **`cheap`** | 1 (D63) | 1 | `requiresMinCost: 1`, `excludesRunes: ["eco"]` (D51) | `reduceCost 1` | 50 (D63) | **neuf** |
| **`precise`** | 1 (D63) | 10 (brainstorm §8) | `eligibleEffects: ["damage"]` (A9) | `critBonus 5` | 50 (D63) | **neuf** |
| **`spectral`** | 1 (D63) | `null` (brainstorm §8) | `eligibleEffects: ["damage"]` (A9) | `percentBonus damage 40`, `addExhaust` | 50 (D63) | **neuf** |

**Aucun `weight` existant ne change, ni aucun `eligibleCardTypes`** ; les trois runes neuves ne déclarent **pas**
`eligibleCardTypes` — le script de simulation leur donnerait sinon des types que leur définition en dur n'a pas (§9).
Les trois fichiers entrent dans un dossier déjà déclaré : `pubspec.yaml` ne change pas, `dart run tool/sync_assets.dart
--check` reste propre. La symétrie des exclusions (D61) donne `eco` ↔ `cheap` sans rien écrire dans `eco.json`.

### 3.3. Les signatures

Les six fichiers `assets/data/classes/*/cards/*.json` perdent `"baseMaxForgeUpgrades": 5` (par exemple
`classes/paladin/cards/smite.json:22`). Rien d'autre ne change en eux : leur forme de compétence est E4.

### 3.4. Le modèle

| Où | Avec E2 |
|:---|:---|
| `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) | `pools` (`:18`, `:64`, `:88`, `:198`) et `stackable` (`:38-41`, `:71`, `:100`, `:205`) supprimés ; `minFusionRank` neuf : obligatoire dans le fichier, refusé par `fromJson` sinon (A8), `1` par défaut au constructeur, pour les tests — le précédent de `maxLevel` (`:43-47`) —, écrit par `toJson` ; `getDescription` calcule `{val}` pour toute sorte chiffrée (A14, §5.2) |
| `CardDelta` (`lib/models/data/card_delta.dart`) | Trois sortes neuves (§4.1) ; `typeNames` (`:17`) en compte six |
| `EffectiveCard` (`lib/models/effective_card.dart`) | Gagne `cost`, `critChanceBonus`, `addsExhaust` (§4.2) |
| `CardInstance` (`lib/models/card_instance.dart`) | `forgeCapacity` (`:24-25`) supprimé ; `currentCost` (`:22`) lit `effective.cost` ; `exhaustsOnPlay` (`:36-38`) lit aussi `addsExhaust` |
| `CardData` (`lib/models/data/card_data.dart`) | `baseMaxForgeUpgrades` (`:133`, `:152`, `:222`, `:242`) et `forgeCapacityAt` (`:176-178`) supprimés ; la doc de `fusionRank` (`:34-35`) ne cite plus la capacité : « le nombre de fusions qu'il a fallu pour atteindre cette rareté ; `minFusionRank` le compare, G1 compte ses paliers, il borne les runes d'une pré-forgée » |
| `RunState` (`lib/game/controllers/run_controller.dart:24`) | `forgeSlots`, `forgeTargetCardId`, `forgeTargetSessions`, `bonusForgeSlots` (`:32-35`) supprimés, avec leurs lignes de constructeur, `copyWith`, `toJson` et `fromJson` (A3) |
| `RunController` (`run_controller.dart:211`) | `setForgeSession`, `clearForgeSession`, `buyBonusForgeSlot` (`:503-523`) supprimés (A3) ; `sharpenRune` et `exchangeRune` neufs, qui délèguent à `GoldManager` (A16) |
| `ShopState` (`lib/models/shop_state.dart`) | Gagne `deckCopy` (`CardInstance?`) (§4.9) ; `toJson` / `fromJson`, sans lecteur, ne l'apprennent pas |
| `DamagePipeline.calculate` (`lib/game/services/damage_pipeline.dart:6-11`) | Gagne `critChanceBonus` (entier, défaut 0), ajouté à `effectiveCritChance` au jet (`:24`) |

---

## 4. Le moteur

### 4.1. Les sortes de delta neuves

| `type` | Paramètres | Au niveau L | Lu par | Rune |
|:---|:---|:---|:---|:---|
| `reduceCost` | `valuePerLevel` (entier > 0) | La carte coûte `max(0, coût − valuePerLevel × L)` | `CardInstance.currentCost` | `cheap` (1) |
| `critBonus` | `valuePerLevel` (entier > 0, en points de pourcentage) | +`valuePerLevel × L` % de critique sur les dégâts de la carte | `DamageEffectStrategy` → `DamagePipeline.calculate` | `precise` (5) |
| `addExhaust` | — | La carte s'épuise, quel que soit L ; l'emporte sur `removeExhaust` (A10) | `CardInstance.exhaustsOnPlay` | `spectral` |

Les trois sortes d'E1 (`percentBonus`, `addEffect`, `removeExhaust`) ne changent pas. Une sorte s'écrit une fois, par
mécanisme — jamais un `case` par rune (`test/unit/rune_ids_in_code_test.dart` le garde).

### 4.2. L'applicateur

`EffectiveCard.apply` (`effective_card.dart:29-65`), à l'étape des deltas : `reduceCost` soustrait du coût de la
donnée, plancher 0 — la rareté ne change jamais le coût ; `critBonus` s'additionne dans `critChanceBonus` ;
`addExhaust` lève `addsExhaust`. Deux `percentBonus` sur un même effet ne se composent toujours pas : `sharp` et
`spectral` s'additionnent, chacun sur la valeur à la rareté.

| Lecteur | Avec E2 |
|:---|:---|
| `CardInstance.currentCost` (`card_instance.dart:22`) | `effective.cost` — et donc ses lecteurs, sans qu'ils changent : `effect_resolver.dart:109`, `:134` ; `card_component.dart:56`, `:322` ; `card_text_renderer.dart:519` ; `ui_card.dart:71` ; `tutorial_engine.dart:376`, `:381` ; `tutorial/widgets/tutorial_cards_widget.dart:119-120`. La carte affiche le coût qu'elle demande |
| `DamageEffectStrategy` (`strategies.dart:36-40`, `:49-53`) | Passe `card.effective.critChanceBonus` à `DamagePipeline.calculate`. Les appels des ennemis (`turn_phase_manager.dart:109`) et du tutoriel (`tutorial_engine.dart:391`, critique forcé à 0) gardent 0 |
| `CardInstance.exhaustsOnPlay` | `type == power ‖ addsExhaust ‖ (isExhaust ∧ ¬removesExhaust)` |

Le soin (`strategies.dart:94-97`) ne lit pas `critChanceBonus` : `precise` ne s'offre qu'à une carte de dégâts (A9) et
dit « sur les dégâts de la carte » (§5.1).

### 4.3. Le prédicat

`ForgeRuneRules.isEligible(rune, card, catalog)` (`forge_rune_rules.dart:96-134`) — vrai si et seulement si, à la fois :

1. à 4. les conditions d'E1 sur le type, les effets propres visés et exclus, l'épuisement (`:108-117`) ;
5. le coût courant ≥ `requiresMinCost`, **coût calculé par l'applicateur sur `catalog`** (A15 — en partie 2, avec
   `reduceCost`) ;
6. la symétrie des exclusions (`:120-130`) ;
7. **`rune.minFusionRank ≤ card.rarity.fusionRank`** — la carte passée est celle qui reçoit la rune : la carte
   fusionnée, au rang **atteint**, pour l'offre ; la carte elle-même pour le Puits et la boutique ;
8. **la carte ne porte pas `rune.id`** (D3). La condition 7 d'E1 — le plafond atteint (`:132-133`, D75) — en devient un
   cas et disparaît : aucune rune portée ne se repropose.

**Ses lecteurs**, et eux seuls : le tirage (§4.4), donc l'offre de fusion et les pré-forgées ; les remplaçantes du Puits
(§4.8). Ses deux lecteurs du feu disparaissent avec lui (`forge_upgrade_dialog.dart:83-94`,
`rest_card_selection_screen.dart:42-53`). Une carte `unique` (`fusionRank` 0) n'a jamais de rune éligible.

**La borne `boundLevel`** (`forge_upgrade_data.dart:277-284`, D72) garde une fonction et change de lecteurs : la fusion
(`consolidate`), le tirage des pré-forgées, l'affûtage (`canSharpen`), le Puits (`wellLevel`). Le prédicat ne la lit
plus ; `fusionOptionsFor` et le tirage du feu disparaissent.

### 4.4. Le tirage

```dart
// lib/game/services/forge_rune_rules.dart
static List<String> drawRunes(CardInstance card, Iterable<ForgeUpgradeData> catalog,
    Random rng, {required int count})
```

Fonction pure, sur ses entrées : jusqu'à `count` ids **distincts**, tirés pondérés par `weight`, sans remise, parmi les
runes du `catalog` que le prédicat accepte sur `card` — moins s'il y en a moins, aucun s'il n'y en a pas (D65).
**Deux lecteurs** : l'offre de fusion, `count: 3`, sur la carte fusionnée ; les pré-forgées, `count: 1` par rune, sur
la carte avec les runes déjà posées (A12). Le tutoriel l'appelle sur son registre (A18). Le tirage par `pools`
(`forge_upgrade_dialog.dart:96-160`, `shop_controller.dart:67-124`) disparaît.

### 4.5. Le geste de fusion

| Étape | Avec E2 |
|:---|:---|
| Le bouton « FUSIONNER (3) » (`deck_screen.dart:107-127`) | Inchangé ; `_MergeDialog` garde son étape 1, le choix de trois exemplaires quand il y en a plus (`:252-333`) |
| `_proceedToUpgrades` (`:215-237`) | Ne calcule plus ni capacité (`:224`) ni héritage (`:226-228`) : il appelle `_performMerge` |
| `_performMerge` (`:239-245`) | Appelle `mergeCards(ids)` et ferme `_MergeDialog` **sur la `CardInstance` rendue** — `Navigator.pop(carte)` à la place de `pop(true)` (`:244`) —, `null` si la fusion est refusée. Annuler à l'étape 1 ferme aussi sur `null` |
| `_confirmMerge` (`:156-180`) | `showDialog<bool>` (`:166-169`) devient `showDialog<CardInstance>` ; sur `null`, rien ; sinon il tire l'offre sur la carte rendue (ligne suivante) |
| L'étape 2, « Capacité de Forge Dépassée » (`:334-413`) | **Supprimée** |
| `DeckNotifier.mergeCards` (`deck_controller.dart:288-334`) | `mergeCards(List<String> selectedIds)` — l'héritage se calcule dedans, une fois (§4.6) ; rend la carte créée, ou `null` si la fusion est refusée (gardes `:289`, `:305-308` inchangées) |
| L'offre | **L'écran de deck la tire** — `_confirmMerge` (`deck_screen.dart:156-180`), couche Flutter —, sur la carte que `mergeCards` rend : `ForgeRuneRules.drawRunes(carte, registre.forgeUpgrades, Random(), count: 3)`, une fonction pure qui ne lit ni n'écrit aucun état ; l'offre est passée au dialogue. L'état ne change que par `DeckNotifier` : `mergeCards`, puis `addForgeUpgrade` (A1, tranché par l'orchestrateur au tour 2). **Offre vide** : pas de dialogue de choix ; `deckMergeSuccess`, **puis** `forgeNoEligibleRune` (A1) |
| Le choix | `ForgeUpgradeDialog(card, offer)` : la carte fusionnée et une ligne par rune offerte, au niveau 1 ; ni annulation, ni retour, ni relance, ni fente achetée (A1, A2) ; le choix écrit `id:1` par `addForgeUpgrade` (`:344-354`) |
| La fin | Offre non vide : après le choix, la notification `deckMergeSuccess` d'aujourd'hui (`deck_screen.dart:171-179`) ; offre vide : la ligne « L'offre » |

Ce que `ForgeUpgradeDialog` perd : `ForgeSlot` et sa relance (`forge_upgrade_dialog.dart:18-30`), la capacité (`:46`,
`:51`), la session (`:53-77`), les tirages (`:80-221`), la relance et l'achat de fente (`:223-264`, `:300-303`,
`:431-435`), le bouton Annuler (`:472-478`). `lib/ui/widgets/forge/forge_buy_slot_button.dart` est supprimé ;
`ForgeCardPreview` perd la capacité (`forge_card_preview.dart:10`, `:37`, `:80-81`, `:100`) ; `ForgeSlotRow` perd sa
relance (`forge_slot_row.dart:108-109`, `:168-205`) et devient la ligne de rune des trois écrans — fusion, affûtage,
Puits —, son bouton recevant son libellé et son état. Le gabarit plein écran d'ADR-039 D4 reste.

**La fusion reste gratuite** (D32).

### 4.6. L'héritage

`mergeCards` garde `ForgeRuneRules.consolidate` des runes des trois exemplaires (`deck_controller.dart:314-315`) — la
somme par id, bornée par `maxLevel` (A9 de la spec E1), une rune exclue par une rune gardée avant elle écartée (E-S3) —
et **supprime la troncature** (`:317-321`) : aucun plafond de runes par carte (D13). La branche `isStackable` de
`consolidate` (`forge_rune_rules.dart:49`) disparaît : `boundLevel` donne déjà 1 à une rune de plafond 1.

```
Trois Frappes peu communes :  sharp:3  ·  sharp:1  ·  burning:1
                         ⟹   Frappe rare :  sharp:4  ·  burning:1  ·  + une rune neuve parmi trois (hors sharp, burning)
```

Trois exemplaires runés différemment donnent une carte à quatre runes ; runés pareil, deux runes dont une haute : le
choix *s'étaler ou concentrer* est celui du joueur (brainstorm §4.2).

### 4.7. L'affûtage

| Étape | Avec E2 |
|:---|:---|
| `RestScreen` (`lib/ui/screens/rest_screen.dart`) | L'option « FORGER » (`:162-168`) devient « AFFÛTER », **inactive avec son motif** quand aucune carte du deck n'a de rune affûtable ; `_upgradeCard` (`:43-73`) devient l'affûtage ; `_leave` (`:105-109`) perd `clearForgeSession`. L'exclusivité des trois options (`_actionTaken`) tient « une fois par visite » (A4) ; `canPop: _actionTaken` (`:121`) devient `canPop: false` avec un `onPopInvokedWithResult` qui, une action faite, appelle `_leave` — le retour système résout alors le nœud comme « Continuer » (A4, mécanisme) |
| `RestCardSelectionScreen` (`rest_card_selection_screen.dart`) | Le mode forge (`isForge`, `:19`, `:31-68`) devient le mode affûtage : le refus d'une carte pleine (`:32-40`) et celui d'une carte sans rune éligible (`:42-53`) font place à un refus unique, une carte sans rune affûtable, grisée, refusée au toucher avec `sharpenNothingOnCard` |
| Le dialogue d'affûtage (neuf, `lib/ui/widgets/forge/`) | La carte, puis une ligne par rune portée (`levelsOf`) : son nom, son niveau et le suivant, `getDescription(1, …, carried: niveau)` — le gain marginal —, et « Affûter — `coût` or », inactif au plafond (« Niveau maximal ») ou faute d'or ; Annuler ramène à la sélection. **« Affûter » appelle `sharpenRune`, puis ferme le dialogue sur la rune affûtée ; la sélection se ferme à son tour et rend la carte et la rune à `RestScreen`**, qui passe `_actionTaken` à vrai — les précédents de la forge, `forge_upgrade_dialog.dart:266-272` (le choix écrit, puis le dialogue fermé sur lui) et `rest_card_selection_screen.dart:61-67` (la sélection fermée sur la carte et la rune). Un second affûtage n'est donc jamais offert dans la même visite : ni dans le dialogue, fermé, ni à l'écran du feu, dont les options ont disparu |
| L'opération | `RunController.sharpenRune(cardId, runeId)` → `GoldManager` : refuse si la rune est au plafond ou l'or insuffisant ; sinon dépense, puis réécrit la référence `id:n` en `id:n+1` à sa place (`setForgeUpgrades`, `deck_controller.dart:357-366`) |

```dart
// lib/game/services/forge_rune_rules.dart
static const sharpenBaseCost = 50;                                  // b, D63
static int sharpenCost(int level) => sharpenBaseCost * level;       // D20
static bool canSharpen(ForgeUpgradeData rune, int level) =>
    rune.boundLevel(1, carried: level) >= 1;                        // maxLevel respecté
```

| Niveau porté | 1 | 2 | 3 | 4 | n |
|:---|---:|---:|---:|---:|---:|
| Coût pour monter d'un niveau | 50 | 100 | 150 | 200 | 50 n |

**Ce qui se monte** : `sharp`, `hardened`, `burning`, `shocking`, `spectral` sans plafond ; `precise` jusqu'à 10 ;
jamais `eco`, `quick`, `freezing`, `enduring`, `cheap`, au plafond dès le niveau 1. Le pari « affûter avant de
fusionner » reste sans taxe (D32 ; brainstorm §12, ligne 2).

### 4.8. Le Puits d'échange

**Le placement** — `MapContentPlacer.placeSpecialEvents` (`lib/services/map/map_content_placer.dart:23-37`) : la
condition `random.nextDouble() < 0.25` (`:24`) devient `act % 3 == 0` (D22) ; le choix du nœud ne change pas — un
combat ou un événement des étages 3 à 7 (`:25-30`), qui garde son `originalType`. L'Autel est placé avant (`:10-21`) :
un nœud devenu Autel n'est plus candidat, comme dans le script (`:1111-1136`). Le nœud garde son id `forgeFusion`
(A17).

**L'écran** — `ForgeFusionScreen` réécrit (A5) :

1. les cartes qui portent au moins une rune ;
2. la carte choisie, ses runes : la rune à **donner** ;
3. **toutes** les remplaçantes : `ForgeRuneRules.wellOptions(card, givenId, catalog)` — les runes que le prédicat accepte
   sur la carte **sans la rune donnée**, la rune donnée exclue —, chacune avec son niveau d'arrivée, sa description sur
   la carte et « Échanger — `coût` or » ; inactive faute d'or ;
4. « Échanger » appelle `exchangeRune` et, **dans le même geste**, passe l'état local à « échangé » — comme
   `_actionTaken` au feu : les cartes et les remplaçantes disparaissent, l'écran ne propose plus que la sortie (un
   échange par visite, A5). Le Puits n'ouvre aucun dialogue au-dessus de lui : le choix se fait dans l'écran même, et
   aucun second échange n'y reste offert ;
5. le retour système : avant tout échange, il ferme l'écran sans résoudre le nœud — le joueur peut revenir, comme
   aujourd'hui ; après un échange, `canPop` passe à faux et le rappel `onPopInvokedWithResult` appelle `_leave`
   (`forge_fusion_screen.dart:84-87`) : le nœud est résolu, comme par le bouton de sortie (A5, mécanisme).

**L'opération** — `RunController.exchangeRune(cardId, givenId, receivedId)` → `GoldManager` : vérifie que la
remplaçante est dans `wellOptions`, dépense, puis remplace la référence donnée **à sa place** par
`receivedId:wellLevel`. `_onFusionPerform` (`forge_fusion_screen.dart:35-82`) et sa logique dans l'écran disparaissent.

```dart
static const wellBaseCost = 50;                                     // A6
static int wellCost(int givenLevel) => wellBaseCost * givenLevel;   // D6, D39
static int wellLevel(ForgeUpgradeData received, int givenLevel) =>
    received.boundLevel((2 * givenLevel + 1) ~/ 3);                 // D39
```

`(2L + 1) ~/ 3` est l'arrondi au plus proche de 2L/3 — deux tiers d'un entier ne tombent jamais sur une demie — et vaut
au moins 1 dès L = 1 : le « au moins 1 » de D39 tient par construction, et un test le garde.

| Niveau donné | 1 | 2 | 3 | 4 | 5 | 6 | 9 | 12 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| Niveau reçu, avant `maxLevel` | 1 | 1 | 2 | 3 | 3 | 4 | 6 | 8 |
| Coût | 50 | 100 | 150 | 200 | 250 | 300 | 450 | 600 |

*Tranchant* 9 troqué contre *Économe* : `eco` 1 (D39). `fusionOptionsFor` et `FusionOption`
(`forge_rune_rules.dart:4-18`, `:65-94`) disparaissent.

### 4.9. La boutique

**Les pré-forgées** — `_generateShopCardInstance` (`shop_controller.dart:189-228`) : le nombre tiré par acte
(`:200-212`) est borné par `finalRarity.fusionRank` à la place de la capacité (`:198`, `:214-216`) — une commune n'en
porte aucune (D28) ; chaque rune vient de `drawRunes(instance, catalog, rng, count: 1)` ; son niveau reste tiré
80 · 15 · 5 %, puis borné (`:139-156`), sans `isStackable` (`:140`). `_getEligibleUpgradesForPool`, `_rollUpgradeId`,
`_rollWeighted` (`:50-124`) disparaissent. Le prix (+20 or par rune, `:42`) ne change pas.

**La copie du deck** (D46, A11) — `initializeShop` (`:230-255`) tire `deckCopy` : une carte uniforme de
`DeckState.copyableCards`, recréée `CardInstance(data, rarity)` — même rareté, sans rune, identifiant neuf — ou `null`.
`ShopController.buyDeckCopy()` dépense `getCardPrice(deckCopy)` — 25 · 50 · 100 · 150 · 200 —, l'ajoute au deck et la
retire. `rerollCards` (`:309-331`) et `expandShop` ne la touchent pas. `ShopScreen` la montre **à part** des cartes en
vente (`lib/ui/screens/shop_screen.dart:348-370`), sous le libellé `shopDeckCopy`. Le Miroir magique (`:204-285`,
`cloneCard`, `shop_controller.dart:344-363`) ne change pas.

### 4.10. La capacité supprimée

Les sept lecteurs de la revue §2.1, re-mesurés :

| Lecteur | Aujourd'hui | Avec E2 | Partie |
|:---|:---|:---|:---:|
| `rest_card_selection_screen.dart:32-40` | Refuse une carte pleine au feu | Disparaît : l'affûtage ne pose pas de rune (§4.7) | 1 |
| `forge_upgrade_dialog.dart:46`, `:51`, `:393-398` | La capacité montrée à la forge | Disparaît (§4.5) | 1 |
| `deck_controller.dart:317-321` | Tronque l'héritage | Disparaît (§4.6) | 1 |
| `deck_screen.dart:202`, `:224`, `:230`, `:334-413` | Le dialogue d'héritage | Disparaît (§4.5) | 1 |
| `card_text_renderer.dart:362-365` ; `ui_card.dart:28`, `:47`, `:76`, `:107`, `:246` et `ui_card/card_rune_sockets.dart:7`, `:18` | `max(capacité, runes portées)` prises, dont des vides | **Une prise par rune portée, aucune vide** ; `UiCard.forgeCapacity` et `CardRuneSockets.totalSlots` disparaissent | 1 |
| `shop_controller.dart:198`, `:214-216` | Borne les pré-forgées | `finalRarity.fusionRank` (D28, §4.9) | 1 |
| `card_instance.dart:24-25` | Le relais | Supprimé | 1 |

Et la donnée qui les nourrissait : `CardData.baseMaxForgeUpgrades` et `forgeCapacityAt` (§3.4), le gabarit de carte de
l'éditeur (`lib/services/content_editor/entity_descriptor.dart:239`), les six signatures (§3.3).

### 4.11. `pools` et `stackable` supprimés

| Lecteur | Ce qu'il en fait | Avec E2 | Partie |
|:---|:---|:---|:---:|
| `forge_upgrade_dialog.dart:83-94` (`pools`) | Le ciblage du feu | Disparaît avec le tirage du feu (§4.5) | 1 |
| `forge_upgrade_dialog.dart:172` (`isStackable`) | Le tirage de niveau du feu | Disparaît | 1 |
| `forge_slot_row.dart:94-96` (`stackable`) | Le niveau écrit dans la fente | La règle des infobulles d'E1 : le niveau s'écrit quand `maxLevel` n'est pas 1 (`forge_upgrade_data.dart:257-260`) | 1 |
| `deck_screen.dart:284`, `:362` (`stackable`) | Le niveau dans le dialogue de fusion | `:284` : la même règle, par `parseRef` ; `:362` disparaît avec l'étape 2 | 1 |
| `shop_controller.dart:50-65` (`pools`), `:140` (`isStackable`) | Le ciblage et le niveau des pré-forgées | `drawRunes` ; niveau borné seul (§4.9) | 2 |
| `forge_rune_rules.dart:30-33` (`isStackable`), `:49`, `:80` | `consolidate`, `fusionOptionsFor` | `isStackable` supprimé ; `consolidate` sans branche (§4.6) ; `fusionOptionsFor` supprimé (§4.8) | 2 |
| `forge_rune_rules.dart:23`, `:100-102` | Commentaires | Réécrits | 2 |
| `ForgeUpgradeData` (§3.4) ; les huit fichiers ; `enduring.json:26` | Le champ, la donnée | Supprimés | 2 |
| `entity_descriptor.dart:331-335`, `:376`, `:382` | `requiredKeys: {'pools'}`, le gabarit | §6 | 2 |

**Le point du vérificateur.** Après E2 :

```
git grep -n -w pools     -- lib test assets tool
git grep -n -w stackable -- lib test assets tool
git grep -n -e forgeCapacity -e forgeCapacityAt -e baseMaxForgeUpgrades -- lib test assets tool
```

ne rendent que **trois homonymes**, sans rapport avec les runes : le commentaire de `CardData.compareByDisplayOrder`
(« les trois pools » d'affichage, aujourd'hui `card_data.dart:261`), la variable locale `pools` de
`test/unit/audio/flame_audio_backend_pool_test.dart`, et le commentaire de `StatusEffect.combine`
(`lib/models/status_effect.dart:108`, qui parle de `StatusEffect.isStackable`). La troisième commande ne rend rien. Les
tests qui nomment `pools` comme exemple de clé de liste (`test/unit/content_editor/known_values_test.dart:53-59`,
`field_kind_test.dart:69`, `fixtures.dart:53`, `entity_validator_test.dart:205`, `:595`,
`test/widget/content_editor/document_form_test.dart:84`) prennent une autre clé de rune, ou perdent seulement `pools`
pour les deux brouillons d'`entity_validator_test` (§8). `docs/` et `.obsidian_vault/`
gardent l'histoire.

**Les lecteurs que `git grep -w` ne voit pas** — un nom dérivé, que les trois commandes ne touchent pas :

| Nom | Lecteurs aujourd'hui | Avec E2 | Partie |
|:---|:---|:---|:---:|
| `isStackable` | `forge_rune_rules.dart:32` (définition), `:49` (`consolidate`), `:80` (`fusionOptionsFor`) ; `shop_controller.dart:140` ; `forge_upgrade_dialog.dart:172` | Supprimé avec tous ses lecteurs (§4.6, §4.8, §4.9, §4.5) | 1 (`:172`), 2 (le reste) |
| `totalMaxForgeUpgrades` | `forge_card_preview.dart:10`, `:17`, `:81`, `:100` ; `forge_upgrade_dialog.dart:46`, `:51`, `:395` | Supprimé : l'aperçu ne montre plus de capacité (§4.5) | 1 |
| `CardRuneSockets.totalSlots` | `ui_card/card_rune_sockets.dart:7`, `:12`, `:18` ; passé par `ui_card.dart:246` | Supprimé : une prise par rune (§4.10). La variable locale `totalSlots` du rendu Flame (`card_text_renderer.dart:365`) peut survivre, recalculée sur les runes portées | 1 |
| `_capacity` | `deck_screen.dart:202`, `:224`, `:230`, `:347`, `:376`, `:402` | Supprimé avec l'étape 2 (§4.5) | 1 |
| `fusionOptionsFor`, `FusionOption` | `forge_rune_rules.dart:6`, `:12`, `:70`, `:78`, `:86` ; `forge_fusion_screen.dart:35`, `:102`, `:112`, `:200`, `:279`, `:281`, `:302`, `:304`, `:367` ; `test/unit/forge_rune_rules_test.dart:144-190` | Supprimés avec la Forge de Fusion (§4.8) | 2 |

Une quatrième commande le garde, **résultat vide attendu** :

```
git grep -n -e totalMaxForgeUpgrades -e 'totalSlots:' -e 'this.totalSlots' -e 'isStackable(' \
  -e fusionOptionsFor -e FusionOption -e _capacity -- lib test
```

Ajustée par rapport à la proposition du vérificateur : `isStackable(` à la place de `ForgeRuneRules.isStackable`, qui
manquerait la définition (`forge_rune_rules.dart:32`) et les deux appels internes (`:49`, `:80`) — et ne prend pas
`StatusEffect.isStackable`, un champ jamais appelé ; `this.totalSlots` en plus de `totalSlots:`, pour le champ de
`CardRuneSockets` ; `_capacity` pour l'écran de deck. La variable locale du rendu Flame, `final int totalSlots =`, n'y
répond pas.

### 4.12. Ce que cela fait au jeu

**L'offre à la fusion** — ce que le prédicat accepte sur les cartes livrées, sans rune héritée :

| Cartes | Première fusion (peu commune, rang 1) | Deuxième (rare, rang 2) |
|:---|:---|:---|
| *Frappe*, *Frappe Lourde*, *Boule de Feu*, *Trait de Glace*, *Coup Empoisonné*, *Attaque Rapide*, *Balayage*, *Coup de Tonnerre* | `sharp`, `burning`, `freezing`, `shocking`, `cheap`, `precise`, `spectral` | les mêmes, `eco`, `quick` |
| *Cri de Guerre* | les mêmes et `hardened` | et `eco`, `quick` |
| *Défense*, *Mur de Fer*, *Éveil* | `hardened`, `cheap` | et `eco`, `quick` |
| *Potion de Soin* | `enduring`, `cheap` | et `eco`, `quick` (ni l'une ni l'autre avec `enduring`) |
| *Forme Démoniaque*, *Métallisation* | `cheap` | et `eco`, `quick` |
| *Concentration*, *Focalisation* | **aucune** | `quick` |
| Les six signatures (`unique`) | Ne fusionnent pas : aucune rune, jamais | — |

Brainstorm §8 (paragraphe D65) : « une Compétence d'armure n'a que `hardened` et `cheap` à sa première fusion » —
confirmé. Revue §11 S6 : **aucune carte de rang 1 ne porte `eco` ni `quick`** dans une partie neuve — ni par la fusion,
ni par la boutique, ni par le Puits.

**Les sources de rune** en `0.5.4` : la fusion (une rune), les pré-forgées de la boutique, les clones qui recopient
(boss « cartes », Miroirs) ; les niveaux montent par l'héritage et l'affûtage. Une commune ne porte jamais de rune. Les
cartes de classe n'en reçoivent plus (D7) : le feu était leur seule source — et leurs cinq prises vides disparaissent.

**La transition E2 → E3** (orchestration §7.2) : la forge du feu a disparu et la trouvaille n'existe pas encore. Les
doublons ne viennent que du boss « cartes », de la carte bonus du boss « XP » — une carte offrable tirée au hasard,
commune (`reward_controller.dart:186-193`, ajoutée au deck en `:217-218`) —, de la boutique (étal, copie du deck,
Miroir magique) et du Miroir de montée de niveau ; **les fusions sont rares en `0.5.4`**, donc les runes, l'affûtage et le Puits aussi. C'est voulu
(brainstorm §11, ligne E3 : la trouvaille vient après la fusion, son puits) ; la note de version le dit. Le pari
« affûter avant de fusionner » (revue §11 S4) s'allonge d'autant jusqu'en `0.5.5`.

### 4.13. Les frontières

| Frontière | Ce que le lot voisin trouve |
|:---|:---|
| **E1 → E2** | `pools`, `stackable` et la capacité en lecture, la forge du feu et la Forge de Fusion vivantes (D68) : E2 réécrit les deux écrans et supprime les trois. Le prédicat, `boundLevel`, `consolidate` borné et sans paire exclue, `currentCost` comme couture de `cheap` : E2 s'écrit dessus |
| **E2 → E3** | `canSharpen`, `boundLevel` et la réécriture `id:n → id:n+1` pour les sources d'affûtage de D42 — aucune ne se paie en or ; `fusionRank` lu par le prédicat, G1 et la borne des pré-forgées, pour la DDA de D47 ; les fusions rares, que la trouvaille nourrit |
| **E2 → E4** | Les signatures restent des cartes `unique`, sans rune ni prise ; `baseMaxForgeUpgrades` n'existe plus |
| **E2 → vague 5** | `CardDelta` à six sortes, la couture des évolutions de signature (ADR-105 D1) ; à examiner avec les cartes de lot et la relance qui les mesure : `spectral` sur une carte qui s'épuise déjà, et la paire `spectral` / `enduring`, aujourd'hui tenue par la seule préséance (A9, A10) |

### 4.14. Ce qui ne change pas

- Le format `id:niveau` de `CardInstance.forgeUpgrades` ; `addForgeUpgrade`, `setForgeUpgrades`.
- L'applicateur sur les huit runes, G1, G2, `percentBonus` ; les stratégies d'effet (ADR-061) ; `createStatus`.
- Les gardes de `mergeCards` : trois exemplaires d'une même carte à une même rareté, jamais au-delà de légendaire.
- Le repos (30 %), l'oubli, l'Autel, le Miroir magique, le soin et la purge de la boutique, ses prix.
- Les clones (boss « cartes », Miroirs) qui recopient les runes.

---

## 5. Textes joueur

### 5.1. Les runes neuves

| Rune | Nom | Description — français | Description — English | Emoji · icône · couleur |
|:---|:---|:---|:---|:---|
| `cheap` | Allégé · Light | `Coûte {val} Mana de moins (jamais sous 0)` | `Costs {val} less Mana (never below 0)` | 🪙 · `savings_rounded` · `tealAccent` |
| `precise` | Précis · Precise | `+{val}% de chance de critique sur les dégâts de la carte` | `+{val}% critical chance on the card's damage` | 🎯 · `gps_fixed_rounded` · `pinkAccent` |
| `spectral` | Spectral · Spectral | `+{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier}) ; la carte s'épuise` | `+{val} Damage on the card (+{percent}% of base, at least +{tier}); the card exhausts` | 👻 · `blur_on_rounded` · `purpleAccent` |

Les deux tables de `forge_slot_row.dart:35-80`, devenues `runeIcons` et `runeColors` (A19), gagnent ces trois icônes et
ces trois couleurs.

### 5.2. `{val}`, pour toute sorte chiffrée

`ForgeUpgradeData.getDescription` (`forge_upgrade_data.dart:223-251`) : `{val}` est ce que la rune ajoute à **cette**
carte, sur son premier delta chiffré, au-delà de ce que la carte porte déjà — `percentBonus` : le bonus marginal
(spec E1 §5.1) ; `addEffect` : `valuePerLevel × L` ; `reduceCost` : la baisse de coût marginale ; `critBonus` :
`valuePerLevel × L`. `{percent}` et `{tier}` ne changent pas. Les cinq descriptions à effet ajouté passent de `{tier}` à
`{val}`, sans changer à l'écran :

| Rune | Français | English |
|:---|:---|:---|
| `burning` | `Applique {val} Brûlure` | `Applies {val} Burn` |
| `freezing` | `Applique {val} Gel` | `Applies {val} Freeze` |
| `shocking` | `Applique {val} Électrocution` | `Applies {val} Shock` |
| `quick` | `Pioche +{val} carte(s)` | `Draw +{val} card(s)` |
| `eco` | `Gagne +{val} Mana à l'utilisation` | `Gains +{val} Mana on play` |

### 5.3. Les chaînes ARB

Déclarées dans `app_en.arb` (gabarit) et `app_fr.arb` ; `flutter gen-l10n` régénère les trois `app_localizations*.dart`.
Tout texte que le lot écrit ou réécrit dans `lib/ui/` passe par elles.

| Clé | Français | English |
|:---|:---|:---|
| `fusionRuneTitle` | `FUSION — CHOISISSEZ UNE RUNE` | `MERGE — CHOOSE A RUNE` |
| `fusionRuneSubtitle` | `La carte garde les runes de ses trois exemplaires et en reçoit une de plus, au niveau 1.` | `The card keeps its three copies' runes and gains one more, at level 1.` |
| `fusionRuneChoose` | `Choisir` | `Choose` |
| `restCampSharpen` *(remplace `restCampForge`)* | `AFFÛTER` | `SHARPEN` |
| `restCampSharpenDesc` *(remplace `restCampForgeDesc`)* | `Une rune d'une de vos cartes gagne un niveau, contre de l'or.` | `One rune on one of your cards gains a level, for gold.` |
| `restCampSharpenNone` | `Aucune rune de votre deck ne peut gagner de niveau.` | `No rune in your deck can gain a level.` |
| `restCampSharpenTitle` *(remplace `restCampForgeTitle`)* | `AFFÛTER UNE RUNE` | `SHARPEN A RUNE` |
| `restCampSharpenSubtitle` *(remplace `restCampForgeSubtitle`)* | `Choisissez une carte, puis la rune qui gagne un niveau.` | `Choose a card, then the rune that gains a level.` |
| `sharpenNothingOnCard` | `Aucune rune de cette carte ne peut gagner de niveau.` | `No rune on this card can gain a level.` |
| `sharpenAction` (`{cost}`) | `Affûter — {cost} or` | `Sharpen — {cost} gold` |
| `runeMaxLevel` | `Niveau maximal` | `Max level` |
| `restCampSnackbarSharpen` (`{runeName}`, `{level}`, `{cardName}`) *(remplace `restCampSnackbarForge`, sans lecteur)* | `{runeName} passe au niveau {level} sur {cardName} !` | `{runeName} reaches level {level} on {cardName}!` |
| `wellTitle` — titre de l'écran, en capitales comme aujourd'hui (`forge_fusion_screen.dart:119`) | `PUITS D'ÉCHANGE` | `EXCHANGE WELL` |
| `wellName` — la carte du monde, en casse mixte comme ses voisines (`app_fr.arb:48-67`) | `Puits d'échange` | `Exchange Well` |
| `wellDesc` | `Échangez une rune d'une carte contre une autre, contre de l'or.` | `Swap one of a card's runes for another, for gold.` |
| `wellEmpty` | `Aucune carte de votre deck ne porte de rune à échanger.` | `No card in your deck carries a rune to swap.` |
| `wellPickCard` | `Choisissez une carte, puis la rune à donner.` | `Choose a card, then the rune to give up.` |
| `wellNoOption` | `Aucune autre rune ne peut la remplacer.` | `No other rune can replace it.` |
| `wellReceive` (`{level}`) | `Reçue au niveau {level}` | `Received at level {level}` |
| `wellExchange` (`{cost}`) | `Échanger — {cost} or` | `Swap — {cost} gold` |
| `wellDone` (`{oldRune}`, `{newRune}`, `{level}`) | `{oldRune} devient {newRune} (niveau {level}).` | `{oldRune} becomes {newRune} (level {level}).` |
| `wellLeave` | `Quitter le Puits` | `Leave the Well` |
| `shopDeckCopy` | `COPIE DE VOTRE DECK` | `COPY FROM YOUR DECK` |
| `shopDeckCopyDesc` | `Même rareté, sans ses runes.` | `Same rarity, without its runes.` |
| `mergeRunesLabel` (`{runes}`) *(§5.7)* | `Runes : {runes}` | `Runes: {runes}` |
| `mergeRunesNone` *(§5.7)* | `Runes : aucune` | `Runes: none` |

`forgeNoEligibleRune` garde son texte et change de lecteur : l'écran de deck, après une fusion sans offre, à la suite
de `deckMergeSuccess` (A1). Les textes en ligne que la réécriture retire disparaissent avec leur code (« CAPACITÉ »,
« Fusionner Nx … »… ; ceux qui nomment la forge sont listés un à un en §5.7). Le message de succès du feu, écrit en ligne
(`rest_screen.dart:65-70`), devient `restCampSnackbarSharpen`.

### 5.4. La carte du monde

L'infobulle du nœud (`lib/ui/widgets/map/map_node_widget.dart:54-61`) lit `wellName` pour son titre et `wellDesc`
pour sa description ; la légende (`lib/ui/widgets/map/map_legend.dart:114-120`) lit `wellName` — en casse mixte, comme
toutes les entrées de la légende et des infobulles (`app_fr.arb:48-67`). Seul l'en-tête de l'écran du Puits lit
`wellTitle`, en capitales comme l'en-tête d'aujourd'hui (`forge_fusion_screen.dart:119`). L'icône et la couleur du nœud
(`map_node_widget.dart:106-109`) ne changent pas.

### 5.5. Le tutoriel

| Où | Avec E2 — français | Avec E2 — English |
|:---|:---|:---|
| Étape des nœuds, `lib/tutorial/tutorial_data.dart:90-97` (fr), `:76-82` (en) — Boutique | « … agrandir le stock, cloner ou acheter la copie d'une de vos cartes. Aucune relique. » | "… expand the stock, clone a card or buy a copy of one of yours. No relics." |
| — Repos | « soigner 30 % de vos PV max, monter une rune d'un niveau contre de l'or, **ou retirer une carte de votre deck**. » | "heal 30% of your max HP, raise a rune by one level for gold, **or remove a card from your deck**." |
| — Forge de Fusion | « 🧩 Puits d'échange : échanger une rune d'une carte contre une autre, contre de l'or — tous les trois actes. » | "🧩 Exchange Well: swap one of a card's runes for another, for gold — every third act." |
| Étape « La Fusion de Cartes », `tutorial_data.dart:287-292` (fr), `:272-276` (en), dernier paragraphe | « Les runes des trois exemplaires sont toutes conservées — une même rune additionne ses niveaux — et la carte fusionnée **en reçoit une de plus, au choix parmi trois**, au niveau 1 ; Véloce et Économe n'apparaissent qu'à partir de la deuxième fusion. Vos cartes de classe sont uniques, et une carte unique ne fusionne jamais. **Le Puits d'échange est un système distinct et payant** — un nœud dédié de la carte du monde, à ne pas confondre avec cette fusion-ci, qui reste gratuite. » | "The runes of the three copies are all kept — the same rune adds up its levels — and the merged card **gains one more, chosen among three**, at level 1; Quick and Eco only appear from the second merge. Your class cards are unique, and unique cards never merge. **The Exchange Well is a separate, paid system** — a dedicated map node, not to be confused with this free merging." |
| `lib/tutorial/widgets/tutorial_node_types_widget.dart:48-57` — Boutique | « Achetez des cartes ou la copie d'une des vôtres, relancez le stock, purgez-en une. Aucune relique. » | "Buy cards or a copy of yours, reroll stock, purge a card. No relics." |
| — `:58-65`, Repos | « Soignez 30 % des PV max, affûtez une rune ou retirez une carte. » | "Heal 30% max HP, sharpen a rune, or remove a card." |
| — `:81-88`, Forge de Fusion | Titre « Puits d'échange » ; « Échangez une rune contre une autre, contre de l'or. » | Title "Exchange Well"; "Swap a rune for another, for gold." |
| `lib/tutorial/widgets/tutorial_merge_widget.dart:255-266`, après la fusion | « Même coût, rareté supérieure. » puis « Choisissez une rune : » et les runes offertes ; après le choix « Rune ajoutée : {nom} » ; sans offre « Aucune rune ne peut s'ajouter à cette carte. » | "Same cost, higher rarity." then "Choose a rune:"; "Rune added: {name}"; "No rune can be added to this card." |

Le tutoriel garde sa convention de textes en ligne (`lib/tutorial/`). « La rareté ne change jamais le coût en Mana »
(`:283`, `:268`) reste vrai : `cheap` change le coût, pas la rareté.

### 5.6. Ce qui ne change pas

Les noms, emoji, icônes et couleurs des huit runes ; les descriptions de `sharp`, `hardened`, `enduring` ; le texte des
cartes ; `deckMergeSuccess`, `forgeNoEligibleRune`.

### 5.7. Les textes qui nomment encore la forge *(tranché par l'orchestrateur au tour 2)*

**6** : un texte que le joueur lit et qui nomme une forge qui n'existe plus est renommé — « Runes », ou l'équivalent
juste —, en `_fr` et `_en` s'il passe par l'ARB ; un texte qui ne s'affiche jamais au joueur ne change pas ; les noms
de code restent (A17). Relevé par une recherche de `forge`, `Forge` et `FORGE` dans les chaînes de `lib/` et dans les
deux ARB :

| Texte | Où | Sort | Partie |
|:---|:---|:---|:---:|
| « === AMÉLIORATIONS DE LA FORGE === » / « === FORGE UPGRADES === », en-tête des runes dans l'infobulle Flame | `lib/game/components/card_component.dart:443` | « === RUNES === », le même dans les deux langues, en ligne comme aujourd'hui (couche Flame, hors de la règle ARB de §5.3, qui vise `lib/ui/`) | 1 |
| « Forge: {runes} », sous-titre d'un exemplaire à l'étape 1 du dialogue de fusion, et son cas vide « (Sans amélioration) » / « (No upgrade) » | `lib/ui/screens/deck_screen.dart:293`, `:277` | Deux clés ARB : `mergeRunesLabel` (`{runes}`) « Runes : {runes} » / « Runes: {runes} », et `mergeRunesNone` « Runes : aucune » / « Runes: none » | 1 |
| « Capacité de Forge Dépassée » | `deck_screen.dart:338` | Disparaît avec l'étape 2 (§4.5) | 1 |
| « Cette carte a atteint sa capacité maximale d'améliorations de forge ! » / « …maximum forge upgrades capacity! » | `lib/ui/screens/rest_card_selection_screen.dart:35-36` | Disparaît avec le refus de la carte pleine (§4.7) | 1 |
| « AMÉLIORATION FORGE » / « FORGE UPGRADE » | `lib/ui/widgets/forge_upgrade_dialog.dart:335` | `fusionRuneTitle` (§5.3) | 1 |
| « OFFRES DE LA FORGE » / « AVAILABLE FORGE SLOTS » | `forge_upgrade_dialog.dart:409` | Disparaît : le titre `fusionRuneTitle` dit le choix | 1 |
| « Forger » / « Forge », bouton d'une fente | `lib/ui/widgets/forge/forge_slot_row.dart:212` | Le libellé que chaque écran passe à la ligne de rune : `fusionRuneChoose`, `sharpenAction` (partie 1), `wellExchange` (partie 2) | 1, 2 |
| `restCampForge`, `restCampForgeDesc`, `restCampForgeTitle`, `restCampForgeSubtitle` | `lib/l10n/app_fr.arb:187-188`, `:195-196` ; `app_en.arb:445-446`, `:469-470` | Remplacées par `restCampSharpen*` (§5.3) | 1 |
| `restCampSnackbarForge`, sans lecteur | `app_fr.arb:193` ; `app_en.arb:456-457` | Remplacée par `restCampSnackbarSharpen` (§5.3) | 1 |
| « FORGE DE FUSION » / « FUSION FORGE », en-tête | `lib/ui/screens/forge_fusion_screen.dart:119` | `wellTitle` (§5.3) | 2 |
| « Forge de Fusion » / « Fusion Forge », infobulle et légende | `lib/ui/widgets/map/map_node_widget.dart:57` ; `map_legend.dart:118-119` | `wellName` (§5.4) | 2 |
| La prose du tutoriel | `lib/tutorial/tutorial_data.dart:78`, `:82`, `:92`, `:96`, `:272`, `:274`, `:287`, `:290` ; `lib/tutorial/widgets/tutorial_node_types_widget.dart:63-64`, `:84-85` | Réécrite (§5.5) | 1 (repos, fusion), 2 (Puits) |

**Ne changent pas**, jamais montrés au joueur : le libellé « Amélioration de forge » de l'éditeur de contenu
(`lib/services/content_editor/entity_descriptor.dart:329`), un outil du menu de debug, absent d'une build de release
(`lib/ui/screens/home_screen.dart:176`) ; le journal de `ForgeUpgradeData.getById` (`lib/models/data/forge_upgrade_data.dart:318`) ;
la catégorie interne `'forgeUpgrade'` d'un élément de sauvegarde manquant (`:340`), jamais affichée — la boîte des
éléments manquants ne montre que leurs noms (`lib/ui/screens/home_screen.dart:61-63`).
La ligne « Slots de forge bonus » du menu de debug (`debug_run_tab.dart:60`) disparaît avec `bonusForgeSlots` (A3).

---

## 6. L'éditeur de contenu

| Élément | Avec E2 |
|:---|:---|
| Descripteur de rune, `requiredKeys` (`entity_descriptor.dart:331-335`) | `{'pools'}` → `const {}` : `minFusionRank`, comme `maxLevel` et `deltas`, est exigé par `ForgeUpgradeData.fromJson`, que la famille 7 appelle — un fait à un seul endroit (spec E1 §6). Le commentaire suit |
| `enumKeys` (`:338`) | `deltas[].type` lit `CardDelta.typeNames`, six sortes, sans changement de code |
| `vocabularyKeys` | Inchangées ; `icon` et `color` admettent les noms des trois fichiers neufs, lus sur le disque. Le commentaire (`:342-345`) suit : les noms sont traduits par `runeIcons` et `runeColors` (`lib/ui/widgets/forge/rune_style.dart`, A19), qui connaissent onze runes |
| Gabarit de rune (`:372-389`) | Perd `"pools": ["common"]` (`:376`) et `"stackable": true` (`:382`) ; gagne `"minFusionRank": 1` |
| Gabarit de carte (`:228-240`) | Perd `"baseMaxForgeUpgrades": 1` (`:239`) |

Les deux gabarits restent valides (`test/unit/content_editor/entity_validator_test.dart` l'exige de tous).
`minFusionRank` s'édite comme un nombre.

---

## 7. La sauvegarde

**Rien à migrer ; `SaveMigrator.currentVersion` ne bouge pas.** `RunState` perd quatre clés (§3.4), `CardData` — que
chaque carte sauvegardée embarque — perd `baseMaxForgeUpgrades` : une sauvegarde plus ancienne les porte, la lecture
les ignore. Les sauvegardes ne se transfèrent pas avant la `1.0.0` : rien de cela n'est testé ni annoncé.

---

## 8. Tests

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| Le modèle de rune | `test/unit/forge_upgrade_data_test.dart` | `minFusionRank` lu ; absent, 0, négatif, décimal refusés ; les trois sortes neuves lues, paramètre manquant ou ≤ 0 refusé ; `toJson` aller-retour sans `pools` ni `stackable` ; `{val}` sur `reduceCost` (marginal, plancher 0), `critBonus`, `addEffect` (valeur, pas niveau) |
| Les onze runes | `test/unit/forge_upgrades_catalog_test.dart` — un test par rune | `minFusionRank` (2 pour `eco`, `quick`, 1 pour les neuf autres) ; `maxLevel` (1 pour `eco`, `quick`, `freezing`, `enduring`, `cheap` ; 10 pour `precise` ; `null` pour les cinq autres) ; éligibilité, deltas et `weight` exacts (100, 100, 80, 80, 80, 60, 40, 30, 50, 50, 50) ; aucune ne déclare `pools` ni `stackable` ; les trois neuves sans `eligibleCardTypes`. **La matrice de §4.12** : pour les 23 cartes livrées, sans rune, l'ensemble accepté au rang 1 et au rang 2 ; les six signatures n'ont rien |
| Le prédicat | `test/unit/rune_eligibility_test.dart` | `minFusionRank` contre le rang de la carte passée ; une rune portée, plafonnée ou non, refusée ; le coût courant lu après `cheap` sur le catalogue reçu (une rune de test à `requiresMinCost: 1` refusée sur une carte à 1 qui porte `cheap`) ; les conditions d'E1 inchangées |
| Le tirage | `test/unit/forge_rune_rules_test.dart` | `drawRunes` : au plus `count` ids distincts, tous éligibles ; moins s'il y en a moins ; aucun s'il n'y en a pas ; la pondération sur de nombreux tirages ; `consolidate` sans branche (`enduring` gardé à 1 par la borne) ; le groupe `stackable` (`:58-84`), les cas « non cumulable » (`:94-104`) et le groupe `fusionOptionsFor` (`:144-190`) supprimés ; `:109-111` (`legacy:1` + `legacy:1` → `legacy:2`) **reste**, renommé « une rune absente du registre n'a pas de plafond » — ce comportement survit à E2 (`_bounded`, `forge_rune_rules.dart:62-63`) ; `sharpenCost`, `canSharpen` ; `wellLevel` — la table de §4.8, L = 1 → 1, `sharp` 9 → `eco` 1 ; `wellCost` ; `wellOptions` — la rune donnée exclue, l'éligibilité jugée sans elle (`enduring` donné → `eco` possible sur une rare), le rang de la carte |
| L'applicateur | `test/unit/effective_card_test.dart` | `reduceCost` : coût − 1, plancher 0, la rareté sans effet ; `critBonus` additionné ; `addExhaust` ; `sharp` et `spectral` additionnés sur la base à la rareté |
| La résolution | `test/unit/rune_resolution_test.dart` | `cheap` : le mana consommé est le coût réduit ; `precise` : `DamagePipeline.calculate` reçoit le bonus (à 100 % de critique effectif, le coup critique) ; `spectral` : +40 % de la base, au moins +1 |
| La chaîne de dégâts | `test/unit/damage_pipeline_test.dart` *(nouveau — aucun test ne vise `DamagePipeline` seul aujourd'hui)* | `critChanceBonus` ajouté au jet : à 100 points, le coup est critique ; 0 par défaut, le jet d'aujourd'hui |
| L'épuisement | `test/unit/deck_controller_test.dart:484-512` | Une carte `spectral` part à l'épuisement, même portant `enduring` (A10) ; les cas d'E1 inchangés |
| La fusion | `test/unit/deck_controller_test.dart:85-183`, `:185-222` ; `test/unit/decoupled_forge_test.dart:271`, `:287`, `:303` | `mergeCards(ids)` rend la carte ; quatre runes distinctes toutes gardées (le cas de capacité `:136-183` réécrit) ; les trois refus (`:185-222` — appels `:192`, `:210`, `:219`) passent à `mergeCards(ids)` et rendent `null` ; `sharp:3` + `sharp:1` + `burning:1` → `sharp:4`, `burning:1` ; la paire exclue d'E-S3 ; `eco:1` ×3 → `eco:1` |
| `decoupled_forge_test` | `test/unit/decoupled_forge_test.dart` | Le cas de capacité (`:90-109`) et la simulation de la Forge de Fusion (`:202-264`) supprimés — l'assistant `threeCopies` qui suit (`:266-269`) reste, les tests de `mergeCards` le lisent ; le cas non cumulable (`:303`) devient « plafond 1 » ; `{val}` (`:141-171`) étendu aux sortes neuves |
| `CardRarity` | `test/unit/card_rarity_test.dart` | Les cas de capacité (`:49-65`) supprimés ; `fusionRank` et `multiplier` inchangés |
| Les prises | `test/widget/ui_card_rune_sockets_test.dart` | Une prise par rune portée, aucune vide ; une carte de classe sans rune n'en montre aucune (`:69-86` réécrits) ; l'emoji par `parseRef` |
| Le badge | `test/widget/ui_card_values_test.dart` | Une carte `spectral` montre « Usage unique » ; une *Potion de Soin* `enduring` ne le montre plus |
| Le dialogue de fusion | `test/widget/forge_upgrade_dialog_test.dart` *(réécrit)* | Trois lignes pour trois runes offertes, une pour une ; ni Annuler ni retour ; le choix écrit `id:1` sur la carte et ferme ; aucune relance, aucun achat |
| L'écran de deck | `test/widget/deck_screen_test.dart` | La fusion de trois *Frappes* ouvre le dialogue, le choix pose la rune ; trois *Concentrations* communes fusionnent sans dialogue de choix, avec `deckMergeSuccess` puis `forgeNoEligibleRune`, dans cet ordre ; plus d'étape « Capacité » ; les cas d'aujourd'hui (`:58-170`) gardés |
| Le feu | `test/widget/rest_screen_test.dart:101-220` | Trois options, « AFFÛTER » à la place de « FORGER » ; inactive avec son motif sans rune affûtable ; le parcours d'affûtage notifie (`:157-190` réécrit) ; **D14** : après un affûtage, les trois options disparaissent et seul « Continuer » reste. **Le retour système** (A4) — `RestScreen` poussé sur une vraie pile, au nœud courant d'une carte, puis `navigator.maybePop()`, sur le précédent de `test/widget/map_screen_test.dart:244-256` : après un repos, un affûtage ou un oubli, le nœud courant est `isCompleted` — la condition qui, sur la carte du monde, interdit d'y rentrer (`map_screen.dart:389-392`) — et l'écran est fermé ; `checkpointProvider` n'a avancé que d'un cran (`completeCurrentNode` le pousse,
`map_progression_manager.dart:45`) — pas de double `_leave` ; avant toute action, l'écran reste ouvert et le nœud non résolu |
| La sélection du feu | `test/widget/rest_card_selection_screen_test.dart` *(réécrit)* | Une carte sans rune affûtable grisée et refusée avec `sharpenNothingOnCard` ; une carte avec une rune affûtable ouvre le dialogue |
| Le dialogue d'affûtage | `test/widget/sharpen_rune_dialog_test.dart` *(nouveau)* | Une ligne par rune ; « Niveau maximal » pour `eco:1` ; le coût `50 × niveau` ; inactif faute d'or ; le gain marginal dans la description ; **un affûtage ferme le dialogue sur la rune affûtée ; aucun second affûtage n'est possible** — l'or n'est dépensé qu'une fois et une seule rune a monté d'un niveau |
| Les opérations payantes | `test/unit/run_controller_test.dart` | `sharpenRune` : dépense `50 × n`, écrit `id:n+1` à sa place, refuse au plafond et faute d'or sans rien toucher ; `exchangeRune` : dépense `50 × L`, remplace à sa place par `reçue:wellLevel`, refuse une remplaçante hors `wellOptions` ; les cas de session et d'achat de fente (`:189-249`) supprimés |
| Le Puits | `test/widget/forge_fusion_screen_test.dart` *(réécrit)* | Les cartes qui portent une rune ; les remplaçantes d'une rune ; **un échange par visite** (A5) : après un échange, les cartes et les remplaçantes disparaissent et seule la sortie reste — aucun second échange n'est possible, l'or n'est dépensé qu'une fois ; l'écran vide ; une rune sans remplaçante inactive. **Le retour système** (A5), de la même façon qu'au feu : après un échange, `maybePop()` ferme l'écran et le nœud courant est `isCompleted` ; sans échange, l'écran se ferme et le nœud courant reste non résolu |
| Le placement | `test/unit/map_content_placer_test.dart` *(nouveau, sur le modèle de `relic_exchange_test.dart`)* | Aux actes 3, 6, 9 : un nœud `forgeFusion`, étage 3 à 7, ancien combat ou événement ; aux actes 1, 2, 4, 5, 7 : aucun |
| La boutique | `test/unit/shop_controller_test.dart` | Une pré-forgée porte au plus `fusionRank` runes, distinctes, éligibles au rang (aucune commune runée ; jamais `eco` ni `quick` sous la rare) ; le niveau borné ; la copie tirée de `copyableCards`, même rareté, sans rune, au prix 25 · 50 · 100 · 150 · 200 ; `rerollCards` la garde ; `buyDeckCopy` l'ajoute et la retire ; deck sans carte copiable : pas de copie. Le cas « non cumulable au tier 1 » (`:460`) devient « plafond 1 » |
| L'écran de boutique | `test/widget/shop_screen_test.dart` | La copie se montre à part, sous `shopDeckCopy` |
| La persistance | `test/unit/run_state_persistence_test.dart:59-84`, `:120-126` ; `test/unit/deck_state_persistence_test.dart:33` | Sans les champs de forge ; sans `baseMaxForgeUpgrades` |
| Le chargement | `test/unit/real_bundle_load_test.dart:38`, `:97-101` | 11 runes ; l'assertion `stackable` devient « `maxLevel` 1 : `cheap`, `eco`, `enduring`, `freezing`, `quick` » |
| Les ids hors de la donnée | `test/unit/rune_ids_in_code_test.dart:33` | `hasLength(11)` ; aucun des onze ids en littéral dans `lib/` |
| L'intégrité | `test/unit/referential_integrity_test.dart` | Chaque `icon` et chaque `color` de rune livrée est une clé de `runeIcons` et de `runeColors` (`lib/ui/widgets/forge/rune_style.dart`, A19) |
| L'éditeur | `test/unit/content_editor/entity_descriptor_test.dart:239`, `:264`, `:270` ; `entity_validator_test.dart`, `field_kind_test.dart`, `known_values_test.dart`, `fixtures.dart`, `document_form_test.dart` | Les clés des deux gabarits ; `minFusionRank: 0` refusé par la famille 7 ; les exemples de clé de liste sans `pools` |
| Les fichiers réels dans l'éditeur | `test/unit/content_editor/shipped_entities_round_trip_test.dart` | Inchangé : les onze runes valident et se réécrivent à l'identique |
| Le tutoriel | `test/tutorial/tutorial_engine_test.dart:348-360`, `:504-530` ; `test/widget/tutorial_merge_transition_test.dart` | La fusion tire une offre éligible de trois runes au plus sur le registre du tutoriel ; le choix pose `id:1` ; la carte semée est la première dont la fusion offre une rune ; sans offre, l'étape le dit ; le passage d'étape ne lève rien |

**Les tests qui suivent sans changer ce qu'ils vérifient** — la liste complète, mesurée :

| Ce qui change sous eux | Où |
|:---|:---|
| Une rune construite en Dart avec `pools:` ou `stackable:` — le paramètre disparaît ; `minFusionRank` prend 1 par défaut (A8) | `test/unit/decoupled_forge_test.dart:41`, `:55`, `:69`, `:82`, `:84` ; `effective_card_test.dart:39` ; `forge_rune_rules_test.dart:10-20` (l'assistant `_rune`), `:51` ; `rune_eligibility_test.dart:27` ; `save_catalog_lookups_test.dart:111` ; `run_state_persistence_test.dart:38` ; `deck_state_persistence_test.dart:53` ; `shop_controller_test.dart:373`, `:491-492` ; `test/widget/ui_card_rune_sockets_test.dart:107` ; `test/widget/forge_fusion_screen_test.dart:52`, `:67`, `:80`, `:82` (réécrit, §8) |
| Une rune lue par `fromJson` sans `minFusionRank` — la clé devient obligatoire | `test/unit/forge_upgrade_data_test.dart:9-17` (`_json`, dont `pools` `:11`) ; `test/unit/content_editor/fixtures.dart:47-58` (`fixtureRune`, dont `pools` `:53`) ; `test/unit/forge_rune_rules_test.dart:58-84` (le groupe `stackable`, supprimé) ; `test/unit/content_editor/entity_validator_test.dart:595-596` — le brouillon de couleur, dont la seconde attente (`:602`) ne veut aucune faute et atteint donc `_construct` : en **partie 1** il gagne `minFusionRank` et garde `pools`, que `requiredKeys` exige encore ; en **partie 2** il perd `pools` |
| Un brouillon qui n'atteint pas `fromJson` | `test/unit/content_editor/entity_validator_test.dart:205-206` : le validateur s'arrête à la première famille en échec (`lib/services/content_editor/entity_validator.dart:30-31`, boucle `:87-100`) et ce brouillon échoue sur l'énumération (`_enums`, `:89`) avant `_construct` (`:96`) — il n'a pas besoin de `minFusionRank` ; il ne fait que perdre `pools`, en **partie 2**, pour la commande de contrôle (§4.11) |
| Une carte commune, que la condition 7 du prédicat refuse désormais | `test/unit/rune_eligibility_test.dart:38-57` (`_card`, `rarity: CardRarity.common` en `:51`) : en **partie 1**, avec `minFusionRank`, `_card` passe au rang 1 (`uncommon`), sans quoi la condition 7 (§4.3) refuse toute rune et ses cas positifs basculent |
| Ce qu'une rune déclare, sous forme comparable | `test/unit/forge_upgrades_catalog_test.dart:14-48` (`_declared`, `_rune` : `pools`, `stackable`), `:83`, `:92`, `:120`, `:125`, `:137` (§8 : réécrit pour onze runes) |
| Une carte construite avec `baseMaxForgeUpgrades:` — le paramètre disparaît | `test/unit/card_rarity_test.dart:7`, `:17` (l'assistant `_cardData`) ; `deck_controller_test.dart:98`, `:149` (et le commentaire `:120`) ; `deck_state_persistence_test.dart:33` ; `decoupled_forge_test.dart:98` ; `test/widget/ui_card_rune_sockets_test.dart:53`, `:65` ; `test/unit/content_editor/entity_descriptor_test.dart:239` |
| `mergeCards` appelé à deux arguments — il n'en prend plus qu'un | `test/unit/deck_controller_test.dart:123`, `:173`, `:192`, `:210`, `:219` ; `decoupled_forge_test.dart:278`, `:294`, `:324` |
| `pools` pris comme exemple de clé de liste | `test/unit/content_editor/known_values_test.dart:53-59` ; `field_kind_test.dart:69` ; `test/widget/content_editor/document_form_test.dart:84` |

`dart analyze` propre et suite verte à la fin de chaque tâche, comme chaque lot du programme.

---

## 9. La simulation

**Premier temps — dans le plan de la partie 2, une tâche** (orchestration §3.6, §7.3 ligne 2). Les trois fichiers neufs
seraient pris par la branche par défaut du `switch` (`d26_economy_sim.dart:845`) **en plus** de leurs entrées en dur
(`:850`, `:854`, `:858`), rangés au milieu des huit — et sans leur condition (`needs`), que la branche par défaut ne
donne pas.

- Une **liste d'ordre explicite des 17 ids**, dans l'ordre qu'ils ont aujourd'hui — fichiers triés, puis entrées en dur
  (`:825-859`) : `burning`, `eco`, `enduring`, `freezing`, `hardened`, `quick`, `sharp`, `shocking`, `cheap`,
  `piercing`, `lifesteal`, `transfusion`, `precise`, `splash`, `echo`, `retain`, `spectral`.
- Pour chacun : le fichier s'il existe — `weight` et `eligibleCardTypes` lus comme aujourd'hui (`:828-829`), `needs` et
  `excludes` donnés par le `switch`, qui gagne trois cas reproduisant les entrées en dur (`cheap` : `cost1`,
  `excludes: ['eco']` ; `precise`, `spectral` : `damage`) — sinon l'entrée en dur.
- Un fichier dont l'id n'est pas dans la liste lève une erreur.
- Les fichiers portent `weight: 50` et aucun `eligibleCardTypes` (§3.2) : la définition jouée ne bouge pas.
- Relance : **diff vide** contre `tool/simulations/d26_reference_output.md`, ligne « Données lues » comprise — elle
  compte les runes, 17, pas les fichiers (`:3837-3841`, référence ligne 5).

Le script ne lit ni `pools` ni `stackable` ni `baseMaxForgeUpgrades` ni `minFusionRank` : la partie 1 ne le touche pas.

**Second temps — `spectral`, une tâche à part, après celle du réalignement, en partie 2** *(tranché par l'orchestrateur
au tour 1, A10)*. Le premier temps laisse le `spectral` du script tel quel. Le second l'aligne sur la forme que la
spec fixe pour le jeu (A10, §4.2) : **+40 % de la valeur de base à la rareté, par niveau, au moins +1 par niveau,
ajoutés à la valeur — jamais multipliant la Puissance, la part de `sharp` ni le terme `scaleWith`**. Aujourd'hui le
script multiplie par `1 + 0,4 × niveau` la valeur par coup, Puissance et `sharp` compris : dans l'estimation de l'IA
(`:1700-1702`), dans la résolution (`:1894`, `:1902`) et dans la valeur d'une pose (`:2202`). Ce qu'il doit calculer :

- `percentRuneBonus` (`:1264-1265`, `max((0.15 * level * cardValue).round(), level)`) prend le pourcentage `p` en
  paramètre et s'écrit **exactement** `max((p / 100 * level * cardValue).round(), level)` — **dans cet ordre**.
  Pourquoi : `15 / 100` est le même flottant que le littéral `0.15`, et l'évaluation de gauche à droite garde les
  mêmes produits intermédiaires, si bien que pour p = 15 le résultat est identique au bit près à celui d'aujourd'hui :
  `sharp` et `hardened` ne bougent pas dans la relance du second temps, qui ne mesure que `spectral`. Un autre ordre ne
  l'est pas : `p * level * cardValue / 100` diffère de l'actuel sur 60 des 6 030 couples (niveau 1 à 30, valeur 0 à
  200) mesurés le 2026-10-02 hors du dépôt, contre 0 pour l'ordre prescrit. Ses quatre appelants d'aujourd'hui et leur
  pourcentage : `:1646` (`_perHit`, `sharp`, 15), `:1653` (`_armorOf`, `hardened`, 15), `:2192` (`staticValue`,
  `sharp`, 15), `:2208` (`staticValue`, `hardened`, 15) ; les deux appels neufs de `spectral` prennent 40 ;
- `_perHit` (`:1642-1648`) ajoute la part de `spectral` à côté de celle de `sharp`, de la même façon : sur la valeur au
  rang (`scaled`, G1), coups additionnés puis répartis (`percentRuneBonus(max(0, base) × hits, niveau, 40) / hits`,
  comme `sharp` — D33 : la rune ne multiplie plus par le nombre de coups) ; les deux parts s'additionnent, aucune ne
  porte sur l'autre ;
- la valeur d'une pose (`staticValue`) ajoute de même le bonus de `spectral` à côté de celui de `sharp` (`:2192`,
  `:2199`) ;
- les trois multiplications (`:1700`, `:1702` ; `:1894`, `:1902` ; `:2202`) disparaissent ;
- l'épuisement (`:1849-1852`) et la pénalité que l'IA lui donne (`:2251`) ne changent pas : D33 les garde.

À 40 %, `0,4 × niveau × valeur` ne tombe jamais sur une demie exacte (4 × niveau × valeur est pair) : l'arrondi en
virgule flottante du script et l'arithmétique entière du jeu (`(40 L B + 50) ~/ 100`) coïncident. La tâche se vérifie
par une fumée (`--quick`) ; **l'orchestrateur** relance la mesure complète, explique l'écart dans le compte rendu et
recommite `tool/simulations/d26_reference_output.md` (orchestration §3.6, second temps).

**L'ordre des deux relances.** La relance du premier temps tourne sur l'état du commit de réalignement — les données
de la vague comprises, les trois fichiers neufs présents — ; celle du second temps, sur le commit `spectral`. La tâche
`spectral` est donc **la dernière à toucher le script**, et aucune tâche qui touche `assets/data/` ne vient entre les
deux.

**Aucun autre second temps.** A6 garde la base du Puits (50), A7 le `minFusionRank` 1 des six runes, A9 l'éligibilité
de `precise` et `spectral` ; le poids 50 et le `minFusionRank` 1 des trois runes neuves sont ceux de D63.

**Les écarts du script, consignés et non relancés** — aucun n'est une valeur qu'un arbitrage d'E2 remplace :

| Écart | Où | Pourquoi pas de relance |
|:---|:---|:---|
| L'héritage sans la règle d'exclusion d'E-S3 | `:2308-2317` | Le jeu l'applique depuis `0.5.3` |
| 17 runes jouées dès l'acte 1, 11 dans le jeu | `:848-859` | Brainstorm §8, paragraphe D65 ; revue IV11 : le nombre de runes par carte ne change pas |
| La relance de l'étal, que le script ne joue pas | — | Elle ne touche pas la copie (A11) |

**Ce qu'E2 confirme de ce que le script joue** : l'offre de trois runes pondérées au rang atteint, niveau 1
(`:2281-2303`) ; l'héritage additionné et borné (`:2310-2317`) ; l'affûtage `50 × niveau`, une rune par visite, au
plafond près (`:2369-2407`) ; le Puits tous les trois actes, étages 3 à 7, sur un combat ou un événement
(`:1125-1136`), `50 × niveau`, deux tiers arrondis, au moins 1, bornés, un échange par visite (`:3068-3108`) ; les
pré-forgées bornées par le rang, niveau 80 · 15 · 5 borné (`:2842-2862`) ; la copie au prix d'une carte de son rang
(`:2876`) ; `cheap` à −1, plancher 0 (`:1245`) ; `precise` à +5 par niveau (`:1629`), plafond 10 (`:1287`) ; `minFusionRank`
2 pour `eco` et `quick`, 1 sinon (`:1267-1269`).

---

## 10. Le découpage en parties

**L'invariant** : chaque partie laisse le jeu jouable, `dart analyze` propre et `flutter test` vert ; une partie ne
supprime un champ qu'avec son dernier lecteur, et n'écrit aucun code que la suivante jetterait.

**Partie 1 — la fusion devient la forge** : la boucle change une fois.
- `minFusionRank` (champ, huit fichiers, gabarit de rune de l'éditeur — `requiredKeys` garde `pools` jusqu'en
  partie 2) ; le prédicat (§4.3) — sa condition de coût garde `card.currentCost`, qui égale le coût de la donnée tant
  qu'aucune sorte ne le change ; `drawRunes` (§4.4) ;
- le geste de fusion (§4.5) et l'héritage sans troncature (§4.6) ; le dialogue de fusion réduit au choix ;
  `ForgeSlotRow` devenue ligne de rune ; `ForgeCardPreview` sans capacité ; `forge_buy_slot_button.dart` supprimé ;
- la capacité supprimée, ses sept lecteurs et sa donnée (§4.10) — la ligne des pré-forgées passe à `fusionRank` (D28) ;
- la session de forge et les fentes achetées supprimées (A3), la ligne du menu de debug ;
- l'affûtage (§4.7), `GoldManager.sharpenRune` à la place de `buyBonusForgeSlot` ; le retour système de `RestScreen`
  qui, une action faite, résout le nœud (A4, mécanisme) ;
- le tutoriel de fusion (A18), la prose de l'étape de fusion hors sa phrase sur le Puits, et celle du repos (§5.5) ; les
  chaînes ARB de la fusion et de l'affûtage ; `forgeNoEligibleRune` passe de la sélection du feu à l'écran de deck ;
  les textes de la forge de la partie 1 (§5.7) ;
- les lecteurs de `stackable` que la partie réécrit (`forge_upgrade_dialog.dart:172`, `forge_slot_row.dart:94-96`,
  `deck_screen.dart:284`, `:362`) ;
- les tests correspondants.

*Entre les deux parties* : `pools` n'est plus lu que par le tirage des pré-forgées (`shop_controller.dart:50-98`) et
l'éditeur ; `stackable` que par `consolidate`, `fusionOptionsFor`, le niveau des pré-forgées et l'éditeur ; la capacité
par personne. La Forge de Fusion vit encore, placée à 25 % : dans une partie neuve, aucune carte n'y porte deux fois une
même rune, et l'écran montre son état vide — jouable, et jamais livré ainsi, la vague sortant en une version.

**Partie 2 — le Puits, la boutique, les trois runes.**
- Le Puits (§4.8) : placement, écran — son retour système qui, après un échange, résout le nœud (A5, mécanisme) —,
  `GoldManager.exchangeRune`, `wellOptions`, `wellLevel`, `wellCost`, la carte du monde (`wellName`, `wellDesc`), la
  prose des nœuds et la phrase du Puits de l'étape de fusion (§5.4, §5.5), les textes de la forge de la partie 2
  (§5.7) ; `fusionOptionsFor`, `FusionOption` supprimés ;
- la boutique (§4.9) : la copie, les pré-forgées par `drawRunes` ;
- `pools` et `stackable` supprimés, avec leurs derniers lecteurs (§4.11) ;
- `cheap`, `precise`, `spectral` : fichiers, sortes, lecteurs (§3.2, §4.1, §4.2), et avec `reduceCost` le coût courant
  du prédicat lu par l'applicateur sur le catalogue reçu (A15, tranché par l'orchestrateur au tour 1) ; le badge
  (A13) ; `{val}` et les cinq descriptions (A14) ; `runeIcons`, `runeColors` et le test d'intégrité (A19) ;
- le réalignement du script, premier temps (§9) ; **puis, dans une tâche à part qui le suit**, l'alignement du
  `spectral` du script sur D33, second temps (§9, A10) — fumé par `--quick`, la mesure complète relancée par
  l'orchestrateur. Le réalignement vient après toute tâche qui touche `assets/data/` ; la relance 1 tourne sur son
  commit, la relance 2 sur le commit `spectral`, la dernière tâche à toucher le script ; aucune tâche qui touche
  `assets/data/` ne vient entre les deux ;
- les tests correspondants.

**Pourquoi cet ordre.** Le Puits et les pré-forgées lisent le prédicat et le tirage que la partie 1 écrit ; `pools` et
`stackable` ne peuvent disparaître qu'avec leurs derniers lecteurs, réécrits en partie 2 ; les trois runes ne
s'atteignent que par une offre qui existe. **Corrections à la proposition de la fiche** : `minFusionRank` et « une
rune par type » passent en partie 1 — sans eux, l'offre de fusion proposerait `eco` et `quick` dès la première fusion
(D48), ou relirait `pools` dans un code que la partie 2 jetterait ; la borne des pré-forgées par `fusionRank` passe en
partie 1 avec la capacité, dont elle remplace la ligne.

---

## 11. Documentation et livraison

**Pour `memory-bank-sync`**, à la fin de la vague :

| Quoi | Contenu |
|:---|:---|
| Un ADR neuf, « fusion = forge » | A1 à A20. Il **amende ADR-074** — le nœud devient le Puits d'échange, garanti tous les trois actes au lieu de 25 %, `base × niveau` au lieu de `80 × (N − 1)`, un échange par visite ; **ADR-094** — D1 : `forgeCapacityAt` et `forgeCapacity` supprimés, `fusionRank` comparé par `minFusionRank` et bornant les pré-forgées ; D3 : `stackable` supprimé ; D5 : `ForgeRuneRules` perd `isStackable` et `fusionOptionsFor` ; **ADR-105** — D1 : six sortes de delta ; D3 : `ForgeRuneRules` gagne `drawRunes`, l'affûtage et le Puits ; D7 : `boundLevel` borne la fusion, les pré-forgées, l'affûtage et le Puits ; D8 : le prédicat gagne le rang et « une rune par type », ses lecteurs changent ; D10 : l'héritage garde toutes les runes. Il **rend caduques** les décisions restantes d'**ADR-025** (fentes tirées, pools, relance, dialogue au feu — le tirage 80 · 15 · 5 ne vit plus qu'en boutique), d'**ADR-039** (D1 la session, D3 les fentes achetées) et le point 4 d'**ADR-024** (la capacité) — chacun ne change que de Statut |
| `_rules/02-3` | « 5 runes au plus » et la capacité des cartes de classe ; les cartes de classe ne reçoivent plus de rune |
| `_rules/02-4` | Le point 4 : plus de capacité ni de choix d'héritage ; la fusion propose une rune parmi trois ; l'héritage entier |
| `_rules/03-7` | La forge devient l'affûtage |
| `_rules/03-8` | Réécrite : l'offre de fusion, `minFusionRank`, « une rune par type », l'affûtage, le Puits, les onze runes ; la session anti-relance (`:29`, fausse), les fentes, les relances et l'achat disparaissent |
| `_patterns/10-00` | `pools`, `stackable` et la capacité supprimés (§10.1, §10.2, « Capacité Limite par Rareté », le graphe) ; `drawRunes`, `consolidate` sans troncature |
| `_patterns/20-00` | Le script lit les runes par une liste d'ordre explicite de 17 ids (§9) ; la ligne « un fichier de rune neuf est pris par le cas par défaut — doublon » ne vaut plus |
| À relire, que le diff peut périmer | `_rules/02-1` (le Puits tous les trois actes) ; `_rules/03-9` (la copie, les pré-forgées) ; `_rules/03-13` (les champs de forge de `RunState`) ; `_rules/08-00` (l'étape de fusion) ; `_patterns/02-1` (`RunState`, `GoldManager`), `02-5` (`ShopController`), `03-2` (le placement), `03-7`, `05-2` (`UiCard.forgeCapacity`), `19-00` (`requiredKeys` de la rune) |

`CLAUDE.md` ne change pas : `ForgeFusionScreen` et `gold_manager.dart` gardent leur nom (A16, A17).

**Ce que le joueur voit en `0.5.4`** :
- chaque fusion de trois cartes offre **une rune au choix parmi trois** — moins quand moins lui sont permises —, au
  niveau 1 ; la carte fusionnée garde toutes les runes de ses trois exemplaires, une même rune additionnant ses
  niveaux : plus de limite de runes par carte, plus de prises vides, plus de choix de ce qu'on garde ;
- une rune de chaque sorte par carte ; *Véloce* et *Économe* ne s'offrent qu'à partir de la deuxième fusion (rare) ;
- **le feu de camp affûte** : une rune d'une carte gagne un niveau pour 50 or × son niveau, à la place du repos ou de
  l'oubli ; la forge du feu disparaît, avec ses fentes, ses relances et ses fentes achetées ;
- **le Puits d'échange remplace la Forge de Fusion** : un tous les trois actes, entre les étages 3 et 7 ; une rune d'une
  carte contre n'importe quelle autre qui lui est permise, aux deux tiers de son niveau (au moins 1), pour 50 or × le
  niveau donné ; un échange par visite ;
- **la boutique vend la copie d'une carte de votre deck**, même rareté, sans ses runes, au prix d'une carte de cette
  rareté ; les cartes runées de la boutique ne portent pas plus de runes que leur rareté n'a demandé de fusions — une
  commune n'en porte plus ;
- trois runes neuves : *Allégé* (la carte coûte 1 Mana de moins), *Précis* (+5 % de critique par niveau), *Spectral*
  (+40 % des dégâts de base par niveau, mais la carte s'épuise) ;
- le badge « Usage unique » dit vrai : il apparaît sur une carte *Spectrale* et quitte une carte *Persistante* ;
- **une correction** : au feu de camp, quitter l'écran par le retour après avoir agi termine désormais la visite, comme
  « Continuer » — on ne peut plus revenir pour un second repos, un second oubli ou un second affûtage ; au Puits, de
  même après un échange (sans échange, on peut toujours y revenir) ;
- les cartes de classe ne reçoivent plus de rune ;
- **à dire dans la note : les fusions restent rares jusqu'à la version suivante**, qui apporte une carte après chaque
  combat — d'ici là, les doublons ne viennent que des récompenses de boss (les cartes du boss « cartes », la carte
  bonus du boss « XP »), de la boutique et des Miroirs, et les runes à affûter ou à échanger sont rares.

Pas de lien dans `docs/ROADMAP.md`, pas de note de version propre au lot : la note est celle de la vague, écrite à sa
fin.

---

## 12. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Choisir la rune avant de fusionner, sur un aperçu** | Annuler puis refusionner retirerait une offre neuve : une relance gratuite, ou une garde anti-relance de plus (A1) |
| **Un choix différable, l'offre gardée en attente sur la carte** | Un état sérialisé et un chemin de réouverture pour une carte laissée sans sa rune (A1, A3) |
| **Le niveau de la rune offerte selon le rang atteint** | Le « palier » de D3 est `minFusionRank` ; le script pose le niveau 1, et les niveaux viennent de l'héritage et de l'affûtage (A2) |
| **Garder les fentes tirées, les relances ou les fentes achetées à la fusion** | D3 : une parmi trois ; une relance non jouée par la mesure (A2) |
| **Garder `forgeTargetCardId` pour la carte affûtée** | La règle « une fois par visite » vivrait à deux endroits (A3, A4) |
| **L'affûtage en plus du repos ou de l'oubli** | D5 met l'affûtage à la place de la forge ; le script joue un feu à une action (A4) |
| **Plusieurs échanges par visite au Puits** | La réserve d'or achèterait des échanges que la mesure ne compte pas (A5) |
| **Une base du Puits partagée avec `b`, ou une autre valeur** | La mesure sépare les deux prix ; aucun motif de remplacer la valeur jouée (A6) |
| **`enduring` à `minFusionRank` 2** | Aucun motif de remplacer la valeur jouée ; rien de neuf sur la *Potion de Soin* (A7) |
| **`minFusionRank` facultatif, ou 0 admis** | Une rune s'offrirait dès la première fusion faute de l'avoir dit ; 0 promettrait une commune runée (A8) |
| **`precise` sur le soin ; `spectral` refusée à une carte qui s'épuise** | Valeurs non jouées, pour des cas qu'aucune carte de `0.5.4` ne produit — vague 5 (A9) |
| **`spectral` en multiplicateur, Puissance comprise, comme le script** | D33 : un pourcentage de la valeur de base (A10) |
| **`enduring` l'emportant sur `spectral`** | D33 : la carte s'épuise (A10) |
| **Une prime sur la copie, ou le prix du Miroir** | D46 : un prix par rareté ; valeur jouée (A11) |
| **La relance de l'étal qui retire aussi la copie** | D46 : tirée, non choisie (A11) |
| **Les pré-forgées au niveau 1** | Le script tire leur niveau (A12) |
| **Le badge sur la donnée seule** | Deux réponses à « la carte s'épuise-t-elle ? » (A13) |
| **Un placeholder par sorte, ou des textes littéraux** | Un vocabulaire par sorte ; un chiffre écrit deux fois (A14) |
| **L'affûtage et l'échange dans les écrans, ou dans `DeckNotifier`** | Logique métier dans l'interface ; l'or hors de son contrôleur (A16) |
| **Renommer `forgeFusion`, `ForgeFusionScreen`, `ForgeUpgradeDialog`** | Le joueur ne les lit pas ; le renommage gagnerait `CLAUDE.md`, les tests et la carte sauvegardée (A17) |
| **Un tutoriel qui pose la rune d'office, ou la prose seule** | L'étape enseigne un choix ; ADR-081 (A18) |
| **Reprendre des icônes existantes pour les runes neuves** | Deux runes d'une même apparence (A19) |
| **`minFusionRank` en partie 2, comme la fiche le proposait** | L'offre de fusion de la partie 1 en a besoin (A20, §10) |
| **Une relance de second temps pour la base du Puits, les `minFusionRank` ou l'éligibilité des runes neuves** | Aucune de ces valeurs jouées n'est remplacée (A6, A7, A9) |
| **Le `spectral` du script laissé tel quel, l'écart consigné** | La référence mesurerait un `spectral` que le jeu ne joue pas — tranché par l'orchestrateur au tour 1 (A10, §9) |
| **Une étape de migration de sauvegarde** | Rien à migrer ; les sauvegardes ne se transfèrent pas avant la `1.0.0` (§7) |

## 13. Vérification — état à l'arrêt (02/10/2026)

Écrit par l'orchestrateur de la vague 2. Trois tours de vérification, chacun par un vérificateur neuf ; deux
corrections par le rédacteur, repris avec son contexte, entre les tours. Les arbitrages des tours 1 et 2 sont dans les
deux tableaux « Tranchés par l'orchestrateur » du §1.2.

| Tour | Constats | Suite |
|:---|:---|:---|
| 1 | 1 moyen (`spectral` du script), 11 mineurs, 1 de rédaction | Corrigés ; cinq arbitrages de l'orchestrateur, dont le retour système après une action (4 bis) |
| 2 | 2 moyens (ordre du calcul flottant du script ; un affûtage qui ne fermait pas son dialogue), 7 mineurs, 5 de rédaction | Corrigés ; trois arbitrages de l'orchestrateur |
| 3 | **2 moyens**, 8 mineurs, 1 de rédaction | **Non corrigés : la troisième vérification qui rend un constat moyen arrête la vague** (orchestration §3.3, §6) |

**Les constats ouverts du tour 3**, tels que le vérificateur les a rendus — preuves relues sur `a9e2db6` :

| # | Gravité | Où | Constat | Correction proposée par le vérificateur |
|:---|:---|:---|:---|:---|
| 1 | **moyen** | §8, §10 | La matrice de `forge_upgrades_catalog_test` (`:135-163`, `:187-200`) teste les 23 cartes à leur rareté de donnée ; la condition 7 du prédicat (`minFusionRank` ≤ rang), qui entre en partie 1, refuse toute rune au rang 0 (`card_data.dart:36-37`) : la partie 1, telle que §8 la découpe, finirait rouge | En partie 1, la matrice passe aux rangs 1 et 2 avec les huit runes ; la partie 2 y ajoute les trois runes neuves |
| 2 | **moyen** | §4.9, A11 | La copie du deck se retire gratuitement : `initializeShop` retire tout l'étal à chaque création de l'écran (`shop_screen.dart:31-42`), le retour système ne résout pas le nœud (`:307-313`, `canPop: true`), seul « Quitter » le fait (`:466-469`), et la carte laisse rentrer dans un nœud non résolu (`map_screen.dart:389-392`). Défait D46 (« tirée et non choisie ») et le motif d'A11. Défaut antérieur — l'étal entier se retire de la même façon aujourd'hui —, mais E2 y pose une mécanique neuve. Le script tire la copie une fois par visite (`d26_economy_sim.dart:2873-2877`) | Arbitrer comme A4 et A5 : (a) l'étal n'est tiré qu'une fois par nœud de boutique ; (b) le retour système résout le nœud ; (c) consigner. Le filtre 1 (D46) écarte (c) |
| 3 | mineur | A1 | D65 (`:104`, et §8 `:394`) écrit aussi « `mergeCards` en propose moins » : à citer, en disant que son objet est le nombre de runes offertes, que `drawRunes` tient | Citer et motiver |
| 4 | mineur | §8 | `decoupled_forge_test.dart:74-85`, `shop_controller_test.dart:477-493` et `forge_rune_rules_test.dart:51` doivent remplacer `stackable: false` par `maxLevel: 1`, sans quoi `:303` et `:460` rougissent | Le dire |
| 5 | mineur | §8 | Le groupe `stackable` de `forge_rune_rules_test.dart:58-84` lit des runes sans `minFusionRank` : sa partie n'est pas dite | « Supprimé en partie 1 », ou il gagne la clé jusqu'en partie 2 |
| 6 | mineur | §4.5 | `deckMergeSuccess` s'affiche par le `context` d'une case de la grille, qui peut être démontée pendant le dialogue de choix | Notifier par le `context` stable de `DeckScreen`, avec un test |
| 7 | mineur | §8 | Le « rang atteint » n'est gardé qu'au niveau du prédicat | Test d'écran : trois *Concentration* peu communes fusionnent en rare, le dialogue offre *Véloce*, seule |
| 8 | mineur | §8, A13 | `exchangeRune` n'a pas de cas de refus faute d'or ; les trois lecteurs Flame d'A13 n'ont pas de test | Le cas de refus ; une commande de contrôle `git grep -n "data.isExhaust" -- lib/game/components lib/ui`, vide après E2 |
| 9 | mineur | §9, §10 | La relance 1 doit tourner sur le commit de réalignement, mais la spec ne dit pas comment l'orchestrateur retrouve cet état une fois le code fini | Un clone jetable hors du dépôt, extrait au commit de réalignement |
| 10 | mineur | §5.3, §4.7 | La ligne « niveau et suivant » du dialogue d'affûtage n'a pas de clé ARB | `sharpenLevel` (`{from}`, `{to}`) |
| 11 | rédaction | §4.4, tableau du tour 2 | « Deux lecteurs » au lieu de trois ; les options de l'offre vide non énumérées ; `forge_slot_row.dart:168-205` → `:167-209` | Corriger |

**Ce que l'orchestrateur recommande pour lever l'arrêt**, sans l'avoir appliqué — c'est au propriétaire d'en décider :

- **n° 2 — l'option (a), étendue à l'étal entier** : la boutique retient le nœud pour lequel elle a tiré son étal, copie
  comprise, et ne le retire pas tant que ce nœud n'est pas résolu. Le filtre 1 écarte (c), au nom de D46. Le filtre 5
  retient (a) contre (b) : l'étal est déjà l'état du Notifier de la boutique, et (b) ne fermerait rien — sortir sans
  acheter doit rester possible, comme au Puits sans échange, et rouvrirait le tirage. Un seul mécanisme ferme au passage
  le retirage gratuit de tout l'étal, un défaut antérieur, à dire dans la note de version. Test : « sortir par le retour
  puis revenir garde le même étal et la même copie ».
- **n° 1 et les mineurs** : les corrections proposées par le vérificateur.
- **Puis un quatrième tour de vérification**, par un vérificateur neuf, qui reçoit les arbitrages des tours 1 à 3.
