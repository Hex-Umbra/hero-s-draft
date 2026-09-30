# Orchestration — P-43 « Économie unifiée », P-42 « Catalogue par lots » et P-44 « Profondeur » : cohérence des lots et prompts de session

**Date** : 01/10/2026
**Objet** : vérifier que la chaîne des lots que le brainstorm v3 découpe (§11, D64 à D68) est cohérente de bout en bout — chaque décision a un lot, chaque lot se livre seul, chaque frontière a un état transitoire connu — puis donner, pour chaque session neuve, le prompt à coller.
**Sources** : [`22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md`](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md) §1, §10, §11 ; [`29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md`](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md) §2.1, §13 ; [`30-09-2026_simulation_D26_economie_Fable5.md`](30-09-2026_simulation_D26_economie_Fable5.md) §7 ; `docs/ROADMAP.md` §4 et §5 ; les prompts qui ont lancé les sessions de P-41, de P-49, du filtre de classe (T1) et de la spec de P-42 (T3, 21/09) — le format des prompts de §5 est le leur.
**Vérifié contre** : `main` à `3b8c66f`, 1187 tests ; les références de code de §2.3 lues le 01/10.
**Statut** : Orchestration. **Rien n'est tranché ici** — les décisions sont celles du brainstorm §1. §3 liste ce que le propriétaire doit encore trancher, et à quel moment ; §5 donne les prompts, à copier tels quels dans une session neuve, une fois la session 0 passée.

---

## 0. En six lignes

1. **La chaîne tient.** Cinq lots de P-43 (E0 → E4), puis la tranche 1 de P-42 livrée avec le lot 1 de P-44, puis les tranches 2 et 3, puis les lots 2 à 4 de P-44 derrière P-05, puis P-16. L'ordre est forcé par des dépendances de code, pas par commodité (§1).
2. **Les 68 décisions ont un lot**, à deux exceptions près que le brainstorm n'assigne pas : le changement de déclencheur de *Marque du Mage* (D34) et le quatrième lot de P-44 — les effets interactifs (§9.2 #9, « lot propre ») — absent du graphe (§3, O1 et O2).
3. **Deux préalables avant la première spec** : redécouper la ROADMAP par `memory-bank-sync`, et décider du numéro de version que le chantier vise. C'est la session 0 (§5.1). Le dossier lui-même — brainstorm, revue, simulation, ce document — est commité par lot et poussé sur `main` depuis le 01/10.
4. **Quatre lots sont lourds** — E2, E3, E4 et la tranche 1 avec P-44 lot 1 — et leur spec doit proposer un découpage en parties, comme P-41 l'a fait, avec l'invariant qui justifie l'ordre (§1, colonne « Poids »).
5. **La chaîne de sessions par lot** est celle de P-41 : spec, plan, passe de correction, implémentation, post-fusion — cinq sessions par lot, ou par partie de lot. E0 tient sa spec et son plan dans une seule (§4). Une trentaine de sessions séparent aujourd'hui de la tranche 2.
6. **Le script de simulation lit `assets/data/`** : E2, E3, E4 et la tranche 1 changent un schéma ou un dossier qu'il parse. Le lot qui casse le script le répare et le relance dans son plan — une relance à valeurs inchangées est un test de non-régression de D56 à D67 (§2.3).

---

## 1. La chaîne des lots

Le graphe et la table des lots sont dans le brainstorm §11 ; ce tableau y ajoute ce que l'orchestration doit savoir : l'identifiant ROADMAP après redécoupage, les fichiers pivots, le poids et le découpage en parties que la spec devra proposer.

| # | Lot | ID ROADMAP | Contenu, en une ligne | Décisions | Dépend de | Fichiers pivots | Poids et parties |
|:---|:---|:---|:---|:---|:---|:---|:---|
| 0 | **Session 0** | — | ROADMAP redécoupée, trois retouches au brainstorm, version cible | D64-D68 | — | `docs/ROADMAP.md`, `.obsidian_vault/` | Une session, sans code |
| 1 | **E0** | P-43 E0 | Un statut `might` par source ; `ratio` 0,5 arrondi au supérieur pour le Berserker | D36, D37 | — | `entity_stats.dart`, `status_effect.dart`, `stat_rule.dart`, `player_stats_manager.dart` (`StatGains`), textes générés (carte de classe, tutoriel), éditeur (ADR-100) | Petit : spec et plan dans une session, une PR |
| 2 | **E1** | P-43 E1 | Moteur de runes data-driven — applicateur de deltas, `valuePercentPerLevel`, `maxLevel`, éligibilité en donnée, renommage `fusionRank`, G1, G2 ; **sans changement de boucle** | D27, D28 (renommage), D33, D44, D51, D61, D68 | E0 (convention ; indépendant en code) | `forge_upgrade_data.dart`, `effect_resolver.dart`, `card_instance.dart`, `forge_rune_rules.dart`, `forge_upgrade_dialog.dart`, `shop_controller.dart`, `card_data.dart`, `card_text_renderer.dart`, `entity_descriptor.dart`, 8 JSON de `forge_upgrades/` | Moyen : un plan |
| 3 | **E2** | P-43 E2 | Fusion = forge — `mergeCards` propose une rune, héritage additionné, capacité et `pools` / `stackable` supprimés, `minFusionRank`, affûtage au feu, Puits tous les 3 actes, boutique (copie du deck, pré-forgées bornées), trois runes neuves | D3, D5, D6, D13, D14, D20, D22, D28, D32, D39, D46, D48, D63 (`b`), D65, D68 | E1 | `deck_controller.dart`, `deck_screen.dart`, `forge_upgrade_dialog.dart`, `rest_screen.dart`, `rest_card_selection_screen.dart`, `forge_fusion_screen.dart`, `forge_rune_rules.dart`, `map_content_placer.dart`, `shop_controller.dart`, `card_data.dart`, `card_instance.dart`, `ui_card.dart`, `tutorial_engine.dart:451`, 11 JSON | **Lourd** : deux parties — (1) fusion, héritage, capacité, affûtage ; (2) Puits, boutique, runes neuves |
| 4 | **E3** | P-43 E3 | Trouvaille et progression — table `cardDrops` et reliques A, C ; `maxHandSize` en stat de run ; XP en table par acte ; DDA 2 × Σ `fusionRank` ; *Sagesse* mythique ; sources d'affûtage (boss « XP », événement, mythique `maxLevel`) ; événement d'échange de relique ; Bénédiction et Flux en donnée | D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57-D60, D63 (Q15), D67 | E2 | `reward_controller.dart`, `game_constants.dart`, `run_controller.dart`, `player_stats_manager.dart`, `encounter_system.dart`, `level_up_reward_service.dart`, `level_up_rewards/`, `relics/`, `events/`, `event_controller.dart`, `passives/`, `passive_strategies.dart` | **Lourd** : deux parties — (1) trouvaille, main, XP, DDA ; (2) sources d'affûtage, événements, *Sagesse*, seuils |
| 5 | **E4** | P-43 E4 | Signatures en compétences de classe — hors du deck, coût et recharge, barre au HUD, disponibles dès le tour 1 ; `unique` et `characterSpecific` supprimés ; tutoriel, draft de départ, sauvegarde, dictionnaire | D7 (forme), D28 (`magic_missile`), D41, D49, D53 | E3 | `hero_data.dart`, `classes/*/skills/`, `game_data_service.dart`, `card_data.dart`, `hero_skills_link.dart`, `deck_controller.dart`, `combat_state.dart`, `effect_resolver.dart`, `lib/ui/widgets/hud/`, `tutorial_engine.dart:175`, `tutorial_starter_deck_widget.dart:41`, `starter_deck_draft_screen.dart`, `save_service.dart`, dictionnaire | **Lourd** : deux parties — (1) donnée, modèle, moteur, sauvegarde ; (2) HUD, tutoriel, draft, dictionnaire |
| 6 | **C1 + P-44 lot 1** | P-42 tranche 1 · P-44 lot 1 | Forme C (`cards/<passif>/`), trois lots (Rempart, Sang, Arcaniste), masquage des six autres passifs, tests `feeds` et cartes gratuites, écran d'évolution des signatures ; moteur `scaleWith`, multi-coups, `mightRatio`, statuts proportionnels, coûts combinés, cinq runes de pipeline | D8-D10, D12, D15-D17, D19, D21, D34 (ordre), D35, D38, D40, D45, D50, D54, D63 (Q9), D65, D66 | E4 | `game_data_service.dart`, `card_data.dart`, `passive_data.dart`, `passive_availability.dart`, `card_effect`, `effect_resolver.dart`, `damage_pipeline.dart`, `strategies.dart`, `power_rules.dart`, `enemy_instance.dart`, `turn_phase_manager.dart`, `passive_strategies.dart`, `draft_screen.dart`, `save_service.dart`, ~18 cartes JSON, 6 fichiers de signature, 5 runes JSON | **Le plus lourd** : trois parties — (1) moteur P-44 lot 1 sur les 17 neutres, avec les cinq runes ; (2) forme C, trois lots, masquage, tests ; (3) évolutions et écran |
| 7 | **C2** | P-42 tranche 2 | Trois lots de plus, passifs démasqués ; D30 avec Voile ; D34 (déclencheur) si Marque ; D55 si Sanctifié | D30, D34, D55, D16, D17 | C1 | `cards/<passif>/`, `passives/`, `passive_strategies.dart` | Moyen : composition à trancher (O3) |
| 8 | **C3** | P-42 tranche 3 | Les trois derniers lots | idem | C2 | idem | Moyen |
| 9 | **P-44 lot 2** | P-44 lot 2 | Malédictions, étourdissement, épines — et les cartes qu'ils doivent aux lots déjà livrés (Rempart : épines) | §9.2 #5, #7 | P-05 (`onHitEffect`), C1 | `enemy_intent.dart`, statuts, `deck_controller.dart` | Moyen |
| 10 | **P-44 lot 3** | P-44 lot 3 | Mots-clés (`retain`, `innate`, `ethereal`) et la rune `retain` ; production de cartes — et les cartes dues (Voile : `retain` ; Carnage : *Forge de guerre*) | §9.2 #6, #8, D65 (`retain`) | lot 2 | `deck_controller.dart` (fin de tour), `addCardToHand` | Moyen |
| 11 | **P-44 lot 4** | P-44 lot 4 | Effets interactifs (B19 : défausse choisie, piles), `CardTarget.none`, `costs.discard` — le « lot propre » de §9.2 #9, **absent du graphe** (O2) | §9.2 #9, §9.1 | lot 3 | `effect_strategy.dart` (résolution asynchrone) | Lourd : architecture |
| 12 | **P-16** | P-16 | Hérite : reliques de mana, puits d'or, survie après l'acte 5, boucle XP / niveau ennemi, échange 3 → 1 et événement de fusion (D29, D56, Q4, Q18), P-17 | D29, D56 | C3 | — | Calibration, pas de spec maintenant |

