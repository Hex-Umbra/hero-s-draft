### 3.3. `TraitSystem` — Passifs de Héros

Depuis P-49 ([ADR-096](../_adr/ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md), qui
remplace la D4 d'ADR-086), `TraitSystem` n'a plus qu'une méthode : un répartiteur, sur le modèle
Strategy d'[ADR-061](../_adr/ADR-061-strategy-pattern-pour-la-resolution-des-effets-de.md).

**`TraitSystem.dispatch(RunController run, PassiveEvent event)`** (`lib/game/systems/trait_system.dart`) :
1. Lit `run.currentState.activePassive` — rien si `null` (aucun passif actif).
2. Compare le `trigger` déclaré par le passif à celui de `event` — rien s'ils diffèrent. C'est ce qui
   rend le trigger réellement data-driven : un passif suit son `trigger` déclaré, plus une cascade
   `if/else` qui ne le testait qu'à certains endroits.
3. Applique la Maîtrise au passif : `passive.withMastery(run.currentState.heroStats.effectiveMastery)`
   (`PassiveData.withMastery`, `lib/models/data/passive_data.dart`) — augmente le paramètre que
   désigne le bloc `mastery` du passif (`field`, `perPoint`), ou le rend tel quel sans `mastery`.
4. Délègue à la stratégie de l'`effectType` du passif augmenté.

**Le registre `PassiveStrategies.byEffectType`** (`lib/game/systems/passives/passive_strategies.dart`)
est une `Map<String, PassiveStrategy>` **constante** — table de code, pas un état :

| `effectType` | Stratégie | Logique |
|:---|:---|:---|
| `gain_armor` | `GainArmorPassive` | Accorde `value` d'armure |
| `fervor` | `FervorPassive` | `value` Puissance pendant `duration`, si l'armure a réellement absorbé |
| `blessing` | `BlessingPassive` | `(armure survivante ~/ 5) × value` PV |
| `rage` | `RagePassive` | `value × (1 + PV manquants ~/ 10)` Puissance pour `duration` |
| `bloodthirst` | `BloodthirstPassive` | Arme le Vol de vie `duration` tours, valeur croissant par quart de PV manquants |
| `frenzy` | `FrenzyPassive` | `value` Puissance pour `duration` et `draw` cartes, **par ennemi abattu** |
| `channeling` | `ChannelingPassive` | `mana non dépensé × value` armure |
| `mage_mark` | `MageMarkPassive` | Rend `event.enemyId` Vulnérable `duration` tours, une fois par tour |
| `mana_flux` | `ManaFluxPassive` | `value` Mana toutes les `threshold` Compétences du combat |

**Ce qu'un passif reçoit.** `PassiveEvent(RelicTrigger trigger, {CardInstance? card, String? enemyId,
int? absorbedDamage, int? survivingArmor})` — toujours `const`-constructible. Les trois charges utiles
ajoutées par P-41 lot B existent parce qu'un passif ne peut pas les recalculer :
`absorbedDamage` (ce que l'armure a réellement encaissé), `survivingArmor` (l'armure **capturée avant**
la remise à zéro de début de tour — le dispatch, lui, n'a pas bougé, sinon tout passif `startOfTurn`
donnant de l'armure aurait disparu du calcul), et `enemyId`, passé **uniquement** quand la carte vise
un ennemi unique.

**Ce qu'un passif compte.** Un compteur (« la 1ʳᵉ Attaque du tour », « toutes les N Compétences »)
est un **statut caché du héros** `<id>_count` — `PassiveCounters` / `CounterScope` — de durée 1 pour
le tour, 99 pour le combat. C'est l'idiome déjà en place pour les charges de reliques
(`shuriken_charge`, `pen_nib_charge`, `incense_charge`) : les statuts sont décrémentés à chaque début
de tour et vidés en fin de combat, donc **la portée vient de la durée** et aucun état nouveau n'est à
sérialiser.

> [!IMPORTANT]
> **Un passif choisit son déclencheur par sa donnée, pas par son code.** Les points de dispatch
> couvrent le type de carte jouée (`onAttackPlayed`, `onSkillPlayed`, `onPowerPlayed`), la mort d'un
> ennemi (`onEnemyKilled`, une fois **par ennemi**) et les dégâts encaissés (`onDamageTaken`). Une
> stratégie ne re-teste jamais son propre trigger : `dispatch` l'a déjà fait.

Chaque stratégie implémente `PassiveStrategy.resolve(PassiveData passive, PassiveEvent event, RunController run)`
(`lib/game/systems/passives/passive_strategy.dart`) et lit `passive.value` **déjà augmenté** par
`dispatch` — elle ne lit jamais `effectiveMastery` elle-même. Chaque gain d'armure passe par
`RunController.grant(StatGain(GainResource.armor, n, GainSource.passive))`, comme avant P-49 ;
`StatGains` n'a plus de règle spéciale pour cette source ([`_rules/03-2`](../_rules/03-2-gestion-de-l-armure.md)).
Un `effectType` absent de la table **ne fait rien** — jamais d'exception en plein combat —
et `referential_integrity_test` refuse qu'un passif livré soit dans ce cas.

**Éligibilité et rang** : chaque passif déclare ses `classes` (absent = toutes) ; le point d'accès
unique `availablePassivesFor(HeroData, GameDataRegistry)` (`lib/game/systems/passive_availability.dart`)
est la seule fonction qui les lit, triés par **`(displayOrder, id)`**. Ses deux lecteurs ne le
consomment plus de la même façon depuis le **lot C partie 2** de P-41 : l'écran de sélection de
classe affiche **toute** la liste et laisse le joueur choisir — jamais un `take(3)`, le compte de
trois étant celui d'aujourd'hui et non une règle —, tandis que le **tutoriel** prend encore le
premier (`tutorial_fixtures.dart:58`), son étape de choix de classe étant reportée au **lot D**. Le
rang reste explicite : c'est lui qui fixe l'ordre d'affichage et le choix par défaut, là où l'ordre
alphabétique déciderait sinon
([ADR-099](../_adr/ADR-099-choix-du-passif-et-conditionnement-des-recompenses.md)).

> [!NOTE]
> Un dixième passif se pose en **un seul fichier JSON** s'il réutilise un `effectType` existant ; il
> lui faut en plus une stratégie et une ligne dans `byEffectType` seulement s'il apporte une formule
> neuve. Le trigger, toutes les valeurs, le rang d'affichage, la cible de Maîtrise et les six chaînes
> localisées sont, eux, **toujours** de la donnée pure.
