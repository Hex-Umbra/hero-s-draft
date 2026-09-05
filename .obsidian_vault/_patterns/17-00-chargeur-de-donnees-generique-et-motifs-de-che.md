## 17. Chargeur de Données Générique et Motifs de Chemin (`GameDataLoader`)

> [!IMPORTANT]
> **Le répertoire fait autorité sur l'appartenance.** Un fichier rangé dans
> `assets/data/classes/paladin/cards/` *est* une carte du paladin : le chargeur l'injecte
> depuis le chemin. Un JSON qui déclarerait `heroClass` échoue au chargement. Voir
> [ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).

### 17.1. Les deux classes

`lib/services/game_data_loader.dart` — aucune dépendance au jeu, aucun type d'entité connu.

| Classe | Rôle |
|:---|:---|
| `EntitySource<T>` | Une catégorie : **où** trouver les fichiers (`pattern`), **comment** les construire (`fromJson`), et **ce que leur emplacement dit d'elles** (`inject`) |
| `GameDataLoader` | Lit le manifeste une fois, apparie, décode, fusionne, trie, déduplique — en **accumulant** les fautes |

`loadGameDataRegistry(bundle)` (`lib/services/game_data_service.dart`) est l'**unique
déclaration des huit sources du jeu**. Le provider de production et le registre des tests du
tutoriel passent tous deux par elle : une seconde déclaration serait une seconde vérité.

### 17.2. Le motif de chemin porte la sélection *et* l'injection

Chaque segment d'un `pattern` est un littéral, `*` (un segment quelconque, capturé tel quel)
ou `*.json` (un segment finissant par `.json`, capturé sans son extension). Les segments
capturés alimentent `inject`, dans leur ordre d'apparition.

| Motif | Capture | Injecte |
|:---|:---|:---|
| `assets/data/cards/*.json` | `[id]` | `id`, `category: global` |
| `assets/data/classes/*/cards/*.json` | `[classe, id]` | `id`, `heroClass`, `category: characterSpecific` |
| `assets/data/classes/*/class.json` | `[id]` | `id` |
| `assets/data/enemies/*/enemy.json` | `[id]` | `id` |
| `assets/data/relics/*.json` · `events/` · `forge_upgrades/` · `passives/` | `[id]` | `id` |

> [!NOTE]
> **Le nombre de segments doit correspondre exactement.** C'est ce seul fait qui sépare
> `classes/*/class.json` de `classes/*/cards/*.json` — les deux commencent pareil. Aucune
> expression régulière n'est en jeu.
>
> ⚠️ Les assets de paquets, eux, ne sont **pas** écartés par la profondeur : servis sous
> `packages/<nom>/...`, ils sont rejetés dès le premier segment par la comparaison littérale
> `assets` ≠ `packages` (`game_data_loader.dart`, branche `p != s`). Un paquet déclarant un
> asset peu profond produirait une clé plus *courte*, pas plus longue.

**Les passifs ne reçoivent aucune appartenance** (décision D4) : `PassiveData` n'a pas de
champ `heroClass`, donc l'injection y serait silencieusement jetée par `fromJson` — un no-op
qu'aucun test ne pourrait détecter. Ils restent à plat sous `assets/data/passives/`.

### 17.3. Règle de conflit

Le répertoire injecte ; le fichier a le droit de **confirmer à l'identique** si le champ
figure dans `EntitySource.redundantFields` ; la **contradiction échoue**, en nommant le
fichier, le champ, la valeur imposée et la valeur trouvée.

`redundantFields` vaut `const {'id'}` partout en production. `heroClass` et `category` y ont
été tolérés le temps de la migration ; **cette tolérance a expiré** et les déclarer est
désormais une erreur de chargement. `id` y reste à titre permanent : le porter dans le
fichier le rend lisible hors contexte et inspectable en masse
(`jq -s '.' assets/data/relics/*.json`).

### 17.4. Les fautes s'accumulent, la levée est unique

Une entité dont le JSON est illisible, dont `fromJson` lève, dont l'`id` manque ou fait
doublon est **exclue** du résultat, et sa faute rejoint `_errors`. Le chargement va jusqu'au
bout ; `throwIfFailed()` lève une seule fois, à la fin, toutes catégories confondues.

Corriger une faute par cycle de rebuild, sur 71 fichiers, serait invivable. Le message est
tronqué à 10 lignes ; la liste complète part en `debugPrint`.

Les entités sont **triées par `id`** avant construction : `AssetManifest.listAssets()`
n'offre aucune garantie d'ordre, et l'ordre d'affichage ne doit jamais dépendre de
l'énumération du disque.

### 17.5. Deux seams délibérés

- **`bundle` est un paramètre**, pas `rootBundle` en dur. C'est le seul point qui rend le
  chargeur testable sur une arborescence choisie.
- **`cache: false` sur chaque lecture.** L'appelant fait son propre cache — c'est
  `GameDataRegistry`, résolu une fois par `gameDataLoaderProvider` ; le SDK Flutter procède
  de même dans `loadStructuredData`. Trois conséquences, dans cet ordre : le devtool
  d'édition à venir relit le disque à chaud au lieu de servir un `Future` déjà réglé ; les
  ~40 Ko de chaînes ne sont pas retenus après le démarrage ; et sous `flutter test`, un
  `Future` mis en cache dans la zone d'un test terminé **ne se résout jamais** depuis un
  nouveau test. Ne pas retirer ce drapeau sans traiter les trois.

L'audio reste **hors du chargeur** : `loadAudioData` ne lève jamais, fichier absent ou
malformé valant catalogue désactivé. C'est le seul sous-système auquel il est interdit de
faire échouer le démarrage — [`_patterns/16-00`](16-00-architecture-du-systeme-audio.md).

### 17.6. Ce qui garde la structure

| Garde | Ce qu'il rend impossible |
|:---|:---|
| `tool/sync_assets.dart` | Régénère la section `assets:` du `pubspec.yaml` depuis le disque ; `--check` sort 1 sur dérive. Refuse de travailler plutôt que de deviner sur un pubspec ambigu |
| `test/unit/real_bundle_load_test.dart` | Une **ligne de pubspec oubliée**. Les déclarations d'assets ne sont récursives à aucun niveau, et un répertoire non déclaré ne produit **aucun message** : son contenu se charge en développement et disparaît en build. Seul un chargement par le vrai bundle prouve que l'application voit les fichiers |
| `test/unit/referential_integrity_test.dart` | Un **dossier incomplet** : classe sans `icon.png`, `skills` désignant une carte absente |
| `test/unit/flame_image_prefix_test.dart` | La **collision de clés du cache d'images de Flame**. `Images.prefix` ne fait pas partie des clés : sous un préfixe par dossier, les trois `icon.png` de classes s'écraseraient |

> [!NOTE]
> **Coût de démarrage relevé le 2026-09-05** : 72 lectures de bundle en **53 ms** en profile,
> contre un seuil d'alerte fixé à 200 ms. Aucune parallélisation nécessaire. ⚠️ Mesure
> ponctuelle du chantier : **rien dans le dépôt ne la reproduit ni ne garde ce seuil**.

Structure des données et règle de partage catalogue / configuration —
[`_rules/07-00`](../_rules/07-00-architecture-des-donnees.md) et
[ADR-085](../_adr/ADR-085-regle-de-partage-catalogue-configuration.md).
