---
description: A status remembers what applied it — addStatus merges only the same id from the same source, and only Might receives a source; the class conversion rule gains a bounded ratio, 0.5 rounded up for the Berserker, and the player reads that rate on the class rule
---

# ADR-104 — Un Statut par Source, et le `ratio` de la Règle de Classe

### Statut

✅ Accepté — 2026-10-02 (P-43, lot **E0** ; brainstorm v3, décisions D36, D37 et D66). **Livré sur
la branche `feat/v0.5.3-p43-e0-e1` — vague 1 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Spec `f38a0f1`, plan
`bdd82f6`, cinq commits de code `258aca1`..`dd5ae0c`.
**Complète [ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md)** — `StatRule` gagne
`ratio` — sans amender aucune de ses décisions ; le passage unique
d'[ADR-095](ADR-095-passage-unique-des-gains-scission-des-puissances-et.md) tient. Sa décision D4
est livrée par [ADR-105](ADR-105-moteur-de-runes-data-driven.md) (E1, même vague).
Conception : [spec E0](../../docs/superpowers/specs/2026-10-01-p43-e0-puissance-par-source-et-ratio-design.md),
[plan](../../docs/superpowers/plans/2026-10-01-p43-e0-puissance-par-source-et-ratio.md) ; arbitrages
et décisions d'exécution recopiés au
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-1-compte-rendu.md),
§2.1 à §2.3.

### Contexte

Deux défauts de la Puissance, que le brainstorm v3 réunit dans un même lot (D66) :

- **Deux Puissances de durées différentes se fondaient en une.** `EntityStats.addStatus` cherchait
  une entrée de même identifiant ; `combine` additionnait les valeurs et gardait la durée la plus
  longue. Chez le Berserker, *Forme Démoniaque* (2 Puissance, 4 tours) puis *Mur de Fer* (10 Armure,
  convertie en Puissance d'un tour) au même tour donnaient **12 Puissance pendant quatre tours** —
  la Puissance d'un tour héritait de la durée d'un Pouvoir. La Puissance de *Rage*, posée à chaque
  début de tour, s'accumulait de même dans une *Forme Démoniaque* en cours (D36).
- **La conversion du Berserker se faisait à 1 pour 1.** *Mur de Fer* lui valait 10 Puissance —
  « l'échange voulu, à équilibrer » qu'ADR-097 laissait en conséquence (D37).

### Décision

**D1 — La règle de fusion : même statut et même source** *(A1)*. `StatusEffect.mergesWith` —
même `id` **et** même `sourceId`, `null` compris — est la seule règle, lue par `combine` et par
`addStatus`. Le mécanisme est général : **`addStatus` ne teste jamais l'identifiant `might`**. Mais
**seule la Puissance reçoit une source** ; tout autre statut est posé sans source et fusionne
exactement comme avant. Écartés : une source sur tout statut (le lecteur de `shock`, les icônes des
ennemis et toutes les altérations auraient changé de règle) ; une source réservée aux statuts du
héros (la source est une propriété de ce qui pose, pas de ce qui reçoit).

**D2 — L'identité d'une source : l'id du contenu qui pose, jamais l'exemplaire** *(A2)*.

| Nature | Forme | Conséquence voulue |
|:---|:---|:---|
| Carte | `card:<id de la carte>` | Deux *Forme Démoniaque* s'additionnent, rareté comprise — « la même carte rejouée s'additionne » |
| Règle de classe | `rule:<ressource>`, dans le vocabulaire du fichier (`StatRule.statName`) | Toutes les conversions d'un tour fusionnent : elles ont la durée de la règle |
| Passif | `passive:<id>` | *Rage* a son entrée, qui expire au tic suivant au lieu de grossir |
| Relique | `relic:<id>` | *Plume de scribe* (un tour) et *Shuriken* (le combat) ne se mêlent pas |
| Statut qui en pose un autre | `status:might_regen` | Seul, Éveil de Puissance rend 1, 2, 3, 3, comme avant |
| Ennemi | `enemy:<id de la donnée>` | La règle commune, jamais l'uuid de l'instance |

**D3 — La forme : une chaîne `<nature>:<id>`, nullable** *(A3)*, fabriquée par le seul utilitaire
`StatusSource`. La clé JSON `sourceId` n'est écrite que si elle n'est pas nulle : aucun type neuf
dans le format, aucune migration.

**D4 — Les statuts des runes élémentaires restent hors de la règle de source** *(A4)* : ils seront
posés par `addStatus`, sans source, et fusionneront avec le statut que la cible porte déjà — un seul
chemin de pose pour tous les statuts. **Livré par ADR-105**, avec son changement de jeu.

**D5 — `ratio`, un champ borné par le modèle** *(A5)*. Facultatif sur une règle de `statRules`,
défaut 1 ; borné à **]0, 1]**, refusé par `StatRule.fromJson` — que traversent le chargeur et la
famille 7 de l'éditeur. **Aucune entrée de descripteur** : un fait à un seul endroit (ADR-100 D1).
L'égalité et le `hashCode` de `StatRule` le comptent ; `toString` ajoute `, ratio 0.5` quand il
diffère de 1. `classes/berserker/class.json` déclare `"ratio": 0.5`.

**D6 — L'arrondi : par gain, à l'entier supérieur, à un seul endroit** *(A6)*.
`StatRule.convertedAmount` rend le produit arrondi à l'entier supérieur **avec une tolérance de
10⁻⁹** — sans quoi `0,1 × 30` donnerait 4 — et jamais moins de 1. `StatGains._convert` l'appelle
gain par gain, et le texte de la règle aussi : l'exemple que lit le joueur sort de l'arithmétique
que le moteur joue. À 0,5 : 6 → 3, 5 → 3, 1 → 1 ; deux *Défense* donnent 3 + 3.

