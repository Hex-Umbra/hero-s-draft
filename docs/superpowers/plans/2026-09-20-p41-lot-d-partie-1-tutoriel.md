# P-41 lot D, partie 1 — Le tutoriel enseigne la classe qu'on a choisie — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le tutoriel cesse d'enseigner une règle que la classe choisie ne suit pas : l'étape de choix de classe laisse retenir un passif parmi ceux que la classe ouvre, l'étape « Armure & Dégâts » fait passer son gain de démonstration par les règles de la classe au lieu d'écrire 4 Armure en dur, l'étape « Jouer des cartes » n'annonce plus « +5 🛡️ » à un Berserker qui n'en gardera aucune, et les deux acquis que le lot B avait livrés sans les verrouiller — `critChance` forcé à 0, conversion d'armure appliquée par `playCard` — passent sous test.

**Architecture:** Aucun mécanisme nouveau. Les trois étapes cessent chacune de court-circuiter un point de passage qui existe déjà : `StatGains.apply` pour un gain d'armure (le même appel que `TutorialEngine.playCard` fait déjà), `availablePassivesFor` pour les passifs d'une classe, et `ClassPassiveList` — le bloc dépliant que l'écran de sélection a reçu au lot C — pour les afficher. Le seul texte généré est la phrase de la règle de stat, et elle est déjà écrite : `StatRuleLabel.describe`. Le tutoriel ne recopie donc toujours aucune règle (ADR-081), et il en recopiera une de moins qu'avant.

**Tech Stack:** Flutter / Dart 3.11, Flame, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md` — lire le **§9.1** en entier, puis le §1.4 (« Le tutoriel est une seconde implémentation du jeu »), le §7.1 pour `statRules` et la conversion d'armure du Berserker, le §7.3 pour son `critChance`, et le §5.1 pour le point d'accès unique aux passifs. ADR-081 (`.obsidian_vault/_adr/`) porte l'isolation du tutoriel vis-à-vis de l'état.

**Dépend de :** les lots A, B et C de P-41 et le chantier frère P-49, **tous fusionnés dans `main`** (PR #38, #39, #40, #41, #42, #43). Rien d'autre. La partie 2 du lot D — la console de debug, spec §9.2, [plan](2026-09-20-p41-lot-d-partie-2-console-de-debug.md) — est **indépendante** de celle-ci : voir « Pourquoi deux plans pour le lot D » ci-dessous.

## Pourquoi deux plans pour le lot D

Le §9 de la spec réunit deux sujets qui ne partagent **aucun fichier de `lib/`**, aucun type, aucun test, et dont la livraison de l'un ne change rien à la vérification de l'autre.

| | Partie 1 *(ce plan)* | Partie 2 — [plan](2026-09-20-p41-lot-d-partie-2-console-de-debug.md) |
|:---|:---|:---|
| Spec | §9.1 | §9.2 |
| Contenu | Le tutoriel : choix du passif, étape « Armure », étape « Jouer des cartes » | La console : validation de `statRules`, passif garanti à la création guidée, récompenses de niveau éditables, identité de la run au menu de debug |
| Fichiers de `lib/` | `lib/tutorial/` seul, plus `lib/models/data/model_extensions.dart` pour un libellé | `lib/services/content_editor/`, `lib/ui/widgets/debug/`, `lib/models/data/stat_rule.dart` |
| Le joueur le voit ? | **Oui** — le tutoriel enseigne autre chose | **Non** — outillage de développement, `kDebugMode` compris |
| Ce qui casse si c'est faux | Un nouveau joueur apprend une règle fausse | Un auteur de contenu écrit un fichier que le jeu refusera |
| Branche | `feat/p41-lot-d-tutoriel` | `feat/p41-lot-d-console` |

**Aucune des deux ne dépend de l'autre** ; elles peuvent s'exécuter dans n'importe quel ordre, ou en parallèle. Le seul point de contact est `lib/models/data/stat_rule.dart` : cette partie le **lit** sans le modifier (par `StatRuleLabel.describe`, écrit au lot C), la partie 2 lui ajoute trois accesseurs de vocabulaire. Si les deux branches vivent en même temps, la fusion de `stat_rule.dart` est un ajout pur, sans conflit de ligne.

## Global Constraints

- **Le jeu ne change pas ; le tutoriel, si.** Aucune valeur de carte, d'ennemi, de relique, de passif, de récompense ni de classe ne bouge. Ce qui change est ce que le tutoriel **montre et permet**, borné à ceci : le choix du passif à l'étape 02, la démonstration de l'étape « Armure », le texte flottant d'un gain d'armure à l'étape « Jouer des cartes », et la prose de ces deux étapes. Rien d'autre.
- **Le tutoriel ne recopie aucune règle** (ADR-081, vérifié par `test/tutorial/tutorial_isolation_test.dart`). Toute règle qu'il applique vient d'une fonction pure du jeu : `StatGains.apply` (`lib/game/systems/stat_gains.dart`), `PowerRules`, `EntityStats.takeDamage`, `availablePassivesFor` (`lib/game/systems/passive_availability.dart`). **Écrire `if (hero.id == 'berserker')` dans ce lot est un défaut, pas un raccourci** (ADR-090) — et la tentation est maximale ici.
- **Une seule exception à la fidélité, et elle est explicite** : `critChance` est forcé à 0 dans `TutorialMockState.baseStatsForHero` (`tutorial_engine.dart:55-72`). Le lot B l'a écrite et commentée ; la tâche 1 la met sous test, ce que le §9.1 exige (« une exception explicite **et testée** »). Ne pas la retirer, ne pas l'étendre.
- **`dart analyze` doit afficher `No issues found!`** à la fin de **chaque** tâche.
- **`flutter test` doit être entièrement vert à la fin de chaque tâche.** Point de départ **mesuré le 2026-09-20 sur `6bc3705`** : **1135 tests**, `dart analyze` propre. Les totaux annoncés tâche par tâche sont une **prévision arithmétique** à partir de ce chiffre, **non un rejeu** : un écart signale un test oublié ou dupliqué, à comprendre avant de continuer — jamais un nombre à réajuster à l'aveugle.
- **Ne jamais lancer `dart format`** : le dépôt ne l'utilise pas (120 des 185 fichiers de `lib/` en seraient modifiés).
- Créer et modifier les fichiers avec les outils Write / Edit. **Jamais par heredoc bash** pour du contenu : les heredocs de cet environnement mangent les antislashs, et le code Dart et les ARB de ce plan en contiennent (`l\'Armure`, `\n`, `{duration, plural, ...}`).
- Tout texte joueur d'un JSON porte ses variantes `_fr` **et** `_en` (`CLAUDE.md`). Ce lot n'écrit aucun JSON de contenu, mais il écrit des ARB et de la prose de `tutorial_data.dart`, qui suivent la même règle sous une autre forme (`bodyFr`/`bodyEn`).
- Les fichiers `lib/l10n/app_localizations.dart`, `app_localizations_en.dart` et `app_localizations_fr.dart` sont générés **et commités** : après toute modification d'un ARB, lancer `flutter gen-l10n` et commiter les trois. Le fichier **gabarit** est `app_en.arb` (`l10n.yaml`) : c'est lui qui porte les blocs `@clé` de métadonnées.
- Ne pas toucher `assets/data/patch_notes.json` ni le champ `version:` de `pubspec.yaml` : ils appartiennent au skill `patch-notes-writer`.
- Ne toucher à **aucun fichier de `.obsidian_vault/_memory_bank/`, `_adr/`, `_rules/` ou `_patterns/`** : ils appartiennent au skill `memory-bank-sync`, lancé après la fusion.
- Le code va sur la branche `feat/p41-lot-d-tutoriel`, jamais sur `main`. La documentation de cette partie — ce plan, celui de la partie 2, et leurs liens dans `docs/INDEX.md` et `docs/ROADMAP.md` — est **déjà commitée sur `main`** avant l'exécution. **Pas de worktree** (décision du propriétaire) : la branche est créée dans le checkout principal, même si le skill d'exécution en propose un.
- Messages de commit en français, forme `type(portee): message`, **sans accents ni apostrophes**, terminés par la ligne `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`.
- Les commandes `flutter` peuvent réécrire des fichiers générés sans en changer le contenu, fins de ligne seulement : `macos/Flutter/GeneratedPluginRegistrant.swift` et, dans un checkout neuf, ceux de `linux/flutter/` et de `windows/flutter/`. S'ils apparaissent dans `git status`, les restaurer (`git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift linux/flutter windows/flutter`) ; ne jamais les commiter.

## Ce que la spec demande et qui est **déjà livré**

Le §9.1 a été écrit avant les lots B et C ; trois de ses cinq points sont tombés en chemin. Les vérifier au passage, ne pas les réécrire.

| Ce que le §9.1 demande | État sur `6bc3705` |
|:---|:---|
| « Les règles viennent de la fonction pure du lot A […] aucune recopie de `statRules`, de la maîtrise ou de l'orientation de la Puissance dans `lib/tutorial/` » | ✅ **Fait au lot B.** `TutorialEngine.playCard` appelle `StatGains.apply(..., mockState.chosenHero?.statRules ?? const [])` (`tutorial_engine.dart:363-370`) et `heroStats.damageBonusFor(card.data.type)` (`:355`) ; `baseStatsForHero` copie `mightTargets`, `mastery` et `luck` de la classe (`:62-72`). **Non testé** — c'est l'objet de la tâche 1 |
| « Le tutoriel **force** [`critChance`] à 0. C'est une exception explicite **et testée** » | ⚠️ **Explicite, pas testée.** Le commentaire est à `tutorial_engine.dart:55-61`, l'omission du champ à `:62-72`. Aucun test ne la tient : tâche 1 |
| « Les récompenses enseignées lisent le registre de la partie 1 du lot C » | ✅ **Fait au lot C.** `tutorial_draft_widget.dart:41-45` tire par `LevelUpRewardService.generateChoices(rewards: widget.engine.data.levelUpRewards, ...)`, et `tutorial_prose.dart` remplit la prose de l'étape draft depuis le registre (`tutorial_prose_test.dart`) |
| « L'étape de choix de classe propose les passifs disponibles […] `tutorial_fixtures.dart:54` cesse de supposer un passif unique » | ❌ **À faire** — tâche 2. `TutorialFixtures.passiveFor` rend `availablePassivesFor(hero, registry).first` (`tutorial_fixtures.dart:57-58`) et `chooseHero` l'écrit sans recours (`tutorial_engine.dart:132`) |
| « L'étape « Armure » […] le tutoriel n'enseigne jamais une règle que la classe choisie ne suit pas » | ❌ **À faire** — tâche 3 |

