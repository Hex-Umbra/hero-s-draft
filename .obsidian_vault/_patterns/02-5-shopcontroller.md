### 2.5. `ShopController` (`shopProvider`)

**Provider** : `NotifierProvider<ShopController, ShopState>`

**État (`ShopState`) — l'étal**, tiré une fois par nœud de boutique et retenu, achats compris,
jusqu'à ce que le nœud courant de la run change ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md),
P-43 E2, branche de la vague 2, en attente du propriétaire) :
- `cardsForSale` : `List<CardInstance>` — les cartes en vente, pré-forgées et relancées comprises.
- `purchasedHeal` : `bool` — le soin unique du nœud est-il acheté.
- `cloneOptions` : `List<CardInstance>` — les trois choix du Miroir Magique, tirés à sa première ouverture.
- `clonePurchasedCount` : `int` — les achats au Miroir ; getter `clonePrice` = $150 \ll \text{clonePurchasedCount}$ ($150 \rightarrow 300 \rightarrow 600 \dots$ Or).
- `deckCopy` : `CardInstance?` — la copie d'une carte du deck, `null` sans carte copiable ou une fois achetée.
- `nodeId` : `String?` — le nœud courant de la run pour lequel l'étal a été tiré.

> [!IMPORTANT]
> **Le seul Notifier de `lib/game/controllers/` qui écoute un autre provider.** `build()` pose
> `ref.listen(runProvider.select((run) => run.currentNodeId), …)`, qui remet l'état à
> `const ShopState()` dès que le nœud courant change — départ vers un autre nœud, acte, run neuve,
> sauvegarde chargée. Rentrer dans le même nœud ne le change pas. **Pas `ref.watch`** : il laisse
> le Notifier périmé entre le changement de nœud et la lecture suivante de `state`, et tout
> `ref.read` de ses méthodes y lève l'assertion de Riverpod « Cannot use ref functions after the
> dependency of a provider changed ». L'étal retenu est un instantané : la copie et les options du
> Miroir ne suivent pas un deck qui change dans le même nœud. Il ne se sauvegarde pas.

**Responsabilités & Logique métier** :
- `initializeShop(allCards, bonusShopCards)` : appelé à chaque création de `ShopScreen`. **Ne fait
  rien si `state.nodeId` égale le nœud courant non nul** — l'écran rend alors l'étal retenu. Sinon,
  tire `3 + bonusShopCards` cartes proposables (`CardData.isOfferableTo`,
  [ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md)) scalées par
  l'acte, la copie du deck, et note le nœud. Sans nœud courant — les tests unitaires —, chaque appel
  tire.
- `_generateShopCardInstance(data, act, rng)` (privé) : la rareté finale, tirée plus haute selon
  l'acte, puis les runes : 15 % d'une à l'acte 2 ; dès l'acte 3, 30 % d'une et 10 % de deux —
  **bornées par `finalRarity.fusionRank`** (D28), une commune n'en porte aucune. Une carte à qui ne
  reste aucune rune éligible en reçoit moins.
- `_rollRandomUpgrade(card, rng)` (privé) : une rune par `ForgeRuneRules.drawRunes(card, catalogue,
  rng, count: 1)` — le tirage de la fusion, sur la carte **avec les runes déjà tirées**, au rang de
  la carte —, puis un niveau 1, 2 ou 3 à 80/15/5 %, **borné par `maxLevel`**. Une rune ne se repose
  jamais deux fois sur une même pré-forgée.
- `_drawDeckCopy(rng)` (privé) et `buyDeckCopy()` : la copie (D46) — une carte uniforme de
  `DeckState.copyableCards`, recréée `CardInstance(data, rarity)`, sans rune, identifiant neuf ;
  achetée au prix `getCardPrice` d'une carte sans rune de sa rareté, elle rejoint le deck et quitte
  l'étal.
- `buyCard(card, price)` : retire l'instance de l'étal, dépense l'or par `inventoryProvider`, ajoute
  l'instance exacte au deck.
- `cloneCard(card)` : duplique une carte des `cloneOptions` — runes et rareté comprises —, débite
  `clonePrice`, incrémente `clonePurchasedCount`. `setCloneOptions` retient les trois choix.
  **`clearCloneOptions` n'existe plus** : le Miroir repart avec tout l'étal, au nœud suivant (point
  5 d'[ADR-067](../_adr/ADR-067-equilibrage-de-l-economie-scaling-par-acte-des-car.md), amendé par
  ADR-106).
- `buyHeal(price, amount)` : soigne, débite l'or, marque `purchasedHeal`.
- `expandShop(price, allCards)` : une carte de plus, de façon permanente (`buyShopExpansion`).
- `rerollCards(price, allCards, bonusShopCards)` : remplace les cartes en vente dans l'étal retenu,
  sans toucher ni la copie ni le nœud — la copie est tirée, non choisie.
- `purgeCard(price, card)` : retire définitivement une carte du deck contre de l'or.

**Tarification dynamique (`getCardPrice(CardInstance card)`)** :
Calculé à la volée pour chaque carte exposée :
$$\text{Prix} = \text{BaseRareté} + (20 \times \text{nombre de runes})$$
- Base par Rareté : Commun (25 Or), Peu Commun (50 Or), Rare (100 Or), Épique (150 Or), Légendaire (200 Or).
- Surcoût : +20 Or par rune présente dans l'instance — la copie du deck, sans rune, coûte la base.
