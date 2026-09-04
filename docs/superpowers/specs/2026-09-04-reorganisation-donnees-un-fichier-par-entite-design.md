# Réorganisation des données — un fichier par entité — Conception

Date : 2026-09-04
Statut : **Design validé, non implémenté**
Révision : v3 — après deux tours de revue indépendante (4 agents)
Prérequis : **P-40 bloc 1** — **livré** le 2026-09-04 (`ced306e`), voir §3.1
Créneau : **entre P-40 et P-41**, donc avant **P-42** (pools de cartes par classe)
Sources amont :
- `docs/ROADMAP.md` §4 — programme P-40 → P-44, et la dépendance P-41 → P-42
- `docs/possible_upgrades/05-08-2026_brainstorm_heros_et_cartes_Opus5.md` — l'AXE A, devenu ce programme
- Analyse de faisabilité du devtool d'édition de contenu, 2026-09-04

> **Le chantier n'est pas « ranger les JSON », c'est « faire porter l'appartenance par la structure ».**
>
> Huit catalogues monolithiques décrivent tout le contenu du jeu. Éditer une carte veut dire
> réécrire le catalogue ; ajouter une classe veut dire toucher quatre fichiers dispersés ; et l'ordre
> des tableaux, que personne n'a jamais décidé, est visible par le joueur.
>
> Deux décisions structurantes en découlent. **Une entité vit dans un fichier** — créer du contenu
> n'écrase plus jamais du contenu existant. Et **le répertoire fait autorité sur l'appartenance** —
> une carte rangée dans `classes/paladin/cards/` *est* une carte du paladin, le chargeur l'injecte,
> et un JSON qui prétendrait le contraire échoue au chargement.

---

## 1. Mesures de référence

Relevées le **2026-09-04**, sur `ced306e` — c'est-à-dire **après la livraison du bloc 1 de P-40**
(§3.1), dont toutes les valeurs ci-dessous tiennent déjà compte.