## La prémisse du §9.1 sur l'étape « Armure » a vieilli — ce qui reste vrai

> « L'étape « Armure » **se valide** aujourd'hui sur l'armure gagnée pendant l'étape. Pour une classe qui convertit l'armure, elle **ne peut plus être franchie** telle quelle. »

**Ni l'un ni l'autre n'est vrai sur `6bc3705`**, et il faut le savoir avant de chercher un blocage qui n'existe pas :

1. **L'étape « Armure & Dégâts » (`TutorialStepType.armorDamage`) n'a aucune condition de franchissement.** Elle tombe dans le `default: return true` de `_isStepActionComplete` (`tutorial_screen.dart:83-84`). Le drapeau `armorGainedThisStep` garde **une autre** étape, « Jouer des cartes & finir le tour » (`tutorial_screen.dart:67-71`) — ce que dit d'ailleurs la documentation du drapeau lui-même (`tutorial_engine.dart:303-309`).
2. **Même cette étape-là n'est pas bloquée pour un Berserker.** `playCard` arme le drapeau sur `if (scaled > 0)` (`tutorial_engine.dart:371`), c'est-à-dire sur la **valeur imprimée de la carte**, avant toute conversion. Le lot B l'a écrit ainsi ; rien à corriger.

**Ce qui reste, et qui est le vrai sujet de ce lot**, c'est la phrase qui suit dans la spec : *« le tutoriel n'enseigne jamais une règle que la classe choisie ne suit pas »*. Or il l'enseigne à deux endroits :

- `TutorialArmorWidget` fixe l'Armure par `engine.setHeroArmor(4)` (`tutorial_armor_widget.dart:90`), qui écrit `armure: 4` **en court-circuitant `StatGains.apply`**. Le panneau intitulé « AVEC ARMURE », posé au-dessus du passif du joueur et calé sur ses PV max réels, montre donc un Berserker tenant 4 Armure — ce qui ne lui arrive jamais, sa classe convertissant chaque point gagné en Puissance temporaire d'un tour (`assets/data/classes/berserker/class.json`, `statRules`).
- `TutorialPlayCardWidget` annonce « +5 🛡️ » en texte flottant sur la valeur imprimée de la carte (`tutorial_play_card_widget.dart:340-343`), tandis que le badge d'Armure juste en dessous reste à 0 (`:411`). **La spec ne mentionne pas ce point** : il est ajouté au périmètre sur décision du propriétaire du 2026-09-20 (tâche 4) — corriger un mensonge et en laisser un autre deux étapes plus tôt n'aurait pas de sens.

## Décisions prises à la rédaction du plan

La spec pose la contrainte, pas la solution. Sept points d'implémentation sont tranchés ici, et l'exécutant n'a pas à les rouvrir.

| # | Question | Décision | Pourquoi |
|:---|:---|:---|:---|
| **1** | Par où la règle de la classe entre-t-elle dans l'étape « Armure » ? | **Par la simulation *et* par une phrase générée.** Le gain de démonstration passe par `StatGains.apply` avec les `statRules` de la classe ; le titre du panneau droit est généré depuis la règle ; une phrase générée par `StatRuleLabel.describe` la nomme sous les panneaux | **Tranché avec le propriétaire le 2026-09-20.** La phrase seule laisserait le panneau montrer un Berserker tenant 4 Armure ; la simulation seule laisserait le joueur deviner pourquoi les deux panneaux perdent 10 PV. Les deux ensemble sont la seule version où ce que le panneau montre est ce qui lui arriverait |
| **2** | La démonstration devient-elle un seul temps ou deux ? | **Deux temps** : à 200 ms le **gain** (le panneau droit montre ce qu'il a obtenu), à 900 ms le **coup** sur les deux panneaux | Un panneau qui affiche « 0 🛡️ ⚡4 » sans qu'on ait vu le gain arriver est illisible. Et cela supprime le problème d'état initial : les deux panneaux démarrent désormais à 0 Armure, donc plus rien n'est écrit en dur avant que la règle n'ait parlé. La version d'aujourd'hui préremplissait `_rightArmor = 4` dans un champ (`tutorial_armor_widget.dart:28`) |
| **3** | Où vit le titre court du panneau droit ? | Dans `lib/models/data/model_extensions.dart`, `StatRuleLabel.shortTitle`, sur le **même `switch` exhaustif** sur `(stat, mode, to)` que `describe` | C'est déjà là que vit la phrase longue (lot C, partie 2, décision 3). Deux fichiers pour deux formes du même libellé seraient deux endroits à tenir, et le `switch` exhaustif fait rougir l'analyseur si une valeur d'énumération arrive sans son libellé |
| **4** | La phrase de la règle est à la troisième personne (« **Son** Armure devient… ») ; le tutoriel tutoie. Faut-il une seconde variante ? | **Non.** La phrase est rendue **sous le nom de la classe**, dans un encadré de la même forme que celui du passif déjà présent (`tutorial_armor_widget.dart:279-330`) : « Le Berserker » / « Son Armure devient de la Puissance pour un tour. » | La troisième personne est alors juste, et `describe` reste une seule chaîne ARB pour ses deux lecteurs. Une variante tutoyante doublerait deux clés ARB par règle, pour un gain nul |
| **5** | Le tutoriel borne-t-il le choix à trois passifs ? Les cartes non choisies montrent-elles les leurs ? | **Aucune borne** — tous ceux que rend `availablePassivesFor` —, et **chaque carte montre son passif retenu replié**, seule la carte choisie étant dépliée | C'est exactement le comportement de l'écran de sélection (lot C, décision 6, et `class_passive_list.dart:56-58`), donc la fidélité coûte ici moins cher que l'écart. Replié, le joueur compare les trois classes sans rien ouvrir ; déplié, il choisit. Trois est le compte d'aujourd'hui, pas une règle : P-13 le fera varier |
| **6** | `ClassPassiveList` vit dans `lib/ui/widgets/`. Le tutoriel a-t-il le droit de l'importer ? | **Oui.** `lib/tutorial/widgets/tutorial_draft_widget.dart:5-6` importe déjà `ui/widgets/draft/draft_choice_card.dart` et `draft_choice_labels.dart` | ADR-081 interdit au tutoriel de lire un **provider d'état**, pas de réutiliser un widget de présentation sans état. Réutiliser est même le remède au §1.4 (« Le tutoriel est une seconde implémentation du jeu ») : un widget partagé de moins à faire diverger |
| **7** | `setHeroArmor` survit-elle ? | **Non** : remplacée par `gainArmorForDemo(int amount)`, qui passe par `StatGains.apply`. `resetHeroStatsForDemo` gagne en plus `statuses: []` | Laisser un point d'entrée qui écrit `armure:` sans passer par les règles, c'est laisser la porte par laquelle le défaut est entré. Et sans le nettoyage des statuts, presser deux fois « Voir la différence » afficherait +4 puis +8 Puissance : `EntityStats.addStatus` empile (`entity_stats.dart:134-144`) |

## Conséquences assumées, à annoncer plutôt qu'à découvrir

1. **Le parcours Berserker du tutoriel ne démontre plus l'absorption d'armure sur le joueur.** Ses deux panneaux perdent 10 PV, et le contraste se déplace sur « 0 Armure contre +4 Puissance ». La règle universelle reste **écrite** dans la prose de l'étape (« L'Armure absorbe les dégâts avant vos PV ») et le joueur la rencontre sur les ennemis, qui en gagnent par leur intention « Défense ». C'est le prix du choix n° 1, et il est assumé : un panneau qui montre au Berserker une armure qu'il n'aura jamais est pire qu'une démonstration qu'il devra lire plutôt que voir.
2. **Deux des trois classes livrées ne changent pas du tout.** Le Paladin et le Mage n'ont pas de `statRules` : leurs panneaux, leur titre et leur absence d'encadré de règle sont identiques à aujourd'hui, à la découpe en deux temps près. **Un seul parcours sur trois est visuellement modifié.** Ce n'est pas un mécanisme spéculatif pour autant : la règle du Berserker est livrée et jouable depuis le lot B.
3. **La carte de classe du tutoriel s'allonge**, de trois tuiles de passif sur la classe choisie. Les trois cartes sont dans un `Wrap` de 190 px de large à l'intérieur d'un `SingleChildScrollView` (`tutorial_class_choice_widget.dart:43-55`), qui absorbe la hauteur. **À revoir à l'œil après la tâche 2** — un débordement est un défaut de cette partie, pas un « à voir plus tard ».
4. **La prose de deux étapes change**, donc ce que lit un joueur francophone et anglophone. L'étape 02 annonçait « leur passif, qui décide de la façon dont elles gagnent de l'Armure » : le passif est désormais un **choix**, et pour le Berserker la classe décide aussi s'il en garde. L'étape « Armure & Dégâts » annonçait « ce que votre classe change, c'est la *façon d'en gagner* » : c'est incomplet depuis le lot B.
5. **Le tutoriel n'applique toujours pas le passif choisi.** Il l'affiche (étape 02, étape « Armure ») et le passe au tirage des récompenses (`tutorial_draft_widget.dart:44`). `TraitSystem` n'est pas appelé depuis `lib/tutorial/` et ce lot ne l'y appelle pas : choisir *Rage* plutôt que *Frénésie* ne change aucun chiffre du tutoriel. C'était déjà vrai du passif unique ; la nouveauté est seulement que le joueur en désigne un.
6. **`setHeroArmor` disparaît de l'API du moteur** (décision 7). Quatre tests de `tutorial_engine_test.dart` l'appellent (`:108`, `:393`, `:486`, `:502`) et migrent vers `gainArmorForDemo` — sans changer d'assertion : sans classe choisie, `statRules` est vide et le comportement est identique.

## Carte des fichiers

