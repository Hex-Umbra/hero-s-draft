## 🔒 ADR-005 : Immuabilité d'État et Pattern `copyWith`

### Statut
✅ Accepté & Implémenté

### Contexte
La gestion d'état mutable dans des contextes asynchrones (Flame loop + UI rebuilds) provoque des race conditions et des mutations silencieuses non détectées par Riverpod.

### Décision
- Tous les `StateNotifier` émettent de nouveaux objets d'état via `state = state.copyWith(...)`.
- Les listes sont recréées (pas de `.add()` in-place) : `state = state.copyWith(enemies: [...state.enemies, newEnemy])`.
- Les modèles d'état (`RunState`, `DeckState`, `CombatState`, etc.) implémentent `copyWith()`.

### Preuves dans le code
- Pattern `copyWith` visible dans tous les contrôleurs (`RunController`, `CombatController`, `DeckNotifier`, etc.).
- Documentation dans `docs/lessons/state_immutability.md`.
- `CombatState`, `EntityStats`, `StatusEffect` possèdent des `copyWith` complets.

### Conséquences
- ✅ Réactivité fiable de Riverpod (détection de changements par référence).
- ✅ Traçabilité des mutations d'état.
- ⚠️ **Violation partielle identifiée** (rapport Opus 4.6) : Certaines listes mutables persistent dans les états "immuables" (enemies, relics, statusEffects) — risque de casser la détection de changements Riverpod.
- ⚠️ Absence de `==`/`hashCode` sur les modèles — comparaison par référence uniquement.
