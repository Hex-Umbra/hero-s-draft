# P-42 tranche 1 et P-44 lot 1, partie 3 — Les évolutions de signature — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, chaque signature évolue tous les cinq niveaux du héros : un écran à trois rouleaux propose trois évolutions de son pool (trois mineures, quatre majeures), le joueur en prend une, la tuile de combat montre aussitôt les valeurs, le coût, la recharge, la cible et la description évolués, un badge de niveau et une icône par évolution prise ; les choix survivent à la sauvegarde ; l'éditeur de contenu sait écrire une évolution.

**Architecture:** Une évolution est une donnée du fichier de sa signature (`SignatureEvolutionData`, sous `evolutions`), faite de deltas du vocabulaire de `CardDelta` — plus une sorte neuve, `flatBonus` — et de deux champs propres, `target` et `cooldown`. `SignatureInstance` porte ses références `id:niveau` ; sa vue de carte (`asCard`) les traduit en `CardInstance.extraDeltas`, que l'applicateur des runes (`EffectiveCard.apply`) lit après les runes : la couture d'ADR-105 D1, sans que runes et évolutions partagent stockage ni affichage. Le tirage et l'admissibilité vivent dans une règle pure (`SignatureEvolutionRules`) ; l'attente se dérive du niveau du héros, rien de neuf ne se compte ; seule la liste des références se sauvegarde, sous `signatureEvolutions`. L'écran d'évolution reprend le carrousel du draft de niveau ; la barre de signatures se mesure avant d'être posée (A38).

**Tech Stack:** Flutter / Dart 3, Flame (non touché), Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md` — §10 « Partie 3 » pour le périmètre ; §3.7 (gabarits, évolutions, pools, icônes), §4.10 (le moteur des évolutions), §5.1 (l'écran), §5.2 (les deux lignes marquées 3 : tuile de combat, tuile hors combat), §6.1 (les clés `evolution…` et `levelLabel`), §7 (la ligne marquée 3 : descripteur de signature), §8 (la sauvegarde — **tâche à risque**), §9 (les lignes marquées 3), §11. Les décisions de §1 — les réponses du propriétaire de §1.2 (dont Q6, Q7, P-2 (c), P-4 (a), l'écran d'évolution) et les arbitrages A1 à A38 de §1.3, en particulier A24 à A28 et A35 à A38 — sont acquises : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md`.

Réponses du propriétaire reprises telles quelles (spec §1.2) : **Q6** — 3 mineures et 4 majeures par signature ; une majeure en manque tire une mineure (repli). **Q7** — deux majeures contradictoires s'excluent par une liste `excludes` d'ids sur l'évolution, lue dans les deux sens. **P-2 (c)** — un badge de niveau et une icône par évolution prise sur la tuile. **P-4 (a)** — l'icône de l'évolution sur chaque rouleau. **L'écran** — le carrousel `DraftScreen` / `DraftCardReel`, trois rouleaux, une fois par signature, par le rideau de `pendingDrafts` ; chaque rouleau : nom, description, palier, « 1 → 2 » pour une mineure déjà prise ; l'en-tête nomme la signature.

