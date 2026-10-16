# P-43 E4, partie 2 — Les signatures : ce que le joueur voit — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** À la fin de ce plan, le joueur voit et joue ses deux signatures : une barre à gauche du HUD, à mi-hauteur, dont chaque tuile dit son état (inactive, en recharge, mana insuffisant, armée, disponible) et se joue d'un toucher — puis d'un toucher sur l'ennemi pour une signature à cible unique ; les signatures figurent sur la carte de classe et dans un troisième onglet du dictionnaire ; le tutoriel les enseigne par la prose de l'étape « Votre deck de départ » et par le bandeau du draft.

**Architecture:** La partie 1 a livré le moteur (`CombatController.playSignature`, `CombatState.signatureTurnsLeft`, `RunState.signatures`) ; cette partie ne fait que le montrer. La barre (`SignatureBar`, Flutter) ne lit ni provider ni composant Flame : `GameScreen` lui passe tout ce qu'elle montre et reçoit ses gestes par rappels ; la priorité des cinq états est une fonction pure, testée seule. Le ciblage est un contrat étroit : l'écran arme, Flame rapporte un ennemi vivant par le rappel `onSelectEnemy` qui existait sans appelant, ou annule par `onEnemyTargetCancelled` ; Flame ne connaît ni `SignatureInstance` ni la barre. Hors combat, un seul widget de tuile (`SignatureTile`, compacte ou détaillée) sert la sélection de classe et le dictionnaire.

