## 4. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état. Le décompte (`tickStatuses()`) s'opère au début de leur tour respectif.

### 4.1. Statuts Implémentés

| Statut (`id`) | Type | Empilable | Effet Mécanique | Tick |
|:---|:---:|:---:|:---|:---|
| `poison` | Debuff | Oui | Inflige dégâts directs = valeur au début du tour | Durée -1 chaque tour |
| `might` | Buff | Oui, **par source** (§4.3) | La **Puissance** : ajoute sa valeur à `effectiveMight`, que la classe oriente par `mightTargets` — Attaques, Compétences, altérations ([ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md)). `effectiveMight` somme **toutes** les entrées `might`, une par source | Durée -1 chaque tour, chaque entrée pour elle-même |
| `weakness` | Debuff | Oui | **−25 % de dégâts infligés par point, 2 points au plus** (−50 %) — §4.4 | Durée -1 chaque tour |
| `might_regen` | Buff | Oui | Ajoute sa valeur au statut `might` au début du tour, sous la source `status:might_regen` | Durée -1 chaque tour |
| `armor_regen` | Buff | Oui | Génère de l'armure = valeur au début du tour | Durée -1 chaque tour |
| `burn` | Debuff | Oui | Inflige des dégâts de feu = valeur active au début du tour. Le tick réduit la valeur et la durée de 1. | Durée -1 chaque tour |
| `freeze` | Debuff | Oui | **−25 % à la prochaine attaque par point, 3 points au plus** (−75 %), calculé dans l'intention affichée — §4.4. Ne se dissipe pas en début de tour mais après la résolution de son action d'attaque. | Durée décrémentée après l'action d'attaque |
| `shock` | Debuff | Oui | Ajoute sa valeur active cumulée à tout dégât d'attaque direct subi par la cible. | Durée -1 chaque tour |
| `vulnerable` | Debuff | Oui | **+25 % de dégâts reçus par point, 4 points au plus** (+100 %), arrondi — §4.4. Affecte autant le Héros que les Ennemis. | Durée -1 chaque tour |

### 4.2. Statuts Partiellement Implémentés
Aucun. Tous les statuts décrits ci-dessus sont 100% implémentés et opérationnels dans le calcul des dégâts.

### 4.3. Mécanique de Stacking (`StatusEffect.combine`)

**Deux statuts fusionnent s'ils ont le même `id` et la même source** (`StatusEffect.mergesWith`,
`sourceId` nul compris) : c'est la seule règle, que lisent `combine` et `EntityStats.addStatus`.
Au sein d'une même entrée :

```dart
if (isStackable) {
  value += other.value;
  duration = max(duration, other.duration);
} else {
  value = max(value, other.value);
  duration = max(duration, other.duration);
}
```

> [!IMPORTANT]
> **Seule la Puissance reçoit une source** — [ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md).
> Tout autre statut est posé sans source, et tous les statuts sans source d'un même `id`
> fusionnent comme avant. La source est l'id du contenu qui pose, jamais l'exemplaire :
> `card:<id>`, `rule:<ressource>` (la conversion de classe), `passive:<id>`, `relic:<id>`,
> `status:might_regen`, `enemy:<id>`. **La même source rejouée s'additionne** — deux *Forme
> Démoniaque*, les conversions d'un tour, *Ferveur* d'un tour ennemi à l'autre, les charges de
> *Shuriken* ; **deux sources différentes ne se confondent plus** : *Forme Démoniaque* (2 pendant
> 4 tours) puis *Mur de Fer* chez le Berserker (5 pendant 1 tour) font **7** ce tour-ci, puis 2
> pendant trois tours — et non plus 12 pendant quatre. La Puissance de *Rage* ne s'accumule plus
> dans celle d'une *Forme Démoniaque* en cours. Le panneau des effets montre une ligne par entrée,
> chacune avec sa durée ; la barre de vie, leur somme.

> [!NOTE]
> **Les statuts des runes élémentaires fusionnent avec ceux de la cible** —
> [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md). *Brûlant*, *Congelant* et *Surchargé*
> ajoutent un effet `apply_status`, posé par `addStatus` sans source, avant les effets de la carte.
> Ils ne sont plus concaténés à la liste de l'ennemi : une brûlure de rune se fond dans la brûlure
> en cours et s'éteint au même rythme (4 puis 3, au lieu de 4 puis 2) ; le choc d'une rune sur une
> cible déjà électrocutée compte enfin dans les dégâts (le pipeline n'en lit qu'une entrée) ; le gel
> n'a aucun effet de cumul.

> [!WARNING]
> **Les icônes de statut des ennemis supposent une entrée par `id`**
> (`lib/game/components/entities/status_indicator.dart:43-62`). Vrai aujourd'hui : la Puissance
> d'un ennemi n'a qu'une source, son intention Buff — celle d'Éveil meurt dans l'appel qui la
> crée. Une carte qui donnerait de la Puissance à un ennemi casserait cet invariant (ADR-104).

### 4.4. Les statuts proportionnels

> [!IMPORTANT]
> **Vulnérable, Faiblesse et Gel comptent leurs points** — P-44 lot 1, vague 5, en attente du
> propriétaire ; barème de la réponse P-1 (a) du propriétaire, 2026-11-03 —
> [ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md).
> Jusqu'à la vague 4, ils étaient tout ou rien (+50 %, −25 %, −50 %).

| Statut | Par point | Plafond |
|:---|:---|:---|
| `vulnerable` | +25 % de dégâts subis | 4 points (+100 %) |
| `weakness` | −25 % de dégâts infligés | 2 points (−50 %) |
| `freeze` | −25 % à l'attaque | 3 points (−75 %) |

- **Le point se lit sur la somme des entrées de même id**, bornée au plafond ; l'arrondi est au
  plus proche. Les durées ne changent pas : le Gel s'use d'une attaque par attaque.
- **Un seul endroit porte le barème** — `ProportionalStatus` (`lib/game/services/proportional_status.dart`),
  le pourcentage par point et le plafond de chacun — et le pipeline de dégâts, l'intention effective
  de l'ennemi, les infobulles des cartes et la galerie du tutoriel le lisent : aucun texte n'écrit
  plus un pourcentage en dur.
- **La Puissance « altération » ajoute des points** à ces trois statuts, comme à leur durée avant.
  Un seul `apply_status` par résolution reçoit ce bonus ([`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md) §3.14.4).
- **Recalibrés pour garder leur premier effet** : *Trait de Glace* pose 2 Gel, la rune *Congelant*
  2 points par niveau et sans plafond, *Marque du Mage* 2 Vulnérable.
- **C'est le barème des vagues 5 et 6** : les charges élémentaires relisent le Gel, le Feu et la
  Foudre en vague 7 ([ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)).
