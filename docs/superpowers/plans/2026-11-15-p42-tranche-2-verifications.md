# Vérifications — plan de la tranche 2

**Plan** : [`2026-11-15-p42-tranche-2.md`](2026-11-15-p42-tranche-2.md) · **Spec** : aucune (R31, à l'essai) — la section « Décisions de conception » du plan en tient lieu · **Fiche** : [orchestration §8.6](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) · **Vague** : 6, `0.5.8` · **Base de tests** : 1620 (15/11, `b8e0641b`) · **Tâche à risque** : la banque de mana de Canalisation (D30), Task 2 · **Autonomie** : `continu`.
Tenu par l'orchestrateur (ADR-108 D4) : les options écartées des arbitrages, puis le journal des tours.

## Les arbitrages et leurs options écartées

| # | Question | Classe | Options écartées | Choix (plan, Décisions de conception) | Filtre |
|:---:|:---|:---:|:---|:---|:---:|
| A1 | Où vit la réserve | T | Un champ de `CombatState` (le contrôleur de run lirait le combat) ; un statut caché comme `PassiveCounters` (affiché « Compteur » au panneau, il vieillit) ; un champ d'`EntityStats` (partagé avec les ennemis, sérialisé) | `RunState.manaReserve`, jamais sauvegardé ; vidé par `startCombat` et par le `startTurn` qui le lit | 5, 8 |
| A2 | Le calcul et le plafond | T | Deux calculs, stratégie et interface ; un plafond `maxMana + Maîtrise` écrit en Dart ; le champ `threshold` | Une seule fonction `ManaReserve.preview` ; plafond `maxMana + value`, `value: 0`, Maîtrise +1 par point, en donnée | 4, 6 |
| A3 | Quel mana passe en réserve, et comment il revient | T | Le mana de base seulement (suivre l'origine de chaque point) ; la réserve rendue par `StatGains` (une règle de classe la convertirait une seconde fois) | Tout mana non dépensé ; le tour suivant restaure `maxMana + réserve`, reliques et `mana_regen` par-dessus | 1, 8 |
| A4 | Le passif inactif | T | — | Réserve à 0, interface d'aujourd'hui | 1 |
| A5 | `mana_regen` | T | Un gain hors de `StatGains` ; une icône neuve ; « Surtension » / « Mana Surge » (le nom de la signature `mana_surge`) | Le modèle de `might_regen` ; « Source de Mana » / « Mana Spring » ; l'icône de `gain_mana` | 4, 6 |
| A6 | D44 appliqué à *Méditation* | T | Laisser *Persistant* et *Résonant* (le moteur que D44 interdit) ; un `case` par rune en Dart | `excludesEffects` lit aussi `status:<id>` ; `enduring.json` et `echo.json` excluent `status:mana_regen` | 1, 4 |
| A7 | Compléter Croisé | délégué | Une Compétence d'Armure pure (doublon du Rempart) ; un Pouvoir `armor_regen` (hors `feeds`) ; `mightRatio` 0,5 | *Fléau béni* et *Charge du croisé* ; `mightRatio` 0,75 sur les deux multi-coups | P1, P2 |
| A8 | Compléter Vampire | délégué | *Frénésie sanglante* à 3 ou 2 mana ; un filtre « Attaques seulement » (moteur neuf) ; un multi-coups (D35) | *Traque* ; *Frénésie sanglante* à 1 mana, 3 + 2 par carte jouée avant elle | P2, 7 |
| A9 | Compléter Voile, sa courbe de coûts | délégué | Un Pouvoir `mana_regen` (D11) ; une carte à 0 ; une Compétence à 3 de Gel ou de Brûlure (vague 7) ; un `scaleWith` sur le mana courant (hors périmètre) | *Cataclysme* et *Bouclier d'éther* ; courbe 1, 2, 3, 3, 3 | P1, 7 |
| A10 | `feeds` de Canalisation | T | `["power", "status:mana_regen"]` (les Compétences à 3 échoueraient à D45) ; une forme « coût ≥ 3 » (vocabulaire élargi) | `["power", "skill"]` | 1, 7 |
| A11 | Le démasquage | T | Changer le `displayOrder` pour garder *Flux de Mana* en tête | Les données seules démasquent ; le Mage démarre sur *Canalisation*, comme avant `0.5.7` | 1, 7 |
| A12 | La réserve au tutoriel | T | La simuler | Non : le tutoriel ne simule aucun passif | 7 |
| A13 | Les textes de Canalisation | délégué | — | Plan, Décisions §4 | 6 |
| A14 | L'affichage C et D | P | — | Réponse du propriétaire du 15/11, reprise telle quelle | — |
| A14 bis | Les lectures de C et D | T | « (plafond) » dès le plafond atteint ; masquer la ligne de légende à n = 0 ; monter les cristaux de 14 px (diapositive 6 : au ras du panneau des effets sur téléphone) ; un message sur trois lignes | n = ce qui passera en réserve ; « (plafond) » et « Réserve pleine » strictement au-delà du plafond (diapositive 4) ; la barre descend de 14 px ; message réduit plutôt que sur trois lignes | 6, 8 |
| A15 | *Persistant* sur *Lacération* | T | Bloquer *Persistant* sur les cartes à 0 | Accepté : *Économique* + *Persistant* rend déjà `heal_potion` gratuite et non épuisable ; D50 compte le catalogue, pas les runes | 7 |
| Q8 | Cartes-pont | P | — | Aucune (propriétaire, vague 5) | — |

**Confirmés par l'orchestrateur le 15/11**, dont trois que le joueur verra : A11 (la donnée existante, aucun choix neuf), A6 (D44 appliquée), A8 (cartes déléguées, la source `cardsPlayedThisTurn` est celle de la fiche).

## Le journal des tours

| Tour | Mode | Bloquants / moyens / mineurs / rédaction | Corrigé | Contesté et tranché | Verdict |
|:---:|:---|:---:|:---|:---|:---|
| 1 | complet ; la Task 2 rejouée dans un clone (compile, `+1633` = 1620 + 16 − 3 avec le minimum de la Task 1, cinq mutations rougies) | 0 / 3 / 5 / 3 | Les douze par le rédacteur repris : n° 1, `referential_integrity_test` rouge sous `status:mana_regen` ; n° 2, `channeling.json` livré sans test ; n° 3, la légende du tour ennemi recalculée après *Essence spirituelle* ; n° 5, `audio_catalogue_test` (71 → 86) ; n° 6, l'ordre des paramètres ARB ; n° 7 à 12, lignes, grep, littéral, commentaires, titres, carte des fichiers | **T1.1** — n° 4, rendu « mineur, classe P » par le vérificateur (le Mage du tutoriel sous *Canalisation*, fin de tour à « Mana restant » sans réserve) : **reclassé T par l'orchestrateur**, A12 gardé. Le tutoriel ne simule aucun passif, et en `0.5.6` son Mage démarrait déjà sur *Canalisation* avec ce message : la vague ne change pas le comportement du tutoriel (filtre 7). Option écartée : (b) la fin de tour du tutoriel ajoute la réserve et suit D. Un point de tests manuels, et le §0 du compte rendu le signale | à corriger |
| 2 | différentiel, vérificateur neuf ; les douze corrections justes, décompte refait (1624 · 1638 · 1640 · 1678 · 1678), l'ordre des placeholders recoupé dans `flutter_tools` | 0 / 1 / 0 / 3 | Les quatre par le rédacteur repris : n° 1, la phase de combat ne passe à `enemy` que 600 ms après la fin du tour (`heros_draft_game.dart:371`), « (plafond) » resterait sous la bannière — le prédicat lit aussi `_game.currentPhase` ; n° 2 à 4, une ligne, deux commentaires, un lecteur | **T1.2**, née de la correction du tour 1 — au tour ennemi, `ManaReserve.shown` rend la réserve écrite, `capped: false`, la légende sans « (plafond) » : **confirmée T** (la réponse C vaut pour le tour du joueur ; jugée au point M14). Option écartée : déduire `capped` de `manaReserve == plafond` (« (plafond) » à plafond exact, contre A14) | à corriger |
| 3 | différentiel, vérificateur neuf ; les rebuilds de la phase Flame suivis jusqu'au `setState` (bannière, `game_screen.dart:311-315`, `:474` ; retour, `:266-270`), aucune image intermédiaire | 0 / 0 / 0 / 3 | Les trois de rédaction par l'orchestrateur, au passage : la phrase du Step 5 de la Task 3, la plage de `game_screen.dart` (`:545-623`), celle d'`entity_id_convention_test.dart` (`:72-81`) | — | **prêt** |
