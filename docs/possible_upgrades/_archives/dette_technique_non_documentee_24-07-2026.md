# Hero's Draft — Dette Technique Non Documentée (Audit du 24-07-2026)

Ce document recense de la dette technique détectée par audit de la codebase mais **absente** des rapports de dette technique existants (`docs/analysis_reports/technical_debt_report_Opus4.6.md`, `docs/analysis_reports/dette_technique_rapport_Gemini3.5*.md`) et de la roadmap de refactoring suivie dans `.obsidian_vault/_memory_bank/progress.md` (section 4).

Contexte : cet audit fait suite à la décomposition des deux dernières "god classes" de la Phase 2 (voir ci-dessous), effectuée le même jour. Il ne re-liste donc pas ces deux fichiers.

---

## ✅ Pour mémoire : Décomposition `map_screen.dart` / `game_screen.dart` (résolu le 24-07-2026)

Ces deux fichiers étaient les deux derniers éléments critiques de la Phase 2 (`progress.md`). Les chiffres de 2471 / 1667 lignes documentés dans `progress.md` étaient déjà obsolètes avant cet audit (un refactoring partiel avait eu lieu sans mise à jour de la doc) : la taille réelle constatée était de 814 / 949 lignes.

| Fichier | Avant | Après | Extractions |
| :--- | :---: | :---: | :--- |
| [map_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/map_screen.dart) | 814 | 419 | `level_up_overlay.dart`, `map_toolbar.dart`, `map_tooltip_overlay.dart`, `map_path_highlighter.dart` (service) |
| [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) | 949 | 555 | `death_overlay.dart`, `combat_top_bar.dart`, `combat_bottom_hud.dart`, `turn_control_panel.dart`, `combat_side_panels.dart`, `combat_phase_banner.dart`, `combat_tooltip_overlay.dart` |

`dart analyze` : 0 erreur. `flutter test` : 149/149 au vert après refactoring.

---

## 📊 Matrice des Constats

| # | Constat | Sévérité | Fichier(s) |
| :--- | :--- | :---: | :--- |
| 1 | Logique de récompense dupliquée et couplée par chaîne de caractères dans `draft_screen.dart` | **Élevée** | [draft_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart) |
| 2 | `RewardController` sans aucun test unitaire | **Élevée** | [reward_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/reward_controller.dart) |
| 3 | 7 blocs `catch` silencieux sans logging | **Moyenne** | 7 fichiers (voir détail) |
| 4 | Cast non sécurisé sur un retour de navigation | **Moyenne** | [rest_screen.dart:56](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/rest_screen.dart) |
| 5 | 8 écrans majeurs sans test dédié | **Moyenne** | Voir liste détaillée |
| 6 | Incohérence de dialogue (`AlertDialog` brut vs `GameDialog`) | **Faible** | [home_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/home_screen.dart) |

---

## 🔍 Détail des Constats

### 1. Logique de récompense dupliquée et couplée par chaîne de caractères — `draft_screen.dart`

> **Correction par rapport à un audit préliminaire** : une première passe avait conclu à tort que ceci provoquait un bug d'i18n visible en jeu ("texte français affiché aux joueurs anglophones"). Après relecture complète de `_getChoiceTitle`/`_getChoiceDescription` (lignes 121-162), ce n'est **pas** le cas : l'affichage final passe bien par `l10n.draftChoice*`, donc le texte est correctement traduit à l'écran. Le vrai problème est architectural, pas un bug utilisateur visible.

**Constat** :
- [`_rollRarity()`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart) (ligne 685) et [`_generateChoices()`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart) (ligne 735) réimplémentent, **dans la State d'un widget UI**, tout un système de tirage pondéré par la `luck` (mythique/légendaire/épique/rare/peu commun), quasiment identique à celui déjà présent dans `RewardController` pour les butins post-combat. Il existe donc deux implémentations indépendantes de la même mécanique de rareté, avec un risque de divergence silencieuse si l'une est rééquilibrée sans l'autre.
- Les choix de récompense (`Vitalité`, `Aiguisage`, `Forge d'Acier`, `Sagesse`, `Trèfle à 4 feuilles`, `Miroir`, `Précision`, `Férocité`) sont générés avec un `title` **littéral en français codé en dur** (lignes 764, 776, 792, 835, 865, 879, 894), qui sert ensuite de **clé de dispatch** dans `_getChoiceTitle`/`_getChoiceDescription` (lignes 123-160) : `if (choice.title == 'Vitalité') return l10n.draftChoiceVitality;`. Le français fait donc office de pseudo-identifiant technique.
- Fragilité concrète : si une seule de ces chaînes littérales est un jour retouchée (faute de frappe, harmonisation), le fallback (`return choice.title;` / `return choice.description;`, lignes 131 et 161) affiche silencieusement le texte français brut non traduit à **tous** les joueurs, y compris anglophones — sans erreur `dart analyze`, sans test qui casse (aucun test ne couvre ce fichier).
- Viole la règle d'architecture de `CLAUDE.md` : "toute logique métier/état partagé vit dans les controllers Riverpod, jamais dans les widgets UI".

**Suggestion** : donner à chaque choix un `id` technique stable (anglais, type enum), déplacer `_rollRarity`/`_generateChoices` vers un controller ou service partagé (potentiellement en unifiant avec la logique de rareté de `RewardController`), et faire du dispatch `l10n` un simple `switch` sur cet `id` plutôt que sur le texte affiché.

