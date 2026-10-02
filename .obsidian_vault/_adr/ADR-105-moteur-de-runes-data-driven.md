---
description: Runes become pure data — a typed list of card deltas applied by one shared applicator, a single eligibility predicate with symmetric exclusions, and a per-rune maxLevel bounded at every place a level is written; rarity growth always adds at least 1 except on draw and mana; amends ADR-094 and completes ADR-061
---

# ADR-105 — Le Moteur de Runes Data-Driven : des Deltas Typés, un Applicateur, un Prédicat et un Plafond

### Statut

✅ Accepté — 2026-10-02 (P-43, lot **E1** ; brainstorm v3, décisions D4, D27, D28, D33, D44, D51,
D61, D68, D72 et D75, et les propositions G1 et G2 de son §4.5). **Livré sur la branche
`feat/v0.5.3-p43-e0-e1` — vague 1 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Spec `229bce6`, plan
`5bd2f10`, huit commits de code `ae939e6`..`633fe24` et un correctif de la revue d'ensemble,
`ee814e9`.
**Amende [ADR-094](ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)** sur ses
décisions D1, D3, D4 et D5 ; **complète [ADR-061](ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md)** ;
livre la décision D4 d'[ADR-104](ADR-104-un-statut-par-source-et-ratio-de-conversion.md).
Conception : [spec E1](../../docs/superpowers/specs/2026-10-02-p43-e1-moteur-de-runes-design.md),
[plan](../../docs/superpowers/plans/2026-10-02-p43-e1-moteur-de-runes.md) ; arbitrages et décisions
d'exécution au
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md),
§2.4 à §2.6.

### Contexte

Une rune était un fichier pour son nom, son poids et ses types de carte, et du Dart pour tout le
reste. Son effet vivait dans un `switch` par id d'`EffectResolver` ; les runes élémentaires avaient
un bloc à part, qui **concaténait** leurs statuts à la liste de l'ennemi ; la formule « +2 par
niveau » était écrite à six endroits et le multiplicateur de rareté calculé à huit, dont deux dans
le tutoriel ; l'épuisement testait l'id `'enduring'`. L'éligibilité se réduisait au type de carte
écrit en ligne dans deux tirages, qui retombaient sur `sharp` sans regarder rien. Aucun plafond de
niveau n'existait : `eco:3` ou `freezing:3` s'obtenaient au feu, en boutique ou par fusion. E2
(la fusion qui propose une rune) a besoin d'un moteur qui sache appliquer **n'importe quelle** rune
décrite en donnée : D68 met ce moteur dans E1, sans changer la boucle de jeu.

### Décision

**D1 — Une rune déclare son effet par une liste typée de deltas** *(A1)*. Clé `deltas`
obligatoire, vocabulaire fermé `CardDelta` à trois sortes :

| `type` | Au niveau L | Runes |
|:---|:---|:---|
| `percentBonus` (`effect`, `valuePercentPerLevel`) | Chaque effet **propre** de ce type gagne `max((p × L × B + 50) ~/ 100, L)`, B = sa valeur à la rareté de la carte | `sharp` (dégâts, 15), `hardened` (armure, 15) |
| `addEffect` (`effect`, `valuePerLevel` ; `statusId` et `durationPerLevel` pour `apply_status`) | Ajoute un effet, résolu **avant** ceux de la carte, ni multiplié par la rareté ni visé par un pourcentage | `quick`, `eco`, `burning`, `freezing`, `shocking` |
| `removeExhaust` | La carte ne s'épuise plus, quel que soit L | `enduring` |

Une sorte neuve est du Dart **une fois par mécanisme**, jamais un `case` par rune. **La couture des
évolutions de signature** (vague 5) : `EffectiveCard.apply(carte, rareté, paires (delta, niveau))` ;
`runeDeltas` traduit les runes d'une carte en paires, exemplaires d'un même id additionnés.

**D2 — Les effets ajoutés passent par le registre de stratégies** *(A2)* — le résolveur n'a plus
aucun code de rune. Les statuts des runes sont posés par `ApplyStatusEffectStrategy`, donc par
`addStatus`, sans source (ADR-104 D4). `GainSource.rune` perd ses producteurs et disparaît.

**D3 — Le code au modèle, le prédicat dans `ForgeRuneRules`** *(A3)*. `CardDelta`
(`lib/models/data/card_delta.dart`), `EffectiveCard` (`lib/models/effective_card.dart`), la borne
`boundLevel` et l'analyseur unique `parseRef` / `levelsOf` sur `ForgeUpgradeData` ;
`ForgeRuneRules.isEligible`, fonction pure, à côté de `consolidate` et `fusionOptionsFor`.

**D4 — Les textes de runes viennent de leur fichier** *(A4)* : nom, description et emoji lus dans
la donnée, chiffres sur l'applicateur, aux trois infobulles, à la forge et aux prises de rune. Une
ligne par id, au niveau total des exemplaires ; le niveau s'écrit quand `maxLevel` n'est pas 1.

