# Revue du brainstorm v3 — Héros, cartes et économie de deck : cohérence, vérification contre le code, passage en spec

**Date** : 29/09/2026
**Objet** : [`22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md`](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md) — 445 lignes, complété le 28/09, 21 décisions acquises (D1-D21), 14 questions ouvertes.
**Vérifié contre** : `main` à `3b8c66f`, le commit même que la v3 annonce. 35 affirmations `fichier:ligne` / ADR / règle contrôlées une à une (annexe A) ; les trois constats de code du game designer ont été re-vérifiés à la main.
**Méthode** : lecture intégrale ; passe de cohérence interne ; vérification contre le code par un agent en lecture seule ; revue d'équilibrage par un second agent dans le rôle `game_designer` (`.agents/skills/game_designer.md`), qui a fait tourner une simulation jetable de 300 runs (XP, taille de deck, or par acte) sur les formules réelles d'`encounter_system.dart`, `reward_controller.dart` et `player_stats_manager.dart`.
**Statut** : Revue. **Rien n'est tranché ici.** §6 liste les modifications à apporter au brainstorm, §7 et §8 les idées à arbitrer, §10 les questions à trancher avant la spec. Le brainstorm n'a pas été modifié par la passe de revue ; **les corrections I1 à I12 et la proposition §2.1 y ont été appliquées le 29/09** sur décision du propriétaire (détail : annexe B.4). Les points de §3 (E1 à E5) et les idées de §7 et §8 attendent leurs arbitrages. **Seconde passe le 30/09 (§11)**, après D36-D49 : trois décisions non propagées, un chiffre périmé, le périmètre de E incomplet dans §11 — tout appliqué, arbitrages D50 à D55. **Troisième passe le 30/09 (§12)**, après D56-D64 : propagation propre ; restent le couple D58 / D59 non mesuré ensemble, les runes de §8 et six décisions sans lot, et douze retouches de texte — **arbitrages du propriétaire le 30/09 (D65 à D67), tout appliqué**, la simulation relancée à k = 2. **Quatrième passe le 30/09 (§13)**, après D65-D67, dans une session neuve : propagation propre ; restent une ligne de §1 à l'ère de D52, Q4 dite tranchée et ouverte à la fois, et la frontière E1 / E2 à écrire avant la spec E1 — **arbitrages du propriétaire le 30/09 (D68 ; Q4 reste ouverte), tout appliqué**.

---

## 1. Verdict en six lignes

1. **Le document est solide et fidèle au code** : sur 35 affirmations vérifiées, 27 sont exactes, 6 approximatives, 2 fausses. Aucune référence n'est inventée ; les passifs, les cartes, les runes et les ADR sont cités correctement.
2. **Il n'est pas prêt à passer en spec tel quel.** Trois erreurs de lecture changent une décision (la fréquence du Puits, la courbe d'XP, ADR-078 renversé sans le dire), et deux incohérences vivent dans la table des décisions acquises elle-même (D3 contre D13 ; §0 contre §7.2).
3. **Après les corrections de §6 — une demi-journée d'édition — le chantier 1 « Économie unifiée » (§4) est prêt pour une spec**, à condition que Q2 (le plafond des runes) soit tranchée *avant* et nomme `eco` et `quick`, qui sont les deux runes qui cassent D11 en niveau infini.
4. **Les évolutions de signature (§4.4, D19, D21) ne sont pas prêtes** : elles sont dimensionnées pour un héros de niveau 40-50, que la courbe d'XP actuelle (`100 × 1,5^(n−1)`) rend impossible — niveau 10 entre l'acte 5 et l'acte 8 selon la méthode, niveau 15 jamais. Une run typique voit un choix d'évolution, deux au plus.
5. **La forme de données (§6, forme C) est prête ; le catalogue (§7) ne l'est pas**, et le document le dit lui-même : la simulation précède les cartes. Les neuf lots sont des exemples de direction, pas un catalogue.
6. **L'agent game designer relève huit risques d'équilibrage, dont trois sont des défauts du code d'aujourd'hui** (fusion des statuts `might` de durées différentes, Flux de Mana + Affinité, pénalité de DDA sur la taille du deck), et propose une réponse structurelle à P3 que le document n'a pas : **la fusion par lot** plutôt que par copie identique. C'est l'idée qui mérite le premier arbitrage.

---

## 2. Incohérences internes

| # | Où | Constat | Gravité | Correction proposée |
|:---:|:---|:---|:---:|:---|
| **I1** | D3 vs D13 | D3 (22/09) : *« Le système d'héritage par cumul de runes identiques disparaît »*. D13 (28/09) : *« deux runes de même id fusionnent en une, niveaux additionnés »*. D13 contredit la dernière phrase de D3 sans être marquée comme amendement. Une spec ne peut pas hériter de deux décisions acquises contradictoires. | **Bloquant** | ✅ **Appliqué le 29/09** : D13 marquée « amende la dernière phrase de D3 », phrase de D3 barrée. |
| **I2** | §0 vs §7.2 | §0 : *« Seul `weakness` reste orphelin »*. §7.2 : *Transe* pose `might_regen`, *« le second orphelin d'août »*. Vérifié : aucun fichier d'`assets/data/` ne pose `might_regen` ; seul le moteur le lit (`status_effect_processor.dart:23,79`). | Moyen | ✅ **Appliqué le 29/09** : §0 nomme les deux orphelins, ce qu'ils font, et le lot qui attend chacun (`weakness` → Sanctifié, `might_regen` → Sang, *Transe*). |
| **I3** | §4.1 vs D16 | *« le lot du passif (6-8) »* contre D16 *« 5 à 6 cartes par passif »* (repris en §7.4). Le pool accessible est ~15-16, pas 16-18 ; tous les ratios de §4.1, §4.2 et §12 en dérivent. | Mineur | ✅ **Appliqué le 29/09** : 5-6, pool 15-16, ~1/16, ~24 actes. |
| **I4** | §4.2 §1 vs D13 | Le premier paragraphe de §4.2 (*« `forgeSlotBonus` vaut 0/1/2/3/4 : exactement le nombre de fusions. La capacité de rune d'une carte est son rang de fusion »*) a été écrit le 22/09 ; D13 (28/09) retire tout plafond de runes. Le paragraphe est caduc mais ouvre encore la section : `forgeSlotBonus` et `forgeCapacityAt` n'ont plus de lecteur sous D13. | Moyen | Proposition détaillée en **§2.1** : renommer `forgeSlotBonus` en `fusionRank`, supprimer `forgeCapacityAt`, `CardInstance.forgeCapacity` et `baseMaxForgeUpgrades`. ✅ **Tranché et appliqué le 29/09** : renommage en `fusionRank`, suppressions, cartes pré-forgées bornées par `fusionRank` (option 2). |
| **I5** | §11 texte vs graphe | Le brainstorm dit **deux choses incompatibles sur le moment où P-44 lot 1** (`scaleWith`, multi-coups, statuts proportionnels, coûts combinés) **est construit** par rapport à la tranche 1 du catalogue (Rempart, Sang, Marque). Le **tableau** du §11 : *« en trois lots dont le premier est parallèle à la tranche 1 »* — construits en même temps. Le **graphe** du §11 : `C1 → P44a → C2` — P-44 lot 1 ne commence qu'*après* la tranche 1, et la tranche 2 l'attend. Ça compte parce que §7.4 impose que chaque lot porte ses cartes P-44 *« dans la tranche où le mécanisme arrive, pas avant »*. **Si le graphe a raison**, la tranche 1 se livre sans ces mécanismes et chacun de ses trois lots perd ses cartes marquées P-44 : Rempart perd *Rempart brisé* ; Sang perd *Sang versé* et *Dernier souffle* et se réduit à *Garde brisée*, *Transe* et `demon_form` — **3 cartes, sous le minimum de 5 de D16** ; Marque perd *Exploitation* et *Salve* et n'est plus que les 4 élémentaires actuelles. La tranche 1 serait un catalogue de survivantes plus 5 ou 6 cartes neuves, et le lot Sang n'existerait pas en tant que lot. **Si le tableau a raison**, le graphe est faux, et le chiffrage de §10 (*« P-44 lot 1 : Sang existe »*, ~3 j de moteur) doit être compté avec la tranche 1, pas après. | Moyen | ✅ **Appliqué le 29/09** : graphe corrigé (`SIM → P44a`), tableau §11 : P-44 lot 1 forme une seule livraison avec la tranche 1. |
| **I6** | §7.4 | Sur 17 neutres : 8 gardées, 7 migrées vers des lots (les 4 élémentaires, `metallicize`, `demon_form`, `warcry`). **`awakening` et `focus` ne sont citées nulle part** (0 occurrence). `focus` (0 mana, épuise, +1 mana) est la seule autre carte à 0 du jeu et touche D11 et G2. | Moyen | ✅ **Tranché le 29/09** : `awakening` reste neutre (citée en §7.2 ; *Garde brisée*, sa copie à +2, est retirée) ; `focus` est supprimée. |
| **I7** | §7.3 vs §7.4 | *Méditation* (0, Compétence, épuise, pioche 2) proposée pour Voile est **`concentration` à l'identique**, gardée par ailleurs en neutre. | Mineur | ✅ **Tranché le 29/09** : *Méditation* redéfinie — 1 mana, épuise, `mana_regen` 1 pendant 2 tours (statut à créer sur le modèle de `might_regen`). |
| **I8** | §5 vs neutres | *« Au plus une carte à 0 mana par lot, et elle s'épuise »* ne couvre pas les neutres ni les signatures : un Mage Voile a accès à `concentration` + `focus` + `mana_surge` + *Méditation* = quatre cartes à 0. | Moyen | ✅ **Appliqué le 29/09** (§5) : au plus deux cartes à 0 dans le deck accessible, toutes à épuisement — `concentration` plus une signature ou une carte de lot, jamais les deux ; testable par classe et passif. |
| **I9** | §7.4 | *« ~50 cartes neuves »* : 45-54 cartes de lot moins 7 survivantes = 38-47 neuves, plus ~2 neutres. | Mineur | ✅ **Appliqué le 29/09** : ~40-47. |
| **I10** | D6 / D7 vs §4.4 | Les signatures portent des runes privées dans `forgeUpgrades` ; §4.4 dit *« jamais par fusion ni par le feu de camp »*, mais rien n'exclut le Puits (D6 : *« remplacer une rune par une autre »*). | Mineur | ✅ **Tranché le 29/09** : les évolutions ne sont pas des runes (modèle `SignatureEvolutionData`, champ `CardInstance.evolutions`, affichage propre) ; le Puits et l'affûtage ignorent les signatures ; aucun échange d'évolutions — ce sont des choix. |
| **I11** | §11 vs ROADMAP | P-18 est déjà *« entièrement redistribué sur P-42 et P-43 »* (`ROADMAP.md:465`) ; sa limite de 15 cartes vit dans P-43 *« limite de taille »*. *« P-18 annulé par D2 »* vise donc la ligne de P-43. Le *« coût de merge +1 mana »* de P-18 tombe aussi sous D3, ce que le document ne dit pas. | Mineur | ✅ **Appliqué le 29/09**. |
| **I12** | D2 | *« La limite est la main »* : `maxHandSize` borne la **pioche**, pas le deck. Un deck de 36 cartes (acte 10, simulation) n'atteint jamais une main de 10 ; il dilue. D2 est acquise ; c'est son motif qui est mal formulé. | À signaler | ✅ **Appliqué le 29/09** : D2 garde la main comme seule limite — elle répond à un bug observé (pioche au-delà du maximum, à reproduire, §2) — et nomme ce qui traite la dilution. |

### 2.1. Proposition pour I4 — `forgeSlotBonus`, `forgeCapacityAt`, `baseMaxForgeUpgrades`

**Ce que le code en fait aujourd'hui.** `CardRarity.forgeSlotBonus` (`card_data.dart:33-39` : common 0, uncommon 1, rare 2, epic 3, legendary 4, unique 0) n'a qu'un lecteur : `CardData.forgeCapacityAt(rarity) = baseMaxForgeUpgrades + forgeSlotBonus` (`:142-143`). `baseMaxForgeUpgrades` (`:98`, défaut 1, `5` sur les six signatures) n'en a pas d'autre non plus, hors `toJson` et le descripteur de l'éditeur de contenu (`entity_descriptor.dart:238`). La **capacité**, elle, a sept lecteurs :

| Lecteur | Ce qu'il en fait aujourd'hui | Sous D3, D5, D7, D13 |
|:---|:---|:---|
| `rest_card_selection_screen.dart:30` | refuse la forge au feu de camp si la carte est pleine | disparaît avec la forge au feu — D5 affûte une rune existante, n'en ajoute pas |
| `forge_upgrade_dialog.dart:51` | plafonne le nombre de runes proposées | disparaît : rappelé à la fusion, le dialogue propose 3 runes, sans plafond |
| `deck_controller.dart:318-321` | tronque les runes héritées à la capacité de la rareté suivante | disparaît : D13 garde tout |
| `deck_screen.dart:224-230` | décide si le joueur doit choisir ce qu'il hérite | disparaît : plus de dépassement possible |
| `card_text_renderer.dart:519` · `ui_card.dart:69,101,241` | dessinent `max(capacité, runes portées)` fentes — donc des fentes **vides** | dessinent **une fente par rune portée**, aucune vide ; les évolutions de signature (§4.4) s'y affichent de la même façon |
| `shop_controller.dart:195` | borne les runes des cartes **pré-forgées** de l'étal (15 % à l'acte 2, 10 % de deux runes dès l'acte 3) | **à trancher** — voir ci-dessous |
| `card_instance.dart:24` `forgeCapacity` | le relais de tous les précédents | disparaît |

**La proposition : renommer l'un, supprimer les deux autres.**

- **`forgeSlotBonus` → `fusionRank`.** La valeur ne change pas ; le sens, si : *« le nombre de fusions qu'il a fallu pour atteindre cette rareté »*. C'est exactement ce que `minFusionRank` des runes (§4.2 du brainstorm) doit comparer — une rune est proposable quand `nextRarity.fusionRank ≥ rune.minFusionRank` — et ce que le `fusionCost` en donnée du designer (§7, idée 2.2) indexerait. La valeur gagne un lecteur neuf, et le nom cesse de décrire des fentes qui n'existent plus.
- **`forgeCapacityAt`, `CardInstance.forgeCapacity` et le paramètre `forgeCapacity` de `UiCard` : supprimés.** Sans plafond, une capacité n'a pas de sens ; les fentes se comptent sur `forgeUpgrades.length`.
- **`baseMaxForgeUpgrades` : supprimé** du modèle, de `toJson`, du descripteur d'éditeur et des six `classes/*/cards/*.json`. Les évolutions d'une signature sont bornées par le niveau du héros (D19), pas par une capacité. C'est la dernière trace d'ADR-026.

**Hors code** : ADR-094 (qui a introduit `forgeSlotBonus` comme échelle explicite — à amender, pas à réécrire, l'échelle `next` reste), `_rules/02-3` (*« 5 runes au plus »*), `_rules/02-4` point 4 (capacité et choix d'héritage), `_rules/03-8` (fentes et capacité) ; six tests à réécrire (`card_rarity_test.dart:52`, `decoupled_forge_test`, `ui_card_rune_sockets_test`, `deck_controller_test`, `deck_state_persistence_test`, `entity_descriptor_test`). Aucune migration de sauvegarde : une carte sauvegardée garde ses runes, il n'y a plus rien à borner.

**La décision qui reste — les cartes pré-forgées de la boutique** (`shop_controller.dart:188-205`). Aujourd'hui une carte de l'étal peut sortir avec une ou deux runes tirées au sort. P3 dit *« une rune achetée sans fusion casse la chaîne »*. Trois issues :

1. **Supprimer le tirage** : l'étal ne vend que des cartes nues — le plus fidèle à P3.
2. **Borner par `fusionRank`** : une carte de l'étal porte au plus `fusionRank(rareté)` runes, comme si elle avait été fusionnée — le même argument qui autorise l'échange 3 → 1 (§1 du brainstorm, ligne « Plus tard ») à faire entrer une rareté supérieure sans fusion. *Recommandé* : la boutique garde un intérêt, et la règle se lit sur la carte. ✅ **Retenu le 29/09.**
3. **Garder tel quel** avec un plafond arbitraire — l'état actuel, à écarter puisque le plafond n'existe plus.

---

## 3. Cohérence avec le code, les ADR et les règles

> **État au 29/09, soir — tout est tranché et reporté dans le brainstorm (D22 à D28).** E1 → un Puits garanti tous les 3 actes, plus un événement d'échange de relique contre PV ou or (D22, D23). E2 → courbe d'XP aplatie, en donnée, linéaire par acte, au moins 2 niveaux par acte ; les paliers de D19/D21 restent (D24). E3 → confirmé, ADR-078 à amender une fois le bug reproduit (D25). E4 → simulation sur au moins 15 actes, toutes les variables (D26). E5 → tableau de §4.1 corrigé. 3.4 → les six références corrigées. 3.5 → `eco` et `quick` à niveau unique, `maxLevel` par rune, table proposée en §8 du brainstorm (D27).

### 3.1. Les deux erreurs qui changent une décision

**E1 — La fréquence du Puits (§4.3).** Le document écrit *« 25 % des étages 3-7 »*. ADR-074, `_rules/02-1` et `map_content_placer.dart:24-36` disent autre chose : **25 % de chance par carte qu'un seul nœud** (combat ou événement) des étages 3-7 devienne `forgeFusion`. Sur un chemin de 10 nœuds, le joueur ne passe par ce nœud que s'il est sur sa route : le Puits est rencontré dans nettement moins d'une carte sur quatre. D6 en fait **le seul lieu d'échange de rune** — à cette fréquence, l'échange n'existe pas. La spec doit fixer une fréquence, ou faire de l'échange un service de boutique ou une option du feu de camp.

**E2 — La courbe d'XP (§4.4, D19, D21).** Le palier vaut `100 × 1,5^(niveau − 1)` (`player_stats_manager.dart:127`). XP cumulé pour atteindre un niveau :

| Niveau | 5 | 10 | 15 | 20 | 40 |
|:---|--:|--:|--:|--:|--:|
| XP cumulé | ~810 | ~7 500 | ~58 000 | ~443 000 | ~1,5 milliard |

Simulation de 300 runs sur les formules réelles (budget d'ennemis, XP `× (1 + 0,1 × (niveau − 1))`, boss central ×3) : niveau **2,3** en fin d'acte 1, **5,9** en fin d'acte 3, **8,0** à l'acte 5, **10,0** à l'acte 8, **10,4** à l'acte 10. L'estimation manuelle du vérificateur est plus optimiste (niveau 10 vers l'acte 5) ; les deux concluent que **le niveau 15 est hors de portée** et que les niveaux 20 à 50 le sont de plusieurs ordres de grandeur. Une run typique voit donc **une mineure (niveau 5), au mieux une majeure (niveau 10)**. Les phrases *« 4-5 majeures couvrent les niveaux 10 à 50 »* et *« une signature de niveau 40 porte quatre majeures »* décrivent une courbe qui n'existe pas, et les règles de reprise, d'épuisement des majeures et de repli sont conçues pour un écran qui s'affiche une à deux fois par run. Deux issues, à trancher par le propriétaire : la courbe d'XP passe en donnée et s'aplatit (c'est du P-16, et elle couple avec la DDA qui lit `playerLevel`, `encounter_system.dart:104-107`) ; ou les paliers de D19/D21 se réindexent sur ce qui est atteignable — par acte, ou tous les 3 niveaux — ce qui est un amendement à une décision acquise.

