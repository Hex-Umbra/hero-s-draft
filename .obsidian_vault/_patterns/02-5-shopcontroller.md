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
  - *Améliorations* : À partir de l'Acte 2, applique des upgrades de forge aléatoires compatibles (via `_rollRandomUpgrade`) selon l'Acte.
- `_rollRandomUpgrade(card, existingUpgrades, rng)` (privé) : Tire des améliorations de forge adaptées au type de la carte (Pool d'upgrades offensifs/statuts pour les attaques, utilitaires pour les compétences/pouvoirs).
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
