### Statut

✅ **Livré le 2026-09-15**, P-40 bloc 2, branche `fix/p40-bloc-2` **fusionnée dans `main` le
2026-09-15 par la PR #37** (`dc15184`) — commits `b19b39a` à `9196a6e`,
corrections de la revue indépendante comprises, plus la réparation des cartes touchées par B5
(`71d97cb`), décidée le même jour par le propriétaire. **Amende** [ADR-025](ADR-025-systeme-de-forge-decouple-et-probabiliste.md)
(D1, formule de capacité) et **dépasse en partie**
[ADR-051](ADR-051-filtrage-des-cartes-de-rarete-unique-dans-les-reco.md) (le pool du draft de boss).
Conception : `docs/superpowers/specs/2026-09-15-p40-bloc-2-cartes-et-forge-design.md`.

### Contexte

Trois bugs relevés par l'état des lieux du 2026-08-05 (Partie III.B), re-vérifiés contre le code le
2026-09-15, plus un quatrième trouvé en les relisant :

| # | Symptôme | Cause |
|:---:|:---|:---|
| B4 | Une carte de classe porte 5 + 5 = 10 runes, au lieu des 5 fixes d'[ADR-026](ADR-026-isolation-des-cartes-de-classe-unique-et-standardi.md) D2 | `baseMaxForgeUpgrades + rarity.index`, et `unique` est déclarée **après** `legendary` |
| B5 | Trois légendaires fusionnent en une carte `unique` : multiplicateur 2,0 ramené à 1,0, plus jamais fusionnable | `min(index + 1, values.length - 1)` vaut `unique` au sommet |
| B2 | Le draft de boss et les deux Miroirs proposent de copier une carte de classe | Le filtre `unique` était écrit en ligne à chaque source, et les trois sources qui **copient depuis le deck** ne l'ont jamais reçu |
| B1 | Persistant cesse de retirer l'épuisement dès le tier 2 | `playCard` testait la chaîne exacte `'enduring:1'`, alors que la Forge de Fusion et la fusion 3→1 additionnent les tiers |

B4 et B5 viennent d'un même calcul, recopié dans neuf fichiers. B1 vient d'une propriété de la rune
(binaire, sans tier qui vaille) que rien ne modélisait : cinq comparaisons à `'enduring'` la
simulaient, et les trois algorithmes de cumul l'ignoraient. `_rules/03-8` affirmait déjà
`enduring` exclue de la fusion ; aucune ligne de code ne l'excluait.

### Décision