| Mesure | Valeur |
|:---|:---|
| `dart analyze` | `No issues found!` |
| `flutter test` | **387 tests au vert** |
| Fichiers dans `assets/data/` | **10** |
| Entités réparties en 8 catalogues | **71** |
| Lectures de bundle au démarrage | **9** — 8 catalogues + `audio.json` *(`patch_notes.json` n'est lu que par son écran)* |
| Flutter / Dart / Flame | 3.41.6 / 3.11.4 / 1.37.0 |

Le compte de tests est la mesure qui dira, après migration, si un test a disparu en route.

### 1.1 Vérification préalable

Chaque affirmation vérifiée contre le code le 2026-09-04.

| Constat | Vérification |
|:---|:---|
| Huit catalogues chargés depuis huit chemins codés en dur | `lib/services/game_data_service.dart:80-87` |
| `_mapList` lève à la **première** entrée fautive | `lib/services/game_data_service.dart:28-50` |
| `AssetManifest.loadFromAssetBundle` + `listAssets()` rendent les fichiers issus d'une déclaration de répertoire | `flutter/lib/src/services/asset_manifest.dart:27-48, 122-124` |
| `listAssets()` n'offre **aucune garantie d'ordre** — `getAssetVariants` déplace les clés entre deux structures | idem `:115, 122-124` |
| `listAssets()` renvoie aussi les assets de paquets, sous `packages/<nom>/…` | idem |
| **Les déclarations d'assets ne sont pas récursives** | `flutter_tools/lib/src/asset.dart:1178-1180` — `.listSync()` sans `recursive: true` |
| Un répertoire déclaré mais **absent** journalise puis `return` — non fatal | `flutter_tools/lib/src/asset.dart:1173-1176` |
| `Images.prefix` est un setter mutable, préfixe vide autorisé | `flame-1.37.0/lib/src/cache/images.dart:33-41` |
| **Le préfixe ne fait pas partie des clés du cache Flame** | idem `:29-32` — voir §6.2, c'est une contrainte, pas une garantie |
| `FlameGame.images` **est** le singleton global par défaut | `flame-1.37.0/lib/src/game/game.dart:28` |
| `FlameGame` n'accepte pas `images` au constructeur | `flame-1.37.0/lib/src/game/flame_game.dart:43-46` — affectation dans le corps |
| Un second chargeur en doublon relit `enemies.json` et `heroes.json` | `lib/game/heros_draft_game.dart:136` et `:147` |
| …son `catch` retombe sur une liste d'images codée en dur | `lib/game/heros_draft_game.dart:157-167` |
| …et **deux autres** replis d'images codés en dur existent | `state_sync_system.dart:42`, `enemy_card.dart:73` |
| `PassiveData.fallback()` duplique les 3 passifs **en dur en Dart** | `lib/models/data/passive_data.dart:67-120` |
| L'ordre de `registry.cards` est l'ordre d'affichage du dictionnaire | `card_dictionary_screen.dart:87-96` — `Map` non pré-amorcée + `putIfAbsent`, puis `entries.map` |
| L'ordre de `registry.relics` change la relique offerte par un nœud | `relic_exchange_screen.dart:124-125, 140-144` |
| …c'est le seul `Random` graine **en code exécuté** de `lib/` | `deck_controller.dart:393` en contient un second, dans un commentaire de doc |
| Trois replis `.first` sur des listes du registre | `state_sync_system.dart:46`, `stats_dialog.dart:43`, `relic_exchange_screen.dart:144` |
| Une carte de signature manquante disparaît **silencieusement** du deck | `lib/models/data/hero_skills_link.dart:9-11` — `matches.first` puis `.whereType<CardData>()` |
| `PassiveData` **n'a pas** de champ `heroClass` | `lib/models/data/passive_data.dart:6-13` |
| `CardData` **et** `ForgeUpgradeData` possèdent un `toJson()` ; les 5 autres modèles n'en ont pas | `card_data.dart:134`, `forge_upgrade_data.dart:56` |
| `CardData.toJson()` **omet `sfx`**, que `fromJson` lit | `card_data.dart:123` (lecture) vs `:134-151` (écriture) |
| Le constructeur de `GameDataRegistry` écrit un singleton statique | `game_data_registry.dart:33` — `_instance = this` |
| `availableEnemies` / `availableHeroes` sont affectés **après** `onLoad()` | `game_screen.dart:417-418` vs `heros_draft_game.dart:133-172` |
| …mais la donnée **est** disponible en `initState` | `splash_screen.dart:11-22` résout le provider ; il n'est pas `autoDispose` ; `game_screen.dart:73, 150, 236` lisent déjà ainsi |
| `buildTutorialTestRegistry()` est **synchrone** et appelé depuis 3 initialiseurs de `final` de haut niveau | `tutorial_class_step_test.dart:16`, `tutorial_starter_draft_test.dart:16`, `tutorial_merge_transition_test.dart:59` |
| L'audio a le droit de dégrader silencieusement | `game_data_service.dart:61-76` — `loadAudioData` ne lève jamais |
| `flutter test` construit le bundle d'assets par défaut | `flutter_tools/lib/src/commands/test.dart:412, 486-489` |
| …mais `_needsRebuild` **ne détecte pas les suppressions** | idem `:817-843`, TODO explicite, flutter#128563 |
| CI : `dart analyze --fatal-infos` puis `flutter test` nu, sur `ubuntu-latest` | `.github/workflows/ci.yml:21, 36, 38` |
| `tool/` **n'existe pas** dans le dépôt | `ls tool/` |

> **`HeroData.skills` est vivant et ne doit pas être touché.** C'est la liste des ids des deux cartes
> de signature de la classe (`hero_data.dart:14`), lue par `tutorial_engine.dart:150` et
> `tutorial_starter_deck_widget.dart:41`. Elle est homonyme de la chaîne `SkillData` morte que P-40
> supprime, sans aucun rapport avec elle.

---

## 2. Le problème

**2.1 — Créer du contenu impose de réécrire du contenu existant.** Ajouter une carte veut dire
réécrire le tableau des 17. Sans conséquence à la main, rédhibitoire pour le devtool d'édition prévu
au chantier suivant : un `toJson()` incomplet ferait disparaître des champs des 16 autres cartes, en
silence. Le rayon d'explosion d'une écriture doit être l'entité, pas le catalogue.

**2.2 — Ajouter une classe touche quatre endroits dispersés.** `heroes.json`, `passives.json`,
`hero_cards.json`, `assets/images/`. Rien dans la structure ne dit que ces morceaux forment un tout,
et rien ne signale l'oubli de l'un d'eux. **P-42 prévoit ~25-30 cartes de classe supplémentaires.**

**2.3 — L'ordre des tableaux est une décision que personne n'a prise.** Il gouverne l'affichage du
dictionnaire, l'ordre des classes à la sélection, le pool du draft de départ et le tirage de reliques
par nœud. Insérer une carte au milieu de `cards.json` change ce que voit le joueur.

**2.4 — Quatre chemins de repli codés en dur masquent les défaillances.**
`heros_draft_game.dart:136` relit `enemies.json` et `heroes.json` une seconde fois pour collecter les
chemins à précharger, dans un `catch` qui retombe sur une liste d'images en dur (`:157-167`) ;
`state_sync_system.dart:42` et `enemy_card.dart:73` portent chacun leur repli en dur ; et
`PassiveData.fallback()` duplique les trois passifs en Dart. Toute évolution du format casse ces
blocs **sans erreur visible**.

---

## 3. Décisions retenues

Arrêtées avec le propriétaire du projet les 2026-08-26 et 2026-09-04 (deux passes après revue).

| # | Décision | Motif |
|:---|:---|:---|
| D1 | **Trois lots successifs**, correctifs d'abord | Chaque lot referme sa transition ; aucun hybride durable. Voir §3.2 |
| D2 | **Un dossier par classe**, image comprise | La classe devient une unité créable, supprimable et lisible d'un bloc |
| D3 | **Un dossier par ennemi**, sprite compris | Uniformité avec les classes ; le roster est appelé à grossir |
| D4 | **`passives/` à plat**, sans appartenance de classe | `PassiveData` n'a pas de `heroClass` : l'injection serait un no-op silencieux. Et **P-41 refait entièrement les passifs** |
| D5 | **Le répertoire injecte, le JSON peut confirmer, la contradiction échoue** | Migration mécanique, contradiction impossible. Tolérance à expiration, §5.2 |
| D6 | **La purge `skills.json` sort du périmètre** : c'est P-40 | P-40 est chartré, chiffré, et couvre la chaîne complète, sauvegarde comprise |
| D7 | **La section `assets:` du pubspec est générée** | Corollaire de D2/D3 : le nombre de lignes devient variable |
| D8 | **La réorganisation précède le devtool d'édition** | Le devtool devient trivial une fois la structure en place |
| D9 | **Les ids de passifs sont renommés en `snake_case`, et la casse des sauvegardes est acceptée** | Le jeu est en alpha ; aucune sauvegarde en circulation ne justifie une migration de schéma. Voir §3.3 |
| D10 | **`class.json` gagne un champ `displayOrder`** | L'ordre d'affichage des classes est une donnée de présentation ; sa place est dans la donnée, et ça reste vrai quand P-42 ajoutera des classes |
| D11 | **`PassiveData.fallback()` est supprimé au lot 1** | Même motif et même lot que les trois replis d'images : un passif introuvable est un bug, pas un cas à masquer. Le supprimer **avant** le lot 2 est aussi ce qui évite que le renommage traverse un `fallback('regenArmor')` codé en dur (`run_controller.dart:217`) |

### 3.1 Le prérequis P-40 est levé

`ROADMAP.md:396-399` charte P-40 en trois blocs. **Seul le bloc 1 — la suppression de la chaîne
`skills.json` — conditionnait ce chantier, et il est livré** : commit `ced306e`, 34 fichiers,
+49/−544, `dart analyze` propre et 377 tests au vert.

Ont disparu : `assets/data/skills.json`, `SkillData`, `SkillState`, `SkillController`, les deux
`executeSkill`, le callback `onExecuteSkill` et son branchement, les trois appels de cooldown, et le
champ `'skills'` de la sauvegarde. Sont délibérément conservés `applyLifestealBuff`
(`player_stats_manager.dart:475`, sans appelant, réservée à P-41) et `HeroData.skills`, homonyme
sans rapport qui porte les ids des cartes de signature d'une classe.

> **Aucune migration de sauvegarde n'a été nécessaire, contrairement à ce que cette spec annonçait.**
> Le piège supposé — `json['skills'] as Map<String, dynamic>` est un cast non-nullable, donc retirer
> la clé ferait lever la lecture et le `catch` appellerait `clear()` — ne se déclenche que si l'on
> retire l'écriture sans la lecture. Les trois lignes de `save_service.dart` étant parties ensemble,
> une sauvegarde existante conserve une clé `'skills'` simplement jamais relue ; `_schemaVersion`
> reste à 1. Un test épingle la garantie : *« a save still carrying a "skills" key loads without
> error »*.

**Restent ouverts dans P-40**, sans lien avec ce chantier : le bloc 2 (trois bugs confirmés — rune
`enduring`, duplication des cartes `unique`, écart de capacité de forge) et le bloc 3 (dix dérives
documentaires).

### 3.2 Le découpage en lots

| Lot | Contenu | Dépend de | Nature |
|:---|:---|:---|:---|
| **0** | **P-40** — purge de la chaîne `skills.json` | rien | prérequis |
| **1** | Les **quatre** replis codés en dur : chargeur en doublon, `state_sync_system:42`, `enemy_card:73`, `PassiveData.fallback()`. Propriété de préchargement sur le registre et son passage au constructeur de `HerosDraftGame` | rien | correctif |
| **2** | Tris explicites, suppression des trois replis `.first` et du repli silencieux de `hero_skills_link`. **Changements de contenu** : renommage des ids de passifs, ajout de `displayOrder` | rien | correctif |
| **3** | La migration : découpage, chargeur générique, dossiers, pubspec généré | 1 et 2 | migration |

**Le lot 1 embarque la propriété de préchargement et la modification de `game_screen.dart`.** Sans
elles il ne compile pas : supprimer le chargeur en doublon oblige à fournir la liste autrement. La
donnée est disponible — le provider est résolu par `SplashScreen` avant qu'on atteigne `GameScreen`,
et `game_screen.dart:73, 150, 236` lisent déjà le registre ainsi en corps de méthode. À ce stade le
préfixe Flame vaut encore `assets/images/`, donc la liste dérivée de `registry.heroes.iconPath` et
`registry.enemies.spritePath` produit exactement les mêmes noms nus que la liste en dur qu'elle
remplace : le lot 1 est à comportement constant.

**Le lot 2 porte les deux seuls changements de contenu du chantier** (D9, D10). Ils doivent précéder
la prise de référence de l'oracle (§8.2), qui apparie les entités par `id` : les faire pendant la
migration mettrait l'oracle en défaut et ruinerait la promesse « migration à contenu constant ».

Le lot 2 doit aussi précéder le tri par `id` du lot 3 : livré avant, il retire à §5.3 toutes ses
« conséquences assumées » au lieu de les documenter.

### 3.3 La casse de sauvegarde assumée (D9)

`run_controller.dart:126-127` persiste `passiveTrait` et `activePassiveId`. Après le renommage,
`PassiveData.getById('regenArmor')` rend `null` et le run rechargé n'a plus de passif. Avec la
suppression de `fallback()` (D11), `trait_system.dart:11-12, 37-38, 53-54` doit traiter le passif
absent comme **absence de passif** — aucun effet appliqué — et non comme un objet dégradé.

Le mécanisme de signalement existe déjà : `RunState.fromJsonWithReport` remonte un
`MissingSaveItem` de catégorie `passive`, que `home_screen.dart` affiche. Le joueur est donc averti.
**Cette casse est acceptée : le jeu est en alpha.** Aucune migration de schéma n'est écrite.

---

## 4. Architecture cible

```
assets/
    data/
        patch_notes.json                  ← reste à plat (agent-managed, 5 scripts + le site en dépendent)
        audio.json                        ← reste à plat (document de configuration, pas un catalogue)

        cards/            <id>.json       ← le socle neutre — 17 aujourd'hui, ~8 après P-42
        relics/           <id>.json       ← 25
        events/           <id>.json       ← 5
        forge_upgrades/   <id>.json       ← 8
        passives/         <id>.json       ← 3, à plat (D4)

        classes/
            paladin/
                class.json                ← HeroData + displayOrder (D10)
                icon.png
                cards/     <id>.json      ← pool de classe + cartes de signature
            berserker/    …
            mage/         …

        enemies/
            slime/
                enemy.json
                sprite.png
            gobelin/  …  squelette/  …  orc/  …

    images/
        bg_dungeon.png                    ← seul rescapé : n'appartient à aucune entité
    audio/
        sfx/  …  music/  …                ← inchangés
```

**Règle de partage** : un fichier de `assets/data/` est **découpé** s'il est un *catalogue d'entités
interchangeables* ; il **reste à plat** s'il est un *document de configuration unique*.
`patch_notes.json` et `audio.json` tombent du second côté — pour le premier, l'ordre du tableau
*est* la sémantique (index 0 = version courante), et cinq scripts de `.github/scripts/` plus
`site/_site/js/model.js` en dépendent. `assets/data/` reste donc déclaré, pour ces deux fichiers.

> Les noms de dossiers d'ennemis suivent les ids, qui sont français (`gobelin`, `squelette`), alors
> que les sprites sont anglais (`enemy_goblin.png`). Le nom fixe `sprite.png` efface l'incohérence —
> mais le script de découpage **renomme** les images, il ne fait pas que les déplacer (§8.1).

### Décompte cible

**73 fichiers JSON** — 71 fichiers d'entité (17 + 25 + 5 + 8 + 3 + 3 `class.json` + 6 cartes de
classe + 4 `enemy.json`) plus `patch_notes.json` et `audio.json`. Le chargeur en lit **72** au
démarrage (71 entités + `audio.json`), contre 9 aujourd'hui.

