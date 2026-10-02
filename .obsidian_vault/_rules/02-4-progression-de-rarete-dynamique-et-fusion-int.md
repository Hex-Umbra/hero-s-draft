### 2.4. Progression de Rareté Dynamique et Fusion Interactive

La progression des cartes s'effectue via des raretés dynamiques (`common` → `uncommon` → `rare` → `epic` → `legendary`), chacune augmentant les valeurs de base de la carte.

> [!IMPORTANT]
> **L'échelle est portée par `CardRarity`, jamais par l'ordre de l'enum.** `CardRarity.next` donne la rareté qui suit (`null` pour `legendary`, sommet de l'échelle, comme pour `unique`, qui n'en fait pas partie), `CardRarity.fusionRank` le nombre de fusions qu'il a fallu pour l'atteindre — 0 à 4 de `common` à `legendary`, 0 pour `unique` ; renommé depuis `forgeSlotBonus`, mêmes valeurs. Il donne les emplacements de rune qu'ajoute la rareté, et les paliers de G1 ci-dessous. `unique` est déclarée après `legendary` sans lui succéder : un calcul sur `index` en faisait la rareté suivante — [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md), amendé par [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md).

**Ce que la rareté fait aux valeurs** — `CardRarity.scaleValue`, lu par le seul applicateur
(`EffectiveCard`), pour le moteur, les rendus et le tutoriel :

- **G1 — chaque fusion augmente d'au moins 1 chaque chiffre que la rareté multiplie** : dégâts,
  armure, soin, valeur d'un statut. À chaque palier franchi, `v = max(round(base × multiplicateur),
  v + 1)`, les multiplicateurs étant ×1,2 (peu commune), ×1,4 (rare), ×1,6 (épique), ×2,0
  (légendaire) — `CardRarity.multiplier`, 1,0 pour `unique`. Une base de 1 donne 1 · 2 · 3 · 4 · 5
  de commune à légendaire ; à partir d'une base de 5, le multiplicateur seul rend déjà au moins +1
  par palier. *Coup Empoisonné*
  légendaire : 7 dégâts et 5 Poison ; *Forme Démoniaque* légendaire : 6 Puissance.
- **G2 — la pioche (`draw`) et le mana rendu (`gain_mana`) ne grandissent pas avec la rareté** :
  ils gardent la valeur de la donnée. *Concentration* légendaire pioche 2 cartes. Une carte dont
  tous les effets sont gelés ne gagne à la fusion que sa rareté — une fente de rune de plus.
- Le **coût en mana ne change jamais** avec la rareté.

La fusion de cartes 3-en-1 est gérée par `DeckNotifier.mergeCards(selectedIds, inheritedUpgrades)` :
1. Le joueur sélectionne 3 exemplaires d'une même carte à une même rareté : l'écran de deck les groupe par id et rareté, et `mergeCards` refuse tout autre trio.
2. Les 3 copies sont supprimées du `masterDeck`.
3. Une nouvelle copie de la rareté suivante (`CardRarity.next`) est ajoutée au `masterDeck`.
4. **Héritage des Améliorations de Forge** (`ForgeRuneRules.consolidate`) : les runes de même ID voient leurs niveaux additionnés (ex: deux `sharp:1` fusionnent en un unique `sharp:2`), **sauf une rune non cumulable** (`stackable: false`, comme `enduring`), gardée une seule fois au niveau 1. Deux règles bornent l'héritage — [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md) :
   - **la somme est bornée par le `maxLevel` de la rune**, le surplus se perd : trois `eco:1` donnent `eco:1`, trois `sharp:1` donnent `sharp:3` ;
   - **deux runes qui s'excluent ne sont jamais réunies** (`excludesRunes`, dans un sens ou dans l'autre) : **la première arrivée est gardée**, l'autre est perdue. Trois *Potions de Soin* portant *Persistant*, *Économe* et rien donnent une carte qui ne porte que *Persistant* — sans quoi la fusion rouvrait une carte qui rend du mana sans s'épuiser, que l'éligibilité ferme ([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md)).

   Le nombre d'améliorations final est limité par la capacité de la nouvelle rareté (`CardData.forgeCapacityAt`, soit `baseMaxForgeUpgrades + fusionRank`). Le joueur choisit de manière interactive les upgrades qu'il souhaite hériter en cas de dépassement de la capacité ; le dialogue liste le résultat de `consolidate`, donc des niveaux bornés et sans paire exclue.
5. **Pas de fusion sans rareté au-delà** : ni les cartes de rareté `unique` (de classe) ni les légendaires ne fusionnent. L'écran de deck n'affiche pour elles aucune option de fusion, et `mergeCards` les refuse. Jusqu'au 2026-09-15, trois légendaires fusionnaient en une carte `unique`, de multiplicateur 1,0.
