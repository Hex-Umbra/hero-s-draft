# P-41 lot D, partie 2 — La console rattrape l'identité de classe — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** L'outillage de développement rattrape les trois lots livrés : l'éditeur de contenu refuse `"mode": "convrt"` au lieu de le charger en silence, la création guidée d'une classe ne produit plus une classe sans aucun passif disponible, les huit récompenses de niveau deviennent une catégorie éditable au lieu d'être la seule source d'entités sans descripteur, et le menu de debug laisse régler l'orientation de la Puissance tout en affichant les règles de stat et le passif actif de la run.

**Architecture:** Trois des quatre tâches ne font que **déclarer** : le descripteur d'une classe apprend trois clés énumérées imbriquées (`statRules[].stat`, `[].mode`, `[].to`) dont le vocabulaire est lu sur `StatRule` lui-même — jamais recopié, comme `PassiveMastery.fields` avant lui —, et une huitième entrée de `kEntityDescriptors` suffit à rendre les récompenses éditables, le catalogue, les valeurs connues, le formulaire inféré et le test d'aller-retour étant tous pilotés par la table. La seule mécanique neuve est un `pendingIds` sur `EntityValidator` : une recette écrit désormais une classe **et** un passif qui la nomme, et le registre chargé au démarrage ne connaît pas encore cette classe — le commentaire de `_signatureCards` décrit exactement ce trou depuis P-30.