**D5 — G1 : chaque fusion augmente d'au moins 1 tout chiffre que la rareté multiplie** *(A5)* —
dégâts, armure, soin, statuts. `CardRarity.scaleValue` : à chaque palier,
`v = max(round(base × multiplicateur), v + 1)`. **G2** : `draw` et `gain_mana` gardent la valeur de
la donnée. **G1 s'arrête aux effets gelés** *(A6)* : *Concentration* ne gagne à la fusion que sa
rareté.

**D6 — La base du pourcentage est la valeur à la rareté de la carte, sur le niveau total des
exemplaires, en arithmétique entière, demie vers le haut** *(A7)* — la formule que la simulation
joue, sans son erreur de flottant.

**D7 — `maxLevel`, clé obligatoire, `null` = sans plafond** *(A8)* : 1 pour `eco`, `quick`,
`freezing`, `enduring` ; `null` pour `sharp`, `hardened`, `burning`, `shocking`. **Une fonction,
`boundLevel`, borne les quatre endroits qui écrivent un niveau** (D72) — la fusion de cartes
`consolidate`, la Forge de Fusion `fusionOptionsFor`, le tirage du feu, celui des pré-forgées — et
sert le prédicat (D75). La fusion de cartes **borne** la somme, le surplus se perd *(A9)* ; la Forge
de Fusion **ne propose pas** une fusion qui perdrait un niveau *(A10)*.

**D8 — Le prédicat d'éligibilité** (D44, D51, D61, D75). Vrai si et seulement si : le type de carte
est admis (`eligibleCardTypes`) ; un effet **propre** de la carte est visé (`eligibleEffects`) ;
aucun n'est exclu (`excludesEffects`) ; `requiresExhaust` ; `currentCost ≥ requiresMinCost` ;
**aucune exclusion de rune, dans un sens ou dans l'autre** (`excludesRunes`) ; et **le plafond n'est
pas atteint**, exemplaires additionnés. `pools` n'en est pas une condition : c'est le ciblage par
rareté des tirages, qui le gardent jusqu'à E2. Ses trois lecteurs : la forge du feu, la boutique,
la sélection du feu. **Le feu refuse à la sélection une carte sans rune éligible**, avec le message
`forgeNoEligibleRune` *(A11)* ; **une pré-forgée à qui ne reste aucune rune éligible en reçoit
moins** *(A12)* — le repli sur `'sharp'` disparaît des deux tirages.

**D9 — Le vocabulaire des types d'effet est celui du disque** *(A13)* : motifs d'éléments
`eligibleEffects[]`, `excludesEffects[]`, `deltas[].effect`, `deltas[].statusId` ; `vocabularyOf`
lit, pour un motif `clé[]`, les valeurs que `knownValues` range sous la clé nue ; `deltas[].type`
est lu sur `CardDelta.typeNames` ; `excludesRunes` est une liste de références. Un test d'intégrité
vérifie que chaque type nommé par une rune livrée a sa stratégie.