| Fichier | Responsabilité | Tâche |
|:---|:---|:---|
| `test/tutorial/tutorial_engine_test.dart` | Verrouille `critChance: 0`, la copie de l'identité de classe et la conversion d'armure ; puis `gainArmorForDemo` | 1, 2, 3 |
| `lib/tutorial/tutorial_fixtures.dart` | `passivesFor(hero)` remplace `passiveFor(hero)` | 2 |
| `lib/tutorial/tutorial_engine.dart` | `chooseHero` lit la liste ; `choosePassive` ; `gainArmorForDemo` ; `resetHeroStatsForDemo` nettoie les statuts ; `setHeroArmor` supprimée | 2, 3 |
| `lib/tutorial/widgets/tutorial_class_choice_widget.dart` | La carte de classe porte `ClassPassiveList` | 2 |
| `lib/tutorial/tutorial_data.dart` | La prose des étapes 02 et « Armure & Dégâts » | 2, 3 |
| `lib/l10n/app_en.arb`, `app_fr.arb` | Les deux titres courts de règle de stat | 3 |
| `lib/models/data/model_extensions.dart` | `StatRuleLabel.shortTitle` | 3 |
| `lib/tutorial/widgets/tutorial_armor_widget.dart` | La démonstration passe par les règles de la classe, en deux temps | 3 |
| `lib/tutorial/widgets/tutorial_play_card_widget.dart` | Le texte flottant annonce le gain réel | 4 |
| `test/tutorial/tutorial_fixtures_test.dart` | Les passifs ouverts par classe | 2 |
| `test/widget/tutorial_class_step_test.dart` | Ce que la carte de classe montre et ce qu'elle retient | 2 |
| `test/widget/tutorial_armor_step_test.dart` *(nouveau)* | Ce que la démonstration montre, par classe | 3 |
| `test/widget/tutorial_play_card_step_test.dart` *(nouveau)* | Le texte flottant d'un gain converti | 4 |

---

### Task 0: La branche, depuis la documentation déjà commitée

**À faire dans le checkout principal, avant toute tâche de code.**

**Files:**
- Aucun. La documentation de ce lot est **déjà commitée sur `main`** : ce plan, celui de la partie 2, et leurs liens dans `docs/INDEX.md` et `docs/ROADMAP.md`.

**Interfaces:**
- Consumes: ce plan, commité sur `main` ; les lots A, B, C de P-41 et P-49, fusionnés.
- Produces: la branche `feat/p41-lot-d-tutoriel`, et le **compte de tests de départ réellement mesuré**, dont dépendent toutes les prévisions de ce plan.

- [ ] **Step 1: Vérifier l'état de départ**

Run: `git switch main && git pull`, puis `git checkout -- macos/Flutter/GeneratedPluginRegistrant.swift` (fins de ligne seulement), puis `git status --short`
Expected: **aucune sortie** — l'arbre de travail est propre.

Run: `git log --oneline -6`
Expected: on y trouve `2f850c4 Merge pull request #43` — la fusion de la partie 2 du lot C. Si elle manque, **s'arrêter et le signaler** : la tâche 2 réutilise `ClassPassiveList`, et la tâche 3 réutilise `StatRuleLabel.describe`, tous deux écrits là-bas.

Run: `ls lib/ui/widgets/class_passive_list.dart lib/models/data/model_extensions.dart`
Expected: les deux fichiers existent. Même conclusion sinon.

- [ ] **Step 2: Créer la branche**

Run: `git switch -c feat/p41-lot-d-tutoriel` — depuis `main`, dans le checkout principal. **Pas de worktree**, même si le skill d'exécution en propose un.

- [ ] **Step 3: Mesurer la base — et noter le chiffre**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+N: All tests passed!`, **prévision N = 1135** (mesuré le 2026-09-20 sur `6bc3705`).

**Noter N.** Toutes les prévisions de ce plan sont écrites à partir de 1135 ; si N diffère, décaler chaque prévision du même écart plutôt que de la recalculer.

---

### Task 1: Le déterminisme et la conversion, mis sous test

**Ce que cette tâche n'est pas :** une correction. Le lot B a écrit le comportement ; personne ne l'a verrouillé. Le §9.1 exige une exception « explicite **et testée** » : elle est explicite depuis le lot B, elle devient testée ici. **Ces tests doivent passer du premier coup** — c'est leur objet. Si l'un d'eux rougit, c'est une régression du lot B, à comprendre avant d'aller plus loin, **jamais un test à assouplir**.

**Files:**
- Test: `test/tutorial/tutorial_engine_test.dart` (ajout d'un groupe ; aucun fichier de `lib/` n'est touché)

**Interfaces:**
- Consumes: `TutorialEngine`, `TutorialMockState.baseStatsForHero`, `TutorialEngine.playCard`, `TutorialFixtures.heroes`, `HeroData.critChance` / `.mightTargets` / `.mastery` / `.statRules`, `EntityStats.statuses` / `.effectiveMight`, `StatGains.apply`.
- Produces: rien de nouveau. Un filet de sécurité sur cinq comportements dont les tâches 2 à 4 dépendent.

- [ ] **Step 1: Écrire les tests**

Ajouter ce groupe à `test/tutorial/tutorial_engine_test.dart`, **juste après** le groupe `'L\'absorption d\'armure suit EntityStats.takeDamage'` (il se termine ligne 122) :

```dart
  // L'identite de la classe traverse le tutoriel sans y etre recopiee
  // (ADR-081, spec P-41 §9.1). Le lot B a ecrit ce comportement ; ce groupe
  // le verrouille. Il doit passer du premier coup : un rouge ici est une
  // regression du lot B, pas une etape de ce lot.
  group('L identite de la classe traverse le tutoriel', () {
    HeroData heroDit(String id) =>
        engine.fixtures.heroes.firstWhere((h) => h.id == id);

    test('le tutoriel force critChance a 0, y compris pour le Berserker', () {
      final berserker = heroDit('berserker');
      // La classe en declare bien un : sans cela le test ne prouverait rien.
      expect(berserker.critChance, greaterThan(0));

      engine.chooseHero(berserker);

      // L'unique exception, explicite et testee, a la fidelite au jeu : une
      // demonstration qui annonce les degats d'une carte avant de la jouer ne
      // peut pas les voir varier une fois sur dix (spec §9.1).
      expect(engine.mockState.heroStats.critChance, 0);
    });

    test('tout le reste de l identite est copie, jamais recopie', () {
      for (final hero in engine.fixtures.heroes) {
        engine.chooseHero(hero);
        final stats = engine.mockState.heroStats;

        expect(stats.maxPv, hero.maxHp, reason: hero.id);
        expect(stats.maxMana, hero.maxMana, reason: hero.id);
        expect(stats.mightTargets, hero.mightTargets, reason: hero.id);
        expect(stats.mastery, hero.mastery, reason: hero.id);
        expect(stats.luck, hero.luck, reason: hero.id);
      }
    });

    test('une classe qui convertit son armure la convertit aussi ici', () {
      final berserker = heroDit('berserker');
      // La classe declare bien une regle : sinon le test ne prouve rien.
      expect(berserker.statRules, isNotEmpty);

      engine.chooseHero(berserker);
      engine.seedHand([TutorialFixtureIds.defend]);
      final valeur = engine.fixtures
          .card(TutorialFixtureIds.defend)
          .effects
          .firstWhere((e) => e.type == 'armor')
          .value;

      engine.playCard(engine.mockState.hand.first);

      // Aucune Armure conservee, et la Puissance temporaire a sa place :
      // c'est `StatGains.apply` qui le decide, pas le tutoriel.
      expect(engine.mockState.heroStats.armure, 0);
      final buff = engine.mockState.heroStats.statuses
          .firstWhere((s) => s.id == 'might');
      expect(buff.value, valeur);
      expect(buff.duration, berserker.statRules.first.duration);
    });

    test('une classe sans regle de stat garde son armure', () {
      final paladin = heroDit('paladin');
      expect(paladin.statRules, isEmpty);

      engine.chooseHero(paladin);
      engine.seedHand([TutorialFixtureIds.defend]);
      final valeur = engine.fixtures
          .card(TutorialFixtureIds.defend)
          .effects
          .firstWhere((e) => e.type == 'armor')
          .value;

      engine.playCard(engine.mockState.hand.first);

      expect(engine.mockState.heroStats.armure, valeur);
      expect(engine.mockState.heroStats.statuses, isEmpty);
    });

    test('un gain converti verrouille quand meme l etape', () {
      // `armorGainedThisStep` garde l'etape « Jouer des cartes » : il se lit
      // sur la valeur imprimee de la carte, avant conversion. Sans cela, le
      // parcours Berserker serait bloque sur cette etape.
      engine.chooseHero(heroDit('berserker'));
      engine.seedHand([TutorialFixtureIds.defend]);
      expect(engine.armorGainedThisStep, isFalse);

      engine.playCard(engine.mockState.hand.first);

      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.armorGainedThisStep, isTrue);
    });
  });
```

Ajouter l'import manquant en tête du fichier, à sa place alphabétique parmi les `package:roguelike_card_game/` :

```dart
import 'package:roguelike_card_game/models/data/hero_data.dart';
```

- [ ] **Step 2: Lancer le fichier**

Run: `flutter test test/tutorial/tutorial_engine_test.dart`
Expected: **tout vert**, 5 tests de plus qu'avant. Un rouge ici est une régression du lot B : le comprendre avant de continuer.

- [ ] **Step 3: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1140: All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add test/tutorial/tutorial_engine_test.dart
git commit -m "test(tutoriel): l identite de la classe traverse le moteur, sous test

Le lot B a ecrit le comportement sans le verrouiller. Le §9.1 de la spec
exige une exception explicite ET testee pour critChance ; les quatre autres
tests tiennent la copie de l identite de classe et la conversion d armure du
Berserker, dont les taches suivantes dependent.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: L'étape de choix de classe propose les passifs de la classe

**Files:**
- Modify: `lib/tutorial/tutorial_fixtures.dart`, `lib/tutorial/tutorial_engine.dart`, `lib/tutorial/widgets/tutorial_class_choice_widget.dart`, `lib/tutorial/tutorial_data.dart`
- Test: `test/tutorial/tutorial_fixtures_test.dart`, `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_class_step_test.dart`

**Interfaces:**
- Consumes: `availablePassivesFor(HeroData, GameDataRegistry)` (`lib/game/systems/passive_availability.dart`), `ClassPassiveList` (`lib/ui/widgets/class_passive_list.dart`), `ClassIdentity.colorOf` (`lib/ui/widgets/class_identity.dart`).
- Produces:
  - `List<PassiveData> TutorialFixtures.passivesFor(HeroData hero)` — **remplace** `PassiveData passiveFor(HeroData hero)`, qui disparaît.
  - `void TutorialEngine.choosePassive(PassiveData passive)`.
  - `TutorialEngine.chooseHero` retient désormais le **premier** de la liste, ou `null` si elle est vide.

- [ ] **Step 1: Écrire les tests qui échouent**

Dans `test/tutorial/tutorial_fixtures_test.dart`, **remplacer** le test `'chaque classe a pour passif le premier que lui ouvre le point d acces'` (lignes 28-39) par ces deux-ci :

```dart
    test('chaque classe ouvre les passifs que le point d acces lui rend', () {
      // Le tutoriel ne filtre ni ne tronque : il rend ce que rend le point
      // d'acces unique de P-49, dans son ordre (spec P-41, §8.3 — « pas de
      // take(3) »). Trois par classe aujourd'hui ; P-13 fera varier ce
      // nombre, et ce test suivra sans etre reecrit.
      for (final hero in fixtures.heroes) {
        expect(
          fixtures.passivesFor(hero),
          availablePassivesFor(hero, data),
          reason: hero.id,
        );
        expect(fixtures.passivesFor(hero), isNotEmpty, reason: hero.id);
      }
    });

    test('le premier passif de chaque classe est son choix par defaut', () {
      // Le premier par rang d'affichage : celui avec lequel la carte de
      // classe s'affiche repliee, et celui que `chooseHero` retient tant que
      // le joueur n'en designe pas un autre.
      const attendus = {
        'paladin': 'regen_armor',
        'berserker': 'rage',
        'mage': 'channeling',
      };
      for (final hero in fixtures.heroes) {
        expect(fixtures.passivesFor(hero).first.id, attendus[hero.id]);
      }
    });