**Tech Stack:** Flutter / Dart 3.11, Riverpod 2 (`Notifier`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire le **§9.2** en entier, puis le §7.1 pour le vocabulaire de `statRules`, le §5.2 pour ce que la validation d'une liste de références protège, le §8.1 pour les récompenses de niveau, et le §10 pour ce que P-13 branchera derrière. La spec de P-30 lot 2 (`2026-09-06-menu-debug-lot-2-editeur-de-contenu-design.md`) porte la conception de l'éditeur.

**Passe de correction :** relu le **2026-09-20 sur `a270de4`**, chaque chemin, chaque numéro de ligne et chaque symbole vérifiés par commande contre le code de `main`, et la base de tests re-mesurée par un `flutter test` complet. Ce qui a changé : les deux numéros de ligne des comptes d'`entity_descriptor_test` (16 et 34, non 17 et 33), le chemin complet de `debug_hero_tab.dart` et la plage réelle de son champ « Puissance », le compte de `loadAll` dans la documentation de l'énumération, la dépendance de la tâche 3 au renommage de la tâche 2, l'identifiant de classe de la vérification manuelle, et les totaux de tests des tâches 2 à 5. La lecture « la liste de références est déjà livrée par P-49 » a été re-vérifiée et tient.

**Dépend de :** les lots A, B et C de P-41 et le chantier frère P-49, **tous fusionnés dans `main`** (PR #38, #39, #40, #41, #42, #43). Rien d'autre. La partie 1 du lot D — le tutoriel, spec §9.1, [plan](2026-09-20-p41-lot-d-partie-1-tutoriel.md) — est **indépendante** de celle-ci : le tableau « Pourquoi deux plans pour le lot D » de ce plan-là en donne les raisons. Les deux peuvent s'exécuter dans n'importe quel ordre, ou en parallèle. **Seul point de contact :** `lib/models/data/stat_rule.dart`, que cette partie enrichit de quatre membres et que la partie 1 se contente de lire. En cas de branches concurrentes, la fusion est un ajout pur, sans conflit de ligne.

## Global Constraints

- **Le jeu ne change pas du tout.** Aucune valeur, aucun texte joueur, aucun fichier d'`assets/data/` livré n'est modifié. Ce lot ne touche que de l'outillage : l'éditeur de contenu et le menu de debug, ce dernier n'étant monté qu'en `kDebugMode` **et** dans une run de debug (`DebugActions._allowed`, `debug_actions.dart:31-32`). Une modification d'un fichier de contenu observée pendant l'exécution est un défaut de ce lot.
- **Aucun vocabulaire du moteur n'est recopié dans un descripteur.** `kEntityDescriptors` lit les énumérations Dart réelles (`_names(CardType.values)`) ou une table exposée par le modèle (`PassiveMastery.fields`). `statRules` suit la même règle : ses trois vocabulaires sortent de `StatRule`, qui est déjà le seul endroit à les connaître (`stat_rule.dart:43-54`). **Écrire `['armor', 'mana']` dans `entity_descriptor.dart` est un défaut**, pas un raccourci : la liste et le parseur divergeraient au premier ajout.
- **`dart analyze` doit afficher `No issues found!`** à la fin de **chaque** tâche. La tâche 3 fait **volontairement** rougir l'analyseur d'abord : le `switch` exhaustif sur `EntityCategory` du validateur — `EntityValidator._registryIdsOf`, que la tâche 2 a extrait de `_idsOf` sous ce nom — ne compile plus dès qu'une valeur arrive sans son `case`. C'est le filet, pas un accident.
- **`flutter test` doit être entièrement vert à la fin de chaque tâche.** Point de départ **re-mesuré le 2026-09-20 sur `a270de4`** (`main`, après la fusion de la PR #43) : **1135 tests**, `dart analyze` propre. Les totaux annoncés tâche par tâche sont une **prévision arithmétique** à partir de ce chiffre, **non un rejeu** : un écart signale un test oublié ou dupliqué, à comprendre avant de continuer — jamais un nombre à réajuster à l'aveugle. **Si la partie 1 du lot D a été fusionnée entre-temps**, la base est 1156 : décaler toutes les prévisions de +21. Le détail, à vérifier tâche par tâche :

  | Tâche | Δ | Détail | Total |
  |:---|---:|:---|---:|
  | — | — | base mesurée | 1135 |
  | 1 | +7 | `stat_rule_vocabulary_test` 2 (nouveau fichier) ; `entity_descriptor_test` 1 ajout ; `entity_validator_test` 4 ajouts | 1142 |
  | 2 | +5 | `entity_validator_test` 2 ajouts ; `class_recipe_test` 3 pour 1 (+2) ; `content_editor_screen_test` 1 ajout | 1147 |
  | 3 | +4 | `entity_descriptor_test` 1 ajout (`pathOf`) ; `entity_validator_test` 2 ajouts ; **+1 engendré** par `shipped_entities_round_trip_test`, qui produit un test par descripteur (`for (final descriptor in kEntityDescriptors.values)`, ligne 71) | 1151 |
  | 4 | +3 | `debug_drawer_test` 3 ajouts | 1154 |

  Deux modifications ne changent **aucun** compte, et c'est voulu : le test « les sept types sont des boutons » est **renommé** en « les huit types » (tâche 3), et les deux comptes d'`entity_descriptor_test` sont **relevés**, non dédoublés.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas.
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart et les gabarits JSON de ce plan en contiennent.
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`). Les gabarits de descripteur écrits ici en portent, à la charge de `bilingualBases`.
- **`assets/data/` n'est modifié par aucune tâche.** Si `dart run tool/sync_assets.dart --check` rougit, c'est qu'un fichier de contenu a été créé par erreur — le retirer, pas régénérer le `pubspec.yaml`.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Ne toucher à **aucun fichier de `.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/` ou `_patterns/`** : ils appartiennent au skill `memory-bank-sync`, lancé après la fusion.
- Le code va sur la branche `feat/p41-lot-d-console`, jamais sur `main`. La documentation de cette partie — ce plan, celui de la partie 1, et leurs liens dans `docs/INDEX.md` et `docs/ROADMAP.md` — est **déjà commitée sur `main`** avant l'exécution. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.

## Ce que la spec demande et qui est **déjà livré**

Le §9.2 a été écrit avant P-49 ; l'un de ses quatre points de l'éditeur est tombé en chemin. Le vérifier au passage, ne pas le réécrire.

| Ce que le §9.2 demande | État sur `a270de4` |
|:---|:---|
| « **Passifs** : le descripteur […] valide `classes` comme une **liste de références vers des classes existantes**. […] la liste de références est **une extension à écrire** » | ✅ **Écrite par P-49.** `EntityDescriptor.referenceListKeys` existe (`entity_descriptor.dart:105-108`), le descripteur du passif la déclare (`:257-259`, `'classes': EntityCategory.heroClass`), `EntityValidator._references` l'implémente (`entity_validator.dart:339-368`) — liste vide refusée comprise —, et `FieldKind.referenceList` lui donne son widget (`field_kind.dart:36-38`). **Rien à faire** |
| « **Classes** : `statRules` est validé — `stat` et `mode` bornés aux vocabulaires du moteur, `to` à une cible valide » | ❌ **À faire** — tâche 1. Le descripteur le dit lui-même : « `statRules` n'y figure pas non plus, et n'est pas validé : la spec de P-41 place l'édition des règles de stat au lot D (§9.2) […] Seule la vue JSON brute l'atteint d'ici là » (`entity_descriptor.dart:367-370`) |
| « **Création guidée de classe** : la recette **garantit au moins un passif disponible** » | ❌ **À faire** — tâche 2. `ClassRecipe.toDrafts()` rend la classe et ses cartes, jamais un passif (`class_recipe.dart:56-80`). ⚠️ **L'invariant, lui, est déjà gardé au niveau du dépôt** : `test/unit/referential_integrity_test.dart:65`, « chaque classe a au moins un passif disponible ». Une classe créée depuis la console fait donc rougir la suite — ce qui est le bon signal, mais arrive trop tard : l'auteur a déjà écrit ses fichiers |
| « **Récompenses de niveau** : nouvelle catégorie éditable » | ❌ **À faire** — tâche 3 |
| « le réglage de Puissance […] gagne le choix des cibles de `mightTargets` ; la run affichée expose l'orientation de sa Puissance, ses règles de stat et son passif actif » | ❌ **À faire** — tâche 4 |

## Deux citations de la spec ont vieilli

1. **« Le compte des catégories déclarées change (`test/unit/content_editor/entity_descriptor_test.dart:30`). »** La ligne 30 est une ligne de **commentaire**, au milieu du second test. Les deux comptes du fichier, relus sur `a270de4` :
   - **ligne 16** — `expect(EntityCategory.values, hasLength(7))` : le compte des **catégories**. C'est celui-là qui change, **7 → 8** (tâche 3, step 1a).
   - **ligne 34** — `expect(declared, hasLength(9))` : le compte des **`EntitySource` déclarées**. Il **ne change pas** — la neuvième source, celle des récompenses, existe depuis le lot C. Le test le dit lui-même : « les récompenses de niveau ont leur source depuis P-41 lot C partie 1, mais pas encore de descripteur — la spec place leur édition au lot D (§9.2) ». Ce commentaire devient faux et est réécrit au step 1b, **sans toucher au nombre**.

   Relever le 9 serait le contresens exact : c'est **le descripteur** qui manquait, pas la source. Et le vérifier avant d'écrire : `grep -c 'EntitySource(' lib/services/game_data_service.dart` rend **9**, `grep -c 'loadAll' …` rend **8** — un appel à `loadAll` par catégorie, la carte étant la seule à y passer deux sources.
2. **« le réglage de Puissance, renommé mécaniquement à la partie 1 du lot B (`debug_hero_tab.dart:40-43`) »** — deux imprécisions, la seconde plus gênante que la première :
   - **Le chemin manque.** La spec ne donne que le nom de fichier ; il vit sous **`lib/ui/widgets/debug/tabs/debug_hero_tab.dart`**. C'est le seul de ce nom dans le dépôt (`git ls-files | grep debug_hero_tab`), mais toutes les tâches de ce plan le citent en entier.
   - **Le `DebugNumberField` entier va de la ligne 38 à la ligne 45** (`label: 'Puissance'` en 39, `s.copyWith(might: v)` en 43). Les lignes 40-43 de la spec tombent bien *dedans*, mais pas sur son ouverture : viser 38-45 pour insérer quoi que ce soit au-dessus ou en dessous du champ. Le voisin utile est le champ « Chance », lignes **46-53**.

## Décisions prises à la rédaction du plan

La spec tranche la conception ; six points d'implémentation restaient ouverts. Ils sont tranchés ici, et l'exécutant n'a pas à les rouvrir.

| # | Question | Décision | Pourquoi |
|:---|:---|:---|:---|
| **1** | D'où sort le vocabulaire de `statRules` pour le descripteur ? | De **`StatRule`**, par trois getters (`statNames`, `modeNames`, `targetNames`) qui exposent ses tables privées existantes | `_targets` mappe `'status:might'` sur `RuleTarget.statusMight` : `_names(RuleTarget.values)` rendrait `['statusMight']`, qui n'est pas ce qu'un `class.json` écrit. Le seul endroit qui connaît le vocabulaire **du fichier** est le parseur, et c'est exactement le précédent de `PassiveMastery.fields` (spec P-49, §3.3) |
| **2** | Le gabarit de classe porte-t-il une règle de stat ? | **Une liste vide, `"statRules": []`** — jamais une règle toute faite | Une règle au gabarit ferait naître **toute** classe créée en convertisseuse d'armure : un défaut par défaut. Une clé absente, elle, resterait invisible dans le formulaire (`inferFieldKind` ne voit que ce que le document porte) — l'auteur ne saurait pas qu'elle existe. La liste vide rend la clé visible, la validation s'y applique dès qu'une règle y est ajoutée, et les deux classes livrées sans règle restent le cas par défaut |
| **3** | La liste vide donne un champ « JSON brut » et non un formulaire. Acceptable ? | **Oui, pour ce lot.** Le §9.2 demande une **validation**, et c'est elle qui ferme le trou `"convrt"`. Une classe **livrée** qui porte déjà une règle (le Berserker) obtient, elle, un vrai formulaire : sa liste est non vide, donc `FieldKind.objectList` | Un formulaire pour une liste vide exigerait un **élément-modèle découplé du gabarit** : `EditorDocument.modelElementFor` lit le gabarit puis le document (`editor_document.dart:69-81`), et le gabarit porterait alors la règle que la décision 2 refuse. C'est un champ de descripteur à part entière, hors périmètre — porté aux suites |
| **4** | Comment la recette garantit-elle un passif ? | Elle écrit **un troisième brouillon** : un passif dont l'identifiant est celui de la classe, portant `"classes": ["<id>"]`, sa prose remplie par `fillPlaceholders` | C'est ce pour quoi `ClassRecipe` existe : « Ce que la recette apporte n'est pas le lien […] mais **l'atomicité et l'ordre** » (`class_recipe.dart:22-25`). Elle dérive déjà `iconPath` de l'identifiant ; un passif de départ dérivé de la même façon suit la même doctrine. L'auteur le renomme ensuite comme n'importe quelle entité, et `[À REMPLIR] <id>` le lui rappellera |
| **5** | Le validateur refuse ce passif : le registre chargé au démarrage ne connaît pas la classe qu'il nomme. Comment passer ? | `EntityValidator` gagne `pendingIds` — `Map<EntityCategory, Set<String>>`, les identifiants que **la même transaction** va écrire —, uni à `_idsOf`. `_judge` y verse l'identifiant de la classe de la recette | Le trou est décrit mot pour mot dans le code depuis P-30 : « les cartes que la recette vient d'écrire ne sont pas dans le registre chargé au démarrage, et un contrôle par référence refuserait la sortie même de l'outil » (`entity_validator.dart:459-461`) — ce dont `_signatureCards` se protégeait en **n'étant pas** un contrôle par référence. Le passif, lui, en est un. `pendingIds` est ce seam, nommé |
| **6** | Comment le menu de debug affiche-t-il une règle de stat ? | Par `StatRule.toString()`, dans le **vocabulaire du fichier** : `armor convert status:might, 1 tour` | Le menu de debug est un outil de développeur : tous ses libellés sont du français sans accents écrit en dur (`'Chance de critique (%)'`), et **aucun** ne passe par `AppLocalizations`. Y introduire l'ARB pour une ligne en ferait le premier — et afficherait au développeur la phrase du joueur plutôt que la donnée qu'il édite. `StatRuleLabel.describe` reste pour le joueur (écran de sélection, tutoriel) |

## Conséquences assumées, à annoncer plutôt qu'à découvrir

1. **Toute classe créée depuis la console naît avec un passif nommé comme elle.** `assets/data/passives/<id>.json`, prose `[À REMPLIR] <id>`, mécanique du gabarit de passif (`gain_armor`, valeur 2, `startOfTurn`, avec son bloc `mastery`). C'est un squelette à éditer, voyant par construction — pas un passif de production. La classe est immédiatement jouable et `referential_integrity_test` reste vert.
2. **Le gabarit de classe gagne `"statRules": []`**, donc tout nouveau `class.json` écrit par l'éditeur porte cette clé. `StatRule.parseAll([])` rend `const []` : aucun effet de jeu. Les **trois classes livrées ne sont pas touchées** — le gabarit ne complète jamais un fichier en modification (`placeholder_filler.dart:34-43`), et `shipped_entities_round_trip_test` le vérifie sur les 32 fichiers livrés.
3. **`EntityCategory` passe de 7 à 8 valeurs, et quatre `switch` exhaustifs cessent de compiler** tant que le `case` manque : `EntityValidator._idsOf` (`entity_validator.dart:539-554`) est le seul qui soit un vrai `switch`, mais `kEntityDescriptors` et `kCategoryIcons` sont des tables dont un test vérifie la complétude. C'est le filet, pas un obstacle : suivre les rougeurs.
4. **L'onglet « Héros » du menu de debug s'allonge d'un bloc de trois lignes en lecture seule et d'une rangée de trois puces.** Il est déjà dans un `ListView` : la hauteur ne pose pas de problème, mais les tests de tiroir existants font défiler pour atteindre un champ (`_scrollTo`), et un bloc de plus rallonge ce défilement. Aucun test existant ne devrait rougir ; s'il le fait, c'est à son `_scrollTo` de s'ajuster, pas au bloc de disparaître.
5. **La dernière cible de `mightTargets` ne peut pas être retirée** depuis le menu de debug (décision : voir la tâche 4). `HeroData.fromJson` refuse une liste vide comme une faute de donnée (`might_target.dart:20-25`) ; un outil de debug ne doit pas produire un état que la couche de données refuse de relire. Une run dont la Puissance ne renforcerait rien reste atteignable par la mise à 0 du champ « Puissance », qui est le réglage prévu pour ça.
6. **La Maîtrise reste absente de l'onglet « Héros ».** Le §9.2 nomme trois lectures et un réglage ; `mastery` n'en est pas. Elle est pourtant la stat qui pilote tout P-49, et le champ manquerait de sept lignes copiées de `luck`. **Hors périmètre de ce plan, porté aux suites** : c'est au propriétaire d'élargir, pas à l'exécutant.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `lib/models/data/stat_rule.dart` | `statNames`, `modeNames`, `targetNames`, `toString()` | 1, 4 |
| `lib/services/content_editor/entity_descriptor.dart` | Les trois clés énumérées de `statRules`, `"statRules": []` au gabarit ; puis la 8ᵉ catégorie | 1, 3 |
| `lib/services/content_editor/entity_validator.dart` | `pendingIds` ; puis le `case` des récompenses dans `_idsOf` | 2, 3 |
| `lib/services/content_editor/class_recipe.dart` | Le passif de départ, son ordre d'écriture, sa faute | 2 |
| `lib/ui/screens/content_editor_screen.dart` | `_judge` verse l'identifiant de la classe dans `pendingIds` ; la ligne d'aide compte le passif | 2 |
| `lib/ui/widgets/content_editor/editor_style.dart` | L'icône de la catégorie « Récompense de niveau » | 3 |
| `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` | Les puces de `mightTargets`, le bloc d'identité de la run | 4 |
| `lib/game/services/debug_actions.dart` | Rien de neuf : `updateHeroStats` suffit | 4 |
| `test/unit/stat_rule_vocabulary_test.dart` *(nouveau)* | Le vocabulaire exposé est celui que le parseur lit | 1 |
| `test/unit/content_editor/entity_descriptor_test.dart` | `statRules` borné ; le compte passe à 8 ; le chemin d'une récompense | 1, 3 |
| `test/unit/content_editor/entity_validator_test.dart` | Les trois valeurs refusées ; `pendingIds` ; les références d'une récompense | 1, 2, 3 |
| `test/unit/content_editor/class_recipe_test.dart` | Le passif de départ | 2 |
| `test/widget/content_editor_screen_test.dart` | Créer une classe écrit aussi son passif | 2 |
| `test/widget/debug_drawer_test.dart` | Ce que l'onglet Héros montre et règle | 4 |

## Toute la surface de texte que ce lot touche

**Aucune clé ARB, aucun texte joueur, aucun fichier d'`assets/data/`.** Ce lot n'écrit que de l'outillage, et les trois formes de texte qu'il ajoute suivent chacune la convention déjà en place dans son fichier :

| Où | Ce qui change | La convention suivie |
|:---|:---|:---|
| `entity_descriptor.dart` | le `label` de la 8ᵉ catégorie : **« Récompense de niveau »** | Les sept `label` existants sont du **français seul**, avec accents : `'Carte'`, `'Relique'`, `'Passif'`, `'Événement'`, `'Amélioration de forge'`, `'Classe'`, `'Ennemi'`. L'éditeur de contenu n'est pas localisé, et ce lot ne le localise pas |
| `entity_descriptor.dart` | les messages de faute de validation des trois clés de `statRules` | Français, comme les fautes voisines d'`entity_validator.dart` |
| `debug_hero_tab.dart` | les libellés du bloc d'identité et des puces | **Français sans accents, en dur** — `'Chance de critique (%)'`, `'Puissance'` : aucun libellé du menu de debug ne passe par `AppLocalizations`, et la décision 6 dit pourquoi ce lot n'en fait pas le premier |
| `class_recipe.dart` | la prose du passif de départ | **Non écrite** : `fillPlaceholders` produit `[À REMPLIR] <id>` dans les deux langues, à partir des `bilingualBases` du descripteur du passif. Le lot n'invente aucun texte |
| gabarit `level_up_rewards` | `"statRules": []` côté classe, et le gabarit de récompense | **Aucune prose** dans les deux gabarits : les paires `name_fr`/`name_en` et `description_fr`/`description_en` viennent de `bilingualBases`, comme pour les sept autres catégories. `shipped_entities_round_trip_test` le vérifie sur les fichiers livrés |

Si une tâche se trouve à écrire une chaîne anglaise ou une clé ARB, c'est le signe qu'elle a dérivé hors du périmètre : s'arrêter et le signaler.

---

### Task 0: La branche, depuis la documentation déjà commitée

**À faire dans le checkout principal, avant toute tâche de code.**

**Files:**
- Aucun. La documentation de ce lot est **déjà commitée sur `main`** : ce plan, celui de la partie 1, et leurs liens dans `docs/INDEX.md` et `docs/ROADMAP.md`.

**Interfaces:**
- Consumes: ce plan, commité sur `main` ; les lots A, B, C de P-41 et P-49, fusionnés.
- Produces: la branche `feat/p41-lot-d-console`, et le **compte de tests de départ réellement mesuré**, dont dépendent toutes les prévisions de ce plan.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git switch main && git pull`, puis `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: **aucune sortie** — l'arbre de travail est propre.

Run: `ls assets/data/level_up_rewards/`
Expected: huit fichiers. Sinon, **s'arrêter et le signaler** : la tâche 3 leur écrit un descripteur.

Run: `git grep -n "referenceListKeys" -- lib`
Expected: **huit occurrences dans cinq fichiers** — `entity_descriptor.dart` (3 : le champ, sa doc, la déclaration `'classes'` du passif), `entity_validator.dart` (1 : `_references`), `field_kind.dart` (1), `content_editor_screen.dart` (2) et `document_form.dart` (1). C'est la mécanique que le §9.2 croit rester à écrire et que P-49 a livrée. Si elle manque, la lecture « déjà livré » ci-dessus est fausse : le signaler avant de continuer, **sans rien réécrire au hasard**.

- [ ] **Step 2: Créer la branche**

Run: `git switch -c feat/p41-lot-d-console` — depuis `main`, dans le checkout principal. **Pas de worktree**, même si le skill d'exécution en propose un.

- [ ] **Step 3: Mesurer la base — et noter le chiffre**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+N: All tests passed!`, **prévision N = 1135** (re-mesuré le 2026-09-20 sur `a270de4`), ou **1156** si la partie 1 du lot D a été fusionnée entre-temps.

**Noter N.** Toutes les prévisions de ce plan sont écrites à partir de 1135 ; si N diffère, décaler chaque prévision du même écart plutôt que de la recalculer.

---

### Task 1: L'éditeur borne `statRules` au vocabulaire du moteur

**Files:**
- Modify: `lib/models/data/stat_rule.dart`, `lib/services/content_editor/entity_descriptor.dart`
- Test: `test/unit/stat_rule_vocabulary_test.dart` *(nouveau)*, `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Consumes: `StatRule.fromJson`, `EntityDescriptor.enumKeys`, `valuesMatching` (`field_path.dart`, qui sait déjà parcourir `intents[].type`).
- Produces:
  - `static List<String> StatRule.statNames` — `['armor', 'mana']`, lu sur `_stats`.
  - `static List<String> StatRule.modeNames` — `['convert']`, lu sur `_modes`.
  - `static List<String> StatRule.targetNames` — `['status:might']`, lu sur `_targets`.
  - Le descripteur `EntityCategory.heroClass` gagne `enumKeys` (`statRules[].stat`, `[].mode`, `[].to`) et `"statRules": []` à son gabarit.

- [ ] **Step 1: Écrire les tests qui échouent**

Create `test/unit/stat_rule_vocabulary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// Le vocabulaire que `class.json` ecrit, expose pour l'editeur de contenu.
///
/// Il n'est lisible nulle part ailleurs : `RuleTarget.statusMight` s'ecrit
/// `"status:might"` dans le fichier, et `_names(RuleTarget.values)` rendrait
/// donc une valeur qu'aucun fichier ne porte. Le seul endroit qui connait la
/// correspondance est le parseur — precedent : `PassiveMastery.fields`.
void main() {
  test('chaque nom expose se relit par fromJson', () {
    for (final stat in StatRule.statNames) {
      for (final mode in StatRule.modeNames) {
        for (final to in StatRule.targetNames) {
          expect(
            () => StatRule.fromJson({'stat': stat, 'mode': mode, 'to': to}),
            returnsNormally,
            reason: '$stat / $mode / $to',
          );
        }
      }
    }
  });

  test('les trois listes sont non vides et sans doublon', () {
    for (final noms in [
      StatRule.statNames,
      StatRule.modeNames,
      StatRule.targetNames,
    ]) {
      expect(noms, isNotEmpty);
      expect(noms.toSet(), hasLength(noms.length));
    }
  });
}
```

Dans `test/unit/content_editor/entity_descriptor_test.dart`, ajouter ce test **après** `'chaque descripteur est indexe sous sa propre categorie'` :

```dart
  test('le descripteur de classe borne statRules au vocabulaire du moteur', () {
    final classe = kEntityDescriptors[EntityCategory.heroClass]!;

    // Les trois cles imbriquees, et leurs valeurs lues sur `StatRule` : un
    // vocabulaire recopie ici divergerait du parseur au premier ajout.
    expect(classe.enumKeys['statRules[].stat'], StatRule.statNames);
    expect(classe.enumKeys['statRules[].mode'], StatRule.modeNames);
    expect(classe.enumKeys['statRules[].to'], StatRule.targetNames);

    // Le gabarit porte la cle, vide : une regle toute faite ferait naitre
    // toute classe creee en convertisseuse d'armure.
    expect(classe.decodeTemplate()['statRules'], isEmpty);
  });
```

Ajouter en tête du même fichier, à sa place alphabétique :

```dart
import 'package:roguelike_card_game/models/data/stat_rule.dart';
```

Dans `test/unit/content_editor/entity_validator_test.dart`, ajouter ce groupe **à la fin** de `main()`, avant sa `}` de fermeture :

```dart
  group('les regles de stat d une classe', () {
    /// Un brouillon de classe dont seules les `statRules` varient.
    EntityDraft classeAvecRegles(String statRules) {
      Directory('$root/assets/data/classes').createSync(recursive: true);
      final descriptor = kEntityDescriptors[EntityCategory.heroClass]!;
      final template =
          jsonDecode(descriptor.template) as Map<String, dynamic>;
      template['statRules'] = jsonDecode(statRules);
      return EntityDraft(
        descriptor: descriptor,
        id: 'parieur',
        bilingual: const {
          'name_fr': 'Le Parieur',
          'name_en': 'Gambler',
          'description_fr': 'Manipule les probabilites.',
          'description_en': 'Plays the odds.',
        },
        mechanics: jsonEncode(template),
      );
    }

    test('la regle du Berserker passe', () {
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convert", "to": "status:might", "duration": 1}]',
      ));
      // Seules des fautes de ressource peuvent rester (l'image de classe
      // n'existe pas dans le bac a sable) : aucune sur les regles.
      expect(
        faults.where((f) => f.field?.startsWith('statRules') ?? false),
        isEmpty,
        reason: faults.join(' ; '),
      );
    });

    test('un mode mal orthographie est refuse', () {
      // Le cas exact que le §9.2 de la spec nomme : « convrt ».
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convrt", "to": "status:might"}]',
      ));
      expect(
        faults.where((f) => f.field == 'statRules[0].mode'),
        hasLength(1),
        reason: faults.join(' ; '),
      );
    });

    test('une ressource inconnue est refusee', () {
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "puissance", "mode": "convert", "to": "status:might"}]',
      ));
      expect(
        faults.where((f) => f.field == 'statRules[0].stat'),
        hasLength(1),
        reason: faults.join(' ; '),
      );
    });

    test('une cible inconnue est refusee', () {
      // `statusMight` est le **nom Dart** de la valeur ; le fichier ecrit
      // `status:might`. Confondre les deux est l'erreur la plus probable.
      final faults = validatorWith().validate(classeAvecRegles(
        '[{"stat": "armor", "mode": "convert", "to": "statusMight"}]',
      ));
      expect(
        faults.where((f) => f.field == 'statRules[0].to'),
        hasLength(1),
        reason: faults.join(' ; '),
      );
    });
  });