**Pourquoi cet ordre est forcé.** E1 avant E2 : la fusion propose une rune que seul l'applicateur sait appliquer. E2 avant E3 : les cartes trouvées ont besoin de leur puits, la fusion (D56). E3 avant E4 : c'est D31, dans E3, qui rend les signatures-cartes invisibles (D53). E4 avant C1 : l'écran d'évolution écrit sur `SignatureInstance`, qu'E4 crée. P-44 lot 1 avec C1 : sans `costs.hp` ni `scaleWith`, le lot Sang tombe à deux cartes (§7.4, ligne P-44). P-05 avant P-44 lot 2 : les malédictions sont injectées par une intention ennemie qui n'existe pas (`enemy_intent.dart:1`).

---

## 2. Cohérence vérifiée

### 2.1. Chaque décision a un lot

Les 68 décisions du §1 ont été relues une à une contre la table des lots de §11 et les nœuds du graphe. Résultat par famille :

| Famille | Décisions | Lot | Remarque |
|:---|:---|:---|:---|
| Garde-fous de Puissance | D36, D37 | E0 | D66, D68 |
| Moteur de runes | D27, D33, D44, D51, D61, D68 ; D28 pour le renommage | E1 | La frontière est D68 : E1 applique, E2 obtient |
| Fusion, affûtage, Puits, boutique | D3, D5, D6, D13, D14, D20, D22, D32, D39, D46, D48, D63 (`b` = 50), D65 (`cheap`, `precise`, `spectral`) ; D28 pour la capacité et les pré-forgées | E2 | D4 (runes à niveau) est couverte par D27 (E1) et D14 / D42 (E2, E3) |
| Trouvaille, main, XP, DDA, sources, seuils | D1, D2, D11, D23, D24, D25, D31, D42, D43, D47, D57, D58, D59, D60, D62, D63 (Q15), D67 | E3 | D26 est faite ; D52, D56 renvoient à P-16 |
| Signatures | D7 (forme), D41, D49, D53 ; D28 (`magic_missile` en Compétence) | E4 | Le modèle d'évolution (D19, D21, D54) est en C1 par D53 |
| Catalogue et P-44 lot 1 | D8, D9, D10, D12, D15, D16, D17, D19, D21, D34 (ordre des tranches), D35, D38, D40, D45, D50, D54, D63 (Q9), D65 (cinq runes), D66 | C1 + P-44 lot 1 | Une seule livraison, en parties |
| Tranches 2 et 3 | D30 (Voile, D66) ; D55 (*Prière*, Sanctifié) ; **D34, déclencheur de Marque — non assigné** | C2, C3 | O1, O3 |
| P-44 lots 2 à 4 | §9.2 #5 à #9 ; D65 (`retain`) | lots 2, 3, **4** | O2 |
| P-16 | D29, D52, D56 ; Q4, Q18 ; les collatéraux de la revue §9 | P-16 | Rien à ouvrir maintenant |
| Découpage | D64, D65, D66, D68 | session 0 (ROADMAP) | — |

Les items non numérotés ont aussi leur lot : G1 et G2 (§4.5) en E1 ; `wisdom.json` en `mythic` (§5) en E3 ; `EntitySource('cards/*/*.json')`, `isOfferableTo` étendu, `PassiveData.classes` à une seule classe (§6) en C1 ; le validateur `costs.armor` (§7.4) avec `costs`, en P-44 lot 1 ; `CardTarget.none` (§9.2) en P-44 lot 4.

### 2.2. Les transitions entre lots

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|
| E0 → E1 | Aucun : indépendants en code | — |
| E1 → E2 | La forge du feu et le nœud Forge de Fusion vivent encore ; E1 leur laisse `pools`, `stackable` et la capacité en lecture | D68 |
| E2 → E3 | La forge du feu a disparu, la trouvaille n'existe pas encore : les runes ne viennent que de la fusion, et les doublons du boss « cartes » et de la boutique seulement — les fusions sont rares pendant un lot | Voulu : E2 est « jouable seul », son rythme arrive avec E3 (§11, ligne E3). La spec E2 le dit |
| E3 → E4 | Les signatures sont encore des cartes : exclues de la trouvaille par `unique` (`isOfferableTo`), sans rune (aucune fusion possible, plus de forge au feu), `fusionRank` 0 pour la DDA | Rien à faire ; à vérifier par un test dans E3 |
| E4 → C1 | Les signatures sont des compétences sans évolution ; le deck ne connaît que les 17 neutres | C1 ajoute `evolutions` et l'écran |
| C1 → C2 | Six passifs masqués ; `fireball` reste neutre jusqu'au lot Marque (son id de tutoriel ne change pas) | O5 : le mécanisme de masquage est une décision de la spec C1 |
| C2 / C3 → P-44 lots 2-3 | Des cartes dues aux lots déjà livrés (Rempart : épines ; Voile : `retain` ; Carnage : *Forge de guerre*) s'écrivent quand le mécanisme arrive | §7.4 : la spec de chaque lot P-44 liste les cartes qu'il doit |

### 2.3. Ce que le script de simulation impose aux lots

`tool/simulations/d26_economy_sim.dart` lit `assets/data/` au lancement (`:723-845`) : les ennemis, **les cartes de `cards/` à plat** (`_jsonFiles('$root/cards')`), les reliques, `level_up_rewards/`, `forge_upgrades/` (`id`, `weight`, `eligibleCardTypes`, le reste par défaut — il ignore `pools`) et le bloc `mastery` des passifs. Ses lots du §7 et les runes neuves sont **codés en dur** (`:825-845`, un `switch` par id). Conséquences :

| Lot | Ce qui casse ou dérive | À faire dans le plan du lot |
|:---|:---|:---|
| E1 | Rien : `pools` n'est pas lu, `eligibleEffects` non plus | Relance facultative |
| E2 | Trois fichiers `cheap`, `precise`, `spectral` apparaissent : le `switch` les prend par défaut **en plus** des runes du §8 codées en dur — doublon probable | Aligner le chargeur, relancer : mêmes chiffres attendus |
| E3 | `level_up_rewards/` gagne un `effect` nouveau (affûtage, `maxLevel`) que le chargeur peut refuser ; `wisdom.json` change de pool | Aligner, relancer : D56 à D63 et D67 doivent se retrouver — c'est la règle de §12 |
| E4 | `classes/*/cards/` devient `skills/` ; le script lit `class.json` pour `statRules` et code les signatures en dur | Vérifier le chemin, relancer |
| C1 | `cards/<passif>/` apparaît : selon que `_jsonFiles` descend ou non dans les sous-dossiers, les cartes de lot passent pour des neutres ou sont ignorées ; les lots réels remplacent les lots génériques du script | Faire lire les lots réels, relancer : première mesure sur les vraies cartes |

Le script reste `dart analyze` propre (`CLAUDE.md`, § Tooling) ; il n'est ni un test ni un asset.

---

## 3. Ce qui reste à trancher, et quand

| # | Quoi | Quand | Proposition |
|:---:|:---|:---|:---|
| **O1** | **D34, déclencheur de *Marque du Mage*** (`onDamagingCardPlayed`, première carte de dégâts du tour) modifie un passif livré et n'a pas de lot | Avant la spec C2 | Avec le lot Marque, dans la tranche qui le porte. Une ligne à ajouter au nœud C2 de §11 |
| **O2** | **P-44 lot 4** — §9.2 #9 dit « dernier, lot propre » pour les effets interactifs ; le graphe de §11 n'a que trois lots | Session 0 | Ajouter `P44d` au graphe (`P44c → P44d`) et à la ligne P-44 : effets interactifs, `CardTarget.none`, `costs.discard` |
| **O3** | **La composition des tranches 2 et 3** | Avant la spec C2 | **Tranche 2 : Croisé, Vampire, Voile** — une par classe comme la tranche 1, Voile fixé par D66, Croisé et Vampire n'attendent que le lot 1 de P-44 (multi-coups ; Attaques qui piochent). **Tranche 3 : Sanctifié, Carnage, Marque** — Marque change un déclencheur (D34) et déplace `fireball`, l'id du tutoriel ; Carnage doit sa carte de production au lot 3 de P-44 ; Sanctifié demande un statut `hp_regen` neuf |
| **O4** | **Arcaniste n'a aucune carte d'exemple P-44** en §7.3, alors que sa colonne P-44 dit « multi-coups × `shock` » et que §7.4 exige une carte par mécanisme assigné | Spec C1 | La spec C1 écrit une Compétence multi-coups pour Arcaniste |
| **O5** | **Le masquage des six passifs** : `availablePassivesFor` n'a aucun filtre de déblocage — « débloqué vaut tous » (`passive_availability.dart`) | Spec C1 | Une règle dérivée de la donnée : **un passif dont le dossier `cards/<passif>/` est vide n'est pas disponible** — le répertoire dit la vérité, aucun champ à maintenir, et c'est le même point d'accès que P-13 branchera. Alternative : un champ `available: false` sur les six fichiers, à retirer tranche par tranche |
| **O6** | **Le numéro de version** que le chantier vise — « P-42 ira au numéro suivant, qui reste à décider » (ROADMAP §4) | Session 0, au plus tard à la post-fusion de E0 | E0 et E1 ne changent pas la boucle ; E2 la change. Un seul numéro pour tout P-43, décidé maintenant, évite de rouvrir la note à chaque lot comme `0.5.2` l'a été six fois |
| **O7** | **La ROADMAP dit « un seul programme en cinq lots, à ne pas ré-ordonner »** (§4) et fait dépendre P-43 de P-42 ; le brainstorm inverse l'ordre | Session 0 | `memory-bank-sync` réécrit l'encart et la table, en citant D64 |
| **O8** | ~~**Le commit** : les trois documents, le script, `CLAUDE.md` et `docs/INDEX.md` sont dans l'arbre de travail depuis le 30/09~~ | ✅ **Fait le 01/10** | Commité par lot et poussé sur `main` : brainstorm, revue, simulation et son script, orchestration, index |

O1, O2 et O4 sont trois retouches d'une ligne au brainstorm ; elles s'appliquent dans la session 0 si le propriétaire les valide.

---

## 4. La chaîne de sessions par lot

Le rythme est celui de P-41 et de P-49, une session neuve par phase ; les prompts de §5 le suivent.

| Phase | Skill | Produit | Prompt |
|:---|:---|:---|:---|
| **A — Spec** | `superpowers:brainstorming` | `docs/superpowers/specs/<date>-<id>-<sujet>-design.md`, commité sur `main` | §5.2 à §5.7, un par lot |
| **B — Plan** | `superpowers:writing-plans` | `docs/superpowers/plans/<date>-<id>-<sujet>.md`, un par partie, commité sur `main` | Gabarit §5.8.1 |
| **C — Passe de correction** | — | Le plan corrigé contre la spec et le code de `main` à jour | Gabarit §5.8.2 |
| **D — Implémentation** | `superpowers:subagent-driven-development` | Une branche `feat/…` dans le checkout principal, une PR | Gabarit §5.8.3 |
| **E — Post-fusion** | `patch-notes-writer`, `memory-bank-sync` | Note joueur, ROADMAP, memory bank, ADR | Gabarit §5.8.4 |

