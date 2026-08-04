### 3.9. 🛒 Boutique (Shop)

Gérée par `ShopController` :
- **Visualisation et Modélisation** : Les cartes en vente sont représentées sous forme d'instances réelles de cartes (`CardInstance`). Le widget `UiCard.fromInstance` affiche directement leurs rune sockets d'amélioration de forge et leur couleur/halo de rareté dynamique.
- **Tarification Organique Dynamique** : Le prix d'une carte n'est plus fixe mais calculé dynamiquement en fonction de ses caractéristiques :
  - Coût de base déterminé par sa rareté finale : Commun (25 Or), Peu Commun (50 Or), Rare (100 Or), Épique (150 Or), Légendaire (200 Or).
  - Surcoût de forge : +20 Or par amélioration de forge présente (rune socket occupée) sur la carte.
- **Scaling de Progression par Acte** : L'inventaire de la boutique s'adapte à l'avancement du joueur sur la carte :
  - *Rareté accrue* : Les probabilités d'apparition de cartes de rareté supérieure (Rare, Épique, Légendaire) augmentent linéairement à chaque Acte.
  - *Améliorations pré-forge* : À partir de l'Acte 2, les cartes ont des chances croissantes de comporter une ou plusieurs runes d'améliorations générées aléatoirement. Ces runes sont garanties compatibles avec la nature de la carte (pool d'upgrades physiques/élémentaires pour les attaques, utilitaires pour les compétences/pouvoirs).
- **Services additionnels** :
  - Soin (achat unique par visite, prix fixe).
  - Expansion de boutique (+1 carte permanent dans l'inventaire de vente, via `InventoryController.buyShopExpansion()`).
  - Reroll des cartes (coût progressif par relance).
  - Purge de carte (suppression définitive du deck, coût fixe).
  - Miroir Magique (Clonage de carte) :
    - *Équilibrage dynamique (Nerf)* : Afin de limiter le clonage massif, le prix du Miroir Magique double géométriquement à chaque achat au sein de la même boutique ($150 \rightarrow 300 \rightarrow 600 \rightarrow 1200 \dots$ Or).
    - *Réinitialisation automatique* : Le coût du service et le nombre de clones achetés lors de la session se réinitialisent automatiquement à leurs valeurs de base (150 Or et 0) dès que le joueur quitte la boutique (lorsque la session est fermée ou réinitialisée via `clearCloneOptions`).
