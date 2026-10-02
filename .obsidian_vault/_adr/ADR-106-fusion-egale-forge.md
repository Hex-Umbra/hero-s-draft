---
description: The merge becomes the forge — every 3→1 merge keeps all its runes and offers one of three, the campfire sharpens a rune for gold, the Exchange Well replaces the Fusion Forge every third act, the shop sells a copy from the deck and holds its whole stall per node; forge capacity, pools and stackable disappear; amends ADR-074, ADR-094, ADR-105 and ADR-067, makes what remained of ADR-025, ADR-039 D1 and D3 and ADR-024 point 4 obsolete
---

# ADR-106 — Fusion = Forge : la Fusion Donne la Rune, le Feu Affûte, le Puits Échange, la Boutique Copie

### Statut

✅ Accepté — 2026-10-02 (P-43, lot **E2** ; brainstorm v3, décisions D3, D4 — le niveau monté contre
de l'or —, D5, D6, D13, D14, D20, D22, D28, D32, D33 — `spectral` —, D39, D44 et D51 — la donnée de
`cheap` —, D46, D48, D63, D65 et D68). **Livré sur la branche `feat/v0.5.4-p43-e2-fusion-forge` —
vague 2 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Spec `90dd137`, convergée au
quatrième tour de vérification après un arrêt levé par le propriétaire ; plans `7a071b6` (partie 1)
et `017aa4c` (partie 2) ; code `3eafb5e`..`d6e6cd5` et le correctif de revue `1407e2e` (partie 1),
`bcc5b36`..`bff3078` et le correctif `0010ca2` (partie 2) ; référence de simulation recommitée
`cba147c`.
**Amende** [ADR-074](ADR-074-introduction-de-la-forge-de-fusion-procedurale-et.md),
[ADR-094](ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md) (D1 à D5),
[ADR-105](ADR-105-moteur-de-runes-data-driven.md) (D1, D3, D7, D8, D10) et
[ADR-067](ADR-067-equilibrage-de-l-economie-scaling-par-acte-des-car.md) (point 5). **Rend
caduques** les décisions qui restaient à
[ADR-025](ADR-025-systeme-de-forge-decouple-et-probabiliste.md), les D1 et D3 d'
[ADR-039](ADR-039-systeme-de-forge-v2-anti-exploit-filtrage-type-ach.md) et le point 4 d'
[ADR-024](ADR-024-progression-par-rarete-dynamique-et-fusion-interac.md).
Conception : [spec E2](../../docs/superpowers/specs/2026-10-02-p43-e2-fusion-forge-design.md) — §1.2
porte les vingt arbitrages, leurs options écartées et leurs motifs, que ce fichier ne recopie pas ;
plans [partie 1](../../docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-1.md) et
[partie 2](../../docs/superpowers/plans/2026-10-02-p43-e2-fusion-forge-partie-2.md) ; arbitrages et
décisions d'exécution au
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md),
§2.

### Contexte

Jusqu'à E1, une rune s'obtenait au feu de camp : de une à cinq fentes tirées, un ciblage par
`pools` selon la rareté, des relances payantes, des fentes achetées, et une « session » dans
`RunState` qui devait empêcher de retirer l'offre — deux de ses champs n'étaient lus par aucun
code du jeu. La fusion 3 → 1 de cartes tronquait l'héritage à une capacité
`baseMaxForgeUpgrades + fusionRank`, le joueur choisissant ce qu'il gardait ; la Forge de Fusion,
placée à 25 % par carte du monde, cumulait deux exemplaires d'une même rune contre `80 × (N − 1)`
or. Le brainstorm v3 refond la boucle : la fusion devient le moteur de progression et donne la
rune (D3), le feu monte un niveau (D4, D5, D14, D20), le Puits échange (D6, D22, D39), la boutique
vend la copie d'une carte du deck (D46). E1 ([ADR-105](ADR-105-moteur-de-runes-data-driven.md))
avait posé le moteur — deltas, applicateur, prédicat, `maxLevel` — sans toucher à la boucle ; E2 la
change, et supprime `pools`, `stackable` et la capacité avec les deux écrans qui les lisaient (D68).

### Décision