**Tech Stack:** Flutter / Dart 3.11, Flame 1.38, Riverpod 2 (`Notifier`), `flutter_test`, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-10-15-p43-e4-signatures-design.md` — §11 « Partie 2 » pour le périmètre ; §5 (la barre, son ciblage, le jeu côté écran), §6 (sélection de classe, dictionnaire), §7 (textes joueur, clés ARB, tutoriel) ; les lignes « 2 » de la table §10. Les décisions de §1 sont acquises, A6 comprise (la forme de la barre, déléguée par le propriétaire et tranchée par la spec) : aucune ne se rouvre ici. Les options écartées sont dans `docs/superpowers/specs/2026-10-15-p43-e4-signatures-design-verifications.md`.

Réponses du propriétaire, reprises telles quelles (spec §1.2) : recharge 2 pour les six, aux coûts d'aujourd'hui ; une signature jouée déclenche passifs et reliques de son type ; **Q-P2 (a)** — le tutoriel enseigne la barre par la prose seule, dans l'étape « Votre deck de départ » (texte exact en spec §7.2), sans étape jouable ; la barre : à gauche, à mi-hauteur, cinq états, toucher la signature puis l'ennemi (A6).

## Global Constraints

Celles du fichier d'orchestration, §3.5, recopiées :

- `dart analyze` doit rendre `No issues found!` et `flutter test` être entièrement vert **à la fin de chaque tâche** ;
- **ne rien pousser, n'ouvrir aucune PR, n'invoquer aucun skill de livraison** — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync` ;
- **jamais `dart format`** ; Write / Edit plutôt que heredoc ;
- les fichiers que `flutter` régénère sont **suivis** par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification (`git add` par chemin, jamais `git add -A`), les restaurer par `git restore` s'ils apparaissent modifiés ;
- après toute retouche d'un fichier ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit ;
- après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge — `flutter test` ne purge jamais ce dossier, et la copie périmée d'un fichier disparu continue d'être chargée ;
- tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart` ;
- les trois couches de `CLAUDE.md` ne se mélangent pas ; pas de code sans lecteur, pas de code mort ;
- commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By` que la session fournit (`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) ;
- ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/` : ils appartiennent à `patch-notes-writer`.

Propres à cette partie :

- **Un lecteur dans `lib/` au plus tard à une tâche nommée** (arbitrage de l'orchestrateur, T, filtre 8). Les Tasks 1 à 3 créent des widgets et des membres que seuls leurs tests lisent d'abord : `SignatureTile` (Task 1) reçoit son lecteur à la Task 5 ; `SignatureBar` (Task 2), `awaitingEnemyTarget` et `onEnemyTargetCancelled` (Task 3) le reçoivent à la Task 4. `SignatureData.getDescription` et la clé `signatureCostAndCooldown` (Task 1) sont lus par `SignatureTile` dès la Task 1, et par l'écran de combat à la Task 4 ; les clés `signatureChooseTarget` et `signatureTurnsLeft` sont lues par `SignatureBar` dès la Task 2. La vérification finale (Task 7) contrôle qu'aucun ne reste sans lecteur. Cela diffère de V1 en partie 1, où `getDescription` n'aurait eu de lecteur dans aucune tâche de la partie.
- **Jamais `git stash` ni `git commit --amend`** : un fichier oublié va dans un second commit.
- **La branche.** Le plan s'exécute sur `feat/v0.5.6-p43-e4-signatures`, la branche courante, dans le checkout principal, à la suite des commits de la partie 1 (`e7abe74`..`a5a91ef`, puis `1315aab`). Il ne crée aucune branche, n'en change pas, ne commite rien sur `main`, ne pousse rien. Pas de worktree.
- **La base de tests** : `flutter test` rend **1663** sur la branche aujourd'hui (relevé le 2026-10-16). Chaque tâche donne son total cumulé ; un écart est un constat, jamais un « à peu près ».
- **Les trois couches** (spec §5.3) : Flame (`lib/game/`) ne connaît ni `SignatureInstance` ni la barre ; `SignatureBar` et `SignatureTile` n'importent rien de Flame ni de `lib/game/components/`, et ne lisent aucun provider ; seul `GameScreen` relie les deux.
- **Ni `assets/`, ni le moteur ne changent** : `playSignature`, `CombatState`, `RunState` et les six fichiers de signature restent ceux de la partie 1. `playSignature` ne vérifie pas qu'`enemyId` désigne un ennemi présent (arbitrage de l'orchestrateur, comme le chemin d'une carte, spec §4.3) : c'est le contrat du ciblage (Task 3) qui le garantit.
- **Les textes de l'écran de draft ne changent pas** (spec §6) : `draftDeckSubtitle` (« 5 cartes globales ») reste tel quel, même quand la locale `globalCards` se renomme (Task 6).
- **Aucun test neuf ne porte un littéral que vise la commande de §12** : ni `'unique'`, `"unique"`, `` `unique` ``, ni `CardCategory`, `isOfferableTo`, `isAcquirable`, `characterSpecific`, `isUnique`, `rarityUnique`.
- **Les références `fichier:ligne`** de ce plan ont été relues le 2026-10-16 sur `1315aab`. Une tâche qui modifie un fichier décale les lignes des suivantes : l'implémenteur se fie au symbole nommé.
- **Une question P (P-2), sans réponse à l'écriture** (voir la fin du plan) : le contenu de la tuile détaillée (Task 1). Le plan applique sa recommandation ; une autre réponse du propriétaire ne change qu'une étape, nommée.

## Review Focus

Cinq modes d'échec que la spec implique et qu'aucun test ne garde encore, du plus grave au moins grave ; chacun est confié à la tâche qui écrit le test qui le garde.

1. **Une signature jouée contre un ennemi que le joueur n'a pas choisi, ou mort.** `playSignature` ne vérifie pas l'ennemi : si Flame rapportait un ennemi mort ou mourant (touché pendant son fondu, `isDead` / `isPendingDeath`), ou si l'écran passait la sélection restante d'une carte, le mana serait payé et la recharge posée pour rien. Attendu : seul un ennemi vivant, touché pendant l'attente, atteint `onSelectEnemy`, et `GameScreen` ne passe à `playSignature` que cet id. → **Task 3** (« un ennemi mort ou mourant n est jamais rapporte », « sans cible attendue, toucher un ennemi ne rapporte rien ») ; la seconde moitié — l'écran ne lit jamais `combatState.selectedEnemyId` — reste au test manuel (Task 4).
2. **Une tuile qui se joue quand elle ne doit pas** : pendant le tour ennemi ou une animation de carte, en recharge, ou sans le mana. Attendu : l'ordre de priorité de §5.2 — inactive, en recharge, mana insuffisant, armée, disponible — le premier qui s'applique gagne, et seules les tuiles disponibles ou armées répondent. → **Task 2** (« la priorite des etats … », « une tuile inactive … ne repond pas », « toucher une tuile en recharge n appelle rien »).
3. **Le ciblage qui vole le geste d'une carte, ou une attente qui survit.** Attendu : une carte focalisée garde la priorité sur une cible attendue ; focaliser ou saisir une carte, ou toucher le décor, annule l'attente et le dit à l'écran ; l'écran qui désarme (tuile retouchée, fin de tour) n'est pas rappelé en retour. → **Task 3** (trois tests) ; la fin de tour, au test manuel (Task 4).
4. **Mana insuffisant sur une tuile, sans retour.** Attendu : le son `insufficientMana` et une secousse, comme une carte (`card_interaction_handler.dart:134-139`) ; rien n'est joué, rien n'est armé. → **Task 2** (« mana insuffisant : le son, la secousse, rien n est joue »).
5. **Le troisième onglet qui décale les deux premiers.** `card_dictionary_order_test.dart:149` touche `find.byType(Tab).at(1)` et s'attend aux reliques. Attendu : Cartes, Reliques, Signatures, dans cet ordre. → **Task 5** (« le dictionnaire a trois onglets … », et `card_dictionary_order_test.dart` rejoué sans retouche).

**Les trous reportés à cette partie** (vérification de la spec, section « Pour le Review Focus du plan » ; plan de la partie 1, ligne « Reportés au plan de la partie 2 »), chacun confié à un test nommé :

| Trou | Tâche, test |
|:---|:---|
| La priorité des cinq états de la barre (§5.2) | Task 2, « la priorite des etats : inactive, recharge, mana, armee, disponible » |
| Le ciblage depuis Flame — une carte focalisée garde la priorité, l'annulation fonctionne. `HerosDraftGame` se construit en test (`flame_image_prefix_test.dart:11`) : **le test est faisable**, sans monter le jeu, en injectant un `StateSyncSystem` porteur d'un `RunState` et des composants non montés | Task 3, sept tests de `heros_draft_game_targeting_test.dart` |
| Mana insuffisant sur une tuile : son et secousse, rien n'est joué | Task 2 |
| L'onglet « Signatures » en troisième position ; `card_dictionary_order_test.dart:149` (`Tab.at(1)`) reste sur les reliques | Task 5 |
| Le bandeau du tutoriel | Task 6, `tutorial_starter_draft_test.dart` |
| L'`enemyId` venu de l'écran : seul un ennemi vivant, venu de Flame | Task 3 (côté Flame) ; Task 4, test manuel (côté écran) |
| `SignatureData.getDescription`, sans lecteur avant les tuiles | Task 1, avec son premier lecteur |

**Ce qui reste au test manuel** — la glue de `GameScreen` n'a pas de banc de test dans le dépôt (aucun test ne monte l'écran de combat) : voir la liste en fin de Task 4.

---

## Carte des fichiers

| Fichier | Rôle | Tâche |
|:---|:---|:---:|
| `lib/models/data/signature_data.dart` | `getDescription(String locale)` | 1 |
| `lib/ui/widgets/signature_tile.dart` *(nouveau)* | `SignatureTile` : la tuile hors combat, compacte ou détaillée | 1 |
| `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` + les trois `lib/l10n/app_localizations*.dart` régénérés | Les quatre clés de §7.1, chacune avec son premier lecteur | 1, 2, 5 |
| `lib/ui/widgets/hud/signature_bar.dart` *(nouveau)* | `SignatureBar`, ses tuiles, `SignatureTileState`, `signatureTileStateOf` | 2 |
| `lib/game/heros_draft_game.dart` | `awaitingEnemyTarget`, `onEnemyTargetCancelled`, la branche de ciblage, l'illumination au survol, l'annulation | 3 |
| `lib/ui/screens/game_screen.dart` | La barre posée ; armer, désarmer, `_playSignature`, l'avertissement de mana extrait, l'infobulle | 4 |
| `lib/ui/screens/class_selection_screen.dart` | Le bloc « Signatures » de la carte de classe | 5 |
| `lib/ui/screens/card_dictionary_screen.dart` | Le troisième onglet | 5 |
| `lib/tutorial/tutorial_data.dart` | La prose des étapes « Votre deck de départ » et « La Fusion de Cartes » | 6 |
| `lib/tutorial/widgets/tutorial_starter_deck_widget.dart` | Le bandeau ; la doc du pool | 6 |
| `lib/ui/screens/starter_deck_draft_screen.dart` | La locale `globalCards` renommée | 6 |
| `test/unit/signature_data_test.dart` ; `test/widget/signature_tile_test.dart`, `test/widget/signature_bar_test.dart`, `test/unit/heros_draft_game_targeting_test.dart` *(nouveaux)* | — | 1, 2, 3 |
| `test/widget/class_selection_screen_test.dart`, `test/widget/card_dictionary_screen_test.dart`, `test/widget/tutorial_starter_draft_test.dart`, `test/tutorial/tutorial_prose_test.dart` | Les assertions neuves seulement | 5, 6 |

Ordre : les widgets d'abord, sans lecteur dans le jeu mais chacun avec ses tests (Tasks 1, 2) ; le contrat Flame ensuite (Task 3), dont le rappel neuf n'est branché qu'à la Task 4 — ses tests en sont le lecteur d'ici là ; l'écran de combat relie le tout (Task 4) ; puis les écrans hors combat (Task 5) et le tutoriel (Task 6), indépendants entre eux.

---

### Task 1: La tuile hors combat — `SignatureTile`, `getDescription`, la ligne « Coût · Recharge »

**Files:**
- Modify: `lib/models/data/signature_data.dart` (à côté de `getName`, `:51`), `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`, puis régénérés : `lib/l10n/app_localizations.dart`, `app_localizations_fr.dart`, `app_localizations_en.dart`
- Create: `lib/ui/widgets/signature_tile.dart`
- Test: `test/unit/signature_data_test.dart`, `test/widget/signature_tile_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `SignatureData` (partie 1) ; `getCardTypeColor(CardType?)` et `getCardTypeLabel(BuildContext, CardType?)` (`lib/ui/widgets/ui_card/ui_card_helpers.dart:152`, `:224`).
- Produces:
  - `String SignatureData.getDescription(String locale)` — `descriptionFr` si `locale == 'fr'`, sinon `descriptionEn`, comme `getName`.
  - Clé ARB `signatureCostAndCooldown`, générée en `String signatureCostAndCooldown(int cost, int cooldown)`.
  - `class SignatureTile extends StatelessWidget` — `const SignatureTile({super.key, required SignatureData signature, required Color classColor, bool detailed = false})`. Lit la locale et `AppLocalizations` dans le contexte ; aucun provider.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/signature_data_test.dart`, un neuf — `getDescription rend la description de la langue` : sur `SignatureData.fromJson(valid())`, `getDescription('fr')` égale `description_fr` et `getDescription('en')` égale `description_en`.

`test/widget/signature_tile_test.dart` *(nouveau)* — une `SignatureData` construite : `smite`, `heroClass` `paladin`, noms `Smite` / `Châtiment`, descriptions `Deal 6 damage and gain 4 Block.` / `Inflige 6 dégâts et donne 4 d'Armure.`, `cost` 1, `cooldown` 2, `type` attack. La tuile est pompée dans un `MaterialApp` aux délégués de `AppLocalizations` (comme `card_dictionary_screen_test.dart:115-130`), `classColor` `Color(0xFF2196F3)` :
- `la tuile compacte montre le nom, la ligne cout et recharge, la description` — en anglais : `Smite`, `Cost: 1 Mana · Cooldown: 2 turns`, `Deal 6 damage and gain 4 Block.`, chacun `findsOneWidget`.
- `en francais la ligne dit Cout et Recharge, au singulier pour un tour` — en français : `Coût : 1 Mana · Recharge : 2 tours` ; puis la même signature à `cooldown` 1 : `Coût : 1 Mana · Recharge : 1 tour`.
- `la tuile detaillee montre aussi le type de la signature` — `detailed: true` → `Attack` (`cardTypeAttack`) `findsOneWidget` ; la compacte → `findsNothing` *(dépend de P-2 ; voir Step 3)*.
- `la bordure porte la couleur de la classe` — un `Container` de la tuile a une `BoxDecoration` dont `border.top.color` égale `classColor`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/signature_data_test.dart test/widget/signature_tile_test.dart`
Expected: échec de compilation — `getDescription`, `SignatureTile` et `signatureCostAndCooldown` n'existent pas.

- [ ] **Step 3: Implémenter**

- La clé, dans les deux ARB, avec sa métadonnée `@signatureCostAndCooldown` (`cost` et `cooldown` en `int`), valeurs **mot pour mot** de §7.1 — FR : `Coût : {cost} Mana · Recharge : {cooldown, plural, =1{1 tour} other{{cooldown} tours}}` ; EN : `Cost: {cost} Mana · Cooldown: {cooldown, plural, =1{1 turn} other{{cooldown} turns}}`. Puis `flutter gen-l10n`.
- `getDescription` dans `SignatureData`.
- `SignatureTile` — une carte rectangulaire : bordure de `classColor`, liseré de la couleur du type (`getCardTypeColor(signature.type)`) ; le nom (`getName`), la ligne `signatureCostAndCooldown(signature.cost, signature.cooldown)`, la description (`getDescription`). `detailed: false` (sélection de classe) : typographie réduite ; `detailed: true` (dictionnaire) : typographie pleine et, sous le nom, le libellé du type (`getCardTypeLabel`) — **recommandation de P-2** ; si le propriétaire répond autrement, seuls cette ligne et le troisième test changent. La tuile lit la donnée, pas une `SignatureInstance` : hors combat, il n'y a pas de run (spec §6).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/signature_data_test.dart test/widget/signature_tile_test.dart`
Expected: tout passe (14 + 4).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1668** (1663 + 1 + 4).

- [ ] **Step 6: Commit**

`git add lib/models/data/signature_data.dart lib/ui/widgets/signature_tile.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_en.dart test/unit/signature_data_test.dart test/widget/signature_tile_test.dart` puis `git commit` — `feat(signatures): la tuile hors combat et sa ligne cout et recharge`.

---

### Task 2: La barre au HUD — `SignatureBar`, ses cinq états et leurs gestes

**Files:**
- Create: `lib/ui/widgets/hud/signature_bar.dart`
- Modify: `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`, puis les trois `lib/l10n/app_localizations*.dart` régénérés
- Test: `test/widget/signature_bar_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: `SignatureInstance` (`cost`, `cooldown`, `data`), `CombatState.signatureTurnsLeft(String id)` (partie 1) ; `SignatureData.getName` (partie 1) ; `getCardTypeColor` (existant, `ui_card_helpers.dart:152`).
- Produces:
  - `enum SignatureTileState { inactive, recharging, unaffordable, armed, available }` — dans l'ordre de priorité de §5.2.
  - `SignatureTileState signatureTileStateOf({required bool interactive, required int turnsLeft, required bool affordable, required bool armed})` — fonction de premier niveau, pure : `inactive` si `!interactive`, sinon `recharging` si `turnsLeft > 0`, sinon `unaffordable` si `!affordable`, sinon `armed` si `armed`, sinon `available`.
  - `class SignatureBar extends StatelessWidget` — `const SignatureBar({super.key, required List<SignatureInstance> signatures, required CombatState combatState, required int currentMana, required bool interactive, required Color classColor, required String? armedId, required ValueChanged<SignatureInstance> onPlay, required ValueChanged<SignatureInstance> onArm, required VoidCallback onDisarm, required VoidCallback onInsufficientMana, required ValueChanged<SignatureInstance> onShowTooltip, required VoidCallback onHideTooltip})`. Aucun provider, aucun import de Flame.
  - Chaque tuile porte la clé `ValueKey('signature-tile-<id>')`, **sous** la translation de la secousse : sur la boîte qui se déplace.
  - Clés ARB `signatureChooseTarget` (`String get signatureChooseTarget`) et `signatureTurnsLeft` (`String signatureTurnsLeft(int count)`).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/widget/signature_bar_test.dart` *(nouveau)* — deux `SignatureData` construites : `smite` (attack, `singleEnemy`, `cost` 1, `cooldown` 2, nom `Smite`) et `holy_shield` (skill, `self`, `cost` 1, `cooldown` 2, nom `Holy Shield`), enveloppées en `SignatureInstance`. La barre est pompée dans un `MaterialApp` localisé, sous un `Stack` (elle rend un `Positioned`), avec des rappels qui comptent leurs appels et gardent leur argument. Une recharge se pose par `CombatState(turnCount: 1, signaturesReadyOn: {'smite': 3})` (2 tours restants). La bordure pulsante de l'état armé se répète sans fin : tout test où `armedId` n'est pas nul pompe par `pump()`, jamais par `pumpAndSettle`.
- `la priorite des etats : inactive, recharge, mana, armee, disponible` — sur `signatureTileStateOf` : tout faux sauf `interactive` et `affordable` → `available` ; `armed: true` → `armed` ; `affordable: false, armed: true` → `unaffordable` ; `turnsLeft: 2, affordable: false, armed: true` → `recharging` ; `interactive: false, turnsLeft: 2, affordable: false, armed: true` → `inactive`.
- `une tuile en recharge affiche son compte, en anglais et en francais` — `2 turns` (EN) puis `2 tours` (FR) `findsOneWidget` ; à `signaturesReadyOn: {'smite': 2}`, `1 tour` (FR).
- `une tuile inactive garde son compte lisible et ne repond pas` — `interactive: false`, `smite` en recharge : `2 turns` visible ; toucher les deux tuiles n'appelle aucun des quatre rappels de geste.
- `toucher une tuile en recharge n appelle rien` — `interactive: true`, `smite` en recharge : toucher `smite` → aucun rappel.
- `toucher une tuile disponible sans cible d ennemi la joue aussitot` — toucher `holy_shield` → `onPlay` une fois, avec `holy_shield` ; `onArm` jamais.
- `toucher une tuile disponible qui vise un ennemi l arme` — toucher `smite` → `onArm` une fois, avec `smite` ; `onPlay` jamais.
- `une tuile armee montre l invite et se desarme au toucher` — `armedId: 'smite'` → `Choose a target` `findsOneWidget` ; toucher `smite` → `onDisarm` une fois, `onArm` jamais ; avec `armedId: null`, `Choose a target` `findsNothing`.
- `mana insuffisant : le son, la secousse, rien n est joue` — `currentMana: 0` : toucher `smite` une seule fois → `onInsufficientMana` une fois, `onPlay` et `onArm` jamais ; puis `await tester.pump()` (le premier frame démarre l'animation à t = 0), puis `await tester.pump(const Duration(milliseconds: 25))` : `tester.getTopLeft(find.byKey(ValueKey('signature-tile-smite')))` diffère de sa position au repos — un seul `pump` de 25 ms lirait encore le repos, le ticker partant d'un temps écoulé nul ; après `pumpAndSettle`, il y revient. La clé est aussi portée **sous** la translation de la secousse (Interfaces) : c'est une seconde condition, indépendante du pompage.
- `les tuiles suivent l ordre donne et mesurent 76, 64 sous 600 de large` — `signatures: [holy_shield, smite]` : la tuile `holy_shield` est au-dessus de `smite` ; `tester.getSize` d'une tuile vaut `Size(76, 76)` sur une vue de 1280 × 800, `Size(64, 64)` sur 400 × 800.
- `le survol montre l infobulle de la signature, la sortie et l appui long aussi` — un geste souris (`tester.createGesture(kind: PointerDeviceKind.mouse)`) qui entre sur `smite` → `onShowTooltip` avec `smite` ; qui en sort → `onHideTooltip` une fois ; un appui long sur `holy_shield` → `onShowTooltip` avec `holy_shield`, puis, au relâcher, `onHideTooltip` — deux appels de `onHideTooltip` en tout.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/signature_bar_test.dart`
Expected: échec de compilation — `signature_bar.dart` n'existe pas.

- [ ] **Step 3: Implémenter**

- Les deux clés, dans les deux ARB, valeurs **mot pour mot** de §7.1 — `signatureChooseTarget` : `Choisissez une cible` / `Choose a target` ; `signatureTurnsLeft` (métadonnée : `count` en `int`) : `{count, plural, =1{1 tour} other{{count} tours}}` / `{count, plural, =1{1 turn} other{{count} turns}}`. Puis `flutter gen-l10n`.
- Placement (§5.1) : posée comme `TurnControlPanel` (`turn_control_panel.dart:27`), un `Positioned.fill` qui ne capte que ses tuiles ; une colonne centrée sur la hauteur, à `left: 20`, en miroir du bouton de fin de tour (`turn_control_panel.dart:101-104`, `right: 20`). Tuiles carrées de **76 px, 64 px si la largeur est < 600**, dans l'ordre de `signatures` ; sous la colonne, l'invite `signatureChooseTarget` quand `armedId != null`.
- Une tuile (§5.1) : médaillon de coût en haut à gauche ; le nom (`getName`), deux lignes au plus ; liseré de la couleur du type (`getCardTypeColor`) ; bordure de `classColor`.
- Les états (§5.2), calculés par `signatureTileStateOf` avec `turnsLeft = combatState.signatureTurnsLeft(id)`, `affordable = currentMana >= signature.cost`, `armed = armedId == id` : **inactive** atténuée, le compte de recharge encore lisible s'il y en a un ; **recharging** grisée, le compte au centre ; **unaffordable** couleurs gardées, médaillon de coût en `Colors.redAccent` (la couleur d'une carte inabordable, `card_component.dart:60`) ; **armed** bordure pulsante ; **available** pleine couleur, lueur de `classColor`. Le compte s'écrit `signatureTurnsLeft(turnsLeft)`, centré, en grand, d'un bloc (PM19, question T tranchée : la forme de la barre est déléguée, A6).
- Les gestes (§5.2, colonne « Toucher ») : `inactive`, `recharging` → rien ; `unaffordable` → `onInsufficientMana` et une secousse horizontale de ±5 px en 250 ms (la séquence de `card_animator.dart:121-129`) ; `armed` → `onDisarm` ; `available` → `onArm` si `target == CardTarget.singleEnemy`, sinon `onPlay`. Survol (souris) : `onShowTooltip` à l'entrée, `onHideTooltip` à la sortie ; appui long : `onShowTooltip` au début (`onLongPressStart`), `onHideTooltip` à `onLongPressEnd` et à `onLongPressCancel` — sans quoi l'infobulle ouverte sur mobile ne se fermerait jamais : rien d'autre ne la masque. Précédent du dépôt : `stat_badge.dart:472-486` (`onLongTapDown` montre, `onTapUp` et `onTapCancel` masquent).
- La barre reste sans état (spec §5.1) ; la secousse, état d'animation purement visuel, vit dans un widget de tuile privé à état, interne au fichier.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/widget/signature_bar_test.dart`
Expected: tout passe (10).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1678** (1668 + 10) ; `git grep -nE "package:flame|game/components|heros_draft_game|ref\.(read|watch)" -- lib/ui/widgets/hud/signature_bar.dart lib/ui/widgets/signature_tile.dart` → vide.

- [ ] **Step 6: Commit**

`git add lib/ui/widgets/hud/signature_bar.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_en.dart test/widget/signature_bar_test.dart` puis `git commit` — `feat(signatures): la barre du HUD et ses cinq etats`.

---

### Task 3: Le ciblage côté Flame — attendre un ennemi, le rapporter, annuler

**Files:**
- Modify: `lib/game/heros_draft_game.dart` — le constructeur (`:81-97`), `setFocusedCard` (`:116-118`), `onPointerMove` (`:120-124`), `onTapDown` (`:126-130`), `_handlePlayerTargeting` (`:277-300`)
- Test: `test/unit/heros_draft_game_targeting_test.dart` *(nouveau)*

**Interfaces:**
- Consumes: le rappel existant `onSelectEnemy` (`heros_draft_game.dart:77`, `void Function(String? enemyId)`), qu'aucun code Flame n'appelle aujourd'hui (mesuré : `git grep -n "onSelectEnemy" -- lib` ne rend que sa déclaration, son paramètre et son branchement `game_screen.dart:392`) ; `highlightEnemy` (`:179-185`) ; `EnemyCard.isDead`, `isPendingDeath` (`enemy_card.dart:40-41`).
- Produces:
  - `bool get awaitingEnemyTarget` et `set awaitingEnemyTarget(bool value)` — mettre `false` éteint l'ennemi illuminé (`highlightEnemy(null)`) et **n'appelle pas** `onEnemyTargetCancelled` : c'est l'écran qui désarme, il n'a pas à être rappelé.
  - `final VoidCallback? onEnemyTargetCancelled` — paramètre nommé facultatif du constructeur, comme `onAnimationStateChanged`. Appelé seulement quand Flame annule l'attente.
  - Aucun type de signature : Flame ne rapporte qu'un id d'ennemi.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/unit/heros_draft_game_targeting_test.dart` *(nouveau)* — le jeu est construit comme `_buildGame` de `flame_image_prefix_test.dart:11-30`, **sans être monté**, avec des rappels qui enregistrent : `onSelectEnemy` (les ids reçus), `onPlayCard` (les cartes reçues ; rend `false`), `onEnemyTargetCancelled` (le nombre d'appels). Avant chaque test : `game.stateSyncSystem = StateSyncSystem()..currentState = <un RunState minimal, comme run_state_persistence_test.dart:58, currentPv > 0>` — c'est ce que lit `currentRunState`. Un ennemi : `EnemyCard(instance: EnemyInstance(id: 'e1', …), onTapEnemy: (_) {})`, non monté (`EnemyInstance` comme `test/encounter_system_test.dart:335`). Une carte : `CardComponent(CardInstance(data: <une attaque singleEnemy>))`, non montée (`canAfford` vaut alors `true`, `card_component.dart:53-54`).
- `une cible attendue : toucher un ennemi vivant le rapporte et cesse d attendre` — `awaitingEnemyTarget = true` ; `handlePlayerTargeting(e1)` → `onSelectEnemy` a reçu `['e1']`, `awaitingEnemyTarget` est faux, `onEnemyTargetCancelled` n'a pas été appelé.
- `sans cible attendue, toucher un ennemi ne rapporte rien` — `handlePlayerTargeting(e1)` → `onSelectEnemy` n'a rien reçu (le comportement d'aujourd'hui).
- `une carte focalisee garde la priorite sur la cible attendue` — `game.focusedCard = <la carte>` (le champ, `heros_draft_game.dart:38`), `awaitingEnemyTarget = true` ; `handlePlayerTargeting(e1)` → `onPlayCard` a reçu la carte, `onSelectEnemy` rien.
- `un ennemi mort ou mourant n est jamais rapporte` — `awaitingEnemyTarget = true` ; `e1.isDead = true` → rien reçu, l'attente demeure ; idem avec un second ennemi `isPendingDeath = true`.
- `hors du tour du joueur, aucune cible n est rapportee` — `currentPhase = TurnPhase.enemy`, `awaitingEnemyTarget = true` → rien reçu.
- `focaliser une carte ou toucher le decor annule l attente et le dit a l ecran` — `awaitingEnemyTarget = true` ; `setFocusedCard(<la carte>)` → `awaitingEnemyTarget` faux, `onEnemyTargetCancelled` appelé une fois ; de nouveau `true` ; `onTapDown(TapDownEvent(1, game, TapDownDetails()))` → faux, deux appels en tout.
- `l ecran qui rend la main n est pas rappele` — `awaitingEnemyTarget = true` puis `false` → `onEnemyTargetCancelled` jamais appelé.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/unit/heros_draft_game_targeting_test.dart`
Expected: échec de compilation — `awaitingEnemyTarget` et `onEnemyTargetCancelled` n'existent pas.

- [ ] **Step 3: Implémenter**

- `_handlePlayerTargeting`, après la garde existante (run nulle, héros mort, tour ennemi) : si `focusedCard != null`, le chemin de la carte, inchangé, et rien d'autre ; sinon, si `awaitingEnemyTarget` et que la cible n'est ni `isDead` ni `isPendingDeath` : `awaitingEnemyTarget = false`, puis `onSelectEnemy(target.id)`. Un ennemi mort ou mourant laisse l'attente en place : `playSignature` ne vérifie pas l'ennemi (Global Constraints), Flame ne rapporte donc qu'un ennemi vivant.
- Une méthode privée d'annulation : si l'attente est en cours, `awaitingEnemyTarget = false` puis `onEnemyTargetCancelled?.call()`. Appelée par `setFocusedCard` quand la carte n'est pas nulle (avant de déléguer à `cardAnimationSystem`) — ce qui couvre aussi la carte saisie, puisque le glisser commence par le `onTapDown` de la carte, qui la focalise (`card_interaction_handler.dart:30-44`, `:59-66`) — et par `onTapDown` du jeu, qui ne reçoit que les touchers du décor : un ennemi, le héros ou une carte arrêtent la propagation (`Event.continuePropagation`, faux par défaut en Flame 1.38).
- `onPointerMove` : tant que `awaitingEnemyTarget`, `highlightEnemy` de l'ennemi vivant sous le pointeur (`containsPoint`, comme `card_interaction_handler.dart:171-178`), ou `null`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart`
Expected: tout passe (7 + 3).

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1685** (1678 + 7) ; `git grep -nEi "signature" -- lib/game/heros_draft_game.dart lib/game/components lib/game/systems` → vide.

- [ ] **Step 6: Commit**

`git add lib/game/heros_draft_game.dart test/unit/heros_draft_game_targeting_test.dart` puis `git commit` — `feat(signatures): le ciblage cote Flame, attendre un ennemi vivant ou annuler`.

---

### Task 4: Le jeu côté écran — `GameScreen` pose la barre, arme, joue

**Files:**
- Modify: `lib/ui/screens/game_screen.dart` — l'état (`:42-68`), le constructeur du jeu (`:300-412`, dont `onPlayCard` `:327-377` et `onSelectEnemy` `:392-394`), `build` (`:428-589`, dont `TurnControlPanel` `:535-561` et `CombatTooltipOverlay` `:576-581`)
- Test: aucun neuf — l'écran de combat n'a pas de banc de test ; voir « Test manuel » ci-dessous

**Interfaces:**
- Consumes: `SignatureBar` (Task 2) ; `HerosDraftGame.awaitingEnemyTarget`, `onEnemyTargetCancelled` (Task 3) ; `SignatureData.getDescription`, `signatureCostAndCooldown` (Task 1) ; `CombatController.playSignature(SignatureInstance, {String? enemyId}) → bool`, `RunState.signatures` (partie 1) ; `ClassIdentity.colorOf` (`lib/ui/widgets/class_identity.dart:17`) ; `audioDirectorProvider`, `GameMoment.cardPlay`, `GameMoment.insufficientMana`.
- Produces (privé à l'écran) : `SignatureInstance? _armedSignature` ; `void _armSignature(SignatureInstance)` ; `void _disarmSignature()` ; `void _playSignature(SignatureInstance signature, {String? enemyId})` ; `void _refreshManaWarnings(int previousMana)`.

- [ ] **Step 1: L'avertissement de mana, extrait**

`_refreshManaWarnings(int previousMana)` reprend `onPlayCard` `:355-374` tel quel (masquer l'avertissement « mana restant » ; masquer « plus de mana » si du mana reste, sinon l'afficher après 600 ms si le mana vient de tomber à 0). `onPlayCard` l'appelle à la place de ces lignes ; son comportement ne change pas.

- [ ] **Step 2: Armer, désarmer, jouer**

- `_armSignature(s)` : `_armedSignature = s` (dans un `setState`), `_game.setFocusedCard(null)`, puis `_game.awaitingEnemyTarget = true` — dans cet ordre : défocaliser n'annule rien (Task 3), et l'attente commence sans carte focalisée.
- `_disarmSignature()` : `_armedSignature = null` (dans un `setState`), `_game.awaitingEnemyTarget = false`.
- `_playSignature(s, {enemyId})` (spec §5.4) : `previousMana` relevé ; `combatController.playSignature(s, enemyId: enemyId)` ; s'il rend `false`, rien d'autre — la règle du refus vit dans le moteur, l'écran ne la double pas. S'il rend `true` : l'animation du héros comme `onPlayCard` `:340-345` (`dashAnimation` pour une attaque, sinon `buffAnimation('defend')` si un effet `armor`, `buffAnimation('buff')` sinon) ; `ref.read(audioDirectorProvider).onMoment(GameMoment.cardPlay, source: s.data)` — une carte reçoit ce son de son animation Flame (`card_animator.dart:154`), qu'une signature n'a pas ; puis `_refreshManaWarnings(previousMana)`.
- `onSelectEnemy` (`:392-394`) devient : si `_armedSignature` et `enemyId` ne sont pas nuls, désarmer côté écran (`_armedSignature = null`, Flame a déjà cessé d'attendre) puis `_playSignature(armée, enemyId: enemyId)`. L'appel actuel à `selectEnemy` part : aucun code Flame n'appelait ce rappel, et `playSignature` pose lui-même la sélection (§4.3, étape 3). **L'écran ne passe jamais `combatState.selectedEnemyId`.**
- `onEnemyTargetCancelled: () => setState(() => _armedSignature = null)` au constructeur du jeu.
- `onEndTurnTap` (`:541-557`) : `_disarmSignature()` juste avant `ref.read(runProvider.notifier).endTurn()` — le chemin qui avertit d'un mana restant (`:543-548`) ne désarme pas.

- [ ] **Step 3: Poser la barre et l'infobulle**

Dans la pile de la `SafeArea`, juste après `TurnControlPanel` et avant `CombatTooltipOverlay` (qui reste au-dessus) : si `!runState.isDead && !_showDraft && runState.signatures.isNotEmpty`, une `SignatureBar` avec :
- `signatures: runState.signatures` ; `combatState` ; `currentMana: runState.heroStats.currentMana` ; `armedId: _armedSignature?.data.id` ;
- `interactive` : la condition de `canEndTurn` (`:537-540` — tour joueur côté état et côté Flame, aucune animation de carte) **et** `!combatState.isCombatEnded` ; le héros mort n'a pas de barre. `canEndTurn` ne change pas ; extraire la condition commune dans une locale de `build` ;
- `classColor` : `ClassIdentity.colorOf` du héros de `gameData.heroes` dont l'id est `runState.heroClassId` (`firstWhere`, sans repli : une run n'existe pas sans sa classe) ;
- `onPlay` : `_disarmSignature()` si une signature est armée (un seul geste à la fois, §5.3), puis `_playSignature(s)` ; `onArm` : `_armSignature(s)` (remplace une éventuelle signature armée) ; `onDisarm` : `_disarmSignature()` ; `onInsufficientMana` : `ref.read(audioDirectorProvider).onMoment(GameMoment.insufficientMana)` ;
- `onShowTooltip(s)` : dans un `setState`, `_tooltipTitle = s.data.getName(locale)`, `_tooltipDescription = '${s.data.getDescription(locale)}\n${l10n.signatureCostAndCooldown(s.cost, s.cooldown)}'`, `_tooltipCardType = s.data.type` (la bordure suit `_getTooltipBorderColor`, `:53-65`), `_showTooltip = true` ; `onHideTooltip` : `_showTooltip = false`.

- [ ] **Step 4: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1685** (inchangé) ; `git grep -n "selectedEnemyId" -- lib/ui/screens/game_screen.dart` → vide ; `git grep -nEi "signature" -- lib/game/heros_draft_game.dart lib/game/components lib/game/systems` → vide.

**Test manuel** (pour le compte rendu de la vague, §3.8 de l'orchestration — l'implémenteur ne l'exécute pas) : sur `flutter run -d windows` puis en largeur < 600 :
1. La barre est à gauche, à mi-hauteur, sans chevaucher le panneau des statuts (`bottom: 80`) ni le tiroir de debug ; tuiles de 76 px, 64 px en mobile ; ordre de `skills` (paladin : Bouclier Sacré puis Châtiment).
2. Tour 1 : les deux tuiles sont disponibles. Bouclier Sacré se joue d'un toucher : armure et soin, mana −1, animation « defend », son de carte ; la tuile affiche « 2 tours », puis « 1 tour » au tour 2, prête au tour 3 ; prête de nouveau au combat suivant.
3. Châtiment : toucher la tuile → bordure pulsante et « Choisissez une cible » ; l'ennemi survolé s'illumine (bureau) ; toucher un ennemi → 6 dégâts **à cet ennemi**, même si une carte en avait sélectionné un autre auparavant ; mana −1, animation d'attaque, son de carte.
4. Armée, chacun de ces gestes désarme et efface l'invite : retoucher la tuile, focaliser ou glisser une carte, toucher le décor, finir le tour. Châtiment armé, toucher Bouclier Sacré le joue et efface l'invite.
5. Une carte focalisée puis un ennemi touché joue la carte, jamais la signature.
6. Pendant une animation de carte et pendant le tour ennemi, les tuiles sont atténuées et ne répondent pas ; le compte de recharge reste lisible.
7. Mana insuffisant : médaillon rouge ; toucher → son « mana insuffisant » et secousse, rien n'est joué.
8. Survol (bureau) ou appui long (mobile) : l'infobulle montre le nom, la description et « Coût : 1 Mana · Recharge : 2 tours », bordée de la couleur du type ; quitter la tuile, ou relâcher l'appui, masque l'infobulle.
9. Mana tombé à 0 par une signature : l'avertissement « plus de mana » apparaît comme après une carte.
10. Un ennemi tué par une signature disparaît aussitôt (aucune animation de carte en cours).

- [ ] **Step 5: Commit**

`git add lib/ui/screens/game_screen.dart` puis `git commit` — `feat(signatures): l ecran de combat pose la barre, arme et joue`.

---

### Task 5: Les écrans hors combat — la carte de classe et l'onglet du dictionnaire

**Files:**
- Modify: `lib/ui/screens/class_selection_screen.dart` (`_InteractiveClassCardState.build` : `gameData` `:376`, bloc de la Puissance `:616-663`, `Divider` `:664-667`, description `:677`), `lib/ui/screens/card_dictionary_screen.dart` (`:36-64`), `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb`, puis les trois `lib/l10n/app_localizations*.dart` régénérés
- Test: `test/widget/class_selection_screen_test.dart`, `test/widget/card_dictionary_screen_test.dart` ; `test/widget/card_dictionary_order_test.dart` rejoué sans retouche

**Interfaces:**
- Consumes: `SignatureTile` (Task 1) ; `HeroSkillsLink.getSignatures(GameDataRegistry) → List<SignatureData>` (partie 1, fail-fast) ; `ClassIdentity.colorOf` ; `HeroData.displayOrder`, `getName`.
- Produces: clé ARB `signatures` (`String get signatures`).

- [ ] **Step 1: Écrire les tests qui échouent**

`test/widget/class_selection_screen_test.dart` — `_registryOf` (`:342-353`) et `_buildAndReady` (`:355`) gagnent un paramètre nommé `List<SignatureData> signatures = const []`, passé au registre. Un héros neuf de la fixture, `skills: ['smite', 'holy_shield']`, avec deux `SignatureData` (`Smite`, `Holy Shield`, `cost` 1, `cooldown` 2, `heroClass` égal à son id). Deux tests neufs :
- `la carte de classe montre ses signatures entre la Puissance et la description` — avec ce seul héros : `Signatures` `findsOneWidget` ; `Smite` et `Holy Shield` présents ; `Cost: 1 Mana · Cooldown: 2 turns` `findsNWidgets(2)` ; `tester.getTopLeft(find.text('Signatures')).dy` est inférieur à celui du premier `Divider` de la carte et à celui de la description du héros.
- `une classe sans signature n a pas de bloc Signatures` — avec `_heroes` (aucun `skills`) : `Signatures` `findsNothing`.

`test/widget/card_dictionary_screen_test.dart` — `_buildAndReady` (`:102-108`) gagne un paramètre nommé `GameDataRegistry? registry`, lu par `overrideWith((ref) => registry ?? _mockRegistry)` — `_mockRegistry` est un `final` de premier niveau (`:92`), il ne peut pas servir de valeur par défaut (`non_constant_default_value`) ; deux tests neufs :
- `le dictionnaire a trois onglets : Cartes, Reliques, Signatures` — `find.byType(Tab)` en trouve 3 ; leurs textes, dans l'ordre, sont `Cards`, `Relics`, `Signatures`.
- `l onglet Signatures range les signatures par classe, dans l ordre de displayOrder, a la couleur de la classe` — un registre dont `heroes` déclare d'abord `Berserker` (`displayOrder` 2, `themeColor` `0xFFF44336`, `skills: ['rage_t']`) puis `Paladin` (`displayOrder` 1, `themeColor` `0xFF2196F3`, `skills: ['smite_t']`), et les deux `SignatureData` (`Rage T`, `Smite T`) ; `tester.tap(find.byType(Tab).at(2))` puis `pumpAndSettle` → les `dy` vérifient `Paladin` < `Smite T` < `Berserker` < `Rage T` ; le `Text` `Paladin` a pour couleur `Color(0xFF2196F3)`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/class_selection_screen_test.dart test/widget/card_dictionary_screen_test.dart`
Expected: FAIL — ni bloc, ni troisième onglet (et `signatures` n'existe pas dans `AppLocalizations`).

- [ ] **Step 3: Implémenter**

- La clé `signatures`, dans les deux ARB : `Signatures` / `Signatures` (§7.1). Puis `flutter gen-l10n`.
- Carte de classe (§6) : juste après le bloc de la Puissance (`:663`), avant le `Divider`, si `playerClass.getSignatures(gameData)` n'est pas vide : le titre `l10n.signatures` à la couleur de la classe, puis les deux `SignatureTile(detailed: false)`. Une classe sans signature n'a pas de bloc — seules des fixtures de test sont dans ce cas.
- Dictionnaire (§6) : `DefaultTabController(length: 3)` ; un troisième `Tab(text: l10n.signatures)` **après** les reliques, et son `_buildSignaturesTab` dans `TabBarView`. L'onglet : les héros triés par `displayOrder` (comme `class_selection_screen.dart:69-70`), chacun ayant des signatures : son nom (`getName`) à `ClassIdentity.colorOf(hero)`, puis ses signatures dans l'ordre de `skills`, en `SignatureTile(detailed: true)`.

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/widget/class_selection_screen_test.dart test/widget/card_dictionary_screen_test.dart test/widget/card_dictionary_order_test.dart test/widget/home_screen_menu_test.dart test/widget/home_screen_save_test.dart`
Expected: tout passe — `card_dictionary_order_test.dart:149` (`Tab.at(1)`) trouve toujours les reliques, sans retouche.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1689** (1685 + 2 + 2).

- [ ] **Step 6: Commit**

`git add lib/ui/screens/class_selection_screen.dart lib/ui/screens/card_dictionary_screen.dart lib/l10n/app_fr.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_en.dart test/widget/class_selection_screen_test.dart test/widget/card_dictionary_screen_test.dart` puis `git commit` — `feat(signatures): la carte de classe et l onglet du dictionnaire`.

---

### Task 6: Le tutoriel — la prose, le bandeau ; le pool du draft renommé

**Files:**
- Modify: `lib/tutorial/tutorial_data.dart` (étape « Votre deck de départ » `:32-46` ; étape de la Fusion, phrase `:281` en anglais, `:297-298` en français), `lib/tutorial/widgets/tutorial_starter_deck_widget.dart` (doc `:11`, bandeau `:105-109`), `lib/ui/screens/starter_deck_draft_screen.dart` (`:55`, `:64`)
- Test: `test/widget/tutorial_starter_draft_test.dart`, `test/tutorial/tutorial_prose_test.dart`

**Interfaces:**
- Consumes: `TutorialFixtures.signature` (partie 1, déjà lu par le widget `:42-45`) ; `SignatureData.getName` ; `kTutorialSteps` (`tutorial_data.dart:3`).
- Produces: rien de neuf.

- [ ] **Step 1: Écrire les tests qui échouent**

`test/widget/tutorial_starter_draft_test.dart` (moteur au paladin, locale `fr`, `:17`, `:28`), un neuf — `le bandeau nomme les signatures de la classe, toujours disponibles en combat` : `Vos signatures, toujours disponibles en combat : Bouclier Sacré, Châtiment` `findsOneWidget` (l'ordre de `skills` du paladin : `holy_shield`, `smite`) ; `find.textContaining("Ajoutées d'office")` `findsNothing`.

`test/tutorial/tutorial_prose_test.dart`, deux neufs :
- `l etape du deck de depart enseigne les signatures, mot pour mot` — l'étape de `kTutorialSteps` dont `titleFr` vaut `Votre deck de départ` : `bodyFr` et `bodyEn` égalent les textes de §7.2 (Step 3).
- `la Fusion ne dit plus que les cartes de classe ne fusionnent pas` — l'étape de type `TutorialStepType.merge` : `bodyFr` ne contient pas `Vos cartes de classe sont uniques`, `bodyEn` ne contient pas `Your class cards are unique` ; `bodyFr` contient encore `Le Puits d'échange est un système distinct et payant`, `bodyEn` `The Exchange Well is a separate, paid system`.

- [ ] **Step 2: Lancer les tests, constater l'échec**

Run: `flutter test test/widget/tutorial_starter_draft_test.dart test/tutorial/tutorial_prose_test.dart`
Expected: FAIL sur les trois tests neufs.

- [ ] **Step 3: Implémenter**

- Étape « Votre deck de départ », corps **mot pour mot** de §7.2 (le `\n\n` est un saut de paragraphe ; `**…**` le gras du tutoriel) :
  - `bodyFr` : « Choisissez 5 cartes dans le pool commun : elles forment votre deck de départ, celui avec lequel vous jouerez le reste du tutoriel.\n\nVotre classe apporte en plus ses deux **signatures**, qui ne sont pas des cartes : jamais piochées, elles ne fusionnent pas. En combat, elles vous attendent dans une barre à gauche de l'écran, dès le premier tour ; jouer une signature coûte du Mana, puis elle se recharge quelques tours avant de revenir. »
  - `bodyEn` : « Pick 5 cards from the common pool: they form your starting deck, the one you will play the rest of the tutorial with.\n\nYour class also brings its two **signatures**, which are not cards: never drawn, they never merge. In combat they wait in a bar on the left of the screen, from the first turn; playing a signature costs Mana, then it recharges for a few turns before it comes back. »
  - Les titres ne changent pas.
- Étape de la Fusion : retirer la phrase « Your class cards are unique, and unique cards never merge. » et « Vos cartes de classe sont uniques, et une carte unique ne fusionne jamais. » ; la phrase précédente et la suivante (« **The Exchange Well…** », « **Le Puits d'échange…** ») se rejoignent d'une espace. Rien d'autre du tutoriel n'est réécrit (Q-P2).
- Bandeau (§7.2), en texte en ligne comme le reste du widget : « Vos signatures, toujours disponibles en combat : X, Y » / « Your signatures, always available in combat: X, Y », les noms par `getName(locale)` joints par `", "`.
- Doc `:11` du widget : « Le pool est celui de `StarterDeckDraftScreen` : toute carte offerte (`CardData.isOfferable`). »
- `starter_deck_draft_screen.dart` : la locale `globalCards` devient `offerableCards` (le concept « global » n'existe plus) ; `draftDeckSubtitle` et tous les textes de l'écran **ne changent pas** (spec §6).

- [ ] **Step 4: Lancer les tests, constater le succès**

Run: `flutter test test/widget/tutorial_starter_draft_test.dart test/tutorial/ test/widget/starter_deck_draft_screen_test.dart test/widget/starter_deck_draft_order_test.dart`
Expected: tout passe.

- [ ] **Step 5: Vérifier la tâche**

Run: `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1692** (1689 + 1 + 2) ; `git grep -nE "Ajoutées|Added automatically|class cards are unique|classe sont uniques|globalCards|cartes globales non-statut" -- lib` → vide (côté `test/`, ces littéraux sont ceux des assertions d'absence du Step 1, qui gardent l'absence) ; `git diff HEAD -- lib/l10n/app_fr.arb lib/l10n/app_en.arb` → vide (le sous-titre du draft n'a pas bougé).

- [ ] **Step 6: Commit**

`git add lib/tutorial/tutorial_data.dart lib/tutorial/widgets/tutorial_starter_deck_widget.dart lib/ui/screens/starter_deck_draft_screen.dart test/widget/tutorial_starter_draft_test.dart test/tutorial/tutorial_prose_test.dart` puis `git commit` — `feat(tutoriel): la prose et le bandeau des signatures`.

---

### Task 7: La vérification finale

Aucun fichier ne change, sauf correction d'un écart trouvé ici (qui suit alors la règle d'arrêt de §6 de l'orchestration).

- [ ] **Step 1: L'analyse et la suite**

Run: `rm -rf build/unit_test_assets` puis `dart analyze` → `No issues found!` ; `flutter test` → `All tests passed!`, **total 1692**.

- [ ] **Step 2: Les contrôles de la spec §12, rejoués**

- `` git grep -nE "CardRarity\.unique|rarityUnique|isUnique|isAcquirable|characterSpecific|CardCategory|isOfferableTo|'unique'|\"unique\"|\`unique\`" -- lib test assets tool ':!tool/simulations' | grep -v "contains('single')" `` → vide.
- `git diff main -- assets/data/passives/mage_mark.json` → vide.
- `dart run tool/sync_assets.dart --check` → code de sortie 0.
- Aucune signature dans le `masterDeck` ni dans un pool : `flutter test test/unit/referential_integrity_test.dart test/widget/starter_deck_draft_screen_test.dart test/widget/tutorial_starter_draft_test.dart` → vert.

- [ ] **Step 3: Les contrôles propres à cette partie**

- Les couches (§5.3) : `git grep -nEi "signature" -- lib/game/heros_draft_game.dart lib/game/components lib/game/systems` → vide ; `git grep -nE "package:flame|game/components|heros_draft_game|ref\.(read|watch)" -- lib/ui/widgets/hud/signature_bar.dart lib/ui/widgets/signature_tile.dart` → vide.
- L'écran ne passe jamais la sélection restante : `git grep -n "selectedEnemyId" -- lib/ui/screens/game_screen.dart` → vide.
- Les quatre clés de §7.1, et elles seules, sont neuves dans les ARB : `git diff 1315aab -- lib/l10n/app_fr.arb lib/l10n/app_en.arb | grep -oE '^\+  "[a-zA-Z]+"' | sort -u` → `signatureChooseTarget`, `signatureCostAndCooldown`, `signatureTurnsLeft`, `signatures` — plus, au plus, la clé qui précédait un ajout en fin de fichier, si elle n'a gagné que sa virgule.
- Les fichiers générés suivent les ARB : `flutter gen-l10n` puis `git status --short lib/l10n` → vide.
- Le moteur n'a pas bougé : `git diff 1315aab -- lib/game/controllers lib/models assets` → seul `lib/models/data/signature_data.dart` répond (`getDescription`).
- Aucun membre neuf sans lecteur dans `lib/` (Global Constraints) : `git grep -nE "SignatureTile\(|getDescription\(|signatureCostAndCooldown\(|SignatureBar\(|awaitingEnemyTarget|onEnemyTargetCancelled" -- lib/ui/screens` → répond **au moins** : `SignatureTile(` dans `class_selection_screen.dart` et `card_dictionary_screen.dart` ; `getDescription(`, `signatureCostAndCooldown(`, `SignatureBar(`, `awaitingEnemyTarget` et `onEnemyTargetCancelled` dans `game_screen.dart` (`getDescription(` répond aussi, déjà aujourd'hui, en six lignes : reliques, classe, événement, rune du Puits). Puis `git grep -n "signatureTurnsLeft(" -- lib/ui/widgets/hud/signature_bar.dart | grep -v "combatState\."` → au moins une ligne (la clé ARB, et non `CombatState.signatureTurnsLeft`, `combat_state.dart:70`, que la barre appelle aussi) ; `git grep -n "signatureChooseTarget" -- lib/ui/widgets/hud/signature_bar.dart` → au moins une ligne.

- [ ] **Step 4: L'état de la branche**

Run: `git status` → arbre propre (hors fichiers régénérés par `flutter`, à restaurer par `git restore`) ; `git log --oneline 1315aab..HEAD` → les six commits de ce plan, après celui du plan lui-même s'il a été commité entre-temps. Rien n'est poussé.

---

## Questions signalées

### Classe P — non tranchée, recommandation appliquée en attendant

| # | Question | Options | Recommandation | Ce qui change si la réponse diffère |
|:---|:---|:---|:---|:---|
| **P-2** | Le contenu de la tuile « détaillée » du dictionnaire (§6) face à la « compacte » de la carte de classe (« nom, coût, recharge, description »). La spec ne dit pas ce que « détaillée » ajoute. | (a) le même contenu, en typographie pleine ; (b) en plus, le libellé du type (`Attaque` / `Compétence`, clés ARB existantes) ; (c) en plus, le type et la cible | **(b)** : le type est ce qu'une signature a de plus qu'une compétence quelconque — il dit quels passifs et reliques elle déclenche (§1.2) —, sans texte neuf | Task 1 : une ligne de `SignatureTile` et le test « la tuile detaillee montre aussi le type » |

Aucune question de classe D.

### Classe T — tranchées par l'arbre de l'orchestration, §5

| Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---|
| **PM19** — la forme du compte sur une tuile en recharge : §5.2 dit « le nombre de tours en grand au centre et « tour(s) » dessous », §7.1 fixe une seule clé, `signatureTurnsLeft`, qui rend « 2 tours » d'un bloc, et §10 asserte « 2 tours ». Signalée P à l'écriture, reclassée T par l'orchestrateur : la forme de la barre est déléguée (A6) | (a) le nombre seul en grand et le mot par une cinquième clé neuve (un texte joueur que la spec n'a pas ; `signatureTurnsLeft` perdrait son lecteur) · (c) la chaîne traduite coupée après le nombre (du code qui analyse un texte traduit) | (b) `signatureTurnsLeft(n)` centré, en grand, d'un bloc : tous les textes de la spec, mot pour mot | Délégation A6 |
| Où vit la priorité des cinq états | Dans les tuiles privées (la priorité ne se teste qu'à travers le rendu) · un provider Riverpod (l'état Flame `isCardAnimating` n'entre pas dans Riverpod) | Une fonction pure `signatureTileStateOf`, ses entrées calculées par l'écran | 5 |
| Comment la barre rend ses gestes | Un seul `onTap`, l'écran décidant selon la cible : la règle « `singleEnemy` arme, sinon joue » (§5.2, colonne « Toucher ») quitterait le widget testé pour l'écran sans banc | `onPlay`, `onArm`, `onDisarm`, `onInsufficientMana`, et la paire de l'infobulle | 5 |
| Qui joue le son « mana insuffisant » | La barre en `ConsumerWidget` lisant `audioDirectorProvider` | La barre appelle `onInsufficientMana`, l'écran joue le son : un widget du HUD reçoit tout ce qu'il montre, comme `TurnControlPanel` | 5 |
| Où vit l'état de la secousse | Une barre à état (la spec la veut sans état, arbitrage acquis) | Un widget de tuile privé à état, animation purement visuelle | 1 |
| La forme d'`awaitingEnemyTarget` | Un champ nu (l'ennemi reste illuminé quand l'écran désarme) · un setter qui rappelle `onEnemyTargetCancelled` (l'écran se rappelle lui-même) | Accesseur et mutateur : `false` éteint l'illumination, sans rappel ; le rappel ne sert qu'aux annulations venues de Flame | 6, puis 8 |
| Où Flame détecte l'annulation | Dans `CardInteractionHandler.onTapDown` et `onDragStart` (deux sites dans un composant) | `HerosDraftGame.setFocusedCard` (carte non nulle) et `onTapDown` du jeu (le décor) : le glisser commence par la focalisation | 8 |
| Un ennemi mort ou mourant touché pendant l'attente | Le contrôler dans `playSignature` (écarté par l'orchestrateur, comme le chemin d'une carte) · le contrôler dans l'écran contre `combatState.enemies` (l'écran revérifierait ce que Flame garantit) | Flame ignore `isDead` / `isPendingDeath` et garde l'attente | 5 |
| L'illumination au survol | `HoverCallbacks` sur `EnemyCard` (un composant de plus touché, en concurrence avec l'illumination du glisser) | `HerosDraftGame.onPointerMove`, `containsPoint` sur `enemyCards` | 8 |
| Le corps d'`onSelectEnemy` dans l'écran | Garder `selectEnemy` quand rien n'est armé — un chemin que Flame n'appelle jamais | Il ne joue que la signature armée | 5 |
| L'ordre dans `_playSignature` | Le contrôle `canPlayCard` dans l'écran avant l'animation, comme `onPlayCard` (la règle du refus en deux endroits) | `playSignature` d'abord ; animation et son seulement s'il rend `true` | 5 |
| `interactive` de la barre | Modifier `canEndTurn` pour y ajouter le combat fini (change le bouton de fin de tour) | La condition de `canEndTurn` partagée, plus `!isCombatEnded` pour la barre seule | 7 |
| Une autre tuile touchée pendant qu'une signature est armée | La laisser armée (deux gestes en cours, contre §5.3) | `onPlay` désarme d'abord ; `onArm` remplace | 1 (§5.3 : « un seul geste à la fois ») |
| Une classe sans signature, sur sa carte et dans l'onglet | Un titre sans contenu | Pas de bloc, pas d'en-tête — seules des fixtures de test sont dans ce cas | 8 |
| Le bandeau du tutoriel en ARB | Une cinquième clé (la spec en fixe quatre ; le widget écrit ses textes en ligne) | En ligne, comme le reste du widget | 5 |
| Quand ajouter chaque clé ARB | Les quatre d'un coup, en Task 1 (trois sans lecteur jusqu'aux tâches suivantes) | Chacune avec son premier lecteur : Tasks 1, 2, 5 | 5 |
| La couleur de classe dans l'écran de combat | Un repli `fallbackColor` si la classe manque (une run sans classe n'existe pas) | `firstWhere` sur `gameData.heroes` par `heroClassId` | 5 |
| Tester le ciblage Flame ou le laisser au manuel (spec §10) | Le manuel seul | Un test unitaire du jeu non monté (`StateSyncSystem` injecté, composants non montés) ; seule la glue de `GameScreen` reste au manuel | 8 (le test se défait seul ; la spec ne l'interdit pas) |
| Le nom de la locale du draft | `globalCards` (« global » n'existe plus) | `offerableCards` | 5 |

## Prémisses de la spec re-mesurées

- **§5.4** — « `_playSignature` reprend ce que fait `onPlayCard` … le son `GameMoment.cardPlay` » : `onPlayCard` (`game_screen.dart:327-377`) n'émet aucun son ; celui d'une carte part de son animation Flame (`card_animator.dart:154`). Une signature n'ayant pas d'animation de carte, l'écran l'émet lui-même (Task 4). Sans effet sur le périmètre.
- **§5.2** — l'état « inactive » cite « la condition de `canEndTurn` (`game_screen.dart:537-540`) » pour « héros mort, combat fini » : `canEndTurn` ne lit ni l'un ni l'autre. Le héros mort n'a pas de barre (elle est posée sous `!runState.isDead`) ; `!combatState.isCombatEnded` s'ajoute pour la barre seule (Task 4).
- **§5.2 / §7.1** — le compte « en grand, « tour(s) » dessous » contre une clé qui rend « 2 tours » d'un bloc : PM19, tranchée T.
- **§6** — la description de la carte de classe est à `:677` (spec : `:676`) ; le bloc de la Puissance reste `:616-663`.
- **§7.2** — l'étape « Votre deck de départ » couvre `tutorial_data.dart:32-46` (spec : `:35-44`, les seuls corps) ; la phrase de la Fusion est à `:281` et `:297-298`, comme la spec le dit.
- Confirmées : `onSelectEnemy` n'a aucun appelant Flame (`heros_draft_game.dart:77`, branché `game_screen.dart:392-394`) ; `turn_control_panel.dart:101-104` (`right: 20`) ; `combat_side_panels.dart:71-75` (`bottom: 80`) ; `card_interaction_handler.dart:134-139` ; `card_dictionary_screen.dart:36-64` ; `HerosDraftGame` se construit en test (`flame_image_prefix_test.dart:11`).
