### 2.5. Immutabilité Stricte des Modèles d'État
Afin de garantir la robustesse du flux de données unidirectionnel imposé par Riverpod, les modèles d'état de combat essentiels (`EntityStats`, `CombatState`, `EnemyInstance`) sont explicitement marqués avec l'annotation `@immutable` (importée de `package:meta/meta.dart`).

De plus, pour empêcher toute altération accidentelle par référence directe (mutation latérale de listes de statuts ou d'instances d'ennemis), leurs listes internes sont encapsulées dans des instances de `List.unmodifiable` lors de l'instanciation et au sein de la méthode `copyWith`. Toute tentative d'altération directe lève immédiatement une exception à l'exécution, forçant le passage exclusif par les Notifiers et `copyWith`.