```

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/stat_rule_vocabulary_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart`
Expected: **ÉCHEC** — `The getter 'statNames' isn't defined for the type 'StatRule'`.

- [ ] **Step 3: `StatRule` expose son vocabulaire**

Dans `lib/models/data/stat_rule.dart`, ajouter ces trois getters **juste après** la table `_targets` (ligne 54) :

```dart
  /// Le vocabulaire que le fichier de classe écrit, exposé pour l'éditeur de
  /// contenu — précédent : `PassiveMastery.fields` (spec P-49, §3.3).
  ///
  /// Ces listes ne sont **pas** `_names(RuleStat.values)` et compagnie :
  /// `RuleTarget.statusMight` s'écrit `"status:might"` dans le fichier, et le
  /// nom Dart n'y a jamais cours. Le seul endroit qui connaisse la
  /// correspondance est ce parseur ; la recopier dans un descripteur ferait
  /// diverger les deux au premier ajout (spec P-41, §9.2).
  static List<String> get statNames => _stats.keys.toList(growable: false);
  static List<String> get modeNames => _modes.keys.toList(growable: false);
  static List<String> get targetNames => _targets.keys.toList(growable: false);
```

- [ ] **Step 4: Le descripteur de classe borne les trois clés**

Dans `lib/services/content_editor/entity_descriptor.dart` :

