### 3.7. Logique de Forge Data-Driven & Forge de Fusion

#### 3.7.1. Gestion des Données de Forge
- **Déclaration JSON (`assets/data/forge_upgrades/<id>.json`)** : Les runes, leurs textes, leur emoji, leurs pools de rareté et leur poids de tirage sont externalisés — et, depuis [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), **tout ce qu'elles font** : l'effet (`deltas`, liste typée de `CardDelta`), l'éligibilité (`eligibleCardTypes`, `eligibleEffects`, `excludesEffects`, `requiresExhaust`, `requiresMinCost`, `excludesRunes`) et le plafond (`maxLevel`, obligatoire, `null` = sans plafond). `valueMultiplier` n'existe plus.
- **Modèle et Registre (`ForgeUpgradeData`)** : Parser JSON avec registre d'accès statique `getById(id)` pour résoudre les données d'upgrades depuis n'importe quel point de rendu graphique sans avoir à passer par le state. `fromJson` refuse une clé obligatoire absente, un `maxLevel` nul ou négatif, un `deltas` vide, un type de delta inconnu, une rune qui s'exclut elle-même. Le modèle porte aussi la borne `boundLevel` et l'analyseur unique des références `id:niveau` (`parseRef`, `levelsOf`).
- **Chargement asynchrone** : Pris en charge par `loadGameDataRegistry(bundle)` (`lib/services/game_data_service.dart`) lors de la phase de chargement initial et mis à la disposition du jeu dans l'instance globale de `GameDataRegistry`.

#### 3.7.2. Logique Métier de Fusion (`ForgeFusionScreen`)
- **Éligibilité** : Filtrage du deck principal pour identifier les cartes possédant au moins 2 runes identiques (même ID) dont la fusion est proposée par `ForgeRuneRules.fusionOptionsFor` — rune cumulable, et somme qui tient sous son `maxLevel`.
- **Calcul du Coût** : Géré dans l'interface métier de l'écran par la formule $80 \times (N - 1)$ Or.
- **Rendu Visuel et Légende** : Le nœud est rendu graphiquement par l'icône `layers_rounded` fuchsia sur la carte (`MapNodeWidget`) et est explicitement listé avec son libellé traduit dans le panneau de légende de la carte (`MapLegend`).
- **Routage et Navigation** : `MapScreen` intercepte l'entrée du joueur dans le nœud `MapNodeType.forgeFusion` et le redirige vers `ForgeFusionScreen`.
- **Application des Changements** :
  1. Le joueur choisit les runes à fusionner.
  2. L'or est débité via `inventoryProvider.notifier.spendGold(...)`.
  3. Les améliorations de la carte sont remplacées dans l'état immuable du deck via `deckProvider.notifier.setForgeUpgrades(uniqueId, upgrades)`.

#### 3.7.3. Logique de Tirage et Affichage de Forge
- **Ce qui ne se repropose pas** : les dialogues de forge classique (`ForgeUpgradeDialog`) et les générateurs de boutique (`ShopController`) passent chaque rune par le prédicat `ForgeRuneRules.isEligible`, qui écarte une rune dont le plafond est atteint sur la carte, exemplaires additionnés. Les runes sans plafond restent cumulables. Dans une même session, les ids déjà proposés sont écartés, puis repris en dernier recours.
- **Sélection Pondérée** : un pool (`common`, `uncommon`, `rare`) est ciblé selon la rareté de la carte, avec repli vers `common` puis sur tous les pools ; parmi les runes du pool que le prédicat accepte, le tirage est pondéré par la clé `weight` du fichier. Détail des probabilités : [`_rules/03-8`](../_rules/03-8-systeme-de-forge-forge-de-fusion.md).
- **Rendu Dynamique et Traduction** : `ForgeSlotRow`, `ForgeCardPreview`, `CardTextRenderer`, `CardComponent`, `UiCard` et `DeckScreen` lisent ce qu'ils affichent d'une rune — nom, description, emoji — dans sa donnée, et ses chiffres sur l'applicateur `EffectiveCard` ([`_patterns/10-00`](10-00-architecture-du-systeme-de-forge-et-de-fusion.md) §10.2). Les `switch` d'affichage par id ont disparu ; une rune absente du registre s'affiche sous son id, sans description.