**19 lignes d'assets** au pubspec, croissant de **+2 par classe** et **+1 par ennemi**.

---

## 5. Le mécanisme de chargement

### 5.1 Le chargeur

Trois objets, conçus ensemble pour couvrir les huit catégories, la fusion, l'agrégation d'erreurs et
le test.

**Le motif de chemin porte la sélection *et* l'injection.** Un `*` vaut exactement un segment ; les
segments capturés alimentent l'injection.

| Catégorie | Motif | Capture |
|:---|:---|:---|
| Cartes neutres | `assets/data/cards/*.json` | id |
| Cartes de classe | `assets/data/classes/*/cards/*.json` | **classe**, id |
| Reliques, events, forge, passifs | `assets/data/<cat>/*.json` | id |
| Classes | `assets/data/classes/*/class.json` | id |
| Ennemis | `assets/data/enemies/*/enemy.json` | id |

Ce motif est ce qui manquait : `startsWith('assets/data/classes/')` capterait à la fois
`paladin/class.json` et `paladin/cards/holy_shield.json`. Le comptage de segments les sépare, et il
filtre du même coup les assets de paquets en `packages/<nom>/…`.

```
class EntitySource<T> {
  final String pattern;                                  // '*' = un segment
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(List<String> caps)? inject;
}

class GameDataLoader {
  GameDataLoader(this.bundle);                           // ← le seam de test
  final AssetBundle bundle;

  Future<void> prepare();                                // charge le manifeste UNE fois
  Future<List<T>> loadAll<T>(List<EntitySource<T>> sources);
  void throwIfFailed();                                  // lève une fois, à la fin
}
```

