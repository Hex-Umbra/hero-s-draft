## 2. Rôle des Contrôleurs et Architecture Modulaire (`lib/game/controllers/`)

Tous les contrôleurs héritent de `Notifier<T>` (Riverpod 2.x) et exposent des états immuables (pattern `copyWith`). Ils constituent la **source unique de vérité** du jeu. Les contrôleurs sont découplés : plutôt que de recevoir des références à d'autres contrôleurs via leur constructeur, ils accèdent à l'état global et aux autres contrôleurs via la propriété `ref` (ex: `ref.read(inventoryProvider.notifier)`) en interne. Cela élimine les constructeurs complexes et évite les dépendances circulaires au démarrage.

Dans le cadre du refactoring de la Phase 2, les contrôleurs les plus monolithiques (`RunController` et `CombatController`) ont été transformés en **façades légères**. Ils délèguent leurs responsabilités à des gestionnaires spécifiques isolés dans des sous-dossiers dédiés afin de respecter le principe de responsabilité unique (SRP).
