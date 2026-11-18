# P-42 tranche 3 — vérifications du plan

**Plan** : [`2026-11-18-p42-tranche-3.md`](2026-11-18-p42-tranche-3.md), depuis la [spec](../specs/2026-11-18-p42-tranche-3-design.md) entière (un seul plan, §10). **Vague 8**, `0.6.0`, branche `feat/v0.6.0-p42-tranche-3`. Base de tests : **1776** (`6788bfd5`) ; total attendu par le rédacteur : **1826**. Tâches à risque : aucune. Autonomie : `continu` (levée du 18/11). Modèle de forme : le plan de la partie 1 de P-53. Tenu par l'orchestrateur (§3.4 du [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)) : les options écartées, puis le journal des tours.

## 1. Les options écartées

### Arbitrages T (rédacteur, confirmés par l'orchestrateur le 18/11)

| # | Question | Options écartées | Choix | Filtre |
|:---|:---|:---|:---|:---:|
| D1 | Où tester « une signature de dégâts » déclenche le passif | un appareil de signature dans `passive_triggers_test` (le fichier n'a ni registre ni signature) | le test renversé de `combat_signature_test.dart:290` | 8 |
| D2 | Où tester `EffectiveCard.dealsDamage` | `passive_triggers_test` | `effective_card_test`, à côté du modèle | 5 |
| D3 | Déplacements et cartes neuves | deux tâches (les comptes s'écriraient deux fois) | une seule tâche, Task 5 | 8 |
| D4 | Vérifier `scaleWith.statusId` dans `card_catalog_test` | un test à part | un neuvième champ du tuple, `scaleStatus` | 8 |
| D5 | Où garder « `mage_mark` sur `onDamagingCardPlayed` » | aussi dans `real_bundle_load_test` | `passives_mage_test`, qui lit déjà le vrai bundle | 8 |
| D6 | La couleur du libellé du déclencheur neuf (aucun joueur ne la voit) | une autre couleur | `Colors.redAccent`, celle d'`onAttackPlayed` | 8 |
| D7 | Où se place le soin de `hp_regen` | — | ennemi : la ligne `:141` découpée en tic, soin, déclin ; héros : après le Mana, avant le déclin | 8 |
| D8 | `buildTutorialTestRegistry` | le supprimer | le garder, sans `openedPassives` | 8 |
| D9 | `_statusName` | garder le repli par `createStatus` | `charge ?? l10n.statusName(id)`, le cas `other` rendant l'id | 5 |

### Arbitrage de l'orchestrateur, sur une question rendue P par le rédacteur

| # | Question | Classe rendue → retenue | Options écartées | Choix | Filtre |
|:---|:---|:---:|:---|:---|:---:|
| D10 (Q-P1 du rédacteur) | *Prière* reçoit-elle *Résonant* ? | P → **T** | (b) `echo.json` exclut aussi `status:hp_regen` | (a) oui. L'exclusion de `status:mana_regen` vient de D44 (« une carte qui rend du mana ou pioche sans s'épuiser est un moteur infini », A6 du plan de la tranche 2) ; `hp_regen` ne rend ni mana ni pioche, et `heal_potion`, le soin d'aujourd'hui, reçoit déjà *Résonant*. C'est la règle acquise appliquée à une carte neuve, sans rune touchée, pas une question neuve. *Persistant*, qui exige `isExhaust` (`forge_rune_rules.dart:94`), ne s'offre à aucun Pouvoir : *Prière* ne le reçoit pas (constat 5 du tour 1) | 1, 4 |

## 2. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté et tranché |
|:---:|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet | 0 | 1 | 3 | 2 | à corriger — base 1776 et total 1826 confirmés (les +20 de la matrice des runes, aucun autre test généré par carte), toutes les références exactes, rien de déjà fait, chaque trou du §3 de la spec confié à une tâche, fiche 8.8 tenue. Constats confiés au rédacteur repris avec son contexte, tous corrigés : (1) **moyen**, Task 6 — le test de *Sommation* rouge tel que décrit (ennemi à `might` 0, intention nulle) et une consigne qui aurait fait retoucher `summons.json` : l'ennemi à `might` = `baseDamage`, la consigne bornée aux tests 1 à 9 ; (2) Task 2 — les vrais rouges du Step 2 nommés ; (3) Task 5 — les deux listes de `card_catalog_test.dart:245-265` ; (4) D8 — deux appels restants ; (5) D10 — *Persistant* ne s'offre à aucun Pouvoir ; (6) Task 7 — « par un commit de correction » | Aucun contesté ; Q-P1 du rédacteur reclassée T par l'orchestrateur avant le tour (D10, §1) |
| 2 | différentiel | 0 | 0 | 0 | 0 | **prêt** — les six corrections du tour 1 confirmées une à une ; `[6, 6, 8]` recalculé sur le code (intention à 8 par `might` = `baseDamage`, Faiblesse 1 pendant 3 tours vieillie avant chaque intention, (8 × 75 / 100) arrondi à 6) et l'appareil constructible avec les aides existantes ; les trois rouges du Step 2 de Task 2 confirmés ; total 1826 | — |
