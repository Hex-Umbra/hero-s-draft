## 🧠 ADR-061 : Strategy Pattern pour la résolution des effets de cartes (v0.2.3)

### Statut
✅ Accepté & Implémenté (v0.2.3). **Complété le 2026-10-02 par
[ADR-105](ADR-105-moteur-de-runes-data-driven.md)** (P-43, lot E1, livré sur branche, en attente du
propriétaire) : les effets qu'ajoutent les runes passent eux aussi par le registre, et le résolveur
n'a plus aucun code de rune. **Complété le 2026-11-17 par
[ADR-117](ADR-117-les-charges-elementaires.md)** (P-53, vague 7, livré sur la branche
`feat/v0.5.9-p53-charges-elementaires`, en attente du test, de la PR, de la fusion et du tag du
propriétaire) : `ApplyStatusEffectStrategy` aiguille un statut qui est une charge du catalogue vers
`ChargeRules.pose`, les autres vers `addStatus` — toujours une stratégie, aucun `if` sur l'id.

### Contexte
Dans `EffectResolver`, la résolution des effets de cartes reposait sur un switch/case monolithique géant. L'ajout ou la modification d'effets (dégâts, soin, armure, pioche, mana, statut) nécessitait d'étendre ce switch, augmentant la complexité cyclomatique et le risque de régression à chaque sprint.

### Décision
- Introduire le **Strategy Pattern** pour la résolution des effets.
- Créer une interface `EffectStrategy` et un registre `EffectRegistry` sous `lib/game/services/effects/`.
- Implémenter 6 classes de stratégies concrètes, chacune prenant en charge une responsabilité spécifique :
  - `DamageEffectStrategy` (dégâts physiques/magiques, multi-cibles, et statuts associés).
  - `HealEffectStrategy` (soins avec gestion des coups critiques).
  - `ArmorEffectStrategy` (génération d'armure avec Armor Mastery).
  - `GainManaEffectStrategy` (restauration ou surcapacité temporaire).
  - `DrawEffectStrategy` (pioche de cartes).
  - `ApplyStatusEffectStrategy` (application d'effets de statut sur la cible ou sur soi).
- Faire de `EffectResolver` un simple routeur déléguant dynamiquement à l' `EffectRegistry`.

### Preuves dans le code
- `lib/game/services/effects/effect_strategy.dart` (interface).
- `lib/game/services/effects/effect_strategy.dart` (registre `EffectRegistry`, dans le même fichier).
- `lib/game/services/effects/strategies.dart` pour les 6 implémentations concrètes.
- `lib/game/services/effect_resolver.dart` allégé qui redirige vers le registre.

### Conséquences
- ✅ **Extensibilité Facile (Open/Closed Principle)** : L'ajout d'un nouvel effet consiste à créer une nouvelle classe implémentant `EffectStrategy` et à l'enregistrer dans `EffectRegistry`, sans modifier le reste du système.
- ✅ **Lisibilité et SRP** : Chaque effet a son propre fichier de logique propre et isolé.