**La fusion donne la rune.**
- **A1 — Le geste.** `DeckNotifier.mergeCards(ids)` crée la carte, héritage compris, et la rend
  (`null` si la fusion est refusée). L'écran de deck tire l'offre par la fonction pure
  `ForgeRuneRules.drawRunes(carte, catalogue, rng, count: 3)` sur la carte rendue — au rang
  qu'elle **atteint** — et ouvre `ForgeUpgradeDialog`, qui ne se ferme que par un choix ; le choix
  écrit `id:1` par `addForgeUpgrade`. Sans rune éligible, la fusion se fait, puis
  `deckMergeSuccess`, puis `forgeNoEligibleRune`. La fusion reste gratuite (D32).
- **A2 — L'offre** : trois runes, moins si moins sont éligibles, jamais aucune tant qu'une existe
  (D65) ; au niveau 1 ; tirées pondérées par `weight`, sans remise ; ni relance, ni fente achetée.
- **A3 — La session de forge disparaît** : `forgeSlots`, `forgeTargetCardId`,
  `forgeTargetSessions`, `bonusForgeSlots`, `setForgeSession`, `clearForgeSession`,
  `buyBonusForgeSlot`, et la ligne « Slots de forge bonus » du menu de debug.
- **A7, A8 — `minFusionRank`**, clé obligatoire, entier ≥ 1, refusée par `ForgeUpgradeData.fromJson`
  sinon, 1 par défaut au constructeur pour les tests ; 2 pour `eco` et `quick` (D48), 1 pour toutes
  les autres.
- **L'héritage (D13)** : `consolidate` garde les runes des trois exemplaires — même id additionné,
  borné par `maxLevel`, une rune exclue par une rune gardée avant elle écartée (ADR-105 D10) — et
  **la troncature disparaît** : aucun plafond de runes par carte.

**Le feu affûte.**
- **A4** — « AFFÛTER » remplace « FORGER » parmi trois options exclusives, inactive avec son motif
  quand aucune rune du deck ne peut monter. Sélection d'une carte — une carte sans rune affûtable
  est grisée et refusée (`sharpenNothingOnCard`) —, puis `SharpenRuneDialog` : une ligne par rune
  portée, son gain marginal, « Affûter — coût or ». L'état de visite reste local à l'écran
  (`_actionTaken`). **Une action faite, le retour système résout le nœud comme « Continuer »**
  (`canPop: false` et `onPopInvokedWithResult` → `_leave`) ; le même mécanisme ferme le second
  repos et le second oubli, possibles jusque-là par cette voie.
- Coût `ForgeRuneRules.sharpenCost(niveau) = 50 × niveau` (D20, D63) ; `canSharpen` lit `maxLevel`
  par `boundLevel` ; une rune, un niveau, une fois par visite (D14).

**Le Puits d'échange remplace la Forge de Fusion.**
- **A5** — `ForgeFusionScreen` réécrit en place : les cartes qui portent une rune, la rune à donner,
  **toutes** ses remplaçantes (`wellOptions` : le prédicat jugé sur la carte **sans** la rune
  donnée, à son rang), chacune avec son niveau d'arrivée et « Échanger — coût or ». Un échange par
  visite, état local ; après un échange, le retour système résout le nœud — avant, il ne le résout
  pas, et le joueur peut revenir.
- **A6** — `wellCost(L) = wellBaseCost × L` avec `wellBaseCost = 50`, constante distincte de
  `sharpenBaseCost` ; `wellLevel = boundLevel((2L + 1) ~/ 3)` : les deux tiers arrondis au plus
  proche, au moins 1, puis le plafond de la rune reçue (D39).
- **Le placement** : `act % 3 == 0` au lieu de 25 % (D22), sur un combat ou un événement des
  étages 3 à 7, après l'Autel.
- **A16** — Les deux opérations payantes vivent dans `GoldManager` (`sharpenRune`, `exchangeRune`),
  exposées par `RunController` : « payer et écrire, ou rien » est de la logique métier ; les
  formules sont des fonctions pures de `ForgeRuneRules`.
- **A17** — `MapNodeType.forgeFusion`, `ForgeFusionScreen` et `ForgeUpgradeDialog` gardent leur
  nom ; seuls les textes que lit le joueur changent.

