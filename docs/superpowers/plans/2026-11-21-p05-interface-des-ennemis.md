# P-05 vague 1 — l'interface des ennemis en combat — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (méthode fixée par l'orchestrateur). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** rien ne change à ce que les ennemis font ; le joueur voit le panneau des intentions en trois colonnes, une seule barre de PV à la largeur de la carte avec un voile qui est la jauge de l'armure, deux languettes de statuts de part et d'autre des cartes (ennemis et héros) qui se déroulent au survol, et la fiche d'un ennemi qu'on touche.

**Architecture :** tout ce qui s'affiche se calcule par des fonctions pures (`ArmorVeil`, `IntentPips`, `StatusReadout`, `EnemySheetView`, `SheetPlacement`, `pickHoveredEntity`), testées sans écran ; la barre, les languettes, l'agrandissement et l'estompage sont des composants Flame attachés à leur carte ; le panneau et le cadre de la fiche sont des widgets du HUD. La fiche ouverte est un état d'affichage de `HerosDraftGame`, seul propriétaire, que `GameScreen` reflète en différé ; un `Listener` de l'écran, servi après Flame dans le même appui, ferme la fiche sauf si Flame vient de retenir le pointeur de cet appui. Aucun état Riverpod neuf, aucun modèle ne change.

**Tech Stack :** Flutter 3.41.6, Flame 1.38.2, Riverpod 2.x (`Notifier`), `flutter_test`, ARB + `flutter gen-l10n`.

**Spec :** `docs/superpowers/specs/2026-11-21-p05-interface-des-ennemis-design.md`, en entier — décisions B6 à B16 et B31 à B41 (§1.1, §1.2), arbitrages A1 à A16 (§1.3), découpage §10, contrôles §11, et « Pour le Review Focus du plan ». **Ne rouvrir aucun de ces arbitrages.**

Branche : `feat/v0.6.1-interface-des-ennemis`, sans en créer. Base de tests : **1866**. Total attendu à la fin : **1933**. Toute référence `fichier:ligne` est lue sur la branche à `3b3479cf` (seuls des documents ont bougé depuis `c2e2dacb`, où la spec a été écrite) ; les Tasks 4 et 5 désignent les endroits par symbole, leurs fichiers ayant bougé dans les tâches précédentes.

**Ordre d'exécution : 1 → 2 → 3 → 4 → 5 → 6 → 7.** Task 2 dépend de 1 ; Task 3 de 1 ; **Task 4 de 1 et de 3** (elle complète `combat_tap_forwarding_test.dart` que la 3 crée, et retouche après elle `EnemyCard.onLoad`) ; Task 5 de 1, 3 et 4 ; Task 6 de 2 et 3.

---

## Contraintes globales

Recopiées du fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §3.5) ; elles valent pour chaque tâche :

