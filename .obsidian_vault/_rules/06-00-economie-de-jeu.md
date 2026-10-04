## 6. Économie de Jeu

### 6.1. Or

- **Or initial** : 50 (défini dans `InventoryController.reset(initialGold: 50)`).
- **Sources** : Victoires combat (via `completeCurrentNode`), événements (`gain_gold` ; et, sur la
  branche de la vague 3, la relique cédée au *Colporteur* — `trade_relic`, 40 or × (rang de rareté
  + 1), [`_rules/03-6`](03-6-systeme-d-evenements.md)), reliques.
- **Dépenses** : Boutique (cartes, services), événements (`spend_gold`).

### 6.2. Application d'un Gain de Statistique

`PlayerStatsManager.applyHeroStatModifier()` est le point d'entrée commun — récompense de draft
comme effet d'événement. Depuis P-41 lot C partie 1, une récompense de niveau n'appelle plus ses
paramètres nommément : `applyLevelUpReward(DraftChoice)` lit la stat visée dans la donnée et
répartit par un `switch` **exhaustif** sur `RewardStat` — ajouter une stat sans l'appliquer ne
compile plus ([ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md)).

| Paramètre | `RewardStat` | Effet |
|:---|:---|:---|
| `maxPvAcc` | `maxHp` | +X PV Max ; soigne aussi le delta |
| `mightAcc` | `might` | +X Puissance permanente ; ce qu'elle renforce dépend de la classe ([ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md)) |
| `masteryAcc` | `mastery` | +X Maîtrise, sur le paramètre que déclare le passif actif ([ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)) |
| `maxManaAcc` | `maxMana` | +X Mana Max ; augmente le plafond régénéré chaque tour |
| `luckAcc` | `luck` | +X Chance ; influence la rareté des récompenses et des reliques |
| `critChanceAcc` | `critChance` | +X % de chances de coup critique |
| `critDamageAcc` | `critDamage` | +X % de dégâts critiques ; **seule conversion** — la donnée est en points entiers, l'application divise par 100 |

Le **Miroir** ne monte aucune stat : `stat` absent, il ouvre une modale de clonage. *Transcendance*
non plus (`effect: raiseRuneCap`, branche de la vague 3) : elle ouvre la modale des plafonds de rune
([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md)).

### 6.3. Valeurs des Récompenses de Montée de Niveau

> [!IMPORTANT]
> **Ces valeurs sont de la donnée, pas du code.** Elles vivent une par fichier sous
> `assets/data/level_up_rewards/<id>.json`, dans une table `values` **explicite** palier par
> palier. **Aucun multiplicateur ne survit en code** : le multiplicateur générique
> (`×1` / `×1,5` / `×2` / `×3` / `×4`) et les cascades de `if` par type ont disparu ensemble
> ([ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md)). Le tableau
> ci-dessous est la **forme lisible** des cinq fichiers tirables, pas une seconde source.

| Récompense | `stat` | Commun | Peu commun | Rare | Épique | Légendaire |
|:---|:---|---:|---:|---:|---:|---:|
| Vitalité | `maxHp` | 5 | 8 | 10 | 15 | 20 |
| Aiguisage | `might` | 2 | 3 | 4 | 6 | 8 |
| Affinité | `mastery` | 1 | 2 | 3 | 5 | 7 |
| Précision | `critChance` | 1 | 2 | 3 | 4 | 5 |
| Férocité | `critDamage` | +10 % | +20 % | +30 % | +40 % | +50 % |

Ces cinq-là portent `pool: draft` : les **trois emplacements** du draft les tirent uniformément,
chacun à une rareté jetée séparément, et ne sortent **jamais** en mythique. **Ils étaient six
jusqu'au lot E3 de P-43** (branche de la vague 3, en attente du propriétaire —
[ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)) : *Sagesse* est passée mythique (D11).

**Une récompense peut se retirer du tirage**, depuis le lot C partie 2 : le champ `requires`
(`RewardRequirement`) est un prédicat lu par `generateChoices` avant le tirage, et non une
propriété d'une récompense en particulier. Deux exigences existent :
- **`passiveMastery`**, que déclare l'**Affinité** : elle n'est pas proposée si le passif actif ne
  déclare pas de bloc `mastery`, ni s'il n'y a **pas de passif du tout** — dans les deux cas la
  récompense serait inerte. La table effective tombe alors de cinq à quatre types. **Les neuf
  passifs livrés déclarent tous une Maîtrise : aucune run réelle n'est concernée à ce jour**
  ([ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md)) ;
- **`raisableRune`** (branche de la vague 3), que déclare *Transcendance* : elle n'est tirée que si
  une rune du deck est à son plafond effectif, ni sans plafond ni `binary` — l'écran de draft le
  calcule par `ForgeRuneRules.raisableCaps` et le passe à `generateChoices(hasRaisableRune:)`.

