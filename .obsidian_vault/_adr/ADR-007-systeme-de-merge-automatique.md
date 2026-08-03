## 🎲 ADR-007 : Système de Merge Automatique (3→1)

### Statut
✅ Accepté & Implémenté

### Contexte
L'accumulation de cartes dans un roguelike deckbuilder peut diluer la puissance du deck. Un mécanisme d'amélioration automatique est nécessaire.

### Décision
- Quand le `masterDeck` contient 3 exemplaires d'une carte avec le **même `baseCardId` ET le même `level`**, ils fusionnent automatiquement en 1 exemplaire de level+1.
- La fusion est déclenchée par `DeckNotifier.mergeCards(cardId, level)`.
- L'échelonnement des effets suit : `scaledValue = baseValue * (1 + (level - 1) * 0.5)`.

### Preuves dans le code
- `DeckNotifier.mergeCards()` : recherche 3 copies, suppression, ajout level+1.
- `EffectResolver.resolveCard()` : calcul du `scaledValue` par level.
- `UiCard._buildDescription()` : affichage des valeurs scalées.
- Documentation dans `docs/implementation_plans/deck_merge_system.md`.

### Conséquences
- ✅ Progression organique du deck sans interface d'amélioration explicite.
- ✅ Effet satisfaisant pour le joueur ("power spike" naturel).
- ⚠️ Complexité de l'algorithme : O(n²) pour grands decks (non problématique à <50 cartes actuellement).
