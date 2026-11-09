---
description: P-44 lot 1, the card depth engine — cards may cost HP or Block on top of mana under one affordability rule and one debit, an effect may grow with a source (scaleWith, six sources, floored), hit several times with a per-effect Might ratio, Vulnerable, Weakness and Freeze count points on a single scale, only the first status of a resolution gets the Might bonus, and five pipeline runes join the fusion (Piercing, Vampiric, Ricocheting, Echoing, Transfusion)
---

# ADR-111 — La Profondeur, Lot 1 : Coûts Combinés, Croissance, Multi-coups, Statuts Proportionnels et Cinq Runes de Mécanisme

### Statut

✅ Accepté — 2026-11-04 (P-44, **lot 1**, livré avec la tranche 1 de P-42 ; brainstorm v3, décisions
D4, D12, D18, D33, D35, D38, D40, D44, D63, D65, D66 ; réponses du propriétaire P-1 et P-3 du
2026-11-03, Q11). **Livré sur la branche `feat/v0.5.7-p42-tranche-1-p44-lot-1` — vague 5 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Partie 1 de la vague : code
`d04ef990`..`70dc230a` sur le plan `54425f00` ; rendu des coûts et des coups en partie 2
(`ebb739cd`, `bb74d2fa`, `a6c56ba4`). **Clôt P-44 lot 1** dans `docs/ROADMAP.md`. **Complète**
[ADR-105](ADR-105-moteur-de-runes-data-driven.md) (cinq sortes de delta, deux champs d'éligibilité)
et [ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md) (la Puissance par coup). Conception :
[spec](../../docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §3.1, §3.6, §4.1
à §4.7 — ses arbitrages A6 à A23 et leurs motifs ne se recopient pas ici.

### Contexte

Jusqu'à `0.5.6`, une carte ne coûtait que du mana, ne frappait qu'une fois, posait des statuts tout
ou rien (Vulnérable +50 %, Faiblesse −25 %, Gel −50 %) et ne grandissait avec rien. Les lots de
P-42 ont besoin de mécanismes que deux cartes au moins exploitent chacun : sans `costs.hp` ni
`scaleWith`, le lot Sang tombait à deux cartes (brainstorm §11). Les runes, elles, ne savaient que
monter un chiffre, ajouter un effet, baisser un coût ou toucher l'épuisement.

### Décision

**D1 — Les coûts combinés, une règle et un débit** (D40, A9, A10). Une carte déclare `cost` ou
`costs` (`mana` ≥ 0, `hp` et `armor` ≥ 1, au moins l'un des deux ; toute autre clé refusée). Une
seule règle d'accessibilité, `CostRules.canPay` : le mana courant, des PV **strictement**
supérieurs au coût en PV — une carte ne tue jamais son porteur —, une Armure au moins égale au coût.
Un seul débit, `consumeResource({mana, hp, armor})`, en une écriture d'état : ni dégâts, ni
absorption, ni critique, ni `onDamageTaken`. Une neutre ne coûte que du mana (D17).

**D2 — `scaleWith`, la croissance** (A11, A12). Un effet grandit d'un terme `floor(ratio × source)`,
lu au moment de l'effet : `armor`, `missingHp`, `cardsPlayedThisTurn`, `enemiesAlive`,
`targetStatus`, `targetMissingHp` (les deux dernières sur une cible unique seulement). La rareté ne
multiplie jamais le terme ; ni la pioche ni le mana rendu ne grandissent (G2).

**D3 — Multi-coups et `mightRatio`** (D38, A13, A14). `hits` ≥ 1 et `mightRatio` ∈ ]0, 1] sur un
effet de dégâts ; la Puissance ajoutée par coup vaut `floor(bonus × mightRatio)`. Chaque coup passe
le pipeline, son critique et son Électrocution ; le vol de vie se paie une fois, après les coups.
Garde de donnée : Σ `hits` × `mightRatio` ≤ coût en mana + 1.

**D4 — Les statuts proportionnels, un barème en un seul endroit** (P-1 (a)). Vulnérable +25 % de
dégâts subis par point, 4 points au plus ; Faiblesse −25 % infligés par point, 2 au plus ; Gel
−25 % à l'attaque par point, 3 au plus. `ProportionalStatus` porte les trois constantes, que lisent
le pipeline, l'intention effective et tous les textes. Recalibrés pour garder leur premier effet :
*Trait de Glace* (Gel 2), `freezing` (2 points par niveau, sans plafond), *Marque du Mage*
(Vulnérable 2).

**D5 — Un seul bonus de Puissance de statut par résolution** (Q11, A15). Le premier `apply_status`
de la résolution le reçoit, tous statuts confondus ; un écho, seconde résolution, a le sien (C1.1).

**D6 — Cinq runes de mécanisme** (D4, D18, D65), chacune une sorte de `CardDelta` :
*Perforant* (`armorPierce`, 25 % de l'Armure ignorée par niveau), *Vampirique*
(`lifestealPercent`, 20 % des dégâts infligés), *Ricochant* (`splashPercent`, 25 % de chaque coup
aux autres ennemis, `eligibleTargets: [singleEnemy]`), *Résonant* (`echoChance`, 15 % de rejouer
la résolution) et *Transfusion* (`refundHpCost`, 50 % du coût en PV, `requiresCost: "hp"`). Au
poids 50, au rang 1 (D63). **L'écho ne déclenche aucun événement « carte jouée »** (P-3 (a)) : ni
passif, ni relique, ni compteur ne le voient.

**D7 — L'ordre d'un jeu de carte** : l'accessibilité, puis le paiement, puis les effets, l'écho,
le remboursement de *Transfusion*. Une carte refusée ne paie rien ; une carte payée se résout
jusqu'au bout.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| La règle des coûts | `lib/game/systems/cost_rules.dart` (`canPay`, `missingFor`) ; `PlayerStatsManager.consumeResource` |
| La forme de la carte, `ScaleWith`, `ScaleSource` | `lib/models/data/card_data.dart` |
| Le terme, l'écho, le remboursement | `lib/game/services/effect_resolver.dart` (`scaleTerm`, `resolveCard`, `Random` injectable) |
| Coups, éclaboussure, vol de vie, Perforant | `lib/game/services/effects/strategies.dart` ; `EntityStats.takeDamage(armorPiercePercent:)` |
| Le barème | `lib/game/services/proportional_status.dart` ; `lib/game/services/damage_pipeline.dart` ; `enemy_instance.dart` (Gel) |
| Les cinq sortes de delta, leurs lectures | `lib/models/data/card_delta.dart` ; `lib/models/effective_card.dart` ; `ForgeUpgradeData.eligibleTargets`, `.requiresCost` |
| Les cinq runes | `assets/data/forge_upgrades/{piercing,lifesteal,splash,echo,transfusion}.json` |
| Médaillons PV et Armure, `valeur×coups`, ligne de croissance | `lib/ui/widgets/ui_card/card_cost_medallion.dart`, `ui_card_helpers.dart` ; `card_component.dart`, `card_text_renderer.dart` |

Règles de jeu : [`_rules/03-14`](../_rules/03-14-couts-combines-croissance-et-multi-coups.md),
[`_rules/04-00`](../_rules/04-00-alterations-d-etat-statuts.md) §4.1,
[`_rules/03-8`](../_rules/03-8-systeme-de-forge-forge-de-fusion.md) §3.8.2.

### Conséquences

- **Seules `armor` et `missingHp` ont une carte** (Rempart, Sang) : les quatre autres sources sont
  prouvées par des tests unitaires, pour les lots des tranches 2 et 3.
- **Les gardes de D38 restent vides** tant qu'une seule carte porte `hits` (*Rafale d'étincelles*) ;
  `takeDamage` n'a pas de test direct (compte rendu §4).
- **`ProportionalStatus` vit sous `lib/game/services/`** et `enemy_instance.dart` l'importe : la
  couche données dépend d'un service — laissé à la file (compte rendu §4).
- **Le barème est celui des vagues 5 et 6** : les charges élémentaires relisent le Gel, le Feu et la
  Foudre en vague 7 ([ADR-110](ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)).
- **Une sauvegarde antérieure** dont un deck porte une carte retirée la perd, nommée au chargement
  (`MissingSaveItem`) — la règle avant la `1.0.0`.