**D7 — Le joueur lit le taux sur la règle de classe** *(A7)*. Quand le ratio diffère de 1,
`StatRuleLabel.describe` ajoute une seconde phrase (`statRuleRatioArmor`, `statRuleRatioMana`) :
« Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance. » — à la carte de classe et
dans l'étape « Armure & Dégâts » du tutoriel. Le titre « ARMURE → PUISSANCE » et le texte des
cartes ne changent pas.

**D8 — Le panneau des effets : une ligne par entrée** *(A8)*, sans code neuf ; la barre de vie
affiche la somme.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| `StatusSource`, `sourceId`, `mergesWith`, `combine` | `lib/models/status_effect.dart` |
| La fusion | `lib/models/entity_stats.dart` — `addStatus` |
| La fabrique, branche `might` seule | `lib/game/services/effect_resolver.dart` — `createStatus(…, sourceId:)` |
| Carte | `lib/game/services/effects/strategies.dart` — `StatusSource.card` |
| Règle de classe, ratio | `lib/game/systems/stat_gains.dart` — `_convert` ; `lib/models/data/stat_rule.dart` — `ratio`, `convertedAmount`, `statName`, `toString` |
| Passifs | `lib/game/systems/passives/passive_strategies.dart` — `StatusSource.passive` |
| Reliques | `lib/game/controllers/run/player_stats_manager.dart` — trois sites `StatusSource.relic` |
| Éveil, héros et ennemi | `lib/game/controllers/combat/status_effect_processor.dart` — `StatusSource.status('might_regen')` |
| Intention Buff | `lib/game/controllers/combat/turn_phase_manager.dart` — `StatusSource.enemy` |
| Le texte du taux | `lib/models/data/model_extensions.dart` — `StatRuleLabel.describe` ; `lib/l10n/app_fr.arb`, `app_en.arb` |
| La donnée | `assets/data/classes/berserker/class.json` |
| Tests | `test/unit/status_source_test.dart` (neuf), `stat_rule_test.dart`, `stat_rule_conversion_test.dart`, `stat_rule_label_test.dart`, `stat_gains_characterization_test.dart`, `passives_berserker_test.dart`, `passives_paladin_test.dart`, `combat_controller_test.dart` ; `test/widget/status_effects_panel_overflow_test.dart` |

### Conséquences

- ✅ **La Puissance d'un tour reste d'un tour.** *Forme Démoniaque* puis *Mur de Fer* : **7** ce
  tour-ci (2 + 5), puis 2 pendant trois tours, au lieu de 12 pendant quatre. Le panneau des effets
  montre deux lignes « Puissance », chacune avec sa durée.
- ✅ **Le Berserker convertit moitié moins** : *Mur de Fer* 5, *Défense* 3, *Éveil* et *Cri de
  Guerre* 2. Aucune carte n'est rééquilibrée : D37 est un garde-fou de classe.
- ✅ **La conséquence d'ADR-097 « `might_regen` d'ennemi mort » devient exactement vraie.** La
  Puissance d'Éveil d'un ennemi ne fusionne plus dans celle de son intention Buff (99 tours), où
  elle survivait au tic ; devenue une entrée à part d'un tour, elle est retirée par le tic final du
  même `processEnemyStatuses`. La branche reste inatteignable : aucune donnée ne pose `might_regen`.
- ✅ **Aucune migration** : les statuts ne sont jamais sauvegardés (la sauvegarde n'est jamais
  écrite en combat), et `RunState.statRules` est relu de la classe (ADR-097 D1).

> [!IMPORTANT]
> **Invariant connu, relevé par la revue d'ensemble : les icônes de statut des ennemis supposent
> une entrée par identifiant.** `lib/game/components/entities/status_indicator.dart:43-62`
> réconcilie ses icônes par `status.id`. La Puissance d'un ennemi n'a aujourd'hui qu'une source, son
> intention Buff — celle d'Éveil meurt dans l'appel qui la crée. **Une carte qui donnerait de la
> Puissance à un ennemi** — l'éditeur de contenu permet de l'écrire — lui ferait porter deux `might`
> de sources différentes, et l'icône afficherait une valeur périmée. À traiter avec le premier
> contenu qui le rend possible.

- ⚠️ **Une carte d'armure ne dit pas sa Puissance convertie** : chez le Berserker, *Mur de Fer*
  affiche toujours « 10 Armure » ; c'est la règle de classe qui dit le taux. Aucun rendu de carte ne
  lit les règles de classe — fonctionnalité à part entière, non planifiée.
- ⚠️ **`StatRule.convertedAmount` rend 1 pour un gain nul ou négatif** : la précondition « gain
  strictement positif » est documentée, gardée par ses deux appelants, pas imposée.
- ⚠️ **Défaut antérieur relevé en chemin** : *Talisman de fer* et *Encensoir* donnent leur armure
  de début de tour avant le tic ; chez le Berserker, la Puissance qu'elle devient meurt dans le même
  début de tour. E0 ne change rien à ce défaut — porté à la file par le compte rendu, §5.
- ⚠️ **La simulation ne fusionne pas la Puissance comme le jeu** : elle tient une entrée par gain,
  plus fin que D1 ; aucune valeur mesurée par le brainstorm (D56 à D62, D67) n'en dépend —
  [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md).