**D1 — `CardRarity` porte l'échelle.** `next` (rareté produite par une fusion 3→1 : `null` pour
`legendary`, sommet, comme pour `unique`, hors échelle) et `forgeSlotBonus` (0 à 4 le long de
l'échelle, 0 pour `unique`). La capacité ne se lit qu'à `CardData.forgeCapacityAt(rarity)` et
`CardInstance.forgeCapacity`. Toute montée de rareté passe par `next`, tirage de la boutique compris.
`index` ne sert plus qu'à l'affichage. `mergeCards` exige trois exemplaires d'une même carte à une
même rareté ; `DeckNotifier.upgradeCard`, sans appelant, est supprimée.

**D2 — `CardRarity.isAcquirable`**, faux pour `unique` seulement, est la règle d'acquisition en cours
de run. `DeckState.copyableCards` en est la liste pour les trois sources de copie ; les cinq sources
de cartes la lisent.

**D3 — Une rune se déclare non cumulable en donnée** : `ForgeUpgradeData.stackable`, vrai par défaut,
`false` dans `assets/data/forge_upgrades/enduring.json`. Non cumulable ⇒ tirée au tier 1, affichée
sans tier, jamais proposée par la Forge de Fusion, gardée une fois au tier 1 par une fusion 3→1.
**Une clé plutôt que l'id** : depuis P-30, l'éditeur de contenu crée des runes, et une rune binaire
créée depuis le jeu doit pouvoir le dire. Le gabarit de l'éditeur porte la clé.

**D4 — `CardInstance.exhaustsOnPlay`** est la seule règle d'épuisement : un pouvoir toujours, une
carte `isExhaust` sauf si elle porte `enduring`, **quel que soit le tier** — y compris après D3,
parce qu'une sauvegarde peut déjà contenir `enduring:2` ou `enduring:3`.

**D5 — `ForgeRuneRules`** (`isStackable`, `consolidate`, `fusionOptionsFor`) remplace les trois copies
du cumul — Forge de Fusion, fusion 3→1, dialogue de fusion — par une seule, qui connaît D3, avec un
seul analyseur de tier : une référence `id:tier` mal formée est ignorée partout.

**D6 — Une carte abîmée par B5 est réparée au chargement.** Dans `DeckState._decodePile`, une
instance `unique` dont le modèle ne l'est pas retrouve la rareté légendaire : seul B5 produit ce cas.
Sans D6, D1 aurait retiré à ces cartes leurs emplacements de rareté en plus de leur multiplicateur.

### Preuves dans le code

- `lib/models/data/card_data.dart` — enum `CardRarity` (`next`, `forgeSlotBonus`, `isAcquirable`),
  `CardData.forgeCapacityAt`.
- `lib/models/card_instance.dart` — `forgeCapacity`, `exhaustsOnPlay`.
- `lib/game/services/forge_rune_rules.dart` — `FusionOption`, `ForgeRuneRules`.
- `lib/game/controllers/deck_controller.dart` — `DeckState.copyableCards`, réparation de B5 dans
  `DeckState._decodePile`, garde de `mergeCards`, `playCard`.
- `lib/game/controllers/shop_controller.dart` — `_rollRarity` par `next`, tirage de tier par
  `isStackable`.
- `lib/ui/widgets/ui_card.dart` — `UiCard.forgeCapacity` : `getCardRarityIndex`, qui retrouvait l'index
  **à partir du libellé traduit** de la rareté, est supprimée.
- `lib/game/components/widgets/card_text_renderer.dart` — dessine `max(capacité, runes portées)`
  emplacements.
- Tests : `test/unit/card_rarity_test.dart`, `test/unit/forge_rune_rules_test.dart`,
  `test/widget/ui_card_rune_sockets_test.dart`, et des cas ajoutés à `deck_controller_test`,
  `deck_state_persistence_test`, `decoupled_forge_test`, `reward_controller_test`,
  `shop_controller_test`, `deck_screen_test`,
  `shop_screen_test`, `draft_screen_test`, `forge_fusion_screen_test`, `real_bundle_load_test`.
  La revue a vérifié que les tests de régression échouent sur `75d47f2`, chacun pour la raison prévue.

### Conséquences

- ✅ Une carte de classe porte **5 runes au plus** : affaiblissement réel, conforme à l'intention
  d'ADR-026. `_rules/03-8` (capacité fixe, exclusion de la fusion) devient vraie par le code.
- ✅ **Aucune migration**, `schemaVersion` inchangé : une carte en surcapacité garde ses runes et les
  montre toutes, en combat compris ; `enduring:2/3` redevient actif.
- ✅ Un calcul sur l'ordre de déclaration de l'enum est désormais une faute de relecture : les
  `switch` exhaustifs de `next` et `forgeSlotBonus` imposent une décision à toute rareté ajoutée.
- ✅ **Une carte neutre devenue `unique` par B5 redevient légendaire** en reprenant une partie (D6) ;
  les deux exemplaires que l'ancienne fusion avait consommés ne reviennent pas.
- ⚠️ **Hors périmètre, relevé en chemin** (spec §6) : le badge « Usage unique » et les particules
  d'épuisement ignorent Persistant ; un Miroir sans carte copiable échoue en silence ; les textes de
  runes restent codés en dur par id dans le rendu Flame.
