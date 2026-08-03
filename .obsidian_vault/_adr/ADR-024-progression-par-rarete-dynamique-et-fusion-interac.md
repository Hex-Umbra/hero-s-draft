## ⚔️ ADR-024 : Progression par Rareté Dynamique et Fusion Interactive (3→1)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de progression initial reposait sur un niveau numérique de cartes peu évocateur. Pour renforcer l'aspect roguelike deckbuilder traditionnel et donner de la valeur aux doublons de cartes obtenus en récompense, le jeu avait besoin d'un mécanisme de rareté dynamique et d'une fusion interactive de cartes.

### Décision
1. **Rareté Dynamique** : Abandonner le concept de niveau numérique au profit d'une progression par rareté : `common` (Commune) → `uncommon` (Atypique) → `rare` (Rare) → `epic` (Épique) → `legendary` (Légendaire). Un multiplicateur de rareté spécifique applique un échelonnement proportionnel aux dégâts et armures de base de la carte.
2. **Fusion Interactive** : Intégrer dans le deck une mécanique de fusion demandant exactement 3 exemplaires identiques d'une carte à la même rareté. La fusion consomme ces 3 cartes et produit une carte unique de la rareté directement supérieure.
3. **Consolidation d'Upgrades** : Cumuler les améliorations de forge des cartes consommées lors de la fusion en additionnant les Tiers des améliorations de même ID (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`).
4. **Contrainte de Capacité** : Tronquer la liste des upgrades cumulés pour respecter la capacité maximale de la nouvelle rareté (`baseMaxForgeUpgrades + rarityIndex`). Fournir une interface de choix interactif pour décider des améliorations héritées.
5. **Équilibrage de Cartes Clés** : Rééquilibrer plusieurs cartes pour qu'elles s'adaptent harmonieusement au flux de rareté et d'upgrades :
   - `holy_shield` : Dotée du mot-clé `isExhaust: true` pour éviter le spam défensif infini.
   - `warcry` : Dégâts de zone (AoE) couplés à un gain d'armure modéré.
   - `mana_surge` : Gain de 1 mana, pioche 1, et épuisement (`isExhaust: true`).
   - `concentration` : Pioche 2, coût 0, et épuisement.
   - `poison_stab` : Dégâts ciblés avec application directe de poison.

### Preuves dans le code
- `lib/game/controllers/deck_controller.dart` : Méthode `mergeCards()` gérant la validation des 3 IDs, le retrait des cartes du deck principal, le calcul de la rareté supérieure, la consolidation des Tiers d'upgrades et le clamp à la capacité maximale.
- `assets/data/cards.json` : Structure JSON mise à jour avec les attributs de rareté et les configurations d'équilibrage.
- `test/unit/deck_controller_test.dart` : Validation de la fusion 3→1 et de la conservation/limitation des upgrades.

### Conséquences
- ✅ **Valorisation des récompenses** : Le joueur est ravi de recevoir des doublons de cartes car ils lui permettent de monter son deck en rareté.
- ✅ **Conservation d'investissement** : Fusionner des cartes déjà améliorées à la forge ne fait pas perdre l'investissement en or grâce au cumul de Tiers.
