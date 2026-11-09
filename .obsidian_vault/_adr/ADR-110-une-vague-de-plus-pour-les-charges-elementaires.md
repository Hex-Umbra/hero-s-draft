---
description: Amends ADR-102 on the programme's scope and wave count — the programme gains a wave, wave 7 delivers the elemental charges (P-53) and the third tranche of P-42 becomes wave 8, still the 0.6.0 version; the charges' rules are not decided by this ADR and must become numbered decisions before wave 7 opens
---

# ADR-110 — Une Vague de Plus : les Charges Élémentaires en Vague 7, la Tranche 3 en Vague 8

### Statut

✅ Accepté — 2026-11-03, par le propriétaire (brainstorm v3, décision **D76**), pendant l'arrêt de
la vague 5 sur la question P-1 de sa spec. **Décision de méthode et de périmètre, sans code** :
`lib/`, `test/` et `assets/` ne changent pas par elle. **Amende
[ADR-102](ADR-102-chantier-par-vagues-une-version-par-vague.md)** sur D1 (le nombre de vagues, dont
la table vit dans le fichier d'orchestration) et D7 (le périmètre gagne P-53) ; ADR-102 ne change
que de Statut. Consignée dans la vague 5, sur sa branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`, par
la passe `memory-bank-sync` de fin de vague.

### Contexte

La spec de la vague 5 devait fixer le barème des statuts proportionnels de P-44 lot 1. La question
P-1 a fait voir au propriétaire que **le Gel et la Faiblesse font la même chose** — tous deux
réduisent ce que l'ennemi inflige —, et que Brûlure et Poison sont deux dégâts sur la durée. Une
[étude](../../docs/possible_upgrades/03-11-2026_charges_elementaires_Opus5.md), écrite hors de la
vague (`cc0f012a`), propose que le Gel, le Feu et la Foudre s'accumulent jusqu'à un seuil qui les fait
rompre, chacun à sa manière, dans un cadre commun en donnée, symétrique héros / ennemis.

Le lot *Marque*, prévu dans la tranche 3, rassemble les quatre cartes élémentaires du Mage. Écrites
avant les charges, elles seraient à réécrire une fois les charges livrées.

### Décision

**D1 — Le chantier gagne une vague.** **La vague 7 livre `0.5.9` : les charges élémentaires**
(P-53 de `docs/ROADMAP.md`). **La tranche 3 de P-42 devient la vague 8, toujours `0.6.0`** ; la
session de clôture (brainstorm D74) suit la vague 8. La table des vagues, leurs branches et leur
état restent au fichier d'orchestration, §1 et §2 (ADR-102 D1, D6).

**D2 — Le périmètre du chantier gagne P-53** (amende ADR-102 D7). Restent dehors, après `0.6.0` :
les lots 2 à 4 de P-44 et P-16.

**D3 — Les règles des charges ne sont pas acquises par D76.** L'étude porte les orientations du
propriétaire et ses questions ouvertes ; elles deviennent des décisions numérotées du brainstorm,
avec son accord, dans une session de documentation **avant** la vague 7. Tant que la fiche 8.7 du
fichier d'orchestration porte sa note « à compléter », la porte d'entrée de la vague 7 ne passe pas.

**D4 — Le barème de P-1 est celui de la vague 5 et de la vague 6.** Gel, Brûlure et Électrocution y
suivent les statuts proportionnels ([`_rules/04-00`](../_rules/04-00-alterations-d-etat-statuts.md)) ;
les cartes et les runes qui les posent sont relues en vague 7.

### Preuves dans le code

Aucun code : la décision porte sur l'ordre et le périmètre du chantier.

| Élément | Emplacement |
|:---|:---|
| La décision du propriétaire | [brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1, D76 — qui amende D69 |
| La vague 7, la vague 8, la clôture ; la fiche 8.7 à compléter | [fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §1, §2, §7.2, §8.7, §8.8 ; commit `f0064bfe` |
| L'étude des charges | `docs/possible_upgrades/03-11-2026_charges_elementaires_Opus5.md` |
| La ligne du chantier | `docs/ROADMAP.md`, §4, P-53 et le lot S6 |
| L'arbitrage tel que la vague l'a consigné | [compte rendu de la vague 5](../../docs/superpowers/reports/2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md), §2, ligne D76 |

### Conséquences

- **Le déclencheur de D34** (`onDamagingCardPlayed`, qui rendra *Projectile Magique* visible à
  *Marque du Mage*) **passe avec le lot *Marque*, en vague 8** — vague 7 jusqu'ici. Les textes
  publiés qui disent « vague 7 » pour lui, dont
  [ADR-109](ADR-109-signatures-hors-du-deck.md) (corps gelé), se lisent « vague 8 ».
- **Trois passifs restent masqués jusqu'à `0.6.0`** — une version plus tard que prévu au 01/10 ;
  la note de version de la vague 5 le dit au joueur.
- **`0.6.0` reste la version des neuf passifs jouables**, et la vague 8 reste celle que la session
  de clôture constate.
- **ADR-108 se dit valoir « pour les vagues 4 à 7 »**, écrit quand le programme en comptait sept et
  que la tranche 3 était la vague 7. Cette passe le lit comme couvrant la tranche 3 où qu'elle
  tombe, donc la vague 8 aussi, sous l'amendement de D77
  ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) ; lecture à confirmer par le
  propriétaire.
- **Ce qui ne change pas** : une vague par version, une session par vague, le propriétaire garde le
  test, la PR, la fusion et le tag ; `0.5.8` reste la tranche 2.
