## 🧠 ADR-061 : Strategy Pattern pour la résolution des effets de cartes (v0.2.3)

### Statut
✅ Accepté & Implémenté (v0.2.3)

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
- `lib/game/services/effects/effect_registry.dart` (registre).
- Fichiers sous `lib/game/services/effects/strategies/` pour les 6 implémentations concrètes.
- `lib/game/services/effect_resolver.dart` allégé qui redirige vers le registre.

### Conséquences
- ✅ **Extensibilité Facile (Open/Closed Principle)** : L'ajout d'un nouvel effet consiste à créer une nouvelle classe implémentant `EffectStrategy` et à l'enregistrer dans `EffectRegistry`, sans modifier le reste du système.
- ✅ **Lisibilité et SRP** : Chaque effet a son propre fichier de logique propre et isolé.
