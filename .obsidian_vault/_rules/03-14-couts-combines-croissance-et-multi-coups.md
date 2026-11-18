### 3.14. 🩸 Coûts Combinés, Croissance et Multi-coups (P-44, lot 1)

Les mécanismes de profondeur des cartes, livrés par le lot 1 de P-44 par la vague 5,
fusionnée dans `main` le 2026-11-09 —
[ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md).
Les statuts proportionnels sont en [`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.4, les charges §4.5, les
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
| `cardsPlayedThisTurn` | Cartes et signatures jouées avant celle-ci ce tour | *Frénésie sanglante* (vague 6) |
| `enemiesAlive` | Ennemis vivants | — |
| `targetStatus` | Somme brute d'un statut (`statusId`) sur la cible — celle que l'ennemi affiche, au-delà du plafond du barème | *Exploitation* (`vulnerable` × 1, vague 8) *(cible unique seulement)* |
| `targetMissingHp` | PV max − PV de la cible | *Exécution* (× 0,2, vague 8) *(cible unique seulement)* |

- **Les effets se résolvent dans l'ordre** : l'Armure d'un effet précédent de la même carte compte
  pour le suivant ; *Fortification* lit l'Armure avant de donner la sienne.
- **La rareté ne multiplie jamais le terme** ; `scaleWith` est refusé sur `draw` et `gain_mana`
  (ce que G2 gèle ne grandit pas) et sur un effet à plusieurs coups.
- **À l'écran** : hors combat, la valeur de base et une ligne de croissance ; en combat, la valeur
  jouée, terme compris, quand le héros est connu. Une source de cible vaut 0 tant qu'aucune cible
  n'est visée : la face d'*Exécution* ou d'*Exploitation* en main affiche sa base. La ligne de
  `targetStatus` nomme le statut **dans la langue du joueur** depuis la vague 8 (A10) : le nom de la
  charge s'il en est une, sinon la clé ARB `statusName` — « +1 per point of Vulnerable on the
  target », plus « Vulnérable » en anglais.

#### 3.14.3. Multi-coups et `mightRatio`

`hits` (entier ≥ 1, 1 par défaut) et `mightRatio` (]0, 1], 1 par défaut), sur un effet de dégâts
seulement. Pour chaque coup et chaque cible vivante : la valeur jouée plus
**`floor(Puissance × mightRatio)`**, puis le pipeline — critique et Foudre par coup —, puis
l'absorption et l'éclaboussure. Un coup ne tombe que sur une cible vivante ; le vol de vie, de
statut comme de rune, se paie **une fois**, après tous les coups. Le badge affiche `3×3`.

**La Foudre se lit à chaque coup**, sur les points du moment (vague 7, fusionnée dans `main` le 2026-11-18 par la PR #55 —
[ADR-117](../_adr/ADR-117-les-charges-elementaires.md)) : *Rafale d'étincelles* pose 1 Foudre puis
frappe 3 × (3 + 1) = **12** sur un ennemi neuf ; sur un ennemi à 2 Foudre, sa pose le charge et
chaque coup fait +2 par point : 3 × (3 + 6) = **27**. Le joueur voit le bonus « +N » de chaque
coup en jaune ([`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.5). Chez le héros gelé,
chaque coup perd 50 % ([`_rules/03-3`](03-3-pipeline-de-degats-centralise.md)).

> [!NOTE]
> **Garde de donnée (D38)** : sur chaque carte, Σ `hits` × `mightRatio` ≤ coût en mana + 1. Une
> Quatre cartes portent `hits`, re-comptées le 2026-11-18 (`grep -rl '"hits"' assets/data/cards`) :
> *Rafale d'étincelles* (3 × 3 à 0,5, soit 1,5 pour 2 mana), *Fléau béni* (2 × 3 à 0,75, 1,5 pour 1),
> *Marteau sacré* (3 × 3 à 0,75, 2,25 pour 2) et *Salve* (vague 8 : 3 × 2 à 0,5, 1,5 pour 1).

#### 3.14.4. Un seul bonus de Puissance de statut par résolution

**Le premier `apply_status` de la résolution reçoit le bonus de Puissance** de statut
(`statusBonusFor`), tous statuts confondus ; les suivants, non (Q11). Une carte qui pose du
Feu et porte la rune *Brûlant* ne compte la Puissance qu'une fois — depuis la vague 7, le bonus
ajoute des points de charge, avant le plafond du Gel ; une explosion de Feu n'en reçoit aucun. **Un écho est une seconde
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
