## ⚔️ ADR-025 : Système de Forge Découplé et Probabiliste

### Statut
✅ Accepté & Implémenté

### Contexte
L'amélioration des cartes au feu de camp manquait d'aléa et de choix stratégiques significatifs. Proposer des choix d'améliorations fixes et illimités rendait la forge monotone. Un système roguelike robuste exigeait des options aléatoires limitées par la rareté de la carte, des probabilités de slots d'options variables et un coût de relance exponentiel.

### Décision
1. **Capacité Maximale Scalée** : Restreindre le nombre maximum d'améliorations de forge toléré sur une carte à la valeur `baseMaxForgeUpgrades + rarityIndex`.
2. **Génération Probabiliste de Slots** : À chaque ouverture de la forge pour une carte, le nombre d'options d'upgrades disponibles (1 à 5) est déterminé aléatoirement. Chaque slot a une chance indépendante d'apparaître :
   - Slot 1 : 100%
   - Slot 2 : 50%
   - Slot 3 : 25%
   - Slot 4 : 10%
   - Slot 5 : 2%
3. **Pools Clamps par Rareté** : Classer les upgrades par niveaux de rareté :
   - *Common Pool* (Dégâts `sharp`, Armure `hardened`, et effets de statut `burning`, `freezing`, `shocking` limités aux cartes Attaque).
   - *Uncommon Pool* (Pioche `quick`).
   - *Rare Pool* (Économe en mana `eco`, et persistant `enduring` - retirant l'épuisement `exhaust` - réservé aux cartes non-pouvoir qui s'épuisent).
4. **Pondération et Distribution** : Assigner la probabilité d'apparition des pools selon la rareté de la carte (ex : une carte rare a de meilleures chances de tirer des options peu communes ou rares). Déterminer le Tier de l'upgrade (de I à III) via des jets pondérés : Tier I (80%), Tier II (15%), Tier III (5%).
5. **Relance Exponentielle Individuelle** : Permettre au joueur de relancer le tirage d'un slot spécifique en dépensant de l'or de l'inventaire. Le coût augmente exponentiellement par slot selon la formule $20 \times 1.25^n$ (arrondi) où $n$ est le nombre de relances subies par ce slot.
6. **Intégration d'Écran** : Modéliser le système de slots indépendamment de l'UI et l'intégrer dans le widget dialog `ForgeUpgradeDialog` appelé depuis l'écran de feu de camp `RestScreen`.

### Preuves dans le code
- `lib/ui/widgets/forge_upgrade_dialog.dart` : Classe `ForgeSlot` portant la formule `(20 * pow(1.25, rerollsCount)).round()`, méthodes `_generateInitialSlots`, `_rollSlotUpgrade`, et `_rerollSlot` consommant l'or de `inventoryProvider`.
- `test/unit/decoupled_forge_test.dart` : Suite complète de tests unitaires simulant des centaines de tirages pour valider les chances d'ouverture de slots, la clampabilité des pools et le coût de reroll.

### Conséquences
- ✅ **Suspense et rejouabilité** : Le joueur espère obtenir de nombreux slots ou un upgrade Rare puissant (comme `enduring` pour pérenniser un sort de soin).
- ✅ **Arbitrage financier** : Introduit un arbitrage crucial sur l'or : faut-il relancer un slot de forge ou économiser pour la boutique ?
- ⚠️ **Dépendance à la chance** : Un joueur malchanceux peut n'avoir qu'un seul slot d'option disponible, bien que compensé par la possibilité de reroll.
