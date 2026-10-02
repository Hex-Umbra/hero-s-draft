### 2.5. `ShopController` (`shopProvider`)

**Provider** : `NotifierProvider<ShopController, ShopState>`

**État (`ShopState`)** :
- `cardsForSale` : `List<CardInstance>` — Liste des instances de cartes actuellement en vente dans la boutique.
- `hasBoughtHeal` : `bool` — Indique si le joueur a déjà acheté le soin unique de cette visite.
- `cloneOptions` : `List<CardInstance>` — Cache persistant anti-exploit contenant les 3 choix de cartes du deck éligibles au clonage.
- `clonePurchasedCount` : `int` — Nombre d'utilisations du Miroir Magique lors de la session courante.
- Getter `clonePrice` : Calcul du coût dynamique cumulatif du clonage ($150 \ll \text{clonePurchasedCount}$ soit $150 \rightarrow 300 \rightarrow 600 \rightarrow 1200 \dots$ Or).

**Responsabilités & Logique métier** :
- `initializeShop(allCards, bonusShopCards, act, rng)` : Filtre les cartes de type `status` et de rareté `unique`, puis génère un assortiment de `3 + bonusShopCards` instances de cartes (`CardInstance`) adaptées au scaling de l'Acte en cours. Réinitialise le compteur `clonePurchasedCount` à 0 et vide le cache `cloneOptions`.
- `_generateShopCardInstance(data, act, rng)` (privé) : Détermine procéduralement la rareté finale de la carte et ses améliorations de forge initiales :
  - *Rareté* : Probabilité accrue de raretés élevées (Rare, Épique, Légendaire) selon l'Acte.
  - *Améliorations* : À partir de l'Acte 2, tire une ou deux runes selon l'Acte (via `_rollRandomUpgrade`), dans la limite de la capacité de la carte ; **une carte à qui ne reste aucune rune éligible en reçoit moins** — le tirage s'arrête.
- `_rollRandomUpgrade(card, rng)` (privé) : Tire une rune pour une carte **qui porte déjà les runes tirées avant elle** : le prédicat `ForgeRuneRules.isEligible` les lit (exclusions, plafonds). Même ciblage de pool par rareté et même tirage pondéré par `weight` que la forge du feu ; niveau 1, 2 ou 3 à 80/15/5 % pour une rune cumulable, **borné par `maxLevel`**. Rend `null` quand rien ne s'offre : le repli sur `'sharp'` a disparu — [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md). Deux *Tranchant* restent possibles sur une pré-forgée : seules les runes plafonnées ne se reposent pas.
- `buyCard(cardInstance)` : Retire la `CardInstance` spécifique de la liste des cartes en vente, consomme l'or via `inventoryProvider` et ajoute l'instance exacte au deck du joueur.
- `cloneCard()` : Duplique la carte sélectionnée parmi les `cloneOptions` (avec les mêmes runes et niveau), débite `clonePrice` de l'or et incrémente `clonePurchasedCount` dans l'état de la boutique.
- `clearCloneOptions()` : Appelé en quittant la boutique, vide le cache `cloneOptions` et réinitialise `clonePurchasedCount` à 0 (réinitialisant le prix du Miroir Magique à sa valeur de base de 150 Or).
- `buyHeal()` : Restaure 30% des PV Max du héros, débite l'or et marque `hasBoughtHeal = true`.
- `expandShop()` : Augmente de manière permanente le nombre de cartes en vente, débitant l'or.
- `rerollCards(allCards, act, rng)` : Régénère un ensemble complet de `CardInstance` scalées pour l'Acte en cours, pour un coût d'or progressif.
- `purgeCard(card)` : Supprime définitivement une carte du deck en échange d'un coût fixe en or.

**Tarification dynamique (`getCardPrice(CardInstance card)`)** :
Calculé à la volée pour chaque carte exposée :
$$\text{Prix} = \text{BaseRareté} + (20 \times \text{nombre d'upgrades de forge})$$
- Base par Rareté : Commun (25 Or), Peu Commun (50 Or), Rare (100 Or), Épique (150 Or), Légendaire (200 Or).
- Surcoût de Forge : +20 Or par rune d'amélioration présente dans l'instance.
