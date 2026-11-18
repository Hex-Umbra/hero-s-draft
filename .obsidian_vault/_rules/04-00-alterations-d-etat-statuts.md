## 4. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état. Le décompte (`tickStatuses()`) s'opère au début de leur tour respectif — **les charges élémentaires en sont exemptes** (§4.5).

### 4.1. Statuts Implémentés

| Statut (`id`) | Type | Empilable | Effet Mécanique | Tick |
|:---|:---:|:---:|:---|:---|
| `poison` | Debuff | Oui | Inflige dégâts directs = valeur au début du tour. Depuis la vague 7, **le seul dégât sur la durée** (D83) | Durée -1 chaque tour |
| `might` | Buff | Oui, **par source** (§4.3) | La **Puissance** : ajoute sa valeur à `effectiveMight`, que la classe oriente par `mightTargets` — Attaques, Compétences, altérations ([ADR-097](../_adr/ADR-097-puissance-unique-orientee-par-la-classe.md)). `effectiveMight` somme **toutes** les entrées `might`, une par source | Durée -1 chaque tour, chaque entrée pour elle-même |
| `weakness` | Debuff | Oui | **−25 % de dégâts infligés par point, 2 points au plus** (−50 %) — §4.4. Posée par les cartes du lot Sanctifié depuis la vague 8, par l'évolution *Sentence* avant | Durée -1 chaque tour |
| `might_regen` | Buff | Oui | Ajoute sa valeur au statut `might` au début du tour, sous la source `status:might_regen` | Durée -1 chaque tour |
| `mana_regen` | Buff | Oui | La **Source de Mana** (vague 6, fusionnée dans `main` le 2026-11-15 — [ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md)) : donne sa valeur en Mana au début du tour du héros, par `StatGains` (source `status`), après le tic, comme `armor_regen` ; posée par *Méditation* (1 pendant 2 tours). Héros seulement : aucun ennemi n'a de mana. Icône et couleur de `gain_mana`. *Persistant* et *Résonant* ne s'offrent pas à une carte qui la pose ([`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md)) | Durée -1 chaque tour |
| `armor_regen` | Buff | Oui | Génère de l'armure = valeur au début du tour | Durée -1 chaque tour |
| `hp_regen` | Buff | Oui | La **Source de Vie** (vague 8, livrée sur la branche `feat/v0.6.0-p42-tranche-3`, en attente du test, de la PR, de la fusion et du tag du propriétaire — [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md), D55) : rend sa valeur en PV au début du tour du porteur, après le tic, avec la Métallisation et la Source de Mana ; bornée aux PV max ; **ne relève jamais un porteur à 0 PV** (le Poison ou le Feu du même début de tour l'ont tué). Ni `StatGains`, ni critique, ni vol de vie. **Symétrique** : le début de tour d'un ennemi la traite de même, bien qu'aucun n'en pose. Posée par *Prière* (2 pendant 3 tours). Icône et couleur du soin (cœur rose) ; jamais sauvegardée | Durée -1 chaque tour |
| `burn` — **le Feu** | Charge | Points | Une **charge** (§4.5) : au tour du porteur, chaque tranche de 3 points le blesse et explose sur ses voisins | Aucun : la charge se résout entière |
| `freeze` — **le Gel** | Charge | Points | Une **charge** (§4.5) : au seuil, l'ennemi perd sa prochaine action ; le héros frappe moitié moins à son tour suivant | Aucun ; déclin −1 sans gel |
| `shock` — **la Foudre** | Charge | Points | Une **charge** (§4.5) : chaque coup reçu fait plus, deux fois plus une fois chargé | Aucun ; déclin −1 sous le seuil |
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
> **Les statuts des runes élémentaires rejoignent la charge de la cible** —
> [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), complété par
> [ADR-117](../_adr/ADR-117-les-charges-elementaires.md). *Brûlant*, *Congelant* et *Surchargé*
> ajoutent un effet `apply_status`, posé avant les effets de la carte ; depuis la vague 7, c'est la
> **pose d'une charge** (§4.5) : ses points s'ajoutent à ceux que la cible porte, sous les mêmes
> règles de plafond et de rupture. *Surchargé* sur *Coup de Tonnerre* pose donc sa Foudre avant le
> coup de la carte.

> [!WARNING]
> **Les icônes de statut des ennemis supposent une entrée par `id`**
> (`lib/game/components/entities/status_indicator.dart`). Vrai aujourd'hui : la Puissance
> d'un ennemi n'a qu'une source, son intention Buff — celle d'Éveil meurt dans l'appel qui la
> crée. Une carte qui donnerait de la Puissance à un ennemi casserait cet invariant (ADR-104).

### 4.4. Les statuts proportionnels

> [!IMPORTANT]
> **Vulnérable et Faiblesse comptent leurs points** — P-44 lot 1, vague 5, fusionnée dans
> `main` le 2026-11-09 ; barème de la réponse P-1 (a) du propriétaire, 2026-11-03 —
> [ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md).
> Jusqu'à la vague 4, ils étaient tout ou rien (+50 %, −25 %). **Le Gel a quitté ce barème en
> vague 7** pour devenir une charge (§4.5, [ADR-117](../_adr/ADR-117-les-charges-elementaires.md),
> qui amende ADR-111 D4) ; des vagues 5 à 6, il valait −25 % à l'attaque par point, 3 points au
> plus.

| Statut | Par point | Plafond |
|:---|:---|:---|
| `vulnerable` | +25 % de dégâts subis | 4 points (+100 %) |
| `weakness` | −25 % de dégâts infligés | 2 points (−50 %) |

- **Le point se lit sur la somme des entrées de même id**, bornée au plafond ; l'arrondi est au
  plus proche.
- **Un seul endroit porte le barème** — `ProportionalStatus` (`lib/game/services/proportional_status.dart`),
  le pourcentage par point et le plafond de chacun — et le pipeline de dégâts, les infobulles des
  cartes et la galerie du tutoriel le lisent : aucun texte n'écrit plus un pourcentage en dur.
- **La Puissance « altération » ajoute des points** à ces statuts, comme à leur durée avant.
  Un seul `apply_status` par résolution reçoit ce bonus ([`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md) §3.14.4).
