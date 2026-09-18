## 🧮 ADR-098 : Les Récompenses de Niveau en Donnée, Table Explicite et Gabarits à Trous (P-41, lot C, partie 1)

### Statut

✅ Accepté — chantier **P-41, lot C, partie 1**, fusionné dans `main` par la **PR #42**
(2026-09-18, merge `152fbcc`, `face77b`..`9a2f375`, 11 commits dont 10 de code).

Complète [ADR-085](ADR-085-regle-de-partage-catalogue-configuration.md) et
[ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) : la neuvième
source d'entités suit leur règle sans l'amender. Sera étendu par la **partie 2** du lot C,
qui ajoute un champ `requires` au modèle créé ici.

### Contexte

Les huit récompenses de montée de niveau étaient la dernière famille d'entités **écrite en
dur**. Elles vivaient en quatre morceaux dispersés :

- une énumération `LevelUpRewardType` à six valeurs, dont l'**ordre était la sémantique** —
  `rng.nextInt(6)` tirait un index, pas une récompense ;
- deux blocs codés en dur pour les mythiques, Trèfle et Miroir, hors de l'énumération ;
- **deux régimes de valeur coexistants** : un multiplicateur générique (`×1` / `×1,5` / `×2` /
  `×3` / `×4`) pour trois types, et une cascade de `if` par type pour les trois autres ;
- 17 clés ARB de libellés, plus des libellés **raccourcis à la main** dans le rouleau du
  carrousel, plus la liste des récompenses **recopiée en toutes lettres** dans la prose du
  tutoriel, dans les deux langues.

La coexistence des deux régimes de valeur avait déjà coûté un défaut réel : la cascade de
l'*Affinité* (alors *Forge d'Acier*) n'avait pas de palier légendaire et retombait sur `1`, la
valeur d'un commun — corrigé en `0.4.9`, après être passé inaperçu parce qu'aucune table
lisible n'existait à confronter au code.

Ajouter une récompense demandait donc de toucher une énumération, un tirage indexé, deux
cascades de valeurs, deux fichiers ARB, un rouleau et un texte de tutoriel.

### Décision

**Le catalogue de récompenses devient de la donnée, et le code ne connaît plus aucune
récompense par son nom.**

1. **Un fichier par récompense** sous `assets/data/level_up_rewards/<id>.json`, à plat — une
   récompense n'appartient à aucune classe. **Huit fichiers** : les six tirables *et* les deux
   mythiques, qu'un champ `pool` (`draft` / `mythic`) distingue. Les mythiques construites en
   dur auraient laissé la moitié du problème en place.
2. **Une table `values` explicite**, palier par palier. **Aucun multiplicateur ne survit en
   code** : les deux régimes concurrents disparaissent au profit d'un seul, et la table
   redevient lisible sans exécuter le tirage. *Férocité* écrit ses points de pourcentage en
   entiers (`10`), l'application divise par 100 — le catalogue écrit ce que le joueur lit.
