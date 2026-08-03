## 🎨 ADR-062 : Abstractions Graphiques Communes dans Flame (CombatEntity & BaseVisualEffect) (v0.2.3)

### Statut
✅ Accepté & Implémenté (v0.2.3)

### Contexte
1. Les composants `HeroCard` et `EnemyCard` de Flame dupliquaient massivement leur logique d'animation (secousses de dégâts, flashs colorés, dash d'attaque, éjection de particules), entraînant une dette technique de duplication (>300 lignes).
2. Les composants d'effets visuels comme `SlashEffect` et `ShieldDome` (dans `card_animator.dart`) géraient leur propre cycle de vie et leur auto-destruction de manière inconsistante.

### Décision
- **Classe de base `CombatEntity`** : Créer une classe de base abstraite `CombatEntity extends PositionComponent` sous `lib/game/components/entities/` pour y centraliser les comportements visuels et animations communes (`shakeAndFlashAnimation`, `spawnDamageParticles`, `dashAnimation`, `shieldHitAnimation`). Faire hériter `HeroCard` et `EnemyCard` de cette classe.
- **Classe de base `BaseVisualEffect`** : Créer une classe de base `BaseVisualEffect extends PositionComponent` sous `lib/game/components/visual_effects/` gérant une durée de vie (`duration`), un retrait automatique du parent via `RemoveEffect(delay: duration)`, et un callback de fin optionnel `onComplete`. Faire hériter `SlashEffect` et `ShieldDome` de cette classe.

### Preuves dans le code
- `lib/game/components/entities/combat_entity.dart`.
- `lib/game/components/visual_effects/base_visual_effect.dart`.
- Modifications de `hero_card.dart`, `enemy_card.dart`, `slash_effect.dart` et `card_animator.dart` pour s'appuyer sur ces abstractions.

### Conséquences
- ✅ **DRY (Don't Repeat Yourself)** : Réduction importante du code dupliqué (~300 lignes retirées) et centralisation des correctifs d'animations.
- ✅ **Gestion du cycle de vie des effets visuels** : Élimination des fuites mémoire potentielles (leak d'entités non supprimées du canvas) grâce à la gestion systématique de `RemoveEffect` dans `BaseVisualEffect`.
