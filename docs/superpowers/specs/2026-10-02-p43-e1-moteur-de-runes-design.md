# P-43 E1 — Le moteur de runes data-driven — Conception

Date : 2026-10-02
Statut : **Conception** — vague 1 (`0.5.3`), second de ses deux lots, branche `feat/v0.5.3-p43-e0-e1`

Chantier ROADMAP : **P-43** « Économie unifiée », lot **E1**, le deuxième des cinq lots E0 à E4. Le déroulé fait foi
dans le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
(fiche §8.1, partie E1) ; **E0**, déjà implémenté sur cette branche, a laissé le code sur lequel E1 s'écrit.
Sources amont :
- [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 — **D4**, **D27**,
  **D33**, **D44**, **D51**, **D61**, **D68**, **D72**, **D75**, **D28** (le seul renommage) : source de vérité, ni
  rediscutées ni amendées ici ; §4.2 (modèle de rune, esquisse `sharp.json`, geste de fusion), §4.4 avant-dernier
  point (l'applicateur partagé avec les évolutions de signature), **§4.5 (G1, G2 — des propositions)**, §8, §11
  ligne E1 ;
- [revue du brainstorm](../../possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §2.1
  (les sept lecteurs de la capacité), §3.5, §13 IV3 et IV4, §15 W1 ;
- [spec E0](2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md), §1 (A1 : la règle de fusion par source ne
  vise que `might` ; **A4** : E1 pose les statuts des runes élémentaires par `addStatus`, sans source) et §4.8 ;
- ADR-094, ADR-061, ADR-100 ; la sortie de référence de la simulation, `tool/simulations/d26_reference_output.md`.

> **Ce que E1 livre, en une phrase.** Une rune déclare dans son fichier ce qu'elle fait (une liste de deltas
> typés), où elle s'offre (un seul prédicat d'éligibilité) et jusqu'où elle monte (`maxLevel`, lu par une seule
> fonction aux quatre endroits qui écrivent un niveau) ; un applicateur unique calcule la carte telle qu'elle se
> joue — rareté (G1, G2) et runes comprises — pour le moteur comme pour les six rendus ; `sharp` et `hardened`
> passent à +15 % de la base par niveau, au moins +1 ; **la boucle de jeu ne change pas** : `pools`, `stackable`
> et la capacité gardent leurs lecteurs, aucun écran ne change de déroulé.

Toute référence `fichier:ligne` de ce document a été mesurée le 2026-10-02 sur `38da29f`, après E0.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce qu'E1 en livre | Où |
|:---|:---|:---|
| **D4** | Le niveau d'une rune est borné rune par rune (la part « montée contre de l'or » est E2) | §3.1, §4.7 |
| **D27** | Chaque rune déclare `maxLevel` dans son fichier : `eco` et `quick` à 1 ; la table du brainstorm §8 pour les six autres — `freezing` et `enduring` à 1, `sharp`, `hardened`, `burning`, `shocking` sans plafond | §3.2 |
| **D33** | `sharp` et `hardened` en pourcentage de la valeur de base : `valuePercentPerLevel: 15`, au moins +1 par niveau sur la carte | §4.1, §4.2 |
| **D44** (part des huit runes) | Toute règle d'éligibilité est un champ du fichier : `requiresMinCost` (`eco`), `excludesRunes`, `excludesEffects: ["gain_mana", "draw"]` sur `enduring` ; aucun `case` par rune dans l'offre. `requiresCost` (`transfusion`) n'est **pas** écrit : il entre en vague 5 avec `costs` (D40) | §3, §4.6 |
| **D51** (part des huit runes) | `enduring` porte `excludesRunes: ["eco", "quick"]`. La donnée de `cheap` (`requiresMinCost: 1`, `excludesRunes: ["eco"]`) entre en E2 et tiendra dans ces mêmes champs, sans code | §3.2, §4.10 |
| **D61** | `sharp` et `hardened` éligibles par effet (`eligibleEffects: ["damage"]`, `["armor"]`) ; `excludesRunes` symétrique par moteur pour toute paire ; `requiresMinCost` lit le coût courant (`CardInstance.currentCost`) | §4.6 |
| **D68** | E1 applique, E2 obtient : le renommage `fusionRank`, l'applicateur de deltas à la place du `switch`, `valuePercentPerLevel`, `maxLevel`, l'éligibilité en donnée, G1, G2 ; `pools`, `stackable` et la capacité restent en lecture | tout le document ; §4.9 |
| **D72** | `maxLevel` borne les quatre endroits qui écrivent un niveau — `consolidate`, `fusionOptionsFor`, le tirage du feu, celui des pré-forgées — par une seule fonction | §4.7 |
| **D75** | Le prédicat ne propose plus une rune dont le plafond est atteint sur la carte, exemplaires additionnés | §4.6 |
| **D28** (le seul renommage) | `CardRarity.forgeSlotBonus` devient `fusionRank`, valeurs inchangées ; la capacité le lit en attendant E2 | §3.3 |

**G1 et G2** (brainstorm §4.5) sont des **propositions** que D68 met dans E1, non des décisions acquises : leur
portée et leur rencontre sont arbitrées ci-dessous (A5, A6).

### 1.2. Les arbitrages de la spec

Tranchés par l'arbre de décision du fichier d'orchestration (§5) : le premier filtre qui départage l'emporte.
**Aucune question ne s'est révélée ne se trancher qu'en amendant une décision acquise.** A1, A4, A5, A6 et A10
sont posées par la fiche ; A9 est née de « la spec doit fixer » ; les sept autres sont apparues à la rédaction.

#### A1 — La forme de l'applicateur de deltas *(posée par la fiche)*

Comment une rune déclare son effet en donnée, pour couvrir les huit runes d'aujourd'hui, les trois d'E2 (`cheap`,
`precise`, `spectral`) et les six de P-44 (`piercing`, `lifesteal`, `splash`, `echo`, `transfusion`, `retain`)
sans en écrire aucune ici.

- (a) **Champs à plat, l'effet déduit de l'éligibilité** — l'esquisse du brainstorm §4.2 : `valuePercentPerLevel`
  s'applique aux effets nommés par `eligibleEffects` ; chaque autre sorte de rune reçoit son champ (`drawPerLevel`,
  `manaPerLevel`, `statusId`, `removesExhaust`…), et le moteur un `if` par champ ;
- **(b) une liste typée de deltas** (`"deltas": [ { "type": …, …paramètres par niveau } ]`), dans un vocabulaire
  fermé de sortes d'opérations sur une carte (`CardDelta`), chacune un petit objet qui sait s'appliquer ;
  l'éligibilité reste à part ;
- (c) **la rune ajoute des effets de carte** (`CardEffect` réutilisé : `quick` = `draw`, `eco` = `gain_mana`, les
  élémentaires = `apply_status`), plus un modificateur pour `sharp` et `hardened` ;
- (d) garder le `switch` par id (`lib/game/services/effect_resolver.dart:153-175`) et n'ajouter que le pourcentage.

1. *Décision acquise* — **écarte (d)** : D68 livre « l'applicateur de deltas à la place du `switch` ». (a), (b) et
   (c) passent ; D68 nomme le champ `valuePercentPerLevel` sans fixer sa place, (b) le garde dans son delta.
2. *Valeur mesurée* — neutre : les trois reproduisent les huit runes telles que la simulation les joue.
3. *Principes* — neutres.
4. *Le mécanisme plutôt que le cas* — **retient (b)**. (a) écrit un champ et un `if` par sorte de rune, et confond
   l'endroit où une rune s'offre avec ce qu'elle modifie : `lifesteal` s'offre sur une carte de dégâts mais son
   pourcentage porte sur les dégâts infligés, pas sur la valeur de l'effet ; `splash` s'offre sur une cible unique
   et modifie la cible. (c) est (b) restreinte à une sorte, l'ajout d'effet : `sharp`, `hardened`, et toutes les
   runes de pipeline de P-44, qui ne sont pas des effets de carte, lui demanderaient un second mécanisme — (b) sous
   un autre nom.

**Choix : (b).** Une rune est un fichier qui compose des sortes existantes ; une sorte neuve est du Dart **une fois
par mécanisme** (D18 : « une rune par mécanisme »), jamais un `case` par rune. E1 n'écrit que les trois sortes que
ses huit runes lisent (§4.1) ; la table de §4.1 montre où tombent les neuf autres. **La couture avec les évolutions
de signature** (brainstorm §4.4) : `CardDelta` et l'applicateur sont le code commun ; l'applicateur reçoit des
paires *(delta, niveau)*, et la traduction des runes en paires est une fonction à part — la vague 5 traduira de même
ses `SignatureEvolutionData` (`bonusPerLevel`, `addEffect`, `cost`, `target`, `hits`) en paires, sans lire une donnée
de rune ni écrire dans `forgeUpgrades`. Données, stockage et affichage restent séparés.

#### A2 — Le chemin des effets qu'une rune ajoute *(apparue à la rédaction)*

`quick`, `eco`, `burning`, `freezing` et `shocking` produisent une pioche, un gain de mana et trois statuts.

- **(a) par le registre de stratégies** (ADR-061) : l'applicateur rend ces effets comme des `CardEffect`, que
  `EffectResolver` confie aux stratégies des cartes (`lib/game/services/effects/effect_strategy.dart:33-42`) ;
- (b) un bloc de résolution propre aux runes dans `EffectResolver`, comme aujourd'hui (`:178-231`).

Les filtres 1 à 4 ne départagent pas. **5** retient (a) : un seul chemin pour tout effet — ADR-061 fait du résolveur
un routeur — et, pour les statuts, le seul chemin de pose qu'A4 de la spec E0 impose : `ApplyStatusEffectStrategy`
pose par `addStatus` (`strategies.dart:182`, `:189`), sans source hors `might`. (b) garde l'exception que la spec E0
a refusée. **Choix : (a).** Deux conséquences, assumées et annoncées (§4.8, §10) : le mana d'`eco` passe par
`GainManaEffectStrategy`, qui l'étiquette `GainSource.card` et joue le son du gain de mana (`strategies.dart:130-133`) ;
`GainSource.rune` (`lib/game/systems/stat_gains.dart:13`) perd ses deux seuls producteurs (`effect_resolver.dart:183`,
`:259`), n'a aucun lecteur, et disparaît.

#### A3 — Où vivent l'applicateur, la borne et le prédicat *(apparue à la rédaction)*

- **(a)** l'analyseur de niveau, la borne `maxLevel`, `CardDelta` et l'applicateur dans `lib/models/` ; le prédicat
  d'éligibilité dans `ForgeRuneRules` (`lib/game/services/forge_rune_rules.dart`), à côté de `consolidate` et de
  `fusionOptionsFor` ;
- (b) tout dans `ForgeRuneRules` ;
- (c) tout dans `lib/models/`, le prédicat en méthode de `ForgeUpgradeData`, comme `CardData.isOfferableTo`.

**5** tranche. (b) : `CardInstance.exhaustsOnPlay` (`lib/models/card_instance.dart:30-33`) et les widgets de carte
doivent lire l'applicateur, et le modèle n'importe jamais `lib/game/`. (c) contre (a) : ADR-094 D5 a fait de
`ForgeRuneRules` la place unique des règles qui combinent des runes (`consolidate`, `fusionOptionsFor`) ; le prédicat
en est une — il lit les runes que la carte porte déjà, leurs exclusions et leurs plafonds. Et le seul prédicat
d'éligibilité qui ne soit pas une règle de la donnée elle-même, celui des passifs, vit déjà hors du modèle :
`availablePassivesFor` (`lib/game/systems/passive_availability.dart:18`). **Choix : (a).** Le prédicat reste une
fonction pure, sur le modèle d'`isOfferableTo` : ce sont ses entrées qui le rendent pur, pas sa place.

#### A4 — Ce que deviennent les `switch` d'affichage *(posée par la fiche)*

- **(a) en donnée dès E1** : nom, description et emoji lus dans le fichier de rune, chiffres lus sur l'applicateur ;
- (b) laissés à E2 : E1 corrige seulement les chiffres de `sharp` et `hardened` dans les `switch` ;
- (c) entre les deux : les emoji en donnée, les textes en `switch`.