### 3.2. La décision renversée sans le dire

**E3 — ADR-078, décision 3.** L'ADR a explicitement décidé que `maxHandSize` reste une **constante, pas une stat de run** (*« 10 est inatteignable, une relique serait invisible »*). §4.1 la migre dans `RunState` sur le modèle de `cardsPerTurn`. D2 rend cette décision caduque — mais le document ne la cite pas, et la spec devra amender l'ADR.

### 3.3. Les hypothèses sans fondement dans les règles

**E4 — Le nombre d'actes.** Aucune règle ne borne la run : `map_progression_manager.dart:49-54` génère `act + 1` sans fin, `encounter_system.dart:53-56` débloque le tier 3 d'ennemis *« à partir de l'acte 11 »*, `map_content_placer.dart:10` place l'échange de reliques *« tous les 5 actes »*. *« Une run de 10 actes »* (§4.2) et *« ~25 actes pour 3 copies »* (§4.1) sont des extrapolations sans horizon. **La simulation doit d'abord fixer une longueur de run cible** (ou attendre P-12, le boss de cycle).

**E5 — Le comptage des nœuds (§4.1).** La distribution 60 % / 15 % / 10 % / 10 % / 5 % ne s'applique qu'aux **étages 1-4 et 6-7** ; l'étage 0 est un combat forcé, l'étage 5 une élite forcée (chokepoint), l'étage 8 un repos forcé (`_rules/02-1:17-29`). Par chemin : **~4,6 combats, ~1,3 élites, ~1,6 feux de camp, 1 boss** — pas 5,4 / 0,5 / 2. Trouvailles : 4,6 × 0,33 + 1,3 × 0,5 ≈ **2,2 par acte** — la conclusion du document tient, mais avec 2,5 fois plus d'élites que prévu, le 50 % de D1 pèse le double.

### 3.4. Les approximations, sans conséquence sur les décisions

- `vulnerable` est posé par **le code** (`MageMarkPassive`, `passive_strategies.dart:85`), pas par `passives/mage_mark.json`, qui ne porte que le texte.
- `freeze` : `turn_phase_manager.dart:107` lit un booléen pour décrémenter la durée, mais **l'effet réel** (intention × 0,5) vit dans `enemy_instance.dart:28-29`. Le chantier « statuts proportionnels » (§9.2 #3) doit toucher ce fichier-là.
- *« Level Up différé sur la carte »* est documenté dans `_rules/03-10`, pas `_rules/02-1`.
- `_payLifesteal` est défini à `strategies.dart:69` et appelé à `:61`, pas `:63`.
- ADR-097 renomme le statut `strength` en `might` ; le renommage `strength_regen → might_regen` est le commit `ad56024`, que l'ADR ne nomme pas.
- P-50 n'existe pas dans la ROADMAP — il est proposé par la revue du 10/09 ; le document le dit bien.
- *« 1187 tests »* : non re-mesuré ici (la ROADMAP donne 1179 à `d27edc9`, ADR-101 en a ajouté depuis).

### 3.5. Ce que les runes font vraiment — utile à D3, D4 et Q2

| Rune | Effet réel (`effect_resolver.dart:142-174`) | Pools actuels | Types |
|:---|:---|:---|:---|
| `sharp`, `hardened` | +2 × niveau dégâts / armure | common, uncommon, rare | attack / attack + skill |
| `burning`, `freezing`, `shocking` | pose niveau × statut | common, uncommon, rare | **attack seul** |
| `quick` | **pioche niveau cartes à la pose** | uncommon, rare | tous |
| `eco` | **gagne niveau mana à la pose** — pas une réduction de coût (`_rules/03-8:22` est fausse) | rare seul | tous |
| `enduring` | retire l'épuisement ; `stackable: false`, `requiresExhaust: true` | rare | tous |

