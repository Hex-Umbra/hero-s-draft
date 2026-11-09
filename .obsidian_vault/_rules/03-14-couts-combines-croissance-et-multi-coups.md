### 3.14. 🩸 Coûts Combinés, Croissance et Multi-coups (P-44, lot 1)

Les mécanismes de profondeur des cartes, livrés par le lot 1 de P-44 sur la branche de la vague 5,
en attente du test, de la PR, de la fusion et du tag du propriétaire —
[ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md).
Les statuts proportionnels sont en [`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.1, les
cinq runes de mécanisme en [`_rules/03-8`](03-8-systeme-de-forge-forge-de-fusion.md) §3.8.2.

#### 3.14.1. Les coûts en PV et en Armure

Une carte déclare `cost` (du mana seul) **ou** `costs` :
`{ "mana": 0, "armor": 4 }`, `{ "mana": 1, "hp": 3 }`. `costs.mana` ≥ 0 est exigé, `hp` et `armor`
valent au moins 1, l'un des deux au moins ; toute autre clé est refusée, nommée.

> [!IMPORTANT]
> **Une règle, un débit** (`CostRules.canPay`, `lib/game/systems/cost_rules.dart`). Une carte se
> joue si et seulement si : le mana courant couvre son coût en mana, runes appliquées ; **les PV
> sont strictement supérieurs** à son coût en PV — une carte ne tue jamais son porteur ; l'Armure
> couvre son coût en Armure. Le paiement débite les trois ressources en **une** écriture
> (`consumeResource`) : ni dégâts, ni absorption, ni critique, ni vol de vie, ni `onDamageTaken`
> — *Ferveur* ne voit pas l'Armure dépensée. Une carte refusée ne paie rien.

| Cas | Résultat |
|:---|:---|
| PV = coût en PV | Refusée |
| PV = coût + 1 | Jouée ; le héros finit à 1 PV |
| Armure = coût en Armure | Jouée ; Armure 0 |
| Sous *Rage* | Les PV payés comptent dans la Puissance du tour suivant |
| *Allégé* sur une carte à `costs` | Réduit le seul mana ; une carte à 0 mana ne reçoit ni *Allégé* ni *Économe* |

- **Aucune neutre ne coûte autre chose que du mana** (D17) : `hp` et `armor` sont refusés sur une
  carte sans passif.
- **Une carte de lot ne coûte pas d'Armure sous une classe qui convertit la sienne** — le
  Berserker n'en a jamais (A7, lu sur sa `statRule`) ; garde de donnée par `LotRules`
  ([`_rules/02-3`](02-3-catalogue-de-cartes.md)).
- **La rareté ne touche jamais** un coût en PV ou en Armure ; aucune rune ne les réduit,
  *Transfusion* rembourse après coup.
- **À l'écran** : un médaillon par coût non nul — goutte rouge pour les PV, écu d'acier pour
  l'Armure, à côté du mana ; en combat, celui d'une ressource qui manque passe au rouge
  (`missingFor`). Le refus garde la secousse et le son d'aujourd'hui.

#### 3.14.2. La croissance — `scaleWith`

Un effet grandit d'un terme **`floor(ratio × quantité)`**, lu au moment de l'effet :
`"scaleWith": { "source": "armor", "ratio": 0.2 }`.

| Source | Quantité | Carte en jeu |
|:---|:---|:---|
| `armor` | L'Armure du héros | *Rempart brisé*, *Fortification* |
| `missingHp` | PV max − PV du héros | *Dernier souffle*, *Fureur sanguine* |
| `cardsPlayedThisTurn` | Cartes et signatures jouées avant celle-ci ce tour | — |
| `enemiesAlive` | Ennemis vivants | — |
| `targetStatus` | Somme d'un statut (`statusId`) sur la cible | — *(cible unique seulement)* |
| `targetMissingHp` | PV max − PV de la cible | — *(cible unique seulement)* |

- **Les effets se résolvent dans l'ordre** : l'Armure d'un effet précédent de la même carte compte
  pour le suivant ; *Fortification* lit l'Armure avant de donner la sienne.
- **La rareté ne multiplie jamais le terme** ; `scaleWith` est refusé sur `draw` et `gain_mana`
  (ce que G2 gèle ne grandit pas) et sur un effet à plusieurs coups.
- **À l'écran** : hors combat, la valeur de base et une ligne de croissance ; en combat, la valeur
  jouée, terme compris, quand le héros est connu.

#### 3.14.3. Multi-coups et `mightRatio`

`hits` (entier ≥ 1, 1 par défaut) et `mightRatio` (]0, 1], 1 par défaut), sur un effet de dégâts
seulement. Pour chaque coup et chaque cible vivante : la valeur jouée plus
**`floor(Puissance × mightRatio)`**, puis le pipeline — critique et Électrocution par coup —, puis
l'absorption et l'éclaboussure. Un coup ne tombe que sur une cible vivante ; le vol de vie, de
statut comme de rune, se paie **une fois**, après tous les coups. Le badge affiche `3×3`.

> [!NOTE]
> **Garde de donnée (D38)** : sur chaque carte, Σ `hits` × `mightRatio` ≤ coût en mana + 1. Une
> seule carte porte `hits` : *Rafale d'étincelles* (3 coups de 3 à 0,5, soit 1,5 pour 2 mana).

#### 3.14.4. Un seul bonus de Puissance de statut par résolution

**Le premier `apply_status` de la résolution reçoit le bonus de Puissance** de statut
(`statusBonusFor`), tous statuts confondus ; les suivants, non (Q11). Une carte qui pose une
Brûlure et porte la rune *Brûlant* ne compte la Puissance qu'une fois. **Un écho est une seconde
résolution** : son premier `apply_status` reçoit le sien.

#### 3.14.5. L'ordre d'un jeu de carte

1. L'accessibilité (§3.14.1), avec le statut et la cible d'aujourd'hui ;
2. le paiement ;
3. les effets — ceux des runes, puis ceux de la carte — avec leur terme de croissance et le bonus
   du premier statut ;
4. l'écho (*Résonant*), qui ne déclenche **aucun** événement « carte jouée » ;
5. le remboursement de *Transfusion* ;
6. côté contrôleur, la pile et la suite commune qui compte la carte jouée.

Une signature suit 1 à 5 par sa vue de carte, sans pile ([`_rules/02-2`](02-2-systeme-de-heros.md)).