Les filtres 1 à 3 ne départagent pas. **4** retient (a) : sous (b) ou (c), les trois runes d'E2 s'écriraient en
Dart dans chaque `switch` — exactement ce que le brainstorm §12 refuse (« chaque rune serait du Dart ») —, et les
textes de chaque rune, déjà dans son fichier, resteraient écrits deux fois. Les lignes de `sharp` et `hardened` de
ces `switch` doivent changer de toute façon (D33). **Choix : (a)** — ce qui ferme la conséquence d'ADR-094 « les
textes de runes restent codés en dur par id dans le rendu Flame ». Le rendu Flame lit déjà l'emoji dans la donnée
(`lib/game/components/widgets/card_text_renderer.dart:705-709`) : c'est le précédent.

#### A5 — La portée de G1 *(posée par la fiche)*

G1 : `v = max(round(base × multiplicateur), v_précédent + 1)` à chaque palier de rareté (brainstorm §4.5).

- (a) les dégâts et l'armure seuls ;
- (b) les dégâts, l'armure et le soin ;
- **(c) tout effet que la rareté multiplie** — dégâts, armure, soin, valeur d'un statut (`apply_status`) —, `draw` et
  `gain_mana` exceptés (G2, A6) ;
- (d) au moins un chiffre par carte, plutôt que chaque effet.

1. *Décision acquise* — aucune n'est écartée : G1 est une proposition.
2. *Valeur mesurée* — **retient (c)** : c'est la valeur que la simulation a jouée, sans qu'une décision la fixe — la
   fonction `scaled` (`tool/simulations/d26_economy_sim.dart:1253-1258`) est appliquée aux dégâts (`:1643`), à
   l'armure (`:1651`), au soin (`:1870`), aux statuts posés sur soi (`:1876`) et sur l'ennemi (`:1878`). (a), (b) et
   (d) la remplaceraient : un changement voulu, qui demande une relance à part et une référence recommitée (§3.6 de
   l'orchestration, second temps), alors que la fiche veut un diff vide et un script intouché.

**Choix : (c).** À noter : la valeur de `freeze` n'est pas lue avant P-44 lot 1 (`lib/models/enemy_instance.dart:28`,
`lib/game/controllers/combat/turn_phase_manager.dart:107`) ; le chiffre de *Trait de Glace* grandit donc sans effet,
comme il le fait déjà en épique aujourd'hui. Toutes les autres valeurs de statut des cartes livrées sont lues.

#### A6 — La rencontre de G1 et de G2 *(posée par la fiche)*

G2 gèle le multiplicateur de rareté sur `draw` et `gain_mana` (`effect_resolver.dart:235`, qui multiplie tout
effet). *Concentration* (`draw 2`) et *Focalisation* (`gain_mana 1`) ne portent rien d'autre : sous G2, leur fusion ne
change aucun chiffre d'effet, alors que G1 veut qu'une fusion change toujours un chiffre.

- **(a) G1 s'arrête aux effets que la rareté multiplie** : une carte dont tous les effets sont gelés ne gagne à la
  fusion que sa rareté — en E1, une fente de rune de plus (la capacité lit `fusionRank`) ; à partir d'E2, une rune ;
- (b) G1 l'emporte sur G2 pour une telle carte : +1 par palier sur la pioche ou le mana ;
- (c) une compensation propre à ces cartes — un coût réduit à un palier, *Persistant* offert ;
- (d) une carte dont tous les effets sont gelés ne fusionne plus.

1. *Décision acquise* — **écarte (d)** : D68, E1 ne change pas la boucle — l'écran de deck propose aujourd'hui ces
   fusions (`lib/ui/screens/deck_screen.dart:215-237`).
2. *Valeur mesurée* — **écarte (b) et (c)** : la simulation ne multiplie jamais la pioche ni le mana
   (`d26_economy_sim.dart:1868`, `:1874` — « G2 : ni rareté ni rune sur la pioche ») et ne joue aucune
   compensation ; les introduire est un changement voulu hors de la vague. (c) est de surcroît un cas écrit pour deux
   cartes (filtre 4) et anticipe `cheap` et la donnée d'E2 (filtre 7).

**Choix : (a).** G1 se lit : *chaque fusion augmente d'au moins 1 chaque chiffre que la rareté multiplie* ; la pioche
et le mana rendu ne grandissent plus avec la rareté. Ce que gagne réellement une carte toute gelée est maigre, et la
spec le dit : *Concentration* n'accepte qu'une rune, *Véloce*, plafonnée à 1 — sa fente de plus ne sert qu'une fois ;
*Focalisation* disparaît en vague 5 (D28). **Constat pour E2** (§4.10) : sous le prédicat d'E2, la première fusion
d'une *Concentration* (rang 1) n'a aucune rune éligible — `quick` attend le rang 2 (D48), `eco` et `cheap` exigent un
coût ≥ 1, `enduring` exclut `draw`, les autres sont par effet ou par Attaque. D65 (« jamais aucune tant qu'une
existe ») tient, mais à vide.

#### A7 — La base et l'arrondi du pourcentage *(apparue à la rédaction)*

**La base.** (i) La valeur de l'effet **à la rareté de la carte**, G1 et G2 compris, avant la Puissance ; (ii) la
valeur de la donnée, celle de la commune. **1** retient (i) : D33, « la rune grandit avec la fusion ».

**Le calcul.** (α) Une fois, sur le niveau **total** des exemplaires de même id : `max(arrondi(p × L × B / 100), L)` ;
(β) niveau par niveau : `L × max(arrondi(p × B / 100), 1)` ; (γ) exemplaire par exemplaire, puis la somme. **1**
écarte (γ) : D75 additionne les exemplaires. **2** retient (α) : c'est la formule que joue la simulation
(`d26_economy_sim.dart:1264-1265`, sur la base au rang, `:1643`, `:1651`).

**L'arrondi.** (x) En virgule flottante, comme le script ; (y) en arithmétique entière, au plus proche, la demie vers
le haut : `(p × L × B + 50) ~/ 100`. **1** ne départage pas. **2** retient (y) : le script joue « au plus proche » ;
l'arithmétique entière en est la valeur exacte ; l'erreur de flottant de `(0.15 * level * cardValue).round()` n'est pas
une valeur jouée par décision, et les 9 couples sur 720 qu'elle déplace (niveaux 1 à 12, bases 1 à 60, tous au niveau 3
ou plus — 13 au lieu de 14 pour 15 % × 3 × 30) ne sont pas une mesure. **Choix : (i), (α), (y)**, dans une seule
fonction (§4.2) — le précédent est A6 de la spec E0.

#### A8 — Comment une rune déclare son plafond *(apparue à la rédaction)*

- **(a)** clé `maxLevel` **obligatoire**, `null` pour « sans plafond » — l'esquisse du brainstorm §4.2 ;
- (b) clé facultative, absente = sans plafond ;
- (c) clé obligatoire, entière, une sentinelle (999) pour « sans plafond ».

**1** écarte (b) : D27, « Chaque rune déclare son `maxLevel` dans son fichier ». **6** écarte (c) : le fichier dirait
999 pour dire « aucun ». **Choix : (a).**

#### A9 — La fusion de cartes quand la somme dépasse le plafond *(née de « la spec doit fixer »)*

Trois *Forme Démoniaque* communes portant chacune `eco:1` — le feu la propose à un Pouvoir commun, dont le pool
`common` est vide, par le repli sur tous les pools (`forge_upgrade_dialog.dart:132-139`) : `consolidate`
(`forge_rune_rules.dart:46-55`) rend aujourd'hui `eco:3`.

- **(a) la somme est bornée** : la fusion se fait, la carte reçoit `eco:1`, le surplus se perd ; le dialogue
  d'héritage, quand la capacité le fait paraître, liste le résultat de `consolidate` (`deck_screen.dart:226-228`),
  donc le niveau borné ;
- (b) la fusion est refusée ;
- (c) la somme est gardée.

**1** écarte (c) (D72) et (b) (D68 : l'écran de deck propose les mêmes fusions qu'aujourd'hui). **Choix : (a)** —
c'est aussi ce que joue la simulation (`d26_economy_sim.dart:2314-2317`).

#### A10 — Ce que propose la Forge de Fusion quand la somme dépasse le plafond *(posée par la fiche)*

`fusionOptionsFor` (`forge_rune_rules.dart:60-78`) propose de réunir les exemplaires d'une rune cumulable portée au
moins deux fois, et le nœud écrit la somme (`lib/ui/screens/forge_fusion_screen.dart:55`).

- **(a) une fusion qui perdrait un niveau n'est pas proposée** ;
- (b) elle est proposée, bornée — 80 or pour réunir `eco:1` et `eco:1` en `eco:1` ;
- (c) elle est proposée à la somme.

**1** écarte (c) (D72). Les filtres 2 à 5 ne départagent pas — le script n'a pas de Forge de Fusion. **6** retient
(a) : (b) vend une opération qui détruit de la valeur sans le dire. **Choix : (a)**, une fusion proposée si et
seulement si la somme ne dépasse pas le plafond. **Sans objet en partie neuve** : sous D75, le feu ne repropose pas une
rune plafonnée déjà portée, la boutique ne pose jamais deux fois une rune plafonnée (A12), et le tirage d'un niveau tient
compte de ce que la carte porte (§4.7) — aucune carte d'une partie neuve ne porte deux exemplaires dont la somme
dépasse le plafond. Le cas ne vient que d'une sauvegarde écrite avant `0.5.3`.

#### A11 — La forge du feu quand aucune rune n'est éligible *(apparue à la rédaction)*

Le prédicat d'E1 rend possible une carte sans aucune rune éligible : *Concentration* peu commune portant `quick:1`
(une fente libre, sa seule rune plafonnée), *Forme Démoniaque* rare portant `eco:1` et `quick:1`, *Potion de Soin*
rare portant `quick:1` et `eco:1` (`enduring` exclu par symétrie). Le dialogue retombe alors sur `'sharp'`
(`lib/ui/widgets/forge_upgrade_dialog.dart:173`), sans regarder l'éligibilité.

- **(a)** l'écran de sélection du feu refuse la carte, avec un message, comme il refuse une carte pleine
  (`lib/ui/screens/rest_card_selection_screen.dart:29-38`) ;
- (b) le dialogue s'ouvre sans aucune fente ;
- (c) le repli sur `sharp` reste.

**1** écarte (c) : `sharp` est éligible par effet `damage` (D61), et le repli la poserait sur une carte sans
dégâts. Les filtres 2 à 5 ne départagent pas. **6** retient (a) : le joueur apprend pourquoi avant d'entrer, au lieu
d'une forge vide. **Choix : (a)**, et le repli sur `'sharp'` disparaît. Le déroulé ne change pas : c'est le refus
d'aujourd'hui, avec un motif de plus.

#### A12 — La boutique quand aucune rune n'est éligible *(apparue à la rédaction)*

Une pré-forgée tire une ou deux runes (`lib/game/controllers/shop_controller.dart:197-221`). Le second tirage écarte
les ids déjà tirés (`:138`) ; s'il ne trouve rien, il recommence **sans** exclusion (`:140`), puis retombe sur
`'sharp'` (`:141`). Sous le prédicat d'E1, *Concentration* et *Focalisation* n'acceptent que `quick` : une pré-forgée
à deux runes (actes 3 et plus, `:203-208`) recevrait, par ces replis, `quick` deux fois ou `sharp`.

- **(a)** le prédicat lit la carte **avec les runes déjà tirées** ; s'il ne laisse rien, la carte reçoit moins de
  runes ;
- (b) la boutique tire une autre carte ;
- (c) les deux replis restent.

**1** écarte (c) : `:141` pose `sharp` sans éligibilité (D61) et `:140` reposerait une rune plafonnée (D75).
**7** écarte (b) : il change le tirage des cartes de l'étal. **Choix : (a)**, et `'sharp'` disparaît. Le repli sans
exclusion `:140` reste pour les runes sans plafond — deux `sharp` sur une pré-forgée restent possibles, « une rune
par type » est E2.

#### A13 — Le vocabulaire des types d'effet dans l'éditeur *(apparue à la rédaction)*

`eligibleEffects`, `excludesEffects` et `deltas[].effect` nomment des types d'effet, que seul le registre de
stratégies connaît (`effect_strategy.dart:35-40`) ; aucune énumération ne les porte. Les deux premières sont des
**listes de chaînes**, ce qu'aucun `vocabularyKey` livré ne vise (`lib/services/content_editor/entity_descriptor.dart:222`,
`:253`, `:277`, `:310`, `:339`). Un motif nu (`eligibleEffects`) désigne la liste entière, que la famille du
vocabulaire refuse comme non-chaîne (`entity_validator.dart:264-266`) et que le formulaire rendrait en un seul choix
(`field_kind.dart:42`). Un motif d'éléments (`eligibleEffects[]`) parcourt bien chaque élément
(`field_path.dart:42-54`), mais `knownValues` range les éléments d'une liste de chaînes sous la clé nue
(`known_values.dart:40-43`) : `vocabularyOf` (`:78-91`) n'admettrait alors que les valeurs du gabarit, et
`enduring.json` serait refusé.