**a)** Ajouter l'import, à sa place parmi les autres modèles :

```dart
import '../../models/data/stat_rule.dart';
```

**b)** Dans `EntityCategory.heroClass`, ajouter `enumKeys` **juste après** `enumListKeys` (ligne 358) :

```dart
    enumListKeys: {'mightTargets': _names(MightTarget.values)},
    // Les trois vocabulaires d'une règle de stat, **lus sur le parseur** :
    // `to` s'écrit `status:might` et non `statusMight`, et seul `StatRule`
    // connaît la correspondance. Sans ces trois lignes, l'éditeur laissait
    // écrire `"mode": "convrt"` — exactement le cas pour lequel il existe
    // (spec P-41, §9.2).
    enumKeys: {
      'statRules[].stat': StatRule.statNames,
      'statRules[].mode': StatRule.modeNames,
      'statRules[].to': StatRule.targetNames,
    },
```

**c)** **Remplacer** le commentaire du gabarit qui renvoie au lot D (lignes 367-370) et ajouter la clé au gabarit :

```dart
    // Ni `classCard` ni `skills` ne figurent au gabarit : l'ecrivain calcule
    // le premier, et `_registerSignatureCard` remplit le second a chaque carte
    // de classe ecrite. `themeColor` y figure au magenta : une classe dont la
    // couleur n'a pas ete choisie doit se voir.
    //
    // `statRules` y figure **vide**, et non garni : une regle toute faite
    // ferait naitre convertisseuse d'armure toute classe creee depuis la
    // console. Vide, la cle est visible dans le formulaire, et la validation
    // ci-dessus s'applique des qu'une regle y est ajoutee.
    template: '''
{
  "maxHp": 100,
  "maxMana": 3,
  "luck": 0,
  "mastery": 0,
  "critChance": 0,
  "mightTargets": ["attack"],
  "statRules": [],
  "displayOrder": 99,
  "themeColor": "#FF00FF"
}''',
```

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/stat_rule_vocabulary_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart`
Expected: **tout vert**.

- [ ] **Step 6: Le Berserker livré traverse toujours l'éditeur sans changer**

Run: `flutter test test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: **PASS**, dont « Classe : chaque fichier livré se modifie à l'identique ». C'est ce test qui prouve que le gabarit ne verse pas `"statRules": []` dans les fichiers du Paladin et du Mage, et que la règle du Berserker passe la validation neuve sans être réécrite. **S'il rougit, ne pas assouplir le test** : c'est la déclaration de la tâche qui est fausse.

- [ ] **Step 7: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1142: All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add lib/models/data/stat_rule.dart lib/services/content_editor/entity_descriptor.dart test/unit/stat_rule_vocabulary_test.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart
git commit -m "feat(editeur): les regles de stat d une classe sont validees

L editeur laissait ecrire \"mode\": \"convrt\" — exactement le cas pour lequel
il existe. Les trois cles de statRules sont desormais bornees, et leur
vocabulaire est lu sur StatRule : status:might ne s ecrit pas statusMight, et
seul le parseur connait la correspondance.

Le gabarit de classe porte la cle vide, jamais une regle toute faite.

Spec P-41, §9.2.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: La création guidée garantit un passif à la classe créée

**Files:**
- Modify: `lib/services/content_editor/entity_validator.dart`, `lib/services/content_editor/class_recipe.dart`, `lib/ui/screens/content_editor_screen.dart`
- Test: `test/unit/content_editor/entity_validator_test.dart`, `test/unit/content_editor/class_recipe_test.dart`, `test/widget/content_editor_screen_test.dart`

**Interfaces:**
- Consumes: `EntityDraft`, `fillPlaceholders`, `kEntityDescriptors[EntityCategory.passive]`, `EntityValidator._idsOf`.
- Produces:
  - `EntityValidator` gagne le paramètre nommé `Map<EntityCategory, Set<String>> pendingIds = const {}`.
  - `ClassRecipe.toDrafts()` rend **trois familles** dans cet ordre : la classe, **son passif de départ**, puis ses cartes de signature.
  - `ClassRecipe.starterPassiveId` — un getter qui rend l'identifiant du passif écrit (égal à `id`).

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/content_editor/entity_validator_test.dart`, ajouter ce groupe **à la fin** de `main()` :

```dart
  group('pendingIds — ce que la meme transaction va ecrire', () {
    /// Un passif qui vise une classe, valide ou pendante selon le registre.
    EntityDraft passifVisant(String classeId) {
      Directory('$root/assets/data/passives').createSync(recursive: true);
      final descriptor = kEntityDescriptors[EntityCategory.passive]!;
      final template = jsonDecode(descriptor.template) as Map<String, dynamic>;
      template['classes'] = [classeId];
      return EntityDraft(
        descriptor: descriptor,
        id: 'parieur',
        bilingual: const {
          'name_fr': 'Pari',
          'name_en': 'Wager',
          'description_fr': 'x',
          'description_en': 'x',
        },
        mechanics: jsonEncode(template),
      );
    }

    test('un passif qui vise une classe inconnue est refuse', () {
      final validator = EntityValidator(
        fs: fs,
        rootPath: root,
        registry: fixtureRegistry(heroes: [fixtureHero('paladin')]),
      );

      final faults = validator.validate(passifVisant('parieur'));

      expect(faults.where((f) => f.field == 'classes'), hasLength(1));
    });

    test('la meme classe, annoncee pendante, passe', () {
      // Le trou que `_signatureCards` decrit depuis P-30 : la classe que la
      // recette vient d'ecrire n'est pas dans le registre charge au
      // demarrage, et un controle par reference refuserait la sortie meme de
      // l'outil.
      final validator = EntityValidator(
        fs: fs,
        rootPath: root,
        registry: fixtureRegistry(heroes: [fixtureHero('paladin')]),
        pendingIds: const {
          EntityCategory.heroClass: {'parieur'},
        },
      );

      final faults = validator.validate(passifVisant('parieur'));

      expect(faults.where((f) => f.field == 'classes'), isEmpty,
          reason: faults.join(' ; '));
    });
  });
```

Dans `test/unit/content_editor/class_recipe_test.dart`, **remplacer** le test `'la classe vient en premier, ses cartes ensuite'` par celui-ci, et ajouter les deux suivants :

```dart
  test('la classe, puis son passif, puis ses cartes', () {
    final drafts = recipe().toDrafts();

    expect(drafts, hasLength(4));
    expect(drafts.first.descriptor.category, EntityCategory.heroClass);
    expect(drafts.first.path, 'assets/data/classes/gambler/class.json');
    // Le passif nomme la classe : elle doit exister avant lui, comme les
    // cartes de signature.
    expect(drafts[1].descriptor.category, EntityCategory.passive);
    expect(drafts[1].path, 'assets/data/passives/gambler.json');
    // L'inverse leverait StateError : `_registerSignatureCard` exige que le
    // class.json existe avant qu'une de ses cartes ne soit ecrite.
    expect(drafts[2].path, 'assets/data/classes/gambler/cards/pari_1.json');
    expect(drafts[3].path, 'assets/data/classes/gambler/cards/pari_2.json');
  });

  test('le passif de depart ne vise que la classe creee', () {
    final passif = recipe().toDrafts()[1];
    final mechanics = jsonDecode(passif.mechanics) as Map<String, dynamic>;

    // Sans `classes`, le passif serait ouvert a **toutes** les classes et
    // polluerait le pool des trois livrees (spec P-49, §3.2).
    expect(mechanics['classes'], ['gambler']);
    // La mecanique vient du gabarit de passif : un squelette jouable, que
    // l'auteur edite ensuite.
    expect(mechanics['trigger'], 'startOfTurn');
    expect(mechanics['effectType'], 'gain_armor');
  });

  test('la prose du passif est voyante, jamais inventee', () {
    final passif = recipe().toDrafts()[1];

    // `fillPlaceholders` ecrit `[A REMPLIR] <id>` : un nom oublie doit se
    // lire comme tel dans le jeu, pas passer pour un choix.
    expect(passif.bilingual['name_fr'], contains('gambler'));
    expect(passif.bilingual['name_fr'], startsWith(kProsePlaceholderPrefix));
    expect(passif.bilingual['description_en'], startsWith(kProsePlaceholderPrefix));
  });
