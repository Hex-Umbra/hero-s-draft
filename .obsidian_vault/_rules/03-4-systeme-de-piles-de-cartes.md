### 3.4. 🃏 Système de Piles de Cartes

Cinq piles logiques gérées par `DeckNotifier` :

```
[Master Deck]  ── Persistant entre combats. Source de vérité.
      │
      ▼ (initializeCombat: copie + shuffle)
[Draw Pile]  ──  Pioche: drawCards(amount)
      │                    │
      ▼                    ▼
   [Hand]  ────────►  [Discard Pile]  (playCard → si non-Power/non-Exhaust)
      │                    │
      │              shuffleDiscardIntoDraw() ──► [Draw Pile]
      │
      └──────────►  [Exhaust Pile]  (Power cards, isExhaust cards)
                      Retiré définitivement du combat en cours
```

> ⚠️ **Note critique** : `drawCards()` ne reshuffle PAS automatiquement la défausse quand la pioche est vide. `shuffleDiscardIntoDraw()` doit être appelé explicitement.