```

Ajouter en tête du même fichier, à sa place alphabétique :

```dart
import 'package:roguelike_card_game/game/systems/passive_availability.dart';
```

Dans `test/tutorial/tutorial_engine_test.dart`, ajouter ce groupe **après** le groupe `'L identite de la classe traverse le tutoriel'` écrit à la tâche 1 :

```dart
  group('Le choix du passif', () {
    test('choisir une classe retient son premier passif', () {
      final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
      engine.chooseHero(mage);

      expect(
        engine.mockState.activePassive?.id,
        engine.fixtures.passivesFor(mage).first.id,
      );
    });

    test('choisir un passif remplace le choix par defaut', () {
      final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
      engine.chooseHero(mage);
      final autre = engine.fixtures.passivesFor(mage).last;
      // Le pool en contient bien plus d'un : sinon le test ne prouve rien.
      expect(autre.id, isNot(engine.mockState.activePassive?.id));

      engine.choosePassive(autre);

      expect(engine.mockState.activePassive?.id, autre.id);
    });

    test('changer de classe repose le passif par defaut de la nouvelle', () {
      // Regression a eviter : le passif est de la tranche persistante, comme
      // la classe. Sans remise a zero, un Mage garderait le passif d'un
      // Berserker, qui n'est pas dans son pool.
      final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
      final berserker =
          engine.fixtures.heroes.firstWhere((h) => h.id == 'berserker');

      engine.chooseHero(mage);
      engine.choosePassive(engine.fixtures.passivesFor(mage).last);
      engine.chooseHero(berserker);

      expect(
        engine.mockState.activePassive?.id,
        engine.fixtures.passivesFor(berserker).first.id,
      );
    });

    test('le passif choisi survit aux changements d etape', () {
      final paladin = engine.fixtures.heroes.first;
      engine.chooseHero(paladin);
      final autre = engine.fixtures.passivesFor(paladin).last;
      engine.choosePassive(autre);

      engine.nextStep();
      engine.nextStep();

      expect(engine.mockState.activePassive?.id, autre.id);
    });
  });
```

Dans `test/widget/tutorial_class_step_test.dart`, **remplacer** le test `'le passif de chaque classe est affiché depuis assets/data/passives/'` (lignes 49-55) et ajouter les deux suivants, pour obtenir cette fin de fichier :

```dart
  testWidgets('chaque carte montre son passif par defaut, repliee', (tester) async {
    final engine = await _pump(tester);

    // Repliee, la carte montre quand meme le passif avec lequel la run
    // partirait : le joueur compare les trois classes sans rien ouvrir
    // (meme regle que l'ecran de selection, `class_passive_list.dart:56`).
    for (final hero in engine.fixtures.heroes) {
      expect(
        find.text(engine.fixtures.passivesFor(hero).first.getName('fr')),
        findsOneWidget,
        reason: hero.id,
      );
    }

    // Et seulement celui-la : les autres n'apparaissent qu'une fois la
    // classe choisie.
    for (final hero in engine.fixtures.heroes) {
      for (final passif in engine.fixtures.passivesFor(hero).skip(1)) {
        expect(find.text(passif.getName('fr')), findsNothing, reason: passif.id);
      }
    }
  });

  testWidgets('choisir une classe deplie ses passifs', (tester) async {
    final engine = await _pump(tester);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
    for (final passif in engine.fixtures.passivesFor(mage)) {
      expect(find.text(passif.getName('fr')), findsOneWidget, reason: passif.id);
    }
  });

  testWidgets('toucher un passif deplie le retient', (tester) async {
    final engine = await _pump(tester);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    final mage = engine.fixtures.heroes.firstWhere((h) => h.id == 'mage');
    final autre = engine.fixtures.passivesFor(mage).last;
    expect(autre.id, isNot(engine.mockState.activePassive?.id));

    await tester.tap(find.text(autre.getName('fr')));
    await tester.pumpAndSettle();

    expect(engine.mockState.activePassive?.id, autre.id);
  });

  testWidgets('choisir une classe l\'écrit dans la tranche persistante', (tester) async {
    final engine = await _pump(tester);
    expect(engine.mockState.chosenHero, isNull);

    await tester.tap(find.text('Le Mage'));
    await tester.pumpAndSettle();

    expect(engine.mockState.chosenHero?.id, 'mage');
    expect(engine.mockState.activePassive?.id, 'channeling');
    expect(engine.mockState.heroStats.maxPv, 60);
  });
}
```

Le test `'les trois classes s\'affichent avec leurs PV réels'` (lignes 37-47) est **conservé tel quel**.

- [ ] **Step 2: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/tutorial/tutorial_fixtures_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_class_step_test.dart`
Expected: **ÉCHEC** de compilation — `The method 'passivesFor' isn't defined for the type 'TutorialFixtures'` et `The method 'choosePassive' isn't defined for the type 'TutorialEngine'`.

- [ ] **Step 3: Les fixtures rendent la liste**

Dans `lib/tutorial/tutorial_fixtures.dart`, **remplacer** `passiveFor` (lignes 54-58) par :

```dart
  /// Les passifs que la classe peut prendre au tutoriel : ceux que rend le
  /// point d'accès unique de P-49, dans son ordre, **sans troncature**
  /// (spec P-41, §8.3). Le premier est le choix par défaut, comme à l'écran
  /// de sélection ; le joueur garde la main pour en retenir un autre
  /// (spec §9.1).
  List<PassiveData> passivesFor(HeroData hero) =>
      availablePassivesFor(hero, registry);
```

- [ ] **Step 4: Le moteur retient un passif**

Dans `lib/tutorial/tutorial_engine.dart`, **remplacer** la ligne 132 de `chooseHero` :

```dart
    mockState.activePassive = fixtures.passiveFor(hero);
```

par :

```dart
    // Le premier du point d'accès, comme à l'écran de sélection : un choix
    // par défaut, pas une fatalité — `choosePassive` le remplace. La liste
    // est vide si aucun passif ne vise la classe, ce qu'aucune des trois
    // classes livrées ne présente.
    final passives = fixtures.passivesFor(hero);
    mockState.activePassive = passives.isEmpty ? null : passives.first;
```

