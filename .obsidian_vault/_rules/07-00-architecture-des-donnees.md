## 7. Architecture des Données (100% Data-Driven)

> [!IMPORTANT]
> **Une entité, un fichier, et le répertoire porte l'appartenance.** Le nom du fichier **est**
> l'`id`. Une carte rangée sous `classes/paladin/cards/` *est* une carte du paladin — le
> chargeur l'injecte depuis le chemin, et un JSON qui déclarerait `heroClass` échoue au
> chargement. Voir [ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).

### 7.1. Structure de `assets/data/`

```
assets/data/
├── audio.json, patch_notes.json    # à plat : documents de configuration, pas des catalogues
├── cards/<id>.json                 # cartes neutres ; idem relics/, events/,
│                                   #   forge_upgrades/, passives/
├── classes/<id>/{class.json, icon.png, cards/<id>.json}
└── enemies/<id>/{enemy.json, sprite.png}
```

**Un fichier est éclaté s'il est un catalogue d'entités interchangeables ; il reste à plat
s'il est un document de configuration unique** — [ADR-085](../_adr/ADR-085-regle-de-partage-catalogue-configuration.md).
`audio.json` est une table de résolution dont les entrées n'ont de sens que les unes par
rapport aux autres ; dans `patch_notes.json`, l'ordre du tableau **est** la sémantique
(index 0 = version courante) et six consommateurs hors du jeu en dépendent.

Un dossier de classe ou d'ennemi est **auto-suffisant**, image comprise : l'ajouter, c'est
créer un dossier, pas toucher quatre fichiers dispersés.

> [!NOTE]
> **Ajouter un dossier impose `dart run tool/sync_assets.dart`.** Les déclarations d'assets de
> Flutter ne sont récursives à aucun niveau ; un répertoire non déclaré ne produit **aucun
> message** — son contenu se charge en développement et disparaît en build.

Les identifiants sont en `snake_case` ASCII minuscule, épinglé par
`test/unit/entity_id_convention_test.dart`.

### 7.2. Chaîne de chargement

```
AssetManifest.listAssets()  →  appariement par motif de chemin  →  loadString()
    →  jsonDecode()  →  injection des champs imposés par le répertoire
    →  *.fromJson()  →  GameDataRegistry  →  gameDataLoaderProvider (FutureProvider)
```

`loadGameDataRegistry(bundle)` (`lib/services/game_data_service.dart`) est l'**unique
déclaration des huit sources du jeu** ; le provider de production et le registre des tests du
tutoriel passent tous deux par elle. Les fautes de chargement **s'accumulent** et sont levées
en une fois, en nommant fichier et champ.

Mécanique complète du chargeur — [`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).

### 7.3. Graphe de relations entre modèles

```
HeroData.passiveTrait ──────────► PassiveData.id
HeroData.skills ─────────────────► CardData.id  (cartes de signature de la classe)
CardData.heroClass ──────────────► HeroData.id (nullable = global, injecté par le chemin)
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

`HeroData.skills` est la liste des `id` des cartes de signature d'une classe, résolue par
`HeroSkillsLink.getHeroCards()`. **Homonyme sans rapport** avec le système de compétences
héroïques, supprimé du jeu — [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md).

L'intégrité de ce graphe est gardée par `test/unit/referential_integrity_test.dart` : aucune
référence pendante, aucun dossier incomplet.

### 7.4. Internationalisation (i18n)

- **UI Flutter** : 100% via `AppLocalizations` (fichiers ARB `app_en.arb`, `app_fr.arb`). Zéro chaîne codée en dur.
- **Données JSON** : Double-champs bilingues (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`) sur tous les modèles Data, **sans exception depuis le 2026-09-04** — le seul modèle qui y manquait, `SkillData`, a été supprimé avec son système.
- **Méthodes d'accès** : `getName(locale)`, `getDescription(locale)` sur chaque modèle.
- **Statuts de combat** : Traduits à la volée par `StatusEffectsPanel` à partir d'identifiants techniques neutres.