```

Ajouter en tête du même fichier, à sa place alphabétique :

```dart
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';
```

Dans `test/widget/content_editor_screen_test.dart`, ajouter ce test **juste après** `'creer une classe ecrit ses cartes et referme skills'` (ligne 606), dont il calque le harnais :

```dart
  testWidgets('creer une classe ecrit aussi son passif de depart',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));
    await tester.tap(find.text('Classe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();

    // Sans une seule carte de signature : le passif est garanti par la
    // recette elle-meme, pas par ce que l'auteur pense a saisir.
    await tester.enterText(find.byKey(const Key('editeur-id')), 'gambler');
    await tester.tap(find.text('Écrire'));
    await tester.pumpAndSettle();

    // Une classe sans passif disponible afficherait un choix vide a l'ecran
    // de selection, et ferait rougir `referential_integrity_test` apres coup
    // (spec P-41, §9.2).
    final passif = File('$root/assets/data/passives/gambler.json');
    expect(passif.existsSync(), isTrue);

    final json = jsonDecode(passif.readAsStringSync()) as Map<String, dynamic>;
    expect(json['id'], 'gambler');
    // Il ne vise que la classe creee : sans `classes`, il serait ouvert a
    // toutes et polluerait le pool des trois livrees (spec P-49, §3.2).
    expect(json['classes'], ['gambler']);
    // Sa prose est voyante, jamais inventee.
    expect(json['name_fr'], startsWith(kProsePlaceholderPrefix));

    // Et la classe est ecrite avant lui, sans quoi la reference serait
    // pendante sur le disque.
    expect(
      File('$root/assets/data/classes/gambler/class.json').existsSync(),
      isTrue,
    );
  });
```

Ajouter en tête du même fichier, à sa place alphabétique :

```dart
import 'package:roguelike_card_game/services/content_editor/placeholder_filler.dart';
```

> **Ce test passe par `pendingIds` sans le nommer.** Le harnais ne construit aucun registre, donc `GameDataRegistry.instance` peut être `null` : `_idsOf` rend alors les seuls identifiants en attente, et la référence passe. Il vaut donc surtout comme preuve de bout en bout ; ce sont les deux tests de `entity_validator_test.dart` ci-dessus qui exercent le cas **registre présent, classe absente**, celui de la production.

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/class_recipe_test.dart`
Expected: **ÉCHEC** — `No named parameter with the name 'pendingIds'`, puis `Expected: an object with length of <4>  Actual: ... length of <3>`.

- [ ] **Step 3: Le validateur connaît les écritures en attente**

Dans `lib/services/content_editor/entity_validator.dart` :

**a)** Ajouter le paramètre au constructeur (lignes 36-41) et son champ :

```dart
  const EntityValidator({
    required this.fs,
    required this.rootPath,
    this.registry,
    this.imports = const [],
    this.pendingIds = const {},
  });
```

```dart
  /// Les identifiants que **la même transaction** va écrire, et que le
  /// registre chargé au démarrage ne connaît donc pas encore.
  ///
  /// Une recette de classe écrit la classe, puis un passif qui la nomme : au
  /// moment où ce passif est jugé, la classe n'existe ni dans le registre ni
  /// sur le disque. `_signatureCards` contournait le problème en n'étant pas
  /// un contrôle par référence (voir sa documentation) ; le passif, lui, en
  /// est un. C'est ce seam, nommé.
  final Map<EntityCategory, Set<String>> pendingIds;
```

**b)** Dans `_idsOf` (lignes 536-555), unir les identifiants en attente. Renommer la méthode existante en `_registryIdsOf` et écrire :

```dart
  Set<String>? _idsOf(EntityCategory category) {
    final known = _registryIdsOf(category);
    final pending = pendingIds[category];
    if (known == null) return pending == null || pending.isEmpty ? null : pending;
    return pending == null ? known : {...known, ...pending};
  }

  Set<String>? _registryIdsOf(EntityCategory category) {
    final r = registry;
    if (r == null) return null;
    switch (category) {
      // ... le switch existant, inchangé
    }
  }
```

- [ ] **Step 4: La recette écrit le passif de départ**

Dans `lib/services/content_editor/class_recipe.dart` :

**a)** Ajouter l'identifiant du passif, **avant** `toDrafts` :

```dart
  /// L'identifiant du passif de départ que la recette écrit.
  ///
  /// **Dérivé de l'identifiant de la classe**, comme le chemin de son icône :
  /// il ne se saisit pas. Une classe sans aucun passif disponible afficherait
  /// un choix vide à la sélection et ferait rougir
  /// `referential_integrity_test` (spec P-41, §9.2) ; la garantir revient à
  /// écrire ce passif dans la même transaction. L'auteur le renomme ensuite
  /// comme n'importe quelle entité, et sa prose `[À REMPLIR]` le lui
  /// rappellera.
  String get starterPassiveId => id;
```

**b)** **Remplacer** `toDrafts()` par :

```dart
  /// Les brouillons, **dans l'ordre d'écriture**.
  ///
  /// La classe d'abord : `_registerSignatureCard` lève `StateError` si une
  /// carte de classe est écrite avant le `class.json` qui doit la déclarer,
  /// et le passif de départ la **nomme**, donc elle doit exister avant lui.
  /// Son `skills` reste absent : l'écrivain l'alimente carte par carte, si
  /// bien que chaque état intermédiaire respecte la bijection exigée par
  /// `EntityValidator._signatureCards`.
  List<EntityDraft> toDrafts() {
    final classDescriptor = kEntityDescriptors[EntityCategory.heroClass]!;
    final passiveDescriptor = kEntityDescriptors[EntityCategory.passive]!;
    final cardDescriptor = kEntityDescriptors[EntityCategory.card]!;

    return [
      fillPlaceholders(
        EntityDraft(
          descriptor: classDescriptor,
          id: id,
          bilingual: bilingual,
          mechanics: _mechanicsWithIcon,
        ),
      ),
      fillPlaceholders(
        EntityDraft(
          descriptor: passiveDescriptor,
          id: starterPassiveId,
          // Aucune prose saisie : `fillPlaceholders` écrit `[À REMPLIR]`,
          // volontairement voyant. Inventer un nom ferait passer un squelette
          // pour un choix.
          bilingual: const {},
          mechanics: _starterPassiveMechanics,
        ),
      ),
      for (final card in signatureCards)
        fillPlaceholders(
          EntityDraft(
            descriptor: cardDescriptor,
            id: card.id,
            bilingual: card.bilingual,
            mechanics: '{}',
            heroClass: id,
          ),
        ),
    ];
  }

  /// Le corps du passif de départ : le gabarit de la catégorie, plus la seule
  /// clé que la recette impose — `classes`.
  ///
  /// Sans elle, le passif serait ouvert à **toutes** les classes (spec P-49,
  /// §3.2) et viendrait polluer le pool des trois livrées. C'est la même
  /// doctrine que `iconPath` : ce que le geste impose, la recette l'écrit.
  String get _starterPassiveMechanics {
    final decoded = jsonDecode(
      kEntityDescriptors[EntityCategory.passive]!.template,
    ) as Map<String, dynamic>;
    decoded['classes'] = [id];
    return jsonEncode(decoded);
  }
```

**c)** Dans `faults()`, rien à ajouter : l'identifiant du passif est dérivé de celui de la classe, qu'`EntityValidator._identity` juge déjà. **Compléter sa documentation** d'une phrase :

```dart
  /// […]
  ///
  /// Le passif de départ n'y figure pas : son identifiant est celui de la
  /// classe, que `EntityValidator._identity` juge déjà, et il ne peut donc ni
  /// être vide ni faire doublon avec une carte de signature — qui vit dans un
  /// autre répertoire.
```

- [ ] **Step 5: L'écran verse l'identifiant de la classe dans `pendingIds`**

Dans `lib/ui/screens/content_editor_screen.dart`, méthode `_judge` :

**a)** Compléter la construction du validateur :

```dart
    final validator = EntityValidator(
      fs: ref.read(contentFileSystemProvider)!,
      rootPath: root,
      registry: GameDataRegistry.instance,
      imports: imports,
      // La classe que la recette va ecrire n'est ni dans le registre charge
      // au demarrage ni sur le disque : sans cette annonce, son propre passif
      // de depart serait refuse pour reference pendante.
      pendingIds: recipe == null
          ? const {}
          : {
              EntityCategory.heroClass: {recipe.id},
            },
    );
```

**b)** Dans `_note()`, faire compter le passif dans la ligne d'aide :

```dart
    if (_isClassRecipe) {
      final cards = _cardCountValue == 0
          ? ''
          : _cardCountValue == 1
              ? ' et sa carte'
              : ' et ses $_cardCountValue cartes';
      return 'Valider vérifie sans écrire · Écrire valide, puis écrit la '
          'classe, son passif de départ$cards';
    }
```

- [ ] **Step 6: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/class_recipe_test.dart test/widget/content_editor_screen_test.dart`
Expected: **tout vert**.

- [ ] **Step 7: L'invariant du dépôt tient toujours**

Run: `flutter test test/unit/referential_integrity_test.dart`
Expected: **PASS**, dont « chaque classe a au moins un passif disponible ». Ce lot n'écrit aucun fichier d'`assets/data/`, donc rien n'a bougé ; c'est la vérification que la tâche n'a pas eu d'effet de bord.

- [ ] **Step 8: Créer une classe à la main, dans l'application**

Run: `flutter run -d windows`, ouvrir l'éditeur de contenu, créer une classe `gambler` avec une carte de signature, puis « Écrire ».
Expected : quatre fichiers écrits — `assets/data/classes/gambler/class.json`, `assets/data/passives/gambler.json`, `assets/data/classes/gambler/cards/<id>.json`, plus l'icône si elle a été déposée. **Puis annuler** : `git checkout -- assets/ pubspec.yaml && git clean -fd assets/data/classes/gambler assets/data/passives/gambler.json`. Vérifier par `git status --short` qu'il ne reste rien.

`gambler` et non `parieur` : c'est l'identifiant que porte déjà le `recipe()` de `class_recipe_test.dart` (ligne 13) et que saisit le test d'écran, donc le seul que les chemins attendus de cette étape et ceux des tests partagent. Les fixtures de `entity_validator_test.dart` gardent leur propre `parieur` — elles ne passent pas par la recette et n'ont aucun chemin en commun avec elle.

- [ ] **Step 9: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1147: All tests passed!`