Puis ajouter cette méthode **juste après** `chooseHero` (après sa ligne `}` de fermeture, aujourd'hui ligne 142) :

```dart
  /// Retient [passive] parmi ceux que la classe choisie ouvre.
  ///
  /// Le deck n'est pas remis à zéro, contrairement à `chooseHero` : changer
  /// de passif ne change pas les cartes de classe, et l'étape 03 reste
  /// franchie.
  void choosePassive(PassiveData passive) {
    mockState.activePassive = passive;
    notifyListeners();
  }
```

- [ ] **Step 5: La carte de classe porte le bloc des passifs**

Remplacer entièrement `lib/tutorial/widgets/tutorial_class_choice_widget.dart` par :

```dart
import 'package:flutter/material.dart';

import '../../models/data/hero_data.dart';
import '../../ui/widgets/class_identity.dart';
import '../../ui/widgets/class_passive_list.dart';
import '../tutorial_engine.dart';

/// Étape 02 — choix de classe, **et de son passif**.
///
/// Les trois héros, leurs points de vie et les passifs qu'ils ouvrent
/// viennent de `assets/data/classes/<id>/class.json` et
/// `assets/data/passives/`, par le point d'accès unique de P-49 : aucune
/// valeur n'est écrite ici, et aucun identifiant de classe n'est comparé
/// (ADR-090).
///
/// Le bloc des passifs est **celui de l'écran de sélection**
/// (`ClassPassiveList`), et non une seconde implémentation : c'est le remède
/// que demande le §1.4 de la spec. Repliée, chaque carte montre le passif
/// avec lequel la run partirait ; la carte choisie est dépliée et ses tuiles
/// sont cliquables.
class TutorialClassChoiceWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialClassChoiceWidget({super.key, required this.engine});

  @override
  State<TutorialClassChoiceWidget> createState() =>
      _TutorialClassChoiceWidgetState();
}

class _TutorialClassChoiceWidgetState extends State<TutorialClassChoiceWidget> {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final heroes = widget.engine.fixtures.heroes;
    final chosenId = widget.engine.mockState.chosenHero?.id;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            isFrench
                ? 'Choisissez votre classe, puis son passif'
                : 'Choose your class, then its passive',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 12,
                runSpacing: 12,
                children: heroes
                    .map((hero) => _buildHeroCard(hero, locale, chosenId == hero.id))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(HeroData hero, String locale, bool isSelected) {
    final passives = widget.engine.fixtures.passivesFor(hero);
    final activeId = widget.engine.mockState.activePassive?.id;
    // Le rang du passif retenu dans *cette* liste. Une carte non choisie
    // montre donc toujours son propre premier passif, jamais celui d'une
    // autre classe : `indexWhere` rend -1, ramené à 0.
    final rank = isSelected ? passives.indexWhere((p) => p.id == activeId) : -1;
    final selectedIndex = rank < 0 ? 0 : rank;

    return InkWell(
      onTap: () {
        widget.engine.chooseHero(hero);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hero.getName(locale),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${hero.maxHp} ${locale == 'fr' ? 'PV' : 'HP'}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              '${hero.maxMana} Mana',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
            const Divider(color: Colors.white12, height: 18),
            if (passives.isNotEmpty)
              ClassPassiveList(
                passives: passives,
                selectedIndex: selectedIndex,
                classMastery: hero.mastery,
                // Seule la classe choisie est dépliée : une seule carte à la
                // fois, comme à l'écran de sélection.
                isExpanded: isSelected,
                // La carte du tutoriel fait 190 px : c'est la mise en page
                // compacte qu'il lui faut, quelle que soit la taille de
                // l'écran.
                isMobile: true,
                locale: locale,
                classColor: ClassIdentity.colorOf(hero),
                onSelect: (i) {
                  widget.engine.choosePassive(passives[i]);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: La prose de l'étape 02 dit ce que l'étape fait**

Dans `lib/tutorial/tutorial_data.dart`, **remplacer** les corps de l'étape `TutorialStepType.classChoice` (lignes 16-24) par :

```dart
    bodyEn:
        'Every run starts here. The three classes differ by their health pool, '
        'by what their Might strengthens, and — above all — by the passive you '
        'pick for them: each class offers several, and the passive decides how '
        'you earn Armor.\n\n'
        'Choose a class, then tap a passive to keep it. The rest of this '
        'tutorial will use both.',
    bodyFr:
        'Toute partie commence ici. Les trois classes se distinguent par leurs '
        'points de vie, par ce que renforce leur Puissance, et surtout par le '
        'passif que vous leur choisissez : chaque classe en propose plusieurs, '
        'et c\'est lui qui décide de la façon dont vous gagnez de l\'Armure.\n\n'
        'Choisissez une classe, puis touchez un passif pour le retenir. La '
        'suite de ce tutoriel s\'appuiera sur les deux.',
```

- [ ] **Step 7: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/tutorial/tutorial_fixtures_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_class_step_test.dart`
Expected: **tout vert**.

- [ ] **Step 8: Vérifier à l'œil que la carte ne déborde pas**

Run: `flutter run -d windows` (ou la plateforme disponible), aller au tutoriel depuis l'accueil, atteindre l'étape 02, choisir chaque classe tour à tour.
Expected: les trois cartes tiennent dans le panneau d'illustration ; la carte choisie s'allonge de deux tuiles et le `SingleChildScrollView` défile sans bande jaune de débordement. **Un débordement est un défaut de cette tâche** (conséquence assumée n° 3), à corriger ici — par exemple en réduisant l'espacement du `Wrap` — et non à reporter.

- [ ] **Step 9: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1148: All tests passed!`

- [ ] **Step 10: Commit**

```bash
git add lib/tutorial/tutorial_fixtures.dart lib/tutorial/tutorial_engine.dart lib/tutorial/widgets/tutorial_class_choice_widget.dart lib/tutorial/tutorial_data.dart test/tutorial/tutorial_fixtures_test.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_class_step_test.dart
git commit -m "feat(tutoriel): l etape de classe laisse choisir le passif

`passiveFor` rendait le premier passif et jetait les autres. Le tutoriel rend
desormais toute la liste du point d acces unique de P-49, et reutilise le bloc
ClassPassiveList de l ecran de selection plutot que d en ecrire un second.

Spec P-41, §9.1.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: L'étape « Armure » applique la règle de la classe choisie

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/models/data/model_extensions.dart`, `lib/tutorial/tutorial_engine.dart`, `lib/tutorial/widgets/tutorial_armor_widget.dart`, `lib/tutorial/tutorial_data.dart`
- Test: `test/tutorial/tutorial_engine_test.dart`, `test/widget/tutorial_armor_step_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `StatGains.apply` / `StatGain` / `GainResource` / `GainSource` (`lib/game/systems/stat_gains.dart`), `StatRuleLabel.describe` (`lib/models/data/model_extensions.dart`), `EntityStats.effectiveMight` / `.addStatus` / `.takeDamage`, `HeroData.statRules`.
- Produces:
  - `String StatRuleLabel.shortTitle(AppLocalizations l10n)` — le titre court d'un panneau de démonstration.
  - `void TutorialEngine.gainArmorForDemo(int amount)` — **remplace** `void setHeroArmor(int value)`, qui disparaît.
  - `TutorialEngine.resetHeroStatsForDemo` remet aussi `statuses` à vide.

- [ ] **Step 1: Écrire les tests de moteur qui échouent**

Dans `test/tutorial/tutorial_engine_test.dart` :

**a)** Remplacer les quatre appels à `setHeroArmor` par `gainArmorForDemo`, sans toucher aux assertions — ligne 108 (`engine.setHeroArmor(4)`), ligne 393, ligne 486 (`engine.setHeroArmor(7)`) et ligne 502. Sans classe choisie, `statRules` est vide et le comportement est identique.

**b)** Ajouter ce groupe **après** le groupe `'Le choix du passif'` de la tâche 2 :

```dart
  group('Le gain de demonstration passe par les regles de la classe', () {
    test('sans classe choisie, le gain reste de l armure', () {
      engine.gainArmorForDemo(4);
      expect(engine.mockState.heroStats.armure, 4);
      expect(engine.mockState.heroStats.statuses, isEmpty);
    });

    test('une classe qui convertit convertit aussi le gain de demonstration', () {
      final berserker =
          engine.fixtures.heroes.firstWhere((h) => h.id == 'berserker');
      engine.chooseHero(berserker);

      engine.gainArmorForDemo(4);

      // Le meme verdict que `playCard` : c'est le meme appel a StatGains.
      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.effectiveMight, 4);
    });

    test('resetHeroStatsForDemo efface les statuts', () {
      // Regression : `addStatus` empile (`entity_stats.dart:134`). Sans ce
      // nettoyage, presser deux fois « Voir la difference » afficherait +4
      // puis +8 Puissance a un Berserker.
      final berserker =
          engine.fixtures.heroes.firstWhere((h) => h.id == 'berserker');
      engine.chooseHero(berserker);
      engine.gainArmorForDemo(4);
      expect(engine.mockState.heroStats.statuses, isNotEmpty);

      engine.resetHeroStatsForDemo(engine.mockState.heroStats.maxPv);

      expect(engine.mockState.heroStats.statuses, isEmpty);
      expect(engine.mockState.heroStats.armure, 0);
      expect(engine.mockState.heroStats.effectiveMight, 0);
    });
  });
```

- [ ] **Step 2: Écrire le test d'écran qui échoue**

Create `test/widget/tutorial_armor_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_armor_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// L'etape « Armure & Degats » n'enseigne jamais une regle que la classe
/// choisie ne suit pas (spec P-41, §9.1).
Future<TutorialEngine> _pump(WidgetTester tester, String heroId) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.firstWhere((h) => h.id == heroId));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialArmorWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

/// Presse « Voir la différence » et laisse passer les deux temps de la
/// démonstration : le gain (200 ms) puis le coup (900 ms).
Future<void> _simuler(WidgetTester tester) async {
  await tester.tap(find.textContaining('Voir la différence'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('une classe sans regle garde son Armure et l absorbe', (tester) async {
    final engine = await _pump(tester, 'paladin');
    expect(engine.mockState.chosenHero!.statRules, isEmpty);

    await _simuler(tester);

    // 100 PV, 4 Armure, 10 degats : l'armure encaisse 4, les PV 6.
    expect(find.text('94/100'), findsOneWidget);
    // Et le panneau sans armure perd les 10.
    expect(find.text('90/100'), findsOneWidget);
    // Aucun encadre de regle : la classe n'en declare aucune.
    expect(find.text('Le Paladin'), findsNothing);
  });

  testWidgets('une classe qui convertit ne garde aucune Armure', (tester) async {
    final engine = await _pump(tester, 'berserker');
    expect(engine.mockState.chosenHero!.statRules, isNotEmpty);

    await _simuler(tester);

    // 80 PV, 0 Armure conservee : les deux panneaux perdent les 10 degats.
    expect(find.text('70/80'), findsNWidgets(2));
    // La Puissance temporaire produite est montree, avec sa valeur.
    expect(find.text('4'), findsWidgets);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
  });

  testWidgets('la regle de la classe est ecrite sous les panneaux', (tester) async {
    await _pump(tester, 'berserker');

    // Generee par `StatRuleLabel.describe`, jamais ecrite classe par classe
    // (ADR-090). Le nom de la classe la coiffe, ce qui rend juste la
    // troisieme personne de la phrase.
    expect(find.text('Le Berserker'), findsOneWidget);
    expect(
      find.text('Son Armure devient de la Puissance pour un tour.'),
      findsOneWidget,
    );
  });

  testWidgets('presser deux fois n empile pas la Puissance', (tester) async {
    final engine = await _pump(tester, 'berserker');

    await _simuler(tester);
    await _simuler(tester);

    // +4, jamais +8 : `resetHeroStatsForDemo` efface les statuts entre deux
    // passages, sans quoi `addStatus` les empilerait.
    expect(engine.mockState.heroStats.effectiveMight, 4);
  });
}
```

- [ ] **Step 3: Lancer les tests pour vérifier qu'ils échouent**

Run: `flutter test test/tutorial/tutorial_engine_test.dart test/widget/tutorial_armor_step_test.dart`
Expected: **ÉCHEC** de compilation — `The method 'gainArmorForDemo' isn't defined for the type 'TutorialEngine'`.

- [ ] **Step 4: Les deux titres courts en ARB**

Dans `lib/l10n/app_en.arb`, ajouter **juste après** le bloc `statRuleConvertManaToMight` et ses métadonnées :

```json
  "statRuleArmorToMightTitle": "ARMOR → MIGHT",
  "@statRuleArmorToMightTitle": {
    "description": "Short title of the tutorial demo panel for a class that converts its Armor into temporary Might. Upper case, like the panel titles beside it."
  },
  "statRuleManaToMightTitle": "MANA → MIGHT",
  "@statRuleManaToMightTitle": {
    "description": "Short title of the tutorial demo panel for a class that converts its Mana into temporary Might."
  },
```

Dans `lib/l10n/app_fr.arb`, aux mêmes emplacements (sans bloc `@`, le gabarit est `app_en.arb`) :

```json
  "statRuleArmorToMightTitle": "ARMURE → PUISSANCE",
  "statRuleManaToMightTitle": "MANA → PUISSANCE",
```

Run: `flutter gen-l10n`
Expected: pas d'erreur. `lib/l10n/app_localizations*.dart` sont régénérés.

- [ ] **Step 5: Le titre court, généré depuis la règle**

Dans `lib/models/data/model_extensions.dart`, ajouter cette méthode à l'extension `StatRuleLabel`, **après** `describe` (qui se termine ligne 166) :

```dart
  /// Le titre court du panneau de démonstration du tutoriel : ce que la
  /// ressource devient, en majuscules comme les titres voisins.
  ///
  /// Même `switch` **exhaustif** sur le triplet (ressource, mode, cible) que
  /// [describe] : ajouter une valeur à l'une des trois énumérations sans son
  /// libellé ne compile plus.
  String shortTitle(AppLocalizations l10n) => switch ((stat, mode, to)) {
        (RuleStat.armor, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleArmorToMightTitle,
        (RuleStat.mana, RuleMode.convert, RuleTarget.statusMight) =>
          l10n.statRuleManaToMightTitle,
      };
```

