## 🎨 ADR-048 : État Critique Déterministe, Nombres Flottants Néon et Décélération de Jauge HP (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. L'ancien déclenchement des effets visuels de coup critique en combat reposait sur un calcul imprécis ou des seuils de dégâts arbitraires dans la couche de rendu. Il n'y avait pas de propagation déterministe de l'état "critique" depuis la logique de calcul de combat vers la couche Flame.
2. Les textes flottants d'effets et de dégâts (`FloatingText`) manquaient d'identité graphique et de dynamisme. Les critiques, le poison et le bouclier n'avaient pas de style distinctif en dehors de la valeur textuelle brute.
3. L'animation de dégâts de la jauge de vie du joueur (`PlayerHealthBar`) descendait trop rapidement (500ms), ce qui masquait l'intensité et le choc visuel des attaques subies lors des affrontements tendus.

### Décision
1. **Propagation de l'État Critique Déterministe** : Intégrer un champ booléen `lastActionWasCrit` dans le modèle d'état `EntityStats`. Ce flag est résolu à chaque calcul offensif ou curatif dans `EffectResolver` ou `CombatController` (grâce à des jets de chance critique) et stocké dans l'état Riverpod. Les composants Flame s'y synchronisent via `newStats.lastActionWasCrit` pour déclencher les tremblements prononcés (magnitude 28.0), les flashs dorés (`0xFFF59E0B`) et les 35 particules.
2. **Textes Flottants Premium & Néon** : Refondre `FloatingText` pour supporter :
   - *Ombres Néon Thématiques* : Orange/Rouge brillant pour critique, Vert pour poison, Cyan/Bleu pour bouclier.
   - *Rotation & Trajectoire* : Une rotation aléatoire de départ ($\pm 0.15$ rad) et une dérive en arc. Le poison bénéficie en plus d'une oscillation sinusoïdale horizontale dans sa méthode `update` pour simuler un gaz.
   - *Séquence d'Échelle de Critique* : Un effet séquentiel (`SequenceEffect`) composé d'un pop élastique initial à 1.5x (`Curves.elasticOut` en 350ms), d'une redescente à 1.15x, puis d'une pulsation de zoom/dézoom infinie (1.15x ⇄ 1.3x en 300ms) pour attirer l'attention du joueur.
   - *Préfixes Textuels* : Ajout automatique de `"💥 CRIT "`, `"🧪 "` ou `"🛡️ "` et calibrage de la taille de police (36 critique, 22 poison, 26 armure).
3. **Décélération de Jauge HP sous Dégâts** : Paramétrer dynamiquement la durée et la courbe d'animation de `PlayerHealthBar` dans `didUpdateWidget()`. Sous dégâts, la jauge verte descend instantanément tandis que la jauge rouge de catch-up met désormais **1200ms** à se vider avec une courbe de décélération `Curves.easeOut` pour matérialiser la gravité du coup. Pour le soin, la jauge rouge s'aligne immédiatement et la jauge verte remonte de manière fluide en **500ms**.

### Preuves dans le code
- `lib/models/entity_stats.dart` : Intégration de `lastActionWasCrit` dans les schémas JSON et la méthode `copyWith`.
- `lib/game/components/entities/hero_card.dart` & `enemy_card.dart` : Synchronisation et déclenchement d'animations enrichies si `newStats.lastActionWasCrit` est vrai.
- `lib/game/components/floating_text.dart` : Ombres thématiques complexes, préfixes, rotation, cinématique d'échelle séquentielle pour critique, et oscillation sinusoïdale pour poison.
- `lib/ui/widgets/hud/player_health_bar.dart` : Alternance de durée (1200ms dégâts vs 500ms soin) et gestion de courbe `Curves.easeOut`.

### Conséquences
- ✅ **Respect de l'Architecture Découplée (ADR-001)** : La logique de calcul des critiques reste à 100% dans la couche métier (Riverpod). La vue (Flame) est passive et se contente de réagir au flag d'état propagé.
- ✅ **Ressenti Tactile Décuplé (Visual Juice)** : L'élasticité et les ombres néon des critiques ainsi que la traînée de dégâts ralentie de la jauge HP confèrent un impact dramatique et gratifiant aux combats.
- ✅ **Maintenance & Robustesse** : Les 107 tests du projet continuent de s'exécuter sans aucune régression.