- **Recalibré pour garder son premier effet** : *Marque du Mage* pose 2 Vulnérable — depuis la
  vague 8, sur la première **carte de dégâts** du tour, Attaque ou Compétence, à cible unique et
  vivante ([`_rules/02-2`](02-2-systeme-de-heros.md) §Passifs, ADR-118). Ses points s'additionnent
  d'un tour à l'autre sur la même cible : l'ennemi affiche la somme brute, que lit aussi
  `targetStatus` (*Exploitation*), le pipeline n'en compte que 4.
- **La Faiblesse vieillit avant l'action de son porteur** : l'ennemi décompte ses statuts au début
  de sa phase, avant ses intentions — une Faiblesse de N tours posée par une carte réduit N − 1
  attaques. Le moteur n'a pas changé en vague 8 (A19, D83) : les durées des cartes de Sanctifié ont
  un tour de plus ; le décalage, antérieur (*Sentence*), est à la file.

### 4.5. Les charges élémentaires — le Gel, le Feu, la Foudre

> [!IMPORTANT]
> **Une charge est faite de points qui s'accumulent sur leur porteur, héros ou ennemi, jusqu'à un
> seuil où ils rompent** — P-53, vague 7, fusionnée dans `main` le 2026-11-18 par la PR #55 et
> taguée `v0.5.9` ; brainstorm v3, D83 à D86 —
> [ADR-117](../_adr/ADR-117-les-charges-elementaires.md). Le cadre est **symétrique** et **en
> donnée** : un fichier par charge sous `assets/data/charges/` ([`_rules/07-00`](07-00-architecture-des-donnees.md)),
> seules quatre sortes de rupture sont écrites en Dart. Aucun ennemi ne pose encore de charge.

**Les points** d'une charge sont la somme des entrées de même id, sans source ni durée lue : le tic
ne les décompte pas. **La piste**, par porteur et par élément, porte le seuil courant, les ruptures
du combat et l'état — aucun, rompu en attente, rompu actif. Points et piste meurent avec les
statuts du combat ; rien n'est sauvegardé.

**La pose** : sur un porteur rompu sans surcharge, rien n'est posé ; sans surcharge, les points sont
bornés au restant (`seuil − points`) ; une charge qui rompt au seuil rompt **aussitôt**, et son
seuil monte de `thresholdGrowth` pour le reste du combat. La Puissance « altération » s'ajoute
avant le plafond, une fois par résolution ; une explosion n'est pas une carte et n'en reçoit pas.

