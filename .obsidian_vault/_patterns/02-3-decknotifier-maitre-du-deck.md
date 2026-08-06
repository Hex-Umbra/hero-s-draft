### 2.3. `DeckNotifier` (`deckProvider`) — Maître du Deck

**Provider** : `NotifierProvider<DeckNotifier, DeckState>`

**État `DeckState`** : `masterDeck`, `drawPile`, `hand`, `discardPile`, `exhaustPile`
(toutes `List<CardInstance>`) + `reshuffleCount` (`int`).

**Responsabilités** :
- **Immuabilité stricte de `CardInstance`** : Le modèle `CardInstance` est garanti immuable (tous les attributs sont `final`, et `forgeUpgrades` est verrouillé dans `List<String>.unmodifiable`). Toutes les mutations temporaires ou permanentes se font via son pattern `copyWith` pour assurer l'intégrité de l'état.
- **Cycle de vie** : `clearDeck()`, `initializeStarterDeck(cards)`, `startCombat({handSize, maxHandSize})` — mélange le master deck, tire la main d'ouverture et remet `reshuffleCount` à 0, **en une seule affectation de `state`**.
- **Mécanique de pioche** : `drawCards(amount, {required maxHandSize})` — remélange automatiquement la défausse dès que la pioche est vide, s'arrête net quand la main est pleine. Il n'existe pas de méthode de remélange manuel.
- **Jeu de carte** : `playCard(card)` — retire de la main. Cartes Power ou `isExhaust` → exhaustPile; autres → discardPile.
- **Gestion du deck** : `addCardToMasterDeck()`, `removeCardById()`, `upgradeCard(uniqueId)` (level+1 permanent).
- **Auto-Merge** : `mergeCards(cardId, level)` — cherche 3 copies (même baseCardId + level), supprime les 3, ajoute 1 copie à level+1.
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