3. **La description est un gabarit à trous**, pas un texte fini : `{amount}`, `{passive}` et
   `{effect}`. Le code connaît **ces trois noms et rien d'autre**. Composer l'*Affinité* avec
   le passif actif cesse d'être une branche par récompense pour devenir une règle unique, et
   une récompense future qui se décrit par le passif n'ajoute aucun `case`. Deux gabarits
   optionnels complètent : `fallbackDescription` (quand `{passive}`/`{effect}` ne peuvent pas
   être résolus) et `shortDescription` (le rouleau, qui n'a ni passif ni place).
4. **Le tirage ne lit plus l'ordre des fichiers** : `displayOrder` puis `id`, règle portée par
   `LevelUpRewardData.inPool` pour ses deux lecteurs. Un tirage indexé sur l'ordre de lecture
   du disque aurait été un piège silencieux.
5. **L'application du gain quitte l'écran de draft** pour `PlayerStatsManager`, où un `switch`
   **exhaustif** sur `RewardStat` fait rougir l'analyseur si une stat est ajoutée sans être
   appliquée. `DraftChoice` ne porte plus sept accumulateurs dont un seul était non nul, mais
   la récompense tirée, sa rareté et sa valeur.
6. **`RewardRarity` descend dans `lib/models/`** : `lib/models/data/` ne peut pas importer
   `lib/game/services/` sans inverser les couches. Précédent exact — `lib/models/might_target.dart`.
7. **La prose du tutoriel lit le registre** par une fonction pure, `fillRewardPlaceholders`,
   appelée au rendu par `TutorialScreen`, qui porte déjà `final GameDataRegistry data`.
   `kTutorialSteps` reste `const` et [ADR-081](ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md)
   tient : aucune nouvelle voie d'accès au registre depuis `lib/tutorial/`.

**Le jeu ne change pas.** Mêmes valeurs, mêmes probabilités, mêmes textes — seule la
*provenance* change. Les 30 combinaisons type × rareté sont verrouillées à valeurs identiques.

### Preuves dans le code

| Fait | Où le vérifier |
|:---|:---|
| Huit récompenses en donnée | `assets/data/level_up_rewards/` — 8 fichiers |
| Modèle, gabarits, tri de pool | `lib/models/data/level_up_reward_data.dart` (`RewardEffect`, `RewardStat`, `RewardPool`, `amountFor`, `reelAmount`, `inPool`) |
| Neuvième source d'entités | `lib/services/game_data_service.dart` — `grep -c 'EntitySource('` → **9** |
| `LevelUpRewardType` et `nextInt(6)` supprimés | `grep -rn 'LevelUpRewardType' lib/ test/` → **aucun résultat** |
| `DraftChoice` réduit à (récompense, rareté, valeur) | `lib/game/services/level_up_reward_service.dart:12-29` |
| `switch` exhaustif sur la stat visée | `lib/game/controllers/run/player_stats_manager.dart:73-97` |
| `RewardRarity` hors du service | `lib/models/reward_rarity.dart` |
| 17 clés ARB retirées | `grep -c 'draftChoice' lib/l10n/app_fr.arb` → **0** |
| Prose du tutoriel générée | `lib/tutorial/tutorial_prose.dart`, `test/tutorial/tutorial_prose_test.dart` |
| Valeurs verrouillées à l'identique | `test/unit/level_up_reward_values_test.dart`, devenu un test sur la donnée |
| Gardes du catalogue | `test/unit/level_up_rewards_catalog_test.dart`, `level_up_reward_data_test.dart`, `level_up_reward_apply_test.dart` |

**Vérifié le 2026-09-18** — **1065 tests** au vert (`flutter test`), `dart analyze` propre.

### Conséquences

**Ce que cela ouvre.** Une nouvelle récompense est désormais **un fichier**, sans une ligne de
code : c'est la condition de la partie 2 du lot C, dont le filtre d'*Affinité* n'ajoute qu'un
champ `requires` au modèle. Le lot D pourra apprendre cette catégorie à l'éditeur de contenu.

**Ce que cela coûte, assumé plutôt que découvert.**

1. **Une formulation du tutoriel change, dans les deux langues** — le seul texte joueur que
   cette partie modifie. La liste des mythiques perd ses articles (« le Trèfle à 4 feuilles et
   le Miroir » → « Trèfle à 4 feuilles et Miroir ») : le registre ne porte pas le genre d'un
   nom, et inventer un champ `article` pour deux noms coûterait plus que la perte. Le nom
   anglais du Trèfle s'aligne au passage sur celui de la carte de draft (`4-Leaf Clover`),
   une divergence d'orthographe antérieure à ce chantier qu'un fichier unique force à trancher.
2. **Le rouleau du carrousel montre les valeurs `rare`** au lieu de quatre chiffres écrits à la
   main. Ses cartes défilent en 140 ms et sont floutées : décor, pas information.
3. **Le nombre de fichiers d'entité passe de 77 à 85**, et deux tests le comptent nommément
   (`entity_id_convention_test.dart`, `real_bundle_load_test.dart`) — c'est leur raison d'être.
4. **L'éditeur de contenu ne sait pas éditer une récompense** jusqu'au lot D : le compte de
   catégories éditables reste à sept, seule la création à la main fonctionne.

> [!IMPORTANT]
> **Le rééquilibrage n'a pas été fait ici, et ne devait pas l'être.** *Sagesse* garde son
> plateau (1, 2, 2, 3, 4) : `round(1 × 1,5)` et `round(1 × 2,0)` donnaient tous deux 2, et le
> plateau est **recopié tel quel** dans sa donnée. Une table explicite rend ce plateau visible
> sans l'excuser — il appartient à **P-16**. Passer une valeur en donnée et l'ajuster dans le
> même geste aurait rendu indémontrable la promesse « le jeu ne change pas ».
