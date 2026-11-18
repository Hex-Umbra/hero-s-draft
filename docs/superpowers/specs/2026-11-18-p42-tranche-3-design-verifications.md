# P-42 tranche 3 — vérifications de la spec

**Spec** : [`2026-11-18-p42-tranche-3-design.md`](2026-11-18-p42-tranche-3-design.md). **Vague 8**, `0.6.0`, branche `feat/v0.6.0-p42-tranche-3`. Tenu par l'orchestrateur (§3.3 du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)) : les options écartées de chaque arbitrage, puis le journal des tours. La spec ne garde que le choix et sa raison.

## 1. Les options écartées

### Réponses du propriétaire, données au lancement (18/11)

| # | Question | Classe | Réponse |
|:---|:---|:---:|:---|
| Q12 | Les élémentaires restent-elles des Attaques | P | Oui |
| D43 | La variante « armure conservée » pour Sanctifié | P | Non, on ne la prend pas |

### Arbitrages T (rédacteur, confirmés par l'orchestrateur le 18/11)

| # | Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---|:---:|
| A1 | Forme du déclencheur de D34 | un filtre dans `MageMarkPassive` sur `onCardPlayed` ; un filtre de déclencheur en donnée sur `PassiveData` | `RelicTrigger.onDamagingCardPlayed`, envoyé par `_afterCardPlayed` après le déclencheur du type | 1, 4, 7 |
| A2 | Ce qu'est une « carte de dégâts » | un champ `dealsDamage` en donnée ; un prédicat sur les seuls effets de la donnée | `EffectiveCard.dealsDamage` : un effet `damage` propre ou ajouté (rune, évolution) | 4, 5 |
| A4 | La cible tuée par la carte qui déclenche | le comportement actuel (le tour consommé sur un mort) | la cible à 0 PV compte comme absente, la carte de dégâts suivante marque | 6 |
| A5 | Les reliques et le libellé du déclencheur | envoyer aussi `applyRelics` ; un libellé en ternaire | pas de reliques (précédent `onDamageTaken`) ; une clé ARB | 7, 5 |
| A6 | `hp_regen` | héros seul ; un soin par `StatGains` ; un soin qui relève un porteur à 0 PV | modèle de `mana_regen`, symétrique héros / ennemi, borné aux PV max, jamais à 0 PV | 4, 6, 8 |
| A7 | L'icône d'`hp_regen` | une icône propre | celle du soin (`favorite_rounded`, `pinkAccent`) | 6 |
| A8 | *Exécution*, « ×2 sous 30 % » | un multiplicateur conditionnel en donnée ; une source neuve en pourcentage | la source livrée `targetMissingHp` | 4, 7 |
| A9 | *Exploitation*, « ×2 si vulnérable » | un multiplicateur conditionnel ; une lecture plafonnée au barème | la source livrée `targetStatus`, +1 par point, somme brute | 4, 6, 7 |
| A10 | Le nom du statut dans le texte anglais de `targetStatus` | laisser le défaut | une clé ARB `statusName` à sélection | 6 |
| A11 | Les `feeds` | `attack` pour *Frénésie* ; une forme `target:allEnemies` | *Frénésie* + `damage` ; *Bénédiction* + `status:hp_regen` ; *Marque* inchangé | 1, 7 |
| A12 | Les six déplacements, le tutoriel | remplacer *Boule de Feu* au tutoriel | `git mv` sans retouche ; le tutoriel ne change pas | 1, 5, 7 |
| A13 | Le démasquage, l'ordre des passifs | — | par la donnée (O5) ; le passif par défaut reste le premier de chaque classe | 1, 7 |
| A18 | Le découpage | plusieurs parties | un seul plan | 7 |

### Arbitrages de l'orchestrateur (18/11), sur les questions que le rédacteur laissait ouvertes

| # | Question | Classe rendue → retenue | Options écartées | Choix | Filtre |
|:---|:---|:---:|:---|:---|:---:|
| D-1 | La durée d'une Faiblesse posée sur un ennemi (vieillie au début de sa phase : N tours réduisent N − 1 attaques) | D → **T** | (a) la Faiblesse vieillit à la fermeture du tour de son porteur — change le tic que D83 garde ; (c) moteur et durées du brainstorm inchangés — *Édit* ne fait rien | (b) moteur inchangé, durées des cartes allongées d'un tour. Toutes les options n'amendent pas une décision : ce n'est pas une question D. Le décalage, antérieur (*Sentence*, `0.5.7`), va à la file | 1, 3 |
| P-1 | Le nom affiché d'`hp_regen` | P → **T** | « Grâce » / « Grace » ; « Régénération » (confusion avec *Régénération d'Armure*) | « Source de Vie » / « Life Spring », par le précédent de la vague 6 (A5 du plan de la tranche 2 : « Source de Mana », nommée dans un arbitrage T) | 6 |
| A3 | Une carte de dégâts de groupe jouée la première du tour | T → **P** | — | **Ouverte** : une règle que le joueur lit dans la description du passif, que D34 ne tranche pas ; recommandation (c) appliquée à titre provisoire | — |

