---
description: Freeze, Burn and Shock stop being timed statuses and become elemental charges — points summed per id that build up on any bearer, hero or enemy, until a threshold where they break; one data file per element under charges/ (the eleventh source and editor category) declares threshold, growth, overcharge, decay, break moment and rupture kind, and only four rupture kinds are Dart (skipAction, weakenDealt, explode, amplifyHits); a per-bearer track kept off the save, a Fire chain resolved wave by wave, Freeze leaving the proportional scale; amends ADR-023 D1-D3 and ADR-111 D4, completes ADR-104 D4, ADR-105 D2, ADR-061, ADR-086 and ADR-100, closes ADR-110
---

# ADR-117 — Les Charges Élémentaires : le Gel, le Feu et la Foudre

### Statut

✅ Accepté — 2026-11-17 (P-53 ; brainstorm v3, décisions **D76** et **D83 à D86**, tranchées par le
propriétaire le 2026-11-15 ; réponses P-a à P-e du 15/11, Q-P1 du 16/11, Q-P2 du 17/11). **Livré sur
la branche `feat/v0.5.9-p53-charges-elementaires` — vague 7 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.**
[Spec](../../docs/superpowers/specs/2026-11-15-p53-charges-elementaires-design.md) prête au quatrième
tour (`42579386`) ; [plan de la partie 1](../../docs/superpowers/plans/2026-11-15-p53-charges-elementaires-partie-1.md),
code `7a256deb`..`b155d6a2` ; [plan de la partie 2](../../docs/superpowers/plans/2026-11-16-p53-charges-elementaires-partie-2.md),
code `f0e7bb47`..`21050357` ; note de version `d15bcd04`. Arbitrages A1 à A19, Q1, Q2 et décisions
de SDD S0 à S16 au
[compte rendu de la vague](../../docs/superpowers/reports/2026-11-16-economie-et-catalogue-vague-7-compte-rendu.md),
§2 — leurs motifs ne se recopient pas ici.

