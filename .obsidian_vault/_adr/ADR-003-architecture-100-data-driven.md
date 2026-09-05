## 🌐 ADR-003 : Architecture 100% Data-Driven (JSON Assets)

### Statut

✅ **Accepté & Implémenté** — le principe tient toujours : 100 % du contenu vit en JSON sous
`assets/data/`, hors du code.

⚠️ **Sa mise en œuvre est dépassée depuis le 2026-09-05.** Le corps ci-dessous décrit
l'état d'origine et **n'est pas réécrit** : il est conservé pour sa valeur historique. Trois
choses n'y sont plus vraies.

| Ce que dit le corps | Depuis |
|:---|:---|
| 8 fichiers JSON nommément énumérés, avec leurs comptes | Les catalogues sont éclatés en un fichier par entité — [ADR-085](ADR-085-regle-de-partage-catalogue-configuration.md). Les comptes vivants sont dans [`_memory_bank/progress.md`](../_memory_bank/progress.md), qui les re-mesure |
| `GameDataService.loadAll()` charge les 8 fichiers par `Future.wait()` | Cette classe n'existe plus. `loadGameDataRegistry(bundle)` déclare huit sources par motif de chemin — [`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md) |
| `skills.json` (6 compétences) et `SkillData` | Supprimés du jeu — [ADR-084](ADR-084-suppression-de-la-chaine-de-competences-heroiques.md) |

Le point d'attention « **Pas de validation au chargement** » est **levé** : le chargeur
accumule les fautes et lève une fois, en nommant fichier et champ. Le point « **Lookup
O(n)** » reste ouvert, au périmètre de P-26.

L'appartenance d'une entité est désormais portée par son emplacement —
[ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).

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
