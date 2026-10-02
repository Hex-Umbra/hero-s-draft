## 4. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état. Le décompte (`tickStatuses()`) s'opère au début de leur tour respectif.

### 4.1. Statuts Implémentés

| Statut (`id`) | Type | Empilable | Effet Mécanique | Tick |
|:---|:---:|:---:|:---|:---|
| `poison` | Debuff | Oui | Inflige dégâts directs = valeur au début du tour | Durée -1 chaque tour |
| `might` | Buff | Oui, **par source** (§4.3) | La **Puissance** : ajoute sa valeur à `effectiveMight`, que la classe oriente par `mightTargets` — Attaques, Compétences, altérations ([ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md)). `effectiveMight` somme **toutes** les entrées `might`, une par source | Durée -1 chaque tour, chaque entrée pour elle-même |
| `weakness` | Debuff | Oui | Réduit les dégâts physiques infligés de **25%** (`×0.75`) | Durée -1 chaque tour |
| `might_regen` | Buff | Oui | Ajoute sa valeur au statut `might` au début du tour, sous la source `status:might_regen` | Durée -1 chaque tour |
| `armor_regen` | Buff | Oui | Génère de l'armure = valeur au début du tour | Durée -1 chaque tour |
| `burn` | Debuff | Oui | Inflige des dégâts de feu = valeur active au début du tour. Le tick réduit la valeur et la durée de 1. | Durée -1 chaque tour |
| `freeze` | Debuff | Oui | Réduit les dégâts de la prochaine attaque de l'ennemi de **50%** (calculé dans l'intention affichée). Ne se dissipe plus en début de tour mais après la résolution de son action d'attaque. | Durée décrémentée après l'action d'attaque |
| `shock` | Debuff | Oui | Ajoute sa valeur active cumulée à tout dégât d'attaque direct subi par la cible. | Durée -1 chaque tour |
| `vulnerable` | Debuff | Oui | Augmente universellement tous les dégâts reçus de **50%** (arrondi). Affecte autant le Héros que les Ennemis. | Durée -1 chaque tour |

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
