## 🌐 ADR-003 : Architecture 100% Data-Driven (JSON Assets)

### Statut
✅ Accepté & Implémenté

### Contexte
Les données de jeu (cartes, ennemis, héros, reliques, événements, passifs, compétences) pourraient être définies directement dans le code Dart ou dans des fichiers de données externes.

### Décision
- Définir **100% du contenu de jeu** dans des fichiers JSON stockés dans `assets/data/` (8 fichiers).
- Chaque fichier JSON a un modèle Dart correspondant dans `lib/models/data/` (les cartes globales et de classe partagent le modèle `CardData`) avec une factory `fromJson()`.
- Le chargement est centralisé dans `GameDataService.loadAll()` qui produit un `GameDataRegistry` immutable.
- Le registre est exposé via un `FutureProvider<GameDataRegistry>` (`gameDataLoaderProvider`).

### Preuves dans le code
- 8 fichiers JSON : `cards.json` (15 cartes globales), `hero_cards.json` (6 cartes spécifiques de classe), `enemies.json` (4 ennemis), `heroes.json` (3 héros), `skills.json` (6 compétences), `events.json` (2 événements), `passives.json` (3 passifs), `relics.json` (12 reliques).
- 8 modèles Data principaux avec `fromJson()` : `CardData`, `EnemyData`, `HeroData`, `SkillData`, `EventData`, `PassiveData`, `RelicData`, `GameDataRegistry`.
- `GameDataService.loadAll()` utilise `Future.wait()` pour charger les 8 fichiers en parallèle.

### Conséquences
- ✅ **Modding** : Modification des valeurs ou équilibrage instantané sans toucher au code.
- ✅ **Séparation des compétences** : Un game designer peut modifier les JSON sans connaître Dart.
- ✅ **Extension facile** : Ajouter un nouvel ennemi = ajouter un objet dans `enemies.json`.
- ⚠️ **Pas de validation au chargement** : Aucun `try-catch` dans `GameDataService` — une erreur JSON crash l'app.
- ⚠️ **Lookup O(n)** : `GameDataRegistry` utilise des `List<T>` avec recherche linéaire — devrait être `Map<String, T>` pour O(1).