- **(a)** des `vocabularyKeys` sur les éléments — `eligibleEffects[]`, `excludesEffects[]`, `deltas[].effect`,
  `deltas[].statusId` —, comme `effects[].type` des cartes ; **`vocabularyOf` lit, pour un motif d'éléments de liste
  de chaînes (`clé[]`), les valeurs que `knownValues` range sous la clé nue** ; admises : les valeurs déjà employées par
  les fichiers de runes et celles du gabarit ; un test d'intégrité vérifie que chaque type nommé par une rune livrée a
  sa stratégie ;
- (b) une liste constante des six types dans le modèle, refusée au chargement si inconnue, lue par le descripteur,
  tenue en parité avec le registre par un test ;
- (c) du texte libre.

**5** tranche : (c) laisse passer la faute de frappe qu'un éditeur validant existe pour refuser (ADR-100) ; (b) écrit
les six noms une seconde fois, à côté du registre ; (a) généralise d'une règle le mécanisme qui sert déjà les cartes —
dans `vocabularyOf` seul : `knownValues` et le panneau de référence qui le lit (`content_editor_screen.dart:775`) ne
changent pas — et ne déclare aucun nom : le gabarit ne porte que ceux de son exemple (§6), pas la liste des six.
**Choix : (a)**. Sa limite, celle des cartes : un type d'effet qu'aucun fichier de rune ni le gabarit n'emploie n'est
pas admis par l'éditeur — `eligibleEffects[]` admet `damage` et `armor`, `excludesEffects[]` `gain_mana` et `draw`,
`deltas[].effect` les cinq types que les huit runes emploient ; aucune rune du programme n'en demande un autre (§4.1).
Le formulaire montre ces deux listes en listes de texte (`field_kind.dart:56`) ; la validation juge chaque élément.

#### Récapitulatif

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Forme de l'applicateur | champs à plat · deltas typés · effets de carte ajoutés · `switch` | 1 écarte le `switch`, 4 | Deltas typés, `CardDelta`, couture *(delta, niveau)* |
| A2 | Chemin des effets ajoutés | registre de stratégies · bloc propre aux runes | 5 | Le registre ; `GainSource.rune` disparaît |
| A3 | Place du code | modèle + `ForgeRuneRules` · tout en service · tout en modèle | 5 | Applicateur, borne, analyseur au modèle ; prédicat dans `ForgeRuneRules` |
| A4 | `switch` d'affichage | en donnée · laissés à E2 · emoji seuls | 4 | En donnée dès E1 |
| A5 | Portée de G1 | dégâts et armure · + soin · tout effet multiplié · par carte | 2 | Tout effet que la rareté multiplie |
| A6 | G1 face à G2 | G1 s'arrête · G1 l'emporte · compensation · pas de fusion | 1, puis 2 | G1 s'arrête aux effets gelés |
| A7 | Base et arrondi du pourcentage | rareté · commune ; total · par niveau · par exemplaire ; flottant · entier | 1 ; 1 puis 2 ; 2 | Base à la rareté, niveau total, entier demi vers le haut |
| A8 | Déclaration du plafond | obligatoire, `null` · facultative · sentinelle | 1 puis 6 | Clé obligatoire, `null` = sans plafond |
| A9 | Fusion de cartes au-delà | bornée · refusée · sommée | 1 | Bornée |
| A10 | Forge de Fusion au-delà | non proposée · bornée · sommée | 1 puis 6 | Non proposée |
| A11 | Feu sans rune éligible | refus à la sélection · forge vide · repli `sharp` | 1 puis 6 | Refus à la sélection |
| A12 | Boutique sans rune éligible | moins de runes · autre carte · replis | 1 puis 7 | Moins de runes |
| A13 | Vocabulaire des effets | vocabulaire du disque sur les éléments · liste au modèle · texte libre | 5 | Vocabulaire du disque sur `clé[]`, lu par `vocabularyOf` sous la clé nue ; intégrité par test |

---

## 2. Périmètre

**Dans E1**

- les champs neufs du fichier de rune (`eligibleEffects`, `excludesEffects`, `requiresMinCost`, `excludesRunes`,
  `maxLevel`, `deltas`), la suppression de `valueMultiplier`, et les huit fichiers de `assets/data/forge_upgrades/` ;
- `CardDelta` et ses trois sortes, l'applicateur (`EffectiveCard`), G1 et G2 ;
- la réécriture de `EffectResolver.resolveCard` : plus de `switch`, plus de bloc élémentaire, plus de multiplicateur
  écrit en ligne, plus d'armure de rune à part — et la pose des statuts élémentaires par `addStatus` (A4 de la spec E0) ;
- `CardInstance.exhaustsOnPlay` lu sur la donnée ; `CardInstance.rarityMultiplier` et `GainSource.rune` supprimés ;
- le prédicat d'éligibilité et ses trois lecteurs ; la borne `maxLevel` et ses cinq lecteurs ;
- le renommage `forgeSlotBonus` → `fusionRank` ;
- les six rendus et le tutoriel sur l'applicateur ; les `switch` d'affichage remplacés par la donnée ;
- le descripteur de rune de l'éditeur, et la lecture par `vocabularyOf` des éléments d'une liste de chaînes (A13) ;
  une chaîne ARB par langue ; la prose du tutoriel qui dit le multiplicateur (§5.4) ;
- les tests (§8).

**Hors d'E1**

| Sujet | Où |
|:---|:---|
| La fusion qui propose une rune, l'héritage de D13 sans plafond de runes par carte, l'affûtage, le Puits, la copie du deck en boutique, les pré-forgées bornées par `fusionRank` | E2 |
| La suppression de la capacité, de `pools`, de `stackable` ; `minFusionRank` ; « une rune par type » hors des runes que D75 ferme à leur plafond | E2 |
| `baseMaxForgeUpgrades`, son gabarit de carte (`entity_descriptor.dart:238`), les sept lecteurs de la capacité (revue §2.1) | Inchangés — E2 |
| `cheap`, `precise`, `spectral` et leurs sortes de delta | E2 |
| `requiresCost`, `costs`, les cinq runes de pipeline et leurs sortes | Vague 5 (P-44 lot 1) |
| `retain` | P-44 lot 3 |
| Les évolutions de signature, `SignatureEvolutionData` et leurs sortes de delta | Vague 5 |
| La valeur de `freeze` lue (statuts proportionnels), et `freezing` qui perd son plafond | Vague 5 (P-44 lot 1) |
| Le badge « Usage unique » et les particules d'épuisement qui ignorent *Persistant* (ADR-094, Conséquences) | Non planifié — signalé pour la file |
| La mythique qui monte un `maxLevel` (D42 c) | E3 |
| Toute rune neuve ; tout rééquilibrage de carte | Aucun |
| `tool/simulations/d26_economy_sim.dart` | Non touché (§9) |

---

## 3. Données

### 3.1. Le fichier d'une rune

`assets/data/forge_upgrades/sharp.json` après E1 :

```json
{
  "id": "sharp",
  "name_en": "Sharp",
  "name_fr": "Tranchant",
  "description_en": "+{val} Damage on the card (+{percent}% of base, at least +{tier})",
  "description_fr": "+{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier})",
  "icon": "hardware_rounded",
  "color": "redAccent",
  "pools": ["common", "uncommon", "rare"],
  "eligibleEffects": ["damage"],
  "maxLevel": null,
  "deltas": [
    { "type": "percentBonus", "effect": "damage", "valuePercentPerLevel": 15 }
  ],
  "weight": 100,
  "emoji": "⚔️"
}
```

| Clé | Avec E1 | Contrainte, refusée par `ForgeUpgradeData.fromJson` sinon | Lue par |
|:---|:---|:---|:---|
| `pools` | **Reste** | Inchangée | Forge du feu, boutique (D68) |
| `eligibleCardTypes` | **Reste** sur six runes, quitte `sharp` et `hardened` | Inchangée | Prédicat |
| `eligibleEffects` | Neuve | Absente : toute carte. Sinon une liste **non vide** de types d'effet — `[]` serait « éligible à rien » | Prédicat, sur les effets propres de la carte |
| `excludesEffects` | Neuve | Absente ou `[]` : aucune exclusion. Sinon une liste de types d'effet | Prédicat, sur les effets propres de la carte |
| `requiresExhaust` | **Reste** | Inchangée | Prédicat |
| `requiresMinCost` | Neuve | Entier ≥ 0, défaut 0 ; négatif ou non entier refusé | Prédicat, sur `currentCost` |
| `excludesRunes` | Neuve | Absente : aucune. Sinon une liste non vide d'ids de rune ; **son propre id refusé**. L'existence des ids est vérifiée par le test d'intégrité et par l'éditeur, pas au chargement (le chargeur ne voit pas les autres runes) | Prédicat, symétrique |
| `stackable` | **Reste** | Inchangée | Ses lecteurs d'aujourd'hui, et eux seuls (§4.9) : E1 ne lui en ajoute aucun — les infobulles lisent `maxLevel` (§5.2) |
| `maxLevel` | Neuve, **obligatoire** (A8) | `null` : sans plafond ; sinon un entier ≥ 1. Clé absente, 0, négatif ou non entier refusés | La borne (§4.7) |
| `deltas` | Neuve, **obligatoire** | Liste **non vide** d'entrées typées (§4.1) ; type inconnu ou paramètre manquant refusé | L'applicateur |
| `valueMultiplier` | **Supprimée** | — | Remplacée par `valuePercentPerLevel` dans un delta |
| `weight`, `emoji`, `icon`, `color`, noms, descriptions | Restent | Inchangées | — |

Chaque refus est accumulé par `GameDataLoader.throwIfFailed` avec ceux des autres catégories, et montré par la
famille 7 de l'éditeur, qui appelle le même `fromJson`.

### 3.2. Les huit fichiers

| Rune | S'ajoute | Se retire | **Reste**, inchangé |
|:---|:---|:---|:---|
| `sharp` | `eligibleEffects: ["damage"]` ; `maxLevel: null` ; `deltas: [percentBonus damage 15]` ; descriptions (§5.1) | `eligibleCardTypes`, `valueMultiplier` | `pools` (3), `weight: 100`, nom, emoji, icône, couleur |
| `hardened` | `eligibleEffects: ["armor"]` ; `maxLevel: null` ; `deltas: [percentBonus armor 15]` ; descriptions (§5.1) | `eligibleCardTypes` (`attack`, `skill`), `valueMultiplier` | `pools` (3), `weight: 100` |
| `quick` | `maxLevel: 1` ; `deltas: [addEffect draw, 1 par niveau]` | — | `pools` (`uncommon`, `rare`), `eligibleCardTypes` (3), `weight: 60`, descriptions |
| `eco` | `maxLevel: 1` ; `requiresMinCost: 1` ; `deltas: [addEffect gain_mana, 1 par niveau]` | — | `pools` (`rare`), `eligibleCardTypes` (3), `weight: 40`, descriptions |
| `burning` | `maxLevel: null` ; `deltas: [addEffect apply_status burn, 1 et 1 par niveau]` | — | `pools` (3), `eligibleCardTypes: ["attack"]`, `weight: 80` |
| `freezing` | `maxLevel: 1` ; `deltas: [addEffect apply_status freeze, 1 et 1 par niveau]` | — | `pools` (3), `eligibleCardTypes: ["attack"]`, `weight: 80` |
| `shocking` | `maxLevel: null` ; `deltas: [addEffect apply_status shock, 1 et 1 par niveau]` | — | `pools` (3), `eligibleCardTypes: ["attack"]`, `weight: 80` |
| `enduring` | `maxLevel: 1` ; `excludesEffects: ["gain_mana", "draw"]` ; `excludesRunes: ["eco", "quick"]` ; `deltas: [removeExhaust]` | — | `pools` (`rare`), `eligibleCardTypes` (3), `requiresExhaust: true`, `stackable: false`, `weight: 30` |