- `dart analyze` rend `No issues found!` et `flutter test` est entièrement vert **à la fin de chaque tâche**.
- Ne rien pousser, n'ouvrir aucune PR, ne rien commiter sur `main`, n'invoquer aucun skill de livraison — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync`.
- **Jamais `dart format`** ; Write / Edit plutôt que heredoc.
- Les fichiers que `flutter` régénère sont suivis par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification ; les restaurer par `git restore` s'ils apparaissent modifiés. **`git add` par chemin, jamais `git add -A`** : l'arbre porte aussi deux fichiers modifiés par le propriétaire, `docs/.obsidian/workspace.json` et `docs/possible_upgrades/upgrade_ideas.md`, à ne jamais indexer.
- Après toute retouche d'un ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit.
- Après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge (aucun n'est prévu ici : §6.1 de la spec, aucune donnée ne change).
- Tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` (aucun n'est prévu).
- Les trois couches de `CLAUDE.md` ne se mélangent pas : Flame lit l'état et ne calcule aucune règle ; aucun widget Flutter dans Flame, aucun composant Flame dans le HUD (la fiche n'importe que des fichiers purs). Pas de code sans lecteur, pas de code mort, pas de bloc commenté.
- Commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session de l'agent qui commite fournit.
- Ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/`.
- **Aucun test d'écran neuf** (ADR-113) : aucun `testWidgets(` ajouté ; ce que verrait un écran passe aux lignes de tests manuels (fin du plan).
- Aucun fichier de `lib/models/`, `lib/game/controllers/`, `lib/game/services/` ni `assets/data/` ne change (spec §11).

## Review Focus

Les cinq modes d'échec que la spec implique et qu'aucun test ne garde encore ; chacun a ses tests dans la tâche nommée. Ils regroupent les dix-sept trous remontés par les vérifications de la spec (« Pour le Review Focus du plan »).

1. **La fiche se ferme sur l'appui qui devait la garder, ou reste ouverte sur un appui ailleurs** (A10, A12) — le pointeur retenu doit valoir pour un seul appui, et ni la carte focalisée ni la signature ne retiennent rien ; un bouton du HUD peint au-dessus de la barre ferme. → **Task 5**, tests `le pointeur retenu garde la fiche une fois, puis il est oublie`, `un autre pointeur ferme la fiche`, `garder la meme fiche retient aussi le pointeur`, `ni la carte focalisee ni la signature ne retiennent le pointeur` ; lignes manuelles T5-a, T5-b, T5-c.
2. **Le cadre ne suit pas sa carte, ou un `setState` part pendant un `build`** (A12) — la réémission au replacement, son absence sans fiche ou ennemi parti, le reflet différé. → **Task 5**, tests `replacer les ennemis reemet le rectangle de la fiche ouverte`, `replacer les ennemis sans fiche, ou fiche d un ennemi parti, ne rappelle rien`, `une reconstruction a taille inchangee ne reemet rien, un vrai redimensionnement reemet`, les deux tests de `closeInspectionIfStale` ; lignes manuelles T5-d, T5-h.
3. **La bordure ou la taille de la carte ouverte défaite par un autre chemin** (A11) — la sélection, la surbrillance, une secousse en cours, un redimensionnement pendant l'agrandissement. → **Task 5**, test `la selection et la surbrillance ne touchent pas la fiche, qui ne touche pas la selection` — **il ne vérifie que les drapeaux** `isInspected` et `isSelected`, par `setSelection`, `highlightEnemy` (qui n'écrit que `setSelection`, `heros_draft_game.dart:309-315`) et `setHighlight` : la bordure dessinée n'est gardée que par M12 (« bordée d'or ») et T5-i, la taille et la place par T5-g, T5-h et M17.
4. **Un appui ou un survol qui tombe dans un trou de la zone d'une carte** (A3, A8, A9, B39) — la bande y −4 à 0, la languette au repos, le renvoi de la barre et des languettes (celles du héros comprises), le survol sous un pointeur immobile, le bord de l'écran. → **Task 1** (`entity_hover_test` : bande, languette au repos), **Task 3** (`la barre renvoie son appui a sa carte, pointeur compris`, sa zone), **Task 4** (`les languettes renvoient leur appui a leur carte`, les trois tests de `unfoldsInward`) ; lignes manuelles T4-a, T4-b, T4-c (le renvoi vers `HeroCard.onTapDown`, qu'aucun test ne garde).
5. **Un texte ou un ton faux dans les pastilles et les languettes** (A5, A8, B32, B33) — la Foudre en attente et active en jaune, sous le seuil en rouge ; le compteur d'un passif nommé en anglais ; « En attente... » en anglais ; le calcul `_visuals` resté en double. → **Task 1** (`status_readout_test`, `intent_pips_test`), **Task 2** (contrôle `git grep`).

## Décisions du plan

Classe T, tranchées par les filtres de §5 du fichier d'orchestration.

- **D1 — Les tests de contrôleur de la fiche donnent au jeu un canevas** (*filtre 8*) : `baseScale` lit `game.scaleFactor`, qui lit `FlameGame.size`, lequel **lève une assertion tant que le jeu n'a pas de taille** (`flame/lib/src/game/game.dart:193`, mesuré le 21/11 dans un clone). `setUp` appelle `game.onGameResize(Vector2(1280, 800))` (`scaleFactor` = 1), et les cartes jamais montées reçoivent leur jeu par le mutateur `HasGameReference.game` (`flame/lib/src/components/mixins/has_game_reference.dart:24`). Les effets visuels ne jouent que sur une carte chargée (`isLoaded`).
- **D2 — Un seul rappel de pointeur** : `onTapEnemy` devient `void Function(EnemyCard enemy, int pointerId)` (Task 5) ; la barre et les languettes ne connaissent pas ce type, elles renvoient le `TapDownEvent` au `onTapDown` de leur carte (Tasks 3, 4), qui seul le décompose (*filtre 5*).
- **D3 — La zone d'une carte de combat est une seule propriété, `CombatEntity.zone`** (`List<Rect>`, canevas) : le rectangle continu de `bodyLocalRect` plus le rectangle courant de chaque languette non vide ; `zoneContains` la lit pour `_livingEnemyAt`, l'arbitre du survol et `findHoveredEnemy` (*filtre 5*, spec §4.5).
- **D4 — Les fonctions de survol et de zone sont des fonctions de haut niveau** dans `lib/game/systems/entity_hover.dart`, comme `pickHoveredCard` dans `hand_geometry.dart` ; `unfoldsInward` (B39), que le Review Focus veut pure, s'y ajoute en Task 4 (*filtre 6*).
- **D5 — `compactValue` reste sur `EnemyIntentsPanel`** (son test ne change pas, spec §9) ; `IntentPips` l'appelle. L'import réciproque entre `intent_pips.dart` et `enemy_intents_panel.dart` est permis en Dart (*filtre 8*).
- **D6 — Le nom d'un statut** : `l10n.statusName(id)` s'il rend autre chose que l'id (le cas `other{{id}}` rend l'id), sinon `status.name` ; `counterId` passe avant les deux (*filtre 5*, spec §4.3).
- **D7 — La Foudre chargée de l'exemple est à 3 points** : `bonusPerPoint` vaut 2 (`assets/data/charges/shock.json`), donc « Chargé 3 » et « +6 par coup » ; la spec §9 citait « Chargé 4 » et « +6 par coup », qui ne viennent pas du même état — corrigée en « Chargé 3 » (*filtre 8*).
- **D8 — Un ennemi mort ou mourant que la fiche quitte ne rejoue ni agrandissement ni descente** : `animateInspection` retire les effets d'échelle de la carte, et retirerait celui de la mort (`state_sync_system.dart:115-123`), dont le `onComplete` retire la carte du jeu (*filtre 1*). **C'est une garde défensive, qu'un geste ordinaire n'atteint pas** : un ennemi mourant n'ouvre rien, jouer une carte la focalise et ferme la fiche, le Poison et le Feu se résolvent en phase ennemie, fiche fermée ; seuls deux doigts dans la même image l'atteignent (l'un joue une carte visant tous les ennemis, l'autre ouvre la fiche d'un ennemi que l'état suivant rend mourant).
- **D9 — Le cadre de la fiche lit la taille de l'écran par `MediaQuery.sizeOf(context)`** : le `GameWidget` est en `Positioned.fill` dans le `Stack` du `Scaffold` sans barre d'application (`game_screen.dart:566-578`), les deux repères coïncident (*filtre 6*).
- **D10 — Chaque reconstruction de `GameScreen` rappelle `onGameResize` : la fiche ne doit ni s'y couper ni s'y rappeler** (*filtre 1*). `GameWidget(game: _game)` est un widget neuf à chaque `build` (`game_screen.dart:573-578`) ; son `LayoutBuilder` relance son constructeur (`widgets/layout_builder.dart:184-185`), qui appelle `onGameResize(size)` puis `update(0)` (`flame/lib/src/game/game_widget/game_widget.dart:402-416`), sans garde d'égalité sur la taille (`flame/lib/src/game/game.dart:186-188`, `components/core/component.dart:970-979`) — pas seulement au redimensionnement. Or `ScaleEffect.to` ajoute à chaque image sa part d'un écart calculé au départ (`flame/lib/src/effects/scale_effect.dart:50-52`, `:72-73`) : poser l'échelle pendant ses 0,15 s fausse l'arrivée (mesuré sur un composant nu : 1,167 au lieu de 1,0). D'où `EnemyCard._snapScale()`, appelé par le mutateur de `scaleMultiplier` et par `onGameResize` : **une cible inchangée laisse l'agrandissement en cours aller à son terme** ; une cible neuve (vrai redimensionnement) l'arrête et pose l'échelle. Sans agrandissement en cours, l'échelle est posée comme aujourd'hui ; les réactions aux coups en cours gardent leur comportement d'aujourd'hui (hors du lot).
- **D11 — `animateInspection` retire aussi les séquences porteuses d'une échelle** (*filtre 1*) : les réactions aux coups sont des `SequenceEffect` dont les `ScaleEffect` sont des enfants de la séquence (`flame/lib/src/effects/sequence_effect.dart:70` ; `combat_entity.dart:38-52`, `:66-77`, `:294-305`) ; `children.whereType<ScaleEffect>()` ne les voit pas, et les deux échelles s'additionnent — mesuré : ouvrir 0,05 s après un coup finit à 1,041 au lieu de 1,25, fermer à 0,851 au lieu de 1,0 ; avec la règle `_carriesScale`, 1,25 et 1,0. La séquence d'un bouclier retirée ne rend plus sa bordure (`combat_entity.dart:47-49`) : `animateInspection` la rafraîchit.
- **D12 — Le cadre ne connaît pas `EnemyInspection`** : `EnemySheetPanel` reçoit `enemyId` et `card` (un `Rect`) ; seul `GameScreen`, qui construit déjà le jeu, lit le type de `heros_draft_game.dart` (CLAUDE.md : aucune référence Flame dans le HUD ; le cadre lit `combatProvider`, couche Riverpod).
- **D13 — `CombatEntity.addStatusTabs(void Function(TapDownEvent event) onTap)`** : chaque carte passe son propre `onTapDown`, que `CombatEntity` ne déclare pas (elle n'a pas `TapCallbacks`) (*filtre 6*).
- **D14 — L'ordre de la bordure d'un ennemi : fiche, sélection, surbrillance, blanc** — écrite dans la Task 5, avec ce que le joueur voit changer.
- **D15 — La descente et la remise en page sont des écarts relatifs** (*filtre 1*) : `place` ajoute à la position l'écart entre la nouvelle place visée et la précédente (`_headingTo`), `animateInspection` lance un `MoveEffect.by` de l'écart restant ; une place inchangée ne touche donc à rien, une descente en vol va à son terme, et les secousses d'un coup (`MoveEffect.by` alternés, `combat_entity.dart:83-93`, qui reviennent à 0) ne faussent plus l'arrivée, alors qu'un `MoveEffect.to` calcule son écart depuis la position secouée (`flame/lib/src/effects/move_to_effect.dart:45-53`) — mesuré, ouvrir 0,02 s après un coup laissait la carte à 14,3 px de sa place, la fermer à 6,6 px. Seul `LayoutSystem.repositionEnemies` écrit la position d'un ennemi ; tous les autres déplacements sont déjà relatifs.
- **D16 — `repositionEnemies` ne rappelle le rectangle que s'il a changé** (*filtre 1*) : le dernier rectangle rappelé est gardé (`_emittedRect`), remis à nul à la fermeture. Sans cette garde, la réémission → `setState` différé → reconstruction → `onGameResize` → réémission tournait à chaque image (mesuré : 30 reconstructions et 31 rappels en 30 images, fiche ouverte).

---

## Carte des fichiers

| Fichier | Responsabilité | Tâches |
|:---|:---|:---:|
| `lib/game/game_constants.dart` | Géométrie de la barre (1) ; `priorityEntityHovered` (4) ; priorités et facteur de la fiche (5) ; retrait des tailles de badge (3) | 1, 3, 4, 5 |
| `lib/game/systems/armor_veil.dart` *(nouveau)* | `ArmorVeil` | 1 |
| `lib/ui/widgets/hud/intent_pips.dart` *(nouveau)* | `IntentPip`, `IntentPips` | 1 |
| `lib/game/systems/status_readout.dart` *(nouveau)* | `StatusSide`, `ReadoutTone`, `StatusReadout`, `statusEmoji` | 1 |
| `lib/ui/widgets/hud/enemy_sheet_view.dart` *(nouveau)* | `SheetEntry`, `EnemySheetView`, `SheetPlacement` | 1 |
| `lib/game/systems/entity_hover.dart` *(nouveau)* | `pickHoveredEntity`, `enemyBodyRect` (1) ; `unfoldsInward` (4) | 1, 4 |
| `lib/l10n/app_fr.arb`, `app_en.arb`, `app_localizations*.dart` | Clés neuves et `statusName` étendue (1) ; clés retirées (3) | 1, 3 |
| `lib/game/systems/combat_visual_system.dart` | Import de `statusEmoji` | 1 |
| `lib/ui/widgets/hud/enemy_intents_panel.dart` | Trois colonnes, pastilles, infobulle de rangée, liseré | 2 |
| `lib/game/components/entities/enemy_health_bar.dart` *(nouveau)* | La barre, ses textes, son voile, son renvoi | 3 |
| `lib/game/components/entities/stat_badge.dart`, `lib/game/components/widgets/circle_progress.dart` | Supprimés | 3 |
| `lib/game/components/entities/status_tabs.dart` *(nouveau)* ; `status_indicator.dart` | Les languettes ; l'indicateur supprimé | 4 |
| `lib/game/components/entities/combat_entity.dart` | `activeLocale`, `l10n`, languettes, `zone`, `setHovered` | 4 |
| `lib/game/components/entities/enemy_card.dart` | Barre et plein du voile (3) ; languettes et zone (4) ; fiche (5) | 3, 4, 5 |
| `lib/game/components/entities/hero_card.dart` | Languettes du héros, `bodyLocalRect` | 4 |
| `lib/game/components/widgets/card_interaction_handler.dart` | `findHoveredEnemy` sur la zone | 4 |
| `lib/game/heros_draft_game.dart` | `onShowTooltip` en `CardType` (3) ; arbitre du survol (4) ; fiche (5) | 3, 4, 5 |
| `lib/game/systems/layout_system.dart` | Survol relu au replacement (4) ; `place` (5) | 4, 5 |
| `lib/game/systems/state_sync_system.dart` | Rappel de toucher et garde d'état | 5 |
| `lib/game/components/visual_effects/inspection_veil.dart` *(nouveau)* | Le voile d'estompage | 5 |
| `lib/ui/widgets/hud/enemy_sheet_panel.dart` *(nouveau)* | Le cadre de la fiche | 5 |
| `lib/ui/screens/game_screen.dart` | `_tooltipCardType` (3) ; `Listener`, reflet, cadre (5) | 3, 5 |
| `lib/tutorial/widgets/tutorial_combat_overview_widget.dart`, `lib/tutorial/tutorial_data.dart` | Les deux maquettes ; la phrase de l'étape 11 | 6 |
| `test/unit/{armor_veil,intent_pips,status_readout,enemy_sheet_view,entity_hover}_test.dart` *(nouveaux)* | Les règles pures | 1, 4 |
| `test/unit/card_rule_texts_test.dart` | Noms des statuts de reliques | 1 |
| `test/unit/combat_tap_forwarding_test.dart` *(nouveau)* | Le renvoi des touchers | 3, 4 |
| `test/unit/heros_draft_game_targeting_test.dart`, `flame_image_prefix_test.dart` | Ouverture, fermeture, retenue, réémission | 5 |

---

### Task 1: Les règles pures et les textes

**Files :**
- Create : `lib/game/systems/armor_veil.dart`, `lib/ui/widgets/hud/intent_pips.dart`, `lib/game/systems/status_readout.dart`, `lib/ui/widgets/hud/enemy_sheet_view.dart`, `lib/game/systems/entity_hover.dart`
- Modify : `lib/game/game_constants.dart` (bloc neuf après `:32`) ; `lib/game/components/entities/status_indicator.dart:226-252` (`statusEmoji` part, l'import de `status_readout.dart` arrive) ; `lib/game/systems/combat_visual_system.dart:6` (même import) ; `lib/l10n/app_fr.arb`, `app_en.arb` (`statusName`, FR `:252`, EN `:663`) ; les trois `app_localizations*.dart`
- Test : les cinq fichiers neufs ci-dessous ; `test/unit/card_rule_texts_test.dart` (après `:91`)

**Interfaces :**
- Produces — `GameConstants`, bloc « BARRE DE PV D'UN ENNEMI (unités de la carte) » (A4) : `enemyHealthBarTop = -17.0`, `enemyHealthBarHeight = 13.0`, `enemyHealthBarRadius = 4.0`, `enemyHealthBarFontSize = 9.0`, `enemyHealthBarShieldSize = 8.0`, `enemyHealthBarShieldGap = 3.0`, `enemyHealthBarArmorGap = 2.0`. Lues par `enemyBodyRect` (ici), la barre (Task 3) et la fiche (Task 5).
- Produces — `abstract final class ArmorVeil` : `static int nextPeak({required int peak, required int oldArmor, required int newArmor})` et `static double fraction({required int armor, required int peak})`, aux trois règles de spec §4.1 dans cet ordre (`newArmor <= 0` → 0 ; `newArmor > oldArmor` → `newArmor` ; sinon `max(peak, newArmor)`) ; `fraction` = `armor / peak` borné à [0, 1], 0 si `peak <= 0`.
- Produces — `class IntentPip` (champs `final` : `IconData icon`, `Color color`, `String value`, `bool struck`, `bool waiting` ; constructeur `const`) et `abstract final class IntentPips` : `static List<IntentPip> of(EnemyIntent? intent, {required bool skipped, required AppLocalizations l10n})`. Les icônes et couleurs de `_visuals` (`enemy_intents_panel.dart:68-84`) telles quelles ; valeur `EnemyIntentsPanel.compactValue` (D5) ; sans intention, une pastille `Icons.hourglass_empty`, `Colors.white30`, valeur `l10n.waitingIntents`, `waiting` vrai, jamais `struck` ; `skipped` et une intention : couleur `Colors.white38`, `struck` vrai, icône et valeur gardées. Une seule pastille, toujours.
- Produces — dans `status_readout.dart` : `enum StatusSide { left, right }` ; `enum ReadoutTone { buff, debuff, charged }` ; `class StatusReadout` aux champs `final` de spec §4.3 (`String key`, `String emoji`, `String restValue`, `ReadoutTone tone`, `String title`, `String? subtitle`, `int? turnsLeft`, `String? hint`), constructeur `const` ; `static ({List<StatusReadout> left, List<StatusReadout> right}) of(EntityStats stats, ChargeCatalog charges, AppLocalizations l10n, String locale, {String? counterId})` ; `static Color toneColor(ReadoutTone tone)` → `Color(0xFF69F0AE)`, `Color(0xFFFF5252)`, `Colors.yellowAccent` ; `String statusEmoji(String id)`, de haut niveau, celle de `status_indicator.dart:227-252` plus `mana_regen` → `💎` et `hp_regen` → `💖` (B41).
  - Le côté n'est pas un champ (il n'aurait aucun lecteur) : `of` le dit par la liste qui porte l'entrée. `StatusSide` sert aux languettes et à `unfoldsInward` (Task 4).
  - Clés : `'${status.id}:${status.sourceId ?? ''}'` pour un statut, `'charge:${line.chargeId}'` pour une charge (`ChargeRules.linesFor`). Ordre : gauche, les statuts `buff` ; droite, les `debuff` qui ne sont pas des charges (`charges.isCharge`), puis les lignes de charge.
  - Les sept lignes du tableau de spec §4.3, avec les clés de §6.2 : `tabBuff`, `tabDebuff`, `tabTurns` (si 0 < durée < 99), `tabChargePoints`, `tabChargeOpen` (Feu ; et Foudre chargée, avec le nom de l'état), `tabChargeBonus` (`bonus` = `line.value`), `tabChargeWeakenNext` / `tabChargeWeakenNow` (`brokenPending` / `brokenActive`, `percent` = `line.value`) ; `turnsLeft` = la durée si < 99. Une charge n'a ni `subtitle` de durée ni `turnsLeft`.
  - Le ton `charged` : charge `amplifyHits` dont l'état n'est pas `none` (la règle `broken` de `status_indicator.dart:138-140`) ; toute autre charge `debuff`.
  - `hint` : `weakness` → `l10n.statusWeaknessHint(ProportionalStatus.weakness.percentPerPoint, ProportionalStatus.weakness.maxPercent)`, `vulnerable` de même ; `null` ailleurs. Le nom : D6.
- Produces — dans `enemy_sheet_view.dart` : `class SheetEntry { final String text; final String? hint; }` (`text` = « {émoji} {title} », suivi de « · » et `l10n.sheetTurnsLeft(n)` si `turnsLeft`) ; `class EnemySheetView` aux champs `final` `String title, level, hp, armor, might, intentName, intentSentence`, `List<IntentPip> pips`, `List<SheetEntry> bonuses, alterations`, et `static EnemySheetView of(EnemyInstance enemy, {required ChargeCatalog charges, required AppLocalizations l10n, required String locale})`. `title` = le nom en capitales ; `level` = `l10n.levelLabel(stats.level)`, la clé existante (« Niv. {level} » / « Lvl. {level} », `app_fr.arb:178`, `app_en.arb:453`, lue aussi par `signature_bar.dart:536` et `signature_run_card.dart:58`) ; `hp` = `sheetHp`, `armor` = `sheetArmor` (même à 0), `might` = `sheetMight(stats.effectiveMight)` ; l'intention est `enemy.effectiveIntent` : `intentName` par les paliers de `IntentTypeExtension.getLabel` (`model_extensions.dart:89-107`) sur les clés `intentName*`, vide sans intention ; `intentSentence` : sans intention `sheetIntentWaiting`, sinon gelé (`skippingCharge` non nul) `l10n.intentSkipped(<brokenName>)`, sinon `sheetIntentAttack` / `sheetIntentDefend` / `sheetIntentBuff` ; `bonuses` et `alterations` = les deux côtés de `StatusReadout.of` (sans `counterId`).
- Produces — `abstract final class SheetPlacement` : `static Offset topLeftFor({required Rect card, required Size screen, double width = 310, double gap = 24, double margin = 16})`, à la règle de spec §4.6 dans son ordre (droite, gauche, côté le plus large borné à `[margin, screen.width − margin − width]` ; haut = `card.top` borné à `margin` par en dessous).
- Produces — dans `entity_hover.dart` : `int? pickHoveredEntity({required List<List<Rect>> zones, required int? current, required Offset pointer})` (spec §4.5) et `Rect enemyBodyRect(double cardWidth, double cardHeight)` → `Rect.fromLTRB(0, GameConstants.enemyHealthBarTop, cardWidth, cardHeight)`.
- ARB — toutes les clés neuves de spec §6.2 (26, `levelLabel` réutilisée à la place d'une clé `enemyLevel`), mot pour mot, métadonnées `@` dans `app_en.arb` aux types qu'elle donne ; `statusName` gagne `lifesteal` et les six statuts de reliques (`crit_chance`, `mastery`, `kunai_charge`, `shuriken_charge`, `pen_nib_charge`, `incense_charge`) aux noms de §6.2. **Les clés retirées ne partent pas ici** (Task 3).

- [ ] **Step 1 : écrire les tests.** Assertions clés :
  - `armor_veil_test.dart` (7) :
    1. `6 gagnes remplissent le voile` — `nextPeak(peak: 0, oldArmor: 0, newArmor: 6) == 6` ; `fraction(armor: 6, peak: 6) == 1.0` ;
    2. `un coup qui laisse 2 sur 6 couvre un tiers` — `nextPeak(6, 6, 2) == 6` ; `fraction(2, 6)` `closeTo(1 / 3, 1e-9)` ;
    3. `a 0 le voile disparait et son plein s efface` — `nextPeak(6, 2, 0) == 0` ; `fraction(0, 0) == 0` ;
    4. `un boss a 40 : 1, puis 0,625 a 25, puis 0,2 a 8` — le plein reste 40 ;
    5. `de l armure regagnee avant 0 remplit le voile (B16)` — `nextPeak(6, 2, 7) == 7` ; `fraction(7, 7) == 1.0` ;
    6. `la part ne lit pas les PV (B15)` — 6 gagnés par un ennemi de 14 PV et 40 par un boss de 250 PV : `fraction == 1.0` pour les deux ;
    7. `un plein nul ne couvre rien, et le plein ne passe jamais sous l armure` — `fraction(3, 0) == 0` ; `nextPeak(2, 3, 3) == 3`.
  - `intent_pips_test.dart` (6), sur `lookupAppLocalizations` FR et EN :
    1. `chaque palier d attaque a son icone et sa couleur` — 5 → `Icons.bolt`, `Color(0xFFF39C12)`, `'5'` ; 8 → `Icons.flash_on`, `0xFFFF7675` ; 15 → `Icons.whatshot`, `0xFFE74C3C` ; 22 → `Icons.gavel`, `0xFFC0392B` ;
    2. `les seuils 6, 12 et 20 ouvrent le palier suivant` — 5 / 6, 11 / 12, 19 / 20 changent d'icône ;
    3. `la Defense prend le bouclier bleu, le Buff la fleche violette (B31)` — défense 3 → `Icons.shield`, `0xFF448AFF`, `'+3'` ; buff 2 → `Icons.trending_up`, `0xFFE040FB`, `'+2'` ;
    4. `sans intention : le sablier, En attente... et waiting` — `Icons.hourglass_empty`, `Colors.white30`, `waiting` vrai, `struck` faux ; valeur FR `'En attente...'`, EN `'Waiting...'` ;
    5. `un ennemi gele garde icone et valeur, grisees et barrees` — attaque 8, `skipped: true` → `Icons.flash_on`, `Colors.white38`, `'8'`, `struck` vrai ; sans intention et `skipped: true` → la pastille d'attente, `struck` faux ;
    6. `of ne rend jamais plus d une pastille en 0.6.1` — pour les trois types, `null`, `skipped` vrai et faux : `hasLength(1)`.
  - `status_readout_test.dart` (14), catalogue livré (`loadGameDataRegistry(rootBundle)` en `setUpAll`, `registry.charges`), pistes `ChargeTrack(threshold:, ruptures:, state:, rupture: charge.ruptureFor(<porteur>))`, points posés en statuts :
    1. `les bonus a gauche ; a droite les alterations puis les charges` — Puissance +2, Poison 2, Faiblesse 1, Gel 2/3, Feu 5 : `left` = `[might]` ; `right` = poison, weakness, `charge:freeze`, `charge:burn` ;
    2. `deux Puissances de sources differentes font deux entrees` — `sourceId` `'card'` et `'relic'` : deux entrées, clés distinctes ;
    3. `un bonus : sa valeur au repos, son nom et +valeur deroules, FR et EN` — Puissance 2 pendant 3 tours : `restValue '2'`, `'Puissance +2'` / `'Might +2'`, `'3 tours'` / `'3 turns'`, `turnsLeft 3`, ton `buff` ;
    4. `une alteration : son nom et sa valeur, sa duree au pluriel et au singulier` — Poison 2 : `'Poison 2'` ; durée 2 → `'2 tours'` / `'2 turns'` ; durée 1 → `'1 tour'` / `'1 turn'` ;
    5. `une duree de 99 n ecrit ni duree ni tours restants (B34)` — `subtitle` et `turnsLeft` nuls ;
    6. `une charge sous son seuil garde son compte` — Gel 2/3 : `restValue '2/3'`, `'Gel 2/3'` / `'Freeze 2/3'`, sans `subtitle` ni `turnsLeft` ;
    7. `le Feu ecrit ses points` — Feu 5 : `'5'`, `'Feu 5'` / `'Burn 5'` ;
    8. `un ennemi gele montre le nom de son etat (B33)` — `skipAction` en `brokenPending` : `restValue` et `title` `'Gelé'` / `'Frozen'` ;
    9. `un heros gele : l etat et la baisse de degats, au prochain tour puis ce tour` — `weakenDealt` à 50 : `brokenPending` → `'−50 % de dégâts au prochain tour'` / `'−50% damage next turn'` ; `brokenActive` → `'… ce tour'` / `'… this turn'` ;
    10. `la Foudre chargee est jaune, en attente comme active ; sous le seuil elle est rouge (B32)` — Foudre 3 en `brokenActive` : ton `charged`, `restValue '3'`, `'Chargé 3'` / `'Charged 3'`, `'+6 par coup'` / `'+6 per hit'` (D7) ; en `brokenPending` : `charged` ; en `none` (2/3) : `debuff` ;
    11. `toute autre charge et toute alteration sont rouges, tout bonus vert` — tons, et `toneColor` aux trois valeurs ;
    12. `seules la Faiblesse et le Vulnerable portent une ligne d aide` — FR `'−25 % de dégâts infligés par point, jusqu'à −50 %'` et `'+25 % de dégâts subis par point, jusqu'à +100 %'` ; Poison et charges : `hint` nul ;
    13. `le compteur d un passif se nomme Compteur, Counter` — statut `mage_mark_count` (nom `'Compteur'`), `counterId: 'mage_mark_count'` : `'Compteur +1'` / `'Counter +1'` ;
    14. `les emojis : 💎 pour la Source de Mana, 💖 pour la Source de Vie` — `statusEmoji('mana_regen') == '💎'`, `('hp_regen') == '💖'`, `('poison') == '🧪'`, un id inconnu → `'✨'`.
  - `enemy_sheet_view_test.dart` (11) — fixture : `EnemyData` à `baseDamage` 2 ; `stats` 9/14 PV, armure 4, `might` 2, niveau 1, statuts Puissance +2 (`buff`, 99 tours) et Poison 2 pendant 3 tours ; intention attaque 2 — d'où `effectiveIntent` 4 et `effectiveMight` 4 (`enemy_instance.dart:33-51`, `entity_stats.dart:193-201`) :
    1. `la fiche d un ennemi, en francais` — `title` en capitales, `'Niv. 1'`, `'PV 9/14'`, `'Armure 4'`, `'Puissance 4'`, `'Attaque Rapide'`, `'Attaquera le héros pour 4 dégâts.'`, un bonus, une altération qui finit par `'· encore 3 tours'` ;
    2. `la fiche d un ennemi, en anglais` — `'Lvl. 1'`, `'HP 9/14'`, `'Armor 4'`, `'Might 4'`, `'Quick Attack'`, `'Will attack the hero for 4 damage.'`, `'· 3 turns left'` ;
    3. `un ennemi gele dit qu il ne fait rien` — `intentSentence == 'Gelé : ne fait rien ce tour'` ;
    4. `sans intention` — `'Intention pas encore connue.'`, `intentName` vide, la pastille d'attente ;
    5. `sans bonus, pas de section bonus (B34)` — `bonuses` vide ;
    6. `l armure se montre a 0` — `'Armure 0'` ;
    7. `1 degat au singulier` — `'Attaquera le héros pour 1 dégât.'` ;
    8. `le cadre se pose a droite s il tient` — carte `Rect.fromLTWH(100, 100, 200, 300)`, écran 1280 × 800 → `Offset(324, 100)` ;
    9. `sinon a gauche` — carte à `left` 900, `right` 1100 → `Offset(566, …)` ;
    10. `sans place des deux cotes, du cote le plus large, borne` — écran 600 de large, carte de 200 à 450 (200 à gauche, 150 à droite) : à gauche, `−134` borné → `dx == 16` ;
    11. `le haut ne monte pas au-dessus de la marge` — `card.top` 4 → `dy == 16`.
  - `entity_hover_test.dart` (6) :
    1. `le pointeur dans une carte la designe` ;
    2. `dans les languettes deroulees de la courante, hors de sa carte : la courante` ;
    3. `ailleurs : aucune` → `null` ;
    4. `deux zones qui se recouvrent : la courante l emporte` — zone 0 et zone 1 contiennent le point, `current: 1` → 1 ;
    5. `une languette au repos designe sa carte` — zone 0 = `[corps, languette]`, pointeur dans la languette, `current: null` → 0 ;
    6. `la bande entre la barre et la carte appartient a l ennemi` — `enemyBodyRect(100, 140)` contient `Offset(50, -2)` et `Offset(50, 139)`, pas `Offset(50, -18)`.
  - `card_rule_texts_test.dart`, **neuf** `statusName nomme le vol de vie et les six statuts de reliques` — `lifesteal` FR `'Vol de Vie'`, EN `'Lifesteal'` ; FR `crit_chance` `'Critique (Relique)'`, `mastery` `'Maîtrise (Relique)'`, `kunai_charge` `'Charge Kunaï'`, `shuriken_charge` `'Charge Shuriken'`, `pen_nib_charge` `'Charge Plume'`, `incense_charge` `'Charge Encensoir'` (les `name` de `player_stats_manager.dart:300`, `:345`, `:355`, `:390`, `:425`, `:451`) ; en EN, aucun ne rend son id.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/armor_veil_test.dart test/unit/intent_pips_test.dart test/unit/status_readout_test.dart test/unit/enemy_sheet_view_test.dart test/unit/entity_hover_test.dart test/unit/card_rule_texts_test.dart` → échec de compilation (fichiers et clés absents).
- [ ] **Step 3 : implémenter** aux interfaces ci-dessus ; les clés ARB, puis `flutter gen-l10n`.
- [ ] **Step 4 : vérifier.** Les six fichiers → `All tests passed!` ; `git grep -n "String statusEmoji" -- lib` → seulement `status_readout.dart` ; `git grep -n "enemyLevel" -- lib/l10n` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1911** (1866 + 45).
- [ ] **Step 5 : commit.** `feat(bestiaire): les regles pures de l interface des ennemis et leurs textes`.

### Task 2: Le panneau des intentions

**Files :**
- Modify : `lib/ui/widgets/hud/enemy_intents_panel.dart:66-251`

**Interfaces :**
- Consumes : `IntentPips.of`, `IntentPip` (Task 1) ; `l10n.levelLabel` (existante).
- `_visuals` et `_intentChip` partent ; `_enemyRow` devient une `Row` de trois colonnes (spec §5.1, A6) : `SizedBox(width: 40)` portant `FittedBox(fit: BoxFit.scaleDown)` du niveau (11, `white38`) ; 6 ; `Expanded` du nom (12 gras, blanc, `amberAccent` pour un boss, une ligne, points de suspension) ; 6 ; `SizedBox(width: 96)` aligné à gauche, portant `FittedBox(fit: BoxFit.scaleDown)` de la rangée des pastilles (4 entre deux). Les PV disparaissent.
- Une pastille garde le style de `:162-198` (marge 6 × 2, rayon 6, fond à 20 — 10 pour l'attente —, liseré à 60 d'épaisseur 1, icône 14, 4, valeur 12 gras ; italique quand `waiting` ; `lineThrough` quand `struck`).
- Le `Tooltip` de `:113-161`, inchangé dans son contenu, enveloppe **la rangée** : titre `intent.type.getLabel(l10n, intent.value)` (ou `l10n.waitingIntents`), phrase `EnemyIntentsPanel.explanation`, bordure de la couleur de la première pastille, `lightBlueAccent` pour un ennemi gelé.
- Un widget privé à état, `_IntentPipRow`, tient l'index de la pastille survolée (`MouseRegion` par pastille) : elle prend un liseré de 1,5 de la couleur de l'infobulle ; au doigt, aucun `MouseRegion` ne s'active.
- `compactValue`, `explanation` et le cadre du panneau (`:253-349`) ne changent pas.

- [ ] **Step 1 : implémenter** aux interfaces ci-dessus.
- [ ] **Step 2 : vérifier.** `flutter test test/unit/enemy_intents_panel_texts_test.dart` → vert ; `git grep -n "_visuals" -- lib` → rien (Review Focus 5) ; `git grep -n "'Niv. \${" -- lib/ui/widgets/hud/enemy_intents_panel.dart` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1911**.
- [ ] **Step 3 : commit.** `feat(bestiaire): le panneau des intentions en trois colonnes`.

### Task 3: La barre de PV et le voile d'armure

**Files :**
- Create : `lib/game/components/entities/enemy_health_bar.dart` ; `test/unit/combat_tap_forwarding_test.dart`
- Delete : `lib/game/components/entities/stat_badge.dart`, `lib/game/components/widgets/circle_progress.dart`
- Modify : `lib/game/components/entities/enemy_card.dart:6` (l'import d'`AppLocalizations`, sans lecteur une fois `getTranslation` parti), `:16`, `:30`, `:130-143`, `:163`, `:188-225`, `:288-294` ; `lib/game/game_constants.dart:34-37` (supprimées) ; `lib/game/heros_draft_game.dart:79` ; `lib/ui/screens/game_screen.dart:55-70` ; `lib/l10n/app_fr.arb`, `app_en.arb` (neuf clés) ; les trois `app_localizations*.dart`

**Interfaces :**
- Consumes : `ArmorVeil` ; les constantes `enemyHealthBar*` (Task 1).
- Produces — `class EnemyHealthBar extends PositionComponent with TapCallbacks` : `EnemyHealthBar({required double width, required void Function(TapDownEvent event) onTap})`, posée en `(0, GameConstants.enemyHealthBarTop)`, de taille `(width, -GameConstants.enemyHealthBarTop)` — **sa zone d'appui descend jusqu'au haut de la carte** (A3) ; `void setValues({required int currentPv, required int maxPv, required int armor, required double veil})` ; `@override void onTapDown(TapDownEvent event) => onTap(event)`. Elle porte une `LinearProgressBarComponent` de `(width, enemyHealthBarHeight)` en haut, rayon `enemyHealthBarRadius`, `percentage` = PV / PV max, `armorPercentage` = `veil` (le composant, `linear_progress_bar.dart:58-100`, ne change pas) ; le texte « PV/PV max » blanc gras `enemyHealthBarFontSize`, ombré de noir ; si l'armure est positive, `enemyHealthBarShieldGap` plus loin, un `FlameShieldIcon` (`lib/game/components/widgets/flame_shield_icon.dart`) de `enemyHealthBarShieldSize`, `Color(0xFF2196F3)`, et `enemyHealthBarArmorGap` plus loin le montant en `Color(0xFF00E5FF)` gras ; le groupe est centré sur la barre (spec A4).
- `EnemyCard` : `late final EnemyHealthBar healthBar`, ajoutée dans `onLoad` avec `width: size.x` et `onTap: onTapDown` (D2) ; `int _armorPeak`, initialisé à `instance.stats.armure` ; dans `_applyInstance`, **avant** `instance = next` : `_armorPeak = ArmorVeil.nextPeak(peak: _armorPeak, oldArmor: stats.armure, newArmor: next.stats.armure)` ; `_refreshBadges` devient `_refreshHealthBar()` → `healthBar.setValues(…, veil: ArmorVeil.fraction(armor: stats.armure, peak: _armorPeak))`. `getTranslation` part ; `activeLocale` reste (Task 4 le déplace).
- `HerosDraftGame.onShowTooltip` : `void Function(String title, String description, CardType cardType)`. `GameScreen` : `CardType _tooltipCardType = CardType.skill;` ; `_getTooltipBorderColor` perd la branche `null` (`:59`) et le `!` (`:60`).
- `GameConstants` perd `badgeHpSize`, `badgeStandardSize`, `badgeCircleSize` et son commentaire de bloc.
- ARB : partent de `app_fr.arb` et `app_en.arb`, métadonnées comprises, `hpAbbreviation`, `enemyStatsTitle`, `enemyStatsDesc`, `tooltipHpDesc`, `tooltipArmorTitle`, `tooltipArmorDesc`, `tooltipAttackTitle`, `tooltipAttackDesc`, `tooltipManaDesc` ; `tooltipHpTitle` et `tooltipManaTitle` restent (`stats_dialog.dart`).

- [ ] **Step 1 : écrire `combat_tap_forwarding_test.dart`** (2) :
  1. `la barre renvoie son appui a sa carte, pointeur compris` — `EnemyHealthBar(width: 100, onTap: events.add)` ; `bar.onTapDown(TapDownEvent(7, FlameGame(), TapDownDetails()))` → `events.single.pointerId == 7` ;
  2. `la zone d appui de la barre descend jusqu au haut de la carte` — `position == Vector2(0, -17)`, `size == Vector2(100, 17)` ; `containsLocalPoint(Vector2(50, 15))` vrai (y −2 dans la carte).
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/combat_tap_forwarding_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter** ; supprimer les deux fichiers et les clés, puis `flutter gen-l10n`.
- [ ] **Step 4 : vérifier.** Le fichier → vert ; `git grep -nw -e StatBadge -e CircleProgressComponent -e enemyStatsDesc -e hpAbbreviation -e badgeHpSize -e getTranslation -- lib/game/components/entities test` → rien ; `git grep -n "CardType? cardType\|_tooltipCardType!" -- lib` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1913** (1911 + 2).
- [ ] **Step 5 : commit.** `feat(bestiaire): la barre de PV a la largeur de la carte et le voile d armure`.

### Task 4: Les languettes, la zone d'une carte et le survol

**Files :**
- Create : `lib/game/components/entities/status_tabs.dart`
- Delete : `lib/game/components/entities/status_indicator.dart`
- Modify (par symbole : Task 3 a déplacé les lignes) : `combat_entity.dart` (classe `CombatEntity`, ses getters abstraits) ; `enemy_card.dart` — les imports de `status_indicator.dart`, de `../../../models/status_effect.dart` et de `../../systems/charge_rules.dart` (sans lecteur une fois `_indicatorView` parti), les champs `buffIndicator` / `debuffIndicator`, leur création dans `onLoad`, `activeLocale`, `_indicatorView`, `_refreshIndicators` et son appel dans `_applyInstance` ; `hero_card.dart` (`onLoad`, `_applyStats`) ; `heros_draft_game.dart` (`onPointerMove`, `pointerLeft`, `_livingEnemyAt`) ; `layout_system.dart` (`repositionEnemies`) ; `card_interaction_handler.dart` (`findHoveredEnemy`) ; `game_constants.dart` (bloc des priorités) ; `entity_hover.dart`
- Test : `test/unit/entity_hover_test.dart` ; `test/unit/combat_tap_forwarding_test.dart`

**Interfaces :**
- Consumes : `StatusReadout`, `StatusSide`, `ReadoutTone`, `pickHoveredEntity`, `enemyBodyRect` (Task 1) ; `PassiveCounters.idOf` (`lib/game/systems/passives/passive_counters.dart:27`).
- Produces — `GameConstants.priorityEntityHovered = 5`.
- Produces — dans `entity_hover.dart` : `bool unfoldsInward({required StatusSide side, required double attachEdge, required double unfoldedWidth, required double screenWidth})` — vrai si `side == left` et `attachEdge − unfoldedWidth < 0`, ou `side == right` et `attachEdge + unfoldedWidth > screenWidth` (B39 ; `attachEdge`, bord de la carte du côté de la languette, et `unfoldedWidth` sur le canevas).
- Produces — `class StatusTabs extends PositionComponent with TapCallbacks` : `StatusTabs({required StatusSide side, required double cardWidth, required void Function(TapDownEvent event) onTap})`, priorité 6 dans sa carte (au-dessus de la gangue 4 et du halo 5) ; `void setEntries(List<StatusReadout> entries)` (réconciliation par `key`, `status_indicator.dart:63-101`) ; `void setUnfolded(bool unfolded, {bool inward = false})` ; `double get unfoldedWidth` (unités de la carte) ; `Rect? get restLocalRect` et `Rect? get localRect` (le rectangle au repos et le rectangle courant dans la carte, `null` sans entrée) ; `@override void onTapDown(TapDownEvent event) => onTap(event)`. Son `position` et son `size` sont le rectangle courant : l'appui se lit sur ce qui est dessiné. Valeurs de spec §5.3 : au repos 30 de large, 1 unité sur la carte (gauche `x = 1 − 30`, droite `x = cardWidth − 1`), haut à 11, une entrée toutes les 31, fond `#14141E`, liseré `#766734` de 1, rayon 4, marge 3, l'émoji 14 et `restValue` gras 10 de `StatusReadout.toneColor` réduit à la largeur ; déroulée : largeur du contenu bornée à `[30, 120]` (texte coupé au-delà), marges 8 × 4, `title` gras 9 `#F7F7FA`, `subtitle` gras 9 `#FFD740`, une entrée toutes les 22 (30 avec `subtitle`), bord intérieur collé à la carte vers l'extérieur — vers l'intérieur, bord extérieur collé au bord extérieur de la carte ; 0,1 s. Sans entrée, rien n'est dessiné.
- Produces — `CombatEntity` gagne : `String get activeLocale` (déplacé de `EnemyCard`) ; `AppLocalizations get l10n => lookupAppLocalizations(Locale(activeLocale))` ; `late final StatusTabs leftTabs`, `late final StatusTabs rightTabs` ; `void addStatusTabs(void Function(TapDownEvent event) onTap)` — appelé par `onLoad` de chaque carte avec son propre `onTapDown` (D13 : `CombatEntity` n'a pas `TapCallbacks` et ne le déclare pas) ; `void refreshStatusTabs({String? counterId})` (lit `StatusReadout.of(stats, game.chargeCatalog, l10n, activeLocale, counterId:)`) ; `Rect get bodyLocalRect` (abstrait) ; `List<Rect> get zone` (D3 : chaque rectangle local passé par `absolutePositionOf`) ; `bool zoneContains(Vector2 point)` ; `void setHovered(bool hovered)` — priorité `priorityEntityHovered` ou 0, les deux languettes déroulées ou repliées, chacune vers l'intérieur si `unfoldsInward` sur `game.size.x`. `EntityStats get stats` devient abstrait sur `CombatEntity` (les deux cartes l'ont déjà).
- `EnemyCard` : `bodyLocalRect => enemyBodyRect(size.x, size.y)` ; les deux `StatusIndicator` et `_indicatorView` / `_refreshIndicators` partent au profit de `addStatusTabs(onTapDown)` / `refreshStatusTabs()` ; `_brokenNameOf` reste (`frozenTurnAnimation`).
- `HeroCard` : `bodyLocalRect => Rect.fromLTWH(0, 0, size.x, size.y)` ; `addStatusTabs(onTapDown)` dans `onLoad` — l'appui d'une languette du héros va donc à `HeroCard.onTapDown`, qui joue une carte focalisée ciblant soi —, `refreshStatusTabs(counterId: …)` dans `onLoad` et après `stats = newStats` de `_applyStats`, `counterId` = `PassiveCounters.idOf(game.currentRunState!.activePassive!)` quand un passif est actif. Le panneau des effets du héros ne change pas (B38).
- `HerosDraftGame` : `CombatEntity? hoveredEntity` ; `void refreshEntityHover()` — rien sans dernier point de souris ; zones des ennemis vivants puis du héros, `pickHoveredEntity`, `_setHoveredEntity` ; `void _setHoveredEntity(CombatEntity? entity)` (sans effet si inchangé ; `setHovered(false)` sur l'ancien, `setHovered(true)` sur le nouveau). `onPointerMove` l'appelle après `refreshHover` ; `pointerLeft` appelle `_setHoveredEntity(null)`. `_livingEnemyAt` lit `zoneContains`, l'ennemi survolé d'abord (A8).
- `LayoutSystem.repositionEnemies` finit par `game.refreshEntityHover()`, comme `layoutHand` par `refreshHover` (`layout_system.dart:99-101`) : le plateau qui change sous un pointeur immobile est relu (Review Focus 4).
- `findHoveredEnemy` lit `enemy.zoneContains(canvasPos)` : lâcher une carte sur la barre ou une languette la cible.

- [ ] **Step 1 : les tests.**
  - `entity_hover_test.dart`, groupe `unfoldsInward` (3) :
    1. `la languette droite de l ennemi du bord droit se deroule vers l interieur` — `attachEdge: 1184`, `unfoldedWidth: 172`, `screenWidth: 1280` → vrai ;
    2. `la languette gauche de l ennemi du bord gauche aussi` — `attachEdge: 96`, `172` → vrai ;
    3. `le heros au centre ne se retourne jamais` — `left`, `attachEdge: 562`, `156` → faux ; `right`, `718`, `156` → faux.
  - `combat_tap_forwarding_test.dart`, **neuf** `les languettes renvoient leur appui a leur carte` — `StatusTabs(side: StatusSide.right, cardWidth: 100, onTap: events.add)` ; `onTapDown(TapDownEvent(3, FlameGame(), TapDownDetails()))` → `events.single.pointerId == 3`.
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/entity_hover_test.dart test/unit/combat_tap_forwarding_test.dart` → échec de compilation.
- [ ] **Step 3 : implémenter** aux interfaces ci-dessus ; supprimer `status_indicator.dart`.
- [ ] **Step 4 : vérifier.** Les deux fichiers → verts ; `git grep -nw -e StatusIndicator -- lib test` → rien ; `git grep -n "containsPoint" -- lib/game/heros_draft_game.dart lib/game/components/widgets/card_interaction_handler.dart` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1917** (1913 + 4).
- [ ] **Step 5 : commit.** `feat(bestiaire): les languettes des ennemis et du heros, et leur survol`.

### Task 5: La fiche de l'ennemi — *tâche à risque*

**Files :**
- Create : `lib/game/components/visual_effects/inspection_veil.dart` ; `lib/ui/widgets/hud/enemy_sheet_panel.dart`
- Modify (par symbole, les Tasks 3 et 4 ayant déplacé les lignes) : `game_constants.dart` (après `priorityCardDraggingMax`) ; `enemy_card.dart` (`onTapEnemy`, le mutateur de `scaleMultiplier`, `baseScale`, `onGameResize`, `_refreshBorderVisuals`, `setSelection`, `setHighlight`, `onTapDown`) ; `layout_system.dart` (la boucle des places de `repositionEnemies`) ; `heros_draft_game.dart` ; `state_sync_system.dart` (fin de `_applyCombatState`) ; `game_screen.dart`
- Test : `test/unit/heros_draft_game_targeting_test.dart` (réécrit, 7 tests gardés, 16 neufs) ; `test/unit/flame_image_prefix_test.dart:33`

**Interfaces :**
- Consumes : `bodyLocalRect`, `leftTabs` / `rightTabs.restLocalRect`, `_setHoveredEntity`, `refreshEntityHover` (Task 4) ; `EnemySheetView`, `SheetPlacement` (Task 1).
- Produces : `class EnemyInspection { final String enemyId; final Rect rect; }` (dans `heros_draft_game.dart`, lu par `GameScreen` seul : le cadre reçoit `enemyId` et `card`, D12) ; `HerosDraftGame.inspectedEnemy`, `inspectEnemy`, `closeInspection`, `closeInspectionIfStale`, `closeInspectionUnlessOn`, `handlePlayerTargeting(EnemyCard, int)`, le paramètre `required onInspectionChanged` ; `EnemyCard.isInspected`, `restScale`, `restPosition`, `place`, `animateInspection`, `inspectionRect`.

**Ce qui a été rejoué.** Le code ci-dessous a été appliqué le 21/11 dans un clone de la branche à `3b3479cf` — donc sans les Tasks 1 à 4 —, avec le fichier de test ci-dessous : `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart` → `+25: All tests passed!` (22 + 3) ; `dart analyze` → `No issues found!`. Pour ce rejeu, les cinq lignes qui lisent Task 4 en étaient absentes : `_setHoveredEntity(null)` dans `inspectEnemy`, `refreshEntityHover()` dans `closeInspection`, la garde de `refreshEntityHover`, les languettes dans `inspectionRect` (`bodyLocalRect` y était écrit `Rect.fromLTRB(0, GameConstants.enemyHealthBarTop, size.x, size.y)`). Elles ne changent rien aux tests : sans souris, rien n'est survolé, et une carte non chargée n'a pas de languette lue. **Second rejeu, après la vérification du plan**, avec les corrections de la bordure, des séquences d'échelle (D11), de `_snapScale` (D10) et de la fermeture sans relecture du survol (`_closeInspection(rereadHover: false)`) : mêmes commandes, `+25: All tests passed!`, `No issues found!`. D10 et D11 ont été mesurés à part, dans le même clone, sur un `PositionComponent` monté dans un `FlameGame` (un test jetable, retiré) : les chiffres sont ceux de D10 et D11. **Troisième rejeu, après le second tour de vérification**, avec D10 (cible inchangée), D15 et D16 : mêmes commandes, `+26: All tests passed!` (23 + 3), `No issues found!`. Mesuré sur une `EnemyCard` réellement montée dans un `HerosDraftGame` chargé (registre livré, 1280 × 800, test jetable retiré), avant → après : fiche ouverte, la boucle « rappel → reconstruction → `onGameResize` » sur 30 images, 30 reconstructions et 31 rappels → **1 et 1** ; l'échelle relative une image après l'ouverture 1,0278, puis après un `onGameResize` à taille égale 1,25 (l'animation sautait) → **1,0278**, puis à la fin **1,25** ; l'écart de position 0,02 s après un coup, ouverte 14,3 px → **0,00002**, fermée 6,6 px → **0** ; ouvrir et fermer 0,05 s après un coup, 1,25 et 1,0 → **inchangés** ; un vrai redimensionnement (1440 × 900) 0,05 s après l'ouverture : échelle **1,25** de la nouvelle échelle de repos, écart de position **0,00002**, deux rappels (l'ouverture et le redimensionnement).

**Le déroulé de chaque appui contre Flame 1.38.2 et Flutter 3.41.6.** L'ordre est celui de la spec (A12) : la distribution d'un appui suit le chemin du test de point, du plus profond au plus haut (`rendering/box.dart:2953-2954`, `gestures/binding.dart:496`) ; le `Listener` de la `RawGestureDetector` du jeu (`flame/lib/src/game/game_widget/gesture_detector_builder.dart:40`) passe donc avant celui de l'écran, et `MultiTapGestureRecognizer.addAllowedPointer` rend `onTapDown` dans ce même appel (`gestures/multitap.dart:515-534`) → `MultiTapDispatcher.onTapDown` (`flame/lib/src/events/dispatchers/multi_tap_dispatcher.dart:37-45`, `:133-135`) → `deliverAtPoint`, qui confie l'appui au premier composant à `TapCallbacks` contenant le point, enfants avant parents, priorité haute d'abord, que leur parent contienne le point ou non (`flame/lib/src/components/core/component.dart:851-886`, `events/messages/location_context_event.dart:38-54`). Le voile, sans `TapCallbacks`, ne prend rien. Un appui sur un widget du HUD ou sur le cadre arrête le test de point du `Stack` avant le `GameWidget` : Flame ne le voit pas. Chaque cas :

| Appui (bouton principal) | Flame | Pointeur retenu | `Listener` |
|:---|:---|:---:|:---|
| Un ennemi vivant, sa barre, sa languette, sans fiche | `onTapEnemy` → `inspectEnemy` | oui | garde |
| Un autre ennemi vivant, fiche ouverte | remplace | oui | garde |
| La carte ouverte, sa barre, sa languette | même fiche, aucun rappel | oui | garde |
| Le décor | `HerosDraftGame.onTapDown` → `closeInspection` | non | ferme (déjà fermée) |
| Le héros, sa languette | `HeroCard.onTapDown`, sans carte focalisée : rien | non | ferme |
| Une carte de la main | `setFocusedCard(carte)` → `_closeInspection(rereadHover: false)`, la carte se lève — sans relire le survol, qui jouerait `cardHover` avec `cardPickup` (`heros_draft_game.dart:146-151`, `card_interaction_handler.dart:25-26`) | non | ferme (déjà fermée) |
| Une carte jouée en vol | consommé sans effet (`card_interaction_handler.dart:17`) | non | ferme — l'effet de bord accepté par la spec |
| Un bouton du HUD, y compris Son ou Deck peints au-dessus de la barre de l'ennemi de droite | rien reçu | non | ferme |
| Le cadre de la fiche (`AbsorbPointer`) | rien reçu | non | ferme |
| Un ennemi, carte focalisée | la carte se joue ; aucune fiche n'était ouverte (`setFocusedCard` l'a fermée) | non | rien à fermer |
| Un ennemi, signature armée | `onSelectEnemy` ; aucune fiche (armer l'a fermée) | non | rien à fermer |
| Un ennemi mort ou mourant, ou hors du tour du joueur | rien | non | ferme |
| Clic droit, n'importe où | refusé (`multi_tap_dispatcher.dart:161-163`) | non | ignoré (`buttons != kPrimaryButton`) : la fiche reste |

La règle de la spec tient dans chacun de ces cas ; **aucun écart n'est proposé**. Les trous d'implémentation que la spec ne voyait pas sont fermés ci-dessous : D1 (le jeu sans taille dans les tests), D8 (la mort fiche ouverte, garde défensive), D10 (l'échelle réécrite à chaque reconstruction), D11 (une secousse en cours), D15 (la descente partie d'une position secouée), D16 (le rappel qui tournait en boucle). Un pointeur retenu et jamais lu ne peut pas fausser un appui suivant : chaque appui reçoit un `pointer` neuf.

**Le code.**

`lib/game/game_constants.dart`, après `priorityCardDraggingMax` (`:18`) :

```dart
  /// Le voile qui estompe le plateau pendant la fiche d'un ennemi : au-dessus
  /// de la carte focalisée de la main, sous la carte ouverte.
  static const int priorityInspectionVeil = 180;
  /// La carte d'un ennemi dont la fiche est ouverte, au-dessus du voile.
  static const int priorityInspectedEnemy = 190;

  // --- FICHE D'UN ENNEMI ---
  /// L'agrandissement de la carte ouverte : celui de la carte focalisée.
  static const double inspectionScale = 1.25;
  /// Agrandissement, descente et fondu du voile, à l'aller comme au retour.
  static const double inspectionSeconds = 0.15;
```

`lib/game/components/visual_effects/inspection_veil.dart` :

```dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../../game_constants.dart';

/// Le voile noir qui estompe la scène Flame pendant la fiche d'un ennemi
/// (spec P-05 vague 1, A11) : décor, héros, main et autres ennemis. Sans
/// `TapCallbacks`, il ne reçoit aucun appui : un toucher passe à ce qu'il
/// couvre.
class InspectionVeil extends RectangleComponent {
  /// L'opacité du voile posé.
  static const double shownOpacity = 0.55;

  InspectionVeil({required Vector2 size})
      : super(
          size: size,
          priority: GameConstants.priorityInspectionVeil,
          paint: Paint()..color = Colors.black.withValues(alpha: 0),
        );

  void show() => _fadeTo(shownOpacity);

  void hide() => _fadeTo(0);

  void _fadeTo(double opacity) {
    removeAll(children.whereType<OpacityEffect>());
    add(
      OpacityEffect.to(
        opacity,
        EffectController(duration: GameConstants.inspectionSeconds),
      ),
    );
  }
}
```

`lib/game/components/entities/enemy_card.dart` — le champ `onTapEnemy` :

```dart
  /// Le toucher de la carte, de sa barre ou de ses languettes, avec le
  /// pointeur de l'appui : `HerosDraftGame` le retient quand il ouvre ou
  /// garde une fiche (spec P-05 vague 1, A12).
  final void Function(EnemyCard enemy, int pointerId) onTapEnemy;
```

Le mutateur de `scaleMultiplier` et `onGameResize` posent l'échelle par `_snapScale()` (D10) ; la place et la descente suivent D15 :

```dart
  set scaleMultiplier(double value) {
    if (_scaleMultiplier == value) return;
    _scaleMultiplier = value;
    _snapScale();
  }
```

```dart
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _snapScale();
  }
```

`baseScale` est remplacé par :

```dart
  /// L'échelle de la carte au repos, fiche fermée.
  double get restScale =>
      game.scaleFactor * 1.45 * (isBoss ? 1.25 : 1.0) * _scaleMultiplier;

  /// L'échelle à laquelle les effets ramènent la carte : agrandie tant que sa
  /// fiche est ouverte (spec P-05 vague 1, A11).
  double get baseScale =>
      restScale * (_isInspected ? GameConstants.inspectionScale : 1.0);

  bool _isInspected = false;

  /// La fiche de cet ennemi est ouverte. Seul `HerosDraftGame` l'écrit ; ni
  /// la sélection ni la surbrillance n'y touchent.
  bool get isInspected => _isInspected;
  set isInspected(bool value) {
    _isInspected = value;
    if (isLoaded) _refreshBorderVisuals();
  }

  /// La place que la remise en page donne à la carte, fiche fermée.
  Vector2 restPosition = Vector2.zero();

  /// La place vers laquelle la carte va, effets de la fiche compris : chaque
  /// déplacement de la fiche ou de la remise en page s'ajoute à la position
  /// par écart relatif, si bien que les secousses en vol, qui reviennent à 0,
  /// ne faussent jamais l'arrivée.
  Vector2 _headingTo = Vector2.zero();

  ScaleEffect? _inspectionScale;
  double? _inspectionScaleTarget;

  /// Pose l'échelle de base, sauf si l'agrandissement de la fiche y va déjà :
  /// chaque reconstruction de `GameScreen` rappelle `onGameResize` à taille
  /// inchangée, et ne doit pas couper l'animation. Une cible neuve (vrai
  /// redimensionnement) l'arrête, dont le reste s'ajouterait sinon.
  void _snapScale() {
    final target = baseScale;
    final running = _inspectionScale;
    if (running != null &&
        !running.isRemoving &&
        !running.isRemoved &&
        _inspectionScaleTarget == target) {
      return;
    }
    running?.removeFromParent();
    _inspectionScale = null;
    scale = Vector2.all(target);
  }

  /// Un effet qui écrit l'échelle : un `ScaleEffect`, ou la séquence d'une
  /// réaction aux coups qui en porte un.
  static bool _carriesScale(Component c) =>
      c is ScaleEffect ||
      (c is SequenceEffect && c.children.any((e) => e is ScaleEffect));

  /// La descente de la carte ouverte : le haut de sa barre reste où il était
  /// quand elle grandit (B40).
  double get _inspectionDrop =>
      (size.y / 2 - GameConstants.enemyHealthBarTop) * (baseScale - restScale);

  Vector2 get _targetPosition => restPosition + Vector2(0, _inspectionDrop);

  /// Pose la carte à sa place, la descente de la fiche comprise, par l'écart
  /// à sa place précédente : une place inchangée ne touche à rien, une
  /// descente en vol va à son terme. `LayoutSystem.repositionEnemies` passe
  /// par ici.
  void place(Vector2 rest) {
    restPosition = rest;
    final target = _targetPosition;
    position += target - _headingTo;
    _headingTo = target;
  }

  /// Joue l'agrandissement ou le retour, la descente et la priorité qui
  /// suivent [isInspected] ; seulement pour une carte chargée et vivante.
  void animateInspection() {
    priority = _isInspected ? GameConstants.priorityInspectedEnemy : 0;
    removeAll(children.where(_carriesScale).toList());
    _inspectionScaleTarget = baseScale;
    add(
      _inspectionScale = ScaleEffect.to(
        Vector2.all(baseScale),
        EffectController(duration: GameConstants.inspectionSeconds),
      ),
    );
    final target = _targetPosition;
    final delta = target - _headingTo;
    _headingTo = target;
    if (!delta.isZero()) {
      add(
        MoveEffect.by(
          delta,
          EffectController(duration: GameConstants.inspectionSeconds),
        ),
      );
    }
    // La séquence d'un coup retirée ne rendra pas la bordure qu'elle teintait.
    _refreshBorderVisuals();
  }

  /// Le rectangle de la carte ouverte à l'arrivée, barre et languettes au
  /// repos comprises, sur le canevas : ce que `GameScreen` lit pour placer le
  /// cadre de la fiche.
  Rect inspectionRect() {
    var local = bodyLocalRect;
    if (isLoaded) {
      for (final tabs in [leftTabs, rightTabs]) {
        final rest = tabs.restLocalRect;
        if (rest != null) local = local.expandToInclude(rest);
      }
    }
    final s = baseScale;
    final c = _targetPosition;
    return Rect.fromLTRB(
      c.x + (local.left - size.x / 2) * s,
      c.y + (local.top - size.y / 2) * s,
      c.x + (local.right - size.x / 2) * s,
      c.y + (local.bottom - size.y / 2) * s,
    );
  }
```

La bordure (`_refreshBorderVisuals`, `setSelection`, `setHighlight`) : `_refreshBorderVisuals` lit **`_isInspected`, puis `isSelected` (ambre de 4 tous deux), puis la surbrillance (cyan de 3), sinon blanc de 2** — sa première ligne devient `if (_isInspected || isSelected) {`, le reste ne change pas ; `setSelection` devient `isSelected = selected; if (!isLoaded) return; _refreshBorderVisuals();` ; `setHighlight` garde ses deux gardes, puis `_refreshBorderVisuals();` et, quand la surbrillance tombe, son retrait de `_glowAnimation`.

**D14 — Ce que le joueur voit changer, mesuré sur le geste fréquent** (*filtre 7* : garder l'ambre de la sélection, que le joueur voit aujourd'hui). Après une attaque jouée sur E1, qui reste sélectionné, le joueur prend une autre carte qui cible les ennemis. Aujourd'hui, le cyan que `setHighlight(true)` écrit n'est **jamais peint** : la prise de la carte appelle `onShowTooltip` (`card_animation_system.dart:100-104`), dont le `setState` (`game_screen.dart:323-330`) reconstruit l'écran, qui repasse l'état de combat (`:531`), appliqué par l'`update(0)` du `LayoutBuilder` de `GameWidget` dans la même passe, avant toute image (`game_widget.dart:410-416`, `state_sync_system.dart:35-38`) ; sa synchronisation de la sélection (`:185-192`) rappelle `setSelection` sur chaque carte, qui écrit sans lire la surbrillance (`enemy_card.dart:309-319`) : E1 reprend l'ambre, les autres le blanc, sous le halo cyan que `render` dessine encore (`:354-367`). Avec l'ordre ci-dessus, E1 garde son ambre comme aujourd'hui ; **seul changement visible : les ennemis non sélectionnés gardent une bordure cyan sous leur halo cyan, au lieu de retomber au blanc** — à chaque prise de carte, pas seulement quand un état arrive pendant qu'une carte est focalisée. L'ordre proposé par la vérification (surbrillance avant sélection) ferait en plus passer E1 de l'ambre au cyan : il changerait ce que le joueur voit aujourd'hui sur E1, à l'inverse de l'arbitrage.

`onTapDown` :

```dart
  @override
  void onTapDown(TapDownEvent event) {
    onTapEnemy(this, event.pointerId);
  }
```

`lib/game/systems/layout_system.dart:133-135`, la boucle des places :

```dart
    for (int i = 0; i < count; i++) {
      enemyCards[i].place(Vector2(startX + (i * spacing), posY));
    }
```

`lib/game/heros_draft_game.dart` — l'import `components/visual_effects/inspection_veil.dart`, puis avant la classe :

```dart
/// La fiche ouverte, telle que `GameScreen` la reflète (spec P-05 vague 1,
/// A12) : l'ennemi, et le rectangle de sa carte agrandie à l'arrivée, barre
/// et languettes au repos comprises, sur le canevas. Le rectangle ne sert
/// qu'à placer le cadre ; aucune décision de Flame ne le relit.
class EnemyInspection {
  final String enemyId;
  final Rect rect;

  const EnemyInspection({required this.enemyId, required this.rect});
}
```

Après le champ `onEnemyTargetCancelled`, et `required this.onInspectionChanged,` dans le constructeur, avant `this.onEnemyTargetCancelled` :

```dart
  /// Chaque ouverture, remplacement, fermeture de la fiche, et chaque
  /// rectangle neuf d'une fiche ouverte dont la carte se replace.
  final void Function(EnemyInspection? inspection) onInspectionChanged;

  /// L'ennemi dont la fiche est ouverte : un état d'affichage, que seul ce
  /// jeu écrit et que `GameScreen` reflète par [onInspectionChanged].
  EnemyCard? inspectedEnemy;

  /// Le pointeur de l'appui qui vient d'ouvrir ou de garder la fiche, que
  /// [closeInspectionUnlessOn] lit puis oublie, dans le même appui.
  int? _inspectionPointer;

  InspectionVeil? _inspectionVeil;

  /// Le dernier rectangle rappelé : un replacement qui ne le change pas ne le
  /// rappelle pas (chaque reconstruction de l'écran replace les ennemis, D16).
  Rect? _emittedRect;
```

Le mutateur de `awaitingEnemyTarget` et `setFocusedCard` :

```dart
  set awaitingEnemyTarget(bool value) {
    _awaitingEnemyTarget = value;
    if (value) {
      closeInspection();
    } else {
      highlightEnemy(null);
    }
  }
```

```dart
  void setFocusedCard(CardComponent? card) {
    // Saisir une carte au glisser passe aussi par ici : le glisser commence
    // par le onTapDown de la carte, qui la focalise.
    if (card != null) {
      _cancelEnemyTarget();
      // La carte touchée se lève sous la souris : relire le survol jouerait
      // son son de survol avec celui de la prise en main.
      _closeInspection(rereadHover: false);
    }
    cardAnimationSystem?.setFocusedCard(card);
  }
```

La suspension du survol : en tête de `refreshHover`, et en tête de `refreshEntityHover` (Task 4) :

```dart
    // Fiche ouverte, le plateau est estompé : aucune carte ne se lève.
    if (inspectedEnemy != null) {
      setHoveredCard(null);
      return;
    }
```

```dart
    if (inspectedEnemy != null) {
      _setHoveredEntity(null);
      return;
    }
```

`onTapDown` du décor finit par `closeInspection();` ; `onLoad` finit par `add(_inspectionVeil = InspectionVeil(size: size.clone()));` ; `onGameResize` gagne `_inspectionVeil?.size = size;` après `layoutHand();` ; `executeTurn` appelle `closeInspection();` juste après sa garde, avant `audio.onMoment(GameMoment.turnEnd)`.

`repositionEnemies`, `handlePlayerTargeting` et `_handlePlayerTargeting`, puis les méthodes neuves de la fiche :

```dart
  /// Replace les ennemis ; une fiche ouverte dont l'ennemi reste réémet son
  /// rectangle s'il a changé, pour que le cadre suive la carte (A12, D16).
  void repositionEnemies() {
    layoutSystem?.repositionEnemies();
    final enemy = inspectedEnemy;
    if (enemy != null &&
        enemyCards.contains(enemy) &&
        _isAlive(enemy) &&
        enemy.inspectionRect() != _emittedRect) {
      _emitInspection(enemy);
    }
  }

  void handlePlayerTargeting(EnemyCard target, int pointerId) {
    _handlePlayerTargeting(target, pointerId);
  }

  /// L'ordre d'A10 : une carte focalisée garde le toucher ; une signature en
  /// attente reçoit l'ennemi vivant ; sinon l'ennemi vivant ouvre sa fiche,
  /// la garde ou remplace celle d'un autre, et le pointeur est retenu.
  void _handlePlayerTargeting(EnemyCard target, int pointerId) {
    if (currentRunState == null ||
        currentRunState!.isDead ||
        currentPhase != TurnPhase.player) {
      return;
    }

    if (focusedCard != null) {
      // … la branche de la carte focalisée, inchangée …
      return;
    }

    // Un ennemi mort ou mourant laisse l attente en place et n ouvre rien :
    // l ecran ne verifie pas l ennemi qu on lui rapporte.
    if (!_isAlive(target)) return;

    if (_awaitingEnemyTarget) {
      awaitingEnemyTarget = false;
      onSelectEnemy(target.id);
      return;
    }

    inspectEnemy(target);
    _inspectionPointer = pointerId;
  }

  /// Ouvre la fiche de [enemy], ou remplace celle d'un autre ; sans effet si
  /// elle est déjà ouverte. L'état change d'abord ; les effets visuels ne
  /// jouent que sur une carte chargée (spec P-05 vague 1, A11).
  void inspectEnemy(EnemyCard enemy) {
    if (inspectedEnemy == enemy) return;
    final previous = inspectedEnemy;
    if (previous != null) _releaseInspected(previous);

    inspectedEnemy = enemy;
    // Avant la priorité de la carte ouverte : quitter le survol la remet à 0.
    _setHoveredEntity(null);
    setHoveredCard(null);
    enemy.isInspected = true;
    if (enemy.isLoaded) enemy.animateInspection();
    _inspectionVeil?.show();
    _emitInspection(enemy);
  }

  /// Ferme la fiche ouverte ; sans effet si aucune ne l'est.
  void closeInspection() => _closeInspection(rereadHover: true);

  /// [rereadHover] faux pour la seule fermeture par `setFocusedCard` : le
  /// survol reprend au prochain mouvement de la souris.
  void _closeInspection({required bool rereadHover}) {
    final enemy = inspectedEnemy;
    if (enemy == null) return;
    _inspectionPointer = null;
    _emittedRect = null;
    inspectedEnemy = null;
    _releaseInspected(enemy);
    _inspectionVeil?.hide();
    onInspectionChanged(null);
    if (rereadHover) {
      refreshHover();
      refreshEntityHover();
    }
  }

  /// Le `Listener` de `GameScreen`, à chaque appui du bouton principal, après
  /// Flame dans le même appui : la fiche reste si et seulement si [pointer]
  /// est celui que Flame vient de retenir en l'ouvrant ou en la gardant.
  void closeInspectionUnlessOn(int pointer) {
    final kept = _inspectionPointer == pointer;
    _inspectionPointer = null;
    if (!kept) closeInspection();
  }

  /// Après chaque état de combat appliqué : l'ennemi parti, la phase du
  /// joueur quittée ou le combat fini ferment la fiche (B35).
  void closeInspectionIfStale(CombatState state) {
    final enemy = inspectedEnemy;
    if (enemy == null) return;
    final stale = state.isCombatEnded ||
        state.turnPhase != TurnPhase.player ||
        !state.enemies.any((e) => e.id == enemy.id);
    if (stale) closeInspection();
  }

  /// Rend sa taille, sa place et sa bordure à une carte qui n'est plus
  /// ouverte. Une carte morte ou mourante garde ses effets de mort (D8).
  void _releaseInspected(EnemyCard enemy) {
    enemy.isInspected = false;
    if (enemy.isLoaded && _isAlive(enemy)) enemy.animateInspection();
  }

  void _emitInspection(EnemyCard enemy) {
    final rect = enemy.inspectionRect();
    _emittedRect = rect;
    onInspectionChanged(EnemyInspection(enemyId: enemy.id, rect: rect));
  }
```

`lib/game/systems/state_sync_system.dart` — `onTapEnemy: game.handlePlayerTargeting`, à la création d'une `EnemyCard`, ne change pas d'écriture (la signature suit) ; `_applyCombatState` finit par :

```dart
    currentCombatState = state;
    game.closeInspectionIfStale(state);
  }
```

`lib/ui/screens/game_screen.dart` — l'import `package:flutter/gestures.dart' show kPrimaryButton;` (sans lui, `undefined_identifier` : `material.dart` ne l'exporte pas, mesuré), l'import de `enemy_sheet_panel.dart`, puis après le champ `_armedSignature` :

```dart
  /// Le reflet de la fiche ouverte (A12) : il ne sert qu'à poser le cadre,
  /// aucune décision ne le lit.
  EnemyInspection? _inspection;
```

Dans la construction du jeu, avant `onAnimationStateChanged` :

```dart
      // Toujours différé, réémission comprise : le rappel peut venir pendant
      // le `build` du `LayoutBuilder` de `GameWidget` (`onGameResize`, puis
      // `update(0)`), où `setState` est interdit.
      onInspectionChanged: (inspection) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _inspection = inspection);
        });
      },
```

Le `body` du `Scaffold` de `build` :

```dart
        // Après Flame dans le même appui (le `GameWidget` est plus profond) :
        // tout appui du bouton principal que Flame n'a pas retenu sur la
        // fiche ouverte la ferme, HUD et cadre compris (A12).
        body: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (event.buttons == kPrimaryButton) {
              _game.closeInspectionUnlessOn(event.pointer);
            }
          },
          child: Stack(
            children: [
              // … le GameWidget et la SafeArea, inchangés …

              // Hors de la SafeArea, après elle : le cadre de la fiche ne
              // passe jamais sous le HUD (A13).
              if (_inspection case final inspection?)
                EnemySheetPanel(
                  enemyId: inspection.enemyId,
                  card: inspection.rect,
                ),
            ],
          ),
        ),
```

`lib/ui/widgets/hud/enemy_sheet_panel.dart` — `class EnemySheetPanel extends ConsumerWidget`, champs `final String enemyId` et `final Rect card`, `const EnemySheetPanel({super.key, required this.enemyId, required this.card})` — il n'importe aucun fichier Flame (D12). Son `build` lit `ref.watch(combatProvider).enemies` ; l'id absent (une ou deux images, le reflet étant différé) → `SizedBox.shrink()`. Sinon `EnemySheetView.of(enemy, charges: ref.watch(chargeCatalogProvider), l10n: AppLocalizations.of(context)!, locale: Localizations.localeOf(context).languageCode)`, et `Positioned` à `SheetPlacement.topLeftFor(card: card, screen: MediaQuery.sizeOf(context))` (D9), portant `AbsorbPointer(child: SizedBox(width: 310, …))` : le cadre absorbe ses appuis, aucun n'atteint un ennemi estompé dessous. La mise en page et les styles sont ceux du tableau de spec §5.4 (fond `#1E1E2C` à 245, liseré `amberAccent` à 100 de 1,5, rayon 12, marges 15 × 13, 5 entre deux lignes, l'ombre du panneau des intentions ; titre 14 gras `#FFD740` espacé de 0,5, niveau 12 `#7C7C8A` ; traits `white12` ; chiffres 12 gras — PV blanc, bouclier `#2196F3` de 12 et Armure `#00E5FF`, « ⚡ » et Puissance `#FF5252`, 18 entre deux ; titres de section 12 gras `#8E8E9C` espacés de 1 ; les pastilles d'`IntentPip` au style du panneau, le nom 12 gras blanc, la phrase 12 `#C9C9D6` ; bonus `#69F0AE`, altérations `#FF8A80`, la ligne d'aide 12 `#C9C9D6`) ; une section vide ne s'affiche pas (B34). Le cadre se reconstruit avec l'état.

**Les tests.** `test/unit/flame_image_prefix_test.dart`, après `onUpdateEnemyStats: (_, _) {},` (`:33`) : `onInspectionChanged: (_) {},`. `test/unit/heros_draft_game_targeting_test.dart`, en entier :

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/game/components/card_component.dart';
import 'package:roguelike_card_game/game/components/entities/enemy_card.dart';
import 'package:roguelike_card_game/game/controllers/run_controller.dart';
import 'package:roguelike_card_game/game/heros_draft_game.dart';
import 'package:roguelike_card_game/game/systems/state_sync_system.dart';
import 'package:roguelike_card_game/models/card_instance.dart';
import 'package:roguelike_card_game/models/combat_state.dart';
import 'package:roguelike_card_game/models/data/audio_data.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/charge_data.dart';
import 'package:roguelike_card_game/models/data/enemy_data.dart';
import 'package:roguelike_card_game/models/enemy_instance.dart';
import 'package:roguelike_card_game/models/entity_stats.dart';
import 'package:roguelike_card_game/services/audio/audio_director.dart';
import 'package:roguelike_card_game/services/audio/audio_settings.dart';
import 'package:roguelike_card_game/services/audio/silent_audio_backend.dart';

const _slime = EnemyData(
  id: 'slime',
  nameEn: 'Slime',
  maxHp: 18,
  baseDamage: 4,
  spritePath: 'slime.png',
);

const _strike = CardData(
  id: 'strike',
  cost: 1,
  type: CardType.attack,
  rarity: CardRarity.common,
  target: CardTarget.singleEnemy,
  effects: [CardEffect(type: 'damage', value: 6)],
);

EnemyInstance _instance(String id) => EnemyInstance(
      id: id,
      data: _slime,
      stats: EntityStats(maxPv: 18, currentPv: 18, armure: 0, might: 4),
    );

/// Une carte jamais montée : `game` posé à la main, pour que `baseScale` le
/// lise ; aucun effet visuel ne joue sur une carte non chargée.
EnemyCard _enemy(HerosDraftGame game, String id) => EnemyCard(
      instance: _instance(id),
      onTapEnemy: (_, _) {},
    )..game = game;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HerosDraftGame game;
  late List<String?> selectedIds;
  late List<CardInstance> playedCards;
  late List<EnemyInspection?> inspections;
  late int cancellations;
  late EnemyCard e1;
  late EnemyCard e2;

  setUp(() {
    selectedIds = [];
    playedCards = [];
    inspections = [];
    cancellations = 0;
    game = HerosDraftGame(
      audio: AudioDirector(
        backend: const SilentAudioBackend(),
        data: const AudioData.disabled(),
        settings: () => const AudioSettings(),
      ),
      imagesToPreload: const [],
      chargeCatalog: const ChargeCatalog.empty(),
      onEnemiesDead: () {},
      onPhaseChanged: (_) {},
      onShowTooltip: (_, _, _) {},
      onHideTooltip: () {},
      onPlayCard: (card, _) {
        playedCards.add(card);
        return false;
      },
      onEnemyKilled: () {},
      onResolveEnemyIntent: (_) {},
      onStartEnemyTurn: () => false,
      onResolveFireWave: () => false,
      onResolveEnemyStatuses: () {},
      onEndEnemyTurn: () {},
      onSelectEnemy: selectedIds.add,
      onUpdateEnemyStats: (_, _) {},
      onInspectionChanged: inspections.add,
      onEnemyTargetCancelled: () => cancellations++,
    );
    game.stateSyncSystem = StateSyncSystem()
      ..currentState = RunState(
        currentLevel: 1,
        heroClassId: 'paladin',
        heroStats: EntityStats(
          maxPv: 80,
          currentPv: 60,
          maxMana: 3,
          currentMana: 3,
          armure: 0,
          might: 0,
        ),
      );
    // Un canevas de 1280 x 800 : `scaleFactor` vaut 1, et le rectangle de la
    // fiche se calcule sans que le jeu soit charge.
    game.onGameResize(Vector2(1280, 800));
    e1 = _enemy(game, 'e1');
    e2 = _enemy(game, 'e2');
  });

  test('une cible attendue : toucher un ennemi vivant le rapporte et cesse d attendre', () {
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, ['e1']);
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 0);
    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('sans cible attendue, toucher un ennemi ne rapporte rien et ouvre sa fiche', () {
    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, isEmpty);
    expect(game.inspectedEnemy, e1);
    expect(e1.isInspected, isTrue);
    expect(inspections.single!.enemyId, 'e1');
  });

  test('toucher un second ennemi remplace la fiche', () {
    game.handlePlayerTargeting(e1, 1);
    game.handlePlayerTargeting(e2, 2);

    expect(game.inspectedEnemy, e2);
    expect(e1.isInspected, isFalse);
    expect(e2.isInspected, isTrue);
    expect(inspections.map((i) => i!.enemyId), ['e1', 'e2']);
  });

  test('toucher l ennemi dont la fiche est ouverte la garde, sans second rappel', () {
    game.handlePlayerTargeting(e1, 1);
    game.handlePlayerTargeting(e1, 2);

    expect(game.inspectedEnemy, e1);
    expect(inspections, hasLength(1));
  });

  test('une carte focalisee garde la priorite sur la cible attendue', () {
    final card = CardComponent(CardInstance(data: _strike));
    game.focusedCard = card;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(playedCards, [card.card]);
    expect(selectedIds, isEmpty);
  });

  test('une carte focalisee joue sa carte et n ouvre aucune fiche', () {
    final card = CardComponent(CardInstance(data: _strike));
    game.focusedCard = card;

    game.handlePlayerTargeting(e1, 1);

    expect(playedCards, [card.card]);
    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('un ennemi mort ou mourant n est jamais rapporte', () {
    game.awaitingEnemyTarget = true;

    e1.isDead = true;
    game.handlePlayerTargeting(e1, 1);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);

    final dying = _enemy(game, 'e3')..isPendingDeath = true;
    game.handlePlayerTargeting(dying, 2);
    expect(selectedIds, isEmpty);
    expect(game.awaitingEnemyTarget, isTrue);
  });

  test('hors du tour du joueur, aucune cible n est rapportee', () {
    game.currentPhase = TurnPhase.enemy;
    game.awaitingEnemyTarget = true;

    game.handlePlayerTargeting(e1, 1);

    expect(selectedIds, isEmpty);
  });

  test('hors du tour du joueur, un ennemi mort ou mourant : aucune fiche', () {
    game.currentPhase = TurnPhase.enemy;
    game.handlePlayerTargeting(e1, 1);
    expect(game.inspectedEnemy, isNull);

    game.currentPhase = TurnPhase.player;
    e1.isDead = true;
    game.handlePlayerTargeting(e1, 2);
    e2.isPendingDeath = true;
    game.handlePlayerTargeting(e2, 3);

    expect(game.inspectedEnemy, isNull);
    expect(inspections, isEmpty);
  });

  test('focaliser une carte ou toucher le decor annule l attente et le dit a l ecran', () {
    game.awaitingEnemyTarget = true;
    game.setFocusedCard(CardComponent(CardInstance(data: _strike)));
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 1);

    game.awaitingEnemyTarget = true;
    game.onTapDown(TapDownEvent(1, game, TapDownDetails()));
    expect(game.awaitingEnemyTarget, isFalse);
    expect(cancellations, 2);
  });

  test('focaliser une carte, armer une signature, toucher le decor, finir le tour ferment la fiche', () async {
    void open() => game.handlePlayerTargeting(e1, 1);

    open();
    game.setFocusedCard(CardComponent(CardInstance(data: _strike)));
    expect(game.inspectedEnemy, isNull);
    game.setFocusedCard(null);

    open();
    game.awaitingEnemyTarget = true;
    expect(game.inspectedEnemy, isNull);
    game.awaitingEnemyTarget = false;

    open();
    game.onTapDown(TapDownEvent(2, game, TapDownDetails()));
    expect(game.inspectedEnemy, isNull);

    open();
    await game.executeTurn();
    expect(game.inspectedEnemy, isNull);

    expect(e1.isInspected, isFalse);
    expect(inspections.where((i) => i == null), hasLength(4));
  });

  test('closeInspection sans fiche ouverte ne rappelle rien', () {
    game.closeInspection();

    expect(inspections, isEmpty);
  });

  test('l etat de combat ferme la fiche : ennemi parti, phase ennemie, combat fini', () {
    final states = [
      CombatState(enemies: [_instance('e2')]),
      CombatState(enemies: [_instance('e1')], turnPhase: TurnPhase.enemy),
      CombatState(enemies: [_instance('e1')], isCombatEnded: true),
    ];
    for (final state in states) {
      game.handlePlayerTargeting(e1, 1);
      game.closeInspectionIfStale(state);
      expect(game.inspectedEnemy, isNull);
      expect(inspections.last, isNull);
    }
  });

  test('l etat de combat garde la fiche d un ennemi vivant au tour du joueur', () {
    game.handlePlayerTargeting(e1, 1);

    game.closeInspectionIfStale(CombatState(enemies: [_instance('e1')]));

    expect(game.inspectedEnemy, e1);
    expect(inspections, hasLength(1));
  });

  test('le pointeur retenu garde la fiche une fois, puis il est oublie', () {
    game.handlePlayerTargeting(e1, 7);

    game.closeInspectionUnlessOn(7);
    expect(game.inspectedEnemy, e1);

    game.closeInspectionUnlessOn(7);
    expect(game.inspectedEnemy, isNull);
  });

  test('un autre pointeur ferme la fiche', () {
    game.handlePlayerTargeting(e1, 7);

    game.closeInspectionUnlessOn(8);

    expect(game.inspectedEnemy, isNull);
    expect(inspections.last, isNull);
  });

  test('garder la meme fiche retient aussi le pointeur', () {
    game.handlePlayerTargeting(e1, 7);
    game.closeInspectionUnlessOn(7);

    game.handlePlayerTargeting(e1, 9);
    game.closeInspectionUnlessOn(9);

    expect(game.inspectedEnemy, e1);
  });

  test('ni la carte focalisee ni la signature ne retiennent le pointeur', () {
    game.focusedCard = CardComponent(CardInstance(data: _strike));
    game.handlePlayerTargeting(e1, 5);
    game.focusedCard = null;
    game.inspectEnemy(e2);
    game.closeInspectionUnlessOn(5);
    expect(game.inspectedEnemy, isNull);

    game.awaitingEnemyTarget = true;
    game.handlePlayerTargeting(e1, 6);
    game.inspectEnemy(e2);
    game.closeInspectionUnlessOn(6);
    expect(game.inspectedEnemy, isNull);
  });

  test('replacer les ennemis reemet le rectangle de la fiche ouverte', () {
    game.enemyCards.addAll([e1, e2]);
    game.handlePlayerTargeting(e1, 1);
    final before = inspections.single!.rect;

    e1.place(Vector2(300, 200));
    game.repositionEnemies();

    expect(inspections, hasLength(2));
    expect(inspections.last!.enemyId, 'e1');
    expect(inspections.last!.rect.center.dx, closeTo(300, 0.001));
    expect(inspections.last!.rect, isNot(before));
  });

  test('replacer les ennemis sans fiche, ou fiche d un ennemi parti, ne rappelle rien', () {
    game.enemyCards.addAll([e1, e2]);
    game.repositionEnemies();
    expect(inspections, isEmpty);

    game.handlePlayerTargeting(e1, 1);
    game.enemyCards.remove(e1);
    game.repositionEnemies();
    expect(inspections, hasLength(1));
  });

  test('une reconstruction a taille inchangee ne reemet rien, un vrai redimensionnement reemet', () {
    game.enemyCards.add(e1);
    game.handlePlayerTargeting(e1, 1);

    game.onGameResize(Vector2(1280, 800));
    expect(inspections, hasLength(1));

    game.onGameResize(Vector2(1440, 900));
    expect(inspections, hasLength(2));
    expect(inspections.last!.enemyId, 'e1');
  });

  test('la selection et la surbrillance ne touchent pas la fiche, qui ne touche pas la selection', () {
    game.handlePlayerTargeting(e1, 1);

    e1.setSelection(true);
    game.highlightEnemy(e1);
    game.highlightEnemy(null);
    e1.setHighlight(true);
    e1.setHighlight(false);
    expect(e1.isInspected, isTrue);

    e1.setSelection(true);
    game.closeInspection();
    expect(e1.isInspected, isFalse);
    expect(e1.isSelected, isTrue);
  });

  test('l ecran qui rend la main n est pas rappele', () {
    game.awaitingEnemyTarget = true;
    game.awaitingEnemyTarget = false;

    expect(cancellations, 0);
  });
}
```

- [ ] **Step 1 : écrire les tests** ci-dessus (les deux fichiers).
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart` → échec de compilation (`onInspectionChanged`, `inspectedEnemy`, la signature de `handlePlayerTargeting`).
- [ ] **Step 3 : implémenter** le code ci-dessus, dans l'ordre : constantes, voile, `EnemyCard`, `LayoutSystem`, `HerosDraftGame`, `StateSyncSystem`, `EnemySheetPanel`, `GameScreen`.
- [ ] **Step 4 : vérifier.** Les deux fichiers → `+26: All tests passed!` ; `git grep -n "onTapEnemy(this)" -- lib` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1933** (1917 + 16).
- [ ] **Step 5 : commit.** `feat(bestiaire): la fiche de l ennemi, ouverte au toucher et fermee ailleurs`.