- [ ] **Step 10: Commit**

```bash
git add lib/services/content_editor/entity_validator.dart lib/services/content_editor/class_recipe.dart lib/ui/screens/content_editor_screen.dart test/unit/content_editor/entity_validator_test.dart test/unit/content_editor/class_recipe_test.dart test/widget/content_editor_screen_test.dart
git commit -m "feat(editeur): la creation guidee d une classe ecrit son passif

Une classe creee depuis la console n avait aucun passif disponible : choix
vide a la selection, et referential_integrity_test rouge. La recette ecrit
desormais un passif de depart derive de l identifiant de la classe, avec
classes: [id] — la meme doctrine que iconPath.

EntityValidator gagne pendingIds : ce que la meme transaction va ecrire. Le
trou etait decrit dans le code depuis P-30 ; il est nomme.

Spec P-41, §9.2.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Les récompenses de niveau deviennent une catégorie éditable

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart`, `lib/services/content_editor/entity_validator.dart`, `lib/ui/widgets/content_editor/editor_style.dart`
- Test: `test/unit/content_editor/entity_descriptor_test.dart`, `test/unit/content_editor/entity_validator_test.dart`

**Interfaces:**
- Consumes: `LevelUpRewardData.fromJson`, `RewardEffect` / `RewardStat` / `RewardPool` / `RewardRequirement` / `RewardRarity`, `GameDataRegistry.levelUpRewards`, et **`EntityValidator._registryIdsOf`** — le `switch` exhaustif sur `EntityCategory` que la **tâche 2** a extrait de `_idsOf` sous ce nom. C'est à lui que le step 4 ajoute son `case` ; il s'appelle encore `_idsOf` si la tâche 2 n'est pas passée.
- Produces: `EntityCategory.levelUpReward` et son `EntityDescriptor`. Rien d'autre : le catalogue, les valeurs connues, le formulaire inféré, l'écrivain et le test d'aller-retour sont tous pilotés par la table.

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/unit/content_editor/entity_descriptor_test.dart` :

**a)** Dans le premier test, **relever le compte** :

```dart
    expect(EntityCategory.values, hasLength(8));
```

**b)** Dans le second test, **remplacer** le commentaire devenu faux et **garder** `hasLength(9)` :

```dart
    // **Si ce test rougit apres l'ajout d'une `EntitySource` :** ajouter la
    // categorie a `EntityCategory`, son descripteur a `kEntityDescriptors`,
    // puis relever le compte ci-dessous. Neuf sources pour **huit**
    // categories, par un seul ecart assume : la carte en a deux, neutre et de
    // classe, pour un seul descripteur. Les recompenses de niveau ont recu le
    // leur au lot D (spec §9.2).
    final declared = 'EntitySource('
        .allMatches(File('lib/services/game_data_service.dart').readAsStringSync());
    expect(declared, hasLength(9));
```

**c)** Ajouter un test de chemin au groupe `pathOf` :

```dart
    test('une recompense de niveau va dans level_up_rewards/', () {
      expect(
        kEntityDescriptors[EntityCategory.levelUpReward]!.pathOf('affinity'),
        'assets/data/level_up_rewards/affinity.json',
      );
    });
```

Dans `test/unit/content_editor/entity_validator_test.dart`, ajouter ce groupe **à la fin** de `main()` :

```dart
  group('les recompenses de niveau', () {
    EntityDraft recompense(Map<String, dynamic> surcharge) {
      Directory('$root/assets/data/level_up_rewards')
          .createSync(recursive: true);
      final descriptor = kEntityDescriptors[EntityCategory.levelUpReward]!;
      final template = jsonDecode(descriptor.template) as Map<String, dynamic>;
      template.addAll(surcharge);
      return EntityDraft(
        descriptor: descriptor,
        id: 'endurance',
        bilingual: const {
          'name_fr': 'Endurance',
          'name_en': 'Endurance',
          'description_fr': '+{amount} PV max',
          'description_en': '+{amount} max HP',
        },
        mechanics: jsonEncode(template),
      );
    }

    test('le gabarit passe', () {
      final faults = validatorWith().validate(recompense(const {}));
      expect(faults, isEmpty, reason: faults.join(' ; '));
    });

    test('une stat inconnue est refusee', () {
      // `RewardStat` n'a pas de valeur `armure` : `fromJson` leve, et la
      // famille des enumerations le dit avant lui, en nommant le champ.
      final faults = validatorWith().validate(
        recompense(const {'stat': 'armure'}),
      );
      expect(faults.where((f) => f.field == 'stat'), hasLength(1),
          reason: faults.join(' ; '));
    });
  });
```

Dans `test/widget/content_editor_screen_test.dart`, **renommer et compléter** le test `'les sept types sont des boutons, visibles d emblee'` (ligne 120) — c'est lui qui rougira le premier à l'ouverture de l'application :

```dart
  testWidgets('les huit types sont des boutons, visibles d emblee',
      (tester) async {
    await tester.pumpWidget(harness(projectRoot: root));

    for (final label in const [
      'Carte', 'Relique', 'Événement', 'Passif',
      'Amélioration de forge', 'Récompense de niveau', 'Classe', 'Ennemi',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'type manquant : $label');
    }
    expect(find.byType(DropdownButton<EntityCategory>), findsNothing);
  });
```

C'est une **modification**, pas un ajout : le compte de tests ne bouge pas.

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart test/widget/content_editor_screen_test.dart`
Expected: **ÉCHEC** — `The getter 'levelUpReward' isn't defined for the enum 'EntityCategory'`.

- [ ] **Step 3: La huitième catégorie**

Dans `lib/services/content_editor/entity_descriptor.dart` :

**a)** Ajouter l'import, à sa place parmi les autres modèles :

```dart
import '../../models/data/level_up_reward_data.dart';
```

**b)** **Remplacer** l'énumération et sa documentation (lignes 15-18) :

```dart
/// Les huit categories d'entites editables, en regard exact des huit appels a
/// `loadAll` de `loadGameDataRegistry` : un par categorie, sans ecart. Les
/// **sources** sont neuf, la carte en ayant deux — neutre et de classe — pour
/// un seul descripteur. L'audio n'en est pas une, c'est un document de
/// configuration.
enum EntityCategory {
  card,
  relic,
  event,
  passive,
  forgeUpgrade,
  levelUpReward,
  heroClass,
  enemy,
}
```

**c)** Ajouter le descripteur à `kEntityDescriptors`, **entre** `forgeUpgrade` et `heroClass` :

```dart
  EntityCategory.levelUpReward: EntityDescriptor(
    category: EntityCategory.levelUpReward,
    label: 'Récompense de niveau',
    directory: 'level_up_rewards',
    // `LevelUpRewardData.fromJson` leve deja sur `effect`, `pool` et sur un
    // palier manquant. Ces deux cles sont celles sans lesquelles le fichier
    // n'a aucun sens, et que la famille 3 nomme avant que `fromJson` ne leve.
    requiredKeys: const {'effect', 'pool'},
    enumKeys: {
      'effect': _names(RewardEffect.values),
      'stat': _names(RewardStat.values),
      'pool': _names(RewardPool.values),
      'requires': _names(RewardRequirement.values),
    },
    // `name` et `description` seulement : `fallbackDescription` et
    // `shortDescription` sont **optionnels et par paires**, ce que
    // `_readOptionalPair` verifie deja au chargement. Les declarer ici les
    // rendrait obligatoires sur les six recompenses qui n'en portent pas.
    bilingualBases: const ['name', 'description'],
    construct: LevelUpRewardData.fromJson,
    // La table des paliers : les cinq du tirage. Une recompense mythique n'en
    // porte qu'un, `mythic` — le gabarit montre le cas courant, et `fromJson`
    // dit lequel manque (`level_up_reward_data.dart:277-286`).
    //
    // Les cles d'une **table** ne sont bornees par aucune des familles du
    // validateur, qui ne savent viser qu'une valeur : c'est `_readValues` qui
    // leve sur une rarete inconnue, via `construct`. Assume, et c'est la
    // categorie ou `fromJson` fait le plus de travail — comme
    // `forgeUpgrade`.
    template: '''
{
  "effect": "stat",
  "stat": "maxHp",
  "pool": "draft",
  "displayOrder": 99,
  "values": {
    "common": 1,
    "uncommon": 2,
    "rare": 3,
    "epic": 5,
    "legendary": 7
  }
}''',
  ),
```

> **Vérifier les cinq clés contre un fichier livré** — `cat assets/data/level_up_rewards/vitality.json` — avant de les écrire. **Ne pas inventer un palier.**

- [ ] **Step 4: Suivre les rougeurs de l'analyseur**

Run: `dart analyze`
Expected: **ÉCHEC attendu** — `The type 'EntityCategory' is not exhaustively matched` sur `EntityValidator._registryIdsOf`. C'est le filet.

Dans `lib/services/content_editor/entity_validator.dart`, ajouter le `case` manquant à `_registryIdsOf` :

```dart
      case EntityCategory.levelUpReward:
        return r.levelUpRewards.map((e) => e.id).toSet();
```

Dans `lib/ui/widgets/content_editor/editor_style.dart`, ajouter l'icône à `kCategoryIcons` :

```dart
  EntityCategory.levelUpReward: Icons.military_tech,
```