Quatre récompenses portent `pool: mythic` sur la branche de la vague 3 (deux sur `main`) : elles
n'ont pas de courbe, sortent à ce seul palier et sont ajoutées aux trois par un **jet indépendant
chacune** (0,5 %, plus `luck × 0,15`, D62) — **Sagesse** (`maxMana`, `values.mythic: 1`), le
**Trèfle à 4 feuilles** (`luck: 1`), le **Miroir** (`effect: cloneCard`, clone d'une carte) et
***Transcendance*** (`effect: raiseRuneCap`, `requires: raisableRune`). Rangées 1 à 9 par
`displayOrder` avec les tirables ; la fiche des probabilités de la carte du monde nomme les
mythiques depuis la donnée (`luckLevelRewardSubtitle`), dans cet ordre.

> [!IMPORTANT]
> **L'Affinité a sa propre courbe, plus raide que les autres** (rebaptisée depuis la Forge
> d'Acier par [ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md),
> chantier P-49 ; valeurs inchangées). La Maîtrise qu'elle donne renforce le paramètre que
> déclare le passif actif — à chaque tour pour le Paladin, à chaque Compétence jouée pour le
> Mage, à chaque tranche de PV manquants pour le Berserker (désormais multiplicatif, voir
> l'ADR) — donc elle compose bien plus fort que les autres récompenses. C'est aussi la seule
> case qui avait cassé : sa cascade de `if` n'avait pas de palier légendaire et retombait sur
> `1`, la valeur d'un commun. Corrigé en `0.4.9`, quand elle s'appelait encore Forge d'Acier —
> et le régime de valeur qui l'avait permis n'existe plus.

> [!NOTE]
> **Le plateau de Sagesse a disparu avec ses paliers.** Peu commun et rare y rendaient la même
> chose (2), recopiée telle quelle du multiplicateur et laissée à P-16 ; mythique depuis le lot E3,
> *Sagesse* n'a plus qu'une valeur, +1 Mana max.

Les 25 cases de ce tableau sont verrouillées par `test/unit/level_up_reward_values_test.dart`,
devenu un test **sur la donnée**, qui vérifie en outre que chaque récompense progresse strictement
avec la rareté — l'invariant que l'Affinité (alors Forge d'Acier) violait, et dont plus aucune
récompense n'est dispensée depuis le départ de *Sagesse*. La forme des fichiers est garantie par
`level_up_rewards_catalog_test.dart` et `level_up_reward_data_test.dart`.

**Les chances de rareté d'un emplacement** se lisent en un seul endroit,
`LevelUpRewardService.slotRarityChances(luck)` (branche de la vague 3) : la distribution de
`rollRarity(luck, isLevelReward: false)` — 2 / 6 / 16 / 24 % de la légendaire à la peu commune,
plus Chance × 0,5 / 1,5 / 3 / 4, la commune le reste —, que lisent le tirage et la fiche des
probabilités. La copie de la fiche, qui affichait 0,5 / 4,5 / 15 / 20, a disparu avec
`calculateDraftProbabilities`, et la section « Draft standard de récompenses » avec elle.

### 6.4. La trouvaille — une carte après chaque combat

*Branche de la vague 3, en attente du propriétaire —
[ADR-107](../_adr/ADR-107-trouvaille-et-progression.md) (D1, D31, D57).*

| Nœud | Règle (`GameConstants.cardDrops`) | Relique qui la module |
|:---|:---|:---|
| Combat normal | 1 carte garantie | *Sacoche du glaneur* (rare) : +1 carte garantie par exemplaire (`RunState.extraCombatCards`) |
| Élite | 1 garantie, puis un jet à 25 % pour une seconde | *Registre des primes* (rare) : +25 points sur ce jet par exemplaire (`RunState.eliteCardChanceBonus`) |
| Boss, et tout autre type | aucune — le boss garde sa récompense | — |

- **Le tirage** : `CardDrops.roll`, une fonction pure — les cartes garanties, puis un jet par
  chance, l'arrêt au premier raté. La *Sacoche* ne touche jamais l'élite, ni le *Registre* le
  combat normal.
- **Les cartes** : tirées uniformément, avec remise, parmi celles que la classe peut recevoir —
  `CardData.isOfferableTo`, le prédicat d'offre unique d'ADR-101, signatures exclues —, soit les
  17 neutres ; **toujours communes, donc sans rune** ; ajoutées au deck sans refus par
  `collectGoldAndXp`, une notification « 🃏 Carte trouvée : … » par carte. Pool vide : aucune
  carte, sans repli.
- **La carte bonus du boss « XP » a disparu** : la trouvaille lit le prédicat à sa place ; le boss
  « XP » monte une rune ([`_rules/02-1`](02-1-generation-procedurale-de-carte.md)).

### 6.5. L'expérience — le prix d'un niveau par acte

*Branche de la vague 3 — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md) (D24, D58, D67).*

Le prix d'un niveau ne dépend plus du niveau mais de **l'acte courant**, lu dans
`assets/data/xp_curve.json` : **115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 ·
1370 · 1370 · 1300 · 1375 · 1015**, la dernière valeur répétée au-delà de l'acte 15 — de quoi
gagner deux niveaux par acte. La courbe géométrique `100 × 1,5^(n−1)` a disparu. Le palier est
**dérivé** à chaque lecture, jamais stocké : un niveau se paie au prix de l'acte où il se termine,
et un palier qui passe sous l'XP accumulée au changement d'acte — de l'acte 8 (1100) à l'acte 9
(1040) — donne le niveau au gain suivant. L'XP du boss se compte avant le changement d'acte, au prix
de son acte. Le surplus d'XP est conservé ; chaque niveau ajoute un draft en attente
(`pendingDrafts`).

Structure du catalogue — [`_rules/07-00`](07-00-architecture-des-donnees.md).