- [ ] **Step 6: Le moteur n'écrit plus d'armure sans passer par les règles**

Dans `lib/tutorial/tutorial_engine.dart` :

**a)** **Remplacer** `setHeroArmor` (lignes 295-299) par :

```dart
  /// Accorde [amount] points d'Armure de démonstration, **sous les règles de
  /// la classe choisie** — le même appel que `playCard` (ADR-081, spec P-41
  /// §9.1). Une classe qui convertit son Armure la convertit donc aussi dans
  /// une démonstration.
  ///
  /// Il n'existe volontairement **aucun** point d'entrée qui écrive `armure:`
  /// sans passer par ici : c'est par là que l'étape « Armure » en était venue
  /// à montrer 4 Armure à un Berserker qui n'en garde jamais.
  void gainArmorForDemo(int amount) {
    mockState.heroStats = StatGains.apply(
      mockState.heroStats,
      StatGain(GainResource.armor, amount, GainSource.card),
      mockState.chosenHero?.statRules ?? const [],
    );
    // Sur le gain **annoncé**, et non sur l'armure conservée : même règle
    // qu'à `playCard`, faute de quoi une classe qui convertit resterait
    // bloquée à l'étape « Jouer des cartes ».
    if (amount > 0) _armorGainedThisStep = true;
    notifyListeners();
  }
```

**b)** Dans `resetHeroStatsForDemo` (lignes 327-334), ajouter `statuses` et compléter la documentation :

```dart
  /// Remet `heroStats` à un socle neutre pour une démonstration de dégâts :
  /// Armure à 0, statuts vidés, PV courants au plus petit de [desiredPv] et
  /// du `maxPv` réel du héros choisi.
  ///
  /// Contrairement à `gainArmorForDemo`/`applyDamageToHero`, qui ne peuvent
  /// qu'appauvrir l'état ou lui ajouter un gain, ce point d'entrée peut
  /// remonter les PV courants : nécessaire aux démonstrations qui rejouent un
  /// même scénario plusieurs fois sur le `heroStats` partagé du moteur. Le
  /// plafond réel du héros est toujours respecté — jamais de PV courants
  /// supérieurs au maximum, même si [desiredPv] le dépasse (ex. le Mage,
  /// `maxPv: 60`).
  ///
  /// Les **statuts** sont vidés pour la même raison : la conversion d'armure
  /// d'une classe en pose un (`might`), et `addStatus` empile
  /// (`entity_stats.dart:134`). Sans ce nettoyage, rejouer la démonstration
  /// afficherait +4 puis +8 Puissance.
  void resetHeroStatsForDemo(int desiredPv) {
    final stats = mockState.heroStats;
    mockState.heroStats = stats.copyWith(
      currentPv: desiredPv < stats.maxPv ? desiredPv : stats.maxPv,
      armure: 0,
      statuses: [],
    );
    notifyListeners();
  }
```

- [ ] **Step 7: La démonstration, en deux temps et sous les règles**

Dans `lib/tutorial/widgets/tutorial_armor_widget.dart` :

**a)** Ajouter en tête, après `import 'package:flutter/material.dart';` :

```dart
import 'package:roguelike_card_game/l10n/app_localizations.dart';

import '../../models/data/model_extensions.dart';
import '../tutorial_engine.dart';
```

(l'import existant de `../tutorial_engine.dart` est conservé, pas dupliqué.)

**b)** **Remplacer** le bloc de champs et de constantes (lignes 13-37, de `// Point d'Armure de départ` jusqu'à `double _rightDamageY = 0.0;`) par :

```dart
  // Le gain d'Armure de démonstration, et le coup qu'il encaisse : deux
  // paramètres du scénario pédagogique (« et si vous jouiez Défense ? »),
  // pas des valeurs de jeu. Ce que la classe en fait, en revanche, est une
  // vraie règle : `gainArmorForDemo` la lui demande.
  static const int _demoArmorGain = 4;
  static const int _demoDamage = 10;

  // `null` tant qu'aucune simulation n'a tourné : le panneau affiche alors
  // la pleine vie réelle (`_maxHp`). Un champ ne peut pas lire `_maxHp` à
  // l'initialisation (`widget` n'est pas encore attaché à cet instant) —
  // d'où le `null` plutôt qu'une constante comme 80.
  int? _leftHp;
  int _leftArmor = 0;
  int _leftHpLoss = 0;

  // Le panneau droit démarre à **0 Armure**, comme le gauche : ce qu'il aura
  // après le gain dépend de la classe, et l'écrire en dur ici était
  // exactement le défaut que ce lot corrige.
  int? _rightHp;
  int _rightArmor = 0;
  int _rightArmorLoss = 0;
  int _rightHpLoss = 0;

  /// La Puissance temporaire que le gain a produite chez une classe qui
  /// convertit son Armure ; 0 pour une classe qui la garde.
  int _rightMightGain = 0;

  bool _leftShowDamage = false;
  bool _rightShowGain = false;
  bool _rightShowDamage = false;
  double _leftDamageY = 0.0;
  double _rightGainY = 0.0;
  double _rightDamageY = 0.0;
```

**c)** **Remplacer** `_resetDemoBaseline` et `_runSimulation` (lignes 39 à 122, de `/// Remet \`heroStats\`` jusqu'à la fermeture de `_runSimulation`) par :

```dart
  /// Remet `heroStats` à un socle neutre avant un scénario de démonstration :
  /// PV pleins, Armure à 0, statuts vidés. Le moteur plafonne lui-même ce
  /// socle au `maxPv` réel du héros choisi et notifie ses observateurs.
  void _resetDemoBaseline() {
    widget.engine.resetHeroStatsForDemo(_maxHp);
  }

  /// La démonstration, en **deux temps** : le gain, puis le coup.
  ///
  /// Le gain a son propre temps parce que c'est lui que la classe modifie :
  /// un panneau qui afficherait d'un coup « 0 Armure, +4 Puissance, −10 PV »
  /// serait illisible. Il passe par `gainArmorForDemo`, donc par
  /// `StatGains.apply` et les `statRules` de la classe — jamais par une
  /// écriture directe (ADR-081, spec §9.1).
  void _runSimulation() {
    setState(() {
      _leftHp = null;
      _leftArmor = 0;
      _leftHpLoss = 0;
      _rightHp = null;
      _rightArmor = 0;
      _rightArmorLoss = 0;
      _rightHpLoss = 0;
      _rightMightGain = 0;
      _leftShowDamage = false;
      _rightShowGain = false;
      _rightShowDamage = false;
      _leftDamageY = 0.0;
      _rightGainY = 0.0;
      _rightDamageY = 0.0;
    });

    // Temps 1 — le gain, chez la classe choisie.
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      _resetDemoBaseline();
      final avant = widget.engine.mockState.heroStats;
      widget.engine.gainArmorForDemo(_demoArmorGain);
      final apres = widget.engine.mockState.heroStats;

      setState(() {
        _rightArmor = apres.armure;
        // La différence, et non `effectiveMight` seul : la Puissance
        // permanente d'un héros de tutoriel vaut 0, mais s'y fier serait
        // s'appuyer sur un zéro, pas sur une règle.
        _rightMightGain = apres.effectiveMight - avant.effectiveMight;
        _rightShowGain = true;
        _rightGainY = -30.0;
      });
    });

    // Temps 2 — le coup, sur les deux scénarios. La vraie formule
    // d'absorption (`EntityStats.takeDamage`) calcule le résultat : on ne le
    // recopie pas à la main.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;

      // Droite : l'état laissé par le temps 1 est encore celui du moteur.
      final avantDroite = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(_demoDamage);
      final apresDroite = widget.engine.mockState.heroStats;

      // Gauche : le même personnage, qui n'a rien joué.
      _resetDemoBaseline();
      final avantGauche = widget.engine.mockState.heroStats;
      widget.engine.applyDamageToHero(_demoDamage);
      final apresGauche = widget.engine.mockState.heroStats;

      setState(() {
        _leftHp = apresGauche.currentPv;
        _leftHpLoss = avantGauche.currentPv - apresGauche.currentPv;
        _leftArmor = apresGauche.armure;
        _leftShowDamage = true;
        _leftDamageY = -30.0;

        _rightHp = apresDroite.currentPv;
        _rightHpLoss = avantDroite.currentPv - apresDroite.currentPv;
        _rightArmorLoss = avantDroite.armure - apresDroite.armure;
        _rightArmor = apresDroite.armure;
        _rightShowGain = false;
        _rightShowDamage = true;
        _rightDamageY = -30.0;
      });
    });

    // Nettoyage des textes flottants, l'animation finie.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _leftShowDamage = false;
        _rightShowDamage = false;
      });
    });
  }
```

**d)** Dans `build`, ajouter après `final maxHp = _maxHp;` :

```dart
    final l10n = AppLocalizations.of(context)!;
    // Les règles de la classe choisie. Vide pour le Paladin et le Mage : le
    // panneau droit garde alors son titre et son badge d'Armure d'origine.
    final rules = widget.engine.mockState.chosenHero?.statRules ?? const [];
```

**e)** Remplacer le `Text` du titre du panneau droit (aujourd'hui `isFrench ? 'AVEC ARMURE' : 'WITH ARMOR'`) par :

```dart
                              Text(
                                // Généré depuis la règle quand la classe en
                                // déclare une : « ARMURE → PUISSANCE ».
                                // Jamais écrit classe par classe (ADR-090).
                                rules.isEmpty
                                    ? (isFrench ? 'AVEC ARMURE' : 'WITH ARMOR')
                                    : rules.first.shortTitle(l10n),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 1.0,
                                ),
                              ),
```

**f)** Remplacer le `Stack` du panneau droit (l'icône bouclier et son `AnimatedPositioned`) pour porter les **deux** textes flottants :

```dart
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(
                                    Icons.shield_rounded,
                                    size: 40,
                                    color: Colors.blueAccent,
                                  ),
                                  if (_rightShowGain)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _rightGainY,
                                      child: Text(
                                        // Ce que le gain est devenu, pas ce
                                        // que la carte annonçait.
                                        _rightMightGain > 0
                                            ? (isFrench
                                                ? '+$_rightMightGain Puissance'
                                                : '+$_rightMightGain Might')
                                            : (isFrench
                                                ? '+$_rightArmor Armure'
                                                : '+$_rightArmor Armor'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _rightMightGain > 0
                                              ? Colors.amber
                                              : Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  if (_rightShowDamage)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutQuad,
                                      top: _rightDamageY,
                                      child: Text(
                                        _rightArmorLoss > 0
                                            ? (isFrench
                                                ? '-$_rightArmorLoss Armure\n-$_rightHpLoss HP'
                                                : '-$_rightArmorLoss Armor\n-$_rightHpLoss HP')
                                            : '-$_rightHpLoss HP',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
```

**g)** Sous la barre de PV du panneau droit, remplacer `buildArmorBadge(_rightArmor)` par une rangée qui porte aussi le badge de Puissance :