| | Gel (`freeze`) | Feu (`burn`) | Foudre (`shock`) |
|:---|:---|:---|:---|
| Seuil de départ | 3 ; **6 pour tout ennemi d'un combat de boss** (`isBoss`) ; **5 pour le héros** | 3, pour tous | 3, pour tous |
| Montée à chaque rupture | +1 | — | — |
| Surcharge | **Non** : plafonnée au restant, rien sur un porteur gelé | Libre | Libre |
| Déclin, au tour du porteur | −1 s'il n'a pas gelé | Aucun : tout se résout | −1 sous le seuil |
| Rupture | **Au seuil** : l'ennemi gelé **ne fait rien** à son action — attaque, défense ou renforcement —, son intention est consommée, ses statuts se résolvent ; **le héros gelé ne perd pas son tour** : ses cartes et signatures infligent **50 % de moins** pendant son prochain tour, chaque coup compris, après la Faiblesse (8 → 6 → 3) | **Au tour du porteur** : chaque tranche de 3 fait **4 par point** au porteur et **explose** — **12 dégâts et 1 Feu** à chacun de ses voisins ; le reste fait **2 par point** et n'explose pas (5 points : 16 au porteur, 12 et 1 Feu à chaque voisin) | **Sous le seuil** : chaque coup reçu fait **+1 par point** ; **au seuil**, le porteur est **chargé** aussitôt : **+2 par point** à chaque coup, les suivants de la même carte compris, jusqu'à la fin de la phase en cours |
| États affichés | « ❄ 2/3 », puis « ❄ Gelé » | « 🔥 5 » | « ⚡ 2/3 », puis « ⚡ 4 Chargé » |

- **Le Feu : la chaîne**, au début de la phase ennemie. Tous les porteurs vivants se résolvent
  ensemble (vague 1) ; le Feu que leurs explosions posent forme la vague suivante, et elle seule ;
  la chaîne s'arrête quand une vague n'en pose plus — toujours, la validation refusant un seuil de
  Feu inférieur à 3. **Les voisins** sont l'ennemi à gauche et l'ennemi à droite dans la rangée ;
  le héros n'en a pas et ne prend que sa part. Contre le Feu, **l'Armure absorbe ; ni Vulnérable,
  ni critique, ni Faiblesse** (P-d). Un porteur que sa rupture tue explose quand même ; un porteur
  tué avant son tour perd son Feu sans exploser. L'exemple de l'étude, 9 Feu sur B dans A B C :
  **48, 64 et 48** de PV perdus, en trois vagues. L'explosion à la mort d'un porteur est écartée.
- **La Foudre au pipeline** : après le critique, avant Vulnérable, qui l'amplifie
  ([`_rules/03-3`](03-3-pipeline-de-degats-centralise.md)). *Rafale d'étincelles* sur un ennemi
  neuf : 3 × (3 + 1) = 12 ; sur un ennemi à 2 Foudre, elle le charge : 3 × (3 + 6) = 27. *Coup de
  Tonnerre* frappe avant de poser : il prépare.
- **Les fermetures de phase** : au début de la phase ennemie (fin du tour du joueur) et à sa fin,
  toute Foudre chargée retombe à 0 ; le gel actif du héros prend fin avec son tour.
- **Le tour du héros** : son Feu se résout d'abord, avant le Poison ; puis les déclins ; un gel en
  attente passe actif. **La phase ennemie** : la chaîne du Feu, puis les autres statuts de chaque
  ennemi et les déclins, puis les actions.
- **Les noms** (P-a) : Gel, Feu, Foudre ; Freeze, Burn, Shock ; états Gelé / Frozen et Chargé /
  Charged. La règle du Gel sur le héros (`heroDescription`) ne s'affiche nulle part tant qu'aucun
  ennemi ne pose de charge (Q-P1 (d)).
- **L'intention d'un ennemi n'est plus réduite par le Gel** : il agit en entier, ou ne fait rien.
- **Les dix contenus qui posent une charge** ([`_rules/02-3`](02-3-catalogue-de-cartes.md),
  [`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md), [`_rules/02-8`](02-8-evolutions-de-signature.md)) :
  *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Nova de givre*, *Embrasement* (3 Feu, 4
  avant), *Rafale d'étincelles*, les runes *Brûlant*, *Congelant* (1 Gel par niveau, 2 avant) et
  *Surchargé*, l'évolution *Braise*. Les valeurs sont des ordres de grandeur que le test du
  propriétaire corrige.