**Les noms, valeurs, textes et icônes des 42 évolutions sont des ordres de grandeur** (fiche 8.5) : le plan les écrit tels que la spec les fixe (§3.7), le test du propriétaire les corrigera. Ce ne sont pas des questions.

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées (comme aux plans des parties 1 et 2) :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge (aucune tâche de ce plan n'en fait : les six fichiers de signature sont modifiés en place) ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` (aucun ici) ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit (`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

S'y ajoutent :

- **jamais `git stash`, jamais `git commit --amend`** ; messages de commit en **ASCII**, sans accent.

Propres à cette partie :

- **La branche.** Le plan s'exécute sur `feat/v0.5.7-p42-tranche-1-p44-lot-1`, la branche courante, dans le checkout principal. Il ne crée aucune branche, n'en change pas, ne commite rien sur `main`, ne pousse rien. Pas de worktree. Le fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_…`) est modifié dans l'arbre de travail par l'orchestrateur : **ne jamais l'indexer**.
- **La base de tests** : `flutter test` rend **1916** sur la branche (mesuré le 03/11, à la fin de la partie 2). Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ». **Total attendu en fin de plan : 2003** (+87 ajoutés, aucun retiré).
- **Les références `fichier:ligne`** ont été relues le 2026-11-03 sur `996421a`. Une tâche qui modifie un fichier décale les lignes des suivantes : l'implémenteur se fie au symbole nommé, la ligne n'est qu'un repère.
- **La tâche à risque est la Task 5** (la sauvegarde) : son code et ses tests s'écrivent ici en entier, et le vérificateur les rejoue dans un clone. Ailleurs, seul l'algorithme d'A38 (Task 7), imposé ligne à ligne par la spec, est écrit.
- **Les cartes, les runes et le moteur de P-44 lot 1 ne changent pas** ; `tool/simulations/` ne change pas (ADR-108 D5) ; `assets/data/passives/mage_mark.json` garde `"trigger": "onAttackPlayed"` (D34).
- **Deux réponses du propriétaire attendues** (PN12, PN13 du fichier de vérifications) : le plan s'écrit sous l'option recommandée, marquée **(provisoire)** là où elle s'applique (Task 3, Task 7).

## Review Focus

Cinq modes d'échec que la spec implique pour la partie 3 et qu'aucun test ne garde encore, du plus probable au moins probable ; chacun est confié à la tâche qui écrit le test qui le garde.

1. **Une évolution perdue ou déformée à la reprise.** L'ordre de première prise — que la rangée d'icônes lit (A37) — réordonné ; une majeure relue au niveau 2 ; deux majeures exclues relues ensemble ; une évolution supprimée d'une mise à jour qui fait échouer la relecture au lieu d'être signalée ; une sauvegarde de `0.5.6` sans la clé qui ne se relit plus. → **Task 5** (neuf tests, code en entier).
2. **Un tirage qui offre l'interdit, ou un choix qui écrit sans droit.** Une majeure au palier mineur, une majeure exclue par une prise (dans un sens ou dans l'autre), moins de trois rouleaux quand trois évolutions existent, un `chooseSignatureEvolution` qui écrit quand rien n'attend ou qui n'appelle pas la sauvegarde. → **Task 4** (`signature_evolution_rules_test`).
3. **Une tuile qui ment.** Le coût, la recharge, la cible ou la description de base au lieu des évolués ; l'accessibilité lue sur le coût de base (`signature_bar.dart:114`, `currentMana >= signature.cost`) ; un gabarit brut « {damage} » hors combat. → **Task 3** (`asCard`), **Task 7** (la tuile, `canAfford`), **Task 2** (`SignatureTile`).
4. **Une évolution qui attend sans rideau, ou un rideau qui ouvre le mauvais écran.** `pendingFor` faux ; l'ordre des attentes (Châtiment puis Bouclier Sacré au niveau 5 ; les deux mineures puis les deux majeures sur un saut de 4 à 10) ; l'évolution ouverte avant le draft de niveau ; les nœuds ouverts pendant une attente. → **Task 4** (`nextPendingEvolution`, `hasPendingChoice`), **Task 6** (`map_screen_test` : le rideau, l'ordre des écrans, et « les noeuds restent fermes tant qu une evolution attend », qui lit sur le `MapNodeWidget` d'un nœud `node_0_*` son `isAvailable` faux — `map_screen.dart:380` — et son `onTap()`, appelé directement, sans effet — `:403`).
5. **La barre qui sort de l'écran ou bouge à niveau 0 (A38).** La colonne qui monte en `1280 × 800` au niveau 0 par rapport à `0.5.6` ; une réduction sous 0,75 ; une tuile réduite qui ne répond plus au toucher, ou l'invite qui disparaît. → **Task 7** (fonction de placement, deux tests de widget dont un à `H = 400`).

**Les autres trous** — ceux de la section « Pour le Review Focus des plans » des vérifications de la spec qui touchent la partie 3, et les points reportés des parties 1 et 2 —, chacun confié :

| Trou | Tâche, test ou décision |
|:---|:---|
| `nextPendingEvolution` : Châtiment puis Bouclier Sacré au niveau 5 ; mineures puis majeures sur un saut de 4 à 10 | Task 4 |
| Hors combat, `SignatureTile` n'affiche jamais un gabarit brut | Task 2, `signature_tile_test` |
| Refus à l'écran par `signature_bar.dart:114` (`signature.cost` évolué) — **point reporté** | Task 7 : la tuile lit `EffectResolver.canAfford(signature.asCard, heroStats)`, la règle unique d'A10 ; `SignatureBar` reçoit `heroStats` au lieu de `currentMana` |
| Q11 sur une signature à deux statuts d'évolution (*Projectile Magique*, `ember` et `exposure`) : un seul bonus, sur le premier dans l'ordre des effets ajoutés | Task 3, `effect_resolver_test` |
| Écran : mineure déjà prise, `{val}` au prochain niveau (*Zèle* 1 → 2, « +4 dégâts ») et la ligne « 1 → 2 » | Task 2 (`{val}`), Task 6 (l'écran) |
| `{val}` d'une majeure `reduceCost` : `min(coût, valuePerLevel)` (*Dévotion* sur *Châtiment*, coût 1 → 1) | Task 2 |
| *Célérité* : même `icon`, même `color`, même texte dans ses cinq pools | Task 2 |
| Le gabarit d'éditeur de la signature (`entity_descriptor.dart:318-328`) sans `evolutions` : `entity_validator_test`, `entity_descriptor_test` rougiraient dès que `evolutions` est exigée | Task 2 : le gabarit porte une évolution complète, verbale (`ardor`), dans la même tâche que l'exigence |
| La barre réduite : un toucher sur une tuile réduite arme encore, l'invite reste visible ; un cas à `H ≈ 400` | Task 7 |
| Au niveau 0 et en `1280 × 800`, la colonne n'a pas bougé par rapport à `0.5.6` | Task 7 |
| Le badge sur la tuile étroite, à la vraie police | Hors plan : tests manuels (les tests de widget rendent une police carrée, A36) |
| L'aller-retour de sauvegarde garde l'ordre de première prise | Task 5 |
| Chaque entrée d'`evolutionIcons` et d'`evolutionColors` sert au moins une évolution | Task 6, `referential_integrity_test` |
| Sous P-4 (a) : le paramètre de `DraftCardReel` est facultatif, le draft de niveau ne change pas | Task 6, `draft_card_reel_test` |
| A33 : le budget de D38 reste vrai sur chaque signature évoluée | Task 3, `card_catalog_test` (toutes les évolutions prises) |
| **Point reporté** — `SignatureInstance` construit un `CardData` sans `hpCost` ni `armorCost` (`signature_instance.dart:20-36`) | Task 3 : `asCard` est réécrit ; `SignatureData` n'a pas de coût autre que le mana, les défauts (0) sont justes et le commentaire d'`asCard` le dit ; la tuile lisant `canAfford` (Task 7), un coût non-mana futur serait lu sans retouche |
| **Point reporté** — `scaleTerm` lit une cible morte pour `targetStatus` et `targetMissingHp` | **Déjà traité** en partie 2 (Task 4) : `effect_resolver.dart:235-238` filtre `currentPv > 0`, gardé par `scale_with_test.dart:305` « une cible morte ne nourrit ni targetStatus ni targetMissingHp ». Rien à faire |
| **Point reporté** — `ProportionalStatus` vit sous `lib/game/services/` mais `lib/models/enemy_instance.dart:3` l'importe | **Laissé hors de la partie 3** : aucune tâche n'ouvre `enemy_instance.dart` ni `proportional_status.dart`, et le déplacer élargirait la vague (filtre 7). À la file de la clôture |
| **Point reporté** — le texte de croissance `targetStatus` nomme le statut en français dans la version anglaise (`card_rule_texts.dart:65-69`, `_statusName` lit `createStatus(...).name`) | **Laissé hors de la partie 3** : aucune tâche n'ouvre `card_rule_texts.dart`, aucune carte livrée ne lit cette source ; à régler avec le lot de *Marque du Mage* (tranche 3), qui sera son premier lecteur, ou à la file |

---

## Carte des fichiers

| Fichier | Rôle | Tâche |
|:---|:---|:---:|
| `lib/models/data/card_delta.dart` | `FlatBonusDelta`, la sorte neuve | 1 |
| `lib/models/effective_card.dart`, `lib/models/card_instance.dart` | `extraDeltas`, lus après les runes | 1 |
| `lib/models/data/forge_upgrade_data.dart` | `{val}` d'un `flatBonus` (le `switch` exhaustif) | 1 |
| `lib/models/data/signature_evolution_data.dart` *(nouveau)* | `EvolutionTier`, `SignatureEvolutionData` et ses règles de chargement | 2 |
| `lib/models/data/signature_data.dart` | `evolutions`, règles du pool, gabarits | 2 |
| `assets/data/classes/{paladin,berserker,mage}/skills/*.json` (six) | Gabarits et pools | 2 |
| `lib/models/signature_instance.dart` | `evolutions`, `level`, `taken`, `asCard`, `cost`, `cooldown`, `pendingFor`, `nextTier` ; `restore` | 3, 5 |
| `lib/game/systems/signature_evolution_rules.dart` *(nouveau)* | Le tirage, l'admissibilité, le choix | 4 |
| `lib/game/controllers/run_controller.dart` | `nextPendingEvolution`, `hasPendingChoice`, `chooseSignatureEvolution` ; `signatureEvolutions` | 4, 5 |
| `lib/ui/widgets/signature_evolution_style.dart` *(nouveau)* | `evolutionIcons`, `evolutionColors`, `EvolutionIcon` | 6 |
| `lib/ui/screens/signature_evolution_screen.dart` *(nouveau)* | L'écran d'évolution | 6 |
| `lib/ui/widgets/relic_carousel/draft_card_reel.dart`, `lib/ui/widgets/draft/draft_choice_card.dart` | Le paramètre `icon` facultatif | 6 |
| `lib/ui/screens/map_screen.dart` | Le rideau et les gardes de nœud | 6 |
| `lib/ui/widgets/hud/signature_bar.dart`, `combat_side_panels.dart`, `combat_top_bar.dart`, `lib/ui/screens/game_screen.dart` | La tuile évoluée, le badge, la rangée, la bande | 7 |
| `lib/l10n/app_fr.arb`, `app_en.arb` (+ trois `app_localizations*.dart`) | Clés `evolution…` ; `levelLabel` réécrite | 6, 7 |
| `lib/services/content_editor/entity_descriptor.dart` | Le gabarit (2), puis le descripteur des évolutions (8) | 2, 8 |
| `test/unit/signature_evolution_data_test.dart`, `test/unit/signature_evolution_rules_test.dart`, `test/widget/signature_evolution_screen_test.dart` *(nouveaux)* | — | 2, 4, 6 |
| Les autres tests touchés | Nommés tâche par tâche | 1 à 8 |

Ordre : la couture de l'applicateur (1) ; la donnée, ses règles et les six pools (2), qui ne changent rien au jeu tant qu'aucune signature ne porte d'évolution ; la vue évoluée (3) ; le tirage, le choix et l'attente (4) ; **la tâche à risque, la sauvegarde (5)**, avant que le joueur puisse prendre une évolution ; l'écran et le rideau (6), qui ouvrent le jeu aux évolutions ; la tuile (7) ; l'éditeur (8) ; la vérification (9).

| Après la tâche | Total de tests |
|:---:|:---:|
| base | 1916 |
| 1 | 1922 |
| 2 | 1941 |
| 3 | 1952 |
| 4 | 1963 |
| 5 | 1972 |
| 6 | 1987 |
| 7 | 1998 |
| 8 | 2003 |

---

### Task 1: La couture — `flatBonus` et `CardInstance.extraDeltas`

Additive pour le jeu : aucune carte ni rune livrée ne porte `flatBonus`, et seule `SignatureInstance.asCard` remplira `extraDeltas` (Task 3).

**Files:**
- Modify: `lib/models/data/card_delta.dart:5-29` (commentaire de tête, `typeNames`), `:33-67` (`fromJson`), après `:96-120` (la classe neuve) ; `lib/models/effective_card.dart:74-155` (`apply`), `:175-186` (`withRunes`) ; `lib/models/card_instance.dart:5-54` ; `lib/models/data/forge_upgrade_data.dart:318-337` (`_valueAdded`)
- Test: `test/unit/effective_card_test.dart`, `test/unit/forge_upgrade_data_test.dart`, `test/unit/referential_integrity_test.dart:16-28` (le `switch` exhaustif `_effectOf`)

**Interfaces:**
- Produces :
  - `final class FlatBonusDelta extends CardDelta` — `const FlatBonusDelta({required String effect, required int valuePerLevel, String? statusId})` ; `bool targets(CardEffect e) => e.type == effect && (statusId == null || e.statusId == statusId)` ; `toJson()` : `{'type': 'flatBonus', 'effect', 'valuePerLevel', if (statusId != null) 'statusId'}`. Spec A24 : +`valuePerLevel × L` à **chaque** effet propre que `targets` vise (PN2), ajouté après la rareté, jamais multiplié par elle, sur chaque coup d'un multi-coups.
  - `CardDelta.typeNames` gagne `'flatBonus'` (PN1 : une sorte du vocabulaire commun ; une rune pourrait la porter, aucune ne le fait). `CardDelta.fromJson` : `'flatBonus'` → `effect` (texte), `valuePerLevel` (`_positive`), `statusId` facultatif, **refusé** hors d'un `effect: 'apply_status'` (la règle d'`AddEffectDelta`).
  - `CardInstance` gagne `final List<(CardDelta, int)> extraDeltas` (paramètre nommé, défaut `const []`), gardé par `copyWith`, **jamais écrit** par `toJson` ; son commentaire : seule `SignatureInstance.asCard` le remplit (A24).
  - `EffectiveCard.withRunes(CardData data, CardRarity rarity, List<String> runes, {Iterable<(CardDelta, int)> extraDeltas = const []})` — `apply(data, rarity, [...runeDeltas(...), ...extraDeltas])` : les évolutions **après** les runes. `CardInstance.effective` le lit avec ses `extraDeltas`. Les deux commentaires au futur — « en vague 5, aux évolutions de signature » (`effective_card.dart:74-76`) et « la vague 5 y traduira de même les évolutions » (`card_delta.dart:10-12`) — passent au présent.
  - `apply` : `case FlatBonusDelta()` — pour chaque `i` où `delta.targets(effects[i])`, `effects[i] = effects[i].copyWithValue(effects[i].value + delta.valuePerLevel * level)`.
  - `_valueAdded` : `FlatBonusDelta() => delta.valuePerLevel * level`. `_effectOf` (test d'intégrité) : `FlatBonusDelta(:final effect) => effect`.

- [ ] **Step 1: Écrire les tests qui échouent**

`effective_card_test.dart`, groupe neuf `flatBonus (A24)` :
- `flatBonus ajoute N x L a chaque effet propre du type, apres la rarete` — carte épique `[damage 6, armor 5]`, `(FlatBonusDelta(effect: 'damage', valuePerLevel: 2), 3)` : la valeur de dégâts vaut `CardRarity.epic.scaleValue(6) + 6`, l'Armure `scaleValue(5)` inchangée ; aucun `addedEffects`.
- `flatBonus a statusId ne vise que l apply_status de ce statut` — `[apply_status might 2, apply_status burn 1, draw 1]` et `FlatBonusDelta(effect: 'apply_status', statusId: 'might', valuePerLevel: 1)` au niveau 2 : `might` vaut 4, `burn` 1, `draw` 1.
- `extraDeltas s appliquent apres les runes et ne s ecrivent pas` — `CardInstance(data: <damage 6>, forgeUpgrades: ['sharp:1'], extraDeltas: [(FlatBonusDelta(effect: 'damage', valuePerLevel: 2), 1)])` sur un registre portant `sharp` (`percentBonus` 15) : la valeur jouée vaut la valeur de `sharp` seule + 2 ; `toJson()` n'a pas la clé `extraDeltas` ; `copyWith(rarity: …)` garde les `extraDeltas`.

`forge_upgrade_data_test.dart` :
- `flatBonus se lit et se reecrit, statusId facultatif` — `CardDelta.fromJson({'type': 'flatBonus', 'effect': 'damage', 'valuePerLevel': 2})` : `isA<FlatBonusDelta>()`, `statusId` nul ; avec `effect: 'apply_status', statusId: 'might'` : `statusId` `'might'` ; `toJson()` rend l'entrée telle quelle.
- `flatBonus sans effect, a valuePerLevel 0, ou a statusId hors apply_status est refuse` — trois `throwsFormatException`.
- `le {val} d une rune flatBonus vaut valuePerLevel x L` — rune de description `+{val}` portant `flatBonus damage 3` : `getDescription(2, 'fr', card, common)` vaut `+6`.

Réécrit, sans changer le total : `_effectOf` de `referential_integrity_test.dart` gagne son cas.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/effective_card_test.dart test/unit/forge_upgrade_data_test.dart`
Expected: échec de compilation — `FlatBonusDelta` et `extraDeltas` n'existent pas.

- [ ] **Step 3: Implémenter** — la classe, le parseur, les deux `switch` exhaustifs (`apply`, `_valueAdded`), `withRunes`, `CardInstance`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/referential_integrity_test.dart test/unit/content_editor/entity_descriptor_test.dart`.
Expected: tout passe (le descripteur de rune lit `CardDelta.typeNames`, qui gagne `flatBonus` sans retouche du test).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1922** (1916 + 3 + 3).

- [ ] **Step 6: Commit**

`git add` des quatre fichiers de `lib/` et des trois tests, puis `git commit` — `feat(signatures): flatBonus et extraDeltas, la couture des evolutions`.

---

### Task 2 (interface): Les évolutions en donnée — `SignatureEvolutionData`, les gabarits, les six pools

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 3. Ce que le joueur voit : les descriptions des trois signatures qui piochent disent « carte(s) » à la carte de classe et au dictionnaire (spec §3.7) ; rien d'autre ne change à l'écran.

**Files:**
- Create: `lib/models/data/signature_evolution_data.dart`, `test/unit/signature_evolution_data_test.dart`
- Modify: `lib/models/data/signature_data.dart:1-135` ; les six `assets/data/classes/*/skills/*.json` ; `lib/services/content_editor/entity_descriptor.dart:318-328` (le gabarit de la signature)
- Test: `test/widget/signature_tile_test.dart` ; réécrits sans changer le compte, chaque document de signature écrit à la main qui passe par `SignatureData.fromJson` : `test/unit/signature_data_test.dart:6-23` (`valid()`), `test/unit/content_editor/fixtures.dart:26-41` (`fixtureSignature`), et les cinq tests qui rougissent réellement : `test/unit/content_editor/entity_descriptor_test.dart:279` « chaque gabarit porte exactement les cles attendues » (l'ensemble de clés de la signature, `:300-307`, gagne `evolutions` après `'effects'`, `:306`), `test/unit/content_editor/entity_validator_test.dart:114` « une signature homonyme d une signature du registre est refusee » (par `fixtureSignature`), et les trois tests de `signature_data_test.dart` qui lisent `valid()` sans refus (`:31`, `:50`, `:119`). `entity_writer_test.dart:285`, `content_editor_screen_test.dart:1419` et `scale_with_test.dart:139` (voir PN4) restent verts et ne se réécrivent pas

**Interfaces:**
- Consumes : `FlatBonusDelta`, `CardDelta.fromJson` (Task 1).
- Produces (`signature_evolution_data.dart`, couche données) :
  - `enum EvolutionTier { minor, major }`.
  - `class SignatureEvolutionData` — `const SignatureEvolutionData({required String id, required EvolutionTier tier, String nameEn = '', String nameFr = '', String descriptionEn = '', String descriptionFr = '', List<CardDelta> deltas = const [], CardTarget? target, int cooldown = 0, List<String> excludes = const [], String icon = '', String color = ''})` ; champs du même nom.
  - `static const deltaTypeNames = ['flatBonus', 'addEffect', 'reduceCost', 'critBonus']` ; `static const targetNames = ['allEnemies']` — lus par le chargeur et par l'éditeur (Task 8).
  - `factory SignatureEvolutionData.fromJson(Map<String, dynamic> json)` — chaque refus est une `FormatException` dont le message nomme l'id de l'évolution et la clé fautive. Règles de spec §3.7, ligne à ligne : `id` texte non vide ; `tier` `minor` ou `major` ; `name_fr`, `name_en`, `description_fr`, `description_en` textes non vides ; `deltas` **facultative** (absente : aucune — PN3), sinon une liste dont chaque `type` est dans `deltaTypeNames` (toute autre refusée, nommée, `percentBonus` compris), lue par `CardDelta.fromJson` ; `target` majeure seulement, `allEnemies` seulement ; `cooldown` majeure seulement, entier non nul ; `excludes` majeure seulement, liste non vide de textes, sans l'id lui-même ; au moins un changement (`deltas` non vide, `target` ou `cooldown`), sinon refus nommant `deltas` ; `icon` et `color` textes non vides ; **chiffrée ou verbale** (A25) : une évolution qui porte `addEffect`, `critBonus` ou `target` ne porte ni `flatBonus`, ni `reduceCost`, ni `cooldown` — le message contient `verbale`.
  - `bool get isVerbal` — `target != null` ou un delta `AddEffectDelta` / `CritBonusDelta`.
  - `bool excludesOrIsExcludedBy(SignatureEvolutionData other) => excludes.contains(other.id) || other.excludes.contains(id)` — Q7, lu dans les deux sens (Tasks 4 et 5).
  - `String getName(String locale)` ; `String getDescription(int level, String locale, {required int cost})` — `{val}` vaut ce que le **premier** delta porteur d'un nombre ajoute au niveau `level` : `valuePerLevel × level` pour `flatBonus`, `addEffect`, `critBonus` ; pour `reduceCost`, `min(cost, valuePerLevel × level)` (la baisse réelle, bornée à 0 — `_costCut`, `forge_upgrade_data.dart:356-366`) ; 0 sans delta.
- Produces (`signature_data.dart`) :
  - `SignatureData` gagne `final List<SignatureEvolutionData> evolutions` (paramètre nommé, défaut `const []` pour les tests construits en code).
  - `fromJson` lit `evolutions` **après** les effets et `checkScaleTarget` (PN4 : les règles de gabarit lisent les effets). Règles du pool (spec §3.7), refus nommant `evolutions` ou l'id fautif : liste exigée, non vide ; ids uniques, en `snake_case` (`^[a-z][a-z0-9]*(_[a-z0-9]+)*$`) ; au moins une mineure (le message contient `mineure`) ; une évolution `target` n'est admise que sur une signature `singleEnemy` ; chaque id d'`excludes` nomme une **majeure** du même pool ; **gabarits** — chaque `{clé}` de `description_fr` et `description_en` désigne un effet propre (`clé` est un type de `templateEffectTypes`, ou le `statusId` d'un `apply_status` propre), et chaque effet que vise un `flatBonus` du pool a son `{clé}` dans les deux.
  - `static const templateEffectTypes = {'damage', 'armor', 'heal', 'draw', 'gain_mana'}` ; `static String fillTemplate(String template, List<CardEffect> effects)` — chaque `{clé}` reçoit la valeur du **premier** effet de ce type (ou du premier `apply_status` de ce statut) ; une clé sans effet reste telle quelle (le chargeur l'interdit).
  - `String getDescription(String locale)` → `fillTemplate(<la description de la langue>, effects)` : la signature de base, gabarit rempli (A25 ; `SignatureTile`, spec §5.2).
- Les six fichiers (spec §3.7, **mot pour mot**) :
  - `description_fr` / `description_en` : les gabarits de la table de spec §3.7.
  - `evolutions` : les 42 évolutions de la table « Les six pools », mineures puis majeures, chacune avec son `id`, `tier`, ses quatre textes, et `icon` / `color` de la table « Les icônes ». La traduction des colonnes en clés :
    - `flatBonus <effet> N` → `{"type": "flatBonus", "effect": "<effet>", "valuePerLevel": N}` ; `flatBonus apply_status might 1` (*Colère*) porte en plus `"statusId": "might"` ;
    - `addEffect <statut> N, D tours` (majeure) ou `D tours par niveau` (mineure) → `{"type": "addEffect", "effect": "apply_status", "statusId": "<statut>", "valuePerLevel": N, "durationPerLevel": D}` ; `addEffect armor|heal|draw N` → `{"type": "addEffect", "effect": "<armor|heal|draw>", "valuePerLevel": N}` ;
    - `critBonus 5` → `{"type": "critBonus", "valuePerLevel": 5}` ; `reduceCost 1` → `{"type": "reduceCost", "valuePerLevel": 1}` ;
    - `cooldown −1` / `+1` → `"cooldown": -1` / `1`, sans `deltas` s'il n'y a qu'elle ; `target allEnemies` → `"target": "allEnemies"`, sans `deltas` ;
    - `excludes` : `haste` ↔ `devastation` sur *Frappe Téméraire*, `haste` ↔ `overload` sur *Projectile Magique*, déclarés des deux côtés.
  - Exemple, *Dévastation* : `{"id": "devastation", "tier": "major", "name_fr": "Dévastation", "name_en": "Devastation", "description_fr": "+10 dégâts, recharge allongée d'un tour", "description_en": "+10 damage, cooldown one turn longer", "deltas": [{"type": "flatBonus", "effect": "damage", "valuePerLevel": 10}], "cooldown": 1, "excludes": ["haste"], "icon": "bolt_rounded", "color": "yellowAccent"}`.
- Le gabarit d'éditeur de la signature gagne `"evolutions": [ { "id": "ardor", "tier": "minor", "name_fr": "Ardeur", "name_en": "Ardor", "description_fr": "+{val} % de critique", "description_en": "+{val}% critical chance", "deltas": [ { "type": "critBonus", "valuePerLevel": 5 } ], "icon": "gps_fixed_rounded", "color": "amber" } ]` — verbale, pour qu'une description saisie sans `{…}` reste valide ; la recette de classe (`class_recipe.dart`), qui remplit ses signatures du gabarit, en hérite.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/signature_evolution_data_test.dart` *(nouveau ; l'aide `refusing(clé)` de `signature_data_test.dart:25-27`)* :
- `une evolution complete se lit` — l'exemple *Dévastation* : `tier` major, `deltas` `[isA<FlatBonusDelta>()]` à 10, `cooldown` 1, `excludes` `['haste']`, `icon` `'bolt_rounded'`, `color` `'yellowAccent'`, `isVerbal` faux.
- `un tier inconnu est refuse, nomme` — `'legendary'` : `refusing('tier')`.
- `une sorte de delta hors des quatre est refusee, nommee, percentBonus compris` — `percentBonus`, `armorPierce` : `refusing(<la sorte>)`.
- `target, cooldown et excludes sur une mineure sont refuses (D54)` — trois refus, chacun nommant sa clé.
- `target autre que allEnemies, cooldown nul : refuses` — `'self'` : `refusing('target')` ; `0` : `refusing('cooldown')`.
- `une evolution sans aucun changement est refusee` — mineure sans `deltas` : `refusing('deltas')`.
- `icon ou color absents ou vides : refuses` — quatre refus.
- `chiffree et verbale a la fois : refusee` — `addEffect` + `cooldown`, puis `target` + `flatBonus` : `refusing('verbale')`.
- `un texte bilingue manquant est refuse` — sans `name_en`, `description_fr` vide.
- `le pool : evolutions absente, vide ou sans mineure, refusee` — `refusing('evolutions')` deux fois, `refusing('mineure')`.
- `le pool : ids en double ou hors snake_case refuses` — deux `zeal` : `refusing('zeal')` ; `'Zeal'` : `refusing('Zeal')`.
- `le pool : une majeure target sur une signature qui ne vise pas un ennemi unique est refusee` — signature `self` : `refusing('target')`.
- `le pool : excludes vers un id inconnu ou une mineure est refuse` — `refusing('ghost')`, `refusing('zeal')`.
- `les gabarits : un {cle} sans effet propre, ou un effet vise par flatBonus sans son {cle}, refuses` — `« Inflige {heal} dégâts. »` sur `[damage 6]` : `refusing('{heal}')` ; `flatBonus damage` et un `description_en` sans `{damage}` : `refusing('{damage}')`.
- `getDescription remplit le gabarit des valeurs de base` — `[apply_status might 2, draw 1]` et `« Applique {might} Puissance ce tour-ci. Pioche {draw} carte(s). »` : `« Applique 2 Puissance ce tour-ci. Pioche 1 carte(s). »` ; une description sans accolades est rendue telle quelle.
- `{val} : valuePerLevel x L ; pour reduceCost, la baisse reelle bornee au cout` — *Zèle* (`flatBonus damage 2`, `« +{val} dégâts »`) au niveau 2 : `« +4 dégâts »` ; *Ardeur* au niveau 1 en anglais : `« +5% critical chance »` ; une majeure `reduceCost 1` de texte `« -{val} »` : `« -1 »` à `cost: 1`, `« -0 »` à `cost: 0`.
- Groupe `les six pools livres` (`TestWidgetsFlutterBinding.ensureInitialized()`, `setUpAll` sur `loadGameDataRegistry(rootBundle)`) :
  - `les six pools sont ceux de spec 3.7 : trois mineures, quatre majeures (Q6)` — `{s.id: (mineures, majeures)}` vaut : `smite` `([zeal, aegis, ardor], [haste, sentence, radiance, devotion])` ; `holy_shield` `([ward, mercy, resolve], [haste, consecration, inspiration, lasting_aegis])` ; `reckless_strike` `([brutality, instinct, shatter], [haste, devastation, cleave, composure])` ; `rage_form` `([anger, hide, second_wind], [haste, berserk, rally, fury])` ; `magic_missile` `([acuity, precision, ember], [haste, overload, nova, exposure])` ; `mana_surge` `([mana_shield, attunement, clarity], [foresight, glyph, empower, serenity])`. Et : *Dévastation* `cooldown` 1 et `flatBonus` 10 ; *Surcharge* `cooldown` 1 et `flatBonus` 8.
  - `haste porte dans ses cinq pools la meme icone, la meme couleur, le meme texte ; les exclusions sont declarees des deux cotes` — les cinq `haste` : `(icon, color, name_fr, name_en, description_fr, description_en, cooldown)` identiques, `cooldown` −1 ; `mana_surge` n'en a pas ; `haste` ↔ `devastation` et `haste` ↔ `overload` dans les deux `excludes`.

`signature_tile_test.dart` :
- `hors combat, la tuile ne montre jamais un gabarit brut` — `SignatureData` de `descriptionFr` `« Inflige {damage} dégâts. »` sur `[damage 6]` : `find.text('Inflige 6 dégâts.')` trouvé, `find.textContaining('{')` rien.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_evolution_data_test.dart test/widget/signature_tile_test.dart`
Expected: échec de compilation — `SignatureEvolutionData` n'existe pas.

- [ ] **Step 3: Implémenter** — le modèle, les règles du pool et les gabarits, les six fichiers, le gabarit d'éditeur, puis les documents de test écrits à la main (chacun gagne l'évolution du gabarit, `ardor`).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/signature_data_test.dart test/unit/scale_with_test.dart test/unit/real_bundle_load_test.dart test/unit/content_editor/ test/widget/content_editor_screen_test.dart test/widget/card_dictionary_screen_test.dart test/widget/class_selection_screen_test.dart`.
Expected: tout passe — dont `shipped_entities_round_trip_test` sur les six signatures à évolutions.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1941** (1922 + 18 + 1). `dart run tool/sync_assets.dart --check` → code 0.

- [ ] **Step 6: Commit**

`git add` par chemin (les six JSON compris), puis `git commit` — `feat(signatures): les evolutions en donnee, six pools et gabarits`.

---

### Task 3: La signature évoluée — `SignatureInstance`

**Files:**
- Modify: `lib/models/signature_instance.dart:1-37`
- Test: `test/unit/signature_instance_test.dart`, `test/unit/card_catalog_test.dart`, `test/unit/effect_resolver_test.dart` (groupe `Q11`, `:313`)

**Interfaces:**
- Consumes : `CardInstance.extraDeltas`, `EffectiveCard.apply` (Task 1) ; `SignatureEvolutionData`, `SignatureData.evolutions`, `SignatureData.fillTemplate` (Task 2) ; `ForgeUpgradeData.levelsOf` (`forge_upgrade_data.dart:423-432`). `signature_instance.dart`, qui n'importe aujourd'hui que `card_instance.dart`, `data/card_data.dart` et `data/signature_data.dart`, gagne ceux que ses getters et `asCard` lisent : `dart:math` (`show max`), `effective_card.dart`, `data/card_delta.dart` (seulement si le fichier nomme le type — par exemple la variable locale `List<(CardDelta, int)>` des deltas d'`asCard` ; inféré, l'import resterait sans usage et `dart analyze` le signalerait), `data/forge_upgrade_data.dart` (pour `levelsOf`) et `data/signature_evolution_data.dart` ; la Task 5 n'ajoutera que `missing_save_item.dart`.
- Produces (spec §4.10, ligne à ligne) :
  - `const SignatureInstance(this.data, {this.evolutions = const []})` ; `final List<String> evolutions` — des références `id:niveau`, dans l'ordre de la première prise.
  - `List<(SignatureEvolutionData, int)> get taken` — `levelsOf(evolutions)`, chaque id relu dans `data.evolutions` ; un id absent du pool est passé (la relecture, Task 5, n'en laisse aucun).
  - `int get level` — la somme des niveaux de `taken`.
  - `CardInstance get asCard` — la `CardData` d'E4 sur `data.cost` (plus `cost`, sinon `cost` et `asCard` s'appelleraient l'un l'autre) ; sa cible : celle de la **dernière** majeure `target` prise, sinon `data.target` ; ses `extraDeltas` : les deltas de chaque évolution de `taken`, à son niveau, dans l'ordre ; ses deux descriptions : `fillTemplate(<gabarit de la langue>, <les effets propres évolués>)` — les effets d'`EffectiveCard.apply(<la CardData>, common, <ces deltas>)` —, suivi, pour chaque évolution **verbale** de `taken` dans l'ordre, de sa phrase `getDescription(niveau, langue, cost: data.cost)` ; une chiffrée n'ajoute rien (A25). **(provisoire, PN12 (a))** chaque phrase s'ajoute en `' <phrase>.'` : « Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. ». Le commentaire d'`asCard` dit qu'une signature ne coûte que du mana : `hpCost` et `armorCost` restent à 0 (point reporté).
  - `int get cost => asCard.currentCost` ; `int get cooldown => max(1, data.cooldown + Σ cooldown des évolutions de taken)` (D54).
  - `int pendingFor(int heroLevel) => max(0, heroLevel ~/ 5 - level)` (A27) ; `EvolutionTier get nextTier` — mineure si `level + 1` est impair, majeure sinon (D21).
  - Les deux commentaires « La vague 5 y appliquera les évolutions » (`:11`, `:14`) disparaissent avec les getters réécrits.

- [ ] **Step 1: Écrire les tests qui échouent**

`signature_instance_test.dart` — un `SignatureData` *Châtiment* construit en code (`cost` 1, `cooldown` 2, `singleEnemy`, `[damage 6, armor 4]`, gabarits de spec §3.7) portant `zeal`, `aegis`, `ardor` (mineures), `haste`, `sentence`, `radiance`, `devotion`, `devastation` (majeures, valeurs de spec §3.7) :
- `level et taken : la somme des niveaux, les paires dans l ordre de premiere prise` — `['zeal:2', 'sentence:1', 'aegis:1']` : `level` 4 ; `taken` `[(zeal, 2), (sentence, 1), (aegis, 1)]` ; un id hors du pool n'entre pas dans `taken`.
- `asCard : flatBonus sur les degats et l Armure` — `['zeal:2', 'aegis:1']` : `asCard.effective.effects` `[10, 6]`.
- `asCard : reduceCost baisse le cout, jamais sous 0, et cost le lit` — `['devotion:1']` : `cost` 0 ; une signature à `cost` 0 portant `devotion` : `cost` 0.
- `cooldown : la recharge et celle des majeures, jamais sous 1` — `haste` sur recharge 2 : 1 ; `haste` sur recharge 1 : 1 ; `devastation` sur recharge 2 : 3.
- `asCard : la cible est celle de la derniere majeure target prise, sinon la sienne` — sans évolution : `singleEnemy` ; `['radiance:1']` : `allEnemies`.
- `asCard : addEffect et critBonus passent par effective` — `['sentence:1', 'ardor:1']` : `addedEffects` porte `apply_status weakness` valeur 1 durée 2 ; `critChanceBonus` 5.
- `la description : le gabarit rempli des valeurs evoluees, puis les phrases verbales ; une chiffree n ajoute rien` — **(provisoire, PN12 (a))** `['zeal:2', 'sentence:1']` : FR `« Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. »`, EN `« Deal 10 damage and gain 4 Block. Apply 1 Weakness for 2 turns. »` ; `['zeal:1']` seul : le gabarit rempli, rien d'autre.
- `pendingFor : niveau du heros / 5 moins level, jamais negatif` — sans évolution : 4 → 0, 5 → 1, 12 → 2 ; `['zeal:1']` à 10 → 1 ; `['zeal:3']` à 10 → 0 (menu de debug).
- `nextTier : niveau de heros 5 -> mineure, 10 -> majeure` — `level` 0 → `minor`, 1 → `major`, 2 → `minor`, 3 → `major`.

`card_catalog_test.dart` :
- `A33 : chaque signature, toutes ses evolutions prises, tient le budget de D38` — pour chaque signature du registre, `SignatureInstance(s, evolutions: [for (final e in s.evolutions) '${e.id}:1']).asCard` : Σ `hits × mightRatio` des effets `damage` (propres et ajoutés) ≤ `currentCost + 1 + 1e-9`.

`effect_resolver_test.dart`, groupe `Q11` :
- `Projectile Magique a Braise et Mise a nu : la Brulure recoit la Puissance, la Vulnerabilite non` — `SignatureInstance(<magic_missile du registre>, evolutions: const ['ember:1', 'exposure:1']).asCard` résolue par `EffectResolver.resolveCard` (même appel que l'aide `play`) : `burn` vaut 1 + 2, `vulnerable` vaut 2.

Les quatre tests existants de `signature_instance_test.dart` restent verts tels quels (la signature sans évolution).

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_instance_test.dart test/unit/card_catalog_test.dart test/unit/effect_resolver_test.dart`
Expected: échec de compilation — le paramètre `evolutions` n'existe pas.

- [ ] **Step 3: Implémenter** — `SignatureInstance`, sans toucher `signature_bar.dart` (Task 7) ni `run_controller.dart` (Tasks 4, 5).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/combat_signature_test.dart test/widget/signature_bar_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1952** (1941 + 9 + 1 + 1).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(signatures): la vue evoluee d une signature`.

---

### Task 4: Le tirage, le choix et l'attente

**Files:**
- Create: `lib/game/systems/signature_evolution_rules.dart`, `test/unit/signature_evolution_rules_test.dart`
- Modify: `lib/game/controllers/run_controller.dart:84-101` (`RunState` : deux accesseurs), `:483-490` (à côté de `raiseRuneCap`, la méthode neuve)

**Interfaces:**
- Consumes : `SignatureInstance.taken`, `level`, `nextTier`, `pendingFor` (Task 3) ; `SignatureEvolutionData.excludesOrIsExcludedBy` (Task 2) ; `checkpointProvider` (`checkpoint_controller.dart:13-14`).
- Produces :
  - `abstract final class SignatureEvolutionRules` (`lib/game/systems/`, pur, sans Riverpod — PN14) :
    - `static const int offerSize = 3` ;
    - `static List<SignatureEvolutionData> eligibleMajors(SignatureInstance s)` — les majeures du pool ni prises, ni exclues par une majeure prise ni l'excluant (Q7) ;
    - `static List<SignatureEvolutionData> admissible(SignatureInstance s)` — au palier mineur, les mineures ; au palier majeur, les majeures éligibles, plus toutes les mineures quand il en reste moins de `offerSize` (A26, Q6) ;
    - `static List<SignatureEvolutionData> offer(SignatureInstance s, Random rng)` — sans poids, sans remise : au palier mineur, `offerSize` mineures tirées ; au palier majeur, les majeures éligibles tirées jusqu'à `offerSize`, puis des mineures tirées complètent ; moins si le pool n'en a pas assez ;
    - `static List<String> withChoice(List<String> evolutions, SignatureEvolutionData chosen)` — une mineure déjà prise monte d'un niveau **à sa place** ; toute autre entre à `'<id>:1'` à la fin.
  - `RunState.nextPendingEvolution` → `SignatureInstance?` — parmi les signatures dont `pendingFor(heroStats.level) > 0`, celle dont `level + 1` est le plus bas ; à égalité, la première dans l'ordre de `signatures` (celui de `HeroData.skills`).
  - `RunState.hasPendingChoice` → `pendingDrafts > 0 || nextPendingEvolution != null` — la condition du rideau et des deux gardes de nœud (Task 6).
  - `bool RunController.chooseSignatureEvolution(String signatureId, String evolutionId)` — refuse **sans rien écrire** si la signature n'est pas de la run, si `pendingFor(heroStats.level) == 0`, si l'évolution n'est pas de son pool, ou si elle n'est pas dans `admissible` ; sinon remplace l'instance par `SignatureInstance(data, evolutions: withChoice(...))`, puis `ref.read(checkpointProvider.notifier).bump()` — la sauvegarde suit chaque choix, comme `decrementPendingDrafts` (`player_stats_manager.dart:159-168`).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/signature_evolution_rules_test.dart` *(nouveau ; le registre réel en `setUpAll` — le pool livré de *Frappe Téméraire* pour le tirage, ses ids dans les attendus, et une `Random(seed)` ; les tests de `RunController` sur un `ProviderContainer`, une run du Paladin livré — `startNewRun(paladin, null, paladin.getSignatures(registry))` —, ou du Berserker pour l'exclusion, `heroStats.level` posé par `updateState`)* :
- `au palier mineur : trois mineures, sans remise` — `level` 0 : trois ids distincts, tous mineurs, sur vingt graines.
- `au palier majeur : les majeures non prises, trois au plus` — `['brutality:1']` : trois majeures distinctes, sur vingt graines.
- `une majeure exclue n est pas offerte, dans les deux sens` — `['brutality:1', 'haste:1', 'instinct:1']` (palier majeur) : `devastation` jamais offerte ; `['brutality:1', 'devastation:1', 'instinct:1']` : `haste` jamais offerte.
- `sous trois majeures eligibles, des mineures completent jusqu a trois` — `haste` prise, `devastation` exclue, deux majeures restent : trois rouleaux, `cleave` et `composure` toujours, plus une mineure.
- `majeures epuisees : trois mineures au palier majeur (Q6, repli)` — toutes les majeures prises ou exclues : trois mineures.
- `chooseSignatureEvolution refuse sans rien ecrire : signature hors run, rien n attend, hors du pool` — trois refus (`false`), `signatures` et `checkpointProvider` inchangés.
- `chooseSignatureEvolution refuse une evolution non admissible au palier` — Paladin, niveau 5 : `haste` (une majeure au palier mineur) ; niveau 10, `['zeal:1']` : `aegis` (une mineure, quatre majeures restant éligibles) ; Berserker, niveau 20, `['brutality:1', 'haste:1', 'instinct:1']` : `devastation` (exclue) : trois `false`, rien d'écrit.
- `une mineure deja prise monte d un niveau a sa place ; une autre entre a la fin` — niveau 15, `['zeal:1', 'sentence:1']` : choisir `zeal` donne `['zeal:2', 'sentence:1']` ; au niveau 15 avec `['zeal:1', 'haste:1']`, choisir `aegis` donne `['zeal:1', 'haste:1', 'aegis:1']`.
- `chaque choix accepte sauve : le checkpoint monte d un` — `container.read(checkpointProvider)` passe de 0 à 1.
- `nextPendingEvolution : Chatiment puis Bouclier Sacre au niveau 5 ; sur un saut de 4 a 10, les deux mineures puis les deux majeures` — niveau 5 : `smite`, puis après son choix `holy_shield`, puis `null` ; niveau 10 sans évolution : `smite`, `holy_shield` (mineures), `smite`, `holy_shield` (majeures), `null`.
- `hasPendingChoice : un draft ou une evolution en attente` — niveau 4 sans draft : faux ; `pendingDrafts` 1 : vrai ; niveau 5 sans draft : vrai.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_evolution_rules_test.dart`
Expected: échec de compilation — `SignatureEvolutionRules` n'existe pas.

- [ ] **Step 3: Implémenter** — la règle, les deux accesseurs, la méthode. `tutorial_isolation_test.dart` reste vert : le tutoriel n'importe pas ce fichier.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/save_service_test.dart test/unit/run_state_persistence_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1963** (1952 + 11).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(signatures): tirage, choix et attente des evolutions`.

---

### Task 5: La sauvegarde des évolutions — tâche à risque

**Le code s'écrit ici en entier.** Spec §8 : aucune migration, `schemaVersion` inchangé ; un seul champ neuf, `signatureEvolutions`, dans `RunState.toJson` ; la relecture en six étapes, dans l'ordre, après que les signatures sont relues de la classe. Seule l'étape 3 écrit dans le rapport.

**Files:**
- Modify: `lib/models/signature_instance.dart` (imports ; la méthode statique `restore`) ; `lib/game/controllers/run_controller.dart:78-84` (le commentaire de `signatures`), `:164-181` (`toJson`), `:234` (`fromJsonWithReport`), `:240-251` (`_signaturesOf`)
- Test: `test/unit/save_service_test.dart` (groupe neuf, dans `group('SaveService', …)`, après le dernier test)

**Interfaces:**
- Consumes : `SignatureInstance(data, {evolutions})` (Task 3) ; `SignatureEvolutionData`, `EvolutionTier`, `excludesOrIsExcludedBy`, `SignatureData.evolutions` (Task 2) ; `ForgeUpgradeData.parseRef`, `levelsOf` (`forge_upgrade_data.dart:413-432`) ; `MissingSaveItem` (`missing_save_item.dart`).
- Produces : `static (SignatureInstance, List<MissingSaveItem>) SignatureInstance.restore(SignatureData data, Object? raw)` ; `RunState.toJson()['signatureEvolutions']` (`Map<String, List<String>>`, toujours écrit, vide s'il n'y a rien — PN6).

- [ ] **Step 1: Écrire les tests qui échouent — `test/unit/save_service_test.dart`**

Imports à ajouter en tête :

```dart
import 'package:roguelike_card_game/models/data/signature_evolution_data.dart';
import 'package:roguelike_card_game/models/missing_save_item.dart';
import 'package:roguelike_card_game/models/signature_instance.dart';
```

Le groupe, à la fin du `group('SaveService', …)`, après `load migrates a legacy v1 save stored under run_save_v1` :

```dart
    // Les evolutions de signature, sauvegardees sous `signatureEvolutions`
    // (spec P-42 T1 et P-44 lot 1, §8 — tache a risque).
    group('les evolutions de signature (spec §8)', () {
      const zeal = SignatureEvolutionData(id: 'zeal', tier: EvolutionTier.minor);
      const aegis =
          SignatureEvolutionData(id: 'aegis', tier: EvolutionTier.minor);
      const sentence =
          SignatureEvolutionData(id: 'sentence', tier: EvolutionTier.major);
      // Seule `haste` declare l exclusion : la relecture la lit dans les deux
      // sens (Q7).
      const haste = SignatureEvolutionData(
        id: 'haste',
        tier: EvolutionTier.major,
        cooldown: -1,
        excludes: ['devastation'],
      );
      const devastation = SignatureEvolutionData(
        id: 'devastation',
        tier: EvolutionTier.major,
        cooldown: 1,
      );
      const ward = SignatureEvolutionData(id: 'ward', tier: EvolutionTier.minor);
      const evolvingSmite = SignatureData(
        id: 'smite',
        heroClass: 'paladin',
        cost: 1,
        cooldown: 2,
        type: CardType.attack,
        effects: [CardEffect(type: 'damage', value: 6)],
        evolutions: [zeal, aegis, sentence, haste, devastation],
      );
      const evolvingShield = SignatureData(
        id: 'holy_shield',
        heroClass: 'paladin',
        cost: 1,
        cooldown: 2,
        type: CardType.skill,
        target: CardTarget.self,
        effects: [CardEffect(type: 'armor', value: 8)],
        evolutions: [ward],
      );
      const paladin = HeroData(
        id: 'paladin',
        classCard: 'paladin.png',
        maxHp: 100,
        maxMana: 3,
        skills: ['smite', 'holy_shield'],
      );

      setUp(() {
        GameDataRegistry(
          enemies: const [],
          heroes: const [paladin],
          cards: const [],
          events: const [],
          passives: const [],
          relics: const [],
          forgeUpgrades: const [],
          signatures: const [evolvingSmite, evolvingShield],
        );
      });

      /// Une run du Paladin dont chaque signature porte [evolutions], sauvee.
      Future<void> saveRun(Map<String, List<String>> evolutions) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final run = container.read(runProvider.notifier);
        run.startNewRun(paladin, null, const [evolvingSmite, evolvingShield]);
        run.updateState(run.currentState.copyWith(signatures: [
          for (final s in run.currentState.signatures)
            SignatureInstance(
              s.data,
              evolutions: evolutions[s.data.id] ?? const [],
            ),
        ]));
        await SaveService.save(container.read);
      }

      /// La run telle que la sauvegarde l ecrit.
      Future<Map<String, dynamic>> savedRun() async {
        final prefs = await SharedPreferences.getInstance();
        final payload =
            jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
        return payload['run'] as Map<String, dynamic>;
      }

      /// Remplace `signatureEvolutions` dans la sauvegarde ; nul, la retire.
      Future<void> rewrite(Object? value) async {
        final prefs = await SharedPreferences.getInstance();
        final payload =
            jsonDecode(prefs.getString('run_save')!) as Map<String, dynamic>;
        final run = payload['run'] as Map<String, dynamic>;
        if (value == null) {
          run.remove('signatureEvolutions');
        } else {
          run['signatureEvolutions'] = value;
        }
        await prefs.setString('run_save', jsonEncode(payload));
      }

      /// La reprise : le resultat, et les evolutions de chaque signature, dans
      /// l ordre de la classe.
      Future<(SaveLoadResult, List<List<String>>)> reload() async {
        final fresh = ProviderContainer();
        addTearDown(fresh.dispose);
        final result = await SaveService.load(fresh.read);
        return (
          result,
          [for (final s in fresh.read(runProvider).signatures) s.evolutions],
        );
      }

      test('aller-retour exact : chaque liste telle quelle, dans l ordre de '
          'la premiere prise', () async {
        await saveRun({
          'smite': ['zeal:2', 'sentence:1', 'aegis:1'],
          'holy_shield': ['ward:1'],
        });
        expect((await savedRun())['signatureEvolutions'], {
          'smite': ['zeal:2', 'sentence:1', 'aegis:1'],
          'holy_shield': ['ward:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions, [
          ['zeal:2', 'sentence:1', 'aegis:1'],
          ['ward:1'],
        ]);
      });

      test('une signature sans evolution n ecrit aucune cle', () async {
        await saveRun({
          'smite': ['zeal:1'],
        });
        expect((await savedRun())['signatureEvolutions'], {
          'smite': ['zeal:1'],
        });

        final (_, evolutions) = await reload();
        expect(evolutions, [
          ['zeal:1'],
          <String>[],
        ]);
      });

      test('une sauvegarde sans la cle, ou d une autre forme, reprend sans '
          'evolution', () async {
        for (final value in <Object?>[
          null,
          'smite',
          ['zeal:1'],
          {'smite': 'zeal:1'},
        ]) {
          await saveRun({
            'smite': ['zeal:1'],
          });
          await rewrite(value);

          final (result, evolutions) = await reload();
          expect(result.success, isTrue, reason: '$value');
          expect(result.missingItems, isEmpty, reason: '$value');
          expect(evolutions, [<String>[], <String>[]], reason: '$value');
        }
      });

      test('un id absent du pool est retire et signale, une fois', () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1', 'ghost:1', 'ghost:2'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(evolutions.first, ['zeal:1']);
        expect(result.missingItems, const [
          MissingSaveItem(
            id: 'ghost',
            nameFr: 'ghost',
            nameEn: 'ghost',
            category: 'signatureEvolution',
          ),
        ]);
      });

      test('une reference mal formee ou de niveau nul est ignoree, sans '
          'rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': [
            'zeal',
            'zeal:x',
            'zeal:0',
            'zeal:-1',
            'zeal:1:2',
            3,
            null,
            'aegis:1',
          ],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['aegis:1']);
      });

      test('les references d un meme id se reunissent a la place de la '
          'premiere, niveaux additionnes', () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1', 'aegis:1', 'zeal:2'],
        });

        final (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['zeal:3', 'aegis:1']);
      });

      test('une majeure est ramenee au niveau 1, sans rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': ['sentence:2', 'zeal:1', 'sentence:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['sentence:1', 'zeal:1']);
      });

      test('deux majeures qui s excluent : la premiere arrivee est gardee, '
          'dans un sens comme dans l autre, sans rapport', () async {
        await saveRun({});
        await rewrite({
          'smite': ['haste:1', 'zeal:1', 'devastation:1'],
        });
        var (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['haste:1', 'zeal:1']);

        // `devastation` ne declare rien : c est l exclusion de `haste` qui
        // l ecarte, lue dans l autre sens.
        await rewrite({
          'smite': ['devastation:1', 'haste:1'],
        });
        (result, evolutions) = await reload();
        expect(result.missingItems, isEmpty);
        expect(evolutions.first, ['devastation:1']);
      });

      test('la cle d une signature que la classe ne porte pas est ignoree',
          () async {
        await saveRun({});
        await rewrite({
          'smite': ['zeal:1'],
          'reckless_strike': ['brutality:1'],
        });

        final (result, evolutions) = await reload();
        expect(result.success, isTrue);
        expect(result.missingItems, isEmpty);
        expect(evolutions, [
          ['zeal:1'],
          <String>[],
        ]);
      });
    });
```

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/save_service_test.dart`
Expected: huit des neuf tests du groupe échouent — `signatureEvolutions` n'est pas écrit (`savedRun()['signatureEvolutions']` vaut `null`), et la reprise rend des signatures sans évolution ; « une sauvegarde sans la cle, ou d une autre forme, reprend sans evolution » passe déjà : c'est le comportement d'une sauvegarde de `0.5.6`, que le test garde au-delà de la tâche. Les tests existants du fichier restent verts.

- [ ] **Step 3: La relecture — `lib/models/signature_instance.dart`**

Import à ajouter (les deux autres, `data/forge_upgrade_data.dart` et `data/signature_evolution_data.dart`, sont posés par la Task 3) :

```dart
import 'missing_save_item.dart';
```

Dans la classe, après `nextTier` :

```dart
  /// Relit les évolutions sauvegardées de [data] (spec P-42 T1 et P-44 lot 1,
  /// §8) : [raw] est la valeur de sa clé dans `signatureEvolutions`. Seul un
  /// id absent du pool entre au rapport ; une référence mal formée, une
  /// majeure au-delà du niveau 1 ou une majeure exclue par une majeure gardée
  /// avant elle sont corrigées sans rapport — elles ne naissent que d'une
  /// sauvegarde écrite à la main, et le rapport dit au joueur qu'un élément a
  /// disparu d'une mise à jour.
  static (SignatureInstance, List<MissingSaveItem>) restore(
    SignatureData data,
    Object? raw,
  ) {
    final missing = <MissingSaveItem>[];
    // 1. Absente, ou d'une autre forme qu'une liste : aucune évolution.
    if (raw is! List) return (SignatureInstance(data), missing);

    final pool = {
      for (final evolution in data.evolutions) evolution.id: evolution,
    };
    final known = <String>[];
    final reported = <String>{};
    for (final entry in raw) {
      // 2. Mal formée ou de niveau nul : ignorée, sans rapport.
      if (entry is! String) continue;
      final parsed = ForgeUpgradeData.parseRef(entry);
      if (parsed == null) continue;
      final (id, _) = parsed;
      // 3. Absente du pool : retirée, et signalée une fois.
      if (!pool.containsKey(id)) {
        if (reported.add(id)) {
          missing.add(MissingSaveItem(
            id: id,
            nameFr: id,
            nameEn: id,
            category: 'signatureEvolution',
          ));
        }
        continue;
      }
      known.add(entry);
    }

    final keptMajors = <SignatureEvolutionData>[];
    final evolutions = <String>[];
    // 4. Les références d'un même id réunies, niveaux additionnés, dans
    // l'ordre de leur première apparition.
    for (final MapEntry(key: id, value: level)
        in ForgeUpgradeData.levelsOf(known).entries) {
      final evolution = pool[id]!;
      if (evolution.tier == EvolutionTier.minor) {
        evolutions.add('$id:$level');
        continue;
      }
      // 5. Une majeure exclue par une majeure gardée avant elle, dans un
      // sens ou dans l'autre, est retirée : la première arrivée est gardée,
      // comme `ForgeRuneRules.consolidate`.
      if (keptMajors.any(evolution.excludesOrIsExcludedBy)) continue;
      keptMajors.add(evolution);
      // 4, suite. Une majeure ne se prend qu'une fois : ramenée au niveau 1.
      evolutions.add('$id:1');
    }

    // 6. La signature reconstruite, dans l'ordre lu.
    return (SignatureInstance(data, evolutions: evolutions), missing);
  }
```

- [ ] **Step 4: L'écriture et la lecture — `lib/game/controllers/run_controller.dart`**

Le commentaire du champ `signatures` (`:78-84`) devient :

```dart
  /// Les signatures de la run (spec P-43 E4, §9 ; A8), dans l'ordre de
  /// `HeroData.skills`. Hors du deck : le `masterDeck` n'en porte jamais.
  ///
  /// **Leur donnée n'est jamais sérialisée**, comme [statRules] :
  /// `fromJsonWithReport` la relit de la classe. Seules leurs évolutions le
  /// sont, sous `signatureEvolutions` (spec P-42 T1 et P-44 lot 1, §8).
  final List<SignatureInstance> signatures;
```

Dans `toJson`, après `'runeCapBonus': runeCapBonus,` :

```dart
        // Une clé par signature qui porte au moins une évolution, sa liste
        // telle quelle, dans l'ordre de la première prise (spec §8).
        'signatureEvolutions': {
          for (final signature in signatures)
            if (signature.evolutions.isNotEmpty)
              signature.data.id: signature.evolutions,
        },
```

Dans `fromJsonWithReport`, la ligne `signatures: _signaturesOf(json['heroClassId'] as String),` devient :

```dart
      signatures: _signaturesOf(
        json['heroClassId'] as String,
        json['signatureEvolutions'],
        missing,
      ),
```

`_signaturesOf` devient :

```dart
  /// Les signatures de la classe [heroClassId], relues du registre chargé,
  /// chacune avec ses évolutions relues de [saved] — la valeur de
  /// `signatureEvolutions` (spec §8) ; ce que la relecture retire rejoint
  /// [missing]. Une clé d'une signature que la classe ne porte pas n'est
  /// jamais lue. Registre absent ou classe inconnue : aucune, comme
  /// `statRules`. Un id de `skills` absent du registre lève
  /// (`getSignatures`, fail-fast) : la sauvegarde est alors illisible, et
  /// `SaveService.load` l'efface.
  static List<SignatureInstance> _signaturesOf(
    String heroClassId,
    Object? saved,
    List<MissingSaveItem> missing,
  ) {
    final hero = HeroData.getById(heroClassId);
    if (hero == null) return const [];
    final byId =
        saved is Map<String, dynamic> ? saved : const <String, dynamic>{};
    final signatures = <SignatureInstance>[];
    for (final data in hero.getSignatures(GameDataRegistry.instance!)) {
      final (signature, lost) = SignatureInstance.restore(data, byId[data.id]);
      signatures.add(signature);
      missing.addAll(lost);
    }
    return signatures;
  }
```

- [ ] **Step 5: Lancer les tests, constater le succès ; vérifier la tâche**

Run: `flutter test test/unit/save_service_test.dart test/unit/run_state_persistence_test.dart test/unit/checkpoint_autosave_test.dart` → tout passe (le test d'E4 « rien d ecrit » reste vert : aucune signature n'y porte d'évolution, la carte reste vide et ne nomme pas `holy_shield`).
Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1972** (1963 + 9).

- [ ] **Step 6: Commit**

`git add lib/models/signature_instance.dart lib/game/controllers/run_controller.dart test/unit/save_service_test.dart`, puis `git commit` — `feat(sauvegarde): les evolutions de signature survivent a la reprise`.

---

### Task 6 (interface): L'écran d'évolution, ses icônes et le rideau

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 7. Ce que le joueur voit : au niveau 5 du héros, le rideau de la carte s'affiche ; le toucher ouvre le draft de niveau, puis, rideau toujours là, l'évolution de Châtiment, puis celle de Bouclier Sacré.

**Files:**
- Create: `lib/ui/widgets/signature_evolution_style.dart`, `lib/ui/screens/signature_evolution_screen.dart`, `test/widget/signature_evolution_screen_test.dart`
- Modify: `lib/ui/widgets/relic_carousel/draft_card_reel.dart:11-37` (paramètre), `:294-301` (le rouleau posé) ; `lib/ui/widgets/draft/draft_choice_card.dart:3-19` (paramètre), `:130-131` (l'emplacement de l'emoji) ; `lib/ui/screens/map_screen.dart:301-316` (le rideau), `:380`, `:403` (les gardes) ; `lib/l10n/app_fr.arb:280`, `lib/l10n/app_en.arb:766-770` (après `signatureTurnsLeft`)
- Test: `test/widget/draft_card_reel_test.dart`, `test/widget/map_screen_test.dart`, `test/unit/referential_integrity_test.dart` (après `:90-101`, le test des icônes de rune)

**Interfaces:**
- Consumes : `SignatureEvolutionRules.offer`, `RunController.chooseSignatureEvolution`, `RunState.nextPendingEvolution`, `hasPendingChoice` (Task 4) ; `SignatureEvolutionData.getDescription`, `getName`, `tier`, `icon`, `color` (Task 2) ; `SignatureInstance.taken` (Task 3).
- Produces :
  - `signature_evolution_style.dart` (A35) : `const Map<String, IconData> evolutionIcons` — les quinze de spec §3.7 (`gavel_rounded`, `shield_rounded`, `favorite_rounded`, `gps_fixed_rounded`, `fitness_center_rounded`, `trending_up_rounded`, `autorenew_rounded`, `arrow_downward_rounded`, `heart_broken_rounded`, `local_fire_department_rounded`, `style_rounded`, `fast_forward_rounded`, `bolt_rounded`, `all_out_rounded`, `savings_rounded`) vers les `Icons.…` du même nom ; `const Map<String, Color> evolutionColors` — les quatorze (`redAccent`, `blueAccent`, `greenAccent`, `amber`, `orangeAccent`, `lightBlueAccent`, `purpleAccent`, `pinkAccent`, `deepOrangeAccent`, `amberAccent`, `tealAccent`, `yellowAccent`, `deepPurpleAccent`, `cyanAccent`) ; un nom inconnu retombe sur `Icons.help_outline` et `Colors.grey`, comme une rune (`forge/rune_style.dart`).
  - `class EvolutionIcon extends StatelessWidget` — `const EvolutionIcon({super.key, required SignatureEvolutionData evolution, required double size, int level = 1, Color? color})` : la puce entière, anneau compris, mesure `size` ; une **majeure** dans un anneau de sa couleur (`ValueKey('evolution-ring-<id>')`), une mineure nue ; dès `level ≥ 2`, une mineure porte son niveau en petit chiffre en bas à droite ; `color`, s'il est donné, remplace la couleur de l'évolution partout (icône, anneau, chiffre) — le gris de la tuile grisée (Task 7). La puce porte `ValueKey('evolution-icon-<id>')`. Ni toucher ni survol. Le seul dessin d'une icône d'évolution, lu par l'écran et par la tuile (PN7).
  - `DraftChoiceCard` et `DraftCardReel` gagnent `final Widget? icon` (facultatif, défaut nul) : `DraftCardReel` ne le passe qu'au `DraftChoiceCard` du rouleau **posé** (`:294-301`), jamais aux cartes qui défilent ; `DraftChoiceCard` le dessine à la place de l'emoji (`:131`), au-dessus du titre ; nul, l'emoji d'aujourd'hui (PN7). Le draft de niveau et le tutoriel (`tutorial_draft_widget.dart:130`) ne le passent pas : rien n'y change.
  - `class SignatureEvolutionScreen extends ConsumerStatefulWidget` — `const SignatureEvolutionScreen({super.key, required SignatureInstance signature, required VoidCallback onComplete})`. Le tirage (`SignatureEvolutionRules.offer(signature, Random())`) se fait dans `initState`, rien n'est retenu entre deux ouvertures. Mise en page, survol (1,05), sélection (1,12, halo ambre), cadence et sons du `DraftScreen` (`draft_screen.dart:171-404`), recopiés dans l'écran sans toucher `DraftScreen` (PN8) ; la musique `MusicScene.map` ; le son de pose `reelLand` à la variante `common` (PN9). Spec §5.1, mot pour mot :
    - en-tête : `evolutionScreenTitle(<nom de la signature dans la langue>)`, puis `evolutionScreenSubtitle` ;
    - un `DraftCardReel` par évolution tirée : `title` son nom ; `description` sa description à son **prochain** niveau (`getDescription(<niveau pris> + 1, langue, cost: signature.data.cost)`), et, pour une mineure déjà prise, une dernière ligne `'\n${evolutionLevelUp(n, n + 1)}'` ; `rarity` : `evolutionTierMinor` ou `evolutionTierMajor` ; `icon` : `EvolutionIcon(evolution: e, size: 44)` (P-4) ; `spinPool` : les évolutions du pool, nom et description au niveau 1 (PN9) ;
    - toucher un rouleau posé : `chooseSignatureEvolution(signature.data.id, e.id)`, puis `onComplete()` — même si le choix est refusé, le rideau rouvre ce qui reste (PN16).
  - ARB, textes de spec §6.1 **mot pour mot** : `evolutionScreenTitle` (`signature` String) « Évolution de {signature} » / « {signature} evolves » ; `evolutionScreenSubtitle` « Choisissez une évolution » / « Choose an evolution » ; `evolutionTierMinor` « MINEURE » / « MINOR » ; `evolutionTierMajor` « MAJEURE » / « MAJOR » ; `evolutionLevelUp` (`from`, `to` int) « Niveau {from} → {to} » / « Level {from} → {to} ».
  - `MapScreen` : le rideau (`LevelUpOverlay`, `:302`) s'affiche si `runState.hasPendingChoice` ; le toucher pousse `DraftScreen` si `pendingDrafts > 0` (inchangé), sinon `SignatureEvolutionScreen(signature: runState.nextPendingEvolution!, onComplete: () => Navigator.of(context).pop())`. Les deux gardes de nœud (`:380` dans `_isNodeAvailable`, `:403` dans `_onNodeTap`), qui lisent aujourd'hui `pendingDrafts > 0`, lisent `hasPendingChoice` : un draft de niveau **ou** une évolution en attente ferme les nœuds.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/widget/signature_evolution_screen_test.dart` *(nouveau ; registre réel en `setUpAll` ; la run du Paladin au niveau du héros voulu ; les rouleaux posés après `tester.pump(const Duration(seconds: 4))`)* :
- `l en-tete nomme la signature, puis invite a choisir` — FR : `'Évolution de Châtiment'`, `'Choisissez une évolution'` ; EN : `'Smite evolves'`.
- `au palier mineur, trois rouleaux : chacun son nom, sa description et MINEURE` — niveau 5 : `'Zèle'`, `'Égide'`, `'Ardeur'`, `'+2 dégâts'`, trois `'MINEURE'`.
- `au palier majeur, les rouleaux disent MAJEURE` — niveau 10, `['zeal:1']` : trois `'MAJEURE'`, chaque titre celui d'une majeure de *Châtiment*.
- `une mineure deja prise montre sa description au prochain niveau et Niveau 1 -> 2` — niveau 15, `['zeal:1', 'haste:1']` : `find.textContaining('+4 dégâts')` et `find.textContaining('Niveau 1 → 2')` sur le rouleau de *Zèle*.
- `l icone de chaque evolution parait a sa couleur une fois le rouleau arrete ; une majeure dans son anneau` — avant la pose : `find.byKey(ValueKey('evolution-icon-zeal'))` rien ; après : trouvée, son `Icon` à `Icons.gavel_rounded` et `Colors.redAccent` ; au palier majeur, `evolution-ring-<id>` pour chaque rouleau.
- `toucher un rouleau pose choisit l evolution et rend la main` — niveau 5 : toucher *Zèle* ; `onComplete` appelé une fois ; `runProvider.signatures.first.evolutions` vaut `['zeal:1']`.

`draft_card_reel_test.dart` :
- `icon est facultatif : absent, l emoji d aujourd hui ; pose, il parait une fois le rouleau arrete` — sans `icon` : `find.text('✨')` sur le rouleau posé ; avec `icon: const Icon(Icons.star, key: ValueKey('reel-icon'))` : rien pendant la rotation, trouvé une fois posé, et plus de `'✨'`.

`map_screen_test.dart` :
- `le rideau s affiche tant qu une evolution attend, sans draft de niveau` — run à deux signatures construites, `pendingDrafts` 0 : niveau 4, `find.byType(LevelUpOverlay)` rien ; niveau 5, trouvé.
- `toucher le rideau ouvre l evolution de nextPendingEvolution quand aucun draft n attend` — niveau 5 : `find.byType(SignatureEvolutionScreen)` et le titre `evolutionScreenTitle` de la première signature.
- `toucher le rideau ouvre le draft de niveau d abord` — niveau 5, `pendingDrafts` 1 (le registre de test, `gameDataLoaderProvider` surchargé par `mockGameDataLoaderProvider`) : `find.byType(DraftScreen)`, pas d'écran d'évolution.
- `les noeuds restent fermes tant qu une evolution attend` — niveau 5, deux signatures construites, `pendingDrafts` 0, sur le `MapNodeWidget` d'un nœud `node_0_*` — `find.byWidgetPredicate((w) => w is MapNodeWidget && w.node.id.startsWith('node_0_'))`, les nœuds n'ayant pas de `Key` — (aucun toucher : le rideau, `Positioned.fill` opaque, le recevrait, et `MapNodeWidget` n'appelle `onTap` que si `isAvailable`, `map_node_widget.dart:139`) : (a) son `isAvailable` est faux — la garde de `_isNodeAvailable` (`map_screen.dart:380`) ; (b) `tester.widget<MapNodeWidget>(…).onTap()`, appelé directement, laisse `container.read(runProvider).currentNodeId` nul — la garde de `_onNodeTap` (`:403`), l'appel contournant `isAvailable` et le rideau.

`referential_integrity_test.dart` (le registre réel du fichier) :
- `chaque icone et chaque couleur d evolution livree est connue des tables` — sur le modèle du test des runes (`:90-101`).
- `deux evolutions d une meme signature de meme icone ne sont jamais deux mineures ni deux majeures (A37)`.
- `chaque entree d evolutionIcons et d evolutionColors sert au moins une evolution livree`.
- `chaque effet qu ajoute une evolution a sa strategie, et chaque statut qu elle pose est fabrique par createStatus` — les `AddEffectDelta` et `FlatBonusDelta` des pools : `strategies.get(effect)` non nul ; `createStatus(statusId, 1, 1)` non nul.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/signature_evolution_screen_test.dart test/widget/draft_card_reel_test.dart test/widget/map_screen_test.dart test/unit/referential_integrity_test.dart`
Expected: échec de compilation — `SignatureEvolutionScreen`, `evolutionIcons`, le paramètre `icon` n'existent pas.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n` ; les tables et `EvolutionIcon` ; le paramètre des deux widgets du carrousel ; l'écran ; le rideau.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/widget/draft_screen_test.dart test/widget/boss_card_draft_screen_test.dart test/tutorial/`.
Expected: tout passe (le draft de niveau, celui du boss et le tutoriel, qui lit `DraftChoiceCard`, inchangés).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1987** (1972 + 6 + 1 + 4 + 4).

- [ ] **Step 6: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(evolutions): l ecran a trois rouleaux et le rideau de la carte`.

---

### Task 7 (interface): La tuile de combat — valeurs évoluées, badge, icônes, bande

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 8. Ce que le joueur voit : la tuile dit le coût, la cible et la description évolués, sans borne de lignes ; le badge « Niv. n » au bout de la ligne du type ; une rangée d'icônes sous la description ; la colonne reste à mi-hauteur tant qu'elle tient dans sa bande.

**Files:**
- Modify: `lib/ui/widgets/hud/signature_bar.dart:1-439` ; `lib/ui/widgets/hud/combat_side_panels.dart:10-23` (deux constantes), `:71-75` (`bottom: statusPanelBottom`) ; `lib/ui/widgets/hud/combat_top_bar.dart:7` (une constante) ; `lib/ui/screens/game_screen.dart:637-660` (`heroStats` au lieu de `currentMana`) ; `lib/l10n/app_fr.arb:176`, `lib/l10n/app_en.arb:446-451` (`levelLabel`)
- Test: `test/widget/signature_bar_test.dart`, `test/widget/signature_tile_test.dart`

**Interfaces:**
- Consumes : `SignatureInstance.asCard`, `cost`, `level`, `taken` (Task 3) ; `EvolutionIcon` (Task 6) ; `EffectResolver.canAfford` (`effect_resolver.dart:113-118`).
- Produces :
  - `static const double CombatSidePanels.statusPanelBottom = 80`, `static const double CombatSidePanels.statusPanelReserve = 120` ; `static const double CombatTopBar.bandTop = 80` (A38).
  - `({double scale, double top}) signatureBandPlacement({required double available, required double natural})` (top-level, `signature_bar.dart`) — l'algorithme d'A38, imposé ligne à ligne :

    ```dart
    ({double scale, double top}) signatureBandPlacement({
      required double available,
      required double natural,
    }) {
      const bandTop = CombatTopBar.bandTop;
      const bandBottom = CombatSidePanels.statusPanelBottom +
          CombatSidePanels.statusPanelReserve;
      final band = available - bandTop - bandBottom;
      // 1. L'échelle : 1 tant que la colonne tient, 0,75 au plus bas.
      final scale = (band / natural).clamp(0.75, 1.0);
      // 2. La hauteur posée.
      final placed = scale * natural;
      // 3. À mi-hauteur ; décalée vers le haut si elle sortirait de la bande
      // par le bas ; jamais au-dessus de bandTop.
      final top = max(
        bandTop,
        min(available / 2 - placed / 2, available - bandBottom - placed),
      );
      return (scale: scale, top: top);
    }
    ```

  - `SignatureBar` : `final EntityStats heroStats` **remplace** `currentMana` ; `affordable: EffectResolver.canAfford(signature.asCard, heroStats)` (A10, point reporté de `:114`). La colonne n'est plus posée par `Align` : un `Flow` (PN10) de délégué privé, `clipBehavior: Clip.none`, enfant unique (la colonne et son invite pendante, inchangées) contraint en largeur seulement, peint à `Matrix4.translationValues(20, top, 0)..scale(scale, scale, 1)` où `(scale, top) = signatureBandPlacement(available: <hauteur du Flow>, natural: <hauteur de l'enfant>)` ; `H` est la hauteur que le `Positioned.fill` donne, jamais `MediaQuery`. `Flow` porte le toucher à travers la transformation : une tuile réduite répond.
  - `_SignatureTile` lit la signature évoluée : le médaillon `signature.cost` ; le toucher d'une tuile disponible arme si `signature.asCard.data.target == CardTarget.singleEnemy`, joue sinon ; la description `signature.asCard.data.getDescription(locale)`, **sans** `maxLines` ni ellipse (spec §5.2).
  - Le badge (A36) : au bout de la ligne du type (`:257-266`, le type passe dans un `Flexible`), `levelLabel(signature.level)`, absent au niveau 0 ; même taille que le type, gras ; **(provisoire, PN13 (a))** blanc, comme le nom ; `Colors.white38` en recharge et sans le mana.
  - La rangée (A37) : sous la description, au-dessus du compte de recharge, dès la première évolution — un `Row` de `EvolutionIcon` par paire de `taken`, dans l'ordre, `size` 16 sur la tuile étroite, 18 sur la large, 2 d'écart ; `level` de la paire ; `color: Colors.white38` en recharge et sans le mana, nulle sinon. Inactive : toute la tuile à 0,45, comme aujourd'hui.
  - ARB : `levelLabel` réécrite, « Niv. {level} » / « Lvl. {level} » (spec §6.1).
  - `game_screen.dart` passe `heroStats: runState.heroStats`.

- [ ] **Step 1: Écrire les tests qui échouent**

`signature_bar_test.dart` — `_harness` reçoit `EntityStats heroStats` (mana 3 par défaut) au lieu de `currentMana` ; les tests qui passaient `currentMana: 0` passent un `heroStats` à 0 de mana (réécrits, même compte). Une *Châtiment* construite portant les sept évolutions de son pool (icônes et couleurs de spec §3.7) :
- `le badge : absent au niveau 0, Niv. 3 au niveau 3, sur la ligne du type` — FR, `['zeal:2', 'sentence:1']` : `find.text('Niv. 3')` trouvé, sur la même ligne (même `dy` au pixel près) que le libellé du type ; sans évolution : `find.textContaining('Niv.')` rien ; EN : `'Lvl. 3'`.
- `une puce par evolution distincte, dans l ordre de premiere prise` — `['sentence:1', 'zeal:2', 'aegis:1']` : trois `evolution-icon-…`, abscisses croissantes dans cet ordre.
- `une majeure dans un anneau, une mineure nue ; le niveau d une mineure des 2` — `evolution-ring-sentence` trouvé, `evolution-ring-zeal` rien ; le texte `'2'` sous la puce de *Zèle* ; aucun chiffre sous *Égide* (niveau 1).
- `sept puces tiennent sans debordement a 170 et a 220 de large` — les sept évolutions, largeurs d'écran 400 puis 1280 : `tester.takeException()` nul ; le bord droit de la dernière puce ≤ le bord droit de la tuile.
- `en recharge et sans le mana, puces, anneaux, chiffres et badge passent au gris pale` — `['zeal:2', 'sentence:1']`, dans les deux états : chaque `Icon` des puces, le texte du badge, le `Text` `'2'` descendant de `evolution-icon-zeal` (`find.descendant`) et la bordure de `evolution-ring-sentence` à `Colors.white38` ; disponible, la puce de *Zèle* à `Colors.redAccent`.
- `la tuile lit la signature evoluee : cout, cible, description sans borne` — `['devotion:1', 'radiance:1']` : le médaillon `'0'` ; toucher la tuile disponible appelle `onPlay`, pas `onArm` ; `['sentence:1']` : la phrase « Apply 1 Weakness for 2 turns. » **(provisoire, PN12 (a))** visible en entier, le `Text` de la description sans `maxLines`.
- `l accessibilite lit EffectResolver.canAfford : le cout evolue` — mana 0 : sans évolution, état « sans le mana » ; `['devotion:1']`, disponible.
- `signatureBandPlacement : centree, decalee, reduite, plancher` — `(800, 176)` → `(1, 312)` ; `(800, 500)` → `(1, 100)` ; `(800, 600)` → `scale` `closeTo(520 / 600, 1e-9)`, `top` 80 ; `(400, 176)` → `(0.75, 80)`, et `80 + 0.75 × 176 > 400 − 200`.
- `au niveau 0 en 1280 x 800, la colonne est a mi-hauteur, comme en 0.5.6` — vue `1280 × 800`, `devicePixelRatio` 1, deux tuiles : `(haut de smite − 4 + bas de holy_shield + 4) / 2` vaut `closeTo(400, 0.5)` (`tester.getRect`).
- `a H = 400, la colonne est a l echelle 0,75, sous bandTop, sortie par le bas, et une tuile reduite arme encore` — vue `1280 × 400` : `getRect(smite).width` `closeTo(165, 0.5)`, `top ≥ 80` ; toucher *Châtiment* appelle `onArm` ; avec `armedId: 'smite'`, l'invite `signatureChooseTarget` est trouvée.

`signature_tile_test.dart` :
- `hors combat, ni badge ni puce` — la tuile d'une `SignatureData` à évolutions : `find.textContaining('Niv.')` rien, `find.byType(EvolutionIcon)` rien.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/signature_bar_test.dart test/widget/signature_tile_test.dart`
Expected: échec de compilation — `heroStats`, `signatureBandPlacement` n'existent pas.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n` ; les constantes ; la fonction de placement et le `Flow` ; la tuile ; `game_screen.dart`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/widget/debug_drawer_test.dart test/unit/combat_signature_test.dart` (le premier monte `GameScreen`, qui passe désormais `heroStats` à la barre).
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1998** (1987 + 10 + 1). `git grep -n "currentMana >= signature.cost" -- lib` ne rend rien.

- [ ] **Step 6: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(combat): la tuile de signature evoluee, son badge et ses icones`.

---

### Task 8: L'éditeur de contenu — le descripteur des évolutions

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart:298-329` (le descripteur de la signature)
- Test: `test/unit/content_editor/entity_descriptor_test.dart` (`:130-138`, `:437`), `test/unit/content_editor/entity_validator_test.dart` (groupe `une signature (spec P-43 E4, §8)`, `:96`)

**Interfaces:**
- Consumes : `EvolutionTier`, `SignatureEvolutionData.targetNames`, `deltaTypeNames` (Task 2) ; le gabarit à évolution (Task 2).
- Produces (spec §7, la ligne marquée 3) :
  - `requiredKeys` : `{'cost', 'cooldown', 'type', 'evolutions'}` (PN15 : la famille 3 nomme l'absence avant `construct`).
  - `enumKeys` gagne `'evolutions[].tier': _names(EvolutionTier.values)`, `'evolutions[].target': SignatureEvolutionData.targetNames`, `'evolutions[].deltas[].type': SignatureEvolutionData.deltaTypeNames` — lus sur le modèle, jamais recopiés.
  - `vocabularyKeys` gagne `'evolutions[].icon'` et `'evolutions[].color'` — admis si un fichier livré ou le gabarit les emploie déjà, la forme d'`icon` et `color` des runes (`:437-455`), sans lire les tables de `lib/ui/`. Le commentaire le dit, et que le test d'intégrité (Task 6) exige que chaque évolution livrée ait les siens.

- [ ] **Step 1: Écrire les tests qui échouent**

`entity_descriptor_test.dart` :
- `la signature connait ses evolutions : tier, target et deltas[].type lus sur le modele` — les trois `enumKeys` valent `_names(EvolutionTier.values)`, `SignatureEvolutionData.targetNames`, `SignatureEvolutionData.deltaTypeNames`.
- `evolutions[].icon et evolutions[].color sont des cles de vocabulaire, comme celles d une rune` — `vocabularyKeys` de la signature les contient.
- Réécrits, même compte : « la signature exige cost, cooldown et type… » (`entity_descriptor_test.dart:130`), qui rougit dès qu'`evolutions` entre dans `requiredKeys`, attend aussi `evolutions` ; le test des vocabulaires (`:437`) gagne les deux clés.

`entity_validator_test.dart`, groupe de la signature :
- `une evolution au tier inconnu est refusee par les enumerations` — le gabarit, `evolutions[0].tier` à `'legendary'` : une faute au champ `evolutions[0].tier`.
- `une icone d evolution qu aucun fichier n emploie est refusee` — `evolutions[0].icon` à `'rocket_rounded'`, avec le bac à sable : une faute de vocabulaire au champ `evolutions[0].icon`.
- `une signature sans evolutions est refusee, la cle nommee` — le gabarit sans `evolutions` : une faute de clé obligatoire qui nomme `evolutions`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/content_editor/`
Expected: les cinq tests neufs et les deux réécrits échouent.

- [ ] **Step 3: Implémenter** — le descripteur et son commentaire.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/content_editor/ test/widget/content_editor_screen_test.dart test/widget/content_editor/`
Expected: tout passe — `shipped_entities_round_trip_test` sur les six signatures livrées, et la recette de classe, qui crée ses signatures du gabarit.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 2003** (1998 + 2 + 3).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(editeur): les evolutions de signature`.

---

### Task 9: Vérification finale (orchestrateur)

Aucun fichier modifié : des commandes, jouées par l'orchestrateur, sans agent.

- [ ] **Step 1: L'analyse** — `dart analyze` → `No issues found!`
- [ ] **Step 2: La suite** — `rm -rf build/unit_test_assets` puis `flutter test` → `All tests passed!`, **2003**.
- [ ] **Step 3: Les tests nommés de la partie** — `flutter test test/unit/save_service_test.dart test/unit/signature_evolution_data_test.dart test/unit/signature_evolution_rules_test.dart --reporter expanded` → verts, nommément : les neuf du groupe « les evolutions de signature (spec §8) », « les six pools sont ceux de spec 3.7 : trois mineures, quatre majeures (Q6) », « une majeure exclue n est pas offerte, dans les deux sens », « majeures epuisees : trois mineures au palier majeur (Q6, repli) ».
- [ ] **Step 4: Les greps de la spec (§11, « Ce que le vérificateur contrôle »)**
  - `git grep -n "onDamagingCardPlayed" -- lib test assets` → rien (D34) ; `grep -c '"trigger": "onAttackPlayed"' assets/data/passives/mage_mark.json` → `1`.
  - `ls assets/data/cards/focus.json assets/data/cards/demon_form.json` → deux « No such file » ; `ls assets/data/cards/rage/demon_form.json` → le fichier.
  - `git diff main -- tool/simulations` → vide.
  - `dart run tool/sync_assets.dart --check` → code de sortie 0.
- [ ] **Step 5: Les greps propres à la partie 3**
  - `git diff --name-only 996421a -- assets/data` → exactement les six `classes/*/skills/*.json`.
  - `grep -l '"evolutions"' assets/data/classes/*/skills/*.json | wc -l` → `6`.
  - `git grep -niE "vague 5" -- lib` → rien (les cinq commentaires au futur, `run_controller.dart:82`, `card_delta.dart:11`, `effective_card.dart:74`, `signature_instance.dart:11`, `:14`, sont au présent) ; `git grep -n "currentMana >= signature.cost" -- lib` → rien.
  - `git grep -ln "signature_evolution_style.dart" -- lib` → `lib/ui/screens/signature_evolution_screen.dart` et `lib/ui/widgets/hud/signature_bar.dart` seulement (deux lecteurs, aucun dans `lib/game/` ni `lib/models/`).
  - `git grep -n "package:flutter_riverpod\|package:flame" -- lib/game/systems/signature_evolution_rules.dart lib/models/signature_instance.dart lib/models/data/signature_evolution_data.dart` → rien (règle pure, couche données).
  - `git status --short` → seul le fichier d'orchestration, que l'orchestrateur tient ; aucun `generated_plugin*` ni `GeneratedPluginRegistrant.swift` modifié.