**Aucun `weight` ne change, ni l'`eligibleCardTypes` des six runes autres que `sharp` et `hardened`** : c'est la
condition du diff vide de la simulation (§9). Aucun fichier neuf, aucun dossier : `tool/sync_assets.dart` n'est pas
à relancer. `enduring` garde `stackable: false` à côté de `maxLevel: 1` : `stackable` vit jusqu'à E2 (D68), qui le
supprime.

### 3.3. Le modèle

| Où | Avec E1 |
|:---|:---|
| `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) | Les champs de §3.1 ; `valueMultiplier` (`:21`, `:37`, `:57`, `:76`) supprimé ; `toJson` (`:63-80`) écrit les champs neufs, `maxLevel` toujours ; `getDescription` (`:86-92`) reçoit la `CardData`, la rareté et le niveau déjà porté (§5.1). Gagne la borne `boundLevel` (§4.7) et **l'analyseur unique** des références `id:niveau` — aujourd'hui `ForgeRuneRules._tierOf` (`forge_rune_rules.dart:36-41`), privé —, sous deux formes : `parseRef`, qui lit **une** référence (`id:niveau` → `(id, niveau)`, ou rien si elle est mal formée ou de niveau nul), et `levelsOf`, son agrégat, qui additionne les niveaux par id. `fusionOptionsFor`, qui garde les références d'origine et compte les exemplaires (`:63`, `:69`, `:72-73`), lit `parseRef` ; l'applicateur, `exhaustsOnPlay`, le prédicat, `consolidate` et les infobulles lisent `levelsOf`. ADR-094 D5 tient : un seul analyseur |
| `CardDelta` (`lib/models/data/card_delta.dart`, neuf) | Les trois sortes de §4.1, leur lecture JSON, et `CardDelta.typeNames`, la liste des `type` admis, que lit le descripteur (ADR-100 D1 : le vocabulaire est lu sur le parseur) |
| `EffectiveCard` (`lib/models/effective_card.dart`, neuf) | L'applicateur (§4.2) |
| `CardRarity` (`lib/models/data/card_data.dart:9-45`) | `forgeSlotBonus` (`:33-39`) **renommé `fusionRank`**, mêmes valeurs — 0 à 4 de `common` à `legendary`, 0 pour `unique` —, doc : « le nombre de fusions qu'il a fallu pour atteindre cette rareté ». Gagne `multiplier` (1,0 · 1,2 · 1,4 · 1,6 · 2,0 ; 1,0 pour `unique`), la table de `CardInstance.rarityMultiplier` déplacée, dans un `switch` exhaustif comme `next` et `fusionRank`, et `scaleValue` (G1, §4.3). `forgeCapacityAt` (`:142-143`) lit `fusionRank` |
| `CardInstance` (`lib/models/card_instance.dart`) | `rarityMultiplier` (`:35-50`) supprimé — le getter a sept lecteurs, dont `ui_card.dart:67`, qui le passe en paramètre à deux rendus : le multiplicateur se calcule ainsi à huit sites, qui lisent tous l'applicateur (§4.2) ; `exhaustsOnPlay` (`:30-33`) lit l'applicateur (§4.5) ; un accesseur `effective` rend l'`EffectiveCard` de l'instance, sur le catalogue du registre (`GameDataRegistry.instance`, comme `ForgeUpgradeData.getById`). `currentCost` (`:21`) ne change pas : c'est la couture que `cheap` lira en E2 |
| `GainSource` (`lib/game/systems/stat_gains.dart:11-23`) | `rune` supprimé (A2) |

---

## 4. Le moteur

### 4.1. Les sortes de delta

Une entrée de `deltas` porte un `type` et ses paramètres **par niveau** ; appliquée au niveau `L` d'une rune, elle
agit ainsi :

| `type` | Paramètres | Au niveau L | Runes d'E1 |
|:---|:---|:---|:---|
| `percentBonus` | `effect` (type d'effet), `valuePercentPerLevel` (entier > 0) | Chaque effet **propre** de la carte de ce type gagne `max((p × L × B + 50) ~/ 100, L)`, où `p` est le pourcentage et `B` la valeur de cet effet à la rareté de la carte (A7) | `sharp` (`damage`, 15), `hardened` (`armor`, 15) |
| `addEffect` | `effect` (type d'effet), `valuePerLevel` (entier > 0) ; pour `apply_status`, `statusId` et `durationPerLevel` (entier > 0), exigés — refusés pour tout autre type | Ajoute l'effet de valeur `valuePerLevel × L` (et de durée `durationPerLevel × L`), résolu **avant** les effets de la carte ; jamais multiplié par la rareté ni visé par un `percentBonus` | `quick` (`draw`), `eco` (`gain_mana`), `burning`, `freezing`, `shocking` (`apply_status` : `burn`, `freeze`, `shock`) |
| `removeExhaust` | — | La carte ne s'épuise plus, **quel que soit L** (ADR-094 D4) | `enduring` |

La formule du pourcentage n'est écrite qu'une fois, dans `percentBonus`, et sert l'applicateur comme le gabarit de
description (§5.1).

**Où tombent les neuf autres runes** — une forme indicative, aucun fichier n'est écrit ici. Une rune d'un mécanisme
déjà servi est un fichier ; une sorte neuve s'écrit une fois, avec le lecteur de son lot.

| Rune | Lot | Deltas | Éligibilité |
|:---|:---|:---|:---|
| `cheap` | E2 | Une sorte neuve, le coût réduit (−1, plancher 0), que `currentCost` lira | `requiresMinCost: 1`, `excludesRunes: ["eco"]` — champs d'E1 |
| `precise` | E2 | Une sorte neuve, le critique de la carte, lu par `DamagePipeline.calculate` | Par effet (arbitrage d'E2) |
| `spectral` | E2 | `percentBonus damage 40` — sorte d'E1 — et une sorte neuve qui épuise | Par effet |
| `piercing`, `lifesteal`, `splash`, `echo` | Vague 5 | Une sorte neuve chacune : armure ignorée, soin sur les dégâts infligés, débordement, rejeu | Par effet ; une condition de cible pour `splash`, à poser en vague 5 |
| `transfusion` | Vague 5 | Une sorte neuve, le remboursement d'une part du coût en PV | `requiresCost`, vague 5 |
| `retain` | P-44 lot 3 | Une sorte neuve, la carte reste en main | — |

### 4.2. L'applicateur

```dart
// lib/models/effective_card.dart
class EffectiveCard {
  final List<CardEffect> addedEffects; // ajoutés par les runes, résolus en premier
  final List<CardEffect> effects;      // les effets propres, alignés un à un sur CardData.effects
  final bool removesExhaust;

  /// La couture commune aux runes et, en vague 5, aux évolutions de signature.
  static EffectiveCard apply(CardData data, CardRarity rarity,
      Iterable<(CardDelta, int)> deltas);

  /// Les runes d'une carte traduites en paires (delta, niveau).
  static Iterable<(CardDelta, int)> runeDeltas(List<String> runes,
      Iterable<ForgeUpgradeData> catalog);
}
```

`apply`, fonction pure :

1. **Les effets propres** : chaque effet de `data.effects` prend sa valeur à la rareté — `scaleValue` (G1) sauf pour
   `draw` et `gain_mana` (G2), qui gardent la valeur de la donnée (§4.3). `effects` a la longueur et l'ordre de
   `data.effects` : un rendu peut les lire en regard.
2. **Les deltas**, dans l'ordre reçu : `percentBonus` ajoute à chaque effet propre visé, sur sa valeur de l'étape 1 —
   deux pourcentages sur un même effet ne se composent pas ; `addEffect` ajoute à `addedEffects` ; `removeExhaust`
   lève `removesExhaust`.

`runeDeltas` regroupe les runes de la carte par id, **additionne les niveaux de leurs exemplaires** (D75, A7), dans
l'ordre de première apparition, et rend pour chaque id les deltas de sa rune avec ce niveau total. Une référence mal
formée ou de niveau nul est ignorée, comme `ForgeRuneRules` l'ignore aujourd'hui ; un id absent du catalogue n'a pas
de delta, et ne fait rien.

**Ses lecteurs, et seulement lui.** La formule « +2 par niveau » est écrite à six endroits, et le multiplicateur de
rareté — que G1 et G2 changent — se calcule à huit sites : tous lisent l'`EffectiveCard`.

| Site | La formule des runes | Le multiplicateur de rareté |
|:---|:---|:---|
| Le moteur, `EffectResolver.resolveCard` | `effect_resolver.dart:155`, `:158` | `:235` |
| Le rendu Flame de la carte, les pastilles | `card_text_renderer.dart:97-109` (par `valueMultiplier`, `:106-108`) | `:115` |
| Le rendu Flame de la carte, l'infobulle | `card_text_renderer.dart:359-369` (`:367-368`) | `:372` |
| La carte Flame, sa description | `card_component.dart:346-356` (`:354-355`) | `:359` |
| La carte Flutter, l'infobulle | `ui_card/ui_card_helpers.dart:348-358` (`:356-357`) | `:361` |
| La carte Flutter, la description compacte | `ui_card/card_compact_description.dart:43-53` (`:51-52`) | `:59` |
| Le tutoriel, le jeu d'une carte | — | `lib/tutorial/tutorial_engine.dart:386` |
| Le tutoriel, la valeur affichée | — | `lib/tutorial/widgets/tutorial_play_card_widget.dart:27` |

`UiCard` (`lib/ui/widgets/ui_card.dart`) porte aujourd'hui le multiplicateur, un `double` (`:19`, `:38`, `:67`, `:85`,
`:99`), qu'il passe à ses deux rendus (`:161`, `:277`), avec les seuls `effects` de la carte (`:22`, `:70`, `:102`) ;
son champ `rarity` (`:15`) est un libellé traduit (`:63`, `:95`), pas une `CardRarity`. Il ne garde pas la `CardData`
qu'`EffectiveCard.apply` demande. **Avec E1, `UiCard` porte la `CardData` et la `CardRarity` de la carte à la place du
multiplicateur** — ses deux factories les ont en main (`fromInstance`, `:59-77` : `card.data`, `card.rarity` ;
`fromData`, `:91-109` : `card`, `card.rarity`) — et ses deux rendus appellent l'applicateur sur elles et sur
`forgeUpgrades` ; le libellé `rarity` reste ce qu'il est. Le tutoriel appelle la même fonction pure que le jeu
(ADR-081). L'épuisement lit aussi l'applicateur (§4.5).

**Les rendus ne lisent que `effects`**, aligné sur `data.effects`, pour leurs pastilles et leurs lignes d'effet — les
boucles d'aujourd'hui (`card_text_renderer.dart:113`, `:371`, `card_component.dart:358`,
`ui_card/card_compact_description.dart:57`, `ui_card/ui_card_helpers.dart:360`) gardent leur forme, sur les valeurs de
l'applicateur. Les `addedEffects` ne sont dits que par la ligne de leur rune (§5.2), comme aujourd'hui : aucune pastille
ni ligne d'effet neuve sur la carte.

### 4.3. G1 et G2

`CardRarity.scaleValue(int base)` : à partir de `base`, pour chaque palier franchi de `common` jusqu'à la rareté —
`fusionRank` paliers —, `v = max(round(base × multiplicateur du palier), v + 1)`. Une base nulle ou négative est
rendue telle quelle ; `unique` (`fusionRank` 0) rend la base, comme son multiplicateur 1,0 aujourd'hui. `fusionRank`
gagne ainsi en E1 un second lecteur, qui dit exactement son sens.

G2 : `draw` et `gain_mana` ne passent pas par `scaleValue` — une constante de l'applicateur, seul endroit qui la lise.

| Base | Aujourd'hui, de commune à légendaire | Avec G1 |
|---:|:---|:---|
| 1 | 1 · 1 · 1 · 2 · 2 | 1 · 2 · 3 · 4 · 5 |
| 2 | 2 · 2 · 3 · 3 · 4 | 2 · 3 · 4 · 5 · 6 |
| 3 | 3 · 4 · 4 · 5 · 6 | 3 · 4 · 5 · 6 · 7 |
| 4 | 4 · 5 · 6 · 6 · 8 | 4 · 5 · 6 · 7 · 8 |
| 5 et plus (5, 6, 8, 10, 12) | Inchangé | Inchangé |

Les multiplications ne tombent jamais sur une demie exacte (×1,2, ×1,4, ×1,6 d'un entier n'en donnent pas) :
l'arrondi d'aujourd'hui reste.

### 4.4. La résolution

`EffectResolver.resolveCard` (`effect_resolver.dart:125-264`) :

| Aujourd'hui | Avec E1 |
|:---|:---|
| `canPlayCard`, `consumeResource(mana: card.currentCost)` (`:133-137`) | Inchangés |
| Le `switch` des runes (`:147-176`, cases `:153-175`) | Supprimé |
| Pioche de `quick`, mana d'`eco` (`:178-185`) | Les `addedEffects`, par le registre (A2) |
| Le bloc élémentaire (`:187-231`) : éligibilité en dur (`type == attack`, `:188`), `createStatus` (`:195`, `:199`, `:203`), **concaténation** à la liste de l'ennemi (`:216`, `:225`) | Supprimé. Les statuts sont des `addedEffects` `apply_status`, que `ApplyStatusEffectStrategy` pose **par `addStatus`, sans source** (`strategies.dart:165-189`) — A4 de la spec E0. L'éligibilité est dans la donnée seulement |
| Le multiplicateur écrit en ligne et les bonus de rune (`:233-240`) | La valeur de l'effet de l'`EffectiveCard`, passée telle quelle en `scaledValue` |
| L'armure de `hardened` sur une carte sans armure (`:256-261`) | Supprimée : la rune n'est plus proposée sur une telle carte (D61), et `percentBonus` ne vise que les effets que la carte porte |

La boucle devient : pour chaque effet de `addedEffects`, puis de `effects`, la stratégie de son type. Les stratégies
ne changent pas (ADR-061) ; `createStatus` garde la signature qu'E0 lui a donnée.

**Ce que la pose par `addStatus` change au jeu** — le chiffrage de la spec E0, A4, livré ici : seulement quand un
statut de rune tombe sur une cible qui porte déjà ce statut. À bonus de Puissance nul (le Berserker) et en commune :
*Coup de Tonnerre* portant `shocking:1`, joué trois fois
sur la même cible dans le tour : le second coup reçoit +3 et le troisième +5, au lieu de +2 et +3 — chaque choc de
rune rejoint le premier et compte (`lib/game/services/damage_pipeline.dart:31-43` n'en lit qu'un). Une Attaque
portant `burning:2`, jouée deux fois : une brûlure de 4 pour 2 tours (4, puis 3) au lieu de deux de 2 (4, puis 2).
Le gel : aucun effet de cumul. *Boule de Feu* portant `burning:1` fait toujours une seule brûlure, 3 pendant 2 tours :
la rune pose avant la carte, comme aujourd'hui.

### 4.5. L'épuisement

`CardInstance.exhaustsOnPlay` : un Pouvoir toujours ; une carte `isExhaust`, sauf si son `EffectiveCard` porte
`removesExhaust`. ADR-094 D4 tient — la seule règle d'épuisement, quel que soit le niveau —, mais l'id `'enduring'`
quitte le code (`card_instance.dart:33`) : la donnée le dit. Lecteur inchangé : `DeckNotifier.playCard`
(`lib/game/controllers/deck_controller.dart:268`).

### 4.6. Le prédicat d'éligibilité

```dart
// lib/game/services/forge_rune_rules.dart
static bool isEligible(ForgeUpgradeData rune, CardInstance card,
    Iterable<ForgeUpgradeData> catalog)
