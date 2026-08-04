## 7. Architecture des Données (100% Data-Driven)

### 7.1. Chaîne de Chargement

```
assets/data/*.json  →  rootBundle.loadString()  →  jsonDecode()
    →  *.fromJson()  →  GameDataRegistry  →  gameDataLoaderProvider (FutureProvider)
```

`GameDataService.loadAll()` charge les 8 fichiers JSON via `Future.wait()` (chargement parallèle).

### 7.2. Graphe de Relations entre Modèles

```
HeroData.passiveTrait ──────────► PassiveData.id
CardData.heroClass ──────────────► HeroData.id (nullable = global)
PassiveData.trigger ─────────────► RelicTrigger (enum partagé avec RelicData)
CardInstance.data ───────────────► CardData
EnemyInstance.data ──────────────► EnemyData
EnemyInstance.stats ─────────────► EntityStats
EntityStats.statuses ────────────► List<StatusEffect>
CombatState.enemies ─────────────► List<EnemyInstance>
EventState.activeEvent ──────────► EventData
EventState.selectedChoice ───────► EventChoice
InventoryState.relics ───────────► List<RelicData>
ShopState.cardsForSale ──────────► List<CardInstance>
GameDataRegistry ────────────────► List<T> pour chaque type de données
```

### 7.3. Internationalisation (i18n)

- **UI Flutter** : 100% via `AppLocalizations` (fichiers ARB `app_en.arb`, `app_fr.arb`). Zéro chaîne codée en dur.
- **Données JSON** : Double-champs bilingues (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`) sur tous les modèles Data.
- **Méthodes d'accès** : `getName(locale)`, `getDescription(locale)` sur chaque modèle.
- **Exception** : `SkillData` n'a qu'un champ `name` unique (pas de support bilingue).
- **Statuts de combat** : Traduits à la volée par `StatusEffectsPanel` à partir d'identifiants techniques neutres.