Trois propriétés que la signature précédente ne pouvait pas offrir :

- **La fusion est interne.** `loadAll` prend une **liste** de sources, concatène, trie par `id` puis
  vérifie l'unicité. `registry.cards` se déclare ainsi, et le contrôle d'unicité §10 reste dans le
  chargeur au lieu d'être délégué à l'appelant :
  ```
  cards = await loader.loadAll<CardData>([
    EntitySource('assets/data/cards/*.json',            CardData.fromJson,
                 inject: (_) => {'category': 'global'}),
    EntitySource('assets/data/classes/*/cards/*.json',  CardData.fromJson,
                 inject: (c) => {'heroClass': c[0], 'category': 'characterSpecific'}),
  ]);
  ```
- **Les erreurs s'accumulent dans l'objet**, pas dans la valeur de retour, ce qui permet de les
  collecter **à travers les catégories** avant de lever une fois (§5.4).
- **`bundle` est un paramètre.** `AssetManifest.loadFromAssetBundle` en accepte un : les trois tests
  de §10 qui supposent un bundle différent du vrai (autorité du répertoire, agrégation, catégorie
  vide) deviennent écrivables sans fabriquer d'`AssetManifest.bin` ni polluer le bundle de l'app.

`gameDataLoaderProvider` reste l'entrée publique et instancie `GameDataLoader(rootBundle)`.
`_loadJsonList` et `_mapList` disparaissent — `loadAudioData` n'en utilise aucun.

> **Note pour P-26.** `ROADMAP.md:387` prévoit `GameDataRegistry` en `Map` O(1) pour supprimer les
> quatre recherches linéaires des `getById`. Le chargeur construisant déjà les collections, les
> produire en `Map<String, T>` coûte peu ici. À trancher à l'écriture du plan.

### 5.2 L'autorité du répertoire — option C

| Emplacement | Champs injectés |
|:---|:---|
| `classes/<id>/cards/*.json` | `heroClass: <id>`, `category: characterSpecific` |
| `cards/*.json` | `category: global` |
| `classes/<id>/class.json` | `id: <id>` *(segment capturé)* |
| `enemies/<id>/enemy.json` | `id: <id>` *(idem)* |

**Règle de conflit** : si le JSON déclare un champ injecté, la valeur **doit** être identique ; sinon
le chargement échoue en nommant le fichier, le champ, la valeur attendue et la valeur trouvée.

Le périmètre est volontairement limité aux cartes et aux ids. Les passifs en sont exclus (D4) :
`PassiveData` n'ayant pas de `heroClass`, une injection y serait jetée par `fromJson` — un no-op
qu'aucun test ne pourrait détecter.

**Expiration.** La tolérance « le JSON peut confirmer » sert **pendant** la migration, où elle laisse
passer tels quels les `category` des 17 cartes neutres et les `heroClass` + `category` des 6 cartes
de classe. Une fois la migration fusionnée, la règle se durcit : déclarer un champ injecté devient
une erreur, ce qui impose de **dépouiller ces 23 fichiers**. C'est une tâche du lot 3, budgétée
en §14 — sans elle, chaque carte de P-42 porterait deux champs redondants que le chargeur écrase.

### 5.3 Ordre déterministe

Le tri se fait **par `id` après parsing**, jamais sur l'ordre du manifeste, qui n'offre aucune
garantie (`asset_manifest.dart:115`). C'est la seule règle qui donne le même résultat depuis le
bundle et depuis le disque.

**Le lot 2 rend ce tri sans conséquence** en traitant les six surfaces où l'ordre d'une liste du
registre est aujourd'hui observable :

| Surface | Aujourd'hui | Correctif du lot 2 |
|:---|:---|:---|
| `card_dictionary_screen.dart:87-96` | Ordre **des groupes** = première apparition du type ; intra-groupe = ordre du catalogue | Itérer `CardType.values` pour les groupes, trier par rareté/coût/id dedans |
| `card_dictionary_screen.dart` onglet reliques | Groupes pré-amorcés par `RelicRarity.values`, intra-groupe suit le catalogue | Tri explicite intra-groupe |
| `class_selection_screen.dart:24, 61` | `gameData.heroes` indexé — l'ordre est celui du JSON | Tri par **`displayOrder`** (D10) |
| `starter_deck_draft_screen.dart:54-61` | Pool filtré **sans mélange**, sélectionné par index | Tri explicite par rareté/coût/id |
| `state_sync_system.dart:46`, `stats_dialog.dart:43`, `relic_exchange_screen.dart:144` | `orElse: () => liste.first` | **Replis supprimés** |
| `hero_skills_link.dart:9-11` | `matches.first`, puis `.whereType<CardData>()` avale l'absence | Repli supprimé ; une carte de signature manquante devient une erreur |