```

Fonction pure. Vraie si et seulement si, à la fois :

1. `eligibleCardTypes` est absente ou contient le type de la carte ;
2. `eligibleEffects` est absente, ou un **effet propre** de la carte (`card.data.effects`) est de l'un de ces types ;
3. aucun effet propre n'est de l'un des types d'`excludesEffects` ;
4. `requiresExhaust` est faux, ou la carte est `isExhaust` ;
5. `card.currentCost ≥ requiresMinCost` — le coût **courant** (D61) ;
6. **symétrie** (D61) : aucune rune portée par la carte n'est nommée par l'`excludesRunes` de `rune`, et aucune rune
   portée ne nomme `rune` dans le sien — une rune portée absente du catalogue est ignorée ;
7. **le plafond n'est pas atteint** (D75) : `rune.boundLevel(1, carried: niveau total des exemplaires de rune.id sur la
   carte) ≥ 1` — vrai sans plafond, vrai tant que la somme reste sous `maxLevel`.

Les effets **ajoutés** par les runes ne comptent pas en 2 et 3 : *Persistant* refuse une carte qui pioche par
elle-même ; la pioche de *Véloce* est fermée par `excludesRunes` (D51). `pools` n'est **pas** une condition : c'est le
ciblage par rareté des deux tirages, qu'ils gardent (D68) ; E2 y substituera `minFusionRank`, au rang que la fusion
atteint.

**Ses trois lecteurs**, et aucun autre :

| Lecteur | Aujourd'hui | Avec E1 |
|:---|:---|:---|
| Forge du feu, `_getEligibleUpgradesForPool` (`forge_upgrade_dialog.dart:80-101`) | `pools`, types et `requiresExhaust` en ligne (`:86-96`) | `pools.contains(pool)` et `isEligible` ; le reste du tirage — ciblage par rareté (`:103-141`), exclusion des ids déjà proposés et son repli (`:194-230`, `:172`) — ne change pas ; le repli sur `'sharp'` (`:173`) disparaît (A11) |
| Boutique, `_getEligibleUpgradesForPool` (`shop_controller.dart:51-75`) | `pools`, ids déjà tirés, types, `requiresExhaust` (`:57-70`) | `pools.contains(pool)`, ids déjà tirés, et `isEligible` **sur la carte avec les runes déjà tirées** ; le repli sur `'sharp'` (`:141`) disparaît, et une carte sans rune éligible en reçoit moins (A12) |
| Sélection du feu (`rest_card_selection_screen.dart:29-38`) | Refuse une carte pleine (`:30`) | Refuse en outre une carte sans aucune rune éligible du catalogue, avec un message (§5.3, A11) — le test de capacité reste, avant |

### 4.7. La borne de niveau

```dart
// lib/models/data/forge_upgrade_data.dart
int boundLevel(int requested, {int carried = 0})
```

Rend `requested` sans plafond ; sinon `min(requested, maxLevel − carried)`, jamais négatif. **Une fonction, cinq
lecteurs** : les quatre endroits qui écrivent un niveau (D72), et le prédicat (D75).

| Lecteur | Aujourd'hui | Avec E1 |
|:---|:---|:---|
| `consolidate` (`forge_rune_rules.dart:46-55`) — la fusion de cartes 3 → 1 (`deck_controller.dart:315`, `deck_screen.dart:226`) | Somme des tiers d'une rune cumulable, 1 pour une non cumulable (`:52`) | La même, **puis `boundLevel(somme)`** (A9) ; la branche `isStackable` reste (D68) |
| `fusionOptionsFor` (`:60-78`) — le nœud Forge de Fusion | Une option par rune cumulable portée au moins deux fois, au niveau somme (`:69`, `:73`) | La même, références lues par `parseRef` (§3.3), **seulement si `boundLevel(somme) == somme`** (A10) |
| Tirage du feu (`forge_upgrade_dialog.dart:175-185`) | Niveau 1, 2 ou 3 à 80, 15 et 5 % sur une rune cumulable | Le même tirage, **puis `boundLevel(niveau, carried: ce que la carte porte de cet id)`** |
| Tirage des pré-forgées (`shop_controller.dart:143-153`) | Le même | Le même, **borné de même**, sur la carte avec les runes déjà tirées |
| Le prédicat (§4.6, condition 7) | — | `boundLevel(1, carried: …) ≥ 1` |

Le niveau qu'affiche une fente de la forge est donc celui que la carte recevra. `addForgeUpgrade`
(`deck_controller.dart:344-354`) écrit ce que le joueur a choisi, sans recalcul ; les copies d'une carte (Miroirs,
boss « cartes », `reward_controller.dart:180`, `:249`, `shop_controller.dart:351`, `draft_screen.dart:634`)
recopient des runes et n'écrivent aucun niveau neuf.

### 4.8. Ce que cela fait au jeu

**`sharp` et `hardened`** (D33), le bonus selon la valeur de l'effet à la rareté de la carte :

| Valeur de l'effet | Niv. 1 | Niv. 2 | Niv. 3 | Niv. 4 |
|:---|---:|---:|---:|---:|
| Aujourd'hui, quelle que soit la carte | +2 | +4 | +6 | +8 |
| 7 ou moins — *Frappe*, *Défense*, *Éveil*, *Boule de Feu* communes | +1 | +2 | +3 | +4 |
| 8 | +1 | +2 | +4 | +5 |
| 10 — *Mur de Fer* commun | +2 | +3 | +5 | +6 |
| 12 — *Frappe Lourde* commune, *Frappe* légendaire | +2 | +4 | +5 | +7 |

**L'offre de runes** — ce que le feu et la boutique ne proposent plus, sur une carte qui ne porte encore rien :

| Carte | Ne reçoit plus | Pourquoi |
|:---|:---|:---|
| Toute Attaque sans armure — *Frappe*, *Frappe Lourde*, *Boule de Feu*, *Trait de Glace*, *Coup Empoisonné*, *Attaque Rapide*, *Balayage*, *Coup de Tonnerre*, *Frappe Téméraire*, *Projectile Magique* | `hardened` | Aucun effet d'armure (D61). Elle y donnait 2 × niveau d'Armure à part (`effect_resolver.dart:256-261`), absente des effets que la carte affiche — ce gain disparaît avec elle |
| *Potion de Soin*, *Posture de Rage* | `hardened` | Idem |
| *Concentration*, *Focalisation*, *Surtension de Mana* | `hardened`, `eco`, `enduring` | Sans armure ; gratuites (D44) ; elles piochent ou rendent du mana (D44) — il leur reste `quick` |

La matrice complète que le prédicat rend sur les 23 cartes livrées, sans rune — `pools` mis à part, que les tirages
appliquent ensuite :

| Cartes | Runes éligibles |
|:---|:---|
| Attaques sans armure — les dix ci-dessus | `sharp`, `burning`, `freezing`, `shocking`, `quick`, `eco` |
| Attaques à armure — *Cri de Guerre*, *Châtiment* | les mêmes, et `hardened` |
| *Éveil*, *Défense*, *Mur de Fer* | `hardened`, `quick`, `eco` |
| *Bouclier Sacré* | `hardened`, `quick`, `eco`, `enduring` |
| *Potion de Soin* | `quick`, `eco`, `enduring` |
| *Forme Démoniaque*, *Métallisation*, *Posture de Rage* | `quick`, `eco` |
| *Concentration*, *Focalisation*, *Surtension de Mana* | `quick` |

Et, selon ce que la carte porte déjà : `eco` et `quick` ne se proposent plus sur une carte qui porte `enduring`, ni
`enduring` sur une carte qui porte `eco` ou `quick` (D51, D61) ; `eco`, `quick`, `freezing` et `enduring` ne se
reproposent plus sur une carte qui les porte (D75). `sharp` devient éligible à toute carte de dégâts, Compétence
comprise (D61) — aucune des 23 cartes d'aujourd'hui n'est une Compétence de dégâts : invisible avant la vague 5.

**Le plafond.** `eco`, `quick`, `freezing` et `enduring` ne dépassent plus le niveau 1, aux quatre endroits qui
écrivent un niveau, et une carte n'en porte plus deux exemplaires. `freezing:1` pose un gel d'une attaque ennemie
(`turn_phase_manager.dart:117-123`) — un niveau 2 ou 3, que le feu et la boutique tirent aujourd'hui une fois sur
cinq, en gelait deux ou trois.

**G1 et G2**, sur les cartes neutres, de commune à légendaire — les signatures, `unique`, ne fusionnent pas :

| Carte | Effet | Aujourd'hui | Avec E1 |
|:---|:---|:---|:---|
| *Coup Empoisonné* | dégâts 3 · Poison 1 | 3·4·4·5·6 · 1·1·1·2·2 | 3·4·5·6·7 · 1·2·3·4·5 |
| *Attaque Rapide* | dégâts 3 · pioche 1 | 3·4·4·5·6 · 1·1·1·2·2 | 3·4·5·6·7 · 1 partout |
| *Balayage* | dégâts 3 | 3·4·4·5·6 | 3·4·5·6·7 |
| *Trait de Glace* | dégâts 4 · Gel 1 | 4·5·6·6·8 · 1·1·1·2·2 | 4·5·6·7·8 · 1·2·3·4·5 (valeur non lue, A5) |
| *Coup de Tonnerre* | dégâts 4 · Électrocution 1 | 4·5·6·6·8 · 1·1·1·2·2 | 4·5·6·7·8 · 1·2·3·4·5 |
| *Cri de Guerre* | dégâts 4 · armure 4 | 4·5·6·6·8 (les deux) | 4·5·6·7·8 (les deux) |
| *Éveil* | armure 4 · pioche 1 | 4·5·6·6·8 · 1·1·1·2·2 | 4·5·6·7·8 · 1 partout |
| *Potion de Soin* | soin 3 | 3·4·4·5·6 | 3·4·5·6·7 |
| *Forme Démoniaque* | Puissance 2 | 2·2·3·3·4 | 2·3·4·5·6 |
| *Boule de Feu* | dégâts 6 · Brûlure 2 | 6·7·8·10·12 · 2·2·3·3·4 | 6·7·8·10·12 · 2·3·4·5·6 |
| *Métallisation* | armure par tour 2 | 2·2·3·3·4 | 2·3·4·5·6 |
| *Concentration* | pioche 2 | 2·2·3·3·4 | 2 partout |
| *Focalisation* | mana 1 | 1·1·1·2·2 | 1 partout |
| *Frappe*, *Défense*, *Mur de Fer*, *Frappe Lourde* | 6, 5, 10, 12 | — | Inchangés |

**Les autres changements que le lot livre**, conséquences de ses arbitrages : le mana d'`eco` fait entendre le son du
gain de mana, comme toute carte qui rend du mana (A2 — un seul chemin d'effets, le registre de stratégies) ; une
carte qui ne peut plus recevoir aucune rune est refusée à la sélection du feu, avec un message (A11) ; une pré-forgée à
qui ne reste aucune rune éligible en porte une de moins (A12) ; les **descriptions** des runes sont les mêmes sur la
carte, dans ses infobulles et à la forge, une ligne par rune au niveau qu'elle joue (A4, §5.1, §5.2) — les **noms**
non : l'infobulle écrit le niveau sur `maxLevel` (« Véloce »), quand la fente de la forge et le dialogue de fusion
gardent jusqu'à E2 leur suffixe de niveau sur `stackable` (« Véloce 1 », « Véloce (Niveau 1) »,
`forge/forge_slot_row.dart:197`, `deck_screen.dart:284`, `:362`) ; la prose du tutoriel dit G1 et G2 (§5.4).

### 4.9. Ce qui ne change pas

- **`pools`, `stackable` et la capacité, avec tous leurs lecteurs.** `pools` : les deux tirages
  (`forge_upgrade_dialog.dart:86`, `shop_controller.dart:57`). `stackable` : `ForgeRuneRules.isStackable`
  (`forge_rune_rules.dart:31-32`), lu par `consolidate`, `fusionOptionsFor` et les deux tirages, et l'affichage du
  niveau (`forge/forge_slot_row.dart:197`, `deck_screen.dart:282-285`, `:360-363`) — et par aucun lecteur neuf : les
  infobulles décident d'écrire le niveau sur `maxLevel` (§5.2). La capacité : ses sept lecteurs de
  la revue §2.1 — `rest_card_selection_screen.dart:30`, `forge_upgrade_dialog.dart:51`, `deck_controller.dart:318-321`,
  `deck_screen.dart:224-230`, `card_text_renderer.dart:519` et `ui_card.dart:69`, `:101`, `:241`,
  `shop_controller.dart:195`, `card_instance.dart:24` —, sur `forgeCapacityAt`, qui lit `fusionRank`.
- **Aucun écran ne change de déroulé** : feu (sélection, dialogue, fentes à 100 · 50 · 25 · 10 · 2 %, relances, achat de
  fentes, session anti-reroll), Forge de Fusion (sélection, liste des fusions, 80 × (N − 1) or), fusion 3 → 1 (dialogue
  d'héritage quand la capacité déborde), boutique (rareté, nombre de tirages de runes, prix — une pré-forgée sans rune
  éligible en reçoit moins, A12).
- Le format `id:niveau` de `CardInstance.forgeUpgrades` et `addForgeUpgrade`.
- Les stratégies d'effet (ADR-061), `DamagePipeline`, la Puissance, le critique ; `createStatus` et la règle de fusion
  par source d'E0.
- Le texte des cartes hors des chiffres que G1, G2 et les runes changent.

### 4.10. Les frontières

| Frontière | Ce que le lot voisin trouve |
|:---|:---|
| **E0 → E1** | `createStatus` avec sa signature finale, `sourceId` retenu par la seule branche `might` : les statuts des runes, posés sans source, fusionnent comme tout statut hors Puissance (spec E0, A1, A4). Aucune ligne d'E0 n'est réécrite |
| **E1 → E2** | `pools`, `stackable` et la capacité en place, avec leurs lecteurs : E2 les supprime avec la forge du feu et le nœud Forge de Fusion (D68). Le prédicat attend `minFusionRank` et le rang que la fusion atteint ; la donnée de `cheap` tient dans `requiresMinCost` et `excludesRunes`, sans code ; `currentCost` est la couture de sa sorte de delta. `consolidate` est déjà borné pour l'héritage de D13. **Constat** : la première fusion d'une *Concentration* n'a aucune rune éligible sous le prédicat d'E2 (A6) |
| **E1 → vague 5** | `CardDelta` et `EffectiveCard.apply` sont la couture des évolutions de signature : `SignatureEvolutionData` traduira ses entrées en paires *(delta, niveau)* et ajoutera ses sortes ; `requiresCost` entre dans le prédicat avec `costs` ; `freezing` perd son plafond avec les statuts proportionnels (fiche 8.5) |

---

## 5. Textes joueur

### 5.1. Les descriptions de `sharp` et `hardened`

| Rune | Français | English |
|:---|:---|:---|
| `sharp` | `+{val} Dégâts sur la carte (+{percent}% de la base, au moins +{tier})` | `+{val} Damage on the card (+{percent}% of base, at least +{tier})` |
| `hardened` | `+{val} Armure sur la carte (+{percent}% de la base, au moins +{tier})` | `+{val} Block on the card (+{percent}% of base, at least +{tier})` |

`ForgeUpgradeData.getDescription` reçoit, en plus du niveau et de la langue, la `CardData` de la carte, sa rareté
(`CardRarity`) et le niveau que la carte porte déjà de cette rune (`porté`, 0 par défaut) — jamais une `CardInstance`
(`forge_slot_row.dart:200` ne lui passe aujourd'hui que le niveau et la langue). `ForgeSlotRow`, qui ne connaît que sa
fente (`forge_slot_row.dart:8-23`), reçoit du dialogue la `CardInstance` qu'il forge (`forge_upgrade_dialog.dart:431-438`),
d'où il tire la donnée, la rareté et le niveau porté de l'id de la fente :

- `{tier}` : le niveau, comme aujourd'hui ;
- `{val}` : ce que la rune ajoute **à cette carte**, sur le niveau total que joue le moteur (A7) : `f(porté + niveau) −
  f(porté)`, où `f` est la formule de `percentBonus` appliquée au premier effet propre du type visé, à la rareté de la
  carte ; 0 si la carte n'en porte pas. **À la forge**, `porté` est le niveau que la carte porte déjà de cet id : la
  fente dit son gain marginal. **Dans une infobulle**, la ligne dit déjà le total des exemplaires (§5.2) : `porté`
  vaut 0 ;
- `{percent}` : `valuePercentPerLevel × niveau`, écrit `15%`, sans espace, comme les pourcentages du français existant.

Sur *Frappe* commune, au niveau 1 : « +1 Dégâts sur la carte (+15% de la base, au moins +1) ». Sur *Frappe* épique
(10 dégâts) qui porte déjà `sharp:1` (+2), une fente `sharp:1` affiche « +1 » : `f(2) − f(1) = 3 − 2`, le gain réel.
Les six autres descriptions ne changent pas : elles n'emploient que `{tier}`.

### 5.2. La ligne d'une rune dans les infobulles

Les trois listes de runes écrites en dur (`card_text_renderer.dart:451-488`, `lib/game/components/card_component.dart:452-506`,
`lib/ui/widgets/ui_card/ui_card_helpers.dart:443-479`) se composent de la donnée, **une ligne par id**, au niveau
total de ses exemplaires (`levelsOf`, §3.3) — le niveau que joue le moteur (A7) —, sous la forme que
`card_component.dart:504` emploie déjà : `<nom>[ <niveau>] : <description>`. Le niveau s'écrit quand le `maxLevel` de
la rune n'est pas 1 : une rune à niveau unique n'en a pas d'autre à dire. Ces listes ne lisent **jamais** `stackable`,
qui ne garde en E1 que ses lecteurs d'aujourd'hui (D68). Par exemple « Tranchant 2 : +4 Dégâts sur la carte (+30% de la
base, au moins +2) » sur une *Frappe* légendaire, au lieu de « Tranchant 2 (+4 Dégâts) » ; sur une *Frappe* épique qui
porte deux `sharp:1`, une seule ligne, « Tranchant 2 : +3 Dégâts… », le +3 que le moteur joue, au lieu de deux
« Tranchant 1 (+2 Dégâts) ».

Les emoji des rendus Flutter (`ui_card_helpers.dart:215-237`, lu par `ui_card/card_rune_sockets.dart:49`, et
`forge/forge_card_preview.dart:21-43`) sont lus dans la donnée, comme le rendu Flame les lit déjà. Les quatre `switch`
de secours de `forge_slot_row.dart:29-131`, qui ne servent que pour une rune absente du registre (`:190-201`),
disparaissent : une telle rune s'affiche sous son id, sans description, avec l'icône et la couleur par défaut.

### 5.3. Le refus du feu

| Clé ARB | Français | English |
|:---|:---|:---|
| `forgeNoEligibleRune` | `Aucune rune ne peut être ajoutée à cette carte.` | `No rune can be added to this card.` |

Sans placeholder ; déclarée dans `app_en.arb`, le gabarit (`l10n.yaml`) ; `flutter gen-l10n` régénère les trois
`app_localizations*.dart`. Le message de la carte pleine, écrit en ligne à côté (`rest_card_selection_screen.dart:31-36`),
n'est pas touché.

### 5.4. Le tutoriel

Sa prose dit la rareté comme un pur multiplicateur. Sous G1, une petite valeur gagne au moins 1 par fusion ; sous G2,
la pioche et le mana ne sont plus multipliés : trois textes deviendraient faux.

| Où | Aujourd'hui | Avec E1 — français | Avec E1 — English |
|:---|:---|:---|:---|
| Étape des cartes, `lib/tutorial/tutorial_data.dart:147-149` (fr), `:134-136` (en) | « …et la rareté multiplie la valeur de base. » | « …et la rareté augmente la valeur de base. » | "…and rarity raises the base value." |
| Étape « La Fusion de Cartes », `tutorial_data.dart:281-282` (fr), `:268-269` (en) | « La rareté **ne change jamais le coût en Mana** — elle multiplie les valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire. » | « La rareté **ne change jamais le coût en Mana** — elle augmente les valeurs : ×1,2 peu commun, ×1,4 rare, ×1,6 épique, ×2,0 légendaire, et toujours d'au moins 1 à chaque fusion. La pioche et le Mana qu'une carte rend ne grandissent pas avec la rareté. » | "Rarity **never changes a card's Mana cost** — it raises its values: ×1.2 uncommon, ×1.4 rare, ×1.6 epic, ×2.0 legendary, and always by at least 1 per merge. Cards drawn and Mana gained do not grow with rarity." |
| Encart « Fusion Complétée ! », `lib/tutorial/widgets/tutorial_merge_widget.dart:265-266` | « Même coût. Valeurs ×1,2. » / "Same cost. Values ×1.2." | « Même coût, rareté supérieure. » — vrai quelle que soit la carte fusionnée, une *Concentration* comprise | "Same cost, higher rarity." |

Le reste des deux étapes ne change pas. Aucun test ne lit cette prose — `test/tutorial/tutorial_prose_test.dart` ne
vérifie que les placeholders de l'étape de draft — et aucun n'est ajouté : un test qui recopierait une phrase la
figerait sans rien vérifier du jeu. Les commentaires de code qui disent « multipliée par la rareté »
(`lib/tutorial/widgets/tutorial_play_card_widget.dart:10`) suivent.

### 5.5. Ce qui ne change pas

Les noms des huit runes, leurs emoji, icônes et couleurs, les descriptions des six autres ; le texte des cartes ;
les noms des statuts.

---

## 6. L'éditeur de contenu

Le descripteur de rune (`entity_descriptor.dart:326-360`) :

| Élément | Avec E1 |
|:---|:---|
| `requiredKeys` (`:333`) | `{'pools'}`, inchangé : `pools` vit jusqu'à E2. `maxLevel` et `deltas` sont exigés par `ForgeUpgradeData.fromJson`, que la famille 7 appelle — un fait à un seul endroit |
| `enumListKeys` (`:334`) | `eligibleCardTypes`, inchangé |
| `enumKeys` | Neuf : `'deltas[].type': CardDelta.typeNames` — lu sur le parseur (ADR-100 D1) |
| `vocabularyKeys` (`:339`) | `color`, `icon`, plus `eligibleEffects[]`, `excludesEffects[]`, `deltas[].effect`, `deltas[].statusId` (A13) — des motifs d'**éléments** |
| `vocabularyOf` (`lib/services/content_editor/known_values.dart:78-91`) | Pour un motif `clé[]` dont la clé porte une liste de chaînes, lit aussi les valeurs que `knownValues` range sous la clé nue (`:40-43`). `knownValues` ne change pas (A13) |
| `referenceListKeys` | Neuf : `excludesRunes` → `EntityCategory.forgeUpgrade` — le mécanisme de P-49 : une liste non vide d'ids existants, une case à cocher par rune |
| Gabarit (`:348-359`) | Perd `valueMultiplier` ; gagne une rune d'exemple cohérente : `"eligibleEffects": ["damage"]`, `"excludesEffects": []`, `"requiresMinCost": 0`, `"maxLevel": 1` (une valeur prudente : un plafond oublié ne laisse pas monter une rune sans fin), `"deltas": [ { "type": "percentBonus", "effect": "damage", "valuePercentPerLevel": 15 } ]` — le gabarit de carte porte de même un effet `damage` d'exemple (`:235-237`). Il ne réécrit pas la liste des six types (A13). **Pas** `excludesRunes`, dont l'absence vaut « aucune », comme `classes` d'un passif |

Le gabarit valide (`test/unit/content_editor/entity_validator_test.dart:496-517` l'exige de tous). Une rune sans
plafond s'écrit `"maxLevel": null`, que le formulaire montre en JSON brut — `inferFieldKind` n'a pas de champ pour un
nombre nullable et retombe sur `rawJson` (`lib/services/content_editor/field_kind.dart:27-62`, `:61`).

Les commentaires qui citent `valueMultiplier` et le seul couple `color`, `icon` suivent, et deux autres que E1 rend
faux : `entity_descriptor.dart:330-332` (« `ForgeUpgradeData.fromJson` ne lève sur rien d'autre que `id` » — il lève
désormais sur `maxLevel`, `deltas` et les champs de §3.1) et `:342-347` (le filtrage par `eligibleCardTypes` qu'il
attribue à `shop_controller.dart:65`, que le prédicat remplace, §4.6).

---

## 7. La sauvegarde

**Rien à migrer ; `SaveMigrator.currentVersion` ne bouge pas.** Le format porte les runes d'une carte en `id:niveau`
(`card_instance.dart:71`, `:79`), qui ne change pas ; la donnée des runes n'est jamais sauvegardée, elle est relue du
registre. Une partie écrite avant `0.5.3` peut porter ce qu'E1 ne produit plus — `eco:3`, deux `eco:1`, `hardened` sur
une carte sans armure : la carte garde ses runes, l'applicateur les applique à leur niveau, la Forge de Fusion ne
propose pas de réunir des exemplaires au-delà du plafond (A10), et `hardened` y reste sans effet. Une session de forge
en cours (`RunState.forgeTargetSessions`) garde ses fentes. Rien de cela n'est testé ni annoncé : les sauvegardes ne
se transfèrent pas avant la `1.0.0`.

---

## 8. Tests

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| Le modèle de rune | `test/unit/forge_upgrade_data_test.dart` *(nouveau)* | Lecture des champs neufs ; refus : `maxLevel` absent, 0, négatif, décimal ; `eligibleEffects: []` ; `requiresMinCost` négatif ; `excludesRunes: []` ; son propre id dans `excludesRunes` ; `deltas` absent ou vide ; `type` inconnu ; `percentBonus` sans `effect` ou à pourcentage ≤ 0 ; `addEffect` `apply_status` sans `statusId` ou sans `durationPerLevel`, `durationPerLevel` sur un autre type. `excludesEffects: []` et `maxLevel: null` acceptés. `toJson` aller-retour. `levelsOf` : exemplaires additionnés dans l'ordre de première apparition, références mal formées ou de niveau nul ignorées. `boundLevel` : sans plafond, plafond, `carried` |
| Le prédicat | `test/unit/rune_eligibility_test.dart` *(nouveau)* | Chaque condition seule : type, effet propre présent, effet exclu, épuisement, coût courant ≥ minimum ; la symétrie dans les deux sens (`enduring` porté → `eco` refusé ; `eco` porté → `enduring` refusé) ; le plafond atteint par deux exemplaires additionnés ; une rune sans plafond reproposée ; un effet **ajouté** par une rune ne compte pas ; une rune portée inconnue ignorée |
| L'applicateur | `test/unit/effective_card_test.dart` *(nouveau)* | G1 : la table de §4.3 (bases 1 à 4, 5, 12 ; `unique` rend la base) ; G2 : `draw` et `gain_mana` inchangés à toute rareté ; `percentBonus` : la table de §4.8, la base prise à la rareté de la carte, `sharp:1` + `sharp:2` = `sharp:3`, deux effets de dégâts servis chacun, l'arithmétique entière (15 % × 3 × 30 = 14) ; `addEffect` : valeur et durée par niveau, résolu avant, ni multiplié ni visé par un pourcentage ; `removeExhaust` ; `effects` aligné sur `data.effects` ; `apply` reçoit des paires d'autre provenance que les runes |
| Les huit runes livrées | `test/unit/forge_upgrades_catalog_test.dart` *(nouveau)* — **un test par rune** | Sur le vrai registre, pour chacune : `maxLevel` (1 pour `eco`, `quick`, `freezing`, `enduring` ; `null` pour les quatre autres, clé présente) ; ses champs d'éligibilité exacts ; ses deltas exacts ; `weight` inchangé (100, 100, 80, 80, 80, 60, 40, 30) ; `eligibleCardTypes` inchangé pour les six, absent pour `sharp` et `hardened` ; `pools` inchangés ; `stackable` faux pour `enduring` seule. Puis **la matrice de l'offre** : pour les 23 cartes livrées, à leur rareté de donnée et sans rune — le prédicat ne lit pas la rareté —, l'ensemble des runes que le prédicat accepte, contre la matrice de §4.8 |
| La résolution | `test/unit/rune_resolution_test.dart` *(nouveau)* | Par `EffectResolver.resolveCard` : `sharp` et `hardened` selon D33 ; `quick` pioche, `eco` rend du mana ; les cas d'A4 — *Coup de Tonnerre* et `shocking:1` trois fois (+3, puis +5), `burning:2` deux fois (une brûlure de 4, 2 tours), le gel sans cumul, *Boule de Feu* et `burning:1` (3, 2 tours) — chaque statut de rune en **une** entrée, sans source ; une carte G1 (*Coup Empoisonné* légendaire) inflige 7 et pose 5 Poison |
| L'armure de rune à part | `test/unit/stat_gains_characterization_test.dart:116-119` | Il fige aujourd'hui `hardened:1` sur une carte sans armure : 2 Armure. Son cas devient « ne donne rien » — Armure 0 : la rune ne vise que les effets que la carte porte (§4.4). C'est le seul test qui garde ce fait |
| L'épuisement | `test/unit/deck_controller_test.dart:487-501` | Inchangés dans ce qu'ils vérifient, sur un registre qui porte `enduring` — l'épuisement lit désormais la donnée |
| La fusion de cartes | `test/unit/deck_controller_test.dart`, `test/unit/decoupled_forge_test.dart:214-244` | Trois `eco:1` → `eco:1` ; trois `sharp:1` → `sharp:3` ; `enduring` gardé au niveau 1 |
| `ForgeRuneRules` | `test/unit/forge_rune_rules_test.dart:72-128` | `consolidate` borné (rune de test à `maxLevel` 2 : `1 + 2` → 2) ; `fusionOptionsFor` : deux `eco:1` → aucune option ; `1 + 1` sous un plafond de 2 → proposée ; `2 + 1` → non |
| Les descriptions | `test/unit/decoupled_forge_test.dart:112-119` | Réécrit : `{val}`, `{percent}`, `{tier}` sur une `CardData` et une rareté données ; `{val}` marginal quand la carte porte déjà la rune |
| La boutique | `test/unit/shop_controller_test.dart` | Sur de nombreux tirages : aucune pré-forgée ne porte une rune non éligible, ni une rune plafonnée au-delà de son plafond ou deux fois ; une carte dont la seule rune éligible est plafonnée (*Concentration* : `quick`) en porte au plus une ; `:303` (rune non cumulable au niveau 1) reste |
| Le refus du feu | `test/widget/rest_card_selection_screen_test.dart` *(nouveau)* | Une *Concentration* peu commune portant `quick:1` est refusée au toucher avec le message de §5.3, sans ouvrir le dialogue ; une carte pleine garde son message d'aujourd'hui |
| L'offre du feu | `test/widget/forge_upgrade_dialog_test.dart` *(nouveau)* | Aucune fente ne propose `hardened` sur *Frappe* ni `eco` sur *Concentration* ; `eco` n'est jamais tiré au-dessus du niveau 1 ; sur une *Frappe* épique portant `sharp:1`, une fente `sharp:1` affiche « +1 », le gain marginal (§5.1) |
| La Forge de Fusion | `test/widget/forge_fusion_screen_test.dart` | Une carte portant deux `eco:1` n'est pas listée |
| `CardRarity` | `test/unit/card_rarity_test.dart` | `fusionRank` : 0 à 4, 0 pour `unique` ; `multiplier` ; les tests de capacité (`:48-65`) restent tels quels |
| Les rendus | `test/widget/ui_card_values_test.dart` *(nouveau)*, `test/widget/ui_card_rune_sockets_test.dart` | Une *Frappe* légendaire portant `sharp:2` montre 16 dégâts et la ligne « Tranchant 2 : +4 Dégâts… » ; une *Frappe* épique portant deux `sharp:1` montre 13 dégâts et **une** ligne « Tranchant 2 : +3 Dégâts… » ; une *Véloce* s'écrit sans niveau ; un *Éveil* épique montre 7 armure et pioche 1 ; l'emoji d'une prise vient de la donnée |
| Les ids de rune hors de la donnée | `test/unit/rune_ids_in_code_test.dart` *(nouveau)*, sur le modèle de `test/unit/stat_gain_single_passage_test.dart` | Aucune chaîne littérale égale à l'id d'une rune **livrée** — lus dans `assets/data/forge_upgrades/` — dans `lib/` ; aucune occurrence de `rarityMultiplier` dans `lib/` : la formule et les ids n'ont qu'un endroit |
| L'intégrité | `test/unit/referential_integrity_test.dart` | Chaque id d'`excludesRunes` désigne une rune ; chaque type d'`eligibleEffects`, d'`excludesEffects` et de `deltas[].effect` a sa stratégie dans `EffectRegistry` ; chaque `deltas[].statusId` est fabriqué par `EffectResolver.createStatus` |
| Le chargement | `test/unit/real_bundle_load_test.dart:38`, `:97-100` | Toujours 8 runes, `enduring` seule non cumulable |
| L'orientation de la Puissance | `test/unit/might_orientation_test.dart:237-249` | Inchangé — Brûlure 1 + 3, 1 tour —, sur un registre qui porte `burning` |
| L'éditeur | `test/unit/content_editor/entity_descriptor_test.dart:258-268`, `:378-383` ; `entity_validator_test.dart` ; `field_kind_test.dart:64` | La table des clés du gabarit de rune ; les `vocabularyKeys` ; `deltas[].type` lu sur `CardDelta.typeNames` ; `excludesRunes` vide ou inconnu refusé par la famille 6 ; `maxLevel: 0` refusé par la famille 7 ; un élément inconnu d'`eligibleEffects` (`"damge"`) refusé, `["damage"]` admis ; le gabarit valide. Le cas décimal de `field_kind_test.dart:64`, qui prenait `valueMultiplier`, prend une autre clé |
| Le vocabulaire des listes | `test/unit/content_editor/known_values_test.dart` | `vocabularyOf` admet pour `excludesEffects[]` les valeurs que les fichiers rangent sous `excludesEffects` ; `knownValues` inchangé (`:51-60` reste vert) |
| Les huit fichiers réels dans l'éditeur | `test/unit/content_editor/shipped_entities_round_trip_test.dart:71-95` | Inchangé : il valide et réécrit à l'identique chaque fichier livré, les huit runes d'E1 comprises — `enduring.json` et ses `excludesEffects` en tête, `"maxLevel": null` compris |
| Le tutoriel | `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_play_card_step_test.dart`, `test/widget/tutorial_merge_transition_test.dart` | Le jeu d'une carte et la valeur affichée passent par l'applicateur : en commune, inchangés ; à l'étape Fusion, une carte de base 1 ou 2 gagne G1, et l'encart dit « Même coût, rareté supérieure » (§5.4) |
| Les runes de test | `test/unit/decoupled_forge_test.dart:30`, `:42` ; `test/widget/forge_fusion_screen_test.dart:53` ; `test/unit/content_editor/entity_validator_test.dart:589-602` | Leurs registres construisent des runes avec `valueMultiplier: 2` : ils prennent `maxLevel` et `deltas` à la place. Le brouillon de rune minimal du test de couleur (`:595`, `{"pools": …, "color": …}`) reçoit `maxLevel` et `deltas`, sans quoi la famille 7 le refuse et le test, qui attend une seule faute, puis aucune, rougit |

Les tests qui construisent une carte avec des runes sans registre, ou lisent `rarityMultiplier`, suivent sans changer
ce qu'ils vérifient. `dart analyze` propre et suite verte, comme chaque lot du programme.

---

## 9. La simulation

**Aucun réalignement ; aucune tâche ne touche le script.** `tool/simulations/d26_economy_sim.dart` lit des runes l'`id`,
le `weight` et l'`eligibleCardTypes` (`:825-846`, `:828-829`), et redéfinit `sharp` et `hardened` sans lire leurs
types (`:834-835`). E1 ne change aucun `weight`, ni l'`eligibleCardTypes` des six autres runes ; il retire celui de
`sharp` et de `hardened`, que le script ignore ; les clés neuves sont ignorées ; aucun fichier ne s'ajoute — la ligne
« 17 runes » ne bouge pas. La relance de fin de vague, faite par l'orchestrateur, doit rendre un diff vide contre
`tool/simulations/d26_reference_output.md` (D73).

Pour information — ce qu'E1 confirme ou précise de ce que le script joue :

| Ce que le script joue | Où | Avec E1 |
|:---|:---|:---|
| G1 sur dégâts, armure, soin, statuts ; G2 sur pioche et mana | `:1253-1258`, `:1868`, `:1874` | Confirmé (A5, A6) |
| D33 : `max(round(0.15 × L × B), L)`, base au rang | `:1264-1265`, `:1643`, `:1651` | Confirmé ; en arithmétique entière dans le jeu, qui diffère du flottant sur 9 demies exactes sur 720 (A7) |
| Somme des runes à la fusion, bornée par `maxLevel` | `:2314-2317` | Confirmé (A9) |
| `maxLevel` : 1 pour les runes binaires et `freezing`, aucun pour les quatre autres | `:1272`, `:1284` | Confirmé (§3.2) |
| Éligibilité par effet de `sharp` et `hardened` ; `enduring` ↔ `eco`, `quick` dans les deux sens ; `eco` à coût ≥ 1 | `:834-843` | Confirmé (§4.6) |

Le script n'a ni forge du feu, ni Forge de Fusion, ni pré-forgées : A10, A11 et A12 n'y ont pas d'équivalent.

---

## 10. Documentation et livraison — la part d'E1

**Pour `memory-bank-sync`**, à la fin de la vague :

| Quoi | Contenu |
|:---|:---|
| Un ADR neuf, « moteur de runes data-driven » | A1 à A13. Il **amende ADR-094** — l'ancien ne change que de Statut : D1, `forgeSlotBonus` devient `fusionRank`, mêmes valeurs, un second lecteur (G1) ; D3, `stackable` reste jusqu'à E2, `maxLevel` le double et borne quatre écritures — « non cumulable ⇒ affichée sans tier » ne vaut plus que pour la fente de la forge et le dialogue de fusion, les infobulles écrivant le niveau sur `maxLevel` (§5.2) ; D4, `exhaustsOnPlay` lit la donnée au lieu de l'id ; D5, `ForgeRuneRules` gagne le prédicat d'éligibilité, la borne vit sur `ForgeUpgradeData` et l'analyseur de niveau passe au modèle ; et la conséquence « textes de runes codés en dur par id » est close. Il **complète ADR-061** — le résolveur n'a plus de code de rune, les effets de rune passent par le registre — et livre l'A4 de l'ADR d'E0 |
| `_rules/03-8` | Le filtrage par effet et par prédicat, à la place du « Filtrage Intelligent par Type de Carte » ; `maxLevel` ; le plafond atteint qui ne se repropose plus (D75), exemplaires additionnés ; la carte sans rune éligible refusée au feu ; la Forge de Fusion qui ne propose pas une fusion qui perdrait un niveau ; `Tranchant` et `Endurci` en pourcentage ; le « Cumul » réduit aux runes sans plafond. La description d'`eco` est déjà corrigée. À relire : « Sélection Pondérée par Rareté » (`weightCommon`…), qui ne décrit plus le code |
| `_rules/02-4` | `forgeSlotBonus` → `fusionRank` ; le multiplicateur de rareté sous G1 et G2 ; l'héritage borné par `maxLevel` |
| `_patterns/10-00` | §10.1 point 3 : le prédicat à la place du filtrage par type ; §10.2 : `consolidate` borné, `fusionRank`, l'applicateur — G1, G2, runes en pourcentage — au point 4 |
| À relire, que le diff peut périmer | `_patterns/03-7` (« multiplicateurs de tier », « `alreadyHas` ») ; `_rules/02-3` (le multiplicateur de `unique` « défini dans `card_instance.dart` ») ; `_rules/04-00` (les statuts des runes élémentaires fusionnent avec ceux de la cible) ; `_rules/03-4:47` (la pioche de `quick` passe par la stratégie de pioche) |

**Ce que le joueur voit — et entend — en `0.5.3`, part E1** :
- *Tranchant* et *Endurci* donnent +15 % de la valeur de base de la carte par niveau, au moins +1, au lieu de +2 :
  sur *Frappe*, +1 au niveau 1 au lieu de +2 ; sur *Mur de Fer* ou *Frappe Lourde*, +2. La rune grandit avec la
  rareté de la carte ;
- la forge — au feu de camp comme sur les cartes de la boutique — ne propose plus une rune qui ne ferait rien ou qui
  casserait la carte : *Endurci* seulement sur une carte qui donne de l'Armure — sur une carte sans armure, elle
  donnait une Armure à part, absente des effets que la carte affiche ; plus d'*Économe* sur une carte
  gratuite ; plus de *Persistant* sur une carte qui pioche ou rend du mana ; jamais *Persistant* avec *Économe* ou
  *Véloce* sur une même carte ;
- *Économe*, *Véloce*, *Congelant* et *Persistant* ne dépassent plus le niveau 1 — ni au feu, ni à la fusion de
  cartes, ni à la Forge de Fusion, ni en boutique —, et une carte n'en porte plus deux exemplaires : la forge ne les
  repropose pas à une carte qui les porte. Le gel de *Congelant* ralentit une attaque ennemie, et non plus deux ou
  trois ;
- une carte qui ne peut plus recevoir aucune rune est refusée à la forge du feu de camp, avec un message qui dit
  pourquoi ;
- chaque fusion augmente d'au moins 1 chaque chiffre de dégâts, d'armure, de soin ou de statut de la carte — un
  *Coup Empoisonné* légendaire inflige 7 dégâts et 5 Poison au lieu de 6 et 2, une *Forme Démoniaque* légendaire donne
  6 Puissance au lieu de 4 ; la pioche et le mana que rend une carte ne grandissent plus avec sa rareté — une
  *Concentration* légendaire pioche 2 cartes, et non plus 4 ;
- les runes de brûlure et de choc renforcent désormais la brûlure ou le choc que la cible porte déjà : le choc d'une
  rune sur un ennemi déjà électrocuté compte enfin dans les dégâts, et une brûlure de rune se fond dans la brûlure en
  cours, qui s'éteint au même rythme au lieu de deux fois plus vite *(la ligne que la spec E0, A4, transmet)* ;
- les descriptions des runes sont les mêmes sur la carte, dans ses infobulles et à la forge — une ligne par rune, au
  niveau qu'elle joue ;
- *Économe* fait entendre le son du gain de mana, comme toute carte qui rend du mana — conséquence d'A2 : les effets
  des runes passent par le même chemin que ceux des cartes.

*Sans place dans la note* : *Tranchant* devient éligible aux Compétences de dégâts (D61), mais aucune des 23 cartes
d'aujourd'hui n'en est une — cela ne se verra qu'avec le lot Arcaniste, en vague 5.

Pas de lien dans `docs/ROADMAP.md`, pas de note de version propre au lot : la note est celle de la vague, écrite à sa
fin.

---

## 11. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Garder le `switch` par id et n'ajouter que le pourcentage** | D68 livre l'applicateur à la place du `switch` (A1) |
| **L'effet d'une rune déduit de son éligibilité** (`valuePercentPerLevel` appliqué aux effets d'`eligibleEffects`) | Un champ et un `if` par sorte de rune ; l'endroit où une rune s'offre n'est pas ce qu'elle modifie — `lifesteal`, `splash` (A1) |
| **Une rune = des effets de carte ajoutés, seulement** | Ne dit ni `sharp`, ni `hardened`, ni les runes de pipeline : un second mécanisme serait nécessaire (A1) |
| **Un bloc de résolution propre aux runes, `GainSource.rune` gardé** | Un chemin d'exception que la spec E0 a refusé pour les statuts ; garder l'étiquette demanderait de changer la signature des six stratégies pour une valeur sans lecteur (A2) |
| **Le prédicat en méthode de `ForgeUpgradeData`** | ADR-094 D5 range les règles qui combinent des runes dans `ForgeRuneRules` ; le précédent des passifs, `availablePassivesFor`, vit hors du modèle (A3) |
| **Les `switch` d'affichage laissés à E2** | Les trois runes d'E2 s'écriraient en Dart dans chaque rendu (A4) |
| **G1 limité aux dégâts et à l'armure, ou compté par carte** | Remplace la valeur que la simulation a jouée : une relance hors de la vague (A5) |
| **G1 qui l'emporte sur G2, une compensation pour les cartes gelées, ou leur fusion interdite** | La boucle changerait (D68) ; la simulation ne multiplie jamais pioche ni mana (A6) |
| **Le pourcentage sur la valeur de la commune, ou exemplaire par exemplaire** | D33 : la rune grandit avec la fusion ; D75 additionne les exemplaires (A7) |
| **Un `maxLevel` facultatif, ou une sentinelle 999** | D27 : chaque rune déclare son plafond ; 999 dirait « aucun » par un nombre (A8) |
| **Refuser une fusion de cartes qui perdrait un niveau** | L'écran de deck proposerait moins de fusions qu'aujourd'hui (A9) |
| **Une Forge de Fusion qui propose une fusion bornée** | 80 or pour perdre un niveau (A10) |
| **Une forge du feu vide, ou le repli sur `sharp`** | Le joueur n'apprend rien ; `sharp` sur une carte sans dégâts (A11) |
| **Tirer une autre carte de boutique quand la rune manque** | Change le tirage de l'étal (A12) |
| **Une liste des types d'effet dans le modèle** | Écrit les six noms une seconde fois, à côté du registre (A13) |
| **Borner aussi le niveau à l'application** | Garde un état qu'aucune partie neuve ne produit : du code pour une sauvegarde d'avant `0.5.3` |
| **Supprimer `stackable` dès E1, `maxLevel: 1` le rendant redondant pour `enduring`** | D68 : `stackable` garde ses lecteurs jusqu'à E2 |
| **Faire lire au badge « Usage unique » l'épuisement de l'applicateur** | Un changement visible que le lot n'annonce pas (§2) — signalé pour la file |
| **Une étape de migration de sauvegarde** | Rien à migrer : le format ne change pas, la donnée des runes est relue du registre (§7) |
