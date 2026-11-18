### 5.3.1. Abstractions Graphiques Communes (CombatEntity & BaseVisualEffect)

Pour éliminer la duplication de code d'animation et normaliser le cycle de vie des effets visuels Flame, deux classes de base ont été introduites :
- **`CombatEntity`** (`lib/game/components/entities/combat_entity.dart` - `abstract class CombatEntity extends PositionComponent`) :
  - Centralise les animations communes aux entités de combat (`HeroCard` et `EnemyCard`).
  - Gère : secousses de dégâts (`shakeAndFlashAnimation`), flash coloré sur sprite (rouge pour dégâts, vert pour soins, jaune pour critiques), jet de particules de sang ou d'éther (`spawnDamageParticles`), animation de ruée offensive (`dashAnimation`), et animation d'impact de bouclier (`shieldHitAnimation`).
  - Centralise la détection des changements de statistiques (HP, armure) et le déclenchement des retours visuels (floating text orienté haut/bas, secousses, particules) via `triggerHitReactions(EntityStats oldStats, EntityStats newStats, {bool suppressArmorChange = false})` et `spawnFloatingText`.
  - Élimine la duplication de code résiduelle dans le code de rendu d'entité en permettant à `HeroCard` et `EnemyCard` de déléguer leur méthode `updateStats` à `triggerHitReactions`.
  - **Vague 7** (sur la branche — [ADR-117](../_adr/ADR-117-les-charges-elementaires.md)) : `triggerHitReactions` affiche un « +N » jaune par coup de Foudre nouveau (`EntityStats.chargeHits`) ; `refreshChargeVisuals` pose et retire halo, gangue et givre à la transition d'une piste de charge ; `emberFlash` fait rougeoyer la carte que le Feu touche ; une seule teinte de sprite à la fois (`_replaceSpriteTint`) — [`_patterns/05-8`](05-8-rendu-vectoriel-direct-sur-canvas-auras-senso.md) §4.
- **`BaseVisualEffect`** (`lib/game/components/visual_effects/base_visual_effect.dart` - `class BaseVisualEffect extends PositionComponent`) :
  - Centralise la gestion du cycle de vie des effets visuels.
  - Exécute un auto-nettoyage via `RemoveEffect(delay: duration)` et expose un callback optionnel `onComplete` appelé à la fin de la transition.
  - Sert de classe parente pour `SlashEffect` et `ShieldDome` (dans `card_animator.dart`), assurant un nettoyage systématique du canvas de rendu.