### Task 6: Le tutoriel

**Files :**
- Modify : `lib/tutorial/widgets/tutorial_combat_overview_widget.dart:307-363`, `:386-479` ; `lib/tutorial/tutorial_data.dart:252-275`

**Interfaces :**
- Consumes : la forme du panneau (Task 2) et de la barre (Task 3), que les maquettes reproduisent.
- La maquette de l'ennemi perd sa rangée « ⚡ 5 · 🛡 0 · barre · 28/28 » (`:391-443`) : une barre à la largeur de la carte, « 28/28 » dedans, sans Puissance. La maquette du panneau perd « Gobelin (Niv. 1) » (`:329`) et « ⚡ Attaque Rapide : 5 » (`:351`) : une ligne « Niv. 1 · Gobelin · [⚡ 5] » en trois colonnes, « Lvl. 1 · Goblin » en anglais. La prose de l'étape 6 ne change pas.
- L'étape « Les Intentions Ennemies » : la phrase de spec §6.3, FR et EN mot pour mot, ajoutée en dernier paragraphe de `bodyFr` (après `:275`) et de `bodyEn` (après `:262`), séparée par `\n\n`.

- [ ] **Step 1 : implémenter.**
- [ ] **Step 2 : vérifier.** `flutter test test/tutorial/` → vert ; `git grep -n "Gobelin (Niv" -- lib/tutorial` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1933**.
- [ ] **Step 3 : commit.** `feat(bestiaire): le tutoriel suit le panneau, la barre et la fiche`.