Sous D4 (*« montable à l'infini »*) et D13 (niveaux additionnés à la fusion), une légendaire issue de trois épiques à `eco:1` porte `eco:3` : **+3 mana à la pose sur une carte à ≤ 2 mana**, un moteur de mana infini qui rejoue la « pioche infinie » de §2 — et `quick` fait de même pour la pioche. **Q2 (`maxLevel`) n'est pas une question ouverte, elle est bloquante**, et doit nommer `eco` et `quick`, pas seulement `echo` et `cheap`.

---

## 4. Cohérence des chiffres — ce que le document suppose et ce que le jeu fait

| Donnée du document | Valeur réelle | Source | Ce que ça change |
|:---|:---|:---|:---|
| ~0,5 élite par acte | **~1,3** | E5 | Le 50 % d'élite de D1 pèse le double |
| ~2 feux de camp par acte | **~1,6**, partagés entre repos, oubli et affûtage | E5, `_rules/03-7` | Sous D14 (une rune, un niveau, par visite) : **~1 niveau d'affûtage par acte, toutes runes confondues**. La `sharp:9` de l'exemple §4.2 coûte 8 visites — toute une run de 10 actes. D4 « à l'infini » est une promesse que la run ne peut pas tenir |
| L'or comme contrainte de l'affûtage (§4.2) | **La visite est la contrainte, jamais l'or** : ~530 or cumulés à l'acte 3 (simulation) contre `b × n` = 50, 100, 150… | §4.2 pt 1 le dit déjà | Le « pari affûter avant de fusionner » et la taxe de fusion (§4.2 pt 3) traitent un problème qui n'existe pas : les deux ordres coûtent le même nombre de visites |
| Niveaux 5, 10, 15… 40, 50 | Niveau 5 vers l'acte 3, 10 entre l'acte 5 et 8, 15 jamais | E2 | Une à deux évolutions de signature par run |
| Taille du deck | 7 → 10 (acte 1) → 16 (acte 3) → 21 (acte 5) → 36 (acte 10), sans refus | simulation, D1 | Main de 5, deck de 36 : une carte donnée revient tous les ~7 tours |
| Pool accessible 16-18 | **15-16** | I3 | Ratios de §4.1 à recalculer |
| Rythme de fusion | ~3-4 entrées de cartes par acte (2,2 trouvailles + boss + boutique / Miroir). Sous tirage uniforme : rang 2 (rare) vers l'acte 5-8 pour **une** carte, rang 3 (27 communes) jamais | §4.1, simulation | `minFusionRank: 3` pour `eco` / `quick` ne les rend pas rares, il les retire du jeu ; le catalogue de 14 runes (§8) serait vu à ~10 % ; D3 « la rune vient de la fusion » donne 0 à 3 runes par run |

---

## 5. Prêt pour la spec ? Chantier par chantier

| Chantier | Verdict | Ce qui manque pour ouvrir la spec |
|:---|:---:|:---|
| **Économie unifiée** (§4 : moteur de runes data-driven, trouvaille, fusion = forge, affûtage, Puits, main, G1, G2, Sagesse) | **Prêt après corrections** | I1, I4 ; E1 (fréquence du Puits) ; E3 (amender ADR-078) ; **Q2 tranchée** (`maxLevel` par rune : `eco`, `quick`, `cheap`, `echo`, `splash`) ; Q5 ; une longueur de run cible pour la simulation (E4) |
| **Simulation** (§4.1) | Prête à écrire | Compteurs à ajouter : niveau par acte, visites de feu par acte, or **et** visites, les deux ordres d'affûtage, **par classe** (Sang se repose moins), un tour de dégâts Berserker par acte |
| **Évolutions de signature** (§4.4, D19, D21) | **Pas prêt** | E2 : choisir entre courbe d'XP et réindexation des paliers ; dimensionner les pools sur 1 à 3 paliers réels ; Q6, Q7 ; I10 (le Puits) |
| **Forme de données** (§6, forme C) | **Prêt** | Q10 (`category`), Q13 (renommage), Q8 (ponts) sont des décisions de spec, non bloquantes |
| **Catalogue** (§7) | **Pas prêt, par construction** | La simulation d'abord — le document le dit ; I6, I7, I8 ; le risque R6 du designer (un Mage de tranche 1 dont la Puissance ne touche rien) ; Q12, Q14 |
| **P-44 lot 1** (§9 : `scaleWith`, multi-coups, statuts proportionnels, coûts combinés) | **Prêt** | Trois précisions : la rareté ne multiplie que la base, jamais le terme `scaleWith` (sinon une épique `scaleWith: armor` est quadratique) ; `freeze` vit dans `enemy_instance.dart` ; les règles de coût combiné du designer (§8.2, idée 15) |

> **État au 29/09, soir.** Après D22 à D28, l'**Économie unifiée** et les **évolutions de signature** sont prêtes pour une spec ; la forme de données et P-44 lot 1 l'étaient déjà. Le **catalogue** attend la simulation (D26). Les idées du designer (§7, §8) restent à arbitrer, en dernier. **30/09** : D49 sort les signatures des cartes — compétences de classe à recharge, barre au HUD, hors `masterDeck` ; le modèle d'évolution ne change pas, le chantier « évolutions de signature » s'élargit à leur forme et reste prêt pour une spec.

---

## 6. Modifications à apporter au document

Dans l'ordre des sections. Chaque ligne est une édition localisée. *État au 29/09, soir : tout est appliqué sauf la taxe de fusion de l'item 6, qui attend l'arbitrage de §7 (idée 2.3), et le compte de tests de l'item 17, re-mesuré par `flutter test`. **30/09** : la taxe est retirée (D32), le compte est re-mesuré (1187) — les 17 items sont clos.*

1. ✅ **§1** — Marquer D13 *« amende la dernière phrase de D3 »* et barrer cette phrase (I1). *Fait le 29/09.*
2. ✅ **§0, axe B** — *« deux orphelins : `weakness` et `might_regen` »* ; préciser que `vulnerable` est posé par `MageMarkPassive` en Dart, pas par la donnée (I2, §3.4). *Fait le 29/09.*
3. **§0** — `freeze` : ajouter `enemy_instance.dart:28-29` comme siège de l'effet (§3.4).
4. **§4.1** — Recalculer le tableau : 4,6 combats, 1,3 élites, 1,6 feux, ~2,2 trouvailles (E5) ; ✅ pool 15-16 (I3, *fait le 29/09*). Ajouter : *« la run n'a pas de fin ; la simulation fixe d'abord une longueur cible »* (E4).
5. **§4.1** — Sur `maxHandSize` : *« renverse ADR-078 D3, à amender en spec »* (E3).
6. **§4.2** — Réécrire le premier paragraphe : sous D13 la capacité de rune disparaît, `forgeSlotBonus` et `forgeCapacityAt` n'ont plus de lecteur (I4). Retirer la taxe de fusion, ou la conditionner à la simulation en disant que la visite, pas l'or, est la ressource rare — l'argument est déjà au point 1 du même paragraphe (§4).
7. **§4.3** — Corriger *« 25 % par carte qu'un seul nœud des étages 3-7 soit le Puits »* et ajouter *« fréquence à décider en spec »* (E1).
8. **§4.3 / §4.4** — Le Puits ignore les signatures (I10).
9. **§4.4** — Remplacer les exemples *« niveau 40 »*, *« niveaux 10 à 50 »* par la courbe réelle ; ajouter la question *« courbe d'XP en donnée, ou paliers réindexés »* (E2).
10. **§4.4** — *« Level Up différé »* → `_rules/03-10` (§3.4).
11. **§5** — Étendre la règle des cartes à 0 au deck accessible ; trancher `focus` (I6, I8).
12. **§7.3** — *Méditation* = `concentration` : supprimer l'une (I7).
13. **§7.4** — Citer `awakening` et `focus` ; budget *« ~40-47 cartes neuves »* (I6, I9).
14. **§8** — `eco` = +niveau mana à la pose ; ajouter `eco` et `quick` à la liste des runes qui exigent un `maxLevel` (§3.5).
15. **§11** — Aligner le graphe et le tableau sur P-44 lot 1 (I5) ; reformuler la ligne P-18 (I11).
16. **§13** — Ajouter : Q15 longueur de run cible ; Q16 fréquence du Puits ; Q17 courbe d'XP ; Q18 sort de `focus` et `awakening` ; et passer Q2 en bloquante.
17. **Mineurs** — `_payLifesteal :69` ; ADR-097 vs commit `ad56024` ; re-mesurer *« 1187 tests »*.

---

## 7. Idées à remplacer — soumises par l'agent game designer, avec mon avis

> *Arbitrages du 29/09, tous reportés dans le brainstorm : **2.1** refusée comme remplacement — la fusion de trois copies identiques est le concept autobattler, acquis — mais retenue comme **événement** (D29, Q18) ; **2.2** remplacée par une refonte de la trouvaille du propriétaire — une carte garantie par combat, jets et reliques pour les suivantes (D31), `fusionCost` refusé, `minFusionRank` en Q19 — tranchée le 30/09 à 2, D48 ; **2.3** retenue, pas de taxe (D32) ; **2.4** retenue sous forme de runes en pourcentage (D33) ; **2.5** retenue, Mage seul (D30) ; **2.6** retenue en entier (D34) ; **2.7** retenue (Percée chez Rempart) ; **2.8** retenue (D35).*

| # | Proposition du document | Remplaçant proposé par le designer | Coût | Mon avis |
|:---:|:---|:---|:---|:---|
| **2.1** | Fusion 3 → 1 de **trois copies identiques** (règle de `mergeCards`, `_rules/02-4`) | **Trois cartes du même lot, même rareté, l'une monte** ; le joueur choisit la survivante ; les neutres forment leur propre lot. Première fusion à l'acte 1, puis une tous les 2-3 actes ; le deck **maigrit** de 2 par fusion — seule réponse trouvée à la dilution de D2 qui ne coûte pas une visite | Une ligne dans le prédicat (`passive ==` au lieu de `id ==`) + le choix de la survivante dans l'écran de deck | **À arbitrer en premier.** D3 dit *« 3 → 1 »*, l'identité des copies est une règle de moteur, pas une décision. C'est ce qui rend P3 vrai avec les taux de D1 ; sans elle, la simulation dira que personne ne fusionne au-delà du rang 2. À simuler avant les cartes |
| **2.2** | `minFusionRank: 3` pour `eco` et `quick` | Rang 2 maximum partout, et **`fusionCost` en donnée** (`{"uncommon": 3, "rare": 2, …}` lu par `mergeCards`) si la spec veut un rang 3 vivant | JSON + une ligne | Recommandé — §4 : rien au-dessus du rang 2 n'existe en jeu |
| **2.3** | Taxe de fusion sur les niveaux additionnés (§4.2 pt 3) | La supprimer : la ressource rare est la visite, les deux ordres en coûtent autant ; la taxe punit le joueur qui planifie. D20 reste | — | Recommandé (§4) |
| **2.4** | Runes en pourcentage par niveau (`echo` +15 %, `splash` +25 %) | **Runes à charges par combat** : `echo:n` = se rejoue n fois par combat, `splash:n` = les n premiers coups touchent tout le monde, `eco:n` / `quick:n` = les n premières poses rendent 1 mana / piochent 1. Linéaire, borné par la longueur du combat, montable à l'infini sans jamais devenir « toujours » — la promesse de D4. `PassiveCounters` (`CounterScope.combat`) porte déjà le compteur ; forme : `"levelSemantics": "chargesPerCombat" \| "perLevel"` | Moteur, petit | **Recommandé** — c'est la seule forme qui rende D4 vraie sans plafond, et elle répond à Q2 |
| **2.5** | Canalisation : mana non dépensé → armure | Mana non dépensé → **banque** (plafond `maxMana` de réserve, le tour suivant démarre à `maxMana + réserve`). Le Mage *prépare* un tour à 5-6 mana : ce qui donne un sens aux cartes à 3 de D12 sans toucher D11 | `startTurn` + la stratégie, ~10 lignes | À arbitrer : modifie un passif livré par P-41. Répond au risque R6 (Voile « paie pour ne pas jouer ») |
| **2.6** | Marque du Mage : *première Attaque* du tour | *Première carte de dégâts* (`onDamagingCardPlayed`) : les deux lots du Mage partagent le verbe de la classe. Et **tranche 1 = Arcaniste**, pas Marque : le premier lot livré du Mage doit être celui qui lit sa Puissance | Une ligne au dispatch ; ordre des tranches | À arbitrer pour le déclencheur (passif livré) ; **recommandé** pour l'ordre des tranches (Q14) |
| **2.7** | *Percée* (coût 4 armure) dans Croisé | Dans **Rempart** : Ferveur veut de l'armure *frappée* (`onDamageTaken`, `absorbedDamage`) ; une carte qui la dépense la lui vole | JSON | Recommandé |
| **2.8** | Vampire : *« multi-coups, chaque coup draine »* | *Attaques à 1 qui piochent* : `_payLifesteal` (`strategies.dart:69`) soigne **une fois par carte**, borné aux dégâts — *Lacération* 2 × 2 draine autant que *Morsure*. Les multi-coups vont à Marque et Croisé. La rune `lifesteal` de §8 duplique le statut du passif (`isStackable: false`, max des deux) : morte pour un Vampire — un soin par carte propre, ou la retirer | JSON ; une décision sur la rune | Recommandé — vérifié dans le code |

---

## 8. Idées d'amélioration — soumises par l'agent game designer

Rapportées comme il les a formulées, condensées, avec l'état de ma vérification. Chiffres établis sur `3b8c66f`.

### 8.1. Son diagnostic d'équilibrage, par gravité

| # | Risque | Preuve | Conséquence | Vérifié |
|:---:|:---|:---|:---|:---:|
| **R1** | D19/D21 sont dimensionnées pour un héros qui n'existe pas | E2 | Un choix d'évolution par run ; le coût moteur (runes privées, écran, pools) est payé pour un écran | ✅ |
| **R2** | D4 « à l'infini » est une promesse vide sous D14 | ~1,6 feu par acte, partagés ; ~1 niveau d'affûtage par acte | Le pari « affûter avant de fusionner » est un faux problème ; la taxe aussi | ✅ |
| **R3** | Puissance × multi-coups × conversion d'armure : trois multiplicateurs libres sur une stat | (a) La Puissance est un bonus **plat par instance de dégâts**, par ennemi sur les AoE, par coup dès que `hits` existera (`power_rules.dart:17-21`, `strategies.dart:49`) ; (b) la conversion du Berserker est 1:1 sans plafond (`stat_rule.dart`, `StatGains._convert`) ; (c) **les statuts `might` de durées différentes fusionnent en un seul** — `EntityStats.addStatus` (`entity_stats.dart:134-139`) → `StatusEffect.combine`, `isStackable` vrai par défaut (`status_effect.dart:17`) : valeur sommée, durée = max. `demon_form` (2, 4 tours) puis `iron_wall` (10, 1 tour) = **Puissance 12 pendant 4 tours**, et Rage s'y accumule chaque tour | Ordre de grandeur, Berserker Sang à 40/80 PV, acte 3 : *Frénésie sanglante* 4 × 3 ≈ (4 + 11) × 3 = **45** pour 3 mana contre un gobelin à ~49 PV ; *Sang versé* (0 mana, −4 PV, 8) ≈ 19 dégâts gratuits ; avec le bug (c), ≈ 81 | ✅ (a, b, c re-vérifiés) |
| **R4** | L'arbre de fusion est inatteignable au-delà du rang 2, quel que soit D1 | §4 | `eco` / `quick` au rang 3 sortent du jeu ; 0 à 3 runes par run | ✅ |
| **R5** | Flux de Mana + Affinité = mana infini à une récompense près | `mana_flux.json` : `threshold: 3`, `mastery.perPoint: −1` ; `affinity.json` : +1 à +7 ; plancher à 1 dans `ManaFluxPassive` (`passive_strategies.dart:107`). Une Affinité peu commune (+2) porte le seuil à 1 : chaque Compétence rend 1 mana | D11 cassée par un tirage de niveau commun | ✅ |
| **R6** | Le Mage a deux lots sur trois qui ignorent sa Puissance, et 60 PV sans défense | `mightTargets: ["skill", "alteration"]` ; Marque nourrit des **Attaques** (les quatre élémentaires) dont la part dégâts ne reçoit rien ; Voile n'a pas de dégâts ; Canalisation = 3 armure/tour contre 8-12 × 1,35 par ennemi à l'acte 3 | Avec la tranche 1 proposée (Rempart, Sang, **Marque**), le Mage joue toute la première tranche avec une stat morte et des Aiguisages inertes | ✅ (`power_rules.dart`) |
| **R7** | D2 sans plafond : trois effets pervers | (a) dilution : deck 36 à l'acte 10, une carte donnée tous les ~7 tours ; (b) le feu de camp a trois prétendants pour 1,6 visite ; (c) **la DDA punit le deck gonflé** : `PlayerPower += playerCardsCount × 2` (`encounter_system.dart:101`) — +58 de puissance pour 29 cartes subies, donc un budget ennemi plus haut pour un deck plus faible | — | ✅ (c re-vérifié) |
| **R8** | Bénédiction n'a pas de payoff | 5 armure survivante → 1 PV (2 avec Maîtrise 1) ; `defend_basic` entièrement gaspillée vaut 1-2 PV, `heal_potion` en donne 3 ; `weakness` (× 0,75) fait survivre 2,5 armure sur un bloc de 10 : zéro tranche. Le seuil 5 est une constante Dart (`BlessingPassive._armorPerTranche`, `passive_strategies.dart:146`), pas une donnée | Le lot Sanctifié nourrit un passif qui ne rend rien | ✅ |

### 8.2. Ses idées, par ratio décision créée / coût décroissant

> *État au 30/09 : les quinze idées sont arbitrées. 2, 3, 4, 8, 14, 15 → D36 à D40 et D26 amendée ; 1 → D41, puis D49 (compétences de classe, Q20 tranchée) ; 5 → D42 (boss « XP », événement, `maxLevel` en mythique — le pool `mythic` sort à 0,5 % par niveau plus 0,15 % par point de Chance, `level_up_reward_service.dart:50-57`) ; 7 → D43 ; 9 → D44 ; 10 → D45 ; 11 → D46, reformulée par le propriétaire : la copie vient du deck du joueur, pas du lot ; 12 → D47 ; 6 absorbée par D24 ; 13 écrite en §9.2 #1 du brainstorm.*

| # | Idée | Mécanisme | Coût | Note |
|:---:|:---|:---|:---|:---|
| 1 | **Signatures innées** | Les deux `unique` toujours dans la main d'ouverture (`DeckNotifier.startCombat`, `deck_controller.dart:158`) | Moteur, petit | Rend D7/D19 visibles à chaque combat, neutralise la dilution pour les deux cartes qui définissent la classe, et donne un sens aux majeures |
| 2 | **Puissance par tranches de durée** | `addStatus` ne fusionne des `might` qu'à durée égale ; `effectiveMight` somme déjà toutes les entrées, `tickStatuses` les vieillit séparément | Une ligne | Ferme R3(c). **Un bug d'aujourd'hui, à ouvrir indépendamment de la spec** |
| 3 | **`ratio` sur `statRules`** | `{ "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1, "ratio": 0.5 }` | Deux lignes | Le garde-fou de R3(b) devient une donnée de classe, pas un nerf de carte : l'armure vaut 5/mana, les dégâts 6/mana, une conversion 1:1 *par coup* multiplie par le nombre de coups |
| 4 | **`mightRatio` par effet et budget de Puissance validé** | `{"type":"damage","value":4,"hits":3,"mightRatio":0.5}`, défaut 1 ; un test de données impose `Σ hits × mightRatio ≤ coût en mana + 1` par carte | JSON + une ligne + un test | Interdit un *Sang versé* à 0 mana recevant la Puissance entière ; R3(a) devient un invariant du catalogue |
| 5 | **L'affûtage est un verbe, pas un nœud** | `"effect": "sharpenRune"` dans `level_up_rewards/` (pool `draft`, à côté de `cloneCard`), un `BossRewardType`, un service de boutique, une issue d'événement | JSON + le `switch` exhaustif de `cloneCard` | D14 reste (une par visite au feu), D4 devient vrai : 3-4 niveaux par acte au lieu d'un |
| 6 | **Courbe d'XP en donnée, et aplatie** | `1,5` → `1,3` donne niveau 10 à l'acte 5 et 14 à l'acte 9 ; `1,25` donne 15 à l'acte 8 (simulation). Ou : XP × facteur d'acte, puisque les PV ennemis scalent en 1,35^palier et l'XP en +10 %/niveau seulement | Une ligne | Sans cela D19/D21 restent un choix par run. Couplage à simuler : `ExpectedPower` et `BaseBudget` lisent `playerLevel` (`encounter_system.dart:104-107`), aplatir monte les budgets ennemis |
| 7 | **`threshold` de Bénédiction en donnée, et `floor` dans le bloc `mastery`** | `PassiveData.threshold` existe (Flux). `threshold: 3`, `mastery: {field: threshold, perPoint: −1, floor: 2}` ; le même `floor: 2` sur `mana_flux.json` ferme R5 au même endroit | JSON + une ligne | Variante ambitieuse pour Sanctifié : `statRules` mode `retain` (l'armure survivante est conservée jusqu'à N) — le seul lot qui rendrait `scaleWith: armor` cumulatif, contraste réel avec la remise à zéro de `startTurn` (moteur) |
| 8 | **Le Puits transfère `min(niveau, maxLevel cible)`** | Sinon la stratégie dominante est d'affûter `sharp` (linéaire, sûre) puis d'échanger au même niveau en `echo` / `splash` | Une ligne | `maxLevel` devient obligatoire sur toute rune `perLevel` non linéaire |
| 9 | **Éligibilité de rune en donnée** | `cheap` : `requiresMinCost: 1` (morte sur `costs: {mana: 0, armor: 5}`) ; `enduring` : `excludesEffects: ["gain_mana", "draw"]` — `focus`, `concentration`, `mana_surge` non épuisables sont un moteur de cyclage. Même forme que `requiresExhaust` | JSON + une ligne | — |
| 10 | **`feeds` sur le passif, et un test** | `passives/fervor.json` : `"feeds": ["armor", "attack"]` ; un test à la `entity_id_convention_test` exige que toute carte de `cards/<passif>/` touche une entrée de `feeds` | Test seul | P2 devient vérifiable à l'écriture des ~45 cartes |
| 11 | **La boutique stocke toujours une carte du lot actif** | `shopLotSlots: 1` ; `isOfferableTo` existe | Une ligne | Source de doublon *ciblée* hors D1 |
| 12 | **Retirer `playerCardsCount × 2` de `PlayerPower`**, ou le remplacer par Σ(`rarityMultiplier` − 1) | La DDA doit lire la qualité, pas la taille | Une ligne | Ferme R7(c) |
| 13 | **La rareté ne multiplie que la base** | `rarityMultiplier` s'applique à `value`, jamais au terme `scaleWith`, sinon une épique `scaleWith: armor` est quadratique | Spec | À écrire dans §9.2 #1 avec G2 |
| 14 | **Le Sang ne se repose jamais** | Rage veut des PV manquants : le Berserker Sang affûte deux fois plus que les autres (R2) | — | La simulation doit tourner par classe ; une raison de plus pour l'idée 5 |
| 15 | **Règles des coûts combinés (§9.1)** | `canPlayCard` exige `PV > coût` (pas `≥`) ; `eco` / `cheap` ne remboursent que le mana ; la rareté ne scale jamais `costs` ; le validateur de D17 (`costs.armor` dans un lot Berserker → erreur) est bon — ne pas l'étendre à `costs.hp` dans un lot qui soigne, ce serait une faute de conception, pas de donnée | Spec | — |

### 8.3. Ses trois priorités s'il tenait le stylo de la spec

1. **Le moteur de runes data-driven, avec la sémantique « charges par combat » dès le premier jour** (§4.4 du brainstorm + idées 2.4, 8, 9). Tout le reste en dépend ; l'ajouter après coup, c'est réécrire les 14 runes.
2. **La fusion par lot et les signatures innées** (2.1 + idée 1) avant d'écrire une seule carte : elles changent la taille qu'un lot doit avoir (un lot de 6 fusionne dès l'acte 1) et rendent visibles les deux systèmes dans lesquels D3 et D19 investissent le plus.
3. **La simulation de §4.1, avec les trois compteurs qui lui manquent** : niveau atteint par acte (R1), visites de feu par acte (R2), dégâts d'un tour Berserker par acte (R3). Fixer sur ces courbes les chances de D1, l'exposant d'XP et le `ratio` de conversion — puis seulement écrire les lots.

---

## 9. Constats collatéraux — hors brainstorm, à router

| Constat | Preuve | Destination proposée |
|:---|:---|:---|
| **Bug latent** : les statuts `might` de durées différentes fusionnent en un seul (valeur sommée, durée max) — `demon_form` + `iron_wall` chez le Berserker = Puissance 12 pendant 4 tours ; Rage s'y accumule | `entity_stats.dart:134-139`, `status_effect.dart:17` | Correctif indépendant de la spec (idée 2 du designer) — **tranché le 30/09, D36** : un statut par source |
| **Flux de Mana + Affinité** : une Affinité peu commune (+2) porte le seuil à 1 ; toute Compétence à 1 devient gratuite | `mana_flux.json`, `affinity.json`, `passive_strategies.dart:107` | `floor` en donnée — **tranché le 30/09, D43** |
| **DDA** : `PlayerPower += playerCardsCount × 2` — sous D1/D2 le deck gonflé subi monte le budget ennemi | `encounter_system.dart:101` | Spec du chantier 1 — **tranché le 30/09, D47** : la somme des `fusionRank` remplace la taille |
| **Fiches `_rules` périmées** : `01-00` annonce un *« Draft de Récompense : choix de carte de combat normal »* qui n'existe pas et des colonnes *« 5 / 15 / 10 Atk »* supprimées ; `03-8:22` décrit `eco` comme une réduction de coût ; `04-00` liste `strength` / `strength_regen` au lieu de `might` / `might_regen` | lecture | `memory-bank-sync` |
| `docs/INDEX.md` n'indexe pas la revue du 10/09 (`10-09-2026_revue_brainstorms_aout_et_lots.md`) | `grep` vide | Ajout d'une ligne en §1 ou §15 |
| **Survie** *(simulation du 30/09)* : première quasi-mort à l'acte 5 dans 100 % des runs, PV sous 10 % du max dès l'acte 8 — dégâts ennemis 45 → 154 par tour entre les actes 5 et 15 contre ~100 PV de héros ; c'est la pente du code (PV × 1,35 et dégâts × 1,25 tous les 2 actes, +1 ennemi par acte jusqu'à 5, niveau ennemi = niveau héros) | rapport §2.3, §5 | **P-16**, avec P-10 en regard (le portail à l'acte 5 fait de « 15 actes » un horizon endless) ; à mesurer en jeu avant de calibrer |
| **L'or déborde** *(simulation)* : 9 473 gagnés, 3 333 dépensés, 5 978 (2 983–8 262) en réserve à l'acte 15 *(première passe ; à la relance à k = 2 : 9 100 · 3 358 · **5 596 (2 907–7 763)**, rapport §7.2 — les chiffres à porter en ROADMAP)* ; `b` de 25 à 150 ne change pas le nombre d'affûtages | rapport §2.3, §3.8, §7.2 | **P-16** : un puits d'or à créer |
| **Boucle XP / niveau ennemi** *(simulation)* : le niveau ennemi suit celui du héros et rapporte +10 % d'XP par niveau — tout palier constant diverge (niveau 999 avant l'acte 10) ; la table par acte de D58 se recale à chaque changement de budget | `encounter_system.dart:136-148`, `reward_controller.dart:86` ; rapport §3.9 | **P-16** : découpler le bonus d'XP du niveau, ou le niveau ennemi du niveau héros |

---

## 10. Questions à trancher avant d'ouvrir la spec du chantier 1

> *État au 29/09, soir : les questions 1, 2, 3, 4, 5, 7 et 8 sont tranchées (D22 à D28 du brainstorm). La 6, la fusion par lot, est tranchée le 29/09 au soir : refusée comme remplacement, gardée comme événement (D29).*

1. **D3 / D13** : confirmer que D13 amende D3 (I1).
2. **Le plafond des runes (Q2, bloquante)** : `maxLevel` par rune, ou la sémantique « charges par combat » (idée 2.4) — au minimum pour `eco`, `quick`, `cheap`, `echo`, `splash`.
3. **La fréquence du Puits (E1)** : nœud à fréquence fixée, service de boutique, ou option du feu de camp.
4. **La longueur de run cible de la simulation (E4)** : 3, 5, 10 actes — ou attendre P-12.
5. **La courbe d'XP (E2)** : en donnée et aplatie (P-16 avancé), ou paliers de signature réindexés (amendement de D19/D21).
6. **La fusion par lot (idée 2.1)** : à simuler contre la fusion par copie identique avant d'écrire une carte.
7. **`maxHandSize` en stat de run** : confirmer le renversement d'ADR-078 D3 (E3).
8. **Le sort de `focus` et `awakening`**, et la règle des cartes à 0 sur le deck accessible (I6, I8).

Les questions Q1, Q3, Q4, Q6 à Q14 du brainstorm restent des décisions de spec, non bloquantes.

---

## 11. Seconde passe de cohérence — 30/09, après D36-D49

**Objet** : vérifier que les corrections des 29 et 30/09 n'ont pas cassé la cohérence du brainstorm, avant de découper les lots. **Constat** : I1-I12 et §2.1 sont propagées proprement, contrôlées une à une ; c'est la vague D36-D49 du 30/09 qui a désynchronisé le texte — trois décisions non propagées, un chiffre resté à l'ère de D1, et §10-§11 qui n'avaient pas absorbé le périmètre nouveau. Les tableaux de §4.1 (nœuds, trouvailles, copies) et d'or de §4.2 ont été recalculés : justes. Les références de code ajoutées le 30/09 ont été vérifiées : `tutorial_engine.dart:175`, `tutorial_starter_deck_widget.dart:41`, `player_stats_manager.dart:472`, `level_up_reward_service.dart:50-57`, `reward_controller.dart:89-100,186-194`, `effect_resolver.dart:114` — exactes ; `3b8c66f` est toujours `HEAD`. Tout est appliqué le 30/09 ; les arbitrages du propriétaire sont D50 à D55 du brainstorm.

| # | Où | Constat | Sort |
|:---:|:---|:---|:---|
| **S1** | §7.2, §7.4 | D37 (ratio 0,5) non propagé : « 6 armure = +6 Puissance », `iron_wall` +10, `awakening` +4, `warcry` +4 | ✅ 3, 5, 2, 2 |
| **S2** | §4.2 | `eco` / `quick` encore à `minFusionRank: 3` malgré D48 | ✅ 2 |
| **S3** | §4.2 | L'exemple `sharp.json` en `valuePerLevel` malgré D33 | ✅ `valuePercentPerLevel` |
| **S4** | §4.2 pt 2 | « une carte donnée revient tous les ~8 actes » : le rythme de D1 | ✅ ~2,6 actes sous D31 — le pari est plus court, il reste un pari |
| **S5** | §9.2 #4 | « Deuxième » contre « une seule livraison » de §10 / §11 | ✅ Même lot |
| **S6** | §4.2 | Une peu commune portant `quick:1`, impossible sous D48 | ✅ `burning:1` |
| **S7** | §4.1, §2.1 ici | « D8, « plus tard » » : la ligne n'est pas numérotée | ✅ |
| **S8** | §0 | `weakness` → Sanctifié est en §7.1, pas §7.2 | ✅ |
| **S9** | §11 graphe | `E → SIM` contredit §4.1, §12 et la ligne de clôture : la simulation précède la spec | ✅ `SIM → E`, script jetable sur les formules |
| **S10** | §4.4 | *Faiblesse* « au niveau 5 » — une majeure arrive au niveau 10 (D21) | ✅ |
| **S11** | §5 vs §7.2 | *Sang versé* (0 mana, 4 PV, non épuisable) contre « toute carte à 0 mana épuise » | **D50** : le test lit le coût total |
| **S12** | D42(c) vs D27 | `eco` 2 par mythique rouvre D27 sans renvoi ; « une run sur sept » compte la sortie du pool, pas le tirage ; `eco` 2 + `quick` 1 + `enduring` est un moteur que D44 ne voit pas | **D51** : `excludesRunes` sur `enduring`, une run sur 25-30 |
| **S13** | D44 | `cheap` sans `requiresMinCost`, morte sur une carte à 0 | **D51** |
| **S14** | §4.1 vs §11 | L'échange 3 → 1 « nécessaire » vivait en P-16, dernier nœud ; D29 absent du graphe | **D52** : D29 dans E, l'échange aléatoire en P-16 |
| **S15** | §11 | D49 en C1 alors que sa moitié moteur répond à D31, dans E | **D53** : dernier lot de E ; l'écran d'évolution en C1 |
| **S16** | §11 | Périmètre de E sans D22-D24, D29, D42, D46, D47, ni les pré-forgées ; D36 sans destination | ✅ graphe et ligne P-43 réécrits depuis §1 |
| **S17** | §4.4 | `haste` mineure reprenable : un seul niveau utile sur une recharge de 2 ; « plancher (D49) » mal attribué | **D54** : majeure |
| **S18** | §7.1 | *Prière* (1, soigne 3, non épuisable) domine `heal_potion` | **D55** : soin dans le temps, `hp_regen` |
| **S19** | §4.4 | La recharge « à côté » d'`evolutions`, un champ persisté | ✅ état de combat, jamais sauvegardée |
| **S20** | §9.1 | L'idée 4 (§8.2) surestimait D38 : 1 × 1 ≤ 0 + 1, *Sang versé* garde la Puissance entière | Q21 du brainstorm |
| — | Rédaction | Titres de §1 et §13 ; D4 sans renvoi vers D27 / D42 ; « carte » pour signature (D19, Q6, §4.4) ; « 6 signatures » au budget de §7.4 et « le tutoriel ne bouge pas » ; G2 avec `quick:2` ; commentaire de §9.1 ; Vampire absent de §9.2 #1 ; *Jugement* nommait une carte et une évolution ; « première » source `skill` en double ; Q19-Q20 dans un bloc « 30/09 » ; « 200 runs » | ✅ |

À noter sur cette revue même : son §6 item 16 prescrivait des Q15-Q18 (longueur de run, Puits, XP, `focus`) qui ne sont pas celles écrites — elles ont été résolues par D22 à D26 et les numéros ont servi à d'autres questions. Sans effet.

---

## 12. Troisième passe de cohérence — 30/09, après D56-D64

**Objet** : vérifier que la vague de la simulation — D56 à D64, le découpage E0-E4, les tableaux de §4.1, §4.2, §4.4 et §8 réécrits sur la mesure — n'a pas cassé la cohérence du brainstorm, avant de préparer les lots. **Méthode** : lecture intégrale des trois documents ; chaque chiffre que le brainstorm attribue au rapport relu dans le rapport ; les références de code ajoutées le 30/09 relues à `3b8c66f`, toujours `HEAD` ; le script relu aux endroits qui fondent D58 et D59. **Constat** : la propagation est propre — les 64 décisions ne se contredisent pas, les renvois de section vers le rapport (§2.1 à §2.3, §3.1 à §3.16, §4, §5, §6) et vers cette revue existent tous, et les chiffres sont retrouvés au chiffre près. Ce qui reste est d'une autre nature : **le découpage D64 laisse les runes de §8 et six décisions sans lot**, et **D58 et D59 n'ont pas été mesurées ensemble**. **Arbitré et appliqué le 30/09 au soir** : T3 → D65, T4 → D66, T1 et T2 → D67 (script relancé à k = 2, rapport §7) ; T5 à T15 et les deux collatéraux édités le même jour.

### 12.1. Ce qui a été vérifié

| Vérifié | Résultat |
|:---|:---|
| Chiffres attribués au rapport — §4.1 (nœuds, trouvailles, pool, 1re fusion / rare / épique / légendaire, deck 35, 45 fusions, Miroir −27 %, échange 3 → 1) ; §4.2 (20 visites, 14 / 5 / 1, 5 978 or, 4 114 → 1 105, 73 niveaux, rune 9 / 25, 400 or) ; §4.4 (niveau 10 à l'acte 5, 30 à l'acte 15, 12 évolutions, plafond 12 / 4) ; D41 (un combat sur sept) ; D48, D56 à D62 ; §11 P-16 | Tous retrouvés dans le rapport (§2.1, §2.2, §2.3, §3.2 à §3.16, §4). Une seule dissonance, **interne au rapport** : « 1re mythique D42c prise » vaut 12 % dans la table « Première fois » de §2.1 (2 700 runs) et 11 % en §3.11 (1 800 runs) — D62 dit 11 %, sans effet |
| Références de code du 30/09 : `encounter_system.dart:101,136-148`, `reward_controller.dart:86`, `level_up_reward_service.dart:50-57,127-145`, `player_stats_manager.dart:127`, `entity_stats.dart:134-139`, `map_content_placer.dart:10,24-36` | Exactes |
| Les 64 décisions, relues deux à deux : D2 / D56, D27 / D42(c) / D51 / D62, D31 / D57, D43 / D60, D44 / D51 / D61, D47 / D59, D48 / D27, D52 / D56, D29 / D56 | Chaque amendement est marqué sur la décision amendée ; aucune paire ne se contredit |
| §10 contre §11 (graphe, table des lots, lignes P-43 / P-42 / P-44 / P-16) | Alignés : mêmes cinq lots, même contenu, mêmes renvois |
| Cartes citées comme survivantes ou neutres (`metallicize`, `demon_form`, `warcry`, `iron_wall`, `awakening`, `concentration`, `heal_potion`, `focus`) | Valeurs conformes au JSON — mais *Vigile* domine `metallicize`, T6 |
| `dart analyze tool/simulations/d26_economy_sim.dart` | Propre |

### 12.2. Ce qui reste — par gravité

| # | Où | Constat | Gravité | Proposition |
|:---:|:---|:---|:---:|:---|
| **T1** | D58 × D59 | **La table d'XP de D58 a été calée à k = 5, et D59 retient k = 2.** Le script cale la table sur `Params()` dont le défaut est `ddaK = 5` (`d26_economy_sim.dart:91`, `calibrate(base…)`) ; la variante « Σ rang × 2 » de §3.10 reprend cette table telle quelle. À k = 2, le niveau à l'acte 15 tombe à **28 (24–33)** contre 30 (rapport §3.10) : **1,9 niveau par acte**, sous le « au moins 2 » de D24. D58 dit elle-même que « la table se recale à chaque changement de budget ennemi », et §12 du brainstorm interdit de changer une valeur de D56-D63 sans relancer — or D59 change le budget de −7 % | **Moyen** — une valeur de spec E3, pas une décision | Relancer la calibration avec `ddaK = 2` (le script n'a pas d'option : passer le défaut de la ligne 91 à 2, ou ajouter `--dda-k`) ; reporter la table mesurée dans D58, et y noter « calée à k = 2 » |
| **T2** | D58 | **Aucune règle au-delà de l'acte 15.** La run n'a pas de fin (E4, §3.3) ; la table a 15 entrées ; le script répète la dernière valeur (`xpTable[min(act, length) − 1]`, ligne 2555) sans que le brainstorm le dise — et la dernière valeur, 1 120, est la plus basse depuis l'acte 8 : au-delà, le héros monte *plus vite* que dans les actes 11-14 | Moyen | Ajouter à D58 : « au-delà de la dernière entrée, la dernière valeur est répétée (convention du script) » — ou une question de spec en §13 (extrapoler, ou plafonner le gain par acte). À simuler avec T1 si la run cible dépasse 15 actes (P-10, P-12) |
| **T3** | §8, §11 | **Les runes neuves de §8 n'ont pas de lot.** D18 les veut proposables à la fusion, D63 leur donne poids 50 et `minFusionRank` 1, la simulation les a jouées dès l'acte 1 ; mais E1 livre le moteur, E2 la fusion, et aucun lot n'écrit `cheap`, `piercing`, `lifesteal`, `transfusion`, `precise`, `splash`, `echo`, `retain`, `spectral`. Leur colonne « Moteur » les disperse : `transfusion` exige `costs.hp` (P-44 lot 1), `retain` exige les mots-clés (P-44 lot 3), `piercing`, `precise`, `splash`, `echo`, `lifesteal` touchent `DamagePipeline` ou les stratégies. **Conséquence pour E2, avec les 8 runes d'aujourd'hui** : `defend_basic` (Compétence, armure, 1 mana, sans épuisement) n'a qu'une rune éligible à sa première fusion (`hardened` — `sharp` est par effet `damage` sous D61, les trois élémentaires sont `attack` seul, `enduring` exige l'épuisement, `quick` et `eco` attendent le rang 2), deux à la seconde (`quick`, `eco`), **aucune à la troisième**. « 1 rune parmi 3 » (D3) est vraie pour les Attaques, fausse pour les Compétences et les Pouvoirs | **Moyen-fort** — un trou du découpage D64 | Trancher un lot par rune : les trois à moteur nul ou « une ligne » (`cheap`, `precise`, `spectral`) **dans E2**, avec la fusion ; `piercing`, `lifesteal`, `splash`, `echo` dans un **E5** ou avec P-44 lot 1 ; `transfusion` avec P-44 lot 1 (coûts), `retain` avec P-44 lot 3. Et la spec E2 dit ce que fait `mergeCards` sous 3 runes éligibles — en proposer moins, jamais aucune si une existe |
| **T4** | §11 | **Six décisions sans destination** dans le graphe, la table des lots et les lignes P-4x : **D30** (Canalisation en banque de mana — modifie un passif livré ; Voile est en tranche 2 ou 3 par D34) ; **D37** (`ratio` 0,5 du Berserker — règle de classe, jouée par la simulation dès l'acte 1, change `iron_wall` chez lui aujourd'hui : +10 → +5) ; **D38** (`mightRatio` et son test) et **D40** (règles des coûts) — implicites en §9 mais non citées par le nœud P-44 lot 1 ; **D45** (`feeds` et son test) et **D50** (test des cartes gratuites) — des tests de données du catalogue, non cités par C1 | Moyen | Une ligne par décision : D30 → C2 (avec le lot Voile) ; D37 → **E0, à côté de D36** (même famille — un garde-fou de Puissance, quelques lignes, indépendant) ou P-44 lot 1 ; D38, D40 → P-44 lot 1 ; D45, D50 → C1 |
| **T5** | §11, ligne P-44 | « sans `costs.hp` ni `scaleWith` le lot Sang tombe à **trois** cartes » : c'était avec *Garde brisée*, retirée le 29/09 (B.4). Il reste *Transe* et `demon_form` : **deux** | Mineur | Corriger le chiffre — l'argument se renforce |
| **T6** | §7.1 | ***Vigile* domine `metallicize` dans le même lot** : 1, Pouvoir, `armor_regen` 2 pendant **3** tours contre 1, Pouvoir, `armor_regen` 2 pendant **2** tours (`metallicize.json`). Même défaut que *Muraille* / `iron_wall` (B.3). Et *Barrière* (Voile, §7.3) paie **2** mana le même effet que *Vigile* à 1 | Mineur — le catalogue n'est pas prêt par construction | Différencier *Vigile* par ce que Sanctifié veut (l'armure posée **survit** au début du tour — la variante « armure conservée » que D43 réserve à ce lot), ou le retirer au profit de `metallicize` ; *Barrière* à re-valuer avec la tranche 2 |
| **T7** | §8, D44, D51 | **Deux noms pour un même champ** : `excludes: ["eco"]` sur `cheap` (D44) et `excludesRunes: ["eco", "quick"]` sur `enduring` (D51), à côté d'`excludesEffects`. Une exclusion par id de rune, symétrique par D61, n'a besoin que d'un nom | Mineur | `excludesRunes` partout ; une donnée de spec E1 |
| **T8** | §8, note sous la table des `maxLevel` | La note « charges par combat » (idée 2.4) « remplacerait les quatre lignes concernées » — pour `eco` et `quick`, elle rouvrirait D27 (niveau unique), que §3.13 et §3.14 viennent de confirmer ; et §7 ci-dessus note que 2.4 a été **retenue sous forme de pourcentage** (D33) | Mineur | Restreindre la note à `echo` et `splash`, ou la barrer |
| **T9** | §4.3 | « Le puits d'or est **préservé** … P-16 aura les deux à calibrer avec la boutique » contre §4.2, §11 et §12 : l'or déborde (5 978 à l'acte 15), le Puits ne consomme pas (≈ 3 300 quel que soit son rythme, §3.6), P-16 a « un puits d'or **à créer** ». Une phrase d'avant la mesure | Mineur | Reformuler : l'affûtage et le Puits ne suffisent pas, P-16 crée le puits |
| **T10** | §11, E1 | « le seul lot **sans effet visible** » : D33 (`sharp` +15 % de la base, +1 au moins, au lieu de +2 par niveau — `strike_basic` 6 → +1) et D48 (`quick` plus proposée en peu commune) changent ce que le joueur voit à la forge du feu, qui vit jusqu'à E2. Et E1 supprime la capacité pendant que cette forge existe encore : sans borne, une carte y prend une rune de chaque type | Mineur-moyen — une question de spec E1 | « sans changement de boucle » plutôt que « sans effet visible » ; la spec E1 dit ce qui borne la forge du feu entre E1 et E2 — « une rune par type » (D3) suffit |
| **T11** | §4.2 | « Le geste de fusion » ne cite qu'`eligibleCardTypes` ; D61 a fait passer `sharp` et `hardened` en `eligibleEffects`, et l'esquisse `sharp.json` « demain » ne le montre pas | Mineur | Ajouter `eligibleEffects: ["damage"]` à l'esquisse et à la phrase |
| **T12** | §13 | Q9, Q15 et Q18 ne sont ni barrées ni dans « Ce qui reste ouvert » ; D63 en fait des valeurs de spec par défaut | Mineur | Les lister comme « ouvertes, avec valeur par défaut (D63) » |
| **T13** | §11, graphe | `R → E` : la reproduction de la « pioche infinie » ne conditionne que **E3** (D25, `maxHandSize`), pas E0-E2 | Mineur | `R → E3`, ou une note sur le nœud |
| **T14** | §4.4 | « le rendre data-driven est **le premier lot** du chantier » : c'est E1 ; E0 est D36 | Rédaction | « le lot E1 » |
| **T15** | §12 du brainstorm | « **Simuler** l'archétype Sang avec un soin négatif » : « simuler » y veut dire *émuler en code* ; depuis D26 le mot désigne la simulation | Rédaction | « Implémenter le coût en PV de Sang comme un soin négatif » |

### 12.3. Collatéraux — hors brainstorm

| Constat | Preuve | Destination |
|:---|:---|:---|
| **Le script n'est pas jetable.** Le rapport le dit « jetable, non committé » ; le brainstorm en fait un outil durable — §4.1 « se relance à chaque changement de donnée », §12 ligne 1, D26 — et T1 le relance dès la spec E3. `dart analyze` est propre ; `CLAUDE.md` § Tooling dit que `tool/` tient « a single script » | `tool/simulations/d26_economy_sim.dart`, non suivi | Committer le script avec les trois documents ; une ligne dans `CLAUDE.md` (§ Tooling) et dans `_patterns/` par `memory-bank-sync` |
| `docs/INDEX.md` : « Dernière mise à jour : 2026-09-29 » avec trois entrées du 30/09 ; la revue du 10/09 n'y est toujours pas indexée (§9 ci-dessus, constat ouvert) | `grep` vide | Ajout de la ligne ; date mise à jour avec cette passe |

**Ce que la passe change à la préparation des lots.** Trois arbitrages avant d'ouvrir la spec E0 : le lot des runes de §8 (T3) — c'est lui qui fixe le contenu réel de E2 et l'existence d'un E5 ; la destination de D30, D37, D38, D40, D45, D50 (T4) — D37 peut rejoindre E0 dès maintenant ; et la relance de la calibration à k = 2 (T1), qui peut attendre la spec E3 mais doit précéder son écriture. Le reste est de l'édition d'une heure, à appliquer dans la même passe que les arbitrages. *État au 30/09, soir : les trois sont pris — D65 (pas de E5 : les runes de pipeline vont avec P-44 lot 1, dont elles partagent les fichiers, et E4 reste le dernier lot de E par D53), D66, D67 — et tout est appliqué.*

---

## 13. Quatrième passe de cohérence — 30/09, après D65-D67

**Objet** : vérifier que la vague de la troisième passe — D65 à D67, les runes de §8 réparties, les six décisions placées dans leur lot, la table d'XP recalée à k = 2, les retouches T5 à T15 — n'a pas cassé la cohérence du brainstorm, avant de préparer les lots. **Méthode** : lecture intégrale des trois documents, dans une session neuve ; chaque chiffre que le brainstorm attribue à la relance (rapport §7) relu dans le rapport ; les 67 décisions relues avec leurs renvois croisés ; le graphe et la table des lots de §11 relus contre §8, §9, §10 et §13 du brainstorm ; le script relu aux trois endroits qui fondent D67 et §7.3 ; `3b8c66f` toujours `HEAD` (2026-09-21) ; les quatre références de code qu'ajoute cette passe lues à la main. **Constat** : **la propagation de D65 à D67 est propre** — chaque rune a son lot en §8, §10 et §11 ; D37 est en E0 partout où E0 apparaît ; la table de D58 est barrée et D67 la remplace ; les chiffres de référence de §4.1, §4.2, §4.3, D59, D62 et P-16 sont ceux de la relance, les chiffres de leviers ceux de la première passe, comme §4.1 l'annonce. Ce qui reste est plus petit que la troisième passe : **une ligne de §1 restée à l'ère de D52**, **une question (Q4) que §13 dit tranchée et que D52 et §4.1 disent ouverte**, et **une frontière E1 / E2 que la spec E1 devra écrire** — telle qu'E1 est décrite, deux écrans d'aujourd'hui perdent leur entrée pendant un lot entier. **Arbitré et appliqué le 30/09 au soir** : IV3 → **D68** (option a, « E1 applique, E2 obtient »), IV2 → option (a), Q4 reste ouverte ; IV1, IV4 à IV11 et les collatéraux édités le même jour. Lettrage **IV** (quatrième), Q étant pris par les questions du brainstorm.

### 13.1. Ce qui a été vérifié

| Vérifié | Résultat |
|:---|:---|
| **D65** — §8 (paragraphe « Le lot de chaque rune », note « 11 runes en E2 »), §10 ligne 1, §11 (nœuds E2 et P44a, table E2, lignes P-43 et P-44), §4.2 (« moins de 3, jamais aucune ») | Cohérents. Le compte « `hardened` et `cheap` » pour une Compétence d'armure à sa première fusion est juste sous D51 et D61 : `sharp`, `precise`, `spectral` sont par effet `damage`, les trois élémentaires `attack` seul, `enduring` exige l'épuisement, `quick` et `eco` attendent le rang 2 |
| **D66** — note sur D64, §10 ligne 1, §11 (nœud et table E0, nœud C1 pour D45 / D50, nœud P44a pour D38 / D40, nœud C2 pour D30, lignes P-43 et P-44) | Cohérents ; D30 est placé en tranche 2, ce que T4 laissait entre 2 et 3 — aucun autre passage ne fixe l'ordre des tranches 2 et 3, pas de contradiction |
| **D67** — D58 barrée avec renvoi ; §4.4 (niveau 10 (8–12) à l'acte 5, 30 (25–35) à l'acte 15, 12 évolutions) ; §12 ligne 1 ; convention « dernière valeur répétée » | Retrouvés dans le rapport §7.1 et §7.2 ; la convention est dans D67 et dans le rapport (`xpTable[min(act, length) − 1]`, `d26_economy_sim.dart:2556`) |
| Chiffres de la relance cités comme référence — §4.1 (19 % de légendaires ; 3,7 / 1,4 / 1,3 / 1,7 / 0,4 ; 86 cartes ; 45 fusions ; rang 3 (3–4)), §4.2 (20 / 14 / 5 / 1 ; 5 596 (2 907–7 763) ; 3 824 → 1 056 ; 73 niveaux dont ~8 ; 9 jusqu'à 24 ; 7 contre 9 ; ~450 or), §4.3 (5 596 ; ≈ 3 300), D41 (un combat sur sept : 5 / 35), D59 (786 / 783), D62 (11 à 12 %), §9.1 (2 à 11 %), §11 P-16 (5 596) | Tous dans le rapport §7.2 et §7.3. Les chiffres de leviers — Miroir −27 % (§3.4 ; −28 % à la relance), épique 6 % par la trouvaille seule (§3.2 ; 7 %), Puissance à 0 mana −2 à −5 % (§3.12) — restent ceux de §3.x, ce que §4.1 dit explicitement : sans effet |
| **T5 à T15** — deux cartes pour Sang (ligne P-44) ; *Vigile* retirée, *Barrière* re-valuée (§7.1, §7.3) ; `excludesRunes` seul (§8, D44) ; note « charges » restreinte à `echo` et `splash` ; « le puits d'or ne suffit pas » (§4.3) ; « sans changement de boucle » (E1) ; `eligibleEffects` dans l'esquisse et le geste de fusion ; Q9 / Q15 / Q18 « avec valeur par défaut » ; `R → E3` ; « lot E1 » ; « Implémenter » (§12) | Toutes retrouvées |
| Les 67 décisions relues avec leurs renvois croisés : D1 / D31 / D57, D2 / D56, D3 / D13, D4 / D27 / D42, D24 / D58 / D67, D29 / D52 / D56, D42(c) / D51 / D62, D43 / D60, D47 / D59, D48 / D27, D64 / D65 / D66 | Chaque amendement est marqué sur la décision amendée ; **une ligne non numérotée** (« Plus tard ») reste à l'ère de D52 — IV1 |
| §11 (graphe, table des lots, lignes P-4x) contre §8 (lot des runes), §9.2 (« Troisième » = lot 3 pour les mots-clés, « Après 7 » = lot 3 pour la production : le graphe dit la même chose), §10 et §13 | Alignés, sauf §10 ligne 3 (IV7) et E3 sans D67 (IV6) |
| Le script : défaut `ddaK = 2` (`d26_economy_sim.dart:91`) ; Canalisation jouée en **banque de mana** (D30 — `:615`, `:1472`, `:1510`), donc les chiffres de Voile sont ceux du passif décidé, pas de l'ancien | Conformes à D67 et à §7.3 ; `dart analyze` propre à la troisième passe, le fichier n'a pas changé depuis |
| Références de code lues pour IV3 : `forge_upgrade_dialog.dart:80-86`, `shop_controller.dart:51-57`, `forge_rune_rules.dart:46-52` et `:60-78`, `forge_fusion_screen.dart:102,112` | Exactes |
| Cartes survivantes et neutres citées (§7.4 : 7 + 9), `focus` supprimée, `mana_surge` hors du compte (§5), *Lacération* seule carte à 0 de Vampire sous D50 (`concentration` + *Lacération* = 2, épuisables) | Conformes |

### 13.2. Ce qui reste — par gravité

| # | Où | Constat | Gravité | Proposition |
|:---:|:---|:---|:---:|:---|
| **IV1** | §1, ligne « Plus tard » | *« (moment tranché par D52 : P-16 ; l'événement de fusion de D29, lui, est dans le chantier E) »* — c'est la lecture de D52 avant D56, qui a **sorti D29 de E** pour P-16. D52 est barrée en conséquence, D56 et §4.1 le disent ; cette ligne, non numérotée, ne l'a pas suivie | **Moyen** — une ligne de §1 contredit une décision acquise | *« (moment tranché par D52, puis D56 : P-16 — avec l'événement de fusion de D29, qui a quitté E le 30/09) »* |
| **IV2** | §13 Q4 vs D52, §4.1 | **Q4 est dite tranchée et ouverte à la fois.** §13 : *« Tranchée : P-16 … en forme, l'événement — 2 usages par run contre 0 au feu de camp »* ; D52 : *« Q4 garde sa forme ouverte, son moment est tranché »* ; §4.1, table des doublons : *« un choix de variété, la forme reste ouverte (Q4) »*. Aucune décision de §1 ne fixe la forme : D56 place l'échange en P-16 et cite la mesure, sans choisir ; la mesure écarte le feu de camp (0 usage) et n'a pas joué le **nœud** (rapport §3.5 : événement et feu seulement). Q4 manque aussi à « Ce qui reste ouvert » | Mineur-moyen — une question de §13 en avance sur §1 | **(a) recommandé** : Q4 reste ouverte — §13 : *« moment tranché (P-16, D56) ; forme : le feu de camp est écarté par la mesure (0 usage), le nœud n'a pas été mesuré, événement ou nœud se tranche en P-16 »*, et Q4 rejoint « Ce qui reste ouvert » ; D52 et §4.1 inchangées. **(b)** le propriétaire tranche maintenant l'événement : une décision D68, D52 et §4.1 amendées. P-16 hérite dans les deux cas ; (a) ne lui prend pas une décision qu'il n'a pas mesurée |
| **IV3** | §11, E1 | **La frontière E1 / E2 fait tomber deux écrans d'aujourd'hui.** E1 est décrit comme *« le seul lot sans changement de boucle »*, et sa note dit que D33 et D48 « se voient à la forge du feu de camp, qui vit jusqu'à E2 », bornée par « une rune par type ». Or : **(1)** `pools` → `minFusionRank` — la forge du feu (`forge_upgrade_dialog.dart:86`) et les pré-forgées de la boutique (`shop_controller.dart:57`) filtrent aujourd'hui par `pools.contains(rareté)` ; avec `minFusionRank` pour seul filtre, **une commune (rang 0) n'a aucune rune éligible** (`sharp` est à 1) : entre E1 et E2, tout le deck de départ cesse d'être forgeable, ce qui est un changement de boucle. **(2)** « une rune par type par carte » (E1, `stackable` disparaît) — le nœud Forge de Fusion (`forgeFusion`, `ForgeFusionScreen`) ne propose que les cartes portant **deux fois le même id** (`forge_rune_rules.dart:69`, `forge_fusion_screen.dart:102`) : sous E1 aucune carte ne le peut, **le nœud est mort** jusqu'à ce qu'E2 le réécrive en Puits. T10 avait vu la capacité, pas ces deux entrées | **Moyen** — un arbitrage de périmètre avant la spec E1 | **(a) recommandé — E1 n'applique, E2 obtient.** E1 garde `pools`, `stackable` et la capacité **en lecture** (leurs seuls lecteurs sont les deux écrans qu'E2 réécrit) et livre ce qui change *l'application* des runes : le renommage `fusionRank` (lu par la capacité en attendant), l'applicateur de deltas, `valuePercentPerLevel` (D33), `maxLevel` (D27 — lu dès E1 par `consolidate`, `forge_rune_rules.dart:52`, ce qui ferme aussitôt l'`eco:3` de la Forge de Fusion), l'éligibilité en donnée (D44, D51, D61), G1, G2. Passent en **E2**, avec les deux écrans : `minFusionRank` (D48), « une rune par type » (D3), « capacité supprimée, pré-forgées bornées par `fusionRank` » (D28), la suppression de `pools` et `stackable`. La note d'E1 devient : *« D33 se voit à la forge du feu (+15 % de la base au lieu de +2 par niveau) — le seul effet visible, la boucle ne change pas »*. **(b)** garder E1 tel quel et écrire la transition dans sa spec : la forge du feu et la boutique comparent `minFusionRank ≤ fusionRank + 1` (le rang que la fusion donnerait, la comparaison de `mergeCards` en §2.1) ; le nœud `forgeFusion` est accepté mort pendant E1 et masqué de la carte (`map_content_placer`, 25 % → 0 pour un lot). (a) tient la promesse « sans changement de boucle » sans code jetable ; (b) en écrit |
| **IV4** | D44, D51, D61, §8 | **`excludesRunes` : la symétrie n'est déclarée que pour une paire.** D61 rend `enduring` ↔ `eco` / `quick` symétrique ; `cheap` porte `excludesRunes: ["eco"]` (D44, §8) sans que l'inverse soit dit. Dans l'ordre `eco` d'abord, puis `cheap` : la carte à 1 coûte 0 et rend 1 — `focus` encore, ce que D44 voulait fermer. Selon que `requiresMinCost` lit le coût **de base** ou le coût **courant** (après `cheap`), la règle tient ou non dans l'autre ordre | Mineur — une ligne de spec E1 | Une règle, pas une liste : **`excludesRunes` est symétrique par moteur** pour toute paire — une carte qui porte A ne se voit pas proposer B dès que l'un des deux exclut l'autre — et `requiresMinCost` lit le **coût courant**. À écrire dans la note de D61 (ou D44) ; aucune donnée ne change |
| **IV5** | §4.3, Puits | *« **toutes** les runes éligibles à cette carte sont proposées »* — éligibles au sens de quoi ? Le geste de fusion (§4.2) définit le prédicat : types ou effets, `minFusionRank ≤ rang atteint`, id absent, règles de D44 / D51. Sans `minFusionRank`, le Puits met `eco` sur une peu commune et contourne D48 ; sans « id absent », il propose une rune déjà portée | Mineur — spec E2 | *« toutes les runes éligibles **au sens de §4.2** — le prédicat de `mergeCards`, au rang de la carte — sont proposées »* |
| **IV6** | §11 E1-E3, §4.4 | Renvois de décisions incomplets là où la chose est livrée : **E3** cite D58 sans **D67**, la table qu'elle implémente ; **§4.4** dit « mesuré … avec la table par acte de D58 » pour les chiffres de la relance (D67) ; **E1** ne cite pas **D28** (renommage `fusionRank`, capacité, pré-forgées — si IV3(a) est retenue, D28 va en E2) ; **E2** ne cite pas **D63** (`b` = 50) | Rédaction | Ajouter D67 à E3 et à §4.4 ; D28 au lot qu'IV3 lui donne ; D63 à E2 |
| **IV7** | §10, ligne 3 | *« P-44 lot 1 (§9) : `scaleWith`, multi-coups, statuts proportionnels, coûts combinés — un même fichier »* — sans les cinq runes de pipeline et `transfusion` (D65) ni `mightRatio` et les règles de coût (D38, D40 — D66), que §11 (nœud P44a, ligne P-44) porte | Rédaction — §10 en retard d'une passe sur §11 | Compléter la ligne : *« … coûts combinés, `mightRatio` (D38) et les règles de coût (D40) ; les runes `piercing`, `lifesteal`, `splash`, `echo`, `transfusion` (D65) »* |
| **IV8** | §11, E2 | `tutorial_engine.dart:451` appelle `mergeCards()` (annexe A, n° 29) ; sous E2 la fusion propose une rune — le tutoriel bouge **en E2**, pas seulement en E4. §7.4 et la ligne P-43 le disent (« il bouge pour D49 et la fusion »), la ligne E2 non | Mineur | Ajouter à E2 : *« le tutoriel (`tutorial_engine.dart:451`, la fusion propose désormais une rune) »* |
| **IV9** | §7.1, Rempart | *Percée* — *« coût 4 armure : 10 dégâts »* — sans coût en mana écrit ; la simulation l'a jouée à **0 mana** (rapport §3.12 la compte parmi les cartes à 0 mana, avec *Sang versé* et *Lacération*), et c'est ce que le lot veut (D50 : une carte à 0 mana qui coûte de l'armure n'est pas gratuite) | Rédaction | *« *Percée* — 0 mana, coût 4 armure : 10 dégâts »* |
| **IV10** | §11, graphe | Les trois lots de P-44 sont numérotés mais le graphe n'ordonne pas `P44a` avant `P44b` (`P05 → P44b → P44c` seulement) : lu seul, le lot 2 pourrait précéder le lot 1 | Rédaction, optionnel | Une arête `P44a --> P44b` |
| **IV11** | §8, D63 / D65 | **Signalé, sans action.** La référence a joué les neuf runes neuves dès l'acte 1 (D63 : poids 50, `minFusionRank` 1) ; sous D65, E2 n'en livre que trois, les six autres arrivent avec P-44 lot 1 et lot 3. L'état joué en E2 n'est donc pas celui mesuré — le **nombre** de runes par carte ne change pas (une par fusion), seul le choix se resserre ; le pool complet existe à la tranche 1, la livraison suivante. Pas de relance : §12 ligne 1 vise les *valeurs* de D56-D63 et D67, aucune ne bouge | À noter | Une phrase dans le paragraphe D65 de §8, pour que §12 ne soit pas lu comme enfreint |

### 13.3. Collatéraux — hors brainstorm

| Constat | Preuve | Destination |
|:---|:---|:---|
| Le rapport cite **« D8 »** pour l'échange 3 → 1 (§1.2, §3.5, §4) ; D8 est le catalogue, la ligne de l'échange n'est pas numérotée (S7, corrigé dans le brainstorm et ici, pas dans le rapport) | rapport §3.5, §4 | Rédaction du rapport : « §1, ligne « Plus tard » » |
| **§9 de cette revue** porte les chiffres d'or de la première passe (9 473 / 3 333 / 5 978) ; le brainstorm et la ligne P-16 citent la relance (9 100 / 3 358 / 5 596). `memory-bank-sync` lira l'une ou l'autre | rapport §7.2 | Ajouter la relance dans la ligne de §9, pour que la ROADMAP porte les chiffres à k = 2 |
| **Rien n'est commité** : le script, les trois documents, `CLAUDE.md` (§ Tooling) et `docs/INDEX.md` sont tous dans l'arbre de travail ; la ligne `_patterns/` de §12.3 attend `memory-bank-sync` ; `docs/INDEX.md` décrit la revue jusqu'à §12 et le brainstorm à « 67 décisions » — à mettre à jour avec les arbitrages de cette passe | `git status` | Un commit des six fichiers après les arbitrages ; INDEX à jour dans le même commit — ✅ **commité par lot et poussé sur `main` le 01/10** ; la fiche `_patterns/` reste à `memory-bank-sync` |

**Ce que la passe change à la préparation des lots.** **Rien ne bloque la spec E0** : D36 et D37 ne sont touchées par aucun constat. **Avant la spec E1, un arbitrage** : la frontière E1 / E2 (IV3) — elle décide si `minFusionRank`, « une rune par type » et la suppression de la capacité se livrent avec le moteur ou avec la fusion ; IV4 se règle dans la même spec, d'une ligne. IV2 est un arbitrage d'une ligne, sans conséquence sur E. Le reste — IV1, IV5 à IV11 — est de l'édition d'une demi-heure, à appliquer dans la même passe que les arbitrages, avec un D68 (et D69 si IV2(b)) dans §1, l'en-tête du brainstorm, et `docs/INDEX.md`. *État au 30/09, soir : arbitré — D68, Q4 gardée ouverte — et tout appliqué, rapport et INDEX compris.*

---

## Annexe A — Les 35 vérifications contre `3b8c66f`

Verdicts : ✅ exact · ⚠️ approximatif · ❌ faux.

| # | Affirmation du brainstorm | Verdict | Réalité |
|:---:|:---|:---:|:---|
| 1 | ADR-074, 078, 084, 086, 094, 097, 099, 101 existent et sont cités correctement | ✅ | Tous présents ; nuance sur ADR-097 (`strength → might` seulement, `strength_regen` renommé par `ad56024`) |
| 2 | `CardData.isOfferableTo` existe | ✅ | `card_data.dart:136-139` : `type != status && rarity.isAcquirable && (heroClass == null \|\| heroClass == heroClassId)` |
| 3 | Le draft de départ filtre `category == global` (`:57`) | ✅ | `starter_deck_draft_screen.dart:57` ; 5 cartes + 2 signatures d'office (`hero_skills_link.dart:6-13`) |
| 4 | `weakness` absent des données ; `vulnerable` posé par *Marque du Mage* | ⚠️ | `weakness` vide ✅ ; `vulnerable` posé par le code (`passive_strategies.dart:85`) ; **`might_regen` absent des données aussi** ; `armor_regen` : `metallicize.json` seul |
| 5 | Seul le boss offre des cartes (`reward_controller.dart:168-195`) | ✅ | `:168-184` (`BossRewardType.cards`, 5 clones), `:186-194` (`doubleXp`, carte bonus) |
| 6 | Aucun `"cost": 3`, `status`, `scaleWith` | ✅ | Trois greps vides |
| 7 | Collisions d'arrondi (base 3 → 3·4·4·5·6 ; base 4 → 4·5·6·6·8) | ✅ | Multiplicateurs 1,0 / 1,2 / 1,4 / 1,6 / 2,0 (`card_instance.dart:35-50`), arrondi `effect_resolver.dart:224` |
| 8 | Multiplicateur de rareté sur `draw` et `gain_mana` | ✅ | `effect_resolver.dart:222-224` ; `concentration` épique + `quick:2` = 5 |
| 9 | `weakness` / `vulnerable` / `freeze` lus en booléens | ✅ | `damage_pipeline.dart:15-18` (× 0,75), `:46-49` (× 1,5) ; `freeze` : effet réel dans `enemy_instance.dart:28-29` |
| 10 | `RuleMode { convert }` ; `mightTargets` ; `RewardEffect { stat, cloneCard }` | ✅ | `stat_rule.dart:12`, `hero_data.dart:43`, `level_up_reward_data.dart:7-11` |
| 11 | Trois chemins de pioche par `_drawInto`, arrêt à `maxHandSize = 10` | ✅ | `strategies.dart:147`, `effect_resolver.dart:168`, `turn_phase_manager.dart:38-57`, `deck_controller.dart:200`, `game_constants.dart:36` |
| 12 | `RewardController.handleVictory` | ✅ | `reward_controller.dart:75-82` |
| 13 | `cardsPerTurn` dans `RunState`, `scholars_satchel` via `applyRunRuleModifier :102` | ✅ | `run_controller.dart:41`, `player_stats_manager.dart:102-108` — **mais** ADR-078 D3 refuse `maxHandSize` en stat |
| 14 | `_rules/02-1` : proportions, étages, actes, `forgeFusion` | ⚠️ | Distribution sur les étages 1-4 et 6-7 seulement ; **aucune règle ne fixe un nombre d'actes** ; `forgeFusion` = 25 % **par carte**, un seul nœud ; « Level Up différé » est dans `03-10` |
| 15 | `CardRarity.next` : 4 fusions ; `mythic` ? | ✅ | `card_data.dart:22-28` ; pas de `mythic` dans `CardRarity`, seulement dans `RewardPool` |
| 16 | `forgeSlotBonus` 0/1/2/3/4 ; `baseMaxForgeUpgrades` | ✅ | `card_data.dart:33-39` ; défaut 1, signatures 5 |
| 17 | Les 8 runes, `quick` / `eco`, `switch` en dur, `valueMultiplier` affichage seul | ✅ | `effect_resolver.dart:142-174` ; `eco` = **+k mana à la pose** ; `valueMultiplier` lu par `card_text_renderer.dart:106` et `forge_upgrade_data.dart:88` |
| 18 | `forgeUpgrades` en `id:tier` ; `mergeCards` ; `ForgeUpgradeDialog` ; `forgeSlots` / `forgeTargetCardId` | ✅ | `card_instance.dart:8`, `deck_controller.dart:288`, `forge_upgrade_dialog.dart:32`, `run_controller.dart:32-33` |
| 19 | `ForgeRuneRules.consolidate`, `fusionOptionsFor`, `ForgeFusionScreen` | ✅ | `forge_rune_rules.dart:46-78`, `forge_fusion_screen.dart` |
| 20 | Miroir mythique 1 parmi 3 ; boss 5 clones ; miroir de boutique payant | ✅ | `mirror.json`, `reward_controller.dart:175`, `shop_controller.dart:341-355` |
| 21 | Repos 30 % PV ; trois options | ✅ | `rest_screen.dart:29`, `_rules/03-7` |
| 22 | Signatures évoluant aux niveaux 5, 10, 15… 40-50 | ❌ | Courbe `100 × 1,5^(n−1)` : L10 ≈ 7 500 XP, L15 ≈ 58 000, L20 ≈ 443 000 — voir E2 |
| 23 | `wisdom.json` ; palier manquant refusé (`:277`) ; 5 reliques de mana ; 25 reliques | ✅ | `values` 1/2/2/3/4 ; `FormatException` sur palier manquant en pool `draft` ; les 5 sont les seules à `gain_mana` |
| 24 | `EntitySource('classes/*/cards/*.json')` injecte `heroClass` ; pas de `cards/*/*.json` ; `referential_integrity_test` | ✅ | `game_data_service.dart:76-89` |
| 25 | `CardCategory { global, characterSpecific }` ; `PassiveData.classes` liste ; `availablePassivesFor` | ✅ | `card_data.dart:7`, `passive_data.dart:105`, `passive_availability.dart:18` |
| 26 | Plafond de 5 ennemis actifs | ✅ | `_rules/02-6:29`, `combat_controller.dart:89`, `encounter_system.dart:266-268` |
| 27 | Puissance : bonus par effet et par cible ; double bonus `burn` + `burning` ; élémentaires `attack` seul | ✅ | `power_rules.dart:17-32`, `strategies.dart:49,166-167`, `effect_resolver.dart:177,181-184,204-205` |
| 28 | Remise à zéro de l'armure | ✅ | **Début** du tour joueur, `run_controller.dart:452-460` (capture `survivingArmor` avant) |
| 29 | `tutorial_fixtures.dart:17-19` ; `tutorial_engine.dart:451` | ✅ | `strike_basic`, `defend_basic`, `fireball` ; `:451` = `mergeCards()` du tutoriel |
| 30 | `RunState.activePassive` ; choix à la sélection | ✅ | `run_controller.dart:31`, `class_selection_screen.dart:317,377,695-697` |
| 31 | `currentCost` ; `calculate(attackerStats)` ; `_payLifesteal :63` ; branche `allEnemies` ; `HealEffectStrategy` crit `:94` | ⚠️ | Tout exact sauf `_payLifesteal` : défini `:69`, appelé `:61` |
| 32 | `canPlayCard :104` ; `addCardToDiscardPile` ; pas d'`addCardToHand` ; `IntentType` ; `resolve` synchrone ; `power_rules.dart:31` | ✅ | `effect_resolver.dart:104-106`, `deck_controller.dart:374`, `enemy_intent.dart:1`, `effect_strategy.dart:9-19`, `power_rules.dart:31` |
| 33 | Libellés ROADMAP P-42/43/44/18/16/13/49/50 | ⚠️ | P-18 déjà « entièrement redistribué » (`:465`) ; P-50 n'existe pas (proposé par la revue du 10/09) |
| 34 | « lot du passif (6-8) » ; neutres non citées | ✅ confirmé | D16 dit 5-6 ; `awakening` et `focus` absentes ; *Méditation* = `concentration` |
| 35 | Autres | ⚠️ | « 1187 tests » non re-mesuré ; `smite.json` conforme à l'esquisse §4.4 ; 9 passifs, 23 cartes, `demon_form` / `warcry` / `metallicize` / `iron_wall` conformes |

---

## Annexe B — Le sort des 23 cartes actuelles, et les doublons du §7

Ce que le brainstorm dit de chaque carte, et ce qu'il laisse ouvert. À trancher par le propriétaire ; les décisions seront reportées dans le brainstorm.

### B.1. Les 17 neutres

| # | Carte | Aujourd'hui | Sort dans le brainstorm | À trancher ? |
|:---:|:---|:---|:---|:---|
| 1 | `strike_basic` | 1, Attaque : 6 | Gardée neutre (§7.4). Id du tutoriel | Non |
| 2 | `defend_basic` | 1, Compétence : 5 armure | Gardée neutre (§7.4). Id du tutoriel | Non — mais *Rune de garde* (Voile) la duplique, voir B.3 |
| 3 | `quick_attack` | 1, Attaque : 3 + pioche 1 | Gardée neutre (§7.4) | Non |
| 4 | `heavy_strike` | 2, Attaque : 12 | Gardée neutre (§7.4) | Non |
| 5 | `sweep` | 1, Attaque, tous : 3 | Gardée neutre (§7.4) | Non |
| 6 | `iron_wall` | 2, Compétence : 10 armure | Gardée neutre (§7.2, §7.4) : chez le Berserker *« +10 Puissance ce tour, et c'est bien »* | Non — mais c'est la carte du risque R3 (+10 Puissance **par coup** sous multi-coups), et *Muraille* (Rempart, 9 armure) lui est inférieure, voir B.3 |
| 7 | `concentration` | 0, Compétence, épuise : pioche 2 | Gardée neutre (§7.4) | **Oui** — *Méditation* (Voile) est la même carte (I7) : garder `concentration` neutre et retirer *Méditation*, ou la déplacer dans Voile et la retirer du noyau |
| 8 | `heal_potion` | 1, Compétence, épuise : soigne 3 | Gardée neutre (§7.1, §7.4) | Non |
| 9 | `fireball` | 2, Attaque : 6 + Brûlure 2 | Migre vers **Marque** (§7.3). Id du tutoriel — conservé, seul le dossier change | Non, sous réserve de Q12 (elles restent des Attaques) |
| 10 | `ice_bolt` | 1, Attaque : 4 + Gel 1 | Migre vers **Marque** | Non (Q12) |
| 11 | `thunder_clap` | 1, Attaque : 4 + Choc 1 | Migre vers **Marque** | Non (Q12) |
| 12 | `poison_stab` | 1, Attaque : 3 + Poison 1 | Migre vers **Marque** | Non (Q12) |
| 13 | `metallicize` | 1, Pouvoir : `armor_regen` 2, 2 tours | Migre vers **Sanctifié** (§7.1) | Non |
| 14 | `demon_form` | 2, Pouvoir : Puissance 2, 4 tours | *« Survit dans Sang et Carnage »* (§7.2) — la phrase ne dit pas laquelle va où ; par sous-thème, **Sang** (« Puissance qui dure ») | **Oui** : confirmer Sang |
| 15 | `warcry` | 2, Attaque, tous : 4 + 4 armure | Même phrase — par sous-thème, **Carnage** (AoE) | **Oui** : confirmer Carnage |
| 16 | `awakening` | 1, Compétence : 4 armure + pioche 1 | **Nulle part** (I6) | **Oui.** (a) neutre — bonne carte générique, +4 Puissance et un cantrip chez le Berserker ; (b) **Sang** — *Garde brisée* (1, Compétence : 6 armure + pioche 1) est `awakening` à +2 : soit `awakening` devient *Garde brisée* (re-valuée), soit *Garde brisée* disparaît ; (c) supprimée |
| 17 | `focus` | 0, Compétence, épuise : +1 mana | **Nulle part** (I6) | **Oui.** C'est le prototype de « carte à 0 qui rend du mana » (D11 ; G2 : à l'épique elle rend 2). (a) supprimée — la plus cohérente avec D11 et P3 ; (b) re-valuée à 1 mana (« +2 mana, épuise » : neutre pour le tour, mais compte pour Flux de Mana et Canalisation) ; (c) gardée comme unique carte à 0 du noyau — mais `concentration` occupe déjà cette place |

### B.2. Les 6 signatures

> *30/09 : D49 les sort des cartes — compétences de classe à recharge. La colonne « Sort » vaut pour leurs évolutions, plus pour leur forme.*

| Carte | Aujourd'hui | Sort (D7, D19) | À trancher ? |
|:---|:---|:---|:---|
| `holy_shield` | 1, Compétence, épuise : 8 armure + soigne 2 | Reste, perd `baseMaxForgeUpgrades: 5`, gagne `evolutions` | Non |
| `smite` | 1, Attaque : 6 + 4 armure | Idem — esquisse en §4.4 | Non — *Riposte* (Croisé, 5 + 4 armure) en est la version commune, voir B.3 |
| `reckless_strike` | 2, Attaque : 15 | Idem | Non |
| `rage_form` | 1, Compétence : Puissance 2 ce tour + pioche 1 | Idem | Non |
| `magic_missile` | 1, Attaque : 5 + pioche 1 | Idem | **Oui** : une Attaque chez un Mage dont la Puissance ne frappe que par Compétence (R6) — ses évolutions doivent pouvoir en changer le type, ou la carte devenir une Compétence |
| `mana_surge` | 0, Compétence, épuise : +1 mana + pioche 1 | Idem | **Oui** : une carte à 0 qui rend du mana, hors de tout lot — la règle de §5 (*« au plus une carte à 0 par lot »*) ne la voit pas. La compter dans le budget des cartes à 0 du Mage, ou la passer à 1 mana |

### B.3. Les cartes proposées au §7 qui doublonnent une carte existante, ou sont dominées par elle

| Carte proposée (lot) | Carte existante | Rapport | À trancher |
|:---|:---|:---|:---|
| *Méditation* — 0, Compétence, épuise : pioche 2 (Voile) | `concentration` | **Identique** | Une des deux |
| *Rune de garde* — 1, Compétence : 5 armure (Voile) | `defend_basic` | **Identique** | Une des deux, ou différencier *Rune de garde* (par exemple 4 armure + Puissance 1 ce tour) |
| *Garde brisée* — 1, Compétence : 6 armure + pioche 1 (Sang) | `awakening` (4 + pioche 1) | La même carte à +2 armure | Voir `awakening`, B.1 |
| *Muraille* — 2, Compétence : 9 armure (Rempart) | `iron_wall` (2, 10) | **Dominée** par une neutre du même coût | Re-valuer (11-12), ou lui donner ce qu'`iron_wall` n'a pas (« l'armure survit ce tour », `retain`) |
| *Morsure* — 1, Attaque : 4 (Vampire) | `strike_basic` (1, 6) | **Dominée** : Soif de Sang s'arme sur n'importe quelle Attaque, *Frappe* draine autant et frappe plus fort | Re-valuer, ou lui donner ce que *Frappe* n'a pas (pioche ; multi-coups quand P-44 arrive) |
| *Riposte* — 1, Attaque : 5 + 4 armure (Croisé) | `smite` (1, 6 + 4, signature) | Version commune de la signature, à −1 dégât | Acceptable si voulu ; sinon différencier (armure d'abord, dégâts égaux à l'armure gagnée) |
| *Éclat* — 1, Compétence, ennemi : 5 (Arcaniste) | `strike_basic` (1, 6) | −1 dégât pour le type Compétence : justifié chez le Mage, dont la Puissance frappe par Compétence | Non |
| *Onde* — 2, Compétence, tous : 4 (Arcaniste) | `sweep` (1, tous : 3) | +1 dégât pour +1 mana : faible hors Puissance du Mage | À surveiller en simulation |

### B.4. Décisions du 29/09, appliquées au brainstorm

| Carte | Décision | Pourquoi |
|:---|:---|:---|
| `awakening` | **Neutre, gardée** ; citée en §7.2 comme batterie du Berserker | Bonne carte générique pour les trois classes ; D17 veut que la classe *lise* la neutre plutôt que le lot la recopie |
| *Garde brisée* (Sang) | **Retirée** | C'était `awakening` à +2 armure |
| `focus` | **Supprimée** | Prototype de la carte à 0 qui rend du mana (D11, G2 : +2 à l'épique) ; `concentration` occupe déjà la place de la carte à 0 du noyau ; P3 refuse le mana hors chaîne |
| `concentration` | **Neutre, gardée**, la carte à 0 du noyau | *Méditation* est différenciée, plus de doublon |
| *Méditation* (Voile) | **Redéfinie** : 1, Compétence, épuise, `mana_regen` 1 pendant 2 tours | Cohérente avec son nom ; à 1 mana pour respecter la règle des deux cartes à 0 du Mage ; moteur : un statut `mana_regen` sur le modèle de `might_regen` |
| *Rune de garde* (Voile) | **Retirée** | C'était `defend_basic` ; la neutre joue le rôle |
| `demon_form` | **Sang** | Sous-thème « Puissance qui dure » |
| `warcry` | **Carnage** | Sous-thème AoE ; son armure devient +4 Puissance |
| `mana_surge` | **Reste à 0 mana**, compte comme la carte à 0 du Mage hors noyau | La règle de §5 en tient compte : aucun lot du Mage n'a de carte à 0 |
| `magic_missile` | **Devient une Compétence** | La Puissance du Mage frappe par ses Compétences ; première Compétence de dégâts du jeu |
| *Muraille* (Rempart) | **12 armure** pour 2 | À 9 elle était dominée par `iron_wall` (10) ; 6 armure par mana est la prime d'un lot |
| *Morsure* (Vampire) | **4 dégâts + pioche 1** pour 1 ; *Curée* passe à 8 + pioche 1 pour 2 | À 4 secs elle était dominée par `strike_basic` ; Vampire = Attaques à 1 qui piochent |
| *Riposte* (Croisé) | **3 dégâts + 5 armure** pour 1 | Penchée vers l'armure pour ne pas doubler `smite` (6 + 4) ; Ferveur veut de l'armure frappée |
| Les 12 autres | **Sans changement** : 8 neutres gardées, 4 élémentaires vers Marque, `metallicize` vers Sanctifié, 4 signatures inchangées | — |

---

*Revue close le 30/09 : §6 appliqué, §7, §8 et §10 arbitrés (D22 à D49 du brainstorm). Q19 et Q20 sont tranchées le 30/09 (D48, D49) ; aucune question bloquante ne reste. Seconde passe de cohérence le même jour (§11, D50 à D55), puis la simulation de D26 ([rapport](30-09-2026_simulation_D26_economie_Fable5.md)), dont les six contradictions et les valeurs recommandées sont arbitrées en D56 à D64 — trois constats collatéraux routés vers P-16 (§9). Le chantier E est découpé en cinq lots (brainstorm §11). Troisième passe de cohérence le même jour (§12), après D56-D64 : la propagation tient ; les trois arbitrages qui restaient — le lot des runes de §8 (T3), la destination de six décisions (T4), la calibration d'XP à k = 2 (T1) — sont pris le soir même (D65 à D67) et tout est appliqué. Quatrième passe de cohérence le même jour (§13), en session neuve, après D65-D67 : la propagation tient ; onze constats, dont un arbitrage pour la spec E1 — la frontière E1 / E2 (IV3) — et un pour Q4 (IV2) — arbitrés le soir même (D68 ; Q4 reste ouverte) et tout appliqué. Prochaine étape : la spec de E0, puis de E1, chacune dans une session neuve.*
