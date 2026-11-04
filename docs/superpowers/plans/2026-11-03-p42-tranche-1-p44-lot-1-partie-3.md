# P-42 tranche 1 et P-44 lot 1, partie 3 — Les évolutions de signature — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, chaque signature évolue tous les cinq niveaux du héros : un écran à trois rouleaux propose trois évolutions de son pool (trois mineures, quatre majeures), le joueur en prend une ; en combat, la tuile ne montre plus de texte au repos mais une icône chiffrée par effet de la signature évoluée — sa liste de phrases tant qu'on reste appuyé —, avec le coût, la recharge et la cible évolués, un badge de niveau ambre et une puce par évolution prise ; une seule table d'icônes par sorte d'effet, en donnée, sert la tuile, ses puces et le panneau des statuts ; les choix survivent à la sauvegarde ; l'éditeur de contenu sait écrire une évolution.

**Architecture:** Une évolution est une donnée du fichier de sa signature (`SignatureEvolutionData`, sous `evolutions`), faite de deltas du vocabulaire de `CardDelta` — plus une sorte neuve, `flatBonus` — et de deux champs propres, `target` et `cooldown`. `SignatureInstance` porte ses références `id:niveau` ; sa vue de carte (`asCard`) les traduit en `CardInstance.extraDeltas`, que l'applicateur des runes (`EffectiveCard.apply`) lit après les runes : la couture d'ADR-105 D1, sans que runes et évolutions partagent stockage ni affichage. Le tirage et l'admissibilité vivent dans une règle pure (`SignatureEvolutionRules`) ; l'attente se dérive du niveau du héros, rien de neuf ne se compte ; seule la liste des références se sauvegarde, sous `signatureEvolutions`. L'écran d'évolution reprend le carrousel du draft de niveau. En combat, la tuile lit `SignatureInstance.effectLines` : une bande d'icônes par sorte d'effet (A40), traduites par un document plat, `effect_icons.json` (A39), et, à l'appui long, une liste de phrases par sorte (`EffectLineTexts`, A41) dans un calque (A42) ; la barre se mesure et se transforme pendant la mise en page (A38), ce que le calque lit.

**Tech Stack:** Flutter / Dart 3, Flame (non touché), Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md` — §10 « Partie 3 » pour le périmètre ; §3.7 (gabarits, évolutions, pools, icônes, et « Les icônes d'effet »), §4.10 (le moteur des évolutions), §5.1 (l'écran), §3.8 (`_configDocuments`), §5.2 (les trois lignes marquées 3 : tuile de combat, panneau des statuts, tuile hors combat), §6.1 (les clés `evolution…`, `levelLabel`, `effectValuePercent` et les treize `effectLine…`), §7 (la ligne marquée 3 : descripteur de signature), §8 (la sauvegarde — **tâche à risque**), §9 (les lignes marquées 3) et §9.1 (les tests manuels marqués 3, M7 à M34), §5.4 (l'entrée de debug des évolutions, P-7 (a)), §11. Les décisions de §1 — les réponses du propriétaire de §1.2 (dont Q6, Q7, P-2 (c), P-4 (a), l'écran d'évolution, et PN12 (d) et PN13 (c)) — et les arbitrages A1 à A42 de §1.3, en particulier A24 à A28 et A35 à A42 — sont acquises : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md`.

Réponses du propriétaire reprises telles quelles (spec §1.2) : **Q6** — 3 mineures et 4 majeures par signature ; une majeure en manque tire une mineure (repli). **Q7** — deux majeures contradictoires s'excluent par une liste `excludes` d'ids sur l'évolution, lue dans les deux sens. **P-2 (c)** — un badge de niveau et une icône par évolution prise sur la tuile. **P-4 (a)** — l'icône de l'évolution sur chaque rouleau. **L'écran** — le carrousel `DraftScreen` / `DraftCardReel`, trois rouleaux, une fois par signature, par le rideau de `pendingDrafts` ; chaque rouleau : nom, description, palier, « 1 → 2 » pour une mineure déjà prise ; l'en-tête nomme la signature. **PN12 (d)** — en combat, la tuile écrit en icônes ce que fait la signature : une icône chiffrée par effet, trois par ligne, centrées, sans durée ; à l'appui long, la liste, une ligne par icône, repliée au relâcher, par-dessus les voisines sans déplacer la colonne ; l'appui court garde son rôle ; hors combat, le texte complet. **PN13 (c)** — le badge « Niv. n » en `Colors.amberAccent`, disponible et armée ; `Colors.white38` en recharge et sans le mana.

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
- **D77** (brainstorm v3, §1, 04/11) : aucun nouveau test d'écran — les tests gardent les calculs, les données, les contrôleurs et la sauvegarde ; ce qu'un test d'écran aurait vérifié est un point de test manuel (spec §9.1), que reprend l'étape « Points de tests manuels » de chaque tâche d'interface ; un fichier de test supprimé par le tri du 04/11 n'est jamais recréé.
- **La base de tests** : `flutter test` rend **1524** sur la branche (mesuré le 04/11, après le tri des tests d'écran, `5fbbe63f`). Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ». **Total attendu en fin de plan : 1612** (+88 ajoutés, aucun retiré).
- **Les références `fichier:ligne`** ont été relues le 2026-11-03 sur `996421a`. Une tâche qui modifie un fichier décale les lignes des suivantes : l'implémenteur se fie au symbole nommé, la ligne n'est qu'un repère.
- **La tâche à risque est la Task 5** (la sauvegarde) : son code et ses tests s'écrivent ici en entier, et le vérificateur les rejoue dans un clone. Ailleurs, seul l'algorithme d'A38 (Task 8), imposé ligne à ligne par la spec, est écrit.
- **Les cartes, les runes et le moteur de P-44 lot 1 ne changent pas** ; `tool/simulations/` ne change pas (ADR-108 D5) ; `assets/data/passives/mage_mark.json` garde `"trigger": "onAttackPlayed"` (D34).
- **P-7 est répondue (a) par le propriétaire le 04/11** (spec §1.2, §5.4) : l'entrée de debug des évolutions, en Task 7.
- **P-5 et P-6 sont répondues (a) par le propriétaire le 04/11** (spec §1.2), les options sous lesquelles le plan s'est écrit : plus rien de provisoire à leur nom, ni à celui de PN12 et PN13.

## Review Focus

**D77** : ce plan ne prescrit aucun test d'écran ; ce qui ne se voit qu'à l'écran est confié aux points de tests manuels (spec §9.1), jamais à un test.

Cinq modes d'échec que la spec implique pour la partie 3 et qu'aucun test ne garde encore, du plus probable au moins probable ; chacun est confié à la tâche qui écrit le test qui le garde, et, pour sa part d'écran, aux points de tests manuels de la tâche d'interface qui le dessine.

1. **Une évolution perdue ou déformée à la reprise.** L'ordre de première prise — que la rangée des puces et la bande lisent (A37, A40) — réordonné ; une majeure relue au niveau 2 ; deux majeures exclues relues ensemble ; une évolution supprimée d'une mise à jour qui fait échouer la relecture au lieu d'être signalée ; une sauvegarde de `0.5.6` sans la clé qui ne se relit plus. → **Task 5** (neuf tests, code en entier).
2. **Une tuile qui ment, ou une bande qui déborde.** Le coût, la cible ou la valeur de base au lieu des évolués ; l'accessibilité lue sur le coût de base (`signature_bar.dart:114`) ; une durée de statut écrite sur la bande ; une ligne coupée au lieu d'être réduite d'un bloc, ou décentrée ; un texte resté au repos ; un gabarit brut hors combat. → **Task 3** (`asCard`, `effectLines`, et `canAfford` sur `asCard` : le coût évolué), **Task 8** (le grep de `canAfford(signature.asCard`), **Task 2** (`getDescription` remplit le gabarit) ; la bande et la tuile hors combat à l'écran, points de tests manuels des Tasks 2 et 8.
3. **Le calque qui bouge la barre, ou qui reste ouvert.** L'ouverture qui change la hauteur, l'échelle ou la place de la colonne ; la liste qui survit à un `PointerCancelEvent` ou se replie au moindre glissement ; un appui long qui joue ou arme ; la liste du bas qui sort de l'écran au lieu de s'ouvrir vers le haut ; et, sous elle, la barre qui monte à niveau 0 en `1280 × 800` ou une tuile réduite à `H = 400` qui ne répond plus. → **Task 8** (la fonction de placement, un test, dont un cas à `H = 400`) ; le calque, le geste et la barre posée, points de tests manuels des Tasks 8 et 9.
4. **Deux icônes pour un même effet.** La bande, la liste, la puce d'une évolution, le panneau des statuts et les faces des cartes qui divergent ; une sorte produite par une signature absente du document (un `help_outline` sur la bande) ; le panneau qui tombe en `help_outline` sur un registre construit à la main. → **Task 6** (`referential_integrity_test`, dont les 32 évolutions à une sorte et l'égalité avec les deux faces ; `effect_icon_table_test`, `effectVisualsOrNull` nul sur une table vide) ; le panneau à l'écran, points de tests manuels de la Task 6.
5. **Un tirage qui offre l'interdit, un choix qui écrit sans droit, ou une attente sans rideau.** Une majeure au palier mineur ou exclue par une prise ; moins de trois rouleaux quand trois évolutions existent ; un `chooseSignatureEvolution` qui écrit quand rien n'attend ou n'appelle pas la sauvegarde ; l'ordre des attentes (Châtiment puis Bouclier Sacré au niveau 5 ; les deux mineures puis les deux majeures sur un saut de 4 à 10) ; l'évolution ouverte avant le draft de niveau ; les nœuds ouverts pendant une attente. → **Task 4** (`signature_evolution_rules_test`, dont `nextPendingEvolution` et `hasPendingChoice`, la condition que lisent le rideau et les deux gardes de nœud) ; le rideau, l'ordre des écrans et les nœuds fermés à l'écran, points de tests manuels de la Task 7.

**Les autres trous** — ceux de la section « Pour le Review Focus des plans » des vérifications de la spec qui touchent la partie 3, et les points reportés des parties 1 et 2 —, chacun confié :