```dart
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  buildArmorBadge(_rightArmor),
                                  if (_rightMightGain > 0) ...[
                                    const SizedBox(width: 4),
                                    buildMightBadge(_rightMightGain),
                                  ],
                                ],
                              ),
```

**h)** Ajouter la méthode `buildMightBadge`, **juste après** `buildArmorBadge` (qui termine le fichier) :

```dart
  /// Le badge de la Puissance temporaire produite par la conversion d'une
  /// classe. Même forme que [buildArmorBadge] : les deux se lisent côte à
  /// côte, et ce qui change entre eux est ce que la règle a produit.
  ///
  /// L'éclair est l'icône de la Puissance depuis le lot B
  /// (`card_text_renderer.dart:309`, `might_icon_test.dart`) : jamais une
  /// épée, jamais un 💪.
  Widget buildMightBadge(int value) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.black87, size: 12),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
```

**i)** Ajouter l'encadré de la règle, **juste après** le `Builder` du passif (celui qui se termine par `const SizedBox(height: 10),` avant le bouton de simulation) :

```dart
                // La règle de stat de la classe choisie, en clair. Générée
                // par `StatRuleLabel.describe` — la même phrase qu'à l'écran
                // de sélection de classe, jamais écrite ici (ADR-090). Le nom
                // de la classe la coiffe : la phrase est à la troisième
                // personne, et c'est sous ce titre qu'elle est juste.
                if (rules.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.engine.mockState.chosenHero!.getName(
                            Localizations.localeOf(context).languageCode,
                          ),
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final rule in rules)
                          Text(
                            rule.describe(l10n),
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
```

**j)** Retirer la constante `_rightStartArmor` de tout commentaire qui la nomme encore, et mettre à jour le commentaire de `_maxHp` s'il évoque `setHeroArmor` (lignes 46-51 d'origine). Vérifier par `git grep -n "setHeroArmor\|_rightStartArmor" -- lib` : **aucune sortie attendue**.

- [ ] **Step 8: La prose de l'étape dit ce que la démonstration montre**

Dans `lib/tutorial/tutorial_data.dart`, **remplacer** les corps de l'étape `TutorialStepType.armorDamage` (lignes 174-193) par :

```dart
    bodyEn:
        'Armor absorbs damage before your HP. Any damage left over after the '
        'Armor is gone hits your health.\n\n'
        '**Armor always resets to 0 at the start of your turn** — every class, '
        'no exception — and again at the end of a combat. It is a one-turn '
        'expense, never a stock you build up.\n\n'
        'Your class decides two things. *How you earn it*: that is your '
        'passive — Mastery, a permanent stat, strengthens what your passive '
        'produces, and each passive states what one point adds. And *what '
        'becomes of it*: most classes keep it for the turn, some turn it into '
        'something else at once.\n\n'
        'The demonstration below applies the rule of the class you picked.',
    bodyFr:
        'L\'Armure absorbe les dégâts avant vos PV. Ce qui dépasse une fois '
        'l\'Armure épuisée entame votre santé.\n\n'
        '**L\'Armure retombe toujours à 0 au début de votre tour** — toutes '
        'classes confondues, sans exception — et de nouveau à la fin d\'un '
        'combat. C\'est une dépense pour un tour, jamais un stock qu\'on '
        'accumule.\n\n'
        'Votre classe décide de deux choses. La *façon d\'en gagner* : c\'est '
        'votre passif — la Maîtrise, statistique permanente, renforce ce que '
        'produit votre passif, et chaque passif indique ce qu\'un point lui '
        'apporte. Et *ce qu\'elle devient* : la plupart des classes la gardent '
        'pour le tour, certaines la transforment aussitôt en autre chose.\n\n'
        'La démonstration ci-dessous applique la règle de la classe que vous '
        'avez choisie.',
```

- [ ] **Step 9: Lancer les tests pour vérifier qu'ils passent**

Run: `flutter test test/tutorial/tutorial_engine_test.dart test/widget/tutorial_armor_step_test.dart`
Expected: **tout vert**.

- [ ] **Step 10: Vérifier à l'œil les trois parcours**

Run: `flutter run -d windows`, aller au tutoriel, et pour **chacune des trois classes** atteindre l'étape « Armure & Dégâts » et presser « Voir la différence ».
Expected :
- **Paladin** et **Mage** : identiques à avant, à la découpe en deux temps près. Titre « AVEC ARMURE », badge d'Armure à 4 puis à 0, `94/100` et `54/60` respectivement. Aucun encadré cyan.
- **Berserker** : titre « ARMURE → PUISSANCE », badge d'Armure à 0 et badge éclair à 4, les deux panneaux à `70/80`, et l'encadré cyan « Le Berserker / Son Armure devient de la Puissance pour un tour. »
- Presser deux fois : le badge éclair affiche **4**, jamais 8.

- [ ] **Step 11: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1155: All tests passed!`

- [ ] **Step 12: Commit**

```bash
git add lib/l10n lib/models/data/model_extensions.dart lib/tutorial/tutorial_engine.dart lib/tutorial/widgets/tutorial_armor_widget.dart lib/tutorial/tutorial_data.dart test/tutorial/tutorial_engine_test.dart test/widget/tutorial_armor_step_test.dart
git commit -m "feat(tutoriel): l etape Armure applique la regle de la classe

Le panneau AVEC ARMURE ecrivait 4 Armure par setHeroArmor, en court-circuitant
StatGains.apply : il montrait donc un Berserker tenant une armure que sa classe
convertit systematiquement. Le gain passe desormais par les regles de la classe,
en deux temps, et la regle est ecrite sous les panneaux par StatRuleLabel.

setHeroArmor disparait : plus aucun point d entree n ecrit armure: sans regle.
resetHeroStatsForDemo vide aussi les statuts, sans quoi rejouer la demonstration
empilerait la Puissance.

Spec P-41, §9.1.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: L'étape « Jouer des cartes » annonce le gain réel

**Hors spec, dans le périmètre sur décision du propriétaire du 2026-09-20.** Le §9.1 ne nomme pas cette étape ; elle porte pourtant exactement le même défaut, deux étapes plus tôt. Corriger l'une en laissant l'autre n'aurait pas de sens.

**Files:**
- Modify: `lib/tutorial/widgets/tutorial_play_card_widget.dart`
- Test: `test/widget/tutorial_play_card_step_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `TutorialEngine.playCard`, `TutorialEngine.mockState.heroStats`, `EntityStats.armure` / `.effectiveMight`.
- Produces: rien de public. `_effectValue(card, 'armor')` n'a plus d'appelant et **disparaît** ; `_effectValue(card, 'damage')` reste, l'attaque n'étant convertie par aucune règle.

- [ ] **Step 1: Écrire le test qui échoue**

Create `test/widget/tutorial_play_card_step_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/tutorial/tutorial_engine.dart';
import 'package:roguelike_card_game/tutorial/tutorial_fixtures.dart';
import 'package:roguelike_card_game/tutorial/widgets/tutorial_play_card_widget.dart';

import '../tutorial/tutorial_test_registry.dart';

/// Le texte flottant d'un gain d'Armure annonce ce que la classe a
/// réellement obtenu, pas la valeur imprimée sur la carte (spec P-41, §9.1,
/// périmètre élargi le 2026-09-20).
Future<TutorialEngine> _pump(WidgetTester tester, String heroId) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final engine = TutorialEngine(data: await buildTutorialTestRegistry());
  engine.chooseHero(engine.fixtures.heroes.firstWhere((h) => h.id == heroId));
  engine.seedEnemy();
  engine.seedHand([TutorialFixtureIds.defend]);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', ''), Locale('fr', '')],
      locale: const Locale('fr', ''),
      home: Scaffold(body: TutorialPlayCardWidget(engine: engine)),
    ),
  );
  await tester.pumpAndSettle();
  return engine;
}