Reste une conséquence assumée : `relic_exchange_screen.dart:125` **recalcule** la relique offerte à
chaque affichage. Une run reprise après migration verra une autre relique au même nœud — non parce
que la sauvegarde la mémorise, mais parce qu'elle ne la mémorise pas. *(Le correctif propre — tirer
un `id` plutôt qu'un index — est hors périmètre.)*

### 5.4 Agrégation des erreurs

`_mapList` lève aujourd'hui à la **première** entrée fautive (`game_data_service.dart:28-50`). Avec
72 fichiers, corriger une faute par cycle de rebuild serait invivable. `GameDataLoader` accumule
donc les erreurs de toutes les catégories, et `throwIfFailed()` lève une fois à la fin.

**Contrat précis :**
- Une entité dont `fromJson` lève est **exclue** de la liste ; le tri s'applique au reste. Le
  chargement va jusqu'au bout pour collecter, puis lève avant de rendre le registre.
- Le message est **tronqué à 10 fichiers** suivis de `… et N autres`. `gameDataLoaderProvider` est un
  `FutureProvider` dont l'erreur atterrit dans des `Text('Erreur de chargement: $err')` non
  scrollables (`relic_exchange_screen.dart:118`) : 72 lignes y seraient illisibles. La liste complète
  part dans `debugPrint`.
- **L'audio reste exempté** : `loadAudioData` ne lève jamais et conserve ce comportement.

### 5.5 La liste de préchargement

Le registre expose la liste des chemins d'images référencés par les entités chargées (icônes de
classes, sprites d'ennemis). C'est un **getter calculé** sur `heroes` et `enemies`, non un champ de
constructeur : 18 sites de `test/` construisent `GameDataRegistry(...)`, qu'un champ requis casserait
tous.

**L'ordonnancement, qui est la vraie difficulté.** `availableEnemies` et `availableHeroes` sont
affectés dans `build()` (`game_screen.dart:417-418`), soit **après** que `onLoad()` a préchargé — ce
qui est précisément pourquoi le chargeur en doublon existe. La liste est donc **passée au
constructeur de `HerosDraftGame`** (`game_screen.dart:254`), comme `audio:` l'est déjà à `:255`. La
donnée y est disponible : `SplashScreen` a résolu le provider, qui n'est pas `autoDispose`.

---

## 6. Le contrat de données

### 6.1 Convention de nommage

- Le nom du fichier **est** l'`id` : `relics/iron_talisman.json` contient `"id": "iron_talisman"`.
- **Exception** : les fichiers à nom fixe (`class.json`, `enemy.json`) tirent leur `id` du
  **répertoire parent**, injecté par le chargeur (§5.2). Le test de §10 porte cette dérogation.
- **Les ids sont en `snake_case` ASCII minuscule.** Le poste de développement est Windows (NTFS
  insensible à la casse), la CI est `ubuntu-latest`, les cibles web/Android sont sensibles à la
  casse : un fichier commité avec une casse divergente passe en local et échoue en CI, et un
  renommage de pure casse est invisible pour git sous Windows. Les trois passifs
  (`regenArmor`, `berserkerArmor`, `spellArmor`) deviennent `regen_armor`, `berserker_armor`,
  `spell_armor` — ce qui touche `heroes.json:passiveTrait` et ~20 fichiers de `test/` qui portent
  ces ids en dur. **Renommage et test de convention appartiennent au lot 2** (§3.2), avec la casse de
  sauvegarde assumée en §3.3.
- Un JSON d'entité contient **un objet**, pas un tableau.

### 6.2 Le préfixe d'images Flame

Les images vivant sous `assets/data/`, le préfixe `assets/images/` par défaut ne convient plus.

**`HerosDraftGame` se donne sa propre instance `Images(prefix: '')`**, affectée dans le corps de son
constructeur — `FlameGame` n'accepte pas `images` en paramètre (`flame_game.dart:43-46`), mais
`Game.images` est un champ mutable (`game.dart:28`). Muter `Flame.images` en place changerait le
préfixe pour tout consommateur du processus, **et cette mutation survit d'un test widget à l'autre
dans le même isolate**, rendant les tests dépendants de leur ordre.

> **Le préfixe vide n'est pas un confort, c'est la seule option sûre.** `images.dart:29-32` :
> *« le préfixe ne fait pas partie des clés du cache »*. Charger `icon.png` sous le préfixe
> `assets/data/classes/paladin/` le stockerait sous la clé `icon.png` — et le `icon.png` du mage
> **écraserait** le sien. Avec `prefix: ''` et des chemins complets, le chemin *est* la clé, et la
> collision est structurellement impossible.

| Fichier | Ligne | Lot | Aujourd'hui | Cible |
|:---|---:|:---:|:---|:---|
| `heros_draft_game.dart` | 133 | 3 | `'bg_dungeon.png'` | `'assets/images/bg_dungeon.png'` |
| `heros_draft_game.dart` | 172 | 3 | `images.fromCache('bg_dungeon.png')` | idem |
| `heros_draft_game.dart` | 170 | — | `images.loadAll(uniqueImages)` | inchangé — consomme la liste du registre |
| `state_sync_system.dart` | 42 | 1 | `'hero_paladin.png'` *(repli)* | **repli supprimé** |
| `enemy_card.dart` | 73 | 1 | `'enemy_goblin.png'` *(repli)* | **repli supprimé** |
| `enemy_card.dart` | 76 | 3 | `game.images.load(spriteName)` | inchangé, `spriteName` devient complet |
| `hero_card.dart` | 114 | 3 | `game.images.fromCache(imagePath)` | inchangé, `imagePath` devient complet |