| Trou | Tâche, test ou décision |
|:---|:---|
| `nextPendingEvolution` : Châtiment puis Bouclier Sacré au niveau 5 ; mineures puis majeures sur un saut de 4 à 10 | Task 4 |
| Hors combat, `SignatureTile` n'affiche jamais un gabarit brut | Task 2 : `getDescription` remplit le gabarit (`signature_evolution_data_test`) ; la tuile, point de test manuel M8 |
| Refus à l'écran par `signature_bar.dart:114` (`signature.cost` évolué) — **point reporté** | Task 8 : la tuile lit `EffectResolver.canAfford(signature.asCard, heroStats)`, la règle unique d'A10 ; `SignatureBar` reçoit `heroStats` au lieu de `currentMana`. Gardé par la Task 3 (`canAfford` sur `asCard`, le coût évolué) et le grep de la Task 8 ; à l'écran, M24 |
| Q11 sur une signature à deux statuts d'évolution (*Projectile Magique*, `ember` et `exposure`) : un seul bonus, sur le premier dans l'ordre des effets ajoutés | Task 3, `effect_resolver_test` |
| Écran : mineure déjà prise, `{val}` au prochain niveau (*Zèle* 1 → 2, « +4 dégâts ») et la ligne « 1 → 2 » | Task 2 (`{val}`), Task 7 (l'écran, point de test manuel M15) |
| `{val}` d'une majeure `reduceCost` : `min(coût, valuePerLevel)` (*Dévotion* sur *Châtiment*, coût 1 → 1) | Task 2 |
| *Célérité* : même `icon`, même `color`, même texte dans ses cinq pools | Task 2 |
| Le gabarit d'éditeur de la signature (`entity_descriptor.dart:318-328`) sans `evolutions` : `entity_validator_test`, `entity_descriptor_test` rougiraient dès que `evolutions` est exigée | Task 2 : le gabarit porte une évolution complète, verbale (`ardor`), dans la même tâche que l'exigence |
| La barre réduite : un toucher sur une tuile réduite arme encore, l'invite reste visible ; un cas à `H ≈ 400` | Task 8 : `signatureBandPlacement` à `H = 400` ; le toucher et l'invite, point de test manuel M31 |
| Au niveau 0 et en `1280 × 800`, la colonne n'a pas bougé par rapport à `0.5.6` | Task 8 : `signatureBandPlacement` (`(800, 176)` → `(1, 312)`) ; la colonne posée, M30 |
| Le badge et la bande sur la tuile étroite, à la vraie police (« 10 », « 10 », « +5 % » à la limite des 154 px) | Task 8, points de tests manuels M18, M21, M22 (les largeurs, la réduction d'un bloc et le centrage) |
| L'aller-retour de sauvegarde garde l'ordre de première prise | Task 5 |
| Chaque entrée d'`effectIcons` et d'`effectColors` sert au moins une évolution ou une sorte | Task 6, `referential_integrity_test` |
| Soixante fichiers de test construisent `GameDataRegistry(` à la main | Task 6 : `effectIcons` facultatif, une table vide par défaut ; `effectVisualsOrNull` y rend `null` (`effect_icon_table_test`), et le panneau garde alors ses icônes d'aujourd'hui |
| La face Flame `_getEffectVisuals`, privée, que le test d'égalité doit appeler | Task 6 : publique, `static`, `@visibleForTesting`, son type de retour public (`RendererEffectVisuals`) |
| Le calque lit la transformation de la tuile pendant la mise en page ; `Flow` ne l'établit qu'à la peinture | Task 8 : la barre passe par un `RenderBox` propre (PN18) ; Task 9 la lit |
| Sous P-4 (a) : le paramètre de `DraftCardReel` est facultatif, le draft de niveau ne change pas | Task 7 : `dart analyze` (le paramètre facultatif, les appelants inchangés) ; point de test manuel M11 |
| Sous P-7 (a) : les tests manuels qui demandent un état d'évolution précis (M18 à M25, M27), inatteignable en jouant | Task 7 : l'entrée de debug des évolutions, par `admissible` et `withChoice` (`debug_actions_test`) ; la section de l'onglet, M34 |
| A33 : le budget de D38 reste vrai sur chaque signature évoluée | Task 3, `card_catalog_test` (toutes les évolutions prises) |
| **Point reporté** — `SignatureInstance` construit un `CardData` sans `hpCost` ni `armorCost` (`signature_instance.dart:20-36`) | Task 3 : `asCard` est réécrit ; `SignatureData` n'a pas de coût autre que le mana, les défauts (0) sont justes et le commentaire d'`asCard` le dit ; la tuile lisant `canAfford` (Task 8), un coût non-mana futur serait lu sans retouche |
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
| `lib/models/data/effect_kind.dart` *(nouveau)* | Le vocabulaire des sortes d'effet (A39) | 3, 6 |
| `lib/models/signature_instance.dart` | `evolutions`, `level`, `taken`, `asCard`, `effectLines`, `cost`, `cooldown`, `pendingFor`, `nextTier` ; `restore` | 3, 5 |
| `lib/game/systems/signature_evolution_rules.dart` *(nouveau)* | Le tirage, l'admissibilité, le choix | 4 |
| `lib/game/controllers/run_controller.dart` | `nextPendingEvolution`, `hasPendingChoice`, `chooseSignatureEvolution` ; `signatureEvolutions` | 4, 5 |
| `assets/data/effect_icons.json`, `lib/models/data/effect_icon_table.dart` *(nouveaux)*, `game_data_registry.dart`, `lib/services/game_data_service.dart` | Le document des icônes d'effet, son modèle, son chargement | 6 |
| `lib/ui/widgets/effect_style.dart` *(nouveau)* | `effectIcons`, `effectColors`, leurs deux lectures (6) ; `EvolutionIcon` (7) | 6, 7 |
| `lib/ui/widgets/hud/status_effects_panel.dart`, `lib/tutorial/widgets/tutorial_elements_widget.dart` | Le panneau des statuts lit la table | 6 |
| `lib/game/components/widgets/card_text_renderer.dart` | La face Flame, `getEffectVisuals` publique | 6 |
| `CLAUDE.md` | `effect_icon_table.dart`, `effect_icons.json` (spec §11) | 6 |
| `lib/ui/screens/signature_evolution_screen.dart` *(nouveau)* | L'écran d'évolution | 7 |
| `lib/ui/widgets/relic_carousel/draft_card_reel.dart`, `lib/ui/widgets/draft/draft_choice_card.dart` | Le paramètre `icon` facultatif | 7 |
| `lib/ui/screens/map_screen.dart` | Le rideau et les gardes de nœud | 7 |
| `lib/game/services/debug_actions.dart`, `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` | L'entrée de debug des évolutions (P-7 (a), spec §5.4) | 7 |
| `lib/ui/widgets/hud/signature_bar.dart`, `combat_side_panels.dart`, `combat_top_bar.dart`, `lib/ui/screens/game_screen.dart` | La tuile évoluée, la bande, le badge, les puces, la barre (8) ; la liste et le calque (9) | 6, 8, 9 |
| `lib/game/services/effect_line_texts.dart` *(nouveau)* | Les phrases de la liste, par sorte | 9 |
| `lib/l10n/app_fr.arb`, `app_en.arb` (+ trois `app_localizations*.dart`) | Clés `evolution…` (7) ; `levelLabel` réécrite, `effectValuePercent` (8) ; les treize `effectLine…` (9) | 7, 8, 9 |
| `lib/services/content_editor/entity_descriptor.dart` | Le gabarit (2), puis le descripteur des évolutions (10) | 2, 10 |
| `test/unit/signature_evolution_data_test.dart`, `signature_evolution_rules_test.dart`, `effect_icon_table_test.dart`, `effect_line_texts_test.dart` *(nouveaux ; aucun test d'écran neuf, D77)* | — | 2, 4, 6, 9 |
| Les autres tests touchés | Nommés tâche par tâche | 1 à 10 |

Ordre : la couture de l'applicateur (1) ; la donnée, ses règles et les six pools (2), qui ne changent rien au jeu tant qu'aucune signature ne porte d'évolution ; la vue évoluée et ses entrées de bande (3) ; le tirage, le choix et l'attente (4) ; **la tâche à risque, la sauvegarde (5)**, avant que le joueur puisse prendre une évolution ; le document des icônes d'effet, avec le panneau des statuts pour premier lecteur (6) ; l'écran et le rideau (7), qui ouvrent le jeu aux évolutions ; la tuile et sa bande (8), puis sa liste (9) ; l'éditeur (10) ; la vérification (11).

| Après la tâche | Total de tests |
|:---:|:---:|
| base | 1524 |
| 1 | 1530 |
| 2 | 1548 |
| 3 | 1563 |
| 4 | 1574 |
| 5 | 1583 |
| 6 | 1596 |
| 7 | 1601 |
| 8 | 1602 |
| 9 | 1607 |
| 10 | 1612 |

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

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1530** (1524 + 3 + 3).

- [ ] **Step 6: Commit**

`git add` des quatre fichiers de `lib/` et des trois tests, puis `git commit` — `feat(signatures): flatBonus et extraDeltas, la couture des evolutions`.

---

### Task 2 (interface): Les évolutions en donnée — `SignatureEvolutionData`, les gabarits, les six pools

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 3. Ce que le joueur voit : les descriptions des trois signatures qui piochent disent « carte(s) » à la carte de classe et au dictionnaire (spec §3.7) ; rien d'autre ne change à l'écran.

**Files:**
- Create: `lib/models/data/signature_evolution_data.dart`, `test/unit/signature_evolution_data_test.dart`
- Modify: `lib/models/data/signature_data.dart:1-135` ; les six `assets/data/classes/*/skills/*.json` ; `lib/services/content_editor/entity_descriptor.dart:318-328` (le gabarit de la signature)
- Test: aucun test d'écran (D77 ; `signature_tile_test.dart`, supprimé par le tri du 04/11, n'est pas recréé) ; réécrits sans changer le compte, chaque document de signature écrit à la main qui passe par `SignatureData.fromJson` : `test/unit/signature_data_test.dart:6-23` (`valid()`), `test/unit/content_editor/fixtures.dart:26-41` (`fixtureSignature`), et les cinq tests qui rougissent réellement : `test/unit/content_editor/entity_descriptor_test.dart:279` « chaque gabarit porte exactement les cles attendues » (l'ensemble de clés de la signature, `:300-307`, gagne `evolutions` après `'effects'`, `:306`), `test/unit/content_editor/entity_validator_test.dart:114` « une signature homonyme d une signature du registre est refusee » (par `fixtureSignature`), et les trois tests de `signature_data_test.dart` qui lisent `valid()` sans refus (`:31`, `:50`, `:119`). `entity_writer_test.dart:285`, `content_editor_screen_test.dart:607` (« choisir une signature la charge depuis son dossier ») et `scale_with_test.dart:139` (voir PN4) restent verts et ne se réécrivent pas

**Interfaces:**
- Consumes : `FlatBonusDelta`, `CardDelta.fromJson` (Task 1).
- Produces (`signature_evolution_data.dart`, couche données) :
  - `enum EvolutionTier { minor, major }`.
  - `class SignatureEvolutionData` — `const SignatureEvolutionData({required String id, required EvolutionTier tier, String nameEn = '', String nameFr = '', String descriptionEn = '', String descriptionFr = '', List<CardDelta> deltas = const [], CardTarget? target, int cooldown = 0, List<String> excludes = const [], String icon = '', String color = ''})` ; champs du même nom.
  - `static const deltaTypeNames = ['flatBonus', 'addEffect', 'reduceCost', 'critBonus']` ; `static const targetNames = ['allEnemies']` — lus par le chargeur et par l'éditeur (Task 10).
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
  - `evolutions` : les 42 évolutions de la table « Les six pools », mineures puis majeures, chacune avec son `id`, `tier`, ses quatre textes, et `icon` / `color` de la table « Les icônes » — ces icônes et couleurs, alignées sur les faces des cartes ; *Carapace* et *Bouclier de mana* écrivent « Donne {val} d'Armure » / « Gain {val} Block ». La traduction des colonnes en clés :
    - `flatBonus <effet> N` → `{"type": "flatBonus", "effect": "<effet>", "valuePerLevel": N}` ; `flatBonus apply_status might 1` (*Colère*) porte en plus `"statusId": "might"` ;
    - `addEffect <statut> N, D tours` (majeure) ou `D tours par niveau` (mineure) → `{"type": "addEffect", "effect": "apply_status", "statusId": "<statut>", "valuePerLevel": N, "durationPerLevel": D}` ; `addEffect armor|heal|draw N` → `{"type": "addEffect", "effect": "<armor|heal|draw>", "valuePerLevel": N}` ;
    - `critBonus 5` → `{"type": "critBonus", "valuePerLevel": 5}` ; `reduceCost 1` → `{"type": "reduceCost", "valuePerLevel": 1}` ;
    - `cooldown −1` / `+1` → `"cooldown": -1` / `1`, sans `deltas` s'il n'y a qu'elle ; `target allEnemies` → `"target": "allEnemies"`, sans `deltas` ;
    - `excludes` : `haste` ↔ `devastation` sur *Frappe Téméraire*, `haste` ↔ `overload` sur *Projectile Magique*, déclarés des deux côtés.
  - Exemple, *Dévastation* : `{"id": "devastation", "tier": "major", "name_fr": "Dévastation", "name_en": "Devastation", "description_fr": "+10 dégâts, recharge allongée d'un tour", "description_en": "+10 damage, cooldown one turn longer", "deltas": [{"type": "flatBonus", "effect": "damage", "valuePerLevel": 10}], "cooldown": 1, "excludes": ["haste"], "icon": "rocket_launch_rounded", "color": "yellowAccent"}`.
- Le gabarit d'éditeur de la signature gagne `"evolutions": [ { "id": "ardor", "tier": "minor", "name_fr": "Ardeur", "name_en": "Ardor", "description_fr": "+{val} % de critique", "description_en": "+{val}% critical chance", "deltas": [ { "type": "critBonus", "valuePerLevel": 5 } ], "icon": "flare_rounded", "color": "amber" } ]` — verbale, pour qu'une description saisie sans `{…}` reste valide ; la recette de classe (`class_recipe.dart`), qui remplit ses signatures du gabarit, en hérite.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/signature_evolution_data_test.dart` *(nouveau ; l'aide `refusing(clé)` de `signature_data_test.dart:25-27`)* :
- `une evolution complete se lit` — l'exemple *Dévastation* : `tier` major, `deltas` `[isA<FlatBonusDelta>()]` à 10, `cooldown` 1, `excludes` `['haste']`, `icon` `'rocket_launch_rounded'` `color` `'yellowAccent'`, `isVerbal` faux.
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

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_evolution_data_test.dart`
Expected: échec de compilation — `SignatureEvolutionData` n'existe pas.

- [ ] **Step 3: Implémenter** — le modèle, les règles du pool et les gabarits, les six fichiers, le gabarit d'éditeur, puis les documents de test écrits à la main (chacun gagne l'évolution du gabarit, `ardor`).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/signature_data_test.dart test/unit/scale_with_test.dart test/unit/real_bundle_load_test.dart test/unit/content_editor/ test/widget/content_editor_screen_test.dart`.
Expected: tout passe — dont `shipped_entities_round_trip_test` sur les six signatures à évolutions.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1548** (1530 + 18). `dart run tool/sync_assets.dart --check` → code 0.

- [ ] **Step 6: Points de tests manuels** (spec §9.1 ; aucun ne se joue ici, l'orchestrateur les porte au fichier de tests manuels de la vague)

- **M8** — La sélection de classe et le dictionnaire : déplier la carte du Paladin, puis chercher *Châtiment* au dictionnaire → la tuile de la signature dit sa description complète, chiffres remplis (« Inflige 6 dégâts et donne 4 d'Armure. »), jamais une accolade `{…}` ; ni badge, ni puce, ni bande d'icônes ; les trois signatures qui piochent disent « carte(s) ».

- [ ] **Step 7: Commit**

`git add` par chemin (les six JSON compris), puis `git commit` — `feat(signatures): les evolutions en donnee, six pools et gabarits`.

---

### Task 3: La signature évoluée — `SignatureInstance`

**Files:**
- Create: `lib/models/data/effect_kind.dart`
- Modify: `lib/models/signature_instance.dart:1-37`
- Test: `test/unit/signature_instance_test.dart`, `test/unit/card_catalog_test.dart`, `test/unit/effect_resolver_test.dart` (groupe `Q11`, `:313`)

**Interfaces:**
- Consumes : `CardInstance.extraDeltas`, `EffectiveCard.apply` (Task 1) ; `SignatureEvolutionData`, `SignatureData.evolutions`, `SignatureData.fillTemplate` (Task 2) ; `ForgeUpgradeData.levelsOf` (`forge_upgrade_data.dart:423-432`). `signature_instance.dart`, qui n'importe aujourd'hui que `card_instance.dart`, `data/card_data.dart` et `data/signature_data.dart`, gagne ceux que ses getters et `asCard` lisent : `dart:math` (`show max`), `effective_card.dart`, `data/card_delta.dart` (`effectLines` distingue `AddEffectDelta` et `CritBonusDelta`), `data/effect_kind.dart`, `data/forge_upgrade_data.dart` (pour `levelsOf`) et `data/signature_evolution_data.dart` ; la Task 5 n'ajoutera que `missing_save_item.dart`.
- Produces (spec §4.10, ligne à ligne) :
  - `const SignatureInstance(this.data, {this.evolutions = const []})` ; `final List<String> evolutions` — des références `id:niveau`, dans l'ordre de la première prise.
  - `List<(SignatureEvolutionData, int)> get taken` — `levelsOf(evolutions)`, chaque id relu dans `data.evolutions` ; un id absent du pool est passé (la relecture, Task 5, n'en laisse aucun).
  - `int get level` — la somme des niveaux de `taken`.
  - `CardInstance get asCard` — la `CardData` d'E4 sur `data.cost` (plus `cost`, sinon `cost` et `asCard` s'appelleraient l'un l'autre) ; sa cible : celle de la **dernière** majeure `target` prise, sinon `data.target` ; ses `extraDeltas` : les deltas de chaque évolution de `taken`, à son niveau, dans l'ordre ; ses deux descriptions : `fillTemplate(<gabarit de la langue>, <les effets propres évolués>)` — les effets d'`EffectiveCard.apply(<la CardData>, common, <ces deltas>)` —, suivi, pour chaque évolution **verbale** de `taken` dans l'ordre, de sa phrase `getDescription(niveau, langue, cost: data.cost)` ; une chiffrée n'ajoute rien. La jointure est celle d'A25 : chaque phrase s'ajoute en `' <phrase>.'` — « Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. ». C'est la forme **hors combat** de la signature évoluée : aucun écran de `0.5.7` ne la montre (en combat, la bande et la liste, Tasks 8 et 9), le test d'`asCard` la verrouille. Le commentaire d'`asCard` dit qu'une signature ne coûte que du mana : `hpCost` et `armorCost` restent à 0 (point reporté).
  - `abstract final class EffectKind` (`lib/models/data/effect_kind.dart`, couche données) — la sorte d'un effet (A39) : `static const crit = 'crit'`, `static const allEnemies = 'target:allEnemies'`, `static String of(CardEffect effect)` — `status:<statusId>` pour un `apply_status`, le type sinon. La Task 6 y ajoute le reste du vocabulaire.
  - `typedef EffectLine = ({String kind, int? value, int? duration})` (dans `signature_instance.dart`, son producteur) et `List<EffectLine> get effectLines` (A40, spec §4.10), lu sur la vue évoluée, `asCard.effective` : d'abord une entrée par effet propre, dans l'ordre du fichier — `EffectKind.of(e)`, la valeur évoluée de l'effet, la durée d'un `apply_status` (nulle sinon) ; puis, pour chaque évolution **verbale** de `taken`, dans l'ordre, une entrée par changement : chaque `AddEffectDelta`, l'effet ajouté qui lui répond dans `addedEffects` (même ordre), à sa sorte, sa valeur et sa durée ; un `CritBonusDelta`, `(kind: EffectKind.crit, value: valuePerLevel × niveau, duration: null)` ; une `target`, `(kind: EffectKind.allEnemies, value: null, duration: null)`. Une chiffrée n'en ajoute aucune ; deux effets de même sorte restent deux entrées. Aucun widget ne recalcule une valeur.
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
- `la description : le gabarit rempli des valeurs evoluees, puis les phrases verbales ; une chiffree n ajoute rien` — la forme hors combat (A25) ; `['zeal:2', 'sentence:1']` : FR `« Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. »`, EN `« Deal 10 damage and gain 4 Block. Apply 1 Weakness for 2 turns. »` ; `['zeal:1']` seul : le gabarit rempli, rien d'autre.
- `effectLines : les effets propres puis les verbales, dans l ordre de premiere prise, a leurs valeurs evoluees` — `['zeal:2', 'sentence:1', 'ardor:1', 'radiance:1']` : `[(kind: 'damage', value: 10, duration: null), (kind: 'armor', value: 4, duration: null), (kind: 'status:weakness', value: 1, duration: 2), (kind: 'crit', value: 5, duration: null), (kind: 'target:allEnemies', value: null, duration: null)]`.
- `effectLines : une chiffree n ajoute aucune entree` — `['zeal:1', 'devotion:1', 'haste:1']` : deux entrées, `damage` 8 et `armor` 4.
- `effectLines : deux effets de meme sorte restent deux entrees` — une *Surtension de Mana* construite (`[gain_mana 1, draw 1]`) portant `['clarity:1', 'serenity:1']` : `gain_mana` 1, `draw` 1, `heal` 1, `heal` 4, dans cet ordre.
- `pendingFor : niveau du heros / 5 moins level, jamais negatif` — sans évolution : 4 → 0, 5 → 1, 12 → 2 ; `['zeal:1']` à 10 → 1 ; `['zeal:3']` à 10 → 0 (menu de debug).
- `nextTier : niveau de heros 5 -> mineure, 10 -> majeure` — `level` 0 → `minor`, 1 → `major`, 2 → `minor`, 3 → `major`.
- `canAfford lit le cout evolue : a 0 mana, Chatiment est refusee, avec Devotion acceptee` — `EffectResolver.canAfford(SignatureInstance(<Châtiment>).asCard, EntityStats(maxPv: 100, currentPv: 100, armure: 0, might: 0))` (mana 0) : faux ; avec `['devotion:1']` : vrai. La règle unique d'A10 que la tuile lira (Task 8, point reporté de `signature_bar.dart:114`) ; elle remplace, sous D77, le test d'écran « l accessibilite lit EffectResolver.canAfford » que la Task 8 prévoyait. Le fichier importe `effect_resolver.dart` et `entity_stats.dart`.

`card_catalog_test.dart` :
- `A33 : chaque signature, toutes ses evolutions prises, tient le budget de D38` — pour chaque signature du registre, `SignatureInstance(s, evolutions: [for (final e in s.evolutions) '${e.id}:1']).asCard` : Σ `hits × mightRatio` des effets `damage` (propres et ajoutés) ≤ `currentCost + 1 + 1e-9`.

`effect_resolver_test.dart`, groupe `Q11` :
- `Projectile Magique a Braise et Mise a nu : la Brulure recoit la Puissance, la Vulnerabilite non` — `SignatureInstance(<magic_missile du registre>, evolutions: const ['ember:1', 'exposure:1']).asCard` résolue par `EffectResolver.resolveCard` (même appel que l'aide `play`) : `burn` vaut 1 + 2, `vulnerable` vaut 2.

Les quatre tests existants de `signature_instance_test.dart` restent verts tels quels (la signature sans évolution).

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_instance_test.dart test/unit/card_catalog_test.dart test/unit/effect_resolver_test.dart`
Expected: échec de compilation — le paramètre `evolutions` n'existe pas.

- [ ] **Step 3: Implémenter** — `EffectKind`, puis `SignatureInstance`, sans toucher `signature_bar.dart` (Task 8) ni `run_controller.dart` (Tasks 4, 5).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/combat_signature_test.dart test/widget/signature_bar_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1563** (1548 + 13 + 1 + 1).

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
  - `RunState.hasPendingChoice` → `pendingDrafts > 0 || nextPendingEvolution != null` — la condition du rideau et des deux gardes de nœud (Task 7).
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

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1574** (1563 + 11).

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
Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1583** (1574 + 9).

- [ ] **Step 6: Commit**

`git add lib/models/signature_instance.dart lib/game/controllers/run_controller.dart test/unit/save_service_test.dart`, puis `git commit` — `feat(sauvegarde): les evolutions de signature survivent a la reprise`.

---

### Task 6 (interface): Les icônes d'effet — le document, la table, le panneau des statuts

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 7. Ce que le joueur voit : le panneau des statuts du héros, en combat et à l'étape des éléments du tutoriel, dessine la Puissance, l'Éveil de Puissance (`flash_on` → `bolt_rounded` ; `status_effects_panel.dart:106-110`), l'Armure au début du tour (`shield` cyan → `autorenew_rounded` bleu ; `:90-95`), la Faiblesse, Vulnérable, la Brûlure, le Poison, le Gel et l'Électrocution avec l'icône et la couleur des faces des cartes ; `metallicize` et `lifesteal` gardent les leurs.

**Files:**
- Create: `assets/data/effect_icons.json`, `lib/models/data/effect_icon_table.dart`, `lib/ui/widgets/effect_style.dart`, `test/unit/effect_icon_table_test.dart`
- Modify: `lib/models/data/effect_kind.dart` (Task 3) ; `lib/models/data/game_data_registry.dart:22-57` (le champ facultatif) ; `lib/services/game_data_service.dart:152-157` (le chargement, avant `throwIfFailed`), `:169-180` (le registre) ; `lib/ui/widgets/hud/status_effects_panel.dart:5-8`, `:79-146` ; `lib/ui/widgets/hud/combat_side_panels.dart:10-23`, `:71-75` ; `lib/ui/screens/game_screen.dart:626-631` ; `lib/tutorial/widgets/tutorial_elements_widget.dart:486-500` ; `lib/game/components/widgets/card_text_renderer.dart:11-15`, `:112`, `:277-357` ; `CLAUDE.md:43`, `:75-77`
- Test: `test/unit/referential_integrity_test.dart` (après `:90-101`, le test des icônes de rune), `test/unit/game_data_loader_test.dart` (après `:328-337`), `test/unit/real_bundle_load_test.dart:72-77`, `:92`, `test/unit/entity_id_convention_test.dart:16-18`, `test/tutorial/tutorial_test_registry.dart:34-48` ; aucun test d'écran (D77 : le panneau des statuts et celui du tutoriel, aux points de tests manuels ; `tutorial_elements_widget_test.dart`, supprimé par le tri du 04/11, n'est pas recréé)

**Interfaces:**
- Consumes : `SignatureEvolutionData.icon`, `color`, `deltas`, `target`, `cooldown` (Task 2) ; `SignatureInstance.effectLines` et `EffectLine` (Task 3) ; `getEffectVisuals` (`ui_card/ui_card_helpers.dart:72-152`), lu seulement par le test d'égalité.
- Produces :
  - `assets/data/effect_icons.json` — un document plat, les seize sortes de la table de spec §3.7 « Les icônes d'effet », `{"<sorte>": {"icon": "<nom>", "color": "<nom>"}}`, **mot pour mot** ; `status:poison`, `status:freeze`, `status:shock` y figurent, et chaque sorte que dessinent les faces des cartes y prend leur icône et leur couleur. Les fichiers de premier niveau d'`assets/data/` étant déclarés (`pubspec.yaml:35`), `sync_assets` n'a rien à ajouter : `--check` passe.
  - `lib/models/data/effect_icon_table.dart` (A39) — `class EffectIconEntry { const EffectIconEntry({required this.icon, required this.color}); final String icon; final String color; }` ; `class EffectIconTable` — `const EffectIconTable(Map<String, EffectIconEntry> entries)`, `const EffectIconTable.empty()`, `EffectIconEntry? entryOf(String kind)`, `Iterable<String> get kinds` ; `factory EffectIconTable.fromJson(Map<String, dynamic> json)` — refus nommant la clé (spec §3.7) : une clé qui n'est pas une sorte (`EffectKind.isKind`), `apply_status` nu compris ; une valeur qui n'est pas un objet à `icon` et `color`, deux textes non vides ; une clé de plus. Le document qui n'est pas un objet est déjà refusé par `GameDataLoader._read` (`game_data_loader.dart:195-200`).
  - `buildTutorialTestRegistry(openedPassives:)` (`test/tutorial/tutorial_test_registry.dart:34-48`), qui reconstruit le registre livré à la main, passe `effectIcons: shipped.effectIcons` (aucun test de plus).
  - `EffectKind` (`lib/models/data/effect_kind.dart`, Task 3) gagne `static const plain = {'damage', 'armor', 'heal', 'draw', 'gain_mana'}` et `static bool isKind(String key)` — un de `plain`, `crit`, `allEnemies`, ou `status:<id>` à l'id en `snake_case` ; la seule écriture du vocabulaire des sortes (A39), lue par `fromJson`.
  - `GameDataRegistry` gagne `final EffectIconTable effectIcons` (paramètre nommé, défaut `const EffectIconTable.empty()`, comme `levelUpRewards`, `:52` — soixante fichiers de test construisent le registre à la main). `loadGameDataRegistry` le lit par `loader.loadDocument('assets/data/effect_icons.json', EffectIconTable.fromJson)`, à côté de `xp_curve.json`, **avant** `throwIfFailed` : un fichier absent ou fautif fait échouer le démarrage (PN23).
  - `lib/ui/widgets/effect_style.dart` (A35, A39) : `const Map<String, IconData> effectIcons` — les dix-huit noms de spec §3.7 (`hardware_rounded`, `shield_rounded`, `favorite_rounded`, `flare_rounded`, `bolt_rounded`, `autorenew_rounded`, `trending_down_rounded`, `gps_fixed_rounded`, `local_fire_department_rounded`, `style_rounded`, `fast_forward_rounded`, `rocket_launch_rounded`, `all_out_rounded`, `savings_rounded`, `diamond_rounded`, `science_rounded`, `ac_unit_rounded`, `flash_on_rounded`) vers les `Icons.…` du même nom ; `const Map<String, Color> effectColors` — les quatorze (`redAccent`, `blueAccent`, `pinkAccent`, `amber`, `orangeAccent`, `purpleAccent`, `deepOrangeAccent`, `tealAccent`, `yellowAccent`, `deepPurpleAccent`, `cyanAccent`, `greenAccent`, `lightBlueAccent`, `amberAccent`) ; ces deux comptes, dix-huit et quatorze. Deux lectures, la seule traduction des noms : `({IconData icon, Color color}) effectVisualsOf(EffectIconTable table, String kind)` — une sorte absente, ou un nom inconnu, retombe sur `Icons.help_outline` et `Colors.grey` (la bande, la liste) ; `({IconData icon, Color color})? effectVisualsOrNull(EffectIconTable table, String kind)` — `null` pour une sorte absente (le panneau, qui garde alors son icône d'aujourd'hui) (PN25).
  - `StatusEffectsPanel` gagne `final EffectIconTable effectIcons` (défaut vide) : pour chaque statut dont `effectVisualsOrNull(effectIcons, 'status:${status.id}')` n'est pas nul, cette icône et cette couleur ; sinon, la branche d'aujourd'hui (`:79-146`), `metallicize` et `lifesteal` compris ; les libellés ne changent pas. `CombatSidePanels` gagne le même paramètre (défaut vide) et le passe au panneau (`:74`) ; `GameScreen` passe `gameData.effectIcons` (`:626-631`) ; `TutorialElementsWidget` passe `widget.engine.data.effectIcons` (`:486`).
  - la face Flame : `_RendererEffectVisuals` devient `RendererEffectVisuals` (`card_text_renderer.dart:11-15`) ; `_getEffectVisuals` devient `@visibleForTesting static RendererEffectVisuals getEffectVisuals(CardEffect effect)` (`:277`), sans état, comme `badgeValue` (`:266`), lu à `:112` ; les icônes et les couleurs rendues ne changent pas.
  - `CLAUDE.md:43` : `effect_icon_table.dart` rejoint la liste des modèles de données ; `:75-77` : l'arbre de `assets/data/` nomme `effect_icons.json` parmi les documents plats (spec §11).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/effect_icon_table_test.dart` *(nouveau)* :
- `un document complet se lit : chaque sorte, son icon et sa color` — l'exemple de spec §3.7 (`damage`, `status:weakness`, `crit`) : `entryOf('damage')` vaut `('hardware_rounded', 'redAccent')` ; `kinds` les trois ; `EffectKind.isKind` vrai pour `'status:weakness'`, `'crit'`, `'target:allEnemies'`.
- `une cle hors des sortes est refusee, nommee, apply_status nu compris` — `apply_status`, `status:Weakness`, `poison`, `target:self` : quatre `FormatException` nommant la clé.
- `une valeur sans icon ou color, vide, ou a une cle de plus est refusee` — quatre refus nommant la sorte.
- `une sorte absente retombe sur Icons.help_outline et du gris` — `effectVisualsOf(const EffectIconTable.empty(), 'damage')` : `(Icons.help_outline, Colors.grey)` ; `effectVisualsOrNull` : `null`.

`game_data_loader_test.dart` :
- `le demarrage du jeu refuse un registre sans effect_icons.json` — un `FakeBundle` qui ne porte que `assets/data/xp_curve.json` (valide) : `loadGameDataRegistry` lève, le message contient `effect_icons.json`.

`real_bundle_load_test.dart` :
- `le registre reel charge les seize sortes d effect_icons.json` — `registry.effectIcons.kinds` en compte 16.
- Réécrit, même compte : « le manifeste declare les 115 fichiers d entite » (`:72-77`) : « quatre documents de configuration », `effect_icons.json` compris.

`entity_id_convention_test.dart` — réécrit, même compte : `_configDocuments` (`:18`) gagne `effect_icons.json`, son commentaire dit « quatre ».

`referential_integrity_test.dart` (le registre réel du fichier ; les sortes produites se lisent sur `SignatureInstance(s, evolutions: [for (final e in s.evolutions) '${e.id}:1']).effectLines`, toutes évolutions prises) :
- `chaque icone et chaque couleur d evolution livree et d effect_icons.json est connue d effectIcons et effectColors` — sur le modèle du test des runes (`:90-101`).
- `chaque entree d effectIcons et d effectColors sert au moins une evolution ou une sorte`.
- `deux evolutions d une meme signature de meme icone ne sont jamais deux mineures ni deux majeures (A37)`.
- `chaque sorte que produit une signature livree ou une evolution de son pool figure au document ; chaque status:<id> du document est cree par createStatus`.
- `une evolution sans cooldown qui vise une seule sorte porte son icon et sa color (A39)` — la sorte d'un `flatBonus` ou d'un `addEffect` (`EffectKind.of` de son effet), `crit` d'un `critBonus`, `target:allEnemies` d'une `target` ; une seule, sans `cooldown` : `icon` et `color` de l'entrée du document ; le compte des évolutions vérifiées vaut **32**, dont `zeal` (`damage`) et `sentence` (`status:weakness`).
- `chaque effet qu ajoute une evolution a sa strategie, et chaque statut qu elle pose est fabrique par createStatus` — les `AddEffectDelta` et `FlatBonusDelta` des pools : `strategies.get(effect)` non nul ; `createStatus(statusId, 1, 1)` non nul.
- `les faces des cartes et le document donnent la meme icone et la meme couleur a chaque sorte commune` — pour `damage`, `armor`, `heal`, `gain_mana`, `draw` et les statuts `might`, `might_regen`, `armor_regen`, `poison`, `weakness`, `vulnerable`, `burn`, `freeze`, `shock` (un `CardEffect` construit par sorte) : `getEffectVisuals(e)` et `CardTextRenderer.getEffectVisuals(e)` rendent l'icône et la couleur d'`effectVisualsOf(registry.effectIcons, EffectKind.of(e))`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/effect_icon_table_test.dart test/unit/game_data_loader_test.dart test/unit/real_bundle_load_test.dart test/unit/entity_id_convention_test.dart test/unit/referential_integrity_test.dart`
Expected: échec de compilation — `EffectIconTable`, `effectIcons` et `CardTextRenderer.getEffectVisuals` n'existent pas.

- [ ] **Step 3: Implémenter** — le document, le modèle, le registre et son chargement, les tables, `CLAUDE.md` ; le panneau et ses deux lecteurs, la face Flame.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/tutorial/ test/widget/debug_drawer_test.dart` (des registres construits à la main).
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1596** (1583 + 4 + 1 + 1 + 7) dont 1 test d'égalité avec les faces. `dart run tool/sync_assets.dart --check` → code 0.

- [ ] **Step 6: Points de tests manuels** (spec §9.1 ; aucun ne se joue ici, l'orchestrateur les porte au fichier de tests manuels de la vague)

- **M7** — Le tutoriel : à l'étape des éléments, regarder le panneau des statuts → le Poison et la Brûlure ont l'icône et la couleur des faces des cartes (la fiole verte, la flamme orange).
- **M32** — Le combat, le panneau des statuts : donner au héros Puissance, Éveil de Puissance, Armure au début du tour, Faiblesse, Brûlure et Poison (cartes, signatures, ennemis) → chaque statut porte l'icône et la couleur des faces des cartes : l'éclair orange (Puissance), `bolt` pour l'Éveil, `autorenew` bleu pour l'Armure au début du tour, la flèche descendante violette, la flamme orange, la fiole verte ; les libellés ne changent pas.
- **M33** — Le combat, le panneau des statuts : porter Métallisation et Vol de vie (reliques) → ils gardent leurs icônes d'aujourd'hui (l'écu cyan, le cœur rouge) ; aucun statut ne s'affiche en point d'interrogation.

- [ ] **Step 7: Commit**

`git add` par chemin, puis `git commit` — `feat(effets): une table d icones par sorte d effet, lue par le panneau des statuts`.

---

### Task 7 (interface): L'écran d'évolution, le rideau et l'entrée de debug

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 8. Ce que le joueur voit : au niveau 5 du héros, le rideau de la carte s'affiche ; le toucher ouvre le draft de niveau, puis, rideau toujours là, l'évolution de Châtiment, puis celle de Bouclier Sacré. Dans une run debug, l'onglet Héros pose les évolutions d'une signature (P-7 (a)). L'entrée de debug vit ici : elle lit les règles de la Task 4, cette tâche est celle qui ouvre le jeu aux évolutions, et elle précède les Tasks 8 et 9, dont les points de tests manuels se préparent par elle — la Task 10, après elles, la donnerait trop tard.

**Files:**
- Create: `lib/ui/screens/signature_evolution_screen.dart`
- Modify: `lib/ui/widgets/effect_style.dart` (`EvolutionIcon`) ; `lib/ui/widgets/relic_carousel/draft_card_reel.dart:11-37` (paramètre), `:294-301` (le rouleau posé) ; `lib/ui/widgets/draft/draft_choice_card.dart:3-19` (paramètre), `:130-131` (l'emplacement de l'emoji) ; `lib/ui/screens/map_screen.dart:301-316` (le rideau), `:380`, `:403` (les gardes) ; `lib/l10n/app_fr.arb:280`, `lib/l10n/app_en.arb:766-770` (après `signatureTurnsLeft`) ; `lib/game/services/debug_actions.dart` (deux actions), `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` (la section « Évolutions de signature »)
- Test: `test/unit/debug_actions_test.dart` (un groupe neuf, l'entrée de debug) ; aucun test d'écran (D77). Les règles que lisent l'écran et le rideau — `offer`, `chooseSignatureEvolution`, `nextPendingEvolution`, `hasPendingChoice` — sont gardées par la Task 4 ; `draft_card_reel_test.dart` et `map_screen_test.dart`, supprimés par le tri du 04/11, ne sont pas recréés

**Interfaces:**
- Consumes : `SignatureEvolutionRules.offer`, `RunController.chooseSignatureEvolution`, `RunState.nextPendingEvolution`, `hasPendingChoice` (Task 4) ; `SignatureEvolutionData.getDescription`, `getName`, `tier`, `icon`, `color` (Task 2) ; `SignatureInstance.taken` (Task 3) ; `effectIcons`, `effectColors` (Task 6).
- Produces :
  - `class EvolutionIcon extends StatelessWidget` (`effect_style.dart`) — `const EvolutionIcon({super.key, required SignatureEvolutionData evolution, required double size, int level = 1, Color? color})` : la puce entière, anneau compris, mesure `size` ; l'icône `effectIcons[evolution.icon]`, la couleur `effectColors[evolution.color]`, un nom inconnu retombant sur `Icons.help_outline` et `Colors.grey` ; une **majeure** dans un anneau de sa couleur, une mineure nue ; dès `level ≥ 2`, une mineure porte son niveau en petit chiffre en bas à droite ; `color`, s'il est donné, remplace la couleur de l'évolution partout (icône, anneau, chiffre) — le gris de la tuile grisée (Task 8). Aucune clé de test (D77). Ni toucher ni survol. Le seul dessin d'une icône d'évolution, lu par l'écran et par la tuile (PN7).
  - `DraftChoiceCard` et `DraftCardReel` gagnent `final Widget? icon` (facultatif, défaut nul) : `DraftCardReel` ne le passe qu'au `DraftChoiceCard` du rouleau **posé** (`:294-301`), jamais aux cartes qui défilent ; `DraftChoiceCard` le dessine à la place de l'emoji (`:131`), au-dessus du titre ; nul, l'emoji d'aujourd'hui (PN7). Le draft de niveau et le tutoriel (`tutorial_draft_widget.dart:130`) ne le passent pas : rien n'y change.
  - `class SignatureEvolutionScreen extends ConsumerStatefulWidget` — `const SignatureEvolutionScreen({super.key, required SignatureInstance signature, required VoidCallback onComplete})`. Le tirage (`SignatureEvolutionRules.offer(signature, Random())`) se fait dans `initState`, rien n'est retenu entre deux ouvertures. Mise en page, survol (1,05), sélection (1,12, halo ambre), cadence et sons du `DraftScreen` (`draft_screen.dart:171-404`), recopiés dans l'écran sans toucher `DraftScreen` (PN8) ; la musique `MusicScene.map` ; le son de pose `reelLand` à la variante `common` (PN9). Spec §5.1, mot pour mot :
    - en-tête : `evolutionScreenTitle(<nom de la signature dans la langue>)`, puis `evolutionScreenSubtitle` ;
    - un `DraftCardReel` par évolution tirée : `title` son nom ; `description` sa description à son **prochain** niveau (`getDescription(<niveau pris> + 1, langue, cost: signature.data.cost)`), et, pour une mineure déjà prise, une dernière ligne `'\n${evolutionLevelUp(n, n + 1)}'` ; `rarity` : `evolutionTierMinor` ou `evolutionTierMajor` ; `icon` : `EvolutionIcon(evolution: e, size: 44)` (P-4) ; `spinPool` : les évolutions du pool, nom et description au niveau 1 (PN9) ;
    - toucher un rouleau posé : `chooseSignatureEvolution(signature.data.id, e.id)`, puis `onComplete()` — même si le choix est refusé, le rideau rouvre ce qui reste (PN16).
  - ARB, textes de spec §6.1 **mot pour mot** : `evolutionScreenTitle` (`signature` String) « Évolution de {signature} » / « {signature} evolves » ; `evolutionScreenSubtitle` « Choisissez une évolution » / « Choose an evolution » ; `evolutionTierMinor` « MINEURE » / « MINOR » ; `evolutionTierMajor` « MAJEURE » / « MAJOR » ; `evolutionLevelUp` (`from`, `to` int) « Niveau {from} → {to} » / « Level {from} → {to} ».
  - L'entrée de debug (spec §5.4, P-7 (a)), dans `DebugActions` (`lib/game/services/debug_actions.dart`), sous sa garde `_allowed` : `static bool takeSignatureEvolution(RefReader read, String signatureId, String evolutionId)` — refuse sans rien écrire si la signature n'est pas de la run, si l'évolution n'est pas de son pool, ou si elle n'est pas dans `SignatureEvolutionRules.admissible(signature)` ; sinon `updateRun` remplace l'instance par `SignatureInstance(data, evolutions: SignatureEvolutionRules.withChoice(signature.evolutions, evolution))`. Ni `pendingFor`, ni le niveau du héros, ni `checkpointProvider` : la seule règle du choix en jeu qu'elle ne lit pas est l'attente (spec §8, « menu de debug »). `static void clearSignatureEvolutions(RefReader read, String signatureId)` — la signature sans évolution. `DebugHeroTab` gagne, après le bouton « Gagner un niveau », un `Divider` puis, par signature de la run, son nom, ses références (`evolutions.join(', ')`, « aucune » si vide), un `TextButton` par évolution d'`admissible` (son nom) qui appelle `takeSignatureEvolution`, et « Retirer les évolutions » ; textes en français en dur, comme l'onglet.
  - `MapScreen` : le rideau (`LevelUpOverlay`, `:302`) s'affiche si `runState.hasPendingChoice` ; le toucher pousse `DraftScreen` si `pendingDrafts > 0` (inchangé), sinon `SignatureEvolutionScreen(signature: runState.nextPendingEvolution!, onComplete: () => Navigator.of(context).pop())`. Les deux gardes de nœud (`:380` dans `_isNodeAvailable`, `:403` dans `_onNodeTap`), qui lisent aujourd'hui `pendingDrafts > 0`, lisent `hasPendingChoice` : un draft de niveau **ou** une évolution en attente ferme les nœuds.

- [ ] **Step 1: Écrire les tests qui échouent — l'entrée de debug**

`test/unit/debug_actions_test.dart`, groupe neuf `DebugActions — evolutions de signature (P-7 (a))` *(le registre réel en `setUpAll`, comme `signature_evolution_rules_test` ; une run debug sur le modèle de `_startedRun` — `requestDebugRun()`, puis `startNewRun(<classe livrée>, null, <classe livrée>.getSignatures(registry))` — du Paladin livré, ou du Berserker pour l'exclusion ; le niveau du héros laissé à 1)* :
- `takeSignatureEvolution suit le palier : une majeure refusee d abord, admise apres une mineure` — *Châtiment* sans évolution : `haste` → `false`, rien d'écrit ; `zeal` → `true`, `['zeal:1']` ; `haste` → `true`, `['zeal:1', 'haste:1']`.
- `une mineure reprise monte a sa place ; une majeure prise ou exclue est refusee` — Berserker, *Frappe Téméraire* : `brutality`, `haste`, `brutality` → `['brutality:2', 'haste:1']` ; au palier majeur, `devastation` (exclue par `haste`) et `haste` (prise) → `false`, rien d'écrit ; `cleave` → `true`, `['brutality:2', 'haste:1', 'cleave:1']`.
- `l attente n est pas exigee : le niveau du heros ne bouge pas, pendingFor vaut 0, rien n est sauve` — au niveau 1, `zeal` accepté ; `heroStats.level` 1 ; `pendingFor(1)` 0 ; `container.read(checkpointProvider)` 0.
- `hors du pool, hors de la run ou hors d une run debug, rien n est ecrit` — `ghost` sur `smite`, `zeal` sur `reckless_strike` (pas une signature du Paladin), et `zeal` sur `smite` dans une run normale (`requestNormalRun()` avant `startNewRun`) : trois `false`, `signatures` inchangées.
- `clearSignatureEvolutions rend la signature sans evolution` — après `zeal`, `haste` : `smite` à `[]`, `holy_shield` intacte.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/debug_actions_test.dart`
Expected: échec de compilation — `takeSignatureEvolution` et `clearSignatureEvolutions` n'existent pas. Les tests existants du fichier restent verts.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n` ; `EvolutionIcon` ; le paramètre des deux widgets du carrousel ; l'écran ; le rideau ; les deux actions de debug et la section de l'onglet Héros. L'écran et le rideau n'ont pas de test à écrire d'abord (D77) : les règles qu'ils lisent sont gardées depuis la Task 4.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/signature_evolution_rules_test.dart test/unit/debug_run_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1601** (1596 + 5). `git grep -c "hasPendingChoice" -- lib/ui/screens/map_screen.dart` → `3` (le rideau, `_isNodeAvailable`, `_onNodeTap` ; `0` avant la tâche) : les deux gardes de nœud, qu'aucun joueur n'atteint sous le rideau opaque, sont vérifiées ici. `git grep -n "SignatureEvolutionRules.admissible" -- lib/game/services/debug_actions.dart` → une ligne au moins : l'entrée de debug lit la règle du jeu.

- [ ] **Step 6: Points de tests manuels** (spec §9.1 ; aucun ne se joue ici, l'orchestrateur les porte au fichier de tests manuels de la vague)

- **M9** — La carte du monde : monter le héros au niveau 5, sans draft de niveau en attente → le rideau de montée de niveau s'affiche ; pendant son fondu, les nœuds restent éteints derrière le voile, sans s'éclaircir. Le toucher, lui, est bloqué par le rideau : la garde de `_onNodeTap` n'est pas à la portée du joueur, le grep du Step 5 la vérifie.
- **M10** — La carte du monde : au niveau 5, avec un draft de niveau en attente, toucher le rideau, puis chaque fois qu'il revient → d'abord le draft de niveau ; au retour, le rideau toujours là ouvre l'évolution de *Châtiment*, puis celle de *Bouclier Sacré* ; après le dernier choix, le rideau disparaît et les nœuds s'ouvrent.
- **M11** — Le draft de niveau : faire un draft de niveau, puis un draft de boss → les rouleaux posés montrent l'emoji d'aujourd'hui (✨) : rien n'y change.
- **M12** — L'écran d'évolution : l'ouvrir au niveau 5, en français puis en anglais → l'en-tête « Évolution de Châtiment », puis « Choisissez une évolution » ; en anglais, « Smite evolves ».
- **M13** — L'écran d'évolution : l'ouvrir au niveau 5, sans évolution prise → trois rouleaux, chacun son nom, sa description et « MINEURE » : *Zèle* (« +2 dégâts »), *Égide*, *Ardeur*.
- **M14** — L'écran d'évolution : l'ouvrir au niveau 10, *Zèle* prise → trois rouleaux « MAJEURE », chacun une majeure de *Châtiment*.
- **M15** — L'écran d'évolution : l'ouvrir au niveau 15, *Zèle* et *Célérité* prises → le rouleau de *Zèle* dit « +4 dégâts », sa description au prochain niveau, et en dernière ligne « Niveau 1 → 2 ».
- **M16** — L'écran d'évolution : regarder les rouleaux tourner, puis s'arrêter → aucune icône pendant la rotation ; rouleau arrêté, l'icône de l'évolution à sa couleur au-dessus du nom (*Zèle* : le marteau rouge) ; une majeure dans un anneau de sa couleur.
- **M17** — L'écran d'évolution : toucher un rouleau posé, puis entrer en combat → l'écran se ferme et la carte revient ; en combat, la tuile porte la puce de l'évolution choisie.
- **M34** — Le menu de debug : dans une run lancée par « Run Debug », hors combat, ouvrir l'onglet Héros, section « Évolutions de signature » ; poser puis retirer des évolutions de *Châtiment*, puis de *Frappe Téméraire* (Berserker) ; entrer en combat → pour chaque signature, ses évolutions prises dans l'ordre (« zeal:2, sentence:1 ») ou « aucune » ; un bouton par évolution que le prochain palier admet — sans évolution, les trois mineures seules ; après une mineure, les quatre majeures ; une majeure prise, ou exclue (*Célérité* et *Dévastation*), n'est plus proposée ; « Retirer les évolutions » vide la liste ; le niveau du héros ne bouge pas ; en combat, la tuile porte ce qui est posé.

- [ ] **Step 7: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(evolutions): l ecran a trois rouleaux et le rideau de la carte`.

---

### Task 8 (interface): La tuile de combat — la bande d'icônes, le badge, les puces, la barre

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 9. Ce que le joueur voit : la tuile ne montre plus de texte au repos — sous l'en-tête, une icône chiffrée par effet de la signature évoluée, trois par ligne, centrées ; le badge « Niv. n » en ambre au bout de la ligne du type ; la rangée des puces d'évolution sous la bande ; le coût et la cible évolués ; la colonne reste à mi-hauteur tant qu'elle tient dans sa bande.

**Files:**
- Modify: `lib/ui/widgets/hud/signature_bar.dart:1-439` ; `lib/ui/widgets/hud/combat_side_panels.dart:10-23` (deux constantes), `:71-75` (`bottom: statusPanelBottom`) ; `lib/ui/widgets/hud/combat_top_bar.dart:7` (une constante) ; `lib/ui/screens/game_screen.dart:637-660` (`heroStats` au lieu de `currentMana`, `effectIcons`) ; `lib/l10n/app_fr.arb:176`, `lib/l10n/app_en.arb:446-451` (`levelLabel`), et après `signatureTurnsLeft` (`effectValuePercent`)
- Test: `test/widget/signature_bar_test.dart` — une fonction pure, `signatureBandPlacement` ; le fichier ne garde que des fonctions pures depuis le tri du 04/11, sans harnais. Aucun test d'écran (D77) ; `signature_tile_test.dart`, supprimé par le tri, n'est pas recréé

**Interfaces:**
- Consumes : `SignatureInstance.asCard`, `cost`, `level`, `taken`, `effectLines` (Task 3) ; `EffectIconTable`, `GameDataRegistry.effectIcons`, `effectVisualsOf` (Task 6) ; `EvolutionIcon` (Task 7) ; `EffectResolver.canAfford` (`effect_resolver.dart:113-118`).
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

  - `SignatureBar` : `final EntityStats heroStats` **remplace** `currentMana` ; `final EffectIconTable effectIcons` (défaut vide ; `GameScreen` passe `gameData.effectIcons`) ; `affordable: EffectResolver.canAfford(signature.asCard, heroStats)` (A10, point reporté de `:114`). La colonne n'est plus posée par `Align` mais par une mise en page propre à la barre (PN18, qui remplace PN10) : `_SignatureBandLayout extends SingleChildRenderObjectWidget` et son `RenderBox` (`RenderObjectWithChildMixin<RenderBox>`) — taille `constraints.biggest` ; l'enfant unique (la colonne et son invite pendante, inchangées) contraint en largeur seulement (`maxWidth` moins 20) ; **dans `performLayout`**, `(scale, top) = signatureBandPlacement(available: size.height, natural: child.size.height)` et la transformation `Matrix4.translationValues(20, top, 0) * Matrix4.diagonal3Values(scale, scale, 1)`, comme `map_screen.dart:367-368` (le `..scale` de `vector_math` est déprécié, `deprecated_member_use`), gardée ; `paint` par `pushTransform`, `applyPaintTransform` et `hitTestChildren` (`addWithPaintTransform`) par la même ; `hitTestSelf` faux. La transformation est connue dès la mise en page — ce que le calque de la Task 9 exige (`OverlayPortal.overlayChildLayoutBuilder` lit la transformation de la tuile pendant la mise en page, quand `Flow` ne l'établit qu'à la peinture). `H` est la hauteur que le `Positioned.fill` donne, jamais `MediaQuery` ; une tuile réduite répond au toucher.
  - `_SignatureTile` lit la signature évoluée : le médaillon `signature.cost` ; le toucher d'une tuile disponible arme si `signature.asCard.data.target == CardTarget.singleEnemy`, joue sinon. **La description quitte la tuile** (`:268-276`, PN12 (d)). La `ValueKey('signature-tile-<id>')` du cadre (`:367`), qu'aucun test ne lit plus depuis le tri du 04/11, n'est pas reprise (D77 : aucune clé de test).
  - **La bande** (A40), sous l'en-tête (médaillon, nom, type et badge) : une cellule par entrée de `signature.effectLines`, dans l'ordre, trois par ligne ; chaque ligne centrée dans la largeur intérieure de la tuile — 154 px sur l'étroite, 204 sur la large —, et réduite d'un bloc si elle est plus large (`FittedBox`, `BoxFit.scaleDown`) : jamais de coupure. Une cellule : l'icône `effectVisualsOf(effectIcons, line.kind)`, 24 px sur l'étroite, 28 sur la large ; puis, 4 px plus loin, sa valeur en gras, 12 et 14 px, `Colors.white` — `'${line.value}'`, le critique par `effectValuePercent(value)`, rien pour `target:allEnemies` ; la durée jamais ; 8 px entre deux cellules, 4 entre deux lignes. En recharge et sans le mana, icônes et valeurs en `Colors.white38`.
  - Le badge (A36, PN13) : au bout de la ligne du type (`:257-266`, le type passe dans un `Flexible`), `levelLabel(signature.level)`, absent au niveau 0 ; même taille que le type, gras ; `Colors.amberAccent` disponible et armée, `Colors.white38` en recharge et sans le mana ; inactive, l'ambre, toute la tuile à 0,45.
  - La rangée des puces (A37) : sous la bande, dans la colonne de texte, à droite du médaillon (128 et 178 px, A37 ; spec A40), au-dessus du compte de recharge, dès la première évolution — un `Row` de `EvolutionIcon` par paire de `taken`, dans l'ordre, `size` 16 sur la tuile étroite, 18 sur la large, 2 d'écart ; `level` de la paire ; `color: Colors.white38` en recharge et sans le mana, nulle sinon. Inactive : toute la tuile à 0,45, comme aujourd'hui.
  - ARB : `levelLabel` réécrite, « Niv. {level} » / « Lvl. {level} » ; `effectValuePercent` (`value` int) « +{value} % » / « +{value}% » (spec §6.1, mot pour mot).
  - `game_screen.dart` passe `heroStats: runState.heroStats` et `effectIcons: gameData.effectIcons`.

- [ ] **Step 1: Écrire le test qui échoue**

`signature_bar_test.dart` — le fichier, sans harnais depuis le tri du 04/11, garde ses fonctions pures ; aucun test d'écran (D77) :
- `signatureBandPlacement : centree, decalee, reduite, plancher` — `(800, 176)` → `(1, 312)` ; `(800, 500)` → `(1, 100)` ; `(800, 600)` → `scale` `closeTo(520 / 600, 1e-9)`, `top` 80 ; `(400, 176)` → `(0.75, 80)`, et `80 + 0.75 × 176 > 400 − 200`.

La règle d'accessibilité de la tuile, le coût évolué, est gardée par la Task 3 (« canAfford lit le cout evolue ») ; le câblage, par le grep du Step 5.

- [ ] **Step 2: Lancer le test, constater l'échec**

Run: `flutter test test/widget/signature_bar_test.dart`
Expected: échec de compilation — `signatureBandPlacement` n'existe pas.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n` ; les constantes ; la fonction de placement et la mise en page de la barre ; la tuile, sa bande, son badge, ses puces ; `game_screen.dart`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/unit/combat_signature_test.dart test/unit/signature_instance_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1602** (1601 + 1). `git grep -n "currentMana >= signature.cost" -- lib` ne rend rien ; `git grep -n "canAfford(signature.asCard" -- lib/ui/widgets/hud/signature_bar.dart` rend une ligne.

- [ ] **Step 6: Points de tests manuels** (spec §9.1 ; aucun ne se joue ici, l'orchestrateur les porte au fichier de tests manuels de la vague)

- **M18** — Le combat, la tuile : regarder *Châtiment* sans évolution, puis poser par l'entrée de debug (M34) `zeal`, `sentence`, `zeal` (`zeal:2`, `sentence:1`) ; dans les quatre états, en français puis en anglais → sans évolution, aucun « Niv. » ; avec, « Niv. 3 » (« Lvl. 3 ») au bout de la ligne du type, sur la même ligne ; ambre disponible et armée, gris pâle en recharge et sans le mana ; sur la tuile étroite, un nom long (« Surtension de Mana ») ne passe pas en « … » à cause du badge.
- **M19** — Le combat, la tuile : poser par l'entrée de debug `zeal`, `sentence`, `zeal`, `haste`, `aegis` ; puis, après « Retirer les évolutions », les sept évolutions de *Châtiment* en alternant les paliers (`zeal`, `haste`, `aegis`, `sentence`, `ardor`, `radiance`, `zeal`, `devotion`), sur une fenêtre étroite (≈ 400 px de large) et une large → une puce par évolution distincte, dans l'ordre de première prise, sous la bande : *Zèle* nue avec un petit « 2 » en bas à droite, *Sentence* et *Célérité* dans un anneau, *Égide* sans chiffre ; sept puces tiennent sur les deux tuiles, sans débordement.
- **M20** — Le combat, la tuile : regarder *Châtiment* sans évolution ; poser par l'entrée de debug `zeal`, `sentence`, `zeal` ; puis `radiance` et `ardor` de plus → plus aucun texte de description au repos ; deux icônes (« 6 », « 4 »), puis trois (« 10 », « 4 », « 1 ») sur une ligne, sans durée (« 2 tours ») ; puis cinq, trois sur la première ligne et deux sur la seconde : *Rayonnement* sans chiffre, puis le critique à « +5 % ».
- **M21** — Le combat, la tuile : poser par l'entrée de debug les six verbales de *Surtension de Mana* (§3.7), en alternant les paliers — une mineure déjà prise se reprend pour passer un palier mineur —, sur une fenêtre étroite puis large → huit icônes en trois lignes, chaque ligne centrée dans la tuile, la ligne de deux comprise ; l'icône de la bande plus grande que la puce ; rien ne déborde.
- **M22** — Le combat, la tuile : sur la tuile étroite, poser par l'entrée de debug `zeal`, `haste`, `ardor` (*Célérité*, chiffrée, n'ajoute pas d'icône) ; puis, après « Retirer les évolutions », `zeal`, `haste`, `zeal`, `devotion`, `aegis`, `aegis`, `aegis`, `ardor` — les deux majeures chiffrées prises, le palier majeur admet les mineures (Q6) → la ligne (« 8 », « 4 », « +5 % », puis « 10 », « 10 », « +5 % ») tient, ou se réduit d'un bloc : jamais coupée, jamais en débordement ; sur la large, elle tient sans réduction.
- **M23** — Le combat, la tuile : poser par l'entrée de debug `zeal`, `sentence`, `zeal` ; mettre la tuile en recharge, puis à 0 mana (onglet Combat), puis la regarder hors du tour du joueur → en recharge et sans le mana, icônes et valeurs de la bande, puces, anneaux, chiffres et badge en gris pâle ; disponible et armée, à leurs couleurs (la puce de *Zèle* rouge) ; inactive, toute la tuile à demi effacée.
- **M24** — Le combat, la tuile : poser par l'entrée de debug `zeal`, `devotion`, mettre le mana à 0 ; puis, après « Retirer les évolutions », `zeal`, `radiance`, et toucher *Châtiment* → le médaillon dit 0 et la tuile reste disponible à 0 mana ; avec *Rayonnement*, le toucher joue aussitôt sur tous les ennemis, sans demander de cible.
- **M30** — Le combat, la barre : au niveau 0, sur une fenêtre de 1280 × 800 → la colonne des deux tuiles est à mi-hauteur, comme en `0.5.6`, en face du bouton de fin de tour.
- **M31** — Le combat, la barre : sur une fenêtre basse (≈ 400 px de haut), en fin de run (beaucoup d'évolutions), toucher *Châtiment* → la colonne se réduit (aux trois quarts au plus), reste sous la barre du haut et peut sortir par le bas, peinte au-dessus du HUD ; la tuile réduite s'arme, et l'invite « Choisissez une cible » reste visible sous la colonne.

- [ ] **Step 7: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(combat): la tuile de signature en icones, son badge et ses puces`.

---

### Task 9 (interface): La liste de l'appui long — les phrases par sorte, le calque

Tâche d'interface : l'orchestrateur trie les mineurs visibles avant la Task 10. Ce que le joueur voit : tant qu'il reste appuyé sur une tuile, elle déroule par-dessus ses voisines la liste de ses effets — l'icône, puis sa phrase (« Inflige 10 dégâts », « Applique 1 Faiblesse pendant 2 tours ») — ; relâcher la replie ; un appui court joue ou arme comme avant.

**Files:**
- Create: `lib/game/services/effect_line_texts.dart`, `test/unit/effect_line_texts_test.dart`
- Modify: `lib/ui/widgets/hud/signature_bar.dart` (le geste, le calque) ; `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` (après `effectValuePercent`)
- Test: `test/unit/referential_integrity_test.dart` ; aucun test d'écran (D77 : le geste, le calque et la liste, aux points de tests manuels)

**Interfaces:**
- Consumes : `SignatureInstance.effectLines`, `EffectLine` (Task 3) ; `EffectIconTable`, `effectVisualsOf` (Task 6) ; la tuile, sa bande et la mise en page de la barre (Task 8).
- Produces :
  - ARB, les treize clés `effectLine…` de spec §6.1, **mot pour mot**, pluriels d'ICU compris, sans point final : `effectLineDamage`, `effectLineArmor`, `effectLineHeal`, `effectLineDraw`, `effectLineGainMana` (`amount` int) ; `effectLineMight`, `effectLineMightRegen`, `effectLineArmorRegen`, `effectLineWeakness`, `effectLineVulnerable`, `effectLineBurn` (`amount`, `duration` int) ; `effectLineCrit` (`amount` int) ; `effectLineAllEnemies`.
  - `abstract final class EffectLineTexts` (`lib/game/services/effect_line_texts.dart`, à côté de `CardRuleTexts`) — `static String? phrase(AppLocalizations l10n, EffectLine line)`, la seule écriture des lignes (A41) : `damage`, `armor`, `heal`, `draw`, `gain_mana`, `status:might`, `status:might_regen`, `status:armor_regen`, `status:weakness`, `status:vulnerable`, `status:burn`, `crit`, `target:allEnemies` vers leur clé, à la valeur et, pour un statut, à la durée de la ligne ; `null` pour toute autre sorte (`status:poison`, `status:freeze`, `status:shock` compris) — la ligne montre alors l'icône seule.
  - Le geste (A42), sur le `GestureDetector` de la tuile (`signature_bar.dart:324-326`), comme `map_node_widget.dart:140-142` : `onLongPressStart` ouvre la liste, `onLongPressEnd` et `onLongPressCancel` la replient ; `onTap` garde `_onTap` (`:215-232`) ; un appui long ne joue, n'arme ni ne désarme. la liste s'ouvre dans tous les états de la tuile, inactive comprise : le geste ne lit pas l'état.
  - Le calque (A42, PN19) : un `OverlayPortalController` dans `_SignatureTileState` ; un `OverlayPortal.overlayChildLayoutBuilder` enveloppe le `MouseRegion` de la tuile (`:320`). Son enfant de calque : `IgnorePointer` → `CustomSingleChildLayout` (délégué privé qui reçoit l'`OverlayChildLayoutInfo`) → `Transform.scale(scale: s, alignment: Alignment.topLeft)` → la tuile déployée, à la largeur `info.childSize.width`, hauteur libre. `s = info.childPaintTransform.getMaxScaleOnAxis()` ; le haut de la tuile dans le calque, `o = MatrixUtils.transformPoint(info.childPaintTransform, Offset.zero)` ; la hauteur posée de la liste, `s × <hauteur naturelle de l'enfant>`, que le délégué lit dans `getPositionForChild` : la liste s'ouvre vers le bas depuis `o` si `o.dy + s × hauteur ≤ info.overlaySize.height`, sinon vers le haut, son bas au bas de la tuile (`o.dy + s × info.childSize.height`). La colonne de la barre ne change ni de hauteur, ni d'échelle, ni de place. La tuile retirée, l'`OverlayPortal` replie sa liste.
  - La tuile déployée (A42) : la même construction que la tuile — un `_body({required bool expanded})` de `_SignatureTileState`, sans clé de test (D77) — : son cadre à sa largeur, sa bordure et la pulsation armée, son gris en recharge et sans le mana son en-tête, sa rangée de puces et son compte de recharge ; la liste à la place de la bande : une ligne par entrée de `effectLines`, dans l'ordre — l'icône `effectVisualsOf(…)`, 16 px sur les deux tuiles, **toujours à sa couleur** ; puis, 4 px plus loin, `EffectLineTexts.phrase(l10n, line)` (rien si `null`), à la taille de l'ancienne description (10 et 11 px), `Colors.white70`, `Colors.white38` en recharge et sans le mana sur autant de lignes qu'il lui faut. le calque ne prend pas l'opacité 0,45 de la tuile inactive.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/effect_line_texts_test.dart` *(nouveau ; une vraie `AppLocalizations`, comme `card_rule_texts_test`)* :
- `les treize sortes ont leur phrase, en francais et en anglais` — `(damage, 10)` « Inflige 10 dégâts » / « Deal 10 damage » ; `(armor, 4)` « Donne 4 d'Armure » / « Gain 4 Block » ; `(status:weakness, 1, 2)` « Applique 1 Faiblesse pendant 2 tours » / « Apply 1 Weakness for 2 turns » ; `(crit, 5)` « +5 % de critique » / « +5% critical chance » ; `(target:allEnemies)` « Touche tous les ennemis » / « Hits all enemies » ; et les huit autres, chacune non nulle dans les deux langues.
- `les pluriels se lisent sur la valeur et la duree` — `(draw, 1)` « Pioche 1 carte », `(draw, 2)` « Pioche 2 cartes » ; `(status:might, 2, 1)` « Gagne 2 Puissance ce tour-ci », `(status:might, 2, 2)` « Gagne 2 Puissance pendant 2 tours » ; `(status:burn, 1, 1)` « Applique 1 Brûlure pendant 1 tour ».
- `aucune phrase ne finit par un point` — les treize, dans les deux langues.
- `hors des treize sortes, aucune phrase` — `status:poison`, `status:freeze`, `status:shock` : `null`.

`referential_integrity_test.dart` :
- `chaque sorte que produit une signature livree ou une evolution de son pool a sa phrase (A41)` — sur `effectLines` de chaque signature, toutes évolutions prises : `EffectLineTexts.phrase` non nulle, en français et en anglais.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/effect_line_texts_test.dart test/unit/referential_integrity_test.dart`
Expected: échec de compilation — `EffectLineTexts` et les clés `effectLine…` n'existent pas.

- [ ] **Step 3: Implémenter** — ARB et `flutter gen-l10n` ; `EffectLineTexts` ; le geste, la tuile déployée et le calque.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: la commande du Step 2, puis `flutter test test/widget/signature_bar_test.dart test/unit/combat_signature_test.dart`.
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1607** (1602 + 4 + 1).

- [ ] **Step 6: Points de tests manuels** (spec §9.1 ; aucun ne se joue ici, l'orchestrateur les porte au fichier de tests manuels de la vague)

- **M25** — Le combat, la liste : rester appuyé sur *Châtiment* (`zeal:2`, `sentence:1`, posées comme en M18), au-dessus de *Bouclier Sacré* → la liste s'ouvre vers le bas, par-dessus la tuile voisine : une ligne par icône de la bande, dans son ordre, l'icône puis sa phrase (« Inflige 10 dégâts », « Donne 4 d'Armure », « Applique 1 Faiblesse pendant 2 tours ») ; la colonne des tuiles ne bouge ni ne change de taille.
- **M26** — Le combat, la liste : relâcher ; rouvrir et glisser le doigt hors de la tuile sans le lever ; Android seulement, rouvrir et tirer le volet des notifications → relâcher replie la liste ; le glissement ne la replie pas ; le geste du système la replie (sous Windows, ce dernier cas ne se provoque pas).
- **M27** — Le combat, la liste : sur une fenêtre basse (≈ 400 px de haut, celle de M31), poser par l'entrée de debug les sept évolutions de *Bouclier Sacré* en alternant les paliers (`ward`, `haste`, `mercy`, `consecration`, `resolve`, `inspiration`, `ward`, `lasting_aegis`), puis rester appuyé sur *Bouclier Sacré*, sous *Châtiment* → la liste s'ouvre vers le haut, son bas au bas de la tuile.
- **M28** — Le combat, la liste : l'ouvrir en recharge, sans le mana, disponible, puis hors du tour du joueur — l'appui tenu pendant que l'ennemi joue, un tour court —, sur une fenêtre étroite puis large → elle s'ouvre dans les quatre états ; en recharge et sans le mana, cadre et en-tête gris, phrases en gris pâle, icônes de la liste à leurs couleurs ; disponible, phrases en blanc atténué ; inactive, la liste à pleine opacité ; les icônes de la liste petites (16 px) sur les deux tuiles.
- **M29** — Le combat, la tuile : toucher brièvement une signature sur soi, une signature à cible, une signature armée, une signature sans le mana ; puis rester appuyé sur chacune → l'appui court joue, arme, désarme, ou refuse faute de mana, comme en `0.5.6` ; l'appui long ne joue, n'arme ni ne désarme rien.

- [ ] **Step 7: Commit**

`git add` par chemin (les trois `app_localizations*.dart` compris), puis `git commit` — `feat(combat): la liste des effets d une signature a l appui long`.

---

### Task 10: L'éditeur de contenu — le descripteur des évolutions

**Files:**
- Modify: `lib/services/content_editor/entity_descriptor.dart:298-329` (le descripteur de la signature)
- Test: `test/unit/content_editor/entity_descriptor_test.dart` (`:130-138`, `:437`), `test/unit/content_editor/entity_validator_test.dart` (groupe `une signature (spec P-43 E4, §8)`, `:96`)

**Interfaces:**
- Consumes : `EvolutionTier`, `SignatureEvolutionData.targetNames`, `deltaTypeNames` (Task 2) ; le gabarit à évolution (Task 2).
- Produces (spec §7, la ligne marquée 3) :
  - `requiredKeys` : `{'cost', 'cooldown', 'type', 'evolutions'}` (PN15 : la famille 3 nomme l'absence avant `construct`).
  - `enumKeys` gagne `'evolutions[].tier': _names(EvolutionTier.values)`, `'evolutions[].target': SignatureEvolutionData.targetNames`, `'evolutions[].deltas[].type': SignatureEvolutionData.deltaTypeNames` — lus sur le modèle, jamais recopiés.
  - `vocabularyKeys` gagne `'evolutions[].icon'` et `'evolutions[].color'` — admis si un fichier livré ou le gabarit les emploie déjà, la forme d'`icon` et `color` des runes (`:437-455`), sans lire les tables de `lib/ui/`. Le commentaire le dit, et que le test d'intégrité (Task 6) exige que chaque évolution livrée ait les siens, connus d'`effectIcons` et d'`effectColors`.

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

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1612** (1607 + 2 + 3).

- [ ] **Step 6: Commit**

`git add` par chemin, puis `git commit` — `feat(editeur): les evolutions de signature`.

---

### Task 11: Vérification finale (orchestrateur)

Aucun fichier modifié : des commandes, jouées par l'orchestrateur, sans agent.

- [ ] **Step 1: L'analyse** — `dart analyze` → `No issues found!`
- [ ] **Step 2: La suite** — `rm -rf build/unit_test_assets` puis `flutter test` → `All tests passed!`, **1612**.
- [ ] **Step 3: Les tests nommés de la partie** — `flutter test test/unit/save_service_test.dart test/unit/signature_evolution_data_test.dart test/unit/signature_evolution_rules_test.dart test/unit/signature_instance_test.dart test/unit/referential_integrity_test.dart test/unit/debug_actions_test.dart test/widget/signature_bar_test.dart --reporter expanded` → verts, nommément : les neuf du groupe « les evolutions de signature (spec §8) », « canAfford lit le cout evolue : a 0 mana, Chatiment est refusee, avec Devotion acceptee », « hasPendingChoice : un draft ou une evolution en attente », « signatureBandPlacement : centree, decalee, reduite, plancher », « takeSignatureEvolution suit le palier : une majeure refusee d abord, admise apres une mineure », « une mineure reprise monte a sa place ; une majeure prise ou exclue est refusee », « les six pools sont ceux de spec 3.7 : trois mineures, quatre majeures (Q6) », « une majeure exclue n est pas offerte, dans les deux sens », « majeures epuisees : trois mineures au palier majeur (Q6, repli) », « une evolution sans cooldown qui vise une seule sorte porte son icon et sa color (A39) », « chaque sorte que produit une signature livree ou une evolution de son pool a sa phrase (A41) » et, « les faces des cartes et le document donnent la meme icone et la meme couleur a chaque sorte commune ».
- [ ] **Step 4: Les greps de la spec (§11, « Ce que le vérificateur contrôle »)**
  - `git grep -n "onDamagingCardPlayed" -- lib test assets` → rien (D34) ; `grep -c '"trigger": "onAttackPlayed"' assets/data/passives/mage_mark.json` → `1`.
  - `ls assets/data/cards/focus.json assets/data/cards/demon_form.json` → deux « No such file » ; `ls assets/data/cards/rage/demon_form.json` → le fichier.
  - `git diff main -- tool/simulations` → vide.
  - `dart run tool/sync_assets.dart --check` → code de sortie 0.
- [ ] **Step 5: Les greps propres à la partie 3**
  - `git diff --name-only 996421a -- assets/data` → exactement les six `classes/*/skills/*.json` et `effect_icons.json`.
  - `grep -l '"evolutions"' assets/data/classes/*/skills/*.json | wc -l` → `6`.
  - `git grep -n "evolutionIcons\|evolutionColors\|signature_evolution_style" -- lib test` → rien : les tables sont `effectIcons` et `effectColors`, dans `lib/ui/widgets/effect_style.dart`.
  - `git grep -ln "effect_style.dart" -- lib` → `lib/ui/screens/signature_evolution_screen.dart`, `lib/ui/widgets/hud/signature_bar.dart` et `lib/ui/widgets/hud/status_effects_panel.dart` (aucun dans `lib/game/` ni `lib/models/`).
  - `git grep -n "effect_icons.json" -- lib/services/game_data_service.dart test/unit/entity_id_convention_test.dart CLAUDE.md` → une ligne au moins dans chacun ; `grep -o '"status:' assets/data/effect_icons.json | wc -l` → `9`.
  - `git grep -n "_getEffectVisuals\|_RendererEffectVisuals" -- lib` → rien ; `git grep -n "@visibleForTesting" -- lib/game/components/widgets/card_text_renderer.dart` → une ligne.
  - `git grep -n "maxLines: 2" -- lib/ui/widgets/hud/signature_bar.dart` → rien (la description a quitté la tuile).
  - D77 : `git diff --name-only --diff-filter=A 5fbbe63f -- test` → exactement `test/unit/signature_evolution_data_test.dart`, `test/unit/signature_evolution_rules_test.dart`, `test/unit/effect_icon_table_test.dart` et `test/unit/effect_line_texts_test.dart` ; `git diff 5fbbe63f -- test | grep -c '^+.*testWidgets('` → `0` ; `git grep -n "canAfford(signature.asCard" -- lib/ui/widgets/hud/signature_bar.dart` → une ligne ; `git grep -o "hasPendingChoice" -- lib/ui/screens/map_screen.dart | wc -l` → `3` (des lectures, pas des lignes) (le rideau, `_isNodeAvailable`, `_onNodeTap` ; `0` avant la tâche).
  - P-7 (a) : `git grep -n "SignatureEvolutionRules.admissible" -- lib/game/services/debug_actions.dart` → une ligne au moins.
  - `git grep -niE "vague 5" -- lib` → rien (les cinq commentaires au futur, `run_controller.dart:82`, `card_delta.dart:11`, `effective_card.dart:74`, `signature_instance.dart:11`, `:14`, sont au présent) ; `git grep -n "currentMana >= signature.cost" -- lib` → rien.
  - `git grep -n "package:flutter_riverpod\|package:flame\|package:flutter/" -- lib/game/systems/signature_evolution_rules.dart lib/models/signature_instance.dart lib/models/data/signature_evolution_data.dart lib/models/data/effect_icon_table.dart lib/models/data/effect_kind.dart` → rien (règle pure, couche données).
  - `git status --short` → seul le fichier d'orchestration, que l'orchestrateur tient ; aucun `generated_plugin*` ni `GeneratedPluginRegistrant.swift` modifié.
- [ ] **Step 6: Les points de tests manuels** — rien ne se joue ici : M7 à M34 (spec §9.1), réunis par les étapes « Points de tests manuels » des Tasks 2, 6, 7, 8 et 9, sont ceux que le fichier de tests manuels de la vague reprend pour le propriétaire (D77).
