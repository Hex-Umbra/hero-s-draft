### 3.9. 🛒 Boutique (Shop)

Gérée par `ShopController` :
- **Visualisation et Modélisation** : Les cartes en vente sont représentées sous forme d'instances réelles de cartes (`CardInstance`). Le widget `UiCard.fromInstance` affiche directement leurs rune sockets d'amélioration de forge et leur couleur/halo de rareté dynamique.
- **Tarification Organique Dynamique** : Le prix d'une carte n'est plus fixe mais calculé dynamiquement en fonction de ses caractéristiques :
  - Coût de base déterminé par sa rareté finale : Commun (25 Or), Peu Commun (50 Or), Rare (100 Or), Épique (150 Or), Légendaire (200 Or).
  - Surcoût de forge : +20 Or par amélioration de forge présente (rune socket occupée) sur la carte.
- **Scaling de Progression par Acte** : L'inventaire de la boutique s'adapte à l'avancement du joueur sur la carte :
  - *Rareté accrue* : Les probabilités d'apparition de cartes de rareté supérieure (Rare, Épique, Légendaire) augmentent linéairement à chaque Acte.
  - *Améliorations pré-forge* : À partir de l'Acte 2, les cartes ont des chances croissantes de comporter une ou deux runes (15 % d'une rune à l'acte 2 ; dès l'acte 3, 30 % d'une, 10 % de deux). **Une carte pré-forgée porte au plus autant de runes que sa rareté a demandé de fusions** (`fusionRank`, D28) : **une commune n'en porte aucune**. Chaque rune est tirée comme à la fusion (`ForgeRuneRules.drawRunes`) : par le prédicat d'éligibilité au rang de la carte, sur la carte avec les runes déjà tirées, pondérée par `weight` — jamais une rune qui ne ferait rien sur la carte, ni deux runes qui s'excluent, ni deux fois la même ; son niveau est tiré 1, 2 ou 3 à 80, 15 et 5 %, puis borné par son plafond. Une carte à qui ne reste aucune rune éligible en porte une de moins ([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md), [ADR-106](../_adr/ADR-106-fusion-egale-forge.md)).
- **La copie d'une carte du deck** (D46, depuis le lot E2 de P-43 — branche de la vague 2, en attente du propriétaire) : à part des cartes en vente, la boutique propose **la copie d'une carte tirée au hasard dans tout le deck** (`DeckState.copyableCards`, sans les cartes de classe) — **même rareté, sans ses runes**, au prix d'une carte sans rune de cette rareté (25 · 50 · 100 · 150 · 200 or). Tirée, non choisie : la relance de l'étal ne la touche pas. Deck sans carte copiable : pas de copie.
- **L'étal est tiré une fois par nœud de boutique, et retenu** (décision du propriétaire du 02/10/2026) : les cartes en vente — relancées comprises —, la copie, le soin et les trois options du Miroir Magique avec son prix. Sortir par le retour système puis revenir dans le même nœud rend **le même étal** ; ce qui a été acheté reste acheté. L'étal est oublié dès que le nœud courant de la run change — un autre nœud, un acte, une run, une sauvegarde chargée. On ne peut donc plus retirer l'étal gratuitement en sortant puis en revenant, comme avant `ADR-106`.
- **Services additionnels** :
  - Soin (achat unique par nœud de boutique, prix fixe).
  - Expansion de boutique (+1 carte permanent dans l'inventaire de vente, via `InventoryController.buyShopExpansion()`).
  - Reroll des cartes (coût progressif par relance).
  - Purge de carte (suppression définitive du deck, coût fixe).
  - Miroir Magique (Clonage de carte) :
    - *Équilibrage dynamique (Nerf)* : Afin de limiter le clonage massif, le prix du Miroir Magique double géométriquement à chaque achat au sein de la même boutique ($150 \rightarrow 300 \rightarrow 600 \rightarrow 1200 \dots$ Or).
    - *Réinitialisation au nœud suivant* : options neuves, prix ramené à 150 Or et compteur à 0 **avec le reste de l'étal, quand le nœud courant change** — plus à chaque sortie de l'écran. `clearCloneOptions` a disparu : le point 5 d'[ADR-067](../_adr/ADR-067-equilibrage-de-l-economie-scaling-par-acte-des-car.md) est amendé par [ADR-106](../_adr/ADR-106-fusion-egale-forge.md), et un simple aller-retour ne ramène plus le prix du Miroir à sa base.
