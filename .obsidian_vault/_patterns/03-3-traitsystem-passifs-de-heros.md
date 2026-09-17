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
| `berserker_armor` | `BerserkerArmorPassive` | Accorde `(PV manquants ~/ 10) × value` d'armure, rien si le total est nul |
| `spell_armor` | `SpellArmorPassive` | Accorde `value` d'armure si la carte jouée est de type `skill` |

Chaque stratégie implémente `PassiveStrategy.resolve(PassiveData passive, PassiveEvent event, RunController run)`
(`lib/game/systems/passives/passive_strategy.dart`) et lit `passive.value` **déjà augmenté** par
`dispatch` — elle ne lit jamais `effectiveMastery` elle-même. Chaque gain d'armure passe par
`RunController.grant(StatGain(GainResource.armor, n, GainSource.passive))`, comme avant P-49 ;
`StatGains` n'a plus de règle spéciale pour cette source ([`_rules/03-2`](../_rules/03-2-gestion-de-l-armure.md)).
Un `effectType` absent de la table **ne fait rien** — jamais d'exception en plein combat —
et `referential_integrity_test` refuse qu'un passif livré soit dans ce cas.

**Éligibilité** : chaque passif déclare ses `classes` (absent = toutes) ; le point d'accès unique
`availablePassivesFor(HeroData, GameDataRegistry)` (`lib/game/systems/passive_availability.dart`)
est la seule fonction qui les lit, triés par `id`. Ses deux lecteurs : l'écran de sélection de
classe et le tutoriel, tous deux prenant le premier passif disponible.