/// Sélectionne la carte de Défense, puis la joue sur la carte Héros.
///
/// La zone Héros est le bloc intitulé « HÉROS » au centre du plateau
/// (`tutorial_play_card_widget.dart`, `_buildHeroZone`) : son `GestureDetector`
/// enveloppe ce titre, donc taper le texte suffit.
Future<void> _jouerDefense(WidgetTester tester, TutorialEngine engine) async {
  final nom = engine.fixtures.card(TutorialFixtureIds.defend).getName('fr');
  await tester.tap(find.text(nom).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('HÉROS'));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('une classe qui garde son Armure l annonce en armure', (tester) async {
    final engine = await _pump(tester, 'paladin');
    final valeur = engine.fixtures
        .card(TutorialFixtureIds.defend)
        .effects
        .firstWhere((e) => e.type == 'armor')
        .value;

    await _jouerDefense(tester, engine);

    expect(find.text('+$valeur 🛡️'), findsOneWidget);
  });

  testWidgets('une classe qui convertit annonce la Puissance', (tester) async {
    final engine = await _pump(tester, 'berserker');
    final valeur = engine.fixtures
        .card(TutorialFixtureIds.defend)
        .effects
        .firstWhere((e) => e.type == 'armor')
        .value;

    await _jouerDefense(tester, engine);

    // Le badge d'Armure reste a 0 : annoncer « +5 bouclier » etait le
    // mensonge que cette tache corrige.
    expect(engine.mockState.heroStats.armure, 0);
    expect(find.text('+$valeur 🛡️'), findsNothing);
    expect(find.text('+$valeur ⚡'), findsOneWidget);
  });
}
```

> **Si `find.text('HÉROS')` désigne plusieurs widgets** — la carte Héros en porte un seul, mais une future ligne d'instruction pourrait le répéter : viser `.first`, ou ajouter une `Key` à la `GestureDetector` de `_buildHeroZone`. **Ajouter une `Key` est permis** ; changer la disposition ne l'est pas.

- [ ] **Step 2: Lancer le test pour vérifier qu'il échoue**

Run: `flutter test test/widget/tutorial_play_card_step_test.dart`
Expected: **ÉCHEC** — le second test trouve `+5 🛡️` là où il attend `+5 ⚡`.

- [ ] **Step 3: Le texte flottant lit le gain réel**

Dans `lib/tutorial/widgets/tutorial_play_card_widget.dart`, **remplacer** le bloc `if (_selectedCard!.data.type == CardType.skill)` de `_buildHeroZone` (lignes 339-348) par :

```dart
          if (_selectedCard!.data.type == CardType.skill) {
            // Le gain **réel**, mesuré de part et d'autre de `playCard` : une
            // classe qui convertit son Armure ne garde aucun point, et
            // annoncer la valeur imprimée sur la carte serait lui enseigner
            // une règle qu'elle ne suit pas (spec P-41, §9.1). C'est
            // `StatGains.apply` qui a décidé, pas ce widget.
            final avant = widget.engine.mockState.heroStats;
            final success = widget.engine.playCard(_selectedCard!);
            if (success) {
              final apres = widget.engine.mockState.heroStats;
              final armure = apres.armure - avant.armure;
              final puissance = apres.effectiveMight - avant.effectiveMight;

              if (puissance > 0) {
                _triggerFloatingText('+$puissance ⚡', Colors.amber);
              } else {
                _triggerFloatingText('+$armure 🛡️', Colors.blueAccent);
              }
              setState(() {
                _selectedCard = null;
              });
            }
          } else if (_selectedCard!.data.type == CardType.attack) {
```

**Supprimer** ensuite le paramètre devenu inutile de `_effectValue` : la fonction reste, mais son appel `'armor'` a disparu. Vérifier par `git grep -n "_effectValue(" -- lib` qu'il ne reste que l'appel `'damage'` (ligne 168 d'origine). Si c'est le cas, **simplifier `_effectValue`** en une fonction à un seul rôle :

```dart
/// Dégâts réels d'une carte, utilisés pour le texte flottant déclenché par le
/// chemin tap-puis-tap ; applique le multiplicateur de rareté, comme
/// `TutorialEngine.playCard`.
///
/// Il n'existe pas d'équivalent pour l'armure : ce qu'un gain d'armure
/// devient dépend de la classe, et seul le moteur le sait (spec P-41, §9.1).
int _damageValue(CardInstance card) {
  for (final effect in card.data.effects) {
    if (effect.type == 'damage') {
      return (effect.value * card.rarityMultiplier).round();
    }
  }
  return 0;
}
```

et remplacer l'appel `_effectValue(_selectedCard!, 'damage')` par `_damageValue(_selectedCard!)`.

- [ ] **Step 4: Lancer le test pour vérifier qu'il passe**

Run: `flutter test test/widget/tutorial_play_card_step_test.dart`
Expected: **PASS**, 2 tests.

- [ ] **Step 5: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1157: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/tutorial/widgets/tutorial_play_card_widget.dart test/widget/tutorial_play_card_step_test.dart
git commit -m "fix(tutoriel): le texte flottant annonce le gain reel, pas l imprime

Jouer Defense affichait +5 bouclier a un Berserker dont le badge d Armure
restait a 0. Le texte flottant mesure desormais le gain de part et d autre de
playCard : l armure conservee, ou la Puissance temporaire produite.

Hors spec §9.1, ajoute au perimetre sur decision du proprietaire du 2026-09-20.

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Vérification finale et pull request

**Files:**
- Aucun changement de code attendu. Si une vérification rougit, la corriger dans une tâche à part — pas ici.

**Interfaces:**
- Consumes: les tâches 1 à 4.
- Produces: la PR de la partie 1 du lot D.

- [ ] **Step 1: La suite complète**

Run: `dart analyze` — Expected: `No issues found!`
Run: `flutter test` — Expected: `+1157: All tests passed!`

- [ ] **Step 2: Le tutoriel ne recopie toujours aucune règle**

Run: `flutter test test/tutorial/tutorial_isolation_test.dart`
Expected: **PASS**. Ce lot a ajouté deux imports de `lib/ui/widgets/` dans `lib/tutorial/` ; ni `ClassPassiveList` ni `ClassIdentity` ne touche Riverpod, donc le garde-fou reste vert. S'il rougit, c'est qu'un provider a été importé : **le retirer**, pas assouplir le test.

Run: `git grep -n "id == 'berserker'\|id == 'mage'\|id == 'paladin'\|id == \"berserker\"" -- lib`
Expected: **aucune sortie** — ADR-090.

Run: `git grep -n "statRules\|mightTargets\|critChance" -- lib/tutorial`
Expected: uniquement des **lectures** de la classe choisie (`mockState.chosenHero?.statRules`, la copie dans `baseStatsForHero`, le commentaire de l'exception `critChance`). **Aucune valeur en dur**, aucune table de règles recopiée.

- [ ] **Step 3: Plus aucune écriture d'armure hors des règles**

Run: `git grep -n "setHeroArmor\|armure: 4\|armure: 5" -- lib/tutorial`
Expected: **aucune sortie**. `armure: 0` dans `resetHeroStatsForDemo` et dans `endTurn` est légitime — une remise à zéro n'est pas un gain.

- [ ] **Step 4: Les trois parcours, à l'œil, de bout en bout**

Run: `flutter run -d windows`, et parcourir le tutoriel **en entier** une fois par classe, en français puis en anglais pour le Berserker.
Expected: aucune étape bloquée, aucun débordement, aucun `{placeholder}` visible, et à l'étape « Armure » le comportement décrit à la tâche 3, step 10.

- [ ] **Step 5: Le pubspec ne dérive pas**

Run: `dart run tool/sync_assets.dart --check`
Expected: code de retour 0. (Ce lot n'ajoute aucun fichier d'`assets/`, donc aucune dérive n'est attendue ; la vérification coûte une seconde.)

- [ ] **Step 6: Rien de généré n'est en attente**

Run: `git status --short`
Expected: aucune sortie. Si `macos/Flutter/GeneratedPluginRegistrant.swift`, `linux/flutter/` ou `windows/flutter/` apparaissent : `git checkout --` dessus, ne jamais les commiter. Les trois `lib/l10n/app_localizations*.dart` doivent en revanche être **commités** (tâche 3).

- [ ] **Step 7: Ouvrir la pull request**

```bash
git push -u origin feat/p41-lot-d-tutoriel
```

Titre : `P-41 lot D, partie 1 — Le tutoriel enseigne la classe qu on a choisie`

Corps :

```
Implemente le §9.1 de la spec S2.

- L etape de choix de classe propose les passifs que la classe ouvre, lus par
  le point d acces unique de P-49, et reutilise le bloc ClassPassiveList de
  l ecran de selection plutot que d en ecrire un second. `passiveFor` rendait
  le premier et jetait les autres.
- L etape « Armure & Degats » fait passer son gain de demonstration par
  StatGains.apply et les statRules de la classe. Elle ecrivait 4 Armure en
  dur : elle montrait donc un Berserker tenant une armure que sa classe
  convertit systematiquement en Puissance temporaire. Le titre du panneau et
  la phrase de la regle sont generes depuis la donnee ; aucun ecran ne compare
  un identifiant de classe (ADR-090).
- L etape « Jouer des cartes » annonce le gain reel au lieu de la valeur
  imprimee sur la carte — hors spec, ajoute au perimetre le 2026-09-20 :
  corriger un mensonge et en laisser un autre deux etapes plus tot n aurait
  pas de sens.
- Cinq tests verrouillent ce que le lot B avait livre sans le tenir : critChance
  force a 0 (l exception explicite ET testee qu exige le §9.1), la copie de
  l identite de classe, et la conversion d armure appliquee par playCard.

Deux des trois classes livrees ne changent pas du tout : le Paladin et le Mage
n ont pas de statRules. Le parcours Berserker est le seul modifie, et c est
exactement celui que le lot B avait rendu faux.

Prise de note : la premisse du §9.1 sur le franchissement de l etape avait
vieilli. L etape « Armure » n a aucune condition de franchissement, et le
drapeau armorGainedThisStep — qui garde une autre etape — se lit sur la valeur
imprimee de la carte, avant conversion. Rien n etait bloque ; c est la fidelite
pedagogique qui l etait.

`dart analyze` propre, `flutter test` vert (1157 tests, contre 1135 au depart).

Reste au lot D : la console de debug (spec §9.2), independante de cette partie.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 8: Après la fusion**

Une fois la PR fusionnée, lancer le skill `patch-notes-writer` (la note `0.5.2` est rouverte en place, cf. `docs/ROADMAP.md`) puis, **une fois les deux parties du lot D fusionnées**, le skill `memory-bank-sync`. Les deux sont agent-gérés : ne pas éditer `assets/data/patch_notes.json`, `pubspec.yaml` (`version:`) ni `.obsidian_vault/_memory_bank/` à la main.

---

## Suites connues, laissées ouvertes

| Sujet | Où il vit |
|:---|:---|
| La console de debug : validation de `statRules`, passif garanti à la création guidée de classe, récompenses de niveau éditables, identité de la run au menu de debug | Lot D, partie 2, spec §9.2 — [plan](2026-09-20-p41-lot-d-partie-2-console-de-debug.md) |
| **Le tutoriel n'applique toujours pas le passif choisi.** `TraitSystem.dispatch` n'est appelé depuis aucun fichier de `lib/tutorial/` : choisir *Rage* plutôt que *Frénésie* ne change aucun chiffre du tutoriel. Ce qui manque n'est pas un point d'accès — `mockState.activePassive` est déjà là et le tirage des récompenses le lit — mais une boucle de tour dans le tutoriel : les passifs se déclenchent sur `startOfTurn` / `endOfTurn`, et le tutoriel n'a qu'un `endTurn()` de démonstration à une étape. C'est un chantier de fidélité à part entière, pas un oubli de ce lot | Non planifié. Relève du §1.4 de la spec (« Le tutoriel est une seconde implémentation du jeu ») ; à porter dans `docs/ROADMAP.md` au moment de la synchronisation de mémoire |
| **Le parcours Berserker ne voit jamais l'absorption d'armure sur lui-même.** Conséquence assumée n° 1. Une réponse possible : faire porter la démonstration de l'absorption sur l'**ennemi**, qui gagne de l'armure par son intention « Défense » et dont aucune classe ne convertit les gains. C'est un changement de sujet de l'étape, pas un correctif | Idée, non tranchée. À verser à `docs/possible_upgrades/` si le propriétaire la retient |
| Le déblocage des passifs par personnage, derrière le point d'accès de P-49 — le tutoriel en héritera sans rien changer, `passivesFor` ne filtrant rien lui-même | P-13, spec §10 |