### Task 7: La vérification finale

**Files :** aucun, sauf correction d'un écart trouvé ici, par un commit de correction au nom de la tâche fautive.

- [ ] **Step 1 : l'analyse et les tests.** `dart analyze` → `No issues found!` ; `flutter test` → `+1933: All tests passed!`.
- [ ] **Step 2 : les contrôles de spec §11.**
  - aucune règle de combat ne change : `git diff c2e2dacb -- lib/game/controllers lib/game/services assets/data ':!assets/data/patch_notes.json'` → rien ;
  - aucun modèle ne change : `git diff c2e2dacb -- lib/models` → rien ;
  - plus aucun lecteur des pièces retirées : `git grep -nw -e StatBadge -e StatusIndicator -e CircleProgressComponent -e enemyStatsDesc -e hpAbbreviation -e badgeHpSize -- lib test` → rien ;
  - aucun test d'écran neuf : `git diff c2e2dacb -- test | grep -c '^+.*testWidgets(' || true` → `0` ;
  - `dart run tool/sync_assets.dart --check` → code 0.
- [ ] **Step 3 : les restes.** `git grep -n "_visuals\|getTranslation" -- lib/ui/widgets/hud lib/game/components/entities` → rien ; `git status --short` ne montre aucun fichier de plateforme généré indexé, ni `patch_notes.json`, ni `site/`, ni la ligne `version:` de `pubspec.yaml`, ni `docs/.obsidian/workspace.json`, ni `docs/possible_upgrades/upgrade_ideas.md`.
- [ ] **Step 4 : rendre** à l'orchestrateur le total de tests, la sortie de `dart analyze`, la liste des commits du plan (`git log --oneline 3b3479cf..HEAD`), et toute décision prise en cours d'exécution.

---

## Lignes de tests manuels

Les trous de la spec qui ne relèvent pas d'un test automatique (ADR-113), à reprendre par le rédacteur du fichier de tests manuels de la vague, à la suite de spec §9.1 (M1 à M20) :

| # | Tâche | Ce que fait le propriétaire | Ce qu'il doit voir |
|:---:|:---:|:---|:---|
| T4-a | 4 | Souris : cinq ennemis à 1280 × 800, survole l'ennemi le plus à droite, puis reste immobile pendant qu'un voisin meurt | Ses languettes se déroulent vers l'intérieur ; le survol suit la carte replacée sans bouger la souris |
| T4-b | 4 | Carte focalisée, touche la barre d'un ennemi, puis sa languette au repos | La carte se joue sur cet ennemi, les deux fois |
| T4-c | 4 | Le héros porte un statut ; une carte qui cible soi (Armure) focalisée, touche la languette au repos du héros | La carte se joue |
| T5-a | 5 | Sans fiche, touche la barre, puis le haut de la carte d'un ennemi ; puis sa languette au repos — sans fiche, avec sa propre fiche ouverte, avec la fiche d'un autre | La fiche s'ouvre et reste ouverte ; la languette ouvre ou garde la sienne |
| T5-b | 5 | Cinq ennemis, fiche ouverte sur l'ennemi de droite : touche Son, puis Deck, à hauteur de sa barre | La fiche se ferme |
| T5-c | 5 | Fiche ouverte : clic droit sur un autre ennemi ; puis souris sur la main ; puis, souris immobile sur une carte de la main, clic | Rien ne change ; aucune carte ne se lève au survol ; au clic, la fiche se ferme, la carte se lève et un seul son joue, celui de la prise |
| T5-d | 5 | Fiche ouverte : redimensionne la fenêtre ; puis joue une carte qui tue un ennemi et, pendant son vol, touche un autre ennemi | Le cadre suit la carte ; la fiche de l'autre ennemi s'ouvre, les cartes se replacent à la mort, le cadre suit ; aucune erreur dans la console |
| T5-e | 5 | Fiche d'un ennemi gelé ; fiche d'un boss ; fiche d'un ennemi qui porte un bonus et une altération | « Gelé : ne fait rien ce tour » ; le boss grandit vers le bas sans sortir de l'écran ; le cadre ne couvre pas la languette du côté où il se pose |
| T5-f | 5 | Joue une attaque mortelle et, pendant son vol, touche sa cible | Aucune fiche ne s'ouvre (la cible est mourante) ; elle meurt et disparaît. D8 est une garde défensive qu'un geste ordinaire n'atteint pas |
| T5-g | 5 | Joue une attaque sur un ennemi et touche-le juste après l'impact, pendant sa secousse ; puis joue une attaque sur un ennemi, touche-le avant l'impact (sa fiche s'ouvre) et touche le décor juste après l'impact ; enfin, fiche ouverte, redimensionne la fenêtre | La carte finit agrandie exactement (× 1,25 de sa taille au repos), puis exactement à sa taille au repos ; au redimensionnement, ni trop grande ni trop petite |
| T5-h | 5 | Touche un ennemi, puis un autre, puis ferme ; souris immobile fiche ouverte | La carte grandit et descend en 0,15 s, sans à-coup, et revient de même ; fiche ouverte, rien ne bouge ni ne clignote |
| T5-i | 5 | Attaque un ennemi, puis prends une carte qui cible les ennemis | L'ennemi déjà frappé garde son bord ambre ; les autres ont une bordure cyan sous leur halo, au lieu du blanc d'avant (D14) |
