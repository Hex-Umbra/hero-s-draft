### 2.4. Progression de Rareté Dynamique et Fusion Interactive

La progression des cartes s'effectue via des raretés dynamiques (`common` → `uncommon` → `rare` → `epic` → `legendary`), chacune appliquant un coefficient multiplicateur sur les statistiques de base de dégâts et d'armure de la carte.

> [!IMPORTANT]
> **L'échelle est portée par `CardRarity`, jamais par l'ordre de l'enum.** `CardRarity.next` donne la rareté qui suit (`null` pour `legendary`, sommet de l'échelle, comme pour `unique`, qui n'en fait pas partie), `CardRarity.forgeSlotBonus` les emplacements de rune qu'elle ajoute. `unique` est déclarée après `legendary` sans lui succéder : un calcul sur `index` en faisait la rareté suivante — [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md).

La fusion de cartes 3-en-1 est gérée par `DeckNotifier.mergeCards(selectedIds, inheritedUpgrades)` :
1. Le joueur sélectionne 3 exemplaires d'une même carte à une même rareté : l'écran de deck les groupe par id et rareté, et `mergeCards` refuse tout autre trio.
2. Les 3 copies sont supprimées du `masterDeck`.
3. Une nouvelle copie de la rareté suivante (`CardRarity.next`) est ajoutée au `masterDeck`.
4. **Héritage des Améliorations de Forge** : Les upgrades de même ID voient leurs Tiers additionnés (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`), **sauf une rune non cumulable** (`stackable: false`, comme `enduring`), gardée une seule fois au tier 1 (`ForgeRuneRules.consolidate`). Le nombre d'améliorations final est limité par la capacité de la nouvelle rareté (`CardData.forgeCapacityAt`, soit `baseMaxForgeUpgrades + forgeSlotBonus`). Le joueur choisit de manière interactive les upgrades qu'il souhaite hériter en cas de dépassement de la capacité.
5. **Pas de fusion sans rareté au-delà** : ni les cartes de rareté `unique` (de classe) ni les légendaires ne fusionnent. L'écran de deck n'affiche pour elles aucune option de fusion, et `mergeCards` les refuse. Jusqu'au 2026-09-15, trois légendaires fusionnaient en une carte `unique`, de multiplicateur 1,0.
