## 🃏 ADR-051 : Filtrage des Cartes de Rareté Unique dans les Récompenses de Boss (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. Lors de l'implémentation de la récompense de cartes du Boss 1 (position x=0) via `BossCardDraftScreen`, les cartes étaient générées par `RewardController` en tirant depuis `allCards` sans filtrage de rareté spécifique.
2. Les cartes spécifiques de classe (ex: *Bouclier Saint*, *Fureur*) ayant été déplacées de `cards.json` à `hero_cards.json` avec la rareté `unique`, ces cartes étaient tirées à tort dans le draft de cartes globales, permettant à un joueur de collecter des cartes d'autres classes ou de briser la restriction de gating de classe.

### Décision
1. **Filtrage des Unique dans le RewardController** : Modifier la méthode d'initialisation de récompense `RewardController.initializeReward()`. Pour le cas de récompense `BossRewardType.cards` (Boss x=0), ajouter un filtre restrictif lors de l'extraction des cartes disponibles :
   ```dart
   rolledCards = allCards
       .where((c) => c.type != CardType.status && c.rarity != CardRarity.unique)
       .toList();
   ```
2. **Alignement des Pools** : Garantir que les cartes de rareté `unique` restent réservées à l'attribution initiale (starter decks via compétences) ou à des systèmes explicitement liés à la classe choisie, les excluant du pool de cartes globales proposées post-combat de boss.

### Preuves dans le code
- `lib/game/controllers/reward_controller.dart` : Ajout de la clause `c.rarity != CardRarity.unique` dans la méthode de roll des récompenses du boss de cartes.

### Conséquences
- ✅ **Cohérence Métier Restaurée** : Les cartes de classe conservent leur exclusivité. Un joueur Paladin n'aura aucun risque de se voir proposer des cartes de Mage ou de Berserker après avoir vaincu le premier boss.
- ✅ **Contrôle de l'Équilibrage** : Le pool de drafts de boss reste sain et équilibré avec les 15 cartes globales neutres uniquement.
