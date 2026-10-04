### 2.3. `DeckNotifier` (`deckProvider`) — Maître du Deck

**Provider** : `NotifierProvider<DeckNotifier, DeckState>`

**État `DeckState`** : `masterDeck`, `drawPile`, `hand`, `discardPile`, `exhaustPile`
(toutes `List<CardInstance>`) + `reshuffleCount` (`int`).

**Responsabilités** :
- **Immuabilité stricte de `CardInstance`** : Le modèle `CardInstance` est garanti immuable (tous les attributs sont `final`, et `forgeUpgrades` est verrouillé dans `List<String>.unmodifiable`). Toutes les mutations temporaires ou permanentes se font via son pattern `copyWith` pour assurer l'intégrité de l'état.
- **Cycle de vie** : `clearDeck()`, `initializeStarterDeck(cards)`, `startCombat({handSize, maxHandSize})` — mélange le master deck, tire la main d'ouverture et remet `reshuffleCount` à 0, **en une seule affectation de `state`**.
- **Mécanique de pioche** : `drawCards(amount, {required maxHandSize})` — remélange automatiquement la défausse dès que la pioche est vide, s'arrête net quand la main est pleine. Il n'existe pas de méthode de remélange manuel. La borne reste un paramètre : la couture ne change pas, seule la valeur passée change — `RunState.maxHandSize` sur les six chemins depuis la branche de la vague 3, `GameConstants.maxHandSize` avant (ADR-107, qui amende ADR-078 D3).
- **Jeu de carte** : `playCard(card)` — retire de la main, puis `CardInstance.exhaustsOnPlay` décide : pouvoir, rune qui ajoute l'épuisement (delta `addExhaust`, aujourd'hui *Spectral*, qui l'emporte — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md)), ou `isExhaust` sans rune qui le lève (delta `removeExhaust`, aujourd'hui *Persistant*, lu dans la donnée par l'applicateur — [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md)) → exhaustPile ; autres → discardPile.
- **Gestion du deck** : `addCardToMasterDeck()`, `removeCardById()`, `addForgeUpgrade()`, `setForgeUpgrades()`. Aucune méthode ne monte la rareté d'une carte hors fusion (`upgradeCard`, sans appelant, supprimée le 2026-09-15).
- **Monter une rune, sans or** (branche de la vague 3 — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md), A13) : `raiseRuneLevel(cardId, runeId, {levels = 1, capBonus = const {}})` — refuse sans rien toucher une carte hors du master deck, une rune qu'elle ne porte pas, une rune hors registre, ou un plafond effectif qui ne la laisse pas monter (`boundLevel(levels, carried:, capBonus:)` à 0) ; sinon réécrit `id:n` en `id:n+k` **à sa place** (`ForgeRuneRules.replaceRune`). Rend vrai si la rune a monté. **L'écriture unique de quatre appelants** : `GoldManager.sharpenRune` (le feu, qui paie d'abord), le boss « XP » et la *Meule* (`RewardController`), le *Rémouleur* (`EventController`) — la troisième copie d'une même écriture que la vague 2 demandait de factoriser.
- **La qualité du deck** : `DeckState.fusionRankSum` (branche de la vague 3, A12) — Σ `card.rarity.fusionRank` sur le master deck, 0 pour une commune comme pour une `unique` ; la difficulté adaptative en lit le double ([`_rules/02-6`](../_rules/02-6-equilibrage-hybride-budget-de-menace-et-reser.md)).
- **Auto-Merge** : `mergeCards(selectedIds, {capBonus = const {}})` — exige 3 exemplaires d'une même carte à une même rareté qui a une rareté au-delà (`CardRarity.next`), les remplace par 1 carte de cette rareté et **la rend** (`null` si refusée). L'héritage se calcule dedans : **toutes** les runes des trois exemplaires, réunies par `ForgeRuneRules.consolidate` — niveaux bornés par le plafond effectif (`maxLevel` plus `capBonus`, que l'écran de deck lit sur `RunState.runeCapBonus`, branche de la vague 3), jamais deux runes qui s'excluent —, sans troncature ni choix d'héritage depuis [ADR-106](../_adr/ADR-106-fusion-egale-forge.md). L'offre d'une rune parmi trois est tirée par l'écran de deck, et le choix écrit par `addForgeUpgrade` ([`_rules/02-4`](../_rules/02-4-progression-de-rarete-dynamique-et-fusion-int.md), [`_patterns/10-00`](10-00-architecture-du-systeme-de-forge-et-de-fusion.md) §10.2).
- **Copies** : `DeckState.copyableCards` — les cartes du master deck qu'une source de copie peut tirer, sans les `unique` : le draft de boss, les deux Miroirs et, depuis ADR-106, la copie du deck vendue en boutique ; liste neuve à chaque appel, que ses appelants mélangent en place — [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md).
- **Défausse/Main** : `discardHand()` (main → défausse), `addCardToDiscardPile()` (ajout direct en défausse).

> [!NOTE]
> **`_drawInto` est le cœur, et il est pur.** `drawCards` et `startCombat` sont deux
> appelants d'une même fonction `static` qui ne touche pas à `state` : elle mute les
> listes qu'on lui passe et retourne un record `({draw, hand, discard, reshuffles})`.
> La main d'ouverture respecte donc **exactement** les mêmes invariants que toute autre
> pioche, et chaque méthode publique n'affecte `state` qu'une fois — donc une seule
> notification Riverpod, donc un seul `layoutHand()` côté Flame.

> [!IMPORTANT]
> **L'aléatoire est injecté, pas construit.** `deckRandomProvider` (`Provider<Random>`)
> est lu une fois dans `build()`. En test, `deckRandomProvider.overrideWithValue(Random(42))`
> rend toute séquence de pioche reproductible. Ne jamais réintroduire un `Random()` en dur
> dans ce fichier : c'est ce qui rendait les tests de séquence inécrivables.

Règle de jeu correspondante — [../\_rules/03-4-systeme-de-piles-de-cartes.md](../_rules/03-4-systeme-de-piles-de-cartes.md).
Conception — [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
