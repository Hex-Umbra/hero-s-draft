# P-53, les charges élémentaires — vérifications de la spec

**Spec** : [`2026-11-15-p53-charges-elementaires-design.md`](2026-11-15-p53-charges-elementaires-design.md). **Vague 7**, `0.5.9`, branche `feat/v0.5.9-p53-charges-elementaires`. Tenu par l'orchestrateur (§3.3 du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)) : les options écartées de chaque arbitrage, puis le journal des tours. La spec ne garde que le choix et sa raison.

## 1. Les options écartées

### Arbitrages T (rédacteur, confirmés par l'orchestrateur le 15/11)

| # | Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---|:---:|
| A1 | Où vit une charge | un document plat `charges.json` | `assets/data/charges/<id>.json`, l'id est celui du statut, injecté | 5 |
| A2 | Le modèle et l'accès au catalogue | `GameDataRegistry.instance` ; un provider qui lève sans registre | `ChargeData` + `ChargeRupture` ; `registry.charges` vide par défaut ; `chargeCatalogProvider` rend un catalogue vide sans registre | 5 |
| A3 | La validation au chargement | un refus « seuil de Feu < 3 » écrit en dur | règle générale : une rupture `explode` refusée si seuil ≤ 2 × `chargePerNeighbour` ; `skipAction` refusé comme rupture du héros | 1 |
| A4 | Le chemin de pose | garder les cas `burn`, `freeze`, `shock` dans `createStatus` | une fonction pure `ChargeRules.pose` ; `createStatus` perd ses trois cas | 5 |
| A5 | Seuil courant, ruptures, état de rupture | des statuts aux ids réservés ; une table dans `CombatState` | une piste `ChargeTrack` sur `EntityStats`, non sérialisée | 5 |
| A6 | Le tic et les charges | ids en dur dans `tickStatuses` | `tickStatuses` reçoit les ids du catalogue ; `tickEnemyStatuses`, sans appelant, disparaît | 4 |
| A7 | Les durées des effets qui posent une charge | les retirer des données ; `durationPerLevel` facultatif | gardées, ni lues ni affichées | 7, 8 |
| A8 | Le seuil par porteur | calculé dans l'affichage | selon le porteur + montée × ruptures, écrit sur la piste | 1 |
| A9 | Durée des ruptures | une durée en donnée | portée par la sorte de rupture ; deux fermetures de phase | 1 |
| A10 | L'ordre au tour du porteur | Poison puis Feu, avec ou sans « vivant au début » | le Feu, puis les autres statuts, puis `cleanDeadEnemies` | 1 |
| A11 | Une vague de la chaîne | résolution séquentielle dans la vague | vague simultanée sur un instantané | 1 |
| A12 | Lisibilité de la chaîne | chaîne calculée d'un bloc puis rejouée par Flame | `resolveNextFireWave()` → bool, `resolveEnemyStatuses()`, un compte rendu de vague dans `CombatState` | 5, 6 |
| A13 | L'ennemi gelé avant l'animation | `effectiveIntent` à null | un accesseur sur `EnemyInstance`, lu par Flame et par `resolveEnemyIntent` | 5 |
| A14 | Le pipeline | un seul passage avec la Faiblesse | catalogue en paramètre ; `weakenDealt` après la Faiblesse ; `amplifyHits` à la place de l'Électrocution | 1, 5 |
| A15 | L'arrondi sous le seuil | vers le bas | demie vers le haut, en entiers | 8 |
| A16 | Les textes | clés ARB par élément | dans le fichier de la charge, avec jetons ; clés ARB génériques | 5 |
| A17 | L'éditeur | pas de catégorie | `EntityCategory.charge` | 5 |
| A18 | Le test de l'exemple 48/64/48 | lié aux fichiers livrés | construit aux valeurs de l'exemple ; un test de données fixe les valeurs livrées | 8 |
| A19 | Le découpage | la forme de la fiche (textes et tutoriel en partie 2) | deux parties, les textes avec le moteur | 7, 8 |

### Questions P ouvertes (§1.4 de la spec), appliquées « (provisoire) »