**Amende [ADR-023](ADR-023-systeme-de-statuts-elementaires-riches-vulnerabili.md)** sur D1 (Brûlure),
D2 (Gel) et D3 (Électrocution) ; sa D4 (Vulnérable) est inchangée. **Amende
[ADR-111](ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md)** sur D4 :
le Gel quitte le barème proportionnel, *Congelant* pose 1 point par niveau. **Complète
[ADR-104](ADR-104-un-statut-par-source-et-ratio-de-conversion.md)** D4,
[ADR-105](ADR-105-moteur-de-runes-data-driven.md) D2,
[ADR-061](ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md),
[ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) (la onzième source) et
[ADR-100](ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md) (la onzième catégorie de
l'éditeur). **Clôt [ADR-110](ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)** : la vague
de plus est livrée. Chacun de ces ADR ne change que de Statut. **Clôt P-53** dans `docs/ROADMAP.md`.
**Fusionné dans `main` le 2026-11-18 par la PR #55** (commit de fusion `5d894785`), tagué `v0.5.9` sur ce commit ; CI de tête `44271012349` et `release.yml` run `44271100229` verts — constaté par la porte d'entrée de la vague 8 (`eb7945fb`) et re-vérifié par `gh` le 2026-11-18.
**Complété le 2026-11-22 par [ADR-121](ADR-121-l-interface-des-ennemis-en-combat.md)** (les états des
charges se lisent au repos et au déroulé des languettes) **et sa réserve S9 close par
[ADR-122](ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md)** — tous deux livrés sur la branche
`feat/v0.6.1-interface-des-ennemis` (P-05 vague 1), test du propriétaire passé le 2026-11-22, en attente de la PR, de la fusion et du
tag du propriétaire. **Puis par la correction C1 d'ADR-121** : chaque charge déclare aussi
une phrase courte, `summary_fr` / `summary_en`, obligatoire, que la fiche d'un ennemi écrit sous
elle ; la description reste celle des infobulles des cartes.

### Contexte

Sous le barème de P-1 (vague 5, ADR-111 D4), le Gel réduisait ce que l'ennemi inflige, comme la
Faiblesse, et la Brûlure était un second dégât sur la durée, comme le Poison. D76 a donné une vague
au chantier pour en faire des **charges** : des points qui s'accumulent jusqu'à un seuil où ils
rompent, chacun à sa manière, dans un cadre commun en donnée, symétrique héros / ennemis. Leurs
règles, décidées le 15/11 (D83 à D86), sont fondées par l'[étude](../../docs/possible_upgrades/03-11-2026_charges_elementaires_Opus5.md),
§11 et §12. Le moteur lisait ces trois statuts par leur id en dur — le tic, l'attaque, le pipeline —,
en sept endroits.

### Décision

**D1 — Un fichier par charge, sous `charges/<id>.json`** (D83, A1 à A3). L'id du fichier est l'id du
statut que posent les cartes : `freeze`, `burn`, `shock`, aucun `statusId` ne change. Un fichier
déclare son nom et son état rompu (`brokenName`), sa description à jetons — et `heroDescription` si
et seulement si une `heroRupture` existe —, le seuil de départ (`threshold`, `bossThreshold`,
`heroThreshold`), sa montée à chaque rupture (`thresholdGrowth`), la surcharge (`overcharge`), le
déclin (`decay`), le moment de rupture (`breaksOn` : `threshold` ou `bearerTurn`), la part sous le
seuil (`belowThresholdPercent`) et la rupture (`rupture`, `heroRupture`). `ChargeData.fromJson`
valide tout au chargement, faute accumulée avec celles des entités : clé inconnue, paire bilingue,
bornes, sorte et moment incompatibles, jeton inconnu, et **un seuil de Feu inférieur à 3 refusé**
(D85) — la garantie que la chaîne s'arrête. `chargeCatalogProvider` les expose, vide par défaut.

**D2 — Quatre sortes de rupture, seules écrites en Dart** (D83). `skipAction` (le porteur perd sa
prochaine action), `weakenDealt` (ses coups font `percent` % de moins pendant son prochain tour),
`explode` (toute la charge se résout et explose sur les voisins), `amplifyHits` (chaque coup reçu
fait plus). Une charge future est un fichier, et au besoin une sorte de plus.

**D3 — Les points restent des statuts ; la piste, à côté, hors sauvegarde** (A4 à A9). Les points
d'une charge sont la somme des entrées de même id — une entrée de forme fixe, `debuff`, durée 1,
**jamais décomptée par le tic** (`tickStatuses` reçoit les ids des charges) et retirée à 0. La
**piste** (`ChargeTrack`, `EntityStats.charges`, par porteur et par élément) porte le seuil courant,
le nombre de ruptures, l'état — aucun, rompu en attente, rompu actif — et la rupture en vigueur,
`heroRupture` pour le héros s'il y en a une. Ni `toJson` ni `fromJson` ne la lisent : la sauvegarde
n'est jamais écrite en combat, aucun `schemaVersion` ne change. `ChargeRules`
(`lib/game/systems/charge_rules.dart`) est la seule écriture des règles : la pose (refus sur un porteur
rompu sans surcharge, plafond au restant, rupture aussitôt au seuil), le déclin, la résolution du
Feu, les deux fermetures de phase, les lignes d'affichage.

**D4 — Les trois éléments, aux valeurs de D84 à D86.** **Gel** : seuils 3, 6 pour tout ennemi
`isBoss`, 5 pour le héros, +1 à chaque gel ; pas de surcharge ; déclin −1 s'il n'a pas gelé ;
l'ennemi gelé ne fait rien, son intention est consommée, ses statuts se résolvent ; **le héros gelé
ne perd pas son tour** — ses cartes et signatures infligent 50 % de moins pendant le suivant, après
la Faiblesse. **Feu** : seuil 3 fixe, surcharge libre, aucun déclin ; au tour du porteur, chaque
tranche fait 4 par point et explose — 12 et 1 Feu à chaque voisin de la rangée —, le reste fait 2
par point ; l'Armure absorbe, ni Vulnérable, ni critique, ni Faiblesse (P-d) ; le héros n'a pas de
voisin. **Foudre** : seuil 3 fixe, surcharge libre ; +1 par point à chaque coup reçu sous le seuil,
+2 par point une fois chargé, jusqu'à la fin de la phase en cours ; déclin −1 sous le seuil.

**D5 — La chaîne du Feu, vague par vague, jouée par le contrôleur, animée par Flame** (A10 à A12).
Au début de la phase ennemie, après la fermeture du tour du joueur : `startEnemyTurn` joue la vague 1
— tous les porteurs vivants ensemble —, puis `resolveNextFireWave` la suivante, formée du seul Feu
posé par les explosions, jusqu'à ce qu'une vague n'en pose plus ; puis `resolveEnemyStatuses` et un
seul `cleanDeadEnemies`. Chaque vague laisse un compte rendu, `CombatState.fireWaveReport`, sans
dégâts nominaux : les dégâts se lisent sur les PV. Un porteur que sa rupture tue explose ; un porteur
tué avant son tour perd son Feu. L'exemple de l'étude — 9 Feu sur B dans A B C : 48, 64, 48 — est un
test.

**D6 — Le pipeline reçoit le catalogue** (A14). `DamagePipeline.calculate(charges:)` : Faiblesse,
puis **le héros gelé** (`ChargeRules.weakenPercent`), critique, **la Foudre du défenseur**
(`ChargeRules.hitBonus`, à la place de l'Électrocution), Vulnérable, qui l'amplifie. **`ProportionalStatus`
ne garde que Vulnérable et Faiblesse** : le Gel quitte le barème, l'intention d'un ennemi n'est plus
réduite par le Gel. Chaque coup de Foudre note son bonus sur le défenseur (`EntityStats.chargeHits`,
hors sauvegarde) pour que Flame le montre coup par coup (Q2).

**D7 — `ApplyStatusEffectStrategy` aiguille les charges** (complète ADR-061 et ADR-105 D2). Un
`apply_status` dont le statut est une charge du catalogue passe par `ChargeRules.pose`, sur la cible
de la carte — un ennemi, tous, ou le héros ; les autres, par `addStatus`. Les runes élémentaires
posent ainsi leur charge, avant les effets de la carte. `EffectResolver.createStatus` ne fabrique
plus `burn`, `freeze` ni `shock`. Le bonus de Puissance « altération » ajoute des points, une fois par
résolution, **avant** le plafond du Gel ; une explosion n'est pas une carte et n'en reçoit pas.

**D8 — Les charges restent sans source** (complète ADR-104 D4) : posées sans `sourceId`, leurs points
en somme par id, leur piste hors sauvegarde.

**D9 — Les noms et les valeurs du joueur** (P-a, P-b). Gel, Feu, Foudre ; Freeze, Burn, Shock ; états
Gelé / Frozen et Chargé / Charged ; les runes gardent leurs noms. *Embrasement* pose 3 Feu (4 avant),
*Congelant* 1 Gel par niveau (2 avant) ; les huit autres contenus — *Braise* comprise — inchangés. Les
textes viennent du fichier de la charge, jetons remplis ; `heroDescription` ne s'affiche nulle part
dans cette vague (Q-P1 (d)) : aucun ennemi ne pose de charge.

**D10 — L'écran lit l'état, Flame ne calcule rien** (A13, P-c, Q-P2). L'ennemi gelé se lit
(`EnemyInstance.skipsAction`) **avant** que Flame lance son action : il ne fonce pas. Les icônes des
ennemis et le panneau du héros lisent les lignes de `ChargeRules.linesFor` (« ❄ 2/3 », « 🔥 5 »,
« ⚡ Chargé »). Les animations de la partie 2 : **la gangue** du Gel (G-a, `FrostShell`, et
`FrostVignette` chez le héros gelé), **l'onde** du Feu (F-a, `FireBurst` et `Fireball`, jouées par
`CombatVisualSystem.playFireWave`, 800 ms par vague), **le halo** de la Foudre chargée (L-b,
`ChargeHalo`) et son bonus « +N » à chaque coup, sous le seuil comme chargé, dans le même jaune
`#FFEA00` (Q-P2 (c)).

**D11 — La onzième source et la onzième catégorie** (complète ADR-086 et ADR-100).
`assets/data/charges/*.json` injecte l'`id` ; l'éditeur de contenu gagne `EntityCategory.charge`,
`construct` = `ChargeData.fromJson`. Le menu de debug gagne une section « Charges » dans l'onglet
Combat (P-e) : `DebugActions.poseCharge` pose un point par la vraie règle, `clearCharges` vide.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| La donnée et sa validation | `assets/data/charges/` (trois fichiers) ; `ChargeData`, `ChargeRupture`, `ChargeCatalog` (`lib/models/data/charge_data.dart`) |
| La source, le registre, le provider | `chargeSource`, `chargeCatalogProvider` (`lib/services/game_data_service.dart`) ; `GameDataRegistry.charges` |
| La piste et les coups | `ChargeTrack`, `ChargeState`, `ChargeHit` (`lib/models/charge_track.dart`) ; `EntityStats.charges`, `.chargeHits` |
| Les règles | `ChargeRules` (`lib/game/systems/charge_rules.dart`) |
| La chaîne et son compte rendu | `TurnPhaseManager.startEnemyTurn`, `.resolveNextFireWave`, `.resolveEnemyStatuses` ; `FireWaveReport` (`lib/models/fire_wave_report.dart`) ; `CombatState.fireWaveReport` |
| L'ennemi gelé | `EnemyInstance.skipsAction` ; `TurnPhaseManager.resolveEnemyIntent` ; `HerosDraftGame._enemyRipostePhase` |
| Le pipeline | `DamagePipeline.calculate` ; `ProportionalStatus` (`vulnerable`, `weakness` seuls) |
| La pose | `ApplyStatusEffectStrategy` (`lib/game/services/effects/strategies.dart`) |
| Les animations | `lib/game/components/visual_effects/frost_shell.dart`, `fire_wave_effects.dart`, `charge_halo.dart` ; `CombatVisualSystem.playFireWave` ; `GameConstants.combatDelayFireWaveMs` |
| L'éditeur, le debug | `EntityCategory.charge` ; `DebugActions.poseCharge`, `.clearCharges` ; `debug_combat_tab.dart` |
| Les gardes | `test/unit/charge_data_test.dart`, `charge_rules_test.dart` (48, 64, 48 ; la chaîne s'arrête), `charge_symmetry_test.dart`, `damage_pipeline_test.dart`, `combat_controller_test.dart` |

Règles de jeu : [`_rules/04-00`](../_rules/04-00-alterations-d-etat-statuts.md) §4.5,
[`_rules/03-3`](../_rules/03-3-pipeline-de-degats-centralise.md). Patterns :
[`_patterns/07-00`](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md),
[`_patterns/03-4`](../_patterns/03-4-effectresolver-resolution-d-effets-de-cartes.md).

### Conséquences

- **Plus aucune règle ne lit un élément par son id en dur** :
  `git grep -E "(s|status)\.id [!=]= '(burn|freeze|shock)'" -- lib` et
  `git grep "ProportionalStatus.freeze" -- lib test` ne rendent rien (re-mesuré le 2026-11-17).
- **Le cadre est symétrique, mais aucun ennemi ne pose de charge** : `IntentType` ne connaît que
  `attack`, `defend`, `buff`. Le Gel, le Feu et la Foudre du héros ne se vérifient à la main que par
  l'entrée de debug.
- **Vulnérable, Faiblesse et Poison ne changent pas** : même barème, même tic, mêmes valeurs
  attendues des tests.
- **Aucun test d'écran** ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) :
  l'affichage et les animations sont les points M1 à M16 des tests manuels (spec §9.1).
- **Laissé pour la file** (compte rendu §4) : la fin de la phase ennemie se joue après une victoire
  constatée par les statuts — un soin de trop de *Bénédiction*, déjà dans `main` avant la vague —, **bloquant pour le
  premier contenu qui posera du Feu ou du Poison sur le héros** (S9) ; un harnais de test commun qui
  surcharge le chargement du registre ; `FrostVignette` recrée ses dégradés à chaque frame,
  `ChargeHalo` et `FireBurst` leur `Paint` ; le serrement de la gangue ne se voit pas sous le sursaut
  du coup (S16) ; `shippedCard(id)` ne lit pas les cartes de lot.
- **L'explosion du Feu à la mort** d'un porteur reste écartée (D85).