**Exceptions.** E0 tient A et B dans une session : deux décisions, trois fichiers. Les lots en parties (E2, E3, E4, C1) ont **une** spec et **une** phase B à E **par partie** — c'est ce que P-41 a fait pour ses lots B, C et D.

**Compte.** Session 0, puis E0 (4), E1 (5), E2 (1 + 2 × 4), E3 (1 + 2 × 4), E4 (1 + 2 × 4), C1 + P-44 lot 1 (1 + 3 × 4) : **une trentaine de sessions** avant la tranche 2. C'est le prix de D10 et de D64, annoncé.

---

## 5. Les prompts

### 5.0. Le préambule commun

Chaque prompt de spec commence par ces trois lignes, reprises des sessions précédentes :

````
Tu travailles dans le dépôt Hero's Draft (Flutter, Flame, Riverpod, 100 % data-driven). Lis `CLAUDE.md` d'abord. Réponds et écris en français.
````

Chaque prompt cite la base de tests **1187 à `3b8c66f`, à re-mesurer** : après chaque fusion, le nombre change, et c'est le prompt suivant qui porte le nouveau.

### 5.1. Session 0 — ROADMAP redécoupée, retouches, version

````
# Session 0 — Redécouper la ROADMAP après le brainstorm v3

## Contexte

Le brainstorm v3 « Héros, cartes et économie de deck » est clos : 68 décisions acquises (§1), quatre passes de cohérence (revue, §2 à §13), une simulation de 2 700 runs relancée à k = 2 (rapport, §7). Le chantier « Économie unifiée » est découpé en cinq lots E0 à E4 (brainstorm §11, D64 à D68), suivi du catalogue en trois tranches et de P-44 en lots. Le dossier est commité et poussé sur `main` depuis le 01/10 : le brainstorm, la revue, le rapport de simulation et son script, le document d'orchestration.

## Ce que cette session fait, dans l'ordre

1. **Trois retouches au brainstorm, à faire valider par le propriétaire en début de session** (orchestration §3, O1, O2, O4) : au nœud C2 de §11, « Marque du Mage sur la première carte de dégâts (D34) avec le lot Marque » ; au graphe de §11, un nœud `P44d["P-44 lot 4<br/>effets interactifs (B19) · CardTarget.none · costs.discard"]` après `P44c`, et la ligne P-44 de la table « La roadmap à redécouper » passe à **quatre** lots ; en §7.3, ligne Arcaniste, une note « une Compétence multi-coups à écrire en tranche 1 (§7.4) ». Un commit de documentation sur `main`, en français sans accents, terminé par `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. Une retouche refusée ne s'applique pas ; dis-le dans le compte rendu.
2. **`memory-bank-sync`**, avec pour consigne de redécouper `docs/ROADMAP.md` selon le brainstorm §11, table « La roadmap à redécouper » :
   - **P-43** devient « Économie unifiée », **premier chantier** du programme, en cinq lots E0 à E4 (contenu et décisions : brainstorm §11, table « Les cinq lots de E ») ; il ne dépend de rien, P-41 étant clos ; sa « limite de taille » est annulée par D2, son « coût de merge » par D3.
   - **P-42** devient « Catalogue par lots de passif », en trois tranches, après E4 ; la tranche 1 (Rempart, Sang, Arcaniste) est une seule livraison avec **P-44 lot 1**.
   - **P-44** devient quatre lots : 1 (`scaleWith`, multi-coups, `mightRatio`, statuts proportionnels, coûts combinés, cinq runes de pipeline) avec la tranche 1 ; 2 (malédictions, étourdissement, épines) après P-05 ; 3 (mots-clés, `retain`, production de cartes) ; 4 (effets interactifs, `CardTarget.none`, `costs.discard`).
   - L'encart « un seul programme en cinq lots, à ne pas ré-ordonner » est réécrit : l'ordre est désormais P-43 → P-42 → P-44, motivé par D64 (« l'économie décide combien de cartes un lot peut contenir »).
   - **P-18** : ses deux points restants sont annulés (D2, D3), à noter sur sa ligne.
   - **P-16** hérite cinq constats, à porter sur sa ligne avec leurs chiffres à k = 2 (rapport §7.2) : reliques de mana ; un puits d'or à créer (5 596 or dorment à l'acte 15) ; la survie après l'acte 5 (quasi-mort dans 100 % des runs) ; la boucle XP / niveau ennemi (D58) ; l'échange 3 → 1 et l'événement de fusion (D29, D56 ; Q4 et Q18 ouvertes).
   - §9 « Séquencement » : le jalon suivant est P-43.
   - `_patterns/` : une fiche pour le script de simulation (ce qu'il lit, quand le relancer, orchestration §2.3) ; `_rules` périmées relevées par la revue §9 (`01-00`, `03-8` sur `eco`, `04-00` sur `strength`) : corrigées ou marquées « change avec E1 / E2 ».
   - `activeContext.md` : focus courant = spec E0 ; `progress.md` : rien à re-mesurer côté code, `main` est à `3b8c66f`.
   Aucun chiffre sans commande. Chaque fichier sous son plafond.
3. **Le numéro de version** : le propriétaire décide ici du numéro que P-43 vise (`0.5.3` ou `0.6.0`), pour que `patch-notes-writer` l'applique à la première livraison au lieu de rouvrir une note à chaque lot. Pose-lui la question, consigne la réponse dans `docs/ROADMAP.md` §4 (là où « P-42 ira au numéro suivant, qui reste à décider » l'attend).

## Ce que cette session ne fait pas

Aucune spec, aucun code, aucun fichier de `lib/`, `assets/` ou `test/`. Ne lance pas `patch-notes-writer` : rien n'est livré au joueur.

## En fin de session

Un compte rendu court : les hashs des commits, les lignes de ROADMAP réécrites, le numéro de version décidé, et toute incohérence trouvée entre la ROADMAP et le brainstorm que `memory-bank-sync` n'a pas pu résoudre seul.
````

### 5.2. E0 — spec et plan : un statut `might` par source, `ratio` de conversion

````
# E0 — Spec et plan : un statut `might` par source, et le `ratio` de conversion d'armure du Berserker

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-0X-p43-e0-puissance-par-source-et-ratio-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md` ; **puis son plan d'implémentation** dans `docs/superpowers/plans/`, avec `superpowers:writing-plans`, sur le modèle de `2026-09-16-p49-passifs-partages.md`. Le lot est petit — deux décisions, trois fichiers de moteur — c'est pourquoi spec et plan tiennent dans une session. **Aucun code, aucune donnée modifiée cette session.** Écris et commite les deux documents sur `main`.

Utilise `superpowers:brainstorming` pour la spec. Presque tout est tranché (D36, D37) : l'échange avec le propriétaire porte sur la forme, et ses arbitrages lui appartiennent.

## Le chantier

