### 3.7. Logique de Forge Data-Driven & Forge de Fusion

#### 3.7.1. Gestion des Données de Forge
- **Déclaration JSON (`assets/data/forge_upgrades/<id>.json`)** : Les améliorations, descriptions, types de cartes éligibles, poids de tirage par rareté et multiplicateurs de tier sont externalisés.
- **Modèle et Registre (`ForgeUpgradeData`)** : Parser JSON avec registre d'accès statique `getById(id)` pour résoudre les données d'upgrades depuis n'importe quel point de rendu graphique sans avoir à passer par le state.
- **Chargement asynchrone** : Pris en charge par `loadGameDataRegistry(bundle)` (`lib/services/game_data_service.dart`) lors de la phase de chargement initial et mis à la disposition du jeu dans l'instance globale de `GameDataRegistry`.

#### 3.7.2. Logique Métier de Fusion (`ForgeFusionScreen`)
- **Éligibilité** : Filtrage du deck principal pour identifier les cartes possédant au moins 2 runes identiques (même ID).
- **Calcul du Coût** : Géré dans l'interface métier de l'écran par la formule $80 \times (N - 1)$ Or.
- **Rendu Visuel et Légende** : Le nœud est rendu graphiquement par l'icône `layers_rounded` fuchsia sur la carte (`MapNodeWidget`) et est explicitement listé avec son libellé traduit dans le panneau de légende de la carte (`MapLegend`).
- **Routage et Navigation** : `MapScreen` intercepte l'entrée du joueur dans le nœud `MapNodeType.forgeFusion` et le redirige vers `ForgeFusionScreen`.
- **Application des Changements** :
  1. Le joueur choisit les runes à fusionner.
  2. L'or est débité via `inventoryProvider.notifier.spendGold(...)`.
  3. Les améliorations de la carte sont remplacées dans l'état immuable du deck via `deckProvider.notifier.setForgeUpgrades(uniqueId, upgrades)`.

#### 3.7.3. Logique de Tirage et Affichage de Forge
- **Logique de non-épuisement** : Les dialogues de forge classique (`ForgeUpgradeDialog`) et les générateurs de boutique (`ShopController`) n'excluent plus les upgrades possédés via `alreadyHas` pour autoriser le cumul de runes identiques.
- **Sélection Pondérée** : Le choix probabiliste des slots utilise une sélection pondérée basée sur les poids déclarés dans le JSON en fonction de la rareté de la carte.
- **Rendu Dynamique et Traduction** : `ForgeSlotRow`, `CardTextRenderer` et `DeckScreen` résolvent dynamiquement les icônes, les libellés localisés et les cumuls d'effets en combat à partir du registre `ForgeUpgradeData.getById`.
