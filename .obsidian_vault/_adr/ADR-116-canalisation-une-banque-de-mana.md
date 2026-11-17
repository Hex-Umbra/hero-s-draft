---
description: Channeling becomes a mana bank (D30) — unspent mana is banked at end of turn up to max Mana plus Mastery, held as an unsaved RunState int read once by startTurn and cleared by startCombat; one pure calculation, ManaReserve.preview, serves the strategy and the HUD; the reserve bypasses StatGains; a new mana_regen status modelled on might_regen; rune excludesEffects also reads status:<id>, completing ADR-105
---

# ADR-116 — *Canalisation*, une Banque de Mana

### Statut

✅ Accepté — 2026-11-15 (P-42, **tranche 2** ; brainstorm v3, décision **D30**, tenue avec D11, D44,
D45, D49 et D50). **Livré sur la branche `feat/v0.5.8-p42-tranche-2` — vague 6 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Premier lot « sans spec »
(R31, à l'essai) : les « Décisions de conception » du
[plan](../../docs/superpowers/plans/2026-11-15-p42-tranche-2.md) en tiennent lieu (§1 à §5, arbitrages
A1 à A15), leur instruction au [fichier de vérifications](../../docs/superpowers/plans/2026-11-15-p42-tranche-2-verifications.md).
Plan `6d3afeaf` ; code `866fefd7`..`ffb55edb` et le correctif de la revue d'ensemble `ec438c28` ;
arbitrages et décisions de SDD S1 à S6 au
[compte rendu de la vague](../../docs/superpowers/reports/2026-11-15-economie-et-catalogue-vague-6-compte-rendu.md), §2.
**Complète [ADR-105](ADR-105-moteur-de-runes-data-driven.md)** (D5 ci-dessous : le prédicat
d'éligibilité lit aussi les statuts posés), qui ne change que de Statut. **ADR-097 reste vrai** : sa
D5 nommait `channeling` premier passif du Mage, et il le redevient (D6).
**Fusionné dans `main` le 2026-11-15 par la PR #54** (commit de fusion `56fae9df`), tagué sur ce
commit, `release.yml` run `43727018143` vert — constaté par la porte d'entrée de la vague 7
(`b50eca31`) et re-vérifié par `gh` le 2026-11-17.

### Contexte

Sous la tranche 1 (vague 5, [ADR-112](ADR-112-forme-c-un-lot-de-cartes-par-passif.md)), six passifs
sur neuf étaient masqués faute de lot. La tranche 2 rouvre *Ferveur*, *Soif de Sang* et
*Canalisation* avec les lots Croisé, Vampire et Voile. *Canalisation* changeait de règle (D30) :
le mana non dépensé ne devient plus de l'Armure, il est **gardé pour le tour suivant**. Le mana
était jusque-là un état sans mémoire d'un tour à l'autre — `startTurn` le remettait à `maxMana` —,
et le joueur ne pouvait pas lire ce qu'il garderait. Le lot Voile apportait *Méditation*, qui rend
du mana par un statut que ni le moteur ni les runes ne connaissaient.

### Décision

**D1 — La réserve est un entier de `RunState`, jamais sauvegardé** (A1). `RunState.manaReserve`
(défaut 0) : le mana est un état de run et `RunController.startTurn`, qui la lit, possède cet état ;
la ranger sur `CombatState` ferait lire le combat au contrôleur de run. Écrite à la fin d'un tour
joueur par `RunController.setManaReserve`, **lue et remise à 0 par le `startTurn` suivant**, remise
à 0 par `startCombat` — un combat gagné pendant le tour ennemi ne la transmet pas au suivant. Ni
`toJson` ni `fromJsonWithReport` ne la lisent : la sauvegarde n'a jamais lieu en combat, comme pour
`CombatState.signaturesReadyOn`.

**D2 — Un seul calcul, `ManaReserve.preview`, lu par la stratégie et par l'écran** (A2). Une
fonction pure rend `(banked, capped)` : `banked = min(mana non dépensé, plafond)`,
`capped = mana non dépensé > plafond`. **Le plafond est en donnée** : `maxMana + passive.value`,
`channeling.json` déclarant `value: 0` et sa Maîtrise `{field: value, perPoint: 1}` — « +1 par
point de Maîtrise » par le mécanisme de P-49, sans constante en Dart. `ManaReserve.forRun(run)`
applique la Maîtrise effective comme `TraitSystem.dispatch` ; `ManaReserve.shown(run, enemyTurn:)`
dit ce que l'écran montre — au tour ennemi, la réserve **écrite**, jamais `capped`, pour qu'un mana
gagné après la fin du tour (*Essence spirituelle*) ne gonfle pas le « +n » affiché.

**D3 — Tout mana non dépensé passe en réserve, hors de `StatGains`** (A3). Le mana non dépensé est
`currentMana` quand `endTurn` déclenche le passif, d'où qu'il vienne. Au `startTurn`, la réserve
s'ajoute à la restauration (`currentMana = maxMana + manaReserve`), avant les reliques
`startOfTurn` et les statuts, qui s'ajoutent par-dessus. **Ce n'est pas un gain** — c'est du mana
déjà gagné et gardé — : elle ne passe pas par `StatGains.apply`, qu'une règle de classe sur le mana
convertirait une seconde fois ([ADR-095](ADR-095-passage-unique-des-gains-scission-des-puissances-et.md)).
Sans *Canalisation*, rien n'écrit la réserve (A4) : « Mage seulement » tient par `classes`, sans
test d'id dans le code.

**D4 — `mana_regen`, la *Source de Mana*, sur le modèle de `might_regen`** (A5).
`EffectResolver.createStatus` le fabrique (buff) ; `StatusEffectProcessor.processPlayerStatuses`
additionne ses valeurs et accorde ce mana par `StatGains.apply(… GainResource.mana …
GainSource.status)`, après le tic, comme `armor_regen`. Aucune branche ennemie : aucun ennemi n'a
de mana. Son icône et sa couleur sont celles de `gain_mana` (`effect_icons.json`, 17 sortes).

**D5 — `excludesEffects` lit aussi `status:<id>`** (A6, D44). `ForgeRuneRules.isEligible` compte
parmi les effets propres d'une carte `status:<statusId>` pour chaque `apply_status` — le
vocabulaire de `feeds` et d'`EffectKind`. *Persistant* (`enduring.json`) et *Résonant*
(`echo.json`) excluent `status:mana_regen` : *Méditation* ne devient ni rejouable à +1 net ni
doublée. Une règle en donnée, aucun `case` par rune — ce qu'ADR-105 demandait au prédicat.

**D6 — Le démasquage est la donnée** (A10, A11). Les quinze fichiers des trois lots ouvrent leurs
passifs par O5, sans code ; six passifs sont jouables, deux par classe. Le Mage propose
*Canalisation* (`displayOrder` 1) puis *Flux de Mana* (3) et démarre de nouveau sur
*Canalisation*, à la sélection comme au tutoriel. `feeds` de *Canalisation* : `["power", "skill"]`.
**Le tutoriel ne simule pas la réserve** (A12) : sa fin de tour ne joue aucun passif et garde le
message « Mana restant ».

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Le calcul unique, `preview`, `forRun`, `shown` | `lib/game/systems/mana_reserve.dart` |
| La réserve, son écriture et sa lecture | `RunState.manaReserve`, `RunController.setManaReserve`, `.startCombat`, `.startTurn` (`lib/game/controllers/run_controller.dart`) |
| La stratégie | `ManaReservePassive`, clé `ManaReserve.effectType` de `PassiveStrategies.byEffectType` ; `ChannelingPassive` supprimée (`lib/game/systems/passives/passive_strategies.dart`) |
| La donnée du passif | `assets/data/passives/channeling.json` (`effectType` `mana_reserve`, `value` 0, Maîtrise sur `value`) |
| `mana_regen` | `EffectResolver.createStatus` ; `StatusEffectProcessor.processPlayerStatuses` ; `assets/data/effect_icons.json` |
| `status:<id>` dans le prédicat | `ForgeRuneRules.isEligible` (`lib/game/services/forge_rune_rules.dart`) ; `assets/data/forge_upgrades/enduring.json`, `echo.json` |
| L'écran | `ManaIndicator` (`reserveArrows`), `CombatBottomHud`, `TurnControlPanel` (`reservePreview`), `GameScreen` |
| Les gardes | `test/unit/mana_reserve_test.dart`, `mana_regen_test.dart`, `passives_mage_test.dart`, `run_state_persistence_test.dart` (« manaReserve ne se sauvegarde pas »), `rune_eligibility_test.dart` |

Règles de jeu : [`_rules/03-1`](../_rules/03-1-gestion-du-mana.md),
[`_rules/02-2`](../_rules/02-2-systeme-de-heros.md), [`_rules/04-00`](../_rules/04-00-alterations-d-etat-statuts.md).
Patterns : [`_patterns/03-3`](../_patterns/03-3-traitsystem-passifs-de-heros.md),
[`_patterns/07-00`](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md).

### Conséquences

- **Le mana a une mémoire d'un tour**, sous un seul passif : un Mage peut jouer peu pour jouer gros.
  Au plus, sans Maîtrise : 3 + 3 de réserve + 1 (*Pierre d'énergie*) + 1 (`mana_regen`) = 8.
- **L'Armure de *Canalisation* disparaît** : trois tests retirés avec elle.
- **Aucun test d'écran** ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) : les
  flèches, la légende et le message de fin de tour sont aux points M1 à M6, M12 à M14 de la §8 du
  plan, pour le fichier de tests manuels ; leurs calculs, `preview` et `shown`, sont gardés.
- **Laissé pour la file** (compte rendu §4) : `effect_line_texts.dart` n'a pas de phrase pour
  `mana_regen` ; l'écriture `'status:${statusId}'` vit en trois endroits — `forge_rune_rules.dart`,
  `passive_feeds.dart`, `EffectKind.of` —, à factoriser à la quatrième lectrice ; la garde
  `if (preview == null) return;` de `ManaReservePassive` est inatteignable ; seize cristaux ou plus
  sous *Canalisation* feraient déborder le HUD de 88 px.
