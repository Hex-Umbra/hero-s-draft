## 7. Architecture des Données (100% Data-Driven)

> [!IMPORTANT]
> **Une entité, un fichier, et le répertoire porte l'appartenance.** Le nom du fichier **est**
> l'`id`. Une signature rangée sous `classes/paladin/skills/` *est* une signature du paladin —
> le chargeur l'injecte depuis le chemin, et un JSON qui déclarerait `heroClass` échoue au
> chargement ; une carte neutre qui déclarerait `heroClass` ou `category` aussi. Voir
> [ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md), complété par
> [ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md) (branche de la vague 4).

### 7.1. Structure de `assets/data/`

```
assets/data/
├── audio.json, patch_notes.json,   # à plat : documents de configuration, pas des catalogues
│   xp_curve.json
├── cards/<id>.json                 # cartes neutres ; idem relics/, events/,
│                                   #   forge_upgrades/, passives/, level_up_rewards/
├── classes/<id>/{class.json, <id>.png, skills/<id>.json}
└── enemies/<id>/{enemy.json, sprite.png}
```

**Un fichier est éclaté s'il est un catalogue d'entités interchangeables ; il reste à plat
s'il est un document de configuration unique** — [ADR-085](../_adr/ADR-085-regle-de-partage-catalogue-configuration.md).
`audio.json` est une table de résolution dont les entrées n'ont de sens que les unes par
rapport aux autres ; dans `patch_notes.json`, l'ordre du tableau **est** la sémantique
(index 0 = version courante) et six consommateurs hors du jeu en dépendent. **`xp_curve.json`**
(vague 3, fusionnée dans `main` le 2026-10-04 —
[ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)) porte une seule table,
`xpPerLevelByAct` — le prix d'un niveau par acte ([`_rules/06-00`](06-00-economie-de-jeu.md)
§6.5) —, lue par `XpCurveData` (`lib/models/data/xp_curve_data.dart`) : une liste non vide
d'entiers d'au moins 1, refusée sinon. Comme `audio.json`, elle n'a ni id ni dossier et reste hors
de l'éditeur de contenu ; **à sa différence, son absence ou sa faute fait échouer le démarrage**,
avec les fautes des entités.

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
déclaration des neuf sources du jeu** ; le provider de production et le registre des tests du
tutoriel passent tous deux par elle. Les fautes de chargement **s'accumulent** et sont levées
en une fois, en nommant fichier et champ. Depuis la vague 3, elle charge aussi la
courbe d'XP, un document plat, par `GameDataLoader.loadDocument`, avant la levée ; le registre la
porte en `xpCurve`, que lit `xpCurveProvider`.

Mécanique complète du chargeur — [`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).

### 7.3. Graphe de relations entre modèles

```
PassiveData.classes ─────────────► HeroData.id (liste optionnelle, lue par availablePassivesFor)
HeroData.skills ─────────────────► SignatureData.id (signatures de la classe, rangées sous elle)
SignatureData.heroClass ─────────► HeroData.id (exigé, injecté par le chemin)
RunState.signatures ─────────────► List<SignatureInstance> (relues de la classe, jamais sérialisées)
CombatState.signaturesReadyOn ───► SignatureData.id → tour de disponibilité (jamais sérialisé)
PassiveData.trigger ─────────────► RelicTrigger (enum partagé avec RelicData)
CardInstance.data ───────────────► CardData
EnemyInstance.data ──────────────► EnemyData
EnemyInstance.stats ─────────────► EntityStats
EntityStats.statuses ────────────► List<StatusEffect>
CombatState.enemies ─────────────► List<EnemyInstance>
EventState.activeEvent ──────────► EventData
EventState.selectedChoice ───────► EventChoice
EventState.tradedRelic ──────────► RelicData (la relique que vise trade_relic, vague 3)
RunState.runeCapBonus ───────────► ForgeUpgradeData.id (bonus de plafond par rune, vague 3)
InventoryState.relics ───────────► List<RelicData>
ShopState.cardsForSale ──────────► List<CardInstance>
GameDataRegistry ────────────────► List<T> pour chaque type de données
```

`HeroData.skills` est la liste des `id` des signatures d'une classe, dans leur ordre
d'affichage, résolue par `HeroSkillsLink.getSignatures()` dans `registry.signatures` — une liste
à part de `registry.cards`, ce qui tient les signatures hors de tout pool de cartes par
construction (ADR-109). Le lien est fail-fast : un id introuvable lève. **Homonyme sans rapport**
avec le système de compétences héroïques, supprimé du jeu —
[ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md).

L'intégrité de ce graphe est gardée par `test/unit/referential_integrity_test.dart` : aucune
référence pendante, aucun dossier incomplet, le dossier `skills/` d'une classe en bijection avec
son champ `skills`, et **aucun id de signature n'est un id de carte**.

### 7.4. Internationalisation (i18n)

- **UI Flutter** : 100% via `AppLocalizations` (fichiers ARB `app_en.arb`, `app_fr.arb`). Zéro chaîne codée en dur.
- **Données JSON** : Double-champs bilingues (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`). **Aucun champ de texte visible monolingue ne subsiste depuis le 2026-09-04** — le dernier modèle qui y manquait a disparu avec son système ([ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md)). Ce n'est pas la même chose que « les deux paires partout » : `EnemyData` n'a pas de description du tout, et le `name` de `StatusEffect` (`lib/models/status_effect.dart`) est un identifiant technique, traduit à l'affichage.
- **Méthodes d'accès** : `getName(locale)` sur chaque modèle porteur d'un nom, `getDescription(locale)` sur ceux qui ont une description.
- **Statuts de combat** : Traduits à la volée par `StatusEffectsPanel` à partir d'identifiants techniques neutres.