### Les cartes, déléguées (`game_designer`)

Comme aux vagues 5 et 6, les cartes qui complètent les lots et leurs valeurs sont déléguées en ordres de grandeur (brainstorm, en-tête ; D83), le test du propriétaire les corrige. Retenues : Sanctifié — *Sommation*, *Édit*, *Réprimande* (neuve), *Prière*, `metallicize` ; Carnage — *Moulinet* (7 à tous), *Tourbillon*, *Coup de grâce* (10 à tous), *Exécution*, `warcry` ; Marque — `fireball`, `ice_bolt`, `thunder_clap`, `poison_stab`, *Exploitation*, *Salve*. Écarts au brainstorm, à signaler au propriétaire : *Exploitation* et *Salve* en Compétences (D34 et R6 : sans quoi la Puissance du Mage ne toucherait aucun dégât du lot) ; *Moulinet* et *Coup de grâce* relevés de 1.

## 2. Le journal des tours

| Tour | Mode | Bloquants / moyens / mineurs / rédaction | Corrigé | Contesté et tranché |
|:---:|:---|:---:|:---|:---|
| 1 | complet | 0 / 0 / 6 / 3 | Les neuf, au passage, par le rédacteur repris avec son contexte : *Nova* et `splash` sous chaque option d'A3 ; A8, A9 et *Salve* étiquetées « délégué pour la règle de la carte », leurs écarts au brainstorm dits ; la Faiblesse affichée au-delà de son plafond portée à la file avec Vulnérable ; un test de données sur l'accord des trois exemplaires des noms de statut ; trois citations | **n° 1, A4 reclassée P** par l'orchestrateur (règle du doute : la même phrase du passif qu'A3), groupée avec A3 ; n° 4 et n° 8, rendus P par le vérificateur, gardés délégué et file : des règles de carte, déléguées, et un affichage antérieur au lot. Aucun bloquant ni moyen : la spec a convergé, il ne reste que les questions P |

## 3. Pour le Review Focus du plan (tour 1)

- Tests rouges que la spec ne nomme pas : `card_rule_texts_test.dart:33-36` (« Vulnérable » dans les deux langues, que A10 corrige) ; `passives_mage_test.dart:56-62` et `:558` (`onAttackPlayed`) ; `tutorial_fixtures_test.dart:134` (15 neutres → 9) ; `real_bundle_load_test.dart:26`, `:199` (titres) ; les `reason` d'`entity_id_convention_test.dart:73-81` et d'`audio_catalogue_test.dart:54`.
- Code sans lecteur : `openedPassives` de `tutorial_engine_test.dart:235-247` et `tutorial_test_registry.dart:25-40`, inutile une fois les neuf passifs ouverts.
- Assets de test périmés : `build/unit_test_assets` garde les six cartes à leur ancien chemin, et le chargeur refuse un id déclaré deux fois (`game_data_loader.dart:128-131`) — les `git mv` et `sync_assets` dans la même tâche, puis `rm -r build/unit_test_assets`.
- Boutique : `shop_controller_test.dart:355`, `:487`, `:558` passent par `shippedNeutralCards()`, qui rendra 9 cartes — `checked > 0` à vérifier.
- `card_catalog_test.dart:18-32` : le tuple ne porte pas `scaleWith.statusId`, le `vulnerable` d'*Exploitation* n'y serait pas vérifié.
- `forge_upgrades_catalog_test.dart:258` : *Prière* recevra *Résonant* (`echo.json` et `enduring.json` n'excluent que `status:mana_regen`) — à confirmer voulu.
- Cas de test à écrire : A4 sous l'option retenue ; *Nova* sous l'option retenue d'A3 ; Q11 sur *Réprimande*.
- `hp_regen` côté ennemi : le soin après le tic dans `processEnemyStatuses`, où tic et déclin sont une seule expression (`status_effect_processor.dart:141`).
- Le commentaire de classe `passive_strategies.dart:51` (« la première Attaque ») à réécrire.
- Tests à mettre à jour : `feeds` attendus (`referential_integrity_test.dart:394-411`) ; les trois tests de disponibilité (`passives_paladin_test.dart:207-214`, `passives_berserker_test.dart:249-256`, `passives_mage_test.dart:508-515`).