| # | Question | Options | Recommandation |
|:---|:---|:---|:---|
| P-a | Les noms affichés | (a) Gel/Feu/Foudre, Freeze/Fire/Lightning ; (b) rien ne change ; (c) Gel/Feu/Foudre, Freeze/Burn/Shock | (c) |
| P-b | Les valeurs des contenus relus | (a) *Embrasement* 4 → 3 Feu, *Congelant* 2 → 1 Gel par niveau, le reste inchangé ; (b) tout garder | (a) |
| P-c | La forme des trois animations | G-a/b/c, F-a/b/c, L-a/b/c | G-a, F-a, L-a |
| P-d | Ce qui protège du Feu | (a) l'Armure absorbe, sans Vulnérable ; (b) par le pipeline ; (c) l'Armure ne protège pas | (a) |
| P-e | Une entrée de debug « Charges » | (a) une section de l'onglet Combat ; (b) rien | (a) |

## 2. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté et tranché |
|:---:|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet | 0 | 2 | 8 | 2 | à corriger — les douze constats confiés au rédacteur repris avec son contexte : (1) six appels de tests qui attendent l'ancien contrat de `startEnemyTurn` ; (2) tests rouges non listés — textes des runes, intention réduite par le Gel, contenus joués sans catalogue ; (3) la sorte de rupture absente de la piste, le chemin du catalogue jusqu'à Flame ; (4) la forme de l'entrée de statut d'une charge ; (5) `_statusName` de `card_rule_texts.dart` ; (6) « deux fois plus » → le bonus par point double ; (7) M2, M6, M8 injouables tels qu'écrits ; (8) §2.1, seul le Gel suivait P-1 ; (9) `{belowPercent}` sans lecteur ; (10) arbitrages hors fiche A3, A7, A10, A11, A15, signalés, déjà consignés ; (11) citation de D33 ; (12) bornes, « (provisoire) » dans le tutoriel | Aucun constat contesté. Le constat 10 ne demande rien. La liste « Pour le Review Focus du plan » est gardée pour le rédacteur du plan |
| 2 | différentiel | 0 | 1 | 5 | 1 | à corriger — les onze corrections du tour 1 confirmées (5, 10, 14 et 27 recalculés ; appelants complets ; le chemin du catalogue conforme aux trois couches, précédent `notification_overlay.dart:93-96`). Constats confiés au correcteur : (1) **moyen**, le second chemin de mise à jour des indicateurs d'`EnemyCard`, différé après l'animation (`enemy_card.dart:217-246`) ; (2) appelants de test aux signatures qui changent (`tickStatuses`, `CardRuleTexts.scale`, constructeur de `HerosDraftGame`) ; (3) les pistes du héros n'atteignent pas son panneau ; (4) `referential_integrity_test.dart:199-216` et `effect_icons.json` ; (5) M8 sans héros nommé ; (6) trois ennemis à l'acte 3 n'est qu'un plafond ; (7) colonne « Fichier » de la ligne Poison | Aucun constat contesté. Trois précisions T de la correction 1 confirmées par l'orchestrateur : le chemin du catalogue (filtre 5), la durée fixe 1 de l'entrée (filtre 8), la rupture copiée sur la piste (filtre 5) |
| 3 | différentiel | 0 | 1 | 3 | 1 | **non convergée** — les sept corrections du tour 2 et le point M8 des PV (tranché T par l'orchestrateur, filtre 8) ; six sur sept confirmées. Restent les constats de §3 ci-dessous, tous de classe T, non corrigés : l'autonomie est `strict`, un moyen après le troisième tour arrête la vague (§3.3.4, §6) | Aucun constat contesté |

## 3. Les constats ouverts après le tour 3, et ce que l'orchestrateur recommande

Tous de classe T ; aucun n'amende une décision acquise ni ne change une valeur mesurée. Recommandation : les corriger tels que le vérificateur les propose, par le correcteur, puis un **quatrième tour, différentiel, par un vérificateur neuf, centré sur ces cinq corrections** ; la suite du cycle seulement s'il rend « prête ».

| # | Où | Constat | Preuve | Gravité | Correction recommandée |
|:---:|:---|:---|:---|:---:|:---|
| 1 | §9.1 M8 | En combat, `DebugActions.addCard` n'ajoute la carte qu'au deck maître, ni à la main ni à la pioche : la pioche n'est tirée du deck maître qu'au début du combat. M8, tel qu'écrit, ne se joue pas au premier tour du combat en cours | `debug_actions.dart:127-130` ; `deck_controller.dart:159-172`, `:219-235`, `:284-286` | moyen | « Avant le combat, sur la carte » : ajouter les deux cartes par l'onglet Deck (au deck maître, mélangé en pioche au début du combat) et retirer les autres (`removeCard`) pour que la main d'ouverture les contienne ; le reste de M8 inchangé |
| 2 | §9, ligne « Intégrité » | Deux autres tests du même fichier rougissent quand `createStatus` perd ses trois cas : `referential_integrity_test.dart:265-294` (assertion `:285-288`, *Braise* pose `burn`) et `:346-361` (assertion `:356`, les trois runes) | `magic_missile.json:68` | mineur | Les citer avec la même règle : « créé par `createStatus` ou charge du catalogue » |
| 3 | §5.1, « Les lignes d'affichage » | Lu à la lettre, les lignes du héros partent aussi au panneau des intentions, où personne ne les lit ; A2 donne le catalogue aux deux panneaux et les lignes au seul panneau du héros | `combat_side_panels.dart:95` ; spec A2 | mineur | « … le catalogue, que `CombatSidePanels` transmet aux deux panneaux ; les lignes, au seul `StatusEffectsPanel`. Le panneau des intentions lit l'accesseur d'A13 et le nom de l'état dans le catalogue » |
| 4 | §9.1 introduction et M6 | « Passer encore d'acte » mène à l'acte 4, plafond de quatre ennemis : sur quatre, la chaîne de M6 change (D prend 12, 1 Feu, puis 2) | `encounter_system.dart:66-71` ; spec §4.7 | mineur | « M6 veut exactement trois ennemis : s'il y en a quatre, jouer un autre combat » ; le renvoi d'acte reste pour M5 |
| 5 | §9.1 introduction | La plage `:274-289` commence en `:275` | `encounter_system.dart:275-289` | rédaction | `:275-289` |

## 4. Pour le Review Focus du plan

Rassemblé des trois tours, pour le rédacteur du plan : `chargeCatalogProvider` déterministe en test (`valueOrNull`, jamais `requireValue` ; une surcharge de test commune ; `might_orientation_test.dart` construit son registre par `shippedRuneRegistry`, il faut une aide sœur dans `shipped_data.dart`) ; la piste survit à `takeDamage`, `addStatus`, `tickStatuses` et à tout `copyWith`, et `toJson` ne l'écrit pas ; les appels qui ne compileront plus (§9, « Signatures qui changent ») et la place du helper « début de phase ennemie complet », qui sert trois fichiers dont `test/encounter_system_test.dart` ; un porteur que son Poison achève à son tour explose quand même (A10) ; un gel du héros en attente survit à la fermeture du tour du joueur ; −50 % sur l'éclaboussure de *Ricochant* ; un ennemi gelé sans intention consomme son gel (A13) ; tous les ennemis d'un combat de boss au seuil 6, une élite à 3 ; *Rafale d'étincelles* 12 et 27 en toutes lettres ; la Puissance avant le plafond du Gel ; `rune_resolution_test` aux PV `[95, 85, 71]` et Foudre `(6, null)` ; `CardRuleTexts.scale` sur une charge en `targetStatus` dit le nom, jamais l'id ; `DebugActions.skipEnemyPhase` saute les fermetures de phase — à trancher ou à documenter ; `StatusIndicator` : une charge dessinée une fois, par sa ligne ; son constructeur dans `EnemyCard.onLoad` (`enemy_card.dart:139-150`) ; une égalité de valeur de la ligne, testée dans `charge_rules_test.dart` ; les bouchons des deux rappels neufs de `HerosDraftGame` dans `flame_image_prefix_test.dart` et `heros_draft_game_targeting_test.dart` ; `buildDetailedDescription` lu avec `listen: false`, sous `UncontrolledProviderScope` pour les tests d'écran existants ; M8 corrigé recopié dans le fichier de tests manuels.