E0 est le premier des cinq lots de **P-43 « Économie unifiée »** (brainstorm v3, §11, D64 à D68 ; `docs/ROADMAP.md` §4 tel que la session 0 l'a réécrit). Il ne change rien à la boucle de jeu : un correctif d'aujourd'hui et un garde-fou de la même famille, livrés avant tout le reste.

- **D36 — un statut `might` par source.** `EntityStats.addStatus` (`entity_stats.dart:134-139`) fusionne deux `might` de durées différentes en un seul, valeur sommée, durée maximale (`StatusEffect.combine`, `isStackable` vrai par défaut, `status_effect.dart:17`) : `demon_form` (2 pendant 4 tours) puis `iron_wall` chez le Berserker (10 pendant 1 tour) donne **Puissance 12 pendant 4 tours**, et Rage s'y accumule. Demain `StatusEffect` porte l'id de ce qui l'a posé — carte, passif, règle de classe, relique — et `addStatus` ne fusionne que même statut *et* même source. La même carte rejouée s'additionne comme aujourd'hui ; `effectiveMight` somme déjà toutes les entrées ; `tickStatuses` les vieillit séparément ; le HUD affiche la somme.
- **D37 — `ratio` sur `statRules`.** La conversion d'armure du Berserker passe de 1:1 à **0,5:1, arrondi à l'entier supérieur** (6 → 3, 5 → 3, 1 → 1) : un champ `ratio` (défaut 1) sur `stat_rule.dart`, appliqué par `StatGains._convert`, écrit dans `assets/data/classes/berserker/class.json`. `iron_wall` chez lui : +10 → +5 Puissance ; `awakening` : +2 ; `warcry` : +2.

## À lire avant de poser la première question

1. `docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md` — §1, lignes D36, D37, D66, D68 ; §11, table des lots, ligne E0 ; §7.2, ce que le Berserker lit des neutres sous D37.
2. `docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md` — §8.1, risque R3 (a, b, c) ; §8.2, idées 2 et 3.
3. Les ADR qui contraignent : ADR-097 (Puissance unique orientée par la classe), ADR-090 (textes générés depuis la donnée), ADR-100 (l'éditeur valide `statRules` sur le vocabulaire lu sur `StatRule`), ADR-081 (isolation du tutoriel).
4. `docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md`, §7 (les `statRules`) et §9.1 (l'étape « Armure » du tutoriel, qui mesure le gain réel).

## État mesuré le 30/09 — à revérifier, pas à croire

- `stat_rule.dart` : `RuleMode { convert }` seul ; champs `stat`, `mode`, `to`, `duration`. `StatGains._convert` dans `player_stats_manager.dart`.
- Le tutoriel (P-41 lot D partie 1) fait passer son gain de démonstration par `StatGains.apply` et les `statRules` de la classe, en deux temps, et **génère** le titre de l'étape et la règle écrite en clair depuis la règle ; la carte de classe affiche la règle générée (ADR-090).
- L'éditeur de contenu refuse un `mode` inconnu sur `statRules` (ADR-100) ; l'onglet Héros du menu de debug affiche les règles de stat.

## Ce que la spec doit fixer

- **L'identité d'une source** : l'id que porte un `might` posé par une carte (l'id de carte, ou l'`uniqueId` de l'instance ?), par un passif, par une règle de classe, par une relique — et ce que « la même carte rejouée s'additionne » veut dire quand deux exemplaires d'une même carte sont dans le deck. Un choix, pas deux.
- **La sauvegarde n'est pas concernée** : `SaveService` n'est jamais appelé en combat, les statuts ne sont pas persistés — à vérifier et à écrire.
- **Les textes générés** : la règle en clair de la carte de classe et les titres du tutoriel doivent dire « 6 armure → 3 Puissance » — où ces textes sont produits, et le gabarit qui prend `ratio`.
- **L'éditeur** : `ratio` entre dans le vocabulaire validé (borne : strictement positif, au plus 1 — à trancher), et dans l'onglet Héros.
- **Les tests** : `demon_form` puis `iron_wall` donne deux effets (2 pendant 4, 10 pendant 1), vieillis séparément ; l'arrondi supérieur sur 1, 5, 6 armure ; le tutoriel qui mesure le gain réel ne casse pas.
- **Ce que le joueur voit** : D37 se voit — le Berserker convertit moitié moins ; D36 est un correctif. `patch-notes-writer` décide de l'entrée, la spec dit ce qui change.

## Ce que cette spec ne doit pas absorber

- Rien de E1 : ni `fusionRank`, ni les runes, ni `maxLevel`. E0 ne touche ni `forge_upgrade_data.dart` ni `effect_resolver.dart`.
- Ni le `mightRatio` par effet (D38) ni le budget de Puissance : P-44 lot 1.
- Aucun rééquilibrage de carte : D37 est un garde-fou de classe, pas un nerf de carte.

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire : le brainstorm a été vérifié à `3b8c66f`, `main` a pu bouger.
- Le plan reprend les contraintes globales du plan de P-49 : `dart analyze` propre après chaque tâche ; `flutter test` entièrement vert (base 1187 à `3b8c66f`, à re-mesurer) ; jamais `dart format` ; Write / Edit plutôt que heredoc ; branche `feat/p43-e0-puissance-par-source` ; commits en français sans accents, terminés par `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` ; ne jamais commiter les registrants générés.
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync` : une spec n'est pas une livraison. Un compte rendu court : les choix de forme pris avec le propriétaire, la carte des fichiers du plan, le nombre de tâches, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.3. E1 — spec : le moteur de runes data-driven

````
# E1 — Spec : le moteur de runes data-driven

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-0X-p43-e1-moteur-de-runes-data-driven-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md`. **Aucun code, aucune donnée modifiée cette session.** Le plan viendra dans une session suivante. Commite la spec sur `main`.

Utilise `superpowers:brainstorming`. Les décisions sont acquises ; ce qui se conçoit ici, c'est la **forme de l'applicateur de deltas**, et elle engage deux consommateurs.

## Le chantier

E1 est le deuxième lot de **P-43 « Économie unifiée »**, le prérequis de tout le reste (brainstorm §4.4, §8, §12) : aujourd'hui l'effet d'une rune est un `switch` codé en dur sur son id (`effect_resolver.dart:143-161` — `sharp` vaut `+2 × k` parce qu'un `case 'sharp'` le dit), et `ForgeUpgradeData.valueMultiplier` n'est lu que par l'affichage. Demain une rune déclare son effet dans son fichier et un applicateur l'applique. **E1 ne change pas la boucle de jeu** (D68) : E0 est fusionné, E2 obtiendra les runes autrement, E1 change seulement la manière dont elles s'appliquent et lesquelles sont éligibles.

Décisions du lot : **D27** (`maxLevel` par rune — `eco` et `quick` à 1), **D33** (`sharp`, `hardened`, `spectral`, `lifesteal`, `piercing` en pourcentage de la valeur de base, au moins +1 par niveau — G1), **D44** et **D51** (éligibilité en donnée : `requiresMinCost`, `excludesRunes`, `excludesEffects`, à côté d'`eligibleCardTypes` et `requiresExhaust`), **D61** (`sharp` et `hardened` éligibles par effet, `eligibleEffects` ; `excludesRunes` symétrique par moteur pour toute paire ; `requiresMinCost` lit le coût courant), **D28** pour le seul renommage `forgeSlotBonus` → `fusionRank`, **D68** (la frontière avec E2), et G1, G2 (§4.5).

## À lire avant de poser la première question

1. Brainstorm — §4.2 (le modèle de rune « aujourd'hui / demain », l'esquisse `sharp.json`, et le prédicat du geste de fusion, dont E1 livre la fonction et E2 l'appelant) ; §4.4, dernier point (« le prérequis moteur » : un applicateur de deltas que les évolutions de signature partageront **en code**, jamais en données ni en affichage) ; §4.5 (G1, G2) ; §8 en entier (table des runes, table des `maxLevel`, « le prérequis ») ; §11, ligne E1 ; §1 lignes D27, D33, D44, D48, D51, D61, D68.
2. Revue — §2.1 (les sept lecteurs de la capacité : **E1 n'en touche aucun**, c'est E2) ; §3.5 (ce que les runes font vraiment aujourd'hui) ; §13, IV3 et IV4.
3. ADR-094 (échelle de rareté explicite, `forgeSlotBonus` — à amender, pas à réécrire), ADR-061 (registre de stratégies, le modèle), ADR-100 (l'éditeur lit son vocabulaire sur le modèle).

## État mesuré le 30/09 — à revérifier, pas à croire

- `forge_upgrade_data.dart` : `pools`, `valueMultiplier`, `eligibleCardTypes`, `stackable` (défaut vrai), `requiresExhaust` ; `entity_descriptor.dart:238` le décrit pour l'éditeur ; `card_text_renderer.dart:106` et `forge_upgrade_data.dart:88` lisent `valueMultiplier` pour l'affichage.
- `effect_resolver.dart:142-174` : le `switch` ; `:222-228` : le multiplicateur de rareté, appliqué aussi à `draw` et `gain_mana` (G2) ; le bonus des runes s'ajoute après lui.
- `card_instance.dart:35-50` : les paliers de rareté (1,0 / 1,2 / 1,4 / 1,6 / 2,0) et leurs collisions d'arrondi (G1).
- `forge_rune_rules.dart:46-52` : `consolidate` additionne les tiers de même id — le lecteur naturel de `maxLevel` dès E1.
- `forge_upgrade_dialog.dart:80-86` et `shop_controller.dart:51-57` : les deux lecteurs de l'éligibilité, qui filtrent par `pools.contains(rareté)` **et gardent `pools` jusqu'à E2** (D68).
- `card_data.dart:33-39` : `forgeSlotBonus` 0 / 1 / 2 / 3 / 4, `unique` 0 ; son seul lecteur est `forgeCapacityAt` (`:142-143`), qui reste.

## Ce que la spec doit fixer

- **La forme de l'applicateur** : comment une rune déclare son effet en donnée (par niveau, en pourcentage, en piles, binaire ; sur quel champ de la carte ou de l'effet) pour couvrir les huit runes d'aujourd'hui, les trois d'E2 (`cheap`, `precise`, `spectral`) et les six de P-44 (§8, colonne « Moteur »), **sans en écrire aucune de neuve ici** ; et la couture que les évolutions de signature (C1, `SignatureEvolutionData`) réutiliseront en code sans confondre les deux systèmes.
- **Un seul prédicat d'éligibilité**, fonction pure, appelé par le dialogue du feu et la boutique aujourd'hui, par `mergeCards` demain — sur le modèle d'`isOfferableTo` (ADR-101). Ses règles : `eligibleCardTypes` ou `eligibleEffects`, `requiresExhaust`, `requiresMinCost` sur le coût courant, `excludesEffects`, `excludesRunes` symétrique.
- **`maxLevel`** : qui le lit en E1 (`consolidate` ; l'affichage ?), et la valeur de chaque rune d'aujourd'hui selon la table de §8 (`eco`, `quick`, `enduring` : 1 ; `freezing` : 1 tant que `freeze` est booléen ; les autres : aucun).
- **G1 et G2** : la monotonie stricte des paliers ; le multiplicateur de rareté gelé sur `draw` et `gain_mana`.
- **Le renommage** `forgeSlotBonus` → `fusionRank` et l'amendement d'ADR-094 ; `forgeCapacityAt` continue de le lire.
- **Les huit fichiers JSON** : ce qui s'ajoute (`valuePercentPerLevel`, `maxLevel`, `eligibleEffects`, `requiresMinCost`, `excludesRunes`, `excludesEffects`), ce qui **reste** (`pools`, `stackable`, D68), et le descripteur de l'éditeur.
- **Ce que le joueur voit** : `sharp` donne +15 % de la base (au moins +1) au lieu de +2 par niveau — `strike_basic` 6 → +1 — à la forge du feu, seul effet visible.
- **Les tests** : un test de données sur chaque rune (déclare son éligibilité, son `maxLevel` s'il en a un) ; l'applicateur par rune ; la symétrie d'`excludesRunes` ; `consolidate` borné ; G1 ; G2.
- **Ce que la spec dit de la simulation** : le script ne lit ni `pools` ni `eligibleEffects` (orchestration §2.3) — aucune relance requise par E1.

## Ce que cette spec ne doit pas absorber

- La fusion, l'héritage, l'affûtage, le Puits, la boutique, les pré-forgées, la suppression de la capacité, de `pools` et de `stackable`, `minFusionRank`, « une rune par type par carte » : **E2** (D68).
- Aucune rune neuve : `cheap`, `precise`, `spectral` sont E2 ; `piercing`, `lifesteal`, `splash`, `echo`, `transfusion` sont P-44 lot 1 ; `retain` est P-44 lot 3.
- Les évolutions de signature : C1. E1 leur laisse une couture en code, rien de plus.

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire.
- La spec nomme les tests existants qu'elle touche (revue §2.1 en liste plusieurs pour E2 — ne prends que ceux d'E1).
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync`. Un compte rendu court : la forme retenue pour l'applicateur et le prédicat, la liste des fichiers touchés, les tests prévus, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.4. E2 — spec : fusion = forge

````
# E2 — Spec : fusion = forge — héritage, affûtage, Puits, boutique

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-0X-p43-e2-fusion-egale-forge-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md`. **Aucun code, aucune donnée modifiée cette session.** La spec **propose un découpage en deux parties**, chacune avec son plan dans une session suivante, et l'invariant qui justifie l'ordre — comme P-41 pour ses lots B, C et D. Commite la spec sur `main`.

Utilise `superpowers:brainstorming`. Les décisions sont acquises ; les arbitrages restants portent sur les écrans et sur le découpage.

## Le chantier

E2 est le troisième lot de **P-43 « Économie unifiée »** et **le cœur de P3** (brainstorm §3) : la rune ne s'obtient plus au feu de camp mais à la fusion, le feu affûte, le nœud Forge de Fusion devient le Puits d'échange, la boutique vend une copie du deck. Un seul changement de boucle, cohérent et jouable seul. E1 est fusionné : l'applicateur et le prédicat d'éligibilité existent, `pools`, `stackable` et la capacité sont encore en lecture — **E2 les supprime avec les deux écrans qui les lisaient** (D68).

Décisions du lot : **D3** (à chaque fusion 3 → 1, la carte monte de rareté et le joueur choisit 1 rune parmi 3 ; une rune par type par carte), **D13** (héritage : runes conservées, même id additionné, puis la rune neuve), **D65** (moins de 3 si moins d'éligibles, jamais aucune tant qu'une existe ; `cheap`, `precise`, `spectral` s'ajoutent), **D48** (`eco` et `quick` à `minFusionRank: 2`), **D28** (capacité supprimée, pré-forgées bornées par `fusionRank`), **D5** et **D14** (le feu : affûter une rune d'un niveau, une fois par visite), **D20** et **D63** (`b × niveau`, `b` = 50), **D32** (pas de taxe), **D6**, **D22** et **D39** (le Puits : toutes les runes éligibles, deux tiers du niveau arrondi au plus proche et borné par `maxLevel`, `base × niveau`, garanti tous les 3 actes), **D46** (la copie du deck en boutique), **D68**.

## À lire avant de poser la première question

1. Brainstorm — §4.2 en entier (le rang de fusion, le modèle de rune, le geste de fusion, l'héritage, l'or, ce que la simulation en a fait) ; §4.3 (feu et Puits) ; §8 (lignes `cheap`, `precise`, `spectral`, la table des `maxLevel`, le paragraphe D65) ; §11, ligne E2 ; §12, lignes 1 et 2 ; §1, les décisions ci-dessus et D65, D68.
2. Revue — **§2.1 en entier** : les sept lecteurs de la capacité et ce qu'ils deviennent, les six tests à réécrire, les ADR et fiches `_rules` à amender, la décision sur les pré-forgées ; §11, S4 et S6 ; §13, IV3 et IV5.
3. Rapport — §2.3 (le feu est un lit : 14 repos, 5 affûtages, 1 oubli sur 20 visites), §3.6 (le Puits ne consomme pas), §3.8 (`b`), §3.15 (l'ordre d'affûtage n'a pas d'enjeu). La spec ne recalibre rien : elle livre les valeurs mesurées.
4. ADR-074 (le nœud `forgeFusion` à 25 % par carte — à amender pour « garanti tous les 3 actes »), ADR-094 (à amender : plus de capacité), ADR-101, ADR-078 (le remélange à sec, que `quick` et `eco` exploitaient).

## État mesuré le 30/09 — à revérifier, pas à croire

- `deck_controller.dart:288` (`mergeCards`), `:314-321` (héritage tronqué à la capacité) ; `deck_screen.dart:200-231` (le choix d'héritage) ; `forge_upgrade_dialog.dart:32,51` (le dialogue, plafonné) ; `run_controller.dart:32-33` (`forgeSlots`, `forgeTargetCardId` : la persistance anti-reroll).
- `rest_screen.dart:29` (repos 30 %), `rest_card_selection_screen.dart:30` (refuse la forge si la carte est pleine).
- `forge_fusion_screen.dart:102,112` et `forge_rune_rules.dart:60-78` (`fusionOptionsFor` : le nœud n'accepte qu'une carte portant deux fois le même id — il meurt avec « une rune par type », c'est le Puits qui prend sa place) ; `map_content_placer.dart:24-36` (le placement).
- `shop_controller.dart:188-205` (pré-forgées), `:341-355` (Miroir magique), `shop_state.dart:16` ; `card_data.dart:142-143` (`forgeCapacityAt`), `card_instance.dart:24` (`forgeCapacity`), `ui_card.dart:69,101,241` et `card_text_renderer.dart:519` (fentes vides).
- `tutorial_engine.dart:451` : le `mergeCards()` du tutoriel.
- `tool/simulations/d26_economy_sim.dart:825-845` : les runes neuves du §8 sont codées en dur ; trois fichiers `cheap`, `precise`, `spectral` seraient pris en plus par le `switch` par défaut.

## Ce que la spec doit fixer

- **Le découpage en deux parties et son invariant.** Proposition : (1) la fusion propose une rune, l'héritage, la suppression de la capacité, l'affûtage au feu — la boucle change une fois ; (2) le Puits, la boutique, les trois runes neuves, `minFusionRank`, `pools` et `stackable` supprimés. À défendre ou à remplacer.
- **Le geste de fusion** : `ForgeUpgradeDialog` rappelé depuis l'écran de deck ; ce que `forgeTargetCardId` désigne désormais ; où la carte fusionnée entre au niveau 1 de sa rune ; le prédicat d'E1 comparé au rang **atteint** (`nextRarity.fusionRank ≥ minFusionRank`, revue §2.1).
- **L'affûtage** : l'écran (carte, puis rune, puis +1), `b × niveau`, une fois par visite — comment « une fois » est tenu (un drapeau de visite, comme le repos ?), `maxLevel` respecté, aucune rune ajoutée au feu.
- **Le Puits** : l'écran, « toutes les runes éligibles au sens de §4.2 », les deux tiers arrondis au plus proche et bornés, `base × niveau` de la rune donnée, un nœud garanti tous les 3 actes sur les étages 3-7 (D22) — le placement et son test.
- **La boutique** : la quatrième carte (copie tirée dans le deck, même rang, sans rune, prix par rareté — quelle table ?), les pré-forgées bornées par `fusionRank`.
- **Les trois runes neuves** : `cheap` (−1, minimum 0, `requiresMinCost: 1`, exclut `eco`), `precise` (+5 % de critique par niveau, `maxLevel` 10), `spectral` (+40 % par niveau, épuise) — leurs fichiers, poids 50, `minFusionRank` 1 (D63).
- **La transition E2 → E3** : sans trouvaille, les doublons ne viennent que du boss « cartes » et de la boutique — la spec le dit, et dit que c'est voulu.
- **Le tutoriel** (`:451`) et **la simulation** : le plan aligne le chargeur du script sur les trois fichiers neufs et relance (`dart run tool/simulations/d26_economy_sim.dart`, 8 à 10 minutes) ; mêmes chiffres attendus, sinon on s'arrête.
- **Les tests** de la revue §2.1 ; les ADR-074 et ADR-094 à amender ; les fiches `_rules/02-3`, `02-4`, `03-7`, `03-8` à corriger — par `memory-bank-sync`, en post-fusion, la spec les nomme.
- **Ce que le joueur voit** : tout. C'est le lot de la note joueur.

## Ce que cette spec ne doit pas absorber

- La trouvaille, `maxHandSize`, l'XP, la DDA, *Sagesse*, les sources d'affûtage hors feu (boss « XP », événement, mythique), l'événement de relique : **E3**.
- Les signatures : **E4**. Elles sont encore des cartes `unique`, sans copie possible, donc sans fusion ni rune — la spec le constate, rien de plus.
- Les runes de pipeline (`piercing`, `lifesteal`, `splash`, `echo`, `transfusion`) : P-44 lot 1. `retain` : P-44 lot 3.
- L'échange 3 → 1 et l'événement de fusion : P-16 (D56).

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire : E1 vient de fusionner, les lignes ont bougé.
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync`. Un compte rendu court : les deux parties et leur invariant, les arbitrages d'écran pris par le propriétaire, la liste des fichiers par partie, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.5. E3 — spec : trouvaille et progression

````
# E3 — Spec : trouvaille et progression

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-0X-p43-e3-trouvaille-et-progression-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md`. **Aucun code, aucune donnée modifiée cette session.** La spec **propose un découpage en deux parties**, chacune avec son plan dans une session suivante, et l'invariant qui justifie l'ordre. Commite la spec sur `main`.

Utilise `superpowers:brainstorming`. Les valeurs sont **mesurées** (rapport §4 et §7) et acquises (D56 à D63, D67) : la spec les livre, elle ne les rediscute pas. Ce qui se conçoit ici, c'est où chaque table vit en donnée et comment les sources neuves s'écrivent.

## Le chantier

E3 est le quatrième lot de **P-43 « Économie unifiée »** : tout ce qui alimente la fusion d'E2. E2 est fusionné : la fusion propose une rune, le feu affûte, le Puits échange. Il manque les cartes — et la progression qui les accompagne.

Décisions du lot : **D1** et **D31** amendée par **D57** (une carte garantie après chaque combat normal ; en élite, une garantie et 25 % pour une seconde ; tirage uniforme dans le pool offrable, `common`, sans refus ; reliques A — +25 % de seconde carte en élite, rare — et C — +1 carte garantie en combat normal, rare au moins — ; B supprimée), **D2** et **D25** (`maxHandSize` devient une stat de run, sur le modèle de `cardsPerTurn` ; ADR-078 D3 amendé), **D24**, **D58** et **D67** (l'XP en table par acte, en donnée : 115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015 ; au-delà, la dernière valeur répétée), **D47** et **D59** (`PlayerPower` lit 2 × Σ `fusionRank` à la place de `playerCardsCount × 2`), **D11** (*Sagesse* en pool `mythic`), **D42** (le boss « XP » ne donne plus de carte : une rune tirée dans tout le deck monte d'un niveau, une relique légendaire porte ce nombre au-delà de 1 ; une issue d'événement affûte ; une récompense de niveau mythique monte de 1 le `maxLevel` d'une rune), **D23** et **D63** (un événement d'échange de relique — valeur de spec : la plus faible contre 40 or × (rareté + 1), ou 20 % des PV sous 50 % des PV), **D43** et **D60** (`threshold` de Bénédiction en donnée, à 5, la Maîtrise sur la valeur ; `floor: 2` sur Flux de Mana — ferme R5), **D62** (pour information : chaque mythique a son propre jet).

## À lire avant de poser la première question

1. Brainstorm — §4.1 en entier (le mécanisme, la table `cardDrops`, le plafond de main, ce que la simulation a mesuré, les sources de doublon) ; §4.3 (D42, les sources d'affûtage) ; §5 (`wisdom.json`, les reliques de mana qui restent à P-16) ; §2, l'encadré sur la « pioche infinie » ; §11, ligne E3 et le nœud R du graphe ; §13, Q5 et Q15 ; §1, les décisions ci-dessus.
2. Revue — §3.1 E2 (la courbe d'XP d'aujourd'hui), §3.2 E3 (ADR-078 renversé), §9 (les collatéraux routés vers P-16 — **pas vers E3**), annexe A n° 5, 11, 12, 13, 20, 23.
3. Rapport — §2.1 (la référence), §3.1, §3.3, §3.9, §3.10, §3.11, §3.16, §4 (valeurs recommandées), **§7.1** (la table à k = 2) et §7.3.
4. ADR-078 (D3 : `maxHandSize` constante — à amender), ADR-098 (récompenses de niveau en donnée, `RewardEffect`, gabarits à trous), ADR-099 (`requires`), ADR-101.

## État mesuré le 30/09 — à revérifier, pas à croire

- `reward_controller.dart:75-82` (`handleVictory`), `:83-165` (XP, or, reliques — `:86` le +10 % d'XP par niveau), `:168-195` (récompenses de boss ; `:186-194` le `doubleXp` et sa carte bonus, qui disparaît).
- `game_constants.dart:36` (`maxHandSize = 10`), `deck_controller.dart:200` (`_drawInto` casse à la limite), `run_controller.dart:41` et `player_stats_manager.dart:102-108` (`cardsPerTurn` et `applyRunRuleModifier`, le modèle).
- `player_stats_manager.dart:127` : `100 × 1,5^(n−1)`.
- `encounter_system.dart:97-120` (`PlayerPower`, `:101` le terme de taille), `:136-148` (le niveau ennemi suit le héros).
- `level_up_reward_service.dart:38-148` (`:50-57` le jet mythique, `:127-145` un jet par mythique), `level_up_reward_data.dart:7-11` (`RewardEffect { stat, cloneCard }`), `:277` (`values`) ; `level_up_rewards/wisdom.json`, `mirror.json`.
- `event_controller.dart:80-100`, `events/*.json` ; `relics/*.json` (25 reliques, 5 de mana) ; `passives/blessing.json`, `mana_flux.json`, `passive_strategies.dart:107,146`.
- Le script : `level_up_rewards/` est parsé ; un `effect` inconnu peut le faire échouer.

## Ce que la spec doit fixer

- **Le découpage en deux parties et son invariant.** Proposition : (1) la boucle — `cardDrops` et les reliques A, C ; `maxHandSize` en stat de run ; l'XP en table ; la DDA — ; (2) les sources — boss « XP », relique légendaire, événement d'affûtage, mythique `maxLevel`, *Sagesse*, événement de relique, seuils en donnée.
- **La « pioche infinie » d'abord** (D25, nœud R) : avant d'écrire la migration de `maxHandSize`, reproduire ou faire reproduire par le propriétaire l'observation du testeur sur un build ≥ ADR-078. Reproduite : un bug à corriger dans ce lot, et l'ADR s'amende pour la raison observée. Non reproduite : D2 tient quand même — la main reste la seule limite, `maxHandSize` migre pour être modifiable —, et la spec dit ce que le testeur a vu (le cyclage).
- **Où vivent les tables en donnée** : `cardDrops` (Q5 : `GameConstants` tant que le socle de la carte n'existe pas — P-50 est proposé, pas dans la ROADMAP) ; la table d'XP (« en donnée », D24 — un document plat comme `audio.json`, ou une constante nommée ? `CLAUDE.md` réserve les documents plats aux configurations uniques) ; `threshold` et `floor` sur les passifs (`PassiveData.threshold` existe pour Flux).
- **`RewardEffect`** gagne les effets neufs (affûter une rune, monter un `maxLevel`) — le `switch` exhaustif de `cloneCard`, les gabarits à trous, `requires` s'il y a lieu, et le pool `mythic` avec son jet propre (D62).
- **Le boss « XP »** : ×3 XP, ×3 or, plus de carte, une rune tirée dans tout le deck monte d'un niveau — que se passe-t-il si aucune rune n'est sous son `maxLevel`, ou si le deck n'en porte aucune ?
- **Les événements** : deux fichiers neufs (échange de relique, affûtage), bilingues, aux valeurs de spec de D63, que la spec confirme ou remplace — en le disant.
- **La DDA** : 2 × Σ `fusionRank` ; les signatures encore `unique` valent 0 ; le test qui fixe k = 2.
- **La transition E3 → E4** : les signatures-cartes sont exclues de la trouvaille par `unique` (`isOfferableTo`) — un test le garde.
- **La simulation** : le plan aligne le chargeur sur `level_up_rewards/` et relance ; les valeurs de D56 à D63 et D67 doivent se retrouver — c'est le test de non-régression du lot. Un écart arrête le plan et remonte au propriétaire (brainstorm §12, ligne 1).
- **Ce que le joueur voit** : une carte après chaque combat, une main modifiable par relique, deux niveaux par acte, des sources d'affûtage. La note joueur de ce lot est la plus longue.

## Ce que cette spec ne doit pas absorber

- Les reliques de mana, le puits d'or, la survie après l'acte 5, la boucle XP / niveau ennemi, l'échange 3 → 1, l'événement de fusion : **P-16** (D56 ; revue §9). E3 livre la table d'XP mesurée sur le budget d'aujourd'hui, et note que P-16 la recalera.
- Les signatures : **E4**.
- Aucun rééquilibrage de carte ni de relique existante.

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire : E2 vient de fusionner.
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync`. Un compte rendu court : le résultat de la reproduction de la « pioche infinie », les deux parties et leur invariant, où chaque table vit, la liste des fichiers par partie, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.6. E4 — spec : les signatures en compétences de classe

````
# E4 — Spec : les signatures en compétences de classe

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-0X-p43-e4-signatures-competences-de-classe-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md`. **Aucun code, aucune donnée modifiée cette session.** La spec **propose un découpage en deux parties**, chacune avec son plan dans une session suivante, et l'invariant qui justifie l'ordre. Commite la spec sur `main`.

Utilise `superpowers:brainstorming`. La forme est acquise (D49) ; ce qui se conçoit ici, c'est le modèle, le chemin de résolution et la barre au HUD — et une question que le brainstorm laisse implicite (ci-dessous).

## Le chantier

E4 est le dernier lot de **P-43 « Économie unifiée »** (D53) : **les signatures ne sont plus des cartes.** Deux compétences de classe par héros, hors du deck, listées par `HeroData.skills` comme aujourd'hui, avec un coût en mana et un temps de recharge en tours, disponibles dès le premier tour de chaque combat (D41), jouées depuis une barre au HUD, résolues comme une carte puis mises en recharge au lieu d'être défaussées. Ni piochées, ni défaussées, ni offertes, ni clonées. La rareté `unique` et `CardCategory.characterSpecific` disparaissent ; `classes/<id>/cards/` devient `classes/<id>/skills/`. E3 est fusionné : sous D31 les signatures-cartes étaient devenues invisibles dans un deck qui grossit, c'est le motif de D49.

Décisions du lot : **D49**, **D41**, **D53**, **D7** pour la forme (elles évoluent avec le niveau du héros — le modèle d'évolution et son écran sont **C1**, D53 ; E4 leur laisse leur place), **D28** (`magic_missile` devient une Compétence — la Puissance du Mage frappe par `mightTargets`).

## À lire avant de poser la première question

1. Brainstorm — le bloc « Vocabulaire » en tête ; **§4.4** (les deux premiers paragraphes : forme, moteur, à revoir ; l'esquisse `smite.json` pour le champ `evolutions` que C1 remplira ; le point « Stockage » ; le point `magic_missile`) ; §5 (`mana_surge` hors du compte des cartes gratuites : sa recharge est sa limite) ; §6 (`characterSpecific` ne désigne plus rien) ; §11, ligne E4 ; §1, D41, D49, D53, D54.
2. Revue — §2.1 (`baseMaxForgeUpgrades` : vérifie qu'E2 l'a bien retiré des six fichiers) ; annexe A n° 3, 24, 25, 29 ; annexe B.2 (le sort des six signatures).
3. ADR-084 (`skills.json`), ADR-086 (le répertoire porte l'appartenance — les signatures restent sous `classes/<id>/`), ADR-094 (`unique` — à amender), ADR-101 (le draft de départ et `getHeroCards`), ADR-081 (isolation du tutoriel), ADR-100 (l'éditeur : les signatures deviennent-elles une catégorie éditable ?).

## État mesuré le 30/09 — à revérifier, pas à croire

- `hero_data.dart:43` (`skills`, liste d'ids, validée par `referential_integrity_test`) ; `hero_skills_link.dart:6-13` (`getHeroCards` ajoute les deux signatures d'office au deck de départ) ; `starter_deck_draft_screen.dart:57` (5 cartes `global`).
- `game_data_service.dart:76-89` : `EntitySource('classes/*/cards/*.json')` injecte `heroClass` ; `tool/sync_assets.dart` déclare chaque dossier.
- `card_data.dart:7` (`CardCategory { global, characterSpecific }`), `:22-28` (`CardRarity`, `unique`), `:44` (`isAcquirable`), `:136-139` (`isOfferableTo`).
- `deck_controller.dart:158` (`startCombat`) ; `effect_resolver.dart:104-106` (`canPlayCard`) et `resolveCard` ; `combat_state.dart` ; `power_rules.dart` (`mightTargets` lit le type).
- `tutorial_engine.dart:175` lit `hero.skills` comme des cartes ; `tutorial_starter_deck_widget.dart:41` ; `tutorial_fixtures.dart`.
- `save_service.dart` : `RunState`, `DeckState`, `InventoryState` — les signatures vivent aujourd'hui dans le `masterDeck`.
- Le HUD est en Flutter (`lib/ui/widgets/hud/`), la main en Flame (`CardComponent`) : la barre de compétences est un widget, pas un composant.
- Le script de simulation code les six signatures en dur (recharge 2) et lit `classes/*/class.json` pour `statRules`.

## Ce que la spec doit fixer

- **Le modèle** : un `SignatureData` propre (`id`, `cost`, `cooldown`, `type` — lu par `mightTargets` —, `effects`, et la place d'`evolutions` que C1 remplit), ou `CardData` restreint ? Le brainstorm dit « fonctionne comme une carte sans en être une ». Une `SignatureInstance` en run (id, niveau d'évolution plus tard) ; la recharge restante dans l'état de combat, remise à zéro à chaque combat, **jamais sauvegardée**.
- **Le chemin de résolution** : débit du mana, `EffectResolver.resolveCard` sur l'instance, mise en recharge — et **une question que le brainstorm n'écrit pas** : une signature jouée compte-t-elle comme une carte jouée pour les déclencheurs de passif (`onSkillPlayed` de Flux de Mana avec `magic_missile`, `onAttackPlayed` de Soif de Sang avec `reckless_strike`, `onDamagingCardPlayed` de Marque) ? « Résolue comme une carte » penche pour oui ; à trancher avec le propriétaire, et à tester.
- **Les valeurs** : le coût en mana de chaque signature (celui d'aujourd'hui), sa recharge (l'esquisse dit 2 ; *Célérité* la baissera d'un cran en C1, plancher 1) ; `mana_surge` à 0 mana.
- **La donnée** : `classes/<id>/skills/<id>.json`, l'`EntitySource`, `sync_assets`, le retrait de `rarity` et de `category` des six fichiers, `magic_missile` en `type: skill`.
- **Ce qui disparaît** : `CardRarity.unique` et `isAcquirable`, `CardCategory.characterSpecific` — et si `global` reste seule, ce que devient l'enum jusqu'à ce que C1 tranche Q10 (`lot`). ADR-094 et ADR-101 amendés.
- **La barre au HUD** : deux boutons, état (disponible, en recharge avec le compte, mana insuffisant), la même résolution que la main ; l'éclair de la Puissance (P-41 lot B) sur une signature.
- **Le tutoriel** : quelle étape joue une signature, ce que `:175` et `:41` deviennent, les fixtures.
- **Le draft de départ** : 5 cartes, plus de signatures d'office ; le test d'ADR-101 change de garantie.
- **La sauvegarde** : les signatures sortent du `masterDeck` ; `SignatureInstance` dans `RunState` — sans migration (les sauvegardes ne se transfèrent pas avant la `1.0.0`).
- **Le dictionnaire** : un onglet ; **la carte de classe** : les deux signatures lisibles à la sélection.
- **L'éditeur de contenu** (ADR-100) : une catégorie « signatures », ou rien pour ce lot — à trancher, et à dire.
- **Le découpage en deux parties et son invariant.** Proposition : (1) donnée, modèle, moteur, sauvegarde, tests — le jeu ne montre rien de neuf mais tout tient ; (2) HUD, tutoriel, draft de départ, dictionnaire, sélection de classe.
- **La simulation** : le plan vérifie le chemin `class.json` et relance ; mêmes chiffres attendus.
- **Ce que le joueur voit** : deux compétences toujours là, dès le premier tour. Une entrée joueur, et un ADR — c'est un mécanisme nouveau.

## Ce que cette spec ne doit pas absorber

- Le modèle d'évolution, les pools d'évolutions des six signatures et l'écran : **C1** (D53, D19, D21, D54). E4 réserve le champ, rien de plus.
- Toute carte du catalogue, toute rune.
- Un rééquilibrage des six signatures hors le changement de type de `magic_missile`.

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire : E3 vient de fusionner.
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync`. Un compte rendu court : le modèle retenu, la réponse à la question des déclencheurs, les deux parties et leur invariant, la liste des fichiers par partie, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.7. C1 + P-44 lot 1 — spec : la tranche 1 du catalogue et la profondeur

````
# C1 + P-44 lot 1 — Spec : la tranche 1 du catalogue (Rempart, Sang, Arcaniste) et le lot 1 de la profondeur

## Ce que cette session produit

Un **document de design** dans `docs/superpowers/specs/`, nommé `2026-10-XX-p42-tranche-1-et-p44-lot-1-design.md` (ajuste la date), sur le modèle de `2026-09-16-p49-passifs-partages-design.md`. **Aucun code, aucune carte écrite dans `assets/data/` cette session** — la spec fixe les cartes en ordre de grandeur, le plan les écrit. La spec **propose un découpage en trois parties**, chacune avec son plan dans une session suivante, et l'invariant qui justifie l'ordre. Commite la spec sur `main`.

Utilise `superpowers:brainstorming`. C'est la session la plus lourde en design du programme : les décisions structurelles sont acquises, **les cartes ne le sont pas** — ce sont des ordres de grandeur (brainstorm, bloc « Vocabulaire ») — et sept questions de §13 restent à trancher ici. Prends le rôle `game_designer` (`.agents/skills/game_designer.md`) pour l'équilibrage des cartes, et rends chaque arbitrage au propriétaire.

## Le chantier

**P-42 « Catalogue par lots de passif »**, tranche 1, livrée en une seule fois avec **P-44 « Profondeur », lot 1** (brainstorm §11, ligne P-44 : sans `costs.hp` ni `scaleWith`, le lot Sang tombe à deux cartes). P-43 est fusionné en entier : la fusion est le moteur de progression, la trouvaille apporte une carte par combat, les signatures sont des compétences de classe. Le deck ne connaît encore que les 17 neutres ; les trois classes jouent différemment mais ne draftent toujours pas différemment (brainstorm §2). Cette tranche fait exister le deckbuilding : **un lot par classe** — Rempart (Paladin, *Régénération*), Sang (Berserker, *Rage*), Arcaniste (Mage, *Flux de Mana*) — les six autres passifs masqués jusqu'à leur tranche.

Décisions du lot : **D8** (on repart de zéro, ids gardés), **D9** (passifs fixés à leur classe : `PassiveData.classes` vaut exactement une classe, le partage de P-49 est retiré), **D10** et **D15** (forme C : `cards/<passif>/<id>.json`, neutres à la racine), **D16** (5 à 6 cartes par lot), **D17** (aucune neutre bloquée ; une neutre ne porte jamais de coût autre que du mana ; le validateur `costs.armor` dans un lot Berserker → erreur de donnée), **D34** (l'ordre : Rempart, Sang, Arcaniste), **D35** (Vampire — pour mémoire, pas cette tranche), **D45** (`feeds` sur chaque passif et un test de données), **D50** (au plus deux cartes à coût total nul par deck accessible, toutes à épuisement — un test), **D63** (draft de départ : 2 cartes du lot + 3 neutres, valeur de spec, Q9), **D19**, **D21**, **D54** (les évolutions de signature : tous les 5 niveaux, 3 tirées, une choisie, mineures reprenables aux 5, majeures uniques aux 10, *Célérité* majeure), **D12** et **P-44 lot 1** (`scaleWith` sur six sources, multi-coups, statuts proportionnels, coûts combinés), **D38** (`mightRatio` par effet, test Σ `hits` × `mightRatio` ≤ coût + 1), **D40** (PV strictement supérieurs au coût, la rareté ne multiplie jamais `costs`, chaque rune ne rembourse qu'une ressource), **D65** (les runes `piercing`, `lifesteal`, `splash`, `echo`, `transfusion`), **D66**.

## À lire avant de poser la première question

1. Brainstorm — §3 (P1, P2, P3) ; **§6 en entier** (la forme C, ce qu'elle entraîne, les deux questions) ; §7, intro et les lignes **Rempart** (§7.1), **Sang** (§7.2, avec sa note) et **Arcaniste** (§7.3, avec la note de la session 0 : une Compétence multi-coups à écrire) ; **§7.4 en entier** (les quatre leviers, le budget, ce qui est bloqué) ; §8 (les cinq runes de pipeline et leurs `maxLevel`) ; **§9 en entier** (coûts combinés, les trois règles, le budget de Puissance, la table des mécanismes — lignes 1 à 4 sont ce lot) ; **§4.4** (le modèle d'évolution : l'esquisse `smite.json`, les paliers, le repli, l'écran, le prérequis moteur) ; §5 (la règle des cartes gratuites) ; §10, lignes 2 et 3 ; §11, nœuds C1 et P44a ; §12 ; §13, Q6, Q7, Q8, Q9, Q10, Q11.
2. Revue — §5 (le catalogue « pas prêt par construction » — la simulation a tourné depuis) ; §7, idées 2.6 à 2.8 ; §8.1, R3, R6, R8 ; **annexe B en entier** (le sort des 23 cartes, les doublons, les décisions du 29/09) ; §11, S1, S11, S20 ; §12, T6 ; §13, IV9.
3. Rapport — §2.2 (chaque configuration à l'acte 15 : Rempart, Sang, Arcaniste), §3.12 (la Puissance à 0 mana), §5 (« les lots n'existent pas encore : ce sont les exemples du §7 et des cartes génériques »).
4. `docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md`, §2.3 (le script et les sous-dossiers de `cards/`) et §3, O4 et O5.
5. ADR-086 (le répertoire porte l'appartenance), ADR-101 (le prédicat d'offre, à étendre d'une ligne), ADR-096 (P-49 : `classes` sur le passif), ADR-061 (stratégies d'effet), ADR-097 (`mightTargets`), ADR-081 (tutoriel).

## État mesuré le 30/09 — à revérifier, pas à croire

- `game_data_service.dart:76-89` : pas de source `cards/*/*.json` ; le nombre de segments sépare `classes/*/class.json` de `classes/*/skills/*.json`.
- `card_data.dart:136-139` (`isOfferableTo`), `passive_data.dart:105` (`classes`, liste), `passive_availability.dart` (« débloqué vaut tous » — aucun masquage).
- `power_rules.dart:17-32` (bonus par effet et par cible), `strategies.dart:49` (par coup), `:61,69` (`_payLifesteal`, une fois par carte), `:94` (le soin passe par le critique — ne pas implémenter le coût en PV comme un soin négatif, §12), `:147`, `:166-167` ; `effect_resolver.dart:104-106` (`canPlayCard`), `:177-184`, `:204-205`, `:222-228` (le multiplicateur de rareté — jamais sur le terme `scaleWith`, §9.2 #1).
- `damage_pipeline.dart:15-18` (`weakness` × 0,75), `:46-49` (`vulnerable` × 1,5), `turn_phase_manager.dart:107` et `enemy_instance.dart:28-29` (`freeze`) : trois statuts lus en booléens.
- `passive_strategies.dart:85` (*Marque du Mage* pose `vulnerable` en code — à recalibrer quand il devient proportionnel), `:146` (Bénédiction).
- `player_stats_manager.dart:472` (`consumeResource`, le modèle du coût en PV).
- `draft_screen.dart`, `DraftCardReel`, `pendingDrafts` (`_rules/03-10`) : l'écran de montée de niveau, que l'écran d'évolution reprend.
- `tutorial_fixtures.dart:17-19` : `strike_basic`, `defend_basic`, `fireball` — aucun ne bouge dans cette tranche.
- `test/unit/entity_id_convention_test.dart`, `referential_integrity_test` : les modèles des tests de données de D45 et D50.
- Le script de simulation lit `cards/` à plat et code ses lots en dur.

## Ce que la spec doit fixer

- **Le découpage en trois parties et son invariant.** Proposition : (1) **P-44 lot 1, moteur seul, sur les 17 neutres** — `scaleWith`, `hits`, `mightRatio` et son test, statuts proportionnels (et `freezing` qui perd son `maxLevel: 1`), `costs` et ses trois règles, les cinq runes, la recalibration de Marque — rien de visible, tout testé ; (2) **la forme C et les trois lots** — `EntitySource`, `passive` injecté, `isOfferableTo`, `classes` à une, le masquage, le draft de départ, `feeds` et son test, le test des cartes gratuites, les ~15-18 cartes bilingues, `demon_form` déplacé, `focus` supprimée ; (3) **les évolutions et leur écran** — `SignatureEvolutionData`, les pools des six signatures, `SignatureInstance.evolutions`, l'écran, la sauvegarde, le dictionnaire.
- **Les cartes** : 5 à 6 par lot, chacune nourrissant son passif (P2, vérifié par `feeds`), la courbe de coûts du lot, au moins une carte par mécanisme P-44 assigné — Rempart : `scaleWith: armor`, `costs.armor` (*Rempart brisé*, *Percée* à 0 mana) ; Sang : `costs.hp`, `scaleWith: missingHp` (*Sang versé*, *Dernier souffle*), *Transe* qui pose `might_regen` — l'orphelin d'août — et `demon_form` ; Arcaniste : des Compétences de dégâts à 1, l'altération pure, **une Compétence multi-coups** (O4). Les doublons et dominations de l'annexe B sont réglés (D55 est une autre tranche) ; chaque carte porte `_fr` et `_en`, un id `snake_case` égal au nom de fichier.
- **Q10** : une carte de lot est-elle `category: global` + `passive`, ou une valeur `lot` ? **Q8** : les cartes-pont (forme B en complément), oui ou non, combien. **Q9** : le draft de départ (2 + 3, à confirmer). **Q11** : le double bonus de Puissance sur `fireball` + `burning` — hors de cette tranche en pratique (Marque est plus tard), mais la règle se décide avec `mightRatio`. **O5** : le masquage — proposition : un passif dont le dossier `cards/<passif>/` est vide n'est pas disponible, dans `availablePassivesFor`, le point d'accès que P-13 branchera.
- **Les évolutions** (partie 3) : **Q6** — combien de mineures et de majeures par signature (3-4 / 4-5), le repli « majeur tire des mineures » ; **Q7** — deux majeures peuvent-elles se contredire (un champ `excludes`, ou des pools sans conflit) ; les pools des six signatures, bilingues, avec `Célérité` majeure (D54) ; l'applicateur de deltas d'E1 réutilisé en code, données et affichage propres (§4.4, §12 ligne 3) ; l'écran par `pendingDrafts`, un par signature ; la sauvegarde du champ.
- **Les tests** : D38 (budget de Puissance sur tout le catalogue), D45 (`feeds`), D50 (cartes gratuites par classe et par passif), `costs.armor` dans un lot Berserker, `isOfferableTo` avec `passive`, le draft de départ, `EntitySource` refuse un `passive` écrit dans le fichier, l'entité-id sur les sous-dossiers, `sync_assets --check`.
- **La simulation** : le plan fait lire au script les lots réels à la place des lots génériques et relance — **première mesure sur les vraies cartes** ; l'écart avec le rapport §2.2 est une information, pas un test.
- **Ce que le joueur voit** : le deckbuilding existe, trois passifs jouables avec leur lot, les évolutions de signature. La note joueur, et un ou deux ADR (forme C ; évolutions).

## Ce que cette spec ne doit pas absorber

- Les tranches 2 et 3 : Croisé, Sanctifié, Vampire, Carnage, Voile, Marque — et avec elles D30 (Canalisation en banque), D34 (le déclencheur de Marque), D55 (*Prière*). Leur composition est une décision du propriétaire avant la spec C2 (orchestration §3, O3).
- P-44 lots 2 à 4 : malédictions, étourdissement, épines, mots-clés et `retain`, production de cartes, effets interactifs, `CardTarget.none`, `costs.discard`.
- P-16 : aucun rééquilibrage des neutres ni des reliques ; `maxMana` reste 3.
- Le numéro de version : décidé en session 0.

## Méthode

- Re-mesure chaque `fichier:ligne` avant de l'écrire : E4 vient de fusionner, et `card_data.dart` a beaucoup changé depuis `3b8c66f`.
- Les valeurs de cartes sont des ordres de grandeur calés sur 6 dégâts ou 5 armure par mana (brainstorm §7) ; la spec les fixe, le plan les écrit, le playtest les corrige.
- Ne touche ni à `assets/data/patch_notes.json` ni à `pubspec.yaml`.

## En fin de session

Ne lance ni `patch-notes-writer` ni `memory-bank-sync`. Un compte rendu court : les arbitrages pris par le propriétaire (Q6 à Q11, O5), les trois parties et leur invariant, la liste des cartes par lot avec leur coût et leur mécanisme, le volume d'évolutions, et toute prémisse du brainstorm trouvée périmée en la re-mesurant.
````

### 5.8. Les gabarits des autres phases

Les crochets `<…>` sont à remplacer. Les formulations sont celles des sessions de P-41.

#### 5.8.1. Plan

````
Écris le plan d'implémentation de <lot ou partie> avec superpowers:writing-plans, depuis docs/superpowers/specs/<fichier de spec>.md <§ de la partie s'il y a lieu>. Modèle de forme : docs/superpowers/plans/2026-09-16-p49-passifs-partages.md. Cite le code tel qu'il est sur main après la fusion de <la PR précédente> — re-mesure chaque fichier:ligne, jamais de mémoire. Base de tests : <N> sur main, à re-mesurer. Branche : feat/<id>-<sujet>. Contraintes globales : celles du plan de P-49, avec le trailer `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`. <Si la spec découpe en parties : un plan par partie ; n'écris que celui de la partie <n>.> Écris et commite le plan sur main, ne touche à aucun fichier de lib/, assets/ ni test/.
````

#### 5.8.2. Passe de correction du plan

````
Passe de correction du plan docs/superpowers/plans/<fichier>.md, contre la spec docs/superpowers/specs/<fichier>.md <§> et le code de main après la fusion de <la PR précédente>. Ne crée pas de branche, ne touche à aucun fichier de lib/ ni de test/.

Vérifie en priorité, chaque point par une commande, jamais de mémoire :
- ce que le plan croit avoir à faire et qui est déjà fait par un lot précédent — toute tâche qui le réécrit est à supprimer ;
- les chemins et numéros de ligne cités, un par un ;
- le total de tests attendu à chaque tâche, en rejouant mentalement les ajouts ;
- que chaque tâche laisse dart analyze propre et flutter test vert, et qu'aucune n'introduit de code sans lecteur ;
- <le point propre au lot : par exemple, pour E1, « que pools, stackable et la capacité restent lus par la forge du feu et le nœud Forge de Fusion (D68) » ; pour E3, « que la relance de la simulation est une tâche du plan » ; pour C1, « que chaque carte de lot touche une entrée de feeds »>.

Corrige le plan en place, commite sur main, et rends-moi la liste des corrections avec leur motif.
````

#### 5.8.3. Implémentation

````
Exécute le plan docs/superpowers/plans/<fichier>.md avec superpowers:subagent-driven-development. N'utilise pas de worktree : travaille dans le checkout principal, sur la branche que crée sa Task 0. Base de tests : <N> sur main. dart analyze propre après chaque tâche, jamais de dart format, ne jamais commiter les registrants générés, Write/Edit plutôt que heredoc. Commence par la Task 0. <Pour E3 et C1 : la relance de la simulation fait partie du plan ; un écart avec le rapport arrête le lot et remonte.> En fin de plan, ouvre la PR avec un descriptif en français ; ne lance ni patch-notes-writer ni memory-bank-sync avant la fusion.
````

#### 5.8.4. Post-fusion

````
La PR #<n> est fusionnée dans main : <P-43 lot E<k>, partie <p>> — <une ligne sur ce qui est livré>. Lance patch-notes-writer — <juge s'il y a une entrée joueur, une entrée Technique, ou rien ; pour E0 : D37 se voit, D36 est un correctif ; pour E1 : sharp change de formule, rien d'autre de visible ; pour E2 et suivants : une entrée joueur> — sur le numéro <version décidée en session 0>, rouvert en place s'il existe déjà. Puis memory-bank-sync : clore <le lot ou la partie> dans docs/ROADMAP.md §4, mettre à jour activeContext (focus = <la phase suivante>) et progress avec des chiffres re-mesurés (base <N> tests), ouvrir l'ADR que le lot appelle <E0 : un statut par source ; E1 : le moteur de runes data-driven ; E2 : fusion = forge, amendements d'ADR-074 et ADR-094 ; E3 : amendement d'ADR-078 D3 ; E4 : signatures hors du deck, amendements d'ADR-094 et ADR-101 ; C1 : forme C, évolutions>, et corriger les fiches _rules que le lot périme <E1 : 03-8 sur eco ; E2 : 02-3, 02-4, 03-7, 03-8 ; E3 : 01-00 ; E4 : 02-3 sur les signatures>. Rends-moi un compte rendu court : version, tests, ADR, et ce qui mérite d'entrer dans la file.
````

### 5.9. Les lots suivants — gabarits à instancier quand leur amont est fusionné

Ces prompts se dérivent de §5.7 ; ils ne s'écrivent en entier qu'une fois la tranche 1 fusionnée et O3 tranchée, parce que leur contenu dépend de ce que la tranche 1 aura appris.

| Session | Produit | Ce que le prompt doit porter en plus du gabarit de §5.7 |
|:---|:---|:---|
| **C2 — tranche 2** | `p42-tranche-2-design.md` | La composition tranchée (O3 — proposition : Croisé, Vampire, Voile) ; **D30** (Canalisation en banque de mana : `channeling.json` change d'`effectType`, `startTurn` lit la réserve, plafond `maxMana` + Maîtrise) avec Voile ; *Méditation* et le statut `mana_regen` ; les cartes dues à P-44 lot 3 (Voile : `retain`) listées comme **hors tranche** ; le démasquage des trois passifs ; la simulation sur six lots réels |
| **C3 — tranche 3** | `p42-tranche-3-design.md` | Sanctifié (D55 *Prière* et le statut `hp_regen` ; `weakness` — l'orphelin d'août — par pile ; la variante « armure conservée » de D43 si retenue), Carnage (`warcry` déplacé ; *Forge de guerre* due à P-44 lot 3), Marque (**D34**, le déclencheur `onDamagingCardPlayed` ; les quatre élémentaires déplacées — `fireball` garde son id de tutoriel ; Q12 : elles restent des Attaques) ; tous les passifs démasqués ; la première mesure sur les neuf lots |
| **P-44 lot 2** | `p44-lot-2-design.md` | Après **P-05** (`onHitEffect`, `IntentType` qui injecte) : malédictions (`CardType.status`, `addCardToDiscardPile`), étourdissement, épines ; **les cartes dues** aux lots livrés (Rempart : épines) ; la relation avec P-14 |
| **P-44 lot 3** | `p44-lot-3-design.md` | Mots-clés (`retain`, `innate`, `ethereal` : trois règles de fin de tour dans `DeckNotifier`), la rune `retain` (D65), production de cartes (`addCardToHand`, provenance hors `masterDeck`, épuisement de fin de combat) ; **les cartes dues** (Voile : `retain` ; Carnage : *Forge de guerre*) |
| **P-44 lot 4** | `p44-lot-4-design.md` | Effets interactifs (B19 : `EffectStrategy.resolve` synchrone et sans UI — le prérequis architectural), `CardTarget.none` (`power_rules.dart:31`), `costs.discard` ; **un lot d'architecture**, à chiffrer seul |
| **P-16** | pas de spec maintenant | Hérite de la revue §9 et du brainstorm §11, ligne P-16 ; la simulation relancée sur le catalogue complet est son point de départ |

---

*Orchestration. Rien n'est tranché ici. Les décisions sont dans le brainstorm §1 ; sept points de §3 attendent le propriétaire (O8, le commit, est fait), trois en session 0 (O2, O6, O7), deux avant la spec C1 (O4, O5 — dans la spec elle-même), deux avant la spec C2 (O1, O3). Prochaine étape : la session 0, puis la spec de E0.*
