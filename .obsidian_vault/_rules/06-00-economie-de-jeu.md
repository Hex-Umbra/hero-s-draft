## 6. Économie de Jeu

### 6.1. Or

- **Or initial** : 50 (défini dans `InventoryController.reset(initialGold: 50)`).
- **Sources** : Victoires combat (via `completeCurrentNode`), événements (`gain_gold`), reliques.
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

Le **Miroir** ne monte aucune stat : `stat` absent, il ouvre une modale de clonage.

### 6.3. Valeurs des Récompenses de Montée de Niveau

> [!IMPORTANT]
> **Ces valeurs sont de la donnée, pas du code.** Elles vivent une par fichier sous
> `assets/data/level_up_rewards/<id>.json`, dans une table `values` **explicite** palier par
> palier. **Aucun multiplicateur ne survit en code** : le multiplicateur générique
> (`×1` / `×1,5` / `×2` / `×3` / `×4`) et les cascades de `if` par type ont disparu ensemble
> ([ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md)). Le tableau
> ci-dessous est la **forme lisible** de ces huit fichiers, pas une seconde source.

| Récompense | `stat` | Commun | Peu commun | Rare | Épique | Légendaire |
|:---|:---|---:|---:|---:|---:|---:|
| Vitalité | `maxHp` | 5 | 8 | 10 | 15 | 20 |
| Aiguisage | `might` | 2 | 3 | 4 | 6 | 8 |
| Affinité | `mastery` | 1 | 2 | 3 | 5 | 7 |
| Sagesse | `maxMana` | 1 | 2 | 2 | 3 | 4 |
| Précision | `critChance` | 1 | 2 | 3 | 4 | 5 |
| Férocité | `critDamage` | +10 % | +20 % | +30 % | +40 % | +50 % |

Ces six-là portent `pool: draft` : les **trois emplacements** du draft les tirent uniformément,
chacun à une rareté jetée séparément, et ne sortent **jamais** en mythique.

**Une récompense peut se retirer du tirage**, depuis le lot C partie 2 : le champ `requires`
(`RewardRequirement`) est un prédicat lu par `generateChoices` avant le tirage, et non une
propriété d'une récompense en particulier. Seule l'**Affinité** le déclare aujourd'hui
(`passiveMastery`) : elle n'est pas proposée si le passif actif ne déclare pas de bloc `mastery`,
ni s'il n'y a **pas de passif du tout** — dans les deux cas la récompense serait inerte. La table
effective tombe alors de six à cinq types. **Les neuf passifs livrés déclarent tous une Maîtrise :
aucune run réelle n'est concernée à ce jour**, le filtre attend le premier passif qui n'en
déclarera pas ([ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md)).

Deux récompenses portent `pool: mythic` : elles n'ont pas de courbe, sortent à ce seul palier et
sont ajoutées aux trois par un **jet indépendant chacune** (0,5 %, plus `luck × 0,15`) — le
**Trèfle à 4 feuilles** (`luck: 1`) et le **Miroir** (`effect: cloneCard`, clone d'une carte). Une
troisième mythique ne serait qu'un fichier de plus.

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
> **Sagesse plafonne à 2 sur deux paliers consécutifs.** Peu commun et rare rendent la même
> chose : `round(1 × 1,5)` et `round(1 × 2,0)` donnaient tous deux 2 à l'époque du multiplicateur,
> et le plateau a été **recopié tel quel** dans sa donnée. Rendu visible plutôt qu'excusé par la
> table explicite ; son rééquilibrage appartient à **P-16**.

Les 30 cases de ce tableau sont verrouillées par `test/unit/level_up_reward_values_test.dart`,
devenu un test **sur la donnée**, qui vérifie en outre que chaque récompense progresse strictement
avec la rareté — l'invariant que l'Affinité (alors Forge d'Acier) violait. La forme des fichiers
est garantie par `level_up_rewards_catalog_test.dart` et `level_up_reward_data_test.dart`.

Structure du catalogue — [`_rules/07-00`](07-00-architecture-des-donnees.md).