**La boutique.**
- **A11 — La copie du deck** (D46) : une carte tirée uniformément dans `DeckState.copyableCards`,
  même rareté, sans ses runes, au prix d'une carte de sa rareté (25 · 50 · 100 · 150 · 200) ; la
  relance de l'étal ne la touche pas. **L'étal entier — cartes, copie, soin, Miroir — est tiré une
  fois par nœud de boutique** (`ShopState.nodeId`) et retenu, achats compris, jusqu'à ce que le
  nœud courant de la run change — décision du propriétaire du 02/10/2026, le Miroir et l'identité
  du nœud tranchés par l'orchestrateur. `clearCloneOptions` et le `PopScope` de `ShopScreen`
  disparaissent. Sans nœud courant, chaque appel tire.
- **A12 — Les pré-forgées** portent au plus `fusionRank` runes (D28) — une commune n'en porte
  aucune —, chacune tirée par `drawRunes(count: 1)` sur la carte avec les runes déjà posées, au
  niveau 80 · 15 · 5 % borné. Ce tirage de niveau ne vit plus qu'ici.

**Trois runes neuves, trois sortes de delta.**
- **A9, A10** — `cheap` (`reduceCost 1`, `requiresMinCost: 1`, `excludesRunes: ["eco"]`, plafond 1),
  `precise` (`critBonus 5`, plafond 10), `spectral` (`percentBonus damage 40` et `addExhaust`, sans
  plafond), toutes à `minFusionRank` 1 et au poids 50 (D63) ; `precise` et `spectral` sur les seules
  cartes de dégâts. `spectral` suit D33 — 40 % de la valeur à la rareté par niveau, au moins +1,
  sans la Puissance — et son épuisement l'emporte sur `removeExhaust`.
- **A13** — Les quatre lecteurs du badge « Usage unique » et des particules lisent
  `CardInstance.exhaustsOnPlay`, plus la donnée.
- **A14** — `{val}` dit ce que la rune ajoute à cette carte pour toute sorte chiffrée ; les cinq
  descriptions à effet ajouté passent de `{tier}` à `{val}`, sans changer à l'écran.
- **A15** — Le prédicat calcule le coût courant par l'applicateur sur le `catalog` qu'il reçoit,
  jamais sur le registre global : le tutoriel juge sur le sien.
- **A18** — L'étape de fusion du tutoriel tire l'offre par `drawRunes` sur son propre registre ; le
  joueur choisit, et SUIVANT attend le choix.
- **A19** — `runeIcons` et `runeColors`, deux tables `const` publiques
  (`lib/ui/widgets/forge/rune_style.dart`), lues par la ligne de rune et gardées par un test
  d'intégrité.
- **A20** — Deux parties ; `minFusionRank` et « une rune par type » dès la première, que l'offre
  de fusion demande.

**Ce que ces décisions font aux ADR antérieurs** — chacun ne change que de Statut et lie celui-ci :

| ADR | Amendé, ou rendu caduc, ainsi |
|:---|:---|
| ADR-074 | Le nœud devient le Puits d'échange : tous les trois actes au lieu de 25 %, `50 × niveau donné` au lieu de `80 × (N − 1)`, un échange par visite. **Point 2 caduc** — le cumul de plusieurs exemplaires d'une même rune sur une carte : une rune par type (D3) |
| ADR-094 D1 | `forgeCapacityAt` et `CardInstance.forgeCapacity` supprimés ; `fusionRank` est comparé par `minFusionRank` et borne les pré-forgées |
| ADR-094 D2 | `copyableCards` sert quatre sources de copie, la copie du deck comprise |
| ADR-094 D3 | `stackable` supprimé, avec tous ses lecteurs |
| ADR-094 D4 | `exhaustsOnPlay` lit aussi `addsExhaust` ; sa conséquence ⚠️ — le badge et les particules qui ignoraient *Persistant* — est close (A13) |
| ADR-094 D5 | `ForgeRuneRules` perd `isStackable` et `fusionOptionsFor` |
| ADR-105 D1 | Six sortes de delta : `reduceCost`, `critBonus` et `addExhaust` s'ajoutent |
| ADR-105 D3 | `ForgeRuneRules` gagne `drawRunes`, l'affûtage et le Puits |
| ADR-105 D7 | `boundLevel` borne la fusion, les pré-forgées, l'affûtage (`canSharpen`) et le Puits (`wellLevel`) ; la Forge de Fusion et le tirage du feu disparaissent |
| ADR-105 D8 | Le prédicat gagne le rang (`minFusionRank ≤ fusionRank`) et « une rune par type », dont la condition du plafond devient un cas ; ses lecteurs sont `drawRunes` — l'offre, les pré-forgées, le tutoriel — et `wellOptions` |
| ADR-105 D10 | L'héritage garde toutes les runes, sous la même règle d'exclusion |
| ADR-067 point 5 | Le Miroir ne repart plus — options neuves, 150 or — à chaque sortie de la boutique, mais avec tout l'étal, au nœud courant suivant |
| ADR-025 | **Caduc** pour ce qui en restait : la capacité, les fentes tirées, les pools, la relance, le dialogue au feu. Le tirage de niveau 80 · 15 · 5 ne vit plus qu'en boutique |
| ADR-039 D1, D3 | **Caduques** : la session persistée, les fentes achetées. D4, le gabarit plein écran, reste celui du dialogue de fusion |
| ADR-024 point 4 | **Caduc** : plus de capacité, plus de choix d'héritage |