Recherche exhaustive sur `images.load|fromCache|loadAll|Sprite(|AssetImage|Image.asset|.prefix` dans
`lib/` **et** `test/` : aucun autre site, et aucun chargement d'image dans `test/`.

Dans les données, `iconPath` et `spritePath` portent le chemin complet : l'entrée devient
auto-descriptive.

### 6.3 Bilinguisme et schémas

Toute entrée à texte visible garde ses variantes `_fr` et `_en`.

**Un seul schéma est modifié : `HeroData` gagne `displayOrder` (D10).** C'est une donnée de
présentation, dont la place est dans la donnée plutôt que dans une liste d'ids codée en dur qui
exigerait une édition de code à chaque nouvelle classe — soit exactement l'anti-pattern que le lot 1
supprime. L'ajout appartient au lot 2, avec les autres changements de contenu. Aucun autre modèle
n'est touché : c'est ce que garantit la révision de D4, qui a écarté une injection `heroClass` sur
`PassiveData` faute de champ pour la recevoir.

---

## 7. La synchronisation du pubspec

Les déclarations d'assets n'étant récursives à aucun niveau, chaque dossier de classe et d'ennemi
exige sa ligne. Le mode de défaillance est asymétrique, et c'est le pire des deux qui est probable :

- **Répertoire déclaré mais absent** — `asset.dart:1173-1176` journalise
  `Error: unable to find directory entry in pubspec.yaml` puis `return;` : **bruyant, non fatal**.
- **Répertoire présent mais non déclaré** — aucun message. Le contenu **se charge en développement**
  et **disparaît en build.** C'est celui-là qu'il faut couvrir.

Deux réponses complémentaires :

- **`tool/sync_assets.dart`** — le répertoire `tool/` est à créer. Le script parcourt `assets/`,
  régénère la section `assets:` triée, préserve le reste du fichier, et accepte un drapeau
  `--check` qui sort en code 1 si le pubspec diverge. N'émet que les répertoires **existants et non
  vides** ; symétriquement, une catégorie absente du manifeste rend une liste vide côté chargeur.
  Le test de §10 l'invoque par `Process.run('dart', ['run', 'tool/sync_assets.dart', '--check'])` —
  un fichier hors `lib/` n'étant pas importable par `package:`.
- **Un test qui charge par le vrai bundle** — sous `flutter test`,
  `AssetManifest.loadFromAssetBundle(rootBundle)` puis assertion du nombre de `.json` par catégorie.
  C'est le **seul** test qui prouve que l'application voit les fichiers : comparer le générateur au
  pubspec ne prouve rien, les deux parcourant le disque. Il attrape la ligne oubliée, la faute de
  frappe de chemin **et** la casse.

`flutter test` construit le bundle par défaut (`test.dart:412, 486-489`), ce que
`test/unit/audio/load_audio_data_test.dart` exerce déjà. *Hypothèse gardée : la CI lance
`flutter test` nu ; `--no-test-assets` ferait échouer ces tests.*

Créer une classe devient : créer le dossier, lancer le script. Le devtool appellera le même script.

---

## 8. Migration

### 8.1 Le script de découpage

Un script jetable, **non conservé** (`tool/` ne garde que `sync_assets.dart`) : il lit les catalogues,
écrit un fichier par entité au bon emplacement, **déplace et renomme** les images
(`enemy_goblin.png` → `enemies/gobelin/sprite.png`, `hero_paladin.png` →
`classes/paladin/icon.png`), et supprime les anciens fichiers.

`hero_cards.json` → dossiers de classe, sur le champ `heroClass`, présent sur les 6 entrées.
`passives.json` → `passives/` à plat, **sans renommage** : les ids sont déjà en `snake_case` depuis
le lot 2.