**L'analyseur ne dit rien d'une table incomplète** : `editor_toolbar.dart:42` la déréférence par `!`, donc l'oubli se traduit par un plantage à l'ouverture de l'éditeur — que le test « les huit types sont des boutons » attrape au step 5.

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart test/widget/content_editor_screen_test.dart`
Expected: **tout vert**.

- [ ] **Step 6: Les huit récompenses livrées se modifient à l'identique**

Run: `flutter test test/unit/content_editor/shipped_entities_round_trip_test.dart`
Expected: **PASS**, avec **un test de plus** — « Récompense de niveau : chaque fichier livré se modifie à l'identique ». Le fichier produit un test par descripteur : la huitième catégorie en ajoute exactement un.

**S'il rougit**, le message nomme le fichier et la différence. Les causes probables, dans l'ordre :
- une clé optionnelle déclarée `bilingualBases` : `fallbackDescription` ou `shortDescription`, que six récompenses sur huit ne portent pas ;
- une clé du gabarit versée dans un fichier livré : impossible en modification (`placeholder_filler.dart:34-43`), mais à vérifier si le message le suggère ;
- `requires` déclaré `enumKeys` alors qu'il est absent de sept fichiers : une clé absente ne rend rien (`valuesMatching`), donc ce n'est pas une cause — sauf si elle a été mise dans `requiredKeys`.

**Corriger la déclaration, jamais les fichiers livrés.**

- [ ] **Step 7: Ouvrir la catégorie dans l'application**

Run: `flutter run -d windows`, ouvrir l'éditeur de contenu, choisir « Récompense de niveau » dans la barre d'outils.
Expected : l'arbre montre les huit récompenses ; charger `affinity` en modification affiche son formulaire, `requires` en liste déroulante, `values` en objet. « Écrire » sans rien changer réécrit le fichier à l'identique (`git status --short` vide ensuite). **Annuler tout changement** avant de continuer.

- [ ] **Step 8: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1151: All tests passed!`

- [ ] **Step 9: Commit**

```bash
git add lib/services/content_editor/entity_descriptor.dart lib/services/content_editor/entity_validator.dart lib/ui/widgets/content_editor/editor_style.dart test/unit/content_editor/entity_descriptor_test.dart test/unit/content_editor/entity_validator_test.dart
git commit -m "feat(editeur): les recompenses de niveau deviennent editables

Huitieme categorie, en regard de la neuvieme source ajoutee au lot C. Le
catalogue, les valeurs connues, le formulaire infere, l ecrivain et l aller
retour sur les fichiers livres sont tous pilotes par la table : une entree
suffit.

Spec P-41, §9.2.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Le menu de debug expose et règle l'identité de la run

**Files:**
- Modify: `lib/models/data/stat_rule.dart`, `lib/ui/widgets/debug/tabs/debug_hero_tab.dart`
- Test: `test/widget/debug_drawer_test.dart`

**Interfaces:**
- Consumes: `runProvider`, `DebugActions.updateHeroStats`, `EntityStats.mightTargets`, `RunState.statRules` / `.activePassive`, `MightTarget.values`.
- Produces: `StatRule.toString()` — la règle dans le vocabulaire du fichier de classe.

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/widget/debug_drawer_test.dart` :

**a)** Ajouter une fixture de classe qui convertit, à côté de `_paladin` :

```dart
const _berserker = HeroData(
  id: 'berserker',
  nameEn: 'Berserker',
  nameFr: 'Berserker',
  descriptionEn: 'Damage oriented',
  descriptionFr: 'Oriente degats',
  classCard: 'berserker.png',
  maxHp: 80,
  maxMana: 3,
  luck: 0,
  mastery: 0,
  critChance: 10,
  mightTargets: {MightTarget.attack},
  statRules: [
    StatRule(
      stat: RuleStat.armor,
      mode: RuleMode.convert,
      to: RuleTarget.statusMight,
      duration: 1,
    ),
  ],
);
```

**b)** Rendre le conteneur paramétrable par la classe et le passif :

```dart
ProviderContainer _debugRunContainer({
  List<EnemyInstance> enemies = const [],
  HeroData hero = _paladin,
  PassiveData? activePassive,
}) {
  final container = ProviderContainer();
  container.read(debugRunProvider.notifier).requestDebugRun();
  container.read(runProvider.notifier).startNewRun(hero, activePassive);
  container
      .read(combatProvider.notifier)
      .updateState(CombatState(enemies: enemies));
  return container;
}
```

**c)** Ajouter ces trois tests :

```dart
  testWidgets('l onglet Heros expose l orientation de la Puissance', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(hero: _berserker);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);
    await tester.tap(find.text('Heros'));
    await tester.pumpAndSettle();

    // Une puce par cible de `MightTarget`, generee : jamais une liste ecrite
    // a la main.
    for (final cible in MightTarget.values) {
      await _scrollTo(tester, find.text(cible.name));
      expect(find.text(cible.name), findsOneWidget, reason: cible.name);
    }
  });

  testWidgets('l onglet Heros expose les regles de stat et le passif', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(
      hero: _berserker,
      activePassive: _rage,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);
    await tester.tap(find.text('Heros'));
    await tester.pumpAndSettle();

    // La regle, dans le vocabulaire du fichier : c'est la donnee que le
    // developpeur edite, pas la phrase du joueur.
    final regle = _berserker.statRules.first.toString();
    await _scrollTo(tester, find.text(regle));
    expect(find.text(regle), findsOneWidget);

    await _scrollTo(tester, find.textContaining('rage'));
    expect(find.textContaining('rage'), findsWidgets);
  });

  testWidgets('la derniere cible de Puissance ne peut pas etre retiree', (tester) async {
    sizeScreen(tester);
    final container = _debugRunContainer(hero: _berserker);
    addTearDown(container.dispose);

    await tester.pumpWidget(_harness(container, inCombat: false));
    await _openDrawer(tester);
    await tester.tap(find.text('Heros'));
    await tester.pumpAndSettle();

    // Le Berserker n'a que `attack` : la decocher laisserait une run dont la
    // Puissance ne renforce rien, etat que `HeroData.fromJson` refuse de
    // relire (`might_target.dart:20-25`).
    await _scrollTo(tester, find.text(MightTarget.attack.name));
    await tester.tap(find.text(MightTarget.attack.name));
    await tester.pumpAndSettle();

    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack},
    );

    // En revanche, en ajouter une marche.
    await _scrollTo(tester, find.text(MightTarget.skill.name));
    await tester.tap(find.text(MightTarget.skill.name));
    await tester.pumpAndSettle();

    expect(
      container.read(runProvider).heroStats.mightTargets,
      {MightTarget.attack, MightTarget.skill},
    );
  });
```

**d)** Ajouter la fixture de passif, à côté de `_talisman`. Son constructeur est `const` et ses quatre champs de prose ont un défaut (`passive_data.dart:110-125`), comme `_paladin` et `_talisman` du même fichier :

```dart
const _rage = PassiveData(
  id: 'rage',
  nameEn: 'Rage',
  nameFr: 'Rage',
  descriptionEn: 'x',
  descriptionFr: 'x',
  trigger: RelicTrigger.startOfTurn,
  effectType: 'gain_armor',
  value: 2,
);
```

**e)** Ajouter les trois imports manquants en tête du fichier, à leur place alphabétique parmi les `package:roguelike_card_game/` :

```dart
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';
import 'package:roguelike_card_game/models/might_target.dart';
```

(`relic_data.dart`, qui porte `RelicTrigger`, est déjà importé pour `_talisman`.)

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/widget/debug_drawer_test.dart`
Expected: **ÉCHEC** — les puces de `mightTargets` n'existent pas.

- [ ] **Step 3: `StatRule` se dit dans le vocabulaire du fichier**

Dans `lib/models/data/stat_rule.dart`, ajouter **après** les trois getters de la tâche 1 :

```dart
  static String _nameOf<T>(T value, Map<String, T> by) =>
      by.entries.firstWhere((entry) => entry.value == value).key;
```

et, **après** `hashCode` :

```dart
  /// La règle dans le vocabulaire du **fichier de classe** :
  /// `armor convert status:might, 1 tour`.
  ///
  /// C'est la forme qu'un développeur lit au menu de debug — la donnée qu'il
  /// édite. La phrase du joueur, elle, est `StatRuleLabel.describe`
  /// (`model_extensions.dart`), et passe par les ARB.
  @override
  String toString() => '${_nameOf(stat, _stats)} ${_nameOf(mode, _modes)} '
      '${_nameOf(to, _targets)}, $duration tour(s)';
```

- [ ] **Step 4: L'onglet Héros règle l'orientation et affiche l'identité**

Dans `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` :

**a)** Ajouter les imports :

```dart
import '../../../../models/might_target.dart';
import '../../../theme/app_spacing.dart';
```

**b)** Lire aussi la run entière : **remplacer la ligne 18**, `final stats = ref.watch(runProvider).heroStats;`, par les deux lignes suivantes — un seul `watch`, comme aujourd'hui :

```dart
    final run = ref.watch(runProvider);
    final stats = run.heroStats;
```

**c)** Insérer, **juste après** le champ « Puissance » (aujourd'hui lignes 38-45), la rangée de puces :

```dart
        // Ce que la Puissance renforce. Une puce par valeur de `MightTarget`,
        // **generee** : une liste ecrite a la main divergerait de
        // l'enumeration au premier ajout (ADR-090).
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Row(
            children: [
              const Expanded(child: Text('Puissance : cibles')),
              for (final target in MightTarget.values)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: FilterChip(
                    label: Text(target.name),
                    selected: stats.mightTargets.contains(target),
                    onSelected: (_) => _toggleTarget(ref, stats, target),
                  ),
                ),
            ],
          ),
        ),
