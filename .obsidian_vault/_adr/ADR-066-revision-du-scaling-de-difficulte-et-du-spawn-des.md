## ⚔️ ADR-066 : Révision du Scaling de Difficulté et du Spawn des Ennemis (v0.2.7)

### Statut
✅ Accepté & Implémenté (v0.2.7)

### Contexte
La génération des combats dans `EncounterSystem` limitait trop souvent les rencontres à un ou deux ennemis maximum car le coût de combat (`CombatRating`) d'un ennemi était disproportionnellement élevé par rapport au budget de combat. En effet, la formule de `CombatRating` additionnait les PV bruts de l'ennemi (1 PV = 1 budget de menace), ce qui épuisait instantanément le budget final.
De plus, le budget de combat ne prenait pas en compte la puissance accumulée par le joueur via la taille de son deck, et le scaling de difficulté à partir de l'Acte 2 n'était pas assez marqué pour offrir un défi persistant.

### Décision
1. **Intégration du Deck du Joueur** : Ajouter le nombre de cartes du deck principal (`playerCardsCount`) dans le calcul de la puissance estimée du joueur (`playerCardsCount * 2.0`), augmentant son budget de combat de façon cohérente avec la taille de son deck.
2. **Formule de Combat Rating rééquilibrée** :
   - Diviser par 4.0 le poids des PV bruts de l'ennemi.
   - Multiplier par 2.0 le poids de ses dégâts de base.
   - Augmenter le coefficient du Tier à 15.0 (au lieu de 10.0) pour bien distinguer les paliers de force de base.
   $$\text{CombatRating} = (\text{tier} \times 15.0) + \frac{\text{HP\_Scalé}}{4.0} + (\text{Dégâts\_Scalés} \times 2.0) \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
3. **Bonus de Budget par Acte** : Introduire un bonus de budget de combat fixe de `+10.0` par acte au-delà de l'acte 1 (`((act - 1) * 10.0)`) pour donner plus de flexibilité au générateur à générer des combats en surnombre (3 à 5 monstres).
4. **Scaling accru à partir de l'Acte 2** :
   - Multiplicateur de PV : croissance par acte de 20% $\rightarrow$ 35%
   - Multiplicateur de Dégâts : croissance par acte de 15% $\rightarrow$ 25%

### Preuves dans le code
- [encounter_system.dart](../../lib/game/systems/encounter_system.dart) :
  - Mise à jour de la signature de `generateEnemiesForLevel` pour accepter `playerCardsCount`.
  - Intégration de `playerCardsCount` dans `playerPower`.
  - Application du bonus d'acte sur `finalBudget`.
  - Refonte de `calculateCombatRating` et mise à jour de `getHpMultiplier` et `getDamageMultiplier`.
- [combat_controller.dart](../../lib/game/controllers/combat_controller.dart) : Réception et transmission de `playerCardsCount` dans `initializeCombat`.
- [game_screen.dart](../../lib/ui/screens/game_screen.dart) : Passage du paramètre `playerCardsCount` lors de l'initialisation du combat via `ref.read(deckProvider).masterDeck.length`.
- [encounter_system_test.dart](../../test/encounter_system_test.dart) : Adaptation des assertions de test pour correspondre au nouveau calcul de Combat Rating ( slime : `32.2` $\rightarrow$ `27.9`).

### Conséquences
- ✅ **Combats tactiques plus variés** : Possibilité accrue de rencontrer plus de deux ennemis simultanément (jusqu'à 5 sur le plateau actif).
- ✅ **Difficulté progressive et adaptée** : La taille du deck offre un budget de combat plus dynamique, et l'acte 2+ offre un vrai pic de difficulté par rapport à l'acte 1.
- ✅ **Zéro Régression** : Tous les tests unitaires et widget-tests (108/108) passent au vert et l'analyse statique reste impeccable.