> **`flutter clean` est obligatoire après le découpage.** `_needsRebuild` (`test.dart:817-843`) ne
> détecte pas les suppressions (TODO explicite, flutter#128563) : les 8 catalogues supprimés peuvent
> survivre dans `build/unit_test_assets/`.

### 8.2 Le filet de sécurité

C'est le point le plus important du chantier, et son oracle doit être **le JSON brut**.

1. **Après le lot 2, avant le lot 3** : pour chaque catégorie, `jsonDecode` de l'ancien catalogue →
   liste de `Map` triée par `id`, figée dans un fichier de référence commité. La référence est prise
   après les deux changements de contenu du lot 2 (D9, D10), faute de quoi l'appariement par `id`
   échouerait sur les trois passifs.
2. Après migration : `jsonDecode` de chaque nouveau fichier, application de l'injection, tri par
   `id`, comparaison clé par clé.

**Aucun modèle Dart dans la boucle.** Comparer des `Map` produites par `toJson()` serait
auto-référentiel : un champ lu par `fromJson` et omis par `toJson` est invisible **des deux côtés du
diff**. Ce n'est pas théorique — `CardData.toJson()` (`:134-151`) omet déjà `sfx` que `fromJson:123`
lit. Aucune carte ne porte `sfx` aujourd'hui, mais **P-47 « seconde passe audio » est le chantier
ouvert** et son objet est de sonoriser du contenu : la fenêtre où l'angle mort devient une perte
réelle est exactement celle de la migration.

Corollaire : **les cinq `toJson()` qu'il aurait fallu écrire** (`RelicData`, `HeroData`,
`PassiveData`, `EnemyData`, `EventData` — les seuls modèles qui n'en ont pas) **sortent du
périmètre**. Ils restent un prérequis du devtool d'édition, qui les paiera avec ses propres tests de
round-trip.

> **Piège du singleton.** `GameDataRegistry` fait `_instance = this` dans son constructeur
> (`:36`), et les quatre `getById` lisent ce global. Tout test construisant deux registres écrase
> silencieusement le premier. L'oracle en JSON brut n'instancie aucun registre — mais tout autre test
> de la migration doit s'en méfier, en particulier le passage de `buildTutorialTestRegistry` au vrai
> chargeur.

Le test d'équivalence est supprimé une fois la migration fusionnée.

---

## 9. Ce qui casse — inventaire

| Fichier | Ligne | Lot | Nature de la rupture |
|:---|---:|:---:|:---|
| `lib/game/heros_draft_game.dart` | 133-172 | **1, 3** | Lot 1 : second chargeur supprimé, liste reçue au constructeur. Lot 3 : chemins `bg_dungeon` complets |
| `lib/models/data/game_data_registry.dart` | — | 1 | Getter de préchargement calculé sur `heroes`/`enemies` |
| `lib/ui/screens/game_screen.dart` | 254 | 1 | Liste de préchargement passée au constructeur |
| `lib/game/systems/state_sync_system.dart` | 42, 46 | 1, 2 | Repli d'image en dur, puis repli `.first` |
| `lib/game/components/entities/enemy_card.dart` | 73 | 1 | Repli d'image en dur supprimé |
| `lib/models/data/passive_data.dart` | 67-120 | 1 | `fallback()` **supprimé** (D11) — **7 points d'appel dans 5 fichiers** |
| `lib/game/systems/trait_system.dart` | 12, 38, 54 | 1 | Passif absent = aucun effet, plus d'objet dégradé |
| `lib/game/controllers/run_controller.dart` | 170, 217, 250 | 1 | Chargement de sauvegarde, état initial, démarrage de run |
| `lib/ui/widgets/map/dialogs/stats_dialog.dart` | 60 | 1 | Affichage du passif |
| `lib/ui/screens/class_selection_screen.dart` | 24, 61, 156 | 1, 2 | Usage de `fallback()` retiré ; tri par `displayOrder` |
| `lib/ui/screens/card_dictionary_screen.dart` | 87-96 | 2 | Groupes via `CardType.values` + tri intra-groupe |
| `lib/ui/screens/starter_deck_draft_screen.dart` | 54-61 | 2 | Tri explicite du pool |
| `lib/ui/widgets/map/dialogs/stats_dialog.dart` | 43 | 2 | Repli `.first` supprimé |
| `lib/ui/screens/relic_exchange_screen.dart` | 144 | 2 | Repli `.first` supprimé |
| `lib/models/data/hero_skills_link.dart` | 9-11 | 2 | Repli silencieux supprimé |
| `lib/models/data/hero_data.dart` | — | 2 | Champ `displayOrder` (D10) |
| `assets/data/passives.json` + `heroes.json` | — | 2 | Ids renommés, `displayOrder` ajouté |
| ~20 fichiers de `test/` | — | 2 | Ids de passifs en dur à mettre à jour |
| `lib/services/game_data_service.dart` | 15-50, 78-116 | 3 | `_loadJsonList`/`_mapList` supprimés ; `GameDataLoader` |
| `lib/game/components/entities/enemy_card.dart` | 76 | 3 | Dépend du préfixe vidé |
| `lib/game/components/entities/hero_card.dart` | 114 | 3 | Dépend du préfixe vidé |
| 23 fichiers de cartes | — | 3 | `heroClass`/`category` dépouillés au durcissement (§5.2) |
| `test/tutorial/tutorial_test_registry.dart` | 11-36 | 3 | Passe par le vrai chargeur ; devient **asynchrone** |
| 3 tests du tutoriel | — | 3 | Construction déplacée de l'initialiseur `final` vers `setUpAll` |
| `assets/data/*.json` | — | 3 | Catalogues supprimés, 71 fichiers d'entité créés |
| `assets/images/hero_*.png`, `enemy_*.png` | — | 3 | Déplacés **et renommés** |
| `pubspec.yaml` | 30-34 | 3 | Section `assets:` régénérée, 4 → 19 lignes |
| `tool/sync_assets.dart` | — | 3 | Nouveau, avec `tool/` |

---

## 10. Tests

| Test | Lot | Ce qu'il garantit |
|:---|:---:|:---|
| **Liste de préchargement** | 1 | Toute icône de classe et tout sprite d'ennemi déclaré y figure |
| **Passif absent** | 1 | Un `passiveTrait` introuvable n'applique aucun effet et remonte un `MissingSaveItem` |
| **Tris explicites** | 2 | Dictionnaire, sélection de classe et draft de départ ont un ordre indépendant du catalogue |
| **Convention de casse** | 2 | Tout id est en `snake_case` ASCII minuscule — livré avec le renommage qu'il protège |
| **Carte de signature manquante** | 2 | `hero_skills_link` échoue au lieu d'avaler l'absence |
| **Chargement par le vrai bundle** | 3 | `AssetManifest` sous `flutter test` voit le bon nombre de `.json` par catégorie. Le seul qui couvre la ligne de pubspec oubliée |
| **Équivalence de migration** *(temporaire)* | 3 | JSON brut avant ≡ JSON brut après, clé par clé |
| **Nom de fichier = `id`** | 3 | …**sauf** `class.json` et `enemy.json`, dont l'id vient du répertoire parent (§6.1) |
| **Unicité des `id` après fusion** | 3 | `registry.cards` agrège deux sources : l'unicité se vérifie sur la liste fusionnée, dans le chargeur |
| **Autorité du répertoire** | 3 | Un `heroClass` contradictoire fait échouer le chargement. Écrit sur un `AssetBundle` de test (§5.1) |
| **Intégrité référentielle** | 3 | `passiveTrait` désigne un passif existant ; chaque id de `HeroData.skills` désigne une carte de `classes/<id>/cards/` ; `icon.png` et `sprite.png` existent. **Sans lui, §2.2 n'est pas résolu** : un dossier incomplet est aussi silencieux qu'une entrée manquante |
| **Agrégation des erreurs** | 3 | Deux fichiers fautifs produisent **un** rapport listant les deux, tronqué à 10 |
| **Catégorie vide** | 3 | Un répertoire absent du manifeste rend une liste vide sans lever |
| **Pubspec synchronisé** | 3 | `dart run tool/sync_assets.dart --check` sort en 0 |
| **Isolation du tutoriel** *(existant)* | — | `test/tutorial/tutorial_isolation_test.dart` continue de passer |

**377 tests au vert et `dart analyze` à zéro problème** après chaque lot, conformément à `CLAUDE.md`.

---

## 11. Documentation et traçabilité

- **ADR neufs** : la règle de partage catalogue/configuration, et l'autorité du répertoire (option C
  avec expiration). Numérotation attribuée par la skill `memory-bank-sync`.