**D10 — La fusion de cartes n'assemble jamais deux runes qui s'excluent** *(constat de la revue
d'ensemble, E-S3, correctif `ee814e9`)*. Trois *Potions de Soin* portant *Persistant*, *Économe* et
rien donnaient une carte qui rend du mana sans s'épuiser — le moteur que D44 et D51 ferment,
atteignable en partie neuve. `consolidate` écarte une rune exclue par une rune gardée avant elle,
**symétriquement**, en lisant `excludesRunes` dans la donnée ; **la première arrivée est gardée**.
**L'héritage d'E2 (D13), qui garde toutes les runes, devra suivre la même règle.**

**Ce que ces décisions font à ADR-094** — il ne change que de Statut :

| Décision d'ADR-094 | Amendée ainsi |
|:---|:---|
| D1 | `CardRarity.forgeSlotBonus` devient **`fusionRank`**, mêmes valeurs (0 à 4, 0 pour `unique`), et gagne un second lecteur, G1 ; `CardRarity.multiplier` reprend la table de `CardInstance.rarityMultiplier`, supprimé |
| D3 | `stackable` reste jusqu'à E2, avec ses seuls lecteurs ; `maxLevel` le double et borne quatre écritures. « Non cumulable ⇒ affichée sans tier » ne vaut plus que pour la fente de la forge et le dialogue de fusion : les infobulles écrivent le niveau selon `maxLevel` |
| D4 | `exhaustsOnPlay` lit l'applicateur (`removesExhaust`), plus l'id `'enduring'` |
| D5 | `ForgeRuneRules` gagne le prédicat d'éligibilité ; la borne vit sur `ForgeUpgradeData`, et l'analyseur unique de niveau passe au modèle |
| Conséquence « textes de runes codés en dur par id » | Close (D4 ci-dessus) |

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Les sortes de delta | `lib/models/data/card_delta.dart` — `CardDelta`, `typeNames` |
| L'applicateur | `lib/models/effective_card.dart` — `apply`, `runeDeltas`, `withRunes` ; `CardInstance.effective`, `exhaustsOnPlay` |
| G1, G2, `fusionRank` | `lib/models/data/card_data.dart` — `fusionRank`, `multiplier`, `scaleValue` |
| Le modèle de rune, la borne, l'analyseur | `lib/models/data/forge_upgrade_data.dart` — `boundLevel`, `parseRef`, `levelsOf`, `tooltipLines` |
| Le prédicat, la fusion bornée et sans paire exclue | `lib/game/services/forge_rune_rules.dart` — `isEligible`, `consolidate`, `fusionOptionsFor` |
| La résolution | `lib/game/services/effect_resolver.dart` — `resolveCard` : `addedEffects` puis `effects` |
| Les tirages et le refus | `lib/ui/widgets/forge_upgrade_dialog.dart`, `lib/game/controllers/shop_controller.dart`, `lib/ui/screens/rest_card_selection_screen.dart` |
| Les rendus | `card_text_renderer.dart`, `card_component.dart`, `ui_card.dart`, `ui_card/ui_card_helpers.dart`, `ui_card/card_compact_description.dart`, `forge/forge_slot_row.dart`, `forge/forge_card_preview.dart` ; le tutoriel |
| L'éditeur | `lib/services/content_editor/entity_descriptor.dart`, `known_values.dart` |
| La donnée | les huit fichiers de `assets/data/forge_upgrades/` |
| Tests neufs | `test/unit/forge_upgrade_data_test.dart`, `rune_eligibility_test.dart`, `effective_card_test.dart`, `forge_upgrades_catalog_test.dart` (un test par rune et la matrice de l'offre), `rune_resolution_test.dart`, `rune_ids_in_code_test.dart` (aucun id de rune livrée ni `rarityMultiplier` dans `lib/`) ; `test/widget/forge_upgrade_dialog_test.dart`, `rest_card_selection_screen_test.dart`, `ui_card_values_test.dart` |

### Conséquences

- ✅ **Une rune neuve d'un mécanisme existant est un fichier.** `cheap` (E2) tiendra dans
  `requiresMinCost` et `excludesRunes` sans code d'éligibilité.
- ✅ **Le joueur voit le chiffre que le moteur joue**, partout : une ligne par rune, au niveau total.
- ✅ **Changements de jeu, annoncés par la note de version de la vague** : *Tranchant* et *Endurci*
  à +15 % de la base, au moins +1 (sur *Frappe*, +1 au lieu de +2) ; *Endurci* seulement sur une
  carte d'armure — sur une autre, elle donnait une Armure à part, invisible ; plus d'*Économe* sur
  une carte gratuite, ni de *Persistant* sur une carte qui pioche ou rend du mana, ni avec *Économe*
  ou *Véloce* ; `eco`, `quick`, `freezing`, `enduring` jamais au-delà du niveau 1 ; G1 et G2
  (*Coup Empoisonné* légendaire 7 dégâts et 5 Poison au lieu de 6 et 2 ; *Concentration* légendaire
  pioche 2 au lieu de 4) ; les statuts de *Brûlant* et *Surchargé* se fondent dans ceux que la
  cible porte, le choc d'une rune compte enfin ; *Économe* fait entendre le son du gain de mana.
- ⚠️ **L'éligibilité des runes élémentaires ne lit pas la cible de la carte.** Leurs statuts
  passent par la stratégie, qui lit la cible : une Attaque `target: self` portant une rune
  élémentaire poserait le statut sur le héros. Aucune carte livrée ne l'est, mais l'éditeur permet
  d'en écrire une. À trancher par une **condition de cible en donnée** quand un contenu le rendra
  possible — la spec en prévoit déjà une pour `splash`, en vague 5.
- ⚠️ **Reste pour E2** : une relance payante de la forge du feu ne peut rien changer sur les cartes
  à une seule rune éligible (*Concentration*, *Focalisation*, *Surtension de Mana*, qui n'acceptent
  que *Véloce*) — E2 supprime la forge du feu ; les descriptions des runes à effet ajouté écrivent
  leur niveau, pas la valeur que joue l'applicateur — identiques pour les huit runes livrées, une
  unité par niveau, faux pour une rune future à deux unités par niveau ; la première fusion d'une
  *Concentration* n'aura aucune rune éligible sous le prédicat d'E2.
- ⚠️ **Les cartes communes sans dégâts ni armure se voient proposer au feu *Véloce*, *Économe* ou
  *Persistant*** : leur pool `common` est vide sous le prédicat, et le repli préexistant de la forge
  descend aux autres pools. C'est ce qui rendait D10 atteignable.
- ⚠️ **Non planifié** : le badge « Usage unique » et les particules d'épuisement ignorent toujours
  *Persistant* (ADR-094, Conséquences) ; l'emoji d'une rune et la fente de la forge lisent encore
  `id:niveau` à la main — affichage, hors de la règle « un seul analyseur ».