**Trois points que la revue d'ensemble de la partie 2 demande de consigner.**
1. **`ShopController` est le premier Notifier de `lib/game/controllers/` à écouter un autre
   provider** : `ref.listen` sur `runProvider.select((run) => run.currentNodeId)`, posé dans
   `build`, remet l'état à `const ShopState()` à chaque changement. Jusque-là, le seul `ref.listen`
   du dossier était celui du Provider `autosaveOrchestratorProvider`. **`ref.watch` y lève
   l'assertion de Riverpod « Cannot use ref functions after the dependency of a provider
   changed »** : le Notifier, périmé entre le changement de nœud et la lecture suivante de
   `state`, refuse alors tout `ref.read` de ses méthodes — mesuré au plan : sept tests rouges.
2. **L'étal retenu est un instantané** : la copie et les options du Miroir ne suivent pas un deck
   qui change dans le même nœud.
3. **Un chargement de sauvegarde vide l'état en mémoire de la boutique** — `hydrate` change
   `currentNodeId`. Cela ne se voit pas en jeu : une sauvegarde prise sur un nœud de boutique l'a
   résolu, et la carte n'y laisse plus entrer (spec §7, corrigée à la revue).

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Les trois sortes neuves | `lib/models/data/card_delta.dart` — `reduceCost`, `critBonus`, `addExhaust`, `typeNames` à six ; `lib/models/effective_card.dart` — `cost`, `critChanceBonus`, `addsExhaust` |
| Coût, épuisement, critique | `lib/models/card_instance.dart` — `currentCost`, `exhaustsOnPlay` ; `lib/game/services/damage_pipeline.dart` — `critChanceBonus` ; `lib/game/services/effects/strategies.dart` |
| Prédicat, tirage, affûtage, Puits | `lib/game/services/forge_rune_rules.dart` — `isEligible`, `drawRunes`, `sharpenCost`, `canSharpen`, `hasSharpenableRune`, `replaceRune`, `wellCost`, `wellLevel`, `wellOptions` |
| Le modèle de rune | `lib/models/data/forge_upgrade_data.dart` — `minFusionRank`, `{val}` |
| Les opérations payantes | `lib/game/controllers/run/gold_manager.dart` ; `lib/game/controllers/run_controller.dart` — `sharpenRune`, `exchangeRune` |
| La fusion | `lib/game/controllers/deck_controller.dart` — `mergeCards` ; `lib/ui/screens/deck_screen.dart` ; `lib/ui/widgets/forge_upgrade_dialog.dart` |
| Le feu | `lib/ui/screens/rest_screen.dart`, `lib/ui/screens/rest_card_selection_screen.dart`, `lib/ui/widgets/forge/sharpen_rune_dialog.dart` |
| Le Puits | `lib/ui/screens/forge_fusion_screen.dart` ; `lib/services/map/map_content_placer.dart` ; `lib/ui/widgets/map/map_node_widget.dart`, `map_legend.dart` |
| La boutique | `lib/game/controllers/shop_controller.dart` — `build` (`ref.listen`), `initializeShop`, `buyDeckCopy`, `_rollRandomUpgrade` ; `lib/models/shop_state.dart` — `deckCopy`, `nodeId` ; `lib/ui/screens/shop_screen.dart` |
| Les rendus | `card_text_renderer.dart` (`centerBlockTop`), `card_component.dart`, `card_animator.dart`, `ui_card.dart`, `ui_card/card_rune_sockets.dart`, `forge/forge_slot_row.dart`, `forge/rune_style.dart` |
| Le tutoriel | `lib/tutorial/tutorial_engine.dart` — `_seedMergeHand`, `mergeCards`, `chooseMergeRune` ; `lib/tutorial/widgets/tutorial_merge_widget.dart` |
| L'éditeur | `lib/services/content_editor/entity_descriptor.dart` — `requiredKeys` vide, gabarits de rune et de carte |
| La donnée | onze fichiers sous `assets/data/forge_upgrades/`, dont `cheap.json`, `precise.json`, `spectral.json` ; six signatures sans `baseMaxForgeUpgrades` |
| Supprimés | `ForgeBuySlotButton` et son fichier, `forge_buy_slot_button.dart` ; `FusionOption`, `fusionOptionsFor`, `isStackable`, `forgeCapacityAt`, `CardInstance.forgeCapacity`, `UiCard.forgeCapacity`, `CardRuneSockets.totalSlots` |
| Tests neufs | `test/widget/sharpen_rune_dialog_test.dart`, `test/widget/tutorial_merge_widget_test.dart`, `test/unit/damage_pipeline_test.dart`, `test/unit/map_content_placer_test.dart`, `test/unit/card_text_renderer_layout_test.dart` ; cas ajoutés à `shop_controller_test` (l'étal retenu, puis oublié au changement de nœud), `run_controller_test`, `forge_rune_rules_test`, `forge_upgrades_catalog_test`, `deck_screen_test`, `rest_screen_test`, `forge_fusion_screen_test`, `referential_integrity_test` (`runeIcons`, `runeColors`) |
| Commandes de contrôle | spec §4.11 et A13 : `git grep` de `pools`, `stackable`, la capacité, la session de forge et `data.isExhaust` dans `lib/game/components lib/ui` — ne rendent que trois homonymes sans rapport aux runes, ou rien (**vérifié le 2026-10-02**) |

### Conséquences

- ✅ **Une rune s'obtient par la fusion, se monte au feu, s'échange au Puits** ; la boutique vend
  des pré-forgées bornées et la copie d'une carte du deck. Une commune ne porte jamais de rune, et
  aucune carte de rang 1 ne porte *Économe* ni *Véloce* dans une partie neuve.
- ✅ **Plus de prises vides** : une prise par rune portée, en Flutter comme en Flame ; jusqu'à neuf
  runes sur un *Cri de Guerre* épique, le bloc central descendu sous les prises (`centerBlockTop`).
- ✅ **Deux défauts antérieurs fermés au passage** : le second repos ou le second oubli par le
  retour système, et le retirage gratuit de tout l'étal de la boutique par une sortie suivie d'un
  retour — dits dans la note de version.
- ✅ **La simulation suit le jeu** : le réalignement seul rend un diff vide (`9f1f203`) ; le
  `spectral` du script aligné sur D33 change 477 lignes sur 798, écart expliqué au compte rendu
  §4, référence recommitée.
- ⚠️ **Les fusions restent rares jusqu'à la vague 3** : la forge du feu a disparu et la trouvaille
  n'existe pas encore ; les doublons ne viennent que des récompenses de boss, de la boutique et
  des Miroirs. Voulu (brainstorm §11), et dit dans la note.
- ⚠️ **Les cartes de classe ne reçoivent plus de rune** (D7) : le feu était leur seule source.
- ⚠️ **Deux cas latents pour la vague 5** : `spectral` sur une carte qui s'épuise déjà, et la paire
  `spectral` / `enduring`, tenue par la seule préséance de l'épuisement (A9, A10).
- ⚠️ ***Précis* au niveau 10 ajoute 50 points de critique** : sur le Berserker, avec des récompenses
  de critique, une carte peut devenir critique à coup sûr — la donnée du brainstorm, à regarder au
  test du propriétaire.
- ⚠️ **Le coût courant passe par l'applicateur, que le rendu Flame relit à chaque image** pour
  chaque carte en main : des allocations, sans blocage de la boucle ; une mémorisation si le
  combat ralentit (compte rendu, S9).
- ⚠️ **Une sauvegarde d'avant E2 peut porter deux références d'une même rune** : l'affûtage les
  monte ensemble. Laissé : les sauvegardes sont jetables avant la `1.0.0`.
- ⚠️ **`ShopState.toJson` / `fromJson`, sans lecteur, n'apprennent ni `deckCopy` ni `nodeId`** :
  l'étal ne se sauvegarde pas (point 3 ci-dessus).