- **ADR-003 « Architecture 100 % Data-Driven » doit être amendé** : il énumère nommément les
  8 fichiers JSON et décrit un `GameDataService.loadAll()` qui n'existe déjà plus, et ses comptes
  sont déjà faux (15 cartes, 2 événements, 12 reliques). `CLAUDE.md` pose « One question, one
  place » : laisser ADR-003 décrire une structure abolie viole la règle plus sûrement que de ne rien
  écrire.
- **Fiche `_patterns/`** : `GameDataLoader`, `EntitySource` et le motif de chemin.
- **`.claude/skills/memory-bank-sync/SKILL.md:46`** : la métrique « Fichiers de données » est mesurée
  par `ls assets/data/*.json | wc -l`. Elle passe de 10 à **2**. La skill re-mesure avant d'écrire :
  sans correction de la commande, elle publiera un chiffre juste et trompeur.
- **`CLAUDE.md`** : « Data-Driven Content Workflow » décrit le fichier unique à éditer ; il faut
  décrire la création d'un fichier et l'appel au générateur. La liste des modèles de « Data layer »
  nomme `skill_data.dart`, supprimé par le bloc 1 de P-40 (`ced306e`).
- **`.agents/skills/game_designer.md:12`** : énumère les catalogues, `skills.json` compris.
- **`docs/INDEX.md`** : entrée sous « Héros, classes & cartes ». **`docs/ROADMAP.md`** : nouvelle
  fiche entre P-40 et P-41.
- **Patch note** : le joueur ne voit rien d'autre que la casse de sauvegarde de §3.3, qui relève d'un
  build alpha. Aucune entrée `patch_notes.json` n'est justifiée.

---

## 12. Hors périmètre

- **P-40 blocs 2 et 3** — trois bugs de gameplay et dix dérives documentaires, sans lien avec ce chantier. Le bloc 1, seul prérequis, est livré (§3.1).
- **Le devtool d'édition de contenu** — chantier suivant, accessible uniquement en `kDebugMode`.
- **P-30** (menu de triche) — chantier distinct, même s'il partagera une coquille `lib/devtools/`.
- **P-41 et P-42** — ce chantier construit l'infrastructure des pools par classe, il n'en écrit pas
  le contenu, et ne touche pas au modèle de passifs que P-41 refondra.
- **Toute migration de schéma de sauvegarde** — la casse de §3.3 est assumée (D9).
- **Le correctif « tirer un `id` plutôt qu'un index »** dans `relic_exchange_screen.dart`.
- **Toute modification d'équilibrage.** Aucune valeur de carte, de relique ou de héros ne change ;
  les deux seuls changements de contenu sont le renommage des ids de passifs et l'ajout de
  `displayOrder`, tous deux au lot 2 et antérieurs à la référence de l'oracle.

---

## 13. Risques

| Risque | Gravité | Mitigation |
|:---|:---:|:---|
| Perte silencieuse d'une entité ou d'un champ pendant la migration | **Élevée** | Oracle en JSON brut (§8.2), référence prise après le lot 2 |
| Répertoire présent mais non déclaré → contenu absent en build uniquement | **Élevée** | Le test de chargement par le vrai bundle (§7), pas le générateur seul |
| Bundle de test périmé masquant une suppression | Moyenne | `flutter clean` obligatoire (§8.1) |
| Le préfixe d'images fuit entre tests widget | Moyenne | Instance `Images` propre au jeu, jamais `Flame.images` (§6.2) |
| Un dossier de classe incomplet passe inaperçu | Moyenne | Test d'intégrité référentielle (§10) |
| Le passage de `buildTutorialTestRegistry` en asynchrone casse 3 tests | Moyenne | Construction déplacée en `setUpAll`, budgétée en §14 |
| Les runs en cours perdent leur passif | **Acceptée** | Décision D9, §3.3 — alpha |
| Coût de démarrage : 72 lectures de bundle au lieu de 9 | Faible | À **mesurer** avant fusion. Le bundle est mappé en mémoire ; les lectures sont parallélisables |
| Perte de la vue d'ensemble pour l'équilibrage | Faible | `jq -s '.' assets/data/relics/*.json` ; la vue liste du devtool jouera ce rôle |

---

## 14. Estimation

**6 à 7 jours**. Le prérequis P-40 bloc 1 est déjà livré et ne compte pas dans ce total.

| Lot | Contenu | Effort |
|:---:|:---|:---:|
| **1** | 4 replis en dur supprimés, getter de préchargement, passage au constructeur, comportement du passif absent | 1 j |
| **2** | Tris explicites (4 surfaces), 4 replis `.first`, renommage des ids + ~20 fichiers de test, `displayOrder` | 1 j |
| **3** | `GameDataLoader`, `EntitySource`, motif de chemin, injection, validation, agrégation | 1 j |
| **3** | Script de découpage (avec renommage d'images) + oracle JSON brut + exécution + vérification | 1 j |
| **3** | `tool/sync_assets.dart` + `--check` + test de chargement par le vrai bundle | 0,75 j |
| **3** | Préfixe Flame, instance `Images` propre, conversion des chemins | 0,5 j |
| **3** | `tutorial_test_registry` au vrai chargeur + passage asynchrone de 3 tests | 0,5 j |
| **3** | Dépouillement des 23 fichiers de cartes au durcissement de §5.2 | 0,25 j |
| **3** | ADR neufs, amendement ADR-003, fiches, ROADMAP, `CLAUDE.md`, métrique de la skill | 0,5 j |