```

**d)** Ajouter la méthode de bascule, en fin de classe :

```dart
  /// Ajoute ou retire [target], **sans jamais vider l'ensemble**.
  ///
  /// `HeroData.fromJson` refuse une liste vide comme une faute de donnee
  /// (`might_target.dart:20-25`) : un outil de debug ne doit pas produire un
  /// etat que la couche de donnees refuse de relire. Pour une run dont la
  /// Puissance ne renforce rien, le reglage prevu est le champ « Puissance »
  /// a 0.
  void _toggleTarget(WidgetRef ref, EntityStats stats, MightTarget target) {
    final next = {...stats.mightTargets};
    if (next.contains(target)) {
      if (next.length == 1) return;
      next.remove(target);
    } else {
      next.add(target);
    }
    DebugActions.updateHeroStats(
      ref.read,
      (s) => s.copyWith(mightTargets: next),
    );
  }
```

(ajouter `import '../../../../models/entity_stats.dart';` pour le type du paramètre.)

**e)** Ajouter le bloc en lecture seule, **avant** le premier `Divider()` (aujourd'hui ligne 62) :

```dart
        const Divider(),
        // L'identite de la classe telle que la run la porte. En lecture
        // seule : ces trois-la viennent du `class.json` et du choix de
        // passif, et les ecraser ici produirait une run qu'aucune sauvegarde
        // ne saurait relire (`RunState.statRules` n'est pas serialise, il est
        // relu de la classe).
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text('Classe : ${run.heroClassId}'),
        ),
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text(
            run.statRules.isEmpty
                ? 'Regles de stat : aucune'
                : 'Regles de stat :',
          ),
        ),
        for (final rule in run.statRules)
          Padding(
            padding: AppSpacing.paddingVSm,
            // `StatRule.toString()` : le vocabulaire du fichier, pas la
            // phrase du joueur.
            child: Text('$rule'),
          ),
        Padding(
          padding: AppSpacing.paddingVSm,
          child: Text('Passif actif : ${run.activePassive?.id ?? 'aucun'}'),
        ),
```

- [ ] **Step 5: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/widget/debug_drawer_test.dart`
Expected: **tout vert**. Si un test **existant** rougit sur un `_scrollTo` qui n'atteint plus sa cible, allonger son défilement : le bloc neuf rallonge la liste (conséquence assumée n° 4).

- [ ] **Step 6: Vérifier dans l'application**

Run: `flutter run -d windows`, démarrer une run de debug avec le Berserker, ouvrir le tiroir DEBUG puis l'onglet « Heros ».
Expected : les trois puces, `attack` cochée seule ; décocher `attack` ne fait rien ; cocher `skill` puis décocher `attack` fonctionne. Le bloc affiche `Classe : berserker`, `armor convert status:might, 1 tour(s)` et le passif retenu à la sélection.

- [ ] **Step 7: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1154: All tests passed!`

- [ ] **Step 8: Commit**

```bash
git add lib/models/data/stat_rule.dart lib/ui/widgets/debug/tabs/debug_hero_tab.dart test/widget/debug_drawer_test.dart
git commit -m "feat(debug): l onglet Heros regle l orientation et expose l identite

Le reglage de Puissance gagne le choix de ses cibles, par une puce generee par
valeur de MightTarget. La derniere ne peut pas etre retiree : HeroData refuse
une liste vide, et un outil de debug ne doit pas produire un etat que la donnee
refuse de relire.

La run affiche sa classe, ses regles de stat dans le vocabulaire du fichier, et
son passif actif.

Spec P-41, §9.2.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Vérification finale et pull request

**Files:**
- Aucun changement de code attendu. Si une vérification rougit, la corriger dans une tâche à part — pas ici.

**Interfaces:**
- Consumes: les tâches 1 à 4.
- Produces: la PR de la partie 2 du lot D, qui **clôt P-41**.

- [ ] **Step 1: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1154: All tests passed!`

- [ ] **Step 2: Aucun vocabulaire n'a été recopié**

Run: `git grep -n "'armor'\|'convert'\|'status:might'" -- lib/services/content_editor`
Expected: **aucune sortie**. Les trois vocabulaires viennent de `StatRule` ; les voir en dur dans un descripteur est le défaut que la tâche 1 existe pour éviter.

Run: `git grep -n "statusMight" -- lib/services lib/ui`
Expected: **aucune sortie** — le nom Dart n'a cours que dans `stat_rule.dart` et `model_extensions.dart`.

- [ ] **Step 3: Aucun fichier de contenu n'a bougé**

Run: `git status --short assets/`
Expected: **aucune sortie**. Ce lot ne touche que de l'outillage. Si un fichier apparaît, c'est une classe ou une récompense créée pendant une vérification manuelle : la retirer.

Run: `dart run tool/sync_assets.dart --check`
Expected: code de retour 0.

- [ ] **Step 4: Les huit catégories se tiennent**

Run: `flutter test test/unit/content_editor/ test/unit/referential_integrity_test.dart test/unit/entity_id_convention_test.dart`
Expected: **tout vert**. `entity_id_convention_test` parcourt `assets/data` en entier (`:17`) : les récompenses y étaient déjà couvertes, rien ne change pour elles.

- [ ] **Step 5: Rien de généré n'est en attente**

Run: `git status --short`
Expected: aucune sortie. Si `macos/Flutter/GeneratedPluginRegistrant.swift`, `linux/flutter/` ou `windows/flutter/` apparaissent : `git checkout --` dessus, ne jamais les commiter. Ce lot ne touche aucun ARB, donc `lib/l10n/app_localizations*.dart` ne doit pas avoir bougé.

- [ ] **Step 6: Ouvrir la pull request**

```bash
git push -u origin feat/p41-lot-d-console
```

Titre : `P-41 lot D, partie 2 — La console rattrape l identite de classe`

Corps :

```
Implemente le §9.2 de la spec S2.

- L editeur borne les trois cles de `statRules` au vocabulaire du moteur. Il
  laissait ecrire "mode": "convrt" — exactement le cas pour lequel il existe.
  Le vocabulaire est lu sur StatRule, jamais recopie : `status:might` ne
  s ecrit pas `statusMight`, et seul le parseur connait la correspondance.
  Le gabarit de classe porte la cle vide, jamais une regle toute faite.
- La creation guidee d une classe ecrit son passif de depart, derive de l
  identifiant de la classe et ne visant qu elle. Une classe creee depuis la
  console n avait aucun passif disponible : choix vide a la selection, et
  `referential_integrity_test` rouge apres coup. EntityValidator gagne
  `pendingIds` — ce que la meme transaction va ecrire —, le trou que le
  commentaire de `_signatureCards` decrit depuis P-30.
- Les recompenses de niveau deviennent la huitieme categorie editable, en
  regard de la neuvieme source ajoutee au lot C. Une entree de table suffit :
  catalogue, valeurs connues, formulaire infere, ecrivain et aller-retour sur
  les fichiers livres en decoulent.
- Le menu de debug laisse regler les cibles de la Puissance, par une puce
  generee par valeur de MightTarget, et affiche la classe de la run, ses
  regles de stat dans le vocabulaire du fichier et son passif actif.

Deja livre, verifie au passage : la validation de `classes` comme liste de
references, que le §9.2 annonçait comme « une extension a ecrire », a ete
ecrite par P-49 (referenceListKeys).

Aucun fichier de contenu n est modifie, et le jeu ne change pas : ce lot
n est que de l outillage.

`dart analyze` propre, `flutter test` vert (1154 tests, contre 1135 au depart).

**Cette PR clot P-41.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 7: Après la fusion**

Une fois la PR fusionnée, lancer le skill `patch-notes-writer` (la note `0.5.2` est rouverte en place, cf. `docs/ROADMAP.md`) puis, **une fois les deux parties du lot D fusionnées**, le skill `memory-bank-sync` — qui clôt P-41 dans `docs/ROADMAP.md` et dans `.obsidian_vault/_memory_bank/progress.md`. Les deux sont agent-gérés : ne pas éditer `assets/data/patch_notes.json`, `pubspec.yaml` (`version:`) ni `.obsidian_vault/_memory_bank/` à la main.

---

## Suites connues, laissées ouvertes

| Sujet | Où il vit |
|:---|:---|
| Le tutoriel : choix du passif, étape « Armure », étape « Jouer des cartes » | Lot D, partie 1, spec §9.1 — [plan](2026-09-20-p41-lot-d-partie-1-tutoriel.md) |
| **La Maîtrise reste absente de l'onglet « Héros » du menu de debug.** Le §9.2 ne la nomme pas, et le champ manquerait de sept lignes copiées de `luck` (`debug_hero_tab.dart:46-53`). Sans lui, la chaîne Maîtrise → passif → *Affinité*, centrale à P-49, ne s'exerce pas depuis la console. **Décision du propriétaire attendue** : élargir le périmètre du lot D, ou en faire une ligne de ROADMAP | Conséquence assumée n° 6 de ce plan |
| **`statRules` n'a pas de vrai formulaire tant que la liste est vide.** Une classe livrée qui porte déjà une règle en obtient un (`FieldKind.objectList`) ; une classe neuve n'a qu'un champ JSON brut. Ce qui manque est un **élément-modèle déclaré par le descripteur**, indépendant du gabarit : `EditorDocument.modelElementFor` lit le gabarit puis le document (`editor_document.dart:69-81`), et y mettre la règle ferait naître toute classe convertisseuse. Un champ `listModels` sur `EntityDescriptor` réglerait le cas pour `statRules` comme pour toute liste d'objets optionnelle | Décision 3 de ce plan. Extension de P-30 lot 2, non planifiée |
| **`pendingIds` n'est alimenté que par la recette de classe.** Toute transaction future qui écrira deux entités dont l'une réfère l'autre devra y verser ses identifiants. Le mécanisme est générique (`Map<EntityCategory, Set<String>>`) ; seul son unique appelant ne l'est pas | Décision 5 de ce plan |
| Le déblocage des passifs par personnage, derrière le point d'accès de P-49 — l'éditeur n'aura rien à apprendre : `classes` est déjà validé, et le filtre vivra dans `availablePassivesFor` | P-13, spec §10 |
| Le rééquilibrage des valeurs et des paliers de récompense, *Sagesse* en tête — désormais éditable depuis la console | P-16, spec §8.4 |