### 2. `RewardController` sans aucun test unitaire

**Constat** : `lib/game/controllers/reward_controller.dart` implémente la résolution complète des récompenses post-combat (or, XP avec triplement boss, tirage de relique pondéré par rareté et scaling par Acte, cartes bonus/clonage) — une logique combat-critique et non triviale — sans qu'aucun fichier sous `test/` ne le couvre. À titre de comparaison, `combat_controller`, `deck_controller`, `shop_controller`, `event_controller` et `skill_controller` ont tous des tests dédiés.

**Suggestion** : créer `test/unit/reward_controller_test.dart` couvrant au minimum : calcul de gold/XP, triplement Acte boss central, scaling de rareté de relique par Acte, exclusion des cartes `unique` du pool de cartes bonus.

### 3. Blocs `catch` silencieux sans logging (7 occurrences)

Chacun de ces blocs avale une exception sans la journaliser, rendant un bug de production irreproductible à partir d'un simple rapport utilisateur :

| Fichier | Ligne | Contexte |
| :--- | :---: | :--- |
| [run_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart) | 43 | `catch (_) { return null; }` |
| [card_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/card_data.dart) | 151 | `catch (_) { return null; }` — entrée JSON malformée retirée silencieusement |
| [forge_upgrade_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/forge_upgrade_data.dart) | 90 | idem |
| [passive_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/passive_data.dart) | 58 | idem |
| [relic_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/relic_data.dart) | 77 | idem |
| [save_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/save_service.dart) | 68, 94 | Sauvegarde traitée comme totalement corrompue (ADR-069, comportement voulu) mais sans logger la cause exacte |
| [map_connection_painter.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/map/map_connection_painter.dart) | 79 | Commentaire "Ignorer si la cible n'existe pas" mais sans log |

Deux cas supplémentaires existent dans les fichiers déjà refactorés aujourd'hui (`map_screen.dart:380`, `game_screen.dart:438`) mais sont volontaires et documentés en commentaire (fallback de synchronisation d'état après changement d'Acte) — non listés comme dette ici.

**Suggestion** : à minima, ajouter un `debugPrint`/log conditionnel (`kDebugMode`) dans les 4 modèles de données (`card_data.dart`, `forge_upgrade_data.dart`, `passive_data.dart`, `relic_data.dart`) et dans `save_service.dart`, pour qu'un contenu JSON invalide ou une sauvegarde corrompue laisse une trace diagnostique.

### 4. Cast non sécurisé sur un retour de navigation — `rest_screen.dart`

**Constat** : [rest_screen.dart:56](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/rest_screen.dart) fait `final card = result['card'] as CardInstance;` sur le résultat `Map<String, dynamic>?` renvoyé par `RestCardSelectionScreen`. Le `null`-check sur `result` existe (ligne 55), mais rien ne garantit que la clé `'card'` soit bien présente et du bon type — un futur changement du contrat de retour de `RestCardSelectionScreen` provoquerait un crash `TypeError` en plein run plutôt qu'un échec contrôlé.

**Suggestion** : `result['card'] as CardInstance?` avec vérification explicite, ou typer le retour de `RestCardSelectionScreen` via une petite classe dédiée plutôt qu'un `Map<String, dynamic>` non typé.

### 5. Écrans majeurs sans test dédié

Aucun fichier sous `test/` ne référence directement ces écrans :

- `draft_screen.dart` (938 lignes — voir aussi constat n°1)
- `class_selection_screen.dart`
- `forge_fusion_screen.dart`
- `relic_exchange_screen.dart` (seul son controller est couvert, via `relic_exchange_test.dart`)
- `rest_screen.dart`
- `deck_screen.dart`
- `card_dictionary_screen.dart`
- `boss_card_draft_screen.dart`

**Suggestion** : prioriser `draft_screen.dart` (le plus gros, et lié au constat n°1) et `rest_screen.dart` (lié au constat n°4), avant les autres.

### 6. Incohérence de dialogue — `home_screen.dart`

**Constat** : [home_screen.dart:39,62](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/home_screen.dart) utilise `AlertDialog(...)` brut à deux endroits, alors que le reste de la codebase (8 fichiers) s'est standardisé sur le wrapper `GameDialog`. Risque de divergence visuelle/comportementale mineure (thème, boutons, animations d'ouverture) par rapport au reste du jeu.

**Suggestion** : migrer ces deux `AlertDialog` vers `GameDialog` par cohérence, en priorité basse (pas de bug fonctionnel).

---

## 💡 Priorisation Suggérée

1. **Constat n°1** (récompenses draft_screen) — le plus risqué architecturalement : logique dupliquée + couplage fragile par chaîne de caractères, aggravé par l'absence totale de test (constat n°5).
2. **Constat n°2** (tests `RewardController`) — combler avant de toucher à la logique de récompense du constat n°1, pour sécuriser tout refactoring futur.
3. **Constat n°3** (catch silencieux) — gain rapide et peu risqué (ajout de logs uniquement, aucun changement de comportement).
4. **Constat n°4** (cast non sécurisé) — corrigé rapidement en même temps qu'un futur passage sur `rest_screen.dart`.
5. **Constat n°5** (couverture de tests écrans) — travail de fond, à mener progressivement.
6. **Constat n°6** (incohérence dialogue) — cosmétique, à traiter en passant.
